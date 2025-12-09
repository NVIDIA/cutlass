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
!memref_rmem_i8_4 = !cute.memref<i8, rmem, align<32>, "(1,(4,2),(4,2)):(0,(1,4),(8,32))">
!memref_smem_f32_ = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),128)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<16>, "(1,(4,2),8):(0,(1,64),132)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 256, 1, 1>} {
      %cst = arith.constant dense<0.000000e+00> : vector<64xf32>
      %0 = llvm.mlir.constant(0 : i8) : i8
      %1 = cute.static : !cute.int_tuple<"64">
      %2 = cute.static : !cute.shape<"(1,(((4,2),(4,2))))">
      %3 = cute.static : !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">
      %4 = cute.static : !cute.shape<"(1,((4,2),(4,2)))">
      %5 = cute.static : !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">
      %c64_i32 = arith.constant 64 : i32
      %c3_i32 = arith.constant 3 : i32
      %6 = cute.static : !cute.int_tuple<"8">
      %7 = cute.static : !cute.layout<"(1,(4,2),1):(0,(1,4),0)">
      %8 = cute.static : !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">
      %9 = cute.static : !cute.layout<"(1,(4,2),8):(0,(1,64),132)">
      %10 = cute.static : !cute.layout<"(1,(4,2),8):(0,(1,4),8)">
      %11 = cute.static : !cute.layout<"(1,(4,2),8):(0,(1,64),128)">
      %c7_i32 = arith.constant 7 : i32
      %12 = cute.static : !cute.int_tuple<"2">
      %13 = cute.static : !cute.layout<"(4,(2)):(1,(4))">
      %14 = cute.static : !cute.layout<"(4,(2)):(1,(64))">
      %15 = cute.static : !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">
      %16 = cute.static : !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">
      %17 = cute.static : !cute.shape<"(1,(4,2),(4,2))">
      %c64_i64 = arith.constant 64 : i64
      %c4_i64 = arith.constant 4 : i64
      %c16_i32 = arith.constant 16 : i32
      %18 = cute.static : !cute.layout<"(1,((4,1))):(4,((1,0)))">
      %19 = cute.static : !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">
      %20 = cute.static : !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">
      %c2_i32 = arith.constant 2 : i32
      %21 = cute.static : !cute.int_tuple<"4">
      %22 = cute.static : !cute.layout<"(1,((4,1))):(4,((1,1)))">
      %23 = cute.static : !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">
      %24 = cute.static : !cute.shape<"((1,1),((4,1)))">
      %25 = cute.static : !cute.shape<"((1,1),(4,1))">
      %26 = cute.static : !cute.shape<"((1,1),4,1)">
      %27 = cute.static : !cute.int_tuple<"1">
      %28 = cute.static : !cute.layout<"(1,((1,1))):(1,((1,1)))">
      %29 = cute.static : !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">
      %30 = cute.static : !cute.coord<"256">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %31 = cute.static : !cute.stride<"((0,0),32@0,0,8@1)">
      %32 = cute.static : !cute.stride<"(1@0,1@1,8@1)">
      %33 = cute.static : !cute.stride<"((1@0,1@1),(128@0,8@1))">
      %34 = cute.static : !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">
      %35 = cute.static : !cute.stride<"(1@0,1@1)">
      %36 = cute.static : !cute.int_tuple<"(0,0)">
      %c132_i32 = arith.constant 132 : i32
      %c32_i64 = arith.constant 32 : i64
      %c256_i32 = arith.constant 256 : i32
      %c4_i32 = arith.constant 4 : i32
      %c32_i32 = arith.constant 32 : i32
      %37 = cute.static : !cute.int_tuple<"12288">
      %38 = cute.static : !cute.shape<"(128,128)">
      %c8_i32 = arith.constant 8 : i32
      %c128_i64 = arith.constant 128 : i64
      %c128_i32 = arith.constant 128 : i32
      %39 = cute.static : !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">
      %40 = cute.static : !cute.layout<"1:0">
      %41 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %42 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %43 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %coord = cute.make_coord(%42, %43) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %44:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_0 = cute.make_coord(%44#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %idx = cute.crd2idx(%coord_0, %39) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1,256),(128,2048))">) -> !cute.int_tuple<"?{div=128}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_1 = cute.make_coord(%44#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg1) : !memref_gmem_f32_1
      %45:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">
      %46 = arith.ceildivsi %45#0, %c128_i32 : i32
      %47 = arith.muli %45#2, %c128_i64 : i64
      %48 = arith.ceildivsi %45#1, %c8_i32 : i32
      %shape = cute.make_shape(%46, %48) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %iv = cute.assume(%45#2) : (i64) -> !cute.i64<divby 64>
      %iv_2 = cute.assume(%47) : (i64) -> !cute.i64<divby 8192>
      %stride = cute.make_stride(%iv, %iv_2) : (!cute.i64<divby 64>, !cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=64},1),(?{i64 div=8192},8))">
      %lay_3 = cute.make_layout(%shape, %stride) : !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">
      %49:4 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">
      %shape_4 = cute.make_shape(%49#1) : (i32) -> !cute.shape<"(128,8,?)">
      %iv_5 = cute.assume(%49#2) : (i64) -> !cute.i64<divby 64>
      %stride_6 = cute.make_stride(%iv_5) : (!cute.i64<divby 64>) -> !cute.stride<"(?{i64 div=64},1,8)">
      %lay_7 = cute.make_layout(%shape_4, %stride_6) : !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %idx_8 = cute.crd2idx(%coord_1, %lay_3) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((?{i64 div=64},1),(?{i64 div=8192},8))">) -> !cute.int_tuple<"?{i64 div=8192}">
      %iter_9 = cute.get_iter(%arg1) : !memref_gmem_f32_1
      %ptr_10 = cute.add_offset(%iter_9, %idx_8) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_11 = cute.make_coord(%44#0, %44#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_12 = cute.get_layout(%arg2) : !memref_gmem_f32_2
      %50:3 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">
      %51 = arith.ceildivsi %50#0, %c128_i32 : i32
      %52 = arith.muli %50#2, %c128_i64 : i64
      %53 = arith.ceildivsi %50#1, %c128_i32 : i32
      %shape_13 = cute.make_shape(%51, %53) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_14 = cute.assume(%50#2) : (i64) -> !cute.i64<divby 256>
      %iv_15 = cute.assume(%52) : (i64) -> !cute.i64<divby 32768>
      %stride_16 = cute.make_stride(%iv_14, %iv_15) : (!cute.i64<divby 256>, !cute.i64<divby 32768>) -> !cute.stride<"((?{i64 div=256},1),(?{i64 div=32768},128))">
      %lay_17 = cute.make_layout(%shape_13, %stride_16) : !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">
      %54:4 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">
      %iv_18 = cute.assume(%54#2) : (i64) -> !cute.i64<divby 256>
      %stride_19 = cute.make_stride(%iv_18) : (!cute.i64<divby 256>) -> !cute.stride<"(?{i64 div=256},1)">
      %lay_20 = cute.make_layout(%38, %stride_19) : !cute.layout<"(128,128):(?{i64 div=256},1)">
      %idx_21 = cute.crd2idx(%coord_11, %lay_17) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=256},1),(?{i64 div=32768},128))">) -> !cute.int_tuple<"?{i64 div=128}">
      %iter_22 = cute.get_iter(%arg2) : !memref_gmem_f32_2
      %ptr_23 = cute.add_offset(%iter_22, %idx_21) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<f32, gmem, align<16>>
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_24 = cute.add_offset(%smem_ptr, %37) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"12288">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_25 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %iter_26 = cute.recast_iter(%ptr_24) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %coord_27 = cute.make_coord(%41) : (i32) -> !cute.coord<"?">
      %55 = cute.get_scalars(%coord_27) <{only_dynamic}> : !cute.coord<"?">
      %56 = arith.divsi %55, %c32_i32 : i32
      %57 = arith.remsi %55, %c32_i32 : i32
      %58 = arith.muli %57, %c4_i32 : i32
      %59 = arith.muli %56, %c256_i32 : i32
      %60 = arith.addi %58, %59 : i32
      %iv_28 = cute.assume(%60) : (i32) -> !cute.i32<divby 4>
      %int_tuple = cute.make_int_tuple(%iv_28) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_29 = cute.add_offset(%ptr, %int_tuple) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %61 = arith.muli %55, %c4_i32 : i32
      %iv_30 = cute.assume(%61) : (i32) -> !cute.i32<divby 4>
      %int_tuple_31 = cute.make_int_tuple(%iv_30) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_32 = cute.add_offset(%iter_25, %int_tuple_31) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %62:2 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(128,8,?):(?{i64 div=64},1,8)">
      %63 = arith.muli %62#1, %c32_i64 : i64
      %64 = arith.divsi %55, %c8_i32 : i32
      %65 = arith.remsi %55, %c8_i32 : i32
      %66 = arith.extsi %64 : i32 to i64
      %67 = arith.muli %66, %62#1 : i64
      %68 = arith.extsi %65 : i32 to i64
      %69 = arith.addi %68, %67 : i64
      %int_tuple_33 = cute.make_int_tuple(%69) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_34 = cute.add_offset(%ptr_10, %int_tuple_33) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %shape_35 = cute.make_shape(%62#0) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %iv_36 = cute.assume(%63) : (i64) -> !cute.i64<divby 2048>
      %stride_37 = cute.make_stride(%iv_36) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0,8)">
      %lay_38 = cute.make_layout(%shape_35, %stride_37) : !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %70 = arith.muli %65, %c132_i32 : i32
      %71 = arith.addi %70, %64 : i32
      %int_tuple_39 = cute.make_int_tuple(%71) : (i32) -> !cute.int_tuple<"?">
      %ptr_40 = cute.add_offset(%iter_26, %int_tuple_39) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<f32, smem>
      %72 = cute.get_shape(%lay) : (!cute.layout<"(?,?{div=64}):(?{i64 div=64},1)">) -> !cute.shape<"(?,?{div=64})">
      %e0, %e1 = cute.get_leaves(%72) : !cute.shape<"(?,?{div=64})">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_41 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=64}"> to !cute.int_tuple<"?{div=64}">
      %shape_42 = cute.make_shape(%itup, %itup_41) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=64}">) -> !cute.shape<"(?,?{div=64})">
      %lay_43 = cute.make_layout(%shape_42, %35) : !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %idx_44 = cute.crd2idx(%coord_0, %34) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(2,8)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %tup = cute.add_offset(%36, %idx_44) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %e0_45, %e1_46 = cute.get_leaves(%tup) : !cute.int_tuple<"(?{div=128},0)">
      %73:2 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(?,?{div=64}):(1@0,1@1)">
      %74 = arith.ceildivsi %73#0, %c128_i32 : i32
      %75 = arith.ceildivsi %73#1, %c8_i32 : i32
      %shape_47 = cute.make_shape(%74, %75) : (i32, i32) -> !cute.shape<"((128,8),(?,?))">
      %lay_48 = cute.make_layout(%shape_47, %33) : !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">
      %76:2 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">
      %shape_49 = cute.make_shape(%76#1) : (i32) -> !cute.shape<"(128,8,?)">
      %lay_50 = cute.make_layout(%shape_49, %32) : !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %idx_51 = cute.crd2idx(%coord_1, %lay_48) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,8),(?,?)):((1@0,1@1),(128@0,8@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %tup_52 = cute.add_offset(%36, %idx_51) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0)">
      %e0_53, %e1_54 = cute.get_leaves(%tup_52) : !cute.int_tuple<"(?{div=128},0)">
      %int_tuple_55 = cute.make_int_tuple(%e0_45) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %e0_56, %e1_57 = cute.get_leaves(%int_tuple_55) : !cute.int_tuple<"(?{div=128},0)">
      %int_tuple_58 = cute.make_int_tuple(%e0_56) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %int_tuple_59 = cute.make_int_tuple(%e0_53) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %e0_60, %e1_61 = cute.get_leaves(%int_tuple_59) : !cute.int_tuple<"(?{div=128},0)">
      %int_tuple_62 = cute.make_int_tuple(%e0_60) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0)">
      %iv_63 = cute.assume(%58) : (i32) -> !cute.i32<divby 4>
      %int_tuple_64 = cute.make_int_tuple(%iv_63, %56) : (!cute.i32<divby 4>, i32) -> !cute.int_tuple<"(?{div=4},?)">
      %tup_65 = cute.add_offset(%int_tuple_58, %int_tuple_64) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(?{div=4},?)">) -> !cute.int_tuple<"(?{div=4},?)">
      %77 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"(128,8,?):(1@0,1@1,8@1)">
      %int_tuple_66 = cute.make_int_tuple(%64, %65) : (i32, i32) -> !cute.int_tuple<"(?,?)">
      %tup_67 = cute.add_offset(%int_tuple_62, %int_tuple_66) : (!cute.int_tuple<"(?{div=128},0)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %shape_68 = cute.make_shape(%77) : (i32) -> !cute.shape<"((1,1),4,1,?)">
      %lay_69 = cute.make_layout(%shape_68, %31) : !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">
      %rmem = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_70 = cute.memref.alloca() : !memref_rmem_i8_1
      %rmem_71 = cute.memref.alloca() : !memref_rmem_i8_2
      %rmem_72 = cute.memref.alloca() : !memref_rmem_i8_3
      %e0_73, %e1_74 = cute.get_leaves(%tup_65) : !cute.int_tuple<"(?{div=4},?)">
      %coord_75 = cute.make_coord(%e0_73) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"?{div=4}">
      %78 = cute.get_scalars(%coord_75) : !cute.coord<"?{div=4}">
      %79 = cute.get_scalars(%30) : !cute.coord<"256">
      %80 = arith.cmpi slt, %78, %79 : i32
      %81 = arith.extui %80 : i1 to i8
      %coord_76 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %dyn = cute.derefine(%coord_76) : !cute.coord<"(0,0,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem, %dyn, %81) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %iter_77 = cute.get_iter(%rmem) : !memref_rmem_i8_
      %coord_78 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %82 = cute.get_scalars(%coord_78) : !cute.coord<"?">
      scf.for %arg3 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"((0,0),?,0,0)">
        %idx_152 = cute.crd2idx(%coord_151, %lay_69) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
        %tup_153 = cute.add_offset(%tup_67, %idx_152) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?)">
        %e0_154, %e1_155 = cute.get_leaves(%tup_153) : !cute.int_tuple<"(?,?)">
        %coord_156 = cute.make_coord(%e0_154) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %120 = cute.get_scalars(%coord_156) : !cute.coord<"?">
        %121 = arith.cmpi slt, %120, %82 : i32
        %122 = arith.extui %121 : i1 to i8
        %coord_157 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(0,?,0)">
        %dyn_158 = cute.derefine(%coord_157) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
        cute.memref.store(%rmem_70, %dyn_158, %122) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
      }
      %iter_79 = cute.get_iter(%rmem_70) : !memref_rmem_i8_1
      %coord_80 = cute.make_coord(%e0_73) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},-1)">
      %dyn_81 = cute.derefine(%coord_80) : !cute.coord<"(?{div=4},-1)"> to !cute.coord<"(?{div=4},?)">
      %coord_82 = cute.make_coord(%e1_74) : (!cute.int_tuple<"?">) -> !cute.coord<"(256,?)">
      %83:2 = cute.get_scalars(%dyn_81) : !cute.coord<"(?{div=4},?)">
      %84:2 = cute.get_scalars(%coord_82) : !cute.coord<"(256,?)">
      %85 = arith.cmpi slt, %83#0, %84#0 : i32
      %86 = arith.cmpi slt, %83#1, %84#1 : i32
      %87 = arith.andi %85, %86 : i1
      %88 = arith.extui %87 : i1 to i8
      %dyn_83 = cute.derefine(%coord_76) : !cute.coord<"(0,0,0)"> to !cute.coord<"(?,?,?)">
      cute.memref.store(%rmem_71, %dyn_83, %88) : (!memref_rmem_i8_2, !cute.coord<"(?,?,?)">, i8) -> ()
      %iter_84 = cute.get_iter(%rmem_71) : !memref_rmem_i8_2
      scf.for %arg3 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"((0,0),?,0,0)">
        %idx_152 = cute.crd2idx(%coord_151, %lay_69) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
        %tup_153 = cute.add_offset(%tup_67, %idx_152) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?)">
        %e0_154, %e1_155 = cute.get_leaves(%tup_153) : !cute.int_tuple<"(?,?)">
        %coord_156 = cute.make_coord(%e0_154) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,-1)">
        %dyn_157 = cute.derefine(%coord_156) : !cute.coord<"(?,-1)"> to !cute.coord<"(?,?)">
        %coord_158 = cute.make_coord(%itup, %e1_155) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %120:2 = cute.get_scalars(%dyn_157) : !cute.coord<"(?,?)">
        %121:2 = cute.get_scalars(%coord_158) : !cute.coord<"(?,?)">
        %122 = arith.cmpi slt, %120#0, %121#0 : i32
        %123 = arith.cmpi slt, %120#1, %121#1 : i32
        %124 = arith.andi %122, %123 : i1
        %125 = arith.extui %124 : i1 to i8
        %coord_159 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(0,?,0)">
        %dyn_160 = cute.derefine(%coord_159) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,?)">
        cute.memref.store(%rmem_72, %dyn_160, %125) : (!memref_rmem_i8_3, !cute.coord<"(?,?,?)">, i8) -> ()
      }
      %iter_85 = cute.get_iter(%rmem_72) : !memref_rmem_i8_3
      %89 = cute.get_scalars(%27) : !cute.int_tuple<"1">
      %iter_86 = cute.recast_iter(%ptr_29) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_87 = cute.recast_iter(%ptr_32) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
      scf.for %arg3 = %c0_i32 to %89 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((1,1))):(1,((1,1)))">) -> !cute.int_tuple<"?">
        %ptr_153 = cute.add_offset(%iter_84, %idx_152) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<i8, rmem> to !llvm.ptr
        %121 = llvm.load %120 : !llvm.ptr -> i8
        %122 = llvm.trunc %121 : i8 to i1
        cute_nvgpu.arch.copy.SM80.cp_async(%iter_87 : !cute.ptr<i128, smem>, %iter_86 : !cute.ptr<i128, gmem>, %122 : i1) {cache_mode = <always>}
      } {llvm.loop_annotation = #loop_annotation}
      %90:2 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %iv_88 = cute.assume(%90#1) : (i64) -> !cute.i64<divby 2048>
      %stride_89 = cute.make_stride(%iv_88) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %lay_90 = cute.make_layout(%26, %stride_89) : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %append = cute.append_to_rank<2> (%lay_90, %40) : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">
      %91 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %iv_91 = cute.assume(%91) : (i64) -> !cute.i64<divby 2048>
      %stride_92 = cute.make_stride(%iv_91) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %lay_93 = cute.make_layout(%25, %stride_92) : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %append_94 = cute.append_to_rank<2> (%lay_93, %40) : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">
      %92 = cute.get_scalars(%append_94) <{only_dynamic}> : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %iv_95 = cute.assume(%92) : (i64) -> !cute.i64<divby 2048>
      %stride_96 = cute.make_stride(%iv_95) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %lay_97 = cute.make_layout(%24, %stride_96) : !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      %93 = cute.get_scalars(%21) : !cute.int_tuple<"4">
      scf.for %arg3 = %c0_i32 to %93 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %lay_97) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
        %ptr_153 = cute.add_offset(%ptr_34, %idx_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
        %idx_154 = cute.crd2idx(%coord_151, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_155 = cute.add_offset(%ptr_40, %idx_154) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
        %idx_156 = cute.crd2idx(%coord_151, %22) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,1)))">) -> !cute.int_tuple<"?">
        %ptr_157 = cute.add_offset(%iter_85, %idx_156) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
        %121 = llvm.load %120 : !llvm.ptr -> i8
        %122 = llvm.trunc %121 : i8 to i1
        %iter_158 = cute.recast_iter(%ptr_153) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
        %iter_159 = cute.recast_iter(%ptr_155) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
        cute_nvgpu.arch.copy.SM80.cp_async(%iter_159 : !cute.ptr<i32, smem>, %iter_158 : !cute.ptr<i32, gmem>, %122 : i1) {cache_mode = <always>}
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.commit.group
      %coord_98 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
      %idx_99 = cute.crd2idx(%coord_98, %29) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"2048">
      %ptr_100 = cute.add_offset(%ptr_29, %idx_99) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<f32, gmem, align<16>>
      %idx_101 = cute.crd2idx(%coord_98, %20) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"1024">
      %ptr_102 = cute.add_offset(%ptr_32, %idx_101) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<f32, smem, align<16>>
      %94 = builtin.unrealized_conversion_cast %iter_77 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %iter_103 = cute.recast_iter(%ptr_100) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_104 = cute.recast_iter(%ptr_102) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
      scf.for %arg3 = %c0_i32 to %89 step %c1_i32  : i32 {
        %120 = llvm.load %94 : !llvm.ptr -> i8
        %121 = llvm.trunc %120 : i8 to i1
        cute_nvgpu.arch.copy.SM80.cp_async(%iter_104 : !cute.ptr<i128, smem>, %iter_103 : !cute.ptr<i128, gmem>, %121 : i1) {cache_mode = <always>}
      } {llvm.loop_annotation = #loop_annotation}
      %idx_105 = cute.crd2idx(%coord_98, %lay_38) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"8">
      %ptr_106 = cute.add_offset(%ptr_34, %idx_105) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"8">) -> !cute.ptr<f32, gmem>
      %idx_107 = cute.crd2idx(%coord_98, %19) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"1056">
      %ptr_108 = cute.add_offset(%ptr_40, %idx_107) : (!cute.ptr<f32, smem>, !cute.int_tuple<"1056">) -> !cute.ptr<f32, smem>
      scf.for %arg3 = %c0_i32 to %93 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %lay_97) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
        %ptr_153 = cute.add_offset(%ptr_106, %idx_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
        %idx_154 = cute.crd2idx(%coord_151, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_155 = cute.add_offset(%ptr_108, %idx_154) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
        %idx_156 = cute.crd2idx(%coord_151, %18) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
        %ptr_157 = cute.add_offset(%iter_79, %idx_156) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
        %121 = llvm.load %120 : !llvm.ptr -> i8
        %122 = llvm.trunc %121 : i8 to i1
        %iter_158 = cute.recast_iter(%ptr_153) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
        %iter_159 = cute.recast_iter(%ptr_155) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
        cute_nvgpu.arch.copy.SM80.cp_async(%iter_159 : !cute.ptr<i32, smem>, %iter_158 : !cute.ptr<i32, gmem>, %122 : i1) {cache_mode = <always>}
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.commit.group
      %95 = arith.divsi %55, %c16_i32 : i32
      %96 = arith.remsi %95, %c16_i32 : i32
      %97 = arith.remsi %96, %c16_i32 : i32
      %98 = arith.muli %97, %c4_i32 : i32
      %iv_109 = cute.assume(%98) : (i32) -> !cute.i32<divby 4>
      %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_111 = cute.add_offset(%iter_25, %int_tuple_110) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %99 = arith.remsi %55, %c16_i32 : i32
      %100 = arith.remsi %99, %c16_i32 : i32
      %101 = arith.muli %100, %c4_i32 : i32
      %iv_112 = cute.assume(%101) : (i32) -> !cute.i32<divby 4>
      %int_tuple_113 = cute.make_int_tuple(%iv_112) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_114 = cute.add_offset(%iter_26, %int_tuple_113) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %102 = cute.get_scalars(%lay_20) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=256},1)">
      %103 = arith.muli %102, %c4_i64 : i64
      %104 = arith.muli %102, %c64_i64 : i64
      %105 = arith.extsi %97 : i32 to i64
      %106 = arith.muli %105, %103 : i64
      %107 = arith.extsi %101 : i32 to i64
      %108 = arith.addi %106, %107 : i64
      %iv_115 = cute.assume(%108) : (i64) -> !cute.i64<divby 4>
      %int_tuple_116 = cute.make_int_tuple(%iv_115) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_117 = cute.add_offset(%ptr_23, %int_tuple_116) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %iv_118 = cute.assume(%102) : (i64) -> !cute.i64<divby 256>
      %iv_119 = cute.assume(%104) : (i64) -> !cute.i64<divby 16384>
      %stride_120 = cute.make_stride(%iv_118, %iv_119) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %lay_121 = cute.make_layout(%17, %stride_120) : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %rmem_122 = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_123 = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_124 = cute.memref.alloca() : !memref_rmem_f32_1
      %iter_125 = cute.get_iter(%rmem_124) : !memref_rmem_f32_1
      cute.memref.store_vec %cst, %rmem_124 : !memref_rmem_f32_1
      %view = cute.make_view(%ptr_111) : !memref_smem_f32_
      %view_126 = cute.make_view(%ptr_114) : !memref_smem_f32_1
      nvvm.cp.async.wait.group 1
      nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
      %iter_127 = cute.get_iter(%rmem_122) : !memref_rmem_f32_
      %109 = cute.get_scalars(%12) : !cute.int_tuple<"2">
      scf.for %arg3 = %c0_i32 to %109 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_153 = cute.add_offset(%ptr_111, %idx_152) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
        %idx_154 = cute.crd2idx(%coord_151, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
        %ptr_155 = cute.add_offset(%iter_127, %idx_154) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
        %121 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem> to !llvm.ptr
        %122 = llvm.load %120 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
        llvm.store %122, %121 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %iter_128 = cute.get_iter(%rmem_123) : !memref_rmem_f32_
      scf.for %arg3 = %c0_i32 to %109 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_153 = cute.add_offset(%ptr_114, %idx_152) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
        %idx_154 = cute.crd2idx(%coord_151, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
        %ptr_155 = cute.add_offset(%iter_128, %idx_154) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
        %121 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem> to !llvm.ptr
        %122 = llvm.load %120 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
        llvm.store %122, %121 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %110 = cute.get_scalars(%6) : !cute.int_tuple<"8">
      %111:5 = scf.for %arg3 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg4 = %view, %arg5 = %view_126, %arg6 = %c2_i32, %arg7 = %c0_i32, %arg8 = %c2_i32) -> (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32)  : i32 {
        %120 = arith.addi %c0_i32, %c1_i32 : i32
        %121 = arith.remsi %120, %c8_i32 : i32
        %122:6 = scf.for %arg9 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg10 = %arg4, %arg11 = %arg5, %arg12 = %arg6, %arg13 = %arg7, %arg14 = %arg8, %arg15 = %121) -> (!memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32, i32)  : i32 {
          %123 = arith.cmpi eq, %arg9, %c7_i32 : i32
          %124:2 = scf.if %123 -> (!memref_smem_f32_, !memref_smem_f32_1) {
            %coord_167 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_168 = cute.crd2idx(%coord_167, %16) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_169 = cute.add_offset(%ptr_111, %idx_168) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %view_170 = cute.make_view(%ptr_169) : !memref_smem_f32_
            %idx_171 = cute.crd2idx(%coord_167, %15) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %ptr_172 = cute.add_offset(%ptr_114, %idx_171) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
            %view_173 = cute.make_view(%ptr_172) : !memref_smem_f32_1
            nvvm.cp.async.wait.group 1
            nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
            scf.yield %view_170, %view_173 : !memref_smem_f32_, !memref_smem_f32_1
          } else {
            scf.yield %arg10, %arg11 : !memref_smem_f32_, !memref_smem_f32_1
          }
          %125 = arith.addi %arg9, %c1_i32 : i32
          %coord_151 = cute.make_coord(%arg15) : (i32) -> !cute.coord<"(_,_,?)">
          %idx_152 = cute.crd2idx(%coord_151, %11) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),128)">) -> !cute.int_tuple<"?{div=128}">
          %iter_153 = cute.get_iter(%124#0) : !memref_smem_f32_
          %ptr_154 = cute.add_offset(%iter_153, %idx_152) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, smem, align<16>>
          %idx_155 = cute.crd2idx(%coord_151, %10) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %ptr_156 = cute.add_offset(%iter_127, %idx_155) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          scf.for %arg16 = %c0_i32 to %109 step %c1_i32  : i32 {
            %coord_167 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
            %idx_168 = cute.crd2idx(%coord_167, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_169 = cute.add_offset(%ptr_154, %idx_168) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %idx_170 = cute.crd2idx(%coord_167, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %ptr_171 = cute.add_offset(%ptr_156, %idx_170) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %132 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
            %133 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<f32, rmem> to !llvm.ptr
            %134 = llvm.load %132 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
            llvm.store %134, %133 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %idx_157 = cute.crd2idx(%coord_151, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),132)">) -> !cute.int_tuple<"?{div=132}">
          %iter_158 = cute.get_iter(%124#1) : !memref_smem_f32_1
          %ptr_159 = cute.add_offset(%iter_158, %idx_157) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=132}">) -> !cute.ptr<f32, smem, align<16>>
          %ptr_160 = cute.add_offset(%iter_128, %idx_155) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          scf.for %arg16 = %c0_i32 to %109 step %c1_i32  : i32 {
            %coord_167 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
            %idx_168 = cute.crd2idx(%coord_167, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_169 = cute.add_offset(%ptr_159, %idx_168) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
            %idx_170 = cute.crd2idx(%coord_167, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
            %ptr_171 = cute.add_offset(%ptr_160, %idx_170) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
            %132 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
            %133 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<f32, rmem> to !llvm.ptr
            %134 = llvm.load %132 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
            llvm.store %134, %133 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %126 = arith.cmpi eq, %arg9, %c0_i32 : i32
          scf.if %126 {
            %coord_167 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_168 = cute.crd2idx(%coord_167, %29) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_169 = cute.add_offset(%ptr_29, %idx_168) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
            %coord_170 = cute.make_coord(%arg12) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_171 = cute.crd2idx(%coord_170, %20) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_172 = cute.add_offset(%ptr_32, %idx_171) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
            %132 = builtin.unrealized_conversion_cast %iter_77 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %iter_173 = cute.recast_iter(%ptr_169) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_174 = cute.recast_iter(%ptr_172) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
            scf.for %arg16 = %c0_i32 to %89 step %c1_i32  : i32 {
              %133 = llvm.load %132 : !llvm.ptr -> i8
              %134 = llvm.trunc %133 : i8 to i1
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_174 : !cute.ptr<i128, smem>, %iter_173 : !cute.ptr<i128, gmem>, %134 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          }
          %coord_161 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,_,?)">
          %idx_162 = cute.crd2idx(%coord_161, %10) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
          %ptr_163 = cute.add_offset(%iter_127, %idx_162) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          %ptr_164 = cute.add_offset(%iter_128, %idx_162) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
          scf.for %arg16 = %c0_i32 to %89 step %c1_i32  : i32 {
            scf.for %arg17 = %c0_i32 to %110 step %c1_i32  : i32 {
              %coord_167 = cute.make_coord(%arg17, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_168 = cute.crd2idx(%coord_167, %7) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
              %ptr_169 = cute.add_offset(%ptr_163, %idx_168) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
              %view_170 = cute.make_view(%ptr_169) : !memref_rmem_f32_2
              scf.for %arg18 = %c0_i32 to %110 step %c1_i32  : i32 {
                %coord_171 = cute.make_coord(%arg18, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %coord_172 = cute.make_coord(%arg17, %arg18) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %idx_173 = cute.crd2idx(%coord_171, %7) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
                %ptr_174 = cute.add_offset(%ptr_164, %idx_173) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
                %idx_175 = cute.crd2idx(%coord_172, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !cute.int_tuple<"?">
                %ptr_176 = cute.add_offset(%iter_125, %idx_175) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
                %view_177 = cute.make_view(%ptr_174) : !memref_rmem_f32_2
                %view_178 = cute.make_view(%ptr_176) : !memref_rmem_f32_2
                %132 = cute.memref.load_vec %view_170 : !memref_rmem_f32_2
                %133 = cute.memref.load_vec %view_177 : !memref_rmem_f32_2
                %134 = cute.memref.load_vec %view_178 : !memref_rmem_f32_2
                %135 = math.fma %132, %133, %134 : vector<1xf32>
                cute.memref.store_vec %135, %view_178 : !memref_rmem_f32_2
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %127 = arith.select %126, %arg13, %arg12 : i32
          %128:2 = scf.if %126 -> (i32, i32) {
            %coord_167 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_168 = cute.crd2idx(%coord_167, %lay_38) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_169 = cute.add_offset(%ptr_34, %idx_168) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
            %coord_170 = cute.make_coord(%arg12) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_171 = cute.crd2idx(%coord_170, %19) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
            %ptr_172 = cute.add_offset(%ptr_40, %idx_171) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
            scf.for %arg16 = %c0_i32 to %93 step %c1_i32  : i32 {
              %coord_173 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
              %idx_174 = cute.crd2idx(%coord_173, %lay_97) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
              %ptr_175 = cute.add_offset(%ptr_169, %idx_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
              %idx_176 = cute.crd2idx(%coord_173, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
              %ptr_177 = cute.add_offset(%ptr_172, %idx_176) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
              %idx_178 = cute.crd2idx(%coord_173, %18) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
              %ptr_179 = cute.add_offset(%iter_79, %idx_178) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %138 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<i8, rmem> to !llvm.ptr
              %139 = llvm.load %138 : !llvm.ptr -> i8
              %140 = llvm.trunc %139 : i8 to i1
              %iter_180 = cute.recast_iter(%ptr_175) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
              %iter_181 = cute.recast_iter(%ptr_177) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_181 : !cute.ptr<i32, smem>, %iter_180 : !cute.ptr<i32, gmem>, %140 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.cp.async.commit.group
            %132 = arith.addi %arg13, %c1_i32 : i32
            %133 = arith.cmpi eq, %132, %c3_i32 : i32
            %134 = arith.select %133, %c0_i32, %132 : i32
            %135 = arith.addi %arg14, %c1_i32 : i32
            %136 = arith.cmpi slt, %135, %c8_i32 : i32
            %137 = arith.select %136, %135, %c1_i32 : i32
            scf.yield %134, %137 : i32, i32
          } else {
            scf.yield %arg13, %arg14 : i32, i32
          }
          %c1_i32_165 = arith.constant 1 : i32
          %129 = arith.addi %arg15, %c1_i32_165 : i32
          %130 = arith.cmpi eq, %129, %c8_i32 : i32
          %c0_i32_166 = arith.constant 0 : i32
          %131 = arith.select %130, %c0_i32_166, %129 : i32
          scf.yield %124#0, %124#1, %127, %128#0, %128#1, %131 : !memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32, i32
        } {loop_annotation = #loop_annotation1}
        scf.yield %122#0, %122#1, %122#2, %122#3, %122#4 : !memref_smem_f32_, !memref_smem_f32_1, i32, i32, i32
      }
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
      %112 = cute.memref.load_vec %rmem_124 : !memref_rmem_f32_1
      cute.memref.store_vec %112, %rmem_124 : !memref_rmem_f32_1
      %int_tuple_129 = cute.make_int_tuple(%iv_109, %iv_112) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_130 = cute.add_offset(%36, %int_tuple_129) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_131 = cute.memref.alloca() : !memref_rmem_i8_4
      %113 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %e0_132, %e1_133 = cute.get_leaves(%113) : !cute.shape<"(?,?{div=256})">
      %itup_134 = cute.to_int_tuple(%e0_132) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_135 = cute.to_int_tuple(%e1_133) : !cute.shape<"?{div=256}"> to !cute.int_tuple<"?{div=256}">
      %114 = arith.muli %42, %c128_i32 : i32
      %int_tuple_136 = cute.make_int_tuple(%114) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%itup_134, %int_tuple_136) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %115 = arith.muli %43, %c128_i32 : i32
      %int_tuple_137 = cute.make_int_tuple(%115) : (i32) -> !cute.int_tuple<"?">
      %sub_138 = cute.tuple_sub(%itup_135, %int_tuple_137) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %coord_139 = cute.make_coord(%sub, %sub_138) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %116:2 = cute.get_scalars(%coord_139) : !cute.coord<"(?,?)">
      scf.for %arg3 = %c0_i32 to %c64_i32 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"?">
        %idx_152 = cute.crd2idx(%coord_151, %5) : (!cute.coord<"?">, !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.int_tuple<"(?,?)">
        %tup_153 = cute.add_offset(%tup_130, %idx_152) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %e0_154, %e1_155 = cute.get_leaves(%tup_153) : !cute.int_tuple<"(?,?)">
        %coord_156 = cute.make_coord(%e0_154, %e1_155) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %120:2 = cute.get_scalars(%coord_156) : !cute.coord<"(?,?)">
        %121 = arith.cmpi slt, %120#0, %116#0 : i32
        %122 = arith.cmpi slt, %120#1, %116#1 : i32
        %123 = arith.andi %121, %122 : i1
        %124 = arith.extui %123 : i1 to i8
        cute.memref.store(%rmem_131, %coord_151, %124) : (!memref_rmem_i8_4, !cute.coord<"?">, i8) -> ()
      }
      %iter_140 = cute.get_iter(%rmem_131) : !memref_rmem_i8_4
      %append_141 = cute.append_to_rank<2> (%lay_121, %40) : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">, !cute.layout<"1:0">
      %117:2 = cute.get_scalars(%append_141) <{only_dynamic}> : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %iv_142 = cute.assume(%117#0) : (i64) -> !cute.i64<divby 256>
      %iv_143 = cute.assume(%117#1) : (i64) -> !cute.i64<divby 16384>
      %stride_144 = cute.make_stride(%iv_142, %iv_143) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %lay_145 = cute.make_layout(%4, %stride_144) : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %append_146 = cute.append_to_rank<2> (%lay_145, %40) : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">, !cute.layout<"1:0">
      %118:2 = cute.get_scalars(%append_146) <{only_dynamic}> : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %iv_147 = cute.assume(%118#0) : (i64) -> !cute.i64<divby 256>
      %iv_148 = cute.assume(%118#1) : (i64) -> !cute.i64<divby 16384>
      %stride_149 = cute.make_stride(%iv_147, %iv_148) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %lay_150 = cute.make_layout(%2, %stride_149) : !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %119 = cute.get_scalars(%1) : !cute.int_tuple<"64">
      scf.for %arg3 = %c0_i32 to %119 step %c1_i32  : i32 {
        %coord_151 = cute.make_coord(%arg3) : (i32) -> !cute.coord<"(_,?)">
        %idx_152 = cute.crd2idx(%coord_151, %3) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
        %ptr_153 = cute.add_offset(%iter_125, %idx_152) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
        %idx_154 = cute.crd2idx(%coord_151, %lay_150) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.int_tuple<"?{i64}">
        %ptr_155 = cute.add_offset(%ptr_117, %idx_154) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %ptr_156 = cute.add_offset(%iter_140, %idx_152) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %120 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<i8, rmem> to !llvm.ptr
        %121 = llvm.load %120 : !llvm.ptr -> i8
        %122 = llvm.icmp "ne" %121, %0 : i8
        scf.if %122 {
          %123 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
          %124 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass___call_____main__SGemm_object_at__Tensorgmemo256641256_Tensorgmemodiv64i64div641_Tensorgmemodiv256i64div2561_functionlambdaat_CUstream0x0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c24944_i64 = arith.constant 24944 : i64
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %c256_i32 = arith.constant 256 : i32
    %c128_i32 = arith.constant 128 : i32
    %lay = cute.get_layout(%arg2) : !memref_gmem_f32_2
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
    %e0, %e1 = cute.get_leaves(%0) : !cute.shape<"(?,?{div=256})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=256}"> to !cute.int_tuple<"?{div=256}">
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 32 b>
    %atom_1 = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<f32, cache = always, 128 b>
    %1 = cute.make_tiled_copy(%atom_1) : !copy_ldgsts
    %2 = cute.make_tiled_copy(%atom) : !copy_ldgsts1
    %int_tuple = cute.make_int_tuple(%itup, %itup_0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?,?{div=256})">
    %3:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=256})">
    %4 = arith.ceildivsi %3#0, %c128_i32 : i32
    %5 = arith.ceildivsi %3#1, %c128_i32 : i32
    %int_tuple_2 = cute.make_int_tuple(%4, %5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %e0_3, %e1_4 = cute.get_leaves(%int_tuple_2) : !cute.int_tuple<"(?,?)">
    %6 = cute.get_scalars(%e0_3) : !cute.int_tuple<"?">
    %7 = cute.get_scalars(%e1_4) : !cute.int_tuple<"?">
    %8 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c256_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c24944_i64, gridDim = (%6, %7, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %9 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__SGemm_object_at__tensorptrf32gmemalign16o256641256_tensorptrf32gmemalign16odiv64i64div641_tensorptrf32gmemalign16odiv256i64div2561_TiledCopy_TilerMN128181_TV_0<%8> (%arg0, %arg1, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %10 = cuda.cast %9 : !cuda.result -> i32
    cuda.return_if_error %10 : i32
    return %c0_i32 : i32
  }
}
