!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> (), sym_name = "kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0"}> ({
    ^bb0(%arg3: !memref_gmem_f32_, %arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_, %arg6: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg7: i32, %arg8: i32):
      %69 = "cute.static"() : () -> !cute.int_tuple<"15">
      %70 = "cute.static"() : () -> !cute.int_tuple<"14">
      %71 = "cute.static"() : () -> !cute.int_tuple<"13">
      %72 = "cute.static"() : () -> !cute.int_tuple<"12">
      %73 = "cute.static"() : () -> !cute.int_tuple<"11">
      %74 = "cute.static"() : () -> !cute.int_tuple<"10">
      %75 = "cute.static"() : () -> !cute.int_tuple<"9">
      %76 = "cute.static"() : () -> !cute.int_tuple<"8">
      %77 = "arith.constant"() <{value = 3 : i64}> : () -> i64
      %78 = "cute.static"() : () -> !cute.int_tuple<"7">
      %79 = "arith.constant"() <{value = 2 : i64}> : () -> i64
      %80 = "cute.static"() : () -> !cute.int_tuple<"6">
      %81 = "arith.constant"() <{value = 1 : i64}> : () -> i64
      %82 = "cute.static"() : () -> !cute.int_tuple<"5">
      %83 = "cute.static"() : () -> !cute.int_tuple<"4">
      %84 = "cute.static"() : () -> !cute.int_tuple<"3">
      %85 = "cute.static"() : () -> !cute.int_tuple<"2">
      %86 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %87 = "cute.static"() : () -> !cute.shape<"((1,(4,4)))">
      %88 = "cute.static"() : () -> !cute.int_tuple<"1">
      %89 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %90 = "cute.static"() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %91 = "cute.static"() : () -> !cute.layout<"1:0">
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
      %104 = "cute.get_layout"(%arg3) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %105:4 = "cute.get_scalars"(%104) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %106 = "cute.make_stride"(%105#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %107 = "cute.make_layout"(%100, %106) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %108 = "cute.crd2idx"(%103, %104) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %109 = "cute.get_iter"(%arg3) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %110 = "cute.add_offset"(%109, %108) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %111 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %112 = "cute.get_layout"(%arg4) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %113:4 = "cute.get_scalars"(%112) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %114 = "cute.make_stride"(%113#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %115 = "cute.make_layout"(%100, %114) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %116 = "cute.crd2idx"(%111, %112) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %117 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %118 = "cute.add_offset"(%117, %116) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %119 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %120 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_) -> !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %121:4 = "cute.get_scalars"(%120) <{only_dynamic}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> (i32, i32, i64, i64)
      %122 = "cute.make_stride"(%121#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %123 = "cute.make_layout"(%100, %122) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(16,128)">, !cute.stride<"(?{i64},1)">) -> !cute.layout<"(16,128):(?{i64},1)">
      %124 = "cute.crd2idx"(%119, %120) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %125 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %126 = "cute.add_offset"(%125, %124) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %127 = "cute.make_coord"(%102) : (i32) -> !cute.coord<"((_,_),?)">
      %128 = "cute.get_layout"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %129 = "cute.crd2idx"(%127, %128) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %130 = "cute.get_iter"(%arg6) : (!cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.arith_tuple_iter<"(0,0)">
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
      %184 = "cute.get_iter"(%183) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %185 = "arith.divsi"(%101, %98) : (i32, i32) -> i32
      %186 = "arith.remsi"(%101, %98) : (i32, i32) -> i32
      %187 = "arith.muli"(%186, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %188 = "arith.muli"(%185, %97) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %189 = "cute.assume"(%188) : (i32) -> !cute.i32<divby 4>
      %190 = "cute.assume"(%187) : (i32) -> !cute.i32<divby 4>
      %191 = "cute.make_int_tuple"(%189, %190) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %192 = "cute.add_offset"(%131, %191) : (!cute.arith_tuple_iter<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %193 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      "scf.for"(%95, %94, %93) ({
      ^bb0(%arg9: i32):
        %756 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        %757 = "cute.crd2idx"(%756, %92) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %758 = "cute.add_offset"(%192, %757) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %759 = "cute.deref_arith_tuple_iter"(%758) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %760:2 = "cute.get_leaves"(%759) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %761 = "cute.make_coord"(%760#0, %760#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %762 = "cute.make_coord"(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(?,?)">
        %763:2 = "cute.get_scalars"(%761) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %764:2 = "cute.get_scalars"(%762) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %765 = "arith.cmpi"(%763#0, %764#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %766 = "arith.cmpi"(%763#1, %764#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %767 = "arith.andi"(%765, %766) : (i1, i1) -> i1
        %768 = "arith.extui"(%767) : (i1) -> i8
        %769 = "cute.make_coord"(%arg9) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%193, %769, %768) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %194 = "cute.get_iter"(%193) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %195 = "cute.append_to_rank"(%150, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %196 = "cute.get_scalars"(%195) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %197 = "cute.make_stride"(%196) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %198 = "cute.make_layout"(%90, %197) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %199 = "cute.append_to_rank"(%198, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %200 = "cute.get_scalars"(%199) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %201 = "cute.make_stride"(%200) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %202 = "cute.make_layout"(%89, %201) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %203 = "cute.get_scalars"(%202) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %204 = "cute.make_stride"(%203) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %205 = "cute.make_layout"(%87, %204) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %206 = "cute.get_scalars"(%205) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %207 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %208 = "llvm.load"(%207) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %209 = "llvm.icmp"(%208, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%209) ({
        %753 = "builtin.unrealized_conversion_cast"(%148) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %754 = "builtin.unrealized_conversion_cast"(%180) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %755 = "llvm.load"(%753) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%755, %754) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %210 = "cute.add_offset"(%194, %88) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %211 = "builtin.unrealized_conversion_cast"(%210) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %212 = "llvm.load"(%211) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %213 = "llvm.icmp"(%212, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%213) ({
        %748 = "cute.add_offset"(%148, %88) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %749 = "cute.add_offset"(%180, %88) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %750 = "builtin.unrealized_conversion_cast"(%748) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %751 = "builtin.unrealized_conversion_cast"(%749) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %752 = "llvm.load"(%750) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%752, %751) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %214 = "cute.add_offset"(%194, %85) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %215 = "builtin.unrealized_conversion_cast"(%214) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %216 = "llvm.load"(%215) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %217 = "llvm.icmp"(%216, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%217) ({
        %743 = "cute.add_offset"(%148, %85) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %744 = "cute.add_offset"(%180, %85) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %745 = "builtin.unrealized_conversion_cast"(%743) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %746 = "builtin.unrealized_conversion_cast"(%744) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %747 = "llvm.load"(%745) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%747, %746) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %218 = "cute.add_offset"(%194, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %219 = "builtin.unrealized_conversion_cast"(%218) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %220 = "llvm.load"(%219) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %221 = "llvm.icmp"(%220, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%221) ({
        %738 = "cute.add_offset"(%148, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %739 = "cute.add_offset"(%180, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %740 = "builtin.unrealized_conversion_cast"(%738) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %741 = "builtin.unrealized_conversion_cast"(%739) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %742 = "llvm.load"(%740) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%742, %741) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %222 = "cute.add_offset"(%194, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %223 = "builtin.unrealized_conversion_cast"(%222) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %224 = "llvm.load"(%223) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %225 = "llvm.icmp"(%224, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%225) ({
        %732 = "cute.make_int_tuple"(%206) : (i64) -> !cute.int_tuple<"?{i64}">
        %733 = "cute.add_offset"(%148, %732) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %734 = "cute.add_offset"(%180, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %735 = "builtin.unrealized_conversion_cast"(%733) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %736 = "builtin.unrealized_conversion_cast"(%734) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %737 = "llvm.load"(%735) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%737, %736) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %226 = "cute.add_offset"(%194, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %227 = "builtin.unrealized_conversion_cast"(%226) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %228 = "llvm.load"(%227) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %229 = "llvm.icmp"(%228, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%229) ({
        %725 = "arith.addi"(%206, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %726 = "cute.make_int_tuple"(%725) : (i64) -> !cute.int_tuple<"?{i64}">
        %727 = "cute.add_offset"(%148, %726) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %728 = "cute.add_offset"(%180, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %729 = "builtin.unrealized_conversion_cast"(%727) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %730 = "builtin.unrealized_conversion_cast"(%728) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %731 = "llvm.load"(%729) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%731, %730) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %230 = "cute.add_offset"(%194, %80) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %231 = "builtin.unrealized_conversion_cast"(%230) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %232 = "llvm.load"(%231) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %233 = "llvm.icmp"(%232, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%233) ({
        %718 = "arith.addi"(%206, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %719 = "cute.make_int_tuple"(%718) : (i64) -> !cute.int_tuple<"?{i64}">
        %720 = "cute.add_offset"(%148, %719) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %721 = "cute.add_offset"(%180, %80) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %722 = "builtin.unrealized_conversion_cast"(%720) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %723 = "builtin.unrealized_conversion_cast"(%721) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %724 = "llvm.load"(%722) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%724, %723) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %234 = "cute.add_offset"(%194, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %235 = "builtin.unrealized_conversion_cast"(%234) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %236 = "llvm.load"(%235) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %237 = "llvm.icmp"(%236, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%237) ({
        %711 = "arith.addi"(%206, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %712 = "cute.make_int_tuple"(%711) : (i64) -> !cute.int_tuple<"?{i64}">
        %713 = "cute.add_offset"(%148, %712) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %714 = "cute.add_offset"(%180, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %715 = "builtin.unrealized_conversion_cast"(%713) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %716 = "builtin.unrealized_conversion_cast"(%714) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %717 = "llvm.load"(%715) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%717, %716) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %238 = "cute.add_offset"(%194, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %239 = "builtin.unrealized_conversion_cast"(%238) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %240 = "llvm.load"(%239) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %241 = "llvm.icmp"(%240, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%241) ({
        %703 = "arith.muli"(%206, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %704 = "cute.assume"(%703) : (i64) -> !cute.i64<divby 2>
        %705 = "cute.make_int_tuple"(%704) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %706 = "cute.add_offset"(%148, %705) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %707 = "cute.add_offset"(%180, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %708 = "builtin.unrealized_conversion_cast"(%706) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %709 = "builtin.unrealized_conversion_cast"(%707) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %710 = "llvm.load"(%708) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%710, %709) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %242 = "cute.add_offset"(%194, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %243 = "builtin.unrealized_conversion_cast"(%242) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %244 = "llvm.load"(%243) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %245 = "llvm.icmp"(%244, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%245) ({
        %695 = "arith.muli"(%206, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %696 = "arith.addi"(%695, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %697 = "cute.make_int_tuple"(%696) : (i64) -> !cute.int_tuple<"?{i64}">
        %698 = "cute.add_offset"(%148, %697) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %699 = "cute.add_offset"(%180, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %700 = "builtin.unrealized_conversion_cast"(%698) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %701 = "builtin.unrealized_conversion_cast"(%699) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %702 = "llvm.load"(%700) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%702, %701) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %246 = "cute.add_offset"(%194, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %247 = "builtin.unrealized_conversion_cast"(%246) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %248 = "llvm.load"(%247) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %249 = "llvm.icmp"(%248, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%249) ({
        %686 = "arith.muli"(%206, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %687 = "arith.addi"(%686, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %688 = "cute.assume"(%687) : (i64) -> !cute.i64<divby 2>
        %689 = "cute.make_int_tuple"(%688) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %690 = "cute.add_offset"(%148, %689) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %691 = "cute.add_offset"(%180, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %692 = "builtin.unrealized_conversion_cast"(%690) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %693 = "builtin.unrealized_conversion_cast"(%691) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %694 = "llvm.load"(%692) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%694, %693) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %250 = "cute.add_offset"(%194, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %251 = "builtin.unrealized_conversion_cast"(%250) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %252 = "llvm.load"(%251) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %253 = "llvm.icmp"(%252, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%253) ({
        %678 = "arith.muli"(%206, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %679 = "arith.addi"(%678, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %680 = "cute.make_int_tuple"(%679) : (i64) -> !cute.int_tuple<"?{i64}">
        %681 = "cute.add_offset"(%148, %680) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %682 = "cute.add_offset"(%180, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %683 = "builtin.unrealized_conversion_cast"(%681) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %684 = "builtin.unrealized_conversion_cast"(%682) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %685 = "llvm.load"(%683) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%685, %684) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %254 = "cute.add_offset"(%194, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %255 = "builtin.unrealized_conversion_cast"(%254) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %256 = "llvm.load"(%255) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %257 = "llvm.icmp"(%256, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%257) ({
        %670 = "arith.muli"(%206, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %671 = "cute.assume"(%670) : (i64) -> !cute.i64<divby 3>
        %672 = "cute.make_int_tuple"(%671) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %673 = "cute.add_offset"(%148, %672) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %674 = "cute.add_offset"(%180, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %675 = "builtin.unrealized_conversion_cast"(%673) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %676 = "builtin.unrealized_conversion_cast"(%674) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %677 = "llvm.load"(%675) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%677, %676) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %258 = "cute.add_offset"(%194, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %259 = "builtin.unrealized_conversion_cast"(%258) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %260 = "llvm.load"(%259) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %261 = "llvm.icmp"(%260, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%261) ({
        %662 = "arith.muli"(%206, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %663 = "arith.addi"(%662, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %664 = "cute.make_int_tuple"(%663) : (i64) -> !cute.int_tuple<"?{i64}">
        %665 = "cute.add_offset"(%148, %664) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %666 = "cute.add_offset"(%180, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %667 = "builtin.unrealized_conversion_cast"(%665) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %668 = "builtin.unrealized_conversion_cast"(%666) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %669 = "llvm.load"(%667) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%669, %668) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %262 = "cute.add_offset"(%194, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %263 = "builtin.unrealized_conversion_cast"(%262) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %264 = "llvm.load"(%263) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %265 = "llvm.icmp"(%264, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%265) ({
        %654 = "arith.muli"(%206, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %655 = "arith.addi"(%654, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %656 = "cute.make_int_tuple"(%655) : (i64) -> !cute.int_tuple<"?{i64}">
        %657 = "cute.add_offset"(%148, %656) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %658 = "cute.add_offset"(%180, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %659 = "builtin.unrealized_conversion_cast"(%657) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %660 = "builtin.unrealized_conversion_cast"(%658) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %661 = "llvm.load"(%659) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%661, %660) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %266 = "cute.add_offset"(%194, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %267 = "builtin.unrealized_conversion_cast"(%266) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %268 = "llvm.load"(%267) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %269 = "llvm.icmp"(%268, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%269) ({
        %645 = "arith.muli"(%206, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %646 = "arith.addi"(%645, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %647 = "cute.assume"(%646) : (i64) -> !cute.i64<divby 3>
        %648 = "cute.make_int_tuple"(%647) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %649 = "cute.add_offset"(%148, %648) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %650 = "cute.add_offset"(%180, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %651 = "builtin.unrealized_conversion_cast"(%649) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %652 = "builtin.unrealized_conversion_cast"(%650) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %653 = "llvm.load"(%651) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%653, %652) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %270 = "cute.append_to_rank"(%164, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %271 = "cute.get_scalars"(%270) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %272 = "cute.make_stride"(%271) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %273 = "cute.make_layout"(%90, %272) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %274 = "cute.append_to_rank"(%273, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %275 = "cute.get_scalars"(%274) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %276 = "cute.make_stride"(%275) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %277 = "cute.make_layout"(%89, %276) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %278 = "cute.get_scalars"(%277) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %279 = "cute.make_stride"(%278) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %280 = "cute.make_layout"(%87, %279) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %281 = "cute.get_scalars"(%280) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %282 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %283 = "llvm.load"(%282) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %284 = "llvm.icmp"(%283, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%284) ({
        %642 = "builtin.unrealized_conversion_cast"(%162) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %643 = "builtin.unrealized_conversion_cast"(%182) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %644 = "llvm.load"(%642) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%644, %643) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %285 = "cute.add_offset"(%194, %88) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %286 = "builtin.unrealized_conversion_cast"(%285) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %287 = "llvm.load"(%286) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %288 = "llvm.icmp"(%287, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%288) ({
        %637 = "cute.add_offset"(%162, %88) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %638 = "cute.add_offset"(%182, %88) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %639 = "builtin.unrealized_conversion_cast"(%637) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %640 = "builtin.unrealized_conversion_cast"(%638) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %641 = "llvm.load"(%639) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%641, %640) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %289 = "cute.add_offset"(%194, %85) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %290 = "builtin.unrealized_conversion_cast"(%289) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %291 = "llvm.load"(%290) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %292 = "llvm.icmp"(%291, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%292) ({
        %632 = "cute.add_offset"(%162, %85) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %633 = "cute.add_offset"(%182, %85) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %634 = "builtin.unrealized_conversion_cast"(%632) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %635 = "builtin.unrealized_conversion_cast"(%633) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %636 = "llvm.load"(%634) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%636, %635) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %293 = "cute.add_offset"(%194, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %294 = "builtin.unrealized_conversion_cast"(%293) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %295 = "llvm.load"(%294) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %296 = "llvm.icmp"(%295, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%296) ({
        %627 = "cute.add_offset"(%162, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %628 = "cute.add_offset"(%182, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %629 = "builtin.unrealized_conversion_cast"(%627) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %630 = "builtin.unrealized_conversion_cast"(%628) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %631 = "llvm.load"(%629) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%631, %630) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %297 = "cute.add_offset"(%194, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %298 = "builtin.unrealized_conversion_cast"(%297) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %299 = "llvm.load"(%298) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %300 = "llvm.icmp"(%299, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%300) ({
        %621 = "cute.make_int_tuple"(%281) : (i64) -> !cute.int_tuple<"?{i64}">
        %622 = "cute.add_offset"(%162, %621) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %623 = "cute.add_offset"(%182, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %624 = "builtin.unrealized_conversion_cast"(%622) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %625 = "builtin.unrealized_conversion_cast"(%623) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %626 = "llvm.load"(%624) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%626, %625) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %301 = "cute.add_offset"(%194, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %302 = "builtin.unrealized_conversion_cast"(%301) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %303 = "llvm.load"(%302) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %304 = "llvm.icmp"(%303, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%304) ({
        %614 = "arith.addi"(%281, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %615 = "cute.make_int_tuple"(%614) : (i64) -> !cute.int_tuple<"?{i64}">
        %616 = "cute.add_offset"(%162, %615) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %617 = "cute.add_offset"(%182, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %618 = "builtin.unrealized_conversion_cast"(%616) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %619 = "builtin.unrealized_conversion_cast"(%617) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %620 = "llvm.load"(%618) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%620, %619) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %305 = "cute.add_offset"(%194, %80) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %306 = "builtin.unrealized_conversion_cast"(%305) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %307 = "llvm.load"(%306) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %308 = "llvm.icmp"(%307, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%308) ({
        %607 = "arith.addi"(%281, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %608 = "cute.make_int_tuple"(%607) : (i64) -> !cute.int_tuple<"?{i64}">
        %609 = "cute.add_offset"(%162, %608) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %610 = "cute.add_offset"(%182, %80) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %611 = "builtin.unrealized_conversion_cast"(%609) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %612 = "builtin.unrealized_conversion_cast"(%610) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %613 = "llvm.load"(%611) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%613, %612) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %309 = "cute.add_offset"(%194, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %310 = "builtin.unrealized_conversion_cast"(%309) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %311 = "llvm.load"(%310) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %312 = "llvm.icmp"(%311, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%312) ({
        %600 = "arith.addi"(%281, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %601 = "cute.make_int_tuple"(%600) : (i64) -> !cute.int_tuple<"?{i64}">
        %602 = "cute.add_offset"(%162, %601) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %603 = "cute.add_offset"(%182, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %604 = "builtin.unrealized_conversion_cast"(%602) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %605 = "builtin.unrealized_conversion_cast"(%603) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %606 = "llvm.load"(%604) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%606, %605) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %313 = "cute.add_offset"(%194, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %314 = "builtin.unrealized_conversion_cast"(%313) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %315 = "llvm.load"(%314) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %316 = "llvm.icmp"(%315, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%316) ({
        %592 = "arith.muli"(%281, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %593 = "cute.assume"(%592) : (i64) -> !cute.i64<divby 2>
        %594 = "cute.make_int_tuple"(%593) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %595 = "cute.add_offset"(%162, %594) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %596 = "cute.add_offset"(%182, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %597 = "builtin.unrealized_conversion_cast"(%595) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %598 = "builtin.unrealized_conversion_cast"(%596) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %599 = "llvm.load"(%597) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%599, %598) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %317 = "cute.add_offset"(%194, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %318 = "builtin.unrealized_conversion_cast"(%317) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %319 = "llvm.load"(%318) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %320 = "llvm.icmp"(%319, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%320) ({
        %584 = "arith.muli"(%281, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %585 = "arith.addi"(%584, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %586 = "cute.make_int_tuple"(%585) : (i64) -> !cute.int_tuple<"?{i64}">
        %587 = "cute.add_offset"(%162, %586) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %588 = "cute.add_offset"(%182, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %589 = "builtin.unrealized_conversion_cast"(%587) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %590 = "builtin.unrealized_conversion_cast"(%588) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %591 = "llvm.load"(%589) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%591, %590) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %321 = "cute.add_offset"(%194, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %322 = "builtin.unrealized_conversion_cast"(%321) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %323 = "llvm.load"(%322) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %324 = "llvm.icmp"(%323, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%324) ({
        %575 = "arith.muli"(%281, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %576 = "arith.addi"(%575, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %577 = "cute.assume"(%576) : (i64) -> !cute.i64<divby 2>
        %578 = "cute.make_int_tuple"(%577) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %579 = "cute.add_offset"(%162, %578) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %580 = "cute.add_offset"(%182, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %581 = "builtin.unrealized_conversion_cast"(%579) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %582 = "builtin.unrealized_conversion_cast"(%580) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %583 = "llvm.load"(%581) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%583, %582) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %325 = "cute.add_offset"(%194, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %326 = "builtin.unrealized_conversion_cast"(%325) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %327 = "llvm.load"(%326) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %328 = "llvm.icmp"(%327, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%328) ({
        %567 = "arith.muli"(%281, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %568 = "arith.addi"(%567, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %569 = "cute.make_int_tuple"(%568) : (i64) -> !cute.int_tuple<"?{i64}">
        %570 = "cute.add_offset"(%162, %569) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %571 = "cute.add_offset"(%182, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %572 = "builtin.unrealized_conversion_cast"(%570) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %573 = "builtin.unrealized_conversion_cast"(%571) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %574 = "llvm.load"(%572) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%574, %573) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %329 = "cute.add_offset"(%194, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %330 = "builtin.unrealized_conversion_cast"(%329) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %331 = "llvm.load"(%330) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %332 = "llvm.icmp"(%331, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%332) ({
        %559 = "arith.muli"(%281, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %560 = "cute.assume"(%559) : (i64) -> !cute.i64<divby 3>
        %561 = "cute.make_int_tuple"(%560) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %562 = "cute.add_offset"(%162, %561) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %563 = "cute.add_offset"(%182, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %564 = "builtin.unrealized_conversion_cast"(%562) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %565 = "builtin.unrealized_conversion_cast"(%563) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %566 = "llvm.load"(%564) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%566, %565) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %333 = "cute.add_offset"(%194, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %334 = "builtin.unrealized_conversion_cast"(%333) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %335 = "llvm.load"(%334) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %336 = "llvm.icmp"(%335, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%336) ({
        %551 = "arith.muli"(%281, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %552 = "arith.addi"(%551, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %553 = "cute.make_int_tuple"(%552) : (i64) -> !cute.int_tuple<"?{i64}">
        %554 = "cute.add_offset"(%162, %553) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %555 = "cute.add_offset"(%182, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %556 = "builtin.unrealized_conversion_cast"(%554) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %557 = "builtin.unrealized_conversion_cast"(%555) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %558 = "llvm.load"(%556) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%558, %557) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %337 = "cute.add_offset"(%194, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %338 = "builtin.unrealized_conversion_cast"(%337) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %339 = "llvm.load"(%338) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %340 = "llvm.icmp"(%339, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%340) ({
        %543 = "arith.muli"(%281, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %544 = "arith.addi"(%543, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %545 = "cute.make_int_tuple"(%544) : (i64) -> !cute.int_tuple<"?{i64}">
        %546 = "cute.add_offset"(%162, %545) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %547 = "cute.add_offset"(%182, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %548 = "builtin.unrealized_conversion_cast"(%546) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %549 = "builtin.unrealized_conversion_cast"(%547) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %550 = "llvm.load"(%548) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%550, %549) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %341 = "cute.add_offset"(%194, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %342 = "builtin.unrealized_conversion_cast"(%341) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %343 = "llvm.load"(%342) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %344 = "llvm.icmp"(%343, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%344) ({
        %534 = "arith.muli"(%281, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %535 = "arith.addi"(%534, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %536 = "cute.assume"(%535) : (i64) -> !cute.i64<divby 3>
        %537 = "cute.make_int_tuple"(%536) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %538 = "cute.add_offset"(%162, %537) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %539 = "cute.add_offset"(%182, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %540 = "builtin.unrealized_conversion_cast"(%538) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %541 = "builtin.unrealized_conversion_cast"(%539) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %542 = "llvm.load"(%540) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%542, %541) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %345 = "cute.memref.load_vec"(%179) : (!memref_rmem_f32_) -> vector<16xf32>
      %346 = "cute.memref.load_vec"(%181) : (!memref_rmem_f32_) -> vector<16xf32>
      %347 = "arith.addf"(%345, %346) <{fastmath = #arith.fastmath<none>}> : (vector<16xf32>, vector<16xf32>) -> vector<16xf32>
      "cute.memref.store_vec"(%347, %183) : (vector<16xf32>, !memref_rmem_f32_) -> ()
      %348 = "cute.append_to_rank"(%178, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %349 = "cute.get_scalars"(%348) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> i64
      %350 = "cute.make_stride"(%349) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %351 = "cute.make_layout"(%90, %350) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),(1,1))">, !cute.stride<"((0,(1,?{i64})),(0,0))">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %352 = "cute.append_to_rank"(%351, %91) <{rank = 2 : si32}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %353 = "cute.get_scalars"(%352) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> i64
      %354 = "cute.make_stride"(%353) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %355 = "cute.make_layout"(%89, %354) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)),((1,1)))">, !cute.stride<"((0,(1,?{i64})),((0,0)))">) -> !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %356 = "cute.get_scalars"(%355) <{only_dynamic}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> i64
      %357 = "cute.make_stride"(%356) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %358 = "cute.make_layout"(%87, %357) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,(4,4)))">, !cute.stride<"((0,(1,?{i64})))">) -> !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %359 = "cute.get_scalars"(%358) <{only_dynamic}> : (!cute.layout<"((1,(4,4))):((0,(1,?{i64})))">) -> i64
      %360 = "builtin.unrealized_conversion_cast"(%194) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %361 = "llvm.load"(%360) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %362 = "llvm.icmp"(%361, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%362) ({
        %531 = "builtin.unrealized_conversion_cast"(%184) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %532 = "builtin.unrealized_conversion_cast"(%176) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %533 = "llvm.load"(%531) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%533, %532) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %363 = "cute.add_offset"(%194, %88) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %364 = "builtin.unrealized_conversion_cast"(%363) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %365 = "llvm.load"(%364) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %366 = "llvm.icmp"(%365, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%366) ({
        %526 = "cute.add_offset"(%184, %88) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %527 = "cute.add_offset"(%176, %88) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %528 = "builtin.unrealized_conversion_cast"(%526) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %529 = "builtin.unrealized_conversion_cast"(%527) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %530 = "llvm.load"(%528) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%530, %529) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %367 = "cute.add_offset"(%194, %85) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %368 = "builtin.unrealized_conversion_cast"(%367) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %369 = "llvm.load"(%368) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %370 = "llvm.icmp"(%369, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%370) ({
        %521 = "cute.add_offset"(%184, %85) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %522 = "cute.add_offset"(%176, %85) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %523 = "builtin.unrealized_conversion_cast"(%521) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %524 = "builtin.unrealized_conversion_cast"(%522) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %525 = "llvm.load"(%523) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%525, %524) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %371 = "cute.add_offset"(%194, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %372 = "builtin.unrealized_conversion_cast"(%371) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %373 = "llvm.load"(%372) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %374 = "llvm.icmp"(%373, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%374) ({
        %516 = "cute.add_offset"(%184, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %517 = "cute.add_offset"(%176, %84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %518 = "builtin.unrealized_conversion_cast"(%516) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %519 = "builtin.unrealized_conversion_cast"(%517) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %520 = "llvm.load"(%518) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%520, %519) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %375 = "cute.add_offset"(%194, %83) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %376 = "builtin.unrealized_conversion_cast"(%375) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %377 = "llvm.load"(%376) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %378 = "llvm.icmp"(%377, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%378) ({
        %510 = "cute.add_offset"(%184, %83) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %511 = "cute.make_int_tuple"(%359) : (i64) -> !cute.int_tuple<"?{i64}">
        %512 = "cute.add_offset"(%176, %511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %513 = "builtin.unrealized_conversion_cast"(%510) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %514 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %515 = "llvm.load"(%513) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%515, %514) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %379 = "cute.add_offset"(%194, %82) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %380 = "builtin.unrealized_conversion_cast"(%379) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %381 = "llvm.load"(%380) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %382 = "llvm.icmp"(%381, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%382) ({
        %503 = "cute.add_offset"(%184, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %504 = "arith.addi"(%359, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %505 = "cute.make_int_tuple"(%504) : (i64) -> !cute.int_tuple<"?{i64}">
        %506 = "cute.add_offset"(%176, %505) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %507 = "builtin.unrealized_conversion_cast"(%503) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %508 = "builtin.unrealized_conversion_cast"(%506) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %509 = "llvm.load"(%507) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%509, %508) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %383 = "cute.add_offset"(%194, %80) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %384 = "builtin.unrealized_conversion_cast"(%383) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %385 = "llvm.load"(%384) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %386 = "llvm.icmp"(%385, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%386) ({
        %496 = "cute.add_offset"(%184, %80) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %497 = "arith.addi"(%359, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %498 = "cute.make_int_tuple"(%497) : (i64) -> !cute.int_tuple<"?{i64}">
        %499 = "cute.add_offset"(%176, %498) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %500 = "builtin.unrealized_conversion_cast"(%496) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %501 = "builtin.unrealized_conversion_cast"(%499) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %502 = "llvm.load"(%500) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%502, %501) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %387 = "cute.add_offset"(%194, %78) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %388 = "builtin.unrealized_conversion_cast"(%387) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %389 = "llvm.load"(%388) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %390 = "llvm.icmp"(%389, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%390) ({
        %489 = "cute.add_offset"(%184, %78) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %490 = "arith.addi"(%359, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %491 = "cute.make_int_tuple"(%490) : (i64) -> !cute.int_tuple<"?{i64}">
        %492 = "cute.add_offset"(%176, %491) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %493 = "builtin.unrealized_conversion_cast"(%489) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %494 = "builtin.unrealized_conversion_cast"(%492) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %495 = "llvm.load"(%493) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%495, %494) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %391 = "cute.add_offset"(%194, %76) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %392 = "builtin.unrealized_conversion_cast"(%391) : (!cute.ptr<i8, rmem, align<8>>) -> !llvm.ptr
      %393 = "llvm.load"(%392) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %394 = "llvm.icmp"(%393, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%394) ({
        %481 = "cute.add_offset"(%184, %76) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %482 = "arith.muli"(%359, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %483 = "cute.assume"(%482) : (i64) -> !cute.i64<divby 2>
        %484 = "cute.make_int_tuple"(%483) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %485 = "cute.add_offset"(%176, %484) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %486 = "builtin.unrealized_conversion_cast"(%481) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %487 = "builtin.unrealized_conversion_cast"(%485) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %488 = "llvm.load"(%486) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%488, %487) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %395 = "cute.add_offset"(%194, %75) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %396 = "builtin.unrealized_conversion_cast"(%395) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %397 = "llvm.load"(%396) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %398 = "llvm.icmp"(%397, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%398) ({
        %473 = "cute.add_offset"(%184, %75) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
        %474 = "arith.muli"(%359, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %475 = "arith.addi"(%474, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %476 = "cute.make_int_tuple"(%475) : (i64) -> !cute.int_tuple<"?{i64}">
        %477 = "cute.add_offset"(%176, %476) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %478 = "builtin.unrealized_conversion_cast"(%473) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %479 = "builtin.unrealized_conversion_cast"(%477) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %480 = "llvm.load"(%478) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%480, %479) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %399 = "cute.add_offset"(%194, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %400 = "builtin.unrealized_conversion_cast"(%399) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %401 = "llvm.load"(%400) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %402 = "llvm.icmp"(%401, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%402) ({
        %464 = "cute.add_offset"(%184, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
        %465 = "arith.muli"(%359, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %466 = "arith.addi"(%465, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %467 = "cute.assume"(%466) : (i64) -> !cute.i64<divby 2>
        %468 = "cute.make_int_tuple"(%467) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %469 = "cute.add_offset"(%176, %468) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %470 = "builtin.unrealized_conversion_cast"(%464) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %471 = "builtin.unrealized_conversion_cast"(%469) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %472 = "llvm.load"(%470) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%472, %471) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %403 = "cute.add_offset"(%194, %73) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %404 = "builtin.unrealized_conversion_cast"(%403) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %405 = "llvm.load"(%404) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %406 = "llvm.icmp"(%405, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%406) ({
        %456 = "cute.add_offset"(%184, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
        %457 = "arith.muli"(%359, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %458 = "arith.addi"(%457, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %459 = "cute.make_int_tuple"(%458) : (i64) -> !cute.int_tuple<"?{i64}">
        %460 = "cute.add_offset"(%176, %459) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %461 = "builtin.unrealized_conversion_cast"(%456) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %462 = "builtin.unrealized_conversion_cast"(%460) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %463 = "llvm.load"(%461) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%463, %462) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %407 = "cute.add_offset"(%194, %72) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %408 = "builtin.unrealized_conversion_cast"(%407) : (!cute.ptr<i8, rmem, align<4>>) -> !llvm.ptr
      %409 = "llvm.load"(%408) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %410 = "llvm.icmp"(%409, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%410) ({
        %448 = "cute.add_offset"(%184, %72) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %449 = "arith.muli"(%359, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %450 = "cute.assume"(%449) : (i64) -> !cute.i64<divby 3>
        %451 = "cute.make_int_tuple"(%450) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %452 = "cute.add_offset"(%176, %451) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %453 = "builtin.unrealized_conversion_cast"(%448) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
        %454 = "builtin.unrealized_conversion_cast"(%452) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %455 = "llvm.load"(%453) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%455, %454) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %411 = "cute.add_offset"(%194, %71) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %412 = "builtin.unrealized_conversion_cast"(%411) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %413 = "llvm.load"(%412) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %414 = "llvm.icmp"(%413, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%414) ({
        %440 = "cute.add_offset"(%184, %71) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
        %441 = "arith.muli"(%359, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %442 = "arith.addi"(%441, %81) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %443 = "cute.make_int_tuple"(%442) : (i64) -> !cute.int_tuple<"?{i64}">
        %444 = "cute.add_offset"(%176, %443) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %445 = "builtin.unrealized_conversion_cast"(%440) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %446 = "builtin.unrealized_conversion_cast"(%444) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %447 = "llvm.load"(%445) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%447, %446) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %415 = "cute.add_offset"(%194, %70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %416 = "builtin.unrealized_conversion_cast"(%415) : (!cute.ptr<i8, rmem, align<2>>) -> !llvm.ptr
      %417 = "llvm.load"(%416) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %418 = "llvm.icmp"(%417, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%418) ({
        %432 = "cute.add_offset"(%184, %70) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
        %433 = "arith.muli"(%359, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %434 = "arith.addi"(%433, %79) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %435 = "cute.make_int_tuple"(%434) : (i64) -> !cute.int_tuple<"?{i64}">
        %436 = "cute.add_offset"(%176, %435) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %437 = "builtin.unrealized_conversion_cast"(%432) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %438 = "builtin.unrealized_conversion_cast"(%436) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %439 = "llvm.load"(%437) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%439, %438) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %419 = "cute.add_offset"(%194, %69) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %420 = "builtin.unrealized_conversion_cast"(%419) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %421 = "llvm.load"(%420) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %422 = "llvm.icmp"(%421, %86) <{predicate = 1 : i64}> : (i8, i8) -> i1
      "scf.if"(%422) ({
        %423 = "cute.add_offset"(%184, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
        %424 = "arith.muli"(%359, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %425 = "arith.addi"(%424, %77) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
        %426 = "cute.assume"(%425) : (i64) -> !cute.i64<divby 3>
        %427 = "cute.make_int_tuple"(%426) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %428 = "cute.add_offset"(%176, %427) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %429 = "builtin.unrealized_conversion_cast"(%423) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %430 = "builtin.unrealized_conversion_cast"(%428) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %431 = "llvm.load"(%429) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
        "llvm.store"(%431, %430) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
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
    %65 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %66 = "cuda.launch_cfg.create"(%5, %0, %0, %1, %64, %0, %0, %65) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%66, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%66, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %67 = "cuda.launch_ex"(%66, %18, %29, %40, %54, %59, %61) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %68 = "cuda.cast"(%67) : (!cuda.result) -> i32
    "cuda.return_if_error"(%68) : (i32) -> ()
    "func.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
