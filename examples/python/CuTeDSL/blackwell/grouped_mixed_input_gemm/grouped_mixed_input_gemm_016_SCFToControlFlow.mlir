!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i4_ = !cute.memref<i4, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_i8_, %arg4: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %51 = "cute.static"() : () -> !cute.int_tuple<"7">
      %52 = "cute.static"() : () -> !cute.int_tuple<"6">
      %53 = "cute.static"() : () -> !cute.int_tuple<"5">
      %54 = "cute.static"() : () -> !cute.int_tuple<"4">
      %55 = "cute.static"() : () -> !cute.int_tuple<"3">
      %56 = "cute.static"() : () -> !cute.int_tuple<"2">
      %57 = "cute.static"() : () -> !cute.int_tuple<"1">
      %58 = "cute.static"() : () -> !cute.layout<"8:1">
      %59 = "cute.static"() : () -> !cute.layout<"(128,8):(8@0,1@0)">
      %60 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %61 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %62 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %63 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %64 = "cute.make_coord"(%63) : (i32) -> !cute.coord<"(_,?)">
      %65 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %66 = "cute.crd2idx"(%64, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %67 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %68 = "cute.add_offset"(%67, %66) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %69 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %70 = "cute.crd2idx"(%64, %69) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %71 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %72 = "cute.add_offset"(%71, %70) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %73 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %74 = "cute.crd2idx"(%64, %73) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %75 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %76 = "cute.add_offset"(%75, %74) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %77 = "cute.make_coord"(%62) : (i32) -> !cute.coord<"(?,_)">
      %78 = "cute.crd2idx"(%77, %60) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %79 = "cute.add_offset"(%68, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %80 = "cute.crd2idx"(%77, %61) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %81 = "cute.add_offset"(%72, %80) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %82 = "cute.crd2idx"(%77, %59) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %83 = "cute.add_offset"(%76, %82) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %84 = "cute.deref_arith_tuple_iter"(%83) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %85:3 = "cute.get_leaves"(%84) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %86 = "cute.make_coord"(%85#0, %85#1, %85#2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %87 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %88:3 = "cute.get_scalars"(%86) : (!cute.coord<"(?{div=8},?,?)">) -> (i32, i32, i32)
      %89:3 = "cute.get_scalars"(%87) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %90 = "arith.cmpi"(%88#0, %89#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %91 = "arith.cmpi"(%88#1, %89#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %92 = "arith.andi"(%90, %91) : (i1, i1) -> i1
      %93 = "arith.cmpi"(%88#2, %89#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %94 = "arith.andi"(%92, %93) : (i1, i1) -> i1
      "cf.cond_br"(%94)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %95 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %96 = "cute.get_iter"(%95) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %97 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %98 = "cute.get_iter"(%97) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %99 = "builtin.unrealized_conversion_cast"(%79) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %100 = "builtin.unrealized_conversion_cast"(%96) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %101 = "llvm.load"(%99) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%101, %100) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %102 = "cute.add_offset"(%79, %57) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %103 = "cute.add_offset"(%96, %57) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %104 = "builtin.unrealized_conversion_cast"(%102) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %105 = "builtin.unrealized_conversion_cast"(%103) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %106 = "llvm.load"(%104) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%106, %105) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %107 = "cute.add_offset"(%79, %56) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %108 = "cute.add_offset"(%96, %56) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %109 = "builtin.unrealized_conversion_cast"(%107) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %110 = "builtin.unrealized_conversion_cast"(%108) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %111 = "llvm.load"(%109) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%111, %110) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %112 = "cute.add_offset"(%79, %55) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %113 = "cute.add_offset"(%96, %55) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %114 = "builtin.unrealized_conversion_cast"(%112) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %115 = "builtin.unrealized_conversion_cast"(%113) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %116 = "llvm.load"(%114) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%116, %115) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %117 = "cute.add_offset"(%79, %54) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
      %118 = "cute.add_offset"(%96, %54) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %119 = "builtin.unrealized_conversion_cast"(%117) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %120 = "builtin.unrealized_conversion_cast"(%118) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %121 = "llvm.load"(%119) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%121, %120) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %122 = "cute.add_offset"(%79, %53) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
      %123 = "cute.add_offset"(%96, %53) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %124 = "builtin.unrealized_conversion_cast"(%122) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %125 = "builtin.unrealized_conversion_cast"(%123) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %126 = "llvm.load"(%124) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%126, %125) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %127 = "cute.add_offset"(%79, %52) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
      %128 = "cute.add_offset"(%96, %52) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %129 = "builtin.unrealized_conversion_cast"(%127) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %130 = "builtin.unrealized_conversion_cast"(%128) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %131 = "llvm.load"(%129) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%131, %130) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %132 = "cute.add_offset"(%79, %51) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
      %133 = "cute.add_offset"(%96, %51) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %134 = "builtin.unrealized_conversion_cast"(%132) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %135 = "builtin.unrealized_conversion_cast"(%133) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %136 = "llvm.load"(%134) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%136, %135) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %137 = "cute.memref.load_vec"(%95) : (!memref_rmem_f32_) -> vector<8xf32>
      %138 = "arith.fptosi"(%137) : (vector<8xf32>) -> vector<8xi4>
      %139 = "cute.recast_layout"(%58) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
      %140 = "vector.bitcast"(%138) : (vector<8xi4>) -> vector<4xi8>
      "cute.memref.store_vec"(%140, %97) : (vector<4xi8>, !memref_rmem_i8_) -> ()
      %141 = "builtin.unrealized_conversion_cast"(%98) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %142 = "builtin.unrealized_conversion_cast"(%81) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %143 = "llvm.load"(%141) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%143, %142) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %144 = "cute.add_offset"(%98, %57) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %145 = "cute.add_offset"(%81, %57) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
      %146 = "builtin.unrealized_conversion_cast"(%144) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %147 = "builtin.unrealized_conversion_cast"(%145) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %148 = "llvm.load"(%146) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%148, %147) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %149 = "cute.add_offset"(%98, %56) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %150 = "cute.add_offset"(%81, %56) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
      %151 = "builtin.unrealized_conversion_cast"(%149) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %152 = "builtin.unrealized_conversion_cast"(%150) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %153 = "llvm.load"(%151) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%153, %152) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %154 = "cute.add_offset"(%98, %55) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %155 = "cute.add_offset"(%81, %55) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
      %156 = "builtin.unrealized_conversion_cast"(%154) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %157 = "builtin.unrealized_conversion_cast"(%155) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %158 = "llvm.load"(%156) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%158, %157) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_i4_) -> i32, sym_name = "cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8"}> ({
  ^bb0(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_i4_):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %3 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %5 = "cute.static"() : () -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %6 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %7 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %8 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
    %9 = "cute.get_iter"(%arg1) : (!memref_gmem_i4_) -> !cute.ptr<i4, gmem, align<128>>
    %10 = "cute.recast_layout"(%8) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"(128,4):(4,1)">
    %11 = "cute.recast_iter"(%9) : (!cute.ptr<i4, gmem, align<128>>) -> !cute.ptr<i8, gmem, align<128>>
    %12 = "cute.get_layout"(%arg1) : (!memref_gmem_i4_) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %13 = "cute.recast_layout"(%12) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %14 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %15 = "cute.get_shape"(%14) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %16:3 = "cute.get_leaves"(%15) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %17 = "cute.to_int_tuple"(%16#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %18 = "cute.get_scalars"(%17) : (!cute.int_tuple<"?">) -> i32
    %19 = "cute.to_int_tuple"(%16#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %20 = "cute.get_scalars"(%19) : (!cute.int_tuple<"?">) -> i32
    %21 = "cute.to_int_tuple"(%16#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %22 = "cute.get_scalars"(%21) : (!cute.int_tuple<"?">) -> i32
    %23 = "cute.make_shape"(%17, %19, %21) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %24 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %25 = "cute.make_layout"(%23, %7) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %26 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %27:5 = "cute.get_scalars"(%14) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %28 = "arith.ceildivsi"(%27#0, %6) : (i32, i32) -> i32
    %29 = "cute.make_shape"(%28, %27#1, %27#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %30 = "cute.make_stride"(%27#3, %27#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %31 = "cute.make_layout"(%29, %30) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %32 = "cute.make_view"(%26, %31) : (!cute.ptr<f32, gmem>, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !memref_gmem_f32_
    %33:3 = "cute.get_scalars"(%25) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %34 = "arith.ceildivsi"(%33#0, %6) : (i32, i32) -> i32
    %35 = "cute.make_shape"(%34, %33#1, %33#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %36 = "cute.make_layout"(%35, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %37 = "cute.make_view"(%24, %36) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %38:5 = "cute.get_scalars"(%13) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %39 = "arith.ceildivsi"(%38#0, %4) : (i32, i32) -> i32
    %40 = "cute.make_shape"(%39, %38#1, %38#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %41 = "cute.make_stride"(%38#3, %38#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %42 = "cute.make_layout"(%40, %41) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((512,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %43 = "cute.make_view"(%11, %42) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !memref_gmem_i8_
    %44 = "cute.size"(%31) <{mode = array<i32: 1>}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %45 = "cute.get_leaves"(%44) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.get_scalars"(%45) : (!cute.int_tuple<"?">) -> i32
    %47 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %48 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %46, %0, %0, %47) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%48, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%48, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %49 = "cuda.launch_ex"(%48, %32, %43, %37, %18, %20, %22) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> !cuda.result
    %50 = "cuda.cast"(%49) : (!cuda.result) -> i32
    "cuda.return_if_error"(%50) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
