gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
  llvm.mlir.global external @__dynamic_shmem__0() {addr_space = 3 : i32, alignment = 1024 : i64, dso_local} : !llvm.array<0 x i8>
  llvm.func @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !llvm.struct<(i1, i1, i1)>, %arg1: !llvm.ptr {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg3: !llvm.ptr {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, %arg4: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg5: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.constant(16 : i32) : i32
    %1 = llvm.mlir.constant(dense<0> : vector<4xi32>) : vector<4xi32>
    %2 = llvm.mlir.constant(2048 : i32) : i32
    %3 = llvm.mlir.constant(1024 : i32) : i32
    %4 = llvm.mlir.constant(16384 : i32) : i32
    %5 = llvm.mlir.constant(8192 : i32) : i32
    %6 = llvm.mlir.zero : !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)>
    %7 = llvm.mlir.constant(0 : i8) : i8
    %8 = llvm.mlir.constant(2 : i8) : i8
    %9 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
    %10 = llvm.mlir.undef : !llvm.struct<(i64, i64)>
    %11 = llvm.mlir.undef : !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %12 = llvm.mlir.undef : !llvm.struct<(i32, i32)>
    %13 = llvm.mlir.constant(6 : i32) : i32
    %14 = llvm.mlir.addressof @__dynamic_shmem__0 : !llvm.ptr<3>
    %15 = llvm.mlir.constant(31 : i32) : i32
    %16 = llvm.mlir.constant(-1 : i32) : i32
    %17 = llvm.mlir.constant(false) : i1
    %18 = llvm.mlir.constant(32 : i32) : i32
    %19 = llvm.mlir.constant(128 : i32) : i32
    %20 = llvm.mlir.constant(-128 : i32) : i32
    %21 = llvm.mlir.constant(0 : i32) : i32
    %22 = llvm.mlir.constant(512 : i32) : i32
    %23 = llvm.mlir.constant(256 : i32) : i32
    %24 = llvm.mlir.constant(128 : i64) : i64
    %25 = llvm.mlir.constant(2097152 : i32) : i32
    %26 = llvm.mlir.constant(32 : i64) : i64
    %27 = llvm.mlir.constant(true) : i1
    %28 = llvm.mlir.constant(10000000 : i32) : i32
    %29 = llvm.mlir.constant(4 : i32) : i32
    %30 = llvm.mlir.constant(2 : i32) : i32
    %31 = llvm.mlir.constant(49152 : i32) : i32
    %32 = llvm.mlir.constant(138412048 : i32) : i32
    %33 = llvm.mlir.constant(13 : i32) : i32
    %34 = llvm.mlir.constant(14 : i32) : i32
    %35 = llvm.mlir.constant(127 : i32) : i32
    %36 = llvm.mlir.constant(64 : i32) : i32
    %37 = llvm.mlir.constant(1 : i32) : i32
    %38 = llvm.alloca %36 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %39 = llvm.alloca %36 x i32 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %40 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %41 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
    %42 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
    %43 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
    %44 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
    %45 = llvm.mul %41, %43 : i32
    %46 = llvm.add %40, %45 : i32
    %47 = llvm.mul %42, %43 : i32
    %48 = llvm.mul %47, %44 : i32
    %49 = llvm.add %46, %48 : i32
    %50 = llvm.sdiv %49, %18 : i32
    %51 = llvm.mul %50, %18 : i32
    %52 = llvm.icmp "ne" %49, %51 : i32
    %53 = llvm.icmp "slt" %49, %21 : i32
    %54 = llvm.icmp "ne" %53, %17 : i1
    %55 = llvm.and %52, %54 : i1
    %56 = llvm.add %50, %16 : i32
    %57 = llvm.select %55, %56, %50 : i1, i32
    %58 = nvvm.shfl.sync  idx %16, %57, %21, %15 : i32 -> i32
    %59 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %60 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
    %61 = llvm.getelementptr %14[88] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
    %62 = llvm.getelementptr %14[64] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
    %63 = llvm.getelementptr %14[80] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
    %64 = llvm.ptrtoint %61 : !llvm.ptr<3> to i32
    %65 = llvm.add %64, %35 : i32
    %66 = llvm.and %65, %20 : i32
    %67 = llvm.sext %66 : i32 to i64
    %68 = llvm.inttoptr %67 : i64 to !llvm.ptr<3>
    %69 = llvm.getelementptr %68[65536] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
    %70 = llvm.icmp "eq" %58, %21 : i32
    llvm.cond_br %70, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    nvvm.tcgen05.alloc %63, %22 : !llvm.ptr<3>, i32
    llvm.br ^bb2
  ^bb2:  // 2 preds: ^bb0, ^bb1
    llvm.cond_br %70, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    llvm.inline_asm has_side_effects asm_dialect = att "prefetch.tensormap [$0];", "l" %arg1 : (!llvm.ptr) -> ()
    llvm.inline_asm has_side_effects asm_dialect = att "prefetch.tensormap [$0];", "l" %arg3 : (!llvm.ptr) -> ()
    llvm.br ^bb4
  ^bb4:  // 2 preds: ^bb2, ^bb3
    llvm.cond_br %70, ^bb5, ^bb6
  ^bb5:  // pred: ^bb4
    nvvm.mbarrier.init.shared %14, %37 : !llvm.ptr<3>, i32
    %71 = llvm.getelementptr %14[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %71, %37 : !llvm.ptr<3>, i32
    %72 = llvm.getelementptr %14[2] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %72, %37 : !llvm.ptr<3>, i32
    %73 = llvm.getelementptr %14[3] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %73, %37 : !llvm.ptr<3>, i32
    llvm.br ^bb6
  ^bb6:  // 2 preds: ^bb4, ^bb5
    %74 = llvm.getelementptr %14[4] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    llvm.cond_br %70, ^bb7, ^bb8
  ^bb7:  // pred: ^bb6
    nvvm.mbarrier.init.shared %74, %37 : !llvm.ptr<3>, i32
    %75 = llvm.getelementptr %14[5] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %75, %37 : !llvm.ptr<3>, i32
    %76 = llvm.getelementptr %14[6] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %76, %37 : !llvm.ptr<3>, i32
    %77 = llvm.getelementptr %14[7] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.init.shared %77, %37 : !llvm.ptr<3>, i32
    llvm.br ^bb8
  ^bb8:  // 2 preds: ^bb6, ^bb7
    %78 = llvm.mlir.constant(0 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %78 : (i32) -> ()
    nvvm.barrier
    llvm.cond_br %70, ^bb9, ^bb10
  ^bb9:  // pred: ^bb8
    nvvm.mbarrier.init.shared %62, %37 : !llvm.ptr<3>, i32
    llvm.br ^bb10
  ^bb10:  // 2 preds: ^bb8, ^bb9
    %79 = llvm.getelementptr %62[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    llvm.cond_br %70, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    nvvm.mbarrier.init.shared %79, %19 : !llvm.ptr<3>, i32
    llvm.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %80 = llvm.mlir.constant(0 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %80 : (i32) -> ()
    nvvm.barrier
    %81 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %82 = llvm.extractvalue %81[0, 0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %83 = llvm.extractvalue %81[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %84 = llvm.select %27, %16, %37 : i1, i32
    %85 = llvm.add %84, %82 : i32
    %86 = llvm.sdiv %85, %19 : i32
    %87 = llvm.add %86, %37 : i32
    %88 = llvm.sub %21, %82 : i32
    %89 = llvm.sdiv %88, %19 : i32
    %90 = llvm.sub %21, %89 : i32
    %91 = llvm.icmp "slt" %82, %21 : i32
    %92 = llvm.icmp "sgt" %82, %21 : i32
    %93 = llvm.and %91, %17 : i1
    %94 = llvm.and %92, %27 : i1
    %95 = llvm.or %93, %94 : i1
    %96 = llvm.select %95, %87, %90 : i1, i32
    %97 = llvm.add %84, %83 : i32
    %98 = llvm.sdiv %97, %36 : i32
    %99 = llvm.add %98, %37 : i32
    %100 = llvm.sub %21, %83 : i32
    %101 = llvm.sdiv %100, %36 : i32
    %102 = llvm.sub %21, %101 : i32
    %103 = llvm.icmp "slt" %83, %21 : i32
    %104 = llvm.icmp "sgt" %83, %21 : i32
    %105 = llvm.and %103, %17 : i1
    %106 = llvm.and %104, %27 : i1
    %107 = llvm.or %105, %106 : i1
    %108 = llvm.select %107, %99, %102 : i1, i32
    %109 = llvm.insertvalue %96, %12[0] : !llvm.struct<(i32, i32)> 
    %110 = llvm.insertvalue %108, %109[1] : !llvm.struct<(i32, i32)> 
    %111 = llvm.insertvalue %110, %11[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %112 = llvm.extractvalue %111[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %113 = llvm.mul %59, %19 : i32
    %114 = llvm.mul %60, %23 : i32
    %115 = llvm.extractvalue %arg5[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %116 = llvm.extractvalue %115[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %117 = llvm.extractvalue %115[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %118 = llvm.extractvalue %115[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %119 = llvm.add %84, %116 : i32
    %120 = llvm.sdiv %119, %19 : i32
    %121 = llvm.add %120, %37 : i32
    %122 = llvm.sub %21, %116 : i32
    %123 = llvm.sdiv %122, %19 : i32
    %124 = llvm.sub %21, %123 : i32
    %125 = llvm.icmp "slt" %116, %21 : i32
    %126 = llvm.icmp "sgt" %116, %21 : i32
    %127 = llvm.and %125, %17 : i1
    %128 = llvm.and %126, %27 : i1
    %129 = llvm.or %127, %128 : i1
    %130 = llvm.select %129, %121, %124 : i1, i32
    %131 = llvm.mul %118, %24 : i64
    %132 = llvm.add %84, %117 : i32
    %133 = llvm.sdiv %132, %23 : i32
    %134 = llvm.add %133, %37 : i32
    %135 = llvm.sub %21, %117 : i32
    %136 = llvm.sdiv %135, %23 : i32
    %137 = llvm.sub %21, %136 : i32
    %138 = llvm.icmp "slt" %117, %21 : i32
    %139 = llvm.icmp "sgt" %117, %21 : i32
    %140 = llvm.and %138, %17 : i1
    %141 = llvm.and %139, %27 : i1
    %142 = llvm.or %140, %141 : i1
    %143 = llvm.select %142, %134, %137 : i1, i32
    %144 = llvm.insertvalue %130, %12[0] : !llvm.struct<(i32, i32)> 
    %145 = llvm.insertvalue %143, %144[1] : !llvm.struct<(i32, i32)> 
    %146 = llvm.insertvalue %118, %10[0] : !llvm.struct<(i64, i64)> 
    %147 = llvm.insertvalue %131, %146[1] : !llvm.struct<(i64, i64)> 
    %148 = llvm.insertvalue %145, %9[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %149 = llvm.insertvalue %147, %148[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %150 = llvm.extractvalue %149[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %151 = llvm.sext %59 : i32 to i64
    %152 = llvm.mul %151, %131 : i64
    %153 = llvm.sext %114 : i32 to i64
    %154 = llvm.add %152, %153 : i64
    %155 = llvm.extractvalue %arg5[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %156 = llvm.getelementptr %155[%154] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
    %157 = llvm.ptrtoint %68 : !llvm.ptr<3> to i32
    %158 = llvm.lshr %157, %29 : i32
    %159 = nvvm.mma_smem_desc(%158, %37, %36, %7, %8) : (i32, i32, i32, i8, i8) -> i64
    %160 = llvm.ptrtoint %69 : !llvm.ptr<3> to i32
    %161 = llvm.lshr %160, %29 : i32
    %162 = nvvm.mma_smem_desc(%161, %37, %36, %7, %8) : (i32, i32, i32, i8, i8) -> i64
    nvvm.barrier id = %37 number_of_threads = %19
    %163 = llvm.load %63 : !llvm.ptr<3> -> i32
    %164 = llvm.sdiv %40, %18 : i32
    %165 = llvm.mul %164, %25 : i32
    %166 = llvm.add %163, %165 : i32
    %167 = llvm.mul %150, %26 : i64
    %168 = llvm.srem %40, %18 : i32
    %169 = llvm.sext %168 : i32 to i64
    %170 = llvm.mul %169, %150 : i64
    %171 = llvm.sext %164 : i32 to i64
    %172 = llvm.mul %171, %167 : i64
    %173 = llvm.add %170, %172 : i64
    %174 = llvm.getelementptr %156[%173] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
    llvm.cond_br %70, ^bb13, ^bb107
  ^bb13:  // pred: ^bb12
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %79, %37, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %175 = llvm.getelementptr %arg1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
    %176 = llvm.getelementptr %arg3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
    %177 = llvm.icmp "slt" %112, %30 : i32
    %178 = llvm.select %177, %112, %30 : i1, i32
    llvm.br ^bb14(%21, %21, %37, %21 : i32, i32, i32, i32)
  ^bb14(%179: i32, %180: i32, %181: i32, %182: i32):  // 2 preds: ^bb13, ^bb31
    %183 = llvm.icmp "slt" %179, %178 : i32
    llvm.cond_br %183, ^bb15, ^bb32
  ^bb15:  // pred: ^bb14
    %184 = llvm.getelementptr %74[%180] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %184, %181, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %185 = nvvm.elect.sync -> i1
    llvm.cond_br %185, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %186 = llvm.getelementptr %14[%180] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.txn %186, %31 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    %187 = llvm.add %180, %37 : i32
    %188 = llvm.add %182, %37 : i32
    %189 = llvm.icmp "eq" %187, %29 : i32
    %190 = llvm.select %189, %21, %187 : i1, i32
    llvm.cond_br %189, ^bb18, ^bb19
  ^bb18:  // pred: ^bb17
    %191 = llvm.xor %181, %37 : i32
    llvm.br ^bb20(%191 : i32)
  ^bb19:  // pred: ^bb17
    llvm.br ^bb20(%181 : i32)
  ^bb20(%192: i32):  // 2 preds: ^bb18, ^bb19
    llvm.br ^bb21
  ^bb21:  // pred: ^bb20
    %193 = llvm.mul %182, %36 : i32
    %194 = llvm.mul %180, %5 : i32
    %195 = llvm.getelementptr %68[%194] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    %196 = llvm.getelementptr %14[%180] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    %197 = llvm.extractvalue %6[3] : !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)> 
    llvm.br ^bb22(%21 : i32)
  ^bb22(%198: i32):  // 2 preds: ^bb21, ^bb25
    %199 = llvm.icmp "slt" %198, %37 : i32
    llvm.cond_br %199, ^bb23, ^bb26 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb23:  // pred: ^bb22
    %200 = nvvm.elect.sync -> i1
    llvm.cond_br %200, ^bb24, ^bb25
  ^bb24:  // pred: ^bb23
    nvvm.cp.async.bulk.tensor.shared.cluster.global %195, %175, %196, box[%193, %113] l2_cache_hint = %197 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb25
  ^bb25:  // 2 preds: ^bb23, ^bb24
    %201 = llvm.add %198, %37 : i32
    llvm.br ^bb22(%201 : i32)
  ^bb26:  // pred: ^bb22
    %202 = llvm.mul %180, %4 : i32
    %203 = llvm.getelementptr %69[%202] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    llvm.br ^bb27(%21 : i32)
  ^bb27(%204: i32):  // 2 preds: ^bb26, ^bb30
    %205 = llvm.icmp "slt" %204, %37 : i32
    llvm.cond_br %205, ^bb28, ^bb31 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb28:  // pred: ^bb27
    %206 = nvvm.elect.sync -> i1
    llvm.cond_br %206, ^bb29, ^bb30
  ^bb29:  // pred: ^bb28
    nvvm.cp.async.bulk.tensor.shared.cluster.global %203, %176, %196, box[%193, %114] l2_cache_hint = %197 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb30
  ^bb30:  // 2 preds: ^bb28, ^bb29
    %207 = llvm.add %204, %37 : i32
    llvm.br ^bb27(%207 : i32)
  ^bb31:  // pred: ^bb27
    %208 = llvm.add %179, %37 : i32
    llvm.br ^bb14(%208, %190, %192, %188 : i32, i32, i32, i32)
  ^bb32:  // pred: ^bb14
    llvm.br ^bb33(%21, %182, %180, %181, %21, %21, %arg0 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
  ^bb33(%209: i32, %210: i32, %211: i32, %212: i32, %213: i32, %214: i32, %215: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb32, ^bb103
    %216 = llvm.icmp "slt" %209, %112 : i32
    llvm.cond_br %216, ^bb34, ^bb104
  ^bb34:  // pred: ^bb33
    %217 = llvm.add %209, %178 : i32
    %218 = llvm.icmp "ult" %217, %112 : i32
    llvm.cond_br %218, ^bb35, ^bb51(%211, %212, %210 : i32, i32, i32)
  ^bb35:  // pred: ^bb34
    %219 = llvm.getelementptr %74[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %219, %212, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %220 = nvvm.elect.sync -> i1
    llvm.cond_br %220, ^bb36, ^bb37
  ^bb36:  // pred: ^bb35
    %221 = llvm.getelementptr %14[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.txn %221, %31 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
    llvm.br ^bb37
  ^bb37:  // 2 preds: ^bb35, ^bb36
    %222 = llvm.add %211, %37 : i32
    %223 = llvm.add %210, %37 : i32
    %224 = llvm.icmp "eq" %222, %29 : i32
    %225 = llvm.select %224, %21, %222 : i1, i32
    llvm.cond_br %224, ^bb38, ^bb39
  ^bb38:  // pred: ^bb37
    %226 = llvm.xor %212, %37 : i32
    llvm.br ^bb40(%226 : i32)
  ^bb39:  // pred: ^bb37
    llvm.br ^bb40(%212 : i32)
  ^bb40(%227: i32):  // 2 preds: ^bb38, ^bb39
    llvm.br ^bb41
  ^bb41:  // pred: ^bb40
    %228 = llvm.mul %210, %36 : i32
    %229 = llvm.mul %211, %5 : i32
    %230 = llvm.getelementptr %68[%229] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    %231 = llvm.getelementptr %14[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    %232 = llvm.extractvalue %6[3] : !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)> 
    llvm.br ^bb42(%21 : i32)
  ^bb42(%233: i32):  // 2 preds: ^bb41, ^bb45
    %234 = llvm.icmp "slt" %233, %37 : i32
    llvm.cond_br %234, ^bb43, ^bb46 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb43:  // pred: ^bb42
    %235 = nvvm.elect.sync -> i1
    llvm.cond_br %235, ^bb44, ^bb45
  ^bb44:  // pred: ^bb43
    nvvm.cp.async.bulk.tensor.shared.cluster.global %230, %175, %231, box[%228, %113] l2_cache_hint = %232 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb45
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %236 = llvm.add %233, %37 : i32
    llvm.br ^bb42(%236 : i32)
  ^bb46:  // pred: ^bb42
    %237 = llvm.mul %211, %4 : i32
    %238 = llvm.getelementptr %69[%237] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    llvm.br ^bb47(%21 : i32)
  ^bb47(%239: i32):  // 2 preds: ^bb46, ^bb50
    %240 = llvm.icmp "slt" %239, %37 : i32
    llvm.cond_br %240, ^bb48, ^bb51(%225, %227, %223 : i32, i32, i32) {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb48:  // pred: ^bb47
    %241 = nvvm.elect.sync -> i1
    llvm.cond_br %241, ^bb49, ^bb50
  ^bb49:  // pred: ^bb48
    nvvm.cp.async.bulk.tensor.shared.cluster.global %238, %176, %231, box[%228, %114] l2_cache_hint = %232 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb50
  ^bb50:  // 2 preds: ^bb48, ^bb49
    %242 = llvm.add %239, %37 : i32
    llvm.br ^bb47(%242 : i32)
  ^bb51(%243: i32, %244: i32, %245: i32):  // 2 preds: ^bb34, ^bb47
    llvm.br ^bb52
  ^bb52:  // pred: ^bb51
    llvm.br ^bb53
  ^bb53:  // pred: ^bb52
    %246 = llvm.getelementptr %14[%213] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %246, %214, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %247 = llvm.add %213, %37 : i32
    %248 = llvm.icmp "eq" %247, %29 : i32
    %249 = llvm.select %248, %21, %247 : i1, i32
    llvm.cond_br %248, ^bb54, ^bb55
  ^bb54:  // pred: ^bb53
    %250 = llvm.xor %214, %37 : i32
    llvm.br ^bb56(%250 : i32)
  ^bb55:  // pred: ^bb53
    llvm.br ^bb56(%214 : i32)
  ^bb56(%251: i32):  // 2 preds: ^bb54, ^bb55
    llvm.br ^bb57
  ^bb57:  // pred: ^bb56
    %252 = llvm.mul %213, %3 : i32
    %253 = llvm.bitcast %159 : i64 to vector<2xi32>
    %254 = llvm.extractelement %253[%21 : i32] : vector<2xi32>
    %255 = llvm.add %254, %252 : i32
    %256 = llvm.insertelement %255, %253[%21 : i32] : vector<2xi32>
    %257 = llvm.bitcast %256 : vector<2xi32> to i64
    %258 = llvm.mul %213, %2 : i32
    %259 = llvm.bitcast %162 : i64 to vector<2xi32>
    %260 = llvm.extractelement %259[%21 : i32] : vector<2xi32>
    %261 = llvm.add %260, %258 : i32
    %262 = llvm.insertelement %261, %259[%21 : i32] : vector<2xi32>
    %263 = llvm.bitcast %262 : vector<2xi32> to i64
    %264 = llvm.extractvalue %215[1] : !llvm.struct<(i1, i1, i1)> 
    %265 = llvm.extractvalue %215[2] : !llvm.struct<(i1, i1, i1)> 
    %266 = llvm.extractvalue %215[0] : !llvm.struct<(i1, i1, i1)> 
    %267 = llvm.zext %264 : i1 to i32
    %268 = llvm.zext %265 : i1 to i32
    %269 = llvm.shl %267, %33 : i32
    %270 = llvm.shl %268, %34 : i32
    %271 = llvm.or %269, %32 : i32
    %272 = llvm.or %271, %270 : i32
    llvm.br ^bb58(%21 : i32)
  ^bb58(%273: i32):  // 2 preds: ^bb57, ^bb67
    %274 = llvm.icmp "slt" %273, %37 : i32
    llvm.cond_br %274, ^bb59, ^bb68 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb59:  // pred: ^bb58
    llvm.br ^bb60(%21 : i32)
  ^bb60(%275: i32):  // 2 preds: ^bb59, ^bb66
    %276 = llvm.icmp "slt" %275, %37 : i32
    llvm.cond_br %276, ^bb61, ^bb67 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb61:  // pred: ^bb60
    llvm.br ^bb62(%21 : i32)
  ^bb62(%277: i32):  // 2 preds: ^bb61, ^bb65
    %278 = llvm.icmp "slt" %277, %37 : i32
    llvm.cond_br %278, ^bb63, ^bb66 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb63:  // pred: ^bb62
    %279 = llvm.inttoptr %163 : i32 to !llvm.ptr<6>
    %280 = nvvm.elect.sync -> i1
    llvm.cond_br %280, ^bb64, ^bb65
  ^bb64:  // pred: ^bb63
    nvvm.tcgen05.mma %279, %257, %263, %272, %266 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb65
  ^bb65:  // 2 preds: ^bb63, ^bb64
    %281 = llvm.add %277, %37 : i32
    llvm.br ^bb62(%281 : i32)
  ^bb66:  // pred: ^bb62
    %282 = llvm.add %275, %37 : i32
    llvm.br ^bb60(%282 : i32)
  ^bb67:  // pred: ^bb60
    %283 = llvm.add %273, %37 : i32
    llvm.br ^bb58(%283 : i32)
  ^bb68:  // pred: ^bb58
    %284 = llvm.insertvalue %27, %215[0] : !llvm.struct<(i1, i1, i1)> 
    %285 = llvm.add %252, %30 : i32
    %286 = llvm.add %254, %285 : i32
    %287 = llvm.insertelement %286, %253[%21 : i32] : vector<2xi32>
    %288 = llvm.bitcast %287 : vector<2xi32> to i64
    %289 = llvm.add %258, %30 : i32
    %290 = llvm.add %260, %289 : i32
    %291 = llvm.insertelement %290, %259[%21 : i32] : vector<2xi32>
    %292 = llvm.bitcast %291 : vector<2xi32> to i64
    llvm.br ^bb69(%21 : i32)
  ^bb69(%293: i32):  // 2 preds: ^bb68, ^bb78
    %294 = llvm.icmp "slt" %293, %37 : i32
    llvm.cond_br %294, ^bb70, ^bb79 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb70:  // pred: ^bb69
    llvm.br ^bb71(%21 : i32)
  ^bb71(%295: i32):  // 2 preds: ^bb70, ^bb77
    %296 = llvm.icmp "slt" %295, %37 : i32
    llvm.cond_br %296, ^bb72, ^bb78 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb72:  // pred: ^bb71
    llvm.br ^bb73(%21 : i32)
  ^bb73(%297: i32):  // 2 preds: ^bb72, ^bb76
    %298 = llvm.icmp "slt" %297, %37 : i32
    llvm.cond_br %298, ^bb74, ^bb77 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb74:  // pred: ^bb73
    %299 = llvm.inttoptr %163 : i32 to !llvm.ptr<6>
    %300 = nvvm.elect.sync -> i1
    llvm.cond_br %300, ^bb75, ^bb76
  ^bb75:  // pred: ^bb74
    nvvm.tcgen05.mma %299, %288, %292, %272, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb76
  ^bb76:  // 2 preds: ^bb74, ^bb75
    %301 = llvm.add %297, %37 : i32
    llvm.br ^bb73(%301 : i32)
  ^bb77:  // pred: ^bb73
    %302 = llvm.add %295, %37 : i32
    llvm.br ^bb71(%302 : i32)
  ^bb78:  // pred: ^bb71
    %303 = llvm.add %293, %37 : i32
    llvm.br ^bb69(%303 : i32)
  ^bb79:  // pred: ^bb69
    %304 = llvm.insertvalue %27, %284[0] : !llvm.struct<(i1, i1, i1)> 
    %305 = llvm.add %252, %29 : i32
    %306 = llvm.add %254, %305 : i32
    %307 = llvm.insertelement %306, %253[%21 : i32] : vector<2xi32>
    %308 = llvm.bitcast %307 : vector<2xi32> to i64
    %309 = llvm.add %258, %29 : i32
    %310 = llvm.add %260, %309 : i32
    %311 = llvm.insertelement %310, %259[%21 : i32] : vector<2xi32>
    %312 = llvm.bitcast %311 : vector<2xi32> to i64
    llvm.br ^bb80(%21 : i32)
  ^bb80(%313: i32):  // 2 preds: ^bb79, ^bb89
    %314 = llvm.icmp "slt" %313, %37 : i32
    llvm.cond_br %314, ^bb81, ^bb90 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb81:  // pred: ^bb80
    llvm.br ^bb82(%21 : i32)
  ^bb82(%315: i32):  // 2 preds: ^bb81, ^bb88
    %316 = llvm.icmp "slt" %315, %37 : i32
    llvm.cond_br %316, ^bb83, ^bb89 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb83:  // pred: ^bb82
    llvm.br ^bb84(%21 : i32)
  ^bb84(%317: i32):  // 2 preds: ^bb83, ^bb87
    %318 = llvm.icmp "slt" %317, %37 : i32
    llvm.cond_br %318, ^bb85, ^bb88 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb85:  // pred: ^bb84
    %319 = llvm.inttoptr %163 : i32 to !llvm.ptr<6>
    %320 = nvvm.elect.sync -> i1
    llvm.cond_br %320, ^bb86, ^bb87
  ^bb86:  // pred: ^bb85
    nvvm.tcgen05.mma %319, %308, %312, %272, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb87
  ^bb87:  // 2 preds: ^bb85, ^bb86
    %321 = llvm.add %317, %37 : i32
    llvm.br ^bb84(%321 : i32)
  ^bb88:  // pred: ^bb84
    %322 = llvm.add %315, %37 : i32
    llvm.br ^bb82(%322 : i32)
  ^bb89:  // pred: ^bb82
    %323 = llvm.add %313, %37 : i32
    llvm.br ^bb80(%323 : i32)
  ^bb90:  // pred: ^bb80
    %324 = llvm.insertvalue %27, %304[0] : !llvm.struct<(i1, i1, i1)> 
    %325 = llvm.add %252, %13 : i32
    %326 = llvm.add %254, %325 : i32
    %327 = llvm.insertelement %326, %253[%21 : i32] : vector<2xi32>
    %328 = llvm.bitcast %327 : vector<2xi32> to i64
    %329 = llvm.add %258, %13 : i32
    %330 = llvm.add %260, %329 : i32
    %331 = llvm.insertelement %330, %259[%21 : i32] : vector<2xi32>
    %332 = llvm.bitcast %331 : vector<2xi32> to i64
    llvm.br ^bb91(%21 : i32)
  ^bb91(%333: i32):  // 2 preds: ^bb90, ^bb100
    %334 = llvm.icmp "slt" %333, %37 : i32
    llvm.cond_br %334, ^bb92, ^bb101 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb92:  // pred: ^bb91
    llvm.br ^bb93(%21 : i32)
  ^bb93(%335: i32):  // 2 preds: ^bb92, ^bb99
    %336 = llvm.icmp "slt" %335, %37 : i32
    llvm.cond_br %336, ^bb94, ^bb100 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb94:  // pred: ^bb93
    llvm.br ^bb95(%21 : i32)
  ^bb95(%337: i32):  // 2 preds: ^bb94, ^bb98
    %338 = llvm.icmp "slt" %337, %37 : i32
    llvm.cond_br %338, ^bb96, ^bb99 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb96:  // pred: ^bb95
    %339 = llvm.inttoptr %163 : i32 to !llvm.ptr<6>
    %340 = nvvm.elect.sync -> i1
    llvm.cond_br %340, ^bb97, ^bb98
  ^bb97:  // pred: ^bb96
    nvvm.tcgen05.mma %339, %328, %332, %272, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb98
  ^bb98:  // 2 preds: ^bb96, ^bb97
    %341 = llvm.add %337, %37 : i32
    llvm.br ^bb95(%341 : i32)
  ^bb99:  // pred: ^bb95
    %342 = llvm.add %335, %37 : i32
    llvm.br ^bb93(%342 : i32)
  ^bb100:  // pred: ^bb93
    %343 = llvm.add %333, %37 : i32
    llvm.br ^bb91(%343 : i32)
  ^bb101:  // pred: ^bb91
    %344 = llvm.insertvalue %27, %324[0] : !llvm.struct<(i1, i1, i1)> 
    %345 = nvvm.elect.sync -> i1
    llvm.cond_br %345, ^bb102, ^bb103
  ^bb102:  // pred: ^bb101
    %346 = llvm.getelementptr %74[%213] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.tcgen05.commit.arrive %346 : !llvm.ptr<3>
    llvm.br ^bb103
  ^bb103:  // 2 preds: ^bb101, ^bb102
    %347 = llvm.add %209, %37 : i32
    llvm.br ^bb33(%347, %245, %243, %244, %249, %251, %344 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
  ^bb104:  // pred: ^bb33
    %348 = nvvm.elect.sync -> i1
    llvm.cond_br %348, ^bb105, ^bb106
  ^bb105:  // pred: ^bb104
    nvvm.tcgen05.commit.arrive %62 : !llvm.ptr<3>
    llvm.br ^bb106
  ^bb106:  // 2 preds: ^bb104, ^bb105
    llvm.br ^bb107
  ^bb107:  // 2 preds: ^bb12, ^bb106
    llvm.cond_br %70, ^bb108, ^bb109
  ^bb108:  // pred: ^bb107
    nvvm.tcgen05.relinquish_alloc_permit
    llvm.br ^bb109
  ^bb109:  // 2 preds: ^bb107, ^bb108
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %62, %21, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    llvm.br ^bb110(%21 : i32)
  ^bb110(%349: i32):  // 2 preds: ^bb109, ^bb117
    %350 = llvm.icmp "slt" %349, %29 : i32
    llvm.cond_br %350, ^bb111, ^bb118
  ^bb111:  // pred: ^bb110
    %351 = llvm.srem %349, %29 : i32
    %352 = llvm.mul %351, %36 : i32
    %353 = llvm.add %166, %352 : i32
    llvm.br ^bb112(%21 : i32)
  ^bb112(%354: i32):  // 2 preds: ^bb111, ^bb113
    %355 = llvm.icmp "slt" %354, %37 : i32
    llvm.cond_br %355, ^bb113, ^bb114 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb113:  // pred: ^bb112
    %356 = llvm.inttoptr %353 : i32 to !llvm.ptr<6>
    %357 = nvvm.tcgen05.ld %356 {num = 64 : i32, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>} : vector<64xi32>
    llvm.store %357, %39 : vector<64xi32>, !llvm.ptr
    %358 = llvm.add %354, %37 : i32
    llvm.br ^bb112(%358 : i32)
  ^bb114:  // pred: ^bb112
    %359 = llvm.load %39 {alignment = 32 : i64} : !llvm.ptr -> vector<64xf32>
    %360 = llvm.fptrunc %359 : vector<64xf32> to vector<64xf16>
    llvm.store %360, %38 {alignment = 32 : i64} : vector<64xf16>, !llvm.ptr
    %361 = llvm.getelementptr %174[%352] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
    llvm.br ^bb115(%21 : i32)
  ^bb115(%362: i32):  // 2 preds: ^bb114, ^bb116
    %363 = llvm.icmp "slt" %362, %29 : i32
    llvm.cond_br %363, ^bb116, ^bb117 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb116:  // pred: ^bb115
    %364 = llvm.mul %362, %0 : i32
    %365 = llvm.getelementptr %38[%364] : (!llvm.ptr, i32) -> !llvm.ptr, f16
    %366 = llvm.getelementptr %361[%364] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
    %367 = llvm.load %365 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
    llvm.store %367, %366 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
    %368 = llvm.add %362, %37 : i32
    llvm.br ^bb115(%368 : i32)
  ^bb117:  // pred: ^bb115
    %369 = llvm.add %349, %37 : i32
    llvm.br ^bb110(%369 : i32)
  ^bb118:  // pred: ^bb110
    nvvm.mbarrier.txn %79, %37 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
    nvvm.barrier id = %37
    llvm.cond_br %70, ^bb119, ^bb120
  ^bb119:  // pred: ^bb118
    %370 = llvm.inttoptr %163 : i32 to !llvm.ptr<6>
    nvvm.tcgen05.dealloc %370, %22 : !llvm.ptr<6>, i32
    llvm.br ^bb120
  ^bb120:  // 2 preds: ^bb118, ^bb119
    llvm.return
  }
}
