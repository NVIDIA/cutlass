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
    llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %21 : (i32) -> ()
    nvvm.barrier
    llvm.cond_br %70, ^bb9, ^bb10
  ^bb9:  // pred: ^bb8
    nvvm.mbarrier.init.shared %62, %37 : !llvm.ptr<3>, i32
    llvm.br ^bb10
  ^bb10:  // 2 preds: ^bb8, ^bb9
    %78 = llvm.getelementptr %62[1] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i64
    llvm.cond_br %70, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    nvvm.mbarrier.init.shared %78, %19 : !llvm.ptr<3>, i32
    llvm.br ^bb12
  ^bb12:  // 2 preds: ^bb10, ^bb11
    llvm.inline_asm has_side_effects asm_dialect = att "fence.mbarrier_init.release.cluster;", "n" %21 : (i32) -> ()
    nvvm.barrier
    %79 = llvm.extractvalue %arg2[1] : !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)> 
    %80 = llvm.extractvalue %79[0, 0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %81 = llvm.extractvalue %79[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %82 = llvm.select %27, %16, %37 : i1, i32
    %83 = llvm.add %82, %80 : i32
    %84 = llvm.sdiv %83, %19 : i32
    %85 = llvm.add %84, %37 : i32
    %86 = llvm.sub %21, %80 : i32
    %87 = llvm.sdiv %86, %19 : i32
    %88 = llvm.sub %21, %87 : i32
    %89 = llvm.icmp "slt" %80, %21 : i32
    %90 = llvm.icmp "sgt" %80, %21 : i32
    %91 = llvm.and %89, %17 : i1
    %92 = llvm.and %90, %27 : i1
    %93 = llvm.or %91, %92 : i1
    %94 = llvm.select %93, %85, %88 : i1, i32
    %95 = llvm.add %82, %81 : i32
    %96 = llvm.sdiv %95, %36 : i32
    %97 = llvm.add %96, %37 : i32
    %98 = llvm.sub %21, %81 : i32
    %99 = llvm.sdiv %98, %36 : i32
    %100 = llvm.sub %21, %99 : i32
    %101 = llvm.icmp "slt" %81, %21 : i32
    %102 = llvm.icmp "sgt" %81, %21 : i32
    %103 = llvm.and %101, %17 : i1
    %104 = llvm.and %102, %27 : i1
    %105 = llvm.or %103, %104 : i1
    %106 = llvm.select %105, %97, %100 : i1, i32
    %107 = llvm.insertvalue %94, %12[0] : !llvm.struct<(i32, i32)> 
    %108 = llvm.insertvalue %106, %107[1] : !llvm.struct<(i32, i32)> 
    %109 = llvm.insertvalue %108, %11[0] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %110 = llvm.extractvalue %109[0, 1] : !llvm.struct<(struct<(i32, i32)>, struct<()>)> 
    %111 = llvm.mul %59, %19 : i32
    %112 = llvm.mul %60, %23 : i32
    %113 = llvm.extractvalue %arg5[1] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %114 = llvm.extractvalue %113[0, 0] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %115 = llvm.extractvalue %113[0, 1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %116 = llvm.extractvalue %113[1] : !llvm.struct<(struct<(i32, i32)>, i64)> 
    %117 = llvm.add %82, %114 : i32
    %118 = llvm.sdiv %117, %19 : i32
    %119 = llvm.add %118, %37 : i32
    %120 = llvm.sub %21, %114 : i32
    %121 = llvm.sdiv %120, %19 : i32
    %122 = llvm.sub %21, %121 : i32
    %123 = llvm.icmp "slt" %114, %21 : i32
    %124 = llvm.icmp "sgt" %114, %21 : i32
    %125 = llvm.and %123, %17 : i1
    %126 = llvm.and %124, %27 : i1
    %127 = llvm.or %125, %126 : i1
    %128 = llvm.select %127, %119, %122 : i1, i32
    %129 = llvm.mul %116, %24 : i64
    %130 = llvm.add %82, %115 : i32
    %131 = llvm.sdiv %130, %23 : i32
    %132 = llvm.add %131, %37 : i32
    %133 = llvm.sub %21, %115 : i32
    %134 = llvm.sdiv %133, %23 : i32
    %135 = llvm.sub %21, %134 : i32
    %136 = llvm.icmp "slt" %115, %21 : i32
    %137 = llvm.icmp "sgt" %115, %21 : i32
    %138 = llvm.and %136, %17 : i1
    %139 = llvm.and %137, %27 : i1
    %140 = llvm.or %138, %139 : i1
    %141 = llvm.select %140, %132, %135 : i1, i32
    %142 = llvm.insertvalue %128, %12[0] : !llvm.struct<(i32, i32)> 
    %143 = llvm.insertvalue %141, %142[1] : !llvm.struct<(i32, i32)> 
    %144 = llvm.insertvalue %116, %10[0] : !llvm.struct<(i64, i64)> 
    %145 = llvm.insertvalue %129, %144[1] : !llvm.struct<(i64, i64)> 
    %146 = llvm.insertvalue %143, %9[0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %147 = llvm.insertvalue %145, %146[1] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %148 = llvm.extractvalue %147[1, 0] : !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)> 
    %149 = llvm.sext %59 : i32 to i64
    %150 = llvm.mul %149, %129 : i64
    %151 = llvm.sext %112 : i32 to i64
    %152 = llvm.add %150, %151 : i64
    %153 = llvm.extractvalue %arg5[0] : !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)> 
    %154 = llvm.getelementptr %153[%152] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
    %155 = llvm.ptrtoint %68 : !llvm.ptr<3> to i32
    %156 = llvm.lshr %155, %29 : i32
    %157 = nvvm.mma_smem_desc(%156, %37, %36, %7, %8) : (i32, i32, i32, i8, i8) -> i64
    %158 = llvm.ptrtoint %69 : !llvm.ptr<3> to i32
    %159 = llvm.lshr %158, %29 : i32
    %160 = nvvm.mma_smem_desc(%159, %37, %36, %7, %8) : (i32, i32, i32, i8, i8) -> i64
    nvvm.barrier id = %37 number_of_threads = %19
    %161 = llvm.load %63 : !llvm.ptr<3> -> i32
    %162 = llvm.sdiv %40, %18 : i32
    %163 = llvm.mul %162, %25 : i32
    %164 = llvm.add %161, %163 : i32
    %165 = llvm.mul %148, %26 : i64
    %166 = llvm.srem %40, %18 : i32
    %167 = llvm.sext %166 : i32 to i64
    %168 = llvm.mul %167, %148 : i64
    %169 = llvm.sext %162 : i32 to i64
    %170 = llvm.mul %169, %165 : i64
    %171 = llvm.add %168, %170 : i64
    %172 = llvm.getelementptr %154[%171] : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>, f16
    llvm.cond_br %70, ^bb13, ^bb107
  ^bb13:  // pred: ^bb12
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,n,n" %78, %37, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %173 = llvm.getelementptr %arg1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
    %174 = llvm.getelementptr %arg3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(struct<(array<16 x i64>)>)>
    %175 = llvm.icmp "slt" %110, %30 : i32
    %176 = llvm.select %175, %110, %30 : i1, i32
    llvm.br ^bb14(%21, %21, %37, %21 : i32, i32, i32, i32)
  ^bb14(%177: i32, %178: i32, %179: i32, %180: i32):  // 2 preds: ^bb13, ^bb31
    %181 = llvm.icmp "slt" %177, %176 : i32
    llvm.cond_br %181, ^bb15, ^bb32
  ^bb15:  // pred: ^bb14
    %182 = llvm.getelementptr %74[%178] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %182, %179, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %183 = nvvm.elect.sync -> i1
    llvm.cond_br %183, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %184 = llvm.getelementptr %14[%178] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.txn %184, %31 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    %185 = llvm.add %178, %37 : i32
    %186 = llvm.add %180, %37 : i32
    %187 = llvm.icmp "eq" %185, %29 : i32
    %188 = llvm.select %187, %21, %185 : i1, i32
    llvm.cond_br %187, ^bb18, ^bb19
  ^bb18:  // pred: ^bb17
    %189 = llvm.xor %179, %37 : i32
    llvm.br ^bb20(%189 : i32)
  ^bb19:  // pred: ^bb17
    llvm.br ^bb20(%179 : i32)
  ^bb20(%190: i32):  // 2 preds: ^bb18, ^bb19
    llvm.br ^bb21
  ^bb21:  // pred: ^bb20
    %191 = llvm.mul %180, %36 : i32
    %192 = llvm.mul %178, %5 : i32
    %193 = llvm.getelementptr %68[%192] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    %194 = llvm.getelementptr %14[%178] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    %195 = llvm.extractvalue %6[3] : !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)> 
    llvm.br ^bb22(%21 : i32)
  ^bb22(%196: i32):  // 2 preds: ^bb21, ^bb25
    %197 = llvm.icmp "slt" %196, %37 : i32
    llvm.cond_br %197, ^bb23, ^bb26 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb23:  // pred: ^bb22
    %198 = nvvm.elect.sync -> i1
    llvm.cond_br %198, ^bb24, ^bb25
  ^bb24:  // pred: ^bb23
    nvvm.cp.async.bulk.tensor.shared.cluster.global %193, %173, %194, box[%191, %111] l2_cache_hint = %195 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb25
  ^bb25:  // 2 preds: ^bb23, ^bb24
    %199 = llvm.add %196, %37 : i32
    llvm.br ^bb22(%199 : i32)
  ^bb26:  // pred: ^bb22
    %200 = llvm.mul %178, %4 : i32
    %201 = llvm.getelementptr %69[%200] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    llvm.br ^bb27(%21 : i32)
  ^bb27(%202: i32):  // 2 preds: ^bb26, ^bb30
    %203 = llvm.icmp "slt" %202, %37 : i32
    llvm.cond_br %203, ^bb28, ^bb31 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb28:  // pred: ^bb27
    %204 = nvvm.elect.sync -> i1
    llvm.cond_br %204, ^bb29, ^bb30
  ^bb29:  // pred: ^bb28
    nvvm.cp.async.bulk.tensor.shared.cluster.global %201, %174, %194, box[%191, %112] l2_cache_hint = %195 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb30
  ^bb30:  // 2 preds: ^bb28, ^bb29
    %205 = llvm.add %202, %37 : i32
    llvm.br ^bb27(%205 : i32)
  ^bb31:  // pred: ^bb27
    %206 = llvm.add %177, %37 : i32
    llvm.br ^bb14(%206, %188, %190, %186 : i32, i32, i32, i32)
  ^bb32:  // pred: ^bb14
    llvm.br ^bb33(%21, %180, %178, %179, %21, %21, %arg0 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
  ^bb33(%207: i32, %208: i32, %209: i32, %210: i32, %211: i32, %212: i32, %213: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb32, ^bb103
    %214 = llvm.icmp "slt" %207, %110 : i32
    llvm.cond_br %214, ^bb34, ^bb104
  ^bb34:  // pred: ^bb33
    %215 = llvm.add %207, %176 : i32
    %216 = llvm.icmp "ult" %215, %110 : i32
    llvm.cond_br %216, ^bb35, ^bb51(%209, %210, %208 : i32, i32, i32)
  ^bb35:  // pred: ^bb34
    %217 = llvm.getelementptr %74[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %217, %210, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %218 = nvvm.elect.sync -> i1
    llvm.cond_br %218, ^bb36, ^bb37
  ^bb36:  // pred: ^bb35
    %219 = llvm.getelementptr %14[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.mbarrier.txn %219, %31 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
    llvm.br ^bb37
  ^bb37:  // 2 preds: ^bb35, ^bb36
    %220 = llvm.add %209, %37 : i32
    %221 = llvm.add %208, %37 : i32
    %222 = llvm.icmp "eq" %220, %29 : i32
    %223 = llvm.select %222, %21, %220 : i1, i32
    llvm.cond_br %222, ^bb38, ^bb39
  ^bb38:  // pred: ^bb37
    %224 = llvm.xor %210, %37 : i32
    llvm.br ^bb40(%224 : i32)
  ^bb39:  // pred: ^bb37
    llvm.br ^bb40(%210 : i32)
  ^bb40(%225: i32):  // 2 preds: ^bb38, ^bb39
    llvm.br ^bb41
  ^bb41:  // pred: ^bb40
    %226 = llvm.mul %208, %36 : i32
    %227 = llvm.mul %209, %5 : i32
    %228 = llvm.getelementptr %68[%227] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    %229 = llvm.getelementptr %14[%209] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    %230 = llvm.extractvalue %6[3] : !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)> 
    llvm.br ^bb42(%21 : i32)
  ^bb42(%231: i32):  // 2 preds: ^bb41, ^bb45
    %232 = llvm.icmp "slt" %231, %37 : i32
    llvm.cond_br %232, ^bb43, ^bb46 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb43:  // pred: ^bb42
    %233 = nvvm.elect.sync -> i1
    llvm.cond_br %233, ^bb44, ^bb45
  ^bb44:  // pred: ^bb43
    nvvm.cp.async.bulk.tensor.shared.cluster.global %228, %173, %229, box[%226, %111] l2_cache_hint = %230 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb45
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %234 = llvm.add %231, %37 : i32
    llvm.br ^bb42(%234 : i32)
  ^bb46:  // pred: ^bb42
    %235 = llvm.mul %209, %4 : i32
    %236 = llvm.getelementptr %69[%235] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f16
    llvm.br ^bb47(%21 : i32)
  ^bb47(%237: i32):  // 2 preds: ^bb46, ^bb50
    %238 = llvm.icmp "slt" %237, %37 : i32
    llvm.cond_br %238, ^bb48, ^bb51(%223, %225, %221 : i32, i32, i32) {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb48:  // pred: ^bb47
    %239 = nvvm.elect.sync -> i1
    llvm.cond_br %239, ^bb49, ^bb50
  ^bb49:  // pred: ^bb48
    nvvm.cp.async.bulk.tensor.shared.cluster.global %236, %174, %229, box[%226, %112] l2_cache_hint = %230 {useIntrinsic = true} : <3>, !llvm.ptr
    llvm.br ^bb50
  ^bb50:  // 2 preds: ^bb48, ^bb49
    %240 = llvm.add %237, %37 : i32
    llvm.br ^bb47(%240 : i32)
  ^bb51(%241: i32, %242: i32, %243: i32):  // 2 preds: ^bb34, ^bb47
    llvm.br ^bb52
  ^bb52:  // pred: ^bb51
    llvm.br ^bb53
  ^bb53:  // pred: ^bb52
    %244 = llvm.getelementptr %14[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", "r,r,n" %244, %212, %28 : (!llvm.ptr<3>, i32, i32) -> ()
    %245 = llvm.add %211, %37 : i32
    %246 = llvm.icmp "eq" %245, %29 : i32
    %247 = llvm.select %246, %21, %245 : i1, i32
    llvm.cond_br %246, ^bb54, ^bb55
  ^bb54:  // pred: ^bb53
    %248 = llvm.xor %212, %37 : i32
    llvm.br ^bb56(%248 : i32)
  ^bb55:  // pred: ^bb53
    llvm.br ^bb56(%212 : i32)
  ^bb56(%249: i32):  // 2 preds: ^bb54, ^bb55
    llvm.br ^bb57
  ^bb57:  // pred: ^bb56
    %250 = llvm.mul %211, %3 : i32
    %251 = llvm.bitcast %157 : i64 to vector<2xi32>
    %252 = llvm.extractelement %251[%21 : i32] : vector<2xi32>
    %253 = llvm.add %252, %250 : i32
    %254 = llvm.insertelement %253, %251[%21 : i32] : vector<2xi32>
    %255 = llvm.bitcast %254 : vector<2xi32> to i64
    %256 = llvm.mul %211, %2 : i32
    %257 = llvm.bitcast %160 : i64 to vector<2xi32>
    %258 = llvm.extractelement %257[%21 : i32] : vector<2xi32>
    %259 = llvm.add %258, %256 : i32
    %260 = llvm.insertelement %259, %257[%21 : i32] : vector<2xi32>
    %261 = llvm.bitcast %260 : vector<2xi32> to i64
    %262 = llvm.extractvalue %213[1] : !llvm.struct<(i1, i1, i1)> 
    %263 = llvm.extractvalue %213[2] : !llvm.struct<(i1, i1, i1)> 
    %264 = llvm.extractvalue %213[0] : !llvm.struct<(i1, i1, i1)> 
    %265 = llvm.zext %262 : i1 to i32
    %266 = llvm.zext %263 : i1 to i32
    %267 = llvm.shl %265, %33 : i32
    %268 = llvm.shl %266, %34 : i32
    %269 = llvm.or %267, %32 : i32
    %270 = llvm.or %269, %268 : i32
    llvm.br ^bb58(%21 : i32)
  ^bb58(%271: i32):  // 2 preds: ^bb57, ^bb67
    %272 = llvm.icmp "slt" %271, %37 : i32
    llvm.cond_br %272, ^bb59, ^bb68 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb59:  // pred: ^bb58
    llvm.br ^bb60(%21 : i32)
  ^bb60(%273: i32):  // 2 preds: ^bb59, ^bb66
    %274 = llvm.icmp "slt" %273, %37 : i32
    llvm.cond_br %274, ^bb61, ^bb67 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb61:  // pred: ^bb60
    llvm.br ^bb62(%21 : i32)
  ^bb62(%275: i32):  // 2 preds: ^bb61, ^bb65
    %276 = llvm.icmp "slt" %275, %37 : i32
    llvm.cond_br %276, ^bb63, ^bb66 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb63:  // pred: ^bb62
    %277 = llvm.inttoptr %161 : i32 to !llvm.ptr<6>
    %278 = nvvm.elect.sync -> i1
    llvm.cond_br %278, ^bb64, ^bb65
  ^bb64:  // pred: ^bb63
    nvvm.tcgen05.mma %277, %255, %261, %270, %264 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb65
  ^bb65:  // 2 preds: ^bb63, ^bb64
    %279 = llvm.add %275, %37 : i32
    llvm.br ^bb62(%279 : i32)
  ^bb66:  // pred: ^bb62
    %280 = llvm.add %273, %37 : i32
    llvm.br ^bb60(%280 : i32)
  ^bb67:  // pred: ^bb60
    %281 = llvm.add %271, %37 : i32
    llvm.br ^bb58(%281 : i32)
  ^bb68:  // pred: ^bb58
    %282 = llvm.insertvalue %27, %213[0] : !llvm.struct<(i1, i1, i1)> 
    %283 = llvm.add %250, %30 : i32
    %284 = llvm.add %252, %283 : i32
    %285 = llvm.insertelement %284, %251[%21 : i32] : vector<2xi32>
    %286 = llvm.bitcast %285 : vector<2xi32> to i64
    %287 = llvm.add %256, %30 : i32
    %288 = llvm.add %258, %287 : i32
    %289 = llvm.insertelement %288, %257[%21 : i32] : vector<2xi32>
    %290 = llvm.bitcast %289 : vector<2xi32> to i64
    llvm.br ^bb69(%21 : i32)
  ^bb69(%291: i32):  // 2 preds: ^bb68, ^bb78
    %292 = llvm.icmp "slt" %291, %37 : i32
    llvm.cond_br %292, ^bb70, ^bb79 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb70:  // pred: ^bb69
    llvm.br ^bb71(%21 : i32)
  ^bb71(%293: i32):  // 2 preds: ^bb70, ^bb77
    %294 = llvm.icmp "slt" %293, %37 : i32
    llvm.cond_br %294, ^bb72, ^bb78 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb72:  // pred: ^bb71
    llvm.br ^bb73(%21 : i32)
  ^bb73(%295: i32):  // 2 preds: ^bb72, ^bb76
    %296 = llvm.icmp "slt" %295, %37 : i32
    llvm.cond_br %296, ^bb74, ^bb77 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb74:  // pred: ^bb73
    %297 = llvm.inttoptr %161 : i32 to !llvm.ptr<6>
    %298 = nvvm.elect.sync -> i1
    llvm.cond_br %298, ^bb75, ^bb76
  ^bb75:  // pred: ^bb74
    nvvm.tcgen05.mma %297, %286, %290, %270, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb76
  ^bb76:  // 2 preds: ^bb74, ^bb75
    %299 = llvm.add %295, %37 : i32
    llvm.br ^bb73(%299 : i32)
  ^bb77:  // pred: ^bb73
    %300 = llvm.add %293, %37 : i32
    llvm.br ^bb71(%300 : i32)
  ^bb78:  // pred: ^bb71
    %301 = llvm.add %291, %37 : i32
    llvm.br ^bb69(%301 : i32)
  ^bb79:  // pred: ^bb69
    %302 = llvm.insertvalue %27, %282[0] : !llvm.struct<(i1, i1, i1)> 
    %303 = llvm.add %250, %29 : i32
    %304 = llvm.add %252, %303 : i32
    %305 = llvm.insertelement %304, %251[%21 : i32] : vector<2xi32>
    %306 = llvm.bitcast %305 : vector<2xi32> to i64
    %307 = llvm.add %256, %29 : i32
    %308 = llvm.add %258, %307 : i32
    %309 = llvm.insertelement %308, %257[%21 : i32] : vector<2xi32>
    %310 = llvm.bitcast %309 : vector<2xi32> to i64
    llvm.br ^bb80(%21 : i32)
  ^bb80(%311: i32):  // 2 preds: ^bb79, ^bb89
    %312 = llvm.icmp "slt" %311, %37 : i32
    llvm.cond_br %312, ^bb81, ^bb90 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb81:  // pred: ^bb80
    llvm.br ^bb82(%21 : i32)
  ^bb82(%313: i32):  // 2 preds: ^bb81, ^bb88
    %314 = llvm.icmp "slt" %313, %37 : i32
    llvm.cond_br %314, ^bb83, ^bb89 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb83:  // pred: ^bb82
    llvm.br ^bb84(%21 : i32)
  ^bb84(%315: i32):  // 2 preds: ^bb83, ^bb87
    %316 = llvm.icmp "slt" %315, %37 : i32
    llvm.cond_br %316, ^bb85, ^bb88 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb85:  // pred: ^bb84
    %317 = llvm.inttoptr %161 : i32 to !llvm.ptr<6>
    %318 = nvvm.elect.sync -> i1
    llvm.cond_br %318, ^bb86, ^bb87
  ^bb86:  // pred: ^bb85
    nvvm.tcgen05.mma %317, %306, %310, %270, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb87
  ^bb87:  // 2 preds: ^bb85, ^bb86
    %319 = llvm.add %315, %37 : i32
    llvm.br ^bb84(%319 : i32)
  ^bb88:  // pred: ^bb84
    %320 = llvm.add %313, %37 : i32
    llvm.br ^bb82(%320 : i32)
  ^bb89:  // pred: ^bb82
    %321 = llvm.add %311, %37 : i32
    llvm.br ^bb80(%321 : i32)
  ^bb90:  // pred: ^bb80
    %322 = llvm.insertvalue %27, %302[0] : !llvm.struct<(i1, i1, i1)> 
    %323 = llvm.add %250, %13 : i32
    %324 = llvm.add %252, %323 : i32
    %325 = llvm.insertelement %324, %251[%21 : i32] : vector<2xi32>
    %326 = llvm.bitcast %325 : vector<2xi32> to i64
    %327 = llvm.add %256, %13 : i32
    %328 = llvm.add %258, %327 : i32
    %329 = llvm.insertelement %328, %257[%21 : i32] : vector<2xi32>
    %330 = llvm.bitcast %329 : vector<2xi32> to i64
    llvm.br ^bb91(%21 : i32)
  ^bb91(%331: i32):  // 2 preds: ^bb90, ^bb100
    %332 = llvm.icmp "slt" %331, %37 : i32
    llvm.cond_br %332, ^bb92, ^bb101 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb92:  // pred: ^bb91
    llvm.br ^bb93(%21 : i32)
  ^bb93(%333: i32):  // 2 preds: ^bb92, ^bb99
    %334 = llvm.icmp "slt" %333, %37 : i32
    llvm.cond_br %334, ^bb94, ^bb100 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb94:  // pred: ^bb93
    llvm.br ^bb95(%21 : i32)
  ^bb95(%335: i32):  // 2 preds: ^bb94, ^bb98
    %336 = llvm.icmp "slt" %335, %37 : i32
    llvm.cond_br %336, ^bb96, ^bb99 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb96:  // pred: ^bb95
    %337 = llvm.inttoptr %161 : i32 to !llvm.ptr<6>
    %338 = nvvm.elect.sync -> i1
    llvm.cond_br %338, ^bb97, ^bb98
  ^bb97:  // pred: ^bb96
    nvvm.tcgen05.mma %337, %326, %330, %270, %27 mask = %1 {ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>} : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>)
    llvm.br ^bb98
  ^bb98:  // 2 preds: ^bb96, ^bb97
    %339 = llvm.add %335, %37 : i32
    llvm.br ^bb95(%339 : i32)
  ^bb99:  // pred: ^bb95
    %340 = llvm.add %333, %37 : i32
    llvm.br ^bb93(%340 : i32)
  ^bb100:  // pred: ^bb93
    %341 = llvm.add %331, %37 : i32
    llvm.br ^bb91(%341 : i32)
  ^bb101:  // pred: ^bb91
    %342 = llvm.insertvalue %27, %322[0] : !llvm.struct<(i1, i1, i1)> 
    %343 = nvvm.elect.sync -> i1
    llvm.cond_br %343, ^bb102, ^bb103
  ^bb102:  // pred: ^bb101
    %344 = llvm.getelementptr %74[%211] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, i64
    nvvm.tcgen05.commit.arrive %344 : !llvm.ptr<3>
    llvm.br ^bb103
  ^bb103:  // 2 preds: ^bb101, ^bb102
    %345 = llvm.add %207, %37 : i32
    llvm.br ^bb33(%345, %243, %241, %242, %247, %249, %342 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
  ^bb104:  // pred: ^bb33
    %346 = nvvm.elect.sync -> i1
    llvm.cond_br %346, ^bb105, ^bb106
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
  ^bb110(%347: i32):  // 2 preds: ^bb109, ^bb117
    %348 = llvm.icmp "slt" %347, %29 : i32
    llvm.cond_br %348, ^bb111, ^bb118
  ^bb111:  // pred: ^bb110
    %349 = llvm.srem %347, %29 : i32
    %350 = llvm.mul %349, %36 : i32
    %351 = llvm.add %164, %350 : i32
    llvm.br ^bb112(%21 : i32)
  ^bb112(%352: i32):  // 2 preds: ^bb111, ^bb113
    %353 = llvm.icmp "slt" %352, %37 : i32
    llvm.cond_br %353, ^bb113, ^bb114 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb113:  // pred: ^bb112
    %354 = llvm.inttoptr %351 : i32 to !llvm.ptr<6>
    %355 = nvvm.tcgen05.ld %354 {num = 64 : i32, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>} : vector<64xi32>
    llvm.store %355, %39 : vector<64xi32>, !llvm.ptr
    %356 = llvm.add %352, %37 : i32
    llvm.br ^bb112(%356 : i32)
  ^bb114:  // pred: ^bb112
    %357 = llvm.load %39 {alignment = 32 : i64} : !llvm.ptr -> vector<64xf32>
    %358 = llvm.fptrunc %357 : vector<64xf32> to vector<64xf16>
    llvm.store %358, %38 {alignment = 32 : i64} : vector<64xf16>, !llvm.ptr
    %359 = llvm.getelementptr %172[%350] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
    llvm.br ^bb115(%21 : i32)
  ^bb115(%360: i32):  // 2 preds: ^bb114, ^bb116
    %361 = llvm.icmp "slt" %360, %29 : i32
    llvm.cond_br %361, ^bb116, ^bb117 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb116:  // pred: ^bb115
    %362 = llvm.mul %360, %0 : i32
    %363 = llvm.getelementptr %38[%362] : (!llvm.ptr, i32) -> !llvm.ptr, f16
    %364 = llvm.getelementptr %359[%362] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, f16
    %365 = llvm.load %363 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
    llvm.store %365, %364 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
    %366 = llvm.add %360, %37 : i32
    llvm.br ^bb115(%366 : i32)
  ^bb117:  // pred: ^bb115
    %367 = llvm.add %347, %37 : i32
    llvm.br ^bb110(%367 : i32)
  ^bb118:  // pred: ^bb110
    nvvm.mbarrier.txn %78, %37 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
    nvvm.barrier id = %37
    llvm.cond_br %70, ^bb119, ^bb120
  ^bb119:  // pred: ^bb118
    %368 = llvm.inttoptr %161 : i32 to !llvm.ptr<6>
    nvvm.tcgen05.dealloc %368, %22 : !llvm.ptr<6>, i32
    llvm.br ^bb120
  ^bb120:  // 2 preds: ^bb118, ^bb119
    llvm.return
  }
}
