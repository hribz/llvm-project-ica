; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv64 -mattr=+v,+d -mattr=+d -O0 < %s \
; RUN:    | FileCheck --check-prefix=SPILL-O0 %s
; RUN: llc -mtriple=riscv64 -mattr=+v,+d -mattr=+d -O2 < %s \
; RUN:    | FileCheck --check-prefix=SPILL-O2 %s
; RUN: llc -mtriple=riscv64 -mattr=+v,+d -mattr=+d -riscv-v-vector-bits-max=128 -O2 < %s \
; RUN:    | FileCheck --check-prefix=SPILL-O2-VLEN128 %s


@.str = private unnamed_addr constant [6 x i8] c"hello\00", align 1

define <vscale x 1 x double> @foo(<vscale x 1 x double> %a, <vscale x 1 x double> %b, <vscale x 1 x double> %c, i64 %gvl) nounwind
; SPILL-O0-LABEL: foo:
; SPILL-O0:       # %bb.0:
; SPILL-O0-NEXT:    addi sp, sp, -48
; SPILL-O0-NEXT:    sd ra, 40(sp) # 8-byte Folded Spill
; SPILL-O0-NEXT:    csrr a1, vlenb
; SPILL-O0-NEXT:    slli a1, a1, 1
; SPILL-O0-NEXT:    sub sp, sp, a1
; SPILL-O0-NEXT:    sd a0, 16(sp) # 8-byte Folded Spill
; SPILL-O0-NEXT:    vmv1r.v v10, v9
; SPILL-O0-NEXT:    vmv1r.v v9, v8
; SPILL-O0-NEXT:    csrr a1, vlenb
; SPILL-O0-NEXT:    add a1, sp, a1
; SPILL-O0-NEXT:    addi a1, a1, 32
; SPILL-O0-NEXT:    vs1r.v v9, (a1) # Unknown-size Folded Spill
; SPILL-O0-NEXT:    # implicit-def: $v8
; SPILL-O0-NEXT:    vsetvli zero, a0, e64, m1, tu, ma
; SPILL-O0-NEXT:    vfadd.vv v8, v9, v10
; SPILL-O0-NEXT:    addi a0, sp, 32
; SPILL-O0-NEXT:    vs1r.v v8, (a0) # Unknown-size Folded Spill
; SPILL-O0-NEXT:    lui a0, %hi(.L.str)
; SPILL-O0-NEXT:    addi a0, a0, %lo(.L.str)
; SPILL-O0-NEXT:    call puts
; SPILL-O0-NEXT:    addi a1, sp, 32
; SPILL-O0-NEXT:    vl1r.v v10, (a1) # Unknown-size Folded Reload
; SPILL-O0-NEXT:    csrr a1, vlenb
; SPILL-O0-NEXT:    add a1, sp, a1
; SPILL-O0-NEXT:    addi a1, a1, 32
; SPILL-O0-NEXT:    vl1r.v v9, (a1) # Unknown-size Folded Reload
; SPILL-O0-NEXT:    # kill: def $x11 killed $x10
; SPILL-O0-NEXT:    ld a0, 16(sp) # 8-byte Folded Reload
; SPILL-O0-NEXT:    # implicit-def: $v8
; SPILL-O0-NEXT:    vsetvli zero, a0, e64, m1, tu, ma
; SPILL-O0-NEXT:    vfadd.vv v8, v9, v10
; SPILL-O0-NEXT:    csrr a0, vlenb
; SPILL-O0-NEXT:    slli a0, a0, 1
; SPILL-O0-NEXT:    add sp, sp, a0
; SPILL-O0-NEXT:    ld ra, 40(sp) # 8-byte Folded Reload
; SPILL-O0-NEXT:    addi sp, sp, 48
; SPILL-O0-NEXT:    ret
;
; SPILL-O2-LABEL: foo:
; SPILL-O2:       # %bb.0:
; SPILL-O2-NEXT:    addi sp, sp, -32
; SPILL-O2-NEXT:    sd ra, 24(sp) # 8-byte Folded Spill
; SPILL-O2-NEXT:    sd s0, 16(sp) # 8-byte Folded Spill
; SPILL-O2-NEXT:    csrr a1, vlenb
; SPILL-O2-NEXT:    slli a1, a1, 1
; SPILL-O2-NEXT:    sub sp, sp, a1
; SPILL-O2-NEXT:    mv s0, a0
; SPILL-O2-NEXT:    addi a1, sp, 16
; SPILL-O2-NEXT:    vs1r.v v8, (a1) # Unknown-size Folded Spill
; SPILL-O2-NEXT:    vsetvli zero, a0, e64, m1, ta, ma
; SPILL-O2-NEXT:    vfadd.vv v9, v8, v9
; SPILL-O2-NEXT:    csrr a0, vlenb
; SPILL-O2-NEXT:    add a0, sp, a0
; SPILL-O2-NEXT:    addi a0, a0, 16
; SPILL-O2-NEXT:    vs1r.v v9, (a0) # Unknown-size Folded Spill
; SPILL-O2-NEXT:    lui a0, %hi(.L.str)
; SPILL-O2-NEXT:    addi a0, a0, %lo(.L.str)
; SPILL-O2-NEXT:    call puts
; SPILL-O2-NEXT:    csrr a0, vlenb
; SPILL-O2-NEXT:    add a0, sp, a0
; SPILL-O2-NEXT:    addi a0, a0, 16
; SPILL-O2-NEXT:    vl1r.v v8, (a0) # Unknown-size Folded Reload
; SPILL-O2-NEXT:    addi a0, sp, 16
; SPILL-O2-NEXT:    vl1r.v v9, (a0) # Unknown-size Folded Reload
; SPILL-O2-NEXT:    vsetvli zero, s0, e64, m1, ta, ma
; SPILL-O2-NEXT:    vfadd.vv v8, v9, v8
; SPILL-O2-NEXT:    csrr a0, vlenb
; SPILL-O2-NEXT:    slli a0, a0, 1
; SPILL-O2-NEXT:    add sp, sp, a0
; SPILL-O2-NEXT:    ld ra, 24(sp) # 8-byte Folded Reload
; SPILL-O2-NEXT:    ld s0, 16(sp) # 8-byte Folded Reload
; SPILL-O2-NEXT:    addi sp, sp, 32
; SPILL-O2-NEXT:    ret
;
; SPILL-O2-VLEN128-LABEL: foo:
; SPILL-O2-VLEN128:       # %bb.0:
; SPILL-O2-VLEN128-NEXT:    addi sp, sp, -32
; SPILL-O2-VLEN128-NEXT:    sd ra, 24(sp) # 8-byte Folded Spill
; SPILL-O2-VLEN128-NEXT:    sd s0, 16(sp) # 8-byte Folded Spill
; SPILL-O2-VLEN128-NEXT:    addi sp, sp, -32
; SPILL-O2-VLEN128-NEXT:    mv s0, a0
; SPILL-O2-VLEN128-NEXT:    addi a1, sp, 16
; SPILL-O2-VLEN128-NEXT:    vs1r.v v8, (a1) # Unknown-size Folded Spill
; SPILL-O2-VLEN128-NEXT:    vsetvli zero, a0, e64, m1, ta, ma
; SPILL-O2-VLEN128-NEXT:    vfadd.vv v9, v8, v9
; SPILL-O2-VLEN128-NEXT:    addi a0, sp, 32
; SPILL-O2-VLEN128-NEXT:    vs1r.v v9, (a0) # Unknown-size Folded Spill
; SPILL-O2-VLEN128-NEXT:    lui a0, %hi(.L.str)
; SPILL-O2-VLEN128-NEXT:    addi a0, a0, %lo(.L.str)
; SPILL-O2-VLEN128-NEXT:    call puts
; SPILL-O2-VLEN128-NEXT:    addi a0, sp, 32
; SPILL-O2-VLEN128-NEXT:    vl1r.v v8, (a0) # Unknown-size Folded Reload
; SPILL-O2-VLEN128-NEXT:    addi a0, sp, 16
; SPILL-O2-VLEN128-NEXT:    vl1r.v v9, (a0) # Unknown-size Folded Reload
; SPILL-O2-VLEN128-NEXT:    vsetvli zero, s0, e64, m1, ta, ma
; SPILL-O2-VLEN128-NEXT:    vfadd.vv v8, v9, v8
; SPILL-O2-VLEN128-NEXT:    addi sp, sp, 32
; SPILL-O2-VLEN128-NEXT:    ld ra, 24(sp) # 8-byte Folded Reload
; SPILL-O2-VLEN128-NEXT:    ld s0, 16(sp) # 8-byte Folded Reload
; SPILL-O2-VLEN128-NEXT:    addi sp, sp, 32
; SPILL-O2-VLEN128-NEXT:    ret
{
   %x = call <vscale x 1 x double> @llvm.riscv.vfadd.nxv1f64.nxv1f64(<vscale x 1 x double> undef, <vscale x 1 x double> %a, <vscale x 1 x double> %b, i64 7, i64 %gvl)
   %call = call signext i32 @puts(ptr @.str)
   %z = call <vscale x 1 x double> @llvm.riscv.vfadd.nxv1f64.nxv1f64(<vscale x 1 x double> undef, <vscale x 1 x double> %a, <vscale x 1 x double> %x, i64 7, i64 %gvl)
   ret <vscale x 1 x double> %z
}

declare <vscale x 1 x double> @llvm.riscv.vfadd.nxv1f64.nxv1f64(<vscale x 1 x double> %passthru, <vscale x 1 x double> %a, <vscale x 1 x double> %b, i64, i64 %gvl)
declare i32 @puts(ptr);