; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-linux | FileCheck %s

define <4 x float> @foo(ptr %p, <4 x float> %x) nounwind {
; CHECK-LABEL: foo:
; CHECK:       # %bb.0:
; CHECK-NEXT:    mulps (%rdi), %xmm0
; CHECK-NEXT:    retq
  %t = load <4 x float>, ptr %p
  %z = fmul <4 x float> %t, %x
  ret <4 x float> %z
}

define <2 x double> @bar(ptr %p, <2 x double> %x) nounwind {
; CHECK-LABEL: bar:
; CHECK:       # %bb.0:
; CHECK-NEXT:    mulpd (%rdi), %xmm0
; CHECK-NEXT:    retq
  %t = load <2 x double>, ptr %p
  %z = fmul <2 x double> %t, %x
  ret <2 x double> %z
}