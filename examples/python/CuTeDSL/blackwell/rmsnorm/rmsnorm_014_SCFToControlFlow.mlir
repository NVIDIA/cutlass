!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_1, %arg2: !memref_gmem_bf16_, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %cst = arith.constant 4.096000e+03 : f32
      %c32_i32 = arith.constant 32 : i32
      %c4_i32 = arith.constant 4 : i32
      %c31_i32 = arith.constant 31 : i32
      %c16_i32 = arith.constant 16 : i32
      %c-1_i32 = arith.constant -1 : i32
      %cst_0 = arith.constant 0.000000e+00 : f32
      %0 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %1 = cute.static : !cute.layout<"(8,(8)):(1,(512))">
      %2 = cute.static : !cute.int_tuple<"56">
      %3 = cute.static : !cute.int_tuple<"48">
      %4 = cute.static : !cute.int_tuple<"40">
      %5 = cute.static : !cute.int_tuple<"32">
      %6 = cute.static : !cute.int_tuple<"24">
      %7 = cute.static : !cute.int_tuple<"16">
      %8 = cute.static : !cute.int_tuple<"8">
      %9 = llvm.mlir.constant(0 : i8) : i8
      %10 = cute.static : !cute.int_tuple<"7">
      %11 = cute.static : !cute.int_tuple<"3584">
      %12 = cute.static : !cute.int_tuple<"6">
      %13 = cute.static : !cute.int_tuple<"3072">
      %14 = cute.static : !cute.int_tuple<"5">
      %15 = cute.static : !cute.int_tuple<"2560">
      %16 = cute.static : !cute.int_tuple<"4">
      %17 = cute.static : !cute.int_tuple<"2048">
      %18 = cute.static : !cute.int_tuple<"3">
      %19 = cute.static : !cute.int_tuple<"1536">
      %20 = cute.static : !cute.int_tuple<"2">
      %21 = cute.static : !cute.int_tuple<"1024">
      %22 = cute.static : !cute.int_tuple<"512">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %23 = cute.static : !cute.int_tuple<"1">
      %24 = cute.static : !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %25 = cute.static : !cute.coord<"(7,0,0)">
      %26 = cute.static : !cute.int_tuple<"(0,3584)">
      %27 = cute.static : !cute.coord<"(6,0,0)">
      %28 = cute.static : !cute.int_tuple<"(0,3072)">
      %29 = cute.static : !cute.coord<"(5,0,0)">
      %30 = cute.static : !cute.int_tuple<"(0,2560)">
      %31 = cute.static : !cute.coord<"(4,0,0)">
      %32 = cute.static : !cute.int_tuple<"(0,2048)">
      %33 = cute.static : !cute.coord<"(3,0,0)">
      %34 = cute.static : !cute.int_tuple<"(0,1536)">
      %35 = cute.static : !cute.coord<"(2,0,0)">
      %36 = cute.static : !cute.int_tuple<"(0,1024)">
      %37 = cute.static : !cute.coord<"(1,0,0)">
      %38 = cute.static : !cute.int_tuple<"(0,512)">
      %39 = cute.static : !cute.coord<"(0,0,0)">
      %40 = cute.static : !cute.coord<"4096">
      %c4096_i32 = arith.constant 4096 : i32
      %c8_i32 = arith.constant 8 : i32
      %c64_i32 = arith.constant 64 : i32
      %41 = cute.static : !cute.stride<"((1@0,1@1),(2@0,0))">
      %42 = cute.static : !cute.stride<"((4096,1),(8192,0))">
      %c2_i32 = arith.constant 2 : i32
      %43 = cute.static : !cute.stride<"(1@0,1@1)">
      %44 = cute.static : !cute.int_tuple<"(0,0)">
      %45 = cute.static : !cute.layout<"(2,2):(1,2)">
      %46 = cute.static : !cute.int_tuple<"16384">
      %iter = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %47 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %48 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %49 = cute.get_shape(%lay) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0, %e1 = cute.get_leaves(%49) : !cute.shape<"(?,4096)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %50 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %46) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_1 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_2 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view = cute.make_view(%iter_2, %45) : !memref_smem_f32_
      %shape = cute.make_shape(%itup) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %lay_3 = cute.make_layout(%shape, %43) : !cute.layout<"(?,4096):(1@0,1@1)">
      %coord = cute.make_coord(%48) : (i32) -> !cute.coord<"(?,0)">
      %51 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_4 = cute.make_coord(%51) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %52 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %53 = arith.ceildivsi %52, %c2_i32 : i32
      %shape_5 = cute.make_shape(%53) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_6 = cute.make_layout(%shape_5, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx = cute.crd2idx(%coord_4, %lay_6) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_7 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_8 = cute.add_offset(%iter_7, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %lay_9 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %54 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %55 = arith.ceildivsi %54, %c2_i32 : i32
      %shape_10 = cute.make_shape(%55) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_11 = cute.make_layout(%shape_10, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_12 = cute.crd2idx(%coord_4, %lay_11) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_13 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_14 = cute.add_offset(%iter_13, %idx_12) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %56 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %57 = arith.ceildivsi %56, %c2_i32 : i32
      %shape_15 = cute.make_shape(%57) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_16 = cute.make_layout(%shape_15, %41) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_17 = cute.crd2idx(%coord_4, %lay_16) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %tup = cute.add_offset(%44, %idx_17) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_18 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %58 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %59 = cute.make_tiled_copy(%atom_18) : !copy_simt
      %60 = cute.make_tiled_copy(%atom_18) : !copy_simt
      %coord_19 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %61 = cute.get_scalars(%coord_19) <{only_dynamic}> : !cute.coord<"?">
      %62 = arith.divsi %61, %c64_i32 : i32
      %63 = arith.remsi %61, %c64_i32 : i32
      %64 = arith.muli %63, %c8_i32 : i32
      %65 = arith.muli %62, %c4096_i32 : i32
      %66 = arith.addi %64, %65 : i32
      %iv = cute.assume(%66) : (i32) -> !cute.i32<divby 8>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_20 = cute.add_offset(%ptr_8, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_21 = cute.add_offset(%iter_1, %int_tuple) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_22 = cute.add_offset(%ptr_14, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_23 = cute.assume(%64) : (i32) -> !cute.i32<divby 8>
      %int_tuple_24 = cute.make_int_tuple(%62, %iv_23) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_25 = cute.add_offset(%tup, %int_tuple_24) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_26 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_27 = cute.get_iter(%rmem_26) : !memref_rmem_bf16_
      %int_tuple_28 = cute.make_int_tuple(%iv_23) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_29 = cute.add_offset(%iter, %int_tuple_28) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %rmem_30 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_31 = cute.get_iter(%rmem_30) : !memref_rmem_bf16_
      %view_32 = cute.make_view(%iter_31) : !memref_rmem_bf16_
      %rmem_33 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_34 = cute.get_iter(%rmem_33) : !memref_rmem_i8_
      %e0_35, %e1_36 = cute.get_leaves(%tup_25) : !cute.int_tuple<"(?,?{div=8})">
      %coord_37 = cute.make_coord(%e1_36) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %67 = cute.get_scalars(%coord_37) : !cute.coord<"?{div=8}">
      %68 = cute.get_scalars(%40) : !cute.coord<"4096">
      %69 = arith.cmpi slt, %67, %68 : i32
      %70 = arith.extui %69 : i1 to i8
      cute.memref.store(%rmem_33, %39, %70) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_38 = cute.add_offset(%tup_25, %38) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_39, %e1_40 = cute.get_leaves(%tup_38) : !cute.int_tuple<"(?,?{div=8})">
      %coord_41 = cute.make_coord(%e1_40) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %71 = cute.get_scalars(%coord_41) : !cute.coord<"?{div=8}">
      %72 = arith.cmpi slt, %71, %68 : i32
      %73 = arith.extui %72 : i1 to i8
      cute.memref.store(%rmem_33, %37, %73) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %tup_42 = cute.add_offset(%tup_25, %36) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_43, %e1_44 = cute.get_leaves(%tup_42) : !cute.int_tuple<"(?,?{div=8})">
      %coord_45 = cute.make_coord(%e1_44) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %74 = cute.get_scalars(%coord_45) : !cute.coord<"?{div=8}">
      %75 = arith.cmpi slt, %74, %68 : i32
      %76 = arith.extui %75 : i1 to i8
      cute.memref.store(%rmem_33, %35, %76) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %tup_46 = cute.add_offset(%tup_25, %34) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_47, %e1_48 = cute.get_leaves(%tup_46) : !cute.int_tuple<"(?,?{div=8})">
      %coord_49 = cute.make_coord(%e1_48) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %77 = cute.get_scalars(%coord_49) : !cute.coord<"?{div=8}">
      %78 = arith.cmpi slt, %77, %68 : i32
      %79 = arith.extui %78 : i1 to i8
      cute.memref.store(%rmem_33, %33, %79) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %tup_50 = cute.add_offset(%tup_25, %32) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_51, %e1_52 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(?,?{div=8})">
      %coord_53 = cute.make_coord(%e1_52) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %80 = cute.get_scalars(%coord_53) : !cute.coord<"?{div=8}">
      %81 = arith.cmpi slt, %80, %68 : i32
      %82 = arith.extui %81 : i1 to i8
      cute.memref.store(%rmem_33, %31, %82) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %tup_54 = cute.add_offset(%tup_25, %30) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_55, %e1_56 = cute.get_leaves(%tup_54) : !cute.int_tuple<"(?,?{div=8})">
      %coord_57 = cute.make_coord(%e1_56) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %83 = cute.get_scalars(%coord_57) : !cute.coord<"?{div=8}">
      %84 = arith.cmpi slt, %83, %68 : i32
      %85 = arith.extui %84 : i1 to i8
      cute.memref.store(%rmem_33, %29, %85) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %tup_58 = cute.add_offset(%tup_25, %28) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_59, %e1_60 = cute.get_leaves(%tup_58) : !cute.int_tuple<"(?,?{div=8})">
      %coord_61 = cute.make_coord(%e1_60) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %86 = cute.get_scalars(%coord_61) : !cute.coord<"?{div=8}">
      %87 = arith.cmpi slt, %86, %68 : i32
      %88 = arith.extui %87 : i1 to i8
      cute.memref.store(%rmem_33, %27, %88) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %tup_62 = cute.add_offset(%tup_25, %26) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_63, %e1_64 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?{div=8})">
      %coord_65 = cute.make_coord(%e1_64) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %89 = cute.get_scalars(%coord_65) : !cute.coord<"?{div=8}">
      %90 = arith.cmpi slt, %89, %68 : i32
      %91 = arith.extui %90 : i1 to i8
      cute.memref.store(%rmem_33, %25, %91) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %92 = cute.get_scalars(%e0_35) : !cute.int_tuple<"?">
      %93 = arith.cmpi slt, %92, %50 : i32
      cf.cond_br %93, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %94 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      %iter_66 = cute.recast_iter(%ptr_20) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_67 = cute.recast_iter(%ptr_21) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_68 = cute.add_offset(%ptr_20, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_69 = cute.add_offset(%ptr_21, %22) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_70 = cute.recast_iter(%ptr_68) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_71 = cute.recast_iter(%ptr_69) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_72 = cute.add_offset(%ptr_20, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_73 = cute.add_offset(%ptr_21, %21) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_74 = cute.recast_iter(%ptr_72) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_75 = cute.recast_iter(%ptr_73) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_76 = cute.add_offset(%ptr_20, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_77 = cute.add_offset(%ptr_21, %19) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_78 = cute.recast_iter(%ptr_76) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_79 = cute.recast_iter(%ptr_77) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_80 = cute.add_offset(%ptr_20, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_81 = cute.add_offset(%ptr_21, %17) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_82 = cute.recast_iter(%ptr_80) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_83 = cute.recast_iter(%ptr_81) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_84 = cute.add_offset(%ptr_20, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_85 = cute.add_offset(%ptr_21, %15) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_86 = cute.recast_iter(%ptr_84) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_87 = cute.recast_iter(%ptr_85) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_88 = cute.add_offset(%ptr_20, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_89 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_90 = cute.recast_iter(%ptr_88) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_91 = cute.recast_iter(%ptr_89) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_92 = cute.add_offset(%ptr_20, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_93 = cute.add_offset(%ptr_21, %11) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_94 = cute.recast_iter(%ptr_92) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_95 = cute.recast_iter(%ptr_93) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%95: i32):  // 2 preds: ^bb1, ^bb3
      %96 = arith.cmpi slt, %95, %94 : i32
      cf.cond_br %96, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_96 = cute.make_coord(%95) : (i32) -> !cute.coord<"(_,?)">
      %idx_97 = cute.crd2idx(%coord_96, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_98 = cute.add_offset(%iter_34, %idx_97) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %97 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<i8, rmem> to !llvm.ptr
      %98 = llvm.load %97 : !llvm.ptr -> i8
      %99 = llvm.trunc %98 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_67 : !cute.ptr<i128, smem>, %iter_66 : !cute.ptr<i128, gmem>, %99 : i1) {cache_mode = <always>}
      %ptr_99 = cute.add_offset(%ptr_98, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %100 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<i8, rmem> to !llvm.ptr
      %101 = llvm.load %100 : !llvm.ptr -> i8
      %102 = llvm.trunc %101 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_71 : !cute.ptr<i128, smem>, %iter_70 : !cute.ptr<i128, gmem>, %102 : i1) {cache_mode = <always>}
      %ptr_100 = cute.add_offset(%ptr_98, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %103 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i8, rmem> to !llvm.ptr
      %104 = llvm.load %103 : !llvm.ptr -> i8
      %105 = llvm.trunc %104 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_75 : !cute.ptr<i128, smem>, %iter_74 : !cute.ptr<i128, gmem>, %105 : i1) {cache_mode = <always>}
      %ptr_101 = cute.add_offset(%ptr_98, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %106 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i8, rmem> to !llvm.ptr
      %107 = llvm.load %106 : !llvm.ptr -> i8
      %108 = llvm.trunc %107 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_79 : !cute.ptr<i128, smem>, %iter_78 : !cute.ptr<i128, gmem>, %108 : i1) {cache_mode = <always>}
      %ptr_102 = cute.add_offset(%ptr_98, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %109 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i8, rmem> to !llvm.ptr
      %110 = llvm.load %109 : !llvm.ptr -> i8
      %111 = llvm.trunc %110 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_83 : !cute.ptr<i128, smem>, %iter_82 : !cute.ptr<i128, gmem>, %111 : i1) {cache_mode = <always>}
      %ptr_103 = cute.add_offset(%ptr_98, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %112 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i8, rmem> to !llvm.ptr
      %113 = llvm.load %112 : !llvm.ptr -> i8
      %114 = llvm.trunc %113 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_87 : !cute.ptr<i128, smem>, %iter_86 : !cute.ptr<i128, gmem>, %114 : i1) {cache_mode = <always>}
      %ptr_104 = cute.add_offset(%ptr_98, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %115 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i8, rmem> to !llvm.ptr
      %116 = llvm.load %115 : !llvm.ptr -> i8
      %117 = llvm.trunc %116 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_91 : !cute.ptr<i128, smem>, %iter_90 : !cute.ptr<i128, gmem>, %117 : i1) {cache_mode = <always>}
      %ptr_105 = cute.add_offset(%ptr_98, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %118 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i8, rmem> to !llvm.ptr
      %119 = llvm.load %118 : !llvm.ptr -> i8
      %120 = llvm.trunc %119 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_95 : !cute.ptr<i128, smem>, %iter_94 : !cute.ptr<i128, gmem>, %120 : i1) {cache_mode = <always>}
      %121 = arith.addi %95, %c1_i32 : i32
      cf.br ^bb2(%121 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb5
    ^bb5:  // 2 preds: ^bb0, ^bb4
      nvvm.cp.async.commit.group
      %rmem_106 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_107 = cute.get_iter(%rmem_106) : !memref_rmem_i8_
      cute.memref.store(%rmem_106, %39, %70) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %37, %73) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %35, %76) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %33, %79) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %31, %82) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %29, %85) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %27, %88) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      cute.memref.store(%rmem_106, %25, %91) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %122 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      cf.br ^bb6(%c0_i32 : i32)
    ^bb6(%123: i32):  // 2 preds: ^bb5, ^bb23
      %124 = arith.cmpi slt, %123, %122 : i32
      cf.cond_br %124, ^bb7, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %coord_108 = cute.make_coord(%123) : (i32) -> !cute.coord<"(_,?)">
      %idx_109 = cute.crd2idx(%coord_108, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_110 = cute.add_offset(%iter_107, %idx_109) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %125 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<i8, rmem> to !llvm.ptr
      %126 = llvm.load %125 : !llvm.ptr -> i8
      %127 = llvm.icmp "ne" %126, %9 : i8
      cf.cond_br %127, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %128 = builtin.unrealized_conversion_cast %ptr_29 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %129 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %130 = llvm.load %128 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %130, %129 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %ptr_111 = cute.add_offset(%ptr_110, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %131 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i8, rmem> to !llvm.ptr
      %132 = llvm.load %131 : !llvm.ptr -> i8
      %133 = llvm.icmp "ne" %132, %9 : i8
      cf.cond_br %133, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %ptr_112 = cute.add_offset(%ptr_29, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_113 = cute.add_offset(%iter_31, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %134 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %135 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %136 = llvm.load %134 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %136, %135 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %ptr_114 = cute.add_offset(%ptr_110, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %137 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i8, rmem> to !llvm.ptr
      %138 = llvm.load %137 : !llvm.ptr -> i8
      %139 = llvm.icmp "ne" %138, %9 : i8
      cf.cond_br %139, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %ptr_115 = cute.add_offset(%ptr_29, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_116 = cute.add_offset(%iter_31, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %140 = builtin.unrealized_conversion_cast %ptr_115 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %141 = builtin.unrealized_conversion_cast %ptr_116 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %142 = llvm.load %140 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %142, %141 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %ptr_117 = cute.add_offset(%ptr_110, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %143 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<i8, rmem> to !llvm.ptr
      %144 = llvm.load %143 : !llvm.ptr -> i8
      %145 = llvm.icmp "ne" %144, %9 : i8
      cf.cond_br %145, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %ptr_118 = cute.add_offset(%ptr_29, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_119 = cute.add_offset(%iter_31, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %146 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %147 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %148 = llvm.load %146 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %148, %147 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %ptr_120 = cute.add_offset(%ptr_110, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %149 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i8, rmem> to !llvm.ptr
      %150 = llvm.load %149 : !llvm.ptr -> i8
      %151 = llvm.icmp "ne" %150, %9 : i8
      cf.cond_br %151, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %ptr_121 = cute.add_offset(%ptr_29, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_122 = cute.add_offset(%iter_31, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %152 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %153 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %154 = llvm.load %152 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %154, %153 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %ptr_123 = cute.add_offset(%ptr_110, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %155 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i8, rmem> to !llvm.ptr
      %156 = llvm.load %155 : !llvm.ptr -> i8
      %157 = llvm.icmp "ne" %156, %9 : i8
      cf.cond_br %157, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %ptr_124 = cute.add_offset(%ptr_29, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_125 = cute.add_offset(%iter_31, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %158 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %159 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %160 = llvm.load %158 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %160, %159 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %ptr_126 = cute.add_offset(%ptr_110, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %161 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem> to !llvm.ptr
      %162 = llvm.load %161 : !llvm.ptr -> i8
      %163 = llvm.icmp "ne" %162, %9 : i8
      cf.cond_br %163, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %ptr_127 = cute.add_offset(%ptr_29, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_128 = cute.add_offset(%iter_31, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %164 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %165 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %166 = llvm.load %164 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %166, %165 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %ptr_129 = cute.add_offset(%ptr_110, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %167 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem> to !llvm.ptr
      %168 = llvm.load %167 : !llvm.ptr -> i8
      %169 = llvm.icmp "ne" %168, %9 : i8
      cf.cond_br %169, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %ptr_130 = cute.add_offset(%ptr_29, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_131 = cute.add_offset(%iter_31, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %170 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %171 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %172 = llvm.load %170 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %172, %171 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %173 = arith.addi %123, %c1_i32 : i32
      cf.br ^bb6(%173 : i32)
    ^bb24:  // pred: ^bb6
      nvvm.cp.async.wait.group 0
      %iter_132 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %174 = cute.get_scalars(%8) : !cute.int_tuple<"8">
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%175: i32):  // 2 preds: ^bb24, ^bb26
      %176 = arith.cmpi slt, %175, %174 : i32
      cf.cond_br %176, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %coord_133 = cute.make_coord(%175) : (i32) -> !cute.coord<"(_,?)">
      %idx_134 = cute.crd2idx(%coord_133, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %ptr_135 = cute.add_offset(%ptr_21, %idx_134) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_136 = cute.crd2idx(%coord_133, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_137 = cute.add_offset(%iter_132, %idx_136) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %177 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %178 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %179 = llvm.load %177 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %179, %178 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %180 = arith.addi %175, %c1_i32 : i32
      cf.br ^bb25(%180 : i32)
    ^bb27:  // pred: ^bb25
      %181 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %182 = arith.extf %181 : vector<64xbf16> to vector<64xf32>
      %183 = arith.mulf %182, %182 : vector<64xf32>
      %184 = vector.reduction <add>, %183, %cst_0 : vector<64xf32> into f32
      %185 = nvvm.shfl.sync  bfly %c-1_i32, %184, %c16_i32, %c31_i32 : f32 -> f32
      %186 = arith.addf %185, %184 : f32
      %187 = nvvm.shfl.sync  bfly %c-1_i32, %186, %c8_i32, %c31_i32 : f32 -> f32
      %188 = arith.addf %186, %187 : f32
      %189 = nvvm.shfl.sync  bfly %c-1_i32, %188, %c4_i32, %c31_i32 : f32 -> f32
      %190 = arith.addf %188, %189 : f32
      %191 = nvvm.shfl.sync  bfly %c-1_i32, %190, %c2_i32, %c31_i32 : f32 -> f32
      %192 = arith.addf %190, %191 : f32
      %193 = nvvm.shfl.sync  bfly %c-1_i32, %192, %c1_i32, %c31_i32 : f32 -> f32
      %194 = arith.addf %192, %193 : f32
      %195 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %196 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %197 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %198 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %199 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %200 = arith.muli %196, %198 : i32
      %201 = arith.addi %47, %200 : i32
      %202 = arith.muli %197, %198 : i32
      %203 = arith.muli %202, %199 : i32
      %204 = arith.addi %201, %203 : i32
      %205 = arith.floordivsi %204, %c32_i32 : i32
      %206 = arith.floordivsi %205, %c2_i32 : i32
      %207 = arith.remsi %205, %c2_i32 : i32
      %208 = arith.cmpi eq, %195, %c0_i32 : i32
      cf.cond_br %208, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %coord_138 = cute.make_coord(%206, %207) : (i32, i32) -> !cute.coord<"(?,?)">
      cute.memref.store(%view, %coord_138, %194) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      cf.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      nvvm.barrier
      %209 = arith.cmpi slt, %195, %c2_i32 : i32
      cf.cond_br %209, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %coord_139 = cute.make_coord(%206, %195) : (i32, i32) -> !cute.coord<"(?,?)">
      %210 = cute.memref.load(%view, %coord_139) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
      cf.br ^bb32(%210 : f32)
    ^bb31:  // pred: ^bb29
      cf.br ^bb32(%cst_0 : f32)
    ^bb32(%211: f32):  // 2 preds: ^bb30, ^bb31
      cf.br ^bb33
    ^bb33:  // pred: ^bb32
      %212 = nvvm.shfl.sync  bfly %c-1_i32, %211, %c16_i32, %c31_i32 : f32 -> f32
      %213 = arith.addf %211, %212 : f32
      %214 = nvvm.shfl.sync  bfly %c-1_i32, %213, %c8_i32, %c31_i32 : f32 -> f32
      %215 = arith.addf %213, %214 : f32
      %216 = nvvm.shfl.sync  bfly %c-1_i32, %215, %c4_i32, %c31_i32 : f32 -> f32
      %217 = arith.addf %215, %216 : f32
      %218 = nvvm.shfl.sync  bfly %c-1_i32, %217, %c2_i32, %c31_i32 : f32 -> f32
      %219 = arith.addf %217, %218 : f32
      %220 = nvvm.shfl.sync  bfly %c-1_i32, %219, %c1_i32, %c31_i32 : f32 -> f32
      %221 = arith.addf %219, %220 : f32
      %222 = arith.divf %221, %cst : f32
      %223 = arith.addf %222, %arg3 : f32
      %224 = math.rsqrt %223 fastmath<fast> : f32
      nvvm.barrier
      cf.br ^bb34(%c0_i32 : i32)
    ^bb34(%225: i32):  // 2 preds: ^bb33, ^bb35
      %226 = arith.cmpi slt, %225, %174 : i32
      cf.cond_br %226, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %coord_140 = cute.make_coord(%225) : (i32) -> !cute.coord<"(_,?)">
      %idx_141 = cute.crd2idx(%coord_140, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %ptr_142 = cute.add_offset(%ptr_21, %idx_141) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_143 = cute.crd2idx(%coord_140, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_144 = cute.add_offset(%iter_132, %idx_143) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %227 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %228 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %229 = llvm.load %227 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %229, %228 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %230 = arith.addi %225, %c1_i32 : i32
      cf.br ^bb34(%230 : i32)
    ^bb36:  // pred: ^bb34
      %231 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %232 = arith.extf %231 : vector<64xbf16> to vector<64xf32>
      %233 = vector.broadcast %224 : f32 to vector<64xf32>
      %234 = arith.mulf %232, %233 : vector<64xf32>
      %235 = cute.memref.load_vec %view_32 : !memref_rmem_bf16_
      %236 = arith.extf %235 : vector<64xbf16> to vector<64xf32>
      %237 = arith.mulf %234, %236 : vector<64xf32>
      %238 = arith.truncf %237 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %238, %rmem_26 : !memref_rmem_bf16_
      cf.cond_br %93, ^bb37, ^bb57
    ^bb37:  // pred: ^bb36
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%239: i32):  // 2 preds: ^bb37, ^bb55
      %240 = arith.cmpi slt, %239, %122 : i32
      cf.cond_br %240, ^bb39, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_145 = cute.make_coord(%239) : (i32) -> !cute.coord<"(_,?)">
      %idx_146 = cute.crd2idx(%coord_145, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_147 = cute.add_offset(%iter_34, %idx_146) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %241 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i8, rmem> to !llvm.ptr
      %242 = llvm.load %241 : !llvm.ptr -> i8
      %243 = llvm.icmp "ne" %242, %9 : i8
      cf.cond_br %243, ^bb40, ^bb41
    ^bb40:  // pred: ^bb39
      %244 = builtin.unrealized_conversion_cast %iter_27 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %245 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %246 = llvm.load %244 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %246, %245 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb41
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %ptr_148 = cute.add_offset(%ptr_147, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %247 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<i8, rmem> to !llvm.ptr
      %248 = llvm.load %247 : !llvm.ptr -> i8
      %249 = llvm.icmp "ne" %248, %9 : i8
      cf.cond_br %249, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %ptr_149 = cute.add_offset(%iter_27, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_150 = cute.add_offset(%ptr_22, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %250 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %251 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %252 = llvm.load %250 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %252, %251 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %ptr_151 = cute.add_offset(%ptr_147, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %253 = builtin.unrealized_conversion_cast %ptr_151 : !cute.ptr<i8, rmem> to !llvm.ptr
      %254 = llvm.load %253 : !llvm.ptr -> i8
      %255 = llvm.icmp "ne" %254, %9 : i8
      cf.cond_br %255, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %ptr_152 = cute.add_offset(%iter_27, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_153 = cute.add_offset(%ptr_22, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %256 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %257 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %258 = llvm.load %256 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %258, %257 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %ptr_154 = cute.add_offset(%ptr_147, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %259 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<i8, rmem> to !llvm.ptr
      %260 = llvm.load %259 : !llvm.ptr -> i8
      %261 = llvm.icmp "ne" %260, %9 : i8
      cf.cond_br %261, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %ptr_155 = cute.add_offset(%iter_27, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_156 = cute.add_offset(%ptr_22, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %262 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %263 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %264 = llvm.load %262 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %264, %263 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %ptr_157 = cute.add_offset(%ptr_147, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %265 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
      %266 = llvm.load %265 : !llvm.ptr -> i8
      %267 = llvm.icmp "ne" %266, %9 : i8
      cf.cond_br %267, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %ptr_158 = cute.add_offset(%iter_27, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_159 = cute.add_offset(%ptr_22, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %268 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %269 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %270 = llvm.load %268 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %270, %269 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %ptr_160 = cute.add_offset(%ptr_147, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %271 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
      %272 = llvm.load %271 : !llvm.ptr -> i8
      %273 = llvm.icmp "ne" %272, %9 : i8
      cf.cond_br %273, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %ptr_161 = cute.add_offset(%iter_27, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_162 = cute.add_offset(%ptr_22, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %274 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %275 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %276 = llvm.load %274 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %276, %275 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %ptr_163 = cute.add_offset(%ptr_147, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %277 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem> to !llvm.ptr
      %278 = llvm.load %277 : !llvm.ptr -> i8
      %279 = llvm.icmp "ne" %278, %9 : i8
      cf.cond_br %279, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %ptr_164 = cute.add_offset(%iter_27, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_165 = cute.add_offset(%ptr_22, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %280 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %281 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %282 = llvm.load %280 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %282, %281 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %ptr_166 = cute.add_offset(%ptr_147, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %283 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem> to !llvm.ptr
      %284 = llvm.load %283 : !llvm.ptr -> i8
      %285 = llvm.icmp "ne" %284, %9 : i8
      cf.cond_br %285, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %ptr_167 = cute.add_offset(%iter_27, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_168 = cute.add_offset(%ptr_22, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %286 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %287 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %288 = llvm.load %286 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %288, %287 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %289 = arith.addi %239, %c1_i32 : i32
      cf.br ^bb38(%289 : i32)
    ^bb56:  // pred: ^bb38
      cf.br ^bb57
    ^bb57:  // 2 preds: ^bb36, ^bb56
      return
    }
  }
  func.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c16400_i64 = arith.constant 16400 : i64
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c2_i32 = arith.constant 2 : i32
    %0 = cute.static : !cute.layout<"(4096):(1)">
    %1 = cute.static : !cute.stride<"(4096,1)">
    %shape = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %lay = cute.make_layout(%shape, %1) : !cute.layout<"(?,4096):(4096,1)">
    %view = cute.make_view(%arg0, %lay) : !memref_gmem_bf16_
    %view_0 = cute.make_view(%arg2, %lay) : !memref_gmem_bf16_
    %view_1 = cute.make_view(%arg1, %0) : !memref_gmem_bf16_1
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %3 = arith.ceildivsi %2, %c2_i32 : i32
    %int_tuple_2 = cute.make_int_tuple(%3) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_2) : !cute.int_tuple<"?">
    %4 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %5 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c16400_i64, gridDim = (%4, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %6 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%5> (%view, %view_1, %view_0, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %7 = cuda.cast %6 : !cuda.result -> i32
    cuda.return_if_error %7 : i32
    return %c0_i32 : i32
  }
}
