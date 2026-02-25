!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>, layout_copy_tv = <"(256,4):(4,1)">, tiler_mn = <"[128:1;8:1]">>
!copy_ldgsts1 = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>, layout_copy_tv = <"((8,32),1):((32,1),0)">, tiler_mn = <"[32:1;8:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "(256,64):(1,256)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "(?,?{div=64}):(?{i64 div=64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, align<16>, "(?,?{div=256}):(?{i64 div=256},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, "(1,(4,2),8):(0,(1,4),8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, "(1):(0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,1)">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,1)">
!memref_rmem_i8_4 = !cute.memref<i8, rmem, align<32>, "(1):(1)">
!memref_rmem_i8_5 = !cute.memref<i8, rmem, "(1):(1)">
!memref_rmem_i8_6 = !cute.memref<i8, rmem, align<32>, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_smem_f32_ = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),128)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),132)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> (), sym_name = "kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_1, %arg6: !memref_gmem_f32_2):
      %25 = "arith.constant"() <{value = dense<0.000000e+00> : vector<64xf32>}> : () -> vector<64xf32>
      %26 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
      %27 = "cute.static"() : () -> !cute.shape<"(1,(((4,2),(4,2))))">
      %28 = "cute.static"() : () -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">
      %29 = "cute.static"() : () -> !cute.shape<"(1,((4,2),(4,2)))">
      %30 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">
      %31 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %32 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %33 = "cute.static"() : () -> !cute.layout<"(1,(4,2),1):(0,(1,4),0)">
      %34 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %35 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),132)">
      %36 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
      %37 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),128)">
      %38 = "arith.constant"() <{value = 7 : i32}> : () -> i32
      %39 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
      %40 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
      %41 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">
      %42 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">
      %43 = "cute.static"() : () -> !cute.shape<"(1,(4,2),(4,2))">
      %44 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %45 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %46 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %47 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,0)))">
      %48 = "cute.static"() : () -> !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">
      %49 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">
      %50 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %51 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,1)))">
      %52 = "cute.static"() : () -> !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
      %53 = "cute.static"() : () -> !cute.shape<"((1,1),((4,1)))">
      %54 = "cute.static"() : () -> !cute.shape<"((1,1),(4,1))">
      %55 = "cute.static"() : () -> !cute.shape<"((1,1),4,1)">
      %56 = "cute.static"() : () -> !cute.layout<"(1):(1)">
      %57 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
      %58 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %59 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %60 = "cute.static"() : () -> !cute.stride<"((0,0),32@0,0,8@1)">
      %61 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %62 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,8@1)">
      %63 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(128@0,8@1))">
      %64 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">
      %65 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %66 = "arith.constant"() <{value = 132 : i32}> : () -> i32
      %67 = "arith.constant"() <{value = 32 : i64}> : () -> i64
      %68 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %69 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %70 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %71 = "cute.static"() : () -> !cute.int_tuple<"12288">
      %72 = "cute.static"() : () -> !cute.shape<"(128,128)">
      %73 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %74 = "arith.constant"() <{value = 128 : i64}> : () -> i64
      %75 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %76 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">
      %77 = "cute.static"() : () -> !cute.layout<"1:0">
      %78 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %79 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %80 = "nvvm.read.ptx.sreg.ctaid.y"() <{range = #llvm.constant_range<i32, 0, 65535>}> : () -> i32
      %81 = "cute.make_coord"(%79) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %82 = "cute.crd2idx"(%81, %76) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">) -> !cute.int_tuple<"?{div=128}">
      %83 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %84 = "cute.add_offset"(%83, %82) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %85 = "cute.make_coord"(%80) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %86 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %87:3 = "cute.get_scalars"(%86) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> (i32, i32, i64)
      %88 = "arith.ceildivsi"(%87#0, %75) : (i32, i32) -> i32
      %89 = "arith.muli"(%87#2, %74) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %90 = "arith.ceildivsi"(%87#1, %73) : (i32, i32) -> i32
      %91 = "cute.make_shape"(%88, %90) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %92 = "cute.assume"(%87#2) : (i64) -> !cute.i64<divby 64>
      %93 = "cute.assume"(%89) : (i64) -> !cute.i64<divby 8192>
      %94 = "cute.make_stride"(%92, %93) : (!cute.i64<divby 64>, !cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">
      %95 = "cute.make_layout"(%91, %94) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">
      %96:4 = "cute.get_scalars"(%95) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> (i32, i32, i64, i64)
      %97 = "cute.make_shape"(%96#1) : (i32) -> !cute.shape<"(128,8,?)">
      %98 = "cute.assume"(%96#2) : (i64) -> !cute.i64<divby 64>
      %99 = "cute.make_stride"(%98) : (!cute.i64<divby 64>) -> !cute.stride<"(?{i64 div=64},1,8)">
      %100 = "cute.make_layout"(%97, %99) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(?{i64 div=64},1,8)">) -> !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %101 = "cute.crd2idx"(%85, %95) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.int_tuple<"?{i64 div=8192}">
      %102 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem, align<16>>
      %103 = "cute.add_offset"(%102, %101) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f32, gmem, align<16>>
      %104 = "cute.make_coord"(%79, %80) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %105 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %106:3 = "cute.get_scalars"(%105) <{only_dynamic}> : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> (i32, i32, i64)
      %107 = "arith.ceildivsi"(%106#0, %75) : (i32, i32) -> i32
      %108 = "arith.muli"(%106#2, %74) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %109 = "arith.ceildivsi"(%106#1, %75) : (i32, i32) -> i32
      %110 = "cute.make_shape"(%107, %109) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %111 = "cute.assume"(%106#2) : (i64) -> !cute.i64<divby 256>
      %112 = "cute.assume"(%108) : (i64) -> !cute.i64<divby 32768>
      %113 = "cute.make_stride"(%111, %112) : (!cute.i64<divby 256>, !cute.i64<divby 32768>) -> !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">
      %114 = "cute.make_layout"(%110, %113) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,128),(?,?))">, !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">
      %115:4 = "cute.get_scalars"(%114) <{only_dynamic}> : (!cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> (i32, i32, i64, i64)
      %116 = "cute.assume"(%115#2) : (i64) -> !cute.i64<divby 256>
      %117 = "cute.make_stride"(%116) : (!cute.i64<divby 256>) -> !cute.stride<"(?{i64 div=256},1)">
      %118 = "cute.make_layout"(%72, %117) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,128)">, !cute.stride<"(?{i64 div=256},1)">) -> !cute.layout<"(128,128):(?{i64 div=256},1)">
      %119 = "cute.crd2idx"(%104, %114) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.int_tuple<"?{i64 div=128}">
      %120 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem, align<16>>
      %121 = "cute.add_offset"(%120, %119) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %122 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %123 = "cute.add_offset"(%122, %71) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"12288">) -> !cute.ptr<i8, smem, align<1024>>
      %124 = "cute.recast_iter"(%122) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %125 = "cute.recast_iter"(%123) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %126 = "arith.divsi"(%78, %70) : (i32, i32) -> i32
      %127 = "arith.remsi"(%78, %70) : (i32, i32) -> i32
      %128 = "arith.muli"(%127, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %129 = "arith.muli"(%126, %68) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %130 = "arith.addi"(%128, %129) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %131 = "cute.assume"(%130) : (i32) -> !cute.i32<divby 4>
      %132 = "cute.make_int_tuple"(%131) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %133 = "cute.add_offset"(%84, %132) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %134 = "arith.muli"(%78, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %135 = "cute.assume"(%134) : (i32) -> !cute.i32<divby 4>
      %136 = "cute.make_int_tuple"(%135) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %137 = "cute.add_offset"(%124, %136) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %138:2 = "cute.get_scalars"(%100) <{only_dynamic}> : (!cute.layout<"(128,8,?):(?{i64 div=64},1,8)">) -> (i32, i64)
      %139 = "arith.muli"(%138#1, %67) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %140 = "arith.divsi"(%78, %73) : (i32, i32) -> i32
      %141 = "arith.remsi"(%78, %73) : (i32, i32) -> i32
      %142 = "arith.extsi"(%140) : (i32) -> i64
      %143 = "arith.muli"(%142, %138#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %144 = "arith.extsi"(%141) : (i32) -> i64
      %145 = "arith.addi"(%144, %143) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %146 = "cute.make_int_tuple"(%145) : (i64) -> !cute.int_tuple<"?{i64}">
      %147 = "cute.add_offset"(%103, %146) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %148 = "cute.make_shape"(%138#0) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %149 = "cute.assume"(%139) : (i64) -> !cute.i64<divby 2048>
      %150 = "cute.make_stride"(%149) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0,8)">
      %151 = "cute.make_layout"(%148, %150) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),?{i64 div=2048},0,8)">) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %152 = "arith.divsi"(%78, %73) : (i32, i32) -> i32
      %153 = "arith.remsi"(%78, %73) : (i32, i32) -> i32
      %154 = "arith.muli"(%153, %66) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %155 = "arith.addi"(%154, %152) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %156 = "cute.make_int_tuple"(%155) : (i32) -> !cute.int_tuple<"?">
      %157 = "cute.add_offset"(%125, %156) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<f32, smem>
      %158 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %159 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %160 = "cute.get_shape"(%159) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
      %161:2 = "cute.get_leaves"(%160) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
      %162 = "cute.to_int_tuple"(%161#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %163 = "cute.to_int_tuple"(%161#1) : (!cute.shape<"?{div=64}">) -> !cute.int_tuple<"?{div=64}">
      %164 = "cute.make_shape"(%162, %163) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=64}">) -> !cute.shape<"(?,?{div=64})">
      %165 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %166 = "cute.make_layout"(%164, %65) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=64})">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %167 = "cute.make_coord"(%79) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %168 = "cute.crd2idx"(%167, %64) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %169 = "cute.add_offset"(%158, %168) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %170 = "cute.deref_arith_tuple_iter"(%169) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %171:2 = "cute.get_leaves"(%170) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %172 = "cute.make_coord"(%80) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %173:2 = "cute.get_scalars"(%166) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(1@0,1@1)">) -> (i32, i32)
      %174 = "arith.ceildivsi"(%173#0, %75) : (i32, i32) -> i32
      %175 = "arith.ceildivsi"(%173#1, %73) : (i32, i32) -> i32
      %176 = "cute.make_shape"(%174, %175) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %177 = "cute.make_layout"(%176, %63) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((1@0,1@1),(128@0,8@1))">) -> !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">
      %178:2 = "cute.get_scalars"(%177) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> (i32, i32)
      %179 = "cute.make_shape"(%178#1) : (i32) -> !cute.shape<"(128,8,?)">
      %180 = "cute.make_layout"(%179, %62) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(1@0,1@1,8@1)">) -> !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %181 = "cute.crd2idx"(%172, %177) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %182 = "cute.add_offset"(%165, %181) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %183 = "cute.deref_arith_tuple_iter"(%182) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %184:2 = "cute.get_leaves"(%183) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %185 = "cute.make_int_tuple"(%171#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %186 = "cute.tuple_add"(%185, %61) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %187:2 = "cute.get_leaves"(%186) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %188 = "cute.make_int_tuple"(%187#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %189 = "cute.make_arith_tuple_iter"(%188) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %190 = "cute.make_int_tuple"(%184#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %191 = "cute.tuple_add"(%190, %61) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %192:2 = "cute.get_leaves"(%191) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %193 = "cute.make_int_tuple"(%192#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %194 = "cute.make_arith_tuple_iter"(%193) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %195 = "arith.divsi"(%78, %70) : (i32, i32) -> i32
      %196 = "arith.remsi"(%78, %70) : (i32, i32) -> i32
      %197 = "arith.muli"(%196, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %198 = "cute.assume"(%197) : (i32) -> !cute.i32<divby 4>
      %199 = "cute.make_int_tuple"(%198, %195) : (!cute.i32<divby 4>, i32) -> !cute.int_tuple<"(?{div=4},?)">
      %200 = "cute.add_offset"(%189, %199) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?{div=4},?)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
      %201 = "cute.get_scalars"(%180) <{only_dynamic}> : (!cute.layout<"(128,8,?):(1@0,1@1,8@1)">) -> i32
      %202 = "arith.divsi"(%78, %73) : (i32, i32) -> i32
      %203 = "arith.remsi"(%78, %73) : (i32, i32) -> i32
      %204 = "cute.make_int_tuple"(%202, %203) : (i32, i32) -> !cute.int_tuple<"(?,?)">
      %205 = "cute.add_offset"(%194, %204) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %206 = "cute.make_shape"(%201) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %207 = "cute.make_layout"(%206, %60) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),32@0,0,8@1)">) -> !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
      %208 = "cute.memref.alloca"() : () -> !memref_rmem_i8_
      %209 = "cute.memref.alloca"() : () -> !memref_rmem_i8_1
      %210 = "cute.memref.alloca"() : () -> !memref_rmem_i8_2
      %211 = "cute.memref.alloca"() : () -> !memref_rmem_i8_3
      %212 = "cute.deref_arith_tuple_iter"(%200) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
      %213:2 = "cute.get_leaves"(%212) : (!cute.int_tuple<"(?{div=4},?)">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %214 = "cute.make_coord"(%213#0) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"?{div=4}">
      %215 = "cute.get_scalars"(%214) : (!cute.coord<"?{div=4}">) -> i32
      %216 = "arith.cmpi"(%215, %68) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %217 = "arith.extui"(%216) : (i1) -> i8
      %218 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      %219 = "cute.derefine"(%218) : (!cute.coord<"(0,0,0)">) -> !cute.coord<"(?,?,0)">
      "cute.memref.store"(%208, %219, %217) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %220 = "cute.get_iter"(%208) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      "scf.for"(%59, %69, %58) ({
      ^bb0(%arg31: i32):
        %586 = "cute.make_coord"(%arg31) : (i32) -> !cute.coord<"((0,0),?,0,0)">
        %587 = "cute.crd2idx"(%586, %207) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
        %588 = "cute.add_offset"(%205, %587) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
        %589 = "cute.deref_arith_tuple_iter"(%588) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %590:2 = "cute.get_leaves"(%589) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %591 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
        %592 = "cute.get_shape"(%591) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
        %593:2 = "cute.get_leaves"(%592) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
        %594 = "cute.to_int_tuple"(%593#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
        %595 = "cute.make_coord"(%590#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %596 = "cute.make_coord"(%594) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %597 = "cute.get_scalars"(%595) : (!cute.coord<"?">) -> i32
        %598 = "cute.get_scalars"(%596) : (!cute.coord<"?">) -> i32
        %599 = "arith.cmpi"(%597, %598) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %600 = "arith.extui"(%599) : (i1) -> i8
        %601 = "cute.make_coord"(%arg31) : (i32) -> !cute.coord<"(0,?,0)">
        %602 = "cute.derefine"(%601) : (!cute.coord<"(0,?,0)">) -> !cute.coord<"(?,?,0)">
        "cute.memref.store"(%209, %602, %600) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %221 = "cute.get_iter"(%209) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %222 = "cute.deref_arith_tuple_iter"(%200) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
      %223:2 = "cute.get_leaves"(%222) : (!cute.int_tuple<"(?{div=4},?)">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %224 = "cute.make_coord"(%223#0) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},-1)">
      %225 = "cute.derefine"(%224) : (!cute.coord<"(?{div=4},-1)">) -> !cute.coord<"(?{div=4},?)">
      %226 = "cute.make_coord"(%223#1) : (!cute.int_tuple<"?">) -> !cute.coord<"(256,?)">
      %227:2 = "cute.get_scalars"(%225) : (!cute.coord<"(?{div=4},?)">) -> (i32, i32)
      %228:2 = "cute.get_scalars"(%226) : (!cute.coord<"(256,?)">) -> (i32, i32)
      %229 = "arith.cmpi"(%227#0, %68) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %230 = "arith.cmpi"(%227#1, %228#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %231 = "arith.andi"(%229, %230) : (i1, i1) -> i1
      %232 = "arith.extui"(%231) : (i1) -> i8
      %233 = "cute.make_coord"() : () -> !cute.coord<"(0,0,0)">
      %234 = "cute.derefine"(%233) : (!cute.coord<"(0,0,0)">) -> !cute.coord<"(?,?,?)">
      "cute.memref.store"(%210, %234, %232) : (!memref_rmem_i8_2, !cute.coord<"(?,?,?)">, i8) -> ()
      %235 = "cute.get_iter"(%210) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
      "scf.for"(%59, %69, %58) ({
      ^bb0(%arg30: i32):
        %566 = "cute.make_coord"(%arg30) : (i32) -> !cute.coord<"((0,0),?,0,0)">
        %567 = "cute.crd2idx"(%566, %207) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
        %568 = "cute.add_offset"(%205, %567) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
        %569 = "cute.deref_arith_tuple_iter"(%568) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %570:2 = "cute.get_leaves"(%569) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %571 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
        %572 = "cute.get_shape"(%571) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
        %573:2 = "cute.get_leaves"(%572) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
        %574 = "cute.to_int_tuple"(%573#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
        %575 = "cute.make_coord"(%570#0) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,-1)">
        %576 = "cute.derefine"(%575) : (!cute.coord<"(?,-1)">) -> !cute.coord<"(?,?)">
        %577 = "cute.make_coord"(%574, %570#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %578:2 = "cute.get_scalars"(%576) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %579:2 = "cute.get_scalars"(%577) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %580 = "arith.cmpi"(%578#0, %579#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %581 = "arith.cmpi"(%578#1, %579#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %582 = "arith.andi"(%580, %581) : (i1, i1) -> i1
        %583 = "arith.extui"(%582) : (i1) -> i8
        %584 = "cute.make_coord"(%arg30) : (i32) -> !cute.coord<"(0,?,0)">
        %585 = "cute.derefine"(%584) : (!cute.coord<"(0,?,0)">) -> !cute.coord<"(?,?,?)">
        "cute.memref.store"(%211, %585, %583) : (!memref_rmem_i8_3, !cute.coord<"(?,?,?)">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %236 = "cute.get_iter"(%211) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
      %237 = "cute.make_view"(%235, %56) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1):(1)">) -> !memref_rmem_i8_4
      %238 = "cute.derefine"(%237) : (!memref_rmem_i8_4) -> !memref_rmem_i8_5
      %239 = "cute.get_iter"(%238) : (!memref_rmem_i8_5) -> !cute.ptr<i8, rmem>
      %240 = "builtin.unrealized_conversion_cast"(%239) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
      %241 = "llvm.load"(%240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %242 = "llvm.trunc"(%241) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %243 = "cute.recast_iter"(%133) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %244 = "cute.recast_iter"(%137) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%244, %243, %242) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %245:2 = "cute.get_scalars"(%151) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
      %246 = "cute.assume"(%245#1) : (i64) -> !cute.i64<divby 2048>
      %247 = "cute.make_stride"(%246) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %248 = "cute.make_layout"(%55, %247) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %249 = "cute.append_to_rank"(%248, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %250 = "cute.get_scalars"(%249) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
      %251 = "cute.assume"(%250) : (i64) -> !cute.i64<divby 2048>
      %252 = "cute.make_stride"(%251) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %253 = "cute.make_layout"(%54, %252) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %254 = "cute.append_to_rank"(%253, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %255 = "cute.get_scalars"(%254) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
      %256 = "cute.assume"(%255) : (i64) -> !cute.i64<divby 2048>
      %257 = "cute.make_stride"(%256) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %258 = "cute.make_layout"(%53, %257) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      "scf.for"(%59, %69, %58) ({
      ^bb0(%arg29: i32):
        %554 = "cute.make_coord"(%arg29) : (i32) -> !cute.coord<"(_,?)">
        %555 = "cute.crd2idx"(%554, %258) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
        %556 = "cute.add_offset"(%147, %555) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
        %557 = "cute.crd2idx"(%554, %52) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
        %558 = "cute.add_offset"(%157, %557) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
        %559 = "cute.crd2idx"(%554, %51) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,1)))">) -> !cute.int_tuple<"?">
        %560 = "cute.add_offset"(%236, %559) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %561 = "builtin.unrealized_conversion_cast"(%560) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %562 = "llvm.load"(%561) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %563 = "llvm.trunc"(%562) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %564 = "cute.recast_iter"(%556) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
        %565 = "cute.recast_iter"(%558) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%565, %564, %563) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %259 = "cute.make_coord"() : () -> !cute.coord<"(_,_,_,1)">
      %260 = "cute.crd2idx"(%259, %57) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"2048">
      %261 = "cute.add_offset"(%133, %260) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<f32, gmem, align<16>>
      %262 = "cute.make_coord"() : () -> !cute.coord<"(_,_,_,1)">
      %263 = "cute.crd2idx"(%262, %49) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"1024">
      %264 = "cute.add_offset"(%137, %263) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<f32, smem, align<16>>
      %265 = "builtin.unrealized_conversion_cast"(%220) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
      %266 = "llvm.load"(%265) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
      %267 = "llvm.trunc"(%266) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
      %268 = "cute.recast_iter"(%261) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
      %269 = "cute.recast_iter"(%264) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
      "cute_nvgpu.arch.copy.SM80.cp_async"(%269, %268, %267) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
      %270 = "cute.make_coord"() : () -> !cute.coord<"(_,_,_,1)">
      %271:2 = "cute.get_scalars"(%151) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
      %272 = "cute.assume"(%271#1) : (i64) -> !cute.i64<divby 2048>
      %273 = "cute.make_stride"(%272) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %274 = "cute.make_layout"(%55, %273) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %275 = "cute.crd2idx"(%270, %151) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"8">
      %276 = "cute.add_offset"(%147, %275) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"8">) -> !cute.ptr<f32, gmem>
      %277 = "cute.make_coord"() : () -> !cute.coord<"(_,_,_,1)">
      %278 = "cute.crd2idx"(%277, %48) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"1056">
      %279 = "cute.add_offset"(%157, %278) : (!cute.ptr<f32, smem>, !cute.int_tuple<"1056">) -> !cute.ptr<f32, smem>
      %280 = "cute.append_to_rank"(%274, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %281 = "cute.get_scalars"(%280) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
      %282 = "cute.assume"(%281) : (i64) -> !cute.i64<divby 2048>
      %283 = "cute.make_stride"(%282) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %284 = "cute.make_layout"(%54, %283) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %285 = "cute.append_to_rank"(%284, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %286 = "cute.get_scalars"(%285) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
      %287 = "cute.assume"(%286) : (i64) -> !cute.i64<divby 2048>
      %288 = "cute.make_stride"(%287) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %289 = "cute.make_layout"(%53, %288) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      "scf.for"(%59, %69, %58) ({
      ^bb0(%arg28: i32):
        %542 = "cute.make_coord"(%arg28) : (i32) -> !cute.coord<"(_,?)">
        %543 = "cute.crd2idx"(%542, %289) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
        %544 = "cute.add_offset"(%276, %543) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
        %545 = "cute.crd2idx"(%542, %52) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
        %546 = "cute.add_offset"(%279, %545) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
        %547 = "cute.crd2idx"(%542, %47) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
        %548 = "cute.add_offset"(%221, %547) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %549 = "builtin.unrealized_conversion_cast"(%548) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %550 = "llvm.load"(%549) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %551 = "llvm.trunc"(%550) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %552 = "cute.recast_iter"(%544) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
        %553 = "cute.recast_iter"(%546) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%553, %552, %551) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %290 = "cute.get_iter"(%208) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %291 = "cute.get_iter"(%209) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %292 = "arith.divsi"(%78, %46) : (i32, i32) -> i32
      %293 = "arith.remsi"(%292, %46) : (i32, i32) -> i32
      %294 = "arith.remsi"(%293, %46) : (i32, i32) -> i32
      %295 = "arith.muli"(%294, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %296 = "cute.assume"(%295) : (i32) -> !cute.i32<divby 4>
      %297 = "cute.make_int_tuple"(%296) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %298 = "cute.add_offset"(%124, %297) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %299 = "arith.remsi"(%78, %46) : (i32, i32) -> i32
      %300 = "arith.remsi"(%299, %46) : (i32, i32) -> i32
      %301 = "arith.muli"(%300, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %302 = "cute.assume"(%301) : (i32) -> !cute.i32<divby 4>
      %303 = "cute.make_int_tuple"(%302) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %304 = "cute.add_offset"(%125, %303) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %305 = "cute.get_scalars"(%118) <{only_dynamic}> : (!cute.layout<"(128,128):(?{i64 div=256},1)">) -> i64
      %306 = "arith.muli"(%305, %45) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %307 = "arith.muli"(%305, %44) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %308 = "arith.divsi"(%78, %46) : (i32, i32) -> i32
      %309 = "arith.remsi"(%308, %46) : (i32, i32) -> i32
      %310 = "arith.remsi"(%78, %46) : (i32, i32) -> i32
      %311 = "arith.remsi"(%309, %46) : (i32, i32) -> i32
      %312 = "arith.remsi"(%310, %46) : (i32, i32) -> i32
      %313 = "arith.extsi"(%311) : (i32) -> i64
      %314 = "arith.muli"(%313, %306) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %315 = "arith.muli"(%312, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %316 = "arith.extsi"(%315) : (i32) -> i64
      %317 = "arith.addi"(%314, %316) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %318 = "cute.assume"(%317) : (i64) -> !cute.i64<divby 4>
      %319 = "cute.make_int_tuple"(%318) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %320 = "cute.add_offset"(%121, %319) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %321 = "cute.assume"(%305) : (i64) -> !cute.i64<divby 256>
      %322 = "cute.assume"(%307) : (i64) -> !cute.i64<divby 16384>
      %323 = "cute.make_stride"(%321, %322) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %324 = "cute.make_layout"(%43, %323) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(4,2),(4,2))">, !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %325 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %326 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %327 = "cute.memref.alloca"() : () -> !memref_rmem_f32_1
      %328 = "cute.get_iter"(%327) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
      "cute.memref.store_vec"(%25, %327) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %329 = "cute.make_view"(%298) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_
      %330 = "cute.make_view"(%304) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_1
      "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
      "llvm.inline_asm"(%58, %68) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %331 = "cute.get_iter"(%325) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
      "scf.for"(%59, %50, %58) ({
      ^bb0(%arg27: i32):
        %534 = "cute.make_coord"(%arg27) : (i32) -> !cute.coord<"(_,?)">
        %535 = "cute.crd2idx"(%534, %40) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
        %536 = "cute.add_offset"(%298, %535) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
        %537 = "cute.crd2idx"(%534, %39) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
        %538 = "cute.add_offset"(%331, %537) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
        %539 = "builtin.unrealized_conversion_cast"(%536) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
        %540 = "builtin.unrealized_conversion_cast"(%538) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %541 = "llvm.load"(%539) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
        "llvm.store"(%541, %540) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %332 = "cute.get_iter"(%326) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
      "scf.for"(%59, %50, %58) ({
      ^bb0(%arg26: i32):
        %526 = "cute.make_coord"(%arg26) : (i32) -> !cute.coord<"(_,?)">
        %527 = "cute.crd2idx"(%526, %40) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
        %528 = "cute.add_offset"(%304, %527) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
        %529 = "cute.crd2idx"(%526, %39) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
        %530 = "cute.add_offset"(%332, %529) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
        %531 = "builtin.unrealized_conversion_cast"(%528) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
        %532 = "builtin.unrealized_conversion_cast"(%530) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %533 = "llvm.load"(%531) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
        "llvm.store"(%533, %532) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %333:5 = "scf.for"(%59, %73, %58, %329, %330, %50, %59, %50) ({
      ^bb0(%arg9: i32, %arg10: !memref_smem_f32_, %arg11: !memref_smem_f32_1, %arg12: i32, %arg13: i32, %arg14: i32):
        %402:5 = "scf.for"(%59, %73, %58, %arg10, %arg11, %arg12, %arg13, %arg14) ({
        ^bb0(%arg15: i32, %arg16: !memref_smem_f32_, %arg17: !memref_smem_f32_1, %arg18: i32, %arg19: i32, %arg20: i32):
          %403 = "arith.cmpi"(%arg15, %38) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %404:2 = "scf.if"(%403) ({
            %518 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"(_,_,_,?)">
            %519 = "cute.crd2idx"(%518, %42) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %520 = "cute.add_offset"(%298, %519) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %521 = "cute.make_view"(%520) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_
            %522 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"(_,_,_,?)">
            %523 = "cute.crd2idx"(%522, %41) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %524 = "cute.add_offset"(%304, %523) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
            %525 = "cute.make_view"(%524) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_1
            "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
            "llvm.inline_asm"(%58, %68) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
            "scf.yield"(%521, %525) : (!memref_smem_f32_, !memref_smem_f32_1) -> ()
          }, {
            "scf.yield"(%arg16, %arg17) : (!memref_smem_f32_, !memref_smem_f32_1) -> ()
          }) : (i1) -> (!memref_smem_f32_, !memref_smem_f32_1)
          %405 = "arith.addi"(%arg15, %58) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %406 = "arith.remsi"(%405, %73) : (i32, i32) -> i32
          %407 = "cute.make_coord"(%406) : (i32) -> !cute.coord<"(_,_,?)">
          %408 = "cute.crd2idx"(%407, %37) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),128)">) -> !cute.int_tuple<"?{div=128}">
          %409 = "cute.get_iter"(%404#0) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<16>>
          %410 = "cute.add_offset"(%409, %408) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, smem, align<16>>
          %411 = "cute.make_coord"(%406) : (i32) -> !cute.coord<"(_,_,?)">
          %412 = "cute.crd2idx"(%411, %36) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %413 = "cute.get_iter"(%325) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %414 = "cute.add_offset"(%413, %412) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          "scf.for"(%59, %50, %58) ({
          ^bb0(%arg25: i32):
            %510 = "cute.make_coord"(%arg25) : (i32) -> !cute.coord<"(_,?)">
            %511 = "cute.crd2idx"(%510, %40) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %512 = "cute.add_offset"(%410, %511) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %513 = "cute.crd2idx"(%510, %39) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %514 = "cute.add_offset"(%414, %513) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %515 = "builtin.unrealized_conversion_cast"(%512) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
            %516 = "builtin.unrealized_conversion_cast"(%514) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
            %517 = "llvm.load"(%515) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
            "llvm.store"(%517, %516) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %415 = "cute.make_coord"(%406) : (i32) -> !cute.coord<"(_,_,?)">
          %416 = "cute.crd2idx"(%415, %35) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),132)">) -> !cute.int_tuple<"?{div=132}">
          %417 = "cute.get_iter"(%404#1) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<16>>
          %418 = "cute.add_offset"(%417, %416) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=132}">) -> !cute.ptr<f32, smem, align<16>>
          %419 = "cute.make_coord"(%406) : (i32) -> !cute.coord<"(_,_,?)">
          %420 = "cute.crd2idx"(%419, %36) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %421 = "cute.get_iter"(%326) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %422 = "cute.add_offset"(%421, %420) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          "scf.for"(%59, %50, %58) ({
          ^bb0(%arg24: i32):
            %502 = "cute.make_coord"(%arg24) : (i32) -> !cute.coord<"(_,?)">
            %503 = "cute.crd2idx"(%502, %40) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %504 = "cute.add_offset"(%418, %503) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %505 = "cute.crd2idx"(%502, %39) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %506 = "cute.add_offset"(%422, %505) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %507 = "builtin.unrealized_conversion_cast"(%504) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
            %508 = "builtin.unrealized_conversion_cast"(%506) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
            %509 = "llvm.load"(%507) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
            "llvm.store"(%509, %508) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %423 = "arith.cmpi"(%arg15, %59) <{predicate = 0 : i64}> : (i32, i32) -> i1
          "scf.if"(%423) ({
            %491 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,_,_,?)">
            %492 = "cute.crd2idx"(%491, %57) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
            %493 = "cute.add_offset"(%133, %492) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
            %494 = "cute.make_coord"(%arg18) : (i32) -> !cute.coord<"(_,_,_,?)">
            %495 = "cute.crd2idx"(%494, %49) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %496 = "cute.add_offset"(%137, %495) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %497 = "builtin.unrealized_conversion_cast"(%290) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
            %498 = "llvm.load"(%497) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
            %499 = "llvm.trunc"(%498) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
            %500 = "cute.recast_iter"(%493) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
            %501 = "cute.recast_iter"(%496) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
            "cute_nvgpu.arch.copy.SM80.cp_async"(%501, %500, %499) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %424 = "cute.make_coord"(%arg15) : (i32) -> !cute.coord<"(_,_,?)">
          %425 = "cute.crd2idx"(%424, %36) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %426 = "cute.get_iter"(%325) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %427 = "cute.add_offset"(%426, %425) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %428 = "cute.make_coord"(%arg15) : (i32) -> !cute.coord<"(_,_,?)">
          %429 = "cute.crd2idx"(%428, %36) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %430 = "cute.get_iter"(%326) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %431 = "cute.add_offset"(%430, %429) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %432 = "cute.get_iter"(%327) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
          "scf.for"(%59, %73, %58) ({
          ^bb0(%arg22: i32):
            "scf.for"(%59, %73, %58) ({
            ^bb0(%arg23: i32):
              %475 = "cute.make_coord"(%arg22) : (i32) -> !cute.coord<"(_,?,0)">
              %476 = "cute.make_coord"(%arg23) : (i32) -> !cute.coord<"(_,?,0)">
              %477 = "cute.make_coord"(%arg22, %arg23) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %478 = "cute.crd2idx"(%475, %33) : (!cute.coord<"(_,?,0)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
              %479 = "cute.add_offset"(%427, %478) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
              %480 = "cute.crd2idx"(%476, %33) : (!cute.coord<"(_,?,0)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
              %481 = "cute.add_offset"(%431, %480) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
              %482 = "cute.crd2idx"(%477, %34) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !cute.int_tuple<"?">
              %483 = "cute.add_offset"(%432, %482) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
              %484 = "cute.make_view"(%479) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
              %485 = "cute.make_view"(%481) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
              %486 = "cute.make_view"(%483) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
              %487 = "cute.memref.load_vec"(%484) : (!memref_rmem_f32_2) -> vector<1xf32>
              %488 = "cute.memref.load_vec"(%485) : (!memref_rmem_f32_2) -> vector<1xf32>
              %489 = "cute.memref.load_vec"(%486) : (!memref_rmem_f32_2) -> vector<1xf32>
              %490 = "math.fma"(%487, %488, %489) <{fastmath = #arith.fastmath<none>}> : (vector<1xf32>, vector<1xf32>, vector<1xf32>) -> vector<1xf32>
              "cute.memref.store_vec"(%490, %486) : (vector<1xf32>, !memref_rmem_f32_2) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %433 = "arith.cmpi"(%arg15, %59) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %434 = "arith.select"(%433, %arg19, %arg18) : (i1, i32, i32) -> i32
          %435:2 = "scf.if"(%433) ({
            %436 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,_,_,?)">
            %437:2 = "cute.get_scalars"(%151) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
            %438 = "cute.assume"(%437#1) : (i64) -> !cute.i64<divby 2048>
            %439 = "cute.make_stride"(%438) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
            %440 = "cute.make_layout"(%55, %439) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %441 = "cute.crd2idx"(%436, %151) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
            %442 = "cute.add_offset"(%147, %441) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
            %443 = "cute.make_coord"(%arg18) : (i32) -> !cute.coord<"(_,_,_,?)">
            %444 = "cute.crd2idx"(%443, %48) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %445 = "cute.add_offset"(%157, %444) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
            %446 = "cute.append_to_rank"(%440, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %447 = "cute.get_scalars"(%446) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
            %448 = "cute.assume"(%447) : (i64) -> !cute.i64<divby 2048>
            %449 = "cute.make_stride"(%448) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
            %450 = "cute.make_layout"(%54, %449) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
            %451 = "cute.append_to_rank"(%450, %77) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
            %452 = "cute.get_scalars"(%451) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
            %453 = "cute.assume"(%452) : (i64) -> !cute.i64<divby 2048>
            %454 = "cute.make_stride"(%453) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
            %455 = "cute.make_layout"(%53, %454) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
            "scf.for"(%59, %69, %58) ({
            ^bb0(%arg21: i32):
              %463 = "cute.make_coord"(%arg21) : (i32) -> !cute.coord<"(_,?)">
              %464 = "cute.crd2idx"(%463, %455) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
              %465 = "cute.add_offset"(%442, %464) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
              %466 = "cute.crd2idx"(%463, %52) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
              %467 = "cute.add_offset"(%445, %466) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
              %468 = "cute.crd2idx"(%463, %47) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
              %469 = "cute.add_offset"(%291, %468) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %470 = "builtin.unrealized_conversion_cast"(%469) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %471 = "llvm.load"(%470) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %472 = "llvm.trunc"(%471) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %473 = "cute.recast_iter"(%465) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
              %474 = "cute.recast_iter"(%467) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%474, %473, %472) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "nvvm.cp.async.commit.group"() : () -> ()
            %456 = "arith.addi"(%arg19, %58) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %457 = "arith.cmpi"(%456, %32) <{predicate = 0 : i64}> : (i32, i32) -> i1
            %458 = "arith.select"(%457, %59, %456) : (i1, i32, i32) -> i32
            %459 = "arith.addi"(%arg20, %58) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %460 = "arith.cmpi"(%459, %73) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %461 = "scf.if"(%460) ({
              %462 = "arith.addi"(%arg20, %58) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
              "scf.yield"(%462) : (i32) -> ()
            }, {
              "scf.yield"(%58) : (i32) -> ()
            }) : (i1) -> i32
            "scf.yield"(%458, %461) : (i32, i32) -> ()
          }, {
            "scf.yield"(%arg19, %arg20) : (i32, i32) -> ()
          }) : (i1) -> (i32, i32)
          "scf.yield"(%404#0, %404#1, %434, %435#0, %435#1) : (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32) -> ()
        }) {loop_annotation = #loop_annotation1} : (i32, i32, i32, !memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32) -> (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32)
        "scf.yield"(%402#0, %402#1, %402#2, %402#3, %402#4) : (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32) -> ()
      }) : (i32, i32, i32, !memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32) -> (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32)
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      "llvm.inline_asm"(%58, %68) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %334 = "cute.memref.load_vec"(%327) : (!memref_rmem_f32_1) -> vector<64xf32>
      "cute.memref.store_vec"(%334, %327) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %335 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %336 = "arith.divsi"(%78, %46) : (i32, i32) -> i32
      %337 = "arith.remsi"(%336, %46) : (i32, i32) -> i32
      %338 = "arith.remsi"(%78, %46) : (i32, i32) -> i32
      %339 = "arith.remsi"(%337, %46) : (i32, i32) -> i32
      %340 = "arith.remsi"(%338, %46) : (i32, i32) -> i32
      %341 = "arith.muli"(%339, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %342 = "arith.muli"(%340, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %343 = "cute.assume"(%341) : (i32) -> !cute.i32<divby 4>
      %344 = "cute.assume"(%342) : (i32) -> !cute.i32<divby 4>
      %345 = "cute.make_int_tuple"(%343, %344) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %346 = "cute.add_offset"(%335, %345) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %347 = "cute.memref.alloca"() : () -> !memref_rmem_i8_6
      %348 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %349 = "cute.get_shape"(%348) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %350:2 = "cute.get_leaves"(%349) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
      %351 = "cute.to_int_tuple"(%350#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %352 = "arith.muli"(%79, %75) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %353 = "cute.make_int_tuple"(%352) : (i32) -> !cute.int_tuple<"?">
      %354 = "cute.tuple_sub"(%351, %353) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %355 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %356 = "cute.get_shape"(%355) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %357:2 = "cute.get_leaves"(%356) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
      %358 = "cute.to_int_tuple"(%357#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
      %359 = "arith.muli"(%80, %75) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %360 = "cute.make_int_tuple"(%359) : (i32) -> !cute.int_tuple<"?">
      %361 = "cute.tuple_sub"(%358, %360) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      "scf.for"(%59, %31, %58) ({
      ^bb0(%arg8: i32):
        %388 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"?">
        %389 = "cute.crd2idx"(%388, %30) : (!cute.coord<"?">, !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.int_tuple<"(?,?)">
        %390 = "cute.add_offset"(%346, %389) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %391 = "cute.deref_arith_tuple_iter"(%390) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %392:2 = "cute.get_leaves"(%391) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %393 = "cute.make_coord"(%392#0, %392#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %394 = "cute.make_coord"(%354, %361) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %395:2 = "cute.get_scalars"(%393) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %396:2 = "cute.get_scalars"(%394) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %397 = "arith.cmpi"(%395#0, %396#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %398 = "arith.cmpi"(%395#1, %396#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %399 = "arith.andi"(%397, %398) : (i1, i1) -> i1
        %400 = "arith.extui"(%399) : (i1) -> i8
        %401 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%347, %401, %400) : (!memref_rmem_i8_6, !cute.coord<"?">, i8) -> ()
        "scf.yield"() : () -> ()
      }) : (i32, i32, i32) -> ()
      %362 = "cute.get_iter"(%347) : (!memref_rmem_i8_6) -> !cute.ptr<i8, rmem, align<32>>
      %363 = "cute.append_to_rank"(%324, %77) <{rank = 2 : si32}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">, !cute.layout<"1:0">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %364:2 = "cute.get_scalars"(%363) <{only_dynamic}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> (i64, i64)
      %365 = "cute.assume"(%364#0) : (i64) -> !cute.i64<divby 256>
      %366 = "cute.assume"(%364#1) : (i64) -> !cute.i64<divby 16384>
      %367 = "cute.make_stride"(%365, %366) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %368 = "cute.make_layout"(%29, %367) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,((4,2),(4,2)))">, !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %369 = "cute.append_to_rank"(%368, %77) <{rank = 2 : si32}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">, !cute.layout<"1:0">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %370:2 = "cute.get_scalars"(%369) <{only_dynamic}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> (i64, i64)
      %371 = "cute.assume"(%370#0) : (i64) -> !cute.i64<divby 256>
      %372 = "cute.assume"(%370#1) : (i64) -> !cute.i64<divby 16384>
      %373 = "cute.make_stride"(%371, %372) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %374 = "cute.make_layout"(%27, %373) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(((4,2),(4,2))))">, !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      "scf.for"(%59, %31, %58) ({
      ^bb0(%arg7: i32):
        %375 = "cute.make_coord"(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %376 = "cute.crd2idx"(%375, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
        %377 = "cute.add_offset"(%328, %376) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
        %378 = "cute.crd2idx"(%375, %374) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.int_tuple<"?{i64}">
        %379 = "cute.add_offset"(%320, %378) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %380 = "cute.crd2idx"(%375, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
        %381 = "cute.add_offset"(%362, %380) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %382 = "builtin.unrealized_conversion_cast"(%381) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %383 = "llvm.load"(%382) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %384 = "llvm.icmp"(%383, %26) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%384) ({
          %385 = "builtin.unrealized_conversion_cast"(%377) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %386 = "builtin.unrealized_conversion_cast"(%379) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %387 = "llvm.load"(%385) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%387, %386) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 256, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2, !cuda.stream) -> i32, sym_name = "cutlass___call_____main__SGemm_object_at__Tensorgmemo256641256_Tensorgmemodiv64i64div641_Tensorgmemodiv256i64div2561_functionSGemmlambdaat_CUstream0x0"}> ({
  ^bb0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2, %arg3: !cuda.stream):
    %0 = "arith.constant"() <{value = 24944 : i64}> : () -> i64
    %1 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %3 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %4 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %5 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>
    %6 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>
    %7 = "cute.make_tiled_copy"(%6) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>) -> !copy_ldgsts
    %8 = "cute.make_tiled_copy"(%5) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>) -> !copy_ldgsts1
    %9 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
    %10 = "cute.get_shape"(%9) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
    %11:2 = "cute.get_leaves"(%10) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
    %12 = "cute.to_int_tuple"(%11#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.to_int_tuple"(%11#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
    %14 = "cute.make_int_tuple"(%12, %13) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?,?{div=256})">
    %15:2 = "cute.get_scalars"(%14) <{only_dynamic}> : (!cute.int_tuple<"(?,?{div=256})">) -> (i32, i32)
    %16 = "arith.ceildivsi"(%15#0, %4) : (i32, i32) -> i32
    %17 = "arith.ceildivsi"(%15#1, %4) : (i32, i32) -> i32
    %18 = "cute.make_int_tuple"(%16, %17) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %19:2 = "cute.get_leaves"(%18) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
    %20 = "cute.get_scalars"(%19#0) : (!cute.int_tuple<"?">) -> i32
    %21 = "cute.get_scalars"(%19#1) : (!cute.int_tuple<"?">) -> i32
    %22 = "cuda.launch_cfg.create"(%3, %2, %2, %0, %20, %21, %2, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%22, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%22, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %23 = "cuda.launch_ex"(%22, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %24 = "cuda.cast"(%23) : (!cuda.result) -> i32
    "cuda.return_if_error"(%24) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
