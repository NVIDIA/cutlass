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
      %8 = "arith.constant"() <{value = dense<2.000000e+00> : vector<32xf32>}> : () -> vector<32xf32>
      %9 = "arith.constant"() <{value = dense<1.000000e+00> : vector<16xf32>}> : () -> vector<16xf32>
      %10 = "arith.constant"() <{value = dense<5.000000e-01> : vector<32xf32>}> : () -> vector<32xf32>
      %11 = "arith.constant"() <{value = 31 : i32}> : () -> i32
      %12 = "arith.constant"() <{value = 127 : i32}> : () -> i32
      %13 = "cute.static"() : () -> !cute.layout<"(8,2):(1,8)">
      %14 = "cute.static"() : () -> !cute.layout<"(8,4):(1,8)">
      %15 = "arith.constant"() <{value = -32 : i32}> : () -> i32
      %16 = "cute.static"() : () -> !cute.layout<"(16,2):(1,16)">
      %17 = "cute.static"() : () -> !cute.int_tuple<"512">
      %18 = "arith.constant"() <{value = -128 : i32}> : () -> i32
      %19 = "cute.static"() : () -> !cute.int_tuple<"4">
      %20 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %21 = "cute.add_offset"(%20, %19) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %22 = "cute.ptrtoint"(%21) : (!cute.ptr<i8, smem, align<4>>) -> i32
      %23 = "arith.addi"(%22, %12) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %24 = "arith.andi"(%23, %18) : (i32, i32) -> i32
      %25 = "arith.extsi"(%24) : (i32) -> i64
      %26 = "cute.assume"(%25) : (i64) -> !cute.i64<divby 128>
      %27 = "cute.inttoptr"(%26) : (!cute.i64<divby 128>) -> !cute.ptr<i8, smem, align<128>>
      %28 = "cute.add_offset"(%27, %17) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<128>>
      %29 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"688">
      %30 = "cute.add_offset"(%27, %29) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"688">) -> !cute.ptr<i8, smem, align<16>>
      %31 = "cute.ptrtoint"(%30) : (!cute.ptr<i8, smem, align<16>>) -> i32
      %32 = "arith.addi"(%31, %11) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %33 = "arith.andi"(%32, %15) : (i32, i32) -> i32
      %34 = "arith.extsi"(%33) : (i32) -> i64
      %35 = "cute.assume"(%34) : (i64) -> !cute.i64<divby 32>
      %36 = "cute.inttoptr"(%35) : (!cute.i64<divby 32>) -> !cute.ptr<i8, smem, align<32>>
      %37 = "cute.recast_iter"(%36) : (!cute.ptr<i8, smem, align<32>>) -> !cute.ptr<f32, smem, align<32>>
      %38 = "cute.make_view"(%37, %16) : (!cute.ptr<f32, smem, align<32>>, !cute.layout<"(16,2):(1,16)">) -> !memref_smem_f32_
      %39 = "cute.recast_iter"(%27) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %40 = "cute.make_view"(%39, %14) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,4):(1,8)">) -> !memref_smem_f32_1
      "cute.memref.store_vec"(%10, %40) : (vector<32xf32>, !memref_smem_f32_1) -> ()
      %41 = "builtin.unrealized_conversion_cast"(%39) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %42 = "llvm.ptrtoint"(%41) : (!llvm.ptr<3>) -> i64
      %43 = "cute.memref.load_vec"(%40) : (!memref_smem_f32_1) -> vector<32xf32>
      %44 = "vector.extract"(%43) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %45 = "vector.extract"(%43) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %46 = "vector.extract"(%43) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %47 = "vector.extract"(%43) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %48 = "vector.extract"(%43) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %49 = "vector.extract"(%43) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %50 = "vector.extract"(%43) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %51 = "vector.extract"(%43) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %52 = "vector.extract"(%43) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %53 = "vector.extract"(%43) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %54 = "vector.extract"(%43) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %55 = "vector.extract"(%43) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %56 = "vector.extract"(%43) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %57 = "vector.extract"(%43) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %58 = "vector.extract"(%43) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %59 = "vector.extract"(%43) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %60 = "vector.extract"(%43) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %61 = "vector.extract"(%43) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %62 = "vector.extract"(%43) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %63 = "vector.extract"(%43) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %64 = "vector.extract"(%43) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %65 = "vector.extract"(%43) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %66 = "vector.extract"(%43) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %67 = "vector.extract"(%43) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %68 = "vector.extract"(%43) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %69 = "vector.extract"(%43) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %70 = "vector.extract"(%43) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %71 = "vector.extract"(%43) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %72 = "vector.extract"(%43) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %73 = "vector.extract"(%43) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %74 = "vector.extract"(%43) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%42, %44, %45, %46, %47, %48, %49, %50, %51, %52, %53, %54, %55, %56, %57, %58, %59, %60, %61, %62, %63, %64, %65, %66, %67, %68, %69, %70, %71, %72, %73, %74) <{format = "cute.struct.MemRange: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,4):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %75 = "cute.memref.load_vec"(%40) : (!memref_smem_f32_1) -> vector<32xf32>
      "cute.memref.store_vec"(%75, %arg3) : (vector<32xf32>, !memref_gmem_f32_) -> ()
      %76 = "cute.recast_iter"(%28) : (!cute.ptr<i8, smem, align<128>>) -> !cute.ptr<f32, smem, align<128>>
      %77 = "cute.make_view"(%76, %13) : (!cute.ptr<f32, smem, align<128>>, !cute.layout<"(8,2):(1,8)">) -> !memref_smem_f32_2
      "cute.memref.store_vec"(%9, %77) : (vector<16xf32>, !memref_smem_f32_2) -> ()
      %78 = "builtin.unrealized_conversion_cast"(%76) : (!cute.ptr<f32, smem, align<128>>) -> !llvm.ptr<3>
      %79 = "llvm.ptrtoint"(%78) : (!llvm.ptr<3>) -> i64
      %80 = "cute.memref.load_vec"(%77) : (!memref_smem_f32_2) -> vector<16xf32>
      %81 = "vector.extract"(%80) <{static_position = array<i64: 0>}> : (vector<16xf32>) -> f32
      %82 = "vector.extract"(%80) <{static_position = array<i64: 1>}> : (vector<16xf32>) -> f32
      %83 = "vector.extract"(%80) <{static_position = array<i64: 2>}> : (vector<16xf32>) -> f32
      %84 = "vector.extract"(%80) <{static_position = array<i64: 3>}> : (vector<16xf32>) -> f32
      %85 = "vector.extract"(%80) <{static_position = array<i64: 4>}> : (vector<16xf32>) -> f32
      %86 = "vector.extract"(%80) <{static_position = array<i64: 5>}> : (vector<16xf32>) -> f32
      %87 = "vector.extract"(%80) <{static_position = array<i64: 6>}> : (vector<16xf32>) -> f32
      %88 = "vector.extract"(%80) <{static_position = array<i64: 7>}> : (vector<16xf32>) -> f32
      %89 = "vector.extract"(%80) <{static_position = array<i64: 8>}> : (vector<16xf32>) -> f32
      %90 = "vector.extract"(%80) <{static_position = array<i64: 9>}> : (vector<16xf32>) -> f32
      %91 = "vector.extract"(%80) <{static_position = array<i64: 10>}> : (vector<16xf32>) -> f32
      %92 = "vector.extract"(%80) <{static_position = array<i64: 11>}> : (vector<16xf32>) -> f32
      %93 = "vector.extract"(%80) <{static_position = array<i64: 12>}> : (vector<16xf32>) -> f32
      %94 = "vector.extract"(%80) <{static_position = array<i64: 13>}> : (vector<16xf32>) -> f32
      %95 = "vector.extract"(%80) <{static_position = array<i64: 14>}> : (vector<16xf32>) -> f32
      %96 = "vector.extract"(%80) <{static_position = array<i64: 15>}> : (vector<16xf32>) -> f32
      "gpu.printf"(%79, %81, %82, %83, %84, %85, %86, %87, %88, %89, %90, %91, %92, %93, %94, %95, %96) <{format = "block of memory: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,2):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %97 = "cute.memref.load_vec"(%77) : (!memref_smem_f32_2) -> vector<16xf32>
      "cute.memref.store_vec"(%97, %arg4) : (vector<16xf32>, !memref_gmem_f32_1) -> ()
      "cute.memref.store_vec"(%8, %38) : (vector<32xf32>, !memref_smem_f32_) -> ()
      %98 = "builtin.unrealized_conversion_cast"(%37) : (!cute.ptr<f32, smem, align<32>>) -> !llvm.ptr<3>
      %99 = "llvm.ptrtoint"(%98) : (!llvm.ptr<3>) -> i64
      %100 = "cute.memref.load_vec"(%38) : (!memref_smem_f32_) -> vector<32xf32>
      %101 = "vector.extract"(%100) <{static_position = array<i64: 0>}> : (vector<32xf32>) -> f32
      %102 = "vector.extract"(%100) <{static_position = array<i64: 1>}> : (vector<32xf32>) -> f32
      %103 = "vector.extract"(%100) <{static_position = array<i64: 2>}> : (vector<32xf32>) -> f32
      %104 = "vector.extract"(%100) <{static_position = array<i64: 3>}> : (vector<32xf32>) -> f32
      %105 = "vector.extract"(%100) <{static_position = array<i64: 4>}> : (vector<32xf32>) -> f32
      %106 = "vector.extract"(%100) <{static_position = array<i64: 5>}> : (vector<32xf32>) -> f32
      %107 = "vector.extract"(%100) <{static_position = array<i64: 6>}> : (vector<32xf32>) -> f32
      %108 = "vector.extract"(%100) <{static_position = array<i64: 7>}> : (vector<32xf32>) -> f32
      %109 = "vector.extract"(%100) <{static_position = array<i64: 8>}> : (vector<32xf32>) -> f32
      %110 = "vector.extract"(%100) <{static_position = array<i64: 9>}> : (vector<32xf32>) -> f32
      %111 = "vector.extract"(%100) <{static_position = array<i64: 10>}> : (vector<32xf32>) -> f32
      %112 = "vector.extract"(%100) <{static_position = array<i64: 11>}> : (vector<32xf32>) -> f32
      %113 = "vector.extract"(%100) <{static_position = array<i64: 12>}> : (vector<32xf32>) -> f32
      %114 = "vector.extract"(%100) <{static_position = array<i64: 13>}> : (vector<32xf32>) -> f32
      %115 = "vector.extract"(%100) <{static_position = array<i64: 14>}> : (vector<32xf32>) -> f32
      %116 = "vector.extract"(%100) <{static_position = array<i64: 15>}> : (vector<32xf32>) -> f32
      %117 = "vector.extract"(%100) <{static_position = array<i64: 16>}> : (vector<32xf32>) -> f32
      %118 = "vector.extract"(%100) <{static_position = array<i64: 17>}> : (vector<32xf32>) -> f32
      %119 = "vector.extract"(%100) <{static_position = array<i64: 18>}> : (vector<32xf32>) -> f32
      %120 = "vector.extract"(%100) <{static_position = array<i64: 19>}> : (vector<32xf32>) -> f32
      %121 = "vector.extract"(%100) <{static_position = array<i64: 20>}> : (vector<32xf32>) -> f32
      %122 = "vector.extract"(%100) <{static_position = array<i64: 21>}> : (vector<32xf32>) -> f32
      %123 = "vector.extract"(%100) <{static_position = array<i64: 22>}> : (vector<32xf32>) -> f32
      %124 = "vector.extract"(%100) <{static_position = array<i64: 23>}> : (vector<32xf32>) -> f32
      %125 = "vector.extract"(%100) <{static_position = array<i64: 24>}> : (vector<32xf32>) -> f32
      %126 = "vector.extract"(%100) <{static_position = array<i64: 25>}> : (vector<32xf32>) -> f32
      %127 = "vector.extract"(%100) <{static_position = array<i64: 26>}> : (vector<32xf32>) -> f32
      %128 = "vector.extract"(%100) <{static_position = array<i64: 27>}> : (vector<32xf32>) -> f32
      %129 = "vector.extract"(%100) <{static_position = array<i64: 28>}> : (vector<32xf32>) -> f32
      %130 = "vector.extract"(%100) <{static_position = array<i64: 29>}> : (vector<32xf32>) -> f32
      %131 = "vector.extract"(%100) <{static_position = array<i64: 30>}> : (vector<32xf32>) -> f32
      "gpu.printf"(%99, %101, %102, %103, %104, %105, %106, %107, %108, %109, %110, %111, %112, %113, %114, %115, %116, %117, %118, %119, %120, %121, %122, %123, %124, %125, %126, %127, %128, %129, %130, %131) <{format = "tensor in smem: raw_ptr(0x%016llx: f32, smem, align<32>) o (16,2):(1,16) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A"}> : (i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) -> ()
      %132 = "cute.memref.load_vec"(%38) : (!memref_smem_f32_) -> vector<32xf32>
      "cute.memref.store_vec"(%132, %arg5) : (vector<32xf32>, !memref_gmem_f32_2) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> i32, sym_name = "cutlass_host_05_Tensorgmemo8441_10_Tensorgmemo8221_20_Tensorgmemo16221"}> ({
  ^bb0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2):
    %0 = "arith.constant"() <{value = 960 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %3 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %4 = "cuda.cast"(%3) : (i64) -> !cuda.stream
    %5 = "cuda.launch_cfg.create"(%2, %2, %2, %0, %2, %2, %2, %4) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%5, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%5, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %6 = "cuda.launch_ex"(%5, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %7 = "cuda.cast"(%6) : (!cuda.result) -> i32
    "cuda.return_if_error"(%7) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
