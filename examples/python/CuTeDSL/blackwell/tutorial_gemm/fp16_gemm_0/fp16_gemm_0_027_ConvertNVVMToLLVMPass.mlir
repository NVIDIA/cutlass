!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
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
      %77 = llvm.mlir.constant(0 : i32) : i32
      llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %77 : (i32) -> ()
      nvvm.barrier
      llvm.cond_br %69, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      nvvm.mbarrier.init.shared %61, %36 : !llvm.ptr<3>, i32
      llvm.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %78 = llvm.getelementptr %61[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
      llvm.cond_br %69, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      nvvm.mbarrier.init.shared %78, %18 : !llvm.ptr<3>, i32
      llvm.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %79 = llvm.mlir.constant(0 : i32) : i32
      llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %79 : (i32) -> ()
      nvvm.barrier
      %80 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
      %81 = llvm.extractvalue %80[0, 0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %82 = llvm.extractvalue %80[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %83 = llvm.select %26, %15, %36 : i1, i32
      %84 = llvm.add %83, %81 : i32
      %85 = llvm.sdiv %84, %18 : i32
      %86 = llvm.add %85, %36 : i32
      %87 = llvm.sub %20, %81 : i32
      %88 = llvm.sdiv %87, %18 : i32
      %89 = llvm.sub %20, %88 : i32
      %90 = llvm.icmp "slt" %81, %20 : i32
      %91 = llvm.icmp "sgt" %81, %20 : i32
      %92 = llvm.and %90, %16 : i1
      %93 = llvm.and %91, %26 : i1
      %94 = llvm.or %92, %93 : i1
      %95 = llvm.select %94, %86, %89 : i1, i32
      %96 = llvm.add %83, %82 : i32
      %97 = llvm.sdiv %96, %35 : i32
      %98 = llvm.add %97, %36 : i32
      %99 = llvm.sub %20, %82 : i32
      %100 = llvm.sdiv %99, %35 : i32
      %101 = llvm.sub %20, %100 : i32
      %102 = llvm.icmp "slt" %82, %20 : i32
      %103 = llvm.icmp "sgt" %82, %20 : i32
      %104 = llvm.and %102, %16 : i1
      %105 = llvm.and %103, %26 : i1
      %106 = llvm.or %104, %105 : i1
      %107 = llvm.select %106, %98, %101 : i1, i32
      %108 = llvm.insertvalue %95, %11[0] : !llvm.struct<(i32, i32)> 
      %109 = llvm.insertvalue %107, %108[1] : !llvm.struct<(i32, i32)> 
      %110 = llvm.insertvalue %109, %10[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %111 = llvm.extractvalue %110[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %112 = llvm.mul %58, %18 : i32
      %113 = llvm.mul %59, %22 : i32
      %114 = llvm.extractvalue %arg5[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %115 = llvm.extractvalue %114[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %116 = llvm.extractvalue %114[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %117 = llvm.extractvalue %114[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %118 = llvm.add %83, %115 : i32
      %119 = llvm.sdiv %118, %18 : i32
      %120 = llvm.add %119, %36 : i32
      %121 = llvm.sub %20, %115 : i32
      %122 = llvm.sdiv %121, %18 : i32
      %123 = llvm.sub %20, %122 : i32
      %124 = llvm.icmp "slt" %115, %20 : i32
      %125 = llvm.icmp "sgt" %115, %20 : i32
      %126 = llvm.and %124, %16 : i1
      %127 = llvm.and %125, %26 : i1
      %128 = llvm.or %126, %127 : i1
      %129 = llvm.select %128, %120, %123 : i1, i32
      %130 = llvm.mul %117, %23 : i64
      %131 = llvm.add %83, %116 : i32
      %132 = llvm.sdiv %131, %22 : i32
      %133 = llvm.add %132, %36 : i32
      %134 = llvm.sub %20, %116 : i32
      %135 = llvm.sdiv %134, %22 : i32
      %136 = llvm.sub %20, %135 : i32
      %137 = llvm.icmp "slt" %116, %20 : i32
      %138 = llvm.icmp "sgt" %116, %20 : i32
      %139 = llvm.and %137, %16 : i1
      %140 = llvm.and %138, %26 : i1
      %141 = llvm.or %139, %140 : i1
      %142 = llvm.select %141, %133, %136 : i1, i32
      %143 = llvm.insertvalue %129, %11[0] : !llvm.struct<(i32, i32)> 
      %144 = llvm.insertvalue %142, %143[1] : !llvm.struct<(i32, i32)> 
      %145 = llvm.insertvalue %117, %9[0] : !llvm.struct<(i64, i64)> 
      %146 = llvm.insertvalue %130, %145[1] : !llvm.struct<(i64, i64)> 
      %147 = llvm.insertvalue %144, %8[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %148 = llvm.insertvalue %146, %147[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %149 = llvm.extractvalue %148[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %150 = llvm.sext %58 : i32 to i64
      %151 = llvm.mul %150, %130 : i64
      %152 = llvm.sext %113 : i32 to i64
      %153 = llvm.add %151, %152 : i64
      %154 = llvm.extractvalue %arg5[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %155 = llvm.getelementptr %154[%153] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      %156 = llvm.ptrtoint %67 : !llvm.ptr<3> to i32
      %157 = llvm.lshr %156, %28 : i32
      %158 = nvvm.mma_smem_desc(%157, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      %159 = llvm.ptrtoint %68 : !llvm.ptr<3> to i32
      %160 = llvm.lshr %159, %28 : i32
      %161 = nvvm.mma_smem_desc(%160, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      nvvm.barrier id = %36 number_of_threads = %18
      %162 = llvm.load %62 : !llvm.ptr<3> -> i32
      %163 = llvm.sdiv %39, %17 : i32
      %164 = llvm.mul %163, %24 : i32
      %165 = llvm.add %162, %164 : i32
      %166 = llvm.mul %149, %25 : i64
      %167 = llvm.srem %39, %17 : i32
      %168 = llvm.sext %167 : i32 to i64
      %169 = llvm.mul %168, %149 : i64
      %170 = llvm.sext %163 : i32 to i64
      %171 = llvm.mul %170, %166 : i64
      %172 = llvm.add %169, %171 : i64
      %173 = llvm.getelementptr %155[%172] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      llvm.cond_br %69, ^bb13, ^bb107
    ^bb13:  // pred: ^bb12
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %78, %36, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %174 = llvm.getelementptr %arg1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %175 = llvm.getelementptr %arg3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %176 = llvm.icmp "slt" %111, %29 : i32
      %177 = llvm.select %176, %111, %29 : i1, i32
      llvm.br ^bb14(%20, %20, %36, %20 : i32, i32, i32, i32)
    ^bb14(%178: i32, %179: i32, %180: i32, %181: i32):  // 2 preds: ^bb13, ^bb31
      %182 = llvm.icmp "slt" %178, %177 : i32
      llvm.cond_br %182, ^bb15, ^bb32
    ^bb15:  // pred: ^bb14
      %183 = llvm.getelementptr %73[%179] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %183, %180, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %184 = nvvm.elect.sync -> i1
      llvm.cond_br %184, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %185 = llvm.getelementptr %13[%179] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %185, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %186 = llvm.add %179, %36 : i32
      %187 = llvm.add %181, %36 : i32
      %188 = llvm.icmp "eq" %186, %28 : i32
      %189 = llvm.select %188, %20, %186 : i1, i32
      llvm.cond_br %188, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %190 = llvm.xor %180, %36 : i32
      llvm.br ^bb20(%190 : i32)
    ^bb19:  // pred: ^bb17
      llvm.br ^bb20(%180 : i32)
    ^bb20(%191: i32):  // 2 preds: ^bb18, ^bb19
      llvm.br ^bb21
    ^bb21:  // pred: ^bb20
      %192 = llvm.mul %181, %35 : i32
      %193 = llvm.mul %179, %5 : i32
      %194 = llvm.getelementptr %67[%193] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %195 = llvm.getelementptr %13[%179] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb22(%20 : i32)
    ^bb22(%196: i32):  // 2 preds: ^bb21, ^bb25
      %197 = llvm.icmp "slt" %196, %36 : i32
      llvm.cond_br %197, ^bb23, ^bb26 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %198 = nvvm.elect.sync -> i1
      llvm.cond_br %198, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      nvvm.cp.async.bulk.tensor.shared.cluster.global %194, %174, %195, box[%192, %112] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %199 = llvm.add %196, %36 : i32
      llvm.br ^bb22(%199 : i32)
    ^bb26:  // pred: ^bb22
      %200 = llvm.mul %179, %4 : i32
      %201 = llvm.getelementptr %68[%200] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb27(%20 : i32)
    ^bb27(%202: i32):  // 2 preds: ^bb26, ^bb30
      %203 = llvm.icmp "slt" %202, %36 : i32
      llvm.cond_br %203, ^bb28, ^bb31 {llvm.loop_annotation = #loop_annotation}
    ^bb28:  // pred: ^bb27
      %204 = nvvm.elect.sync -> i1
      llvm.cond_br %204, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      nvvm.cp.async.bulk.tensor.shared.cluster.global %201, %175, %195, box[%192, %113] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %205 = llvm.add %202, %36 : i32
      llvm.br ^bb27(%205 : i32)
    ^bb31:  // pred: ^bb27
      %206 = llvm.add %178, %36 : i32
      llvm.br ^bb14(%206, %189, %191, %187 : i32, i32, i32, i32)
    ^bb32:  // pred: ^bb14
      llvm.br ^bb33(%20, %181, %179, %180, %20, %20, %arg0 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb33(%207: i32, %208: i32, %209: i32, %210: i32, %211: i32, %212: i32, %213: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb32, ^bb103
      %214 = llvm.icmp "slt" %207, %111 : i32
      llvm.cond_br %214, ^bb34, ^bb104
    ^bb34:  // pred: ^bb33
      %215 = llvm.add %207, %177 : i32
      %216 = llvm.icmp "ult" %215, %111 : i32
      llvm.cond_br %216, ^bb35, ^bb51(%209, %210, %208 : i32, i32, i32)
    ^bb35:  // pred: ^bb34
      %217 = llvm.getelementptr %73[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %217, %210, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %218 = nvvm.elect.sync -> i1
      llvm.cond_br %218, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %219 = llvm.getelementptr %13[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %219, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %220 = llvm.add %209, %36 : i32
      %221 = llvm.add %208, %36 : i32
      %222 = llvm.icmp "eq" %220, %28 : i32
      %223 = llvm.select %222, %20, %220 : i1, i32
      llvm.cond_br %222, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %224 = llvm.xor %210, %36 : i32
      llvm.br ^bb40(%224 : i32)
    ^bb39:  // pred: ^bb37
      llvm.br ^bb40(%210 : i32)
    ^bb40(%225: i32):  // 2 preds: ^bb38, ^bb39
      llvm.br ^bb41
    ^bb41:  // pred: ^bb40
      %226 = llvm.mul %208, %35 : i32
      %227 = llvm.mul %209, %5 : i32
      %228 = llvm.getelementptr %67[%227] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %229 = llvm.getelementptr %13[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb42(%20 : i32)
    ^bb42(%230: i32):  // 2 preds: ^bb41, ^bb45
      %231 = llvm.icmp "slt" %230, %36 : i32
      llvm.cond_br %231, ^bb43, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %232 = nvvm.elect.sync -> i1
      llvm.cond_br %232, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      nvvm.cp.async.bulk.tensor.shared.cluster.global %228, %174, %229, box[%226, %112] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %233 = llvm.add %230, %36 : i32
      llvm.br ^bb42(%233 : i32)
    ^bb46:  // pred: ^bb42
      %234 = llvm.mul %209, %4 : i32
      %235 = llvm.getelementptr %68[%234] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb47(%20 : i32)
    ^bb47(%236: i32):  // 2 preds: ^bb46, ^bb50
      %237 = llvm.icmp "slt" %236, %36 : i32
      llvm.cond_br %237, ^bb48, ^bb51(%223, %225, %221 : i32, i32, i32) {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %238 = nvvm.elect.sync -> i1
      llvm.cond_br %238, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      nvvm.cp.async.bulk.tensor.shared.cluster.global %235, %175, %229, box[%226, %113] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb50
    ^bb50:  // 2 preds: ^bb48, ^bb49
      %239 = llvm.add %236, %36 : i32
      llvm.br ^bb47(%239 : i32)
    ^bb51(%240: i32, %241: i32, %242: i32):  // 2 preds: ^bb34, ^bb47
      llvm.br ^bb52
    ^bb52:  // pred: ^bb51
      llvm.br ^bb53
    ^bb53:  // pred: ^bb52
      %243 = llvm.getelementptr %13[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %243, %212, %27 : (!llvm.ptr<3>, i32, i32) -> ()
      %244 = llvm.add %211, %36 : i32
      %245 = llvm.icmp "eq" %244, %28 : i32
      %246 = llvm.select %245, %20, %244 : i1, i32
      llvm.cond_br %245, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %247 = llvm.xor %212, %36 : i32
      llvm.br ^bb56(%247 : i32)
    ^bb55:  // pred: ^bb53
      llvm.br ^bb56(%212 : i32)
    ^bb56(%248: i32):  // 2 preds: ^bb54, ^bb55
      llvm.br ^bb57
    ^bb57:  // pred: ^bb56
      %249 = llvm.mul %211, %3 : i32
      %250 = llvm.bitcast %158 : i64 to vector<2xi32>
      %251 = llvm.extractelement %250[%20 : i32] : vector<2xi32>
      %252 = llvm.add %251, %249 : i32
      %253 = llvm.insertelement %252, %250[%20 : i32] : vector<2xi32>
      %254 = llvm.bitcast %253 : vector<2xi32> to i64
      %255 = llvm.mul %211, %2 : i32
      %256 = llvm.bitcast %161 : i64 to vector<2xi32>
      %257 = llvm.extractelement %256[%20 : i32] : vector<2xi32>
      %258 = llvm.add %257, %255 : i32
      %259 = llvm.insertelement %258, %256[%20 : i32] : vector<2xi32>
      %260 = llvm.bitcast %259 : vector<2xi32> to i64
      %261 = llvm.extractvalue %213[1] : !llvm.struct<(i1, i1, i1)> 
      %262 = llvm.extractvalue %213[2] : !llvm.struct<(i1, i1, i1)> 
      %263 = llvm.extractvalue %213[0] : !llvm.struct<(i1, i1, i1)> 
      %264 = llvm.zext %261 : i1 to i32
      %265 = llvm.zext %262 : i1 to i32
      %266 = llvm.shl %264, %32 : i32
      %267 = llvm.shl %265, %33 : i32
      %268 = llvm.or %266, %31 : i32
      %269 = llvm.or %268, %267 : i32
      llvm.br ^bb58(%20 : i32)
    ^bb58(%270: i32):  // 2 preds: ^bb57, ^bb67
      %271 = llvm.icmp "slt" %270, %36 : i32
      llvm.cond_br %271, ^bb59, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb59:  // pred: ^bb58
      llvm.br ^bb60(%20 : i32)
    ^bb60(%272: i32):  // 2 preds: ^bb59, ^bb66
      %273 = llvm.icmp "slt" %272, %36 : i32
      llvm.cond_br %273, ^bb61, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      llvm.br ^bb62(%20 : i32)
    ^bb62(%274: i32):  // 2 preds: ^bb61, ^bb65
      %275 = llvm.icmp "slt" %274, %36 : i32
      llvm.cond_br %275, ^bb63, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %276 = llvm.inttoptr %162 : i32 to !llvm.ptr<6>
      %277 = nvvm.elect.sync -> i1
      llvm.cond_br %277, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      nvvm.tcgen05.mma %276, %254, %260, %269, %263 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %278 = llvm.add %274, %36 : i32
      llvm.br ^bb62(%278 : i32)
    ^bb66:  // pred: ^bb62
      %279 = llvm.add %272, %36 : i32
      llvm.br ^bb60(%279 : i32)
    ^bb67:  // pred: ^bb60
      %280 = llvm.add %270, %36 : i32
      llvm.br ^bb58(%280 : i32)
    ^bb68:  // pred: ^bb58
      %281 = llvm.insertvalue %26, %213[0] : !llvm.struct<(i1, i1, i1)> 
      %282 = llvm.add %249, %29 : i32
      %283 = llvm.add %251, %282 : i32
      %284 = llvm.insertelement %283, %250[%20 : i32] : vector<2xi32>
      %285 = llvm.bitcast %284 : vector<2xi32> to i64
      %286 = llvm.add %255, %29 : i32
      %287 = llvm.add %257, %286 : i32
      %288 = llvm.insertelement %287, %256[%20 : i32] : vector<2xi32>
      %289 = llvm.bitcast %288 : vector<2xi32> to i64
      llvm.br ^bb69(%20 : i32)
    ^bb69(%290: i32):  // 2 preds: ^bb68, ^bb78
      %291 = llvm.icmp "slt" %290, %36 : i32
      llvm.cond_br %291, ^bb70, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb70:  // pred: ^bb69
      llvm.br ^bb71(%20 : i32)
    ^bb71(%292: i32):  // 2 preds: ^bb70, ^bb77
      %293 = llvm.icmp "slt" %292, %36 : i32
      llvm.cond_br %293, ^bb72, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      llvm.br ^bb73(%20 : i32)
    ^bb73(%294: i32):  // 2 preds: ^bb72, ^bb76
      %295 = llvm.icmp "slt" %294, %36 : i32
      llvm.cond_br %295, ^bb74, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      %296 = llvm.inttoptr %162 : i32 to !llvm.ptr<6>
      %297 = nvvm.elect.sync -> i1
      llvm.cond_br %297, ^bb75, ^bb76
    ^bb75:  // pred: ^bb74
      nvvm.tcgen05.mma %296, %285, %289, %269, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb76
    ^bb76:  // 2 preds: ^bb74, ^bb75
      %298 = llvm.add %294, %36 : i32
      llvm.br ^bb73(%298 : i32)
    ^bb77:  // pred: ^bb73
      %299 = llvm.add %292, %36 : i32
      llvm.br ^bb71(%299 : i32)
    ^bb78:  // pred: ^bb71
      %300 = llvm.add %290, %36 : i32
      llvm.br ^bb69(%300 : i32)
    ^bb79:  // pred: ^bb69
      %301 = llvm.insertvalue %26, %281[0] : !llvm.struct<(i1, i1, i1)> 
      %302 = llvm.add %249, %28 : i32
      %303 = llvm.add %251, %302 : i32
      %304 = llvm.insertelement %303, %250[%20 : i32] : vector<2xi32>
      %305 = llvm.bitcast %304 : vector<2xi32> to i64
      %306 = llvm.add %255, %28 : i32
      %307 = llvm.add %257, %306 : i32
      %308 = llvm.insertelement %307, %256[%20 : i32] : vector<2xi32>
      %309 = llvm.bitcast %308 : vector<2xi32> to i64
      llvm.br ^bb80(%20 : i32)
    ^bb80(%310: i32):  // 2 preds: ^bb79, ^bb89
      %311 = llvm.icmp "slt" %310, %36 : i32
      llvm.cond_br %311, ^bb81, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      llvm.br ^bb82(%20 : i32)
    ^bb82(%312: i32):  // 2 preds: ^bb81, ^bb88
      %313 = llvm.icmp "slt" %312, %36 : i32
      llvm.cond_br %313, ^bb83, ^bb89 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      llvm.br ^bb84(%20 : i32)
    ^bb84(%314: i32):  // 2 preds: ^bb83, ^bb87
      %315 = llvm.icmp "slt" %314, %36 : i32
      llvm.cond_br %315, ^bb85, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      %316 = llvm.inttoptr %162 : i32 to !llvm.ptr<6>
      %317 = nvvm.elect.sync -> i1
      llvm.cond_br %317, ^bb86, ^bb87
    ^bb86:  // pred: ^bb85
      nvvm.tcgen05.mma %316, %305, %309, %269, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb87
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %318 = llvm.add %314, %36 : i32
      llvm.br ^bb84(%318 : i32)
    ^bb88:  // pred: ^bb84
      %319 = llvm.add %312, %36 : i32
      llvm.br ^bb82(%319 : i32)
    ^bb89:  // pred: ^bb82
      %320 = llvm.add %310, %36 : i32
      llvm.br ^bb80(%320 : i32)
    ^bb90:  // pred: ^bb80
      %321 = llvm.insertvalue %26, %301[0] : !llvm.struct<(i1, i1, i1)> 
      %322 = llvm.add %249, %12 : i32
      %323 = llvm.add %251, %322 : i32
      %324 = llvm.insertelement %323, %250[%20 : i32] : vector<2xi32>
      %325 = llvm.bitcast %324 : vector<2xi32> to i64
      %326 = llvm.add %255, %12 : i32
      %327 = llvm.add %257, %326 : i32
      %328 = llvm.insertelement %327, %256[%20 : i32] : vector<2xi32>
      %329 = llvm.bitcast %328 : vector<2xi32> to i64
      llvm.br ^bb91(%20 : i32)
    ^bb91(%330: i32):  // 2 preds: ^bb90, ^bb100
      %331 = llvm.icmp "slt" %330, %36 : i32
      llvm.cond_br %331, ^bb92, ^bb101 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      llvm.br ^bb93(%20 : i32)
    ^bb93(%332: i32):  // 2 preds: ^bb92, ^bb99
      %333 = llvm.icmp "slt" %332, %36 : i32
      llvm.cond_br %333, ^bb94, ^bb100 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      llvm.br ^bb95(%20 : i32)
    ^bb95(%334: i32):  // 2 preds: ^bb94, ^bb98
      %335 = llvm.icmp "slt" %334, %36 : i32
      llvm.cond_br %335, ^bb96, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb96:  // pred: ^bb95
      %336 = llvm.inttoptr %162 : i32 to !llvm.ptr<6>
      %337 = nvvm.elect.sync -> i1
      llvm.cond_br %337, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      nvvm.tcgen05.mma %336, %325, %329, %269, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %338 = llvm.add %334, %36 : i32
      llvm.br ^bb95(%338 : i32)
    ^bb99:  // pred: ^bb95
      %339 = llvm.add %332, %36 : i32
      llvm.br ^bb93(%339 : i32)
    ^bb100:  // pred: ^bb93
      %340 = llvm.add %330, %36 : i32
      llvm.br ^bb91(%340 : i32)
    ^bb101:  // pred: ^bb91
      %341 = llvm.insertvalue %26, %321[0] : !llvm.struct<(i1, i1, i1)> 
      %342 = nvvm.elect.sync -> i1
      llvm.cond_br %342, ^bb102, ^bb103
    ^bb102:  // pred: ^bb101
      %343 = llvm.getelementptr %73[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.tcgen05.commit.arrive %343 : !llvm.ptr<3>
      llvm.br ^bb103
    ^bb103:  // 2 preds: ^bb101, ^bb102
      %344 = llvm.add %207, %36 : i32
      llvm.br ^bb33(%344, %242, %240, %241, %246, %248, %341 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb104:  // pred: ^bb33
      %345 = nvvm.elect.sync -> i1
      llvm.cond_br %345, ^bb105, ^bb106
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
    ^bb110(%346: i32):  // 2 preds: ^bb109, ^bb117
      %347 = llvm.icmp "slt" %346, %28 : i32
      llvm.cond_br %347, ^bb111, ^bb118
    ^bb111:  // pred: ^bb110
      %348 = llvm.srem %346, %28 : i32
      %349 = llvm.mul %348, %35 : i32
      %350 = llvm.add %165, %349 : i32
      llvm.br ^bb112(%20 : i32)
    ^bb112(%351: i32):  // 2 preds: ^bb111, ^bb113
      %352 = llvm.icmp "slt" %351, %36 : i32
      llvm.cond_br %352, ^bb113, ^bb114 {llvm.loop_annotation = #loop_annotation}
    ^bb113:  // pred: ^bb112
      %353 = llvm.inttoptr %350 : i32 to !llvm.ptr<6>
      %354 = nvvm.tcgen05.ld %353 {num = 64 : i32, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>} : vector<64xi32>
      llvm.store %354, %38 : vector<64xi32>, !llvm.ptr
      %355 = llvm.add %351, %36 : i32
      llvm.br ^bb112(%355 : i32)
    ^bb114:  // pred: ^bb112
      %356 = llvm.load %38 {alignment = 32 : i64} : !llvm.ptr -> vector<64xf32>
      %357 = llvm.fptrunc %356 : vector<64xf32> to vector<64xf16>
      llvm.store %357, %37 {alignment = 32 : i64} : vector<64xf16>, !llvm.ptr
      %358 = llvm.getelementptr %173[%349] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      llvm.br ^bb115(%20 : i32)
    ^bb115(%359: i32):  // 2 preds: ^bb114, ^bb116
      %360 = llvm.icmp "slt" %359, %0 : i32
      llvm.cond_br %360, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %361 = llvm.mul %359, %0 : i32
      %362 = llvm.getelementptr %37[%361] : (!llvm.ptr, i32) -> !llvm.ptr, f16
      %363 = llvm.getelementptr %358[%361] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      %364 = llvm.load %362 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %364, %363 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %365 = llvm.add %359, %36 : i32
      llvm.br ^bb115(%365 : i32)
    ^bb117:  // pred: ^bb115
      %366 = llvm.add %346, %36 : i32
      llvm.br ^bb110(%366 : i32)
    ^bb118:  // pred: ^bb110
      nvvm.mbarrier.txn %78, %36 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %36
      llvm.cond_br %69, ^bb119, ^bb120
    ^bb119:  // pred: ^bb118
      %367 = llvm.inttoptr %162 : i32 to !llvm.ptr<6>
      nvvm.tcgen05.dealloc %367, %21 : !llvm.ptr<6>, i32
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
