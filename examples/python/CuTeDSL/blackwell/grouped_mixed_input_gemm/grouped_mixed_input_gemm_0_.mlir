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
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}, {}, {}, {}, {}], function_type = (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, !cute.layout<"(128,8):(8,1)">, !cute.layout<"(128,4):(4,1)">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_i8_, %arg4: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg5: !cute.layout<"(128,8):(8,1)">, %arg6: !cute.layout<"(128,4):(4,1)">, %arg7: i32, %arg8: i32, %arg9: i32):
      %96 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %97 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %98 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %99 = "cute.deref_arith_tuple_iter"(%98) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %100:3 = "cute.get_leaves"(%99) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %101 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %102 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %103 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %104 = "cute.deref_arith_tuple_iter"(%103) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
      %105:3 = "cute.get_leaves"(%104) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
      %106 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %107 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %108 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %109 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %110 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %111 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %112 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %113 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %114 = "cute.make_coord"(%113) : (i32) -> !cute.coord<"(_,?)">
      %115 = "cute.slice"(%arg2, %114) : (!memref_gmem_f32_, !cute.coord<"(_,?)">) -> !memref_gmem_f32_1
      %116 = "cute.get_iter"(%115) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %117 = "cute.get_iter"(%115) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
      %118 = "cute.make_coord"(%113) : (i32) -> !cute.coord<"(_,?)">
      %119 = "cute.slice"(%arg3, %118) : (!memref_gmem_i8_, !cute.coord<"(_,?)">) -> !memref_gmem_i8_1
      %120 = "cute.get_iter"(%119) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %121 = "cute.get_iter"(%119) : (!memref_gmem_i8_1) -> !cute.ptr<i8, gmem>
      %122 = "cute.make_coord"(%113) : (i32) -> !cute.coord<"(_,?)">
      %123 = "cute.slice"(%arg4, %122) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, !cute.coord<"(_,?)">) -> !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %124 = "cute.get_iter"(%123) : (!cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %125 = "cute.deref_arith_tuple_iter"(%124) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %126:3 = "cute.get_leaves"(%125) : (!cute.int_tuple<"(?{div=1024},?,?)">) -> (!cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %127 = "cute.get_scalars"(%126#0) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %128 = "cute.get_scalars"(%126#1) : (!cute.int_tuple<"?">) -> i32
      %129 = "cute.get_scalars"(%126#2) : (!cute.int_tuple<"?">) -> i32
      %130 = "cute.get_iter"(%123) : (!cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %131 = "cute.deref_arith_tuple_iter"(%130) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %132:3 = "cute.get_leaves"(%131) : (!cute.int_tuple<"(?{div=1024},?,?)">) -> (!cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %133 = "cute.get_scalars"(%132#0) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %134 = "cute.get_scalars"(%132#1) : (!cute.int_tuple<"?">) -> i32
      %135 = "cute.get_scalars"(%132#2) : (!cute.int_tuple<"?">) -> i32
      %136 = "cute.composition"(%115, %arg5) : (!memref_gmem_f32_1, !cute.layout<"(128,8):(8,1)">) -> !memref_gmem_f32_2
      %137 = "cute.get_iter"(%136) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem>
      %138 = "cute.composition"(%119, %arg6) : (!memref_gmem_i8_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_i8_2
      %139 = "cute.get_iter"(%138) : (!memref_gmem_i8_2) -> !cute.ptr<i8, gmem>
      %140 = "cute.composition"(%123, %arg5) : (!cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">, !cute.layout<"(128,8):(8,1)">) -> !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %141 = "cute.get_iter"(%140) : (!cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %142 = "cute.deref_arith_tuple_iter"(%141) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %143:3 = "cute.get_leaves"(%142) : (!cute.int_tuple<"(?{div=1024},?,?)">) -> (!cute.int_tuple<"?{div=1024}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %144 = "cute.get_scalars"(%143#0) : (!cute.int_tuple<"?{div=1024}">) -> i32
      %145 = "cute.get_scalars"(%143#1) : (!cute.int_tuple<"?">) -> i32
      %146 = "cute.get_scalars"(%143#2) : (!cute.int_tuple<"?">) -> i32
      %147 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"(?,_)">
      %148 = "cute.slice"(%136, %147) : (!memref_gmem_f32_2, !cute.coord<"(?,_)">) -> !memref_gmem_f32_3
      %149 = "cute.get_iter"(%148) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %150 = "cute.get_iter"(%148) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem>
      %151 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"(?,_)">
      %152 = "cute.slice"(%138, %151) : (!memref_gmem_i8_2, !cute.coord<"(?,_)">) -> !memref_gmem_i8_3
      %153 = "cute.get_iter"(%152) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %154 = "cute.get_iter"(%152) : (!memref_gmem_i8_3) -> !cute.ptr<i8, gmem>
      %155 = "cute.make_coord"(%112) : (i32) -> !cute.coord<"(?,_)">
      %156 = "cute.slice"(%140, %155) : (!cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">, !cute.coord<"(?,_)">) -> !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %157 = "cute.get_iter"(%156) : (!cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %158 = "cute.deref_arith_tuple_iter"(%157) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %159:3 = "cute.get_leaves"(%158) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %160 = "cute.get_scalars"(%159#0) : (!cute.int_tuple<"?{div=8}">) -> i32
      %161 = "cute.get_scalars"(%159#1) : (!cute.int_tuple<"?">) -> i32
      %162 = "cute.get_scalars"(%159#2) : (!cute.int_tuple<"?">) -> i32
      %163 = "cute.get_iter"(%156) : (!cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %164 = "cute.deref_arith_tuple_iter"(%163) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %165:3 = "cute.get_leaves"(%164) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %166 = "cute.get_scalars"(%165#0) : (!cute.int_tuple<"?{div=8}">) -> i32
      %167 = "cute.get_scalars"(%165#1) : (!cute.int_tuple<"?">) -> i32
      %168 = "cute.get_scalars"(%165#2) : (!cute.int_tuple<"?">) -> i32
      %169 = "cute.make_coord"() : () -> !cute.coord<"0">
      %170 = "cute.slice"(%156, %169) : (!cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">, !cute.coord<"0">) -> !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %171 = "cute.get_iter"(%170) : (!cute.coord_tensor<"(?{div=8},?,?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %172 = "cute.deref_arith_tuple_iter"(%171) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %173:3 = "cute.get_leaves"(%172) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %174 = "cute.get_scalars"(%173#0) : (!cute.int_tuple<"?{div=8}">) -> i32
      %175 = "cute.get_scalars"(%173#1) : (!cute.int_tuple<"?">) -> i32
      %176 = "cute.get_scalars"(%173#2) : (!cute.int_tuple<"?">) -> i32
      %177 = "cute.get_iter"(%170) : (!cute.coord_tensor<"(?{div=8},?,?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %178 = "cute.deref_arith_tuple_iter"(%177) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %179:3 = "cute.get_leaves"(%178) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %180 = "cute.get_scalars"(%179#0) : (!cute.int_tuple<"?{div=8}">) -> i32
      %181 = "cute.get_scalars"(%179#1) : (!cute.int_tuple<"?">) -> i32
      %182 = "cute.get_scalars"(%179#2) : (!cute.int_tuple<"?">) -> i32
      %183 = "cute.get_iter"(%170) : (!cute.coord_tensor<"(?{div=8},?,?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %184 = "cute.deref_arith_tuple_iter"(%183) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %185:3 = "cute.get_leaves"(%184) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %186 = "cute.get_scalars"(%185#0) : (!cute.int_tuple<"?{div=8}">) -> i32
      %187 = "cute.get_scalars"(%185#1) : (!cute.int_tuple<"?">) -> i32
      %188 = "cute.get_scalars"(%185#2) : (!cute.int_tuple<"?">) -> i32
      %189 = "cute.make_coord"(%185#0, %185#1, %185#2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %190 = "cute.make_coord"(%arg7, %arg8, %arg9) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %191 = "cute.elem_less"(%189, %190) : (!cute.coord<"(?{div=8},?,?)">, !cute.coord<"(?,?,?)">) -> i1
      "scf.if"(%191) ({
        %192 = "cute.get_shape"(%arg5) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %193:2 = "cute.get_leaves"(%192) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %194 = "cute.get_shape"(%arg5) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %195:2 = "cute.get_leaves"(%194) : (!cute.shape<"(128,8)">) -> (!cute.shape<"128">, !cute.shape<"8">)
        %196 = "cute.get"(%arg5) <{mode = array<i32: 1>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"8:1">
        %197 = "cute.memref.alloca"(%196) : (!cute.layout<"8:1">) -> !memref_rmem_f32_
        %198 = "cute.get_iter"(%197) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %199 = "cute.get_iter"(%197) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %200 = "cute.get_shape"(%arg6) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %201:2 = "cute.get_leaves"(%200) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %202 = "cute.get_shape"(%arg6) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %203:2 = "cute.get_leaves"(%202) : (!cute.shape<"(128,4)">) -> (!cute.shape<"128">, !cute.shape<"4">)
        %204 = "cute.get"(%arg6) <{mode = array<i32: 1>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.layout<"4:1">
        %205 = "cute.memref.alloca"(%204) : (!cute.layout<"4:1">) -> !memref_rmem_i8_
        %206 = "cute.get_iter"(%205) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %207 = "cute.get_iter"(%205) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %208 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %209 = "cute.get_layout"(%148) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %210 = "cute.get_shape"(%209) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %211 = "cute.get_leaves"(%210) : (!cute.shape<"(8)">) -> !cute.shape<"8">
        %212 = "cute.get_layout"(%197) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %213 = "cute.get_shape"(%212) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %214 = "cute.get_leaves"(%213) : (!cute.shape<"8">) -> !cute.shape<"8">
        %215 = "cute.get_layout"(%148) : (!memref_gmem_f32_3) -> !cute.layout<"(8):(1)">
        %216 = "cute.make_shape"() : () -> !cute.shape<"1">
        %217 = "cute.make_layout"(%216) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %218 = "cute.append_to_rank"(%215, %217) <{rank = 2 : si32}> : (!cute.layout<"(8):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %219 = "cute.make_view"(%150, %218) : (!cute.ptr<f32, gmem>, !cute.layout<"(8,1):(1,0)">) -> !memref_gmem_f32_4
        %220 = "cute.get_iter"(%219) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem>
        %221 = "cute.get_layout"(%219) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %222 = "cute.get_shape"(%221) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %223:2 = "cute.get_leaves"(%222) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %224 = "cute.get_layout"(%219) : (!memref_gmem_f32_4) -> !cute.layout<"(8,1):(1,0)">
        %225 = "cute.get_shape"(%224) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %226:2 = "cute.get_leaves"(%225) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %227 = "cute.group_modes"(%219) <{begin = 1 : i32, end = 2 : i32}> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %228 = "cute.get_iter"(%227) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %229 = "cute.get_iter"(%227) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem>
        %230 = "cute.get_layout"(%197) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %231 = "cute.make_shape"() : () -> !cute.shape<"1">
        %232 = "cute.make_layout"(%231) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %233 = "cute.append_to_rank"(%230, %232) <{rank = 2 : si32}> : (!cute.layout<"8:1">, !cute.layout<"1:0">) -> !cute.layout<"(8,1):(1,0)">
        %234 = "cute.make_view"(%199, %233) : (!cute.ptr<f32, rmem, align<32>>, !cute.layout<"(8,1):(1,0)">) -> !memref_rmem_f32_1
        %235 = "cute.get_iter"(%234) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %236 = "cute.get_layout"(%234) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %237 = "cute.get_shape"(%236) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %238:2 = "cute.get_leaves"(%237) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %239 = "cute.get_layout"(%234) : (!memref_rmem_f32_1) -> !cute.layout<"(8,1):(1,0)">
        %240 = "cute.get_shape"(%239) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %241:2 = "cute.get_leaves"(%240) : (!cute.shape<"(8,1)">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %242 = "cute.group_modes"(%234) <{begin = 1 : i32, end = 2 : i32}> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %243 = "cute.get_iter"(%242) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %244 = "cute.get_iter"(%242) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<32>>
        %245 = "cute.get_layout"(%227) : (!memref_gmem_f32_5) -> !cute.layout<"(8,(1)):(1,(0))">
        %246 = "cute.get_shape"(%245) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %247:2 = "cute.get_leaves"(%246) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %248 = "cute.get_layout"(%242) : (!memref_rmem_f32_2) -> !cute.layout<"(8,(1)):(1,(0))">
        %249 = "cute.get_shape"(%248) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %250:2 = "cute.get_leaves"(%249) : (!cute.shape<"(8,(1))">) -> (!cute.shape<"8">, !cute.shape<"1">)
        %251 = "cute.size"(%227) <{mode = array<i32: 1>}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %252 = "cute.get_leaves"(%251) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %253 = "cute.size"(%242) <{mode = array<i32: 1>}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %254 = "cute.get_leaves"(%253) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%208, %227, %242) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2) -> ()
        %255 = "cute.get_layout"(%197) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %256 = "cute.get_shape"(%255) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %257 = "cute.get_leaves"(%256) : (!cute.shape<"8">) -> !cute.shape<"8">
        %258 = "cute.memref.load_vec"(%197) : (!memref_rmem_f32_) -> vector<8xf32>
        %259 = "cute.get_layout"(%197) : (!memref_rmem_f32_) -> !cute.layout<"8:1">
        %260 = "cute.get_shape"(%259) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %261 = "cute.get_leaves"(%260) : (!cute.shape<"8">) -> !cute.shape<"8">
        %262 = "arith.fptosi"(%258) : (vector<8xf32>) -> vector<8xi4>
        %263 = "cute.make_shape"() : () -> !cute.shape<"8">
        %264 = "cute.make_layout"(%263) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"8">) -> !cute.layout<"8:1">
        %265 = "cute.recast_layout"(%264) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
        %266 = "cute.get_shape"(%265) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %267 = "cute.get_leaves"(%266) : (!cute.shape<"4">) -> !cute.shape<"4">
        %268 = "builtin.unrealized_conversion_cast"(%262) : (vector<8xi4>) -> vector<8xi4>
        %269 = "vector.bitcast"(%268) : (vector<8xi4>) -> vector<4xi8>
        %270 = "cute.get_layout"(%205) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %271 = "cute.get_shape"(%270) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %272 = "cute.get_leaves"(%271) : (!cute.shape<"4">) -> !cute.shape<"4">
        %273 = "cute.get_layout"(%205) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %274 = "cute.get_shape"(%273) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %275 = "cute.get_leaves"(%274) : (!cute.shape<"4">) -> !cute.shape<"4">
        %276 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %277 = "cute.size"(%276) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %278 = "cute.get_leaves"(%277) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %279 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"4">
        %280 = "cute.size"(%279) <{mode = array<i32>}> : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %281 = "cute.get_leaves"(%280) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        "cute.memref.store_vec"(%269, %205) : (vector<4xi8>, !memref_rmem_i8_) -> ()
        %282 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %283 = "cute.get_layout"(%205) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %284 = "cute.get_shape"(%283) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %285 = "cute.get_leaves"(%284) : (!cute.shape<"4">) -> !cute.shape<"4">
        %286 = "cute.get_layout"(%152) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %287 = "cute.get_shape"(%286) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %288 = "cute.get_leaves"(%287) : (!cute.shape<"(4)">) -> !cute.shape<"4">
        %289 = "cute.get_layout"(%205) : (!memref_rmem_i8_) -> !cute.layout<"4:1">
        %290 = "cute.make_shape"() : () -> !cute.shape<"1">
        %291 = "cute.make_layout"(%290) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %292 = "cute.append_to_rank"(%289, %291) <{rank = 2 : si32}> : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %293 = "cute.make_view"(%207, %292) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(4,1):(1,0)">) -> !memref_rmem_i8_1
        %294 = "cute.get_iter"(%293) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %295 = "cute.get_layout"(%293) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %296 = "cute.get_shape"(%295) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %297:2 = "cute.get_leaves"(%296) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %298 = "cute.get_layout"(%293) : (!memref_rmem_i8_1) -> !cute.layout<"(4,1):(1,0)">
        %299 = "cute.get_shape"(%298) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %300:2 = "cute.get_leaves"(%299) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %301 = "cute.group_modes"(%293) <{begin = 1 : i32, end = 2 : i32}> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %302 = "cute.get_iter"(%301) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %303 = "cute.get_iter"(%301) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %304 = "cute.get_layout"(%152) : (!memref_gmem_i8_3) -> !cute.layout<"(4):(1)">
        %305 = "cute.make_shape"() : () -> !cute.shape<"1">
        %306 = "cute.make_layout"(%305) <{operandSegmentSizes = array<i32: 1, 0>}> : (!cute.shape<"1">) -> !cute.layout<"1:0">
        %307 = "cute.append_to_rank"(%304, %306) <{rank = 2 : si32}> : (!cute.layout<"(4):(1)">, !cute.layout<"1:0">) -> !cute.layout<"(4,1):(1,0)">
        %308 = "cute.make_view"(%154, %307) : (!cute.ptr<i8, gmem>, !cute.layout<"(4,1):(1,0)">) -> !memref_gmem_i8_4
        %309 = "cute.get_iter"(%308) : (!memref_gmem_i8_4) -> !cute.ptr<i8, gmem>
        %310 = "cute.get_layout"(%308) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %311 = "cute.get_shape"(%310) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %312:2 = "cute.get_leaves"(%311) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %313 = "cute.get_layout"(%308) : (!memref_gmem_i8_4) -> !cute.layout<"(4,1):(1,0)">
        %314 = "cute.get_shape"(%313) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %315:2 = "cute.get_leaves"(%314) : (!cute.shape<"(4,1)">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %316 = "cute.group_modes"(%308) <{begin = 1 : i32, end = 2 : i32}> : (!memref_gmem_i8_4) -> !memref_gmem_i8_5
        %317 = "cute.get_iter"(%316) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %318 = "cute.get_iter"(%316) : (!memref_gmem_i8_5) -> !cute.ptr<i8, gmem>
        %319 = "cute.get_layout"(%301) : (!memref_rmem_i8_2) -> !cute.layout<"(4,(1)):(1,(0))">
        %320 = "cute.get_shape"(%319) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %321:2 = "cute.get_leaves"(%320) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %322 = "cute.get_layout"(%316) : (!memref_gmem_i8_5) -> !cute.layout<"(4,(1)):(1,(0))">
        %323 = "cute.get_shape"(%322) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %324:2 = "cute.get_leaves"(%323) : (!cute.shape<"(4,(1))">) -> (!cute.shape<"4">, !cute.shape<"1">)
        %325 = "cute.size"(%301) <{mode = array<i32: 1>}> : (!memref_rmem_i8_2) -> !cute.int_tuple<"1">
        %326 = "cute.get_leaves"(%325) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        %327 = "cute.size"(%316) <{mode = array<i32: 1>}> : (!memref_gmem_i8_5) -> !cute.int_tuple<"1">
        %328 = "cute.get_leaves"(%327) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
        "cute.copy"(%282, %301, %316) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_2, !memref_gmem_i8_5) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_6, !memref_gmem_i4_) -> i32, sym_name = "cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8"}> ({
  ^bb0(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_i4_):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_i4_) -> !cute.ptr<i4, gmem, align<128>>
    %2 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem>
    %3 = "cute.get_iter"(%arg1) : (!memref_gmem_i4_) -> !cute.ptr<i4, gmem, align<128>>
    %4 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %5 = "cute.get_layout"(%arg1) : (!memref_gmem_i4_) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %6 = "cute.make_shape"() : () -> !cute.shape<"(128,8)">
    %7 = "cute.make_stride"() : () -> !cute.stride<"(8,1)">
    %8 = "cute.make_layout"(%6, %7) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(128,8):(8,1)">
    %9 = "cute.recast_layout"(%8) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.layout<"(128,4):(4,1)">
    %10 = "cute.recast_iter"(%3) : (!cute.ptr<i4, gmem, align<128>>) -> !cute.ptr<i8, gmem, align<128>>
    %11 = "cute.get_layout"(%arg1) : (!memref_gmem_i4_) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %12 = "cute.recast_layout"(%11) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %13 = "cute.make_view"(%10, %12) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !memref_gmem_i8_6
    %14 = "cute.get_iter"(%13) : (!memref_gmem_i8_6) -> !cute.ptr<i8, gmem, align<128>>
    %15 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %16 = "cute.get_shape"(%15) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %17:3 = "cute.get_leaves"(%16) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %18 = "cute.to_int_tuple"(%17#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %19 = "cute.get_scalars"(%18) : (!cute.int_tuple<"?">) -> i32
    %20 = "cute.to_int_tuple"(%17#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.get_scalars"(%20) : (!cute.int_tuple<"?">) -> i32
    %22 = "cute.to_int_tuple"(%17#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %23 = "cute.get_scalars"(%22) : (!cute.int_tuple<"?">) -> i32
    %24 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %25 = "cute.get_shape"(%24) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
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
    %38 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %39 = "cute.get_shape"(%38) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %40:3 = "cute.get_leaves"(%39) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %41 = "cute.to_int_tuple"(%40#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %42 = "cute.get_scalars"(%41) : (!cute.int_tuple<"?">) -> i32
    %43 = "cute.to_int_tuple"(%40#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %44 = "cute.get_scalars"(%43) : (!cute.int_tuple<"?">) -> i32
    %45 = "cute.to_int_tuple"(%40#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.get_scalars"(%45) : (!cute.int_tuple<"?">) -> i32
    %47 = "cute.size"(%8) <{mode = array<i32>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %48 = "cute.get_leaves"(%47) : (!cute.int_tuple<"1024">) -> !cute.int_tuple<"1024">
    %49 = "cute.get_layout"(%13) : (!memref_gmem_i8_6) -> !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %50 = "cute.get_shape"(%49) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %51:3 = "cute.get_leaves"(%50) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %52 = "cute.to_int_tuple"(%51#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %53 = "cute.get_scalars"(%52) : (!cute.int_tuple<"?">) -> i32
    %54 = "cute.to_int_tuple"(%51#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %55 = "cute.get_scalars"(%54) : (!cute.int_tuple<"?">) -> i32
    %56 = "cute.to_int_tuple"(%51#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %57 = "cute.get_scalars"(%56) : (!cute.int_tuple<"?">) -> i32
    %58 = "cute.size"(%9) <{mode = array<i32>}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %59 = "cute.get_leaves"(%58) : (!cute.int_tuple<"512">) -> !cute.int_tuple<"512">
    %60 = "cute.make_tile"() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %61 = "cute.zipped_divide"(%arg0, %60) : (!memref_gmem_f32_6, !cute.tile<"[1024:1;1:0;1:0]">) -> !memref_gmem_f32_
    %62 = "cute.get_iter"(%61) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %63 = "cute.get_iter"(%61) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
    %64 = "cute.make_tile"() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %65 = "cute.zipped_divide"(%34, %64) : (!cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1024:1;1:0;1:0]">) -> !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %66 = "cute.get_iter"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %67 = "cute.deref_arith_tuple_iter"(%66) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %68:3 = "cute.get_leaves"(%67) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %69 = "cute.get_iter"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
    %70 = "cute.deref_arith_tuple_iter"(%69) : (!cute.arith_tuple_iter<"(0,0,0)">) -> !cute.int_tuple<"(0,0,0)">
    %71:3 = "cute.get_leaves"(%70) : (!cute.int_tuple<"(0,0,0)">) -> (!cute.int_tuple<"0">, !cute.int_tuple<"0">, !cute.int_tuple<"0">)
    %72 = "cute.make_tile"() : () -> !cute.tile<"[512:1;1:0;1:0]">
    %73 = "cute.zipped_divide"(%13, %72) : (!memref_gmem_i8_6, !cute.tile<"[512:1;1:0;1:0]">) -> !memref_gmem_i8_
    %74 = "cute.get_iter"(%73) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
    %75 = "cute.get_iter"(%73) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
    %76 = "cute.size"(%61) <{mode = array<i32: 1>}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %77 = "cute.get_leaves"(%76) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %78 = "cute.get_scalars"(%77) : (!cute.int_tuple<"?">) -> i32
    %79 = "cute.size"(%8) <{mode = array<i32: 0>}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %80 = "cute.get_leaves"(%79) : (!cute.int_tuple<"128">) -> !cute.int_tuple<"128">
    %81 = "cute.get_layout"(%61) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %82 = "cute.get_layout"(%73) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %83 = "cute.get_layout"(%65) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
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
    %93 = "cuda.launch_ex"(%90, %61, %73, %65, %8, %9, %19, %21, %23) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, !cute.layout<"(128,8):(8,1)">, !cute.layout<"(128,4):(4,1)">, i32, i32, i32) -> !cuda.result
    %94 = "cuda.cast"(%93) : (!cuda.result) -> i32
    "cuda.return_if_error"(%94) : (i32) -> ()
    %95 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%95) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
