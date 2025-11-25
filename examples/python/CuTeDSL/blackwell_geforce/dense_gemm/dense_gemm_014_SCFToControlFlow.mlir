!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),((2,2,2),(1,1))):((64,1,16,0),((32,8,256),(0,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),((2,2),(2,1))):((64,1,0,8),((32,256),(16,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_stsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),(2,2,2)):((32,1,8,128),(256,16,512))">, tiler_mn = <"[(8,2,2):(1,16,8);(8,2,2):(2,1,16)]">>
!copy_stsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>, layout_copy_tv = <"((4,16,2),((2,2,2),1)):((32,1,128),((256,16,512),0))">, tiler_mn = <"[(8,2,2):(1,16,8);(8,2,2):(2,1,16)]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,?):(1,?{i64},?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<16>, "((2,2,2),2,4):((1,2,4),8,16)">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<8>, "((2,2),4,4):((1,2),4,16)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "(((2,2,2),1),2,1):(((1,2,4),0),8,0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),2,4):((1,2),4,8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(((4,2),1),2,2):(((1,8),0),4,16)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(((2,2,2),1),2,1):(((1,2,4),0),8,0)">
!memref_smem_f16_ = !cute.memref<f16, smem, align<16>, S<3,4,3>, "((8,1),2,4):((1,0),32,1024)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel___main__Sm120GemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutDst1409601_Valuetypef16_tensor000o101112_CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutD_0(%arg0: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg1: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg2: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg3: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg4: !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg5: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg6: i32, %arg7: i32, %arg8: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 160, 1, 1>} {
      %cst = arith.constant dense<0.000000e+00> : vector<32xf32>
      %0 = cute.static : !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">
      %c16384_i32 = arith.constant 16384 : i32
      %1 = cute.static : !cute.stride<"(((1@0,1@1),0),64@1)">
      %2 = cute.static : !cute.int_tuple<"(0,32)">
      %3 = cute.static : !cute.coord<"31">
      %4 = cute.static : !cute.coord<"30">
      %5 = cute.static : !cute.coord<"29">
      %6 = cute.static : !cute.coord<"28">
      %7 = cute.static : !cute.coord<"27">
      %8 = cute.static : !cute.coord<"26">
      %9 = cute.static : !cute.coord<"25">
      %10 = cute.static : !cute.coord<"24">
      %11 = cute.static : !cute.coord<"23">
      %12 = cute.static : !cute.coord<"22">
      %13 = cute.static : !cute.coord<"21">
      %14 = cute.static : !cute.coord<"20">
      %15 = cute.static : !cute.coord<"19">
      %16 = cute.static : !cute.coord<"18">
      %17 = cute.static : !cute.coord<"17">
      %18 = cute.static : !cute.coord<"16">
      %19 = cute.static : !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">
      %20 = cute.static : !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">
      %21 = cute.static : !cute.coord<"15">
      %22 = cute.static : !cute.coord<"14">
      %23 = cute.static : !cute.coord<"13">
      %24 = cute.static : !cute.coord<"12">
      %25 = cute.static : !cute.coord<"11">
      %26 = cute.static : !cute.coord<"10">
      %27 = cute.static : !cute.coord<"9">
      %28 = cute.static : !cute.coord<"8">
      %29 = cute.static : !cute.coord<"7">
      %30 = cute.static : !cute.coord<"6">
      %31 = cute.static : !cute.coord<"5">
      %32 = cute.static : !cute.coord<"4">
      %33 = cute.static : !cute.coord<"3">
      %34 = cute.static : !cute.coord<"2">
      %35 = cute.static : !cute.coord<"1">
      %36 = cute.static : !cute.coord<"0">
      %c1024_i32 = arith.constant 1024 : i32
      %c128_i32 = arith.constant 128 : i32
      %37 = cute.static : !cute.int_tuple<"48">
      %38 = cute.static : !cute.int_tuple<"3072">
      %39 = cute.static : !cute.int_tuple<"32">
      %40 = cute.static : !cute.int_tuple<"2048">
      %41 = cute.static : !cute.layout<"((2,2),4,1):((1,2),4,0)">
      %42 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %43 = cute.static : !cute.int_tuple<"16">
      %44 = cute.static : !cute.int_tuple<"6">
      %45 = llvm.mlir.constant(3 : i32) : i32
      %46 = llvm.mlir.constant(2 : i32) : i32
      %47 = llvm.mlir.constant(1 : i32) : i32
      %48 = llvm.mlir.constant(0 : i32) : i32
      %49 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %50 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((32)))">
      %51 = cute.static : !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">
      %c10000000_i32 = arith.constant 10000000 : i32
      %c16_i32 = arith.constant 16 : i32
      %c512_i32 = arith.constant 512 : i32
      %c2_i32 = arith.constant 2 : i32
      %c8_i32 = arith.constant 8 : i32
      %52 = cute.static : !cute.layout<"((2,2),2,4):((1,2),4,8)">
      %53 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0,64@1,1@2)">
      %54 = cute.static : !cute.stride<"((1@0,1@1),64@0,64@1,1@2)">
      %55 = cute.static : !cute.int_tuple<"(0,0,0)">
      %56 = cute.static : !cute.stride<"(1@0,1@1,64@0,64@1,1@2)">
      %57 = cute.static : !cute.stride<"((1@0,1@1),(64@0,64@1,1@2))">
      %c64_i32 = arith.constant 64 : i32
      %true = arith.constant true
      %c4_i32 = arith.constant 4 : i32
      %58 = cute.static : !cute.int_tuple<"4">
      %59 = cute.static : !cute.int_tuple<"3">
      %60 = cute.static : !cute.int_tuple<"2">
      %61 = cute.static : !cute.int_tuple<"1">
      %c1_i32 = arith.constant 1 : i32
      %62 = cute.static : !cute.int_tuple<"66560">
      %63 = cute.static : !cute.int_tuple<"33792">
      %64 = cute.static : !cute.int_tuple<"1024">
      %c0_i32 = arith.constant 0 : i32
      %c32_i32 = arith.constant 32 : i32
      %int_tuple = cute.make_int_tuple(%arg6, %arg7, %arg8) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %65:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %int_tuple_0 = cute.make_int_tuple(%65#0, %65#1, %65#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(?,?,?)">
      %shape = cute.make_shape(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(?,?,?):(1,?,?)">
      %66 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %67 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %68 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %69 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %70 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %71 = arith.muli %67, %69 : i32
      %72 = arith.addi %66, %71 : i32
      %73 = arith.muli %68, %69 : i32
      %74 = arith.muli %73, %70 : i32
      %75 = arith.addi %72, %74 : i32
      %76 = arith.floordivsi %75, %c32_i32 : i32
      %77 = cute_nvgpu.arch.make_warp_uniform(%76) : i32
      %78 = arith.cmpi eq, %77, %c0_i32 : i32
      cf.cond_br %78, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %64) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_1 = cute.add_offset(%smem_ptr, %63) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_2 = cute.add_offset(%smem_ptr, %62) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"66560">) -> !cute.ptr<i8, smem, align<1024>>
      %iter = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %78, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %79 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %79, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_3 = cute.add_offset(%iter, %61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %80 = builtin.unrealized_conversion_cast %ptr_3 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %80, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_4 = cute.add_offset(%iter, %60) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %81 = builtin.unrealized_conversion_cast %ptr_4 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %81, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_5 = cute.add_offset(%iter, %59) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %82 = builtin.unrealized_conversion_cast %ptr_5 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %82, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_6 = cute.add_offset(%iter, %58) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      cf.cond_br %78, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %83 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %83, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_7 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_8 = cute.add_offset(%iter, %int_tuple_7) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %84 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %84, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_9 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_10 = cute.add_offset(%iter, %int_tuple_9) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %85 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %85, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_11 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_12 = cute.add_offset(%iter, %int_tuple_11) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %86 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %86, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %87 = arith.remsi %66, %c32_i32 : i32
      %88 = arith.cmpi slt, %87, %c1_i32 : i32
      %89 = arith.extui %88 : i1 to i32
      %90 = arith.select %88, %c1_i32, %89 : i32
      %91 = arith.cmpi ne, %90, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_13 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_14 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_15 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %lay_16 = cute.get_layout(%arg1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %92:3 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %93 = arith.ceildivsi %92#0, %c64_i32 : i32
      %94 = arith.ceildivsi %92#1, %c64_i32 : i32
      %shape_17 = cute.make_shape(%93, %94, %92#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_18 = cute.make_layout(%shape_17, %57) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %95:3 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_19 = cute.make_shape(%95#0, %95#1, %95#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_20 = cute.make_layout(%shape_19, %56) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %lay_21 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %96:3 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %97 = arith.ceildivsi %96#0, %c64_i32 : i32
      %98 = arith.ceildivsi %96#1, %c64_i32 : i32
      %shape_22 = cute.make_shape(%97, %98, %96#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_23 = cute.make_layout(%shape_22, %57) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %99:3 = cute.get_scalars(%lay_23) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_24 = cute.make_shape(%99#0, %99#1, %99#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_25 = cute.make_layout(%shape_24, %56) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %lay_26 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %100:3 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %101 = arith.ceildivsi %100#0, %c64_i32 : i32
      %102 = arith.ceildivsi %100#1, %c64_i32 : i32
      %shape_27 = cute.make_shape(%101, %102, %100#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_28 = cute.make_layout(%shape_27, %57) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %103:3 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_29 = cute.make_shape(%103#0, %103#1, %103#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_30 = cute.make_layout(%shape_29, %56) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %104:3 = cute.get_scalars(%lay_20) <{only_dynamic}> : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %shape_31 = cute.make_shape(%104#0, %104#1, %104#2) : (i32, i32, i32) -> !cute.shape<"((64,64),?,?,?)">
      %lay_32 = cute.make_layout(%shape_31, %54) : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %105:3 = cute.get_scalars(%lay_32) <{only_dynamic}> : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %shape_33 = cute.make_shape(%105#0, %105#1, %105#2) : (i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,?)">
      %lay_34 = cute.make_layout(%shape_33, %53) : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %106:3 = cute.get_scalars(%lay_25) <{only_dynamic}> : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %shape_35 = cute.make_shape(%106#0, %106#1, %106#2) : (i32, i32, i32) -> !cute.shape<"((64,64),?,?,?)">
      %lay_36 = cute.make_layout(%shape_35, %54) : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %107:3 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %shape_37 = cute.make_shape(%107#0, %107#1, %107#2) : (i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,?)">
      %lay_38 = cute.make_layout(%shape_37, %53) : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %rmem = cute.memref.alloca() : !memref_rmem_f16_
      %rmem_39 = cute.memref.alloca() : !memref_rmem_f16_1
      %rmem_40 = cute.memref.alloca() : !memref_rmem_f32_
      nvvm.barrier id = %c1_i32
      %sz = cute.size(%lay_20) <{mode = [3]}> : (!cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">) -> !cute.int_tuple<"?">
      %e0_41 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %108 = cute.get_scalars(%e0_41) : !cute.int_tuple<"?">
      %109 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %110 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %111 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %112 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_42 = cute.make_int_tuple(%110, %111, %112) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_43 = cute.size(%int_tuple_42) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_44 = cute.get_leaves(%sz_43) : !cute.int_tuple<"?">
      %div = cute.tuple_div(%e0_44, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %113 = cute.get_scalars(%div) : !cute.int_tuple<"?">
      %sz_45 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_46 = cute.get_leaves(%sz_45) : !cute.int_tuple<"?">
      %114 = cute.get_scalars(%e0_46) : !cute.int_tuple<"?">
      %115 = arith.cmpi sgt, %114, %109 : i32
      %116 = cute.get_hier_coord(%109, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_47, %e1_48, %e2_49 = cute.get_leaves(%116) : !cute.coord<"(?,?,?)">
      %itup = cute.to_int_tuple(%e0_47) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_50 = cute.to_int_tuple(%e1_48) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_51 = cute.to_int_tuple(%e2_49) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%itup, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %117 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %mul_52 = cute.tuple_mul(%itup_50, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %118 = cute.get_scalars(%mul_52) : !cute.int_tuple<"?">
      %mul_53 = cute.tuple_mul(%itup_51, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %119 = cute.get_scalars(%mul_53) : !cute.int_tuple<"?">
      %120 = arith.cmpi slt, %77, %c4_i32 : i32
      cf.cond_br %120, ^bb7, ^bb170
    ^bb7:  // pred: ^bb6
      nvvm.setmaxregister  increase 232
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %121 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %122 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %coord = cute.make_coord(%66) : (i32) -> !cute.coord<"?">
      %123 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"?">
      %124 = arith.divsi %123, %c8_i32 : i32
      %125 = arith.remsi %123, %c8_i32 : i32
      %126 = arith.muli %125, %c64_i32 : i32
      %127 = arith.divsi %124, %c2_i32 : i32
      %128 = arith.remsi %124, %c2_i32 : i32
      %129 = arith.muli %128, %c8_i32 : i32
      %130 = arith.addi %126, %129 : i32
      %131 = arith.divsi %127, %c2_i32 : i32
      %132 = arith.remsi %127, %c2_i32 : i32
      %133 = arith.muli %132, %c512_i32 : i32
      %134 = arith.addi %130, %133 : i32
      %135 = arith.remsi %131, %c2_i32 : i32
      %136 = arith.muli %135, %c16_i32 : i32
      %137 = arith.addi %134, %136 : i32
      %iv = cute.assume(%137) : (i32) -> !cute.i32<divby 8>
      %int_tuple_54 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_55 = cute.add_offset(%iter_13, %int_tuple_54) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %iter_56 = cute.get_iter(%rmem) : !memref_rmem_f16_
      %138 = arith.divsi %123, %c16_i32 : i32
      %139 = arith.remsi %123, %c16_i32 : i32
      %140 = arith.muli %139, %c64_i32 : i32
      %141 = arith.divsi %138, %c2_i32 : i32
      %142 = arith.remsi %138, %c2_i32 : i32
      %143 = arith.muli %142, %c16_i32 : i32
      %144 = arith.addi %140, %143 : i32
      %145 = arith.divsi %141, %c2_i32 : i32
      %146 = arith.muli %145, %c8_i32 : i32
      %147 = arith.addi %144, %146 : i32
      %iv_57 = cute.assume(%147) : (i32) -> !cute.i32<divby 8>
      %int_tuple_58 = cute.make_int_tuple(%iv_57) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_59 = cute.add_offset(%iter_14, %int_tuple_58) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %iter_60 = cute.get_iter(%rmem_39) : !memref_rmem_f16_1
      %148 = arith.cmpi sgt, %108, %c0_i32 : i32
      %149 = cute.get_scalars(%60) : !cute.int_tuple<"2">
      %sub = cute.tuple_sub(%e0_41, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %150 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %ptr_61 = cute.add_offset(%iter_56, %43) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_62 = cute.add_offset(%iter_60, %43) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<8>>
      %iter_63 = cute.get_iter(%rmem_40) : !memref_rmem_f32_
      %151 = cute.get_scalars(%61) : !cute.int_tuple<"1">
      %152 = cute.get_scalars(%58) : !cute.int_tuple<"4">
      %ptr_64 = cute.add_offset(%iter_56, %39) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_65 = cute.add_offset(%iter_60, %39) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_66 = cute.add_offset(%iter_56, %37) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_67 = cute.add_offset(%iter_60, %37) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_68 = cute.add_offset(%iter_56, %43) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_69 = cute.add_offset(%iter_60, %43) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<8>>
      %iter_70 = cute.get_iter(%rmem_40) : !memref_rmem_f32_
      %153 = cute.get_scalars(%61) : !cute.int_tuple<"1">
      %154 = cute.get_scalars(%58) : !cute.int_tuple<"4">
      %ptr_71 = cute.add_offset(%iter_56, %39) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_72 = cute.add_offset(%iter_60, %39) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_73 = cute.add_offset(%iter_56, %37) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_74 = cute.add_offset(%iter_60, %37) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<8>>
      %atom_75 = cute.make_atom() : () -> !cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>
      %155 = arith.divsi %123, %c2_i32 : i32
      %156 = arith.remsi %123, %c2_i32 : i32
      %157 = arith.muli %156, %c64_i32 : i32
      %158 = arith.divsi %155, %c4_i32 : i32
      %159 = arith.remsi %155, %c4_i32 : i32
      %160 = arith.muli %159, %c128_i32 : i32
      %161 = arith.addi %157, %160 : i32
      %162 = arith.divsi %158, %c2_i32 : i32
      %163 = arith.remsi %158, %c2_i32 : i32
      %164 = arith.muli %163, %c8_i32 : i32
      %165 = arith.addi %161, %164 : i32
      %166 = arith.divsi %162, %c2_i32 : i32
      %167 = arith.remsi %162, %c2_i32 : i32
      %168 = arith.muli %167, %c1024_i32 : i32
      %169 = arith.addi %165, %168 : i32
      %170 = arith.divsi %166, %c2_i32 : i32
      %171 = arith.remsi %166, %c2_i32 : i32
      %172 = arith.muli %171, %c16_i32 : i32
      %173 = arith.addi %169, %172 : i32
      %174 = arith.muli %170, %c512_i32 : i32
      %175 = arith.addi %173, %174 : i32
      %iv_76 = cute.assume(%175) : (i32) -> !cute.i32<divby 8>
      %int_tuple_77 = cute.make_int_tuple(%iv_76) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_78 = cute.add_offset(%iter_15, %int_tuple_77) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view = cute.make_view(%iter_70) : !memref_rmem_f32_1
      %ptr_79 = cute.add_offset(%ptr_78, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb8(%117, %118, %119, %115, %c0_i32, %c0_i32, %109, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb8(%176: i32, %177: i32, %178: i32, %179: i1, %180: i32, %181: i32, %182: i32, %183: i32):  // 2 preds: ^bb7, ^bb168
      cf.cond_br %179, ^bb9(%176, %177, %178, %180, %181, %182, %183 : i32, i32, i32, i32, i32, i32, i32), ^bb169
    ^bb9(%184: i32, %185: i32, %186: i32, %187: i32, %188: i32, %189: i32, %190: i32):  // pred: ^bb8
      %coord_80 = cute.make_coord(%184, %185, %186) : (i32, i32, i32) -> !cute.coord<"(_,_,?,?,?)">
      %idx = cute.crd2idx(%coord_80, %lay_30) : (!cute.coord<"(_,_,?,?,?)">, !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %tup = cute.add_offset(%55, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},?{div=64},?)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cute.memref.store_vec %cst, %rmem_40, row_major : !memref_rmem_f32_
      cf.cond_br %148, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %int_tuple_81 = cute.make_int_tuple(%187) : (i32) -> !cute.int_tuple<"?">
      %ptr_82 = cute.add_offset(%iter, %int_tuple_81) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %191 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %192 = nvvm.mbarrier.wait.parity %191, %188 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb12(%192 : i1)
    ^bb11:  // pred: ^bb9
      cf.br ^bb12(%true : i1)
    ^bb12(%193: i1):  // 2 preds: ^bb10, ^bb11
      cf.br ^bb13
    ^bb13:  // pred: ^bb12
      %194 = arith.extui %193 : i1 to i32
      %195 = arith.cmpi eq, %194, %c0_i32 : i32
      cf.cond_br %195, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %int_tuple_83 = cute.make_int_tuple(%187) : (i32) -> !cute.int_tuple<"?">
      %ptr_84 = cute.add_offset(%iter, %int_tuple_83) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %196 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %196, %188, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %coord_85 = cute.make_coord(%187) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_86 = cute.crd2idx(%coord_85, %51) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_87 = cute.add_offset(%ptr_55, %idx_86) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_88 = cute.make_view(%ptr_87) : !memref_smem_f16_
      %197 = builtin.unrealized_conversion_cast %view_88 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %ptr_89 = cute.add_offset(%ptr_59, %idx_86) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_90 = cute.make_view(%ptr_89) : !memref_smem_f16_
      %198 = builtin.unrealized_conversion_cast %view_90 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      cf.br ^bb16(%c0_i32 : i32)
    ^bb16(%199: i32):  // 2 preds: ^bb15, ^bb17
      %200 = arith.cmpi slt, %199, %149 : i32
      cf.cond_br %200, ^bb17, ^bb18 {llvm.loop_annotation = #loop_annotation}
    ^bb17:  // pred: ^bb16
      %coord_91 = cute.make_coord(%199) : (i32) -> !cute.coord<"(_,?)">
      %idx_92 = cute.crd2idx(%coord_91, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_93 = cute.add_offset(%ptr_55, %idx_92) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_94 = cute.crd2idx(%coord_91, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_95 = cute.add_offset(%iter_56, %idx_94) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled = cute.apply_swizzle(%ptr_93) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_96 = cute.add_offset(%swizzled, %idx_86) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %201 = cute_nvgpu.arch.copy.ldsm %ptr_96{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %202 = vector.extractelement %201[%48 : i32] : vector<4xi32>
      %203 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %202, %203 : i32, !llvm.ptr
      %204 = vector.extractelement %201[%47 : i32] : vector<4xi32>
      %ptr_97 = cute.add_offset(%ptr_95, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %205 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %204, %205 : i32, !llvm.ptr
      %206 = vector.extractelement %201[%46 : i32] : vector<4xi32>
      %ptr_98 = cute.add_offset(%ptr_95, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %207 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %206, %207 : i32, !llvm.ptr
      %208 = vector.extractelement %201[%45 : i32] : vector<4xi32>
      %ptr_99 = cute.add_offset(%ptr_95, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %209 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %208, %209 : i32, !llvm.ptr
      %210 = arith.addi %199, %c1_i32 : i32
      cf.br ^bb16(%210 : i32)
    ^bb18:  // pred: ^bb16
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%211: i32):  // 2 preds: ^bb18, ^bb20
      %212 = arith.cmpi slt, %211, %149 : i32
      cf.cond_br %212, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation}
    ^bb20:  // pred: ^bb19
      %coord_100 = cute.make_coord(%211) : (i32) -> !cute.coord<"(_,?)">
      %idx_101 = cute.crd2idx(%coord_100, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_102 = cute.add_offset(%ptr_59, %idx_101) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_103 = cute.crd2idx(%coord_100, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_104 = cute.add_offset(%iter_60, %idx_103) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_105 = cute.apply_swizzle(%ptr_102) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_106 = cute.add_offset(%swizzled_105, %idx_86) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %213 = cute_nvgpu.arch.copy.ldsm %ptr_106{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %214 = vector.extractelement %213[%48 : i32] : vector<4xi32>
      %215 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %214, %215 : i32, !llvm.ptr
      %216 = vector.extractelement %213[%47 : i32] : vector<4xi32>
      %ptr_107 = cute.add_offset(%ptr_104, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %217 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %216, %217 : i32, !llvm.ptr
      %218 = vector.extractelement %213[%46 : i32] : vector<4xi32>
      %ptr_108 = cute.add_offset(%ptr_104, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %219 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %218, %219 : i32, !llvm.ptr
      %220 = vector.extractelement %213[%45 : i32] : vector<4xi32>
      %ptr_109 = cute.add_offset(%ptr_104, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %221 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %220, %221 : i32, !llvm.ptr
      %222 = arith.addi %211, %c1_i32 : i32
      cf.br ^bb19(%222 : i32)
    ^bb21:  // pred: ^bb19
      cf.br ^bb22(%c0_i32, %197, %198, %c0_i32, %187, %188 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb22(%223: i32, %224: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %225: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %226: i32, %227: i32, %228: i32):  // 2 preds: ^bb21, ^bb91
      %229 = arith.cmpi slt, %223, %150 : i32
      cf.cond_br %229, ^bb23, ^bb92 {loop_annotation = #loop_annotation1}
    ^bb23:  // pred: ^bb22
      %230 = builtin.unrealized_conversion_cast %225 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %231 = builtin.unrealized_conversion_cast %224 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %iter_110 = cute.get_iter(%231) : !memref_smem_f16_
      %ptr_111 = cute.add_offset(%iter_110, %64) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb24(%c0_i32 : i32)
    ^bb24(%232: i32):  // 2 preds: ^bb23, ^bb25
      %233 = arith.cmpi slt, %232, %149 : i32
      cf.cond_br %233, ^bb25, ^bb26 {llvm.loop_annotation = #loop_annotation}
    ^bb25:  // pred: ^bb24
      %coord_112 = cute.make_coord(%232) : (i32) -> !cute.coord<"(_,?)">
      %idx_113 = cute.crd2idx(%coord_112, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_114 = cute.add_offset(%ptr_111, %idx_113) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_115 = cute.crd2idx(%coord_112, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_116 = cute.add_offset(%ptr_61, %idx_115) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_117 = cute.apply_swizzle(%ptr_114) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %234 = cute_nvgpu.arch.copy.ldsm %swizzled_117{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %235 = vector.extractelement %234[%48 : i32] : vector<4xi32>
      %236 = builtin.unrealized_conversion_cast %ptr_116 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %235, %236 : i32, !llvm.ptr
      %237 = vector.extractelement %234[%47 : i32] : vector<4xi32>
      %ptr_118 = cute.add_offset(%ptr_116, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %238 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %237, %238 : i32, !llvm.ptr
      %239 = vector.extractelement %234[%46 : i32] : vector<4xi32>
      %ptr_119 = cute.add_offset(%ptr_116, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %240 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %239, %240 : i32, !llvm.ptr
      %241 = vector.extractelement %234[%45 : i32] : vector<4xi32>
      %ptr_120 = cute.add_offset(%ptr_116, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %242 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %241, %242 : i32, !llvm.ptr
      %243 = arith.addi %232, %c1_i32 : i32
      cf.br ^bb24(%243 : i32)
    ^bb26:  // pred: ^bb24
      %iter_121 = cute.get_iter(%230) : !memref_smem_f16_
      %ptr_122 = cute.add_offset(%iter_121, %64) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb27(%c0_i32 : i32)
    ^bb27(%244: i32):  // 2 preds: ^bb26, ^bb28
      %245 = arith.cmpi slt, %244, %149 : i32
      cf.cond_br %245, ^bb28, ^bb29 {llvm.loop_annotation = #loop_annotation}
    ^bb28:  // pred: ^bb27
      %coord_123 = cute.make_coord(%244) : (i32) -> !cute.coord<"(_,?)">
      %idx_124 = cute.crd2idx(%coord_123, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_125 = cute.add_offset(%ptr_122, %idx_124) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_126 = cute.crd2idx(%coord_123, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_127 = cute.add_offset(%ptr_62, %idx_126) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_128 = cute.apply_swizzle(%ptr_125) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %246 = cute_nvgpu.arch.copy.ldsm %swizzled_128{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %247 = vector.extractelement %246[%48 : i32] : vector<4xi32>
      %248 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %247, %248 : i32, !llvm.ptr
      %249 = vector.extractelement %246[%47 : i32] : vector<4xi32>
      %ptr_129 = cute.add_offset(%ptr_127, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %250 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %249, %250 : i32, !llvm.ptr
      %251 = vector.extractelement %246[%46 : i32] : vector<4xi32>
      %ptr_130 = cute.add_offset(%ptr_127, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %252 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %251, %252 : i32, !llvm.ptr
      %253 = vector.extractelement %246[%45 : i32] : vector<4xi32>
      %ptr_131 = cute.add_offset(%ptr_127, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %254 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %253, %254 : i32, !llvm.ptr
      %255 = arith.addi %244, %c1_i32 : i32
      cf.br ^bb27(%255 : i32)
    ^bb29:  // pred: ^bb27
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%256: i32):  // 2 preds: ^bb29, ^bb37
      %257 = arith.cmpi slt, %256, %151 : i32
      cf.cond_br %257, ^bb31, ^bb38 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%258: i32):  // 2 preds: ^bb31, ^bb36
      %259 = arith.cmpi slt, %258, %149 : i32
      cf.cond_br %259, ^bb33, ^bb37 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_132 = cute.make_coord(%258, %256) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_133 = cute.crd2idx(%coord_132, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_134 = cute.add_offset(%iter_56, %idx_133) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %260 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %261 = llvm.getelementptr %260[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %262 = llvm.getelementptr %260[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %263 = llvm.getelementptr %260[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb34(%c0_i32 : i32)
    ^bb34(%264: i32):  // 2 preds: ^bb33, ^bb35
      %265 = arith.cmpi slt, %264, %152 : i32
      cf.cond_br %265, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %coord_135 = cute.make_coord(%264, %256) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_136 = cute.make_coord(%258, %264) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_137 = cute.crd2idx(%coord_135, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_138 = cute.add_offset(%iter_60, %idx_137) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_139 = cute.crd2idx(%coord_136, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_140 = cute.add_offset(%iter_63, %idx_139) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %266 = llvm.load %260 : !llvm.ptr -> vector<2xf16>
      %267 = llvm.load %261 : !llvm.ptr -> vector<2xf16>
      %268 = llvm.load %262 : !llvm.ptr -> vector<2xf16>
      %269 = llvm.load %263 : !llvm.ptr -> vector<2xf16>
      %270 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %271 = llvm.load %270 : !llvm.ptr -> vector<2xf16>
      %272 = llvm.getelementptr %270[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %273 = llvm.load %272 : !llvm.ptr -> vector<2xf16>
      %274 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %275 = llvm.load %274 : !llvm.ptr -> f32
      %276 = llvm.getelementptr %274[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %277 = llvm.load %276 : !llvm.ptr -> f32
      %278 = llvm.getelementptr %274[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %279 = llvm.load %278 : !llvm.ptr -> f32
      %280 = llvm.getelementptr %274[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %281 = llvm.load %280 : !llvm.ptr -> f32
      %282:4 = cute_nvgpu.arch.mma.SM80 A[%266, %267, %268, %269]  B[%271, %273]  C[%275, %277, %279, %281] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %282#0, %274 : f32, !llvm.ptr
      llvm.store %282#1, %276 : f32, !llvm.ptr
      llvm.store %282#2, %278 : f32, !llvm.ptr
      llvm.store %282#3, %280 : f32, !llvm.ptr
      %283 = arith.addi %264, %c1_i32 : i32
      cf.br ^bb34(%283 : i32)
    ^bb36:  // pred: ^bb34
      %284 = arith.addi %258, %c1_i32 : i32
      cf.br ^bb32(%284 : i32)
    ^bb37:  // pred: ^bb32
      %285 = arith.addi %256, %c1_i32 : i32
      cf.br ^bb30(%285 : i32)
    ^bb38:  // pred: ^bb30
      %ptr_141 = cute.add_offset(%iter_110, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb39(%c0_i32 : i32)
    ^bb39(%286: i32):  // 2 preds: ^bb38, ^bb40
      %287 = arith.cmpi slt, %286, %149 : i32
      cf.cond_br %287, ^bb40, ^bb41 {llvm.loop_annotation = #loop_annotation}
    ^bb40:  // pred: ^bb39
      %coord_142 = cute.make_coord(%286) : (i32) -> !cute.coord<"(_,?)">
      %idx_143 = cute.crd2idx(%coord_142, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_144 = cute.add_offset(%ptr_141, %idx_143) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_145 = cute.crd2idx(%coord_142, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_146 = cute.add_offset(%ptr_64, %idx_145) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_147 = cute.apply_swizzle(%ptr_144) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %288 = cute_nvgpu.arch.copy.ldsm %swizzled_147{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %289 = vector.extractelement %288[%48 : i32] : vector<4xi32>
      %290 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %289, %290 : i32, !llvm.ptr
      %291 = vector.extractelement %288[%47 : i32] : vector<4xi32>
      %ptr_148 = cute.add_offset(%ptr_146, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %292 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %291, %292 : i32, !llvm.ptr
      %293 = vector.extractelement %288[%46 : i32] : vector<4xi32>
      %ptr_149 = cute.add_offset(%ptr_146, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %294 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %293, %294 : i32, !llvm.ptr
      %295 = vector.extractelement %288[%45 : i32] : vector<4xi32>
      %ptr_150 = cute.add_offset(%ptr_146, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %296 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %295, %296 : i32, !llvm.ptr
      %297 = arith.addi %286, %c1_i32 : i32
      cf.br ^bb39(%297 : i32)
    ^bb41:  // pred: ^bb39
      %ptr_151 = cute.add_offset(%iter_121, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%298: i32):  // 2 preds: ^bb41, ^bb43
      %299 = arith.cmpi slt, %298, %149 : i32
      cf.cond_br %299, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %coord_152 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,?)">
      %idx_153 = cute.crd2idx(%coord_152, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_154 = cute.add_offset(%ptr_151, %idx_153) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_155 = cute.crd2idx(%coord_152, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_156 = cute.add_offset(%ptr_65, %idx_155) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_157 = cute.apply_swizzle(%ptr_154) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %300 = cute_nvgpu.arch.copy.ldsm %swizzled_157{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %301 = vector.extractelement %300[%48 : i32] : vector<4xi32>
      %302 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %301, %302 : i32, !llvm.ptr
      %303 = vector.extractelement %300[%47 : i32] : vector<4xi32>
      %ptr_158 = cute.add_offset(%ptr_156, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %304 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %303, %304 : i32, !llvm.ptr
      %305 = vector.extractelement %300[%46 : i32] : vector<4xi32>
      %ptr_159 = cute.add_offset(%ptr_156, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %306 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %305, %306 : i32, !llvm.ptr
      %307 = vector.extractelement %300[%45 : i32] : vector<4xi32>
      %ptr_160 = cute.add_offset(%ptr_156, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %308 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %307, %308 : i32, !llvm.ptr
      %309 = arith.addi %298, %c1_i32 : i32
      cf.br ^bb42(%309 : i32)
    ^bb44:  // pred: ^bb42
      cf.br ^bb45(%c0_i32 : i32)
    ^bb45(%310: i32):  // 2 preds: ^bb44, ^bb52
      %311 = arith.cmpi slt, %310, %151 : i32
      cf.cond_br %311, ^bb46, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb46:  // pred: ^bb45
      cf.br ^bb47(%c0_i32 : i32)
    ^bb47(%312: i32):  // 2 preds: ^bb46, ^bb51
      %313 = arith.cmpi slt, %312, %149 : i32
      cf.cond_br %313, ^bb48, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %coord_161 = cute.make_coord(%312, %310) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_162 = cute.crd2idx(%coord_161, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_163 = cute.add_offset(%ptr_61, %idx_162) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %314 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %315 = llvm.getelementptr %314[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %316 = llvm.getelementptr %314[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %317 = llvm.getelementptr %314[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb49(%c0_i32 : i32)
    ^bb49(%318: i32):  // 2 preds: ^bb48, ^bb50
      %319 = arith.cmpi slt, %318, %152 : i32
      cf.cond_br %319, ^bb50, ^bb51 {llvm.loop_annotation = #loop_annotation}
    ^bb50:  // pred: ^bb49
      %coord_164 = cute.make_coord(%318, %310) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_165 = cute.make_coord(%312, %318) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_166 = cute.crd2idx(%coord_164, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_167 = cute.add_offset(%ptr_62, %idx_166) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_168 = cute.crd2idx(%coord_165, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_169 = cute.add_offset(%iter_63, %idx_168) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %320 = llvm.load %314 : !llvm.ptr -> vector<2xf16>
      %321 = llvm.load %315 : !llvm.ptr -> vector<2xf16>
      %322 = llvm.load %316 : !llvm.ptr -> vector<2xf16>
      %323 = llvm.load %317 : !llvm.ptr -> vector<2xf16>
      %324 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %325 = llvm.load %324 : !llvm.ptr -> vector<2xf16>
      %326 = llvm.getelementptr %324[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %327 = llvm.load %326 : !llvm.ptr -> vector<2xf16>
      %328 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %329 = llvm.load %328 : !llvm.ptr -> f32
      %330 = llvm.getelementptr %328[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %331 = llvm.load %330 : !llvm.ptr -> f32
      %332 = llvm.getelementptr %328[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %333 = llvm.load %332 : !llvm.ptr -> f32
      %334 = llvm.getelementptr %328[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %335 = llvm.load %334 : !llvm.ptr -> f32
      %336:4 = cute_nvgpu.arch.mma.SM80 A[%320, %321, %322, %323]  B[%325, %327]  C[%329, %331, %333, %335] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %336#0, %328 : f32, !llvm.ptr
      llvm.store %336#1, %330 : f32, !llvm.ptr
      llvm.store %336#2, %332 : f32, !llvm.ptr
      llvm.store %336#3, %334 : f32, !llvm.ptr
      %337 = arith.addi %318, %c1_i32 : i32
      cf.br ^bb49(%337 : i32)
    ^bb51:  // pred: ^bb49
      %338 = arith.addi %312, %c1_i32 : i32
      cf.br ^bb47(%338 : i32)
    ^bb52:  // pred: ^bb47
      %339 = arith.addi %310, %c1_i32 : i32
      cf.br ^bb45(%339 : i32)
    ^bb53:  // pred: ^bb45
      %ptr_170 = cute.add_offset(%iter_110, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%340: i32):  // 2 preds: ^bb53, ^bb55
      %341 = arith.cmpi slt, %340, %149 : i32
      cf.cond_br %341, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %coord_171 = cute.make_coord(%340) : (i32) -> !cute.coord<"(_,?)">
      %idx_172 = cute.crd2idx(%coord_171, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_173 = cute.add_offset(%ptr_170, %idx_172) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_174 = cute.crd2idx(%coord_171, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_175 = cute.add_offset(%ptr_66, %idx_174) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_176 = cute.apply_swizzle(%ptr_173) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %342 = cute_nvgpu.arch.copy.ldsm %swizzled_176{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %343 = vector.extractelement %342[%48 : i32] : vector<4xi32>
      %344 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %343, %344 : i32, !llvm.ptr
      %345 = vector.extractelement %342[%47 : i32] : vector<4xi32>
      %ptr_177 = cute.add_offset(%ptr_175, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %346 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %345, %346 : i32, !llvm.ptr
      %347 = vector.extractelement %342[%46 : i32] : vector<4xi32>
      %ptr_178 = cute.add_offset(%ptr_175, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %348 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %347, %348 : i32, !llvm.ptr
      %349 = vector.extractelement %342[%45 : i32] : vector<4xi32>
      %ptr_179 = cute.add_offset(%ptr_175, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %350 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %349, %350 : i32, !llvm.ptr
      %351 = arith.addi %340, %c1_i32 : i32
      cf.br ^bb54(%351 : i32)
    ^bb56:  // pred: ^bb54
      %ptr_180 = cute.add_offset(%iter_121, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb57(%c0_i32 : i32)
    ^bb57(%352: i32):  // 2 preds: ^bb56, ^bb58
      %353 = arith.cmpi slt, %352, %149 : i32
      cf.cond_br %353, ^bb58, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb58:  // pred: ^bb57
      %coord_181 = cute.make_coord(%352) : (i32) -> !cute.coord<"(_,?)">
      %idx_182 = cute.crd2idx(%coord_181, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_183 = cute.add_offset(%ptr_180, %idx_182) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_184 = cute.crd2idx(%coord_181, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_185 = cute.add_offset(%ptr_67, %idx_184) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_186 = cute.apply_swizzle(%ptr_183) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %354 = cute_nvgpu.arch.copy.ldsm %swizzled_186{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %355 = vector.extractelement %354[%48 : i32] : vector<4xi32>
      %356 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %355, %356 : i32, !llvm.ptr
      %357 = vector.extractelement %354[%47 : i32] : vector<4xi32>
      %ptr_187 = cute.add_offset(%ptr_185, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %358 = builtin.unrealized_conversion_cast %ptr_187 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %357, %358 : i32, !llvm.ptr
      %359 = vector.extractelement %354[%46 : i32] : vector<4xi32>
      %ptr_188 = cute.add_offset(%ptr_185, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %360 = builtin.unrealized_conversion_cast %ptr_188 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %359, %360 : i32, !llvm.ptr
      %361 = vector.extractelement %354[%45 : i32] : vector<4xi32>
      %ptr_189 = cute.add_offset(%ptr_185, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %362 = builtin.unrealized_conversion_cast %ptr_189 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %361, %362 : i32, !llvm.ptr
      %363 = arith.addi %352, %c1_i32 : i32
      cf.br ^bb57(%363 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%364: i32):  // 2 preds: ^bb59, ^bb67
      %365 = arith.cmpi slt, %364, %151 : i32
      cf.cond_br %365, ^bb61, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%366: i32):  // 2 preds: ^bb61, ^bb66
      %367 = arith.cmpi slt, %366, %149 : i32
      cf.cond_br %367, ^bb63, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %coord_190 = cute.make_coord(%366, %364) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_191 = cute.crd2idx(%coord_190, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_192 = cute.add_offset(%ptr_64, %idx_191) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %368 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %369 = llvm.getelementptr %368[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %370 = llvm.getelementptr %368[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %371 = llvm.getelementptr %368[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%372: i32):  // 2 preds: ^bb63, ^bb65
      %373 = arith.cmpi slt, %372, %152 : i32
      cf.cond_br %373, ^bb65, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      %coord_193 = cute.make_coord(%372, %364) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_194 = cute.make_coord(%366, %372) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_195 = cute.crd2idx(%coord_193, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_196 = cute.add_offset(%ptr_65, %idx_195) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_197 = cute.crd2idx(%coord_194, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_198 = cute.add_offset(%iter_63, %idx_197) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %374 = llvm.load %368 : !llvm.ptr -> vector<2xf16>
      %375 = llvm.load %369 : !llvm.ptr -> vector<2xf16>
      %376 = llvm.load %370 : !llvm.ptr -> vector<2xf16>
      %377 = llvm.load %371 : !llvm.ptr -> vector<2xf16>
      %378 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %379 = llvm.load %378 : !llvm.ptr -> vector<2xf16>
      %380 = llvm.getelementptr %378[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %381 = llvm.load %380 : !llvm.ptr -> vector<2xf16>
      %382 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %383 = llvm.load %382 : !llvm.ptr -> f32
      %384 = llvm.getelementptr %382[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %385 = llvm.load %384 : !llvm.ptr -> f32
      %386 = llvm.getelementptr %382[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %387 = llvm.load %386 : !llvm.ptr -> f32
      %388 = llvm.getelementptr %382[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %389 = llvm.load %388 : !llvm.ptr -> f32
      %390:4 = cute_nvgpu.arch.mma.SM80 A[%374, %375, %376, %377]  B[%379, %381]  C[%383, %385, %387, %389] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %390#0, %382 : f32, !llvm.ptr
      llvm.store %390#1, %384 : f32, !llvm.ptr
      llvm.store %390#2, %386 : f32, !llvm.ptr
      llvm.store %390#3, %388 : f32, !llvm.ptr
      %391 = arith.addi %372, %c1_i32 : i32
      cf.br ^bb64(%391 : i32)
    ^bb66:  // pred: ^bb64
      %392 = arith.addi %366, %c1_i32 : i32
      cf.br ^bb62(%392 : i32)
    ^bb67:  // pred: ^bb62
      %393 = arith.addi %364, %c1_i32 : i32
      cf.br ^bb60(%393 : i32)
    ^bb68:  // pred: ^bb60
      cf.cond_br %91, ^bb69, ^bb70
    ^bb69:  // pred: ^bb68
      %int_tuple_199 = cute.make_int_tuple(%227) : (i32) -> !cute.int_tuple<"?">
      %ptr_200 = cute.add_offset(%ptr_6, %int_tuple_199) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %394 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %394, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb70
    ^bb70:  // 2 preds: ^bb68, ^bb69
      %395 = arith.addi %227, %c1_i32 : i32
      %396 = arith.addi %226, %c1_i32 : i32
      %397 = arith.cmpi eq, %395, %c4_i32 : i32
      %398 = arith.select %397, %c0_i32, %395 : i32
      cf.cond_br %397, ^bb71, ^bb72
    ^bb71:  // pred: ^bb70
      %399 = arith.xori %228, %c1_i32 : i32
      cf.br ^bb73(%399 : i32)
    ^bb72:  // pred: ^bb70
      cf.br ^bb73(%228 : i32)
    ^bb73(%400: i32):  // 2 preds: ^bb71, ^bb72
      cf.br ^bb74
    ^bb74:  // pred: ^bb73
      %int_tuple_201 = cute.make_int_tuple(%398) : (i32) -> !cute.int_tuple<"?">
      %ptr_202 = cute.add_offset(%iter, %int_tuple_201) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %401 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %402 = nvvm.mbarrier.wait.parity %401, %400 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      %coord_203 = cute.make_coord(%398) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_204 = cute.crd2idx(%coord_203, %51) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_205 = cute.add_offset(%ptr_55, %idx_204) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_206 = cute.make_view(%ptr_205) : !memref_smem_f16_
      %403 = builtin.unrealized_conversion_cast %view_206 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %ptr_207 = cute.add_offset(%ptr_59, %idx_204) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_208 = cute.make_view(%ptr_207) : !memref_smem_f16_
      %404 = builtin.unrealized_conversion_cast %view_208 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %405 = arith.extui %402 : i1 to i32
      %406 = arith.cmpi eq, %405, %c0_i32 : i32
      cf.cond_br %406, ^bb75, ^bb76
    ^bb75:  // pred: ^bb74
      nvvm.mbarrier.try_wait.parity.shared %401, %400, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb76
    ^bb76:  // 2 preds: ^bb74, ^bb75
      cf.br ^bb77(%c0_i32 : i32)
    ^bb77(%407: i32):  // 2 preds: ^bb76, ^bb78
      %408 = arith.cmpi slt, %407, %149 : i32
      cf.cond_br %408, ^bb78, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb78:  // pred: ^bb77
      %coord_209 = cute.make_coord(%407) : (i32) -> !cute.coord<"(_,?)">
      %idx_210 = cute.crd2idx(%coord_209, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_211 = cute.add_offset(%ptr_55, %idx_210) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_212 = cute.crd2idx(%coord_209, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_213 = cute.add_offset(%iter_56, %idx_212) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_214 = cute.apply_swizzle(%ptr_211) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_215 = cute.add_offset(%swizzled_214, %idx_204) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %409 = cute_nvgpu.arch.copy.ldsm %ptr_215{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %410 = vector.extractelement %409[%48 : i32] : vector<4xi32>
      %411 = builtin.unrealized_conversion_cast %ptr_213 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %410, %411 : i32, !llvm.ptr
      %412 = vector.extractelement %409[%47 : i32] : vector<4xi32>
      %ptr_216 = cute.add_offset(%ptr_213, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %413 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %412, %413 : i32, !llvm.ptr
      %414 = vector.extractelement %409[%46 : i32] : vector<4xi32>
      %ptr_217 = cute.add_offset(%ptr_213, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %415 = builtin.unrealized_conversion_cast %ptr_217 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %414, %415 : i32, !llvm.ptr
      %416 = vector.extractelement %409[%45 : i32] : vector<4xi32>
      %ptr_218 = cute.add_offset(%ptr_213, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %417 = builtin.unrealized_conversion_cast %ptr_218 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %416, %417 : i32, !llvm.ptr
      %418 = arith.addi %407, %c1_i32 : i32
      cf.br ^bb77(%418 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%419: i32):  // 2 preds: ^bb79, ^bb81
      %420 = arith.cmpi slt, %419, %149 : i32
      cf.cond_br %420, ^bb81, ^bb82 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      %coord_219 = cute.make_coord(%419) : (i32) -> !cute.coord<"(_,?)">
      %idx_220 = cute.crd2idx(%coord_219, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_221 = cute.add_offset(%ptr_59, %idx_220) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_222 = cute.crd2idx(%coord_219, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_223 = cute.add_offset(%iter_60, %idx_222) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_224 = cute.apply_swizzle(%ptr_221) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_225 = cute.add_offset(%swizzled_224, %idx_204) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %421 = cute_nvgpu.arch.copy.ldsm %ptr_225{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %422 = vector.extractelement %421[%48 : i32] : vector<4xi32>
      %423 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %422, %423 : i32, !llvm.ptr
      %424 = vector.extractelement %421[%47 : i32] : vector<4xi32>
      %ptr_226 = cute.add_offset(%ptr_223, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %425 = builtin.unrealized_conversion_cast %ptr_226 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %424, %425 : i32, !llvm.ptr
      %426 = vector.extractelement %421[%46 : i32] : vector<4xi32>
      %ptr_227 = cute.add_offset(%ptr_223, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %427 = builtin.unrealized_conversion_cast %ptr_227 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %426, %427 : i32, !llvm.ptr
      %428 = vector.extractelement %421[%45 : i32] : vector<4xi32>
      %ptr_228 = cute.add_offset(%ptr_223, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %429 = builtin.unrealized_conversion_cast %ptr_228 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %428, %429 : i32, !llvm.ptr
      %430 = arith.addi %419, %c1_i32 : i32
      cf.br ^bb80(%430 : i32)
    ^bb82:  // pred: ^bb80
      cf.br ^bb83(%c0_i32 : i32)
    ^bb83(%431: i32):  // 2 preds: ^bb82, ^bb90
      %432 = arith.cmpi slt, %431, %151 : i32
      cf.cond_br %432, ^bb84, ^bb91 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%433: i32):  // 2 preds: ^bb84, ^bb89
      %434 = arith.cmpi slt, %433, %149 : i32
      cf.cond_br %434, ^bb86, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      %coord_229 = cute.make_coord(%433, %431) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_230 = cute.crd2idx(%coord_229, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_231 = cute.add_offset(%ptr_66, %idx_230) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %435 = builtin.unrealized_conversion_cast %ptr_231 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %436 = llvm.getelementptr %435[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %437 = llvm.getelementptr %435[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %438 = llvm.getelementptr %435[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb87(%c0_i32 : i32)
    ^bb87(%439: i32):  // 2 preds: ^bb86, ^bb88
      %440 = arith.cmpi slt, %439, %152 : i32
      cf.cond_br %440, ^bb88, ^bb89 {llvm.loop_annotation = #loop_annotation}
    ^bb88:  // pred: ^bb87
      %coord_232 = cute.make_coord(%439, %431) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_233 = cute.make_coord(%433, %439) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_234 = cute.crd2idx(%coord_232, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_235 = cute.add_offset(%ptr_67, %idx_234) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_236 = cute.crd2idx(%coord_233, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_237 = cute.add_offset(%iter_63, %idx_236) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %441 = llvm.load %435 : !llvm.ptr -> vector<2xf16>
      %442 = llvm.load %436 : !llvm.ptr -> vector<2xf16>
      %443 = llvm.load %437 : !llvm.ptr -> vector<2xf16>
      %444 = llvm.load %438 : !llvm.ptr -> vector<2xf16>
      %445 = builtin.unrealized_conversion_cast %ptr_235 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %446 = llvm.load %445 : !llvm.ptr -> vector<2xf16>
      %447 = llvm.getelementptr %445[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %448 = llvm.load %447 : !llvm.ptr -> vector<2xf16>
      %449 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %450 = llvm.load %449 : !llvm.ptr -> f32
      %451 = llvm.getelementptr %449[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %452 = llvm.load %451 : !llvm.ptr -> f32
      %453 = llvm.getelementptr %449[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %454 = llvm.load %453 : !llvm.ptr -> f32
      %455 = llvm.getelementptr %449[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %456 = llvm.load %455 : !llvm.ptr -> f32
      %457:4 = cute_nvgpu.arch.mma.SM80 A[%441, %442, %443, %444]  B[%446, %448]  C[%450, %452, %454, %456] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %457#0, %449 : f32, !llvm.ptr
      llvm.store %457#1, %451 : f32, !llvm.ptr
      llvm.store %457#2, %453 : f32, !llvm.ptr
      llvm.store %457#3, %455 : f32, !llvm.ptr
      %458 = arith.addi %439, %c1_i32 : i32
      cf.br ^bb87(%458 : i32)
    ^bb89:  // pred: ^bb87
      %459 = arith.addi %433, %c1_i32 : i32
      cf.br ^bb85(%459 : i32)
    ^bb90:  // pred: ^bb85
      %460 = arith.addi %431, %c1_i32 : i32
      cf.br ^bb83(%460 : i32)
    ^bb91:  // pred: ^bb83
      %461 = arith.addi %223, %c1_i32 : i32
      cf.br ^bb22(%461, %403, %404, %396, %398, %400 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb92:  // pred: ^bb22
      %462 = builtin.unrealized_conversion_cast %225 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %463 = builtin.unrealized_conversion_cast %224 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %iter_238 = cute.get_iter(%463) : !memref_smem_f16_
      %ptr_239 = cute.add_offset(%iter_238, %64) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%464: i32):  // 2 preds: ^bb92, ^bb94
      %465 = arith.cmpi slt, %464, %149 : i32
      cf.cond_br %465, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      %coord_240 = cute.make_coord(%464) : (i32) -> !cute.coord<"(_,?)">
      %idx_241 = cute.crd2idx(%coord_240, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_242 = cute.add_offset(%ptr_239, %idx_241) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_243 = cute.crd2idx(%coord_240, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_244 = cute.add_offset(%ptr_68, %idx_243) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_245 = cute.apply_swizzle(%ptr_242) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %466 = cute_nvgpu.arch.copy.ldsm %swizzled_245{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %467 = vector.extractelement %466[%48 : i32] : vector<4xi32>
      %468 = builtin.unrealized_conversion_cast %ptr_244 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %467, %468 : i32, !llvm.ptr
      %469 = vector.extractelement %466[%47 : i32] : vector<4xi32>
      %ptr_246 = cute.add_offset(%ptr_244, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %470 = builtin.unrealized_conversion_cast %ptr_246 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %469, %470 : i32, !llvm.ptr
      %471 = vector.extractelement %466[%46 : i32] : vector<4xi32>
      %ptr_247 = cute.add_offset(%ptr_244, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %472 = builtin.unrealized_conversion_cast %ptr_247 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %471, %472 : i32, !llvm.ptr
      %473 = vector.extractelement %466[%45 : i32] : vector<4xi32>
      %ptr_248 = cute.add_offset(%ptr_244, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %474 = builtin.unrealized_conversion_cast %ptr_248 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %473, %474 : i32, !llvm.ptr
      %475 = arith.addi %464, %c1_i32 : i32
      cf.br ^bb93(%475 : i32)
    ^bb95:  // pred: ^bb93
      %iter_249 = cute.get_iter(%462) : !memref_smem_f16_
      %ptr_250 = cute.add_offset(%iter_249, %64) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb96(%c0_i32 : i32)
    ^bb96(%476: i32):  // 2 preds: ^bb95, ^bb97
      %477 = arith.cmpi slt, %476, %149 : i32
      cf.cond_br %477, ^bb97, ^bb98 {llvm.loop_annotation = #loop_annotation}
    ^bb97:  // pred: ^bb96
      %coord_251 = cute.make_coord(%476) : (i32) -> !cute.coord<"(_,?)">
      %idx_252 = cute.crd2idx(%coord_251, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_253 = cute.add_offset(%ptr_250, %idx_252) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_254 = cute.crd2idx(%coord_251, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_255 = cute.add_offset(%ptr_69, %idx_254) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_256 = cute.apply_swizzle(%ptr_253) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %478 = cute_nvgpu.arch.copy.ldsm %swizzled_256{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %479 = vector.extractelement %478[%48 : i32] : vector<4xi32>
      %480 = builtin.unrealized_conversion_cast %ptr_255 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %479, %480 : i32, !llvm.ptr
      %481 = vector.extractelement %478[%47 : i32] : vector<4xi32>
      %ptr_257 = cute.add_offset(%ptr_255, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %482 = builtin.unrealized_conversion_cast %ptr_257 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %481, %482 : i32, !llvm.ptr
      %483 = vector.extractelement %478[%46 : i32] : vector<4xi32>
      %ptr_258 = cute.add_offset(%ptr_255, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %484 = builtin.unrealized_conversion_cast %ptr_258 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %483, %484 : i32, !llvm.ptr
      %485 = vector.extractelement %478[%45 : i32] : vector<4xi32>
      %ptr_259 = cute.add_offset(%ptr_255, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %486 = builtin.unrealized_conversion_cast %ptr_259 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %485, %486 : i32, !llvm.ptr
      %487 = arith.addi %476, %c1_i32 : i32
      cf.br ^bb96(%487 : i32)
    ^bb98:  // pred: ^bb96
      cf.br ^bb99(%c0_i32 : i32)
    ^bb99(%488: i32):  // 2 preds: ^bb98, ^bb106
      %489 = arith.cmpi slt, %488, %153 : i32
      cf.cond_br %489, ^bb100, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb100:  // pred: ^bb99
      cf.br ^bb101(%c0_i32 : i32)
    ^bb101(%490: i32):  // 2 preds: ^bb100, ^bb105
      %491 = arith.cmpi slt, %490, %149 : i32
      cf.cond_br %491, ^bb102, ^bb106 {llvm.loop_annotation = #loop_annotation}
    ^bb102:  // pred: ^bb101
      %coord_260 = cute.make_coord(%490, %488) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_261 = cute.crd2idx(%coord_260, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_262 = cute.add_offset(%iter_56, %idx_261) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %492 = builtin.unrealized_conversion_cast %ptr_262 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %493 = llvm.getelementptr %492[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %494 = llvm.getelementptr %492[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %495 = llvm.getelementptr %492[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%496: i32):  // 2 preds: ^bb102, ^bb104
      %497 = arith.cmpi slt, %496, %154 : i32
      cf.cond_br %497, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation}
    ^bb104:  // pred: ^bb103
      %coord_263 = cute.make_coord(%496, %488) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_264 = cute.make_coord(%490, %496) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_265 = cute.crd2idx(%coord_263, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_266 = cute.add_offset(%iter_60, %idx_265) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_267 = cute.crd2idx(%coord_264, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_268 = cute.add_offset(%iter_70, %idx_267) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %498 = llvm.load %492 : !llvm.ptr -> vector<2xf16>
      %499 = llvm.load %493 : !llvm.ptr -> vector<2xf16>
      %500 = llvm.load %494 : !llvm.ptr -> vector<2xf16>
      %501 = llvm.load %495 : !llvm.ptr -> vector<2xf16>
      %502 = builtin.unrealized_conversion_cast %ptr_266 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %503 = llvm.load %502 : !llvm.ptr -> vector<2xf16>
      %504 = llvm.getelementptr %502[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %505 = llvm.load %504 : !llvm.ptr -> vector<2xf16>
      %506 = builtin.unrealized_conversion_cast %ptr_268 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %507 = llvm.load %506 : !llvm.ptr -> f32
      %508 = llvm.getelementptr %506[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %509 = llvm.load %508 : !llvm.ptr -> f32
      %510 = llvm.getelementptr %506[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %511 = llvm.load %510 : !llvm.ptr -> f32
      %512 = llvm.getelementptr %506[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %513 = llvm.load %512 : !llvm.ptr -> f32
      %514:4 = cute_nvgpu.arch.mma.SM80 A[%498, %499, %500, %501]  B[%503, %505]  C[%507, %509, %511, %513] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %514#0, %506 : f32, !llvm.ptr
      llvm.store %514#1, %508 : f32, !llvm.ptr
      llvm.store %514#2, %510 : f32, !llvm.ptr
      llvm.store %514#3, %512 : f32, !llvm.ptr
      %515 = arith.addi %496, %c1_i32 : i32
      cf.br ^bb103(%515 : i32)
    ^bb105:  // pred: ^bb103
      %516 = arith.addi %490, %c1_i32 : i32
      cf.br ^bb101(%516 : i32)
    ^bb106:  // pred: ^bb101
      %517 = arith.addi %488, %c1_i32 : i32
      cf.br ^bb99(%517 : i32)
    ^bb107:  // pred: ^bb99
      %ptr_269 = cute.add_offset(%iter_238, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%518: i32):  // 2 preds: ^bb107, ^bb109
      %519 = arith.cmpi slt, %518, %149 : i32
      cf.cond_br %519, ^bb109, ^bb110 {llvm.loop_annotation = #loop_annotation}
    ^bb109:  // pred: ^bb108
      %coord_270 = cute.make_coord(%518) : (i32) -> !cute.coord<"(_,?)">
      %idx_271 = cute.crd2idx(%coord_270, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_272 = cute.add_offset(%ptr_269, %idx_271) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_273 = cute.crd2idx(%coord_270, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_274 = cute.add_offset(%ptr_71, %idx_273) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_275 = cute.apply_swizzle(%ptr_272) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %520 = cute_nvgpu.arch.copy.ldsm %swizzled_275{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %521 = vector.extractelement %520[%48 : i32] : vector<4xi32>
      %522 = builtin.unrealized_conversion_cast %ptr_274 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %521, %522 : i32, !llvm.ptr
      %523 = vector.extractelement %520[%47 : i32] : vector<4xi32>
      %ptr_276 = cute.add_offset(%ptr_274, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %524 = builtin.unrealized_conversion_cast %ptr_276 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %523, %524 : i32, !llvm.ptr
      %525 = vector.extractelement %520[%46 : i32] : vector<4xi32>
      %ptr_277 = cute.add_offset(%ptr_274, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %526 = builtin.unrealized_conversion_cast %ptr_277 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %525, %526 : i32, !llvm.ptr
      %527 = vector.extractelement %520[%45 : i32] : vector<4xi32>
      %ptr_278 = cute.add_offset(%ptr_274, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %528 = builtin.unrealized_conversion_cast %ptr_278 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %527, %528 : i32, !llvm.ptr
      %529 = arith.addi %518, %c1_i32 : i32
      cf.br ^bb108(%529 : i32)
    ^bb110:  // pred: ^bb108
      %ptr_279 = cute.add_offset(%iter_249, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%530: i32):  // 2 preds: ^bb110, ^bb112
      %531 = arith.cmpi slt, %530, %149 : i32
      cf.cond_br %531, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_280 = cute.make_coord(%530) : (i32) -> !cute.coord<"(_,?)">
      %idx_281 = cute.crd2idx(%coord_280, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_282 = cute.add_offset(%ptr_279, %idx_281) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_283 = cute.crd2idx(%coord_280, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_284 = cute.add_offset(%ptr_72, %idx_283) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_285 = cute.apply_swizzle(%ptr_282) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %532 = cute_nvgpu.arch.copy.ldsm %swizzled_285{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %533 = vector.extractelement %532[%48 : i32] : vector<4xi32>
      %534 = builtin.unrealized_conversion_cast %ptr_284 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %533, %534 : i32, !llvm.ptr
      %535 = vector.extractelement %532[%47 : i32] : vector<4xi32>
      %ptr_286 = cute.add_offset(%ptr_284, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %536 = builtin.unrealized_conversion_cast %ptr_286 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %535, %536 : i32, !llvm.ptr
      %537 = vector.extractelement %532[%46 : i32] : vector<4xi32>
      %ptr_287 = cute.add_offset(%ptr_284, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %538 = builtin.unrealized_conversion_cast %ptr_287 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %537, %538 : i32, !llvm.ptr
      %539 = vector.extractelement %532[%45 : i32] : vector<4xi32>
      %ptr_288 = cute.add_offset(%ptr_284, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %540 = builtin.unrealized_conversion_cast %ptr_288 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %539, %540 : i32, !llvm.ptr
      %541 = arith.addi %530, %c1_i32 : i32
      cf.br ^bb111(%541 : i32)
    ^bb113:  // pred: ^bb111
      cf.br ^bb114(%c0_i32 : i32)
    ^bb114(%542: i32):  // 2 preds: ^bb113, ^bb121
      %543 = arith.cmpi slt, %542, %153 : i32
      cf.cond_br %543, ^bb115, ^bb122 {llvm.loop_annotation = #loop_annotation}
    ^bb115:  // pred: ^bb114
      cf.br ^bb116(%c0_i32 : i32)
    ^bb116(%544: i32):  // 2 preds: ^bb115, ^bb120
      %545 = arith.cmpi slt, %544, %149 : i32
      cf.cond_br %545, ^bb117, ^bb121 {llvm.loop_annotation = #loop_annotation}
    ^bb117:  // pred: ^bb116
      %coord_289 = cute.make_coord(%544, %542) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_290 = cute.crd2idx(%coord_289, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_291 = cute.add_offset(%ptr_68, %idx_290) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %546 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %547 = llvm.getelementptr %546[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %548 = llvm.getelementptr %546[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %549 = llvm.getelementptr %546[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%550: i32):  // 2 preds: ^bb117, ^bb119
      %551 = arith.cmpi slt, %550, %154 : i32
      cf.cond_br %551, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_292 = cute.make_coord(%550, %542) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_293 = cute.make_coord(%544, %550) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_294 = cute.crd2idx(%coord_292, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_295 = cute.add_offset(%ptr_69, %idx_294) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_296 = cute.crd2idx(%coord_293, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_297 = cute.add_offset(%iter_70, %idx_296) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %552 = llvm.load %546 : !llvm.ptr -> vector<2xf16>
      %553 = llvm.load %547 : !llvm.ptr -> vector<2xf16>
      %554 = llvm.load %548 : !llvm.ptr -> vector<2xf16>
      %555 = llvm.load %549 : !llvm.ptr -> vector<2xf16>
      %556 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %557 = llvm.load %556 : !llvm.ptr -> vector<2xf16>
      %558 = llvm.getelementptr %556[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %559 = llvm.load %558 : !llvm.ptr -> vector<2xf16>
      %560 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %561 = llvm.load %560 : !llvm.ptr -> f32
      %562 = llvm.getelementptr %560[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %563 = llvm.load %562 : !llvm.ptr -> f32
      %564 = llvm.getelementptr %560[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %565 = llvm.load %564 : !llvm.ptr -> f32
      %566 = llvm.getelementptr %560[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %567 = llvm.load %566 : !llvm.ptr -> f32
      %568:4 = cute_nvgpu.arch.mma.SM80 A[%552, %553, %554, %555]  B[%557, %559]  C[%561, %563, %565, %567] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %568#0, %560 : f32, !llvm.ptr
      llvm.store %568#1, %562 : f32, !llvm.ptr
      llvm.store %568#2, %564 : f32, !llvm.ptr
      llvm.store %568#3, %566 : f32, !llvm.ptr
      %569 = arith.addi %550, %c1_i32 : i32
      cf.br ^bb118(%569 : i32)
    ^bb120:  // pred: ^bb118
      %570 = arith.addi %544, %c1_i32 : i32
      cf.br ^bb116(%570 : i32)
    ^bb121:  // pred: ^bb116
      %571 = arith.addi %542, %c1_i32 : i32
      cf.br ^bb114(%571 : i32)
    ^bb122:  // pred: ^bb114
      %ptr_298 = cute.add_offset(%iter_238, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb123(%c0_i32 : i32)
    ^bb123(%572: i32):  // 2 preds: ^bb122, ^bb124
      %573 = arith.cmpi slt, %572, %149 : i32
      cf.cond_br %573, ^bb124, ^bb125 {llvm.loop_annotation = #loop_annotation}
    ^bb124:  // pred: ^bb123
      %coord_299 = cute.make_coord(%572) : (i32) -> !cute.coord<"(_,?)">
      %idx_300 = cute.crd2idx(%coord_299, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_301 = cute.add_offset(%ptr_298, %idx_300) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_302 = cute.crd2idx(%coord_299, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_303 = cute.add_offset(%ptr_73, %idx_302) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_304 = cute.apply_swizzle(%ptr_301) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %574 = cute_nvgpu.arch.copy.ldsm %swizzled_304{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %575 = vector.extractelement %574[%48 : i32] : vector<4xi32>
      %576 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %575, %576 : i32, !llvm.ptr
      %577 = vector.extractelement %574[%47 : i32] : vector<4xi32>
      %ptr_305 = cute.add_offset(%ptr_303, %60) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %578 = builtin.unrealized_conversion_cast %ptr_305 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %577, %578 : i32, !llvm.ptr
      %579 = vector.extractelement %574[%46 : i32] : vector<4xi32>
      %ptr_306 = cute.add_offset(%ptr_303, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %580 = builtin.unrealized_conversion_cast %ptr_306 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %579, %580 : i32, !llvm.ptr
      %581 = vector.extractelement %574[%45 : i32] : vector<4xi32>
      %ptr_307 = cute.add_offset(%ptr_303, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %582 = builtin.unrealized_conversion_cast %ptr_307 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %581, %582 : i32, !llvm.ptr
      %583 = arith.addi %572, %c1_i32 : i32
      cf.br ^bb123(%583 : i32)
    ^bb125:  // pred: ^bb123
      %ptr_308 = cute.add_offset(%iter_249, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb126(%c0_i32 : i32)
    ^bb126(%584: i32):  // 2 preds: ^bb125, ^bb127
      %585 = arith.cmpi slt, %584, %149 : i32
      cf.cond_br %585, ^bb127, ^bb128 {llvm.loop_annotation = #loop_annotation}
    ^bb127:  // pred: ^bb126
      %coord_309 = cute.make_coord(%584) : (i32) -> !cute.coord<"(_,?)">
      %idx_310 = cute.crd2idx(%coord_309, %50) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_311 = cute.add_offset(%ptr_308, %idx_310) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_312 = cute.crd2idx(%coord_309, %49) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_313 = cute.add_offset(%ptr_74, %idx_312) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_314 = cute.apply_swizzle(%ptr_311) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %586 = cute_nvgpu.arch.copy.ldsm %swizzled_314{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %587 = vector.extractelement %586[%48 : i32] : vector<4xi32>
      %588 = builtin.unrealized_conversion_cast %ptr_313 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %587, %588 : i32, !llvm.ptr
      %589 = vector.extractelement %586[%47 : i32] : vector<4xi32>
      %ptr_315 = cute.add_offset(%ptr_313, %60) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %590 = builtin.unrealized_conversion_cast %ptr_315 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %589, %590 : i32, !llvm.ptr
      %591 = vector.extractelement %586[%46 : i32] : vector<4xi32>
      %ptr_316 = cute.add_offset(%ptr_313, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %592 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %591, %592 : i32, !llvm.ptr
      %593 = vector.extractelement %586[%45 : i32] : vector<4xi32>
      %ptr_317 = cute.add_offset(%ptr_313, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %594 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %593, %594 : i32, !llvm.ptr
      %595 = arith.addi %584, %c1_i32 : i32
      cf.br ^bb126(%595 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%c0_i32 : i32)
    ^bb129(%596: i32):  // 2 preds: ^bb128, ^bb136
      %597 = arith.cmpi slt, %596, %153 : i32
      cf.cond_br %597, ^bb130, ^bb137 {llvm.loop_annotation = #loop_annotation}
    ^bb130:  // pred: ^bb129
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%598: i32):  // 2 preds: ^bb130, ^bb135
      %599 = arith.cmpi slt, %598, %149 : i32
      cf.cond_br %599, ^bb132, ^bb136 {llvm.loop_annotation = #loop_annotation}
    ^bb132:  // pred: ^bb131
      %coord_318 = cute.make_coord(%598, %596) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_319 = cute.crd2idx(%coord_318, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_320 = cute.add_offset(%ptr_71, %idx_319) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %600 = builtin.unrealized_conversion_cast %ptr_320 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %601 = llvm.getelementptr %600[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %602 = llvm.getelementptr %600[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %603 = llvm.getelementptr %600[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%604: i32):  // 2 preds: ^bb132, ^bb134
      %605 = arith.cmpi slt, %604, %154 : i32
      cf.cond_br %605, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      %coord_321 = cute.make_coord(%604, %596) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_322 = cute.make_coord(%598, %604) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_323 = cute.crd2idx(%coord_321, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_324 = cute.add_offset(%ptr_72, %idx_323) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_325 = cute.crd2idx(%coord_322, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_326 = cute.add_offset(%iter_70, %idx_325) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %606 = llvm.load %600 : !llvm.ptr -> vector<2xf16>
      %607 = llvm.load %601 : !llvm.ptr -> vector<2xf16>
      %608 = llvm.load %602 : !llvm.ptr -> vector<2xf16>
      %609 = llvm.load %603 : !llvm.ptr -> vector<2xf16>
      %610 = builtin.unrealized_conversion_cast %ptr_324 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %611 = llvm.load %610 : !llvm.ptr -> vector<2xf16>
      %612 = llvm.getelementptr %610[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %613 = llvm.load %612 : !llvm.ptr -> vector<2xf16>
      %614 = builtin.unrealized_conversion_cast %ptr_326 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %615 = llvm.load %614 : !llvm.ptr -> f32
      %616 = llvm.getelementptr %614[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %617 = llvm.load %616 : !llvm.ptr -> f32
      %618 = llvm.getelementptr %614[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %619 = llvm.load %618 : !llvm.ptr -> f32
      %620 = llvm.getelementptr %614[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %621 = llvm.load %620 : !llvm.ptr -> f32
      %622:4 = cute_nvgpu.arch.mma.SM80 A[%606, %607, %608, %609]  B[%611, %613]  C[%615, %617, %619, %621] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %622#0, %614 : f32, !llvm.ptr
      llvm.store %622#1, %616 : f32, !llvm.ptr
      llvm.store %622#2, %618 : f32, !llvm.ptr
      llvm.store %622#3, %620 : f32, !llvm.ptr
      %623 = arith.addi %604, %c1_i32 : i32
      cf.br ^bb133(%623 : i32)
    ^bb135:  // pred: ^bb133
      %624 = arith.addi %598, %c1_i32 : i32
      cf.br ^bb131(%624 : i32)
    ^bb136:  // pred: ^bb131
      %625 = arith.addi %596, %c1_i32 : i32
      cf.br ^bb129(%625 : i32)
    ^bb137:  // pred: ^bb129
      cf.cond_br %91, ^bb138, ^bb139
    ^bb138:  // pred: ^bb137
      %int_tuple_327 = cute.make_int_tuple(%227) : (i32) -> !cute.int_tuple<"?">
      %ptr_328 = cute.add_offset(%ptr_6, %int_tuple_327) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %626 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %626, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb139
    ^bb139:  // 2 preds: ^bb137, ^bb138
      %627 = arith.addi %227, %c1_i32 : i32
      %628 = arith.cmpi eq, %627, %c4_i32 : i32
      %629 = arith.select %628, %c0_i32, %627 : i32
      cf.cond_br %628, ^bb140, ^bb141
    ^bb140:  // pred: ^bb139
      %630 = arith.xori %228, %c1_i32 : i32
      cf.br ^bb142(%630 : i32)
    ^bb141:  // pred: ^bb139
      cf.br ^bb142(%228 : i32)
    ^bb142(%631: i32):  // 2 preds: ^bb140, ^bb141
      cf.br ^bb143
    ^bb143:  // pred: ^bb142
      cf.br ^bb144(%c0_i32 : i32)
    ^bb144(%632: i32):  // 2 preds: ^bb143, ^bb151
      %633 = arith.cmpi slt, %632, %153 : i32
      cf.cond_br %633, ^bb145, ^bb152 {llvm.loop_annotation = #loop_annotation}
    ^bb145:  // pred: ^bb144
      cf.br ^bb146(%c0_i32 : i32)
    ^bb146(%634: i32):  // 2 preds: ^bb145, ^bb150
      %635 = arith.cmpi slt, %634, %149 : i32
      cf.cond_br %635, ^bb147, ^bb151 {llvm.loop_annotation = #loop_annotation}
    ^bb147:  // pred: ^bb146
      %coord_329 = cute.make_coord(%634, %632) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_330 = cute.crd2idx(%coord_329, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_331 = cute.add_offset(%ptr_73, %idx_330) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %636 = builtin.unrealized_conversion_cast %ptr_331 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %637 = llvm.getelementptr %636[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %638 = llvm.getelementptr %636[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %639 = llvm.getelementptr %636[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%640: i32):  // 2 preds: ^bb147, ^bb149
      %641 = arith.cmpi slt, %640, %154 : i32
      cf.cond_br %641, ^bb149, ^bb150 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      %coord_332 = cute.make_coord(%640, %632) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_333 = cute.make_coord(%634, %640) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_334 = cute.crd2idx(%coord_332, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_335 = cute.add_offset(%ptr_74, %idx_334) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_336 = cute.crd2idx(%coord_333, %52) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_337 = cute.add_offset(%iter_70, %idx_336) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %642 = llvm.load %636 : !llvm.ptr -> vector<2xf16>
      %643 = llvm.load %637 : !llvm.ptr -> vector<2xf16>
      %644 = llvm.load %638 : !llvm.ptr -> vector<2xf16>
      %645 = llvm.load %639 : !llvm.ptr -> vector<2xf16>
      %646 = builtin.unrealized_conversion_cast %ptr_335 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %647 = llvm.load %646 : !llvm.ptr -> vector<2xf16>
      %648 = llvm.getelementptr %646[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %649 = llvm.load %648 : !llvm.ptr -> vector<2xf16>
      %650 = builtin.unrealized_conversion_cast %ptr_337 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %651 = llvm.load %650 : !llvm.ptr -> f32
      %652 = llvm.getelementptr %650[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %653 = llvm.load %652 : !llvm.ptr -> f32
      %654 = llvm.getelementptr %650[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %655 = llvm.load %654 : !llvm.ptr -> f32
      %656 = llvm.getelementptr %650[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %657 = llvm.load %656 : !llvm.ptr -> f32
      %658:4 = cute_nvgpu.arch.mma.SM80 A[%642, %643, %644, %645]  B[%647, %649]  C[%651, %653, %655, %657] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %658#0, %650 : f32, !llvm.ptr
      llvm.store %658#1, %652 : f32, !llvm.ptr
      llvm.store %658#2, %654 : f32, !llvm.ptr
      llvm.store %658#3, %656 : f32, !llvm.ptr
      %659 = arith.addi %640, %c1_i32 : i32
      cf.br ^bb148(%659 : i32)
    ^bb150:  // pred: ^bb148
      %660 = arith.addi %634, %c1_i32 : i32
      cf.br ^bb146(%660 : i32)
    ^bb151:  // pred: ^bb146
      %661 = arith.addi %632, %c1_i32 : i32
      cf.br ^bb144(%661 : i32)
    ^bb152:  // pred: ^bb144
      %662 = cute.make_tiled_copy(%atom_75) : !copy_stsm_4_
      %663 = cute.make_tiled_copy(%atom_75) : !copy_stsm_4_1
      %rmem_338 = cute.memref.alloca() : !memref_rmem_f32_2
      %664 = cute.memref.load(%view, %36) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      cute.memref.store(%rmem_338, %36, %664) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %665 = cute.memref.load(%view, %35) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      cute.memref.store(%rmem_338, %35, %665) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %666 = cute.memref.load(%view, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      cute.memref.store(%rmem_338, %34, %666) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %667 = cute.memref.load(%view, %33) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      cute.memref.store(%rmem_338, %33, %667) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %668 = cute.memref.load(%view, %32) : (!memref_rmem_f32_1, !cute.coord<"4">) -> f32
      cute.memref.store(%rmem_338, %32, %668) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %669 = cute.memref.load(%view, %31) : (!memref_rmem_f32_1, !cute.coord<"5">) -> f32
      cute.memref.store(%rmem_338, %31, %669) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %670 = cute.memref.load(%view, %30) : (!memref_rmem_f32_1, !cute.coord<"6">) -> f32
      cute.memref.store(%rmem_338, %30, %670) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %671 = cute.memref.load(%view, %29) : (!memref_rmem_f32_1, !cute.coord<"7">) -> f32
      cute.memref.store(%rmem_338, %29, %671) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %672 = cute.memref.load(%view, %28) : (!memref_rmem_f32_1, !cute.coord<"8">) -> f32
      cute.memref.store(%rmem_338, %28, %672) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %673 = cute.memref.load(%view, %27) : (!memref_rmem_f32_1, !cute.coord<"9">) -> f32
      cute.memref.store(%rmem_338, %27, %673) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %674 = cute.memref.load(%view, %26) : (!memref_rmem_f32_1, !cute.coord<"10">) -> f32
      cute.memref.store(%rmem_338, %26, %674) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %675 = cute.memref.load(%view, %25) : (!memref_rmem_f32_1, !cute.coord<"11">) -> f32
      cute.memref.store(%rmem_338, %25, %675) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %676 = cute.memref.load(%view, %24) : (!memref_rmem_f32_1, !cute.coord<"12">) -> f32
      cute.memref.store(%rmem_338, %24, %676) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %677 = cute.memref.load(%view, %23) : (!memref_rmem_f32_1, !cute.coord<"13">) -> f32
      cute.memref.store(%rmem_338, %23, %677) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %678 = cute.memref.load(%view, %22) : (!memref_rmem_f32_1, !cute.coord<"14">) -> f32
      cute.memref.store(%rmem_338, %22, %678) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %679 = cute.memref.load(%view, %21) : (!memref_rmem_f32_1, !cute.coord<"15">) -> f32
      cute.memref.store(%rmem_338, %21, %679) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_339 = cute.memref.alloca() : !memref_rmem_f16_2
      %iter_340 = cute.get_iter(%rmem_339) : !memref_rmem_f16_2
      %680 = cute.memref.load_vec %rmem_338, row_major : !memref_rmem_f32_2
      %681 = arith.truncf %680 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %681, %rmem_339, row_major : !memref_rmem_f16_2
      cf.br ^bb153(%c0_i32 : i32)
    ^bb153(%682: i32):  // 2 preds: ^bb152, ^bb154
      %683 = arith.cmpi slt, %682, %149 : i32
      cf.cond_br %683, ^bb154, ^bb155 {llvm.loop_annotation = #loop_annotation}
    ^bb154:  // pred: ^bb153
      %coord_341 = cute.make_coord(%682) : (i32) -> !cute.coord<"(_,?)">
      %idx_342 = cute.crd2idx(%coord_341, %20) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_343 = cute.add_offset(%iter_340, %idx_342) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_344 = cute.crd2idx(%coord_341, %19) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_345 = cute.add_offset(%ptr_78, %idx_344) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %684 = builtin.unrealized_conversion_cast %ptr_343 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %685 = llvm.load %684 : !llvm.ptr -> vector<4xi32>
      %swizzled_346 = cute.apply_swizzle(%ptr_345) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_346, %685) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>>, vector<4xi32>
      %686 = arith.addi %682, %c1_i32 : i32
      cf.br ^bb153(%686 : i32)
    ^bb155:  // pred: ^bb153
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %78, ^bb156, ^bb160
    ^bb156:  // pred: ^bb155
      %e0_347, %e1_348, %e2_349 = cute.get_leaves(%tup) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %int_tuple_350 = cute.make_int_tuple(%e0_347, %e1_348, %e2_349) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %687 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%687 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %688:3 = cute.get_scalars(%int_tuple_350) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb157(%c0_i32 : i32)
    ^bb157(%689: i32):  // 2 preds: ^bb156, ^bb158
      %690 = arith.cmpi slt, %689, %153 : i32
      cf.cond_br %690, ^bb158, ^bb159 {llvm.loop_annotation = #loop_annotation}
    ^bb158:  // pred: ^bb157
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_15 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, [%688#0, %688#1, %688#2] : i32, i32, i32) mode = <tiled>
      %691 = arith.addi %689, %c1_i32 : i32
      cf.br ^bb157(%691 : i32)
    ^bb159:  // pred: ^bb157
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 7 {read}
      cf.br ^bb160
    ^bb160:  // 2 preds: ^bb155, ^bb159
      %692 = cute.memref.load(%view, %18) : (!memref_rmem_f32_1, !cute.coord<"16">) -> f32
      cute.memref.store(%rmem_338, %36, %692) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %693 = cute.memref.load(%view, %17) : (!memref_rmem_f32_1, !cute.coord<"17">) -> f32
      cute.memref.store(%rmem_338, %35, %693) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %694 = cute.memref.load(%view, %16) : (!memref_rmem_f32_1, !cute.coord<"18">) -> f32
      cute.memref.store(%rmem_338, %34, %694) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %695 = cute.memref.load(%view, %15) : (!memref_rmem_f32_1, !cute.coord<"19">) -> f32
      cute.memref.store(%rmem_338, %33, %695) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %696 = cute.memref.load(%view, %14) : (!memref_rmem_f32_1, !cute.coord<"20">) -> f32
      cute.memref.store(%rmem_338, %32, %696) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %697 = cute.memref.load(%view, %13) : (!memref_rmem_f32_1, !cute.coord<"21">) -> f32
      cute.memref.store(%rmem_338, %31, %697) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %698 = cute.memref.load(%view, %12) : (!memref_rmem_f32_1, !cute.coord<"22">) -> f32
      cute.memref.store(%rmem_338, %30, %698) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %699 = cute.memref.load(%view, %11) : (!memref_rmem_f32_1, !cute.coord<"23">) -> f32
      cute.memref.store(%rmem_338, %29, %699) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %700 = cute.memref.load(%view, %10) : (!memref_rmem_f32_1, !cute.coord<"24">) -> f32
      cute.memref.store(%rmem_338, %28, %700) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %701 = cute.memref.load(%view, %9) : (!memref_rmem_f32_1, !cute.coord<"25">) -> f32
      cute.memref.store(%rmem_338, %27, %701) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %702 = cute.memref.load(%view, %8) : (!memref_rmem_f32_1, !cute.coord<"26">) -> f32
      cute.memref.store(%rmem_338, %26, %702) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %703 = cute.memref.load(%view, %7) : (!memref_rmem_f32_1, !cute.coord<"27">) -> f32
      cute.memref.store(%rmem_338, %25, %703) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %704 = cute.memref.load(%view, %6) : (!memref_rmem_f32_1, !cute.coord<"28">) -> f32
      cute.memref.store(%rmem_338, %24, %704) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %705 = cute.memref.load(%view, %5) : (!memref_rmem_f32_1, !cute.coord<"29">) -> f32
      cute.memref.store(%rmem_338, %23, %705) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %706 = cute.memref.load(%view, %4) : (!memref_rmem_f32_1, !cute.coord<"30">) -> f32
      cute.memref.store(%rmem_338, %22, %706) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %707 = cute.memref.load(%view, %3) : (!memref_rmem_f32_1, !cute.coord<"31">) -> f32
      cute.memref.store(%rmem_338, %21, %707) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_351 = cute.memref.alloca() : !memref_rmem_f16_2
      %iter_352 = cute.get_iter(%rmem_351) : !memref_rmem_f16_2
      %708 = cute.memref.load_vec %rmem_338, row_major : !memref_rmem_f32_2
      %709 = arith.truncf %708 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %709, %rmem_351, row_major : !memref_rmem_f16_2
      cf.br ^bb161(%c0_i32 : i32)
    ^bb161(%710: i32):  // 2 preds: ^bb160, ^bb162
      %711 = arith.cmpi slt, %710, %149 : i32
      cf.cond_br %711, ^bb162, ^bb163 {llvm.loop_annotation = #loop_annotation}
    ^bb162:  // pred: ^bb161
      %coord_353 = cute.make_coord(%710) : (i32) -> !cute.coord<"(_,?)">
      %idx_354 = cute.crd2idx(%coord_353, %20) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_355 = cute.add_offset(%iter_352, %idx_354) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_356 = cute.crd2idx(%coord_353, %19) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_357 = cute.add_offset(%ptr_79, %idx_356) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %712 = builtin.unrealized_conversion_cast %ptr_355 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %713 = llvm.load %712 : !llvm.ptr -> vector<4xi32>
      %swizzled_358 = cute.apply_swizzle(%ptr_357) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_358, %713) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>>, vector<4xi32>
      %714 = arith.addi %710, %c1_i32 : i32
      cf.br ^bb161(%714 : i32)
    ^bb163:  // pred: ^bb161
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %78, ^bb164, ^bb168
    ^bb164:  // pred: ^bb163
      %ptr_359 = cute.add_offset(%iter_15, %40) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %tup_360 = cute.add_offset(%tup, %2) : (!cute.int_tuple<"(?{div=64},?{div=64},?)">, !cute.int_tuple<"(0,32)">) -> !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %e0_361, %e1_362, %e2_363 = cute.get_leaves(%tup_360) : !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %int_tuple_364 = cute.make_int_tuple(%e0_361, %e1_362, %e2_363) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %715 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>
      %TMADescAddr_365 = cute_nvgpu.get_tma_desc_addr(%715 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %716:3 = cute.get_scalars(%int_tuple_364) : !cute.int_tuple<"(?{div=64},?{div=32},?)">
      cf.br ^bb165(%c0_i32 : i32)
    ^bb165(%717: i32):  // 2 preds: ^bb164, ^bb166
      %718 = arith.cmpi slt, %717, %153 : i32
      cf.cond_br %718, ^bb166, ^bb167 {llvm.loop_annotation = #loop_annotation}
    ^bb166:  // pred: ^bb165
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_365 : !cute.ptr<generic, align<64>>, %ptr_359 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, [%716#0, %716#1, %716#2] : i32, i32, i32) mode = <tiled>
      %719 = arith.addi %717, %c1_i32 : i32
      cf.br ^bb165(%719 : i32)
    ^bb167:  // pred: ^bb165
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 7 {read}
      cf.br ^bb168
    ^bb168:  // 2 preds: ^bb163, ^bb167
      %720 = arith.addi %189, %113 : i32
      %721 = arith.addi %190, %c1_i32 : i32
      %722 = arith.cmpi sgt, %114, %720 : i32
      %723 = cute.get_hier_coord(%720, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_366, %e1_367, %e2_368 = cute.get_leaves(%723) : !cute.coord<"(?,?,?)">
      %itup_369 = cute.to_int_tuple(%e0_366) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_370 = cute.to_int_tuple(%e1_367) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_371 = cute.to_int_tuple(%e2_368) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_372 = cute.tuple_mul(%itup_369, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %724 = cute.get_scalars(%mul_372) : !cute.int_tuple<"?">
      %mul_373 = cute.tuple_mul(%itup_370, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %725 = cute.get_scalars(%mul_373) : !cute.int_tuple<"?">
      %mul_374 = cute.tuple_mul(%itup_371, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %726 = cute.get_scalars(%mul_374) : !cute.int_tuple<"?">
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb8(%724, %725, %726, %722, %629, %631, %720, %721 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb169:  // pred: ^bb8
      cf.br ^bb205
    ^bb170:  // pred: ^bb6
      %727 = arith.cmpi eq, %77, %c4_i32 : i32
      cf.cond_br %727, ^bb171, ^bb204
    ^bb171:  // pred: ^bb170
      nvvm.setmaxregister  decrease 40
      %728:3 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %shape_375 = cute.make_shape(%728#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_376 = cute.make_layout(%shape_375, %1) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">
      %729:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %shape_377 = cute.make_shape(%729#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_378 = cute.make_layout(%shape_377, %1) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">
      %730 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %731 = cute.get_scalars(%61) : !cute.int_tuple<"1">
      %732 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      cf.br ^bb172(%117, %118, %119, %115, %c0_i32, %c1_i32, %109, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb172(%733: i32, %734: i32, %735: i32, %736: i1, %737: i32, %738: i32, %739: i32, %740: i32):  // 2 preds: ^bb171, ^bb188
      cf.cond_br %736, ^bb173(%733, %734, %735, %737, %738, %739, %740 : i32, i32, i32, i32, i32, i32, i32), ^bb189
    ^bb173(%741: i32, %742: i32, %743: i32, %744: i32, %745: i32, %746: i32, %747: i32):  // pred: ^bb172
      %coord_379 = cute.make_coord(%741, %743) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx_380 = cute.crd2idx(%coord_379, %lay_34) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %tup_381 = cute.add_offset(%55, %idx_380) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},0,?)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %coord_382 = cute.make_coord(%742, %743) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx_383 = cute.crd2idx(%coord_382, %lay_38) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %tup_384 = cute.add_offset(%55, %idx_383) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},0,?)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      cf.br ^bb174(%c0_i32, %c0_i32, %744, %745 : i32, i32, i32, i32)
    ^bb174(%748: i32, %749: i32, %750: i32, %751: i32):  // 2 preds: ^bb173, ^bb187
      %752 = arith.cmpi slt, %748, %108 : i32
      cf.cond_br %752, ^bb175, ^bb188 {loop_annotation = #loop_annotation1}
    ^bb175:  // pred: ^bb174
      %int_tuple_385 = cute.make_int_tuple(%750) : (i32) -> !cute.int_tuple<"?">
      %ptr_386 = cute.add_offset(%ptr_6, %int_tuple_385) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %753 = builtin.unrealized_conversion_cast %ptr_386 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %753, %751, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %754 = nvvm.elect.sync -> i1
      cf.cond_br %754, ^bb176, ^bb177
    ^bb176:  // pred: ^bb175
      %ptr_387 = cute.add_offset(%iter, %int_tuple_385) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %755 = builtin.unrealized_conversion_cast %ptr_387 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %755, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb175, ^bb176
      %coord_388 = cute.make_coord(%749) : (i32) -> !cute.coord<"(_,?)">
      %idx_389 = cute.crd2idx(%coord_388, %lay_376) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">) -> !cute.int_tuple<"(0,?{div=64})">
      %tup_390 = cute.add_offset(%tup_381, %idx_389) : (!cute.int_tuple<"(?{div=64},0,?)">, !cute.int_tuple<"(0,?{div=64})">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_391, %e1_392, %e2_393 = cute.get_leaves(%tup_390) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %coord_394 = cute.make_coord(%750) : (i32) -> !cute.coord<"(_,?)">
      %idx_395 = cute.crd2idx(%coord_394, %0) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_396 = cute.add_offset(%iter_13, %idx_395) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_397 = cute.crd2idx(%coord_388, %lay_378) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">) -> !cute.int_tuple<"(0,?{div=64})">
      %tup_398 = cute.add_offset(%tup_384, %idx_397) : (!cute.int_tuple<"(?{div=64},0,?)">, !cute.int_tuple<"(0,?{div=64})">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_399, %e1_400, %e2_401 = cute.get_leaves(%tup_398) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %ptr_402 = cute.add_offset(%iter_14, %idx_395) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_403 = cute.add_offset(%iter, %int_tuple_385) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_404 = cute.make_int_tuple(%e0_391, %e1_392, %e2_393) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %756 = cute_nvgpu.atom.set_value(%730, %ptr_403 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %757 = cute_nvgpu.atom.get_value(%756 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_405 = cute_nvgpu.get_tma_desc_addr(%756 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %758:3 = cute.get_scalars(%int_tuple_404) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb178(%c0_i32 : i32)
    ^bb178(%759: i32):  // 2 preds: ^bb177, ^bb179
      %760 = arith.cmpi slt, %759, %731 : i32
      cf.cond_br %760, ^bb179, ^bb180 {llvm.loop_annotation = #loop_annotation}
    ^bb179:  // pred: ^bb178
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_405 : !cute.ptr<generic, align<64>>, %ptr_396 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %757 : !cute.ptr<smem, align<8>>, [%758#0, %758#1, %758#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %761 = arith.addi %759, %c1_i32 : i32
      cf.br ^bb178(%761 : i32)
    ^bb180:  // pred: ^bb178
      %int_tuple_406 = cute.make_int_tuple(%e0_399, %e1_400, %e2_401) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %762 = cute_nvgpu.atom.set_value(%732, %ptr_403 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %763 = cute_nvgpu.atom.get_value(%762 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_407 = cute_nvgpu.get_tma_desc_addr(%762 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %764:3 = cute.get_scalars(%int_tuple_406) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb181(%c0_i32 : i32)
    ^bb181(%765: i32):  // 2 preds: ^bb180, ^bb182
      %766 = arith.cmpi slt, %765, %731 : i32
      cf.cond_br %766, ^bb182, ^bb183 {llvm.loop_annotation = #loop_annotation}
    ^bb182:  // pred: ^bb181
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_407 : !cute.ptr<generic, align<64>>, %ptr_402 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %763 : !cute.ptr<smem, align<8>>, [%764#0, %764#1, %764#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %767 = arith.addi %765, %c1_i32 : i32
      cf.br ^bb181(%767 : i32)
    ^bb183:  // pred: ^bb181
      %768 = arith.addi %750, %c1_i32 : i32
      %769 = arith.addi %749, %c1_i32 : i32
      %770 = arith.cmpi eq, %768, %c4_i32 : i32
      %771 = arith.select %770, %c0_i32, %768 : i32
      cf.cond_br %770, ^bb184, ^bb185
    ^bb184:  // pred: ^bb183
      %772 = arith.xori %751, %c1_i32 : i32
      cf.br ^bb186(%772 : i32)
    ^bb185:  // pred: ^bb183
      cf.br ^bb186(%751 : i32)
    ^bb186(%773: i32):  // 2 preds: ^bb184, ^bb185
      cf.br ^bb187
    ^bb187:  // pred: ^bb186
      %774 = arith.addi %748, %c1_i32 : i32
      cf.br ^bb174(%774, %769, %771, %773 : i32, i32, i32, i32)
    ^bb188:  // pred: ^bb174
      %775 = arith.addi %746, %113 : i32
      %776 = arith.addi %747, %c1_i32 : i32
      %777 = arith.cmpi sgt, %114, %775 : i32
      %778 = cute.get_hier_coord(%775, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_408, %e1_409, %e2_410 = cute.get_leaves(%778) : !cute.coord<"(?,?,?)">
      %itup_411 = cute.to_int_tuple(%e0_408) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_412 = cute.to_int_tuple(%e1_409) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_413 = cute.to_int_tuple(%e2_410) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_414 = cute.tuple_mul(%itup_411, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %779 = cute.get_scalars(%mul_414) : !cute.int_tuple<"?">
      %mul_415 = cute.tuple_mul(%itup_412, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %780 = cute.get_scalars(%mul_415) : !cute.int_tuple<"?">
      %mul_416 = cute.tuple_mul(%itup_413, %61) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %781 = cute.get_scalars(%mul_416) : !cute.int_tuple<"?">
      cf.br ^bb172(%779, %780, %781, %777, %750, %751, %775, %776 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb189:  // pred: ^bb172
      %782 = arith.addi %737, %c1_i32 : i32
      %783 = arith.cmpi eq, %782, %c4_i32 : i32
      %784 = arith.select %783, %c0_i32, %782 : i32
      cf.cond_br %783, ^bb190, ^bb191
    ^bb190:  // pred: ^bb189
      %785 = arith.xori %738, %c1_i32 : i32
      cf.br ^bb192(%785 : i32)
    ^bb191:  // pred: ^bb189
      cf.br ^bb192(%738 : i32)
    ^bb192(%786: i32):  // 2 preds: ^bb190, ^bb191
      cf.br ^bb193
    ^bb193:  // pred: ^bb192
      %787 = arith.addi %784, %c1_i32 : i32
      %788 = arith.cmpi eq, %787, %c4_i32 : i32
      %789 = arith.select %788, %c0_i32, %787 : i32
      cf.cond_br %788, ^bb194, ^bb195
    ^bb194:  // pred: ^bb193
      %790 = arith.xori %786, %c1_i32 : i32
      cf.br ^bb196(%790 : i32)
    ^bb195:  // pred: ^bb193
      cf.br ^bb196(%786 : i32)
    ^bb196(%791: i32):  // 2 preds: ^bb194, ^bb195
      cf.br ^bb197
    ^bb197:  // pred: ^bb196
      %792 = arith.addi %789, %c1_i32 : i32
      %793 = arith.cmpi eq, %792, %c4_i32 : i32
      %794 = arith.select %793, %c0_i32, %792 : i32
      cf.cond_br %793, ^bb198, ^bb199
    ^bb198:  // pred: ^bb197
      %795 = arith.xori %791, %c1_i32 : i32
      cf.br ^bb200(%795 : i32)
    ^bb199:  // pred: ^bb197
      cf.br ^bb200(%791 : i32)
    ^bb200(%796: i32):  // 2 preds: ^bb198, ^bb199
      cf.br ^bb201
    ^bb201:  // pred: ^bb200
      %int_tuple_417 = cute.make_int_tuple(%794) : (i32) -> !cute.int_tuple<"?">
      %ptr_418 = cute.add_offset(%ptr_6, %int_tuple_417) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %797 = builtin.unrealized_conversion_cast %ptr_418 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %797, %796, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %798 = nvvm.elect.sync -> i1
      cf.cond_br %798, ^bb202, ^bb203
    ^bb202:  // pred: ^bb201
      %ptr_419 = cute.add_offset(%iter, %int_tuple_417) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %799 = builtin.unrealized_conversion_cast %ptr_419 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %799, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb203
    ^bb203:  // 2 preds: ^bb201, ^bb202
      cf.br ^bb204
    ^bb204:  // 2 preds: ^bb170, ^bb203
      cf.br ^bb205
    ^bb205:  // 2 preds: ^bb169, ^bb204
      return
    }
  }
  func.func @cutlass___call_____main__Sm120GemmKernel_object_at__Tensorgmemo1i64i64_Tensorgmemo1i64i64_Tensorgmemo1i64i64_1_CUstream0x0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_, %arg3: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(31 : i64) : i64
    %1 = llvm.mlir.constant(63 : i64) : i64
    %2 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %3 = llvm.mlir.constant(287522 : i64) : i64
    %c99328_i32 = arith.constant 99328 : i32
    %c160 = arith.constant 160 : index
    %c1 = arith.constant 1 : index
    %c1_i32 = arith.constant 1 : i32
    %4 = cute.static : !cute.int_tuple<"1">
    %c64_i64 = arith.constant 64 : i64
    %c64_i32 = arith.constant 64 : i32
    %5 = cute.static : !cute.int_tuple<"(0,0,0)">
    %6 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c32_i64 = arith.constant 32 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4_i64 = arith.constant 4 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c2_i64 = arith.constant 2 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c16_i32 = arith.constant 16 : i32
    %7 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %8:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %9 = arith.extui %8#0 : i32 to i64
    %10 = arith.extui %8#1 : i32 to i64
    %11 = llvm.mul %8#3, %c2_i64 : i64
    %12 = arith.extui %8#2 : i32 to i64
    %13 = llvm.mul %8#4, %c2_i64 : i64
    %14 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<16>> to i64
    %15 = llvm.getelementptr %7[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %15 : i64, !llvm.ptr
    %16 = llvm.getelementptr %7[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %16 : i64, !llvm.ptr
    %17 = llvm.getelementptr %7[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %17 : i64, !llvm.ptr
    %18 = llvm.getelementptr %7[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %18 : i64, !llvm.ptr
    %19 = llvm.getelementptr %7[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %19 : i64, !llvm.ptr
    %20 = llvm.getelementptr %7[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %20 : i64, !llvm.ptr
    %21 = llvm.getelementptr %7[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %7[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %7[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %7[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %7[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %7[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %7[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %7[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %7[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %7[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.udiv %14, %c16_i64 : i64
    %32 = llvm.and %31, %c9007199254740991_i64 : i64
    %33 = llvm.shl %32, %c4_i64 : i64
    llvm.store %33, %15 : i64, !llvm.ptr
    %34 = llvm.sub %10, %c1_i64 : i64
    %35 = llvm.sub %12, %c1_i64 : i64
    %36 = llvm.sub %c1_i64, %c1_i64 : i64
    %37 = llvm.mul %34, %11 : i64
    %38 = llvm.mul %35, %13 : i64
    %39 = llvm.mul %36, %c0_i64 : i64
    %40 = llvm.add %37, %38 : i64
    %41 = llvm.add %39, %39 : i64
    %42 = llvm.mul %9, %c16_i64 : i64
    %43 = llvm.udiv %42, %c8_i64 : i64
    %44 = llvm.add %43, %40 : i64
    %45 = llvm.add %44, %41 : i64
    %46 = llvm.icmp "uge" %45, %c131072_i64 : i64
    %47 = llvm.zext %46 : i1 to i64
    %48 = llvm.shl %47, %c21_i64 : i64
    %49 = llvm.udiv %11, %c16_i64 : i64
    %50 = llvm.shl %49, %c32_i64 : i64
    %51 = llvm.or %c0_i64, %48 : i64
    %52 = llvm.or %51, %50 : i64
    %53 = llvm.or %3, %52 : i64
    llvm.store %53, %16 : i64, !llvm.ptr
    %54 = llvm.udiv %13, %c16_i64 : i64
    %55 = llvm.and %54, %c4294967295_i64 : i64
    %56 = llvm.shl %55, %c0_i64 : i64
    %57 = llvm.udiv %c0_i64, %c16_i64 : i64
    %58 = llvm.shl %57, %c32_i64 : i64
    %59 = llvm.or %56, %58 : i64
    llvm.store %59, %17 : i64, !llvm.ptr
    %60 = llvm.and %57, %c4294967295_i64 : i64
    %61 = llvm.shl %60, %c0_i64 : i64
    %62 = llvm.lshr %11, %c36_i64 : i64
    %63 = llvm.and %62, %c15_i64 : i64
    %64 = llvm.shl %63, %c32_i64 : i64
    %65 = llvm.lshr %13, %c36_i64 : i64
    %66 = llvm.and %65, %c15_i64 : i64
    %67 = llvm.shl %66, %c36_i64 : i64
    %68 = llvm.lshr %c0_i64, %c36_i64 : i64
    %69 = llvm.and %68, %c15_i64 : i64
    %70 = llvm.shl %69, %c40_i64 : i64
    %71 = llvm.shl %68, %c44_i64 : i64
    %72 = llvm.or %64, %67 : i64
    %73 = llvm.or %70, %71 : i64
    %74 = llvm.or %72, %73 : i64
    %75 = llvm.or %61, %74 : i64
    llvm.store %75, %18 : i64, !llvm.ptr
    %76 = llvm.sub %9, %c1_i64 : i64
    %77 = llvm.and %76, %c4294967295_i64 : i64
    %78 = llvm.shl %77, %c0_i64 : i64
    %79 = llvm.shl %34, %c32_i64 : i64
    %80 = llvm.or %78, %79 : i64
    llvm.store %80, %19 : i64, !llvm.ptr
    %81 = llvm.and %35, %c4294967295_i64 : i64
    %82 = llvm.shl %81, %c0_i64 : i64
    %83 = llvm.shl %36, %c32_i64 : i64
    %84 = llvm.or %82, %83 : i64
    llvm.store %84, %20 : i64, !llvm.ptr
    %85 = llvm.and %36, %c4294967295_i64 : i64
    %86 = llvm.or %85, %c0_i64 : i64
    %87 = llvm.or %86, %2 : i64
    llvm.store %87, %21 : i64, !llvm.ptr
    llvm.store %1, %22 : i64, !llvm.ptr
    %88 = builtin.unrealized_conversion_cast %7 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %89 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %90 = llvm.inttoptr %89 : i64 to !llvm.ptr
    %91 = llvm.load %90 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %92 = builtin.unrealized_conversion_cast %91 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %93 = cute_nvgpu.atom.set_value(%atom, %92 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %94 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_0 = cute.make_layout(%94, %6) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view = cute.make_view(%5, %lay_0) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %95 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_1 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %96:5 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %97 = arith.extui %96#0 : i32 to i64
    %98 = arith.extui %96#1 : i32 to i64
    %99 = llvm.mul %96#3, %c2_i64 : i64
    %100 = arith.extui %96#2 : i32 to i64
    %101 = llvm.mul %96#4, %c2_i64 : i64
    %102 = cute.ptrtoint(%iter_1) : !cute.ptr<f16, gmem, align<16>> to i64
    %103 = llvm.getelementptr %95[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %103 : i64, !llvm.ptr
    %104 = llvm.getelementptr %95[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %104 : i64, !llvm.ptr
    %105 = llvm.getelementptr %95[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %105 : i64, !llvm.ptr
    %106 = llvm.getelementptr %95[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %106 : i64, !llvm.ptr
    %107 = llvm.getelementptr %95[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %107 : i64, !llvm.ptr
    %108 = llvm.getelementptr %95[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %108 : i64, !llvm.ptr
    %109 = llvm.getelementptr %95[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.getelementptr %95[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.getelementptr %95[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %111 : i64, !llvm.ptr
    %112 = llvm.getelementptr %95[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %112 : i64, !llvm.ptr
    %113 = llvm.getelementptr %95[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %113 : i64, !llvm.ptr
    %114 = llvm.getelementptr %95[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %114 : i64, !llvm.ptr
    %115 = llvm.getelementptr %95[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %95[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %95[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %95[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.udiv %102, %c16_i64 : i64
    %120 = llvm.and %119, %c9007199254740991_i64 : i64
    %121 = llvm.shl %120, %c4_i64 : i64
    llvm.store %121, %103 : i64, !llvm.ptr
    %122 = llvm.sub %98, %c1_i64 : i64
    %123 = llvm.sub %100, %c1_i64 : i64
    %124 = llvm.mul %122, %99 : i64
    %125 = llvm.mul %123, %101 : i64
    %126 = llvm.add %124, %125 : i64
    %127 = llvm.mul %97, %c16_i64 : i64
    %128 = llvm.udiv %127, %c8_i64 : i64
    %129 = llvm.add %128, %126 : i64
    %130 = llvm.add %129, %41 : i64
    %131 = llvm.icmp "uge" %130, %c131072_i64 : i64
    %132 = llvm.zext %131 : i1 to i64
    %133 = llvm.shl %132, %c21_i64 : i64
    %134 = llvm.udiv %99, %c16_i64 : i64
    %135 = llvm.shl %134, %c32_i64 : i64
    %136 = llvm.or %c0_i64, %133 : i64
    %137 = llvm.or %136, %135 : i64
    %138 = llvm.or %3, %137 : i64
    llvm.store %138, %104 : i64, !llvm.ptr
    %139 = llvm.udiv %101, %c16_i64 : i64
    %140 = llvm.and %139, %c4294967295_i64 : i64
    %141 = llvm.shl %140, %c0_i64 : i64
    %142 = llvm.or %141, %58 : i64
    llvm.store %142, %105 : i64, !llvm.ptr
    %143 = llvm.lshr %99, %c36_i64 : i64
    %144 = llvm.and %143, %c15_i64 : i64
    %145 = llvm.shl %144, %c32_i64 : i64
    %146 = llvm.lshr %101, %c36_i64 : i64
    %147 = llvm.and %146, %c15_i64 : i64
    %148 = llvm.shl %147, %c36_i64 : i64
    %149 = llvm.or %145, %148 : i64
    %150 = llvm.or %149, %73 : i64
    %151 = llvm.or %61, %150 : i64
    llvm.store %151, %106 : i64, !llvm.ptr
    %152 = llvm.sub %97, %c1_i64 : i64
    %153 = llvm.and %152, %c4294967295_i64 : i64
    %154 = llvm.shl %153, %c0_i64 : i64
    %155 = llvm.shl %122, %c32_i64 : i64
    %156 = llvm.or %154, %155 : i64
    llvm.store %156, %107 : i64, !llvm.ptr
    %157 = llvm.and %123, %c4294967295_i64 : i64
    %158 = llvm.shl %157, %c0_i64 : i64
    %159 = llvm.or %158, %83 : i64
    llvm.store %159, %108 : i64, !llvm.ptr
    llvm.store %87, %109 : i64, !llvm.ptr
    llvm.store %1, %110 : i64, !llvm.ptr
    %160 = builtin.unrealized_conversion_cast %95 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %161 = cute.ptrtoint(%160) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %162 = llvm.inttoptr %161 : i64 to !llvm.ptr
    %163 = llvm.load %162 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %164 = builtin.unrealized_conversion_cast %163 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %165 = cute_nvgpu.atom.set_value(%atom, %164 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %166 = cute.get_shape(%lay_2) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_3 = cute.make_layout(%166, %6) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_4 = cute.make_view(%5, %lay_3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %167 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_5 = cute.get_iter(%arg2) : !memref_gmem_f16_
    %lay_6 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %168:5 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %169 = arith.extui %168#0 : i32 to i64
    %170 = arith.extui %168#1 : i32 to i64
    %171 = llvm.mul %168#3, %c2_i64 : i64
    %172 = arith.extui %168#2 : i32 to i64
    %173 = llvm.mul %168#4, %c2_i64 : i64
    %174 = cute.ptrtoint(%iter_5) : !cute.ptr<f16, gmem, align<16>> to i64
    %175 = llvm.getelementptr %167[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %175 : i64, !llvm.ptr
    %176 = llvm.getelementptr %167[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %176 : i64, !llvm.ptr
    %177 = llvm.getelementptr %167[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %177 : i64, !llvm.ptr
    %178 = llvm.getelementptr %167[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %178 : i64, !llvm.ptr
    %179 = llvm.getelementptr %167[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %179 : i64, !llvm.ptr
    %180 = llvm.getelementptr %167[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %180 : i64, !llvm.ptr
    %181 = llvm.getelementptr %167[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %181 : i64, !llvm.ptr
    %182 = llvm.getelementptr %167[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %167[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %167[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %167[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %167[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %167[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %167[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %167[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %167[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.udiv %174, %c16_i64 : i64
    %192 = llvm.and %191, %c9007199254740991_i64 : i64
    %193 = llvm.shl %192, %c4_i64 : i64
    llvm.store %193, %175 : i64, !llvm.ptr
    %194 = llvm.sub %170, %c1_i64 : i64
    %195 = llvm.sub %172, %c1_i64 : i64
    %196 = llvm.mul %194, %171 : i64
    %197 = llvm.mul %195, %173 : i64
    %198 = llvm.add %196, %197 : i64
    %199 = llvm.mul %169, %c16_i64 : i64
    %200 = llvm.udiv %199, %c8_i64 : i64
    %201 = llvm.add %200, %198 : i64
    %202 = llvm.add %201, %41 : i64
    %203 = llvm.icmp "uge" %202, %c131072_i64 : i64
    %204 = llvm.zext %203 : i1 to i64
    %205 = llvm.shl %204, %c21_i64 : i64
    %206 = llvm.udiv %171, %c16_i64 : i64
    %207 = llvm.shl %206, %c32_i64 : i64
    %208 = llvm.or %c0_i64, %205 : i64
    %209 = llvm.or %208, %207 : i64
    %210 = llvm.or %3, %209 : i64
    llvm.store %210, %176 : i64, !llvm.ptr
    %211 = llvm.udiv %173, %c16_i64 : i64
    %212 = llvm.and %211, %c4294967295_i64 : i64
    %213 = llvm.shl %212, %c0_i64 : i64
    %214 = llvm.or %213, %58 : i64
    llvm.store %214, %177 : i64, !llvm.ptr
    %215 = llvm.lshr %171, %c36_i64 : i64
    %216 = llvm.and %215, %c15_i64 : i64
    %217 = llvm.shl %216, %c32_i64 : i64
    %218 = llvm.lshr %173, %c36_i64 : i64
    %219 = llvm.and %218, %c15_i64 : i64
    %220 = llvm.shl %219, %c36_i64 : i64
    %221 = llvm.or %217, %220 : i64
    %222 = llvm.or %221, %73 : i64
    %223 = llvm.or %61, %222 : i64
    llvm.store %223, %178 : i64, !llvm.ptr
    %224 = llvm.sub %169, %c1_i64 : i64
    %225 = llvm.and %224, %c4294967295_i64 : i64
    %226 = llvm.shl %225, %c0_i64 : i64
    %227 = llvm.shl %194, %c32_i64 : i64
    %228 = llvm.or %226, %227 : i64
    llvm.store %228, %179 : i64, !llvm.ptr
    %229 = llvm.and %195, %c4294967295_i64 : i64
    %230 = llvm.shl %229, %c0_i64 : i64
    %231 = llvm.or %230, %83 : i64
    llvm.store %231, %180 : i64, !llvm.ptr
    llvm.store %87, %181 : i64, !llvm.ptr
    llvm.store %0, %182 : i64, !llvm.ptr
    %232 = builtin.unrealized_conversion_cast %167 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %233 = cute.ptrtoint(%232) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %234 = llvm.inttoptr %233 : i64 to !llvm.ptr
    %235 = llvm.load %234 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %236 = builtin.unrealized_conversion_cast %235 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_7 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %237 = cute_nvgpu.atom.set_value(%atom_7, %236 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %238 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_8 = cute.make_layout(%238, %6) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_9 = cute.make_view(%5, %lay_8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %239 = arith.ceildivsi %168#0, %c64_i32 : i32
    %240 = arith.ceildivsi %168#1, %c64_i32 : i32
    %241 = arith.muli %168#3, %c64_i64 : i64
    %shape = cute.make_shape(%239, %240, %168#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
    %iv = cute.assume(%241) : (i64) -> !cute.i64<divby 64>
    %stride = cute.make_stride(%168#3, %iv, %168#4) : (i64, !cute.i64<divby 64>, i64) -> !cute.stride<"((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %lay_10 = cute.make_layout(%shape, %stride) : !cute.layout<"((64,64),(?,?,?)):((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %242:6 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %shape_11 = cute.make_shape(%242#0, %242#1, %242#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_12 = cute.assume(%242#4) : (i64) -> !cute.i64<divby 64>
    %stride_13 = cute.make_stride(%iv_12, %242#5) : (!cute.i64<divby 64>, i64) -> !cute.stride<"(64,?{i64 div=64},?{i64})">
    %lay_14 = cute.make_layout(%shape_11, %stride_13) : !cute.layout<"(?,?,?):(64,?{i64 div=64},?{i64})">
    %243 = cute.get_shape(%lay_14) : (!cute.layout<"(?,?,?):(64,?{i64 div=64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%243) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %244 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %245 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %246 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_15, %itup_16) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %247:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_17 = cute.make_int_tuple(%247#0, %247#1, %247#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_18, %e1_19, %e2_20 = cute.get_leaves(%int_tuple_17) : !cute.int_tuple<"(?,?,?)">
    %shape_21 = cute.make_shape(%e0_18, %e1_19, %e2_20) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_22 = cute.make_layout(%shape_21) : !cute.layout<"(?,?,?):(1,?,?)">
    %248 = cute.get_shape(%lay_22) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.shape<"(?,?,?)">
    %e0_23, %e1_24, %e2_25 = cute.get_leaves(%248) : !cute.shape<"(?,?,?)">
    %itup_26 = cute.to_int_tuple(%e0_23) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_27 = cute.to_int_tuple(%e1_24) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_28 = cute.make_int_tuple(%itup_26) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_28) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_29 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%e0_29, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %int_tuple_30 = cute.make_int_tuple(%itup_27) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_31 = cute.size(%int_tuple_30) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_32 = cute.get_leaves(%sz_31) : !cute.int_tuple<"?">
    %mul_33 = cute.tuple_mul(%e0_32, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %itup_34 = cute.to_int_tuple(%e2_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_35 = cute.make_int_tuple(%mul, %mul_33, %itup_34) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %sz_36 = cute.size(%int_tuple_35) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
    %e0_37 = cute.get_leaves(%sz_36) : !cute.int_tuple<"?">
    %249 = cute.get_scalars(%e0_37) : !cute.int_tuple<"?">
    %250 = arith.minsi %249, %c1_i32 : i32
    %251 = arith.index_cast %250 : i32 to index
    %252 = gpu.launch_func async [%arg3] @kernels::@kernel_cutlass_kernel___main__Sm120GemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutDst1409601_Valuetypef16_tensor000o101112_CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutD_0 clusters in (%c1, %c1, %c1) blocks in (%c1, %c1, %251) threads in (%c160, %c1, %c1)  dynamic_shared_memory_size %c99328_i32 args(%93 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %165 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %view_4 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %237 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %view_9 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %244 : i32, %245 : i32, %246 : i32) {use_pdl = false}
    return
  }
}
