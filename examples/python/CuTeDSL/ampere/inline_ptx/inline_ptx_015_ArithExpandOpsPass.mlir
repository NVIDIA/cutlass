!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
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
  func.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) -> i32 attributes {llvm.emit_c_interface} {
    %c1_i32 = arith.constant 1 : i32
    %c32_i32 = arith.constant 32 : i32
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %1 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c32_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%c1_i32, %c1_i32, %c1_i32), stream = %0) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %2 = cuda.launch_ex @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0<%1> (%arg0, %arg1, %arg2, %arg3) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> !cuda.result
    %3 = cuda.cast %2 : !cuda.result -> i32
    cuda.return_if_error %3 : i32
    return %c0_i32 : i32
  }
}
