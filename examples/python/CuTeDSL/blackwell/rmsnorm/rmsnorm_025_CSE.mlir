#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.mlir.global external @__dynamic_shmem__0() {addr_space = 3 : i32, alignment = 1024 : i64, dso_local} : !llvm.array<0 x i8>
    llvm.func @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = llvm.mlir.constant(3584 : i32) : i32
      %1 = llvm.mlir.constant(3072 : i32) : i32
      %2 = llvm.mlir.constant(2560 : i32) : i32
      %3 = llvm.mlir.constant(2048 : i32) : i32
      %4 = llvm.mlir.constant(1536 : i32) : i32
      %5 = llvm.mlir.constant(1024 : i32) : i32
      %6 = llvm.mlir.constant(512 : i32) : i32
      %7 = llvm.mlir.constant(8192 : i32) : i32
      %8 = llvm.mlir.constant(false) : i1
      %9 = llvm.mlir.addressof @__dynamic_shmem__0 : !llvm.ptr<3>
      %10 = llvm.mlir.constant(2 : i32) : i32
      %11 = llvm.mlir.constant(4096 : i32) : i32
      %12 = llvm.mlir.constant(0 : i32) : i32
      %13 = llvm.mlir.constant(0 : i8) : i8
      %14 = llvm.mlir.constant(0.000000e+00 : f32) : f32
      %15 = llvm.mlir.constant(-1 : i32) : i32
      %16 = llvm.mlir.constant(16 : i32) : i32
      %17 = llvm.mlir.constant(31 : i32) : i32
      %18 = llvm.mlir.constant(4 : i32) : i32
      %19 = llvm.mlir.constant(32 : i32) : i32
      %20 = llvm.mlir.constant(4.096000e+03 : f32) : f32
      %21 = llvm.mlir.constant(64 : i32) : i32
      %22 = llvm.mlir.constant(8 : i32) : i32
      %23 = llvm.mlir.constant(1 : i32) : i32
      %24 = llvm.alloca %22 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %25 = llvm.alloca %22 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %26 = llvm.alloca %21 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %27 = llvm.alloca %21 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %28 = llvm.alloca %21 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
      %29 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
      %30 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %31 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %32 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %33 = llvm.extractvalue %32[0] : !llvm.struct<(i32, struct<()>)> 
      %34 = llvm.getelementptr %9[16384] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
      %35 = llvm.mul %31, %7 : i32
      %36 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %37 = llvm.getelementptr %36[%35] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %38 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %39 = llvm.getelementptr %38[%35] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %40 = llvm.mul %31, %10 : i32
      %41 = llvm.sdiv %30, %21 : i32
      %42 = llvm.srem %30, %21 : i32
      %43 = llvm.mul %42, %22 : i32
      %44 = llvm.mul %41, %11 : i32
      %45 = llvm.add %43, %44 : i32
      %46 = llvm.getelementptr %37[%45] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %47 = llvm.getelementptr %9[%45] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %48 = llvm.getelementptr %39[%45] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %49 = llvm.add %40, %41 : i32
      %50 = llvm.getelementptr %29[%43] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
      %51 = llvm.icmp "slt" %43, %11 : i32
      %52 = llvm.zext %51 : i1 to i8
      %53 = llvm.ptrtoint %25 : !llvm.ptr to i64
      %54 = llvm.inttoptr %53 : i64 to !llvm.ptr
      llvm.store %52, %54 {alignment = 32 : i64} : i8, !llvm.ptr
      %55 = llvm.add %43, %6 : i32
      %56 = llvm.icmp "slt" %55, %11 : i32
      %57 = llvm.zext %56 : i1 to i8
      %58 = llvm.getelementptr %25[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %59 = llvm.ptrtoint %58 : !llvm.ptr to i64
      %60 = llvm.inttoptr %59 : i64 to !llvm.ptr
      llvm.store %57, %60 {alignment = 1 : i64} : i8, !llvm.ptr
      %61 = llvm.add %43, %5 : i32
      %62 = llvm.icmp "slt" %61, %11 : i32
      %63 = llvm.zext %62 : i1 to i8
      %64 = llvm.getelementptr %25[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %65 = llvm.ptrtoint %64 : !llvm.ptr to i64
      %66 = llvm.inttoptr %65 : i64 to !llvm.ptr
      llvm.store %63, %66 {alignment = 2 : i64} : i8, !llvm.ptr
      %67 = llvm.add %43, %4 : i32
      %68 = llvm.icmp "slt" %67, %11 : i32
      %69 = llvm.zext %68 : i1 to i8
      %70 = llvm.getelementptr %25[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %71 = llvm.ptrtoint %70 : !llvm.ptr to i64
      %72 = llvm.inttoptr %71 : i64 to !llvm.ptr
      llvm.store %69, %72 {alignment = 1 : i64} : i8, !llvm.ptr
      %73 = llvm.add %43, %3 : i32
      %74 = llvm.icmp "slt" %73, %11 : i32
      %75 = llvm.zext %74 : i1 to i8
      %76 = llvm.getelementptr %25[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %77 = llvm.ptrtoint %76 : !llvm.ptr to i64
      %78 = llvm.inttoptr %77 : i64 to !llvm.ptr
      llvm.store %75, %78 {alignment = 4 : i64} : i8, !llvm.ptr
      %79 = llvm.add %43, %2 : i32
      %80 = llvm.icmp "slt" %79, %11 : i32
      %81 = llvm.zext %80 : i1 to i8
      %82 = llvm.getelementptr %25[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %83 = llvm.ptrtoint %82 : !llvm.ptr to i64
      %84 = llvm.inttoptr %83 : i64 to !llvm.ptr
      llvm.store %81, %84 {alignment = 1 : i64} : i8, !llvm.ptr
      %85 = llvm.add %43, %1 : i32
      %86 = llvm.icmp "slt" %85, %11 : i32
      %87 = llvm.zext %86 : i1 to i8
      %88 = llvm.getelementptr %25[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %89 = llvm.ptrtoint %88 : !llvm.ptr to i64
      %90 = llvm.inttoptr %89 : i64 to !llvm.ptr
      llvm.store %87, %90 {alignment = 2 : i64} : i8, !llvm.ptr
      %91 = llvm.add %43, %0 : i32
      %92 = llvm.icmp "slt" %91, %11 : i32
      %93 = llvm.zext %92 : i1 to i8
      %94 = llvm.getelementptr %25[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %95 = llvm.ptrtoint %94 : !llvm.ptr to i64
      %96 = llvm.inttoptr %95 : i64 to !llvm.ptr
      llvm.store %93, %96 {alignment = 1 : i64} : i8, !llvm.ptr
      %97 = llvm.icmp "slt" %49, %33 : i32
      llvm.cond_br %97, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %98 = llvm.getelementptr %46[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %99 = llvm.getelementptr %47[512] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %100 = llvm.getelementptr %46[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %101 = llvm.getelementptr %47[1024] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %102 = llvm.getelementptr %46[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %103 = llvm.getelementptr %47[1536] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %104 = llvm.getelementptr %46[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %105 = llvm.getelementptr %47[2048] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %106 = llvm.getelementptr %46[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %107 = llvm.getelementptr %47[2560] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %108 = llvm.getelementptr %46[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %109 = llvm.getelementptr %47[3072] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      %110 = llvm.getelementptr %46[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %111 = llvm.getelementptr %47[3584] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
      llvm.br ^bb2(%12 : i32)
    ^bb2(%112: i32):  // 2 preds: ^bb1, ^bb3
      %113 = llvm.icmp "slt" %112, %23 : i32
      llvm.cond_br %113, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %114 = llvm.getelementptr %25[%112] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %115 = llvm.load %114 : !llvm.ptr -> i8
      %116 = llvm.trunc %115 : i8 to i1
      %117 = llvm.select %116, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %47, %46, 16, cache =  ca, %117 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %118 = llvm.getelementptr %114[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %119 = llvm.load %118 : !llvm.ptr -> i8
      %120 = llvm.trunc %119 : i8 to i1
      %121 = llvm.select %120, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %99, %98, 16, cache =  ca, %121 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %122 = llvm.getelementptr %114[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %123 = llvm.load %122 : !llvm.ptr -> i8
      %124 = llvm.trunc %123 : i8 to i1
      %125 = llvm.select %124, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %101, %100, 16, cache =  ca, %125 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %126 = llvm.getelementptr %114[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %127 = llvm.load %126 : !llvm.ptr -> i8
      %128 = llvm.trunc %127 : i8 to i1
      %129 = llvm.select %128, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %103, %102, 16, cache =  ca, %129 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %130 = llvm.getelementptr %114[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %131 = llvm.load %130 : !llvm.ptr -> i8
      %132 = llvm.trunc %131 : i8 to i1
      %133 = llvm.select %132, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %105, %104, 16, cache =  ca, %133 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %134 = llvm.getelementptr %114[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %135 = llvm.load %134 : !llvm.ptr -> i8
      %136 = llvm.trunc %135 : i8 to i1
      %137 = llvm.select %136, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %107, %106, 16, cache =  ca, %137 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %138 = llvm.getelementptr %114[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %139 = llvm.load %138 : !llvm.ptr -> i8
      %140 = llvm.trunc %139 : i8 to i1
      %141 = llvm.select %140, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %109, %108, 16, cache =  ca, %141 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %142 = llvm.getelementptr %114[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %143 = llvm.load %142 : !llvm.ptr -> i8
      %144 = llvm.trunc %143 : i8 to i1
      %145 = llvm.select %144, %16, %12 : i1, i32
      nvvm.cp.async.shared.global %111, %110, 16, cache =  ca, %145 : !llvm.ptr<3>, !llvm.ptr<1>, i32
      %146 = llvm.add %112, %23 : i32
      llvm.br ^bb2(%146 : i32)
    ^bb4:  // pred: ^bb2
      llvm.br ^bb5
    ^bb5:  // 2 preds: ^bb0, ^bb4
      nvvm.cp.async.commit.group
      %147 = llvm.ptrtoint %24 : !llvm.ptr to i64
      %148 = llvm.inttoptr %147 : i64 to !llvm.ptr
      llvm.store %52, %148 {alignment = 32 : i64} : i8, !llvm.ptr
      %149 = llvm.getelementptr %24[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %150 = llvm.ptrtoint %149 : !llvm.ptr to i64
      %151 = llvm.inttoptr %150 : i64 to !llvm.ptr
      llvm.store %57, %151 {alignment = 1 : i64} : i8, !llvm.ptr
      %152 = llvm.getelementptr %24[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %153 = llvm.ptrtoint %152 : !llvm.ptr to i64
      %154 = llvm.inttoptr %153 : i64 to !llvm.ptr
      llvm.store %63, %154 {alignment = 2 : i64} : i8, !llvm.ptr
      %155 = llvm.getelementptr %24[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %156 = llvm.ptrtoint %155 : !llvm.ptr to i64
      %157 = llvm.inttoptr %156 : i64 to !llvm.ptr
      llvm.store %69, %157 {alignment = 1 : i64} : i8, !llvm.ptr
      %158 = llvm.getelementptr %24[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %159 = llvm.ptrtoint %158 : !llvm.ptr to i64
      %160 = llvm.inttoptr %159 : i64 to !llvm.ptr
      llvm.store %75, %160 {alignment = 4 : i64} : i8, !llvm.ptr
      %161 = llvm.getelementptr %24[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %162 = llvm.ptrtoint %161 : !llvm.ptr to i64
      %163 = llvm.inttoptr %162 : i64 to !llvm.ptr
      llvm.store %81, %163 {alignment = 1 : i64} : i8, !llvm.ptr
      %164 = llvm.getelementptr %24[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %165 = llvm.ptrtoint %164 : !llvm.ptr to i64
      %166 = llvm.inttoptr %165 : i64 to !llvm.ptr
      llvm.store %87, %166 {alignment = 2 : i64} : i8, !llvm.ptr
      %167 = llvm.getelementptr %24[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %168 = llvm.ptrtoint %167 : !llvm.ptr to i64
      %169 = llvm.inttoptr %168 : i64 to !llvm.ptr
      llvm.store %93, %169 {alignment = 1 : i64} : i8, !llvm.ptr
      llvm.br ^bb6(%12 : i32)
    ^bb6(%170: i32):  // 2 preds: ^bb5, ^bb23
      %171 = llvm.icmp "slt" %170, %23 : i32
      llvm.cond_br %171, ^bb7, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %172 = llvm.getelementptr %24[%170] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %173 = llvm.load %172 : !llvm.ptr -> i8
      %174 = llvm.icmp "ne" %173, %13 : i8
      llvm.cond_br %174, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %175 = llvm.load %50 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %175, %26 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %176 = llvm.getelementptr %172[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %177 = llvm.load %176 : !llvm.ptr -> i8
      %178 = llvm.icmp "ne" %177, %13 : i8
      llvm.cond_br %178, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %179 = llvm.getelementptr %50[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %180 = llvm.getelementptr %26[8] : (!llvm.ptr) -> !llvm.ptr, bf16
      %181 = llvm.load %179 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %181, %180 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %182 = llvm.getelementptr %172[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %183 = llvm.load %182 : !llvm.ptr -> i8
      %184 = llvm.icmp "ne" %183, %13 : i8
      llvm.cond_br %184, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %185 = llvm.getelementptr %50[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %186 = llvm.getelementptr %26[16] : (!llvm.ptr) -> !llvm.ptr, bf16
      %187 = llvm.load %185 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %187, %186 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %188 = llvm.getelementptr %172[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %189 = llvm.load %188 : !llvm.ptr -> i8
      %190 = llvm.icmp "ne" %189, %13 : i8
      llvm.cond_br %190, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %191 = llvm.getelementptr %50[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %192 = llvm.getelementptr %26[24] : (!llvm.ptr) -> !llvm.ptr, bf16
      %193 = llvm.load %191 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %193, %192 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %194 = llvm.getelementptr %172[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %195 = llvm.load %194 : !llvm.ptr -> i8
      %196 = llvm.icmp "ne" %195, %13 : i8
      llvm.cond_br %196, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %197 = llvm.getelementptr %50[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %198 = llvm.getelementptr %26[32] : (!llvm.ptr) -> !llvm.ptr, bf16
      %199 = llvm.load %197 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %199, %198 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %200 = llvm.getelementptr %172[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %201 = llvm.load %200 : !llvm.ptr -> i8
      %202 = llvm.icmp "ne" %201, %13 : i8
      llvm.cond_br %202, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %203 = llvm.getelementptr %50[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %204 = llvm.getelementptr %26[40] : (!llvm.ptr) -> !llvm.ptr, bf16
      %205 = llvm.load %203 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %205, %204 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %206 = llvm.getelementptr %172[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %207 = llvm.load %206 : !llvm.ptr -> i8
      %208 = llvm.icmp "ne" %207, %13 : i8
      llvm.cond_br %208, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %209 = llvm.getelementptr %50[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %210 = llvm.getelementptr %26[48] : (!llvm.ptr) -> !llvm.ptr, bf16
      %211 = llvm.load %209 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %211, %210 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %212 = llvm.getelementptr %172[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %213 = llvm.load %212 : !llvm.ptr -> i8
      %214 = llvm.icmp "ne" %213, %13 : i8
      llvm.cond_br %214, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %215 = llvm.getelementptr %50[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %216 = llvm.getelementptr %26[56] : (!llvm.ptr) -> !llvm.ptr, bf16
      %217 = llvm.load %215 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %217, %216 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      llvm.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %218 = llvm.add %170, %23 : i32
      llvm.br ^bb6(%218 : i32)
    ^bb24:  // pred: ^bb6
      nvvm.cp.async.wait.group 0
      llvm.br ^bb25(%12 : i32)
    ^bb25(%219: i32):  // 2 preds: ^bb24, ^bb26
      %220 = llvm.icmp "slt" %219, %22 : i32
      llvm.cond_br %220, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %221 = llvm.mul %219, %6 : i32
      %222 = llvm.getelementptr %47[%221] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %223 = llvm.mul %219, %22 : i32
      %224 = llvm.getelementptr %28[%223] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %225 = llvm.load %222 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %225, %224 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %226 = llvm.add %219, %23 : i32
      llvm.br ^bb25(%226 : i32)
    ^bb27:  // pred: ^bb25
      %227 = llvm.load %28 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %228 = llvm.fpext %227 : vector<64xbf16> to vector<64xf32>
      %229 = llvm.fmul %228, %228 : vector<64xf32>
      %230 = vector.reduction <add>, %229, %14 : vector<64xf32> into f32
      %231 = nvvm.shfl.sync  bfly %15, %230, %16, %17 : f32 -> f32
      %232 = llvm.fadd %231, %230 : f32
      %233 = nvvm.shfl.sync  bfly %15, %232, %22, %17 : f32 -> f32
      %234 = llvm.fadd %232, %233 : f32
      %235 = nvvm.shfl.sync  bfly %15, %234, %18, %17 : f32 -> f32
      %236 = llvm.fadd %234, %235 : f32
      %237 = nvvm.shfl.sync  bfly %15, %236, %10, %17 : f32 -> f32
      %238 = llvm.fadd %236, %237 : f32
      %239 = nvvm.shfl.sync  bfly %15, %238, %23, %17 : f32 -> f32
      %240 = llvm.fadd %238, %239 : f32
      %241 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %242 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %243 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %244 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %245 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %246 = llvm.mul %242, %244 : i32
      %247 = llvm.add %30, %246 : i32
      %248 = llvm.mul %243, %244 : i32
      %249 = llvm.mul %248, %245 : i32
      %250 = llvm.add %247, %249 : i32
      %251 = llvm.sdiv %250, %19 : i32
      %252 = llvm.mul %251, %19 : i32
      %253 = llvm.icmp "ne" %250, %252 : i32
      %254 = llvm.icmp "slt" %250, %12 : i32
      %255 = llvm.icmp "ne" %254, %8 : i1
      %256 = llvm.and %253, %255 : i1
      %257 = llvm.add %251, %15 : i32
      %258 = llvm.select %256, %257, %251 : i1, i32
      %259 = llvm.sdiv %258, %10 : i32
      %260 = llvm.mul %259, %10 : i32
      %261 = llvm.icmp "ne" %258, %260 : i32
      %262 = llvm.icmp "slt" %258, %12 : i32
      %263 = llvm.icmp "ne" %262, %8 : i1
      %264 = llvm.and %261, %263 : i1
      %265 = llvm.add %259, %15 : i32
      %266 = llvm.select %264, %265, %259 : i1, i32
      %267 = llvm.srem %258, %10 : i32
      %268 = llvm.icmp "eq" %241, %12 : i32
      llvm.cond_br %268, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %269 = llvm.mul %267, %10 : i32
      %270 = llvm.add %266, %269 : i32
      %271 = llvm.getelementptr %34[%270] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
      %272 = llvm.ptrtoint %271 : !llvm.ptr<3> to i64
      %273 = llvm.inttoptr %272 : i64 to !llvm.ptr<3>
      llvm.store %240, %273 {alignment = 4 : i64} : f32, !llvm.ptr<3>
      llvm.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      nvvm.barrier
      %274 = llvm.icmp "slt" %241, %10 : i32
      llvm.cond_br %274, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %275 = llvm.mul %241, %10 : i32
      %276 = llvm.add %266, %275 : i32
      %277 = llvm.getelementptr %34[%276] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
      %278 = llvm.ptrtoint %277 : !llvm.ptr<3> to i64
      %279 = llvm.inttoptr %278 : i64 to !llvm.ptr<3>
      %280 = llvm.load %279 {alignment = 4 : i64} : !llvm.ptr<3> -> f32
      llvm.br ^bb32(%280 : f32)
    ^bb31:  // pred: ^bb29
      llvm.br ^bb32(%14 : f32)
    ^bb32(%281: f32):  // 2 preds: ^bb30, ^bb31
      llvm.br ^bb33
    ^bb33:  // pred: ^bb32
      %282 = nvvm.shfl.sync  bfly %15, %281, %16, %17 : f32 -> f32
      %283 = llvm.fadd %281, %282 : f32
      %284 = nvvm.shfl.sync  bfly %15, %283, %22, %17 : f32 -> f32
      %285 = llvm.fadd %283, %284 : f32
      %286 = nvvm.shfl.sync  bfly %15, %285, %18, %17 : f32 -> f32
      %287 = llvm.fadd %285, %286 : f32
      %288 = nvvm.shfl.sync  bfly %15, %287, %10, %17 : f32 -> f32
      %289 = llvm.fadd %287, %288 : f32
      %290 = nvvm.shfl.sync  bfly %15, %289, %23, %17 : f32 -> f32
      %291 = llvm.fadd %289, %290 : f32
      %292 = llvm.fdiv %291, %20 : f32
      %293 = llvm.fadd %292, %arg3 : f32
      %294 = math.rsqrt %293 fastmath<fast> : f32
      nvvm.barrier
      llvm.br ^bb34(%12 : i32)
    ^bb34(%295: i32):  // 2 preds: ^bb33, ^bb35
      %296 = llvm.icmp "slt" %295, %22 : i32
      llvm.cond_br %296, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %297 = llvm.mul %295, %6 : i32
      %298 = llvm.getelementptr %47[%297] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
      %299 = llvm.mul %295, %22 : i32
      %300 = llvm.getelementptr %28[%299] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
      %301 = llvm.load %298 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %301, %300 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %302 = llvm.add %295, %23 : i32
      llvm.br ^bb34(%302 : i32)
    ^bb36:  // pred: ^bb34
      %303 = llvm.load %28 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %304 = llvm.fpext %303 : vector<64xbf16> to vector<64xf32>
      %305 = vector.broadcast %294 : f32 to vector<64xf32>
      %306 = llvm.fmul %304, %305 : vector<64xf32>
      %307 = llvm.load %26 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
      %308 = llvm.fpext %307 : vector<64xbf16> to vector<64xf32>
      %309 = llvm.fmul %306, %308 : vector<64xf32>
      %310 = llvm.fptrunc %309 : vector<64xf32> to vector<64xbf16>
      llvm.store %310, %27 {alignment = 32 : i64} : vector<64xbf16>, !llvm.ptr
      llvm.cond_br %97, ^bb37, ^bb57
    ^bb37:  // pred: ^bb36
      llvm.br ^bb38(%12 : i32)
    ^bb38(%311: i32):  // 2 preds: ^bb37, ^bb55
      %312 = llvm.icmp "slt" %311, %23 : i32
      llvm.cond_br %312, ^bb39, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %313 = llvm.getelementptr %25[%311] : (!llvm.ptr, i32) -> !llvm.ptr, i8
      %314 = llvm.load %313 : !llvm.ptr -> i8
      %315 = llvm.icmp "ne" %314, %13 : i8
      llvm.cond_br %315, ^bb40, ^bb41
    ^bb40:  // pred: ^bb39
      %316 = llvm.load %27 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %316, %48 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb41
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %317 = llvm.getelementptr %313[1] : (!llvm.ptr) -> !llvm.ptr, i8
      %318 = llvm.load %317 : !llvm.ptr -> i8
      %319 = llvm.icmp "ne" %318, %13 : i8
      llvm.cond_br %319, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %320 = llvm.getelementptr %27[8] : (!llvm.ptr) -> !llvm.ptr, bf16
      %321 = llvm.getelementptr %48[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %322 = llvm.load %320 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %322, %321 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %323 = llvm.getelementptr %313[2] : (!llvm.ptr) -> !llvm.ptr, i8
      %324 = llvm.load %323 : !llvm.ptr -> i8
      %325 = llvm.icmp "ne" %324, %13 : i8
      llvm.cond_br %325, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %326 = llvm.getelementptr %27[16] : (!llvm.ptr) -> !llvm.ptr, bf16
      %327 = llvm.getelementptr %48[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %328 = llvm.load %326 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %328, %327 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %329 = llvm.getelementptr %313[3] : (!llvm.ptr) -> !llvm.ptr, i8
      %330 = llvm.load %329 : !llvm.ptr -> i8
      %331 = llvm.icmp "ne" %330, %13 : i8
      llvm.cond_br %331, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %332 = llvm.getelementptr %27[24] : (!llvm.ptr) -> !llvm.ptr, bf16
      %333 = llvm.getelementptr %48[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %334 = llvm.load %332 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %334, %333 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %335 = llvm.getelementptr %313[4] : (!llvm.ptr) -> !llvm.ptr, i8
      %336 = llvm.load %335 : !llvm.ptr -> i8
      %337 = llvm.icmp "ne" %336, %13 : i8
      llvm.cond_br %337, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %338 = llvm.getelementptr %27[32] : (!llvm.ptr) -> !llvm.ptr, bf16
      %339 = llvm.getelementptr %48[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %340 = llvm.load %338 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %340, %339 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %341 = llvm.getelementptr %313[5] : (!llvm.ptr) -> !llvm.ptr, i8
      %342 = llvm.load %341 : !llvm.ptr -> i8
      %343 = llvm.icmp "ne" %342, %13 : i8
      llvm.cond_br %343, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %344 = llvm.getelementptr %27[40] : (!llvm.ptr) -> !llvm.ptr, bf16
      %345 = llvm.getelementptr %48[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %346 = llvm.load %344 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %346, %345 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %347 = llvm.getelementptr %313[6] : (!llvm.ptr) -> !llvm.ptr, i8
      %348 = llvm.load %347 : !llvm.ptr -> i8
      %349 = llvm.icmp "ne" %348, %13 : i8
      llvm.cond_br %349, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %350 = llvm.getelementptr %27[48] : (!llvm.ptr) -> !llvm.ptr, bf16
      %351 = llvm.getelementptr %48[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %352 = llvm.load %350 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %352, %351 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %353 = llvm.getelementptr %313[7] : (!llvm.ptr) -> !llvm.ptr, i8
      %354 = llvm.load %353 : !llvm.ptr -> i8
      %355 = llvm.icmp "ne" %354, %13 : i8
      llvm.cond_br %355, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %356 = llvm.getelementptr %27[56] : (!llvm.ptr) -> !llvm.ptr, bf16
      %357 = llvm.getelementptr %48[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
      %358 = llvm.load %356 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %358, %357 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      llvm.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %359 = llvm.add %311, %23 : i32
      llvm.br ^bb38(%359 : i32)
    ^bb56:  // pred: ^bb38
      llvm.br ^bb57
    ^bb57:  // 2 preds: ^bb36, ^bb56
      llvm.return
    }
  }
  llvm.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg1: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg2: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(false) : i1
    %1 = llvm.mlir.constant(true) : i1
    %2 = llvm.mlir.constant(-1 : i32) : i32
    %3 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>
    %4 = llvm.mlir.undef : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>
    %5 = llvm.mlir.constant(16400 : i64) : i64
    %6 = llvm.mlir.constant(0 : i32) : i32
    %7 = llvm.mlir.constant(1 : i32) : i32
    %8 = llvm.mlir.constant(128 : i32) : i32
    %9 = llvm.mlir.constant(2 : i32) : i32
    %10 = llvm.mlir.poison : !llvm.struct<(struct<()>, struct<()>)>
    %11 = llvm.mlir.poison : !llvm.struct<()>
    %12 = llvm.mlir.undef : !llvm.struct<(i32, struct<()>)>
    %13 = llvm.insertvalue %arg3, %12[0] : !llvm.struct<(i32, struct<()>)> 
    %14 = llvm.insertvalue %11, %13[1] : !llvm.struct<(i32, struct<()>)> 
    %15 = llvm.insertvalue %arg0, %4[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %16 = llvm.insertvalue %14, %15[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %17 = llvm.insertvalue %arg2, %4[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %18 = llvm.insertvalue %14, %17[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %19 = llvm.insertvalue %arg1, %3[0] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
    %20 = llvm.insertvalue %10, %19[1] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
    %21 = llvm.select %1, %2, %7 : i1, i32
    %22 = llvm.add %21, %arg3 : i32
    %23 = llvm.sdiv %22, %9 : i32
    %24 = llvm.add %23, %7 : i32
    %25 = llvm.sub %6, %arg3 : i32
    %26 = llvm.sdiv %25, %9 : i32
    %27 = llvm.sub %6, %26 : i32
    %28 = llvm.icmp "slt" %arg3, %6 : i32
    %29 = llvm.icmp "sgt" %arg3, %6 : i32
    %30 = llvm.and %28, %0 : i1
    %31 = llvm.and %29, %1 : i1
    %32 = llvm.or %30, %31 : i1
    %33 = llvm.select %32, %24, %27 : i1, i32
    %34 = llvm.alloca %7 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %35 = llvm.alloca %7 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %36 = llvm.getelementptr %34[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %35, %36 : !llvm.ptr, !llvm.ptr
    %37 = llvm.getelementptr %34[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %8, %37 : i32, !llvm.ptr
    %38 = llvm.getelementptr %34[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %7, %38 : i32, !llvm.ptr
    %39 = llvm.getelementptr %34[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %7, %39 : i32, !llvm.ptr
    %40 = llvm.getelementptr %34[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %5, %40 : i64, !llvm.ptr
    %41 = llvm.getelementptr %34[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %33, %41 : i32, !llvm.ptr
    %42 = llvm.getelementptr %34[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %7, %42 : i32, !llvm.ptr
    %43 = llvm.getelementptr %34[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %7, %43 : i32, !llvm.ptr
    %44 = llvm.getelementptr %34[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %6, %44 : i32, !llvm.ptr
    %45 = llvm.getelementptr %34[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %arg5, %45 : !llvm.ptr, !llvm.ptr
    %46 = llvm.alloca %7 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %47 = llvm.getelementptr %46[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %34, %47 : !llvm.ptr, !llvm.ptr
    %48 = builtin.unrealized_conversion_cast %46 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %49 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%48> (%16, %20, %18, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32) -> !cuda.result
    %50 = builtin.unrealized_conversion_cast %49 : !cuda.result to i32
    cuda.return_if_error %50 : i32
    llvm.return %6 : i32
  }
  llvm.func @_mlir_ciface_cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg1: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg2: !llvm.ptr<1> {llvm.align = 16 : i64}, %arg3: i32, %arg4: f32, %arg5: !llvm.ptr) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0, %arg1, %arg2, %arg3, %arg4, %arg5) : (!llvm.ptr<1>, !llvm.ptr<1>, !llvm.ptr<1>, i32, f32, !llvm.ptr) -> i32
    llvm.return %0 : i32
  }
}
