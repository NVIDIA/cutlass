!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
      %c-1_i32 = arith.constant -1 : i32
      %c10_i32 = arith.constant 10 : i32
      %0 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %1 = arith.cmpi slt, %0, %c10_i32 : i32
      %2 = nvvm.vote.ballot.sync %c-1_i32, %1 : i32
      %3 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %1, %c-1_i32 : (i1, i32) -> i1
      %4 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %1, %c-1_i32 : (i1, i32) -> i1
      %5 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %1, %c-1_i32 : (i1, i32) -> i1
      %coord = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg0, %coord, %2) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %6 = arith.extui %3 : i1 to i8
      cute.memref.store(%arg1, %coord, %6) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %7 = arith.extui %4 : i1 to i8
      cute.memref.store(%arg2, %coord, %7) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %8 = arith.extui %5 : i1 to i8
      cute.memref.store(%arg3, %coord, %8) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      return
    }
  }
  func.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {llvm.emit_c_interface} {
    %c1 = arith.constant 1 : index
    %c32 = arith.constant 32 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 blocks in (%c1, %c1, %c1) threads in (%c32, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%arg0 : !memref_gmem_i32_, %arg1 : !memref_gmem_i8_, %arg2 : !memref_gmem_i8_, %arg3 : !memref_gmem_i8_) {use_pdl = false}
    return
  }
}
