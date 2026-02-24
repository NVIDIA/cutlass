!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1024,1,1)):((1,0,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i4_ = !cute.memref<i4, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((512,1,1)):((1,0,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(8,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(8,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_i8_, %arg4: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %70 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %71 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %72 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %73 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %74 = "cute.make_coord"(%73) : (i32) -> !cute.coord<"(_,?)">
      %75 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %76 = "cute.crd2idx"(%74, %75) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %77 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %78 = "cute.add_offset"(%77, %76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %79 = "cute.make_view"(%78) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_1
      %80 = "cute.make_coord"(%73) : (i32) -> !cute.coord<"(_,?)">
      %81 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %82 = "cute.crd2idx"(%80, %81) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %83 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %84 = "cute.add_offset"(%83, %82) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %85 = "cute.make_view"(%84) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_1
      %86 = "cute.make_coord"(%73) : (i32) -> !cute.coord<"(_,?)">
      %87 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %88 = "cute.crd2idx"(%86, %87) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %89 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %90 = "cute.add_offset"(%89, %88) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %91 = "cute.make_view"(%90) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">) -> !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %92 = "cute.get_iter"(%79) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %93 = "cute.make_view"(%92) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_2
      %94 = "cute.get_iter"(%85) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %95 = "cute.make_view"(%94) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_2
      %96 = "cute.get_iter"(%91) : (!cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %97 = "cute.make_view"(%96) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">) -> !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %98 = "cute.make_coord"(%72) : (i32) -> !cute.coord<"(?,_)">
      %99 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %100 = "cute.crd2idx"(%98, %99) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %101 = "cute.get_iter"(%93) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %102 = "cute.add_offset"(%101, %100) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %103 = "cute.make_view"(%102) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_3
      %104 = "cute.get_iter"(%103) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %105 = "cute.make_coord"(%72) : (i32) -> !cute.coord<"(?,_)">
      %106 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %107 = "cute.crd2idx"(%105, %106) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %108 = "cute.get_iter"(%95) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %109 = "cute.add_offset"(%108, %107) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %110 = "cute.make_view"(%109) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_3
      %111 = "cute.get_iter"(%110) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %112 = "cute.make_coord"(%72) : (i32) -> !cute.coord<"(?,_)">
      %113 = "cute.static"() : () -> !cute.layout<"(128,8):(8@0,1@0)">
      %114 = "cute.crd2idx"(%112, %113) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %115 = "cute.get_iter"(%97) : (!cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %116 = "cute.add_offset"(%115, %114) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %117 = "cute.make_view"(%116) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %118 = "cute.static"() : () -> !cute.int_tuple<"(0)">
      %119 = "cute.get_iter"(%117) : (!cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %120 = "cute.add_offset"(%119, %118) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">, !cute.int_tuple<"(0)">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %121 = "cute.make_view"(%120) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %122 = "cute.get_iter"(%121) : (!cute.coord_tensor<"(?{div=8},?,?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %123 = "cute.deref_arith_tuple_iter"(%122) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %124:3 = "cute.get_leaves"(%123) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %125 = "cute.make_coord"(%124#0, %124#1, %124#2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %126 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %127:3 = "cute.get_scalars"(%125) : (!cute.coord<"(?{div=8},?,?)">) -> (i32, i32, i32)
      %128:3 = "cute.get_scalars"(%126) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %129 = "arith.constant"() <{value = true}> : () -> i1
      %130 = "arith.cmpi"(%127#0, %128#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %131 = "arith.andi"(%129, %130) : (i1, i1) -> i1
      %132 = "arith.cmpi"(%127#1, %128#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %133 = "arith.andi"(%131, %132) : (i1, i1) -> i1
      %134 = "arith.cmpi"(%127#2, %128#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %135 = "arith.andi"(%133, %134) : (i1, i1) -> i1
      "scf.if"(%135) ({
        %136 = "cute.static"() : () -> !cute.layout<"8:1">
        %137 = "cute.memref.alloca"(%136) : (!cute.layout<"8:1">) -> !memref_rmem_f32_
        %138 = "cute.get_iter"(%137) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %139 = "cute.static"() : () -> !cute.layout<"4:1">
        %140 = "cute.memref.alloca"(%139) : (!cute.layout<"4:1">) -> !memref_rmem_i8_
        %141 = "cute.get_iter"(%140) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %142 = "cute.static"() : () -> !cute.layout<"(8,1):(1,0)">
        %143 = "cute.make_view"(%104, %142) : (!cute.ptr<f32, gmem>, !cute.layout<"(8,1):(1,0)">) -> !memref_gmem_f32_4
        %144 = "cute.get_iter"(%143) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %145 = "cute.make_view"(%144) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_5
        %146 = "cute.static"() : () -> !cute.layout<"(8,1):(1,0)">
        %147 = "cute.make_view"(%138, %146) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8,1):(1,0)">) -> !memref_rmem_f32_1
        %148 = "cute.get_iter"(%147) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %149 = "cute.make_view"(%148) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %150 = "cute.static"() : () -> !cute.layout<"1:0">
        %151 = "cute.get_iter"(%145) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %152 = "cute.get_iter"(%149) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %153 = "cute.static"() : () -> !cute.int_tuple<"1">
        %154 = "cute.get_scalars"(%153) : (!cute.int_tuple<"1">) -> i32
        %155 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %156 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%155, %154, %156) ({
        ^bb0(%arg9: i32):
          %212 = "cute.static"() : () -> !cute.layout<"(8):(1)">
          %213 = "cute.static"() : () -> !cute.int_tuple<"0">
          %214 = "cute.add_offset"(%151, %213) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %215 = "cute.make_view"(%214, %212) : (!cute.ptr<f32, gmem>, !cute.layout<"(8):(1)">) -> !memref_gmem_f32_3
          %216 = "cute.static"() : () -> !cute.layout<"(8):(1)">
          %217 = "cute.static"() : () -> !cute.int_tuple<"0">
          %218 = "cute.add_offset"(%152, %217) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %219 = "cute.make_view"(%218, %216) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8):(1)">) -> !memref_rmem_f32_3
          %220 = "cute.get_iter"(%215) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %221 = "cute.get_iter"(%219) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem, align<32>>
          %222 = "builtin.unrealized_conversion_cast"(%220) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %223 = "builtin.unrealized_conversion_cast"(%221) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %224 = "llvm.load"(%222) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%224, %223) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %225 = "cute.static"() : () -> !cute.int_tuple<"1">
          %226 = "cute.add_offset"(%220, %225) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %227 = "cute.static"() : () -> !cute.int_tuple<"1">
          %228 = "cute.add_offset"(%221, %227) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %229 = "builtin.unrealized_conversion_cast"(%226) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %230 = "builtin.unrealized_conversion_cast"(%228) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %231 = "llvm.load"(%229) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%231, %230) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %232 = "cute.static"() : () -> !cute.int_tuple<"2">
          %233 = "cute.add_offset"(%220, %232) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %234 = "cute.static"() : () -> !cute.int_tuple<"2">
          %235 = "cute.add_offset"(%221, %234) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %236 = "builtin.unrealized_conversion_cast"(%233) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %237 = "builtin.unrealized_conversion_cast"(%235) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %238 = "llvm.load"(%236) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%238, %237) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %239 = "cute.static"() : () -> !cute.int_tuple<"3">
          %240 = "cute.add_offset"(%220, %239) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %241 = "cute.static"() : () -> !cute.int_tuple<"3">
          %242 = "cute.add_offset"(%221, %241) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %243 = "builtin.unrealized_conversion_cast"(%240) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %244 = "builtin.unrealized_conversion_cast"(%242) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %245 = "llvm.load"(%243) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%245, %244) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %246 = "cute.static"() : () -> !cute.int_tuple<"4">
          %247 = "cute.add_offset"(%220, %246) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %248 = "cute.static"() : () -> !cute.int_tuple<"4">
          %249 = "cute.add_offset"(%221, %248) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %250 = "builtin.unrealized_conversion_cast"(%247) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %251 = "builtin.unrealized_conversion_cast"(%249) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %252 = "llvm.load"(%250) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%252, %251) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %253 = "cute.static"() : () -> !cute.int_tuple<"5">
          %254 = "cute.add_offset"(%220, %253) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %255 = "cute.static"() : () -> !cute.int_tuple<"5">
          %256 = "cute.add_offset"(%221, %255) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %257 = "builtin.unrealized_conversion_cast"(%254) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %258 = "builtin.unrealized_conversion_cast"(%256) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %259 = "llvm.load"(%257) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%259, %258) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %260 = "cute.static"() : () -> !cute.int_tuple<"6">
          %261 = "cute.add_offset"(%220, %260) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %262 = "cute.static"() : () -> !cute.int_tuple<"6">
          %263 = "cute.add_offset"(%221, %262) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %264 = "builtin.unrealized_conversion_cast"(%261) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %265 = "builtin.unrealized_conversion_cast"(%263) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %266 = "llvm.load"(%264) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%266, %265) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %267 = "cute.static"() : () -> !cute.int_tuple<"7">
          %268 = "cute.add_offset"(%220, %267) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %269 = "cute.static"() : () -> !cute.int_tuple<"7">
          %270 = "cute.add_offset"(%221, %269) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %271 = "builtin.unrealized_conversion_cast"(%268) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %272 = "builtin.unrealized_conversion_cast"(%270) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %273 = "llvm.load"(%271) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%273, %272) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %157 = "cute.memref.load_vec"(%137) : (!memref_rmem_f32_) -> vector<8xf32>
        %158 = "arith.fptosi"(%157) : (vector<8xf32>) -> vector<8xi4>
        %159 = "cute.static"() : () -> !cute.layout<"8:1">
        %160 = "cute.recast_layout"(%159) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %161 = "builtin.unrealized_conversion_cast"(%158) : (vector<8xi4>) -> vector<8xi4>
        %162 = "vector.bitcast"(%161) : (vector<8xi4>) -> vector<4xi8>
        "cute.memref.store_vec"(%162, %140) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %163 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %164 = "cute.make_view"(%141, %163) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_i8_1
        %165 = "cute.get_iter"(%164) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %166 = "cute.make_view"(%165) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %167 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %168 = "cute.make_view"(%111, %167) : (!cute.ptr<i8, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_i8_4
        %169 = "cute.get_iter"(%168) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %170 = "cute.make_view"(%169) : (!cute.ptr<i8, gmem>) -> !memref_gmem_i8_5
        %171 = "cute.static"() : () -> !cute.layout<"1:0">
        %172 = "cute.get_iter"(%166) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %173 = "cute.get_iter"(%170) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %174 = "cute.static"() : () -> !cute.int_tuple<"1">
        %175 = "cute.get_scalars"(%174) : (!cute.int_tuple<"1">) -> i32
        %176 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %177 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%176, %175, %177) ({
        ^bb0(%arg8: i32):
          %178 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %179 = "cute.static"() : () -> !cute.int_tuple<"0">
          %180 = "cute.add_offset"(%172, %179) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %181 = "cute.make_view"(%180, %178) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_i8_3
          %182 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %183 = "cute.static"() : () -> !cute.int_tuple<"0">
          %184 = "cute.add_offset"(%173, %183) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %185 = "cute.make_view"(%184, %182) : (!cute.ptr<i8, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_i8_3
          %186 = "cute.get_iter"(%181) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
          %187 = "cute.get_iter"(%185) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
          %188 = "builtin.unrealized_conversion_cast"(%186) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
          %189 = "builtin.unrealized_conversion_cast"(%187) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %190 = "llvm.load"(%188) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%190, %189) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %191 = "cute.static"() : () -> !cute.int_tuple<"1">
          %192 = "cute.add_offset"(%186, %191) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %193 = "cute.static"() : () -> !cute.int_tuple<"1">
          %194 = "cute.add_offset"(%187, %193) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %195 = "builtin.unrealized_conversion_cast"(%192) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %196 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %197 = "llvm.load"(%195) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%197, %196) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %198 = "cute.static"() : () -> !cute.int_tuple<"2">
          %199 = "cute.add_offset"(%186, %198) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %200 = "cute.static"() : () -> !cute.int_tuple<"2">
          %201 = "cute.add_offset"(%187, %200) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %202 = "builtin.unrealized_conversion_cast"(%199) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
          %203 = "builtin.unrealized_conversion_cast"(%201) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %204 = "llvm.load"(%202) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%204, %203) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %205 = "cute.static"() : () -> !cute.int_tuple<"3">
          %206 = "cute.add_offset"(%186, %205) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %207 = "cute.static"() : () -> !cute.int_tuple<"3">
          %208 = "cute.add_offset"(%187, %207) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %209 = "builtin.unrealized_conversion_cast"(%206) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %210 = "builtin.unrealized_conversion_cast"(%208) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
          %211 = "llvm.load"(%209) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%211, %210) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_i4_) -> i32, sym_name = "cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8"}> ({
  ^bb0(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_i4_):
    %0 = "cute.get_iter"(%arg1) : (!memref_gmem_i4_) -> !cute.ptr<i4, gmem, align<128>>
    %1 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
    %2 = "cute.recast_layout"(%1) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"(128,4):(4,1)">
    %3 = "cute.recast_iter"(%0) : (!cute.ptr<i4, gmem, align<128>>) -> !cute.ptr<i8, gmem, align<128>>
    %4 = "cute.get_layout"(%arg1) : (!memref_gmem_i4_) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %5 = "cute.recast_layout"(%4) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %6 = "cute.make_view"(%3, %5) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !memref_gmem_i8_6
    %7 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %8 = "cute.get_shape"(%7) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %9:3 = "cute.get_leaves"(%8) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %10 = "cute.to_int_tuple"(%9#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %11 = "cute.get_scalars"(%10) : (!cute.int_tuple<"?">) -> i32
    %12 = "cute.to_int_tuple"(%9#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.get_scalars"(%12) : (!cute.int_tuple<"?">) -> i32
    %14 = "cute.to_int_tuple"(%9#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %15 = "cute.get_scalars"(%14) : (!cute.int_tuple<"?">) -> i32
    %16 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %17 = "cute.get_shape"(%16) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %18:3 = "cute.get_leaves"(%17) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %19 = "cute.to_int_tuple"(%18#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %20 = "cute.to_int_tuple"(%18#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.to_int_tuple"(%18#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %22 = "cute.make_shape"(%19, %20, %21) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %23 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %24 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %25 = "cute.make_layout"(%22, %24) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %26 = "cute.make_view"(%23, %25) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %27 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %28 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %29:5 = "cute.get_scalars"(%28) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %30 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %31 = "arith.ceildivsi"(%29#0, %30) : (i32, i32) -> i32
    %32 = "cute.make_shape"(%31, %29#1, %29#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %33 = "cute.make_stride"(%29#3, %29#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %34 = "cute.make_layout"(%32, %33) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %35 = "cute.make_view"(%27, %34) : (!cute.ptr<f32, gmem>, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !memref_gmem_f32_
    %36 = "cute.get_iter"(%26) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %37 = "cute.get_layout"(%26) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %38:3 = "cute.get_scalars"(%37) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %39 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
    %40 = "arith.ceildivsi"(%38#0, %39) : (i32, i32) -> i32
    %41 = "cute.make_shape"(%40, %38#1, %38#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %42 = "cute.static"() : () -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %43 = "cute.make_layout"(%41, %42) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %44 = "cute.make_view"(%36, %43) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %45 = "cute.get_iter"(%6) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<128>>
    %46 = "cute.get_layout"(%6) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %47:5 = "cute.get_scalars"(%46) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %48 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %49 = "arith.ceildivsi"(%47#0, %48) : (i32, i32) -> i32
    %50 = "cute.make_shape"(%49, %47#1, %47#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %51 = "cute.make_stride"(%47#3, %47#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %52 = "cute.make_layout"(%50, %51) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((512,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %53 = "cute.make_view"(%45, %52) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !memref_gmem_i8_
    %54 = "cute.get_layout"(%35) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %55 = "cute.size"(%54) <{mode = array<i32: 1>}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %56 = "cute.get_leaves"(%55) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %57 = "cute.get_scalars"(%56) : (!cute.int_tuple<"?">) -> i32
    %58 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %59 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %60 = "cuda.cast"(%59) : (i64) -> !cuda.stream
    %61 = "arith.extsi"(%58) : (i32) -> i64
    %62 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %63 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %64 = "cuda.launch_cfg.create"(%62, %63, %63, %61, %57, %63, %63, %60) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %65 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%64, %65) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %66 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%64, %66) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %67 = "cuda.launch_ex"(%64, %35, %53, %44, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> !cuda.result
    %68 = "cuda.cast"(%67) : (!cuda.result) -> i32
    "cuda.return_if_error"(%68) : (i32) -> ()
    %69 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%69) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
