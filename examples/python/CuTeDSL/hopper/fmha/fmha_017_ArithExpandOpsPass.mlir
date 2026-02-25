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
      %107 = "cute.static"() : () -> !cute.shape<"(2,((1)))">
      %108 = "cute.static"() : () -> !cute.shape<"(2,(1))">
      %109 = "cute.static"() : () -> !cute.int_tuple<"1">
      %110 = "cute.static"() : () -> !cute.layout<"1:0">
      %111 = "cute.static"() : () -> !cute.layout<"(128,2):(2@1,1@1)">
      %112 = "cute.static"() : () -> !cute.shape<"(2)">
      %113 = "cute.static"() : () -> !cute.shape<"(128,2)">
      %114 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %115 = "cute.static"() : () -> !cute.shape<"((1,256,1,1,1))">
      %116 = "cute.static"() : () -> !cute.layout<"(128,2):(2,1)">
      %117 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %118 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %119 = "cute.make_coord"(%118) : (i32) -> !cute.coord<"(_,?)">
      %120 = "cute.get_layout"(%arg2) : (!memref_gmem_f16_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
      %121 = "cute.crd2idx"(%119, %120) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %122 = "cute.get_iter"(%arg2) : (!memref_gmem_f16_) -> !cute.ptr<f16, gmem, align<16>>
      %123 = "cute.add_offset"(%122, %121) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f16, gmem>
      %124 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %125:10 = "cute.get_scalars"(%124) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64, i64)
      %126 = "cute.make_stride"(%125#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %127 = "cute.make_layout"(%115, %126) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1))">, !cute.stride<"((0,?{i64},0,0,0))">) -> !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %128 = "cute.crd2idx"(%119, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %129 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %130 = "cute.add_offset"(%129, %128) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %131 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %132 = "cute.crd2idx"(%119, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %133 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.arith_tuple_iter<"(0,0,0,0,0)">
      %134 = "cute.add_offset"(%133, %132) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">
      %135 = "cute.get_scalars"(%127) <{only_dynamic}> : (!cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">) -> i64
      %136 = "arith.muli"(%135, %114) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %137 = "cute.assume"(%136) : (i64) -> !cute.i64<divby 2>
      %138 = "cute.make_stride"(%137, %135) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %139 = "cute.make_layout"(%113, %138) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,2)">, !cute.stride<"(?{i64 div=2},?{i64})">) -> !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %140 = "cute.make_coord"(%117) : (i32) -> !cute.coord<"(?,_)">
      %141 = "cute.crd2idx"(%140, %116) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %142 = "cute.add_offset"(%123, %141) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %143:2 = "cute.get_scalars"(%139) <{only_dynamic}> : (!cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> (i64, i64)
      %144 = "cute.make_stride"(%143#1) : (i64) -> !cute.stride<"(?{i64})">
      %145 = "cute.make_layout"(%112, %144) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
      %146 = "cute.crd2idx"(%140, %139) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %147 = "cute.add_offset"(%130, %146) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %148 = "cute.crd2idx"(%140, %111) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %149 = "cute.add_offset"(%134, %148) : (!cute.arith_tuple_iter<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">
      %150 = "cute.deref_arith_tuple_iter"(%149) : (!cute.arith_tuple_iter<"(?,?{div=2},?,?,?)">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %151:5 = "cute.get_leaves"(%150) : (!cute.int_tuple<"(?,?{div=2},?,?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %152 = "cute.make_coord"(%151#0, %151#1, %151#2, %151#3, %151#4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %153 = "cute.make_coord"(%arg5, %arg6, %arg7, %arg8, %arg9) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %154:5 = "cute.get_scalars"(%152) : (!cute.coord<"(?,?{div=2},?,?,?)">) -> (i32, i32, i32, i32, i32)
      %155:5 = "cute.get_scalars"(%153) : (!cute.coord<"(?,?,?,?,?)">) -> (i32, i32, i32, i32, i32)
      %156 = "arith.cmpi"(%154#0, %155#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %157 = "arith.cmpi"(%154#1, %155#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %158 = "arith.andi"(%156, %157) : (i1, i1) -> i1
      %159 = "arith.cmpi"(%154#2, %155#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %160 = "arith.andi"(%158, %159) : (i1, i1) -> i1
      %161 = "arith.cmpi"(%154#3, %155#3) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %162 = "arith.andi"(%160, %161) : (i1, i1) -> i1
      %163 = "arith.cmpi"(%154#4, %155#4) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %164 = "arith.andi"(%162, %163) : (i1, i1) -> i1
      "cf.cond_br"(%164)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %165 = "cute.memref.alloca"() : () -> !memref_rmem_f16_
      %166 = "cute.get_iter"(%165) : (!memref_rmem_f16_) -> !cute.ptr<f16, rmem, align<32>>
      %167 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %168 = "cute.get_iter"(%167) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %169 = "builtin.unrealized_conversion_cast"(%142) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
      %170 = "builtin.unrealized_conversion_cast"(%166) : (!cute.ptr<f16, rmem, align<32>>) -> !llvm.ptr
      %171 = "llvm.load"(%169) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
      "llvm.store"(%171, %170) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
      %172 = "cute.add_offset"(%142, %109) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
      %173 = "cute.add_offset"(%166, %109) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
      %174 = "builtin.unrealized_conversion_cast"(%172) : (!cute.ptr<f16, gmem>) -> !llvm.ptr<1>
      %175 = "builtin.unrealized_conversion_cast"(%173) : (!cute.ptr<f16, rmem>) -> !llvm.ptr
      %176 = "llvm.load"(%174) <{alignment = 2 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf16>
      "llvm.store"(%176, %175) <{alignment = 2 : i64, ordering = 0 : i64}> : (vector<1xf16>, !llvm.ptr) -> ()
      %177 = "cute.memref.load_vec"(%165) : (!memref_rmem_f16_) -> vector<2xf16>
      %178 = "arith.extf"(%177) : (vector<2xf16>) -> vector<2xf32>
      "cute.memref.store_vec"(%178, %167) : (vector<2xf32>, !memref_rmem_f32_) -> ()
      %179 = "cute.append_to_rank"(%145, %110) <{rank = 2 : si32}> : (!cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">) -> !cute.layout<"(2,1):(?{i64},0)">
      %180 = "cute.get_scalars"(%179) <{only_dynamic}> : (!cute.layout<"(2,1):(?{i64},0)">) -> i64
      %181 = "cute.make_stride"(%180) : (i64) -> !cute.stride<"(?{i64},(0))">
      %182 = "cute.make_layout"(%108, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,(1))">, !cute.stride<"(?{i64},(0))">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
      %183 = "cute.append_to_rank"(%182, %110) <{rank = 2 : si32}> : (!cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">) -> !cute.layout<"(2,(1)):(?{i64},(0))">
      %184 = "cute.get_scalars"(%183) <{only_dynamic}> : (!cute.layout<"(2,(1)):(?{i64},(0))">) -> i64
      %185 = "cute.make_stride"(%184) : (i64) -> !cute.stride<"(?{i64},((0)))">
      %186 = "cute.make_layout"(%107, %185) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2,((1)))">, !cute.stride<"(?{i64},((0)))">) -> !cute.layout<"(2,((1))):(?{i64},((0)))">
      %187 = "cute.get_scalars"(%186) <{only_dynamic}> : (!cute.layout<"(2,((1))):(?{i64},((0)))">) -> i64
      %188 = "cute.make_stride"(%187) : (i64) -> !cute.stride<"(?{i64})">
      %189 = "cute.make_layout"(%112, %188) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(2)">, !cute.stride<"(?{i64})">) -> !cute.layout<"(2):(?{i64})">
      %190 = "cute.get_scalars"(%189) <{only_dynamic}> : (!cute.layout<"(2):(?{i64})">) -> i64
      %191 = "builtin.unrealized_conversion_cast"(%168) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %192 = "builtin.unrealized_conversion_cast"(%147) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %193 = "llvm.load"(%191) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%193, %192) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      %194 = "cute.add_offset"(%168, %109) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %195 = "cute.make_int_tuple"(%190) : (i64) -> !cute.int_tuple<"?{i64}">
      %196 = "cute.add_offset"(%147, %195) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %197 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %198 = "builtin.unrealized_conversion_cast"(%196) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %199 = "llvm.load"(%197) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%199, %198) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
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
    %26 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %27 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %28 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %29 = "arith.cmpi"(%6, %27) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %30 = "arith.select"(%29, %28, %26) : (i1, i32, i32) -> i32
    %31 = "arith.addi"(%30, %25#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %32 = "arith.divsi"(%31, %6) : (i32, i32) -> i32
    %33 = "arith.addi"(%26, %32) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %34 = "arith.subi"(%27, %25#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %35 = "arith.divsi"(%34, %6) : (i32, i32) -> i32
    %36 = "arith.subi"(%27, %35) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %37 = "arith.cmpi"(%25#1, %27) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %38 = "arith.cmpi"(%25#1, %27) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %39 = "arith.cmpi"(%6, %27) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %40 = "arith.cmpi"(%6, %27) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %41 = "arith.andi"(%37, %39) : (i1, i1) -> i1
    %42 = "arith.andi"(%38, %40) : (i1, i1) -> i1
    %43 = "arith.ori"(%41, %42) : (i1, i1) -> i1
    %44 = "arith.select"(%43, %33, %36) : (i1, i32, i32) -> i32
    %45 = "cute.make_shape"(%25#0, %44, %25#2, %25#3, %25#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %46 = "cute.make_stride"(%25#5, %25#6, %25#7, %25#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %47 = "cute.make_layout"(%45, %46) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %48 = "cute.make_view"(%24, %47) : (!cute.ptr<f16, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !memref_gmem_f16_
    %49:5 = "cute.get_scalars"(%23) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">) -> (i32, i32, i32, i32, i32)
    %50 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %51 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %52 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %53 = "arith.cmpi"(%6, %51) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %54 = "arith.select"(%53, %52, %50) : (i1, i32, i32) -> i32
    %55 = "arith.addi"(%54, %49#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %56 = "arith.divsi"(%55, %6) : (i32, i32) -> i32
    %57 = "arith.addi"(%50, %56) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %58 = "arith.subi"(%51, %49#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %59 = "arith.divsi"(%58, %6) : (i32, i32) -> i32
    %60 = "arith.subi"(%51, %59) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %61 = "arith.cmpi"(%49#1, %51) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %62 = "arith.cmpi"(%49#1, %51) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %63 = "arith.cmpi"(%6, %51) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %64 = "arith.cmpi"(%6, %51) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %65 = "arith.andi"(%61, %63) : (i1, i1) -> i1
    %66 = "arith.andi"(%62, %64) : (i1, i1) -> i1
    %67 = "arith.ori"(%65, %66) : (i1, i1) -> i1
    %68 = "arith.select"(%67, %57, %60) : (i1, i32, i32) -> i32
    %69 = "cute.make_shape"(%49#0, %68, %49#2, %49#3, %49#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %70 = "cute.make_layout"(%69, %5) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %71 = "cute.make_view"(%22, %70) : (!cute.arith_tuple_iter<"(0,0,0,0,0)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %72 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem, align<16>>
    %73 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %74:9 = "cute.get_scalars"(%73) <{only_dynamic}> : (!cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">) -> (i32, i32, i32, i32, i32, i64, i64, i64, i64)
    %75 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %76 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %77 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %78 = "arith.cmpi"(%6, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %79 = "arith.select"(%78, %77, %75) : (i1, i32, i32) -> i32
    %80 = "arith.addi"(%79, %74#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %81 = "arith.divsi"(%80, %6) : (i32, i32) -> i32
    %82 = "arith.addi"(%75, %81) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %83 = "arith.subi"(%76, %74#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %84 = "arith.divsi"(%83, %6) : (i32, i32) -> i32
    %85 = "arith.subi"(%76, %84) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %86 = "arith.cmpi"(%74#1, %76) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %87 = "arith.cmpi"(%74#1, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %88 = "arith.cmpi"(%6, %76) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %89 = "arith.cmpi"(%6, %76) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %90 = "arith.andi"(%86, %88) : (i1, i1) -> i1
    %91 = "arith.andi"(%87, %89) : (i1, i1) -> i1
    %92 = "arith.ori"(%90, %91) : (i1, i1) -> i1
    %93 = "arith.select"(%92, %82, %85) : (i1, i32, i32) -> i32
    %94 = "arith.muli"(%74#6, %4) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %95 = "cute.make_shape"(%74#0, %93, %74#2, %74#3, %74#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %96 = "cute.assume"(%94) : (i64) -> !cute.i64<divby 256>
    %97 = "cute.make_stride"(%74#6, %74#5, %96, %74#7, %74#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %98 = "cute.make_layout"(%95, %97) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">, !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %99 = "cute.make_view"(%72, %98) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !memref_gmem_f32_
    %100 = "cute.size"(%47) <{mode = array<i32: 1>}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %101 = "cute.get_leaves"(%100) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %102 = "cute.get_scalars"(%101) : (!cute.int_tuple<"?">) -> i32
    %103 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %104 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %102, %0, %0, %103) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%104, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%104, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %105 = "cuda.launch_ex"(%104, %48, %99, %71, %12, %14, %16, %18, %20) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000i64256i64i64i64_tensorptrf32gmemalign16o12561110i64000i64i64div256i641i64_tensor00000o1256111011000102561121314______Flo_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> !cuda.result
    %106 = "cuda.cast"(%105) : (!cuda.result) -> i32
    "cuda.return_if_error"(%106) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
