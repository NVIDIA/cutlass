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
      "scf.for"(%89, %88, %87) ({
      ^bb0(%arg9: i32):
        %671 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        %672 = "cute.crd2idx"(%671, %86) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %673 = "cute.add_offset"(%169, %672) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %674 = "cute.deref_arith_tuple_iter"(%673) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %675:2 = "cute.get_leaves"(%674) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %676 = "cute.make_coord"(%675#0, %675#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %677 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %678:2 = "cute.get_scalars"(%676) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %679:2 = "cute.get_scalars"(%677) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %680 = "arith.cmpi"(%678#0, %679#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %681 = "arith.cmpi"(%678#1, %679#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %682 = "arith.andi"(%680, %681) : (i1, i1) -> i1
        %683 = "arith.extui"(%682) : (i1) -> i8
        "cute.memref.store"(%170, %671, %683) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %171 = "cute.get_iter"(%170) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %172 = "cute.append_to_rank"(%140, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %173 = "cute.get_scalars"(%172) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %174 = "cute.make_stride"(%173) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %175 = "cute.make_layout"(%84, %174) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %176 = "cute.append_to_rank"(%175, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %177 = "cute.get_scalars"(%176) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %178 = "cute.make_stride"(%177) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %179 = "cute.make_layout"(%83, %178) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %180 = "cute.get_scalars"(%179) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %181 = "cute.make_stride"(%180) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %182 = "cute.make_layout"(%81, %181) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %183 = "cute.get_scalars"(%182) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %184 = "builtin.unrealized_conversion_cast"(%171) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %185 = "llvm.load"(%184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %186 = "llvm.icmp"(%185, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%186) ({
        %668 = "builtin.unrealized_conversion_cast"(%138) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %669 = "builtin.unrealized_conversion_cast"(%160) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %670 = "llvm.load"(%668) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%670, %669) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %187 = "cute.add_offset"(%171, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %188 = "builtin.unrealized_conversion_cast"(%187) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %189 = "llvm.load"(%188) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %190 = "llvm.icmp"(%189, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%190) ({
        %663 = "cute.add_offset"(%138, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %664 = "cute.add_offset"(%160, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %665 = "builtin.unrealized_conversion_cast"(%663) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %666 = "builtin.unrealized_conversion_cast"(%664) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %667 = "llvm.load"(%665) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%667, %666) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %191 = "cute.add_offset"(%171, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %192 = "builtin.unrealized_conversion_cast"(%191) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %193 = "llvm.load"(%192) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %194 = "llvm.icmp"(%193, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%194) ({
        %658 = "cute.add_offset"(%138, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %659 = "cute.add_offset"(%160, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %660 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %661 = "builtin.unrealized_conversion_cast"(%659) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %662 = "llvm.load"(%660) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%662, %661) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %195 = "cute.add_offset"(%171, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %196 = "builtin.unrealized_conversion_cast"(%195) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %197 = "llvm.load"(%196) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %198 = "llvm.icmp"(%197, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%198) ({
        %653 = "cute.add_offset"(%138, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %654 = "cute.add_offset"(%160, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %655 = "builtin.unrealized_conversion_cast"(%653) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %656 = "builtin.unrealized_conversion_cast"(%654) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %657 = "llvm.load"(%655) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%657, %656) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %199 = "cute.add_offset"(%171, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %200 = "builtin.unrealized_conversion_cast"(%199) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %201 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %202 = "llvm.icmp"(%201, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%202) ({
        %647 = "cute.make_int_tuple"(%183) : (i64) -> !cute.int_tuple<"?{i64}">
        %648 = "cute.add_offset"(%138, %647) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %649 = "cute.add_offset"(%160, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %650 = "builtin.unrealized_conversion_cast"(%648) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %651 = "builtin.unrealized_conversion_cast"(%649) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %652 = "llvm.load"(%650) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%652, %651) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %203 = "cute.add_offset"(%171, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %204 = "builtin.unrealized_conversion_cast"(%203) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %205 = "llvm.load"(%204) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %206 = "llvm.icmp"(%205, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%206) ({
        %640 = "arith.addi"(%183, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %641 = "cute.make_int_tuple"(%640) : (i64) -> !cute.int_tuple<"?{i64}">
        %642 = "cute.add_offset"(%138, %641) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %643 = "cute.add_offset"(%160, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %644 = "builtin.unrealized_conversion_cast"(%642) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %645 = "builtin.unrealized_conversion_cast"(%643) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %646 = "llvm.load"(%644) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%646, %645) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %207 = "cute.add_offset"(%171, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %208 = "builtin.unrealized_conversion_cast"(%207) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %209 = "llvm.load"(%208) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %210 = "llvm.icmp"(%209, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%210) ({
        %633 = "arith.addi"(%183, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %634 = "cute.make_int_tuple"(%633) : (i64) -> !cute.int_tuple<"?{i64}">
        %635 = "cute.add_offset"(%138, %634) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %636 = "cute.add_offset"(%160, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %637 = "builtin.unrealized_conversion_cast"(%635) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %638 = "builtin.unrealized_conversion_cast"(%636) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %639 = "llvm.load"(%637) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%639, %638) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %211 = "cute.add_offset"(%171, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %212 = "builtin.unrealized_conversion_cast"(%211) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %213 = "llvm.load"(%212) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %214 = "llvm.icmp"(%213, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%214) ({
        %626 = "arith.addi"(%183, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %627 = "cute.make_int_tuple"(%626) : (i64) -> !cute.int_tuple<"?{i64}">
        %628 = "cute.add_offset"(%138, %627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %629 = "cute.add_offset"(%160, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %630 = "builtin.unrealized_conversion_cast"(%628) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %631 = "builtin.unrealized_conversion_cast"(%629) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %632 = "llvm.load"(%630) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%632, %631) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %215 = "cute.add_offset"(%171, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %216 = "builtin.unrealized_conversion_cast"(%215) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %217 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %218 = "llvm.icmp"(%217, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%218) ({
        %618 = "arith.muli"(%183, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %619 = "cute.assume"(%618) : (i64) -> !cute.i64<divby 2>
        %620 = "cute.make_int_tuple"(%619) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %621 = "cute.add_offset"(%138, %620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %622 = "cute.add_offset"(%160, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %623 = "builtin.unrealized_conversion_cast"(%621) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %624 = "builtin.unrealized_conversion_cast"(%622) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %625 = "llvm.load"(%623) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%625, %624) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %219 = "cute.add_offset"(%171, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %220 = "builtin.unrealized_conversion_cast"(%219) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %221 = "llvm.load"(%220) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %222 = "llvm.icmp"(%221, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%222) ({
        %610 = "arith.muli"(%183, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %611 = "arith.addi"(%610, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %612 = "cute.make_int_tuple"(%611) : (i64) -> !cute.int_tuple<"?{i64}">
        %613 = "cute.add_offset"(%138, %612) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %614 = "cute.add_offset"(%160, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %615 = "builtin.unrealized_conversion_cast"(%613) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %616 = "builtin.unrealized_conversion_cast"(%614) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %617 = "llvm.load"(%615) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%617, %616) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %223 = "cute.add_offset"(%171, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %224 = "builtin.unrealized_conversion_cast"(%223) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %225 = "llvm.load"(%224) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %226 = "llvm.icmp"(%225, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%226) ({
        %601 = "arith.muli"(%183, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %602 = "arith.addi"(%601, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %603 = "cute.assume"(%602) : (i64) -> !cute.i64<divby 2>
        %604 = "cute.make_int_tuple"(%603) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %605 = "cute.add_offset"(%138, %604) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %606 = "cute.add_offset"(%160, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %607 = "builtin.unrealized_conversion_cast"(%605) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %608 = "builtin.unrealized_conversion_cast"(%606) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %609 = "llvm.load"(%607) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%609, %608) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %227 = "cute.add_offset"(%171, %67) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %228 = "builtin.unrealized_conversion_cast"(%227) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %229 = "llvm.load"(%228) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %230 = "llvm.icmp"(%229, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%230) ({
        %593 = "arith.muli"(%183, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %594 = "arith.addi"(%593, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %595 = "cute.make_int_tuple"(%594) : (i64) -> !cute.int_tuple<"?{i64}">
        %596 = "cute.add_offset"(%138, %595) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %597 = "cute.add_offset"(%160, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %598 = "builtin.unrealized_conversion_cast"(%596) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %599 = "builtin.unrealized_conversion_cast"(%597) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %600 = "llvm.load"(%598) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%600, %599) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %231 = "cute.add_offset"(%171, %66) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %232 = "builtin.unrealized_conversion_cast"(%231) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %233 = "llvm.load"(%232) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %234 = "llvm.icmp"(%233, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%234) ({
        %585 = "arith.muli"(%183, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %586 = "cute.assume"(%585) : (i64) -> !cute.i64<divby 3>
        %587 = "cute.make_int_tuple"(%586) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %588 = "cute.add_offset"(%138, %587) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %589 = "cute.add_offset"(%160, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %590 = "builtin.unrealized_conversion_cast"(%588) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %591 = "builtin.unrealized_conversion_cast"(%589) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %592 = "llvm.load"(%590) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%592, %591) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %235 = "cute.add_offset"(%171, %65) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %236 = "builtin.unrealized_conversion_cast"(%235) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %237 = "llvm.load"(%236) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %238 = "llvm.icmp"(%237, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%238) ({
        %577 = "arith.muli"(%183, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %578 = "arith.addi"(%577, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %579 = "cute.make_int_tuple"(%578) : (i64) -> !cute.int_tuple<"?{i64}">
        %580 = "cute.add_offset"(%138, %579) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %581 = "cute.add_offset"(%160, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %582 = "builtin.unrealized_conversion_cast"(%580) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %583 = "builtin.unrealized_conversion_cast"(%581) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %584 = "llvm.load"(%582) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%584, %583) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %239 = "cute.add_offset"(%171, %64) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %240 = "builtin.unrealized_conversion_cast"(%239) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %241 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %242 = "llvm.icmp"(%241, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%242) ({
        %569 = "arith.muli"(%183, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %570 = "arith.addi"(%569, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %571 = "cute.make_int_tuple"(%570) : (i64) -> !cute.int_tuple<"?{i64}">
        %572 = "cute.add_offset"(%138, %571) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %573 = "cute.add_offset"(%160, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %574 = "builtin.unrealized_conversion_cast"(%572) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %575 = "builtin.unrealized_conversion_cast"(%573) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %576 = "llvm.load"(%574) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%576, %575) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %243 = "cute.add_offset"(%171, %63) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %244 = "builtin.unrealized_conversion_cast"(%243) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %245 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %246 = "llvm.icmp"(%245, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%246) ({
        %560 = "arith.muli"(%183, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %561 = "arith.addi"(%560, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %562 = "cute.assume"(%561) : (i64) -> !cute.i64<divby 3>
        %563 = "cute.make_int_tuple"(%562) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %564 = "cute.add_offset"(%138, %563) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %565 = "cute.add_offset"(%160, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %566 = "builtin.unrealized_conversion_cast"(%564) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %567 = "builtin.unrealized_conversion_cast"(%565) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %568 = "llvm.load"(%566) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%568, %567) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %247 = "cute.append_to_rank"(%149, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %248 = "cute.get_scalars"(%247) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %249 = "cute.make_stride"(%248) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %250 = "cute.make_layout"(%84, %249) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %251 = "cute.append_to_rank"(%250, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %252 = "cute.get_scalars"(%251) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %253 = "cute.make_stride"(%252) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %254 = "cute.make_layout"(%83, %253) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %255 = "cute.get_scalars"(%254) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %256 = "cute.make_stride"(%255) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %257 = "cute.make_layout"(%81, %256) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %258 = "cute.get_scalars"(%257) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %259 = "llvm.load"(%184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %260 = "llvm.icmp"(%259, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%260) ({
        %557 = "builtin.unrealized_conversion_cast"(%147) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %558 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %559 = "llvm.load"(%557) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%559, %558) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %261 = "llvm.load"(%188) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %262 = "llvm.icmp"(%261, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%262) ({
        %552 = "cute.add_offset"(%147, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %553 = "cute.add_offset"(%162, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %554 = "builtin.unrealized_conversion_cast"(%552) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %555 = "builtin.unrealized_conversion_cast"(%553) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %556 = "llvm.load"(%554) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%556, %555) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %263 = "llvm.load"(%192) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %264 = "llvm.icmp"(%263, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%264) ({
        %547 = "cute.add_offset"(%147, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %548 = "cute.add_offset"(%162, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %549 = "builtin.unrealized_conversion_cast"(%547) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %550 = "builtin.unrealized_conversion_cast"(%548) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %551 = "llvm.load"(%549) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%551, %550) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %265 = "llvm.load"(%196) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %266 = "llvm.icmp"(%265, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%266) ({
        %542 = "cute.add_offset"(%147, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %543 = "cute.add_offset"(%162, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %544 = "builtin.unrealized_conversion_cast"(%542) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %545 = "builtin.unrealized_conversion_cast"(%543) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %546 = "llvm.load"(%544) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%546, %545) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %267 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %268 = "llvm.icmp"(%267, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%268) ({
        %536 = "cute.make_int_tuple"(%258) : (i64) -> !cute.int_tuple<"?{i64}">
        %537 = "cute.add_offset"(%147, %536) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %538 = "cute.add_offset"(%162, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %539 = "builtin.unrealized_conversion_cast"(%537) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %540 = "builtin.unrealized_conversion_cast"(%538) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %541 = "llvm.load"(%539) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%541, %540) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %269 = "llvm.load"(%204) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %270 = "llvm.icmp"(%269, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%270) ({
        %529 = "arith.addi"(%258, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %530 = "cute.make_int_tuple"(%529) : (i64) -> !cute.int_tuple<"?{i64}">
        %531 = "cute.add_offset"(%147, %530) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %532 = "cute.add_offset"(%162, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %533 = "builtin.unrealized_conversion_cast"(%531) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %534 = "builtin.unrealized_conversion_cast"(%532) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %535 = "llvm.load"(%533) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%535, %534) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %271 = "llvm.load"(%208) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %272 = "llvm.icmp"(%271, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%272) ({
        %522 = "arith.addi"(%258, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %523 = "cute.make_int_tuple"(%522) : (i64) -> !cute.int_tuple<"?{i64}">
        %524 = "cute.add_offset"(%147, %523) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %525 = "cute.add_offset"(%162, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %526 = "builtin.unrealized_conversion_cast"(%524) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %527 = "builtin.unrealized_conversion_cast"(%525) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %528 = "llvm.load"(%526) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%528, %527) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %273 = "llvm.load"(%212) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %274 = "llvm.icmp"(%273, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%274) ({
        %515 = "arith.addi"(%258, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %516 = "cute.make_int_tuple"(%515) : (i64) -> !cute.int_tuple<"?{i64}">
        %517 = "cute.add_offset"(%147, %516) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %518 = "cute.add_offset"(%162, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %519 = "builtin.unrealized_conversion_cast"(%517) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %520 = "builtin.unrealized_conversion_cast"(%518) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %521 = "llvm.load"(%519) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%521, %520) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %275 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %276 = "llvm.icmp"(%275, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%276) ({
        %507 = "arith.muli"(%258, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %508 = "cute.assume"(%507) : (i64) -> !cute.i64<divby 2>
        %509 = "cute.make_int_tuple"(%508) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %510 = "cute.add_offset"(%147, %509) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %511 = "cute.add_offset"(%162, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %512 = "builtin.unrealized_conversion_cast"(%510) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %513 = "builtin.unrealized_conversion_cast"(%511) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %514 = "llvm.load"(%512) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%514, %513) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %277 = "llvm.load"(%220) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %278 = "llvm.icmp"(%277, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%278) ({
        %499 = "arith.muli"(%258, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %500 = "arith.addi"(%499, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %501 = "cute.make_int_tuple"(%500) : (i64) -> !cute.int_tuple<"?{i64}">
        %502 = "cute.add_offset"(%147, %501) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %503 = "cute.add_offset"(%162, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %504 = "builtin.unrealized_conversion_cast"(%502) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %505 = "builtin.unrealized_conversion_cast"(%503) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %506 = "llvm.load"(%504) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%506, %505) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %279 = "llvm.load"(%224) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %280 = "llvm.icmp"(%279, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%280) ({
        %490 = "arith.muli"(%258, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %491 = "arith.addi"(%490, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %492 = "cute.assume"(%491) : (i64) -> !cute.i64<divby 2>
        %493 = "cute.make_int_tuple"(%492) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %494 = "cute.add_offset"(%147, %493) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %495 = "cute.add_offset"(%162, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %496 = "builtin.unrealized_conversion_cast"(%494) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %497 = "builtin.unrealized_conversion_cast"(%495) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %498 = "llvm.load"(%496) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%498, %497) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %281 = "llvm.load"(%228) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %282 = "llvm.icmp"(%281, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%282) ({
        %482 = "arith.muli"(%258, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %483 = "arith.addi"(%482, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %484 = "cute.make_int_tuple"(%483) : (i64) -> !cute.int_tuple<"?{i64}">
        %485 = "cute.add_offset"(%147, %484) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %486 = "cute.add_offset"(%162, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %487 = "builtin.unrealized_conversion_cast"(%485) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %488 = "builtin.unrealized_conversion_cast"(%486) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %489 = "llvm.load"(%487) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%489, %488) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %283 = "llvm.load"(%232) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %284 = "llvm.icmp"(%283, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%284) ({
        %474 = "arith.muli"(%258, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %475 = "cute.assume"(%474) : (i64) -> !cute.i64<divby 3>
        %476 = "cute.make_int_tuple"(%475) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %477 = "cute.add_offset"(%147, %476) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %478 = "cute.add_offset"(%162, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %479 = "builtin.unrealized_conversion_cast"(%477) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %480 = "builtin.unrealized_conversion_cast"(%478) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %481 = "llvm.load"(%479) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%481, %480) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %285 = "llvm.load"(%236) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %286 = "llvm.icmp"(%285, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%286) ({
        %466 = "arith.muli"(%258, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %467 = "arith.addi"(%466, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %468 = "cute.make_int_tuple"(%467) : (i64) -> !cute.int_tuple<"?{i64}">
        %469 = "cute.add_offset"(%147, %468) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %470 = "cute.add_offset"(%162, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %471 = "builtin.unrealized_conversion_cast"(%469) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %472 = "builtin.unrealized_conversion_cast"(%470) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %473 = "llvm.load"(%471) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%473, %472) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %287 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %288 = "llvm.icmp"(%287, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%288) ({
        %458 = "arith.muli"(%258, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %459 = "arith.addi"(%458, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %460 = "cute.make_int_tuple"(%459) : (i64) -> !cute.int_tuple<"?{i64}">
        %461 = "cute.add_offset"(%147, %460) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %462 = "cute.add_offset"(%162, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %463 = "builtin.unrealized_conversion_cast"(%461) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %464 = "builtin.unrealized_conversion_cast"(%462) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %465 = "llvm.load"(%463) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%465, %464) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %289 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %290 = "llvm.icmp"(%289, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%290) ({
        %449 = "arith.muli"(%258, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %450 = "arith.addi"(%449, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %451 = "cute.assume"(%450) : (i64) -> !cute.i64<divby 3>
        %452 = "cute.make_int_tuple"(%451) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %453 = "cute.add_offset"(%147, %452) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %454 = "cute.add_offset"(%162, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %455 = "builtin.unrealized_conversion_cast"(%453) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %456 = "builtin.unrealized_conversion_cast"(%454) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %457 = "llvm.load"(%455) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%457, %456) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %291 = "cute.memref.load_vec"(%159) : (!memref_rmem_f32_) -> vector<16xf32>
      %292 = "cute.memref.load_vec"(%161) : (!memref_rmem_f32_) -> vector<16xf32>
      %293 = "arith.addf"(%291, %292) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%293, %163) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %294 = "cute.append_to_rank"(%158, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %295 = "cute.get_scalars"(%294) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %296 = "cute.make_stride"(%295) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %297 = "cute.make_layout"(%84, %296) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %298 = "cute.append_to_rank"(%297, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %299 = "cute.get_scalars"(%298) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %300 = "cute.make_stride"(%299) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %301 = "cute.make_layout"(%83, %300) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %302 = "cute.get_scalars"(%301) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %303 = "cute.make_stride"(%302) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %304 = "cute.make_layout"(%81, %303) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %305 = "cute.get_scalars"(%304) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %306 = "llvm.load"(%184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %307 = "llvm.icmp"(%306, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%307) ({
        %446 = "builtin.unrealized_conversion_cast"(%164) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %447 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %448 = "llvm.load"(%446) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%448, %447) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %308 = "llvm.load"(%188) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %309 = "llvm.icmp"(%308, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%309) ({
        %441 = "cute.add_offset"(%164, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %442 = "cute.add_offset"(%156, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %443 = "builtin.unrealized_conversion_cast"(%441) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %444 = "builtin.unrealized_conversion_cast"(%442) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %445 = "llvm.load"(%443) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%445, %444) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %310 = "llvm.load"(%192) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %311 = "llvm.icmp"(%310, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%311) ({
        %436 = "cute.add_offset"(%164, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %437 = "cute.add_offset"(%156, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %438 = "builtin.unrealized_conversion_cast"(%436) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %439 = "builtin.unrealized_conversion_cast"(%437) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %440 = "llvm.load"(%438) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%440, %439) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %312 = "llvm.load"(%196) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %313 = "llvm.icmp"(%312, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%313) ({
        %431 = "cute.add_offset"(%164, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %432 = "cute.add_offset"(%156, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %433 = "builtin.unrealized_conversion_cast"(%431) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %434 = "builtin.unrealized_conversion_cast"(%432) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %435 = "llvm.load"(%433) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%435, %434) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %314 = "llvm.load"(%200) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %315 = "llvm.icmp"(%314, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%315) ({
        %425 = "cute.add_offset"(%164, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %426 = "cute.make_int_tuple"(%305) : (i64) -> !cute.int_tuple<"?{i64}">
        %427 = "cute.add_offset"(%156, %426) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %428 = "builtin.unrealized_conversion_cast"(%425) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %429 = "builtin.unrealized_conversion_cast"(%427) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %430 = "llvm.load"(%428) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%430, %429) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %316 = "llvm.load"(%204) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %317 = "llvm.icmp"(%316, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%317) ({
        %418 = "cute.add_offset"(%164, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %419 = "arith.addi"(%305, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %420 = "cute.make_int_tuple"(%419) : (i64) -> !cute.int_tuple<"?{i64}">
        %421 = "cute.add_offset"(%156, %420) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %422 = "builtin.unrealized_conversion_cast"(%418) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %423 = "builtin.unrealized_conversion_cast"(%421) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %424 = "llvm.load"(%422) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%424, %423) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %318 = "llvm.load"(%208) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %319 = "llvm.icmp"(%318, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%319) ({
        %411 = "cute.add_offset"(%164, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %412 = "arith.addi"(%305, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %413 = "cute.make_int_tuple"(%412) : (i64) -> !cute.int_tuple<"?{i64}">
        %414 = "cute.add_offset"(%156, %413) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %415 = "builtin.unrealized_conversion_cast"(%411) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %416 = "builtin.unrealized_conversion_cast"(%414) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %417 = "llvm.load"(%415) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%417, %416) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %320 = "llvm.load"(%212) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %321 = "llvm.icmp"(%320, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%321) ({
        %404 = "cute.add_offset"(%164, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %405 = "arith.addi"(%305, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %406 = "cute.make_int_tuple"(%405) : (i64) -> !cute.int_tuple<"?{i64}">
        %407 = "cute.add_offset"(%156, %406) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %408 = "builtin.unrealized_conversion_cast"(%404) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %409 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %410 = "llvm.load"(%408) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%410, %409) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %322 = "llvm.load"(%216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %323 = "llvm.icmp"(%322, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%323) ({
        %396 = "cute.add_offset"(%164, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %397 = "arith.muli"(%305, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %398 = "cute.assume"(%397) : (i64) -> !cute.i64<divby 2>
        %399 = "cute.make_int_tuple"(%398) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %400 = "cute.add_offset"(%156, %399) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %401 = "builtin.unrealized_conversion_cast"(%396) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %402 = "builtin.unrealized_conversion_cast"(%400) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %403 = "llvm.load"(%401) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%403, %402) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %324 = "llvm.load"(%220) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %325 = "llvm.icmp"(%324, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%325) ({
        %388 = "cute.add_offset"(%164, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %389 = "arith.muli"(%305, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %390 = "arith.addi"(%389, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %391 = "cute.make_int_tuple"(%390) : (i64) -> !cute.int_tuple<"?{i64}">
        %392 = "cute.add_offset"(%156, %391) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %393 = "builtin.unrealized_conversion_cast"(%388) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %394 = "builtin.unrealized_conversion_cast"(%392) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %395 = "llvm.load"(%393) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%395, %394) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %326 = "llvm.load"(%224) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %327 = "llvm.icmp"(%326, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%327) ({
        %379 = "cute.add_offset"(%164, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %380 = "arith.muli"(%305, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %381 = "arith.addi"(%380, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %382 = "cute.assume"(%381) : (i64) -> !cute.i64<divby 2>
        %383 = "cute.make_int_tuple"(%382) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %384 = "cute.add_offset"(%156, %383) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %385 = "builtin.unrealized_conversion_cast"(%379) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %386 = "builtin.unrealized_conversion_cast"(%384) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %387 = "llvm.load"(%385) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%387, %386) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %328 = "llvm.load"(%228) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %329 = "llvm.icmp"(%328, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%329) ({
        %371 = "cute.add_offset"(%164, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %372 = "arith.muli"(%305, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %373 = "arith.addi"(%372, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %374 = "cute.make_int_tuple"(%373) : (i64) -> !cute.int_tuple<"?{i64}">
        %375 = "cute.add_offset"(%156, %374) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %376 = "builtin.unrealized_conversion_cast"(%371) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %377 = "builtin.unrealized_conversion_cast"(%375) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %378 = "llvm.load"(%376) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%378, %377) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %330 = "llvm.load"(%232) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %331 = "llvm.icmp"(%330, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%331) ({
        %363 = "cute.add_offset"(%164, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %364 = "arith.muli"(%305, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %365 = "cute.assume"(%364) : (i64) -> !cute.i64<divby 3>
        %366 = "cute.make_int_tuple"(%365) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %367 = "cute.add_offset"(%156, %366) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %368 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %369 = "builtin.unrealized_conversion_cast"(%367) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %370 = "llvm.load"(%368) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%370, %369) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %332 = "llvm.load"(%236) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %333 = "llvm.icmp"(%332, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%333) ({
        %355 = "cute.add_offset"(%164, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %356 = "arith.muli"(%305, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %357 = "arith.addi"(%356, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %358 = "cute.make_int_tuple"(%357) : (i64) -> !cute.int_tuple<"?{i64}">
        %359 = "cute.add_offset"(%156, %358) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %360 = "builtin.unrealized_conversion_cast"(%355) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %361 = "builtin.unrealized_conversion_cast"(%359) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %362 = "llvm.load"(%360) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%362, %361) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %334 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %335 = "llvm.icmp"(%334, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%335) ({
        %347 = "cute.add_offset"(%164, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %348 = "arith.muli"(%305, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %349 = "arith.addi"(%348, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %350 = "cute.make_int_tuple"(%349) : (i64) -> !cute.int_tuple<"?{i64}">
        %351 = "cute.add_offset"(%156, %350) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %352 = "builtin.unrealized_conversion_cast"(%347) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %353 = "builtin.unrealized_conversion_cast"(%351) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %354 = "llvm.load"(%352) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%354, %353) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %336 = "llvm.load"(%244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %337 = "llvm.icmp"(%336, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%337) ({
        %338 = "cute.add_offset"(%164, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %339 = "arith.muli"(%305, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %340 = "arith.addi"(%339, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %341 = "cute.assume"(%340) : (i64) -> !cute.i64<divby 3>
        %342 = "cute.make_int_tuple"(%341) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %343 = "cute.add_offset"(%156, %342) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %344 = "builtin.unrealized_conversion_cast"(%338) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %345 = "builtin.unrealized_conversion_cast"(%343) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %346 = "llvm.load"(%344) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%346, %345) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
