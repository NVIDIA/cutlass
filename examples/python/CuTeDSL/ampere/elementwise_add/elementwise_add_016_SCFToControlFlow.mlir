!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %63 = "cute.static"() : () -> !cute.int_tuple<"15">
      %64 = "cute.static"() : () -> !cute.int_tuple<"14">
      %65 = "cute.static"() : () -> !cute.int_tuple<"13">
      %66 = "cute.static"() : () -> !cute.int_tuple<"12">
      %67 = "cute.static"() : () -> !cute.int_tuple<"11">
      %68 = "cute.static"() : () -> !cute.int_tuple<"10">
      %69 = "cute.static"() : () -> !cute.int_tuple<"9">
      %70 = "cute.static"() : () -> !cute.int_tuple<"8">
      %71 = "arith.constant"() <{value = 3 : i64}> : () -> i64
      %72 = "cute.static"() : () -> !cute.int_tuple<"7">
      %73 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %74 = "cute.static"() : () -> !cute.int_tuple<"6">
      %75 = "arith.constant"() <{value = 1 : i64}> : () -> i64
      %76 = "cute.static"() : () -> !cute.int_tuple<"5">
      %77 = "cute.static"() : () -> !cute.int_tuple<"4">
      %78 = "cute.static"() : () -> !cute.int_tuple<"3">
      %79 = "cute.static"() : () -> !cute.int_tuple<"2">
      %80 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %81 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
      %82 = "cute.static"() : () -> !cute.int_tuple<"1">
      %83 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %84 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %85 = "cute.static"() : () -> !cute.layout<"1:0">
      %86 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %87 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %88 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %89 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %90 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %91 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %92 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %93 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %94 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %95 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %96 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %97 = "cute.make_coord"(%96) : (i32) -> !cute.coord<"((_,_),?)">
      %98 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %99:4 = "cute.get_scalars"(%98) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %100 = "cute.make_stride"(%99#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %101 = "cute.make_layout"(%94, %100) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %102 = "cute.crd2idx"(%97, %98) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %103 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %104 = "cute.add_offset"(%103, %102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %105 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %106:4 = "cute.get_scalars"(%105) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %107 = "cute.make_stride"(%106#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %108 = "cute.make_layout"(%94, %107) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %109 = "cute.crd2idx"(%97, %105) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %110 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %111 = "cute.add_offset"(%110, %109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %112 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %113:4 = "cute.get_scalars"(%112) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %114 = "cute.make_stride"(%113#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %115 = "cute.make_layout"(%94, %114) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %116 = "cute.crd2idx"(%97, %112) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %117 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %118 = "cute.add_offset"(%117, %116) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %119 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %120 = "cute.crd2idx"(%97, %119) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %121 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %122 = "cute.add_offset"(%121, %120) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %123 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %124 = "cute.make_tiled_copy"(%123) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %125 = "cute.make_tiled_copy"(%123) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %126 = "cute.make_tiled_copy"(%123) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %127 = "cute.get_scalars"(%101) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %128 = "arith.muli"(%127, %93) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %129 = "arith.divsi"(%95, %92) : (i32, i32) -> i32
      %130 = "arith.remsi"(%95, %92) : (i32, i32) -> i32
      %131 = "arith.muli"(%130, %91) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %132 = "arith.extsi"(%129) : (i32) -> i64
      %133 = "arith.muli"(%132, %128) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %134 = "arith.extsi"(%131) : (i32) -> i64
      %135 = "arith.addi"(%134, %133) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %136 = "cute.assume"(%135) : (i64) -> !cute.i64<divby 4>
      %137 = "cute.make_int_tuple"(%136) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %138 = "cute.add_offset"(%104, %137) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %139 = "cute.make_stride"(%127) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %140 = "cute.make_layout"(%90, %139) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %141 = "cute.get_scalars"(%108) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %142 = "arith.muli"(%141, %93) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %143 = "arith.muli"(%132, %142) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %144 = "arith.addi"(%134, %143) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %145 = "cute.assume"(%144) : (i64) -> !cute.i64<divby 4>
      %146 = "cute.make_int_tuple"(%145) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %147 = "cute.add_offset"(%111, %146) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %148 = "cute.make_stride"(%141) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %149 = "cute.make_layout"(%90, %148) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %150 = "cute.get_scalars"(%115) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %151 = "arith.muli"(%150, %93) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %152 = "arith.muli"(%132, %151) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %153 = "arith.addi"(%134, %152) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %154 = "cute.assume"(%153) : (i64) -> !cute.i64<divby 4>
      %155 = "cute.make_int_tuple"(%154) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %156 = "cute.add_offset"(%118, %155) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %157 = "cute.make_stride"(%150) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %158 = "cute.make_layout"(%90, %157) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %159 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %160 = "cute.get_iter"(%159) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %161 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %162 = "cute.get_iter"(%161) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %163 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %164 = "cute.get_iter"(%163) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %165 = "arith.muli"(%129, %91) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %166 = "cute.assume"(%165) : (i32) -> !cute.i32<divby 4>
      %167 = "cute.assume"(%131) : (i32) -> !cute.i32<divby 4>
      %168 = "cute.make_int_tuple"(%166, %167) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %169 = "cute.add_offset"(%122, %168) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %170 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %171 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
      %172:2 = "cute.get_scalars"(%171) : (!cute.coord<"(?,?)">) -> (i32, i32)
      "cf.br"(%89)[^bb1] : (i32) -> ()
    ^bb1(%173: i32):  // 2 preds: ^bb0, ^bb2
      %174 = "arith.cmpi"(%173, %88) <{predicate = 2 : i64}> : (i32, i32) -> i1
      "cf.cond_br"(%174)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb2:  // pred: ^bb1
      %175 = "cute.make_coord"(%173) : (i32) -> !cute.coord<"?">
      %176 = "cute.crd2idx"(%175, %86) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
      %177 = "cute.add_offset"(%169, %176) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %178 = "cute.deref_arith_tuple_iter"(%177) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %179:2 = "cute.get_leaves"(%178) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
      %180 = "cute.make_coord"(%179#0, %179#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %181:2 = "cute.get_scalars"(%180) : (!cute.coord<"(?,?)">) -> (i32, i32)
      %182 = "arith.cmpi"(%181#0, %172#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %183 = "arith.cmpi"(%181#1, %172#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %184 = "arith.andi"(%182, %183) : (i1, i1) -> i1
      %185 = "arith.extui"(%184) : (i1) -> i8
      "cute.memref.store"(%170, %175, %185) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      %186 = "arith.addi"(%173, %87) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      "cf.br"(%186)[^bb1] : (i32) -> ()
    ^bb3:  // pred: ^bb1
      %187 = "cute.get_iter"(%170) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %188 = "cute.append_to_rank"(%140, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %189 = "cute.get_scalars"(%188) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %190 = "cute.make_stride"(%189) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %191 = "cute.make_layout"(%84, %190) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %192 = "cute.append_to_rank"(%191, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %193 = "cute.get_scalars"(%192) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %194 = "cute.make_stride"(%193) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %195 = "cute.make_layout"(%83, %194) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %196 = "cute.get_scalars"(%195) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %197 = "cute.make_stride"(%196) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %198 = "cute.make_layout"(%81, %197) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %199 = "cute.get_scalars"(%198) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %200 = "builtin.unrealized_conversion_cast"(%187) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %201 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %202 = "llvm.icmp"(%201, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%202)[^bb4, ^bb5] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb4:  // pred: ^bb3
      %203 = "builtin.unrealized_conversion_cast"(%138) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %204 = "builtin.unrealized_conversion_cast"(%160) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %205 = "llvm.load"(%203) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%205, %204) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb5] : () -> ()
    ^bb5:  // 2 preds: ^bb3, ^bb4
      %206 = "cute.add_offset"(%187, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %207 = "builtin.unrealized_conversion_cast"(%206) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %208 = "llvm.load"(%207) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %209 = "llvm.icmp"(%208, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%209)[^bb6, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb6:  // pred: ^bb5
      %210 = "cute.add_offset"(%138, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %211 = "cute.add_offset"(%160, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %212 = "builtin.unrealized_conversion_cast"(%210) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %213 = "builtin.unrealized_conversion_cast"(%211) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %214 = "llvm.load"(%212) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%214, %213) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb7] : () -> ()
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %215 = "cute.add_offset"(%187, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %216 = "builtin.unrealized_conversion_cast"(%215) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %217 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %218 = "llvm.icmp"(%217, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%218)[^bb8, ^bb9] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb8:  // pred: ^bb7
      %219 = "cute.add_offset"(%138, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %220 = "cute.add_offset"(%160, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %221 = "builtin.unrealized_conversion_cast"(%219) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %222 = "builtin.unrealized_conversion_cast"(%220) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %223 = "llvm.load"(%221) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%223, %222) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb9] : () -> ()
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %224 = "cute.add_offset"(%187, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %225 = "builtin.unrealized_conversion_cast"(%224) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %226 = "llvm.load"(%225) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %227 = "llvm.icmp"(%226, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%227)[^bb10, ^bb11] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb10:  // pred: ^bb9
      %228 = "cute.add_offset"(%138, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %229 = "cute.add_offset"(%160, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %230 = "builtin.unrealized_conversion_cast"(%228) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %231 = "builtin.unrealized_conversion_cast"(%229) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %232 = "llvm.load"(%230) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%232, %231) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb11] : () -> ()
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %233 = "cute.add_offset"(%187, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %234 = "builtin.unrealized_conversion_cast"(%233) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %235 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %236 = "llvm.icmp"(%235, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%236)[^bb12, ^bb13] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb12:  // pred: ^bb11
      %237 = "cute.make_int_tuple"(%199) : (i64) -> !cute.int_tuple<"?{i64}">
      %238 = "cute.add_offset"(%138, %237) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %239 = "cute.add_offset"(%160, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %240 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %241 = "builtin.unrealized_conversion_cast"(%239) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %242 = "llvm.load"(%240) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%242, %241) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb13] : () -> ()
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %243 = "cute.add_offset"(%187, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %244 = "builtin.unrealized_conversion_cast"(%243) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %245 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %246 = "llvm.icmp"(%245, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%246)[^bb14, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb14:  // pred: ^bb13
      %247 = "arith.addi"(%199, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %248 = "cute.make_int_tuple"(%247) : (i64) -> !cute.int_tuple<"?{i64}">
      %249 = "cute.add_offset"(%138, %248) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %250 = "cute.add_offset"(%160, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %251 = "builtin.unrealized_conversion_cast"(%249) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %252 = "builtin.unrealized_conversion_cast"(%250) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %253 = "llvm.load"(%251) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%253, %252) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb15] : () -> ()
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %254 = "cute.add_offset"(%187, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %255 = "builtin.unrealized_conversion_cast"(%254) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %256 = "llvm.load"(%255) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %257 = "llvm.icmp"(%256, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%257)[^bb16, ^bb17] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb16:  // pred: ^bb15
      %258 = "arith.addi"(%199, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %259 = "cute.make_int_tuple"(%258) : (i64) -> !cute.int_tuple<"?{i64}">
      %260 = "cute.add_offset"(%138, %259) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %261 = "cute.add_offset"(%160, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %262 = "builtin.unrealized_conversion_cast"(%260) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %263 = "builtin.unrealized_conversion_cast"(%261) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %264 = "llvm.load"(%262) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%264, %263) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb17] : () -> ()
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %265 = "cute.add_offset"(%187, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %266 = "builtin.unrealized_conversion_cast"(%265) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %267 = "llvm.load"(%266) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %268 = "llvm.icmp"(%267, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%268)[^bb18, ^bb19] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb18:  // pred: ^bb17
      %269 = "arith.addi"(%199, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %270 = "cute.make_int_tuple"(%269) : (i64) -> !cute.int_tuple<"?{i64}">
      %271 = "cute.add_offset"(%138, %270) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %272 = "cute.add_offset"(%160, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %273 = "builtin.unrealized_conversion_cast"(%271) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %274 = "builtin.unrealized_conversion_cast"(%272) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %275 = "llvm.load"(%273) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%275, %274) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb19] : () -> ()
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %276 = "cute.add_offset"(%187, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %277 = "builtin.unrealized_conversion_cast"(%276) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %278 = "llvm.load"(%277) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %279 = "llvm.icmp"(%278, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%279)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb20:  // pred: ^bb19
      %280 = "arith.muli"(%199, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %281 = "cute.assume"(%280) : (i64) -> !cute.i64<divby 2>
      %282 = "cute.make_int_tuple"(%281) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %283 = "cute.add_offset"(%138, %282) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %284 = "cute.add_offset"(%160, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %285 = "builtin.unrealized_conversion_cast"(%283) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %286 = "builtin.unrealized_conversion_cast"(%284) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %287 = "llvm.load"(%285) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%287, %286) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb21] : () -> ()
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %288 = "cute.add_offset"(%187, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %289 = "builtin.unrealized_conversion_cast"(%288) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %290 = "llvm.load"(%289) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %291 = "llvm.icmp"(%290, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%291)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb22:  // pred: ^bb21
      %292 = "arith.muli"(%199, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %293 = "arith.addi"(%292, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %294 = "cute.make_int_tuple"(%293) : (i64) -> !cute.int_tuple<"?{i64}">
      %295 = "cute.add_offset"(%138, %294) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %296 = "cute.add_offset"(%160, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %297 = "builtin.unrealized_conversion_cast"(%295) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %298 = "builtin.unrealized_conversion_cast"(%296) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %299 = "llvm.load"(%297) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%299, %298) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb23] : () -> ()
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %300 = "cute.add_offset"(%187, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %301 = "builtin.unrealized_conversion_cast"(%300) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %302 = "llvm.load"(%301) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %303 = "llvm.icmp"(%302, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%303)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb24:  // pred: ^bb23
      %304 = "arith.muli"(%199, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %305 = "arith.addi"(%304, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %306 = "cute.assume"(%305) : (i64) -> !cute.i64<divby 2>
      %307 = "cute.make_int_tuple"(%306) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %308 = "cute.add_offset"(%138, %307) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %309 = "cute.add_offset"(%160, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %310 = "builtin.unrealized_conversion_cast"(%308) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %311 = "builtin.unrealized_conversion_cast"(%309) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %312 = "llvm.load"(%310) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%312, %311) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb25] : () -> ()
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %313 = "cute.add_offset"(%187, %67) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %314 = "builtin.unrealized_conversion_cast"(%313) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %315 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %316 = "llvm.icmp"(%315, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%316)[^bb26, ^bb27] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb26:  // pred: ^bb25
      %317 = "arith.muli"(%199, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %318 = "arith.addi"(%317, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %319 = "cute.make_int_tuple"(%318) : (i64) -> !cute.int_tuple<"?{i64}">
      %320 = "cute.add_offset"(%138, %319) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %321 = "cute.add_offset"(%160, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %322 = "builtin.unrealized_conversion_cast"(%320) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %323 = "builtin.unrealized_conversion_cast"(%321) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %324 = "llvm.load"(%322) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%324, %323) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb27] : () -> ()
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %325 = "cute.add_offset"(%187, %66) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %326 = "builtin.unrealized_conversion_cast"(%325) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %327 = "llvm.load"(%326) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %328 = "llvm.icmp"(%327, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%328)[^bb28, ^bb29] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb28:  // pred: ^bb27
      %329 = "arith.muli"(%199, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %330 = "cute.assume"(%329) : (i64) -> !cute.i64<divby 3>
      %331 = "cute.make_int_tuple"(%330) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %332 = "cute.add_offset"(%138, %331) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %333 = "cute.add_offset"(%160, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %334 = "builtin.unrealized_conversion_cast"(%332) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %335 = "builtin.unrealized_conversion_cast"(%333) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %336 = "llvm.load"(%334) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%336, %335) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb29] : () -> ()
    ^bb29:  // 2 preds: ^bb27, ^bb28
      %337 = "cute.add_offset"(%187, %65) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %338 = "builtin.unrealized_conversion_cast"(%337) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %339 = "llvm.load"(%338) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %340 = "llvm.icmp"(%339, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%340)[^bb30, ^bb31] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb30:  // pred: ^bb29
      %341 = "arith.muli"(%199, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %342 = "arith.addi"(%341, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %343 = "cute.make_int_tuple"(%342) : (i64) -> !cute.int_tuple<"?{i64}">
      %344 = "cute.add_offset"(%138, %343) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %345 = "cute.add_offset"(%160, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %346 = "builtin.unrealized_conversion_cast"(%344) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %347 = "builtin.unrealized_conversion_cast"(%345) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %348 = "llvm.load"(%346) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%348, %347) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb31] : () -> ()
    ^bb31:  // 2 preds: ^bb29, ^bb30
      %349 = "cute.add_offset"(%187, %64) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %350 = "builtin.unrealized_conversion_cast"(%349) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %351 = "llvm.load"(%350) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %352 = "llvm.icmp"(%351, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%352)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb32:  // pred: ^bb31
      %353 = "arith.muli"(%199, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %354 = "arith.addi"(%353, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %355 = "cute.make_int_tuple"(%354) : (i64) -> !cute.int_tuple<"?{i64}">
      %356 = "cute.add_offset"(%138, %355) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %357 = "cute.add_offset"(%160, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %358 = "builtin.unrealized_conversion_cast"(%356) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %359 = "builtin.unrealized_conversion_cast"(%357) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %360 = "llvm.load"(%358) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%360, %359) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb33] : () -> ()
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %361 = "cute.add_offset"(%187, %63) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %362 = "builtin.unrealized_conversion_cast"(%361) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %363 = "llvm.load"(%362) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %364 = "llvm.icmp"(%363, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%364)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb34:  // pred: ^bb33
      %365 = "arith.muli"(%199, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %366 = "arith.addi"(%365, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %367 = "cute.assume"(%366) : (i64) -> !cute.i64<divby 3>
      %368 = "cute.make_int_tuple"(%367) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %369 = "cute.add_offset"(%138, %368) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %370 = "cute.add_offset"(%160, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %371 = "builtin.unrealized_conversion_cast"(%369) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %372 = "builtin.unrealized_conversion_cast"(%370) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %373 = "llvm.load"(%371) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%373, %372) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb35] : () -> ()
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %374 = "cute.append_to_rank"(%149, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %375 = "cute.get_scalars"(%374) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %376 = "cute.make_stride"(%375) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %377 = "cute.make_layout"(%84, %376) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %378 = "cute.append_to_rank"(%377, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %379 = "cute.get_scalars"(%378) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %380 = "cute.make_stride"(%379) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %381 = "cute.make_layout"(%83, %380) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %382 = "cute.get_scalars"(%381) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %383 = "cute.make_stride"(%382) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %384 = "cute.make_layout"(%81, %383) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %385 = "cute.get_scalars"(%384) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %386 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %387 = "llvm.icmp"(%386, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%387)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb36:  // pred: ^bb35
      %388 = "builtin.unrealized_conversion_cast"(%147) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %389 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %390 = "llvm.load"(%388) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%390, %389) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb37] : () -> ()
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %391 = "llvm.load"(%207) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %392 = "llvm.icmp"(%391, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%392)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb38:  // pred: ^bb37
      %393 = "cute.add_offset"(%147, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %394 = "cute.add_offset"(%162, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %395 = "builtin.unrealized_conversion_cast"(%393) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %396 = "builtin.unrealized_conversion_cast"(%394) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %397 = "llvm.load"(%395) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%397, %396) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb39] : () -> ()
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %398 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %399 = "llvm.icmp"(%398, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%399)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb40:  // pred: ^bb39
      %400 = "cute.add_offset"(%147, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %401 = "cute.add_offset"(%162, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %402 = "builtin.unrealized_conversion_cast"(%400) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %403 = "builtin.unrealized_conversion_cast"(%401) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %404 = "llvm.load"(%402) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%404, %403) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb41] : () -> ()
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %405 = "llvm.load"(%225) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %406 = "llvm.icmp"(%405, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%406)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb42:  // pred: ^bb41
      %407 = "cute.add_offset"(%147, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %408 = "cute.add_offset"(%162, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %409 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %410 = "builtin.unrealized_conversion_cast"(%408) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %411 = "llvm.load"(%409) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%411, %410) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb43] : () -> ()
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %412 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %413 = "llvm.icmp"(%412, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%413)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb44:  // pred: ^bb43
      %414 = "cute.make_int_tuple"(%385) : (i64) -> !cute.int_tuple<"?{i64}">
      %415 = "cute.add_offset"(%147, %414) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %416 = "cute.add_offset"(%162, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %417 = "builtin.unrealized_conversion_cast"(%415) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %418 = "builtin.unrealized_conversion_cast"(%416) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %419 = "llvm.load"(%417) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%419, %418) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb45] : () -> ()
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %420 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %421 = "llvm.icmp"(%420, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%421)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb46:  // pred: ^bb45
      %422 = "arith.addi"(%385, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %423 = "cute.make_int_tuple"(%422) : (i64) -> !cute.int_tuple<"?{i64}">
      %424 = "cute.add_offset"(%147, %423) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %425 = "cute.add_offset"(%162, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %426 = "builtin.unrealized_conversion_cast"(%424) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %427 = "builtin.unrealized_conversion_cast"(%425) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %428 = "llvm.load"(%426) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%428, %427) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb47] : () -> ()
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %429 = "llvm.load"(%255) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %430 = "llvm.icmp"(%429, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%430)[^bb48, ^bb49] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb48:  // pred: ^bb47
      %431 = "arith.addi"(%385, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %432 = "cute.make_int_tuple"(%431) : (i64) -> !cute.int_tuple<"?{i64}">
      %433 = "cute.add_offset"(%147, %432) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %434 = "cute.add_offset"(%162, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %435 = "builtin.unrealized_conversion_cast"(%433) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %436 = "builtin.unrealized_conversion_cast"(%434) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %437 = "llvm.load"(%435) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%437, %436) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb49] : () -> ()
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %438 = "llvm.load"(%266) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %439 = "llvm.icmp"(%438, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%439)[^bb50, ^bb51] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb50:  // pred: ^bb49
      %440 = "arith.addi"(%385, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %441 = "cute.make_int_tuple"(%440) : (i64) -> !cute.int_tuple<"?{i64}">
      %442 = "cute.add_offset"(%147, %441) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %443 = "cute.add_offset"(%162, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %444 = "builtin.unrealized_conversion_cast"(%442) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %445 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %446 = "llvm.load"(%444) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%446, %445) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb51] : () -> ()
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %447 = "llvm.load"(%277) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %448 = "llvm.icmp"(%447, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%448)[^bb52, ^bb53] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb52:  // pred: ^bb51
      %449 = "arith.muli"(%385, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %450 = "cute.assume"(%449) : (i64) -> !cute.i64<divby 2>
      %451 = "cute.make_int_tuple"(%450) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %452 = "cute.add_offset"(%147, %451) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %453 = "cute.add_offset"(%162, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %454 = "builtin.unrealized_conversion_cast"(%452) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %455 = "builtin.unrealized_conversion_cast"(%453) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %456 = "llvm.load"(%454) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%456, %455) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb53] : () -> ()
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %457 = "llvm.load"(%289) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %458 = "llvm.icmp"(%457, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%458)[^bb54, ^bb55] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb54:  // pred: ^bb53
      %459 = "arith.muli"(%385, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %460 = "arith.addi"(%459, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %461 = "cute.make_int_tuple"(%460) : (i64) -> !cute.int_tuple<"?{i64}">
      %462 = "cute.add_offset"(%147, %461) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %463 = "cute.add_offset"(%162, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %464 = "builtin.unrealized_conversion_cast"(%462) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %465 = "builtin.unrealized_conversion_cast"(%463) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %466 = "llvm.load"(%464) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%466, %465) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb55] : () -> ()
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %467 = "llvm.load"(%301) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %468 = "llvm.icmp"(%467, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%468)[^bb56, ^bb57] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb56:  // pred: ^bb55
      %469 = "arith.muli"(%385, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %470 = "arith.addi"(%469, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %471 = "cute.assume"(%470) : (i64) -> !cute.i64<divby 2>
      %472 = "cute.make_int_tuple"(%471) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %473 = "cute.add_offset"(%147, %472) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %474 = "cute.add_offset"(%162, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %475 = "builtin.unrealized_conversion_cast"(%473) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %476 = "builtin.unrealized_conversion_cast"(%474) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %477 = "llvm.load"(%475) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%477, %476) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb57] : () -> ()
    ^bb57:  // 2 preds: ^bb55, ^bb56
      %478 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %479 = "llvm.icmp"(%478, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%479)[^bb58, ^bb59] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb58:  // pred: ^bb57
      %480 = "arith.muli"(%385, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %481 = "arith.addi"(%480, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %482 = "cute.make_int_tuple"(%481) : (i64) -> !cute.int_tuple<"?{i64}">
      %483 = "cute.add_offset"(%147, %482) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %484 = "cute.add_offset"(%162, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %485 = "builtin.unrealized_conversion_cast"(%483) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %486 = "builtin.unrealized_conversion_cast"(%484) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %487 = "llvm.load"(%485) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%487, %486) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb59] : () -> ()
    ^bb59:  // 2 preds: ^bb57, ^bb58
      %488 = "llvm.load"(%326) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %489 = "llvm.icmp"(%488, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%489)[^bb60, ^bb61] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb60:  // pred: ^bb59
      %490 = "arith.muli"(%385, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %491 = "cute.assume"(%490) : (i64) -> !cute.i64<divby 3>
      %492 = "cute.make_int_tuple"(%491) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %493 = "cute.add_offset"(%147, %492) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %494 = "cute.add_offset"(%162, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %495 = "builtin.unrealized_conversion_cast"(%493) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %496 = "builtin.unrealized_conversion_cast"(%494) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %497 = "llvm.load"(%495) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%497, %496) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb61] : () -> ()
    ^bb61:  // 2 preds: ^bb59, ^bb60
      %498 = "llvm.load"(%338) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %499 = "llvm.icmp"(%498, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%499)[^bb62, ^bb63] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb62:  // pred: ^bb61
      %500 = "arith.muli"(%385, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %501 = "arith.addi"(%500, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %502 = "cute.make_int_tuple"(%501) : (i64) -> !cute.int_tuple<"?{i64}">
      %503 = "cute.add_offset"(%147, %502) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %504 = "cute.add_offset"(%162, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %505 = "builtin.unrealized_conversion_cast"(%503) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %506 = "builtin.unrealized_conversion_cast"(%504) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %507 = "llvm.load"(%505) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%507, %506) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb63] : () -> ()
    ^bb63:  // 2 preds: ^bb61, ^bb62
      %508 = "llvm.load"(%350) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %509 = "llvm.icmp"(%508, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%509)[^bb64, ^bb65] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb64:  // pred: ^bb63
      %510 = "arith.muli"(%385, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %511 = "arith.addi"(%510, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %512 = "cute.make_int_tuple"(%511) : (i64) -> !cute.int_tuple<"?{i64}">
      %513 = "cute.add_offset"(%147, %512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %514 = "cute.add_offset"(%162, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %515 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %516 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %517 = "llvm.load"(%515) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%517, %516) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb65] : () -> ()
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %518 = "llvm.load"(%362) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %519 = "llvm.icmp"(%518, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%519)[^bb66, ^bb67] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb66:  // pred: ^bb65
      %520 = "arith.muli"(%385, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %521 = "arith.addi"(%520, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %522 = "cute.assume"(%521) : (i64) -> !cute.i64<divby 3>
      %523 = "cute.make_int_tuple"(%522) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %524 = "cute.add_offset"(%147, %523) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %525 = "cute.add_offset"(%162, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %526 = "builtin.unrealized_conversion_cast"(%524) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %527 = "builtin.unrealized_conversion_cast"(%525) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %528 = "llvm.load"(%526) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%528, %527) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      "cf.br"()[^bb67] : () -> ()
    ^bb67:  // 2 preds: ^bb65, ^bb66
      %529 = "cute.memref.load_vec"(%159) : (!memref_rmem_f32_) -> vector<16xf32>
      %530 = "cute.memref.load_vec"(%161) : (!memref_rmem_f32_) -> vector<16xf32>
      %531 = "arith.addf"(%529, %530) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%531, %163) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %532 = "cute.append_to_rank"(%158, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %533 = "cute.get_scalars"(%532) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %534 = "cute.make_stride"(%533) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %535 = "cute.make_layout"(%84, %534) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %536 = "cute.append_to_rank"(%535, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %537 = "cute.get_scalars"(%536) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %538 = "cute.make_stride"(%537) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %539 = "cute.make_layout"(%83, %538) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %540 = "cute.get_scalars"(%539) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %541 = "cute.make_stride"(%540) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %542 = "cute.make_layout"(%81, %541) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %543 = "cute.get_scalars"(%542) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %544 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %545 = "llvm.icmp"(%544, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%545)[^bb68, ^bb69] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb68:  // pred: ^bb67
      %546 = "builtin.unrealized_conversion_cast"(%164) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %547 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %548 = "llvm.load"(%546) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%548, %547) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb69] : () -> ()
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %549 = "llvm.load"(%207) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %550 = "llvm.icmp"(%549, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%550)[^bb70, ^bb71] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb70:  // pred: ^bb69
      %551 = "cute.add_offset"(%164, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %552 = "cute.add_offset"(%156, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %553 = "builtin.unrealized_conversion_cast"(%551) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %554 = "builtin.unrealized_conversion_cast"(%552) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %555 = "llvm.load"(%553) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%555, %554) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb71] : () -> ()
    ^bb71:  // 2 preds: ^bb69, ^bb70
      %556 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %557 = "llvm.icmp"(%556, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%557)[^bb72, ^bb73] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb72:  // pred: ^bb71
      %558 = "cute.add_offset"(%164, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %559 = "cute.add_offset"(%156, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %560 = "builtin.unrealized_conversion_cast"(%558) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %561 = "builtin.unrealized_conversion_cast"(%559) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %562 = "llvm.load"(%560) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%562, %561) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb73] : () -> ()
    ^bb73:  // 2 preds: ^bb71, ^bb72
      %563 = "llvm.load"(%225) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %564 = "llvm.icmp"(%563, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%564)[^bb74, ^bb75] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb74:  // pred: ^bb73
      %565 = "cute.add_offset"(%164, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %566 = "cute.add_offset"(%156, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %567 = "builtin.unrealized_conversion_cast"(%565) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %568 = "builtin.unrealized_conversion_cast"(%566) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %569 = "llvm.load"(%567) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%569, %568) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb75] : () -> ()
    ^bb75:  // 2 preds: ^bb73, ^bb74
      %570 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %571 = "llvm.icmp"(%570, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%571)[^bb76, ^bb77] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb76:  // pred: ^bb75
      %572 = "cute.add_offset"(%164, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %573 = "cute.make_int_tuple"(%543) : (i64) -> !cute.int_tuple<"?{i64}">
      %574 = "cute.add_offset"(%156, %573) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %575 = "builtin.unrealized_conversion_cast"(%572) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %576 = "builtin.unrealized_conversion_cast"(%574) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %577 = "llvm.load"(%575) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%577, %576) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb77] : () -> ()
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %578 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %579 = "llvm.icmp"(%578, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%579)[^bb78, ^bb79] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb78:  // pred: ^bb77
      %580 = "cute.add_offset"(%164, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %581 = "arith.addi"(%543, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %582 = "cute.make_int_tuple"(%581) : (i64) -> !cute.int_tuple<"?{i64}">
      %583 = "cute.add_offset"(%156, %582) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %584 = "builtin.unrealized_conversion_cast"(%580) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %585 = "builtin.unrealized_conversion_cast"(%583) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %586 = "llvm.load"(%584) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%586, %585) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb79] : () -> ()
    ^bb79:  // 2 preds: ^bb77, ^bb78
      %587 = "llvm.load"(%255) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %588 = "llvm.icmp"(%587, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%588)[^bb80, ^bb81] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb80:  // pred: ^bb79
      %589 = "cute.add_offset"(%164, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %590 = "arith.addi"(%543, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %591 = "cute.make_int_tuple"(%590) : (i64) -> !cute.int_tuple<"?{i64}">
      %592 = "cute.add_offset"(%156, %591) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %593 = "builtin.unrealized_conversion_cast"(%589) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %594 = "builtin.unrealized_conversion_cast"(%592) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %595 = "llvm.load"(%593) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%595, %594) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb81] : () -> ()
    ^bb81:  // 2 preds: ^bb79, ^bb80
      %596 = "llvm.load"(%266) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %597 = "llvm.icmp"(%596, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%597)[^bb82, ^bb83] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb82:  // pred: ^bb81
      %598 = "cute.add_offset"(%164, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %599 = "arith.addi"(%543, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %600 = "cute.make_int_tuple"(%599) : (i64) -> !cute.int_tuple<"?{i64}">
      %601 = "cute.add_offset"(%156, %600) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %602 = "builtin.unrealized_conversion_cast"(%598) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %603 = "builtin.unrealized_conversion_cast"(%601) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %604 = "llvm.load"(%602) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%604, %603) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb83] : () -> ()
    ^bb83:  // 2 preds: ^bb81, ^bb82
      %605 = "llvm.load"(%277) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %606 = "llvm.icmp"(%605, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%606)[^bb84, ^bb85] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb84:  // pred: ^bb83
      %607 = "cute.add_offset"(%164, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %608 = "arith.muli"(%543, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %609 = "cute.assume"(%608) : (i64) -> !cute.i64<divby 2>
      %610 = "cute.make_int_tuple"(%609) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %611 = "cute.add_offset"(%156, %610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %612 = "builtin.unrealized_conversion_cast"(%607) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %613 = "builtin.unrealized_conversion_cast"(%611) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %614 = "llvm.load"(%612) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%614, %613) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb85] : () -> ()
    ^bb85:  // 2 preds: ^bb83, ^bb84
      %615 = "llvm.load"(%289) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %616 = "llvm.icmp"(%615, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%616)[^bb86, ^bb87] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb86:  // pred: ^bb85
      %617 = "cute.add_offset"(%164, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %618 = "arith.muli"(%543, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %619 = "arith.addi"(%618, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %620 = "cute.make_int_tuple"(%619) : (i64) -> !cute.int_tuple<"?{i64}">
      %621 = "cute.add_offset"(%156, %620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %622 = "builtin.unrealized_conversion_cast"(%617) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %623 = "builtin.unrealized_conversion_cast"(%621) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %624 = "llvm.load"(%622) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%624, %623) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb87] : () -> ()
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %625 = "llvm.load"(%301) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %626 = "llvm.icmp"(%625, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%626)[^bb88, ^bb89] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb88:  // pred: ^bb87
      %627 = "cute.add_offset"(%164, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %628 = "arith.muli"(%543, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %629 = "arith.addi"(%628, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %630 = "cute.assume"(%629) : (i64) -> !cute.i64<divby 2>
      %631 = "cute.make_int_tuple"(%630) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %632 = "cute.add_offset"(%156, %631) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %633 = "builtin.unrealized_conversion_cast"(%627) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %634 = "builtin.unrealized_conversion_cast"(%632) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %635 = "llvm.load"(%633) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%635, %634) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb89] : () -> ()
    ^bb89:  // 2 preds: ^bb87, ^bb88
      %636 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %637 = "llvm.icmp"(%636, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%637)[^bb90, ^bb91] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb90:  // pred: ^bb89
      %638 = "cute.add_offset"(%164, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %639 = "arith.muli"(%543, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %640 = "arith.addi"(%639, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %641 = "cute.make_int_tuple"(%640) : (i64) -> !cute.int_tuple<"?{i64}">
      %642 = "cute.add_offset"(%156, %641) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %643 = "builtin.unrealized_conversion_cast"(%638) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %644 = "builtin.unrealized_conversion_cast"(%642) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %645 = "llvm.load"(%643) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%645, %644) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb91] : () -> ()
    ^bb91:  // 2 preds: ^bb89, ^bb90
      %646 = "llvm.load"(%326) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %647 = "llvm.icmp"(%646, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%647)[^bb92, ^bb93] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb92:  // pred: ^bb91
      %648 = "cute.add_offset"(%164, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %649 = "arith.muli"(%543, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %650 = "cute.assume"(%649) : (i64) -> !cute.i64<divby 3>
      %651 = "cute.make_int_tuple"(%650) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %652 = "cute.add_offset"(%156, %651) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %653 = "builtin.unrealized_conversion_cast"(%648) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
      %654 = "builtin.unrealized_conversion_cast"(%652) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %655 = "llvm.load"(%653) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%655, %654) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb93] : () -> ()
    ^bb93:  // 2 preds: ^bb91, ^bb92
      %656 = "llvm.load"(%338) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %657 = "llvm.icmp"(%656, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%657)[^bb94, ^bb95] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb94:  // pred: ^bb93
      %658 = "cute.add_offset"(%164, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %659 = "arith.muli"(%543, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %660 = "arith.addi"(%659, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %661 = "cute.make_int_tuple"(%660) : (i64) -> !cute.int_tuple<"?{i64}">
      %662 = "cute.add_offset"(%156, %661) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %663 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %664 = "builtin.unrealized_conversion_cast"(%662) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %665 = "llvm.load"(%663) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%665, %664) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb95] : () -> ()
    ^bb95:  // 2 preds: ^bb93, ^bb94
      %666 = "llvm.load"(%350) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %667 = "llvm.icmp"(%666, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%667)[^bb96, ^bb97] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb96:  // pred: ^bb95
      %668 = "cute.add_offset"(%164, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %669 = "arith.muli"(%543, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %670 = "arith.addi"(%669, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %671 = "cute.make_int_tuple"(%670) : (i64) -> !cute.int_tuple<"?{i64}">
      %672 = "cute.add_offset"(%156, %671) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %673 = "builtin.unrealized_conversion_cast"(%668) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %674 = "builtin.unrealized_conversion_cast"(%672) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %675 = "llvm.load"(%673) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%675, %674) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb97] : () -> ()
    ^bb97:  // 2 preds: ^bb95, ^bb96
      %676 = "llvm.load"(%362) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %677 = "llvm.icmp"(%676, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "cf.cond_br"(%677)[^bb98, ^bb99] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb98:  // pred: ^bb97
      %678 = "cute.add_offset"(%164, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %679 = "arith.muli"(%543, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %680 = "arith.addi"(%679, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %681 = "cute.assume"(%680) : (i64) -> !cute.i64<divby 3>
      %682 = "cute.make_int_tuple"(%681) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %683 = "cute.add_offset"(%156, %682) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %684 = "builtin.unrealized_conversion_cast"(%678) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %685 = "builtin.unrealized_conversion_cast"(%683) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %686 = "llvm.load"(%684) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
      "llvm.store"(%686, %685) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb99] : () -> ()
    ^bb99:  // 2 preds: ^bb97, ^bb98
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_f32_1, !memref_gmem_f32_1) -> i32, sym_name = "cutlass_elementwise_add_tensor00644_03711_00110_04851_03515_08385_15093_00759_05930_07060_10713_18194_00944_06791_03214_06920_01900_16902_02636_10262_09792_12286_01389_04307_02417_"}> ({
  ^bb0(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %2 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %3 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %4 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
    %5 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %6 = "arith.constant"() <{value = 16 : i64}> : () -> i64
    %7 = "arith.constant"() <{value = 16 : i32}> : () -> i32
    %8 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %9 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %10:3 = "cute.get_scalars"(%9) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %11 = "arith.ceildivsi"(%10#0, %7) : (i32, i32) -> i32
    %12 = "arith.muli"(%10#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %13 = "arith.ceildivsi"(%10#1, %5) : (i32, i32) -> i32
    %14 = "cute.make_shape"(%11, %13) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %15 = "cute.assume"(%12) : (i64) -> !cute.i64<divby 16>
    %16 = "cute.make_stride"(%10#2, %15) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %17 = "cute.make_layout"(%14, %16) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %18 = "cute.make_view"(%8, %17) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %19 = "cute.get_iter"(%arg1) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %20 = "cute.get_layout"(%arg1) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %21:3 = "cute.get_scalars"(%20) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %22 = "arith.ceildivsi"(%21#0, %7) : (i32, i32) -> i32
    %23 = "arith.muli"(%21#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %24 = "arith.ceildivsi"(%21#1, %5) : (i32, i32) -> i32
    %25 = "cute.make_shape"(%22, %24) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %26 = "cute.assume"(%23) : (i64) -> !cute.i64<divby 16>
    %27 = "cute.make_stride"(%21#2, %26) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %28 = "cute.make_layout"(%25, %27) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %29 = "cute.make_view"(%19, %28) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %30 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %31 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %32:3 = "cute.get_scalars"(%31) <{only_dynamic}> : (!cute.layout<"(?,?):(?{i64},1)">) -> (i32, i32, i64)
    %33 = "arith.ceildivsi"(%32#0, %7) : (i32, i32) -> i32
    %34 = "arith.muli"(%32#2, %6) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
    %35 = "arith.ceildivsi"(%32#1, %5) : (i32, i32) -> i32
    %36 = "cute.make_shape"(%33, %35) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %37 = "cute.assume"(%34) : (i64) -> !cute.i64<divby 16>
    %38 = "cute.make_stride"(%32#2, %37) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %39 = "cute.make_layout"(%36, %38) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((?{i64},1),(?{i64 div=16},128))">) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %40 = "cute.make_view"(%30, %39) : (!cute.ptr<f32, gmem>, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !memref_gmem_f32_
    %41 = "cute.get_shape"(%31) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %42:2 = "cute.get_leaves"(%41) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %43 = "cute.to_int_tuple"(%42#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %44 = "cute.to_int_tuple"(%42#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %45 = "cute.make_shape"(%43, %44) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %46 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
    %47 = "cute.make_layout"(%45, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %48:2 = "cute.get_scalars"(%47) <{only_dynamic}> : (!cute.layout<"(?,?):(1@0,1@1)">) -> (i32, i32)
    %49 = "arith.ceildivsi"(%48#0, %7) : (i32, i32) -> i32
    %50 = "arith.ceildivsi"(%48#1, %5) : (i32, i32) -> i32
    %51 = "cute.make_shape"(%49, %50) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %52 = "cute.make_layout"(%51, %3) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %53 = "cute.make_view"(%46, %52) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %54 = "cute.get_scalars"(%43) : (!cute.int_tuple<"?">) -> i32
    %55 = "cute.get_scalars"(%44) : (!cute.int_tuple<"?">) -> i32
    %56 = "cute.size"(%39) <{mode = array<i32: 1>}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %57 = "cute.get_leaves"(%56) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %58 = "cute.get_scalars"(%57) : (!cute.int_tuple<"?">) -> i32
    %59 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %60 = "cuda.launch_cfg.create"(%5, %0, %0, %1, %58, %0, %0, %59) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%60, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%60, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %61 = "cuda.launch_ex"(%60, %18, %29, %40, %53, %54, %55) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %62 = "cuda.cast"(%61) : (!cuda.result) -> i32
    "cuda.return_if_error"(%62) : (i32) -> ()
    "func.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
