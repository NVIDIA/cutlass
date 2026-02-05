gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
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
    llvm.cond_br %113, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %114 = llvm.getelementptr %25[%112] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %115 = llvm.load %114 : !llvm.ptr -> i8
    %116 = llvm.trunc %115 : i8 to i1
    %117 = llvm.select %116, %16, %12 : i1, i32
    %118 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %47, %46, %118, %117 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %119 = llvm.getelementptr %114[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %120 = llvm.load %119 : !llvm.ptr -> i8
    %121 = llvm.trunc %120 : i8 to i1
    %122 = llvm.select %121, %16, %12 : i1, i32
    %123 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %99, %98, %123, %122 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %124 = llvm.getelementptr %114[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %125 = llvm.load %124 : !llvm.ptr -> i8
    %126 = llvm.trunc %125 : i8 to i1
    %127 = llvm.select %126, %16, %12 : i1, i32
    %128 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %101, %100, %128, %127 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %129 = llvm.getelementptr %114[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %130 = llvm.load %129 : !llvm.ptr -> i8
    %131 = llvm.trunc %130 : i8 to i1
    %132 = llvm.select %131, %16, %12 : i1, i32
    %133 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %103, %102, %133, %132 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %134 = llvm.getelementptr %114[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %135 = llvm.load %134 : !llvm.ptr -> i8
    %136 = llvm.trunc %135 : i8 to i1
    %137 = llvm.select %136, %16, %12 : i1, i32
    %138 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %105, %104, %138, %137 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %139 = llvm.getelementptr %114[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %140 = llvm.load %139 : !llvm.ptr -> i8
    %141 = llvm.trunc %140 : i8 to i1
    %142 = llvm.select %141, %16, %12 : i1, i32
    %143 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %107, %106, %143, %142 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %144 = llvm.getelementptr %114[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %145 = llvm.load %144 : !llvm.ptr -> i8
    %146 = llvm.trunc %145 : i8 to i1
    %147 = llvm.select %146, %16, %12 : i1, i32
    %148 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %109, %108, %148, %147 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %149 = llvm.getelementptr %114[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %150 = llvm.load %149 : !llvm.ptr -> i8
    %151 = llvm.trunc %150 : i8 to i1
    %152 = llvm.select %151, %16, %12 : i1, i32
    %153 = llvm.mlir.constant(16 : i32) : i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %111, %110, %153, %152 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %154 = llvm.add %112, %23 : i32
    llvm.br ^bb2(%154 : i32)
  ^bb4:  // pred: ^bb2
    llvm.br ^bb5
  ^bb5:  // 2 preds: ^bb0, ^bb4
    nvvm.cp.async.commit.group
    %155 = llvm.ptrtoint %24 : !llvm.ptr to i64
    %156 = llvm.inttoptr %155 : i64 to !llvm.ptr
    llvm.store %52, %156 {alignment = 32 : i64} : i8, !llvm.ptr
    %157 = llvm.getelementptr %24[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %158 = llvm.ptrtoint %157 : !llvm.ptr to i64
    %159 = llvm.inttoptr %158 : i64 to !llvm.ptr
    llvm.store %57, %159 {alignment = 1 : i64} : i8, !llvm.ptr
    %160 = llvm.getelementptr %24[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %161 = llvm.ptrtoint %160 : !llvm.ptr to i64
    %162 = llvm.inttoptr %161 : i64 to !llvm.ptr
    llvm.store %63, %162 {alignment = 2 : i64} : i8, !llvm.ptr
    %163 = llvm.getelementptr %24[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %164 = llvm.ptrtoint %163 : !llvm.ptr to i64
    %165 = llvm.inttoptr %164 : i64 to !llvm.ptr
    llvm.store %69, %165 {alignment = 1 : i64} : i8, !llvm.ptr
    %166 = llvm.getelementptr %24[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %167 = llvm.ptrtoint %166 : !llvm.ptr to i64
    %168 = llvm.inttoptr %167 : i64 to !llvm.ptr
    llvm.store %75, %168 {alignment = 4 : i64} : i8, !llvm.ptr
    %169 = llvm.getelementptr %24[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %170 = llvm.ptrtoint %169 : !llvm.ptr to i64
    %171 = llvm.inttoptr %170 : i64 to !llvm.ptr
    llvm.store %81, %171 {alignment = 1 : i64} : i8, !llvm.ptr
    %172 = llvm.getelementptr %24[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %173 = llvm.ptrtoint %172 : !llvm.ptr to i64
    %174 = llvm.inttoptr %173 : i64 to !llvm.ptr
    llvm.store %87, %174 {alignment = 2 : i64} : i8, !llvm.ptr
    %175 = llvm.getelementptr %24[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %176 = llvm.ptrtoint %175 : !llvm.ptr to i64
    %177 = llvm.inttoptr %176 : i64 to !llvm.ptr
    llvm.store %93, %177 {alignment = 1 : i64} : i8, !llvm.ptr
    llvm.br ^bb6(%12 : i32)
  ^bb6(%178: i32):  // 2 preds: ^bb5, ^bb23
    %179 = llvm.icmp "slt" %178, %23 : i32
    llvm.cond_br %179, ^bb7, ^bb24 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb7:  // pred: ^bb6
    %180 = llvm.getelementptr %24[%178] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %181 = llvm.load %180 : !llvm.ptr -> i8
    %182 = llvm.icmp "ne" %181, %13 : i8
    llvm.cond_br %182, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %183 = llvm.load %50 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %183, %26 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb9
  ^bb9:  // 2 preds: ^bb7, ^bb8
    %184 = llvm.getelementptr %180[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %185 = llvm.load %184 : !llvm.ptr -> i8
    %186 = llvm.icmp "ne" %185, %13 : i8
    llvm.cond_br %186, ^bb10, ^bb11
  ^bb10:  // pred: ^bb9
    %187 = llvm.getelementptr %50[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %188 = llvm.getelementptr %26[8] : (!llvm.ptr) -> !llvm.ptr, bf16
    %189 = llvm.load %187 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %189, %188 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb11
  ^bb11:  // 2 preds: ^bb9, ^bb10
    %190 = llvm.getelementptr %180[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %191 = llvm.load %190 : !llvm.ptr -> i8
    %192 = llvm.icmp "ne" %191, %13 : i8
    llvm.cond_br %192, ^bb12, ^bb13
  ^bb12:  // pred: ^bb11
    %193 = llvm.getelementptr %50[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %194 = llvm.getelementptr %26[16] : (!llvm.ptr) -> !llvm.ptr, bf16
    %195 = llvm.load %193 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %195, %194 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb13
  ^bb13:  // 2 preds: ^bb11, ^bb12
    %196 = llvm.getelementptr %180[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %197 = llvm.load %196 : !llvm.ptr -> i8
    %198 = llvm.icmp "ne" %197, %13 : i8
    llvm.cond_br %198, ^bb14, ^bb15
  ^bb14:  // pred: ^bb13
    %199 = llvm.getelementptr %50[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %200 = llvm.getelementptr %26[24] : (!llvm.ptr) -> !llvm.ptr, bf16
    %201 = llvm.load %199 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %201, %200 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb15
  ^bb15:  // 2 preds: ^bb13, ^bb14
    %202 = llvm.getelementptr %180[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %203 = llvm.load %202 : !llvm.ptr -> i8
    %204 = llvm.icmp "ne" %203, %13 : i8
    llvm.cond_br %204, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %205 = llvm.getelementptr %50[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %206 = llvm.getelementptr %26[32] : (!llvm.ptr) -> !llvm.ptr, bf16
    %207 = llvm.load %205 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %207, %206 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    %208 = llvm.getelementptr %180[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %209 = llvm.load %208 : !llvm.ptr -> i8
    %210 = llvm.icmp "ne" %209, %13 : i8
    llvm.cond_br %210, ^bb18, ^bb19
  ^bb18:  // pred: ^bb17
    %211 = llvm.getelementptr %50[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %212 = llvm.getelementptr %26[40] : (!llvm.ptr) -> !llvm.ptr, bf16
    %213 = llvm.load %211 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %213, %212 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb19
  ^bb19:  // 2 preds: ^bb17, ^bb18
    %214 = llvm.getelementptr %180[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %215 = llvm.load %214 : !llvm.ptr -> i8
    %216 = llvm.icmp "ne" %215, %13 : i8
    llvm.cond_br %216, ^bb20, ^bb21
  ^bb20:  // pred: ^bb19
    %217 = llvm.getelementptr %50[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %218 = llvm.getelementptr %26[48] : (!llvm.ptr) -> !llvm.ptr, bf16
    %219 = llvm.load %217 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %219, %218 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb21
  ^bb21:  // 2 preds: ^bb19, ^bb20
    %220 = llvm.getelementptr %180[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %221 = llvm.load %220 : !llvm.ptr -> i8
    %222 = llvm.icmp "ne" %221, %13 : i8
    llvm.cond_br %222, ^bb22, ^bb23
  ^bb22:  // pred: ^bb21
    %223 = llvm.getelementptr %50[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %224 = llvm.getelementptr %26[56] : (!llvm.ptr) -> !llvm.ptr, bf16
    %225 = llvm.load %223 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %225, %224 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb23
  ^bb23:  // 2 preds: ^bb21, ^bb22
    %226 = llvm.add %178, %23 : i32
    llvm.br ^bb6(%226 : i32)
  ^bb24:  // pred: ^bb6
    nvvm.cp.async.wait.group 0
    llvm.br ^bb25(%12 : i32)
  ^bb25(%227: i32):  // 2 preds: ^bb24, ^bb26
    %228 = llvm.icmp "slt" %227, %22 : i32
    llvm.cond_br %228, ^bb26, ^bb27 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb26:  // pred: ^bb25
    %229 = llvm.mul %227, %6 : i32
    %230 = llvm.getelementptr %47[%229] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
    %231 = llvm.mul %227, %22 : i32
    %232 = llvm.getelementptr %28[%231] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
    %233 = llvm.load %230 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
    llvm.store %233, %232 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    %234 = llvm.add %227, %23 : i32
    llvm.br ^bb25(%234 : i32)
  ^bb27:  // pred: ^bb25
    %235 = llvm.load %28 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %236 = llvm.fpext %235 : vector<64xbf16> to vector<64xf32>
    %237 = llvm.fmul %236, %236 : vector<64xf32>
    %238 = "llvm.intr.vector.reduce.fadd"(%14, %237) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
    %239 = nvvm.shfl.sync  bfly %15, %238, %16, %17 : f32 -> f32
    %240 = llvm.fadd %239, %238 : f32
    %241 = nvvm.shfl.sync  bfly %15, %240, %22, %17 : f32 -> f32
    %242 = llvm.fadd %240, %241 : f32
    %243 = nvvm.shfl.sync  bfly %15, %242, %18, %17 : f32 -> f32
    %244 = llvm.fadd %242, %243 : f32
    %245 = nvvm.shfl.sync  bfly %15, %244, %10, %17 : f32 -> f32
    %246 = llvm.fadd %244, %245 : f32
    %247 = nvvm.shfl.sync  bfly %15, %246, %23, %17 : f32 -> f32
    %248 = llvm.fadd %246, %247 : f32
    %249 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
    %250 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
    %251 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
    %252 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
    %253 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
    %254 = llvm.mul %250, %252 : i32
    %255 = llvm.add %30, %254 : i32
    %256 = llvm.mul %251, %252 : i32
    %257 = llvm.mul %256, %253 : i32
    %258 = llvm.add %255, %257 : i32
    %259 = llvm.sdiv %258, %19 : i32
    %260 = llvm.mul %259, %19 : i32
    %261 = llvm.icmp "ne" %258, %260 : i32
    %262 = llvm.icmp "slt" %258, %12 : i32
    %263 = llvm.icmp "ne" %262, %8 : i1
    %264 = llvm.and %261, %263 : i1
    %265 = llvm.add %259, %15 : i32
    %266 = llvm.select %264, %265, %259 : i1, i32
    %267 = llvm.sdiv %266, %10 : i32
    %268 = llvm.mul %267, %10 : i32
    %269 = llvm.icmp "ne" %266, %268 : i32
    %270 = llvm.icmp "slt" %266, %12 : i32
    %271 = llvm.icmp "ne" %270, %8 : i1
    %272 = llvm.and %269, %271 : i1
    %273 = llvm.add %267, %15 : i32
    %274 = llvm.select %272, %273, %267 : i1, i32
    %275 = llvm.srem %266, %10 : i32
    %276 = llvm.icmp "eq" %249, %12 : i32
    llvm.cond_br %276, ^bb28, ^bb29
  ^bb28:  // pred: ^bb27
    %277 = llvm.mul %275, %10 : i32
    %278 = llvm.add %274, %277 : i32
    %279 = llvm.getelementptr %34[%278] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
    %280 = llvm.ptrtoint %279 : !llvm.ptr<3> to i64
    %281 = llvm.inttoptr %280 : i64 to !llvm.ptr<3>
    llvm.store %248, %281 {alignment = 4 : i64} : f32, !llvm.ptr<3>
    llvm.br ^bb29
  ^bb29:  // 2 preds: ^bb27, ^bb28
    nvvm.barrier
    %282 = llvm.icmp "slt" %249, %10 : i32
    llvm.cond_br %282, ^bb30, ^bb31
  ^bb30:  // pred: ^bb29
    %283 = llvm.mul %249, %10 : i32
    %284 = llvm.add %274, %283 : i32
    %285 = llvm.getelementptr %34[%284] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
    %286 = llvm.ptrtoint %285 : !llvm.ptr<3> to i64
    %287 = llvm.inttoptr %286 : i64 to !llvm.ptr<3>
    %288 = llvm.load %287 {alignment = 4 : i64} : !llvm.ptr<3> -> f32
    llvm.br ^bb32(%288 : f32)
  ^bb31:  // pred: ^bb29
    llvm.br ^bb32(%14 : f32)
  ^bb32(%289: f32):  // 2 preds: ^bb30, ^bb31
    llvm.br ^bb33
  ^bb33:  // pred: ^bb32
    %290 = nvvm.shfl.sync  bfly %15, %289, %16, %17 : f32 -> f32
    %291 = llvm.fadd %289, %290 : f32
    %292 = nvvm.shfl.sync  bfly %15, %291, %22, %17 : f32 -> f32
    %293 = llvm.fadd %291, %292 : f32
    %294 = nvvm.shfl.sync  bfly %15, %293, %18, %17 : f32 -> f32
    %295 = llvm.fadd %293, %294 : f32
    %296 = nvvm.shfl.sync  bfly %15, %295, %10, %17 : f32 -> f32
    %297 = llvm.fadd %295, %296 : f32
    %298 = nvvm.shfl.sync  bfly %15, %297, %23, %17 : f32 -> f32
    %299 = llvm.fadd %297, %298 : f32
    %300 = llvm.fdiv %299, %20 : f32
    %301 = llvm.fadd %300, %arg3 : f32
    %302 = math.rsqrt %301 fastmath<fast> : f32
    nvvm.barrier
    llvm.br ^bb34(%12 : i32)
  ^bb34(%303: i32):  // 2 preds: ^bb33, ^bb35
    %304 = llvm.icmp "slt" %303, %22 : i32
    llvm.cond_br %304, ^bb35, ^bb36 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb35:  // pred: ^bb34
    %305 = llvm.mul %303, %6 : i32
    %306 = llvm.getelementptr %47[%305] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
    %307 = llvm.mul %303, %22 : i32
    %308 = llvm.getelementptr %28[%307] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
    %309 = llvm.load %306 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
    llvm.store %309, %308 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    %310 = llvm.add %303, %23 : i32
    llvm.br ^bb34(%310 : i32)
  ^bb36:  // pred: ^bb34
    %311 = llvm.load %28 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %312 = llvm.fpext %311 : vector<64xbf16> to vector<64xf32>
    %313 = llvm.mlir.undef : vector<64xf32>
    %314 = llvm.mlir.constant(0 : i32) : i32
    %315 = llvm.insertelement %302, %313[%314 : i32] : vector<64xf32>
    %316 = llvm.shufflevector %315, %313 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] : vector<64xf32> 
    %317 = llvm.fmul %312, %316 : vector<64xf32>
    %318 = llvm.load %26 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %319 = llvm.fpext %318 : vector<64xbf16> to vector<64xf32>
    %320 = llvm.fmul %317, %319 : vector<64xf32>
    %321 = llvm.fptrunc %320 : vector<64xf32> to vector<64xbf16>
    llvm.store %321, %27 {alignment = 32 : i64} : vector<64xbf16>, !llvm.ptr
    llvm.cond_br %97, ^bb37, ^bb57
  ^bb37:  // pred: ^bb36
    llvm.br ^bb38(%12 : i32)
  ^bb38(%322: i32):  // 2 preds: ^bb37, ^bb55
    %323 = llvm.icmp "slt" %322, %23 : i32
    llvm.cond_br %323, ^bb39, ^bb56 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb39:  // pred: ^bb38
    %324 = llvm.getelementptr %25[%322] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %325 = llvm.load %324 : !llvm.ptr -> i8
    %326 = llvm.icmp "ne" %325, %13 : i8
    llvm.cond_br %326, ^bb40, ^bb41
  ^bb40:  // pred: ^bb39
    %327 = llvm.load %27 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %327, %48 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb41
  ^bb41:  // 2 preds: ^bb39, ^bb40
    %328 = llvm.getelementptr %324[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %329 = llvm.load %328 : !llvm.ptr -> i8
    %330 = llvm.icmp "ne" %329, %13 : i8
    llvm.cond_br %330, ^bb42, ^bb43
  ^bb42:  // pred: ^bb41
    %331 = llvm.getelementptr %27[8] : (!llvm.ptr) -> !llvm.ptr, bf16
    %332 = llvm.getelementptr %48[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %333 = llvm.load %331 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %333, %332 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb43
  ^bb43:  // 2 preds: ^bb41, ^bb42
    %334 = llvm.getelementptr %324[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %335 = llvm.load %334 : !llvm.ptr -> i8
    %336 = llvm.icmp "ne" %335, %13 : i8
    llvm.cond_br %336, ^bb44, ^bb45
  ^bb44:  // pred: ^bb43
    %337 = llvm.getelementptr %27[16] : (!llvm.ptr) -> !llvm.ptr, bf16
    %338 = llvm.getelementptr %48[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %339 = llvm.load %337 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %339, %338 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb45
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %340 = llvm.getelementptr %324[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %341 = llvm.load %340 : !llvm.ptr -> i8
    %342 = llvm.icmp "ne" %341, %13 : i8
    llvm.cond_br %342, ^bb46, ^bb47
  ^bb46:  // pred: ^bb45
    %343 = llvm.getelementptr %27[24] : (!llvm.ptr) -> !llvm.ptr, bf16
    %344 = llvm.getelementptr %48[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %345 = llvm.load %343 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %345, %344 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb47
  ^bb47:  // 2 preds: ^bb45, ^bb46
    %346 = llvm.getelementptr %324[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %347 = llvm.load %346 : !llvm.ptr -> i8
    %348 = llvm.icmp "ne" %347, %13 : i8
    llvm.cond_br %348, ^bb48, ^bb49
  ^bb48:  // pred: ^bb47
    %349 = llvm.getelementptr %27[32] : (!llvm.ptr) -> !llvm.ptr, bf16
    %350 = llvm.getelementptr %48[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %351 = llvm.load %349 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %351, %350 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb49
  ^bb49:  // 2 preds: ^bb47, ^bb48
    %352 = llvm.getelementptr %324[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %353 = llvm.load %352 : !llvm.ptr -> i8
    %354 = llvm.icmp "ne" %353, %13 : i8
    llvm.cond_br %354, ^bb50, ^bb51
  ^bb50:  // pred: ^bb49
    %355 = llvm.getelementptr %27[40] : (!llvm.ptr) -> !llvm.ptr, bf16
    %356 = llvm.getelementptr %48[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %357 = llvm.load %355 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %357, %356 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb51
  ^bb51:  // 2 preds: ^bb49, ^bb50
    %358 = llvm.getelementptr %324[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %359 = llvm.load %358 : !llvm.ptr -> i8
    %360 = llvm.icmp "ne" %359, %13 : i8
    llvm.cond_br %360, ^bb52, ^bb53
  ^bb52:  // pred: ^bb51
    %361 = llvm.getelementptr %27[48] : (!llvm.ptr) -> !llvm.ptr, bf16
    %362 = llvm.getelementptr %48[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %363 = llvm.load %361 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %363, %362 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb53
  ^bb53:  // 2 preds: ^bb51, ^bb52
    %364 = llvm.getelementptr %324[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %365 = llvm.load %364 : !llvm.ptr -> i8
    %366 = llvm.icmp "ne" %365, %13 : i8
    llvm.cond_br %366, ^bb54, ^bb55
  ^bb54:  // pred: ^bb53
    %367 = llvm.getelementptr %27[56] : (!llvm.ptr) -> !llvm.ptr, bf16
    %368 = llvm.getelementptr %48[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %369 = llvm.load %367 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %369, %368 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb55
  ^bb55:  // 2 preds: ^bb53, ^bb54
    %370 = llvm.add %322, %23 : i32
    llvm.br ^bb38(%370 : i32)
  ^bb56:  // pred: ^bb38
    llvm.br ^bb57
  ^bb57:  // 2 preds: ^bb36, ^bb56
    llvm.return
  }
}
