; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc --mtriple=loongarch64 --mattr=+lasx < %s | FileCheck %s

declare <32 x i8> @llvm.loongarch.lasx.xvxor.v(<32 x i8>, <32 x i8>)

define <32 x i8> @lasx_xvxor_v(<32 x i8> %va, <32 x i8> %vb) nounwind {
; CHECK-LABEL: lasx_xvxor_v:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xvxor.v $xr0, $xr0, $xr1
; CHECK-NEXT:    ret
entry:
  %res = call <32 x i8> @llvm.loongarch.lasx.xvxor.v(<32 x i8> %va, <32 x i8> %vb)
  ret <32 x i8> %res
}