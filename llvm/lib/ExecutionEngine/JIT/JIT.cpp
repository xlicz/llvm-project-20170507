//===-- JIT.cpp - LLVM Just in Time Compiler ------------------------------===//
// 
//                     The LLVM Compiler Infrastructure
//
// This file was developed by the LLVM research group and is distributed under
// the University of Illinois Open Source License. See LICENSE.TXT for details.
// 
//===----------------------------------------------------------------------===//
//
// This tool implements a just-in-time compiler for LLVM, allowing direct
// execution of LLVM bytecode in an efficient manner.
//
//===----------------------------------------------------------------------===//

#include "JIT.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Function.h"
#include "llvm/GlobalVariable.h"
#include "llvm/Instructions.h"
#include "llvm/ModuleProvider.h"
#include "llvm/CodeGen/MachineCodeEmitter.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/ExecutionEngine/GenericValue.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetJITInfo.h"
#include "llvm/Support/DynamicLinker.h"
#include <iostream>

using namespace llvm;

JIT::JIT(ModuleProvider *MP, TargetMachine &tm, TargetJITInfo &tji)
  : ExecutionEngine(MP), TM(tm), TJI(tji), PM(MP) {
  setTargetData(TM.getTargetData());

  // Initialize MCE
  MCE = createEmitter(*this);
  
  // Add target data
  PM.add(new TargetData(TM.getTargetData()));

  // Compile LLVM Code down to machine code in the intermediate representation
  TJI.addPassesToJITCompile(PM);

  // Turn the machine code intermediate representation into bytes in memory that
  // may be executed.
  if (TM.addPassesToEmitMachineCode(PM, *MCE)) {
    std::cerr << "Target '" << TM.getName()
              << "' doesn't support machine code emission!\n";
    abort();
  }
}

JIT::~JIT() {
  delete MCE;
  delete &TM;
}

