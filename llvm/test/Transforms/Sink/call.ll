; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -passes=sink -S | FileCheck %s

declare i32 @f_load_global() nounwind willreturn readonly
declare i32 @f_load_global_throwable() willreturn readonly
declare i32 @f_load_global_may_not_return() nounwind readonly
declare i32 @f_load_arg(ptr) nounwind willreturn readonly argmemonly
declare void @f_store_global(i32) nounwind willreturn
declare void @f_store_arg(ptr) nounwind willreturn argmemonly
declare void @f_readonly_arg(ptr readonly, ptr) nounwind willreturn argmemonly
declare i32 @f_readnone(i32) nounwind willreturn readnone

@A = external global i32
@B = external global i32

; Sink readonly call if no stores are in the way.
;
define i32 @test_sink_no_stores(i1 %z) {
; CHECK-LABEL: @test_sink_no_stores(
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_global()
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_global()
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_throwable_no_stores(i1 %z) {
; CHECK-LABEL: @test_throwable_no_stores(
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_global_throwable()
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_global_throwable()
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_may_not_return_no_stores(i1 %z) {
; CHECK-LABEL: @test_may_not_return_no_stores(
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_global_may_not_return()
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_global_may_not_return()
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_sink_argmem_store(i1 %z) {
; CHECK-LABEL: @test_sink_argmem_store(
; CHECK-NEXT:    store i32 0, ptr @B, align 4
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_arg(ptr @A)
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_arg(ptr @A)
  store i32 0, ptr @B
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_sink_argmem_call(i1 %z) {
; CHECK-LABEL: @test_sink_argmem_call(
; CHECK-NEXT:    call void @f_store_arg(ptr @B)
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_arg(ptr @A)
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_arg(ptr @A)
  call void @f_store_arg(ptr @B)
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_sink_argmem_multiple(i1 %z) {
; CHECK-LABEL: @test_sink_argmem_multiple(
; CHECK-NEXT:    call void @f_readonly_arg(ptr @A, ptr @B)
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_arg(ptr @A)
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_arg(ptr @A)
  call void @f_readonly_arg(ptr @A, ptr @B)
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

; But don't sink if there is a store.
define i32 @test_nosink_store(i1 %z) {
; CHECK-LABEL: @test_nosink_store(
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_global()
; CHECK-NEXT:    store i32 0, ptr @A, align 4
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_global()
  store i32 0, ptr @A
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

define i32 @test_nosink_call(i1 %z) {
; CHECK-LABEL: @test_nosink_call(
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_load_global()
; CHECK-NEXT:    call void @f_store_global(i32 0)
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_load_global()
  call void @f_store_global(i32 0)
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}

; readnone calls are sunk across stores.
define i32 @test_sink_readnone(i1 %z) {
; CHECK-LABEL: @test_sink_readnone(
; CHECK-NEXT:    store i32 0, ptr @A, align 4
; CHECK-NEXT:    br i1 [[Z:%.*]], label [[TRUE:%.*]], label [[FALSE:%.*]]
; CHECK:       true:
; CHECK-NEXT:    [[L:%.*]] = call i32 @f_readnone(i32 0)
; CHECK-NEXT:    ret i32 [[L]]
; CHECK:       false:
; CHECK-NEXT:    ret i32 0
;
  %l = call i32 @f_readnone(i32 0)
  store i32 0, ptr @A
  br i1 %z, label %true, label %false
true:
  ret i32 %l
false:
  ret i32 0
}