!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_100a">] {
    llvm.mlir.global external @__dynamic_shmem__0() {addr_space = 3 : i32, alignment = 1024 : i64, dso_local} : !llvm.array<0 x i8>
    llvm.func @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !llvm.struct<(i1, i1, i1)>, %arg1: !llvm.ptr {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg3: !llvm.ptr {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, %arg4: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg5: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = llvm.mlir.constant(8 : i32) : i32
      %1 = llvm.mlir.constant(dense<0> : vector<4xi32>) : vector<4xi32>
      %2 = llvm.mlir.constant(2048 : i32) : i32
      %3 = llvm.mlir.constant(1024 : i32) : i32
      %4 = llvm.mlir.constant(16384 : i32) : i32
      %5 = llvm.mlir.constant(8192 : i32) : i32
      %6 = llvm.mlir.constant(0 : i8) : i8
      %7 = llvm.mlir.constant(2 : i8) : i8
      %8 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
      %9 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
      %10 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<()>)>
      %11 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
      %12 = llvm.mlir.constant(6 : i32) : i32
      %13 = llvm.mlir.addressof @__dynamic_shmem__0 : !llvm.ptr<3>
      %14 = llvm.mlir.constant(31 : i32) : i32
      %15 = llvm.mlir.constant(-1 : i32) : i32
      %16 = llvm.mlir.constant(false) : i1
      %17 = llvm.mlir.constant(32 : i32) : i32
      %18 = llvm.mlir.constant(128 : i32) : i32
      %19 = llvm.mlir.constant(-128 : i32) : i32
      %20 = llvm.mlir.constant(0 : i32) : i32
      %21 = llvm.mlir.constant(512 : i32) : i32
      %22 = llvm.mlir.constant(256 : i32) : i32
      %23 = llvm.mlir.constant(128 : i64) : i64
      %24 = llvm.mlir.constant(2097152 : i32) : i32
      %25 = llvm.mlir.constant(32 : i64) : i64
      %26 = llvm.mlir.constant(true) : i1
      %27 = llvm.mlir.constant(10000000 : i32) : i32
      %28 = llvm.mlir.constant(4 : i32) : i32
      %29 = llvm.mlir.constant(2 : i32) : i32
      %30 = llvm.mlir.constant(49152 : i32) : i32
      %31 = llvm.mlir.constant(138412048 : i32) : i32
      %32 = llvm.mlir.constant(13 : i32) : i32
      %33 = llvm.mlir.constant(14 : i32) : i32
      %34 = llvm.mlir.constant(127 : i32) : i32
      %35 = llvm.mlir.constant(64 : i32) : i32
      %36 = llvm.mlir.constant(1 : i32) : i32
      %37 = llvm.alloca %35 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %38 = llvm.alloca %35 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %39 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %40 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %41 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %42 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %43 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %44 = llvm.mul %40, %42 : i32
      %45 = llvm.add %39, %44 : i32
      %46 = llvm.mul %41, %42 : i32
      %47 = llvm.mul %46, %43 : i32
      %48 = llvm.add %45, %47 : i32
      %49 = llvm.sdiv %48, %17 : i32
      %50 = llvm.mul %49, %17 : i32
      %51 = llvm.icmp "ne" %48, %50 : i32
      %52 = llvm.icmp "slt" %48, %20 : i32
      %53 = llvm.icmp "ne" %52, %16 : i1
      %54 = llvm.and %51, %53 : i1
      %55 = llvm.add %49, %15 : i32
      %56 = llvm.select %54, %55, %49 : i1, i32
      %57 = nvvm.shfl.sync  idx %15, %56, %20, %14 : i32 -> i32
      %58 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %59 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %60 = llvm.getelementptr %13[88] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
      %61 = llvm.getelementptr %13[64] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
      %62 = llvm.getelementptr %13[80] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
      %63 = llvm.ptrtoint %60 : !llvm.ptr<3> to i32
      %64 = llvm.add %63, %34 : i32
      %65 = llvm.and %64, %19 : i32
      %66 = llvm.sext %65 : i32 to i64
      %67 = llvm.inttoptr %66 : i64 to !llvm.ptr<3>
      %68 = llvm.getelementptr %67[65536] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
      %69 = llvm.icmp "eq" %57, %20 : i32
      llvm.cond_br %69, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      nvvm.tcgen05.alloc %62, %21 : !llvm.ptr<3>, i32
      llvm.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      llvm.cond_br %69, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      llvm.inline_asm has_side_effects asm_dialect = att "prefetch.tensormap [$0];", "l" %arg1 : (!llvm.ptr) -> ()
      llvm.inline_asm has_side_effects asm_dialect = att "prefetch.tensormap [$0];", "l" %arg3 : (!llvm.ptr) -> ()
      llvm.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      llvm.cond_br %69, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      nvvm.mbarrier.init.shared %13, %36 : !llvm.ptr<3>, i32
      %70 = llvm.getelementptr %13[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %70, %36 : !llvm.ptr<3>, i32
      %71 = llvm.getelementptr %13[2] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %71, %36 : !llvm.ptr<3>, i32
      %72 = llvm.getelementptr %13[3] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %72, %36 : !llvm.ptr<3>, i32
      llvm.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %73 = llvm.getelementptr %13[4] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      llvm.cond_br %69, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      nvvm.mbarrier.init.shared %73, %36 : !llvm.ptr<3>, i32
      %74 = llvm.getelementptr %13[5] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %74, %36 : !llvm.ptr<3>, i32
      %75 = llvm.getelementptr %13[6] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %75, %36 : !llvm.ptr<3>, i32
      %76 = llvm.getelementptr %13[7] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.init.shared %76, %36 : !llvm.ptr<3>, i32
      llvm.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %20 : (i32) -> ()
      nvvm.barrier
      llvm.cond_br %69, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      nvvm.mbarrier.init.shared %61, %36 : !llvm.ptr<3>, i32
      llvm.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %77 = llvm.getelementptr %61[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      llvm.cond_br %69, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      nvvm.mbarrier.init.shared %77, %18 : !llvm.ptr<3>, i32
      llvm.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %20 : (i32) -> ()
      nvvm.barrier
      %78 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
      %79 = llvm.extractvalue %78[0, 0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %80 = llvm.extractvalue %78[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %81 = llvm.select %26, %15, %36 : i1, i32
      %82 = llvm.add %81, %79 : i32
      %83 = llvm.sdiv %82, %18 : i32
      %84 = llvm.add %83, %36 : i32
      %85 = llvm.sub %20, %79 : i32
      %86 = llvm.sdiv %85, %18 : i32
      %87 = llvm.sub %20, %86 : i32
      %88 = llvm.icmp "slt" %79, %20 : i32
      %89 = llvm.icmp "sgt" %79, %20 : i32
      %90 = llvm.and %88, %16 : i1
      %91 = llvm.and %89, %26 : i1
      %92 = llvm.or %90, %91 : i1
      %93 = llvm.select %92, %84, %87 : i1, i32
      %94 = llvm.add %81, %80 : i32
      %95 = llvm.sdiv %94, %35 : i32
      %96 = llvm.add %95, %36 : i32
      %97 = llvm.sub %20, %80 : i32
      %98 = llvm.sdiv %97, %35 : i32
      %99 = llvm.sub %20, %98 : i32
      %100 = llvm.icmp "slt" %80, %20 : i32
      %101 = llvm.icmp "sgt" %80, %20 : i32
      %102 = llvm.and %100, %16 : i1
      %103 = llvm.and %101, %26 : i1
      %104 = llvm.or %102, %103 : i1
      %105 = llvm.select %104, %96, %99 : i1, i32
      %106 = llvm.insertvalue %93, %11[0] : !llvm.struct<(i32, i32)> 
      %107 = llvm.insertvalue %105, %106[1] : !llvm.struct<(i32, i32)> 
      %108 = llvm.insertvalue %107, %10[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %109 = llvm.extractvalue %108[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %110 = llvm.mul %58, %18 : i32
      %111 = llvm.mul %59, %22 : i32
      %112 = llvm.extractvalue %arg5[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %113 = llvm.extractvalue %112[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %114 = llvm.extractvalue %112[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %115 = llvm.extractvalue %112[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %116 = llvm.add %81, %113 : i32
      %117 = llvm.sdiv %116, %18 : i32
      %118 = llvm.add %117, %36 : i32
      %119 = llvm.sub %20, %113 : i32
      %120 = llvm.sdiv %119, %18 : i32
      %121 = llvm.sub %20, %120 : i32
      %122 = llvm.icmp "slt" %113, %20 : i32
      %123 = llvm.icmp "sgt" %113, %20 : i32
      %124 = llvm.and %122, %16 : i1
      %125 = llvm.and %123, %26 : i1
      %126 = llvm.or %124, %125 : i1
      %127 = llvm.select %126, %118, %121 : i1, i32
      %128 = llvm.mul %115, %23 : i64
      %129 = llvm.add %81, %114 : i32
      %130 = llvm.sdiv %129, %22 : i32
      %131 = llvm.add %130, %36 : i32
      %132 = llvm.sub %20, %114 : i32
      %133 = llvm.sdiv %132, %22 : i32
      %134 = llvm.sub %20, %133 : i32
      %135 = llvm.icmp "slt" %114, %20 : i32
      %136 = llvm.icmp "sgt" %114, %20 : i32
      %137 = llvm.and %135, %16 : i1
      %138 = llvm.and %136, %26 : i1
      %139 = llvm.or %137, %138 : i1
      %140 = llvm.select %139, %131, %134 : i1, i32
      %141 = llvm.insertvalue %127, %11[0] : !llvm.struct<(i32, i32)> 
      %142 = llvm.insertvalue %140, %141[1] : !llvm.struct<(i32, i32)> 
      %143 = llvm.insertvalue %115, %9[0] : !llvm.struct<(i64, i64)> 
      %144 = llvm.insertvalue %128, %143[1] : !llvm.struct<(i64, i64)> 
      %145 = llvm.insertvalue %142, %8[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %146 = llvm.insertvalue %144, %145[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %147 = llvm.extractvalue %146[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %148 = llvm.sext %58 : i32 to i64
      %149 = llvm.mul %148, %128 : i64
      %150 = llvm.sext %111 : i32 to i64
      %151 = llvm.add %149, %150 : i64
      %152 = llvm.extractvalue %arg5[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %153 = llvm.getelementptr %152[%151] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      %154 = llvm.ptrtoint %67 : !llvm.ptr<3> to i32
      %155 = llvm.lshr %154, %28 : i32
      %156 = nvvm.mma_smem_desc(%155, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      %157 = llvm.ptrtoint %68 : !llvm.ptr<3> to i32
      %158 = llvm.lshr %157, %28 : i32
      %159 = nvvm.mma_smem_desc(%158, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      nvvm.barrier id = %36 number_of_threads = %18
      %160 = llvm.load %62 : !llvm.ptr<3> -> i32
      %161 = llvm.sdiv %39, %17 : i32
      %162 = llvm.mul %161, %24 : i32
      %163 = llvm.add %160, %162 : i32
      %164 = llvm.mul %147, %25 : i64
      %165 = llvm.srem %39, %17 : i32
      %166 = llvm.sext %165 : i32 to i64
      %167 = llvm.mul %166, %147 : i64
      %168 = llvm.sext %161 : i32 to i64
      %169 = llvm.mul %168, %164 : i64
      %170 = llvm.add %167, %169 : i64
      %171 = llvm.getelementptr %153[%170] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      llvm.cond_br %69, ^bb13, ^bb107
    ^bb13:  // pred: ^bb12
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %77, %36, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %172 = llvm.getelementptr %arg1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %173 = llvm.getelementptr %arg3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %174 = llvm.icmp "slt" %109, %29 : i32
      %175 = llvm.select %174, %109, %29 : i1, i32
      llvm.br ^bb14(%20, %20, %36, %20 : i32, i32, i32, i32)
    ^bb14(%176: i32, %177: i32, %178: i32, %179: i32):  // 2 preds: ^bb13, ^bb31
      %180 = llvm.icmp "slt" %176, %175 : i32
      llvm.cond_br %180, ^bb15, ^bb32
    ^bb15:  // pred: ^bb14
      %181 = llvm.getelementptr %73[%177] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %181, %178, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %182 = nvvm.elect.sync -> i1
      llvm.cond_br %182, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %183 = llvm.getelementptr %13[%177] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %183, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %184 = llvm.add %177, %36 : i32
      %185 = llvm.add %179, %36 : i32
      %186 = llvm.icmp "eq" %184, %28 : i32
      %187 = llvm.select %186, %20, %184 : i1, i32
      llvm.cond_br %186, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %188 = llvm.xor %178, %36 : i32
      llvm.br ^bb20(%188 : i32)
    ^bb19:  // pred: ^bb17
      llvm.br ^bb20(%178 : i32)
    ^bb20(%189: i32):  // 2 preds: ^bb18, ^bb19
      llvm.br ^bb21
    ^bb21:  // pred: ^bb20
      %190 = llvm.mul %179, %35 : i32
      %191 = llvm.mul %177, %5 : i32
      %192 = llvm.getelementptr %67[%191] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %193 = llvm.getelementptr %13[%177] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb22(%20 : i32)
    ^bb22(%194: i32):  // 2 preds: ^bb21, ^bb25
      %195 = llvm.icmp "slt" %194, %36 : i32
      llvm.cond_br %195, ^bb23, ^bb26 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %196 = nvvm.elect.sync -> i1
      llvm.cond_br %196, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      nvvm.cp.async.bulk.tensor.shared.cluster.global %192, %172, %193, box[%190, %110] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %197 = llvm.add %194, %36 : i32
      llvm.br ^bb22(%197 : i32)
    ^bb26:  // pred: ^bb22
      %198 = llvm.mul %177, %4 : i32
      %199 = llvm.getelementptr %68[%198] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb27(%20 : i32)
    ^bb27(%200: i32):  // 2 preds: ^bb26, ^bb30
      %201 = llvm.icmp "slt" %200, %36 : i32
      llvm.cond_br %201, ^bb28, ^bb31 {llvm.loop_annotation = #loop_annotation}
    ^bb28:  // pred: ^bb27
      %202 = nvvm.elect.sync -> i1
      llvm.cond_br %202, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      nvvm.cp.async.bulk.tensor.shared.cluster.global %199, %173, %193, box[%190, %111] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %203 = llvm.add %200, %36 : i32
      llvm.br ^bb27(%203 : i32)
    ^bb31:  // pred: ^bb27
      %204 = llvm.add %176, %36 : i32
      llvm.br ^bb14(%204, %187, %189, %185 : i32, i32, i32, i32)
    ^bb32:  // pred: ^bb14
      llvm.br ^bb33(%20, %179, %177, %178, %20, %20, %arg0 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb33(%205: i32, %206: i32, %207: i32, %208: i32, %209: i32, %210: i32, %211: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb32, ^bb103
      %212 = llvm.icmp "slt" %205, %109 : i32
      llvm.cond_br %212, ^bb34, ^bb104
    ^bb34:  // pred: ^bb33
      %213 = llvm.add %205, %175 : i32
      %214 = llvm.icmp "ult" %213, %109 : i32
      llvm.cond_br %214, ^bb35, ^bb51(%207, %208, %206 : i32, i32, i32)
    ^bb35:  // pred: ^bb34
      %215 = llvm.getelementptr %73[%207] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %215, %208, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %216 = nvvm.elect.sync -> i1
      llvm.cond_br %216, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %217 = llvm.getelementptr %13[%207] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %217, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %218 = llvm.add %207, %36 : i32
      %219 = llvm.add %206, %36 : i32
      %220 = llvm.icmp "eq" %218, %28 : i32
      %221 = llvm.select %220, %20, %218 : i1, i32
      llvm.cond_br %220, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %222 = llvm.xor %208, %36 : i32
      llvm.br ^bb40(%222 : i32)
    ^bb39:  // pred: ^bb37
      llvm.br ^bb40(%208 : i32)
    ^bb40(%223: i32):  // 2 preds: ^bb38, ^bb39
      llvm.br ^bb41
    ^bb41:  // pred: ^bb40
      %224 = llvm.mul %206, %35 : i32
      %225 = llvm.mul %207, %5 : i32
      %226 = llvm.getelementptr %67[%225] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %227 = llvm.getelementptr %13[%207] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb42(%20 : i32)
    ^bb42(%228: i32):  // 2 preds: ^bb41, ^bb45
      %229 = llvm.icmp "slt" %228, %36 : i32
      llvm.cond_br %229, ^bb43, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %230 = nvvm.elect.sync -> i1
      llvm.cond_br %230, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      nvvm.cp.async.bulk.tensor.shared.cluster.global %226, %172, %227, box[%224, %110] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %231 = llvm.add %228, %36 : i32
      llvm.br ^bb42(%231 : i32)
    ^bb46:  // pred: ^bb42
      %232 = llvm.mul %207, %4 : i32
      %233 = llvm.getelementptr %68[%232] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb47(%20 : i32)
    ^bb47(%234: i32):  // 2 preds: ^bb46, ^bb50
      %235 = llvm.icmp "slt" %234, %36 : i32
      llvm.cond_br %235, ^bb48, ^bb51(%221, %223, %219 : i32, i32, i32) {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %236 = nvvm.elect.sync -> i1
      llvm.cond_br %236, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      nvvm.cp.async.bulk.tensor.shared.cluster.global %233, %173, %227, box[%224, %111] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb50
    ^bb50:  // 2 preds: ^bb48, ^bb49
      %237 = llvm.add %234, %36 : i32
      llvm.br ^bb47(%237 : i32)
    ^bb51(%238: i32, %239: i32, %240: i32):  // 2 preds: ^bb34, ^bb47
      llvm.br ^bb52
    ^bb52:  // pred: ^bb51
      llvm.br ^bb53
    ^bb53:  // pred: ^bb52
      %241 = llvm.getelementptr %13[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %241, %210, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %242 = llvm.add %209, %36 : i32
      %243 = llvm.icmp "eq" %242, %28 : i32
      %244 = llvm.select %243, %20, %242 : i1, i32
      llvm.cond_br %243, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %245 = llvm.xor %210, %36 : i32
      llvm.br ^bb56(%245 : i32)
    ^bb55:  // pred: ^bb53
      llvm.br ^bb56(%210 : i32)
    ^bb56(%246: i32):  // 2 preds: ^bb54, ^bb55
      llvm.br ^bb57
    ^bb57:  // pred: ^bb56
      %247 = llvm.mul %209, %3 : i32
      %248 = llvm.bitcast %156 : i64 to vector<2xi32>
      %249 = llvm.extractelement %248[%20 : i32] : vector<2xi32>
      %250 = llvm.add %249, %247 : i32
      %251 = llvm.insertelement %250, %248[%20 : i32] : vector<2xi32>
      %252 = llvm.bitcast %251 : vector<2xi32> to i64
      %253 = llvm.mul %209, %2 : i32
      %254 = llvm.bitcast %159 : i64 to vector<2xi32>
      %255 = llvm.extractelement %254[%20 : i32] : vector<2xi32>
      %256 = llvm.add %255, %253 : i32
      %257 = llvm.insertelement %256, %254[%20 : i32] : vector<2xi32>
      %258 = llvm.bitcast %257 : vector<2xi32> to i64
      %259 = llvm.extractvalue %211[1] : !llvm.struct<(i1, i1, i1)> 
      %260 = llvm.extractvalue %211[2] : !llvm.struct<(i1, i1, i1)> 
      %261 = llvm.extractvalue %211[0] : !llvm.struct<(i1, i1, i1)> 
      %262 = llvm.zext %259 : i1 to i32
      %263 = llvm.zext %260 : i1 to i32
      %264 = llvm.shl %262, %32 : i32
      %265 = llvm.shl %263, %33 : i32
      %266 = llvm.or %264, %31 : i32
      %267 = llvm.or %266, %265 : i32
      llvm.br ^bb58(%20 : i32)
    ^bb58(%268: i32):  // 2 preds: ^bb57, ^bb67
      %269 = llvm.icmp "slt" %268, %36 : i32
      llvm.cond_br %269, ^bb59, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb59:  // pred: ^bb58
      llvm.br ^bb60(%20 : i32)
    ^bb60(%270: i32):  // 2 preds: ^bb59, ^bb66
      %271 = llvm.icmp "slt" %270, %36 : i32
      llvm.cond_br %271, ^bb61, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      llvm.br ^bb62(%20 : i32)
    ^bb62(%272: i32):  // 2 preds: ^bb61, ^bb65
      %273 = llvm.icmp "slt" %272, %36 : i32
      llvm.cond_br %273, ^bb63, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %274 = llvm.inttoptr %160 : i32 to !llvm.ptr<6>
      %275 = nvvm.elect.sync -> i1
      llvm.cond_br %275, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      nvvm.tcgen05.mma %274, %252, %258, %267, %261 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %276 = llvm.add %272, %36 : i32
      llvm.br ^bb62(%276 : i32)
    ^bb66:  // pred: ^bb62
      %277 = llvm.add %270, %36 : i32
      llvm.br ^bb60(%277 : i32)
    ^bb67:  // pred: ^bb60
      %278 = llvm.add %268, %36 : i32
      llvm.br ^bb58(%278 : i32)
    ^bb68:  // pred: ^bb58
      %279 = llvm.insertvalue %26, %211[0] : !llvm.struct<(i1, i1, i1)> 
      %280 = llvm.add %247, %29 : i32
      %281 = llvm.add %249, %280 : i32
      %282 = llvm.insertelement %281, %248[%20 : i32] : vector<2xi32>
      %283 = llvm.bitcast %282 : vector<2xi32> to i64
      %284 = llvm.add %253, %29 : i32
      %285 = llvm.add %255, %284 : i32
      %286 = llvm.insertelement %285, %254[%20 : i32] : vector<2xi32>
      %287 = llvm.bitcast %286 : vector<2xi32> to i64
      llvm.br ^bb69(%20 : i32)
    ^bb69(%288: i32):  // 2 preds: ^bb68, ^bb78
      %289 = llvm.icmp "slt" %288, %36 : i32
      llvm.cond_br %289, ^bb70, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb70:  // pred: ^bb69
      llvm.br ^bb71(%20 : i32)
    ^bb71(%290: i32):  // 2 preds: ^bb70, ^bb77
      %291 = llvm.icmp "slt" %290, %36 : i32
      llvm.cond_br %291, ^bb72, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      llvm.br ^bb73(%20 : i32)
    ^bb73(%292: i32):  // 2 preds: ^bb72, ^bb76
      %293 = llvm.icmp "slt" %292, %36 : i32
      llvm.cond_br %293, ^bb74, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      %294 = llvm.inttoptr %160 : i32 to !llvm.ptr<6>
      %295 = nvvm.elect.sync -> i1
      llvm.cond_br %295, ^bb75, ^bb76
    ^bb75:  // pred: ^bb74
      nvvm.tcgen05.mma %294, %283, %287, %267, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb76
    ^bb76:  // 2 preds: ^bb74, ^bb75
      %296 = llvm.add %292, %36 : i32
      llvm.br ^bb73(%296 : i32)
    ^bb77:  // pred: ^bb73
      %297 = llvm.add %290, %36 : i32
      llvm.br ^bb71(%297 : i32)
    ^bb78:  // pred: ^bb71
      %298 = llvm.add %288, %36 : i32
      llvm.br ^bb69(%298 : i32)
    ^bb79:  // pred: ^bb69
      %299 = llvm.insertvalue %26, %279[0] : !llvm.struct<(i1, i1, i1)> 
      %300 = llvm.add %247, %28 : i32
      %301 = llvm.add %249, %300 : i32
      %302 = llvm.insertelement %301, %248[%20 : i32] : vector<2xi32>
      %303 = llvm.bitcast %302 : vector<2xi32> to i64
      %304 = llvm.add %253, %28 : i32
      %305 = llvm.add %255, %304 : i32
      %306 = llvm.insertelement %305, %254[%20 : i32] : vector<2xi32>
      %307 = llvm.bitcast %306 : vector<2xi32> to i64
      llvm.br ^bb80(%20 : i32)
    ^bb80(%308: i32):  // 2 preds: ^bb79, ^bb89
      %309 = llvm.icmp "slt" %308, %36 : i32
      llvm.cond_br %309, ^bb81, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      llvm.br ^bb82(%20 : i32)
    ^bb82(%310: i32):  // 2 preds: ^bb81, ^bb88
      %311 = llvm.icmp "slt" %310, %36 : i32
      llvm.cond_br %311, ^bb83, ^bb89 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      llvm.br ^bb84(%20 : i32)
    ^bb84(%312: i32):  // 2 preds: ^bb83, ^bb87
      %313 = llvm.icmp "slt" %312, %36 : i32
      llvm.cond_br %313, ^bb85, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      %314 = llvm.inttoptr %160 : i32 to !llvm.ptr<6>
      %315 = nvvm.elect.sync -> i1
      llvm.cond_br %315, ^bb86, ^bb87
    ^bb86:  // pred: ^bb85
      nvvm.tcgen05.mma %314, %303, %307, %267, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb87
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %316 = llvm.add %312, %36 : i32
      llvm.br ^bb84(%316 : i32)
    ^bb88:  // pred: ^bb84
      %317 = llvm.add %310, %36 : i32
      llvm.br ^bb82(%317 : i32)
    ^bb89:  // pred: ^bb82
      %318 = llvm.add %308, %36 : i32
      llvm.br ^bb80(%318 : i32)
    ^bb90:  // pred: ^bb80
      %319 = llvm.insertvalue %26, %299[0] : !llvm.struct<(i1, i1, i1)> 
      %320 = llvm.add %247, %12 : i32
      %321 = llvm.add %249, %320 : i32
      %322 = llvm.insertelement %321, %248[%20 : i32] : vector<2xi32>
      %323 = llvm.bitcast %322 : vector<2xi32> to i64
      %324 = llvm.add %253, %12 : i32
      %325 = llvm.add %255, %324 : i32
      %326 = llvm.insertelement %325, %254[%20 : i32] : vector<2xi32>
      %327 = llvm.bitcast %326 : vector<2xi32> to i64
      llvm.br ^bb91(%20 : i32)
    ^bb91(%328: i32):  // 2 preds: ^bb90, ^bb100
      %329 = llvm.icmp "slt" %328, %36 : i32
      llvm.cond_br %329, ^bb92, ^bb101 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      llvm.br ^bb93(%20 : i32)
    ^bb93(%330: i32):  // 2 preds: ^bb92, ^bb99
      %331 = llvm.icmp "slt" %330, %36 : i32
      llvm.cond_br %331, ^bb94, ^bb100 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      llvm.br ^bb95(%20 : i32)
    ^bb95(%332: i32):  // 2 preds: ^bb94, ^bb98
      %333 = llvm.icmp "slt" %332, %36 : i32
      llvm.cond_br %333, ^bb96, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb96:  // pred: ^bb95
      %334 = llvm.inttoptr %160 : i32 to !llvm.ptr<6>
      %335 = nvvm.elect.sync -> i1
      llvm.cond_br %335, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      nvvm.tcgen05.mma %334, %323, %327, %267, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %336 = llvm.add %332, %36 : i32
      llvm.br ^bb95(%336 : i32)
    ^bb99:  // pred: ^bb95
      %337 = llvm.add %330, %36 : i32
      llvm.br ^bb93(%337 : i32)
    ^bb100:  // pred: ^bb93
      %338 = llvm.add %328, %36 : i32
      llvm.br ^bb91(%338 : i32)
    ^bb101:  // pred: ^bb91
      %339 = llvm.insertvalue %26, %319[0] : !llvm.struct<(i1, i1, i1)> 
      %340 = nvvm.elect.sync -> i1
      llvm.cond_br %340, ^bb102, ^bb103
    ^bb102:  // pred: ^bb101
      %341 = llvm.getelementptr %73[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.tcgen05.commit.arrive %341 : !llvm.ptr<3>
      llvm.br ^bb103
    ^bb103:  // 2 preds: ^bb101, ^bb102
      %342 = llvm.add %205, %36 : i32
      llvm.br ^bb33(%342, %240, %238, %239, %244, %246, %339 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb104:  // pred: ^bb33
      %343 = nvvm.elect.sync -> i1
      llvm.cond_br %343, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      nvvm.tcgen05.commit.arrive %61 : !llvm.ptr<3>
      llvm.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      llvm.br ^bb107
    ^bb107:  // 2 preds: ^bb12, ^bb106
      llvm.cond_br %69, ^bb108, ^bb109
    ^bb108:  // pred: ^bb107
      nvvm.tcgen05.relinquish_alloc_permit
      llvm.br ^bb109
    ^bb109:  // 2 preds: ^bb107, ^bb108
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %61, %20, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      llvm.br ^bb110(%20 : i32)
    ^bb110(%344: i32):  // 2 preds: ^bb109, ^bb117
      %345 = llvm.icmp "slt" %344, %28 : i32
      llvm.cond_br %345, ^bb111, ^bb118
    ^bb111:  // pred: ^bb110
      %346 = llvm.srem %344, %28 : i32
      %347 = llvm.mul %346, %35 : i32
      %348 = llvm.add %163, %347 : i32
      llvm.br ^bb112(%20 : i32)
    ^bb112(%349: i32):  // 2 preds: ^bb111, ^bb113
      %350 = llvm.icmp "slt" %349, %36 : i32
      llvm.cond_br %350, ^bb113, ^bb114 {llvm.loop_annotation = #loop_annotation}
    ^bb113:  // pred: ^bb112
      %351 = llvm.inttoptr %348 : i32 to !llvm.ptr<6>
      %352 = nvvm.tcgen05.ld %351 {num = 64 : i32, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>} : vector<64xi32>
      llvm.store %352, %38 : vector<64xi32>, !llvm.ptr
      %353 = llvm.add %349, %36 : i32
      llvm.br ^bb112(%353 : i32)
    ^bb114:  // pred: ^bb112
      %354 = llvm.load %38 {alignment = 32 : i64} : !llvm.ptr -> vector<64xf32>
      %355 = llvm.fptrunc %354 : vector<64xf32> to vector<64xf16>
      llvm.store %355, %37 {alignment = 32 : i64} : vector<64xf16>, !llvm.ptr
      %356 = llvm.getelementptr %171[%347] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      llvm.br ^bb115(%20 : i32)
    ^bb115(%357: i32):  // 2 preds: ^bb114, ^bb116
      %358 = llvm.icmp "slt" %357, %0 : i32
      llvm.cond_br %358, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %359 = llvm.mul %357, %0 : i32
      %360 = llvm.getelementptr %37[%359] : (!llvm.ptr, i32) -> !llvm.ptr, f16
      %361 = llvm.getelementptr %356[%359] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      %362 = llvm.load %360 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %362, %361 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %363 = llvm.add %357, %36 : i32
      llvm.br ^bb115(%363 : i32)
    ^bb117:  // pred: ^bb115
      %364 = llvm.add %344, %36 : i32
      llvm.br ^bb110(%364 : i32)
    ^bb118:  // pred: ^bb110
      nvvm.mbarrier.txn %77, %36 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %36
      llvm.cond_br %69, ^bb119, ^bb120
    ^bb119:  // pred: ^bb118
      %365 = llvm.inttoptr %160 : i32 to !llvm.ptr<6>
      nvvm.tcgen05.dealloc %365, %21 : !llvm.ptr<6>, i32
      llvm.br ^bb120
    ^bb120:  // 2 preds: ^bb118, ^bb119
      llvm.return
    }
  }
  llvm.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(true) : i1
    %1 = llvm.mlir.constant(-1 : i32) : i32
    %2 = llvm.mlir.constant(0 : i32) : i32
    %3 = llvm.mlir.constant(1 : i32) : i32
    %4 = llvm.mlir.undef : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>
    %5 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %6 = llvm.mlir.undef : !llvm.struct<(struct<(array<16 x i64>)>)>
    %7 = llvm.mlir.undef : !llvm.struct<(i1, i1, i1)>
    %8 = llvm.mlir.constant(false) : i1
    %9 = llvm.mlir.constant(16 : i32) : i32
    %10 = llvm.mlir.constant(0 : i64) : i64
    %11 = llvm.mlir.constant(1 : i64) : i64
    %12 = llvm.mlir.constant(2 : i64) : i64
    %13 = llvm.mlir.constant(8 : i64) : i64
    %14 = llvm.mlir.constant(16 : i64) : i64
    %15 = llvm.mlir.constant(4294967295 : i64) : i64
    %16 = llvm.mlir.constant(4 : i64) : i64
    %17 = llvm.mlir.constant(9007199254740991 : i64) : i64
    %18 = llvm.mlir.constant(131072 : i64) : i64
    %19 = llvm.mlir.constant(21 : i64) : i64
    %20 = llvm.mlir.constant(32 : i64) : i64
    %21 = llvm.mlir.constant(36 : i64) : i64
    %22 = llvm.mlir.constant(15 : i64) : i64
    %23 = llvm.mlir.constant(40 : i64) : i64
    %24 = llvm.mlir.constant(44 : i64) : i64
    %25 = llvm.mlir.poison : !llvm.struct<()>
    %26 = llvm.mlir.constant(128 : i32) : i32
    %27 = llvm.mlir.constant(256 : i32) : i32
    %28 = llvm.mlir.constant(1 : index) : i64
    %29 = llvm.mlir.constant(128 : index) : i64
    %30 = llvm.mlir.constant(196736 : i32) : i32
    %31 = llvm.mlir.constant(287506 : i64) : i64
    %32 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %33 = llvm.mlir.constant(127 : i64) : i64
    %34 = llvm.mlir.constant(255 : i64) : i64
    %35 = builtin.unrealized_conversion_cast %arg2 : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> to !memref_gmem_f16_
    %36 = builtin.unrealized_conversion_cast %29 : i64 to index
    %37 = builtin.unrealized_conversion_cast %28 : i64 to index
    %38 = llvm.insertvalue %8, %7[0] : !llvm.struct<(i1, i1, i1)> 
    %39 = llvm.insertvalue %8, %38[1] : !llvm.struct<(i1, i1, i1)> 
    %40 = llvm.insertvalue %8, %39[2] : !llvm.struct<(i1, i1, i1)> 
    %41 = builtin.unrealized_conversion_cast %40 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x256x16_
    %42 = llvm.alloca %9 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %43 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %44 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %45 = llvm.extractvalue %44[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %46 = llvm.extractvalue %44[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %47 = llvm.extractvalue %44[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %48 = llvm.zext %46 : i32 to i64
    %49 = llvm.zext %45 : i32 to i64
    %50 = llvm.mul %47, %12 : i64
    %51 = llvm.ptrtoint %43 : !llvm.ptr<1> to i64
    %52 = llvm.getelementptr %42[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %52 : i64, !llvm.ptr
    %53 = llvm.getelementptr %42[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %53 : i64, !llvm.ptr
    %54 = llvm.getelementptr %42[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %54 : i64, !llvm.ptr
    %55 = llvm.getelementptr %42[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %55 : i64, !llvm.ptr
    %56 = llvm.getelementptr %42[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %56 : i64, !llvm.ptr
    %57 = llvm.getelementptr %42[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %57 : i64, !llvm.ptr
    %58 = llvm.getelementptr %42[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %58 : i64, !llvm.ptr
    %59 = llvm.getelementptr %42[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %59 : i64, !llvm.ptr
    %60 = llvm.getelementptr %42[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %60 : i64, !llvm.ptr
    %61 = llvm.getelementptr %42[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %61 : i64, !llvm.ptr
    %62 = llvm.getelementptr %42[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %62 : i64, !llvm.ptr
    %63 = llvm.getelementptr %42[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %63 : i64, !llvm.ptr
    %64 = llvm.getelementptr %42[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %64 : i64, !llvm.ptr
    %65 = llvm.getelementptr %42[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %65 : i64, !llvm.ptr
    %66 = llvm.getelementptr %42[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %66 : i64, !llvm.ptr
    %67 = llvm.getelementptr %42[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %67 : i64, !llvm.ptr
    %68 = llvm.udiv %51, %14 : i64
    %69 = llvm.and %68, %17 : i64
    %70 = llvm.shl %69, %16 : i64
    llvm.store %70, %52 : i64, !llvm.ptr
    %71 = llvm.sub %49, %11 : i64
    %72 = llvm.sub %11, %11 : i64
    %73 = llvm.mul %71, %50 : i64
    %74 = llvm.mul %72, %10 : i64
    %75 = llvm.add %73, %74 : i64
    %76 = llvm.add %74, %74 : i64
    %77 = llvm.mul %48, %14 : i64
    %78 = llvm.udiv %77, %13 : i64
    %79 = llvm.add %78, %75 : i64
    %80 = llvm.add %79, %76 : i64
    %81 = llvm.icmp "uge" %80, %18 : i64
    %82 = llvm.zext %81 : i1 to i64
    %83 = llvm.shl %82, %19 : i64
    %84 = llvm.udiv %50, %14 : i64
    %85 = llvm.shl %84, %20 : i64
    %86 = llvm.or %10, %83 : i64
    %87 = llvm.or %86, %85 : i64
    %88 = llvm.or %31, %87 : i64
    llvm.store %88, %53 : i64, !llvm.ptr
    %89 = llvm.udiv %10, %14 : i64
    %90 = llvm.and %89, %15 : i64
    %91 = llvm.shl %90, %10 : i64
    %92 = llvm.shl %89, %20 : i64
    %93 = llvm.or %91, %92 : i64
    llvm.store %93, %54 : i64, !llvm.ptr
    %94 = llvm.lshr %50, %21 : i64
    %95 = llvm.and %94, %22 : i64
    %96 = llvm.shl %95, %20 : i64
    %97 = llvm.lshr %10, %21 : i64
    %98 = llvm.and %97, %22 : i64
    %99 = llvm.shl %98, %21 : i64
    %100 = llvm.shl %98, %23 : i64
    %101 = llvm.shl %97, %24 : i64
    %102 = llvm.or %96, %99 : i64
    %103 = llvm.or %100, %101 : i64
    %104 = llvm.or %102, %103 : i64
    %105 = llvm.or %91, %104 : i64
    llvm.store %105, %55 : i64, !llvm.ptr
    %106 = llvm.sub %48, %11 : i64
    %107 = llvm.and %106, %15 : i64
    %108 = llvm.shl %107, %10 : i64
    %109 = llvm.shl %71, %20 : i64
    %110 = llvm.or %108, %109 : i64
    llvm.store %110, %56 : i64, !llvm.ptr
    %111 = llvm.and %72, %15 : i64
    %112 = llvm.shl %111, %10 : i64
    %113 = llvm.shl %72, %20 : i64
    %114 = llvm.or %112, %113 : i64
    llvm.store %114, %57 : i64, !llvm.ptr
    %115 = llvm.or %111, %10 : i64
    %116 = llvm.or %115, %32 : i64
    llvm.store %116, %58 : i64, !llvm.ptr
    llvm.store %33, %59 : i64, !llvm.ptr
    %117 = llvm.ptrtoint %42 : !llvm.ptr to i64
    %118 = llvm.inttoptr %117 : i64 to !llvm.ptr
    %119 = llvm.load %118 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %120 = llvm.insertvalue %119, %6[0] : !llvm.struct<(struct<(array<16 x i64>)>)> 
    %121 = builtin.unrealized_conversion_cast %120 : !llvm.struct<(struct<(array<16 x i64>)>)> to !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %122 = llvm.extractvalue %44[0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %123 = llvm.insertvalue %122, %5[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %124 = llvm.insertvalue %25, %123[1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %125 = llvm.insertvalue %25, %4[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %126 = llvm.insertvalue %124, %125[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %127 = builtin.unrealized_conversion_cast %126 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %128 = llvm.alloca %9 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %129 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %130 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %131 = llvm.extractvalue %130[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %132 = llvm.extractvalue %130[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %133 = llvm.extractvalue %130[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %134 = llvm.zext %132 : i32 to i64
    %135 = llvm.zext %131 : i32 to i64
    %136 = llvm.mul %133, %12 : i64
    %137 = llvm.ptrtoint %129 : !llvm.ptr<1> to i64
    %138 = llvm.getelementptr %128[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %138 : i64, !llvm.ptr
    %139 = llvm.getelementptr %128[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %139 : i64, !llvm.ptr
    %140 = llvm.getelementptr %128[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %140 : i64, !llvm.ptr
    %141 = llvm.getelementptr %128[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %141 : i64, !llvm.ptr
    %142 = llvm.getelementptr %128[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %142 : i64, !llvm.ptr
    %143 = llvm.getelementptr %128[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %143 : i64, !llvm.ptr
    %144 = llvm.getelementptr %128[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %144 : i64, !llvm.ptr
    %145 = llvm.getelementptr %128[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %145 : i64, !llvm.ptr
    %146 = llvm.getelementptr %128[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %146 : i64, !llvm.ptr
    %147 = llvm.getelementptr %128[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %147 : i64, !llvm.ptr
    %148 = llvm.getelementptr %128[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %148 : i64, !llvm.ptr
    %149 = llvm.getelementptr %128[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %149 : i64, !llvm.ptr
    %150 = llvm.getelementptr %128[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %150 : i64, !llvm.ptr
    %151 = llvm.getelementptr %128[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %151 : i64, !llvm.ptr
    %152 = llvm.getelementptr %128[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %152 : i64, !llvm.ptr
    %153 = llvm.getelementptr %128[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %10, %153 : i64, !llvm.ptr
    %154 = llvm.udiv %137, %14 : i64
    %155 = llvm.and %154, %17 : i64
    %156 = llvm.shl %155, %16 : i64
    llvm.store %156, %138 : i64, !llvm.ptr
    %157 = llvm.sub %135, %11 : i64
    %158 = llvm.mul %157, %136 : i64
    %159 = llvm.add %158, %74 : i64
    %160 = llvm.mul %134, %14 : i64
    %161 = llvm.udiv %160, %13 : i64
    %162 = llvm.add %161, %159 : i64
    %163 = llvm.add %162, %76 : i64
    %164 = llvm.icmp "uge" %163, %18 : i64
    %165 = llvm.zext %164 : i1 to i64
    %166 = llvm.shl %165, %19 : i64
    %167 = llvm.udiv %136, %14 : i64
    %168 = llvm.shl %167, %20 : i64
    %169 = llvm.or %10, %166 : i64
    %170 = llvm.or %169, %168 : i64
    %171 = llvm.or %31, %170 : i64
    llvm.store %171, %139 : i64, !llvm.ptr
    llvm.store %93, %140 : i64, !llvm.ptr
    %172 = llvm.lshr %136, %21 : i64
    %173 = llvm.and %172, %22 : i64
    %174 = llvm.shl %173, %20 : i64
    %175 = llvm.or %174, %99 : i64
    %176 = llvm.or %175, %103 : i64
    %177 = llvm.or %91, %176 : i64
    llvm.store %177, %141 : i64, !llvm.ptr
    %178 = llvm.sub %134, %11 : i64
    %179 = llvm.and %178, %15 : i64
    %180 = llvm.shl %179, %10 : i64
    %181 = llvm.shl %157, %20 : i64
    %182 = llvm.or %180, %181 : i64
    llvm.store %182, %142 : i64, !llvm.ptr
    llvm.store %114, %143 : i64, !llvm.ptr
    llvm.store %116, %144 : i64, !llvm.ptr
    llvm.store %34, %145 : i64, !llvm.ptr
    %183 = llvm.ptrtoint %128 : !llvm.ptr to i64
    %184 = llvm.inttoptr %183 : i64 to !llvm.ptr
    %185 = llvm.load %184 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %186 = llvm.insertvalue %185, %6[0] : !llvm.struct<(struct<(array<16 x i64>)>)> 
    %187 = builtin.unrealized_conversion_cast %186 : !llvm.struct<(struct<(array<16 x i64>)>)> to !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %188 = llvm.extractvalue %130[0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %189 = llvm.insertvalue %188, %5[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %190 = llvm.insertvalue %25, %189[1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %191 = llvm.insertvalue %190, %125[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %192 = builtin.unrealized_conversion_cast %191 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %193 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %194 = llvm.extractvalue %193[0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %195 = llvm.extractvalue %194[0] : !llvm.struct<(i32, i32)> 
    %196 = llvm.extractvalue %194[1] : !llvm.struct<(i32, i32)> 
    %197 = llvm.select %0, %1, %3 : i1, i32
    %198 = llvm.add %197, %195 : i32
    %199 = llvm.sdiv %198, %26 : i32
    %200 = llvm.add %199, %3 : i32
    %201 = llvm.sub %2, %195 : i32
    %202 = llvm.sdiv %201, %26 : i32
    %203 = llvm.sub %2, %202 : i32
    %204 = llvm.icmp "slt" %195, %2 : i32
    %205 = llvm.icmp "sgt" %195, %2 : i32
    %206 = llvm.and %204, %8 : i1
    %207 = llvm.and %205, %0 : i1
    %208 = llvm.or %206, %207 : i1
    %209 = llvm.select %208, %200, %203 : i1, i32
    %210 = llvm.add %197, %196 : i32
    %211 = llvm.sdiv %210, %27 : i32
    %212 = llvm.add %211, %3 : i32
    %213 = llvm.sub %2, %196 : i32
    %214 = llvm.sdiv %213, %27 : i32
    %215 = llvm.sub %2, %214 : i32
    %216 = llvm.icmp "slt" %196, %2 : i32
    %217 = llvm.icmp "sgt" %196, %2 : i32
    %218 = llvm.and %216, %8 : i1
    %219 = llvm.and %217, %0 : i1
    %220 = llvm.or %218, %219 : i1
    %221 = llvm.select %220, %212, %215 : i1, i32
    %222 = llvm.sext %209 : i32 to i64
    %223 = builtin.unrealized_conversion_cast %222 : i64 to index
    %224 = llvm.sext %221 : i32 to i64
    %225 = builtin.unrealized_conversion_cast %224 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0 blocks in (%223, %225, %37) threads in (%36, %37, %37)  dynamic_shared_memory_size %30 args(%41 : !mma_f16_f16_f32_128x256x16_, %121 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %127 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %187 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %192 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %35 : !memref_gmem_f16_) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0, %arg1, %arg2) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) -> ()
    llvm.return
  }
}
