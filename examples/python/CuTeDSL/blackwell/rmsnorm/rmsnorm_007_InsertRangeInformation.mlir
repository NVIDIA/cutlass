!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(4096,1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "((2),4096):((0),1)">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(0,1)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_gmem_bf16_7 = !cute.memref<bf16, gmem, align<16>, "((8,8)):((1,512))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((8,8),(1,1)):((1,8),(0,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "((8,8)):((1,8))">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "(8,8):(1,8)">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<16>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8,(1,1)):(1,(0,1))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, "(8):(1)">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "(2,4096):(4096,1)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,8)):((1,512))">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "(8,8):(1,512)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<16>, "(8):(1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_1, %arg2: !memref_gmem_bf16_, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
      %iter = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %1 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %2 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %3 = cute.get_shape(%lay) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %4 = cute.static : !cute.shape<"4096">
      %e0, %e1 = cute.get_leaves(%3) : !cute.shape<"(?,4096)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %6 = cute.static : !cute.layout<"(2,4096):(4096,1)">
      %7 = cute.static : !cute.int_tuple<"16384">
      %ptr = cute.add_offset(%smem_ptr, %7) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_0 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view = cute.make_view(%iter_0, %6) : !memref_smem_bf16_
      %8 = cute.static : !cute.layout<"(2,2):(1,2)">
      %iter_1 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view_2 = cute.make_view(%iter_1, %8) : !memref_smem_f32_
      %shape = cute.make_shape(%itup) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %9 = cute.static : !cute.int_tuple<"(0,0)">
      %10 = cute.static : !cute.stride<"(1@0,1@1)">
      %lay_3 = cute.make_layout(%shape, %10) : !cute.layout<"(?,4096):(1@0,1@1)">
      %view_4 = cute.make_view(%9, %lay_3) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %coord = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,0)">
      %11 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_5 = cute.make_coord(%11) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_6 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %12 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32 = arith.constant 2 : i32
      %13 = arith.ceildivsi %12, %c2_i32 : i32
      %shape_7 = cute.make_shape(%13) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %14 = cute.static : !cute.stride<"((4096,1),(8192,0))">
      %lay_8 = cute.make_layout(%shape_7, %14) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx = cute.crd2idx(%coord_5, %lay_8) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_9 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_10 = cute.add_offset(%iter_9, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_11 = cute.make_view(%ptr_10) : !memref_gmem_bf16_2
      %coord_12 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,0)">
      %15 = cute.get_scalars(%coord_12) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_13 = cute.make_coord(%15) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_14 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %16 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32_15 = arith.constant 2 : i32
      %17 = arith.ceildivsi %16, %c2_i32_15 : i32
      %shape_16 = cute.make_shape(%17) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %18 = cute.static : !cute.stride<"((4096,1),(8192,0))">
      %lay_17 = cute.make_layout(%shape_16, %18) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_18 = cute.crd2idx(%coord_13, %lay_17) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_19 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_20 = cute.add_offset(%iter_19, %idx_18) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_21 = cute.make_view(%ptr_20) : !memref_gmem_bf16_2
      %coord_22 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,0)">
      %19 = cute.get_scalars(%coord_22) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_23 = cute.make_coord(%19) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_24 = cute.get_layout(%view_4) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %20 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %c2_i32_25 = arith.constant 2 : i32
      %21 = arith.ceildivsi %20, %c2_i32_25 : i32
      %shape_26 = cute.make_shape(%21) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %22 = cute.static : !cute.stride<"((1@0,1@1),(2@0,0))">
      %lay_27 = cute.make_layout(%shape_26, %22) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_28 = cute.crd2idx(%coord_23, %lay_27) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %23 = cute.static : !cute.int_tuple<"(0,0)">
      %tup = cute.add_offset(%23, %idx_28) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %view_29 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %24 = cute.static : !cute.layout<"((2),4096):((0),1)">
      %view_30 = cute.make_view(%iter, %24) : !memref_gmem_bf16_3
      %25 = cute.static : !cute.int_tuple<"0">
      %iter_31 = cute.get_iter(%view_30) : !memref_gmem_bf16_3
      %ptr_32 = cute.add_offset(%iter_31, %25) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_33 = cute.make_view(%ptr_32) : !memref_gmem_bf16_4
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_34 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_35 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %26 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %27 = cute.make_tiled_copy(%atom_34) : !copy_simt
      %28 = cute.make_tiled_copy(%atom_35) : !copy_simt
      %coord_36 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_37 = cute.get_iter(%view_11) : !memref_gmem_bf16_2
      %29 = cute.get_scalars(%coord_36) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32 = arith.constant 64 : i32
      %30 = arith.divsi %29, %c64_i32 : i32
      %c64_i32_38 = arith.constant 64 : i32
      %31 = arith.remsi %29, %c64_i32_38 : i32
      %c8_i32 = arith.constant 8 : i32
      %32 = arith.muli %31, %c8_i32 : i32
      %c4096_i32 = arith.constant 4096 : i32
      %33 = arith.muli %30, %c4096_i32 : i32
      %34 = arith.addi %32, %33 : i32
      %iv = cute.assume(%34) : (i32) -> !cute.i32<divby 8>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_39 = cute.add_offset(%iter_37, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_40 = cute.make_view(%ptr_39) : !memref_gmem_bf16_5
      %iter_41 = cute.get_iter(%view_40) : !memref_gmem_bf16_5
      %coord_42 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_43 = cute.get_iter(%view) : !memref_smem_bf16_
      %35 = cute.get_scalars(%coord_42) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_44 = arith.constant 64 : i32
      %36 = arith.divsi %35, %c64_i32_44 : i32
      %c64_i32_45 = arith.constant 64 : i32
      %37 = arith.remsi %35, %c64_i32_45 : i32
      %c8_i32_46 = arith.constant 8 : i32
      %38 = arith.muli %37, %c8_i32_46 : i32
      %c4096_i32_47 = arith.constant 4096 : i32
      %39 = arith.muli %36, %c4096_i32_47 : i32
      %40 = arith.addi %38, %39 : i32
      %iv_48 = cute.assume(%40) : (i32) -> !cute.i32<divby 8>
      %int_tuple_49 = cute.make_int_tuple(%iv_48) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_50 = cute.add_offset(%iter_43, %int_tuple_49) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_51 = cute.make_view(%ptr_50) : !memref_smem_bf16_1
      %iter_52 = cute.get_iter(%view_51) : !memref_smem_bf16_1
      %coord_53 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_54 = cute.get_iter(%view_21) : !memref_gmem_bf16_2
      %41 = cute.get_scalars(%coord_53) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_55 = arith.constant 64 : i32
      %42 = arith.divsi %41, %c64_i32_55 : i32
      %c64_i32_56 = arith.constant 64 : i32
      %43 = arith.remsi %41, %c64_i32_56 : i32
      %c8_i32_57 = arith.constant 8 : i32
      %44 = arith.muli %43, %c8_i32_57 : i32
      %c4096_i32_58 = arith.constant 4096 : i32
      %45 = arith.muli %42, %c4096_i32_58 : i32
      %46 = arith.addi %44, %45 : i32
      %iv_59 = cute.assume(%46) : (i32) -> !cute.i32<divby 8>
      %int_tuple_60 = cute.make_int_tuple(%iv_59) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_61 = cute.add_offset(%iter_54, %int_tuple_60) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_62 = cute.make_view(%ptr_61) : !memref_gmem_bf16_5
      %iter_63 = cute.get_iter(%view_62) : !memref_gmem_bf16_5
      %coord_64 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_65 = cute.get_iter(%view_29) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %47 = cute.get_scalars(%coord_64) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_66 = arith.constant 64 : i32
      %48 = arith.divsi %47, %c64_i32_66 : i32
      %c64_i32_67 = arith.constant 64 : i32
      %49 = arith.remsi %47, %c64_i32_67 : i32
      %c8_i32_68 = arith.constant 8 : i32
      %50 = arith.muli %49, %c8_i32_68 : i32
      %iv_69 = cute.assume(%50) : (i32) -> !cute.i32<divby 8>
      %int_tuple_70 = cute.make_int_tuple(%48, %iv_69) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_71 = cute.add_offset(%iter_65, %int_tuple_70) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_72 = cute.make_view(%tup_71) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %51 = cute.static : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem = cute.memref.alloca(%51) : !memref_rmem_bf16_
      %52 = cute.static : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_73 = cute.memref.alloca(%52) : !memref_rmem_bf16_
      %iter_74 = cute.get_iter(%rmem_73) : !memref_rmem_bf16_
      %coord_75 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_76 = cute.get_iter(%view_33) : !memref_gmem_bf16_4
      %53 = cute.get_scalars(%coord_75) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_77 = arith.constant 64 : i32
      %54 = arith.remsi %53, %c64_i32_77 : i32
      %c8_i32_78 = arith.constant 8 : i32
      %55 = arith.muli %54, %c8_i32_78 : i32
      %iv_79 = cute.assume(%55) : (i32) -> !cute.i32<divby 8>
      %int_tuple_80 = cute.make_int_tuple(%iv_79) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_81 = cute.add_offset(%iter_76, %int_tuple_80) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_82 = cute.make_view(%ptr_81) : !memref_gmem_bf16_5
      %iter_83 = cute.get_iter(%view_82) : !memref_gmem_bf16_5
      %56 = cute.static : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_84 = cute.memref.alloca(%56) : !memref_rmem_bf16_
      %iter_85 = cute.get_iter(%rmem_84) : !memref_rmem_bf16_
      %iter_86 = cute.get_iter(%rmem_84) : !memref_rmem_bf16_
      %view_87 = cute.make_view(%iter_86) : !memref_rmem_bf16_
      %57 = cute.static : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_88 = cute.memref.alloca(%57) : !memref_rmem_i8_
      %iter_89 = cute.get_iter(%rmem_88) : !memref_rmem_i8_
      %58 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_90 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_91 = cute.add_offset(%iter_90, %58) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_92 = cute.make_view(%tup_91) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_93 = cute.get_iter(%view_92) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_94, %e1_95 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(?,?{div=8})">
      %coord_96 = cute.make_coord(%e1_95) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %59 = cute.static : !cute.coord<"4096">
      %60 = cute.get_scalars(%coord_96) : !cute.coord<"?{div=8}">
      %61 = cute.get_scalars(%59) : !cute.coord<"4096">
      %true = arith.constant true
      %62 = arith.cmpi slt, %60, %61 : i32
      %63 = arith.andi %true, %62 : i1
      %64 = arith.extui %63 : i1 to i8
      %65 = cute.static : !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_88, %65, %64) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %66 = cute.static : !cute.int_tuple<"(0,512)">
      %iter_97 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_98 = cute.add_offset(%iter_97, %66) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_99 = cute.make_view(%tup_98) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_100 = cute.get_iter(%view_99) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_101, %e1_102 = cute.get_leaves(%iter_100) : !cute.int_tuple<"(?,?{div=8})">
      %coord_103 = cute.make_coord(%e1_102) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %67 = cute.static : !cute.coord<"4096">
      %68 = cute.get_scalars(%coord_103) : !cute.coord<"?{div=8}">
      %69 = cute.get_scalars(%67) : !cute.coord<"4096">
      %true_104 = arith.constant true
      %70 = arith.cmpi slt, %68, %69 : i32
      %71 = arith.andi %true_104, %70 : i1
      %72 = arith.extui %71 : i1 to i8
      %73 = cute.static : !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_88, %73, %72) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %74 = cute.static : !cute.int_tuple<"(0,1024)">
      %iter_105 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_106 = cute.add_offset(%iter_105, %74) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_107 = cute.make_view(%tup_106) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_108 = cute.get_iter(%view_107) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_109, %e1_110 = cute.get_leaves(%iter_108) : !cute.int_tuple<"(?,?{div=8})">
      %coord_111 = cute.make_coord(%e1_110) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %75 = cute.static : !cute.coord<"4096">
      %76 = cute.get_scalars(%coord_111) : !cute.coord<"?{div=8}">
      %77 = cute.get_scalars(%75) : !cute.coord<"4096">
      %true_112 = arith.constant true
      %78 = arith.cmpi slt, %76, %77 : i32
      %79 = arith.andi %true_112, %78 : i1
      %80 = arith.extui %79 : i1 to i8
      %81 = cute.static : !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_88, %81, %80) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %82 = cute.static : !cute.int_tuple<"(0,1536)">
      %iter_113 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_114 = cute.add_offset(%iter_113, %82) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_115 = cute.make_view(%tup_114) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_116 = cute.get_iter(%view_115) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_117, %e1_118 = cute.get_leaves(%iter_116) : !cute.int_tuple<"(?,?{div=8})">
      %coord_119 = cute.make_coord(%e1_118) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %83 = cute.static : !cute.coord<"4096">
      %84 = cute.get_scalars(%coord_119) : !cute.coord<"?{div=8}">
      %85 = cute.get_scalars(%83) : !cute.coord<"4096">
      %true_120 = arith.constant true
      %86 = arith.cmpi slt, %84, %85 : i32
      %87 = arith.andi %true_120, %86 : i1
      %88 = arith.extui %87 : i1 to i8
      %89 = cute.static : !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_88, %89, %88) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %90 = cute.static : !cute.int_tuple<"(0,2048)">
      %iter_121 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_122 = cute.add_offset(%iter_121, %90) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_123 = cute.make_view(%tup_122) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_124 = cute.get_iter(%view_123) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_125, %e1_126 = cute.get_leaves(%iter_124) : !cute.int_tuple<"(?,?{div=8})">
      %coord_127 = cute.make_coord(%e1_126) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %91 = cute.static : !cute.coord<"4096">
      %92 = cute.get_scalars(%coord_127) : !cute.coord<"?{div=8}">
      %93 = cute.get_scalars(%91) : !cute.coord<"4096">
      %true_128 = arith.constant true
      %94 = arith.cmpi slt, %92, %93 : i32
      %95 = arith.andi %true_128, %94 : i1
      %96 = arith.extui %95 : i1 to i8
      %97 = cute.static : !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_88, %97, %96) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %98 = cute.static : !cute.int_tuple<"(0,2560)">
      %iter_129 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_130 = cute.add_offset(%iter_129, %98) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_131 = cute.make_view(%tup_130) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_132 = cute.get_iter(%view_131) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_133, %e1_134 = cute.get_leaves(%iter_132) : !cute.int_tuple<"(?,?{div=8})">
      %coord_135 = cute.make_coord(%e1_134) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %99 = cute.static : !cute.coord<"4096">
      %100 = cute.get_scalars(%coord_135) : !cute.coord<"?{div=8}">
      %101 = cute.get_scalars(%99) : !cute.coord<"4096">
      %true_136 = arith.constant true
      %102 = arith.cmpi slt, %100, %101 : i32
      %103 = arith.andi %true_136, %102 : i1
      %104 = arith.extui %103 : i1 to i8
      %105 = cute.static : !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_88, %105, %104) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %106 = cute.static : !cute.int_tuple<"(0,3072)">
      %iter_137 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_138 = cute.add_offset(%iter_137, %106) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_139 = cute.make_view(%tup_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_140 = cute.get_iter(%view_139) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_141, %e1_142 = cute.get_leaves(%iter_140) : !cute.int_tuple<"(?,?{div=8})">
      %coord_143 = cute.make_coord(%e1_142) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %107 = cute.static : !cute.coord<"4096">
      %108 = cute.get_scalars(%coord_143) : !cute.coord<"?{div=8}">
      %109 = cute.get_scalars(%107) : !cute.coord<"4096">
      %true_144 = arith.constant true
      %110 = arith.cmpi slt, %108, %109 : i32
      %111 = arith.andi %true_144, %110 : i1
      %112 = arith.extui %111 : i1 to i8
      %113 = cute.static : !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_88, %113, %112) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %114 = cute.static : !cute.int_tuple<"(0,3584)">
      %iter_145 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_146 = cute.add_offset(%iter_145, %114) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_147 = cute.make_view(%tup_146) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_148 = cute.get_iter(%view_147) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_149, %e1_150 = cute.get_leaves(%iter_148) : !cute.int_tuple<"(?,?{div=8})">
      %coord_151 = cute.make_coord(%e1_150) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %115 = cute.static : !cute.coord<"4096">
      %116 = cute.get_scalars(%coord_151) : !cute.coord<"?{div=8}">
      %117 = cute.get_scalars(%115) : !cute.coord<"4096">
      %true_152 = arith.constant true
      %118 = arith.cmpi slt, %116, %117 : i32
      %119 = arith.andi %true_152, %118 : i1
      %120 = arith.extui %119 : i1 to i8
      %121 = cute.static : !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_88, %121, %120) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %122 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_153 = cute.get_iter(%view_72) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_154 = cute.add_offset(%iter_153, %122) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_155 = cute.make_view(%tup_154) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_156 = cute.get_iter(%view_155) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_157, %e1_158 = cute.get_leaves(%iter_156) : !cute.int_tuple<"(?,?{div=8})">
      %123 = cute.get_scalars(%e0_157) : !cute.int_tuple<"?">
      %124 = arith.cmpi slt, %123, %5 : i32
      scf.if %124 {
        %264 = cute.static : !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %view_284 = cute.make_view(%iter_41, %264) : !memref_gmem_bf16_5
        %iter_285 = cute.get_iter(%view_284) : !memref_gmem_bf16_5
        %view_286 = cute.make_view(%iter_285) : !memref_gmem_bf16_6
        %265 = cute.static : !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %view_287 = cute.make_view(%iter_52, %265) : !memref_smem_bf16_1
        %iter_288 = cute.get_iter(%view_287) : !memref_smem_bf16_1
        %view_289 = cute.make_view(%iter_288) : !memref_smem_bf16_2
        %266 = cute.static : !cute.layout<"(8,1,1):(1,0,1)">
        %view_290 = cute.make_view(%iter_89, %266) : !memref_rmem_i8_
        %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
        %view_292 = cute.make_view(%iter_291) : !memref_rmem_i8_1
        %267 = cute.static : !cute.layout<"1:0">
        %iter_293 = cute.get_iter(%view_286) : !memref_gmem_bf16_6
        %iter_294 = cute.get_iter(%view_289) : !memref_smem_bf16_2
        %iter_295 = cute.get_iter(%view_292) : !memref_rmem_i8_1
        %268 = cute.static : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %269 = cute.static : !cute.int_tuple<"1">
        %270 = cute.get_scalars(%269) : !cute.int_tuple<"1">
        %c0_i32_296 = arith.constant 0 : i32
        %c1_i32_297 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_296 to %270 step %c1_i32_297  : i32 {
          %coord_298 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %271 = cute.static : !cute.layout<"((8,8)):((1,512))">
          %272 = cute.static : !cute.int_tuple<"0">
          %ptr_299 = cute.add_offset(%iter_293, %272) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_300 = cute.make_view(%ptr_299, %271) : !memref_gmem_bf16_7
          %273 = cute.static : !cute.layout<"((8,8)):((1,512))">
          %274 = cute.static : !cute.int_tuple<"0">
          %ptr_301 = cute.add_offset(%iter_294, %274) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %view_302 = cute.make_view(%ptr_301, %273) : !memref_smem_bf16_3
          %275 = cute.static : !cute.layout<"(8):(1)">
          %idx_303 = cute.crd2idx(%coord_298, %268) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_304 = cute.add_offset(%iter_295, %idx_303) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_305 = cute.make_view(%ptr_304, %275) : !memref_rmem_i8_2
          %iter_306 = cute.get_iter(%view_300) : !memref_gmem_bf16_7
          %iter_307 = cute.get_iter(%view_302) : !memref_smem_bf16_3
          %iter_308 = cute.get_iter(%view_305) : !memref_rmem_i8_2
          %276 = builtin.unrealized_conversion_cast %iter_308 : !cute.ptr<i8, rmem> to !llvm.ptr
          %277 = llvm.load %276 : !llvm.ptr -> i8
          %278 = llvm.trunc %277 : i8 to i1
          %iter_309 = cute.recast_iter(%iter_306) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_310 = cute.recast_iter(%iter_307) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_310 : !cute.ptr<i128, smem>, %iter_309 : !cute.ptr<i128, gmem>, %278 : i1) {cache_mode = <always>}
          %279 = cute.static : !cute.int_tuple<"512">
          %ptr_311 = cute.add_offset(%iter_306, %279) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %280 = cute.static : !cute.int_tuple<"512">
          %ptr_312 = cute.add_offset(%iter_307, %280) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
          %281 = cute.static : !cute.int_tuple<"1">
          %ptr_313 = cute.add_offset(%iter_308, %281) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %282 = builtin.unrealized_conversion_cast %ptr_313 : !cute.ptr<i8, rmem> to !llvm.ptr
          %283 = llvm.load %282 : !llvm.ptr -> i8
          %284 = llvm.trunc %283 : i8 to i1
          %iter_314 = cute.recast_iter(%ptr_311) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_315 = cute.recast_iter(%ptr_312) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_315 : !cute.ptr<i128, smem>, %iter_314 : !cute.ptr<i128, gmem>, %284 : i1) {cache_mode = <always>}
          %285 = cute.static : !cute.int_tuple<"1024">
          %ptr_316 = cute.add_offset(%iter_306, %285) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %286 = cute.static : !cute.int_tuple<"1024">
          %ptr_317 = cute.add_offset(%iter_307, %286) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %287 = cute.static : !cute.int_tuple<"2">
          %ptr_318 = cute.add_offset(%iter_308, %287) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %288 = builtin.unrealized_conversion_cast %ptr_318 : !cute.ptr<i8, rmem> to !llvm.ptr
          %289 = llvm.load %288 : !llvm.ptr -> i8
          %290 = llvm.trunc %289 : i8 to i1
          %iter_319 = cute.recast_iter(%ptr_316) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_320 = cute.recast_iter(%ptr_317) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_320 : !cute.ptr<i128, smem>, %iter_319 : !cute.ptr<i128, gmem>, %290 : i1) {cache_mode = <always>}
          %291 = cute.static : !cute.int_tuple<"1536">
          %ptr_321 = cute.add_offset(%iter_306, %291) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %292 = cute.static : !cute.int_tuple<"1536">
          %ptr_322 = cute.add_offset(%iter_307, %292) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
          %293 = cute.static : !cute.int_tuple<"3">
          %ptr_323 = cute.add_offset(%iter_308, %293) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %294 = builtin.unrealized_conversion_cast %ptr_323 : !cute.ptr<i8, rmem> to !llvm.ptr
          %295 = llvm.load %294 : !llvm.ptr -> i8
          %296 = llvm.trunc %295 : i8 to i1
          %iter_324 = cute.recast_iter(%ptr_321) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_325 = cute.recast_iter(%ptr_322) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_325 : !cute.ptr<i128, smem>, %iter_324 : !cute.ptr<i128, gmem>, %296 : i1) {cache_mode = <always>}
          %297 = cute.static : !cute.int_tuple<"2048">
          %ptr_326 = cute.add_offset(%iter_306, %297) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %298 = cute.static : !cute.int_tuple<"2048">
          %ptr_327 = cute.add_offset(%iter_307, %298) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %299 = cute.static : !cute.int_tuple<"4">
          %ptr_328 = cute.add_offset(%iter_308, %299) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %300 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<i8, rmem> to !llvm.ptr
          %301 = llvm.load %300 : !llvm.ptr -> i8
          %302 = llvm.trunc %301 : i8 to i1
          %iter_329 = cute.recast_iter(%ptr_326) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_330 = cute.recast_iter(%ptr_327) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_330 : !cute.ptr<i128, smem>, %iter_329 : !cute.ptr<i128, gmem>, %302 : i1) {cache_mode = <always>}
          %303 = cute.static : !cute.int_tuple<"2560">
          %ptr_331 = cute.add_offset(%iter_306, %303) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %304 = cute.static : !cute.int_tuple<"2560">
          %ptr_332 = cute.add_offset(%iter_307, %304) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
          %305 = cute.static : !cute.int_tuple<"5">
          %ptr_333 = cute.add_offset(%iter_308, %305) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %306 = builtin.unrealized_conversion_cast %ptr_333 : !cute.ptr<i8, rmem> to !llvm.ptr
          %307 = llvm.load %306 : !llvm.ptr -> i8
          %308 = llvm.trunc %307 : i8 to i1
          %iter_334 = cute.recast_iter(%ptr_331) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_335 = cute.recast_iter(%ptr_332) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_335 : !cute.ptr<i128, smem>, %iter_334 : !cute.ptr<i128, gmem>, %308 : i1) {cache_mode = <always>}
          %309 = cute.static : !cute.int_tuple<"3072">
          %ptr_336 = cute.add_offset(%iter_306, %309) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %310 = cute.static : !cute.int_tuple<"3072">
          %ptr_337 = cute.add_offset(%iter_307, %310) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %311 = cute.static : !cute.int_tuple<"6">
          %ptr_338 = cute.add_offset(%iter_308, %311) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %312 = builtin.unrealized_conversion_cast %ptr_338 : !cute.ptr<i8, rmem> to !llvm.ptr
          %313 = llvm.load %312 : !llvm.ptr -> i8
          %314 = llvm.trunc %313 : i8 to i1
          %iter_339 = cute.recast_iter(%ptr_336) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_340 = cute.recast_iter(%ptr_337) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_340 : !cute.ptr<i128, smem>, %iter_339 : !cute.ptr<i128, gmem>, %314 : i1) {cache_mode = <always>}
          %315 = cute.static : !cute.int_tuple<"3584">
          %ptr_341 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %316 = cute.static : !cute.int_tuple<"3584">
          %ptr_342 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
          %317 = cute.static : !cute.int_tuple<"7">
          %ptr_343 = cute.add_offset(%iter_308, %317) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %318 = builtin.unrealized_conversion_cast %ptr_343 : !cute.ptr<i8, rmem> to !llvm.ptr
          %319 = llvm.load %318 : !llvm.ptr -> i8
          %320 = llvm.trunc %319 : i8 to i1
          %iter_344 = cute.recast_iter(%ptr_341) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_345 = cute.recast_iter(%ptr_342) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_345 : !cute.ptr<i128, smem>, %iter_344 : !cute.ptr<i128, gmem>, %320 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %coord_159 = cute.make_coord(%1) : (i32) -> !cute.coord<"?">
      %iter_160 = cute.get_iter(%view_29) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %125 = cute.get_scalars(%coord_159) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_161 = arith.constant 64 : i32
      %126 = arith.divsi %125, %c64_i32_161 : i32
      %c64_i32_162 = arith.constant 64 : i32
      %127 = arith.remsi %125, %c64_i32_162 : i32
      %c8_i32_163 = arith.constant 8 : i32
      %128 = arith.muli %127, %c8_i32_163 : i32
      %iv_164 = cute.assume(%128) : (i32) -> !cute.i32<divby 8>
      %int_tuple_165 = cute.make_int_tuple(%126, %iv_164) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_166 = cute.add_offset(%iter_160, %int_tuple_165) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_167 = cute.make_view(%tup_166) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %129 = cute.static : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_168 = cute.memref.alloca(%129) : !memref_rmem_i8_
      %iter_169 = cute.get_iter(%rmem_168) : !memref_rmem_i8_
      %130 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_170 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_171 = cute.add_offset(%iter_170, %130) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_172 = cute.make_view(%tup_171) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_173 = cute.get_iter(%view_172) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_174, %e1_175 = cute.get_leaves(%iter_173) : !cute.int_tuple<"(?,?{div=8})">
      %coord_176 = cute.make_coord(%e1_175) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %131 = cute.static : !cute.coord<"4096">
      %132 = cute.get_scalars(%coord_176) : !cute.coord<"?{div=8}">
      %133 = cute.get_scalars(%131) : !cute.coord<"4096">
      %true_177 = arith.constant true
      %134 = arith.cmpi slt, %132, %133 : i32
      %135 = arith.andi %true_177, %134 : i1
      %136 = arith.extui %135 : i1 to i8
      %137 = cute.static : !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_168, %137, %136) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %138 = cute.static : !cute.int_tuple<"(0,512)">
      %iter_178 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_179 = cute.add_offset(%iter_178, %138) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_180 = cute.make_view(%tup_179) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_181 = cute.get_iter(%view_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_182, %e1_183 = cute.get_leaves(%iter_181) : !cute.int_tuple<"(?,?{div=8})">
      %coord_184 = cute.make_coord(%e1_183) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %139 = cute.static : !cute.coord<"4096">
      %140 = cute.get_scalars(%coord_184) : !cute.coord<"?{div=8}">
      %141 = cute.get_scalars(%139) : !cute.coord<"4096">
      %true_185 = arith.constant true
      %142 = arith.cmpi slt, %140, %141 : i32
      %143 = arith.andi %true_185, %142 : i1
      %144 = arith.extui %143 : i1 to i8
      %145 = cute.static : !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_168, %145, %144) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %146 = cute.static : !cute.int_tuple<"(0,1024)">
      %iter_186 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_187 = cute.add_offset(%iter_186, %146) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_188 = cute.make_view(%tup_187) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_189 = cute.get_iter(%view_188) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_190, %e1_191 = cute.get_leaves(%iter_189) : !cute.int_tuple<"(?,?{div=8})">
      %coord_192 = cute.make_coord(%e1_191) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %147 = cute.static : !cute.coord<"4096">
      %148 = cute.get_scalars(%coord_192) : !cute.coord<"?{div=8}">
      %149 = cute.get_scalars(%147) : !cute.coord<"4096">
      %true_193 = arith.constant true
      %150 = arith.cmpi slt, %148, %149 : i32
      %151 = arith.andi %true_193, %150 : i1
      %152 = arith.extui %151 : i1 to i8
      %153 = cute.static : !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_168, %153, %152) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %154 = cute.static : !cute.int_tuple<"(0,1536)">
      %iter_194 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_195 = cute.add_offset(%iter_194, %154) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_196 = cute.make_view(%tup_195) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_197 = cute.get_iter(%view_196) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_198, %e1_199 = cute.get_leaves(%iter_197) : !cute.int_tuple<"(?,?{div=8})">
      %coord_200 = cute.make_coord(%e1_199) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %155 = cute.static : !cute.coord<"4096">
      %156 = cute.get_scalars(%coord_200) : !cute.coord<"?{div=8}">
      %157 = cute.get_scalars(%155) : !cute.coord<"4096">
      %true_201 = arith.constant true
      %158 = arith.cmpi slt, %156, %157 : i32
      %159 = arith.andi %true_201, %158 : i1
      %160 = arith.extui %159 : i1 to i8
      %161 = cute.static : !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_168, %161, %160) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %162 = cute.static : !cute.int_tuple<"(0,2048)">
      %iter_202 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_203 = cute.add_offset(%iter_202, %162) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_204 = cute.make_view(%tup_203) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_205 = cute.get_iter(%view_204) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_206, %e1_207 = cute.get_leaves(%iter_205) : !cute.int_tuple<"(?,?{div=8})">
      %coord_208 = cute.make_coord(%e1_207) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %163 = cute.static : !cute.coord<"4096">
      %164 = cute.get_scalars(%coord_208) : !cute.coord<"?{div=8}">
      %165 = cute.get_scalars(%163) : !cute.coord<"4096">
      %true_209 = arith.constant true
      %166 = arith.cmpi slt, %164, %165 : i32
      %167 = arith.andi %true_209, %166 : i1
      %168 = arith.extui %167 : i1 to i8
      %169 = cute.static : !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_168, %169, %168) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %170 = cute.static : !cute.int_tuple<"(0,2560)">
      %iter_210 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_211 = cute.add_offset(%iter_210, %170) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_212 = cute.make_view(%tup_211) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_213 = cute.get_iter(%view_212) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_214, %e1_215 = cute.get_leaves(%iter_213) : !cute.int_tuple<"(?,?{div=8})">
      %coord_216 = cute.make_coord(%e1_215) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %171 = cute.static : !cute.coord<"4096">
      %172 = cute.get_scalars(%coord_216) : !cute.coord<"?{div=8}">
      %173 = cute.get_scalars(%171) : !cute.coord<"4096">
      %true_217 = arith.constant true
      %174 = arith.cmpi slt, %172, %173 : i32
      %175 = arith.andi %true_217, %174 : i1
      %176 = arith.extui %175 : i1 to i8
      %177 = cute.static : !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_168, %177, %176) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %178 = cute.static : !cute.int_tuple<"(0,3072)">
      %iter_218 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_219 = cute.add_offset(%iter_218, %178) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_220 = cute.make_view(%tup_219) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_221 = cute.get_iter(%view_220) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_222, %e1_223 = cute.get_leaves(%iter_221) : !cute.int_tuple<"(?,?{div=8})">
      %coord_224 = cute.make_coord(%e1_223) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %179 = cute.static : !cute.coord<"4096">
      %180 = cute.get_scalars(%coord_224) : !cute.coord<"?{div=8}">
      %181 = cute.get_scalars(%179) : !cute.coord<"4096">
      %true_225 = arith.constant true
      %182 = arith.cmpi slt, %180, %181 : i32
      %183 = arith.andi %true_225, %182 : i1
      %184 = arith.extui %183 : i1 to i8
      %185 = cute.static : !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_168, %185, %184) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %186 = cute.static : !cute.int_tuple<"(0,3584)">
      %iter_226 = cute.get_iter(%view_167) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_227 = cute.add_offset(%iter_226, %186) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_228 = cute.make_view(%tup_227) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_229 = cute.get_iter(%view_228) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_230, %e1_231 = cute.get_leaves(%iter_229) : !cute.int_tuple<"(?,?{div=8})">
      %coord_232 = cute.make_coord(%e1_231) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %187 = cute.static : !cute.coord<"4096">
      %188 = cute.get_scalars(%coord_232) : !cute.coord<"?{div=8}">
      %189 = cute.get_scalars(%187) : !cute.coord<"4096">
      %true_233 = arith.constant true
      %190 = arith.cmpi slt, %188, %189 : i32
      %191 = arith.andi %true_233, %190 : i1
      %192 = arith.extui %191 : i1 to i8
      %193 = cute.static : !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_168, %193, %192) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %194 = cute.static : !cute.layout<"((8,8),1,1):((1,512),0,0)">
      %view_234 = cute.make_view(%iter_83, %194) : !memref_gmem_bf16_5
      %iter_235 = cute.get_iter(%view_234) : !memref_gmem_bf16_5
      %view_236 = cute.make_view(%iter_235) : !memref_gmem_bf16_6
      %195 = cute.static : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %view_237 = cute.make_view(%iter_85, %195) : !memref_rmem_bf16_
      %iter_238 = cute.get_iter(%view_237) : !memref_rmem_bf16_
      %view_239 = cute.make_view(%iter_238) : !memref_rmem_bf16_1
      %196 = cute.static : !cute.layout<"(8,1,1):(1,0,1)">
      %view_240 = cute.make_view(%iter_169, %196) : !memref_rmem_i8_
      %iter_241 = cute.get_iter(%view_240) : !memref_rmem_i8_
      %view_242 = cute.make_view(%iter_241) : !memref_rmem_i8_1
      %197 = cute.static : !cute.layout<"1:0">
      %iter_243 = cute.get_iter(%view_236) : !memref_gmem_bf16_6
      %iter_244 = cute.get_iter(%view_239) : !memref_rmem_bf16_1
      %iter_245 = cute.get_iter(%view_242) : !memref_rmem_i8_1
      %198 = cute.static : !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %199 = cute.static : !cute.int_tuple<"1">
      %200 = cute.get_scalars(%199) : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %c1_i32 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32 to %200 step %c1_i32  : i32 {
        %coord_284 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %264 = cute.static : !cute.layout<"((8,8)):((1,512))">
        %265 = cute.static : !cute.int_tuple<"0">
        %ptr_285 = cute.add_offset(%iter_243, %265) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_286 = cute.make_view(%ptr_285, %264) : !memref_gmem_bf16_7
        %266 = cute.static : !cute.layout<"((8,8)):((1,8))">
        %267 = cute.static : !cute.int_tuple<"0">
        %ptr_287 = cute.add_offset(%iter_244, %267) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_288 = cute.make_view(%ptr_287, %266) : !memref_rmem_bf16_2
        %268 = cute.static : !cute.layout<"(8):(1)">
        %idx_289 = cute.crd2idx(%coord_284, %198) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %ptr_290 = cute.add_offset(%iter_245, %idx_289) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %view_291 = cute.make_view(%ptr_290, %268) : !memref_rmem_i8_2
        %iter_292 = cute.get_iter(%view_286) : !memref_gmem_bf16_7
        %iter_293 = cute.get_iter(%view_288) : !memref_rmem_bf16_2
        %iter_294 = cute.get_iter(%view_291) : !memref_rmem_i8_2
        %269 = builtin.unrealized_conversion_cast %iter_294 : !cute.ptr<i8, rmem> to !llvm.ptr
        %270 = llvm.load %269 : !llvm.ptr -> i8
        %271 = llvm.mlir.constant(0 : i8) : i8
        %272 = llvm.icmp "ne" %270, %271 : i8
        scf.if %272 {
          %308 = builtin.unrealized_conversion_cast %iter_292 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %309 = builtin.unrealized_conversion_cast %iter_293 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %310 = llvm.load %308 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %310, %309 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %273 = cute.static : !cute.int_tuple<"1">
        %ptr_295 = cute.add_offset(%iter_294, %273) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %274 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<i8, rmem> to !llvm.ptr
        %275 = llvm.load %274 : !llvm.ptr -> i8
        %276 = llvm.mlir.constant(0 : i8) : i8
        %277 = llvm.icmp "ne" %275, %276 : i8
        scf.if %277 {
          %308 = cute.static : !cute.int_tuple<"512">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"8">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %278 = cute.static : !cute.int_tuple<"2">
        %ptr_296 = cute.add_offset(%iter_294, %278) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %279 = builtin.unrealized_conversion_cast %ptr_296 : !cute.ptr<i8, rmem> to !llvm.ptr
        %280 = llvm.load %279 : !llvm.ptr -> i8
        %281 = llvm.mlir.constant(0 : i8) : i8
        %282 = llvm.icmp "ne" %280, %281 : i8
        scf.if %282 {
          %308 = cute.static : !cute.int_tuple<"1024">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"16">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %283 = cute.static : !cute.int_tuple<"3">
        %ptr_297 = cute.add_offset(%iter_294, %283) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %284 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<i8, rmem> to !llvm.ptr
        %285 = llvm.load %284 : !llvm.ptr -> i8
        %286 = llvm.mlir.constant(0 : i8) : i8
        %287 = llvm.icmp "ne" %285, %286 : i8
        scf.if %287 {
          %308 = cute.static : !cute.int_tuple<"1536">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"24">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %288 = cute.static : !cute.int_tuple<"4">
        %ptr_298 = cute.add_offset(%iter_294, %288) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %289 = builtin.unrealized_conversion_cast %ptr_298 : !cute.ptr<i8, rmem> to !llvm.ptr
        %290 = llvm.load %289 : !llvm.ptr -> i8
        %291 = llvm.mlir.constant(0 : i8) : i8
        %292 = llvm.icmp "ne" %290, %291 : i8
        scf.if %292 {
          %308 = cute.static : !cute.int_tuple<"2048">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"32">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %293 = cute.static : !cute.int_tuple<"5">
        %ptr_299 = cute.add_offset(%iter_294, %293) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %294 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<i8, rmem> to !llvm.ptr
        %295 = llvm.load %294 : !llvm.ptr -> i8
        %296 = llvm.mlir.constant(0 : i8) : i8
        %297 = llvm.icmp "ne" %295, %296 : i8
        scf.if %297 {
          %308 = cute.static : !cute.int_tuple<"2560">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"40">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %298 = cute.static : !cute.int_tuple<"6">
        %ptr_300 = cute.add_offset(%iter_294, %298) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %299 = builtin.unrealized_conversion_cast %ptr_300 : !cute.ptr<i8, rmem> to !llvm.ptr
        %300 = llvm.load %299 : !llvm.ptr -> i8
        %301 = llvm.mlir.constant(0 : i8) : i8
        %302 = llvm.icmp "ne" %300, %301 : i8
        scf.if %302 {
          %308 = cute.static : !cute.int_tuple<"3072">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"48">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %303 = cute.static : !cute.int_tuple<"7">
        %ptr_301 = cute.add_offset(%iter_294, %303) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %304 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<i8, rmem> to !llvm.ptr
        %305 = llvm.load %304 : !llvm.ptr -> i8
        %306 = llvm.mlir.constant(0 : i8) : i8
        %307 = llvm.icmp "ne" %305, %306 : i8
        scf.if %307 {
          %308 = cute.static : !cute.int_tuple<"3584">
          %ptr_302 = cute.add_offset(%iter_292, %308) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %309 = cute.static : !cute.int_tuple<"56">
          %ptr_303 = cute.add_offset(%iter_293, %309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %310 = builtin.unrealized_conversion_cast %ptr_302 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %311 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %312 = llvm.load %310 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %312, %311 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %iter_246 = cute.get_iter(%view_51) : !memref_smem_bf16_1
      %view_247 = cute.make_view(%iter_246) : !memref_smem_bf16_4
      %iter_248 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_249 = cute.make_view(%iter_248) : !memref_rmem_bf16_3
      %iter_250 = cute.get_iter(%view_247) : !memref_smem_bf16_4
      %view_251 = cute.make_view(%iter_250) : !memref_smem_bf16_4
      %iter_252 = cute.get_iter(%view_249) : !memref_rmem_bf16_3
      %view_253 = cute.make_view(%iter_252) : !memref_rmem_bf16_3
      %201 = cute.static : !cute.layout<"1:0">
      %iter_254 = cute.get_iter(%view_251) : !memref_smem_bf16_4
      %iter_255 = cute.get_iter(%view_253) : !memref_rmem_bf16_3
      %202 = cute.static : !cute.layout<"(8,(8)):(1,(512))">
      %203 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %204 = cute.static : !cute.int_tuple<"8">
      %205 = cute.get_scalars(%204) : !cute.int_tuple<"8">
      %c0_i32_256 = arith.constant 0 : i32
      %c1_i32_257 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_256 to %205 step %c1_i32_257  : i32 {
        %coord_284 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %264 = cute.static : !cute.layout<"(8):(1)">
        %idx_285 = cute.crd2idx(%coord_284, %202) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_286 = cute.add_offset(%iter_254, %idx_285) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_287 = cute.make_view(%ptr_286, %264) : !memref_smem_bf16_5
        %265 = cute.static : !cute.layout<"(8):(1)">
        %idx_288 = cute.crd2idx(%coord_284, %203) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_289 = cute.add_offset(%iter_255, %idx_288) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_290 = cute.make_view(%ptr_289, %265) : !memref_rmem_bf16_4
        %iter_291 = cute.get_iter(%view_287) : !memref_smem_bf16_5
        %iter_292 = cute.get_iter(%view_290) : !memref_rmem_bf16_4
        %266 = builtin.unrealized_conversion_cast %iter_291 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %267 = builtin.unrealized_conversion_cast %iter_292 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %268 = llvm.load %266 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %268, %267 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %206 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %207 = arith.extf %206 : vector<64xbf16> to vector<64xf32>
      %208 = arith.mulf %207, %207 : vector<64xf32>
      %cst = arith.constant 0.000000e+00 : f32
      %209 = vector.reduction <add>, %208, %cst : vector<64xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c31_i32 = arith.constant 31 : i32
      %210 = nvvm.shfl.sync  bfly %c-1_i32, %209, %c16_i32, %c31_i32 : f32 -> f32
      %211 = arith.addf %210, %209 : f32
      %c8_i32_258 = arith.constant 8 : i32
      %212 = nvvm.shfl.sync  bfly %c-1_i32, %211, %c8_i32_258, %c31_i32 : f32 -> f32
      %213 = arith.addf %211, %212 : f32
      %c4_i32 = arith.constant 4 : i32
      %214 = nvvm.shfl.sync  bfly %c-1_i32, %213, %c4_i32, %c31_i32 : f32 -> f32
      %215 = arith.addf %213, %214 : f32
      %c2_i32_259 = arith.constant 2 : i32
      %216 = nvvm.shfl.sync  bfly %c-1_i32, %215, %c2_i32_259, %c31_i32 : f32 -> f32
      %217 = arith.addf %215, %216 : f32
      %c1_i32_260 = arith.constant 1 : i32
      %218 = nvvm.shfl.sync  bfly %c-1_i32, %217, %c1_i32_260, %c31_i32 : f32 -> f32
      %219 = arith.addf %217, %218 : f32
      %220 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %221 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %222 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %223 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %224 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %225 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %226 = arith.muli %222, %224 : i32
      %227 = arith.addi %221, %226 : i32
      %228 = arith.muli %223, %224 : i32
      %229 = arith.muli %228, %225 : i32
      %230 = arith.addi %227, %229 : i32
      %c32_i32 = arith.constant 32 : i32
      %231 = arith.floordivsi %230, %c32_i32 : i32
      %c2_i32_261 = arith.constant 2 : i32
      %232 = arith.floordivsi %231, %c2_i32_261 : i32
      %233 = arith.remsi %231, %c2_i32_261 : i32
      %c0_i32_262 = arith.constant 0 : i32
      %234 = arith.cmpi eq, %220, %c0_i32_262 : i32
      %235 = scf.if %234 -> (!memref_smem_f32_) {
        %coord_284 = cute.make_coord(%232, %233) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view_2, %coord_284, %219) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        scf.yield %view_2 : !memref_smem_f32_
      } else {
        scf.yield %view_2 : !memref_smem_f32_
      }
      nvvm.barrier
      %236 = arith.cmpi slt, %220, %c2_i32_261 : i32
      %cst_263 = arith.constant 0.000000e+00 : f32
      %237 = scf.if %236 -> (f32) {
        %coord_284 = cute.make_coord(%232, %220) : (i32, i32) -> !cute.coord<"(?,?)">
        %264 = cute.memref.load(%235, %coord_284) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %264 : f32
      } else {
        scf.yield %cst_263 : f32
      }
      %c-1_i32_264 = arith.constant -1 : i32
      %c16_i32_265 = arith.constant 16 : i32
      %c31_i32_266 = arith.constant 31 : i32
      %238 = nvvm.shfl.sync  bfly %c-1_i32_264, %237, %c16_i32_265, %c31_i32_266 : f32 -> f32
      %239 = arith.addf %237, %238 : f32
      %c8_i32_267 = arith.constant 8 : i32
      %240 = nvvm.shfl.sync  bfly %c-1_i32_264, %239, %c8_i32_267, %c31_i32_266 : f32 -> f32
      %241 = arith.addf %239, %240 : f32
      %c4_i32_268 = arith.constant 4 : i32
      %242 = nvvm.shfl.sync  bfly %c-1_i32_264, %241, %c4_i32_268, %c31_i32_266 : f32 -> f32
      %243 = arith.addf %241, %242 : f32
      %c2_i32_269 = arith.constant 2 : i32
      %244 = nvvm.shfl.sync  bfly %c-1_i32_264, %243, %c2_i32_269, %c31_i32_266 : f32 -> f32
      %245 = arith.addf %243, %244 : f32
      %c1_i32_270 = arith.constant 1 : i32
      %246 = nvvm.shfl.sync  bfly %c-1_i32_264, %245, %c1_i32_270, %c31_i32_266 : f32 -> f32
      %247 = arith.addf %245, %246 : f32
      %cst_271 = arith.constant 4.096000e+03 : f32
      %248 = arith.divf %247, %cst_271 : f32
      %249 = arith.addf %248, %arg3 : f32
      %250 = math.rsqrt %249 fastmath<fast> : f32
      nvvm.barrier
      %iter_272 = cute.get_iter(%view_51) : !memref_smem_bf16_1
      %view_273 = cute.make_view(%iter_272) : !memref_smem_bf16_4
      %iter_274 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_275 = cute.make_view(%iter_274) : !memref_rmem_bf16_3
      %iter_276 = cute.get_iter(%view_273) : !memref_smem_bf16_4
      %view_277 = cute.make_view(%iter_276) : !memref_smem_bf16_4
      %iter_278 = cute.get_iter(%view_275) : !memref_rmem_bf16_3
      %view_279 = cute.make_view(%iter_278) : !memref_rmem_bf16_3
      %251 = cute.static : !cute.layout<"1:0">
      %iter_280 = cute.get_iter(%view_277) : !memref_smem_bf16_4
      %iter_281 = cute.get_iter(%view_279) : !memref_rmem_bf16_3
      %252 = cute.static : !cute.layout<"(8,(8)):(1,(512))">
      %253 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %254 = cute.static : !cute.int_tuple<"8">
      %255 = cute.get_scalars(%254) : !cute.int_tuple<"8">
      %c0_i32_282 = arith.constant 0 : i32
      %c1_i32_283 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_282 to %255 step %c1_i32_283  : i32 {
        %coord_284 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %264 = cute.static : !cute.layout<"(8):(1)">
        %idx_285 = cute.crd2idx(%coord_284, %252) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_286 = cute.add_offset(%iter_280, %idx_285) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_287 = cute.make_view(%ptr_286, %264) : !memref_smem_bf16_5
        %265 = cute.static : !cute.layout<"(8):(1)">
        %idx_288 = cute.crd2idx(%coord_284, %253) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_289 = cute.add_offset(%iter_281, %idx_288) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_290 = cute.make_view(%ptr_289, %265) : !memref_rmem_bf16_4
        %iter_291 = cute.get_iter(%view_287) : !memref_smem_bf16_5
        %iter_292 = cute.get_iter(%view_290) : !memref_rmem_bf16_4
        %266 = builtin.unrealized_conversion_cast %iter_291 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %267 = builtin.unrealized_conversion_cast %iter_292 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %268 = llvm.load %266 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %268, %267 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %256 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %257 = arith.extf %256 : vector<64xbf16> to vector<64xf32>
      %258 = vector.broadcast %250 : f32 to vector<64xf32>
      %259 = arith.mulf %257, %258 : vector<64xf32>
      %260 = cute.memref.load_vec %view_87 : !memref_rmem_bf16_
      %261 = arith.extf %260 : vector<64xbf16> to vector<64xf32>
      %262 = arith.mulf %259, %261 : vector<64xf32>
      %263 = arith.truncf %262 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %263, %rmem_73 : !memref_rmem_bf16_
      scf.if %124 {
        %264 = cute.static : !cute.layout<"((8,8),1,1):((1,8),0,0)">
        %view_284 = cute.make_view(%iter_74, %264) : !memref_rmem_bf16_
        %iter_285 = cute.get_iter(%view_284) : !memref_rmem_bf16_
        %view_286 = cute.make_view(%iter_285) : !memref_rmem_bf16_1
        %265 = cute.static : !cute.layout<"((8,8),1,1):((1,512),0,0)">
        %view_287 = cute.make_view(%iter_63, %265) : !memref_gmem_bf16_5
        %iter_288 = cute.get_iter(%view_287) : !memref_gmem_bf16_5
        %view_289 = cute.make_view(%iter_288) : !memref_gmem_bf16_6
        %266 = cute.static : !cute.layout<"(8,1,1):(1,0,1)">
        %view_290 = cute.make_view(%iter_89, %266) : !memref_rmem_i8_
        %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
        %view_292 = cute.make_view(%iter_291) : !memref_rmem_i8_1
        %267 = cute.static : !cute.layout<"1:0">
        %iter_293 = cute.get_iter(%view_286) : !memref_rmem_bf16_1
        %iter_294 = cute.get_iter(%view_289) : !memref_gmem_bf16_6
        %iter_295 = cute.get_iter(%view_292) : !memref_rmem_i8_1
        %268 = cute.static : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %269 = cute.static : !cute.int_tuple<"1">
        %270 = cute.get_scalars(%269) : !cute.int_tuple<"1">
        %c0_i32_296 = arith.constant 0 : i32
        %c1_i32_297 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_296 to %270 step %c1_i32_297  : i32 {
          %coord_298 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %271 = cute.static : !cute.layout<"((8,8)):((1,8))">
          %272 = cute.static : !cute.int_tuple<"0">
          %ptr_299 = cute.add_offset(%iter_293, %272) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %view_300 = cute.make_view(%ptr_299, %271) : !memref_rmem_bf16_2
          %273 = cute.static : !cute.layout<"((8,8)):((1,512))">
          %274 = cute.static : !cute.int_tuple<"0">
          %ptr_301 = cute.add_offset(%iter_294, %274) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_302 = cute.make_view(%ptr_301, %273) : !memref_gmem_bf16_7
          %275 = cute.static : !cute.layout<"(8):(1)">
          %idx_303 = cute.crd2idx(%coord_298, %268) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_304 = cute.add_offset(%iter_295, %idx_303) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_305 = cute.make_view(%ptr_304, %275) : !memref_rmem_i8_2
          %iter_306 = cute.get_iter(%view_300) : !memref_rmem_bf16_2
          %iter_307 = cute.get_iter(%view_302) : !memref_gmem_bf16_7
          %iter_308 = cute.get_iter(%view_305) : !memref_rmem_i8_2
          %276 = builtin.unrealized_conversion_cast %iter_308 : !cute.ptr<i8, rmem> to !llvm.ptr
          %277 = llvm.load %276 : !llvm.ptr -> i8
          %278 = llvm.mlir.constant(0 : i8) : i8
          %279 = llvm.icmp "ne" %277, %278 : i8
          scf.if %279 {
            %315 = builtin.unrealized_conversion_cast %iter_306 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %316 = builtin.unrealized_conversion_cast %iter_307 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %317 = llvm.load %315 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %317, %316 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %280 = cute.static : !cute.int_tuple<"1">
          %ptr_309 = cute.add_offset(%iter_308, %280) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %281 = builtin.unrealized_conversion_cast %ptr_309 : !cute.ptr<i8, rmem> to !llvm.ptr
          %282 = llvm.load %281 : !llvm.ptr -> i8
          %283 = llvm.mlir.constant(0 : i8) : i8
          %284 = llvm.icmp "ne" %282, %283 : i8
          scf.if %284 {
            %315 = cute.static : !cute.int_tuple<"8">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %316 = cute.static : !cute.int_tuple<"512">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %285 = cute.static : !cute.int_tuple<"2">
          %ptr_310 = cute.add_offset(%iter_308, %285) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %286 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<i8, rmem> to !llvm.ptr
          %287 = llvm.load %286 : !llvm.ptr -> i8
          %288 = llvm.mlir.constant(0 : i8) : i8
          %289 = llvm.icmp "ne" %287, %288 : i8
          scf.if %289 {
            %315 = cute.static : !cute.int_tuple<"16">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %316 = cute.static : !cute.int_tuple<"1024">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %290 = cute.static : !cute.int_tuple<"3">
          %ptr_311 = cute.add_offset(%iter_308, %290) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %291 = builtin.unrealized_conversion_cast %ptr_311 : !cute.ptr<i8, rmem> to !llvm.ptr
          %292 = llvm.load %291 : !llvm.ptr -> i8
          %293 = llvm.mlir.constant(0 : i8) : i8
          %294 = llvm.icmp "ne" %292, %293 : i8
          scf.if %294 {
            %315 = cute.static : !cute.int_tuple<"24">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %316 = cute.static : !cute.int_tuple<"1536">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %295 = cute.static : !cute.int_tuple<"4">
          %ptr_312 = cute.add_offset(%iter_308, %295) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %296 = builtin.unrealized_conversion_cast %ptr_312 : !cute.ptr<i8, rmem> to !llvm.ptr
          %297 = llvm.load %296 : !llvm.ptr -> i8
          %298 = llvm.mlir.constant(0 : i8) : i8
          %299 = llvm.icmp "ne" %297, %298 : i8
          scf.if %299 {
            %315 = cute.static : !cute.int_tuple<"32">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %316 = cute.static : !cute.int_tuple<"2048">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %300 = cute.static : !cute.int_tuple<"5">
          %ptr_313 = cute.add_offset(%iter_308, %300) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %301 = builtin.unrealized_conversion_cast %ptr_313 : !cute.ptr<i8, rmem> to !llvm.ptr
          %302 = llvm.load %301 : !llvm.ptr -> i8
          %303 = llvm.mlir.constant(0 : i8) : i8
          %304 = llvm.icmp "ne" %302, %303 : i8
          scf.if %304 {
            %315 = cute.static : !cute.int_tuple<"40">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %316 = cute.static : !cute.int_tuple<"2560">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %305 = cute.static : !cute.int_tuple<"6">
          %ptr_314 = cute.add_offset(%iter_308, %305) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %306 = builtin.unrealized_conversion_cast %ptr_314 : !cute.ptr<i8, rmem> to !llvm.ptr
          %307 = llvm.load %306 : !llvm.ptr -> i8
          %308 = llvm.mlir.constant(0 : i8) : i8
          %309 = llvm.icmp "ne" %307, %308 : i8
          scf.if %309 {
            %315 = cute.static : !cute.int_tuple<"48">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %316 = cute.static : !cute.int_tuple<"3072">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %310 = cute.static : !cute.int_tuple<"7">
          %ptr_315 = cute.add_offset(%iter_308, %310) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %311 = builtin.unrealized_conversion_cast %ptr_315 : !cute.ptr<i8, rmem> to !llvm.ptr
          %312 = llvm.load %311 : !llvm.ptr -> i8
          %313 = llvm.mlir.constant(0 : i8) : i8
          %314 = llvm.icmp "ne" %312, %313 : i8
          scf.if %314 {
            %315 = cute.static : !cute.int_tuple<"56">
            %ptr_316 = cute.add_offset(%iter_306, %315) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %316 = cute.static : !cute.int_tuple<"3584">
            %ptr_317 = cute.add_offset(%iter_307, %316) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %317 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %318 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %shape = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %0 = cute.static : !cute.stride<"(4096,1)">
    %lay = cute.make_layout(%shape, %0) : !cute.layout<"(?,4096):(4096,1)">
    %view = cute.make_view(%arg0, %lay) : !memref_gmem_bf16_
    %shape_0 = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %1 = cute.static : !cute.stride<"(4096,1)">
    %lay_1 = cute.make_layout(%shape_0, %1) : !cute.layout<"(?,4096):(4096,1)">
    %view_2 = cute.make_view(%arg2, %lay_1) : !memref_gmem_bf16_
    %2 = cute.static : !cute.layout<"(4096):(1)">
    %view_3 = cute.make_view(%arg1, %2) : !memref_gmem_bf16_1
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %c2_i32 = arith.constant 2 : i32
    %4 = arith.ceildivsi %3, %c2_i32 : i32
    %int_tuple_4 = cute.make_int_tuple(%4) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_4) : !cute.int_tuple<"?">
    %5 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %c16400_i32 = arith.constant 16400 : i32
    %6 = arith.extsi %c16400_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %7 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %6, gridDim = (%5, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %8 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%7> (%view, %view_3, %view_2, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %9 = cuda.cast %8 : !cuda.result -> i32
    cuda.return_if_error %9 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
