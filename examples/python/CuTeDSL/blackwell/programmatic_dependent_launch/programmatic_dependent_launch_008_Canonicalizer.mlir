!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !memref_gmem_f32_, %arg7: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg8: i32, %arg9: i32):
      %68 = "cute.static"() : () -> !cute.int_tuple<"15">
      %69 = "cute.static"() : () -> !cute.int_tuple<"14">
      %70 = "cute.static"() : () -> !cute.int_tuple<"13">
      %71 = "cute.static"() : () -> !cute.int_tuple<"12">
      %72 = "cute.static"() : () -> !cute.int_tuple<"11">
      %73 = "cute.static"() : () -> !cute.int_tuple<"10">
      %74 = "cute.static"() : () -> !cute.int_tuple<"9">
      %75 = "cute.static"() : () -> !cute.int_tuple<"8">
      %76 = "arith.constant"() <{value = 3 : i64}> : () -> i64
      %77 = "cute.static"() : () -> !cute.int_tuple<"7">
      %78 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %79 = "cute.static"() : () -> !cute.int_tuple<"6">
      %80 = "arith.constant"() <{value = 1 : i64}> : () -> i64
      %81 = "cute.static"() : () -> !cute.int_tuple<"5">
      %82 = "cute.static"() : () -> !cute.int_tuple<"4">
      %83 = "cute.static"() : () -> !cute.int_tuple<"3">
      %84 = "cute.static"() : () -> !cute.int_tuple<"2">
      %85 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %86 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
      %87 = "cute.static"() : () -> !cute.int_tuple<"1">
      %88 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %89 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %90 = "cute.static"() : () -> !cute.layout<"1:0">
      %91 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %92 = "cute.static"() : () -> !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %93 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %94 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %95 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %96 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %97 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %98 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %99 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %100 = "cute.static"() : () -> !cute.shape<"(16,128)">
      %101 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %102 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %103 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %104 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %105:4 = "cute.get_scalars"(%104) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %106 = "cute.make_stride"(%105#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %107 = "cute.make_layout"(%100, %106) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %108 = "cute.crd2idx"(%103, %104) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %109 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %110 = "cute.add_offset"(%109, %108) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %111 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %112 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %113:4 = "cute.get_scalars"(%112) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %114 = "cute.make_stride"(%113#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %115 = "cute.make_layout"(%100, %114) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %116 = "cute.crd2idx"(%111, %112) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %117 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %118 = "cute.add_offset"(%117, %116) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %119 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %120 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %121:4 = "cute.get_scalars"(%120) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %122 = "cute.make_stride"(%121#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %123 = "cute.make_layout"(%100, %122) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %124 = "cute.crd2idx"(%119, %120) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %125 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %126 = "cute.add_offset"(%125, %124) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %127 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %128 = "cute.get_layout"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %129 = "cute.crd2idx"(%127, %128) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %130 = "cute.get_iter"(%arg7) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
      %131 = "cute.add_offset"(%130, %129) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %132 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %133 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %134 = "cute.make_tiled_copy"(%132) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %135 = "cute.make_tiled_copy"(%132) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %136 = "cute.make_tiled_copy"(%133) : (!cute_nvgpu.atom.universal_copy<f32>) -> !copy_simt
      %137 = "cute.get_scalars"(%107) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %138 = "arith.muli"(%137, %99) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %139 = "arith.divsi"(%101, %98) : (i32, i32) -> i32
      %140 = "arith.remsi"(%101, %98) : (i32, i32) -> i32
      %141 = "arith.muli"(%140, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %142 = "arith.extsi"(%139) : (i32) -> i64
      %143 = "arith.muli"(%142, %138) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %144 = "arith.extsi"(%141) : (i32) -> i64
      %145 = "arith.addi"(%144, %143) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %146 = "cute.assume"(%145) : (i64) -> !cute.i64<divby 4>
      %147 = "cute.make_int_tuple"(%146) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %148 = "cute.add_offset"(%110, %147) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %149 = "cute.make_stride"(%137) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %150 = "cute.make_layout"(%96, %149) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %151 = "cute.get_scalars"(%115) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %152 = "arith.muli"(%151, %99) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %153 = "arith.divsi"(%101, %98) : (i32, i32) -> i32
      %154 = "arith.remsi"(%101, %98) : (i32, i32) -> i32
      %155 = "arith.muli"(%154, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %156 = "arith.extsi"(%153) : (i32) -> i64
      %157 = "arith.muli"(%156, %152) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %158 = "arith.extsi"(%155) : (i32) -> i64
      %159 = "arith.addi"(%158, %157) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %160 = "cute.assume"(%159) : (i64) -> !cute.i64<divby 4>
      %161 = "cute.make_int_tuple"(%160) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %162 = "cute.add_offset"(%118, %161) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %163 = "cute.make_stride"(%151) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %164 = "cute.make_layout"(%96, %163) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %165 = "cute.get_scalars"(%123) <{only_dynamic}> : (!cute.layout<"(16,128):(?{i64},1)">) -> i64
      %166 = "arith.muli"(%165, %99) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %167 = "arith.divsi"(%101, %98) : (i32, i32) -> i32
      %168 = "arith.remsi"(%101, %98) : (i32, i32) -> i32
      %169 = "arith.muli"(%168, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %170 = "arith.extsi"(%167) : (i32) -> i64
      %171 = "arith.muli"(%170, %166) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %172 = "arith.extsi"(%169) : (i32) -> i64
      %173 = "arith.addi"(%172, %171) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %174 = "cute.assume"(%173) : (i64) -> !cute.i64<divby 4>
      %175 = "cute.make_int_tuple"(%174) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %176 = "cute.add_offset"(%126, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %177 = "cute.make_stride"(%165) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %178 = "cute.make_layout"(%96, %177) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),1,1)">, !cute.stride<"((0,(1,?{i64})),0,0)">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %179 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %180 = "cute.get_iter"(%179) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %181 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %182 = "cute.get_iter"(%181) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %183 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %184 = "arith.divsi"(%101, %98) : (i32, i32) -> i32
      %185 = "arith.remsi"(%101, %98) : (i32, i32) -> i32
      %186 = "arith.muli"(%185, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %187 = "arith.muli"(%184, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %188 = "cute.assume"(%187) : (i32) -> !cute.i32<divby 4>
      %189 = "cute.assume"(%186) : (i32) -> !cute.i32<divby 4>
      %190 = "cute.make_int_tuple"(%188, %189) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %191 = "cute.add_offset"(%131, %190) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %192 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      "scf.for"(%95, %94, %93) ({
      ^bb0(%arg13: i32):
        %756 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"?">
        %757 = "cute.crd2idx"(%756, %92) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %758 = "cute.add_offset"(%191, %757) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %759 = "cute.deref_arith_tuple_iter"(%758) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %760:2 = "cute.get_leaves"(%759) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %761 = "cute.make_coord"(%760#0, %760#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %762 = "cute.make_coord"(%arg8, %arg9) : (i32, i32) -> !cute.coord<"(?,?)">
        %763:2 = "cute.get_scalars"(%761) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %764:2 = "cute.get_scalars"(%762) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %765 = "arith.cmpi"(%763#0, %764#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %766 = "arith.cmpi"(%763#1, %764#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %767 = "arith.andi"(%765, %766) : (i1, i1) -> i1
        %768 = "arith.extui"(%767) : (i1) -> i8
        %769 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%192, %769, %768) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %193 = "cute.get_iter"(%192) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      "scf.for"(%95, %91, %93) ({
      ^bb0(%arg12: i32):
        %570 = "cute.append_to_rank"(%164, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %571 = "cute.get_scalars"(%570) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
        %572 = "cute.make_stride"(%571) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %573 = "cute.make_layout"(%89, %572) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %574 = "cute.append_to_rank"(%573, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %575 = "cute.get_scalars"(%574) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
        %576 = "cute.make_stride"(%575) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %577 = "cute.make_layout"(%88, %576) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %578 = "cute.get_scalars"(%577) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
        %579 = "cute.make_stride"(%578) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %580 = "cute.make_layout"(%86, %579) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %581 = "cute.get_scalars"(%580) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
        %582 = "builtin.unrealized_conversion_cast"(%193) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %583 = "llvm.load"(%582) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %584 = "llvm.icmp"(%583, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%584) ({
          %753 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %754 = "builtin.unrealized_conversion_cast"(%182) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %755 = "llvm.load"(%753) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%755, %754) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %585 = "cute.add_offset"(%193, %87) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %586 = "builtin.unrealized_conversion_cast"(%585) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %587 = "llvm.load"(%586) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %588 = "llvm.icmp"(%587, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%588) ({
          %748 = "cute.add_offset"(%162, %87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %749 = "cute.add_offset"(%182, %87) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %750 = "builtin.unrealized_conversion_cast"(%748) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %751 = "builtin.unrealized_conversion_cast"(%749) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %752 = "llvm.load"(%750) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%752, %751) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %589 = "cute.add_offset"(%193, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %590 = "builtin.unrealized_conversion_cast"(%589) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %591 = "llvm.load"(%590) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %592 = "llvm.icmp"(%591, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%592) ({
          %743 = "cute.add_offset"(%162, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %744 = "cute.add_offset"(%182, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %745 = "builtin.unrealized_conversion_cast"(%743) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %746 = "builtin.unrealized_conversion_cast"(%744) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %747 = "llvm.load"(%745) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%747, %746) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %593 = "cute.add_offset"(%193, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %594 = "builtin.unrealized_conversion_cast"(%593) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %595 = "llvm.load"(%594) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %596 = "llvm.icmp"(%595, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%596) ({
          %738 = "cute.add_offset"(%162, %83) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %739 = "cute.add_offset"(%182, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %740 = "builtin.unrealized_conversion_cast"(%738) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %741 = "builtin.unrealized_conversion_cast"(%739) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %742 = "llvm.load"(%740) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%742, %741) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %597 = "cute.add_offset"(%193, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %598 = "builtin.unrealized_conversion_cast"(%597) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %599 = "llvm.load"(%598) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %600 = "llvm.icmp"(%599, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%600) ({
          %732 = "cute.make_int_tuple"(%581) : (i64) -> !cute.int_tuple<"?{i64}">
          %733 = "cute.add_offset"(%162, %732) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %734 = "cute.add_offset"(%182, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %735 = "builtin.unrealized_conversion_cast"(%733) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %736 = "builtin.unrealized_conversion_cast"(%734) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %737 = "llvm.load"(%735) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%737, %736) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %601 = "cute.add_offset"(%193, %81) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %602 = "builtin.unrealized_conversion_cast"(%601) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %603 = "llvm.load"(%602) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %604 = "llvm.icmp"(%603, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%604) ({
          %725 = "arith.addi"(%581, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %726 = "cute.make_int_tuple"(%725) : (i64) -> !cute.int_tuple<"?{i64}">
          %727 = "cute.add_offset"(%162, %726) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %728 = "cute.add_offset"(%182, %81) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %729 = "builtin.unrealized_conversion_cast"(%727) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %730 = "builtin.unrealized_conversion_cast"(%728) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %731 = "llvm.load"(%729) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%731, %730) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %605 = "cute.add_offset"(%193, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %606 = "builtin.unrealized_conversion_cast"(%605) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %607 = "llvm.load"(%606) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %608 = "llvm.icmp"(%607, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%608) ({
          %718 = "arith.addi"(%581, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %719 = "cute.make_int_tuple"(%718) : (i64) -> !cute.int_tuple<"?{i64}">
          %720 = "cute.add_offset"(%162, %719) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %721 = "cute.add_offset"(%182, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %722 = "builtin.unrealized_conversion_cast"(%720) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %723 = "builtin.unrealized_conversion_cast"(%721) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %724 = "llvm.load"(%722) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%724, %723) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %609 = "cute.add_offset"(%193, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %610 = "builtin.unrealized_conversion_cast"(%609) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %611 = "llvm.load"(%610) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %612 = "llvm.icmp"(%611, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%612) ({
          %711 = "arith.addi"(%581, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %712 = "cute.make_int_tuple"(%711) : (i64) -> !cute.int_tuple<"?{i64}">
          %713 = "cute.add_offset"(%162, %712) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %714 = "cute.add_offset"(%182, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %715 = "builtin.unrealized_conversion_cast"(%713) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %716 = "builtin.unrealized_conversion_cast"(%714) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %717 = "llvm.load"(%715) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%717, %716) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %613 = "cute.add_offset"(%193, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %614 = "builtin.unrealized_conversion_cast"(%613) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
        %615 = "llvm.load"(%614) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %616 = "llvm.icmp"(%615, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%616) ({
          %703 = "arith.muli"(%581, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %704 = "cute.assume"(%703) : (i64) -> !cute.i64<divby 2>
          %705 = "cute.make_int_tuple"(%704) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %706 = "cute.add_offset"(%162, %705) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %707 = "cute.add_offset"(%182, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %708 = "builtin.unrealized_conversion_cast"(%706) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %709 = "builtin.unrealized_conversion_cast"(%707) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %710 = "llvm.load"(%708) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%710, %709) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %617 = "cute.add_offset"(%193, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %618 = "builtin.unrealized_conversion_cast"(%617) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %619 = "llvm.load"(%618) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %620 = "llvm.icmp"(%619, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%620) ({
          %695 = "arith.muli"(%581, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %696 = "arith.addi"(%695, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %697 = "cute.make_int_tuple"(%696) : (i64) -> !cute.int_tuple<"?{i64}">
          %698 = "cute.add_offset"(%162, %697) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %699 = "cute.add_offset"(%182, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %700 = "builtin.unrealized_conversion_cast"(%698) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %701 = "builtin.unrealized_conversion_cast"(%699) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %702 = "llvm.load"(%700) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%702, %701) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %621 = "cute.add_offset"(%193, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %622 = "builtin.unrealized_conversion_cast"(%621) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %623 = "llvm.load"(%622) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %624 = "llvm.icmp"(%623, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%624) ({
          %686 = "arith.muli"(%581, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %687 = "arith.addi"(%686, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %688 = "cute.assume"(%687) : (i64) -> !cute.i64<divby 2>
          %689 = "cute.make_int_tuple"(%688) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %690 = "cute.add_offset"(%162, %689) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %691 = "cute.add_offset"(%182, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %692 = "builtin.unrealized_conversion_cast"(%690) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %693 = "builtin.unrealized_conversion_cast"(%691) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %694 = "llvm.load"(%692) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%694, %693) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %625 = "cute.add_offset"(%193, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %626 = "builtin.unrealized_conversion_cast"(%625) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %627 = "llvm.load"(%626) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %628 = "llvm.icmp"(%627, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%628) ({
          %678 = "arith.muli"(%581, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %679 = "arith.addi"(%678, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %680 = "cute.make_int_tuple"(%679) : (i64) -> !cute.int_tuple<"?{i64}">
          %681 = "cute.add_offset"(%162, %680) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %682 = "cute.add_offset"(%182, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %683 = "builtin.unrealized_conversion_cast"(%681) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %684 = "builtin.unrealized_conversion_cast"(%682) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %685 = "llvm.load"(%683) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%685, %684) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %629 = "cute.add_offset"(%193, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %630 = "builtin.unrealized_conversion_cast"(%629) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %631 = "llvm.load"(%630) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %632 = "llvm.icmp"(%631, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%632) ({
          %670 = "arith.muli"(%581, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %671 = "cute.assume"(%670) : (i64) -> !cute.i64<divby 3>
          %672 = "cute.make_int_tuple"(%671) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %673 = "cute.add_offset"(%162, %672) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %674 = "cute.add_offset"(%182, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %675 = "builtin.unrealized_conversion_cast"(%673) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %676 = "builtin.unrealized_conversion_cast"(%674) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %677 = "llvm.load"(%675) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%677, %676) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %633 = "cute.add_offset"(%193, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %634 = "builtin.unrealized_conversion_cast"(%633) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %635 = "llvm.load"(%634) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %636 = "llvm.icmp"(%635, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%636) ({
          %662 = "arith.muli"(%581, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %663 = "arith.addi"(%662, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %664 = "cute.make_int_tuple"(%663) : (i64) -> !cute.int_tuple<"?{i64}">
          %665 = "cute.add_offset"(%162, %664) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %666 = "cute.add_offset"(%182, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %667 = "builtin.unrealized_conversion_cast"(%665) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %668 = "builtin.unrealized_conversion_cast"(%666) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %669 = "llvm.load"(%667) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%669, %668) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %637 = "cute.add_offset"(%193, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %638 = "builtin.unrealized_conversion_cast"(%637) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %639 = "llvm.load"(%638) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %640 = "llvm.icmp"(%639, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%640) ({
          %654 = "arith.muli"(%581, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %655 = "arith.addi"(%654, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %656 = "cute.make_int_tuple"(%655) : (i64) -> !cute.int_tuple<"?{i64}">
          %657 = "cute.add_offset"(%162, %656) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %658 = "cute.add_offset"(%182, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %659 = "builtin.unrealized_conversion_cast"(%657) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %660 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %661 = "llvm.load"(%659) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%661, %660) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %641 = "cute.add_offset"(%193, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %642 = "builtin.unrealized_conversion_cast"(%641) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %643 = "llvm.load"(%642) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %644 = "llvm.icmp"(%643, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%644) ({
          %645 = "arith.muli"(%581, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %646 = "arith.addi"(%645, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %647 = "cute.assume"(%646) : (i64) -> !cute.i64<divby 3>
          %648 = "cute.make_int_tuple"(%647) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %649 = "cute.add_offset"(%162, %648) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %650 = "cute.add_offset"(%182, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %651 = "builtin.unrealized_conversion_cast"(%649) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %652 = "builtin.unrealized_conversion_cast"(%650) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %653 = "llvm.load"(%651) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%653, %652) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      "llvm.inline_asm"() <{asm_dialect = 0 : i64, asm_string = "griddepcontrol.wait;", constraints = "", has_side_effects}> : () -> ()
      "scf.for"(%95, %91, %93) ({
      ^bb0(%arg11: i32):
        %384 = "cute.append_to_rank"(%150, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %385 = "cute.get_scalars"(%384) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
        %386 = "cute.make_stride"(%385) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %387 = "cute.make_layout"(%89, %386) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %388 = "cute.append_to_rank"(%387, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %389 = "cute.get_scalars"(%388) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
        %390 = "cute.make_stride"(%389) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %391 = "cute.make_layout"(%88, %390) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %392 = "cute.get_scalars"(%391) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
        %393 = "cute.make_stride"(%392) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %394 = "cute.make_layout"(%86, %393) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %395 = "cute.get_scalars"(%394) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
        %396 = "builtin.unrealized_conversion_cast"(%193) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
        %397 = "llvm.load"(%396) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %398 = "llvm.icmp"(%397, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%398) ({
          %567 = "builtin.unrealized_conversion_cast"(%148) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %568 = "builtin.unrealized_conversion_cast"(%180) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %569 = "llvm.load"(%567) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%569, %568) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %399 = "cute.add_offset"(%193, %87) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %400 = "builtin.unrealized_conversion_cast"(%399) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %401 = "llvm.load"(%400) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %402 = "llvm.icmp"(%401, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%402) ({
          %562 = "cute.add_offset"(%148, %87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %563 = "cute.add_offset"(%180, %87) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %564 = "builtin.unrealized_conversion_cast"(%562) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %565 = "builtin.unrealized_conversion_cast"(%563) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %566 = "llvm.load"(%564) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%566, %565) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %403 = "cute.add_offset"(%193, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %404 = "builtin.unrealized_conversion_cast"(%403) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %405 = "llvm.load"(%404) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %406 = "llvm.icmp"(%405, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%406) ({
          %557 = "cute.add_offset"(%148, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %558 = "cute.add_offset"(%180, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %559 = "builtin.unrealized_conversion_cast"(%557) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %560 = "builtin.unrealized_conversion_cast"(%558) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %561 = "llvm.load"(%559) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%561, %560) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %407 = "cute.add_offset"(%193, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %408 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %409 = "llvm.load"(%408) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %410 = "llvm.icmp"(%409, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%410) ({
          %552 = "cute.add_offset"(%148, %83) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %553 = "cute.add_offset"(%180, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %554 = "builtin.unrealized_conversion_cast"(%552) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %555 = "builtin.unrealized_conversion_cast"(%553) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %556 = "llvm.load"(%554) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%556, %555) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %411 = "cute.add_offset"(%193, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %412 = "builtin.unrealized_conversion_cast"(%411) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %413 = "llvm.load"(%412) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %414 = "llvm.icmp"(%413, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%414) ({
          %546 = "cute.make_int_tuple"(%395) : (i64) -> !cute.int_tuple<"?{i64}">
          %547 = "cute.add_offset"(%148, %546) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %548 = "cute.add_offset"(%180, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %549 = "builtin.unrealized_conversion_cast"(%547) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %550 = "builtin.unrealized_conversion_cast"(%548) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %551 = "llvm.load"(%549) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%551, %550) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %415 = "cute.add_offset"(%193, %81) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %416 = "builtin.unrealized_conversion_cast"(%415) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %417 = "llvm.load"(%416) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %418 = "llvm.icmp"(%417, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%418) ({
          %539 = "arith.addi"(%395, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %540 = "cute.make_int_tuple"(%539) : (i64) -> !cute.int_tuple<"?{i64}">
          %541 = "cute.add_offset"(%148, %540) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %542 = "cute.add_offset"(%180, %81) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %543 = "builtin.unrealized_conversion_cast"(%541) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %544 = "builtin.unrealized_conversion_cast"(%542) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %545 = "llvm.load"(%543) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%545, %544) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %419 = "cute.add_offset"(%193, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %420 = "builtin.unrealized_conversion_cast"(%419) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %421 = "llvm.load"(%420) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %422 = "llvm.icmp"(%421, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%422) ({
          %532 = "arith.addi"(%395, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %533 = "cute.make_int_tuple"(%532) : (i64) -> !cute.int_tuple<"?{i64}">
          %534 = "cute.add_offset"(%148, %533) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %535 = "cute.add_offset"(%180, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %536 = "builtin.unrealized_conversion_cast"(%534) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %537 = "builtin.unrealized_conversion_cast"(%535) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %538 = "llvm.load"(%536) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%538, %537) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %423 = "cute.add_offset"(%193, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %424 = "builtin.unrealized_conversion_cast"(%423) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %425 = "llvm.load"(%424) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %426 = "llvm.icmp"(%425, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%426) ({
          %525 = "arith.addi"(%395, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %526 = "cute.make_int_tuple"(%525) : (i64) -> !cute.int_tuple<"?{i64}">
          %527 = "cute.add_offset"(%148, %526) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %528 = "cute.add_offset"(%180, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %529 = "builtin.unrealized_conversion_cast"(%527) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %530 = "builtin.unrealized_conversion_cast"(%528) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %531 = "llvm.load"(%529) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%531, %530) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %427 = "cute.add_offset"(%193, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %428 = "builtin.unrealized_conversion_cast"(%427) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
        %429 = "llvm.load"(%428) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %430 = "llvm.icmp"(%429, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%430) ({
          %517 = "arith.muli"(%395, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %518 = "cute.assume"(%517) : (i64) -> !cute.i64<divby 2>
          %519 = "cute.make_int_tuple"(%518) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %520 = "cute.add_offset"(%148, %519) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %521 = "cute.add_offset"(%180, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %522 = "builtin.unrealized_conversion_cast"(%520) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %523 = "builtin.unrealized_conversion_cast"(%521) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
          %524 = "llvm.load"(%522) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%524, %523) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %431 = "cute.add_offset"(%193, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %432 = "builtin.unrealized_conversion_cast"(%431) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %433 = "llvm.load"(%432) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %434 = "llvm.icmp"(%433, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%434) ({
          %509 = "arith.muli"(%395, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %510 = "arith.addi"(%509, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %511 = "cute.make_int_tuple"(%510) : (i64) -> !cute.int_tuple<"?{i64}">
          %512 = "cute.add_offset"(%148, %511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %513 = "cute.add_offset"(%180, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %514 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %515 = "builtin.unrealized_conversion_cast"(%513) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %516 = "llvm.load"(%514) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%516, %515) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %435 = "cute.add_offset"(%193, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %436 = "builtin.unrealized_conversion_cast"(%435) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %437 = "llvm.load"(%436) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %438 = "llvm.icmp"(%437, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%438) ({
          %500 = "arith.muli"(%395, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %501 = "arith.addi"(%500, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %502 = "cute.assume"(%501) : (i64) -> !cute.i64<divby 2>
          %503 = "cute.make_int_tuple"(%502) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %504 = "cute.add_offset"(%148, %503) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %505 = "cute.add_offset"(%180, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %506 = "builtin.unrealized_conversion_cast"(%504) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %507 = "builtin.unrealized_conversion_cast"(%505) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %508 = "llvm.load"(%506) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%508, %507) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %439 = "cute.add_offset"(%193, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %440 = "builtin.unrealized_conversion_cast"(%439) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %441 = "llvm.load"(%440) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %442 = "llvm.icmp"(%441, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%442) ({
          %492 = "arith.muli"(%395, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %493 = "arith.addi"(%492, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %494 = "cute.make_int_tuple"(%493) : (i64) -> !cute.int_tuple<"?{i64}">
          %495 = "cute.add_offset"(%148, %494) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %496 = "cute.add_offset"(%180, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %497 = "builtin.unrealized_conversion_cast"(%495) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %498 = "builtin.unrealized_conversion_cast"(%496) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %499 = "llvm.load"(%497) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%499, %498) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %443 = "cute.add_offset"(%193, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %444 = "builtin.unrealized_conversion_cast"(%443) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
        %445 = "llvm.load"(%444) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %446 = "llvm.icmp"(%445, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%446) ({
          %484 = "arith.muli"(%395, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %485 = "cute.assume"(%484) : (i64) -> !cute.i64<divby 3>
          %486 = "cute.make_int_tuple"(%485) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %487 = "cute.add_offset"(%148, %486) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %488 = "cute.add_offset"(%180, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %489 = "builtin.unrealized_conversion_cast"(%487) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %490 = "builtin.unrealized_conversion_cast"(%488) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
          %491 = "llvm.load"(%489) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%491, %490) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %447 = "cute.add_offset"(%193, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %448 = "builtin.unrealized_conversion_cast"(%447) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %449 = "llvm.load"(%448) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %450 = "llvm.icmp"(%449, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%450) ({
          %476 = "arith.muli"(%395, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %477 = "arith.addi"(%476, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %478 = "cute.make_int_tuple"(%477) : (i64) -> !cute.int_tuple<"?{i64}">
          %479 = "cute.add_offset"(%148, %478) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %480 = "cute.add_offset"(%180, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %481 = "builtin.unrealized_conversion_cast"(%479) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %482 = "builtin.unrealized_conversion_cast"(%480) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %483 = "llvm.load"(%481) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%483, %482) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %451 = "cute.add_offset"(%193, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %452 = "builtin.unrealized_conversion_cast"(%451) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
        %453 = "llvm.load"(%452) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %454 = "llvm.icmp"(%453, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%454) ({
          %468 = "arith.muli"(%395, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %469 = "arith.addi"(%468, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %470 = "cute.make_int_tuple"(%469) : (i64) -> !cute.int_tuple<"?{i64}">
          %471 = "cute.add_offset"(%148, %470) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %472 = "cute.add_offset"(%180, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %473 = "builtin.unrealized_conversion_cast"(%471) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %474 = "builtin.unrealized_conversion_cast"(%472) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
          %475 = "llvm.load"(%473) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%475, %474) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %455 = "cute.add_offset"(%193, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %456 = "builtin.unrealized_conversion_cast"(%455) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %457 = "llvm.load"(%456) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %458 = "llvm.icmp"(%457, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%458) ({
          %459 = "arith.muli"(%395, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %460 = "arith.addi"(%459, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
          %461 = "cute.assume"(%460) : (i64) -> !cute.i64<divby 3>
          %462 = "cute.make_int_tuple"(%461) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %463 = "cute.add_offset"(%148, %462) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %464 = "cute.add_offset"(%180, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %465 = "builtin.unrealized_conversion_cast"(%463) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %466 = "builtin.unrealized_conversion_cast"(%464) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %467 = "llvm.load"(%465) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
          "llvm.store"(%467, %466) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      "scf.for"(%95, %91, %93) ({
      ^bb0(%arg10: i32):
        %381 = "cute.memref.load_vec"(%179) : (!memref_rmem_f32_) -> vector<16xf32>
        %382 = "cute.memref.load_vec"(%181) : (!memref_rmem_f32_) -> vector<16xf32>
        %383 = "arith.addf"(%381, %382) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
        "cute.memref.store_vec"(%383, %183) : (vector<16xf32>, !memref_rmem_f32_) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %194 = "cute.get_iter"(%183) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %195 = "cute.append_to_rank"(%178, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %196 = "cute.get_scalars"(%195) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %197 = "cute.make_stride"(%196) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %198 = "cute.make_layout"(%89, %197) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %199 = "cute.append_to_rank"(%198, %90) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %200 = "cute.get_scalars"(%199) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %201 = "cute.make_stride"(%200) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %202 = "cute.make_layout"(%88, %201) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %203 = "cute.get_scalars"(%202) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %204 = "cute.make_stride"(%203) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %205 = "cute.make_layout"(%86, %204) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %206 = "cute.get_scalars"(%205) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %207 = "builtin.unrealized_conversion_cast"(%193) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %208 = "llvm.load"(%207) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %209 = "llvm.icmp"(%208, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%209) ({
        %378 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %379 = "builtin.unrealized_conversion_cast"(%176) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %380 = "llvm.load"(%378) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%380, %379) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %210 = "cute.add_offset"(%193, %87) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %211 = "builtin.unrealized_conversion_cast"(%210) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %212 = "llvm.load"(%211) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %213 = "llvm.icmp"(%212, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%213) ({
        %373 = "cute.add_offset"(%194, %87) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %374 = "cute.add_offset"(%176, %87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %375 = "builtin.unrealized_conversion_cast"(%373) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %376 = "builtin.unrealized_conversion_cast"(%374) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %377 = "llvm.load"(%375) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%377, %376) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %214 = "cute.add_offset"(%193, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %215 = "builtin.unrealized_conversion_cast"(%214) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %216 = "llvm.load"(%215) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %217 = "llvm.icmp"(%216, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%217) ({
        %368 = "cute.add_offset"(%194, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %369 = "cute.add_offset"(%176, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %370 = "builtin.unrealized_conversion_cast"(%368) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %371 = "builtin.unrealized_conversion_cast"(%369) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %372 = "llvm.load"(%370) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%372, %371) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %218 = "cute.add_offset"(%193, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %219 = "builtin.unrealized_conversion_cast"(%218) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %220 = "llvm.load"(%219) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %221 = "llvm.icmp"(%220, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%221) ({
        %363 = "cute.add_offset"(%194, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %364 = "cute.add_offset"(%176, %83) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %365 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %366 = "builtin.unrealized_conversion_cast"(%364) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %367 = "llvm.load"(%365) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%367, %366) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %222 = "cute.add_offset"(%193, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %223 = "builtin.unrealized_conversion_cast"(%222) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %224 = "llvm.load"(%223) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %225 = "llvm.icmp"(%224, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%225) ({
        %357 = "cute.add_offset"(%194, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %358 = "cute.make_int_tuple"(%206) : (i64) -> !cute.int_tuple<"?{i64}">
        %359 = "cute.add_offset"(%176, %358) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %360 = "builtin.unrealized_conversion_cast"(%357) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %361 = "builtin.unrealized_conversion_cast"(%359) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %362 = "llvm.load"(%360) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%362, %361) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %226 = "cute.add_offset"(%193, %81) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %227 = "builtin.unrealized_conversion_cast"(%226) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %228 = "llvm.load"(%227) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %229 = "llvm.icmp"(%228, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%229) ({
        %350 = "cute.add_offset"(%194, %81) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %351 = "arith.addi"(%206, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %352 = "cute.make_int_tuple"(%351) : (i64) -> !cute.int_tuple<"?{i64}">
        %353 = "cute.add_offset"(%176, %352) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %354 = "builtin.unrealized_conversion_cast"(%350) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %355 = "builtin.unrealized_conversion_cast"(%353) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %356 = "llvm.load"(%354) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%356, %355) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %230 = "cute.add_offset"(%193, %79) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %231 = "builtin.unrealized_conversion_cast"(%230) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %232 = "llvm.load"(%231) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %233 = "llvm.icmp"(%232, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%233) ({
        %343 = "cute.add_offset"(%194, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %344 = "arith.addi"(%206, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %345 = "cute.make_int_tuple"(%344) : (i64) -> !cute.int_tuple<"?{i64}">
        %346 = "cute.add_offset"(%176, %345) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %347 = "builtin.unrealized_conversion_cast"(%343) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %348 = "builtin.unrealized_conversion_cast"(%346) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %349 = "llvm.load"(%347) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%349, %348) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %234 = "cute.add_offset"(%193, %77) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %235 = "builtin.unrealized_conversion_cast"(%234) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %236 = "llvm.load"(%235) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %237 = "llvm.icmp"(%236, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%237) ({
        %336 = "cute.add_offset"(%194, %77) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %337 = "arith.addi"(%206, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %338 = "cute.make_int_tuple"(%337) : (i64) -> !cute.int_tuple<"?{i64}">
        %339 = "cute.add_offset"(%176, %338) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %340 = "builtin.unrealized_conversion_cast"(%336) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %341 = "builtin.unrealized_conversion_cast"(%339) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %342 = "llvm.load"(%340) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%342, %341) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %238 = "cute.add_offset"(%193, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %239 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %240 = "llvm.load"(%239) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %241 = "llvm.icmp"(%240, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%241) ({
        %328 = "cute.add_offset"(%194, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %329 = "arith.muli"(%206, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %330 = "cute.assume"(%329) : (i64) -> !cute.i64<divby 2>
        %331 = "cute.make_int_tuple"(%330) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %332 = "cute.add_offset"(%176, %331) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %333 = "builtin.unrealized_conversion_cast"(%328) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %334 = "builtin.unrealized_conversion_cast"(%332) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %335 = "llvm.load"(%333) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%335, %334) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %242 = "cute.add_offset"(%193, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %243 = "builtin.unrealized_conversion_cast"(%242) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %244 = "llvm.load"(%243) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %245 = "llvm.icmp"(%244, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%245) ({
        %320 = "cute.add_offset"(%194, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %321 = "arith.muli"(%206, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %322 = "arith.addi"(%321, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %323 = "cute.make_int_tuple"(%322) : (i64) -> !cute.int_tuple<"?{i64}">
        %324 = "cute.add_offset"(%176, %323) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %325 = "builtin.unrealized_conversion_cast"(%320) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %326 = "builtin.unrealized_conversion_cast"(%324) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %327 = "llvm.load"(%325) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%327, %326) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %246 = "cute.add_offset"(%193, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %247 = "builtin.unrealized_conversion_cast"(%246) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %248 = "llvm.load"(%247) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %249 = "llvm.icmp"(%248, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%249) ({
        %311 = "cute.add_offset"(%194, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %312 = "arith.muli"(%206, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %313 = "arith.addi"(%312, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %314 = "cute.assume"(%313) : (i64) -> !cute.i64<divby 2>
        %315 = "cute.make_int_tuple"(%314) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %316 = "cute.add_offset"(%176, %315) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %317 = "builtin.unrealized_conversion_cast"(%311) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %318 = "builtin.unrealized_conversion_cast"(%316) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %319 = "llvm.load"(%317) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%319, %318) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %250 = "cute.add_offset"(%193, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %251 = "builtin.unrealized_conversion_cast"(%250) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %252 = "llvm.load"(%251) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %253 = "llvm.icmp"(%252, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%253) ({
        %303 = "cute.add_offset"(%194, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %304 = "arith.muli"(%206, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %305 = "arith.addi"(%304, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %306 = "cute.make_int_tuple"(%305) : (i64) -> !cute.int_tuple<"?{i64}">
        %307 = "cute.add_offset"(%176, %306) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %308 = "builtin.unrealized_conversion_cast"(%303) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %309 = "builtin.unrealized_conversion_cast"(%307) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %310 = "llvm.load"(%308) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%310, %309) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %254 = "cute.add_offset"(%193, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %255 = "builtin.unrealized_conversion_cast"(%254) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %256 = "llvm.load"(%255) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %257 = "llvm.icmp"(%256, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%257) ({
        %295 = "cute.add_offset"(%194, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %296 = "arith.muli"(%206, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %297 = "cute.assume"(%296) : (i64) -> !cute.i64<divby 3>
        %298 = "cute.make_int_tuple"(%297) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %299 = "cute.add_offset"(%176, %298) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %300 = "builtin.unrealized_conversion_cast"(%295) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %301 = "builtin.unrealized_conversion_cast"(%299) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %302 = "llvm.load"(%300) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%302, %301) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %258 = "cute.add_offset"(%193, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %259 = "builtin.unrealized_conversion_cast"(%258) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %260 = "llvm.load"(%259) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %261 = "llvm.icmp"(%260, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%261) ({
        %287 = "cute.add_offset"(%194, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %288 = "arith.muli"(%206, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %289 = "arith.addi"(%288, %80) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %290 = "cute.make_int_tuple"(%289) : (i64) -> !cute.int_tuple<"?{i64}">
        %291 = "cute.add_offset"(%176, %290) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %292 = "builtin.unrealized_conversion_cast"(%287) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %293 = "builtin.unrealized_conversion_cast"(%291) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %294 = "llvm.load"(%292) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%294, %293) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %262 = "cute.add_offset"(%193, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %263 = "builtin.unrealized_conversion_cast"(%262) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %264 = "llvm.load"(%263) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %265 = "llvm.icmp"(%264, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%265) ({
        %279 = "cute.add_offset"(%194, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %280 = "arith.muli"(%206, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %281 = "arith.addi"(%280, %78) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %282 = "cute.make_int_tuple"(%281) : (i64) -> !cute.int_tuple<"?{i64}">
        %283 = "cute.add_offset"(%176, %282) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %284 = "builtin.unrealized_conversion_cast"(%279) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %285 = "builtin.unrealized_conversion_cast"(%283) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %286 = "llvm.load"(%284) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%286, %285) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %266 = "cute.add_offset"(%193, %68) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %267 = "builtin.unrealized_conversion_cast"(%266) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %268 = "llvm.load"(%267) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %269 = "llvm.icmp"(%268, %85) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%269) ({
        %270 = "cute.add_offset"(%194, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %271 = "arith.muli"(%206, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %272 = "arith.addi"(%271, %76) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %273 = "cute.assume"(%272) : (i64) -> !cute.i64<divby 3>
        %274 = "cute.make_int_tuple"(%273) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %275 = "cute.add_offset"(%176, %274) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %276 = "builtin.unrealized_conversion_cast"(%270) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %277 = "builtin.unrealized_conversion_cast"(%275) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %278 = "llvm.load"(%276) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%278, %277) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_f32_1, !memref_gmem_f32_1, !cuda.stream) -> i32, sym_name = "cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False"}> ({
  ^bb0(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1, %arg3: !cuda.stream):
    %0 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 1 : i32}> : () -> i32
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
    %41 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %42 = "cute.get_shape"(%41) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %43:2 = "cute.get_leaves"(%42) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %44 = "cute.to_int_tuple"(%43#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %45 = "cute.to_int_tuple"(%43#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %46 = "cute.make_shape"(%44, %45) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %47 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
    %48 = "cute.make_layout"(%46, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?):(1@0,1@1)">
    %49:2 = "cute.get_scalars"(%48) <{only_dynamic}> : (!cute.layout<"(?,?):(1@0,1@1)">) -> (i32, i32)
    %50 = "arith.ceildivsi"(%49#0, %7) : (i32, i32) -> i32
    %51 = "arith.ceildivsi"(%49#1, %5) : (i32, i32) -> i32
    %52 = "cute.make_shape"(%50, %51) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %53 = "cute.make_layout"(%52, %3) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((16,128),(?,?))">, !cute.stride<"((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %54 = "cute.make_view"(%47, %53) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %55 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?):(?{i64},1)">
    %56 = "cute.get_shape"(%55) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %57:2 = "cute.get_leaves"(%56) : (!cute.shape<"(?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">)
    %58 = "cute.to_int_tuple"(%57#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %59 = "cute.get_scalars"(%58) : (!cute.int_tuple<"?">) -> i32
    %60 = "cute.to_int_tuple"(%57#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %61 = "cute.get_scalars"(%60) : (!cute.int_tuple<"?">) -> i32
    %62 = "cute.size"(%39) <{mode = array<i32: 1>}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %63 = "cute.get_leaves"(%62) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %64 = "cute.get_scalars"(%63) : (!cute.int_tuple<"?">) -> i32
    %65 = "cuda.launch_cfg.create"(%5, %1, %1, %0, %64, %1, %1, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%65, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%65, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %66 = "cuda.launch_ex"(%65, %18, %29, %40, %54, %59, %61) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %67 = "cuda.cast"(%66) : (!cuda.result) -> i32
    "cuda.return_if_error"(%67) : (i32) -> ()
    "func.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
