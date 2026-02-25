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
      %11 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %12 = "cute.static"() : () -> !cute.int_tuple<"4">
      %13 = "cute.add_offset"(%11, %12) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %14 = "cute.ptrtoint"(%13) : (!cute.ptr<i8, smem, align<4>>) -> i32
      %15 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %16 = "arith.addi"(%14, %15) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %17 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %18 = "arith.subi"(%16, %17) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %19 = "arith.constant"() <{value = -128 : i32}> : () -> i32
      %20 = "arith.andi"(%18, %19) : (i32, i32) -> i32
      %21 = "arith.extsi"(%20) : (i32) -> i64
      %22 = "cute.assume"(%21) : (i64) -> !cute.i64<divby 128>
      %23 = "cute.inttoptr"(%22) : (!cute.i64<divby 128>) -> !cute.ptr<i8, smem, align<128>>
      %24 = "cute.static"() : () -> !cute.int_tuple<"512">
      %25 = "cute.add_offset"(%23, %24) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<128>>
      %26 = "cute.static"() : () -> !cute.int_tuple<"0">
      %27 = "cute.add_offset"(%23, %26) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<128>>
      %28 = "cute.static"() : () -> !cute.int_tuple<"64">
      %29 = "cute.add_offset"(%25, %28) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %30 = "cute.static"() : () -> !cute.int_tuple<"112">
      %31 = "cute.add_offset"(%29, %30) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %32 = "cute.static"() : () -> !cute.layout<"(16,2):(1,16)">
      %33 = "cute.ptrtoint"(%31) : (!cute.ptr<i8, smem, align<16>>) -> i32
      %34 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %35 = "arith.addi"(%33, %34) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %36 = "arith.subi"(%35, %17) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %37 = "arith.constant"() <{value = -32 : i32}> : () -> i32
      %38 = "arith.andi"(%36, %37) : (i32, i32) -> i32
      %39 = "arith.extsi"(%38) : (i32) -> i64
      %40 = "cute.assume"(%39) : (i64) -> !cute.i64<divby 32>
      %41 = "cute.inttoptr"(%40) : (!cute.i64<divby 32>) -> !cute.ptr<i8, smem, align<32>>
      %42 = "cute.recast_iter"(%41) : (!cute.ptr<i8, smem, align<32>>) -> !cute.ptr<f32, smem, align<32>>
      %43 = "cute.make_view"(%42, %32) : (!cute.ptr<f32, smem, align<32>>, !cute.layout<"(16,2):(1,16)">) -> !memref_smem_f32_
      %44 = "cute.static"() : () -> !cute.layout<"(8,4):(1,8)">
      %45 = "cute.recast_iter"(%27) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %46 = "cute.make_view"(%45, %44) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,4):(1,8)">) -> !memref_smem_f32_1
      %47 = "arith.constant"() <{value = 5.000000e-01 : f32}> : () -> f32
      %48 = "vector.splat"(%47) : (f32) -> vector<32xf32>
      "cute.memref.store_vec"(%48, %46) : (vector<32xf32>, !memref_smem_f32_1) -> ()
      %49 = "cute.get_iter"(%46) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<128>>
      %50 = "builtin.unrealized_conversion_cast"(%49) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %51 = "llvm.ptrtoint"(%50) : (!llvm.ptr<3>) -> i64
      %52 = "cute.memref.load_vec"(%46) : (!memref_smem_f32_1) -> vector<32xf32>
      %53 = "vector.extract"(%52) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %54 = "vector.extract"(%52) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %55 = "vector.extract"(%52) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %56 = "vector.extract"(%52) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %57 = "vector.extract"(%52) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %58 = "vector.extract"(%52) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %59 = "vector.extract"(%52) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %60 = "vector.extract"(%52) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %61 = "vector.extract"(%52) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %62 = "vector.extract"(%52) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %63 = "vector.extract"(%52) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %64 = "vector.extract"(%52) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %65 = "vector.extract"(%52) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %66 = "vector.extract"(%52) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %67 = "vector.extract"(%52) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %68 = "vector.extract"(%52) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %69 = "vector.extract"(%52) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %70 = "vector.extract"(%52) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %71 = "vector.extract"(%52) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %72 = "vector.extract"(%52) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %73 = "vector.extract"(%52) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %74 = "vector.extract"(%52) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %75 = "vector.extract"(%52) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %76 = "vector.extract"(%52) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %77 = "vector.extract"(%52) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %78 = "vector.extract"(%52) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %79 = "vector.extract"(%52) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %80 = "vector.extract"(%52) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %81 = "vector.extract"(%52) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %82 = "vector.extract"(%52) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %83 = "vector.extract"(%52) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%51, %53, %54, %55, %56, %57, %58, %59, %60, %61, %62, %63, %64, %65, %66, %67, %68, %69, %70, %71, %72, %73, %74, %75, %76, %77, %78, %79, %80, %81, %82, %83) <{format = "cute.struct.MemRange: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,4):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %84 = "cute.memref.load_vec"(%46) : (!memref_smem_f32_1) -> vector<32xf32>
      "cute.memref.store_vec"(%84, %arg3) : (vector<32xf32>, !memref_gmem_f32_) -> ()
      %85 = "cute.static"() : () -> !cute.layout<"(8,2):(1,8)">
      %86 = "cute.recast_iter"(%25) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %87 = "cute.make_view"(%86, %85) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,2):(1,8)">) -> !memref_smem_f32_2
      %88 = "arith.constant"() <{value = 1.000000e+00 : f32}> : () -> f32
      %89 = "vector.splat"(%88) : (f32) -> vector<16xf32>
      "cute.memref.store_vec"(%89, %87) : (vector<16xf32>, !memref_smem_f32_2) -> ()
      %90 = "cute.get_iter"(%87) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<128>>
      %91 = "builtin.unrealized_conversion_cast"(%90) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %92 = "llvm.ptrtoint"(%91) : (!llvm.ptr<3>) -> i64
      %93 = "cute.memref.load_vec"(%87) : (!memref_smem_f32_2) -> vector<16xf32>
      %94 = "vector.extract"(%93) <{static_position = array<i64: 0>}> : (vector<16xf32>) -> f32
      %95 = "vector.extract"(%93) <{static_position = array<i64: 1>}> : (vector<16xf32>) -> f32
      %96 = "vector.extract"(%93) <{static_position = array<i64: 2>}> : (vector<16xf32>) -> f32
      %97 = "vector.extract"(%93) <{static_position = array<i64: 3>}> : (vector<16xf32>) -> f32
      %98 = "vector.extract"(%93) <{static_position = array<i64: 4>}> : (vector<16xf32>) -> f32
      %99 = "vector.extract"(%93) <{static_position = array<i64: 5>}> : (vector<16xf32>) -> f32
      %100 = "vector.extract"(%93) <{static_position = array<i64: 6>}> : (vector<16xf32>) -> f32
      %101 = "vector.extract"(%93) <{static_position = array<i64: 7>}> : (vector<16xf32>) -> f32
      %102 = "vector.extract"(%93) <{static_position = array<i64: 8>}> : (vector<16xf32>) -> f32
      %103 = "vector.extract"(%93) <{static_position = array<i64: 9>}> : (vector<16xf32>) -> f32
      %104 = "vector.extract"(%93) <{static_position = array<i64: 10>}> : (vector<16xf32>) -> f32
      %105 = "vector.extract"(%93) <{static_position = array<i64: 11>}> : (vector<16xf32>) -> f32
      %106 = "vector.extract"(%93) <{static_position = array<i64: 12>}> : (vector<16xf32>) -> f32
      %107 = "vector.extract"(%93) <{static_position = array<i64: 13>}> : (vector<16xf32>) -> f32
      %108 = "vector.extract"(%93) <{static_position = array<i64: 14>}> : (vector<16xf32>) -> f32
      %109 = "vector.extract"(%93) <{static_position = array<i64: 15>}> : (vector<16xf32>) -> f32
      "gpu.printf"(%92, %94, %95, %96, %97, %98, %99, %100, %101, %102, %103, %104, %105, %106, %107, %108, %109) <{format = "block of memory: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,2):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %110 = "cute.memref.load_vec"(%87) : (!memref_smem_f32_2) -> vector<16xf32>
      "cute.memref.store_vec"(%110, %arg4) : (vector<16xf32>, !memref_gmem_f32_1) -> ()
      %111 = "arith.constant"() <{value = 2.000000e+00 : f32}> : () -> f32
      %112 = "vector.splat"(%111) : (f32) -> vector<32xf32>
      "cute.memref.store_vec"(%112, %43) : (vector<32xf32>, !memref_smem_f32_) -> ()
      %113 = "cute.get_iter"(%43) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<32>>
      %114 = "builtin.unrealized_conversion_cast"(%113) : (!cute.ptr<f32, smem, align<32>>) -> !llvm.ptr<3>
      %115 = "llvm.ptrtoint"(%114) : (!llvm.ptr<3>) -> i64
      %116 = "cute.memref.load_vec"(%43) : (!memref_smem_f32_) -> vector<32xf32>
      %117 = "vector.extract"(%116) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %118 = "vector.extract"(%116) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %119 = "vector.extract"(%116) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %120 = "vector.extract"(%116) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %121 = "vector.extract"(%116) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %122 = "vector.extract"(%116) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %123 = "vector.extract"(%116) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %124 = "vector.extract"(%116) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %125 = "vector.extract"(%116) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %126 = "vector.extract"(%116) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %127 = "vector.extract"(%116) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %128 = "vector.extract"(%116) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %129 = "vector.extract"(%116) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %130 = "vector.extract"(%116) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %131 = "vector.extract"(%116) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %132 = "vector.extract"(%116) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %133 = "vector.extract"(%116) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %134 = "vector.extract"(%116) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %135 = "vector.extract"(%116) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %136 = "vector.extract"(%116) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %137 = "vector.extract"(%116) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %138 = "vector.extract"(%116) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %139 = "vector.extract"(%116) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %140 = "vector.extract"(%116) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %141 = "vector.extract"(%116) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %142 = "vector.extract"(%116) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %143 = "vector.extract"(%116) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %144 = "vector.extract"(%116) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %145 = "vector.extract"(%116) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %146 = "vector.extract"(%116) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %147 = "vector.extract"(%116) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%115, %117, %118, %119, %120, %121, %122, %123, %124, %125, %126, %127, %128, %129, %130, %131, %132, %133, %134, %135, %136, %137, %138, %139, %140, %141, %142, %143, %144, %145, %146, %147) <{format = "tensor in smem: raw_ptr(0x%016llx: f32, smem, align<32>) o (16,2):(1,16) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %148 = "cute.memref.load_vec"(%43) : (!memref_smem_f32_) -> vector<32xf32>
      "cute.memref.store_vec"(%148, %arg5) : (vector<32xf32>, !memref_gmem_f32_2) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> i32, sym_name = "cutlass_host_05_Tensorgmemo8441_10_Tensorgmemo8221_20_Tensorgmemo16221"}> ({
  ^bb0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2):
    %0 = "arith.constant"() <{value = 960 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %2 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %3 = "arith.extsi"(%0) : (i32) -> i64
    %4 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %5 = "cuda.launch_cfg.create"(%4, %4, %4, %3, %4, %4, %4, %2) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %6 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%5, %6) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %7 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%5, %7) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %8 = "cuda.launch_ex"(%5, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %9 = "cuda.cast"(%8) : (!cuda.result) -> i32
    "cuda.return_if_error"(%9) : (i32) -> ()
    %10 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%10) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
