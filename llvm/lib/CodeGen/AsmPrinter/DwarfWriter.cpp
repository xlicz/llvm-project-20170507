//===-- llvm/CodeGen/DwarfWriter.cpp - Dwarf Framework --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains support for writing dwarf info into asm files.
//
//===----------------------------------------------------------------------===//

#include "llvm/CodeGen/DwarfWriter.h"
#include "DwarfDebug.h"
#include "DwarfException.h"
#include "llvm/CodeGen/MachineModuleInfo.h"

using namespace llvm;

static RegisterPass<DwarfWriter>
X("dwarfwriter", "DWARF Information Writer");
char DwarfWriter::ID = 0;

//===----------------------------------------------------------------------===//
/// DwarfWriter Implementation
///

DwarfWriter::DwarfWriter()
  : ImmutablePass(&ID), DD(0), DE(0) {}

DwarfWriter::~DwarfWriter() {
  delete DE;
  delete DD;
}

/// BeginModule - Emit all Dwarf sections that should come prior to the
/// content.
void DwarfWriter::BeginModule(Module *M, AsmPrinter *A) {
  DE = new DwarfException(A);
  DD = new DwarfDebug(A);
  DD->beginModule(M);
}

/// EndModule - Emit all Dwarf sections that should come after the content.
///
void DwarfWriter::EndModule() {
  DE->EndModule();
  DD->endModule();
  delete DD; DD = 0;
  delete DE; DE = 0;
}

/// BeginFunction - Gather pre-function debug information.  Assumes being
/// emitted immediately after the function entry point.
void DwarfWriter::BeginFunction(const MachineFunction *MF) {
  DE->BeginFunction(MF);
  DD->beginFunction(MF);
}

/// EndFunction - Gather and emit post-function debug information.
///
void DwarfWriter::EndFunction(const MachineFunction *MF) {
  DD->endFunction(MF);
  DE->EndFunction();

  if (MachineModuleInfo *MMI = DE->MMI)
    // Clear function debug information.
    MMI->EndFunction();
}

/// ShouldEmitDwarfDebug - Returns true if Dwarf debugging declarations should
/// be emitted.
bool DwarfWriter::ShouldEmitDwarfDebug() const {
  return DD && DD->ShouldEmitDwarfDebug();
}

void DwarfWriter::BeginScope(const MachineInstr *MI) {
  DD->beginScope(MI);
}
void DwarfWriter::EndScope(const MachineInstr *MI) {
  DD->endScope(MI);
}
