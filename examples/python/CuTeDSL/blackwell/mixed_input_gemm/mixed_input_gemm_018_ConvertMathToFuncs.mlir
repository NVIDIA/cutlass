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
      %105 = "cute.static"() : () -> !cute.int_tuple<"7">
      %106 = "cute.static"() : () -> !cute.int_tuple<"6">
      %107 = "cute.static"() : () -> !cute.int_tuple<"5">
      %108 = "cute.static"() : () -> !cute.int_tuple<"4">
      %109 = "cute.static"() : () -> !cute.int_tuple<"3">
      %110 = "cute.static"() : () -> !cute.int_tuple<"2">
      %111 = "cute.static"() : () -> !cute.int_tuple<"1">
      %112 = "cute.static"() : () -> !cute.layout<"8:1">
      %113 = "cute.static"() : () -> !cute.layout<"(128,8):(8@0,1@0)">
      %114 = "cute.static"() : () -> !cute.layout<"(128,8):(8,1)">
      %115 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %116 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %117 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %118 = "cute.make_coord"(%117) : (i32) -> !cute.coord<"(_,?)">
      %119 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
      %120 = "cute.crd2idx"(%118, %119) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %121 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %122 = "cute.add_offset"(%121, %120) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %123 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
      %124 = "cute.crd2idx"(%118, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %125 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem, align<128>>
      %126 = "cute.add_offset"(%125, %124) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %127 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %128 = "cute.crd2idx"(%118, %127) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %129 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %130 = "cute.add_offset"(%129, %128) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.arith_tuple_iter<"(?{div=1024},?,?)">
      %131 = "cute.make_coord"(%116) : (i32) -> !cute.coord<"(?,_)">
      %132 = "cute.crd2idx"(%131, %114) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %133 = "cute.add_offset"(%122, %132) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %134 = "cute.crd2idx"(%131, %115) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %135 = "cute.add_offset"(%126, %134) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %136 = "cute.crd2idx"(%131, %113) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %137 = "cute.add_offset"(%130, %136) : (!cute.arith_tuple_iter<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.arith_tuple_iter<"(?{div=8},?,?)">
      %138 = "cute.deref_arith_tuple_iter"(%137) : (!cute.arith_tuple_iter<"(?{div=8},?,?)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %139:3 = "cute.get_leaves"(%138) : (!cute.int_tuple<"(?{div=8},?,?)">) -> (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %140 = "cute.make_coord"(%139#0, %139#1, %139#2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %141 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %142:3 = "cute.get_scalars"(%140) : (!cute.coord<"(?{div=8},?,?)">) -> (i32, i32, i32)
      %143:3 = "cute.get_scalars"(%141) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %144 = "arith.cmpi"(%142#0, %143#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %145 = "arith.cmpi"(%142#1, %143#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %146 = "arith.andi"(%144, %145) : (i1, i1) -> i1
      %147 = "arith.cmpi"(%142#2, %143#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %148 = "arith.andi"(%146, %147) : (i1, i1) -> i1
      "cf.cond_br"(%148)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %149 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %150 = "cute.get_iter"(%149) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %151 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %152 = "cute.get_iter"(%151) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %153 = "builtin.unrealized_conversion_cast"(%133) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %154 = "builtin.unrealized_conversion_cast"(%150) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %155 = "llvm.load"(%153) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%155, %154) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %156 = "cute.add_offset"(%133, %111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %157 = "cute.add_offset"(%150, %111) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %158 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %159 = "builtin.unrealized_conversion_cast"(%157) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %160 = "llvm.load"(%158) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%160, %159) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %161 = "cute.add_offset"(%133, %110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %162 = "cute.add_offset"(%150, %110) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %163 = "builtin.unrealized_conversion_cast"(%161) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %164 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %165 = "llvm.load"(%163) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%165, %164) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %166 = "cute.add_offset"(%133, %109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %167 = "cute.add_offset"(%150, %109) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %168 = "builtin.unrealized_conversion_cast"(%166) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %169 = "builtin.unrealized_conversion_cast"(%167) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %170 = "llvm.load"(%168) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%170, %169) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %171 = "cute.add_offset"(%133, %108) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
      %172 = "cute.add_offset"(%150, %108) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %173 = "builtin.unrealized_conversion_cast"(%171) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %174 = "builtin.unrealized_conversion_cast"(%172) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %175 = "llvm.load"(%173) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%175, %174) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %176 = "cute.add_offset"(%133, %107) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
      %177 = "cute.add_offset"(%150, %107) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %178 = "builtin.unrealized_conversion_cast"(%176) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %179 = "builtin.unrealized_conversion_cast"(%177) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %180 = "llvm.load"(%178) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%180, %179) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %181 = "cute.add_offset"(%133, %106) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
      %182 = "cute.add_offset"(%150, %106) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %183 = "builtin.unrealized_conversion_cast"(%181) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %184 = "builtin.unrealized_conversion_cast"(%182) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %185 = "llvm.load"(%183) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%185, %184) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %186 = "cute.add_offset"(%133, %105) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
      %187 = "cute.add_offset"(%150, %105) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %188 = "builtin.unrealized_conversion_cast"(%186) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %189 = "builtin.unrealized_conversion_cast"(%187) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %190 = "llvm.load"(%188) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%190, %189) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %191 = "cute.memref.load_vec"(%149) : (!memref_rmem_f32_) -> vector<8xf32>
      %192 = "arith.fptosi"(%191) : (vector<8xf32>) -> vector<8xi4>
      %193 = "cute.recast_layout"(%112) <{new_type_bits = 8 : i32, old_type_bits = 4 : i32}> : (!cute.layout<"8:1">) -> !cute.layout<"4:1">
      %194 = "vector.bitcast"(%192) : (vector<8xi4>) -> vector<4xi8>
      "cute.memref.store_vec"(%194, %151) : (vector<4xi8>, !memref_rmem_i8_) -> ()
      %195 = "builtin.unrealized_conversion_cast"(%152) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %196 = "builtin.unrealized_conversion_cast"(%135) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %197 = "llvm.load"(%195) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%197, %196) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %198 = "cute.add_offset"(%152, %111) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %199 = "cute.add_offset"(%135, %111) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
      %200 = "builtin.unrealized_conversion_cast"(%198) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %201 = "builtin.unrealized_conversion_cast"(%199) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %202 = "llvm.load"(%200) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%202, %201) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %203 = "cute.add_offset"(%152, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %204 = "cute.add_offset"(%135, %110) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
      %205 = "builtin.unrealized_conversion_cast"(%203) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %206 = "builtin.unrealized_conversion_cast"(%204) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %207 = "llvm.load"(%205) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%207, %206) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %208 = "cute.add_offset"(%152, %109) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %209 = "cute.add_offset"(%135, %109) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
      %210 = "builtin.unrealized_conversion_cast"(%208) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %211 = "builtin.unrealized_conversion_cast"(%209) : (!cute.ptr<i8, gmem>) -> !llvm.ptr<1>
      %212 = "llvm.load"(%210) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%212, %211) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
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
    %28 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %29 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %30 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %31 = "arith.cmpi"(%6, %29) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %32 = "arith.select"(%31, %30, %28) : (i1, i32, i32) -> i32
    %33 = "arith.addi"(%32, %27#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %34 = "arith.divsi"(%33, %6) : (i32, i32) -> i32
    %35 = "arith.addi"(%28, %34) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %36 = "arith.subi"(%29, %27#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %37 = "arith.divsi"(%36, %6) : (i32, i32) -> i32
    %38 = "arith.subi"(%29, %37) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %39 = "arith.cmpi"(%27#0, %29) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %40 = "arith.cmpi"(%27#0, %29) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %41 = "arith.cmpi"(%6, %29) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %42 = "arith.cmpi"(%6, %29) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %43 = "arith.andi"(%39, %41) : (i1, i1) -> i1
    %44 = "arith.andi"(%40, %42) : (i1, i1) -> i1
    %45 = "arith.ori"(%43, %44) : (i1, i1) -> i1
    %46 = "arith.select"(%45, %35, %38) : (i1, i32, i32) -> i32
    %47 = "cute.make_shape"(%46, %27#1, %27#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %48 = "cute.make_stride"(%27#3, %27#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %49 = "cute.make_layout"(%47, %48) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %50 = "cute.make_view"(%26, %49) : (!cute.ptr<f32, gmem>, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !memref_gmem_f32_
    %51:3 = "cute.get_scalars"(%25) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %52 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %53 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %54 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %55 = "arith.cmpi"(%6, %53) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %56 = "arith.select"(%55, %54, %52) : (i1, i32, i32) -> i32
    %57 = "arith.addi"(%56, %51#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %58 = "arith.divsi"(%57, %6) : (i32, i32) -> i32
    %59 = "arith.addi"(%52, %58) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %60 = "arith.subi"(%53, %51#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %61 = "arith.divsi"(%60, %6) : (i32, i32) -> i32
    %62 = "arith.subi"(%53, %61) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %63 = "arith.cmpi"(%51#0, %53) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %64 = "arith.cmpi"(%51#0, %53) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %65 = "arith.cmpi"(%6, %53) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %66 = "arith.cmpi"(%6, %53) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %67 = "arith.andi"(%63, %65) : (i1, i1) -> i1
    %68 = "arith.andi"(%64, %66) : (i1, i1) -> i1
    %69 = "arith.ori"(%67, %68) : (i1, i1) -> i1
    %70 = "arith.select"(%69, %59, %62) : (i1, i32, i32) -> i32
    %71 = "cute.make_shape"(%70, %51#1, %51#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %72 = "cute.make_layout"(%71, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1024,1,1),(?,?,?))">, !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %73 = "cute.make_view"(%24, %72) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %74:5 = "cute.get_scalars"(%13) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> (i32, i32, i32, i64, i64)
    %75 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %76 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %77 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %78 = "arith.cmpi"(%4, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %79 = "arith.select"(%78, %77, %75) : (i1, i32, i32) -> i32
    %80 = "arith.addi"(%79, %74#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %81 = "arith.divsi"(%80, %4) : (i32, i32) -> i32
    %82 = "arith.addi"(%75, %81) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %83 = "arith.subi"(%76, %74#0) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %84 = "arith.divsi"(%83, %4) : (i32, i32) -> i32
    %85 = "arith.subi"(%76, %84) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %86 = "arith.cmpi"(%74#0, %76) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %87 = "arith.cmpi"(%74#0, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %88 = "arith.cmpi"(%4, %76) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %89 = "arith.cmpi"(%4, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %90 = "arith.andi"(%86, %88) : (i1, i1) -> i1
    %91 = "arith.andi"(%87, %89) : (i1, i1) -> i1
    %92 = "arith.ori"(%90, %91) : (i1, i1) -> i1
    %93 = "arith.select"(%92, %82, %85) : (i1, i32, i32) -> i32
    %94 = "cute.make_shape"(%93, %74#1, %74#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %95 = "cute.make_stride"(%74#3, %74#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %96 = "cute.make_layout"(%94, %95) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((512,1,1),(?,?,?))">, !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">) -> !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %97 = "cute.make_view"(%11, %96) : (!cute.ptr<i8, gmem, align<128>>, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !memref_gmem_i8_
    %98 = "cute.size"(%49) <{mode = array<i32: 1>}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %99 = "cute.get_leaves"(%98) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %100 = "cute.get_scalars"(%99) : (!cute.int_tuple<"?">) -> i32
    %101 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %102 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %100, %0, %0, %101) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%102, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%102, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %103 = "cuda.launch_ex"(%102, %50, %97, %73, %18, %20, %22) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> !cuda.result
    %104 = "cuda.cast"(%103) : (!cuda.result) -> i32
    "cuda.return_if_error"(%104) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
