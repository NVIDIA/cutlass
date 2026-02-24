!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(4,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1)):((0,1,0))">
!memref_gmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, gmem, align<16>, "(128,4):(4,1)">
!memref_gmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4):(1)">
!memref_gmem_f8E4M3FN4 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,1):(1,0)">
!memref_gmem_f8E4M3FN5 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,(1)):(1,(0))">
!memref_gmem_f8E4M3FN6 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?{div=16},?):(?{div=16},1,?{div=16})">
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
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f8E4M3FN, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %65 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %66 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %67 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %68 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %69 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"(_,?)">
      %70 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %71 = "cute.crd2idx"(%69, %70) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %72 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %73 = "cute.add_offset"(%72, %71) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %74 = "cute.make_view"(%73) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_1
      %75 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"(_,?)">
      %76 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
      %77 = "cute.crd2idx"(%75, %76) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %78 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %79 = "cute.add_offset"(%78, %77) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %80 = "cute.make_view"(%79) : (!cute.ptr<f8E4M3FN, gmem, align<16>>) -> !memref_gmem_f8E4M3FN1
      %81 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"(_,?)">
      %82 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %83 = "cute.crd2idx"(%81, %82) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %84 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %85 = "cute.add_offset"(%84, %83) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %86 = "cute.make_view"(%85) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %87 = "cute.get_iter"(%74) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %88 = "cute.make_view"(%87) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_2
      %89 = "cute.get_iter"(%80) : (!memref_gmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %90 = "cute.make_view"(%89) : (!cute.ptr<f8E4M3FN, gmem, align<16>>) -> !memref_gmem_f8E4M3FN2
      %91 = "cute.get_iter"(%86) : (!cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %92 = "cute.make_view"(%91) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %93 = "cute.make_coord"(%67) : (i32) -> !cute.coord<"(?,_)">
      %94 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %95 = "cute.crd2idx"(%93, %94) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %96 = "cute.get_iter"(%88) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %97 = "cute.add_offset"(%96, %95) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %98 = "cute.make_view"(%97) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_3
      %99 = "cute.get_iter"(%98) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %100 = "cute.make_coord"(%67) : (i32) -> !cute.coord<"(?,_)">
      %101 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %102 = "cute.crd2idx"(%100, %101) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %103 = "cute.get_iter"(%90) : (!memref_gmem_f8E4M3FN2) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %104 = "cute.add_offset"(%103, %102) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %105 = "cute.make_view"(%104) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !memref_gmem_f8E4M3FN3
      %106 = "cute.get_iter"(%105) : (!memref_gmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %107 = "cute.make_coord"(%67) : (i32) -> !cute.coord<"(?,_)">
      %108 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %109 = "cute.crd2idx"(%107, %108) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %110 = "cute.get_iter"(%92) : (!cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %111 = "cute.add_offset"(%110, %109) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %112 = "cute.make_view"(%111) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %113 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %114 = "cute.get_iter"(%112) : (!cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %115 = "cute.add_offset"(%114, %113) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %116 = "cute.make_view"(%115) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %117 = "cute.get_iter"(%116) : (!cute.coord_tensor<"(?,?{div=4},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %118 = "cute.deref_arith_tuple_iter"(%117) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %119:3 = "cute.get_leaves"(%118) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %120 = "cute.make_coord"(%119#0, %119#1, %119#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %121 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %122:3 = "cute.get_scalars"(%120) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %123:3 = "cute.get_scalars"(%121) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %124 = "arith.constant"() <{value = true}> : () -> i1
      %125 = "arith.cmpi"(%122#0, %123#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %126 = "arith.andi"(%124, %125) : (i1, i1) -> i1
      %127 = "arith.cmpi"(%122#1, %123#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %128 = "arith.andi"(%126, %127) : (i1, i1) -> i1
      %129 = "arith.cmpi"(%122#2, %123#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %130 = "arith.andi"(%128, %129) : (i1, i1) -> i1
      "scf.if"(%130) ({
        %131 = "cute.static"() : () -> !cute.layout<"4:1">
        %132 = "cute.memref.alloca"(%131) : (!cute.layout<"4:1">) -> !memref_rmem_f32_
        %133 = "cute.get_iter"(%132) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %134 = "cute.static"() : () -> !cute.layout<"4:1">
        %135 = "cute.memref.alloca"(%134) : (!cute.layout<"4:1">) -> !memref_rmem_f8E4M3FN
        %136 = "cute.get_iter"(%135) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %137 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %138 = "cute.make_view"(%99, %137) : (!cute.ptr<f32, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_f32_4
        %139 = "cute.get_iter"(%138) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %140 = "cute.make_view"(%139) : (!cute.ptr<f32, gmem>) -> !memref_gmem_f32_5
        %141 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %142 = "cute.make_view"(%133, %141) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_f32_1
        %143 = "cute.get_iter"(%142) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %144 = "cute.make_view"(%143) : (!cute.ptr<f32, rmem, align<32>>) -> !memref_rmem_f32_2
        %145 = "cute.static"() : () -> !cute.layout<"1:0">
        %146 = "cute.get_iter"(%140) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %147 = "cute.get_iter"(%144) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %148 = "cute.static"() : () -> !cute.int_tuple<"1">
        %149 = "cute.get_scalars"(%148) : (!cute.int_tuple<"1">) -> i32
        %150 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %151 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%150, %149, %151) ({
        ^bb0(%arg9: i32):
          %182 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %183 = "cute.static"() : () -> !cute.int_tuple<"0">
          %184 = "cute.add_offset"(%146, %183) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %185 = "cute.make_view"(%184, %182) : (!cute.ptr<f32, gmem>, !cute.layout<"(4):(1)">) -> !memref_gmem_f32_3
          %186 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %187 = "cute.static"() : () -> !cute.int_tuple<"0">
          %188 = "cute.add_offset"(%147, %187) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %189 = "cute.make_view"(%188, %186) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_3
          %190 = "cute.get_iter"(%185) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
          %191 = "cute.get_iter"(%189) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem, align<32>>
          %192 = "builtin.unrealized_conversion_cast"(%190) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %193 = "builtin.unrealized_conversion_cast"(%191) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %194 = "llvm.load"(%192) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%194, %193) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %195 = "cute.static"() : () -> !cute.int_tuple<"1">
          %196 = "cute.add_offset"(%190, %195) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %197 = "cute.static"() : () -> !cute.int_tuple<"1">
          %198 = "cute.add_offset"(%191, %197) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %199 = "builtin.unrealized_conversion_cast"(%196) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %200 = "builtin.unrealized_conversion_cast"(%198) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %201 = "llvm.load"(%199) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%201, %200) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %202 = "cute.static"() : () -> !cute.int_tuple<"2">
          %203 = "cute.add_offset"(%190, %202) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %204 = "cute.static"() : () -> !cute.int_tuple<"2">
          %205 = "cute.add_offset"(%191, %204) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %206 = "builtin.unrealized_conversion_cast"(%203) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %207 = "builtin.unrealized_conversion_cast"(%205) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %208 = "llvm.load"(%206) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%208, %207) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          %209 = "cute.static"() : () -> !cute.int_tuple<"3">
          %210 = "cute.add_offset"(%190, %209) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %211 = "cute.static"() : () -> !cute.int_tuple<"3">
          %212 = "cute.add_offset"(%191, %211) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %213 = "builtin.unrealized_conversion_cast"(%210) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %214 = "builtin.unrealized_conversion_cast"(%212) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %215 = "llvm.load"(%213) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%215, %214) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %152 = "cute.memref.load_vec"(%132) : (!memref_rmem_f32_) -> vector<4xf32>
        %153 = "nvgpu.cvt_fptrunc"(%152) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
        "cute.memref.store_vec"(%153, %135) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
        %154 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %155 = "cute.make_view"(%136, %154) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_f8E4M3FN1
        %156 = "cute.get_iter"(%155) : (!memref_rmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %157 = "cute.make_view"(%156) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !memref_rmem_f8E4M3FN2
        %158 = "cute.static"() : () -> !cute.layout<"(4,1):(1,0)">
        %159 = "cute.make_view"(%106, %158) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_f8E4M3FN4
        %160 = "cute.get_iter"(%159) : (!memref_gmem_f8E4M3FN4) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
        %161 = "cute.make_view"(%160) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !memref_gmem_f8E4M3FN5
        %162 = "cute.static"() : () -> !cute.layout<"1:0">
        %163 = "cute.get_iter"(%157) : (!memref_rmem_f8E4M3FN2) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %164 = "cute.get_iter"(%161) : (!memref_gmem_f8E4M3FN5) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
        %165 = "cute.static"() : () -> !cute.int_tuple<"1">
        %166 = "cute.get_scalars"(%165) : (!cute.int_tuple<"1">) -> i32
        %167 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %168 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%167, %166, %168) ({
        ^bb0(%arg8: i32):
          %169 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %170 = "cute.static"() : () -> !cute.int_tuple<"0">
          %171 = "cute.add_offset"(%163, %170) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %172 = "cute.make_view"(%171, %169) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.layout<"(4):(1)">) -> !memref_rmem_f8E4M3FN3
          %173 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %174 = "cute.static"() : () -> !cute.int_tuple<"0">
          %175 = "cute.add_offset"(%164, %174) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
          %176 = "cute.make_view"(%175, %173) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.layout<"(4):(1)">) -> !memref_gmem_f8E4M3FN3
          %177 = "cute.get_iter"(%172) : (!memref_rmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %178 = "cute.get_iter"(%176) : (!memref_gmem_f8E4M3FN3) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
          %179 = "builtin.unrealized_conversion_cast"(%177) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
          %180 = "builtin.unrealized_conversion_cast"(%178) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !llvm.ptr<1>
          %181 = "llvm.load"(%179) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<4xi8>
          "llvm.store"(%181, %180) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_f8E4M3FN6) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemodiv16div161div16_1_4"}> ({
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
    %39 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN6) -> !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %40:5 = "cute.get_scalars"(%39) <{only_dynamic}> : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> (i32, i32, i32, i32, i32)
    %41 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %42 = "arith.ceildivsi"(%40#1, %41) : (i32, i32) -> i32
    %43 = "cute.make_shape"(%40#0, %42, %40#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %44 = "cute.assume"(%40#3) : (i32) -> !cute.i32<divby 16>
    %45 = "cute.assume"(%40#4) : (i32) -> !cute.i32<divby 16>
    %46 = "cute.make_stride"(%44, %45) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %47 = "cute.make_layout"(%43, %46) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %48 = "cute.make_view"(%38, %47) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !memref_gmem_f8E4M3FN
    %49 = "cute.get_layout"(%28) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %50 = "cute.size"(%49) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %51 = "cute.get_leaves"(%50) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %52 = "cute.get_scalars"(%51) : (!cute.int_tuple<"?">) -> i32
    %53 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %54 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %55 = "cuda.cast"(%54) : (i64) -> !cuda.stream
    %56 = "arith.extsi"(%53) : (i32) -> i64
    %57 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %58 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %59 = "cuda.launch_cfg.create"(%57, %58, %58, %56, %52, %58, %58, %55) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %60 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%59, %60) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %61 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%59, %61) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %62 = "cuda.launch_ex"(%59, %28, %48, %37, %4, %6, %8) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %63 = "cuda.cast"(%62) : (!cuda.result) -> i32
    "cuda.return_if_error"(%63) : (i32) -> ()
    %64 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%64) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
