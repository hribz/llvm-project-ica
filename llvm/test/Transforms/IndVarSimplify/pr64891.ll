; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 2
; RUN: opt -S -passes=indvars < %s | FileCheck %s

target datalayout = "n8:16:32:64"

; Just make sure this doesn't crash.
; SCEVExpander produces a degenerate phi node for the widened IV here,
; where the "increment" instruction folds to a poison value.
define i32 @main() {
; CHECK-LABEL: define i32 @main() {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    br label [[LOOP]]
;
entry:
  %div = sdiv i32 1, 0
  %trunc = trunc i32 %div to i16
  br label %loop

loop:
  %phi = phi i16 [ 0, %entry ], [ %or, %loop ]
  %or = or disjoint i16 %phi, %trunc
  %phi.ext = sext i16 %phi to i64
  %add.ptr = getelementptr i8, ptr null, i64 %phi.ext
  br label %loop
}