/// run - Start execution with the specified function and arguments.
///
GenericValue JIT::runFunction(Function *F,
                              const std::vector<GenericValue> &ArgValues) {
  assert(F && "Function *F was null at entry to run()");

  void *FPtr = getPointerToFunction(F);
  assert(FPtr && "Pointer to fn's code was null after getPointerToFunction");
  const FunctionType *FTy = F->getFunctionType();
  const Type *RetTy = FTy->getReturnType();

  assert((FTy->getNumParams() <= ArgValues.size() || FTy->isVarArg()) &&
         "Too many arguments passed into function!");
  assert(FTy->getNumParams() == ArgValues.size() &&
         "This doesn't support passing arguments through varargs (yet)!");

  // Handle some common cases first.  These cases correspond to common 'main'
  // prototypes.
  if (RetTy == Type::IntTy || RetTy == Type::UIntTy || RetTy == Type::VoidTy) {
    switch (ArgValues.size()) {
    case 3:
      if ((FTy->getParamType(0) == Type::IntTy || 
           FTy->getParamType(0) == Type::UIntTy) &&
          isa<PointerType>(FTy->getParamType(1)) &&
          isa<PointerType>(FTy->getParamType(2))) {
        int (*PF)(int, char **, const char **) =
          (int(*)(int, char **, const char **))FPtr;
        
        // Call the function.
        GenericValue rv;
        rv.IntVal = PF(ArgValues[0].IntVal, (char **)GVTOP(ArgValues[1]),
                       (const char **)GVTOP(ArgValues[2]));
        return rv;
      }
      break;
    case 2:
      if ((FTy->getParamType(0) == Type::IntTy || 
           FTy->getParamType(0) == Type::UIntTy) &&
          isa<PointerType>(FTy->getParamType(1))) {
        int (*PF)(int, char **) = (int(*)(int, char **))FPtr;
        
        // Call the function.
        GenericValue rv;
        rv.IntVal = PF(ArgValues[0].IntVal, (char **)GVTOP(ArgValues[1]));
        return rv;
      }
      break;
    case 1:
      if (FTy->getNumParams() == 1 &&
          (FTy->getParamType(0) == Type::IntTy || 
           FTy->getParamType(0) == Type::UIntTy)) {
        GenericValue rv;
        int (*PF)(int) = (int(*)(int))FPtr;
        rv.IntVal = PF(ArgValues[0].IntVal);
        return rv;
      }
      break;
    }
  }

  // Handle cases where no arguments are passed first.
  if (ArgValues.empty()) {
    GenericValue rv;
    switch (RetTy->getTypeID()) {
    default: assert(0 && "Unknown return type for function call!");
    case Type::BoolTyID:
      rv.BoolVal = ((bool(*)())FPtr)();
      return rv;
    case Type::SByteTyID:
    case Type::UByteTyID:
      rv.SByteVal = ((char(*)())FPtr)();
      return rv;
    case Type::ShortTyID:
    case Type::UShortTyID:
      rv.ShortVal = ((short(*)())FPtr)();
      return rv;
    case Type::VoidTyID:
    case Type::IntTyID:
    case Type::UIntTyID:
      rv.IntVal = ((int(*)())FPtr)();
      return rv;
    case Type::LongTyID:
    case Type::ULongTyID:
      rv.LongVal = ((int64_t(*)())FPtr)();
      return rv;
    case Type::FloatTyID:
      rv.FloatVal = ((float(*)())FPtr)();
      return rv;
    case Type::DoubleTyID:
      rv.DoubleVal = ((double(*)())FPtr)();
      return rv;
    case Type::PointerTyID:
      return PTOGV(((void*(*)())FPtr)());
    }
  }

  // Okay, this is not one of our quick and easy cases.  Because we don't have a
  // full FFI, we have to codegen a nullary stub function that just calls the
  // function we are interested in, passing in constants for all of the
  // arguments.  Make this function and return.

  // First, create the function.
  FunctionType *STy=FunctionType::get(RetTy, std::vector<const Type*>(), false);
  Function *Stub = new Function(STy, Function::InternalLinkage, "",
                                F->getParent());

  // Insert a basic block.
  BasicBlock *StubBB = new BasicBlock("", Stub);

  // Convert all of the GenericValue arguments over to constants.  Note that we
  // currently don't support varargs.
  std::vector<Value*> Args;
  for (unsigned i = 0, e = ArgValues.size(); i != e; ++i) {
    Constant *C = 0;
    const Type *ArgTy = FTy->getParamType(i);
    const GenericValue &AV = ArgValues[i];
    switch (ArgTy->getTypeID()) {
    default: assert(0 && "Unknown argument type for function call!");
    case Type::BoolTyID:   C = ConstantBool::get(AV.BoolVal); break;
    case Type::SByteTyID:  C = ConstantSInt::get(ArgTy, AV.SByteVal);  break;
    case Type::UByteTyID:  C = ConstantUInt::get(ArgTy, AV.UByteVal);  break;
    case Type::ShortTyID:  C = ConstantSInt::get(ArgTy, AV.ShortVal);  break;
    case Type::UShortTyID: C = ConstantUInt::get(ArgTy, AV.UShortVal); break;
    case Type::IntTyID:    C = ConstantSInt::get(ArgTy, AV.IntVal);    break;
    case Type::UIntTyID:   C = ConstantUInt::get(ArgTy, AV.UIntVal);   break;
    case Type::LongTyID:   C = ConstantSInt::get(ArgTy, AV.LongVal);   break;
    case Type::ULongTyID:  C = ConstantUInt::get(ArgTy, AV.ULongVal);  break;
    case Type::FloatTyID:  C = ConstantFP  ::get(ArgTy, AV.FloatVal);  break;
    case Type::DoubleTyID: C = ConstantFP  ::get(ArgTy, AV.DoubleVal); break;
    case Type::PointerTyID:
      void *ArgPtr = GVTOP(AV);
      if (sizeof(void*) == 4) {
        C = ConstantSInt::get(Type::IntTy, (int)(intptr_t)ArgPtr);
      } else {
        C = ConstantSInt::get(Type::LongTy, (intptr_t)ArgPtr);
      }
      C = ConstantExpr::getCast(C, ArgTy);  // Cast the integer to pointer
      break;
    }
    Args.push_back(C);
  }

  Value *TheCall = new CallInst(F, Args, "", StubBB);
  if (TheCall->getType() != Type::VoidTy)
    new ReturnInst(TheCall, StubBB);             // Return result of the call.
  else
    new ReturnInst(StubBB);                      // Just return void.

  // Finally, return the value returned by our nullary stub function.
  return runFunction(Stub, std::vector<GenericValue>());
}

