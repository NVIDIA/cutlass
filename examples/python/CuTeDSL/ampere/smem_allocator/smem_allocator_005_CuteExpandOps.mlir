!memref_gmem_f32_ = !cute.memref<f32, gmem, "(8,4):(4,1)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(8,2):(2,1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(16,2):(2,1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<32>, "(16,2):(1,16)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<128>, "(8,4):(1,8)">
!memref_smem_f32_2 = !cute.memref<f32, smem, align<128>, "(8,2):(1,8)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}], function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> (), sym_name = "kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_1, %arg5: !memref_gmem_f32_2):
      %23 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %24 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %25 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %26 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %27 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %28 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %29 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %30 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %31 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %32 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %33 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %34 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %35 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %36 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
      %37 = "cute.make_tile"() : () -> !cute.tile<"8:1">
      %38 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
      %39 = "cute.get_leaves"(%38) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %40 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
      %41 = "cute.add_offset"(%35, %40) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %42 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %43 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %44 = "arith.cmpi"(%42, %43) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %45 = "cute.recast_iter"(%35) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<i32, smem, align<1024>>
      %46 = "cute.ptrtoint"(%41) : (!cute.ptr<i8, smem, align<4>>) -> i32
      %47 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %48 = "arith.addi"(%46, %47) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %49 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %50 = "arith.subi"(%48, %49) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %51 = "arith.constant"() <{value = -128 : i32}> : () -> i32
      %52 = "arith.andi"(%50, %51) : (i32, i32) -> i32
      %53 = "arith.extsi"(%52) : (i32) -> i64
      %54 = "cute.assume"(%53) : (i64) -> !cute.i64<divby 128>
      %55 = "cute.inttoptr"(%54) : (!cute.i64<divby 128>) -> !cute.ptr<i8, smem, align<128>>
      %56 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"512">
      %57 = "cute.add_offset"(%55, %56) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<128>>
      %58 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %59 = "arith.constant"() <{value = 640 : i32}> : () -> i32
      %60 = "arith.cmpi"(%58, %59) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %61 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"0">
      %62 = "cute.add_offset"(%55, %61) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<128>>
      %63 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"128">
      %64 = "cute.add_offset"(%55, %63) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %65 = "cute.recast_iter"(%64) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<i64, smem, align<128>>
      %66 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"136">
      %67 = "cute.add_offset"(%55, %66) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %68 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"0">
      %69 = "cute.add_offset"(%67, %68) : (!cute.ptr<i8, smem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<8>>
      %70 = "cute.recast_iter"(%69) : (!cute.ptr<i8, smem, align<8>>) -> !cute.ptr<f32, smem, align<8>>
      %71 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
      %72 = "cute.add_offset"(%67, %71) : (!cute.ptr<i8, smem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %73 = "cute.recast_iter"(%72) : (!cute.ptr<i8, smem, align<4>>) -> !cute.ptr<f32, smem>
      %74 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"256">
      %75 = "cute.add_offset"(%55, %74) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"256">) -> !cute.ptr<i8, smem, align<128>>
      %76 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"384">
      %77 = "cute.add_offset"(%55, %76) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"384">) -> !cute.ptr<i8, smem, align<128>>
      %78 = "cute.recast_iter"(%77) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<i32, smem, align<128>>
      %79 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"400">
      %80 = "cute.add_offset"(%55, %79) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"400">) -> !cute.ptr<i8, smem, align<16>>
      %81 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"0">
      %82 = "cute.add_offset"(%80, %81) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<16>>
      %83 = "cute.recast_iter"(%82) : (!cute.ptr<i8, smem, align<16>>) -> !cute.ptr<f32, smem, align<16>>
      %84 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
      %85 = "cute.add_offset"(%80, %84) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %86 = "cute.recast_iter"(%85) : (!cute.ptr<i8, smem, align<4>>) -> !cute.ptr<f32, smem>
      %87 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"64">
      %88 = "cute.add_offset"(%57, %87) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %89 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %90 = "arith.constant"() <{value = 704 : i32}> : () -> i32
      %91 = "arith.cmpi"(%89, %90) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %92 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"112">
      %93 = "cute.add_offset"(%88, %92) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %94 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %95 = "arith.constant"() <{value = 816 : i32}> : () -> i32
      %96 = "arith.cmpi"(%94, %95) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %97 = "cute.recast_iter"(%88) : (!cute.ptr<i8, smem, align<64>>) -> !cute.ptr<i64, smem, align<64>>
      %98 = "cute.make_shape"() : () -> !cute.shape<"(16,2)">
      %99 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(16,2):(1,16)">
      %100 = "cute.make_coord"() : () -> !cute.coord<"0">
      %101 = "cute.crd2idx"(%100, %99) : (!cute.coord<"0">, !cute.layout<"(16,2):(1,16)">) -> !cute.int_tuple<"0">
      %102 = "cute.get_leaves"(%101) : (!cute.int_tuple<"0">) -> !cute.int_tuple<"0">
      %103 = "cute.cosize"(%99) <{mode = array<i32>}> : (!cute.layout<"(16,2):(1,16)">) -> !cute.int_tuple<"32">
      %104 = "cute.get_leaves"(%103) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %105 = "cute.ptrtoint"(%93) : (!cute.ptr<i8, smem, align<16>>) -> i32
      %106 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %107 = "arith.addi"(%105, %106) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %108 = "arith.subi"(%107, %49) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %109 = "arith.constant"() <{value = -32 : i32}> : () -> i32
      %110 = "arith.andi"(%108, %109) : (i32, i32) -> i32
      %111 = "arith.extsi"(%110) : (i32) -> i64
      %112 = "cute.assume"(%111) : (i64) -> !cute.i64<divby 32>
      %113 = "cute.inttoptr"(%112) : (!cute.i64<divby 32>) -> !cute.ptr<i8, smem, align<32>>
      %114 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"128">
      %115 = "cute.add_offset"(%113, %114) : (!cute.ptr<i8, smem, align<32>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<32>>
      %116 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %117 = "arith.constant"() <{value = 960 : i32}> : () -> i32
      %118 = "arith.cmpi"(%116, %117) <{predicate = 5 : i64}> : (i32, i32) -> i1
      %119 = "cute.recast_iter"(%113) : (!cute.ptr<i8, smem, align<32>>) -> !cute.ptr<f32, smem, align<32>>
      %120 = "cute.make_view"(%119, %99) : (!cute.ptr<f32, smem, align<32>>, !cute.layout<"(16,2):(1,16)">) -> !memref_smem_f32_
      %121 = "cute.get_iter"(%120) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<32>>
      %122 = "cute.recast_iter"(%62) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %123 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %124 = "cute.make_shape"() : () -> !cute.shape<"(8,4)">
      %125 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,4):(1,8)">
      %126 = "cute.recast_iter"(%62) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %127 = "cute.make_view"(%126, %125) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,4):(1,8)">) -> !memref_smem_f32_1
      %128 = "cute.get_iter"(%127) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<128>>
      %129 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %130 = "cute.size"(%129) <{mode = array<i32>}> : (!cute.layout<"(8,4):(1,8)">) -> !cute.int_tuple<"32">
      %131 = "cute.get_leaves"(%130) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %132 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %133 = "cute.get_shape"(%132) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %134:2 = "cute.get_leaves"(%133) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %135 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %136 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
      %137 = "cute.get_leaves"(%136) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %138 = "arith.constant"() <{value = 5.000000e-01 : f32}> : () -> f32
      %139 = "vector.splat"(%138) : (f32) -> vector<32xf32>
      %140 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %141 = "cute.get_shape"(%140) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %142:2 = "cute.get_leaves"(%141) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %143 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %144 = "cute.get_shape"(%143) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %145:2 = "cute.get_leaves"(%144) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %146 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %147 = "cute.size"(%146) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %148 = "cute.get_leaves"(%147) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %149 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %150 = "cute.size"(%149) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %151 = "cute.get_leaves"(%150) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%139, %127) : (vector<32xf32>, !memref_smem_f32_1) -> ()
      %152 = "cute.get_iter"(%127) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<128>>
      %153 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %154 = "builtin.unrealized_conversion_cast"(%152) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %155 = "llvm.ptrtoint"(%154) : (!llvm.ptr<3>) -> i64
      %156 = "cute.memref.load_vec"(%127) : (!memref_smem_f32_1) -> vector<32xf32>
      %157 = "vector.extract"(%156) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %158 = "vector.extract"(%156) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %159 = "vector.extract"(%156) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %160 = "vector.extract"(%156) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %161 = "vector.extract"(%156) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %162 = "vector.extract"(%156) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %163 = "vector.extract"(%156) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %164 = "vector.extract"(%156) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %165 = "vector.extract"(%156) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %166 = "vector.extract"(%156) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %167 = "vector.extract"(%156) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %168 = "vector.extract"(%156) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %169 = "vector.extract"(%156) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %170 = "vector.extract"(%156) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %171 = "vector.extract"(%156) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %172 = "vector.extract"(%156) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %173 = "vector.extract"(%156) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %174 = "vector.extract"(%156) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %175 = "vector.extract"(%156) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %176 = "vector.extract"(%156) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %177 = "vector.extract"(%156) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %178 = "vector.extract"(%156) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %179 = "vector.extract"(%156) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %180 = "vector.extract"(%156) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %181 = "vector.extract"(%156) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %182 = "vector.extract"(%156) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %183 = "vector.extract"(%156) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %184 = "vector.extract"(%156) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %185 = "vector.extract"(%156) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %186 = "vector.extract"(%156) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %187 = "vector.extract"(%156) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%155, %157, %158, %159, %160, %161, %162, %163, %164, %165, %166, %167, %168, %169, %170, %171, %172, %173, %174, %175, %176, %177, %178, %179, %180, %181, %182, %183, %184, %185, %186, %187) <{format = "cute.struct.MemRange: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,4):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %188 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %189 = "cute.get_shape"(%188) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %190:2 = "cute.get_leaves"(%189) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %191 = "cute.memref.load_vec"(%127) : (!memref_smem_f32_1) -> vector<32xf32>
      %192 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %193 = "cute.get_shape"(%192) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %194:2 = "cute.get_leaves"(%193) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %195 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %196 = "cute.get_shape"(%195) : (!cute.layout<"(8,4):(4,1)">) -> !cute.shape<"(8,4)">
      %197:2 = "cute.get_leaves"(%196) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %198 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %199 = "cute.get_shape"(%198) : (!cute.layout<"(8,4):(4,1)">) -> !cute.shape<"(8,4)">
      %200:2 = "cute.get_leaves"(%199) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %201 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %202 = "cute.size"(%201) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %203 = "cute.get_leaves"(%202) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %204 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %205 = "cute.size"(%204) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %206 = "cute.get_leaves"(%205) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%191, %arg3) : (vector<32xf32>, !memref_gmem_f32_) -> ()
      %207 = "cute.make_shape"() : () -> !cute.shape<"(8,2)">
      %208 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,2):(1,8)">
      %209 = "cute.recast_iter"(%57) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %210 = "cute.make_view"(%209, %208) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,2):(1,8)">) -> !memref_smem_f32_2
      %211 = "cute.get_iter"(%210) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<128>>
      %212 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %213 = "cute.size"(%212) <{mode = array<i32>}> : (!cute.layout<"(8,2):(1,8)">) -> !cute.int_tuple<"16">
      %214 = "cute.get_leaves"(%213) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %215 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %216 = "cute.get_shape"(%215) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %217:2 = "cute.get_leaves"(%216) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %218 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %219 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"16">
      %220 = "cute.get_leaves"(%219) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %221 = "arith.constant"() <{value = 1.000000e+00 : f32}> : () -> f32
      %222 = "vector.splat"(%221) : (f32) -> vector<16xf32>
      %223 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %224 = "cute.get_shape"(%223) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %225:2 = "cute.get_leaves"(%224) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %226 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %227 = "cute.get_shape"(%226) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %228:2 = "cute.get_leaves"(%227) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %229 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %230 = "cute.size"(%229) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %231 = "cute.get_leaves"(%230) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %232 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %233 = "cute.size"(%232) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %234 = "cute.get_leaves"(%233) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%222, %210) : (vector<16xf32>, !memref_smem_f32_2) -> ()
      %235 = "cute.get_iter"(%210) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<128>>
      %236 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %237 = "builtin.unrealized_conversion_cast"(%235) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %238 = "llvm.ptrtoint"(%237) : (!llvm.ptr<3>) -> i64
      %239 = "cute.memref.load_vec"(%210) : (!memref_smem_f32_2) -> vector<16xf32>
      %240 = "vector.extract"(%239) <{static_position = array<i64: 0>}> : (vector<16xf32>) -> f32
      %241 = "vector.extract"(%239) <{static_position = array<i64: 1>}> : (vector<16xf32>) -> f32
      %242 = "vector.extract"(%239) <{static_position = array<i64: 2>}> : (vector<16xf32>) -> f32
      %243 = "vector.extract"(%239) <{static_position = array<i64: 3>}> : (vector<16xf32>) -> f32
      %244 = "vector.extract"(%239) <{static_position = array<i64: 4>}> : (vector<16xf32>) -> f32
      %245 = "vector.extract"(%239) <{static_position = array<i64: 5>}> : (vector<16xf32>) -> f32
      %246 = "vector.extract"(%239) <{static_position = array<i64: 6>}> : (vector<16xf32>) -> f32
      %247 = "vector.extract"(%239) <{static_position = array<i64: 7>}> : (vector<16xf32>) -> f32
      %248 = "vector.extract"(%239) <{static_position = array<i64: 8>}> : (vector<16xf32>) -> f32
      %249 = "vector.extract"(%239) <{static_position = array<i64: 9>}> : (vector<16xf32>) -> f32
      %250 = "vector.extract"(%239) <{static_position = array<i64: 10>}> : (vector<16xf32>) -> f32
      %251 = "vector.extract"(%239) <{static_position = array<i64: 11>}> : (vector<16xf32>) -> f32
      %252 = "vector.extract"(%239) <{static_position = array<i64: 12>}> : (vector<16xf32>) -> f32
      %253 = "vector.extract"(%239) <{static_position = array<i64: 13>}> : (vector<16xf32>) -> f32
      %254 = "vector.extract"(%239) <{static_position = array<i64: 14>}> : (vector<16xf32>) -> f32
      %255 = "vector.extract"(%239) <{static_position = array<i64: 15>}> : (vector<16xf32>) -> f32
      "gpu.printf"(%238, %240, %241, %242, %243, %244, %245, %246, %247, %248, %249, %250, %251, %252, %253, %254, %255) <{format = "block of memory: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,2):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %256 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %257 = "cute.get_shape"(%256) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %258:2 = "cute.get_leaves"(%257) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %259 = "cute.memref.load_vec"(%210) : (!memref_smem_f32_2) -> vector<16xf32>
      %260 = "cute.get_layout"(%210) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %261 = "cute.get_shape"(%260) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %262:2 = "cute.get_leaves"(%261) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %263 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %264 = "cute.get_shape"(%263) : (!cute.layout<"(8,2):(2,1)">) -> !cute.shape<"(8,2)">
      %265:2 = "cute.get_leaves"(%264) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %266 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %267 = "cute.get_shape"(%266) : (!cute.layout<"(8,2):(2,1)">) -> !cute.shape<"(8,2)">
      %268:2 = "cute.get_leaves"(%267) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %269 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %270 = "cute.size"(%269) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %271 = "cute.get_leaves"(%270) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %272 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %273 = "cute.size"(%272) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %274 = "cute.get_leaves"(%273) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%259, %arg4) : (vector<16xf32>, !memref_gmem_f32_1) -> ()
      %275 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %276 = "cute.size"(%275) <{mode = array<i32>}> : (!cute.layout<"(16,2):(1,16)">) -> !cute.int_tuple<"32">
      %277 = "cute.get_leaves"(%276) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %278 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %279 = "cute.get_shape"(%278) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %280:2 = "cute.get_leaves"(%279) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %281 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %282 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
      %283 = "cute.get_leaves"(%282) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %284 = "arith.constant"() <{value = 2.000000e+00 : f32}> : () -> f32
      %285 = "vector.splat"(%284) : (f32) -> vector<32xf32>
      %286 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %287 = "cute.get_shape"(%286) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %288:2 = "cute.get_leaves"(%287) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %289 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %290 = "cute.get_shape"(%289) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %291:2 = "cute.get_leaves"(%290) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %292 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %293 = "cute.size"(%292) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %294 = "cute.get_leaves"(%293) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %295 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %296 = "cute.size"(%295) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %297 = "cute.get_leaves"(%296) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%285, %120) : (vector<32xf32>, !memref_smem_f32_) -> ()
      %298 = "cute.get_iter"(%120) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<32>>
      %299 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %300 = "builtin.unrealized_conversion_cast"(%298) : (!cute.ptr<f32, smem, align<32>>) -> !llvm.ptr<3>
      %301 = "llvm.ptrtoint"(%300) : (!llvm.ptr<3>) -> i64
      %302 = "cute.memref.load_vec"(%120) : (!memref_smem_f32_) -> vector<32xf32>
      %303 = "vector.extract"(%302) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %304 = "vector.extract"(%302) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %305 = "vector.extract"(%302) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %306 = "vector.extract"(%302) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %307 = "vector.extract"(%302) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %308 = "vector.extract"(%302) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %309 = "vector.extract"(%302) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %310 = "vector.extract"(%302) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %311 = "vector.extract"(%302) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %312 = "vector.extract"(%302) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %313 = "vector.extract"(%302) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %314 = "vector.extract"(%302) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %315 = "vector.extract"(%302) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %316 = "vector.extract"(%302) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %317 = "vector.extract"(%302) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %318 = "vector.extract"(%302) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %319 = "vector.extract"(%302) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %320 = "vector.extract"(%302) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %321 = "vector.extract"(%302) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %322 = "vector.extract"(%302) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %323 = "vector.extract"(%302) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %324 = "vector.extract"(%302) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %325 = "vector.extract"(%302) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %326 = "vector.extract"(%302) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %327 = "vector.extract"(%302) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %328 = "vector.extract"(%302) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %329 = "vector.extract"(%302) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %330 = "vector.extract"(%302) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %331 = "vector.extract"(%302) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %332 = "vector.extract"(%302) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %333 = "vector.extract"(%302) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%301, %303, %304, %305, %306, %307, %308, %309, %310, %311, %312, %313, %314, %315, %316, %317, %318, %319, %320, %321, %322, %323, %324, %325, %326, %327, %328, %329, %330, %331, %332, %333) <{format = "tensor in smem: raw_ptr(0x%016llx: f32, smem, align<32>) o (16,2):(1,16) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %334 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %335 = "cute.get_shape"(%334) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %336:2 = "cute.get_leaves"(%335) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %337 = "cute.memref.load_vec"(%120) : (!memref_smem_f32_) -> vector<32xf32>
      %338 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %339 = "cute.get_shape"(%338) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %340:2 = "cute.get_leaves"(%339) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %341 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %342 = "cute.get_shape"(%341) : (!cute.layout<"(16,2):(2,1)">) -> !cute.shape<"(16,2)">
      %343:2 = "cute.get_leaves"(%342) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %344 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %345 = "cute.get_shape"(%344) : (!cute.layout<"(16,2):(2,1)">) -> !cute.shape<"(16,2)">
      %346:2 = "cute.get_leaves"(%345) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %347 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %348 = "cute.size"(%347) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %349 = "cute.get_leaves"(%348) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %350 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %351 = "cute.size"(%350) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %352 = "cute.get_leaves"(%351) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%337, %arg5) : (vector<32xf32>, !memref_gmem_f32_2) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> i32, sym_name = "cutlass_host_05_Tensorgmemo8441_10_Tensorgmemo8221_20_Tensorgmemo16221"}> ({
  ^bb0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %2 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %4 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %5 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
    %6 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
    %7 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
    %8 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
    %9 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
    %10 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
    %11 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
    %12 = "arith.constant"() <{value = 960 : i32}> : () -> i32
    %13 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %14 = "cuda.cast"(%13) : (i64) -> !cuda.stream
    %15 = "arith.extsi"(%12) : (i32) -> i64
    %16 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %17 = "cuda.launch_cfg.create"(%16, %16, %16, %15, %16, %16, %16, %14) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %18 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%17, %18) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %19 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%17, %19) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %20 = "cuda.launch_ex"(%17, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %21 = "cuda.cast"(%20) : (!cuda.result) -> i32
    "cuda.return_if_error"(%21) : (i32) -> ()
    %22 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%22) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
