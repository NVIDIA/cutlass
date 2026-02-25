!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, "((1,256,1,1,1)):((0,1,0,0,0))">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, "(128,2):(2,1)">
!memref_gmem_f16_3 = !cute.memref<f16, gmem, "(2):(1)">
!memref_gmem_f16_4 = !cute.memref<f16, gmem, "(2,1):(1,0)">
!memref_gmem_f16_5 = !cute.memref<f16, gmem, "(2,(1)):(1,(0))">
!memref_gmem_f16_6 = !cute.memref<f16, gmem, align<16>, "(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,256,1,1,1)):((0,?{i64},0,0,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,2):(?{i64 div=2},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(2):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(2,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(2,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, align<16>, "(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "2:1">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<32>, "(2,1):(1,0)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "(2,(1)):(1,(0))">
!memref_rmem_f16_3 = !cute.memref<f16, rmem, align<32>, "(2):(1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "2:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(2,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(2,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(2):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000i64256i64i64i64_tensorptrf32gmemalign16o12561110i64000i64i64div256i641i64_tensor00000o1256111011000102561121314______Flo_0"}> ({
    ^bb0(%arg2: !memref_gmem_f16_, %arg3: !memref_gmem_f32_, %arg4: !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %arg5: i32, %arg6: i32, %arg7: i32, %arg8: i32, %arg9: i32):
      %72 = "cute.static"() : () -> !cute.layout<"(128,2):(2,1)">
      %73 = "cute.static"() : () -> !cute.layout<"(128,2):(2,1)">
      %74 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %75 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %76 = "cute.make_coord"(%75) : (i32) -> !cute.coord<"(_,?)">
      %77 = "cute.get_layout"(%arg2) : (!memref_gmem_f16_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
      %78 = "cute.crd2idx"(%76, %77) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %79 = "cute.get_iter"(%arg2) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<16>>
      %80 = "cute.add_offset"(%79, %78) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f16, gmem>
      %81 = "cute.make_view"(%80) : (!cute.ptr<f16, gmem>) -> !memref_gmem_f16_1
      %82 = "cute.make_coord"(%75) : (i32) -> !cute.coord<"(_,?)">
      %83 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %84:10 = "cute.get_scalars"(%83) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64, i64)
      %85 = "cute.static"() : () -> !cute.shape<"((1,256,1,1,1))">
      %86 = "cute.make_stride"(%84#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %87 = "cute.make_layout"(%85, %86) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1))">, !cute.stride<"((0,?{i64},0,0,0))">) -> !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %88 = "cute.crd2idx"(%82, %83) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %89 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %90 = "cute.add_offset"(%89, %88) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %91 = "cute.make_view"(%90, %87) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">) -> !memref_gmem_f32_1
      %92 = "cute.make_coord"(%75) : (i32) -> !cute.coord<"(_,?)">
      %93 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %94 = "cute.crd2idx"(%92, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %95 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
      %96 = "cute.add_offset"(%95, %94) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">
      %97 = "cute.make_view"(%96) : (!cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">) -> !cute.coord_tensor<"(?,?{div=256},?,?,?)", "((1,256,1,1,1)):((0,1@1,0,0,0))">
      %98 = "cute.get_iter"(%81) : (!memref_gmem_f16_1) -> !cute.ptr<f16, gmem>
      %99 = "cute.make_view"(%98) : (!cute.ptr<f16, gmem>) -> !memref_gmem_f16_2
      %100 = "cute.get_iter"(%91) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %101 = "cute.get_layout"(%91) : (!memref_gmem_f32_1) -> !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %102 = "cute.get_scalars"(%101) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">) -> i64
      %103 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %104 = "arith.muli"(%102, %103) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %105 = "cute.static"() : () -> !cute.shape<"(128,2)">
      %106 = "cute.assume"(%104) : (i64) -> !cute.i64<divby 2>
      %107 = "cute.make_stride"(%106, %102) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %108 = "cute.make_layout"(%105, %107) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,2)">, !cute.stride<"(?{i64 div=2},?{i64})">) -> !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %109 = "cute.make_view"(%100, %108) : (!cute.ptr<f32, gmem>, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !memref_gmem_f32_2
      %110 = "cute.get_iter"(%97) : (!cute.coord_tensor<"(?,?{div=256},?,?,?)", "((1,256,1,1,1)):((0,1@1,0,0,0))">) -> !cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">
      %111 = "cute.make_view"(%110) : (!cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">) -> !cute.coord_tensor<"(?,?{div=256},?,?,?)", "(128,2):(2@1,1@1)">
      %112 = "cute.make_coord"(%74) : (i32) -> !cute.coord<"(?,_)">
      %113 = "cute.static"() : () -> !cute.layout<"(128,2):(2,1)">
      %114 = "cute.crd2idx"(%112, %113) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %115 = "cute.get_iter"(%99) : (!memref_gmem_f16_2) -> !cute.ptr<f16, gmem>
      %116 = "cute.add_offset"(%115, %114) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %117 = "cute.make_view"(%116) : (!cute.ptr<f16, gmem>) -> !memref_gmem_f16_3
      %118 = "cute.get_iter"(%117) : (!memref_gmem_f16_3) -> !cute.ptr<f16, gmem>
      %119 = "cute.make_coord"(%74) : (i32) -> !cute.coord<"(?,_)">
      %120 = "cute.get_layout"(%109) : (!memref_gmem_f32_2) -> !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %121:2 = "cute.get_scalars"(%120) <{only_dynamic}> : (!cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> (i64, i64)
      %122 = "cute.static"() : () -> !cute.shape<"(2)">
      %123 = "cute.make_stride"(%121#1) : (i64) -> !cute.stride<"(?{i64})">
      %124 = "cute.make_layout"(%122, %123) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
      %125 = "cute.crd2idx"(%119, %120) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %126 = "cute.get_iter"(%109) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %127 = "cute.add_offset"(%126, %125) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %128 = "cute.make_view"(%127, %124) : (!cute.ptr<f32, gmem>, !cute.layout<"(2):(?{i64})">) -> !memref_gmem_f32_3
      %129 = "cute.get_iter"(%128) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %130 = "cute.make_coord"(%74) : (i32) -> !cute.coord<"(?,_)">
      %131 = "cute.static"() : () -> !cute.layout<"(128,2):(2@1,1@1)">
      %132 = "cute.crd2idx"(%130, %131) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %133 = "cute.get_iter"(%111) : (!cute.coord_tensor<"(?,?{div=256},?,?,?)", "(128,2):(2@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">
      %134 = "cute.add_offset"(%133, %132) : (!cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %135 = "cute.make_view"(%134) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">) -> !cute.coord_tensor<"(?,?{div=2},?,?,?)", "(2):(1@1)">
      %136 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %137 = "cute.get_iter"(%135) : (!cute.coord_tensor<"(?,?{div=2},?,?,?)", "(2):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %138 = "cute.add_offset"(%137, %136) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %139 = "cute.make_view"(%138) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">) -> !cute.coord_tensor<"(?,?{div=2},?,?,?)", "():()">
      %140 = "cute.get_iter"(%139) : (!cute.coord_tensor<"(?,?{div=2},?,?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %141 = "cute.deref_arith_tuple_iter"(%140) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %142:5 = "cute.get_leaves"(%141) : (!cute.int_tuple<"(?,?{div=2},?,?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %143 = "cute.make_coord"(%142#0, %142#1, %142#2, %142#3, %142#4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %144 = "cute.make_coord"(%arg5, %arg6, %arg7, %arg8, %arg9) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %145:5 = "cute.get_scalars"(%143) : (!cute.coord<"(?,?{div=2},?,?,?)">) -> (i32, i32, i32, i32, i32)
      %146:5 = "cute.get_scalars"(%144) : (!cute.coord<"(?,?,?,?,?)">) -> (i32, i32, i32, i32, i32)
      %147 = "arith.constant"() <{value = true}> : () -> i1
      %148 = "arith.cmpi"(%145#0, %146#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %149 = "arith.andi"(%147, %148) : (i1, i1) -> i1
      %150 = "arith.cmpi"(%145#1, %146#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %151 = "arith.andi"(%149, %150) : (i1, i1) -> i1
      %152 = "arith.cmpi"(%145#2, %146#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %153 = "arith.andi"(%151, %152) : (i1, i1) -> i1
      %154 = "arith.cmpi"(%145#3, %146#3) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %155 = "arith.andi"(%153, %154) : (i1, i1) -> i1
      %156 = "arith.cmpi"(%145#4, %146#4) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %157 = "arith.andi"(%155, %156) : (i1, i1) -> i1
      "scf.if"(%157) ({
        %158 = "cute.static"() : () -> !cute.layout<"2:1">
        %159 = "cute.memref.alloca"(%158) : (!cute.layout<"2:1">) -> !memref_rmem_f16_
        %160 = "cute.get_iter"(%159) : (!memref_rmem_f16_) -> !cute.ptr<f16, rmem, align<32>>
        %161 = "cute.static"() : () -> !cute.layout<"2:1">
        %162 = "cute.memref.alloca"(%161) : (!cute.layout<"2:1">) -> !memref_rmem_f32_
        %163 = "cute.get_iter"(%162) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %164 = "cute.static"() : () -> !cute.layout<"(2,1):(1,0)">
        %165 = "cute.make_view"(%118, %164) : (!cute.ptr<f16, gmem>, !cute.layout<"(2,1):(1,0)">) -> !memref_gmem_f16_4
        %166 = "cute.get_iter"(%165) : (!memref_gmem_f16_4) -> !cute.ptr<f16, gmem>
        %167 = "cute.make_view"(%166) : (!cute.ptr<f16, gmem>) -> !memref_gmem_f16_5
        %168 = "cute.static"() : () -> !cute.layout<"(2,1):(1,0)">
        %169 = "cute.make_view"(%160, %168) : (!cute.ptr<f16, rmem, align<32>>, !cute.layout<"(2,1):(1,0)">) -> !memref_rmem_f16_1
        %170 = "cute.get_iter"(%169) : (!memref_rmem_f16_1) -> !cute.ptr<f16, rmem, align<32>>
        %171 = "cute.make_view"(%170) : (!cute.ptr<f16, rmem, align<32>>) -> !memref_rmem_f16_2
        %172 = "cute.static"() : () -> !cute.layout<"1:0">
        %173 = "cute.get_iter"(%167) : (!memref_gmem_f16_5) -> !cute.ptr<f16, gmem>
        %174 = "cute.get_iter"(%171) : (!memref_rmem_f16_2) -> !cute.ptr<f16, rmem, align<32>>
        %175 = "cute.static"() : () -> !cute.int_tuple<"1">
        %176 = "cute.get_scalars"(%175) : (!cute.int_tuple<"1">) -> i32
        %177 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %178 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%177, %176, %178) ({
        ^bb0(%arg11: i32):
          %234 = "cute.static"() : () -> !cute.layout<"(2):(1)">
          %235 = "cute.static"() : () -> !cute.int_tuple<"0">
          %236 = "cute.add_offset"(%173, %235) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f16, gmem>
          %237 = "cute.make_view"(%236, %234) : (!cute.ptr<f16, gmem>, !cute.layout<"(2):(1)">) -> !memref_gmem_f16_3
          %238 = "cute.static"() : () -> !cute.layout<"(2):(1)">
          %239 = "cute.static"() : () -> !cute.int_tuple<"0">
          %240 = "cute.add_offset"(%174, %239) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, rmem, align<32>>
          %241 = "cute.make_view"(%240, %238) : (!cute.ptr<f16, rmem, align<32>>, !cute.layout<"(2):(1)">) -> !memref_rmem_f16_3
          %242 = "cute.get_iter"(%237) : (!memref_gmem_f16_3) -> !cute.ptr<f16, gmem>
          %243 = "cute.get_iter"(%241) : (!memref_rmem_f16_3) -> !cute.ptr<f16, rmem, align<32>>
          %244 = "builtin.unrealized_conversion_cast"(%242) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
          %245 = "builtin.unrealized_conversion_cast"(%243) : (!cute.ptr<f16, rmem, align<32>>) -> !llvm.ptr
          %246 = "llvm.load"(%244) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
          "llvm.store"(%246, %245) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
          %247 = "cute.static"() : () -> !cute.int_tuple<"1">
          %248 = "cute.add_offset"(%242, %247) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
          %249 = "cute.static"() : () -> !cute.int_tuple<"1">
          %250 = "cute.add_offset"(%243, %249) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
          %251 = "builtin.unrealized_conversion_cast"(%248) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
          %252 = "builtin.unrealized_conversion_cast"(%250) : (!cute.ptr<f16, rmem>) -> !llvm.ptr
          %253 = "llvm.load"(%251) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
          "llvm.store"(%253, %252) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %179 = "cute.memref.load_vec"(%159) : (!memref_rmem_f16_) -> vector<2xf16>
        %180 = "arith.extf"(%179) : (vector<2xf16>) -> vector<2xf32>
        "cute.memref.store_vec"(%180, %162) : (vector<2xf32>, !memref_rmem_f32_) -> ()
        %181 = "cute.static"() : () -> !cute.layout<"(2,1):(1,0)">
        %182 = "cute.make_view"(%163, %181) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(2,1):(1,0)">) -> !memref_rmem_f32_1
        %183 = "cute.get_iter"(%182) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %184 = "cute.make_view"(%183) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %185 = "cute.get_layout"(%128) : (!memref_gmem_f32_3) -> !cute.layout<"(2):(?{i64})">
        %186 = "cute.static"() : () -> !cute.layout<"1:0">
        %187 = "cute.append_to_rank"(%185, %186) <{rank = 2 : si32}> : (!cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">) -> !cute.layout<"(2,1):(?{i64},0)">
        %188 = "cute.make_view"(%129, %187) : (!cute.ptr<f32, gmem>, !cute.layout<"(2,1):(?{i64},0)">) -> !memref_gmem_f32_4
        %189 = "cute.get_iter"(%188) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %190 = "cute.get_layout"(%188) : (!memref_gmem_f32_4) -> !cute.layout<"(2,1):(?{i64},0)">
        %191 = "cute.get_scalars"(%190) <{only_dynamic}> : (!cute.layout<"(2,1):(?{i64},0)">) -> i64
        %192 = "cute.static"() : () -> !cute.shape<"(2,(1))">
        %193 = "cute.make_stride"(%191) : (i64) -> !cute.stride<"(?{i64},(0))">
        %194 = "cute.make_layout"(%192, %193) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,(1))">, !cute.stride<"(?{i64},(0))">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
        %195 = "cute.make_view"(%189, %194) : (!cute.ptr<f32, gmem>, !cute.layout<"(2,(1)):(?{i64},(0))">) -> !memref_gmem_f32_5
        %196 = "cute.static"() : () -> !cute.layout<"1:0">
        %197 = "cute.get_iter"(%184) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %198 = "cute.get_iter"(%195) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %199 = "cute.get_layout"(%195) : (!memref_gmem_f32_5) -> !cute.layout<"(2,(1)):(?{i64},(0))">
        %200 = "cute.append_to_rank"(%199, %196) <{rank = 2 : si32}> : (!cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
        %201 = "cute.get_scalars"(%200) <{only_dynamic}> : (!cute.layout<"(2,(1)):(?{i64},(0))">) -> i64
        %202 = "cute.static"() : () -> !cute.shape<"(2,((1)))">
        %203 = "cute.make_stride"(%201) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %204 = "cute.make_layout"(%202, %203) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,((1)))">, !cute.stride<"(?{i64},((0)))">) -> !cute.layout<"(2,((1))):(?{i64},((0)))">
        %205 = "cute.static"() : () -> !cute.int_tuple<"1">
        %206 = "cute.get_scalars"(%205) : (!cute.int_tuple<"1">) -> i32
        %207 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %208 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%207, %206, %208) ({
        ^bb0(%arg10: i32):
          %209 = "cute.static"() : () -> !cute.layout<"(2):(1)">
          %210 = "cute.static"() : () -> !cute.int_tuple<"0">
          %211 = "cute.add_offset"(%197, %210) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %212 = "cute.make_view"(%211, %209) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(2):(1)">) -> !memref_rmem_f32_3
          %213 = "cute.get_scalars"(%204) <{only_dynamic}> : (!cute.layout<"(2,((1))):(?{i64},((0)))">) -> i64
          %214 = "cute.static"() : () -> !cute.shape<"(2)">
          %215 = "cute.make_stride"(%213) : (i64) -> !cute.stride<"(?{i64})">
          %216 = "cute.make_layout"(%214, %215) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
          %217 = "cute.static"() : () -> !cute.int_tuple<"0">
          %218 = "cute.add_offset"(%198, %217) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %219 = "cute.make_view"(%218, %216) : (!cute.ptr<f32, gmem>, !cute.layout<"(2):(?{i64})">) -> !memref_gmem_f32_3
          %220 = "cute.get_iter"(%212) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem, align<32>>
          %221 = "cute.get_iter"(%219) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %222 = "cute.get_layout"(%219) : (!memref_gmem_f32_3) -> !cute.layout<"(2):(?{i64})">
          %223 = "cute.get_scalars"(%222) <{only_dynamic}> : (!cute.layout<"(2):(?{i64})">) -> i64
          %224 = "builtin.unrealized_conversion_cast"(%220) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %225 = "builtin.unrealized_conversion_cast"(%221) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %226 = "llvm.load"(%224) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%226, %225) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          %227 = "cute.static"() : () -> !cute.int_tuple<"1">
          %228 = "cute.add_offset"(%220, %227) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %229 = "cute.make_int_tuple"(%223) : (i64) -> !cute.int_tuple<"?{i64}">
          %230 = "cute.add_offset"(%221, %229) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %231 = "builtin.unrealized_conversion_cast"(%228) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %232 = "builtin.unrealized_conversion_cast"(%230) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %233 = "llvm.load"(%231) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%233, %232) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f16_6, !memref_gmem_f32_6) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64i64i64_Tensorgmemoi64i64i641i64_1_2"}> ({
  ^bb0(%arg0: !memref_gmem_f16_6, %arg1: !memref_gmem_f32_6):
    %0 = "cute.get_layout"(%arg0) : (!memref_gmem_f16_6) -> !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %1 = "cute.get_shape"(%0) : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> !cute.shape<"(?,?,?,?,?)">
    %2:5 = "cute.get_leaves"(%1) : (!cute.shape<"(?,?,?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %3 = "cute.to_int_tuple"(%2#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %4 = "cute.get_scalars"(%3) : (!cute.int_tuple<"?">) -> i32
    %5 = "cute.to_int_tuple"(%2#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %6 = "cute.get_scalars"(%5) : (!cute.int_tuple<"?">) -> i32
    %7 = "cute.to_int_tuple"(%2#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %8 = "cute.get_scalars"(%7) : (!cute.int_tuple<"?">) -> i32
    %9 = "cute.to_int_tuple"(%2#3) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %10 = "cute.get_scalars"(%9) : (!cute.int_tuple<"?">) -> i32
    %11 = "cute.to_int_tuple"(%2#4) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %12 = "cute.get_scalars"(%11) : (!cute.int_tuple<"?">) -> i32
    %13 = "cute.get_layout"(%arg0) : (!memref_gmem_f16_6) -> !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %14 = "cute.get_shape"(%13) : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> !cute.shape<"(?,?,?,?,?)">
    %15:5 = "cute.get_leaves"(%14) : (!cute.shape<"(?,?,?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %16 = "cute.to_int_tuple"(%15#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %17 = "cute.to_int_tuple"(%15#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %18 = "cute.to_int_tuple"(%15#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %19 = "cute.to_int_tuple"(%15#3) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %20 = "cute.to_int_tuple"(%15#4) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.make_shape"(%16, %17, %18, %19, %20) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?,?)">
    %22 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
    %23 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">
    %24 = "cute.make_layout"(%21, %23) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?,?)">, !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">) -> !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %25 = "cute.make_view"(%22, %24) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %26 = "cute.get_iter"(%arg0) : (!memref_gmem_f16_6) -> !cute.ptr<f16, gmem, align<16>>
    %27 = "cute.get_layout"(%arg0) : (!memref_gmem_f16_6) -> !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %28:9 = "cute.get_scalars"(%27) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64)
    %29 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %30 = "arith.ceildivsi"(%28#1, %29) : (i32, i32) -> i32
    %31 = "cute.make_shape"(%28#0, %30, %28#2, %28#3, %28#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %32 = "cute.make_stride"(%28#5, %28#6, %28#7, %28#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %33 = "cute.make_layout"(%31, %32) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %34 = "cute.make_view"(%26, %33) : (!cute.ptr<f16, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !memref_gmem_f16_
    %35 = "cute.get_iter"(%25) : (!cute.coord_tensor<"(0,0,0,0,0)", "(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
    %36 = "cute.get_layout"(%25) : (!cute.coord_tensor<"(0,0,0,0,0)", "(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %37:5 = "cute.get_scalars"(%36) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> (i32, i32, i32, i32, i32)
    %38 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %39 = "arith.ceildivsi"(%37#1, %38) : (i32, i32) -> i32
    %40 = "cute.make_shape"(%37#0, %39, %37#2, %37#3, %37#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %41 = "cute.static"() : () -> !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %42 = "cute.make_layout"(%40, %41) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %43 = "cute.make_view"(%35, %42) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %44 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem, align<16>>
    %45 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %46:9 = "cute.get_scalars"(%45) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64)
    %47 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %48 = "arith.ceildivsi"(%46#1, %47) : (i32, i32) -> i32
    %49 = "arith.constant"() <{value = 256 : i64}> : () -> i64
    %50 = "arith.muli"(%46#6, %49) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %51 = "cute.make_shape"(%46#0, %48, %46#2, %46#3, %46#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %52 = "cute.assume"(%50) : (i64) -> !cute.i64<divby 256>
    %53 = "cute.make_stride"(%46#6, %46#5, %52, %46#7, %46#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %54 = "cute.make_layout"(%51, %53) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %55 = "cute.make_view"(%44, %54) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !memref_gmem_f32_
    %56 = "cute.get_layout"(%34) : (!memref_gmem_f16_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %57 = "cute.size"(%56) <{mode = array<i32: 1>}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %58 = "cute.get_leaves"(%57) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %59 = "cute.get_scalars"(%58) : (!cute.int_tuple<"?">) -> i32
    %60 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %61 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %62 = "cuda.cast"(%61) : (i64) -> !cuda.stream
    %63 = "arith.extsi"(%60) : (i32) -> i64
    %64 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %65 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %66 = "cuda.launch_cfg.create"(%64, %65, %65, %63, %59, %65, %65, %62) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %67 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%66, %67) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %68 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%66, %68) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %69 = "cuda.launch_ex"(%66, %34, %55, %43, %4, %6, %8, %10, %12) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000i64256i64i64i64_tensorptrf32gmemalign16o12561110i64000i64i64div256i641i64_tensor00000o1256111011000102561121314______Flo_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> !cuda.result
    %70 = "cuda.cast"(%69) : (!cuda.result) -> i32
    "cuda.return_if_error"(%70) : (i32) -> ()
    %71 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%71) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
