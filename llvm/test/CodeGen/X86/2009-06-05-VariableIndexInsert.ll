; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-- -mattr=+sse2 | FileCheck %s -check-prefix=X86
; RUN: llc < %s -mtriple=x86_64-- -mattr=+sse2 | FileCheck %s -check-prefix=X64

define <2 x i64> @_mm_insert_epi16(<2 x i64> %a, i32 %b, i32 %imm) nounwind readnone {
; X86-LABEL: _mm_insert_epi16:
; X86:       # %bb.0: # %entry
; X86-NEXT:    pushl %ebp
; X86-NEXT:    movl %esp, %ebp
; X86-NEXT:    andl $-16, %esp
; X86-NEXT:    subl $32, %esp
; X86-NEXT:    movl 12(%ebp), %eax
; X86-NEXT:    movzwl 8(%ebp), %ecx
; X86-NEXT:    andl $7, %eax
; X86-NEXT:    movaps %xmm0, (%esp)
; X86-NEXT:    movw %cx, (%esp,%eax,2)
; X86-NEXT:    movaps (%esp), %xmm0
; X86-NEXT:    movl %ebp, %esp
; X86-NEXT:    popl %ebp
; X86-NEXT:    retl
;
; X64-LABEL: _mm_insert_epi16:
; X64:       # %bb.0: # %entry
; X64-NEXT:    # kill: def $esi killed $esi def $rsi
; X64-NEXT:    andl $7, %esi
; X64-NEXT:    movaps %xmm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movw %di, -24(%rsp,%rsi,2)
; X64-NEXT:    movaps -{{[0-9]+}}(%rsp), %xmm0
; X64-NEXT:    retq
entry:
	%conv = bitcast <2 x i64> %a to <8 x i16>		; <<8 x i16>> [#uses=1]
	%conv2 = trunc i32 %b to i16		; <i16> [#uses=1]
	%and = and i32 %imm, 7		; <i32> [#uses=1]
	%vecins = insertelement <8 x i16> %conv, i16 %conv2, i32 %and		; <<8 x i16>> [#uses=1]
	%conv6 = bitcast <8 x i16> %vecins to <2 x i64>		; <<2 x i64>> [#uses=1]
	ret <2 x i64> %conv6
}