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
      cf.br ^bb1(%c0_i32 : i32)
    ^bb1(%83: i32):  // 2 preds: ^bb0, ^bb2
      %84 = arith.cmpi slt, %83, %c4_i32 : i32
      cf.cond_br %84, ^bb2, ^bb3
    ^bb2:  // pred: ^bb1
      %coord_79 = cute.make_coord(%83) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_80 = cute.crd2idx(%coord_79, %lay_69) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_81 = cute.add_offset(%tup_67, %idx_80) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?)">
      %e0_82, %e1_83 = cute.get_leaves(%tup_81) : !cute.int_tuple<"(?,?)">
      %coord_84 = cute.make_coord(%e0_82) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %85 = cute.get_scalars(%coord_84) : !cute.coord<"?">
      %86 = arith.cmpi slt, %85, %82 : i32
      %87 = arith.extui %86 : i1 to i8
      %coord_85 = cute.make_coord(%83) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_86 = cute.derefine(%coord_85) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem_70, %dyn_86, %87) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
      %88 = arith.addi %83, %c1_i32 : i32
      cf.br ^bb1(%88 : i32)
    ^bb3:  // pred: ^bb1
      %iter_87 = cute.get_iter(%rmem_70) : !memref_rmem_i8_1
      %coord_88 = cute.make_coord(%e0_73) : (!cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},-1)">
      %dyn_89 = cute.derefine(%coord_88) : !cute.coord<"(?{div=4},-1)"> to !cute.coord<"(?{div=4},?)">
      %coord_90 = cute.make_coord(%e1_74) : (!cute.int_tuple<"?">) -> !cute.coord<"(256,?)">
      %89:2 = cute.get_scalars(%dyn_89) : !cute.coord<"(?{div=4},?)">
      %90:2 = cute.get_scalars(%coord_90) : !cute.coord<"(256,?)">
      %91 = arith.cmpi slt, %89#0, %90#0 : i32
      %92 = arith.cmpi slt, %89#1, %90#1 : i32
      %93 = arith.andi %91, %92 : i1
      %94 = arith.extui %93 : i1 to i8
      %dyn_91 = cute.derefine(%coord_76) : !cute.coord<"(0,0,0)"> to !cute.coord<"(?,?,?)">
      cute.memref.store(%rmem_71, %dyn_91, %94) : (!memref_rmem_i8_2, !cute.coord<"(?,?,?)">, i8) -> ()
      %iter_92 = cute.get_iter(%rmem_71) : !memref_rmem_i8_2
      cf.br ^bb4(%c0_i32 : i32)
    ^bb4(%95: i32):  // 2 preds: ^bb3, ^bb5
      %96 = arith.cmpi slt, %95, %c4_i32 : i32
      cf.cond_br %96, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %coord_93 = cute.make_coord(%95) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_94 = cute.crd2idx(%coord_93, %lay_69) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((1,1),4,1,?):((0,0),32@0,0,8@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_95 = cute.add_offset(%tup_67, %idx_94) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?)">
      %e0_96, %e1_97 = cute.get_leaves(%tup_95) : !cute.int_tuple<"(?,?)">
      %coord_98 = cute.make_coord(%e0_96) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,-1)">
      %dyn_99 = cute.derefine(%coord_98) : !cute.coord<"(?,-1)"> to !cute.coord<"(?,?)">
      %coord_100 = cute.make_coord(%itup, %e1_97) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %97:2 = cute.get_scalars(%dyn_99) : !cute.coord<"(?,?)">
      %98:2 = cute.get_scalars(%coord_100) : !cute.coord<"(?,?)">
      %99 = arith.cmpi slt, %97#0, %98#0 : i32
      %100 = arith.cmpi slt, %97#1, %98#1 : i32
      %101 = arith.andi %99, %100 : i1
      %102 = arith.extui %101 : i1 to i8
      %coord_101 = cute.make_coord(%95) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_102 = cute.derefine(%coord_101) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,?)">
      cute.memref.store(%rmem_72, %dyn_102, %102) : (!memref_rmem_i8_3, !cute.coord<"(?,?,?)">, i8) -> ()
      %103 = arith.addi %95, %c1_i32 : i32
      cf.br ^bb4(%103 : i32)
    ^bb6:  // pred: ^bb4
      %iter_103 = cute.get_iter(%rmem_72) : !memref_rmem_i8_3
      %104 = cute.get_scalars(%27) : !cute.int_tuple<"1">
      %iter_104 = cute.recast_iter(%ptr_29) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_105 = cute.recast_iter(%ptr_32) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb7(%c0_i32 : i32)
    ^bb7(%105: i32):  // 2 preds: ^bb6, ^bb8
      %106 = arith.cmpi slt, %105, %104 : i32
      cf.cond_br %106, ^bb8, ^bb9 {llvm.loop_annotation = #loop_annotation}
    ^bb8:  // pred: ^bb7
      %coord_106 = cute.make_coord(%105) : (i32) -> !cute.coord<"(_,?)">
      %idx_107 = cute.crd2idx(%coord_106, %28) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((1,1))):(1,((1,1)))">) -> !cute.int_tuple<"?">
      %ptr_108 = cute.add_offset(%iter_92, %idx_107) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %107 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i8, rmem> to !llvm.ptr
      %108 = llvm.load %107 : !llvm.ptr -> i8
      %109 = llvm.trunc %108 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_105 : !cute.ptr<i128, smem>, %iter_104 : !cute.ptr<i128, gmem>, %109 : i1) {cache_mode = <always>}
      %110 = arith.addi %105, %c1_i32 : i32
      cf.br ^bb7(%110 : i32)
    ^bb9:  // pred: ^bb7
      %111:2 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">
      %iv_109 = cute.assume(%111#1) : (i64) -> !cute.i64<divby 2048>
      %stride_110 = cute.make_stride(%iv_109) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),?{i64 div=2048},0)">
      %lay_111 = cute.make_layout(%26, %stride_110) : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %append = cute.append_to_rank<2> (%lay_111, %40) : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">, !cute.layout<"1:0">
      %112 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,1),4,1):((0,0),?{i64 div=2048},0)">
      %iv_112 = cute.assume(%112) : (i64) -> !cute.i64<divby 2048>
      %stride_113 = cute.make_stride(%iv_112) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),(?{i64 div=2048},0))">
      %lay_114 = cute.make_layout(%25, %stride_113) : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %append_115 = cute.append_to_rank<2> (%lay_114, %40) : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">, !cute.layout<"1:0">
      %113 = cute.get_scalars(%append_115) <{only_dynamic}> : !cute.layout<"((1,1),(4,1)):((0,0),(?{i64 div=2048},0))">
      %iv_116 = cute.assume(%113) : (i64) -> !cute.i64<divby 2048>
      %stride_117 = cute.make_stride(%iv_116) : (!cute.i64<divby 2048>) -> !cute.stride<"((0,0),((?{i64 div=2048},0)))">
      %lay_118 = cute.make_layout(%24, %stride_117) : !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">
      %114 = cute.get_scalars(%21) : !cute.int_tuple<"4">
      cf.br ^bb10(%c0_i32 : i32)
    ^bb10(%115: i32):  // 2 preds: ^bb9, ^bb11
      %116 = arith.cmpi slt, %115, %114 : i32
      cf.cond_br %116, ^bb11, ^bb12 {llvm.loop_annotation = #loop_annotation}
    ^bb11:  // pred: ^bb10
      %coord_119 = cute.make_coord(%115) : (i32) -> !cute.coord<"(_,?)">
      %idx_120 = cute.crd2idx(%coord_119, %lay_118) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %ptr_121 = cute.add_offset(%ptr_34, %idx_120) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %idx_122 = cute.crd2idx(%coord_119, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_123 = cute.add_offset(%ptr_40, %idx_122) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %idx_124 = cute.crd2idx(%coord_119, %22) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,1)))">) -> !cute.int_tuple<"?">
      %ptr_125 = cute.add_offset(%iter_103, %idx_124) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %117 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
      %118 = llvm.load %117 : !llvm.ptr -> i8
      %119 = llvm.trunc %118 : i8 to i1
      %iter_126 = cute.recast_iter(%ptr_121) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
      %iter_127 = cute.recast_iter(%ptr_123) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_127 : !cute.ptr<i32, smem>, %iter_126 : !cute.ptr<i32, gmem>, %119 : i1) {cache_mode = <always>}
      %120 = arith.addi %115, %c1_i32 : i32
      cf.br ^bb10(%120 : i32)
    ^bb12:  // pred: ^bb10
      nvvm.cp.async.commit.group
      %coord_128 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
      %idx_129 = cute.crd2idx(%coord_128, %29) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"2048">
      %ptr_130 = cute.add_offset(%ptr_29, %idx_129) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<f32, gmem, align<16>>
      %idx_131 = cute.crd2idx(%coord_128, %20) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"1024">
      %ptr_132 = cute.add_offset(%ptr_32, %idx_131) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<f32, smem, align<16>>
      %121 = builtin.unrealized_conversion_cast %iter_77 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %iter_133 = cute.recast_iter(%ptr_130) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_134 = cute.recast_iter(%ptr_132) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb13(%c0_i32 : i32)
    ^bb13(%122: i32):  // 2 preds: ^bb12, ^bb14
      %123 = arith.cmpi slt, %122, %104 : i32
      cf.cond_br %123, ^bb14, ^bb15 {llvm.loop_annotation = #loop_annotation}
    ^bb14:  // pred: ^bb13
      %124 = llvm.load %121 : !llvm.ptr -> i8
      %125 = llvm.trunc %124 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_134 : !cute.ptr<i128, smem>, %iter_133 : !cute.ptr<i128, gmem>, %125 : i1) {cache_mode = <always>}
      %126 = arith.addi %122, %c1_i32 : i32
      cf.br ^bb13(%126 : i32)
    ^bb15:  // pred: ^bb13
      %idx_135 = cute.crd2idx(%coord_128, %lay_38) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"8">
      %ptr_136 = cute.add_offset(%ptr_34, %idx_135) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"8">) -> !cute.ptr<f32, gmem>
      %idx_137 = cute.crd2idx(%coord_128, %19) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"1056">
      %ptr_138 = cute.add_offset(%ptr_40, %idx_137) : (!cute.ptr<f32, smem>, !cute.int_tuple<"1056">) -> !cute.ptr<f32, smem>
      cf.br ^bb16(%c0_i32 : i32)
    ^bb16(%127: i32):  // 2 preds: ^bb15, ^bb17
      %128 = arith.cmpi slt, %127, %114 : i32
      cf.cond_br %128, ^bb17, ^bb18 {llvm.loop_annotation = #loop_annotation}
    ^bb17:  // pred: ^bb16
      %coord_139 = cute.make_coord(%127) : (i32) -> !cute.coord<"(_,?)">
      %idx_140 = cute.crd2idx(%coord_139, %lay_118) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %ptr_141 = cute.add_offset(%ptr_136, %idx_140) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %idx_142 = cute.crd2idx(%coord_139, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_143 = cute.add_offset(%ptr_138, %idx_142) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %idx_144 = cute.crd2idx(%coord_139, %18) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_145 = cute.add_offset(%iter_87, %idx_144) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %129 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i8, rmem> to !llvm.ptr
      %130 = llvm.load %129 : !llvm.ptr -> i8
      %131 = llvm.trunc %130 : i8 to i1
      %iter_146 = cute.recast_iter(%ptr_141) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
      %iter_147 = cute.recast_iter(%ptr_143) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_147 : !cute.ptr<i32, smem>, %iter_146 : !cute.ptr<i32, gmem>, %131 : i1) {cache_mode = <always>}
      %132 = arith.addi %127, %c1_i32 : i32
      cf.br ^bb16(%132 : i32)
    ^bb18:  // pred: ^bb16
      nvvm.cp.async.commit.group
      %133 = arith.divsi %55, %c16_i32 : i32
      %134 = arith.remsi %133, %c16_i32 : i32
      %135 = arith.remsi %134, %c16_i32 : i32
      %136 = arith.muli %135, %c4_i32 : i32
      %iv_148 = cute.assume(%136) : (i32) -> !cute.i32<divby 4>
      %int_tuple_149 = cute.make_int_tuple(%iv_148) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_150 = cute.add_offset(%iter_25, %int_tuple_149) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %137 = arith.remsi %55, %c16_i32 : i32
      %138 = arith.remsi %137, %c16_i32 : i32
      %139 = arith.muli %138, %c4_i32 : i32
      %iv_151 = cute.assume(%139) : (i32) -> !cute.i32<divby 4>
      %int_tuple_152 = cute.make_int_tuple(%iv_151) : (!cute.i32<divby 4>) -> !cute.int_tuple<"?{div=4}">
      %ptr_153 = cute.add_offset(%iter_26, %int_tuple_152) : (!cute.ptr<f32, smem, align<1024>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, smem, align<16>>
      %140 = cute.get_scalars(%lay_20) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=256},1)">
      %141 = arith.muli %140, %c4_i64 : i64
      %142 = arith.muli %140, %c64_i64 : i64
      %143 = arith.extsi %135 : i32 to i64
      %144 = arith.muli %143, %141 : i64
      %145 = arith.extsi %139 : i32 to i64
      %146 = arith.addi %144, %145 : i64
      %iv_154 = cute.assume(%146) : (i64) -> !cute.i64<divby 4>
      %int_tuple_155 = cute.make_int_tuple(%iv_154) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_156 = cute.add_offset(%ptr_23, %int_tuple_155) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %iv_157 = cute.assume(%140) : (i64) -> !cute.i64<divby 256>
      %iv_158 = cute.assume(%142) : (i64) -> !cute.i64<divby 16384>
      %stride_159 = cute.make_stride(%iv_157, %iv_158) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %lay_160 = cute.make_layout(%17, %stride_159) : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %rmem_161 = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_162 = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_163 = cute.memref.alloca() : !memref_rmem_f32_1
      %iter_164 = cute.get_iter(%rmem_163) : !memref_rmem_f32_1
      cute.memref.store_vec %cst, %rmem_163 : !memref_rmem_f32_1
      %view = cute.make_view(%ptr_150) : !memref_smem_f32_
      %147 = builtin.unrealized_conversion_cast %view : !memref_smem_f32_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %view_165 = cute.make_view(%ptr_153) : !memref_smem_f32_1
      %148 = builtin.unrealized_conversion_cast %view_165 : !memref_smem_f32_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
      %iter_166 = cute.get_iter(%rmem_161) : !memref_rmem_f32_
      %149 = cute.get_scalars(%12) : !cute.int_tuple<"2">
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%150: i32):  // 2 preds: ^bb18, ^bb20
      %151 = arith.cmpi slt, %150, %149 : i32
      cf.cond_br %151, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation}
    ^bb20:  // pred: ^bb19
      %coord_167 = cute.make_coord(%150) : (i32) -> !cute.coord<"(_,?)">
      %idx_168 = cute.crd2idx(%coord_167, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_169 = cute.add_offset(%ptr_150, %idx_168) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %idx_170 = cute.crd2idx(%coord_167, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_171 = cute.add_offset(%iter_166, %idx_170) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %152 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
      %153 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<f32, rmem> to !llvm.ptr
      %154 = llvm.load %152 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %154, %153 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %155 = arith.addi %150, %c1_i32 : i32
      cf.br ^bb19(%155 : i32)
    ^bb21:  // pred: ^bb19
      %iter_172 = cute.get_iter(%rmem_162) : !memref_rmem_f32_
      cf.br ^bb22(%c0_i32 : i32)
    ^bb22(%156: i32):  // 2 preds: ^bb21, ^bb23
      %157 = arith.cmpi slt, %156, %149 : i32
      cf.cond_br %157, ^bb23, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %coord_173 = cute.make_coord(%156) : (i32) -> !cute.coord<"(_,?)">
      %idx_174 = cute.crd2idx(%coord_173, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_175 = cute.add_offset(%ptr_153, %idx_174) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %idx_176 = cute.crd2idx(%coord_173, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_177 = cute.add_offset(%iter_172, %idx_176) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %158 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
      %159 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
      %160 = llvm.load %158 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %160, %159 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %161 = arith.addi %156, %c1_i32 : i32
      cf.br ^bb22(%161 : i32)
    ^bb24:  // pred: ^bb22
      %162 = cute.get_scalars(%6) : !cute.int_tuple<"8">
      cf.br ^bb25(%c0_i32, %147, %148, %c2_i32, %c0_i32, %c2_i32 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb25(%163: i32, %164: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %165: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %166: i32, %167: i32, %168: i32):  // 2 preds: ^bb24, ^bb60
      %169 = arith.cmpi slt, %163, %c8_i32 : i32
      cf.cond_br %169, ^bb26, ^bb61
    ^bb26:  // pred: ^bb25
      cf.br ^bb27(%c0_i32, %164, %165, %166, %167, %168, %c1_i32 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32, i32)
    ^bb27(%170: i32, %171: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %172: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %173: i32, %174: i32, %175: i32, %176: i32):  // 2 preds: ^bb26, ^bb59
      %177 = arith.cmpi slt, %170, %c8_i32 : i32
      cf.cond_br %177, ^bb28, ^bb60 {loop_annotation = #loop_annotation1}
    ^bb28:  // pred: ^bb27
      %178 = arith.cmpi eq, %170, %c7_i32 : i32
      cf.cond_br %178, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %coord_178 = cute.make_coord(%174) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_179 = cute.crd2idx(%coord_178, %16) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_180 = cute.add_offset(%ptr_150, %idx_179) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
      %view_181 = cute.make_view(%ptr_180) : !memref_smem_f32_
      %179 = builtin.unrealized_conversion_cast %view_181 : !memref_smem_f32_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %idx_182 = cute.crd2idx(%coord_178, %15) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,(4,2),8,3):(0,(1,64),132,1056)">) -> !cute.int_tuple<"?{div=1056}">
      %ptr_183 = cute.add_offset(%ptr_153, %idx_182) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem, align<16>>
      %view_184 = cute.make_view(%ptr_183) : !memref_smem_f32_1
      %180 = builtin.unrealized_conversion_cast %view_184 : !memref_smem_f32_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
      cf.br ^bb31(%179, %180 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>)
    ^bb30:  // pred: ^bb28
      cf.br ^bb31(%171, %172 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>)
    ^bb31(%181: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %182: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>):  // 2 preds: ^bb29, ^bb30
      cf.br ^bb32
    ^bb32:  // pred: ^bb31
      %183 = builtin.unrealized_conversion_cast %182 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f32_1
      %184 = builtin.unrealized_conversion_cast %181 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f32_
      %coord_185 = cute.make_coord(%176) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_186 = cute.crd2idx(%coord_185, %11) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),128)">) -> !cute.int_tuple<"?{div=128}">
      %iter_187 = cute.get_iter(%184) : !memref_smem_f32_
      %ptr_188 = cute.add_offset(%iter_187, %idx_186) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, smem, align<16>>
      %idx_189 = cute.crd2idx(%coord_185, %10) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_190 = cute.add_offset(%iter_166, %idx_189) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      cf.br ^bb33(%c0_i32 : i32)
    ^bb33(%185: i32):  // 2 preds: ^bb32, ^bb34
      %186 = arith.cmpi slt, %185, %149 : i32
      cf.cond_br %186, ^bb34, ^bb35 {llvm.loop_annotation = #loop_annotation}
    ^bb34:  // pred: ^bb33
      %coord_191 = cute.make_coord(%185) : (i32) -> !cute.coord<"(_,?)">
      %idx_192 = cute.crd2idx(%coord_191, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_193 = cute.add_offset(%ptr_188, %idx_192) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %idx_194 = cute.crd2idx(%coord_191, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_195 = cute.add_offset(%ptr_190, %idx_194) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %187 = builtin.unrealized_conversion_cast %ptr_193 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
      %188 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<f32, rmem> to !llvm.ptr
      %189 = llvm.load %187 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %189, %188 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %190 = arith.addi %185, %c1_i32 : i32
      cf.br ^bb33(%190 : i32)
    ^bb35:  // pred: ^bb33
      %idx_196 = cute.crd2idx(%coord_185, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,64),132)">) -> !cute.int_tuple<"?{div=132}">
      %iter_197 = cute.get_iter(%183) : !memref_smem_f32_1
      %ptr_198 = cute.add_offset(%iter_197, %idx_196) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=132}">) -> !cute.ptr<f32, smem, align<16>>
      %ptr_199 = cute.add_offset(%iter_172, %idx_189) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      cf.br ^bb36(%c0_i32 : i32)
    ^bb36(%191: i32):  // 2 preds: ^bb35, ^bb37
      %192 = arith.cmpi slt, %191, %149 : i32
      cf.cond_br %192, ^bb37, ^bb38 {llvm.loop_annotation = #loop_annotation}
    ^bb37:  // pred: ^bb36
      %coord_200 = cute.make_coord(%191) : (i32) -> !cute.coord<"(_,?)">
      %idx_201 = cute.crd2idx(%coord_200, %14) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(64))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_202 = cute.add_offset(%ptr_198, %idx_201) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, smem, align<16>>
      %idx_203 = cute.crd2idx(%coord_200, %13) : (!cute.coord<"(_,?)">, !cute.layout<"(4,(2)):(1,(4))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_204 = cute.add_offset(%ptr_199, %idx_203) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem>
      %193 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<f32, smem, align<16>> to !llvm.ptr<3>
      %194 = builtin.unrealized_conversion_cast %ptr_204 : !cute.ptr<f32, rmem> to !llvm.ptr
      %195 = llvm.load %193 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %195, %194 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %196 = arith.addi %191, %c1_i32 : i32
      cf.br ^bb36(%196 : i32)
    ^bb38:  // pred: ^bb36
      %197 = arith.cmpi eq, %170, %c0_i32 : i32
      cf.cond_br %197, ^bb39, ^bb43
    ^bb39:  // pred: ^bb38
      %coord_205 = cute.make_coord(%175) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_206 = cute.crd2idx(%coord_205, %29) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,8):((1,0),0,0,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_207 = cute.add_offset(%ptr_29, %idx_206) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_208 = cute.make_coord(%173) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_209 = cute.crd2idx(%coord_208, %20) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((4,1),1,1,3):((1,0),0,0,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_210 = cute.add_offset(%ptr_32, %idx_209) : (!cute.ptr<f32, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f32, smem, align<16>>
      %198 = builtin.unrealized_conversion_cast %iter_77 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %iter_211 = cute.recast_iter(%ptr_207) : !cute.ptr<f32, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_212 = cute.recast_iter(%ptr_210) : !cute.ptr<f32, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb40(%c0_i32 : i32)
    ^bb40(%199: i32):  // 2 preds: ^bb39, ^bb41
      %200 = arith.cmpi slt, %199, %104 : i32
      cf.cond_br %200, ^bb41, ^bb42 {llvm.loop_annotation = #loop_annotation}
    ^bb41:  // pred: ^bb40
      %201 = llvm.load %198 : !llvm.ptr -> i8
      %202 = llvm.trunc %201 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_212 : !cute.ptr<i128, smem>, %iter_211 : !cute.ptr<i128, gmem>, %202 : i1) {cache_mode = <always>}
      %203 = arith.addi %199, %c1_i32 : i32
      cf.br ^bb40(%203 : i32)
    ^bb42:  // pred: ^bb40
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb38, ^bb42
      %coord_213 = cute.make_coord(%170) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_214 = cute.crd2idx(%coord_213, %10) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,(4,2),8):(0,(1,4),8)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_215 = cute.add_offset(%iter_166, %idx_214) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      %ptr_216 = cute.add_offset(%iter_172, %idx_214) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, rmem>
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%204: i32):  // 2 preds: ^bb43, ^bb51
      %205 = arith.cmpi slt, %204, %104 : i32
      cf.cond_br %205, ^bb45, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      cf.br ^bb46(%c0_i32 : i32)
    ^bb46(%206: i32):  // 2 preds: ^bb45, ^bb50
      %207 = arith.cmpi slt, %206, %162 : i32
      cf.cond_br %207, ^bb47, ^bb51 {llvm.loop_annotation = #loop_annotation}
    ^bb47:  // pred: ^bb46
      %coord_217 = cute.make_coord(%206, %204) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_218 = cute.crd2idx(%coord_217, %7) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
      %ptr_219 = cute.add_offset(%ptr_215, %idx_218) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %view_220 = cute.make_view(%ptr_219) : !memref_rmem_f32_2
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%208: i32):  // 2 preds: ^bb47, ^bb49
      %209 = arith.cmpi slt, %208, %162 : i32
      cf.cond_br %209, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      %coord_221 = cute.make_coord(%208, %204) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_222 = cute.make_coord(%206, %208) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_223 = cute.crd2idx(%coord_221, %7) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),1):(0,(1,4),0)">) -> !cute.int_tuple<"?">
      %ptr_224 = cute.add_offset(%ptr_216, %idx_223) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %idx_225 = cute.crd2idx(%coord_222, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,(4,2),(4,2)):(0,(1,4),(8,32))">) -> !cute.int_tuple<"?">
      %ptr_226 = cute.add_offset(%iter_164, %idx_225) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %view_227 = cute.make_view(%ptr_224) : !memref_rmem_f32_2
      %view_228 = cute.make_view(%ptr_226) : !memref_rmem_f32_2
      %210 = cute.memref.load_vec %view_220 : !memref_rmem_f32_2
      %211 = cute.memref.load_vec %view_227 : !memref_rmem_f32_2
      %212 = cute.memref.load_vec %view_228 : !memref_rmem_f32_2
      %213 = math.fma %210, %211, %212 : vector<1xf32>
      cute.memref.store_vec %213, %view_228 : !memref_rmem_f32_2
      %214 = arith.addi %208, %c1_i32 : i32
      cf.br ^bb48(%214 : i32)
    ^bb50:  // pred: ^bb48
      %215 = arith.addi %206, %c1_i32 : i32
      cf.br ^bb46(%215 : i32)
    ^bb51:  // pred: ^bb46
      %216 = arith.addi %204, %c1_i32 : i32
      cf.br ^bb44(%216 : i32)
    ^bb52:  // pred: ^bb44
      %217 = arith.select %197, %174, %173 : i32
      cf.cond_br %197, ^bb53, ^bb57
    ^bb53:  // pred: ^bb52
      %coord_229 = cute.make_coord(%175) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_230 = cute.crd2idx(%coord_229, %lay_38) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,?):((0,0),?{i64 div=2048},0,8)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_231 = cute.add_offset(%ptr_34, %idx_230) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %coord_232 = cute.make_coord(%173) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_233 = cute.crd2idx(%coord_232, %19) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,1),4,1,3):((0,0),32,0,1056)">) -> !cute.int_tuple<"?{div=1056}">
      %ptr_234 = cute.add_offset(%ptr_40, %idx_233) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=1056}">) -> !cute.ptr<f32, smem>
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%218: i32):  // 2 preds: ^bb53, ^bb55
      %219 = arith.cmpi slt, %218, %114 : i32
      cf.cond_br %219, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %coord_235 = cute.make_coord(%218) : (i32) -> !cute.coord<"(_,?)">
      %idx_236 = cute.crd2idx(%coord_235, %lay_118) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((?{i64 div=2048},0)))">) -> !cute.int_tuple<"?{i64 div=2048}">
      %ptr_237 = cute.add_offset(%ptr_231, %idx_236) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2048}">) -> !cute.ptr<f32, gmem>
      %idx_238 = cute.crd2idx(%coord_235, %23) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1),((4,1))):((0,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_239 = cute.add_offset(%ptr_234, %idx_238) : (!cute.ptr<f32, smem>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, smem>
      %idx_240 = cute.crd2idx(%coord_235, %18) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_241 = cute.add_offset(%iter_87, %idx_240) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %220 = builtin.unrealized_conversion_cast %ptr_241 : !cute.ptr<i8, rmem> to !llvm.ptr
      %221 = llvm.load %220 : !llvm.ptr -> i8
      %222 = llvm.trunc %221 : i8 to i1
      %iter_242 = cute.recast_iter(%ptr_237) : !cute.ptr<f32, gmem> to !cute.ptr<i32, gmem>
      %iter_243 = cute.recast_iter(%ptr_239) : !cute.ptr<f32, smem> to !cute.ptr<i32, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_243 : !cute.ptr<i32, smem>, %iter_242 : !cute.ptr<i32, gmem>, %222 : i1) {cache_mode = <always>}
      %223 = arith.addi %218, %c1_i32 : i32
      cf.br ^bb54(%223 : i32)
    ^bb56:  // pred: ^bb54
      nvvm.cp.async.commit.group
      %224 = arith.addi %174, %c1_i32 : i32
      %225 = arith.cmpi eq, %224, %c3_i32 : i32
      %226 = arith.select %225, %c0_i32, %224 : i32
      %227 = arith.addi %175, %c1_i32 : i32
      %228 = arith.cmpi slt, %227, %c8_i32 : i32
      %229 = arith.select %228, %227, %c1_i32 : i32
      cf.br ^bb58(%226, %229 : i32, i32)
    ^bb57:  // pred: ^bb52
      cf.br ^bb58(%174, %175 : i32, i32)
    ^bb58(%230: i32, %231: i32):  // 2 preds: ^bb56, ^bb57
      cf.br ^bb59
    ^bb59:  // pred: ^bb58
      %232 = arith.addi %176, %c1_i32 : i32
      %233 = arith.cmpi eq, %232, %c8_i32 : i32
      %234 = arith.select %233, %c0_i32, %232 : i32
      %235 = arith.addi %170, %c1_i32 : i32
      cf.br ^bb27(%235, %181, %182, %217, %230, %231, %234 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32, i32)
    ^bb60:  // pred: ^bb27
      %236 = arith.addi %163, %c1_i32 : i32
      cf.br ^bb25(%236, %171, %172, %173, %174, %175 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb61:  // pred: ^bb25
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c256_i32
      %237 = cute.memref.load_vec %rmem_163 : !memref_rmem_f32_1
      cute.memref.store_vec %237, %rmem_163 : !memref_rmem_f32_1
      %int_tuple_244 = cute.make_int_tuple(%iv_148, %iv_151) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_245 = cute.add_offset(%36, %int_tuple_244) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_246 = cute.memref.alloca() : !memref_rmem_i8_4
      %238 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?{div=256}):(?{i64 div=256},1)">) -> !cute.shape<"(?,?{div=256})">
      %e0_247, %e1_248 = cute.get_leaves(%238) : !cute.shape<"(?,?{div=256})">
      %itup_249 = cute.to_int_tuple(%e0_247) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_250 = cute.to_int_tuple(%e1_248) : !cute.shape<"?{div=256}"> to !cute.int_tuple<"?{div=256}">
      %239 = arith.muli %42, %c128_i32 : i32
      %int_tuple_251 = cute.make_int_tuple(%239) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%itup_249, %int_tuple_251) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %240 = arith.muli %43, %c128_i32 : i32
      %int_tuple_252 = cute.make_int_tuple(%240) : (i32) -> !cute.int_tuple<"?">
      %sub_253 = cute.tuple_sub(%itup_250, %int_tuple_252) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %coord_254 = cute.make_coord(%sub, %sub_253) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %241:2 = cute.get_scalars(%coord_254) : !cute.coord<"(?,?)">
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%242: i32):  // 2 preds: ^bb61, ^bb63
      %243 = arith.cmpi slt, %242, %c64_i32 : i32
      cf.cond_br %243, ^bb63, ^bb64
    ^bb63:  // pred: ^bb62
      %coord_255 = cute.make_coord(%242) : (i32) -> !cute.coord<"?">
      %idx_256 = cute.crd2idx(%coord_255, %5) : (!cute.coord<"?">, !cute.layout<"(1,(4,2),(4,2)):(0,(1@0,64@0),(1@1,64@1))">) -> !cute.int_tuple<"(?,?)">
      %tup_257 = cute.add_offset(%tup_245, %idx_256) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %e0_258, %e1_259 = cute.get_leaves(%tup_257) : !cute.int_tuple<"(?,?)">
      %coord_260 = cute.make_coord(%e0_258, %e1_259) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %244:2 = cute.get_scalars(%coord_260) : !cute.coord<"(?,?)">
      %245 = arith.cmpi slt, %244#0, %241#0 : i32
      %246 = arith.cmpi slt, %244#1, %241#1 : i32
      %247 = arith.andi %245, %246 : i1
      %248 = arith.extui %247 : i1 to i8
      cute.memref.store(%rmem_246, %coord_255, %248) : (!memref_rmem_i8_4, !cute.coord<"?">, i8) -> ()
      %249 = arith.addi %242, %c1_i32 : i32
      cf.br ^bb62(%249 : i32)
    ^bb64:  // pred: ^bb62
      %iter_261 = cute.get_iter(%rmem_246) : !memref_rmem_i8_4
      %append_262 = cute.append_to_rank<2> (%lay_160, %40) : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">, !cute.layout<"1:0">
      %250:2 = cute.get_scalars(%append_262) <{only_dynamic}> : !cute.layout<"(1,(4,2),(4,2)):(0,(?{i64 div=256},?{i64 div=16384}),(1,64))">
      %iv_263 = cute.assume(%250#0) : (i64) -> !cute.i64<divby 256>
      %iv_264 = cute.assume(%250#1) : (i64) -> !cute.i64<divby 16384>
      %stride_265 = cute.make_stride(%iv_263, %iv_264) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %lay_266 = cute.make_layout(%4, %stride_265) : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %append_267 = cute.append_to_rank<2> (%lay_266, %40) : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">, !cute.layout<"1:0">
      %251:2 = cute.get_scalars(%append_267) <{only_dynamic}> : !cute.layout<"(1,((4,2),(4,2))):(0,((?{i64 div=256},?{i64 div=16384}),(1,64)))">
      %iv_268 = cute.assume(%251#0) : (i64) -> !cute.i64<divby 256>
      %iv_269 = cute.assume(%251#1) : (i64) -> !cute.i64<divby 16384>
      %stride_270 = cute.make_stride(%iv_268, %iv_269) : (!cute.i64<divby 256>, !cute.i64<divby 16384>) -> !cute.stride<"(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %lay_271 = cute.make_layout(%2, %stride_270) : !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">
      %252 = cute.get_scalars(%1) : !cute.int_tuple<"64">
      cf.br ^bb65(%c0_i32 : i32)
    ^bb65(%253: i32):  // 2 preds: ^bb64, ^bb68
      %254 = arith.cmpi slt, %253, %252 : i32
      cf.cond_br %254, ^bb66, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb66:  // pred: ^bb65
      %coord_272 = cute.make_coord(%253) : (i32) -> !cute.coord<"(_,?)">
      %idx_273 = cute.crd2idx(%coord_272, %3) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((1,4),(8,32))))">) -> !cute.int_tuple<"?">
      %ptr_274 = cute.add_offset(%iter_164, %idx_273) : (!cute.ptr<f32, rmem>, !cute.int_tuple<"?">) -> !cute.ptr<f32, rmem>
      %idx_275 = cute.crd2idx(%coord_272, %lay_271) : (!cute.coord<"(_,?)">, !cute.layout<"(1,(((4,2),(4,2)))):(0,(((?{i64 div=256},?{i64 div=16384}),(1,64))))">) -> !cute.int_tuple<"?{i64}">
      %ptr_276 = cute.add_offset(%ptr_156, %idx_275) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_277 = cute.add_offset(%iter_261, %idx_273) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %255 = builtin.unrealized_conversion_cast %ptr_277 : !cute.ptr<i8, rmem> to !llvm.ptr
      %256 = llvm.load %255 : !llvm.ptr -> i8
      %257 = llvm.icmp "ne" %256, %0 : i8
      cf.cond_br %257, ^bb67, ^bb68
    ^bb67:  // pred: ^bb66
      %258 = builtin.unrealized_conversion_cast %ptr_274 : !cute.ptr<f32, rmem> to !llvm.ptr
      %259 = builtin.unrealized_conversion_cast %ptr_276 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %260 = llvm.load %258 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %260, %259 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb68
    ^bb68:  // 2 preds: ^bb66, ^bb67
      %261 = arith.addi %253, %c1_i32 : i32
      cf.br ^bb65(%261 : i32)
    ^bb69:  // pred: ^bb65
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
