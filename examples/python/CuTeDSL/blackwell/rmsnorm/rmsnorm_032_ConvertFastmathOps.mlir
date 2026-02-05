gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} {
  llvm.mlir.global external @__dynamic_shmem__0() {addr_space = 3 : i32, alignment = 1024 : i64, dso_local} : !llvm.array<0 x i8>
  llvm.func @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
    %0 = llvm.mlir.undef : vector<64xf32>
    %1 = llvm.mlir.constant(3584 : i32) : i32
    %2 = llvm.mlir.constant(3072 : i32) : i32
    %3 = llvm.mlir.constant(2560 : i32) : i32
    %4 = llvm.mlir.constant(2048 : i32) : i32
    %5 = llvm.mlir.constant(1536 : i32) : i32
    %6 = llvm.mlir.constant(1024 : i32) : i32
    %7 = llvm.mlir.constant(512 : i32) : i32
    %8 = llvm.mlir.constant(8192 : i32) : i32
    %9 = llvm.mlir.constant(false) : i1
    %10 = llvm.mlir.addressof @__dynamic_shmem__0 : !llvm.ptr<3>
    %11 = llvm.mlir.constant(2 : i32) : i32
    %12 = llvm.mlir.constant(4096 : i32) : i32
    %13 = llvm.mlir.constant(0 : i32) : i32
    %14 = llvm.mlir.constant(0 : i8) : i8
    %15 = llvm.mlir.constant(0.000000e+00 : f32) : f32
    %16 = llvm.mlir.constant(-1 : i32) : i32
    %17 = llvm.mlir.constant(16 : i32) : i32
    %18 = llvm.mlir.constant(31 : i32) : i32
    %19 = llvm.mlir.constant(4 : i32) : i32
    %20 = llvm.mlir.constant(32 : i32) : i32
    %21 = llvm.mlir.constant(4.096000e+03 : f32) : f32
    %22 = llvm.mlir.constant(64 : i32) : i32
    %23 = llvm.mlir.constant(8 : i32) : i32
    %24 = llvm.mlir.constant(1 : i32) : i32
    %25 = llvm.alloca %23 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %26 = llvm.alloca %23 x i8 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %27 = llvm.alloca %22 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %28 = llvm.alloca %22 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %29 = llvm.alloca %22 x i16 {alignment = 32 : i64} : (i32) -> !llvm.ptr
    %30 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)> 
    %31 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
    %32 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %33 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %34 = llvm.extractvalue %33[0] : !llvm.struct<(i32, struct<()>)> 
    %35 = llvm.getelementptr %10[16384] : (!llvm.ptr<3>) -> !llvm.ptr<3>, i8
    %36 = llvm.mul %32, %8 : i32
    %37 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %38 = llvm.getelementptr %37[%36] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
    %39 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
    %40 = llvm.getelementptr %39[%36] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
    %41 = llvm.mul %32, %11 : i32
    %42 = llvm.sdiv %31, %22 : i32
    %43 = llvm.srem %31, %22 : i32
    %44 = llvm.mul %43, %23 : i32
    %45 = llvm.mul %42, %12 : i32
    %46 = llvm.add %44, %45 : i32
    %47 = llvm.getelementptr %38[%46] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
    %48 = llvm.getelementptr %10[%46] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
    %49 = llvm.getelementptr %40[%46] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
    %50 = llvm.add %41, %42 : i32
    %51 = llvm.getelementptr %30[%44] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, bf16
    %52 = llvm.icmp "slt" %44, %12 : i32
    %53 = llvm.zext %52 : i1 to i8
    %54 = llvm.ptrtoint %26 : !llvm.ptr to i64
    %55 = llvm.inttoptr %54 : i64 to !llvm.ptr
    llvm.store %53, %55 {alignment = 32 : i64} : i8, !llvm.ptr
    %56 = llvm.add %44, %7 : i32
    %57 = llvm.icmp "slt" %56, %12 : i32
    %58 = llvm.zext %57 : i1 to i8
    %59 = llvm.getelementptr %26[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %60 = llvm.ptrtoint %59 : !llvm.ptr to i64
    %61 = llvm.inttoptr %60 : i64 to !llvm.ptr
    llvm.store %58, %61 {alignment = 1 : i64} : i8, !llvm.ptr
    %62 = llvm.add %44, %6 : i32
    %63 = llvm.icmp "slt" %62, %12 : i32
    %64 = llvm.zext %63 : i1 to i8
    %65 = llvm.getelementptr %26[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %66 = llvm.ptrtoint %65 : !llvm.ptr to i64
    %67 = llvm.inttoptr %66 : i64 to !llvm.ptr
    llvm.store %64, %67 {alignment = 2 : i64} : i8, !llvm.ptr
    %68 = llvm.add %44, %5 : i32
    %69 = llvm.icmp "slt" %68, %12 : i32
    %70 = llvm.zext %69 : i1 to i8
    %71 = llvm.getelementptr %26[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %72 = llvm.ptrtoint %71 : !llvm.ptr to i64
    %73 = llvm.inttoptr %72 : i64 to !llvm.ptr
    llvm.store %70, %73 {alignment = 1 : i64} : i8, !llvm.ptr
    %74 = llvm.add %44, %4 : i32
    %75 = llvm.icmp "slt" %74, %12 : i32
    %76 = llvm.zext %75 : i1 to i8
    %77 = llvm.getelementptr %26[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %78 = llvm.ptrtoint %77 : !llvm.ptr to i64
    %79 = llvm.inttoptr %78 : i64 to !llvm.ptr
    llvm.store %76, %79 {alignment = 4 : i64} : i8, !llvm.ptr
    %80 = llvm.add %44, %3 : i32
    %81 = llvm.icmp "slt" %80, %12 : i32
    %82 = llvm.zext %81 : i1 to i8
    %83 = llvm.getelementptr %26[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %84 = llvm.ptrtoint %83 : !llvm.ptr to i64
    %85 = llvm.inttoptr %84 : i64 to !llvm.ptr
    llvm.store %82, %85 {alignment = 1 : i64} : i8, !llvm.ptr
    %86 = llvm.add %44, %2 : i32
    %87 = llvm.icmp "slt" %86, %12 : i32
    %88 = llvm.zext %87 : i1 to i8
    %89 = llvm.getelementptr %26[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %90 = llvm.ptrtoint %89 : !llvm.ptr to i64
    %91 = llvm.inttoptr %90 : i64 to !llvm.ptr
    llvm.store %88, %91 {alignment = 2 : i64} : i8, !llvm.ptr
    %92 = llvm.add %44, %1 : i32
    %93 = llvm.icmp "slt" %92, %12 : i32
    %94 = llvm.zext %93 : i1 to i8
    %95 = llvm.getelementptr %26[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %96 = llvm.ptrtoint %95 : !llvm.ptr to i64
    %97 = llvm.inttoptr %96 : i64 to !llvm.ptr
    llvm.store %94, %97 {alignment = 1 : i64} : i8, !llvm.ptr
    %98 = llvm.icmp "slt" %50, %34 : i32
    llvm.cond_br %98, ^bb1, ^bb5
  ^bb1:  // pred: ^bb0
    %99 = llvm.getelementptr %47[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %100 = llvm.getelementptr %48[512] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %101 = llvm.getelementptr %47[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %102 = llvm.getelementptr %48[1024] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %103 = llvm.getelementptr %47[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %104 = llvm.getelementptr %48[1536] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %105 = llvm.getelementptr %47[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %106 = llvm.getelementptr %48[2048] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %107 = llvm.getelementptr %47[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %108 = llvm.getelementptr %48[2560] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %109 = llvm.getelementptr %47[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %110 = llvm.getelementptr %48[3072] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    %111 = llvm.getelementptr %47[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %112 = llvm.getelementptr %48[3584] : (!llvm.ptr<3>) -> !llvm.ptr<3>, bf16
    llvm.br ^bb2(%13 : i32)
  ^bb2(%113: i32):  // 2 preds: ^bb1, ^bb3
    %114 = llvm.icmp "slt" %113, %24 : i32
    llvm.cond_br %114, ^bb3, ^bb4 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb3:  // pred: ^bb2
    %115 = llvm.getelementptr %26[%113] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %116 = llvm.load %115 : !llvm.ptr -> i8
    %117 = llvm.trunc %116 : i8 to i1
    %118 = llvm.select %117, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %48, %47, %17, %118 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %119 = llvm.getelementptr %115[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %120 = llvm.load %119 : !llvm.ptr -> i8
    %121 = llvm.trunc %120 : i8 to i1
    %122 = llvm.select %121, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %100, %99, %17, %122 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %123 = llvm.getelementptr %115[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %124 = llvm.load %123 : !llvm.ptr -> i8
    %125 = llvm.trunc %124 : i8 to i1
    %126 = llvm.select %125, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %102, %101, %17, %126 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %127 = llvm.getelementptr %115[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %128 = llvm.load %127 : !llvm.ptr -> i8
    %129 = llvm.trunc %128 : i8 to i1
    %130 = llvm.select %129, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %104, %103, %17, %130 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %131 = llvm.getelementptr %115[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %132 = llvm.load %131 : !llvm.ptr -> i8
    %133 = llvm.trunc %132 : i8 to i1
    %134 = llvm.select %133, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %106, %105, %17, %134 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %135 = llvm.getelementptr %115[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %136 = llvm.load %135 : !llvm.ptr -> i8
    %137 = llvm.trunc %136 : i8 to i1
    %138 = llvm.select %137, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %108, %107, %17, %138 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %139 = llvm.getelementptr %115[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %140 = llvm.load %139 : !llvm.ptr -> i8
    %141 = llvm.trunc %140 : i8 to i1
    %142 = llvm.select %141, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %110, %109, %17, %142 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %143 = llvm.getelementptr %115[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %144 = llvm.load %143 : !llvm.ptr -> i8
    %145 = llvm.trunc %144 : i8 to i1
    %146 = llvm.select %145, %17, %13 : i1, i32
    llvm.inline_asm has_side_effects asm_dialect = att "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", "r,l,n,r" %112, %111, %17, %146 : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %147 = llvm.add %113, %24 : i32
    llvm.br ^bb2(%147 : i32)
  ^bb4:  // pred: ^bb2
    llvm.br ^bb5
  ^bb5:  // 2 preds: ^bb0, ^bb4
    nvvm.cp.async.commit.group
    %148 = llvm.ptrtoint %25 : !llvm.ptr to i64
    %149 = llvm.inttoptr %148 : i64 to !llvm.ptr
    llvm.store %53, %149 {alignment = 32 : i64} : i8, !llvm.ptr
    %150 = llvm.getelementptr %25[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %151 = llvm.ptrtoint %150 : !llvm.ptr to i64
    %152 = llvm.inttoptr %151 : i64 to !llvm.ptr
    llvm.store %58, %152 {alignment = 1 : i64} : i8, !llvm.ptr
    %153 = llvm.getelementptr %25[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %154 = llvm.ptrtoint %153 : !llvm.ptr to i64
    %155 = llvm.inttoptr %154 : i64 to !llvm.ptr
    llvm.store %64, %155 {alignment = 2 : i64} : i8, !llvm.ptr
    %156 = llvm.getelementptr %25[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %157 = llvm.ptrtoint %156 : !llvm.ptr to i64
    %158 = llvm.inttoptr %157 : i64 to !llvm.ptr
    llvm.store %70, %158 {alignment = 1 : i64} : i8, !llvm.ptr
    %159 = llvm.getelementptr %25[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %160 = llvm.ptrtoint %159 : !llvm.ptr to i64
    %161 = llvm.inttoptr %160 : i64 to !llvm.ptr
    llvm.store %76, %161 {alignment = 4 : i64} : i8, !llvm.ptr
    %162 = llvm.getelementptr %25[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %163 = llvm.ptrtoint %162 : !llvm.ptr to i64
    %164 = llvm.inttoptr %163 : i64 to !llvm.ptr
    llvm.store %82, %164 {alignment = 1 : i64} : i8, !llvm.ptr
    %165 = llvm.getelementptr %25[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %166 = llvm.ptrtoint %165 : !llvm.ptr to i64
    %167 = llvm.inttoptr %166 : i64 to !llvm.ptr
    llvm.store %88, %167 {alignment = 2 : i64} : i8, !llvm.ptr
    %168 = llvm.getelementptr %25[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %169 = llvm.ptrtoint %168 : !llvm.ptr to i64
    %170 = llvm.inttoptr %169 : i64 to !llvm.ptr
    llvm.store %94, %170 {alignment = 1 : i64} : i8, !llvm.ptr
    llvm.br ^bb6(%13 : i32)
  ^bb6(%171: i32):  // 2 preds: ^bb5, ^bb23
    %172 = llvm.icmp "slt" %171, %24 : i32
    llvm.cond_br %172, ^bb7, ^bb24 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb7:  // pred: ^bb6
    %173 = llvm.getelementptr %25[%171] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %174 = llvm.load %173 : !llvm.ptr -> i8
    %175 = llvm.icmp "ne" %174, %14 : i8
    llvm.cond_br %175, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %176 = llvm.load %51 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %176, %27 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb9
  ^bb9:  // 2 preds: ^bb7, ^bb8
    %177 = llvm.getelementptr %173[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %178 = llvm.load %177 : !llvm.ptr -> i8
    %179 = llvm.icmp "ne" %178, %14 : i8
    llvm.cond_br %179, ^bb10, ^bb11
  ^bb10:  // pred: ^bb9
    %180 = llvm.getelementptr %51[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %181 = llvm.getelementptr %27[8] : (!llvm.ptr) -> !llvm.ptr, bf16
    %182 = llvm.load %180 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %182, %181 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb11
  ^bb11:  // 2 preds: ^bb9, ^bb10
    %183 = llvm.getelementptr %173[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %184 = llvm.load %183 : !llvm.ptr -> i8
    %185 = llvm.icmp "ne" %184, %14 : i8
    llvm.cond_br %185, ^bb12, ^bb13
  ^bb12:  // pred: ^bb11
    %186 = llvm.getelementptr %51[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %187 = llvm.getelementptr %27[16] : (!llvm.ptr) -> !llvm.ptr, bf16
    %188 = llvm.load %186 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %188, %187 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb13
  ^bb13:  // 2 preds: ^bb11, ^bb12
    %189 = llvm.getelementptr %173[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %190 = llvm.load %189 : !llvm.ptr -> i8
    %191 = llvm.icmp "ne" %190, %14 : i8
    llvm.cond_br %191, ^bb14, ^bb15
  ^bb14:  // pred: ^bb13
    %192 = llvm.getelementptr %51[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %193 = llvm.getelementptr %27[24] : (!llvm.ptr) -> !llvm.ptr, bf16
    %194 = llvm.load %192 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %194, %193 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb15
  ^bb15:  // 2 preds: ^bb13, ^bb14
    %195 = llvm.getelementptr %173[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %196 = llvm.load %195 : !llvm.ptr -> i8
    %197 = llvm.icmp "ne" %196, %14 : i8
    llvm.cond_br %197, ^bb16, ^bb17
  ^bb16:  // pred: ^bb15
    %198 = llvm.getelementptr %51[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %199 = llvm.getelementptr %27[32] : (!llvm.ptr) -> !llvm.ptr, bf16
    %200 = llvm.load %198 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %200, %199 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb17
  ^bb17:  // 2 preds: ^bb15, ^bb16
    %201 = llvm.getelementptr %173[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %202 = llvm.load %201 : !llvm.ptr -> i8
    %203 = llvm.icmp "ne" %202, %14 : i8
    llvm.cond_br %203, ^bb18, ^bb19
  ^bb18:  // pred: ^bb17
    %204 = llvm.getelementptr %51[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %205 = llvm.getelementptr %27[40] : (!llvm.ptr) -> !llvm.ptr, bf16
    %206 = llvm.load %204 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %206, %205 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb19
  ^bb19:  // 2 preds: ^bb17, ^bb18
    %207 = llvm.getelementptr %173[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %208 = llvm.load %207 : !llvm.ptr -> i8
    %209 = llvm.icmp "ne" %208, %14 : i8
    llvm.cond_br %209, ^bb20, ^bb21
  ^bb20:  // pred: ^bb19
    %210 = llvm.getelementptr %51[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %211 = llvm.getelementptr %27[48] : (!llvm.ptr) -> !llvm.ptr, bf16
    %212 = llvm.load %210 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %212, %211 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb21
  ^bb21:  // 2 preds: ^bb19, ^bb20
    %213 = llvm.getelementptr %173[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %214 = llvm.load %213 : !llvm.ptr -> i8
    %215 = llvm.icmp "ne" %214, %14 : i8
    llvm.cond_br %215, ^bb22, ^bb23
  ^bb22:  // pred: ^bb21
    %216 = llvm.getelementptr %51[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %217 = llvm.getelementptr %27[56] : (!llvm.ptr) -> !llvm.ptr, bf16
    %218 = llvm.load %216 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
    llvm.store %218, %217 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    llvm.br ^bb23
  ^bb23:  // 2 preds: ^bb21, ^bb22
    %219 = llvm.add %171, %24 : i32
    llvm.br ^bb6(%219 : i32)
  ^bb24:  // pred: ^bb6
    nvvm.cp.async.wait.group 0
    llvm.br ^bb25(%13 : i32)
  ^bb25(%220: i32):  // 2 preds: ^bb24, ^bb26
    %221 = llvm.icmp "slt" %220, %23 : i32
    llvm.cond_br %221, ^bb26, ^bb27 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb26:  // pred: ^bb25
    %222 = llvm.mul %220, %7 : i32
    %223 = llvm.getelementptr %48[%222] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
    %224 = llvm.mul %220, %23 : i32
    %225 = llvm.getelementptr %29[%224] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
    %226 = llvm.load %223 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
    llvm.store %226, %225 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    %227 = llvm.add %220, %24 : i32
    llvm.br ^bb25(%227 : i32)
  ^bb27:  // pred: ^bb25
    %228 = llvm.load %29 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %229 = llvm.fpext %228 : vector<64xbf16> to vector<64xf32>
    %230 = llvm.fmul %229, %229 : vector<64xf32>
    %231 = "llvm.intr.vector.reduce.fadd"(%15, %230) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
    %232 = nvvm.shfl.sync  bfly %16, %231, %17, %18 : f32 -> f32
    %233 = llvm.fadd %232, %231 : f32
    %234 = nvvm.shfl.sync  bfly %16, %233, %23, %18 : f32 -> f32
    %235 = llvm.fadd %233, %234 : f32
    %236 = nvvm.shfl.sync  bfly %16, %235, %19, %18 : f32 -> f32
    %237 = llvm.fadd %235, %236 : f32
    %238 = nvvm.shfl.sync  bfly %16, %237, %11, %18 : f32 -> f32
    %239 = llvm.fadd %237, %238 : f32
    %240 = nvvm.shfl.sync  bfly %16, %239, %24, %18 : f32 -> f32
    %241 = llvm.fadd %239, %240 : f32
    %242 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
    %243 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
    %244 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
    %245 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
    %246 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
    %247 = llvm.mul %243, %245 : i32
    %248 = llvm.add %31, %247 : i32
    %249 = llvm.mul %244, %245 : i32
    %250 = llvm.mul %249, %246 : i32
    %251 = llvm.add %248, %250 : i32
    %252 = llvm.sdiv %251, %20 : i32
    %253 = llvm.mul %252, %20 : i32
    %254 = llvm.icmp "ne" %251, %253 : i32
    %255 = llvm.icmp "slt" %251, %13 : i32
    %256 = llvm.icmp "ne" %255, %9 : i1
    %257 = llvm.and %254, %256 : i1
    %258 = llvm.add %252, %16 : i32
    %259 = llvm.select %257, %258, %252 : i1, i32
    %260 = llvm.sdiv %259, %11 : i32
    %261 = llvm.mul %260, %11 : i32
    %262 = llvm.icmp "ne" %259, %261 : i32
    %263 = llvm.icmp "slt" %259, %13 : i32
    %264 = llvm.icmp "ne" %263, %9 : i1
    %265 = llvm.and %262, %264 : i1
    %266 = llvm.add %260, %16 : i32
    %267 = llvm.select %265, %266, %260 : i1, i32
    %268 = llvm.srem %259, %11 : i32
    %269 = llvm.icmp "eq" %242, %13 : i32
    llvm.cond_br %269, ^bb28, ^bb29
  ^bb28:  // pred: ^bb27
    %270 = llvm.mul %268, %11 : i32
    %271 = llvm.add %267, %270 : i32
    %272 = llvm.getelementptr %35[%271] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
    %273 = llvm.ptrtoint %272 : !llvm.ptr<3> to i64
    %274 = llvm.inttoptr %273 : i64 to !llvm.ptr<3>
    llvm.store %241, %274 {alignment = 4 : i64} : f32, !llvm.ptr<3>
    llvm.br ^bb29
  ^bb29:  // 2 preds: ^bb27, ^bb28
    nvvm.barrier
    %275 = llvm.icmp "slt" %242, %11 : i32
    llvm.cond_br %275, ^bb30, ^bb31
  ^bb30:  // pred: ^bb29
    %276 = llvm.mul %242, %11 : i32
    %277 = llvm.add %267, %276 : i32
    %278 = llvm.getelementptr %35[%277] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, f32
    %279 = llvm.ptrtoint %278 : !llvm.ptr<3> to i64
    %280 = llvm.inttoptr %279 : i64 to !llvm.ptr<3>
    %281 = llvm.load %280 {alignment = 4 : i64} : !llvm.ptr<3> -> f32
    llvm.br ^bb32(%281 : f32)
  ^bb31:  // pred: ^bb29
    llvm.br ^bb32(%15 : f32)
  ^bb32(%282: f32):  // 2 preds: ^bb30, ^bb31
    llvm.br ^bb33
  ^bb33:  // pred: ^bb32
    %283 = nvvm.shfl.sync  bfly %16, %282, %17, %18 : f32 -> f32
    %284 = llvm.fadd %282, %283 : f32
    %285 = nvvm.shfl.sync  bfly %16, %284, %23, %18 : f32 -> f32
    %286 = llvm.fadd %284, %285 : f32
    %287 = nvvm.shfl.sync  bfly %16, %286, %19, %18 : f32 -> f32
    %288 = llvm.fadd %286, %287 : f32
    %289 = nvvm.shfl.sync  bfly %16, %288, %11, %18 : f32 -> f32
    %290 = llvm.fadd %288, %289 : f32
    %291 = nvvm.shfl.sync  bfly %16, %290, %24, %18 : f32 -> f32
    %292 = llvm.fadd %290, %291 : f32
    %293 = llvm.fdiv %292, %21 : f32
    %294 = llvm.fadd %293, %arg3 : f32
    %295 = math.rsqrt %294 fastmath<fast> : f32
    nvvm.barrier
    llvm.br ^bb34(%13 : i32)
  ^bb34(%296: i32):  // 2 preds: ^bb33, ^bb35
    %297 = llvm.icmp "slt" %296, %23 : i32
    llvm.cond_br %297, ^bb35, ^bb36 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb35:  // pred: ^bb34
    %298 = llvm.mul %296, %7 : i32
    %299 = llvm.getelementptr %48[%298] : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>, bf16
    %300 = llvm.mul %296, %23 : i32
    %301 = llvm.getelementptr %29[%300] : (!llvm.ptr, i32) -> !llvm.ptr, bf16
    %302 = llvm.load %299 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
    llvm.store %302, %301 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
    %303 = llvm.add %296, %24 : i32
    llvm.br ^bb34(%303 : i32)
  ^bb36:  // pred: ^bb34
    %304 = llvm.load %29 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %305 = llvm.fpext %304 : vector<64xbf16> to vector<64xf32>
    %306 = llvm.insertelement %295, %0[%13 : i32] : vector<64xf32>
    %307 = llvm.shufflevector %306, %0 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] : vector<64xf32> 
    %308 = llvm.fmul %305, %307 : vector<64xf32>
    %309 = llvm.load %27 {alignment = 32 : i64} : !llvm.ptr -> vector<64xbf16>
    %310 = llvm.fpext %309 : vector<64xbf16> to vector<64xf32>
    %311 = llvm.fmul %308, %310 : vector<64xf32>
    %312 = llvm.fptrunc %311 : vector<64xf32> to vector<64xbf16>
    llvm.store %312, %28 {alignment = 32 : i64} : vector<64xbf16>, !llvm.ptr
    llvm.cond_br %98, ^bb37, ^bb57
  ^bb37:  // pred: ^bb36
    llvm.br ^bb38(%13 : i32)
  ^bb38(%313: i32):  // 2 preds: ^bb37, ^bb55
    %314 = llvm.icmp "slt" %313, %24 : i32
    llvm.cond_br %314, ^bb39, ^bb56 {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>}
  ^bb39:  // pred: ^bb38
    %315 = llvm.getelementptr %26[%313] : (!llvm.ptr, i32) -> !llvm.ptr, i8
    %316 = llvm.load %315 : !llvm.ptr -> i8
    %317 = llvm.icmp "ne" %316, %14 : i8
    llvm.cond_br %317, ^bb40, ^bb41
  ^bb40:  // pred: ^bb39
    %318 = llvm.load %28 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %318, %49 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb41
  ^bb41:  // 2 preds: ^bb39, ^bb40
    %319 = llvm.getelementptr %315[1] : (!llvm.ptr) -> !llvm.ptr, i8
    %320 = llvm.load %319 : !llvm.ptr -> i8
    %321 = llvm.icmp "ne" %320, %14 : i8
    llvm.cond_br %321, ^bb42, ^bb43
  ^bb42:  // pred: ^bb41
    %322 = llvm.getelementptr %28[8] : (!llvm.ptr) -> !llvm.ptr, bf16
    %323 = llvm.getelementptr %49[512] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %324 = llvm.load %322 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %324, %323 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb43
  ^bb43:  // 2 preds: ^bb41, ^bb42
    %325 = llvm.getelementptr %315[2] : (!llvm.ptr) -> !llvm.ptr, i8
    %326 = llvm.load %325 : !llvm.ptr -> i8
    %327 = llvm.icmp "ne" %326, %14 : i8
    llvm.cond_br %327, ^bb44, ^bb45
  ^bb44:  // pred: ^bb43
    %328 = llvm.getelementptr %28[16] : (!llvm.ptr) -> !llvm.ptr, bf16
    %329 = llvm.getelementptr %49[1024] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %330 = llvm.load %328 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %330, %329 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb45
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %331 = llvm.getelementptr %315[3] : (!llvm.ptr) -> !llvm.ptr, i8
    %332 = llvm.load %331 : !llvm.ptr -> i8
    %333 = llvm.icmp "ne" %332, %14 : i8
    llvm.cond_br %333, ^bb46, ^bb47
  ^bb46:  // pred: ^bb45
    %334 = llvm.getelementptr %28[24] : (!llvm.ptr) -> !llvm.ptr, bf16
    %335 = llvm.getelementptr %49[1536] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %336 = llvm.load %334 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %336, %335 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb47
  ^bb47:  // 2 preds: ^bb45, ^bb46
    %337 = llvm.getelementptr %315[4] : (!llvm.ptr) -> !llvm.ptr, i8
    %338 = llvm.load %337 : !llvm.ptr -> i8
    %339 = llvm.icmp "ne" %338, %14 : i8
    llvm.cond_br %339, ^bb48, ^bb49
  ^bb48:  // pred: ^bb47
    %340 = llvm.getelementptr %28[32] : (!llvm.ptr) -> !llvm.ptr, bf16
    %341 = llvm.getelementptr %49[2048] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %342 = llvm.load %340 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %342, %341 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb49
  ^bb49:  // 2 preds: ^bb47, ^bb48
    %343 = llvm.getelementptr %315[5] : (!llvm.ptr) -> !llvm.ptr, i8
    %344 = llvm.load %343 : !llvm.ptr -> i8
    %345 = llvm.icmp "ne" %344, %14 : i8
    llvm.cond_br %345, ^bb50, ^bb51
  ^bb50:  // pred: ^bb49
    %346 = llvm.getelementptr %28[40] : (!llvm.ptr) -> !llvm.ptr, bf16
    %347 = llvm.getelementptr %49[2560] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %348 = llvm.load %346 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %348, %347 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb51
  ^bb51:  // 2 preds: ^bb49, ^bb50
    %349 = llvm.getelementptr %315[6] : (!llvm.ptr) -> !llvm.ptr, i8
    %350 = llvm.load %349 : !llvm.ptr -> i8
    %351 = llvm.icmp "ne" %350, %14 : i8
    llvm.cond_br %351, ^bb52, ^bb53
  ^bb52:  // pred: ^bb51
    %352 = llvm.getelementptr %28[48] : (!llvm.ptr) -> !llvm.ptr, bf16
    %353 = llvm.getelementptr %49[3072] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %354 = llvm.load %352 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %354, %353 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb53
  ^bb53:  // 2 preds: ^bb51, ^bb52
    %355 = llvm.getelementptr %315[7] : (!llvm.ptr) -> !llvm.ptr, i8
    %356 = llvm.load %355 : !llvm.ptr -> i8
    %357 = llvm.icmp "ne" %356, %14 : i8
    llvm.cond_br %357, ^bb54, ^bb55
  ^bb54:  // pred: ^bb53
    %358 = llvm.getelementptr %28[56] : (!llvm.ptr) -> !llvm.ptr, bf16
    %359 = llvm.getelementptr %49[3584] : (!llvm.ptr<1>) -> !llvm.ptr<1>, bf16
    %360 = llvm.load %358 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
    llvm.store %360, %359 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
    llvm.br ^bb55
  ^bb55:  // 2 preds: ^bb53, ^bb54
    %361 = llvm.add %313, %24 : i32
    llvm.br ^bb38(%361 : i32)
  ^bb56:  // pred: ^bb38
    llvm.br ^bb57
  ^bb57:  // 2 preds: ^bb36, ^bb56
    llvm.return
  }
}
