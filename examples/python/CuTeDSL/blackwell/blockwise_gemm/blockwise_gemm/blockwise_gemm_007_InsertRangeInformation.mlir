!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(4,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, gmem, "(128,4):(4,1)">
!memref_gmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, gmem, "(4):(1)">
!memref_gmem_f8E4M3FN4 = !cute.memref<f8E4M3FN, gmem, "(4,1):(1,0)">
!memref_gmem_f8E4M3FN5 = !cute.memref<f8E4M3FN, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f8E4M3FN6 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(4):(1)">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f8E4M3FN, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %63 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %64 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %65 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %66 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %67 = "cute.make_coord"(%66) : (i32) -> !cute.coord<"(_,?)">
      %68 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %69 = "cute.crd2idx"(%67, %68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %70 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %71 = "cute.add_offset"(%70, %69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %72 = "cute.make_view"(%71) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_1
      %73 = "cute.make_coord"(%66) : (i32) -> !cute.coord<"(_,?)">
      %74 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %75 = "cute.crd2idx"(%73, %74) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %76 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %77 = "cute.add_offset"(%76, %75) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %78 = "cute.make_view"(%77) : (!cute.ptr<f8E4M3FN, gmem>) -> !memref_gmem_f8E4M3FN1
      %79 = "cute.make_coord"(%66) : (i32) -> !cute.coord<"(_,?)">
      %80 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %81 = "cute.crd2idx"(%79, %80) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %82 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %83 = "cute.add_offset"(%82, %81) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %84 = "cute.make_view"(%83) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %85 = "cute.get_iter"(%72) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %86 = "cute.make_view"(%85) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_2
      %87 = "cute.get_iter"(%78) : (!memref_gmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, gmem>
      %88 = "cute.make_view"(%87) : (!cute.ptr<f8E4M3FN, gmem>) -> !memref_gmem_f8E4M3FN2
      %89 = "cute.get_iter"(%84) : (!cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %90 = "cute.make_view"(%89) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %91 = "cute.make_coord"(%65) : (i32) -> !cute.coord<"(?,_)">
      %92 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %93 = "cute.crd2idx"(%91, %92) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %94 = "cute.get_iter"(%86) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %95 = "cute.add_offset"(%94, %93) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %96 = "cute.make_view"(%95) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_3
      %97 = "cute.get_iter"(%96) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %98 = "cute.make_coord"(%65) : (i32) -> !cute.coord<"(?,_)">
      %99 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %100 = "cute.crd2idx"(%98, %99) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %101 = "cute.get_iter"(%88) : (!memref_gmem_f8E4M3FN2) -> !cute.ptr<f8E4M3FN, gmem>
      %102 = "cute.add_offset"(%101, %100) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %103 = "cute.make_view"(%102) : (!cute.ptr<f8E4M3FN, gmem>) -> !memref_gmem_f8E4M3FN3
      %104 = "cute.get_iter"(%103) : (!memref_gmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, gmem>
      %105 = "cute.make_coord"(%65) : (i32) -> !cute.coord<"(?,_)">
      %106 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %107 = "cute.crd2idx"(%105, %106) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %108 = "cute.get_iter"(%90) : (!cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %109 = "cute.add_offset"(%108, %107) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %110 = "cute.make_view"(%109) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %111 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %112 = "cute.get_iter"(%110) : (!cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %113 = "cute.add_offset"(%112, %111) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %114 = "cute.make_view"(%113) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %115 = "cute.get_iter"(%114) : (!cute.coord_tensor<"(?,?{div=4},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %116 = "cute.deref_arith_tuple_iter"(%115) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %117:3 = "cute.get_leaves"(%116) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %118 = "cute.make_coord"(%117#0, %117#1, %117#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %119 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %120:3 = "cute.get_scalars"(%118) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %121:3 = "cute.get_scalars"(%119) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %122 = "arith.constant"() <{value = true}> : () -> i1
      %123 = "arith.cmpi"(%120#0, %121#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %124 = "arith.andi"(%122, %123) : (i1, i1) -> i1
      %125 = "arith.cmpi"(%120#1, %121#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %126 = "arith.andi"(%124, %125) : (i1, i1) -> i1
      %127 = "arith.cmpi"(%120#2, %121#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %128 = "arith.andi"(%126, %127) : (i1, i1) -> i1
      "scf.if"(%128) ({
        %129 = "cute.static"() : () -> !cute.layout<"4:1">
        %130 = "cute.memref.alloca"(%129) : (!cute.layout<"4:1">) -> !memref_rmem_f32_
        %131 = "cute.get_iter"(%130) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %132 = "cute.static"() : () -> !cute.layout<"4:1">
        %133 = "cute.memref.alloca"(%132) : (!cute.layout<"4:1">) -> !memref_rmem_f8E4M3FN
        %134 = "cute.get_iter"(%133) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %135 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %136 = "cute.make_view"(%97, %135) : (!cute.ptr<f32, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_f32_4
        %137 = "cute.get_iter"(%136) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %138 = "cute.make_view"(%137) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_5
        %139 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %140 = "cute.make_view"(%131, %139) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_f32_1
        %141 = "cute.get_iter"(%140) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %142 = "cute.make_view"(%141) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %143 = "cute.static"() : () -> !cute.layout<"1:0">
        %144 = "cute.get_iter"(%138) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %145 = "cute.get_iter"(%142) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %146 = "cute.static"() : () -> !cute.int_tuple<"1">
        %147 = "cute.get_scalars"(%146) : (!cute.int_tuple<"1">) -> i32
        %148 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %149 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%148, %147, %149) ({
        ^bb0(%arg9: i32):
          %201 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %202 = "cute.static"() : () -> !cute.int_tuple<"0">
          %203 = "cute.add_offset"(%144, %202) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %204 = "cute.make_view"(%203, %201) : (!cute.ptr<f32, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_f32_3
          %205 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %206 = "cute.static"() : () -> !cute.int_tuple<"0">
          %207 = "cute.add_offset"(%145, %206) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %208 = "cute.make_view"(%207, %205) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_3
          %209 = "cute.get_iter"(%204) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %210 = "cute.get_iter"(%208) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem, align<32>>
          %211 = "builtin.unrealized_conversion_cast"(%209) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %212 = "builtin.unrealized_conversion_cast"(%210) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %213 = "llvm.load"(%211) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%213, %212) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %214 = "cute.static"() : () -> !cute.int_tuple<"1">
          %215 = "cute.add_offset"(%209, %214) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %216 = "cute.static"() : () -> !cute.int_tuple<"1">
          %217 = "cute.add_offset"(%210, %216) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %218 = "builtin.unrealized_conversion_cast"(%215) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %219 = "builtin.unrealized_conversion_cast"(%217) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %220 = "llvm.load"(%218) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%220, %219) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %221 = "cute.static"() : () -> !cute.int_tuple<"2">
          %222 = "cute.add_offset"(%209, %221) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %223 = "cute.static"() : () -> !cute.int_tuple<"2">
          %224 = "cute.add_offset"(%210, %223) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %225 = "builtin.unrealized_conversion_cast"(%222) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %226 = "builtin.unrealized_conversion_cast"(%224) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %227 = "llvm.load"(%225) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%227, %226) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %228 = "cute.static"() : () -> !cute.int_tuple<"3">
          %229 = "cute.add_offset"(%209, %228) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %230 = "cute.static"() : () -> !cute.int_tuple<"3">
          %231 = "cute.add_offset"(%210, %230) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %232 = "builtin.unrealized_conversion_cast"(%229) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %233 = "builtin.unrealized_conversion_cast"(%231) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %234 = "llvm.load"(%232) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%234, %233) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %150 = "cute.memref.load_vec"(%130) : (!memref_rmem_f32_) -> vector<4xf32>
        %151 = "nvgpu.cvt_fptrunc"(%150) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
        "cute.memref.store_vec"(%151, %133) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
        %152 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %153 = "cute.make_view"(%134, %152) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_f8E4M3FN1
        %154 = "cute.get_iter"(%153) : (!memref_rmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %155 = "cute.make_view"(%154) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !memref_rmem_f8E4M3FN2
        %156 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %157 = "cute.make_view"(%104, %156) : (!cute.ptr<f8E4M3FN, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_f8E4M3FN4
        %158 = "cute.get_iter"(%157) : (!memref_gmem_f8E4M3FN4) -> !cute.ptr<f8E4M3FN, gmem>
        %159 = "cute.make_view"(%158) : (!cute.ptr<f8E4M3FN, gmem>) -> !memref_gmem_f8E4M3FN5
        %160 = "cute.static"() : () -> !cute.layout<"1:0">
        %161 = "cute.get_iter"(%155) : (!memref_rmem_f8E4M3FN2) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %162 = "cute.get_iter"(%159) : (!memref_gmem_f8E4M3FN5) -> !cute.ptr<f8E4M3FN, gmem>
        %163 = "cute.static"() : () -> !cute.int_tuple<"1">
        %164 = "cute.get_scalars"(%163) : (!cute.int_tuple<"1">) -> i32
        %165 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %166 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%165, %164, %166) ({
        ^bb0(%arg8: i32):
          %167 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %168 = "cute.static"() : () -> !cute.int_tuple<"0">
          %169 = "cute.add_offset"(%161, %168) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %170 = "cute.make_view"(%169, %167) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_f8E4M3FN3
          %171 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %172 = "cute.static"() : () -> !cute.int_tuple<"0">
          %173 = "cute.add_offset"(%162, %172) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem>
          %174 = "cute.make_view"(%173, %171) : (!cute.ptr<f8E4M3FN, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_f8E4M3FN3
          %175 = "cute.get_iter"(%170) : (!memref_rmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %176 = "cute.get_iter"(%174) : (!memref_gmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, gmem>
          %177 = "builtin.unrealized_conversion_cast"(%175) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
          %178 = "builtin.unrealized_conversion_cast"(%176) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
          %179 = "llvm.load"(%177) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%179, %178) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %180 = "cute.static"() : () -> !cute.int_tuple<"1">
          %181 = "cute.add_offset"(%175, %180) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
          %182 = "cute.static"() : () -> !cute.int_tuple<"1">
          %183 = "cute.add_offset"(%176, %182) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
          %184 = "builtin.unrealized_conversion_cast"(%181) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
          %185 = "builtin.unrealized_conversion_cast"(%183) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
          %186 = "llvm.load"(%184) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%186, %185) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %187 = "cute.static"() : () -> !cute.int_tuple<"2">
          %188 = "cute.add_offset"(%175, %187) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
          %189 = "cute.static"() : () -> !cute.int_tuple<"2">
          %190 = "cute.add_offset"(%176, %189) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
          %191 = "builtin.unrealized_conversion_cast"(%188) : (!cute.ptr<f8E4M3FN, rmem, align<2>>) -> !llvm.ptr
          %192 = "builtin.unrealized_conversion_cast"(%190) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
          %193 = "llvm.load"(%191) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%193, %192) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          %194 = "cute.static"() : () -> !cute.int_tuple<"3">
          %195 = "cute.add_offset"(%175, %194) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
          %196 = "cute.static"() : () -> !cute.int_tuple<"3">
          %197 = "cute.add_offset"(%176, %196) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
          %198 = "builtin.unrealized_conversion_cast"(%195) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
          %199 = "builtin.unrealized_conversion_cast"(%197) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
          %200 = "llvm.load"(%198) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
          "llvm.store"(%200, %199) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_f8E4M3FN6) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_4"}> ({
  ^bb0(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6):
    %0 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %1 = "cute.get_shape"(%0) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %2:3 = "cute.get_leaves"(%1) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %3 = "cute.to_int_tuple"(%2#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %4 = "cute.get_scalars"(%3) : (!cute.int_tuple<"?">) -> i32
    %5 = "cute.to_int_tuple"(%2#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %6 = "cute.get_scalars"(%5) : (!cute.int_tuple<"?">) -> i32
    %7 = "cute.to_int_tuple"(%2#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %8 = "cute.get_scalars"(%7) : (!cute.int_tuple<"?">) -> i32
    %9 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %10 = "cute.get_shape"(%9) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %11:3 = "cute.get_leaves"(%10) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %12 = "cute.to_int_tuple"(%11#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.to_int_tuple"(%11#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %14 = "cute.to_int_tuple"(%11#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %15 = "cute.make_shape"(%12, %13, %14) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %16 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %17 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %18 = "cute.make_layout"(%15, %17) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %19 = "cute.make_view"(%16, %18) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %20 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %21 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %22:5 = "cute.get_scalars"(%21) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %23 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %24 = "arith.ceildivsi"(%22#1, %23) : (i32, i32) -> i32
    %25 = "cute.make_shape"(%22#0, %24, %22#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %26 = "cute.make_stride"(%22#3, %22#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %27 = "cute.make_layout"(%25, %26) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %28 = "cute.make_view"(%20, %27) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f32_
    %29 = "cute.get_iter"(%19) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %30 = "cute.get_layout"(%19) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %31:3 = "cute.get_scalars"(%30) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %32 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %33 = "arith.ceildivsi"(%31#1, %32) : (i32, i32) -> i32
    %34 = "cute.make_shape"(%31#0, %33, %31#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %35 = "cute.static"() : () -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %36 = "cute.make_layout"(%34, %35) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %37 = "cute.make_view"(%29, %36) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %38 = "cute.get_iter"(%arg1) : (!memref_gmem_f8E4M3FN6) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
    %39 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %40:5 = "cute.get_scalars"(%39) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %41 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %42 = "arith.ceildivsi"(%40#1, %41) : (i32, i32) -> i32
    %43 = "cute.make_shape"(%40#0, %42, %40#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %44 = "cute.make_stride"(%40#3, %40#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %45 = "cute.make_layout"(%43, %44) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %46 = "cute.make_view"(%38, %45) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f8E4M3FN
    %47 = "cute.get_layout"(%28) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %48 = "cute.size"(%47) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %49 = "cute.get_leaves"(%48) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %50 = "cute.get_scalars"(%49) : (!cute.int_tuple<"?">) -> i32
    %51 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %52 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %53 = "cuda.cast"(%52) : (i64) -> !cuda.stream
    %54 = "arith.extsi"(%51) : (i32) -> i64
    %55 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %56 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %57 = "cuda.launch_cfg.create"(%55, %56, %56, %54, %50, %56, %56, %53) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %58 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%57, %58) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %59 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%57, %59) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %60 = "cuda.launch_ex"(%57, %28, %46, %37, %4, %6, %8) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %61 = "cuda.cast"(%60) : (!cuda.result) -> i32
    "cuda.return_if_error"(%61) : (i32) -> ()
    %62 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%62) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
