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
    func.func public @kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %arg6: !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %arg7: !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">, %arg8: !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %arg9: !copy_ldgsts, %arg10: !copy_simt, %arg11: !mma_bf16_bf16_f32_16x8x16_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %45 = cute.composed_get_inner(%arg5) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %46 = cute.composed_get_offset(%arg5) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_83 = cute.get_leaves(%46) : !cute.int_tuple<"0">
      %47 = cute.composed_get_outer(%arg5) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %48 = cute.get_shape(%47) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_84, %e1_85, %e2_86, %e3_87 = cute.get_leaves(%48) : !cute.shape<"((8,8),(64,2))">
      %49 = cute.get_stride(%47) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_88, %e1_89, %e2_90, %e3_91 = cute.get_leaves(%49) : !cute.stride<"((64,512),(1,4096))">
      %50 = cute.composed_get_inner(%arg6) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %51 = cute.composed_get_offset(%arg6) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_92 = cute.get_leaves(%51) : !cute.int_tuple<"0">
      %52 = cute.composed_get_outer(%arg6) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %53 = cute.get_shape(%52) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_93, %e1_94, %e2_95, %e3_96 = cute.get_leaves(%53) : !cute.shape<"((8,8),(64,2))">
      %54 = cute.get_stride(%52) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_97, %e1_98, %e2_99, %e3_100 = cute.get_leaves(%54) : !cute.stride<"((64,512),(1,4096))">
      %55 = cute.composed_get_inner(%arg7) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.swizzle<"S<3,4,3>">
      %56 = cute.composed_get_offset(%arg7) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.int_tuple<"0">
      %e0_101 = cute.get_leaves(%56) : !cute.int_tuple<"0">
      %57 = cute.composed_get_outer(%arg7) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !cute.layout<"((8,8),(64,1)):((64,512),(1,0))">
      %58 = cute.get_shape(%57) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.shape<"((8,8),(64,1))">
      %e0_102, %e1_103, %e2_104, %e3_105 = cute.get_leaves(%58) : !cute.shape<"((8,8),(64,1))">
      %59 = cute.get_stride(%57) : (!cute.layout<"((8,8),(64,1)):((64,512),(1,0))">) -> !cute.stride<"((64,512),(1,0))">
      %e0_106, %e1_107, %e2_108, %e3_109 = cute.get_leaves(%59) : !cute.stride<"((64,512),(1,0))">
      %60 = cute.composed_get_inner(%arg8) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %61 = cute.composed_get_offset(%arg8) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.int_tuple<"0">
      %e0_110 = cute.get_leaves(%61) : !cute.int_tuple<"0">
      %62 = cute.composed_get_outer(%arg8) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %63 = cute.get_shape(%62) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.shape<"((8,8),(64,2))">
      %e0_111, %e1_112, %e2_113, %e3_114 = cute.get_leaves(%63) : !cute.shape<"((8,8),(64,2))">
      %64 = cute.get_stride(%62) : (!cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.stride<"((64,512),(1,4096))">
      %e0_115, %e1_116, %e2_117, %e3_118 = cute.get_leaves(%64) : !cute.stride<"((64,512),(1,4096))">
      %65 = cute.static : !cute.tile<"[16:1;64:1]">
      %e0_119, %e1_120 = cute.get_leaves(%65) : !cute.tile<"[16:1;64:1]">
      %66 = cute.get_shape(%e0_119) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_121 = cute.get_leaves(%66) : !cute.shape<"16">
      %67 = cute.get_stride(%e0_119) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_122 = cute.get_leaves(%67) : !cute.stride<"1">
      %68 = cute.get_shape(%e1_120) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_123 = cute.get_leaves(%68) : !cute.shape<"64">
      %69 = cute.get_stride(%e1_120) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_124 = cute.get_leaves(%69) : !cute.stride<"1">
      %70 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %71 = cute.get_shape(%70) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
      %e0_125, %e1_126, %e2_127 = cute.get_leaves(%71) : !cute.shape<"((8,16),8)">
      %72 = cute.get_stride(%70) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
      %e0_128, %e1_129, %e2_130 = cute.get_leaves(%72) : !cute.stride<"((128,1),16)">
      %73 = cute.static : !cute.layout<"1:0">
      %74 = cute.get_shape(%73) : (!cute.layout<"1:0">) -> !cute.shape<"1">
      %e0_131 = cute.get_leaves(%74) : !cute.shape<"1">
      %75 = cute.get_stride(%73) : (!cute.layout<"1:0">) -> !cute.stride<"0">
      %e0_132 = cute.get_leaves(%75) : !cute.stride<"0">
      %76 = cute.static : !cute.layout<"(1,8):(0,1)">
      %77 = cute.get_shape(%76) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_133, %e1_134 = cute.get_leaves(%77) : !cute.shape<"(1,8)">
      %78 = cute.get_stride(%76) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_135, %e1_136 = cute.get_leaves(%78) : !cute.stride<"(0,1)">
      %79 = cute.static : !cute.layout<"(1,8):(0,1)">
      %80 = cute.get_shape(%79) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_137, %e1_138 = cute.get_leaves(%80) : !cute.shape<"(1,8)">
      %81 = cute.get_stride(%79) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_139, %e1_140 = cute.get_leaves(%81) : !cute.stride<"(0,1)">
      %82 = cute.static : !cute.tile<"[16:1;64:1]">
      %e0_141, %e1_142 = cute.get_leaves(%82) : !cute.tile<"[16:1;64:1]">
      %83 = cute.get_shape(%e0_141) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_143 = cute.get_leaves(%83) : !cute.shape<"16">
      %84 = cute.get_stride(%e0_141) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_144 = cute.get_leaves(%84) : !cute.stride<"1">
      %85 = cute.get_shape(%e1_142) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_145 = cute.get_leaves(%85) : !cute.shape<"64">
      %86 = cute.get_stride(%e1_142) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_146 = cute.get_leaves(%86) : !cute.stride<"1">
      %87 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %88 = cute.get_shape(%87) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.shape<"((8,16),8)">
      %e0_147, %e1_148, %e2_149 = cute.get_leaves(%88) : !cute.shape<"((8,16),8)">
      %89 = cute.get_stride(%87) : (!cute.layout<"((8,16),8):((128,1),16)">) -> !cute.stride<"((128,1),16)">
      %e0_150, %e1_151, %e2_152 = cute.get_leaves(%89) : !cute.stride<"((128,1),16)">
      %90 = cute.static : !cute.layout<"1:0">
      %91 = cute.get_shape(%90) : (!cute.layout<"1:0">) -> !cute.shape<"1">
      %e0_153 = cute.get_leaves(%91) : !cute.shape<"1">
      %92 = cute.get_stride(%90) : (!cute.layout<"1:0">) -> !cute.stride<"0">
      %e0_154 = cute.get_leaves(%92) : !cute.stride<"0">
      %93 = cute.static : !cute.layout<"(1,8):(0,1)">
      %94 = cute.get_shape(%93) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_155, %e1_156 = cute.get_leaves(%94) : !cute.shape<"(1,8)">
      %95 = cute.get_stride(%93) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_157, %e1_158 = cute.get_leaves(%95) : !cute.stride<"(0,1)">
      %96 = cute.static : !cute.layout<"(1,8):(0,1)">
      %97 = cute.get_shape(%96) : (!cute.layout<"(1,8):(0,1)">) -> !cute.shape<"(1,8)">
      %e0_159, %e1_160 = cute.get_leaves(%97) : !cute.shape<"(1,8)">
      %98 = cute.get_stride(%96) : (!cute.layout<"(1,8):(0,1)">) -> !cute.stride<"(0,1)">
      %e0_161, %e1_162 = cute.get_leaves(%98) : !cute.stride<"(0,1)">
      %99 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %100 = cute.get_shape(%99) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
      %e0_163, %e1_164, %e2_165, %e3_166 = cute.get_leaves(%100) : !cute.shape<"(32,4,1,1)">
      %101 = cute.get_stride(%99) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
      %e0_167, %e1_168, %e2_169, %e3_170 = cute.get_leaves(%101) : !cute.stride<"(1,32,0,0)">
      %102 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_171, %e1_172, %e2_173 = cute.get_leaves(%102) : !cute.tile<"[64:1;16:1;16:1]">
      %103 = cute.get_shape(%e0_171) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_174 = cute.get_leaves(%103) : !cute.shape<"64">
      %104 = cute.get_stride(%e0_171) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_175 = cute.get_leaves(%104) : !cute.stride<"1">
      %105 = cute.get_shape(%e1_172) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_176 = cute.get_leaves(%105) : !cute.shape<"16">
      %106 = cute.get_stride(%e1_172) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_177 = cute.get_leaves(%106) : !cute.stride<"1">
      %107 = cute.get_shape(%e2_173) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_178 = cute.get_leaves(%107) : !cute.shape<"16">
      %108 = cute.get_stride(%e2_173) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_179 = cute.get_leaves(%108) : !cute.stride<"1">
      %109 = cute.static : !cute.layout<"32:1">
      %110 = cute.get_shape(%109) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_180 = cute.get_leaves(%110) : !cute.shape<"32">
      %111 = cute.get_stride(%109) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_181 = cute.get_leaves(%111) : !cute.stride<"1">
      %112 = cute.static : !cute.shape<"(16,8,16)">
      %e0_182, %e1_183, %e2_184 = cute.get_leaves(%112) : !cute.shape<"(16,8,16)">
      %113 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %114 = cute.get_shape(%113) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
      %e0_185, %e1_186, %e2_187, %e3_188, %e4 = cute.get_leaves(%114) : !cute.shape<"((4,8),(2,2,2))">
      %115 = cute.get_stride(%113) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
      %e0_189, %e1_190, %e2_191, %e3_192, %e4_193 = cute.get_leaves(%115) : !cute.stride<"((32,1),(16,8,128))">
      %116 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %117 = cute.get_shape(%116) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_194, %e1_195, %e2_196, %e3_197 = cute.get_leaves(%117) : !cute.shape<"((4,8),(2,2))">
      %118 = cute.get_stride(%116) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
      %e0_198, %e1_199, %e2_200, %e3_201 = cute.get_leaves(%118) : !cute.stride<"((16,1),(8,64))">
      %119 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %120 = cute.get_shape(%119) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_202, %e1_203, %e2_204, %e3_205 = cute.get_leaves(%120) : !cute.shape<"((4,8),(2,2))">
      %121 = cute.get_stride(%119) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
      %e0_206, %e1_207, %e2_208, %e3_209 = cute.get_leaves(%121) : !cute.stride<"((32,1),(16,8))">
      %122 = nvvm.read.ptx.sreg.tid.x : i32
      %123 = nvvm.read.ptx.sreg.tid.y : i32
      %124 = nvvm.read.ptx.sreg.tid.z : i32
      %125 = nvvm.read.ptx.sreg.ctaid.x : i32
      %126 = nvvm.read.ptx.sreg.ctaid.y : i32
      %127 = nvvm.read.ptx.sreg.ctaid.z : i32
      %lay_210 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %128 = cute.get_shape(%lay_210) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_211, %e1_212, %e2_213, %e3_214 = cute.get_leaves(%128) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_215 = cute.to_int_tuple(%e0_211) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %129 = cute.get_scalars(%itup_215) : !cute.int_tuple<"?">
      %itup_216 = cute.to_int_tuple(%e1_212) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %130 = cute.get_scalars(%itup_216) : !cute.int_tuple<"?">
      %itup_217 = cute.to_int_tuple(%e2_213) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %131 = cute.get_scalars(%itup_217) : !cute.int_tuple<"?">
      %itup_218 = cute.to_int_tuple(%e3_214) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %132 = cute.get_scalars(%itup_218) : !cute.int_tuple<"?{div=8}">
      %int_tuple = cute.make_int_tuple(%itup_216) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %tile = cute.make_tile() : () -> !cute.tile<"64:1">
      %shp = cute.ceil_div(%int_tuple, %tile) : !cute.int_tuple<"?">, !cute.tile<"64:1">
      %e0_219 = cute.get_leaves(%shp) : !cute.int_tuple<"?">
      %133 = cute.get_scalars(%e0_219) : !cute.int_tuple<"?">
      %int_tuple_220 = cute.make_int_tuple(%127) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_219, %int_tuple_220) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %134 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %int_tuple_221 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sub_222 = cute.tuple_sub(%sub, %int_tuple_221) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %135 = cute.get_scalars(%sub_222) : !cute.int_tuple<"?">
      %lay_223 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %136 = cute.get_shape(%lay_223) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_224, %e1_225, %e2_226, %e3_227 = cute.get_leaves(%136) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_228 = cute.to_int_tuple(%e0_224) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %137 = cute.get_scalars(%itup_228) : !cute.int_tuple<"?">
      %itup_229 = cute.to_int_tuple(%e1_225) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %138 = cute.get_scalars(%itup_229) : !cute.int_tuple<"?">
      %itup_230 = cute.to_int_tuple(%e2_226) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %139 = cute.get_scalars(%itup_230) : !cute.int_tuple<"?">
      %itup_231 = cute.to_int_tuple(%e3_227) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %140 = cute.get_scalars(%itup_231) : !cute.int_tuple<"?{div=8}">
      %int_tuple_232 = cute.make_int_tuple(%itup_229) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %tile_233 = cute.make_tile() : () -> !cute.tile<"64:1">
      %shp_234 = cute.ceil_div(%int_tuple_232, %tile_233) : !cute.int_tuple<"?">, !cute.tile<"64:1">
      %e0_235 = cute.get_leaves(%shp_234) : !cute.int_tuple<"?">
      %141 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?">
      %int_tuple_236 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sub_237 = cute.tuple_sub(%e0_235, %int_tuple_236) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %142 = cute.get_scalars(%sub_237) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_238 = cute.get_iter(%slice) : !memref_gmem_bf16_1
      %tile_239 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_240 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view = cute.local_tile(%slice, %tile_239, %coord_240) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_241 = cute.get_iter(%tiled_view) : !memref_gmem_bf16_2
      %coord_242 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_243 = cute.slice(%arg1, %coord_242) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_244 = cute.get_iter(%slice_243) : !memref_gmem_bf16_1
      %tile_245 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_246 = cute.make_coord() : () -> !cute.coord<"(_,0)">
      %tiled_view_247 = cute.local_tile(%slice_243, %tile_245, %coord_246) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(_,0)">) -> !memref_gmem_bf16_3
      %iter_248 = cute.get_iter(%tiled_view_247) : !memref_gmem_bf16_3
      %coord_249 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_250 = cute.slice(%arg2, %coord_249) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_251 = cute.get_iter(%slice_250) : !memref_gmem_bf16_1
      %tile_252 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_253 = cute.make_coord() : () -> !cute.coord<"(_,0)">
      %tiled_view_254 = cute.local_tile(%slice_250, %tile_252, %coord_253) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(_,0)">) -> !memref_gmem_bf16_3
      %iter_255 = cute.get_iter(%tiled_view_254) : !memref_gmem_bf16_3
      %coord_256 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %slice_257 = cute.slice(%arg4, %coord_256) : !memref_gmem_bf16_, !cute.coord<"(?,?,_,_)">
      %iter_258 = cute.get_iter(%slice_257) : !memref_gmem_bf16_1
      %tile_259 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
      %coord_260 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %tiled_view_261 = cute.local_tile(%slice_257, %tile_259, %coord_260) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,_)">) -> !memref_gmem_bf16_4
      %iter_262 = cute.get_iter(%tiled_view_261) : !memref_gmem_bf16_4
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %int_tuple_263 = cute.make_int_tuple() : () -> !cute.int_tuple<"57344">
      %ptr = cute.add_offset(%smem_ptr, %int_tuple_263) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"57344">) -> !cute.ptr<i8, smem, align<1024>>
      %smem_size = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c57344_i32 = arith.constant 57344 : i32
      %143 = arith.cmpi sge, %smem_size, %c57344_i32 : i32
      cf.assert %143, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 57344 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %int_tuple_264 = cute.make_int_tuple() : () -> !cute.int_tuple<"0">
      %ptr_265 = cute.add_offset(%smem_ptr, %int_tuple_264) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_266 = cute.make_int_tuple() : () -> !cute.int_tuple<"16384">
      %ptr_267 = cute.add_offset(%smem_ptr, %int_tuple_266) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_268 = cute.make_int_tuple() : () -> !cute.int_tuple<"32768">
      %ptr_269 = cute.add_offset(%smem_ptr, %int_tuple_268) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_270 = cute.make_int_tuple() : () -> !cute.int_tuple<"49152">
      %ptr_271 = cute.add_offset(%smem_ptr, %int_tuple_270) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_272 = cute.recast_iter(%ptr_265) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view = cute.make_view(%iter_272, %arg5) : !memref_smem_bf16_
      %iter_273 = cute.get_iter(%view) : !memref_smem_bf16_
      %iter_274 = cute.recast_iter(%ptr_267) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_275 = cute.make_view(%iter_274, %arg6) : !memref_smem_bf16_
      %iter_276 = cute.get_iter(%view_275) : !memref_smem_bf16_
      %iter_277 = cute.recast_iter(%ptr_269) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_278 = cute.make_view(%iter_277, %arg6) : !memref_smem_bf16_
      %iter_279 = cute.get_iter(%view_278) : !memref_smem_bf16_
      %iter_280 = cute.recast_iter(%ptr_271) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_281 = cute.make_view(%iter_280, %arg7) : !memref_smem_bf16_1
      %iter_282 = cute.get_iter(%view_281) : !memref_smem_bf16_1
      %shape = cute.make_shape() : () -> !cute.shape<"(128,64)">
      %stride = cute.make_stride() : () -> !cute.stride<"(64,1)">
      %lay_283 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,64):(64,1)">
      %144 = cute.composition(%view_278, %lay_283) : (!memref_smem_bf16_, !cute.layout<"(128,64):(64,1)">) -> !memref_smem_bf16_2
      %iter_284 = cute.get_iter(%144) : !memref_smem_bf16_2
      %coord_285 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%arg9, %tiled_view, %coord_285) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_286 = cute.get_iter(%src_partitioned) : !memref_gmem_bf16_5
      %coord_287 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned = cute.tiled.copy.partition_D(%arg9, %view, %coord_287) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_288 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_3
      %coord_289 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_290 = cute.tiled.copy.partition_S(%arg9, %tiled_view_247, %coord_289) : (!copy_ldgsts, !memref_gmem_bf16_3, !cute.coord<"?">) -> !memref_gmem_bf16_6
      %iter_291 = cute.get_iter(%src_partitioned_290) : !memref_gmem_bf16_6
      %coord_292 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_293 = cute.tiled.copy.partition_D(%arg9, %view_275, %coord_292) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_294 = cute.get_iter(%dst_partitioned_293) : !memref_smem_bf16_3
      %coord_295 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_296 = cute.tiled.copy.partition_S(%arg9, %tiled_view_254, %coord_295) : (!copy_ldgsts, !memref_gmem_bf16_3, !cute.coord<"?">) -> !memref_gmem_bf16_6
      %iter_297 = cute.get_iter(%src_partitioned_296) : !memref_gmem_bf16_6
      %coord_298 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_299 = cute.tiled.copy.partition_D(%arg9, %view_278, %coord_298) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_3
      %iter_300 = cute.get_iter(%dst_partitioned_299) : !memref_smem_bf16_3
      %coord_301 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_302 = cute.tiled.copy.partition_S(%arg9, %tiled_view_261, %coord_301) : (!copy_ldgsts, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_7
      %iter_303 = cute.get_iter(%src_partitioned_302) : !memref_gmem_bf16_7
      %coord_304 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_305 = cute.tiled.copy.partition_D(%arg9, %view_281, %coord_304) : (!copy_ldgsts, !memref_smem_bf16_1, !cute.coord<"?">) -> !memref_smem_bf16_4
      %iter_306 = cute.get_iter(%dst_partitioned_305) : !memref_smem_bf16_4
      %coord_307 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %ptn_A = cute.tiled.mma.partition A (%arg11, %view, %coord_307) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_5
      %iter_308 = cute.get_iter(%ptn_A) : !memref_smem_bf16_5
      %frg_A = cute.mma.make_fragment A (%arg11, %ptn_A) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_5) -> !memref_rmem_bf16_
      %iter_309 = cute.get_iter(%frg_A) : !memref_rmem_bf16_
      %coord_310 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %ptn_B = cute.tiled.mma.partition B (%arg11, %view_275, %coord_310) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_6
      %iter_311 = cute.get_iter(%ptn_B) : !memref_smem_bf16_6
      %frg_B = cute.mma.make_fragment B (%arg11, %ptn_B) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_6) -> !memref_rmem_bf16_1
      %iter_312 = cute.get_iter(%frg_B) : !memref_rmem_bf16_1
      %coord_313 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %ptn_B_314 = cute.tiled.mma.partition B (%arg11, %144, %coord_313) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_2, !cute.coord<"?">) -> !memref_smem_bf16_7
      %iter_315 = cute.get_iter(%ptn_B_314) : !memref_smem_bf16_7
      %frg_B_316 = cute.mma.make_fragment B (%arg11, %ptn_B_314) : (!mma_bf16_bf16_f32_16x8x16_, !memref_smem_bf16_7) -> !memref_rmem_bf16_2
      %iter_317 = cute.get_iter(%frg_B_316) : !memref_rmem_bf16_2
      %shape_318 = cute.make_shape() : () -> !cute.shape<"(64,128)">
      %145 = cute.tiled.mma.partition_shape C (%arg11, %shape_318) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,128)">) -> !cute.shape<"((2,2),1,16)">
      %e0_319, %e1_320, %e2_321, %e3_322 = cute.get_leaves(%145) : !cute.shape<"((2,2),1,16)">
      %shape_323 = cute.make_shape() : () -> !cute.shape<"((2,2),1,16)">
      %lay_324 = cute.make_layout(%shape_323) : !cute.layout<"((2,2),1,16):((1,2),0,4)">
      %rmem = cute.memref.alloca(%lay_324) : !memref_rmem_f32_
      %iter_325 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_326 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %sz = cute.size(%rmem) : (!memref_rmem_f32_) -> !cute.int_tuple<"64">
      %e0_327 = cute.get_leaves(%sz) : !cute.int_tuple<"64">
      %lay_328 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %146 = cute.get_shape(%lay_328) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_329, %e1_330, %e2_331, %e3_332 = cute.get_leaves(%146) : !cute.shape<"((2,2),1,16)">
      %int_tuple_333 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %res = cute.tuple.product(%int_tuple_333) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_334 = cute.get_leaves(%res) : !cute.int_tuple<"64">
      %cst = arith.constant 0.000000e+00 : f32
      %147 = vector.splat %cst : vector<64xf32>
      %int_tuple_335 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_336 = cute.size(%int_tuple_335) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_337 = cute.get_leaves(%sz_336) : !cute.int_tuple<"64">
      %int_tuple_338 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_339 = cute.size(%int_tuple_338) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_340 = cute.get_leaves(%sz_339) : !cute.int_tuple<"64">
      cute.memref.store_vec %147, %rmem, row_major : !memref_rmem_f32_
      %shape_341 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %shape_342 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_343 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %shape_344 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_345 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %shape_346 = cute.make_shape() : () -> !cute.shape<"(8,8)">
      %atom_347 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %148 = cute.static : !cute.layout<"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">
      %149 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_348, %e1_349, %e2_350 = cute.get_leaves(%149) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_351 = cute.size(%e0_348) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_352 = cute.get_leaves(%sz_351) : !cute.int_tuple<"64">
      %150 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_353, %e1_354, %e2_355 = cute.get_leaves(%150) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_356 = cute.size(%e2_355) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_357 = cute.get_leaves(%sz_356) : !cute.int_tuple<"16">
      %tile_358 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %151 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %152 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %153 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_359, %e1_360, %e2_361 = cute.get_leaves(%153) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_362 = cute.size(%e1_360) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_363 = cute.get_leaves(%sz_362) : !cute.int_tuple<"16">
      %154 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_364, %e1_365, %e2_366 = cute.get_leaves(%154) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_367 = cute.size(%e2_366) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_368 = cute.get_leaves(%sz_367) : !cute.int_tuple<"16">
      %tile_369 = cute.make_tile() : () -> !cute.tile<"[16:1;16:1]">
      %155 = cute.make_tiled_copy(%atom_343) : !copy_ldsm_4_1
      %156 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %157 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_370, %e1_371, %e2_372 = cute.get_leaves(%157) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_373 = cute.size(%e1_371) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_374 = cute.get_leaves(%sz_373) : !cute.int_tuple<"16">
      %158 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_375, %e1_376, %e2_377 = cute.get_leaves(%158) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_378 = cute.size(%e2_377) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_379 = cute.get_leaves(%sz_378) : !cute.int_tuple<"16">
      %tile_380 = cute.make_tile() : () -> !cute.tile<"[16:1;16:1]">
      %159 = cute.make_tiled_copy(%atom_345) : !copy_ldsm_4_2
      %160 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %161 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_381, %e1_382, %e2_383 = cute.get_leaves(%161) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_384 = cute.size(%e0_381) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_385 = cute.get_leaves(%sz_384) : !cute.int_tuple<"64">
      %162 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_386, %e1_387, %e2_388 = cute.get_leaves(%162) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_389 = cute.size(%e1_387) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_390 = cute.get_leaves(%sz_389) : !cute.int_tuple<"16">
      %tile_391 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %163 = cute.make_tiled_copy(%atom_347) : !copy_ldsm_4_3
      %coord_392 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_393 = cute.tiled.copy.partition_S(%151, %view, %coord_392) : (!copy_ldsm_4_, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_8
      %iter_394 = cute.get_iter(%src_partitioned_393) : !memref_smem_bf16_8
      %retiled = cute.tiled.copy.retile(%151, %frg_A) : (!copy_ldsm_4_, !memref_rmem_bf16_) -> !memref_rmem_bf16_3
      %iter_395 = cute.get_iter(%retiled) : !memref_rmem_bf16_3
      %coord_396 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_397 = cute.tiled.copy.partition_S(%155, %view_275, %coord_396) : (!copy_ldsm_4_1, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_9
      %iter_398 = cute.get_iter(%src_partitioned_397) : !memref_smem_bf16_9
      %retiled_399 = cute.tiled.copy.retile(%155, %frg_B) : (!copy_ldsm_4_1, !memref_rmem_bf16_1) -> !memref_rmem_bf16_4
      %iter_400 = cute.get_iter(%retiled_399) : !memref_rmem_bf16_4
      %coord_401 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_402 = cute.tiled.copy.partition_S(%159, %144, %coord_401) : (!copy_ldsm_4_2, !memref_smem_bf16_2, !cute.coord<"?">) -> !memref_smem_bf16_10
      %iter_403 = cute.get_iter(%src_partitioned_402) : !memref_smem_bf16_10
      %retiled_404 = cute.tiled.copy.retile(%159, %frg_B_316) : (!copy_ldsm_4_2, !memref_rmem_bf16_2) -> !memref_rmem_bf16_5
      %iter_405 = cute.get_iter(%retiled_404) : !memref_rmem_bf16_5
      %coord_406 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_407 = cute.tiled.copy.partition_S(%163, %view_281, %coord_406) : (!copy_ldsm_4_3, !memref_smem_bf16_1, !cute.coord<"?">) -> !memref_smem_bf16_11
      %iter_408 = cute.get_iter(%src_partitioned_407) : !memref_smem_bf16_11
      %lay_409 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %164 = cute.get_shape(%lay_409) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_410, %e1_411, %e2_412, %e3_413 = cute.get_leaves(%164) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_414 = cute.to_int_tuple(%e0_410) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %165 = cute.get_scalars(%itup_414) : !cute.int_tuple<"?">
      %itup_415 = cute.to_int_tuple(%e1_411) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %166 = cute.get_scalars(%itup_415) : !cute.int_tuple<"?">
      %itup_416 = cute.to_int_tuple(%e2_412) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %167 = cute.get_scalars(%itup_416) : !cute.int_tuple<"?">
      %itup_417 = cute.to_int_tuple(%e3_413) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %168 = cute.get_scalars(%itup_417) : !cute.int_tuple<"?{div=8}">
      %shape_418 = cute.make_shape(%itup_414, %itup_415, %itup_416, %itup_417) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %169 = cute.make_identity_tensor(%shape_418) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_419 = cute.get_iter(%169) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_420, %e1_421, %e2_422, %e3_423 = cute.get_leaves(%iter_419) : !cute.int_tuple<"(0,0,0,0)">
      %lay_424 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %170 = cute.get_shape(%lay_424) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_425, %e1_426, %e2_427, %e3_428 = cute.get_leaves(%170) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_429 = cute.to_int_tuple(%e0_425) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %171 = cute.get_scalars(%itup_429) : !cute.int_tuple<"?">
      %itup_430 = cute.to_int_tuple(%e1_426) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %172 = cute.get_scalars(%itup_430) : !cute.int_tuple<"?">
      %itup_431 = cute.to_int_tuple(%e2_427) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %173 = cute.get_scalars(%itup_431) : !cute.int_tuple<"?">
      %itup_432 = cute.to_int_tuple(%e3_428) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %174 = cute.get_scalars(%itup_432) : !cute.int_tuple<"?{div=8}">
      %shape_433 = cute.make_shape(%itup_429, %itup_430, %itup_431, %itup_432) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %175 = cute.make_identity_tensor(%shape_433) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_434 = cute.get_iter(%175) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_435, %e1_436, %e2_437, %e3_438 = cute.get_leaves(%iter_434) : !cute.int_tuple<"(0,0,0,0)">
      %lay_439 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %176 = cute.get_shape(%lay_439) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_440, %e1_441, %e2_442, %e3_443 = cute.get_leaves(%176) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_444 = cute.to_int_tuple(%e0_440) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %177 = cute.get_scalars(%itup_444) : !cute.int_tuple<"?">
      %itup_445 = cute.to_int_tuple(%e1_441) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %178 = cute.get_scalars(%itup_445) : !cute.int_tuple<"?">
      %itup_446 = cute.to_int_tuple(%e2_442) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %179 = cute.get_scalars(%itup_446) : !cute.int_tuple<"?">
      %itup_447 = cute.to_int_tuple(%e3_443) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %180 = cute.get_scalars(%itup_447) : !cute.int_tuple<"?{div=8}">
      %shape_448 = cute.make_shape(%itup_444, %itup_445, %itup_446, %itup_447) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %181 = cute.make_identity_tensor(%shape_448) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_449 = cute.get_iter(%181) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_450, %e1_451, %e2_452, %e3_453 = cute.get_leaves(%iter_449) : !cute.int_tuple<"(0,0,0,0)">
      %coord_454 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_455 = cute.slice(%169, %coord_454) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_456 = cute.get_iter(%slice_455) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_457, %e1_458, %e2_459, %e3_460 = cute.get_leaves(%iter_456) : !cute.int_tuple<"(?,0,?,0)">
      %182 = cute.get_scalars(%e0_457) : !cute.int_tuple<"?">
      %183 = cute.get_scalars(%e2_459) : !cute.int_tuple<"?">
      %tile_461 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_462 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_463 = cute.local_tile(%slice_455, %tile_461, %coord_462) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_464 = cute.get_iter(%tiled_view_463) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_465, %e1_466, %e2_467, %e3_468 = cute.get_leaves(%iter_464) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %184 = cute.get_scalars(%e0_465) : !cute.int_tuple<"?">
      %185 = cute.get_scalars(%e1_466) : !cute.int_tuple<"?{div=64}">
      %186 = cute.get_scalars(%e2_467) : !cute.int_tuple<"?">
      %coord_469 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_470 = cute.slice(%175, %coord_469) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_471 = cute.get_iter(%slice_470) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_472, %e1_473, %e2_474, %e3_475 = cute.get_leaves(%iter_471) : !cute.int_tuple<"(?,0,?,0)">
      %187 = cute.get_scalars(%e0_472) : !cute.int_tuple<"?">
      %188 = cute.get_scalars(%e2_474) : !cute.int_tuple<"?">
      %tile_476 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_477 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_478 = cute.local_tile(%slice_470, %tile_476, %coord_477) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_479 = cute.get_iter(%tiled_view_478) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_480, %e1_481, %e2_482, %e3_483 = cute.get_leaves(%iter_479) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %189 = cute.get_scalars(%e0_480) : !cute.int_tuple<"?">
      %190 = cute.get_scalars(%e1_481) : !cute.int_tuple<"?{div=64}">
      %191 = cute.get_scalars(%e2_482) : !cute.int_tuple<"?">
      %coord_484 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %slice_485 = cute.slice(%181, %coord_484) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,?,_,_)">
      %iter_486 = cute.get_iter(%slice_485) : !cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">
      %e0_487, %e1_488, %e2_489, %e3_490 = cute.get_leaves(%iter_486) : !cute.int_tuple<"(?,?,0,0)">
      %192 = cute.get_scalars(%e0_487) : !cute.int_tuple<"?">
      %193 = cute.get_scalars(%e1_488) : !cute.int_tuple<"?">
      %tile_491 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
      %coord_492 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %tiled_view_493 = cute.local_tile(%slice_485, %tile_491, %coord_492) : (!cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,_)">) -> !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">
      %iter_494 = cute.get_iter(%tiled_view_493) : !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">
      %e0_495, %e1_496, %e2_497, %e3_498 = cute.get_leaves(%iter_494) : !cute.int_tuple<"(?,?,?{div=64},0)">
      %194 = cute.get_scalars(%e0_495) : !cute.int_tuple<"?">
      %195 = cute.get_scalars(%e1_496) : !cute.int_tuple<"?">
      %196 = cute.get_scalars(%e2_497) : !cute.int_tuple<"?{div=64}">
      %coord_499 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_500 = cute.tiled.copy.partition_S(%arg9, %tiled_view_463, %coord_499) : (!copy_ldgsts, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_501 = cute.get_iter(%src_partitioned_500) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_502, %e1_503, %e2_504, %e3_505 = cute.get_leaves(%iter_501) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %197 = cute.get_scalars(%e0_502) : !cute.int_tuple<"?">
      %198 = cute.get_scalars(%e1_503) : !cute.int_tuple<"?">
      %199 = cute.get_scalars(%e2_504) : !cute.int_tuple<"?">
      %200 = cute.get_scalars(%e3_505) : !cute.int_tuple<"?{div=8}">
      %coord_506 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_507 = cute.tiled.copy.partition_S(%arg9, %tiled_view_478, %coord_506) : (!copy_ldgsts, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_508 = cute.get_iter(%src_partitioned_507) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_509, %e1_510, %e2_511, %e3_512 = cute.get_leaves(%iter_508) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %201 = cute.get_scalars(%e0_509) : !cute.int_tuple<"?">
      %202 = cute.get_scalars(%e1_510) : !cute.int_tuple<"?">
      %203 = cute.get_scalars(%e2_511) : !cute.int_tuple<"?">
      %204 = cute.get_scalars(%e3_512) : !cute.int_tuple<"?{div=8}">
      %coord_513 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_514 = cute.tiled.copy.partition_S(%arg9, %tiled_view_493, %coord_513) : (!copy_ldgsts, !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %iter_515 = cute.get_iter(%src_partitioned_514) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %e0_516, %e1_517, %e2_518, %e3_519 = cute.get_leaves(%iter_515) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %205 = cute.get_scalars(%e0_516) : !cute.int_tuple<"?">
      %206 = cute.get_scalars(%e1_517) : !cute.int_tuple<"?">
      %207 = cute.get_scalars(%e2_518) : !cute.int_tuple<"?">
      %208 = cute.get_scalars(%e3_519) : !cute.int_tuple<"?{div=8}">
      %lay_520 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_3
      %209 = cute.get_shape(%lay_520) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_521, %e1_522, %e2_523, %e3_524 = cute.get_leaves(%209) : !cute.shape<"((8,1),4,2)">
      %sz_525 = cute.size(%dst_partitioned) <{mode = [1]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"4">
      %e0_526 = cute.get_leaves(%sz_525) : !cute.int_tuple<"4">
      %sz_527 = cute.size(%dst_partitioned) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_528 = cute.get_leaves(%sz_527) : !cute.int_tuple<"2">
      %sz_529 = cute.size(%dst_partitioned) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_530 = cute.get_leaves(%sz_529) : !cute.int_tuple<"2">
      %shape_531 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_532 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_533 = cute.make_layout(%shape_531, %stride_532) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_534 = cute.memref.alloca(%lay_533) : !memref_rmem_i8_
      %iter_535 = cute.get_iter(%rmem_534) : !memref_rmem_i8_
      %iter_536 = cute.get_iter(%rmem_534) : !memref_rmem_i8_
      %lay_537 = cute.get_layout(%dst_partitioned_293) : !memref_smem_bf16_3
      %210 = cute.get_shape(%lay_537) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_538, %e1_539, %e2_540, %e3_541 = cute.get_leaves(%210) : !cute.shape<"((8,1),4,2)">
      %sz_542 = cute.size(%dst_partitioned_293) <{mode = [1]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"4">
      %e0_543 = cute.get_leaves(%sz_542) : !cute.int_tuple<"4">
      %sz_544 = cute.size(%dst_partitioned_293) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_545 = cute.get_leaves(%sz_544) : !cute.int_tuple<"2">
      %sz_546 = cute.size(%dst_partitioned_293) <{mode = [2]}> : (!memref_smem_bf16_3) -> !cute.int_tuple<"2">
      %e0_547 = cute.get_leaves(%sz_546) : !cute.int_tuple<"2">
      %shape_548 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_549 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_550 = cute.make_layout(%shape_548, %stride_549) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_551 = cute.memref.alloca(%lay_550) : !memref_rmem_i8_
      %iter_552 = cute.get_iter(%rmem_551) : !memref_rmem_i8_
      %iter_553 = cute.get_iter(%rmem_551) : !memref_rmem_i8_
      %lay_554 = cute.get_layout(%rmem_534) : !memref_rmem_i8_
      %211 = cute.get_shape(%lay_554) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_555, %e1_556, %e2_557 = cute.get_leaves(%211) : !cute.shape<"(1,4,2)">
      %coord_558 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_559 = cute.slice(%src_partitioned_500, %coord_558) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_560 = cute.get_iter(%slice_559) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_561, %e1_562, %e2_563, %e3_564 = cute.get_leaves(%iter_560) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %212 = cute.get_scalars(%e0_561) : !cute.int_tuple<"?">
      %213 = cute.get_scalars(%e1_562) : !cute.int_tuple<"?">
      %214 = cute.get_scalars(%e2_563) : !cute.int_tuple<"?">
      %215 = cute.get_scalars(%e3_564) : !cute.int_tuple<"?{div=8}">
      %iter_565 = cute.get_iter(%slice_559) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_566, %e1_567, %e2_568, %e3_569 = cute.get_leaves(%iter_565) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %216 = cute.get_scalars(%e0_566) : !cute.int_tuple<"?">
      %217 = cute.get_scalars(%e1_567) : !cute.int_tuple<"?">
      %218 = cute.get_scalars(%e2_568) : !cute.int_tuple<"?">
      %219 = cute.get_scalars(%e3_569) : !cute.int_tuple<"?{div=8}">
      %iter_570 = cute.get_iter(%slice_559) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_571, %e1_572, %e2_573, %e3_574 = cute.get_leaves(%iter_570) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %220 = cute.get_scalars(%e0_571) : !cute.int_tuple<"?">
      %221 = cute.get_scalars(%e1_572) : !cute.int_tuple<"?">
      %222 = cute.get_scalars(%e2_573) : !cute.int_tuple<"?">
      %223 = cute.get_scalars(%e3_574) : !cute.int_tuple<"?{div=8}">
      %lay_575 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %224 = cute.get_shape(%lay_575) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_576, %e1_577, %e2_578, %e3_579 = cute.get_leaves(%224) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_580 = cute.to_int_tuple(%e0_576) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %225 = cute.get_scalars(%itup_580) : !cute.int_tuple<"?">
      %itup_581 = cute.to_int_tuple(%e1_577) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %226 = cute.get_scalars(%itup_581) : !cute.int_tuple<"?">
      %itup_582 = cute.to_int_tuple(%e2_578) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %227 = cute.get_scalars(%itup_582) : !cute.int_tuple<"?">
      %itup_583 = cute.to_int_tuple(%e3_579) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %228 = cute.get_scalars(%itup_583) : !cute.int_tuple<"?{div=8}">
      %coord_584 = cute.make_coord(%e3_574) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_585 = cute.make_coord(%itup_583) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %229 = cute.elem_less(%coord_584, %coord_585) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %230 = arith.extui %229 : i1 to i8
      %coord_586 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_534, %coord_586, %230) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_587 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_588 = cute.slice(%src_partitioned_500, %coord_587) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_589 = cute.get_iter(%slice_588) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_590, %e1_591, %e2_592, %e3_593 = cute.get_leaves(%iter_589) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %231 = cute.get_scalars(%e0_590) : !cute.int_tuple<"?">
      %232 = cute.get_scalars(%e1_591) : !cute.int_tuple<"?">
      %233 = cute.get_scalars(%e2_592) : !cute.int_tuple<"?">
      %234 = cute.get_scalars(%e3_593) : !cute.int_tuple<"?{div=8}">
      %iter_594 = cute.get_iter(%slice_588) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_595, %e1_596, %e2_597, %e3_598 = cute.get_leaves(%iter_594) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %235 = cute.get_scalars(%e0_595) : !cute.int_tuple<"?">
      %236 = cute.get_scalars(%e1_596) : !cute.int_tuple<"?">
      %237 = cute.get_scalars(%e2_597) : !cute.int_tuple<"?">
      %238 = cute.get_scalars(%e3_598) : !cute.int_tuple<"?{div=8}">
      %iter_599 = cute.get_iter(%slice_588) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_600, %e1_601, %e2_602, %e3_603 = cute.get_leaves(%iter_599) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %239 = cute.get_scalars(%e0_600) : !cute.int_tuple<"?">
      %240 = cute.get_scalars(%e1_601) : !cute.int_tuple<"?">
      %241 = cute.get_scalars(%e2_602) : !cute.int_tuple<"?">
      %242 = cute.get_scalars(%e3_603) : !cute.int_tuple<"?{div=8}">
      %lay_604 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %243 = cute.get_shape(%lay_604) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_605, %e1_606, %e2_607, %e3_608 = cute.get_leaves(%243) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_609 = cute.to_int_tuple(%e0_605) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %244 = cute.get_scalars(%itup_609) : !cute.int_tuple<"?">
      %itup_610 = cute.to_int_tuple(%e1_606) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %245 = cute.get_scalars(%itup_610) : !cute.int_tuple<"?">
      %itup_611 = cute.to_int_tuple(%e2_607) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %246 = cute.get_scalars(%itup_611) : !cute.int_tuple<"?">
      %itup_612 = cute.to_int_tuple(%e3_608) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %247 = cute.get_scalars(%itup_612) : !cute.int_tuple<"?{div=8}">
      %coord_613 = cute.make_coord(%e3_603) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_614 = cute.make_coord(%itup_612) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %248 = cute.elem_less(%coord_613, %coord_614) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %249 = arith.extui %248 : i1 to i8
      %coord_615 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_534, %coord_615, %249) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %lay_616 = cute.get_layout(%rmem_551) : !memref_rmem_i8_
      %250 = cute.get_shape(%lay_616) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_617, %e1_618, %e2_619 = cute.get_leaves(%250) : !cute.shape<"(1,4,2)">
      %coord_620 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_621 = cute.slice(%src_partitioned_507, %coord_620) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_622 = cute.get_iter(%slice_621) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_623, %e1_624, %e2_625, %e3_626 = cute.get_leaves(%iter_622) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %251 = cute.get_scalars(%e0_623) : !cute.int_tuple<"?">
      %252 = cute.get_scalars(%e1_624) : !cute.int_tuple<"?">
      %253 = cute.get_scalars(%e2_625) : !cute.int_tuple<"?">
      %254 = cute.get_scalars(%e3_626) : !cute.int_tuple<"?{div=8}">
      %iter_627 = cute.get_iter(%slice_621) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_628, %e1_629, %e2_630, %e3_631 = cute.get_leaves(%iter_627) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %255 = cute.get_scalars(%e0_628) : !cute.int_tuple<"?">
      %256 = cute.get_scalars(%e1_629) : !cute.int_tuple<"?">
      %257 = cute.get_scalars(%e2_630) : !cute.int_tuple<"?">
      %258 = cute.get_scalars(%e3_631) : !cute.int_tuple<"?{div=8}">
      %iter_632 = cute.get_iter(%slice_621) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_633, %e1_634, %e2_635, %e3_636 = cute.get_leaves(%iter_632) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %259 = cute.get_scalars(%e0_633) : !cute.int_tuple<"?">
      %260 = cute.get_scalars(%e1_634) : !cute.int_tuple<"?">
      %261 = cute.get_scalars(%e2_635) : !cute.int_tuple<"?">
      %262 = cute.get_scalars(%e3_636) : !cute.int_tuple<"?{div=8}">
      %lay_637 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %263 = cute.get_shape(%lay_637) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_638, %e1_639, %e2_640, %e3_641 = cute.get_leaves(%263) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_642 = cute.to_int_tuple(%e0_638) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %264 = cute.get_scalars(%itup_642) : !cute.int_tuple<"?">
      %itup_643 = cute.to_int_tuple(%e1_639) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %265 = cute.get_scalars(%itup_643) : !cute.int_tuple<"?">
      %itup_644 = cute.to_int_tuple(%e2_640) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %266 = cute.get_scalars(%itup_644) : !cute.int_tuple<"?">
      %itup_645 = cute.to_int_tuple(%e3_641) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %267 = cute.get_scalars(%itup_645) : !cute.int_tuple<"?{div=8}">
      %coord_646 = cute.make_coord(%e3_636) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_647 = cute.make_coord(%itup_645) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %268 = cute.elem_less(%coord_646, %coord_647) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %269 = arith.extui %268 : i1 to i8
      %coord_648 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_551, %coord_648, %269) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_649 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_650 = cute.slice(%src_partitioned_507, %coord_649) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_651 = cute.get_iter(%slice_650) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_652, %e1_653, %e2_654, %e3_655 = cute.get_leaves(%iter_651) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %270 = cute.get_scalars(%e0_652) : !cute.int_tuple<"?">
      %271 = cute.get_scalars(%e1_653) : !cute.int_tuple<"?">
      %272 = cute.get_scalars(%e2_654) : !cute.int_tuple<"?">
      %273 = cute.get_scalars(%e3_655) : !cute.int_tuple<"?{div=8}">
      %iter_656 = cute.get_iter(%slice_650) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_657, %e1_658, %e2_659, %e3_660 = cute.get_leaves(%iter_656) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %274 = cute.get_scalars(%e0_657) : !cute.int_tuple<"?">
      %275 = cute.get_scalars(%e1_658) : !cute.int_tuple<"?">
      %276 = cute.get_scalars(%e2_659) : !cute.int_tuple<"?">
      %277 = cute.get_scalars(%e3_660) : !cute.int_tuple<"?{div=8}">
      %iter_661 = cute.get_iter(%slice_650) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_662, %e1_663, %e2_664, %e3_665 = cute.get_leaves(%iter_661) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %278 = cute.get_scalars(%e0_662) : !cute.int_tuple<"?">
      %279 = cute.get_scalars(%e1_663) : !cute.int_tuple<"?">
      %280 = cute.get_scalars(%e2_664) : !cute.int_tuple<"?">
      %281 = cute.get_scalars(%e3_665) : !cute.int_tuple<"?{div=8}">
      %lay_666 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %282 = cute.get_shape(%lay_666) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_667, %e1_668, %e2_669, %e3_670 = cute.get_leaves(%282) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_671 = cute.to_int_tuple(%e0_667) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %283 = cute.get_scalars(%itup_671) : !cute.int_tuple<"?">
      %itup_672 = cute.to_int_tuple(%e1_668) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %284 = cute.get_scalars(%itup_672) : !cute.int_tuple<"?">
      %itup_673 = cute.to_int_tuple(%e2_669) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %285 = cute.get_scalars(%itup_673) : !cute.int_tuple<"?">
      %itup_674 = cute.to_int_tuple(%e3_670) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %286 = cute.get_scalars(%itup_674) : !cute.int_tuple<"?{div=8}">
      %coord_675 = cute.make_coord(%e3_665) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_676 = cute.make_coord(%itup_674) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %287 = cute.elem_less(%coord_675, %coord_676) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %288 = arith.extui %287 : i1 to i8
      %coord_677 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_551, %coord_677, %288) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %int_tuple_678 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_679 = cute.size(%int_tuple_678) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_680 = cute.get_leaves(%sz_679) : !cute.int_tuple<"4">
      %coord_681 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_682 = cute.slice(%src_partitioned_500, %coord_681) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_683 = cute.get_iter(%slice_682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_684, %e1_685, %e2_686, %e3_687 = cute.get_leaves(%iter_683) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %289 = cute.get_scalars(%e0_684) : !cute.int_tuple<"?">
      %290 = cute.get_scalars(%e1_685) : !cute.int_tuple<"?">
      %291 = cute.get_scalars(%e2_686) : !cute.int_tuple<"?">
      %292 = cute.get_scalars(%e3_687) : !cute.int_tuple<"?{div=8}">
      %iter_688 = cute.get_iter(%slice_682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_689, %e1_690, %e2_691, %e3_692 = cute.get_leaves(%iter_688) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %293 = cute.get_scalars(%e0_689) : !cute.int_tuple<"?">
      %294 = cute.get_scalars(%e1_690) : !cute.int_tuple<"?">
      %295 = cute.get_scalars(%e2_691) : !cute.int_tuple<"?">
      %296 = cute.get_scalars(%e3_692) : !cute.int_tuple<"?{div=8}">
      %iter_693 = cute.get_iter(%slice_682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_694, %e1_695, %e2_696, %e3_697 = cute.get_leaves(%iter_693) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %297 = cute.get_scalars(%e0_694) : !cute.int_tuple<"?">
      %298 = cute.get_scalars(%e1_695) : !cute.int_tuple<"?">
      %299 = cute.get_scalars(%e2_696) : !cute.int_tuple<"?">
      %300 = cute.get_scalars(%e3_697) : !cute.int_tuple<"?{div=8}">
      %lay_698 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %301 = cute.get_shape(%lay_698) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_699, %e1_700, %e2_701, %e3_702 = cute.get_leaves(%301) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_703 = cute.to_int_tuple(%e0_699) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %302 = cute.get_scalars(%itup_703) : !cute.int_tuple<"?">
      %itup_704 = cute.to_int_tuple(%e1_700) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %303 = cute.get_scalars(%itup_704) : !cute.int_tuple<"?">
      %itup_705 = cute.to_int_tuple(%e2_701) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %304 = cute.get_scalars(%itup_705) : !cute.int_tuple<"?">
      %itup_706 = cute.to_int_tuple(%e3_702) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %305 = cute.get_scalars(%itup_706) : !cute.int_tuple<"?{div=8}">
      %coord_707 = cute.make_coord(%e1_695) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_708 = cute.make_coord(%itup_704) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %306 = cute.elem_less(%coord_707, %coord_708) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %306 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1744 = cute.slice(%src_partitioned, %coord_1743) : !memref_gmem_bf16_5, !cute.coord<"(_,0,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1747 = cute.slice(%dst_partitioned, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1750 = cute.slice(%rmem_534, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1744 = cute.slice(%dst_partitioned, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_709 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_710 = cute.slice(%src_partitioned_500, %coord_709) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_711 = cute.get_iter(%slice_710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_712, %e1_713, %e2_714, %e3_715 = cute.get_leaves(%iter_711) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %307 = cute.get_scalars(%e0_712) : !cute.int_tuple<"?">
      %308 = cute.get_scalars(%e1_713) : !cute.int_tuple<"?">
      %309 = cute.get_scalars(%e2_714) : !cute.int_tuple<"?">
      %310 = cute.get_scalars(%e3_715) : !cute.int_tuple<"?{div=8}">
      %iter_716 = cute.get_iter(%slice_710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_717, %e1_718, %e2_719, %e3_720 = cute.get_leaves(%iter_716) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %311 = cute.get_scalars(%e0_717) : !cute.int_tuple<"?">
      %312 = cute.get_scalars(%e1_718) : !cute.int_tuple<"?">
      %313 = cute.get_scalars(%e2_719) : !cute.int_tuple<"?">
      %314 = cute.get_scalars(%e3_720) : !cute.int_tuple<"?{div=8}">
      %iter_721 = cute.get_iter(%slice_710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_722, %e1_723, %e2_724, %e3_725 = cute.get_leaves(%iter_721) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %315 = cute.get_scalars(%e0_722) : !cute.int_tuple<"?">
      %316 = cute.get_scalars(%e1_723) : !cute.int_tuple<"?">
      %317 = cute.get_scalars(%e2_724) : !cute.int_tuple<"?">
      %318 = cute.get_scalars(%e3_725) : !cute.int_tuple<"?{div=8}">
      %lay_726 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %319 = cute.get_shape(%lay_726) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_727, %e1_728, %e2_729, %e3_730 = cute.get_leaves(%319) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_731 = cute.to_int_tuple(%e0_727) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %320 = cute.get_scalars(%itup_731) : !cute.int_tuple<"?">
      %itup_732 = cute.to_int_tuple(%e1_728) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %321 = cute.get_scalars(%itup_732) : !cute.int_tuple<"?">
      %itup_733 = cute.to_int_tuple(%e2_729) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %322 = cute.get_scalars(%itup_733) : !cute.int_tuple<"?">
      %itup_734 = cute.to_int_tuple(%e3_730) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %323 = cute.get_scalars(%itup_734) : !cute.int_tuple<"?{div=8}">
      %coord_735 = cute.make_coord(%e1_723) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_736 = cute.make_coord(%itup_732) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %324 = cute.elem_less(%coord_735, %coord_736) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %324 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1744 = cute.slice(%src_partitioned, %coord_1743) : !memref_gmem_bf16_5, !cute.coord<"(_,1,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1747 = cute.slice(%dst_partitioned, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1750 = cute.slice(%rmem_534, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1744 = cute.slice(%dst_partitioned, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_737 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_738 = cute.slice(%src_partitioned_500, %coord_737) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_739 = cute.get_iter(%slice_738) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_740, %e1_741, %e2_742, %e3_743 = cute.get_leaves(%iter_739) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %325 = cute.get_scalars(%e0_740) : !cute.int_tuple<"?">
      %326 = cute.get_scalars(%e1_741) : !cute.int_tuple<"?">
      %327 = cute.get_scalars(%e2_742) : !cute.int_tuple<"?">
      %328 = cute.get_scalars(%e3_743) : !cute.int_tuple<"?{div=8}">
      %iter_744 = cute.get_iter(%slice_738) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_745, %e1_746, %e2_747, %e3_748 = cute.get_leaves(%iter_744) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %329 = cute.get_scalars(%e0_745) : !cute.int_tuple<"?">
      %330 = cute.get_scalars(%e1_746) : !cute.int_tuple<"?">
      %331 = cute.get_scalars(%e2_747) : !cute.int_tuple<"?">
      %332 = cute.get_scalars(%e3_748) : !cute.int_tuple<"?{div=8}">
      %iter_749 = cute.get_iter(%slice_738) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_750, %e1_751, %e2_752, %e3_753 = cute.get_leaves(%iter_749) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %333 = cute.get_scalars(%e0_750) : !cute.int_tuple<"?">
      %334 = cute.get_scalars(%e1_751) : !cute.int_tuple<"?">
      %335 = cute.get_scalars(%e2_752) : !cute.int_tuple<"?">
      %336 = cute.get_scalars(%e3_753) : !cute.int_tuple<"?{div=8}">
      %lay_754 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %337 = cute.get_shape(%lay_754) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_755, %e1_756, %e2_757, %e3_758 = cute.get_leaves(%337) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_759 = cute.to_int_tuple(%e0_755) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %338 = cute.get_scalars(%itup_759) : !cute.int_tuple<"?">
      %itup_760 = cute.to_int_tuple(%e1_756) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %339 = cute.get_scalars(%itup_760) : !cute.int_tuple<"?">
      %itup_761 = cute.to_int_tuple(%e2_757) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %340 = cute.get_scalars(%itup_761) : !cute.int_tuple<"?">
      %itup_762 = cute.to_int_tuple(%e3_758) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %341 = cute.get_scalars(%itup_762) : !cute.int_tuple<"?{div=8}">
      %coord_763 = cute.make_coord(%e1_751) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_764 = cute.make_coord(%itup_760) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %342 = cute.elem_less(%coord_763, %coord_764) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %342 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1744 = cute.slice(%src_partitioned, %coord_1743) : !memref_gmem_bf16_5, !cute.coord<"(_,2,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1747 = cute.slice(%dst_partitioned, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1750 = cute.slice(%rmem_534, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1744 = cute.slice(%dst_partitioned, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_765 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_766 = cute.slice(%src_partitioned_500, %coord_765) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_767 = cute.get_iter(%slice_766) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_768, %e1_769, %e2_770, %e3_771 = cute.get_leaves(%iter_767) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %343 = cute.get_scalars(%e0_768) : !cute.int_tuple<"?">
      %344 = cute.get_scalars(%e1_769) : !cute.int_tuple<"?">
      %345 = cute.get_scalars(%e2_770) : !cute.int_tuple<"?">
      %346 = cute.get_scalars(%e3_771) : !cute.int_tuple<"?{div=8}">
      %iter_772 = cute.get_iter(%slice_766) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_773, %e1_774, %e2_775, %e3_776 = cute.get_leaves(%iter_772) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %347 = cute.get_scalars(%e0_773) : !cute.int_tuple<"?">
      %348 = cute.get_scalars(%e1_774) : !cute.int_tuple<"?">
      %349 = cute.get_scalars(%e2_775) : !cute.int_tuple<"?">
      %350 = cute.get_scalars(%e3_776) : !cute.int_tuple<"?{div=8}">
      %iter_777 = cute.get_iter(%slice_766) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_778, %e1_779, %e2_780, %e3_781 = cute.get_leaves(%iter_777) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %351 = cute.get_scalars(%e0_778) : !cute.int_tuple<"?">
      %352 = cute.get_scalars(%e1_779) : !cute.int_tuple<"?">
      %353 = cute.get_scalars(%e2_780) : !cute.int_tuple<"?">
      %354 = cute.get_scalars(%e3_781) : !cute.int_tuple<"?{div=8}">
      %lay_782 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %355 = cute.get_shape(%lay_782) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_783, %e1_784, %e2_785, %e3_786 = cute.get_leaves(%355) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_787 = cute.to_int_tuple(%e0_783) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %356 = cute.get_scalars(%itup_787) : !cute.int_tuple<"?">
      %itup_788 = cute.to_int_tuple(%e1_784) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %357 = cute.get_scalars(%itup_788) : !cute.int_tuple<"?">
      %itup_789 = cute.to_int_tuple(%e2_785) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %358 = cute.get_scalars(%itup_789) : !cute.int_tuple<"?">
      %itup_790 = cute.to_int_tuple(%e3_786) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %359 = cute.get_scalars(%itup_790) : !cute.int_tuple<"?{div=8}">
      %coord_791 = cute.make_coord(%e1_779) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_792 = cute.make_coord(%itup_788) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %360 = cute.elem_less(%coord_791, %coord_792) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %360 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1744 = cute.slice(%src_partitioned, %coord_1743) : !memref_gmem_bf16_5, !cute.coord<"(_,3,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1747 = cute.slice(%dst_partitioned, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1750 = cute.slice(%rmem_534, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1744 = cute.slice(%dst_partitioned, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %int_tuple_793 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_794 = cute.size(%int_tuple_793) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_795 = cute.get_leaves(%sz_794) : !cute.int_tuple<"4">
      %coord_796 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_797 = cute.slice(%src_partitioned_507, %coord_796) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_798 = cute.get_iter(%slice_797) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_799, %e1_800, %e2_801, %e3_802 = cute.get_leaves(%iter_798) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %361 = cute.get_scalars(%e0_799) : !cute.int_tuple<"?">
      %362 = cute.get_scalars(%e1_800) : !cute.int_tuple<"?">
      %363 = cute.get_scalars(%e2_801) : !cute.int_tuple<"?">
      %364 = cute.get_scalars(%e3_802) : !cute.int_tuple<"?{div=8}">
      %iter_803 = cute.get_iter(%slice_797) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_804, %e1_805, %e2_806, %e3_807 = cute.get_leaves(%iter_803) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %365 = cute.get_scalars(%e0_804) : !cute.int_tuple<"?">
      %366 = cute.get_scalars(%e1_805) : !cute.int_tuple<"?">
      %367 = cute.get_scalars(%e2_806) : !cute.int_tuple<"?">
      %368 = cute.get_scalars(%e3_807) : !cute.int_tuple<"?{div=8}">
      %iter_808 = cute.get_iter(%slice_797) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_809, %e1_810, %e2_811, %e3_812 = cute.get_leaves(%iter_808) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %369 = cute.get_scalars(%e0_809) : !cute.int_tuple<"?">
      %370 = cute.get_scalars(%e1_810) : !cute.int_tuple<"?">
      %371 = cute.get_scalars(%e2_811) : !cute.int_tuple<"?">
      %372 = cute.get_scalars(%e3_812) : !cute.int_tuple<"?{div=8}">
      %lay_813 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %373 = cute.get_shape(%lay_813) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_814, %e1_815, %e2_816, %e3_817 = cute.get_leaves(%373) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_818 = cute.to_int_tuple(%e0_814) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %374 = cute.get_scalars(%itup_818) : !cute.int_tuple<"?">
      %itup_819 = cute.to_int_tuple(%e1_815) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %375 = cute.get_scalars(%itup_819) : !cute.int_tuple<"?">
      %itup_820 = cute.to_int_tuple(%e2_816) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %376 = cute.get_scalars(%itup_820) : !cute.int_tuple<"?">
      %itup_821 = cute.to_int_tuple(%e3_817) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %377 = cute.get_scalars(%itup_821) : !cute.int_tuple<"?{div=8}">
      %coord_822 = cute.make_coord(%e1_810) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_823 = cute.make_coord(%itup_819) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %378 = cute.elem_less(%coord_822, %coord_823) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %378 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %slice_1744 = cute.slice(%src_partitioned_290, %coord_1743) : !memref_gmem_bf16_6, !cute.coord<"(_,0,_,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1747 = cute.slice(%dst_partitioned_293, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1750 = cute.slice(%rmem_551, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1744 = cute.slice(%dst_partitioned_293, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_824 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_825 = cute.slice(%src_partitioned_507, %coord_824) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_826 = cute.get_iter(%slice_825) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_827, %e1_828, %e2_829, %e3_830 = cute.get_leaves(%iter_826) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %379 = cute.get_scalars(%e0_827) : !cute.int_tuple<"?">
      %380 = cute.get_scalars(%e1_828) : !cute.int_tuple<"?">
      %381 = cute.get_scalars(%e2_829) : !cute.int_tuple<"?">
      %382 = cute.get_scalars(%e3_830) : !cute.int_tuple<"?{div=8}">
      %iter_831 = cute.get_iter(%slice_825) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_832, %e1_833, %e2_834, %e3_835 = cute.get_leaves(%iter_831) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %383 = cute.get_scalars(%e0_832) : !cute.int_tuple<"?">
      %384 = cute.get_scalars(%e1_833) : !cute.int_tuple<"?">
      %385 = cute.get_scalars(%e2_834) : !cute.int_tuple<"?">
      %386 = cute.get_scalars(%e3_835) : !cute.int_tuple<"?{div=8}">
      %iter_836 = cute.get_iter(%slice_825) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_837, %e1_838, %e2_839, %e3_840 = cute.get_leaves(%iter_836) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %387 = cute.get_scalars(%e0_837) : !cute.int_tuple<"?">
      %388 = cute.get_scalars(%e1_838) : !cute.int_tuple<"?">
      %389 = cute.get_scalars(%e2_839) : !cute.int_tuple<"?">
      %390 = cute.get_scalars(%e3_840) : !cute.int_tuple<"?{div=8}">
      %lay_841 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %391 = cute.get_shape(%lay_841) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_842, %e1_843, %e2_844, %e3_845 = cute.get_leaves(%391) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_846 = cute.to_int_tuple(%e0_842) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %392 = cute.get_scalars(%itup_846) : !cute.int_tuple<"?">
      %itup_847 = cute.to_int_tuple(%e1_843) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %393 = cute.get_scalars(%itup_847) : !cute.int_tuple<"?">
      %itup_848 = cute.to_int_tuple(%e2_844) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %394 = cute.get_scalars(%itup_848) : !cute.int_tuple<"?">
      %itup_849 = cute.to_int_tuple(%e3_845) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %395 = cute.get_scalars(%itup_849) : !cute.int_tuple<"?{div=8}">
      %coord_850 = cute.make_coord(%e1_838) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_851 = cute.make_coord(%itup_847) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %396 = cute.elem_less(%coord_850, %coord_851) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %396 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %slice_1744 = cute.slice(%src_partitioned_290, %coord_1743) : !memref_gmem_bf16_6, !cute.coord<"(_,1,_,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1747 = cute.slice(%dst_partitioned_293, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1750 = cute.slice(%rmem_551, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1744 = cute.slice(%dst_partitioned_293, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_852 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_853 = cute.slice(%src_partitioned_507, %coord_852) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_854 = cute.get_iter(%slice_853) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_855, %e1_856, %e2_857, %e3_858 = cute.get_leaves(%iter_854) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %397 = cute.get_scalars(%e0_855) : !cute.int_tuple<"?">
      %398 = cute.get_scalars(%e1_856) : !cute.int_tuple<"?">
      %399 = cute.get_scalars(%e2_857) : !cute.int_tuple<"?">
      %400 = cute.get_scalars(%e3_858) : !cute.int_tuple<"?{div=8}">
      %iter_859 = cute.get_iter(%slice_853) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_860, %e1_861, %e2_862, %e3_863 = cute.get_leaves(%iter_859) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %401 = cute.get_scalars(%e0_860) : !cute.int_tuple<"?">
      %402 = cute.get_scalars(%e1_861) : !cute.int_tuple<"?">
      %403 = cute.get_scalars(%e2_862) : !cute.int_tuple<"?">
      %404 = cute.get_scalars(%e3_863) : !cute.int_tuple<"?{div=8}">
      %iter_864 = cute.get_iter(%slice_853) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_865, %e1_866, %e2_867, %e3_868 = cute.get_leaves(%iter_864) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %405 = cute.get_scalars(%e0_865) : !cute.int_tuple<"?">
      %406 = cute.get_scalars(%e1_866) : !cute.int_tuple<"?">
      %407 = cute.get_scalars(%e2_867) : !cute.int_tuple<"?">
      %408 = cute.get_scalars(%e3_868) : !cute.int_tuple<"?{div=8}">
      %lay_869 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %409 = cute.get_shape(%lay_869) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_870, %e1_871, %e2_872, %e3_873 = cute.get_leaves(%409) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_874 = cute.to_int_tuple(%e0_870) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %410 = cute.get_scalars(%itup_874) : !cute.int_tuple<"?">
      %itup_875 = cute.to_int_tuple(%e1_871) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %411 = cute.get_scalars(%itup_875) : !cute.int_tuple<"?">
      %itup_876 = cute.to_int_tuple(%e2_872) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %412 = cute.get_scalars(%itup_876) : !cute.int_tuple<"?">
      %itup_877 = cute.to_int_tuple(%e3_873) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %413 = cute.get_scalars(%itup_877) : !cute.int_tuple<"?{div=8}">
      %coord_878 = cute.make_coord(%e1_866) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_879 = cute.make_coord(%itup_875) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %414 = cute.elem_less(%coord_878, %coord_879) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %414 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %slice_1744 = cute.slice(%src_partitioned_290, %coord_1743) : !memref_gmem_bf16_6, !cute.coord<"(_,2,_,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1747 = cute.slice(%dst_partitioned_293, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1750 = cute.slice(%rmem_551, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1744 = cute.slice(%dst_partitioned_293, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %coord_880 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_881 = cute.slice(%src_partitioned_507, %coord_880) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_882 = cute.get_iter(%slice_881) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_883, %e1_884, %e2_885, %e3_886 = cute.get_leaves(%iter_882) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %415 = cute.get_scalars(%e0_883) : !cute.int_tuple<"?">
      %416 = cute.get_scalars(%e1_884) : !cute.int_tuple<"?">
      %417 = cute.get_scalars(%e2_885) : !cute.int_tuple<"?">
      %418 = cute.get_scalars(%e3_886) : !cute.int_tuple<"?{div=8}">
      %iter_887 = cute.get_iter(%slice_881) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_888, %e1_889, %e2_890, %e3_891 = cute.get_leaves(%iter_887) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %419 = cute.get_scalars(%e0_888) : !cute.int_tuple<"?">
      %420 = cute.get_scalars(%e1_889) : !cute.int_tuple<"?">
      %421 = cute.get_scalars(%e2_890) : !cute.int_tuple<"?">
      %422 = cute.get_scalars(%e3_891) : !cute.int_tuple<"?{div=8}">
      %iter_892 = cute.get_iter(%slice_881) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_893, %e1_894, %e2_895, %e3_896 = cute.get_leaves(%iter_892) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %423 = cute.get_scalars(%e0_893) : !cute.int_tuple<"?">
      %424 = cute.get_scalars(%e1_894) : !cute.int_tuple<"?">
      %425 = cute.get_scalars(%e2_895) : !cute.int_tuple<"?">
      %426 = cute.get_scalars(%e3_896) : !cute.int_tuple<"?{div=8}">
      %lay_897 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %427 = cute.get_shape(%lay_897) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_898, %e1_899, %e2_900, %e3_901 = cute.get_leaves(%427) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_902 = cute.to_int_tuple(%e0_898) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %428 = cute.get_scalars(%itup_902) : !cute.int_tuple<"?">
      %itup_903 = cute.to_int_tuple(%e1_899) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %429 = cute.get_scalars(%itup_903) : !cute.int_tuple<"?">
      %itup_904 = cute.to_int_tuple(%e2_900) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %430 = cute.get_scalars(%itup_904) : !cute.int_tuple<"?">
      %itup_905 = cute.to_int_tuple(%e3_901) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %431 = cute.get_scalars(%itup_905) : !cute.int_tuple<"?{div=8}">
      %coord_906 = cute.make_coord(%e1_894) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_907 = cute.make_coord(%itup_903) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %432 = cute.elem_less(%coord_906, %coord_907) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %432 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %slice_1744 = cute.slice(%src_partitioned_290, %coord_1743) : !memref_gmem_bf16_6, !cute.coord<"(_,3,_,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_8
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1747 = cute.slice(%dst_partitioned_293, %coord_1746) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_12
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1750 = cute.slice(%rmem_551, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_8
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_gmem_bf16_8
        %iter_1765 = cute.get_iter(%view_1764) : !memref_gmem_bf16_8
        %lay_1766 = cute.get_layout(%view_1764) : !memref_gmem_bf16_8
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_gmem_bf16_9
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_smem_bf16_12
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_smem_bf16_12
        %iter_1778 = cute.get_iter(%view_1777) : !memref_smem_bf16_12
        %lay_1779 = cute.get_layout(%view_1777) : !memref_smem_bf16_12
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_smem_bf16_13
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_gmem_bf16_9
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_smem_bf16_13
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg9, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1744 = cute.slice(%dst_partitioned_293, %coord_1743) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_12
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"16">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_12
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
        %e0_1749, %e1_1750, %e2_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %int_tuple_1752 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %res_1753 = cute.tuple.product(%int_tuple_1752) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1754 = cute.get_leaves(%res_1753) : !cute.int_tuple<"16">
        %cst_1755 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1755 : vector<16xbf16>
        %int_tuple_1756 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1757 = cute.size(%int_tuple_1756) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1758 = cute.get_leaves(%sz_1757) : !cute.int_tuple<"16">
        %int_tuple_1759 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
        %sz_1760 = cute.size(%int_tuple_1759) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
        %e0_1761 = cute.get_leaves(%sz_1760) : !cute.int_tuple<"16">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_12
      }
      %lay_908 = cute.get_layout(%src_partitioned_514) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %433 = cute.get_shape(%lay_908) : (!cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.shape<"((8,1),4,1,?)">
      %e0_909, %e1_910, %e2_911, %e3_912, %e4_913 = cute.get_leaves(%433) : !cute.shape<"((8,1),4,1,?)">
      %itup_914 = cute.to_int_tuple(%e4_913) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %434 = cute.get_scalars(%itup_914) : !cute.int_tuple<"?">
      %int_tuple_915 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_916 = cute.size(%int_tuple_915) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_917 = cute.get_leaves(%sz_916) : !cute.int_tuple<"4">
      %int_tuple_918 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_919 = cute.size(%int_tuple_918) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_920 = cute.get_leaves(%sz_919) : !cute.int_tuple<"1">
      %coord_921 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_922 = cute.slice(%src_partitioned_514, %coord_921) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_923 = cute.get_iter(%slice_922) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_924, %e1_925, %e2_926, %e3_927 = cute.get_leaves(%iter_923) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %435 = cute.get_scalars(%e0_924) : !cute.int_tuple<"?">
      %436 = cute.get_scalars(%e1_925) : !cute.int_tuple<"?">
      %437 = cute.get_scalars(%e2_926) : !cute.int_tuple<"?">
      %438 = cute.get_scalars(%e3_927) : !cute.int_tuple<"?{div=8}">
      %iter_928 = cute.get_iter(%slice_922) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_929, %e1_930, %e2_931, %e3_932 = cute.get_leaves(%iter_928) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %439 = cute.get_scalars(%e0_929) : !cute.int_tuple<"?">
      %440 = cute.get_scalars(%e1_930) : !cute.int_tuple<"?">
      %441 = cute.get_scalars(%e2_931) : !cute.int_tuple<"?">
      %442 = cute.get_scalars(%e3_932) : !cute.int_tuple<"?{div=8}">
      %iter_933 = cute.get_iter(%slice_922) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_934, %e1_935, %e2_936, %e3_937 = cute.get_leaves(%iter_933) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %443 = cute.get_scalars(%e0_934) : !cute.int_tuple<"?">
      %444 = cute.get_scalars(%e1_935) : !cute.int_tuple<"?">
      %445 = cute.get_scalars(%e2_936) : !cute.int_tuple<"?">
      %446 = cute.get_scalars(%e3_937) : !cute.int_tuple<"?{div=8}">
      %lay_938 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %447 = cute.get_shape(%lay_938) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_939, %e1_940, %e2_941, %e3_942 = cute.get_leaves(%447) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_943 = cute.to_int_tuple(%e0_939) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %448 = cute.get_scalars(%itup_943) : !cute.int_tuple<"?">
      %itup_944 = cute.to_int_tuple(%e1_940) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %449 = cute.get_scalars(%itup_944) : !cute.int_tuple<"?">
      %itup_945 = cute.to_int_tuple(%e2_941) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %450 = cute.get_scalars(%itup_945) : !cute.int_tuple<"?">
      %itup_946 = cute.to_int_tuple(%e3_942) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %451 = cute.get_scalars(%itup_946) : !cute.int_tuple<"?{div=8}">
      %coord_947 = cute.make_coord(%e1_935) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_948 = cute.make_coord(%itup_945) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %452 = cute.elem_less(%coord_947, %coord_948) : !cute.coord<"?">, !cute.coord<"?">
      %coord_949 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_950 = cute.slice(%src_partitioned_514, %coord_949) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_951 = cute.get_iter(%slice_950) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_952, %e1_953, %e2_954, %e3_955 = cute.get_leaves(%iter_951) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %453 = cute.get_scalars(%e0_952) : !cute.int_tuple<"?">
      %454 = cute.get_scalars(%e1_953) : !cute.int_tuple<"?">
      %455 = cute.get_scalars(%e2_954) : !cute.int_tuple<"?">
      %456 = cute.get_scalars(%e3_955) : !cute.int_tuple<"?{div=8}">
      %iter_956 = cute.get_iter(%slice_950) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_957, %e1_958, %e2_959, %e3_960 = cute.get_leaves(%iter_956) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %457 = cute.get_scalars(%e0_957) : !cute.int_tuple<"?">
      %458 = cute.get_scalars(%e1_958) : !cute.int_tuple<"?">
      %459 = cute.get_scalars(%e2_959) : !cute.int_tuple<"?">
      %460 = cute.get_scalars(%e3_960) : !cute.int_tuple<"?{div=8}">
      %iter_961 = cute.get_iter(%slice_950) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_962, %e1_963, %e2_964, %e3_965 = cute.get_leaves(%iter_961) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %461 = cute.get_scalars(%e0_962) : !cute.int_tuple<"?">
      %462 = cute.get_scalars(%e1_963) : !cute.int_tuple<"?">
      %463 = cute.get_scalars(%e2_964) : !cute.int_tuple<"?">
      %464 = cute.get_scalars(%e3_965) : !cute.int_tuple<"?{div=8}">
      %lay_966 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %465 = cute.get_shape(%lay_966) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_967, %e1_968, %e2_969, %e3_970 = cute.get_leaves(%465) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_971 = cute.to_int_tuple(%e0_967) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %466 = cute.get_scalars(%itup_971) : !cute.int_tuple<"?">
      %itup_972 = cute.to_int_tuple(%e1_968) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %467 = cute.get_scalars(%itup_972) : !cute.int_tuple<"?">
      %itup_973 = cute.to_int_tuple(%e2_969) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %468 = cute.get_scalars(%itup_973) : !cute.int_tuple<"?">
      %itup_974 = cute.to_int_tuple(%e3_970) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %469 = cute.get_scalars(%itup_974) : !cute.int_tuple<"?{div=8}">
      %coord_975 = cute.make_coord(%e1_963) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_976 = cute.make_coord(%itup_973) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %470 = cute.elem_less(%coord_975, %coord_976) : !cute.coord<"?">, !cute.coord<"?">
      %coord_977 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %slice_978 = cute.slice(%src_partitioned_514, %coord_977) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
      %iter_979 = cute.get_iter(%slice_978) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_980, %e1_981, %e2_982, %e3_983 = cute.get_leaves(%iter_979) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %471 = cute.get_scalars(%e0_980) : !cute.int_tuple<"?">
      %472 = cute.get_scalars(%e1_981) : !cute.int_tuple<"?">
      %473 = cute.get_scalars(%e2_982) : !cute.int_tuple<"?">
      %474 = cute.get_scalars(%e3_983) : !cute.int_tuple<"?{div=8}">
      %iter_984 = cute.get_iter(%slice_978) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_985, %e1_986, %e2_987, %e3_988 = cute.get_leaves(%iter_984) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %475 = cute.get_scalars(%e0_985) : !cute.int_tuple<"?">
      %476 = cute.get_scalars(%e1_986) : !cute.int_tuple<"?">
      %477 = cute.get_scalars(%e2_987) : !cute.int_tuple<"?">
      %478 = cute.get_scalars(%e3_988) : !cute.int_tuple<"?{div=8}">
      %iter_989 = cute.get_iter(%slice_978) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_990, %e1_991, %e2_992, %e3_993 = cute.get_leaves(%iter_989) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %479 = cute.get_scalars(%e0_990) : !cute.int_tuple<"?">
      %480 = cute.get_scalars(%e1_991) : !cute.int_tuple<"?">
      %481 = cute.get_scalars(%e2_992) : !cute.int_tuple<"?">
      %482 = cute.get_scalars(%e3_993) : !cute.int_tuple<"?{div=8}">
      %lay_994 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %483 = cute.get_shape(%lay_994) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_995, %e1_996, %e2_997, %e3_998 = cute.get_leaves(%483) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_999 = cute.to_int_tuple(%e0_995) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %484 = cute.get_scalars(%itup_999) : !cute.int_tuple<"?">
      %itup_1000 = cute.to_int_tuple(%e1_996) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %485 = cute.get_scalars(%itup_1000) : !cute.int_tuple<"?">
      %itup_1001 = cute.to_int_tuple(%e2_997) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %486 = cute.get_scalars(%itup_1001) : !cute.int_tuple<"?">
      %itup_1002 = cute.to_int_tuple(%e3_998) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %487 = cute.get_scalars(%itup_1002) : !cute.int_tuple<"?{div=8}">
      %coord_1003 = cute.make_coord(%e2_992) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1004 = cute.make_coord(%itup_1002) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %488 = cute.elem_less(%coord_1003, %coord_1004) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %489 = arith.extui %470 : i1 to i32
      %c0_i32 = arith.constant 0 : i32
      %490 = arith.cmpi ne, %489, %c0_i32 : i32
      %491 = arith.extui %470 : i1 to i32
      %492 = arith.extui %488 : i1 to i32
      %493 = arith.select %490, %492, %491 : i32
      %c0_i32_1005 = arith.constant 0 : i32
      %494 = arith.cmpi ne, %493, %c0_i32_1005 : i32
      scf.if %494 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %slice_1744 = cute.slice(%src_partitioned_302, %coord_1743) : !memref_gmem_bf16_7, !cute.coord<"(_,0,0,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_10
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,0,0)">
        %slice_1747 = cute.slice(%dst_partitioned_305, %coord_1746) : !memref_smem_bf16_4, !cute.coord<"(_,0,0)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_14
        %lay_1749 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %867 = cute.get_shape(%lay_1749) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1750, %e1_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %lay_1752 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %868 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1753, %e1_1754 = cute.get_leaves(%868) : !cute.shape<"((8,1))">
        %lay_1755 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %shape_1756 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1757 = cute.make_layout(%shape_1756) : !cute.layout<"1:0">
        %append_1758 = cute.append_to_rank<2> (%lay_1755, %lay_1757) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1759 = cute.make_view(%iter_1745, %append_1758) : !memref_gmem_bf16_11
        %iter_1760 = cute.get_iter(%view_1759) : !memref_gmem_bf16_11
        %lay_1761 = cute.get_layout(%view_1759) : !memref_gmem_bf16_11
        %869 = cute.get_shape(%lay_1761) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1762, %e1_1763, %e2_1764 = cute.get_leaves(%869) : !cute.shape<"((8,1),1)">
        %grouped_1765 = cute.group_modes(%view_1759) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1766 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %iter_1767 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %lay_1768 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %shape_1769 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1770 = cute.make_layout(%shape_1769) : !cute.layout<"1:0">
        %append_1771 = cute.append_to_rank<2> (%lay_1768, %lay_1770) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1772 = cute.make_view(%iter_1748, %append_1771) : !memref_smem_bf16_15
        %iter_1773 = cute.get_iter(%view_1772) : !memref_smem_bf16_15
        %lay_1774 = cute.get_layout(%view_1772) : !memref_smem_bf16_15
        %870 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%870) : !cute.shape<"((8,1),1)">
        %grouped_1778 = cute.group_modes(%view_1772) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1779 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %iter_1780 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %lay_1781 = cute.get_layout(%grouped_1765) : !memref_gmem_bf16_12
        %871 = cute.get_shape(%lay_1781) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1782, %e1_1783, %e2_1784 = cute.get_leaves(%871) : !cute.shape<"((8,1),(1))">
        %lay_1785 = cute.get_layout(%grouped_1778) : !memref_smem_bf16_16
        %872 = cute.get_shape(%lay_1785) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1786, %e1_1787, %e2_1788 = cute.get_leaves(%872) : !cute.shape<"((8,1),(1))">
        %sz_1789 = cute.size(%grouped_1765) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1790 = cute.get_leaves(%sz_1789) : !cute.int_tuple<"1">
        %sz_1791 = cute.size(%grouped_1778) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1792 = cute.get_leaves(%sz_1791) : !cute.int_tuple<"1">
        cute.copy(%arg9, %grouped_1765, %grouped_1778) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,0,0)">
        %slice_1744 = cute.slice(%dst_partitioned_305, %coord_1743) : !memref_smem_bf16_4, !cute.coord<"(_,0,0)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_14
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"8">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_14
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1749, %e1_1750 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %int_tuple_1751 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1752 = cute.tuple.product(%int_tuple_1751) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1753 = cute.get_leaves(%res_1752) : !cute.int_tuple<"8">
        %cst_1754 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1754 : vector<8xbf16>
        %int_tuple_1755 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1756 = cute.size(%int_tuple_1755) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1757 = cute.get_leaves(%sz_1756) : !cute.int_tuple<"8">
        %int_tuple_1758 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1759 = cute.size(%int_tuple_1758) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1760 = cute.get_leaves(%sz_1759) : !cute.int_tuple<"8">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_14
      }
      %int_tuple_1006 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1007 = cute.size(%int_tuple_1006) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1008 = cute.get_leaves(%sz_1007) : !cute.int_tuple<"1">
      %coord_1009 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1010 = cute.slice(%src_partitioned_514, %coord_1009) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1011 = cute.get_iter(%slice_1010) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1012, %e1_1013, %e2_1014, %e3_1015 = cute.get_leaves(%iter_1011) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %495 = cute.get_scalars(%e0_1012) : !cute.int_tuple<"?">
      %496 = cute.get_scalars(%e1_1013) : !cute.int_tuple<"?">
      %497 = cute.get_scalars(%e2_1014) : !cute.int_tuple<"?">
      %498 = cute.get_scalars(%e3_1015) : !cute.int_tuple<"?{div=8}">
      %iter_1016 = cute.get_iter(%slice_1010) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1017, %e1_1018, %e2_1019, %e3_1020 = cute.get_leaves(%iter_1016) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %499 = cute.get_scalars(%e0_1017) : !cute.int_tuple<"?">
      %500 = cute.get_scalars(%e1_1018) : !cute.int_tuple<"?">
      %501 = cute.get_scalars(%e2_1019) : !cute.int_tuple<"?">
      %502 = cute.get_scalars(%e3_1020) : !cute.int_tuple<"?{div=8}">
      %iter_1021 = cute.get_iter(%slice_1010) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1022, %e1_1023, %e2_1024, %e3_1025 = cute.get_leaves(%iter_1021) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %503 = cute.get_scalars(%e0_1022) : !cute.int_tuple<"?">
      %504 = cute.get_scalars(%e1_1023) : !cute.int_tuple<"?">
      %505 = cute.get_scalars(%e2_1024) : !cute.int_tuple<"?">
      %506 = cute.get_scalars(%e3_1025) : !cute.int_tuple<"?{div=8}">
      %lay_1026 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %507 = cute.get_shape(%lay_1026) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1027, %e1_1028, %e2_1029, %e3_1030 = cute.get_leaves(%507) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1031 = cute.to_int_tuple(%e0_1027) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %508 = cute.get_scalars(%itup_1031) : !cute.int_tuple<"?">
      %itup_1032 = cute.to_int_tuple(%e1_1028) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %509 = cute.get_scalars(%itup_1032) : !cute.int_tuple<"?">
      %itup_1033 = cute.to_int_tuple(%e2_1029) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %510 = cute.get_scalars(%itup_1033) : !cute.int_tuple<"?">
      %itup_1034 = cute.to_int_tuple(%e3_1030) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %511 = cute.get_scalars(%itup_1034) : !cute.int_tuple<"?{div=8}">
      %coord_1035 = cute.make_coord(%e1_1023) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1036 = cute.make_coord(%itup_1033) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %512 = cute.elem_less(%coord_1035, %coord_1036) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1037 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1038 = cute.slice(%src_partitioned_514, %coord_1037) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1039 = cute.get_iter(%slice_1038) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1040, %e1_1041, %e2_1042, %e3_1043 = cute.get_leaves(%iter_1039) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %513 = cute.get_scalars(%e0_1040) : !cute.int_tuple<"?">
      %514 = cute.get_scalars(%e1_1041) : !cute.int_tuple<"?">
      %515 = cute.get_scalars(%e2_1042) : !cute.int_tuple<"?">
      %516 = cute.get_scalars(%e3_1043) : !cute.int_tuple<"?{div=8}">
      %iter_1044 = cute.get_iter(%slice_1038) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1045, %e1_1046, %e2_1047, %e3_1048 = cute.get_leaves(%iter_1044) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %517 = cute.get_scalars(%e0_1045) : !cute.int_tuple<"?">
      %518 = cute.get_scalars(%e1_1046) : !cute.int_tuple<"?">
      %519 = cute.get_scalars(%e2_1047) : !cute.int_tuple<"?">
      %520 = cute.get_scalars(%e3_1048) : !cute.int_tuple<"?{div=8}">
      %iter_1049 = cute.get_iter(%slice_1038) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1050, %e1_1051, %e2_1052, %e3_1053 = cute.get_leaves(%iter_1049) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %521 = cute.get_scalars(%e0_1050) : !cute.int_tuple<"?">
      %522 = cute.get_scalars(%e1_1051) : !cute.int_tuple<"?">
      %523 = cute.get_scalars(%e2_1052) : !cute.int_tuple<"?">
      %524 = cute.get_scalars(%e3_1053) : !cute.int_tuple<"?{div=8}">
      %lay_1054 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %525 = cute.get_shape(%lay_1054) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1055, %e1_1056, %e2_1057, %e3_1058 = cute.get_leaves(%525) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1059 = cute.to_int_tuple(%e0_1055) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %526 = cute.get_scalars(%itup_1059) : !cute.int_tuple<"?">
      %itup_1060 = cute.to_int_tuple(%e1_1056) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %527 = cute.get_scalars(%itup_1060) : !cute.int_tuple<"?">
      %itup_1061 = cute.to_int_tuple(%e2_1057) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %528 = cute.get_scalars(%itup_1061) : !cute.int_tuple<"?">
      %itup_1062 = cute.to_int_tuple(%e3_1058) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %529 = cute.get_scalars(%itup_1062) : !cute.int_tuple<"?{div=8}">
      %coord_1063 = cute.make_coord(%e1_1051) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1064 = cute.make_coord(%itup_1061) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %530 = cute.elem_less(%coord_1063, %coord_1064) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1065 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %slice_1066 = cute.slice(%src_partitioned_514, %coord_1065) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
      %iter_1067 = cute.get_iter(%slice_1066) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1068, %e1_1069, %e2_1070, %e3_1071 = cute.get_leaves(%iter_1067) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %531 = cute.get_scalars(%e0_1068) : !cute.int_tuple<"?">
      %532 = cute.get_scalars(%e1_1069) : !cute.int_tuple<"?">
      %533 = cute.get_scalars(%e2_1070) : !cute.int_tuple<"?">
      %534 = cute.get_scalars(%e3_1071) : !cute.int_tuple<"?{div=8}">
      %iter_1072 = cute.get_iter(%slice_1066) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1073, %e1_1074, %e2_1075, %e3_1076 = cute.get_leaves(%iter_1072) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %535 = cute.get_scalars(%e0_1073) : !cute.int_tuple<"?">
      %536 = cute.get_scalars(%e1_1074) : !cute.int_tuple<"?">
      %537 = cute.get_scalars(%e2_1075) : !cute.int_tuple<"?">
      %538 = cute.get_scalars(%e3_1076) : !cute.int_tuple<"?{div=8}">
      %iter_1077 = cute.get_iter(%slice_1066) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1078, %e1_1079, %e2_1080, %e3_1081 = cute.get_leaves(%iter_1077) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %539 = cute.get_scalars(%e0_1078) : !cute.int_tuple<"?">
      %540 = cute.get_scalars(%e1_1079) : !cute.int_tuple<"?">
      %541 = cute.get_scalars(%e2_1080) : !cute.int_tuple<"?">
      %542 = cute.get_scalars(%e3_1081) : !cute.int_tuple<"?{div=8}">
      %lay_1082 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %543 = cute.get_shape(%lay_1082) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1083, %e1_1084, %e2_1085, %e3_1086 = cute.get_leaves(%543) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1087 = cute.to_int_tuple(%e0_1083) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %544 = cute.get_scalars(%itup_1087) : !cute.int_tuple<"?">
      %itup_1088 = cute.to_int_tuple(%e1_1084) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %545 = cute.get_scalars(%itup_1088) : !cute.int_tuple<"?">
      %itup_1089 = cute.to_int_tuple(%e2_1085) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %546 = cute.get_scalars(%itup_1089) : !cute.int_tuple<"?">
      %itup_1090 = cute.to_int_tuple(%e3_1086) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %547 = cute.get_scalars(%itup_1090) : !cute.int_tuple<"?{div=8}">
      %coord_1091 = cute.make_coord(%e2_1080) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1092 = cute.make_coord(%itup_1090) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %548 = cute.elem_less(%coord_1091, %coord_1092) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %549 = arith.extui %530 : i1 to i32
      %550 = arith.cmpi ne, %549, %c0_i32 : i32
      %551 = arith.extui %530 : i1 to i32
      %552 = arith.extui %548 : i1 to i32
      %553 = arith.select %550, %552, %551 : i32
      %554 = arith.cmpi ne, %553, %c0_i32_1005 : i32
      scf.if %554 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %slice_1744 = cute.slice(%src_partitioned_302, %coord_1743) : !memref_gmem_bf16_7, !cute.coord<"(_,1,0,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_10
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,1,0)">
        %slice_1747 = cute.slice(%dst_partitioned_305, %coord_1746) : !memref_smem_bf16_4, !cute.coord<"(_,1,0)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_14
        %lay_1749 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %867 = cute.get_shape(%lay_1749) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1750, %e1_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %lay_1752 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %868 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1753, %e1_1754 = cute.get_leaves(%868) : !cute.shape<"((8,1))">
        %lay_1755 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %shape_1756 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1757 = cute.make_layout(%shape_1756) : !cute.layout<"1:0">
        %append_1758 = cute.append_to_rank<2> (%lay_1755, %lay_1757) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1759 = cute.make_view(%iter_1745, %append_1758) : !memref_gmem_bf16_11
        %iter_1760 = cute.get_iter(%view_1759) : !memref_gmem_bf16_11
        %lay_1761 = cute.get_layout(%view_1759) : !memref_gmem_bf16_11
        %869 = cute.get_shape(%lay_1761) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1762, %e1_1763, %e2_1764 = cute.get_leaves(%869) : !cute.shape<"((8,1),1)">
        %grouped_1765 = cute.group_modes(%view_1759) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1766 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %iter_1767 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %lay_1768 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %shape_1769 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1770 = cute.make_layout(%shape_1769) : !cute.layout<"1:0">
        %append_1771 = cute.append_to_rank<2> (%lay_1768, %lay_1770) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1772 = cute.make_view(%iter_1748, %append_1771) : !memref_smem_bf16_15
        %iter_1773 = cute.get_iter(%view_1772) : !memref_smem_bf16_15
        %lay_1774 = cute.get_layout(%view_1772) : !memref_smem_bf16_15
        %870 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%870) : !cute.shape<"((8,1),1)">
        %grouped_1778 = cute.group_modes(%view_1772) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1779 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %iter_1780 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %lay_1781 = cute.get_layout(%grouped_1765) : !memref_gmem_bf16_12
        %871 = cute.get_shape(%lay_1781) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1782, %e1_1783, %e2_1784 = cute.get_leaves(%871) : !cute.shape<"((8,1),(1))">
        %lay_1785 = cute.get_layout(%grouped_1778) : !memref_smem_bf16_16
        %872 = cute.get_shape(%lay_1785) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1786, %e1_1787, %e2_1788 = cute.get_leaves(%872) : !cute.shape<"((8,1),(1))">
        %sz_1789 = cute.size(%grouped_1765) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1790 = cute.get_leaves(%sz_1789) : !cute.int_tuple<"1">
        %sz_1791 = cute.size(%grouped_1778) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1792 = cute.get_leaves(%sz_1791) : !cute.int_tuple<"1">
        cute.copy(%arg9, %grouped_1765, %grouped_1778) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,1,0)">
        %slice_1744 = cute.slice(%dst_partitioned_305, %coord_1743) : !memref_smem_bf16_4, !cute.coord<"(_,1,0)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_14
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"8">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_14
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1749, %e1_1750 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %int_tuple_1751 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1752 = cute.tuple.product(%int_tuple_1751) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1753 = cute.get_leaves(%res_1752) : !cute.int_tuple<"8">
        %cst_1754 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1754 : vector<8xbf16>
        %int_tuple_1755 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1756 = cute.size(%int_tuple_1755) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1757 = cute.get_leaves(%sz_1756) : !cute.int_tuple<"8">
        %int_tuple_1758 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1759 = cute.size(%int_tuple_1758) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1760 = cute.get_leaves(%sz_1759) : !cute.int_tuple<"8">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_14
      }
      %int_tuple_1093 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1094 = cute.size(%int_tuple_1093) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1095 = cute.get_leaves(%sz_1094) : !cute.int_tuple<"1">
      %coord_1096 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1097 = cute.slice(%src_partitioned_514, %coord_1096) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1098 = cute.get_iter(%slice_1097) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1099, %e1_1100, %e2_1101, %e3_1102 = cute.get_leaves(%iter_1098) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %555 = cute.get_scalars(%e0_1099) : !cute.int_tuple<"?">
      %556 = cute.get_scalars(%e1_1100) : !cute.int_tuple<"?">
      %557 = cute.get_scalars(%e2_1101) : !cute.int_tuple<"?">
      %558 = cute.get_scalars(%e3_1102) : !cute.int_tuple<"?{div=8}">
      %iter_1103 = cute.get_iter(%slice_1097) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1104, %e1_1105, %e2_1106, %e3_1107 = cute.get_leaves(%iter_1103) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %559 = cute.get_scalars(%e0_1104) : !cute.int_tuple<"?">
      %560 = cute.get_scalars(%e1_1105) : !cute.int_tuple<"?">
      %561 = cute.get_scalars(%e2_1106) : !cute.int_tuple<"?">
      %562 = cute.get_scalars(%e3_1107) : !cute.int_tuple<"?{div=8}">
      %iter_1108 = cute.get_iter(%slice_1097) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1109, %e1_1110, %e2_1111, %e3_1112 = cute.get_leaves(%iter_1108) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %563 = cute.get_scalars(%e0_1109) : !cute.int_tuple<"?">
      %564 = cute.get_scalars(%e1_1110) : !cute.int_tuple<"?">
      %565 = cute.get_scalars(%e2_1111) : !cute.int_tuple<"?">
      %566 = cute.get_scalars(%e3_1112) : !cute.int_tuple<"?{div=8}">
      %lay_1113 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %567 = cute.get_shape(%lay_1113) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1114, %e1_1115, %e2_1116, %e3_1117 = cute.get_leaves(%567) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1118 = cute.to_int_tuple(%e0_1114) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %568 = cute.get_scalars(%itup_1118) : !cute.int_tuple<"?">
      %itup_1119 = cute.to_int_tuple(%e1_1115) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %569 = cute.get_scalars(%itup_1119) : !cute.int_tuple<"?">
      %itup_1120 = cute.to_int_tuple(%e2_1116) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %570 = cute.get_scalars(%itup_1120) : !cute.int_tuple<"?">
      %itup_1121 = cute.to_int_tuple(%e3_1117) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %571 = cute.get_scalars(%itup_1121) : !cute.int_tuple<"?{div=8}">
      %coord_1122 = cute.make_coord(%e1_1110) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1123 = cute.make_coord(%itup_1120) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %572 = cute.elem_less(%coord_1122, %coord_1123) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1124 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1125 = cute.slice(%src_partitioned_514, %coord_1124) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1126 = cute.get_iter(%slice_1125) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1127, %e1_1128, %e2_1129, %e3_1130 = cute.get_leaves(%iter_1126) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %573 = cute.get_scalars(%e0_1127) : !cute.int_tuple<"?">
      %574 = cute.get_scalars(%e1_1128) : !cute.int_tuple<"?">
      %575 = cute.get_scalars(%e2_1129) : !cute.int_tuple<"?">
      %576 = cute.get_scalars(%e3_1130) : !cute.int_tuple<"?{div=8}">
      %iter_1131 = cute.get_iter(%slice_1125) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1132, %e1_1133, %e2_1134, %e3_1135 = cute.get_leaves(%iter_1131) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %577 = cute.get_scalars(%e0_1132) : !cute.int_tuple<"?">
      %578 = cute.get_scalars(%e1_1133) : !cute.int_tuple<"?">
      %579 = cute.get_scalars(%e2_1134) : !cute.int_tuple<"?">
      %580 = cute.get_scalars(%e3_1135) : !cute.int_tuple<"?{div=8}">
      %iter_1136 = cute.get_iter(%slice_1125) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1137, %e1_1138, %e2_1139, %e3_1140 = cute.get_leaves(%iter_1136) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %581 = cute.get_scalars(%e0_1137) : !cute.int_tuple<"?">
      %582 = cute.get_scalars(%e1_1138) : !cute.int_tuple<"?">
      %583 = cute.get_scalars(%e2_1139) : !cute.int_tuple<"?">
      %584 = cute.get_scalars(%e3_1140) : !cute.int_tuple<"?{div=8}">
      %lay_1141 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %585 = cute.get_shape(%lay_1141) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1142, %e1_1143, %e2_1144, %e3_1145 = cute.get_leaves(%585) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1146 = cute.to_int_tuple(%e0_1142) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %586 = cute.get_scalars(%itup_1146) : !cute.int_tuple<"?">
      %itup_1147 = cute.to_int_tuple(%e1_1143) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %587 = cute.get_scalars(%itup_1147) : !cute.int_tuple<"?">
      %itup_1148 = cute.to_int_tuple(%e2_1144) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %588 = cute.get_scalars(%itup_1148) : !cute.int_tuple<"?">
      %itup_1149 = cute.to_int_tuple(%e3_1145) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %589 = cute.get_scalars(%itup_1149) : !cute.int_tuple<"?{div=8}">
      %coord_1150 = cute.make_coord(%e1_1138) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1151 = cute.make_coord(%itup_1148) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %590 = cute.elem_less(%coord_1150, %coord_1151) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1152 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %slice_1153 = cute.slice(%src_partitioned_514, %coord_1152) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
      %iter_1154 = cute.get_iter(%slice_1153) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1155, %e1_1156, %e2_1157, %e3_1158 = cute.get_leaves(%iter_1154) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %591 = cute.get_scalars(%e0_1155) : !cute.int_tuple<"?">
      %592 = cute.get_scalars(%e1_1156) : !cute.int_tuple<"?">
      %593 = cute.get_scalars(%e2_1157) : !cute.int_tuple<"?">
      %594 = cute.get_scalars(%e3_1158) : !cute.int_tuple<"?{div=8}">
      %iter_1159 = cute.get_iter(%slice_1153) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1160, %e1_1161, %e2_1162, %e3_1163 = cute.get_leaves(%iter_1159) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %595 = cute.get_scalars(%e0_1160) : !cute.int_tuple<"?">
      %596 = cute.get_scalars(%e1_1161) : !cute.int_tuple<"?">
      %597 = cute.get_scalars(%e2_1162) : !cute.int_tuple<"?">
      %598 = cute.get_scalars(%e3_1163) : !cute.int_tuple<"?{div=8}">
      %iter_1164 = cute.get_iter(%slice_1153) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1165, %e1_1166, %e2_1167, %e3_1168 = cute.get_leaves(%iter_1164) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %599 = cute.get_scalars(%e0_1165) : !cute.int_tuple<"?">
      %600 = cute.get_scalars(%e1_1166) : !cute.int_tuple<"?">
      %601 = cute.get_scalars(%e2_1167) : !cute.int_tuple<"?">
      %602 = cute.get_scalars(%e3_1168) : !cute.int_tuple<"?{div=8}">
      %lay_1169 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %603 = cute.get_shape(%lay_1169) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1170, %e1_1171, %e2_1172, %e3_1173 = cute.get_leaves(%603) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1174 = cute.to_int_tuple(%e0_1170) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %604 = cute.get_scalars(%itup_1174) : !cute.int_tuple<"?">
      %itup_1175 = cute.to_int_tuple(%e1_1171) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %605 = cute.get_scalars(%itup_1175) : !cute.int_tuple<"?">
      %itup_1176 = cute.to_int_tuple(%e2_1172) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %606 = cute.get_scalars(%itup_1176) : !cute.int_tuple<"?">
      %itup_1177 = cute.to_int_tuple(%e3_1173) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %607 = cute.get_scalars(%itup_1177) : !cute.int_tuple<"?{div=8}">
      %coord_1178 = cute.make_coord(%e2_1167) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1179 = cute.make_coord(%itup_1177) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %608 = cute.elem_less(%coord_1178, %coord_1179) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %609 = arith.extui %590 : i1 to i32
      %610 = arith.cmpi ne, %609, %c0_i32 : i32
      %611 = arith.extui %590 : i1 to i32
      %612 = arith.extui %608 : i1 to i32
      %613 = arith.select %610, %612, %611 : i32
      %614 = arith.cmpi ne, %613, %c0_i32_1005 : i32
      scf.if %614 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %slice_1744 = cute.slice(%src_partitioned_302, %coord_1743) : !memref_gmem_bf16_7, !cute.coord<"(_,2,0,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_10
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,2,0)">
        %slice_1747 = cute.slice(%dst_partitioned_305, %coord_1746) : !memref_smem_bf16_4, !cute.coord<"(_,2,0)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_14
        %lay_1749 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %867 = cute.get_shape(%lay_1749) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1750, %e1_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %lay_1752 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %868 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1753, %e1_1754 = cute.get_leaves(%868) : !cute.shape<"((8,1))">
        %lay_1755 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %shape_1756 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1757 = cute.make_layout(%shape_1756) : !cute.layout<"1:0">
        %append_1758 = cute.append_to_rank<2> (%lay_1755, %lay_1757) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1759 = cute.make_view(%iter_1745, %append_1758) : !memref_gmem_bf16_11
        %iter_1760 = cute.get_iter(%view_1759) : !memref_gmem_bf16_11
        %lay_1761 = cute.get_layout(%view_1759) : !memref_gmem_bf16_11
        %869 = cute.get_shape(%lay_1761) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1762, %e1_1763, %e2_1764 = cute.get_leaves(%869) : !cute.shape<"((8,1),1)">
        %grouped_1765 = cute.group_modes(%view_1759) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1766 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %iter_1767 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %lay_1768 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %shape_1769 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1770 = cute.make_layout(%shape_1769) : !cute.layout<"1:0">
        %append_1771 = cute.append_to_rank<2> (%lay_1768, %lay_1770) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1772 = cute.make_view(%iter_1748, %append_1771) : !memref_smem_bf16_15
        %iter_1773 = cute.get_iter(%view_1772) : !memref_smem_bf16_15
        %lay_1774 = cute.get_layout(%view_1772) : !memref_smem_bf16_15
        %870 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%870) : !cute.shape<"((8,1),1)">
        %grouped_1778 = cute.group_modes(%view_1772) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1779 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %iter_1780 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %lay_1781 = cute.get_layout(%grouped_1765) : !memref_gmem_bf16_12
        %871 = cute.get_shape(%lay_1781) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1782, %e1_1783, %e2_1784 = cute.get_leaves(%871) : !cute.shape<"((8,1),(1))">
        %lay_1785 = cute.get_layout(%grouped_1778) : !memref_smem_bf16_16
        %872 = cute.get_shape(%lay_1785) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1786, %e1_1787, %e2_1788 = cute.get_leaves(%872) : !cute.shape<"((8,1),(1))">
        %sz_1789 = cute.size(%grouped_1765) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1790 = cute.get_leaves(%sz_1789) : !cute.int_tuple<"1">
        %sz_1791 = cute.size(%grouped_1778) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1792 = cute.get_leaves(%sz_1791) : !cute.int_tuple<"1">
        cute.copy(%arg9, %grouped_1765, %grouped_1778) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,2,0)">
        %slice_1744 = cute.slice(%dst_partitioned_305, %coord_1743) : !memref_smem_bf16_4, !cute.coord<"(_,2,0)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_14
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"8">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_14
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1749, %e1_1750 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %int_tuple_1751 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1752 = cute.tuple.product(%int_tuple_1751) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1753 = cute.get_leaves(%res_1752) : !cute.int_tuple<"8">
        %cst_1754 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1754 : vector<8xbf16>
        %int_tuple_1755 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1756 = cute.size(%int_tuple_1755) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1757 = cute.get_leaves(%sz_1756) : !cute.int_tuple<"8">
        %int_tuple_1758 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1759 = cute.size(%int_tuple_1758) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1760 = cute.get_leaves(%sz_1759) : !cute.int_tuple<"8">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_14
      }
      %int_tuple_1180 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %sz_1181 = cute.size(%int_tuple_1180) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
      %e0_1182 = cute.get_leaves(%sz_1181) : !cute.int_tuple<"1">
      %coord_1183 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1184 = cute.slice(%src_partitioned_514, %coord_1183) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1185 = cute.get_iter(%slice_1184) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1186, %e1_1187, %e2_1188, %e3_1189 = cute.get_leaves(%iter_1185) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %615 = cute.get_scalars(%e0_1186) : !cute.int_tuple<"?">
      %616 = cute.get_scalars(%e1_1187) : !cute.int_tuple<"?">
      %617 = cute.get_scalars(%e2_1188) : !cute.int_tuple<"?">
      %618 = cute.get_scalars(%e3_1189) : !cute.int_tuple<"?{div=8}">
      %iter_1190 = cute.get_iter(%slice_1184) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1191, %e1_1192, %e2_1193, %e3_1194 = cute.get_leaves(%iter_1190) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %619 = cute.get_scalars(%e0_1191) : !cute.int_tuple<"?">
      %620 = cute.get_scalars(%e1_1192) : !cute.int_tuple<"?">
      %621 = cute.get_scalars(%e2_1193) : !cute.int_tuple<"?">
      %622 = cute.get_scalars(%e3_1194) : !cute.int_tuple<"?{div=8}">
      %iter_1195 = cute.get_iter(%slice_1184) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1196, %e1_1197, %e2_1198, %e3_1199 = cute.get_leaves(%iter_1195) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %623 = cute.get_scalars(%e0_1196) : !cute.int_tuple<"?">
      %624 = cute.get_scalars(%e1_1197) : !cute.int_tuple<"?">
      %625 = cute.get_scalars(%e2_1198) : !cute.int_tuple<"?">
      %626 = cute.get_scalars(%e3_1199) : !cute.int_tuple<"?{div=8}">
      %lay_1200 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %627 = cute.get_shape(%lay_1200) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1201, %e1_1202, %e2_1203, %e3_1204 = cute.get_leaves(%627) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1205 = cute.to_int_tuple(%e0_1201) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %628 = cute.get_scalars(%itup_1205) : !cute.int_tuple<"?">
      %itup_1206 = cute.to_int_tuple(%e1_1202) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %629 = cute.get_scalars(%itup_1206) : !cute.int_tuple<"?">
      %itup_1207 = cute.to_int_tuple(%e2_1203) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %630 = cute.get_scalars(%itup_1207) : !cute.int_tuple<"?">
      %itup_1208 = cute.to_int_tuple(%e3_1204) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %631 = cute.get_scalars(%itup_1208) : !cute.int_tuple<"?{div=8}">
      %coord_1209 = cute.make_coord(%e1_1197) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1210 = cute.make_coord(%itup_1207) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %632 = cute.elem_less(%coord_1209, %coord_1210) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1211 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1212 = cute.slice(%src_partitioned_514, %coord_1211) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1213 = cute.get_iter(%slice_1212) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1214, %e1_1215, %e2_1216, %e3_1217 = cute.get_leaves(%iter_1213) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %633 = cute.get_scalars(%e0_1214) : !cute.int_tuple<"?">
      %634 = cute.get_scalars(%e1_1215) : !cute.int_tuple<"?">
      %635 = cute.get_scalars(%e2_1216) : !cute.int_tuple<"?">
      %636 = cute.get_scalars(%e3_1217) : !cute.int_tuple<"?{div=8}">
      %iter_1218 = cute.get_iter(%slice_1212) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1219, %e1_1220, %e2_1221, %e3_1222 = cute.get_leaves(%iter_1218) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %637 = cute.get_scalars(%e0_1219) : !cute.int_tuple<"?">
      %638 = cute.get_scalars(%e1_1220) : !cute.int_tuple<"?">
      %639 = cute.get_scalars(%e2_1221) : !cute.int_tuple<"?">
      %640 = cute.get_scalars(%e3_1222) : !cute.int_tuple<"?{div=8}">
      %iter_1223 = cute.get_iter(%slice_1212) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1224, %e1_1225, %e2_1226, %e3_1227 = cute.get_leaves(%iter_1223) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %641 = cute.get_scalars(%e0_1224) : !cute.int_tuple<"?">
      %642 = cute.get_scalars(%e1_1225) : !cute.int_tuple<"?">
      %643 = cute.get_scalars(%e2_1226) : !cute.int_tuple<"?">
      %644 = cute.get_scalars(%e3_1227) : !cute.int_tuple<"?{div=8}">
      %lay_1228 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %645 = cute.get_shape(%lay_1228) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1229, %e1_1230, %e2_1231, %e3_1232 = cute.get_leaves(%645) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1233 = cute.to_int_tuple(%e0_1229) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %646 = cute.get_scalars(%itup_1233) : !cute.int_tuple<"?">
      %itup_1234 = cute.to_int_tuple(%e1_1230) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %647 = cute.get_scalars(%itup_1234) : !cute.int_tuple<"?">
      %itup_1235 = cute.to_int_tuple(%e2_1231) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %648 = cute.get_scalars(%itup_1235) : !cute.int_tuple<"?">
      %itup_1236 = cute.to_int_tuple(%e3_1232) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %649 = cute.get_scalars(%itup_1236) : !cute.int_tuple<"?{div=8}">
      %coord_1237 = cute.make_coord(%e1_1225) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1238 = cute.make_coord(%itup_1235) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %650 = cute.elem_less(%coord_1237, %coord_1238) : !cute.coord<"?">, !cute.coord<"?">
      %coord_1239 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %slice_1240 = cute.slice(%src_partitioned_514, %coord_1239) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
      %iter_1241 = cute.get_iter(%slice_1240) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1242, %e1_1243, %e2_1244, %e3_1245 = cute.get_leaves(%iter_1241) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %651 = cute.get_scalars(%e0_1242) : !cute.int_tuple<"?">
      %652 = cute.get_scalars(%e1_1243) : !cute.int_tuple<"?">
      %653 = cute.get_scalars(%e2_1244) : !cute.int_tuple<"?">
      %654 = cute.get_scalars(%e3_1245) : !cute.int_tuple<"?{div=8}">
      %iter_1246 = cute.get_iter(%slice_1240) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1247, %e1_1248, %e2_1249, %e3_1250 = cute.get_leaves(%iter_1246) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %655 = cute.get_scalars(%e0_1247) : !cute.int_tuple<"?">
      %656 = cute.get_scalars(%e1_1248) : !cute.int_tuple<"?">
      %657 = cute.get_scalars(%e2_1249) : !cute.int_tuple<"?">
      %658 = cute.get_scalars(%e3_1250) : !cute.int_tuple<"?{div=8}">
      %iter_1251 = cute.get_iter(%slice_1240) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1252, %e1_1253, %e2_1254, %e3_1255 = cute.get_leaves(%iter_1251) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %659 = cute.get_scalars(%e0_1252) : !cute.int_tuple<"?">
      %660 = cute.get_scalars(%e1_1253) : !cute.int_tuple<"?">
      %661 = cute.get_scalars(%e2_1254) : !cute.int_tuple<"?">
      %662 = cute.get_scalars(%e3_1255) : !cute.int_tuple<"?{div=8}">
      %lay_1256 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %663 = cute.get_shape(%lay_1256) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1257, %e1_1258, %e2_1259, %e3_1260 = cute.get_leaves(%663) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1261 = cute.to_int_tuple(%e0_1257) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %664 = cute.get_scalars(%itup_1261) : !cute.int_tuple<"?">
      %itup_1262 = cute.to_int_tuple(%e1_1258) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %665 = cute.get_scalars(%itup_1262) : !cute.int_tuple<"?">
      %itup_1263 = cute.to_int_tuple(%e2_1259) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %666 = cute.get_scalars(%itup_1263) : !cute.int_tuple<"?">
      %itup_1264 = cute.to_int_tuple(%e3_1260) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %667 = cute.get_scalars(%itup_1264) : !cute.int_tuple<"?{div=8}">
      %coord_1265 = cute.make_coord(%e2_1254) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1266 = cute.make_coord(%itup_1264) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %668 = cute.elem_less(%coord_1265, %coord_1266) : !cute.coord<"?">, !cute.coord<"?{div=8}">
      %669 = arith.extui %650 : i1 to i32
      %670 = arith.cmpi ne, %669, %c0_i32 : i32
      %671 = arith.extui %650 : i1 to i32
      %672 = arith.extui %668 : i1 to i32
      %673 = arith.select %670, %672, %671 : i32
      %674 = arith.cmpi ne, %673, %c0_i32_1005 : i32
      scf.if %674 {
        %coord_1743 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %slice_1744 = cute.slice(%src_partitioned_302, %coord_1743) : !memref_gmem_bf16_7, !cute.coord<"(_,3,0,?)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_gmem_bf16_10
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,3,0)">
        %slice_1747 = cute.slice(%dst_partitioned_305, %coord_1746) : !memref_smem_bf16_4, !cute.coord<"(_,3,0)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_smem_bf16_14
        %lay_1749 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %867 = cute.get_shape(%lay_1749) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1750, %e1_1751 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %lay_1752 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %868 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1753, %e1_1754 = cute.get_leaves(%868) : !cute.shape<"((8,1))">
        %lay_1755 = cute.get_layout(%slice_1744) : !memref_gmem_bf16_10
        %shape_1756 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1757 = cute.make_layout(%shape_1756) : !cute.layout<"1:0">
        %append_1758 = cute.append_to_rank<2> (%lay_1755, %lay_1757) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1759 = cute.make_view(%iter_1745, %append_1758) : !memref_gmem_bf16_11
        %iter_1760 = cute.get_iter(%view_1759) : !memref_gmem_bf16_11
        %lay_1761 = cute.get_layout(%view_1759) : !memref_gmem_bf16_11
        %869 = cute.get_shape(%lay_1761) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1762, %e1_1763, %e2_1764 = cute.get_leaves(%869) : !cute.shape<"((8,1),1)">
        %grouped_1765 = cute.group_modes(%view_1759) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
        %iter_1766 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %iter_1767 = cute.get_iter(%grouped_1765) : !memref_gmem_bf16_12
        %lay_1768 = cute.get_layout(%slice_1747) : !memref_smem_bf16_14
        %shape_1769 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1770 = cute.make_layout(%shape_1769) : !cute.layout<"1:0">
        %append_1771 = cute.append_to_rank<2> (%lay_1768, %lay_1770) : !cute.layout<"((8,1)):((1,0))">, !cute.layout<"1:0">
        %view_1772 = cute.make_view(%iter_1748, %append_1771) : !memref_smem_bf16_15
        %iter_1773 = cute.get_iter(%view_1772) : !memref_smem_bf16_15
        %lay_1774 = cute.get_layout(%view_1772) : !memref_smem_bf16_15
        %870 = cute.get_shape(%lay_1774) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1775, %e1_1776, %e2_1777 = cute.get_leaves(%870) : !cute.shape<"((8,1),1)">
        %grouped_1778 = cute.group_modes(%view_1772) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1779 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %iter_1780 = cute.get_iter(%grouped_1778) : !memref_smem_bf16_16
        %lay_1781 = cute.get_layout(%grouped_1765) : !memref_gmem_bf16_12
        %871 = cute.get_shape(%lay_1781) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1782, %e1_1783, %e2_1784 = cute.get_leaves(%871) : !cute.shape<"((8,1),(1))">
        %lay_1785 = cute.get_layout(%grouped_1778) : !memref_smem_bf16_16
        %872 = cute.get_shape(%lay_1785) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1786, %e1_1787, %e2_1788 = cute.get_leaves(%872) : !cute.shape<"((8,1),(1))">
        %sz_1789 = cute.size(%grouped_1765) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
        %e0_1790 = cute.get_leaves(%sz_1789) : !cute.int_tuple<"1">
        %sz_1791 = cute.size(%grouped_1778) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1792 = cute.get_leaves(%sz_1791) : !cute.int_tuple<"1">
        cute.copy(%arg9, %grouped_1765, %grouped_1778) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
      } else {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,3,0)">
        %slice_1744 = cute.slice(%dst_partitioned_305, %coord_1743) : !memref_smem_bf16_4, !cute.coord<"(_,3,0)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_smem_bf16_14
        %sz_1746 = cute.size(%slice_1744) : (!memref_smem_bf16_14) -> !cute.int_tuple<"8">
        %e0_1747 = cute.get_leaves(%sz_1746) : !cute.int_tuple<"8">
        %lay_1748 = cute.get_layout(%slice_1744) : !memref_smem_bf16_14
        %867 = cute.get_shape(%lay_1748) : (!cute.layout<"((8,1)):((1,0))">) -> !cute.shape<"((8,1))">
        %e0_1749, %e1_1750 = cute.get_leaves(%867) : !cute.shape<"((8,1))">
        %int_tuple_1751 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %res_1752 = cute.tuple.product(%int_tuple_1751) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1753 = cute.get_leaves(%res_1752) : !cute.int_tuple<"8">
        %cst_1754 = arith.constant 0.000000e+00 : bf16
        %868 = vector.splat %cst_1754 : vector<8xbf16>
        %int_tuple_1755 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1756 = cute.size(%int_tuple_1755) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1757 = cute.get_leaves(%sz_1756) : !cute.int_tuple<"8">
        %int_tuple_1758 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1))">
        %sz_1759 = cute.size(%int_tuple_1758) : (!cute.int_tuple<"((8,1))">) -> !cute.int_tuple<"8">
        %e0_1760 = cute.get_leaves(%sz_1759) : !cute.int_tuple<"8">
        cute.memref.store_vec %868, %slice_1744, row_major : !memref_smem_bf16_14
      }
      nvvm.cp.async.commit.group
      %int_tuple_1267 = cute.make_int_tuple() : () -> !cute.int_tuple<"-1">
      %tup = cute.add_offset(%sub_237, %int_tuple_1267) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %675 = cute.get_scalars(%tup) : !cute.int_tuple<"?">
      %676 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %677 = cute.get_shape(%676) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
      %e0_1268, %e1_1269, %e2_1270, %e3_1271 = cute.get_leaves(%677) : !cute.shape<"(32,4,1,1)">
      %678 = cute.get_stride(%676) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
      %e0_1272, %e1_1273, %e2_1274, %e3_1275 = cute.get_leaves(%678) : !cute.stride<"(1,32,0,0)">
      %679 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1276, %e1_1277, %e2_1278 = cute.get_leaves(%679) : !cute.tile<"[64:1;16:1;16:1]">
      %680 = cute.get_shape(%e0_1276) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_1279 = cute.get_leaves(%680) : !cute.shape<"64">
      %681 = cute.get_stride(%e0_1276) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_1280 = cute.get_leaves(%681) : !cute.stride<"1">
      %682 = cute.get_shape(%e1_1277) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1281 = cute.get_leaves(%682) : !cute.shape<"16">
      %683 = cute.get_stride(%e1_1277) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1282 = cute.get_leaves(%683) : !cute.stride<"1">
      %684 = cute.get_shape(%e2_1278) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1283 = cute.get_leaves(%684) : !cute.shape<"16">
      %685 = cute.get_stride(%e2_1278) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1284 = cute.get_leaves(%685) : !cute.stride<"1">
      %686 = cute.static : !cute.layout<"32:1">
      %687 = cute.get_shape(%686) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_1285 = cute.get_leaves(%687) : !cute.shape<"32">
      %688 = cute.get_stride(%686) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_1286 = cute.get_leaves(%688) : !cute.stride<"1">
      %689 = cute.static : !cute.shape<"(16,8,16)">
      %e0_1287, %e1_1288, %e2_1289 = cute.get_leaves(%689) : !cute.shape<"(16,8,16)">
      %690 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %691 = cute.get_shape(%690) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
      %e0_1290, %e1_1291, %e2_1292, %e3_1293, %e4_1294 = cute.get_leaves(%691) : !cute.shape<"((4,8),(2,2,2))">
      %692 = cute.get_stride(%690) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
      %e0_1295, %e1_1296, %e2_1297, %e3_1298, %e4_1299 = cute.get_leaves(%692) : !cute.stride<"((32,1),(16,8,128))">
      %693 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %694 = cute.get_shape(%693) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_1300, %e1_1301, %e2_1302, %e3_1303 = cute.get_leaves(%694) : !cute.shape<"((4,8),(2,2))">
      %695 = cute.get_stride(%693) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
      %e0_1304, %e1_1305, %e2_1306, %e3_1307 = cute.get_leaves(%695) : !cute.stride<"((16,1),(8,64))">
      %696 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %697 = cute.get_shape(%696) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
      %e0_1308, %e1_1309, %e2_1310, %e3_1311 = cute.get_leaves(%697) : !cute.shape<"((4,8),(2,2))">
      %698 = cute.get_stride(%696) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
      %e0_1312, %e1_1313, %e2_1314, %e3_1315 = cute.get_leaves(%698) : !cute.stride<"((32,1),(16,8))">
      %699 = cute.static : !cute.tile<"[64:1;16:1]">
      %e0_1316, %e1_1317 = cute.get_leaves(%699) : !cute.tile<"[64:1;16:1]">
      %700 = cute.get_shape(%e0_1316) : (!cute.layout<"64:1">) -> !cute.shape<"64">
      %e0_1318 = cute.get_leaves(%700) : !cute.shape<"64">
      %701 = cute.get_stride(%e0_1316) : (!cute.layout<"64:1">) -> !cute.stride<"1">
      %e0_1319 = cute.get_leaves(%701) : !cute.stride<"1">
      %702 = cute.get_shape(%e1_1317) : (!cute.layout<"16:1">) -> !cute.shape<"16">
      %e0_1320 = cute.get_leaves(%702) : !cute.shape<"16">
      %703 = cute.get_stride(%e1_1317) : (!cute.layout<"16:1">) -> !cute.stride<"1">
      %e0_1321 = cute.get_leaves(%703) : !cute.stride<"1">
      %704 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %705 = cute.get_shape(%704) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.shape<"((4,8,4),((2,2),(1,2)))">
      %e0_1322, %e1_1323, %e2_1324, %e3_1325, %e4_1326, %e5, %e6 = cute.get_leaves(%705) : !cute.shape<"((4,8,4),((2,2),(1,2)))">
      %706 = cute.get_stride(%704) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.stride<"((128,1,16),((64,8),(0,512)))">
      %e0_1327, %e1_1328, %e2_1329, %e3_1330, %e4_1331, %e5_1332, %e6_1333 = cute.get_leaves(%706) : !cute.stride<"((128,1,16),((64,8),(0,512)))">
      %707 = cute.static : !cute.layout<"32:1">
      %708 = cute.get_shape(%707) : (!cute.layout<"32:1">) -> !cute.shape<"32">
      %e0_1334 = cute.get_leaves(%708) : !cute.shape<"32">
      %709 = cute.get_stride(%707) : (!cute.layout<"32:1">) -> !cute.stride<"1">
      %e0_1335 = cute.get_leaves(%709) : !cute.stride<"1">
      %710 = cute.static : !cute.layout<"(32,8):(8,1)">
      %711 = cute.get_shape(%710) : (!cute.layout<"(32,8):(8,1)">) -> !cute.shape<"(32,8)">
      %e0_1336, %e1_1337 = cute.get_leaves(%711) : !cute.shape<"(32,8)">
      %712 = cute.get_stride(%710) : (!cute.layout<"(32,8):(8,1)">) -> !cute.stride<"(8,1)">
      %e0_1338, %e1_1339 = cute.get_leaves(%712) : !cute.stride<"(8,1)">
      %713 = cute.static : !cute.layout<"(32,(2,4)):(2,(1,64))">
      %714 = cute.get_shape(%713) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.shape<"(32,(2,4))">
      %e0_1340, %e1_1341, %e2_1342 = cute.get_leaves(%714) : !cute.shape<"(32,(2,4))">
      %715 = cute.get_stride(%713) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.stride<"(2,(1,64))">
      %e0_1343, %e1_1344, %e2_1345 = cute.get_leaves(%715) : !cute.stride<"(2,(1,64))">
      %c-1_i32 = arith.constant -1 : i32
      %c1_i32 = arith.constant 1 : i32
      %716:2 = scf.for %arg12 = %c-1_i32 to %142 step %c1_i32 iter_args(%arg13 = %arg11, %arg14 = %163) -> (!mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3)  : i32 {
        %int_tuple_1743 = cute.make_int_tuple(%arg12) : (i32) -> !cute.int_tuple<"?">
        %sub_1744 = cute.tuple_sub(%tup, %int_tuple_1743) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %867 = cute.get_scalars(%sub_1744) : !cute.int_tuple<"?">
        nvvm.cp.async.wait.group 0
        %c1_i32_1745 = arith.constant 1 : i32
        %c128_i32_1746 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_1745 number_of_threads = %c128_i32_1746
        %868 = arith.cmpi eq, %867, %142 : i32
        scf.if %868 {
          %lay_2539 = cute.get_layout(%dst_partitioned_299) : !memref_smem_bf16_3
          %1026 = cute.get_shape(%lay_2539) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2540, %e1_2541, %e2_2542, %e3_2543 = cute.get_leaves(%1026) : !cute.shape<"((8,1),4,2)">
          %int_tuple_2544 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %sz_2545 = cute.size(%int_tuple_2544) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
          %e0_2546 = cute.get_leaves(%sz_2545) : !cute.int_tuple<"4">
          %coord_2547 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2548 = cute.slice(%src_partitioned_507, %coord_2547) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
          %iter_2549 = cute.get_iter(%slice_2548) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2550, %e1_2551, %e2_2552, %e3_2553 = cute.get_leaves(%iter_2549) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1027 = cute.get_scalars(%e0_2550) : !cute.int_tuple<"?">
          %1028 = cute.get_scalars(%e1_2551) : !cute.int_tuple<"?">
          %1029 = cute.get_scalars(%e2_2552) : !cute.int_tuple<"?">
          %1030 = cute.get_scalars(%e3_2553) : !cute.int_tuple<"?{div=8}">
          %iter_2554 = cute.get_iter(%slice_2548) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2555, %e1_2556, %e2_2557, %e3_2558 = cute.get_leaves(%iter_2554) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1031 = cute.get_scalars(%e0_2555) : !cute.int_tuple<"?">
          %1032 = cute.get_scalars(%e1_2556) : !cute.int_tuple<"?">
          %1033 = cute.get_scalars(%e2_2557) : !cute.int_tuple<"?">
          %1034 = cute.get_scalars(%e3_2558) : !cute.int_tuple<"?{div=8}">
          %iter_2559 = cute.get_iter(%slice_2548) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2560, %e1_2561, %e2_2562, %e3_2563 = cute.get_leaves(%iter_2559) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1035 = cute.get_scalars(%e0_2560) : !cute.int_tuple<"?">
          %1036 = cute.get_scalars(%e1_2561) : !cute.int_tuple<"?">
          %1037 = cute.get_scalars(%e2_2562) : !cute.int_tuple<"?">
          %1038 = cute.get_scalars(%e3_2563) : !cute.int_tuple<"?{div=8}">
          %lay_2564 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1039 = cute.get_shape(%lay_2564) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2565, %e1_2566, %e2_2567, %e3_2568 = cute.get_leaves(%1039) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2569 = cute.to_int_tuple(%e0_2565) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1040 = cute.get_scalars(%itup_2569) : !cute.int_tuple<"?">
          %itup_2570 = cute.to_int_tuple(%e1_2566) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1041 = cute.get_scalars(%itup_2570) : !cute.int_tuple<"?">
          %itup_2571 = cute.to_int_tuple(%e2_2567) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1042 = cute.get_scalars(%itup_2571) : !cute.int_tuple<"?">
          %itup_2572 = cute.to_int_tuple(%e3_2568) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1043 = cute.get_scalars(%itup_2572) : !cute.int_tuple<"?{div=8}">
          %coord_2573 = cute.make_coord(%e1_2561) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2574 = cute.make_coord(%itup_2570) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1044 = cute.elem_less(%coord_2573, %coord_2574) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1044 {
            %coord_2659 = cute.make_coord(%sub_1744) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %slice_2660 = cute.slice(%src_partitioned_296, %coord_2659) : !memref_gmem_bf16_6, !cute.coord<"(_,0,_,?)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_gmem_bf16_8
            %coord_2662 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2663 = cute.slice(%dst_partitioned_299, %coord_2662) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
            %iter_2664 = cute.get_iter(%slice_2663) : !memref_smem_bf16_12
            %coord_2665 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2666 = cute.slice(%rmem_551, %coord_2665) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
            %iter_2667 = cute.get_iter(%slice_2666) : !memref_rmem_i8_1
            %lay_2668 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %1099 = cute.get_shape(%lay_2668) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2669, %e1_2670, %e2_2671 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %lay_2672 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %1100 = cute.get_shape(%lay_2672) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2673, %e1_2674, %e2_2675 = cute.get_leaves(%1100) : !cute.shape<"((8,1),2)">
            %lay_2676 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %shape_2677 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2678 = cute.make_layout(%shape_2677) : !cute.layout<"1:0">
            %append_2679 = cute.append_to_rank<2> (%lay_2676, %lay_2678) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2680 = cute.make_view(%iter_2661, %append_2679) : !memref_gmem_bf16_8
            %iter_2681 = cute.get_iter(%view_2680) : !memref_gmem_bf16_8
            %lay_2682 = cute.get_layout(%view_2680) : !memref_gmem_bf16_8
            %1101 = cute.get_shape(%lay_2682) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2683, %e1_2684, %e2_2685 = cute.get_leaves(%1101) : !cute.shape<"((8,1),2)">
            %grouped_2686 = cute.group_modes(%view_2680) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2687 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %iter_2688 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %lay_2689 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %shape_2690 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2691 = cute.make_layout(%shape_2690) : !cute.layout<"1:0">
            %append_2692 = cute.append_to_rank<2> (%lay_2689, %lay_2691) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2693 = cute.make_view(%iter_2664, %append_2692) : !memref_smem_bf16_12
            %iter_2694 = cute.get_iter(%view_2693) : !memref_smem_bf16_12
            %lay_2695 = cute.get_layout(%view_2693) : !memref_smem_bf16_12
            %1102 = cute.get_shape(%lay_2695) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2696, %e1_2697, %e2_2698 = cute.get_leaves(%1102) : !cute.shape<"((8,1),2)">
            %grouped_2699 = cute.group_modes(%view_2693) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2700 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %iter_2701 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %lay_2702 = cute.get_layout(%slice_2666) : !memref_rmem_i8_1
            %shape_2703 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2704 = cute.make_layout(%shape_2703) : !cute.layout<"1:0">
            %append_2705 = cute.append_to_rank<2> (%lay_2702, %lay_2704) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2706 = cute.make_view(%iter_2667, %append_2705) : !memref_rmem_i8_1
            %iter_2707 = cute.get_iter(%view_2706) : !memref_rmem_i8_1
            %lay_2708 = cute.get_layout(%view_2706) : !memref_rmem_i8_1
            %1103 = cute.get_shape(%lay_2708) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2709, %e1_2710 = cute.get_leaves(%1103) : !cute.shape<"(1,2)">
            %grouped_2711 = cute.group_modes(%view_2706) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2712 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %iter_2713 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %lay_2714 = cute.get_layout(%grouped_2686) : !memref_gmem_bf16_9
            %1104 = cute.get_shape(%lay_2714) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2715, %e1_2716, %e2_2717 = cute.get_leaves(%1104) : !cute.shape<"((8,1),(2))">
            %lay_2718 = cute.get_layout(%grouped_2699) : !memref_smem_bf16_13
            %1105 = cute.get_shape(%lay_2718) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2719, %e1_2720, %e2_2721 = cute.get_leaves(%1105) : !cute.shape<"((8,1),(2))">
            %sz_2722 = cute.size(%grouped_2686) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2723 = cute.get_leaves(%sz_2722) : !cute.int_tuple<"2">
            %sz_2724 = cute.size(%grouped_2699) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2725 = cute.get_leaves(%sz_2724) : !cute.int_tuple<"2">
            cute.copy(%arg9, %grouped_2686, %grouped_2699, %grouped_2711) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2659 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2660 = cute.slice(%dst_partitioned_299, %coord_2659) : !memref_smem_bf16_3, !cute.coord<"(_,0,_)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_smem_bf16_12
            %sz_2662 = cute.size(%slice_2660) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2663 = cute.get_leaves(%sz_2662) : !cute.int_tuple<"16">
            %lay_2664 = cute.get_layout(%slice_2660) : !memref_smem_bf16_12
            %1099 = cute.get_shape(%lay_2664) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2665, %e1_2666, %e2_2667 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %int_tuple_2668 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2669 = cute.tuple.product(%int_tuple_2668) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2670 = cute.get_leaves(%res_2669) : !cute.int_tuple<"16">
            %cst_2671 = arith.constant 0.000000e+00 : bf16
            %1100 = vector.splat %cst_2671 : vector<16xbf16>
            %int_tuple_2672 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2673 = cute.size(%int_tuple_2672) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2674 = cute.get_leaves(%sz_2673) : !cute.int_tuple<"16">
            %int_tuple_2675 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2676 = cute.size(%int_tuple_2675) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2677 = cute.get_leaves(%sz_2676) : !cute.int_tuple<"16">
            cute.memref.store_vec %1100, %slice_2660, row_major : !memref_smem_bf16_12
          }
          %coord_2575 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
          %slice_2576 = cute.slice(%src_partitioned_507, %coord_2575) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
          %iter_2577 = cute.get_iter(%slice_2576) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2578, %e1_2579, %e2_2580, %e3_2581 = cute.get_leaves(%iter_2577) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1045 = cute.get_scalars(%e0_2578) : !cute.int_tuple<"?">
          %1046 = cute.get_scalars(%e1_2579) : !cute.int_tuple<"?">
          %1047 = cute.get_scalars(%e2_2580) : !cute.int_tuple<"?">
          %1048 = cute.get_scalars(%e3_2581) : !cute.int_tuple<"?{div=8}">
          %iter_2582 = cute.get_iter(%slice_2576) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2583, %e1_2584, %e2_2585, %e3_2586 = cute.get_leaves(%iter_2582) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1049 = cute.get_scalars(%e0_2583) : !cute.int_tuple<"?">
          %1050 = cute.get_scalars(%e1_2584) : !cute.int_tuple<"?">
          %1051 = cute.get_scalars(%e2_2585) : !cute.int_tuple<"?">
          %1052 = cute.get_scalars(%e3_2586) : !cute.int_tuple<"?{div=8}">
          %iter_2587 = cute.get_iter(%slice_2576) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2588, %e1_2589, %e2_2590, %e3_2591 = cute.get_leaves(%iter_2587) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1053 = cute.get_scalars(%e0_2588) : !cute.int_tuple<"?">
          %1054 = cute.get_scalars(%e1_2589) : !cute.int_tuple<"?">
          %1055 = cute.get_scalars(%e2_2590) : !cute.int_tuple<"?">
          %1056 = cute.get_scalars(%e3_2591) : !cute.int_tuple<"?{div=8}">
          %lay_2592 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1057 = cute.get_shape(%lay_2592) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2593, %e1_2594, %e2_2595, %e3_2596 = cute.get_leaves(%1057) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2597 = cute.to_int_tuple(%e0_2593) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1058 = cute.get_scalars(%itup_2597) : !cute.int_tuple<"?">
          %itup_2598 = cute.to_int_tuple(%e1_2594) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1059 = cute.get_scalars(%itup_2598) : !cute.int_tuple<"?">
          %itup_2599 = cute.to_int_tuple(%e2_2595) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1060 = cute.get_scalars(%itup_2599) : !cute.int_tuple<"?">
          %itup_2600 = cute.to_int_tuple(%e3_2596) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1061 = cute.get_scalars(%itup_2600) : !cute.int_tuple<"?{div=8}">
          %coord_2601 = cute.make_coord(%e1_2589) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2602 = cute.make_coord(%itup_2598) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1062 = cute.elem_less(%coord_2601, %coord_2602) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1062 {
            %coord_2659 = cute.make_coord(%sub_1744) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %slice_2660 = cute.slice(%src_partitioned_296, %coord_2659) : !memref_gmem_bf16_6, !cute.coord<"(_,1,_,?)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_gmem_bf16_8
            %coord_2662 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2663 = cute.slice(%dst_partitioned_299, %coord_2662) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
            %iter_2664 = cute.get_iter(%slice_2663) : !memref_smem_bf16_12
            %coord_2665 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2666 = cute.slice(%rmem_551, %coord_2665) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
            %iter_2667 = cute.get_iter(%slice_2666) : !memref_rmem_i8_1
            %lay_2668 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %1099 = cute.get_shape(%lay_2668) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2669, %e1_2670, %e2_2671 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %lay_2672 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %1100 = cute.get_shape(%lay_2672) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2673, %e1_2674, %e2_2675 = cute.get_leaves(%1100) : !cute.shape<"((8,1),2)">
            %lay_2676 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %shape_2677 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2678 = cute.make_layout(%shape_2677) : !cute.layout<"1:0">
            %append_2679 = cute.append_to_rank<2> (%lay_2676, %lay_2678) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2680 = cute.make_view(%iter_2661, %append_2679) : !memref_gmem_bf16_8
            %iter_2681 = cute.get_iter(%view_2680) : !memref_gmem_bf16_8
            %lay_2682 = cute.get_layout(%view_2680) : !memref_gmem_bf16_8
            %1101 = cute.get_shape(%lay_2682) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2683, %e1_2684, %e2_2685 = cute.get_leaves(%1101) : !cute.shape<"((8,1),2)">
            %grouped_2686 = cute.group_modes(%view_2680) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2687 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %iter_2688 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %lay_2689 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %shape_2690 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2691 = cute.make_layout(%shape_2690) : !cute.layout<"1:0">
            %append_2692 = cute.append_to_rank<2> (%lay_2689, %lay_2691) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2693 = cute.make_view(%iter_2664, %append_2692) : !memref_smem_bf16_12
            %iter_2694 = cute.get_iter(%view_2693) : !memref_smem_bf16_12
            %lay_2695 = cute.get_layout(%view_2693) : !memref_smem_bf16_12
            %1102 = cute.get_shape(%lay_2695) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2696, %e1_2697, %e2_2698 = cute.get_leaves(%1102) : !cute.shape<"((8,1),2)">
            %grouped_2699 = cute.group_modes(%view_2693) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2700 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %iter_2701 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %lay_2702 = cute.get_layout(%slice_2666) : !memref_rmem_i8_1
            %shape_2703 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2704 = cute.make_layout(%shape_2703) : !cute.layout<"1:0">
            %append_2705 = cute.append_to_rank<2> (%lay_2702, %lay_2704) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2706 = cute.make_view(%iter_2667, %append_2705) : !memref_rmem_i8_1
            %iter_2707 = cute.get_iter(%view_2706) : !memref_rmem_i8_1
            %lay_2708 = cute.get_layout(%view_2706) : !memref_rmem_i8_1
            %1103 = cute.get_shape(%lay_2708) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2709, %e1_2710 = cute.get_leaves(%1103) : !cute.shape<"(1,2)">
            %grouped_2711 = cute.group_modes(%view_2706) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2712 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %iter_2713 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %lay_2714 = cute.get_layout(%grouped_2686) : !memref_gmem_bf16_9
            %1104 = cute.get_shape(%lay_2714) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2715, %e1_2716, %e2_2717 = cute.get_leaves(%1104) : !cute.shape<"((8,1),(2))">
            %lay_2718 = cute.get_layout(%grouped_2699) : !memref_smem_bf16_13
            %1105 = cute.get_shape(%lay_2718) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2719, %e1_2720, %e2_2721 = cute.get_leaves(%1105) : !cute.shape<"((8,1),(2))">
            %sz_2722 = cute.size(%grouped_2686) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2723 = cute.get_leaves(%sz_2722) : !cute.int_tuple<"2">
            %sz_2724 = cute.size(%grouped_2699) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2725 = cute.get_leaves(%sz_2724) : !cute.int_tuple<"2">
            cute.copy(%arg9, %grouped_2686, %grouped_2699, %grouped_2711) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2659 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2660 = cute.slice(%dst_partitioned_299, %coord_2659) : !memref_smem_bf16_3, !cute.coord<"(_,1,_)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_smem_bf16_12
            %sz_2662 = cute.size(%slice_2660) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2663 = cute.get_leaves(%sz_2662) : !cute.int_tuple<"16">
            %lay_2664 = cute.get_layout(%slice_2660) : !memref_smem_bf16_12
            %1099 = cute.get_shape(%lay_2664) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2665, %e1_2666, %e2_2667 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %int_tuple_2668 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2669 = cute.tuple.product(%int_tuple_2668) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2670 = cute.get_leaves(%res_2669) : !cute.int_tuple<"16">
            %cst_2671 = arith.constant 0.000000e+00 : bf16
            %1100 = vector.splat %cst_2671 : vector<16xbf16>
            %int_tuple_2672 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2673 = cute.size(%int_tuple_2672) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2674 = cute.get_leaves(%sz_2673) : !cute.int_tuple<"16">
            %int_tuple_2675 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2676 = cute.size(%int_tuple_2675) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2677 = cute.get_leaves(%sz_2676) : !cute.int_tuple<"16">
            cute.memref.store_vec %1100, %slice_2660, row_major : !memref_smem_bf16_12
          }
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
          %slice_2604 = cute.slice(%src_partitioned_507, %coord_2603) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
          %iter_2605 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2606, %e1_2607, %e2_2608, %e3_2609 = cute.get_leaves(%iter_2605) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1063 = cute.get_scalars(%e0_2606) : !cute.int_tuple<"?">
          %1064 = cute.get_scalars(%e1_2607) : !cute.int_tuple<"?">
          %1065 = cute.get_scalars(%e2_2608) : !cute.int_tuple<"?">
          %1066 = cute.get_scalars(%e3_2609) : !cute.int_tuple<"?{div=8}">
          %iter_2610 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2611, %e1_2612, %e2_2613, %e3_2614 = cute.get_leaves(%iter_2610) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1067 = cute.get_scalars(%e0_2611) : !cute.int_tuple<"?">
          %1068 = cute.get_scalars(%e1_2612) : !cute.int_tuple<"?">
          %1069 = cute.get_scalars(%e2_2613) : !cute.int_tuple<"?">
          %1070 = cute.get_scalars(%e3_2614) : !cute.int_tuple<"?{div=8}">
          %iter_2615 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2616, %e1_2617, %e2_2618, %e3_2619 = cute.get_leaves(%iter_2615) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1071 = cute.get_scalars(%e0_2616) : !cute.int_tuple<"?">
          %1072 = cute.get_scalars(%e1_2617) : !cute.int_tuple<"?">
          %1073 = cute.get_scalars(%e2_2618) : !cute.int_tuple<"?">
          %1074 = cute.get_scalars(%e3_2619) : !cute.int_tuple<"?{div=8}">
          %lay_2620 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1075 = cute.get_shape(%lay_2620) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2621, %e1_2622, %e2_2623, %e3_2624 = cute.get_leaves(%1075) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2625 = cute.to_int_tuple(%e0_2621) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1076 = cute.get_scalars(%itup_2625) : !cute.int_tuple<"?">
          %itup_2626 = cute.to_int_tuple(%e1_2622) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1077 = cute.get_scalars(%itup_2626) : !cute.int_tuple<"?">
          %itup_2627 = cute.to_int_tuple(%e2_2623) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1078 = cute.get_scalars(%itup_2627) : !cute.int_tuple<"?">
          %itup_2628 = cute.to_int_tuple(%e3_2624) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1079 = cute.get_scalars(%itup_2628) : !cute.int_tuple<"?{div=8}">
          %coord_2629 = cute.make_coord(%e1_2617) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2630 = cute.make_coord(%itup_2626) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1080 = cute.elem_less(%coord_2629, %coord_2630) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1080 {
            %coord_2659 = cute.make_coord(%sub_1744) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %slice_2660 = cute.slice(%src_partitioned_296, %coord_2659) : !memref_gmem_bf16_6, !cute.coord<"(_,2,_,?)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_gmem_bf16_8
            %coord_2662 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2663 = cute.slice(%dst_partitioned_299, %coord_2662) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
            %iter_2664 = cute.get_iter(%slice_2663) : !memref_smem_bf16_12
            %coord_2665 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2666 = cute.slice(%rmem_551, %coord_2665) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
            %iter_2667 = cute.get_iter(%slice_2666) : !memref_rmem_i8_1
            %lay_2668 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %1099 = cute.get_shape(%lay_2668) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2669, %e1_2670, %e2_2671 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %lay_2672 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %1100 = cute.get_shape(%lay_2672) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2673, %e1_2674, %e2_2675 = cute.get_leaves(%1100) : !cute.shape<"((8,1),2)">
            %lay_2676 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %shape_2677 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2678 = cute.make_layout(%shape_2677) : !cute.layout<"1:0">
            %append_2679 = cute.append_to_rank<2> (%lay_2676, %lay_2678) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2680 = cute.make_view(%iter_2661, %append_2679) : !memref_gmem_bf16_8
            %iter_2681 = cute.get_iter(%view_2680) : !memref_gmem_bf16_8
            %lay_2682 = cute.get_layout(%view_2680) : !memref_gmem_bf16_8
            %1101 = cute.get_shape(%lay_2682) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2683, %e1_2684, %e2_2685 = cute.get_leaves(%1101) : !cute.shape<"((8,1),2)">
            %grouped_2686 = cute.group_modes(%view_2680) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2687 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %iter_2688 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %lay_2689 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %shape_2690 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2691 = cute.make_layout(%shape_2690) : !cute.layout<"1:0">
            %append_2692 = cute.append_to_rank<2> (%lay_2689, %lay_2691) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2693 = cute.make_view(%iter_2664, %append_2692) : !memref_smem_bf16_12
            %iter_2694 = cute.get_iter(%view_2693) : !memref_smem_bf16_12
            %lay_2695 = cute.get_layout(%view_2693) : !memref_smem_bf16_12
            %1102 = cute.get_shape(%lay_2695) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2696, %e1_2697, %e2_2698 = cute.get_leaves(%1102) : !cute.shape<"((8,1),2)">
            %grouped_2699 = cute.group_modes(%view_2693) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2700 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %iter_2701 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %lay_2702 = cute.get_layout(%slice_2666) : !memref_rmem_i8_1
            %shape_2703 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2704 = cute.make_layout(%shape_2703) : !cute.layout<"1:0">
            %append_2705 = cute.append_to_rank<2> (%lay_2702, %lay_2704) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2706 = cute.make_view(%iter_2667, %append_2705) : !memref_rmem_i8_1
            %iter_2707 = cute.get_iter(%view_2706) : !memref_rmem_i8_1
            %lay_2708 = cute.get_layout(%view_2706) : !memref_rmem_i8_1
            %1103 = cute.get_shape(%lay_2708) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2709, %e1_2710 = cute.get_leaves(%1103) : !cute.shape<"(1,2)">
            %grouped_2711 = cute.group_modes(%view_2706) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2712 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %iter_2713 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %lay_2714 = cute.get_layout(%grouped_2686) : !memref_gmem_bf16_9
            %1104 = cute.get_shape(%lay_2714) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2715, %e1_2716, %e2_2717 = cute.get_leaves(%1104) : !cute.shape<"((8,1),(2))">
            %lay_2718 = cute.get_layout(%grouped_2699) : !memref_smem_bf16_13
            %1105 = cute.get_shape(%lay_2718) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2719, %e1_2720, %e2_2721 = cute.get_leaves(%1105) : !cute.shape<"((8,1),(2))">
            %sz_2722 = cute.size(%grouped_2686) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2723 = cute.get_leaves(%sz_2722) : !cute.int_tuple<"2">
            %sz_2724 = cute.size(%grouped_2699) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2725 = cute.get_leaves(%sz_2724) : !cute.int_tuple<"2">
            cute.copy(%arg9, %grouped_2686, %grouped_2699, %grouped_2711) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2659 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2660 = cute.slice(%dst_partitioned_299, %coord_2659) : !memref_smem_bf16_3, !cute.coord<"(_,2,_)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_smem_bf16_12
            %sz_2662 = cute.size(%slice_2660) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2663 = cute.get_leaves(%sz_2662) : !cute.int_tuple<"16">
            %lay_2664 = cute.get_layout(%slice_2660) : !memref_smem_bf16_12
            %1099 = cute.get_shape(%lay_2664) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2665, %e1_2666, %e2_2667 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %int_tuple_2668 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2669 = cute.tuple.product(%int_tuple_2668) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2670 = cute.get_leaves(%res_2669) : !cute.int_tuple<"16">
            %cst_2671 = arith.constant 0.000000e+00 : bf16
            %1100 = vector.splat %cst_2671 : vector<16xbf16>
            %int_tuple_2672 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2673 = cute.size(%int_tuple_2672) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2674 = cute.get_leaves(%sz_2673) : !cute.int_tuple<"16">
            %int_tuple_2675 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2676 = cute.size(%int_tuple_2675) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2677 = cute.get_leaves(%sz_2676) : !cute.int_tuple<"16">
            cute.memref.store_vec %1100, %slice_2660, row_major : !memref_smem_bf16_12
          }
          %coord_2631 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
          %slice_2632 = cute.slice(%src_partitioned_507, %coord_2631) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
          %iter_2633 = cute.get_iter(%slice_2632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2634, %e1_2635, %e2_2636, %e3_2637 = cute.get_leaves(%iter_2633) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1081 = cute.get_scalars(%e0_2634) : !cute.int_tuple<"?">
          %1082 = cute.get_scalars(%e1_2635) : !cute.int_tuple<"?">
          %1083 = cute.get_scalars(%e2_2636) : !cute.int_tuple<"?">
          %1084 = cute.get_scalars(%e3_2637) : !cute.int_tuple<"?{div=8}">
          %iter_2638 = cute.get_iter(%slice_2632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2639, %e1_2640, %e2_2641, %e3_2642 = cute.get_leaves(%iter_2638) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1085 = cute.get_scalars(%e0_2639) : !cute.int_tuple<"?">
          %1086 = cute.get_scalars(%e1_2640) : !cute.int_tuple<"?">
          %1087 = cute.get_scalars(%e2_2641) : !cute.int_tuple<"?">
          %1088 = cute.get_scalars(%e3_2642) : !cute.int_tuple<"?{div=8}">
          %iter_2643 = cute.get_iter(%slice_2632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2644, %e1_2645, %e2_2646, %e3_2647 = cute.get_leaves(%iter_2643) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1089 = cute.get_scalars(%e0_2644) : !cute.int_tuple<"?">
          %1090 = cute.get_scalars(%e1_2645) : !cute.int_tuple<"?">
          %1091 = cute.get_scalars(%e2_2646) : !cute.int_tuple<"?">
          %1092 = cute.get_scalars(%e3_2647) : !cute.int_tuple<"?{div=8}">
          %lay_2648 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %1093 = cute.get_shape(%lay_2648) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2649, %e1_2650, %e2_2651, %e3_2652 = cute.get_leaves(%1093) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2653 = cute.to_int_tuple(%e0_2649) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1094 = cute.get_scalars(%itup_2653) : !cute.int_tuple<"?">
          %itup_2654 = cute.to_int_tuple(%e1_2650) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1095 = cute.get_scalars(%itup_2654) : !cute.int_tuple<"?">
          %itup_2655 = cute.to_int_tuple(%e2_2651) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1096 = cute.get_scalars(%itup_2655) : !cute.int_tuple<"?">
          %itup_2656 = cute.to_int_tuple(%e3_2652) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1097 = cute.get_scalars(%itup_2656) : !cute.int_tuple<"?{div=8}">
          %coord_2657 = cute.make_coord(%e1_2645) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2658 = cute.make_coord(%itup_2654) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1098 = cute.elem_less(%coord_2657, %coord_2658) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1098 {
            %coord_2659 = cute.make_coord(%sub_1744) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %slice_2660 = cute.slice(%src_partitioned_296, %coord_2659) : !memref_gmem_bf16_6, !cute.coord<"(_,3,_,?)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_gmem_bf16_8
            %coord_2662 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2663 = cute.slice(%dst_partitioned_299, %coord_2662) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
            %iter_2664 = cute.get_iter(%slice_2663) : !memref_smem_bf16_12
            %coord_2665 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2666 = cute.slice(%rmem_551, %coord_2665) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
            %iter_2667 = cute.get_iter(%slice_2666) : !memref_rmem_i8_1
            %lay_2668 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %1099 = cute.get_shape(%lay_2668) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2669, %e1_2670, %e2_2671 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %lay_2672 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %1100 = cute.get_shape(%lay_2672) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2673, %e1_2674, %e2_2675 = cute.get_leaves(%1100) : !cute.shape<"((8,1),2)">
            %lay_2676 = cute.get_layout(%slice_2660) : !memref_gmem_bf16_8
            %shape_2677 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2678 = cute.make_layout(%shape_2677) : !cute.layout<"1:0">
            %append_2679 = cute.append_to_rank<2> (%lay_2676, %lay_2678) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
            %view_2680 = cute.make_view(%iter_2661, %append_2679) : !memref_gmem_bf16_8
            %iter_2681 = cute.get_iter(%view_2680) : !memref_gmem_bf16_8
            %lay_2682 = cute.get_layout(%view_2680) : !memref_gmem_bf16_8
            %1101 = cute.get_shape(%lay_2682) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
            %e0_2683, %e1_2684, %e2_2685 = cute.get_leaves(%1101) : !cute.shape<"((8,1),2)">
            %grouped_2686 = cute.group_modes(%view_2680) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
            %iter_2687 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %iter_2688 = cute.get_iter(%grouped_2686) : !memref_gmem_bf16_9
            %lay_2689 = cute.get_layout(%slice_2663) : !memref_smem_bf16_12
            %shape_2690 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2691 = cute.make_layout(%shape_2690) : !cute.layout<"1:0">
            %append_2692 = cute.append_to_rank<2> (%lay_2689, %lay_2691) : !cute.layout<"((8,1),2):((1,0),4096)">, !cute.layout<"1:0">
            %view_2693 = cute.make_view(%iter_2664, %append_2692) : !memref_smem_bf16_12
            %iter_2694 = cute.get_iter(%view_2693) : !memref_smem_bf16_12
            %lay_2695 = cute.get_layout(%view_2693) : !memref_smem_bf16_12
            %1102 = cute.get_shape(%lay_2695) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2696, %e1_2697, %e2_2698 = cute.get_leaves(%1102) : !cute.shape<"((8,1),2)">
            %grouped_2699 = cute.group_modes(%view_2693) <1, 2> : (!memref_smem_bf16_12) -> !memref_smem_bf16_13
            %iter_2700 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %iter_2701 = cute.get_iter(%grouped_2699) : !memref_smem_bf16_13
            %lay_2702 = cute.get_layout(%slice_2666) : !memref_rmem_i8_1
            %shape_2703 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2704 = cute.make_layout(%shape_2703) : !cute.layout<"1:0">
            %append_2705 = cute.append_to_rank<2> (%lay_2702, %lay_2704) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
            %view_2706 = cute.make_view(%iter_2667, %append_2705) : !memref_rmem_i8_1
            %iter_2707 = cute.get_iter(%view_2706) : !memref_rmem_i8_1
            %lay_2708 = cute.get_layout(%view_2706) : !memref_rmem_i8_1
            %1103 = cute.get_shape(%lay_2708) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
            %e0_2709, %e1_2710 = cute.get_leaves(%1103) : !cute.shape<"(1,2)">
            %grouped_2711 = cute.group_modes(%view_2706) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
            %iter_2712 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %iter_2713 = cute.get_iter(%grouped_2711) : !memref_rmem_i8_2
            %lay_2714 = cute.get_layout(%grouped_2686) : !memref_gmem_bf16_9
            %1104 = cute.get_shape(%lay_2714) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
            %e0_2715, %e1_2716, %e2_2717 = cute.get_leaves(%1104) : !cute.shape<"((8,1),(2))">
            %lay_2718 = cute.get_layout(%grouped_2699) : !memref_smem_bf16_13
            %1105 = cute.get_shape(%lay_2718) : (!cute.layout<"((8,1),(2)):((1,0),(4096))">) -> !cute.shape<"((8,1),(2))">
            %e0_2719, %e1_2720, %e2_2721 = cute.get_leaves(%1105) : !cute.shape<"((8,1),(2))">
            %sz_2722 = cute.size(%grouped_2686) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
            %e0_2723 = cute.get_leaves(%sz_2722) : !cute.int_tuple<"2">
            %sz_2724 = cute.size(%grouped_2699) <{mode = [1]}> : (!memref_smem_bf16_13) -> !cute.int_tuple<"2">
            %e0_2725 = cute.get_leaves(%sz_2724) : !cute.int_tuple<"2">
            cute.copy(%arg9, %grouped_2686, %grouped_2699, %grouped_2711) : (!copy_ldgsts, !memref_gmem_bf16_9, !memref_smem_bf16_13, !memref_rmem_i8_2)
          } else {
            %coord_2659 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2660 = cute.slice(%dst_partitioned_299, %coord_2659) : !memref_smem_bf16_3, !cute.coord<"(_,3,_)">
            %iter_2661 = cute.get_iter(%slice_2660) : !memref_smem_bf16_12
            %sz_2662 = cute.size(%slice_2660) : (!memref_smem_bf16_12) -> !cute.int_tuple<"16">
            %e0_2663 = cute.get_leaves(%sz_2662) : !cute.int_tuple<"16">
            %lay_2664 = cute.get_layout(%slice_2660) : !memref_smem_bf16_12
            %1099 = cute.get_shape(%lay_2664) : (!cute.layout<"((8,1),2):((1,0),4096)">) -> !cute.shape<"((8,1),2)">
            %e0_2665, %e1_2666, %e2_2667 = cute.get_leaves(%1099) : !cute.shape<"((8,1),2)">
            %int_tuple_2668 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %res_2669 = cute.tuple.product(%int_tuple_2668) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2670 = cute.get_leaves(%res_2669) : !cute.int_tuple<"16">
            %cst_2671 = arith.constant 0.000000e+00 : bf16
            %1100 = vector.splat %cst_2671 : vector<16xbf16>
            %int_tuple_2672 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2673 = cute.size(%int_tuple_2672) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2674 = cute.get_leaves(%sz_2673) : !cute.int_tuple<"16">
            %int_tuple_2675 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),2)">
            %sz_2676 = cute.size(%int_tuple_2675) : (!cute.int_tuple<"((8,1),2)">) -> !cute.int_tuple<"16">
            %e0_2677 = cute.get_leaves(%sz_2676) : !cute.int_tuple<"16">
            cute.memref.store_vec %1100, %slice_2660, row_major : !memref_smem_bf16_12
          }
        } else {
          %coord_2539 = cute.make_coord(%sub_1744) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %slice_2540 = cute.slice(%src_partitioned_296, %coord_2539) : !memref_gmem_bf16_6, !cute.coord<"(_,_,_,?)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_gmem_bf16_5
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2543 = cute.slice(%dst_partitioned_299, %coord_2542) : !memref_smem_bf16_3, !cute.coord<"(_,_,_)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_smem_bf16_3
          %coord_2545 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2546 = cute.slice(%rmem_551, %coord_2545) : !memref_rmem_i8_, !cute.coord<"(_,_,_)">
          %iter_2547 = cute.get_iter(%slice_2546) : !memref_rmem_i8_
          %lay_2548 = cute.get_layout(%slice_2540) : !memref_gmem_bf16_5
          %1026 = cute.get_shape(%lay_2548) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2549, %e1_2550, %e2_2551, %e3_2552 = cute.get_leaves(%1026) : !cute.shape<"((8,1),4,2)">
          %lay_2553 = cute.get_layout(%slice_2543) : !memref_smem_bf16_3
          %1027 = cute.get_shape(%lay_2553) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2554, %e1_2555, %e2_2556, %e3_2557 = cute.get_leaves(%1027) : !cute.shape<"((8,1),4,2)">
          %lay_2558 = cute.get_layout(%slice_2540) : !memref_gmem_bf16_5
          %shape_2559 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2560 = cute.make_layout(%shape_2559) : !cute.layout<"1:0">
          %append_2561 = cute.append_to_rank<2> (%lay_2558, %lay_2560) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_2562 = cute.make_view(%iter_2541, %append_2561) : !memref_gmem_bf16_5
          %iter_2563 = cute.get_iter(%view_2562) : !memref_gmem_bf16_5
          %lay_2564 = cute.get_layout(%view_2562) : !memref_gmem_bf16_5
          %1028 = cute.get_shape(%lay_2564) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2565, %e1_2566, %e2_2567, %e3_2568 = cute.get_leaves(%1028) : !cute.shape<"((8,1),4,2)">
          %grouped_2569 = cute.group_modes(%view_2562) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_13
          %iter_2570 = cute.get_iter(%grouped_2569) : !memref_gmem_bf16_13
          %iter_2571 = cute.get_iter(%grouped_2569) : !memref_gmem_bf16_13
          %lay_2572 = cute.get_layout(%slice_2543) : !memref_smem_bf16_3
          %shape_2573 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2574 = cute.make_layout(%shape_2573) : !cute.layout<"1:0">
          %append_2575 = cute.append_to_rank<2> (%lay_2572, %lay_2574) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
          %view_2576 = cute.make_view(%iter_2544, %append_2575) : !memref_smem_bf16_3
          %iter_2577 = cute.get_iter(%view_2576) : !memref_smem_bf16_3
          %lay_2578 = cute.get_layout(%view_2576) : !memref_smem_bf16_3
          %1029 = cute.get_shape(%lay_2578) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2579, %e1_2580, %e2_2581, %e3_2582 = cute.get_leaves(%1029) : !cute.shape<"((8,1),4,2)">
          %grouped_2583 = cute.group_modes(%view_2576) <1, 3> : (!memref_smem_bf16_3) -> !memref_smem_bf16_17
          %iter_2584 = cute.get_iter(%grouped_2583) : !memref_smem_bf16_17
          %iter_2585 = cute.get_iter(%grouped_2583) : !memref_smem_bf16_17
          %lay_2586 = cute.get_layout(%slice_2546) : !memref_rmem_i8_
          %shape_2587 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2588 = cute.make_layout(%shape_2587) : !cute.layout<"1:0">
          %append_2589 = cute.append_to_rank<2> (%lay_2586, %lay_2588) : !cute.layout<"(1,4,2):(2,0,1)">, !cute.layout<"1:0">
          %view_2590 = cute.make_view(%iter_2547, %append_2589) : !memref_rmem_i8_
          %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_i8_
          %lay_2592 = cute.get_layout(%view_2590) : !memref_rmem_i8_
          %1030 = cute.get_shape(%lay_2592) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
          %e0_2593, %e1_2594, %e2_2595 = cute.get_leaves(%1030) : !cute.shape<"(1,4,2)">
          %grouped_2596 = cute.group_modes(%view_2590) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_3
          %iter_2597 = cute.get_iter(%grouped_2596) : !memref_rmem_i8_3
          %iter_2598 = cute.get_iter(%grouped_2596) : !memref_rmem_i8_3
          %lay_2599 = cute.get_layout(%grouped_2569) : !memref_gmem_bf16_13
          %1031 = cute.get_shape(%lay_2599) : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2600, %e1_2601, %e2_2602, %e3_2603 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(4,2))">
          %lay_2604 = cute.get_layout(%grouped_2583) : !memref_smem_bf16_17
          %1032 = cute.get_shape(%lay_2604) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2605, %e1_2606, %e2_2607, %e3_2608 = cute.get_leaves(%1032) : !cute.shape<"((8,1),(4,2))">
          %sz_2609 = cute.size(%grouped_2569) <{mode = [1]}> : (!memref_gmem_bf16_13) -> !cute.int_tuple<"8">
          %e0_2610 = cute.get_leaves(%sz_2609) : !cute.int_tuple<"8">
          %sz_2611 = cute.size(%grouped_2583) <{mode = [1]}> : (!memref_smem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2612 = cute.get_leaves(%sz_2611) : !cute.int_tuple<"8">
          cute.copy(%arg9, %grouped_2569, %grouped_2583, %grouped_2596) : (!copy_ldgsts, !memref_gmem_bf16_13, !memref_smem_bf16_17, !memref_rmem_i8_3)
        }
        nvvm.cp.async.commit.group
        %shape_1747 = cute.make_shape() : () -> !cute.shape<"(64,64)">
        %869 = cute.tiled.mma.partition_shape C (%arg13, %shape_1747) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,64)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1748, %e1_1749, %e2_1750, %e3_1751 = cute.get_leaves(%869) : !cute.shape<"((2,2),1,8)">
        %shape_1752 = cute.make_shape() : () -> !cute.shape<"((2,2),1,8)">
        %lay_1753 = cute.make_layout(%shape_1752) : !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_1754 = cute.memref.alloca(%lay_1753) : !memref_rmem_f32_1
        %iter_1755 = cute.get_iter(%rmem_1754) : !memref_rmem_f32_1
        %iter_1756 = cute.get_iter(%rmem_1754) : !memref_rmem_f32_1
        %shape_1757 = cute.make_shape() : () -> !cute.shape<"(64,64)">
        %870 = cute.tiled.mma.partition_shape C (%arg13, %shape_1757) : (!mma_bf16_bf16_f32_16x8x16_, !cute.shape<"(64,64)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1758, %e1_1759, %e2_1760, %e3_1761 = cute.get_leaves(%870) : !cute.shape<"((2,2),1,8)">
        %shape_1762 = cute.make_shape() : () -> !cute.shape<"((2,2),1,8)">
        %lay_1763 = cute.make_layout(%shape_1762) : !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_1764 = cute.memref.alloca(%lay_1763) : !memref_rmem_bf16_6
        %iter_1765 = cute.get_iter(%rmem_1764) : !memref_rmem_bf16_6
        %iter_1766 = cute.get_iter(%rmem_1764) : !memref_rmem_bf16_6
        %retiled_1767 = cute.tiled.copy.retile(%arg14, %rmem_1764) : (!copy_ldsm_4_3, !memref_rmem_bf16_6) -> !memref_rmem_bf16_7
        %iter_1768 = cute.get_iter(%retiled_1767) : !memref_rmem_bf16_7
        %coord_1769 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
        %slice_1770 = cute.slice(%src_partitioned_407, %coord_1769) : !memref_smem_bf16_11, !cute.coord<"(_,_,_)">
        %iter_1771 = cute.get_iter(%slice_1770) : !memref_smem_bf16_11
        %coord_1772 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
        %slice_1773 = cute.slice(%retiled_1767, %coord_1772) : !memref_rmem_bf16_7, !cute.coord<"(_,_,_)">
        %iter_1774 = cute.get_iter(%slice_1773) : !memref_rmem_bf16_7
        %lay_1775 = cute.get_layout(%slice_1770) : !memref_smem_bf16_11
        %871 = cute.get_shape(%lay_1775) : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !cute.shape<"((8,1),1,(2,2))">
        %e0_1776, %e1_1777, %e2_1778, %e3_1779, %e4_1780 = cute.get_leaves(%871) : !cute.shape<"((8,1),1,(2,2))">
        %lay_1781 = cute.get_layout(%slice_1773) : !memref_rmem_bf16_7
        %872 = cute.get_shape(%lay_1781) : (!cute.layout<"((8,1),1,4):((1,0),0,8)">) -> !cute.shape<"((8,1),1,4)">
        %e0_1782, %e1_1783, %e2_1784, %e3_1785 = cute.get_leaves(%872) : !cute.shape<"((8,1),1,4)">
        %lay_1786 = cute.get_layout(%slice_1770) : !memref_smem_bf16_11
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1771, %append_1789) : !memref_smem_bf16_11
        %iter_1791 = cute.get_iter(%view_1790) : !memref_smem_bf16_11
        %lay_1792 = cute.get_layout(%view_1790) : !memref_smem_bf16_11
        %873 = cute.get_shape(%lay_1792) : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !cute.shape<"((8,1),1,(2,2))">
        %e0_1793, %e1_1794, %e2_1795, %e3_1796, %e4_1797 = cute.get_leaves(%873) : !cute.shape<"((8,1),1,(2,2))">
        %grouped_1798 = cute.group_modes(%view_1790) <1, 3> : (!memref_smem_bf16_11) -> !memref_smem_bf16_18
        %iter_1799 = cute.get_iter(%grouped_1798) : !memref_smem_bf16_18
        %iter_1800 = cute.get_iter(%grouped_1798) : !memref_smem_bf16_18
        %lay_1801 = cute.get_layout(%slice_1773) : !memref_rmem_bf16_7
        %shape_1802 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1803 = cute.make_layout(%shape_1802) : !cute.layout<"1:0">
        %append_1804 = cute.append_to_rank<2> (%lay_1801, %lay_1803) : !cute.layout<"((8,1),1,4):((1,0),0,8)">, !cute.layout<"1:0">
        %view_1805 = cute.make_view(%iter_1774, %append_1804) : !memref_rmem_bf16_7
        %iter_1806 = cute.get_iter(%view_1805) : !memref_rmem_bf16_7
        %lay_1807 = cute.get_layout(%view_1805) : !memref_rmem_bf16_7
        %874 = cute.get_shape(%lay_1807) : (!cute.layout<"((8,1),1,4):((1,0),0,8)">) -> !cute.shape<"((8,1),1,4)">
        %e0_1808, %e1_1809, %e2_1810, %e3_1811 = cute.get_leaves(%874) : !cute.shape<"((8,1),1,4)">
        %grouped_1812 = cute.group_modes(%view_1805) <1, 3> : (!memref_rmem_bf16_7) -> !memref_rmem_bf16_8
        %iter_1813 = cute.get_iter(%grouped_1812) : !memref_rmem_bf16_8
        %iter_1814 = cute.get_iter(%grouped_1812) : !memref_rmem_bf16_8
        %lay_1815 = cute.get_layout(%grouped_1798) : !memref_smem_bf16_18
        %875 = cute.get_shape(%lay_1815) : (!cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">) -> !cute.shape<"((8,1),(1,(2,2)))">
        %e0_1816, %e1_1817, %e2_1818, %e3_1819, %e4_1820 = cute.get_leaves(%875) : !cute.shape<"((8,1),(1,(2,2)))">
        %lay_1821 = cute.get_layout(%grouped_1812) : !memref_rmem_bf16_8
        %876 = cute.get_shape(%lay_1821) : (!cute.layout<"((8,1),(1,4)):((1,0),(0,8))">) -> !cute.shape<"((8,1),(1,4))">
        %e0_1822, %e1_1823, %e2_1824, %e3_1825 = cute.get_leaves(%876) : !cute.shape<"((8,1),(1,4))">
        %sz_1826 = cute.size(%grouped_1798) <{mode = [1]}> : (!memref_smem_bf16_18) -> !cute.int_tuple<"4">
        %e0_1827 = cute.get_leaves(%sz_1826) : !cute.int_tuple<"4">
        %sz_1828 = cute.size(%grouped_1812) <{mode = [1]}> : (!memref_rmem_bf16_8) -> !cute.int_tuple<"4">
        %e0_1829 = cute.get_leaves(%sz_1828) : !cute.int_tuple<"4">
        cute.copy(%163, %grouped_1798, %grouped_1812) : (!copy_ldsm_4_3, !memref_smem_bf16_18, !memref_rmem_bf16_8)
        %lay_1830 = cute.get_layout(%rmem_1764) : !memref_rmem_bf16_6
        %877 = cute.get_shape(%lay_1830) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1831, %e1_1832, %e2_1833, %e3_1834 = cute.get_leaves(%877) : !cute.shape<"((2,2),1,8)">
        %878 = cute.memref.load_vec %rmem_1764, row_major : !memref_rmem_bf16_6
        %879 = arith.extf %878 : vector<32xbf16> to vector<32xf32>
        %lay_1835 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
        %880 = cute.get_shape(%lay_1835) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_1836, %e1_1837, %e2_1838, %e3_1839 = cute.get_leaves(%880) : !cute.shape<"((2,2),1,8)">
        %int_tuple_1840 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_1841 = cute.size(%int_tuple_1840) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_1842 = cute.get_leaves(%sz_1841) : !cute.int_tuple<"32">
        %int_tuple_1843 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_1844 = cute.size(%int_tuple_1843) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_1845 = cute.get_leaves(%sz_1844) : !cute.int_tuple<"32">
        cute.memref.store_vec %879, %rmem_1754, row_major : !memref_rmem_f32_1
        %coord_1846 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1847 = cute.slice(%src_partitioned_393, %coord_1846) : !memref_smem_bf16_8, !cute.coord<"(_,_,0)">
        %iter_1848 = cute.get_iter(%slice_1847) : !memref_smem_bf16_15
        %coord_1849 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1850 = cute.slice(%retiled, %coord_1849) : !memref_rmem_bf16_3, !cute.coord<"(_,_,0)">
        %iter_1851 = cute.get_iter(%slice_1850) : !memref_rmem_bf16_9
        %lay_1852 = cute.get_layout(%slice_1847) : !memref_smem_bf16_15
        %881 = cute.get_shape(%lay_1852) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1853, %e1_1854, %e2_1855 = cute.get_leaves(%881) : !cute.shape<"((8,1),1)">
        %lay_1856 = cute.get_layout(%slice_1850) : !memref_rmem_bf16_9
        %882 = cute.get_shape(%lay_1856) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1857, %e1_1858, %e2_1859 = cute.get_leaves(%882) : !cute.shape<"((8,1),1)">
        %lay_1860 = cute.get_layout(%slice_1847) : !memref_smem_bf16_15
        %shape_1861 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1862 = cute.make_layout(%shape_1861) : !cute.layout<"1:0">
        %append_1863 = cute.append_to_rank<2> (%lay_1860, %lay_1862) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
        %view_1864 = cute.make_view(%iter_1848, %append_1863) : !memref_smem_bf16_15
        %iter_1865 = cute.get_iter(%view_1864) : !memref_smem_bf16_15
        %lay_1866 = cute.get_layout(%view_1864) : !memref_smem_bf16_15
        %883 = cute.get_shape(%lay_1866) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1867, %e1_1868, %e2_1869 = cute.get_leaves(%883) : !cute.shape<"((8,1),1)">
        %grouped_1870 = cute.group_modes(%view_1864) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
        %iter_1871 = cute.get_iter(%grouped_1870) : !memref_smem_bf16_16
        %iter_1872 = cute.get_iter(%grouped_1870) : !memref_smem_bf16_16
        %lay_1873 = cute.get_layout(%slice_1850) : !memref_rmem_bf16_9
        %shape_1874 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1875 = cute.make_layout(%shape_1874) : !cute.layout<"1:0">
        %append_1876 = cute.append_to_rank<2> (%lay_1873, %lay_1875) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
        %view_1877 = cute.make_view(%iter_1851, %append_1876) : !memref_rmem_bf16_9
        %iter_1878 = cute.get_iter(%view_1877) : !memref_rmem_bf16_9
        %lay_1879 = cute.get_layout(%view_1877) : !memref_rmem_bf16_9
        %884 = cute.get_shape(%lay_1879) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
        %e0_1880, %e1_1881, %e2_1882 = cute.get_leaves(%884) : !cute.shape<"((8,1),1)">
        %grouped_1883 = cute.group_modes(%view_1877) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
        %iter_1884 = cute.get_iter(%grouped_1883) : !memref_rmem_bf16_10
        %iter_1885 = cute.get_iter(%grouped_1883) : !memref_rmem_bf16_10
        %lay_1886 = cute.get_layout(%grouped_1870) : !memref_smem_bf16_16
        %885 = cute.get_shape(%lay_1886) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1887, %e1_1888, %e2_1889 = cute.get_leaves(%885) : !cute.shape<"((8,1),(1))">
        %lay_1890 = cute.get_layout(%grouped_1883) : !memref_rmem_bf16_10
        %886 = cute.get_shape(%lay_1890) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
        %e0_1891, %e1_1892, %e2_1893 = cute.get_leaves(%886) : !cute.shape<"((8,1),(1))">
        %sz_1894 = cute.size(%grouped_1870) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
        %e0_1895 = cute.get_leaves(%sz_1894) : !cute.int_tuple<"1">
        %sz_1896 = cute.size(%grouped_1883) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
        %e0_1897 = cute.get_leaves(%sz_1896) : !cute.int_tuple<"1">
        cute.copy(%151, %grouped_1870, %grouped_1883) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
        %coord_1898 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1899 = cute.slice(%src_partitioned_397, %coord_1898) : !memref_smem_bf16_9, !cute.coord<"(_,_,0)">
        %iter_1900 = cute.get_iter(%slice_1899) : !memref_smem_bf16_19
        %coord_1901 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1902 = cute.slice(%retiled_399, %coord_1901) : !memref_rmem_bf16_4, !cute.coord<"(_,_,0)">
        %iter_1903 = cute.get_iter(%slice_1902) : !memref_rmem_bf16_11
        %lay_1904 = cute.get_layout(%slice_1899) : !memref_smem_bf16_19
        %887 = cute.get_shape(%lay_1904) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
        %e0_1905, %e1_1906, %e2_1907 = cute.get_leaves(%887) : !cute.shape<"((8,1),4)">
        %lay_1908 = cute.get_layout(%slice_1902) : !memref_rmem_bf16_11
        %888 = cute.get_shape(%lay_1908) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
        %e0_1909, %e1_1910, %e2_1911, %e3_1912 = cute.get_leaves(%888) : !cute.shape<"(((4,2),1),4)">
        %lay_1913 = cute.get_layout(%slice_1899) : !memref_smem_bf16_19
        %shape_1914 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1915 = cute.make_layout(%shape_1914) : !cute.layout<"1:0">
        %append_1916 = cute.append_to_rank<2> (%lay_1913, %lay_1915) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
        %view_1917 = cute.make_view(%iter_1900, %append_1916) : !memref_smem_bf16_19
        %iter_1918 = cute.get_iter(%view_1917) : !memref_smem_bf16_19
        %lay_1919 = cute.get_layout(%view_1917) : !memref_smem_bf16_19
        %889 = cute.get_shape(%lay_1919) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
        %e0_1920, %e1_1921, %e2_1922 = cute.get_leaves(%889) : !cute.shape<"((8,1),4)">
        %grouped_1923 = cute.group_modes(%view_1917) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
        %iter_1924 = cute.get_iter(%grouped_1923) : !memref_smem_bf16_20
        %iter_1925 = cute.get_iter(%grouped_1923) : !memref_smem_bf16_20
        %lay_1926 = cute.get_layout(%slice_1902) : !memref_rmem_bf16_11
        %shape_1927 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1928 = cute.make_layout(%shape_1927) : !cute.layout<"1:0">
        %append_1929 = cute.append_to_rank<2> (%lay_1926, %lay_1928) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
        %view_1930 = cute.make_view(%iter_1903, %append_1929) : !memref_rmem_bf16_11
        %iter_1931 = cute.get_iter(%view_1930) : !memref_rmem_bf16_11
        %lay_1932 = cute.get_layout(%view_1930) : !memref_rmem_bf16_11
        %890 = cute.get_shape(%lay_1932) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
        %e0_1933, %e1_1934, %e2_1935, %e3_1936 = cute.get_leaves(%890) : !cute.shape<"(((4,2),1),4)">
        %grouped_1937 = cute.group_modes(%view_1930) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
        %iter_1938 = cute.get_iter(%grouped_1937) : !memref_rmem_bf16_12
        %iter_1939 = cute.get_iter(%grouped_1937) : !memref_rmem_bf16_12
        %lay_1940 = cute.get_layout(%grouped_1923) : !memref_smem_bf16_20
        %891 = cute.get_shape(%lay_1940) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
        %e0_1941, %e1_1942, %e2_1943 = cute.get_leaves(%891) : !cute.shape<"((8,1),(4))">
        %lay_1944 = cute.get_layout(%grouped_1937) : !memref_rmem_bf16_12
        %892 = cute.get_shape(%lay_1944) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
        %e0_1945, %e1_1946, %e2_1947, %e3_1948 = cute.get_leaves(%892) : !cute.shape<"(((4,2),1),(4))">
        %sz_1949 = cute.size(%grouped_1923) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
        %e0_1950 = cute.get_leaves(%sz_1949) : !cute.int_tuple<"4">
        %sz_1951 = cute.size(%grouped_1937) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
        %e0_1952 = cute.get_leaves(%sz_1951) : !cute.int_tuple<"4">
        cute.copy(%155, %grouped_1923, %grouped_1937) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        %lay_1953 = cute.get_layout(%src_partitioned_393) : !memref_smem_bf16_8
        %893 = cute.get_shape(%lay_1953) : (!cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),1,((2,2),2))">
        %e0_1954, %e1_1955, %e2_1956, %e3_1957, %e4_1958, %e5_1959 = cute.get_leaves(%893) : !cute.shape<"((8,1),1,((2,2),2))">
        %int_tuple_1960 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_1961 = cute.size(%int_tuple_1960) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_1962 = cute.get_leaves(%sz_1961) : !cute.int_tuple<"8">
        %int_tuple_1963 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_1964 = cute.size(%int_tuple_1963) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_1965 = cute.get_leaves(%sz_1964) : !cute.int_tuple<"8">
        %true = arith.constant true
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,1)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,1)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,1)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,1)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_1966 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1967 = cute.slice(%frg_A, %coord_1966) : !memref_rmem_bf16_, !cute.coord<"(_,_,0)">
        %iter_1968 = cute.get_iter(%slice_1967) : !memref_rmem_bf16_13
        %coord_1969 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_1970 = cute.slice(%frg_B, %coord_1969) : !memref_rmem_bf16_1, !cute.coord<"(_,_,0)">
        %iter_1971 = cute.get_iter(%slice_1970) : !memref_rmem_bf16_14
        %lay_1972 = cute.get_layout(%slice_1967) : !memref_rmem_bf16_13
        %894 = cute.get_shape(%lay_1972) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_1973, %e1_1974, %e2_1975, %e3_1976 = cute.get_leaves(%894) : !cute.shape<"((2,2,2),1)">
        %lay_1977 = cute.get_layout(%slice_1970) : !memref_rmem_bf16_14
        %895 = cute.get_shape(%lay_1977) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_1978, %e1_1979, %e2_1980, %e3_1981 = cute.get_leaves(%895) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_1967, %slice_1970, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_1982 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_1983 = cute.size(%int_tuple_1982) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_1984 = cute.get_leaves(%sz_1983) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,2)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,2)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,2)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,2)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_1985 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_1986 = cute.slice(%frg_A, %coord_1985) : !memref_rmem_bf16_, !cute.coord<"(_,_,1)">
        %iter_1987 = cute.get_iter(%slice_1986) : !memref_rmem_bf16_13
        %coord_1988 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_1989 = cute.slice(%frg_B, %coord_1988) : !memref_rmem_bf16_1, !cute.coord<"(_,_,1)">
        %iter_1990 = cute.get_iter(%slice_1989) : !memref_rmem_bf16_14
        %lay_1991 = cute.get_layout(%slice_1986) : !memref_rmem_bf16_13
        %896 = cute.get_shape(%lay_1991) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_1992, %e1_1993, %e2_1994, %e3_1995 = cute.get_leaves(%896) : !cute.shape<"((2,2,2),1)">
        %lay_1996 = cute.get_layout(%slice_1989) : !memref_rmem_bf16_14
        %897 = cute.get_shape(%lay_1996) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_1997, %e1_1998, %e2_1999, %e3_2000 = cute.get_leaves(%897) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_1986, %slice_1989, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2001 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2002 = cute.size(%int_tuple_2001) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2003 = cute.get_leaves(%sz_2002) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,3)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,3)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,3)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,3)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2004 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2005 = cute.slice(%frg_A, %coord_2004) : !memref_rmem_bf16_, !cute.coord<"(_,_,2)">
        %iter_2006 = cute.get_iter(%slice_2005) : !memref_rmem_bf16_13
        %coord_2007 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2008 = cute.slice(%frg_B, %coord_2007) : !memref_rmem_bf16_1, !cute.coord<"(_,_,2)">
        %iter_2009 = cute.get_iter(%slice_2008) : !memref_rmem_bf16_14
        %lay_2010 = cute.get_layout(%slice_2005) : !memref_rmem_bf16_13
        %898 = cute.get_shape(%lay_2010) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2011, %e1_2012, %e2_2013, %e3_2014 = cute.get_leaves(%898) : !cute.shape<"((2,2,2),1)">
        %lay_2015 = cute.get_layout(%slice_2008) : !memref_rmem_bf16_14
        %899 = cute.get_shape(%lay_2015) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2016, %e1_2017, %e2_2018, %e3_2019 = cute.get_leaves(%899) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2005, %slice_2008, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2020 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2021 = cute.size(%int_tuple_2020) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2022 = cute.get_leaves(%sz_2021) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,4)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,4)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,4)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,4)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2023 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2024 = cute.slice(%frg_A, %coord_2023) : !memref_rmem_bf16_, !cute.coord<"(_,_,3)">
        %iter_2025 = cute.get_iter(%slice_2024) : !memref_rmem_bf16_13
        %coord_2026 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2027 = cute.slice(%frg_B, %coord_2026) : !memref_rmem_bf16_1, !cute.coord<"(_,_,3)">
        %iter_2028 = cute.get_iter(%slice_2027) : !memref_rmem_bf16_14
        %lay_2029 = cute.get_layout(%slice_2024) : !memref_rmem_bf16_13
        %900 = cute.get_shape(%lay_2029) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2030, %e1_2031, %e2_2032, %e3_2033 = cute.get_leaves(%900) : !cute.shape<"((2,2,2),1)">
        %lay_2034 = cute.get_layout(%slice_2027) : !memref_rmem_bf16_14
        %901 = cute.get_shape(%lay_2034) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2035, %e1_2036, %e2_2037, %e3_2038 = cute.get_leaves(%901) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2024, %slice_2027, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2039 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2040 = cute.size(%int_tuple_2039) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2041 = cute.get_leaves(%sz_2040) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,5)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,5)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,5)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,5)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2042 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
        %slice_2043 = cute.slice(%frg_A, %coord_2042) : !memref_rmem_bf16_, !cute.coord<"(_,_,4)">
        %iter_2044 = cute.get_iter(%slice_2043) : !memref_rmem_bf16_13
        %coord_2045 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
        %slice_2046 = cute.slice(%frg_B, %coord_2045) : !memref_rmem_bf16_1, !cute.coord<"(_,_,4)">
        %iter_2047 = cute.get_iter(%slice_2046) : !memref_rmem_bf16_14
        %lay_2048 = cute.get_layout(%slice_2043) : !memref_rmem_bf16_13
        %902 = cute.get_shape(%lay_2048) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2049, %e1_2050, %e2_2051, %e3_2052 = cute.get_leaves(%902) : !cute.shape<"((2,2,2),1)">
        %lay_2053 = cute.get_layout(%slice_2046) : !memref_rmem_bf16_14
        %903 = cute.get_shape(%lay_2053) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2054, %e1_2055, %e2_2056, %e3_2057 = cute.get_leaves(%903) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2043, %slice_2046, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2058 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2059 = cute.size(%int_tuple_2058) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2060 = cute.get_leaves(%sz_2059) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,6)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,6)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,6)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,6)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2061 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
        %slice_2062 = cute.slice(%frg_A, %coord_2061) : !memref_rmem_bf16_, !cute.coord<"(_,_,5)">
        %iter_2063 = cute.get_iter(%slice_2062) : !memref_rmem_bf16_13
        %coord_2064 = cute.make_coord() : () -> !cute.coord<"(_,_,5)">
        %slice_2065 = cute.slice(%frg_B, %coord_2064) : !memref_rmem_bf16_1, !cute.coord<"(_,_,5)">
        %iter_2066 = cute.get_iter(%slice_2065) : !memref_rmem_bf16_14
        %lay_2067 = cute.get_layout(%slice_2062) : !memref_rmem_bf16_13
        %904 = cute.get_shape(%lay_2067) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2068, %e1_2069, %e2_2070, %e3_2071 = cute.get_leaves(%904) : !cute.shape<"((2,2,2),1)">
        %lay_2072 = cute.get_layout(%slice_2065) : !memref_rmem_bf16_14
        %905 = cute.get_shape(%lay_2072) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2073, %e1_2074, %e2_2075, %e3_2076 = cute.get_leaves(%905) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2062, %slice_2065, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2077 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2078 = cute.size(%int_tuple_2077) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2079 = cute.get_leaves(%sz_2078) : !cute.int_tuple<"8">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,7)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,7)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,7)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,7)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2080 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
        %slice_2081 = cute.slice(%frg_A, %coord_2080) : !memref_rmem_bf16_, !cute.coord<"(_,_,6)">
        %iter_2082 = cute.get_iter(%slice_2081) : !memref_rmem_bf16_13
        %coord_2083 = cute.make_coord() : () -> !cute.coord<"(_,_,6)">
        %slice_2084 = cute.slice(%frg_B, %coord_2083) : !memref_rmem_bf16_1, !cute.coord<"(_,_,6)">
        %iter_2085 = cute.get_iter(%slice_2084) : !memref_rmem_bf16_14
        %lay_2086 = cute.get_layout(%slice_2081) : !memref_rmem_bf16_13
        %906 = cute.get_shape(%lay_2086) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2087, %e1_2088, %e2_2089, %e3_2090 = cute.get_leaves(%906) : !cute.shape<"((2,2,2),1)">
        %lay_2091 = cute.get_layout(%slice_2084) : !memref_rmem_bf16_14
        %907 = cute.get_shape(%lay_2091) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2092, %e1_2093, %e2_2094, %e3_2095 = cute.get_leaves(%907) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2081, %slice_2084, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        %int_tuple_2096 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),2)">
        %sz_2097 = cute.size(%int_tuple_2096) : (!cute.int_tuple<"((2,2),2)">) -> !cute.int_tuple<"8">
        %e0_2098 = cute.get_leaves(%sz_2097) : !cute.int_tuple<"8">
        %false = arith.constant false
        scf.if %false {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2540 = cute.slice(%src_partitioned_393, %coord_2539) : !memref_smem_bf16_8, !cute.coord<"(_,_,8)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_15
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2543 = cute.slice(%retiled, %coord_2542) : !memref_rmem_bf16_3, !cute.coord<"(_,_,8)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_9
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2546, %e1_2547, %e2_2548 = cute.get_leaves(%1026) : !cute.shape<"((8,1),1)">
          %lay_2549 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %1027 = cute.get_shape(%lay_2549) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2550, %e1_2551, %e2_2552 = cute.get_leaves(%1027) : !cute.shape<"((8,1),1)">
          %lay_2553 = cute.get_layout(%slice_2540) : !memref_smem_bf16_15
          %shape_2554 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2555 = cute.make_layout(%shape_2554) : !cute.layout<"1:0">
          %append_2556 = cute.append_to_rank<2> (%lay_2553, %lay_2555) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2557 = cute.make_view(%iter_2541, %append_2556) : !memref_smem_bf16_15
          %iter_2558 = cute.get_iter(%view_2557) : !memref_smem_bf16_15
          %lay_2559 = cute.get_layout(%view_2557) : !memref_smem_bf16_15
          %1028 = cute.get_shape(%lay_2559) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2560, %e1_2561, %e2_2562 = cute.get_leaves(%1028) : !cute.shape<"((8,1),1)">
          %grouped_2563 = cute.group_modes(%view_2557) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
          %iter_2564 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %iter_2565 = cute.get_iter(%grouped_2563) : !memref_smem_bf16_16
          %lay_2566 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_9
          %shape_2567 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2568 = cute.make_layout(%shape_2567) : !cute.layout<"1:0">
          %append_2569 = cute.append_to_rank<2> (%lay_2566, %lay_2568) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
          %view_2570 = cute.make_view(%iter_2544, %append_2569) : !memref_rmem_bf16_9
          %iter_2571 = cute.get_iter(%view_2570) : !memref_rmem_bf16_9
          %lay_2572 = cute.get_layout(%view_2570) : !memref_rmem_bf16_9
          %1029 = cute.get_shape(%lay_2572) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
          %e0_2573, %e1_2574, %e2_2575 = cute.get_leaves(%1029) : !cute.shape<"((8,1),1)">
          %grouped_2576 = cute.group_modes(%view_2570) <1, 2> : (!memref_rmem_bf16_9) -> !memref_rmem_bf16_10
          %iter_2577 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %iter_2578 = cute.get_iter(%grouped_2576) : !memref_rmem_bf16_10
          %lay_2579 = cute.get_layout(%grouped_2563) : !memref_smem_bf16_16
          %1030 = cute.get_shape(%lay_2579) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2580, %e1_2581, %e2_2582 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(1))">
          %lay_2583 = cute.get_layout(%grouped_2576) : !memref_rmem_bf16_10
          %1031 = cute.get_shape(%lay_2583) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
          %e0_2584, %e1_2585, %e2_2586 = cute.get_leaves(%1031) : !cute.shape<"((8,1),(1))">
          %sz_2587 = cute.size(%grouped_2563) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
          %e0_2588 = cute.get_leaves(%sz_2587) : !cute.int_tuple<"1">
          %sz_2589 = cute.size(%grouped_2576) <{mode = [1]}> : (!memref_rmem_bf16_10) -> !cute.int_tuple<"1">
          %e0_2590 = cute.get_leaves(%sz_2589) : !cute.int_tuple<"1">
          cute.copy(%151, %grouped_2563, %grouped_2576) : (!copy_ldsm_4_, !memref_smem_bf16_16, !memref_rmem_bf16_10)
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2592 = cute.slice(%src_partitioned_397, %coord_2591) : !memref_smem_bf16_9, !cute.coord<"(_,_,8)">
          %iter_2593 = cute.get_iter(%slice_2592) : !memref_smem_bf16_19
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(_,_,8)">
          %slice_2595 = cute.slice(%retiled_399, %coord_2594) : !memref_rmem_bf16_4, !cute.coord<"(_,_,8)">
          %iter_2596 = cute.get_iter(%slice_2595) : !memref_rmem_bf16_11
          %lay_2597 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %1032 = cute.get_shape(%lay_2597) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2598, %e1_2599, %e2_2600 = cute.get_leaves(%1032) : !cute.shape<"((8,1),4)">
          %lay_2601 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %1033 = cute.get_shape(%lay_2601) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1033) : !cute.shape<"(((4,2),1),4)">
          %lay_2606 = cute.get_layout(%slice_2592) : !memref_smem_bf16_19
          %shape_2607 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2608 = cute.make_layout(%shape_2607) : !cute.layout<"1:0">
          %append_2609 = cute.append_to_rank<2> (%lay_2606, %lay_2608) : !cute.layout<"((8,1),4):((1,0),1024)">, !cute.layout<"1:0">
          %view_2610 = cute.make_view(%iter_2593, %append_2609) : !memref_smem_bf16_19
          %iter_2611 = cute.get_iter(%view_2610) : !memref_smem_bf16_19
          %lay_2612 = cute.get_layout(%view_2610) : !memref_smem_bf16_19
          %1034 = cute.get_shape(%lay_2612) : (!cute.layout<"((8,1),4):((1,0),1024)">) -> !cute.shape<"((8,1),4)">
          %e0_2613, %e1_2614, %e2_2615 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4)">
          %grouped_2616 = cute.group_modes(%view_2610) <1, 2> : (!memref_smem_bf16_19) -> !memref_smem_bf16_20
          %iter_2617 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %iter_2618 = cute.get_iter(%grouped_2616) : !memref_smem_bf16_20
          %lay_2619 = cute.get_layout(%slice_2595) : !memref_rmem_bf16_11
          %shape_2620 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2621 = cute.make_layout(%shape_2620) : !cute.layout<"1:0">
          %append_2622 = cute.append_to_rank<2> (%lay_2619, %lay_2621) : !cute.layout<"(((4,2),1),4):(((1,32),0),4)">, !cute.layout<"1:0">
          %view_2623 = cute.make_view(%iter_2596, %append_2622) : !memref_rmem_bf16_11
          %iter_2624 = cute.get_iter(%view_2623) : !memref_rmem_bf16_11
          %lay_2625 = cute.get_layout(%view_2623) : !memref_rmem_bf16_11
          %1035 = cute.get_shape(%lay_2625) : (!cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !cute.shape<"(((4,2),1),4)">
          %e0_2626, %e1_2627, %e2_2628, %e3_2629 = cute.get_leaves(%1035) : !cute.shape<"(((4,2),1),4)">
          %grouped_2630 = cute.group_modes(%view_2623) <1, 2> : (!memref_rmem_bf16_11) -> !memref_rmem_bf16_12
          %iter_2631 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %iter_2632 = cute.get_iter(%grouped_2630) : !memref_rmem_bf16_12
          %lay_2633 = cute.get_layout(%grouped_2616) : !memref_smem_bf16_20
          %1036 = cute.get_shape(%lay_2633) : (!cute.layout<"((8,1),(4)):((1,0),(1024))">) -> !cute.shape<"((8,1),(4))">
          %e0_2634, %e1_2635, %e2_2636 = cute.get_leaves(%1036) : !cute.shape<"((8,1),(4))">
          %lay_2637 = cute.get_layout(%grouped_2630) : !memref_rmem_bf16_12
          %1037 = cute.get_shape(%lay_2637) : (!cute.layout<"(((4,2),1),(4)):(((1,32),0),(4))">) -> !cute.shape<"(((4,2),1),(4))">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1037) : !cute.shape<"(((4,2),1),(4))">
          %sz_2642 = cute.size(%grouped_2616) <{mode = [1]}> : (!memref_smem_bf16_20) -> !cute.int_tuple<"4">
          %e0_2643 = cute.get_leaves(%sz_2642) : !cute.int_tuple<"4">
          %sz_2644 = cute.size(%grouped_2630) <{mode = [1]}> : (!memref_rmem_bf16_12) -> !cute.int_tuple<"4">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"4">
          cute.copy(%155, %grouped_2616, %grouped_2630) : (!copy_ldsm_4_1, !memref_smem_bf16_20, !memref_rmem_bf16_12)
        }
        %coord_2099 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
        %slice_2100 = cute.slice(%frg_A, %coord_2099) : !memref_rmem_bf16_, !cute.coord<"(_,_,7)">
        %iter_2101 = cute.get_iter(%slice_2100) : !memref_rmem_bf16_13
        %coord_2102 = cute.make_coord() : () -> !cute.coord<"(_,_,7)">
        %slice_2103 = cute.slice(%frg_B, %coord_2102) : !memref_rmem_bf16_1, !cute.coord<"(_,_,7)">
        %iter_2104 = cute.get_iter(%slice_2103) : !memref_rmem_bf16_14
        %lay_2105 = cute.get_layout(%slice_2100) : !memref_rmem_bf16_13
        %908 = cute.get_shape(%lay_2105) : (!cute.layout<"((2,2,2),1):((1,2,4),0)">) -> !cute.shape<"((2,2,2),1)">
        %e0_2106, %e1_2107, %e2_2108, %e3_2109 = cute.get_leaves(%908) : !cute.shape<"((2,2,2),1)">
        %lay_2110 = cute.get_layout(%slice_2103) : !memref_rmem_bf16_14
        %909 = cute.get_shape(%lay_2110) : (!cute.layout<"((2,2),(2,4)):((1,2),(32,4))">) -> !cute.shape<"((2,2),(2,4))">
        %e0_2111, %e1_2112, %e2_2113, %e3_2114 = cute.get_leaves(%909) : !cute.shape<"((2,2),(2,4))">
        cute.gemm(%arg11, %rmem_1754, %slice_2100, %slice_2103, %rmem_1754) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_1, !memref_rmem_bf16_13, !memref_rmem_bf16_14, !memref_rmem_f32_1)
        nvvm.cp.async.wait.group 0
        %c1_i32_2115 = arith.constant 1 : i32
        %c128_i32_2116 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_2115 number_of_threads = %c128_i32_2116
        %c0_i32_2117 = arith.constant 0 : i32
        %910 = arith.cmpi sgt, %867, %c0_i32_2117 : i32
        scf.if %910 {
          %int_tuple_2539 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sub_2540 = cute.tuple_sub(%sub_1744, %int_tuple_2539) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %1026 = cute.get_scalars(%sub_2540) : !cute.int_tuple<"?">
          %coord_2541 = cute.make_coord(%sub_2540) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %slice_2542 = cute.slice(%src_partitioned_290, %coord_2541) : !memref_gmem_bf16_6, !cute.coord<"(_,_,_,?)">
          %iter_2543 = cute.get_iter(%slice_2542) : !memref_gmem_bf16_5
          %coord_2544 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2545 = cute.slice(%dst_partitioned_293, %coord_2544) : !memref_smem_bf16_3, !cute.coord<"(_,_,_)">
          %iter_2546 = cute.get_iter(%slice_2545) : !memref_smem_bf16_3
          %coord_2547 = cute.make_coord() : () -> !cute.coord<"(_,_,_)">
          %slice_2548 = cute.slice(%rmem_551, %coord_2547) : !memref_rmem_i8_, !cute.coord<"(_,_,_)">
          %iter_2549 = cute.get_iter(%slice_2548) : !memref_rmem_i8_
          %lay_2550 = cute.get_layout(%slice_2542) : !memref_gmem_bf16_5
          %1027 = cute.get_shape(%lay_2550) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2551, %e1_2552, %e2_2553, %e3_2554 = cute.get_leaves(%1027) : !cute.shape<"((8,1),4,2)">
          %lay_2555 = cute.get_layout(%slice_2545) : !memref_smem_bf16_3
          %1028 = cute.get_shape(%lay_2555) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2556, %e1_2557, %e2_2558, %e3_2559 = cute.get_leaves(%1028) : !cute.shape<"((8,1),4,2)">
          %lay_2560 = cute.get_layout(%slice_2542) : !memref_gmem_bf16_5
          %shape_2561 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2562 = cute.make_layout(%shape_2561) : !cute.layout<"1:0">
          %append_2563 = cute.append_to_rank<2> (%lay_2560, %lay_2562) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_2564 = cute.make_view(%iter_2543, %append_2563) : !memref_gmem_bf16_5
          %iter_2565 = cute.get_iter(%view_2564) : !memref_gmem_bf16_5
          %lay_2566 = cute.get_layout(%view_2564) : !memref_gmem_bf16_5
          %1029 = cute.get_shape(%lay_2566) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2567, %e1_2568, %e2_2569, %e3_2570 = cute.get_leaves(%1029) : !cute.shape<"((8,1),4,2)">
          %grouped_2571 = cute.group_modes(%view_2564) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_13
          %iter_2572 = cute.get_iter(%grouped_2571) : !memref_gmem_bf16_13
          %iter_2573 = cute.get_iter(%grouped_2571) : !memref_gmem_bf16_13
          %lay_2574 = cute.get_layout(%slice_2545) : !memref_smem_bf16_3
          %shape_2575 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2576 = cute.make_layout(%shape_2575) : !cute.layout<"1:0">
          %append_2577 = cute.append_to_rank<2> (%lay_2574, %lay_2576) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
          %view_2578 = cute.make_view(%iter_2546, %append_2577) : !memref_smem_bf16_3
          %iter_2579 = cute.get_iter(%view_2578) : !memref_smem_bf16_3
          %lay_2580 = cute.get_layout(%view_2578) : !memref_smem_bf16_3
          %1030 = cute.get_shape(%lay_2580) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
          %e0_2581, %e1_2582, %e2_2583, %e3_2584 = cute.get_leaves(%1030) : !cute.shape<"((8,1),4,2)">
          %grouped_2585 = cute.group_modes(%view_2578) <1, 3> : (!memref_smem_bf16_3) -> !memref_smem_bf16_17
          %iter_2586 = cute.get_iter(%grouped_2585) : !memref_smem_bf16_17
          %iter_2587 = cute.get_iter(%grouped_2585) : !memref_smem_bf16_17
          %lay_2588 = cute.get_layout(%slice_2548) : !memref_rmem_i8_
          %shape_2589 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2590 = cute.make_layout(%shape_2589) : !cute.layout<"1:0">
          %append_2591 = cute.append_to_rank<2> (%lay_2588, %lay_2590) : !cute.layout<"(1,4,2):(2,0,1)">, !cute.layout<"1:0">
          %view_2592 = cute.make_view(%iter_2549, %append_2591) : !memref_rmem_i8_
          %iter_2593 = cute.get_iter(%view_2592) : !memref_rmem_i8_
          %lay_2594 = cute.get_layout(%view_2592) : !memref_rmem_i8_
          %1031 = cute.get_shape(%lay_2594) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
          %e0_2595, %e1_2596, %e2_2597 = cute.get_leaves(%1031) : !cute.shape<"(1,4,2)">
          %grouped_2598 = cute.group_modes(%view_2592) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_3
          %iter_2599 = cute.get_iter(%grouped_2598) : !memref_rmem_i8_3
          %iter_2600 = cute.get_iter(%grouped_2598) : !memref_rmem_i8_3
          %lay_2601 = cute.get_layout(%grouped_2571) : !memref_gmem_bf16_13
          %1032 = cute.get_shape(%lay_2601) : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1032) : !cute.shape<"((8,1),(4,2))">
          %lay_2606 = cute.get_layout(%grouped_2585) : !memref_smem_bf16_17
          %1033 = cute.get_shape(%lay_2606) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2607, %e1_2608, %e2_2609, %e3_2610 = cute.get_leaves(%1033) : !cute.shape<"((8,1),(4,2))">
          %sz_2611 = cute.size(%grouped_2571) <{mode = [1]}> : (!memref_gmem_bf16_13) -> !cute.int_tuple<"8">
          %e0_2612 = cute.get_leaves(%sz_2611) : !cute.int_tuple<"8">
          %sz_2613 = cute.size(%grouped_2585) <{mode = [1]}> : (!memref_smem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2614 = cute.get_leaves(%sz_2613) : !cute.int_tuple<"8">
          cute.copy(%arg9, %grouped_2571, %grouped_2585, %grouped_2598) : (!copy_ldgsts, !memref_gmem_bf16_13, !memref_smem_bf16_17, !memref_rmem_i8_3)
          %lay_2615 = cute.get_layout(%src_partitioned_514) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %1034 = cute.get_shape(%lay_2615) : (!cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.shape<"((8,1),4,1,?)">
          %e0_2616, %e1_2617, %e2_2618, %e3_2619, %e4_2620 = cute.get_leaves(%1034) : !cute.shape<"((8,1),4,1,?)">
          %itup_2621 = cute.to_int_tuple(%e4_2620) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1035 = cute.get_scalars(%itup_2621) : !cute.int_tuple<"?">
          %int_tuple_2622 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %sz_2623 = cute.size(%int_tuple_2622) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
          %e0_2624 = cute.get_leaves(%sz_2623) : !cute.int_tuple<"4">
          %coord_2625 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %slice_2626 = cute.slice(%src_partitioned_514, %coord_2625) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,0,0,?)">
          %iter_2627 = cute.get_iter(%slice_2626) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2628, %e1_2629, %e2_2630, %e3_2631 = cute.get_leaves(%iter_2627) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1036 = cute.get_scalars(%e0_2628) : !cute.int_tuple<"?">
          %1037 = cute.get_scalars(%e1_2629) : !cute.int_tuple<"?">
          %1038 = cute.get_scalars(%e2_2630) : !cute.int_tuple<"?">
          %1039 = cute.get_scalars(%e3_2631) : !cute.int_tuple<"?{div=8}">
          %iter_2632 = cute.get_iter(%slice_2626) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2633, %e1_2634, %e2_2635, %e3_2636 = cute.get_leaves(%iter_2632) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1040 = cute.get_scalars(%e0_2633) : !cute.int_tuple<"?">
          %1041 = cute.get_scalars(%e1_2634) : !cute.int_tuple<"?">
          %1042 = cute.get_scalars(%e2_2635) : !cute.int_tuple<"?">
          %1043 = cute.get_scalars(%e3_2636) : !cute.int_tuple<"?{div=8}">
          %iter_2637 = cute.get_iter(%slice_2626) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%iter_2637) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1044 = cute.get_scalars(%e0_2638) : !cute.int_tuple<"?">
          %1045 = cute.get_scalars(%e1_2639) : !cute.int_tuple<"?">
          %1046 = cute.get_scalars(%e2_2640) : !cute.int_tuple<"?">
          %1047 = cute.get_scalars(%e3_2641) : !cute.int_tuple<"?{div=8}">
          %lay_2642 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1048 = cute.get_shape(%lay_2642) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2643, %e1_2644, %e2_2645, %e3_2646 = cute.get_leaves(%1048) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2647 = cute.to_int_tuple(%e0_2643) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1049 = cute.get_scalars(%itup_2647) : !cute.int_tuple<"?">
          %itup_2648 = cute.to_int_tuple(%e1_2644) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1050 = cute.get_scalars(%itup_2648) : !cute.int_tuple<"?">
          %itup_2649 = cute.to_int_tuple(%e2_2645) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1051 = cute.get_scalars(%itup_2649) : !cute.int_tuple<"?">
          %itup_2650 = cute.to_int_tuple(%e3_2646) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1052 = cute.get_scalars(%itup_2650) : !cute.int_tuple<"?{div=8}">
          %coord_2651 = cute.make_coord(%e1_2639) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2652 = cute.make_coord(%itup_2649) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1053 = cute.elem_less(%coord_2651, %coord_2652) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1053 {
            %int_tuple_2737 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2738 = cute.tuple_sub(%sub_1744, %int_tuple_2737) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1108 = cute.get_scalars(%sub_2738) : !cute.int_tuple<"?">
            %coord_2739 = cute.make_coord(%sub_2738) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %slice_2740 = cute.slice(%src_partitioned_302, %coord_2739) : !memref_gmem_bf16_7, !cute.coord<"(_,0,_,?)">
            %iter_2741 = cute.get_iter(%slice_2740) : !memref_gmem_bf16_11
            %coord_2742 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2743 = cute.slice(%dst_partitioned_305, %coord_2742) : !memref_smem_bf16_4, !cute.coord<"(_,0,_)">
            %iter_2744 = cute.get_iter(%slice_2743) : !memref_smem_bf16_15
            %lay_2745 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %1109 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1109) : !cute.shape<"((8,1),1)">
            %lay_2749 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %1110 = cute.get_shape(%lay_2749) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2750, %e1_2751, %e2_2752 = cute.get_leaves(%1110) : !cute.shape<"((8,1),1)">
            %lay_2753 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %shape_2754 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2755 = cute.make_layout(%shape_2754) : !cute.layout<"1:0">
            %append_2756 = cute.append_to_rank<2> (%lay_2753, %lay_2755) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2757 = cute.make_view(%iter_2741, %append_2756) : !memref_gmem_bf16_11
            %iter_2758 = cute.get_iter(%view_2757) : !memref_gmem_bf16_11
            %lay_2759 = cute.get_layout(%view_2757) : !memref_gmem_bf16_11
            %1111 = cute.get_shape(%lay_2759) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2760, %e1_2761, %e2_2762 = cute.get_leaves(%1111) : !cute.shape<"((8,1),1)">
            %grouped_2763 = cute.group_modes(%view_2757) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2764 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %iter_2765 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %lay_2766 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %shape_2767 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2768 = cute.make_layout(%shape_2767) : !cute.layout<"1:0">
            %append_2769 = cute.append_to_rank<2> (%lay_2766, %lay_2768) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2770 = cute.make_view(%iter_2744, %append_2769) : !memref_smem_bf16_15
            %iter_2771 = cute.get_iter(%view_2770) : !memref_smem_bf16_15
            %lay_2772 = cute.get_layout(%view_2770) : !memref_smem_bf16_15
            %1112 = cute.get_shape(%lay_2772) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2773, %e1_2774, %e2_2775 = cute.get_leaves(%1112) : !cute.shape<"((8,1),1)">
            %grouped_2776 = cute.group_modes(%view_2770) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2777 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %iter_2778 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %lay_2779 = cute.get_layout(%grouped_2763) : !memref_gmem_bf16_12
            %1113 = cute.get_shape(%lay_2779) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2780, %e1_2781, %e2_2782 = cute.get_leaves(%1113) : !cute.shape<"((8,1),(1))">
            %lay_2783 = cute.get_layout(%grouped_2776) : !memref_smem_bf16_16
            %1114 = cute.get_shape(%lay_2783) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2784, %e1_2785, %e2_2786 = cute.get_leaves(%1114) : !cute.shape<"((8,1),(1))">
            %sz_2787 = cute.size(%grouped_2763) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"1">
            %sz_2789 = cute.size(%grouped_2776) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2790 = cute.get_leaves(%sz_2789) : !cute.int_tuple<"1">
            cute.copy(%arg9, %grouped_2763, %grouped_2776) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2737 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
            %slice_2738 = cute.slice(%dst_partitioned_305, %coord_2737) : !memref_smem_bf16_4, !cute.coord<"(_,0,_)">
            %iter_2739 = cute.get_iter(%slice_2738) : !memref_smem_bf16_15
            %sz_2740 = cute.size(%slice_2738) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2741 = cute.get_leaves(%sz_2740) : !cute.int_tuple<"8">
            %lay_2742 = cute.get_layout(%slice_2738) : !memref_smem_bf16_15
            %1108 = cute.get_shape(%lay_2742) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2743, %e1_2744, %e2_2745 = cute.get_leaves(%1108) : !cute.shape<"((8,1),1)">
            %int_tuple_2746 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2747 = cute.tuple.product(%int_tuple_2746) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2748 = cute.get_leaves(%res_2747) : !cute.int_tuple<"8">
            %cst_2749 = arith.constant 0.000000e+00 : bf16
            %1109 = vector.splat %cst_2749 : vector<8xbf16>
            %int_tuple_2750 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2751 = cute.size(%int_tuple_2750) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2752 = cute.get_leaves(%sz_2751) : !cute.int_tuple<"8">
            %int_tuple_2753 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2754 = cute.size(%int_tuple_2753) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2755 = cute.get_leaves(%sz_2754) : !cute.int_tuple<"8">
            cute.memref.store_vec %1109, %slice_2738, row_major : !memref_smem_bf16_15
          }
          %coord_2653 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %slice_2654 = cute.slice(%src_partitioned_514, %coord_2653) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,1,0,?)">
          %iter_2655 = cute.get_iter(%slice_2654) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2656, %e1_2657, %e2_2658, %e3_2659 = cute.get_leaves(%iter_2655) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1054 = cute.get_scalars(%e0_2656) : !cute.int_tuple<"?">
          %1055 = cute.get_scalars(%e1_2657) : !cute.int_tuple<"?">
          %1056 = cute.get_scalars(%e2_2658) : !cute.int_tuple<"?">
          %1057 = cute.get_scalars(%e3_2659) : !cute.int_tuple<"?{div=8}">
          %iter_2660 = cute.get_iter(%slice_2654) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2661, %e1_2662, %e2_2663, %e3_2664 = cute.get_leaves(%iter_2660) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1058 = cute.get_scalars(%e0_2661) : !cute.int_tuple<"?">
          %1059 = cute.get_scalars(%e1_2662) : !cute.int_tuple<"?">
          %1060 = cute.get_scalars(%e2_2663) : !cute.int_tuple<"?">
          %1061 = cute.get_scalars(%e3_2664) : !cute.int_tuple<"?{div=8}">
          %iter_2665 = cute.get_iter(%slice_2654) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2666, %e1_2667, %e2_2668, %e3_2669 = cute.get_leaves(%iter_2665) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1062 = cute.get_scalars(%e0_2666) : !cute.int_tuple<"?">
          %1063 = cute.get_scalars(%e1_2667) : !cute.int_tuple<"?">
          %1064 = cute.get_scalars(%e2_2668) : !cute.int_tuple<"?">
          %1065 = cute.get_scalars(%e3_2669) : !cute.int_tuple<"?{div=8}">
          %lay_2670 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1066 = cute.get_shape(%lay_2670) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2671, %e1_2672, %e2_2673, %e3_2674 = cute.get_leaves(%1066) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2675 = cute.to_int_tuple(%e0_2671) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1067 = cute.get_scalars(%itup_2675) : !cute.int_tuple<"?">
          %itup_2676 = cute.to_int_tuple(%e1_2672) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1068 = cute.get_scalars(%itup_2676) : !cute.int_tuple<"?">
          %itup_2677 = cute.to_int_tuple(%e2_2673) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1069 = cute.get_scalars(%itup_2677) : !cute.int_tuple<"?">
          %itup_2678 = cute.to_int_tuple(%e3_2674) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1070 = cute.get_scalars(%itup_2678) : !cute.int_tuple<"?{div=8}">
          %coord_2679 = cute.make_coord(%e1_2667) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2680 = cute.make_coord(%itup_2677) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1071 = cute.elem_less(%coord_2679, %coord_2680) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1071 {
            %int_tuple_2737 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2738 = cute.tuple_sub(%sub_1744, %int_tuple_2737) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1108 = cute.get_scalars(%sub_2738) : !cute.int_tuple<"?">
            %coord_2739 = cute.make_coord(%sub_2738) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %slice_2740 = cute.slice(%src_partitioned_302, %coord_2739) : !memref_gmem_bf16_7, !cute.coord<"(_,1,_,?)">
            %iter_2741 = cute.get_iter(%slice_2740) : !memref_gmem_bf16_11
            %coord_2742 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2743 = cute.slice(%dst_partitioned_305, %coord_2742) : !memref_smem_bf16_4, !cute.coord<"(_,1,_)">
            %iter_2744 = cute.get_iter(%slice_2743) : !memref_smem_bf16_15
            %lay_2745 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %1109 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1109) : !cute.shape<"((8,1),1)">
            %lay_2749 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %1110 = cute.get_shape(%lay_2749) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2750, %e1_2751, %e2_2752 = cute.get_leaves(%1110) : !cute.shape<"((8,1),1)">
            %lay_2753 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %shape_2754 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2755 = cute.make_layout(%shape_2754) : !cute.layout<"1:0">
            %append_2756 = cute.append_to_rank<2> (%lay_2753, %lay_2755) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2757 = cute.make_view(%iter_2741, %append_2756) : !memref_gmem_bf16_11
            %iter_2758 = cute.get_iter(%view_2757) : !memref_gmem_bf16_11
            %lay_2759 = cute.get_layout(%view_2757) : !memref_gmem_bf16_11
            %1111 = cute.get_shape(%lay_2759) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2760, %e1_2761, %e2_2762 = cute.get_leaves(%1111) : !cute.shape<"((8,1),1)">
            %grouped_2763 = cute.group_modes(%view_2757) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2764 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %iter_2765 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %lay_2766 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %shape_2767 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2768 = cute.make_layout(%shape_2767) : !cute.layout<"1:0">
            %append_2769 = cute.append_to_rank<2> (%lay_2766, %lay_2768) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2770 = cute.make_view(%iter_2744, %append_2769) : !memref_smem_bf16_15
            %iter_2771 = cute.get_iter(%view_2770) : !memref_smem_bf16_15
            %lay_2772 = cute.get_layout(%view_2770) : !memref_smem_bf16_15
            %1112 = cute.get_shape(%lay_2772) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2773, %e1_2774, %e2_2775 = cute.get_leaves(%1112) : !cute.shape<"((8,1),1)">
            %grouped_2776 = cute.group_modes(%view_2770) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2777 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %iter_2778 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %lay_2779 = cute.get_layout(%grouped_2763) : !memref_gmem_bf16_12
            %1113 = cute.get_shape(%lay_2779) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2780, %e1_2781, %e2_2782 = cute.get_leaves(%1113) : !cute.shape<"((8,1),(1))">
            %lay_2783 = cute.get_layout(%grouped_2776) : !memref_smem_bf16_16
            %1114 = cute.get_shape(%lay_2783) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2784, %e1_2785, %e2_2786 = cute.get_leaves(%1114) : !cute.shape<"((8,1),(1))">
            %sz_2787 = cute.size(%grouped_2763) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"1">
            %sz_2789 = cute.size(%grouped_2776) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2790 = cute.get_leaves(%sz_2789) : !cute.int_tuple<"1">
            cute.copy(%arg9, %grouped_2763, %grouped_2776) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2737 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
            %slice_2738 = cute.slice(%dst_partitioned_305, %coord_2737) : !memref_smem_bf16_4, !cute.coord<"(_,1,_)">
            %iter_2739 = cute.get_iter(%slice_2738) : !memref_smem_bf16_15
            %sz_2740 = cute.size(%slice_2738) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2741 = cute.get_leaves(%sz_2740) : !cute.int_tuple<"8">
            %lay_2742 = cute.get_layout(%slice_2738) : !memref_smem_bf16_15
            %1108 = cute.get_shape(%lay_2742) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2743, %e1_2744, %e2_2745 = cute.get_leaves(%1108) : !cute.shape<"((8,1),1)">
            %int_tuple_2746 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2747 = cute.tuple.product(%int_tuple_2746) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2748 = cute.get_leaves(%res_2747) : !cute.int_tuple<"8">
            %cst_2749 = arith.constant 0.000000e+00 : bf16
            %1109 = vector.splat %cst_2749 : vector<8xbf16>
            %int_tuple_2750 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2751 = cute.size(%int_tuple_2750) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2752 = cute.get_leaves(%sz_2751) : !cute.int_tuple<"8">
            %int_tuple_2753 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2754 = cute.size(%int_tuple_2753) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2755 = cute.get_leaves(%sz_2754) : !cute.int_tuple<"8">
            cute.memref.store_vec %1109, %slice_2738, row_major : !memref_smem_bf16_15
          }
          %coord_2681 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %slice_2682 = cute.slice(%src_partitioned_514, %coord_2681) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,2,0,?)">
          %iter_2683 = cute.get_iter(%slice_2682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2684, %e1_2685, %e2_2686, %e3_2687 = cute.get_leaves(%iter_2683) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1072 = cute.get_scalars(%e0_2684) : !cute.int_tuple<"?">
          %1073 = cute.get_scalars(%e1_2685) : !cute.int_tuple<"?">
          %1074 = cute.get_scalars(%e2_2686) : !cute.int_tuple<"?">
          %1075 = cute.get_scalars(%e3_2687) : !cute.int_tuple<"?{div=8}">
          %iter_2688 = cute.get_iter(%slice_2682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2689, %e1_2690, %e2_2691, %e3_2692 = cute.get_leaves(%iter_2688) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1076 = cute.get_scalars(%e0_2689) : !cute.int_tuple<"?">
          %1077 = cute.get_scalars(%e1_2690) : !cute.int_tuple<"?">
          %1078 = cute.get_scalars(%e2_2691) : !cute.int_tuple<"?">
          %1079 = cute.get_scalars(%e3_2692) : !cute.int_tuple<"?{div=8}">
          %iter_2693 = cute.get_iter(%slice_2682) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2694, %e1_2695, %e2_2696, %e3_2697 = cute.get_leaves(%iter_2693) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1080 = cute.get_scalars(%e0_2694) : !cute.int_tuple<"?">
          %1081 = cute.get_scalars(%e1_2695) : !cute.int_tuple<"?">
          %1082 = cute.get_scalars(%e2_2696) : !cute.int_tuple<"?">
          %1083 = cute.get_scalars(%e3_2697) : !cute.int_tuple<"?{div=8}">
          %lay_2698 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1084 = cute.get_shape(%lay_2698) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2699, %e1_2700, %e2_2701, %e3_2702 = cute.get_leaves(%1084) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2703 = cute.to_int_tuple(%e0_2699) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1085 = cute.get_scalars(%itup_2703) : !cute.int_tuple<"?">
          %itup_2704 = cute.to_int_tuple(%e1_2700) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1086 = cute.get_scalars(%itup_2704) : !cute.int_tuple<"?">
          %itup_2705 = cute.to_int_tuple(%e2_2701) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1087 = cute.get_scalars(%itup_2705) : !cute.int_tuple<"?">
          %itup_2706 = cute.to_int_tuple(%e3_2702) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1088 = cute.get_scalars(%itup_2706) : !cute.int_tuple<"?{div=8}">
          %coord_2707 = cute.make_coord(%e1_2695) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2708 = cute.make_coord(%itup_2705) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1089 = cute.elem_less(%coord_2707, %coord_2708) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1089 {
            %int_tuple_2737 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2738 = cute.tuple_sub(%sub_1744, %int_tuple_2737) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1108 = cute.get_scalars(%sub_2738) : !cute.int_tuple<"?">
            %coord_2739 = cute.make_coord(%sub_2738) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %slice_2740 = cute.slice(%src_partitioned_302, %coord_2739) : !memref_gmem_bf16_7, !cute.coord<"(_,2,_,?)">
            %iter_2741 = cute.get_iter(%slice_2740) : !memref_gmem_bf16_11
            %coord_2742 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2743 = cute.slice(%dst_partitioned_305, %coord_2742) : !memref_smem_bf16_4, !cute.coord<"(_,2,_)">
            %iter_2744 = cute.get_iter(%slice_2743) : !memref_smem_bf16_15
            %lay_2745 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %1109 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1109) : !cute.shape<"((8,1),1)">
            %lay_2749 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %1110 = cute.get_shape(%lay_2749) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2750, %e1_2751, %e2_2752 = cute.get_leaves(%1110) : !cute.shape<"((8,1),1)">
            %lay_2753 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %shape_2754 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2755 = cute.make_layout(%shape_2754) : !cute.layout<"1:0">
            %append_2756 = cute.append_to_rank<2> (%lay_2753, %lay_2755) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2757 = cute.make_view(%iter_2741, %append_2756) : !memref_gmem_bf16_11
            %iter_2758 = cute.get_iter(%view_2757) : !memref_gmem_bf16_11
            %lay_2759 = cute.get_layout(%view_2757) : !memref_gmem_bf16_11
            %1111 = cute.get_shape(%lay_2759) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2760, %e1_2761, %e2_2762 = cute.get_leaves(%1111) : !cute.shape<"((8,1),1)">
            %grouped_2763 = cute.group_modes(%view_2757) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2764 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %iter_2765 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %lay_2766 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %shape_2767 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2768 = cute.make_layout(%shape_2767) : !cute.layout<"1:0">
            %append_2769 = cute.append_to_rank<2> (%lay_2766, %lay_2768) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2770 = cute.make_view(%iter_2744, %append_2769) : !memref_smem_bf16_15
            %iter_2771 = cute.get_iter(%view_2770) : !memref_smem_bf16_15
            %lay_2772 = cute.get_layout(%view_2770) : !memref_smem_bf16_15
            %1112 = cute.get_shape(%lay_2772) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2773, %e1_2774, %e2_2775 = cute.get_leaves(%1112) : !cute.shape<"((8,1),1)">
            %grouped_2776 = cute.group_modes(%view_2770) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2777 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %iter_2778 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %lay_2779 = cute.get_layout(%grouped_2763) : !memref_gmem_bf16_12
            %1113 = cute.get_shape(%lay_2779) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2780, %e1_2781, %e2_2782 = cute.get_leaves(%1113) : !cute.shape<"((8,1),(1))">
            %lay_2783 = cute.get_layout(%grouped_2776) : !memref_smem_bf16_16
            %1114 = cute.get_shape(%lay_2783) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2784, %e1_2785, %e2_2786 = cute.get_leaves(%1114) : !cute.shape<"((8,1),(1))">
            %sz_2787 = cute.size(%grouped_2763) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"1">
            %sz_2789 = cute.size(%grouped_2776) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2790 = cute.get_leaves(%sz_2789) : !cute.int_tuple<"1">
            cute.copy(%arg9, %grouped_2763, %grouped_2776) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2737 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
            %slice_2738 = cute.slice(%dst_partitioned_305, %coord_2737) : !memref_smem_bf16_4, !cute.coord<"(_,2,_)">
            %iter_2739 = cute.get_iter(%slice_2738) : !memref_smem_bf16_15
            %sz_2740 = cute.size(%slice_2738) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2741 = cute.get_leaves(%sz_2740) : !cute.int_tuple<"8">
            %lay_2742 = cute.get_layout(%slice_2738) : !memref_smem_bf16_15
            %1108 = cute.get_shape(%lay_2742) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2743, %e1_2744, %e2_2745 = cute.get_leaves(%1108) : !cute.shape<"((8,1),1)">
            %int_tuple_2746 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2747 = cute.tuple.product(%int_tuple_2746) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2748 = cute.get_leaves(%res_2747) : !cute.int_tuple<"8">
            %cst_2749 = arith.constant 0.000000e+00 : bf16
            %1109 = vector.splat %cst_2749 : vector<8xbf16>
            %int_tuple_2750 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2751 = cute.size(%int_tuple_2750) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2752 = cute.get_leaves(%sz_2751) : !cute.int_tuple<"8">
            %int_tuple_2753 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2754 = cute.size(%int_tuple_2753) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2755 = cute.get_leaves(%sz_2754) : !cute.int_tuple<"8">
            cute.memref.store_vec %1109, %slice_2738, row_major : !memref_smem_bf16_15
          }
          %coord_2709 = cute.make_coord(%sub_237) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %slice_2710 = cute.slice(%src_partitioned_514, %coord_2709) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">, !cute.coord<"(0,3,0,?)">
          %iter_2711 = cute.get_iter(%slice_2710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2712, %e1_2713, %e2_2714, %e3_2715 = cute.get_leaves(%iter_2711) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1090 = cute.get_scalars(%e0_2712) : !cute.int_tuple<"?">
          %1091 = cute.get_scalars(%e1_2713) : !cute.int_tuple<"?">
          %1092 = cute.get_scalars(%e2_2714) : !cute.int_tuple<"?">
          %1093 = cute.get_scalars(%e3_2715) : !cute.int_tuple<"?{div=8}">
          %iter_2716 = cute.get_iter(%slice_2710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2717, %e1_2718, %e2_2719, %e3_2720 = cute.get_leaves(%iter_2716) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1094 = cute.get_scalars(%e0_2717) : !cute.int_tuple<"?">
          %1095 = cute.get_scalars(%e1_2718) : !cute.int_tuple<"?">
          %1096 = cute.get_scalars(%e2_2719) : !cute.int_tuple<"?">
          %1097 = cute.get_scalars(%e3_2720) : !cute.int_tuple<"?{div=8}">
          %iter_2721 = cute.get_iter(%slice_2710) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_2722, %e1_2723, %e2_2724, %e3_2725 = cute.get_leaves(%iter_2721) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %1098 = cute.get_scalars(%e0_2722) : !cute.int_tuple<"?">
          %1099 = cute.get_scalars(%e1_2723) : !cute.int_tuple<"?">
          %1100 = cute.get_scalars(%e2_2724) : !cute.int_tuple<"?">
          %1101 = cute.get_scalars(%e3_2725) : !cute.int_tuple<"?{div=8}">
          %lay_2726 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %1102 = cute.get_shape(%lay_2726) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_2727, %e1_2728, %e2_2729, %e3_2730 = cute.get_leaves(%1102) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_2731 = cute.to_int_tuple(%e0_2727) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1103 = cute.get_scalars(%itup_2731) : !cute.int_tuple<"?">
          %itup_2732 = cute.to_int_tuple(%e1_2728) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1104 = cute.get_scalars(%itup_2732) : !cute.int_tuple<"?">
          %itup_2733 = cute.to_int_tuple(%e2_2729) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %1105 = cute.get_scalars(%itup_2733) : !cute.int_tuple<"?">
          %itup_2734 = cute.to_int_tuple(%e3_2730) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
          %1106 = cute.get_scalars(%itup_2734) : !cute.int_tuple<"?{div=8}">
          %coord_2735 = cute.make_coord(%e1_2723) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2736 = cute.make_coord(%itup_2733) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1107 = cute.elem_less(%coord_2735, %coord_2736) : !cute.coord<"?">, !cute.coord<"?">
          scf.if %1107 {
            %int_tuple_2737 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %sub_2738 = cute.tuple_sub(%sub_1744, %int_tuple_2737) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %1108 = cute.get_scalars(%sub_2738) : !cute.int_tuple<"?">
            %coord_2739 = cute.make_coord(%sub_2738) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %slice_2740 = cute.slice(%src_partitioned_302, %coord_2739) : !memref_gmem_bf16_7, !cute.coord<"(_,3,_,?)">
            %iter_2741 = cute.get_iter(%slice_2740) : !memref_gmem_bf16_11
            %coord_2742 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2743 = cute.slice(%dst_partitioned_305, %coord_2742) : !memref_smem_bf16_4, !cute.coord<"(_,3,_)">
            %iter_2744 = cute.get_iter(%slice_2743) : !memref_smem_bf16_15
            %lay_2745 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %1109 = cute.get_shape(%lay_2745) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2746, %e1_2747, %e2_2748 = cute.get_leaves(%1109) : !cute.shape<"((8,1),1)">
            %lay_2749 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %1110 = cute.get_shape(%lay_2749) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2750, %e1_2751, %e2_2752 = cute.get_leaves(%1110) : !cute.shape<"((8,1),1)">
            %lay_2753 = cute.get_layout(%slice_2740) : !memref_gmem_bf16_11
            %shape_2754 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2755 = cute.make_layout(%shape_2754) : !cute.layout<"1:0">
            %append_2756 = cute.append_to_rank<2> (%lay_2753, %lay_2755) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2757 = cute.make_view(%iter_2741, %append_2756) : !memref_gmem_bf16_11
            %iter_2758 = cute.get_iter(%view_2757) : !memref_gmem_bf16_11
            %lay_2759 = cute.get_layout(%view_2757) : !memref_gmem_bf16_11
            %1111 = cute.get_shape(%lay_2759) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2760, %e1_2761, %e2_2762 = cute.get_leaves(%1111) : !cute.shape<"((8,1),1)">
            %grouped_2763 = cute.group_modes(%view_2757) <1, 2> : (!memref_gmem_bf16_11) -> !memref_gmem_bf16_12
            %iter_2764 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %iter_2765 = cute.get_iter(%grouped_2763) : !memref_gmem_bf16_12
            %lay_2766 = cute.get_layout(%slice_2743) : !memref_smem_bf16_15
            %shape_2767 = cute.make_shape() : () -> !cute.shape<"1">
            %lay_2768 = cute.make_layout(%shape_2767) : !cute.layout<"1:0">
            %append_2769 = cute.append_to_rank<2> (%lay_2766, %lay_2768) : !cute.layout<"((8,1),1):((1,0),0)">, !cute.layout<"1:0">
            %view_2770 = cute.make_view(%iter_2744, %append_2769) : !memref_smem_bf16_15
            %iter_2771 = cute.get_iter(%view_2770) : !memref_smem_bf16_15
            %lay_2772 = cute.get_layout(%view_2770) : !memref_smem_bf16_15
            %1112 = cute.get_shape(%lay_2772) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2773, %e1_2774, %e2_2775 = cute.get_leaves(%1112) : !cute.shape<"((8,1),1)">
            %grouped_2776 = cute.group_modes(%view_2770) <1, 2> : (!memref_smem_bf16_15) -> !memref_smem_bf16_16
            %iter_2777 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %iter_2778 = cute.get_iter(%grouped_2776) : !memref_smem_bf16_16
            %lay_2779 = cute.get_layout(%grouped_2763) : !memref_gmem_bf16_12
            %1113 = cute.get_shape(%lay_2779) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2780, %e1_2781, %e2_2782 = cute.get_leaves(%1113) : !cute.shape<"((8,1),(1))">
            %lay_2783 = cute.get_layout(%grouped_2776) : !memref_smem_bf16_16
            %1114 = cute.get_shape(%lay_2783) : (!cute.layout<"((8,1),(1)):((1,0),(0))">) -> !cute.shape<"((8,1),(1))">
            %e0_2784, %e1_2785, %e2_2786 = cute.get_leaves(%1114) : !cute.shape<"((8,1),(1))">
            %sz_2787 = cute.size(%grouped_2763) <{mode = [1]}> : (!memref_gmem_bf16_12) -> !cute.int_tuple<"1">
            %e0_2788 = cute.get_leaves(%sz_2787) : !cute.int_tuple<"1">
            %sz_2789 = cute.size(%grouped_2776) <{mode = [1]}> : (!memref_smem_bf16_16) -> !cute.int_tuple<"1">
            %e0_2790 = cute.get_leaves(%sz_2789) : !cute.int_tuple<"1">
            cute.copy(%arg9, %grouped_2763, %grouped_2776) : (!copy_ldgsts, !memref_gmem_bf16_12, !memref_smem_bf16_16)
          } else {
            %coord_2737 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
            %slice_2738 = cute.slice(%dst_partitioned_305, %coord_2737) : !memref_smem_bf16_4, !cute.coord<"(_,3,_)">
            %iter_2739 = cute.get_iter(%slice_2738) : !memref_smem_bf16_15
            %sz_2740 = cute.size(%slice_2738) : (!memref_smem_bf16_15) -> !cute.int_tuple<"8">
            %e0_2741 = cute.get_leaves(%sz_2740) : !cute.int_tuple<"8">
            %lay_2742 = cute.get_layout(%slice_2738) : !memref_smem_bf16_15
            %1108 = cute.get_shape(%lay_2742) : (!cute.layout<"((8,1),1):((1,0),0)">) -> !cute.shape<"((8,1),1)">
            %e0_2743, %e1_2744, %e2_2745 = cute.get_leaves(%1108) : !cute.shape<"((8,1),1)">
            %int_tuple_2746 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %res_2747 = cute.tuple.product(%int_tuple_2746) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2748 = cute.get_leaves(%res_2747) : !cute.int_tuple<"8">
            %cst_2749 = arith.constant 0.000000e+00 : bf16
            %1109 = vector.splat %cst_2749 : vector<8xbf16>
            %int_tuple_2750 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2751 = cute.size(%int_tuple_2750) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2752 = cute.get_leaves(%sz_2751) : !cute.int_tuple<"8">
            %int_tuple_2753 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,1),1)">
            %sz_2754 = cute.size(%int_tuple_2753) : (!cute.int_tuple<"((8,1),1)">) -> !cute.int_tuple<"8">
            %e0_2755 = cute.get_leaves(%sz_2754) : !cute.int_tuple<"8">
            cute.memref.store_vec %1109, %slice_2738, row_major : !memref_smem_bf16_15
          }
          nvvm.cp.async.commit.group
        }
        %lay_2118 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
        %911 = cute.get_shape(%lay_2118) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2119, %e1_2120, %e2_2121, %e3_2122 = cute.get_leaves(%911) : !cute.shape<"((2,2),1,8)">
        %912 = cute.get_stride(%lay_2118) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2123, %e1_2124, %e2_2125, %e3_2126 = cute.get_leaves(%912) : !cute.stride<"((1,2),0,4)">
        %913 = scf.if %true -> (!memref_rmem_f32_1) {
          %iter_2539 = cute.get_iter(%rmem_1754) : !memref_rmem_f32_1
          %lay_2540 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
          %1026 = cute.get_shape(%lay_2540) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2541, %e1_2542, %e2_2543, %e3_2544 = cute.get_leaves(%1026) : !cute.shape<"((2,2),1,8)">
          %1027 = cute.memref.load_vec %rmem_1754, row_major : !memref_rmem_f32_1
          %cst_2545 = arith.constant 5.000000e-01 : f32
          %1028 = vector.broadcast %cst_2545 : f32 to vector<32xf32>
          %1029 = arith.mulf %1027, %1028 : vector<32xf32>
          %int_tuple_2546 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2547 = cute.size(%int_tuple_2546) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2548 = cute.get_leaves(%sz_2547) : !cute.int_tuple<"32">
          %int_tuple_2549 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2550 = cute.size(%int_tuple_2549) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2551 = cute.get_leaves(%sz_2550) : !cute.int_tuple<"32">
          cute.memref.store_vec %1029, %rmem_1754, row_major : !memref_rmem_f32_1
          %int_tuple_2552 = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,2)">
          %sz_2553 = cute.size(%int_tuple_2552) : (!cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"4">
          %e0_2554 = cute.get_leaves(%sz_2553) : !cute.int_tuple<"4">
          %int_tuple_2555 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2556 = cute.size(%int_tuple_2555) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2557 = cute.get_leaves(%sz_2556) : !cute.int_tuple<"1">
          %int_tuple_2558 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2559 = cute.size(%int_tuple_2558) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2560 = cute.get_leaves(%sz_2559) : !cute.int_tuple<"8">
          %coord_2561 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %1030 = cute.memref.load(%rmem_1754, %coord_2561) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
          %1031 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1030 : (f32) -> f32
          %coord_2562 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          cute.memref.store(%rmem_1754, %coord_2562, %1031) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
          %coord_2563 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %1032 = cute.memref.load(%rmem_1754, %coord_2563) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
          %1033 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1032 : (f32) -> f32
          %coord_2564 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          cute.memref.store(%rmem_1754, %coord_2564, %1033) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
          %coord_2565 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %1034 = cute.memref.load(%rmem_1754, %coord_2565) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
          %1035 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1034 : (f32) -> f32
          %coord_2566 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          cute.memref.store(%rmem_1754, %coord_2566, %1035) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
          %coord_2567 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %1036 = cute.memref.load(%rmem_1754, %coord_2567) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
          %1037 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1036 : (f32) -> f32
          %coord_2568 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          cute.memref.store(%rmem_1754, %coord_2568, %1037) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
          %coord_2569 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %1038 = cute.memref.load(%rmem_1754, %coord_2569) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
          %1039 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1038 : (f32) -> f32
          %coord_2570 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          cute.memref.store(%rmem_1754, %coord_2570, %1039) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
          %coord_2571 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %1040 = cute.memref.load(%rmem_1754, %coord_2571) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
          %1041 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1040 : (f32) -> f32
          %coord_2572 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          cute.memref.store(%rmem_1754, %coord_2572, %1041) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
          %coord_2573 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %1042 = cute.memref.load(%rmem_1754, %coord_2573) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
          %1043 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1042 : (f32) -> f32
          %coord_2574 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          cute.memref.store(%rmem_1754, %coord_2574, %1043) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
          %coord_2575 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %1044 = cute.memref.load(%rmem_1754, %coord_2575) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
          %1045 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1044 : (f32) -> f32
          %coord_2576 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          cute.memref.store(%rmem_1754, %coord_2576, %1045) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
          %int_tuple_2577 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2578 = cute.size(%int_tuple_2577) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2579 = cute.get_leaves(%sz_2578) : !cute.int_tuple<"1">
          %int_tuple_2580 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2581 = cute.size(%int_tuple_2580) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2582 = cute.get_leaves(%sz_2581) : !cute.int_tuple<"8">
          %coord_2583 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %1046 = cute.memref.load(%rmem_1754, %coord_2583) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
          %1047 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1046 : (f32) -> f32
          %coord_2584 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          cute.memref.store(%rmem_1754, %coord_2584, %1047) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
          %coord_2585 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %1048 = cute.memref.load(%rmem_1754, %coord_2585) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
          %1049 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1048 : (f32) -> f32
          %coord_2586 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          cute.memref.store(%rmem_1754, %coord_2586, %1049) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
          %coord_2587 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %1050 = cute.memref.load(%rmem_1754, %coord_2587) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
          %1051 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1050 : (f32) -> f32
          %coord_2588 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          cute.memref.store(%rmem_1754, %coord_2588, %1051) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
          %coord_2589 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %1052 = cute.memref.load(%rmem_1754, %coord_2589) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
          %1053 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1052 : (f32) -> f32
          %coord_2590 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          cute.memref.store(%rmem_1754, %coord_2590, %1053) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
          %coord_2591 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %1054 = cute.memref.load(%rmem_1754, %coord_2591) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
          %1055 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1054 : (f32) -> f32
          %coord_2592 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          cute.memref.store(%rmem_1754, %coord_2592, %1055) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
          %coord_2593 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %1056 = cute.memref.load(%rmem_1754, %coord_2593) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
          %1057 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1056 : (f32) -> f32
          %coord_2594 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          cute.memref.store(%rmem_1754, %coord_2594, %1057) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
          %coord_2595 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %1058 = cute.memref.load(%rmem_1754, %coord_2595) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
          %1059 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1058 : (f32) -> f32
          %coord_2596 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          cute.memref.store(%rmem_1754, %coord_2596, %1059) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
          %coord_2597 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %1060 = cute.memref.load(%rmem_1754, %coord_2597) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
          %1061 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1060 : (f32) -> f32
          %coord_2598 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          cute.memref.store(%rmem_1754, %coord_2598, %1061) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
          %int_tuple_2599 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2600 = cute.size(%int_tuple_2599) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2601 = cute.get_leaves(%sz_2600) : !cute.int_tuple<"1">
          %int_tuple_2602 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2603 = cute.size(%int_tuple_2602) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2604 = cute.get_leaves(%sz_2603) : !cute.int_tuple<"8">
          %coord_2605 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %1062 = cute.memref.load(%rmem_1754, %coord_2605) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
          %1063 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1062 : (f32) -> f32
          %coord_2606 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          cute.memref.store(%rmem_1754, %coord_2606, %1063) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
          %coord_2607 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %1064 = cute.memref.load(%rmem_1754, %coord_2607) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
          %1065 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1064 : (f32) -> f32
          %coord_2608 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          cute.memref.store(%rmem_1754, %coord_2608, %1065) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
          %coord_2609 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %1066 = cute.memref.load(%rmem_1754, %coord_2609) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
          %1067 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1066 : (f32) -> f32
          %coord_2610 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          cute.memref.store(%rmem_1754, %coord_2610, %1067) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
          %coord_2611 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %1068 = cute.memref.load(%rmem_1754, %coord_2611) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
          %1069 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1068 : (f32) -> f32
          %coord_2612 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          cute.memref.store(%rmem_1754, %coord_2612, %1069) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
          %coord_2613 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %1070 = cute.memref.load(%rmem_1754, %coord_2613) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
          %1071 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1070 : (f32) -> f32
          %coord_2614 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          cute.memref.store(%rmem_1754, %coord_2614, %1071) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
          %coord_2615 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %1072 = cute.memref.load(%rmem_1754, %coord_2615) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
          %1073 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1072 : (f32) -> f32
          %coord_2616 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          cute.memref.store(%rmem_1754, %coord_2616, %1073) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
          %coord_2617 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %1074 = cute.memref.load(%rmem_1754, %coord_2617) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
          %1075 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1074 : (f32) -> f32
          %coord_2618 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          cute.memref.store(%rmem_1754, %coord_2618, %1075) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
          %coord_2619 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %1076 = cute.memref.load(%rmem_1754, %coord_2619) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
          %1077 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1076 : (f32) -> f32
          %coord_2620 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          cute.memref.store(%rmem_1754, %coord_2620, %1077) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
          %int_tuple_2621 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2622 = cute.size(%int_tuple_2621) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2623 = cute.get_leaves(%sz_2622) : !cute.int_tuple<"1">
          %int_tuple_2624 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2625 = cute.size(%int_tuple_2624) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2626 = cute.get_leaves(%sz_2625) : !cute.int_tuple<"8">
          %coord_2627 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %1078 = cute.memref.load(%rmem_1754, %coord_2627) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
          %1079 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1078 : (f32) -> f32
          %coord_2628 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          cute.memref.store(%rmem_1754, %coord_2628, %1079) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
          %coord_2629 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %1080 = cute.memref.load(%rmem_1754, %coord_2629) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
          %1081 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1080 : (f32) -> f32
          %coord_2630 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          cute.memref.store(%rmem_1754, %coord_2630, %1081) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
          %coord_2631 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %1082 = cute.memref.load(%rmem_1754, %coord_2631) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
          %1083 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1082 : (f32) -> f32
          %coord_2632 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          cute.memref.store(%rmem_1754, %coord_2632, %1083) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
          %coord_2633 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %1084 = cute.memref.load(%rmem_1754, %coord_2633) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
          %1085 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1084 : (f32) -> f32
          %coord_2634 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          cute.memref.store(%rmem_1754, %coord_2634, %1085) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
          %coord_2635 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %1086 = cute.memref.load(%rmem_1754, %coord_2635) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
          %1087 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1086 : (f32) -> f32
          %coord_2636 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          cute.memref.store(%rmem_1754, %coord_2636, %1087) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
          %coord_2637 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %1088 = cute.memref.load(%rmem_1754, %coord_2637) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
          %1089 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1088 : (f32) -> f32
          %coord_2638 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          cute.memref.store(%rmem_1754, %coord_2638, %1089) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
          %coord_2639 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %1090 = cute.memref.load(%rmem_1754, %coord_2639) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
          %1091 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1090 : (f32) -> f32
          %coord_2640 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          cute.memref.store(%rmem_1754, %coord_2640, %1091) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
          %coord_2641 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %1092 = cute.memref.load(%rmem_1754, %coord_2641) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
          %1093 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1092 : (f32) -> f32
          %coord_2642 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          cute.memref.store(%rmem_1754, %coord_2642, %1093) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
          %1094 = cute.memref.load_vec %rmem_1754, row_major : !memref_rmem_f32_1
          %1095 = arith.mulf %1029, %1094 : vector<32xf32>
          %1096 = arith.addf %1095, %1029 : vector<32xf32>
          %int_tuple_2643 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2644 = cute.size(%int_tuple_2643) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2645 = cute.get_leaves(%sz_2644) : !cute.int_tuple<"32">
          %int_tuple_2646 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2647 = cute.size(%int_tuple_2646) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2648 = cute.get_leaves(%sz_2647) : !cute.int_tuple<"32">
          cute.memref.store_vec %1096, %rmem_1754, row_major : !memref_rmem_f32_1
          %lay_2649 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
          %1097 = cute.get_shape(%lay_2649) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2650, %e1_2651, %e2_2652, %e3_2653 = cute.get_leaves(%1097) : !cute.shape<"((2,2),1,8)">
          %1098 = cute.get_stride(%lay_2649) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2654, %e1_2655, %e2_2656, %e3_2657 = cute.get_leaves(%1098) : !cute.stride<"((1,2),0,4)">
          scf.yield %rmem_1754 : !memref_rmem_f32_1
        } else {
          %iter_2539 = cute.get_iter(%rmem_1754) : !memref_rmem_f32_1
          %lay_2540 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
          %1026 = cute.get_shape(%lay_2540) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2541, %e1_2542, %e2_2543, %e3_2544 = cute.get_leaves(%1026) : !cute.shape<"((2,2),1,8)">
          %1027 = cute.memref.load_vec %rmem_1754, row_major : !memref_rmem_f32_1
          %cst_2545 = arith.constant -1.44269502 : f32
          %1028 = vector.broadcast %cst_2545 : f32 to vector<32xf32>
          %1029 = arith.mulf %1027, %1028 : vector<32xf32>
          %1030 = math.exp2 %1029 fastmath<fast> : vector<32xf32>
          %cst_2546 = arith.constant 1.000000e+00 : f32
          %1031 = vector.broadcast %cst_2546 : f32 to vector<32xf32>
          %1032 = arith.addf %1030, %1031 : vector<32xf32>
          %1033 = arith.divf %1027, %1032 : vector<32xf32>
          %int_tuple_2547 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2548 = cute.size(%int_tuple_2547) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2549 = cute.get_leaves(%sz_2548) : !cute.int_tuple<"32">
          %int_tuple_2550 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
          %sz_2551 = cute.size(%int_tuple_2550) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
          %e0_2552 = cute.get_leaves(%sz_2551) : !cute.int_tuple<"32">
          cute.memref.store_vec %1033, %rmem_1754, row_major : !memref_rmem_f32_1
          %lay_2553 = cute.get_layout(%rmem_1754) : !memref_rmem_f32_1
          %1034 = cute.get_shape(%lay_2553) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2554, %e1_2555, %e2_2556, %e3_2557 = cute.get_leaves(%1034) : !cute.shape<"((2,2),1,8)">
          %1035 = cute.get_stride(%lay_2553) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2558, %e1_2559, %e2_2560, %e3_2561 = cute.get_leaves(%1035) : !cute.stride<"((1,2),0,4)">
          scf.yield %rmem_1754 : !memref_rmem_f32_1
        }
        %iter_2127 = cute.get_iter(%913) : !memref_rmem_f32_1
        %lay_2128 = cute.get_layout(%913) : !memref_rmem_f32_1
        %914 = cute.get_shape(%lay_2128) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2129, %e1_2130, %e2_2131, %e3_2132 = cute.get_leaves(%914) : !cute.shape<"((2,2),1,8)">
        %915 = cute.get_stride(%lay_2128) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2133, %e1_2134, %e2_2135, %e3_2136 = cute.get_leaves(%915) : !cute.stride<"((1,2),0,4)">
        %iter_2137 = cute.get_iter(%913) : !memref_rmem_f32_1
        %iter_2138 = cute.get_iter(%913) : !memref_rmem_f32_1
        %lay_2139 = cute.get_layout(%arg4) : !memref_gmem_bf16_
        %916 = cute.get_shape(%lay_2139) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2140, %e1_2141, %e2_2142, %e3_2143 = cute.get_leaves(%916) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2144 = cute.to_int_tuple(%e0_2140) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %917 = cute.get_scalars(%itup_2144) : !cute.int_tuple<"?">
        %itup_2145 = cute.to_int_tuple(%e1_2141) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %918 = cute.get_scalars(%itup_2145) : !cute.int_tuple<"?">
        %itup_2146 = cute.to_int_tuple(%e2_2142) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %919 = cute.get_scalars(%itup_2146) : !cute.int_tuple<"?">
        %itup_2147 = cute.to_int_tuple(%e3_2143) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
        %920 = cute.get_scalars(%itup_2147) : !cute.int_tuple<"?{div=8}">
        %lay_2148 = cute.get_layout(%arg4) : !memref_gmem_bf16_
        %921 = cute.get_shape(%lay_2148) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2149, %e1_2150, %e2_2151, %e3_2152 = cute.get_leaves(%921) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2153 = cute.to_int_tuple(%e0_2149) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %922 = cute.get_scalars(%itup_2153) : !cute.int_tuple<"?">
        %itup_2154 = cute.to_int_tuple(%e1_2150) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %923 = cute.get_scalars(%itup_2154) : !cute.int_tuple<"?">
        %itup_2155 = cute.to_int_tuple(%e2_2151) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %924 = cute.get_scalars(%itup_2155) : !cute.int_tuple<"?">
        %itup_2156 = cute.to_int_tuple(%e3_2152) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
        %925 = cute.get_scalars(%itup_2156) : !cute.int_tuple<"?{div=8}">
        %shape_2157 = cute.make_shape(%itup_2146, %itup_2156) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?{div=8})">
        %926 = cute.make_identity_tensor(%shape_2157) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %iter_2158 = cute.get_iter(%926) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %e0_2159, %e1_2160 = cute.get_leaves(%iter_2158) : !cute.int_tuple<"(0,0)">
        %coord_2161 = cute.make_coord() : () -> !cute.coord<"(_,_)">
        %slice_2162 = cute.slice(%926, %coord_2161) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">, !cute.coord<"(_,_)">
        %iter_2163 = cute.get_iter(%slice_2162) : !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %e0_2164, %e1_2165 = cute.get_leaves(%iter_2163) : !cute.int_tuple<"(0,0)">
        %tile_2166 = cute.make_tile() : () -> !cute.tile<"[64:1;64:1]">
        %coord_2167 = cute.make_coord(%sub_222, %sub_1744) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %tiled_view_2168 = cute.local_tile(%slice_2162, %tile_2166, %coord_2167) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">, !cute.tile<"[64:1;64:1]">, !cute.coord<"(?,?)">) -> !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">
        %iter_2169 = cute.get_iter(%tiled_view_2168) : !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">
        %e0_2170, %e1_2171 = cute.get_leaves(%iter_2169) : !cute.int_tuple<"(?{div=64},?{div=64})">
        %927 = cute.get_scalars(%e0_2170) : !cute.int_tuple<"?{div=64}">
        %928 = cute.get_scalars(%e1_2171) : !cute.int_tuple<"?{div=64}">
        %lay_2172 = cute.get_layout(%913) : !memref_rmem_f32_1
        %929 = cute.get_shape(%lay_2172) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2173, %e1_2174, %e2_2175, %e3_2176 = cute.get_leaves(%929) : !cute.shape<"((2,2),1,8)">
        %930 = cute.get_stride(%lay_2172) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2177, %e1_2178, %e2_2179, %e3_2180 = cute.get_leaves(%930) : !cute.stride<"((1,2),0,4)">
        %931 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
        %932 = cute.get_shape(%931) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
        %e0_2181, %e1_2182, %e2_2183, %e3_2184 = cute.get_leaves(%932) : !cute.shape<"(32,4,1,1)">
        %933 = cute.get_stride(%931) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
        %e0_2185, %e1_2186, %e2_2187, %e3_2188 = cute.get_leaves(%933) : !cute.stride<"(1,32,0,0)">
        %934 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
        %e0_2189, %e1_2190, %e2_2191 = cute.get_leaves(%934) : !cute.tile<"[64:1;16:1;16:1]">
        %935 = cute.get_shape(%e0_2189) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2192 = cute.get_leaves(%935) : !cute.shape<"64">
        %936 = cute.get_stride(%e0_2189) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2193 = cute.get_leaves(%936) : !cute.stride<"1">
        %937 = cute.get_shape(%e1_2190) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2194 = cute.get_leaves(%937) : !cute.shape<"16">
        %938 = cute.get_stride(%e1_2190) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2195 = cute.get_leaves(%938) : !cute.stride<"1">
        %939 = cute.get_shape(%e2_2191) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2196 = cute.get_leaves(%939) : !cute.shape<"16">
        %940 = cute.get_stride(%e2_2191) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2197 = cute.get_leaves(%940) : !cute.stride<"1">
        %941 = cute.static : !cute.layout<"32:1">
        %942 = cute.get_shape(%941) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2198 = cute.get_leaves(%942) : !cute.shape<"32">
        %943 = cute.get_stride(%941) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2199 = cute.get_leaves(%943) : !cute.stride<"1">
        %944 = cute.static : !cute.shape<"(16,8,16)">
        %e0_2200, %e1_2201, %e2_2202 = cute.get_leaves(%944) : !cute.shape<"(16,8,16)">
        %945 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
        %946 = cute.get_shape(%945) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
        %e0_2203, %e1_2204, %e2_2205, %e3_2206, %e4_2207 = cute.get_leaves(%946) : !cute.shape<"((4,8),(2,2,2))">
        %947 = cute.get_stride(%945) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
        %e0_2208, %e1_2209, %e2_2210, %e3_2211, %e4_2212 = cute.get_leaves(%947) : !cute.stride<"((32,1),(16,8,128))">
        %948 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
        %949 = cute.get_shape(%948) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2213, %e1_2214, %e2_2215, %e3_2216 = cute.get_leaves(%949) : !cute.shape<"((4,8),(2,2))">
        %950 = cute.get_stride(%948) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
        %e0_2217, %e1_2218, %e2_2219, %e3_2220 = cute.get_leaves(%950) : !cute.stride<"((16,1),(8,64))">
        %951 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
        %952 = cute.get_shape(%951) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2221, %e1_2222, %e2_2223, %e3_2224 = cute.get_leaves(%952) : !cute.shape<"((4,8),(2,2))">
        %953 = cute.get_stride(%951) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
        %e0_2225, %e1_2226, %e2_2227, %e3_2228 = cute.get_leaves(%953) : !cute.stride<"((32,1),(16,8))">
        %954:2 = scf.if %false -> (!memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_) {
          %iter_2539 = cute.get_iter(%913) : !memref_rmem_f32_1
          %coord_2540 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
          %ptn_C = cute.tiled.mma.partition C (%arg13, %tiled_view_2168, %coord_2540) : (!mma_bf16_bf16_f32_16x8x16_, !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %iter_2541 = cute.get_iter(%ptn_C) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %e0_2542, %e1_2543 = cute.get_leaves(%iter_2541) : !cute.int_tuple<"(?,?{div=2})">
          %1026 = cute.get_scalars(%e0_2542) : !cute.int_tuple<"?">
          %1027 = cute.get_scalars(%e1_2543) : !cute.int_tuple<"?{div=2}">
          %lay_2544 = cute.get_layout(%ptn_C) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %1028 = cute.get_shape(%lay_2544) : (!cute.layout<"((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2545, %e1_2546, %e2_2547, %e3_2548 = cute.get_leaves(%1028) : !cute.shape<"((2,2),1,8)">
          %int_tuple_2549 = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,2)">
          %sz_2550 = cute.size(%int_tuple_2549) : (!cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"4">
          %e0_2551 = cute.get_leaves(%sz_2550) : !cute.int_tuple<"4">
          %int_tuple_2552 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2553 = cute.size(%int_tuple_2552) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2554 = cute.get_leaves(%sz_2553) : !cute.int_tuple<"1">
          %int_tuple_2555 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2556 = cute.size(%int_tuple_2555) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2557 = cute.get_leaves(%sz_2556) : !cute.int_tuple<"8">
          %coord_2558 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2559 = cute.slice(%ptn_C, %coord_2558) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,0)">
          %iter_2560 = cute.get_iter(%slice_2559) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2561, %e1_2562 = cute.get_leaves(%iter_2560) : !cute.int_tuple<"(?,?{div=2})">
          %1029 = cute.get_scalars(%e0_2561) : !cute.int_tuple<"?">
          %1030 = cute.get_scalars(%e1_2562) : !cute.int_tuple<"?{div=2}">
          %iter_2563 = cute.get_iter(%slice_2559) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2564, %e1_2565 = cute.get_leaves(%iter_2563) : !cute.int_tuple<"(?,?{div=2})">
          %1031 = cute.get_scalars(%e0_2564) : !cute.int_tuple<"?">
          %1032 = cute.get_scalars(%e1_2565) : !cute.int_tuple<"?{div=2}">
          %iter_2566 = cute.get_iter(%slice_2559) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2567, %e1_2568 = cute.get_leaves(%iter_2566) : !cute.int_tuple<"(?,?{div=2})">
          %1033 = cute.get_scalars(%e0_2567) : !cute.int_tuple<"?">
          %1034 = cute.get_scalars(%e1_2568) : !cute.int_tuple<"?{div=2}">
          %coord_2569 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
          %slice_2570 = cute.slice(%ptn_C, %coord_2569) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,0)">
          %iter_2571 = cute.get_iter(%slice_2570) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2572, %e1_2573 = cute.get_leaves(%iter_2571) : !cute.int_tuple<"(?,?{div=2})">
          %1035 = cute.get_scalars(%e0_2572) : !cute.int_tuple<"?">
          %1036 = cute.get_scalars(%e1_2573) : !cute.int_tuple<"?{div=2}">
          %iter_2574 = cute.get_iter(%slice_2570) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2575, %e1_2576 = cute.get_leaves(%iter_2574) : !cute.int_tuple<"(?,?{div=2})">
          %1037 = cute.get_scalars(%e0_2575) : !cute.int_tuple<"?">
          %1038 = cute.get_scalars(%e1_2576) : !cute.int_tuple<"?{div=2}">
          %iter_2577 = cute.get_iter(%slice_2570) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2578, %e1_2579 = cute.get_leaves(%iter_2577) : !cute.int_tuple<"(?,?{div=2})">
          %1039 = cute.get_scalars(%e0_2578) : !cute.int_tuple<"?">
          %1040 = cute.get_scalars(%e1_2579) : !cute.int_tuple<"?{div=2}">
          %coord_2580 = cute.make_coord(%e0_2567) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2581 = cute.make_coord(%e1_2579) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1041 = cute.elem_less(%coord_2580, %coord_2581) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2582 = cute.get_layout(%913) : !memref_rmem_f32_1
          %1042 = cute.get_shape(%lay_2582) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2583, %e1_2584, %e2_2585, %e3_2586 = cute.get_leaves(%1042) : !cute.shape<"((2,2),1,8)">
          %1043 = cute.get_stride(%lay_2582) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2587, %e1_2588, %e2_2589, %e3_2590 = cute.get_leaves(%1043) : !cute.stride<"((1,2),0,4)">
          %1044 = scf.if %1041 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%913) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
            cute.memref.store(%913, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
            %lay_4076 = cute.get_layout(%913) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %913 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%913) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%913) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %913 : !memref_rmem_f32_1
          }
          %iter_2591 = cute.get_iter(%1044) : !memref_rmem_f32_1
          %lay_2592 = cute.get_layout(%1044) : !memref_rmem_f32_1
          %1045 = cute.get_shape(%lay_2592) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2593, %e1_2594, %e2_2595, %e3_2596 = cute.get_leaves(%1045) : !cute.shape<"((2,2),1,8)">
          %1046 = cute.get_stride(%lay_2592) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2597, %e1_2598, %e2_2599, %e3_2600 = cute.get_leaves(%1046) : !cute.stride<"((1,2),0,4)">
          %iter_2601 = cute.get_iter(%1044) : !memref_rmem_f32_1
          %iter_2602 = cute.get_iter(%1044) : !memref_rmem_f32_1
          %coord_2603 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %slice_2604 = cute.slice(%ptn_C, %coord_2603) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,1)">
          %iter_2605 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2606, %e1_2607 = cute.get_leaves(%iter_2605) : !cute.int_tuple<"(?,?{div=2})">
          %1047 = cute.get_scalars(%e0_2606) : !cute.int_tuple<"?">
          %1048 = cute.get_scalars(%e1_2607) : !cute.int_tuple<"?{div=2}">
          %iter_2608 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2609, %e1_2610 = cute.get_leaves(%iter_2608) : !cute.int_tuple<"(?,?{div=2})">
          %1049 = cute.get_scalars(%e0_2609) : !cute.int_tuple<"?">
          %1050 = cute.get_scalars(%e1_2610) : !cute.int_tuple<"?{div=2}">
          %iter_2611 = cute.get_iter(%slice_2604) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2612, %e1_2613 = cute.get_leaves(%iter_2611) : !cute.int_tuple<"(?,?{div=2})">
          %1051 = cute.get_scalars(%e0_2612) : !cute.int_tuple<"?">
          %1052 = cute.get_scalars(%e1_2613) : !cute.int_tuple<"?{div=2}">
          %coord_2614 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
          %slice_2615 = cute.slice(%ptn_C, %coord_2614) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,1)">
          %iter_2616 = cute.get_iter(%slice_2615) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2617, %e1_2618 = cute.get_leaves(%iter_2616) : !cute.int_tuple<"(?,?{div=2})">
          %1053 = cute.get_scalars(%e0_2617) : !cute.int_tuple<"?">
          %1054 = cute.get_scalars(%e1_2618) : !cute.int_tuple<"?{div=2}">
          %iter_2619 = cute.get_iter(%slice_2615) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2620, %e1_2621 = cute.get_leaves(%iter_2619) : !cute.int_tuple<"(?,?{div=2})">
          %1055 = cute.get_scalars(%e0_2620) : !cute.int_tuple<"?">
          %1056 = cute.get_scalars(%e1_2621) : !cute.int_tuple<"?{div=2}">
          %iter_2622 = cute.get_iter(%slice_2615) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2623, %e1_2624 = cute.get_leaves(%iter_2622) : !cute.int_tuple<"(?,?{div=2})">
          %1057 = cute.get_scalars(%e0_2623) : !cute.int_tuple<"?">
          %1058 = cute.get_scalars(%e1_2624) : !cute.int_tuple<"?{div=2}">
          %coord_2625 = cute.make_coord(%e0_2612) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2626 = cute.make_coord(%e1_2624) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1059 = cute.elem_less(%coord_2625, %coord_2626) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2627 = cute.get_layout(%1044) : !memref_rmem_f32_1
          %1060 = cute.get_shape(%lay_2627) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2628, %e1_2629, %e2_2630, %e3_2631 = cute.get_leaves(%1060) : !cute.shape<"((2,2),1,8)">
          %1061 = cute.get_stride(%lay_2627) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2632, %e1_2633, %e2_2634, %e3_2635 = cute.get_leaves(%1061) : !cute.stride<"((1,2),0,4)">
          %1062 = scf.if %1059 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1044) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
            cute.memref.store(%1044, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1044) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1044 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1044) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1044) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1044 : !memref_rmem_f32_1
          }
          %iter_2636 = cute.get_iter(%1062) : !memref_rmem_f32_1
          %lay_2637 = cute.get_layout(%1062) : !memref_rmem_f32_1
          %1063 = cute.get_shape(%lay_2637) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2638, %e1_2639, %e2_2640, %e3_2641 = cute.get_leaves(%1063) : !cute.shape<"((2,2),1,8)">
          %1064 = cute.get_stride(%lay_2637) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2642, %e1_2643, %e2_2644, %e3_2645 = cute.get_leaves(%1064) : !cute.stride<"((1,2),0,4)">
          %iter_2646 = cute.get_iter(%1062) : !memref_rmem_f32_1
          %iter_2647 = cute.get_iter(%1062) : !memref_rmem_f32_1
          %coord_2648 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %slice_2649 = cute.slice(%ptn_C, %coord_2648) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,2)">
          %iter_2650 = cute.get_iter(%slice_2649) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2651, %e1_2652 = cute.get_leaves(%iter_2650) : !cute.int_tuple<"(?,?{div=2})">
          %1065 = cute.get_scalars(%e0_2651) : !cute.int_tuple<"?">
          %1066 = cute.get_scalars(%e1_2652) : !cute.int_tuple<"?{div=2}">
          %iter_2653 = cute.get_iter(%slice_2649) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2654, %e1_2655 = cute.get_leaves(%iter_2653) : !cute.int_tuple<"(?,?{div=2})">
          %1067 = cute.get_scalars(%e0_2654) : !cute.int_tuple<"?">
          %1068 = cute.get_scalars(%e1_2655) : !cute.int_tuple<"?{div=2}">
          %iter_2656 = cute.get_iter(%slice_2649) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2657, %e1_2658 = cute.get_leaves(%iter_2656) : !cute.int_tuple<"(?,?{div=2})">
          %1069 = cute.get_scalars(%e0_2657) : !cute.int_tuple<"?">
          %1070 = cute.get_scalars(%e1_2658) : !cute.int_tuple<"?{div=2}">
          %coord_2659 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
          %slice_2660 = cute.slice(%ptn_C, %coord_2659) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,2)">
          %iter_2661 = cute.get_iter(%slice_2660) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2662, %e1_2663 = cute.get_leaves(%iter_2661) : !cute.int_tuple<"(?,?{div=2})">
          %1071 = cute.get_scalars(%e0_2662) : !cute.int_tuple<"?">
          %1072 = cute.get_scalars(%e1_2663) : !cute.int_tuple<"?{div=2}">
          %iter_2664 = cute.get_iter(%slice_2660) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2665, %e1_2666 = cute.get_leaves(%iter_2664) : !cute.int_tuple<"(?,?{div=2})">
          %1073 = cute.get_scalars(%e0_2665) : !cute.int_tuple<"?">
          %1074 = cute.get_scalars(%e1_2666) : !cute.int_tuple<"?{div=2}">
          %iter_2667 = cute.get_iter(%slice_2660) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2668, %e1_2669 = cute.get_leaves(%iter_2667) : !cute.int_tuple<"(?,?{div=2})">
          %1075 = cute.get_scalars(%e0_2668) : !cute.int_tuple<"?">
          %1076 = cute.get_scalars(%e1_2669) : !cute.int_tuple<"?{div=2}">
          %coord_2670 = cute.make_coord(%e0_2657) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2671 = cute.make_coord(%e1_2669) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1077 = cute.elem_less(%coord_2670, %coord_2671) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2672 = cute.get_layout(%1062) : !memref_rmem_f32_1
          %1078 = cute.get_shape(%lay_2672) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2673, %e1_2674, %e2_2675, %e3_2676 = cute.get_leaves(%1078) : !cute.shape<"((2,2),1,8)">
          %1079 = cute.get_stride(%lay_2672) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2677, %e1_2678, %e2_2679, %e3_2680 = cute.get_leaves(%1079) : !cute.stride<"((1,2),0,4)">
          %1080 = scf.if %1077 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1062) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,2)">
            cute.memref.store(%1062, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1062) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1062 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1062) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1062) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1062 : !memref_rmem_f32_1
          }
          %iter_2681 = cute.get_iter(%1080) : !memref_rmem_f32_1
          %lay_2682 = cute.get_layout(%1080) : !memref_rmem_f32_1
          %1081 = cute.get_shape(%lay_2682) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2683, %e1_2684, %e2_2685, %e3_2686 = cute.get_leaves(%1081) : !cute.shape<"((2,2),1,8)">
          %1082 = cute.get_stride(%lay_2682) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2687, %e1_2688, %e2_2689, %e3_2690 = cute.get_leaves(%1082) : !cute.stride<"((1,2),0,4)">
          %iter_2691 = cute.get_iter(%1080) : !memref_rmem_f32_1
          %iter_2692 = cute.get_iter(%1080) : !memref_rmem_f32_1
          %coord_2693 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %slice_2694 = cute.slice(%ptn_C, %coord_2693) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,3)">
          %iter_2695 = cute.get_iter(%slice_2694) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2696, %e1_2697 = cute.get_leaves(%iter_2695) : !cute.int_tuple<"(?,?{div=2})">
          %1083 = cute.get_scalars(%e0_2696) : !cute.int_tuple<"?">
          %1084 = cute.get_scalars(%e1_2697) : !cute.int_tuple<"?{div=2}">
          %iter_2698 = cute.get_iter(%slice_2694) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2699, %e1_2700 = cute.get_leaves(%iter_2698) : !cute.int_tuple<"(?,?{div=2})">
          %1085 = cute.get_scalars(%e0_2699) : !cute.int_tuple<"?">
          %1086 = cute.get_scalars(%e1_2700) : !cute.int_tuple<"?{div=2}">
          %iter_2701 = cute.get_iter(%slice_2694) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2702, %e1_2703 = cute.get_leaves(%iter_2701) : !cute.int_tuple<"(?,?{div=2})">
          %1087 = cute.get_scalars(%e0_2702) : !cute.int_tuple<"?">
          %1088 = cute.get_scalars(%e1_2703) : !cute.int_tuple<"?{div=2}">
          %coord_2704 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
          %slice_2705 = cute.slice(%ptn_C, %coord_2704) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,3)">
          %iter_2706 = cute.get_iter(%slice_2705) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2707, %e1_2708 = cute.get_leaves(%iter_2706) : !cute.int_tuple<"(?,?{div=2})">
          %1089 = cute.get_scalars(%e0_2707) : !cute.int_tuple<"?">
          %1090 = cute.get_scalars(%e1_2708) : !cute.int_tuple<"?{div=2}">
          %iter_2709 = cute.get_iter(%slice_2705) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2710, %e1_2711 = cute.get_leaves(%iter_2709) : !cute.int_tuple<"(?,?{div=2})">
          %1091 = cute.get_scalars(%e0_2710) : !cute.int_tuple<"?">
          %1092 = cute.get_scalars(%e1_2711) : !cute.int_tuple<"?{div=2}">
          %iter_2712 = cute.get_iter(%slice_2705) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2713, %e1_2714 = cute.get_leaves(%iter_2712) : !cute.int_tuple<"(?,?{div=2})">
          %1093 = cute.get_scalars(%e0_2713) : !cute.int_tuple<"?">
          %1094 = cute.get_scalars(%e1_2714) : !cute.int_tuple<"?{div=2}">
          %coord_2715 = cute.make_coord(%e0_2702) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2716 = cute.make_coord(%e1_2714) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1095 = cute.elem_less(%coord_2715, %coord_2716) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2717 = cute.get_layout(%1080) : !memref_rmem_f32_1
          %1096 = cute.get_shape(%lay_2717) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2718, %e1_2719, %e2_2720, %e3_2721 = cute.get_leaves(%1096) : !cute.shape<"((2,2),1,8)">
          %1097 = cute.get_stride(%lay_2717) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2722, %e1_2723, %e2_2724, %e3_2725 = cute.get_leaves(%1097) : !cute.stride<"((1,2),0,4)">
          %1098 = scf.if %1095 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1080) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,3)">
            cute.memref.store(%1080, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1080) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1080 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1080) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1080) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1080 : !memref_rmem_f32_1
          }
          %iter_2726 = cute.get_iter(%1098) : !memref_rmem_f32_1
          %lay_2727 = cute.get_layout(%1098) : !memref_rmem_f32_1
          %1099 = cute.get_shape(%lay_2727) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2728, %e1_2729, %e2_2730, %e3_2731 = cute.get_leaves(%1099) : !cute.shape<"((2,2),1,8)">
          %1100 = cute.get_stride(%lay_2727) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2732, %e1_2733, %e2_2734, %e3_2735 = cute.get_leaves(%1100) : !cute.stride<"((1,2),0,4)">
          %iter_2736 = cute.get_iter(%1098) : !memref_rmem_f32_1
          %iter_2737 = cute.get_iter(%1098) : !memref_rmem_f32_1
          %coord_2738 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %slice_2739 = cute.slice(%ptn_C, %coord_2738) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,4)">
          %iter_2740 = cute.get_iter(%slice_2739) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2741, %e1_2742 = cute.get_leaves(%iter_2740) : !cute.int_tuple<"(?,?{div=2})">
          %1101 = cute.get_scalars(%e0_2741) : !cute.int_tuple<"?">
          %1102 = cute.get_scalars(%e1_2742) : !cute.int_tuple<"?{div=2}">
          %iter_2743 = cute.get_iter(%slice_2739) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2744, %e1_2745 = cute.get_leaves(%iter_2743) : !cute.int_tuple<"(?,?{div=2})">
          %1103 = cute.get_scalars(%e0_2744) : !cute.int_tuple<"?">
          %1104 = cute.get_scalars(%e1_2745) : !cute.int_tuple<"?{div=2}">
          %iter_2746 = cute.get_iter(%slice_2739) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2747, %e1_2748 = cute.get_leaves(%iter_2746) : !cute.int_tuple<"(?,?{div=2})">
          %1105 = cute.get_scalars(%e0_2747) : !cute.int_tuple<"?">
          %1106 = cute.get_scalars(%e1_2748) : !cute.int_tuple<"?{div=2}">
          %coord_2749 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
          %slice_2750 = cute.slice(%ptn_C, %coord_2749) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,4)">
          %iter_2751 = cute.get_iter(%slice_2750) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2752, %e1_2753 = cute.get_leaves(%iter_2751) : !cute.int_tuple<"(?,?{div=2})">
          %1107 = cute.get_scalars(%e0_2752) : !cute.int_tuple<"?">
          %1108 = cute.get_scalars(%e1_2753) : !cute.int_tuple<"?{div=2}">
          %iter_2754 = cute.get_iter(%slice_2750) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2755, %e1_2756 = cute.get_leaves(%iter_2754) : !cute.int_tuple<"(?,?{div=2})">
          %1109 = cute.get_scalars(%e0_2755) : !cute.int_tuple<"?">
          %1110 = cute.get_scalars(%e1_2756) : !cute.int_tuple<"?{div=2}">
          %iter_2757 = cute.get_iter(%slice_2750) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2758, %e1_2759 = cute.get_leaves(%iter_2757) : !cute.int_tuple<"(?,?{div=2})">
          %1111 = cute.get_scalars(%e0_2758) : !cute.int_tuple<"?">
          %1112 = cute.get_scalars(%e1_2759) : !cute.int_tuple<"?{div=2}">
          %coord_2760 = cute.make_coord(%e0_2747) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2761 = cute.make_coord(%e1_2759) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1113 = cute.elem_less(%coord_2760, %coord_2761) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2762 = cute.get_layout(%1098) : !memref_rmem_f32_1
          %1114 = cute.get_shape(%lay_2762) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2763, %e1_2764, %e2_2765, %e3_2766 = cute.get_leaves(%1114) : !cute.shape<"((2,2),1,8)">
          %1115 = cute.get_stride(%lay_2762) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2767, %e1_2768, %e2_2769, %e3_2770 = cute.get_leaves(%1115) : !cute.stride<"((1,2),0,4)">
          %1116 = scf.if %1113 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1098) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,4)">
            cute.memref.store(%1098, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1098) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1098 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1098) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1098) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1098 : !memref_rmem_f32_1
          }
          %iter_2771 = cute.get_iter(%1116) : !memref_rmem_f32_1
          %lay_2772 = cute.get_layout(%1116) : !memref_rmem_f32_1
          %1117 = cute.get_shape(%lay_2772) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2773, %e1_2774, %e2_2775, %e3_2776 = cute.get_leaves(%1117) : !cute.shape<"((2,2),1,8)">
          %1118 = cute.get_stride(%lay_2772) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2777, %e1_2778, %e2_2779, %e3_2780 = cute.get_leaves(%1118) : !cute.stride<"((1,2),0,4)">
          %iter_2781 = cute.get_iter(%1116) : !memref_rmem_f32_1
          %iter_2782 = cute.get_iter(%1116) : !memref_rmem_f32_1
          %coord_2783 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %slice_2784 = cute.slice(%ptn_C, %coord_2783) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,5)">
          %iter_2785 = cute.get_iter(%slice_2784) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2786, %e1_2787 = cute.get_leaves(%iter_2785) : !cute.int_tuple<"(?,?{div=2})">
          %1119 = cute.get_scalars(%e0_2786) : !cute.int_tuple<"?">
          %1120 = cute.get_scalars(%e1_2787) : !cute.int_tuple<"?{div=2}">
          %iter_2788 = cute.get_iter(%slice_2784) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2789, %e1_2790 = cute.get_leaves(%iter_2788) : !cute.int_tuple<"(?,?{div=2})">
          %1121 = cute.get_scalars(%e0_2789) : !cute.int_tuple<"?">
          %1122 = cute.get_scalars(%e1_2790) : !cute.int_tuple<"?{div=2}">
          %iter_2791 = cute.get_iter(%slice_2784) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2792, %e1_2793 = cute.get_leaves(%iter_2791) : !cute.int_tuple<"(?,?{div=2})">
          %1123 = cute.get_scalars(%e0_2792) : !cute.int_tuple<"?">
          %1124 = cute.get_scalars(%e1_2793) : !cute.int_tuple<"?{div=2}">
          %coord_2794 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
          %slice_2795 = cute.slice(%ptn_C, %coord_2794) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,5)">
          %iter_2796 = cute.get_iter(%slice_2795) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2797, %e1_2798 = cute.get_leaves(%iter_2796) : !cute.int_tuple<"(?,?{div=2})">
          %1125 = cute.get_scalars(%e0_2797) : !cute.int_tuple<"?">
          %1126 = cute.get_scalars(%e1_2798) : !cute.int_tuple<"?{div=2}">
          %iter_2799 = cute.get_iter(%slice_2795) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2800, %e1_2801 = cute.get_leaves(%iter_2799) : !cute.int_tuple<"(?,?{div=2})">
          %1127 = cute.get_scalars(%e0_2800) : !cute.int_tuple<"?">
          %1128 = cute.get_scalars(%e1_2801) : !cute.int_tuple<"?{div=2}">
          %iter_2802 = cute.get_iter(%slice_2795) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2803, %e1_2804 = cute.get_leaves(%iter_2802) : !cute.int_tuple<"(?,?{div=2})">
          %1129 = cute.get_scalars(%e0_2803) : !cute.int_tuple<"?">
          %1130 = cute.get_scalars(%e1_2804) : !cute.int_tuple<"?{div=2}">
          %coord_2805 = cute.make_coord(%e0_2792) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2806 = cute.make_coord(%e1_2804) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1131 = cute.elem_less(%coord_2805, %coord_2806) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2807 = cute.get_layout(%1116) : !memref_rmem_f32_1
          %1132 = cute.get_shape(%lay_2807) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2808, %e1_2809, %e2_2810, %e3_2811 = cute.get_leaves(%1132) : !cute.shape<"((2,2),1,8)">
          %1133 = cute.get_stride(%lay_2807) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2812, %e1_2813, %e2_2814, %e3_2815 = cute.get_leaves(%1133) : !cute.stride<"((1,2),0,4)">
          %1134 = scf.if %1131 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1116) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,5)">
            cute.memref.store(%1116, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1116) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1116 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1116) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1116) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1116 : !memref_rmem_f32_1
          }
          %iter_2816 = cute.get_iter(%1134) : !memref_rmem_f32_1
          %lay_2817 = cute.get_layout(%1134) : !memref_rmem_f32_1
          %1135 = cute.get_shape(%lay_2817) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2818, %e1_2819, %e2_2820, %e3_2821 = cute.get_leaves(%1135) : !cute.shape<"((2,2),1,8)">
          %1136 = cute.get_stride(%lay_2817) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2822, %e1_2823, %e2_2824, %e3_2825 = cute.get_leaves(%1136) : !cute.stride<"((1,2),0,4)">
          %iter_2826 = cute.get_iter(%1134) : !memref_rmem_f32_1
          %iter_2827 = cute.get_iter(%1134) : !memref_rmem_f32_1
          %coord_2828 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %slice_2829 = cute.slice(%ptn_C, %coord_2828) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,6)">
          %iter_2830 = cute.get_iter(%slice_2829) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2831, %e1_2832 = cute.get_leaves(%iter_2830) : !cute.int_tuple<"(?,?{div=2})">
          %1137 = cute.get_scalars(%e0_2831) : !cute.int_tuple<"?">
          %1138 = cute.get_scalars(%e1_2832) : !cute.int_tuple<"?{div=2}">
          %iter_2833 = cute.get_iter(%slice_2829) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2834, %e1_2835 = cute.get_leaves(%iter_2833) : !cute.int_tuple<"(?,?{div=2})">
          %1139 = cute.get_scalars(%e0_2834) : !cute.int_tuple<"?">
          %1140 = cute.get_scalars(%e1_2835) : !cute.int_tuple<"?{div=2}">
          %iter_2836 = cute.get_iter(%slice_2829) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2837, %e1_2838 = cute.get_leaves(%iter_2836) : !cute.int_tuple<"(?,?{div=2})">
          %1141 = cute.get_scalars(%e0_2837) : !cute.int_tuple<"?">
          %1142 = cute.get_scalars(%e1_2838) : !cute.int_tuple<"?{div=2}">
          %coord_2839 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
          %slice_2840 = cute.slice(%ptn_C, %coord_2839) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,6)">
          %iter_2841 = cute.get_iter(%slice_2840) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2842, %e1_2843 = cute.get_leaves(%iter_2841) : !cute.int_tuple<"(?,?{div=2})">
          %1143 = cute.get_scalars(%e0_2842) : !cute.int_tuple<"?">
          %1144 = cute.get_scalars(%e1_2843) : !cute.int_tuple<"?{div=2}">
          %iter_2844 = cute.get_iter(%slice_2840) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2845, %e1_2846 = cute.get_leaves(%iter_2844) : !cute.int_tuple<"(?,?{div=2})">
          %1145 = cute.get_scalars(%e0_2845) : !cute.int_tuple<"?">
          %1146 = cute.get_scalars(%e1_2846) : !cute.int_tuple<"?{div=2}">
          %iter_2847 = cute.get_iter(%slice_2840) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2848, %e1_2849 = cute.get_leaves(%iter_2847) : !cute.int_tuple<"(?,?{div=2})">
          %1147 = cute.get_scalars(%e0_2848) : !cute.int_tuple<"?">
          %1148 = cute.get_scalars(%e1_2849) : !cute.int_tuple<"?{div=2}">
          %coord_2850 = cute.make_coord(%e0_2837) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2851 = cute.make_coord(%e1_2849) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1149 = cute.elem_less(%coord_2850, %coord_2851) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2852 = cute.get_layout(%1134) : !memref_rmem_f32_1
          %1150 = cute.get_shape(%lay_2852) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2853, %e1_2854, %e2_2855, %e3_2856 = cute.get_leaves(%1150) : !cute.shape<"((2,2),1,8)">
          %1151 = cute.get_stride(%lay_2852) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2857, %e1_2858, %e2_2859, %e3_2860 = cute.get_leaves(%1151) : !cute.stride<"((1,2),0,4)">
          %1152 = scf.if %1149 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1134) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,6)">
            cute.memref.store(%1134, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1134) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1134 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1134) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1134) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1134 : !memref_rmem_f32_1
          }
          %iter_2861 = cute.get_iter(%1152) : !memref_rmem_f32_1
          %lay_2862 = cute.get_layout(%1152) : !memref_rmem_f32_1
          %1153 = cute.get_shape(%lay_2862) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2863, %e1_2864, %e2_2865, %e3_2866 = cute.get_leaves(%1153) : !cute.shape<"((2,2),1,8)">
          %1154 = cute.get_stride(%lay_2862) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2867, %e1_2868, %e2_2869, %e3_2870 = cute.get_leaves(%1154) : !cute.stride<"((1,2),0,4)">
          %iter_2871 = cute.get_iter(%1152) : !memref_rmem_f32_1
          %iter_2872 = cute.get_iter(%1152) : !memref_rmem_f32_1
          %coord_2873 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %slice_2874 = cute.slice(%ptn_C, %coord_2873) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,7)">
          %iter_2875 = cute.get_iter(%slice_2874) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2876, %e1_2877 = cute.get_leaves(%iter_2875) : !cute.int_tuple<"(?,?{div=2})">
          %1155 = cute.get_scalars(%e0_2876) : !cute.int_tuple<"?">
          %1156 = cute.get_scalars(%e1_2877) : !cute.int_tuple<"?{div=2}">
          %iter_2878 = cute.get_iter(%slice_2874) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2879, %e1_2880 = cute.get_leaves(%iter_2878) : !cute.int_tuple<"(?,?{div=2})">
          %1157 = cute.get_scalars(%e0_2879) : !cute.int_tuple<"?">
          %1158 = cute.get_scalars(%e1_2880) : !cute.int_tuple<"?{div=2}">
          %iter_2881 = cute.get_iter(%slice_2874) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2882, %e1_2883 = cute.get_leaves(%iter_2881) : !cute.int_tuple<"(?,?{div=2})">
          %1159 = cute.get_scalars(%e0_2882) : !cute.int_tuple<"?">
          %1160 = cute.get_scalars(%e1_2883) : !cute.int_tuple<"?{div=2}">
          %coord_2884 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
          %slice_2885 = cute.slice(%ptn_C, %coord_2884) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(0,0,7)">
          %iter_2886 = cute.get_iter(%slice_2885) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2887, %e1_2888 = cute.get_leaves(%iter_2886) : !cute.int_tuple<"(?,?{div=2})">
          %1161 = cute.get_scalars(%e0_2887) : !cute.int_tuple<"?">
          %1162 = cute.get_scalars(%e1_2888) : !cute.int_tuple<"?{div=2}">
          %iter_2889 = cute.get_iter(%slice_2885) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2890, %e1_2891 = cute.get_leaves(%iter_2889) : !cute.int_tuple<"(?,?{div=2})">
          %1163 = cute.get_scalars(%e0_2890) : !cute.int_tuple<"?">
          %1164 = cute.get_scalars(%e1_2891) : !cute.int_tuple<"?{div=2}">
          %iter_2892 = cute.get_iter(%slice_2885) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_2893, %e1_2894 = cute.get_leaves(%iter_2892) : !cute.int_tuple<"(?,?{div=2})">
          %1165 = cute.get_scalars(%e0_2893) : !cute.int_tuple<"?">
          %1166 = cute.get_scalars(%e1_2894) : !cute.int_tuple<"?{div=2}">
          %coord_2895 = cute.make_coord(%e0_2882) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2896 = cute.make_coord(%e1_2894) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1167 = cute.elem_less(%coord_2895, %coord_2896) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_2897 = cute.get_layout(%1152) : !memref_rmem_f32_1
          %1168 = cute.get_shape(%lay_2897) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2898, %e1_2899, %e2_2900, %e3_2901 = cute.get_leaves(%1168) : !cute.shape<"((2,2),1,8)">
          %1169 = cute.get_stride(%lay_2897) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2902, %e1_2903, %e2_2904, %e3_2905 = cute.get_leaves(%1169) : !cute.stride<"((1,2),0,4)">
          %1170 = scf.if %1167 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1152) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(0,0,7)">
            cute.memref.store(%1152, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1152) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1152 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1152) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1152) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1152 : !memref_rmem_f32_1
          }
          %iter_2906 = cute.get_iter(%1170) : !memref_rmem_f32_1
          %lay_2907 = cute.get_layout(%1170) : !memref_rmem_f32_1
          %1171 = cute.get_shape(%lay_2907) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2908, %e1_2909, %e2_2910, %e3_2911 = cute.get_leaves(%1171) : !cute.shape<"((2,2),1,8)">
          %1172 = cute.get_stride(%lay_2907) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2912, %e1_2913, %e2_2914, %e3_2915 = cute.get_leaves(%1172) : !cute.stride<"((1,2),0,4)">
          %iter_2916 = cute.get_iter(%1170) : !memref_rmem_f32_1
          %iter_2917 = cute.get_iter(%1170) : !memref_rmem_f32_1
          %int_tuple_2918 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_2919 = cute.size(%int_tuple_2918) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_2920 = cute.get_leaves(%sz_2919) : !cute.int_tuple<"1">
          %int_tuple_2921 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_2922 = cute.size(%int_tuple_2921) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_2923 = cute.get_leaves(%sz_2922) : !cute.int_tuple<"8">
          %coord_2924 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %slice_2925 = cute.slice(%ptn_C, %coord_2924) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,0)">
          %iter_2926 = cute.get_iter(%slice_2925) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2927, %e1_2928 = cute.get_leaves(%iter_2926) : !cute.int_tuple<"(?,?)">
          %1173 = cute.get_scalars(%e0_2927) : !cute.int_tuple<"?">
          %1174 = cute.get_scalars(%e1_2928) : !cute.int_tuple<"?">
          %iter_2929 = cute.get_iter(%slice_2925) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2930, %e1_2931 = cute.get_leaves(%iter_2929) : !cute.int_tuple<"(?,?)">
          %1175 = cute.get_scalars(%e0_2930) : !cute.int_tuple<"?">
          %1176 = cute.get_scalars(%e1_2931) : !cute.int_tuple<"?">
          %iter_2932 = cute.get_iter(%slice_2925) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2933, %e1_2934 = cute.get_leaves(%iter_2932) : !cute.int_tuple<"(?,?)">
          %1177 = cute.get_scalars(%e0_2933) : !cute.int_tuple<"?">
          %1178 = cute.get_scalars(%e1_2934) : !cute.int_tuple<"?">
          %coord_2935 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
          %slice_2936 = cute.slice(%ptn_C, %coord_2935) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,0)">
          %iter_2937 = cute.get_iter(%slice_2936) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2938, %e1_2939 = cute.get_leaves(%iter_2937) : !cute.int_tuple<"(?,?)">
          %1179 = cute.get_scalars(%e0_2938) : !cute.int_tuple<"?">
          %1180 = cute.get_scalars(%e1_2939) : !cute.int_tuple<"?">
          %iter_2940 = cute.get_iter(%slice_2936) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2941, %e1_2942 = cute.get_leaves(%iter_2940) : !cute.int_tuple<"(?,?)">
          %1181 = cute.get_scalars(%e0_2941) : !cute.int_tuple<"?">
          %1182 = cute.get_scalars(%e1_2942) : !cute.int_tuple<"?">
          %iter_2943 = cute.get_iter(%slice_2936) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2944, %e1_2945 = cute.get_leaves(%iter_2943) : !cute.int_tuple<"(?,?)">
          %1183 = cute.get_scalars(%e0_2944) : !cute.int_tuple<"?">
          %1184 = cute.get_scalars(%e1_2945) : !cute.int_tuple<"?">
          %coord_2946 = cute.make_coord(%e0_2933) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2947 = cute.make_coord(%e1_2945) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1185 = cute.elem_less(%coord_2946, %coord_2947) : !cute.coord<"?">, !cute.coord<"?">
          %lay_2948 = cute.get_layout(%1170) : !memref_rmem_f32_1
          %1186 = cute.get_shape(%lay_2948) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2949, %e1_2950, %e2_2951, %e3_2952 = cute.get_leaves(%1186) : !cute.shape<"((2,2),1,8)">
          %1187 = cute.get_stride(%lay_2948) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2953, %e1_2954, %e2_2955, %e3_2956 = cute.get_leaves(%1187) : !cute.stride<"((1,2),0,4)">
          %1188 = scf.if %1185 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1170) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
            cute.memref.store(%1170, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1170) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1170 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1170) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1170) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1170 : !memref_rmem_f32_1
          }
          %iter_2957 = cute.get_iter(%1188) : !memref_rmem_f32_1
          %lay_2958 = cute.get_layout(%1188) : !memref_rmem_f32_1
          %1189 = cute.get_shape(%lay_2958) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2959, %e1_2960, %e2_2961, %e3_2962 = cute.get_leaves(%1189) : !cute.shape<"((2,2),1,8)">
          %1190 = cute.get_stride(%lay_2958) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2963, %e1_2964, %e2_2965, %e3_2966 = cute.get_leaves(%1190) : !cute.stride<"((1,2),0,4)">
          %iter_2967 = cute.get_iter(%1188) : !memref_rmem_f32_1
          %iter_2968 = cute.get_iter(%1188) : !memref_rmem_f32_1
          %coord_2969 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %slice_2970 = cute.slice(%ptn_C, %coord_2969) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,1)">
          %iter_2971 = cute.get_iter(%slice_2970) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2972, %e1_2973 = cute.get_leaves(%iter_2971) : !cute.int_tuple<"(?,?)">
          %1191 = cute.get_scalars(%e0_2972) : !cute.int_tuple<"?">
          %1192 = cute.get_scalars(%e1_2973) : !cute.int_tuple<"?">
          %iter_2974 = cute.get_iter(%slice_2970) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2975, %e1_2976 = cute.get_leaves(%iter_2974) : !cute.int_tuple<"(?,?)">
          %1193 = cute.get_scalars(%e0_2975) : !cute.int_tuple<"?">
          %1194 = cute.get_scalars(%e1_2976) : !cute.int_tuple<"?">
          %iter_2977 = cute.get_iter(%slice_2970) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2978, %e1_2979 = cute.get_leaves(%iter_2977) : !cute.int_tuple<"(?,?)">
          %1195 = cute.get_scalars(%e0_2978) : !cute.int_tuple<"?">
          %1196 = cute.get_scalars(%e1_2979) : !cute.int_tuple<"?">
          %coord_2980 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
          %slice_2981 = cute.slice(%ptn_C, %coord_2980) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,1)">
          %iter_2982 = cute.get_iter(%slice_2981) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2983, %e1_2984 = cute.get_leaves(%iter_2982) : !cute.int_tuple<"(?,?)">
          %1197 = cute.get_scalars(%e0_2983) : !cute.int_tuple<"?">
          %1198 = cute.get_scalars(%e1_2984) : !cute.int_tuple<"?">
          %iter_2985 = cute.get_iter(%slice_2981) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2986, %e1_2987 = cute.get_leaves(%iter_2985) : !cute.int_tuple<"(?,?)">
          %1199 = cute.get_scalars(%e0_2986) : !cute.int_tuple<"?">
          %1200 = cute.get_scalars(%e1_2987) : !cute.int_tuple<"?">
          %iter_2988 = cute.get_iter(%slice_2981) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_2989, %e1_2990 = cute.get_leaves(%iter_2988) : !cute.int_tuple<"(?,?)">
          %1201 = cute.get_scalars(%e0_2989) : !cute.int_tuple<"?">
          %1202 = cute.get_scalars(%e1_2990) : !cute.int_tuple<"?">
          %coord_2991 = cute.make_coord(%e0_2978) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_2992 = cute.make_coord(%e1_2990) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1203 = cute.elem_less(%coord_2991, %coord_2992) : !cute.coord<"?">, !cute.coord<"?">
          %lay_2993 = cute.get_layout(%1188) : !memref_rmem_f32_1
          %1204 = cute.get_shape(%lay_2993) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2994, %e1_2995, %e2_2996, %e3_2997 = cute.get_leaves(%1204) : !cute.shape<"((2,2),1,8)">
          %1205 = cute.get_stride(%lay_2993) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2998, %e1_2999, %e2_3000, %e3_3001 = cute.get_leaves(%1205) : !cute.stride<"((1,2),0,4)">
          %1206 = scf.if %1203 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1188) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,1)">
            cute.memref.store(%1188, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1188) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1188 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1188) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1188) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1188 : !memref_rmem_f32_1
          }
          %iter_3002 = cute.get_iter(%1206) : !memref_rmem_f32_1
          %lay_3003 = cute.get_layout(%1206) : !memref_rmem_f32_1
          %1207 = cute.get_shape(%lay_3003) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3004, %e1_3005, %e2_3006, %e3_3007 = cute.get_leaves(%1207) : !cute.shape<"((2,2),1,8)">
          %1208 = cute.get_stride(%lay_3003) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3008, %e1_3009, %e2_3010, %e3_3011 = cute.get_leaves(%1208) : !cute.stride<"((1,2),0,4)">
          %iter_3012 = cute.get_iter(%1206) : !memref_rmem_f32_1
          %iter_3013 = cute.get_iter(%1206) : !memref_rmem_f32_1
          %coord_3014 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %slice_3015 = cute.slice(%ptn_C, %coord_3014) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,2)">
          %iter_3016 = cute.get_iter(%slice_3015) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3017, %e1_3018 = cute.get_leaves(%iter_3016) : !cute.int_tuple<"(?,?)">
          %1209 = cute.get_scalars(%e0_3017) : !cute.int_tuple<"?">
          %1210 = cute.get_scalars(%e1_3018) : !cute.int_tuple<"?">
          %iter_3019 = cute.get_iter(%slice_3015) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3020, %e1_3021 = cute.get_leaves(%iter_3019) : !cute.int_tuple<"(?,?)">
          %1211 = cute.get_scalars(%e0_3020) : !cute.int_tuple<"?">
          %1212 = cute.get_scalars(%e1_3021) : !cute.int_tuple<"?">
          %iter_3022 = cute.get_iter(%slice_3015) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3023, %e1_3024 = cute.get_leaves(%iter_3022) : !cute.int_tuple<"(?,?)">
          %1213 = cute.get_scalars(%e0_3023) : !cute.int_tuple<"?">
          %1214 = cute.get_scalars(%e1_3024) : !cute.int_tuple<"?">
          %coord_3025 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
          %slice_3026 = cute.slice(%ptn_C, %coord_3025) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,2)">
          %iter_3027 = cute.get_iter(%slice_3026) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3028, %e1_3029 = cute.get_leaves(%iter_3027) : !cute.int_tuple<"(?,?)">
          %1215 = cute.get_scalars(%e0_3028) : !cute.int_tuple<"?">
          %1216 = cute.get_scalars(%e1_3029) : !cute.int_tuple<"?">
          %iter_3030 = cute.get_iter(%slice_3026) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3031, %e1_3032 = cute.get_leaves(%iter_3030) : !cute.int_tuple<"(?,?)">
          %1217 = cute.get_scalars(%e0_3031) : !cute.int_tuple<"?">
          %1218 = cute.get_scalars(%e1_3032) : !cute.int_tuple<"?">
          %iter_3033 = cute.get_iter(%slice_3026) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3034, %e1_3035 = cute.get_leaves(%iter_3033) : !cute.int_tuple<"(?,?)">
          %1219 = cute.get_scalars(%e0_3034) : !cute.int_tuple<"?">
          %1220 = cute.get_scalars(%e1_3035) : !cute.int_tuple<"?">
          %coord_3036 = cute.make_coord(%e0_3023) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3037 = cute.make_coord(%e1_3035) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1221 = cute.elem_less(%coord_3036, %coord_3037) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3038 = cute.get_layout(%1206) : !memref_rmem_f32_1
          %1222 = cute.get_shape(%lay_3038) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3039, %e1_3040, %e2_3041, %e3_3042 = cute.get_leaves(%1222) : !cute.shape<"((2,2),1,8)">
          %1223 = cute.get_stride(%lay_3038) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3043, %e1_3044, %e2_3045, %e3_3046 = cute.get_leaves(%1223) : !cute.stride<"((1,2),0,4)">
          %1224 = scf.if %1221 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1206) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,2)">
            cute.memref.store(%1206, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1206) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1206 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1206) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1206) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1206 : !memref_rmem_f32_1
          }
          %iter_3047 = cute.get_iter(%1224) : !memref_rmem_f32_1
          %lay_3048 = cute.get_layout(%1224) : !memref_rmem_f32_1
          %1225 = cute.get_shape(%lay_3048) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3049, %e1_3050, %e2_3051, %e3_3052 = cute.get_leaves(%1225) : !cute.shape<"((2,2),1,8)">
          %1226 = cute.get_stride(%lay_3048) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3053, %e1_3054, %e2_3055, %e3_3056 = cute.get_leaves(%1226) : !cute.stride<"((1,2),0,4)">
          %iter_3057 = cute.get_iter(%1224) : !memref_rmem_f32_1
          %iter_3058 = cute.get_iter(%1224) : !memref_rmem_f32_1
          %coord_3059 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %slice_3060 = cute.slice(%ptn_C, %coord_3059) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,3)">
          %iter_3061 = cute.get_iter(%slice_3060) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3062, %e1_3063 = cute.get_leaves(%iter_3061) : !cute.int_tuple<"(?,?)">
          %1227 = cute.get_scalars(%e0_3062) : !cute.int_tuple<"?">
          %1228 = cute.get_scalars(%e1_3063) : !cute.int_tuple<"?">
          %iter_3064 = cute.get_iter(%slice_3060) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3065, %e1_3066 = cute.get_leaves(%iter_3064) : !cute.int_tuple<"(?,?)">
          %1229 = cute.get_scalars(%e0_3065) : !cute.int_tuple<"?">
          %1230 = cute.get_scalars(%e1_3066) : !cute.int_tuple<"?">
          %iter_3067 = cute.get_iter(%slice_3060) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3068, %e1_3069 = cute.get_leaves(%iter_3067) : !cute.int_tuple<"(?,?)">
          %1231 = cute.get_scalars(%e0_3068) : !cute.int_tuple<"?">
          %1232 = cute.get_scalars(%e1_3069) : !cute.int_tuple<"?">
          %coord_3070 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
          %slice_3071 = cute.slice(%ptn_C, %coord_3070) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,3)">
          %iter_3072 = cute.get_iter(%slice_3071) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3073, %e1_3074 = cute.get_leaves(%iter_3072) : !cute.int_tuple<"(?,?)">
          %1233 = cute.get_scalars(%e0_3073) : !cute.int_tuple<"?">
          %1234 = cute.get_scalars(%e1_3074) : !cute.int_tuple<"?">
          %iter_3075 = cute.get_iter(%slice_3071) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3076, %e1_3077 = cute.get_leaves(%iter_3075) : !cute.int_tuple<"(?,?)">
          %1235 = cute.get_scalars(%e0_3076) : !cute.int_tuple<"?">
          %1236 = cute.get_scalars(%e1_3077) : !cute.int_tuple<"?">
          %iter_3078 = cute.get_iter(%slice_3071) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3079, %e1_3080 = cute.get_leaves(%iter_3078) : !cute.int_tuple<"(?,?)">
          %1237 = cute.get_scalars(%e0_3079) : !cute.int_tuple<"?">
          %1238 = cute.get_scalars(%e1_3080) : !cute.int_tuple<"?">
          %coord_3081 = cute.make_coord(%e0_3068) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3082 = cute.make_coord(%e1_3080) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1239 = cute.elem_less(%coord_3081, %coord_3082) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3083 = cute.get_layout(%1224) : !memref_rmem_f32_1
          %1240 = cute.get_shape(%lay_3083) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3084, %e1_3085, %e2_3086, %e3_3087 = cute.get_leaves(%1240) : !cute.shape<"((2,2),1,8)">
          %1241 = cute.get_stride(%lay_3083) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3088, %e1_3089, %e2_3090, %e3_3091 = cute.get_leaves(%1241) : !cute.stride<"((1,2),0,4)">
          %1242 = scf.if %1239 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1224) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,3)">
            cute.memref.store(%1224, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1224) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1224 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1224) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1224) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1224 : !memref_rmem_f32_1
          }
          %iter_3092 = cute.get_iter(%1242) : !memref_rmem_f32_1
          %lay_3093 = cute.get_layout(%1242) : !memref_rmem_f32_1
          %1243 = cute.get_shape(%lay_3093) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3094, %e1_3095, %e2_3096, %e3_3097 = cute.get_leaves(%1243) : !cute.shape<"((2,2),1,8)">
          %1244 = cute.get_stride(%lay_3093) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3098, %e1_3099, %e2_3100, %e3_3101 = cute.get_leaves(%1244) : !cute.stride<"((1,2),0,4)">
          %iter_3102 = cute.get_iter(%1242) : !memref_rmem_f32_1
          %iter_3103 = cute.get_iter(%1242) : !memref_rmem_f32_1
          %coord_3104 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %slice_3105 = cute.slice(%ptn_C, %coord_3104) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,4)">
          %iter_3106 = cute.get_iter(%slice_3105) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3107, %e1_3108 = cute.get_leaves(%iter_3106) : !cute.int_tuple<"(?,?)">
          %1245 = cute.get_scalars(%e0_3107) : !cute.int_tuple<"?">
          %1246 = cute.get_scalars(%e1_3108) : !cute.int_tuple<"?">
          %iter_3109 = cute.get_iter(%slice_3105) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3110, %e1_3111 = cute.get_leaves(%iter_3109) : !cute.int_tuple<"(?,?)">
          %1247 = cute.get_scalars(%e0_3110) : !cute.int_tuple<"?">
          %1248 = cute.get_scalars(%e1_3111) : !cute.int_tuple<"?">
          %iter_3112 = cute.get_iter(%slice_3105) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3113, %e1_3114 = cute.get_leaves(%iter_3112) : !cute.int_tuple<"(?,?)">
          %1249 = cute.get_scalars(%e0_3113) : !cute.int_tuple<"?">
          %1250 = cute.get_scalars(%e1_3114) : !cute.int_tuple<"?">
          %coord_3115 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
          %slice_3116 = cute.slice(%ptn_C, %coord_3115) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,4)">
          %iter_3117 = cute.get_iter(%slice_3116) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3118, %e1_3119 = cute.get_leaves(%iter_3117) : !cute.int_tuple<"(?,?)">
          %1251 = cute.get_scalars(%e0_3118) : !cute.int_tuple<"?">
          %1252 = cute.get_scalars(%e1_3119) : !cute.int_tuple<"?">
          %iter_3120 = cute.get_iter(%slice_3116) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3121, %e1_3122 = cute.get_leaves(%iter_3120) : !cute.int_tuple<"(?,?)">
          %1253 = cute.get_scalars(%e0_3121) : !cute.int_tuple<"?">
          %1254 = cute.get_scalars(%e1_3122) : !cute.int_tuple<"?">
          %iter_3123 = cute.get_iter(%slice_3116) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3124, %e1_3125 = cute.get_leaves(%iter_3123) : !cute.int_tuple<"(?,?)">
          %1255 = cute.get_scalars(%e0_3124) : !cute.int_tuple<"?">
          %1256 = cute.get_scalars(%e1_3125) : !cute.int_tuple<"?">
          %coord_3126 = cute.make_coord(%e0_3113) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3127 = cute.make_coord(%e1_3125) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1257 = cute.elem_less(%coord_3126, %coord_3127) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3128 = cute.get_layout(%1242) : !memref_rmem_f32_1
          %1258 = cute.get_shape(%lay_3128) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3129, %e1_3130, %e2_3131, %e3_3132 = cute.get_leaves(%1258) : !cute.shape<"((2,2),1,8)">
          %1259 = cute.get_stride(%lay_3128) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3133, %e1_3134, %e2_3135, %e3_3136 = cute.get_leaves(%1259) : !cute.stride<"((1,2),0,4)">
          %1260 = scf.if %1257 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1242) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,4)">
            cute.memref.store(%1242, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1242) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1242 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1242) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1242) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1242 : !memref_rmem_f32_1
          }
          %iter_3137 = cute.get_iter(%1260) : !memref_rmem_f32_1
          %lay_3138 = cute.get_layout(%1260) : !memref_rmem_f32_1
          %1261 = cute.get_shape(%lay_3138) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3139, %e1_3140, %e2_3141, %e3_3142 = cute.get_leaves(%1261) : !cute.shape<"((2,2),1,8)">
          %1262 = cute.get_stride(%lay_3138) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3143, %e1_3144, %e2_3145, %e3_3146 = cute.get_leaves(%1262) : !cute.stride<"((1,2),0,4)">
          %iter_3147 = cute.get_iter(%1260) : !memref_rmem_f32_1
          %iter_3148 = cute.get_iter(%1260) : !memref_rmem_f32_1
          %coord_3149 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %slice_3150 = cute.slice(%ptn_C, %coord_3149) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,5)">
          %iter_3151 = cute.get_iter(%slice_3150) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3152, %e1_3153 = cute.get_leaves(%iter_3151) : !cute.int_tuple<"(?,?)">
          %1263 = cute.get_scalars(%e0_3152) : !cute.int_tuple<"?">
          %1264 = cute.get_scalars(%e1_3153) : !cute.int_tuple<"?">
          %iter_3154 = cute.get_iter(%slice_3150) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3155, %e1_3156 = cute.get_leaves(%iter_3154) : !cute.int_tuple<"(?,?)">
          %1265 = cute.get_scalars(%e0_3155) : !cute.int_tuple<"?">
          %1266 = cute.get_scalars(%e1_3156) : !cute.int_tuple<"?">
          %iter_3157 = cute.get_iter(%slice_3150) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3158, %e1_3159 = cute.get_leaves(%iter_3157) : !cute.int_tuple<"(?,?)">
          %1267 = cute.get_scalars(%e0_3158) : !cute.int_tuple<"?">
          %1268 = cute.get_scalars(%e1_3159) : !cute.int_tuple<"?">
          %coord_3160 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
          %slice_3161 = cute.slice(%ptn_C, %coord_3160) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,5)">
          %iter_3162 = cute.get_iter(%slice_3161) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3163, %e1_3164 = cute.get_leaves(%iter_3162) : !cute.int_tuple<"(?,?)">
          %1269 = cute.get_scalars(%e0_3163) : !cute.int_tuple<"?">
          %1270 = cute.get_scalars(%e1_3164) : !cute.int_tuple<"?">
          %iter_3165 = cute.get_iter(%slice_3161) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3166, %e1_3167 = cute.get_leaves(%iter_3165) : !cute.int_tuple<"(?,?)">
          %1271 = cute.get_scalars(%e0_3166) : !cute.int_tuple<"?">
          %1272 = cute.get_scalars(%e1_3167) : !cute.int_tuple<"?">
          %iter_3168 = cute.get_iter(%slice_3161) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3169, %e1_3170 = cute.get_leaves(%iter_3168) : !cute.int_tuple<"(?,?)">
          %1273 = cute.get_scalars(%e0_3169) : !cute.int_tuple<"?">
          %1274 = cute.get_scalars(%e1_3170) : !cute.int_tuple<"?">
          %coord_3171 = cute.make_coord(%e0_3158) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3172 = cute.make_coord(%e1_3170) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1275 = cute.elem_less(%coord_3171, %coord_3172) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3173 = cute.get_layout(%1260) : !memref_rmem_f32_1
          %1276 = cute.get_shape(%lay_3173) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3174, %e1_3175, %e2_3176, %e3_3177 = cute.get_leaves(%1276) : !cute.shape<"((2,2),1,8)">
          %1277 = cute.get_stride(%lay_3173) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3178, %e1_3179, %e2_3180, %e3_3181 = cute.get_leaves(%1277) : !cute.stride<"((1,2),0,4)">
          %1278 = scf.if %1275 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1260) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,5)">
            cute.memref.store(%1260, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1260) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1260 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1260) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1260) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1260 : !memref_rmem_f32_1
          }
          %iter_3182 = cute.get_iter(%1278) : !memref_rmem_f32_1
          %lay_3183 = cute.get_layout(%1278) : !memref_rmem_f32_1
          %1279 = cute.get_shape(%lay_3183) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3184, %e1_3185, %e2_3186, %e3_3187 = cute.get_leaves(%1279) : !cute.shape<"((2,2),1,8)">
          %1280 = cute.get_stride(%lay_3183) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3188, %e1_3189, %e2_3190, %e3_3191 = cute.get_leaves(%1280) : !cute.stride<"((1,2),0,4)">
          %iter_3192 = cute.get_iter(%1278) : !memref_rmem_f32_1
          %iter_3193 = cute.get_iter(%1278) : !memref_rmem_f32_1
          %coord_3194 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %slice_3195 = cute.slice(%ptn_C, %coord_3194) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,6)">
          %iter_3196 = cute.get_iter(%slice_3195) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3197, %e1_3198 = cute.get_leaves(%iter_3196) : !cute.int_tuple<"(?,?)">
          %1281 = cute.get_scalars(%e0_3197) : !cute.int_tuple<"?">
          %1282 = cute.get_scalars(%e1_3198) : !cute.int_tuple<"?">
          %iter_3199 = cute.get_iter(%slice_3195) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3200, %e1_3201 = cute.get_leaves(%iter_3199) : !cute.int_tuple<"(?,?)">
          %1283 = cute.get_scalars(%e0_3200) : !cute.int_tuple<"?">
          %1284 = cute.get_scalars(%e1_3201) : !cute.int_tuple<"?">
          %iter_3202 = cute.get_iter(%slice_3195) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3203, %e1_3204 = cute.get_leaves(%iter_3202) : !cute.int_tuple<"(?,?)">
          %1285 = cute.get_scalars(%e0_3203) : !cute.int_tuple<"?">
          %1286 = cute.get_scalars(%e1_3204) : !cute.int_tuple<"?">
          %coord_3205 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
          %slice_3206 = cute.slice(%ptn_C, %coord_3205) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,6)">
          %iter_3207 = cute.get_iter(%slice_3206) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3208, %e1_3209 = cute.get_leaves(%iter_3207) : !cute.int_tuple<"(?,?)">
          %1287 = cute.get_scalars(%e0_3208) : !cute.int_tuple<"?">
          %1288 = cute.get_scalars(%e1_3209) : !cute.int_tuple<"?">
          %iter_3210 = cute.get_iter(%slice_3206) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3211, %e1_3212 = cute.get_leaves(%iter_3210) : !cute.int_tuple<"(?,?)">
          %1289 = cute.get_scalars(%e0_3211) : !cute.int_tuple<"?">
          %1290 = cute.get_scalars(%e1_3212) : !cute.int_tuple<"?">
          %iter_3213 = cute.get_iter(%slice_3206) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3214, %e1_3215 = cute.get_leaves(%iter_3213) : !cute.int_tuple<"(?,?)">
          %1291 = cute.get_scalars(%e0_3214) : !cute.int_tuple<"?">
          %1292 = cute.get_scalars(%e1_3215) : !cute.int_tuple<"?">
          %coord_3216 = cute.make_coord(%e0_3203) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3217 = cute.make_coord(%e1_3215) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1293 = cute.elem_less(%coord_3216, %coord_3217) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3218 = cute.get_layout(%1278) : !memref_rmem_f32_1
          %1294 = cute.get_shape(%lay_3218) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3219, %e1_3220, %e2_3221, %e3_3222 = cute.get_leaves(%1294) : !cute.shape<"((2,2),1,8)">
          %1295 = cute.get_stride(%lay_3218) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3223, %e1_3224, %e2_3225, %e3_3226 = cute.get_leaves(%1295) : !cute.stride<"((1,2),0,4)">
          %1296 = scf.if %1293 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1278) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,6)">
            cute.memref.store(%1278, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1278) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1278 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1278) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1278) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1278 : !memref_rmem_f32_1
          }
          %iter_3227 = cute.get_iter(%1296) : !memref_rmem_f32_1
          %lay_3228 = cute.get_layout(%1296) : !memref_rmem_f32_1
          %1297 = cute.get_shape(%lay_3228) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3229, %e1_3230, %e2_3231, %e3_3232 = cute.get_leaves(%1297) : !cute.shape<"((2,2),1,8)">
          %1298 = cute.get_stride(%lay_3228) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3233, %e1_3234, %e2_3235, %e3_3236 = cute.get_leaves(%1298) : !cute.stride<"((1,2),0,4)">
          %iter_3237 = cute.get_iter(%1296) : !memref_rmem_f32_1
          %iter_3238 = cute.get_iter(%1296) : !memref_rmem_f32_1
          %coord_3239 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %slice_3240 = cute.slice(%ptn_C, %coord_3239) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,7)">
          %iter_3241 = cute.get_iter(%slice_3240) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3242, %e1_3243 = cute.get_leaves(%iter_3241) : !cute.int_tuple<"(?,?)">
          %1299 = cute.get_scalars(%e0_3242) : !cute.int_tuple<"?">
          %1300 = cute.get_scalars(%e1_3243) : !cute.int_tuple<"?">
          %iter_3244 = cute.get_iter(%slice_3240) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3245, %e1_3246 = cute.get_leaves(%iter_3244) : !cute.int_tuple<"(?,?)">
          %1301 = cute.get_scalars(%e0_3245) : !cute.int_tuple<"?">
          %1302 = cute.get_scalars(%e1_3246) : !cute.int_tuple<"?">
          %iter_3247 = cute.get_iter(%slice_3240) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3248, %e1_3249 = cute.get_leaves(%iter_3247) : !cute.int_tuple<"(?,?)">
          %1303 = cute.get_scalars(%e0_3248) : !cute.int_tuple<"?">
          %1304 = cute.get_scalars(%e1_3249) : !cute.int_tuple<"?">
          %coord_3250 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
          %slice_3251 = cute.slice(%ptn_C, %coord_3250) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(1,0,7)">
          %iter_3252 = cute.get_iter(%slice_3251) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3253, %e1_3254 = cute.get_leaves(%iter_3252) : !cute.int_tuple<"(?,?)">
          %1305 = cute.get_scalars(%e0_3253) : !cute.int_tuple<"?">
          %1306 = cute.get_scalars(%e1_3254) : !cute.int_tuple<"?">
          %iter_3255 = cute.get_iter(%slice_3251) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3256, %e1_3257 = cute.get_leaves(%iter_3255) : !cute.int_tuple<"(?,?)">
          %1307 = cute.get_scalars(%e0_3256) : !cute.int_tuple<"?">
          %1308 = cute.get_scalars(%e1_3257) : !cute.int_tuple<"?">
          %iter_3258 = cute.get_iter(%slice_3251) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3259, %e1_3260 = cute.get_leaves(%iter_3258) : !cute.int_tuple<"(?,?)">
          %1309 = cute.get_scalars(%e0_3259) : !cute.int_tuple<"?">
          %1310 = cute.get_scalars(%e1_3260) : !cute.int_tuple<"?">
          %coord_3261 = cute.make_coord(%e0_3248) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3262 = cute.make_coord(%e1_3260) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1311 = cute.elem_less(%coord_3261, %coord_3262) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3263 = cute.get_layout(%1296) : !memref_rmem_f32_1
          %1312 = cute.get_shape(%lay_3263) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3264, %e1_3265, %e2_3266, %e3_3267 = cute.get_leaves(%1312) : !cute.shape<"((2,2),1,8)">
          %1313 = cute.get_stride(%lay_3263) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3268, %e1_3269, %e2_3270, %e3_3271 = cute.get_leaves(%1313) : !cute.stride<"((1,2),0,4)">
          %1314 = scf.if %1311 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1296) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(1,0,7)">
            cute.memref.store(%1296, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1296) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1296 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1296) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1296) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1296 : !memref_rmem_f32_1
          }
          %iter_3272 = cute.get_iter(%1314) : !memref_rmem_f32_1
          %lay_3273 = cute.get_layout(%1314) : !memref_rmem_f32_1
          %1315 = cute.get_shape(%lay_3273) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3274, %e1_3275, %e2_3276, %e3_3277 = cute.get_leaves(%1315) : !cute.shape<"((2,2),1,8)">
          %1316 = cute.get_stride(%lay_3273) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3278, %e1_3279, %e2_3280, %e3_3281 = cute.get_leaves(%1316) : !cute.stride<"((1,2),0,4)">
          %iter_3282 = cute.get_iter(%1314) : !memref_rmem_f32_1
          %iter_3283 = cute.get_iter(%1314) : !memref_rmem_f32_1
          %int_tuple_3284 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_3285 = cute.size(%int_tuple_3284) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_3286 = cute.get_leaves(%sz_3285) : !cute.int_tuple<"1">
          %int_tuple_3287 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_3288 = cute.size(%int_tuple_3287) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_3289 = cute.get_leaves(%sz_3288) : !cute.int_tuple<"8">
          %coord_3290 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %slice_3291 = cute.slice(%ptn_C, %coord_3290) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,0)">
          %iter_3292 = cute.get_iter(%slice_3291) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3293, %e1_3294 = cute.get_leaves(%iter_3292) : !cute.int_tuple<"(?,?{div=2})">
          %1317 = cute.get_scalars(%e0_3293) : !cute.int_tuple<"?">
          %1318 = cute.get_scalars(%e1_3294) : !cute.int_tuple<"?{div=2}">
          %iter_3295 = cute.get_iter(%slice_3291) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3296, %e1_3297 = cute.get_leaves(%iter_3295) : !cute.int_tuple<"(?,?{div=2})">
          %1319 = cute.get_scalars(%e0_3296) : !cute.int_tuple<"?">
          %1320 = cute.get_scalars(%e1_3297) : !cute.int_tuple<"?{div=2}">
          %iter_3298 = cute.get_iter(%slice_3291) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3299, %e1_3300 = cute.get_leaves(%iter_3298) : !cute.int_tuple<"(?,?{div=2})">
          %1321 = cute.get_scalars(%e0_3299) : !cute.int_tuple<"?">
          %1322 = cute.get_scalars(%e1_3300) : !cute.int_tuple<"?{div=2}">
          %coord_3301 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
          %slice_3302 = cute.slice(%ptn_C, %coord_3301) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,0)">
          %iter_3303 = cute.get_iter(%slice_3302) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3304, %e1_3305 = cute.get_leaves(%iter_3303) : !cute.int_tuple<"(?,?{div=2})">
          %1323 = cute.get_scalars(%e0_3304) : !cute.int_tuple<"?">
          %1324 = cute.get_scalars(%e1_3305) : !cute.int_tuple<"?{div=2}">
          %iter_3306 = cute.get_iter(%slice_3302) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3307, %e1_3308 = cute.get_leaves(%iter_3306) : !cute.int_tuple<"(?,?{div=2})">
          %1325 = cute.get_scalars(%e0_3307) : !cute.int_tuple<"?">
          %1326 = cute.get_scalars(%e1_3308) : !cute.int_tuple<"?{div=2}">
          %iter_3309 = cute.get_iter(%slice_3302) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3310, %e1_3311 = cute.get_leaves(%iter_3309) : !cute.int_tuple<"(?,?{div=2})">
          %1327 = cute.get_scalars(%e0_3310) : !cute.int_tuple<"?">
          %1328 = cute.get_scalars(%e1_3311) : !cute.int_tuple<"?{div=2}">
          %coord_3312 = cute.make_coord(%e0_3299) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3313 = cute.make_coord(%e1_3311) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1329 = cute.elem_less(%coord_3312, %coord_3313) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3314 = cute.get_layout(%1314) : !memref_rmem_f32_1
          %1330 = cute.get_shape(%lay_3314) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3315, %e1_3316, %e2_3317, %e3_3318 = cute.get_leaves(%1330) : !cute.shape<"((2,2),1,8)">
          %1331 = cute.get_stride(%lay_3314) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3319, %e1_3320, %e2_3321, %e3_3322 = cute.get_leaves(%1331) : !cute.stride<"((1,2),0,4)">
          %1332 = scf.if %1329 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1314) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
            cute.memref.store(%1314, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1314) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1314 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1314) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1314) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1314 : !memref_rmem_f32_1
          }
          %iter_3323 = cute.get_iter(%1332) : !memref_rmem_f32_1
          %lay_3324 = cute.get_layout(%1332) : !memref_rmem_f32_1
          %1333 = cute.get_shape(%lay_3324) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3325, %e1_3326, %e2_3327, %e3_3328 = cute.get_leaves(%1333) : !cute.shape<"((2,2),1,8)">
          %1334 = cute.get_stride(%lay_3324) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3329, %e1_3330, %e2_3331, %e3_3332 = cute.get_leaves(%1334) : !cute.stride<"((1,2),0,4)">
          %iter_3333 = cute.get_iter(%1332) : !memref_rmem_f32_1
          %iter_3334 = cute.get_iter(%1332) : !memref_rmem_f32_1
          %coord_3335 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %slice_3336 = cute.slice(%ptn_C, %coord_3335) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,1)">
          %iter_3337 = cute.get_iter(%slice_3336) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3338, %e1_3339 = cute.get_leaves(%iter_3337) : !cute.int_tuple<"(?,?{div=2})">
          %1335 = cute.get_scalars(%e0_3338) : !cute.int_tuple<"?">
          %1336 = cute.get_scalars(%e1_3339) : !cute.int_tuple<"?{div=2}">
          %iter_3340 = cute.get_iter(%slice_3336) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3341, %e1_3342 = cute.get_leaves(%iter_3340) : !cute.int_tuple<"(?,?{div=2})">
          %1337 = cute.get_scalars(%e0_3341) : !cute.int_tuple<"?">
          %1338 = cute.get_scalars(%e1_3342) : !cute.int_tuple<"?{div=2}">
          %iter_3343 = cute.get_iter(%slice_3336) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3344, %e1_3345 = cute.get_leaves(%iter_3343) : !cute.int_tuple<"(?,?{div=2})">
          %1339 = cute.get_scalars(%e0_3344) : !cute.int_tuple<"?">
          %1340 = cute.get_scalars(%e1_3345) : !cute.int_tuple<"?{div=2}">
          %coord_3346 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
          %slice_3347 = cute.slice(%ptn_C, %coord_3346) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,1)">
          %iter_3348 = cute.get_iter(%slice_3347) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3349, %e1_3350 = cute.get_leaves(%iter_3348) : !cute.int_tuple<"(?,?{div=2})">
          %1341 = cute.get_scalars(%e0_3349) : !cute.int_tuple<"?">
          %1342 = cute.get_scalars(%e1_3350) : !cute.int_tuple<"?{div=2}">
          %iter_3351 = cute.get_iter(%slice_3347) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3352, %e1_3353 = cute.get_leaves(%iter_3351) : !cute.int_tuple<"(?,?{div=2})">
          %1343 = cute.get_scalars(%e0_3352) : !cute.int_tuple<"?">
          %1344 = cute.get_scalars(%e1_3353) : !cute.int_tuple<"?{div=2}">
          %iter_3354 = cute.get_iter(%slice_3347) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3355, %e1_3356 = cute.get_leaves(%iter_3354) : !cute.int_tuple<"(?,?{div=2})">
          %1345 = cute.get_scalars(%e0_3355) : !cute.int_tuple<"?">
          %1346 = cute.get_scalars(%e1_3356) : !cute.int_tuple<"?{div=2}">
          %coord_3357 = cute.make_coord(%e0_3344) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3358 = cute.make_coord(%e1_3356) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1347 = cute.elem_less(%coord_3357, %coord_3358) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3359 = cute.get_layout(%1332) : !memref_rmem_f32_1
          %1348 = cute.get_shape(%lay_3359) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3360, %e1_3361, %e2_3362, %e3_3363 = cute.get_leaves(%1348) : !cute.shape<"((2,2),1,8)">
          %1349 = cute.get_stride(%lay_3359) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3364, %e1_3365, %e2_3366, %e3_3367 = cute.get_leaves(%1349) : !cute.stride<"((1,2),0,4)">
          %1350 = scf.if %1347 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1332) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,1)">
            cute.memref.store(%1332, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1332) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1332 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1332) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1332) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1332 : !memref_rmem_f32_1
          }
          %iter_3368 = cute.get_iter(%1350) : !memref_rmem_f32_1
          %lay_3369 = cute.get_layout(%1350) : !memref_rmem_f32_1
          %1351 = cute.get_shape(%lay_3369) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3370, %e1_3371, %e2_3372, %e3_3373 = cute.get_leaves(%1351) : !cute.shape<"((2,2),1,8)">
          %1352 = cute.get_stride(%lay_3369) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3374, %e1_3375, %e2_3376, %e3_3377 = cute.get_leaves(%1352) : !cute.stride<"((1,2),0,4)">
          %iter_3378 = cute.get_iter(%1350) : !memref_rmem_f32_1
          %iter_3379 = cute.get_iter(%1350) : !memref_rmem_f32_1
          %coord_3380 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %slice_3381 = cute.slice(%ptn_C, %coord_3380) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,2)">
          %iter_3382 = cute.get_iter(%slice_3381) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3383, %e1_3384 = cute.get_leaves(%iter_3382) : !cute.int_tuple<"(?,?{div=2})">
          %1353 = cute.get_scalars(%e0_3383) : !cute.int_tuple<"?">
          %1354 = cute.get_scalars(%e1_3384) : !cute.int_tuple<"?{div=2}">
          %iter_3385 = cute.get_iter(%slice_3381) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3386, %e1_3387 = cute.get_leaves(%iter_3385) : !cute.int_tuple<"(?,?{div=2})">
          %1355 = cute.get_scalars(%e0_3386) : !cute.int_tuple<"?">
          %1356 = cute.get_scalars(%e1_3387) : !cute.int_tuple<"?{div=2}">
          %iter_3388 = cute.get_iter(%slice_3381) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3389, %e1_3390 = cute.get_leaves(%iter_3388) : !cute.int_tuple<"(?,?{div=2})">
          %1357 = cute.get_scalars(%e0_3389) : !cute.int_tuple<"?">
          %1358 = cute.get_scalars(%e1_3390) : !cute.int_tuple<"?{div=2}">
          %coord_3391 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
          %slice_3392 = cute.slice(%ptn_C, %coord_3391) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,2)">
          %iter_3393 = cute.get_iter(%slice_3392) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3394, %e1_3395 = cute.get_leaves(%iter_3393) : !cute.int_tuple<"(?,?{div=2})">
          %1359 = cute.get_scalars(%e0_3394) : !cute.int_tuple<"?">
          %1360 = cute.get_scalars(%e1_3395) : !cute.int_tuple<"?{div=2}">
          %iter_3396 = cute.get_iter(%slice_3392) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3397, %e1_3398 = cute.get_leaves(%iter_3396) : !cute.int_tuple<"(?,?{div=2})">
          %1361 = cute.get_scalars(%e0_3397) : !cute.int_tuple<"?">
          %1362 = cute.get_scalars(%e1_3398) : !cute.int_tuple<"?{div=2}">
          %iter_3399 = cute.get_iter(%slice_3392) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3400, %e1_3401 = cute.get_leaves(%iter_3399) : !cute.int_tuple<"(?,?{div=2})">
          %1363 = cute.get_scalars(%e0_3400) : !cute.int_tuple<"?">
          %1364 = cute.get_scalars(%e1_3401) : !cute.int_tuple<"?{div=2}">
          %coord_3402 = cute.make_coord(%e0_3389) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3403 = cute.make_coord(%e1_3401) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1365 = cute.elem_less(%coord_3402, %coord_3403) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3404 = cute.get_layout(%1350) : !memref_rmem_f32_1
          %1366 = cute.get_shape(%lay_3404) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3405, %e1_3406, %e2_3407, %e3_3408 = cute.get_leaves(%1366) : !cute.shape<"((2,2),1,8)">
          %1367 = cute.get_stride(%lay_3404) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3409, %e1_3410, %e2_3411, %e3_3412 = cute.get_leaves(%1367) : !cute.stride<"((1,2),0,4)">
          %1368 = scf.if %1365 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1350) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,2)">
            cute.memref.store(%1350, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1350) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1350 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1350) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1350) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1350 : !memref_rmem_f32_1
          }
          %iter_3413 = cute.get_iter(%1368) : !memref_rmem_f32_1
          %lay_3414 = cute.get_layout(%1368) : !memref_rmem_f32_1
          %1369 = cute.get_shape(%lay_3414) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3415, %e1_3416, %e2_3417, %e3_3418 = cute.get_leaves(%1369) : !cute.shape<"((2,2),1,8)">
          %1370 = cute.get_stride(%lay_3414) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3419, %e1_3420, %e2_3421, %e3_3422 = cute.get_leaves(%1370) : !cute.stride<"((1,2),0,4)">
          %iter_3423 = cute.get_iter(%1368) : !memref_rmem_f32_1
          %iter_3424 = cute.get_iter(%1368) : !memref_rmem_f32_1
          %coord_3425 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %slice_3426 = cute.slice(%ptn_C, %coord_3425) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,3)">
          %iter_3427 = cute.get_iter(%slice_3426) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3428, %e1_3429 = cute.get_leaves(%iter_3427) : !cute.int_tuple<"(?,?{div=2})">
          %1371 = cute.get_scalars(%e0_3428) : !cute.int_tuple<"?">
          %1372 = cute.get_scalars(%e1_3429) : !cute.int_tuple<"?{div=2}">
          %iter_3430 = cute.get_iter(%slice_3426) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3431, %e1_3432 = cute.get_leaves(%iter_3430) : !cute.int_tuple<"(?,?{div=2})">
          %1373 = cute.get_scalars(%e0_3431) : !cute.int_tuple<"?">
          %1374 = cute.get_scalars(%e1_3432) : !cute.int_tuple<"?{div=2}">
          %iter_3433 = cute.get_iter(%slice_3426) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3434, %e1_3435 = cute.get_leaves(%iter_3433) : !cute.int_tuple<"(?,?{div=2})">
          %1375 = cute.get_scalars(%e0_3434) : !cute.int_tuple<"?">
          %1376 = cute.get_scalars(%e1_3435) : !cute.int_tuple<"?{div=2}">
          %coord_3436 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
          %slice_3437 = cute.slice(%ptn_C, %coord_3436) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,3)">
          %iter_3438 = cute.get_iter(%slice_3437) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3439, %e1_3440 = cute.get_leaves(%iter_3438) : !cute.int_tuple<"(?,?{div=2})">
          %1377 = cute.get_scalars(%e0_3439) : !cute.int_tuple<"?">
          %1378 = cute.get_scalars(%e1_3440) : !cute.int_tuple<"?{div=2}">
          %iter_3441 = cute.get_iter(%slice_3437) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3442, %e1_3443 = cute.get_leaves(%iter_3441) : !cute.int_tuple<"(?,?{div=2})">
          %1379 = cute.get_scalars(%e0_3442) : !cute.int_tuple<"?">
          %1380 = cute.get_scalars(%e1_3443) : !cute.int_tuple<"?{div=2}">
          %iter_3444 = cute.get_iter(%slice_3437) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3445, %e1_3446 = cute.get_leaves(%iter_3444) : !cute.int_tuple<"(?,?{div=2})">
          %1381 = cute.get_scalars(%e0_3445) : !cute.int_tuple<"?">
          %1382 = cute.get_scalars(%e1_3446) : !cute.int_tuple<"?{div=2}">
          %coord_3447 = cute.make_coord(%e0_3434) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3448 = cute.make_coord(%e1_3446) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1383 = cute.elem_less(%coord_3447, %coord_3448) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3449 = cute.get_layout(%1368) : !memref_rmem_f32_1
          %1384 = cute.get_shape(%lay_3449) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3450, %e1_3451, %e2_3452, %e3_3453 = cute.get_leaves(%1384) : !cute.shape<"((2,2),1,8)">
          %1385 = cute.get_stride(%lay_3449) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3454, %e1_3455, %e2_3456, %e3_3457 = cute.get_leaves(%1385) : !cute.stride<"((1,2),0,4)">
          %1386 = scf.if %1383 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1368) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,3)">
            cute.memref.store(%1368, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1368) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1368 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1368) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1368) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1368 : !memref_rmem_f32_1
          }
          %iter_3458 = cute.get_iter(%1386) : !memref_rmem_f32_1
          %lay_3459 = cute.get_layout(%1386) : !memref_rmem_f32_1
          %1387 = cute.get_shape(%lay_3459) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3460, %e1_3461, %e2_3462, %e3_3463 = cute.get_leaves(%1387) : !cute.shape<"((2,2),1,8)">
          %1388 = cute.get_stride(%lay_3459) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3464, %e1_3465, %e2_3466, %e3_3467 = cute.get_leaves(%1388) : !cute.stride<"((1,2),0,4)">
          %iter_3468 = cute.get_iter(%1386) : !memref_rmem_f32_1
          %iter_3469 = cute.get_iter(%1386) : !memref_rmem_f32_1
          %coord_3470 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %slice_3471 = cute.slice(%ptn_C, %coord_3470) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,4)">
          %iter_3472 = cute.get_iter(%slice_3471) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3473, %e1_3474 = cute.get_leaves(%iter_3472) : !cute.int_tuple<"(?,?{div=2})">
          %1389 = cute.get_scalars(%e0_3473) : !cute.int_tuple<"?">
          %1390 = cute.get_scalars(%e1_3474) : !cute.int_tuple<"?{div=2}">
          %iter_3475 = cute.get_iter(%slice_3471) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3476, %e1_3477 = cute.get_leaves(%iter_3475) : !cute.int_tuple<"(?,?{div=2})">
          %1391 = cute.get_scalars(%e0_3476) : !cute.int_tuple<"?">
          %1392 = cute.get_scalars(%e1_3477) : !cute.int_tuple<"?{div=2}">
          %iter_3478 = cute.get_iter(%slice_3471) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3479, %e1_3480 = cute.get_leaves(%iter_3478) : !cute.int_tuple<"(?,?{div=2})">
          %1393 = cute.get_scalars(%e0_3479) : !cute.int_tuple<"?">
          %1394 = cute.get_scalars(%e1_3480) : !cute.int_tuple<"?{div=2}">
          %coord_3481 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
          %slice_3482 = cute.slice(%ptn_C, %coord_3481) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,4)">
          %iter_3483 = cute.get_iter(%slice_3482) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3484, %e1_3485 = cute.get_leaves(%iter_3483) : !cute.int_tuple<"(?,?{div=2})">
          %1395 = cute.get_scalars(%e0_3484) : !cute.int_tuple<"?">
          %1396 = cute.get_scalars(%e1_3485) : !cute.int_tuple<"?{div=2}">
          %iter_3486 = cute.get_iter(%slice_3482) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3487, %e1_3488 = cute.get_leaves(%iter_3486) : !cute.int_tuple<"(?,?{div=2})">
          %1397 = cute.get_scalars(%e0_3487) : !cute.int_tuple<"?">
          %1398 = cute.get_scalars(%e1_3488) : !cute.int_tuple<"?{div=2}">
          %iter_3489 = cute.get_iter(%slice_3482) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3490, %e1_3491 = cute.get_leaves(%iter_3489) : !cute.int_tuple<"(?,?{div=2})">
          %1399 = cute.get_scalars(%e0_3490) : !cute.int_tuple<"?">
          %1400 = cute.get_scalars(%e1_3491) : !cute.int_tuple<"?{div=2}">
          %coord_3492 = cute.make_coord(%e0_3479) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3493 = cute.make_coord(%e1_3491) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1401 = cute.elem_less(%coord_3492, %coord_3493) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3494 = cute.get_layout(%1386) : !memref_rmem_f32_1
          %1402 = cute.get_shape(%lay_3494) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3495, %e1_3496, %e2_3497, %e3_3498 = cute.get_leaves(%1402) : !cute.shape<"((2,2),1,8)">
          %1403 = cute.get_stride(%lay_3494) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3499, %e1_3500, %e2_3501, %e3_3502 = cute.get_leaves(%1403) : !cute.stride<"((1,2),0,4)">
          %1404 = scf.if %1401 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1386) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,4)">
            cute.memref.store(%1386, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1386) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1386 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1386) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1386) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1386 : !memref_rmem_f32_1
          }
          %iter_3503 = cute.get_iter(%1404) : !memref_rmem_f32_1
          %lay_3504 = cute.get_layout(%1404) : !memref_rmem_f32_1
          %1405 = cute.get_shape(%lay_3504) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3505, %e1_3506, %e2_3507, %e3_3508 = cute.get_leaves(%1405) : !cute.shape<"((2,2),1,8)">
          %1406 = cute.get_stride(%lay_3504) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3509, %e1_3510, %e2_3511, %e3_3512 = cute.get_leaves(%1406) : !cute.stride<"((1,2),0,4)">
          %iter_3513 = cute.get_iter(%1404) : !memref_rmem_f32_1
          %iter_3514 = cute.get_iter(%1404) : !memref_rmem_f32_1
          %coord_3515 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %slice_3516 = cute.slice(%ptn_C, %coord_3515) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,5)">
          %iter_3517 = cute.get_iter(%slice_3516) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3518, %e1_3519 = cute.get_leaves(%iter_3517) : !cute.int_tuple<"(?,?{div=2})">
          %1407 = cute.get_scalars(%e0_3518) : !cute.int_tuple<"?">
          %1408 = cute.get_scalars(%e1_3519) : !cute.int_tuple<"?{div=2}">
          %iter_3520 = cute.get_iter(%slice_3516) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3521, %e1_3522 = cute.get_leaves(%iter_3520) : !cute.int_tuple<"(?,?{div=2})">
          %1409 = cute.get_scalars(%e0_3521) : !cute.int_tuple<"?">
          %1410 = cute.get_scalars(%e1_3522) : !cute.int_tuple<"?{div=2}">
          %iter_3523 = cute.get_iter(%slice_3516) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3524, %e1_3525 = cute.get_leaves(%iter_3523) : !cute.int_tuple<"(?,?{div=2})">
          %1411 = cute.get_scalars(%e0_3524) : !cute.int_tuple<"?">
          %1412 = cute.get_scalars(%e1_3525) : !cute.int_tuple<"?{div=2}">
          %coord_3526 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
          %slice_3527 = cute.slice(%ptn_C, %coord_3526) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,5)">
          %iter_3528 = cute.get_iter(%slice_3527) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3529, %e1_3530 = cute.get_leaves(%iter_3528) : !cute.int_tuple<"(?,?{div=2})">
          %1413 = cute.get_scalars(%e0_3529) : !cute.int_tuple<"?">
          %1414 = cute.get_scalars(%e1_3530) : !cute.int_tuple<"?{div=2}">
          %iter_3531 = cute.get_iter(%slice_3527) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3532, %e1_3533 = cute.get_leaves(%iter_3531) : !cute.int_tuple<"(?,?{div=2})">
          %1415 = cute.get_scalars(%e0_3532) : !cute.int_tuple<"?">
          %1416 = cute.get_scalars(%e1_3533) : !cute.int_tuple<"?{div=2}">
          %iter_3534 = cute.get_iter(%slice_3527) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3535, %e1_3536 = cute.get_leaves(%iter_3534) : !cute.int_tuple<"(?,?{div=2})">
          %1417 = cute.get_scalars(%e0_3535) : !cute.int_tuple<"?">
          %1418 = cute.get_scalars(%e1_3536) : !cute.int_tuple<"?{div=2}">
          %coord_3537 = cute.make_coord(%e0_3524) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3538 = cute.make_coord(%e1_3536) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1419 = cute.elem_less(%coord_3537, %coord_3538) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3539 = cute.get_layout(%1404) : !memref_rmem_f32_1
          %1420 = cute.get_shape(%lay_3539) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3540, %e1_3541, %e2_3542, %e3_3543 = cute.get_leaves(%1420) : !cute.shape<"((2,2),1,8)">
          %1421 = cute.get_stride(%lay_3539) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3544, %e1_3545, %e2_3546, %e3_3547 = cute.get_leaves(%1421) : !cute.stride<"((1,2),0,4)">
          %1422 = scf.if %1419 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1404) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,5)">
            cute.memref.store(%1404, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1404) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1404 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1404) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1404) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1404 : !memref_rmem_f32_1
          }
          %iter_3548 = cute.get_iter(%1422) : !memref_rmem_f32_1
          %lay_3549 = cute.get_layout(%1422) : !memref_rmem_f32_1
          %1423 = cute.get_shape(%lay_3549) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3550, %e1_3551, %e2_3552, %e3_3553 = cute.get_leaves(%1423) : !cute.shape<"((2,2),1,8)">
          %1424 = cute.get_stride(%lay_3549) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3554, %e1_3555, %e2_3556, %e3_3557 = cute.get_leaves(%1424) : !cute.stride<"((1,2),0,4)">
          %iter_3558 = cute.get_iter(%1422) : !memref_rmem_f32_1
          %iter_3559 = cute.get_iter(%1422) : !memref_rmem_f32_1
          %coord_3560 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %slice_3561 = cute.slice(%ptn_C, %coord_3560) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,6)">
          %iter_3562 = cute.get_iter(%slice_3561) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3563, %e1_3564 = cute.get_leaves(%iter_3562) : !cute.int_tuple<"(?,?{div=2})">
          %1425 = cute.get_scalars(%e0_3563) : !cute.int_tuple<"?">
          %1426 = cute.get_scalars(%e1_3564) : !cute.int_tuple<"?{div=2}">
          %iter_3565 = cute.get_iter(%slice_3561) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3566, %e1_3567 = cute.get_leaves(%iter_3565) : !cute.int_tuple<"(?,?{div=2})">
          %1427 = cute.get_scalars(%e0_3566) : !cute.int_tuple<"?">
          %1428 = cute.get_scalars(%e1_3567) : !cute.int_tuple<"?{div=2}">
          %iter_3568 = cute.get_iter(%slice_3561) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3569, %e1_3570 = cute.get_leaves(%iter_3568) : !cute.int_tuple<"(?,?{div=2})">
          %1429 = cute.get_scalars(%e0_3569) : !cute.int_tuple<"?">
          %1430 = cute.get_scalars(%e1_3570) : !cute.int_tuple<"?{div=2}">
          %coord_3571 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
          %slice_3572 = cute.slice(%ptn_C, %coord_3571) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,6)">
          %iter_3573 = cute.get_iter(%slice_3572) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3574, %e1_3575 = cute.get_leaves(%iter_3573) : !cute.int_tuple<"(?,?{div=2})">
          %1431 = cute.get_scalars(%e0_3574) : !cute.int_tuple<"?">
          %1432 = cute.get_scalars(%e1_3575) : !cute.int_tuple<"?{div=2}">
          %iter_3576 = cute.get_iter(%slice_3572) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3577, %e1_3578 = cute.get_leaves(%iter_3576) : !cute.int_tuple<"(?,?{div=2})">
          %1433 = cute.get_scalars(%e0_3577) : !cute.int_tuple<"?">
          %1434 = cute.get_scalars(%e1_3578) : !cute.int_tuple<"?{div=2}">
          %iter_3579 = cute.get_iter(%slice_3572) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3580, %e1_3581 = cute.get_leaves(%iter_3579) : !cute.int_tuple<"(?,?{div=2})">
          %1435 = cute.get_scalars(%e0_3580) : !cute.int_tuple<"?">
          %1436 = cute.get_scalars(%e1_3581) : !cute.int_tuple<"?{div=2}">
          %coord_3582 = cute.make_coord(%e0_3569) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3583 = cute.make_coord(%e1_3581) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1437 = cute.elem_less(%coord_3582, %coord_3583) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3584 = cute.get_layout(%1422) : !memref_rmem_f32_1
          %1438 = cute.get_shape(%lay_3584) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3585, %e1_3586, %e2_3587, %e3_3588 = cute.get_leaves(%1438) : !cute.shape<"((2,2),1,8)">
          %1439 = cute.get_stride(%lay_3584) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3589, %e1_3590, %e2_3591, %e3_3592 = cute.get_leaves(%1439) : !cute.stride<"((1,2),0,4)">
          %1440 = scf.if %1437 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1422) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,6)">
            cute.memref.store(%1422, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1422) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1422 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1422) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1422) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1422 : !memref_rmem_f32_1
          }
          %iter_3593 = cute.get_iter(%1440) : !memref_rmem_f32_1
          %lay_3594 = cute.get_layout(%1440) : !memref_rmem_f32_1
          %1441 = cute.get_shape(%lay_3594) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3595, %e1_3596, %e2_3597, %e3_3598 = cute.get_leaves(%1441) : !cute.shape<"((2,2),1,8)">
          %1442 = cute.get_stride(%lay_3594) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3599, %e1_3600, %e2_3601, %e3_3602 = cute.get_leaves(%1442) : !cute.stride<"((1,2),0,4)">
          %iter_3603 = cute.get_iter(%1440) : !memref_rmem_f32_1
          %iter_3604 = cute.get_iter(%1440) : !memref_rmem_f32_1
          %coord_3605 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %slice_3606 = cute.slice(%ptn_C, %coord_3605) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,7)">
          %iter_3607 = cute.get_iter(%slice_3606) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3608, %e1_3609 = cute.get_leaves(%iter_3607) : !cute.int_tuple<"(?,?{div=2})">
          %1443 = cute.get_scalars(%e0_3608) : !cute.int_tuple<"?">
          %1444 = cute.get_scalars(%e1_3609) : !cute.int_tuple<"?{div=2}">
          %iter_3610 = cute.get_iter(%slice_3606) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3611, %e1_3612 = cute.get_leaves(%iter_3610) : !cute.int_tuple<"(?,?{div=2})">
          %1445 = cute.get_scalars(%e0_3611) : !cute.int_tuple<"?">
          %1446 = cute.get_scalars(%e1_3612) : !cute.int_tuple<"?{div=2}">
          %iter_3613 = cute.get_iter(%slice_3606) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3614, %e1_3615 = cute.get_leaves(%iter_3613) : !cute.int_tuple<"(?,?{div=2})">
          %1447 = cute.get_scalars(%e0_3614) : !cute.int_tuple<"?">
          %1448 = cute.get_scalars(%e1_3615) : !cute.int_tuple<"?{div=2}">
          %coord_3616 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
          %slice_3617 = cute.slice(%ptn_C, %coord_3616) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(2,0,7)">
          %iter_3618 = cute.get_iter(%slice_3617) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3619, %e1_3620 = cute.get_leaves(%iter_3618) : !cute.int_tuple<"(?,?{div=2})">
          %1449 = cute.get_scalars(%e0_3619) : !cute.int_tuple<"?">
          %1450 = cute.get_scalars(%e1_3620) : !cute.int_tuple<"?{div=2}">
          %iter_3621 = cute.get_iter(%slice_3617) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3622, %e1_3623 = cute.get_leaves(%iter_3621) : !cute.int_tuple<"(?,?{div=2})">
          %1451 = cute.get_scalars(%e0_3622) : !cute.int_tuple<"?">
          %1452 = cute.get_scalars(%e1_3623) : !cute.int_tuple<"?{div=2}">
          %iter_3624 = cute.get_iter(%slice_3617) : !cute.coord_tensor<"(?,?{div=2})", "():()">
          %e0_3625, %e1_3626 = cute.get_leaves(%iter_3624) : !cute.int_tuple<"(?,?{div=2})">
          %1453 = cute.get_scalars(%e0_3625) : !cute.int_tuple<"?">
          %1454 = cute.get_scalars(%e1_3626) : !cute.int_tuple<"?{div=2}">
          %coord_3627 = cute.make_coord(%e0_3614) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3628 = cute.make_coord(%e1_3626) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %1455 = cute.elem_less(%coord_3627, %coord_3628) : !cute.coord<"?">, !cute.coord<"?{div=2}">
          %lay_3629 = cute.get_layout(%1440) : !memref_rmem_f32_1
          %1456 = cute.get_shape(%lay_3629) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3630, %e1_3631, %e2_3632, %e3_3633 = cute.get_leaves(%1456) : !cute.shape<"((2,2),1,8)">
          %1457 = cute.get_stride(%lay_3629) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3634, %e1_3635, %e2_3636, %e3_3637 = cute.get_leaves(%1457) : !cute.stride<"((1,2),0,4)">
          %1458 = scf.if %1455 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1440) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(2,0,7)">
            cute.memref.store(%1440, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1440) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1440 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1440) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1440) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1440 : !memref_rmem_f32_1
          }
          %iter_3638 = cute.get_iter(%1458) : !memref_rmem_f32_1
          %lay_3639 = cute.get_layout(%1458) : !memref_rmem_f32_1
          %1459 = cute.get_shape(%lay_3639) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3640, %e1_3641, %e2_3642, %e3_3643 = cute.get_leaves(%1459) : !cute.shape<"((2,2),1,8)">
          %1460 = cute.get_stride(%lay_3639) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3644, %e1_3645, %e2_3646, %e3_3647 = cute.get_leaves(%1460) : !cute.stride<"((1,2),0,4)">
          %iter_3648 = cute.get_iter(%1458) : !memref_rmem_f32_1
          %iter_3649 = cute.get_iter(%1458) : !memref_rmem_f32_1
          %int_tuple_3650 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %sz_3651 = cute.size(%int_tuple_3650) : (!cute.int_tuple<"1">) -> !cute.int_tuple<"1">
          %e0_3652 = cute.get_leaves(%sz_3651) : !cute.int_tuple<"1">
          %int_tuple_3653 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %sz_3654 = cute.size(%int_tuple_3653) : (!cute.int_tuple<"8">) -> !cute.int_tuple<"8">
          %e0_3655 = cute.get_leaves(%sz_3654) : !cute.int_tuple<"8">
          %coord_3656 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %slice_3657 = cute.slice(%ptn_C, %coord_3656) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,0)">
          %iter_3658 = cute.get_iter(%slice_3657) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3659, %e1_3660 = cute.get_leaves(%iter_3658) : !cute.int_tuple<"(?,?)">
          %1461 = cute.get_scalars(%e0_3659) : !cute.int_tuple<"?">
          %1462 = cute.get_scalars(%e1_3660) : !cute.int_tuple<"?">
          %iter_3661 = cute.get_iter(%slice_3657) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3662, %e1_3663 = cute.get_leaves(%iter_3661) : !cute.int_tuple<"(?,?)">
          %1463 = cute.get_scalars(%e0_3662) : !cute.int_tuple<"?">
          %1464 = cute.get_scalars(%e1_3663) : !cute.int_tuple<"?">
          %iter_3664 = cute.get_iter(%slice_3657) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3665, %e1_3666 = cute.get_leaves(%iter_3664) : !cute.int_tuple<"(?,?)">
          %1465 = cute.get_scalars(%e0_3665) : !cute.int_tuple<"?">
          %1466 = cute.get_scalars(%e1_3666) : !cute.int_tuple<"?">
          %coord_3667 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
          %slice_3668 = cute.slice(%ptn_C, %coord_3667) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,0)">
          %iter_3669 = cute.get_iter(%slice_3668) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3670, %e1_3671 = cute.get_leaves(%iter_3669) : !cute.int_tuple<"(?,?)">
          %1467 = cute.get_scalars(%e0_3670) : !cute.int_tuple<"?">
          %1468 = cute.get_scalars(%e1_3671) : !cute.int_tuple<"?">
          %iter_3672 = cute.get_iter(%slice_3668) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3673, %e1_3674 = cute.get_leaves(%iter_3672) : !cute.int_tuple<"(?,?)">
          %1469 = cute.get_scalars(%e0_3673) : !cute.int_tuple<"?">
          %1470 = cute.get_scalars(%e1_3674) : !cute.int_tuple<"?">
          %iter_3675 = cute.get_iter(%slice_3668) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3676, %e1_3677 = cute.get_leaves(%iter_3675) : !cute.int_tuple<"(?,?)">
          %1471 = cute.get_scalars(%e0_3676) : !cute.int_tuple<"?">
          %1472 = cute.get_scalars(%e1_3677) : !cute.int_tuple<"?">
          %coord_3678 = cute.make_coord(%e0_3665) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3679 = cute.make_coord(%e1_3677) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1473 = cute.elem_less(%coord_3678, %coord_3679) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3680 = cute.get_layout(%1458) : !memref_rmem_f32_1
          %1474 = cute.get_shape(%lay_3680) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3681, %e1_3682, %e2_3683, %e3_3684 = cute.get_leaves(%1474) : !cute.shape<"((2,2),1,8)">
          %1475 = cute.get_stride(%lay_3680) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3685, %e1_3686, %e2_3687, %e3_3688 = cute.get_leaves(%1475) : !cute.stride<"((1,2),0,4)">
          %1476 = scf.if %1473 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1458) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
            cute.memref.store(%1458, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1458) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1458 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1458) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1458) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1458 : !memref_rmem_f32_1
          }
          %iter_3689 = cute.get_iter(%1476) : !memref_rmem_f32_1
          %lay_3690 = cute.get_layout(%1476) : !memref_rmem_f32_1
          %1477 = cute.get_shape(%lay_3690) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3691, %e1_3692, %e2_3693, %e3_3694 = cute.get_leaves(%1477) : !cute.shape<"((2,2),1,8)">
          %1478 = cute.get_stride(%lay_3690) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3695, %e1_3696, %e2_3697, %e3_3698 = cute.get_leaves(%1478) : !cute.stride<"((1,2),0,4)">
          %iter_3699 = cute.get_iter(%1476) : !memref_rmem_f32_1
          %iter_3700 = cute.get_iter(%1476) : !memref_rmem_f32_1
          %coord_3701 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %slice_3702 = cute.slice(%ptn_C, %coord_3701) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,1)">
          %iter_3703 = cute.get_iter(%slice_3702) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3704, %e1_3705 = cute.get_leaves(%iter_3703) : !cute.int_tuple<"(?,?)">
          %1479 = cute.get_scalars(%e0_3704) : !cute.int_tuple<"?">
          %1480 = cute.get_scalars(%e1_3705) : !cute.int_tuple<"?">
          %iter_3706 = cute.get_iter(%slice_3702) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3707, %e1_3708 = cute.get_leaves(%iter_3706) : !cute.int_tuple<"(?,?)">
          %1481 = cute.get_scalars(%e0_3707) : !cute.int_tuple<"?">
          %1482 = cute.get_scalars(%e1_3708) : !cute.int_tuple<"?">
          %iter_3709 = cute.get_iter(%slice_3702) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3710, %e1_3711 = cute.get_leaves(%iter_3709) : !cute.int_tuple<"(?,?)">
          %1483 = cute.get_scalars(%e0_3710) : !cute.int_tuple<"?">
          %1484 = cute.get_scalars(%e1_3711) : !cute.int_tuple<"?">
          %coord_3712 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
          %slice_3713 = cute.slice(%ptn_C, %coord_3712) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,1)">
          %iter_3714 = cute.get_iter(%slice_3713) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3715, %e1_3716 = cute.get_leaves(%iter_3714) : !cute.int_tuple<"(?,?)">
          %1485 = cute.get_scalars(%e0_3715) : !cute.int_tuple<"?">
          %1486 = cute.get_scalars(%e1_3716) : !cute.int_tuple<"?">
          %iter_3717 = cute.get_iter(%slice_3713) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3718, %e1_3719 = cute.get_leaves(%iter_3717) : !cute.int_tuple<"(?,?)">
          %1487 = cute.get_scalars(%e0_3718) : !cute.int_tuple<"?">
          %1488 = cute.get_scalars(%e1_3719) : !cute.int_tuple<"?">
          %iter_3720 = cute.get_iter(%slice_3713) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3721, %e1_3722 = cute.get_leaves(%iter_3720) : !cute.int_tuple<"(?,?)">
          %1489 = cute.get_scalars(%e0_3721) : !cute.int_tuple<"?">
          %1490 = cute.get_scalars(%e1_3722) : !cute.int_tuple<"?">
          %coord_3723 = cute.make_coord(%e0_3710) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3724 = cute.make_coord(%e1_3722) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1491 = cute.elem_less(%coord_3723, %coord_3724) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3725 = cute.get_layout(%1476) : !memref_rmem_f32_1
          %1492 = cute.get_shape(%lay_3725) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3726, %e1_3727, %e2_3728, %e3_3729 = cute.get_leaves(%1492) : !cute.shape<"((2,2),1,8)">
          %1493 = cute.get_stride(%lay_3725) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3730, %e1_3731, %e2_3732, %e3_3733 = cute.get_leaves(%1493) : !cute.stride<"((1,2),0,4)">
          %1494 = scf.if %1491 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1476) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,1)">
            cute.memref.store(%1476, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1476) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1476 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1476) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1476) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1476 : !memref_rmem_f32_1
          }
          %iter_3734 = cute.get_iter(%1494) : !memref_rmem_f32_1
          %lay_3735 = cute.get_layout(%1494) : !memref_rmem_f32_1
          %1495 = cute.get_shape(%lay_3735) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3736, %e1_3737, %e2_3738, %e3_3739 = cute.get_leaves(%1495) : !cute.shape<"((2,2),1,8)">
          %1496 = cute.get_stride(%lay_3735) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3740, %e1_3741, %e2_3742, %e3_3743 = cute.get_leaves(%1496) : !cute.stride<"((1,2),0,4)">
          %iter_3744 = cute.get_iter(%1494) : !memref_rmem_f32_1
          %iter_3745 = cute.get_iter(%1494) : !memref_rmem_f32_1
          %coord_3746 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %slice_3747 = cute.slice(%ptn_C, %coord_3746) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,2)">
          %iter_3748 = cute.get_iter(%slice_3747) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3749, %e1_3750 = cute.get_leaves(%iter_3748) : !cute.int_tuple<"(?,?)">
          %1497 = cute.get_scalars(%e0_3749) : !cute.int_tuple<"?">
          %1498 = cute.get_scalars(%e1_3750) : !cute.int_tuple<"?">
          %iter_3751 = cute.get_iter(%slice_3747) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3752, %e1_3753 = cute.get_leaves(%iter_3751) : !cute.int_tuple<"(?,?)">
          %1499 = cute.get_scalars(%e0_3752) : !cute.int_tuple<"?">
          %1500 = cute.get_scalars(%e1_3753) : !cute.int_tuple<"?">
          %iter_3754 = cute.get_iter(%slice_3747) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3755, %e1_3756 = cute.get_leaves(%iter_3754) : !cute.int_tuple<"(?,?)">
          %1501 = cute.get_scalars(%e0_3755) : !cute.int_tuple<"?">
          %1502 = cute.get_scalars(%e1_3756) : !cute.int_tuple<"?">
          %coord_3757 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
          %slice_3758 = cute.slice(%ptn_C, %coord_3757) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,2)">
          %iter_3759 = cute.get_iter(%slice_3758) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3760, %e1_3761 = cute.get_leaves(%iter_3759) : !cute.int_tuple<"(?,?)">
          %1503 = cute.get_scalars(%e0_3760) : !cute.int_tuple<"?">
          %1504 = cute.get_scalars(%e1_3761) : !cute.int_tuple<"?">
          %iter_3762 = cute.get_iter(%slice_3758) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3763, %e1_3764 = cute.get_leaves(%iter_3762) : !cute.int_tuple<"(?,?)">
          %1505 = cute.get_scalars(%e0_3763) : !cute.int_tuple<"?">
          %1506 = cute.get_scalars(%e1_3764) : !cute.int_tuple<"?">
          %iter_3765 = cute.get_iter(%slice_3758) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3766, %e1_3767 = cute.get_leaves(%iter_3765) : !cute.int_tuple<"(?,?)">
          %1507 = cute.get_scalars(%e0_3766) : !cute.int_tuple<"?">
          %1508 = cute.get_scalars(%e1_3767) : !cute.int_tuple<"?">
          %coord_3768 = cute.make_coord(%e0_3755) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3769 = cute.make_coord(%e1_3767) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1509 = cute.elem_less(%coord_3768, %coord_3769) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3770 = cute.get_layout(%1494) : !memref_rmem_f32_1
          %1510 = cute.get_shape(%lay_3770) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3771, %e1_3772, %e2_3773, %e3_3774 = cute.get_leaves(%1510) : !cute.shape<"((2,2),1,8)">
          %1511 = cute.get_stride(%lay_3770) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3775, %e1_3776, %e2_3777, %e3_3778 = cute.get_leaves(%1511) : !cute.stride<"((1,2),0,4)">
          %1512 = scf.if %1509 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1494) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,2)">
            cute.memref.store(%1494, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1494) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1494 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1494) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1494) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1494 : !memref_rmem_f32_1
          }
          %iter_3779 = cute.get_iter(%1512) : !memref_rmem_f32_1
          %lay_3780 = cute.get_layout(%1512) : !memref_rmem_f32_1
          %1513 = cute.get_shape(%lay_3780) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3781, %e1_3782, %e2_3783, %e3_3784 = cute.get_leaves(%1513) : !cute.shape<"((2,2),1,8)">
          %1514 = cute.get_stride(%lay_3780) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3785, %e1_3786, %e2_3787, %e3_3788 = cute.get_leaves(%1514) : !cute.stride<"((1,2),0,4)">
          %iter_3789 = cute.get_iter(%1512) : !memref_rmem_f32_1
          %iter_3790 = cute.get_iter(%1512) : !memref_rmem_f32_1
          %coord_3791 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %slice_3792 = cute.slice(%ptn_C, %coord_3791) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,3)">
          %iter_3793 = cute.get_iter(%slice_3792) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3794, %e1_3795 = cute.get_leaves(%iter_3793) : !cute.int_tuple<"(?,?)">
          %1515 = cute.get_scalars(%e0_3794) : !cute.int_tuple<"?">
          %1516 = cute.get_scalars(%e1_3795) : !cute.int_tuple<"?">
          %iter_3796 = cute.get_iter(%slice_3792) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3797, %e1_3798 = cute.get_leaves(%iter_3796) : !cute.int_tuple<"(?,?)">
          %1517 = cute.get_scalars(%e0_3797) : !cute.int_tuple<"?">
          %1518 = cute.get_scalars(%e1_3798) : !cute.int_tuple<"?">
          %iter_3799 = cute.get_iter(%slice_3792) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3800, %e1_3801 = cute.get_leaves(%iter_3799) : !cute.int_tuple<"(?,?)">
          %1519 = cute.get_scalars(%e0_3800) : !cute.int_tuple<"?">
          %1520 = cute.get_scalars(%e1_3801) : !cute.int_tuple<"?">
          %coord_3802 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
          %slice_3803 = cute.slice(%ptn_C, %coord_3802) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,3)">
          %iter_3804 = cute.get_iter(%slice_3803) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3805, %e1_3806 = cute.get_leaves(%iter_3804) : !cute.int_tuple<"(?,?)">
          %1521 = cute.get_scalars(%e0_3805) : !cute.int_tuple<"?">
          %1522 = cute.get_scalars(%e1_3806) : !cute.int_tuple<"?">
          %iter_3807 = cute.get_iter(%slice_3803) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3808, %e1_3809 = cute.get_leaves(%iter_3807) : !cute.int_tuple<"(?,?)">
          %1523 = cute.get_scalars(%e0_3808) : !cute.int_tuple<"?">
          %1524 = cute.get_scalars(%e1_3809) : !cute.int_tuple<"?">
          %iter_3810 = cute.get_iter(%slice_3803) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3811, %e1_3812 = cute.get_leaves(%iter_3810) : !cute.int_tuple<"(?,?)">
          %1525 = cute.get_scalars(%e0_3811) : !cute.int_tuple<"?">
          %1526 = cute.get_scalars(%e1_3812) : !cute.int_tuple<"?">
          %coord_3813 = cute.make_coord(%e0_3800) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3814 = cute.make_coord(%e1_3812) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1527 = cute.elem_less(%coord_3813, %coord_3814) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3815 = cute.get_layout(%1512) : !memref_rmem_f32_1
          %1528 = cute.get_shape(%lay_3815) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3816, %e1_3817, %e2_3818, %e3_3819 = cute.get_leaves(%1528) : !cute.shape<"((2,2),1,8)">
          %1529 = cute.get_stride(%lay_3815) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3820, %e1_3821, %e2_3822, %e3_3823 = cute.get_leaves(%1529) : !cute.stride<"((1,2),0,4)">
          %1530 = scf.if %1527 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1512) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,3)">
            cute.memref.store(%1512, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1512) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1512 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1512) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1512) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1512 : !memref_rmem_f32_1
          }
          %iter_3824 = cute.get_iter(%1530) : !memref_rmem_f32_1
          %lay_3825 = cute.get_layout(%1530) : !memref_rmem_f32_1
          %1531 = cute.get_shape(%lay_3825) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3826, %e1_3827, %e2_3828, %e3_3829 = cute.get_leaves(%1531) : !cute.shape<"((2,2),1,8)">
          %1532 = cute.get_stride(%lay_3825) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3830, %e1_3831, %e2_3832, %e3_3833 = cute.get_leaves(%1532) : !cute.stride<"((1,2),0,4)">
          %iter_3834 = cute.get_iter(%1530) : !memref_rmem_f32_1
          %iter_3835 = cute.get_iter(%1530) : !memref_rmem_f32_1
          %coord_3836 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %slice_3837 = cute.slice(%ptn_C, %coord_3836) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,4)">
          %iter_3838 = cute.get_iter(%slice_3837) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3839, %e1_3840 = cute.get_leaves(%iter_3838) : !cute.int_tuple<"(?,?)">
          %1533 = cute.get_scalars(%e0_3839) : !cute.int_tuple<"?">
          %1534 = cute.get_scalars(%e1_3840) : !cute.int_tuple<"?">
          %iter_3841 = cute.get_iter(%slice_3837) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3842, %e1_3843 = cute.get_leaves(%iter_3841) : !cute.int_tuple<"(?,?)">
          %1535 = cute.get_scalars(%e0_3842) : !cute.int_tuple<"?">
          %1536 = cute.get_scalars(%e1_3843) : !cute.int_tuple<"?">
          %iter_3844 = cute.get_iter(%slice_3837) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3845, %e1_3846 = cute.get_leaves(%iter_3844) : !cute.int_tuple<"(?,?)">
          %1537 = cute.get_scalars(%e0_3845) : !cute.int_tuple<"?">
          %1538 = cute.get_scalars(%e1_3846) : !cute.int_tuple<"?">
          %coord_3847 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
          %slice_3848 = cute.slice(%ptn_C, %coord_3847) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,4)">
          %iter_3849 = cute.get_iter(%slice_3848) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3850, %e1_3851 = cute.get_leaves(%iter_3849) : !cute.int_tuple<"(?,?)">
          %1539 = cute.get_scalars(%e0_3850) : !cute.int_tuple<"?">
          %1540 = cute.get_scalars(%e1_3851) : !cute.int_tuple<"?">
          %iter_3852 = cute.get_iter(%slice_3848) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3853, %e1_3854 = cute.get_leaves(%iter_3852) : !cute.int_tuple<"(?,?)">
          %1541 = cute.get_scalars(%e0_3853) : !cute.int_tuple<"?">
          %1542 = cute.get_scalars(%e1_3854) : !cute.int_tuple<"?">
          %iter_3855 = cute.get_iter(%slice_3848) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3856, %e1_3857 = cute.get_leaves(%iter_3855) : !cute.int_tuple<"(?,?)">
          %1543 = cute.get_scalars(%e0_3856) : !cute.int_tuple<"?">
          %1544 = cute.get_scalars(%e1_3857) : !cute.int_tuple<"?">
          %coord_3858 = cute.make_coord(%e0_3845) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3859 = cute.make_coord(%e1_3857) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1545 = cute.elem_less(%coord_3858, %coord_3859) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3860 = cute.get_layout(%1530) : !memref_rmem_f32_1
          %1546 = cute.get_shape(%lay_3860) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3861, %e1_3862, %e2_3863, %e3_3864 = cute.get_leaves(%1546) : !cute.shape<"((2,2),1,8)">
          %1547 = cute.get_stride(%lay_3860) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3865, %e1_3866, %e2_3867, %e3_3868 = cute.get_leaves(%1547) : !cute.stride<"((1,2),0,4)">
          %1548 = scf.if %1545 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1530) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,4)">
            cute.memref.store(%1530, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1530) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1530 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1530) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1530) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1530 : !memref_rmem_f32_1
          }
          %iter_3869 = cute.get_iter(%1548) : !memref_rmem_f32_1
          %lay_3870 = cute.get_layout(%1548) : !memref_rmem_f32_1
          %1549 = cute.get_shape(%lay_3870) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3871, %e1_3872, %e2_3873, %e3_3874 = cute.get_leaves(%1549) : !cute.shape<"((2,2),1,8)">
          %1550 = cute.get_stride(%lay_3870) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3875, %e1_3876, %e2_3877, %e3_3878 = cute.get_leaves(%1550) : !cute.stride<"((1,2),0,4)">
          %iter_3879 = cute.get_iter(%1548) : !memref_rmem_f32_1
          %iter_3880 = cute.get_iter(%1548) : !memref_rmem_f32_1
          %coord_3881 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %slice_3882 = cute.slice(%ptn_C, %coord_3881) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,5)">
          %iter_3883 = cute.get_iter(%slice_3882) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3884, %e1_3885 = cute.get_leaves(%iter_3883) : !cute.int_tuple<"(?,?)">
          %1551 = cute.get_scalars(%e0_3884) : !cute.int_tuple<"?">
          %1552 = cute.get_scalars(%e1_3885) : !cute.int_tuple<"?">
          %iter_3886 = cute.get_iter(%slice_3882) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3887, %e1_3888 = cute.get_leaves(%iter_3886) : !cute.int_tuple<"(?,?)">
          %1553 = cute.get_scalars(%e0_3887) : !cute.int_tuple<"?">
          %1554 = cute.get_scalars(%e1_3888) : !cute.int_tuple<"?">
          %iter_3889 = cute.get_iter(%slice_3882) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3890, %e1_3891 = cute.get_leaves(%iter_3889) : !cute.int_tuple<"(?,?)">
          %1555 = cute.get_scalars(%e0_3890) : !cute.int_tuple<"?">
          %1556 = cute.get_scalars(%e1_3891) : !cute.int_tuple<"?">
          %coord_3892 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
          %slice_3893 = cute.slice(%ptn_C, %coord_3892) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,5)">
          %iter_3894 = cute.get_iter(%slice_3893) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3895, %e1_3896 = cute.get_leaves(%iter_3894) : !cute.int_tuple<"(?,?)">
          %1557 = cute.get_scalars(%e0_3895) : !cute.int_tuple<"?">
          %1558 = cute.get_scalars(%e1_3896) : !cute.int_tuple<"?">
          %iter_3897 = cute.get_iter(%slice_3893) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3898, %e1_3899 = cute.get_leaves(%iter_3897) : !cute.int_tuple<"(?,?)">
          %1559 = cute.get_scalars(%e0_3898) : !cute.int_tuple<"?">
          %1560 = cute.get_scalars(%e1_3899) : !cute.int_tuple<"?">
          %iter_3900 = cute.get_iter(%slice_3893) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3901, %e1_3902 = cute.get_leaves(%iter_3900) : !cute.int_tuple<"(?,?)">
          %1561 = cute.get_scalars(%e0_3901) : !cute.int_tuple<"?">
          %1562 = cute.get_scalars(%e1_3902) : !cute.int_tuple<"?">
          %coord_3903 = cute.make_coord(%e0_3890) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3904 = cute.make_coord(%e1_3902) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1563 = cute.elem_less(%coord_3903, %coord_3904) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3905 = cute.get_layout(%1548) : !memref_rmem_f32_1
          %1564 = cute.get_shape(%lay_3905) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3906, %e1_3907, %e2_3908, %e3_3909 = cute.get_leaves(%1564) : !cute.shape<"((2,2),1,8)">
          %1565 = cute.get_stride(%lay_3905) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3910, %e1_3911, %e2_3912, %e3_3913 = cute.get_leaves(%1565) : !cute.stride<"((1,2),0,4)">
          %1566 = scf.if %1563 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1548) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,5)">
            cute.memref.store(%1548, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1548) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1548 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1548) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1548) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1548 : !memref_rmem_f32_1
          }
          %iter_3914 = cute.get_iter(%1566) : !memref_rmem_f32_1
          %lay_3915 = cute.get_layout(%1566) : !memref_rmem_f32_1
          %1567 = cute.get_shape(%lay_3915) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3916, %e1_3917, %e2_3918, %e3_3919 = cute.get_leaves(%1567) : !cute.shape<"((2,2),1,8)">
          %1568 = cute.get_stride(%lay_3915) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3920, %e1_3921, %e2_3922, %e3_3923 = cute.get_leaves(%1568) : !cute.stride<"((1,2),0,4)">
          %iter_3924 = cute.get_iter(%1566) : !memref_rmem_f32_1
          %iter_3925 = cute.get_iter(%1566) : !memref_rmem_f32_1
          %coord_3926 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %slice_3927 = cute.slice(%ptn_C, %coord_3926) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,6)">
          %iter_3928 = cute.get_iter(%slice_3927) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3929, %e1_3930 = cute.get_leaves(%iter_3928) : !cute.int_tuple<"(?,?)">
          %1569 = cute.get_scalars(%e0_3929) : !cute.int_tuple<"?">
          %1570 = cute.get_scalars(%e1_3930) : !cute.int_tuple<"?">
          %iter_3931 = cute.get_iter(%slice_3927) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3932, %e1_3933 = cute.get_leaves(%iter_3931) : !cute.int_tuple<"(?,?)">
          %1571 = cute.get_scalars(%e0_3932) : !cute.int_tuple<"?">
          %1572 = cute.get_scalars(%e1_3933) : !cute.int_tuple<"?">
          %iter_3934 = cute.get_iter(%slice_3927) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3935, %e1_3936 = cute.get_leaves(%iter_3934) : !cute.int_tuple<"(?,?)">
          %1573 = cute.get_scalars(%e0_3935) : !cute.int_tuple<"?">
          %1574 = cute.get_scalars(%e1_3936) : !cute.int_tuple<"?">
          %coord_3937 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
          %slice_3938 = cute.slice(%ptn_C, %coord_3937) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,6)">
          %iter_3939 = cute.get_iter(%slice_3938) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3940, %e1_3941 = cute.get_leaves(%iter_3939) : !cute.int_tuple<"(?,?)">
          %1575 = cute.get_scalars(%e0_3940) : !cute.int_tuple<"?">
          %1576 = cute.get_scalars(%e1_3941) : !cute.int_tuple<"?">
          %iter_3942 = cute.get_iter(%slice_3938) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3943, %e1_3944 = cute.get_leaves(%iter_3942) : !cute.int_tuple<"(?,?)">
          %1577 = cute.get_scalars(%e0_3943) : !cute.int_tuple<"?">
          %1578 = cute.get_scalars(%e1_3944) : !cute.int_tuple<"?">
          %iter_3945 = cute.get_iter(%slice_3938) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3946, %e1_3947 = cute.get_leaves(%iter_3945) : !cute.int_tuple<"(?,?)">
          %1579 = cute.get_scalars(%e0_3946) : !cute.int_tuple<"?">
          %1580 = cute.get_scalars(%e1_3947) : !cute.int_tuple<"?">
          %coord_3948 = cute.make_coord(%e0_3935) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3949 = cute.make_coord(%e1_3947) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1581 = cute.elem_less(%coord_3948, %coord_3949) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3950 = cute.get_layout(%1566) : !memref_rmem_f32_1
          %1582 = cute.get_shape(%lay_3950) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3951, %e1_3952, %e2_3953, %e3_3954 = cute.get_leaves(%1582) : !cute.shape<"((2,2),1,8)">
          %1583 = cute.get_stride(%lay_3950) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3955, %e1_3956, %e2_3957, %e3_3958 = cute.get_leaves(%1583) : !cute.stride<"((1,2),0,4)">
          %1584 = scf.if %1581 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1566) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,6)">
            cute.memref.store(%1566, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1566) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1566 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1566) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1566) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1566 : !memref_rmem_f32_1
          }
          %iter_3959 = cute.get_iter(%1584) : !memref_rmem_f32_1
          %lay_3960 = cute.get_layout(%1584) : !memref_rmem_f32_1
          %1585 = cute.get_shape(%lay_3960) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3961, %e1_3962, %e2_3963, %e3_3964 = cute.get_leaves(%1585) : !cute.shape<"((2,2),1,8)">
          %1586 = cute.get_stride(%lay_3960) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_3965, %e1_3966, %e2_3967, %e3_3968 = cute.get_leaves(%1586) : !cute.stride<"((1,2),0,4)">
          %iter_3969 = cute.get_iter(%1584) : !memref_rmem_f32_1
          %iter_3970 = cute.get_iter(%1584) : !memref_rmem_f32_1
          %coord_3971 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %slice_3972 = cute.slice(%ptn_C, %coord_3971) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,7)">
          %iter_3973 = cute.get_iter(%slice_3972) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3974, %e1_3975 = cute.get_leaves(%iter_3973) : !cute.int_tuple<"(?,?)">
          %1587 = cute.get_scalars(%e0_3974) : !cute.int_tuple<"?">
          %1588 = cute.get_scalars(%e1_3975) : !cute.int_tuple<"?">
          %iter_3976 = cute.get_iter(%slice_3972) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3977, %e1_3978 = cute.get_leaves(%iter_3976) : !cute.int_tuple<"(?,?)">
          %1589 = cute.get_scalars(%e0_3977) : !cute.int_tuple<"?">
          %1590 = cute.get_scalars(%e1_3978) : !cute.int_tuple<"?">
          %iter_3979 = cute.get_iter(%slice_3972) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3980, %e1_3981 = cute.get_leaves(%iter_3979) : !cute.int_tuple<"(?,?)">
          %1591 = cute.get_scalars(%e0_3980) : !cute.int_tuple<"?">
          %1592 = cute.get_scalars(%e1_3981) : !cute.int_tuple<"?">
          %coord_3982 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
          %slice_3983 = cute.slice(%ptn_C, %coord_3982) : !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">, !cute.coord<"(3,0,7)">
          %iter_3984 = cute.get_iter(%slice_3983) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3985, %e1_3986 = cute.get_leaves(%iter_3984) : !cute.int_tuple<"(?,?)">
          %1593 = cute.get_scalars(%e0_3985) : !cute.int_tuple<"?">
          %1594 = cute.get_scalars(%e1_3986) : !cute.int_tuple<"?">
          %iter_3987 = cute.get_iter(%slice_3983) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3988, %e1_3989 = cute.get_leaves(%iter_3987) : !cute.int_tuple<"(?,?)">
          %1595 = cute.get_scalars(%e0_3988) : !cute.int_tuple<"?">
          %1596 = cute.get_scalars(%e1_3989) : !cute.int_tuple<"?">
          %iter_3990 = cute.get_iter(%slice_3983) : !cute.coord_tensor<"(?,?)", "():()">
          %e0_3991, %e1_3992 = cute.get_leaves(%iter_3990) : !cute.int_tuple<"(?,?)">
          %1597 = cute.get_scalars(%e0_3991) : !cute.int_tuple<"?">
          %1598 = cute.get_scalars(%e1_3992) : !cute.int_tuple<"?">
          %coord_3993 = cute.make_coord(%e0_3980) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3994 = cute.make_coord(%e1_3992) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %1599 = cute.elem_less(%coord_3993, %coord_3994) : !cute.coord<"?">, !cute.coord<"?">
          %lay_3995 = cute.get_layout(%1584) : !memref_rmem_f32_1
          %1600 = cute.get_shape(%lay_3995) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_3996, %e1_3997, %e2_3998, %e3_3999 = cute.get_leaves(%1600) : !cute.shape<"((2,2),1,8)">
          %1601 = cute.get_stride(%lay_3995) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4000, %e1_4001, %e2_4002, %e3_4003 = cute.get_leaves(%1601) : !cute.stride<"((1,2),0,4)">
          %1602 = scf.if %1599 -> (!memref_rmem_f32_1) {
            %iter_4073 = cute.get_iter(%1584) : !memref_rmem_f32_1
            %cst_4074 = arith.constant 0.000000e+00 : f32
            %coord_4075 = cute.make_coord() : () -> !cute.coord<"(3,0,7)">
            cute.memref.store(%1584, %coord_4075, %cst_4074) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
            %lay_4076 = cute.get_layout(%1584) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4077, %e1_4078, %e2_4079, %e3_4080 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4076) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4081, %e1_4082, %e2_4083, %e3_4084 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1584 : !memref_rmem_f32_1
          } else {
            %iter_4073 = cute.get_iter(%1584) : !memref_rmem_f32_1
            %lay_4074 = cute.get_layout(%1584) : !memref_rmem_f32_1
            %1630 = cute.get_shape(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
            %e0_4075, %e1_4076, %e2_4077, %e3_4078 = cute.get_leaves(%1630) : !cute.shape<"((2,2),1,8)">
            %1631 = cute.get_stride(%lay_4074) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
            %e0_4079, %e1_4080, %e2_4081, %e3_4082 = cute.get_leaves(%1631) : !cute.stride<"((1,2),0,4)">
            scf.yield %1584 : !memref_rmem_f32_1
          }
          %iter_4004 = cute.get_iter(%1602) : !memref_rmem_f32_1
          %lay_4005 = cute.get_layout(%1602) : !memref_rmem_f32_1
          %1603 = cute.get_shape(%lay_4005) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4006, %e1_4007, %e2_4008, %e3_4009 = cute.get_leaves(%1603) : !cute.shape<"((2,2),1,8)">
          %1604 = cute.get_stride(%lay_4005) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4010, %e1_4011, %e2_4012, %e3_4013 = cute.get_leaves(%1604) : !cute.stride<"((1,2),0,4)">
          %iter_4014 = cute.get_iter(%1602) : !memref_rmem_f32_1
          %iter_4015 = cute.get_iter(%1602) : !memref_rmem_f32_1
          %lay_4016 = cute.get_layout(%1602) : !memref_rmem_f32_1
          %1605 = cute.get_shape(%lay_4016) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_4017, %e1_4018, %e2_4019, %e3_4020 = cute.get_leaves(%1605) : !cute.shape<"((2,2),1,8)">
          %1606 = cute.get_stride(%lay_4016) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_4021, %e1_4022, %e2_4023, %e3_4024 = cute.get_leaves(%1606) : !cute.stride<"((1,2),0,4)">
          %1607 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
          %1608 = cute.get_shape(%1607) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
          %e0_4025, %e1_4026, %e2_4027, %e3_4028 = cute.get_leaves(%1608) : !cute.shape<"(32,4,1,1)">
          %1609 = cute.get_stride(%1607) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
          %e0_4029, %e1_4030, %e2_4031, %e3_4032 = cute.get_leaves(%1609) : !cute.stride<"(1,32,0,0)">
          %1610 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
          %e0_4033, %e1_4034, %e2_4035 = cute.get_leaves(%1610) : !cute.tile<"[64:1;16:1;16:1]">
          %1611 = cute.get_shape(%e0_4033) : (!cute.layout<"64:1">) -> !cute.shape<"64">
          %e0_4036 = cute.get_leaves(%1611) : !cute.shape<"64">
          %1612 = cute.get_stride(%e0_4033) : (!cute.layout<"64:1">) -> !cute.stride<"1">
          %e0_4037 = cute.get_leaves(%1612) : !cute.stride<"1">
          %1613 = cute.get_shape(%e1_4034) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_4038 = cute.get_leaves(%1613) : !cute.shape<"16">
          %1614 = cute.get_stride(%e1_4034) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_4039 = cute.get_leaves(%1614) : !cute.stride<"1">
          %1615 = cute.get_shape(%e2_4035) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_4040 = cute.get_leaves(%1615) : !cute.shape<"16">
          %1616 = cute.get_stride(%e2_4035) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_4041 = cute.get_leaves(%1616) : !cute.stride<"1">
          %1617 = cute.static : !cute.layout<"32:1">
          %1618 = cute.get_shape(%1617) : (!cute.layout<"32:1">) -> !cute.shape<"32">
          %e0_4042 = cute.get_leaves(%1618) : !cute.shape<"32">
          %1619 = cute.get_stride(%1617) : (!cute.layout<"32:1">) -> !cute.stride<"1">
          %e0_4043 = cute.get_leaves(%1619) : !cute.stride<"1">
          %1620 = cute.static : !cute.shape<"(16,8,16)">
          %e0_4044, %e1_4045, %e2_4046 = cute.get_leaves(%1620) : !cute.shape<"(16,8,16)">
          %1621 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
          %1622 = cute.get_shape(%1621) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
          %e0_4047, %e1_4048, %e2_4049, %e3_4050, %e4_4051 = cute.get_leaves(%1622) : !cute.shape<"((4,8),(2,2,2))">
          %1623 = cute.get_stride(%1621) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
          %e0_4052, %e1_4053, %e2_4054, %e3_4055, %e4_4056 = cute.get_leaves(%1623) : !cute.stride<"((32,1),(16,8,128))">
          %1624 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
          %1625 = cute.get_shape(%1624) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_4057, %e1_4058, %e2_4059, %e3_4060 = cute.get_leaves(%1625) : !cute.shape<"((4,8),(2,2))">
          %1626 = cute.get_stride(%1624) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
          %e0_4061, %e1_4062, %e2_4063, %e3_4064 = cute.get_leaves(%1626) : !cute.stride<"((16,1),(8,64))">
          %1627 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
          %1628 = cute.get_shape(%1627) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_4065, %e1_4066, %e2_4067, %e3_4068 = cute.get_leaves(%1628) : !cute.shape<"((4,8),(2,2))">
          %1629 = cute.get_stride(%1627) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
          %e0_4069, %e1_4070, %e2_4071, %e3_4072 = cute.get_leaves(%1629) : !cute.stride<"((32,1),(16,8))">
          scf.yield %1602, %arg13 : !memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_
        } else {
          %iter_2539 = cute.get_iter(%913) : !memref_rmem_f32_1
          %lay_2540 = cute.get_layout(%913) : !memref_rmem_f32_1
          %1026 = cute.get_shape(%lay_2540) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
          %e0_2541, %e1_2542, %e2_2543, %e3_2544 = cute.get_leaves(%1026) : !cute.shape<"((2,2),1,8)">
          %1027 = cute.get_stride(%lay_2540) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
          %e0_2545, %e1_2546, %e2_2547, %e3_2548 = cute.get_leaves(%1027) : !cute.stride<"((1,2),0,4)">
          %1028 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
          %1029 = cute.get_shape(%1028) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
          %e0_2549, %e1_2550, %e2_2551, %e3_2552 = cute.get_leaves(%1029) : !cute.shape<"(32,4,1,1)">
          %1030 = cute.get_stride(%1028) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
          %e0_2553, %e1_2554, %e2_2555, %e3_2556 = cute.get_leaves(%1030) : !cute.stride<"(1,32,0,0)">
          %1031 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
          %e0_2557, %e1_2558, %e2_2559 = cute.get_leaves(%1031) : !cute.tile<"[64:1;16:1;16:1]">
          %1032 = cute.get_shape(%e0_2557) : (!cute.layout<"64:1">) -> !cute.shape<"64">
          %e0_2560 = cute.get_leaves(%1032) : !cute.shape<"64">
          %1033 = cute.get_stride(%e0_2557) : (!cute.layout<"64:1">) -> !cute.stride<"1">
          %e0_2561 = cute.get_leaves(%1033) : !cute.stride<"1">
          %1034 = cute.get_shape(%e1_2558) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_2562 = cute.get_leaves(%1034) : !cute.shape<"16">
          %1035 = cute.get_stride(%e1_2558) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_2563 = cute.get_leaves(%1035) : !cute.stride<"1">
          %1036 = cute.get_shape(%e2_2559) : (!cute.layout<"16:1">) -> !cute.shape<"16">
          %e0_2564 = cute.get_leaves(%1036) : !cute.shape<"16">
          %1037 = cute.get_stride(%e2_2559) : (!cute.layout<"16:1">) -> !cute.stride<"1">
          %e0_2565 = cute.get_leaves(%1037) : !cute.stride<"1">
          %1038 = cute.static : !cute.layout<"32:1">
          %1039 = cute.get_shape(%1038) : (!cute.layout<"32:1">) -> !cute.shape<"32">
          %e0_2566 = cute.get_leaves(%1039) : !cute.shape<"32">
          %1040 = cute.get_stride(%1038) : (!cute.layout<"32:1">) -> !cute.stride<"1">
          %e0_2567 = cute.get_leaves(%1040) : !cute.stride<"1">
          %1041 = cute.static : !cute.shape<"(16,8,16)">
          %e0_2568, %e1_2569, %e2_2570 = cute.get_leaves(%1041) : !cute.shape<"(16,8,16)">
          %1042 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
          %1043 = cute.get_shape(%1042) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
          %e0_2571, %e1_2572, %e2_2573, %e3_2574, %e4_2575 = cute.get_leaves(%1043) : !cute.shape<"((4,8),(2,2,2))">
          %1044 = cute.get_stride(%1042) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
          %e0_2576, %e1_2577, %e2_2578, %e3_2579, %e4_2580 = cute.get_leaves(%1044) : !cute.stride<"((32,1),(16,8,128))">
          %1045 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
          %1046 = cute.get_shape(%1045) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_2581, %e1_2582, %e2_2583, %e3_2584 = cute.get_leaves(%1046) : !cute.shape<"((4,8),(2,2))">
          %1047 = cute.get_stride(%1045) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
          %e0_2585, %e1_2586, %e2_2587, %e3_2588 = cute.get_leaves(%1047) : !cute.stride<"((16,1),(8,64))">
          %1048 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
          %1049 = cute.get_shape(%1048) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
          %e0_2589, %e1_2590, %e2_2591, %e3_2592 = cute.get_leaves(%1049) : !cute.shape<"((4,8),(2,2))">
          %1050 = cute.get_stride(%1048) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
          %e0_2593, %e1_2594, %e2_2595, %e3_2596 = cute.get_leaves(%1050) : !cute.stride<"((32,1),(16,8))">
          scf.yield %913, %arg13 : !memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_
        }
        %iter_2229 = cute.get_iter(%954#0) : !memref_rmem_f32_1
        %lay_2230 = cute.get_layout(%954#0) : !memref_rmem_f32_1
        %955 = cute.get_shape(%lay_2230) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2231, %e1_2232, %e2_2233, %e3_2234 = cute.get_leaves(%955) : !cute.shape<"((2,2),1,8)">
        %956 = cute.get_stride(%lay_2230) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.stride<"((1,2),0,4)">
        %e0_2235, %e1_2236, %e2_2237, %e3_2238 = cute.get_leaves(%956) : !cute.stride<"((1,2),0,4)">
        %iter_2239 = cute.get_iter(%954#0) : !memref_rmem_f32_1
        %iter_2240 = cute.get_iter(%954#0) : !memref_rmem_f32_1
        %lay_2241 = cute.get_layout(%954#0) : !memref_rmem_f32_1
        %957 = cute.make_layout_like(%lay_2241) : !cute.layout<"((2,2),1,8):((1,2),0,4)"> to !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %rmem_2242 = cute.memref.alloca(%957) : !memref_rmem_bf16_6
        %iter_2243 = cute.get_iter(%rmem_2242) : !memref_rmem_bf16_6
        %iter_2244 = cute.get_iter(%rmem_2242) : !memref_rmem_bf16_6
        %lay_2245 = cute.get_layout(%954#0) : !memref_rmem_f32_1
        %958 = cute.get_shape(%lay_2245) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2246, %e1_2247, %e2_2248, %e3_2249 = cute.get_leaves(%958) : !cute.shape<"((2,2),1,8)">
        %959 = cute.memref.load_vec %954#0, row_major : !memref_rmem_f32_1
        %960 = arith.truncf %959 : vector<32xf32> to vector<32xbf16>
        %lay_2250 = cute.get_layout(%rmem_2242) : !memref_rmem_bf16_6
        %961 = cute.get_shape(%lay_2250) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.shape<"((2,2),1,8)">
        %e0_2251, %e1_2252, %e2_2253, %e3_2254 = cute.get_leaves(%961) : !cute.shape<"((2,2),1,8)">
        %int_tuple_2255 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_2256 = cute.size(%int_tuple_2255) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_2257 = cute.get_leaves(%sz_2256) : !cute.int_tuple<"32">
        %int_tuple_2258 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,8)">
        %sz_2259 = cute.size(%int_tuple_2258) : (!cute.int_tuple<"((2,2),1,8)">) -> !cute.int_tuple<"32">
        %e0_2260 = cute.get_leaves(%sz_2259) : !cute.int_tuple<"32">
        cute.memref.store_vec %960, %rmem_2242, row_major : !memref_rmem_bf16_6
        %lay_2261 = cute.get_layout(%rmem_2242) : !memref_rmem_bf16_6
        %tile_2262 = cute.make_tile() : () -> !cute.tile<"[_;_;2:1]">
        %div = cute.logical_divide(%lay_2261, %tile_2262) : !cute.layout<"((2,2),1,8):((1,2),0,4)">, !cute.tile<"[_;_;2:1]">
        %962 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2263, %e1_2264, %e2_2265, %e3_2266, %e4_2267 = cute.get_leaves(%962) : !cute.shape<"((2,2),1,(2,4))">
        %963 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2268, %e1_2269, %e2_2270, %e3_2271, %e4_2272 = cute.get_leaves(%963) : !cute.shape<"((2,2),1,(2,4))">
        %964 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2273, %e1_2274, %e2_2275, %e3_2276, %e4_2277 = cute.get_leaves(%964) : !cute.shape<"((2,2),1,(2,4))">
        %965 = cute.get_shape(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.shape<"((2,2),1,(2,4))">
        %e0_2278, %e1_2279, %e2_2280, %e3_2281, %e4_2282 = cute.get_leaves(%965) : !cute.shape<"((2,2),1,(2,4))">
        %966 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2283, %e1_2284, %e2_2285, %e3_2286, %e4_2287 = cute.get_leaves(%966) : !cute.stride<"((1,2),0,(4,8))">
        %967 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2288, %e1_2289, %e2_2290, %e3_2291, %e4_2292 = cute.get_leaves(%967) : !cute.stride<"((1,2),0,(4,8))">
        %968 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2293, %e1_2294, %e2_2295, %e3_2296, %e4_2297 = cute.get_leaves(%968) : !cute.stride<"((1,2),0,(4,8))">
        %969 = cute.get_stride(%div) : (!cute.layout<"((2,2),1,(2,4)):((1,2),0,(4,8))">) -> !cute.stride<"((1,2),0,(4,8))">
        %e0_2298, %e1_2299, %e2_2300, %e3_2301, %e4_2302 = cute.get_leaves(%969) : !cute.stride<"((1,2),0,(4,8))">
        %shape_2303 = cute.make_shape() : () -> !cute.shape<"(((2,2),2),1,4)">
        %stride_2304 = cute.make_stride() : () -> !cute.stride<"(((1,2),4),0,8)">
        %lay_2305 = cute.make_layout(%shape_2303, %stride_2304) : !cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">
        %view_2306 = cute.make_view(%iter_2244, %lay_2305) : !memref_rmem_bf16_15
        %iter_2307 = cute.get_iter(%view_2306) : !memref_rmem_bf16_15
        %coord_2308 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2309 = cute.slice(%src_partitioned_402, %coord_2308) : !memref_smem_bf16_10, !cute.coord<"(_,_,0)">
        %iter_2310 = cute.get_iter(%slice_2309) : !memref_smem_bf16_21
        %coord_2311 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2312 = cute.slice(%retiled_404, %coord_2311) : !memref_rmem_bf16_5, !cute.coord<"(_,_,0)">
        %iter_2313 = cute.get_iter(%slice_2312) : !memref_rmem_bf16_16
        %lay_2314 = cute.get_layout(%slice_2309) : !memref_smem_bf16_21
        %970 = cute.get_shape(%lay_2314) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
        %e0_2315, %e1_2316, %e2_2317, %e3_2318, %e4_2319 = cute.get_leaves(%970) : !cute.shape<"((8,1),((2,2),2))">
        %lay_2320 = cute.get_layout(%slice_2312) : !memref_rmem_bf16_16
        %971 = cute.get_shape(%lay_2320) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
        %e0_2321, %e1_2322, %e2_2323, %e3_2324 = cute.get_leaves(%971) : !cute.shape<"((8,1),(4,2))">
        %lay_2325 = cute.get_layout(%slice_2309) : !memref_smem_bf16_21
        %shape_2326 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_2327 = cute.make_layout(%shape_2326) : !cute.layout<"1:0">
        %append_2328 = cute.append_to_rank<2> (%lay_2325, %lay_2327) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_2329 = cute.make_view(%iter_2310, %append_2328) : !memref_smem_bf16_21
        %iter_2330 = cute.get_iter(%view_2329) : !memref_smem_bf16_21
        %lay_2331 = cute.get_layout(%view_2329) : !memref_smem_bf16_21
        %972 = cute.get_shape(%lay_2331) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
        %e0_2332, %e1_2333, %e2_2334, %e3_2335, %e4_2336 = cute.get_leaves(%972) : !cute.shape<"((8,1),((2,2),2))">
        %grouped_2337 = cute.group_modes(%view_2329) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
        %iter_2338 = cute.get_iter(%grouped_2337) : !memref_smem_bf16_22
        %iter_2339 = cute.get_iter(%grouped_2337) : !memref_smem_bf16_22
        %lay_2340 = cute.get_layout(%slice_2312) : !memref_rmem_bf16_16
        %shape_2341 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_2342 = cute.make_layout(%shape_2341) : !cute.layout<"1:0">
        %append_2343 = cute.append_to_rank<2> (%lay_2340, %lay_2342) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
        %view_2344 = cute.make_view(%iter_2313, %append_2343) : !memref_rmem_bf16_16
        %iter_2345 = cute.get_iter(%view_2344) : !memref_rmem_bf16_16
        %lay_2346 = cute.get_layout(%view_2344) : !memref_rmem_bf16_16
        %973 = cute.get_shape(%lay_2346) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
        %e0_2347, %e1_2348, %e2_2349, %e3_2350 = cute.get_leaves(%973) : !cute.shape<"((8,1),(4,2))">
        %grouped_2351 = cute.group_modes(%view_2344) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
        %iter_2352 = cute.get_iter(%grouped_2351) : !memref_rmem_bf16_17
        %iter_2353 = cute.get_iter(%grouped_2351) : !memref_rmem_bf16_17
        %lay_2354 = cute.get_layout(%grouped_2337) : !memref_smem_bf16_22
        %974 = cute.get_shape(%lay_2354) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
        %e0_2355, %e1_2356, %e2_2357, %e3_2358, %e4_2359 = cute.get_leaves(%974) : !cute.shape<"((8,1),(((2,2),2)))">
        %lay_2360 = cute.get_layout(%grouped_2351) : !memref_rmem_bf16_17
        %975 = cute.get_shape(%lay_2360) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
        %e0_2361, %e1_2362, %e2_2363, %e3_2364 = cute.get_leaves(%975) : !cute.shape<"((8,1),((4,2)))">
        %sz_2365 = cute.size(%grouped_2337) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
        %e0_2366 = cute.get_leaves(%sz_2365) : !cute.int_tuple<"8">
        %sz_2367 = cute.size(%grouped_2351) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
        %e0_2368 = cute.get_leaves(%sz_2367) : !cute.int_tuple<"8">
        cute.copy(%159, %grouped_2337, %grouped_2351) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        %lay_2369 = cute.get_layout(%view_2306) : !memref_rmem_bf16_15
        %976 = cute.get_shape(%lay_2369) : (!cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">) -> !cute.shape<"(((2,2),2),1,4)">
        %e0_2370, %e1_2371, %e2_2372, %e3_2373, %e4_2374 = cute.get_leaves(%976) : !cute.shape<"(((2,2),2),1,4)">
        %int_tuple_2375 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2376 = cute.size(%int_tuple_2375) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2377 = cute.get_leaves(%sz_2376) : !cute.int_tuple<"4">
        %int_tuple_2378 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2379 = cute.size(%int_tuple_2378) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2380 = cute.get_leaves(%sz_2379) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2540 = cute.slice(%src_partitioned_402, %coord_2539) : !memref_smem_bf16_10, !cute.coord<"(_,_,1)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_21
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
          %slice_2543 = cute.slice(%retiled_404, %coord_2542) : !memref_rmem_bf16_5, !cute.coord<"(_,_,1)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_16
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2546, %e1_2547, %e2_2548, %e3_2549, %e4_2550 = cute.get_leaves(%1026) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2551 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %1027 = cute.get_shape(%lay_2551) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2552, %e1_2553, %e2_2554, %e3_2555 = cute.get_leaves(%1027) : !cute.shape<"((8,1),(4,2))">
          %lay_2556 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %shape_2557 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2558 = cute.make_layout(%shape_2557) : !cute.layout<"1:0">
          %append_2559 = cute.append_to_rank<2> (%lay_2556, %lay_2558) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2560 = cute.make_view(%iter_2541, %append_2559) : !memref_smem_bf16_21
          %iter_2561 = cute.get_iter(%view_2560) : !memref_smem_bf16_21
          %lay_2562 = cute.get_layout(%view_2560) : !memref_smem_bf16_21
          %1028 = cute.get_shape(%lay_2562) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2563, %e1_2564, %e2_2565, %e3_2566, %e4_2567 = cute.get_leaves(%1028) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2568 = cute.group_modes(%view_2560) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2569 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %iter_2570 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %lay_2571 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %shape_2572 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2573 = cute.make_layout(%shape_2572) : !cute.layout<"1:0">
          %append_2574 = cute.append_to_rank<2> (%lay_2571, %lay_2573) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2575 = cute.make_view(%iter_2544, %append_2574) : !memref_rmem_bf16_16
          %iter_2576 = cute.get_iter(%view_2575) : !memref_rmem_bf16_16
          %lay_2577 = cute.get_layout(%view_2575) : !memref_rmem_bf16_16
          %1029 = cute.get_shape(%lay_2577) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2578, %e1_2579, %e2_2580, %e3_2581 = cute.get_leaves(%1029) : !cute.shape<"((8,1),(4,2))">
          %grouped_2582 = cute.group_modes(%view_2575) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2583 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %iter_2584 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %lay_2585 = cute.get_layout(%grouped_2568) : !memref_smem_bf16_22
          %1030 = cute.get_shape(%lay_2585) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2586, %e1_2587, %e2_2588, %e3_2589, %e4_2590 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2591 = cute.get_layout(%grouped_2582) : !memref_rmem_bf16_17
          %1031 = cute.get_shape(%lay_2591) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2592, %e1_2593, %e2_2594, %e3_2595 = cute.get_leaves(%1031) : !cute.shape<"((8,1),((4,2)))">
          %sz_2596 = cute.size(%grouped_2568) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2597 = cute.get_leaves(%sz_2596) : !cute.int_tuple<"8">
          %sz_2598 = cute.size(%grouped_2582) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2599 = cute.get_leaves(%sz_2598) : !cute.int_tuple<"8">
          cute.copy(%159, %grouped_2568, %grouped_2582) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2381 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2382 = cute.slice(%view_2306, %coord_2381) : !memref_rmem_bf16_15, !cute.coord<"(_,_,0)">
        %iter_2383 = cute.get_iter(%slice_2382) : !memref_rmem_bf16_18
        %coord_2384 = cute.make_coord() : () -> !cute.coord<"(_,_,0)">
        %slice_2385 = cute.slice(%frg_B_316, %coord_2384) : !memref_rmem_bf16_2, !cute.coord<"(_,_,0)">
        %iter_2386 = cute.get_iter(%slice_2385) : !memref_rmem_bf16_19
        %lay_2387 = cute.get_layout(%slice_2382) : !memref_rmem_bf16_18
        %977 = cute.get_shape(%lay_2387) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2388, %e1_2389, %e2_2390, %e3_2391 = cute.get_leaves(%977) : !cute.shape<"(((2,2),2),1)">
        %lay_2392 = cute.get_layout(%slice_2385) : !memref_rmem_bf16_19
        %978 = cute.get_shape(%lay_2392) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2393, %e1_2394, %e2_2395, %e3_2396 = cute.get_leaves(%978) : !cute.shape<"((2,2),(8,2))">
        %lay_2397 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %979 = cute.get_shape(%lay_2397) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
        %e0_2398, %e1_2399, %e2_2400, %e3_2401 = cute.get_leaves(%979) : !cute.shape<"((2,2),1,16)">
        cute.gemm(%arg11, %rmem, %slice_2382, %slice_2385, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_18, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2402 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2403 = cute.size(%int_tuple_2402) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2404 = cute.get_leaves(%sz_2403) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2540 = cute.slice(%src_partitioned_402, %coord_2539) : !memref_smem_bf16_10, !cute.coord<"(_,_,2)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_21
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
          %slice_2543 = cute.slice(%retiled_404, %coord_2542) : !memref_rmem_bf16_5, !cute.coord<"(_,_,2)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_16
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2546, %e1_2547, %e2_2548, %e3_2549, %e4_2550 = cute.get_leaves(%1026) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2551 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %1027 = cute.get_shape(%lay_2551) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2552, %e1_2553, %e2_2554, %e3_2555 = cute.get_leaves(%1027) : !cute.shape<"((8,1),(4,2))">
          %lay_2556 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %shape_2557 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2558 = cute.make_layout(%shape_2557) : !cute.layout<"1:0">
          %append_2559 = cute.append_to_rank<2> (%lay_2556, %lay_2558) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2560 = cute.make_view(%iter_2541, %append_2559) : !memref_smem_bf16_21
          %iter_2561 = cute.get_iter(%view_2560) : !memref_smem_bf16_21
          %lay_2562 = cute.get_layout(%view_2560) : !memref_smem_bf16_21
          %1028 = cute.get_shape(%lay_2562) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2563, %e1_2564, %e2_2565, %e3_2566, %e4_2567 = cute.get_leaves(%1028) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2568 = cute.group_modes(%view_2560) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2569 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %iter_2570 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %lay_2571 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %shape_2572 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2573 = cute.make_layout(%shape_2572) : !cute.layout<"1:0">
          %append_2574 = cute.append_to_rank<2> (%lay_2571, %lay_2573) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2575 = cute.make_view(%iter_2544, %append_2574) : !memref_rmem_bf16_16
          %iter_2576 = cute.get_iter(%view_2575) : !memref_rmem_bf16_16
          %lay_2577 = cute.get_layout(%view_2575) : !memref_rmem_bf16_16
          %1029 = cute.get_shape(%lay_2577) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2578, %e1_2579, %e2_2580, %e3_2581 = cute.get_leaves(%1029) : !cute.shape<"((8,1),(4,2))">
          %grouped_2582 = cute.group_modes(%view_2575) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2583 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %iter_2584 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %lay_2585 = cute.get_layout(%grouped_2568) : !memref_smem_bf16_22
          %1030 = cute.get_shape(%lay_2585) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2586, %e1_2587, %e2_2588, %e3_2589, %e4_2590 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2591 = cute.get_layout(%grouped_2582) : !memref_rmem_bf16_17
          %1031 = cute.get_shape(%lay_2591) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2592, %e1_2593, %e2_2594, %e3_2595 = cute.get_leaves(%1031) : !cute.shape<"((8,1),((4,2)))">
          %sz_2596 = cute.size(%grouped_2568) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2597 = cute.get_leaves(%sz_2596) : !cute.int_tuple<"8">
          %sz_2598 = cute.size(%grouped_2582) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2599 = cute.get_leaves(%sz_2598) : !cute.int_tuple<"8">
          cute.copy(%159, %grouped_2568, %grouped_2582) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2405 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2406 = cute.slice(%view_2306, %coord_2405) : !memref_rmem_bf16_15, !cute.coord<"(_,_,1)">
        %iter_2407 = cute.get_iter(%slice_2406) : !memref_rmem_bf16_20
        %coord_2408 = cute.make_coord() : () -> !cute.coord<"(_,_,1)">
        %slice_2409 = cute.slice(%frg_B_316, %coord_2408) : !memref_rmem_bf16_2, !cute.coord<"(_,_,1)">
        %iter_2410 = cute.get_iter(%slice_2409) : !memref_rmem_bf16_19
        %lay_2411 = cute.get_layout(%slice_2406) : !memref_rmem_bf16_20
        %980 = cute.get_shape(%lay_2411) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2412, %e1_2413, %e2_2414, %e3_2415 = cute.get_leaves(%980) : !cute.shape<"(((2,2),2),1)">
        %lay_2416 = cute.get_layout(%slice_2409) : !memref_rmem_bf16_19
        %981 = cute.get_shape(%lay_2416) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2417, %e1_2418, %e2_2419, %e3_2420 = cute.get_leaves(%981) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%arg11, %rmem, %slice_2406, %slice_2409, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_20, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2421 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2422 = cute.size(%int_tuple_2421) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2423 = cute.get_leaves(%sz_2422) : !cute.int_tuple<"4">
        scf.if %true {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2540 = cute.slice(%src_partitioned_402, %coord_2539) : !memref_smem_bf16_10, !cute.coord<"(_,_,3)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_21
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
          %slice_2543 = cute.slice(%retiled_404, %coord_2542) : !memref_rmem_bf16_5, !cute.coord<"(_,_,3)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_16
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2546, %e1_2547, %e2_2548, %e3_2549, %e4_2550 = cute.get_leaves(%1026) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2551 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %1027 = cute.get_shape(%lay_2551) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2552, %e1_2553, %e2_2554, %e3_2555 = cute.get_leaves(%1027) : !cute.shape<"((8,1),(4,2))">
          %lay_2556 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %shape_2557 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2558 = cute.make_layout(%shape_2557) : !cute.layout<"1:0">
          %append_2559 = cute.append_to_rank<2> (%lay_2556, %lay_2558) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2560 = cute.make_view(%iter_2541, %append_2559) : !memref_smem_bf16_21
          %iter_2561 = cute.get_iter(%view_2560) : !memref_smem_bf16_21
          %lay_2562 = cute.get_layout(%view_2560) : !memref_smem_bf16_21
          %1028 = cute.get_shape(%lay_2562) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2563, %e1_2564, %e2_2565, %e3_2566, %e4_2567 = cute.get_leaves(%1028) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2568 = cute.group_modes(%view_2560) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2569 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %iter_2570 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %lay_2571 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %shape_2572 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2573 = cute.make_layout(%shape_2572) : !cute.layout<"1:0">
          %append_2574 = cute.append_to_rank<2> (%lay_2571, %lay_2573) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2575 = cute.make_view(%iter_2544, %append_2574) : !memref_rmem_bf16_16
          %iter_2576 = cute.get_iter(%view_2575) : !memref_rmem_bf16_16
          %lay_2577 = cute.get_layout(%view_2575) : !memref_rmem_bf16_16
          %1029 = cute.get_shape(%lay_2577) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2578, %e1_2579, %e2_2580, %e3_2581 = cute.get_leaves(%1029) : !cute.shape<"((8,1),(4,2))">
          %grouped_2582 = cute.group_modes(%view_2575) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2583 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %iter_2584 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %lay_2585 = cute.get_layout(%grouped_2568) : !memref_smem_bf16_22
          %1030 = cute.get_shape(%lay_2585) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2586, %e1_2587, %e2_2588, %e3_2589, %e4_2590 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2591 = cute.get_layout(%grouped_2582) : !memref_rmem_bf16_17
          %1031 = cute.get_shape(%lay_2591) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2592, %e1_2593, %e2_2594, %e3_2595 = cute.get_leaves(%1031) : !cute.shape<"((8,1),((4,2)))">
          %sz_2596 = cute.size(%grouped_2568) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2597 = cute.get_leaves(%sz_2596) : !cute.int_tuple<"8">
          %sz_2598 = cute.size(%grouped_2582) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2599 = cute.get_leaves(%sz_2598) : !cute.int_tuple<"8">
          cute.copy(%159, %grouped_2568, %grouped_2582) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2424 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2425 = cute.slice(%view_2306, %coord_2424) : !memref_rmem_bf16_15, !cute.coord<"(_,_,2)">
        %iter_2426 = cute.get_iter(%slice_2425) : !memref_rmem_bf16_18
        %coord_2427 = cute.make_coord() : () -> !cute.coord<"(_,_,2)">
        %slice_2428 = cute.slice(%frg_B_316, %coord_2427) : !memref_rmem_bf16_2, !cute.coord<"(_,_,2)">
        %iter_2429 = cute.get_iter(%slice_2428) : !memref_rmem_bf16_19
        %lay_2430 = cute.get_layout(%slice_2425) : !memref_rmem_bf16_18
        %982 = cute.get_shape(%lay_2430) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2431, %e1_2432, %e2_2433, %e3_2434 = cute.get_leaves(%982) : !cute.shape<"(((2,2),2),1)">
        %lay_2435 = cute.get_layout(%slice_2428) : !memref_rmem_bf16_19
        %983 = cute.get_shape(%lay_2435) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2436, %e1_2437, %e2_2438, %e3_2439 = cute.get_leaves(%983) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%arg11, %rmem, %slice_2425, %slice_2428, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_18, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %int_tuple_2440 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_2441 = cute.size(%int_tuple_2440) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_2442 = cute.get_leaves(%sz_2441) : !cute.int_tuple<"4">
        scf.if %false {
          %coord_2539 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2540 = cute.slice(%src_partitioned_402, %coord_2539) : !memref_smem_bf16_10, !cute.coord<"(_,_,4)">
          %iter_2541 = cute.get_iter(%slice_2540) : !memref_smem_bf16_21
          %coord_2542 = cute.make_coord() : () -> !cute.coord<"(_,_,4)">
          %slice_2543 = cute.slice(%retiled_404, %coord_2542) : !memref_rmem_bf16_5, !cute.coord<"(_,_,4)">
          %iter_2544 = cute.get_iter(%slice_2543) : !memref_rmem_bf16_16
          %lay_2545 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %1026 = cute.get_shape(%lay_2545) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2546, %e1_2547, %e2_2548, %e3_2549, %e4_2550 = cute.get_leaves(%1026) : !cute.shape<"((8,1),((2,2),2))">
          %lay_2551 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %1027 = cute.get_shape(%lay_2551) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2552, %e1_2553, %e2_2554, %e3_2555 = cute.get_leaves(%1027) : !cute.shape<"((8,1),(4,2))">
          %lay_2556 = cute.get_layout(%slice_2540) : !memref_smem_bf16_21
          %shape_2557 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2558 = cute.make_layout(%shape_2557) : !cute.layout<"1:0">
          %append_2559 = cute.append_to_rank<2> (%lay_2556, %lay_2558) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
          %view_2560 = cute.make_view(%iter_2541, %append_2559) : !memref_smem_bf16_21
          %iter_2561 = cute.get_iter(%view_2560) : !memref_smem_bf16_21
          %lay_2562 = cute.get_layout(%view_2560) : !memref_smem_bf16_21
          %1028 = cute.get_shape(%lay_2562) : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.shape<"((8,1),((2,2),2))">
          %e0_2563, %e1_2564, %e2_2565, %e3_2566, %e4_2567 = cute.get_leaves(%1028) : !cute.shape<"((8,1),((2,2),2))">
          %grouped_2568 = cute.group_modes(%view_2560) <1, 2> : (!memref_smem_bf16_21) -> !memref_smem_bf16_22
          %iter_2569 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %iter_2570 = cute.get_iter(%grouped_2568) : !memref_smem_bf16_22
          %lay_2571 = cute.get_layout(%slice_2543) : !memref_rmem_bf16_16
          %shape_2572 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_2573 = cute.make_layout(%shape_2572) : !cute.layout<"1:0">
          %append_2574 = cute.append_to_rank<2> (%lay_2571, %lay_2573) : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">, !cute.layout<"1:0">
          %view_2575 = cute.make_view(%iter_2544, %append_2574) : !memref_rmem_bf16_16
          %iter_2576 = cute.get_iter(%view_2575) : !memref_rmem_bf16_16
          %lay_2577 = cute.get_layout(%view_2575) : !memref_rmem_bf16_16
          %1029 = cute.get_shape(%lay_2577) : (!cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !cute.shape<"((8,1),(4,2))">
          %e0_2578, %e1_2579, %e2_2580, %e3_2581 = cute.get_leaves(%1029) : !cute.shape<"((8,1),(4,2))">
          %grouped_2582 = cute.group_modes(%view_2575) <1, 2> : (!memref_rmem_bf16_16) -> !memref_rmem_bf16_17
          %iter_2583 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %iter_2584 = cute.get_iter(%grouped_2582) : !memref_rmem_bf16_17
          %lay_2585 = cute.get_layout(%grouped_2568) : !memref_smem_bf16_22
          %1030 = cute.get_shape(%lay_2585) : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.shape<"((8,1),(((2,2),2)))">
          %e0_2586, %e1_2587, %e2_2588, %e3_2589, %e4_2590 = cute.get_leaves(%1030) : !cute.shape<"((8,1),(((2,2),2)))">
          %lay_2591 = cute.get_layout(%grouped_2582) : !memref_rmem_bf16_17
          %1031 = cute.get_shape(%lay_2591) : (!cute.layout<"((8,1),((4,2))):((1,0),((8,128)))">) -> !cute.shape<"((8,1),((4,2)))">
          %e0_2592, %e1_2593, %e2_2594, %e3_2595 = cute.get_leaves(%1031) : !cute.shape<"((8,1),((4,2)))">
          %sz_2596 = cute.size(%grouped_2568) <{mode = [1]}> : (!memref_smem_bf16_22) -> !cute.int_tuple<"8">
          %e0_2597 = cute.get_leaves(%sz_2596) : !cute.int_tuple<"8">
          %sz_2598 = cute.size(%grouped_2582) <{mode = [1]}> : (!memref_rmem_bf16_17) -> !cute.int_tuple<"8">
          %e0_2599 = cute.get_leaves(%sz_2598) : !cute.int_tuple<"8">
          cute.copy(%159, %grouped_2568, %grouped_2582) : (!copy_ldsm_4_2, !memref_smem_bf16_22, !memref_rmem_bf16_17)
        }
        %coord_2443 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2444 = cute.slice(%view_2306, %coord_2443) : !memref_rmem_bf16_15, !cute.coord<"(_,_,3)">
        %iter_2445 = cute.get_iter(%slice_2444) : !memref_rmem_bf16_20
        %coord_2446 = cute.make_coord() : () -> !cute.coord<"(_,_,3)">
        %slice_2447 = cute.slice(%frg_B_316, %coord_2446) : !memref_rmem_bf16_2, !cute.coord<"(_,_,3)">
        %iter_2448 = cute.get_iter(%slice_2447) : !memref_rmem_bf16_19
        %lay_2449 = cute.get_layout(%slice_2444) : !memref_rmem_bf16_20
        %984 = cute.get_shape(%lay_2449) : (!cute.layout<"(((2,2),2),1):(((1,2),4),0)">) -> !cute.shape<"(((2,2),2),1)">
        %e0_2450, %e1_2451, %e2_2452, %e3_2453 = cute.get_leaves(%984) : !cute.shape<"(((2,2),2),1)">
        %lay_2454 = cute.get_layout(%slice_2447) : !memref_rmem_bf16_19
        %985 = cute.get_shape(%lay_2454) : (!cute.layout<"((2,2),(8,2)):((1,2),(4,128))">) -> !cute.shape<"((2,2),(8,2))">
        %e0_2455, %e1_2456, %e2_2457, %e3_2458 = cute.get_leaves(%985) : !cute.shape<"((2,2),(8,2))">
        cute.gemm(%arg11, %rmem, %slice_2444, %slice_2447, %rmem) : (!mma_bf16_bf16_f32_16x8x16_, !memref_rmem_f32_, !memref_rmem_bf16_20, !memref_rmem_bf16_19, !memref_rmem_f32_)
        %986 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
        %987 = cute.get_shape(%986) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.shape<"(32,4,1,1)">
        %e0_2459, %e1_2460, %e2_2461, %e3_2462 = cute.get_leaves(%987) : !cute.shape<"(32,4,1,1)">
        %988 = cute.get_stride(%986) : (!cute.layout<"(32,4,1,1):(1,32,0,0)">) -> !cute.stride<"(1,32,0,0)">
        %e0_2463, %e1_2464, %e2_2465, %e3_2466 = cute.get_leaves(%988) : !cute.stride<"(1,32,0,0)">
        %989 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
        %e0_2467, %e1_2468, %e2_2469 = cute.get_leaves(%989) : !cute.tile<"[64:1;16:1;16:1]">
        %990 = cute.get_shape(%e0_2467) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2470 = cute.get_leaves(%990) : !cute.shape<"64">
        %991 = cute.get_stride(%e0_2467) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2471 = cute.get_leaves(%991) : !cute.stride<"1">
        %992 = cute.get_shape(%e1_2468) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2472 = cute.get_leaves(%992) : !cute.shape<"16">
        %993 = cute.get_stride(%e1_2468) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2473 = cute.get_leaves(%993) : !cute.stride<"1">
        %994 = cute.get_shape(%e2_2469) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2474 = cute.get_leaves(%994) : !cute.shape<"16">
        %995 = cute.get_stride(%e2_2469) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2475 = cute.get_leaves(%995) : !cute.stride<"1">
        %996 = cute.static : !cute.layout<"32:1">
        %997 = cute.get_shape(%996) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2476 = cute.get_leaves(%997) : !cute.shape<"32">
        %998 = cute.get_stride(%996) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2477 = cute.get_leaves(%998) : !cute.stride<"1">
        %999 = cute.static : !cute.shape<"(16,8,16)">
        %e0_2478, %e1_2479, %e2_2480 = cute.get_leaves(%999) : !cute.shape<"(16,8,16)">
        %1000 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
        %1001 = cute.get_shape(%1000) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.shape<"((4,8),(2,2,2))">
        %e0_2481, %e1_2482, %e2_2483, %e3_2484, %e4_2485 = cute.get_leaves(%1001) : !cute.shape<"((4,8),(2,2,2))">
        %1002 = cute.get_stride(%1000) : (!cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">) -> !cute.stride<"((32,1),(16,8,128))">
        %e0_2486, %e1_2487, %e2_2488, %e3_2489, %e4_2490 = cute.get_leaves(%1002) : !cute.stride<"((32,1),(16,8,128))">
        %1003 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
        %1004 = cute.get_shape(%1003) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2491, %e1_2492, %e2_2493, %e3_2494 = cute.get_leaves(%1004) : !cute.shape<"((4,8),(2,2))">
        %1005 = cute.get_stride(%1003) : (!cute.layout<"((4,8),(2,2)):((16,1),(8,64))">) -> !cute.stride<"((16,1),(8,64))">
        %e0_2495, %e1_2496, %e2_2497, %e3_2498 = cute.get_leaves(%1005) : !cute.stride<"((16,1),(8,64))">
        %1006 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
        %1007 = cute.get_shape(%1006) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.shape<"((4,8),(2,2))">
        %e0_2499, %e1_2500, %e2_2501, %e3_2502 = cute.get_leaves(%1007) : !cute.shape<"((4,8),(2,2))">
        %1008 = cute.get_stride(%1006) : (!cute.layout<"((4,8),(2,2)):((32,1),(16,8))">) -> !cute.stride<"((32,1),(16,8))">
        %e0_2503, %e1_2504, %e2_2505, %e3_2506 = cute.get_leaves(%1008) : !cute.stride<"((32,1),(16,8))">
        %1009 = cute.static : !cute.tile<"[64:1;16:1]">
        %e0_2507, %e1_2508 = cute.get_leaves(%1009) : !cute.tile<"[64:1;16:1]">
        %1010 = cute.get_shape(%e0_2507) : (!cute.layout<"64:1">) -> !cute.shape<"64">
        %e0_2509 = cute.get_leaves(%1010) : !cute.shape<"64">
        %1011 = cute.get_stride(%e0_2507) : (!cute.layout<"64:1">) -> !cute.stride<"1">
        %e0_2510 = cute.get_leaves(%1011) : !cute.stride<"1">
        %1012 = cute.get_shape(%e1_2508) : (!cute.layout<"16:1">) -> !cute.shape<"16">
        %e0_2511 = cute.get_leaves(%1012) : !cute.shape<"16">
        %1013 = cute.get_stride(%e1_2508) : (!cute.layout<"16:1">) -> !cute.stride<"1">
        %e0_2512 = cute.get_leaves(%1013) : !cute.stride<"1">
        %1014 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
        %1015 = cute.get_shape(%1014) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.shape<"((4,8,4),((2,2),(1,2)))">
        %e0_2513, %e1_2514, %e2_2515, %e3_2516, %e4_2517, %e5_2518, %e6_2519 = cute.get_leaves(%1015) : !cute.shape<"((4,8,4),((2,2),(1,2)))">
        %1016 = cute.get_stride(%1014) : (!cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">) -> !cute.stride<"((128,1,16),((64,8),(0,512)))">
        %e0_2520, %e1_2521, %e2_2522, %e3_2523, %e4_2524, %e5_2525, %e6_2526 = cute.get_leaves(%1016) : !cute.stride<"((128,1,16),((64,8),(0,512)))">
        %1017 = cute.static : !cute.layout<"32:1">
        %1018 = cute.get_shape(%1017) : (!cute.layout<"32:1">) -> !cute.shape<"32">
        %e0_2527 = cute.get_leaves(%1018) : !cute.shape<"32">
        %1019 = cute.get_stride(%1017) : (!cute.layout<"32:1">) -> !cute.stride<"1">
        %e0_2528 = cute.get_leaves(%1019) : !cute.stride<"1">
        %1020 = cute.static : !cute.layout<"(32,8):(8,1)">
        %1021 = cute.get_shape(%1020) : (!cute.layout<"(32,8):(8,1)">) -> !cute.shape<"(32,8)">
        %e0_2529, %e1_2530 = cute.get_leaves(%1021) : !cute.shape<"(32,8)">
        %1022 = cute.get_stride(%1020) : (!cute.layout<"(32,8):(8,1)">) -> !cute.stride<"(8,1)">
        %e0_2531, %e1_2532 = cute.get_leaves(%1022) : !cute.stride<"(8,1)">
        %1023 = cute.static : !cute.layout<"(32,(2,4)):(2,(1,64))">
        %1024 = cute.get_shape(%1023) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.shape<"(32,(2,4))">
        %e0_2533, %e1_2534, %e2_2535 = cute.get_leaves(%1024) : !cute.shape<"(32,(2,4))">
        %1025 = cute.get_stride(%1023) : (!cute.layout<"(32,(2,4)):(2,(1,64))">) -> !cute.stride<"(2,(1,64))">
        %e0_2536, %e1_2537, %e2_2538 = cute.get_leaves(%1025) : !cute.stride<"(2,(1,64))">
        scf.yield %954#1, %arg14 : !mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3
      }
      %lay_1346 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %rmem_1347 = cute.memref.alloca(%lay_1346) : !memref_rmem_bf16_21
      %iter_1348 = cute.get_iter(%rmem_1347) : !memref_rmem_bf16_21
      %iter_1349 = cute.get_iter(%rmem_1347) : !memref_rmem_bf16_21
      %lay_1350 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %717 = cute.get_shape(%lay_1350) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_1351, %e1_1352, %e2_1353, %e3_1354 = cute.get_leaves(%717) : !cute.shape<"((2,2),1,16)">
      %718 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %719 = arith.truncf %718 : vector<64xf32> to vector<64xbf16>
      %lay_1355 = cute.get_layout(%rmem_1347) : !memref_rmem_bf16_21
      %720 = cute.get_shape(%lay_1355) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.shape<"((2,2),1,16)">
      %e0_1356, %e1_1357, %e2_1358, %e3_1359 = cute.get_leaves(%720) : !cute.shape<"((2,2),1,16)">
      %int_tuple_1360 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_1361 = cute.size(%int_tuple_1360) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_1362 = cute.get_leaves(%sz_1361) : !cute.int_tuple<"64">
      %int_tuple_1363 = cute.make_int_tuple() : () -> !cute.int_tuple<"((2,2),1,16)">
      %sz_1364 = cute.size(%int_tuple_1363) : (!cute.int_tuple<"((2,2),1,16)">) -> !cute.int_tuple<"64">
      %e0_1365 = cute.get_leaves(%sz_1364) : !cute.int_tuple<"64">
      cute.memref.store_vec %719, %rmem_1347, row_major : !memref_rmem_bf16_21
      %721 = cute.composed_get_inner(%arg8) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.swizzle<"S<3,4,3>">
      %iter_1366 = cute.recast_iter(%iter_273) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %722 = cute.composed_get_outer(%arg8) : (!cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %view_1367 = cute.make_view(%iter_1366, %722) : !memref_smem_bf16_23
      %iter_1368 = cute.get_iter(%view_1367) : !memref_smem_bf16_23
      %atom_1369 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %723 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %724 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1370, %e1_1371, %e2_1372 = cute.get_leaves(%724) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_1373 = cute.size(%e0_1370) : (!cute.layout<"64:1">) -> !cute.int_tuple<"64">
      %e0_1374 = cute.get_leaves(%sz_1373) : !cute.int_tuple<"64">
      %725 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %e0_1375, %e1_1376, %e2_1377 = cute.get_leaves(%725) : !cute.tile<"[64:1;16:1;16:1]">
      %sz_1378 = cute.size(%e1_1376) : (!cute.layout<"16:1">) -> !cute.int_tuple<"16">
      %e0_1379 = cute.get_leaves(%sz_1378) : !cute.int_tuple<"16">
      %tile_1380 = cute.make_tile() : () -> !cute.tile<"[64:1;16:1]">
      %726 = cute.make_tiled_copy(%atom_1369) : !copy_simt1
      %retiled_1381 = cute.tiled.copy.retile(%726, %rmem_1347) : (!copy_simt1, !memref_rmem_bf16_21) -> !memref_rmem_bf16_22
      %iter_1382 = cute.get_iter(%retiled_1381) : !memref_rmem_bf16_22
      %coord_1383 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1384 = cute.tiled.copy.partition_D(%726, %view_1367, %coord_1383) : (!copy_simt1, !memref_smem_bf16_23, !cute.coord<"?">) -> !memref_smem_bf16_24
      %iter_1385 = cute.get_iter(%dst_partitioned_1384) : !memref_smem_bf16_24
      %lay_1386 = cute.get_layout(%retiled_1381) : !memref_rmem_bf16_22
      %727 = cute.get_shape(%lay_1386) : (!cute.layout<"((1,8),1,8):((0,1),0,8)">) -> !cute.shape<"((1,8),1,8)">
      %e0_1387, %e1_1388, %e2_1389, %e3_1390 = cute.get_leaves(%727) : !cute.shape<"((1,8),1,8)">
      %lay_1391 = cute.get_layout(%dst_partitioned_1384) : !memref_smem_bf16_24
      %728 = cute.get_shape(%lay_1391) : (!cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">) -> !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %e0_1392, %e1_1393, %e2_1394, %e3_1395, %e4_1396, %e5_1397, %e6_1398 = cute.get_leaves(%728) : !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %lay_1399 = cute.get_layout(%retiled_1381) : !memref_rmem_bf16_22
      %shape_1400 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1401 = cute.make_layout(%shape_1400) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_1399, %lay_1401) : !cute.layout<"((1,8),1,8):((0,1),0,8)">, !cute.layout<"1:0">
      %view_1402 = cute.make_view(%iter_1382, %append) : !memref_rmem_bf16_22
      %iter_1403 = cute.get_iter(%view_1402) : !memref_rmem_bf16_22
      %lay_1404 = cute.get_layout(%view_1402) : !memref_rmem_bf16_22
      %729 = cute.get_shape(%lay_1404) : (!cute.layout<"((1,8),1,8):((0,1),0,8)">) -> !cute.shape<"((1,8),1,8)">
      %e0_1405, %e1_1406, %e2_1407, %e3_1408 = cute.get_leaves(%729) : !cute.shape<"((1,8),1,8)">
      %grouped = cute.group_modes(%view_1402) <1, 3> : (!memref_rmem_bf16_22) -> !memref_rmem_bf16_23
      %iter_1409 = cute.get_iter(%grouped) : !memref_rmem_bf16_23
      %iter_1410 = cute.get_iter(%grouped) : !memref_rmem_bf16_23
      %lay_1411 = cute.get_layout(%dst_partitioned_1384) : !memref_smem_bf16_24
      %shape_1412 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1413 = cute.make_layout(%shape_1412) : !cute.layout<"1:0">
      %append_1414 = cute.append_to_rank<2> (%lay_1411, %lay_1413) : !cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">, !cute.layout<"1:0">
      %view_1415 = cute.make_view(%iter_1385, %append_1414) : !memref_smem_bf16_24
      %iter_1416 = cute.get_iter(%view_1415) : !memref_smem_bf16_24
      %lay_1417 = cute.get_layout(%view_1415) : !memref_smem_bf16_24
      %730 = cute.get_shape(%lay_1417) : (!cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">) -> !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %e0_1418, %e1_1419, %e2_1420, %e3_1421, %e4_1422, %e5_1423, %e6_1424 = cute.get_leaves(%730) : !cute.shape<"((1,(2,2,2)),1,(4,2))">
      %grouped_1425 = cute.group_modes(%view_1415) <1, 3> : (!memref_smem_bf16_24) -> !memref_smem_bf16_25
      %iter_1426 = cute.get_iter(%grouped_1425) : !memref_smem_bf16_25
      %iter_1427 = cute.get_iter(%grouped_1425) : !memref_smem_bf16_25
      %lay_1428 = cute.get_layout(%grouped) : !memref_rmem_bf16_23
      %731 = cute.get_shape(%lay_1428) : (!cute.layout<"((1,8),(1,8)):((0,1),(0,8))">) -> !cute.shape<"((1,8),(1,8))">
      %e0_1429, %e1_1430, %e2_1431, %e3_1432 = cute.get_leaves(%731) : !cute.shape<"((1,8),(1,8))">
      %lay_1433 = cute.get_layout(%grouped_1425) : !memref_smem_bf16_25
      %732 = cute.get_shape(%lay_1433) : (!cute.layout<"((1,(2,2,2)),(1,(4,2))):((0,(1,512,8)),(0,(16,4096)))">) -> !cute.shape<"((1,(2,2,2)),(1,(4,2)))">
      %e0_1434, %e1_1435, %e2_1436, %e3_1437, %e4_1438, %e5_1439, %e6_1440 = cute.get_leaves(%732) : !cute.shape<"((1,(2,2,2)),(1,(4,2)))">
      %sz_1441 = cute.size(%grouped) <{mode = [1]}> : (!memref_rmem_bf16_23) -> !cute.int_tuple<"8">
      %e0_1442 = cute.get_leaves(%sz_1441) : !cute.int_tuple<"8">
      %sz_1443 = cute.size(%grouped_1425) <{mode = [1]}> : (!memref_smem_bf16_25) -> !cute.int_tuple<"8">
      %e0_1444 = cute.get_leaves(%sz_1443) : !cute.int_tuple<"8">
      cute.copy(%atom_1369, %grouped, %grouped_1425) : (!cute_nvgpu.atom.universal_copy<bf16>, !memref_rmem_bf16_23, !memref_smem_bf16_25)
      %coord_1445 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_1446 = cute.slice(%arg3, %coord_1445) : !memref_gmem_bf16_, !cute.coord<"(?,_,?,_)">
      %iter_1447 = cute.get_iter(%slice_1446) : !memref_gmem_bf16_1
      %tile_1448 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_1449 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_1450 = cute.local_tile(%slice_1446, %tile_1448, %coord_1449) : (!memref_gmem_bf16_1, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_1451 = cute.get_iter(%tiled_view_1450) : !memref_gmem_bf16_2
      %coord_1452 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %src_partitioned_1453 = cute.tiled.copy.partition_S(%arg10, %view_1367, %coord_1452) : (!copy_simt, !memref_smem_bf16_23, !cute.coord<"?">) -> !memref_smem_bf16_26
      %iter_1454 = cute.get_iter(%src_partitioned_1453) : !memref_smem_bf16_26
      %coord_1455 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1456 = cute.tiled.copy.partition_D(%arg10, %tiled_view_1450, %coord_1455) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_1457 = cute.get_iter(%dst_partitioned_1456) : !memref_gmem_bf16_5
      %lay_1458 = cute.get_layout(%dst_partitioned_1456) : !memref_gmem_bf16_5
      %733 = cute.make_layout_like(%lay_1458) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)"> to !cute.layout<"((8,1),4,2):((1,0),16,8)">
      %rmem_1459 = cute.memref.alloca(%733) : !memref_rmem_bf16_24
      %iter_1460 = cute.get_iter(%rmem_1459) : !memref_rmem_bf16_24
      %iter_1461 = cute.get_iter(%rmem_1459) : !memref_rmem_bf16_24
      %c1_i32_1462 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_1462 number_of_threads = %c128_i32
      %lay_1463 = cute.get_layout(%src_partitioned_1453) : !memref_smem_bf16_26
      %734 = cute.get_shape(%lay_1463) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1464, %e1_1465, %e2_1466, %e3_1467 = cute.get_leaves(%734) : !cute.shape<"((8,1),4,2)">
      %lay_1468 = cute.get_layout(%rmem_1459) : !memref_rmem_bf16_24
      %735 = cute.get_shape(%lay_1468) : (!cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1469, %e1_1470, %e2_1471, %e3_1472 = cute.get_leaves(%735) : !cute.shape<"((8,1),4,2)">
      %lay_1473 = cute.get_layout(%src_partitioned_1453) : !memref_smem_bf16_26
      %shape_1474 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1475 = cute.make_layout(%shape_1474) : !cute.layout<"1:0">
      %append_1476 = cute.append_to_rank<2> (%lay_1473, %lay_1475) : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">, !cute.layout<"1:0">
      %view_1477 = cute.make_view(%iter_1454, %append_1476) : !memref_smem_bf16_26
      %iter_1478 = cute.get_iter(%view_1477) : !memref_smem_bf16_26
      %lay_1479 = cute.get_layout(%view_1477) : !memref_smem_bf16_26
      %736 = cute.get_shape(%lay_1479) : (!cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1480, %e1_1481, %e2_1482, %e3_1483 = cute.get_leaves(%736) : !cute.shape<"((8,1),4,2)">
      %grouped_1484 = cute.group_modes(%view_1477) <1, 3> : (!memref_smem_bf16_26) -> !memref_smem_bf16_27
      %iter_1485 = cute.get_iter(%grouped_1484) : !memref_smem_bf16_27
      %iter_1486 = cute.get_iter(%grouped_1484) : !memref_smem_bf16_27
      %lay_1487 = cute.get_layout(%rmem_1459) : !memref_rmem_bf16_24
      %shape_1488 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_1489 = cute.make_layout(%shape_1488) : !cute.layout<"1:0">
      %append_1490 = cute.append_to_rank<2> (%lay_1487, %lay_1489) : !cute.layout<"((8,1),4,2):((1,0),16,8)">, !cute.layout<"1:0">
      %view_1491 = cute.make_view(%iter_1461, %append_1490) : !memref_rmem_bf16_24
      %iter_1492 = cute.get_iter(%view_1491) : !memref_rmem_bf16_24
      %lay_1493 = cute.get_layout(%view_1491) : !memref_rmem_bf16_24
      %737 = cute.get_shape(%lay_1493) : (!cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1494, %e1_1495, %e2_1496, %e3_1497 = cute.get_leaves(%737) : !cute.shape<"((8,1),4,2)">
      %grouped_1498 = cute.group_modes(%view_1491) <1, 3> : (!memref_rmem_bf16_24) -> !memref_rmem_bf16_25
      %iter_1499 = cute.get_iter(%grouped_1498) : !memref_rmem_bf16_25
      %iter_1500 = cute.get_iter(%grouped_1498) : !memref_rmem_bf16_25
      %lay_1501 = cute.get_layout(%grouped_1484) : !memref_smem_bf16_27
      %738 = cute.get_shape(%lay_1501) : (!cute.layout<"((8,1),(4,2)):((1,0),(1024,4096))">) -> !cute.shape<"((8,1),(4,2))">
      %e0_1502, %e1_1503, %e2_1504, %e3_1505 = cute.get_leaves(%738) : !cute.shape<"((8,1),(4,2))">
      %lay_1506 = cute.get_layout(%grouped_1498) : !memref_rmem_bf16_25
      %739 = cute.get_shape(%lay_1506) : (!cute.layout<"((8,1),(4,2)):((1,0),(16,8))">) -> !cute.shape<"((8,1),(4,2))">
      %e0_1507, %e1_1508, %e2_1509, %e3_1510 = cute.get_leaves(%739) : !cute.shape<"((8,1),(4,2))">
      %sz_1511 = cute.size(%grouped_1484) <{mode = [1]}> : (!memref_smem_bf16_27) -> !cute.int_tuple<"8">
      %e0_1512 = cute.get_leaves(%sz_1511) : !cute.int_tuple<"8">
      %sz_1513 = cute.size(%grouped_1498) <{mode = [1]}> : (!memref_rmem_bf16_25) -> !cute.int_tuple<"8">
      %e0_1514 = cute.get_leaves(%sz_1513) : !cute.int_tuple<"8">
      cute.copy(%arg10, %grouped_1484, %grouped_1498) : (!copy_simt, !memref_smem_bf16_27, !memref_rmem_bf16_25)
      %lay_1515 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %740 = cute.get_shape(%lay_1515) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1516, %e1_1517, %e2_1518, %e3_1519 = cute.get_leaves(%740) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1520 = cute.to_int_tuple(%e0_1516) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %741 = cute.get_scalars(%itup_1520) : !cute.int_tuple<"?">
      %itup_1521 = cute.to_int_tuple(%e1_1517) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %742 = cute.get_scalars(%itup_1521) : !cute.int_tuple<"?">
      %itup_1522 = cute.to_int_tuple(%e2_1518) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %743 = cute.get_scalars(%itup_1522) : !cute.int_tuple<"?">
      %itup_1523 = cute.to_int_tuple(%e3_1519) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %744 = cute.get_scalars(%itup_1523) : !cute.int_tuple<"?{div=8}">
      %shape_1524 = cute.make_shape(%itup_1520, %itup_1521, %itup_1522, %itup_1523) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %745 = cute.make_identity_tensor(%shape_1524) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iter_1525 = cute.get_iter(%745) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %e0_1526, %e1_1527, %e2_1528, %e3_1529 = cute.get_leaves(%iter_1525) : !cute.int_tuple<"(0,0,0,0)">
      %coord_1530 = cute.make_coord(%125, %126) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %slice_1531 = cute.slice(%745, %coord_1530) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">, !cute.coord<"(?,_,?,_)">
      %iter_1532 = cute.get_iter(%slice_1531) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %e0_1533, %e1_1534, %e2_1535, %e3_1536 = cute.get_leaves(%iter_1532) : !cute.int_tuple<"(?,0,?,0)">
      %746 = cute.get_scalars(%e0_1533) : !cute.int_tuple<"?">
      %747 = cute.get_scalars(%e2_1535) : !cute.int_tuple<"?">
      %tile_1537 = cute.make_tile() : () -> !cute.tile<"[64:1;128:1]">
      %coord_1538 = cute.make_coord(%sub_222) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %tiled_view_1539 = cute.local_tile(%slice_1531, %tile_1537, %coord_1538) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">, !cute.tile<"[64:1;128:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %iter_1540 = cute.get_iter(%tiled_view_1539) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %e0_1541, %e1_1542, %e2_1543, %e3_1544 = cute.get_leaves(%iter_1540) : !cute.int_tuple<"(?,?{div=64},?,0)">
      %748 = cute.get_scalars(%e0_1541) : !cute.int_tuple<"?">
      %749 = cute.get_scalars(%e1_1542) : !cute.int_tuple<"?{div=64}">
      %750 = cute.get_scalars(%e2_1543) : !cute.int_tuple<"?">
      %coord_1545 = cute.make_coord(%122) : (i32) -> !cute.coord<"?">
      %dst_partitioned_1546 = cute.tiled.copy.partition_D(%arg10, %tiled_view_1539, %coord_1545) : (!copy_simt, !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %iter_1547 = cute.get_iter(%dst_partitioned_1546) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %e0_1548, %e1_1549, %e2_1550, %e3_1551 = cute.get_leaves(%iter_1547) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %751 = cute.get_scalars(%e0_1548) : !cute.int_tuple<"?">
      %752 = cute.get_scalars(%e1_1549) : !cute.int_tuple<"?">
      %753 = cute.get_scalars(%e2_1550) : !cute.int_tuple<"?">
      %754 = cute.get_scalars(%e3_1551) : !cute.int_tuple<"?{div=8}">
      %lay_1552 = cute.get_layout(%dst_partitioned_1456) : !memref_gmem_bf16_5
      %755 = cute.get_shape(%lay_1552) : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.shape<"((8,1),4,2)">
      %e0_1553, %e1_1554, %e2_1555, %e3_1556 = cute.get_leaves(%755) : !cute.shape<"((8,1),4,2)">
      %shape_1557 = cute.make_shape() : () -> !cute.shape<"(1,4,2)">
      %stride_1558 = cute.make_stride() : () -> !cute.stride<"(2,0,1)">
      %lay_1559 = cute.make_layout(%shape_1557, %stride_1558) : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_1560 = cute.memref.alloca(%lay_1559) : !memref_rmem_i8_
      %iter_1561 = cute.get_iter(%rmem_1560) : !memref_rmem_i8_
      %iter_1562 = cute.get_iter(%rmem_1560) : !memref_rmem_i8_
      %lay_1563 = cute.get_layout(%rmem_1560) : !memref_rmem_i8_
      %756 = cute.get_shape(%lay_1563) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !cute.shape<"(1,4,2)">
      %e0_1564, %e1_1565, %e2_1566 = cute.get_leaves(%756) : !cute.shape<"(1,4,2)">
      %int_tuple_1567 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_1568 = cute.size(%int_tuple_1567) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_1569 = cute.get_leaves(%sz_1568) : !cute.int_tuple<"2">
      %coord_1570 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_1571 = cute.slice(%dst_partitioned_1546, %coord_1570) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,0)">
      %iter_1572 = cute.get_iter(%slice_1571) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1573, %e1_1574, %e2_1575, %e3_1576 = cute.get_leaves(%iter_1572) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %757 = cute.get_scalars(%e0_1573) : !cute.int_tuple<"?">
      %758 = cute.get_scalars(%e1_1574) : !cute.int_tuple<"?">
      %759 = cute.get_scalars(%e2_1575) : !cute.int_tuple<"?">
      %760 = cute.get_scalars(%e3_1576) : !cute.int_tuple<"?{div=8}">
      %iter_1577 = cute.get_iter(%slice_1571) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1578, %e1_1579, %e2_1580, %e3_1581 = cute.get_leaves(%iter_1577) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %761 = cute.get_scalars(%e0_1578) : !cute.int_tuple<"?">
      %762 = cute.get_scalars(%e1_1579) : !cute.int_tuple<"?">
      %763 = cute.get_scalars(%e2_1580) : !cute.int_tuple<"?">
      %764 = cute.get_scalars(%e3_1581) : !cute.int_tuple<"?{div=8}">
      %iter_1582 = cute.get_iter(%slice_1571) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1583, %e1_1584, %e2_1585, %e3_1586 = cute.get_leaves(%iter_1582) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %765 = cute.get_scalars(%e0_1583) : !cute.int_tuple<"?">
      %766 = cute.get_scalars(%e1_1584) : !cute.int_tuple<"?">
      %767 = cute.get_scalars(%e2_1585) : !cute.int_tuple<"?">
      %768 = cute.get_scalars(%e3_1586) : !cute.int_tuple<"?{div=8}">
      %lay_1587 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %769 = cute.get_shape(%lay_1587) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1588, %e1_1589, %e2_1590, %e3_1591 = cute.get_leaves(%769) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1592 = cute.to_int_tuple(%e0_1588) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %770 = cute.get_scalars(%itup_1592) : !cute.int_tuple<"?">
      %itup_1593 = cute.to_int_tuple(%e1_1589) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %771 = cute.get_scalars(%itup_1593) : !cute.int_tuple<"?">
      %itup_1594 = cute.to_int_tuple(%e2_1590) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %772 = cute.get_scalars(%itup_1594) : !cute.int_tuple<"?">
      %itup_1595 = cute.to_int_tuple(%e3_1591) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %773 = cute.get_scalars(%itup_1595) : !cute.int_tuple<"?{div=8}">
      %coord_1596 = cute.make_coord(%e3_1586) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1597 = cute.make_coord(%itup_1595) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %774 = cute.elem_less(%coord_1596, %coord_1597) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %775 = arith.extui %774 : i1 to i8
      %coord_1598 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_1560, %coord_1598, %775) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_1599 = cute.make_coord() : () -> !cute.coord<"((0,0),0,1)">
      %slice_1600 = cute.slice(%dst_partitioned_1546, %coord_1599) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"((0,0),0,1)">
      %iter_1601 = cute.get_iter(%slice_1600) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1602, %e1_1603, %e2_1604, %e3_1605 = cute.get_leaves(%iter_1601) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %776 = cute.get_scalars(%e0_1602) : !cute.int_tuple<"?">
      %777 = cute.get_scalars(%e1_1603) : !cute.int_tuple<"?">
      %778 = cute.get_scalars(%e2_1604) : !cute.int_tuple<"?">
      %779 = cute.get_scalars(%e3_1605) : !cute.int_tuple<"?{div=8}">
      %iter_1606 = cute.get_iter(%slice_1600) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1607, %e1_1608, %e2_1609, %e3_1610 = cute.get_leaves(%iter_1606) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %780 = cute.get_scalars(%e0_1607) : !cute.int_tuple<"?">
      %781 = cute.get_scalars(%e1_1608) : !cute.int_tuple<"?">
      %782 = cute.get_scalars(%e2_1609) : !cute.int_tuple<"?">
      %783 = cute.get_scalars(%e3_1610) : !cute.int_tuple<"?{div=8}">
      %iter_1611 = cute.get_iter(%slice_1600) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1612, %e1_1613, %e2_1614, %e3_1615 = cute.get_leaves(%iter_1611) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %784 = cute.get_scalars(%e0_1612) : !cute.int_tuple<"?">
      %785 = cute.get_scalars(%e1_1613) : !cute.int_tuple<"?">
      %786 = cute.get_scalars(%e2_1614) : !cute.int_tuple<"?">
      %787 = cute.get_scalars(%e3_1615) : !cute.int_tuple<"?{div=8}">
      %lay_1616 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %788 = cute.get_shape(%lay_1616) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1617, %e1_1618, %e2_1619, %e3_1620 = cute.get_leaves(%788) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1621 = cute.to_int_tuple(%e0_1617) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %789 = cute.get_scalars(%itup_1621) : !cute.int_tuple<"?">
      %itup_1622 = cute.to_int_tuple(%e1_1618) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %790 = cute.get_scalars(%itup_1622) : !cute.int_tuple<"?">
      %itup_1623 = cute.to_int_tuple(%e2_1619) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %791 = cute.get_scalars(%itup_1623) : !cute.int_tuple<"?">
      %itup_1624 = cute.to_int_tuple(%e3_1620) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %792 = cute.get_scalars(%itup_1624) : !cute.int_tuple<"?{div=8}">
      %coord_1625 = cute.make_coord(%e3_1615) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1626 = cute.make_coord(%itup_1624) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %793 = cute.elem_less(%coord_1625, %coord_1626) : !cute.coord<"?{div=8}">, !cute.coord<"?{div=8}">
      %794 = arith.extui %793 : i1 to i8
      %coord_1627 = cute.make_coord() : () -> !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_1560, %coord_1627, %794) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %int_tuple_1628 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %sz_1629 = cute.size(%int_tuple_1628) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
      %e0_1630 = cute.get_leaves(%sz_1629) : !cute.int_tuple<"4">
      %coord_1631 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      %slice_1632 = cute.slice(%dst_partitioned_1546, %coord_1631) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,0,0)">
      %iter_1633 = cute.get_iter(%slice_1632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1634, %e1_1635, %e2_1636, %e3_1637 = cute.get_leaves(%iter_1633) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %795 = cute.get_scalars(%e0_1634) : !cute.int_tuple<"?">
      %796 = cute.get_scalars(%e1_1635) : !cute.int_tuple<"?">
      %797 = cute.get_scalars(%e2_1636) : !cute.int_tuple<"?">
      %798 = cute.get_scalars(%e3_1637) : !cute.int_tuple<"?{div=8}">
      %iter_1638 = cute.get_iter(%slice_1632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1639, %e1_1640, %e2_1641, %e3_1642 = cute.get_leaves(%iter_1638) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %799 = cute.get_scalars(%e0_1639) : !cute.int_tuple<"?">
      %800 = cute.get_scalars(%e1_1640) : !cute.int_tuple<"?">
      %801 = cute.get_scalars(%e2_1641) : !cute.int_tuple<"?">
      %802 = cute.get_scalars(%e3_1642) : !cute.int_tuple<"?{div=8}">
      %iter_1643 = cute.get_iter(%slice_1632) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1644, %e1_1645, %e2_1646, %e3_1647 = cute.get_leaves(%iter_1643) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %803 = cute.get_scalars(%e0_1644) : !cute.int_tuple<"?">
      %804 = cute.get_scalars(%e1_1645) : !cute.int_tuple<"?">
      %805 = cute.get_scalars(%e2_1646) : !cute.int_tuple<"?">
      %806 = cute.get_scalars(%e3_1647) : !cute.int_tuple<"?{div=8}">
      %lay_1648 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %807 = cute.get_shape(%lay_1648) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1649, %e1_1650, %e2_1651, %e3_1652 = cute.get_leaves(%807) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1653 = cute.to_int_tuple(%e0_1649) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %808 = cute.get_scalars(%itup_1653) : !cute.int_tuple<"?">
      %itup_1654 = cute.to_int_tuple(%e1_1650) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %809 = cute.get_scalars(%itup_1654) : !cute.int_tuple<"?">
      %itup_1655 = cute.to_int_tuple(%e2_1651) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %810 = cute.get_scalars(%itup_1655) : !cute.int_tuple<"?">
      %itup_1656 = cute.to_int_tuple(%e3_1652) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %811 = cute.get_scalars(%itup_1656) : !cute.int_tuple<"?{div=8}">
      %coord_1657 = cute.make_coord(%e1_1645) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1658 = cute.make_coord(%itup_1654) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %812 = cute.elem_less(%coord_1657, %coord_1658) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %812 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1744 = cute.slice(%rmem_1459, %coord_1743) : !memref_rmem_bf16_24, !cute.coord<"(_,0,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_rmem_bf16_26
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1747 = cute.slice(%dst_partitioned_1456, %coord_1746) : !memref_gmem_bf16_5, !cute.coord<"(_,0,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_gmem_bf16_8
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,0,_)">
        %slice_1750 = cute.slice(%rmem_1560, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,0,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_rmem_bf16_26
        %iter_1765 = cute.get_iter(%view_1764) : !memref_rmem_bf16_26
        %lay_1766 = cute.get_layout(%view_1764) : !memref_rmem_bf16_26
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_gmem_bf16_8
        %iter_1778 = cute.get_iter(%view_1777) : !memref_gmem_bf16_8
        %lay_1779 = cute.get_layout(%view_1777) : !memref_gmem_bf16_8
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_rmem_bf16_27
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_gmem_bf16_9
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg10, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1659 = cute.make_coord() : () -> !cute.coord<"(0,1,0)">
      %slice_1660 = cute.slice(%dst_partitioned_1546, %coord_1659) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,1,0)">
      %iter_1661 = cute.get_iter(%slice_1660) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1662, %e1_1663, %e2_1664, %e3_1665 = cute.get_leaves(%iter_1661) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %813 = cute.get_scalars(%e0_1662) : !cute.int_tuple<"?">
      %814 = cute.get_scalars(%e1_1663) : !cute.int_tuple<"?">
      %815 = cute.get_scalars(%e2_1664) : !cute.int_tuple<"?">
      %816 = cute.get_scalars(%e3_1665) : !cute.int_tuple<"?{div=8}">
      %iter_1666 = cute.get_iter(%slice_1660) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1667, %e1_1668, %e2_1669, %e3_1670 = cute.get_leaves(%iter_1666) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %817 = cute.get_scalars(%e0_1667) : !cute.int_tuple<"?">
      %818 = cute.get_scalars(%e1_1668) : !cute.int_tuple<"?">
      %819 = cute.get_scalars(%e2_1669) : !cute.int_tuple<"?">
      %820 = cute.get_scalars(%e3_1670) : !cute.int_tuple<"?{div=8}">
      %iter_1671 = cute.get_iter(%slice_1660) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1672, %e1_1673, %e2_1674, %e3_1675 = cute.get_leaves(%iter_1671) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %821 = cute.get_scalars(%e0_1672) : !cute.int_tuple<"?">
      %822 = cute.get_scalars(%e1_1673) : !cute.int_tuple<"?">
      %823 = cute.get_scalars(%e2_1674) : !cute.int_tuple<"?">
      %824 = cute.get_scalars(%e3_1675) : !cute.int_tuple<"?{div=8}">
      %lay_1676 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %825 = cute.get_shape(%lay_1676) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1677, %e1_1678, %e2_1679, %e3_1680 = cute.get_leaves(%825) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1681 = cute.to_int_tuple(%e0_1677) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %826 = cute.get_scalars(%itup_1681) : !cute.int_tuple<"?">
      %itup_1682 = cute.to_int_tuple(%e1_1678) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %827 = cute.get_scalars(%itup_1682) : !cute.int_tuple<"?">
      %itup_1683 = cute.to_int_tuple(%e2_1679) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %828 = cute.get_scalars(%itup_1683) : !cute.int_tuple<"?">
      %itup_1684 = cute.to_int_tuple(%e3_1680) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %829 = cute.get_scalars(%itup_1684) : !cute.int_tuple<"?{div=8}">
      %coord_1685 = cute.make_coord(%e1_1673) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1686 = cute.make_coord(%itup_1682) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %830 = cute.elem_less(%coord_1685, %coord_1686) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %830 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1744 = cute.slice(%rmem_1459, %coord_1743) : !memref_rmem_bf16_24, !cute.coord<"(_,1,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_rmem_bf16_26
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1747 = cute.slice(%dst_partitioned_1456, %coord_1746) : !memref_gmem_bf16_5, !cute.coord<"(_,1,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_gmem_bf16_8
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,1,_)">
        %slice_1750 = cute.slice(%rmem_1560, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,1,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_rmem_bf16_26
        %iter_1765 = cute.get_iter(%view_1764) : !memref_rmem_bf16_26
        %lay_1766 = cute.get_layout(%view_1764) : !memref_rmem_bf16_26
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_gmem_bf16_8
        %iter_1778 = cute.get_iter(%view_1777) : !memref_gmem_bf16_8
        %lay_1779 = cute.get_layout(%view_1777) : !memref_gmem_bf16_8
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_rmem_bf16_27
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_gmem_bf16_9
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg10, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1687 = cute.make_coord() : () -> !cute.coord<"(0,2,0)">
      %slice_1688 = cute.slice(%dst_partitioned_1546, %coord_1687) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,2,0)">
      %iter_1689 = cute.get_iter(%slice_1688) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1690, %e1_1691, %e2_1692, %e3_1693 = cute.get_leaves(%iter_1689) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %831 = cute.get_scalars(%e0_1690) : !cute.int_tuple<"?">
      %832 = cute.get_scalars(%e1_1691) : !cute.int_tuple<"?">
      %833 = cute.get_scalars(%e2_1692) : !cute.int_tuple<"?">
      %834 = cute.get_scalars(%e3_1693) : !cute.int_tuple<"?{div=8}">
      %iter_1694 = cute.get_iter(%slice_1688) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1695, %e1_1696, %e2_1697, %e3_1698 = cute.get_leaves(%iter_1694) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %835 = cute.get_scalars(%e0_1695) : !cute.int_tuple<"?">
      %836 = cute.get_scalars(%e1_1696) : !cute.int_tuple<"?">
      %837 = cute.get_scalars(%e2_1697) : !cute.int_tuple<"?">
      %838 = cute.get_scalars(%e3_1698) : !cute.int_tuple<"?{div=8}">
      %iter_1699 = cute.get_iter(%slice_1688) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1700, %e1_1701, %e2_1702, %e3_1703 = cute.get_leaves(%iter_1699) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %839 = cute.get_scalars(%e0_1700) : !cute.int_tuple<"?">
      %840 = cute.get_scalars(%e1_1701) : !cute.int_tuple<"?">
      %841 = cute.get_scalars(%e2_1702) : !cute.int_tuple<"?">
      %842 = cute.get_scalars(%e3_1703) : !cute.int_tuple<"?{div=8}">
      %lay_1704 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %843 = cute.get_shape(%lay_1704) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1705, %e1_1706, %e2_1707, %e3_1708 = cute.get_leaves(%843) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1709 = cute.to_int_tuple(%e0_1705) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %844 = cute.get_scalars(%itup_1709) : !cute.int_tuple<"?">
      %itup_1710 = cute.to_int_tuple(%e1_1706) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %845 = cute.get_scalars(%itup_1710) : !cute.int_tuple<"?">
      %itup_1711 = cute.to_int_tuple(%e2_1707) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %846 = cute.get_scalars(%itup_1711) : !cute.int_tuple<"?">
      %itup_1712 = cute.to_int_tuple(%e3_1708) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %847 = cute.get_scalars(%itup_1712) : !cute.int_tuple<"?{div=8}">
      %coord_1713 = cute.make_coord(%e1_1701) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1714 = cute.make_coord(%itup_1710) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %848 = cute.elem_less(%coord_1713, %coord_1714) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %848 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1744 = cute.slice(%rmem_1459, %coord_1743) : !memref_rmem_bf16_24, !cute.coord<"(_,2,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_rmem_bf16_26
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1747 = cute.slice(%dst_partitioned_1456, %coord_1746) : !memref_gmem_bf16_5, !cute.coord<"(_,2,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_gmem_bf16_8
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,2,_)">
        %slice_1750 = cute.slice(%rmem_1560, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,2,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_rmem_bf16_26
        %iter_1765 = cute.get_iter(%view_1764) : !memref_rmem_bf16_26
        %lay_1766 = cute.get_layout(%view_1764) : !memref_rmem_bf16_26
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_gmem_bf16_8
        %iter_1778 = cute.get_iter(%view_1777) : !memref_gmem_bf16_8
        %lay_1779 = cute.get_layout(%view_1777) : !memref_gmem_bf16_8
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_rmem_bf16_27
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_gmem_bf16_9
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg10, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      %coord_1715 = cute.make_coord() : () -> !cute.coord<"(0,3,0)">
      %slice_1716 = cute.slice(%dst_partitioned_1546, %coord_1715) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">, !cute.coord<"(0,3,0)">
      %iter_1717 = cute.get_iter(%slice_1716) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1718, %e1_1719, %e2_1720, %e3_1721 = cute.get_leaves(%iter_1717) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %849 = cute.get_scalars(%e0_1718) : !cute.int_tuple<"?">
      %850 = cute.get_scalars(%e1_1719) : !cute.int_tuple<"?">
      %851 = cute.get_scalars(%e2_1720) : !cute.int_tuple<"?">
      %852 = cute.get_scalars(%e3_1721) : !cute.int_tuple<"?{div=8}">
      %iter_1722 = cute.get_iter(%slice_1716) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1723, %e1_1724, %e2_1725, %e3_1726 = cute.get_leaves(%iter_1722) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %853 = cute.get_scalars(%e0_1723) : !cute.int_tuple<"?">
      %854 = cute.get_scalars(%e1_1724) : !cute.int_tuple<"?">
      %855 = cute.get_scalars(%e2_1725) : !cute.int_tuple<"?">
      %856 = cute.get_scalars(%e3_1726) : !cute.int_tuple<"?{div=8}">
      %iter_1727 = cute.get_iter(%slice_1716) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_1728, %e1_1729, %e2_1730, %e3_1731 = cute.get_leaves(%iter_1727) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %857 = cute.get_scalars(%e0_1728) : !cute.int_tuple<"?">
      %858 = cute.get_scalars(%e1_1729) : !cute.int_tuple<"?">
      %859 = cute.get_scalars(%e2_1730) : !cute.int_tuple<"?">
      %860 = cute.get_scalars(%e3_1731) : !cute.int_tuple<"?{div=8}">
      %lay_1732 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %861 = cute.get_shape(%lay_1732) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1733, %e1_1734, %e2_1735, %e3_1736 = cute.get_leaves(%861) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1737 = cute.to_int_tuple(%e0_1733) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %862 = cute.get_scalars(%itup_1737) : !cute.int_tuple<"?">
      %itup_1738 = cute.to_int_tuple(%e1_1734) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %863 = cute.get_scalars(%itup_1738) : !cute.int_tuple<"?">
      %itup_1739 = cute.to_int_tuple(%e2_1735) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %864 = cute.get_scalars(%itup_1739) : !cute.int_tuple<"?">
      %itup_1740 = cute.to_int_tuple(%e3_1736) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %865 = cute.get_scalars(%itup_1740) : !cute.int_tuple<"?{div=8}">
      %coord_1741 = cute.make_coord(%e1_1729) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1742 = cute.make_coord(%itup_1738) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %866 = cute.elem_less(%coord_1741, %coord_1742) : !cute.coord<"?">, !cute.coord<"?">
      scf.if %866 {
        %coord_1743 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1744 = cute.slice(%rmem_1459, %coord_1743) : !memref_rmem_bf16_24, !cute.coord<"(_,3,_)">
        %iter_1745 = cute.get_iter(%slice_1744) : !memref_rmem_bf16_26
        %coord_1746 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1747 = cute.slice(%dst_partitioned_1456, %coord_1746) : !memref_gmem_bf16_5, !cute.coord<"(_,3,_)">
        %iter_1748 = cute.get_iter(%slice_1747) : !memref_gmem_bf16_8
        %coord_1749 = cute.make_coord() : () -> !cute.coord<"(_,3,_)">
        %slice_1750 = cute.slice(%rmem_1560, %coord_1749) : !memref_rmem_i8_, !cute.coord<"(_,3,_)">
        %iter_1751 = cute.get_iter(%slice_1750) : !memref_rmem_i8_1
        %lay_1752 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %867 = cute.get_shape(%lay_1752) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1753, %e1_1754, %e2_1755 = cute.get_leaves(%867) : !cute.shape<"((8,1),2)">
        %lay_1756 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %868 = cute.get_shape(%lay_1756) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1757, %e1_1758, %e2_1759 = cute.get_leaves(%868) : !cute.shape<"((8,1),2)">
        %lay_1760 = cute.get_layout(%slice_1744) : !memref_rmem_bf16_26
        %shape_1761 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1762 = cute.make_layout(%shape_1761) : !cute.layout<"1:0">
        %append_1763 = cute.append_to_rank<2> (%lay_1760, %lay_1762) : !cute.layout<"((8,1),2):((1,0),8)">, !cute.layout<"1:0">
        %view_1764 = cute.make_view(%iter_1745, %append_1763) : !memref_rmem_bf16_26
        %iter_1765 = cute.get_iter(%view_1764) : !memref_rmem_bf16_26
        %lay_1766 = cute.get_layout(%view_1764) : !memref_rmem_bf16_26
        %869 = cute.get_shape(%lay_1766) : (!cute.layout<"((8,1),2):((1,0),8)">) -> !cute.shape<"((8,1),2)">
        %e0_1767, %e1_1768, %e2_1769 = cute.get_leaves(%869) : !cute.shape<"((8,1),2)">
        %grouped_1770 = cute.group_modes(%view_1764) <1, 2> : (!memref_rmem_bf16_26) -> !memref_rmem_bf16_27
        %iter_1771 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %iter_1772 = cute.get_iter(%grouped_1770) : !memref_rmem_bf16_27
        %lay_1773 = cute.get_layout(%slice_1747) : !memref_gmem_bf16_8
        %shape_1774 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1775 = cute.make_layout(%shape_1774) : !cute.layout<"1:0">
        %append_1776 = cute.append_to_rank<2> (%lay_1773, %lay_1775) : !cute.layout<"((8,1),2):((1,0),64)">, !cute.layout<"1:0">
        %view_1777 = cute.make_view(%iter_1748, %append_1776) : !memref_gmem_bf16_8
        %iter_1778 = cute.get_iter(%view_1777) : !memref_gmem_bf16_8
        %lay_1779 = cute.get_layout(%view_1777) : !memref_gmem_bf16_8
        %870 = cute.get_shape(%lay_1779) : (!cute.layout<"((8,1),2):((1,0),64)">) -> !cute.shape<"((8,1),2)">
        %e0_1780, %e1_1781, %e2_1782 = cute.get_leaves(%870) : !cute.shape<"((8,1),2)">
        %grouped_1783 = cute.group_modes(%view_1777) <1, 2> : (!memref_gmem_bf16_8) -> !memref_gmem_bf16_9
        %iter_1784 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %iter_1785 = cute.get_iter(%grouped_1783) : !memref_gmem_bf16_9
        %lay_1786 = cute.get_layout(%slice_1750) : !memref_rmem_i8_1
        %shape_1787 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_1788 = cute.make_layout(%shape_1787) : !cute.layout<"1:0">
        %append_1789 = cute.append_to_rank<2> (%lay_1786, %lay_1788) : !cute.layout<"(1,2):(2,1)">, !cute.layout<"1:0">
        %view_1790 = cute.make_view(%iter_1751, %append_1789) : !memref_rmem_i8_1
        %iter_1791 = cute.get_iter(%view_1790) : !memref_rmem_i8_1
        %lay_1792 = cute.get_layout(%view_1790) : !memref_rmem_i8_1
        %871 = cute.get_shape(%lay_1792) : (!cute.layout<"(1,2):(2,1)">) -> !cute.shape<"(1,2)">
        %e0_1793, %e1_1794 = cute.get_leaves(%871) : !cute.shape<"(1,2)">
        %grouped_1795 = cute.group_modes(%view_1790) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_1796 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %iter_1797 = cute.get_iter(%grouped_1795) : !memref_rmem_i8_2
        %lay_1798 = cute.get_layout(%grouped_1770) : !memref_rmem_bf16_27
        %872 = cute.get_shape(%lay_1798) : (!cute.layout<"((8,1),(2)):((1,0),(8))">) -> !cute.shape<"((8,1),(2))">
        %e0_1799, %e1_1800, %e2_1801 = cute.get_leaves(%872) : !cute.shape<"((8,1),(2))">
        %lay_1802 = cute.get_layout(%grouped_1783) : !memref_gmem_bf16_9
        %873 = cute.get_shape(%lay_1802) : (!cute.layout<"((8,1),(2)):((1,0),(64))">) -> !cute.shape<"((8,1),(2))">
        %e0_1803, %e1_1804, %e2_1805 = cute.get_leaves(%873) : !cute.shape<"((8,1),(2))">
        %sz_1806 = cute.size(%grouped_1770) <{mode = [1]}> : (!memref_rmem_bf16_27) -> !cute.int_tuple<"2">
        %e0_1807 = cute.get_leaves(%sz_1806) : !cute.int_tuple<"2">
        %sz_1808 = cute.size(%grouped_1783) <{mode = [1]}> : (!memref_gmem_bf16_9) -> !cute.int_tuple<"2">
        %e0_1809 = cute.get_leaves(%sz_1808) : !cute.int_tuple<"2">
        cute.copy(%arg10, %grouped_1770, %grouped_1783, %grouped_1795) : (!copy_simt, !memref_rmem_bf16_27, !memref_gmem_bf16_9, !memref_rmem_i8_2)
      }
      return
    }
  }
  func.func @cutlass___call_____main__HSTUAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Ten(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !gpu.async.token) attributes {llvm.emit_c_interface} {
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
    %c4 = arith.constant 4 : index
    %185 = arith.index_cast %62 : i32 to index
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
    %c57344_i32 = arith.constant 57344 : i32
    %186 = gpu.launch_func async [%arg5] @kernels::@kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8_0 blocks in (%c4, %c4, %185) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c57344_i32 args(%arg0 : !memref_gmem_bf16_, %arg1 : !memref_gmem_bf16_, %arg2 : !memref_gmem_bf16_, %arg3 : !memref_gmem_bf16_, %arg4 : !memref_gmem_bf16_, %tile_to_shape : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %tile_to_shape_91 : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %tile_to_shape_94 : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">, %tile_to_shape : !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">, %51 : !copy_ldgsts, %54 : !copy_simt, %56 : !mma_bf16_bf16_f32_16x8x16_) {use_pdl = false}
    return
  }
}