/// runJITOnFunction - Run the FunctionPassManager full of
/// just-in-time compilation passes on F, hopefully filling in
/// GlobalAddress[F] with the address of F's machine code.
///
void JIT::runJITOnFunction(Function *F) {
  static bool isAlreadyCodeGenerating = false;
  assert(!isAlreadyCodeGenerating && "Error: Recursive compilation detected!");

  // JIT the function
  isAlreadyCodeGenerating = true;
  PM.run(*F);
  isAlreadyCodeGenerating = false;

  // If the function referred to a global variable that had not yet been
  // emitted, it allocates memory for the global, but doesn't emit it yet.  Emit
  // all of these globals now.
  while (!PendingGlobals.empty()) {
    const GlobalVariable *GV = PendingGlobals.back();
    PendingGlobals.pop_back();
    EmitGlobalVariable(GV);
  }
}

/// getPointerToFunction - This method is used to get the address of the
/// specified function, compiling it if neccesary.
///
void *JIT::getPointerToFunction(Function *F) {
  if (void *Addr = getPointerToGlobalIfAvailable(F))
    return Addr;   // Check if function already code gen'd

  // Make sure we read in the function if it exists in this Module
  try {
    MP->materializeFunction(F);
  } catch ( std::string& errmsg ) {
    std::cerr << "Error reading bytecode file: " << errmsg << "\n";
    abort();
  } catch (...) {
    std::cerr << "Error reading bytecode file!\n";
    abort();
  }

  if (F->isExternal()) {
    void *Addr = getPointerToNamedFunction(F->getName());
    addGlobalMapping(F, Addr);
    return Addr;
  }

  runJITOnFunction(F);

  void *Addr = getPointerToGlobalIfAvailable(F);
  assert(Addr && "Code generation didn't add function to GlobalAddress table!");
  return Addr;
}

// getPointerToFunctionOrStub - If the specified function has been
// code-gen'd, return a pointer to the function.  If not, compile it, or use
// a stub to implement lazy compilation if available.
//
void *JIT::getPointerToFunctionOrStub(Function *F) {
  // If we have already code generated the function, just return the address.
  if (void *Addr = getPointerToGlobalIfAvailable(F))
    return Addr;

  // If the target supports "stubs" for functions, get a stub now.
  if (void *Ptr = TJI.getJITStubForFunction(F, *MCE))
    return Ptr;

  // Otherwise, if the target doesn't support it, just codegen the function.
  return getPointerToFunction(F);
}

/// getOrEmitGlobalVariable - Return the address of the specified global
/// variable, possibly emitting it to memory if needed.  This is used by the
/// Emitter.
void *JIT::getOrEmitGlobalVariable(const GlobalVariable *GV) {
  void *Ptr = getPointerToGlobalIfAvailable(GV);
  if (Ptr) return Ptr;

  // If the global is external, just remember the address.
  if (GV->isExternal()) {
    Ptr = GetAddressOfSymbol(GV->getName().c_str());
    if (Ptr == 0) {
      std::cerr << "Could not resolve external global address: "
                << GV->getName() << "\n";
      abort();
    }
  } else {
    // If the global hasn't been emitted to memory yet, allocate space.  We will
    // actually initialize the global after current function has finished
    // compilation.
    Ptr =new char[getTargetData().getTypeSize(GV->getType()->getElementType())];
    PendingGlobals.push_back(GV);
  }
  addGlobalMapping(GV, Ptr);
  return Ptr;
}


/// recompileAndRelinkFunction - This method is used to force a function
/// which has already been compiled, to be compiled again, possibly
/// after it has been modified. Then the entry to the old copy is overwritten
/// with a branch to the new copy. If there was no old copy, this acts
/// just like JIT::getPointerToFunction().
///
void *JIT::recompileAndRelinkFunction(Function *F) {
  void *OldAddr = getPointerToGlobalIfAvailable(F);

  // If it's not already compiled there is no reason to patch it up.
  if (OldAddr == 0) { return getPointerToFunction(F); }

  // Delete the old function mapping.
  addGlobalMapping(F, 0);

  // Recodegen the function
  runJITOnFunction(F);

  // Update state, forward the old function to the new function.
  void *Addr = getPointerToGlobalIfAvailable(F);
  assert(Addr && "Code generation didn't add function to GlobalAddress table!");
  TJI.replaceMachineCodeForFunction(OldAddr, Addr);
  return Addr;
}
