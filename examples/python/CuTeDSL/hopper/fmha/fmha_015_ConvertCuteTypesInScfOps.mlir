!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<16>, "(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "2:1">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "2:1">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000i64256i64i64i64_tensorptrf32gmemalign16o12561110i64000i64i64div256i641i64_tensor00000o1256111011000102561121314______Flo_0"}> ({
    ^bb0(%arg2: !memref_gmem_f16_, %arg3: !memref_gmem_f32_, %arg4: !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %arg5: i32, %arg6: i32, %arg7: i32, %arg8: i32, %arg9: i32):
      %53 = "cute.static"() : () -> !cute.shape<"(2,((1)))">
      %54 = "cute.static"() : () -> !cute.shape<"(2,(1))">
      %55 = "cute.static"() : () -> !cute.int_tuple<"1">
      %56 = "cute.static"() : () -> !cute.layout<"1:0">
      %57 = "cute.static"() : () -> !cute.layout<"(128,2):(2@1,1@1)">
      %58 = "cute.static"() : () -> !cute.shape<"(2)">
      %59 = "cute.static"() : () -> !cute.shape<"(128,2)">
      %60 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %61 = "cute.static"() : () -> !cute.shape<"((1,256,1,1,1))">
      %62 = "cute.static"() : () -> !cute.layout<"(128,2):(2,1)">
      %63 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %64 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %65 = "cute.make_coord"(%64) : (i32) -> !cute.coord<"(_,?)">
      %66 = "cute.get_layout"(%arg2) : (!memref_gmem_f16_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
      %67 = "cute.crd2idx"(%65, %66) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %68 = "cute.get_iter"(%arg2) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<16>>
      %69 = "cute.add_offset"(%68, %67) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f16, gmem>
      %70 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %71:10 = "cute.get_scalars"(%70) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64, i64)
      %72 = "cute.make_stride"(%71#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %73 = "cute.make_layout"(%61, %72) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1))">, !cute.stride<"((0,?{i64},0,0,0))">) -> !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %74 = "cute.crd2idx"(%65, %70) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %75 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %76 = "cute.add_offset"(%75, %74) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %77 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %78 = "cute.crd2idx"(%65, %77) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %79 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
      %80 = "cute.add_offset"(%79, %78) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">
      %81 = "cute.get_scalars"(%73) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">) -> i64
      %82 = "arith.muli"(%81, %60) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %83 = "cute.assume"(%82) : (i64) -> !cute.i64<divby 2>
      %84 = "cute.make_stride"(%83, %81) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %85 = "cute.make_layout"(%59, %84) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,2)">, !cute.stride<"(?{i64 div=2},?{i64})">) -> !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %86 = "cute.make_coord"(%63) : (i32) -> !cute.coord<"(?,_)">
      %87 = "cute.crd2idx"(%86, %62) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %88 = "cute.add_offset"(%69, %87) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %89:2 = "cute.get_scalars"(%85) <{only_dynamic}> : (!cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> (i64, i64)
      %90 = "cute.make_stride"(%89#1) : (i64) -> !cute.stride<"(?{i64})">
      %91 = "cute.make_layout"(%58, %90) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
      %92 = "cute.crd2idx"(%86, %85) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %93 = "cute.add_offset"(%76, %92) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %94 = "cute.crd2idx"(%86, %57) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %95 = "cute.add_offset"(%80, %94) : (!cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %96 = "cute.deref_arith_tuple_iter"(%95) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %97:5 = "cute.get_leaves"(%96) : (!cute.int_tuple<"(?,?{div=2},?,?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %98 = "cute.make_coord"(%97#0, %97#1, %97#2, %97#3, %97#4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %99 = "cute.make_coord"(%arg5, %arg6, %arg7, %arg8, %arg9) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %100:5 = "cute.get_scalars"(%98) : (!cute.coord<"(?,?{div=2},?,?,?)">) -> (i32, i32, i32, i32, i32)
      %101:5 = "cute.get_scalars"(%99) : (!cute.coord<"(?,?,?,?,?)">) -> (i32, i32, i32, i32, i32)
      %102 = "arith.cmpi"(%100#0, %101#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %103 = "arith.cmpi"(%100#1, %101#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %104 = "arith.andi"(%102, %103) : (i1, i1) -> i1
      %105 = "arith.cmpi"(%100#2, %101#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %106 = "arith.andi"(%104, %105) : (i1, i1) -> i1
      %107 = "arith.cmpi"(%100#3, %101#3) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %108 = "arith.andi"(%106, %107) : (i1, i1) -> i1
      %109 = "arith.cmpi"(%100#4, %101#4) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %110 = "arith.andi"(%108, %109) : (i1, i1) -> i1
      "scf.if"(%110) ({
        %111 = "cute.memref.alloca"() : () -> !memref_rmem_f16_
        %112 = "cute.get_iter"(%111) : (!memref_rmem_f16_) -> !cute.ptr<f16, rmem, align<32>>
        %113 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
        %114 = "cute.get_iter"(%113) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %115 = "builtin.unrealized_conversion_cast"(%88) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
        %116 = "builtin.unrealized_conversion_cast"(%112) : (!cute.ptr<f16, rmem, align<32>>) -> !llvm.ptr
        %117 = "llvm.load"(%115) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
        "llvm.store"(%117, %116) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
        %118 = "cute.add_offset"(%88, %55) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
        %119 = "cute.add_offset"(%112, %55) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
        %120 = "builtin.unrealized_conversion_cast"(%118) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
        %121 = "builtin.unrealized_conversion_cast"(%119) : (!cute.ptr<f16, rmem>) -> !llvm.ptr
        %122 = "llvm.load"(%120) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
        "llvm.store"(%122, %121) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
        %123 = "cute.memref.load_vec"(%111) : (!memref_rmem_f16_) -> vector<2xf16>
        %124 = "arith.extf"(%123) : (vector<2xf16>) -> vector<2xf32>
        "cute.memref.store_vec"(%124, %113) : (vector<2xf32>, !memref_rmem_f32_) -> ()
        %125 = "cute.append_to_rank"(%91, %56) <{rank = 2 : si32}> : (!cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">) -> !cute.layout<"(2,1):(?{i64},0)">
        %126 = "cute.get_scalars"(%125) <{only_dynamic}> : (!cute.layout<"(2,1):(?{i64},0)">) -> i64
        %127 = "cute.make_stride"(%126) : (i64) -> !cute.stride<"(?{i64},(0))">
        %128 = "cute.make_layout"(%54, %127) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,(1))">, !cute.stride<"(?{i64},(0))">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
        %129 = "cute.append_to_rank"(%128, %56) <{rank = 2 : si32}> : (!cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
        %130 = "cute.get_scalars"(%129) <{only_dynamic}> : (!cute.layout<"(2,(1)):(?{i64},(0))">) -> i64
        %131 = "cute.make_stride"(%130) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %132 = "cute.make_layout"(%53, %131) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,((1)))">, !cute.stride<"(?{i64},((0)))">) -> !cute.layout<"(2,((1))):(?{i64},((0)))">
        %133 = "cute.get_scalars"(%132) <{only_dynamic}> : (!cute.layout<"(2,((1))):(?{i64},((0)))">) -> i64
        %134 = "cute.make_stride"(%133) : (i64) -> !cute.stride<"(?{i64})">
        %135 = "cute.make_layout"(%58, %134) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
        %136 = "cute.get_scalars"(%135) <{only_dynamic}> : (!cute.layout<"(2):(?{i64})">) -> i64
        %137 = "builtin.unrealized_conversion_cast"(%114) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %138 = "builtin.unrealized_conversion_cast"(%93) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %139 = "llvm.load"(%137) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%139, %138) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        %140 = "cute.add_offset"(%114, %55) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %141 = "cute.make_int_tuple"(%136) : (i64) -> !cute.int_tuple<"?{i64}">
        %142 = "cute.add_offset"(%93, %141) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %143 = "builtin.unrealized_conversion_cast"(%140) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %144 = "builtin.unrealized_conversion_cast"(%142) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %145 = "llvm.load"(%143) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%145, %144) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f16_1, !memref_gmem_f32_1) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64i64i64_Tensorgmemoi64i64i641i64_1_2"}> ({
  ^bb0(%arg0: !memref_gmem_f16_1, %arg1: !memref_gmem_f32_1):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %3 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 256 : i64}> : () -> i64
    %5 = "cute.static"() : () -> !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %6 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %7 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">
    %8 = "cute.get_layout"(%arg0) : (!memref_gmem_f16_1) -> !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %9 = "cute.get_shape"(%8) : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> !cute.shape<"(?,?,?,?,?)">
    %10:5 = "cute.get_leaves"(%9) : (!cute.shape<"(?,?,?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %11 = "cute.to_int_tuple"(%10#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %12 = "cute.get_scalars"(%11) : (!cute.int_tuple<"?">) -> i32
    %13 = "cute.to_int_tuple"(%10#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %14 = "cute.get_scalars"(%13) : (!cute.int_tuple<"?">) -> i32
    %15 = "cute.to_int_tuple"(%10#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %16 = "cute.get_scalars"(%15) : (!cute.int_tuple<"?">) -> i32
    %17 = "cute.to_int_tuple"(%10#3) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %18 = "cute.get_scalars"(%17) : (!cute.int_tuple<"?">) -> i32
    %19 = "cute.to_int_tuple"(%10#4) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %20 = "cute.get_scalars"(%19) : (!cute.int_tuple<"?">) -> i32
    %21 = "cute.make_shape"(%11, %13, %15, %17, %19) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?,?)">
    %22 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
    %23 = "cute.make_layout"(%21, %7) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?,?)">, !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">) -> !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %24 = "cute.get_iter"(%arg0) : (!memref_gmem_f16_1) -> !cute.ptr<f16, gmem, align<16>>
    %25:9 = "cute.get_scalars"(%8) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64)
    %26 = "arith.ceildivsi"(%25#1, %6) : (i32, i32) -> i32
    %27 = "cute.make_shape"(%25#0, %26, %25#2, %25#3, %25#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %28 = "cute.make_stride"(%25#5, %25#6, %25#7, %25#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %29 = "cute.make_layout"(%27, %28) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %30 = "cute.make_view"(%24, %29) : (!cute.ptr<f16, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !memref_gmem_f16_
    %31:5 = "cute.get_scalars"(%23) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> (i32, i32, i32, i32, i32)
    %32 = "arith.ceildivsi"(%31#1, %6) : (i32, i32) -> i32
    %33 = "cute.make_shape"(%31#0, %32, %31#2, %31#3, %31#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %34 = "cute.make_layout"(%33, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %35 = "cute.make_view"(%22, %34) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %36 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem, align<16>>
    %37 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %38:9 = "cute.get_scalars"(%37) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64)
    %39 = "arith.ceildivsi"(%38#1, %6) : (i32, i32) -> i32
    %40 = "arith.muli"(%38#6, %4) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %41 = "cute.make_shape"(%38#0, %39, %38#2, %38#3, %38#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %42 = "cute.assume"(%40) : (i64) -> !cute.i64<divby 256>
    %43 = "cute.make_stride"(%38#6, %38#5, %42, %38#7, %38#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %44 = "cute.make_layout"(%41, %43) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %45 = "cute.make_view"(%36, %44) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !memref_gmem_f32_
    %46 = "cute.size"(%29) <{mode = array<i32: 1>}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %47 = "cute.get_leaves"(%46) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %48 = "cute.get_scalars"(%47) : (!cute.int_tuple<"?">) -> i32
    %49 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %50 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %48, %0, %0, %49) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%50, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%50, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %51 = "cuda.launch_ex"(%50, %30, %45, %35, %12, %14, %16, %18, %20) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000i64256i64i64i64_tensorptrf32gmemalign16o12561110i64000i64i64div256i641i64_tensor00000o1256111011000102561121314______Flo_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> !cuda.result
    %52 = "cuda.cast"(%51) : (!cuda.result) -> i32
    "cuda.return_if_error"(%52) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
