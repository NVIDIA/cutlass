!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">, tiler_mn = <"[64:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_2 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_3 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_simt1 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(?,?{div=8}):(?{i64 div=8},1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(64,128):(?{i64 div=8},1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(64,64,?):(?{i64 div=8},1,64)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,1),4,2):((1,0),?{i64 div=128},64)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
!memref_gmem_bf16_7 = !cute.memref<bf16, gmem, align<16>, "((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
!memref_gmem_bf16_8 = !cute.memref<bf16, gmem, align<16>, "((8,1),2):((1,0),64)">
!memref_gmem_bf16_9 = !cute.memref<bf16, gmem, align<16>, "((8,1),(2)):((1,0),(64))">
!memref_gmem_bf16_10 = !cute.memref<bf16, gmem, align<16>, "((8,1)):((1,0))">
!memref_gmem_bf16_11 = !cute.memref<bf16, gmem, align<16>, "((8,1),1):((1,0),0)">
!memref_gmem_bf16_12 = !cute.memref<bf16, gmem, align<16>, "((8,1),(1)):((1,0),(0))">
!memref_gmem_bf16_13 = !cute.memref<bf16, gmem, align<16>, "((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<16>, "((2,2,2),1,((2,2),2)):((1,2,4),0,((16,32),8))">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<8>, "((2,2),(2,4),((2,2),2)):((1,2),(32,4),((64,128),16))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2),4):((1,2),(4,128),32)">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<16>, "((8,1),1,(4,2)):((1,0),0,(16,8))">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1),4,(4,2)):(((1,32),0),4,(64,16))">
!memref_rmem_bf16_5 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4,2),4):((1,0),(8,128),32)">
!memref_rmem_bf16_6 = !cute.memref<bf16, rmem, align<32>, "((2,2),1,8):((1,2),0,4)">
!memref_rmem_bf16_7 = !cute.memref<bf16, rmem, align<32>, "((8,1),1,4):((1,0),0,8)">
!memref_rmem_bf16_8 = !cute.memref<bf16, rmem, align<32>, "((8,1),(1,4)):((1,0),(0,8))">
!memref_rmem_bf16_9 = !cute.memref<bf16, rmem, align<16>, "((8,1),1):((1,0),0)">
!memref_rmem_bf16_10 = !cute.memref<bf16, rmem, align<16>, "((8,1),(1)):((1,0),(0))">
!memref_rmem_bf16_11 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1),4):(((1,32),0),4)">
!memref_rmem_bf16_12 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1),(4)):(((1,32),0),(4))">
!memref_rmem_bf16_13 = !cute.memref<bf16, rmem, align<16>, "((2,2,2),1):((1,2,4),0)">
!memref_rmem_bf16_14 = !cute.memref<bf16, rmem, align<8>, "((2,2),(2,4)):((1,2),(32,4))">
!memref_rmem_bf16_15 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),1,4):(((1,2),4),0,8)">
!memref_rmem_bf16_16 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4,2)):((1,0),(8,128))">
!memref_rmem_bf16_17 = !cute.memref<bf16, rmem, align<8>, "((8,1),((4,2))):((1,0),((8,128)))">
!memref_rmem_bf16_18 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),1):(((1,2),4),0)">
!memref_rmem_bf16_19 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2)):((1,2),(4,128))">
!memref_rmem_bf16_20 = !cute.memref<bf16, rmem, align<16>, "(((2,2),2),1):(((1,2),4),0)">
!memref_rmem_bf16_21 = !cute.memref<bf16, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_bf16_22 = !cute.memref<bf16, rmem, align<32>, "((1,8),1,8):((0,1),0,8)">
!memref_rmem_bf16_23 = !cute.memref<bf16, rmem, align<32>, "((1,8),(1,8)):((0,1),(0,8))">
!memref_rmem_bf16_24 = !cute.memref<bf16, rmem, align<32>, "((8,1),4,2):((1,0),16,8)">
!memref_rmem_bf16_25 = !cute.memref<bf16, rmem, align<32>, "((8,1),(4,2)):((1,0),(16,8))">
!memref_rmem_bf16_26 = !cute.memref<bf16, rmem, align<32>, "((8,1),2):((1,0),8)">
!memref_rmem_bf16_27 = !cute.memref<bf16, rmem, align<32>, "((8,1),(2)):((1,0),(8))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((2,2),1,8):((1,2),0,4)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,4,2):(2,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,2):(2,1)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,(2)):(2,(1))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(1,(4,2)):(2,(0,1))">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((64,2),64):((1,4096),64)">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,1),4,2):((1,0),1024,4096)">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "((8,1),4,1):((1,0),1024,0)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<4>, "((2,2,2),1,((2,2),2)):((1,?{div=64},8),0,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_6 = !cute.memref<bf16, smem, align<4>, "((2,2),(2,4),((2,2),2)):((1,8),(?{div=64},1024),((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_7 = !cute.memref<bf16, smem, "S<3,4,3> o ?{div=128} o ((2,2),(8,2),4):((64,512),(8,4096),1024)">
!memref_smem_bf16_8 = !cute.memref<bf16, smem, align<16>, "((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_9 = !cute.memref<bf16, smem, align<16>, "((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_10 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
!memref_smem_bf16_11 = !cute.memref<bf16, smem, align<16>, "((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
!memref_smem_bf16_12 = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),4096)">
!memref_smem_bf16_13 = !cute.memref<bf16, smem, align<16>, "((8,1),(2)):((1,0),(4096))">
!memref_smem_bf16_14 = !cute.memref<bf16, smem, align<16>, "((8,1)):((1,0))">
!memref_smem_bf16_15 = !cute.memref<bf16, smem, align<16>, "((8,1),1):((1,0),0)">
!memref_smem_bf16_16 = !cute.memref<bf16, smem, align<16>, "((8,1),(1)):((1,0),(0))">
!memref_smem_bf16_17 = !cute.memref<bf16, smem, align<16>, "((8,1),(4,2)):((1,0),(1024,4096))">
!memref_smem_bf16_18 = !cute.memref<bf16, smem, align<16>, "((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
!memref_smem_bf16_19 = !cute.memref<bf16, smem, align<16>, "((8,1),4):((1,0),1024)">
!memref_smem_bf16_20 = !cute.memref<bf16, smem, align<16>, "((8,1),(4)):((1,0),(1024))">
!memref_smem_bf16_21 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_22 = !cute.memref<bf16, smem, align<16>, "((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
!memref_smem_bf16_23 = !cute.memref<bf16, smem, align<1024>, S<3,4,3>, "((8,8),(64,2)):((64,512),(1,4096))">
!memref_smem_bf16_24 = !cute.memref<bf16, smem, align<4>, S<3,4,3>, "((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">
!memref_smem_bf16_25 = !cute.memref<bf16, smem, align<4>, S<3,4,3>, "((1,(2,2,2)),(1,(4,2))):((0,(1,512,8)),(0,(16,4096)))">
!memref_smem_bf16_26 = !cute.memref<bf16, smem, align<16>, S<3,4,3>, "((8,1),4,2):((1,0),1024,4096)">
!memref_smem_bf16_27 = !cute.memref<bf16, smem, align<16>, S<3,4,3>, "((8,1),(4,2)):((1,0),(1024,4096))">
!mma_bf16_bf16_f32_16x8x16_ = !cute.tiled_mma<!cute_nvgpu.sm80.mma<16x8x16, elem_type = (bf16, bf16, f32) >, atom_layout_MNK = <"(4,1,1):(1,0,0)">, permutation_MNK = <"[64:1;16:1;16:1]">>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %1 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %2 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
      %3 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %4 = cute.static : !copy_ldgsts
      %5 = cute.static : !copy_simt
      %6 = cute.static : !mma_bf16_bf16_f32_16x8x16_
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %iter_2 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %iter_3 = cute.get_iter(%arg4) : !memref_gmem_bf16_
      %iter_4 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_5 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %iter_6 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %iter_7 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %iter_8 = cute.get_iter(%arg4) : !memref_gmem_bf16_
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %7 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%7) : !cute.shape<"(?,?,?,?{div=8})">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %8 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_9 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %9 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?">
      %itup_10 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %11 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?{div=8}">
      %12 = cute.get_stride(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %e0_12, %e1_13, %e2_14, %e3_15 = cute.get_leaves(%12) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %itup_16 = cute.to_int_tuple(%e0_12) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %13 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?{i64 div=8}">
      %itup_17 = cute.to_int_tuple(%e1_13) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %14 = cute.get_scalars(%itup_17) : !cute.int_tuple<"?{i64 div=8}">
      %itup_18 = cute.to_int_tuple(%e2_14) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %15 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?{i64 div=8}">
      %lay_19 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %16 = cute.get_shape(%lay_19) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_20, %e1_21, %e2_22, %e3_23 = cute.get_leaves(%16) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_24 = cute.to_int_tuple(%e0_20) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %17 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?">
      %itup_25 = cute.to_int_tuple(%e1_21) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_25) : !cute.int_tuple<"?">
      %itup_26 = cute.to_int_tuple(%e2_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_26) : !cute.int_tuple<"?">
      %itup_27 = cute.to_int_tuple(%e3_23) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %20 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?{div=8}">
      %21 = cute.get_stride(%lay_19) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %e0_28, %e1_29, %e2_30, %e3_31 = cute.get_leaves(%21) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %itup_32 = cute.to_int_tuple(%e0_28) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %22 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?{i64 div=8}">
      %itup_33 = cute.to_int_tuple(%e1_29) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %23 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?{i64 div=8}">
      %itup_34 = cute.to_int_tuple(%e2_30) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %24 = cute.get_scalars(%itup_34) : !cute.int_tuple<"?{i64 div=8}">
      %lay_35 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %25 = cute.get_shape(%lay_35) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_36, %e1_37, %e2_38, %e3_39 = cute.get_leaves(%25) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_40 = cute.to_int_tuple(%e0_36) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %26 = cute.get_scalars(%itup_40) : !cute.int_tuple<"?">
      %itup_41 = cute.to_int_tuple(%e1_37) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %27 = cute.get_scalars(%itup_41) : !cute.int_tuple<"?">
      %itup_42 = cute.to_int_tuple(%e2_38) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %28 = cute.get_scalars(%itup_42) : !cute.int_tuple<"?">
      %itup_43 = cute.to_int_tuple(%e3_39) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %29 = cute.get_scalars(%itup_43) : !cute.int_tuple<"?{div=8}">
      %30 = cute.get_stride(%lay_35) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %e0_44, %e1_45, %e2_46, %e3_47 = cute.get_leaves(%30) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %itup_48 = cute.to_int_tuple(%e0_44) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %31 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?{i64 div=8}">
      %itup_49 = cute.to_int_tuple(%e1_45) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %32 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?{i64 div=8}">
      %itup_50 = cute.to_int_tuple(%e2_46) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %33 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?{i64 div=8}">
      %lay_51 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %34 = cute.get_shape(%lay_51) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_52, %e1_53, %e2_54, %e3_55 = cute.get_leaves(%34) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_56 = cute.to_int_tuple(%e0_52) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %35 = cute.get_scalars(%itup_56) : !cute.int_tuple<"?">
      %itup_57 = cute.to_int_tuple(%e1_53) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %36 = cute.get_scalars(%itup_57) : !cute.int_tuple<"?">
      %itup_58 = cute.to_int_tuple(%e2_54) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %37 = cute.get_scalars(%itup_58) : !cute.int_tuple<"?">
      %itup_59 = cute.to_int_tuple(%e3_55) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %38 = cute.get_scalars(%itup_59) : !cute.int_tuple<"?{div=8}">
      %39 = cute.get_stride(%lay_51) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %e0_60, %e1_61, %e2_62, %e3_63 = cute.get_leaves(%39) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %itup_64 = cute.to_int_tuple(%e0_60) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %40 = cute.get_scalars(%itup_64) : !cute.int_tuple<"?{i64 div=8}">
      %itup_65 = cute.to_int_tuple(%e1_61) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %41 = cute.get_scalars(%itup_65) : !cute.int_tuple<"?{i64 div=8}">
      %itup_66 = cute.to_int_tuple(%e2_62) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %42 = cute.get_scalars(%itup_66) : !cute.int_tuple<"?{i64 div=8}">
      %lay_67 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %43 = cute.get_shape(%lay_67) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_68, %e1_69, %e2_70, %e3_71 = cute.get_leaves(%43) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_72 = cute.to_int_tuple(%e0_68) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %44 = cute.get_scalars(%itup_72) : !cute.int_tuple<"?">
      %itup_73 = cute.to_int_tuple(%e1_69) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %45 = cute.get_scalars(%itup_73) : !cute.int_tuple<"?">
      %itup_74 = cute.to_int_tuple(%e2_70) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %46 = cute.get_scalars(%itup_74) : !cute.int_tuple<"?">
      %itup_75 = cute.to_int_tuple(%e3_71) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %47 = cute.get_scalars(%itup_75) : !cute.int_tuple<"?{div=8}">
      %48 = cute.get_stride(%lay_67) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %e0_76, %e1_77, %e2_78, %e3_79 = cute.get_leaves(%48) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %itup_80 = cute.to_int_tuple(%e0_76) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %49 = cute.get_scalars(%itup_80) : !cute.int_tuple<"?{i64 div=8}">
      %itup_81 = cute.to_int_tuple(%e1_77) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %50 = cute.get_scalars(%itup_81) : !cute.int_tuple<"?{i64 div=8}">
      %itup_82 = cute.to_int_tuple(%e2_78) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
      %51 = cute.get_scalars(%itup_82) : !cute.int_tuple<"?{i64 div=8}">
      %52 = cute.composed_get_inner(%0) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %53 = cute.composed_get_offset(%0) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_83 = cute.get_leaves(%53) : !cute.int_tuple<"0">
      %54 = cute.composed_get_outer(%0) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %55 = cute.get_shape(%54) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_84, %e1_85, %e2_86, %e3_87 = cute.get_leaves(%55) : !cute.shape<"((8,8),(64,2))">
      %56 = cute.get_stride(%54) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_88, %e1_89, %e2_90, %e3_91 = cute.get_leaves(%56) : !cute.stride<"((64,512),(1,4096))">
      %57 = cute.composed_get_inner(%1) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %58 = cute.composed_get_offset(%1) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_92 = cute.get_leaves(%58) : !cute.int_tuple<"0">
      %59 = cute.composed_get_outer(%1) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %60 = cute.get_shape(%59) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_93, %e1_94, %e2_95, %e3_96 = cute.get_leaves(%60) : !cute.shape<"((8,8),(64,2))">
      %61 = cute.get_stride(%59) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_97, %e1_98, %e2_99, %e3_100 = cute.get_leaves(%61) : !cute.stride<"((64,512),(1,4096))">
      %62 = cute.composed_get_inner(%2) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.swizzle<"S<3,4,3>">
      %63 = cute.composed_get_offset(%2) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.int_tuple<"0">
      %e0_101 = cute.get_leaves(%63) : !cute.int_tuple<"0">
      %64 = cute.composed_get_outer(%2) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.layout<"((8,8),(64,1)):((64,512),(1,0))">
      %65 = cute.get_shape(%64) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.shape<"((8,8),(64,1))">
      %e0_102, %e1_103, %e2_104, %e3_105 = cute.get_leaves(%65) : !cute.shape<"((8,8),(64,1))">
      %66 = cute.get_stride(%64) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.stride<"((64,512),(1,0))">
      %e0_106, %e1_107, %e2_108, %e3_109 = cute.get_leaves(%66) : !cute.stride<"((64,512),(1,0))">
      %67 = cute.composed_get_inner(%3) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %68 = cute.composed_get_offset(%3) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_110 = cute.get_leaves(%68) : !cute.int_tuple<"0">
      %69 = cute.composed_get_outer(%3) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %70 = cute.get_shape(%69) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_111, %e1_112, %e2_113, %e3_114 = cute.get_leaves(%70) : !cute.shape<"((8,8),(64,2))">
      %71 = cute.get_stride(%69) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_115, %e1_116, %e2_117, %e3_118 = cute.get_leaves(%71) : !cute.stride<"((64,512),(1,4096))">
      %72 = cute.static : !cute.tile<"[16:1;64:1]">
      %e0_119, %e1_120 = cute.get_leaves(%72) : !cute.tile<"[16:1;64:1]">
      %73 = cute.get_shape(%e0_119) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_121 = cute.get_leaves(%73) : !cute.shape<"16">
      %74 = cute.get_stride(%e0_119) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_122 = cute.get_leaves(%74) : !cute.stride<"1">
      %75 = cute.get_shape(%e1_120) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_123 = cute.get_leaves(%75) : !cute.shape<"64">
      %76 = cute.get_stride(%e1_120) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_124 = cute.get_leaves(%76) : !cute.stride<"1">
      %77 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %78 = cute.get_shape(%77) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
      %e0_125, %e1_126, %e2_127 = cute.get_leaves(%78) : !cute.shape<"((8,16),8)">
      %79 = cute.get_stride(%77) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
      %e0_128, %e1_129, %e2_130 = cute.get_leaves(%79) : !cute.stride<"((128,1),16)">
      %80 = cute.static : !cute.layout<"1:0">
      %81 = cute.get_shape(%80) : (!cute.layout<"1:0">) -> !cute.shape<"1">
      %e0_131 = cute.get_leaves(%81) : !cute.shape<"1">
      %82 = cute.get_stride(%80) : (!cute.layout<"1:0">) -> !cute.stride<"0">
      %e0_132 = cute.get_leaves(%82) : !cute.stride<"0">
      %83 = cute.static : !cute.layout<"(1,8):(0,1)">
      %84 = cute.get_shape(%83) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_133, %e1_134 = cute.get_leaves(%84) : !cute.shape<"(1,8)">
      %85 = cute.get_stride(%83) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_135, %e1_136 = cute.get_leaves(%85) : !cute.stride<"(0,1)">
      %86 = cute.static : !cute.layout<"(1,8):(0,1)">
      %87 = cute.get_shape(%86) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_137, %e1_138 = cute.get_leaves(%87) : !cute.shape<"(1,8)">
      %88 = cute.get_stride(%86) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_139, %e1_140 = cute.get_leaves(%88) : !cute.stride<"(0,1)">
      %89 = cute.static : !cute.tile<"[16:1;64:1]">
      %e0_141, %e1_142 = cute.get_leaves(%89) : !cute.tile<"[16:1;64:1]">
      %90 = cute.get_shape(%e0_141) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_143 = cute.get_leaves(%90) : !cute.shape<"16">
      %91 = cute.get_stride(%e0_141) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_144 = cute.get_leaves(%91) : !cute.stride<"1">
      %92 = cute.get_shape(%e1_142) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_145 = cute.get_leaves(%92) : !cute.shape<"64">
      %93 = cute.get_stride(%e1_142) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_146 = cute.get_leaves(%93) : !cute.stride<"1">
      %94 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %95 = cute.get_shape(%94) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
      %e0_147, %e1_148, %e2_149 = cute.get_leaves(%95) : !cute.shape<"((8,16),8)">
      %96 = cute.get_stride(%94) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
      %e0_150, %e1_151, %e2_152 = cute.get_leaves(%96) : !cute.stride<"((128,1),16)">
      %97 = cute.static : !cute.layout<"1:0">
      %98 = cute.get_shape(%97) : (!cute.layout<"1:0">) -> !cute.shape<"1">
      %e0_153 = cute.get_leaves(%98) : !cute.shape<"1">
      %99 = cute.get_stride(%97) : (!cute.layout<"1:0">) -> !cute.stride<"0">
      %e0_154 = cute.get_leaves(%99) : !cute.stride<"0">
      %100 = cute.static : !cute.layout<"(1,8):(0,1)">
      %101 = cute.get_shape(%100) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_155, %e1_156 = cute.get_leaves(%101) : !cute.shape<"(1,8)">
      %102 = cute.get_stride(%100) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_157, %e1_158 = cute.get_leaves(%102) : !cute.stride<"(0,1)">
      %103 = cute.static : !cute.layout<"(1,8):(0,1)">
      %104 = cute.get_shape(%103) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_159, %e1_160 = cute.get_leaves(%104) : !cute.shape<"(1,8)">
      %105 = cute.get_stride(%103) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_161, %e1_162 = cute.get_leaves(%105) : !cute.stride<"(0,1)">
      %106 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %107 = cute.get_shape(%106) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
      %e0_163, %e1_164, %e2_165, %e3_166 = cute.get_leaves(%107) : !cute.shape<"(32,4,1,1)">
      %108 = cute.get_stride(%106) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
      %e0_167, %e1_168, %e2_169, %e3_170 = cute.get_leaves(%108) : !cute.stride<"(1,32,0,0)">
      %109 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_171, %e1_172, %e2_173 = cute.get_leaves(%109) : !cute.tile<"[64:1;16:1;16:1]">
      %110 = cute.get_shape(%e0_171) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_174 = cute.get_leaves(%110) : !cute.shape<"64">
      %111 = cute.get_stride(%e0_171) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_175 = cute.get_leaves(%111) : !cute.stride<"1">
      %112 = cute.get_shape(%e1_172) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_176 = cute.get_leaves(%112) : !cute.shape<"16">
      %113 = cute.get_stride(%e1_172) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_177 = cute.get_leaves(%113) : !cute.stride<"1">
      %114 = cute.get_shape(%e2_173) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_178 = cute.get_leaves(%114) : !cute.shape<"16">
      %115 = cute.get_stride(%e2_173) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_179 = cute.get_leaves(%115) : !cute.stride<"1">
      %116 = cute.static : !cute.layout<"32:1">
      %117 = cute.get_shape(%116) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_180 = cute.get_leaves(%117) : !cute.shape<"32">
      %118 = cute.get_stride(%116) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_181 = cute.get_leaves(%118) : !cute.stride<"1">
      %119 = cute.static : !cute.shape<"(16,8,16)">
      %e0_182, %e1_183, %e2_184 = cute.get_leaves(%119) : !cute.shape<"(16,8,16)">
      %120 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %121 = cute.get_shape(%120) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
      %e0_185, %e1_186, %e2_187, %e3_188, %e4 = cute.get_leaves(%121) : !cute.shape<"((4,8),(2,2,2))">
      %122 = cute.get_stride(%120) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
      %e0_189, %e1_190, %e2_191, %e3_192, %e4_193 = cute.get_leaves(%122) : !cute.stride<"((32,1),(16,8,128))">
      %123 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %124 = cute.get_shape(%123) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_194, %e1_195, %e2_196, %e3_197 = cute.get_leaves(%124) : !cute.shape<"((4,8),(2,2))">
      %125 = cute.get_stride(%123) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
      %e0_198, %e1_199, %e2_200, %e3_201 = cute.get_leaves(%125) : !cute.stride<"((16,1),(8,64))">
      %126 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %127 = cute.get_shape(%126) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_202, %e1_203, %e2_204, %e3_205 = cute.get_leaves(%127) : !cute.shape<"((4,8),(2,2))">
      %128 = cute.get_stride(%126) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
      %e0_206, %e1_207, %e2_208, %e3_209 = cute.get_leaves(%128) : !cute.stride<"((32,1),(16,8))">
      %129 = nvvm.read.ptx.sreg.tid.x : i32
      %130 = nvvm.read.ptx.sreg.tid.y : i32
      %131 = nvvm.read.ptx.sreg.tid.z : i32
      %132 = nvvm.read.ptx.sreg.ctaid.x : i32
      %133 = nvvm.read.ptx.sreg.ctaid.y : i32
      %134 = nvvm.read.ptx.sreg.ctaid.z : i32
      %lay_210 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %135 = cute.get_shape(%lay_210) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_211, %e1_212, %e2_213, %e3_214 = cute.get_leaves(%135) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_215 = cute.to_int_tuple(%e0_211) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %136 = cute.get_scalars(%itup_215) : !cute.int_tuple<"?">
      %itup_216 = cute.to_int_tuple(%e1_212) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %137 = cute.get_scalars(%itup_216) : !cute.int_tuple<"?">
      %itup_217 = cute.to_int_tuple(%e2_213) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %138 = cute.get_scalars(%itup_217) : !cute.int_tuple<"?">
      %itup_218 = cute.to_int_tuple(%e3_214) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %139 = cute.get_scalars(%itup_218) : !cute.int_tuple<"?{div=8}">
      %int_tuple = cute.make_int_tuple(%itup_216) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %tile = cute.make_tile() : () -> !cute.tile<"64:1">
      %shp = cute.ceil_div(%int_tuple, %tile) : !cute.int_tuple<"?">, !cute.tile<"64:1">
      %e0_219 = cute.get_leaves(%shp) : !cute.int_tuple<"?">
      %140 = cute.get_scalars(%e0_219) : !cute.int_tuple<"?">
      %int_tuple_220 = cute.make_int_tuple(%134) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_219, %int_tuple_220) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %141 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %int_tuple_221 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sub_222 = cute.tuple_sub(%sub, %int_tuple_221) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %142 = cute.get_scalars(%sub_222) : !cute.int_tuple<"?">
      %lay_223 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %143 = cute.get_shape(%lay_223) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_224, %e1_225, %e2_226, %e3_227 = cute.get_leaves(%143) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_228 = cute.to_int_tuple(%e0_224) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %144 = cute.get_scalars(%itup_228) : !cute.int_tuple<"?">
      %itup_229 = cute.to_int_tuple(%e1_225) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %145 = cute.get_scalars(%itup_229) : !cute.int_tuple<"?">
      %itup_230 = cute.to_int_tuple(%e2_226) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %146 = cute.get_scalars(%itup_230) : !cute.int_tuple<"?">
      %itup_231 = cute.to_int_tuple(%e3_227) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %147 = cute.get_scalars(%itup_231) : !cute.int_tuple<"?{div=8}">
      %int_tuple_232 = cute.make_int_tuple(%itup_229) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %tile_233 = cute.make_tile() : () -> !cute.tile<"64:1">
      %shp_234 = cute.ceil_div(%int_tuple_232, %tile_233) : !cute.int_tuple<"?">, !cute.tile<"64:1">
      %e0_235 = cute.get_leaves(%shp_234) : !cute.int_tuple<"?">
      %148 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?">
      %int_tuple_236 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sub_237 = cute.tuple_sub(%e0_235, %int_tuple_236) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %149 = cute.get_scalars(%sub_237) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_238 = cute.get_iter(%slice) : !memref_gmem_bf16_1
      %iter_239 = cute.get_iter(%slice) : !memref_gmem_bf16_1
      %tile_240 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_241 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view = cute.local_tile(%slice, %tile_240, %coord_241) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_242 = cute.get_iter(%tiled_view) : !memref_gmem_bf16_2
      %coord_243 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_244 = cute.slice(%arg1, %coord_243) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_245 = cute.get_iter(%slice_244) : !memref_gmem_bf16_1
      %iter_246 = cute.get_iter(%slice_244) : !memref_gmem_bf16_1
      %tile_247 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_248 = cute.make_coord() : () -> !cute.coord<"(_,0)">
      %tiled_view_249 = cute.local_tile(%slice_244, %tile_247, %coord_248) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(_,0)">) -> !memref_gmem_bf16_3
      %iter_250 = cute.get_iter(%tiled_view_249) : !memref_gmem_bf16_3
      %coord_251 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_252 = cute.slice(%arg2, %coord_251) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_253 = cute.get_iter(%slice_252) : !memref_gmem_bf16_1
      %iter_254 = cute.get_iter(%slice_252) : !memref_gmem_bf16_1
      %tile_255 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_256 = cute.make_coord() : () -> !cute.coord<"(_,0)">
      %tiled_view_257 = cute.local_tile(%slice_252, %tile_255, %coord_256) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(_,0)">) -> !memref_gmem_bf16_3
      %iter_258 = cute.get_iter(%tiled_view_257) : !memref_gmem_bf16_3
      %coord_259 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %slice_260 = cute.slice(%arg4, %coord_259) : !memref_gmem_bf16_, !cute.coord<"(?,?,_,_)">
      %iter_261 = cute.get_iter(%slice_260) : !memref_gmem_bf16_1
      %iter_262 = cute.get_iter(%slice_260) : !memref_gmem_bf16_1
      %tile_263 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
      %coord_264 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %tiled_view_265 = cute.local_tile(%slice_260, %tile_263, %coord_264) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,_)">) -> !memref_gmem_bf16_4
      %iter_266 = cute.get_iter(%tiled_view_265) : !memref_gmem_bf16_4
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %int_tuple_267 = cute.make_int_tuple() : () -> !cute.int_tuple<"57344">
      %ptr = cute.add_offset(%smem_ptr, %int_tuple_267) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"57344">) -> !cute.ptr<i8, smem, align<1024>>
      %smem_size = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c57344_i32 = arith.constant 57344 : i32
      %150 = arith.cmpi sge, %smem_size, %c57344_i32 : i32
      cf.assert %150, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 57344 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %int_tuple_268 = cute.make_int_tuple() : () -> !cute.int_tuple<"0">
      %ptr_269 = cute.add_offset(%smem_ptr, %int_tuple_268) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_270 = cute.make_int_tuple() : () -> !cute.int_tuple<"16384">
      %ptr_271 = cute.add_offset(%smem_ptr, %int_tuple_270) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_272 = cute.make_int_tuple() : () -> !cute.int_tuple<"32768">
      %ptr_273 = cute.add_offset(%smem_ptr, %int_tuple_272) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_274 = cute.make_int_tuple() : () -> !cute.int_tuple<"49152">
      %ptr_275 = cute.add_offset(%smem_ptr, %int_tuple_274) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_276 = cute.recast_iter(%ptr_269) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view = cute.make_view(%iter_276, %0) : !memref_smem_bf16_
      %iter_277 = cute.get_iter(%view) : !memref_smem_bf16_
      %iter_278 = cute.recast_iter(%ptr_271) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_279 = cute.make_view(%iter_278, %1) : !memref_smem_bf16_
      %iter_280 = cute.get_iter(%view_279) : !memref_smem_bf16_
      %iter_281 = cute.recast_iter(%ptr_273) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_282 = cute.make_view(%iter_281, %1) : !memref_smem_bf16_
      %iter_283 = cute.get_iter(%view_282) : !memref_smem_bf16_
      %iter_284 = cute.recast_iter(%ptr_275) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_285 = cute.make_view(%iter_284, %2) : !memref_smem_bf16_1
      %iter_286 = cute.get_iter(%view_285) : !memref_smem_bf16_1
      %shape = cute.make_shape() : () -> !cute.shape<"(128,64)">
      %stride = cute.make_stride() : () -> !cute.stride<"(64,1)">
      %lay_287 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,64):(64,1)">
      %151 = cute.composition(%view_282, %lay_287) : (!memref_smem_bf16_, !cute.layout<"(128,64):(64,1)">) -> !memref_smem_bf16_2
      %iter_288 = cute.get_iter(%151) : !memref_smem_bf16_2
      %coord_289 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%4, %tiled_view, %coord_289) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_290 = cute.get_iter(%src_partitioned) : !memref_gmem_bf16_5
      %coord_291 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned = cute.tiled.copy.partition_D(%4, %view, %coord_291) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_292 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_3
      %coord_293 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_294 = cute.tiled.copy.partition_S(%4, %tiled_view_249, %coord_293) : (!copy_ldgsts, !memref_gmem_bf16_3, !cute.coord<"?">) -> !memref_gmem_bf16_6
      %iter_295 = cute.get_iter(%src_partitioned_294) : !memref_gmem_bf16_6
      %coord_296 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_297 = cute.tiled.copy.partition_D(%4, %view_279, %coord_296) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_298 = cute.get_iter(%dst_partitioned_297) : !memref_smem_bf16_3
      %coord_299 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_300 = cute.tiled.copy.partition_S(%4, %tiled_view_257, %coord_299) : (!copy_ldgsts, !memref_gmem_bf16_3, !cute.coord<"?">) -> !memref_gmem_bf16_6
      %iter_301 = cute.get_iter(%src_partitioned_300) : !memref_gmem_bf16_6
      %coord_302 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_303 = cute.tiled.copy.partition_D(%4, %view_282, %coord_302) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_304 = cute.get_iter(%dst_partitioned_303) : !memref_smem_bf16_3
      %coord_305 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_306 = cute.tiled.copy.partition_S(%4, %tiled_view_265, %coord_305) : (!copy_ldgsts, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_7
      %iter_307 = cute.get_iter(%src_partitioned_306) : !memref_gmem_bf16_7
      %coord_308 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_309 = cute.tiled.copy.partition_D(%4, %view_285, %coord_308) : (!copy_ldgsts, !memref_smem_bf16_1, !cute.coord<"?">) -> !memref_smem_bf16_4
      %iter_310 = cute.get_iter(%dst_partitioned_309) : !memref_smem_bf16_4
      %coord_311 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %ptn_A = cute.tiled.mma.partition A (%6, %view, %coord_311) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_5
      %iter_312 = cute.get_iter(%ptn_A) : !memref_smem_bf16_5
      %frg_A = cute.mma.make_fragment A (%6, %ptn_A) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_5) -> !memref_rmem_bf16_
      %iter_313 = cute.get_iter(%frg_A) : !memref_rmem_bf16_
      %coord_314 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %ptn_B = cute.tiled.mma.partition B (%6, %view_279, %coord_314) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_6
      %iter_315 = cute.get_iter(%ptn_B) : !memref_smem_bf16_6
      %frg_B = cute.mma.make_fragment B (%6, %ptn_B) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_6) -> !memref_rmem_bf16_1
      %iter_316 = cute.get_iter(%frg_B) : !memref_rmem_bf16_1
      %coord_317 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %ptn_B_318 = cute.tiled.mma.partition B (%6, %151, %coord_317) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_2, !cute.coord<"?">) -> !memref_smem_bf16_7
      %iter_319 = cute.get_iter(%ptn_B_318) : !memref_smem_bf16_7
      %frg_B_320 = cute.mma.make_fragment B (%6, %ptn_B_318) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_7) -> !memref_rmem_bf16_2
      %iter_321 = cute.get_iter(%frg_B_320) : !memref_rmem_bf16_2
      %shape_322 = cute.make_shape() : () -> !cute.shape<"(64,128)">
      %152 = cute.tiled.mma.partition_shape C (%6, %shape_322) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,128)">) -> !cute.shape<"((2,2),1,16)">
      %e0_323, %e1_324, %e2_325, %e3_326 = cute.get_leaves(%152) : !cute.shape<"((2,2),1,16)">
      %shape_327 = cute.make_shape() : () -> !cute.shape<"((2,2),1,16)">
      %lay_328 = cute.make_layout(%shape_327) : !cute.layout<"((2,2),1,16):((1,2),0,4)">
      %rmem = cute.memref.alloca(%lay_328) : !memref_rmem_f32_
      %iter_329 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_330 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %sz = cute.size(%rmem) : (!memref_rmem_f32_) -> !cute.int_tuple<"64">
      %e0_331 = cute.get_leaves(%sz) : !cute.int_tuple<"64">
      %lay_332 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %153 = cute.get_shape(%lay_332) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_333, %e1_334, %e2_335, %e3_336 = cute.get_leaves(%153) : !cute.shape<"((2,2),1,16)">
      %int_tuple_337 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %res = cute.tuple.product(%int_tuple_337) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_338 = cute.get_leaves(%res) : !cute.int_tuple<"64">
      %cst = arith.constant 0.000000e+00 : f32
      %154 = vector.splat %cst : vector<64xf32>
      %int_tuple_339 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_340 = cute.size(%int_tuple_339) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_341 = cute.get_leaves(%sz_340) : !cute.int_tuple<"64">
      %int_tuple_342 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_343 = cute.size(%int_tuple_342) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_344 = cute.get_leaves(%sz_343) : !cute.int_tuple<"64">
      cute.memref.store_vec %154, %rmem : !memref_rmem_f32_
      %shape_345 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %shape_346 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_347 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %shape_348 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_349 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %shape_350 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_351 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %155 = cute.static : !cute.layout<"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">
      %156 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_352, %e1_353, %e2_354 = cute.get_leaves(%156) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_355 = cute.size(%e0_352) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_356 = cute.get_leaves(%sz_355) : !cute.int_tuple<"64">
      %157 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_357, %e1_358, %e2_359 = cute.get_leaves(%157) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_360 = cute.size(%e2_359) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_361 = cute.get_leaves(%sz_360) : !cute.int_tuple<"16">
      %tile_362 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %158 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %159 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %160 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_363, %e1_364, %e2_365 = cute.get_leaves(%160) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_366 = cute.size(%e1_364) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_367 = cute.get_leaves(%sz_366) : !cute.int_tuple<"16">
      %161 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_368, %e1_369, %e2_370 = cute.get_leaves(%161) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_371 = cute.size(%e2_370) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_372 = cute.get_leaves(%sz_371) : !cute.int_tuple<"16">
      %tile_373 = cute.make_tile() : () -> !cute.tile<"[16:1;16:1]">
      %162 = cute.make_tiled_copy(%atom_347) : !copy_ldsm_4_1
      %163 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %164 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_374, %e1_375, %e2_376 = cute.get_leaves(%164) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_377 = cute.size(%e1_375) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_378 = cute.get_leaves(%sz_377) : !cute.int_tuple<"16">
      %165 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_379, %e1_380, %e2_381 = cute.get_leaves(%165) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_382 = cute.size(%e2_381) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_383 = cute.get_leaves(%sz_382) : !cute.int_tuple<"16">
      %tile_384 = cute.make_tile() : () -> !cute.tile<"[16:1;16:1]">
      %166 = cute.make_tiled_copy(%atom_349) : !copy_ldsm_4_2
      %167 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %168 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_385, %e1_386, %e2_387 = cute.get_leaves(%168) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_388 = cute.size(%e0_385) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_389 = cute.get_leaves(%sz_388) : !cute.int_tuple<"64">
      %169 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_390, %e1_391, %e2_392 = cute.get_leaves(%169) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_393 = cute.size(%e1_391) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_394 = cute.get_leaves(%sz_393) : !cute.int_tuple<"16">
      %tile_395 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %170 = cute.make_tiled_copy(%atom_351) : !copy_ldsm_4_3
      %coord_396 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_397 = cute.tiled.copy.partition_S(%158, %view, %coord_396) : (!copy_ldsm_4_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_8
      %iter_398 = cute.get_iter(%src_partitioned_397) : !memref_smem_bf16_8
      %retiled = cute.tiled.copy.retile(%158, %frg_A) : (!copy_ldsm_4_, !memref_rmem_bf16_) -> !memref_rmem_bf16_3
      %iter_399 = cute.get_iter(%retiled) : !memref_rmem_bf16_3
      %coord_400 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_401 = cute.tiled.copy.partition_S(%162, %view_279, %coord_400) : (!copy_ldsm_4_1, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_9
      %iter_402 = cute.get_iter(%src_partitioned_401) : !memref_smem_bf16_9
      %retiled_403 = cute.tiled.copy.retile(%162, %frg_B) : (!copy_ldsm_4_1, !memref_rmem_bf16_1) -> !memref_rmem_bf16_4
      %iter_404 = cute.get_iter(%retiled_403) : !memref_rmem_bf16_4
      %coord_405 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_406 = cute.tiled.copy.partition_S(%166, %151, %coord_405) : (!copy_ldsm_4_2, !memref_smem_bf16_2, !cute.coord<"?">) -> !memref_smem_bf16_10
      %iter_407 = cute.get_iter(%src_partitioned_406) : !memref_smem_bf16_10
      %retiled_408 = cute.tiled.copy.retile(%166, %frg_B_320) : (!copy_ldsm_4_2, !memref_rmem_bf16_2) -> !memref_rmem_bf16_5
      %iter_409 = cute.get_iter(%retiled_408) : !memref_rmem_bf16_5
      %coord_410 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_411 = cute.tiled.copy.partition_S(%170, %view_285, %coord_410) : (!copy_ldsm_4_3, !memref_smem_bf16_1, !cute.coord<"?">) -> !memref_smem_bf16_11
      %iter_412 = cute.get_iter(%src_partitioned_411) : !memref_smem_bf16_11
      %lay_413 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %171 = cute.get_shape(%lay_413) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_414, %e1_415, %e2_416, %e3_417 = cute.get_leaves(%171) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_418 = cute.to_int_tuple(%e0_414) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %172 = cute.get_scalars(%itup_418) : !cute.int_tuple<"?">
      %itup_419 = cute.to_int_tuple(%e1_415) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %173 = cute.get_scalars(%itup_419) : !cute.int_tuple<"?">
      %itup_420 = cute.to_int_tuple(%e2_416) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %174 = cute.get_scalars(%itup_420) : !cute.int_tuple<"?">
      %itup_421 = cute.to_int_tuple(%e3_417) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %175 = cute.get_scalars(%itup_421) : !cute.int_tuple<"?{div=8}">
      %shape_422 = cute.make_shape(%itup_418, %itup_419, %itup_420, %itup_421) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %176 = cute.make_identity_tensor(%shape_422) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_423 = cute.get_iter(%176) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_424, %e1_425, %e2_426, %e3_427 = cute.get_leaves(%iter_423) : !cute.int_tuple<"(0,0,0,0)">
      %lay_428 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %177 = cute.get_shape(%lay_428) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_429, %e1_430, %e2_431, %e3_432 = cute.get_leaves(%177) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_433 = cute.to_int_tuple(%e0_429) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %178 = cute.get_scalars(%itup_433) : !cute.int_tuple<"?">
      %itup_434 = cute.to_int_tuple(%e1_430) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %179 = cute.get_scalars(%itup_434) : !cute.int_tuple<"?">
      %itup_435 = cute.to_int_tuple(%e2_431) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %180 = cute.get_scalars(%itup_435) : !cute.int_tuple<"?">
      %itup_436 = cute.to_int_tuple(%e3_432) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %181 = cute.get_scalars(%itup_436) : !cute.int_tuple<"?{div=8}">
      %shape_437 = cute.make_shape(%itup_433, %itup_434, %itup_435, %itup_436) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %182 = cute.make_identity_tensor(%shape_437) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_438 = cute.get_iter(%182) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_439, %e1_440, %e2_441, %e3_442 = cute.get_leaves(%iter_438) : !cute.int_tuple<"(0,0,0,0)">
      %lay_443 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %183 = cute.get_shape(%lay_443) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_444, %e1_445, %e2_446, %e3_447 = cute.get_leaves(%183) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_448 = cute.to_int_tuple(%e0_444) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %184 = cute.get_scalars(%itup_448) : !cute.int_tuple<"?">
      %itup_449 = cute.to_int_tuple(%e1_445) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %185 = cute.get_scalars(%itup_449) : !cute.int_tuple<"?">
      %itup_450 = cute.to_int_tuple(%e2_446) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %186 = cute.get_scalars(%itup_450) : !cute.int_tuple<"?">
      %itup_451 = cute.to_int_tuple(%e3_447) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %187 = cute.get_scalars(%itup_451) : !cute.int_tuple<"?{div=8}">
      %shape_452 = cute.make_shape(%itup_448, %itup_449, %itup_450, %itup_451) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %188 = cute.make_identity_tensor(%shape_452) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_453 = cute.get_iter(%188) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_454, %e1_455, %e2_456, %e3_457 = cute.get_leaves(%iter_453) : !cute.int_tuple<"(0,0,0,0)">
      %coord_458 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_459 = cute.slice(%176, %coord_458) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_460 = cute.get_iter(%slice_459) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_461, %e1_462, %e2_463, %e3_464 = cute.get_leaves(%iter_460) : !cute.int_tuple<"(?,0,?,0)">
      %189 = cute.get_scalars(%e0_461) : !cute.int_tuple<"?">
      %190 = cute.get_scalars(%e2_463) : !cute.int_tuple<"?">
      %iter_465 = cute.get_iter(%slice_459) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_466, %e1_467, %e2_468, %e3_469 = cute.get_leaves(%iter_465) : !cute.int_tuple<"(?,0,?,0)">
      %191 = cute.get_scalars(%e0_466) : !cute.int_tuple<"?">
      %192 = cute.get_scalars(%e2_468) : !cute.int_tuple<"?">
      %tile_470 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_471 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_472 = cute.local_tile(%slice_459, %tile_470, %coord_471) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_473 = cute.get_iter(%tiled_view_472) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_474, %e1_475, %e2_476, %e3_477 = cute.get_leaves(%iter_473) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %193 = cute.get_scalars(%e0_474) : !cute.int_tuple<"?">
      %194 = cute.get_scalars(%e1_475) : !cute.int_tuple<"?{div=64}">
      %195 = cute.get_scalars(%e2_476) : !cute.int_tuple<"?">
      %coord_478 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_479 = cute.slice(%182, %coord_478) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_480 = cute.get_iter(%slice_479) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_481, %e1_482, %e2_483, %e3_484 = cute.get_leaves(%iter_480) : !cute.int_tuple<"(?,0,?,0)">
      %196 = cute.get_scalars(%e0_481) : !cute.int_tuple<"?">
      %197 = cute.get_scalars(%e2_483) : !cute.int_tuple<"?">
      %iter_485 = cute.get_iter(%slice_479) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_486, %e1_487, %e2_488, %e3_489 = cute.get_leaves(%iter_485) : !cute.int_tuple<"(?,0,?,0)">
      %198 = cute.get_scalars(%e0_486) : !cute.int_tuple<"?">
      %199 = cute.get_scalars(%e2_488) : !cute.int_tuple<"?">
      %tile_490 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_491 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_492 = cute.local_tile(%slice_479, %tile_490, %coord_491) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_493 = cute.get_iter(%tiled_view_492) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_494, %e1_495, %e2_496, %e3_497 = cute.get_leaves(%iter_493) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %200 = cute.get_scalars(%e0_494) : !cute.int_tuple<"?">
      %201 = cute.get_scalars(%e1_495) : !cute.int_tuple<"?{div=64}">
      %202 = cute.get_scalars(%e2_496) : !cute.int_tuple<"?">
      %coord_498 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %slice_499 = cute.slice(%188, %coord_498) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,?,_,_)">
      %iter_500 = cute.get_iter(%slice_499) : !cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">
      %e0_501, %e1_502, %e2_503, %e3_504 = cute.get_leaves(%iter_500) : !cute.int_tuple<"(?,?,0,0)">
      %203 = cute.get_scalars(%e0_501) : !cute.int_tuple<"?">
      %204 = cute.get_scalars(%e1_502) : !cute.int_tuple<"?">
      %iter_505 = cute.get_iter(%slice_499) : !cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">
      %e0_506, %e1_507, %e2_508, %e3_509 = cute.get_leaves(%iter_505) : !cute.int_tuple<"(?,?,0,0)">
      %205 = cute.get_scalars(%e0_506) : !cute.int_tuple<"?">
      %206 = cute.get_scalars(%e1_507) : !cute.int_tuple<"?">
      %tile_510 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
      %coord_511 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %tiled_view_512 = cute.local_tile(%slice_499, %tile_510, %coord_511) : (!cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,_)">) -> !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">
      %iter_513 = cute.get_iter(%tiled_view_512) : !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">
      %e0_514, %e1_515, %e2_516, %e3_517 = cute.get_leaves(%iter_513) : !cute.int_tuple<"(?,?,?{div=64},0)">
      %207 = cute.get_scalars(%e0_514) : !cute.int_tuple<"?">
      %208 = cute.get_scalars(%e1_515) : !cute.int_tuple<"?">
      %209 = cute.get_scalars(%e2_516) : !cute.int_tuple<"?{div=64}">
      %coord_518 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_519 = cute.tiled.copy.partition_S(%4, %tiled_view_472, %coord_518) : (!copy_ldgsts, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_520 = cute.get_iter(%src_partitioned_519) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_521, %e1_522, %e2_523, %e3_524 = cute.get_leaves(%iter_520) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %210 = cute.get_scalars(%e0_521) : !cute.int_tuple<"?">
      %211 = cute.get_scalars(%e1_522) : !cute.int_tuple<"?">
      %212 = cute.get_scalars(%e2_523) : !cute.int_tuple<"?">
      %213 = cute.get_scalars(%e3_524) : !cute.int_tuple<"?{div=8}">
      %coord_525 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_526 = cute.tiled.copy.partition_S(%4, %tiled_view_492, %coord_525) : (!copy_ldgsts, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_527 = cute.get_iter(%src_partitioned_526) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_528, %e1_529, %e2_530, %e3_531 = cute.get_leaves(%iter_527) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %214 = cute.get_scalars(%e0_528) : !cute.int_tuple<"?">
      %215 = cute.get_scalars(%e1_529) : !cute.int_tuple<"?">
      %216 = cute.get_scalars(%e2_530) : !cute.int_tuple<"?">
      %217 = cute.get_scalars(%e3_531) : !cute.int_tuple<"?{div=8}">
      %coord_532 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_533 = cute.tiled.copy.partition_S(%4, %tiled_view_512, %coord_532) : (!copy_ldgsts, !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %iter_534 = cute.get_iter(%src_partitioned_533) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %e0_535, %e1_536, %e2_537, %e3_538 = cute.get_leaves(%iter_534) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %218 = cute.get_scalars(%e0_535) : !cute.int_tuple<"?">
      %219 = cute.get_scalars(%e1_536) : !cute.int_tuple<"?">
      %220 = cute.get_scalars(%e2_537) : !cute.int_tuple<"?">
      %221 = cute.get_scalars(%e3_538) : !cute.int_tuple<"?{div=8}">
      %lay_539 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_3
      %222 = cute.get_shape(%lay_539) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_540, %e1_541, %e2_542, %e3_543 = cute.get_leaves(%222) : !cute.shape<"((8,1),4,2)">
      %sz_544 = cute.size(%dst_partitioned) <{mode = [1]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"4">
      %e0_545 = cute.get_leaves(%sz_544) : !cute.int_tuple<"4">
      %sz_546 = cute.size(%dst_partitioned) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_547 = cute.get_leaves(%sz_546) : !cute.int_tuple<"2">
      %sz_548 = cute.size(%dst_partitioned) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_549 = cute.get_leaves(%sz_548) : !cute.int_tuple<"2">
      %shape_550 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_551 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_552 = cute.make_layout(%shape_550, %stride_551) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_553 = cute.memref.alloca(%lay_552) : !memref_rmem_i8_
      %iter_554 = cute.get_iter(%rmem_553) : !memref_rmem_i8_
      %iter_555 = cute.get_iter(%rmem_553) : !memref_rmem_i8_
      %lay_556 = cute.get_layout(%dst_partitioned_297) : !memref_smem_bf16_3
      %223 = cute.get_shape(%lay_556) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_557, %e1_558, %e2_559, %e3_560 = cute.get_leaves(%223) : !cute.shape<"((8,1),4,2)">
      %sz_561 = cute.size(%dst_partitioned_297) <{mode = [1]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"4">
      %e0_562 = cute.get_leaves(%sz_561) : !cute.int_tuple<"4">
      %sz_563 = cute.size(%dst_partitioned_297) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_564 = cute.get_leaves(%sz_563) : !cute.int_tuple<"2">
      %sz_565 = cute.size(%dst_partitioned_297) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_566 = cute.get_leaves(%sz_565) : !cute.int_tuple<"2">
      %shape_567 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_568 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_569 = cute.make_layout(%shape_567, %stride_568) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_570 = cute.memref.alloca(%lay_569) : !memref_rmem_i8_
      %iter_571 = cute.get_iter(%rmem_570) : !memref_rmem_i8_
      %iter_572 = cute.get_iter(%rmem_570) : !memref_rmem_i8_
      %lay_573 = cute.get_layout(%rmem_553) : !memref_rmem_i8_
      %224 = cute.get_shape(%lay_573) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_574, %e1_575, %e2_576 = cute.get_leaves(%224) : !cute.shape<"(1,4,2)">
      %coord_577 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_578 = cute.slice(%src_partitioned_519, %coord_577) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_579 = cute.get_iter(%slice_578) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_580, %e1_581, %e2_582, %e3_583 = cute.get_leaves(%iter_579) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %225 = cute.get_scalars(%e0_580) : !cute.int_tuple<"?">
      %226 = cute.get_scalars(%e1_581) : !cute.int_tuple<"?">
      %227 = cute.get_scalars(%e2_582) : !cute.int_tuple<"?">
      %228 = cute.get_scalars(%e3_583) : !cute.int_tuple<"?{div=8}">
      %iter_584 = cute.get_iter(%slice_578) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_585, %e1_586, %e2_587, %e3_588 = cute.get_leaves(%iter_584) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %229 = cute.get_scalars(%e0_585) : !cute.int_tuple<"?">
      %230 = cute.get_scalars(%e1_586) : !cute.int_tuple<"?">
      %231 = cute.get_scalars(%e2_587) : !cute.int_tuple<"?">
      %232 = cute.get_scalars(%e3_588) : !cute.int_tuple<"?{div=8}">
      %iter_589 = cute.get_iter(%slice_578) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_590, %e1_591, %e2_592, %e3_593 = cute.get_leaves(%iter_589) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %233 = cute.get_scalars(%e0_590) : !cute.int_tuple<"?">
      %234 = cute.get_scalars(%e1_591) : !cute.int_tuple<"?">
      %235 = cute.get_scalars(%e2_592) : !cute.int_tuple<"?">
      %236 = cute.get_scalars(%e3_593) : !cute.int_tuple<"?{div=8}">
      %lay_594 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %237 = cute.get_shape(%lay_594) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_595, %e1_596, %e2_597, %e3_598 = cute.get_leaves(%237) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_599 = cute.to_int_tuple(%e0_595) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %238 = cute.get_scalars(%itup_599) : !cute.int_tuple<"?">
      %itup_600 = cute.to_int_tuple(%e1_596) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %239 = cute.get_scalars(%itup_600) : !cute.int_tuple<"?">
      %itup_601 = cute.to_int_tuple(%e2_597) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %240 = cute.get_scalars(%itup_601) : !cute.int_tuple<"?">
      %itup_602 = cute.to_int_tuple(%e3_598) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %241 = cute.get_scalars(%itup_602) : !cute.int_tuple<"?{div=8}">
      %coord_603 = cute.make_coord(%e3_593) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_604 = cute.make_coord(%itup_602) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %242 = cute.elem_less(%coord_603, %coord_604) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %243 = arith.extui %242 : i1 to i8
      %coord_605 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_553, %coord_605, %243) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_606 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_607 = cute.slice(%src_partitioned_519, %coord_606) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_608 = cute.get_iter(%slice_607) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_609, %e1_610, %e2_611, %e3_612 = cute.get_leaves(%iter_608) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %244 = cute.get_scalars(%e0_609) : !cute.int_tuple<"?">
      %245 = cute.get_scalars(%e1_610) : !cute.int_tuple<"?">
      %246 = cute.get_scalars(%e2_611) : !cute.int_tuple<"?">
      %247 = cute.get_scalars(%e3_612) : !cute.int_tuple<"?{div=8}">
      %iter_613 = cute.get_iter(%slice_607) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_614, %e1_615, %e2_616, %e3_617 = cute.get_leaves(%iter_613) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %248 = cute.get_scalars(%e0_614) : !cute.int_tuple<"?">
      %249 = cute.get_scalars(%e1_615) : !cute.int_tuple<"?">
      %250 = cute.get_scalars(%e2_616) : !cute.int_tuple<"?">
      %251 = cute.get_scalars(%e3_617) : !cute.int_tuple<"?{div=8}">
      %iter_618 = cute.get_iter(%slice_607) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_619, %e1_620, %e2_621, %e3_622 = cute.get_leaves(%iter_618) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %252 = cute.get_scalars(%e0_619) : !cute.int_tuple<"?">
      %253 = cute.get_scalars(%e1_620) : !cute.int_tuple<"?">
      %254 = cute.get_scalars(%e2_621) : !cute.int_tuple<"?">
      %255 = cute.get_scalars(%e3_622) : !cute.int_tuple<"?{div=8}">
      %lay_623 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %256 = cute.get_shape(%lay_623) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_624, %e1_625, %e2_626, %e3_627 = cute.get_leaves(%256) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_628 = cute.to_int_tuple(%e0_624) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %257 = cute.get_scalars(%itup_628) : !cute.int_tuple<"?">
      %itup_629 = cute.to_int_tuple(%e1_625) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %258 = cute.get_scalars(%itup_629) : !cute.int_tuple<"?">
      %itup_630 = cute.to_int_tuple(%e2_626) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %259 = cute.get_scalars(%itup_630) : !cute.int_tuple<"?">
      %itup_631 = cute.to_int_tuple(%e3_627) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %260 = cute.get_scalars(%itup_631) : !cute.int_tuple<"?{div=8}">
      %coord_632 = cute.make_coord(%e3_622) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_633 = cute.make_coord(%itup_631) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %261 = cute.elem_less(%coord_632, %coord_633) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %262 = arith.extui %261 : i1 to i8
      %coord_634 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_553, %coord_634, %262) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %lay_635 = cute.get_layout(%rmem_570) : !memref_rmem_i8_
      %263 = cute.get_shape(%lay_635) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_636, %e1_637, %e2_638 = cute.get_leaves(%263) : !cute.shape<"(1,4,2)">
      %coord_639 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_640 = cute.slice(%src_partitioned_526, %coord_639) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_641 = cute.get_iter(%slice_640) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_642, %e1_643, %e2_644, %e3_645 = cute.get_leaves(%iter_641) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %264 = cute.get_scalars(%e0_642) : !cute.int_tuple<"?">
      %265 = cute.get_scalars(%e1_643) : !cute.int_tuple<"?">
      %266 = cute.get_scalars(%e2_644) : !cute.int_tuple<"?">
      %267 = cute.get_scalars(%e3_645) : !cute.int_tuple<"?{div=8}">
      %iter_646 = cute.get_iter(%slice_640) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_647, %e1_648, %e2_649, %e3_650 = cute.get_leaves(%iter_646) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %268 = cute.get_scalars(%e0_647) : !cute.int_tuple<"?">
      %269 = cute.get_scalars(%e1_648) : !cute.int_tuple<"?">
      %270 = cute.get_scalars(%e2_649) : !cute.int_tuple<"?">
      %271 = cute.get_scalars(%e3_650) : !cute.int_tuple<"?{div=8}">
      %iter_651 = cute.get_iter(%slice_640) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_652, %e1_653, %e2_654, %e3_655 = cute.get_leaves(%iter_651) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %272 = cute.get_scalars(%e0_652) : !cute.int_tuple<"?">
      %273 = cute.get_scalars(%e1_653) : !cute.int_tuple<"?">
      %274 = cute.get_scalars(%e2_654) : !cute.int_tuple<"?">
      %275 = cute.get_scalars(%e3_655) : !cute.int_tuple<"?{div=8}">
      %lay_656 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %276 = cute.get_shape(%lay_656) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_657, %e1_658, %e2_659, %e3_660 = cute.get_leaves(%276) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_661 = cute.to_int_tuple(%e0_657) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %277 = cute.get_scalars(%itup_661) : !cute.int_tuple<"?">
      %itup_662 = cute.to_int_tuple(%e1_658) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %278 = cute.get_scalars(%itup_662) : !cute.int_tuple<"?">
      %itup_663 = cute.to_int_tuple(%e2_659) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %279 = cute.get_scalars(%itup_663) : !cute.int_tuple<"?">
      %itup_664 = cute.to_int_tuple(%e3_660) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %280 = cute.get_scalars(%itup_664) : !cute.int_tuple<"?{div=8}">
      %coord_665 = cute.make_coord(%e3_655) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_666 = cute.make_coord(%itup_664) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %281 = cute.elem_less(%coord_665, %coord_666) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %282 = arith.extui %281 : i1 to i8
      %coord_667 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_570, %coord_667, %282) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_668 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_669 = cute.slice(%src_partitioned_526, %coord_668) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_670 = cute.get_iter(%slice_669) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_671, %e1_672, %e2_673, %e3_674 = cute.get_leaves(%iter_670) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %283 = cute.get_scalars(%e0_671) : !cute.int_tuple<"?">
      %284 = cute.get_scalars(%e1_672) : !cute.int_tuple<"?">
      %285 = cute.get_scalars(%e2_673) : !cute.int_tuple<"?">
      %286 = cute.get_scalars(%e3_674) : !cute.int_tuple<"?{div=8}">
      %iter_675 = cute.get_iter(%slice_669) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_676, %e1_677, %e2_678, %e3_679 = cute.get_leaves(%iter_675) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %287 = cute.get_scalars(%e0_676) : !cute.int_tuple<"?">
      %288 = cute.get_scalars(%e1_677) : !cute.int_tuple<"?">
      %289 = cute.get_scalars(%e2_678) : !cute.int_tuple<"?">
      %290 = cute.get_scalars(%e3_679) : !cute.int_tuple<"?{div=8}">
      %iter_680 = cute.get_iter(%slice_669) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_681, %e1_682, %e2_683, %e3_684 = cute.get_leaves(%iter_680) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %291 = cute.get_scalars(%e0_681) : !cute.int_tuple<"?">
      %292 = cute.get_scalars(%e1_682) : !cute.int_tuple<"?">
      %293 = cute.get_scalars(%e2_683) : !cute.int_tuple<"?">
      %294 = cute.get_scalars(%e3_684) : !cute.int_tuple<"?{div=8}">
      %lay_685 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %295 = cute.get_shape(%lay_685) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_686, %e1_687, %e2_688, %e3_689 = cute.get_leaves(%295) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_690 = cute.to_int_tuple(%e0_686) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %296 = cute.get_scalars(%itup_690) : !cute.int_tuple<"?">
      %itup_691 = cute.to_int_tuple(%e1_687) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %297 = cute.get_scalars(%itup_691) : !cute.int_tuple<"?">
      %itup_692 = cute.to_int_tuple(%e2_688) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %298 = cute.get_scalars(%itup_692) : !cute.int_tuple<"?">
      %itup_693 = cute.to_int_tuple(%e3_689) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %299 = cute.get_scalars(%itup_693) : !cute.int_tuple<"?{div=8}">
      %coord_694 = cute.make_coord(%e3_684) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_695 = cute.make_coord(%itup_693) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %300 = cute.elem_less(%coord_694, %coord_695) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %301 = arith.extui %300 : i1 to i8
      %coord_696 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_570, %coord_696, %301) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %int_tuple_697 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_698 = cute.size(%int_tuple_697) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_699 = cute.get_leaves(%sz_698) : !cute.int_tuple<"4">
      %coord_700 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_701 = cute.slice(%src_partitioned_519, %coord_700) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_702 = cute.get_iter(%slice_701) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_703, %e1_704, %e2_705, %e3_706 = cute.get_leaves(%iter_702) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %302 = cute.get_scalars(%e0_703) : !cute.int_tuple<"?">
      %303 = cute.get_scalars(%e1_704) : !cute.int_tuple<"?">
      %304 = cute.get_scalars(%e2_705) : !cute.int_tuple<"?">
      %305 = cute.get_scalars(%e3_706) : !cute.int_tuple<"?{div=8}">
      %iter_707 = cute.get_iter(%slice_701) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_708, %e1_709, %e2_710, %e3_711 = cute.get_leaves(%iter_707) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %306 = cute.get_scalars(%e0_708) : !cute.int_tuple<"?">
      %307 = cute.get_scalars(%e1_709) : !cute.int_tuple<"?">
      %308 = cute.get_scalars(%e2_710) : !cute.int_tuple<"?">
      %309 = cute.get_scalars(%e3_711) : !cute.int_tuple<"?{div=8}">
      %iter_712 = cute.get_iter(%slice_701) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_713, %e1_714, %e2_715, %e3_716 = cute.get_leaves(%iter_712) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %310 = cute.get_scalars(%e0_713) : !cute.int_tuple<"?">
      %311 = cute.get_scalars(%e1_714) : !cute.int_tuple<"?">
      %312 = cute.get_scalars(%e2_715) : !cute.int_tuple<"?">
      %313 = cute.get_scalars(%e3_716) : !cute.int_tuple<"?{div=8}">
      %lay_717 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %314 = cute.get_shape(%lay_717) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_718, %e1_719, %e2_720, %e3_721 = cute.get_leaves(%314) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_722 = cute.to_int_tuple(%e0_718) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %315 = cute.get_scalars(%itup_722) : !cute.int_tuple<"?">
      %itup_723 = cute.to_int_tuple(%e1_719) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %316 = cute.get_scalars(%itup_723) : !cute.int_tuple<"?">
      %itup_724 = cute.to_int_tuple(%e2_720) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %317 = cute.get_scalars(%itup_724) : !cute.int_tuple<"?">
      %itup_725 = cute.to_int_tuple(%e3_721) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %318 = cute.get_scalars(%itup_725) : !cute.int_tuple<"?{div=8}">
      %coord_726 = cute.make_coord(%e1_714) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_727 = cute.make_coord(%itup_723) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %319 = cute.elem_less(%coord_726, %coord_727) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %319 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1769 = cute.slice(%src_partitioned, %coord_1768) : !memref_gmem_bf16_5, !cute.coord<"(_,0,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1773 = cute.slice(%dst_partitioned, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1777 = cute.slice(%rmem_553, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1769 = cute.slice(%dst_partitioned, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_728 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_729 = cute.slice(%src_partitioned_519, %coord_728) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_730 = cute.get_iter(%slice_729) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_731, %e1_732, %e2_733, %e3_734 = cute.get_leaves(%iter_730) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %320 = cute.get_scalars(%e0_731) : !cute.int_tuple<"?">
      %321 = cute.get_scalars(%e1_732) : !cute.int_tuple<"?">
      %322 = cute.get_scalars(%e2_733) : !cute.int_tuple<"?">
      %323 = cute.get_scalars(%e3_734) : !cute.int_tuple<"?{div=8}">
      %iter_735 = cute.get_iter(%slice_729) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_736, %e1_737, %e2_738, %e3_739 = cute.get_leaves(%iter_735) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %324 = cute.get_scalars(%e0_736) : !cute.int_tuple<"?">
      %325 = cute.get_scalars(%e1_737) : !cute.int_tuple<"?">
      %326 = cute.get_scalars(%e2_738) : !cute.int_tuple<"?">
      %327 = cute.get_scalars(%e3_739) : !cute.int_tuple<"?{div=8}">
      %iter_740 = cute.get_iter(%slice_729) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_741, %e1_742, %e2_743, %e3_744 = cute.get_leaves(%iter_740) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %328 = cute.get_scalars(%e0_741) : !cute.int_tuple<"?">
      %329 = cute.get_scalars(%e1_742) : !cute.int_tuple<"?">
      %330 = cute.get_scalars(%e2_743) : !cute.int_tuple<"?">
      %331 = cute.get_scalars(%e3_744) : !cute.int_tuple<"?{div=8}">
      %lay_745 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %332 = cute.get_shape(%lay_745) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_746, %e1_747, %e2_748, %e3_749 = cute.get_leaves(%332) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_750 = cute.to_int_tuple(%e0_746) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %333 = cute.get_scalars(%itup_750) : !cute.int_tuple<"?">
      %itup_751 = cute.to_int_tuple(%e1_747) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %334 = cute.get_scalars(%itup_751) : !cute.int_tuple<"?">
      %itup_752 = cute.to_int_tuple(%e2_748) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %335 = cute.get_scalars(%itup_752) : !cute.int_tuple<"?">
      %itup_753 = cute.to_int_tuple(%e3_749) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %336 = cute.get_scalars(%itup_753) : !cute.int_tuple<"?{div=8}">
      %coord_754 = cute.make_coord(%e1_742) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_755 = cute.make_coord(%itup_751) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %337 = cute.elem_less(%coord_754, %coord_755) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %337 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1769 = cute.slice(%src_partitioned, %coord_1768) : !memref_gmem_bf16_5, !cute.coord<"(_,1,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1773 = cute.slice(%dst_partitioned, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1777 = cute.slice(%rmem_553, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1769 = cute.slice(%dst_partitioned, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_756 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_757 = cute.slice(%src_partitioned_519, %coord_756) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_758 = cute.get_iter(%slice_757) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_759, %e1_760, %e2_761, %e3_762 = cute.get_leaves(%iter_758) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %338 = cute.get_scalars(%e0_759) : !cute.int_tuple<"?">
      %339 = cute.get_scalars(%e1_760) : !cute.int_tuple<"?">
      %340 = cute.get_scalars(%e2_761) : !cute.int_tuple<"?">
      %341 = cute.get_scalars(%e3_762) : !cute.int_tuple<"?{div=8}">
      %iter_763 = cute.get_iter(%slice_757) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_764, %e1_765, %e2_766, %e3_767 = cute.get_leaves(%iter_763) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %342 = cute.get_scalars(%e0_764) : !cute.int_tuple<"?">
      %343 = cute.get_scalars(%e1_765) : !cute.int_tuple<"?">
      %344 = cute.get_scalars(%e2_766) : !cute.int_tuple<"?">
      %345 = cute.get_scalars(%e3_767) : !cute.int_tuple<"?{div=8}">
      %iter_768 = cute.get_iter(%slice_757) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_769, %e1_770, %e2_771, %e3_772 = cute.get_leaves(%iter_768) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %346 = cute.get_scalars(%e0_769) : !cute.int_tuple<"?">
      %347 = cute.get_scalars(%e1_770) : !cute.int_tuple<"?">
      %348 = cute.get_scalars(%e2_771) : !cute.int_tuple<"?">
      %349 = cute.get_scalars(%e3_772) : !cute.int_tuple<"?{div=8}">
      %lay_773 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %350 = cute.get_shape(%lay_773) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_774, %e1_775, %e2_776, %e3_777 = cute.get_leaves(%350) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_778 = cute.to_int_tuple(%e0_774) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %351 = cute.get_scalars(%itup_778) : !cute.int_tuple<"?">
      %itup_779 = cute.to_int_tuple(%e1_775) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %352 = cute.get_scalars(%itup_779) : !cute.int_tuple<"?">
      %itup_780 = cute.to_int_tuple(%e2_776) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %353 = cute.get_scalars(%itup_780) : !cute.int_tuple<"?">
      %itup_781 = cute.to_int_tuple(%e3_777) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %354 = cute.get_scalars(%itup_781) : !cute.int_tuple<"?{div=8}">
      %coord_782 = cute.make_coord(%e1_770) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_783 = cute.make_coord(%itup_779) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %355 = cute.elem_less(%coord_782, %coord_783) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %355 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1769 = cute.slice(%src_partitioned, %coord_1768) : !memref_gmem_bf16_5, !cute.coord<"(_,2,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1773 = cute.slice(%dst_partitioned, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1777 = cute.slice(%rmem_553, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1769 = cute.slice(%dst_partitioned, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_784 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_785 = cute.slice(%src_partitioned_519, %coord_784) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_786 = cute.get_iter(%slice_785) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_787, %e1_788, %e2_789, %e3_790 = cute.get_leaves(%iter_786) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %356 = cute.get_scalars(%e0_787) : !cute.int_tuple<"?">
      %357 = cute.get_scalars(%e1_788) : !cute.int_tuple<"?">
      %358 = cute.get_scalars(%e2_789) : !cute.int_tuple<"?">
      %359 = cute.get_scalars(%e3_790) : !cute.int_tuple<"?{div=8}">
      %iter_791 = cute.get_iter(%slice_785) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_792, %e1_793, %e2_794, %e3_795 = cute.get_leaves(%iter_791) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %360 = cute.get_scalars(%e0_792) : !cute.int_tuple<"?">
      %361 = cute.get_scalars(%e1_793) : !cute.int_tuple<"?">
      %362 = cute.get_scalars(%e2_794) : !cute.int_tuple<"?">
      %363 = cute.get_scalars(%e3_795) : !cute.int_tuple<"?{div=8}">
      %iter_796 = cute.get_iter(%slice_785) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_797, %e1_798, %e2_799, %e3_800 = cute.get_leaves(%iter_796) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %364 = cute.get_scalars(%e0_797) : !cute.int_tuple<"?">
      %365 = cute.get_scalars(%e1_798) : !cute.int_tuple<"?">
      %366 = cute.get_scalars(%e2_799) : !cute.int_tuple<"?">
      %367 = cute.get_scalars(%e3_800) : !cute.int_tuple<"?{div=8}">
      %lay_801 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %368 = cute.get_shape(%lay_801) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_802, %e1_803, %e2_804, %e3_805 = cute.get_leaves(%368) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_806 = cute.to_int_tuple(%e0_802) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %369 = cute.get_scalars(%itup_806) : !cute.int_tuple<"?">
      %itup_807 = cute.to_int_tuple(%e1_803) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %370 = cute.get_scalars(%itup_807) : !cute.int_tuple<"?">
      %itup_808 = cute.to_int_tuple(%e2_804) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %371 = cute.get_scalars(%itup_808) : !cute.int_tuple<"?">
      %itup_809 = cute.to_int_tuple(%e3_805) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %372 = cute.get_scalars(%itup_809) : !cute.int_tuple<"?{div=8}">
      %coord_810 = cute.make_coord(%e1_798) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_811 = cute.make_coord(%itup_807) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %373 = cute.elem_less(%coord_810, %coord_811) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %373 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1769 = cute.slice(%src_partitioned, %coord_1768) : !memref_gmem_bf16_5, !cute.coord<"(_,3,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1773 = cute.slice(%dst_partitioned, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1777 = cute.slice(%rmem_553, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1769 = cute.slice(%dst_partitioned, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %int_tuple_812 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_813 = cute.size(%int_tuple_812) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_814 = cute.get_leaves(%sz_813) : !cute.int_tuple<"4">
      %coord_815 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_816 = cute.slice(%src_partitioned_526, %coord_815) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_817 = cute.get_iter(%slice_816) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_818, %e1_819, %e2_820, %e3_821 = cute.get_leaves(%iter_817) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %374 = cute.get_scalars(%e0_818) : !cute.int_tuple<"?">
      %375 = cute.get_scalars(%e1_819) : !cute.int_tuple<"?">
      %376 = cute.get_scalars(%e2_820) : !cute.int_tuple<"?">
      %377 = cute.get_scalars(%e3_821) : !cute.int_tuple<"?{div=8}">
      %iter_822 = cute.get_iter(%slice_816) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_823, %e1_824, %e2_825, %e3_826 = cute.get_leaves(%iter_822) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %378 = cute.get_scalars(%e0_823) : !cute.int_tuple<"?">
      %379 = cute.get_scalars(%e1_824) : !cute.int_tuple<"?">
      %380 = cute.get_scalars(%e2_825) : !cute.int_tuple<"?">
      %381 = cute.get_scalars(%e3_826) : !cute.int_tuple<"?{div=8}">
      %iter_827 = cute.get_iter(%slice_816) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_828, %e1_829, %e2_830, %e3_831 = cute.get_leaves(%iter_827) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %382 = cute.get_scalars(%e0_828) : !cute.int_tuple<"?">
      %383 = cute.get_scalars(%e1_829) : !cute.int_tuple<"?">
      %384 = cute.get_scalars(%e2_830) : !cute.int_tuple<"?">
      %385 = cute.get_scalars(%e3_831) : !cute.int_tuple<"?{div=8}">
      %lay_832 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %386 = cute.get_shape(%lay_832) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_833, %e1_834, %e2_835, %e3_836 = cute.get_leaves(%386) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_837 = cute.to_int_tuple(%e0_833) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %387 = cute.get_scalars(%itup_837) : !cute.int_tuple<"?">
      %itup_838 = cute.to_int_tuple(%e1_834) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %388 = cute.get_scalars(%itup_838) : !cute.int_tuple<"?">
      %itup_839 = cute.to_int_tuple(%e2_835) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %389 = cute.get_scalars(%itup_839) : !cute.int_tuple<"?">
      %itup_840 = cute.to_int_tuple(%e3_836) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %390 = cute.get_scalars(%itup_840) : !cute.int_tuple<"?{div=8}">
      %coord_841 = cute.make_coord(%e1_829) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_842 = cute.make_coord(%itup_838) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %391 = cute.elem_less(%coord_841, %coord_842) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %391 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %slice_1769 = cute.slice(%src_partitioned_294, %coord_1768) : !memref_gmem_bf16_6, !cute.coord<"(_,0,_,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1773 = cute.slice(%dst_partitioned_297, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1777 = cute.slice(%rmem_570, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1769 = cute.slice(%dst_partitioned_297, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_843 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_844 = cute.slice(%src_partitioned_526, %coord_843) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_845 = cute.get_iter(%slice_844) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_846, %e1_847, %e2_848, %e3_849 = cute.get_leaves(%iter_845) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %392 = cute.get_scalars(%e0_846) : !cute.int_tuple<"?">
      %393 = cute.get_scalars(%e1_847) : !cute.int_tuple<"?">
      %394 = cute.get_scalars(%e2_848) : !cute.int_tuple<"?">
      %395 = cute.get_scalars(%e3_849) : !cute.int_tuple<"?{div=8}">
      %iter_850 = cute.get_iter(%slice_844) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_851, %e1_852, %e2_853, %e3_854 = cute.get_leaves(%iter_850) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %396 = cute.get_scalars(%e0_851) : !cute.int_tuple<"?">
      %397 = cute.get_scalars(%e1_852) : !cute.int_tuple<"?">
      %398 = cute.get_scalars(%e2_853) : !cute.int_tuple<"?">
      %399 = cute.get_scalars(%e3_854) : !cute.int_tuple<"?{div=8}">
      %iter_855 = cute.get_iter(%slice_844) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_856, %e1_857, %e2_858, %e3_859 = cute.get_leaves(%iter_855) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %400 = cute.get_scalars(%e0_856) : !cute.int_tuple<"?">
      %401 = cute.get_scalars(%e1_857) : !cute.int_tuple<"?">
      %402 = cute.get_scalars(%e2_858) : !cute.int_tuple<"?">
      %403 = cute.get_scalars(%e3_859) : !cute.int_tuple<"?{div=8}">
      %lay_860 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %404 = cute.get_shape(%lay_860) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_861, %e1_862, %e2_863, %e3_864 = cute.get_leaves(%404) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_865 = cute.to_int_tuple(%e0_861) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %405 = cute.get_scalars(%itup_865) : !cute.int_tuple<"?">
      %itup_866 = cute.to_int_tuple(%e1_862) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %406 = cute.get_scalars(%itup_866) : !cute.int_tuple<"?">
      %itup_867 = cute.to_int_tuple(%e2_863) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %407 = cute.get_scalars(%itup_867) : !cute.int_tuple<"?">
      %itup_868 = cute.to_int_tuple(%e3_864) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %408 = cute.get_scalars(%itup_868) : !cute.int_tuple<"?{div=8}">
      %coord_869 = cute.make_coord(%e1_857) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_870 = cute.make_coord(%itup_866) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %409 = cute.elem_less(%coord_869, %coord_870) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %409 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %slice_1769 = cute.slice(%src_partitioned_294, %coord_1768) : !memref_gmem_bf16_6, !cute.coord<"(_,1,_,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1773 = cute.slice(%dst_partitioned_297, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1777 = cute.slice(%rmem_570, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1769 = cute.slice(%dst_partitioned_297, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_871 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_872 = cute.slice(%src_partitioned_526, %coord_871) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_873 = cute.get_iter(%slice_872) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_874, %e1_875, %e2_876, %e3_877 = cute.get_leaves(%iter_873) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %410 = cute.get_scalars(%e0_874) : !cute.int_tuple<"?">
      %411 = cute.get_scalars(%e1_875) : !cute.int_tuple<"?">
      %412 = cute.get_scalars(%e2_876) : !cute.int_tuple<"?">
      %413 = cute.get_scalars(%e3_877) : !cute.int_tuple<"?{div=8}">
      %iter_878 = cute.get_iter(%slice_872) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_879, %e1_880, %e2_881, %e3_882 = cute.get_leaves(%iter_878) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %414 = cute.get_scalars(%e0_879) : !cute.int_tuple<"?">
      %415 = cute.get_scalars(%e1_880) : !cute.int_tuple<"?">
      %416 = cute.get_scalars(%e2_881) : !cute.int_tuple<"?">
      %417 = cute.get_scalars(%e3_882) : !cute.int_tuple<"?{div=8}">
      %iter_883 = cute.get_iter(%slice_872) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_884, %e1_885, %e2_886, %e3_887 = cute.get_leaves(%iter_883) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %418 = cute.get_scalars(%e0_884) : !cute.int_tuple<"?">
      %419 = cute.get_scalars(%e1_885) : !cute.int_tuple<"?">
      %420 = cute.get_scalars(%e2_886) : !cute.int_tuple<"?">
      %421 = cute.get_scalars(%e3_887) : !cute.int_tuple<"?{div=8}">
      %lay_888 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %422 = cute.get_shape(%lay_888) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_889, %e1_890, %e2_891, %e3_892 = cute.get_leaves(%422) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_893 = cute.to_int_tuple(%e0_889) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %423 = cute.get_scalars(%itup_893) : !cute.int_tuple<"?">
      %itup_894 = cute.to_int_tuple(%e1_890) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %424 = cute.get_scalars(%itup_894) : !cute.int_tuple<"?">
      %itup_895 = cute.to_int_tuple(%e2_891) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %425 = cute.get_scalars(%itup_895) : !cute.int_tuple<"?">
      %itup_896 = cute.to_int_tuple(%e3_892) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %426 = cute.get_scalars(%itup_896) : !cute.int_tuple<"?{div=8}">
      %coord_897 = cute.make_coord(%e1_885) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_898 = cute.make_coord(%itup_894) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %427 = cute.elem_less(%coord_897, %coord_898) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %427 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %slice_1769 = cute.slice(%src_partitioned_294, %coord_1768) : !memref_gmem_bf16_6, !cute.coord<"(_,2,_,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1773 = cute.slice(%dst_partitioned_297, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1777 = cute.slice(%rmem_570, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1769 = cute.slice(%dst_partitioned_297, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %coord_899 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_900 = cute.slice(%src_partitioned_526, %coord_899) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_901 = cute.get_iter(%slice_900) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_902, %e1_903, %e2_904, %e3_905 = cute.get_leaves(%iter_901) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %428 = cute.get_scalars(%e0_902) : !cute.int_tuple<"?">
      %429 = cute.get_scalars(%e1_903) : !cute.int_tuple<"?">
      %430 = cute.get_scalars(%e2_904) : !cute.int_tuple<"?">
      %431 = cute.get_scalars(%e3_905) : !cute.int_tuple<"?{div=8}">
      %iter_906 = cute.get_iter(%slice_900) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_907, %e1_908, %e2_909, %e3_910 = cute.get_leaves(%iter_906) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %432 = cute.get_scalars(%e0_907) : !cute.int_tuple<"?">
      %433 = cute.get_scalars(%e1_908) : !cute.int_tuple<"?">
      %434 = cute.get_scalars(%e2_909) : !cute.int_tuple<"?">
      %435 = cute.get_scalars(%e3_910) : !cute.int_tuple<"?{div=8}">
      %iter_911 = cute.get_iter(%slice_900) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_912, %e1_913, %e2_914, %e3_915 = cute.get_leaves(%iter_911) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %436 = cute.get_scalars(%e0_912) : !cute.int_tuple<"?">
      %437 = cute.get_scalars(%e1_913) : !cute.int_tuple<"?">
      %438 = cute.get_scalars(%e2_914) : !cute.int_tuple<"?">
      %439 = cute.get_scalars(%e3_915) : !cute.int_tuple<"?{div=8}">
      %lay_916 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %440 = cute.get_shape(%lay_916) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_917, %e1_918, %e2_919, %e3_920 = cute.get_leaves(%440) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_921 = cute.to_int_tuple(%e0_917) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %441 = cute.get_scalars(%itup_921) : !cute.int_tuple<"?">
      %itup_922 = cute.to_int_tuple(%e1_918) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %442 = cute.get_scalars(%itup_922) : !cute.int_tuple<"?">
      %itup_923 = cute.to_int_tuple(%e2_919) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %443 = cute.get_scalars(%itup_923) : !cute.int_tuple<"?">
      %itup_924 = cute.to_int_tuple(%e3_920) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %444 = cute.get_scalars(%itup_924) : !cute.int_tuple<"?{div=8}">
      %coord_925 = cute.make_coord(%e1_913) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_926 = cute.make_coord(%itup_922) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %445 = cute.elem_less(%coord_925, %coord_926) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %445 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %slice_1769 = cute.slice(%src_partitioned_294, %coord_1768) : !memref_gmem_bf16_6, !cute.coord<"(_,3,_,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_8
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1773 = cute.slice(%dst_partitioned_297, %coord_1772) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_12
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1777 = cute.slice(%rmem_570, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_8
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_gmem_bf16_8
        %iter_1793 = cute.get_iter(%view_1792) : !memref_gmem_bf16_8
        %lay_1794 = cute.get_layout(%view_1792) : !memref_gmem_bf16_8
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_gmem_bf16_9
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_smem_bf16_12
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_smem_bf16_12
        %iter_1806 = cute.get_iter(%view_1805) : !memref_smem_bf16_12
        %lay_1807 = cute.get_layout(%view_1805) : !memref_smem_bf16_12
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_smem_bf16_13
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_gmem_bf16_9
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_smem_bf16_13
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%4, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1769 = cute.slice(%dst_partitioned_297, %coord_1768) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_12
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"16">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_12
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %int_tuple_1778 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1779 = cute.tuple.product(%int_tuple_1778) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1780 = cute.get_leaves(%res_1779) : !cute.int_tuple<"16">
        %cst_1781 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1781 : vector<16xbf16>
        %int_tuple_1782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1783 = cute.size(%int_tuple_1782) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1784 = cute.get_leaves(%sz_1783) : !cute.int_tuple<"16">
        %int_tuple_1785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1786 = cute.size(%int_tuple_1785) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1787 = cute.get_leaves(%sz_1786) : !cute.int_tuple<"16">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_12
      }
      %lay_927 = cute.get_layout(%src_partitioned_533) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %446 = cute.get_shape(%lay_927) : (!cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.shape<"((8,1),4,1,?)">
      %e0_928, %e1_929, %e2_930, %e3_931, %e4_932 = cute.get_leaves(%446) : !cute.shape<"((8,1),4,1,?)">
      %itup_933 = cute.to_int_tuple(%e4_932) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %447 = cute.get_scalars(%itup_933) : !cute.int_tuple<"?">
      %int_tuple_934 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_935 = cute.size(%int_tuple_934) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_936 = cute.get_leaves(%sz_935) : !cute.int_tuple<"4">
      %int_tuple_937 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_938 = cute.size(%int_tuple_937) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_939 = cute.get_leaves(%sz_938) : !cute.int_tuple<"1">
      %coord_940 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_941 = cute.slice(%src_partitioned_533, %coord_940) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_942 = cute.get_iter(%slice_941) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_943, %e1_944, %e2_945, %e3_946 = cute.get_leaves(%iter_942) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %448 = cute.get_scalars(%e0_943) : !cute.int_tuple<"?">
      %449 = cute.get_scalars(%e1_944) : !cute.int_tuple<"?">
      %450 = cute.get_scalars(%e2_945) : !cute.int_tuple<"?">
      %451 = cute.get_scalars(%e3_946) : !cute.int_tuple<"?{div=8}">
      %iter_947 = cute.get_iter(%slice_941) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_948, %e1_949, %e2_950, %e3_951 = cute.get_leaves(%iter_947) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %452 = cute.get_scalars(%e0_948) : !cute.int_tuple<"?">
      %453 = cute.get_scalars(%e1_949) : !cute.int_tuple<"?">
      %454 = cute.get_scalars(%e2_950) : !cute.int_tuple<"?">
      %455 = cute.get_scalars(%e3_951) : !cute.int_tuple<"?{div=8}">
      %iter_952 = cute.get_iter(%slice_941) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_953, %e1_954, %e2_955, %e3_956 = cute.get_leaves(%iter_952) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %456 = cute.get_scalars(%e0_953) : !cute.int_tuple<"?">
      %457 = cute.get_scalars(%e1_954) : !cute.int_tuple<"?">
      %458 = cute.get_scalars(%e2_955) : !cute.int_tuple<"?">
      %459 = cute.get_scalars(%e3_956) : !cute.int_tuple<"?{div=8}">
      %lay_957 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %460 = cute.get_shape(%lay_957) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_958, %e1_959, %e2_960, %e3_961 = cute.get_leaves(%460) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_962 = cute.to_int_tuple(%e0_958) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %461 = cute.get_scalars(%itup_962) : !cute.int_tuple<"?">
      %itup_963 = cute.to_int_tuple(%e1_959) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %462 = cute.get_scalars(%itup_963) : !cute.int_tuple<"?">
      %itup_964 = cute.to_int_tuple(%e2_960) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %463 = cute.get_scalars(%itup_964) : !cute.int_tuple<"?">
      %itup_965 = cute.to_int_tuple(%e3_961) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %464 = cute.get_scalars(%itup_965) : !cute.int_tuple<"?{div=8}">
      %coord_966 = cute.make_coord(%e1_954) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_967 = cute.make_coord(%itup_964) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %465 = cute.elem_less(%coord_966, %coord_967) : !cute.coord<"?">, !cute.coord<"?">
      %coord_968 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_969 = cute.slice(%src_partitioned_533, %coord_968) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_970 = cute.get_iter(%slice_969) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_971, %e1_972, %e2_973, %e3_974 = cute.get_leaves(%iter_970) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %466 = cute.get_scalars(%e0_971) : !cute.int_tuple<"?">
      %467 = cute.get_scalars(%e1_972) : !cute.int_tuple<"?">
      %468 = cute.get_scalars(%e2_973) : !cute.int_tuple<"?">
      %469 = cute.get_scalars(%e3_974) : !cute.int_tuple<"?{div=8}">
      %iter_975 = cute.get_iter(%slice_969) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_976, %e1_977, %e2_978, %e3_979 = cute.get_leaves(%iter_975) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %470 = cute.get_scalars(%e0_976) : !cute.int_tuple<"?">
      %471 = cute.get_scalars(%e1_977) : !cute.int_tuple<"?">
      %472 = cute.get_scalars(%e2_978) : !cute.int_tuple<"?">
      %473 = cute.get_scalars(%e3_979) : !cute.int_tuple<"?{div=8}">
      %iter_980 = cute.get_iter(%slice_969) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_981, %e1_982, %e2_983, %e3_984 = cute.get_leaves(%iter_980) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %474 = cute.get_scalars(%e0_981) : !cute.int_tuple<"?">
      %475 = cute.get_scalars(%e1_982) : !cute.int_tuple<"?">
      %476 = cute.get_scalars(%e2_983) : !cute.int_tuple<"?">
      %477 = cute.get_scalars(%e3_984) : !cute.int_tuple<"?{div=8}">
      %lay_985 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %478 = cute.get_shape(%lay_985) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_986, %e1_987, %e2_988, %e3_989 = cute.get_leaves(%478) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_990 = cute.to_int_tuple(%e0_986) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %479 = cute.get_scalars(%itup_990) : !cute.int_tuple<"?">
      %itup_991 = cute.to_int_tuple(%e1_987) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %480 = cute.get_scalars(%itup_991) : !cute.int_tuple<"?">
      %itup_992 = cute.to_int_tuple(%e2_988) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %481 = cute.get_scalars(%itup_992) : !cute.int_tuple<"?">
      %itup_993 = cute.to_int_tuple(%e3_989) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %482 = cute.get_scalars(%itup_993) : !cute.int_tuple<"?{div=8}">
      %coord_994 = cute.make_coord(%e1_982) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_995 = cute.make_coord(%itup_992) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %483 = cute.elem_less(%coord_994, %coord_995) : !cute.coord<"?">, !cute.coord<"?">
      %coord_996 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_997 = cute.slice(%src_partitioned_533, %coord_996) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_998 = cute.get_iter(%slice_997) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_999, %e1_1000, %e2_1001, %e3_1002 = cute.get_leaves(%iter_998) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %484 = cute.get_scalars(%e0_999) : !cute.int_tuple<"?">
      %485 = cute.get_scalars(%e1_1000) : !cute.int_tuple<"?">
      %486 = cute.get_scalars(%e2_1001) : !cute.int_tuple<"?">
      %487 = cute.get_scalars(%e3_1002) : !cute.int_tuple<"?{div=8}">
      %iter_1003 = cute.get_iter(%slice_997) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1004, %e1_1005, %e2_1006, %e3_1007 = cute.get_leaves(%iter_1003) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %488 = cute.get_scalars(%e0_1004) : !cute.int_tuple<"?">
      %489 = cute.get_scalars(%e1_1005) : !cute.int_tuple<"?">
      %490 = cute.get_scalars(%e2_1006) : !cute.int_tuple<"?">
      %491 = cute.get_scalars(%e3_1007) : !cute.int_tuple<"?{div=8}">
      %iter_1008 = cute.get_iter(%slice_997) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1009, %e1_1010, %e2_1011, %e3_1012 = cute.get_leaves(%iter_1008) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %492 = cute.get_scalars(%e0_1009) : !cute.int_tuple<"?">
      %493 = cute.get_scalars(%e1_1010) : !cute.int_tuple<"?">
      %494 = cute.get_scalars(%e2_1011) : !cute.int_tuple<"?">
      %495 = cute.get_scalars(%e3_1012) : !cute.int_tuple<"?{div=8}">
      %lay_1013 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %496 = cute.get_shape(%lay_1013) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1014, %e1_1015, %e2_1016, %e3_1017 = cute.get_leaves(%496) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1018 = cute.to_int_tuple(%e0_1014) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %497 = cute.get_scalars(%itup_1018) : !cute.int_tuple<"?">
      %itup_1019 = cute.to_int_tuple(%e1_1015) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %498 = cute.get_scalars(%itup_1019) : !cute.int_tuple<"?">
      %itup_1020 = cute.to_int_tuple(%e2_1016) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %499 = cute.get_scalars(%itup_1020) : !cute.int_tuple<"?">
      %itup_1021 = cute.to_int_tuple(%e3_1017) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %500 = cute.get_scalars(%itup_1021) : !cute.int_tuple<"?{div=8}">
      %coord_1022 = cute.make_coord(%e2_1011) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1023 = cute.make_coord(%itup_1021) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %501 = cute.elem_less(%coord_1022, %coord_1023) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %502 = arith.extui %483 : i1 to i32
      %c0_i32 = arith.constant 0 : i32
      %503 = arith.cmpi ne, %502, %c0_i32 : i32
      %504 = arith.extui %483 : i1 to i32
      %505 = arith.extui %501 : i1 to i32
      %506 = arith.select %503, %505, %504 : i32
      %c0_i32_1024 = arith.constant 0 : i32
      %507 = arith.cmpi ne, %506, %c0_i32_1024 : i32
      scf.if %507 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %slice_1769 = cute.slice(%src_partitioned_306, %coord_1768) : !memref_gmem_bf16_7, !cute.coord<"(_,0,0,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,0,0)">
        %slice_1773 = cute.slice(%dst_partitioned_309, %coord_1772) : !memref_smem_bf16_4, !cute.coord<"(_,0,0)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %lay_1776 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %882 = cute.get_shape(%lay_1776) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1777, %e1_1778 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %lay_1779 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %883 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1780, %e1_1781 = cute.get_leaves(%883) : !cute.shape<"((8,1))">
        %lay_1782 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %shape_1783 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1784 = cute.make_layout(%shape_1783) : !cute.layout<"1:0">
        %append_1785 = cute.append_to_rank<2> (%lay_1782, %lay_1784) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1786 = cute.make_view(%iter_1771, %append_1785) : !memref_gmem_bf16_11
        %iter_1787 = cute.get_iter(%view_1786) : !memref_gmem_bf16_11
        %lay_1788 = cute.get_layout(%view_1786) : !memref_gmem_bf16_11
        %884 = cute.get_shape(%lay_1788) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1789, %e1_1790, %e2_1791 = cute.get_leaves(%884) : !cute.shape<"((8,1),1)">
        %grouped_1792 = cute.group_modes(%view_1786) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1793 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %iter_1794 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %lay_1795 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %shape_1796 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1797 = cute.make_layout(%shape_1796) : !cute.layout<"1:0">
        %append_1798 = cute.append_to_rank<2> (%lay_1795, %lay_1797) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1799 = cute.make_view(%iter_1775, %append_1798) : !memref_smem_bf16_15
        %iter_1800 = cute.get_iter(%view_1799) : !memref_smem_bf16_15
        %lay_1801 = cute.get_layout(%view_1799) : !memref_smem_bf16_15
        %885 = cute.get_shape(%lay_1801) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1802, %e1_1803, %e2_1804 = cute.get_leaves(%885) : !cute.shape<"((8,1),1)">
        %grouped_1805 = cute.group_modes(%view_1799) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1806 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %iter_1807 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %lay_1808 = cute.get_layout(%grouped_1792) : !memref_gmem_bf16_12
        %886 = cute.get_shape(%lay_1808) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1809, %e1_1810, %e2_1811 = cute.get_leaves(%886) : !cute.shape<"((8,1),(1))">
        %lay_1812 = cute.get_layout(%grouped_1805) : !memref_smem_bf16_16
        %887 = cute.get_shape(%lay_1812) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1813, %e1_1814, %e2_1815 = cute.get_leaves(%887) : !cute.shape<"((8,1),(1))">
        %sz_1816 = cute.size(%grouped_1792) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1817 = cute.get_leaves(%sz_1816) : !cute.int_tuple<"1">
        %sz_1818 = cute.size(%grouped_1805) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1819 = cute.get_leaves(%sz_1818) : !cute.int_tuple<"1">
        cute.copy(%4, %grouped_1792, %grouped_1805) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,0,0)">
        %slice_1769 = cute.slice(%dst_partitioned_309, %coord_1768) : !memref_smem_bf16_4, !cute.coord<"(_,0,0)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"8">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_14
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1775, %e1_1776 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %int_tuple_1777 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1778 = cute.tuple.product(%int_tuple_1777) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1779 = cute.get_leaves(%res_1778) : !cute.int_tuple<"8">
        %cst_1780 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1780 : vector<8xbf16>
        %int_tuple_1781 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1782 = cute.size(%int_tuple_1781) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1783 = cute.get_leaves(%sz_1782) : !cute.int_tuple<"8">
        %int_tuple_1784 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1785 = cute.size(%int_tuple_1784) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1786 = cute.get_leaves(%sz_1785) : !cute.int_tuple<"8">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_14
      }
      %int_tuple_1025 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1026 = cute.size(%int_tuple_1025) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1027 = cute.get_leaves(%sz_1026) : !cute.int_tuple<"1">
      %coord_1028 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1029 = cute.slice(%src_partitioned_533, %coord_1028) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1030 = cute.get_iter(%slice_1029) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1031, %e1_1032, %e2_1033, %e3_1034 = cute.get_leaves(%iter_1030) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %508 = cute.get_scalars(%e0_1031) : !cute.int_tuple<"?">
      %509 = cute.get_scalars(%e1_1032) : !cute.int_tuple<"?">
      %510 = cute.get_scalars(%e2_1033) : !cute.int_tuple<"?">
      %511 = cute.get_scalars(%e3_1034) : !cute.int_tuple<"?{div=8}">
      %iter_1035 = cute.get_iter(%slice_1029) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1036, %e1_1037, %e2_1038, %e3_1039 = cute.get_leaves(%iter_1035) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %512 = cute.get_scalars(%e0_1036) : !cute.int_tuple<"?">
      %513 = cute.get_scalars(%e1_1037) : !cute.int_tuple<"?">
      %514 = cute.get_scalars(%e2_1038) : !cute.int_tuple<"?">
      %515 = cute.get_scalars(%e3_1039) : !cute.int_tuple<"?{div=8}">
      %iter_1040 = cute.get_iter(%slice_1029) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1041, %e1_1042, %e2_1043, %e3_1044 = cute.get_leaves(%iter_1040) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %516 = cute.get_scalars(%e0_1041) : !cute.int_tuple<"?">
      %517 = cute.get_scalars(%e1_1042) : !cute.int_tuple<"?">
      %518 = cute.get_scalars(%e2_1043) : !cute.int_tuple<"?">
      %519 = cute.get_scalars(%e3_1044) : !cute.int_tuple<"?{div=8}">
      %lay_1045 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %520 = cute.get_shape(%lay_1045) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1046, %e1_1047, %e2_1048, %e3_1049 = cute.get_leaves(%520) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1050 = cute.to_int_tuple(%e0_1046) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %521 = cute.get_scalars(%itup_1050) : !cute.int_tuple<"?">
      %itup_1051 = cute.to_int_tuple(%e1_1047) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %522 = cute.get_scalars(%itup_1051) : !cute.int_tuple<"?">
      %itup_1052 = cute.to_int_tuple(%e2_1048) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %523 = cute.get_scalars(%itup_1052) : !cute.int_tuple<"?">
      %itup_1053 = cute.to_int_tuple(%e3_1049) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %524 = cute.get_scalars(%itup_1053) : !cute.int_tuple<"?{div=8}">
      %coord_1054 = cute.make_coord(%e1_1042) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1055 = cute.make_coord(%itup_1052) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %525 = cute.elem_less(%coord_1054, %coord_1055) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1056 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1057 = cute.slice(%src_partitioned_533, %coord_1056) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1058 = cute.get_iter(%slice_1057) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1059, %e1_1060, %e2_1061, %e3_1062 = cute.get_leaves(%iter_1058) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %526 = cute.get_scalars(%e0_1059) : !cute.int_tuple<"?">
      %527 = cute.get_scalars(%e1_1060) : !cute.int_tuple<"?">
      %528 = cute.get_scalars(%e2_1061) : !cute.int_tuple<"?">
      %529 = cute.get_scalars(%e3_1062) : !cute.int_tuple<"?{div=8}">
      %iter_1063 = cute.get_iter(%slice_1057) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1064, %e1_1065, %e2_1066, %e3_1067 = cute.get_leaves(%iter_1063) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %530 = cute.get_scalars(%e0_1064) : !cute.int_tuple<"?">
      %531 = cute.get_scalars(%e1_1065) : !cute.int_tuple<"?">
      %532 = cute.get_scalars(%e2_1066) : !cute.int_tuple<"?">
      %533 = cute.get_scalars(%e3_1067) : !cute.int_tuple<"?{div=8}">
      %iter_1068 = cute.get_iter(%slice_1057) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1069, %e1_1070, %e2_1071, %e3_1072 = cute.get_leaves(%iter_1068) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %534 = cute.get_scalars(%e0_1069) : !cute.int_tuple<"?">
      %535 = cute.get_scalars(%e1_1070) : !cute.int_tuple<"?">
      %536 = cute.get_scalars(%e2_1071) : !cute.int_tuple<"?">
      %537 = cute.get_scalars(%e3_1072) : !cute.int_tuple<"?{div=8}">
      %lay_1073 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %538 = cute.get_shape(%lay_1073) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1074, %e1_1075, %e2_1076, %e3_1077 = cute.get_leaves(%538) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1078 = cute.to_int_tuple(%e0_1074) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %539 = cute.get_scalars(%itup_1078) : !cute.int_tuple<"?">
      %itup_1079 = cute.to_int_tuple(%e1_1075) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %540 = cute.get_scalars(%itup_1079) : !cute.int_tuple<"?">
      %itup_1080 = cute.to_int_tuple(%e2_1076) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %541 = cute.get_scalars(%itup_1080) : !cute.int_tuple<"?">
      %itup_1081 = cute.to_int_tuple(%e3_1077) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %542 = cute.get_scalars(%itup_1081) : !cute.int_tuple<"?{div=8}">
      %coord_1082 = cute.make_coord(%e1_1070) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1083 = cute.make_coord(%itup_1080) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %543 = cute.elem_less(%coord_1082, %coord_1083) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1084 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1085 = cute.slice(%src_partitioned_533, %coord_1084) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1086 = cute.get_iter(%slice_1085) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1087, %e1_1088, %e2_1089, %e3_1090 = cute.get_leaves(%iter_1086) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %544 = cute.get_scalars(%e0_1087) : !cute.int_tuple<"?">
      %545 = cute.get_scalars(%e1_1088) : !cute.int_tuple<"?">
      %546 = cute.get_scalars(%e2_1089) : !cute.int_tuple<"?">
      %547 = cute.get_scalars(%e3_1090) : !cute.int_tuple<"?{div=8}">
      %iter_1091 = cute.get_iter(%slice_1085) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1092, %e1_1093, %e2_1094, %e3_1095 = cute.get_leaves(%iter_1091) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %548 = cute.get_scalars(%e0_1092) : !cute.int_tuple<"?">
      %549 = cute.get_scalars(%e1_1093) : !cute.int_tuple<"?">
      %550 = cute.get_scalars(%e2_1094) : !cute.int_tuple<"?">
      %551 = cute.get_scalars(%e3_1095) : !cute.int_tuple<"?{div=8}">
      %iter_1096 = cute.get_iter(%slice_1085) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1097, %e1_1098, %e2_1099, %e3_1100 = cute.get_leaves(%iter_1096) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %552 = cute.get_scalars(%e0_1097) : !cute.int_tuple<"?">
      %553 = cute.get_scalars(%e1_1098) : !cute.int_tuple<"?">
      %554 = cute.get_scalars(%e2_1099) : !cute.int_tuple<"?">
      %555 = cute.get_scalars(%e3_1100) : !cute.int_tuple<"?{div=8}">
      %lay_1101 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %556 = cute.get_shape(%lay_1101) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1102, %e1_1103, %e2_1104, %e3_1105 = cute.get_leaves(%556) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1106 = cute.to_int_tuple(%e0_1102) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %557 = cute.get_scalars(%itup_1106) : !cute.int_tuple<"?">
      %itup_1107 = cute.to_int_tuple(%e1_1103) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %558 = cute.get_scalars(%itup_1107) : !cute.int_tuple<"?">
      %itup_1108 = cute.to_int_tuple(%e2_1104) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %559 = cute.get_scalars(%itup_1108) : !cute.int_tuple<"?">
      %itup_1109 = cute.to_int_tuple(%e3_1105) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %560 = cute.get_scalars(%itup_1109) : !cute.int_tuple<"?{div=8}">
      %coord_1110 = cute.make_coord(%e2_1099) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1111 = cute.make_coord(%itup_1109) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %561 = cute.elem_less(%coord_1110, %coord_1111) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %562 = arith.extui %543 : i1 to i32
      %563 = arith.cmpi ne, %562, %c0_i32 : i32
      %564 = arith.extui %543 : i1 to i32
      %565 = arith.extui %561 : i1 to i32
      %566 = arith.select %563, %565, %564 : i32
      %567 = arith.cmpi ne, %566, %c0_i32_1024 : i32
      scf.if %567 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %slice_1769 = cute.slice(%src_partitioned_306, %coord_1768) : !memref_gmem_bf16_7, !cute.coord<"(_,1,0,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,1,0)">
        %slice_1773 = cute.slice(%dst_partitioned_309, %coord_1772) : !memref_smem_bf16_4, !cute.coord<"(_,1,0)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %lay_1776 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %882 = cute.get_shape(%lay_1776) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1777, %e1_1778 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %lay_1779 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %883 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1780, %e1_1781 = cute.get_leaves(%883) : !cute.shape<"((8,1))">
        %lay_1782 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %shape_1783 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1784 = cute.make_layout(%shape_1783) : !cute.layout<"1:0">
        %append_1785 = cute.append_to_rank<2> (%lay_1782, %lay_1784) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1786 = cute.make_view(%iter_1771, %append_1785) : !memref_gmem_bf16_11
        %iter_1787 = cute.get_iter(%view_1786) : !memref_gmem_bf16_11
        %lay_1788 = cute.get_layout(%view_1786) : !memref_gmem_bf16_11
        %884 = cute.get_shape(%lay_1788) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1789, %e1_1790, %e2_1791 = cute.get_leaves(%884) : !cute.shape<"((8,1),1)">
        %grouped_1792 = cute.group_modes(%view_1786) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1793 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %iter_1794 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %lay_1795 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %shape_1796 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1797 = cute.make_layout(%shape_1796) : !cute.layout<"1:0">
        %append_1798 = cute.append_to_rank<2> (%lay_1795, %lay_1797) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1799 = cute.make_view(%iter_1775, %append_1798) : !memref_smem_bf16_15
        %iter_1800 = cute.get_iter(%view_1799) : !memref_smem_bf16_15
        %lay_1801 = cute.get_layout(%view_1799) : !memref_smem_bf16_15
        %885 = cute.get_shape(%lay_1801) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1802, %e1_1803, %e2_1804 = cute.get_leaves(%885) : !cute.shape<"((8,1),1)">
        %grouped_1805 = cute.group_modes(%view_1799) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1806 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %iter_1807 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %lay_1808 = cute.get_layout(%grouped_1792) : !memref_gmem_bf16_12
        %886 = cute.get_shape(%lay_1808) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1809, %e1_1810, %e2_1811 = cute.get_leaves(%886) : !cute.shape<"((8,1),(1))">
        %lay_1812 = cute.get_layout(%grouped_1805) : !memref_smem_bf16_16
        %887 = cute.get_shape(%lay_1812) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1813, %e1_1814, %e2_1815 = cute.get_leaves(%887) : !cute.shape<"((8,1),(1))">
        %sz_1816 = cute.size(%grouped_1792) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1817 = cute.get_leaves(%sz_1816) : !cute.int_tuple<"1">
        %sz_1818 = cute.size(%grouped_1805) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1819 = cute.get_leaves(%sz_1818) : !cute.int_tuple<"1">
        cute.copy(%4, %grouped_1792, %grouped_1805) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,1,0)">
        %slice_1769 = cute.slice(%dst_partitioned_309, %coord_1768) : !memref_smem_bf16_4, !cute.coord<"(_,1,0)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"8">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_14
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1775, %e1_1776 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %int_tuple_1777 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1778 = cute.tuple.product(%int_tuple_1777) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1779 = cute.get_leaves(%res_1778) : !cute.int_tuple<"8">
        %cst_1780 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1780 : vector<8xbf16>
        %int_tuple_1781 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1782 = cute.size(%int_tuple_1781) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1783 = cute.get_leaves(%sz_1782) : !cute.int_tuple<"8">
        %int_tuple_1784 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1785 = cute.size(%int_tuple_1784) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1786 = cute.get_leaves(%sz_1785) : !cute.int_tuple<"8">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_14
      }
      %int_tuple_1112 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1113 = cute.size(%int_tuple_1112) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1114 = cute.get_leaves(%sz_1113) : !cute.int_tuple<"1">
      %coord_1115 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1116 = cute.slice(%src_partitioned_533, %coord_1115) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1117 = cute.get_iter(%slice_1116) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1118, %e1_1119, %e2_1120, %e3_1121 = cute.get_leaves(%iter_1117) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %568 = cute.get_scalars(%e0_1118) : !cute.int_tuple<"?">
      %569 = cute.get_scalars(%e1_1119) : !cute.int_tuple<"?">
      %570 = cute.get_scalars(%e2_1120) : !cute.int_tuple<"?">
      %571 = cute.get_scalars(%e3_1121) : !cute.int_tuple<"?{div=8}">
      %iter_1122 = cute.get_iter(%slice_1116) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1123, %e1_1124, %e2_1125, %e3_1126 = cute.get_leaves(%iter_1122) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %572 = cute.get_scalars(%e0_1123) : !cute.int_tuple<"?">
      %573 = cute.get_scalars(%e1_1124) : !cute.int_tuple<"?">
      %574 = cute.get_scalars(%e2_1125) : !cute.int_tuple<"?">
      %575 = cute.get_scalars(%e3_1126) : !cute.int_tuple<"?{div=8}">
      %iter_1127 = cute.get_iter(%slice_1116) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1128, %e1_1129, %e2_1130, %e3_1131 = cute.get_leaves(%iter_1127) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %576 = cute.get_scalars(%e0_1128) : !cute.int_tuple<"?">
      %577 = cute.get_scalars(%e1_1129) : !cute.int_tuple<"?">
      %578 = cute.get_scalars(%e2_1130) : !cute.int_tuple<"?">
      %579 = cute.get_scalars(%e3_1131) : !cute.int_tuple<"?{div=8}">
      %lay_1132 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %580 = cute.get_shape(%lay_1132) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1133, %e1_1134, %e2_1135, %e3_1136 = cute.get_leaves(%580) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1137 = cute.to_int_tuple(%e0_1133) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %581 = cute.get_scalars(%itup_1137) : !cute.int_tuple<"?">
      %itup_1138 = cute.to_int_tuple(%e1_1134) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %582 = cute.get_scalars(%itup_1138) : !cute.int_tuple<"?">
      %itup_1139 = cute.to_int_tuple(%e2_1135) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %583 = cute.get_scalars(%itup_1139) : !cute.int_tuple<"?">
      %itup_1140 = cute.to_int_tuple(%e3_1136) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %584 = cute.get_scalars(%itup_1140) : !cute.int_tuple<"?{div=8}">
      %coord_1141 = cute.make_coord(%e1_1129) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1142 = cute.make_coord(%itup_1139) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %585 = cute.elem_less(%coord_1141, %coord_1142) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1143 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1144 = cute.slice(%src_partitioned_533, %coord_1143) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1145 = cute.get_iter(%slice_1144) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1146, %e1_1147, %e2_1148, %e3_1149 = cute.get_leaves(%iter_1145) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %586 = cute.get_scalars(%e0_1146) : !cute.int_tuple<"?">
      %587 = cute.get_scalars(%e1_1147) : !cute.int_tuple<"?">
      %588 = cute.get_scalars(%e2_1148) : !cute.int_tuple<"?">
      %589 = cute.get_scalars(%e3_1149) : !cute.int_tuple<"?{div=8}">
      %iter_1150 = cute.get_iter(%slice_1144) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1151, %e1_1152, %e2_1153, %e3_1154 = cute.get_leaves(%iter_1150) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %590 = cute.get_scalars(%e0_1151) : !cute.int_tuple<"?">
      %591 = cute.get_scalars(%e1_1152) : !cute.int_tuple<"?">
      %592 = cute.get_scalars(%e2_1153) : !cute.int_tuple<"?">
      %593 = cute.get_scalars(%e3_1154) : !cute.int_tuple<"?{div=8}">
      %iter_1155 = cute.get_iter(%slice_1144) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1156, %e1_1157, %e2_1158, %e3_1159 = cute.get_leaves(%iter_1155) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %594 = cute.get_scalars(%e0_1156) : !cute.int_tuple<"?">
      %595 = cute.get_scalars(%e1_1157) : !cute.int_tuple<"?">
      %596 = cute.get_scalars(%e2_1158) : !cute.int_tuple<"?">
      %597 = cute.get_scalars(%e3_1159) : !cute.int_tuple<"?{div=8}">
      %lay_1160 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %598 = cute.get_shape(%lay_1160) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1161, %e1_1162, %e2_1163, %e3_1164 = cute.get_leaves(%598) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1165 = cute.to_int_tuple(%e0_1161) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %599 = cute.get_scalars(%itup_1165) : !cute.int_tuple<"?">
      %itup_1166 = cute.to_int_tuple(%e1_1162) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %600 = cute.get_scalars(%itup_1166) : !cute.int_tuple<"?">
      %itup_1167 = cute.to_int_tuple(%e2_1163) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %601 = cute.get_scalars(%itup_1167) : !cute.int_tuple<"?">
      %itup_1168 = cute.to_int_tuple(%e3_1164) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %602 = cute.get_scalars(%itup_1168) : !cute.int_tuple<"?{div=8}">
      %coord_1169 = cute.make_coord(%e1_1157) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1170 = cute.make_coord(%itup_1167) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %603 = cute.elem_less(%coord_1169, %coord_1170) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1171 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1172 = cute.slice(%src_partitioned_533, %coord_1171) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1173 = cute.get_iter(%slice_1172) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1174, %e1_1175, %e2_1176, %e3_1177 = cute.get_leaves(%iter_1173) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %604 = cute.get_scalars(%e0_1174) : !cute.int_tuple<"?">
      %605 = cute.get_scalars(%e1_1175) : !cute.int_tuple<"?">
      %606 = cute.get_scalars(%e2_1176) : !cute.int_tuple<"?">
      %607 = cute.get_scalars(%e3_1177) : !cute.int_tuple<"?{div=8}">
      %iter_1178 = cute.get_iter(%slice_1172) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1179, %e1_1180, %e2_1181, %e3_1182 = cute.get_leaves(%iter_1178) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %608 = cute.get_scalars(%e0_1179) : !cute.int_tuple<"?">
      %609 = cute.get_scalars(%e1_1180) : !cute.int_tuple<"?">
      %610 = cute.get_scalars(%e2_1181) : !cute.int_tuple<"?">
      %611 = cute.get_scalars(%e3_1182) : !cute.int_tuple<"?{div=8}">
      %iter_1183 = cute.get_iter(%slice_1172) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1184, %e1_1185, %e2_1186, %e3_1187 = cute.get_leaves(%iter_1183) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %612 = cute.get_scalars(%e0_1184) : !cute.int_tuple<"?">
      %613 = cute.get_scalars(%e1_1185) : !cute.int_tuple<"?">
      %614 = cute.get_scalars(%e2_1186) : !cute.int_tuple<"?">
      %615 = cute.get_scalars(%e3_1187) : !cute.int_tuple<"?{div=8}">
      %lay_1188 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %616 = cute.get_shape(%lay_1188) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1189, %e1_1190, %e2_1191, %e3_1192 = cute.get_leaves(%616) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1193 = cute.to_int_tuple(%e0_1189) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %617 = cute.get_scalars(%itup_1193) : !cute.int_tuple<"?">
      %itup_1194 = cute.to_int_tuple(%e1_1190) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %618 = cute.get_scalars(%itup_1194) : !cute.int_tuple<"?">
      %itup_1195 = cute.to_int_tuple(%e2_1191) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %619 = cute.get_scalars(%itup_1195) : !cute.int_tuple<"?">
      %itup_1196 = cute.to_int_tuple(%e3_1192) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %620 = cute.get_scalars(%itup_1196) : !cute.int_tuple<"?{div=8}">
      %coord_1197 = cute.make_coord(%e2_1186) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1198 = cute.make_coord(%itup_1196) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %621 = cute.elem_less(%coord_1197, %coord_1198) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %622 = arith.extui %603 : i1 to i32
      %623 = arith.cmpi ne, %622, %c0_i32 : i32
      %624 = arith.extui %603 : i1 to i32
      %625 = arith.extui %621 : i1 to i32
      %626 = arith.select %623, %625, %624 : i32
      %627 = arith.cmpi ne, %626, %c0_i32_1024 : i32
      scf.if %627 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %slice_1769 = cute.slice(%src_partitioned_306, %coord_1768) : !memref_gmem_bf16_7, !cute.coord<"(_,2,0,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,2,0)">
        %slice_1773 = cute.slice(%dst_partitioned_309, %coord_1772) : !memref_smem_bf16_4, !cute.coord<"(_,2,0)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %lay_1776 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %882 = cute.get_shape(%lay_1776) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1777, %e1_1778 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %lay_1779 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %883 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1780, %e1_1781 = cute.get_leaves(%883) : !cute.shape<"((8,1))">
        %lay_1782 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %shape_1783 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1784 = cute.make_layout(%shape_1783) : !cute.layout<"1:0">
        %append_1785 = cute.append_to_rank<2> (%lay_1782, %lay_1784) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1786 = cute.make_view(%iter_1771, %append_1785) : !memref_gmem_bf16_11
        %iter_1787 = cute.get_iter(%view_1786) : !memref_gmem_bf16_11
        %lay_1788 = cute.get_layout(%view_1786) : !memref_gmem_bf16_11
        %884 = cute.get_shape(%lay_1788) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1789, %e1_1790, %e2_1791 = cute.get_leaves(%884) : !cute.shape<"((8,1),1)">
        %grouped_1792 = cute.group_modes(%view_1786) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1793 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %iter_1794 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %lay_1795 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %shape_1796 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1797 = cute.make_layout(%shape_1796) : !cute.layout<"1:0">
        %append_1798 = cute.append_to_rank<2> (%lay_1795, %lay_1797) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1799 = cute.make_view(%iter_1775, %append_1798) : !memref_smem_bf16_15
        %iter_1800 = cute.get_iter(%view_1799) : !memref_smem_bf16_15
        %lay_1801 = cute.get_layout(%view_1799) : !memref_smem_bf16_15
        %885 = cute.get_shape(%lay_1801) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1802, %e1_1803, %e2_1804 = cute.get_leaves(%885) : !cute.shape<"((8,1),1)">
        %grouped_1805 = cute.group_modes(%view_1799) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1806 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %iter_1807 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %lay_1808 = cute.get_layout(%grouped_1792) : !memref_gmem_bf16_12
        %886 = cute.get_shape(%lay_1808) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1809, %e1_1810, %e2_1811 = cute.get_leaves(%886) : !cute.shape<"((8,1),(1))">
        %lay_1812 = cute.get_layout(%grouped_1805) : !memref_smem_bf16_16
        %887 = cute.get_shape(%lay_1812) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1813, %e1_1814, %e2_1815 = cute.get_leaves(%887) : !cute.shape<"((8,1),(1))">
        %sz_1816 = cute.size(%grouped_1792) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1817 = cute.get_leaves(%sz_1816) : !cute.int_tuple<"1">
        %sz_1818 = cute.size(%grouped_1805) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1819 = cute.get_leaves(%sz_1818) : !cute.int_tuple<"1">
        cute.copy(%4, %grouped_1792, %grouped_1805) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,2,0)">
        %slice_1769 = cute.slice(%dst_partitioned_309, %coord_1768) : !memref_smem_bf16_4, !cute.coord<"(_,2,0)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"8">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_14
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1775, %e1_1776 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %int_tuple_1777 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1778 = cute.tuple.product(%int_tuple_1777) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1779 = cute.get_leaves(%res_1778) : !cute.int_tuple<"8">
        %cst_1780 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1780 : vector<8xbf16>
        %int_tuple_1781 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1782 = cute.size(%int_tuple_1781) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1783 = cute.get_leaves(%sz_1782) : !cute.int_tuple<"8">
        %int_tuple_1784 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1785 = cute.size(%int_tuple_1784) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1786 = cute.get_leaves(%sz_1785) : !cute.int_tuple<"8">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_14
      }
      %int_tuple_1199 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1200 = cute.size(%int_tuple_1199) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1201 = cute.get_leaves(%sz_1200) : !cute.int_tuple<"1">
      %coord_1202 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1203 = cute.slice(%src_partitioned_533, %coord_1202) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1204 = cute.get_iter(%slice_1203) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1205, %e1_1206, %e2_1207, %e3_1208 = cute.get_leaves(%iter_1204) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %628 = cute.get_scalars(%e0_1205) : !cute.int_tuple<"?">
      %629 = cute.get_scalars(%e1_1206) : !cute.int_tuple<"?">
      %630 = cute.get_scalars(%e2_1207) : !cute.int_tuple<"?">
      %631 = cute.get_scalars(%e3_1208) : !cute.int_tuple<"?{div=8}">
      %iter_1209 = cute.get_iter(%slice_1203) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1210, %e1_1211, %e2_1212, %e3_1213 = cute.get_leaves(%iter_1209) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %632 = cute.get_scalars(%e0_1210) : !cute.int_tuple<"?">
      %633 = cute.get_scalars(%e1_1211) : !cute.int_tuple<"?">
      %634 = cute.get_scalars(%e2_1212) : !cute.int_tuple<"?">
      %635 = cute.get_scalars(%e3_1213) : !cute.int_tuple<"?{div=8}">
      %iter_1214 = cute.get_iter(%slice_1203) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1215, %e1_1216, %e2_1217, %e3_1218 = cute.get_leaves(%iter_1214) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %636 = cute.get_scalars(%e0_1215) : !cute.int_tuple<"?">
      %637 = cute.get_scalars(%e1_1216) : !cute.int_tuple<"?">
      %638 = cute.get_scalars(%e2_1217) : !cute.int_tuple<"?">
      %639 = cute.get_scalars(%e3_1218) : !cute.int_tuple<"?{div=8}">
      %lay_1219 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %640 = cute.get_shape(%lay_1219) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1220, %e1_1221, %e2_1222, %e3_1223 = cute.get_leaves(%640) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1224 = cute.to_int_tuple(%e0_1220) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %641 = cute.get_scalars(%itup_1224) : !cute.int_tuple<"?">
      %itup_1225 = cute.to_int_tuple(%e1_1221) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %642 = cute.get_scalars(%itup_1225) : !cute.int_tuple<"?">
      %itup_1226 = cute.to_int_tuple(%e2_1222) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %643 = cute.get_scalars(%itup_1226) : !cute.int_tuple<"?">
      %itup_1227 = cute.to_int_tuple(%e3_1223) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %644 = cute.get_scalars(%itup_1227) : !cute.int_tuple<"?{div=8}">
      %coord_1228 = cute.make_coord(%e1_1216) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1229 = cute.make_coord(%itup_1226) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %645 = cute.elem_less(%coord_1228, %coord_1229) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1230 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1231 = cute.slice(%src_partitioned_533, %coord_1230) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1232 = cute.get_iter(%slice_1231) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1233, %e1_1234, %e2_1235, %e3_1236 = cute.get_leaves(%iter_1232) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %646 = cute.get_scalars(%e0_1233) : !cute.int_tuple<"?">
      %647 = cute.get_scalars(%e1_1234) : !cute.int_tuple<"?">
      %648 = cute.get_scalars(%e2_1235) : !cute.int_tuple<"?">
      %649 = cute.get_scalars(%e3_1236) : !cute.int_tuple<"?{div=8}">
      %iter_1237 = cute.get_iter(%slice_1231) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1238, %e1_1239, %e2_1240, %e3_1241 = cute.get_leaves(%iter_1237) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %650 = cute.get_scalars(%e0_1238) : !cute.int_tuple<"?">
      %651 = cute.get_scalars(%e1_1239) : !cute.int_tuple<"?">
      %652 = cute.get_scalars(%e2_1240) : !cute.int_tuple<"?">
      %653 = cute.get_scalars(%e3_1241) : !cute.int_tuple<"?{div=8}">
      %iter_1242 = cute.get_iter(%slice_1231) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1243, %e1_1244, %e2_1245, %e3_1246 = cute.get_leaves(%iter_1242) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %654 = cute.get_scalars(%e0_1243) : !cute.int_tuple<"?">
      %655 = cute.get_scalars(%e1_1244) : !cute.int_tuple<"?">
      %656 = cute.get_scalars(%e2_1245) : !cute.int_tuple<"?">
      %657 = cute.get_scalars(%e3_1246) : !cute.int_tuple<"?{div=8}">
      %lay_1247 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %658 = cute.get_shape(%lay_1247) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1248, %e1_1249, %e2_1250, %e3_1251 = cute.get_leaves(%658) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1252 = cute.to_int_tuple(%e0_1248) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %659 = cute.get_scalars(%itup_1252) : !cute.int_tuple<"?">
      %itup_1253 = cute.to_int_tuple(%e1_1249) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %660 = cute.get_scalars(%itup_1253) : !cute.int_tuple<"?">
      %itup_1254 = cute.to_int_tuple(%e2_1250) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %661 = cute.get_scalars(%itup_1254) : !cute.int_tuple<"?">
      %itup_1255 = cute.to_int_tuple(%e3_1251) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %662 = cute.get_scalars(%itup_1255) : !cute.int_tuple<"?{div=8}">
      %coord_1256 = cute.make_coord(%e1_1244) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1257 = cute.make_coord(%itup_1254) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %663 = cute.elem_less(%coord_1256, %coord_1257) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1258 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1259 = cute.slice(%src_partitioned_533, %coord_1258) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1260 = cute.get_iter(%slice_1259) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1261, %e1_1262, %e2_1263, %e3_1264 = cute.get_leaves(%iter_1260) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %664 = cute.get_scalars(%e0_1261) : !cute.int_tuple<"?">
      %665 = cute.get_scalars(%e1_1262) : !cute.int_tuple<"?">
      %666 = cute.get_scalars(%e2_1263) : !cute.int_tuple<"?">
      %667 = cute.get_scalars(%e3_1264) : !cute.int_tuple<"?{div=8}">
      %iter_1265 = cute.get_iter(%slice_1259) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1266, %e1_1267, %e2_1268, %e3_1269 = cute.get_leaves(%iter_1265) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %668 = cute.get_scalars(%e0_1266) : !cute.int_tuple<"?">
      %669 = cute.get_scalars(%e1_1267) : !cute.int_tuple<"?">
      %670 = cute.get_scalars(%e2_1268) : !cute.int_tuple<"?">
      %671 = cute.get_scalars(%e3_1269) : !cute.int_tuple<"?{div=8}">
      %iter_1270 = cute.get_iter(%slice_1259) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1271, %e1_1272, %e2_1273, %e3_1274 = cute.get_leaves(%iter_1270) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %672 = cute.get_scalars(%e0_1271) : !cute.int_tuple<"?">
      %673 = cute.get_scalars(%e1_1272) : !cute.int_tuple<"?">
      %674 = cute.get_scalars(%e2_1273) : !cute.int_tuple<"?">
      %675 = cute.get_scalars(%e3_1274) : !cute.int_tuple<"?{div=8}">
      %lay_1275 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %676 = cute.get_shape(%lay_1275) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1276, %e1_1277, %e2_1278, %e3_1279 = cute.get_leaves(%676) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1280 = cute.to_int_tuple(%e0_1276) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %677 = cute.get_scalars(%itup_1280) : !cute.int_tuple<"?">
      %itup_1281 = cute.to_int_tuple(%e1_1277) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %678 = cute.get_scalars(%itup_1281) : !cute.int_tuple<"?">
      %itup_1282 = cute.to_int_tuple(%e2_1278) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %679 = cute.get_scalars(%itup_1282) : !cute.int_tuple<"?">
      %itup_1283 = cute.to_int_tuple(%e3_1279) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %680 = cute.get_scalars(%itup_1283) : !cute.int_tuple<"?{div=8}">
      %coord_1284 = cute.make_coord(%e2_1273) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1285 = cute.make_coord(%itup_1283) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %681 = cute.elem_less(%coord_1284, %coord_1285) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %682 = arith.extui %663 : i1 to i32
      %683 = arith.cmpi ne, %682, %c0_i32 : i32
      %684 = arith.extui %663 : i1 to i32
      %685 = arith.extui %681 : i1 to i32
      %686 = arith.select %683, %685, %684 : i32
      %687 = arith.cmpi ne, %686, %c0_i32_1024 : i32
      scf.if %687 {
        %coord_1768 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %slice_1769 = cute.slice(%src_partitioned_306, %coord_1768) : !memref_gmem_bf16_7, !cute.coord<"(_,3,0,?)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_gmem_bf16_10
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,3,0)">
        %slice_1773 = cute.slice(%dst_partitioned_309, %coord_1772) : !memref_smem_bf16_4, !cute.coord<"(_,3,0)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_smem_bf16_14
        %lay_1776 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %882 = cute.get_shape(%lay_1776) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1777, %e1_1778 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %lay_1779 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %883 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1780, %e1_1781 = cute.get_leaves(%883) : !cute.shape<"((8,1))">
        %lay_1782 = cute.get_layout(%slice_1769) : !memref_gmem_bf16_10
        %shape_1783 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1784 = cute.make_layout(%shape_1783) : !cute.layout<"1:0">
        %append_1785 = cute.append_to_rank<2> (%lay_1782, %lay_1784) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1786 = cute.make_view(%iter_1771, %append_1785) : !memref_gmem_bf16_11
        %iter_1787 = cute.get_iter(%view_1786) : !memref_gmem_bf16_11
        %lay_1788 = cute.get_layout(%view_1786) : !memref_gmem_bf16_11
        %884 = cute.get_shape(%lay_1788) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1789, %e1_1790, %e2_1791 = cute.get_leaves(%884) : !cute.shape<"((8,1),1)">
        %grouped_1792 = cute.group_modes(%view_1786) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1793 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %iter_1794 = cute.get_iter(%grouped_1792) : !memref_gmem_bf16_12
        %lay_1795 = cute.get_layout(%slice_1773) : !memref_smem_bf16_14
        %shape_1796 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1797 = cute.make_layout(%shape_1796) : !cute.layout<"1:0">
        %append_1798 = cute.append_to_rank<2> (%lay_1795, %lay_1797) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1799 = cute.make_view(%iter_1775, %append_1798) : !memref_smem_bf16_15
        %iter_1800 = cute.get_iter(%view_1799) : !memref_smem_bf16_15
        %lay_1801 = cute.get_layout(%view_1799) : !memref_smem_bf16_15
        %885 = cute.get_shape(%lay_1801) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1802, %e1_1803, %e2_1804 = cute.get_leaves(%885) : !cute.shape<"((8,1),1)">
        %grouped_1805 = cute.group_modes(%view_1799) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1806 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %iter_1807 = cute.get_iter(%grouped_1805) : !memref_smem_bf16_16
        %lay_1808 = cute.get_layout(%grouped_1792) : !memref_gmem_bf16_12
        %886 = cute.get_shape(%lay_1808) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1809, %e1_1810, %e2_1811 = cute.get_leaves(%886) : !cute.shape<"((8,1),(1))">
        %lay_1812 = cute.get_layout(%grouped_1805) : !memref_smem_bf16_16
        %887 = cute.get_shape(%lay_1812) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1813, %e1_1814, %e2_1815 = cute.get_leaves(%887) : !cute.shape<"((8,1),(1))">
        %sz_1816 = cute.size(%grouped_1792) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1817 = cute.get_leaves(%sz_1816) : !cute.int_tuple<"1">
        %sz_1818 = cute.size(%grouped_1805) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1819 = cute.get_leaves(%sz_1818) : !cute.int_tuple<"1">
        cute.copy(%4, %grouped_1792, %grouped_1805) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,3,0)">
        %slice_1769 = cute.slice(%dst_partitioned_309, %coord_1768) : !memref_smem_bf16_4, !cute.coord<"(_,3,0)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_smem_bf16_14
        %sz_1772 = cute.size(%slice_1769) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1773 = cute.get_leaves(%sz_1772) : !cute.int_tuple<"8">
        %lay_1774 = cute.get_layout(%slice_1769) : !memref_smem_bf16_14
        %882 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1775, %e1_1776 = cute.get_leaves(%882) : !cute.shape<"((8,1))">
        %int_tuple_1777 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1778 = cute.tuple.product(%int_tuple_1777) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1779 = cute.get_leaves(%res_1778) : !cute.int_tuple<"8">
        %cst_1780 = arith.constant 0.000000e+00 : bf16
        %883 = vector.splat %cst_1780 : vector<8xbf16>
        %int_tuple_1781 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1782 = cute.size(%int_tuple_1781) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1783 = cute.get_leaves(%sz_1782) : !cute.int_tuple<"8">
        %int_tuple_1784 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1785 = cute.size(%int_tuple_1784) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1786 = cute.get_leaves(%sz_1785) : !cute.int_tuple<"8">
        cute.memref.store_vec %883, %slice_1769 : !memref_smem_bf16_14
      }
      nvvm.cp.async.commit.group
      %int_tuple_1286 = cute.make_int_tuple() : () -> !cute.int_tuple<"-1">
      %tup = cute.add_offset(%sub_237, %int_tuple_1286) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %688 = cute.get_scalars(%tup) : !cute.int_tuple<"?">
      %689 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %690 = cute.get_shape(%689) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
      %e0_1287, %e1_1288, %e2_1289, %e3_1290 = cute.get_leaves(%690) : !cute.shape<"(32,4,1,1)">
      %691 = cute.get_stride(%689) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
      %e0_1291, %e1_1292, %e2_1293, %e3_1294 = cute.get_leaves(%691) : !cute.stride<"(1,32,0,0)">
      %692 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1295, %e1_1296, %e2_1297 = cute.get_leaves(%692) : !cute.tile<"[64:1;16:1;16:1]">
      %693 = cute.get_shape(%e0_1295) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_1298 = cute.get_leaves(%693) : !cute.shape<"64">
      %694 = cute.get_stride(%e0_1295) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_1299 = cute.get_leaves(%694) : !cute.stride<"1">
      %695 = cute.get_shape(%e1_1296) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1300 = cute.get_leaves(%695) : !cute.shape<"16">
      %696 = cute.get_stride(%e1_1296) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1301 = cute.get_leaves(%696) : !cute.stride<"1">
      %697 = cute.get_shape(%e2_1297) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1302 = cute.get_leaves(%697) : !cute.shape<"16">
      %698 = cute.get_stride(%e2_1297) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1303 = cute.get_leaves(%698) : !cute.stride<"1">
      %699 = cute.static : !cute.layout<"32:1">
      %700 = cute.get_shape(%699) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_1304 = cute.get_leaves(%700) : !cute.shape<"32">
      %701 = cute.get_stride(%699) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_1305 = cute.get_leaves(%701) : !cute.stride<"1">
      %702 = cute.static : !cute.shape<"(16,8,16)">
      %e0_1306, %e1_1307, %e2_1308 = cute.get_leaves(%702) : !cute.shape<"(16,8,16)">
      %703 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %704 = cute.get_shape(%703) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
      %e0_1309, %e1_1310, %e2_1311, %e3_1312, %e4_1313 = cute.get_leaves(%704) : !cute.shape<"((4,8),(2,2,2))">
      %705 = cute.get_stride(%703) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
      %e0_1314, %e1_1315, %e2_1316, %e3_1317, %e4_1318 = cute.get_leaves(%705) : !cute.stride<"((32,1),(16,8,128))">
      %706 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %707 = cute.get_shape(%706) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_1319, %e1_1320, %e2_1321, %e3_1322 = cute.get_leaves(%707) : !cute.shape<"((4,8),(2,2))">
      %708 = cute.get_stride(%706) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
      %e0_1323, %e1_1324, %e2_1325, %e3_1326 = cute.get_leaves(%708) : !cute.stride<"((16,1),(8,64))">
      %709 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %710 = cute.get_shape(%709) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_1327, %e1_1328, %e2_1329, %e3_1330 = cute.get_leaves(%710) : !cute.shape<"((4,8),(2,2))">
      %711 = cute.get_stride(%709) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
      %e0_1331, %e1_1332, %e2_1333, %e3_1334 = cute.get_leaves(%711) : !cute.stride<"((32,1),(16,8))">
      %712 = cute.static : !cute.tile<"[64:1;16:1]">
      %e0_1335, %e1_1336 = cute.get_leaves(%712) : !cute.tile<"[64:1;16:1]">
      %713 = cute.get_shape(%e0_1335) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_1337 = cute.get_leaves(%713) : !cute.shape<"64">
      %714 = cute.get_stride(%e0_1335) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_1338 = cute.get_leaves(%714) : !cute.stride<"1">
      %715 = cute.get_shape(%e1_1336) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1339 = cute.get_leaves(%715) : !cute.shape<"16">
      %716 = cute.get_stride(%e1_1336) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1340 = cute.get_leaves(%716) : !cute.stride<"1">
      %717 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %718 = cute.get_shape(%717) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.shape<"((4,8,4),((2,2),(1,2)))">
      %e0_1341, %e1_1342, %e2_1343, %e3_1344, %e4_1345, %e5, %e6 = cute.get_leaves(%718) : !cute.shape<"((4,8,4),((2,2),(1,2)))">
      %719 = cute.get_stride(%717) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.stride<"((128,1,16),((64,8),(0,512)))">
      %e0_1346, %e1_1347, %e2_1348, %e3_1349, %e4_1350, %e5_1351, %e6_1352 = cute.get_leaves(%719) : !cute.stride<"((128,1,16),((64,8),(0,512)))">
      %720 = cute.static : !cute.layout<"32:1">
      %721 = cute.get_shape(%720) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_1353 = cute.get_leaves(%721) : !cute.shape<"32">
      %722 = cute.get_stride(%720) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_1354 = cute.get_leaves(%722) : !cute.stride<"1">
      %723 = cute.static : !cute.layout<"(32,8):(8,1)">
      %724 = cute.get_shape(%723) : (!cute.layout<"(32,8):(8,1)">) -> !cute.shape<"(32,8)">
      %e0_1355, %e1_1356 = cute.get_leaves(%724) : !cute.shape<"(32,8)">
      %725 = cute.get_stride(%723) : (!cute.layout<"(32,8):(8,1)">) -> !cute.stride<"(8,1)">
      %e0_1357, %e1_1358 = cute.get_leaves(%725) : !cute.stride<"(8,1)">
      %726 = cute.static : !cute.layout<"(32,(2,4)):(2,(1,64))">
      %727 = cute.get_shape(%726) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.shape<"(32,(2,4))">
      %e0_1359, %e1_1360, %e2_1361 = cute.get_leaves(%727) : !cute.shape<"(32,(2,4))">
      %728 = cute.get_stride(%726) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.stride<"(2,(1,64))">
      %e0_1362, %e1_1363, %e2_1364 = cute.get_leaves(%728) : !cute.stride<"(2,(1,64))">
      %c-1_i32 = arith.constant -1 : i32
      %c1_i32 = arith.constant 1 : i32
      %729:2 = scf.for %arg5 = %c-1_i32 to %149 step %c1_i32 iter_args(%arg6 = %6, %arg7 = %170) -> (!mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3)  : i32 {
        %int_tuple_1768 = cute.make_int_tuple(%arg5) : (i32) -> !cute.int_tuple<"?">
        %sub_1769 = cute.tuple_sub(%tup, %int_tuple_1768) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %882 = cute.get_scalars(%sub_1769) : !cute.int_tuple<"?">
        nvvm.cp.async.wait.group 0
        %c1_i32_1770 = arith.constant 1 : i32
        %c128_i32_1771 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_1770 number_of_threads = %c128_i32_1771
        %883 = arith.cmpi eq, %882, %149 : i32
        scf.if %883 {
          %lay_2599 = cute.get_layout(%dst_partitioned_303) : !memref_smem_bf16_3
          %1041 = cute.get_shape(%lay_2599) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2600, %e1_2601, %e2_2602, %e3_2603 = cute.get_leaves(%1041) : !cute.shape<"((8,1),4,2)">
          %int_tuple_2604 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %sz_2605 = cute.size(%int_tuple_2604) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
          %e0_2606 = cute.get_leaves(%sz_2605) : !cute.int_tuple<"4">
          %coord_2607 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2608 = cute.slice(%src_partitioned_526, %coord_2607) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
          %iter_2609 = cute.get_iter(%slice_2608) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2610, %e1_2611, %e2_2612, %e3_2613 = cute.get_leaves(%iter_2609) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1042 = cute.get_scalars(%e0_2610) : !cute.int_tuple<"?">
          %1043 = cute.get_scalars(%e1_2611) : !cute.int_tuple<"?">
          %1044 = cute.get_scalars(%e2_2612) : !cute.int_tuple<"?">
          %1045 = cute.get_scalars(%e3_2613) : !cute.int_tuple<"?{div=8}">
          %iter_2614 = cute.get_iter(%slice_2608) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2615, %e1_2616, %e2_2617, %e3_2618 = cute.get_leaves(%iter_2614) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1046 = cute.get_scalars(%e0_2615) : !cute.int_tuple<"?">
          %1047 = cute.get_scalars(%e1_2616) : !cute.int_tuple<"?">
          %1048 = cute.get_scalars(%e2_2617) : !cute.int_tuple<"?">
          %1049 = cute.get_scalars(%e3_2618) : !cute.int_tuple<"?{div=8}">
          %iter_2619 = cute.get_iter(%slice_2608) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2620, %e1_2621, %e2_2622, %e3_2623 = cute.get_leaves(%iter_2619) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1050 = cute.get_scalars(%e0_2620) : !cute.int_tuple<"?">
          %1051 = cute.get_scalars(%e1_2621) : !cute.int_tuple<"?">
          %1052 = cute.get_scalars(%e2_2622) : !cute.int_tuple<"?">
          %1053 = cute.get_scalars(%e3_2623) : !cute.int_tuple<"?{div=8}">
          %lay_2624 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1054 = cute.get_shape(%lay_2624) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2625, %e1_2626, %e2_2627, %e3_2628 = cute.get_leaves(%1054) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2629 = cute.to_int_tuple(%e0_2625) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1055 = cute.get_scalars(%itup_2629) : !cute.int_tuple<"?">
          %itup_2630 = cute.to_int_tuple(%e1_2626) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1056 = cute.get_scalars(%itup_2630) : !cute.int_tuple<"?">
          %itup_2631 = cute.to_int_tuple(%e2_2627) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1057 = cute.get_scalars(%itup_2631) : !cute.int_tuple<"?">
          %itup_2632 = cute.to_int_tuple(%e3_2628) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1058 = cute.get_scalars(%itup_2632) : !cute.int_tuple<"?{div=8}">
          %coord_2633 = cute.make_coord(%e1_2621) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2634 = cute.make_coord(%itup_2630) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1059 = cute.elem_less(%coord_2633, %coord_2634) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1059 {
            %coord_2719 = cute.make_coord(%sub_1769) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %slice_2720 = cute.slice(%src_partitioned_300, %coord_2719) : !memref_gmem_bf16_6, !cute.coord<"(_,0,_,?)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %coord_2723 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2724 = cute.slice(%dst_partitioned_303, %coord_2723) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
            %iter_2725 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %iter_2726 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %coord_2727 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2728 = cute.slice(%rmem_570, %coord_2727) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
            %iter_2729 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %iter_2730 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %lay_2731 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %1114 = cute.get_shape(%lay_2731) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2732, %e1_2733, %e2_2734 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %lay_2735 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %1115 = cute.get_shape(%lay_2735) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2736, %e1_2737, %e2_2738 = cute.get_leaves(%1115) : !cute.shape<"((8,1),2)">
            %lay_2739 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %shape_2740 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2741 = cute.make_layout(%shape_2740) : !cute.layout<"1:0">
            %append_2742 = cute.append_to_rank<2> (%lay_2739, %lay_2741) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2743 = cute.make_view(%iter_2722, %append_2742) : !memref_gmem_bf16_8
            %iter_2744 = cute.get_iter(%view_2743) : !memref_gmem_bf16_8
            %lay_2745 = cute.get_layout(%view_2743) : !memref_gmem_bf16_8
            %1116 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1116) : !cute.shape<"((8,1),2)">
            %grouped_2749 = cute.group_modes(%view_2743) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2750 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %iter_2751 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %lay_2752 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %shape_2753 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2754 = cute.make_layout(%shape_2753) : !cute.layout<"1:0">
            %append_2755 = cute.append_to_rank<2> (%lay_2752, %lay_2754) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2756 = cute.make_view(%iter_2726, %append_2755) : !memref_smem_bf16_12
            %iter_2757 = cute.get_iter(%view_2756) : !memref_smem_bf16_12
            %lay_2758 = cute.get_layout(%view_2756) : !memref_smem_bf16_12
            %1117 = cute.get_shape(%lay_2758) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2759, %e1_2760, %e2_2761 = cute.get_leaves(%1117) : !cute.shape<"((8,1),2)">
            %grouped_2762 = cute.group_modes(%view_2756) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2763 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %iter_2764 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %lay_2765 = cute.get_layout(%slice_2728) : !memref_rmem_i8_1
            %shape_2766 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2767 = cute.make_layout(%shape_2766) : !cute.layout<"1:0">
            %append_2768 = cute.append_to_rank<2> (%lay_2765, %lay_2767) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2769 = cute.make_view(%iter_2730, %append_2768) : !memref_rmem_i8_1
            %iter_2770 = cute.get_iter(%view_2769) : !memref_rmem_i8_1
            %lay_2771 = cute.get_layout(%view_2769) : !memref_rmem_i8_1
            %1118 = cute.get_shape(%lay_2771) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2772, %e1_2773 = cute.get_leaves(%1118) : !cute.shape<"(1,2)">
            %grouped_2774 = cute.group_modes(%view_2769) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2775 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %iter_2776 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %lay_2777 = cute.get_layout(%grouped_2749) : !memref_gmem_bf16_9
            %1119 = cute.get_shape(%lay_2777) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2778, %e1_2779, %e2_2780 = cute.get_leaves(%1119) : !cute.shape<"((8,1),(2))">
            %lay_2781 = cute.get_layout(%grouped_2762) : !memref_smem_bf16_13
            %1120 = cute.get_shape(%lay_2781) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2782, %e1_2783, %e2_2784 = cute.get_leaves(%1120) : !cute.shape<"((8,1),(2))">
            %sz_2785 = cute.size(%grouped_2749) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2786 = cute.get_leaves(%sz_2785) : !cute.int_tuple<"2">
            %sz_2787 = cute.size(%grouped_2762) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"2">
            cute.copy(%4, %grouped_2749, %grouped_2762, %grouped_2774) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2719 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2720 = cute.slice(%dst_partitioned_303, %coord_2719) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %sz_2723 = cute.size(%slice_2720) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2724 = cute.get_leaves(%sz_2723) : !cute.int_tuple<"16">
            %lay_2725 = cute.get_layout(%slice_2720) : !memref_smem_bf16_12
            %1114 = cute.get_shape(%lay_2725) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2726, %e1_2727, %e2_2728 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %int_tuple_2729 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2730 = cute.tuple.product(%int_tuple_2729) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2731 = cute.get_leaves(%res_2730) : !cute.int_tuple<"16">
            %cst_2732 = arith.constant 0.000000e+00 : bf16
            %1115 = vector.splat %cst_2732 : vector<16xbf16>
            %int_tuple_2733 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2734 = cute.size(%int_tuple_2733) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2735 = cute.get_leaves(%sz_2734) : !cute.int_tuple<"16">
            %int_tuple_2736 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2737 = cute.size(%int_tuple_2736) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2738 = cute.get_leaves(%sz_2737) : !cute.int_tuple<"16">
            cute.memref.store_vec %1115, %slice_2720 : !memref_smem_bf16_12
          }
          %coord_2635 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
          %slice_2636 = cute.slice(%src_partitioned_526, %coord_2635) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
          %iter_2637 = cute.get_iter(%slice_2636) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%iter_2637) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1060 = cute.get_scalars(%e0_2638) : !cute.int_tuple<"?">
          %1061 = cute.get_scalars(%e1_2639) : !cute.int_tuple<"?">
          %1062 = cute.get_scalars(%e2_2640) : !cute.int_tuple<"?">
          %1063 = cute.get_scalars(%e3_2641) : !cute.int_tuple<"?{div=8}">
          %iter_2642 = cute.get_iter(%slice_2636) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2643, %e1_2644, %e2_2645, %e3_2646 = cute.get_leaves(%iter_2642) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1064 = cute.get_scalars(%e0_2643) : !cute.int_tuple<"?">
          %1065 = cute.get_scalars(%e1_2644) : !cute.int_tuple<"?">
          %1066 = cute.get_scalars(%e2_2645) : !cute.int_tuple<"?">
          %1067 = cute.get_scalars(%e3_2646) : !cute.int_tuple<"?{div=8}">
          %iter_2647 = cute.get_iter(%slice_2636) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2648, %e1_2649, %e2_2650, %e3_2651 = cute.get_leaves(%iter_2647) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1068 = cute.get_scalars(%e0_2648) : !cute.int_tuple<"?">
          %1069 = cute.get_scalars(%e1_2649) : !cute.int_tuple<"?">
          %1070 = cute.get_scalars(%e2_2650) : !cute.int_tuple<"?">
          %1071 = cute.get_scalars(%e3_2651) : !cute.int_tuple<"?{div=8}">
          %lay_2652 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1072 = cute.get_shape(%lay_2652) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2653, %e1_2654, %e2_2655, %e3_2656 = cute.get_leaves(%1072) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2657 = cute.to_int_tuple(%e0_2653) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1073 = cute.get_scalars(%itup_2657) : !cute.int_tuple<"?">
          %itup_2658 = cute.to_int_tuple(%e1_2654) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1074 = cute.get_scalars(%itup_2658) : !cute.int_tuple<"?">
          %itup_2659 = cute.to_int_tuple(%e2_2655) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1075 = cute.get_scalars(%itup_2659) : !cute.int_tuple<"?">
          %itup_2660 = cute.to_int_tuple(%e3_2656) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1076 = cute.get_scalars(%itup_2660) : !cute.int_tuple<"?{div=8}">
          %coord_2661 = cute.make_coord(%e1_2649) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2662 = cute.make_coord(%itup_2658) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1077 = cute.elem_less(%coord_2661, %coord_2662) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1077 {
            %coord_2719 = cute.make_coord(%sub_1769) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %slice_2720 = cute.slice(%src_partitioned_300, %coord_2719) : !memref_gmem_bf16_6, !cute.coord<"(_,1,_,?)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %coord_2723 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2724 = cute.slice(%dst_partitioned_303, %coord_2723) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
            %iter_2725 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %iter_2726 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %coord_2727 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2728 = cute.slice(%rmem_570, %coord_2727) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
            %iter_2729 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %iter_2730 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %lay_2731 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %1114 = cute.get_shape(%lay_2731) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2732, %e1_2733, %e2_2734 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %lay_2735 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %1115 = cute.get_shape(%lay_2735) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2736, %e1_2737, %e2_2738 = cute.get_leaves(%1115) : !cute.shape<"((8,1),2)">
            %lay_2739 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %shape_2740 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2741 = cute.make_layout(%shape_2740) : !cute.layout<"1:0">
            %append_2742 = cute.append_to_rank<2> (%lay_2739, %lay_2741) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2743 = cute.make_view(%iter_2722, %append_2742) : !memref_gmem_bf16_8
            %iter_2744 = cute.get_iter(%view_2743) : !memref_gmem_bf16_8
            %lay_2745 = cute.get_layout(%view_2743) : !memref_gmem_bf16_8
            %1116 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1116) : !cute.shape<"((8,1),2)">
            %grouped_2749 = cute.group_modes(%view_2743) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2750 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %iter_2751 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %lay_2752 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %shape_2753 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2754 = cute.make_layout(%shape_2753) : !cute.layout<"1:0">
            %append_2755 = cute.append_to_rank<2> (%lay_2752, %lay_2754) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2756 = cute.make_view(%iter_2726, %append_2755) : !memref_smem_bf16_12
            %iter_2757 = cute.get_iter(%view_2756) : !memref_smem_bf16_12
            %lay_2758 = cute.get_layout(%view_2756) : !memref_smem_bf16_12
            %1117 = cute.get_shape(%lay_2758) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2759, %e1_2760, %e2_2761 = cute.get_leaves(%1117) : !cute.shape<"((8,1),2)">
            %grouped_2762 = cute.group_modes(%view_2756) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2763 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %iter_2764 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %lay_2765 = cute.get_layout(%slice_2728) : !memref_rmem_i8_1
            %shape_2766 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2767 = cute.make_layout(%shape_2766) : !cute.layout<"1:0">
            %append_2768 = cute.append_to_rank<2> (%lay_2765, %lay_2767) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2769 = cute.make_view(%iter_2730, %append_2768) : !memref_rmem_i8_1
            %iter_2770 = cute.get_iter(%view_2769) : !memref_rmem_i8_1
            %lay_2771 = cute.get_layout(%view_2769) : !memref_rmem_i8_1
            %1118 = cute.get_shape(%lay_2771) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2772, %e1_2773 = cute.get_leaves(%1118) : !cute.shape<"(1,2)">
            %grouped_2774 = cute.group_modes(%view_2769) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2775 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %iter_2776 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %lay_2777 = cute.get_layout(%grouped_2749) : !memref_gmem_bf16_9
            %1119 = cute.get_shape(%lay_2777) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2778, %e1_2779, %e2_2780 = cute.get_leaves(%1119) : !cute.shape<"((8,1),(2))">
            %lay_2781 = cute.get_layout(%grouped_2762) : !memref_smem_bf16_13
            %1120 = cute.get_shape(%lay_2781) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2782, %e1_2783, %e2_2784 = cute.get_leaves(%1120) : !cute.shape<"((8,1),(2))">
            %sz_2785 = cute.size(%grouped_2749) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2786 = cute.get_leaves(%sz_2785) : !cute.int_tuple<"2">
            %sz_2787 = cute.size(%grouped_2762) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"2">
            cute.copy(%4, %grouped_2749, %grouped_2762, %grouped_2774) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2719 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2720 = cute.slice(%dst_partitioned_303, %coord_2719) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %sz_2723 = cute.size(%slice_2720) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2724 = cute.get_leaves(%sz_2723) : !cute.int_tuple<"16">
            %lay_2725 = cute.get_layout(%slice_2720) : !memref_smem_bf16_12
            %1114 = cute.get_shape(%lay_2725) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2726, %e1_2727, %e2_2728 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %int_tuple_2729 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2730 = cute.tuple.product(%int_tuple_2729) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2731 = cute.get_leaves(%res_2730) : !cute.int_tuple<"16">
            %cst_2732 = arith.constant 0.000000e+00 : bf16
            %1115 = vector.splat %cst_2732 : vector<16xbf16>
            %int_tuple_2733 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2734 = cute.size(%int_tuple_2733) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2735 = cute.get_leaves(%sz_2734) : !cute.int_tuple<"16">
            %int_tuple_2736 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2737 = cute.size(%int_tuple_2736) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2738 = cute.get_leaves(%sz_2737) : !cute.int_tuple<"16">
            cute.memref.store_vec %1115, %slice_2720 : !memref_smem_bf16_12
          }
          %coord_2663 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
          %slice_2664 = cute.slice(%src_partitioned_526, %coord_2663) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
          %iter_2665 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%iter_2665) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1078 = cute.get_scalars(%e0_2666) : !cute.int_tuple<"?">
          %1079 = cute.get_scalars(%e1_2667) : !cute.int_tuple<"?">
          %1080 = cute.get_scalars(%e2_2668) : !cute.int_tuple<"?">
          %1081 = cute.get_scalars(%e3_2669) : !cute.int_tuple<"?{div=8}">
          %iter_2670 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2671, %e1_2672, %e2_2673, %e3_2674 = cute.get_leaves(%iter_2670) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1082 = cute.get_scalars(%e0_2671) : !cute.int_tuple<"?">
          %1083 = cute.get_scalars(%e1_2672) : !cute.int_tuple<"?">
          %1084 = cute.get_scalars(%e2_2673) : !cute.int_tuple<"?">
          %1085 = cute.get_scalars(%e3_2674) : !cute.int_tuple<"?{div=8}">
          %iter_2675 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2676, %e1_2677, %e2_2678, %e3_2679 = cute.get_leaves(%iter_2675) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1086 = cute.get_scalars(%e0_2676) : !cute.int_tuple<"?">
          %1087 = cute.get_scalars(%e1_2677) : !cute.int_tuple<"?">
          %1088 = cute.get_scalars(%e2_2678) : !cute.int_tuple<"?">
          %1089 = cute.get_scalars(%e3_2679) : !cute.int_tuple<"?{div=8}">
          %lay_2680 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1090 = cute.get_shape(%lay_2680) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2681, %e1_2682, %e2_2683, %e3_2684 = cute.get_leaves(%1090) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2685 = cute.to_int_tuple(%e0_2681) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1091 = cute.get_scalars(%itup_2685) : !cute.int_tuple<"?">
          %itup_2686 = cute.to_int_tuple(%e1_2682) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1092 = cute.get_scalars(%itup_2686) : !cute.int_tuple<"?">
          %itup_2687 = cute.to_int_tuple(%e2_2683) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1093 = cute.get_scalars(%itup_2687) : !cute.int_tuple<"?">
          %itup_2688 = cute.to_int_tuple(%e3_2684) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1094 = cute.get_scalars(%itup_2688) : !cute.int_tuple<"?{div=8}">
          %coord_2689 = cute.make_coord(%e1_2677) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2690 = cute.make_coord(%itup_2686) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1095 = cute.elem_less(%coord_2689, %coord_2690) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1095 {
            %coord_2719 = cute.make_coord(%sub_1769) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %slice_2720 = cute.slice(%src_partitioned_300, %coord_2719) : !memref_gmem_bf16_6, !cute.coord<"(_,2,_,?)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %coord_2723 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2724 = cute.slice(%dst_partitioned_303, %coord_2723) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
            %iter_2725 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %iter_2726 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %coord_2727 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2728 = cute.slice(%rmem_570, %coord_2727) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
            %iter_2729 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %iter_2730 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %lay_2731 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %1114 = cute.get_shape(%lay_2731) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2732, %e1_2733, %e2_2734 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %lay_2735 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %1115 = cute.get_shape(%lay_2735) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2736, %e1_2737, %e2_2738 = cute.get_leaves(%1115) : !cute.shape<"((8,1),2)">
            %lay_2739 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %shape_2740 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2741 = cute.make_layout(%shape_2740) : !cute.layout<"1:0">
            %append_2742 = cute.append_to_rank<2> (%lay_2739, %lay_2741) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2743 = cute.make_view(%iter_2722, %append_2742) : !memref_gmem_bf16_8
            %iter_2744 = cute.get_iter(%view_2743) : !memref_gmem_bf16_8
            %lay_2745 = cute.get_layout(%view_2743) : !memref_gmem_bf16_8
            %1116 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1116) : !cute.shape<"((8,1),2)">
            %grouped_2749 = cute.group_modes(%view_2743) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2750 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %iter_2751 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %lay_2752 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %shape_2753 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2754 = cute.make_layout(%shape_2753) : !cute.layout<"1:0">
            %append_2755 = cute.append_to_rank<2> (%lay_2752, %lay_2754) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2756 = cute.make_view(%iter_2726, %append_2755) : !memref_smem_bf16_12
            %iter_2757 = cute.get_iter(%view_2756) : !memref_smem_bf16_12
            %lay_2758 = cute.get_layout(%view_2756) : !memref_smem_bf16_12
            %1117 = cute.get_shape(%lay_2758) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2759, %e1_2760, %e2_2761 = cute.get_leaves(%1117) : !cute.shape<"((8,1),2)">
            %grouped_2762 = cute.group_modes(%view_2756) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2763 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %iter_2764 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %lay_2765 = cute.get_layout(%slice_2728) : !memref_rmem_i8_1
            %shape_2766 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2767 = cute.make_layout(%shape_2766) : !cute.layout<"1:0">
            %append_2768 = cute.append_to_rank<2> (%lay_2765, %lay_2767) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2769 = cute.make_view(%iter_2730, %append_2768) : !memref_rmem_i8_1
            %iter_2770 = cute.get_iter(%view_2769) : !memref_rmem_i8_1
            %lay_2771 = cute.get_layout(%view_2769) : !memref_rmem_i8_1
            %1118 = cute.get_shape(%lay_2771) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2772, %e1_2773 = cute.get_leaves(%1118) : !cute.shape<"(1,2)">
            %grouped_2774 = cute.group_modes(%view_2769) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2775 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %iter_2776 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %lay_2777 = cute.get_layout(%grouped_2749) : !memref_gmem_bf16_9
            %1119 = cute.get_shape(%lay_2777) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2778, %e1_2779, %e2_2780 = cute.get_leaves(%1119) : !cute.shape<"((8,1),(2))">
            %lay_2781 = cute.get_layout(%grouped_2762) : !memref_smem_bf16_13
            %1120 = cute.get_shape(%lay_2781) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2782, %e1_2783, %e2_2784 = cute.get_leaves(%1120) : !cute.shape<"((8,1),(2))">
            %sz_2785 = cute.size(%grouped_2749) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2786 = cute.get_leaves(%sz_2785) : !cute.int_tuple<"2">
            %sz_2787 = cute.size(%grouped_2762) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"2">
            cute.copy(%4, %grouped_2749, %grouped_2762, %grouped_2774) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2719 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2720 = cute.slice(%dst_partitioned_303, %coord_2719) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %sz_2723 = cute.size(%slice_2720) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2724 = cute.get_leaves(%sz_2723) : !cute.int_tuple<"16">
            %lay_2725 = cute.get_layout(%slice_2720) : !memref_smem_bf16_12
            %1114 = cute.get_shape(%lay_2725) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2726, %e1_2727, %e2_2728 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %int_tuple_2729 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2730 = cute.tuple.product(%int_tuple_2729) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2731 = cute.get_leaves(%res_2730) : !cute.int_tuple<"16">
            %cst_2732 = arith.constant 0.000000e+00 : bf16
            %1115 = vector.splat %cst_2732 : vector<16xbf16>
            %int_tuple_2733 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2734 = cute.size(%int_tuple_2733) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2735 = cute.get_leaves(%sz_2734) : !cute.int_tuple<"16">
            %int_tuple_2736 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2737 = cute.size(%int_tuple_2736) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2738 = cute.get_leaves(%sz_2737) : !cute.int_tuple<"16">
            cute.memref.store_vec %1115, %slice_2720 : !memref_smem_bf16_12
          }
          %coord_2691 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
          %slice_2692 = cute.slice(%src_partitioned_526, %coord_2691) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
          %iter_2693 = cute.get_iter(%slice_2692) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2694, %e1_2695, %e2_2696, %e3_2697 = cute.get_leaves(%iter_2693) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1096 = cute.get_scalars(%e0_2694) : !cute.int_tuple<"?">
          %1097 = cute.get_scalars(%e1_2695) : !cute.int_tuple<"?">
          %1098 = cute.get_scalars(%e2_2696) : !cute.int_tuple<"?">
          %1099 = cute.get_scalars(%e3_2697) : !cute.int_tuple<"?{div=8}">
          %iter_2698 = cute.get_iter(%slice_2692) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2699, %e1_2700, %e2_2701, %e3_2702 = cute.get_leaves(%iter_2698) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1100 = cute.get_scalars(%e0_2699) : !cute.int_tuple<"?">
          %1101 = cute.get_scalars(%e1_2700) : !cute.int_tuple<"?">
          %1102 = cute.get_scalars(%e2_2701) : !cute.int_tuple<"?">
          %1103 = cute.get_scalars(%e3_2702) : !cute.int_tuple<"?{div=8}">
          %iter_2703 = cute.get_iter(%slice_2692) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2704, %e1_2705, %e2_2706, %e3_2707 = cute.get_leaves(%iter_2703) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1104 = cute.get_scalars(%e0_2704) : !cute.int_tuple<"?">
          %1105 = cute.get_scalars(%e1_2705) : !cute.int_tuple<"?">
          %1106 = cute.get_scalars(%e2_2706) : !cute.int_tuple<"?">
          %1107 = cute.get_scalars(%e3_2707) : !cute.int_tuple<"?{div=8}">
          %lay_2708 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1108 = cute.get_shape(%lay_2708) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2709, %e1_2710, %e2_2711, %e3_2712 = cute.get_leaves(%1108) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2713 = cute.to_int_tuple(%e0_2709) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1109 = cute.get_scalars(%itup_2713) : !cute.int_tuple<"?">
          %itup_2714 = cute.to_int_tuple(%e1_2710) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1110 = cute.get_scalars(%itup_2714) : !cute.int_tuple<"?">
          %itup_2715 = cute.to_int_tuple(%e2_2711) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1111 = cute.get_scalars(%itup_2715) : !cute.int_tuple<"?">
          %itup_2716 = cute.to_int_tuple(%e3_2712) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1112 = cute.get_scalars(%itup_2716) : !cute.int_tuple<"?{div=8}">
          %coord_2717 = cute.make_coord(%e1_2705) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2718 = cute.make_coord(%itup_2714) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1113 = cute.elem_less(%coord_2717, %coord_2718) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1113 {
            %coord_2719 = cute.make_coord(%sub_1769) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %slice_2720 = cute.slice(%src_partitioned_300, %coord_2719) : !memref_gmem_bf16_6, !cute.coord<"(_,3,_,?)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_gmem_bf16_8
            %coord_2723 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2724 = cute.slice(%dst_partitioned_303, %coord_2723) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
            %iter_2725 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %iter_2726 = cute.get_iter(%slice_2724) : !memref_smem_bf16_12
            %coord_2727 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2728 = cute.slice(%rmem_570, %coord_2727) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
            %iter_2729 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %iter_2730 = cute.get_iter(%slice_2728) : !memref_rmem_i8_1
            %lay_2731 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %1114 = cute.get_shape(%lay_2731) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2732, %e1_2733, %e2_2734 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %lay_2735 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %1115 = cute.get_shape(%lay_2735) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2736, %e1_2737, %e2_2738 = cute.get_leaves(%1115) : !cute.shape<"((8,1),2)">
            %lay_2739 = cute.get_layout(%slice_2720) : !memref_gmem_bf16_8
            %shape_2740 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2741 = cute.make_layout(%shape_2740) : !cute.layout<"1:0">
            %append_2742 = cute.append_to_rank<2> (%lay_2739, %lay_2741) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2743 = cute.make_view(%iter_2722, %append_2742) : !memref_gmem_bf16_8
            %iter_2744 = cute.get_iter(%view_2743) : !memref_gmem_bf16_8
            %lay_2745 = cute.get_layout(%view_2743) : !memref_gmem_bf16_8
            %1116 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1116) : !cute.shape<"((8,1),2)">
            %grouped_2749 = cute.group_modes(%view_2743) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2750 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %iter_2751 = cute.get_iter(%grouped_2749) : !memref_gmem_bf16_9
            %lay_2752 = cute.get_layout(%slice_2724) : !memref_smem_bf16_12
            %shape_2753 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2754 = cute.make_layout(%shape_2753) : !cute.layout<"1:0">
            %append_2755 = cute.append_to_rank<2> (%lay_2752, %lay_2754) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2756 = cute.make_view(%iter_2726, %append_2755) : !memref_smem_bf16_12
            %iter_2757 = cute.get_iter(%view_2756) : !memref_smem_bf16_12
            %lay_2758 = cute.get_layout(%view_2756) : !memref_smem_bf16_12
            %1117 = cute.get_shape(%lay_2758) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2759, %e1_2760, %e2_2761 = cute.get_leaves(%1117) : !cute.shape<"((8,1),2)">
            %grouped_2762 = cute.group_modes(%view_2756) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2763 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %iter_2764 = cute.get_iter(%grouped_2762) : !memref_smem_bf16_13
            %lay_2765 = cute.get_layout(%slice_2728) : !memref_rmem_i8_1
            %shape_2766 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2767 = cute.make_layout(%shape_2766) : !cute.layout<"1:0">
            %append_2768 = cute.append_to_rank<2> (%lay_2765, %lay_2767) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2769 = cute.make_view(%iter_2730, %append_2768) : !memref_rmem_i8_1
            %iter_2770 = cute.get_iter(%view_2769) : !memref_rmem_i8_1
            %lay_2771 = cute.get_layout(%view_2769) : !memref_rmem_i8_1
            %1118 = cute.get_shape(%lay_2771) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2772, %e1_2773 = cute.get_leaves(%1118) : !cute.shape<"(1,2)">
            %grouped_2774 = cute.group_modes(%view_2769) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2775 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %iter_2776 = cute.get_iter(%grouped_2774) : !memref_rmem_i8_2
            %lay_2777 = cute.get_layout(%grouped_2749) : !memref_gmem_bf16_9
            %1119 = cute.get_shape(%lay_2777) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2778, %e1_2779, %e2_2780 = cute.get_leaves(%1119) : !cute.shape<"((8,1),(2))">
            %lay_2781 = cute.get_layout(%grouped_2762) : !memref_smem_bf16_13
            %1120 = cute.get_shape(%lay_2781) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2782, %e1_2783, %e2_2784 = cute.get_leaves(%1120) : !cute.shape<"((8,1),(2))">
            %sz_2785 = cute.size(%grouped_2749) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2786 = cute.get_leaves(%sz_2785) : !cute.int_tuple<"2">
            %sz_2787 = cute.size(%grouped_2762) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"2">
            cute.copy(%4, %grouped_2749, %grouped_2762, %grouped_2774) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2719 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2720 = cute.slice(%dst_partitioned_303, %coord_2719) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
            %iter_2721 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %iter_2722 = cute.get_iter(%slice_2720) : !memref_smem_bf16_12
            %sz_2723 = cute.size(%slice_2720) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2724 = cute.get_leaves(%sz_2723) : !cute.int_tuple<"16">
            %lay_2725 = cute.get_layout(%slice_2720) : !memref_smem_bf16_12
            %1114 = cute.get_shape(%lay_2725) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2726, %e1_2727, %e2_2728 = cute.get_leaves(%1114) : !cute.shape<"((8,1),2)">
            %int_tuple_2729 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2730 = cute.tuple.product(%int_tuple_2729) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2731 = cute.get_leaves(%res_2730) : !cute.int_tuple<"16">
            %cst_2732 = arith.constant 0.000000e+00 : bf16
            %1115 = vector.splat %cst_2732 : vector<16xbf16>
            %int_tuple_2733 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2734 = cute.size(%int_tuple_2733) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2735 = cute.get_leaves(%sz_2734) : !cute.int_tuple<"16">
            %int_tuple_2736 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2737 = cute.size(%int_tuple_2736) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2738 = cute.get_leaves(%sz_2737) : !cute.int_tuple<"16">
            cute.memref.store_vec %1115, %slice_2720 : !memref_smem_bf16_12
          }
        } else {
          %coord_2599 = cute.make_coord(%sub_1769) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %slice_2600 = cute.slice(%src_partitioned_300, %coord_2599) : !memref_gmem_bf16_6, !cute.coord<"(_,_,_,?)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_gmem_bf16_5
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_gmem_bf16_5
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2604 = cute.slice(%dst_partitioned_303, %coord_2603) : !memref_smem_bf16_3, !cute.coord<"(_,_,_)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_smem_bf16_3
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_smem_bf16_3
          %coord_2607 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2608 = cute.slice(%rmem_570, %coord_2607) : !memref_rmem_i8_, !cute.coord<"(_,_,_)">
          %iter_2609 = cute.get_iter(%slice_2608) : !memref_rmem_i8_
          %iter_2610 = cute.get_iter(%slice_2608) : !memref_rmem_i8_
          %lay_2611 = cute.get_layout(%slice_2600) : !memref_gmem_bf16_5
          %1041 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2612, %e1_2613, %e2_2614, %e3_2615 = cute.get_leaves(%1041) : !cute.shape<"((8,1),4,2)">
          %lay_2616 = cute.get_layout(%slice_2604) : !memref_smem_bf16_3
          %1042 = cute.get_shape(%lay_2616) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2617, %e1_2618, %e2_2619, %e3_2620 = cute.get_leaves(%1042) : !cute.shape<"((8,1),4,2)">
          %lay_2621 = cute.get_layout(%slice_2600) : !memref_gmem_bf16_5
          %shape_2622 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2623 = cute.make_layout(%shape_2622) : !cute.layout<"1:0">
          %append_2624 = cute.append_to_rank<2> (%lay_2621, %lay_2623) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_2625 = cute.make_view(%iter_2602, %append_2624) : !memref_gmem_bf16_5
          %iter_2626 = cute.get_iter(%view_2625) : !memref_gmem_bf16_5
          %lay_2627 = cute.get_layout(%view_2625) : !memref_gmem_bf16_5
          %1043 = cute.get_shape(%lay_2627) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2628, %e1_2629, %e2_2630, %e3_2631 = cute.get_leaves(%1043) : !cute.shape<"((8,1),4,2)">
          %grouped_2632 = cute.group_modes(%view_2625) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_13
          %iter_2633 = cute.get_iter(%grouped_2632) : !memref_gmem_bf16_13
          %iter_2634 = cute.get_iter(%grouped_2632) : !memref_gmem_bf16_13
          %lay_2635 = cute.get_layout(%slice_2604) : !memref_smem_bf16_3
          %shape_2636 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2637 = cute.make_layout(%shape_2636) : !cute.layout<"1:0">
          %append_2638 = cute.append_to_rank<2> (%lay_2635, %lay_2637) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
          %view_2639 = cute.make_view(%iter_2606, %append_2638) : !memref_smem_bf16_3
          %iter_2640 = cute.get_iter(%view_2639) : !memref_smem_bf16_3
          %lay_2641 = cute.get_layout(%view_2639) : !memref_smem_bf16_3
          %1044 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2642, %e1_2643, %e2_2644, %e3_2645 = cute.get_leaves(%1044) : !cute.shape<"((8,1),4,2)">
          %grouped_2646 = cute.group_modes(%view_2639) <1, 3> : (!memref_smem_bf16_3) -> !memref_smem_bf16_17
          %iter_2647 = cute.get_iter(%grouped_2646) : !memref_smem_bf16_17
          %iter_2648 = cute.get_iter(%grouped_2646) : !memref_smem_bf16_17
          %lay_2649 = cute.get_layout(%slice_2608) : !memref_rmem_i8_
          %shape_2650 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2651 = cute.make_layout(%shape_2650) : !cute.layout<"1:0">
          %append_2652 = cute.append_to_rank<2> (%lay_2649, %lay_2651) : !cute.layout<"(1,4,2):(2,0,1)">, !cute.layout<"1:0">
          %view_2653 = cute.make_view(%iter_2610, %append_2652) : !memref_rmem_i8_
          %iter_2654 = cute.get_iter(%view_2653) : !memref_rmem_i8_
          %lay_2655 = cute.get_layout(%view_2653) : !memref_rmem_i8_
          %1045 = cute.get_shape(%lay_2655) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
          %e0_2656, %e1_2657, %e2_2658 = cute.get_leaves(%1045) : !cute.shape<"(1,4,2)">
          %grouped_2659 = cute.group_modes(%view_2653) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_3
          %iter_2660 = cute.get_iter(%grouped_2659) : !memref_rmem_i8_3
          %iter_2661 = cute.get_iter(%grouped_2659) : !memref_rmem_i8_3
          %lay_2662 = cute.get_layout(%grouped_2632) : !memref_gmem_bf16_13
          %1046 = cute.get_shape(%lay_2662) : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2663, %e1_2664, %e2_2665, %e3_2666 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(4,2))">
          %lay_2667 = cute.get_layout(%grouped_2646) : !memref_smem_bf16_17
          %1047 = cute.get_shape(%lay_2667) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2668, %e1_2669, %e2_2670, %e3_2671 = cute.get_leaves(%1047) : !cute.shape<"((8,1),(4,2))">
          %sz_2672 = cute.size(%grouped_2632) <{mode = [1]}> : (!memref_gmem_bf16_13) -> !cute.int_tuple<"8">
          %e0_2673 = cute.get_leaves(%sz_2672) : !cute.int_tuple<"8">
          %sz_2674 = cute.size(%grouped_2646) <{mode = [1]}> : (!memref_smem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2675 = cute.get_leaves(%sz_2674) : !cute.int_tuple<"8">
          cute.copy(%4, %grouped_2632, %grouped_2646, %grouped_2659) : (!copy_ldgsts, !memref_gmem_bf16_13, !memref_smem_bf16_17, !memref_rmem_i8_3)
        }
        nvvm.cp.async.commit.group
        %shape_1772 = cute.make_shape() : () -> !cute.shape<"(64,64)">
        %884 = cute.tiled.mma.partition_shape C (%arg6, %shape_1772) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,64)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1773, %e1_1774, %e2_1775, %e3_1776 = cute.get_leaves(%884) : !cute.shape<"((2,2),1,8)">
        %shape_1777 = cute.make_shape() : () -> !cute.shape<"((2,2),1,8)">
        %lay_1778 = cute.make_layout(%shape_1777) : !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_1779 = cute.memref.alloca(%lay_1778) : !memref_rmem_f32_1
        %iter_1780 = cute.get_iter(%rmem_1779) : !memref_rmem_f32_1
        %iter_1781 = cute.get_iter(%rmem_1779) : !memref_rmem_f32_1
        %shape_1782 = cute.make_shape() : () -> !cute.shape<"(64,64)">
        %885 = cute.tiled.mma.partition_shape C (%arg6, %shape_1782) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,64)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1783, %e1_1784, %e2_1785, %e3_1786 = cute.get_leaves(%885) : !cute.shape<"((2,2),1,8)">
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"((2,2),1,8)">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_1789 = cute.memref.alloca(%lay_1788) : !memref_rmem_bf16_6
        %iter_1790 = cute.get_iter(%rmem_1789) : !memref_rmem_bf16_6
        %iter_1791 = cute.get_iter(%rmem_1789) : !memref_rmem_bf16_6
        %retiled_1792 = cute.tiled.copy.retile(%arg7, %rmem_1789) : (!copy_ldsm_4_3, !memref_rmem_bf16_6) -> !memref_rmem_bf16_7
        %iter_1793 = cute.get_iter(%retiled_1792) : !memref_rmem_bf16_7
        %coord_1794 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
        %slice_1795 = cute.slice(%src_partitioned_411, %coord_1794) : !memref_smem_bf16_11, !cute.coord<"(_,_,_)">
        %iter_1796 = cute.get_iter(%slice_1795) : !memref_smem_bf16_11
        %iter_1797 = cute.get_iter(%slice_1795) : !memref_smem_bf16_11
        %coord_1798 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
        %slice_1799 = cute.slice(%retiled_1792, %coord_1798) : !memref_rmem_bf16_7, !cute.coord<"(_,_,_)">
        %iter_1800 = cute.get_iter(%slice_1799) : !memref_rmem_bf16_7
        %iter_1801 = cute.get_iter(%slice_1799) : !memref_rmem_bf16_7
        %lay_1802 = cute.get_layout(%slice_1795) : !memref_smem_bf16_11
        %886 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !cute.shape<"((8,1),1,(2,2))">
        %e0_1803, %e1_1804, %e2_1805, %e3_1806, %e4_1807 = cute.get_leaves(%886) : !cute.shape<"((8,1),1,(2,2))">
        %lay_1808 = cute.get_layout(%slice_1799) : !memref_rmem_bf16_7
        %887 = cute.get_shape(%lay_1808) : (!cute.layout<"((8,1),1,4):((1,0),0,8)">) -> !cute.shape<"((8,1),1,4)">
        %e0_1809, %e1_1810, %e2_1811, %e3_1812 = cute.get_leaves(%887) : !cute.shape<"((8,1),1,4)">
        %lay_1813 = cute.get_layout(%slice_1795) : !memref_smem_bf16_11
        %shape_1814 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1815 = cute.make_layout(%shape_1814) : !cute.layout<"1:0">
        %append_1816 = cute.append_to_rank<2> (%lay_1813, %lay_1815) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
        %view_1817 = cute.make_view(%iter_1797, %append_1816) : !memref_smem_bf16_11
        %iter_1818 = cute.get_iter(%view_1817) : !memref_smem_bf16_11
        %lay_1819 = cute.get_layout(%view_1817) : !memref_smem_bf16_11
        %888 = cute.get_shape(%lay_1819) : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !cute.shape<"((8,1),1,(2,2))">
        %e0_1820, %e1_1821, %e2_1822, %e3_1823, %e4_1824 = cute.get_leaves(%888) : !cute.shape<"((8,1),1,(2,2))">
        %grouped_1825 = cute.group_modes(%view_1817) <1, 3> : (!memref_smem_bf16_11) -> !memref_smem_bf16_18
        %iter_1826 = cute.get_iter(%grouped_1825) : !memref_smem_bf16_18
        %iter_1827 = cute.get_iter(%grouped_1825) : !memref_smem_bf16_18
        %lay_1828 = cute.get_layout(%slice_1799) : !memref_rmem_bf16_7
        %shape_1829 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1830 = cute.make_layout(%shape_1829) : !cute.layout<"1:0">
        %append_1831 = cute.append_to_rank<2> (%lay_1828, %lay_1830) : !cute.layout<"((8,1),1,4):((1,0),0,8)">, !cute.layout<"1:0">
        %view_1832 = cute.make_view(%iter_1801, %append_1831) : !memref_rmem_bf16_7
        %iter_1833 = cute.get_iter(%view_1832) : !memref_rmem_bf16_7
        %lay_1834 = cute.get_layout(%view_1832) : !memref_rmem_bf16_7
        %889 = cute.get_shape(%lay_1834) : (!cute.layout<"((8,1),1,4):((1,0),0,8)">) -> !cute.shape<"((8,1),1,4)">
        %e0_1835, %e1_1836, %e2_1837, %e3_1838 = cute.get_leaves(%889) : !cute.shape<"((8,1),1,4)">
        %grouped_1839 = cute.group_modes(%view_1832) <1, 3> : (!memref_rmem_bf16_7) -> !memref_rmem_bf16_8
        %iter_1840 = cute.get_iter(%grouped_1839) : !memref_rmem_bf16_8
        %iter_1841 = cute.get_iter(%grouped_1839) : !memref_rmem_bf16_8
        %lay_1842 = cute.get_layout(%grouped_1825) : !memref_smem_bf16_18
        %890 = cute.get_shape(%lay_1842) : (!cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">) -> !cute.shape<"((8,1),(1,(2,2)))">
        %e0_1843, %e1_1844, %e2_1845, %e3_1846, %e4_1847 = cute.get_leaves(%890) : !cute.shape<"((8,1),(1,(2,2)))">
        %lay_1848 = cute.get_layout(%grouped_1839) : !memref_rmem_bf16_8
        %891 = cute.get_shape(%lay_1848) : (!cute.layout<"((8,1),(1,4)):((1,0),(0,8))">) -> !cute.shape<"((8,1),(1,4))">
        %e0_1849, %e1_1850, %e2_1851, %e3_1852 = cute.get_leaves(%891) : !cute.shape<"((8,1),(1,4))">
        %sz_1853 = cute.size(%grouped_1825) <{mode = [1]}> : (!memref_smem_bf16_18) -> !cute.int_tuple<"4">
        %e0_1854 = cute.get_leaves(%sz_1853) : !cute.int_tuple<"4">
        %sz_1855 = cute.size(%grouped_1839) <{mode = [1]}> : (!memref_rmem_bf16_8) -> !cute.int_tuple<"4">
        %e0_1856 = cute.get_leaves(%sz_1855) : !cute.int_tuple<"4">
        cute.copy(%170, %grouped_1825, %grouped_1839) : (!copy_ldsm_4_3, !memref_smem_bf16_18, !memref_rmem_bf16_8)
        %lay_1857 = cute.get_layout(%rmem_1789) : !memref_rmem_bf16_6
        %892 = cute.get_shape(%lay_1857) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1858, %e1_1859, %e2_1860, %e3_1861 = cute.get_leaves(%892) : !cute.shape<"((2,2),1,8)">
        %893 = cute.memref.load_vec %rmem_1789 : !memref_rmem_bf16_6
        %894 = arith.extf %893 : vector<32xbf16> to vector<32xf32>
        %lay_1862 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
        %895 = cute.get_shape(%lay_1862) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1863, %e1_1864, %e2_1865, %e3_1866 = cute.get_leaves(%895) : !cute.shape<"((2,2),1,8)">
        %int_tuple_1867 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_1868 = cute.size(%int_tuple_1867) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_1869 = cute.get_leaves(%sz_1868) : !cute.int_tuple<"32">
        %int_tuple_1870 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_1871 = cute.size(%int_tuple_1870) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_1872 = cute.get_leaves(%sz_1871) : !cute.int_tuple<"32">
        cute.memref.store_vec %894, %rmem_1779 : !memref_rmem_f32_1
        %coord_1873 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1874 = cute.slice(%src_partitioned_397, %coord_1873) : !memref_smem_bf16_8, !cute.coord<"(_,_,0)">
        %iter_1875 = cute.get_iter(%slice_1874) : !memref_smem_bf16_15
        %iter_1876 = cute.get_iter(%slice_1874) : !memref_smem_bf16_15
        %coord_1877 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1878 = cute.slice(%retiled, %coord_1877) : !memref_rmem_bf16_3, !cute.coord<"(_,_,0)">
        %iter_1879 = cute.get_iter(%slice_1878) : !memref_rmem_bf16_9
        %iter_1880 = cute.get_iter(%slice_1878) : !memref_rmem_bf16_9
        %lay_1881 = cute.get_layout(%slice_1874) : !memref_smem_bf16_15
        %896 = cute.get_shape(%lay_1881) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1882, %e1_1883, %e2_1884 = cute.get_leaves(%896) : !cute.shape<"((8,1),1)">
        %lay_1885 = cute.get_layout(%slice_1878) : !memref_rmem_bf16_9
        %897 = cute.get_shape(%lay_1885) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1886, %e1_1887, %e2_1888 = cute.get_leaves(%897) : !cute.shape<"((8,1),1)">
        %lay_1889 = cute.get_layout(%slice_1874) : !memref_smem_bf16_15
        %shape_1890 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1891 = cute.make_layout(%shape_1890) : !cute.layout<"1:0">
        %append_1892 = cute.append_to_rank<2> (%lay_1889, %lay_1891) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
        %view_1893 = cute.make_view(%iter_1876, %append_1892) : !memref_smem_bf16_15
        %iter_1894 = cute.get_iter(%view_1893) : !memref_smem_bf16_15
        %lay_1895 = cute.get_layout(%view_1893) : !memref_smem_bf16_15
        %898 = cute.get_shape(%lay_1895) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1896, %e1_1897, %e2_1898 = cute.get_leaves(%898) : !cute.shape<"((8,1),1)">
        %grouped_1899 = cute.group_modes(%view_1893) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1900 = cute.get_iter(%grouped_1899) : !memref_smem_bf16_16
        %iter_1901 = cute.get_iter(%grouped_1899) : !memref_smem_bf16_16
        %lay_1902 = cute.get_layout(%slice_1878) : !memref_rmem_bf16_9
        %shape_1903 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1904 = cute.make_layout(%shape_1903) : !cute.layout<"1:0">
        %append_1905 = cute.append_to_rank<2> (%lay_1902, %lay_1904) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
        %view_1906 = cute.make_view(%iter_1880, %append_1905) : !memref_rmem_bf16_9
        %iter_1907 = cute.get_iter(%view_1906) : !memref_rmem_bf16_9
        %lay_1908 = cute.get_layout(%view_1906) : !memref_rmem_bf16_9
        %899 = cute.get_shape(%lay_1908) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1909, %e1_1910, %e2_1911 = cute.get_leaves(%899) : !cute.shape<"((8,1),1)">
        %grouped_1912 = cute.group_modes(%view_1906) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
        %iter_1913 = cute.get_iter(%grouped_1912) : !memref_rmem_bf16_10
        %iter_1914 = cute.get_iter(%grouped_1912) : !memref_rmem_bf16_10
        %lay_1915 = cute.get_layout(%grouped_1899) : !memref_smem_bf16_16
        %900 = cute.get_shape(%lay_1915) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1916, %e1_1917, %e2_1918 = cute.get_leaves(%900) : !cute.shape<"((8,1),(1))">
        %lay_1919 = cute.get_layout(%grouped_1912) : !memref_rmem_bf16_10
        %901 = cute.get_shape(%lay_1919) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1920, %e1_1921, %e2_1922 = cute.get_leaves(%901) : !cute.shape<"((8,1),(1))">
        %sz_1923 = cute.size(%grouped_1899) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1924 = cute.get_leaves(%sz_1923) : !cute.int_tuple<"1">
        %sz_1925 = cute.size(%grouped_1912) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
        %e0_1926 = cute.get_leaves(%sz_1925) : !cute.int_tuple<"1">
        cute.copy(%158, %grouped_1899, %grouped_1912) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
        %coord_1927 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1928 = cute.slice(%src_partitioned_401, %coord_1927) : !memref_smem_bf16_9, !cute.coord<"(_,_,0)">
        %iter_1929 = cute.get_iter(%slice_1928) : !memref_smem_bf16_19
        %iter_1930 = cute.get_iter(%slice_1928) : !memref_smem_bf16_19
        %coord_1931 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1932 = cute.slice(%retiled_403, %coord_1931) : !memref_rmem_bf16_4, !cute.coord<"(_,_,0)">
        %iter_1933 = cute.get_iter(%slice_1932) : !memref_rmem_bf16_11
        %iter_1934 = cute.get_iter(%slice_1932) : !memref_rmem_bf16_11
        %lay_1935 = cute.get_layout(%slice_1928) : !memref_smem_bf16_19
        %902 = cute.get_shape(%lay_1935) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
        %e0_1936, %e1_1937, %e2_1938 = cute.get_leaves(%902) : !cute.shape<"((8,1),4)">
        %lay_1939 = cute.get_layout(%slice_1932) : !memref_rmem_bf16_11
        %903 = cute.get_shape(%lay_1939) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
        %e0_1940, %e1_1941, %e2_1942, %e3_1943 = cute.get_leaves(%903) : !cute.shape<"(((4,2),1),4)">
        %lay_1944 = cute.get_layout(%slice_1928) : !memref_smem_bf16_19
        %shape_1945 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1946 = cute.make_layout(%shape_1945) : !cute.layout<"1:0">
        %append_1947 = cute.append_to_rank<2> (%lay_1944, %lay_1946) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
        %view_1948 = cute.make_view(%iter_1930, %append_1947) : !memref_smem_bf16_19
        %iter_1949 = cute.get_iter(%view_1948) : !memref_smem_bf16_19
        %lay_1950 = cute.get_layout(%view_1948) : !memref_smem_bf16_19
        %904 = cute.get_shape(%lay_1950) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
        %e0_1951, %e1_1952, %e2_1953 = cute.get_leaves(%904) : !cute.shape<"((8,1),4)">
        %grouped_1954 = cute.group_modes(%view_1948) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
        %iter_1955 = cute.get_iter(%grouped_1954) : !memref_smem_bf16_20
        %iter_1956 = cute.get_iter(%grouped_1954) : !memref_smem_bf16_20
        %lay_1957 = cute.get_layout(%slice_1932) : !memref_rmem_bf16_11
        %shape_1958 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1959 = cute.make_layout(%shape_1958) : !cute.layout<"1:0">
        %append_1960 = cute.append_to_rank<2> (%lay_1957, %lay_1959) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
        %view_1961 = cute.make_view(%iter_1934, %append_1960) : !memref_rmem_bf16_11
        %iter_1962 = cute.get_iter(%view_1961) : !memref_rmem_bf16_11
        %lay_1963 = cute.get_layout(%view_1961) : !memref_rmem_bf16_11
        %905 = cute.get_shape(%lay_1963) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
        %e0_1964, %e1_1965, %e2_1966, %e3_1967 = cute.get_leaves(%905) : !cute.shape<"(((4,2),1),4)">
        %grouped_1968 = cute.group_modes(%view_1961) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
        %iter_1969 = cute.get_iter(%grouped_1968) : !memref_rmem_bf16_12
        %iter_1970 = cute.get_iter(%grouped_1968) : !memref_rmem_bf16_12
        %lay_1971 = cute.get_layout(%grouped_1954) : !memref_smem_bf16_20
        %906 = cute.get_shape(%lay_1971) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
        %e0_1972, %e1_1973, %e2_1974 = cute.get_leaves(%906) : !cute.shape<"((8,1),(4))">
        %lay_1975 = cute.get_layout(%grouped_1968) : !memref_rmem_bf16_12
        %907 = cute.get_shape(%lay_1975) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
        %e0_1976, %e1_1977, %e2_1978, %e3_1979 = cute.get_leaves(%907) : !cute.shape<"(((4,2),1),(4))">
        %sz_1980 = cute.size(%grouped_1954) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
        %e0_1981 = cute.get_leaves(%sz_1980) : !cute.int_tuple<"4">
        %sz_1982 = cute.size(%grouped_1968) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
        %e0_1983 = cute.get_leaves(%sz_1982) : !cute.int_tuple<"4">
        cute.copy(%162, %grouped_1954, %grouped_1968) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        %lay_1984 = cute.get_layout(%src_partitioned_397) : !memref_smem_bf16_8
        %908 = cute.get_shape(%lay_1984) : (!cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),1,((2,2),2))">
        %e0_1985, %e1_1986, %e2_1987, %e3_1988, %e4_1989, %e5_1990 = cute.get_leaves(%908) : !cute.shape<"((8,1),1,((2,2),2))">
        %int_tuple_1991 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_1992 = cute.size(%int_tuple_1991) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_1993 = cute.get_leaves(%sz_1992) : !cute.int_tuple<"8">
        %int_tuple_1994 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_1995 = cute.size(%int_tuple_1994) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_1996 = cute.get_leaves(%sz_1995) : !cute.int_tuple<"8">
        %true = arith.constant true
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,1)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,1)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,1)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,1)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_1997 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1998 = cute.slice(%frg_A, %coord_1997) : !memref_rmem_bf16_, !cute.coord<"(_,_,0)">
        %iter_1999 = cute.get_iter(%slice_1998) : !memref_rmem_bf16_13
        %iter_2000 = cute.get_iter(%slice_1998) : !memref_rmem_bf16_13
        %coord_2001 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2002 = cute.slice(%frg_B, %coord_2001) : !memref_rmem_bf16_1, !cute.coord<"(_,_,0)">
        %iter_2003 = cute.get_iter(%slice_2002) : !memref_rmem_bf16_14
        %iter_2004 = cute.get_iter(%slice_2002) : !memref_rmem_bf16_14
        %lay_2005 = cute.get_layout(%slice_1998) : !memref_rmem_bf16_13
        %909 = cute.get_shape(%lay_2005) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2006, %e1_2007, %e2_2008, %e3_2009 = cute.get_leaves(%909) : !cute.shape<"((2,2,2),1)">
        %lay_2010 = cute.get_layout(%slice_2002) : !memref_rmem_bf16_14
        %910 = cute.get_shape(%lay_2010) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2011, %e1_2012, %e2_2013, %e3_2014 = cute.get_leaves(%910) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_1998, %slice_2002, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2015 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2016 = cute.size(%int_tuple_2015) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2017 = cute.get_leaves(%sz_2016) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,2)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,2)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,2)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,2)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2018 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2019 = cute.slice(%frg_A, %coord_2018) : !memref_rmem_bf16_, !cute.coord<"(_,_,1)">
        %iter_2020 = cute.get_iter(%slice_2019) : !memref_rmem_bf16_13
        %iter_2021 = cute.get_iter(%slice_2019) : !memref_rmem_bf16_13
        %coord_2022 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2023 = cute.slice(%frg_B, %coord_2022) : !memref_rmem_bf16_1, !cute.coord<"(_,_,1)">
        %iter_2024 = cute.get_iter(%slice_2023) : !memref_rmem_bf16_14
        %iter_2025 = cute.get_iter(%slice_2023) : !memref_rmem_bf16_14
        %lay_2026 = cute.get_layout(%slice_2019) : !memref_rmem_bf16_13
        %911 = cute.get_shape(%lay_2026) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2027, %e1_2028, %e2_2029, %e3_2030 = cute.get_leaves(%911) : !cute.shape<"((2,2,2),1)">
        %lay_2031 = cute.get_layout(%slice_2023) : !memref_rmem_bf16_14
        %912 = cute.get_shape(%lay_2031) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2032, %e1_2033, %e2_2034, %e3_2035 = cute.get_leaves(%912) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2019, %slice_2023, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2036 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2037 = cute.size(%int_tuple_2036) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2038 = cute.get_leaves(%sz_2037) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,3)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,3)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,3)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,3)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2039 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2040 = cute.slice(%frg_A, %coord_2039) : !memref_rmem_bf16_, !cute.coord<"(_,_,2)">
        %iter_2041 = cute.get_iter(%slice_2040) : !memref_rmem_bf16_13
        %iter_2042 = cute.get_iter(%slice_2040) : !memref_rmem_bf16_13
        %coord_2043 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2044 = cute.slice(%frg_B, %coord_2043) : !memref_rmem_bf16_1, !cute.coord<"(_,_,2)">
        %iter_2045 = cute.get_iter(%slice_2044) : !memref_rmem_bf16_14
        %iter_2046 = cute.get_iter(%slice_2044) : !memref_rmem_bf16_14
        %lay_2047 = cute.get_layout(%slice_2040) : !memref_rmem_bf16_13
        %913 = cute.get_shape(%lay_2047) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2048, %e1_2049, %e2_2050, %e3_2051 = cute.get_leaves(%913) : !cute.shape<"((2,2,2),1)">
        %lay_2052 = cute.get_layout(%slice_2044) : !memref_rmem_bf16_14
        %914 = cute.get_shape(%lay_2052) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2053, %e1_2054, %e2_2055, %e3_2056 = cute.get_leaves(%914) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2040, %slice_2044, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2057 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2058 = cute.size(%int_tuple_2057) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2059 = cute.get_leaves(%sz_2058) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,4)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,4)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,4)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,4)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2060 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2061 = cute.slice(%frg_A, %coord_2060) : !memref_rmem_bf16_, !cute.coord<"(_,_,3)">
        %iter_2062 = cute.get_iter(%slice_2061) : !memref_rmem_bf16_13
        %iter_2063 = cute.get_iter(%slice_2061) : !memref_rmem_bf16_13
        %coord_2064 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2065 = cute.slice(%frg_B, %coord_2064) : !memref_rmem_bf16_1, !cute.coord<"(_,_,3)">
        %iter_2066 = cute.get_iter(%slice_2065) : !memref_rmem_bf16_14
        %iter_2067 = cute.get_iter(%slice_2065) : !memref_rmem_bf16_14
        %lay_2068 = cute.get_layout(%slice_2061) : !memref_rmem_bf16_13
        %915 = cute.get_shape(%lay_2068) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2069, %e1_2070, %e2_2071, %e3_2072 = cute.get_leaves(%915) : !cute.shape<"((2,2,2),1)">
        %lay_2073 = cute.get_layout(%slice_2065) : !memref_rmem_bf16_14
        %916 = cute.get_shape(%lay_2073) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2074, %e1_2075, %e2_2076, %e3_2077 = cute.get_leaves(%916) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2061, %slice_2065, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2078 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2079 = cute.size(%int_tuple_2078) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2080 = cute.get_leaves(%sz_2079) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,5)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,5)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,5)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,5)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2081 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
        %slice_2082 = cute.slice(%frg_A, %coord_2081) : !memref_rmem_bf16_, !cute.coord<"(_,_,4)">
        %iter_2083 = cute.get_iter(%slice_2082) : !memref_rmem_bf16_13
        %iter_2084 = cute.get_iter(%slice_2082) : !memref_rmem_bf16_13
        %coord_2085 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
        %slice_2086 = cute.slice(%frg_B, %coord_2085) : !memref_rmem_bf16_1, !cute.coord<"(_,_,4)">
        %iter_2087 = cute.get_iter(%slice_2086) : !memref_rmem_bf16_14
        %iter_2088 = cute.get_iter(%slice_2086) : !memref_rmem_bf16_14
        %lay_2089 = cute.get_layout(%slice_2082) : !memref_rmem_bf16_13
        %917 = cute.get_shape(%lay_2089) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2090, %e1_2091, %e2_2092, %e3_2093 = cute.get_leaves(%917) : !cute.shape<"((2,2,2),1)">
        %lay_2094 = cute.get_layout(%slice_2086) : !memref_rmem_bf16_14
        %918 = cute.get_shape(%lay_2094) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2095, %e1_2096, %e2_2097, %e3_2098 = cute.get_leaves(%918) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2082, %slice_2086, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2099 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2100 = cute.size(%int_tuple_2099) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2101 = cute.get_leaves(%sz_2100) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,6)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,6)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,6)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,6)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2102 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
        %slice_2103 = cute.slice(%frg_A, %coord_2102) : !memref_rmem_bf16_, !cute.coord<"(_,_,5)">
        %iter_2104 = cute.get_iter(%slice_2103) : !memref_rmem_bf16_13
        %iter_2105 = cute.get_iter(%slice_2103) : !memref_rmem_bf16_13
        %coord_2106 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
        %slice_2107 = cute.slice(%frg_B, %coord_2106) : !memref_rmem_bf16_1, !cute.coord<"(_,_,5)">
        %iter_2108 = cute.get_iter(%slice_2107) : !memref_rmem_bf16_14
        %iter_2109 = cute.get_iter(%slice_2107) : !memref_rmem_bf16_14
        %lay_2110 = cute.get_layout(%slice_2103) : !memref_rmem_bf16_13
        %919 = cute.get_shape(%lay_2110) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2111, %e1_2112, %e2_2113, %e3_2114 = cute.get_leaves(%919) : !cute.shape<"((2,2,2),1)">
        %lay_2115 = cute.get_layout(%slice_2107) : !memref_rmem_bf16_14
        %920 = cute.get_shape(%lay_2115) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2116, %e1_2117, %e2_2118, %e3_2119 = cute.get_leaves(%920) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2103, %slice_2107, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2120 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2121 = cute.size(%int_tuple_2120) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2122 = cute.get_leaves(%sz_2121) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,7)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,7)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,7)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,7)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2123 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
        %slice_2124 = cute.slice(%frg_A, %coord_2123) : !memref_rmem_bf16_, !cute.coord<"(_,_,6)">
        %iter_2125 = cute.get_iter(%slice_2124) : !memref_rmem_bf16_13
        %iter_2126 = cute.get_iter(%slice_2124) : !memref_rmem_bf16_13
        %coord_2127 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
        %slice_2128 = cute.slice(%frg_B, %coord_2127) : !memref_rmem_bf16_1, !cute.coord<"(_,_,6)">
        %iter_2129 = cute.get_iter(%slice_2128) : !memref_rmem_bf16_14
        %iter_2130 = cute.get_iter(%slice_2128) : !memref_rmem_bf16_14
        %lay_2131 = cute.get_layout(%slice_2124) : !memref_rmem_bf16_13
        %921 = cute.get_shape(%lay_2131) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2132, %e1_2133, %e2_2134, %e3_2135 = cute.get_leaves(%921) : !cute.shape<"((2,2,2),1)">
        %lay_2136 = cute.get_layout(%slice_2128) : !memref_rmem_bf16_14
        %922 = cute.get_shape(%lay_2136) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2137, %e1_2138, %e2_2139, %e3_2140 = cute.get_leaves(%922) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2124, %slice_2128, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2141 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2142 = cute.size(%int_tuple_2141) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2143 = cute.get_leaves(%sz_2142) : !cute.int_tuple<"8">
        %false = arith.constant false
        scf.if %false {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2600 = cute.slice(%src_partitioned_397, %coord_2599) : !memref_smem_bf16_8, !cute.coord<"(_,_,8)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_15
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2604 = cute.slice(%retiled, %coord_2603) : !memref_rmem_bf16_3, !cute.coord<"(_,_,8)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_9
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2608, %e1_2609, %e2_2610 = cute.get_leaves(%1041) : !cute.shape<"((8,1),1)">
          %lay_2611 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %1042 = cute.get_shape(%lay_2611) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2612, %e1_2613, %e2_2614 = cute.get_leaves(%1042) : !cute.shape<"((8,1),1)">
          %lay_2615 = cute.get_layout(%slice_2600) : !memref_smem_bf16_15
          %shape_2616 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2617 = cute.make_layout(%shape_2616) : !cute.layout<"1:0">
          %append_2618 = cute.append_to_rank<2> (%lay_2615, %lay_2617) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2619 = cute.make_view(%iter_2602, %append_2618) : !memref_smem_bf16_15
          %iter_2620 = cute.get_iter(%view_2619) : !memref_smem_bf16_15
          %lay_2621 = cute.get_layout(%view_2619) : !memref_smem_bf16_15
          %1043 = cute.get_shape(%lay_2621) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2622, %e1_2623, %e2_2624 = cute.get_leaves(%1043) : !cute.shape<"((8,1),1)">
          %grouped_2625 = cute.group_modes(%view_2619) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2626 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %iter_2627 = cute.get_iter(%grouped_2625) : !memref_smem_bf16_16
          %lay_2628 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_9
          %shape_2629 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2630 = cute.make_layout(%shape_2629) : !cute.layout<"1:0">
          %append_2631 = cute.append_to_rank<2> (%lay_2628, %lay_2630) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2632 = cute.make_view(%iter_2606, %append_2631) : !memref_rmem_bf16_9
          %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_9
          %lay_2634 = cute.get_layout(%view_2632) : !memref_rmem_bf16_9
          %1044 = cute.get_shape(%lay_2634) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2635, %e1_2636, %e2_2637 = cute.get_leaves(%1044) : !cute.shape<"((8,1),1)">
          %grouped_2638 = cute.group_modes(%view_2632) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2639 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %iter_2640 = cute.get_iter(%grouped_2638) : !memref_rmem_bf16_10
          %lay_2641 = cute.get_layout(%grouped_2625) : !memref_smem_bf16_16
          %1045 = cute.get_shape(%lay_2641) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2642, %e1_2643, %e2_2644 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(1))">
          %lay_2645 = cute.get_layout(%grouped_2638) : !memref_rmem_bf16_10
          %1046 = cute.get_shape(%lay_2645) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2646, %e1_2647, %e2_2648 = cute.get_leaves(%1046) : !cute.shape<"((8,1),(1))">
          %sz_2649 = cute.size(%grouped_2625) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2650 = cute.get_leaves(%sz_2649) : !cute.int_tuple<"1">
          %sz_2651 = cute.size(%grouped_2638) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2652 = cute.get_leaves(%sz_2651) : !cute.int_tuple<"1">
          cute.copy(%158, %grouped_2625, %grouped_2638) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2654 = cute.slice(%src_partitioned_401, %coord_2653) : !memref_smem_bf16_9, !cute.coord<"(_,_,8)">
          %iter_2655 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %iter_2656 = cute.get_iter(%slice_2654) : !memref_smem_bf16_19
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2658 = cute.slice(%retiled_403, %coord_2657) : !memref_rmem_bf16_4, !cute.coord<"(_,_,8)">
          %iter_2659 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %iter_2660 = cute.get_iter(%slice_2658) : !memref_rmem_bf16_11
          %lay_2661 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %1047 = cute.get_shape(%lay_2661) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2662, %e1_2663, %e2_2664 = cute.get_leaves(%1047) : !cute.shape<"((8,1),4)">
          %lay_2665 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %1048 = cute.get_shape(%lay_2665) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%1048) : !cute.shape<"(((4,2),1),4)">
          %lay_2670 = cute.get_layout(%slice_2654) : !memref_smem_bf16_19
          %shape_2671 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2672 = cute.make_layout(%shape_2671) : !cute.layout<"1:0">
          %append_2673 = cute.append_to_rank<2> (%lay_2670, %lay_2672) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2674 = cute.make_view(%iter_2656, %append_2673) : !memref_smem_bf16_19
          %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_19
          %lay_2676 = cute.get_layout(%view_2674) : !memref_smem_bf16_19
          %1049 = cute.get_shape(%lay_2676) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2677, %e1_2678, %e2_2679 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4)">
          %grouped_2680 = cute.group_modes(%view_2674) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2681 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %iter_2682 = cute.get_iter(%grouped_2680) : !memref_smem_bf16_20
          %lay_2683 = cute.get_layout(%slice_2658) : !memref_rmem_bf16_11
          %shape_2684 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2685 = cute.make_layout(%shape_2684) : !cute.layout<"1:0">
          %append_2686 = cute.append_to_rank<2> (%lay_2683, %lay_2685) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2687 = cute.make_view(%iter_2660, %append_2686) : !memref_rmem_bf16_11
          %iter_2688 = cute.get_iter(%view_2687) : !memref_rmem_bf16_11
          %lay_2689 = cute.get_layout(%view_2687) : !memref_rmem_bf16_11
          %1050 = cute.get_shape(%lay_2689) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2690, %e1_2691, %e2_2692, %e3_2693 = cute.get_leaves(%1050) : !cute.shape<"(((4,2),1),4)">
          %grouped_2694 = cute.group_modes(%view_2687) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2695 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %iter_2696 = cute.get_iter(%grouped_2694) : !memref_rmem_bf16_12
          %lay_2697 = cute.get_layout(%grouped_2680) : !memref_smem_bf16_20
          %1051 = cute.get_shape(%lay_2697) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2698, %e1_2699, %e2_2700 = cute.get_leaves(%1051) : !cute.shape<"((8,1),(4))">
          %lay_2701 = cute.get_layout(%grouped_2694) : !memref_rmem_bf16_12
          %1052 = cute.get_shape(%lay_2701) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1052) : !cute.shape<"(((4,2),1),(4))">
          %sz_2706 = cute.size(%grouped_2680) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2707 = cute.get_leaves(%sz_2706) : !cute.int_tuple<"4">
          %sz_2708 = cute.size(%grouped_2694) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2709 = cute.get_leaves(%sz_2708) : !cute.int_tuple<"4">
          cute.copy(%162, %grouped_2680, %grouped_2694) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2144 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
        %slice_2145 = cute.slice(%frg_A, %coord_2144) : !memref_rmem_bf16_, !cute.coord<"(_,_,7)">
        %iter_2146 = cute.get_iter(%slice_2145) : !memref_rmem_bf16_13
        %iter_2147 = cute.get_iter(%slice_2145) : !memref_rmem_bf16_13
        %coord_2148 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
        %slice_2149 = cute.slice(%frg_B, %coord_2148) : !memref_rmem_bf16_1, !cute.coord<"(_,_,7)">
        %iter_2150 = cute.get_iter(%slice_2149) : !memref_rmem_bf16_14
        %iter_2151 = cute.get_iter(%slice_2149) : !memref_rmem_bf16_14
        %lay_2152 = cute.get_layout(%slice_2145) : !memref_rmem_bf16_13
        %923 = cute.get_shape(%lay_2152) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2153, %e1_2154, %e2_2155, %e3_2156 = cute.get_leaves(%923) : !cute.shape<"((2,2,2),1)">
        %lay_2157 = cute.get_layout(%slice_2149) : !memref_rmem_bf16_14
        %924 = cute.get_shape(%lay_2157) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2158, %e1_2159, %e2_2160, %e3_2161 = cute.get_leaves(%924) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%6, %rmem_1779, %slice_2145, %slice_2149, %rmem_1779) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        nvvm.cp.async.wait.group 0
        %c1_i32_2162 = arith.constant 1 : i32
        %c128_i32_2163 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_2162 number_of_threads = %c128_i32_2163
        %c0_i32_2164 = arith.constant 0 : i32
        %925 = arith.cmpi sgt, %882, %c0_i32_2164 : i32
        scf.if %925 {
          %int_tuple_2599 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sub_2600 = cute.tuple_sub(%sub_1769, %int_tuple_2599) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %1041 = cute.get_scalars(%sub_2600) : !cute.int_tuple<"?">
          %coord_2601 = cute.make_coord(%sub_2600) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %slice_2602 = cute.slice(%src_partitioned_294, %coord_2601) : !memref_gmem_bf16_6, !cute.coord<"(_,_,_,?)">
          %iter_2603 = cute.get_iter(%slice_2602) : !memref_gmem_bf16_5
          %iter_2604 = cute.get_iter(%slice_2602) : !memref_gmem_bf16_5
          %coord_2605 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2606 = cute.slice(%dst_partitioned_297, %coord_2605) : !memref_smem_bf16_3, !cute.coord<"(_,_,_)">
          %iter_2607 = cute.get_iter(%slice_2606) : !memref_smem_bf16_3
          %iter_2608 = cute.get_iter(%slice_2606) : !memref_smem_bf16_3
          %coord_2609 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2610 = cute.slice(%rmem_570, %coord_2609) : !memref_rmem_i8_, !cute.coord<"(_,_,_)">
          %iter_2611 = cute.get_iter(%slice_2610) : !memref_rmem_i8_
          %iter_2612 = cute.get_iter(%slice_2610) : !memref_rmem_i8_
          %lay_2613 = cute.get_layout(%slice_2602) : !memref_gmem_bf16_5
          %1042 = cute.get_shape(%lay_2613) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1042) : !cute.shape<"((8,1),4,2)">
          %lay_2618 = cute.get_layout(%slice_2606) : !memref_smem_bf16_3
          %1043 = cute.get_shape(%lay_2618) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2619, %e1_2620, %e2_2621, %e3_2622 = cute.get_leaves(%1043) : !cute.shape<"((8,1),4,2)">
          %lay_2623 = cute.get_layout(%slice_2602) : !memref_gmem_bf16_5
          %shape_2624 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2625 = cute.make_layout(%shape_2624) : !cute.layout<"1:0">
          %append_2626 = cute.append_to_rank<2> (%lay_2623, %lay_2625) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_2627 = cute.make_view(%iter_2604, %append_2626) : !memref_gmem_bf16_5
          %iter_2628 = cute.get_iter(%view_2627) : !memref_gmem_bf16_5
          %lay_2629 = cute.get_layout(%view_2627) : !memref_gmem_bf16_5
          %1044 = cute.get_shape(%lay_2629) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2630, %e1_2631, %e2_2632, %e3_2633 = cute.get_leaves(%1044) : !cute.shape<"((8,1),4,2)">
          %grouped_2634 = cute.group_modes(%view_2627) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_13
          %iter_2635 = cute.get_iter(%grouped_2634) : !memref_gmem_bf16_13
          %iter_2636 = cute.get_iter(%grouped_2634) : !memref_gmem_bf16_13
          %lay_2637 = cute.get_layout(%slice_2606) : !memref_smem_bf16_3
          %shape_2638 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2639 = cute.make_layout(%shape_2638) : !cute.layout<"1:0">
          %append_2640 = cute.append_to_rank<2> (%lay_2637, %lay_2639) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
          %view_2641 = cute.make_view(%iter_2608, %append_2640) : !memref_smem_bf16_3
          %iter_2642 = cute.get_iter(%view_2641) : !memref_smem_bf16_3
          %lay_2643 = cute.get_layout(%view_2641) : !memref_smem_bf16_3
          %1045 = cute.get_shape(%lay_2643) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2644, %e1_2645, %e2_2646, %e3_2647 = cute.get_leaves(%1045) : !cute.shape<"((8,1),4,2)">
          %grouped_2648 = cute.group_modes(%view_2641) <1, 3> : (!memref_smem_bf16_3) -> !memref_smem_bf16_17
          %iter_2649 = cute.get_iter(%grouped_2648) : !memref_smem_bf16_17
          %iter_2650 = cute.get_iter(%grouped_2648) : !memref_smem_bf16_17
          %lay_2651 = cute.get_layout(%slice_2610) : !memref_rmem_i8_
          %shape_2652 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2653 = cute.make_layout(%shape_2652) : !cute.layout<"1:0">
          %append_2654 = cute.append_to_rank<2> (%lay_2651, %lay_2653) : !cute.layout<"(1,4,2):(2,0,1)">, !cute.layout<"1:0">
          %view_2655 = cute.make_view(%iter_2612, %append_2654) : !memref_rmem_i8_
          %iter_2656 = cute.get_iter(%view_2655) : !memref_rmem_i8_
          %lay_2657 = cute.get_layout(%view_2655) : !memref_rmem_i8_
          %1046 = cute.get_shape(%lay_2657) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
          %e0_2658, %e1_2659, %e2_2660 = cute.get_leaves(%1046) : !cute.shape<"(1,4,2)">
          %grouped_2661 = cute.group_modes(%view_2655) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_3
          %iter_2662 = cute.get_iter(%grouped_2661) : !memref_rmem_i8_3
          %iter_2663 = cute.get_iter(%grouped_2661) : !memref_rmem_i8_3
          %lay_2664 = cute.get_layout(%grouped_2634) : !memref_gmem_bf16_13
          %1047 = cute.get_shape(%lay_2664) : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2665, %e1_2666, %e2_2667, %e3_2668 = cute.get_leaves(%1047) : !cute.shape<"((8,1),(4,2))">
          %lay_2669 = cute.get_layout(%grouped_2648) : !memref_smem_bf16_17
          %1048 = cute.get_shape(%lay_2669) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2670, %e1_2671, %e2_2672, %e3_2673 = cute.get_leaves(%1048) : !cute.shape<"((8,1),(4,2))">
          %sz_2674 = cute.size(%grouped_2634) <{mode = [1]}> : (!memref_gmem_bf16_13) -> !cute.int_tuple<"8">
          %e0_2675 = cute.get_leaves(%sz_2674) : !cute.int_tuple<"8">
          %sz_2676 = cute.size(%grouped_2648) <{mode = [1]}> : (!memref_smem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2677 = cute.get_leaves(%sz_2676) : !cute.int_tuple<"8">
          cute.copy(%4, %grouped_2634, %grouped_2648, %grouped_2661) : (!copy_ldgsts, !memref_gmem_bf16_13, !memref_smem_bf16_17, !memref_rmem_i8_3)
          %lay_2678 = cute.get_layout(%src_partitioned_533) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %1049 = cute.get_shape(%lay_2678) : (!cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.shape<"((8,1),4,1,?)">
          %e0_2679, %e1_2680, %e2_2681, %e3_2682, %e4_2683 = cute.get_leaves(%1049) : !cute.shape<"((8,1),4,1,?)">
          %itup_2684 = cute.to_int_tuple(%e4_2683) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1050 = cute.get_scalars(%itup_2684) : !cute.int_tuple<"?">
          %int_tuple_2685 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %sz_2686 = cute.size(%int_tuple_2685) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
          %e0_2687 = cute.get_leaves(%sz_2686) : !cute.int_tuple<"4">
          %coord_2688 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %slice_2689 = cute.slice(%src_partitioned_533, %coord_2688) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
          %iter_2690 = cute.get_iter(%slice_2689) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2691, %e1_2692, %e2_2693, %e3_2694 = cute.get_leaves(%iter_2690) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1051 = cute.get_scalars(%e0_2691) : !cute.int_tuple<"?">
          %1052 = cute.get_scalars(%e1_2692) : !cute.int_tuple<"?">
          %1053 = cute.get_scalars(%e2_2693) : !cute.int_tuple<"?">
          %1054 = cute.get_scalars(%e3_2694) : !cute.int_tuple<"?{div=8}">
          %iter_2695 = cute.get_iter(%slice_2689) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2696, %e1_2697, %e2_2698, %e3_2699 = cute.get_leaves(%iter_2695) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1055 = cute.get_scalars(%e0_2696) : !cute.int_tuple<"?">
          %1056 = cute.get_scalars(%e1_2697) : !cute.int_tuple<"?">
          %1057 = cute.get_scalars(%e2_2698) : !cute.int_tuple<"?">
          %1058 = cute.get_scalars(%e3_2699) : !cute.int_tuple<"?{div=8}">
          %iter_2700 = cute.get_iter(%slice_2689) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2701, %e1_2702, %e2_2703, %e3_2704 = cute.get_leaves(%iter_2700) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1059 = cute.get_scalars(%e0_2701) : !cute.int_tuple<"?">
          %1060 = cute.get_scalars(%e1_2702) : !cute.int_tuple<"?">
          %1061 = cute.get_scalars(%e2_2703) : !cute.int_tuple<"?">
          %1062 = cute.get_scalars(%e3_2704) : !cute.int_tuple<"?{div=8}">
          %lay_2705 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1063 = cute.get_shape(%lay_2705) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2706, %e1_2707, %e2_2708, %e3_2709 = cute.get_leaves(%1063) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2710 = cute.to_int_tuple(%e0_2706) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1064 = cute.get_scalars(%itup_2710) : !cute.int_tuple<"?">
          %itup_2711 = cute.to_int_tuple(%e1_2707) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1065 = cute.get_scalars(%itup_2711) : !cute.int_tuple<"?">
          %itup_2712 = cute.to_int_tuple(%e2_2708) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1066 = cute.get_scalars(%itup_2712) : !cute.int_tuple<"?">
          %itup_2713 = cute.to_int_tuple(%e3_2709) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1067 = cute.get_scalars(%itup_2713) : !cute.int_tuple<"?{div=8}">
          %coord_2714 = cute.make_coord(%e1_2702) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2715 = cute.make_coord(%itup_2712) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1068 = cute.elem_less(%coord_2714, %coord_2715) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1068 {
            %int_tuple_2800 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2801 = cute.tuple_sub(%sub_1769, %int_tuple_2800) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1123 = cute.get_scalars(%sub_2801) : !cute.int_tuple<"?">
            %coord_2802 = cute.make_coord(%sub_2801) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %slice_2803 = cute.slice(%src_partitioned_306, %coord_2802) : !memref_gmem_bf16_7, !cute.coord<"(_,0,_,?)">
            %iter_2804 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %iter_2805 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %coord_2806 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2807 = cute.slice(%dst_partitioned_309, %coord_2806) : !memref_smem_bf16_4, !cute.coord<"(_,0,_)">
            %iter_2808 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %iter_2809 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %lay_2810 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %1124 = cute.get_shape(%lay_2810) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2811, %e1_2812, %e2_2813 = cute.get_leaves(%1124) : !cute.shape<"((8,1),1)">
            %lay_2814 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %1125 = cute.get_shape(%lay_2814) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2815, %e1_2816, %e2_2817 = cute.get_leaves(%1125) : !cute.shape<"((8,1),1)">
            %lay_2818 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %shape_2819 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2820 = cute.make_layout(%shape_2819) : !cute.layout<"1:0">
            %append_2821 = cute.append_to_rank<2> (%lay_2818, %lay_2820) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2822 = cute.make_view(%iter_2805, %append_2821) : !memref_gmem_bf16_11
            %iter_2823 = cute.get_iter(%view_2822) : !memref_gmem_bf16_11
            %lay_2824 = cute.get_layout(%view_2822) : !memref_gmem_bf16_11
            %1126 = cute.get_shape(%lay_2824) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2825, %e1_2826, %e2_2827 = cute.get_leaves(%1126) : !cute.shape<"((8,1),1)">
            %grouped_2828 = cute.group_modes(%view_2822) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2829 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %iter_2830 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %lay_2831 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %shape_2832 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2833 = cute.make_layout(%shape_2832) : !cute.layout<"1:0">
            %append_2834 = cute.append_to_rank<2> (%lay_2831, %lay_2833) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2835 = cute.make_view(%iter_2809, %append_2834) : !memref_smem_bf16_15
            %iter_2836 = cute.get_iter(%view_2835) : !memref_smem_bf16_15
            %lay_2837 = cute.get_layout(%view_2835) : !memref_smem_bf16_15
            %1127 = cute.get_shape(%lay_2837) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2838, %e1_2839, %e2_2840 = cute.get_leaves(%1127) : !cute.shape<"((8,1),1)">
            %grouped_2841 = cute.group_modes(%view_2835) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2842 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %iter_2843 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %lay_2844 = cute.get_layout(%grouped_2828) : !memref_gmem_bf16_12
            %1128 = cute.get_shape(%lay_2844) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2845, %e1_2846, %e2_2847 = cute.get_leaves(%1128) : !cute.shape<"((8,1),(1))">
            %lay_2848 = cute.get_layout(%grouped_2841) : !memref_smem_bf16_16
            %1129 = cute.get_shape(%lay_2848) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2849, %e1_2850, %e2_2851 = cute.get_leaves(%1129) : !cute.shape<"((8,1),(1))">
            %sz_2852 = cute.size(%grouped_2828) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2853 = cute.get_leaves(%sz_2852) : !cute.int_tuple<"1">
            %sz_2854 = cute.size(%grouped_2841) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2855 = cute.get_leaves(%sz_2854) : !cute.int_tuple<"1">
            cute.copy(%4, %grouped_2828, %grouped_2841) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2800 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2801 = cute.slice(%dst_partitioned_309, %coord_2800) : !memref_smem_bf16_4, !cute.coord<"(_,0,_)">
            %iter_2802 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %iter_2803 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %sz_2804 = cute.size(%slice_2801) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2805 = cute.get_leaves(%sz_2804) : !cute.int_tuple<"8">
            %lay_2806 = cute.get_layout(%slice_2801) : !memref_smem_bf16_15
            %1123 = cute.get_shape(%lay_2806) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2807, %e1_2808, %e2_2809 = cute.get_leaves(%1123) : !cute.shape<"((8,1),1)">
            %int_tuple_2810 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2811 = cute.tuple.product(%int_tuple_2810) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2812 = cute.get_leaves(%res_2811) : !cute.int_tuple<"8">
            %cst_2813 = arith.constant 0.000000e+00 : bf16
            %1124 = vector.splat %cst_2813 : vector<8xbf16>
            %int_tuple_2814 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2815 = cute.size(%int_tuple_2814) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2816 = cute.get_leaves(%sz_2815) : !cute.int_tuple<"8">
            %int_tuple_2817 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2818 = cute.size(%int_tuple_2817) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2819 = cute.get_leaves(%sz_2818) : !cute.int_tuple<"8">
            cute.memref.store_vec %1124, %slice_2801 : !memref_smem_bf16_15
          }
          %coord_2716 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %slice_2717 = cute.slice(%src_partitioned_533, %coord_2716) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
          %iter_2718 = cute.get_iter(%slice_2717) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2719, %e1_2720, %e2_2721, %e3_2722 = cute.get_leaves(%iter_2718) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1069 = cute.get_scalars(%e0_2719) : !cute.int_tuple<"?">
          %1070 = cute.get_scalars(%e1_2720) : !cute.int_tuple<"?">
          %1071 = cute.get_scalars(%e2_2721) : !cute.int_tuple<"?">
          %1072 = cute.get_scalars(%e3_2722) : !cute.int_tuple<"?{div=8}">
          %iter_2723 = cute.get_iter(%slice_2717) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2724, %e1_2725, %e2_2726, %e3_2727 = cute.get_leaves(%iter_2723) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1073 = cute.get_scalars(%e0_2724) : !cute.int_tuple<"?">
          %1074 = cute.get_scalars(%e1_2725) : !cute.int_tuple<"?">
          %1075 = cute.get_scalars(%e2_2726) : !cute.int_tuple<"?">
          %1076 = cute.get_scalars(%e3_2727) : !cute.int_tuple<"?{div=8}">
          %iter_2728 = cute.get_iter(%slice_2717) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2729, %e1_2730, %e2_2731, %e3_2732 = cute.get_leaves(%iter_2728) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1077 = cute.get_scalars(%e0_2729) : !cute.int_tuple<"?">
          %1078 = cute.get_scalars(%e1_2730) : !cute.int_tuple<"?">
          %1079 = cute.get_scalars(%e2_2731) : !cute.int_tuple<"?">
          %1080 = cute.get_scalars(%e3_2732) : !cute.int_tuple<"?{div=8}">
          %lay_2733 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1081 = cute.get_shape(%lay_2733) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2734, %e1_2735, %e2_2736, %e3_2737 = cute.get_leaves(%1081) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2738 = cute.to_int_tuple(%e0_2734) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1082 = cute.get_scalars(%itup_2738) : !cute.int_tuple<"?">
          %itup_2739 = cute.to_int_tuple(%e1_2735) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1083 = cute.get_scalars(%itup_2739) : !cute.int_tuple<"?">
          %itup_2740 = cute.to_int_tuple(%e2_2736) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1084 = cute.get_scalars(%itup_2740) : !cute.int_tuple<"?">
          %itup_2741 = cute.to_int_tuple(%e3_2737) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1085 = cute.get_scalars(%itup_2741) : !cute.int_tuple<"?{div=8}">
          %coord_2742 = cute.make_coord(%e1_2730) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2743 = cute.make_coord(%itup_2740) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1086 = cute.elem_less(%coord_2742, %coord_2743) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1086 {
            %int_tuple_2800 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2801 = cute.tuple_sub(%sub_1769, %int_tuple_2800) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1123 = cute.get_scalars(%sub_2801) : !cute.int_tuple<"?">
            %coord_2802 = cute.make_coord(%sub_2801) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %slice_2803 = cute.slice(%src_partitioned_306, %coord_2802) : !memref_gmem_bf16_7, !cute.coord<"(_,1,_,?)">
            %iter_2804 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %iter_2805 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %coord_2806 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2807 = cute.slice(%dst_partitioned_309, %coord_2806) : !memref_smem_bf16_4, !cute.coord<"(_,1,_)">
            %iter_2808 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %iter_2809 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %lay_2810 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %1124 = cute.get_shape(%lay_2810) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2811, %e1_2812, %e2_2813 = cute.get_leaves(%1124) : !cute.shape<"((8,1),1)">
            %lay_2814 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %1125 = cute.get_shape(%lay_2814) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2815, %e1_2816, %e2_2817 = cute.get_leaves(%1125) : !cute.shape<"((8,1),1)">
            %lay_2818 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %shape_2819 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2820 = cute.make_layout(%shape_2819) : !cute.layout<"1:0">
            %append_2821 = cute.append_to_rank<2> (%lay_2818, %lay_2820) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2822 = cute.make_view(%iter_2805, %append_2821) : !memref_gmem_bf16_11
            %iter_2823 = cute.get_iter(%view_2822) : !memref_gmem_bf16_11
            %lay_2824 = cute.get_layout(%view_2822) : !memref_gmem_bf16_11
            %1126 = cute.get_shape(%lay_2824) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2825, %e1_2826, %e2_2827 = cute.get_leaves(%1126) : !cute.shape<"((8,1),1)">
            %grouped_2828 = cute.group_modes(%view_2822) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2829 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %iter_2830 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %lay_2831 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %shape_2832 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2833 = cute.make_layout(%shape_2832) : !cute.layout<"1:0">
            %append_2834 = cute.append_to_rank<2> (%lay_2831, %lay_2833) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2835 = cute.make_view(%iter_2809, %append_2834) : !memref_smem_bf16_15
            %iter_2836 = cute.get_iter(%view_2835) : !memref_smem_bf16_15
            %lay_2837 = cute.get_layout(%view_2835) : !memref_smem_bf16_15
            %1127 = cute.get_shape(%lay_2837) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2838, %e1_2839, %e2_2840 = cute.get_leaves(%1127) : !cute.shape<"((8,1),1)">
            %grouped_2841 = cute.group_modes(%view_2835) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2842 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %iter_2843 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %lay_2844 = cute.get_layout(%grouped_2828) : !memref_gmem_bf16_12
            %1128 = cute.get_shape(%lay_2844) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2845, %e1_2846, %e2_2847 = cute.get_leaves(%1128) : !cute.shape<"((8,1),(1))">
            %lay_2848 = cute.get_layout(%grouped_2841) : !memref_smem_bf16_16
            %1129 = cute.get_shape(%lay_2848) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2849, %e1_2850, %e2_2851 = cute.get_leaves(%1129) : !cute.shape<"((8,1),(1))">
            %sz_2852 = cute.size(%grouped_2828) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2853 = cute.get_leaves(%sz_2852) : !cute.int_tuple<"1">
            %sz_2854 = cute.size(%grouped_2841) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2855 = cute.get_leaves(%sz_2854) : !cute.int_tuple<"1">
            cute.copy(%4, %grouped_2828, %grouped_2841) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2800 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2801 = cute.slice(%dst_partitioned_309, %coord_2800) : !memref_smem_bf16_4, !cute.coord<"(_,1,_)">
            %iter_2802 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %iter_2803 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %sz_2804 = cute.size(%slice_2801) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2805 = cute.get_leaves(%sz_2804) : !cute.int_tuple<"8">
            %lay_2806 = cute.get_layout(%slice_2801) : !memref_smem_bf16_15
            %1123 = cute.get_shape(%lay_2806) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2807, %e1_2808, %e2_2809 = cute.get_leaves(%1123) : !cute.shape<"((8,1),1)">
            %int_tuple_2810 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2811 = cute.tuple.product(%int_tuple_2810) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2812 = cute.get_leaves(%res_2811) : !cute.int_tuple<"8">
            %cst_2813 = arith.constant 0.000000e+00 : bf16
            %1124 = vector.splat %cst_2813 : vector<8xbf16>
            %int_tuple_2814 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2815 = cute.size(%int_tuple_2814) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2816 = cute.get_leaves(%sz_2815) : !cute.int_tuple<"8">
            %int_tuple_2817 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2818 = cute.size(%int_tuple_2817) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2819 = cute.get_leaves(%sz_2818) : !cute.int_tuple<"8">
            cute.memref.store_vec %1124, %slice_2801 : !memref_smem_bf16_15
          }
          %coord_2744 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %slice_2745 = cute.slice(%src_partitioned_533, %coord_2744) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
          %iter_2746 = cute.get_iter(%slice_2745) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2747, %e1_2748, %e2_2749, %e3_2750 = cute.get_leaves(%iter_2746) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1087 = cute.get_scalars(%e0_2747) : !cute.int_tuple<"?">
          %1088 = cute.get_scalars(%e1_2748) : !cute.int_tuple<"?">
          %1089 = cute.get_scalars(%e2_2749) : !cute.int_tuple<"?">
          %1090 = cute.get_scalars(%e3_2750) : !cute.int_tuple<"?{div=8}">
          %iter_2751 = cute.get_iter(%slice_2745) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2752, %e1_2753, %e2_2754, %e3_2755 = cute.get_leaves(%iter_2751) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1091 = cute.get_scalars(%e0_2752) : !cute.int_tuple<"?">
          %1092 = cute.get_scalars(%e1_2753) : !cute.int_tuple<"?">
          %1093 = cute.get_scalars(%e2_2754) : !cute.int_tuple<"?">
          %1094 = cute.get_scalars(%e3_2755) : !cute.int_tuple<"?{div=8}">
          %iter_2756 = cute.get_iter(%slice_2745) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2757, %e1_2758, %e2_2759, %e3_2760 = cute.get_leaves(%iter_2756) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1095 = cute.get_scalars(%e0_2757) : !cute.int_tuple<"?">
          %1096 = cute.get_scalars(%e1_2758) : !cute.int_tuple<"?">
          %1097 = cute.get_scalars(%e2_2759) : !cute.int_tuple<"?">
          %1098 = cute.get_scalars(%e3_2760) : !cute.int_tuple<"?{div=8}">
          %lay_2761 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1099 = cute.get_shape(%lay_2761) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2762, %e1_2763, %e2_2764, %e3_2765 = cute.get_leaves(%1099) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2766 = cute.to_int_tuple(%e0_2762) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1100 = cute.get_scalars(%itup_2766) : !cute.int_tuple<"?">
          %itup_2767 = cute.to_int_tuple(%e1_2763) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1101 = cute.get_scalars(%itup_2767) : !cute.int_tuple<"?">
          %itup_2768 = cute.to_int_tuple(%e2_2764) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1102 = cute.get_scalars(%itup_2768) : !cute.int_tuple<"?">
          %itup_2769 = cute.to_int_tuple(%e3_2765) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1103 = cute.get_scalars(%itup_2769) : !cute.int_tuple<"?{div=8}">
          %coord_2770 = cute.make_coord(%e1_2758) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2771 = cute.make_coord(%itup_2768) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1104 = cute.elem_less(%coord_2770, %coord_2771) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1104 {
            %int_tuple_2800 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2801 = cute.tuple_sub(%sub_1769, %int_tuple_2800) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1123 = cute.get_scalars(%sub_2801) : !cute.int_tuple<"?">
            %coord_2802 = cute.make_coord(%sub_2801) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %slice_2803 = cute.slice(%src_partitioned_306, %coord_2802) : !memref_gmem_bf16_7, !cute.coord<"(_,2,_,?)">
            %iter_2804 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %iter_2805 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %coord_2806 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2807 = cute.slice(%dst_partitioned_309, %coord_2806) : !memref_smem_bf16_4, !cute.coord<"(_,2,_)">
            %iter_2808 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %iter_2809 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %lay_2810 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %1124 = cute.get_shape(%lay_2810) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2811, %e1_2812, %e2_2813 = cute.get_leaves(%1124) : !cute.shape<"((8,1),1)">
            %lay_2814 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %1125 = cute.get_shape(%lay_2814) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2815, %e1_2816, %e2_2817 = cute.get_leaves(%1125) : !cute.shape<"((8,1),1)">
            %lay_2818 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %shape_2819 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2820 = cute.make_layout(%shape_2819) : !cute.layout<"1:0">
            %append_2821 = cute.append_to_rank<2> (%lay_2818, %lay_2820) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2822 = cute.make_view(%iter_2805, %append_2821) : !memref_gmem_bf16_11
            %iter_2823 = cute.get_iter(%view_2822) : !memref_gmem_bf16_11
            %lay_2824 = cute.get_layout(%view_2822) : !memref_gmem_bf16_11
            %1126 = cute.get_shape(%lay_2824) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2825, %e1_2826, %e2_2827 = cute.get_leaves(%1126) : !cute.shape<"((8,1),1)">
            %grouped_2828 = cute.group_modes(%view_2822) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2829 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %iter_2830 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %lay_2831 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %shape_2832 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2833 = cute.make_layout(%shape_2832) : !cute.layout<"1:0">
            %append_2834 = cute.append_to_rank<2> (%lay_2831, %lay_2833) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2835 = cute.make_view(%iter_2809, %append_2834) : !memref_smem_bf16_15
            %iter_2836 = cute.get_iter(%view_2835) : !memref_smem_bf16_15
            %lay_2837 = cute.get_layout(%view_2835) : !memref_smem_bf16_15
            %1127 = cute.get_shape(%lay_2837) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2838, %e1_2839, %e2_2840 = cute.get_leaves(%1127) : !cute.shape<"((8,1),1)">
            %grouped_2841 = cute.group_modes(%view_2835) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2842 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %iter_2843 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %lay_2844 = cute.get_layout(%grouped_2828) : !memref_gmem_bf16_12
            %1128 = cute.get_shape(%lay_2844) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2845, %e1_2846, %e2_2847 = cute.get_leaves(%1128) : !cute.shape<"((8,1),(1))">
            %lay_2848 = cute.get_layout(%grouped_2841) : !memref_smem_bf16_16
            %1129 = cute.get_shape(%lay_2848) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2849, %e1_2850, %e2_2851 = cute.get_leaves(%1129) : !cute.shape<"((8,1),(1))">
            %sz_2852 = cute.size(%grouped_2828) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2853 = cute.get_leaves(%sz_2852) : !cute.int_tuple<"1">
            %sz_2854 = cute.size(%grouped_2841) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2855 = cute.get_leaves(%sz_2854) : !cute.int_tuple<"1">
            cute.copy(%4, %grouped_2828, %grouped_2841) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2800 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2801 = cute.slice(%dst_partitioned_309, %coord_2800) : !memref_smem_bf16_4, !cute.coord<"(_,2,_)">
            %iter_2802 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %iter_2803 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %sz_2804 = cute.size(%slice_2801) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2805 = cute.get_leaves(%sz_2804) : !cute.int_tuple<"8">
            %lay_2806 = cute.get_layout(%slice_2801) : !memref_smem_bf16_15
            %1123 = cute.get_shape(%lay_2806) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2807, %e1_2808, %e2_2809 = cute.get_leaves(%1123) : !cute.shape<"((8,1),1)">
            %int_tuple_2810 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2811 = cute.tuple.product(%int_tuple_2810) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2812 = cute.get_leaves(%res_2811) : !cute.int_tuple<"8">
            %cst_2813 = arith.constant 0.000000e+00 : bf16
            %1124 = vector.splat %cst_2813 : vector<8xbf16>
            %int_tuple_2814 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2815 = cute.size(%int_tuple_2814) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2816 = cute.get_leaves(%sz_2815) : !cute.int_tuple<"8">
            %int_tuple_2817 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2818 = cute.size(%int_tuple_2817) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2819 = cute.get_leaves(%sz_2818) : !cute.int_tuple<"8">
            cute.memref.store_vec %1124, %slice_2801 : !memref_smem_bf16_15
          }
          %coord_2772 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %slice_2773 = cute.slice(%src_partitioned_533, %coord_2772) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
          %iter_2774 = cute.get_iter(%slice_2773) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2775, %e1_2776, %e2_2777, %e3_2778 = cute.get_leaves(%iter_2774) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1105 = cute.get_scalars(%e0_2775) : !cute.int_tuple<"?">
          %1106 = cute.get_scalars(%e1_2776) : !cute.int_tuple<"?">
          %1107 = cute.get_scalars(%e2_2777) : !cute.int_tuple<"?">
          %1108 = cute.get_scalars(%e3_2778) : !cute.int_tuple<"?{div=8}">
          %iter_2779 = cute.get_iter(%slice_2773) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2780, %e1_2781, %e2_2782, %e3_2783 = cute.get_leaves(%iter_2779) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1109 = cute.get_scalars(%e0_2780) : !cute.int_tuple<"?">
          %1110 = cute.get_scalars(%e1_2781) : !cute.int_tuple<"?">
          %1111 = cute.get_scalars(%e2_2782) : !cute.int_tuple<"?">
          %1112 = cute.get_scalars(%e3_2783) : !cute.int_tuple<"?{div=8}">
          %iter_2784 = cute.get_iter(%slice_2773) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2785, %e1_2786, %e2_2787, %e3_2788 = cute.get_leaves(%iter_2784) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1113 = cute.get_scalars(%e0_2785) : !cute.int_tuple<"?">
          %1114 = cute.get_scalars(%e1_2786) : !cute.int_tuple<"?">
          %1115 = cute.get_scalars(%e2_2787) : !cute.int_tuple<"?">
          %1116 = cute.get_scalars(%e3_2788) : !cute.int_tuple<"?{div=8}">
          %lay_2789 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1117 = cute.get_shape(%lay_2789) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2790, %e1_2791, %e2_2792, %e3_2793 = cute.get_leaves(%1117) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2794 = cute.to_int_tuple(%e0_2790) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1118 = cute.get_scalars(%itup_2794) : !cute.int_tuple<"?">
          %itup_2795 = cute.to_int_tuple(%e1_2791) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1119 = cute.get_scalars(%itup_2795) : !cute.int_tuple<"?">
          %itup_2796 = cute.to_int_tuple(%e2_2792) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1120 = cute.get_scalars(%itup_2796) : !cute.int_tuple<"?">
          %itup_2797 = cute.to_int_tuple(%e3_2793) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1121 = cute.get_scalars(%itup_2797) : !cute.int_tuple<"?{div=8}">
          %coord_2798 = cute.make_coord(%e1_2786) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2799 = cute.make_coord(%itup_2796) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1122 = cute.elem_less(%coord_2798, %coord_2799) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1122 {
            %int_tuple_2800 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2801 = cute.tuple_sub(%sub_1769, %int_tuple_2800) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1123 = cute.get_scalars(%sub_2801) : !cute.int_tuple<"?">
            %coord_2802 = cute.make_coord(%sub_2801) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %slice_2803 = cute.slice(%src_partitioned_306, %coord_2802) : !memref_gmem_bf16_7, !cute.coord<"(_,3,_,?)">
            %iter_2804 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %iter_2805 = cute.get_iter(%slice_2803) : !memref_gmem_bf16_11
            %coord_2806 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2807 = cute.slice(%dst_partitioned_309, %coord_2806) : !memref_smem_bf16_4, !cute.coord<"(_,3,_)">
            %iter_2808 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %iter_2809 = cute.get_iter(%slice_2807) : !memref_smem_bf16_15
            %lay_2810 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %1124 = cute.get_shape(%lay_2810) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2811, %e1_2812, %e2_2813 = cute.get_leaves(%1124) : !cute.shape<"((8,1),1)">
            %lay_2814 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %1125 = cute.get_shape(%lay_2814) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2815, %e1_2816, %e2_2817 = cute.get_leaves(%1125) : !cute.shape<"((8,1),1)">
            %lay_2818 = cute.get_layout(%slice_2803) : !memref_gmem_bf16_11
            %shape_2819 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2820 = cute.make_layout(%shape_2819) : !cute.layout<"1:0">
            %append_2821 = cute.append_to_rank<2> (%lay_2818, %lay_2820) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2822 = cute.make_view(%iter_2805, %append_2821) : !memref_gmem_bf16_11
            %iter_2823 = cute.get_iter(%view_2822) : !memref_gmem_bf16_11
            %lay_2824 = cute.get_layout(%view_2822) : !memref_gmem_bf16_11
            %1126 = cute.get_shape(%lay_2824) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2825, %e1_2826, %e2_2827 = cute.get_leaves(%1126) : !cute.shape<"((8,1),1)">
            %grouped_2828 = cute.group_modes(%view_2822) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2829 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %iter_2830 = cute.get_iter(%grouped_2828) : !memref_gmem_bf16_12
            %lay_2831 = cute.get_layout(%slice_2807) : !memref_smem_bf16_15
            %shape_2832 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2833 = cute.make_layout(%shape_2832) : !cute.layout<"1:0">
            %append_2834 = cute.append_to_rank<2> (%lay_2831, %lay_2833) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2835 = cute.make_view(%iter_2809, %append_2834) : !memref_smem_bf16_15
            %iter_2836 = cute.get_iter(%view_2835) : !memref_smem_bf16_15
            %lay_2837 = cute.get_layout(%view_2835) : !memref_smem_bf16_15
            %1127 = cute.get_shape(%lay_2837) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2838, %e1_2839, %e2_2840 = cute.get_leaves(%1127) : !cute.shape<"((8,1),1)">
            %grouped_2841 = cute.group_modes(%view_2835) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2842 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %iter_2843 = cute.get_iter(%grouped_2841) : !memref_smem_bf16_16
            %lay_2844 = cute.get_layout(%grouped_2828) : !memref_gmem_bf16_12
            %1128 = cute.get_shape(%lay_2844) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2845, %e1_2846, %e2_2847 = cute.get_leaves(%1128) : !cute.shape<"((8,1),(1))">
            %lay_2848 = cute.get_layout(%grouped_2841) : !memref_smem_bf16_16
            %1129 = cute.get_shape(%lay_2848) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2849, %e1_2850, %e2_2851 = cute.get_leaves(%1129) : !cute.shape<"((8,1),(1))">
            %sz_2852 = cute.size(%grouped_2828) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2853 = cute.get_leaves(%sz_2852) : !cute.int_tuple<"1">
            %sz_2854 = cute.size(%grouped_2841) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2855 = cute.get_leaves(%sz_2854) : !cute.int_tuple<"1">
            cute.copy(%4, %grouped_2828, %grouped_2841) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2800 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2801 = cute.slice(%dst_partitioned_309, %coord_2800) : !memref_smem_bf16_4, !cute.coord<"(_,3,_)">
            %iter_2802 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %iter_2803 = cute.get_iter(%slice_2801) : !memref_smem_bf16_15
            %sz_2804 = cute.size(%slice_2801) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2805 = cute.get_leaves(%sz_2804) : !cute.int_tuple<"8">
            %lay_2806 = cute.get_layout(%slice_2801) : !memref_smem_bf16_15
            %1123 = cute.get_shape(%lay_2806) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2807, %e1_2808, %e2_2809 = cute.get_leaves(%1123) : !cute.shape<"((8,1),1)">
            %int_tuple_2810 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2811 = cute.tuple.product(%int_tuple_2810) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2812 = cute.get_leaves(%res_2811) : !cute.int_tuple<"8">
            %cst_2813 = arith.constant 0.000000e+00 : bf16
            %1124 = vector.splat %cst_2813 : vector<8xbf16>
            %int_tuple_2814 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2815 = cute.size(%int_tuple_2814) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2816 = cute.get_leaves(%sz_2815) : !cute.int_tuple<"8">
            %int_tuple_2817 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2818 = cute.size(%int_tuple_2817) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2819 = cute.get_leaves(%sz_2818) : !cute.int_tuple<"8">
            cute.memref.store_vec %1124, %slice_2801 : !memref_smem_bf16_15
          }
          nvvm.cp.async.commit.group
        }
        %lay_2165 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
        %926 = cute.get_shape(%lay_2165) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2166, %e1_2167, %e2_2168, %e3_2169 = cute.get_leaves(%926) : !cute.shape<"((2,2),1,8)">
        %927 = cute.get_stride(%lay_2165) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2170, %e1_2171, %e2_2172, %e3_2173 = cute.get_leaves(%927) : !cute.stride<"((1,2),0,4)">
        %928 = scf.if %true -> (!memref_rmem_f32_1) {
          %iter_2599 = cute.get_iter(%rmem_1779) : !memref_rmem_f32_1
          %lay_2600 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
          %1041 = cute.get_shape(%lay_2600) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2601, %e1_2602, %e2_2603, %e3_2604 = cute.get_leaves(%1041) : !cute.shape<"((2,2),1,8)">
          %1042 = cute.memref.load_vec %rmem_1779 : !memref_rmem_f32_1
          %cst_2605 = arith.constant 5.000000e-01 : f32
          %1043 = vector.broadcast %cst_2605 : f32 to vector<32xf32>
          %1044 = arith.mulf %1042, %1043 : vector<32xf32>
          %int_tuple_2606 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2607 = cute.size(%int_tuple_2606) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2608 = cute.get_leaves(%sz_2607) : !cute.int_tuple<"32">
          %int_tuple_2609 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2610 = cute.size(%int_tuple_2609) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2611 = cute.get_leaves(%sz_2610) : !cute.int_tuple<"32">
          cute.memref.store_vec %1044, %rmem_1779 : !memref_rmem_f32_1
          %int_tuple_2612 = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,2)">
          %sz_2613 = cute.size(%int_tuple_2612) : (!cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"4">
          %e0_2614 = cute.get_leaves(%sz_2613) : !cute.int_tuple<"4">
          %int_tuple_2615 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2616 = cute.size(%int_tuple_2615) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2617 = cute.get_leaves(%sz_2616) : !cute.int_tuple<"1">
          %int_tuple_2618 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2619 = cute.size(%int_tuple_2618) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2620 = cute.get_leaves(%sz_2619) : !cute.int_tuple<"8">
          %coord_2621 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %1045 = cute.memref.load(%rmem_1779, %coord_2621) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
          %1046 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1045 : (f32) -> f32
          %coord_2622 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          cute.memref.store(%rmem_1779, %coord_2622, %1046) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
          %coord_2623 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %1047 = cute.memref.load(%rmem_1779, %coord_2623) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
          %1048 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1047 : (f32) -> f32
          %coord_2624 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          cute.memref.store(%rmem_1779, %coord_2624, %1048) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
          %coord_2625 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %1049 = cute.memref.load(%rmem_1779, %coord_2625) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
          %1050 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1049 : (f32) -> f32
          %coord_2626 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          cute.memref.store(%rmem_1779, %coord_2626, %1050) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
          %coord_2627 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %1051 = cute.memref.load(%rmem_1779, %coord_2627) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
          %1052 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1051 : (f32) -> f32
          %coord_2628 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          cute.memref.store(%rmem_1779, %coord_2628, %1052) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
          %coord_2629 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %1053 = cute.memref.load(%rmem_1779, %coord_2629) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
          %1054 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1053 : (f32) -> f32
          %coord_2630 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          cute.memref.store(%rmem_1779, %coord_2630, %1054) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
          %coord_2631 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %1055 = cute.memref.load(%rmem_1779, %coord_2631) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
          %1056 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1055 : (f32) -> f32
          %coord_2632 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          cute.memref.store(%rmem_1779, %coord_2632, %1056) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
          %coord_2633 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %1057 = cute.memref.load(%rmem_1779, %coord_2633) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
          %1058 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1057 : (f32) -> f32
          %coord_2634 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          cute.memref.store(%rmem_1779, %coord_2634, %1058) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
          %coord_2635 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %1059 = cute.memref.load(%rmem_1779, %coord_2635) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
          %1060 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1059 : (f32) -> f32
          %coord_2636 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          cute.memref.store(%rmem_1779, %coord_2636, %1060) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
          %int_tuple_2637 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2638 = cute.size(%int_tuple_2637) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2639 = cute.get_leaves(%sz_2638) : !cute.int_tuple<"1">
          %int_tuple_2640 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2641 = cute.size(%int_tuple_2640) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2642 = cute.get_leaves(%sz_2641) : !cute.int_tuple<"8">
          %coord_2643 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %1061 = cute.memref.load(%rmem_1779, %coord_2643) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
          %1062 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1061 : (f32) -> f32
          %coord_2644 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          cute.memref.store(%rmem_1779, %coord_2644, %1062) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
          %coord_2645 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %1063 = cute.memref.load(%rmem_1779, %coord_2645) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
          %1064 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1063 : (f32) -> f32
          %coord_2646 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          cute.memref.store(%rmem_1779, %coord_2646, %1064) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
          %coord_2647 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %1065 = cute.memref.load(%rmem_1779, %coord_2647) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
          %1066 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1065 : (f32) -> f32
          %coord_2648 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          cute.memref.store(%rmem_1779, %coord_2648, %1066) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
          %coord_2649 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %1067 = cute.memref.load(%rmem_1779, %coord_2649) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
          %1068 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1067 : (f32) -> f32
          %coord_2650 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          cute.memref.store(%rmem_1779, %coord_2650, %1068) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
          %coord_2651 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %1069 = cute.memref.load(%rmem_1779, %coord_2651) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
          %1070 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1069 : (f32) -> f32
          %coord_2652 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          cute.memref.store(%rmem_1779, %coord_2652, %1070) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
          %coord_2653 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %1071 = cute.memref.load(%rmem_1779, %coord_2653) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
          %1072 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1071 : (f32) -> f32
          %coord_2654 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          cute.memref.store(%rmem_1779, %coord_2654, %1072) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
          %coord_2655 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %1073 = cute.memref.load(%rmem_1779, %coord_2655) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
          %1074 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1073 : (f32) -> f32
          %coord_2656 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          cute.memref.store(%rmem_1779, %coord_2656, %1074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
          %coord_2657 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %1075 = cute.memref.load(%rmem_1779, %coord_2657) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
          %1076 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1075 : (f32) -> f32
          %coord_2658 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          cute.memref.store(%rmem_1779, %coord_2658, %1076) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
          %int_tuple_2659 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2660 = cute.size(%int_tuple_2659) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2661 = cute.get_leaves(%sz_2660) : !cute.int_tuple<"1">
          %int_tuple_2662 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2663 = cute.size(%int_tuple_2662) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2664 = cute.get_leaves(%sz_2663) : !cute.int_tuple<"8">
          %coord_2665 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %1077 = cute.memref.load(%rmem_1779, %coord_2665) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
          %1078 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1077 : (f32) -> f32
          %coord_2666 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          cute.memref.store(%rmem_1779, %coord_2666, %1078) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
          %coord_2667 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %1079 = cute.memref.load(%rmem_1779, %coord_2667) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
          %1080 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1079 : (f32) -> f32
          %coord_2668 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          cute.memref.store(%rmem_1779, %coord_2668, %1080) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
          %coord_2669 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %1081 = cute.memref.load(%rmem_1779, %coord_2669) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
          %1082 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1081 : (f32) -> f32
          %coord_2670 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          cute.memref.store(%rmem_1779, %coord_2670, %1082) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
          %coord_2671 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %1083 = cute.memref.load(%rmem_1779, %coord_2671) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
          %1084 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1083 : (f32) -> f32
          %coord_2672 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          cute.memref.store(%rmem_1779, %coord_2672, %1084) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
          %coord_2673 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %1085 = cute.memref.load(%rmem_1779, %coord_2673) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
          %1086 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1085 : (f32) -> f32
          %coord_2674 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          cute.memref.store(%rmem_1779, %coord_2674, %1086) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
          %coord_2675 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %1087 = cute.memref.load(%rmem_1779, %coord_2675) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
          %1088 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1087 : (f32) -> f32
          %coord_2676 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          cute.memref.store(%rmem_1779, %coord_2676, %1088) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
          %coord_2677 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %1089 = cute.memref.load(%rmem_1779, %coord_2677) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
          %1090 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1089 : (f32) -> f32
          %coord_2678 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          cute.memref.store(%rmem_1779, %coord_2678, %1090) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
          %coord_2679 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %1091 = cute.memref.load(%rmem_1779, %coord_2679) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
          %1092 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1091 : (f32) -> f32
          %coord_2680 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          cute.memref.store(%rmem_1779, %coord_2680, %1092) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
          %int_tuple_2681 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2682 = cute.size(%int_tuple_2681) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2683 = cute.get_leaves(%sz_2682) : !cute.int_tuple<"1">
          %int_tuple_2684 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2685 = cute.size(%int_tuple_2684) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2686 = cute.get_leaves(%sz_2685) : !cute.int_tuple<"8">
          %coord_2687 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %1093 = cute.memref.load(%rmem_1779, %coord_2687) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
          %1094 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1093 : (f32) -> f32
          %coord_2688 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          cute.memref.store(%rmem_1779, %coord_2688, %1094) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
          %coord_2689 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %1095 = cute.memref.load(%rmem_1779, %coord_2689) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
          %1096 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1095 : (f32) -> f32
          %coord_2690 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          cute.memref.store(%rmem_1779, %coord_2690, %1096) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
          %coord_2691 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %1097 = cute.memref.load(%rmem_1779, %coord_2691) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
          %1098 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1097 : (f32) -> f32
          %coord_2692 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          cute.memref.store(%rmem_1779, %coord_2692, %1098) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
          %coord_2693 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %1099 = cute.memref.load(%rmem_1779, %coord_2693) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
          %1100 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1099 : (f32) -> f32
          %coord_2694 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          cute.memref.store(%rmem_1779, %coord_2694, %1100) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
          %coord_2695 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %1101 = cute.memref.load(%rmem_1779, %coord_2695) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
          %1102 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1101 : (f32) -> f32
          %coord_2696 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          cute.memref.store(%rmem_1779, %coord_2696, %1102) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
          %coord_2697 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %1103 = cute.memref.load(%rmem_1779, %coord_2697) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
          %1104 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1103 : (f32) -> f32
          %coord_2698 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          cute.memref.store(%rmem_1779, %coord_2698, %1104) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
          %coord_2699 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %1105 = cute.memref.load(%rmem_1779, %coord_2699) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
          %1106 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1105 : (f32) -> f32
          %coord_2700 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          cute.memref.store(%rmem_1779, %coord_2700, %1106) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
          %coord_2701 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %1107 = cute.memref.load(%rmem_1779, %coord_2701) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
          %1108 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1107 : (f32) -> f32
          %coord_2702 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          cute.memref.store(%rmem_1779, %coord_2702, %1108) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
          %1109 = cute.memref.load_vec %rmem_1779 : !memref_rmem_f32_1
          %1110 = arith.mulf %1044, %1109 : vector<32xf32>
          %1111 = arith.addf %1110, %1044 : vector<32xf32>
          %int_tuple_2703 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2704 = cute.size(%int_tuple_2703) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2705 = cute.get_leaves(%sz_2704) : !cute.int_tuple<"32">
          %int_tuple_2706 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2707 = cute.size(%int_tuple_2706) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2708 = cute.get_leaves(%sz_2707) : !cute.int_tuple<"32">
          cute.memref.store_vec %1111, %rmem_1779 : !memref_rmem_f32_1
          %lay_2709 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
          %1112 = cute.get_shape(%lay_2709) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2710, %e1_2711, %e2_2712, %e3_2713 = cute.get_leaves(%1112) : !cute.shape<"((2,2),1,8)">
          %1113 = cute.get_stride(%lay_2709) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2714, %e1_2715, %e2_2716, %e3_2717 = cute.get_leaves(%1113) : !cute.stride<"((1,2),0,4)">
          scf.yield %rmem_1779 : !memref_rmem_f32_1
        } else {
          %iter_2599 = cute.get_iter(%rmem_1779) : !memref_rmem_f32_1
          %lay_2600 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
          %1041 = cute.get_shape(%lay_2600) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2601, %e1_2602, %e2_2603, %e3_2604 = cute.get_leaves(%1041) : !cute.shape<"((2,2),1,8)">
          %1042 = cute.memref.load_vec %rmem_1779 : !memref_rmem_f32_1
          %cst_2605 = arith.constant -1.44269502 : f32
          %1043 = vector.broadcast %cst_2605 : f32 to vector<32xf32>
          %1044 = arith.mulf %1042, %1043 : vector<32xf32>
          %1045 = math.exp2 %1044 fastmath<fast> : vector<32xf32>
          %cst_2606 = arith.constant 1.000000e+00 : f32
          %1046 = vector.broadcast %cst_2606 : f32 to vector<32xf32>
          %1047 = arith.addf %1045, %1046 : vector<32xf32>
          %1048 = arith.divf %1042, %1047 : vector<32xf32>
          %int_tuple_2607 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2608 = cute.size(%int_tuple_2607) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2609 = cute.get_leaves(%sz_2608) : !cute.int_tuple<"32">
          %int_tuple_2610 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2611 = cute.size(%int_tuple_2610) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2612 = cute.get_leaves(%sz_2611) : !cute.int_tuple<"32">
          cute.memref.store_vec %1048, %rmem_1779 : !memref_rmem_f32_1
          %lay_2613 = cute.get_layout(%rmem_1779) : !memref_rmem_f32_1
          %1049 = cute.get_shape(%lay_2613) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1049) : !cute.shape<"((2,2),1,8)">
          %1050 = cute.get_stride(%lay_2613) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2618, %e1_2619, %e2_2620, %e3_2621 = cute.get_leaves(%1050) : !cute.stride<"((1,2),0,4)">
          scf.yield %rmem_1779 : !memref_rmem_f32_1
        }
        %iter_2174 = cute.get_iter(%928) : !memref_rmem_f32_1
        %lay_2175 = cute.get_layout(%928) : !memref_rmem_f32_1
        %929 = cute.get_shape(%lay_2175) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2176, %e1_2177, %e2_2178, %e3_2179 = cute.get_leaves(%929) : !cute.shape<"((2,2),1,8)">
        %930 = cute.get_stride(%lay_2175) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2180, %e1_2181, %e2_2182, %e3_2183 = cute.get_leaves(%930) : !cute.stride<"((1,2),0,4)">
        %iter_2184 = cute.get_iter(%928) : !memref_rmem_f32_1
        %iter_2185 = cute.get_iter(%928) : !memref_rmem_f32_1
        %lay_2186 = cute.get_layout(%arg4) : !memref_gmem_bf16_
        %931 = cute.get_shape(%lay_2186) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2187, %e1_2188, %e2_2189, %e3_2190 = cute.get_leaves(%931) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2191 = cute.to_int_tuple(%e0_2187) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %932 = cute.get_scalars(%itup_2191) : !cute.int_tuple<"?">
        %itup_2192 = cute.to_int_tuple(%e1_2188) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %933 = cute.get_scalars(%itup_2192) : !cute.int_tuple<"?">
        %itup_2193 = cute.to_int_tuple(%e2_2189) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %934 = cute.get_scalars(%itup_2193) : !cute.int_tuple<"?">
        %itup_2194 = cute.to_int_tuple(%e3_2190) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
        %935 = cute.get_scalars(%itup_2194) : !cute.int_tuple<"?{div=8}">
        %lay_2195 = cute.get_layout(%arg4) : !memref_gmem_bf16_
        %936 = cute.get_shape(%lay_2195) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2196, %e1_2197, %e2_2198, %e3_2199 = cute.get_leaves(%936) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2200 = cute.to_int_tuple(%e0_2196) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %937 = cute.get_scalars(%itup_2200) : !cute.int_tuple<"?">
        %itup_2201 = cute.to_int_tuple(%e1_2197) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %938 = cute.get_scalars(%itup_2201) : !cute.int_tuple<"?">
        %itup_2202 = cute.to_int_tuple(%e2_2198) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %939 = cute.get_scalars(%itup_2202) : !cute.int_tuple<"?">
        %itup_2203 = cute.to_int_tuple(%e3_2199) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
        %940 = cute.get_scalars(%itup_2203) : !cute.int_tuple<"?{div=8}">
        %shape_2204 = cute.make_shape(%itup_2193, %itup_2203) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?{div=8})">
        %941 = cute.make_identity_tensor(%shape_2204) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %iter_2205 = cute.get_iter(%941) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %e0_2206, %e1_2207 = cute.get_leaves(%iter_2205) : !cute.int_tuple<"(0,0)">
        %coord_2208 = cute.make_coord() : () -> !cute.coord<"(_,_)">
        %slice_2209 = cute.slice(%941, %coord_2208) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">, !cute.coord<"(_,_)">
        %iter_2210 = cute.get_iter(%slice_2209) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %e0_2211, %e1_2212 = cute.get_leaves(%iter_2210) : !cute.int_tuple<"(0,0)">
        %iter_2213 = cute.get_iter(%slice_2209) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %e0_2214, %e1_2215 = cute.get_leaves(%iter_2213) : !cute.int_tuple<"(0,0)">
        %tile_2216 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
        %coord_2217 = cute.make_coord(%sub_222, %sub_1769) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %tiled_view_2218 = cute.local_tile(%slice_2209, %tile_2216, %coord_2217) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,?)">) -> !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">
        %iter_2219 = cute.get_iter(%tiled_view_2218) : !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">
        %e0_2220, %e1_2221 = cute.get_leaves(%iter_2219) : !cute.int_tuple<"(?{div=64},?{div=64})">
        %942 = cute.get_scalars(%e0_2220) : !cute.int_tuple<"?{div=64}">
        %943 = cute.get_scalars(%e1_2221) : !cute.int_tuple<"?{div=64}">
        %lay_2222 = cute.get_layout(%928) : !memref_rmem_f32_1
        %944 = cute.get_shape(%lay_2222) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2223, %e1_2224, %e2_2225, %e3_2226 = cute.get_leaves(%944) : !cute.shape<"((2,2),1,8)">
        %945 = cute.get_stride(%lay_2222) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2227, %e1_2228, %e2_2229, %e3_2230 = cute.get_leaves(%945) : !cute.stride<"((1,2),0,4)">
        %946 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
        %947 = cute.get_shape(%946) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
        %e0_2231, %e1_2232, %e2_2233, %e3_2234 = cute.get_leaves(%947) : !cute.shape<"(32,4,1,1)">
        %948 = cute.get_stride(%946) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
        %e0_2235, %e1_2236, %e2_2237, %e3_2238 = cute.get_leaves(%948) : !cute.stride<"(1,32,0,0)">
        %949 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
        %e0_2239, %e1_2240, %e2_2241 = cute.get_leaves(%949) : !cute.tile<"[64:1;16:1;16:1]">
        %950 = cute.get_shape(%e0_2239) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2242 = cute.get_leaves(%950) : !cute.shape<"64">
        %951 = cute.get_stride(%e0_2239) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2243 = cute.get_leaves(%951) : !cute.stride<"1">
        %952 = cute.get_shape(%e1_2240) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2244 = cute.get_leaves(%952) : !cute.shape<"16">
        %953 = cute.get_stride(%e1_2240) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2245 = cute.get_leaves(%953) : !cute.stride<"1">
        %954 = cute.get_shape(%e2_2241) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2246 = cute.get_leaves(%954) : !cute.shape<"16">
        %955 = cute.get_stride(%e2_2241) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2247 = cute.get_leaves(%955) : !cute.stride<"1">
        %956 = cute.static : !cute.layout<"32:1">
        %957 = cute.get_shape(%956) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2248 = cute.get_leaves(%957) : !cute.shape<"32">
        %958 = cute.get_stride(%956) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2249 = cute.get_leaves(%958) : !cute.stride<"1">
        %959 = cute.static : !cute.shape<"(16,8,16)">
        %e0_2250, %e1_2251, %e2_2252 = cute.get_leaves(%959) : !cute.shape<"(16,8,16)">
        %960 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
        %961 = cute.get_shape(%960) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
        %e0_2253, %e1_2254, %e2_2255, %e3_2256, %e4_2257 = cute.get_leaves(%961) : !cute.shape<"((4,8),(2,2,2))">
        %962 = cute.get_stride(%960) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
        %e0_2258, %e1_2259, %e2_2260, %e3_2261, %e4_2262 = cute.get_leaves(%962) : !cute.stride<"((32,1),(16,8,128))">
        %963 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
        %964 = cute.get_shape(%963) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2263, %e1_2264, %e2_2265, %e3_2266 = cute.get_leaves(%964) : !cute.shape<"((4,8),(2,2))">
        %965 = cute.get_stride(%963) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
        %e0_2267, %e1_2268, %e2_2269, %e3_2270 = cute.get_leaves(%965) : !cute.stride<"((16,1),(8,64))">
        %966 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
        %967 = cute.get_shape(%966) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2271, %e1_2272, %e2_2273, %e3_2274 = cute.get_leaves(%967) : !cute.shape<"((4,8),(2,2))">
        %968 = cute.get_stride(%966) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
        %e0_2275, %e1_2276, %e2_2277, %e3_2278 = cute.get_leaves(%968) : !cute.stride<"((32,1),(16,8))">
        %969:2 = scf.if %false -> (!memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_) {
          %iter_2599 = cute.get_iter(%928) : !memref_rmem_f32_1
          %coord_2600 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
          %ptn_C = cute.tiled.mma.partition C (%arg6, %tiled_view_2218, %coord_2600) : (!mma_bf16_bf16_f32_16x8x16_, !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %iter_2601 = cute.get_iter(%ptn_C) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %e0_2602, %e1_2603 = cute.get_leaves(%iter_2601) : !cute.int_tuple<"(?,?{div=2})">
          %1041 = cute.get_scalars(%e0_2602) : !cute.int_tuple<"?">
          %1042 = cute.get_scalars(%e1_2603) : !cute.int_tuple<"?{div=2}">
          %lay_2604 = cute.get_layout(%ptn_C) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %1043 = cute.get_shape(%lay_2604) : (!cute.layout<"((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2605, %e1_2606, %e2_2607, %e3_2608 = cute.get_leaves(%1043) : !cute.shape<"((2,2),1,8)">
          %int_tuple_2609 = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,2)">
          %sz_2610 = cute.size(%int_tuple_2609) : (!cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"4">
          %e0_2611 = cute.get_leaves(%sz_2610) : !cute.int_tuple<"4">
          %int_tuple_2612 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2613 = cute.size(%int_tuple_2612) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2614 = cute.get_leaves(%sz_2613) : !cute.int_tuple<"1">
          %int_tuple_2615 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2616 = cute.size(%int_tuple_2615) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2617 = cute.get_leaves(%sz_2616) : !cute.int_tuple<"8">
          %coord_2618 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2619 = cute.slice(%ptn_C, %coord_2618) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,0)">
          %iter_2620 = cute.get_iter(%slice_2619) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2621, %e1_2622 = cute.get_leaves(%iter_2620) : !cute.int_tuple<"(?,?{div=2})">
          %1044 = cute.get_scalars(%e0_2621) : !cute.int_tuple<"?">
          %1045 = cute.get_scalars(%e1_2622) : !cute.int_tuple<"?{div=2}">
          %iter_2623 = cute.get_iter(%slice_2619) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2624, %e1_2625 = cute.get_leaves(%iter_2623) : !cute.int_tuple<"(?,?{div=2})">
          %1046 = cute.get_scalars(%e0_2624) : !cute.int_tuple<"?">
          %1047 = cute.get_scalars(%e1_2625) : !cute.int_tuple<"?{div=2}">
          %iter_2626 = cute.get_iter(%slice_2619) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2627, %e1_2628 = cute.get_leaves(%iter_2626) : !cute.int_tuple<"(?,?{div=2})">
          %1048 = cute.get_scalars(%e0_2627) : !cute.int_tuple<"?">
          %1049 = cute.get_scalars(%e1_2628) : !cute.int_tuple<"?{div=2}">
          %coord_2629 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2630 = cute.slice(%ptn_C, %coord_2629) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,0)">
          %iter_2631 = cute.get_iter(%slice_2630) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2632, %e1_2633 = cute.get_leaves(%iter_2631) : !cute.int_tuple<"(?,?{div=2})">
          %1050 = cute.get_scalars(%e0_2632) : !cute.int_tuple<"?">
          %1051 = cute.get_scalars(%e1_2633) : !cute.int_tuple<"?{div=2}">
          %iter_2634 = cute.get_iter(%slice_2630) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2635, %e1_2636 = cute.get_leaves(%iter_2634) : !cute.int_tuple<"(?,?{div=2})">
          %1052 = cute.get_scalars(%e0_2635) : !cute.int_tuple<"?">
          %1053 = cute.get_scalars(%e1_2636) : !cute.int_tuple<"?{div=2}">
          %iter_2637 = cute.get_iter(%slice_2630) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2638, %e1_2639 = cute.get_leaves(%iter_2637) : !cute.int_tuple<"(?,?{div=2})">
          %1054 = cute.get_scalars(%e0_2638) : !cute.int_tuple<"?">
          %1055 = cute.get_scalars(%e1_2639) : !cute.int_tuple<"?{div=2}">
          %coord_2640 = cute.make_coord(%e0_2627) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2641 = cute.make_coord(%e1_2639) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1056 = cute.elem_less(%coord_2640, %coord_2641) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2642 = cute.get_layout(%928) : !memref_rmem_f32_1
          %1057 = cute.get_shape(%lay_2642) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2643, %e1_2644, %e2_2645, %e3_2646 = cute.get_leaves(%1057) : !cute.shape<"((2,2),1,8)">
          %1058 = cute.get_stride(%lay_2642) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2647, %e1_2648, %e2_2649, %e3_2650 = cute.get_leaves(%1058) : !cute.stride<"((1,2),0,4)">
          %1059 = scf.if %1056 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%928) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
            cute.memref.store(%928, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
            %lay_4136 = cute.get_layout(%928) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %928 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%928) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%928) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %928 : !memref_rmem_f32_1
          }
          %iter_2651 = cute.get_iter(%1059) : !memref_rmem_f32_1
          %lay_2652 = cute.get_layout(%1059) : !memref_rmem_f32_1
          %1060 = cute.get_shape(%lay_2652) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2653, %e1_2654, %e2_2655, %e3_2656 = cute.get_leaves(%1060) : !cute.shape<"((2,2),1,8)">
          %1061 = cute.get_stride(%lay_2652) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2657, %e1_2658, %e2_2659, %e3_2660 = cute.get_leaves(%1061) : !cute.stride<"((1,2),0,4)">
          %iter_2661 = cute.get_iter(%1059) : !memref_rmem_f32_1
          %iter_2662 = cute.get_iter(%1059) : !memref_rmem_f32_1
          %coord_2663 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %slice_2664 = cute.slice(%ptn_C, %coord_2663) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,1)">
          %iter_2665 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2666, %e1_2667 = cute.get_leaves(%iter_2665) : !cute.int_tuple<"(?,?{div=2})">
          %1062 = cute.get_scalars(%e0_2666) : !cute.int_tuple<"?">
          %1063 = cute.get_scalars(%e1_2667) : !cute.int_tuple<"?{div=2}">
          %iter_2668 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2669, %e1_2670 = cute.get_leaves(%iter_2668) : !cute.int_tuple<"(?,?{div=2})">
          %1064 = cute.get_scalars(%e0_2669) : !cute.int_tuple<"?">
          %1065 = cute.get_scalars(%e1_2670) : !cute.int_tuple<"?{div=2}">
          %iter_2671 = cute.get_iter(%slice_2664) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2672, %e1_2673 = cute.get_leaves(%iter_2671) : !cute.int_tuple<"(?,?{div=2})">
          %1066 = cute.get_scalars(%e0_2672) : !cute.int_tuple<"?">
          %1067 = cute.get_scalars(%e1_2673) : !cute.int_tuple<"?{div=2}">
          %coord_2674 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %slice_2675 = cute.slice(%ptn_C, %coord_2674) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,1)">
          %iter_2676 = cute.get_iter(%slice_2675) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2677, %e1_2678 = cute.get_leaves(%iter_2676) : !cute.int_tuple<"(?,?{div=2})">
          %1068 = cute.get_scalars(%e0_2677) : !cute.int_tuple<"?">
          %1069 = cute.get_scalars(%e1_2678) : !cute.int_tuple<"?{div=2}">
          %iter_2679 = cute.get_iter(%slice_2675) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2680, %e1_2681 = cute.get_leaves(%iter_2679) : !cute.int_tuple<"(?,?{div=2})">
          %1070 = cute.get_scalars(%e0_2680) : !cute.int_tuple<"?">
          %1071 = cute.get_scalars(%e1_2681) : !cute.int_tuple<"?{div=2}">
          %iter_2682 = cute.get_iter(%slice_2675) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2683, %e1_2684 = cute.get_leaves(%iter_2682) : !cute.int_tuple<"(?,?{div=2})">
          %1072 = cute.get_scalars(%e0_2683) : !cute.int_tuple<"?">
          %1073 = cute.get_scalars(%e1_2684) : !cute.int_tuple<"?{div=2}">
          %coord_2685 = cute.make_coord(%e0_2672) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2686 = cute.make_coord(%e1_2684) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1074 = cute.elem_less(%coord_2685, %coord_2686) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2687 = cute.get_layout(%1059) : !memref_rmem_f32_1
          %1075 = cute.get_shape(%lay_2687) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2688, %e1_2689, %e2_2690, %e3_2691 = cute.get_leaves(%1075) : !cute.shape<"((2,2),1,8)">
          %1076 = cute.get_stride(%lay_2687) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2692, %e1_2693, %e2_2694, %e3_2695 = cute.get_leaves(%1076) : !cute.stride<"((1,2),0,4)">
          %1077 = scf.if %1074 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1059) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
            cute.memref.store(%1059, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1059) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1059 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1059) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1059) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1059 : !memref_rmem_f32_1
          }
          %iter_2696 = cute.get_iter(%1077) : !memref_rmem_f32_1
          %lay_2697 = cute.get_layout(%1077) : !memref_rmem_f32_1
          %1078 = cute.get_shape(%lay_2697) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2698, %e1_2699, %e2_2700, %e3_2701 = cute.get_leaves(%1078) : !cute.shape<"((2,2),1,8)">
          %1079 = cute.get_stride(%lay_2697) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2702, %e1_2703, %e2_2704, %e3_2705 = cute.get_leaves(%1079) : !cute.stride<"((1,2),0,4)">
          %iter_2706 = cute.get_iter(%1077) : !memref_rmem_f32_1
          %iter_2707 = cute.get_iter(%1077) : !memref_rmem_f32_1
          %coord_2708 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %slice_2709 = cute.slice(%ptn_C, %coord_2708) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,2)">
          %iter_2710 = cute.get_iter(%slice_2709) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2711, %e1_2712 = cute.get_leaves(%iter_2710) : !cute.int_tuple<"(?,?{div=2})">
          %1080 = cute.get_scalars(%e0_2711) : !cute.int_tuple<"?">
          %1081 = cute.get_scalars(%e1_2712) : !cute.int_tuple<"?{div=2}">
          %iter_2713 = cute.get_iter(%slice_2709) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2714, %e1_2715 = cute.get_leaves(%iter_2713) : !cute.int_tuple<"(?,?{div=2})">
          %1082 = cute.get_scalars(%e0_2714) : !cute.int_tuple<"?">
          %1083 = cute.get_scalars(%e1_2715) : !cute.int_tuple<"?{div=2}">
          %iter_2716 = cute.get_iter(%slice_2709) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2717, %e1_2718 = cute.get_leaves(%iter_2716) : !cute.int_tuple<"(?,?{div=2})">
          %1084 = cute.get_scalars(%e0_2717) : !cute.int_tuple<"?">
          %1085 = cute.get_scalars(%e1_2718) : !cute.int_tuple<"?{div=2}">
          %coord_2719 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %slice_2720 = cute.slice(%ptn_C, %coord_2719) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,2)">
          %iter_2721 = cute.get_iter(%slice_2720) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2722, %e1_2723 = cute.get_leaves(%iter_2721) : !cute.int_tuple<"(?,?{div=2})">
          %1086 = cute.get_scalars(%e0_2722) : !cute.int_tuple<"?">
          %1087 = cute.get_scalars(%e1_2723) : !cute.int_tuple<"?{div=2}">
          %iter_2724 = cute.get_iter(%slice_2720) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2725, %e1_2726 = cute.get_leaves(%iter_2724) : !cute.int_tuple<"(?,?{div=2})">
          %1088 = cute.get_scalars(%e0_2725) : !cute.int_tuple<"?">
          %1089 = cute.get_scalars(%e1_2726) : !cute.int_tuple<"?{div=2}">
          %iter_2727 = cute.get_iter(%slice_2720) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2728, %e1_2729 = cute.get_leaves(%iter_2727) : !cute.int_tuple<"(?,?{div=2})">
          %1090 = cute.get_scalars(%e0_2728) : !cute.int_tuple<"?">
          %1091 = cute.get_scalars(%e1_2729) : !cute.int_tuple<"?{div=2}">
          %coord_2730 = cute.make_coord(%e0_2717) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2731 = cute.make_coord(%e1_2729) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1092 = cute.elem_less(%coord_2730, %coord_2731) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2732 = cute.get_layout(%1077) : !memref_rmem_f32_1
          %1093 = cute.get_shape(%lay_2732) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2733, %e1_2734, %e2_2735, %e3_2736 = cute.get_leaves(%1093) : !cute.shape<"((2,2),1,8)">
          %1094 = cute.get_stride(%lay_2732) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2737, %e1_2738, %e2_2739, %e3_2740 = cute.get_leaves(%1094) : !cute.stride<"((1,2),0,4)">
          %1095 = scf.if %1092 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1077) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
            cute.memref.store(%1077, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1077) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1077 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1077) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1077) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1077 : !memref_rmem_f32_1
          }
          %iter_2741 = cute.get_iter(%1095) : !memref_rmem_f32_1
          %lay_2742 = cute.get_layout(%1095) : !memref_rmem_f32_1
          %1096 = cute.get_shape(%lay_2742) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2743, %e1_2744, %e2_2745, %e3_2746 = cute.get_leaves(%1096) : !cute.shape<"((2,2),1,8)">
          %1097 = cute.get_stride(%lay_2742) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2747, %e1_2748, %e2_2749, %e3_2750 = cute.get_leaves(%1097) : !cute.stride<"((1,2),0,4)">
          %iter_2751 = cute.get_iter(%1095) : !memref_rmem_f32_1
          %iter_2752 = cute.get_iter(%1095) : !memref_rmem_f32_1
          %coord_2753 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %slice_2754 = cute.slice(%ptn_C, %coord_2753) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,3)">
          %iter_2755 = cute.get_iter(%slice_2754) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2756, %e1_2757 = cute.get_leaves(%iter_2755) : !cute.int_tuple<"(?,?{div=2})">
          %1098 = cute.get_scalars(%e0_2756) : !cute.int_tuple<"?">
          %1099 = cute.get_scalars(%e1_2757) : !cute.int_tuple<"?{div=2}">
          %iter_2758 = cute.get_iter(%slice_2754) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2759, %e1_2760 = cute.get_leaves(%iter_2758) : !cute.int_tuple<"(?,?{div=2})">
          %1100 = cute.get_scalars(%e0_2759) : !cute.int_tuple<"?">
          %1101 = cute.get_scalars(%e1_2760) : !cute.int_tuple<"?{div=2}">
          %iter_2761 = cute.get_iter(%slice_2754) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2762, %e1_2763 = cute.get_leaves(%iter_2761) : !cute.int_tuple<"(?,?{div=2})">
          %1102 = cute.get_scalars(%e0_2762) : !cute.int_tuple<"?">
          %1103 = cute.get_scalars(%e1_2763) : !cute.int_tuple<"?{div=2}">
          %coord_2764 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %slice_2765 = cute.slice(%ptn_C, %coord_2764) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,3)">
          %iter_2766 = cute.get_iter(%slice_2765) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2767, %e1_2768 = cute.get_leaves(%iter_2766) : !cute.int_tuple<"(?,?{div=2})">
          %1104 = cute.get_scalars(%e0_2767) : !cute.int_tuple<"?">
          %1105 = cute.get_scalars(%e1_2768) : !cute.int_tuple<"?{div=2}">
          %iter_2769 = cute.get_iter(%slice_2765) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2770, %e1_2771 = cute.get_leaves(%iter_2769) : !cute.int_tuple<"(?,?{div=2})">
          %1106 = cute.get_scalars(%e0_2770) : !cute.int_tuple<"?">
          %1107 = cute.get_scalars(%e1_2771) : !cute.int_tuple<"?{div=2}">
          %iter_2772 = cute.get_iter(%slice_2765) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2773, %e1_2774 = cute.get_leaves(%iter_2772) : !cute.int_tuple<"(?,?{div=2})">
          %1108 = cute.get_scalars(%e0_2773) : !cute.int_tuple<"?">
          %1109 = cute.get_scalars(%e1_2774) : !cute.int_tuple<"?{div=2}">
          %coord_2775 = cute.make_coord(%e0_2762) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2776 = cute.make_coord(%e1_2774) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1110 = cute.elem_less(%coord_2775, %coord_2776) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2777 = cute.get_layout(%1095) : !memref_rmem_f32_1
          %1111 = cute.get_shape(%lay_2777) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2778, %e1_2779, %e2_2780, %e3_2781 = cute.get_leaves(%1111) : !cute.shape<"((2,2),1,8)">
          %1112 = cute.get_stride(%lay_2777) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2782, %e1_2783, %e2_2784, %e3_2785 = cute.get_leaves(%1112) : !cute.stride<"((1,2),0,4)">
          %1113 = scf.if %1110 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1095) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
            cute.memref.store(%1095, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1095) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1095 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1095) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1095) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1095 : !memref_rmem_f32_1
          }
          %iter_2786 = cute.get_iter(%1113) : !memref_rmem_f32_1
          %lay_2787 = cute.get_layout(%1113) : !memref_rmem_f32_1
          %1114 = cute.get_shape(%lay_2787) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2788, %e1_2789, %e2_2790, %e3_2791 = cute.get_leaves(%1114) : !cute.shape<"((2,2),1,8)">
          %1115 = cute.get_stride(%lay_2787) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2792, %e1_2793, %e2_2794, %e3_2795 = cute.get_leaves(%1115) : !cute.stride<"((1,2),0,4)">
          %iter_2796 = cute.get_iter(%1113) : !memref_rmem_f32_1
          %iter_2797 = cute.get_iter(%1113) : !memref_rmem_f32_1
          %coord_2798 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %slice_2799 = cute.slice(%ptn_C, %coord_2798) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,4)">
          %iter_2800 = cute.get_iter(%slice_2799) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2801, %e1_2802 = cute.get_leaves(%iter_2800) : !cute.int_tuple<"(?,?{div=2})">
          %1116 = cute.get_scalars(%e0_2801) : !cute.int_tuple<"?">
          %1117 = cute.get_scalars(%e1_2802) : !cute.int_tuple<"?{div=2}">
          %iter_2803 = cute.get_iter(%slice_2799) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2804, %e1_2805 = cute.get_leaves(%iter_2803) : !cute.int_tuple<"(?,?{div=2})">
          %1118 = cute.get_scalars(%e0_2804) : !cute.int_tuple<"?">
          %1119 = cute.get_scalars(%e1_2805) : !cute.int_tuple<"?{div=2}">
          %iter_2806 = cute.get_iter(%slice_2799) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2807, %e1_2808 = cute.get_leaves(%iter_2806) : !cute.int_tuple<"(?,?{div=2})">
          %1120 = cute.get_scalars(%e0_2807) : !cute.int_tuple<"?">
          %1121 = cute.get_scalars(%e1_2808) : !cute.int_tuple<"?{div=2}">
          %coord_2809 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %slice_2810 = cute.slice(%ptn_C, %coord_2809) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,4)">
          %iter_2811 = cute.get_iter(%slice_2810) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2812, %e1_2813 = cute.get_leaves(%iter_2811) : !cute.int_tuple<"(?,?{div=2})">
          %1122 = cute.get_scalars(%e0_2812) : !cute.int_tuple<"?">
          %1123 = cute.get_scalars(%e1_2813) : !cute.int_tuple<"?{div=2}">
          %iter_2814 = cute.get_iter(%slice_2810) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2815, %e1_2816 = cute.get_leaves(%iter_2814) : !cute.int_tuple<"(?,?{div=2})">
          %1124 = cute.get_scalars(%e0_2815) : !cute.int_tuple<"?">
          %1125 = cute.get_scalars(%e1_2816) : !cute.int_tuple<"?{div=2}">
          %iter_2817 = cute.get_iter(%slice_2810) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2818, %e1_2819 = cute.get_leaves(%iter_2817) : !cute.int_tuple<"(?,?{div=2})">
          %1126 = cute.get_scalars(%e0_2818) : !cute.int_tuple<"?">
          %1127 = cute.get_scalars(%e1_2819) : !cute.int_tuple<"?{div=2}">
          %coord_2820 = cute.make_coord(%e0_2807) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2821 = cute.make_coord(%e1_2819) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1128 = cute.elem_less(%coord_2820, %coord_2821) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2822 = cute.get_layout(%1113) : !memref_rmem_f32_1
          %1129 = cute.get_shape(%lay_2822) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2823, %e1_2824, %e2_2825, %e3_2826 = cute.get_leaves(%1129) : !cute.shape<"((2,2),1,8)">
          %1130 = cute.get_stride(%lay_2822) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2827, %e1_2828, %e2_2829, %e3_2830 = cute.get_leaves(%1130) : !cute.stride<"((1,2),0,4)">
          %1131 = scf.if %1128 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1113) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
            cute.memref.store(%1113, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1113) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1113 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1113) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1113) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1113 : !memref_rmem_f32_1
          }
          %iter_2831 = cute.get_iter(%1131) : !memref_rmem_f32_1
          %lay_2832 = cute.get_layout(%1131) : !memref_rmem_f32_1
          %1132 = cute.get_shape(%lay_2832) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2833, %e1_2834, %e2_2835, %e3_2836 = cute.get_leaves(%1132) : !cute.shape<"((2,2),1,8)">
          %1133 = cute.get_stride(%lay_2832) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2837, %e1_2838, %e2_2839, %e3_2840 = cute.get_leaves(%1133) : !cute.stride<"((1,2),0,4)">
          %iter_2841 = cute.get_iter(%1131) : !memref_rmem_f32_1
          %iter_2842 = cute.get_iter(%1131) : !memref_rmem_f32_1
          %coord_2843 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %slice_2844 = cute.slice(%ptn_C, %coord_2843) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,5)">
          %iter_2845 = cute.get_iter(%slice_2844) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2846, %e1_2847 = cute.get_leaves(%iter_2845) : !cute.int_tuple<"(?,?{div=2})">
          %1134 = cute.get_scalars(%e0_2846) : !cute.int_tuple<"?">
          %1135 = cute.get_scalars(%e1_2847) : !cute.int_tuple<"?{div=2}">
          %iter_2848 = cute.get_iter(%slice_2844) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2849, %e1_2850 = cute.get_leaves(%iter_2848) : !cute.int_tuple<"(?,?{div=2})">
          %1136 = cute.get_scalars(%e0_2849) : !cute.int_tuple<"?">
          %1137 = cute.get_scalars(%e1_2850) : !cute.int_tuple<"?{div=2}">
          %iter_2851 = cute.get_iter(%slice_2844) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2852, %e1_2853 = cute.get_leaves(%iter_2851) : !cute.int_tuple<"(?,?{div=2})">
          %1138 = cute.get_scalars(%e0_2852) : !cute.int_tuple<"?">
          %1139 = cute.get_scalars(%e1_2853) : !cute.int_tuple<"?{div=2}">
          %coord_2854 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %slice_2855 = cute.slice(%ptn_C, %coord_2854) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,5)">
          %iter_2856 = cute.get_iter(%slice_2855) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2857, %e1_2858 = cute.get_leaves(%iter_2856) : !cute.int_tuple<"(?,?{div=2})">
          %1140 = cute.get_scalars(%e0_2857) : !cute.int_tuple<"?">
          %1141 = cute.get_scalars(%e1_2858) : !cute.int_tuple<"?{div=2}">
          %iter_2859 = cute.get_iter(%slice_2855) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2860, %e1_2861 = cute.get_leaves(%iter_2859) : !cute.int_tuple<"(?,?{div=2})">
          %1142 = cute.get_scalars(%e0_2860) : !cute.int_tuple<"?">
          %1143 = cute.get_scalars(%e1_2861) : !cute.int_tuple<"?{div=2}">
          %iter_2862 = cute.get_iter(%slice_2855) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2863, %e1_2864 = cute.get_leaves(%iter_2862) : !cute.int_tuple<"(?,?{div=2})">
          %1144 = cute.get_scalars(%e0_2863) : !cute.int_tuple<"?">
          %1145 = cute.get_scalars(%e1_2864) : !cute.int_tuple<"?{div=2}">
          %coord_2865 = cute.make_coord(%e0_2852) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2866 = cute.make_coord(%e1_2864) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1146 = cute.elem_less(%coord_2865, %coord_2866) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2867 = cute.get_layout(%1131) : !memref_rmem_f32_1
          %1147 = cute.get_shape(%lay_2867) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2868, %e1_2869, %e2_2870, %e3_2871 = cute.get_leaves(%1147) : !cute.shape<"((2,2),1,8)">
          %1148 = cute.get_stride(%lay_2867) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2872, %e1_2873, %e2_2874, %e3_2875 = cute.get_leaves(%1148) : !cute.stride<"((1,2),0,4)">
          %1149 = scf.if %1146 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1131) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
            cute.memref.store(%1131, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1131) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1131 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1131) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1131) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1131 : !memref_rmem_f32_1
          }
          %iter_2876 = cute.get_iter(%1149) : !memref_rmem_f32_1
          %lay_2877 = cute.get_layout(%1149) : !memref_rmem_f32_1
          %1150 = cute.get_shape(%lay_2877) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2878, %e1_2879, %e2_2880, %e3_2881 = cute.get_leaves(%1150) : !cute.shape<"((2,2),1,8)">
          %1151 = cute.get_stride(%lay_2877) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2882, %e1_2883, %e2_2884, %e3_2885 = cute.get_leaves(%1151) : !cute.stride<"((1,2),0,4)">
          %iter_2886 = cute.get_iter(%1149) : !memref_rmem_f32_1
          %iter_2887 = cute.get_iter(%1149) : !memref_rmem_f32_1
          %coord_2888 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %slice_2889 = cute.slice(%ptn_C, %coord_2888) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,6)">
          %iter_2890 = cute.get_iter(%slice_2889) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2891, %e1_2892 = cute.get_leaves(%iter_2890) : !cute.int_tuple<"(?,?{div=2})">
          %1152 = cute.get_scalars(%e0_2891) : !cute.int_tuple<"?">
          %1153 = cute.get_scalars(%e1_2892) : !cute.int_tuple<"?{div=2}">
          %iter_2893 = cute.get_iter(%slice_2889) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2894, %e1_2895 = cute.get_leaves(%iter_2893) : !cute.int_tuple<"(?,?{div=2})">
          %1154 = cute.get_scalars(%e0_2894) : !cute.int_tuple<"?">
          %1155 = cute.get_scalars(%e1_2895) : !cute.int_tuple<"?{div=2}">
          %iter_2896 = cute.get_iter(%slice_2889) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2897, %e1_2898 = cute.get_leaves(%iter_2896) : !cute.int_tuple<"(?,?{div=2})">
          %1156 = cute.get_scalars(%e0_2897) : !cute.int_tuple<"?">
          %1157 = cute.get_scalars(%e1_2898) : !cute.int_tuple<"?{div=2}">
          %coord_2899 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %slice_2900 = cute.slice(%ptn_C, %coord_2899) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,6)">
          %iter_2901 = cute.get_iter(%slice_2900) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2902, %e1_2903 = cute.get_leaves(%iter_2901) : !cute.int_tuple<"(?,?{div=2})">
          %1158 = cute.get_scalars(%e0_2902) : !cute.int_tuple<"?">
          %1159 = cute.get_scalars(%e1_2903) : !cute.int_tuple<"?{div=2}">
          %iter_2904 = cute.get_iter(%slice_2900) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2905, %e1_2906 = cute.get_leaves(%iter_2904) : !cute.int_tuple<"(?,?{div=2})">
          %1160 = cute.get_scalars(%e0_2905) : !cute.int_tuple<"?">
          %1161 = cute.get_scalars(%e1_2906) : !cute.int_tuple<"?{div=2}">
          %iter_2907 = cute.get_iter(%slice_2900) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2908, %e1_2909 = cute.get_leaves(%iter_2907) : !cute.int_tuple<"(?,?{div=2})">
          %1162 = cute.get_scalars(%e0_2908) : !cute.int_tuple<"?">
          %1163 = cute.get_scalars(%e1_2909) : !cute.int_tuple<"?{div=2}">
          %coord_2910 = cute.make_coord(%e0_2897) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2911 = cute.make_coord(%e1_2909) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1164 = cute.elem_less(%coord_2910, %coord_2911) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2912 = cute.get_layout(%1149) : !memref_rmem_f32_1
          %1165 = cute.get_shape(%lay_2912) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2913, %e1_2914, %e2_2915, %e3_2916 = cute.get_leaves(%1165) : !cute.shape<"((2,2),1,8)">
          %1166 = cute.get_stride(%lay_2912) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2917, %e1_2918, %e2_2919, %e3_2920 = cute.get_leaves(%1166) : !cute.stride<"((1,2),0,4)">
          %1167 = scf.if %1164 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1149) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
            cute.memref.store(%1149, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1149) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1149 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1149) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1149) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1149 : !memref_rmem_f32_1
          }
          %iter_2921 = cute.get_iter(%1167) : !memref_rmem_f32_1
          %lay_2922 = cute.get_layout(%1167) : !memref_rmem_f32_1
          %1168 = cute.get_shape(%lay_2922) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2923, %e1_2924, %e2_2925, %e3_2926 = cute.get_leaves(%1168) : !cute.shape<"((2,2),1,8)">
          %1169 = cute.get_stride(%lay_2922) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2927, %e1_2928, %e2_2929, %e3_2930 = cute.get_leaves(%1169) : !cute.stride<"((1,2),0,4)">
          %iter_2931 = cute.get_iter(%1167) : !memref_rmem_f32_1
          %iter_2932 = cute.get_iter(%1167) : !memref_rmem_f32_1
          %coord_2933 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %slice_2934 = cute.slice(%ptn_C, %coord_2933) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,7)">
          %iter_2935 = cute.get_iter(%slice_2934) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2936, %e1_2937 = cute.get_leaves(%iter_2935) : !cute.int_tuple<"(?,?{div=2})">
          %1170 = cute.get_scalars(%e0_2936) : !cute.int_tuple<"?">
          %1171 = cute.get_scalars(%e1_2937) : !cute.int_tuple<"?{div=2}">
          %iter_2938 = cute.get_iter(%slice_2934) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2939, %e1_2940 = cute.get_leaves(%iter_2938) : !cute.int_tuple<"(?,?{div=2})">
          %1172 = cute.get_scalars(%e0_2939) : !cute.int_tuple<"?">
          %1173 = cute.get_scalars(%e1_2940) : !cute.int_tuple<"?{div=2}">
          %iter_2941 = cute.get_iter(%slice_2934) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2942, %e1_2943 = cute.get_leaves(%iter_2941) : !cute.int_tuple<"(?,?{div=2})">
          %1174 = cute.get_scalars(%e0_2942) : !cute.int_tuple<"?">
          %1175 = cute.get_scalars(%e1_2943) : !cute.int_tuple<"?{div=2}">
          %coord_2944 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %slice_2945 = cute.slice(%ptn_C, %coord_2944) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,7)">
          %iter_2946 = cute.get_iter(%slice_2945) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2947, %e1_2948 = cute.get_leaves(%iter_2946) : !cute.int_tuple<"(?,?{div=2})">
          %1176 = cute.get_scalars(%e0_2947) : !cute.int_tuple<"?">
          %1177 = cute.get_scalars(%e1_2948) : !cute.int_tuple<"?{div=2}">
          %iter_2949 = cute.get_iter(%slice_2945) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2950, %e1_2951 = cute.get_leaves(%iter_2949) : !cute.int_tuple<"(?,?{div=2})">
          %1178 = cute.get_scalars(%e0_2950) : !cute.int_tuple<"?">
          %1179 = cute.get_scalars(%e1_2951) : !cute.int_tuple<"?{div=2}">
          %iter_2952 = cute.get_iter(%slice_2945) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2953, %e1_2954 = cute.get_leaves(%iter_2952) : !cute.int_tuple<"(?,?{div=2})">
          %1180 = cute.get_scalars(%e0_2953) : !cute.int_tuple<"?">
          %1181 = cute.get_scalars(%e1_2954) : !cute.int_tuple<"?{div=2}">
          %coord_2955 = cute.make_coord(%e0_2942) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2956 = cute.make_coord(%e1_2954) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1182 = cute.elem_less(%coord_2955, %coord_2956) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2957 = cute.get_layout(%1167) : !memref_rmem_f32_1
          %1183 = cute.get_shape(%lay_2957) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2958, %e1_2959, %e2_2960, %e3_2961 = cute.get_leaves(%1183) : !cute.shape<"((2,2),1,8)">
          %1184 = cute.get_stride(%lay_2957) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2962, %e1_2963, %e2_2964, %e3_2965 = cute.get_leaves(%1184) : !cute.stride<"((1,2),0,4)">
          %1185 = scf.if %1182 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1167) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
            cute.memref.store(%1167, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1167) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1167 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1167) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1167) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1167 : !memref_rmem_f32_1
          }
          %iter_2966 = cute.get_iter(%1185) : !memref_rmem_f32_1
          %lay_2967 = cute.get_layout(%1185) : !memref_rmem_f32_1
          %1186 = cute.get_shape(%lay_2967) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2968, %e1_2969, %e2_2970, %e3_2971 = cute.get_leaves(%1186) : !cute.shape<"((2,2),1,8)">
          %1187 = cute.get_stride(%lay_2967) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2972, %e1_2973, %e2_2974, %e3_2975 = cute.get_leaves(%1187) : !cute.stride<"((1,2),0,4)">
          %iter_2976 = cute.get_iter(%1185) : !memref_rmem_f32_1
          %iter_2977 = cute.get_iter(%1185) : !memref_rmem_f32_1
          %int_tuple_2978 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2979 = cute.size(%int_tuple_2978) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2980 = cute.get_leaves(%sz_2979) : !cute.int_tuple<"1">
          %int_tuple_2981 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2982 = cute.size(%int_tuple_2981) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2983 = cute.get_leaves(%sz_2982) : !cute.int_tuple<"8">
          %coord_2984 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %slice_2985 = cute.slice(%ptn_C, %coord_2984) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,0)">
          %iter_2986 = cute.get_iter(%slice_2985) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2987, %e1_2988 = cute.get_leaves(%iter_2986) : !cute.int_tuple<"(?,?)">
          %1188 = cute.get_scalars(%e0_2987) : !cute.int_tuple<"?">
          %1189 = cute.get_scalars(%e1_2988) : !cute.int_tuple<"?">
          %iter_2989 = cute.get_iter(%slice_2985) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2990, %e1_2991 = cute.get_leaves(%iter_2989) : !cute.int_tuple<"(?,?)">
          %1190 = cute.get_scalars(%e0_2990) : !cute.int_tuple<"?">
          %1191 = cute.get_scalars(%e1_2991) : !cute.int_tuple<"?">
          %iter_2992 = cute.get_iter(%slice_2985) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2993, %e1_2994 = cute.get_leaves(%iter_2992) : !cute.int_tuple<"(?,?)">
          %1192 = cute.get_scalars(%e0_2993) : !cute.int_tuple<"?">
          %1193 = cute.get_scalars(%e1_2994) : !cute.int_tuple<"?">
          %coord_2995 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %slice_2996 = cute.slice(%ptn_C, %coord_2995) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,0)">
          %iter_2997 = cute.get_iter(%slice_2996) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2998, %e1_2999 = cute.get_leaves(%iter_2997) : !cute.int_tuple<"(?,?)">
          %1194 = cute.get_scalars(%e0_2998) : !cute.int_tuple<"?">
          %1195 = cute.get_scalars(%e1_2999) : !cute.int_tuple<"?">
          %iter_3000 = cute.get_iter(%slice_2996) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3001, %e1_3002 = cute.get_leaves(%iter_3000) : !cute.int_tuple<"(?,?)">
          %1196 = cute.get_scalars(%e0_3001) : !cute.int_tuple<"?">
          %1197 = cute.get_scalars(%e1_3002) : !cute.int_tuple<"?">
          %iter_3003 = cute.get_iter(%slice_2996) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3004, %e1_3005 = cute.get_leaves(%iter_3003) : !cute.int_tuple<"(?,?)">
          %1198 = cute.get_scalars(%e0_3004) : !cute.int_tuple<"?">
          %1199 = cute.get_scalars(%e1_3005) : !cute.int_tuple<"?">
          %coord_3006 = cute.make_coord(%e0_2993) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3007 = cute.make_coord(%e1_3005) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1200 = cute.elem_less(%coord_3006, %coord_3007) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3008 = cute.get_layout(%1185) : !memref_rmem_f32_1
          %1201 = cute.get_shape(%lay_3008) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3009, %e1_3010, %e2_3011, %e3_3012 = cute.get_leaves(%1201) : !cute.shape<"((2,2),1,8)">
          %1202 = cute.get_stride(%lay_3008) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3013, %e1_3014, %e2_3015, %e3_3016 = cute.get_leaves(%1202) : !cute.stride<"((1,2),0,4)">
          %1203 = scf.if %1200 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1185) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
            cute.memref.store(%1185, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1185) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1185 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1185) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1185) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1185 : !memref_rmem_f32_1
          }
          %iter_3017 = cute.get_iter(%1203) : !memref_rmem_f32_1
          %lay_3018 = cute.get_layout(%1203) : !memref_rmem_f32_1
          %1204 = cute.get_shape(%lay_3018) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3019, %e1_3020, %e2_3021, %e3_3022 = cute.get_leaves(%1204) : !cute.shape<"((2,2),1,8)">
          %1205 = cute.get_stride(%lay_3018) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3023, %e1_3024, %e2_3025, %e3_3026 = cute.get_leaves(%1205) : !cute.stride<"((1,2),0,4)">
          %iter_3027 = cute.get_iter(%1203) : !memref_rmem_f32_1
          %iter_3028 = cute.get_iter(%1203) : !memref_rmem_f32_1
          %coord_3029 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %slice_3030 = cute.slice(%ptn_C, %coord_3029) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,1)">
          %iter_3031 = cute.get_iter(%slice_3030) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3032, %e1_3033 = cute.get_leaves(%iter_3031) : !cute.int_tuple<"(?,?)">
          %1206 = cute.get_scalars(%e0_3032) : !cute.int_tuple<"?">
          %1207 = cute.get_scalars(%e1_3033) : !cute.int_tuple<"?">
          %iter_3034 = cute.get_iter(%slice_3030) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3035, %e1_3036 = cute.get_leaves(%iter_3034) : !cute.int_tuple<"(?,?)">
          %1208 = cute.get_scalars(%e0_3035) : !cute.int_tuple<"?">
          %1209 = cute.get_scalars(%e1_3036) : !cute.int_tuple<"?">
          %iter_3037 = cute.get_iter(%slice_3030) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3038, %e1_3039 = cute.get_leaves(%iter_3037) : !cute.int_tuple<"(?,?)">
          %1210 = cute.get_scalars(%e0_3038) : !cute.int_tuple<"?">
          %1211 = cute.get_scalars(%e1_3039) : !cute.int_tuple<"?">
          %coord_3040 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %slice_3041 = cute.slice(%ptn_C, %coord_3040) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,1)">
          %iter_3042 = cute.get_iter(%slice_3041) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3043, %e1_3044 = cute.get_leaves(%iter_3042) : !cute.int_tuple<"(?,?)">
          %1212 = cute.get_scalars(%e0_3043) : !cute.int_tuple<"?">
          %1213 = cute.get_scalars(%e1_3044) : !cute.int_tuple<"?">
          %iter_3045 = cute.get_iter(%slice_3041) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3046, %e1_3047 = cute.get_leaves(%iter_3045) : !cute.int_tuple<"(?,?)">
          %1214 = cute.get_scalars(%e0_3046) : !cute.int_tuple<"?">
          %1215 = cute.get_scalars(%e1_3047) : !cute.int_tuple<"?">
          %iter_3048 = cute.get_iter(%slice_3041) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3049, %e1_3050 = cute.get_leaves(%iter_3048) : !cute.int_tuple<"(?,?)">
          %1216 = cute.get_scalars(%e0_3049) : !cute.int_tuple<"?">
          %1217 = cute.get_scalars(%e1_3050) : !cute.int_tuple<"?">
          %coord_3051 = cute.make_coord(%e0_3038) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3052 = cute.make_coord(%e1_3050) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1218 = cute.elem_less(%coord_3051, %coord_3052) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3053 = cute.get_layout(%1203) : !memref_rmem_f32_1
          %1219 = cute.get_shape(%lay_3053) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3054, %e1_3055, %e2_3056, %e3_3057 = cute.get_leaves(%1219) : !cute.shape<"((2,2),1,8)">
          %1220 = cute.get_stride(%lay_3053) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3058, %e1_3059, %e2_3060, %e3_3061 = cute.get_leaves(%1220) : !cute.stride<"((1,2),0,4)">
          %1221 = scf.if %1218 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1203) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
            cute.memref.store(%1203, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1203) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1203 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1203) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1203) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1203 : !memref_rmem_f32_1
          }
          %iter_3062 = cute.get_iter(%1221) : !memref_rmem_f32_1
          %lay_3063 = cute.get_layout(%1221) : !memref_rmem_f32_1
          %1222 = cute.get_shape(%lay_3063) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3064, %e1_3065, %e2_3066, %e3_3067 = cute.get_leaves(%1222) : !cute.shape<"((2,2),1,8)">
          %1223 = cute.get_stride(%lay_3063) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3068, %e1_3069, %e2_3070, %e3_3071 = cute.get_leaves(%1223) : !cute.stride<"((1,2),0,4)">
          %iter_3072 = cute.get_iter(%1221) : !memref_rmem_f32_1
          %iter_3073 = cute.get_iter(%1221) : !memref_rmem_f32_1
          %coord_3074 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %slice_3075 = cute.slice(%ptn_C, %coord_3074) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,2)">
          %iter_3076 = cute.get_iter(%slice_3075) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3077, %e1_3078 = cute.get_leaves(%iter_3076) : !cute.int_tuple<"(?,?)">
          %1224 = cute.get_scalars(%e0_3077) : !cute.int_tuple<"?">
          %1225 = cute.get_scalars(%e1_3078) : !cute.int_tuple<"?">
          %iter_3079 = cute.get_iter(%slice_3075) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3080, %e1_3081 = cute.get_leaves(%iter_3079) : !cute.int_tuple<"(?,?)">
          %1226 = cute.get_scalars(%e0_3080) : !cute.int_tuple<"?">
          %1227 = cute.get_scalars(%e1_3081) : !cute.int_tuple<"?">
          %iter_3082 = cute.get_iter(%slice_3075) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3083, %e1_3084 = cute.get_leaves(%iter_3082) : !cute.int_tuple<"(?,?)">
          %1228 = cute.get_scalars(%e0_3083) : !cute.int_tuple<"?">
          %1229 = cute.get_scalars(%e1_3084) : !cute.int_tuple<"?">
          %coord_3085 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %slice_3086 = cute.slice(%ptn_C, %coord_3085) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,2)">
          %iter_3087 = cute.get_iter(%slice_3086) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3088, %e1_3089 = cute.get_leaves(%iter_3087) : !cute.int_tuple<"(?,?)">
          %1230 = cute.get_scalars(%e0_3088) : !cute.int_tuple<"?">
          %1231 = cute.get_scalars(%e1_3089) : !cute.int_tuple<"?">
          %iter_3090 = cute.get_iter(%slice_3086) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3091, %e1_3092 = cute.get_leaves(%iter_3090) : !cute.int_tuple<"(?,?)">
          %1232 = cute.get_scalars(%e0_3091) : !cute.int_tuple<"?">
          %1233 = cute.get_scalars(%e1_3092) : !cute.int_tuple<"?">
          %iter_3093 = cute.get_iter(%slice_3086) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3094, %e1_3095 = cute.get_leaves(%iter_3093) : !cute.int_tuple<"(?,?)">
          %1234 = cute.get_scalars(%e0_3094) : !cute.int_tuple<"?">
          %1235 = cute.get_scalars(%e1_3095) : !cute.int_tuple<"?">
          %coord_3096 = cute.make_coord(%e0_3083) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3097 = cute.make_coord(%e1_3095) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1236 = cute.elem_less(%coord_3096, %coord_3097) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3098 = cute.get_layout(%1221) : !memref_rmem_f32_1
          %1237 = cute.get_shape(%lay_3098) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3099, %e1_3100, %e2_3101, %e3_3102 = cute.get_leaves(%1237) : !cute.shape<"((2,2),1,8)">
          %1238 = cute.get_stride(%lay_3098) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3103, %e1_3104, %e2_3105, %e3_3106 = cute.get_leaves(%1238) : !cute.stride<"((1,2),0,4)">
          %1239 = scf.if %1236 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1221) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
            cute.memref.store(%1221, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1221) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1221 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1221) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1221) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1221 : !memref_rmem_f32_1
          }
          %iter_3107 = cute.get_iter(%1239) : !memref_rmem_f32_1
          %lay_3108 = cute.get_layout(%1239) : !memref_rmem_f32_1
          %1240 = cute.get_shape(%lay_3108) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3109, %e1_3110, %e2_3111, %e3_3112 = cute.get_leaves(%1240) : !cute.shape<"((2,2),1,8)">
          %1241 = cute.get_stride(%lay_3108) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3113, %e1_3114, %e2_3115, %e3_3116 = cute.get_leaves(%1241) : !cute.stride<"((1,2),0,4)">
          %iter_3117 = cute.get_iter(%1239) : !memref_rmem_f32_1
          %iter_3118 = cute.get_iter(%1239) : !memref_rmem_f32_1
          %coord_3119 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %slice_3120 = cute.slice(%ptn_C, %coord_3119) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,3)">
          %iter_3121 = cute.get_iter(%slice_3120) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3122, %e1_3123 = cute.get_leaves(%iter_3121) : !cute.int_tuple<"(?,?)">
          %1242 = cute.get_scalars(%e0_3122) : !cute.int_tuple<"?">
          %1243 = cute.get_scalars(%e1_3123) : !cute.int_tuple<"?">
          %iter_3124 = cute.get_iter(%slice_3120) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3125, %e1_3126 = cute.get_leaves(%iter_3124) : !cute.int_tuple<"(?,?)">
          %1244 = cute.get_scalars(%e0_3125) : !cute.int_tuple<"?">
          %1245 = cute.get_scalars(%e1_3126) : !cute.int_tuple<"?">
          %iter_3127 = cute.get_iter(%slice_3120) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3128, %e1_3129 = cute.get_leaves(%iter_3127) : !cute.int_tuple<"(?,?)">
          %1246 = cute.get_scalars(%e0_3128) : !cute.int_tuple<"?">
          %1247 = cute.get_scalars(%e1_3129) : !cute.int_tuple<"?">
          %coord_3130 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %slice_3131 = cute.slice(%ptn_C, %coord_3130) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,3)">
          %iter_3132 = cute.get_iter(%slice_3131) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3133, %e1_3134 = cute.get_leaves(%iter_3132) : !cute.int_tuple<"(?,?)">
          %1248 = cute.get_scalars(%e0_3133) : !cute.int_tuple<"?">
          %1249 = cute.get_scalars(%e1_3134) : !cute.int_tuple<"?">
          %iter_3135 = cute.get_iter(%slice_3131) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3136, %e1_3137 = cute.get_leaves(%iter_3135) : !cute.int_tuple<"(?,?)">
          %1250 = cute.get_scalars(%e0_3136) : !cute.int_tuple<"?">
          %1251 = cute.get_scalars(%e1_3137) : !cute.int_tuple<"?">
          %iter_3138 = cute.get_iter(%slice_3131) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3139, %e1_3140 = cute.get_leaves(%iter_3138) : !cute.int_tuple<"(?,?)">
          %1252 = cute.get_scalars(%e0_3139) : !cute.int_tuple<"?">
          %1253 = cute.get_scalars(%e1_3140) : !cute.int_tuple<"?">
          %coord_3141 = cute.make_coord(%e0_3128) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3142 = cute.make_coord(%e1_3140) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1254 = cute.elem_less(%coord_3141, %coord_3142) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3143 = cute.get_layout(%1239) : !memref_rmem_f32_1
          %1255 = cute.get_shape(%lay_3143) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3144, %e1_3145, %e2_3146, %e3_3147 = cute.get_leaves(%1255) : !cute.shape<"((2,2),1,8)">
          %1256 = cute.get_stride(%lay_3143) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3148, %e1_3149, %e2_3150, %e3_3151 = cute.get_leaves(%1256) : !cute.stride<"((1,2),0,4)">
          %1257 = scf.if %1254 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1239) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
            cute.memref.store(%1239, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1239) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1239 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1239) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1239) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1239 : !memref_rmem_f32_1
          }
          %iter_3152 = cute.get_iter(%1257) : !memref_rmem_f32_1
          %lay_3153 = cute.get_layout(%1257) : !memref_rmem_f32_1
          %1258 = cute.get_shape(%lay_3153) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3154, %e1_3155, %e2_3156, %e3_3157 = cute.get_leaves(%1258) : !cute.shape<"((2,2),1,8)">
          %1259 = cute.get_stride(%lay_3153) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3158, %e1_3159, %e2_3160, %e3_3161 = cute.get_leaves(%1259) : !cute.stride<"((1,2),0,4)">
          %iter_3162 = cute.get_iter(%1257) : !memref_rmem_f32_1
          %iter_3163 = cute.get_iter(%1257) : !memref_rmem_f32_1
          %coord_3164 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %slice_3165 = cute.slice(%ptn_C, %coord_3164) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,4)">
          %iter_3166 = cute.get_iter(%slice_3165) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3167, %e1_3168 = cute.get_leaves(%iter_3166) : !cute.int_tuple<"(?,?)">
          %1260 = cute.get_scalars(%e0_3167) : !cute.int_tuple<"?">
          %1261 = cute.get_scalars(%e1_3168) : !cute.int_tuple<"?">
          %iter_3169 = cute.get_iter(%slice_3165) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3170, %e1_3171 = cute.get_leaves(%iter_3169) : !cute.int_tuple<"(?,?)">
          %1262 = cute.get_scalars(%e0_3170) : !cute.int_tuple<"?">
          %1263 = cute.get_scalars(%e1_3171) : !cute.int_tuple<"?">
          %iter_3172 = cute.get_iter(%slice_3165) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3173, %e1_3174 = cute.get_leaves(%iter_3172) : !cute.int_tuple<"(?,?)">
          %1264 = cute.get_scalars(%e0_3173) : !cute.int_tuple<"?">
          %1265 = cute.get_scalars(%e1_3174) : !cute.int_tuple<"?">
          %coord_3175 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %slice_3176 = cute.slice(%ptn_C, %coord_3175) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,4)">
          %iter_3177 = cute.get_iter(%slice_3176) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3178, %e1_3179 = cute.get_leaves(%iter_3177) : !cute.int_tuple<"(?,?)">
          %1266 = cute.get_scalars(%e0_3178) : !cute.int_tuple<"?">
          %1267 = cute.get_scalars(%e1_3179) : !cute.int_tuple<"?">
          %iter_3180 = cute.get_iter(%slice_3176) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3181, %e1_3182 = cute.get_leaves(%iter_3180) : !cute.int_tuple<"(?,?)">
          %1268 = cute.get_scalars(%e0_3181) : !cute.int_tuple<"?">
          %1269 = cute.get_scalars(%e1_3182) : !cute.int_tuple<"?">
          %iter_3183 = cute.get_iter(%slice_3176) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3184, %e1_3185 = cute.get_leaves(%iter_3183) : !cute.int_tuple<"(?,?)">
          %1270 = cute.get_scalars(%e0_3184) : !cute.int_tuple<"?">
          %1271 = cute.get_scalars(%e1_3185) : !cute.int_tuple<"?">
          %coord_3186 = cute.make_coord(%e0_3173) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3187 = cute.make_coord(%e1_3185) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1272 = cute.elem_less(%coord_3186, %coord_3187) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3188 = cute.get_layout(%1257) : !memref_rmem_f32_1
          %1273 = cute.get_shape(%lay_3188) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3189, %e1_3190, %e2_3191, %e3_3192 = cute.get_leaves(%1273) : !cute.shape<"((2,2),1,8)">
          %1274 = cute.get_stride(%lay_3188) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3193, %e1_3194, %e2_3195, %e3_3196 = cute.get_leaves(%1274) : !cute.stride<"((1,2),0,4)">
          %1275 = scf.if %1272 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1257) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
            cute.memref.store(%1257, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1257) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1257 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1257) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1257) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1257 : !memref_rmem_f32_1
          }
          %iter_3197 = cute.get_iter(%1275) : !memref_rmem_f32_1
          %lay_3198 = cute.get_layout(%1275) : !memref_rmem_f32_1
          %1276 = cute.get_shape(%lay_3198) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3199, %e1_3200, %e2_3201, %e3_3202 = cute.get_leaves(%1276) : !cute.shape<"((2,2),1,8)">
          %1277 = cute.get_stride(%lay_3198) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3203, %e1_3204, %e2_3205, %e3_3206 = cute.get_leaves(%1277) : !cute.stride<"((1,2),0,4)">
          %iter_3207 = cute.get_iter(%1275) : !memref_rmem_f32_1
          %iter_3208 = cute.get_iter(%1275) : !memref_rmem_f32_1
          %coord_3209 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %slice_3210 = cute.slice(%ptn_C, %coord_3209) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,5)">
          %iter_3211 = cute.get_iter(%slice_3210) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3212, %e1_3213 = cute.get_leaves(%iter_3211) : !cute.int_tuple<"(?,?)">
          %1278 = cute.get_scalars(%e0_3212) : !cute.int_tuple<"?">
          %1279 = cute.get_scalars(%e1_3213) : !cute.int_tuple<"?">
          %iter_3214 = cute.get_iter(%slice_3210) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3215, %e1_3216 = cute.get_leaves(%iter_3214) : !cute.int_tuple<"(?,?)">
          %1280 = cute.get_scalars(%e0_3215) : !cute.int_tuple<"?">
          %1281 = cute.get_scalars(%e1_3216) : !cute.int_tuple<"?">
          %iter_3217 = cute.get_iter(%slice_3210) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3218, %e1_3219 = cute.get_leaves(%iter_3217) : !cute.int_tuple<"(?,?)">
          %1282 = cute.get_scalars(%e0_3218) : !cute.int_tuple<"?">
          %1283 = cute.get_scalars(%e1_3219) : !cute.int_tuple<"?">
          %coord_3220 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %slice_3221 = cute.slice(%ptn_C, %coord_3220) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,5)">
          %iter_3222 = cute.get_iter(%slice_3221) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3223, %e1_3224 = cute.get_leaves(%iter_3222) : !cute.int_tuple<"(?,?)">
          %1284 = cute.get_scalars(%e0_3223) : !cute.int_tuple<"?">
          %1285 = cute.get_scalars(%e1_3224) : !cute.int_tuple<"?">
          %iter_3225 = cute.get_iter(%slice_3221) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3226, %e1_3227 = cute.get_leaves(%iter_3225) : !cute.int_tuple<"(?,?)">
          %1286 = cute.get_scalars(%e0_3226) : !cute.int_tuple<"?">
          %1287 = cute.get_scalars(%e1_3227) : !cute.int_tuple<"?">
          %iter_3228 = cute.get_iter(%slice_3221) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3229, %e1_3230 = cute.get_leaves(%iter_3228) : !cute.int_tuple<"(?,?)">
          %1288 = cute.get_scalars(%e0_3229) : !cute.int_tuple<"?">
          %1289 = cute.get_scalars(%e1_3230) : !cute.int_tuple<"?">
          %coord_3231 = cute.make_coord(%e0_3218) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3232 = cute.make_coord(%e1_3230) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1290 = cute.elem_less(%coord_3231, %coord_3232) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3233 = cute.get_layout(%1275) : !memref_rmem_f32_1
          %1291 = cute.get_shape(%lay_3233) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3234, %e1_3235, %e2_3236, %e3_3237 = cute.get_leaves(%1291) : !cute.shape<"((2,2),1,8)">
          %1292 = cute.get_stride(%lay_3233) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3238, %e1_3239, %e2_3240, %e3_3241 = cute.get_leaves(%1292) : !cute.stride<"((1,2),0,4)">
          %1293 = scf.if %1290 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1275) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
            cute.memref.store(%1275, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1275) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1275 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1275) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1275) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1275 : !memref_rmem_f32_1
          }
          %iter_3242 = cute.get_iter(%1293) : !memref_rmem_f32_1
          %lay_3243 = cute.get_layout(%1293) : !memref_rmem_f32_1
          %1294 = cute.get_shape(%lay_3243) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3244, %e1_3245, %e2_3246, %e3_3247 = cute.get_leaves(%1294) : !cute.shape<"((2,2),1,8)">
          %1295 = cute.get_stride(%lay_3243) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3248, %e1_3249, %e2_3250, %e3_3251 = cute.get_leaves(%1295) : !cute.stride<"((1,2),0,4)">
          %iter_3252 = cute.get_iter(%1293) : !memref_rmem_f32_1
          %iter_3253 = cute.get_iter(%1293) : !memref_rmem_f32_1
          %coord_3254 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %slice_3255 = cute.slice(%ptn_C, %coord_3254) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,6)">
          %iter_3256 = cute.get_iter(%slice_3255) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3257, %e1_3258 = cute.get_leaves(%iter_3256) : !cute.int_tuple<"(?,?)">
          %1296 = cute.get_scalars(%e0_3257) : !cute.int_tuple<"?">
          %1297 = cute.get_scalars(%e1_3258) : !cute.int_tuple<"?">
          %iter_3259 = cute.get_iter(%slice_3255) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3260, %e1_3261 = cute.get_leaves(%iter_3259) : !cute.int_tuple<"(?,?)">
          %1298 = cute.get_scalars(%e0_3260) : !cute.int_tuple<"?">
          %1299 = cute.get_scalars(%e1_3261) : !cute.int_tuple<"?">
          %iter_3262 = cute.get_iter(%slice_3255) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3263, %e1_3264 = cute.get_leaves(%iter_3262) : !cute.int_tuple<"(?,?)">
          %1300 = cute.get_scalars(%e0_3263) : !cute.int_tuple<"?">
          %1301 = cute.get_scalars(%e1_3264) : !cute.int_tuple<"?">
          %coord_3265 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %slice_3266 = cute.slice(%ptn_C, %coord_3265) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,6)">
          %iter_3267 = cute.get_iter(%slice_3266) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3268, %e1_3269 = cute.get_leaves(%iter_3267) : !cute.int_tuple<"(?,?)">
          %1302 = cute.get_scalars(%e0_3268) : !cute.int_tuple<"?">
          %1303 = cute.get_scalars(%e1_3269) : !cute.int_tuple<"?">
          %iter_3270 = cute.get_iter(%slice_3266) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3271, %e1_3272 = cute.get_leaves(%iter_3270) : !cute.int_tuple<"(?,?)">
          %1304 = cute.get_scalars(%e0_3271) : !cute.int_tuple<"?">
          %1305 = cute.get_scalars(%e1_3272) : !cute.int_tuple<"?">
          %iter_3273 = cute.get_iter(%slice_3266) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3274, %e1_3275 = cute.get_leaves(%iter_3273) : !cute.int_tuple<"(?,?)">
          %1306 = cute.get_scalars(%e0_3274) : !cute.int_tuple<"?">
          %1307 = cute.get_scalars(%e1_3275) : !cute.int_tuple<"?">
          %coord_3276 = cute.make_coord(%e0_3263) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3277 = cute.make_coord(%e1_3275) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1308 = cute.elem_less(%coord_3276, %coord_3277) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3278 = cute.get_layout(%1293) : !memref_rmem_f32_1
          %1309 = cute.get_shape(%lay_3278) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3279, %e1_3280, %e2_3281, %e3_3282 = cute.get_leaves(%1309) : !cute.shape<"((2,2),1,8)">
          %1310 = cute.get_stride(%lay_3278) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3283, %e1_3284, %e2_3285, %e3_3286 = cute.get_leaves(%1310) : !cute.stride<"((1,2),0,4)">
          %1311 = scf.if %1308 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1293) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
            cute.memref.store(%1293, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1293) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1293 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1293) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1293) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1293 : !memref_rmem_f32_1
          }
          %iter_3287 = cute.get_iter(%1311) : !memref_rmem_f32_1
          %lay_3288 = cute.get_layout(%1311) : !memref_rmem_f32_1
          %1312 = cute.get_shape(%lay_3288) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3289, %e1_3290, %e2_3291, %e3_3292 = cute.get_leaves(%1312) : !cute.shape<"((2,2),1,8)">
          %1313 = cute.get_stride(%lay_3288) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3293, %e1_3294, %e2_3295, %e3_3296 = cute.get_leaves(%1313) : !cute.stride<"((1,2),0,4)">
          %iter_3297 = cute.get_iter(%1311) : !memref_rmem_f32_1
          %iter_3298 = cute.get_iter(%1311) : !memref_rmem_f32_1
          %coord_3299 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %slice_3300 = cute.slice(%ptn_C, %coord_3299) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,7)">
          %iter_3301 = cute.get_iter(%slice_3300) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3302, %e1_3303 = cute.get_leaves(%iter_3301) : !cute.int_tuple<"(?,?)">
          %1314 = cute.get_scalars(%e0_3302) : !cute.int_tuple<"?">
          %1315 = cute.get_scalars(%e1_3303) : !cute.int_tuple<"?">
          %iter_3304 = cute.get_iter(%slice_3300) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3305, %e1_3306 = cute.get_leaves(%iter_3304) : !cute.int_tuple<"(?,?)">
          %1316 = cute.get_scalars(%e0_3305) : !cute.int_tuple<"?">
          %1317 = cute.get_scalars(%e1_3306) : !cute.int_tuple<"?">
          %iter_3307 = cute.get_iter(%slice_3300) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3308, %e1_3309 = cute.get_leaves(%iter_3307) : !cute.int_tuple<"(?,?)">
          %1318 = cute.get_scalars(%e0_3308) : !cute.int_tuple<"?">
          %1319 = cute.get_scalars(%e1_3309) : !cute.int_tuple<"?">
          %coord_3310 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %slice_3311 = cute.slice(%ptn_C, %coord_3310) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,7)">
          %iter_3312 = cute.get_iter(%slice_3311) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3313, %e1_3314 = cute.get_leaves(%iter_3312) : !cute.int_tuple<"(?,?)">
          %1320 = cute.get_scalars(%e0_3313) : !cute.int_tuple<"?">
          %1321 = cute.get_scalars(%e1_3314) : !cute.int_tuple<"?">
          %iter_3315 = cute.get_iter(%slice_3311) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3316, %e1_3317 = cute.get_leaves(%iter_3315) : !cute.int_tuple<"(?,?)">
          %1322 = cute.get_scalars(%e0_3316) : !cute.int_tuple<"?">
          %1323 = cute.get_scalars(%e1_3317) : !cute.int_tuple<"?">
          %iter_3318 = cute.get_iter(%slice_3311) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3319, %e1_3320 = cute.get_leaves(%iter_3318) : !cute.int_tuple<"(?,?)">
          %1324 = cute.get_scalars(%e0_3319) : !cute.int_tuple<"?">
          %1325 = cute.get_scalars(%e1_3320) : !cute.int_tuple<"?">
          %coord_3321 = cute.make_coord(%e0_3308) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3322 = cute.make_coord(%e1_3320) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1326 = cute.elem_less(%coord_3321, %coord_3322) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3323 = cute.get_layout(%1311) : !memref_rmem_f32_1
          %1327 = cute.get_shape(%lay_3323) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3324, %e1_3325, %e2_3326, %e3_3327 = cute.get_leaves(%1327) : !cute.shape<"((2,2),1,8)">
          %1328 = cute.get_stride(%lay_3323) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3328, %e1_3329, %e2_3330, %e3_3331 = cute.get_leaves(%1328) : !cute.stride<"((1,2),0,4)">
          %1329 = scf.if %1326 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1311) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
            cute.memref.store(%1311, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1311) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1311 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1311) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1311) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1311 : !memref_rmem_f32_1
          }
          %iter_3332 = cute.get_iter(%1329) : !memref_rmem_f32_1
          %lay_3333 = cute.get_layout(%1329) : !memref_rmem_f32_1
          %1330 = cute.get_shape(%lay_3333) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3334, %e1_3335, %e2_3336, %e3_3337 = cute.get_leaves(%1330) : !cute.shape<"((2,2),1,8)">
          %1331 = cute.get_stride(%lay_3333) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3338, %e1_3339, %e2_3340, %e3_3341 = cute.get_leaves(%1331) : !cute.stride<"((1,2),0,4)">
          %iter_3342 = cute.get_iter(%1329) : !memref_rmem_f32_1
          %iter_3343 = cute.get_iter(%1329) : !memref_rmem_f32_1
          %int_tuple_3344 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_3345 = cute.size(%int_tuple_3344) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_3346 = cute.get_leaves(%sz_3345) : !cute.int_tuple<"1">
          %int_tuple_3347 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_3348 = cute.size(%int_tuple_3347) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_3349 = cute.get_leaves(%sz_3348) : !cute.int_tuple<"8">
          %coord_3350 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %slice_3351 = cute.slice(%ptn_C, %coord_3350) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,0)">
          %iter_3352 = cute.get_iter(%slice_3351) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3353, %e1_3354 = cute.get_leaves(%iter_3352) : !cute.int_tuple<"(?,?{div=2})">
          %1332 = cute.get_scalars(%e0_3353) : !cute.int_tuple<"?">
          %1333 = cute.get_scalars(%e1_3354) : !cute.int_tuple<"?{div=2}">
          %iter_3355 = cute.get_iter(%slice_3351) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3356, %e1_3357 = cute.get_leaves(%iter_3355) : !cute.int_tuple<"(?,?{div=2})">
          %1334 = cute.get_scalars(%e0_3356) : !cute.int_tuple<"?">
          %1335 = cute.get_scalars(%e1_3357) : !cute.int_tuple<"?{div=2}">
          %iter_3358 = cute.get_iter(%slice_3351) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3359, %e1_3360 = cute.get_leaves(%iter_3358) : !cute.int_tuple<"(?,?{div=2})">
          %1336 = cute.get_scalars(%e0_3359) : !cute.int_tuple<"?">
          %1337 = cute.get_scalars(%e1_3360) : !cute.int_tuple<"?{div=2}">
          %coord_3361 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %slice_3362 = cute.slice(%ptn_C, %coord_3361) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,0)">
          %iter_3363 = cute.get_iter(%slice_3362) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3364, %e1_3365 = cute.get_leaves(%iter_3363) : !cute.int_tuple<"(?,?{div=2})">
          %1338 = cute.get_scalars(%e0_3364) : !cute.int_tuple<"?">
          %1339 = cute.get_scalars(%e1_3365) : !cute.int_tuple<"?{div=2}">
          %iter_3366 = cute.get_iter(%slice_3362) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3367, %e1_3368 = cute.get_leaves(%iter_3366) : !cute.int_tuple<"(?,?{div=2})">
          %1340 = cute.get_scalars(%e0_3367) : !cute.int_tuple<"?">
          %1341 = cute.get_scalars(%e1_3368) : !cute.int_tuple<"?{div=2}">
          %iter_3369 = cute.get_iter(%slice_3362) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3370, %e1_3371 = cute.get_leaves(%iter_3369) : !cute.int_tuple<"(?,?{div=2})">
          %1342 = cute.get_scalars(%e0_3370) : !cute.int_tuple<"?">
          %1343 = cute.get_scalars(%e1_3371) : !cute.int_tuple<"?{div=2}">
          %coord_3372 = cute.make_coord(%e0_3359) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3373 = cute.make_coord(%e1_3371) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1344 = cute.elem_less(%coord_3372, %coord_3373) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3374 = cute.get_layout(%1329) : !memref_rmem_f32_1
          %1345 = cute.get_shape(%lay_3374) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3375, %e1_3376, %e2_3377, %e3_3378 = cute.get_leaves(%1345) : !cute.shape<"((2,2),1,8)">
          %1346 = cute.get_stride(%lay_3374) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3379, %e1_3380, %e2_3381, %e3_3382 = cute.get_leaves(%1346) : !cute.stride<"((1,2),0,4)">
          %1347 = scf.if %1344 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1329) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
            cute.memref.store(%1329, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1329) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1329 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1329) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1329) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1329 : !memref_rmem_f32_1
          }
          %iter_3383 = cute.get_iter(%1347) : !memref_rmem_f32_1
          %lay_3384 = cute.get_layout(%1347) : !memref_rmem_f32_1
          %1348 = cute.get_shape(%lay_3384) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3385, %e1_3386, %e2_3387, %e3_3388 = cute.get_leaves(%1348) : !cute.shape<"((2,2),1,8)">
          %1349 = cute.get_stride(%lay_3384) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3389, %e1_3390, %e2_3391, %e3_3392 = cute.get_leaves(%1349) : !cute.stride<"((1,2),0,4)">
          %iter_3393 = cute.get_iter(%1347) : !memref_rmem_f32_1
          %iter_3394 = cute.get_iter(%1347) : !memref_rmem_f32_1
          %coord_3395 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %slice_3396 = cute.slice(%ptn_C, %coord_3395) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,1)">
          %iter_3397 = cute.get_iter(%slice_3396) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3398, %e1_3399 = cute.get_leaves(%iter_3397) : !cute.int_tuple<"(?,?{div=2})">
          %1350 = cute.get_scalars(%e0_3398) : !cute.int_tuple<"?">
          %1351 = cute.get_scalars(%e1_3399) : !cute.int_tuple<"?{div=2}">
          %iter_3400 = cute.get_iter(%slice_3396) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3401, %e1_3402 = cute.get_leaves(%iter_3400) : !cute.int_tuple<"(?,?{div=2})">
          %1352 = cute.get_scalars(%e0_3401) : !cute.int_tuple<"?">
          %1353 = cute.get_scalars(%e1_3402) : !cute.int_tuple<"?{div=2}">
          %iter_3403 = cute.get_iter(%slice_3396) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3404, %e1_3405 = cute.get_leaves(%iter_3403) : !cute.int_tuple<"(?,?{div=2})">
          %1354 = cute.get_scalars(%e0_3404) : !cute.int_tuple<"?">
          %1355 = cute.get_scalars(%e1_3405) : !cute.int_tuple<"?{div=2}">
          %coord_3406 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %slice_3407 = cute.slice(%ptn_C, %coord_3406) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,1)">
          %iter_3408 = cute.get_iter(%slice_3407) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3409, %e1_3410 = cute.get_leaves(%iter_3408) : !cute.int_tuple<"(?,?{div=2})">
          %1356 = cute.get_scalars(%e0_3409) : !cute.int_tuple<"?">
          %1357 = cute.get_scalars(%e1_3410) : !cute.int_tuple<"?{div=2}">
          %iter_3411 = cute.get_iter(%slice_3407) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3412, %e1_3413 = cute.get_leaves(%iter_3411) : !cute.int_tuple<"(?,?{div=2})">
          %1358 = cute.get_scalars(%e0_3412) : !cute.int_tuple<"?">
          %1359 = cute.get_scalars(%e1_3413) : !cute.int_tuple<"?{div=2}">
          %iter_3414 = cute.get_iter(%slice_3407) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3415, %e1_3416 = cute.get_leaves(%iter_3414) : !cute.int_tuple<"(?,?{div=2})">
          %1360 = cute.get_scalars(%e0_3415) : !cute.int_tuple<"?">
          %1361 = cute.get_scalars(%e1_3416) : !cute.int_tuple<"?{div=2}">
          %coord_3417 = cute.make_coord(%e0_3404) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3418 = cute.make_coord(%e1_3416) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1362 = cute.elem_less(%coord_3417, %coord_3418) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3419 = cute.get_layout(%1347) : !memref_rmem_f32_1
          %1363 = cute.get_shape(%lay_3419) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3420, %e1_3421, %e2_3422, %e3_3423 = cute.get_leaves(%1363) : !cute.shape<"((2,2),1,8)">
          %1364 = cute.get_stride(%lay_3419) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3424, %e1_3425, %e2_3426, %e3_3427 = cute.get_leaves(%1364) : !cute.stride<"((1,2),0,4)">
          %1365 = scf.if %1362 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1347) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
            cute.memref.store(%1347, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1347) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1347 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1347) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1347) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1347 : !memref_rmem_f32_1
          }
          %iter_3428 = cute.get_iter(%1365) : !memref_rmem_f32_1
          %lay_3429 = cute.get_layout(%1365) : !memref_rmem_f32_1
          %1366 = cute.get_shape(%lay_3429) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3430, %e1_3431, %e2_3432, %e3_3433 = cute.get_leaves(%1366) : !cute.shape<"((2,2),1,8)">
          %1367 = cute.get_stride(%lay_3429) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3434, %e1_3435, %e2_3436, %e3_3437 = cute.get_leaves(%1367) : !cute.stride<"((1,2),0,4)">
          %iter_3438 = cute.get_iter(%1365) : !memref_rmem_f32_1
          %iter_3439 = cute.get_iter(%1365) : !memref_rmem_f32_1
          %coord_3440 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %slice_3441 = cute.slice(%ptn_C, %coord_3440) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,2)">
          %iter_3442 = cute.get_iter(%slice_3441) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3443, %e1_3444 = cute.get_leaves(%iter_3442) : !cute.int_tuple<"(?,?{div=2})">
          %1368 = cute.get_scalars(%e0_3443) : !cute.int_tuple<"?">
          %1369 = cute.get_scalars(%e1_3444) : !cute.int_tuple<"?{div=2}">
          %iter_3445 = cute.get_iter(%slice_3441) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3446, %e1_3447 = cute.get_leaves(%iter_3445) : !cute.int_tuple<"(?,?{div=2})">
          %1370 = cute.get_scalars(%e0_3446) : !cute.int_tuple<"?">
          %1371 = cute.get_scalars(%e1_3447) : !cute.int_tuple<"?{div=2}">
          %iter_3448 = cute.get_iter(%slice_3441) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3449, %e1_3450 = cute.get_leaves(%iter_3448) : !cute.int_tuple<"(?,?{div=2})">
          %1372 = cute.get_scalars(%e0_3449) : !cute.int_tuple<"?">
          %1373 = cute.get_scalars(%e1_3450) : !cute.int_tuple<"?{div=2}">
          %coord_3451 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %slice_3452 = cute.slice(%ptn_C, %coord_3451) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,2)">
          %iter_3453 = cute.get_iter(%slice_3452) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3454, %e1_3455 = cute.get_leaves(%iter_3453) : !cute.int_tuple<"(?,?{div=2})">
          %1374 = cute.get_scalars(%e0_3454) : !cute.int_tuple<"?">
          %1375 = cute.get_scalars(%e1_3455) : !cute.int_tuple<"?{div=2}">
          %iter_3456 = cute.get_iter(%slice_3452) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3457, %e1_3458 = cute.get_leaves(%iter_3456) : !cute.int_tuple<"(?,?{div=2})">
          %1376 = cute.get_scalars(%e0_3457) : !cute.int_tuple<"?">
          %1377 = cute.get_scalars(%e1_3458) : !cute.int_tuple<"?{div=2}">
          %iter_3459 = cute.get_iter(%slice_3452) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3460, %e1_3461 = cute.get_leaves(%iter_3459) : !cute.int_tuple<"(?,?{div=2})">
          %1378 = cute.get_scalars(%e0_3460) : !cute.int_tuple<"?">
          %1379 = cute.get_scalars(%e1_3461) : !cute.int_tuple<"?{div=2}">
          %coord_3462 = cute.make_coord(%e0_3449) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3463 = cute.make_coord(%e1_3461) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1380 = cute.elem_less(%coord_3462, %coord_3463) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3464 = cute.get_layout(%1365) : !memref_rmem_f32_1
          %1381 = cute.get_shape(%lay_3464) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3465, %e1_3466, %e2_3467, %e3_3468 = cute.get_leaves(%1381) : !cute.shape<"((2,2),1,8)">
          %1382 = cute.get_stride(%lay_3464) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3469, %e1_3470, %e2_3471, %e3_3472 = cute.get_leaves(%1382) : !cute.stride<"((1,2),0,4)">
          %1383 = scf.if %1380 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1365) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
            cute.memref.store(%1365, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1365) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1365 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1365) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1365) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1365 : !memref_rmem_f32_1
          }
          %iter_3473 = cute.get_iter(%1383) : !memref_rmem_f32_1
          %lay_3474 = cute.get_layout(%1383) : !memref_rmem_f32_1
          %1384 = cute.get_shape(%lay_3474) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3475, %e1_3476, %e2_3477, %e3_3478 = cute.get_leaves(%1384) : !cute.shape<"((2,2),1,8)">
          %1385 = cute.get_stride(%lay_3474) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3479, %e1_3480, %e2_3481, %e3_3482 = cute.get_leaves(%1385) : !cute.stride<"((1,2),0,4)">
          %iter_3483 = cute.get_iter(%1383) : !memref_rmem_f32_1
          %iter_3484 = cute.get_iter(%1383) : !memref_rmem_f32_1
          %coord_3485 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %slice_3486 = cute.slice(%ptn_C, %coord_3485) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,3)">
          %iter_3487 = cute.get_iter(%slice_3486) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3488, %e1_3489 = cute.get_leaves(%iter_3487) : !cute.int_tuple<"(?,?{div=2})">
          %1386 = cute.get_scalars(%e0_3488) : !cute.int_tuple<"?">
          %1387 = cute.get_scalars(%e1_3489) : !cute.int_tuple<"?{div=2}">
          %iter_3490 = cute.get_iter(%slice_3486) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3491, %e1_3492 = cute.get_leaves(%iter_3490) : !cute.int_tuple<"(?,?{div=2})">
          %1388 = cute.get_scalars(%e0_3491) : !cute.int_tuple<"?">
          %1389 = cute.get_scalars(%e1_3492) : !cute.int_tuple<"?{div=2}">
          %iter_3493 = cute.get_iter(%slice_3486) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3494, %e1_3495 = cute.get_leaves(%iter_3493) : !cute.int_tuple<"(?,?{div=2})">
          %1390 = cute.get_scalars(%e0_3494) : !cute.int_tuple<"?">
          %1391 = cute.get_scalars(%e1_3495) : !cute.int_tuple<"?{div=2}">
          %coord_3496 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %slice_3497 = cute.slice(%ptn_C, %coord_3496) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,3)">
          %iter_3498 = cute.get_iter(%slice_3497) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3499, %e1_3500 = cute.get_leaves(%iter_3498) : !cute.int_tuple<"(?,?{div=2})">
          %1392 = cute.get_scalars(%e0_3499) : !cute.int_tuple<"?">
          %1393 = cute.get_scalars(%e1_3500) : !cute.int_tuple<"?{div=2}">
          %iter_3501 = cute.get_iter(%slice_3497) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3502, %e1_3503 = cute.get_leaves(%iter_3501) : !cute.int_tuple<"(?,?{div=2})">
          %1394 = cute.get_scalars(%e0_3502) : !cute.int_tuple<"?">
          %1395 = cute.get_scalars(%e1_3503) : !cute.int_tuple<"?{div=2}">
          %iter_3504 = cute.get_iter(%slice_3497) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3505, %e1_3506 = cute.get_leaves(%iter_3504) : !cute.int_tuple<"(?,?{div=2})">
          %1396 = cute.get_scalars(%e0_3505) : !cute.int_tuple<"?">
          %1397 = cute.get_scalars(%e1_3506) : !cute.int_tuple<"?{div=2}">
          %coord_3507 = cute.make_coord(%e0_3494) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3508 = cute.make_coord(%e1_3506) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1398 = cute.elem_less(%coord_3507, %coord_3508) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3509 = cute.get_layout(%1383) : !memref_rmem_f32_1
          %1399 = cute.get_shape(%lay_3509) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3510, %e1_3511, %e2_3512, %e3_3513 = cute.get_leaves(%1399) : !cute.shape<"((2,2),1,8)">
          %1400 = cute.get_stride(%lay_3509) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3514, %e1_3515, %e2_3516, %e3_3517 = cute.get_leaves(%1400) : !cute.stride<"((1,2),0,4)">
          %1401 = scf.if %1398 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1383) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
            cute.memref.store(%1383, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1383) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1383 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1383) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1383) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1383 : !memref_rmem_f32_1
          }
          %iter_3518 = cute.get_iter(%1401) : !memref_rmem_f32_1
          %lay_3519 = cute.get_layout(%1401) : !memref_rmem_f32_1
          %1402 = cute.get_shape(%lay_3519) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3520, %e1_3521, %e2_3522, %e3_3523 = cute.get_leaves(%1402) : !cute.shape<"((2,2),1,8)">
          %1403 = cute.get_stride(%lay_3519) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3524, %e1_3525, %e2_3526, %e3_3527 = cute.get_leaves(%1403) : !cute.stride<"((1,2),0,4)">
          %iter_3528 = cute.get_iter(%1401) : !memref_rmem_f32_1
          %iter_3529 = cute.get_iter(%1401) : !memref_rmem_f32_1
          %coord_3530 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %slice_3531 = cute.slice(%ptn_C, %coord_3530) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,4)">
          %iter_3532 = cute.get_iter(%slice_3531) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3533, %e1_3534 = cute.get_leaves(%iter_3532) : !cute.int_tuple<"(?,?{div=2})">
          %1404 = cute.get_scalars(%e0_3533) : !cute.int_tuple<"?">
          %1405 = cute.get_scalars(%e1_3534) : !cute.int_tuple<"?{div=2}">
          %iter_3535 = cute.get_iter(%slice_3531) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3536, %e1_3537 = cute.get_leaves(%iter_3535) : !cute.int_tuple<"(?,?{div=2})">
          %1406 = cute.get_scalars(%e0_3536) : !cute.int_tuple<"?">
          %1407 = cute.get_scalars(%e1_3537) : !cute.int_tuple<"?{div=2}">
          %iter_3538 = cute.get_iter(%slice_3531) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3539, %e1_3540 = cute.get_leaves(%iter_3538) : !cute.int_tuple<"(?,?{div=2})">
          %1408 = cute.get_scalars(%e0_3539) : !cute.int_tuple<"?">
          %1409 = cute.get_scalars(%e1_3540) : !cute.int_tuple<"?{div=2}">
          %coord_3541 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %slice_3542 = cute.slice(%ptn_C, %coord_3541) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,4)">
          %iter_3543 = cute.get_iter(%slice_3542) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3544, %e1_3545 = cute.get_leaves(%iter_3543) : !cute.int_tuple<"(?,?{div=2})">
          %1410 = cute.get_scalars(%e0_3544) : !cute.int_tuple<"?">
          %1411 = cute.get_scalars(%e1_3545) : !cute.int_tuple<"?{div=2}">
          %iter_3546 = cute.get_iter(%slice_3542) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3547, %e1_3548 = cute.get_leaves(%iter_3546) : !cute.int_tuple<"(?,?{div=2})">
          %1412 = cute.get_scalars(%e0_3547) : !cute.int_tuple<"?">
          %1413 = cute.get_scalars(%e1_3548) : !cute.int_tuple<"?{div=2}">
          %iter_3549 = cute.get_iter(%slice_3542) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3550, %e1_3551 = cute.get_leaves(%iter_3549) : !cute.int_tuple<"(?,?{div=2})">
          %1414 = cute.get_scalars(%e0_3550) : !cute.int_tuple<"?">
          %1415 = cute.get_scalars(%e1_3551) : !cute.int_tuple<"?{div=2}">
          %coord_3552 = cute.make_coord(%e0_3539) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3553 = cute.make_coord(%e1_3551) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1416 = cute.elem_less(%coord_3552, %coord_3553) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3554 = cute.get_layout(%1401) : !memref_rmem_f32_1
          %1417 = cute.get_shape(%lay_3554) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3555, %e1_3556, %e2_3557, %e3_3558 = cute.get_leaves(%1417) : !cute.shape<"((2,2),1,8)">
          %1418 = cute.get_stride(%lay_3554) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3559, %e1_3560, %e2_3561, %e3_3562 = cute.get_leaves(%1418) : !cute.stride<"((1,2),0,4)">
          %1419 = scf.if %1416 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1401) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
            cute.memref.store(%1401, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1401) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1401 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1401) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1401) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1401 : !memref_rmem_f32_1
          }
          %iter_3563 = cute.get_iter(%1419) : !memref_rmem_f32_1
          %lay_3564 = cute.get_layout(%1419) : !memref_rmem_f32_1
          %1420 = cute.get_shape(%lay_3564) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3565, %e1_3566, %e2_3567, %e3_3568 = cute.get_leaves(%1420) : !cute.shape<"((2,2),1,8)">
          %1421 = cute.get_stride(%lay_3564) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3569, %e1_3570, %e2_3571, %e3_3572 = cute.get_leaves(%1421) : !cute.stride<"((1,2),0,4)">
          %iter_3573 = cute.get_iter(%1419) : !memref_rmem_f32_1
          %iter_3574 = cute.get_iter(%1419) : !memref_rmem_f32_1
          %coord_3575 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %slice_3576 = cute.slice(%ptn_C, %coord_3575) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,5)">
          %iter_3577 = cute.get_iter(%slice_3576) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3578, %e1_3579 = cute.get_leaves(%iter_3577) : !cute.int_tuple<"(?,?{div=2})">
          %1422 = cute.get_scalars(%e0_3578) : !cute.int_tuple<"?">
          %1423 = cute.get_scalars(%e1_3579) : !cute.int_tuple<"?{div=2}">
          %iter_3580 = cute.get_iter(%slice_3576) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3581, %e1_3582 = cute.get_leaves(%iter_3580) : !cute.int_tuple<"(?,?{div=2})">
          %1424 = cute.get_scalars(%e0_3581) : !cute.int_tuple<"?">
          %1425 = cute.get_scalars(%e1_3582) : !cute.int_tuple<"?{div=2}">
          %iter_3583 = cute.get_iter(%slice_3576) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3584, %e1_3585 = cute.get_leaves(%iter_3583) : !cute.int_tuple<"(?,?{div=2})">
          %1426 = cute.get_scalars(%e0_3584) : !cute.int_tuple<"?">
          %1427 = cute.get_scalars(%e1_3585) : !cute.int_tuple<"?{div=2}">
          %coord_3586 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %slice_3587 = cute.slice(%ptn_C, %coord_3586) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,5)">
          %iter_3588 = cute.get_iter(%slice_3587) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3589, %e1_3590 = cute.get_leaves(%iter_3588) : !cute.int_tuple<"(?,?{div=2})">
          %1428 = cute.get_scalars(%e0_3589) : !cute.int_tuple<"?">
          %1429 = cute.get_scalars(%e1_3590) : !cute.int_tuple<"?{div=2}">
          %iter_3591 = cute.get_iter(%slice_3587) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3592, %e1_3593 = cute.get_leaves(%iter_3591) : !cute.int_tuple<"(?,?{div=2})">
          %1430 = cute.get_scalars(%e0_3592) : !cute.int_tuple<"?">
          %1431 = cute.get_scalars(%e1_3593) : !cute.int_tuple<"?{div=2}">
          %iter_3594 = cute.get_iter(%slice_3587) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3595, %e1_3596 = cute.get_leaves(%iter_3594) : !cute.int_tuple<"(?,?{div=2})">
          %1432 = cute.get_scalars(%e0_3595) : !cute.int_tuple<"?">
          %1433 = cute.get_scalars(%e1_3596) : !cute.int_tuple<"?{div=2}">
          %coord_3597 = cute.make_coord(%e0_3584) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3598 = cute.make_coord(%e1_3596) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1434 = cute.elem_less(%coord_3597, %coord_3598) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3599 = cute.get_layout(%1419) : !memref_rmem_f32_1
          %1435 = cute.get_shape(%lay_3599) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3600, %e1_3601, %e2_3602, %e3_3603 = cute.get_leaves(%1435) : !cute.shape<"((2,2),1,8)">
          %1436 = cute.get_stride(%lay_3599) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3604, %e1_3605, %e2_3606, %e3_3607 = cute.get_leaves(%1436) : !cute.stride<"((1,2),0,4)">
          %1437 = scf.if %1434 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1419) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
            cute.memref.store(%1419, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1419) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1419 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1419) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1419) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1419 : !memref_rmem_f32_1
          }
          %iter_3608 = cute.get_iter(%1437) : !memref_rmem_f32_1
          %lay_3609 = cute.get_layout(%1437) : !memref_rmem_f32_1
          %1438 = cute.get_shape(%lay_3609) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3610, %e1_3611, %e2_3612, %e3_3613 = cute.get_leaves(%1438) : !cute.shape<"((2,2),1,8)">
          %1439 = cute.get_stride(%lay_3609) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3614, %e1_3615, %e2_3616, %e3_3617 = cute.get_leaves(%1439) : !cute.stride<"((1,2),0,4)">
          %iter_3618 = cute.get_iter(%1437) : !memref_rmem_f32_1
          %iter_3619 = cute.get_iter(%1437) : !memref_rmem_f32_1
          %coord_3620 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %slice_3621 = cute.slice(%ptn_C, %coord_3620) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,6)">
          %iter_3622 = cute.get_iter(%slice_3621) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3623, %e1_3624 = cute.get_leaves(%iter_3622) : !cute.int_tuple<"(?,?{div=2})">
          %1440 = cute.get_scalars(%e0_3623) : !cute.int_tuple<"?">
          %1441 = cute.get_scalars(%e1_3624) : !cute.int_tuple<"?{div=2}">
          %iter_3625 = cute.get_iter(%slice_3621) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3626, %e1_3627 = cute.get_leaves(%iter_3625) : !cute.int_tuple<"(?,?{div=2})">
          %1442 = cute.get_scalars(%e0_3626) : !cute.int_tuple<"?">
          %1443 = cute.get_scalars(%e1_3627) : !cute.int_tuple<"?{div=2}">
          %iter_3628 = cute.get_iter(%slice_3621) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3629, %e1_3630 = cute.get_leaves(%iter_3628) : !cute.int_tuple<"(?,?{div=2})">
          %1444 = cute.get_scalars(%e0_3629) : !cute.int_tuple<"?">
          %1445 = cute.get_scalars(%e1_3630) : !cute.int_tuple<"?{div=2}">
          %coord_3631 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %slice_3632 = cute.slice(%ptn_C, %coord_3631) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,6)">
          %iter_3633 = cute.get_iter(%slice_3632) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3634, %e1_3635 = cute.get_leaves(%iter_3633) : !cute.int_tuple<"(?,?{div=2})">
          %1446 = cute.get_scalars(%e0_3634) : !cute.int_tuple<"?">
          %1447 = cute.get_scalars(%e1_3635) : !cute.int_tuple<"?{div=2}">
          %iter_3636 = cute.get_iter(%slice_3632) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3637, %e1_3638 = cute.get_leaves(%iter_3636) : !cute.int_tuple<"(?,?{div=2})">
          %1448 = cute.get_scalars(%e0_3637) : !cute.int_tuple<"?">
          %1449 = cute.get_scalars(%e1_3638) : !cute.int_tuple<"?{div=2}">
          %iter_3639 = cute.get_iter(%slice_3632) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3640, %e1_3641 = cute.get_leaves(%iter_3639) : !cute.int_tuple<"(?,?{div=2})">
          %1450 = cute.get_scalars(%e0_3640) : !cute.int_tuple<"?">
          %1451 = cute.get_scalars(%e1_3641) : !cute.int_tuple<"?{div=2}">
          %coord_3642 = cute.make_coord(%e0_3629) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3643 = cute.make_coord(%e1_3641) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1452 = cute.elem_less(%coord_3642, %coord_3643) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3644 = cute.get_layout(%1437) : !memref_rmem_f32_1
          %1453 = cute.get_shape(%lay_3644) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3645, %e1_3646, %e2_3647, %e3_3648 = cute.get_leaves(%1453) : !cute.shape<"((2,2),1,8)">
          %1454 = cute.get_stride(%lay_3644) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3649, %e1_3650, %e2_3651, %e3_3652 = cute.get_leaves(%1454) : !cute.stride<"((1,2),0,4)">
          %1455 = scf.if %1452 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1437) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
            cute.memref.store(%1437, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1437) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1437 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1437) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1437) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1437 : !memref_rmem_f32_1
          }
          %iter_3653 = cute.get_iter(%1455) : !memref_rmem_f32_1
          %lay_3654 = cute.get_layout(%1455) : !memref_rmem_f32_1
          %1456 = cute.get_shape(%lay_3654) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3655, %e1_3656, %e2_3657, %e3_3658 = cute.get_leaves(%1456) : !cute.shape<"((2,2),1,8)">
          %1457 = cute.get_stride(%lay_3654) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3659, %e1_3660, %e2_3661, %e3_3662 = cute.get_leaves(%1457) : !cute.stride<"((1,2),0,4)">
          %iter_3663 = cute.get_iter(%1455) : !memref_rmem_f32_1
          %iter_3664 = cute.get_iter(%1455) : !memref_rmem_f32_1
          %coord_3665 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %slice_3666 = cute.slice(%ptn_C, %coord_3665) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,7)">
          %iter_3667 = cute.get_iter(%slice_3666) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3668, %e1_3669 = cute.get_leaves(%iter_3667) : !cute.int_tuple<"(?,?{div=2})">
          %1458 = cute.get_scalars(%e0_3668) : !cute.int_tuple<"?">
          %1459 = cute.get_scalars(%e1_3669) : !cute.int_tuple<"?{div=2}">
          %iter_3670 = cute.get_iter(%slice_3666) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3671, %e1_3672 = cute.get_leaves(%iter_3670) : !cute.int_tuple<"(?,?{div=2})">
          %1460 = cute.get_scalars(%e0_3671) : !cute.int_tuple<"?">
          %1461 = cute.get_scalars(%e1_3672) : !cute.int_tuple<"?{div=2}">
          %iter_3673 = cute.get_iter(%slice_3666) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3674, %e1_3675 = cute.get_leaves(%iter_3673) : !cute.int_tuple<"(?,?{div=2})">
          %1462 = cute.get_scalars(%e0_3674) : !cute.int_tuple<"?">
          %1463 = cute.get_scalars(%e1_3675) : !cute.int_tuple<"?{div=2}">
          %coord_3676 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %slice_3677 = cute.slice(%ptn_C, %coord_3676) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,7)">
          %iter_3678 = cute.get_iter(%slice_3677) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3679, %e1_3680 = cute.get_leaves(%iter_3678) : !cute.int_tuple<"(?,?{div=2})">
          %1464 = cute.get_scalars(%e0_3679) : !cute.int_tuple<"?">
          %1465 = cute.get_scalars(%e1_3680) : !cute.int_tuple<"?{div=2}">
          %iter_3681 = cute.get_iter(%slice_3677) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3682, %e1_3683 = cute.get_leaves(%iter_3681) : !cute.int_tuple<"(?,?{div=2})">
          %1466 = cute.get_scalars(%e0_3682) : !cute.int_tuple<"?">
          %1467 = cute.get_scalars(%e1_3683) : !cute.int_tuple<"?{div=2}">
          %iter_3684 = cute.get_iter(%slice_3677) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3685, %e1_3686 = cute.get_leaves(%iter_3684) : !cute.int_tuple<"(?,?{div=2})">
          %1468 = cute.get_scalars(%e0_3685) : !cute.int_tuple<"?">
          %1469 = cute.get_scalars(%e1_3686) : !cute.int_tuple<"?{div=2}">
          %coord_3687 = cute.make_coord(%e0_3674) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3688 = cute.make_coord(%e1_3686) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1470 = cute.elem_less(%coord_3687, %coord_3688) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3689 = cute.get_layout(%1455) : !memref_rmem_f32_1
          %1471 = cute.get_shape(%lay_3689) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3690, %e1_3691, %e2_3692, %e3_3693 = cute.get_leaves(%1471) : !cute.shape<"((2,2),1,8)">
          %1472 = cute.get_stride(%lay_3689) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3694, %e1_3695, %e2_3696, %e3_3697 = cute.get_leaves(%1472) : !cute.stride<"((1,2),0,4)">
          %1473 = scf.if %1470 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1455) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
            cute.memref.store(%1455, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1455) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1455 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1455) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1455) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1455 : !memref_rmem_f32_1
          }
          %iter_3698 = cute.get_iter(%1473) : !memref_rmem_f32_1
          %lay_3699 = cute.get_layout(%1473) : !memref_rmem_f32_1
          %1474 = cute.get_shape(%lay_3699) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3700, %e1_3701, %e2_3702, %e3_3703 = cute.get_leaves(%1474) : !cute.shape<"((2,2),1,8)">
          %1475 = cute.get_stride(%lay_3699) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3704, %e1_3705, %e2_3706, %e3_3707 = cute.get_leaves(%1475) : !cute.stride<"((1,2),0,4)">
          %iter_3708 = cute.get_iter(%1473) : !memref_rmem_f32_1
          %iter_3709 = cute.get_iter(%1473) : !memref_rmem_f32_1
          %int_tuple_3710 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_3711 = cute.size(%int_tuple_3710) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_3712 = cute.get_leaves(%sz_3711) : !cute.int_tuple<"1">
          %int_tuple_3713 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_3714 = cute.size(%int_tuple_3713) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_3715 = cute.get_leaves(%sz_3714) : !cute.int_tuple<"8">
          %coord_3716 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %slice_3717 = cute.slice(%ptn_C, %coord_3716) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,0)">
          %iter_3718 = cute.get_iter(%slice_3717) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3719, %e1_3720 = cute.get_leaves(%iter_3718) : !cute.int_tuple<"(?,?)">
          %1476 = cute.get_scalars(%e0_3719) : !cute.int_tuple<"?">
          %1477 = cute.get_scalars(%e1_3720) : !cute.int_tuple<"?">
          %iter_3721 = cute.get_iter(%slice_3717) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3722, %e1_3723 = cute.get_leaves(%iter_3721) : !cute.int_tuple<"(?,?)">
          %1478 = cute.get_scalars(%e0_3722) : !cute.int_tuple<"?">
          %1479 = cute.get_scalars(%e1_3723) : !cute.int_tuple<"?">
          %iter_3724 = cute.get_iter(%slice_3717) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3725, %e1_3726 = cute.get_leaves(%iter_3724) : !cute.int_tuple<"(?,?)">
          %1480 = cute.get_scalars(%e0_3725) : !cute.int_tuple<"?">
          %1481 = cute.get_scalars(%e1_3726) : !cute.int_tuple<"?">
          %coord_3727 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %slice_3728 = cute.slice(%ptn_C, %coord_3727) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,0)">
          %iter_3729 = cute.get_iter(%slice_3728) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3730, %e1_3731 = cute.get_leaves(%iter_3729) : !cute.int_tuple<"(?,?)">
          %1482 = cute.get_scalars(%e0_3730) : !cute.int_tuple<"?">
          %1483 = cute.get_scalars(%e1_3731) : !cute.int_tuple<"?">
          %iter_3732 = cute.get_iter(%slice_3728) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3733, %e1_3734 = cute.get_leaves(%iter_3732) : !cute.int_tuple<"(?,?)">
          %1484 = cute.get_scalars(%e0_3733) : !cute.int_tuple<"?">
          %1485 = cute.get_scalars(%e1_3734) : !cute.int_tuple<"?">
          %iter_3735 = cute.get_iter(%slice_3728) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3736, %e1_3737 = cute.get_leaves(%iter_3735) : !cute.int_tuple<"(?,?)">
          %1486 = cute.get_scalars(%e0_3736) : !cute.int_tuple<"?">
          %1487 = cute.get_scalars(%e1_3737) : !cute.int_tuple<"?">
          %coord_3738 = cute.make_coord(%e0_3725) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3739 = cute.make_coord(%e1_3737) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1488 = cute.elem_less(%coord_3738, %coord_3739) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3740 = cute.get_layout(%1473) : !memref_rmem_f32_1
          %1489 = cute.get_shape(%lay_3740) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3741, %e1_3742, %e2_3743, %e3_3744 = cute.get_leaves(%1489) : !cute.shape<"((2,2),1,8)">
          %1490 = cute.get_stride(%lay_3740) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3745, %e1_3746, %e2_3747, %e3_3748 = cute.get_leaves(%1490) : !cute.stride<"((1,2),0,4)">
          %1491 = scf.if %1488 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1473) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
            cute.memref.store(%1473, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1473) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1473 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1473) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1473) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1473 : !memref_rmem_f32_1
          }
          %iter_3749 = cute.get_iter(%1491) : !memref_rmem_f32_1
          %lay_3750 = cute.get_layout(%1491) : !memref_rmem_f32_1
          %1492 = cute.get_shape(%lay_3750) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3751, %e1_3752, %e2_3753, %e3_3754 = cute.get_leaves(%1492) : !cute.shape<"((2,2),1,8)">
          %1493 = cute.get_stride(%lay_3750) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3755, %e1_3756, %e2_3757, %e3_3758 = cute.get_leaves(%1493) : !cute.stride<"((1,2),0,4)">
          %iter_3759 = cute.get_iter(%1491) : !memref_rmem_f32_1
          %iter_3760 = cute.get_iter(%1491) : !memref_rmem_f32_1
          %coord_3761 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %slice_3762 = cute.slice(%ptn_C, %coord_3761) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,1)">
          %iter_3763 = cute.get_iter(%slice_3762) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3764, %e1_3765 = cute.get_leaves(%iter_3763) : !cute.int_tuple<"(?,?)">
          %1494 = cute.get_scalars(%e0_3764) : !cute.int_tuple<"?">
          %1495 = cute.get_scalars(%e1_3765) : !cute.int_tuple<"?">
          %iter_3766 = cute.get_iter(%slice_3762) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3767, %e1_3768 = cute.get_leaves(%iter_3766) : !cute.int_tuple<"(?,?)">
          %1496 = cute.get_scalars(%e0_3767) : !cute.int_tuple<"?">
          %1497 = cute.get_scalars(%e1_3768) : !cute.int_tuple<"?">
          %iter_3769 = cute.get_iter(%slice_3762) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3770, %e1_3771 = cute.get_leaves(%iter_3769) : !cute.int_tuple<"(?,?)">
          %1498 = cute.get_scalars(%e0_3770) : !cute.int_tuple<"?">
          %1499 = cute.get_scalars(%e1_3771) : !cute.int_tuple<"?">
          %coord_3772 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %slice_3773 = cute.slice(%ptn_C, %coord_3772) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,1)">
          %iter_3774 = cute.get_iter(%slice_3773) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3775, %e1_3776 = cute.get_leaves(%iter_3774) : !cute.int_tuple<"(?,?)">
          %1500 = cute.get_scalars(%e0_3775) : !cute.int_tuple<"?">
          %1501 = cute.get_scalars(%e1_3776) : !cute.int_tuple<"?">
          %iter_3777 = cute.get_iter(%slice_3773) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3778, %e1_3779 = cute.get_leaves(%iter_3777) : !cute.int_tuple<"(?,?)">
          %1502 = cute.get_scalars(%e0_3778) : !cute.int_tuple<"?">
          %1503 = cute.get_scalars(%e1_3779) : !cute.int_tuple<"?">
          %iter_3780 = cute.get_iter(%slice_3773) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3781, %e1_3782 = cute.get_leaves(%iter_3780) : !cute.int_tuple<"(?,?)">
          %1504 = cute.get_scalars(%e0_3781) : !cute.int_tuple<"?">
          %1505 = cute.get_scalars(%e1_3782) : !cute.int_tuple<"?">
          %coord_3783 = cute.make_coord(%e0_3770) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3784 = cute.make_coord(%e1_3782) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1506 = cute.elem_less(%coord_3783, %coord_3784) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3785 = cute.get_layout(%1491) : !memref_rmem_f32_1
          %1507 = cute.get_shape(%lay_3785) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3786, %e1_3787, %e2_3788, %e3_3789 = cute.get_leaves(%1507) : !cute.shape<"((2,2),1,8)">
          %1508 = cute.get_stride(%lay_3785) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3790, %e1_3791, %e2_3792, %e3_3793 = cute.get_leaves(%1508) : !cute.stride<"((1,2),0,4)">
          %1509 = scf.if %1506 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1491) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
            cute.memref.store(%1491, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1491) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1491 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1491) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1491) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1491 : !memref_rmem_f32_1
          }
          %iter_3794 = cute.get_iter(%1509) : !memref_rmem_f32_1
          %lay_3795 = cute.get_layout(%1509) : !memref_rmem_f32_1
          %1510 = cute.get_shape(%lay_3795) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3796, %e1_3797, %e2_3798, %e3_3799 = cute.get_leaves(%1510) : !cute.shape<"((2,2),1,8)">
          %1511 = cute.get_stride(%lay_3795) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3800, %e1_3801, %e2_3802, %e3_3803 = cute.get_leaves(%1511) : !cute.stride<"((1,2),0,4)">
          %iter_3804 = cute.get_iter(%1509) : !memref_rmem_f32_1
          %iter_3805 = cute.get_iter(%1509) : !memref_rmem_f32_1
          %coord_3806 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %slice_3807 = cute.slice(%ptn_C, %coord_3806) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,2)">
          %iter_3808 = cute.get_iter(%slice_3807) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3809, %e1_3810 = cute.get_leaves(%iter_3808) : !cute.int_tuple<"(?,?)">
          %1512 = cute.get_scalars(%e0_3809) : !cute.int_tuple<"?">
          %1513 = cute.get_scalars(%e1_3810) : !cute.int_tuple<"?">
          %iter_3811 = cute.get_iter(%slice_3807) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3812, %e1_3813 = cute.get_leaves(%iter_3811) : !cute.int_tuple<"(?,?)">
          %1514 = cute.get_scalars(%e0_3812) : !cute.int_tuple<"?">
          %1515 = cute.get_scalars(%e1_3813) : !cute.int_tuple<"?">
          %iter_3814 = cute.get_iter(%slice_3807) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3815, %e1_3816 = cute.get_leaves(%iter_3814) : !cute.int_tuple<"(?,?)">
          %1516 = cute.get_scalars(%e0_3815) : !cute.int_tuple<"?">
          %1517 = cute.get_scalars(%e1_3816) : !cute.int_tuple<"?">
          %coord_3817 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %slice_3818 = cute.slice(%ptn_C, %coord_3817) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,2)">
          %iter_3819 = cute.get_iter(%slice_3818) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3820, %e1_3821 = cute.get_leaves(%iter_3819) : !cute.int_tuple<"(?,?)">
          %1518 = cute.get_scalars(%e0_3820) : !cute.int_tuple<"?">
          %1519 = cute.get_scalars(%e1_3821) : !cute.int_tuple<"?">
          %iter_3822 = cute.get_iter(%slice_3818) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3823, %e1_3824 = cute.get_leaves(%iter_3822) : !cute.int_tuple<"(?,?)">
          %1520 = cute.get_scalars(%e0_3823) : !cute.int_tuple<"?">
          %1521 = cute.get_scalars(%e1_3824) : !cute.int_tuple<"?">
          %iter_3825 = cute.get_iter(%slice_3818) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3826, %e1_3827 = cute.get_leaves(%iter_3825) : !cute.int_tuple<"(?,?)">
          %1522 = cute.get_scalars(%e0_3826) : !cute.int_tuple<"?">
          %1523 = cute.get_scalars(%e1_3827) : !cute.int_tuple<"?">
          %coord_3828 = cute.make_coord(%e0_3815) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3829 = cute.make_coord(%e1_3827) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1524 = cute.elem_less(%coord_3828, %coord_3829) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3830 = cute.get_layout(%1509) : !memref_rmem_f32_1
          %1525 = cute.get_shape(%lay_3830) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3831, %e1_3832, %e2_3833, %e3_3834 = cute.get_leaves(%1525) : !cute.shape<"((2,2),1,8)">
          %1526 = cute.get_stride(%lay_3830) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3835, %e1_3836, %e2_3837, %e3_3838 = cute.get_leaves(%1526) : !cute.stride<"((1,2),0,4)">
          %1527 = scf.if %1524 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1509) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
            cute.memref.store(%1509, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1509) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1509 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1509) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1509) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1509 : !memref_rmem_f32_1
          }
          %iter_3839 = cute.get_iter(%1527) : !memref_rmem_f32_1
          %lay_3840 = cute.get_layout(%1527) : !memref_rmem_f32_1
          %1528 = cute.get_shape(%lay_3840) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3841, %e1_3842, %e2_3843, %e3_3844 = cute.get_leaves(%1528) : !cute.shape<"((2,2),1,8)">
          %1529 = cute.get_stride(%lay_3840) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3845, %e1_3846, %e2_3847, %e3_3848 = cute.get_leaves(%1529) : !cute.stride<"((1,2),0,4)">
          %iter_3849 = cute.get_iter(%1527) : !memref_rmem_f32_1
          %iter_3850 = cute.get_iter(%1527) : !memref_rmem_f32_1
          %coord_3851 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %slice_3852 = cute.slice(%ptn_C, %coord_3851) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,3)">
          %iter_3853 = cute.get_iter(%slice_3852) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3854, %e1_3855 = cute.get_leaves(%iter_3853) : !cute.int_tuple<"(?,?)">
          %1530 = cute.get_scalars(%e0_3854) : !cute.int_tuple<"?">
          %1531 = cute.get_scalars(%e1_3855) : !cute.int_tuple<"?">
          %iter_3856 = cute.get_iter(%slice_3852) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3857, %e1_3858 = cute.get_leaves(%iter_3856) : !cute.int_tuple<"(?,?)">
          %1532 = cute.get_scalars(%e0_3857) : !cute.int_tuple<"?">
          %1533 = cute.get_scalars(%e1_3858) : !cute.int_tuple<"?">
          %iter_3859 = cute.get_iter(%slice_3852) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3860, %e1_3861 = cute.get_leaves(%iter_3859) : !cute.int_tuple<"(?,?)">
          %1534 = cute.get_scalars(%e0_3860) : !cute.int_tuple<"?">
          %1535 = cute.get_scalars(%e1_3861) : !cute.int_tuple<"?">
          %coord_3862 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %slice_3863 = cute.slice(%ptn_C, %coord_3862) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,3)">
          %iter_3864 = cute.get_iter(%slice_3863) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3865, %e1_3866 = cute.get_leaves(%iter_3864) : !cute.int_tuple<"(?,?)">
          %1536 = cute.get_scalars(%e0_3865) : !cute.int_tuple<"?">
          %1537 = cute.get_scalars(%e1_3866) : !cute.int_tuple<"?">
          %iter_3867 = cute.get_iter(%slice_3863) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3868, %e1_3869 = cute.get_leaves(%iter_3867) : !cute.int_tuple<"(?,?)">
          %1538 = cute.get_scalars(%e0_3868) : !cute.int_tuple<"?">
          %1539 = cute.get_scalars(%e1_3869) : !cute.int_tuple<"?">
          %iter_3870 = cute.get_iter(%slice_3863) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3871, %e1_3872 = cute.get_leaves(%iter_3870) : !cute.int_tuple<"(?,?)">
          %1540 = cute.get_scalars(%e0_3871) : !cute.int_tuple<"?">
          %1541 = cute.get_scalars(%e1_3872) : !cute.int_tuple<"?">
          %coord_3873 = cute.make_coord(%e0_3860) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3874 = cute.make_coord(%e1_3872) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1542 = cute.elem_less(%coord_3873, %coord_3874) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3875 = cute.get_layout(%1527) : !memref_rmem_f32_1
          %1543 = cute.get_shape(%lay_3875) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3876, %e1_3877, %e2_3878, %e3_3879 = cute.get_leaves(%1543) : !cute.shape<"((2,2),1,8)">
          %1544 = cute.get_stride(%lay_3875) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3880, %e1_3881, %e2_3882, %e3_3883 = cute.get_leaves(%1544) : !cute.stride<"((1,2),0,4)">
          %1545 = scf.if %1542 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1527) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
            cute.memref.store(%1527, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1527) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1527 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1527) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1527) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1527 : !memref_rmem_f32_1
          }
          %iter_3884 = cute.get_iter(%1545) : !memref_rmem_f32_1
          %lay_3885 = cute.get_layout(%1545) : !memref_rmem_f32_1
          %1546 = cute.get_shape(%lay_3885) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3886, %e1_3887, %e2_3888, %e3_3889 = cute.get_leaves(%1546) : !cute.shape<"((2,2),1,8)">
          %1547 = cute.get_stride(%lay_3885) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3890, %e1_3891, %e2_3892, %e3_3893 = cute.get_leaves(%1547) : !cute.stride<"((1,2),0,4)">
          %iter_3894 = cute.get_iter(%1545) : !memref_rmem_f32_1
          %iter_3895 = cute.get_iter(%1545) : !memref_rmem_f32_1
          %coord_3896 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %slice_3897 = cute.slice(%ptn_C, %coord_3896) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,4)">
          %iter_3898 = cute.get_iter(%slice_3897) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3899, %e1_3900 = cute.get_leaves(%iter_3898) : !cute.int_tuple<"(?,?)">
          %1548 = cute.get_scalars(%e0_3899) : !cute.int_tuple<"?">
          %1549 = cute.get_scalars(%e1_3900) : !cute.int_tuple<"?">
          %iter_3901 = cute.get_iter(%slice_3897) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3902, %e1_3903 = cute.get_leaves(%iter_3901) : !cute.int_tuple<"(?,?)">
          %1550 = cute.get_scalars(%e0_3902) : !cute.int_tuple<"?">
          %1551 = cute.get_scalars(%e1_3903) : !cute.int_tuple<"?">
          %iter_3904 = cute.get_iter(%slice_3897) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3905, %e1_3906 = cute.get_leaves(%iter_3904) : !cute.int_tuple<"(?,?)">
          %1552 = cute.get_scalars(%e0_3905) : !cute.int_tuple<"?">
          %1553 = cute.get_scalars(%e1_3906) : !cute.int_tuple<"?">
          %coord_3907 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %slice_3908 = cute.slice(%ptn_C, %coord_3907) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,4)">
          %iter_3909 = cute.get_iter(%slice_3908) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3910, %e1_3911 = cute.get_leaves(%iter_3909) : !cute.int_tuple<"(?,?)">
          %1554 = cute.get_scalars(%e0_3910) : !cute.int_tuple<"?">
          %1555 = cute.get_scalars(%e1_3911) : !cute.int_tuple<"?">
          %iter_3912 = cute.get_iter(%slice_3908) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3913, %e1_3914 = cute.get_leaves(%iter_3912) : !cute.int_tuple<"(?,?)">
          %1556 = cute.get_scalars(%e0_3913) : !cute.int_tuple<"?">
          %1557 = cute.get_scalars(%e1_3914) : !cute.int_tuple<"?">
          %iter_3915 = cute.get_iter(%slice_3908) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3916, %e1_3917 = cute.get_leaves(%iter_3915) : !cute.int_tuple<"(?,?)">
          %1558 = cute.get_scalars(%e0_3916) : !cute.int_tuple<"?">
          %1559 = cute.get_scalars(%e1_3917) : !cute.int_tuple<"?">
          %coord_3918 = cute.make_coord(%e0_3905) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3919 = cute.make_coord(%e1_3917) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1560 = cute.elem_less(%coord_3918, %coord_3919) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3920 = cute.get_layout(%1545) : !memref_rmem_f32_1
          %1561 = cute.get_shape(%lay_3920) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3921, %e1_3922, %e2_3923, %e3_3924 = cute.get_leaves(%1561) : !cute.shape<"((2,2),1,8)">
          %1562 = cute.get_stride(%lay_3920) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3925, %e1_3926, %e2_3927, %e3_3928 = cute.get_leaves(%1562) : !cute.stride<"((1,2),0,4)">
          %1563 = scf.if %1560 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1545) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
            cute.memref.store(%1545, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1545) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1545 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1545) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1545) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1545 : !memref_rmem_f32_1
          }
          %iter_3929 = cute.get_iter(%1563) : !memref_rmem_f32_1
          %lay_3930 = cute.get_layout(%1563) : !memref_rmem_f32_1
          %1564 = cute.get_shape(%lay_3930) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3931, %e1_3932, %e2_3933, %e3_3934 = cute.get_leaves(%1564) : !cute.shape<"((2,2),1,8)">
          %1565 = cute.get_stride(%lay_3930) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3935, %e1_3936, %e2_3937, %e3_3938 = cute.get_leaves(%1565) : !cute.stride<"((1,2),0,4)">
          %iter_3939 = cute.get_iter(%1563) : !memref_rmem_f32_1
          %iter_3940 = cute.get_iter(%1563) : !memref_rmem_f32_1
          %coord_3941 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %slice_3942 = cute.slice(%ptn_C, %coord_3941) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,5)">
          %iter_3943 = cute.get_iter(%slice_3942) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3944, %e1_3945 = cute.get_leaves(%iter_3943) : !cute.int_tuple<"(?,?)">
          %1566 = cute.get_scalars(%e0_3944) : !cute.int_tuple<"?">
          %1567 = cute.get_scalars(%e1_3945) : !cute.int_tuple<"?">
          %iter_3946 = cute.get_iter(%slice_3942) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3947, %e1_3948 = cute.get_leaves(%iter_3946) : !cute.int_tuple<"(?,?)">
          %1568 = cute.get_scalars(%e0_3947) : !cute.int_tuple<"?">
          %1569 = cute.get_scalars(%e1_3948) : !cute.int_tuple<"?">
          %iter_3949 = cute.get_iter(%slice_3942) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3950, %e1_3951 = cute.get_leaves(%iter_3949) : !cute.int_tuple<"(?,?)">
          %1570 = cute.get_scalars(%e0_3950) : !cute.int_tuple<"?">
          %1571 = cute.get_scalars(%e1_3951) : !cute.int_tuple<"?">
          %coord_3952 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %slice_3953 = cute.slice(%ptn_C, %coord_3952) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,5)">
          %iter_3954 = cute.get_iter(%slice_3953) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3955, %e1_3956 = cute.get_leaves(%iter_3954) : !cute.int_tuple<"(?,?)">
          %1572 = cute.get_scalars(%e0_3955) : !cute.int_tuple<"?">
          %1573 = cute.get_scalars(%e1_3956) : !cute.int_tuple<"?">
          %iter_3957 = cute.get_iter(%slice_3953) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3958, %e1_3959 = cute.get_leaves(%iter_3957) : !cute.int_tuple<"(?,?)">
          %1574 = cute.get_scalars(%e0_3958) : !cute.int_tuple<"?">
          %1575 = cute.get_scalars(%e1_3959) : !cute.int_tuple<"?">
          %iter_3960 = cute.get_iter(%slice_3953) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3961, %e1_3962 = cute.get_leaves(%iter_3960) : !cute.int_tuple<"(?,?)">
          %1576 = cute.get_scalars(%e0_3961) : !cute.int_tuple<"?">
          %1577 = cute.get_scalars(%e1_3962) : !cute.int_tuple<"?">
          %coord_3963 = cute.make_coord(%e0_3950) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3964 = cute.make_coord(%e1_3962) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1578 = cute.elem_less(%coord_3963, %coord_3964) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3965 = cute.get_layout(%1563) : !memref_rmem_f32_1
          %1579 = cute.get_shape(%lay_3965) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3966, %e1_3967, %e2_3968, %e3_3969 = cute.get_leaves(%1579) : !cute.shape<"((2,2),1,8)">
          %1580 = cute.get_stride(%lay_3965) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3970, %e1_3971, %e2_3972, %e3_3973 = cute.get_leaves(%1580) : !cute.stride<"((1,2),0,4)">
          %1581 = scf.if %1578 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1563) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
            cute.memref.store(%1563, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1563) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1563 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1563) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1563) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1563 : !memref_rmem_f32_1
          }
          %iter_3974 = cute.get_iter(%1581) : !memref_rmem_f32_1
          %lay_3975 = cute.get_layout(%1581) : !memref_rmem_f32_1
          %1582 = cute.get_shape(%lay_3975) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3976, %e1_3977, %e2_3978, %e3_3979 = cute.get_leaves(%1582) : !cute.shape<"((2,2),1,8)">
          %1583 = cute.get_stride(%lay_3975) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3980, %e1_3981, %e2_3982, %e3_3983 = cute.get_leaves(%1583) : !cute.stride<"((1,2),0,4)">
          %iter_3984 = cute.get_iter(%1581) : !memref_rmem_f32_1
          %iter_3985 = cute.get_iter(%1581) : !memref_rmem_f32_1
          %coord_3986 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %slice_3987 = cute.slice(%ptn_C, %coord_3986) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,6)">
          %iter_3988 = cute.get_iter(%slice_3987) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3989, %e1_3990 = cute.get_leaves(%iter_3988) : !cute.int_tuple<"(?,?)">
          %1584 = cute.get_scalars(%e0_3989) : !cute.int_tuple<"?">
          %1585 = cute.get_scalars(%e1_3990) : !cute.int_tuple<"?">
          %iter_3991 = cute.get_iter(%slice_3987) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3992, %e1_3993 = cute.get_leaves(%iter_3991) : !cute.int_tuple<"(?,?)">
          %1586 = cute.get_scalars(%e0_3992) : !cute.int_tuple<"?">
          %1587 = cute.get_scalars(%e1_3993) : !cute.int_tuple<"?">
          %iter_3994 = cute.get_iter(%slice_3987) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3995, %e1_3996 = cute.get_leaves(%iter_3994) : !cute.int_tuple<"(?,?)">
          %1588 = cute.get_scalars(%e0_3995) : !cute.int_tuple<"?">
          %1589 = cute.get_scalars(%e1_3996) : !cute.int_tuple<"?">
          %coord_3997 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %slice_3998 = cute.slice(%ptn_C, %coord_3997) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,6)">
          %iter_3999 = cute.get_iter(%slice_3998) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4000, %e1_4001 = cute.get_leaves(%iter_3999) : !cute.int_tuple<"(?,?)">
          %1590 = cute.get_scalars(%e0_4000) : !cute.int_tuple<"?">
          %1591 = cute.get_scalars(%e1_4001) : !cute.int_tuple<"?">
          %iter_4002 = cute.get_iter(%slice_3998) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4003, %e1_4004 = cute.get_leaves(%iter_4002) : !cute.int_tuple<"(?,?)">
          %1592 = cute.get_scalars(%e0_4003) : !cute.int_tuple<"?">
          %1593 = cute.get_scalars(%e1_4004) : !cute.int_tuple<"?">
          %iter_4005 = cute.get_iter(%slice_3998) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4006, %e1_4007 = cute.get_leaves(%iter_4005) : !cute.int_tuple<"(?,?)">
          %1594 = cute.get_scalars(%e0_4006) : !cute.int_tuple<"?">
          %1595 = cute.get_scalars(%e1_4007) : !cute.int_tuple<"?">
          %coord_4008 = cute.make_coord(%e0_3995) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_4009 = cute.make_coord(%e1_4007) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1596 = cute.elem_less(%coord_4008, %coord_4009) : !cute.coord<"?">, !cute.coord<"?">
          %lay_4010 = cute.get_layout(%1581) : !memref_rmem_f32_1
          %1597 = cute.get_shape(%lay_4010) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4011, %e1_4012, %e2_4013, %e3_4014 = cute.get_leaves(%1597) : !cute.shape<"((2,2),1,8)">
          %1598 = cute.get_stride(%lay_4010) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4015, %e1_4016, %e2_4017, %e3_4018 = cute.get_leaves(%1598) : !cute.stride<"((1,2),0,4)">
          %1599 = scf.if %1596 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1581) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
            cute.memref.store(%1581, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1581) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1581 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1581) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1581) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1581 : !memref_rmem_f32_1
          }
          %iter_4019 = cute.get_iter(%1599) : !memref_rmem_f32_1
          %lay_4020 = cute.get_layout(%1599) : !memref_rmem_f32_1
          %1600 = cute.get_shape(%lay_4020) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4021, %e1_4022, %e2_4023, %e3_4024 = cute.get_leaves(%1600) : !cute.shape<"((2,2),1,8)">
          %1601 = cute.get_stride(%lay_4020) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4025, %e1_4026, %e2_4027, %e3_4028 = cute.get_leaves(%1601) : !cute.stride<"((1,2),0,4)">
          %iter_4029 = cute.get_iter(%1599) : !memref_rmem_f32_1
          %iter_4030 = cute.get_iter(%1599) : !memref_rmem_f32_1
          %coord_4031 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %slice_4032 = cute.slice(%ptn_C, %coord_4031) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,7)">
          %iter_4033 = cute.get_iter(%slice_4032) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4034, %e1_4035 = cute.get_leaves(%iter_4033) : !cute.int_tuple<"(?,?)">
          %1602 = cute.get_scalars(%e0_4034) : !cute.int_tuple<"?">
          %1603 = cute.get_scalars(%e1_4035) : !cute.int_tuple<"?">
          %iter_4036 = cute.get_iter(%slice_4032) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4037, %e1_4038 = cute.get_leaves(%iter_4036) : !cute.int_tuple<"(?,?)">
          %1604 = cute.get_scalars(%e0_4037) : !cute.int_tuple<"?">
          %1605 = cute.get_scalars(%e1_4038) : !cute.int_tuple<"?">
          %iter_4039 = cute.get_iter(%slice_4032) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4040, %e1_4041 = cute.get_leaves(%iter_4039) : !cute.int_tuple<"(?,?)">
          %1606 = cute.get_scalars(%e0_4040) : !cute.int_tuple<"?">
          %1607 = cute.get_scalars(%e1_4041) : !cute.int_tuple<"?">
          %coord_4042 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %slice_4043 = cute.slice(%ptn_C, %coord_4042) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,7)">
          %iter_4044 = cute.get_iter(%slice_4043) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4045, %e1_4046 = cute.get_leaves(%iter_4044) : !cute.int_tuple<"(?,?)">
          %1608 = cute.get_scalars(%e0_4045) : !cute.int_tuple<"?">
          %1609 = cute.get_scalars(%e1_4046) : !cute.int_tuple<"?">
          %iter_4047 = cute.get_iter(%slice_4043) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4048, %e1_4049 = cute.get_leaves(%iter_4047) : !cute.int_tuple<"(?,?)">
          %1610 = cute.get_scalars(%e0_4048) : !cute.int_tuple<"?">
          %1611 = cute.get_scalars(%e1_4049) : !cute.int_tuple<"?">
          %iter_4050 = cute.get_iter(%slice_4043) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_4051, %e1_4052 = cute.get_leaves(%iter_4050) : !cute.int_tuple<"(?,?)">
          %1612 = cute.get_scalars(%e0_4051) : !cute.int_tuple<"?">
          %1613 = cute.get_scalars(%e1_4052) : !cute.int_tuple<"?">
          %coord_4053 = cute.make_coord(%e0_4040) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_4054 = cute.make_coord(%e1_4052) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1614 = cute.elem_less(%coord_4053, %coord_4054) : !cute.coord<"?">, !cute.coord<"?">
          %lay_4055 = cute.get_layout(%1599) : !memref_rmem_f32_1
          %1615 = cute.get_shape(%lay_4055) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4056, %e1_4057, %e2_4058, %e3_4059 = cute.get_leaves(%1615) : !cute.shape<"((2,2),1,8)">
          %1616 = cute.get_stride(%lay_4055) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4060, %e1_4061, %e2_4062, %e3_4063 = cute.get_leaves(%1616) : !cute.stride<"((1,2),0,4)">
          %1617 = scf.if %1614 -> (!memref_rmem_f32_1) {
            %iter_4133 = cute.get_iter(%1599) : !memref_rmem_f32_1
            %cst_4134 = arith.constant 0.000000e+00 : f32
            %coord_4135 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
            cute.memref.store(%1599, %coord_4135, %cst_4134) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
            %lay_4136 = cute.get_layout(%1599) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4137, %e1_4138, %e2_4139, %e3_4140 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4136) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4141, %e1_4142, %e2_4143, %e3_4144 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1599 : !memref_rmem_f32_1
          } else {
            %iter_4133 = cute.get_iter(%1599) : !memref_rmem_f32_1
            %lay_4134 = cute.get_layout(%1599) : !memref_rmem_f32_1
            %1645 = cute.get_shape(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4135, %e1_4136, %e2_4137, %e3_4138 = cute.get_leaves(%1645) : !cute.shape<"((2,2),1,8)">
            %1646 = cute.get_stride(%lay_4134) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4139, %e1_4140, %e2_4141, %e3_4142 = cute.get_leaves(%1646) : !cute.stride<"((1,2),0,4)">
            scf.yield %1599 : !memref_rmem_f32_1
          }
          %iter_4064 = cute.get_iter(%1617) : !memref_rmem_f32_1
          %lay_4065 = cute.get_layout(%1617) : !memref_rmem_f32_1
          %1618 = cute.get_shape(%lay_4065) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4066, %e1_4067, %e2_4068, %e3_4069 = cute.get_leaves(%1618) : !cute.shape<"((2,2),1,8)">
          %1619 = cute.get_stride(%lay_4065) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4070, %e1_4071, %e2_4072, %e3_4073 = cute.get_leaves(%1619) : !cute.stride<"((1,2),0,4)">
          %iter_4074 = cute.get_iter(%1617) : !memref_rmem_f32_1
          %iter_4075 = cute.get_iter(%1617) : !memref_rmem_f32_1
          %lay_4076 = cute.get_layout(%1617) : !memref_rmem_f32_1
          %1620 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1620) : !cute.shape<"((2,2),1,8)">
          %1621 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1621) : !cute.stride<"((1,2),0,4)">
          %1622 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
          %1623 = cute.get_shape(%1622) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
          %e0_4085, %e1_4086, %e2_4087, %e3_4088 = cute.get_leaves(%1623) : !cute.shape<"(32,4,1,1)">
          %1624 = cute.get_stride(%1622) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
          %e0_4089, %e1_4090, %e2_4091, %e3_4092 = cute.get_leaves(%1624) : !cute.stride<"(1,32,0,0)">
          %1625 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
          %e0_4093, %e1_4094, %e2_4095 = cute.get_leaves(%1625) : !cute.tile<"[64:1;16:1;16:1]">
          %1626 = cute.get_shape(%e0_4093) : (!cute.layout<"64:1">) -> !cute.shape<"64">
          %e0_4096 = cute.get_leaves(%1626) : !cute.shape<"64">
          %1627 = cute.get_stride(%e0_4093) : (!cute.layout<"64:1">) -> !cute.stride<"1">
          %e0_4097 = cute.get_leaves(%1627) : !cute.stride<"1">
          %1628 = cute.get_shape(%e1_4094) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_4098 = cute.get_leaves(%1628) : !cute.shape<"16">
          %1629 = cute.get_stride(%e1_4094) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_4099 = cute.get_leaves(%1629) : !cute.stride<"1">
          %1630 = cute.get_shape(%e2_4095) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_4100 = cute.get_leaves(%1630) : !cute.shape<"16">
          %1631 = cute.get_stride(%e2_4095) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_4101 = cute.get_leaves(%1631) : !cute.stride<"1">
          %1632 = cute.static : !cute.layout<"32:1">
          %1633 = cute.get_shape(%1632) : (!cute.layout<"32:1">) -> !cute.shape<"32">
          %e0_4102 = cute.get_leaves(%1633) : !cute.shape<"32">
          %1634 = cute.get_stride(%1632) : (!cute.layout<"32:1">) -> !cute.stride<"1">
          %e0_4103 = cute.get_leaves(%1634) : !cute.stride<"1">
          %1635 = cute.static : !cute.shape<"(16,8,16)">
          %e0_4104, %e1_4105, %e2_4106 = cute.get_leaves(%1635) : !cute.shape<"(16,8,16)">
          %1636 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
          %1637 = cute.get_shape(%1636) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
          %e0_4107, %e1_4108, %e2_4109, %e3_4110, %e4_4111 = cute.get_leaves(%1637) : !cute.shape<"((4,8),(2,2,2))">
          %1638 = cute.get_stride(%1636) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
          %e0_4112, %e1_4113, %e2_4114, %e3_4115, %e4_4116 = cute.get_leaves(%1638) : !cute.stride<"((32,1),(16,8,128))">
          %1639 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
          %1640 = cute.get_shape(%1639) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_4117, %e1_4118, %e2_4119, %e3_4120 = cute.get_leaves(%1640) : !cute.shape<"((4,8),(2,2))">
          %1641 = cute.get_stride(%1639) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
          %e0_4121, %e1_4122, %e2_4123, %e3_4124 = cute.get_leaves(%1641) : !cute.stride<"((16,1),(8,64))">
          %1642 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
          %1643 = cute.get_shape(%1642) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_4125, %e1_4126, %e2_4127, %e3_4128 = cute.get_leaves(%1643) : !cute.shape<"((4,8),(2,2))">
          %1644 = cute.get_stride(%1642) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
          %e0_4129, %e1_4130, %e2_4131, %e3_4132 = cute.get_leaves(%1644) : !cute.stride<"((32,1),(16,8))">
          scf.yield %1617, %arg6 : !memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_
        } else {
          %iter_2599 = cute.get_iter(%928) : !memref_rmem_f32_1
          %lay_2600 = cute.get_layout(%928) : !memref_rmem_f32_1
          %1041 = cute.get_shape(%lay_2600) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2601, %e1_2602, %e2_2603, %e3_2604 = cute.get_leaves(%1041) : !cute.shape<"((2,2),1,8)">
          %1042 = cute.get_stride(%lay_2600) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2605, %e1_2606, %e2_2607, %e3_2608 = cute.get_leaves(%1042) : !cute.stride<"((1,2),0,4)">
          %1043 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
          %1044 = cute.get_shape(%1043) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
          %e0_2609, %e1_2610, %e2_2611, %e3_2612 = cute.get_leaves(%1044) : !cute.shape<"(32,4,1,1)">
          %1045 = cute.get_stride(%1043) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
          %e0_2613, %e1_2614, %e2_2615, %e3_2616 = cute.get_leaves(%1045) : !cute.stride<"(1,32,0,0)">
          %1046 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
          %e0_2617, %e1_2618, %e2_2619 = cute.get_leaves(%1046) : !cute.tile<"[64:1;16:1;16:1]">
          %1047 = cute.get_shape(%e0_2617) : (!cute.layout<"64:1">) -> !cute.shape<"64">
          %e0_2620 = cute.get_leaves(%1047) : !cute.shape<"64">
          %1048 = cute.get_stride(%e0_2617) : (!cute.layout<"64:1">) -> !cute.stride<"1">
          %e0_2621 = cute.get_leaves(%1048) : !cute.stride<"1">
          %1049 = cute.get_shape(%e1_2618) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_2622 = cute.get_leaves(%1049) : !cute.shape<"16">
          %1050 = cute.get_stride(%e1_2618) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_2623 = cute.get_leaves(%1050) : !cute.stride<"1">
          %1051 = cute.get_shape(%e2_2619) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_2624 = cute.get_leaves(%1051) : !cute.shape<"16">
          %1052 = cute.get_stride(%e2_2619) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_2625 = cute.get_leaves(%1052) : !cute.stride<"1">
          %1053 = cute.static : !cute.layout<"32:1">
          %1054 = cute.get_shape(%1053) : (!cute.layout<"32:1">) -> !cute.shape<"32">
          %e0_2626 = cute.get_leaves(%1054) : !cute.shape<"32">
          %1055 = cute.get_stride(%1053) : (!cute.layout<"32:1">) -> !cute.stride<"1">
          %e0_2627 = cute.get_leaves(%1055) : !cute.stride<"1">
          %1056 = cute.static : !cute.shape<"(16,8,16)">
          %e0_2628, %e1_2629, %e2_2630 = cute.get_leaves(%1056) : !cute.shape<"(16,8,16)">
          %1057 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
          %1058 = cute.get_shape(%1057) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
          %e0_2631, %e1_2632, %e2_2633, %e3_2634, %e4_2635 = cute.get_leaves(%1058) : !cute.shape<"((4,8),(2,2,2))">
          %1059 = cute.get_stride(%1057) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
          %e0_2636, %e1_2637, %e2_2638, %e3_2639, %e4_2640 = cute.get_leaves(%1059) : !cute.stride<"((32,1),(16,8,128))">
          %1060 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
          %1061 = cute.get_shape(%1060) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_2641, %e1_2642, %e2_2643, %e3_2644 = cute.get_leaves(%1061) : !cute.shape<"((4,8),(2,2))">
          %1062 = cute.get_stride(%1060) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
          %e0_2645, %e1_2646, %e2_2647, %e3_2648 = cute.get_leaves(%1062) : !cute.stride<"((16,1),(8,64))">
          %1063 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
          %1064 = cute.get_shape(%1063) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_2649, %e1_2650, %e2_2651, %e3_2652 = cute.get_leaves(%1064) : !cute.shape<"((4,8),(2,2))">
          %1065 = cute.get_stride(%1063) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
          %e0_2653, %e1_2654, %e2_2655, %e3_2656 = cute.get_leaves(%1065) : !cute.stride<"((32,1),(16,8))">
          scf.yield %928, %arg6 : !memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_
        }
        %iter_2279 = cute.get_iter(%969#0) : !memref_rmem_f32_1
        %lay_2280 = cute.get_layout(%969#0) : !memref_rmem_f32_1
        %970 = cute.get_shape(%lay_2280) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2281, %e1_2282, %e2_2283, %e3_2284 = cute.get_leaves(%970) : !cute.shape<"((2,2),1,8)">
        %971 = cute.get_stride(%lay_2280) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2285, %e1_2286, %e2_2287, %e3_2288 = cute.get_leaves(%971) : !cute.stride<"((1,2),0,4)">
        %iter_2289 = cute.get_iter(%969#0) : !memref_rmem_f32_1
        %iter_2290 = cute.get_iter(%969#0) : !memref_rmem_f32_1
        %lay_2291 = cute.get_layout(%969#0) : !memref_rmem_f32_1
        %972 = cute.make_layout_like(%lay_2291) : !cute.layout<"((2,2),1,8):((1,2),0,4)"> to !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_2292 = cute.memref.alloca(%972) : !memref_rmem_bf16_6
        %iter_2293 = cute.get_iter(%rmem_2292) : !memref_rmem_bf16_6
        %iter_2294 = cute.get_iter(%rmem_2292) : !memref_rmem_bf16_6
        %lay_2295 = cute.get_layout(%969#0) : !memref_rmem_f32_1
        %973 = cute.get_shape(%lay_2295) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2296, %e1_2297, %e2_2298, %e3_2299 = cute.get_leaves(%973) : !cute.shape<"((2,2),1,8)">
        %974 = cute.memref.load_vec %969#0 : !memref_rmem_f32_1
        %975 = arith.truncf %974 : vector<32xf32> to vector<32xbf16>
        %lay_2300 = cute.get_layout(%rmem_2292) : !memref_rmem_bf16_6
        %976 = cute.get_shape(%lay_2300) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2301, %e1_2302, %e2_2303, %e3_2304 = cute.get_leaves(%976) : !cute.shape<"((2,2),1,8)">
        %int_tuple_2305 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_2306 = cute.size(%int_tuple_2305) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_2307 = cute.get_leaves(%sz_2306) : !cute.int_tuple<"32">
        %int_tuple_2308 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_2309 = cute.size(%int_tuple_2308) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_2310 = cute.get_leaves(%sz_2309) : !cute.int_tuple<"32">
        cute.memref.store_vec %975, %rmem_2292 : !memref_rmem_bf16_6
        %lay_2311 = cute.get_layout(%rmem_2292) : !memref_rmem_bf16_6
        %tile_2312 = cute.make_tile() : () -> !cute.tile<"[_;_;2:1]">
        %div = cute.logical_divide(%lay_2311, %tile_2312) : !cute.layout<"((2,2),1,8):((1,2),0,4)">, !cute.tile<"[_;_;2:1]">
        %977 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2313, %e1_2314, %e2_2315, %e3_2316, %e4_2317 = cute.get_leaves(%977) : !cute.shape<"((2,2),1,(2,4))">
        %978 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2318, %e1_2319, %e2_2320, %e3_2321, %e4_2322 = cute.get_leaves(%978) : !cute.shape<"((2,2),1,(2,4))">
        %979 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2323, %e1_2324, %e2_2325, %e3_2326, %e4_2327 = cute.get_leaves(%979) : !cute.shape<"((2,2),1,(2,4))">
        %980 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2328, %e1_2329, %e2_2330, %e3_2331, %e4_2332 = cute.get_leaves(%980) : !cute.shape<"((2,2),1,(2,4))">
        %981 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2333, %e1_2334, %e2_2335, %e3_2336, %e4_2337 = cute.get_leaves(%981) : !cute.stride<"((1,2),0,(4,8))">
        %982 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2338, %e1_2339, %e2_2340, %e3_2341, %e4_2342 = cute.get_leaves(%982) : !cute.stride<"((1,2),0,(4,8))">
        %983 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2343, %e1_2344, %e2_2345, %e3_2346, %e4_2347 = cute.get_leaves(%983) : !cute.stride<"((1,2),0,(4,8))">
        %984 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2348, %e1_2349, %e2_2350, %e3_2351, %e4_2352 = cute.get_leaves(%984) : !cute.stride<"((1,2),0,(4,8))">
        %shape_2353 = cute.make_shape() : () -> !cute.shape<"(((2,2),2),1,4)">
        %stride_2354 = cute.make_stride() : () -> !cute.stride<"(((1,2),4),0,8)">
        %lay_2355 = cute.make_layout(%shape_2353, %stride_2354) : !cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">
        %view_2356 = cute.make_view(%iter_2294, %lay_2355) : !memref_rmem_bf16_15
        %iter_2357 = cute.get_iter(%view_2356) : !memref_rmem_bf16_15
        %coord_2358 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2359 = cute.slice(%src_partitioned_406, %coord_2358) : !memref_smem_bf16_10, !cute.coord<"(_,_,0)">
        %iter_2360 = cute.get_iter(%slice_2359) : !memref_smem_bf16_21
        %iter_2361 = cute.get_iter(%slice_2359) : !memref_smem_bf16_21
        %coord_2362 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2363 = cute.slice(%retiled_408, %coord_2362) : !memref_rmem_bf16_5, !cute.coord<"(_,_,0)">
        %iter_2364 = cute.get_iter(%slice_2363) : !memref_rmem_bf16_16
        %iter_2365 = cute.get_iter(%slice_2363) : !memref_rmem_bf16_16
        %lay_2366 = cute.get_layout(%slice_2359) : !memref_smem_bf16_21
        %985 = cute.get_shape(%lay_2366) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
        %e0_2367, %e1_2368, %e2_2369, %e3_2370, %e4_2371 = cute.get_leaves(%985) : !cute.shape<"((8,1),((2,2),2))">
        %lay_2372 = cute.get_layout(%slice_2363) : !memref_rmem_bf16_16
        %986 = cute.get_shape(%lay_2372) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
        %e0_2373, %e1_2374, %e2_2375, %e3_2376 = cute.get_leaves(%986) : !cute.shape<"((8,1),(4,2))">
        %lay_2377 = cute.get_layout(%slice_2359) : !memref_smem_bf16_21
        %shape_2378 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_2379 = cute.make_layout(%shape_2378) : !cute.layout<"1:0">
        %append_2380 = cute.append_to_rank<2> (%lay_2377, %lay_2379) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_2381 = cute.make_view(%iter_2361, %append_2380) : !memref_smem_bf16_21
        %iter_2382 = cute.get_iter(%view_2381) : !memref_smem_bf16_21
        %lay_2383 = cute.get_layout(%view_2381) : !memref_smem_bf16_21
        %987 = cute.get_shape(%lay_2383) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
        %e0_2384, %e1_2385, %e2_2386, %e3_2387, %e4_2388 = cute.get_leaves(%987) : !cute.shape<"((8,1),((2,2),2))">
        %grouped_2389 = cute.group_modes(%view_2381) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
        %iter_2390 = cute.get_iter(%grouped_2389) : !memref_smem_bf16_22
        %iter_2391 = cute.get_iter(%grouped_2389) : !memref_smem_bf16_22
        %lay_2392 = cute.get_layout(%slice_2363) : !memref_rmem_bf16_16
        %shape_2393 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_2394 = cute.make_layout(%shape_2393) : !cute.layout<"1:0">
        %append_2395 = cute.append_to_rank<2> (%lay_2392, %lay_2394) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
        %view_2396 = cute.make_view(%iter_2365, %append_2395) : !memref_rmem_bf16_16
        %iter_2397 = cute.get_iter(%view_2396) : !memref_rmem_bf16_16
        %lay_2398 = cute.get_layout(%view_2396) : !memref_rmem_bf16_16
        %988 = cute.get_shape(%lay_2398) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
        %e0_2399, %e1_2400, %e2_2401, %e3_2402 = cute.get_leaves(%988) : !cute.shape<"((8,1),(4,2))">
        %grouped_2403 = cute.group_modes(%view_2396) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
        %iter_2404 = cute.get_iter(%grouped_2403) : !memref_rmem_bf16_17
        %iter_2405 = cute.get_iter(%grouped_2403) : !memref_rmem_bf16_17
        %lay_2406 = cute.get_layout(%grouped_2389) : !memref_smem_bf16_22
        %989 = cute.get_shape(%lay_2406) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
        %e0_2407, %e1_2408, %e2_2409, %e3_2410, %e4_2411 = cute.get_leaves(%989) : !cute.shape<"((8,1),(((2,2),2)))">
        %lay_2412 = cute.get_layout(%grouped_2403) : !memref_rmem_bf16_17
        %990 = cute.get_shape(%lay_2412) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
        %e0_2413, %e1_2414, %e2_2415, %e3_2416 = cute.get_leaves(%990) : !cute.shape<"((8,1),((4,2)))">
        %sz_2417 = cute.size(%grouped_2389) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
        %e0_2418 = cute.get_leaves(%sz_2417) : !cute.int_tuple<"8">
        %sz_2419 = cute.size(%grouped_2403) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
        %e0_2420 = cute.get_leaves(%sz_2419) : !cute.int_tuple<"8">
        cute.copy(%166, %grouped_2389, %grouped_2403) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        %lay_2421 = cute.get_layout(%view_2356) : !memref_rmem_bf16_15
        %991 = cute.get_shape(%lay_2421) : (!cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">) -> !cute.shape<"(((2,2),2),1,4)">
        %e0_2422, %e1_2423, %e2_2424, %e3_2425, %e4_2426 = cute.get_leaves(%991) : !cute.shape<"(((2,2),2),1,4)">
        %int_tuple_2427 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2428 = cute.size(%int_tuple_2427) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2429 = cute.get_leaves(%sz_2428) : !cute.int_tuple<"4">
        %int_tuple_2430 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2431 = cute.size(%int_tuple_2430) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2432 = cute.get_leaves(%sz_2431) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2600 = cute.slice(%src_partitioned_406, %coord_2599) : !memref_smem_bf16_10, !cute.coord<"(_,_,1)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2604 = cute.slice(%retiled_408, %coord_2603) : !memref_rmem_bf16_5, !cute.coord<"(_,_,1)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2608, %e1_2609, %e2_2610, %e3_2611, %e4_2612 = cute.get_leaves(%1041) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2613 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %1042 = cute.get_shape(%lay_2613) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1042) : !cute.shape<"((8,1),(4,2))">
          %lay_2618 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %shape_2619 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2620 = cute.make_layout(%shape_2619) : !cute.layout<"1:0">
          %append_2621 = cute.append_to_rank<2> (%lay_2618, %lay_2620) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2622 = cute.make_view(%iter_2602, %append_2621) : !memref_smem_bf16_21
          %iter_2623 = cute.get_iter(%view_2622) : !memref_smem_bf16_21
          %lay_2624 = cute.get_layout(%view_2622) : !memref_smem_bf16_21
          %1043 = cute.get_shape(%lay_2624) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2625, %e1_2626, %e2_2627, %e3_2628, %e4_2629 = cute.get_leaves(%1043) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2630 = cute.group_modes(%view_2622) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %lay_2633 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %shape_2634 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2635 = cute.make_layout(%shape_2634) : !cute.layout<"1:0">
          %append_2636 = cute.append_to_rank<2> (%lay_2633, %lay_2635) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2637 = cute.make_view(%iter_2606, %append_2636) : !memref_rmem_bf16_16
          %iter_2638 = cute.get_iter(%view_2637) : !memref_rmem_bf16_16
          %lay_2639 = cute.get_layout(%view_2637) : !memref_rmem_bf16_16
          %1044 = cute.get_shape(%lay_2639) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2640, %e1_2641, %e2_2642, %e3_2643 = cute.get_leaves(%1044) : !cute.shape<"((8,1),(4,2))">
          %grouped_2644 = cute.group_modes(%view_2637) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2645 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %iter_2646 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %lay_2647 = cute.get_layout(%grouped_2630) : !memref_smem_bf16_22
          %1045 = cute.get_shape(%lay_2647) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2648, %e1_2649, %e2_2650, %e3_2651, %e4_2652 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2653 = cute.get_layout(%grouped_2644) : !memref_rmem_bf16_17
          %1046 = cute.get_shape(%lay_2653) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2654, %e1_2655, %e2_2656, %e3_2657 = cute.get_leaves(%1046) : !cute.shape<"((8,1),((4,2)))">
          %sz_2658 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2659 = cute.get_leaves(%sz_2658) : !cute.int_tuple<"8">
          %sz_2660 = cute.size(%grouped_2644) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2661 = cute.get_leaves(%sz_2660) : !cute.int_tuple<"8">
          cute.copy(%166, %grouped_2630, %grouped_2644) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2433 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2434 = cute.slice(%view_2356, %coord_2433) : !memref_rmem_bf16_15, !cute.coord<"(_,_,0)">
        %iter_2435 = cute.get_iter(%slice_2434) : !memref_rmem_bf16_18
        %iter_2436 = cute.get_iter(%slice_2434) : !memref_rmem_bf16_18
        %coord_2437 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2438 = cute.slice(%frg_B_320, %coord_2437) : !memref_rmem_bf16_2, !cute.coord<"(_,_,0)">
        %iter_2439 = cute.get_iter(%slice_2438) : !memref_rmem_bf16_19
        %iter_2440 = cute.get_iter(%slice_2438) : !memref_rmem_bf16_19
        %lay_2441 = cute.get_layout(%slice_2434) : !memref_rmem_bf16_18
        %992 = cute.get_shape(%lay_2441) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2442, %e1_2443, %e2_2444, %e3_2445 = cute.get_leaves(%992) : !cute.shape<"(((2,2),2),1)">
        %lay_2446 = cute.get_layout(%slice_2438) : !memref_rmem_bf16_19
        %993 = cute.get_shape(%lay_2446) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2447, %e1_2448, %e2_2449, %e3_2450 = cute.get_leaves(%993) : !cute.shape<"((2,2),(8,2))">
        %lay_2451 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %994 = cute.get_shape(%lay_2451) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
        %e0_2452, %e1_2453, %e2_2454, %e3_2455 = cute.get_leaves(%994) : !cute.shape<"((2,2),1,16)">
        cute.gemm(%6, %rmem, %slice_2434, %slice_2438, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_18, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2456 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2457 = cute.size(%int_tuple_2456) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2458 = cute.get_leaves(%sz_2457) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2600 = cute.slice(%src_partitioned_406, %coord_2599) : !memref_smem_bf16_10, !cute.coord<"(_,_,2)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2604 = cute.slice(%retiled_408, %coord_2603) : !memref_rmem_bf16_5, !cute.coord<"(_,_,2)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2608, %e1_2609, %e2_2610, %e3_2611, %e4_2612 = cute.get_leaves(%1041) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2613 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %1042 = cute.get_shape(%lay_2613) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1042) : !cute.shape<"((8,1),(4,2))">
          %lay_2618 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %shape_2619 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2620 = cute.make_layout(%shape_2619) : !cute.layout<"1:0">
          %append_2621 = cute.append_to_rank<2> (%lay_2618, %lay_2620) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2622 = cute.make_view(%iter_2602, %append_2621) : !memref_smem_bf16_21
          %iter_2623 = cute.get_iter(%view_2622) : !memref_smem_bf16_21
          %lay_2624 = cute.get_layout(%view_2622) : !memref_smem_bf16_21
          %1043 = cute.get_shape(%lay_2624) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2625, %e1_2626, %e2_2627, %e3_2628, %e4_2629 = cute.get_leaves(%1043) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2630 = cute.group_modes(%view_2622) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %lay_2633 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %shape_2634 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2635 = cute.make_layout(%shape_2634) : !cute.layout<"1:0">
          %append_2636 = cute.append_to_rank<2> (%lay_2633, %lay_2635) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2637 = cute.make_view(%iter_2606, %append_2636) : !memref_rmem_bf16_16
          %iter_2638 = cute.get_iter(%view_2637) : !memref_rmem_bf16_16
          %lay_2639 = cute.get_layout(%view_2637) : !memref_rmem_bf16_16
          %1044 = cute.get_shape(%lay_2639) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2640, %e1_2641, %e2_2642, %e3_2643 = cute.get_leaves(%1044) : !cute.shape<"((8,1),(4,2))">
          %grouped_2644 = cute.group_modes(%view_2637) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2645 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %iter_2646 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %lay_2647 = cute.get_layout(%grouped_2630) : !memref_smem_bf16_22
          %1045 = cute.get_shape(%lay_2647) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2648, %e1_2649, %e2_2650, %e3_2651, %e4_2652 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2653 = cute.get_layout(%grouped_2644) : !memref_rmem_bf16_17
          %1046 = cute.get_shape(%lay_2653) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2654, %e1_2655, %e2_2656, %e3_2657 = cute.get_leaves(%1046) : !cute.shape<"((8,1),((4,2)))">
          %sz_2658 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2659 = cute.get_leaves(%sz_2658) : !cute.int_tuple<"8">
          %sz_2660 = cute.size(%grouped_2644) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2661 = cute.get_leaves(%sz_2660) : !cute.int_tuple<"8">
          cute.copy(%166, %grouped_2630, %grouped_2644) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2459 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2460 = cute.slice(%view_2356, %coord_2459) : !memref_rmem_bf16_15, !cute.coord<"(_,_,1)">
        %iter_2461 = cute.get_iter(%slice_2460) : !memref_rmem_bf16_20
        %iter_2462 = cute.get_iter(%slice_2460) : !memref_rmem_bf16_20
        %coord_2463 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2464 = cute.slice(%frg_B_320, %coord_2463) : !memref_rmem_bf16_2, !cute.coord<"(_,_,1)">
        %iter_2465 = cute.get_iter(%slice_2464) : !memref_rmem_bf16_19
        %iter_2466 = cute.get_iter(%slice_2464) : !memref_rmem_bf16_19
        %lay_2467 = cute.get_layout(%slice_2460) : !memref_rmem_bf16_20
        %995 = cute.get_shape(%lay_2467) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2468, %e1_2469, %e2_2470, %e3_2471 = cute.get_leaves(%995) : !cute.shape<"(((2,2),2),1)">
        %lay_2472 = cute.get_layout(%slice_2464) : !memref_rmem_bf16_19
        %996 = cute.get_shape(%lay_2472) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2473, %e1_2474, %e2_2475, %e3_2476 = cute.get_leaves(%996) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%6, %rmem, %slice_2460, %slice_2464, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_20, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2477 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2478 = cute.size(%int_tuple_2477) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2479 = cute.get_leaves(%sz_2478) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2600 = cute.slice(%src_partitioned_406, %coord_2599) : !memref_smem_bf16_10, !cute.coord<"(_,_,3)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2604 = cute.slice(%retiled_408, %coord_2603) : !memref_rmem_bf16_5, !cute.coord<"(_,_,3)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2608, %e1_2609, %e2_2610, %e3_2611, %e4_2612 = cute.get_leaves(%1041) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2613 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %1042 = cute.get_shape(%lay_2613) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1042) : !cute.shape<"((8,1),(4,2))">
          %lay_2618 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %shape_2619 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2620 = cute.make_layout(%shape_2619) : !cute.layout<"1:0">
          %append_2621 = cute.append_to_rank<2> (%lay_2618, %lay_2620) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2622 = cute.make_view(%iter_2602, %append_2621) : !memref_smem_bf16_21
          %iter_2623 = cute.get_iter(%view_2622) : !memref_smem_bf16_21
          %lay_2624 = cute.get_layout(%view_2622) : !memref_smem_bf16_21
          %1043 = cute.get_shape(%lay_2624) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2625, %e1_2626, %e2_2627, %e3_2628, %e4_2629 = cute.get_leaves(%1043) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2630 = cute.group_modes(%view_2622) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %lay_2633 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %shape_2634 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2635 = cute.make_layout(%shape_2634) : !cute.layout<"1:0">
          %append_2636 = cute.append_to_rank<2> (%lay_2633, %lay_2635) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2637 = cute.make_view(%iter_2606, %append_2636) : !memref_rmem_bf16_16
          %iter_2638 = cute.get_iter(%view_2637) : !memref_rmem_bf16_16
          %lay_2639 = cute.get_layout(%view_2637) : !memref_rmem_bf16_16
          %1044 = cute.get_shape(%lay_2639) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2640, %e1_2641, %e2_2642, %e3_2643 = cute.get_leaves(%1044) : !cute.shape<"((8,1),(4,2))">
          %grouped_2644 = cute.group_modes(%view_2637) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2645 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %iter_2646 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %lay_2647 = cute.get_layout(%grouped_2630) : !memref_smem_bf16_22
          %1045 = cute.get_shape(%lay_2647) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2648, %e1_2649, %e2_2650, %e3_2651, %e4_2652 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2653 = cute.get_layout(%grouped_2644) : !memref_rmem_bf16_17
          %1046 = cute.get_shape(%lay_2653) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2654, %e1_2655, %e2_2656, %e3_2657 = cute.get_leaves(%1046) : !cute.shape<"((8,1),((4,2)))">
          %sz_2658 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2659 = cute.get_leaves(%sz_2658) : !cute.int_tuple<"8">
          %sz_2660 = cute.size(%grouped_2644) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2661 = cute.get_leaves(%sz_2660) : !cute.int_tuple<"8">
          cute.copy(%166, %grouped_2630, %grouped_2644) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2480 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2481 = cute.slice(%view_2356, %coord_2480) : !memref_rmem_bf16_15, !cute.coord<"(_,_,2)">
        %iter_2482 = cute.get_iter(%slice_2481) : !memref_rmem_bf16_18
        %iter_2483 = cute.get_iter(%slice_2481) : !memref_rmem_bf16_18
        %coord_2484 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2485 = cute.slice(%frg_B_320, %coord_2484) : !memref_rmem_bf16_2, !cute.coord<"(_,_,2)">
        %iter_2486 = cute.get_iter(%slice_2485) : !memref_rmem_bf16_19
        %iter_2487 = cute.get_iter(%slice_2485) : !memref_rmem_bf16_19
        %lay_2488 = cute.get_layout(%slice_2481) : !memref_rmem_bf16_18
        %997 = cute.get_shape(%lay_2488) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2489, %e1_2490, %e2_2491, %e3_2492 = cute.get_leaves(%997) : !cute.shape<"(((2,2),2),1)">
        %lay_2493 = cute.get_layout(%slice_2485) : !memref_rmem_bf16_19
        %998 = cute.get_shape(%lay_2493) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2494, %e1_2495, %e2_2496, %e3_2497 = cute.get_leaves(%998) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%6, %rmem, %slice_2481, %slice_2485, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_18, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2498 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2499 = cute.size(%int_tuple_2498) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2500 = cute.get_leaves(%sz_2499) : !cute.int_tuple<"4">
        scf.if %false {
          %coord_2599 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2600 = cute.slice(%src_partitioned_406, %coord_2599) : !memref_smem_bf16_10, !cute.coord<"(_,_,4)">
          %iter_2601 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %iter_2602 = cute.get_iter(%slice_2600) : !memref_smem_bf16_21
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2604 = cute.slice(%retiled_408, %coord_2603) : !memref_rmem_bf16_5, !cute.coord<"(_,_,4)">
          %iter_2605 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %iter_2606 = cute.get_iter(%slice_2604) : !memref_rmem_bf16_16
          %lay_2607 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %1041 = cute.get_shape(%lay_2607) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2608, %e1_2609, %e2_2610, %e3_2611, %e4_2612 = cute.get_leaves(%1041) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2613 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %1042 = cute.get_shape(%lay_2613) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%1042) : !cute.shape<"((8,1),(4,2))">
          %lay_2618 = cute.get_layout(%slice_2600) : !memref_smem_bf16_21
          %shape_2619 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2620 = cute.make_layout(%shape_2619) : !cute.layout<"1:0">
          %append_2621 = cute.append_to_rank<2> (%lay_2618, %lay_2620) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2622 = cute.make_view(%iter_2602, %append_2621) : !memref_smem_bf16_21
          %iter_2623 = cute.get_iter(%view_2622) : !memref_smem_bf16_21
          %lay_2624 = cute.get_layout(%view_2622) : !memref_smem_bf16_21
          %1043 = cute.get_shape(%lay_2624) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2625, %e1_2626, %e2_2627, %e3_2628, %e4_2629 = cute.get_leaves(%1043) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2630 = cute.group_modes(%view_2622) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_smem_bf16_22
          %lay_2633 = cute.get_layout(%slice_2604) : !memref_rmem_bf16_16
          %shape_2634 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2635 = cute.make_layout(%shape_2634) : !cute.layout<"1:0">
          %append_2636 = cute.append_to_rank<2> (%lay_2633, %lay_2635) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2637 = cute.make_view(%iter_2606, %append_2636) : !memref_rmem_bf16_16
          %iter_2638 = cute.get_iter(%view_2637) : !memref_rmem_bf16_16
          %lay_2639 = cute.get_layout(%view_2637) : !memref_rmem_bf16_16
          %1044 = cute.get_shape(%lay_2639) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2640, %e1_2641, %e2_2642, %e3_2643 = cute.get_leaves(%1044) : !cute.shape<"((8,1),(4,2))">
          %grouped_2644 = cute.group_modes(%view_2637) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2645 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %iter_2646 = cute.get_iter(%grouped_2644) : !memref_rmem_bf16_17
          %lay_2647 = cute.get_layout(%grouped_2630) : !memref_smem_bf16_22
          %1045 = cute.get_shape(%lay_2647) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2648, %e1_2649, %e2_2650, %e3_2651, %e4_2652 = cute.get_leaves(%1045) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2653 = cute.get_layout(%grouped_2644) : !memref_rmem_bf16_17
          %1046 = cute.get_shape(%lay_2653) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2654, %e1_2655, %e2_2656, %e3_2657 = cute.get_leaves(%1046) : !cute.shape<"((8,1),((4,2)))">
          %sz_2658 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2659 = cute.get_leaves(%sz_2658) : !cute.int_tuple<"8">
          %sz_2660 = cute.size(%grouped_2644) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2661 = cute.get_leaves(%sz_2660) : !cute.int_tuple<"8">
          cute.copy(%166, %grouped_2630, %grouped_2644) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2501 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2502 = cute.slice(%view_2356, %coord_2501) : !memref_rmem_bf16_15, !cute.coord<"(_,_,3)">
        %iter_2503 = cute.get_iter(%slice_2502) : !memref_rmem_bf16_20
        %iter_2504 = cute.get_iter(%slice_2502) : !memref_rmem_bf16_20
        %coord_2505 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2506 = cute.slice(%frg_B_320, %coord_2505) : !memref_rmem_bf16_2, !cute.coord<"(_,_,3)">
        %iter_2507 = cute.get_iter(%slice_2506) : !memref_rmem_bf16_19
        %iter_2508 = cute.get_iter(%slice_2506) : !memref_rmem_bf16_19
        %lay_2509 = cute.get_layout(%slice_2502) : !memref_rmem_bf16_20
        %999 = cute.get_shape(%lay_2509) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2510, %e1_2511, %e2_2512, %e3_2513 = cute.get_leaves(%999) : !cute.shape<"(((2,2),2),1)">
        %lay_2514 = cute.get_layout(%slice_2506) : !memref_rmem_bf16_19
        %1000 = cute.get_shape(%lay_2514) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2515, %e1_2516, %e2_2517, %e3_2518 = cute.get_leaves(%1000) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%6, %rmem, %slice_2502, %slice_2506, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_20, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %1001 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
        %1002 = cute.get_shape(%1001) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
        %e0_2519, %e1_2520, %e2_2521, %e3_2522 = cute.get_leaves(%1002) : !cute.shape<"(32,4,1,1)">
        %1003 = cute.get_stride(%1001) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
        %e0_2523, %e1_2524, %e2_2525, %e3_2526 = cute.get_leaves(%1003) : !cute.stride<"(1,32,0,0)">
        %1004 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
        %e0_2527, %e1_2528, %e2_2529 = cute.get_leaves(%1004) : !cute.tile<"[64:1;16:1;16:1]">
        %1005 = cute.get_shape(%e0_2527) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2530 = cute.get_leaves(%1005) : !cute.shape<"64">
        %1006 = cute.get_stride(%e0_2527) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2531 = cute.get_leaves(%1006) : !cute.stride<"1">
        %1007 = cute.get_shape(%e1_2528) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2532 = cute.get_leaves(%1007) : !cute.shape<"16">
        %1008 = cute.get_stride(%e1_2528) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2533 = cute.get_leaves(%1008) : !cute.stride<"1">
        %1009 = cute.get_shape(%e2_2529) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2534 = cute.get_leaves(%1009) : !cute.shape<"16">
        %1010 = cute.get_stride(%e2_2529) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2535 = cute.get_leaves(%1010) : !cute.stride<"1">
        %1011 = cute.static : !cute.layout<"32:1">
        %1012 = cute.get_shape(%1011) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2536 = cute.get_leaves(%1012) : !cute.shape<"32">
        %1013 = cute.get_stride(%1011) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2537 = cute.get_leaves(%1013) : !cute.stride<"1">
        %1014 = cute.static : !cute.shape<"(16,8,16)">
        %e0_2538, %e1_2539, %e2_2540 = cute.get_leaves(%1014) : !cute.shape<"(16,8,16)">
        %1015 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
        %1016 = cute.get_shape(%1015) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
        %e0_2541, %e1_2542, %e2_2543, %e3_2544, %e4_2545 = cute.get_leaves(%1016) : !cute.shape<"((4,8),(2,2,2))">
        %1017 = cute.get_stride(%1015) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
        %e0_2546, %e1_2547, %e2_2548, %e3_2549, %e4_2550 = cute.get_leaves(%1017) : !cute.stride<"((32,1),(16,8,128))">
        %1018 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
        %1019 = cute.get_shape(%1018) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2551, %e1_2552, %e2_2553, %e3_2554 = cute.get_leaves(%1019) : !cute.shape<"((4,8),(2,2))">
        %1020 = cute.get_stride(%1018) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
        %e0_2555, %e1_2556, %e2_2557, %e3_2558 = cute.get_leaves(%1020) : !cute.stride<"((16,1),(8,64))">
        %1021 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
        %1022 = cute.get_shape(%1021) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2559, %e1_2560, %e2_2561, %e3_2562 = cute.get_leaves(%1022) : !cute.shape<"((4,8),(2,2))">
        %1023 = cute.get_stride(%1021) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
        %e0_2563, %e1_2564, %e2_2565, %e3_2566 = cute.get_leaves(%1023) : !cute.stride<"((32,1),(16,8))">
        %1024 = cute.static : !cute.tile<"[64:1;16:1]">
        %e0_2567, %e1_2568 = cute.get_leaves(%1024) : !cute.tile<"[64:1;16:1]">
        %1025 = cute.get_shape(%e0_2567) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2569 = cute.get_leaves(%1025) : !cute.shape<"64">
        %1026 = cute.get_stride(%e0_2567) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2570 = cute.get_leaves(%1026) : !cute.stride<"1">
        %1027 = cute.get_shape(%e1_2568) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2571 = cute.get_leaves(%1027) : !cute.shape<"16">
        %1028 = cute.get_stride(%e1_2568) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2572 = cute.get_leaves(%1028) : !cute.stride<"1">
        %1029 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
        %1030 = cute.get_shape(%1029) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.shape<"((4,8,4),((2,2),(1,2)))">
        %e0_2573, %e1_2574, %e2_2575, %e3_2576, %e4_2577, %e5_2578, %e6_2579 = cute.get_leaves(%1030) : !cute.shape<"((4,8,4),((2,2),(1,2)))">
        %1031 = cute.get_stride(%1029) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.stride<"((128,1,16),((64,8),(0,512)))">
        %e0_2580, %e1_2581, %e2_2582, %e3_2583, %e4_2584, %e5_2585, %e6_2586 = cute.get_leaves(%1031) : !cute.stride<"((128,1,16),((64,8),(0,512)))">
        %1032 = cute.static : !cute.layout<"32:1">
        %1033 = cute.get_shape(%1032) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2587 = cute.get_leaves(%1033) : !cute.shape<"32">
        %1034 = cute.get_stride(%1032) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2588 = cute.get_leaves(%1034) : !cute.stride<"1">
        %1035 = cute.static : !cute.layout<"(32,8):(8,1)">
        %1036 = cute.get_shape(%1035) : (!cute.layout<"(32,8):(8,1)">) -> !cute.shape<"(32,8)">
        %e0_2589, %e1_2590 = cute.get_leaves(%1036) : !cute.shape<"(32,8)">
        %1037 = cute.get_stride(%1035) : (!cute.layout<"(32,8):(8,1)">) -> !cute.stride<"(8,1)">
        %e0_2591, %e1_2592 = cute.get_leaves(%1037) : !cute.stride<"(8,1)">
        %1038 = cute.static : !cute.layout<"(32,(2,4)):(2,(1,64))">
        %1039 = cute.get_shape(%1038) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.shape<"(32,(2,4))">
        %e0_2593, %e1_2594, %e2_2595 = cute.get_leaves(%1039) : !cute.shape<"(32,(2,4))">
        %1040 = cute.get_stride(%1038) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.stride<"(2,(1,64))">
        %e0_2596, %e1_2597, %e2_2598 = cute.get_leaves(%1040) : !cute.stride<"(2,(1,64))">
        scf.yield %969#1, %arg7 : !mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3
      }
      %lay_1365 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %rmem_1366 = cute.memref.alloca(%lay_1365) : !memref_rmem_bf16_21
      %iter_1367 = cute.get_iter(%rmem_1366) : !memref_rmem_bf16_21
      %iter_1368 = cute.get_iter(%rmem_1366) : !memref_rmem_bf16_21
      %lay_1369 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %730 = cute.get_shape(%lay_1369) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_1370, %e1_1371, %e2_1372, %e3_1373 = cute.get_leaves(%730) : !cute.shape<"((2,2),1,16)">
      %731 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %732 = arith.truncf %731 : vector<64xf32> to vector<64xbf16>
      %lay_1374 = cute.get_layout(%rmem_1366) : !memref_rmem_bf16_21
      %733 = cute.get_shape(%lay_1374) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_1375, %e1_1376, %e2_1377, %e3_1378 = cute.get_leaves(%733) : !cute.shape<"((2,2),1,16)">
      %int_tuple_1379 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_1380 = cute.size(%int_tuple_1379) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_1381 = cute.get_leaves(%sz_1380) : !cute.int_tuple<"64">
      %int_tuple_1382 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_1383 = cute.size(%int_tuple_1382) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_1384 = cute.get_leaves(%sz_1383) : !cute.int_tuple<"64">
      cute.memref.store_vec %732, %rmem_1366 : !memref_rmem_bf16_21
      %734 = cute.composed_get_inner(%3) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %iter_1385 = cute.recast_iter(%iter_277) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %735 = cute.composed_get_outer(%3) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %view_1386 = cute.make_view(%iter_1385, %735) : !memref_smem_bf16_23
      %iter_1387 = cute.get_iter(%view_1386) : !memref_smem_bf16_23
      %atom_1388 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %736 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %737 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1389, %e1_1390, %e2_1391 = cute.get_leaves(%737) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_1392 = cute.size(%e0_1389) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_1393 = cute.get_leaves(%sz_1392) : !cute.int_tuple<"64">
      %738 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1394, %e1_1395, %e2_1396 = cute.get_leaves(%738) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_1397 = cute.size(%e1_1395) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_1398 = cute.get_leaves(%sz_1397) : !cute.int_tuple<"16">
      %tile_1399 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %739 = cute.make_tiled_copy(%atom_1388) : !copy_simt1
      %retiled_1400 = cute.tiled.copy.retile(%739, %rmem_1366) : (!copy_simt1, !memref_rmem_bf16_21) -> !memref_rmem_bf16_22
      %iter_1401 = cute.get_iter(%retiled_1400) : !memref_rmem_bf16_22
      %coord_1402 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1403 = cute.tiled.copy.partition_D(%739, %view_1386, %coord_1402) : (!copy_simt1, !memref_smem_bf16_23, !cute.coord<"?">) -> !memref_smem_bf16_24
      %iter_1404 = cute.get_iter(%dst_partitioned_1403) : !memref_smem_bf16_24
      %lay_1405 = cute.get_layout(%retiled_1400) : !memref_rmem_bf16_22
      %740 = cute.get_shape(%lay_1405) : (!cute.layout<"((1,8),1,8):((0,1),0,8)">) -> !cute.shape<"((1,8),1,8)">
      %e0_1406, %e1_1407, %e2_1408, %e3_1409 = cute.get_leaves(%740) : !cute.shape<"((1,8),1,8)">
      %lay_1410 = cute.get_layout(%dst_partitioned_1403) : !memref_smem_bf16_24
      %741 = cute.get_shape(%lay_1410) : (!cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">) -> !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %e0_1411, %e1_1412, %e2_1413, %e3_1414, %e4_1415, %e5_1416, %e6_1417 = cute.get_leaves(%741) : !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %lay_1418 = cute.get_layout(%retiled_1400) : !memref_rmem_bf16_22
      %shape_1419 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1420 = cute.make_layout(%shape_1419) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_1418, %lay_1420) : !cute.layout<"((1,8),1,8):((0,1),0,8)">, !cute.layout<"1:0">
      %view_1421 = cute.make_view(%iter_1401, %append) : !memref_rmem_bf16_22
      %iter_1422 = cute.get_iter(%view_1421) : !memref_rmem_bf16_22
      %lay_1423 = cute.get_layout(%view_1421) : !memref_rmem_bf16_22
      %742 = cute.get_shape(%lay_1423) : (!cute.layout<"((1,8),1,8):((0,1),0,8)">) -> !cute.shape<"((1,8),1,8)">
      %e0_1424, %e1_1425, %e2_1426, %e3_1427 = cute.get_leaves(%742) : !cute.shape<"((1,8),1,8)">
      %grouped = cute.group_modes(%view_1421) <1, 3> : (!memref_rmem_bf16_22) -> !memref_rmem_bf16_23
      %iter_1428 = cute.get_iter(%grouped) : !memref_rmem_bf16_23
      %iter_1429 = cute.get_iter(%grouped) : !memref_rmem_bf16_23
      %lay_1430 = cute.get_layout(%dst_partitioned_1403) : !memref_smem_bf16_24
      %shape_1431 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1432 = cute.make_layout(%shape_1431) : !cute.layout<"1:0">
      %append_1433 = cute.append_to_rank<2> (%lay_1430, %lay_1432) : !cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">, !cute.layout<"1:0">
      %view_1434 = cute.make_view(%iter_1404, %append_1433) : !memref_smem_bf16_24
      %iter_1435 = cute.get_iter(%view_1434) : !memref_smem_bf16_24
      %lay_1436 = cute.get_layout(%view_1434) : !memref_smem_bf16_24
      %743 = cute.get_shape(%lay_1436) : (!cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">) -> !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %e0_1437, %e1_1438, %e2_1439, %e3_1440, %e4_1441, %e5_1442, %e6_1443 = cute.get_leaves(%743) : !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %grouped_1444 = cute.group_modes(%view_1434) <1, 3> : (!memref_smem_bf16_24) -> !memref_smem_bf16_25
      %iter_1445 = cute.get_iter(%grouped_1444) : !memref_smem_bf16_25
      %iter_1446 = cute.get_iter(%grouped_1444) : !memref_smem_bf16_25
      %lay_1447 = cute.get_layout(%grouped) : !memref_rmem_bf16_23
      %744 = cute.get_shape(%lay_1447) : (!cute.layout<"((1,8),(1,8)):((0,1),(0,8))">) -> !cute.shape<"((1,8),(1,8))">
      %e0_1448, %e1_1449, %e2_1450, %e3_1451 = cute.get_leaves(%744) : !cute.shape<"((1,8),(1,8))">
      %lay_1452 = cute.get_layout(%grouped_1444) : !memref_smem_bf16_25
      %745 = cute.get_shape(%lay_1452) : (!cute.layout<"((1,(2,2,2)),(1,(4,2))):((0,(1,512,8)),(0,(16,4096)))">) -> !cute.shape<"((1,(2,2,2)),(1,(4,2)))">
      %e0_1453, %e1_1454, %e2_1455, %e3_1456, %e4_1457, %e5_1458, %e6_1459 = cute.get_leaves(%745) : !cute.shape<"((1,(2,2,2)),(1,(4,2)))">
      %sz_1460 = cute.size(%grouped) <{mode = [1]}> : (!memref_rmem_bf16_23) -> !cute.int_tuple<"8">
      %e0_1461 = cute.get_leaves(%sz_1460) : !cute.int_tuple<"8">
      %sz_1462 = cute.size(%grouped_1444) <{mode = [1]}> : (!memref_smem_bf16_25) -> !cute.int_tuple<"8">
      %e0_1463 = cute.get_leaves(%sz_1462) : !cute.int_tuple<"8">
      cute.copy(%atom_1388, %grouped, %grouped_1444) : (!cute_nvgpu.atom.universal_copy<bf16>, !memref_rmem_bf16_23, !memref_smem_bf16_25)
      %coord_1464 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_1465 = cute.slice(%arg3, %coord_1464) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_1466 = cute.get_iter(%slice_1465) : !memref_gmem_bf16_1
      %iter_1467 = cute.get_iter(%slice_1465) : !memref_gmem_bf16_1
      %tile_1468 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_1469 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_1470 = cute.local_tile(%slice_1465, %tile_1468, %coord_1469) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_1471 = cute.get_iter(%tiled_view_1470) : !memref_gmem_bf16_2
      %coord_1472 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %src_partitioned_1473 = cute.tiled.copy.partition_S(%5, %view_1386, %coord_1472) : (!copy_simt, !memref_smem_bf16_23, !cute.coord<"?">) -> !memref_smem_bf16_26
      %iter_1474 = cute.get_iter(%src_partitioned_1473) : !memref_smem_bf16_26
      %coord_1475 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1476 = cute.tiled.copy.partition_D(%5, %tiled_view_1470, %coord_1475) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_1477 = cute.get_iter(%dst_partitioned_1476) : !memref_gmem_bf16_5
      %lay_1478 = cute.get_layout(%dst_partitioned_1476) : !memref_gmem_bf16_5
      %746 = cute.make_layout_like(%lay_1478) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)"> to !cute.layout<"((8,1),4,2):((1,0),16,8)">
      %rmem_1479 = cute.memref.alloca(%746) : !memref_rmem_bf16_24
      %iter_1480 = cute.get_iter(%rmem_1479) : !memref_rmem_bf16_24
      %iter_1481 = cute.get_iter(%rmem_1479) : !memref_rmem_bf16_24
      %c1_i32_1482 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_1482 number_of_threads = %c128_i32
      %lay_1483 = cute.get_layout(%src_partitioned_1473) : !memref_smem_bf16_26
      %747 = cute.get_shape(%lay_1483) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1484, %e1_1485, %e2_1486, %e3_1487 = cute.get_leaves(%747) : !cute.shape<"((8,1),4,2)">
      %lay_1488 = cute.get_layout(%rmem_1479) : !memref_rmem_bf16_24
      %748 = cute.get_shape(%lay_1488) : (!cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1489, %e1_1490, %e2_1491, %e3_1492 = cute.get_leaves(%748) : !cute.shape<"((8,1),4,2)">
      %lay_1493 = cute.get_layout(%src_partitioned_1473) : !memref_smem_bf16_26
      %shape_1494 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1495 = cute.make_layout(%shape_1494) : !cute.layout<"1:0">
      %append_1496 = cute.append_to_rank<2> (%lay_1493, %lay_1495) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
      %view_1497 = cute.make_view(%iter_1474, %append_1496) : !memref_smem_bf16_26
      %iter_1498 = cute.get_iter(%view_1497) : !memref_smem_bf16_26
      %lay_1499 = cute.get_layout(%view_1497) : !memref_smem_bf16_26
      %749 = cute.get_shape(%lay_1499) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1500, %e1_1501, %e2_1502, %e3_1503 = cute.get_leaves(%749) : !cute.shape<"((8,1),4,2)">
      %grouped_1504 = cute.group_modes(%view_1497) <1, 3> : (!memref_smem_bf16_26) -> !memref_smem_bf16_27
      %iter_1505 = cute.get_iter(%grouped_1504) : !memref_smem_bf16_27
      %iter_1506 = cute.get_iter(%grouped_1504) : !memref_smem_bf16_27
      %lay_1507 = cute.get_layout(%rmem_1479) : !memref_rmem_bf16_24
      %shape_1508 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1509 = cute.make_layout(%shape_1508) : !cute.layout<"1:0">
      %append_1510 = cute.append_to_rank<2> (%lay_1507, %lay_1509) : !cute.layout<"((8,1),4,2):((1,0),16,8)">, !cute.layout<"1:0">
      %view_1511 = cute.make_view(%iter_1481, %append_1510) : !memref_rmem_bf16_24
      %iter_1512 = cute.get_iter(%view_1511) : !memref_rmem_bf16_24
      %lay_1513 = cute.get_layout(%view_1511) : !memref_rmem_bf16_24
      %750 = cute.get_shape(%lay_1513) : (!cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1514, %e1_1515, %e2_1516, %e3_1517 = cute.get_leaves(%750) : !cute.shape<"((8,1),4,2)">
      %grouped_1518 = cute.group_modes(%view_1511) <1, 3> : (!memref_rmem_bf16_24) -> !memref_rmem_bf16_25
      %iter_1519 = cute.get_iter(%grouped_1518) : !memref_rmem_bf16_25
      %iter_1520 = cute.get_iter(%grouped_1518) : !memref_rmem_bf16_25
      %lay_1521 = cute.get_layout(%grouped_1504) : !memref_smem_bf16_27
      %751 = cute.get_shape(%lay_1521) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
      %e0_1522, %e1_1523, %e2_1524, %e3_1525 = cute.get_leaves(%751) : !cute.shape<"((8,1),(4,2))">
      %lay_1526 = cute.get_layout(%grouped_1518) : !memref_rmem_bf16_25
      %752 = cute.get_shape(%lay_1526) : (!cute.layout<"((8,1),(4,2)):((1,0),(16,8))">) -> !cute.shape<"((8,1),(4,2))">
      %e0_1527, %e1_1528, %e2_1529, %e3_1530 = cute.get_leaves(%752) : !cute.shape<"((8,1),(4,2))">
      %sz_1531 = cute.size(%grouped_1504) <{mode = [1]}> : (!memref_smem_bf16_27) -> !cute.int_tuple<"8">
      %e0_1532 = cute.get_leaves(%sz_1531) : !cute.int_tuple<"8">
      %sz_1533 = cute.size(%grouped_1518) <{mode = [1]}> : (!memref_rmem_bf16_25) -> !cute.int_tuple<"8">
      %e0_1534 = cute.get_leaves(%sz_1533) : !cute.int_tuple<"8">
      cute.copy(%5, %grouped_1504, %grouped_1518) : (!copy_simt, !memref_smem_bf16_27, !memref_rmem_bf16_25)
      %lay_1535 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %753 = cute.get_shape(%lay_1535) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1536, %e1_1537, %e2_1538, %e3_1539 = cute.get_leaves(%753) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1540 = cute.to_int_tuple(%e0_1536) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %754 = cute.get_scalars(%itup_1540) : !cute.int_tuple<"?">
      %itup_1541 = cute.to_int_tuple(%e1_1537) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %755 = cute.get_scalars(%itup_1541) : !cute.int_tuple<"?">
      %itup_1542 = cute.to_int_tuple(%e2_1538) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %756 = cute.get_scalars(%itup_1542) : !cute.int_tuple<"?">
      %itup_1543 = cute.to_int_tuple(%e3_1539) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %757 = cute.get_scalars(%itup_1543) : !cute.int_tuple<"?{div=8}">
      %shape_1544 = cute.make_shape(%itup_1540, %itup_1541, %itup_1542, %itup_1543) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %758 = cute.make_identity_tensor(%shape_1544) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_1545 = cute.get_iter(%758) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_1546, %e1_1547, %e2_1548, %e3_1549 = cute.get_leaves(%iter_1545) : !cute.int_tuple<"(0,0,0,0)">
      %coord_1550 = cute.make_coord(%132, %133) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_1551 = cute.slice(%758, %coord_1550) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_1552 = cute.get_iter(%slice_1551) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_1553, %e1_1554, %e2_1555, %e3_1556 = cute.get_leaves(%iter_1552) : !cute.int_tuple<"(?,0,?,0)">
      %759 = cute.get_scalars(%e0_1553) : !cute.int_tuple<"?">
      %760 = cute.get_scalars(%e2_1555) : !cute.int_tuple<"?">
      %iter_1557 = cute.get_iter(%slice_1551) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_1558, %e1_1559, %e2_1560, %e3_1561 = cute.get_leaves(%iter_1557) : !cute.int_tuple<"(?,0,?,0)">
      %761 = cute.get_scalars(%e0_1558) : !cute.int_tuple<"?">
      %762 = cute.get_scalars(%e2_1560) : !cute.int_tuple<"?">
      %tile_1562 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_1563 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_1564 = cute.local_tile(%slice_1551, %tile_1562, %coord_1563) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_1565 = cute.get_iter(%tiled_view_1564) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_1566, %e1_1567, %e2_1568, %e3_1569 = cute.get_leaves(%iter_1565) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %763 = cute.get_scalars(%e0_1566) : !cute.int_tuple<"?">
      %764 = cute.get_scalars(%e1_1567) : !cute.int_tuple<"?{div=64}">
      %765 = cute.get_scalars(%e2_1568) : !cute.int_tuple<"?">
      %coord_1570 = cute.make_coord(%129) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1571 = cute.tiled.copy.partition_D(%5, %tiled_view_1564, %coord_1570) : (!copy_simt, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_1572 = cute.get_iter(%dst_partitioned_1571) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_1573, %e1_1574, %e2_1575, %e3_1576 = cute.get_leaves(%iter_1572) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %766 = cute.get_scalars(%e0_1573) : !cute.int_tuple<"?">
      %767 = cute.get_scalars(%e1_1574) : !cute.int_tuple<"?">
      %768 = cute.get_scalars(%e2_1575) : !cute.int_tuple<"?">
      %769 = cute.get_scalars(%e3_1576) : !cute.int_tuple<"?{div=8}">
      %lay_1577 = cute.get_layout(%dst_partitioned_1476) : !memref_gmem_bf16_5
      %770 = cute.get_shape(%lay_1577) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1578, %e1_1579, %e2_1580, %e3_1581 = cute.get_leaves(%770) : !cute.shape<"((8,1),4,2)">
      %shape_1582 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_1583 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_1584 = cute.make_layout(%shape_1582, %stride_1583) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_1585 = cute.memref.alloca(%lay_1584) : !memref_rmem_i8_
      %iter_1586 = cute.get_iter(%rmem_1585) : !memref_rmem_i8_
      %iter_1587 = cute.get_iter(%rmem_1585) : !memref_rmem_i8_
      %lay_1588 = cute.get_layout(%rmem_1585) : !memref_rmem_i8_
      %771 = cute.get_shape(%lay_1588) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_1589, %e1_1590, %e2_1591 = cute.get_leaves(%771) : !cute.shape<"(1,4,2)">
      %int_tuple_1592 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_1593 = cute.size(%int_tuple_1592) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_1594 = cute.get_leaves(%sz_1593) : !cute.int_tuple<"2">
      %coord_1595 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_1596 = cute.slice(%dst_partitioned_1571, %coord_1595) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_1597 = cute.get_iter(%slice_1596) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1598, %e1_1599, %e2_1600, %e3_1601 = cute.get_leaves(%iter_1597) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %772 = cute.get_scalars(%e0_1598) : !cute.int_tuple<"?">
      %773 = cute.get_scalars(%e1_1599) : !cute.int_tuple<"?">
      %774 = cute.get_scalars(%e2_1600) : !cute.int_tuple<"?">
      %775 = cute.get_scalars(%e3_1601) : !cute.int_tuple<"?{div=8}">
      %iter_1602 = cute.get_iter(%slice_1596) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1603, %e1_1604, %e2_1605, %e3_1606 = cute.get_leaves(%iter_1602) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %776 = cute.get_scalars(%e0_1603) : !cute.int_tuple<"?">
      %777 = cute.get_scalars(%e1_1604) : !cute.int_tuple<"?">
      %778 = cute.get_scalars(%e2_1605) : !cute.int_tuple<"?">
      %779 = cute.get_scalars(%e3_1606) : !cute.int_tuple<"?{div=8}">
      %iter_1607 = cute.get_iter(%slice_1596) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1608, %e1_1609, %e2_1610, %e3_1611 = cute.get_leaves(%iter_1607) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %780 = cute.get_scalars(%e0_1608) : !cute.int_tuple<"?">
      %781 = cute.get_scalars(%e1_1609) : !cute.int_tuple<"?">
      %782 = cute.get_scalars(%e2_1610) : !cute.int_tuple<"?">
      %783 = cute.get_scalars(%e3_1611) : !cute.int_tuple<"?{div=8}">
      %lay_1612 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %784 = cute.get_shape(%lay_1612) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1613, %e1_1614, %e2_1615, %e3_1616 = cute.get_leaves(%784) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1617 = cute.to_int_tuple(%e0_1613) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %785 = cute.get_scalars(%itup_1617) : !cute.int_tuple<"?">
      %itup_1618 = cute.to_int_tuple(%e1_1614) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %786 = cute.get_scalars(%itup_1618) : !cute.int_tuple<"?">
      %itup_1619 = cute.to_int_tuple(%e2_1615) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %787 = cute.get_scalars(%itup_1619) : !cute.int_tuple<"?">
      %itup_1620 = cute.to_int_tuple(%e3_1616) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %788 = cute.get_scalars(%itup_1620) : !cute.int_tuple<"?{div=8}">
      %coord_1621 = cute.make_coord(%e3_1611) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1622 = cute.make_coord(%itup_1620) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %789 = cute.elem_less(%coord_1621, %coord_1622) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %790 = arith.extui %789 : i1 to i8
      %coord_1623 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_1585, %coord_1623, %790) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_1624 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_1625 = cute.slice(%dst_partitioned_1571, %coord_1624) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_1626 = cute.get_iter(%slice_1625) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1627, %e1_1628, %e2_1629, %e3_1630 = cute.get_leaves(%iter_1626) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %791 = cute.get_scalars(%e0_1627) : !cute.int_tuple<"?">
      %792 = cute.get_scalars(%e1_1628) : !cute.int_tuple<"?">
      %793 = cute.get_scalars(%e2_1629) : !cute.int_tuple<"?">
      %794 = cute.get_scalars(%e3_1630) : !cute.int_tuple<"?{div=8}">
      %iter_1631 = cute.get_iter(%slice_1625) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1632, %e1_1633, %e2_1634, %e3_1635 = cute.get_leaves(%iter_1631) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %795 = cute.get_scalars(%e0_1632) : !cute.int_tuple<"?">
      %796 = cute.get_scalars(%e1_1633) : !cute.int_tuple<"?">
      %797 = cute.get_scalars(%e2_1634) : !cute.int_tuple<"?">
      %798 = cute.get_scalars(%e3_1635) : !cute.int_tuple<"?{div=8}">
      %iter_1636 = cute.get_iter(%slice_1625) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1637, %e1_1638, %e2_1639, %e3_1640 = cute.get_leaves(%iter_1636) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %799 = cute.get_scalars(%e0_1637) : !cute.int_tuple<"?">
      %800 = cute.get_scalars(%e1_1638) : !cute.int_tuple<"?">
      %801 = cute.get_scalars(%e2_1639) : !cute.int_tuple<"?">
      %802 = cute.get_scalars(%e3_1640) : !cute.int_tuple<"?{div=8}">
      %lay_1641 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %803 = cute.get_shape(%lay_1641) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1642, %e1_1643, %e2_1644, %e3_1645 = cute.get_leaves(%803) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1646 = cute.to_int_tuple(%e0_1642) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %804 = cute.get_scalars(%itup_1646) : !cute.int_tuple<"?">
      %itup_1647 = cute.to_int_tuple(%e1_1643) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %805 = cute.get_scalars(%itup_1647) : !cute.int_tuple<"?">
      %itup_1648 = cute.to_int_tuple(%e2_1644) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %806 = cute.get_scalars(%itup_1648) : !cute.int_tuple<"?">
      %itup_1649 = cute.to_int_tuple(%e3_1645) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %807 = cute.get_scalars(%itup_1649) : !cute.int_tuple<"?{div=8}">
      %coord_1650 = cute.make_coord(%e3_1640) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1651 = cute.make_coord(%itup_1649) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %808 = cute.elem_less(%coord_1650, %coord_1651) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %809 = arith.extui %808 : i1 to i8
      %coord_1652 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_1585, %coord_1652, %809) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %int_tuple_1653 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_1654 = cute.size(%int_tuple_1653) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_1655 = cute.get_leaves(%sz_1654) : !cute.int_tuple<"4">
      %coord_1656 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_1657 = cute.slice(%dst_partitioned_1571, %coord_1656) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_1658 = cute.get_iter(%slice_1657) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1659, %e1_1660, %e2_1661, %e3_1662 = cute.get_leaves(%iter_1658) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %810 = cute.get_scalars(%e0_1659) : !cute.int_tuple<"?">
      %811 = cute.get_scalars(%e1_1660) : !cute.int_tuple<"?">
      %812 = cute.get_scalars(%e2_1661) : !cute.int_tuple<"?">
      %813 = cute.get_scalars(%e3_1662) : !cute.int_tuple<"?{div=8}">
      %iter_1663 = cute.get_iter(%slice_1657) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1664, %e1_1665, %e2_1666, %e3_1667 = cute.get_leaves(%iter_1663) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %814 = cute.get_scalars(%e0_1664) : !cute.int_tuple<"?">
      %815 = cute.get_scalars(%e1_1665) : !cute.int_tuple<"?">
      %816 = cute.get_scalars(%e2_1666) : !cute.int_tuple<"?">
      %817 = cute.get_scalars(%e3_1667) : !cute.int_tuple<"?{div=8}">
      %iter_1668 = cute.get_iter(%slice_1657) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1669, %e1_1670, %e2_1671, %e3_1672 = cute.get_leaves(%iter_1668) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %818 = cute.get_scalars(%e0_1669) : !cute.int_tuple<"?">
      %819 = cute.get_scalars(%e1_1670) : !cute.int_tuple<"?">
      %820 = cute.get_scalars(%e2_1671) : !cute.int_tuple<"?">
      %821 = cute.get_scalars(%e3_1672) : !cute.int_tuple<"?{div=8}">
      %lay_1673 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %822 = cute.get_shape(%lay_1673) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1674, %e1_1675, %e2_1676, %e3_1677 = cute.get_leaves(%822) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1678 = cute.to_int_tuple(%e0_1674) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %823 = cute.get_scalars(%itup_1678) : !cute.int_tuple<"?">
      %itup_1679 = cute.to_int_tuple(%e1_1675) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %824 = cute.get_scalars(%itup_1679) : !cute.int_tuple<"?">
      %itup_1680 = cute.to_int_tuple(%e2_1676) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %825 = cute.get_scalars(%itup_1680) : !cute.int_tuple<"?">
      %itup_1681 = cute.to_int_tuple(%e3_1677) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %826 = cute.get_scalars(%itup_1681) : !cute.int_tuple<"?{div=8}">
      %coord_1682 = cute.make_coord(%e1_1670) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1683 = cute.make_coord(%itup_1679) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %827 = cute.elem_less(%coord_1682, %coord_1683) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %827 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1769 = cute.slice(%rmem_1479, %coord_1768) : !memref_rmem_bf16_24, !cute.coord<"(_,0,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1773 = cute.slice(%dst_partitioned_1476, %coord_1772) : !memref_gmem_bf16_5, !cute.coord<"(_,0,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1777 = cute.slice(%rmem_1585, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_rmem_bf16_26
        %iter_1793 = cute.get_iter(%view_1792) : !memref_rmem_bf16_26
        %lay_1794 = cute.get_layout(%view_1792) : !memref_rmem_bf16_26
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_gmem_bf16_8
        %iter_1806 = cute.get_iter(%view_1805) : !memref_gmem_bf16_8
        %lay_1807 = cute.get_layout(%view_1805) : !memref_gmem_bf16_8
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_rmem_bf16_27
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_gmem_bf16_9
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%5, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1684 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_1685 = cute.slice(%dst_partitioned_1571, %coord_1684) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_1686 = cute.get_iter(%slice_1685) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1687, %e1_1688, %e2_1689, %e3_1690 = cute.get_leaves(%iter_1686) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %828 = cute.get_scalars(%e0_1687) : !cute.int_tuple<"?">
      %829 = cute.get_scalars(%e1_1688) : !cute.int_tuple<"?">
      %830 = cute.get_scalars(%e2_1689) : !cute.int_tuple<"?">
      %831 = cute.get_scalars(%e3_1690) : !cute.int_tuple<"?{div=8}">
      %iter_1691 = cute.get_iter(%slice_1685) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1692, %e1_1693, %e2_1694, %e3_1695 = cute.get_leaves(%iter_1691) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %832 = cute.get_scalars(%e0_1692) : !cute.int_tuple<"?">
      %833 = cute.get_scalars(%e1_1693) : !cute.int_tuple<"?">
      %834 = cute.get_scalars(%e2_1694) : !cute.int_tuple<"?">
      %835 = cute.get_scalars(%e3_1695) : !cute.int_tuple<"?{div=8}">
      %iter_1696 = cute.get_iter(%slice_1685) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1697, %e1_1698, %e2_1699, %e3_1700 = cute.get_leaves(%iter_1696) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %836 = cute.get_scalars(%e0_1697) : !cute.int_tuple<"?">
      %837 = cute.get_scalars(%e1_1698) : !cute.int_tuple<"?">
      %838 = cute.get_scalars(%e2_1699) : !cute.int_tuple<"?">
      %839 = cute.get_scalars(%e3_1700) : !cute.int_tuple<"?{div=8}">
      %lay_1701 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %840 = cute.get_shape(%lay_1701) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1702, %e1_1703, %e2_1704, %e3_1705 = cute.get_leaves(%840) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1706 = cute.to_int_tuple(%e0_1702) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %841 = cute.get_scalars(%itup_1706) : !cute.int_tuple<"?">
      %itup_1707 = cute.to_int_tuple(%e1_1703) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %842 = cute.get_scalars(%itup_1707) : !cute.int_tuple<"?">
      %itup_1708 = cute.to_int_tuple(%e2_1704) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %843 = cute.get_scalars(%itup_1708) : !cute.int_tuple<"?">
      %itup_1709 = cute.to_int_tuple(%e3_1705) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %844 = cute.get_scalars(%itup_1709) : !cute.int_tuple<"?{div=8}">
      %coord_1710 = cute.make_coord(%e1_1698) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1711 = cute.make_coord(%itup_1707) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %845 = cute.elem_less(%coord_1710, %coord_1711) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %845 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1769 = cute.slice(%rmem_1479, %coord_1768) : !memref_rmem_bf16_24, !cute.coord<"(_,1,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1773 = cute.slice(%dst_partitioned_1476, %coord_1772) : !memref_gmem_bf16_5, !cute.coord<"(_,1,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1777 = cute.slice(%rmem_1585, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_rmem_bf16_26
        %iter_1793 = cute.get_iter(%view_1792) : !memref_rmem_bf16_26
        %lay_1794 = cute.get_layout(%view_1792) : !memref_rmem_bf16_26
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_gmem_bf16_8
        %iter_1806 = cute.get_iter(%view_1805) : !memref_gmem_bf16_8
        %lay_1807 = cute.get_layout(%view_1805) : !memref_gmem_bf16_8
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_rmem_bf16_27
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_gmem_bf16_9
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%5, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1712 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_1713 = cute.slice(%dst_partitioned_1571, %coord_1712) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_1714 = cute.get_iter(%slice_1713) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1715, %e1_1716, %e2_1717, %e3_1718 = cute.get_leaves(%iter_1714) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %846 = cute.get_scalars(%e0_1715) : !cute.int_tuple<"?">
      %847 = cute.get_scalars(%e1_1716) : !cute.int_tuple<"?">
      %848 = cute.get_scalars(%e2_1717) : !cute.int_tuple<"?">
      %849 = cute.get_scalars(%e3_1718) : !cute.int_tuple<"?{div=8}">
      %iter_1719 = cute.get_iter(%slice_1713) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1720, %e1_1721, %e2_1722, %e3_1723 = cute.get_leaves(%iter_1719) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %850 = cute.get_scalars(%e0_1720) : !cute.int_tuple<"?">
      %851 = cute.get_scalars(%e1_1721) : !cute.int_tuple<"?">
      %852 = cute.get_scalars(%e2_1722) : !cute.int_tuple<"?">
      %853 = cute.get_scalars(%e3_1723) : !cute.int_tuple<"?{div=8}">
      %iter_1724 = cute.get_iter(%slice_1713) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1725, %e1_1726, %e2_1727, %e3_1728 = cute.get_leaves(%iter_1724) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %854 = cute.get_scalars(%e0_1725) : !cute.int_tuple<"?">
      %855 = cute.get_scalars(%e1_1726) : !cute.int_tuple<"?">
      %856 = cute.get_scalars(%e2_1727) : !cute.int_tuple<"?">
      %857 = cute.get_scalars(%e3_1728) : !cute.int_tuple<"?{div=8}">
      %lay_1729 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %858 = cute.get_shape(%lay_1729) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1730, %e1_1731, %e2_1732, %e3_1733 = cute.get_leaves(%858) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1734 = cute.to_int_tuple(%e0_1730) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %859 = cute.get_scalars(%itup_1734) : !cute.int_tuple<"?">
      %itup_1735 = cute.to_int_tuple(%e1_1731) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %860 = cute.get_scalars(%itup_1735) : !cute.int_tuple<"?">
      %itup_1736 = cute.to_int_tuple(%e2_1732) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %861 = cute.get_scalars(%itup_1736) : !cute.int_tuple<"?">
      %itup_1737 = cute.to_int_tuple(%e3_1733) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %862 = cute.get_scalars(%itup_1737) : !cute.int_tuple<"?{div=8}">
      %coord_1738 = cute.make_coord(%e1_1726) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1739 = cute.make_coord(%itup_1735) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %863 = cute.elem_less(%coord_1738, %coord_1739) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %863 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1769 = cute.slice(%rmem_1479, %coord_1768) : !memref_rmem_bf16_24, !cute.coord<"(_,2,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1773 = cute.slice(%dst_partitioned_1476, %coord_1772) : !memref_gmem_bf16_5, !cute.coord<"(_,2,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1777 = cute.slice(%rmem_1585, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_rmem_bf16_26
        %iter_1793 = cute.get_iter(%view_1792) : !memref_rmem_bf16_26
        %lay_1794 = cute.get_layout(%view_1792) : !memref_rmem_bf16_26
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_gmem_bf16_8
        %iter_1806 = cute.get_iter(%view_1805) : !memref_gmem_bf16_8
        %lay_1807 = cute.get_layout(%view_1805) : !memref_gmem_bf16_8
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_rmem_bf16_27
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_gmem_bf16_9
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%5, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1740 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_1741 = cute.slice(%dst_partitioned_1571, %coord_1740) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_1742 = cute.get_iter(%slice_1741) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1743, %e1_1744, %e2_1745, %e3_1746 = cute.get_leaves(%iter_1742) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %864 = cute.get_scalars(%e0_1743) : !cute.int_tuple<"?">
      %865 = cute.get_scalars(%e1_1744) : !cute.int_tuple<"?">
      %866 = cute.get_scalars(%e2_1745) : !cute.int_tuple<"?">
      %867 = cute.get_scalars(%e3_1746) : !cute.int_tuple<"?{div=8}">
      %iter_1747 = cute.get_iter(%slice_1741) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1748, %e1_1749, %e2_1750, %e3_1751 = cute.get_leaves(%iter_1747) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %868 = cute.get_scalars(%e0_1748) : !cute.int_tuple<"?">
      %869 = cute.get_scalars(%e1_1749) : !cute.int_tuple<"?">
      %870 = cute.get_scalars(%e2_1750) : !cute.int_tuple<"?">
      %871 = cute.get_scalars(%e3_1751) : !cute.int_tuple<"?{div=8}">
      %iter_1752 = cute.get_iter(%slice_1741) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1753, %e1_1754, %e2_1755, %e3_1756 = cute.get_leaves(%iter_1752) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %872 = cute.get_scalars(%e0_1753) : !cute.int_tuple<"?">
      %873 = cute.get_scalars(%e1_1754) : !cute.int_tuple<"?">
      %874 = cute.get_scalars(%e2_1755) : !cute.int_tuple<"?">
      %875 = cute.get_scalars(%e3_1756) : !cute.int_tuple<"?{div=8}">
      %lay_1757 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %876 = cute.get_shape(%lay_1757) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1758, %e1_1759, %e2_1760, %e3_1761 = cute.get_leaves(%876) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1762 = cute.to_int_tuple(%e0_1758) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %877 = cute.get_scalars(%itup_1762) : !cute.int_tuple<"?">
      %itup_1763 = cute.to_int_tuple(%e1_1759) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %878 = cute.get_scalars(%itup_1763) : !cute.int_tuple<"?">
      %itup_1764 = cute.to_int_tuple(%e2_1760) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %879 = cute.get_scalars(%itup_1764) : !cute.int_tuple<"?">
      %itup_1765 = cute.to_int_tuple(%e3_1761) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %880 = cute.get_scalars(%itup_1765) : !cute.int_tuple<"?{div=8}">
      %coord_1766 = cute.make_coord(%e1_1754) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1767 = cute.make_coord(%itup_1763) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %881 = cute.elem_less(%coord_1766, %coord_1767) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %881 {
        %coord_1768 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1769 = cute.slice(%rmem_1479, %coord_1768) : !memref_rmem_bf16_24, !cute.coord<"(_,3,_)">
        %iter_1770 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %iter_1771 = cute.get_iter(%slice_1769) : !memref_rmem_bf16_26
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1773 = cute.slice(%dst_partitioned_1476, %coord_1772) : !memref_gmem_bf16_5, !cute.coord<"(_,3,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %iter_1775 = cute.get_iter(%slice_1773) : !memref_gmem_bf16_8
        %coord_1776 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1777 = cute.slice(%rmem_1585, %coord_1776) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1778 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %iter_1779 = cute.get_iter(%slice_1777) : !memref_rmem_i8_1
        %lay_1780 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %882 = cute.get_shape(%lay_1780) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1781, %e1_1782, %e2_1783 = cute.get_leaves(%882) : !cute.shape<"((8,1),2)">
        %lay_1784 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %883 = cute.get_shape(%lay_1784) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1785, %e1_1786, %e2_1787 = cute.get_leaves(%883) : !cute.shape<"((8,1),2)">
        %lay_1788 = cute.get_layout(%slice_1769) : !memref_rmem_bf16_26
        %shape_1789 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1790 = cute.make_layout(%shape_1789) : !cute.layout<"1:0">
        %append_1791 = cute.append_to_rank<2> (%lay_1788, %lay_1790) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1792 = cute.make_view(%iter_1771, %append_1791) : !memref_rmem_bf16_26
        %iter_1793 = cute.get_iter(%view_1792) : !memref_rmem_bf16_26
        %lay_1794 = cute.get_layout(%view_1792) : !memref_rmem_bf16_26
        %884 = cute.get_shape(%lay_1794) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1795, %e1_1796, %e2_1797 = cute.get_leaves(%884) : !cute.shape<"((8,1),2)">
        %grouped_1798 = cute.group_modes(%view_1792) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_rmem_bf16_27
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_gmem_bf16_8
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1775, %append_1804) : !memref_gmem_bf16_8
        %iter_1806 = cute.get_iter(%view_1805) : !memref_gmem_bf16_8
        %lay_1807 = cute.get_layout(%view_1805) : !memref_gmem_bf16_8
        %885 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1808, %e1_1809, %e2_1810 = cute.get_leaves(%885) : !cute.shape<"((8,1),2)">
        %grouped_1811 = cute.group_modes(%view_1805) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1812 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %iter_1813 = cute.get_iter(%grouped_1811) : !memref_gmem_bf16_9
        %lay_1814 = cute.get_layout(%slice_1777) : !memref_rmem_i8_1
        %shape_1815 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1816 = cute.make_layout(%shape_1815) : !cute.layout<"1:0">
        %append_1817 = cute.append_to_rank<2> (%lay_1814, %lay_1816) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1818 = cute.make_view(%iter_1779, %append_1817) : !memref_rmem_i8_1
        %iter_1819 = cute.get_iter(%view_1818) : !memref_rmem_i8_1
        %lay_1820 = cute.get_layout(%view_1818) : !memref_rmem_i8_1
        %886 = cute.get_shape(%lay_1820) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1821, %e1_1822 = cute.get_leaves(%886) : !cute.shape<"(1,2)">
        %grouped_1823 = cute.group_modes(%view_1818) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1824 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %iter_1825 = cute.get_iter(%grouped_1823) : !memref_rmem_i8_2
        %lay_1826 = cute.get_layout(%grouped_1798) : !memref_rmem_bf16_27
        %887 = cute.get_shape(%lay_1826) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1827, %e1_1828, %e2_1829 = cute.get_leaves(%887) : !cute.shape<"((8,1),(2))">
        %lay_1830 = cute.get_layout(%grouped_1811) : !memref_gmem_bf16_9
        %888 = cute.get_shape(%lay_1830) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1831, %e1_1832, %e2_1833 = cute.get_leaves(%888) : !cute.shape<"((8,1),(2))">
        %sz_1834 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1835 = cute.get_leaves(%sz_1834) : !cute.int_tuple<"2">
        %sz_1836 = cute.size(%grouped_1811) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1837 = cute.get_leaves(%sz_1836) : !cute.int_tuple<"2">
        cute.copy(%5, %grouped_1798, %grouped_1811, %grouped_1823) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      return
    }
  }
  func.func @cutlass___call_____main__HSTUAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Ten(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_bf16_
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_bf16_
    %iter_2 = cute.get_iter(%arg3) : !memref_gmem_bf16_
    %iter_3 = cute.get_iter(%arg4) : !memref_gmem_bf16_
    %iter_4 = cute.get_iter(%arg0) : !memref_gmem_bf16_
    %iter_5 = cute.get_iter(%arg1) : !memref_gmem_bf16_
    %iter_6 = cute.get_iter(%arg2) : !memref_gmem_bf16_
    %iter_7 = cute.get_iter(%arg3) : !memref_gmem_bf16_
    %iter_8 = cute.get_iter(%arg4) : !memref_gmem_bf16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0, %e1, %e2, %e3 = cute.get_leaves(%0) : !cute.shape<"(?,?,?,?{div=8})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_9 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?">
    %itup_10 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
    %itup_11 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?{div=8}">
    %5 = cute.get_stride(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_12, %e1_13, %e2_14, %e3_15 = cute.get_leaves(%5) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_16 = cute.to_int_tuple(%e0_12) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %6 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?{i64 div=8}">
    %itup_17 = cute.to_int_tuple(%e1_13) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %7 = cute.get_scalars(%itup_17) : !cute.int_tuple<"?{i64 div=8}">
    %itup_18 = cute.to_int_tuple(%e2_14) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %8 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?{i64 div=8}">
    %lay_19 = cute.get_layout(%arg1) : !memref_gmem_bf16_
    %9 = cute.get_shape(%lay_19) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_20, %e1_21, %e2_22, %e3_23 = cute.get_leaves(%9) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_24 = cute.to_int_tuple(%e0_20) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?">
    %itup_25 = cute.to_int_tuple(%e1_21) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %11 = cute.get_scalars(%itup_25) : !cute.int_tuple<"?">
    %itup_26 = cute.to_int_tuple(%e2_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %12 = cute.get_scalars(%itup_26) : !cute.int_tuple<"?">
    %itup_27 = cute.to_int_tuple(%e3_23) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %13 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?{div=8}">
    %14 = cute.get_stride(%lay_19) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_28, %e1_29, %e2_30, %e3_31 = cute.get_leaves(%14) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_32 = cute.to_int_tuple(%e0_28) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %15 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?{i64 div=8}">
    %itup_33 = cute.to_int_tuple(%e1_29) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %16 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?{i64 div=8}">
    %itup_34 = cute.to_int_tuple(%e2_30) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %17 = cute.get_scalars(%itup_34) : !cute.int_tuple<"?{i64 div=8}">
    %lay_35 = cute.get_layout(%arg2) : !memref_gmem_bf16_
    %18 = cute.get_shape(%lay_35) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_36, %e1_37, %e2_38, %e3_39 = cute.get_leaves(%18) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_40 = cute.to_int_tuple(%e0_36) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_40) : !cute.int_tuple<"?">
    %itup_41 = cute.to_int_tuple(%e1_37) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %20 = cute.get_scalars(%itup_41) : !cute.int_tuple<"?">
    %itup_42 = cute.to_int_tuple(%e2_38) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %21 = cute.get_scalars(%itup_42) : !cute.int_tuple<"?">
    %itup_43 = cute.to_int_tuple(%e3_39) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %22 = cute.get_scalars(%itup_43) : !cute.int_tuple<"?{div=8}">
    %23 = cute.get_stride(%lay_35) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_44, %e1_45, %e2_46, %e3_47 = cute.get_leaves(%23) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_48 = cute.to_int_tuple(%e0_44) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %24 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?{i64 div=8}">
    %itup_49 = cute.to_int_tuple(%e1_45) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %25 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?{i64 div=8}">
    %itup_50 = cute.to_int_tuple(%e2_46) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %26 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?{i64 div=8}">
    %lay_51 = cute.get_layout(%arg3) : !memref_gmem_bf16_
    %27 = cute.get_shape(%lay_51) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_52, %e1_53, %e2_54, %e3_55 = cute.get_leaves(%27) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_56 = cute.to_int_tuple(%e0_52) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %28 = cute.get_scalars(%itup_56) : !cute.int_tuple<"?">
    %itup_57 = cute.to_int_tuple(%e1_53) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %29 = cute.get_scalars(%itup_57) : !cute.int_tuple<"?">
    %itup_58 = cute.to_int_tuple(%e2_54) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %30 = cute.get_scalars(%itup_58) : !cute.int_tuple<"?">
    %itup_59 = cute.to_int_tuple(%e3_55) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %31 = cute.get_scalars(%itup_59) : !cute.int_tuple<"?{div=8}">
    %32 = cute.get_stride(%lay_51) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_60, %e1_61, %e2_62, %e3_63 = cute.get_leaves(%32) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_64 = cute.to_int_tuple(%e0_60) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %33 = cute.get_scalars(%itup_64) : !cute.int_tuple<"?{i64 div=8}">
    %itup_65 = cute.to_int_tuple(%e1_61) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %34 = cute.get_scalars(%itup_65) : !cute.int_tuple<"?{i64 div=8}">
    %itup_66 = cute.to_int_tuple(%e2_62) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %35 = cute.get_scalars(%itup_66) : !cute.int_tuple<"?{i64 div=8}">
    %lay_67 = cute.get_layout(%arg4) : !memref_gmem_bf16_
    %36 = cute.get_shape(%lay_67) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_68, %e1_69, %e2_70, %e3_71 = cute.get_leaves(%36) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_72 = cute.to_int_tuple(%e0_68) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_72) : !cute.int_tuple<"?">
    %itup_73 = cute.to_int_tuple(%e1_69) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_73) : !cute.int_tuple<"?">
    %itup_74 = cute.to_int_tuple(%e2_70) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_74) : !cute.int_tuple<"?">
    %itup_75 = cute.to_int_tuple(%e3_71) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %40 = cute.get_scalars(%itup_75) : !cute.int_tuple<"?{div=8}">
    %41 = cute.get_stride(%lay_67) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_76, %e1_77, %e2_78, %e3_79 = cute.get_leaves(%41) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_80 = cute.to_int_tuple(%e0_76) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %42 = cute.get_scalars(%itup_80) : !cute.int_tuple<"?{i64 div=8}">
    %itup_81 = cute.to_int_tuple(%e1_77) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %43 = cute.get_scalars(%itup_81) : !cute.int_tuple<"?{i64 div=8}">
    %itup_82 = cute.to_int_tuple(%e2_78) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %44 = cute.get_scalars(%itup_82) : !cute.int_tuple<"?{i64 div=8}">
    %45 = cute.static : !cute.swizzle<"S<3,4,3>">
    %shape = cute.make_shape() : () -> !cute.shape<"(8,64)">
    %stride = cute.make_stride() : () -> !cute.stride<"(64,1)">
    %lay_83 = cute.make_layout(%shape, %stride) : !cute.layout<"(8,64):(64,1)">
    %46 = cute.get_stride(%lay_83) : (!cute.layout<"(8,64):(64,1)">) -> !cute.stride<"(64,1)">
    %e0_84, %e1_85 = cute.get_leaves(%46) : !cute.stride<"(64,1)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"0">
    %lay_86 = cute.make_composed_layout(%45, %int_tuple, %lay_83) : !cute.composed_layout<"S<3,4,3> o 0 o (8,64):(64,1)">
    %shape_87 = cute.make_shape() : () -> !cute.shape<"(64,128)">
    %int_tuple_88 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
    %tile_to_shape = cute.tile_to_shape(%lay_86, %shape_87, %int_tuple_88) : (!cute.composed_layout<"S<3,4,3> o 0 o (8,64):(64,1)">, !cute.shape<"(64,128)">, !cute.int_tuple<"(0,1)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
    %shape_89 = cute.make_shape() : () -> !cute.shape<"(64,128)">
    %int_tuple_90 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
    %tile_to_shape_91 = cute.tile_to_shape(%lay_86, %shape_89, %int_tuple_90) : (!cute.composed_layout<"S<3,4,3> o 0 o (8,64):(64,1)">, !cute.shape<"(64,128)">, !cute.int_tuple<"(0,1)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
    %shape_92 = cute.make_shape() : () -> !cute.shape<"(64,64)">
    %int_tuple_93 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
    %tile_to_shape_94 = cute.tile_to_shape(%lay_86, %shape_92, %int_tuple_93) : (!cute.composed_layout<"S<3,4,3> o 0 o (8,64):(64,1)">, !cute.shape<"(64,64)">, !cute.int_tuple<"(0,1)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
    %cosz = cute.cosize(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"8192">
    %e0_95 = cute.get_leaves(%cosz) : !cute.int_tuple<"8192">
    %cosz_96 = cute.cosize(%tile_to_shape_91) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"8192">
    %e0_97 = cute.get_leaves(%cosz_96) : !cute.int_tuple<"8192">
    %cosz_98 = cute.cosize(%tile_to_shape_91) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"8192">
    %e0_99 = cute.get_leaves(%cosz_98) : !cute.int_tuple<"8192">
    %cosz_100 = cute.cosize(%tile_to_shape_94) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.int_tuple<"4096">
    %e0_101 = cute.get_leaves(%cosz_100) : !cute.int_tuple<"4096">
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
    %atom_102 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
    %47 = cute.composed_get_outer(%lay_86) : (!cute.composed_layout<"S<3,4,3> o 0 o (8,64):(64,1)">) -> !cute.layout<"(8,64):(64,1)">
    %48 = cute.get_shape(%47) : (!cute.layout<"(8,64):(64,1)">) -> !cute.shape<"(8,64)">
    %e0_103, %e1_104 = cute.get_leaves(%48) : !cute.shape<"(8,64)">
    %shape_105 = cute.make_shape() : () -> !cute.shape<"(16,8)">
    %stride_106 = cute.make_stride() : () -> !cute.stride<"(8,1)">
    %lay_107 = cute.make_layout(%shape_105, %stride_106) : !cute.layout<"(16,8):(8,1)">
    %shape_108 = cute.make_shape() : () -> !cute.shape<"(1,8)">
    %lay_109 = cute.make_layout(%shape_108) : !cute.layout<"(1,8):(0,1)">
    %prod = cute.raked_product(%lay_107, %lay_109) : (!cute.layout<"(16,8):(8,1)">, !cute.layout<"(1,8):(0,1)">) -> !cute.layout<"(16,(8,8)):(8,(128,1))">
    %sz = cute.size(%lay_107) : (!cute.layout<"(16,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_110 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_111 = cute.size(%lay_109) : (!cute.layout<"(1,8):(0,1)">) -> !cute.int_tuple<"8">
    %e0_112 = cute.get_leaves(%sz_111) : !cute.int_tuple<"8">
    %shape_113 = cute.make_shape() : () -> !cute.shape<"(128,8)">
    %lay_114 = cute.make_layout(%shape_113) : !cute.layout<"(128,8):(1,128)">
    %rinv = cute.right_inverse(%prod) : (!cute.layout<"(16,(8,8)):(8,(128,1))">) -> !cute.layout<"(8,128):(128,1)">
    %49 = cute.composition(%rinv, %lay_114) : (!cute.layout<"(8,128):(128,1)">, !cute.layout<"(128,8):(1,128)">) -> !cute.layout<"((8,16),8):((128,1),16)">
    %50 = cute.get_shape(%prod) : (!cute.layout<"(16,(8,8)):(8,(128,1))">) -> !cute.shape<"(16,(8,8))">
    %e0_115, %e1_116, %e2_117 = cute.get_leaves(%50) : !cute.shape<"(16,(8,8))">
    %int_tuple_118 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,(8,8))">
    %res = cute.tuple.product_each(%int_tuple_118) : (!cute.int_tuple<"(16,(8,8))">) -> !cute.int_tuple<"(16,64)">
    %e0_119, %e1_120 = cute.get_leaves(%res) : !cute.int_tuple<"(16,64)">
    %int_tuple_121 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,64)">
    %res_122 = cute.tuple.product_each(%int_tuple_121) : (!cute.int_tuple<"(16,64)">) -> !cute.int_tuple<"(16,64)">
    %e0_123, %e1_124 = cute.get_leaves(%res_122) : !cute.int_tuple<"(16,64)">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;64:1]">
    %51 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %prod_125 = cute.raked_product(%lay_107, %lay_109) : (!cute.layout<"(16,8):(8,1)">, !cute.layout<"(1,8):(0,1)">) -> !cute.layout<"(16,(8,8)):(8,(128,1))">
    %sz_126 = cute.size(%lay_107) : (!cute.layout<"(16,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_127 = cute.get_leaves(%sz_126) : !cute.int_tuple<"128">
    %sz_128 = cute.size(%lay_109) : (!cute.layout<"(1,8):(0,1)">) -> !cute.int_tuple<"8">
    %e0_129 = cute.get_leaves(%sz_128) : !cute.int_tuple<"8">
    %shape_130 = cute.make_shape() : () -> !cute.shape<"(128,8)">
    %lay_131 = cute.make_layout(%shape_130) : !cute.layout<"(128,8):(1,128)">
    %rinv_132 = cute.right_inverse(%prod_125) : (!cute.layout<"(16,(8,8)):(8,(128,1))">) -> !cute.layout<"(8,128):(128,1)">
    %52 = cute.composition(%rinv_132, %lay_131) : (!cute.layout<"(8,128):(128,1)">, !cute.layout<"(128,8):(1,128)">) -> !cute.layout<"((8,16),8):((128,1),16)">
    %53 = cute.get_shape(%prod_125) : (!cute.layout<"(16,(8,8)):(8,(128,1))">) -> !cute.shape<"(16,(8,8))">
    %e0_133, %e1_134, %e2_135 = cute.get_leaves(%53) : !cute.shape<"(16,(8,8))">
    %int_tuple_136 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,(8,8))">
    %res_137 = cute.tuple.product_each(%int_tuple_136) : (!cute.int_tuple<"(16,(8,8))">) -> !cute.int_tuple<"(16,64)">
    %e0_138, %e1_139 = cute.get_leaves(%res_137) : !cute.int_tuple<"(16,64)">
    %int_tuple_140 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,64)">
    %res_141 = cute.tuple.product_each(%int_tuple_140) : (!cute.int_tuple<"(16,64)">) -> !cute.int_tuple<"(16,64)">
    %e0_142, %e1_143 = cute.get_leaves(%res_141) : !cute.int_tuple<"(16,64)">
    %tile_144 = cute.make_tile() : () -> !cute.tile<"[16:1;64:1]">
    %54 = cute.make_tiled_copy(%atom_102) : !copy_simt
    %shape_145 = cute.make_shape() : () -> !cute.shape<"(16,8,16)">
    %atom_146 = cute.make_atom() : () -> !cute_nvgpu.sm80.mma<16x8x16, elem_type = (bf16, bf16, f32) >
    %shape_147 = cute.make_shape() : () -> !cute.shape<"(4,1,1)">
    %lay_148 = cute.make_layout(%shape_147) : !cute.layout<"(4,1,1):(1,0,0)">
    %55 = cute.get_shape(%lay_148) : (!cute.layout<"(4,1,1):(1,0,0)">) -> !cute.shape<"(4,1,1)">
    %e0_149, %e1_150, %e2_151 = cute.get_leaves(%55) : !cute.shape<"(4,1,1)">
    %tile_152 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1;16:1]">
    %56 = cute.make_tiled_mma(%atom_146) : !mma_bf16_bf16_f32_16x8x16_
    %lay_153 = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %57 = cute.get_shape(%lay_153) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_154, %e1_155, %e2_156, %e3_157 = cute.get_leaves(%57) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_158 = cute.to_int_tuple(%e0_154) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %58 = cute.get_scalars(%itup_158) : !cute.int_tuple<"?">
    %itup_159 = cute.to_int_tuple(%e1_155) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %59 = cute.get_scalars(%itup_159) : !cute.int_tuple<"?">
    %itup_160 = cute.to_int_tuple(%e2_156) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %60 = cute.get_scalars(%itup_160) : !cute.int_tuple<"?">
    %itup_161 = cute.to_int_tuple(%e3_157) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %61 = cute.get_scalars(%itup_161) : !cute.int_tuple<"?{div=8}">
    %int_tuple_162 = cute.make_int_tuple(%itup_159) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %tile_163 = cute.make_tile() : () -> !cute.tile<"64:1">
    %shp = cute.ceil_div(%int_tuple_162, %tile_163) : !cute.int_tuple<"?">, !cute.tile<"64:1">
    %e0_164 = cute.get_leaves(%shp) : !cute.int_tuple<"?">
    %62 = cute.get_scalars(%e0_164) : !cute.int_tuple<"?">
    %lay_165 = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %63 = cute.get_shape(%lay_165) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_166, %e1_167, %e2_168, %e3_169 = cute.get_leaves(%63) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_170 = cute.to_int_tuple(%e0_166) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %64 = cute.get_scalars(%itup_170) : !cute.int_tuple<"?">
    %itup_171 = cute.to_int_tuple(%e1_167) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %65 = cute.get_scalars(%itup_171) : !cute.int_tuple<"?">
    %itup_172 = cute.to_int_tuple(%e2_168) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %66 = cute.get_scalars(%itup_172) : !cute.int_tuple<"?">
    %itup_173 = cute.to_int_tuple(%e3_169) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %67 = cute.get_scalars(%itup_173) : !cute.int_tuple<"?{div=8}">
    %68 = cute.get_stride(%lay_165) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_174, %e1_175, %e2_176, %e3_177 = cute.get_leaves(%68) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_178 = cute.to_int_tuple(%e0_174) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %69 = cute.get_scalars(%itup_178) : !cute.int_tuple<"?{i64 div=8}">
    %itup_179 = cute.to_int_tuple(%e1_175) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %70 = cute.get_scalars(%itup_179) : !cute.int_tuple<"?{i64 div=8}">
    %itup_180 = cute.to_int_tuple(%e2_176) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %71 = cute.get_scalars(%itup_180) : !cute.int_tuple<"?{i64 div=8}">
    %lay_181 = cute.get_layout(%arg1) : !memref_gmem_bf16_
    %72 = cute.get_shape(%lay_181) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_182, %e1_183, %e2_184, %e3_185 = cute.get_leaves(%72) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_186 = cute.to_int_tuple(%e0_182) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %73 = cute.get_scalars(%itup_186) : !cute.int_tuple<"?">
    %itup_187 = cute.to_int_tuple(%e1_183) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %74 = cute.get_scalars(%itup_187) : !cute.int_tuple<"?">
    %itup_188 = cute.to_int_tuple(%e2_184) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %75 = cute.get_scalars(%itup_188) : !cute.int_tuple<"?">
    %itup_189 = cute.to_int_tuple(%e3_185) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %76 = cute.get_scalars(%itup_189) : !cute.int_tuple<"?{div=8}">
    %77 = cute.get_stride(%lay_181) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_190, %e1_191, %e2_192, %e3_193 = cute.get_leaves(%77) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_194 = cute.to_int_tuple(%e0_190) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %78 = cute.get_scalars(%itup_194) : !cute.int_tuple<"?{i64 div=8}">
    %itup_195 = cute.to_int_tuple(%e1_191) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %79 = cute.get_scalars(%itup_195) : !cute.int_tuple<"?{i64 div=8}">
    %itup_196 = cute.to_int_tuple(%e2_192) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %80 = cute.get_scalars(%itup_196) : !cute.int_tuple<"?{i64 div=8}">
    %lay_197 = cute.get_layout(%arg2) : !memref_gmem_bf16_
    %81 = cute.get_shape(%lay_197) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_198, %e1_199, %e2_200, %e3_201 = cute.get_leaves(%81) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_202 = cute.to_int_tuple(%e0_198) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %82 = cute.get_scalars(%itup_202) : !cute.int_tuple<"?">
    %itup_203 = cute.to_int_tuple(%e1_199) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %83 = cute.get_scalars(%itup_203) : !cute.int_tuple<"?">
    %itup_204 = cute.to_int_tuple(%e2_200) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %84 = cute.get_scalars(%itup_204) : !cute.int_tuple<"?">
    %itup_205 = cute.to_int_tuple(%e3_201) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %85 = cute.get_scalars(%itup_205) : !cute.int_tuple<"?{div=8}">
    %86 = cute.get_stride(%lay_197) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_206, %e1_207, %e2_208, %e3_209 = cute.get_leaves(%86) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_210 = cute.to_int_tuple(%e0_206) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %87 = cute.get_scalars(%itup_210) : !cute.int_tuple<"?{i64 div=8}">
    %itup_211 = cute.to_int_tuple(%e1_207) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %88 = cute.get_scalars(%itup_211) : !cute.int_tuple<"?{i64 div=8}">
    %itup_212 = cute.to_int_tuple(%e2_208) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %89 = cute.get_scalars(%itup_212) : !cute.int_tuple<"?{i64 div=8}">
    %lay_213 = cute.get_layout(%arg3) : !memref_gmem_bf16_
    %90 = cute.get_shape(%lay_213) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_214, %e1_215, %e2_216, %e3_217 = cute.get_leaves(%90) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_218 = cute.to_int_tuple(%e0_214) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %91 = cute.get_scalars(%itup_218) : !cute.int_tuple<"?">
    %itup_219 = cute.to_int_tuple(%e1_215) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %92 = cute.get_scalars(%itup_219) : !cute.int_tuple<"?">
    %itup_220 = cute.to_int_tuple(%e2_216) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %93 = cute.get_scalars(%itup_220) : !cute.int_tuple<"?">
    %itup_221 = cute.to_int_tuple(%e3_217) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %94 = cute.get_scalars(%itup_221) : !cute.int_tuple<"?{div=8}">
    %95 = cute.get_stride(%lay_213) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_222, %e1_223, %e2_224, %e3_225 = cute.get_leaves(%95) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_226 = cute.to_int_tuple(%e0_222) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %96 = cute.get_scalars(%itup_226) : !cute.int_tuple<"?{i64 div=8}">
    %itup_227 = cute.to_int_tuple(%e1_223) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %97 = cute.get_scalars(%itup_227) : !cute.int_tuple<"?{i64 div=8}">
    %itup_228 = cute.to_int_tuple(%e2_224) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %98 = cute.get_scalars(%itup_228) : !cute.int_tuple<"?{i64 div=8}">
    %lay_229 = cute.get_layout(%arg4) : !memref_gmem_bf16_
    %99 = cute.get_shape(%lay_229) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0_230, %e1_231, %e2_232, %e3_233 = cute.get_leaves(%99) : !cute.shape<"(?,?,?,?{div=8})">
    %itup_234 = cute.to_int_tuple(%e0_230) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %100 = cute.get_scalars(%itup_234) : !cute.int_tuple<"?">
    %itup_235 = cute.to_int_tuple(%e1_231) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %101 = cute.get_scalars(%itup_235) : !cute.int_tuple<"?">
    %itup_236 = cute.to_int_tuple(%e2_232) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %102 = cute.get_scalars(%itup_236) : !cute.int_tuple<"?">
    %itup_237 = cute.to_int_tuple(%e3_233) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
    %103 = cute.get_scalars(%itup_237) : !cute.int_tuple<"?{div=8}">
    %104 = cute.get_stride(%lay_229) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %e0_238, %e1_239, %e2_240, %e3_241 = cute.get_leaves(%104) : !cute.stride<"(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %itup_242 = cute.to_int_tuple(%e0_238) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %105 = cute.get_scalars(%itup_242) : !cute.int_tuple<"?{i64 div=8}">
    %itup_243 = cute.to_int_tuple(%e1_239) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %106 = cute.get_scalars(%itup_243) : !cute.int_tuple<"?{i64 div=8}">
    %itup_244 = cute.to_int_tuple(%e2_240) : !cute.stride<"?{i64 div=8}"> to !cute.int_tuple<"?{i64 div=8}">
    %107 = cute.get_scalars(%itup_244) : !cute.int_tuple<"?{i64 div=8}">
    %108 = cute.composed_get_inner(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
    %109 = cute.composed_get_offset(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
    %e0_245 = cute.get_leaves(%109) : !cute.int_tuple<"0">
    %110 = cute.composed_get_outer(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
    %111 = cute.get_shape(%110) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
    %e0_246, %e1_247, %e2_248, %e3_249 = cute.get_leaves(%111) : !cute.shape<"((8,8),(64,2))">
    %112 = cute.get_stride(%110) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
    %e0_250, %e1_251, %e2_252, %e3_253 = cute.get_leaves(%112) : !cute.stride<"((64,512),(1,4096))">
    %113 = cute.composed_get_inner(%tile_to_shape_91) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
    %114 = cute.composed_get_offset(%tile_to_shape_91) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
    %e0_254 = cute.get_leaves(%114) : !cute.int_tuple<"0">
    %115 = cute.composed_get_outer(%tile_to_shape_91) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
    %116 = cute.get_shape(%115) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
    %e0_255, %e1_256, %e2_257, %e3_258 = cute.get_leaves(%116) : !cute.shape<"((8,8),(64,2))">
    %117 = cute.get_stride(%115) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
    %e0_259, %e1_260, %e2_261, %e3_262 = cute.get_leaves(%117) : !cute.stride<"((64,512),(1,4096))">
    %118 = cute.composed_get_inner(%tile_to_shape_94) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.swizzle<"S<3,4,3>">
    %119 = cute.composed_get_offset(%tile_to_shape_94) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.int_tuple<"0">
    %e0_263 = cute.get_leaves(%119) : !cute.int_tuple<"0">
    %120 = cute.composed_get_outer(%tile_to_shape_94) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.layout<"((8,8),(64,1)):((64,512),(1,0))">
    %121 = cute.get_shape(%120) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.shape<"((8,8),(64,1))">
    %e0_264, %e1_265, %e2_266, %e3_267 = cute.get_leaves(%121) : !cute.shape<"((8,8),(64,1))">
    %122 = cute.get_stride(%120) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.stride<"((64,512),(1,0))">
    %e0_268, %e1_269, %e2_270, %e3_271 = cute.get_leaves(%122) : !cute.stride<"((64,512),(1,0))">
    %123 = cute.composed_get_inner(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
    %124 = cute.composed_get_offset(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
    %e0_272 = cute.get_leaves(%124) : !cute.int_tuple<"0">
    %125 = cute.composed_get_outer(%tile_to_shape) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
    %126 = cute.get_shape(%125) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
    %e0_273, %e1_274, %e2_275, %e3_276 = cute.get_leaves(%126) : !cute.shape<"((8,8),(64,2))">
    %127 = cute.get_stride(%125) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
    %e0_277, %e1_278, %e2_279, %e3_280 = cute.get_leaves(%127) : !cute.stride<"((64,512),(1,4096))">
    %128 = cute.static : !cute.tile<"[16:1;64:1]">
    %e0_281, %e1_282 = cute.get_leaves(%128) : !cute.tile<"[16:1;64:1]">
    %129 = cute.get_shape(%e0_281) : (!cute.layout<"16:1">) -> !cute.shape<"16">
    %e0_283 = cute.get_leaves(%129) : !cute.shape<"16">
    %130 = cute.get_stride(%e0_281) : (!cute.layout<"16:1">) -> !cute.stride<"1">
    %e0_284 = cute.get_leaves(%130) : !cute.stride<"1">
    %131 = cute.get_shape(%e1_282) : (!cute.layout<"64:1">) -> !cute.shape<"64">
    %e0_285 = cute.get_leaves(%131) : !cute.shape<"64">
    %132 = cute.get_stride(%e1_282) : (!cute.layout<"64:1">) -> !cute.stride<"1">
    %e0_286 = cute.get_leaves(%132) : !cute.stride<"1">
    %133 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
    %134 = cute.get_shape(%133) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
    %e0_287, %e1_288, %e2_289 = cute.get_leaves(%134) : !cute.shape<"((8,16),8)">
    %135 = cute.get_stride(%133) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
    %e0_290, %e1_291, %e2_292 = cute.get_leaves(%135) : !cute.stride<"((128,1),16)">
    %136 = cute.static : !cute.layout<"1:0">
    %137 = cute.get_shape(%136) : (!cute.layout<"1:0">) -> !cute.shape<"1">
    %e0_293 = cute.get_leaves(%137) : !cute.shape<"1">
    %138 = cute.get_stride(%136) : (!cute.layout<"1:0">) -> !cute.stride<"0">
    %e0_294 = cute.get_leaves(%138) : !cute.stride<"0">
    %139 = cute.static : !cute.layout<"(1,8):(0,1)">
    %140 = cute.get_shape(%139) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
    %e0_295, %e1_296 = cute.get_leaves(%140) : !cute.shape<"(1,8)">
    %141 = cute.get_stride(%139) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
    %e0_297, %e1_298 = cute.get_leaves(%141) : !cute.stride<"(0,1)">
    %142 = cute.static : !cute.layout<"(1,8):(0,1)">
    %143 = cute.get_shape(%142) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
    %e0_299, %e1_300 = cute.get_leaves(%143) : !cute.shape<"(1,8)">
    %144 = cute.get_stride(%142) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
    %e0_301, %e1_302 = cute.get_leaves(%144) : !cute.stride<"(0,1)">
    %145 = cute.static : !cute.tile<"[16:1;64:1]">
    %e0_303, %e1_304 = cute.get_leaves(%145) : !cute.tile<"[16:1;64:1]">
    %146 = cute.get_shape(%e0_303) : (!cute.layout<"16:1">) -> !cute.shape<"16">
    %e0_305 = cute.get_leaves(%146) : !cute.shape<"16">
    %147 = cute.get_stride(%e0_303) : (!cute.layout<"16:1">) -> !cute.stride<"1">
    %e0_306 = cute.get_leaves(%147) : !cute.stride<"1">
    %148 = cute.get_shape(%e1_304) : (!cute.layout<"64:1">) -> !cute.shape<"64">
    %e0_307 = cute.get_leaves(%148) : !cute.shape<"64">
    %149 = cute.get_stride(%e1_304) : (!cute.layout<"64:1">) -> !cute.stride<"1">
    %e0_308 = cute.get_leaves(%149) : !cute.stride<"1">
    %150 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
    %151 = cute.get_shape(%150) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
    %e0_309, %e1_310, %e2_311 = cute.get_leaves(%151) : !cute.shape<"((8,16),8)">
    %152 = cute.get_stride(%150) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
    %e0_312, %e1_313, %e2_314 = cute.get_leaves(%152) : !cute.stride<"((128,1),16)">
    %153 = cute.static : !cute.layout<"1:0">
    %154 = cute.get_shape(%153) : (!cute.layout<"1:0">) -> !cute.shape<"1">
    %e0_315 = cute.get_leaves(%154) : !cute.shape<"1">
    %155 = cute.get_stride(%153) : (!cute.layout<"1:0">) -> !cute.stride<"0">
    %e0_316 = cute.get_leaves(%155) : !cute.stride<"0">
    %156 = cute.static : !cute.layout<"(1,8):(0,1)">
    %157 = cute.get_shape(%156) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
    %e0_317, %e1_318 = cute.get_leaves(%157) : !cute.shape<"(1,8)">
    %158 = cute.get_stride(%156) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
    %e0_319, %e1_320 = cute.get_leaves(%158) : !cute.stride<"(0,1)">
    %159 = cute.static : !cute.layout<"(1,8):(0,1)">
    %160 = cute.get_shape(%159) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
    %e0_321, %e1_322 = cute.get_leaves(%160) : !cute.shape<"(1,8)">
    %161 = cute.get_stride(%159) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
    %e0_323, %e1_324 = cute.get_leaves(%161) : !cute.stride<"(0,1)">
    %162 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
    %163 = cute.get_shape(%162) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
    %e0_325, %e1_326, %e2_327, %e3_328 = cute.get_leaves(%163) : !cute.shape<"(32,4,1,1)">
    %164 = cute.get_stride(%162) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
    %e0_329, %e1_330, %e2_331, %e3_332 = cute.get_leaves(%164) : !cute.stride<"(1,32,0,0)">
    %165 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
    %e0_333, %e1_334, %e2_335 = cute.get_leaves(%165) : !cute.tile<"[64:1;16:1;16:1]">
    %166 = cute.get_shape(%e0_333) : (!cute.layout<"64:1">) -> !cute.shape<"64">
    %e0_336 = cute.get_leaves(%166) : !cute.shape<"64">
    %167 = cute.get_stride(%e0_333) : (!cute.layout<"64:1">) -> !cute.stride<"1">
    %e0_337 = cute.get_leaves(%167) : !cute.stride<"1">
    %168 = cute.get_shape(%e1_334) : (!cute.layout<"16:1">) -> !cute.shape<"16">
    %e0_338 = cute.get_leaves(%168) : !cute.shape<"16">
    %169 = cute.get_stride(%e1_334) : (!cute.layout<"16:1">) -> !cute.stride<"1">
    %e0_339 = cute.get_leaves(%169) : !cute.stride<"1">
    %170 = cute.get_shape(%e2_335) : (!cute.layout<"16:1">) -> !cute.shape<"16">
    %e0_340 = cute.get_leaves(%170) : !cute.shape<"16">
    %171 = cute.get_stride(%e2_335) : (!cute.layout<"16:1">) -> !cute.stride<"1">
    %e0_341 = cute.get_leaves(%171) : !cute.stride<"1">
    %172 = cute.static : !cute.layout<"32:1">
    %173 = cute.get_shape(%172) : (!cute.layout<"32:1">) -> !cute.shape<"32">
    %e0_342 = cute.get_leaves(%173) : !cute.shape<"32">
    %174 = cute.get_stride(%172) : (!cute.layout<"32:1">) -> !cute.stride<"1">
    %e0_343 = cute.get_leaves(%174) : !cute.stride<"1">
    %175 = cute.static : !cute.shape<"(16,8,16)">
    %e0_344, %e1_345, %e2_346 = cute.get_leaves(%175) : !cute.shape<"(16,8,16)">
    %176 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
    %177 = cute.get_shape(%176) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
    %e0_347, %e1_348, %e2_349, %e3_350, %e4 = cute.get_leaves(%177) : !cute.shape<"((4,8),(2,2,2))">
    %178 = cute.get_stride(%176) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
    %e0_351, %e1_352, %e2_353, %e3_354, %e4_355 = cute.get_leaves(%178) : !cute.stride<"((32,1),(16,8,128))">
    %179 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
    %180 = cute.get_shape(%179) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
    %e0_356, %e1_357, %e2_358, %e3_359 = cute.get_leaves(%180) : !cute.shape<"((4,8),(2,2))">
    %181 = cute.get_stride(%179) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
    %e0_360, %e1_361, %e2_362, %e3_363 = cute.get_leaves(%181) : !cute.stride<"((16,1),(8,64))">
    %182 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
    %183 = cute.get_shape(%182) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
    %e0_364, %e1_365, %e2_366, %e3_367 = cute.get_leaves(%183) : !cute.shape<"((4,8),(2,2))">
    %184 = cute.get_stride(%182) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
    %e0_368, %e1_369, %e2_370, %e3_371 = cute.get_leaves(%184) : !cute.stride<"((32,1),(16,8))">
    %c57344_i32 = arith.constant 57344 : i32
    %185 = arith.extsi %c57344_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %c4_i32 = arith.constant 4 : i32
    %186 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %185, gridDim = (%c4_i32, %c4_i32, %62), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %187 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0<%186> (%arg0, %arg1, %arg2, %arg3, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_) -> !cuda.result
    %188 = cuda.cast %187 : !cuda.result -> i32
    cuda.return_if_error %188 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
