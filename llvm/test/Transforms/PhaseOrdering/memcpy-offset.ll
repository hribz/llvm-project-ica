; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt < %s -passes=memcpyopt,instcombine -S -verify-memoryssa | FileCheck --check-prefix=CUSTOM %s
; RUN: opt < %s -O2 -S | FileCheck --check-prefix=O2 %s

; Check that we eliminate all `memcpy` calls in this function.
define void @memcpy_forward_back_with_offset(ptr %arg) {
; CUSTOM-LABEL: define void @memcpy_forward_back_with_offset(
; CUSTOM-SAME: ptr [[ARG:%.*]]) {
; CUSTOM-NEXT:    store i8 1, ptr [[ARG]], align 1
; CUSTOM-NEXT:    ret void
;
; O2-LABEL: define void @memcpy_forward_back_with_offset(
; O2-SAME: ptr nocapture writeonly [[ARG:%.*]]) local_unnamed_addr #[[ATTR0:[0-9]+]] {
; O2-NEXT:    store i8 1, ptr [[ARG]], align 1
; O2-NEXT:    ret void
;
  %i = alloca [753 x i8], align 1
  %i1 = alloca [754 x i8], align 1
  call void @llvm.memcpy.p0.p0.i64(ptr %i1, ptr %arg, i64 754, i1 false)
  %i2 = getelementptr inbounds i8, ptr %i1, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr %i, ptr %i2, i64 753, i1 false)
  store i8 1, ptr %arg, align 1
  %i3 = getelementptr inbounds i8, ptr %arg, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr %i3, ptr %i, i64 753, i1 false)
  ret void
}

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)