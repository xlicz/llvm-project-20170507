; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-linux   -mcpu=core2 -mattr=+sse2 | FileCheck %s --check-prefix=X86
; RUN: llc < %s -mtriple=x86_64-linux -mcpu=core2 -mattr=+sse2 | FileCheck %s --check-prefix=X64
; RUN: llc < %s -mtriple=x86_64-linux-gnux32 -mcpu=core2 -mattr=+sse2  | FileCheck %s --check-prefix=X32

define void @t1(i32 %x) nounwind ssp {
; X86-LABEL: t1:
; X86:       # %bb.0:
; X86-NEXT:    jmp foo # TAILCALL
;
; X64-LABEL: t1:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo # TAILCALL
;
; X32-LABEL: t1:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo # TAILCALL
  tail call void @foo() nounwind
  ret void
}

declare void @foo()

define void @t2() nounwind ssp {
; X86-LABEL: t2:
; X86:       # %bb.0:
; X86-NEXT:    jmp foo2 # TAILCALL
;
; X64-LABEL: t2:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo2 # TAILCALL
;
; X32-LABEL: t2:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo2 # TAILCALL
  %t0 = tail call i32 @foo2() nounwind
  ret void
}

declare i32 @foo2()

define void @t3() nounwind ssp {
; X86-LABEL: t3:
; X86:       # %bb.0:
; X86-NEXT:    jmp foo3 # TAILCALL
;
; X64-LABEL: t3:
; X64:       # %bb.0:
; X64-NEXT:    jmp foo3 # TAILCALL
;
; X32-LABEL: t3:
; X32:       # %bb.0:
; X32-NEXT:    jmp foo3 # TAILCALL
  %t0 = tail call i32 @foo3() nounwind
  ret void
}

declare i32 @foo3()

define void @t4(void (i32)* nocapture %x) nounwind ssp {
; X86-LABEL: t4:
; X86:       # %bb.0:
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    movl $0, (%esp)
; X86-NEXT:    calll *{{[0-9]+}}(%esp)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t4:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    jmpq *%rax # TAILCALL
;
; X32-LABEL: t4:
; X32:       # %bb.0:
; X32-NEXT:    movl %edi, %eax
; X32-NEXT:    xorl %edi, %edi
; X32-NEXT:    jmpq *%rax # TAILCALL
  tail call void %x(i32 0) nounwind
  ret void
}

; FIXME: This isn't needed since x32 psABI specifies that callers must
;        zero-extend pointers passed in registers.

define void @t5(void ()* nocapture %x) nounwind ssp {
; X86-LABEL: t5:
; X86:       # %bb.0:
; X86-NEXT:    jmpl *{{[0-9]+}}(%esp) # TAILCALL
;
; X64-LABEL: t5:
; X64:       # %bb.0:
; X64-NEXT:    jmpq *%rdi # TAILCALL
;
; X32-LABEL: t5:
; X32:       # %bb.0:
; X32-NEXT:    movl %edi, %eax
; X32-NEXT:    jmpq *%rax # TAILCALL
  tail call void %x() nounwind
  ret void
}

define i32 @t6(i32 %x) nounwind ssp {
; X86-LABEL: t6:
; X86:       # %bb.0:
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    cmpl $9, %eax
; X86-NEXT:    jg .LBB5_2
; X86-NEXT:  # %bb.1: # %bb
; X86-NEXT:    decl %eax
; X86-NEXT:    movl %eax, (%esp)
; X86-NEXT:    calll t6
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
; X86-NEXT:  .LBB5_2: # %bb1
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    jmp bar # TAILCALL
;
; X64-LABEL: t6:
; X64:       # %bb.0:
; X64-NEXT:    cmpl $9, %edi
; X64-NEXT:    jg .LBB5_2
; X64-NEXT:  # %bb.1: # %bb
; X64-NEXT:    decl %edi
; X64-NEXT:    jmp t6 # TAILCALL
; X64-NEXT:  .LBB5_2: # %bb1
; X64-NEXT:    jmp bar # TAILCALL
;
; X32-LABEL: t6:
; X32:       # %bb.0:
; X32-NEXT:    cmpl $9, %edi
; X32-NEXT:    jg .LBB5_2
; X32-NEXT:  # %bb.1: # %bb
; X32-NEXT:    decl %edi
; X32-NEXT:    jmp t6 # TAILCALL
; X32-NEXT:  .LBB5_2: # %bb1
; X32-NEXT:    jmp bar # TAILCALL
  %t0 = icmp slt i32 %x, 10
  br i1 %t0, label %bb, label %bb1

bb:
  %t1 = add nsw i32 %x, -1
  %t2 = tail call i32 @t6(i32 %t1) nounwind ssp
  ret i32 %t2

bb1:
  %t3 = tail call i32 @bar(i32 %x) nounwind
  ret i32 %t3
}

