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
      "cf.assert"(%44) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 4 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
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
      "cf.assert"(%60) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 640 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
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
      "cf.assert"(%91) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 704 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
      %92 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"112">
      %93 = "cute.add_offset"(%88, %92) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %94 = "cute_nvgpu.arch.get_dyn_smem_size"() : () -> i32
      %95 = "arith.constant"() <{value = 816 : i32}> : () -> i32
      %96 = "arith.cmpi"(%94, %95) <{predicate = 5 : i64}> : (i32, i32) -> i1
      "cf.assert"(%96) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 816 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
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
      "cf.assert"(%118) <{msg = "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 960 bytes. Please reduce the allocation or set a larger smem size in kernel launch."}> : (i1) -> ()
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
      %136 = "cute.tuple.product"(%135) : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
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
      "cute.print"(%127) <{fmt = "cute.struct.MemRange: {}\0A"}> : (!memref_smem_f32_1) -> ()
      %152 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %153 = "cute.get_shape"(%152) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %154:2 = "cute.get_leaves"(%153) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %155 = "cute.memref.load_vec"(%127) : (!memref_smem_f32_1) -> vector<32xf32>
      %156 = "cute.get_layout"(%127) : (!memref_smem_f32_1) -> !cute.layout<"(8,4):(1,8)">
      %157 = "cute.get_shape"(%156) : (!cute.layout<"(8,4):(1,8)">) -> !cute.shape<"(8,4)">
      %158:2 = "cute.get_leaves"(%157) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %159 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %160 = "cute.get_shape"(%159) : (!cute.layout<"(8,4):(4,1)">) -> !cute.shape<"(8,4)">
      %161:2 = "cute.get_leaves"(%160) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %162 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"(8,4):(4,1)">
      %163 = "cute.get_shape"(%162) : (!cute.layout<"(8,4):(4,1)">) -> !cute.shape<"(8,4)">
      %164:2 = "cute.get_leaves"(%163) : (!cute.shape<"(8,4)">) -> (!cute.shape<"8">, !cute.shape<"4">)
      %165 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %166 = "cute.size"(%165) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %167 = "cute.get_leaves"(%166) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %168 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,4)">
      %169 = "cute.size"(%168) <{mode = array<i32>}> : (!cute.int_tuple<"(8,4)">) -> !cute.int_tuple<"32">
      %170 = "cute.get_leaves"(%169) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%155, %arg3) : (vector<32xf32>, !memref_gmem_f32_) -> ()
      %171 = "cute.make_shape"() : () -> !cute.shape<"(8,2)">
      %172 = "cute.make_layout"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> !cute.layout<"(8,2):(1,8)">
      %173 = "cute.recast_iter"(%57) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %174 = "cute.make_view"(%173, %172) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,2):(1,8)">) -> !memref_smem_f32_2
      %175 = "cute.get_iter"(%174) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<128>>
      %176 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %177 = "cute.size"(%176) <{mode = array<i32>}> : (!cute.layout<"(8,2):(1,8)">) -> !cute.int_tuple<"16">
      %178 = "cute.get_leaves"(%177) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %179 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %180 = "cute.get_shape"(%179) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %181:2 = "cute.get_leaves"(%180) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %182 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %183 = "cute.tuple.product"(%182) : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %184 = "cute.get_leaves"(%183) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %185 = "arith.constant"() <{value = 1.000000e+00 : f32}> : () -> f32
      %186 = "vector.splat"(%185) : (f32) -> vector<16xf32>
      %187 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %188 = "cute.get_shape"(%187) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %189:2 = "cute.get_leaves"(%188) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %190 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %191 = "cute.get_shape"(%190) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %192:2 = "cute.get_leaves"(%191) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %193 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %194 = "cute.size"(%193) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %195 = "cute.get_leaves"(%194) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %196 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %197 = "cute.size"(%196) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %198 = "cute.get_leaves"(%197) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%186, %174) : (vector<16xf32>, !memref_smem_f32_2) -> ()
      "cute.print"(%174) <{fmt = "block of memory: {}\0A"}> : (!memref_smem_f32_2) -> ()
      %199 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %200 = "cute.get_shape"(%199) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %201:2 = "cute.get_leaves"(%200) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %202 = "cute.memref.load_vec"(%174) : (!memref_smem_f32_2) -> vector<16xf32>
      %203 = "cute.get_layout"(%174) : (!memref_smem_f32_2) -> !cute.layout<"(8,2):(1,8)">
      %204 = "cute.get_shape"(%203) : (!cute.layout<"(8,2):(1,8)">) -> !cute.shape<"(8,2)">
      %205:2 = "cute.get_leaves"(%204) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %206 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %207 = "cute.get_shape"(%206) : (!cute.layout<"(8,2):(2,1)">) -> !cute.shape<"(8,2)">
      %208:2 = "cute.get_leaves"(%207) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %209 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_1) -> !cute.layout<"(8,2):(2,1)">
      %210 = "cute.get_shape"(%209) : (!cute.layout<"(8,2):(2,1)">) -> !cute.shape<"(8,2)">
      %211:2 = "cute.get_leaves"(%210) : (!cute.shape<"(8,2)">) -> (!cute.shape<"8">, !cute.shape<"2">)
      %212 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %213 = "cute.size"(%212) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %214 = "cute.get_leaves"(%213) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      %215 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(8,2)">
      %216 = "cute.size"(%215) <{mode = array<i32>}> : (!cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"16">
      %217 = "cute.get_leaves"(%216) : (!cute.int_tuple<"16">) -> !cute.int_tuple<"16">
      "cute.memref.store_vec"(%202, %arg4) : (vector<16xf32>, !memref_gmem_f32_1) -> ()
      %218 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %219 = "cute.size"(%218) <{mode = array<i32>}> : (!cute.layout<"(16,2):(1,16)">) -> !cute.int_tuple<"32">
      %220 = "cute.get_leaves"(%219) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %221 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %222 = "cute.get_shape"(%221) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %223:2 = "cute.get_leaves"(%222) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %224 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %225 = "cute.tuple.product"(%224) : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %226 = "cute.get_leaves"(%225) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %227 = "arith.constant"() <{value = 2.000000e+00 : f32}> : () -> f32
      %228 = "vector.splat"(%227) : (f32) -> vector<32xf32>
      %229 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %230 = "cute.get_shape"(%229) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %231:2 = "cute.get_leaves"(%230) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %232 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %233 = "cute.get_shape"(%232) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %234:2 = "cute.get_leaves"(%233) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %235 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %236 = "cute.size"(%235) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %237 = "cute.get_leaves"(%236) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %238 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %239 = "cute.size"(%238) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %240 = "cute.get_leaves"(%239) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%228, %120) : (vector<32xf32>, !memref_smem_f32_) -> ()
      "cute.print"(%120) <{fmt = "tensor in smem: {}\0A"}> : (!memref_smem_f32_) -> ()
      %241 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %242 = "cute.get_shape"(%241) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %243:2 = "cute.get_leaves"(%242) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %244 = "cute.memref.load_vec"(%120) : (!memref_smem_f32_) -> vector<32xf32>
      %245 = "cute.get_layout"(%120) : (!memref_smem_f32_) -> !cute.layout<"(16,2):(1,16)">
      %246 = "cute.get_shape"(%245) : (!cute.layout<"(16,2):(1,16)">) -> !cute.shape<"(16,2)">
      %247:2 = "cute.get_leaves"(%246) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %248 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %249 = "cute.get_shape"(%248) : (!cute.layout<"(16,2):(2,1)">) -> !cute.shape<"(16,2)">
      %250:2 = "cute.get_leaves"(%249) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %251 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_2) -> !cute.layout<"(16,2):(2,1)">
      %252 = "cute.get_shape"(%251) : (!cute.layout<"(16,2):(2,1)">) -> !cute.shape<"(16,2)">
      %253:2 = "cute.get_leaves"(%252) : (!cute.shape<"(16,2)">) -> (!cute.shape<"16">, !cute.shape<"2">)
      %254 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %255 = "cute.size"(%254) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %256 = "cute.get_leaves"(%255) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      %257 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"(16,2)">
      %258 = "cute.size"(%257) <{mode = array<i32>}> : (!cute.int_tuple<"(16,2)">) -> !cute.int_tuple<"32">
      %259 = "cute.get_leaves"(%258) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
      "cute.memref.store_vec"(%244, %arg5) : (vector<32xf32>, !memref_gmem_f32_2) -> ()
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
