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
      "scf.for"(%89, %88, %87) ({
      ^bb0(%arg9: i32):
        %673 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        %674 = "cute.crd2idx"(%673, %86) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %675 = "cute.add_offset"(%169, %674) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %676 = "cute.deref_arith_tuple_iter"(%675) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %677:2 = "cute.get_leaves"(%676) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %678 = "cute.make_coord"(%677#0, %677#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %679:2 = "cute.get_scalars"(%678) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %680 = "arith.cmpi"(%679#0, %172#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %681 = "arith.cmpi"(%679#1, %172#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %682 = "arith.andi"(%680, %681) : (i1, i1) -> i1
        %683 = "arith.extui"(%682) : (i1) -> i8
        "cute.memref.store"(%170, %673, %683) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %173 = "cute.get_iter"(%170) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %174 = "cute.append_to_rank"(%140, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %175 = "cute.get_scalars"(%174) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %176 = "cute.make_stride"(%175) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %177 = "cute.make_layout"(%84, %176) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %178 = "cute.append_to_rank"(%177, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %179 = "cute.get_scalars"(%178) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %180 = "cute.make_stride"(%179) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %181 = "cute.make_layout"(%83, %180) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %182 = "cute.get_scalars"(%181) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %183 = "cute.make_stride"(%182) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %184 = "cute.make_layout"(%81, %183) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %185 = "cute.get_scalars"(%184) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %186 = "builtin.unrealized_conversion_cast"(%173) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %187 = "llvm.load"(%186) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %188 = "llvm.icmp"(%187, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%188) ({
        %670 = "builtin.unrealized_conversion_cast"(%138) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %671 = "builtin.unrealized_conversion_cast"(%160) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %672 = "llvm.load"(%670) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%672, %671) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %189 = "cute.add_offset"(%173, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %190 = "builtin.unrealized_conversion_cast"(%189) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %191 = "llvm.load"(%190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %192 = "llvm.icmp"(%191, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%192) ({
        %665 = "cute.add_offset"(%138, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %666 = "cute.add_offset"(%160, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %667 = "builtin.unrealized_conversion_cast"(%665) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %668 = "builtin.unrealized_conversion_cast"(%666) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %669 = "llvm.load"(%667) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%669, %668) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %193 = "cute.add_offset"(%173, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %194 = "builtin.unrealized_conversion_cast"(%193) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %195 = "llvm.load"(%194) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %196 = "llvm.icmp"(%195, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%196) ({
        %660 = "cute.add_offset"(%138, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %661 = "cute.add_offset"(%160, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %662 = "builtin.unrealized_conversion_cast"(%660) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %663 = "builtin.unrealized_conversion_cast"(%661) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %664 = "llvm.load"(%662) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%664, %663) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %197 = "cute.add_offset"(%173, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %198 = "builtin.unrealized_conversion_cast"(%197) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %199 = "llvm.load"(%198) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %200 = "llvm.icmp"(%199, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%200) ({
        %655 = "cute.add_offset"(%138, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %656 = "cute.add_offset"(%160, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %657 = "builtin.unrealized_conversion_cast"(%655) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %658 = "builtin.unrealized_conversion_cast"(%656) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %659 = "llvm.load"(%657) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%659, %658) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %201 = "cute.add_offset"(%173, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %202 = "builtin.unrealized_conversion_cast"(%201) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %203 = "llvm.load"(%202) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %204 = "llvm.icmp"(%203, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%204) ({
        %649 = "cute.make_int_tuple"(%185) : (i64) -> !cute.int_tuple<"?{i64}">
        %650 = "cute.add_offset"(%138, %649) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %651 = "cute.add_offset"(%160, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %652 = "builtin.unrealized_conversion_cast"(%650) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %653 = "builtin.unrealized_conversion_cast"(%651) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %654 = "llvm.load"(%652) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%654, %653) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %205 = "cute.add_offset"(%173, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %206 = "builtin.unrealized_conversion_cast"(%205) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %207 = "llvm.load"(%206) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %208 = "llvm.icmp"(%207, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%208) ({
        %642 = "arith.addi"(%185, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %643 = "cute.make_int_tuple"(%642) : (i64) -> !cute.int_tuple<"?{i64}">
        %644 = "cute.add_offset"(%138, %643) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %645 = "cute.add_offset"(%160, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %646 = "builtin.unrealized_conversion_cast"(%644) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %647 = "builtin.unrealized_conversion_cast"(%645) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %648 = "llvm.load"(%646) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%648, %647) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %209 = "cute.add_offset"(%173, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %210 = "builtin.unrealized_conversion_cast"(%209) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %211 = "llvm.load"(%210) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %212 = "llvm.icmp"(%211, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%212) ({
        %635 = "arith.addi"(%185, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %636 = "cute.make_int_tuple"(%635) : (i64) -> !cute.int_tuple<"?{i64}">
        %637 = "cute.add_offset"(%138, %636) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %638 = "cute.add_offset"(%160, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %639 = "builtin.unrealized_conversion_cast"(%637) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %640 = "builtin.unrealized_conversion_cast"(%638) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %641 = "llvm.load"(%639) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%641, %640) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %213 = "cute.add_offset"(%173, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %214 = "builtin.unrealized_conversion_cast"(%213) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %215 = "llvm.load"(%214) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %216 = "llvm.icmp"(%215, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%216) ({
        %628 = "arith.addi"(%185, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %629 = "cute.make_int_tuple"(%628) : (i64) -> !cute.int_tuple<"?{i64}">
        %630 = "cute.add_offset"(%138, %629) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %631 = "cute.add_offset"(%160, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %632 = "builtin.unrealized_conversion_cast"(%630) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %633 = "builtin.unrealized_conversion_cast"(%631) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %634 = "llvm.load"(%632) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%634, %633) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %217 = "cute.add_offset"(%173, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %218 = "builtin.unrealized_conversion_cast"(%217) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %219 = "llvm.load"(%218) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %220 = "llvm.icmp"(%219, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%220) ({
        %620 = "arith.muli"(%185, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %621 = "cute.assume"(%620) : (i64) -> !cute.i64<divby 2>
        %622 = "cute.make_int_tuple"(%621) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %623 = "cute.add_offset"(%138, %622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %624 = "cute.add_offset"(%160, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %625 = "builtin.unrealized_conversion_cast"(%623) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %626 = "builtin.unrealized_conversion_cast"(%624) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %627 = "llvm.load"(%625) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%627, %626) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %221 = "cute.add_offset"(%173, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %222 = "builtin.unrealized_conversion_cast"(%221) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %223 = "llvm.load"(%222) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %224 = "llvm.icmp"(%223, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%224) ({
        %612 = "arith.muli"(%185, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %613 = "arith.addi"(%612, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %614 = "cute.make_int_tuple"(%613) : (i64) -> !cute.int_tuple<"?{i64}">
        %615 = "cute.add_offset"(%138, %614) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %616 = "cute.add_offset"(%160, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %617 = "builtin.unrealized_conversion_cast"(%615) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %618 = "builtin.unrealized_conversion_cast"(%616) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %619 = "llvm.load"(%617) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%619, %618) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %225 = "cute.add_offset"(%173, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %226 = "builtin.unrealized_conversion_cast"(%225) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %227 = "llvm.load"(%226) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %228 = "llvm.icmp"(%227, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%228) ({
        %603 = "arith.muli"(%185, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %604 = "arith.addi"(%603, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %605 = "cute.assume"(%604) : (i64) -> !cute.i64<divby 2>
        %606 = "cute.make_int_tuple"(%605) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %607 = "cute.add_offset"(%138, %606) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %608 = "cute.add_offset"(%160, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %609 = "builtin.unrealized_conversion_cast"(%607) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %610 = "builtin.unrealized_conversion_cast"(%608) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %611 = "llvm.load"(%609) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%611, %610) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %229 = "cute.add_offset"(%173, %67) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %230 = "builtin.unrealized_conversion_cast"(%229) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %231 = "llvm.load"(%230) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %232 = "llvm.icmp"(%231, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%232) ({
        %595 = "arith.muli"(%185, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %596 = "arith.addi"(%595, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %597 = "cute.make_int_tuple"(%596) : (i64) -> !cute.int_tuple<"?{i64}">
        %598 = "cute.add_offset"(%138, %597) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %599 = "cute.add_offset"(%160, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %600 = "builtin.unrealized_conversion_cast"(%598) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %601 = "builtin.unrealized_conversion_cast"(%599) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %602 = "llvm.load"(%600) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%602, %601) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %233 = "cute.add_offset"(%173, %66) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %234 = "builtin.unrealized_conversion_cast"(%233) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %235 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %236 = "llvm.icmp"(%235, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%236) ({
        %587 = "arith.muli"(%185, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %588 = "cute.assume"(%587) : (i64) -> !cute.i64<divby 3>
        %589 = "cute.make_int_tuple"(%588) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %590 = "cute.add_offset"(%138, %589) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %591 = "cute.add_offset"(%160, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %592 = "builtin.unrealized_conversion_cast"(%590) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %593 = "builtin.unrealized_conversion_cast"(%591) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %594 = "llvm.load"(%592) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%594, %593) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %237 = "cute.add_offset"(%173, %65) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %238 = "builtin.unrealized_conversion_cast"(%237) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %239 = "llvm.load"(%238) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %240 = "llvm.icmp"(%239, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%240) ({
        %579 = "arith.muli"(%185, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %580 = "arith.addi"(%579, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %581 = "cute.make_int_tuple"(%580) : (i64) -> !cute.int_tuple<"?{i64}">
        %582 = "cute.add_offset"(%138, %581) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %583 = "cute.add_offset"(%160, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %584 = "builtin.unrealized_conversion_cast"(%582) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %585 = "builtin.unrealized_conversion_cast"(%583) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %586 = "llvm.load"(%584) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%586, %585) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %241 = "cute.add_offset"(%173, %64) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %242 = "builtin.unrealized_conversion_cast"(%241) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %243 = "llvm.load"(%242) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %244 = "llvm.icmp"(%243, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%244) ({
        %571 = "arith.muli"(%185, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %572 = "arith.addi"(%571, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %573 = "cute.make_int_tuple"(%572) : (i64) -> !cute.int_tuple<"?{i64}">
        %574 = "cute.add_offset"(%138, %573) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %575 = "cute.add_offset"(%160, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %576 = "builtin.unrealized_conversion_cast"(%574) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %577 = "builtin.unrealized_conversion_cast"(%575) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %578 = "llvm.load"(%576) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%578, %577) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %245 = "cute.add_offset"(%173, %63) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %246 = "builtin.unrealized_conversion_cast"(%245) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %247 = "llvm.load"(%246) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %248 = "llvm.icmp"(%247, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%248) ({
        %562 = "arith.muli"(%185, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %563 = "arith.addi"(%562, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %564 = "cute.assume"(%563) : (i64) -> !cute.i64<divby 3>
        %565 = "cute.make_int_tuple"(%564) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %566 = "cute.add_offset"(%138, %565) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %567 = "cute.add_offset"(%160, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %568 = "builtin.unrealized_conversion_cast"(%566) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %569 = "builtin.unrealized_conversion_cast"(%567) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %570 = "llvm.load"(%568) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%570, %569) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %249 = "cute.append_to_rank"(%149, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %250 = "cute.get_scalars"(%249) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %251 = "cute.make_stride"(%250) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %252 = "cute.make_layout"(%84, %251) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %253 = "cute.append_to_rank"(%252, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %254 = "cute.get_scalars"(%253) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %255 = "cute.make_stride"(%254) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %256 = "cute.make_layout"(%83, %255) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %257 = "cute.get_scalars"(%256) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %258 = "cute.make_stride"(%257) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %259 = "cute.make_layout"(%81, %258) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %260 = "cute.get_scalars"(%259) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %261 = "llvm.load"(%186) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %262 = "llvm.icmp"(%261, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%262) ({
        %559 = "builtin.unrealized_conversion_cast"(%147) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %560 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %561 = "llvm.load"(%559) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%561, %560) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %263 = "llvm.load"(%190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %264 = "llvm.icmp"(%263, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%264) ({
        %554 = "cute.add_offset"(%147, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %555 = "cute.add_offset"(%162, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %556 = "builtin.unrealized_conversion_cast"(%554) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %557 = "builtin.unrealized_conversion_cast"(%555) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %558 = "llvm.load"(%556) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%558, %557) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %265 = "llvm.load"(%194) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %266 = "llvm.icmp"(%265, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%266) ({
        %549 = "cute.add_offset"(%147, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %550 = "cute.add_offset"(%162, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %551 = "builtin.unrealized_conversion_cast"(%549) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %552 = "builtin.unrealized_conversion_cast"(%550) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %553 = "llvm.load"(%551) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%553, %552) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %267 = "llvm.load"(%198) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %268 = "llvm.icmp"(%267, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%268) ({
        %544 = "cute.add_offset"(%147, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %545 = "cute.add_offset"(%162, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %546 = "builtin.unrealized_conversion_cast"(%544) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %547 = "builtin.unrealized_conversion_cast"(%545) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %548 = "llvm.load"(%546) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%548, %547) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %269 = "llvm.load"(%202) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %270 = "llvm.icmp"(%269, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%270) ({
        %538 = "cute.make_int_tuple"(%260) : (i64) -> !cute.int_tuple<"?{i64}">
        %539 = "cute.add_offset"(%147, %538) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %540 = "cute.add_offset"(%162, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %541 = "builtin.unrealized_conversion_cast"(%539) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %542 = "builtin.unrealized_conversion_cast"(%540) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %543 = "llvm.load"(%541) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%543, %542) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %271 = "llvm.load"(%206) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %272 = "llvm.icmp"(%271, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%272) ({
        %531 = "arith.addi"(%260, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %532 = "cute.make_int_tuple"(%531) : (i64) -> !cute.int_tuple<"?{i64}">
        %533 = "cute.add_offset"(%147, %532) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %534 = "cute.add_offset"(%162, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %535 = "builtin.unrealized_conversion_cast"(%533) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %536 = "builtin.unrealized_conversion_cast"(%534) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %537 = "llvm.load"(%535) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%537, %536) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %273 = "llvm.load"(%210) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %274 = "llvm.icmp"(%273, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%274) ({
        %524 = "arith.addi"(%260, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %525 = "cute.make_int_tuple"(%524) : (i64) -> !cute.int_tuple<"?{i64}">
        %526 = "cute.add_offset"(%147, %525) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %527 = "cute.add_offset"(%162, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %528 = "builtin.unrealized_conversion_cast"(%526) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %529 = "builtin.unrealized_conversion_cast"(%527) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %530 = "llvm.load"(%528) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%530, %529) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %275 = "llvm.load"(%214) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %276 = "llvm.icmp"(%275, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%276) ({
        %517 = "arith.addi"(%260, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %518 = "cute.make_int_tuple"(%517) : (i64) -> !cute.int_tuple<"?{i64}">
        %519 = "cute.add_offset"(%147, %518) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %520 = "cute.add_offset"(%162, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %521 = "builtin.unrealized_conversion_cast"(%519) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %522 = "builtin.unrealized_conversion_cast"(%520) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %523 = "llvm.load"(%521) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%523, %522) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %277 = "llvm.load"(%218) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %278 = "llvm.icmp"(%277, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%278) ({
        %509 = "arith.muli"(%260, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %510 = "cute.assume"(%509) : (i64) -> !cute.i64<divby 2>
        %511 = "cute.make_int_tuple"(%510) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %512 = "cute.add_offset"(%147, %511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %513 = "cute.add_offset"(%162, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %514 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %515 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %516 = "llvm.load"(%514) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%516, %515) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %279 = "llvm.load"(%222) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %280 = "llvm.icmp"(%279, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%280) ({
        %501 = "arith.muli"(%260, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %502 = "arith.addi"(%501, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %503 = "cute.make_int_tuple"(%502) : (i64) -> !cute.int_tuple<"?{i64}">
        %504 = "cute.add_offset"(%147, %503) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %505 = "cute.add_offset"(%162, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %506 = "builtin.unrealized_conversion_cast"(%504) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %507 = "builtin.unrealized_conversion_cast"(%505) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %508 = "llvm.load"(%506) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%508, %507) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %281 = "llvm.load"(%226) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %282 = "llvm.icmp"(%281, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%282) ({
        %492 = "arith.muli"(%260, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %493 = "arith.addi"(%492, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %494 = "cute.assume"(%493) : (i64) -> !cute.i64<divby 2>
        %495 = "cute.make_int_tuple"(%494) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %496 = "cute.add_offset"(%147, %495) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %497 = "cute.add_offset"(%162, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %498 = "builtin.unrealized_conversion_cast"(%496) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %499 = "builtin.unrealized_conversion_cast"(%497) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %500 = "llvm.load"(%498) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%500, %499) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %283 = "llvm.load"(%230) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %284 = "llvm.icmp"(%283, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%284) ({
        %484 = "arith.muli"(%260, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %485 = "arith.addi"(%484, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %486 = "cute.make_int_tuple"(%485) : (i64) -> !cute.int_tuple<"?{i64}">
        %487 = "cute.add_offset"(%147, %486) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %488 = "cute.add_offset"(%162, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %489 = "builtin.unrealized_conversion_cast"(%487) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %490 = "builtin.unrealized_conversion_cast"(%488) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %491 = "llvm.load"(%489) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%491, %490) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %285 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %286 = "llvm.icmp"(%285, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%286) ({
        %476 = "arith.muli"(%260, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %477 = "cute.assume"(%476) : (i64) -> !cute.i64<divby 3>
        %478 = "cute.make_int_tuple"(%477) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %479 = "cute.add_offset"(%147, %478) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %480 = "cute.add_offset"(%162, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %481 = "builtin.unrealized_conversion_cast"(%479) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %482 = "builtin.unrealized_conversion_cast"(%480) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %483 = "llvm.load"(%481) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%483, %482) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %287 = "llvm.load"(%238) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %288 = "llvm.icmp"(%287, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%288) ({
        %468 = "arith.muli"(%260, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %469 = "arith.addi"(%468, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %470 = "cute.make_int_tuple"(%469) : (i64) -> !cute.int_tuple<"?{i64}">
        %471 = "cute.add_offset"(%147, %470) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %472 = "cute.add_offset"(%162, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %473 = "builtin.unrealized_conversion_cast"(%471) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %474 = "builtin.unrealized_conversion_cast"(%472) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %475 = "llvm.load"(%473) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%475, %474) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %289 = "llvm.load"(%242) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %290 = "llvm.icmp"(%289, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%290) ({
        %460 = "arith.muli"(%260, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %461 = "arith.addi"(%460, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %462 = "cute.make_int_tuple"(%461) : (i64) -> !cute.int_tuple<"?{i64}">
        %463 = "cute.add_offset"(%147, %462) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %464 = "cute.add_offset"(%162, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %465 = "builtin.unrealized_conversion_cast"(%463) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %466 = "builtin.unrealized_conversion_cast"(%464) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %467 = "llvm.load"(%465) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%467, %466) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %291 = "llvm.load"(%246) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %292 = "llvm.icmp"(%291, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%292) ({
        %451 = "arith.muli"(%260, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %452 = "arith.addi"(%451, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %453 = "cute.assume"(%452) : (i64) -> !cute.i64<divby 3>
        %454 = "cute.make_int_tuple"(%453) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %455 = "cute.add_offset"(%147, %454) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %456 = "cute.add_offset"(%162, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %457 = "builtin.unrealized_conversion_cast"(%455) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %458 = "builtin.unrealized_conversion_cast"(%456) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %459 = "llvm.load"(%457) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%459, %458) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %293 = "cute.memref.load_vec"(%159) : (!memref_rmem_f32_) -> vector<16xf32>
      %294 = "cute.memref.load_vec"(%161) : (!memref_rmem_f32_) -> vector<16xf32>
      %295 = "arith.addf"(%293, %294) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%295, %163) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %296 = "cute.append_to_rank"(%158, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %297 = "cute.get_scalars"(%296) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %298 = "cute.make_stride"(%297) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %299 = "cute.make_layout"(%84, %298) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %300 = "cute.append_to_rank"(%299, %85) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %301 = "cute.get_scalars"(%300) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %302 = "cute.make_stride"(%301) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %303 = "cute.make_layout"(%83, %302) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %304 = "cute.get_scalars"(%303) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %305 = "cute.make_stride"(%304) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %306 = "cute.make_layout"(%81, %305) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %307 = "cute.get_scalars"(%306) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %308 = "llvm.load"(%186) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %309 = "llvm.icmp"(%308, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%309) ({
        %448 = "builtin.unrealized_conversion_cast"(%164) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %449 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %450 = "llvm.load"(%448) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%450, %449) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %310 = "llvm.load"(%190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %311 = "llvm.icmp"(%310, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%311) ({
        %443 = "cute.add_offset"(%164, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %444 = "cute.add_offset"(%156, %82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %445 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %446 = "builtin.unrealized_conversion_cast"(%444) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %447 = "llvm.load"(%445) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%447, %446) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %312 = "llvm.load"(%194) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %313 = "llvm.icmp"(%312, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%313) ({
        %438 = "cute.add_offset"(%164, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %439 = "cute.add_offset"(%156, %79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %440 = "builtin.unrealized_conversion_cast"(%438) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %441 = "builtin.unrealized_conversion_cast"(%439) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %442 = "llvm.load"(%440) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%442, %441) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %314 = "llvm.load"(%198) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %315 = "llvm.icmp"(%314, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%315) ({
        %433 = "cute.add_offset"(%164, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %434 = "cute.add_offset"(%156, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %435 = "builtin.unrealized_conversion_cast"(%433) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %436 = "builtin.unrealized_conversion_cast"(%434) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %437 = "llvm.load"(%435) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%437, %436) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %316 = "llvm.load"(%202) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %317 = "llvm.icmp"(%316, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%317) ({
        %427 = "cute.add_offset"(%164, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %428 = "cute.make_int_tuple"(%307) : (i64) -> !cute.int_tuple<"?{i64}">
        %429 = "cute.add_offset"(%156, %428) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %430 = "builtin.unrealized_conversion_cast"(%427) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %431 = "builtin.unrealized_conversion_cast"(%429) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %432 = "llvm.load"(%430) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%432, %431) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %318 = "llvm.load"(%206) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %319 = "llvm.icmp"(%318, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%319) ({
        %420 = "cute.add_offset"(%164, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %421 = "arith.addi"(%307, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %422 = "cute.make_int_tuple"(%421) : (i64) -> !cute.int_tuple<"?{i64}">
        %423 = "cute.add_offset"(%156, %422) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %424 = "builtin.unrealized_conversion_cast"(%420) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %425 = "builtin.unrealized_conversion_cast"(%423) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %426 = "llvm.load"(%424) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%426, %425) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %320 = "llvm.load"(%210) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %321 = "llvm.icmp"(%320, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%321) ({
        %413 = "cute.add_offset"(%164, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %414 = "arith.addi"(%307, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %415 = "cute.make_int_tuple"(%414) : (i64) -> !cute.int_tuple<"?{i64}">
        %416 = "cute.add_offset"(%156, %415) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %417 = "builtin.unrealized_conversion_cast"(%413) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %418 = "builtin.unrealized_conversion_cast"(%416) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %419 = "llvm.load"(%417) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%419, %418) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %322 = "llvm.load"(%214) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %323 = "llvm.icmp"(%322, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%323) ({
        %406 = "cute.add_offset"(%164, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %407 = "arith.addi"(%307, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %408 = "cute.make_int_tuple"(%407) : (i64) -> !cute.int_tuple<"?{i64}">
        %409 = "cute.add_offset"(%156, %408) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %410 = "builtin.unrealized_conversion_cast"(%406) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %411 = "builtin.unrealized_conversion_cast"(%409) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %412 = "llvm.load"(%410) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%412, %411) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %324 = "llvm.load"(%218) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %325 = "llvm.icmp"(%324, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%325) ({
        %398 = "cute.add_offset"(%164, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %399 = "arith.muli"(%307, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %400 = "cute.assume"(%399) : (i64) -> !cute.i64<divby 2>
        %401 = "cute.make_int_tuple"(%400) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %402 = "cute.add_offset"(%156, %401) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %403 = "builtin.unrealized_conversion_cast"(%398) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %404 = "builtin.unrealized_conversion_cast"(%402) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %405 = "llvm.load"(%403) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%405, %404) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %326 = "llvm.load"(%222) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %327 = "llvm.icmp"(%326, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%327) ({
        %390 = "cute.add_offset"(%164, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %391 = "arith.muli"(%307, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %392 = "arith.addi"(%391, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %393 = "cute.make_int_tuple"(%392) : (i64) -> !cute.int_tuple<"?{i64}">
        %394 = "cute.add_offset"(%156, %393) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %395 = "builtin.unrealized_conversion_cast"(%390) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %396 = "builtin.unrealized_conversion_cast"(%394) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %397 = "llvm.load"(%395) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%397, %396) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %328 = "llvm.load"(%226) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %329 = "llvm.icmp"(%328, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%329) ({
        %381 = "cute.add_offset"(%164, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %382 = "arith.muli"(%307, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %383 = "arith.addi"(%382, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %384 = "cute.assume"(%383) : (i64) -> !cute.i64<divby 2>
        %385 = "cute.make_int_tuple"(%384) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %386 = "cute.add_offset"(%156, %385) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %387 = "builtin.unrealized_conversion_cast"(%381) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %388 = "builtin.unrealized_conversion_cast"(%386) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %389 = "llvm.load"(%387) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%389, %388) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %330 = "llvm.load"(%230) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %331 = "llvm.icmp"(%330, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%331) ({
        %373 = "cute.add_offset"(%164, %67) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %374 = "arith.muli"(%307, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %375 = "arith.addi"(%374, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %376 = "cute.make_int_tuple"(%375) : (i64) -> !cute.int_tuple<"?{i64}">
        %377 = "cute.add_offset"(%156, %376) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %378 = "builtin.unrealized_conversion_cast"(%373) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %379 = "builtin.unrealized_conversion_cast"(%377) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %380 = "llvm.load"(%378) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%380, %379) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %332 = "llvm.load"(%234) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %333 = "llvm.icmp"(%332, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%333) ({
        %365 = "cute.add_offset"(%164, %66) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %366 = "arith.muli"(%307, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %367 = "cute.assume"(%366) : (i64) -> !cute.i64<divby 3>
        %368 = "cute.make_int_tuple"(%367) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %369 = "cute.add_offset"(%156, %368) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %370 = "builtin.unrealized_conversion_cast"(%365) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %371 = "builtin.unrealized_conversion_cast"(%369) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %372 = "llvm.load"(%370) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%372, %371) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %334 = "llvm.load"(%238) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %335 = "llvm.icmp"(%334, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%335) ({
        %357 = "cute.add_offset"(%164, %65) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %358 = "arith.muli"(%307, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %359 = "arith.addi"(%358, %75) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %360 = "cute.make_int_tuple"(%359) : (i64) -> !cute.int_tuple<"?{i64}">
        %361 = "cute.add_offset"(%156, %360) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %362 = "builtin.unrealized_conversion_cast"(%357) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %363 = "builtin.unrealized_conversion_cast"(%361) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %364 = "llvm.load"(%362) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%364, %363) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %336 = "llvm.load"(%242) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %337 = "llvm.icmp"(%336, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%337) ({
        %349 = "cute.add_offset"(%164, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %350 = "arith.muli"(%307, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %351 = "arith.addi"(%350, %73) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %352 = "cute.make_int_tuple"(%351) : (i64) -> !cute.int_tuple<"?{i64}">
        %353 = "cute.add_offset"(%156, %352) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %354 = "builtin.unrealized_conversion_cast"(%349) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %355 = "builtin.unrealized_conversion_cast"(%353) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %356 = "llvm.load"(%354) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%356, %355) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %338 = "llvm.load"(%246) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %339 = "llvm.icmp"(%338, %80) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%339) ({
        %340 = "cute.add_offset"(%164, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %341 = "arith.muli"(%307, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %342 = "arith.addi"(%341, %71) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %343 = "cute.assume"(%342) : (i64) -> !cute.i64<divby 3>
        %344 = "cute.make_int_tuple"(%343) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %345 = "cute.add_offset"(%156, %344) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %346 = "builtin.unrealized_conversion_cast"(%340) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %347 = "builtin.unrealized_conversion_cast"(%345) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %348 = "llvm.load"(%346) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%348, %347) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
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