declare i32 @bar(i32)

define i32 @t7(i32 %a, i32 %b, i32 %c) nounwind ssp {
; X86-LABEL: t7:
; X86:       # %bb.0:
; X86-NEXT:    jmp bar2 # TAILCALL
;
; X64-LABEL: t7:
; X64:       # %bb.0:
; X64-NEXT:    jmp bar2 # TAILCALL
;
; X32-LABEL: t7:
; X32:       # %bb.0:
; X32-NEXT:    jmp bar2 # TAILCALL
  %t0 = tail call i32 @bar2(i32 %a, i32 %b, i32 %c) nounwind
  ret i32 %t0
}

declare i32 @bar2(i32, i32, i32)

define signext i16 @t8() nounwind ssp {
; X86-LABEL: t8:
; X86:       # %bb.0: # %entry
; X86-NEXT:    jmp bar3 # TAILCALL
;
; X64-LABEL: t8:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp bar3 # TAILCALL
;
; X32-LABEL: t8:
; X32:       # %bb.0: # %entry
; X32-NEXT:    jmp bar3 # TAILCALL
entry:
  %0 = tail call signext i16 @bar3() nounwind      ; <i16> [#uses=1]
  ret i16 %0
}

declare signext i16 @bar3()

define signext i16 @t9(i32 (i32)* nocapture %x) nounwind ssp {
; X86-LABEL: t9:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    movl $0, (%esp)
; X86-NEXT:    calll *{{[0-9]+}}(%esp)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t9:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    jmpq *%rax # TAILCALL
;
; X32-LABEL: t9:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl %edi, %eax
; X32-NEXT:    xorl %edi, %edi
; X32-NEXT:    jmpq *%rax # TAILCALL
entry:
  %0 = bitcast i32 (i32)* %x to i16 (i32)*
  %1 = tail call signext i16 %0(i32 0) nounwind
  ret i16 %1
}

define void @t10() nounwind ssp {
; X86-LABEL: t10:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    calll foo4
;
; X64-LABEL: t10:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rax
; X64-NEXT:    callq foo4
;
; X32-LABEL: t10:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushq %rax
; X32-NEXT:    callq foo4
entry:
  %0 = tail call i32 @foo4() noreturn nounwind
  unreachable
}

declare i32 @foo4()

; In 32-bit mode, it's emitting a bunch of dead loads that are not being
; eliminated currently.

define i32 @t11(i32 %x, i32 %y, i32 %z.0, i32 %z.1, i32 %z.2) nounwind ssp {
; X86-LABEL: t11:
; X86:       # %bb.0: # %entry
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    je .LBB10_1
; X86-NEXT:  # %bb.2: # %bb
; X86-NEXT:    jmp foo5 # TAILCALL
; X86-NEXT:  .LBB10_1: # %bb6
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    retl
;
; X64-LABEL: t11:
; X64:       # %bb.0: # %entry
; X64-NEXT:    testl %edi, %edi
; X64-NEXT:    je .LBB10_1
; X64-NEXT:  # %bb.2: # %bb
; X64-NEXT:    jmp foo5 # TAILCALL
; X64-NEXT:  .LBB10_1: # %bb6
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    retq
;
; X32-LABEL: t11:
; X32:       # %bb.0: # %entry
; X32-NEXT:    testl %edi, %edi
; X32-NEXT:    je .LBB10_1
; X32-NEXT:  # %bb.2: # %bb
; X32-NEXT:    jmp foo5 # TAILCALL
; X32-NEXT:  .LBB10_1: # %bb6
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    retq
entry:
  %0 = icmp eq i32 %x, 0
  br i1 %0, label %bb6, label %bb

bb:
  %1 = tail call i32 @foo5(i32 %x, i32 %y, i32 %z.0, i32 %z.1, i32 %z.2) nounwind
  ret i32 %1

bb6:
  ret i32 0
}

declare i32 @foo5(i32, i32, i32, i32, i32)

%struct.t = type { i32, i32, i32, i32, i32 }

define i32 @t12(i32 %x, i32 %y, %struct.t* byval align 4 %z) nounwind ssp {
; X86-LABEL: t12:
; X86:       # %bb.0: # %entry
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    je .LBB11_1
; X86-NEXT:  # %bb.2: # %bb
; X86-NEXT:    jmp foo6 # TAILCALL
; X86-NEXT:  .LBB11_1: # %bb2
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    retl
;
; X64-LABEL: t12:
; X64:       # %bb.0: # %entry
; X64-NEXT:    testl %edi, %edi
; X64-NEXT:    je .LBB11_1
; X64-NEXT:  # %bb.2: # %bb
; X64-NEXT:    jmp foo6 # TAILCALL
; X64-NEXT:  .LBB11_1: # %bb2
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    retq
;
; X32-LABEL: t12:
; X32:       # %bb.0: # %entry
; X32-NEXT:    testl %edi, %edi
; X32-NEXT:    je .LBB11_1
; X32-NEXT:  # %bb.2: # %bb
; X32-NEXT:    jmp foo6 # TAILCALL
; X32-NEXT:  .LBB11_1: # %bb2
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    retq
entry:
  %0 = icmp eq i32 %x, 0
  br i1 %0, label %bb2, label %bb

bb:
  %1 = tail call i32 @foo6(i32 %x, i32 %y, %struct.t* byval align 4 %z) nounwind
  ret i32 %1

bb2:
  ret i32 0
}

declare i32 @foo6(i32, i32, %struct.t* byval align 4)

; rdar://r7717598
%struct.ns = type { i32, i32 }
%struct.cp = type { float, float, float, float, float }

define %struct.ns* @t13(%struct.cp* %yy) nounwind ssp {
; X86-LABEL: t13:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $28, %esp
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl 16(%eax), %ecx
; X86-NEXT:    movl %ecx, {{[0-9]+}}(%esp)
; X86-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X86-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X86-NEXT:    movsd %xmm1, {{[0-9]+}}(%esp)
; X86-NEXT:    movsd %xmm0, (%esp)
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    calll foo7
; X86-NEXT:    addl $28, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t13:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rax
; X64-NEXT:    subq $8, %rsp
; X64-NEXT:    movl 16(%rdi), %eax
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq 8(%rdi), %rdx
; X64-NEXT:    xorl %edi, %edi
; X64-NEXT:    pushq %rax
; X64-NEXT:    pushq %rdx
; X64-NEXT:    pushq %rcx
; X64-NEXT:    callq foo7
; X64-NEXT:    addq $32, %rsp
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
;
; X32-LABEL: t13:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushq %rax
; X32-NEXT:    subl $8, %esp
; X32-NEXT:    movl 16(%edi), %eax
; X32-NEXT:    movq (%edi), %rcx
; X32-NEXT:    movq 8(%edi), %rdx
; X32-NEXT:    xorl %edi, %edi
; X32-NEXT:    pushq %rax
; X32-NEXT:    pushq %rdx
; X32-NEXT:    pushq %rcx
; X32-NEXT:    callq foo7
; X32-NEXT:    addl $32, %esp
; X32-NEXT:    popq %rcx
; X32-NEXT:    retq
entry:
  %0 = tail call fastcc %struct.ns* @foo7(%struct.cp* byval align 4 %yy, i8 signext 0) nounwind
  ret %struct.ns* %0
}

; rdar://6195379
; llvm can't do sibcall for this in 32-bit mode (yet).
declare fastcc %struct.ns* @foo7(%struct.cp* byval align 4, i8 signext) nounwind ssp

%struct.__block_descriptor = type { i64, i64 }
%struct.__block_descriptor_withcopydispose = type { i64, i64, i8*, i8* }
%struct.__block_literal_1 = type { i8*, i32, i32, i8*, %struct.__block_descriptor* }
%struct.__block_literal_2 = type { i8*, i32, i32, i8*, %struct.__block_descriptor_withcopydispose*, void ()* }

define void @t14(%struct.__block_literal_2* nocapture %.block_descriptor) nounwind ssp {
; X86-LABEL: t14:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl 20(%eax), %eax
; X86-NEXT:    movl %eax, (%esp)
; X86-NEXT:    calll *12(%eax)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t14:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq 32(%rdi), %rdi
; X64-NEXT:    jmpq *16(%rdi) # TAILCALL
;
; X32-LABEL: t14:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl 20(%edi), %edi
; X32-NEXT:    movl 12(%edi), %eax
; X32-NEXT:    jmpq *%rax # TAILCALL
entry:
  %0 = getelementptr inbounds %struct.__block_literal_2, %struct.__block_literal_2* %.block_descriptor, i64 0, i32 5 ; <void ()**> [#uses=1]
  %1 = load void ()*, void ()** %0, align 8                 ; <void ()*> [#uses=2]
  %2 = bitcast void ()* %1 to %struct.__block_literal_1* ; <%struct.__block_literal_1*> [#uses=1]
  %3 = getelementptr inbounds %struct.__block_literal_1, %struct.__block_literal_1* %2, i64 0, i32 3 ; <i8**> [#uses=1]
  %4 = load i8*, i8** %3, align 8                      ; <i8*> [#uses=1]
  %5 = bitcast i8* %4 to void (i8*)*              ; <void (i8*)*> [#uses=1]
  %6 = bitcast void ()* %1 to i8*                 ; <i8*> [#uses=1]
  tail call void %5(i8* %6) nounwind
  ret void
}

; rdar://7726868
%struct.foo = type { [4 x i32] }

define void @t15(%struct.foo* noalias sret %agg.result) nounwind  {
; X86-LABEL: t15:
; X86:       # %bb.0:
; X86-NEXT:    pushl %esi
; X86-NEXT:    subl $8, %esp
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl %esi, %ecx
; X86-NEXT:    calll f
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:    addl $8, %esp
; X86-NEXT:    popl %esi
; X86-NEXT:    retl $4
;
; X64-LABEL: t15:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rbx
; X64-NEXT:    movq %rdi, %rbx
; X64-NEXT:    callq f
; X64-NEXT:    movq %rbx, %rax
; X64-NEXT:    popq %rbx
; X64-NEXT:    retq
;
; X32-LABEL: t15:
; X32:       # %bb.0:
; X32-NEXT:    pushq %rbx
; X32-NEXT:    movl %edi, %ebx
; X32-NEXT:    callq f
; X32-NEXT:    movl %ebx, %eax
; X32-NEXT:    popq %rbx
; X32-NEXT:    retq
  tail call fastcc void @f(%struct.foo* noalias sret %agg.result) nounwind
  ret void
}

declare void @f(%struct.foo* noalias sret) nounwind

define void @t16() nounwind ssp {
; X86-LABEL: t16:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    calll bar4
; X86-NEXT:    fstp %st(0)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t16:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp bar4 # TAILCALL
;
; X32-LABEL: t16:
; X32:       # %bb.0: # %entry
; X32-NEXT:    jmp bar4 # TAILCALL
entry:
  %0 = tail call double @bar4() nounwind
  ret void
}

declare double @bar4()

; rdar://6283267
define void @t17() nounwind ssp {
; X86-LABEL: t17:
; X86:       # %bb.0: # %entry
; X86-NEXT:    jmp bar5 # TAILCALL
;
; X64-LABEL: t17:
; X64:       # %bb.0: # %entry
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    jmp bar5 # TAILCALL
;
; X32-LABEL: t17:
; X32:       # %bb.0: # %entry
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    jmp bar5 # TAILCALL
entry:
  tail call void (...) @bar5() nounwind
  ret void
}

declare void @bar5(...)

; rdar://7774847
define void @t18() nounwind ssp {
; X86-LABEL: t18:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    calll bar6
; X86-NEXT:    fstp %st(0)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t18:
; X64:       # %bb.0: # %entry
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    jmp bar6 # TAILCALL
;
; X32-LABEL: t18:
; X32:       # %bb.0: # %entry
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    jmp bar6 # TAILCALL
entry:
  %0 = tail call double (...) @bar6() nounwind
  ret void
}

declare double @bar6(...)

define void @t19() alignstack(32) nounwind {
; X86-LABEL: t19:
; X86:       # %bb.0: # %entry
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-32, %esp
; X86-NEXT:    subl $32, %esp
; X86-NEXT:    calll foo
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: t19:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pushq %rbp
; X64-NEXT:    movq %rsp, %rbp
; X64-NEXT:    andq $-32, %rsp
; X64-NEXT:    subq $32, %rsp
; X64-NEXT:    callq foo
; X64-NEXT:    movq %rbp, %rsp
; X64-NEXT:    popq %rbp
; X64-NEXT:    retq
;
; X32-LABEL: t19:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushq %rbp
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    andl $-32, %esp
; X32-NEXT:    subl $32, %esp
; X32-NEXT:    callq foo
; X32-NEXT:    movl %ebp, %esp
; X32-NEXT:    popq %rbp
; X32-NEXT:    retq
entry:
  tail call void @foo() nounwind
  ret void
}

; If caller / callee calling convention mismatch then check if the return
; values are returned in the same registers.
; rdar://7874780

define double @t20(double %x) nounwind {
; X86-LABEL: t20:
; X86:       # %bb.0: # %entry
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X86-NEXT:    calll foo20
; X86-NEXT:    movsd %xmm0, (%esp)
; X86-NEXT:    fldl (%esp)
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t20:
; X64:       # %bb.0: # %entry
; X64-NEXT:    jmp foo20 # TAILCALL
;
; X32-LABEL: t20:
; X32:       # %bb.0: # %entry
; X32-NEXT:    jmp foo20 # TAILCALL
entry:
  %0 = tail call fastcc double @foo20(double %x) nounwind
  ret double %0
}

declare fastcc double @foo20(double) nounwind

; bug 28417
define fastcc void @t21_sret_to_sret(%struct.foo* noalias sret %agg.result) nounwind  {
; X86-LABEL: t21_sret_to_sret:
; X86:       # %bb.0:
; X86-NEXT:    pushl %esi
; X86-NEXT:    subl $8, %esp
; X86-NEXT:    movl %ecx, %esi
; X86-NEXT:    calll t21_f_sret
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:    addl $8, %esp
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: t21_sret_to_sret:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rbx
; X64-NEXT:    movq %rdi, %rbx
; X64-NEXT:    callq t21_f_sret
; X64-NEXT:    movq %rbx, %rax
; X64-NEXT:    popq %rbx
; X64-NEXT:    retq
;
; X32-LABEL: t21_sret_to_sret:
; X32:       # %bb.0:
; X32-NEXT:    pushq %rbx
; X32-NEXT:    movl %edi, %ebx
; X32-NEXT:    callq t21_f_sret
; X32-NEXT:    movl %ebx, %eax
; X32-NEXT:    popq %rbx
; X32-NEXT:    retq
  tail call fastcc void @t21_f_sret(%struct.foo* noalias sret %agg.result) nounwind
  ret void
}

define fastcc void @t21_sret_to_non_sret(%struct.foo* noalias sret %agg.result) nounwind  {
; X86-LABEL: t21_sret_to_non_sret:
; X86:       # %bb.0:
; X86-NEXT:    pushl %esi
; X86-NEXT:    subl $8, %esp
; X86-NEXT:    movl %ecx, %esi
; X86-NEXT:    calll t21_f_non_sret
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:    addl $8, %esp
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: t21_sret_to_non_sret:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rbx
; X64-NEXT:    movq %rdi, %rbx
; X64-NEXT:    callq t21_f_non_sret
; X64-NEXT:    movq %rbx, %rax
; X64-NEXT:    popq %rbx
; X64-NEXT:    retq
;
; X32-LABEL: t21_sret_to_non_sret:
; X32:       # %bb.0:
; X32-NEXT:    pushq %rbx
; X32-NEXT:    movl %edi, %ebx
; X32-NEXT:    callq t21_f_non_sret
; X32-NEXT:    movl %ebx, %eax
; X32-NEXT:    popq %rbx
; X32-NEXT:    retq
  tail call fastcc void @t21_f_non_sret(%struct.foo* %agg.result) nounwind
  ret void
}

define fastcc void @t21_non_sret_to_sret(%struct.foo* %agg.result) nounwind  {
; X86-LABEL: t21_non_sret_to_sret:
; X86:       # %bb.0:
; X86-NEXT:    subl $12, %esp
; X86-NEXT:    calll t21_f_sret
; X86-NEXT:    addl $12, %esp
; X86-NEXT:    retl
;
; X64-LABEL: t21_non_sret_to_sret:
; X64:       # %bb.0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    callq t21_f_sret
; X64-NEXT:    popq %rax
; X64-NEXT:    retq
;
; X32-LABEL: t21_non_sret_to_sret:
; X32:       # %bb.0:
; X32-NEXT:    pushq %rax
; X32-NEXT:    callq t21_f_sret
; X32-NEXT:    popq %rax
; X32-NEXT:    retq
  tail call fastcc void @t21_f_sret(%struct.foo* noalias sret %agg.result) nounwind
  ret void
}

declare fastcc void @t21_f_sret(%struct.foo* noalias sret) nounwind
declare fastcc void @t21_f_non_sret(%struct.foo*) nounwind
