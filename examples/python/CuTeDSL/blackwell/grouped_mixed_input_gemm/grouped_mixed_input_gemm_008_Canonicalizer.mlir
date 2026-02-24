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
      %58 = "cute.static"() : () -> !cute.int_tuple<"7">
      %59 = "cute.static"() : () -> !cute.int_tuple<"6">
      %60 = "cute.static"() : () -> !cute.int_tuple<"5">
      %61 = "cute.static"() : () -> !cute.int_tuple<"4">
      %62 = "cute.static"() : () -> !cute.int_tuple<"3">
      %63 = "cute.static"() : () -> !cute.int_tuple<"2">
      %64 = "cute.static"() : () -> !cute.int_tuple<"1">
      %65 = "cute.static"() : () -> !cute.layout<"8:1">
      %66 = "cute.static"() : () -> !cute.layout<"(128,8):(8@0,1@0)">
      %67 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %68 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %69 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %70 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %71 = "cute.make_coord"(%70) : (i32) -> !cute.coord<"(_,?)">
      %72 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %73 = "cute.crd2idx"(%71, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %74 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %75 = "cute.add_offset"(%74, %73) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %76 = "cute.make_coord"(%70) : (i32) -> !cute.coord<"(_,?)">
      %77 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %78 = "cute.crd2idx"(%76, %77) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %79 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %80 = "cute.add_offset"(%79, %78) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %81 = "cute.make_coord"(%70) : (i32) -> !cute.coord<"(_,?)">
      %82 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %83 = "cute.crd2idx"(%81, %82) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %84 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %85 = "cute.add_offset"(%84, %83) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %86 = "cute.make_coord"(%69) : (i32) -> !cute.coord<"(?,_)">
      %87 = "cute.crd2idx"(%86, %67) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %88 = "cute.add_offset"(%75, %87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %89 = "cute.make_coord"(%69) : (i32) -> !cute.coord<"(?,_)">
      %90 = "cute.crd2idx"(%89, %68) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %91 = "cute.add_offset"(%80, %90) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %92 = "cute.make_coord"(%69) : (i32) -> !cute.coord<"(?,_)">
      %93 = "cute.crd2idx"(%92, %66) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %94 = "cute.add_offset"(%85, %93) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %95 = "cute.deref_arith_tuple_iter"(%94) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %96:3 = "cute.get_leaves"(%95) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %97 = "cute.make_coord"(%96#0, %96#1, %96#2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %98 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %99:3 = "cute.get_scalars"(%97) : (!cute.coord<"(?{div=8},?,?)">) -> (i32, i32, i32)
      %100:3 = "cute.get_scalars"(%98) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %101 = "arith.cmpi"(%99#0, %100#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %102 = "arith.cmpi"(%99#1, %100#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %103 = "arith.andi"(%101, %102) : (i1, i1) -> i1
      %104 = "arith.cmpi"(%99#2, %100#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %105 = "arith.andi"(%103, %104) : (i1, i1) -> i1
      "scf.if"(%105) ({
        %106 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
        %107 = "cute.get_iter"(%106) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %108 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
        %109 = "cute.get_iter"(%108) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %110 = "builtin.unrealized_conversion_cast"(%88) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %111 = "builtin.unrealized_conversion_cast"(%107) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %112 = "llvm.load"(%110) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%112, %111) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %113 = "cute.add_offset"(%88, %64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %114 = "cute.add_offset"(%107, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %115 = "builtin.unrealized_conversion_cast"(%113) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %116 = "builtin.unrealized_conversion_cast"(%114) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %117 = "llvm.load"(%115) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%117, %116) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %118 = "cute.add_offset"(%88, %63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %119 = "cute.add_offset"(%107, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %120 = "builtin.unrealized_conversion_cast"(%118) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %121 = "builtin.unrealized_conversion_cast"(%119) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %122 = "llvm.load"(%120) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%122, %121) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %123 = "cute.add_offset"(%88, %62) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %124 = "cute.add_offset"(%107, %62) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %125 = "builtin.unrealized_conversion_cast"(%123) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %126 = "builtin.unrealized_conversion_cast"(%124) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %127 = "llvm.load"(%125) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%127, %126) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %128 = "cute.add_offset"(%88, %61) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
        %129 = "cute.add_offset"(%107, %61) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %130 = "builtin.unrealized_conversion_cast"(%128) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %131 = "builtin.unrealized_conversion_cast"(%129) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %132 = "llvm.load"(%130) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%132, %131) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %133 = "cute.add_offset"(%88, %60) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
        %134 = "cute.add_offset"(%107, %60) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %135 = "builtin.unrealized_conversion_cast"(%133) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %136 = "builtin.unrealized_conversion_cast"(%134) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %137 = "llvm.load"(%135) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%137, %136) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %138 = "cute.add_offset"(%88, %59) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
        %139 = "cute.add_offset"(%107, %59) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %140 = "builtin.unrealized_conversion_cast"(%138) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %141 = "builtin.unrealized_conversion_cast"(%139) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %142 = "llvm.load"(%140) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%142, %141) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %143 = "cute.add_offset"(%88, %58) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
        %144 = "cute.add_offset"(%107, %58) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %145 = "builtin.unrealized_conversion_cast"(%143) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %146 = "builtin.unrealized_conversion_cast"(%144) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %147 = "llvm.load"(%145) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%147, %146) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %148 = "cute.memref.load_vec"(%106) : (!memref_rmem_f32_) -> vector<8xf32>
        %149 = "arith.fptosi"(%148) : (vector<8xf32>) -> vector<8xi4>
        %150 = "cute.recast_layout"(%65) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %151 = "vector.bitcast"(%149) : (vector<8xi4>) -> vector<4xi8>
        "cute.memref.store_vec"(%151, %108) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %152 = "builtin.unrealized_conversion_cast"(%109) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %153 = "builtin.unrealized_conversion_cast"(%91) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
        %154 = "llvm.load"(%152) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%154, %153) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %155 = "cute.add_offset"(%109, %64) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %156 = "cute.add_offset"(%91, %64) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
        %157 = "builtin.unrealized_conversion_cast"(%155) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %158 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
        %159 = "llvm.load"(%157) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%159, %158) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %160 = "cute.add_offset"(%109, %63) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %161 = "cute.add_offset"(%91, %63) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
        %162 = "builtin.unrealized_conversion_cast"(%160) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %163 = "builtin.unrealized_conversion_cast"(%161) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
        %164 = "llvm.load"(%162) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%164, %163) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %165 = "cute.add_offset"(%109, %62) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %166 = "cute.add_offset"(%91, %62) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
        %167 = "builtin.unrealized_conversion_cast"(%165) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %168 = "builtin.unrealized_conversion_cast"(%166) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
        %169 = "llvm.load"(%167) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%169, %168) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
    %23 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %24 = "cute.get_shape"(%23) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %25:3 = "cute.get_leaves"(%24) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %26 = "cute.to_int_tuple"(%25#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %27 = "cute.to_int_tuple"(%25#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %28 = "cute.to_int_tuple"(%25#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %29 = "cute.make_shape"(%26, %27, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %30 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %31 = "cute.make_layout"(%29, %7) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %32 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %33 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %34:5 = "cute.get_scalars"(%33) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %35 = "arith.ceildivsi"(%34#0, %6) : (i32, i32) -> i32
    %36 = "cute.make_shape"(%35, %34#1, %34#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %37 = "cute.make_stride"(%34#3, %34#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %38 = "cute.make_layout"(%36, %37) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %39 = "cute.make_view"(%32, %38) : (!cute.ptr<f32, gmem>, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !memref_gmem_f32_
    %40:3 = "cute.get_scalars"(%31) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %41 = "arith.ceildivsi"(%40#0, %6) : (i32, i32) -> i32
    %42 = "cute.make_shape"(%41, %40#1, %40#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %43 = "cute.make_layout"(%42, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %44 = "cute.make_view"(%30, %43) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %45:5 = "cute.get_scalars"(%13) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %46 = "arith.ceildivsi"(%45#0, %4) : (i32, i32) -> i32
    %47 = "cute.make_shape"(%46, %45#1, %45#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %48 = "cute.make_stride"(%45#3, %45#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %49 = "cute.make_layout"(%47, %48) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((512,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %50 = "cute.make_view"(%11, %49) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !memref_gmem_i8_
    %51 = "cute.size"(%38) <{mode = array<i32: 1>}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %52 = "cute.get_leaves"(%51) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %53 = "cute.get_scalars"(%52) : (!cute.int_tuple<"?">) -> i32
    %54 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %55 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %53, %0, %0, %54) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%55, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%55, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %56 = "cuda.launch_ex"(%55, %39, %50, %44, %18, %20, %22) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> !cuda.result
    %57 = "cuda.cast"(%56) : (!cuda.result) -> i32
    "cuda.return_if_error"(%57) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
