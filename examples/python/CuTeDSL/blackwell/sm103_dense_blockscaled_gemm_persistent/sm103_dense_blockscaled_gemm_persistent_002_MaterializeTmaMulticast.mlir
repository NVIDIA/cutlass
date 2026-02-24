!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f4E2M1FN = !cute.memref<f4E2M1FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(8,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(8,(1)):(1,(0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_i8_, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %96 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %97 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %98 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %99 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %100 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %101 = "cute.deref_arith_tuple_iter"(%100) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %102:3 = "cute.get_leaves"(%101) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %103 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %104 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
      %105 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %106 = "cute.deref_arith_tuple_iter"(%105) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %107:3 = "cute.get_leaves"(%106) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %108 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %109 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %110 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %111 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
      %112 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %113 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %114 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %115 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %116 = "cute.make_coord"(%115) : (i32) -> !cute.coord<"(_,?)">
      %117 = "cute.slice"(%arg2, %116) : (!memref_gmem_f32_, !cute.coord<"(_,?)">) -> !memref_gmem_f32_1
      %118 = "cute.get_iter"(%117) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %119 = "cute.get_iter"(%117) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %120 = "cute.make_coord"(%115) : (i32) -> !cute.coord<"(_,?)">
      %121 = "cute.slice"(%arg3, %120) : (!memref_gmem_i8_, !cute.coord<"(_,?)">) -> !memref_gmem_i8_1
      %122 = "cute.get_iter"(%121) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %123 = "cute.get_iter"(%121) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %124 = "cute.make_coord"(%115) : (i32) -> !cute.coord<"(_,?)">
      %125 = "cute.slice"(%arg4, %124) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, !cute.coord<"(_,?)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %126 = "cute.get_iter"(%125) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %127 = "cute.deref_arith_tuple_iter"(%126) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %128:3 = "cute.get_leaves"(%127) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %129 = "cute.get_scalars"(%128#0) : (!cute.int_tuple<"?">) -> i32
      %130 = "cute.get_scalars"(%128#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %131 = "cute.get_scalars"(%128#2) : (!cute.int_tuple<"?">) -> i32
      %132 = "cute.get_iter"(%125) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %133 = "cute.deref_arith_tuple_iter"(%132) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %134:3 = "cute.get_leaves"(%133) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %135 = "cute.get_scalars"(%134#0) : (!cute.int_tuple<"?">) -> i32
      %136 = "cute.get_scalars"(%134#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %137 = "cute.get_scalars"(%134#2) : (!cute.int_tuple<"?">) -> i32
      %138 = "cute.composition"(%117, %96) : (!memref_gmem_f32_1, !cute.layout<"(128,8):(8,1)">) -> !memref_gmem_f32_2
      %139 = "cute.get_iter"(%138) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %140 = "cute.composition"(%121, %97) : (!memref_gmem_i8_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_i8_2
      %141 = "cute.get_iter"(%140) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %142 = "cute.composition"(%125, %96) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">, !cute.layout<"(128,8):(8,1)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %143 = "cute.get_iter"(%142) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %144 = "cute.deref_arith_tuple_iter"(%143) : (!cute.arith_tuple_iter<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %145:3 = "cute.get_leaves"(%144) : (!cute.int_tuple<"(?,?{div=1024},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">)
      %146 = "cute.get_scalars"(%145#0) : (!cute.int_tuple<"?">) -> i32
      %147 = "cute.get_scalars"(%145#1) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %148 = "cute.get_scalars"(%145#2) : (!cute.int_tuple<"?">) -> i32
      %149 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"(?,_)">
      %150 = "cute.slice"(%138, %149) : (!memref_gmem_f32_2, !cute.coord<"(?,_)">) -> !memref_gmem_f32_3
      %151 = "cute.get_iter"(%150) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %152 = "cute.get_iter"(%150) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %153 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"(?,_)">
      %154 = "cute.slice"(%140, %153) : (!memref_gmem_i8_2, !cute.coord<"(?,_)">) -> !memref_gmem_i8_3
      %155 = "cute.get_iter"(%154) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %156 = "cute.get_iter"(%154) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %157 = "cute.make_coord"(%114) : (i32) -> !cute.coord<"(?,_)">
      %158 = "cute.slice"(%142, %157) : (!cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">, !cute.coord<"(?,_)">) -> !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %159 = "cute.get_iter"(%158) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %160 = "cute.deref_arith_tuple_iter"(%159) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %161:3 = "cute.get_leaves"(%160) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %162 = "cute.get_scalars"(%161#0) : (!cute.int_tuple<"?">) -> i32
      %163 = "cute.get_scalars"(%161#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %164 = "cute.get_scalars"(%161#2) : (!cute.int_tuple<"?">) -> i32
      %165 = "cute.get_iter"(%158) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %166 = "cute.deref_arith_tuple_iter"(%165) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %167:3 = "cute.get_leaves"(%166) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %168 = "cute.get_scalars"(%167#0) : (!cute.int_tuple<"?">) -> i32
      %169 = "cute.get_scalars"(%167#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %170 = "cute.get_scalars"(%167#2) : (!cute.int_tuple<"?">) -> i32
      %171 = "cute.make_coord"() : () -> !cute.coord<"0">
      %172 = "cute.slice"(%158, %171) : (!cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">, !cute.coord<"0">) -> !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %173 = "cute.get_iter"(%172) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %174 = "cute.deref_arith_tuple_iter"(%173) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %175:3 = "cute.get_leaves"(%174) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %176 = "cute.get_scalars"(%175#0) : (!cute.int_tuple<"?">) -> i32
      %177 = "cute.get_scalars"(%175#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %178 = "cute.get_scalars"(%175#2) : (!cute.int_tuple<"?">) -> i32
      %179 = "cute.get_iter"(%172) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %180 = "cute.deref_arith_tuple_iter"(%179) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %181:3 = "cute.get_leaves"(%180) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %182 = "cute.get_scalars"(%181#0) : (!cute.int_tuple<"?">) -> i32
      %183 = "cute.get_scalars"(%181#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %184 = "cute.get_scalars"(%181#2) : (!cute.int_tuple<"?">) -> i32
      %185 = "cute.get_iter"(%172) : (!cute.coord_tensor<"(?,?{div=8},?)", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %186 = "cute.deref_arith_tuple_iter"(%185) : (!cute.arith_tuple_iter<"(?,?{div=8},?)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %187:3 = "cute.get_leaves"(%186) : (!cute.int_tuple<"(?,?{div=8},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">)
      %188 = "cute.get_scalars"(%187#0) : (!cute.int_tuple<"?">) -> i32
      %189 = "cute.get_scalars"(%187#1) : (!cute.int_tuple<"?{div=8}">) -> i32
      %190 = "cute.get_scalars"(%187#2) : (!cute.int_tuple<"?">) -> i32
      %191 = "cute.make_coord"(%187#0, %187#1, %187#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %192 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %193 = "cute.elem_less"(%191, %192) : (!cute.coord<"(?,?{div=8},?)">, !cute.coord<"(?,?,?)">) -> i1
      "scf.if"(%193) ({
        %194 = "cute.get_shape"(%96) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %195:2 = "cute.get_leaves"(%194) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %196 = "cute.get_shape"(%96) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %197:2 = "cute.get_leaves"(%196) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %198 = "cute.get"(%96) <{mode = array<i32: 1>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"8:1">
        %199 = "cute.memref.alloca"(%198) : (!cute.layout<"8:1">) -> !memref_rmem_f32_
        %200 = "cute.get_iter"(%199) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %201 = "cute.get_iter"(%199) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %202 = "cute.get_shape"(%97) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %203:2 = "cute.get_leaves"(%202) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %204 = "cute.get_shape"(%97) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %205:2 = "cute.get_leaves"(%204) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %206 = "cute.get"(%97) <{mode = array<i32: 1>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.layout<"4:1">
        %207 = "cute.memref.alloca"(%206) : (!cute.layout<"4:1">) -> !memref_rmem_i8_
        %208 = "cute.get_iter"(%207) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %209 = "cute.get_iter"(%207) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %210 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %211 = "cute.get_layout"(%150) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %212 = "cute.get_shape"(%211) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %213 = "cute.get_leaves"(%212) : (!cute.shape<"(8)">) -> !cute.shape<"8">
        %214 = "cute.get_layout"(%199) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %215 = "cute.get_shape"(%214) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %216 = "cute.get_leaves"(%215) : (!cute.shape<"8">) -> !cute.shape<"8">
        %217 = "cute.get_layout"(%150) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %218 = "cute.make_shape"() : () -> !cute.shape<"1">
        %219 = "cute.make_layout"(%218) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %220 = "cute.append_to_rank"(%217, %219) <{rank = 2 : si32}> : (!cute.layout<"(8):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %221 = "cute.make_view"(%152, %220) : (!cute.ptr<f32, gmem>, !cute.layout<"(8,1):(1,0)">) -> !memref_gmem_f32_4
        %222 = "cute.get_iter"(%221) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %223 = "cute.get_layout"(%221) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %224 = "cute.get_shape"(%223) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %225:2 = "cute.get_leaves"(%224) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %226 = "cute.get_layout"(%221) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %227 = "cute.get_shape"(%226) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %228:2 = "cute.get_leaves"(%227) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %229 = "cute.group_modes"(%221) <{begin = 1 : i32, end = 2 : i32}> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %230 = "cute.get_iter"(%229) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %231 = "cute.get_iter"(%229) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %232 = "cute.get_layout"(%199) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %233 = "cute.make_shape"() : () -> !cute.shape<"1">
        %234 = "cute.make_layout"(%233) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %235 = "cute.append_to_rank"(%232, %234) <{rank = 2 : si32}> : (!cute.layout<"8:1">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %236 = "cute.make_view"(%201, %235) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8,1):(1,0)">) -> !memref_rmem_f32_1
        %237 = "cute.get_iter"(%236) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %238 = "cute.get_layout"(%236) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %239 = "cute.get_shape"(%238) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %240:2 = "cute.get_leaves"(%239) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %241 = "cute.get_layout"(%236) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %242 = "cute.get_shape"(%241) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %243:2 = "cute.get_leaves"(%242) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %244 = "cute.group_modes"(%236) <{begin = 1 : i32, end = 2 : i32}> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %245 = "cute.get_iter"(%244) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %246 = "cute.get_iter"(%244) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %247 = "cute.get_layout"(%229) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %248 = "cute.get_shape"(%247) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %249:2 = "cute.get_leaves"(%248) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %250 = "cute.get_layout"(%244) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %251 = "cute.get_shape"(%250) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %252:2 = "cute.get_leaves"(%251) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %253 = "cute.size"(%229) <{mode = array<i32: 1>}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %254 = "cute.get_leaves"(%253) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %255 = "cute.size"(%244) <{mode = array<i32: 1>}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %256 = "cute.get_leaves"(%255) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%210, %229, %244) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2) -> ()
        %257 = "cute.get_layout"(%199) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %258 = "cute.get_shape"(%257) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %259 = "cute.get_leaves"(%258) : (!cute.shape<"8">) -> !cute.shape<"8">
        %260 = "cute.memref.load_vec"(%199) : (!memref_rmem_f32_) -> vector<8xf32>
        %261 = "cute.get_layout"(%199) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %262 = "cute.get_shape"(%261) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %263 = "cute.get_leaves"(%262) : (!cute.shape<"8">) -> !cute.shape<"8">
        %264 = "nvgpu.cvt_fptrunc"(%260) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<8xf32>) -> vector<8xf4E2M1FN>
        %265 = "cute.make_shape"() : () -> !cute.shape<"8">
        %266 = "cute.make_layout"(%265) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
        %267 = "cute.recast_layout"(%266) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %268 = "cute.get_shape"(%267) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %269 = "cute.get_leaves"(%268) : (!cute.shape<"4">) -> !cute.shape<"4">
        %270 = "builtin.unrealized_conversion_cast"(%264) : (vector<8xf4E2M1FN>) -> vector<8xi4>
        %271 = "vector.bitcast"(%270) : (vector<8xi4>) -> vector<4xi8>
        %272 = "cute.get_layout"(%207) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %273 = "cute.get_shape"(%272) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %274 = "cute.get_leaves"(%273) : (!cute.shape<"4">) -> !cute.shape<"4">
        %275 = "cute.get_layout"(%207) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %276 = "cute.get_shape"(%275) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %277 = "cute.get_leaves"(%276) : (!cute.shape<"4">) -> !cute.shape<"4">
        %278 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %279 = "cute.size"(%278) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %280 = "cute.get_leaves"(%279) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %281 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %282 = "cute.size"(%281) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %283 = "cute.get_leaves"(%282) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        "cute.memref.store_vec"(%271, %207) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %284 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %285 = "cute.get_layout"(%207) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %286 = "cute.get_shape"(%285) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %287 = "cute.get_leaves"(%286) : (!cute.shape<"4">) -> !cute.shape<"4">
        %288 = "cute.get_layout"(%154) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %289 = "cute.get_shape"(%288) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %290 = "cute.get_leaves"(%289) : (!cute.shape<"(4)">) -> !cute.shape<"4">
        %291 = "cute.get_layout"(%207) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %292 = "cute.make_shape"() : () -> !cute.shape<"1">
        %293 = "cute.make_layout"(%292) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %294 = "cute.append_to_rank"(%291, %293) <{rank = 2 : si32}> : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %295 = "cute.make_view"(%209, %294) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_i8_1
        %296 = "cute.get_iter"(%295) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %297 = "cute.get_layout"(%295) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %298 = "cute.get_shape"(%297) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %299:2 = "cute.get_leaves"(%298) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %300 = "cute.get_layout"(%295) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %301 = "cute.get_shape"(%300) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %302:2 = "cute.get_leaves"(%301) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %303 = "cute.group_modes"(%295) <{begin = 1 : i32, end = 2 : i32}> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %304 = "cute.get_iter"(%303) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %305 = "cute.get_iter"(%303) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %306 = "cute.get_layout"(%154) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %307 = "cute.make_shape"() : () -> !cute.shape<"1">
        %308 = "cute.make_layout"(%307) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %309 = "cute.append_to_rank"(%306, %308) <{rank = 2 : si32}> : (!cute.layout<"(4):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %310 = "cute.make_view"(%156, %309) : (!cute.ptr<i8, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_i8_4
        %311 = "cute.get_iter"(%310) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %312 = "cute.get_layout"(%310) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %313 = "cute.get_shape"(%312) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %314:2 = "cute.get_leaves"(%313) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %315 = "cute.get_layout"(%310) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %316 = "cute.get_shape"(%315) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %317:2 = "cute.get_leaves"(%316) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %318 = "cute.group_modes"(%310) <{begin = 1 : i32, end = 2 : i32}> : (!memref_gmem_i8_4) -> !memref_gmem_i8_5
        %319 = "cute.get_iter"(%318) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %320 = "cute.get_iter"(%318) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %321 = "cute.get_layout"(%303) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %322 = "cute.get_shape"(%321) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %323:2 = "cute.get_leaves"(%322) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %324 = "cute.get_layout"(%318) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %325 = "cute.get_shape"(%324) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %326:2 = "cute.get_leaves"(%325) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %327 = "cute.size"(%303) <{mode = array<i32: 1>}> : (!memref_rmem_i8_2) -> !cute.int_tuple<"1">
        %328 = "cute.get_leaves"(%327) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %329 = "cute.size"(%318) <{mode = array<i32: 1>}> : (!memref_gmem_i8_5) -> !cute.int_tuple<"1">
        %330 = "cute.get_leaves"(%329) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%284, %303, %318) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_2, !memref_gmem_i8_5) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_f4E2M1FN) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_8"}> ({
  ^bb0(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.ptr<f4E2M1FN, gmem, align<16>>
    %2 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.ptr<f4E2M1FN, gmem, align<16>>
    %4 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %5 = "cute.get_layout"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %6 = "cute.make_shape"() : () -> !cute.shape<"(128,8)">
    %7 = "cute.make_stride"() : () -> !cute.stride<"(8,1)">
    %8 = "cute.make_layout"(%6, %7) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(128,8):(8,1)">
    %9 = "cute.recast_layout"(%8) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"(128,4):(4,1)">
    %10 = "cute.recast_iter"(%3) : (!cute.ptr<f4E2M1FN, gmem, align<16>>) -> !cute.ptr<i8, gmem, align<16>>
    %11 = "cute.get_layout"(%arg1) : (!memref_gmem_f4E2M1FN) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %12 = "cute.recast_layout"(%11) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %13 = "cute.make_view"(%10, %12) : (!cute.ptr<i8, gmem, align<16>>, !cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !memref_gmem_i8_6
    %14 = "cute.get_iter"(%13) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<16>>
    %15 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %16 = "cute.get_shape"(%15) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %17:3 = "cute.get_leaves"(%16) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %18 = "cute.to_int_tuple"(%17#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %19 = "cute.get_scalars"(%18) : (!cute.int_tuple<"?">) -> i32
    %20 = "cute.to_int_tuple"(%17#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.get_scalars"(%20) : (!cute.int_tuple<"?">) -> i32
    %22 = "cute.to_int_tuple"(%17#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %23 = "cute.get_scalars"(%22) : (!cute.int_tuple<"?">) -> i32
    %24 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %25 = "cute.get_shape"(%24) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %26:3 = "cute.get_leaves"(%25) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %27 = "cute.to_int_tuple"(%26#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %28 = "cute.get_scalars"(%27) : (!cute.int_tuple<"?">) -> i32
    %29 = "cute.to_int_tuple"(%26#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %30 = "cute.get_scalars"(%29) : (!cute.int_tuple<"?">) -> i32
    %31 = "cute.to_int_tuple"(%26#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %32 = "cute.get_scalars"(%31) : (!cute.int_tuple<"?">) -> i32
    %33 = "cute.make_shape"(%27, %29, %31) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %34 = "cute.make_identity_tensor"(%33) : (!cute.shape<"(?,?,?)">) -> !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %35 = "cute.get_iter"(%34) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %36 = "cute.deref_arith_tuple_iter"(%35) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %37:3 = "cute.get_leaves"(%36) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %38 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %39 = "cute.get_shape"(%38) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %40:3 = "cute.get_leaves"(%39) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %41 = "cute.to_int_tuple"(%40#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %42 = "cute.get_scalars"(%41) : (!cute.int_tuple<"?">) -> i32
    %43 = "cute.to_int_tuple"(%40#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %44 = "cute.get_scalars"(%43) : (!cute.int_tuple<"?">) -> i32
    %45 = "cute.to_int_tuple"(%40#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.get_scalars"(%45) : (!cute.int_tuple<"?">) -> i32
    %47 = "cute.size"(%8) <{mode = array<i32>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %48 = "cute.get_leaves"(%47) : (!cute.int_tuple<"1024">) -> !cute.int_tuple<"1024">
    %49 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %50 = "cute.get_shape"(%49) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %51:3 = "cute.get_leaves"(%50) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %52 = "cute.to_int_tuple"(%51#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %53 = "cute.get_scalars"(%52) : (!cute.int_tuple<"?">) -> i32
    %54 = "cute.to_int_tuple"(%51#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %55 = "cute.get_scalars"(%54) : (!cute.int_tuple<"?">) -> i32
    %56 = "cute.to_int_tuple"(%51#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %57 = "cute.get_scalars"(%56) : (!cute.int_tuple<"?">) -> i32
    %58 = "cute.size"(%9) <{mode = array<i32>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %59 = "cute.get_leaves"(%58) : (!cute.int_tuple<"512">) -> !cute.int_tuple<"512">
    %60 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %61 = "cute.zipped_divide"(%arg0, %60) : (!memref_gmem_f32_6, !cute.tile<"[1:0;1024:1;1:0]">) -> !memref_gmem_f32_
    %62 = "cute.get_iter"(%61) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %63 = "cute.get_iter"(%61) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %64 = "cute.make_tile"() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %65 = "cute.zipped_divide"(%34, %64) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1:0;1024:1;1:0]">) -> !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %66 = "cute.get_iter"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %67 = "cute.deref_arith_tuple_iter"(%66) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %68:3 = "cute.get_leaves"(%67) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %69 = "cute.get_iter"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %70 = "cute.deref_arith_tuple_iter"(%69) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %71:3 = "cute.get_leaves"(%70) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %72 = "cute.make_tile"() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %73 = "cute.zipped_divide"(%13, %72) : (!memref_gmem_i8_6, !cute.tile<"[1:0;512:1;1:0]">) -> !memref_gmem_i8_
    %74 = "cute.get_iter"(%73) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %75 = "cute.get_iter"(%73) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<16>>
    %76 = "cute.size"(%61) <{mode = array<i32: 1>}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %77 = "cute.get_leaves"(%76) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %78 = "cute.get_scalars"(%77) : (!cute.int_tuple<"?">) -> i32
    %79 = "cute.size"(%8) <{mode = array<i32: 0>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %80 = "cute.get_leaves"(%79) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %81 = "cute.get_layout"(%61) : (!memref_gmem_f32_) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %82 = "cute.get_layout"(%73) : (!memref_gmem_i8_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %83 = "cute.get_layout"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %84 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %85 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %86 = "cuda.cast"(%85) : (i64) -> !cuda.stream
    %87 = "arith.extsi"(%84) : (i32) -> i64
    %88 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %89 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %90 = "cuda.launch_cfg.create"(%88, %89, %89, %87, %78, %89, %89, %86) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %91 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%90, %91) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %92 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%90, %92) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %93 = "cuda.launch_ex"(%90, %61, %73, %65, %19, %21, %23) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> !cuda.result
    %94 = "cuda.cast"(%93) : (!cuda.result) -> i32
    "cuda.return_if_error"(%94) : (i32) -> ()
    %95 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%95) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
