; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt < %s -passes=instcombine -S | FileCheck %s

define i1 @test_switch_with_shl_mask(i32 %a) {
; CHECK-LABEL: define i1 @test_switch_with_shl_mask(
; CHECK-SAME: i32 [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TRUNC:%.*]] = trunc i32 [[A]] to i8
; CHECK-NEXT:    switch i8 [[TRUNC]], label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i8 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i8 1, label [[SW_BB]]
; CHECK-NEXT:      i8 -128, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl i32 %a, 24
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

define i1 @test_switch_with_shl_nuw_multiuse(i32 %a) {
; CHECK-LABEL: define i1 @test_switch_with_shl_nuw_multiuse(
; CHECK-SAME: i32 [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B:%.*]] = shl nuw i32 [[A]], 24
; CHECK-NEXT:    call void @use(i32 [[B]])
; CHECK-NEXT:    switch i32 [[A]], label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i32 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i32 1, label [[SW_BB]]
; CHECK-NEXT:      i32 128, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl nuw i32 %a, 24
  call void @use(i32 %b)
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

define i1 @test_switch_with_shl_nsw_multiuse(i32 %a) {
; CHECK-LABEL: define i1 @test_switch_with_shl_nsw_multiuse(
; CHECK-SAME: i32 [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B:%.*]] = shl nsw i32 [[A]], 24
; CHECK-NEXT:    call void @use(i32 [[B]])
; CHECK-NEXT:    switch i32 [[A]], label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i32 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i32 1, label [[SW_BB]]
; CHECK-NEXT:      i32 -128, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl nsw i32 %a, 24
  call void @use(i32 %b)
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

; Negative tests

define i1 @test_switch_with_shl_mask_multiuse(i32 %a) {
; CHECK-LABEL: define i1 @test_switch_with_shl_mask_multiuse(
; CHECK-SAME: i32 [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B:%.*]] = shl i32 [[A]], 24
; CHECK-NEXT:    call void @use(i32 [[B]])
; CHECK-NEXT:    switch i32 [[B]], label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i32 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i32 16777216, label [[SW_BB]]
; CHECK-NEXT:      i32 -2147483648, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl i32 %a, 24
  call void @use(i32 %b)
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

define i1 @test_switch_with_shl_mask_unknown_shamt(i32 %a, i32 %shamt) {
; CHECK-LABEL: define i1 @test_switch_with_shl_mask_unknown_shamt(
; CHECK-SAME: i32 [[A:%.*]], i32 [[SHAMT:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[B:%.*]] = shl i32 [[A]], [[SHAMT]]
; CHECK-NEXT:    switch i32 [[B]], label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i32 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i32 16777216, label [[SW_BB]]
; CHECK-NEXT:      i32 -2147483648, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl i32 %a, %shamt
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

define i1 @test_switch_with_shl_mask_poison(i32 %a) {
; CHECK-LABEL: define i1 @test_switch_with_shl_mask_poison(
; CHECK-SAME: i32 [[A:%.*]]) {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    switch i32 poison, label [[SW_DEFAULT:%.*]] [
; CHECK-NEXT:      i32 0, label [[SW_BB:%.*]]
; CHECK-NEXT:      i32 16777216, label [[SW_BB]]
; CHECK-NEXT:      i32 -2147483648, label [[SW_BB]]
; CHECK-NEXT:    ]
; CHECK:       sw.bb:
; CHECK-NEXT:    ret i1 true
; CHECK:       sw.default:
; CHECK-NEXT:    ret i1 false
;
entry:
  %b = shl i32 %a, 32
  switch i32 %b, label %sw.default [
  i32 0, label %sw.bb
  i32 16777216, label %sw.bb
  i32 2147483648, label %sw.bb
  ]

sw.bb:
  ret i1 true
sw.default:
  ret i1 false
}

declare void @use(i32)