; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt < %s -passes=instcombine -S | FileCheck %s

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.ssub.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.smul.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)

declare void @use(i1)

; Tests from PR75360
define i1 @ckd_add_unsigned(i31 %num) {
; CHECK-LABEL: define i1 @ckd_add_unsigned(
; CHECK-SAME: i31 [[NUM:%.*]]) {
; CHECK-NEXT:    [[A2:%.*]] = icmp eq i31 [[NUM]], -1
; CHECK-NEXT:    ret i1 [[A2]]
;
  %a0 = zext i31 %num to i32
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @ckd_add_unsigned_commuted(i31 %num) {
; CHECK-LABEL: define i1 @ckd_add_unsigned_commuted(
; CHECK-SAME: i31 [[NUM:%.*]]) {
; CHECK-NEXT:    [[A2:%.*]] = icmp eq i31 [[NUM]], -1
; CHECK-NEXT:    ret i1 [[A2]]
;
  %a0 = zext i31 %num to i32
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  %a5 = or i1 %a4, %a2
  ret i1 %a5
}

define i1 @ckd_add_unsigned_imply_true(i31 %num) {
; CHECK-LABEL: define i1 @ckd_add_unsigned_imply_true(
; CHECK-SAME: i31 [[NUM:%.*]]) {
; CHECK-NEXT:    ret i1 true
;
  %a0 = zext i31 %num to i32
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp sgt i32 %a3, -1
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[A0]], -2147483647
; CHECK-NEXT:    [[A5:%.*]] = icmp sgt i32 [[TMP1]], -1
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_ssub_with_overflow_icmp(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_ssub_with_overflow_icmp(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[TMP1:%.*]] = icmp slt i32 [[A0]], 1
; CHECK-NEXT:    ret i1 [[TMP1]]
;
  %a1 = tail call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_uadd_with_overflow_icmp(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_uadd_with_overflow_icmp(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[A0]], 1
; CHECK-NEXT:    [[A5:%.*]] = icmp ult i32 [[TMP1]], 10
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp ult i32 %a3, 10
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp_eq(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_eq(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A2:%.*]] = icmp eq i32 [[A0]], 2147483647
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i32 [[A0]], 9
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[TMP1]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp eq i32 %a3, 10
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_uadd_with_overflow_icmp_ne(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_uadd_with_overflow_icmp_ne(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ne i32 [[A0]], 9
; CHECK-NEXT:    ret i1 [[TMP1]]
;
  %a1 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp ne i32 %a3, 10
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

; Negative tests
define i1 @canonicalize_or_sadd_with_overflow_icmp_mismatched_pred(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_mismatched_pred(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 [[A0]], i32 1)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp ult i32 [[A3]], 2
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp ult i32 %a3, 2
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp_non_constant1(i32 %a0, i32 %c) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_non_constant1(
; CHECK-SAME: i32 [[A0:%.*]], i32 [[C:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 [[A0]], i32 [[C]])
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], 0
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 %c)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp_non_constant2(i32 %a0, i32 %c) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_non_constant2(
; CHECK-SAME: i32 [[A0:%.*]], i32 [[C:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 [[A0]], i32 1)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], [[C]]
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, %c
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp_multiuse(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_multiuse(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 [[A0]], i32 1)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], 0
; CHECK-NEXT:    call void @use(i1 [[A4]])
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 1)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 0
  call void @use(i1 %a4)
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_sadd_with_overflow_icmp_overflow(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_sadd_with_overflow_icmp_overflow(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 [[A0]], i32 -2147483647)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], 2
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a0, i32 -2147483647)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 2
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_uadd_with_overflow_icmp_overflow(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_uadd_with_overflow_icmp_overflow(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 [[A0]], i32 3)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp ult i32 [[A3]], 2
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a0, i32 3)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp ult i32 %a3, 2
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_ssub_with_overflow_icmp_overflow(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_ssub_with_overflow_icmp_overflow(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 [[A0]], i32 -2147483648)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], -1
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a0, i32 -2147483648)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, -1
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}

define i1 @canonicalize_or_smul_with_overflow_icmp(i32 %a0) {
; CHECK-LABEL: define i1 @canonicalize_or_smul_with_overflow_icmp(
; CHECK-SAME: i32 [[A0:%.*]]) {
; CHECK-NEXT:    [[A1:%.*]] = tail call { i32, i1 } @llvm.smul.with.overflow.i32(i32 [[A0]], i32 3)
; CHECK-NEXT:    [[A2:%.*]] = extractvalue { i32, i1 } [[A1]], 1
; CHECK-NEXT:    [[A3:%.*]] = extractvalue { i32, i1 } [[A1]], 0
; CHECK-NEXT:    [[A4:%.*]] = icmp slt i32 [[A3]], 10
; CHECK-NEXT:    [[A5:%.*]] = or i1 [[A2]], [[A4]]
; CHECK-NEXT:    ret i1 [[A5]]
;
  %a1 = tail call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %a0, i32 3)
  %a2 = extractvalue { i32, i1 } %a1, 1
  %a3 = extractvalue { i32, i1 } %a1, 0
  %a4 = icmp slt i32 %a3, 10
  %a5 = or i1 %a2, %a4
  ret i1 %a5
}