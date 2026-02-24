!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>, layout_copy_tv = <"(256,4):(4,1)">, tiler_mn = <"[128:1;8:1]">>
!copy_ldgsts1 = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>, layout_copy_tv = <"((8,32),1):((32,1),0)">, tiler_mn = <"[32:1;8:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "(256,64):(1,256)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "(?,?{div=64}):(?{i64 div=64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, align<16>, "(?,?{div=256}):(?{i64 div=256},1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, align<16>, "(128,8,8):(1,256,2048)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, align<16>, "(128,8,?):(?{i64 div=64},1,8)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, align<16>, "(128,128):(?{i64 div=256},1)">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, align<16>, "((4,1),1,1,8):((1,0),0,0,2048)">
!memref_gmem_f32_7 = !cute.memref<f32, gmem, "((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
!memref_gmem_f32_8 = !cute.memref<f32, gmem, align<16>, "((4,1),1,1):((1,0),0,0)">
!memref_gmem_f32_9 = !cute.memref<f32, gmem, align<16>, "((4,1),(1,1)):((1,0),(0,0))">
!memref_gmem_f32_10 = !cute.memref<f32, gmem, align<16>, "((4,1)):((1,0))">
!memref_gmem_f32_11 = !cute.memref<f32, gmem, "((1,1),4,1):((0,0),?{i64 div=2048},0)">
!memref_gmem_f32_12 = !cute.memref<f32, gmem, "((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
!memref_gmem_f32_13 = !cute.memref<f32, gmem, "((1,1)):((0,0))">
!memref_gmem_f32_14 = !cute.memref<f32, gmem, align<16>, "(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
!memref_gmem_f32_15 = !cute.memref<f32, gmem, align<16>, "(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
!memref_gmem_f32_16 = !cute.memref<f32, gmem, "(1):(0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, "(1,(4,2),8):(0,(1,4),8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, "(1,(4,2)):(0,(1,4))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, "(4,2):(1,4)">
!memref_rmem_f32_4 = !cute.memref<f32, rmem, "(4):(1)">
!memref_rmem_f32_5 = !cute.memref<f32, rmem, "(1):(0)">
!memref_rmem_f32_6 = !cute.memref<f32, rmem, "(1,((4,2),(4,2))):(0,((1,4),(8,32)))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,1,1):(1,1,1)">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,1)">
!memref_rmem_i8_4 = !cute.memref<i8, rmem, align<32>, "(1,(1,1)):(1,(1,1))">
!memref_rmem_i8_5 = !cute.memref<i8, rmem, "(1):(1)">
!memref_rmem_i8_6 = !cute.memref<i8, rmem, align<32>, "(1,(4,1)):(4,(1,1))">
!memref_rmem_i8_7 = !cute.memref<i8, rmem, "(1):(4)">
!memref_rmem_i8_8 = !cute.memref<i8, rmem, align<32>, "(1,(1,1)):(1,(1,0))">
!memref_rmem_i8_9 = !cute.memref<i8, rmem, align<32>, "(1):(1)">
!memref_rmem_i8_10 = !cute.memref<i8, rmem, align<32>, "(1,(4,1)):(4,(1,0))">
!memref_rmem_i8_11 = !cute.memref<i8, rmem, align<32>, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_rmem_i8_12 = !cute.memref<i8, rmem, align<32>, "(1,((4,2),(4,2))):(0,((1,4),(8,32)))">
!memref_rmem_i8_13 = !cute.memref<i8, rmem, "(1):(0)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(128,8,3):(1,128,1024)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<1024>, "(128,8,3):(1,132,1056)">
!memref_smem_f32_2 = !cute.memref<f32, smem, align<16>, "((4,1),1,1,3):((1,0),0,0,1024)">
!memref_smem_f32_3 = !cute.memref<f32, smem, "((1,1),4,1,3):((0,0),32,0,1056)">
!memref_smem_f32_4 = !cute.memref<f32, smem, align<16>, "((4,1),1,1):((1,0),0,0)">
!memref_smem_f32_5 = !cute.memref<f32, smem, align<16>, "((4,1),(1,1)):((1,0),(0,0))">
!memref_smem_f32_6 = !cute.memref<f32, smem, align<16>, "((4,1)):((1,0))">
!memref_smem_f32_7 = !cute.memref<f32, smem, "((1,1),4,1):((0,0),32,0)">
!memref_smem_f32_8 = !cute.memref<f32, smem, "((1,1),(4,1)):((0,0),(32,0))">
!memref_smem_f32_9 = !cute.memref<f32, smem, "((1,1)):((0,0))">
!memref_smem_f32_10 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8,3):(0,(1,64),128,1024)">
!memref_smem_f32_11 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8,3):(0,(1,64),132,1056)">
!memref_smem_f32_12 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),128)">
!memref_smem_f32_13 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),132)">
!memref_smem_f32_14 = !cute.memref<f32, smem, align<16>, "(1,(4,2)):(0,(1,64))">
!memref_smem_f32_15 = !cute.memref<f32, smem, align<16>, "(4,2):(1,64)">
!memref_smem_f32_16 = !cute.memref<f32, smem, align<16>, "(4):(1)">
!mma_f32_f32_f32_1x1x1_ = !cute.tiled_mma<!cute_nvgpu.atom.universal_fma<1x1x1, (f32, f32) -> f32 >, atom_layout_MNK = <"(16,16,1):(16,1,0)">, permutation_MNK = <"[(16,4):(4,1);(16,4):(4,1);_]">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> (), sym_name = "kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0"}> ({
    ^bb0(%arg4: !memref_gmem_f32_, %arg5: !memref_gmem_f32_1, %arg6: !memref_gmem_f32_2):
      %46 = "cute.static"() : () -> !cute.layout<"(128,8,3):(1,128,1024)">
      %47 = "cute.static"() : () -> !cute.layout<"(128,8,3):(1,132,1056)">
      %48 = "cute.static"() : () -> !copy_ldgsts
      %49 = "cute.static"() : () -> !copy_ldgsts1
      %50 = "cute.static"() : () -> !mma_f32_f32_f32_1x1x1_
      %51 = "cute.static"() : () -> !cute.tile<"[128:1;8:1]">
      %52 = "cute.static"() : () -> !cute.layout<"(256,4):(4,1)">
      %53 = "cute.static"() : () -> !cute.layout<"1:0">
      %54 = "cute.static"() : () -> !cute.layout<"(1,4):(0,1)">
      %55 = "cute.static"() : () -> !cute.layout<"(1,4):(0,1)">
      %56 = "cute.static"() : () -> !cute.tile<"[32:1;8:1]">
      %57 = "cute.static"() : () -> !cute.layout<"((8,32),1):((32,1),0)">
      %58 = "cute.static"() : () -> !cute.layout<"1:0">
      %59 = "cute.static"() : () -> !cute.layout<"(1,1):(0,1)">
      %60 = "cute.static"() : () -> !cute.layout<"(1,1):(0,1)">
      %61 = "cute.static"() : () -> !cute.layout<"(1,16,16,1):(0,16,1,0)">
      %62 = "cute.static"() : () -> !cute.tile<"[(16,4):(4,1);(16,4):(4,1);_]">
      %63 = "cute.static"() : () -> !cute.layout<"1:0">
      %64 = "cute.static"() : () -> !cute.shape<"(1,1,1)">
      %65 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
      %66 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
      %67 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
      %68 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %69 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %70 = "nvvm.read.ptx.sreg.ctaid.y"() <{range = #llvm.constant_range<i32, 0, 65535>}> : () -> i32
      %71 = "cute.make_coord"(%69, %70) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %72:2 = "cute.get_scalars"(%71) <{only_dynamic}> : (!cute.coord<"(?,?,_)">) -> (i32, i32)
      %73 = "cute.make_coord"(%72#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %74 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">
      %75 = "cute.crd2idx"(%73, %74) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">) -> !cute.int_tuple<"?{div=128}">
      %76 = "cute.get_iter"(%arg4) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem, align<16>>
      %77 = "cute.add_offset"(%76, %75) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %78 = "cute.make_view"(%77) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_3
      %79 = "cute.get_iter"(%78) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem, align<16>>
      %80 = "cute.make_coord"(%69, %70) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %81:2 = "cute.get_scalars"(%80) <{only_dynamic}> : (!cute.coord<"(?,?,_)">) -> (i32, i32)
      %82 = "cute.make_coord"(%81#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %83 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %84:3 = "cute.get_scalars"(%83) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> (i32, i32, i64)
      %85 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %86 = "arith.ceildivsi"(%84#0, %85) : (i32, i32) -> i32
      %87 = "arith.constant"() <{value = 128 : i64}> : () -> i64
      %88 = "arith.muli"(%84#2, %87) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %89 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %90 = "arith.ceildivsi"(%84#1, %89) : (i32, i32) -> i32
      %91 = "cute.make_shape"(%86, %90) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %92 = "cute.assume"(%84#2) : (i64) -> !cute.i64<divby 64>
      %93 = "cute.assume"(%88) : (i64) -> !cute.i64<divby 8192>
      %94 = "cute.make_stride"(%92, %93) : (!cute.i64<divby 64>, !cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">
      %95 = "cute.make_layout"(%91, %94) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">
      %96:4 = "cute.get_scalars"(%95) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> (i32, i32, i64, i64)
      %97 = "cute.make_shape"(%96#1) : (i32) -> !cute.shape<"(128,8,?)">
      %98 = "cute.assume"(%96#2) : (i64) -> !cute.i64<divby 64>
      %99 = "cute.make_stride"(%98) : (!cute.i64<divby 64>) -> !cute.stride<"(?{i64 div=64},1,8)">
      %100 = "cute.make_layout"(%97, %99) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(?{i64 div=64},1,8)">) -> !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %101 = "cute.crd2idx"(%82, %95) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.int_tuple<"?{i64 div=8192}">
      %102 = "cute.get_iter"(%arg5) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem, align<16>>
      %103 = "cute.add_offset"(%102, %101) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f32, gmem, align<16>>
      %104 = "cute.make_view"(%103, %100) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">) -> !memref_gmem_f32_4
      %105 = "cute.get_iter"(%104) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem, align<16>>
      %106 = "cute.make_coord"(%69, %70) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %107:2 = "cute.get_scalars"(%106) <{only_dynamic}> : (!cute.coord<"(?,?,_)">) -> (i32, i32)
      %108 = "cute.make_coord"(%107#0, %107#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %109 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %110:3 = "cute.get_scalars"(%109) <{only_dynamic}> : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> (i32, i32, i64)
      %111 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %112 = "arith.ceildivsi"(%110#0, %111) : (i32, i32) -> i32
      %113 = "arith.constant"() <{value = 128 : i64}> : () -> i64
      %114 = "arith.muli"(%110#2, %113) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %115 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %116 = "arith.ceildivsi"(%110#1, %115) : (i32, i32) -> i32
      %117 = "cute.make_shape"(%112, %116) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %118 = "cute.assume"(%110#2) : (i64) -> !cute.i64<divby 256>
      %119 = "cute.assume"(%114) : (i64) -> !cute.i64<divby 32768>
      %120 = "cute.make_stride"(%118, %119) : (!cute.i64<divby 256>, !cute.i64<divby 32768>) -> !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">
      %121 = "cute.make_layout"(%117, %120) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,128),(?,?))">, !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">
      %122:4 = "cute.get_scalars"(%121) <{only_dynamic}> : (!cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> (i32, i32, i64, i64)
      %123 = "cute.static"() : () -> !cute.shape<"(128,128)">
      %124 = "cute.assume"(%122#2) : (i64) -> !cute.i64<divby 256>
      %125 = "cute.make_stride"(%124) : (!cute.i64<divby 256>) -> !cute.stride<"(?{i64 div=256},1)">
      %126 = "cute.make_layout"(%123, %125) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,128)">, !cute.stride<"(?{i64 div=256},1)">) -> !cute.layout<"(128,128):(?{i64 div=256},1)">
      %127 = "cute.crd2idx"(%108, %121) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.int_tuple<"?{i64 div=128}">
      %128 = "cute.get_iter"(%arg6) : (!memref_gmem_f32_2) -> !cute.ptr<f32, gmem, align<16>>
      %129 = "cute.add_offset"(%128, %127) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %130 = "cute.make_view"(%129, %126) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(128,128):(?{i64 div=256},1)">) -> !memref_gmem_f32_5
      %131 = "cute.static"() : () -> !cute.int_tuple<"0">
      %132 = "cute.add_offset"(%79, %131) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem, align<16>>
      %133 = "cute.static"() : () -> !cute.layout<"(128,8,8):(1,256,2048)">
      %134 = "cute.make_view"(%132, %133) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(128,8,8):(1,256,2048)">) -> !memref_gmem_f32_3
      %135 = "cute.static"() : () -> !cute.int_tuple<"0">
      %136 = "cute.add_offset"(%105, %135) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem, align<16>>
      %137 = "cute.get_layout"(%104) : (!memref_gmem_f32_4) -> !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %138 = "cute.make_view"(%136, %137) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">) -> !memref_gmem_f32_4
      %139 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %140 = "cute.static"() : () -> !cute.int_tuple<"12288">
      %141 = "cute.add_offset"(%139, %140) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"12288">) -> !cute.ptr<i8, smem, align<1024>>
      %142 = "cute.recast_iter"(%139) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %143 = "cute.make_view"(%142, %46) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(128,8,3):(1,128,1024)">) -> !memref_smem_f32_
      %144 = "cute.recast_iter"(%141) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<f32, smem, align<1024>>
      %145 = "cute.make_view"(%144, %47) : (!cute.ptr<f32, smem, align<1024>>, !cute.layout<"(128,8,3):(1,132,1056)">) -> !memref_smem_f32_1
      %146 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %147 = "cute.get_iter"(%134) : (!memref_gmem_f32_3) -> !cute.ptr<f32, gmem, align<16>>
      %148 = "cute.get_scalars"(%146) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %149 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %150 = "arith.divsi"(%148, %149) : (i32, i32) -> i32
      %151 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %152 = "arith.remsi"(%148, %151) : (i32, i32) -> i32
      %153 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %154 = "arith.muli"(%152, %153) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %155 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %156 = "arith.muli"(%150, %155) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %157 = "arith.addi"(%154, %156) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %158 = "cute.assume"(%157) : (i32) -> !cute.i32<divby 4>
      %159 = "cute.make_int_tuple"(%158) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %160 = "cute.add_offset"(%147, %159) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %161 = "cute.make_view"(%160) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_6
      %162 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %163 = "cute.get_iter"(%143) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %164 = "cute.get_scalars"(%162) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %165 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %166 = "arith.muli"(%164, %165) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %167 = "cute.assume"(%166) : (i32) -> !cute.i32<divby 4>
      %168 = "cute.make_int_tuple"(%167) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %169 = "cute.add_offset"(%163, %168) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %170 = "cute.make_view"(%169) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_2
      %171 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %172 = "cute.get_iter"(%138) : (!memref_gmem_f32_4) -> !cute.ptr<f32, gmem, align<16>>
      %173 = "cute.get_layout"(%138) : (!memref_gmem_f32_4) -> !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %174:2 = "cute.get_scalars"(%173) <{only_dynamic}> : (!cute.layout<"(128,8,?):(?{i64 div=64},1,8)">) -> (i32, i64)
      %175 = "cute.get_scalars"(%171) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %176 = "arith.constant"() <{value = 32 : i64}> : () -> i64
      %177 = "arith.muli"(%174#1, %176) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %178 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %179 = "arith.divsi"(%175, %178) : (i32, i32) -> i32
      %180 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %181 = "arith.remsi"(%175, %180) : (i32, i32) -> i32
      %182 = "arith.extsi"(%179) : (i32) -> i64
      %183 = "arith.muli"(%182, %174#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %184 = "arith.extsi"(%181) : (i32) -> i64
      %185 = "arith.addi"(%184, %183) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %186 = "cute.make_int_tuple"(%185) : (i64) -> !cute.int_tuple<"?{i64}">
      %187 = "cute.add_offset"(%172, %186) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %188 = "cute.make_shape"(%174#0) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %189 = "cute.assume"(%177) : (i64) -> !cute.i64<divby 2048>
      %190 = "cute.make_stride"(%189) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0,8)">
      %191 = "cute.make_layout"(%188, %190) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),?{i64 div=2048},0,8)">) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %192 = "cute.make_view"(%187, %191) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !memref_gmem_f32_7
      %193 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %194 = "cute.get_iter"(%145) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<1024>>
      %195 = "cute.get_scalars"(%193) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %196 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %197 = "arith.divsi"(%195, %196) : (i32, i32) -> i32
      %198 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %199 = "arith.remsi"(%195, %198) : (i32, i32) -> i32
      %200 = "arith.constant"() <{value = 132 : i32}> : () -> i32
      %201 = "arith.muli"(%199, %200) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %202 = "arith.addi"(%201, %197) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %203 = "cute.make_int_tuple"(%202) : (i32) -> !cute.int_tuple<"?">
      %204 = "cute.add_offset"(%194, %203) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<f32, smem>
      %205 = "cute.make_view"(%204) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_3
      %206 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %207 = "cute.static"() : () -> !cute.layout<"(256,64):(1@0,1@1)">
      %208 = "cute.make_view"(%206, %207) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(256,64):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(256,64):(1@0,1@1)">
      %209 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %210 = "cute.get_shape"(%209) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
      %211:2 = "cute.get_leaves"(%210) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
      %212 = "cute.to_int_tuple"(%211#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %213 = "cute.to_int_tuple"(%211#1) : (!cute.shape<"?{div=64}">) -> !cute.int_tuple<"?{div=64}">
      %214 = "cute.make_shape"(%212, %213) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=64}">) -> !cute.shape<"(?,?{div=64})">
      %215 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %216 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
      %217 = "cute.make_layout"(%214, %216) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=64})">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %218 = "cute.make_view"(%215, %217) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?{div=64}):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,?{div=64}):(1@0,1@1)">
      %219 = "cute.make_coord"(%69, %70) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %220:2 = "cute.get_scalars"(%219) <{only_dynamic}> : (!cute.coord<"(?,?,_)">) -> (i32, i32)
      %221 = "cute.make_coord"(%220#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %222 = "cute.static"() : () -> !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">
      %223 = "cute.crd2idx"(%221, %222) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %224 = "cute.get_iter"(%208) : (!cute.coord_tensor<"(0,0)", "(256,64):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %225 = "cute.add_offset"(%224, %223) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %226 = "cute.make_view"(%225) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.coord_tensor<"(?{div=128},0)", "(128,8,8):(1@0,1@1,8@1)">
      %227 = "cute.get_iter"(%226) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,8):(1@0,1@1,8@1)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %228 = "cute.deref_arith_tuple_iter"(%227) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %229 = "cute.static"() : () -> !cute.int_tuple<"0">
      %230:2 = "cute.get_leaves"(%228) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %231 = "cute.make_coord"(%69, %70) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %232:2 = "cute.get_scalars"(%231) <{only_dynamic}> : (!cute.coord<"(?,?,_)">) -> (i32, i32)
      %233 = "cute.make_coord"(%232#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %234 = "cute.get_layout"(%218) : (!cute.coord_tensor<"(0,0)", "(?,?{div=64}):(1@0,1@1)">) -> !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %235:2 = "cute.get_scalars"(%234) <{only_dynamic}> : (!cute.layout<"(?,?{div=64}):(1@0,1@1)">) -> (i32, i32)
      %236 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %237 = "arith.ceildivsi"(%235#0, %236) : (i32, i32) -> i32
      %238 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %239 = "arith.ceildivsi"(%235#1, %238) : (i32, i32) -> i32
      %240 = "cute.make_shape"(%237, %239) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %241 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(128@0,8@1))">
      %242 = "cute.make_layout"(%240, %241) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((128,8),(?,?))">, !cute.stride<"((1@0,1@1),(128@0,8@1))">) -> !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">
      %243:2 = "cute.get_scalars"(%242) <{only_dynamic}> : (!cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> (i32, i32)
      %244 = "cute.make_shape"(%243#1) : (i32) -> !cute.shape<"(128,8,?)">
      %245 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,8@1)">
      %246 = "cute.make_layout"(%244, %245) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(128,8,?)">, !cute.stride<"(1@0,1@1,8@1)">) -> !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %247 = "cute.crd2idx"(%233, %242) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %248 = "cute.get_iter"(%218) : (!cute.coord_tensor<"(0,0)", "(?,?{div=64}):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %249 = "cute.add_offset"(%248, %247) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %250 = "cute.make_view"(%249, %246) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.layout<"(128,8,?):(1@0,1@1,8@1)">) -> !cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">
      %251 = "cute.get_iter"(%250) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %252 = "cute.deref_arith_tuple_iter"(%251) : (!cute.arith_tuple_iter<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %253 = "cute.static"() : () -> !cute.int_tuple<"0">
      %254:2 = "cute.get_leaves"(%252) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %255 = "cute.make_int_tuple"(%230#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %256 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %257 = "cute.tuple_add"(%255, %256) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %258 = "cute.static"() : () -> !cute.int_tuple<"0">
      %259:2 = "cute.get_leaves"(%257) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %260 = "cute.static"() : () -> !cute.layout<"(128,8,8):(1@0,1@1,8@1)">
      %261 = "cute.make_int_tuple"(%259#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %262 = "cute.make_arith_tuple_iter"(%261) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %263 = "cute.make_view"(%262, %260) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.layout<"(128,8,8):(1@0,1@1,8@1)">) -> !cute.coord_tensor<"(?{div=128},0)", "(128,8,8):(1@0,1@1,8@1)">
      %264 = "cute.make_int_tuple"(%254#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %265 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
      %266 = "cute.tuple_add"(%264, %265) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %267 = "cute.static"() : () -> !cute.int_tuple<"0">
      %268:2 = "cute.get_leaves"(%266) : (!cute.int_tuple<"(?{div=128},0)">) -> (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"0">)
      %269 = "cute.get_layout"(%250) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">) -> !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %270 = "cute.make_int_tuple"(%268#0) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %271 = "cute.make_arith_tuple_iter"(%270) : (!cute.int_tuple<"(?{div=128},0)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %272 = "cute.make_view"(%271, %269) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.layout<"(128,8,?):(1@0,1@1,8@1)">) -> !cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">
      %273 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %274 = "cute.get_iter"(%263) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,8):(1@0,1@1,8@1)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %275 = "cute.get_scalars"(%273) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %276 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %277 = "arith.divsi"(%275, %276) : (i32, i32) -> i32
      %278 = "arith.constant"() <{value = 32 : i32}> : () -> i32
      %279 = "arith.remsi"(%275, %278) : (i32, i32) -> i32
      %280 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %281 = "arith.muli"(%279, %280) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %282 = "cute.assume"(%281) : (i32) -> !cute.i32<divby 4>
      %283 = "cute.make_int_tuple"(%282, %277) : (!cute.i32<divby 4>, i32) -> !cute.int_tuple<"(?{div=4},?)">
      %284 = "cute.add_offset"(%274, %283) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?{div=4},?)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
      %285 = "cute.make_view"(%284) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.coord_tensor<"(?{div=4},?)", "((4,1),1,1,8):((1@0,0),0,0,8@1)">
      %286 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %287 = "cute.get_iter"(%272) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">) -> !cute.arith_tuple_iter<"(?{div=128},0)">
      %288 = "cute.get_layout"(%272) : (!cute.coord_tensor<"(?{div=128},0)", "(128,8,?):(1@0,1@1,8@1)">) -> !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %289 = "cute.get_scalars"(%288) <{only_dynamic}> : (!cute.layout<"(128,8,?):(1@0,1@1,8@1)">) -> i32
      %290 = "cute.get_scalars"(%286) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %291 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %292 = "arith.divsi"(%290, %291) : (i32, i32) -> i32
      %293 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %294 = "arith.remsi"(%290, %293) : (i32, i32) -> i32
      %295 = "cute.make_int_tuple"(%292, %294) : (i32, i32) -> !cute.int_tuple<"(?,?)">
      %296 = "cute.add_offset"(%287, %295) : (!cute.arith_tuple_iter<"(?{div=128},0)">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
      %297 = "cute.make_shape"(%289) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %298 = "cute.static"() : () -> !cute.stride<"((0,0),32@0,0,8@1)">
      %299 = "cute.make_layout"(%297, %298) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1,?)">, !cute.stride<"((0,0),32@0,0,8@1)">) -> !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
      %300 = "cute.make_view"(%296, %299) : (!cute.arith_tuple_iter<"(?,?)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.coord_tensor<"(?,?)", "((1,1),4,1,?):((0,0),32@0,0,8@1)">
      %301 = "cute.static"() : () -> !cute.layout<"(1,1,1):(1,1,0)">
      %302 = "cute.memref.alloca"(%301) : (!cute.layout<"(1,1,1):(1,1,0)">) -> !memref_rmem_i8_
      %303 = "cute.static"() : () -> !cute.layout<"(1,4,1):(4,1,0)">
      %304 = "cute.memref.alloca"(%303) : (!cute.layout<"(1,4,1):(4,1,0)">) -> !memref_rmem_i8_1
      %305 = "cute.static"() : () -> !cute.layout<"(1,1,1):(1,1,1)">
      %306 = "cute.memref.alloca"(%305) : (!cute.layout<"(1,1,1):(1,1,1)">) -> !memref_rmem_i8_2
      %307 = "cute.static"() : () -> !cute.layout<"(1,4,1):(4,1,1)">
      %308 = "cute.memref.alloca"(%307) : (!cute.layout<"(1,4,1):(4,1,1)">) -> !memref_rmem_i8_3
      %309 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %310 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %311 = "scf.for"(%309, %310, %310, %302) ({
      ^bb0(%arg61: i32, %arg62: !memref_rmem_i8_):
        %1300 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1301 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1302 = "scf.for"(%1300, %1301, %1301, %arg62) ({
        ^bb0(%arg63: i32, %arg64: !memref_rmem_i8_):
          %1303 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
          %1304 = "cute.get_iter"(%285) : (!cute.coord_tensor<"(?{div=4},?)", "((4,1),1,1,8):((1@0,0),0,0,8@1)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
          %1305 = "cute.add_offset"(%1304, %1303) : (!cute.arith_tuple_iter<"(?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
          %1306 = "cute.make_view"(%1305) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.coord_tensor<"(?{div=4},?)", "():()">
          %1307 = "cute.get_iter"(%1306) : (!cute.coord_tensor<"(?{div=4},?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
          %1308 = "cute.deref_arith_tuple_iter"(%1307) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
          %1309:2 = "cute.get_leaves"(%1308) : (!cute.int_tuple<"(?{div=4},?)">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
          %1310 = "cute.make_coord"(%1309#0) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"?{div=4}">
          %1311 = "cute.static"() : () -> !cute.coord<"256">
          %1312 = "cute.get_scalars"(%1310) : (!cute.coord<"?{div=4}">) -> i32
          %1313 = "cute.get_scalars"(%1311) : (!cute.coord<"256">) -> i32
          %1314 = "arith.constant"() <{value = true}> : () -> i1
          %1315 = "arith.cmpi"(%1312, %1313) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %1316 = "arith.andi"(%1314, %1315) : (i1, i1) -> i1
          %1317 = "arith.extui"(%1316) : (i1) -> i8
          %1318 = "cute.make_coord"(%arg61, %arg63) : (i32, i32) -> !cute.coord<"(?,?,0)">
          "cute.memref.store"(%arg64, %1318, %1317) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
          "scf.yield"(%arg64) : (!memref_rmem_i8_) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
        "scf.yield"(%1302) : (!memref_rmem_i8_) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
      %312 = "cute.get_iter"(%311) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %313 = "scf.for"(%309, %310, %310, %304) ({
      ^bb0(%arg57: i32, %arg58: !memref_rmem_i8_1):
        %1274 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1275 = "arith.constant"() <{value = 4 : i32}> : () -> i32
        %1276 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1277 = "scf.for"(%1274, %1275, %1276, %arg58) ({
        ^bb0(%arg59: i32, %arg60: !memref_rmem_i8_1):
          %1278 = "cute.make_coord"(%arg57, %arg59) : (i32, i32) -> !cute.coord<"((0,?),?,0,0)">
          %1279 = "cute.get_layout"(%300) : (!cute.coord_tensor<"(?,?)", "((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
          %1280 = "cute.crd2idx"(%1278, %1279) : (!cute.coord<"((0,?),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
          %1281 = "cute.get_iter"(%300) : (!cute.coord_tensor<"(?,?)", "((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.arith_tuple_iter<"(?,?)">
          %1282 = "cute.add_offset"(%1281, %1280) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
          %1283 = "cute.make_view"(%1282) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %1284 = "cute.get_iter"(%1283) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %1285 = "cute.deref_arith_tuple_iter"(%1284) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %1286:2 = "cute.get_leaves"(%1285) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %1287 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
          %1288 = "cute.get_shape"(%1287) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
          %1289:2 = "cute.get_leaves"(%1288) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
          %1290 = "cute.to_int_tuple"(%1289#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %1291 = "cute.make_coord"(%1286#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1292 = "cute.make_coord"(%1290) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1293 = "cute.get_scalars"(%1291) : (!cute.coord<"?">) -> i32
          %1294 = "cute.get_scalars"(%1292) : (!cute.coord<"?">) -> i32
          %1295 = "arith.constant"() <{value = true}> : () -> i1
          %1296 = "arith.cmpi"(%1293, %1294) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %1297 = "arith.andi"(%1295, %1296) : (i1, i1) -> i1
          %1298 = "arith.extui"(%1297) : (i1) -> i8
          %1299 = "cute.make_coord"(%arg57, %arg59) : (i32, i32) -> !cute.coord<"(?,?,0)">
          "cute.memref.store"(%arg60, %1299, %1298) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
          "scf.yield"(%arg60) : (!memref_rmem_i8_1) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_1) -> !memref_rmem_i8_1
        "scf.yield"(%1277) : (!memref_rmem_i8_1) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_1) -> !memref_rmem_i8_1
      %314 = "cute.get_iter"(%313) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %315 = "scf.for"(%309, %310, %310, %306) ({
      ^bb0(%arg51: i32, %arg52: !memref_rmem_i8_2):
        %1249 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1250 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1251 = "scf.for"(%1249, %1250, %1250, %arg52) ({
        ^bb0(%arg53: i32, %arg54: !memref_rmem_i8_2):
          %1252 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1253 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %1254 = "scf.for"(%1252, %1253, %1253, %arg54) ({
          ^bb0(%arg55: i32, %arg56: !memref_rmem_i8_2):
            %1255 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
            %1256 = "cute.get_iter"(%285) : (!cute.coord_tensor<"(?{div=4},?)", "((4,1),1,1,8):((1@0,0),0,0,8@1)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
            %1257 = "cute.add_offset"(%1256, %1255) : (!cute.arith_tuple_iter<"(?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
            %1258 = "cute.make_view"(%1257) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.coord_tensor<"(?{div=4},?)", "():()">
            %1259 = "cute.get_iter"(%1258) : (!cute.coord_tensor<"(?{div=4},?)", "():()">) -> !cute.arith_tuple_iter<"(?{div=4},?)">
            %1260 = "cute.deref_arith_tuple_iter"(%1259) : (!cute.arith_tuple_iter<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
            %1261:2 = "cute.get_leaves"(%1260) : (!cute.int_tuple<"(?{div=4},?)">) -> (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
            %1262 = "arith.constant"() <{value = -1 : i32}> : () -> i32
            %1263 = "cute.make_coord"(%1261#0, %1262) : (!cute.int_tuple<"?{div=4}">, i32) -> !cute.coord<"(?{div=4},?)">
            %1264 = "cute.make_coord"(%1261#1) : (!cute.int_tuple<"?">) -> !cute.coord<"(256,?)">
            %1265:2 = "cute.get_scalars"(%1263) : (!cute.coord<"(?{div=4},?)">) -> (i32, i32)
            %1266:2 = "cute.get_scalars"(%1264) : (!cute.coord<"(256,?)">) -> (i32, i32)
            %1267 = "arith.constant"() <{value = true}> : () -> i1
            %1268 = "arith.cmpi"(%1265#0, %1266#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %1269 = "arith.andi"(%1267, %1268) : (i1, i1) -> i1
            %1270 = "arith.cmpi"(%1265#1, %1266#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %1271 = "arith.andi"(%1269, %1270) : (i1, i1) -> i1
            %1272 = "arith.extui"(%1271) : (i1) -> i8
            %1273 = "cute.make_coord"(%arg51, %arg53, %arg55) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
            "cute.memref.store"(%arg56, %1273, %1272) : (!memref_rmem_i8_2, !cute.coord<"(?,?,?)">, i8) -> ()
            "scf.yield"(%arg56) : (!memref_rmem_i8_2) -> ()
          }) : (i32, i32, i32, !memref_rmem_i8_2) -> !memref_rmem_i8_2
          "scf.yield"(%1254) : (!memref_rmem_i8_2) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_2) -> !memref_rmem_i8_2
        "scf.yield"(%1251) : (!memref_rmem_i8_2) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_2) -> !memref_rmem_i8_2
      %316 = "cute.get_iter"(%315) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
      %317 = "scf.for"(%309, %310, %310, %308) ({
      ^bb0(%arg45: i32, %arg46: !memref_rmem_i8_3):
        %1217 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1218 = "arith.constant"() <{value = 4 : i32}> : () -> i32
        %1219 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1220 = "scf.for"(%1217, %1218, %1219, %arg46) ({
        ^bb0(%arg47: i32, %arg48: !memref_rmem_i8_3):
          %1221 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1222 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %1223 = "scf.for"(%1221, %1222, %1222, %arg48) ({
          ^bb0(%arg49: i32, %arg50: !memref_rmem_i8_3):
            %1224 = "cute.make_coord"(%arg45, %arg47, %arg49) : (i32, i32, i32) -> !cute.coord<"((0,?),?,?,0)">
            %1225 = "cute.get_layout"(%300) : (!cute.coord_tensor<"(?,?)", "((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
            %1226 = "cute.crd2idx"(%1224, %1225) : (!cute.coord<"((0,?),?,?,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
            %1227 = "cute.get_iter"(%300) : (!cute.coord_tensor<"(?,?)", "((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.arith_tuple_iter<"(?,?)">
            %1228 = "cute.add_offset"(%1227, %1226) : (!cute.arith_tuple_iter<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.arith_tuple_iter<"(?,?)">
            %1229 = "cute.make_view"(%1228) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
            %1230 = "cute.get_iter"(%1229) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
            %1231 = "cute.deref_arith_tuple_iter"(%1230) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
            %1232:2 = "cute.get_leaves"(%1231) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
            %1233 = "cute.get_layout"(%arg5) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
            %1234 = "cute.get_shape"(%1233) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
            %1235:2 = "cute.get_leaves"(%1234) : (!cute.shape<"(?,?{div=64})">) -> (!cute.shape<"?">, !cute.shape<"?{div=64}">)
            %1236 = "cute.to_int_tuple"(%1235#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
            %1237 = "arith.constant"() <{value = -1 : i32}> : () -> i32
            %1238 = "cute.make_coord"(%1232#0, %1237) : (!cute.int_tuple<"?">, i32) -> !cute.coord<"(?,?)">
            %1239 = "cute.make_coord"(%1236, %1232#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
            %1240:2 = "cute.get_scalars"(%1238) : (!cute.coord<"(?,?)">) -> (i32, i32)
            %1241:2 = "cute.get_scalars"(%1239) : (!cute.coord<"(?,?)">) -> (i32, i32)
            %1242 = "arith.constant"() <{value = true}> : () -> i1
            %1243 = "arith.cmpi"(%1240#0, %1241#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %1244 = "arith.andi"(%1242, %1243) : (i1, i1) -> i1
            %1245 = "arith.cmpi"(%1240#1, %1241#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %1246 = "arith.andi"(%1244, %1245) : (i1, i1) -> i1
            %1247 = "arith.extui"(%1246) : (i1) -> i8
            %1248 = "cute.make_coord"(%arg45, %arg47, %arg49) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
            "cute.memref.store"(%arg50, %1248, %1247) : (!memref_rmem_i8_3, !cute.coord<"(?,?,?)">, i8) -> ()
            "scf.yield"(%arg50) : (!memref_rmem_i8_3) -> ()
          }) : (i32, i32, i32, !memref_rmem_i8_3) -> !memref_rmem_i8_3
          "scf.yield"(%1223) : (!memref_rmem_i8_3) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_3) -> !memref_rmem_i8_3
        "scf.yield"(%1220) : (!memref_rmem_i8_3) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_3) -> !memref_rmem_i8_3
      %318 = "cute.get_iter"(%317) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
      %319 = "cute.make_coord"(%309) : (i32) -> !cute.coord<"(_,_,_,?)">
      %320 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
      %321 = "cute.crd2idx"(%319, %320) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %322 = "cute.get_iter"(%161) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem, align<16>>
      %323 = "cute.add_offset"(%322, %321) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
      %324 = "cute.make_view"(%323) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_8
      %325 = "cute.get_iter"(%324) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
      %326 = "cute.static"() : () -> !cute.int_tuple<"0">
      %327 = "cute.get_iter"(%170) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<16>>
      %328 = "cute.add_offset"(%327, %326) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
      %329 = "cute.make_view"(%328) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_4
      %330 = "cute.get_iter"(%329) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
      %331 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
      %332 = "cute.make_view"(%325, %331) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_gmem_f32_8
      %333 = "cute.get_iter"(%332) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
      %334 = "cute.make_view"(%333) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_9
      %335 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
      %336 = "cute.make_view"(%330, %335) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_smem_f32_4
      %337 = "cute.get_iter"(%336) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
      %338 = "cute.make_view"(%337) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_5
      %339 = "cute.static"() : () -> !cute.layout<"(1,1,1):(1,1,1)">
      %340 = "cute.make_view"(%316, %339) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,1,1):(1,1,1)">) -> !memref_rmem_i8_2
      %341 = "cute.get_iter"(%340) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
      %342 = "cute.make_view"(%341) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_4
      %343 = "cute.static"() : () -> !cute.layout<"1:0">
      %344 = "cute.get_iter"(%334) : (!memref_gmem_f32_9) -> !cute.ptr<f32, gmem, align<16>>
      %345 = "cute.get_iter"(%338) : (!memref_smem_f32_5) -> !cute.ptr<f32, smem, align<16>>
      %346 = "cute.get_iter"(%342) : (!memref_rmem_i8_4) -> !cute.ptr<i8, rmem, align<32>>
      %347 = "cute.static"() : () -> !cute.layout<"(1,((1,1))):(1,((1,1)))">
      %348 = "cute.static"() : () -> !cute.int_tuple<"1">
      %349 = "cute.get_scalars"(%348) : (!cute.int_tuple<"1">) -> i32
      %350 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %351 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%350, %349, %351) ({
      ^bb0(%arg44: i32):
        %1196 = "cute.make_coord"(%arg44) : (i32) -> !cute.coord<"(_,?)">
        %1197 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
        %1198 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1199 = "cute.add_offset"(%344, %1198) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem, align<16>>
        %1200 = "cute.make_view"(%1199, %1197) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_gmem_f32_10
        %1201 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
        %1202 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1203 = "cute.add_offset"(%345, %1202) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
        %1204 = "cute.make_view"(%1203, %1201) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_smem_f32_6
        %1205 = "cute.static"() : () -> !cute.layout<"(1):(1)">
        %1206 = "cute.crd2idx"(%1196, %347) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((1,1))):(1,((1,1)))">) -> !cute.int_tuple<"?">
        %1207 = "cute.add_offset"(%346, %1206) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %1208 = "cute.make_view"(%1207, %1205) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(1)">) -> !memref_rmem_i8_5
        %1209 = "cute.get_iter"(%1200) : (!memref_gmem_f32_10) -> !cute.ptr<f32, gmem, align<16>>
        %1210 = "cute.get_iter"(%1204) : (!memref_smem_f32_6) -> !cute.ptr<f32, smem, align<16>>
        %1211 = "cute.get_iter"(%1208) : (!memref_rmem_i8_5) -> !cute.ptr<i8, rmem>
        %1212 = "builtin.unrealized_conversion_cast"(%1211) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1213 = "llvm.load"(%1212) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1214 = "llvm.trunc"(%1213) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %1215 = "cute.recast_iter"(%1209) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
        %1216 = "cute.recast_iter"(%1210) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%1216, %1215, %1214) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %352 = "cute.make_coord"(%309) : (i32) -> !cute.coord<"(_,_,_,?)">
      %353 = "cute.get_layout"(%192) : (!memref_gmem_f32_7) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %354:2 = "cute.get_scalars"(%353) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
      %355 = "cute.static"() : () -> !cute.shape<"((1,1),4,1)">
      %356 = "cute.assume"(%354#1) : (i64) -> !cute.i64<divby 2048>
      %357 = "cute.make_stride"(%356) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %358 = "cute.make_layout"(%355, %357) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %359 = "cute.crd2idx"(%352, %353) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
      %360 = "cute.get_iter"(%192) : (!memref_gmem_f32_7) -> !cute.ptr<f32, gmem>
      %361 = "cute.add_offset"(%360, %359) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %362 = "cute.make_view"(%361, %358) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
      %363 = "cute.get_iter"(%362) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
      %364 = "cute.static"() : () -> !cute.int_tuple<"0">
      %365 = "cute.get_iter"(%205) : (!memref_smem_f32_3) -> !cute.ptr<f32, smem>
      %366 = "cute.add_offset"(%365, %364) : (!cute.ptr<f32, smem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem>
      %367 = "cute.make_view"(%366) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_7
      %368 = "cute.get_iter"(%367) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
      %369 = "cute.get_layout"(%362) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %370 = "cute.static"() : () -> !cute.layout<"1:0">
      %371 = "cute.append_to_rank"(%369, %370) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %372 = "cute.make_view"(%363, %371) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
      %373 = "cute.get_iter"(%372) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
      %374 = "cute.get_layout"(%372) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %375 = "cute.get_scalars"(%374) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
      %376 = "cute.static"() : () -> !cute.shape<"((1,1),(4,1))">
      %377 = "cute.assume"(%375) : (i64) -> !cute.i64<divby 2048>
      %378 = "cute.make_stride"(%377) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %379 = "cute.make_layout"(%376, %378) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %380 = "cute.make_view"(%373, %379) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> !memref_gmem_f32_12
      %381 = "cute.static"() : () -> !cute.layout<"((1,1),4,1):((0,0),32,0)">
      %382 = "cute.make_view"(%368, %381) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1),4,1):((0,0),32,0)">) -> !memref_smem_f32_7
      %383 = "cute.get_iter"(%382) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
      %384 = "cute.make_view"(%383) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_8
      %385 = "cute.static"() : () -> !cute.layout<"(1,4,1):(4,1,1)">
      %386 = "cute.make_view"(%318, %385) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,4,1):(4,1,1)">) -> !memref_rmem_i8_3
      %387 = "cute.get_iter"(%386) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem, align<32>>
      %388 = "cute.make_view"(%387) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_6
      %389 = "cute.static"() : () -> !cute.layout<"1:0">
      %390 = "cute.get_iter"(%380) : (!memref_gmem_f32_12) -> !cute.ptr<f32, gmem>
      %391 = "cute.get_iter"(%384) : (!memref_smem_f32_8) -> !cute.ptr<f32, smem>
      %392 = "cute.get_layout"(%380) : (!memref_gmem_f32_12) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %393 = "cute.append_to_rank"(%392, %389) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %394 = "cute.get_scalars"(%393) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
      %395 = "cute.static"() : () -> !cute.shape<"((1,1),((4,1)))">
      %396 = "cute.assume"(%394) : (i64) -> !cute.i64<divby 2048>
      %397 = "cute.make_stride"(%396) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %398 = "cute.make_layout"(%395, %397) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      %399 = "cute.static"() : () -> !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
      %400 = "cute.get_iter"(%388) : (!memref_rmem_i8_6) -> !cute.ptr<i8, rmem, align<32>>
      %401 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,1)))">
      %402 = "cute.static"() : () -> !cute.int_tuple<"4">
      %403 = "cute.get_scalars"(%402) : (!cute.int_tuple<"4">) -> i32
      %404 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %405 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%404, %403, %405) ({
      ^bb0(%arg43: i32):
        %1175 = "cute.make_coord"(%arg43) : (i32) -> !cute.coord<"(_,?)">
        %1176 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
        %1177 = "cute.crd2idx"(%1175, %398) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
        %1178 = "cute.add_offset"(%390, %1177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
        %1179 = "cute.make_view"(%1178, %1176) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_gmem_f32_13
        %1180 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
        %1181 = "cute.crd2idx"(%1175, %399) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
        %1182 = "cute.add_offset"(%391, %1181) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
        %1183 = "cute.make_view"(%1182, %1180) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_smem_f32_9
        %1184 = "cute.static"() : () -> !cute.layout<"(1):(4)">
        %1185 = "cute.crd2idx"(%1175, %401) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,1)))">) -> !cute.int_tuple<"?">
        %1186 = "cute.add_offset"(%400, %1185) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %1187 = "cute.make_view"(%1186, %1184) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(4)">) -> !memref_rmem_i8_7
        %1188 = "cute.get_iter"(%1179) : (!memref_gmem_f32_13) -> !cute.ptr<f32, gmem>
        %1189 = "cute.get_iter"(%1183) : (!memref_smem_f32_9) -> !cute.ptr<f32, smem>
        %1190 = "cute.get_iter"(%1187) : (!memref_rmem_i8_7) -> !cute.ptr<i8, rmem>
        %1191 = "builtin.unrealized_conversion_cast"(%1190) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %1192 = "llvm.load"(%1191) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %1193 = "llvm.trunc"(%1192) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
        %1194 = "cute.recast_iter"(%1188) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
        %1195 = "cute.recast_iter"(%1189) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
        "cute_nvgpu.arch.copy.SM80.cp_async"(%1195, %1194, %1193) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %406 = "arith.constant"() <{value = true}> : () -> i1
      %407 = "scf.if"(%406) ({
        %1174 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.yield"(%1174) : (i32) -> ()
      }, {
        %1173 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        "scf.yield"(%1173) : (i32) -> ()
      }) : (i1) -> i32
      %408 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %409 = "scf.for"(%310, %408, %310, %407) ({
      ^bb0(%arg39: i32, %arg40: i32):
        %1033 = "arith.constant"() <{value = 8 : i32}> : () -> i32
        %1034 = "arith.cmpi"(%arg39, %1033) <{predicate = 2 : i64}> : (i32, i32) -> i1
        "scf.if"(%1034) ({
          %1042 = "cute.make_coord"(%arg40) : (i32) -> !cute.coord<"(_,_,_,?)">
          %1043 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
          %1044 = "cute.crd2idx"(%1042, %1043) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %1045 = "cute.get_iter"(%161) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem, align<16>>
          %1046 = "cute.add_offset"(%1045, %1044) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
          %1047 = "cute.make_view"(%1046) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_8
          %1048 = "cute.get_iter"(%1047) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
          %1049 = "cute.make_coord"(%arg39) : (i32) -> !cute.coord<"(_,_,_,?)">
          %1050 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">
          %1051 = "cute.crd2idx"(%1049, %1050) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %1052 = "cute.get_iter"(%170) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<16>>
          %1053 = "cute.add_offset"(%1052, %1051) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
          %1054 = "cute.make_view"(%1053) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_4
          %1055 = "cute.get_iter"(%1054) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
          %1056 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
          %1057 = "cute.make_view"(%1048, %1056) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_gmem_f32_8
          %1058 = "cute.get_iter"(%1057) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
          %1059 = "cute.make_view"(%1058) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_9
          %1060 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
          %1061 = "cute.make_view"(%1055, %1060) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_smem_f32_4
          %1062 = "cute.get_iter"(%1061) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
          %1063 = "cute.make_view"(%1062) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_5
          %1064 = "cute.static"() : () -> !cute.layout<"(1,1,1):(1,1,0)">
          %1065 = "cute.make_view"(%312, %1064) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,1,1):(1,1,0)">) -> !memref_rmem_i8_
          %1066 = "cute.get_iter"(%1065) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %1067 = "cute.make_view"(%1066) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_8
          %1068 = "cute.static"() : () -> !cute.layout<"1:0">
          %1069 = "cute.get_iter"(%1059) : (!memref_gmem_f32_9) -> !cute.ptr<f32, gmem, align<16>>
          %1070 = "cute.get_iter"(%1063) : (!memref_smem_f32_5) -> !cute.ptr<f32, smem, align<16>>
          %1071 = "cute.get_iter"(%1067) : (!memref_rmem_i8_8) -> !cute.ptr<i8, rmem, align<32>>
          %1072 = "cute.static"() : () -> !cute.int_tuple<"1">
          %1073 = "cute.get_scalars"(%1072) : (!cute.int_tuple<"1">) -> i32
          %1074 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1075 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%1074, %1073, %1075) ({
          ^bb0(%arg42: i32):
            %1153 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
            %1154 = "cute.static"() : () -> !cute.int_tuple<"0">
            %1155 = "cute.add_offset"(%1069, %1154) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem, align<16>>
            %1156 = "cute.make_view"(%1155, %1153) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_gmem_f32_10
            %1157 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
            %1158 = "cute.static"() : () -> !cute.int_tuple<"0">
            %1159 = "cute.add_offset"(%1070, %1158) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
            %1160 = "cute.make_view"(%1159, %1157) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_smem_f32_6
            %1161 = "cute.static"() : () -> !cute.layout<"(1):(1)">
            %1162 = "cute.static"() : () -> !cute.int_tuple<"0">
            %1163 = "cute.add_offset"(%1071, %1162) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %1164 = "cute.make_view"(%1163, %1161) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1):(1)">) -> !memref_rmem_i8_9
            %1165 = "cute.get_iter"(%1156) : (!memref_gmem_f32_10) -> !cute.ptr<f32, gmem, align<16>>
            %1166 = "cute.get_iter"(%1160) : (!memref_smem_f32_6) -> !cute.ptr<f32, smem, align<16>>
            %1167 = "cute.get_iter"(%1164) : (!memref_rmem_i8_9) -> !cute.ptr<i8, rmem, align<32>>
            %1168 = "builtin.unrealized_conversion_cast"(%1167) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
            %1169 = "llvm.load"(%1168) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
            %1170 = "llvm.trunc"(%1169) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
            %1171 = "cute.recast_iter"(%1165) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
            %1172 = "cute.recast_iter"(%1166) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
            "cute_nvgpu.arch.copy.SM80.cp_async"(%1172, %1171, %1170) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %1076 = "cute.make_coord"(%arg40) : (i32) -> !cute.coord<"(_,_,_,?)">
          %1077 = "cute.get_layout"(%192) : (!memref_gmem_f32_7) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
          %1078:2 = "cute.get_scalars"(%1077) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
          %1079 = "cute.static"() : () -> !cute.shape<"((1,1),4,1)">
          %1080 = "cute.assume"(%1078#1) : (i64) -> !cute.i64<divby 2048>
          %1081 = "cute.make_stride"(%1080) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
          %1082 = "cute.make_layout"(%1079, %1081) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
          %1083 = "cute.crd2idx"(%1076, %1077) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
          %1084 = "cute.get_iter"(%192) : (!memref_gmem_f32_7) -> !cute.ptr<f32, gmem>
          %1085 = "cute.add_offset"(%1084, %1083) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
          %1086 = "cute.make_view"(%1085, %1082) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
          %1087 = "cute.get_iter"(%1086) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
          %1088 = "cute.make_coord"(%arg39) : (i32) -> !cute.coord<"(_,_,_,?)">
          %1089 = "cute.static"() : () -> !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">
          %1090 = "cute.crd2idx"(%1088, %1089) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
          %1091 = "cute.get_iter"(%205) : (!memref_smem_f32_3) -> !cute.ptr<f32, smem>
          %1092 = "cute.add_offset"(%1091, %1090) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
          %1093 = "cute.make_view"(%1092) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_7
          %1094 = "cute.get_iter"(%1093) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
          %1095 = "cute.get_layout"(%1086) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
          %1096 = "cute.static"() : () -> !cute.layout<"1:0">
          %1097 = "cute.append_to_rank"(%1095, %1096) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
          %1098 = "cute.make_view"(%1087, %1097) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
          %1099 = "cute.get_iter"(%1098) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
          %1100 = "cute.get_layout"(%1098) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
          %1101 = "cute.get_scalars"(%1100) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
          %1102 = "cute.static"() : () -> !cute.shape<"((1,1),(4,1))">
          %1103 = "cute.assume"(%1101) : (i64) -> !cute.i64<divby 2048>
          %1104 = "cute.make_stride"(%1103) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
          %1105 = "cute.make_layout"(%1102, %1104) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
          %1106 = "cute.make_view"(%1099, %1105) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> !memref_gmem_f32_12
          %1107 = "cute.static"() : () -> !cute.layout<"((1,1),4,1):((0,0),32,0)">
          %1108 = "cute.make_view"(%1094, %1107) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1),4,1):((0,0),32,0)">) -> !memref_smem_f32_7
          %1109 = "cute.get_iter"(%1108) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
          %1110 = "cute.make_view"(%1109) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_8
          %1111 = "cute.static"() : () -> !cute.layout<"(1,4,1):(4,1,0)">
          %1112 = "cute.make_view"(%314, %1111) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,4,1):(4,1,0)">) -> !memref_rmem_i8_1
          %1113 = "cute.get_iter"(%1112) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
          %1114 = "cute.make_view"(%1113) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_10
          %1115 = "cute.static"() : () -> !cute.layout<"1:0">
          %1116 = "cute.get_iter"(%1106) : (!memref_gmem_f32_12) -> !cute.ptr<f32, gmem>
          %1117 = "cute.get_iter"(%1110) : (!memref_smem_f32_8) -> !cute.ptr<f32, smem>
          %1118 = "cute.get_layout"(%1106) : (!memref_gmem_f32_12) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
          %1119 = "cute.append_to_rank"(%1118, %1115) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
          %1120 = "cute.get_scalars"(%1119) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
          %1121 = "cute.static"() : () -> !cute.shape<"((1,1),((4,1)))">
          %1122 = "cute.assume"(%1120) : (i64) -> !cute.i64<divby 2048>
          %1123 = "cute.make_stride"(%1122) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
          %1124 = "cute.make_layout"(%1121, %1123) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
          %1125 = "cute.static"() : () -> !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
          %1126 = "cute.get_iter"(%1114) : (!memref_rmem_i8_10) -> !cute.ptr<i8, rmem, align<32>>
          %1127 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,0)))">
          %1128 = "cute.static"() : () -> !cute.int_tuple<"4">
          %1129 = "cute.get_scalars"(%1128) : (!cute.int_tuple<"4">) -> i32
          %1130 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1131 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%1130, %1129, %1131) ({
          ^bb0(%arg41: i32):
            %1132 = "cute.make_coord"(%arg41) : (i32) -> !cute.coord<"(_,?)">
            %1133 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
            %1134 = "cute.crd2idx"(%1132, %1124) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
            %1135 = "cute.add_offset"(%1116, %1134) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
            %1136 = "cute.make_view"(%1135, %1133) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_gmem_f32_13
            %1137 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
            %1138 = "cute.crd2idx"(%1132, %1125) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
            %1139 = "cute.add_offset"(%1117, %1138) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
            %1140 = "cute.make_view"(%1139, %1137) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_smem_f32_9
            %1141 = "cute.static"() : () -> !cute.layout<"(1):(4)">
            %1142 = "cute.crd2idx"(%1132, %1127) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
            %1143 = "cute.add_offset"(%1126, %1142) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %1144 = "cute.make_view"(%1143, %1141) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(4)">) -> !memref_rmem_i8_7
            %1145 = "cute.get_iter"(%1136) : (!memref_gmem_f32_13) -> !cute.ptr<f32, gmem>
            %1146 = "cute.get_iter"(%1140) : (!memref_smem_f32_9) -> !cute.ptr<f32, smem>
            %1147 = "cute.get_iter"(%1144) : (!memref_rmem_i8_7) -> !cute.ptr<i8, rmem>
            %1148 = "builtin.unrealized_conversion_cast"(%1147) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
            %1149 = "llvm.load"(%1148) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
            %1150 = "llvm.trunc"(%1149) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
            %1151 = "cute.recast_iter"(%1145) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
            %1152 = "cute.recast_iter"(%1146) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
            "cute_nvgpu.arch.copy.SM80.cp_async"(%1152, %1151, %1150) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %1035 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1036 = "arith.addi"(%arg40, %1035) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
        %1037 = "arith.cmpi"(%1036, %1033) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %1038 = "scf.if"(%1037) ({
          %1040 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %1041 = "arith.addi"(%arg40, %1040) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          "scf.yield"(%1041) : (i32) -> ()
        }, {
          %1039 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          "scf.yield"(%1039) : (i32) -> ()
        }) : (i1) -> i32
        "nvvm.cp.async.commit.group"() : () -> ()
        "scf.yield"(%1038) : (i32) -> ()
      }) : (i32, i32, i32, i32) -> i32
      %410 = "arith.constant"() <{value = false}> : () -> i1
      %411:2 = "scf.if"(%410) ({
        %1018 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1019 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1020 = "scf.for"(%1018, %1019, %1019, %311) ({
        ^bb0(%arg35: i32, %arg36: !memref_rmem_i8_):
          %1028 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1029 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %1030 = "scf.for"(%1028, %1029, %1029, %arg36) ({
          ^bb0(%arg37: i32, %arg38: !memref_rmem_i8_):
            %1031 = "arith.constant"() <{value = 0 : i8}> : () -> i8
            %1032 = "cute.make_coord"(%arg35, %arg37) : (i32, i32) -> !cute.coord<"(?,?,0)">
            "cute.memref.store"(%arg38, %1032, %1031) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
            "scf.yield"(%arg38) : (!memref_rmem_i8_) -> ()
          }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
          "scf.yield"(%1030) : (!memref_rmem_i8_) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_) -> !memref_rmem_i8_
        %1021 = "scf.for"(%1018, %1019, %1019, %313) ({
        ^bb0(%arg31: i32, %arg32: !memref_rmem_i8_1):
          %1022 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %1023 = "arith.constant"() <{value = 4 : i32}> : () -> i32
          %1024 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %1025 = "scf.for"(%1022, %1023, %1024, %arg32) ({
          ^bb0(%arg33: i32, %arg34: !memref_rmem_i8_1):
            %1026 = "arith.constant"() <{value = 0 : i8}> : () -> i8
            %1027 = "cute.make_coord"(%arg31, %arg33) : (i32, i32) -> !cute.coord<"(?,?,0)">
            "cute.memref.store"(%arg34, %1027, %1026) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
            "scf.yield"(%arg34) : (!memref_rmem_i8_1) -> ()
          }) : (i32, i32, i32, !memref_rmem_i8_1) -> !memref_rmem_i8_1
          "scf.yield"(%1025) : (!memref_rmem_i8_1) -> ()
        }) : (i32, i32, i32, !memref_rmem_i8_1) -> !memref_rmem_i8_1
        "scf.yield"(%1020, %1021) : (!memref_rmem_i8_, !memref_rmem_i8_1) -> ()
      }, {
        "scf.yield"(%311, %313) : (!memref_rmem_i8_, !memref_rmem_i8_1) -> ()
      }) : (i1) -> (!memref_rmem_i8_, !memref_rmem_i8_1)
      %412 = "cute.get_iter"(%411#0) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
      %413 = "cute.get_iter"(%411#1) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
      %414 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %415 = "cute.get_iter"(%143) : (!memref_smem_f32_) -> !cute.ptr<f32, smem, align<1024>>
      %416 = "cute.get_scalars"(%414) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %417 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %418 = "arith.divsi"(%416, %417) : (i32, i32) -> i32
      %419 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %420 = "arith.remsi"(%418, %419) : (i32, i32) -> i32
      %421 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %422 = "arith.remsi"(%420, %421) : (i32, i32) -> i32
      %423 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %424 = "arith.muli"(%422, %423) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %425 = "cute.assume"(%424) : (i32) -> !cute.i32<divby 4>
      %426 = "cute.make_int_tuple"(%425) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %427 = "cute.add_offset"(%415, %426) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %428 = "cute.make_view"(%427) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_10
      %429 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %430 = "cute.get_iter"(%145) : (!memref_smem_f32_1) -> !cute.ptr<f32, smem, align<1024>>
      %431 = "cute.get_scalars"(%429) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %432 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %433 = "arith.remsi"(%431, %432) : (i32, i32) -> i32
      %434 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %435 = "arith.remsi"(%433, %434) : (i32, i32) -> i32
      %436 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %437 = "arith.muli"(%435, %436) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %438 = "cute.assume"(%437) : (i32) -> !cute.i32<divby 4>
      %439 = "cute.make_int_tuple"(%438) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %440 = "cute.add_offset"(%430, %439) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %441 = "cute.make_view"(%440) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_11
      %442 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %443 = "cute.get_iter"(%130) : (!memref_gmem_f32_5) -> !cute.ptr<f32, gmem, align<16>>
      %444 = "cute.get_layout"(%130) : (!memref_gmem_f32_5) -> !cute.layout<"(128,128):(?{i64 div=256},1)">
      %445 = "cute.get_scalars"(%444) <{only_dynamic}> : (!cute.layout<"(128,128):(?{i64 div=256},1)">) -> i64
      %446 = "cute.get_scalars"(%442) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %447 = "arith.constant"() <{value = 4 : i64}> : () -> i64
      %448 = "arith.muli"(%445, %447) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %449 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %450 = "arith.muli"(%445, %449) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %451 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %452 = "arith.divsi"(%446, %451) : (i32, i32) -> i32
      %453 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %454 = "arith.remsi"(%452, %453) : (i32, i32) -> i32
      %455 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %456 = "arith.remsi"(%446, %455) : (i32, i32) -> i32
      %457 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %458 = "arith.remsi"(%454, %457) : (i32, i32) -> i32
      %459 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %460 = "arith.remsi"(%456, %459) : (i32, i32) -> i32
      %461 = "arith.extsi"(%458) : (i32) -> i64
      %462 = "arith.muli"(%461, %448) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %463 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %464 = "arith.muli"(%460, %463) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %465 = "arith.extsi"(%464) : (i32) -> i64
      %466 = "arith.addi"(%462, %465) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %467 = "cute.assume"(%466) : (i64) -> !cute.i64<divby 4>
      %468 = "cute.make_int_tuple"(%467) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %469 = "cute.add_offset"(%443, %468) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %470 = "cute.static"() : () -> !cute.shape<"(1,(4,2),(4,2))">
      %471 = "cute.assume"(%445) : (i64) -> !cute.i64<divby 256>
      %472 = "cute.assume"(%450) : (i64) -> !cute.i64<divby 16384>
      %473 = "cute.make_stride"(%471, %472) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %474 = "cute.make_layout"(%470, %473) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(4,2),(4,2))">, !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %475 = "cute.make_view"(%469, %474) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> !memref_gmem_f32_14
      %476 = "cute.get_iter"(%475) : (!memref_gmem_f32_14) -> !cute.ptr<f32, gmem, align<16>>
      %477 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %478 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %479 = "cute.memref.alloca"() : () -> !memref_rmem_f32_1
      %480 = "cute.get_iter"(%479) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
      %481 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %482 = "vector.splat"(%481) : (f32) -> vector<64xf32>
      "cute.memref.store_vec"(%482, %479) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %483 = "cute.make_coord"(%309) : (i32) -> !cute.coord<"(_,_,_,?)">
      %484 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">
      %485 = "cute.crd2idx"(%483, %484) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %486 = "cute.get_iter"(%428) : (!memref_smem_f32_10) -> !cute.ptr<f32, smem, align<16>>
      %487 = "cute.add_offset"(%486, %485) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
      %488 = "cute.make_view"(%487) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_12
      %489 = "cute.make_coord"(%309) : (i32) -> !cute.coord<"(_,_,_,?)">
      %490 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">
      %491 = "cute.crd2idx"(%489, %490) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
      %492 = "cute.get_iter"(%441) : (!memref_smem_f32_11) -> !cute.ptr<f32, smem, align<16>>
      %493 = "cute.add_offset"(%492, %491) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
      %494 = "cute.make_view"(%493) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_13
      "scf.if"(%406) ({
        "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
        %938 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %939 = "arith.constant"() <{value = 256 : i32}> : () -> i32
        "llvm.inline_asm"(%938, %939) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
        %940 = "cute.static"() : () -> !cute.int_tuple<"0">
        %941 = "cute.get_iter"(%488) : (!memref_smem_f32_12) -> !cute.ptr<f32, smem, align<16>>
        %942 = "cute.add_offset"(%941, %940) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
        %943 = "cute.make_view"(%942) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_14
        %944 = "cute.static"() : () -> !cute.int_tuple<"0">
        %945 = "cute.get_iter"(%477) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
        %946 = "cute.add_offset"(%945, %944) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem>
        %947 = "cute.make_view"(%946) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
        %948 = "cute.get_iter"(%943) : (!memref_smem_f32_14) -> !cute.ptr<f32, smem, align<16>>
        %949 = "cute.make_view"(%948) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
        %950 = "cute.get_iter"(%947) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
        %951 = "cute.make_view"(%950) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
        %952 = "cute.get_iter"(%949) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
        %953 = "cute.make_view"(%952) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
        %954 = "cute.get_iter"(%951) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
        %955 = "cute.make_view"(%954) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
        %956 = "cute.static"() : () -> !cute.layout<"1:0">
        %957 = "cute.get_iter"(%953) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
        %958 = "cute.get_iter"(%955) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
        %959 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
        %960 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
        %961 = "cute.static"() : () -> !cute.int_tuple<"2">
        %962 = "cute.get_scalars"(%961) : (!cute.int_tuple<"2">) -> i32
        %963 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %964 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%963, %962, %964) ({
        ^bb0(%arg30: i32):
          %1004 = "cute.make_coord"(%arg30) : (i32) -> !cute.coord<"(_,?)">
          %1005 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %1006 = "cute.crd2idx"(%1004, %959) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
          %1007 = "cute.add_offset"(%957, %1006) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
          %1008 = "cute.make_view"(%1007, %1005) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"(4):(1)">) -> !memref_smem_f32_16
          %1009 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %1010 = "cute.crd2idx"(%1004, %960) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
          %1011 = "cute.add_offset"(%958, %1010) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
          %1012 = "cute.make_view"(%1011, %1009) : (!cute.ptr<f32, rmem>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_4
          %1013 = "cute.get_iter"(%1008) : (!memref_smem_f32_16) -> !cute.ptr<f32, smem, align<16>>
          %1014 = "cute.get_iter"(%1012) : (!memref_rmem_f32_4) -> !cute.ptr<f32, rmem>
          %1015 = "builtin.unrealized_conversion_cast"(%1013) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
          %1016 = "builtin.unrealized_conversion_cast"(%1014) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1017 = "llvm.load"(%1015) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
          "llvm.store"(%1017, %1016) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %965 = "cute.static"() : () -> !cute.int_tuple<"0">
        %966 = "cute.get_iter"(%494) : (!memref_smem_f32_13) -> !cute.ptr<f32, smem, align<16>>
        %967 = "cute.add_offset"(%966, %965) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
        %968 = "cute.make_view"(%967) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_14
        %969 = "cute.static"() : () -> !cute.int_tuple<"0">
        %970 = "cute.get_iter"(%478) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
        %971 = "cute.add_offset"(%970, %969) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem>
        %972 = "cute.make_view"(%971) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
        %973 = "cute.get_iter"(%968) : (!memref_smem_f32_14) -> !cute.ptr<f32, smem, align<16>>
        %974 = "cute.make_view"(%973) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
        %975 = "cute.get_iter"(%972) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
        %976 = "cute.make_view"(%975) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
        %977 = "cute.get_iter"(%974) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
        %978 = "cute.make_view"(%977) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
        %979 = "cute.get_iter"(%976) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
        %980 = "cute.make_view"(%979) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
        %981 = "cute.static"() : () -> !cute.layout<"1:0">
        %982 = "cute.get_iter"(%978) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
        %983 = "cute.get_iter"(%980) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
        %984 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
        %985 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
        %986 = "cute.static"() : () -> !cute.int_tuple<"2">
        %987 = "cute.get_scalars"(%986) : (!cute.int_tuple<"2">) -> i32
        %988 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %989 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%988, %987, %989) ({
        ^bb0(%arg29: i32):
          %990 = "cute.make_coord"(%arg29) : (i32) -> !cute.coord<"(_,?)">
          %991 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %992 = "cute.crd2idx"(%990, %984) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
          %993 = "cute.add_offset"(%982, %992) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
          %994 = "cute.make_view"(%993, %991) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"(4):(1)">) -> !memref_smem_f32_16
          %995 = "cute.static"() : () -> !cute.layout<"(4):(1)">
          %996 = "cute.crd2idx"(%990, %985) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
          %997 = "cute.add_offset"(%983, %996) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
          %998 = "cute.make_view"(%997, %995) : (!cute.ptr<f32, rmem>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_4
          %999 = "cute.get_iter"(%994) : (!memref_smem_f32_16) -> !cute.ptr<f32, smem, align<16>>
          %1000 = "cute.get_iter"(%998) : (!memref_rmem_f32_4) -> !cute.ptr<f32, rmem>
          %1001 = "builtin.unrealized_conversion_cast"(%999) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
          %1002 = "builtin.unrealized_conversion_cast"(%1000) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %1003 = "llvm.load"(%1001) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
          "llvm.store"(%1003, %1002) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %495 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %496:5 = "scf.for"(%309, %495, %310, %488, %494, %408, %309, %409) ({
      ^bb0(%arg10: i32, %arg11: !memref_smem_f32_12, %arg12: !memref_smem_f32_13, %arg13: i32, %arg14: i32, %arg15: i32):
        %627 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %628 = "arith.constant"() <{value = 8 : i32}> : () -> i32
        %629 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %630:5 = "scf.for"(%627, %628, %629, %arg11, %arg12, %arg13, %arg14, %arg15) ({
        ^bb0(%arg16: i32, %arg17: !memref_smem_f32_12, %arg18: !memref_smem_f32_13, %arg19: i32, %arg20: i32, %arg21: i32):
          %631 = "arith.constant"() <{value = 7 : i32}> : () -> i32
          %632 = "arith.cmpi"(%arg16, %631) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %633:2 = "scf.if"(%632) ({
            %924 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,_,_,?)">
            %925 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">
            %926 = "cute.crd2idx"(%924, %925) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %927 = "cute.get_iter"(%428) : (!memref_smem_f32_10) -> !cute.ptr<f32, smem, align<16>>
            %928 = "cute.add_offset"(%927, %926) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %929 = "cute.make_view"(%928) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_12
            %930 = "cute.make_coord"(%arg20) : (i32) -> !cute.coord<"(_,_,_,?)">
            %931 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">
            %932 = "cute.crd2idx"(%930, %931) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %933 = "cute.get_iter"(%441) : (!memref_smem_f32_11) -> !cute.ptr<f32, smem, align<16>>
            %934 = "cute.add_offset"(%933, %932) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
            %935 = "cute.make_view"(%934) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_13
            "nvvm.cp.async.wait.group"() <{n = 1 : i32}> : () -> ()
            %936 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            %937 = "arith.constant"() <{value = 256 : i32}> : () -> i32
            "llvm.inline_asm"(%936, %937) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
            "scf.yield"(%929, %935) : (!memref_smem_f32_12, !memref_smem_f32_13) -> ()
          }, {
            "scf.yield"(%arg17, %arg18) : (!memref_smem_f32_12, !memref_smem_f32_13) -> ()
          }) : (i1) -> (!memref_smem_f32_12, !memref_smem_f32_13)
          %634 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          %635 = "arith.addi"(%arg16, %634) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %636 = "arith.constant"() <{value = 8 : i32}> : () -> i32
          %637 = "arith.remsi"(%635, %636) : (i32, i32) -> i32
          %638 = "cute.make_coord"(%637) : (i32) -> !cute.coord<"(_,_,?)">
          %639 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),128)">
          %640 = "cute.crd2idx"(%638, %639) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),128)">) -> !cute.int_tuple<"?{div=128}">
          %641 = "cute.get_iter"(%633#0) : (!memref_smem_f32_12) -> !cute.ptr<f32, smem, align<16>>
          %642 = "cute.add_offset"(%641, %640) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, smem, align<16>>
          %643 = "cute.make_view"(%642) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_14
          %644 = "cute.make_coord"(%637) : (i32) -> !cute.coord<"(_,_,?)">
          %645 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
          %646 = "cute.crd2idx"(%644, %645) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %647 = "cute.get_iter"(%477) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %648 = "cute.add_offset"(%647, %646) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %649 = "cute.make_view"(%648) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
          %650 = "cute.get_iter"(%643) : (!memref_smem_f32_14) -> !cute.ptr<f32, smem, align<16>>
          %651 = "cute.make_view"(%650) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
          %652 = "cute.get_iter"(%649) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
          %653 = "cute.make_view"(%652) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
          %654 = "cute.get_iter"(%651) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
          %655 = "cute.make_view"(%654) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
          %656 = "cute.get_iter"(%653) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
          %657 = "cute.make_view"(%656) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
          %658 = "cute.static"() : () -> !cute.layout<"1:0">
          %659 = "cute.get_iter"(%655) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
          %660 = "cute.get_iter"(%657) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
          %661 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
          %662 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
          %663 = "cute.static"() : () -> !cute.int_tuple<"2">
          %664 = "cute.get_scalars"(%663) : (!cute.int_tuple<"2">) -> i32
          %665 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %666 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%665, %664, %666) ({
          ^bb0(%arg28: i32):
            %910 = "cute.make_coord"(%arg28) : (i32) -> !cute.coord<"(_,?)">
            %911 = "cute.static"() : () -> !cute.layout<"(4):(1)">
            %912 = "cute.crd2idx"(%910, %661) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %913 = "cute.add_offset"(%659, %912) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %914 = "cute.make_view"(%913, %911) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"(4):(1)">) -> !memref_smem_f32_16
            %915 = "cute.static"() : () -> !cute.layout<"(4):(1)">
            %916 = "cute.crd2idx"(%910, %662) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %917 = "cute.add_offset"(%660, %916) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %918 = "cute.make_view"(%917, %915) : (!cute.ptr<f32, rmem>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_4
            %919 = "cute.get_iter"(%914) : (!memref_smem_f32_16) -> !cute.ptr<f32, smem, align<16>>
            %920 = "cute.get_iter"(%918) : (!memref_rmem_f32_4) -> !cute.ptr<f32, rmem>
            %921 = "builtin.unrealized_conversion_cast"(%919) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
            %922 = "builtin.unrealized_conversion_cast"(%920) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
            %923 = "llvm.load"(%921) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
            "llvm.store"(%923, %922) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %667 = "cute.make_coord"(%637) : (i32) -> !cute.coord<"(_,_,?)">
          %668 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,64),132)">
          %669 = "cute.crd2idx"(%667, %668) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),132)">) -> !cute.int_tuple<"?{div=132}">
          %670 = "cute.get_iter"(%633#1) : (!memref_smem_f32_13) -> !cute.ptr<f32, smem, align<16>>
          %671 = "cute.add_offset"(%670, %669) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=132}">) -> !cute.ptr<f32, smem, align<16>>
          %672 = "cute.make_view"(%671) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_14
          %673 = "cute.make_coord"(%637) : (i32) -> !cute.coord<"(_,_,?)">
          %674 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
          %675 = "cute.crd2idx"(%673, %674) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %676 = "cute.get_iter"(%478) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %677 = "cute.add_offset"(%676, %675) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %678 = "cute.make_view"(%677) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
          %679 = "cute.get_iter"(%672) : (!memref_smem_f32_14) -> !cute.ptr<f32, smem, align<16>>
          %680 = "cute.make_view"(%679) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
          %681 = "cute.get_iter"(%678) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
          %682 = "cute.make_view"(%681) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
          %683 = "cute.get_iter"(%680) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
          %684 = "cute.make_view"(%683) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_15
          %685 = "cute.get_iter"(%682) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
          %686 = "cute.make_view"(%685) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_3
          %687 = "cute.static"() : () -> !cute.layout<"1:0">
          %688 = "cute.get_iter"(%684) : (!memref_smem_f32_15) -> !cute.ptr<f32, smem, align<16>>
          %689 = "cute.get_iter"(%686) : (!memref_rmem_f32_3) -> !cute.ptr<f32, rmem>
          %690 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(64))">
          %691 = "cute.static"() : () -> !cute.layout<"(4,(2)):(1,(4))">
          %692 = "cute.static"() : () -> !cute.int_tuple<"2">
          %693 = "cute.get_scalars"(%692) : (!cute.int_tuple<"2">) -> i32
          %694 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %695 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%694, %693, %695) ({
          ^bb0(%arg27: i32):
            %896 = "cute.make_coord"(%arg27) : (i32) -> !cute.coord<"(_,?)">
            %897 = "cute.static"() : () -> !cute.layout<"(4):(1)">
            %898 = "cute.crd2idx"(%896, %690) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %899 = "cute.add_offset"(%688, %898) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %900 = "cute.make_view"(%899, %897) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"(4):(1)">) -> !memref_smem_f32_16
            %901 = "cute.static"() : () -> !cute.layout<"(4):(1)">
            %902 = "cute.crd2idx"(%896, %691) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %903 = "cute.add_offset"(%689, %902) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %904 = "cute.make_view"(%903, %901) : (!cute.ptr<f32, rmem>, !cute.layout<"(4):(1)">) -> !memref_rmem_f32_4
            %905 = "cute.get_iter"(%900) : (!memref_smem_f32_16) -> !cute.ptr<f32, smem, align<16>>
            %906 = "cute.get_iter"(%904) : (!memref_rmem_f32_4) -> !cute.ptr<f32, rmem>
            %907 = "builtin.unrealized_conversion_cast"(%905) : (!cute.ptr<f32, smem, align<16>>) -> !llvm.ptr<3>
            %908 = "builtin.unrealized_conversion_cast"(%906) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
            %909 = "llvm.load"(%907) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<4xf32>
            "llvm.store"(%909, %908) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<4xf32>, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %696 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %697 = "arith.cmpi"(%arg16, %696) <{predicate = 0 : i64}> : (i32, i32) -> i1
          "scf.if"(%697) ({
            %842 = "cute.make_coord"(%arg21) : (i32) -> !cute.coord<"(_,_,_,?)">
            %843 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
            %844 = "cute.crd2idx"(%842, %843) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
            %845 = "cute.get_iter"(%161) : (!memref_gmem_f32_6) -> !cute.ptr<f32, gmem, align<16>>
            %846 = "cute.add_offset"(%845, %844) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
            %847 = "cute.make_view"(%846) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_8
            %848 = "cute.get_iter"(%847) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
            %849 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"(_,_,_,?)">
            %850 = "cute.static"() : () -> !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">
            %851 = "cute.crd2idx"(%849, %850) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %852 = "cute.get_iter"(%170) : (!memref_smem_f32_2) -> !cute.ptr<f32, smem, align<16>>
            %853 = "cute.add_offset"(%852, %851) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %854 = "cute.make_view"(%853) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_4
            %855 = "cute.get_iter"(%854) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
            %856 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
            %857 = "cute.make_view"(%848, %856) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_gmem_f32_8
            %858 = "cute.get_iter"(%857) : (!memref_gmem_f32_8) -> !cute.ptr<f32, gmem, align<16>>
            %859 = "cute.make_view"(%858) : (!cute.ptr<f32, gmem, align<16>>) -> !memref_gmem_f32_9
            %860 = "cute.static"() : () -> !cute.layout<"((4,1),1,1):((1,0),0,0)">
            %861 = "cute.make_view"(%855, %860) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1),1,1):((1,0),0,0)">) -> !memref_smem_f32_4
            %862 = "cute.get_iter"(%861) : (!memref_smem_f32_4) -> !cute.ptr<f32, smem, align<16>>
            %863 = "cute.make_view"(%862) : (!cute.ptr<f32, smem, align<16>>) -> !memref_smem_f32_5
            %864 = "cute.static"() : () -> !cute.layout<"(1,1,1):(1,1,0)">
            %865 = "cute.make_view"(%412, %864) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,1,1):(1,1,0)">) -> !memref_rmem_i8_
            %866 = "cute.get_iter"(%865) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
            %867 = "cute.make_view"(%866) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_8
            %868 = "cute.static"() : () -> !cute.layout<"1:0">
            %869 = "cute.get_iter"(%859) : (!memref_gmem_f32_9) -> !cute.ptr<f32, gmem, align<16>>
            %870 = "cute.get_iter"(%863) : (!memref_smem_f32_5) -> !cute.ptr<f32, smem, align<16>>
            %871 = "cute.get_iter"(%867) : (!memref_rmem_i8_8) -> !cute.ptr<i8, rmem, align<32>>
            %872 = "cute.static"() : () -> !cute.int_tuple<"1">
            %873 = "cute.get_scalars"(%872) : (!cute.int_tuple<"1">) -> i32
            %874 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %875 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%874, %873, %875) ({
            ^bb0(%arg26: i32):
              %876 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
              %877 = "cute.static"() : () -> !cute.int_tuple<"0">
              %878 = "cute.add_offset"(%869, %877) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem, align<16>>
              %879 = "cute.make_view"(%878, %876) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_gmem_f32_10
              %880 = "cute.static"() : () -> !cute.layout<"((4,1)):((1,0))">
              %881 = "cute.static"() : () -> !cute.int_tuple<"0">
              %882 = "cute.add_offset"(%870, %881) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, smem, align<16>>
              %883 = "cute.make_view"(%882, %880) : (!cute.ptr<f32, smem, align<16>>, !cute.layout<"((4,1)):((1,0))">) -> !memref_smem_f32_6
              %884 = "cute.static"() : () -> !cute.layout<"(1):(1)">
              %885 = "cute.static"() : () -> !cute.int_tuple<"0">
              %886 = "cute.add_offset"(%871, %885) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
              %887 = "cute.make_view"(%886, %884) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1):(1)">) -> !memref_rmem_i8_9
              %888 = "cute.get_iter"(%879) : (!memref_gmem_f32_10) -> !cute.ptr<f32, gmem, align<16>>
              %889 = "cute.get_iter"(%883) : (!memref_smem_f32_6) -> !cute.ptr<f32, smem, align<16>>
              %890 = "cute.get_iter"(%887) : (!memref_rmem_i8_9) -> !cute.ptr<i8, rmem, align<32>>
              %891 = "builtin.unrealized_conversion_cast"(%890) : (!cute.ptr<i8, rmem, align<32>>) -> !llvm.ptr
              %892 = "llvm.load"(%891) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %893 = "llvm.trunc"(%892) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %894 = "cute.recast_iter"(%888) : (!cute.ptr<f32, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %895 = "cute.recast_iter"(%889) : (!cute.ptr<f32, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%895, %894, %893) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          %698 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,?)">
          %699 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
          %700 = "cute.crd2idx"(%698, %699) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %701 = "cute.get_iter"(%477) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %702 = "cute.add_offset"(%701, %700) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %703 = "cute.make_view"(%702) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
          %704 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,_,?)">
          %705 = "cute.static"() : () -> !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
          %706 = "cute.crd2idx"(%704, %705) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %707 = "cute.get_iter"(%478) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem>
          %708 = "cute.add_offset"(%707, %706) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %709 = "cute.make_view"(%708) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_2
          %710 = "cute.get_iter"(%703) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
          %711 = "cute.get_iter"(%709) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem>
          %712 = "cute.get_iter"(%479) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
          %713 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
          %714 = "cute.static"() : () -> !cute.layout<"1:0">
          %715 = "cute.static"() : () -> !cute.layout<"(1,(4,2),1):(0,(1,4),0)">
          %716 = "cute.static"() : () -> !cute.layout<"(1,(4,2),1):(0,(1,4),0)">
          %717 = "cute.static"() : () -> !cute.int_tuple<"1">
          %718 = "cute.static"() : () -> !cute.int_tuple<"8">
          %719 = "cute.static"() : () -> !cute.int_tuple<"8">
          %720 = "cute.get_scalars"(%717) : (!cute.int_tuple<"1">) -> i32
          %721 = "cute.get_scalars"(%718) : (!cute.int_tuple<"8">) -> i32
          %722 = "cute.get_scalars"(%719) : (!cute.int_tuple<"8">) -> i32
          %723 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %724 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%723, %720, %724) ({
          ^bb0(%arg23: i32):
            "scf.for"(%723, %721, %724) ({
            ^bb0(%arg24: i32):
              "scf.for"(%723, %722, %724) ({
              ^bb0(%arg25: i32):
                %817 = "cute.make_coord"(%arg24, %arg23) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %818 = "cute.make_coord"(%arg25, %arg23) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %819 = "cute.make_coord"(%arg24, %arg25) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %820 = "cute.static"() : () -> !cute.layout<"(1):(0)">
                %821 = "cute.crd2idx"(%817, %715) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
                %822 = "cute.add_offset"(%710, %821) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
                %823 = "cute.make_view"(%822, %820) : (!cute.ptr<f32, rmem>, !cute.layout<"(1):(0)">) -> !memref_rmem_f32_5
                %824 = "cute.static"() : () -> !cute.layout<"(1):(0)">
                %825 = "cute.crd2idx"(%818, %716) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
                %826 = "cute.add_offset"(%711, %825) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
                %827 = "cute.make_view"(%826, %824) : (!cute.ptr<f32, rmem>, !cute.layout<"(1):(0)">) -> !memref_rmem_f32_5
                %828 = "cute.static"() : () -> !cute.layout<"(1):(0)">
                %829 = "cute.crd2idx"(%819, %713) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !cute.int_tuple<"?">
                %830 = "cute.add_offset"(%712, %829) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
                %831 = "cute.make_view"(%830, %828) : (!cute.ptr<f32, rmem>, !cute.layout<"(1):(0)">) -> !memref_rmem_f32_5
                %832 = "cute.get_iter"(%823) : (!memref_rmem_f32_5) -> !cute.ptr<f32, rmem>
                %833 = "cute.get_iter"(%827) : (!memref_rmem_f32_5) -> !cute.ptr<f32, rmem>
                %834 = "cute.get_iter"(%831) : (!memref_rmem_f32_5) -> !cute.ptr<f32, rmem>
                %835 = "cute.make_view"(%832) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_5
                %836 = "cute.make_view"(%833) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_5
                %837 = "cute.make_view"(%834) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_5
                %838 = "cute.memref.load_vec"(%835) : (!memref_rmem_f32_5) -> vector<1xf32>
                %839 = "cute.memref.load_vec"(%836) : (!memref_rmem_f32_5) -> vector<1xf32>
                %840 = "cute.memref.load_vec"(%837) : (!memref_rmem_f32_5) -> vector<1xf32>
                %841 = "math.fma"(%838, %839, %840) <{fastmath = #arith.fastmath<none>}> : (vector<1xf32>, vector<1xf32>, vector<1xf32>) -> vector<1xf32>
                "cute.memref.store_vec"(%841, %837) : (vector<1xf32>, !memref_rmem_f32_5) -> ()
                "scf.yield"() : () -> ()
              }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %725 = "arith.cmpi"(%arg16, %696) <{predicate = 0 : i64}> : (i32, i32) -> i1
          %726:3 = "scf.if"(%725) ({
            %727 = "cute.make_coord"(%arg21) : (i32) -> !cute.coord<"(_,_,_,?)">
            %728 = "cute.get_layout"(%192) : (!memref_gmem_f32_7) -> !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
            %729:2 = "cute.get_scalars"(%728) <{only_dynamic}> : (!cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> (i32, i64)
            %730 = "cute.static"() : () -> !cute.shape<"((1,1),4,1)">
            %731 = "cute.assume"(%729#1) : (i64) -> !cute.i64<divby 2048>
            %732 = "cute.make_stride"(%731) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
            %733 = "cute.make_layout"(%730, %732) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),4,1)">, !cute.stride<"((0,0),?{i64 div=2048},0)">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %734 = "cute.crd2idx"(%727, %728) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
            %735 = "cute.get_iter"(%192) : (!memref_gmem_f32_7) -> !cute.ptr<f32, gmem>
            %736 = "cute.add_offset"(%735, %734) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
            %737 = "cute.make_view"(%736, %733) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
            %738 = "cute.get_iter"(%737) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
            %739 = "cute.make_coord"(%arg19) : (i32) -> !cute.coord<"(_,_,_,?)">
            %740 = "cute.static"() : () -> !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">
            %741 = "cute.crd2idx"(%739, %740) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %742 = "cute.get_iter"(%205) : (!memref_smem_f32_3) -> !cute.ptr<f32, smem>
            %743 = "cute.add_offset"(%742, %741) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
            %744 = "cute.make_view"(%743) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_7
            %745 = "cute.get_iter"(%744) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
            %746 = "cute.get_layout"(%737) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %747 = "cute.static"() : () -> !cute.layout<"1:0">
            %748 = "cute.append_to_rank"(%746, %747) <{rank = 2 : si32}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %749 = "cute.make_view"(%738, %748) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> !memref_gmem_f32_11
            %750 = "cute.get_iter"(%749) : (!memref_gmem_f32_11) -> !cute.ptr<f32, gmem>
            %751 = "cute.get_layout"(%749) : (!memref_gmem_f32_11) -> !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
            %752 = "cute.get_scalars"(%751) <{only_dynamic}> : (!cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">) -> i64
            %753 = "cute.static"() : () -> !cute.shape<"((1,1),(4,1))">
            %754 = "cute.assume"(%752) : (i64) -> !cute.i64<divby 2048>
            %755 = "cute.make_stride"(%754) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
            %756 = "cute.make_layout"(%753, %755) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),(4,1))">, !cute.stride<"((0,0),(?{i64 div=2048},0))">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
            %757 = "cute.make_view"(%750, %756) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> !memref_gmem_f32_12
            %758 = "cute.static"() : () -> !cute.layout<"((1,1),4,1):((0,0),32,0)">
            %759 = "cute.make_view"(%745, %758) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1),4,1):((0,0),32,0)">) -> !memref_smem_f32_7
            %760 = "cute.get_iter"(%759) : (!memref_smem_f32_7) -> !cute.ptr<f32, smem>
            %761 = "cute.make_view"(%760) : (!cute.ptr<f32, smem>) -> !memref_smem_f32_8
            %762 = "cute.static"() : () -> !cute.layout<"(1,4,1):(4,1,0)">
            %763 = "cute.make_view"(%413, %762) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,4,1):(4,1,0)">) -> !memref_rmem_i8_1
            %764 = "cute.get_iter"(%763) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %765 = "cute.make_view"(%764) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_10
            %766 = "cute.static"() : () -> !cute.layout<"1:0">
            %767 = "cute.get_iter"(%757) : (!memref_gmem_f32_12) -> !cute.ptr<f32, gmem>
            %768 = "cute.get_iter"(%761) : (!memref_smem_f32_8) -> !cute.ptr<f32, smem>
            %769 = "cute.get_layout"(%757) : (!memref_gmem_f32_12) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
            %770 = "cute.append_to_rank"(%769, %766) <{rank = 2 : si32}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">) -> !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
            %771 = "cute.get_scalars"(%770) <{only_dynamic}> : (!cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">) -> i64
            %772 = "cute.static"() : () -> !cute.shape<"((1,1),((4,1)))">
            %773 = "cute.assume"(%771) : (i64) -> !cute.i64<divby 2048>
            %774 = "cute.make_stride"(%773) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
            %775 = "cute.make_layout"(%772, %774) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,1),((4,1)))">, !cute.stride<"((0,0),((?{i64 div=2048},0)))">) -> !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
            %776 = "cute.static"() : () -> !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
            %777 = "cute.get_iter"(%765) : (!memref_rmem_i8_10) -> !cute.ptr<i8, rmem, align<32>>
            %778 = "cute.static"() : () -> !cute.layout<"(1,((4,1))):(4,((1,0)))">
            %779 = "cute.static"() : () -> !cute.int_tuple<"4">
            %780 = "cute.get_scalars"(%779) : (!cute.int_tuple<"4">) -> i32
            %781 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %782 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%781, %780, %782) ({
            ^bb0(%arg22: i32):
              %796 = "cute.make_coord"(%arg22) : (i32) -> !cute.coord<"(_,?)">
              %797 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
              %798 = "cute.crd2idx"(%796, %775) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
              %799 = "cute.add_offset"(%767, %798) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
              %800 = "cute.make_view"(%799, %797) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_gmem_f32_13
              %801 = "cute.static"() : () -> !cute.layout<"((1,1)):((0,0))">
              %802 = "cute.crd2idx"(%796, %776) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
              %803 = "cute.add_offset"(%768, %802) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
              %804 = "cute.make_view"(%803, %801) : (!cute.ptr<f32, smem>, !cute.layout<"((1,1)):((0,0))">) -> !memref_smem_f32_9
              %805 = "cute.static"() : () -> !cute.layout<"(1):(4)">
              %806 = "cute.crd2idx"(%796, %778) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
              %807 = "cute.add_offset"(%777, %806) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %808 = "cute.make_view"(%807, %805) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(4)">) -> !memref_rmem_i8_7
              %809 = "cute.get_iter"(%800) : (!memref_gmem_f32_13) -> !cute.ptr<f32, gmem>
              %810 = "cute.get_iter"(%804) : (!memref_smem_f32_9) -> !cute.ptr<f32, smem>
              %811 = "cute.get_iter"(%808) : (!memref_rmem_i8_7) -> !cute.ptr<i8, rmem>
              %812 = "builtin.unrealized_conversion_cast"(%811) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %813 = "llvm.load"(%812) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %814 = "llvm.trunc"(%813) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %815 = "cute.recast_iter"(%809) : (!cute.ptr<f32, gmem>) -> !cute.ptr<i32, gmem>
              %816 = "cute.recast_iter"(%810) : (!cute.ptr<f32, smem>) -> !cute.ptr<i32, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%816, %815, %814) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i32, smem>, !cute.ptr<i32, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "nvvm.cp.async.commit.group"() : () -> ()
            %783 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            %784 = "arith.addi"(%arg20, %783) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %785 = "arith.constant"() <{value = 3 : i32}> : () -> i32
            %786 = "arith.cmpi"(%784, %785) <{predicate = 0 : i64}> : (i32, i32) -> i1
            %787 = "scf.if"(%786) ({
              %795 = "arith.constant"() <{value = 0 : i32}> : () -> i32
              "scf.yield"(%795) : (i32) -> ()
            }, {
              "scf.yield"(%784) : (i32) -> ()
            }) : (i1) -> i32
            %788 = "arith.addi"(%arg21, %783) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
            %789 = "arith.constant"() <{value = 8 : i32}> : () -> i32
            %790 = "arith.cmpi"(%788, %789) <{predicate = 2 : i64}> : (i32, i32) -> i1
            %791 = "scf.if"(%790) ({
              %793 = "arith.constant"() <{value = 1 : i32}> : () -> i32
              %794 = "arith.addi"(%arg21, %793) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
              "scf.yield"(%794) : (i32) -> ()
            }, {
              %792 = "arith.constant"() <{value = 1 : i32}> : () -> i32
              "scf.yield"(%792) : (i32) -> ()
            }) : (i1) -> i32
            "scf.yield"(%arg20, %787, %791) : (i32, i32, i32) -> ()
          }, {
            "scf.yield"(%arg19, %arg20, %arg21) : (i32, i32, i32) -> ()
          }) : (i1) -> (i32, i32, i32)
          "scf.yield"(%633#0, %633#1, %726#0, %726#1, %726#2) : (!memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32) -> ()
        }) {loop_annotation = #loop_annotation1} : (i32, i32, i32, !memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32) -> (!memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32)
        "scf.yield"(%630#0, %630#1, %630#2, %630#3, %630#4) : (!memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32) -> ()
      }) : (i32, i32, i32, !memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32) -> (!memref_smem_f32_12, !memref_smem_f32_13, i32, i32, i32)
      "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
      %497 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %498 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      "llvm.inline_asm"(%497, %498) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %499 = "cute.memref.load_vec"(%479) : (!memref_rmem_f32_1) -> vector<64xf32>
      "cute.memref.store_vec"(%499, %479) : (vector<64xf32>, !memref_rmem_f32_1) -> ()
      %500 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
      %501 = "cute.static"() : () -> !cute.layout<"(128,128):(1@0,1@1)">
      %502 = "cute.make_view"(%500, %501) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(128,128):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(128,128):(1@0,1@1)">
      %503 = "cute.make_coord"(%68) : (i32) -> !cute.coord<"?">
      %504 = "cute.get_iter"(%502) : (!cute.coord_tensor<"(0,0)", "(128,128):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
      %505 = "cute.get_scalars"(%503) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %506 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %507 = "arith.divsi"(%505, %506) : (i32, i32) -> i32
      %508 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %509 = "arith.remsi"(%507, %508) : (i32, i32) -> i32
      %510 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %511 = "arith.remsi"(%505, %510) : (i32, i32) -> i32
      %512 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %513 = "arith.remsi"(%509, %512) : (i32, i32) -> i32
      %514 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %515 = "arith.remsi"(%511, %514) : (i32, i32) -> i32
      %516 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %517 = "arith.muli"(%513, %516) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %518 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %519 = "arith.muli"(%515, %518) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %520 = "cute.assume"(%517) : (i32) -> !cute.i32<divby 4>
      %521 = "cute.assume"(%519) : (i32) -> !cute.i32<divby 4>
      %522 = "cute.make_int_tuple"(%520, %521) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %523 = "cute.add_offset"(%504, %522) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %524 = "cute.make_view"(%523) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">
      %525 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %526 = "cute.memref.alloca"(%525) : (!cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !memref_rmem_i8_11
      %527 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %528 = "cute.get_shape"(%527) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %529:2 = "cute.get_leaves"(%528) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
      %530 = "cute.to_int_tuple"(%529#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %531 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %532 = "arith.muli"(%531, %69) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %533 = "cute.make_int_tuple"(%532) : (i32) -> !cute.int_tuple<"?">
      %534 = "cute.tuple_sub"(%530, %533) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %535 = "cute.get_layout"(%arg6) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %536 = "cute.get_shape"(%535) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %537:2 = "cute.get_leaves"(%536) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
      %538 = "cute.to_int_tuple"(%537#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
      %539 = "arith.muli"(%531, %70) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %540 = "cute.make_int_tuple"(%539) : (i32) -> !cute.int_tuple<"?">
      %541 = "cute.tuple_sub"(%538, %540) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %542 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %543 = "scf.for"(%309, %542, %310, %526) ({
      ^bb0(%arg8: i32, %arg9: !memref_rmem_i8_11):
        %607 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"?">
        %608 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">
        %609 = "cute.crd2idx"(%607, %608) : (!cute.coord<"?">, !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.int_tuple<"(?,?)">
        %610 = "cute.get_iter"(%524) : (!cute.coord_tensor<"(?{div=4},?{div=4})", "(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
        %611 = "cute.add_offset"(%610, %609) : (!cute.arith_tuple_iter<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.arith_tuple_iter<"(?,?)">
        %612 = "cute.make_view"(%611) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
        %613 = "cute.get_iter"(%612) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
        %614 = "cute.deref_arith_tuple_iter"(%613) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %615:2 = "cute.get_leaves"(%614) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        %616 = "cute.make_coord"(%615#0, %615#1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %617 = "cute.make_coord"(%534, %541) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %618:2 = "cute.get_scalars"(%616) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %619:2 = "cute.get_scalars"(%617) : (!cute.coord<"(?,?)">) -> (i32, i32)
        %620 = "arith.constant"() <{value = true}> : () -> i1
        %621 = "arith.cmpi"(%618#0, %619#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %622 = "arith.andi"(%620, %621) : (i1, i1) -> i1
        %623 = "arith.cmpi"(%618#1, %619#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
        %624 = "arith.andi"(%622, %623) : (i1, i1) -> i1
        %625 = "arith.extui"(%624) : (i1) -> i8
        %626 = "cute.make_coord"(%arg8) : (i32) -> !cute.coord<"?">
        "cute.memref.store"(%arg9, %626, %625) : (!memref_rmem_i8_11, !cute.coord<"?">, i8) -> ()
        "scf.yield"(%arg9) : (!memref_rmem_i8_11) -> ()
      }) : (i32, i32, i32, !memref_rmem_i8_11) -> !memref_rmem_i8_11
      %544 = "cute.get_iter"(%543) : (!memref_rmem_i8_11) -> !cute.ptr<i8, rmem, align<32>>
      %545 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %546 = "cute.make_view"(%480, %545) : (!cute.ptr<f32, rmem>, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !memref_rmem_f32_1
      %547 = "cute.get_iter"(%546) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem>
      %548 = "cute.make_view"(%547) : (!cute.ptr<f32, rmem>) -> !memref_rmem_f32_6
      %549 = "cute.get_layout"(%475) : (!memref_gmem_f32_14) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %550 = "cute.static"() : () -> !cute.layout<"1:0">
      %551 = "cute.append_to_rank"(%549, %550) <{rank = 2 : si32}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">, !cute.layout<"1:0">) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %552 = "cute.make_view"(%476, %551) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> !memref_gmem_f32_14
      %553 = "cute.get_iter"(%552) : (!memref_gmem_f32_14) -> !cute.ptr<f32, gmem, align<16>>
      %554 = "cute.get_layout"(%552) : (!memref_gmem_f32_14) -> !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %555:2 = "cute.get_scalars"(%554) <{only_dynamic}> : (!cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">) -> (i64, i64)
      %556 = "cute.static"() : () -> !cute.shape<"(1,((4,2),(4,2)))">
      %557 = "cute.assume"(%555#0) : (i64) -> !cute.i64<divby 256>
      %558 = "cute.assume"(%555#1) : (i64) -> !cute.i64<divby 16384>
      %559 = "cute.make_stride"(%557, %558) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %560 = "cute.make_layout"(%556, %559) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,((4,2),(4,2)))">, !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %561 = "cute.make_view"(%553, %560) : (!cute.ptr<f32, gmem, align<16>>, !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> !memref_gmem_f32_15
      %562 = "cute.static"() : () -> !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %563 = "cute.make_view"(%544, %562) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !memref_rmem_i8_11
      %564 = "cute.get_iter"(%563) : (!memref_rmem_i8_11) -> !cute.ptr<i8, rmem, align<32>>
      %565 = "cute.make_view"(%564) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_12
      %566 = "cute.static"() : () -> !cute.layout<"1:0">
      %567 = "cute.get_iter"(%548) : (!memref_rmem_f32_6) -> !cute.ptr<f32, rmem>
      %568 = "cute.get_iter"(%561) : (!memref_gmem_f32_15) -> !cute.ptr<f32, gmem, align<16>>
      %569 = "cute.get_layout"(%561) : (!memref_gmem_f32_15) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %570 = "cute.append_to_rank"(%569, %566) <{rank = 2 : si32}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">, !cute.layout<"1:0">) -> !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %571 = "cute.static"() : () -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">
      %572:2 = "cute.get_scalars"(%570) <{only_dynamic}> : (!cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">) -> (i64, i64)
      %573 = "cute.static"() : () -> !cute.shape<"(1,(((4,2),(4,2))))">
      %574 = "cute.assume"(%572#0) : (i64) -> !cute.i64<divby 256>
      %575 = "cute.assume"(%572#1) : (i64) -> !cute.i64<divby 16384>
      %576 = "cute.make_stride"(%574, %575) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %577 = "cute.make_layout"(%573, %576) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(1,(((4,2),(4,2))))">, !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %578 = "cute.get_iter"(%565) : (!memref_rmem_i8_12) -> !cute.ptr<i8, rmem, align<32>>
      %579 = "cute.static"() : () -> !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">
      %580 = "cute.static"() : () -> !cute.int_tuple<"64">
      %581 = "cute.get_scalars"(%580) : (!cute.int_tuple<"64">) -> i32
      %582 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %583 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%582, %581, %583) ({
      ^bb0(%arg7: i32):
        %584 = "cute.make_coord"(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %585 = "cute.static"() : () -> !cute.layout<"(1):(0)">
        %586 = "cute.crd2idx"(%584, %571) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
        %587 = "cute.add_offset"(%567, %586) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
        %588 = "cute.make_view"(%587, %585) : (!cute.ptr<f32, rmem>, !cute.layout<"(1):(0)">) -> !memref_rmem_f32_5
        %589 = "cute.static"() : () -> !cute.layout<"(1):(0)">
        %590 = "cute.crd2idx"(%584, %577) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.int_tuple<"?{i64}">
        %591 = "cute.add_offset"(%568, %590) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %592 = "cute.make_view"(%591, %589) : (!cute.ptr<f32, gmem>, !cute.layout<"(1):(0)">) -> !memref_gmem_f32_16
        %593 = "cute.static"() : () -> !cute.layout<"(1):(0)">
        %594 = "cute.crd2idx"(%584, %579) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
        %595 = "cute.add_offset"(%578, %594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %596 = "cute.make_view"(%595, %593) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(0)">) -> !memref_rmem_i8_13
        %597 = "cute.get_iter"(%588) : (!memref_rmem_f32_5) -> !cute.ptr<f32, rmem>
        %598 = "cute.get_iter"(%592) : (!memref_gmem_f32_16) -> !cute.ptr<f32, gmem>
        %599 = "cute.get_iter"(%596) : (!memref_rmem_i8_13) -> !cute.ptr<i8, rmem>
        %600 = "builtin.unrealized_conversion_cast"(%599) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
        %601 = "llvm.load"(%600) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
        %602 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
        %603 = "llvm.icmp"(%601, %602) <{predicate = 1 : i64}> : (i8, i8) -> i1
        "scf.if"(%603) ({
          %604 = "builtin.unrealized_conversion_cast"(%597) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
          %605 = "builtin.unrealized_conversion_cast"(%598) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
          %606 = "llvm.load"(%604) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xf32>
          "llvm.store"(%606, %605) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr<1>) -> ()
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
    %0 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>
    %1 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>
    %2 = "cute.make_tiled_copy"(%1) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>) -> !copy_ldgsts
    %3 = "cute.make_tiled_copy"(%0) : (!cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>) -> !copy_ldgsts1
    %4 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_2) -> !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
    %5 = "cute.get_shape"(%4) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
    %6:2 = "cute.get_leaves"(%5) : (!cute.shape<"(?,?{div=256})">) -> (!cute.shape<"?">, !cute.shape<"?{div=256}">)
    %7 = "cute.to_int_tuple"(%6#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %8 = "cute.to_int_tuple"(%6#1) : (!cute.shape<"?{div=256}">) -> !cute.int_tuple<"?{div=256}">
    %9 = "cute.make_int_tuple"(%7, %8) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?,?{div=256})">
    %10:2 = "cute.get_scalars"(%9) <{only_dynamic}> : (!cute.int_tuple<"(?,?{div=256})">) -> (i32, i32)
    %11 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %12 = "arith.ceildivsi"(%10#0, %11) : (i32, i32) -> i32
    %13 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %14 = "arith.ceildivsi"(%10#1, %13) : (i32, i32) -> i32
    %15 = "cute.make_int_tuple"(%12, %14) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %16:2 = "cute.get_leaves"(%15) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
    %17 = "cute.get_scalars"(%16#0) : (!cute.int_tuple<"?">) -> i32
    %18 = "cute.get_scalars"(%16#1) : (!cute.int_tuple<"?">) -> i32
    %19 = "cute.static"() : () -> !cute.tile<"[128:1;8:1]">
    %20 = "cute.static"() : () -> !cute.layout<"(256,4):(4,1)">
    %21 = "cute.static"() : () -> !cute.layout<"1:0">
    %22 = "cute.static"() : () -> !cute.layout<"(1,4):(0,1)">
    %23 = "cute.static"() : () -> !cute.layout<"(1,4):(0,1)">
    %24 = "cute.static"() : () -> !cute.tile<"[32:1;8:1]">
    %25 = "cute.static"() : () -> !cute.layout<"((8,32),1):((32,1),0)">
    %26 = "cute.static"() : () -> !cute.layout<"1:0">
    %27 = "cute.static"() : () -> !cute.layout<"(1,1):(0,1)">
    %28 = "cute.static"() : () -> !cute.layout<"(1,1):(0,1)">
    %29 = "cute.static"() : () -> !cute.layout<"(1,16,16,1):(0,16,1,0)">
    %30 = "cute.static"() : () -> !cute.tile<"[(16,4):(4,1);(16,4):(4,1);_]">
    %31 = "cute.static"() : () -> !cute.layout<"1:0">
    %32 = "cute.static"() : () -> !cute.shape<"(1,1,1)">
    %33 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
    %34 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
    %35 = "cute.static"() : () -> !cute.layout<"(1,1):(0,0)">
    %36 = "arith.constant"() <{value = 24944 : i32}> : () -> i32
    %37 = "arith.extsi"(%36) : (i32) -> i64
    %38 = "arith.constant"() <{value = 256 : i32}> : () -> i32
    %39 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %40 = "cuda.launch_cfg.create"(%38, %39, %39, %37, %17, %18, %39, %arg3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %41 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%40, %41) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %42 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%40, %42) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %43 = "cuda.launch_ex"(%40, %arg0, %arg1, %arg2) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %44 = "cuda.cast"(%43) : (!cuda.result) -> i32
    "cuda.return_if_error"(%44) : (i32) -> ()
    %45 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%45) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
