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
      nvvm.prefetch.tensormap %arg1 : !llvm.ptr
      nvvm.prefetch.tensormap %arg3 : !llvm.ptr
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
      nvvm.fence.mbarrier.init
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
      nvvm.fence.mbarrier.init
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
      %94 = llvm.select %26, %15, %36 : i1, i32
      %95 = llvm.add %94, %80 : i32
      %96 = llvm.sdiv %95, %35 : i32
      %97 = llvm.add %96, %36 : i32
      %98 = llvm.sub %20, %80 : i32
      %99 = llvm.sdiv %98, %35 : i32
      %100 = llvm.sub %20, %99 : i32
      %101 = llvm.icmp "slt" %80, %20 : i32
      %102 = llvm.icmp "sgt" %80, %20 : i32
      %103 = llvm.and %101, %16 : i1
      %104 = llvm.and %102, %26 : i1
      %105 = llvm.or %103, %104 : i1
      %106 = llvm.select %105, %97, %100 : i1, i32
      %107 = llvm.insertvalue %93, %11[0] : !llvm.struct<(i32, i32)> 
      %108 = llvm.insertvalue %106, %107[1] : !llvm.struct<(i32, i32)> 
      %109 = llvm.insertvalue %108, %10[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %110 = llvm.extractvalue %109[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
      %111 = llvm.mul %58, %18 : i32
      %112 = llvm.mul %59, %22 : i32
      %113 = llvm.extractvalue %arg5[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %114 = llvm.extractvalue %113[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %115 = llvm.extractvalue %113[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %116 = llvm.extractvalue %113[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
      %117 = llvm.select %26, %15, %36 : i1, i32
      %118 = llvm.add %117, %114 : i32
      %119 = llvm.sdiv %118, %18 : i32
      %120 = llvm.add %119, %36 : i32
      %121 = llvm.sub %20, %114 : i32
      %122 = llvm.sdiv %121, %18 : i32
      %123 = llvm.sub %20, %122 : i32
      %124 = llvm.icmp "slt" %114, %20 : i32
      %125 = llvm.icmp "sgt" %114, %20 : i32
      %126 = llvm.and %124, %16 : i1
      %127 = llvm.and %125, %26 : i1
      %128 = llvm.or %126, %127 : i1
      %129 = llvm.select %128, %120, %123 : i1, i32
      %130 = llvm.mul %116, %23 : i64
      %131 = llvm.select %26, %15, %36 : i1, i32
      %132 = llvm.add %131, %115 : i32
      %133 = llvm.sdiv %132, %22 : i32
      %134 = llvm.add %133, %36 : i32
      %135 = llvm.sub %20, %115 : i32
      %136 = llvm.sdiv %135, %22 : i32
      %137 = llvm.sub %20, %136 : i32
      %138 = llvm.icmp "slt" %115, %20 : i32
      %139 = llvm.icmp "sgt" %115, %20 : i32
      %140 = llvm.and %138, %16 : i1
      %141 = llvm.and %139, %26 : i1
      %142 = llvm.or %140, %141 : i1
      %143 = llvm.select %142, %134, %137 : i1, i32
      %144 = llvm.insertvalue %129, %11[0] : !llvm.struct<(i32, i32)> 
      %145 = llvm.insertvalue %143, %144[1] : !llvm.struct<(i32, i32)> 
      %146 = llvm.insertvalue %116, %9[0] : !llvm.struct<(i64, i64)> 
      %147 = llvm.insertvalue %130, %146[1] : !llvm.struct<(i64, i64)> 
      %148 = llvm.insertvalue %145, %8[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %149 = llvm.insertvalue %147, %148[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %150 = llvm.extractvalue %149[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
      %151 = llvm.sext %58 : i32 to i64
      %152 = llvm.mul %151, %130 : i64
      %153 = llvm.mul %59, %22 : i32
      %154 = llvm.sext %153 : i32 to i64
      %155 = llvm.add %152, %154 : i64
      %156 = llvm.extractvalue %arg5[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
      %157 = llvm.getelementptr %156[%155] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      %158 = llvm.ptrtoint %67 : !llvm.ptr<3> to i32
      %159 = llvm.lshr %158, %28 : i32
      %160 = nvvm.mma_smem_desc(%159, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      %161 = llvm.ptrtoint %68 : !llvm.ptr<3> to i32
      %162 = llvm.lshr %161, %28 : i32
      %163 = nvvm.mma_smem_desc(%162, %36, %35, %6, %7) : (i32, i32, i32, i8, i8) -> i64
      nvvm.barrier id = %36 number_of_threads = %18
      %164 = llvm.load %62 : !llvm.ptr<3> -> i32
      %165 = llvm.sdiv %39, %17 : i32
      %166 = llvm.mul %165, %24 : i32
      %167 = llvm.add %164, %166 : i32
      %168 = llvm.mul %150, %25 : i64
      %169 = llvm.srem %39, %17 : i32
      %170 = llvm.sext %169 : i32 to i64
      %171 = llvm.mul %170, %150 : i64
      %172 = llvm.sext %165 : i32 to i64
      %173 = llvm.mul %172, %168 : i64
      %174 = llvm.add %171, %173 : i64
      %175 = llvm.getelementptr %157[%174] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
      llvm.cond_br %69, ^bb13, ^bb108
    ^bb13:  // pred: ^bb12
      nvvm.mbarrier.try_wait.parity.shared %77, %36, %27 : !llvm.ptr<3>, i32, i32
      %176 = llvm.getelementptr %arg1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %177 = llvm.getelementptr %arg3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
      %178 = llvm.icmp "slt" %110, %29 : i32
      %179 = llvm.select %178, %110, %29 : i1, i32
      llvm.br ^bb14(%20, %20, %36, %20 : i32, i32, i32, i32)
    ^bb14(%180: i32, %181: i32, %182: i32, %183: i32):  // 2 preds: ^bb13, ^bb31
      %184 = llvm.icmp "slt" %180, %179 : i32
      llvm.cond_br %184, ^bb15, ^bb32
    ^bb15:  // pred: ^bb14
      %185 = llvm.getelementptr %73[%181] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.try_wait.parity.shared %185, %182, %27 : !llvm.ptr<3>, i32, i32
      %186 = nvvm.elect.sync -> i1
      llvm.cond_br %186, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %187 = llvm.getelementptr %13[%181] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %187, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %188 = llvm.add %181, %36 : i32
      %189 = llvm.add %183, %36 : i32
      %190 = llvm.icmp "eq" %188, %28 : i32
      %191 = llvm.select %190, %20, %188 : i1, i32
      llvm.cond_br %190, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %192 = llvm.xor %182, %36 : i32
      llvm.br ^bb20(%192 : i32)
    ^bb19:  // pred: ^bb17
      llvm.br ^bb20(%182 : i32)
    ^bb20(%193: i32):  // 2 preds: ^bb18, ^bb19
      llvm.br ^bb21
    ^bb21:  // pred: ^bb20
      %194 = llvm.mul %183, %35 : i32
      %195 = llvm.mul %181, %5 : i32
      %196 = llvm.getelementptr %67[%195] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %197 = llvm.getelementptr %13[%181] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb22(%20 : i32)
    ^bb22(%198: i32):  // 2 preds: ^bb21, ^bb25
      %199 = llvm.icmp "slt" %198, %36 : i32
      llvm.cond_br %199, ^bb23, ^bb26 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %200 = nvvm.elect.sync -> i1
      llvm.cond_br %200, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      nvvm.cp.async.bulk.tensor.shared.cluster.global %196, %176, %197, box[%194, %111] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %201 = llvm.add %198, %36 : i32
      llvm.br ^bb22(%201 : i32)
    ^bb26:  // pred: ^bb22
      %202 = llvm.mul %183, %35 : i32
      %203 = llvm.mul %181, %4 : i32
      %204 = llvm.getelementptr %68[%203] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb27(%20 : i32)
    ^bb27(%205: i32):  // 2 preds: ^bb26, ^bb30
      %206 = llvm.icmp "slt" %205, %36 : i32
      llvm.cond_br %206, ^bb28, ^bb31 {llvm.loop_annotation = #loop_annotation}
    ^bb28:  // pred: ^bb27
      %207 = nvvm.elect.sync -> i1
      llvm.cond_br %207, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      nvvm.cp.async.bulk.tensor.shared.cluster.global %204, %177, %197, box[%202, %112] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %208 = llvm.add %205, %36 : i32
      llvm.br ^bb27(%208 : i32)
    ^bb31:  // pred: ^bb27
      %209 = llvm.add %180, %36 : i32
      llvm.br ^bb14(%209, %191, %193, %189 : i32, i32, i32, i32)
    ^bb32:  // pred: ^bb14
      llvm.br ^bb33(%20, %183, %181, %182, %20, %20, %arg0 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb33(%210: i32, %211: i32, %212: i32, %213: i32, %214: i32, %215: i32, %216: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb32, ^bb104
      %217 = llvm.icmp "slt" %210, %110 : i32
      llvm.cond_br %217, ^bb34, ^bb105
    ^bb34:  // pred: ^bb33
      %218 = llvm.add %210, %179 : i32
      %219 = llvm.icmp "ult" %218, %110 : i32
      llvm.cond_br %219, ^bb35, ^bb52
    ^bb35:  // pred: ^bb34
      %220 = llvm.getelementptr %73[%212] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.try_wait.parity.shared %220, %213, %27 : !llvm.ptr<3>, i32, i32
      %221 = nvvm.elect.sync -> i1
      llvm.cond_br %221, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %222 = llvm.getelementptr %13[%212] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.txn %222, %30 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      llvm.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %223 = llvm.add %212, %36 : i32
      %224 = llvm.add %211, %36 : i32
      %225 = llvm.icmp "eq" %223, %28 : i32
      %226 = llvm.select %225, %20, %223 : i1, i32
      llvm.cond_br %225, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %227 = llvm.xor %213, %36 : i32
      llvm.br ^bb40(%227 : i32)
    ^bb39:  // pred: ^bb37
      llvm.br ^bb40(%213 : i32)
    ^bb40(%228: i32):  // 2 preds: ^bb38, ^bb39
      llvm.br ^bb41
    ^bb41:  // pred: ^bb40
      %229 = llvm.mul %211, %35 : i32
      %230 = llvm.mul %212, %5 : i32
      %231 = llvm.getelementptr %67[%230] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      %232 = llvm.getelementptr %13[%212] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      llvm.br ^bb42(%20 : i32)
    ^bb42(%233: i32):  // 2 preds: ^bb41, ^bb45
      %234 = llvm.icmp "slt" %233, %36 : i32
      llvm.cond_br %234, ^bb43, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %235 = nvvm.elect.sync -> i1
      llvm.cond_br %235, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      nvvm.cp.async.bulk.tensor.shared.cluster.global %231, %176, %232, box[%229, %111] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %236 = llvm.add %233, %36 : i32
      llvm.br ^bb42(%236 : i32)
    ^bb46:  // pred: ^bb42
      %237 = llvm.mul %211, %35 : i32
      %238 = llvm.mul %212, %4 : i32
      %239 = llvm.getelementptr %68[%238] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
      llvm.br ^bb47(%20 : i32)
    ^bb47(%240: i32):  // 2 preds: ^bb46, ^bb50
      %241 = llvm.icmp "slt" %240, %36 : i32
      llvm.cond_br %241, ^bb48, ^bb51 {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %242 = nvvm.elect.sync -> i1
      llvm.cond_br %242, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      nvvm.cp.async.bulk.tensor.shared.cluster.global %239, %177, %232, box[%237, %112] {useIntrinsic = true} : <3>, !llvm.ptr
      llvm.br ^bb50
    ^bb50:  // 2 preds: ^bb48, ^bb49
      %243 = llvm.add %240, %36 : i32
      llvm.br ^bb47(%243 : i32)
    ^bb51:  // pred: ^bb47
      llvm.br ^bb53(%226, %228, %224 : i32, i32, i32)
    ^bb52:  // pred: ^bb34
      llvm.br ^bb53(%212, %213, %211 : i32, i32, i32)
    ^bb53(%244: i32, %245: i32, %246: i32):  // 2 preds: ^bb51, ^bb52
      llvm.br ^bb54
    ^bb54:  // pred: ^bb53
      %247 = llvm.getelementptr %13[%214] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.mbarrier.try_wait.parity.shared %247, %215, %27 : !llvm.ptr<3>, i32, i32
      %248 = llvm.add %214, %36 : i32
      %249 = llvm.icmp "eq" %248, %28 : i32
      %250 = llvm.select %249, %20, %248 : i1, i32
      llvm.cond_br %249, ^bb55, ^bb56
    ^bb55:  // pred: ^bb54
      %251 = llvm.xor %215, %36 : i32
      llvm.br ^bb57(%251 : i32)
    ^bb56:  // pred: ^bb54
      llvm.br ^bb57(%215 : i32)
    ^bb57(%252: i32):  // 2 preds: ^bb55, ^bb56
      llvm.br ^bb58
    ^bb58:  // pred: ^bb57
      %253 = llvm.mul %214, %3 : i32
      %254 = llvm.bitcast %160 : i64 to vector<2xi32>
      %255 = llvm.extractelement %254[%20 : i32] : vector<2xi32>
      %256 = llvm.add %255, %253 : i32
      %257 = llvm.insertelement %256, %254[%20 : i32] : vector<2xi32>
      %258 = llvm.bitcast %257 : vector<2xi32> to i64
      %259 = llvm.mul %214, %2 : i32
      %260 = llvm.bitcast %163 : i64 to vector<2xi32>
      %261 = llvm.extractelement %260[%20 : i32] : vector<2xi32>
      %262 = llvm.add %261, %259 : i32
      %263 = llvm.insertelement %262, %260[%20 : i32] : vector<2xi32>
      %264 = llvm.bitcast %263 : vector<2xi32> to i64
      %265 = llvm.extractvalue %216[1] : !llvm.struct<(i1, i1, i1)> 
      %266 = llvm.extractvalue %216[2] : !llvm.struct<(i1, i1, i1)> 
      %267 = llvm.extractvalue %216[0] : !llvm.struct<(i1, i1, i1)> 
      %268 = llvm.zext %265 : i1 to i32
      %269 = llvm.zext %266 : i1 to i32
      %270 = llvm.shl %268, %32 : i32
      %271 = llvm.shl %269, %33 : i32
      %272 = llvm.or %270, %31 : i32
      %273 = llvm.or %272, %271 : i32
      llvm.br ^bb59(%20 : i32)
    ^bb59(%274: i32):  // 2 preds: ^bb58, ^bb68
      %275 = llvm.icmp "slt" %274, %36 : i32
      llvm.cond_br %275, ^bb60, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb60:  // pred: ^bb59
      llvm.br ^bb61(%20 : i32)
    ^bb61(%276: i32):  // 2 preds: ^bb60, ^bb67
      %277 = llvm.icmp "slt" %276, %36 : i32
      llvm.cond_br %277, ^bb62, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      llvm.br ^bb63(%20 : i32)
    ^bb63(%278: i32):  // 2 preds: ^bb62, ^bb66
      %279 = llvm.icmp "slt" %278, %36 : i32
      llvm.cond_br %279, ^bb64, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb64:  // pred: ^bb63
      %280 = llvm.inttoptr %164 : i32 to !llvm.ptr<6>
      %281 = nvvm.elect.sync -> i1
      llvm.cond_br %281, ^bb65, ^bb66
    ^bb65:  // pred: ^bb64
      nvvm.tcgen05.mma %280, %258, %264, %273, %267 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %282 = llvm.add %278, %36 : i32
      llvm.br ^bb63(%282 : i32)
    ^bb67:  // pred: ^bb63
      %283 = llvm.add %276, %36 : i32
      llvm.br ^bb61(%283 : i32)
    ^bb68:  // pred: ^bb61
      %284 = llvm.add %274, %36 : i32
      llvm.br ^bb59(%284 : i32)
    ^bb69:  // pred: ^bb59
      %285 = llvm.insertvalue %26, %216[0] : !llvm.struct<(i1, i1, i1)> 
      %286 = llvm.mul %214, %3 : i32
      %287 = llvm.add %286, %29 : i32
      %288 = llvm.bitcast %160 : i64 to vector<2xi32>
      %289 = llvm.extractelement %288[%20 : i32] : vector<2xi32>
      %290 = llvm.add %289, %287 : i32
      %291 = llvm.insertelement %290, %288[%20 : i32] : vector<2xi32>
      %292 = llvm.bitcast %291 : vector<2xi32> to i64
      %293 = llvm.mul %214, %2 : i32
      %294 = llvm.add %293, %29 : i32
      %295 = llvm.bitcast %163 : i64 to vector<2xi32>
      %296 = llvm.extractelement %295[%20 : i32] : vector<2xi32>
      %297 = llvm.add %296, %294 : i32
      %298 = llvm.insertelement %297, %295[%20 : i32] : vector<2xi32>
      %299 = llvm.bitcast %298 : vector<2xi32> to i64
      %300 = llvm.extractvalue %216[1] : !llvm.struct<(i1, i1, i1)> 
      %301 = llvm.extractvalue %216[2] : !llvm.struct<(i1, i1, i1)> 
      %302 = llvm.zext %300 : i1 to i32
      %303 = llvm.zext %301 : i1 to i32
      %304 = llvm.shl %302, %32 : i32
      %305 = llvm.shl %303, %33 : i32
      %306 = llvm.or %304, %31 : i32
      %307 = llvm.or %306, %305 : i32
      llvm.br ^bb70(%20 : i32)
    ^bb70(%308: i32):  // 2 preds: ^bb69, ^bb79
      %309 = llvm.icmp "slt" %308, %36 : i32
      llvm.cond_br %309, ^bb71, ^bb80 {llvm.loop_annotation = #loop_annotation}
    ^bb71:  // pred: ^bb70
      llvm.br ^bb72(%20 : i32)
    ^bb72(%310: i32):  // 2 preds: ^bb71, ^bb78
      %311 = llvm.icmp "slt" %310, %36 : i32
      llvm.cond_br %311, ^bb73, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb73:  // pred: ^bb72
      llvm.br ^bb74(%20 : i32)
    ^bb74(%312: i32):  // 2 preds: ^bb73, ^bb77
      %313 = llvm.icmp "slt" %312, %36 : i32
      llvm.cond_br %313, ^bb75, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb75:  // pred: ^bb74
      %314 = llvm.inttoptr %164 : i32 to !llvm.ptr<6>
      %315 = nvvm.elect.sync -> i1
      llvm.cond_br %315, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      nvvm.tcgen05.mma %314, %292, %299, %307, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %316 = llvm.add %312, %36 : i32
      llvm.br ^bb74(%316 : i32)
    ^bb78:  // pred: ^bb74
      %317 = llvm.add %310, %36 : i32
      llvm.br ^bb72(%317 : i32)
    ^bb79:  // pred: ^bb72
      %318 = llvm.add %308, %36 : i32
      llvm.br ^bb70(%318 : i32)
    ^bb80:  // pred: ^bb70
      %319 = llvm.insertvalue %26, %285[0] : !llvm.struct<(i1, i1, i1)> 
      %320 = llvm.mul %214, %3 : i32
      %321 = llvm.add %320, %28 : i32
      %322 = llvm.bitcast %160 : i64 to vector<2xi32>
      %323 = llvm.extractelement %322[%20 : i32] : vector<2xi32>
      %324 = llvm.add %323, %321 : i32
      %325 = llvm.insertelement %324, %322[%20 : i32] : vector<2xi32>
      %326 = llvm.bitcast %325 : vector<2xi32> to i64
      %327 = llvm.mul %214, %2 : i32
      %328 = llvm.add %327, %28 : i32
      %329 = llvm.bitcast %163 : i64 to vector<2xi32>
      %330 = llvm.extractelement %329[%20 : i32] : vector<2xi32>
      %331 = llvm.add %330, %328 : i32
      %332 = llvm.insertelement %331, %329[%20 : i32] : vector<2xi32>
      %333 = llvm.bitcast %332 : vector<2xi32> to i64
      %334 = llvm.extractvalue %216[1] : !llvm.struct<(i1, i1, i1)> 
      %335 = llvm.extractvalue %216[2] : !llvm.struct<(i1, i1, i1)> 
      %336 = llvm.zext %334 : i1 to i32
      %337 = llvm.zext %335 : i1 to i32
      %338 = llvm.shl %336, %32 : i32
      %339 = llvm.shl %337, %33 : i32
      %340 = llvm.or %338, %31 : i32
      %341 = llvm.or %340, %339 : i32
      llvm.br ^bb81(%20 : i32)
    ^bb81(%342: i32):  // 2 preds: ^bb80, ^bb90
      %343 = llvm.icmp "slt" %342, %36 : i32
      llvm.cond_br %343, ^bb82, ^bb91 {llvm.loop_annotation = #loop_annotation}
    ^bb82:  // pred: ^bb81
      llvm.br ^bb83(%20 : i32)
    ^bb83(%344: i32):  // 2 preds: ^bb82, ^bb89
      %345 = llvm.icmp "slt" %344, %36 : i32
      llvm.cond_br %345, ^bb84, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      llvm.br ^bb85(%20 : i32)
    ^bb85(%346: i32):  // 2 preds: ^bb84, ^bb88
      %347 = llvm.icmp "slt" %346, %36 : i32
      llvm.cond_br %347, ^bb86, ^bb89 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      %348 = llvm.inttoptr %164 : i32 to !llvm.ptr<6>
      %349 = nvvm.elect.sync -> i1
      llvm.cond_br %349, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      nvvm.tcgen05.mma %348, %326, %333, %341, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %350 = llvm.add %346, %36 : i32
      llvm.br ^bb85(%350 : i32)
    ^bb89:  // pred: ^bb85
      %351 = llvm.add %344, %36 : i32
      llvm.br ^bb83(%351 : i32)
    ^bb90:  // pred: ^bb83
      %352 = llvm.add %342, %36 : i32
      llvm.br ^bb81(%352 : i32)
    ^bb91:  // pred: ^bb81
      %353 = llvm.insertvalue %26, %319[0] : !llvm.struct<(i1, i1, i1)> 
      %354 = llvm.mul %214, %3 : i32
      %355 = llvm.add %354, %12 : i32
      %356 = llvm.bitcast %160 : i64 to vector<2xi32>
      %357 = llvm.extractelement %356[%20 : i32] : vector<2xi32>
      %358 = llvm.add %357, %355 : i32
      %359 = llvm.insertelement %358, %356[%20 : i32] : vector<2xi32>
      %360 = llvm.bitcast %359 : vector<2xi32> to i64
      %361 = llvm.mul %214, %2 : i32
      %362 = llvm.add %361, %12 : i32
      %363 = llvm.bitcast %163 : i64 to vector<2xi32>
      %364 = llvm.extractelement %363[%20 : i32] : vector<2xi32>
      %365 = llvm.add %364, %362 : i32
      %366 = llvm.insertelement %365, %363[%20 : i32] : vector<2xi32>
      %367 = llvm.bitcast %366 : vector<2xi32> to i64
      %368 = llvm.extractvalue %216[1] : !llvm.struct<(i1, i1, i1)> 
      %369 = llvm.extractvalue %216[2] : !llvm.struct<(i1, i1, i1)> 
      %370 = llvm.zext %368 : i1 to i32
      %371 = llvm.zext %369 : i1 to i32
      %372 = llvm.shl %370, %32 : i32
      %373 = llvm.shl %371, %33 : i32
      %374 = llvm.or %372, %31 : i32
      %375 = llvm.or %374, %373 : i32
      llvm.br ^bb92(%20 : i32)
    ^bb92(%376: i32):  // 2 preds: ^bb91, ^bb101
      %377 = llvm.icmp "slt" %376, %36 : i32
      llvm.cond_br %377, ^bb93, ^bb102 {llvm.loop_annotation = #loop_annotation}
    ^bb93:  // pred: ^bb92
      llvm.br ^bb94(%20 : i32)
    ^bb94(%378: i32):  // 2 preds: ^bb93, ^bb100
      %379 = llvm.icmp "slt" %378, %36 : i32
      llvm.cond_br %379, ^bb95, ^bb101 {llvm.loop_annotation = #loop_annotation}
    ^bb95:  // pred: ^bb94
      llvm.br ^bb96(%20 : i32)
    ^bb96(%380: i32):  // 2 preds: ^bb95, ^bb99
      %381 = llvm.icmp "slt" %380, %36 : i32
      llvm.cond_br %381, ^bb97, ^bb100 {llvm.loop_annotation = #loop_annotation}
    ^bb97:  // pred: ^bb96
      %382 = llvm.inttoptr %164 : i32 to !llvm.ptr<6>
      %383 = nvvm.elect.sync -> i1
      llvm.cond_br %383, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      nvvm.tcgen05.mma %382, %360, %367, %375, %26 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
      llvm.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      %384 = llvm.add %380, %36 : i32
      llvm.br ^bb96(%384 : i32)
    ^bb100:  // pred: ^bb96
      %385 = llvm.add %378, %36 : i32
      llvm.br ^bb94(%385 : i32)
    ^bb101:  // pred: ^bb94
      %386 = llvm.add %376, %36 : i32
      llvm.br ^bb92(%386 : i32)
    ^bb102:  // pred: ^bb92
      %387 = llvm.insertvalue %26, %353[0] : !llvm.struct<(i1, i1, i1)> 
      %388 = nvvm.elect.sync -> i1
      llvm.cond_br %388, ^bb103, ^bb104
    ^bb103:  // pred: ^bb102
      %389 = llvm.getelementptr %73[%214] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
      nvvm.tcgen05.commit.arrive %389 : !llvm.ptr<3>
      llvm.br ^bb104
    ^bb104:  // 2 preds: ^bb102, ^bb103
      %390 = llvm.add %210, %36 : i32
      llvm.br ^bb33(%390, %246, %244, %245, %250, %252, %387 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb105:  // pred: ^bb33
      %391 = nvvm.elect.sync -> i1
      llvm.cond_br %391, ^bb106, ^bb107
    ^bb106:  // pred: ^bb105
      nvvm.tcgen05.commit.arrive %61 : !llvm.ptr<3>
      llvm.br ^bb107
    ^bb107:  // 2 preds: ^bb105, ^bb106
      llvm.br ^bb108
    ^bb108:  // 2 preds: ^bb12, ^bb107
      llvm.cond_br %69, ^bb109, ^bb110
    ^bb109:  // pred: ^bb108
      nvvm.tcgen05.relinquish_alloc_permit
      llvm.br ^bb110
    ^bb110:  // 2 preds: ^bb108, ^bb109
      nvvm.mbarrier.try_wait.parity.shared %61, %20, %27 : !llvm.ptr<3>, i32, i32
      llvm.br ^bb111(%20 : i32)
    ^bb111(%392: i32):  // 2 preds: ^bb110, ^bb118
      %393 = llvm.icmp "slt" %392, %28 : i32
      llvm.cond_br %393, ^bb112, ^bb119
    ^bb112:  // pred: ^bb111
      %394 = llvm.srem %392, %28 : i32
      %395 = llvm.mul %394, %35 : i32
      %396 = llvm.add %167, %395 : i32
      llvm.br ^bb113(%20 : i32)
    ^bb113(%397: i32):  // 2 preds: ^bb112, ^bb114
      %398 = llvm.icmp "slt" %397, %36 : i32
      llvm.cond_br %398, ^bb114, ^bb115 {llvm.loop_annotation = #loop_annotation}
    ^bb114:  // pred: ^bb113
      %399 = llvm.inttoptr %396 : i32 to !llvm.ptr<6>
      %400 = nvvm.tcgen05.ld %399 {num = 64 : i32, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>} : vector<64xi32>
      llvm.store %400, %38 : vector<64xi32>, !llvm.ptr
      %401 = llvm.add %397, %36 : i32
      llvm.br ^bb113(%401 : i32)
    ^bb115:  // pred: ^bb113
      %402 = llvm.load %38 {alignment = 32 : i64} : !llvm.ptr -> vector<64xf32>
      %403 = llvm.fptrunc %402 : vector<64xf32> to vector<64xf16>
      llvm.store %403, %37 {alignment = 32 : i64} : vector<64xf16>, !llvm.ptr
      %404 = llvm.srem %392, %28 : i32
      %405 = llvm.mul %404, %35 : i32
      %406 = llvm.getelementptr %175[%405] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      llvm.br ^bb116(%20 : i32)
    ^bb116(%407: i32):  // 2 preds: ^bb115, ^bb117
      %408 = llvm.icmp "slt" %407, %0 : i32
      llvm.cond_br %408, ^bb117, ^bb118 {llvm.loop_annotation = #loop_annotation}
    ^bb117:  // pred: ^bb116
      %409 = llvm.mul %407, %0 : i32
      %410 = llvm.getelementptr %37[%409] : (!llvm.ptr, i32) -> !llvm.ptr, f16
      %411 = llvm.getelementptr %406[%409] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
      %412 = llvm.load %410 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %412, %411 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %413 = llvm.add %407, %36 : i32
      llvm.br ^bb116(%413 : i32)
    ^bb118:  // pred: ^bb116
      %414 = llvm.add %392, %36 : i32
      llvm.br ^bb111(%414 : i32)
    ^bb119:  // pred: ^bb111
      nvvm.mbarrier.txn %77, %36 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %36
      llvm.cond_br %69, ^bb120, ^bb121
    ^bb120:  // pred: ^bb119
      %415 = llvm.inttoptr %164 : i32 to !llvm.ptr<6>
      nvvm.tcgen05.dealloc %415, %21 : !llvm.ptr<6>, i32
      llvm.br ^bb121
    ^bb121:  // 2 preds: ^bb119, ^bb120
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
    %191 = llvm.insertvalue %25, %4[0] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %192 = llvm.insertvalue %190, %191[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %193 = builtin.unrealized_conversion_cast %192 : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> to !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %194 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %195 = llvm.extractvalue %194[0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %196 = llvm.extractvalue %195[0] : !llvm.struct<(i32, i32)> 
    %197 = llvm.extractvalue %195[1] : !llvm.struct<(i32, i32)> 
    %198 = llvm.select %0, %1, %3 : i1, i32
    %199 = llvm.add %198, %196 : i32
    %200 = llvm.sdiv %199, %26 : i32
    %201 = llvm.add %200, %3 : i32
    %202 = llvm.sub %2, %196 : i32
    %203 = llvm.sdiv %202, %26 : i32
    %204 = llvm.sub %2, %203 : i32
    %205 = llvm.icmp "slt" %196, %2 : i32
    %206 = llvm.icmp "sgt" %196, %2 : i32
    %207 = llvm.and %205, %8 : i1
    %208 = llvm.and %206, %0 : i1
    %209 = llvm.or %207, %208 : i1
    %210 = llvm.select %209, %201, %204 : i1, i32
    %211 = llvm.select %0, %1, %3 : i1, i32
    %212 = llvm.add %211, %197 : i32
    %213 = llvm.sdiv %212, %27 : i32
    %214 = llvm.add %213, %3 : i32
    %215 = llvm.sub %2, %197 : i32
    %216 = llvm.sdiv %215, %27 : i32
    %217 = llvm.sub %2, %216 : i32
    %218 = llvm.icmp "slt" %197, %2 : i32
    %219 = llvm.icmp "sgt" %197, %2 : i32
    %220 = llvm.and %218, %8 : i1
    %221 = llvm.and %219, %0 : i1
    %222 = llvm.or %220, %221 : i1
    %223 = llvm.select %222, %214, %217 : i1, i32
    %224 = llvm.sext %210 : i32 to i64
    %225 = builtin.unrealized_conversion_cast %224 : i64 to index
    %226 = llvm.sext %223 : i32 to i64
    %227 = builtin.unrealized_conversion_cast %226 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0 blocks in (%225, %227, %37) threads in (%36, %37, %37)  dynamic_shared_memory_size %30 args(%41 : !mma_f16_f16_f32_128x256x16_, %121 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %127 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %187 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %193 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %35 : !memref_gmem_f16_) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0, %arg1, %arg2) : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>, !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) -> ()
    llvm.return
  }
}
