!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = global, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">, tiler_mn = <"[64:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_2 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_simt1 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(?,?{div=8}):(?{i64 div=8},1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(128,128):(?{i64 div=8},1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "((8,1),8,2):((1,0),?{i64 div=128},64)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,1),2):((1,0),64)">
!memref_gmem_bf16_7 = !cute.memref<bf16, gmem, align<16>, "((8,1),(2)):((1,0),(64))">
!memref_gmem_bf16_8 = !cute.memref<bf16, gmem, align<16>, "((8,1)):((1,0))">
!memref_gmem_bf16_9 = !cute.memref<bf16, gmem, align<16>, "((8,1),4,2):((1,0),?{i64 div=128},64)">
!memref_gmem_bf16_10 = !cute.memref<bf16, gmem, align<16>, "((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<16>, "((2,2,2),2,((2,2),2)):((1,2,4),8,((32,64),16))">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<8>, "((2,2),8,((2,2),2)):((1,2),4,((64,128),32))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2),4):((1,2),(4,128),32)">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<16>, "((8,1),2,(4,2)):((1,0),8,(32,16))">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<8>, "((8,1),4,(4,2)):((1,0),8,(64,32))">
!memref_rmem_bf16_5 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4,2),4):((1,0),(8,128),32)">
!memref_rmem_bf16_6 = !cute.memref<bf16, rmem, align<16>, "((8,1),2):((1,0),8)">
!memref_rmem_bf16_7 = !cute.memref<bf16, rmem, align<16>, "((8,1),(2)):((1,0),(8))">
!memref_rmem_bf16_8 = !cute.memref<bf16, rmem, align<16>, "((8,1)):((1,0))">
!memref_rmem_bf16_9 = !cute.memref<bf16, rmem, align<8>, "((8,1),4):((1,0),8)">
!memref_rmem_bf16_10 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4)):((1,0),(8))">
!memref_rmem_bf16_11 = !cute.memref<bf16, rmem, align<8>, "((8,1)):((1,0))">
!memref_rmem_bf16_12 = !cute.memref<bf16, rmem, align<16>, "((2,2,2),2):((1,2,4),8)">
!memref_rmem_bf16_13 = !cute.memref<bf16, rmem, align<8>, "((2,2),8):((1,2),4)">
!memref_rmem_bf16_14 = !cute.memref<bf16, rmem, align<16>, "((2,2,2)):((1,2,4))">
!memref_rmem_bf16_15 = !cute.memref<bf16, rmem, align<8>, "((2,2)):((1,2))">
!memref_rmem_bf16_16 = !cute.memref<bf16, rmem, align<32>, "((2,2),2,8):((1,2),4,8)">
!memref_rmem_bf16_17 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),2,4):(((1,2),8),4,16)">
!memref_rmem_bf16_18 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4,2)):((1,0),(8,128))">
!memref_rmem_bf16_19 = !cute.memref<bf16, rmem, align<8>, "((8,1),((4,2))):((1,0),((8,128)))">
!memref_rmem_bf16_20 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),2):(((1,2),8),4)">
!memref_rmem_bf16_21 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2)):((1,2),(4,128))">
!memref_rmem_bf16_22 = !cute.memref<bf16, rmem, align<8>, "(((2,2),2)):(((1,2),8))">
!memref_rmem_bf16_23 = !cute.memref<bf16, rmem, align<32>, "((2,2),2,16):((1,2),4,8)">
!memref_rmem_bf16_24 = !cute.memref<bf16, rmem, align<32>, "((1,(4,2)),2,8):((0,(1,8)),4,16)">
!memref_rmem_bf16_25 = !cute.memref<bf16, rmem, align<32>, "((1,(4,2)),(2,8)):((0,(1,8)),(4,16))">
!memref_rmem_bf16_26 = !cute.memref<bf16, rmem, align<8>, "((1,(4,2))):((0,(1,8)))">
!memref_rmem_bf16_27 = !cute.memref<bf16, rmem, align<32>, "((8,1),8,2):((1,0),16,8)">
!memref_rmem_bf16_28 = !cute.memref<bf16, rmem, align<32>, "((8,1),(8,2)):((1,0),(16,8))">
!memref_rmem_bf16_29 = !cute.memref<bf16, rmem, align<32>, "((8,1),2):((1,0),8)">
!memref_rmem_bf16_30 = !cute.memref<bf16, rmem, align<32>, "((8,1),(2)):((1,0),(8))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),2,16):((1,2),4,8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((2,2),2,8):((1,2),4,8)">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<16>, "((2,2)):((1,2))">
!memref_rmem_f32_4 = !cute.memref<f32, rmem, align<32>, "((2,2),(2,8)):((2,4),(1,8))">
!memref_rmem_f32_5 = !cute.memref<f32, rmem, align<32>, "((2,8)):((1,8))">
!memref_rmem_f32_6 = !cute.memref<f32, rmem, align<8>, "((2,8)):((1,8))">
!memref_rmem_f32_7 = !cute.memref<f32, rmem, align<16>, "((2,8)):((1,8))">
!memref_rmem_f32_8 = !cute.memref<f32, rmem, align<32>, "((2,2),(2,16)):((2,4),(1,8))">
!memref_rmem_f32_9 = !cute.memref<f32, rmem, align<32>, "(4):(1)">
!memref_rmem_f32_10 = !cute.memref<f32, rmem, align<32>, "((2,16)):((1,8))">
!memref_rmem_f32_11 = !cute.memref<f32, rmem, align<8>, "((2,16)):((1,8))">
!memref_rmem_f32_12 = !cute.memref<f32, rmem, align<16>, "((2,16)):((1,8))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,8,2):(2,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,4,2):(2,0,1)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,2):(2,1)">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(1,(2)):(2,(1))">
!memref_rmem_i8_4 = !cute.memref<i8, rmem, "(1):(2)">
!memref_rmem_i8_5 = !cute.memref<i8, rmem, align<32>, "(1,(4,2)):(2,(0,1))">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "S<3,3,3> o 0 o ((8,16),(64,2)):((64,512),(1,8192))">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<1024>, "S<3,3,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<1024>, "S<3,3,3> o 0 o ((64,2),64):((1,4096),64)">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,1),8,2):((1,0),1024,8192)">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "((8,1),4,2):((1,0),1024,4096)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<16>, "((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">
!memref_smem_bf16_6 = !cute.memref<bf16, smem, align<16>, "((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_7 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
!memref_smem_bf16_8 = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),8192)">
!memref_smem_bf16_9 = !cute.memref<bf16, smem, align<16>, "((8,1),(2)):((1,0),(8192))">
!memref_smem_bf16_10 = !cute.memref<bf16, smem, align<16>, "((8,1)):((1,0))">
!memref_smem_bf16_11 = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),4096)">
!memref_smem_bf16_12 = !cute.memref<bf16, smem, align<16>, "((8,1),(2)):((1,0),(4096))">
!memref_smem_bf16_13 = !cute.memref<bf16, smem, align<16>, "((8,1),(4,2)):((1,0),(1024,4096))">
!memref_smem_bf16_14 = !cute.memref<bf16, smem, align<16>, "((8,1),4):((1,0),1024)">
!memref_smem_bf16_15 = !cute.memref<bf16, smem, align<16>, "((8,1),(4)):((1,0),(1024))">
!memref_smem_bf16_16 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_17 = !cute.memref<bf16, smem, align<16>, "((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
!memref_smem_bf16_18 = !cute.memref<bf16, smem, align<4>, "((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
!memref_smem_bf16_19 = !cute.memref<bf16, smem, align<4>, "((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
!memref_smem_bf16_20 = !cute.memref<bf16, smem, align<4>, "((1,(2,2,2))):((0,(1,512,?{div=8})))">
!memref_smem_bf16_21 = !cute.memref<bf16, smem, align<16>, "((8,1),(8,2)):((1,0),(1024,8192))">
!mma_bf16_bf16_f32_16x8x16_ = !cute.tiled_mma<!cute_nvgpu.sm80.mma<16x8x16, elem_type = (bf16, bf16, f32) >, atom_layout_MNK = <"(4,1,1):(1,0,0)">, permutation_MNK = <"[64:1;16:1;16:1]">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__FlashAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16g_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.composed_layout<"S<3,3,3> o 0 o ((8,16),(64,2)):((64,512),(1,8192))">
      %1 = cute.static : !cute.composed_layout<"S<3,3,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %2 = cute.static : !cute.composed_layout<"S<3,3,3> o 0 o ((8,16),(64,2)):((64,512),(1,8192))">
      %3 = cute.static : !copy_ldgsts
      %4 = cute.static : !copy_simt
      %5 = cute.static : !mma_bf16_bf16_f32_16x8x16_
      %6 = cute.static : !cute.tile<"[16:1;64:1]">
      %7 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %8 = cute.static : !cute.layout<"1:0">
      %9 = cute.static : !cute.layout<"(1,8):(0,1)">
      %10 = cute.static : !cute.layout<"(1,8):(0,1)">
      %11 = cute.static : !cute.tile<"[16:1;64:1]">
      %12 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
      %13 = cute.static : !cute.layout<"1:0">
      %14 = cute.static : !cute.layout<"(1,8):(0,1)">
      %15 = cute.static : !cute.layout<"(1,8):(0,1)">
      %16 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %17 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %18 = cute.static : !cute.layout<"32:1">
      %19 = cute.static : !cute.shape<"(16,8,16)">
      %20 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %21 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %22 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %23 = nvvm.read.ptx.sreg.tid.x : i32
      %24 = nvvm.read.ptx.sreg.ctaid.x : i32
      %25 = nvvm.read.ptx.sreg.ctaid.y : i32
      %26 = nvvm.read.ptx.sreg.ctaid.z : i32
      %lay = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %27 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%27) : !cute.shape<"(?,?,?,?{div=8})">
      %itup = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %int_tuple = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %28 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
      %c64_i32 = arith.constant 64 : i32
      %29 = arith.ceildivsi %28, %c64_i32 : i32
      %int_tuple_0 = cute.make_int_tuple(%29) : (i32) -> !cute.int_tuple<"?">
      %e0_1 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"?">
      %30 = cute.get_scalars(%e0_1) : !cute.int_tuple<"?">
      %false = arith.constant false
      %31 = scf.if %false -> (i32) {
        %c1_i32_2576 = arith.constant 1 : i32
        %1582 = arith.addi %24, %c1_i32_2576 : i32
        %c128_i32_2577 = arith.constant 128 : i32
        %1583 = arith.muli %1582, %c128_i32_2577 : i32
        %int_tuple_2578 = cute.make_int_tuple(%1583) : (i32) -> !cute.int_tuple<"?">
        %1584 = cute.get_scalars(%int_tuple_2578) <{only_dynamic}> : !cute.int_tuple<"?">
        %c64_i32_2579 = arith.constant 64 : i32
        %1585 = arith.ceildivsi %1584, %c64_i32_2579 : i32
        %int_tuple_2580 = cute.make_int_tuple(%1585) : (i32) -> !cute.int_tuple<"?">
        %e0_2581 = cute.get_leaves(%int_tuple_2580) : !cute.int_tuple<"?">
        %1586 = cute.get_scalars(%e0_2581) : !cute.int_tuple<"?">
        %1587 = arith.minsi %1586, %30 : i32
        scf.yield %1587 : i32
      } else {
        scf.yield %30 : i32
      }
      %c1_i32 = arith.constant 1 : i32
      %32 = arith.subi %31, %c1_i32 : i32
      %coord = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_2 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %33:7 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%33#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%33#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_3 = cute.assume(%33#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_3) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_4 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay_2) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view = cute.make_view(%ptr, %lay_4) : !memref_gmem_bf16_1
      %coord_5 = cute.make_coord(%24) : (i32) -> !cute.coord<"(?,0)">
      %34 = cute.get_scalars(%coord_5) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_6 = cute.make_coord(%34) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_7 = cute.get_layout(%view) : !memref_gmem_bf16_1
      %35:3 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c128_i32 = arith.constant 128 : i32
      %36 = arith.ceildivsi %35#0, %c128_i32 : i32
      %c128_i64 = arith.constant 128 : i64
      %37 = arith.muli %35#2, %c128_i64 : i64
      %c128_i32_8 = arith.constant 128 : i32
      %38 = arith.ceildivsi %35#1, %c128_i32_8 : i32
      %shape_9 = cute.make_shape(%36, %38) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_10 = cute.assume(%35#2) : (i64) -> !cute.i64<divby 8>
      %iv_11 = cute.assume(%37) : (i64) -> !cute.i64<divby 1024>
      %stride_12 = cute.make_stride(%iv_10, %iv_11) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_13 = cute.make_layout(%shape_9, %stride_12) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %39:4 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %40 = cute.static : !cute.shape<"(128,128)">
      %iv_14 = cute.assume(%39#2) : (i64) -> !cute.i64<divby 8>
      %stride_15 = cute.make_stride(%iv_14) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_16 = cute.make_layout(%40, %stride_15) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_17 = cute.crd2idx(%coord_6, %lay_13) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %iter_18 = cute.get_iter(%view) : !memref_gmem_bf16_1
      %ptr_19 = cute.add_offset(%iter_18, %idx_17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_20 = cute.make_view(%ptr_19, %lay_16) : !memref_gmem_bf16_2
      %coord_21 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_22 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %41:7 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_23 = cute.assume(%41#3) : (i32) -> !cute.i32<divby 8>
      %shape_24 = cute.make_shape(%41#1, %iv_23) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_25 = cute.assume(%41#5) : (i64) -> !cute.i64<divby 8>
      %stride_26 = cute.make_stride(%iv_25) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_27 = cute.make_layout(%shape_24, %stride_26) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_28 = cute.crd2idx(%coord_21, %lay_22) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_29 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_30 = cute.add_offset(%iter_29, %idx_28) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_31 = cute.make_view(%ptr_30, %lay_27) : !memref_gmem_bf16_1
      %lay_32 = cute.get_layout(%view_31) : !memref_gmem_bf16_1
      %42:3 = cute.get_scalars(%lay_32) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c64_i32_33 = arith.constant 64 : i32
      %43 = arith.ceildivsi %42#0, %c64_i32_33 : i32
      %c64_i64 = arith.constant 64 : i64
      %44 = arith.muli %42#2, %c64_i64 : i64
      %c128_i32_34 = arith.constant 128 : i32
      %45 = arith.ceildivsi %42#1, %c128_i32_34 : i32
      %shape_35 = cute.make_shape(%43, %45) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_36 = cute.assume(%42#2) : (i64) -> !cute.i64<divby 8>
      %iv_37 = cute.assume(%44) : (i64) -> !cute.i64<divby 512>
      %stride_38 = cute.make_stride(%iv_36, %iv_37) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_39 = cute.make_layout(%shape_35, %stride_38) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %46:4 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_40 = cute.make_shape(%46#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_41 = cute.assume(%46#2) : (i64) -> !cute.i64<divby 8>
      %iv_42 = cute.assume(%46#3) : (i64) -> !cute.i64<divby 512>
      %stride_43 = cute.make_stride(%iv_41, %iv_42) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_44 = cute.make_layout(%shape_40, %stride_43) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %47 = cute.static : !cute.int_tuple<"0">
      %iter_45 = cute.get_iter(%view_31) : !memref_gmem_bf16_1
      %ptr_46 = cute.add_offset(%iter_45, %47) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_47 = cute.make_view(%ptr_46, %lay_44) : !memref_gmem_bf16_3
      %coord_48 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_49 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %48:7 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_50 = cute.assume(%48#3) : (i32) -> !cute.i32<divby 8>
      %shape_51 = cute.make_shape(%48#1, %iv_50) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_52 = cute.assume(%48#5) : (i64) -> !cute.i64<divby 8>
      %stride_53 = cute.make_stride(%iv_52) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_54 = cute.make_layout(%shape_51, %stride_53) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_55 = cute.crd2idx(%coord_48, %lay_49) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_56 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_57 = cute.add_offset(%iter_56, %idx_55) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_58 = cute.make_view(%ptr_57, %lay_54) : !memref_gmem_bf16_1
      %lay_59 = cute.get_layout(%view_58) : !memref_gmem_bf16_1
      %49:3 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c64_i32_60 = arith.constant 64 : i32
      %50 = arith.ceildivsi %49#0, %c64_i32_60 : i32
      %c64_i64_61 = arith.constant 64 : i64
      %51 = arith.muli %49#2, %c64_i64_61 : i64
      %c128_i32_62 = arith.constant 128 : i32
      %52 = arith.ceildivsi %49#1, %c128_i32_62 : i32
      %shape_63 = cute.make_shape(%50, %52) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_64 = cute.assume(%49#2) : (i64) -> !cute.i64<divby 8>
      %iv_65 = cute.assume(%51) : (i64) -> !cute.i64<divby 512>
      %stride_66 = cute.make_stride(%iv_64, %iv_65) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_67 = cute.make_layout(%shape_63, %stride_66) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %53:4 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_68 = cute.make_shape(%53#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_69 = cute.assume(%53#2) : (i64) -> !cute.i64<divby 8>
      %iv_70 = cute.assume(%53#3) : (i64) -> !cute.i64<divby 512>
      %stride_71 = cute.make_stride(%iv_69, %iv_70) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_72 = cute.make_layout(%shape_68, %stride_71) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %54 = cute.static : !cute.int_tuple<"0">
      %iter_73 = cute.get_iter(%view_58) : !memref_gmem_bf16_1
      %ptr_74 = cute.add_offset(%iter_73, %54) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_75 = cute.make_view(%ptr_74, %lay_72) : !memref_gmem_bf16_3
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %55 = cute.static : !cute.int_tuple<"0">
      %ptr_76 = cute.add_offset(%smem_ptr, %55) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %56 = cute.static : !cute.int_tuple<"32768">
      %ptr_77 = cute.add_offset(%smem_ptr, %56) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %57 = cute.static : !cute.int_tuple<"49152">
      %ptr_78 = cute.add_offset(%smem_ptr, %57) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_79 = cute.recast_iter(%ptr_76) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_80 = cute.make_view(%iter_79, %0) : !memref_smem_bf16_
      %iter_81 = cute.get_iter(%view_80) : !memref_smem_bf16_
      %iter_82 = cute.recast_iter(%ptr_77) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_83 = cute.make_view(%iter_82, %1) : !memref_smem_bf16_1
      %iter_84 = cute.recast_iter(%ptr_78) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view_85 = cute.make_view(%iter_84, %1) : !memref_smem_bf16_1
      %iter_86 = cute.get_iter(%view_85) : !memref_smem_bf16_1
      %view_87 = cute.make_view(%iter_86) : !memref_smem_bf16_2
      %coord_88 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_89 = cute.get_iter(%view_20) : !memref_gmem_bf16_2
      %lay_90 = cute.get_layout(%view_20) : !memref_gmem_bf16_2
      %58 = cute.get_scalars(%lay_90) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %59 = cute.get_scalars(%coord_88) <{only_dynamic}> : !cute.coord<"?">
      %c16_i64 = arith.constant 16 : i64
      %60 = arith.muli %58, %c16_i64 : i64
      %c8_i32 = arith.constant 8 : i32
      %61 = arith.divsi %59, %c8_i32 : i32
      %c8_i32_91 = arith.constant 8 : i32
      %62 = arith.remsi %59, %c8_i32_91 : i32
      %c8_i32_92 = arith.constant 8 : i32
      %63 = arith.muli %62, %c8_i32_92 : i32
      %64 = arith.extsi %61 : i32 to i64
      %65 = arith.muli %64, %58 : i64
      %66 = arith.extsi %63 : i32 to i64
      %67 = arith.addi %66, %65 : i64
      %iv_93 = cute.assume(%67) : (i64) -> !cute.i64<divby 8>
      %int_tuple_94 = cute.make_int_tuple(%iv_93) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_95 = cute.add_offset(%iter_89, %int_tuple_94) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %68 = cute.static : !cute.shape<"((8,1),8,2)">
      %iv_96 = cute.assume(%60) : (i64) -> !cute.i64<divby 128>
      %stride_97 = cute.make_stride(%iv_96) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_98 = cute.make_layout(%68, %stride_97) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %view_99 = cute.make_view(%ptr_95, %lay_98) : !memref_gmem_bf16_4
      %coord_100 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_101 = cute.get_iter(%view_80) : !memref_smem_bf16_
      %69 = cute.get_scalars(%coord_100) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_102 = arith.constant 8 : i32
      %70 = arith.divsi %69, %c8_i32_102 : i32
      %c8_i32_103 = arith.constant 8 : i32
      %71 = arith.remsi %69, %c8_i32_103 : i32
      %c8_i32_104 = arith.constant 8 : i32
      %72 = arith.muli %71, %c8_i32_104 : i32
      %c8_i32_105 = arith.constant 8 : i32
      %73 = arith.remsi %70, %c8_i32_105 : i32
      %c64_i32_106 = arith.constant 64 : i32
      %74 = arith.muli %73, %c64_i32_106 : i32
      %75 = arith.addi %72, %74 : i32
      %c0_i32 = arith.constant 0 : i32
      %76 = arith.xori %75, %c0_i32 : i32
      %c8_i32_107 = arith.constant 8 : i32
      %77 = arith.divsi %69, %c8_i32_107 : i32
      %c8_i32_108 = arith.constant 8 : i32
      %78 = arith.divsi %77, %c8_i32_108 : i32
      %c512_i32 = arith.constant 512 : i32
      %79 = arith.muli %78, %c512_i32 : i32
      %c448_i32 = arith.constant 448 : i32
      %80 = arith.andi %76, %c448_i32 : i32
      %c3_i32 = arith.constant 3 : i32
      %81 = arith.shrsi %80, %c3_i32 : i32
      %82 = arith.xori %76, %81 : i32
      %83 = arith.addi %82, %79 : i32
      %iv_109 = cute.assume(%83) : (i32) -> !cute.i32<divby 8>
      %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_111 = cute.add_offset(%iter_101, %int_tuple_110) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_112 = cute.make_view(%ptr_111) : !memref_smem_bf16_3
      %coord_113 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_114 = cute.get_iter(%view_47) : !memref_gmem_bf16_3
      %lay_115 = cute.get_layout(%view_47) : !memref_gmem_bf16_3
      %84:3 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %85 = cute.get_scalars(%coord_113) <{only_dynamic}> : !cute.coord<"?">
      %c16_i64_116 = arith.constant 16 : i64
      %86 = arith.muli %84#1, %c16_i64_116 : i64
      %c8_i32_117 = arith.constant 8 : i32
      %87 = arith.divsi %85, %c8_i32_117 : i32
      %c8_i32_118 = arith.constant 8 : i32
      %88 = arith.remsi %85, %c8_i32_118 : i32
      %c8_i32_119 = arith.constant 8 : i32
      %89 = arith.muli %88, %c8_i32_119 : i32
      %90 = arith.extsi %87 : i32 to i64
      %91 = arith.muli %90, %84#1 : i64
      %92 = arith.extsi %89 : i32 to i64
      %93 = arith.addi %92, %91 : i64
      %iv_120 = cute.assume(%93) : (i64) -> !cute.i64<divby 8>
      %int_tuple_121 = cute.make_int_tuple(%iv_120) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_122 = cute.add_offset(%iter_114, %int_tuple_121) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_123 = cute.make_shape(%84#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_124 = cute.assume(%86) : (i64) -> !cute.i64<divby 128>
      %iv_125 = cute.assume(%84#2) : (i64) -> !cute.i64<divby 512>
      %stride_126 = cute.make_stride(%iv_124, %iv_125) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_127 = cute.make_layout(%shape_123, %stride_126) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %view_128 = cute.make_view(%ptr_122, %lay_127) : !memref_gmem_bf16_5
      %coord_129 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_130 = cute.get_iter(%view_83) : !memref_smem_bf16_1
      %94 = cute.get_scalars(%coord_129) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_131 = arith.constant 8 : i32
      %95 = arith.divsi %94, %c8_i32_131 : i32
      %c8_i32_132 = arith.constant 8 : i32
      %96 = arith.remsi %94, %c8_i32_132 : i32
      %c8_i32_133 = arith.constant 8 : i32
      %97 = arith.muli %96, %c8_i32_133 : i32
      %c8_i32_134 = arith.constant 8 : i32
      %98 = arith.remsi %95, %c8_i32_134 : i32
      %c64_i32_135 = arith.constant 64 : i32
      %99 = arith.muli %98, %c64_i32_135 : i32
      %100 = arith.addi %97, %99 : i32
      %c0_i32_136 = arith.constant 0 : i32
      %101 = arith.xori %100, %c0_i32_136 : i32
      %c8_i32_137 = arith.constant 8 : i32
      %102 = arith.divsi %94, %c8_i32_137 : i32
      %c8_i32_138 = arith.constant 8 : i32
      %103 = arith.divsi %102, %c8_i32_138 : i32
      %c512_i32_139 = arith.constant 512 : i32
      %104 = arith.muli %103, %c512_i32_139 : i32
      %c448_i32_140 = arith.constant 448 : i32
      %105 = arith.andi %101, %c448_i32_140 : i32
      %c3_i32_141 = arith.constant 3 : i32
      %106 = arith.shrsi %105, %c3_i32_141 : i32
      %107 = arith.xori %101, %106 : i32
      %108 = arith.addi %107, %104 : i32
      %iv_142 = cute.assume(%108) : (i32) -> !cute.i32<divby 8>
      %int_tuple_143 = cute.make_int_tuple(%iv_142) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_144 = cute.add_offset(%iter_130, %int_tuple_143) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_145 = cute.make_view(%ptr_144) : !memref_smem_bf16_4
      %iter_146 = cute.get_iter(%view_145) : !memref_smem_bf16_4
      %coord_147 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_148 = cute.get_iter(%view_75) : !memref_gmem_bf16_3
      %lay_149 = cute.get_layout(%view_75) : !memref_gmem_bf16_3
      %109:3 = cute.get_scalars(%lay_149) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %110 = cute.get_scalars(%coord_147) <{only_dynamic}> : !cute.coord<"?">
      %c16_i64_150 = arith.constant 16 : i64
      %111 = arith.muli %109#1, %c16_i64_150 : i64
      %c8_i32_151 = arith.constant 8 : i32
      %112 = arith.divsi %110, %c8_i32_151 : i32
      %c8_i32_152 = arith.constant 8 : i32
      %113 = arith.remsi %110, %c8_i32_152 : i32
      %c8_i32_153 = arith.constant 8 : i32
      %114 = arith.muli %113, %c8_i32_153 : i32
      %115 = arith.extsi %112 : i32 to i64
      %116 = arith.muli %115, %109#1 : i64
      %117 = arith.extsi %114 : i32 to i64
      %118 = arith.addi %117, %116 : i64
      %iv_154 = cute.assume(%118) : (i64) -> !cute.i64<divby 8>
      %int_tuple_155 = cute.make_int_tuple(%iv_154) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_156 = cute.add_offset(%iter_148, %int_tuple_155) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_157 = cute.make_shape(%109#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_158 = cute.assume(%111) : (i64) -> !cute.i64<divby 128>
      %iv_159 = cute.assume(%109#2) : (i64) -> !cute.i64<divby 512>
      %stride_160 = cute.make_stride(%iv_158, %iv_159) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_161 = cute.make_layout(%shape_157, %stride_160) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %view_162 = cute.make_view(%ptr_156, %lay_161) : !memref_gmem_bf16_5
      %coord_163 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_164 = cute.get_iter(%view_85) : !memref_smem_bf16_1
      %119 = cute.get_scalars(%coord_163) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_165 = arith.constant 8 : i32
      %120 = arith.divsi %119, %c8_i32_165 : i32
      %c8_i32_166 = arith.constant 8 : i32
      %121 = arith.remsi %119, %c8_i32_166 : i32
      %c8_i32_167 = arith.constant 8 : i32
      %122 = arith.muli %121, %c8_i32_167 : i32
      %c8_i32_168 = arith.constant 8 : i32
      %123 = arith.remsi %120, %c8_i32_168 : i32
      %c64_i32_169 = arith.constant 64 : i32
      %124 = arith.muli %123, %c64_i32_169 : i32
      %125 = arith.addi %122, %124 : i32
      %c0_i32_170 = arith.constant 0 : i32
      %126 = arith.xori %125, %c0_i32_170 : i32
      %c8_i32_171 = arith.constant 8 : i32
      %127 = arith.divsi %119, %c8_i32_171 : i32
      %c8_i32_172 = arith.constant 8 : i32
      %128 = arith.divsi %127, %c8_i32_172 : i32
      %c512_i32_173 = arith.constant 512 : i32
      %129 = arith.muli %128, %c512_i32_173 : i32
      %c448_i32_174 = arith.constant 448 : i32
      %130 = arith.andi %126, %c448_i32_174 : i32
      %c3_i32_175 = arith.constant 3 : i32
      %131 = arith.shrsi %130, %c3_i32_175 : i32
      %132 = arith.xori %126, %131 : i32
      %133 = arith.addi %132, %129 : i32
      %iv_176 = cute.assume(%133) : (i32) -> !cute.i32<divby 8>
      %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_178 = cute.add_offset(%iter_164, %int_tuple_177) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_179 = cute.make_view(%ptr_178) : !memref_smem_bf16_4
      %iter_180 = cute.get_iter(%view_179) : !memref_smem_bf16_4
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_181 = cute.memref.alloca() : !memref_rmem_bf16_1
      %134 = cute.static : !cute.swizzle<"S<3,3,3>">
      %rmem_182 = cute.memref.alloca() : !memref_rmem_bf16_2
      %135 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %rmem_183 = cute.memref.alloca(%135) : !memref_rmem_f32_
      %iter_184 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
      %cst = arith.constant 0.000000e+00 : f32
      %136 = vector.splat %cst : vector<128xf32>
      cute.memref.store_vec %136, %rmem_183 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_185 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_186 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %137 = cute.static : !cute.layout<"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">
      %138 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %139 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %140 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %141 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %142 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %143 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %144 = cute.make_tiled_copy(%atom_185) : !copy_ldsm_4_1
      %145 = cute.static : !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %146 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %147 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %148 = cute.make_tiled_copy(%atom_186) : !copy_ldsm_4_2
      %coord_187 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_188 = cute.get_iter(%view_80) : !memref_smem_bf16_
      %149 = cute.get_scalars(%coord_187) <{only_dynamic}> : !cute.coord<"?">
      %c16_i32 = arith.constant 16 : i32
      %150 = arith.divsi %149, %c16_i32 : i32
      %c16_i32_189 = arith.constant 16 : i32
      %151 = arith.remsi %149, %c16_i32_189 : i32
      %c8_i32_190 = arith.constant 8 : i32
      %152 = arith.remsi %151, %c8_i32_190 : i32
      %c64_i32_191 = arith.constant 64 : i32
      %153 = arith.muli %152, %c64_i32_191 : i32
      %c2_i32 = arith.constant 2 : i32
      %154 = arith.remsi %150, %c2_i32 : i32
      %c8_i32_192 = arith.constant 8 : i32
      %155 = arith.muli %154, %c8_i32_192 : i32
      %156 = arith.addi %153, %155 : i32
      %c0_i32_193 = arith.constant 0 : i32
      %157 = arith.xori %156, %c0_i32_193 : i32
      %c16_i32_194 = arith.constant 16 : i32
      %158 = arith.divsi %149, %c16_i32_194 : i32
      %c16_i32_195 = arith.constant 16 : i32
      %159 = arith.remsi %149, %c16_i32_195 : i32
      %c8_i32_196 = arith.constant 8 : i32
      %160 = arith.divsi %159, %c8_i32_196 : i32
      %c512_i32_197 = arith.constant 512 : i32
      %161 = arith.muli %160, %c512_i32_197 : i32
      %c2_i32_198 = arith.constant 2 : i32
      %162 = arith.divsi %158, %c2_i32_198 : i32
      %c1024_i32 = arith.constant 1024 : i32
      %163 = arith.muli %162, %c1024_i32 : i32
      %164 = arith.addi %161, %163 : i32
      %c128_i32_199 = arith.constant 128 : i32
      %165 = arith.andi %157, %c128_i32_199 : i32
      %c0_i32_200 = arith.constant 0 : i32
      %166 = arith.cmpi eq, %165, %c0_i32_200 : i32
      %167 = scf.if %166 -> (i32) {
        %c16_i32_2576 = arith.constant 16 : i32
        scf.yield %c16_i32_2576 : i32
      } else {
        %c-16_i32 = arith.constant -16 : i32
        scf.yield %c-16_i32 : i32
      }
      %c256_i32 = arith.constant 256 : i32
      %168 = arith.andi %157, %c256_i32 : i32
      %c0_i32_201 = arith.constant 0 : i32
      %169 = arith.cmpi eq, %168, %c0_i32_201 : i32
      %170 = scf.if %169 -> (i32) {
        %c32_i32_2576 = arith.constant 32 : i32
        scf.yield %c32_i32_2576 : i32
      } else {
        %c-32_i32 = arith.constant -32 : i32
        scf.yield %c-32_i32 : i32
      }
      %c448_i32_202 = arith.constant 448 : i32
      %171 = arith.andi %157, %c448_i32_202 : i32
      %c3_i32_203 = arith.constant 3 : i32
      %172 = arith.shrsi %171, %c3_i32_203 : i32
      %173 = arith.xori %157, %172 : i32
      %174 = arith.addi %173, %164 : i32
      %iv_204 = cute.assume(%174) : (i32) -> !cute.i32<divby 8>
      %int_tuple_205 = cute.make_int_tuple(%iv_204) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_206 = cute.add_offset(%iter_188, %int_tuple_205) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %175 = cute.static : !cute.shape<"((8,1),2,((2,2),2))">
      %iv_207 = cute.assume(%167) : (i32) -> !cute.i32<divby 16>
      %iv_208 = cute.assume(%170) : (i32) -> !cute.i32<divby 32>
      %stride_209 = cute.make_stride(%iv_207, %iv_208) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),4096,((?{div=16},?{div=32}),8192))">
      %lay_210 = cute.make_layout(%175, %stride_209) : !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">
      %view_211 = cute.make_view(%ptr_206, %lay_210) : !memref_smem_bf16_5
      %iter_212 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_213 = cute.make_view(%iter_212) : !memref_rmem_bf16_3
      %coord_214 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_215 = cute.get_iter(%view_83) : !memref_smem_bf16_1
      %176 = cute.get_scalars(%coord_214) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_216 = arith.constant 8 : i32
      %177 = arith.divsi %176, %c8_i32_216 : i32
      %c8_i32_217 = arith.constant 8 : i32
      %178 = arith.remsi %176, %c8_i32_217 : i32
      %c64_i32_218 = arith.constant 64 : i32
      %179 = arith.muli %178, %c64_i32_218 : i32
      %c2_i32_219 = arith.constant 2 : i32
      %180 = arith.remsi %177, %c2_i32_219 : i32
      %c8_i32_220 = arith.constant 8 : i32
      %181 = arith.muli %180, %c8_i32_220 : i32
      %182 = arith.addi %179, %181 : i32
      %c0_i32_221 = arith.constant 0 : i32
      %183 = arith.xori %182, %c0_i32_221 : i32
      %c8_i32_222 = arith.constant 8 : i32
      %184 = arith.divsi %176, %c8_i32_222 : i32
      %c2_i32_223 = arith.constant 2 : i32
      %185 = arith.divsi %184, %c2_i32_223 : i32
      %c2_i32_224 = arith.constant 2 : i32
      %186 = arith.remsi %185, %c2_i32_224 : i32
      %c512_i32_225 = arith.constant 512 : i32
      %187 = arith.muli %186, %c512_i32_225 : i32
      %c128_i32_226 = arith.constant 128 : i32
      %188 = arith.andi %183, %c128_i32_226 : i32
      %c0_i32_227 = arith.constant 0 : i32
      %189 = arith.cmpi eq, %188, %c0_i32_227 : i32
      %190 = scf.if %189 -> (i32) {
        %c16_i32_2576 = arith.constant 16 : i32
        scf.yield %c16_i32_2576 : i32
      } else {
        %c-16_i32 = arith.constant -16 : i32
        scf.yield %c-16_i32 : i32
      }
      %c256_i32_228 = arith.constant 256 : i32
      %191 = arith.andi %183, %c256_i32_228 : i32
      %c0_i32_229 = arith.constant 0 : i32
      %192 = arith.cmpi eq, %191, %c0_i32_229 : i32
      %193 = scf.if %192 -> (i32) {
        %c32_i32_2576 = arith.constant 32 : i32
        scf.yield %c32_i32_2576 : i32
      } else {
        %c-32_i32 = arith.constant -32 : i32
        scf.yield %c-32_i32 : i32
      }
      %c448_i32_230 = arith.constant 448 : i32
      %194 = arith.andi %183, %c448_i32_230 : i32
      %c3_i32_231 = arith.constant 3 : i32
      %195 = arith.shrsi %194, %c3_i32_231 : i32
      %196 = arith.xori %183, %195 : i32
      %197 = arith.addi %196, %187 : i32
      %iv_232 = cute.assume(%197) : (i32) -> !cute.i32<divby 8>
      %int_tuple_233 = cute.make_int_tuple(%iv_232) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_234 = cute.add_offset(%iter_215, %int_tuple_233) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %198 = cute.static : !cute.shape<"((8,1),4,((2,2),2))">
      %iv_235 = cute.assume(%190) : (i32) -> !cute.i32<divby 16>
      %iv_236 = cute.assume(%193) : (i32) -> !cute.i32<divby 32>
      %stride_237 = cute.make_stride(%iv_235, %iv_236) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_238 = cute.make_layout(%198, %stride_237) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %view_239 = cute.make_view(%ptr_234, %lay_238) : !memref_smem_bf16_6
      %iter_240 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %view_241 = cute.make_view(%iter_240) : !memref_rmem_bf16_4
      %coord_242 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_243 = cute.get_iter(%view_87) : !memref_smem_bf16_2
      %199 = cute.get_scalars(%coord_242) <{only_dynamic}> : !cute.coord<"?">
      %c16_i32_244 = arith.constant 16 : i32
      %200 = arith.divsi %199, %c16_i32_244 : i32
      %c16_i32_245 = arith.constant 16 : i32
      %201 = arith.remsi %199, %c16_i32_245 : i32
      %c8_i32_246 = arith.constant 8 : i32
      %202 = arith.remsi %201, %c8_i32_246 : i32
      %c64_i32_247 = arith.constant 64 : i32
      %203 = arith.muli %202, %c64_i32_247 : i32
      %c2_i32_248 = arith.constant 2 : i32
      %204 = arith.remsi %200, %c2_i32_248 : i32
      %c8_i32_249 = arith.constant 8 : i32
      %205 = arith.muli %204, %c8_i32_249 : i32
      %206 = arith.addi %203, %205 : i32
      %c0_i32_250 = arith.constant 0 : i32
      %207 = arith.xori %206, %c0_i32_250 : i32
      %c16_i32_251 = arith.constant 16 : i32
      %208 = arith.remsi %199, %c16_i32_251 : i32
      %c8_i32_252 = arith.constant 8 : i32
      %209 = arith.divsi %208, %c8_i32_252 : i32
      %c512_i32_253 = arith.constant 512 : i32
      %210 = arith.muli %209, %c512_i32_253 : i32
      %c128_i32_254 = arith.constant 128 : i32
      %211 = arith.andi %207, %c128_i32_254 : i32
      %c0_i32_255 = arith.constant 0 : i32
      %212 = arith.cmpi eq, %211, %c0_i32_255 : i32
      %213 = scf.if %212 -> (i32) {
        %c16_i32_2576 = arith.constant 16 : i32
        scf.yield %c16_i32_2576 : i32
      } else {
        %c-16_i32 = arith.constant -16 : i32
        scf.yield %c-16_i32 : i32
      }
      %c256_i32_256 = arith.constant 256 : i32
      %214 = arith.andi %207, %c256_i32_256 : i32
      %c0_i32_257 = arith.constant 0 : i32
      %215 = arith.cmpi eq, %214, %c0_i32_257 : i32
      %216 = scf.if %215 -> (i32) {
        %c32_i32_2576 = arith.constant 32 : i32
        scf.yield %c32_i32_2576 : i32
      } else {
        %c-32_i32 = arith.constant -32 : i32
        scf.yield %c-32_i32 : i32
      }
      %c448_i32_258 = arith.constant 448 : i32
      %217 = arith.andi %207, %c448_i32_258 : i32
      %c3_i32_259 = arith.constant 3 : i32
      %218 = arith.shrsi %217, %c3_i32_259 : i32
      %219 = arith.xori %207, %218 : i32
      %220 = arith.addi %219, %210 : i32
      %iv_260 = cute.assume(%220) : (i32) -> !cute.i32<divby 8>
      %int_tuple_261 = cute.make_int_tuple(%iv_260) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_262 = cute.add_offset(%iter_243, %int_tuple_261) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %221 = cute.static : !cute.shape<"((8,1),((2,2),2),4)">
      %iv_263 = cute.assume(%213) : (i32) -> !cute.i32<divby 16>
      %iv_264 = cute.assume(%216) : (i32) -> !cute.i32<divby 32>
      %stride_265 = cute.make_stride(%iv_263, %iv_264) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_266 = cute.make_layout(%221, %stride_265) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %view_267 = cute.make_view(%ptr_262, %lay_266) : !memref_smem_bf16_7
      %iter_268 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
      %view_269 = cute.make_view(%iter_268) : !memref_rmem_bf16_5
      %lay_270 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %222 = cute.get_shape(%lay_270) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_271, %e1_272, %e2_273, %e3_274 = cute.get_leaves(%222) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_275 = cute.to_int_tuple(%e0_271) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_276 = cute.to_int_tuple(%e1_272) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_277 = cute.to_int_tuple(%e2_273) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_278 = cute.to_int_tuple(%e3_274) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_279 = cute.make_shape(%itup_275, %itup_276, %itup_277, %itup_278) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %223 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %224 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %lay_280 = cute.make_layout(%shape_279, %224) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %view_281 = cute.make_view(%223, %lay_280) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %lay_282 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %225 = cute.get_shape(%lay_282) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_283, %e1_284, %e2_285, %e3_286 = cute.get_leaves(%225) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_287 = cute.to_int_tuple(%e0_283) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_288 = cute.to_int_tuple(%e1_284) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_289 = cute.to_int_tuple(%e2_285) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_290 = cute.to_int_tuple(%e3_286) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_291 = cute.make_shape(%itup_287, %itup_288, %itup_289, %itup_290) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %226 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %227 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %lay_292 = cute.make_layout(%shape_291, %227) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %view_293 = cute.make_view(%226, %lay_292) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %coord_294 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_295 = cute.get_layout(%view_281) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %228:4 = cute.get_scalars(%lay_295) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_296 = cute.assume(%228#3) : (i32) -> !cute.i32<divby 8>
      %shape_297 = cute.make_shape(%228#1, %iv_296) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %229 = cute.static : !cute.stride<"(1@1,1@3)">
      %lay_298 = cute.make_layout(%shape_297, %229) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_299 = cute.crd2idx(%coord_294, %lay_295) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %230 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %tup = cute.add_offset(%230, %idx_299) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %view_300 = cute.make_view(%tup, %lay_298) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %coord_301 = cute.make_coord(%24) : (i32) -> !cute.coord<"(?,0)">
      %231 = cute.get_scalars(%coord_301) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_302 = cute.make_coord(%231) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_303 = cute.get_layout(%view_300) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %232:2 = cute.get_scalars(%lay_303) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c128_i32_304 = arith.constant 128 : i32
      %233 = arith.ceildivsi %232#0, %c128_i32_304 : i32
      %c128_i32_305 = arith.constant 128 : i32
      %234 = arith.ceildivsi %232#1, %c128_i32_305 : i32
      %shape_306 = cute.make_shape(%233, %234) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %235 = cute.static : !cute.stride<"((1@1,1@3),(128@1,128@3))">
      %lay_307 = cute.make_layout(%shape_306, %235) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_308 = cute.crd2idx(%coord_302, %lay_307) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %iter_309 = cute.get_iter(%view_300) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %tup_310 = cute.add_offset(%iter_309, %idx_308) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %view_311 = cute.make_view(%tup_310) : !cute.coord_tensor<"(?,?{div=128},?,0)", "(128,128):(1@1,1@3)">
      %coord_312 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_313 = cute.get_layout(%view_293) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %236:4 = cute.get_scalars(%lay_313) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_314 = cute.assume(%236#3) : (i32) -> !cute.i32<divby 8>
      %shape_315 = cute.make_shape(%236#1, %iv_314) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %237 = cute.static : !cute.stride<"(1@1,1@3)">
      %lay_316 = cute.make_layout(%shape_315, %237) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_317 = cute.crd2idx(%coord_312, %lay_313) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %238 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %tup_318 = cute.add_offset(%238, %idx_317) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %view_319 = cute.make_view(%tup_318, %lay_316) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %coord_320 = cute.make_coord(%32) : (i32) -> !cute.coord<"(?,0)">
      %239 = cute.get_scalars(%coord_320) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_321 = cute.make_coord(%239) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_322 = cute.get_layout(%view_319) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %240:2 = cute.get_scalars(%lay_322) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c64_i32_323 = arith.constant 64 : i32
      %241 = arith.ceildivsi %240#0, %c64_i32_323 : i32
      %c128_i32_324 = arith.constant 128 : i32
      %242 = arith.ceildivsi %240#1, %c128_i32_324 : i32
      %shape_325 = cute.make_shape(%241, %242) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %243 = cute.static : !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %lay_326 = cute.make_layout(%shape_325, %243) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_327 = cute.crd2idx(%coord_321, %lay_326) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %iter_328 = cute.get_iter(%view_319) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %tup_329 = cute.add_offset(%iter_328, %idx_327) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %view_330 = cute.make_view(%tup_329) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %coord_331 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_332 = cute.get_iter(%view_311) : !cute.coord_tensor<"(?,?{div=128},?,0)", "(128,128):(1@1,1@3)">
      %244 = cute.get_scalars(%coord_331) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_333 = arith.constant 8 : i32
      %245 = arith.divsi %244, %c8_i32_333 : i32
      %c8_i32_334 = arith.constant 8 : i32
      %246 = arith.remsi %244, %c8_i32_334 : i32
      %c8_i32_335 = arith.constant 8 : i32
      %247 = arith.muli %246, %c8_i32_335 : i32
      %iv_336 = cute.assume(%247) : (i32) -> !cute.i32<divby 8>
      %int_tuple_337 = cute.make_int_tuple(%245, %iv_336) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_338 = cute.add_offset(%iter_332, %int_tuple_337) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_339 = cute.make_view(%tup_338) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %coord_340 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_341 = cute.get_iter(%view_330) : !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %248 = cute.get_scalars(%coord_340) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_342 = arith.constant 8 : i32
      %249 = arith.divsi %248, %c8_i32_342 : i32
      %c8_i32_343 = arith.constant 8 : i32
      %250 = arith.remsi %248, %c8_i32_343 : i32
      %c8_i32_344 = arith.constant 8 : i32
      %251 = arith.muli %250, %c8_i32_344 : i32
      %iv_345 = cute.assume(%251) : (i32) -> !cute.i32<divby 8>
      %int_tuple_346 = cute.make_int_tuple(%249, %iv_345) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_347 = cute.add_offset(%iter_341, %int_tuple_346) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_348 = cute.make_view(%tup_347) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %252 = cute.static : !cute.layout<"(1,8,2):(2,0,1)">
      %rmem_349 = cute.memref.alloca(%252) : !memref_rmem_i8_
      %253 = cute.static : !cute.layout<"(1,4,2):(2,0,1)">
      %rmem_350 = cute.memref.alloca(%253) : !memref_rmem_i8_1
      %iter_351 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
      %254 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_352 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_353 = cute.add_offset(%iter_352, %254) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_354 = cute.make_view(%tup_353) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_355 = cute.get_iter(%view_354) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_356, %e1_357, %e2_358, %e3_359 = cute.get_leaves(%iter_355) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_360 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %255 = cute.get_shape(%lay_360) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_361, %e1_362, %e2_363, %e3_364 = cute.get_leaves(%255) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_365 = cute.to_int_tuple(%e3_364) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_366 = cute.make_coord(%e3_359) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_367 = cute.make_coord(%itup_365) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %256 = cute.get_scalars(%coord_366) : !cute.coord<"?{div=8}">
      %257 = cute.get_scalars(%coord_367) : !cute.coord<"?{div=8}">
      %true = arith.constant true
      %258 = arith.cmpi slt, %256, %257 : i32
      %259 = arith.andi %true, %258 : i1
      %260 = arith.extui %259 : i1 to i8
      %261 = cute.static : !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_349, %261, %260) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %262 = cute.static : !cute.int_tuple<"(0,0,0,64)">
      %iter_368 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_369 = cute.add_offset(%iter_368, %262) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_370 = cute.make_view(%tup_369) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_371 = cute.get_iter(%view_370) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_372, %e1_373, %e2_374, %e3_375 = cute.get_leaves(%iter_371) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_376 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %263 = cute.get_shape(%lay_376) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_377, %e1_378, %e2_379, %e3_380 = cute.get_leaves(%263) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_381 = cute.to_int_tuple(%e3_380) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_382 = cute.make_coord(%e3_375) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_383 = cute.make_coord(%itup_381) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %264 = cute.get_scalars(%coord_382) : !cute.coord<"?{div=8}">
      %265 = cute.get_scalars(%coord_383) : !cute.coord<"?{div=8}">
      %true_384 = arith.constant true
      %266 = arith.cmpi slt, %264, %265 : i32
      %267 = arith.andi %true_384, %266 : i1
      %268 = arith.extui %267 : i1 to i8
      %269 = cute.static : !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_349, %269, %268) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %270 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_385 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_386 = cute.add_offset(%iter_385, %270) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_387 = cute.make_view(%tup_386) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_388 = cute.get_iter(%view_387) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_389, %e1_390, %e2_391, %e3_392 = cute.get_leaves(%iter_388) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_393 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %271 = cute.get_shape(%lay_393) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_394, %e1_395, %e2_396, %e3_397 = cute.get_leaves(%271) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_398 = cute.to_int_tuple(%e3_397) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_399 = cute.make_coord(%e3_392) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_400 = cute.make_coord(%itup_398) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %272 = cute.get_scalars(%coord_399) : !cute.coord<"?{div=8}">
      %273 = cute.get_scalars(%coord_400) : !cute.coord<"?{div=8}">
      %true_401 = arith.constant true
      %274 = arith.cmpi slt, %272, %273 : i32
      %275 = arith.andi %true_401, %274 : i1
      %276 = arith.extui %275 : i1 to i8
      %277 = cute.static : !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_350, %277, %276) : (!memref_rmem_i8_1, !cute.coord<"(0,0,0)">, i8) -> ()
      %278 = cute.static : !cute.int_tuple<"(0,0,0,64)">
      %iter_402 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_403 = cute.add_offset(%iter_402, %278) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_404 = cute.make_view(%tup_403) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_405 = cute.get_iter(%view_404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_406, %e1_407, %e2_408, %e3_409 = cute.get_leaves(%iter_405) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_410 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %279 = cute.get_shape(%lay_410) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_411, %e1_412, %e2_413, %e3_414 = cute.get_leaves(%279) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_415 = cute.to_int_tuple(%e3_414) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_416 = cute.make_coord(%e3_409) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_417 = cute.make_coord(%itup_415) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %280 = cute.get_scalars(%coord_416) : !cute.coord<"?{div=8}">
      %281 = cute.get_scalars(%coord_417) : !cute.coord<"?{div=8}">
      %true_418 = arith.constant true
      %282 = arith.cmpi slt, %280, %281 : i32
      %283 = arith.andi %true_418, %282 : i1
      %284 = arith.extui %283 : i1 to i8
      %285 = cute.static : !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_350, %285, %284) : (!memref_rmem_i8_1, !cute.coord<"(0,0,1)">, i8) -> ()
      %286 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_419 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_420 = cute.add_offset(%iter_419, %286) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_421 = cute.make_view(%tup_420) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_422 = cute.get_iter(%view_421) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_423, %e1_424, %e2_425, %e3_426 = cute.get_leaves(%iter_422) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_427 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %287 = cute.get_shape(%lay_427) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_428, %e1_429, %e2_430, %e3_431 = cute.get_leaves(%287) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_432 = cute.to_int_tuple(%e1_429) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_433 = cute.make_coord(%e1_424) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_434 = cute.make_coord(%itup_432) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %288 = cute.get_scalars(%coord_433) : !cute.coord<"?">
      %289 = cute.get_scalars(%coord_434) : !cute.coord<"?">
      %true_435 = arith.constant true
      %290 = arith.cmpi slt, %288, %289 : i32
      %291 = arith.andi %true_435, %290 : i1
      scf.if %291 {
        %1582 = cute.static : !cute.int_tuple<"0">
        %iter_2576 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_gmem_bf16_6
        %iter_2579 = cute.get_iter(%view_2578) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2580 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2581 = cute.add_offset(%iter_2580, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581) : !memref_smem_bf16_8
        %iter_2583 = cute.get_iter(%view_2582) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2584 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2585 = cute.add_offset(%iter_2584, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2586 = cute.make_view(%ptr_2585) : !memref_rmem_i8_2
        %iter_2587 = cute.get_iter(%view_2586) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2588 = cute.make_view(%iter_2579, %1585) : !memref_gmem_bf16_6
        %iter_2589 = cute.get_iter(%view_2588) : !memref_gmem_bf16_6
        %view_2590 = cute.make_view(%iter_2589) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2591 = cute.make_view(%iter_2583, %1586) : !memref_smem_bf16_8
        %iter_2592 = cute.get_iter(%view_2591) : !memref_smem_bf16_8
        %view_2593 = cute.make_view(%iter_2592) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2594 = cute.make_view(%iter_2587, %1587) : !memref_rmem_i8_2
        %iter_2595 = cute.get_iter(%view_2594) : !memref_rmem_i8_2
        %view_2596 = cute.make_view(%iter_2595) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2597 = cute.get_iter(%view_2590) : !memref_gmem_bf16_7
        %iter_2598 = cute.get_iter(%view_2593) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2599 = cute.get_iter(%view_2596) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2600 = arith.constant 0 : i32
        %c1_i32_2601 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2600 to %1593 step %c1_i32_2601  : i32 {
          %coord_2602 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2603 = cute.crd2idx(%coord_2602, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2604 = cute.add_offset(%iter_2597, %idx_2603) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2605 = cute.make_view(%ptr_2604, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2602, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2607 = cute.add_offset(%iter_2598, %idx_2606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2609 = cute.crd2idx(%coord_2602, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2610 = cute.add_offset(%iter_2599, %idx_2609) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2611 = cute.make_view(%ptr_2610, %1596) : !memref_rmem_i8_4
          %iter_2612 = cute.get_iter(%view_2605) : !memref_gmem_bf16_8
          %iter_2613 = cute.get_iter(%view_2608) : !memref_smem_bf16_10
          %iter_2614 = cute.get_iter(%view_2611) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2615 = cute.recast_iter(%iter_2612) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2616 = cute.recast_iter(%iter_2613) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2616 : !cute.ptr<i128, smem>, %iter_2615 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"0">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %292 = cute.static : !cute.int_tuple<"(0,16,0,0)">
      %iter_436 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_437 = cute.add_offset(%iter_436, %292) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_438 = cute.make_view(%tup_437) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_439 = cute.get_iter(%view_438) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_440, %e1_441, %e2_442, %e3_443 = cute.get_leaves(%iter_439) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_444 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %293 = cute.get_shape(%lay_444) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_445, %e1_446, %e2_447, %e3_448 = cute.get_leaves(%293) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_449 = cute.to_int_tuple(%e1_446) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_450 = cute.make_coord(%e1_441) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_451 = cute.make_coord(%itup_449) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %294 = cute.get_scalars(%coord_450) : !cute.coord<"?">
      %295 = cute.get_scalars(%coord_451) : !cute.coord<"?">
      %true_452 = arith.constant true
      %296 = arith.cmpi slt, %294, %295 : i32
      %297 = arith.andi %true_452, %296 : i1
      scf.if %297 {
        %1582 = cute.static : !cute.coord<"(_,1,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"1024">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"1024">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %298 = cute.static : !cute.int_tuple<"(0,32,0,0)">
      %iter_453 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_454 = cute.add_offset(%iter_453, %298) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_455 = cute.make_view(%tup_454) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_456 = cute.get_iter(%view_455) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_457, %e1_458, %e2_459, %e3_460 = cute.get_leaves(%iter_456) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_461 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %299 = cute.get_shape(%lay_461) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_462, %e1_463, %e2_464, %e3_465 = cute.get_leaves(%299) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_466 = cute.to_int_tuple(%e1_463) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_467 = cute.make_coord(%e1_458) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_468 = cute.make_coord(%itup_466) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %300 = cute.get_scalars(%coord_467) : !cute.coord<"?">
      %301 = cute.get_scalars(%coord_468) : !cute.coord<"?">
      %true_469 = arith.constant true
      %302 = arith.cmpi slt, %300, %301 : i32
      %303 = arith.andi %true_469, %302 : i1
      scf.if %303 {
        %1582 = cute.static : !cute.coord<"(_,2,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"2048">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"2048">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %304 = cute.static : !cute.int_tuple<"(0,48,0,0)">
      %iter_470 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_471 = cute.add_offset(%iter_470, %304) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_472 = cute.make_view(%tup_471) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_473 = cute.get_iter(%view_472) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_474, %e1_475, %e2_476, %e3_477 = cute.get_leaves(%iter_473) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_478 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %305 = cute.get_shape(%lay_478) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_479, %e1_480, %e2_481, %e3_482 = cute.get_leaves(%305) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_483 = cute.to_int_tuple(%e1_480) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_484 = cute.make_coord(%e1_475) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_485 = cute.make_coord(%itup_483) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %306 = cute.get_scalars(%coord_484) : !cute.coord<"?">
      %307 = cute.get_scalars(%coord_485) : !cute.coord<"?">
      %true_486 = arith.constant true
      %308 = arith.cmpi slt, %306, %307 : i32
      %309 = arith.andi %true_486, %308 : i1
      scf.if %309 {
        %1582 = cute.static : !cute.coord<"(_,3,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"3072">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"3072">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %310 = cute.static : !cute.int_tuple<"(0,64,0,0)">
      %iter_487 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_488 = cute.add_offset(%iter_487, %310) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_489 = cute.make_view(%tup_488) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_490 = cute.get_iter(%view_489) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_491, %e1_492, %e2_493, %e3_494 = cute.get_leaves(%iter_490) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_495 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %311 = cute.get_shape(%lay_495) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_496, %e1_497, %e2_498, %e3_499 = cute.get_leaves(%311) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_500 = cute.to_int_tuple(%e1_497) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_501 = cute.make_coord(%e1_492) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_502 = cute.make_coord(%itup_500) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %312 = cute.get_scalars(%coord_501) : !cute.coord<"?">
      %313 = cute.get_scalars(%coord_502) : !cute.coord<"?">
      %true_503 = arith.constant true
      %314 = arith.cmpi slt, %312, %313 : i32
      %315 = arith.andi %true_503, %314 : i1
      scf.if %315 {
        %1582 = cute.static : !cute.coord<"(_,4,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"4096">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"4096">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %316 = cute.static : !cute.int_tuple<"(0,80,0,0)">
      %iter_504 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_505 = cute.add_offset(%iter_504, %316) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_506 = cute.make_view(%tup_505) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_507 = cute.get_iter(%view_506) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_508, %e1_509, %e2_510, %e3_511 = cute.get_leaves(%iter_507) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_512 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %317 = cute.get_shape(%lay_512) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_513, %e1_514, %e2_515, %e3_516 = cute.get_leaves(%317) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_517 = cute.to_int_tuple(%e1_514) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_518 = cute.make_coord(%e1_509) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_519 = cute.make_coord(%itup_517) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %318 = cute.get_scalars(%coord_518) : !cute.coord<"?">
      %319 = cute.get_scalars(%coord_519) : !cute.coord<"?">
      %true_520 = arith.constant true
      %320 = arith.cmpi slt, %318, %319 : i32
      %321 = arith.andi %true_520, %320 : i1
      scf.if %321 {
        %1582 = cute.static : !cute.coord<"(_,5,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"5120">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"5120">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %322 = cute.static : !cute.int_tuple<"(0,96,0,0)">
      %iter_521 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_522 = cute.add_offset(%iter_521, %322) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_523 = cute.make_view(%tup_522) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_524 = cute.get_iter(%view_523) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_525, %e1_526, %e2_527, %e3_528 = cute.get_leaves(%iter_524) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_529 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %323 = cute.get_shape(%lay_529) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_530, %e1_531, %e2_532, %e3_533 = cute.get_leaves(%323) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_534 = cute.to_int_tuple(%e1_531) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_535 = cute.make_coord(%e1_526) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_536 = cute.make_coord(%itup_534) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %324 = cute.get_scalars(%coord_535) : !cute.coord<"?">
      %325 = cute.get_scalars(%coord_536) : !cute.coord<"?">
      %true_537 = arith.constant true
      %326 = arith.cmpi slt, %324, %325 : i32
      %327 = arith.andi %true_537, %326 : i1
      scf.if %327 {
        %1582 = cute.static : !cute.coord<"(_,6,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"6144">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"6144">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %328 = cute.static : !cute.int_tuple<"(0,112,0,0)">
      %iter_538 = cute.get_iter(%view_339) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_539 = cute.add_offset(%iter_538, %328) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_540 = cute.make_view(%tup_539) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_541 = cute.get_iter(%view_540) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_542, %e1_543, %e2_544, %e3_545 = cute.get_leaves(%iter_541) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_546 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %329 = cute.get_shape(%lay_546) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_547, %e1_548, %e2_549, %e3_550 = cute.get_leaves(%329) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_551 = cute.to_int_tuple(%e1_548) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_552 = cute.make_coord(%e1_543) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_553 = cute.make_coord(%itup_551) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %330 = cute.get_scalars(%coord_552) : !cute.coord<"?">
      %331 = cute.get_scalars(%coord_553) : !cute.coord<"?">
      %true_554 = arith.constant true
      %332 = arith.cmpi slt, %330, %331 : i32
      %333 = arith.andi %true_554, %332 : i1
      scf.if %333 {
        %1582 = cute.static : !cute.coord<"(_,7,_)">
        %lay_2576 = cute.get_layout(%view_99) : !memref_gmem_bf16_4
        %idx_2577 = cute.crd2idx(%1582, %lay_2576) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
        %iter_2578 = cute.get_iter(%view_99) : !memref_gmem_bf16_4
        %ptr_2579 = cute.add_offset(%iter_2578, %idx_2577) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2580 = cute.make_view(%ptr_2579) : !memref_gmem_bf16_6
        %iter_2581 = cute.get_iter(%view_2580) : !memref_gmem_bf16_6
        %1583 = cute.static : !cute.int_tuple<"7168">
        %iter_2582 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2583 = cute.add_offset(%iter_2582, %1583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_smem_bf16_8
        %iter_2585 = cute.get_iter(%view_2584) : !memref_smem_bf16_8
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_349) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2590 = cute.make_view(%iter_2581, %1585) : !memref_gmem_bf16_6
        %iter_2591 = cute.get_iter(%view_2590) : !memref_gmem_bf16_6
        %view_2592 = cute.make_view(%iter_2591) : !memref_gmem_bf16_7
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),8192)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_smem_bf16_8
        %iter_2594 = cute.get_iter(%view_2593) : !memref_smem_bf16_8
        %view_2595 = cute.make_view(%iter_2594) : !memref_smem_bf16_9
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_gmem_bf16_7
        %iter_2600 = cute.get_iter(%view_2595) : !memref_smem_bf16_9
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_gmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_smem_bf16_10
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_gmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_smem_bf16_10
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.trunc %1598 : i8 to i1
          %iter_2617 = cute.recast_iter(%iter_2614) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2618 : !cute.ptr<i128, smem>, %iter_2617 : !cute.ptr<i128, gmem>, %1599 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"7168">
        %iter_2576 = cute.get_iter(%view_112) : !memref_smem_bf16_3
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_8
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_8
      }
      %334 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_555 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_556 = cute.add_offset(%iter_555, %334) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_557 = cute.make_view(%tup_556) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_558 = cute.get_iter(%view_557) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_559, %e1_560, %e2_561, %e3_562 = cute.get_leaves(%iter_558) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_563 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %335 = cute.get_shape(%lay_563) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_564, %e1_565, %e2_566, %e3_567 = cute.get_leaves(%335) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_568 = cute.to_int_tuple(%e1_565) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_569 = cute.make_coord(%e1_560) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_570 = cute.make_coord(%itup_568) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %336 = cute.get_scalars(%coord_569) : !cute.coord<"?">
      %337 = cute.get_scalars(%coord_570) : !cute.coord<"?">
      %true_571 = arith.constant true
      %338 = arith.cmpi slt, %336, %337 : i32
      %339 = arith.andi %true_571, %338 : i1
      scf.if %339 {
        %coord_2576 = cute.make_coord(%32) : (i32) -> !cute.coord<"(_,0,_,?)">
        %lay_2577 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
        %idx_2578 = cute.crd2idx(%coord_2576, %lay_2577) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %iter_2579 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
        %ptr_2580 = cute.add_offset(%iter_2579, %idx_2578) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2581 = cute.make_view(%ptr_2580) : !memref_gmem_bf16_6
        %iter_2582 = cute.get_iter(%view_2581) : !memref_gmem_bf16_6
        %1582 = cute.static : !cute.int_tuple<"0">
        %iter_2583 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2584 = cute.add_offset(%iter_2583, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584) : !memref_smem_bf16_11
        %iter_2586 = cute.get_iter(%view_2585) : !memref_smem_bf16_11
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2587 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
        %ptr_2588 = cute.add_offset(%iter_2587, %1583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2589 = cute.make_view(%ptr_2588) : !memref_rmem_i8_2
        %iter_2590 = cute.get_iter(%view_2589) : !memref_rmem_i8_2
        %1584 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2591 = cute.make_view(%iter_2582, %1584) : !memref_gmem_bf16_6
        %iter_2592 = cute.get_iter(%view_2591) : !memref_gmem_bf16_6
        %view_2593 = cute.make_view(%iter_2592) : !memref_gmem_bf16_7
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2594 = cute.make_view(%iter_2586, %1585) : !memref_smem_bf16_11
        %iter_2595 = cute.get_iter(%view_2594) : !memref_smem_bf16_11
        %view_2596 = cute.make_view(%iter_2595) : !memref_smem_bf16_12
        %1586 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2597 = cute.make_view(%iter_2590, %1586) : !memref_rmem_i8_2
        %iter_2598 = cute.get_iter(%view_2597) : !memref_rmem_i8_2
        %view_2599 = cute.make_view(%iter_2598) : !memref_rmem_i8_3
        %1587 = cute.static : !cute.layout<"1:0">
        %iter_2600 = cute.get_iter(%view_2593) : !memref_gmem_bf16_7
        %iter_2601 = cute.get_iter(%view_2596) : !memref_smem_bf16_12
        %1588 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %iter_2602 = cute.get_iter(%view_2599) : !memref_rmem_i8_3
        %1590 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1591 = cute.static : !cute.int_tuple<"2">
        %1592 = cute.get_scalars(%1591) : !cute.int_tuple<"2">
        %c0_i32_2603 = arith.constant 0 : i32
        %c1_i32_2604 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2603 to %1592 step %c1_i32_2604  : i32 {
          %coord_2605 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1593 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2605, %1588) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2607 = cute.add_offset(%iter_2600, %idx_2606) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1593) : !memref_gmem_bf16_8
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2609 = cute.crd2idx(%coord_2605, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_2610 = cute.add_offset(%iter_2601, %idx_2609) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2611 = cute.make_view(%ptr_2610, %1594) : !memref_smem_bf16_10
          %1595 = cute.static : !cute.layout<"(1):(2)">
          %idx_2612 = cute.crd2idx(%coord_2605, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2613 = cute.add_offset(%iter_2602, %idx_2612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2614 = cute.make_view(%ptr_2613, %1595) : !memref_rmem_i8_4
          %iter_2615 = cute.get_iter(%view_2608) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2611) : !memref_smem_bf16_10
          %iter_2617 = cute.get_iter(%view_2614) : !memref_rmem_i8_4
          %1596 = builtin.unrealized_conversion_cast %iter_2617 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1597 = llvm.load %1596 : !llvm.ptr -> i8
          %1598 = llvm.trunc %1597 : i8 to i1
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2619 = cute.recast_iter(%iter_2616) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2619 : !cute.ptr<i128, smem>, %iter_2618 : !cute.ptr<i128, gmem>, %1598 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"0">
        %iter_2576 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_11
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_11
      }
      %340 = cute.static : !cute.int_tuple<"(0,16,0,0)">
      %iter_572 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_573 = cute.add_offset(%iter_572, %340) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_574 = cute.make_view(%tup_573) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_575 = cute.get_iter(%view_574) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_576, %e1_577, %e2_578, %e3_579 = cute.get_leaves(%iter_575) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_580 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %341 = cute.get_shape(%lay_580) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_581, %e1_582, %e2_583, %e3_584 = cute.get_leaves(%341) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_585 = cute.to_int_tuple(%e1_582) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_586 = cute.make_coord(%e1_577) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_587 = cute.make_coord(%itup_585) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %342 = cute.get_scalars(%coord_586) : !cute.coord<"?">
      %343 = cute.get_scalars(%coord_587) : !cute.coord<"?">
      %true_588 = arith.constant true
      %344 = arith.cmpi slt, %342, %343 : i32
      %345 = arith.andi %true_588, %344 : i1
      scf.if %345 {
        %coord_2576 = cute.make_coord(%32) : (i32) -> !cute.coord<"(_,1,_,?)">
        %lay_2577 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
        %idx_2578 = cute.crd2idx(%coord_2576, %lay_2577) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %iter_2579 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
        %ptr_2580 = cute.add_offset(%iter_2579, %idx_2578) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2581 = cute.make_view(%ptr_2580) : !memref_gmem_bf16_6
        %iter_2582 = cute.get_iter(%view_2581) : !memref_gmem_bf16_6
        %1582 = cute.static : !cute.int_tuple<"1024">
        %iter_2583 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2584 = cute.add_offset(%iter_2583, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584) : !memref_smem_bf16_11
        %iter_2586 = cute.get_iter(%view_2585) : !memref_smem_bf16_11
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2587 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
        %ptr_2588 = cute.add_offset(%iter_2587, %1583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2589 = cute.make_view(%ptr_2588) : !memref_rmem_i8_2
        %iter_2590 = cute.get_iter(%view_2589) : !memref_rmem_i8_2
        %1584 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2591 = cute.make_view(%iter_2582, %1584) : !memref_gmem_bf16_6
        %iter_2592 = cute.get_iter(%view_2591) : !memref_gmem_bf16_6
        %view_2593 = cute.make_view(%iter_2592) : !memref_gmem_bf16_7
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2594 = cute.make_view(%iter_2586, %1585) : !memref_smem_bf16_11
        %iter_2595 = cute.get_iter(%view_2594) : !memref_smem_bf16_11
        %view_2596 = cute.make_view(%iter_2595) : !memref_smem_bf16_12
        %1586 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2597 = cute.make_view(%iter_2590, %1586) : !memref_rmem_i8_2
        %iter_2598 = cute.get_iter(%view_2597) : !memref_rmem_i8_2
        %view_2599 = cute.make_view(%iter_2598) : !memref_rmem_i8_3
        %1587 = cute.static : !cute.layout<"1:0">
        %iter_2600 = cute.get_iter(%view_2593) : !memref_gmem_bf16_7
        %iter_2601 = cute.get_iter(%view_2596) : !memref_smem_bf16_12
        %1588 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %iter_2602 = cute.get_iter(%view_2599) : !memref_rmem_i8_3
        %1590 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1591 = cute.static : !cute.int_tuple<"2">
        %1592 = cute.get_scalars(%1591) : !cute.int_tuple<"2">
        %c0_i32_2603 = arith.constant 0 : i32
        %c1_i32_2604 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2603 to %1592 step %c1_i32_2604  : i32 {
          %coord_2605 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1593 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2605, %1588) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2607 = cute.add_offset(%iter_2600, %idx_2606) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1593) : !memref_gmem_bf16_8
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2609 = cute.crd2idx(%coord_2605, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_2610 = cute.add_offset(%iter_2601, %idx_2609) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2611 = cute.make_view(%ptr_2610, %1594) : !memref_smem_bf16_10
          %1595 = cute.static : !cute.layout<"(1):(2)">
          %idx_2612 = cute.crd2idx(%coord_2605, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2613 = cute.add_offset(%iter_2602, %idx_2612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2614 = cute.make_view(%ptr_2613, %1595) : !memref_rmem_i8_4
          %iter_2615 = cute.get_iter(%view_2608) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2611) : !memref_smem_bf16_10
          %iter_2617 = cute.get_iter(%view_2614) : !memref_rmem_i8_4
          %1596 = builtin.unrealized_conversion_cast %iter_2617 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1597 = llvm.load %1596 : !llvm.ptr -> i8
          %1598 = llvm.trunc %1597 : i8 to i1
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2619 = cute.recast_iter(%iter_2616) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2619 : !cute.ptr<i128, smem>, %iter_2618 : !cute.ptr<i128, gmem>, %1598 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"1024">
        %iter_2576 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_11
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_11
      }
      %346 = cute.static : !cute.int_tuple<"(0,32,0,0)">
      %iter_589 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_590 = cute.add_offset(%iter_589, %346) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_591 = cute.make_view(%tup_590) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_592 = cute.get_iter(%view_591) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_593, %e1_594, %e2_595, %e3_596 = cute.get_leaves(%iter_592) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_597 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %347 = cute.get_shape(%lay_597) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_598, %e1_599, %e2_600, %e3_601 = cute.get_leaves(%347) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_602 = cute.to_int_tuple(%e1_599) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_603 = cute.make_coord(%e1_594) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_604 = cute.make_coord(%itup_602) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %348 = cute.get_scalars(%coord_603) : !cute.coord<"?">
      %349 = cute.get_scalars(%coord_604) : !cute.coord<"?">
      %true_605 = arith.constant true
      %350 = arith.cmpi slt, %348, %349 : i32
      %351 = arith.andi %true_605, %350 : i1
      scf.if %351 {
        %coord_2576 = cute.make_coord(%32) : (i32) -> !cute.coord<"(_,2,_,?)">
        %lay_2577 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
        %idx_2578 = cute.crd2idx(%coord_2576, %lay_2577) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
        %iter_2579 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
        %ptr_2580 = cute.add_offset(%iter_2579, %idx_2578) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2581 = cute.make_view(%ptr_2580) : !memref_gmem_bf16_6
        %iter_2582 = cute.get_iter(%view_2581) : !memref_gmem_bf16_6
        %1582 = cute.static : !cute.int_tuple<"2048">
        %iter_2583 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2584 = cute.add_offset(%iter_2583, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584) : !memref_smem_bf16_11
        %iter_2586 = cute.get_iter(%view_2585) : !memref_smem_bf16_11
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2587 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
        %ptr_2588 = cute.add_offset(%iter_2587, %1583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2589 = cute.make_view(%ptr_2588) : !memref_rmem_i8_2
        %iter_2590 = cute.get_iter(%view_2589) : !memref_rmem_i8_2
        %1584 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2591 = cute.make_view(%iter_2582, %1584) : !memref_gmem_bf16_6
        %iter_2592 = cute.get_iter(%view_2591) : !memref_gmem_bf16_6
        %view_2593 = cute.make_view(%iter_2592) : !memref_gmem_bf16_7
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2594 = cute.make_view(%iter_2586, %1585) : !memref_smem_bf16_11
        %iter_2595 = cute.get_iter(%view_2594) : !memref_smem_bf16_11
        %view_2596 = cute.make_view(%iter_2595) : !memref_smem_bf16_12
        %1586 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2597 = cute.make_view(%iter_2590, %1586) : !memref_rmem_i8_2
        %iter_2598 = cute.get_iter(%view_2597) : !memref_rmem_i8_2
        %view_2599 = cute.make_view(%iter_2598) : !memref_rmem_i8_3
        %1587 = cute.static : !cute.layout<"1:0">
        %iter_2600 = cute.get_iter(%view_2593) : !memref_gmem_bf16_7
        %iter_2601 = cute.get_iter(%view_2596) : !memref_smem_bf16_12
        %1588 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %iter_2602 = cute.get_iter(%view_2599) : !memref_rmem_i8_3
        %1590 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1591 = cute.static : !cute.int_tuple<"2">
        %1592 = cute.get_scalars(%1591) : !cute.int_tuple<"2">
        %c0_i32_2603 = arith.constant 0 : i32
        %c1_i32_2604 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2603 to %1592 step %c1_i32_2604  : i32 {
          %coord_2605 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1593 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2605, %1588) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2607 = cute.add_offset(%iter_2600, %idx_2606) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1593) : !memref_gmem_bf16_8
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2609 = cute.crd2idx(%coord_2605, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_2610 = cute.add_offset(%iter_2601, %idx_2609) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2611 = cute.make_view(%ptr_2610, %1594) : !memref_smem_bf16_10
          %1595 = cute.static : !cute.layout<"(1):(2)">
          %idx_2612 = cute.crd2idx(%coord_2605, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2613 = cute.add_offset(%iter_2602, %idx_2612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2614 = cute.make_view(%ptr_2613, %1595) : !memref_rmem_i8_4
          %iter_2615 = cute.get_iter(%view_2608) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2611) : !memref_smem_bf16_10
          %iter_2617 = cute.get_iter(%view_2614) : !memref_rmem_i8_4
          %1596 = builtin.unrealized_conversion_cast %iter_2617 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1597 = llvm.load %1596 : !llvm.ptr -> i8
          %1598 = llvm.trunc %1597 : i8 to i1
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2619 = cute.recast_iter(%iter_2616) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2619 : !cute.ptr<i128, smem>, %iter_2618 : !cute.ptr<i128, gmem>, %1598 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"2048">
        %iter_2576 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_11
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_11
      }
      %352 = cute.static : !cute.int_tuple<"(0,48,0,0)">
      %iter_606 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %tup_607 = cute.add_offset(%iter_606, %352) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_608 = cute.make_view(%tup_607) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_609 = cute.get_iter(%view_608) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_610, %e1_611, %e2_612, %e3_613 = cute.get_leaves(%iter_609) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_614 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %353 = cute.get_shape(%lay_614) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_615, %e1_616, %e2_617, %e3_618 = cute.get_leaves(%353) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_619 = cute.to_int_tuple(%e1_616) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_620 = cute.make_coord(%e1_611) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_621 = cute.make_coord(%itup_619) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %354 = cute.get_scalars(%coord_620) : !cute.coord<"?">
      %355 = cute.get_scalars(%coord_621) : !cute.coord<"?">
      %true_622 = arith.constant true
      %356 = arith.cmpi slt, %354, %355 : i32
      %357 = arith.andi %true_622, %356 : i1
      scf.if %357 {
        %coord_2576 = cute.make_coord(%32) : (i32) -> !cute.coord<"(_,3,_,?)">
        %lay_2577 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
        %idx_2578 = cute.crd2idx(%coord_2576, %lay_2577) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %iter_2579 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
        %ptr_2580 = cute.add_offset(%iter_2579, %idx_2578) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2581 = cute.make_view(%ptr_2580) : !memref_gmem_bf16_6
        %iter_2582 = cute.get_iter(%view_2581) : !memref_gmem_bf16_6
        %1582 = cute.static : !cute.int_tuple<"3072">
        %iter_2583 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2584 = cute.add_offset(%iter_2583, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584) : !memref_smem_bf16_11
        %iter_2586 = cute.get_iter(%view_2585) : !memref_smem_bf16_11
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2587 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
        %ptr_2588 = cute.add_offset(%iter_2587, %1583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2589 = cute.make_view(%ptr_2588) : !memref_rmem_i8_2
        %iter_2590 = cute.get_iter(%view_2589) : !memref_rmem_i8_2
        %1584 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2591 = cute.make_view(%iter_2582, %1584) : !memref_gmem_bf16_6
        %iter_2592 = cute.get_iter(%view_2591) : !memref_gmem_bf16_6
        %view_2593 = cute.make_view(%iter_2592) : !memref_gmem_bf16_7
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2594 = cute.make_view(%iter_2586, %1585) : !memref_smem_bf16_11
        %iter_2595 = cute.get_iter(%view_2594) : !memref_smem_bf16_11
        %view_2596 = cute.make_view(%iter_2595) : !memref_smem_bf16_12
        %1586 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2597 = cute.make_view(%iter_2590, %1586) : !memref_rmem_i8_2
        %iter_2598 = cute.get_iter(%view_2597) : !memref_rmem_i8_2
        %view_2599 = cute.make_view(%iter_2598) : !memref_rmem_i8_3
        %1587 = cute.static : !cute.layout<"1:0">
        %iter_2600 = cute.get_iter(%view_2593) : !memref_gmem_bf16_7
        %iter_2601 = cute.get_iter(%view_2596) : !memref_smem_bf16_12
        %1588 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %iter_2602 = cute.get_iter(%view_2599) : !memref_rmem_i8_3
        %1590 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1591 = cute.static : !cute.int_tuple<"2">
        %1592 = cute.get_scalars(%1591) : !cute.int_tuple<"2">
        %c0_i32_2603 = arith.constant 0 : i32
        %c1_i32_2604 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2603 to %1592 step %c1_i32_2604  : i32 {
          %coord_2605 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1593 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2605, %1588) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2607 = cute.add_offset(%iter_2600, %idx_2606) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1593) : !memref_gmem_bf16_8
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2609 = cute.crd2idx(%coord_2605, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_2610 = cute.add_offset(%iter_2601, %idx_2609) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2611 = cute.make_view(%ptr_2610, %1594) : !memref_smem_bf16_10
          %1595 = cute.static : !cute.layout<"(1):(2)">
          %idx_2612 = cute.crd2idx(%coord_2605, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2613 = cute.add_offset(%iter_2602, %idx_2612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2614 = cute.make_view(%ptr_2613, %1595) : !memref_rmem_i8_4
          %iter_2615 = cute.get_iter(%view_2608) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2611) : !memref_smem_bf16_10
          %iter_2617 = cute.get_iter(%view_2614) : !memref_rmem_i8_4
          %1596 = builtin.unrealized_conversion_cast %iter_2617 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1597 = llvm.load %1596 : !llvm.ptr -> i8
          %1598 = llvm.trunc %1597 : i8 to i1
          %iter_2618 = cute.recast_iter(%iter_2615) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2619 = cute.recast_iter(%iter_2616) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2619 : !cute.ptr<i128, smem>, %iter_2618 : !cute.ptr<i128, gmem>, %1598 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %1582 = cute.static : !cute.int_tuple<"3072">
        %iter_2576 = cute.get_iter(%view_145) : !memref_smem_bf16_4
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_smem_bf16_11
        %cst_2579 = arith.constant 0.000000e+00 : bf16
        %1583 = vector.splat %cst_2579 : vector<16xbf16>
        cute.memref.store_vec %1583, %view_2578 : !memref_smem_bf16_11
      }
      nvvm.cp.async.commit.group
      %358 = cute.static : !cute.layout<"4:1">
      %rmem_623 = cute.memref.alloca(%358) : !memref_rmem_f32_1
      %359 = cute.static : !cute.layout<"4:1">
      %rmem_624 = cute.memref.alloca(%359) : !memref_rmem_f32_1
      %cst_625 = arith.constant 0xFF800000 : f32
      %360 = vector.splat %cst_625 : vector<4xf32>
      cute.memref.store_vec %360, %rmem_623 : !memref_rmem_f32_1
      %cst_626 = arith.constant 0.000000e+00 : f32
      %361 = vector.splat %cst_626 : vector<4xf32>
      cute.memref.store_vec %361, %rmem_624 : !memref_rmem_f32_1
      %c0_i32_627 = arith.constant 0 : i32
      %362 = arith.subi %31, %c0_i32_627 : i32
      %363 = arith.subi %362, %c1_i32 : i32
      %364 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %rmem_628 = cute.memref.alloca(%364) : !memref_rmem_f32_2
      %iter_629 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %cst_630 = arith.constant 0.000000e+00 : f32
      %365 = vector.splat %cst_630 : vector<64xf32>
      cute.memref.store_vec %365, %rmem_628 : !memref_rmem_f32_2
      nvvm.cp.async.wait.group 0
      %c1_i32_631 = arith.constant 1 : i32
      %c128_i32_632 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_631 number_of_threads = %c128_i32_632
      %true_633 = arith.constant true
      scf.if %true_633 {
        %1582 = cute.static : !cute.int_tuple<"(0,0,0,0)">
        %iter_2576 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
        %tup_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
        %view_2578 = cute.make_view(%tup_2577) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %iter_2579 = cute.get_iter(%view_2578) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %e0_2580, %e1_2581, %e2_2582, %e3_2583 = cute.get_leaves(%iter_2579) : !cute.int_tuple<"(?,?,?,?{div=8})">
        %lay_2584 = cute.get_layout(%arg1) : !memref_gmem_bf16_
        %1583 = cute.get_shape(%lay_2584) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2585, %e1_2586, %e2_2587, %e3_2588 = cute.get_leaves(%1583) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2589 = cute.to_int_tuple(%e1_2586) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %coord_2590 = cute.make_coord(%e1_2581) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %coord_2591 = cute.make_coord(%itup_2589) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %1584 = cute.get_scalars(%coord_2590) : !cute.coord<"?">
        %1585 = cute.get_scalars(%coord_2591) : !cute.coord<"?">
        %true_2592 = arith.constant true
        %1586 = arith.cmpi slt, %1584, %1585 : i32
        %1587 = arith.andi %true_2592, %1586 : i1
        scf.if %1587 {
          %coord_2644 = cute.make_coord(%363) : (i32) -> !cute.coord<"(_,0,_,?)">
          %lay_2645 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
          %idx_2646 = cute.crd2idx(%coord_2644, %lay_2645) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %iter_2647 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
          %ptr_2648 = cute.add_offset(%iter_2647, %idx_2646) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2649 = cute.make_view(%ptr_2648) : !memref_gmem_bf16_6
          %iter_2650 = cute.get_iter(%view_2649) : !memref_gmem_bf16_6
          %1606 = cute.static : !cute.int_tuple<"0">
          %iter_2651 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2652 = cute.add_offset(%iter_2651, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2653 = cute.make_view(%ptr_2652) : !memref_smem_bf16_11
          %iter_2654 = cute.get_iter(%view_2653) : !memref_smem_bf16_11
          %1607 = cute.static : !cute.int_tuple<"0">
          %iter_2655 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
          %ptr_2656 = cute.add_offset(%iter_2655, %1607) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_2657 = cute.make_view(%ptr_2656) : !memref_rmem_i8_2
          %iter_2658 = cute.get_iter(%view_2657) : !memref_rmem_i8_2
          %1608 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
          %view_2659 = cute.make_view(%iter_2650, %1608) : !memref_gmem_bf16_6
          %iter_2660 = cute.get_iter(%view_2659) : !memref_gmem_bf16_6
          %view_2661 = cute.make_view(%iter_2660) : !memref_gmem_bf16_7
          %1609 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
          %view_2662 = cute.make_view(%iter_2654, %1609) : !memref_smem_bf16_11
          %iter_2663 = cute.get_iter(%view_2662) : !memref_smem_bf16_11
          %view_2664 = cute.make_view(%iter_2663) : !memref_smem_bf16_12
          %1610 = cute.static : !cute.layout<"(1,2):(2,1)">
          %view_2665 = cute.make_view(%iter_2658, %1610) : !memref_rmem_i8_2
          %iter_2666 = cute.get_iter(%view_2665) : !memref_rmem_i8_2
          %view_2667 = cute.make_view(%iter_2666) : !memref_rmem_i8_3
          %1611 = cute.static : !cute.layout<"1:0">
          %iter_2668 = cute.get_iter(%view_2661) : !memref_gmem_bf16_7
          %iter_2669 = cute.get_iter(%view_2664) : !memref_smem_bf16_12
          %1612 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
          %1613 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
          %iter_2670 = cute.get_iter(%view_2667) : !memref_rmem_i8_3
          %1614 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
          %1615 = cute.static : !cute.int_tuple<"2">
          %1616 = cute.get_scalars(%1615) : !cute.int_tuple<"2">
          %c0_i32_2671 = arith.constant 0 : i32
          %c1_i32_2672 = arith.constant 1 : i32
          scf.for %arg5 = %c0_i32_2671 to %1616 step %c1_i32_2672  : i32 {
            %coord_2673 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
            %1617 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2674 = cute.crd2idx(%coord_2673, %1612) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_2675 = cute.add_offset(%iter_2668, %idx_2674) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_2676 = cute.make_view(%ptr_2675, %1617) : !memref_gmem_bf16_8
            %1618 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2677 = cute.crd2idx(%coord_2673, %1613) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_2678 = cute.add_offset(%iter_2669, %idx_2677) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_2679 = cute.make_view(%ptr_2678, %1618) : !memref_smem_bf16_10
            %1619 = cute.static : !cute.layout<"(1):(2)">
            %idx_2680 = cute.crd2idx(%coord_2673, %1614) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
            %ptr_2681 = cute.add_offset(%iter_2670, %idx_2680) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_2682 = cute.make_view(%ptr_2681, %1619) : !memref_rmem_i8_4
            %iter_2683 = cute.get_iter(%view_2676) : !memref_gmem_bf16_8
            %iter_2684 = cute.get_iter(%view_2679) : !memref_smem_bf16_10
            %iter_2685 = cute.get_iter(%view_2682) : !memref_rmem_i8_4
            %1620 = builtin.unrealized_conversion_cast %iter_2685 : !cute.ptr<i8, rmem> to !llvm.ptr
            %1621 = llvm.load %1620 : !llvm.ptr -> i8
            %1622 = llvm.trunc %1621 : i8 to i1
            %iter_2686 = cute.recast_iter(%iter_2683) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_2687 = cute.recast_iter(%iter_2684) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_2687 : !cute.ptr<i128, smem>, %iter_2686 : !cute.ptr<i128, gmem>, %1622 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        } else {
          %1606 = cute.static : !cute.int_tuple<"0">
          %iter_2644 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2645 = cute.add_offset(%iter_2644, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2646 = cute.make_view(%ptr_2645) : !memref_smem_bf16_11
          %cst_2647 = arith.constant 0.000000e+00 : bf16
          %1607 = vector.splat %cst_2647 : vector<16xbf16>
          cute.memref.store_vec %1607, %view_2646 : !memref_smem_bf16_11
        }
        %1588 = cute.static : !cute.int_tuple<"(0,16,0,0)">
        %iter_2593 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
        %tup_2594 = cute.add_offset(%iter_2593, %1588) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
        %view_2595 = cute.make_view(%tup_2594) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %iter_2596 = cute.get_iter(%view_2595) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %e0_2597, %e1_2598, %e2_2599, %e3_2600 = cute.get_leaves(%iter_2596) : !cute.int_tuple<"(?,?,?,?{div=8})">
        %lay_2601 = cute.get_layout(%arg1) : !memref_gmem_bf16_
        %1589 = cute.get_shape(%lay_2601) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2602, %e1_2603, %e2_2604, %e3_2605 = cute.get_leaves(%1589) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2606 = cute.to_int_tuple(%e1_2603) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %coord_2607 = cute.make_coord(%e1_2598) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %coord_2608 = cute.make_coord(%itup_2606) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %1590 = cute.get_scalars(%coord_2607) : !cute.coord<"?">
        %1591 = cute.get_scalars(%coord_2608) : !cute.coord<"?">
        %true_2609 = arith.constant true
        %1592 = arith.cmpi slt, %1590, %1591 : i32
        %1593 = arith.andi %true_2609, %1592 : i1
        scf.if %1593 {
          %coord_2644 = cute.make_coord(%363) : (i32) -> !cute.coord<"(_,1,_,?)">
          %lay_2645 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
          %idx_2646 = cute.crd2idx(%coord_2644, %lay_2645) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
          %iter_2647 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
          %ptr_2648 = cute.add_offset(%iter_2647, %idx_2646) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2649 = cute.make_view(%ptr_2648) : !memref_gmem_bf16_6
          %iter_2650 = cute.get_iter(%view_2649) : !memref_gmem_bf16_6
          %1606 = cute.static : !cute.int_tuple<"1024">
          %iter_2651 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2652 = cute.add_offset(%iter_2651, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2653 = cute.make_view(%ptr_2652) : !memref_smem_bf16_11
          %iter_2654 = cute.get_iter(%view_2653) : !memref_smem_bf16_11
          %1607 = cute.static : !cute.int_tuple<"0">
          %iter_2655 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
          %ptr_2656 = cute.add_offset(%iter_2655, %1607) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_2657 = cute.make_view(%ptr_2656) : !memref_rmem_i8_2
          %iter_2658 = cute.get_iter(%view_2657) : !memref_rmem_i8_2
          %1608 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
          %view_2659 = cute.make_view(%iter_2650, %1608) : !memref_gmem_bf16_6
          %iter_2660 = cute.get_iter(%view_2659) : !memref_gmem_bf16_6
          %view_2661 = cute.make_view(%iter_2660) : !memref_gmem_bf16_7
          %1609 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
          %view_2662 = cute.make_view(%iter_2654, %1609) : !memref_smem_bf16_11
          %iter_2663 = cute.get_iter(%view_2662) : !memref_smem_bf16_11
          %view_2664 = cute.make_view(%iter_2663) : !memref_smem_bf16_12
          %1610 = cute.static : !cute.layout<"(1,2):(2,1)">
          %view_2665 = cute.make_view(%iter_2658, %1610) : !memref_rmem_i8_2
          %iter_2666 = cute.get_iter(%view_2665) : !memref_rmem_i8_2
          %view_2667 = cute.make_view(%iter_2666) : !memref_rmem_i8_3
          %1611 = cute.static : !cute.layout<"1:0">
          %iter_2668 = cute.get_iter(%view_2661) : !memref_gmem_bf16_7
          %iter_2669 = cute.get_iter(%view_2664) : !memref_smem_bf16_12
          %1612 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
          %1613 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
          %iter_2670 = cute.get_iter(%view_2667) : !memref_rmem_i8_3
          %1614 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
          %1615 = cute.static : !cute.int_tuple<"2">
          %1616 = cute.get_scalars(%1615) : !cute.int_tuple<"2">
          %c0_i32_2671 = arith.constant 0 : i32
          %c1_i32_2672 = arith.constant 1 : i32
          scf.for %arg5 = %c0_i32_2671 to %1616 step %c1_i32_2672  : i32 {
            %coord_2673 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
            %1617 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2674 = cute.crd2idx(%coord_2673, %1612) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_2675 = cute.add_offset(%iter_2668, %idx_2674) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_2676 = cute.make_view(%ptr_2675, %1617) : !memref_gmem_bf16_8
            %1618 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2677 = cute.crd2idx(%coord_2673, %1613) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_2678 = cute.add_offset(%iter_2669, %idx_2677) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_2679 = cute.make_view(%ptr_2678, %1618) : !memref_smem_bf16_10
            %1619 = cute.static : !cute.layout<"(1):(2)">
            %idx_2680 = cute.crd2idx(%coord_2673, %1614) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
            %ptr_2681 = cute.add_offset(%iter_2670, %idx_2680) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_2682 = cute.make_view(%ptr_2681, %1619) : !memref_rmem_i8_4
            %iter_2683 = cute.get_iter(%view_2676) : !memref_gmem_bf16_8
            %iter_2684 = cute.get_iter(%view_2679) : !memref_smem_bf16_10
            %iter_2685 = cute.get_iter(%view_2682) : !memref_rmem_i8_4
            %1620 = builtin.unrealized_conversion_cast %iter_2685 : !cute.ptr<i8, rmem> to !llvm.ptr
            %1621 = llvm.load %1620 : !llvm.ptr -> i8
            %1622 = llvm.trunc %1621 : i8 to i1
            %iter_2686 = cute.recast_iter(%iter_2683) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_2687 = cute.recast_iter(%iter_2684) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_2687 : !cute.ptr<i128, smem>, %iter_2686 : !cute.ptr<i128, gmem>, %1622 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        } else {
          %1606 = cute.static : !cute.int_tuple<"1024">
          %iter_2644 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2645 = cute.add_offset(%iter_2644, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2646 = cute.make_view(%ptr_2645) : !memref_smem_bf16_11
          %cst_2647 = arith.constant 0.000000e+00 : bf16
          %1607 = vector.splat %cst_2647 : vector<16xbf16>
          cute.memref.store_vec %1607, %view_2646 : !memref_smem_bf16_11
        }
        %1594 = cute.static : !cute.int_tuple<"(0,32,0,0)">
        %iter_2610 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
        %tup_2611 = cute.add_offset(%iter_2610, %1594) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
        %view_2612 = cute.make_view(%tup_2611) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %iter_2613 = cute.get_iter(%view_2612) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %e0_2614, %e1_2615, %e2_2616, %e3_2617 = cute.get_leaves(%iter_2613) : !cute.int_tuple<"(?,?,?,?{div=8})">
        %lay_2618 = cute.get_layout(%arg1) : !memref_gmem_bf16_
        %1595 = cute.get_shape(%lay_2618) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2619, %e1_2620, %e2_2621, %e3_2622 = cute.get_leaves(%1595) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2623 = cute.to_int_tuple(%e1_2620) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %coord_2624 = cute.make_coord(%e1_2615) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %coord_2625 = cute.make_coord(%itup_2623) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %1596 = cute.get_scalars(%coord_2624) : !cute.coord<"?">
        %1597 = cute.get_scalars(%coord_2625) : !cute.coord<"?">
        %true_2626 = arith.constant true
        %1598 = arith.cmpi slt, %1596, %1597 : i32
        %1599 = arith.andi %true_2626, %1598 : i1
        scf.if %1599 {
          %coord_2644 = cute.make_coord(%363) : (i32) -> !cute.coord<"(_,2,_,?)">
          %lay_2645 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
          %idx_2646 = cute.crd2idx(%coord_2644, %lay_2645) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
          %iter_2647 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
          %ptr_2648 = cute.add_offset(%iter_2647, %idx_2646) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2649 = cute.make_view(%ptr_2648) : !memref_gmem_bf16_6
          %iter_2650 = cute.get_iter(%view_2649) : !memref_gmem_bf16_6
          %1606 = cute.static : !cute.int_tuple<"2048">
          %iter_2651 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2652 = cute.add_offset(%iter_2651, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2653 = cute.make_view(%ptr_2652) : !memref_smem_bf16_11
          %iter_2654 = cute.get_iter(%view_2653) : !memref_smem_bf16_11
          %1607 = cute.static : !cute.int_tuple<"0">
          %iter_2655 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
          %ptr_2656 = cute.add_offset(%iter_2655, %1607) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_2657 = cute.make_view(%ptr_2656) : !memref_rmem_i8_2
          %iter_2658 = cute.get_iter(%view_2657) : !memref_rmem_i8_2
          %1608 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
          %view_2659 = cute.make_view(%iter_2650, %1608) : !memref_gmem_bf16_6
          %iter_2660 = cute.get_iter(%view_2659) : !memref_gmem_bf16_6
          %view_2661 = cute.make_view(%iter_2660) : !memref_gmem_bf16_7
          %1609 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
          %view_2662 = cute.make_view(%iter_2654, %1609) : !memref_smem_bf16_11
          %iter_2663 = cute.get_iter(%view_2662) : !memref_smem_bf16_11
          %view_2664 = cute.make_view(%iter_2663) : !memref_smem_bf16_12
          %1610 = cute.static : !cute.layout<"(1,2):(2,1)">
          %view_2665 = cute.make_view(%iter_2658, %1610) : !memref_rmem_i8_2
          %iter_2666 = cute.get_iter(%view_2665) : !memref_rmem_i8_2
          %view_2667 = cute.make_view(%iter_2666) : !memref_rmem_i8_3
          %1611 = cute.static : !cute.layout<"1:0">
          %iter_2668 = cute.get_iter(%view_2661) : !memref_gmem_bf16_7
          %iter_2669 = cute.get_iter(%view_2664) : !memref_smem_bf16_12
          %1612 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
          %1613 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
          %iter_2670 = cute.get_iter(%view_2667) : !memref_rmem_i8_3
          %1614 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
          %1615 = cute.static : !cute.int_tuple<"2">
          %1616 = cute.get_scalars(%1615) : !cute.int_tuple<"2">
          %c0_i32_2671 = arith.constant 0 : i32
          %c1_i32_2672 = arith.constant 1 : i32
          scf.for %arg5 = %c0_i32_2671 to %1616 step %c1_i32_2672  : i32 {
            %coord_2673 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
            %1617 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2674 = cute.crd2idx(%coord_2673, %1612) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_2675 = cute.add_offset(%iter_2668, %idx_2674) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_2676 = cute.make_view(%ptr_2675, %1617) : !memref_gmem_bf16_8
            %1618 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2677 = cute.crd2idx(%coord_2673, %1613) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_2678 = cute.add_offset(%iter_2669, %idx_2677) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_2679 = cute.make_view(%ptr_2678, %1618) : !memref_smem_bf16_10
            %1619 = cute.static : !cute.layout<"(1):(2)">
            %idx_2680 = cute.crd2idx(%coord_2673, %1614) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
            %ptr_2681 = cute.add_offset(%iter_2670, %idx_2680) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_2682 = cute.make_view(%ptr_2681, %1619) : !memref_rmem_i8_4
            %iter_2683 = cute.get_iter(%view_2676) : !memref_gmem_bf16_8
            %iter_2684 = cute.get_iter(%view_2679) : !memref_smem_bf16_10
            %iter_2685 = cute.get_iter(%view_2682) : !memref_rmem_i8_4
            %1620 = builtin.unrealized_conversion_cast %iter_2685 : !cute.ptr<i8, rmem> to !llvm.ptr
            %1621 = llvm.load %1620 : !llvm.ptr -> i8
            %1622 = llvm.trunc %1621 : i8 to i1
            %iter_2686 = cute.recast_iter(%iter_2683) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_2687 = cute.recast_iter(%iter_2684) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_2687 : !cute.ptr<i128, smem>, %iter_2686 : !cute.ptr<i128, gmem>, %1622 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        } else {
          %1606 = cute.static : !cute.int_tuple<"2048">
          %iter_2644 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2645 = cute.add_offset(%iter_2644, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2646 = cute.make_view(%ptr_2645) : !memref_smem_bf16_11
          %cst_2647 = arith.constant 0.000000e+00 : bf16
          %1607 = vector.splat %cst_2647 : vector<16xbf16>
          cute.memref.store_vec %1607, %view_2646 : !memref_smem_bf16_11
        }
        %1600 = cute.static : !cute.int_tuple<"(0,48,0,0)">
        %iter_2627 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
        %tup_2628 = cute.add_offset(%iter_2627, %1600) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
        %view_2629 = cute.make_view(%tup_2628) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %iter_2630 = cute.get_iter(%view_2629) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
        %e0_2631, %e1_2632, %e2_2633, %e3_2634 = cute.get_leaves(%iter_2630) : !cute.int_tuple<"(?,?,?,?{div=8})">
        %lay_2635 = cute.get_layout(%arg1) : !memref_gmem_bf16_
        %1601 = cute.get_shape(%lay_2635) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %e0_2636, %e1_2637, %e2_2638, %e3_2639 = cute.get_leaves(%1601) : !cute.shape<"(?,?,?,?{div=8})">
        %itup_2640 = cute.to_int_tuple(%e1_2637) : !cute.shape<"?"> to !cute.int_tuple<"?">
        %coord_2641 = cute.make_coord(%e1_2632) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %coord_2642 = cute.make_coord(%itup_2640) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %1602 = cute.get_scalars(%coord_2641) : !cute.coord<"?">
        %1603 = cute.get_scalars(%coord_2642) : !cute.coord<"?">
        %true_2643 = arith.constant true
        %1604 = arith.cmpi slt, %1602, %1603 : i32
        %1605 = arith.andi %true_2643, %1604 : i1
        scf.if %1605 {
          %coord_2644 = cute.make_coord(%363) : (i32) -> !cute.coord<"(_,3,_,?)">
          %lay_2645 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
          %idx_2646 = cute.crd2idx(%coord_2644, %lay_2645) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
          %iter_2647 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
          %ptr_2648 = cute.add_offset(%iter_2647, %idx_2646) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2649 = cute.make_view(%ptr_2648) : !memref_gmem_bf16_6
          %iter_2650 = cute.get_iter(%view_2649) : !memref_gmem_bf16_6
          %1606 = cute.static : !cute.int_tuple<"3072">
          %iter_2651 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2652 = cute.add_offset(%iter_2651, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2653 = cute.make_view(%ptr_2652) : !memref_smem_bf16_11
          %iter_2654 = cute.get_iter(%view_2653) : !memref_smem_bf16_11
          %1607 = cute.static : !cute.int_tuple<"0">
          %iter_2655 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
          %ptr_2656 = cute.add_offset(%iter_2655, %1607) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_2657 = cute.make_view(%ptr_2656) : !memref_rmem_i8_2
          %iter_2658 = cute.get_iter(%view_2657) : !memref_rmem_i8_2
          %1608 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
          %view_2659 = cute.make_view(%iter_2650, %1608) : !memref_gmem_bf16_6
          %iter_2660 = cute.get_iter(%view_2659) : !memref_gmem_bf16_6
          %view_2661 = cute.make_view(%iter_2660) : !memref_gmem_bf16_7
          %1609 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
          %view_2662 = cute.make_view(%iter_2654, %1609) : !memref_smem_bf16_11
          %iter_2663 = cute.get_iter(%view_2662) : !memref_smem_bf16_11
          %view_2664 = cute.make_view(%iter_2663) : !memref_smem_bf16_12
          %1610 = cute.static : !cute.layout<"(1,2):(2,1)">
          %view_2665 = cute.make_view(%iter_2658, %1610) : !memref_rmem_i8_2
          %iter_2666 = cute.get_iter(%view_2665) : !memref_rmem_i8_2
          %view_2667 = cute.make_view(%iter_2666) : !memref_rmem_i8_3
          %1611 = cute.static : !cute.layout<"1:0">
          %iter_2668 = cute.get_iter(%view_2661) : !memref_gmem_bf16_7
          %iter_2669 = cute.get_iter(%view_2664) : !memref_smem_bf16_12
          %1612 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
          %1613 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
          %iter_2670 = cute.get_iter(%view_2667) : !memref_rmem_i8_3
          %1614 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
          %1615 = cute.static : !cute.int_tuple<"2">
          %1616 = cute.get_scalars(%1615) : !cute.int_tuple<"2">
          %c0_i32_2671 = arith.constant 0 : i32
          %c1_i32_2672 = arith.constant 1 : i32
          scf.for %arg5 = %c0_i32_2671 to %1616 step %c1_i32_2672  : i32 {
            %coord_2673 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
            %1617 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2674 = cute.crd2idx(%coord_2673, %1612) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
            %ptr_2675 = cute.add_offset(%iter_2668, %idx_2674) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_2676 = cute.make_view(%ptr_2675, %1617) : !memref_gmem_bf16_8
            %1618 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_2677 = cute.crd2idx(%coord_2673, %1613) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_2678 = cute.add_offset(%iter_2669, %idx_2677) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_2679 = cute.make_view(%ptr_2678, %1618) : !memref_smem_bf16_10
            %1619 = cute.static : !cute.layout<"(1):(2)">
            %idx_2680 = cute.crd2idx(%coord_2673, %1614) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
            %ptr_2681 = cute.add_offset(%iter_2670, %idx_2680) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_2682 = cute.make_view(%ptr_2681, %1619) : !memref_rmem_i8_4
            %iter_2683 = cute.get_iter(%view_2676) : !memref_gmem_bf16_8
            %iter_2684 = cute.get_iter(%view_2679) : !memref_smem_bf16_10
            %iter_2685 = cute.get_iter(%view_2682) : !memref_rmem_i8_4
            %1620 = builtin.unrealized_conversion_cast %iter_2685 : !cute.ptr<i8, rmem> to !llvm.ptr
            %1621 = llvm.load %1620 : !llvm.ptr -> i8
            %1622 = llvm.trunc %1621 : i8 to i1
            %iter_2686 = cute.recast_iter(%iter_2683) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_2687 = cute.recast_iter(%iter_2684) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_2687 : !cute.ptr<i128, smem>, %iter_2686 : !cute.ptr<i128, gmem>, %1622 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        } else {
          %1606 = cute.static : !cute.int_tuple<"3072">
          %iter_2644 = cute.get_iter(%view_179) : !memref_smem_bf16_4
          %ptr_2645 = cute.add_offset(%iter_2644, %1606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2646 = cute.make_view(%ptr_2645) : !memref_smem_bf16_11
          %cst_2647 = arith.constant 0.000000e+00 : bf16
          %1607 = vector.splat %cst_2647 : vector<16xbf16>
          cute.memref.store_vec %1607, %view_2646 : !memref_smem_bf16_11
        }
      } else {
        %coord_2576 = cute.make_coord(%363) : (i32) -> !cute.coord<"(_,_,_,?)">
        %lay_2577 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
        %1582:3 = cute.get_scalars(%lay_2577) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %1583 = cute.static : !cute.shape<"((8,1),4,2)">
        %iv_2578 = cute.assume(%1582#1) : (i64) -> !cute.i64<divby 128>
        %stride_2579 = cute.make_stride(%iv_2578) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
        %lay_2580 = cute.make_layout(%1583, %stride_2579) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %idx_2581 = cute.crd2idx(%coord_2576, %lay_2577) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %iter_2582 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583, %lay_2580) : !memref_gmem_bf16_9
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_9
        %lay_2586 = cute.get_layout(%view_2584) : !memref_gmem_bf16_9
        %1584 = cute.static : !cute.layout<"1:0">
        %append_2587 = cute.append_to_rank<2> (%lay_2586, %1584) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
        %view_2588 = cute.make_view(%iter_2585, %append_2587) : !memref_gmem_bf16_9
        %iter_2589 = cute.get_iter(%view_2588) : !memref_gmem_bf16_9
        %lay_2590 = cute.get_layout(%view_2588) : !memref_gmem_bf16_9
        %1585 = cute.get_scalars(%lay_2590) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %1586 = cute.static : !cute.shape<"((8,1),(4,2))">
        %iv_2591 = cute.assume(%1585) : (i64) -> !cute.i64<divby 128>
        %stride_2592 = cute.make_stride(%iv_2591) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
        %lay_2593 = cute.make_layout(%1586, %stride_2592) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
        %view_2594 = cute.make_view(%iter_2589, %lay_2593) : !memref_gmem_bf16_10
        %1587 = cute.static : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
        %view_2595 = cute.make_view(%iter_180, %1587) : !memref_smem_bf16_4
        %iter_2596 = cute.get_iter(%view_2595) : !memref_smem_bf16_4
        %view_2597 = cute.make_view(%iter_2596) : !memref_smem_bf16_13
        %1588 = cute.static : !cute.layout<"(1,4,2):(2,0,1)">
        %view_2598 = cute.make_view(%iter_351, %1588) : !memref_rmem_i8_1
        %iter_2599 = cute.get_iter(%view_2598) : !memref_rmem_i8_1
        %view_2600 = cute.make_view(%iter_2599) : !memref_rmem_i8_5
        %1589 = cute.static : !cute.layout<"1:0">
        %iter_2601 = cute.get_iter(%view_2594) : !memref_gmem_bf16_10
        %iter_2602 = cute.get_iter(%view_2597) : !memref_smem_bf16_13
        %lay_2603 = cute.get_layout(%view_2594) : !memref_gmem_bf16_10
        %append_2604 = cute.append_to_rank<2> (%lay_2603, %1589) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
        %1590 = cute.get_scalars(%append_2604) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
        %1591 = cute.static : !cute.shape<"((8,1),((4,2)))">
        %iv_2605 = cute.assume(%1590) : (i64) -> !cute.i64<divby 128>
        %stride_2606 = cute.make_stride(%iv_2605) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
        %lay_2607 = cute.make_layout(%1591, %stride_2606) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
        %1592 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
        %iter_2608 = cute.get_iter(%view_2600) : !memref_rmem_i8_5
        %1593 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
        %1594 = cute.static : !cute.int_tuple<"8">
        %1595 = cute.get_scalars(%1594) : !cute.int_tuple<"8">
        %c0_i32_2609 = arith.constant 0 : i32
        %c1_i32_2610 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2609 to %1595 step %c1_i32_2610  : i32 {
          %coord_2611 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1596 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2612 = cute.crd2idx(%coord_2611, %lay_2607) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
          %ptr_2613 = cute.add_offset(%iter_2601, %idx_2612) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2614 = cute.make_view(%ptr_2613, %1596) : !memref_gmem_bf16_8
          %1597 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2615 = cute.crd2idx(%coord_2611, %1592) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_2616 = cute.add_offset(%iter_2602, %idx_2615) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2617 = cute.make_view(%ptr_2616, %1597) : !memref_smem_bf16_10
          %1598 = cute.static : !cute.layout<"(1):(2)">
          %idx_2618 = cute.crd2idx(%coord_2611, %1593) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_2619 = cute.add_offset(%iter_2608, %idx_2618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2620 = cute.make_view(%ptr_2619, %1598) : !memref_rmem_i8_4
          %iter_2621 = cute.get_iter(%view_2614) : !memref_gmem_bf16_8
          %iter_2622 = cute.get_iter(%view_2617) : !memref_smem_bf16_10
          %iter_2623 = cute.get_iter(%view_2620) : !memref_rmem_i8_4
          %1599 = builtin.unrealized_conversion_cast %iter_2623 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1600 = llvm.load %1599 : !llvm.ptr -> i8
          %1601 = llvm.trunc %1600 : i8 to i1
          %iter_2624 = cute.recast_iter(%iter_2621) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2625 = cute.recast_iter(%iter_2622) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2625 : !cute.ptr<i128, smem>, %iter_2624 : !cute.ptr<i128, gmem>, %1601 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %366 = cute.static : !cute.int_tuple<"0">
      %iter_634 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_635 = cute.add_offset(%iter_634, %366) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_636 = cute.make_view(%ptr_635) : !memref_smem_bf16_11
      %iter_637 = cute.get_iter(%view_636) : !memref_smem_bf16_11
      %367 = cute.static : !cute.int_tuple<"0">
      %iter_638 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_639 = cute.add_offset(%iter_638, %367) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_640 = cute.make_view(%ptr_639) : !memref_rmem_bf16_6
      %iter_641 = cute.get_iter(%view_640) : !memref_rmem_bf16_6
      %368 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_642 = cute.make_view(%iter_637, %368) : !memref_smem_bf16_11
      %iter_643 = cute.get_iter(%view_642) : !memref_smem_bf16_11
      %view_644 = cute.make_view(%iter_643) : !memref_smem_bf16_12
      %369 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_645 = cute.make_view(%iter_641, %369) : !memref_rmem_bf16_6
      %iter_646 = cute.get_iter(%view_645) : !memref_rmem_bf16_6
      %view_647 = cute.make_view(%iter_646) : !memref_rmem_bf16_7
      %370 = cute.static : !cute.layout<"1:0">
      %iter_648 = cute.get_iter(%view_644) : !memref_smem_bf16_12
      %iter_649 = cute.get_iter(%view_647) : !memref_rmem_bf16_7
      %371 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %372 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %373 = cute.static : !cute.int_tuple<"2">
      %374 = cute.get_scalars(%373) : !cute.int_tuple<"2">
      %c0_i32_650 = arith.constant 0 : i32
      %c1_i32_651 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_650 to %374 step %c1_i32_651  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %371) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_648, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %372) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_649, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %375 = cute.static : !cute.int_tuple<"0">
      %iter_652 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_653 = cute.add_offset(%iter_652, %375) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_654 = cute.make_view(%ptr_653) : !memref_smem_bf16_14
      %iter_655 = cute.get_iter(%view_654) : !memref_smem_bf16_14
      %376 = cute.static : !cute.int_tuple<"0">
      %iter_656 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_657 = cute.add_offset(%iter_656, %376) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_658 = cute.make_view(%ptr_657) : !memref_rmem_bf16_9
      %iter_659 = cute.get_iter(%view_658) : !memref_rmem_bf16_9
      %377 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_660 = cute.make_view(%iter_655, %377) : !memref_smem_bf16_14
      %iter_661 = cute.get_iter(%view_660) : !memref_smem_bf16_14
      %view_662 = cute.make_view(%iter_661) : !memref_smem_bf16_15
      %378 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_663 = cute.make_view(%iter_659, %378) : !memref_rmem_bf16_9
      %iter_664 = cute.get_iter(%view_663) : !memref_rmem_bf16_9
      %view_665 = cute.make_view(%iter_664) : !memref_rmem_bf16_10
      %379 = cute.static : !cute.layout<"1:0">
      %iter_666 = cute.get_iter(%view_662) : !memref_smem_bf16_15
      %iter_667 = cute.get_iter(%view_665) : !memref_rmem_bf16_10
      %380 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %381 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %382 = cute.static : !cute.int_tuple<"4">
      %383 = cute.get_scalars(%382) : !cute.int_tuple<"4">
      %c0_i32_668 = arith.constant 0 : i32
      %c1_i32_669 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_668 to %383 step %c1_i32_669  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %380) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_666, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %381) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_667, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %384 = cute.static : !cute.coord<"(_,_,1)">
      %lay_670 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_671 = cute.crd2idx(%384, %lay_670) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %iter_672 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_673 = cute.add_offset(%iter_672, %idx_671) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_674 = cute.make_view(%ptr_673) : !memref_smem_bf16_11
      %iter_675 = cute.get_iter(%view_674) : !memref_smem_bf16_11
      %385 = cute.static : !cute.int_tuple<"32">
      %iter_676 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_677 = cute.add_offset(%iter_676, %385) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_678 = cute.make_view(%ptr_677) : !memref_rmem_bf16_6
      %iter_679 = cute.get_iter(%view_678) : !memref_rmem_bf16_6
      %386 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_680 = cute.make_view(%iter_675, %386) : !memref_smem_bf16_11
      %iter_681 = cute.get_iter(%view_680) : !memref_smem_bf16_11
      %view_682 = cute.make_view(%iter_681) : !memref_smem_bf16_12
      %387 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_683 = cute.make_view(%iter_679, %387) : !memref_rmem_bf16_6
      %iter_684 = cute.get_iter(%view_683) : !memref_rmem_bf16_6
      %view_685 = cute.make_view(%iter_684) : !memref_rmem_bf16_7
      %388 = cute.static : !cute.layout<"1:0">
      %iter_686 = cute.get_iter(%view_682) : !memref_smem_bf16_12
      %iter_687 = cute.get_iter(%view_685) : !memref_rmem_bf16_7
      %389 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %390 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %391 = cute.static : !cute.int_tuple<"2">
      %392 = cute.get_scalars(%391) : !cute.int_tuple<"2">
      %c0_i32_688 = arith.constant 0 : i32
      %c1_i32_689 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_688 to %392 step %c1_i32_689  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %389) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_686, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %390) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_687, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %393 = cute.static : !cute.coord<"(_,_,1)">
      %lay_690 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_691 = cute.crd2idx(%393, %lay_690) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %iter_692 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_693 = cute.add_offset(%iter_692, %idx_691) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_694 = cute.make_view(%ptr_693) : !memref_smem_bf16_14
      %iter_695 = cute.get_iter(%view_694) : !memref_smem_bf16_14
      %394 = cute.static : !cute.int_tuple<"64">
      %iter_696 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_697 = cute.add_offset(%iter_696, %394) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_698 = cute.make_view(%ptr_697) : !memref_rmem_bf16_9
      %iter_699 = cute.get_iter(%view_698) : !memref_rmem_bf16_9
      %395 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_700 = cute.make_view(%iter_695, %395) : !memref_smem_bf16_14
      %iter_701 = cute.get_iter(%view_700) : !memref_smem_bf16_14
      %view_702 = cute.make_view(%iter_701) : !memref_smem_bf16_15
      %396 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_703 = cute.make_view(%iter_699, %396) : !memref_rmem_bf16_9
      %iter_704 = cute.get_iter(%view_703) : !memref_rmem_bf16_9
      %view_705 = cute.make_view(%iter_704) : !memref_rmem_bf16_10
      %397 = cute.static : !cute.layout<"1:0">
      %iter_706 = cute.get_iter(%view_702) : !memref_smem_bf16_15
      %iter_707 = cute.get_iter(%view_705) : !memref_rmem_bf16_10
      %398 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %399 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %400 = cute.static : !cute.int_tuple<"4">
      %401 = cute.get_scalars(%400) : !cute.int_tuple<"4">
      %c0_i32_708 = arith.constant 0 : i32
      %c1_i32_709 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_708 to %401 step %c1_i32_709  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %398) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_706, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %399) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_707, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %402 = cute.static : !cute.int_tuple<"0">
      %iter_710 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_711 = cute.add_offset(%iter_710, %402) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_712 = cute.make_view(%ptr_711) : !memref_rmem_bf16_12
      %403 = cute.static : !cute.int_tuple<"0">
      %iter_713 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_714 = cute.add_offset(%iter_713, %403) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_715 = cute.make_view(%ptr_714) : !memref_rmem_bf16_13
      %iter_716 = cute.get_iter(%view_712) : !memref_rmem_bf16_12
      %iter_717 = cute.get_iter(%view_715) : !memref_rmem_bf16_13
      %iter_718 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %404 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %405 = cute.static : !cute.layout<"1:0">
      %406 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %407 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %408 = cute.static : !cute.int_tuple<"1">
      %409 = cute.static : !cute.int_tuple<"2">
      %410 = cute.static : !cute.int_tuple<"8">
      %411 = cute.get_scalars(%408) : !cute.int_tuple<"1">
      %412 = cute.get_scalars(%409) : !cute.int_tuple<"2">
      %413 = cute.get_scalars(%410) : !cute.int_tuple<"8">
      %c0_i32_719 = arith.constant 0 : i32
      %c1_i32_720 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_719 to %411 step %c1_i32_720  : i32 {
        scf.for %arg6 = %c0_i32_719 to %412 step %c1_i32_720  : i32 {
          scf.for %arg7 = %c0_i32_719 to %413 step %c1_i32_720  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %406) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_716, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %407) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_717, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %404) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_718, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %414 = cute.static : !cute.coord<"(_,_,2)">
      %lay_721 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_722 = cute.crd2idx(%414, %lay_721) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %iter_723 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_724 = cute.add_offset(%iter_723, %idx_722) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_725 = cute.make_view(%ptr_724) : !memref_smem_bf16_11
      %iter_726 = cute.get_iter(%view_725) : !memref_smem_bf16_11
      %415 = cute.static : !cute.int_tuple<"64">
      %iter_727 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_728 = cute.add_offset(%iter_727, %415) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_729 = cute.make_view(%ptr_728) : !memref_rmem_bf16_6
      %iter_730 = cute.get_iter(%view_729) : !memref_rmem_bf16_6
      %416 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_731 = cute.make_view(%iter_726, %416) : !memref_smem_bf16_11
      %iter_732 = cute.get_iter(%view_731) : !memref_smem_bf16_11
      %view_733 = cute.make_view(%iter_732) : !memref_smem_bf16_12
      %417 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_734 = cute.make_view(%iter_730, %417) : !memref_rmem_bf16_6
      %iter_735 = cute.get_iter(%view_734) : !memref_rmem_bf16_6
      %view_736 = cute.make_view(%iter_735) : !memref_rmem_bf16_7
      %418 = cute.static : !cute.layout<"1:0">
      %iter_737 = cute.get_iter(%view_733) : !memref_smem_bf16_12
      %iter_738 = cute.get_iter(%view_736) : !memref_rmem_bf16_7
      %419 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %420 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %421 = cute.static : !cute.int_tuple<"2">
      %422 = cute.get_scalars(%421) : !cute.int_tuple<"2">
      %c0_i32_739 = arith.constant 0 : i32
      %c1_i32_740 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_739 to %422 step %c1_i32_740  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %419) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_737, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %420) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_738, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %423 = cute.static : !cute.coord<"(_,_,2)">
      %lay_741 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_742 = cute.crd2idx(%423, %lay_741) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %iter_743 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_744 = cute.add_offset(%iter_743, %idx_742) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_745 = cute.make_view(%ptr_744) : !memref_smem_bf16_14
      %iter_746 = cute.get_iter(%view_745) : !memref_smem_bf16_14
      %424 = cute.static : !cute.int_tuple<"128">
      %iter_747 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_748 = cute.add_offset(%iter_747, %424) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_749 = cute.make_view(%ptr_748) : !memref_rmem_bf16_9
      %iter_750 = cute.get_iter(%view_749) : !memref_rmem_bf16_9
      %425 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_751 = cute.make_view(%iter_746, %425) : !memref_smem_bf16_14
      %iter_752 = cute.get_iter(%view_751) : !memref_smem_bf16_14
      %view_753 = cute.make_view(%iter_752) : !memref_smem_bf16_15
      %426 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_754 = cute.make_view(%iter_750, %426) : !memref_rmem_bf16_9
      %iter_755 = cute.get_iter(%view_754) : !memref_rmem_bf16_9
      %view_756 = cute.make_view(%iter_755) : !memref_rmem_bf16_10
      %427 = cute.static : !cute.layout<"1:0">
      %iter_757 = cute.get_iter(%view_753) : !memref_smem_bf16_15
      %iter_758 = cute.get_iter(%view_756) : !memref_rmem_bf16_10
      %428 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %429 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %430 = cute.static : !cute.int_tuple<"4">
      %431 = cute.get_scalars(%430) : !cute.int_tuple<"4">
      %c0_i32_759 = arith.constant 0 : i32
      %c1_i32_760 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_759 to %431 step %c1_i32_760  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %428) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_757, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %429) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_758, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %432 = cute.static : !cute.int_tuple<"32">
      %iter_761 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_762 = cute.add_offset(%iter_761, %432) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_763 = cute.make_view(%ptr_762) : !memref_rmem_bf16_12
      %433 = cute.static : !cute.int_tuple<"64">
      %iter_764 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_765 = cute.add_offset(%iter_764, %433) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_766 = cute.make_view(%ptr_765) : !memref_rmem_bf16_13
      %iter_767 = cute.get_iter(%view_763) : !memref_rmem_bf16_12
      %iter_768 = cute.get_iter(%view_766) : !memref_rmem_bf16_13
      %iter_769 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %434 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %435 = cute.static : !cute.layout<"1:0">
      %436 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %437 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %438 = cute.static : !cute.int_tuple<"1">
      %439 = cute.static : !cute.int_tuple<"2">
      %440 = cute.static : !cute.int_tuple<"8">
      %441 = cute.get_scalars(%438) : !cute.int_tuple<"1">
      %442 = cute.get_scalars(%439) : !cute.int_tuple<"2">
      %443 = cute.get_scalars(%440) : !cute.int_tuple<"8">
      %c0_i32_770 = arith.constant 0 : i32
      %c1_i32_771 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_770 to %441 step %c1_i32_771  : i32 {
        scf.for %arg6 = %c0_i32_770 to %442 step %c1_i32_771  : i32 {
          scf.for %arg7 = %c0_i32_770 to %443 step %c1_i32_771  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %436) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_767, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %437) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_768, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %434) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_769, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %444 = cute.static : !cute.coord<"(_,_,3)">
      %lay_772 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_773 = cute.crd2idx(%444, %lay_772) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %iter_774 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_775 = cute.add_offset(%iter_774, %idx_773) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_776 = cute.make_view(%ptr_775) : !memref_smem_bf16_11
      %iter_777 = cute.get_iter(%view_776) : !memref_smem_bf16_11
      %445 = cute.static : !cute.int_tuple<"96">
      %iter_778 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_779 = cute.add_offset(%iter_778, %445) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_780 = cute.make_view(%ptr_779) : !memref_rmem_bf16_6
      %iter_781 = cute.get_iter(%view_780) : !memref_rmem_bf16_6
      %446 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_782 = cute.make_view(%iter_777, %446) : !memref_smem_bf16_11
      %iter_783 = cute.get_iter(%view_782) : !memref_smem_bf16_11
      %view_784 = cute.make_view(%iter_783) : !memref_smem_bf16_12
      %447 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_785 = cute.make_view(%iter_781, %447) : !memref_rmem_bf16_6
      %iter_786 = cute.get_iter(%view_785) : !memref_rmem_bf16_6
      %view_787 = cute.make_view(%iter_786) : !memref_rmem_bf16_7
      %448 = cute.static : !cute.layout<"1:0">
      %iter_788 = cute.get_iter(%view_784) : !memref_smem_bf16_12
      %iter_789 = cute.get_iter(%view_787) : !memref_rmem_bf16_7
      %449 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %450 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %451 = cute.static : !cute.int_tuple<"2">
      %452 = cute.get_scalars(%451) : !cute.int_tuple<"2">
      %c0_i32_790 = arith.constant 0 : i32
      %c1_i32_791 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_790 to %452 step %c1_i32_791  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %449) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_788, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %450) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_789, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %453 = cute.static : !cute.coord<"(_,_,3)">
      %lay_792 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_793 = cute.crd2idx(%453, %lay_792) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %iter_794 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_795 = cute.add_offset(%iter_794, %idx_793) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_796 = cute.make_view(%ptr_795) : !memref_smem_bf16_14
      %iter_797 = cute.get_iter(%view_796) : !memref_smem_bf16_14
      %454 = cute.static : !cute.int_tuple<"192">
      %iter_798 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_799 = cute.add_offset(%iter_798, %454) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_800 = cute.make_view(%ptr_799) : !memref_rmem_bf16_9
      %iter_801 = cute.get_iter(%view_800) : !memref_rmem_bf16_9
      %455 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_802 = cute.make_view(%iter_797, %455) : !memref_smem_bf16_14
      %iter_803 = cute.get_iter(%view_802) : !memref_smem_bf16_14
      %view_804 = cute.make_view(%iter_803) : !memref_smem_bf16_15
      %456 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_805 = cute.make_view(%iter_801, %456) : !memref_rmem_bf16_9
      %iter_806 = cute.get_iter(%view_805) : !memref_rmem_bf16_9
      %view_807 = cute.make_view(%iter_806) : !memref_rmem_bf16_10
      %457 = cute.static : !cute.layout<"1:0">
      %iter_808 = cute.get_iter(%view_804) : !memref_smem_bf16_15
      %iter_809 = cute.get_iter(%view_807) : !memref_rmem_bf16_10
      %458 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %459 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %460 = cute.static : !cute.int_tuple<"4">
      %461 = cute.get_scalars(%460) : !cute.int_tuple<"4">
      %c0_i32_810 = arith.constant 0 : i32
      %c1_i32_811 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_810 to %461 step %c1_i32_811  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %458) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_808, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %459) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_809, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %462 = cute.static : !cute.int_tuple<"64">
      %iter_812 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_813 = cute.add_offset(%iter_812, %462) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_814 = cute.make_view(%ptr_813) : !memref_rmem_bf16_12
      %463 = cute.static : !cute.int_tuple<"128">
      %iter_815 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_816 = cute.add_offset(%iter_815, %463) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_817 = cute.make_view(%ptr_816) : !memref_rmem_bf16_13
      %iter_818 = cute.get_iter(%view_814) : !memref_rmem_bf16_12
      %iter_819 = cute.get_iter(%view_817) : !memref_rmem_bf16_13
      %iter_820 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %464 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %465 = cute.static : !cute.layout<"1:0">
      %466 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %467 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %468 = cute.static : !cute.int_tuple<"1">
      %469 = cute.static : !cute.int_tuple<"2">
      %470 = cute.static : !cute.int_tuple<"8">
      %471 = cute.get_scalars(%468) : !cute.int_tuple<"1">
      %472 = cute.get_scalars(%469) : !cute.int_tuple<"2">
      %473 = cute.get_scalars(%470) : !cute.int_tuple<"8">
      %c0_i32_821 = arith.constant 0 : i32
      %c1_i32_822 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_821 to %471 step %c1_i32_822  : i32 {
        scf.for %arg6 = %c0_i32_821 to %472 step %c1_i32_822  : i32 {
          scf.for %arg7 = %c0_i32_821 to %473 step %c1_i32_822  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %466) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_818, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %467) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_819, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %464) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_820, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %474 = cute.static : !cute.int_tuple<"8192">
      %iter_823 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_824 = cute.add_offset(%iter_823, %474) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
      %view_825 = cute.make_view(%ptr_824) : !memref_smem_bf16_11
      %iter_826 = cute.get_iter(%view_825) : !memref_smem_bf16_11
      %475 = cute.static : !cute.int_tuple<"16">
      %iter_827 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_828 = cute.add_offset(%iter_827, %475) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_829 = cute.make_view(%ptr_828) : !memref_rmem_bf16_6
      %iter_830 = cute.get_iter(%view_829) : !memref_rmem_bf16_6
      %476 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_831 = cute.make_view(%iter_826, %476) : !memref_smem_bf16_11
      %iter_832 = cute.get_iter(%view_831) : !memref_smem_bf16_11
      %view_833 = cute.make_view(%iter_832) : !memref_smem_bf16_12
      %477 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_834 = cute.make_view(%iter_830, %477) : !memref_rmem_bf16_6
      %iter_835 = cute.get_iter(%view_834) : !memref_rmem_bf16_6
      %view_836 = cute.make_view(%iter_835) : !memref_rmem_bf16_7
      %478 = cute.static : !cute.layout<"1:0">
      %iter_837 = cute.get_iter(%view_833) : !memref_smem_bf16_12
      %iter_838 = cute.get_iter(%view_836) : !memref_rmem_bf16_7
      %479 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %480 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %481 = cute.static : !cute.int_tuple<"2">
      %482 = cute.get_scalars(%481) : !cute.int_tuple<"2">
      %c0_i32_839 = arith.constant 0 : i32
      %c1_i32_840 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_839 to %482 step %c1_i32_840  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %479) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_837, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %480) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_838, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %483 = cute.static : !cute.int_tuple<"4096">
      %iter_841 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_842 = cute.add_offset(%iter_841, %483) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %view_843 = cute.make_view(%ptr_842) : !memref_smem_bf16_14
      %iter_844 = cute.get_iter(%view_843) : !memref_smem_bf16_14
      %484 = cute.static : !cute.int_tuple<"32">
      %iter_845 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_846 = cute.add_offset(%iter_845, %484) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_847 = cute.make_view(%ptr_846) : !memref_rmem_bf16_9
      %iter_848 = cute.get_iter(%view_847) : !memref_rmem_bf16_9
      %485 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_849 = cute.make_view(%iter_844, %485) : !memref_smem_bf16_14
      %iter_850 = cute.get_iter(%view_849) : !memref_smem_bf16_14
      %view_851 = cute.make_view(%iter_850) : !memref_smem_bf16_15
      %486 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_852 = cute.make_view(%iter_848, %486) : !memref_rmem_bf16_9
      %iter_853 = cute.get_iter(%view_852) : !memref_rmem_bf16_9
      %view_854 = cute.make_view(%iter_853) : !memref_rmem_bf16_10
      %487 = cute.static : !cute.layout<"1:0">
      %iter_855 = cute.get_iter(%view_851) : !memref_smem_bf16_15
      %iter_856 = cute.get_iter(%view_854) : !memref_rmem_bf16_10
      %488 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %489 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %490 = cute.static : !cute.int_tuple<"4">
      %491 = cute.get_scalars(%490) : !cute.int_tuple<"4">
      %c0_i32_857 = arith.constant 0 : i32
      %c1_i32_858 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_857 to %491 step %c1_i32_858  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %488) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_855, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %489) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_856, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %492 = cute.static : !cute.int_tuple<"96">
      %iter_859 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_860 = cute.add_offset(%iter_859, %492) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_861 = cute.make_view(%ptr_860) : !memref_rmem_bf16_12
      %493 = cute.static : !cute.int_tuple<"192">
      %iter_862 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_863 = cute.add_offset(%iter_862, %493) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_864 = cute.make_view(%ptr_863) : !memref_rmem_bf16_13
      %iter_865 = cute.get_iter(%view_861) : !memref_rmem_bf16_12
      %iter_866 = cute.get_iter(%view_864) : !memref_rmem_bf16_13
      %iter_867 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %494 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %495 = cute.static : !cute.layout<"1:0">
      %496 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %497 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %498 = cute.static : !cute.int_tuple<"1">
      %499 = cute.static : !cute.int_tuple<"2">
      %500 = cute.static : !cute.int_tuple<"8">
      %501 = cute.get_scalars(%498) : !cute.int_tuple<"1">
      %502 = cute.get_scalars(%499) : !cute.int_tuple<"2">
      %503 = cute.get_scalars(%500) : !cute.int_tuple<"8">
      %c0_i32_868 = arith.constant 0 : i32
      %c1_i32_869 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_868 to %501 step %c1_i32_869  : i32 {
        scf.for %arg6 = %c0_i32_868 to %502 step %c1_i32_869  : i32 {
          scf.for %arg7 = %c0_i32_868 to %503 step %c1_i32_869  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %496) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_865, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %497) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_866, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %494) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_867, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %504 = cute.static : !cute.coord<"(_,_,5)">
      %lay_870 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_871 = cute.crd2idx(%504, %lay_870) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %iter_872 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_873 = cute.add_offset(%iter_872, %idx_871) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_874 = cute.make_view(%ptr_873) : !memref_smem_bf16_11
      %iter_875 = cute.get_iter(%view_874) : !memref_smem_bf16_11
      %505 = cute.static : !cute.int_tuple<"48">
      %iter_876 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_877 = cute.add_offset(%iter_876, %505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_878 = cute.make_view(%ptr_877) : !memref_rmem_bf16_6
      %iter_879 = cute.get_iter(%view_878) : !memref_rmem_bf16_6
      %506 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_880 = cute.make_view(%iter_875, %506) : !memref_smem_bf16_11
      %iter_881 = cute.get_iter(%view_880) : !memref_smem_bf16_11
      %view_882 = cute.make_view(%iter_881) : !memref_smem_bf16_12
      %507 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_883 = cute.make_view(%iter_879, %507) : !memref_rmem_bf16_6
      %iter_884 = cute.get_iter(%view_883) : !memref_rmem_bf16_6
      %view_885 = cute.make_view(%iter_884) : !memref_rmem_bf16_7
      %508 = cute.static : !cute.layout<"1:0">
      %iter_886 = cute.get_iter(%view_882) : !memref_smem_bf16_12
      %iter_887 = cute.get_iter(%view_885) : !memref_rmem_bf16_7
      %509 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %510 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %511 = cute.static : !cute.int_tuple<"2">
      %512 = cute.get_scalars(%511) : !cute.int_tuple<"2">
      %c0_i32_888 = arith.constant 0 : i32
      %c1_i32_889 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_888 to %512 step %c1_i32_889  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %509) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_886, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %510) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_887, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %513 = cute.static : !cute.coord<"(_,_,5)">
      %lay_890 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_891 = cute.crd2idx(%513, %lay_890) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %iter_892 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_893 = cute.add_offset(%iter_892, %idx_891) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_894 = cute.make_view(%ptr_893) : !memref_smem_bf16_14
      %iter_895 = cute.get_iter(%view_894) : !memref_smem_bf16_14
      %514 = cute.static : !cute.int_tuple<"96">
      %iter_896 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_897 = cute.add_offset(%iter_896, %514) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_898 = cute.make_view(%ptr_897) : !memref_rmem_bf16_9
      %iter_899 = cute.get_iter(%view_898) : !memref_rmem_bf16_9
      %515 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_900 = cute.make_view(%iter_895, %515) : !memref_smem_bf16_14
      %iter_901 = cute.get_iter(%view_900) : !memref_smem_bf16_14
      %view_902 = cute.make_view(%iter_901) : !memref_smem_bf16_15
      %516 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_903 = cute.make_view(%iter_899, %516) : !memref_rmem_bf16_9
      %iter_904 = cute.get_iter(%view_903) : !memref_rmem_bf16_9
      %view_905 = cute.make_view(%iter_904) : !memref_rmem_bf16_10
      %517 = cute.static : !cute.layout<"1:0">
      %iter_906 = cute.get_iter(%view_902) : !memref_smem_bf16_15
      %iter_907 = cute.get_iter(%view_905) : !memref_rmem_bf16_10
      %518 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %519 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %520 = cute.static : !cute.int_tuple<"4">
      %521 = cute.get_scalars(%520) : !cute.int_tuple<"4">
      %c0_i32_908 = arith.constant 0 : i32
      %c1_i32_909 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_908 to %521 step %c1_i32_909  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %518) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_906, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %519) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_907, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %522 = cute.static : !cute.int_tuple<"16">
      %iter_910 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_911 = cute.add_offset(%iter_910, %522) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_912 = cute.make_view(%ptr_911) : !memref_rmem_bf16_12
      %523 = cute.static : !cute.int_tuple<"32">
      %iter_913 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_914 = cute.add_offset(%iter_913, %523) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_915 = cute.make_view(%ptr_914) : !memref_rmem_bf16_13
      %iter_916 = cute.get_iter(%view_912) : !memref_rmem_bf16_12
      %iter_917 = cute.get_iter(%view_915) : !memref_rmem_bf16_13
      %iter_918 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %524 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %525 = cute.static : !cute.layout<"1:0">
      %526 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %527 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %528 = cute.static : !cute.int_tuple<"1">
      %529 = cute.static : !cute.int_tuple<"2">
      %530 = cute.static : !cute.int_tuple<"8">
      %531 = cute.get_scalars(%528) : !cute.int_tuple<"1">
      %532 = cute.get_scalars(%529) : !cute.int_tuple<"2">
      %533 = cute.get_scalars(%530) : !cute.int_tuple<"8">
      %c0_i32_919 = arith.constant 0 : i32
      %c1_i32_920 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_919 to %531 step %c1_i32_920  : i32 {
        scf.for %arg6 = %c0_i32_919 to %532 step %c1_i32_920  : i32 {
          scf.for %arg7 = %c0_i32_919 to %533 step %c1_i32_920  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %526) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_916, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %527) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_917, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %524) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_918, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %534 = cute.static : !cute.coord<"(_,_,6)">
      %lay_921 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_922 = cute.crd2idx(%534, %lay_921) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %iter_923 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_924 = cute.add_offset(%iter_923, %idx_922) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_925 = cute.make_view(%ptr_924) : !memref_smem_bf16_11
      %iter_926 = cute.get_iter(%view_925) : !memref_smem_bf16_11
      %535 = cute.static : !cute.int_tuple<"80">
      %iter_927 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_928 = cute.add_offset(%iter_927, %535) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_929 = cute.make_view(%ptr_928) : !memref_rmem_bf16_6
      %iter_930 = cute.get_iter(%view_929) : !memref_rmem_bf16_6
      %536 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_931 = cute.make_view(%iter_926, %536) : !memref_smem_bf16_11
      %iter_932 = cute.get_iter(%view_931) : !memref_smem_bf16_11
      %view_933 = cute.make_view(%iter_932) : !memref_smem_bf16_12
      %537 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_934 = cute.make_view(%iter_930, %537) : !memref_rmem_bf16_6
      %iter_935 = cute.get_iter(%view_934) : !memref_rmem_bf16_6
      %view_936 = cute.make_view(%iter_935) : !memref_rmem_bf16_7
      %538 = cute.static : !cute.layout<"1:0">
      %iter_937 = cute.get_iter(%view_933) : !memref_smem_bf16_12
      %iter_938 = cute.get_iter(%view_936) : !memref_rmem_bf16_7
      %539 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %540 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %541 = cute.static : !cute.int_tuple<"2">
      %542 = cute.get_scalars(%541) : !cute.int_tuple<"2">
      %c0_i32_939 = arith.constant 0 : i32
      %c1_i32_940 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_939 to %542 step %c1_i32_940  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %539) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_937, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %540) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_938, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %543 = cute.static : !cute.coord<"(_,_,6)">
      %lay_941 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_942 = cute.crd2idx(%543, %lay_941) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %iter_943 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_944 = cute.add_offset(%iter_943, %idx_942) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_945 = cute.make_view(%ptr_944) : !memref_smem_bf16_14
      %iter_946 = cute.get_iter(%view_945) : !memref_smem_bf16_14
      %544 = cute.static : !cute.int_tuple<"160">
      %iter_947 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_948 = cute.add_offset(%iter_947, %544) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_949 = cute.make_view(%ptr_948) : !memref_rmem_bf16_9
      %iter_950 = cute.get_iter(%view_949) : !memref_rmem_bf16_9
      %545 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_951 = cute.make_view(%iter_946, %545) : !memref_smem_bf16_14
      %iter_952 = cute.get_iter(%view_951) : !memref_smem_bf16_14
      %view_953 = cute.make_view(%iter_952) : !memref_smem_bf16_15
      %546 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_954 = cute.make_view(%iter_950, %546) : !memref_rmem_bf16_9
      %iter_955 = cute.get_iter(%view_954) : !memref_rmem_bf16_9
      %view_956 = cute.make_view(%iter_955) : !memref_rmem_bf16_10
      %547 = cute.static : !cute.layout<"1:0">
      %iter_957 = cute.get_iter(%view_953) : !memref_smem_bf16_15
      %iter_958 = cute.get_iter(%view_956) : !memref_rmem_bf16_10
      %548 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %549 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %550 = cute.static : !cute.int_tuple<"4">
      %551 = cute.get_scalars(%550) : !cute.int_tuple<"4">
      %c0_i32_959 = arith.constant 0 : i32
      %c1_i32_960 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_959 to %551 step %c1_i32_960  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %548) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_957, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %549) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_958, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %552 = cute.static : !cute.int_tuple<"48">
      %iter_961 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_962 = cute.add_offset(%iter_961, %552) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_963 = cute.make_view(%ptr_962) : !memref_rmem_bf16_12
      %553 = cute.static : !cute.int_tuple<"96">
      %iter_964 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_965 = cute.add_offset(%iter_964, %553) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_966 = cute.make_view(%ptr_965) : !memref_rmem_bf16_13
      %iter_967 = cute.get_iter(%view_963) : !memref_rmem_bf16_12
      %iter_968 = cute.get_iter(%view_966) : !memref_rmem_bf16_13
      %iter_969 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %554 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %555 = cute.static : !cute.layout<"1:0">
      %556 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %557 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %558 = cute.static : !cute.int_tuple<"1">
      %559 = cute.static : !cute.int_tuple<"2">
      %560 = cute.static : !cute.int_tuple<"8">
      %561 = cute.get_scalars(%558) : !cute.int_tuple<"1">
      %562 = cute.get_scalars(%559) : !cute.int_tuple<"2">
      %563 = cute.get_scalars(%560) : !cute.int_tuple<"8">
      %c0_i32_970 = arith.constant 0 : i32
      %c1_i32_971 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_970 to %561 step %c1_i32_971  : i32 {
        scf.for %arg6 = %c0_i32_970 to %562 step %c1_i32_971  : i32 {
          scf.for %arg7 = %c0_i32_970 to %563 step %c1_i32_971  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %556) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_967, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %557) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_968, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %554) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_969, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %564 = cute.static : !cute.coord<"(_,_,7)">
      %lay_972 = cute.get_layout(%view_211) : !memref_smem_bf16_5
      %idx_973 = cute.crd2idx(%564, %lay_972) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %iter_974 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_975 = cute.add_offset(%iter_974, %idx_973) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_976 = cute.make_view(%ptr_975) : !memref_smem_bf16_11
      %iter_977 = cute.get_iter(%view_976) : !memref_smem_bf16_11
      %565 = cute.static : !cute.int_tuple<"112">
      %iter_978 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_979 = cute.add_offset(%iter_978, %565) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_980 = cute.make_view(%ptr_979) : !memref_rmem_bf16_6
      %iter_981 = cute.get_iter(%view_980) : !memref_rmem_bf16_6
      %566 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_982 = cute.make_view(%iter_977, %566) : !memref_smem_bf16_11
      %iter_983 = cute.get_iter(%view_982) : !memref_smem_bf16_11
      %view_984 = cute.make_view(%iter_983) : !memref_smem_bf16_12
      %567 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_985 = cute.make_view(%iter_981, %567) : !memref_rmem_bf16_6
      %iter_986 = cute.get_iter(%view_985) : !memref_rmem_bf16_6
      %view_987 = cute.make_view(%iter_986) : !memref_rmem_bf16_7
      %568 = cute.static : !cute.layout<"1:0">
      %iter_988 = cute.get_iter(%view_984) : !memref_smem_bf16_12
      %iter_989 = cute.get_iter(%view_987) : !memref_rmem_bf16_7
      %569 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %570 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %571 = cute.static : !cute.int_tuple<"2">
      %572 = cute.get_scalars(%571) : !cute.int_tuple<"2">
      %c0_i32_990 = arith.constant 0 : i32
      %c1_i32_991 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_990 to %572 step %c1_i32_991  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %569) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_988, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %570) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_989, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %573 = cute.static : !cute.coord<"(_,_,7)">
      %lay_992 = cute.get_layout(%view_239) : !memref_smem_bf16_6
      %idx_993 = cute.crd2idx(%573, %lay_992) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %iter_994 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_995 = cute.add_offset(%iter_994, %idx_993) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_996 = cute.make_view(%ptr_995) : !memref_smem_bf16_14
      %iter_997 = cute.get_iter(%view_996) : !memref_smem_bf16_14
      %574 = cute.static : !cute.int_tuple<"224">
      %iter_998 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_999 = cute.add_offset(%iter_998, %574) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1000 = cute.make_view(%ptr_999) : !memref_rmem_bf16_9
      %iter_1001 = cute.get_iter(%view_1000) : !memref_rmem_bf16_9
      %575 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_1002 = cute.make_view(%iter_997, %575) : !memref_smem_bf16_14
      %iter_1003 = cute.get_iter(%view_1002) : !memref_smem_bf16_14
      %view_1004 = cute.make_view(%iter_1003) : !memref_smem_bf16_15
      %576 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_1005 = cute.make_view(%iter_1001, %576) : !memref_rmem_bf16_9
      %iter_1006 = cute.get_iter(%view_1005) : !memref_rmem_bf16_9
      %view_1007 = cute.make_view(%iter_1006) : !memref_rmem_bf16_10
      %577 = cute.static : !cute.layout<"1:0">
      %iter_1008 = cute.get_iter(%view_1004) : !memref_smem_bf16_15
      %iter_1009 = cute.get_iter(%view_1007) : !memref_rmem_bf16_10
      %578 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %579 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %580 = cute.static : !cute.int_tuple<"4">
      %581 = cute.get_scalars(%580) : !cute.int_tuple<"4">
      %c0_i32_1010 = arith.constant 0 : i32
      %c1_i32_1011 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1010 to %581 step %c1_i32_1011  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %578) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_1008, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %579) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_1009, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %582 = cute.static : !cute.int_tuple<"80">
      %iter_1012 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_1013 = cute.add_offset(%iter_1012, %582) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_1014 = cute.make_view(%ptr_1013) : !memref_rmem_bf16_12
      %583 = cute.static : !cute.int_tuple<"160">
      %iter_1015 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_1016 = cute.add_offset(%iter_1015, %583) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1017 = cute.make_view(%ptr_1016) : !memref_rmem_bf16_13
      %iter_1018 = cute.get_iter(%view_1014) : !memref_rmem_bf16_12
      %iter_1019 = cute.get_iter(%view_1017) : !memref_rmem_bf16_13
      %iter_1020 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %584 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %585 = cute.static : !cute.layout<"1:0">
      %586 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %587 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %588 = cute.static : !cute.int_tuple<"1">
      %589 = cute.static : !cute.int_tuple<"2">
      %590 = cute.static : !cute.int_tuple<"8">
      %591 = cute.get_scalars(%588) : !cute.int_tuple<"1">
      %592 = cute.get_scalars(%589) : !cute.int_tuple<"2">
      %593 = cute.get_scalars(%590) : !cute.int_tuple<"8">
      %c0_i32_1021 = arith.constant 0 : i32
      %c1_i32_1022 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1021 to %591 step %c1_i32_1022  : i32 {
        scf.for %arg6 = %c0_i32_1021 to %592 step %c1_i32_1022  : i32 {
          scf.for %arg7 = %c0_i32_1021 to %593 step %c1_i32_1022  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %586) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_1018, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %587) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_1019, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %584) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_1020, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %594 = cute.static : !cute.int_tuple<"0">
      %iter_1023 = cute.get_iter(%view_211) : !memref_smem_bf16_5
      %ptr_1024 = cute.add_offset(%iter_1023, %594) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_1025 = cute.make_view(%ptr_1024) : !memref_smem_bf16_11
      %iter_1026 = cute.get_iter(%view_1025) : !memref_smem_bf16_11
      %595 = cute.static : !cute.int_tuple<"0">
      %iter_1027 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
      %ptr_1028 = cute.add_offset(%iter_1027, %595) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_1029 = cute.make_view(%ptr_1028) : !memref_rmem_bf16_6
      %iter_1030 = cute.get_iter(%view_1029) : !memref_rmem_bf16_6
      %596 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
      %view_1031 = cute.make_view(%iter_1026, %596) : !memref_smem_bf16_11
      %iter_1032 = cute.get_iter(%view_1031) : !memref_smem_bf16_11
      %view_1033 = cute.make_view(%iter_1032) : !memref_smem_bf16_12
      %597 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
      %view_1034 = cute.make_view(%iter_1030, %597) : !memref_rmem_bf16_6
      %iter_1035 = cute.get_iter(%view_1034) : !memref_rmem_bf16_6
      %view_1036 = cute.make_view(%iter_1035) : !memref_rmem_bf16_7
      %598 = cute.static : !cute.layout<"1:0">
      %iter_1037 = cute.get_iter(%view_1033) : !memref_smem_bf16_12
      %iter_1038 = cute.get_iter(%view_1036) : !memref_rmem_bf16_7
      %599 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %600 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %601 = cute.static : !cute.int_tuple<"2">
      %602 = cute.get_scalars(%601) : !cute.int_tuple<"2">
      %c0_i32_1039 = arith.constant 0 : i32
      %c1_i32_1040 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1039 to %602 step %c1_i32_1040  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %599) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
        %ptr_2578 = cute.add_offset(%iter_1037, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %600) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_1038, %idx_2580) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %603 = cute.static : !cute.int_tuple<"0">
      %iter_1041 = cute.get_iter(%view_239) : !memref_smem_bf16_6
      %ptr_1042 = cute.add_offset(%iter_1041, %603) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_1043 = cute.make_view(%ptr_1042) : !memref_smem_bf16_14
      %iter_1044 = cute.get_iter(%view_1043) : !memref_smem_bf16_14
      %604 = cute.static : !cute.int_tuple<"0">
      %iter_1045 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
      %ptr_1046 = cute.add_offset(%iter_1045, %604) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1047 = cute.make_view(%ptr_1046) : !memref_rmem_bf16_9
      %iter_1048 = cute.get_iter(%view_1047) : !memref_rmem_bf16_9
      %605 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
      %view_1049 = cute.make_view(%iter_1044, %605) : !memref_smem_bf16_14
      %iter_1050 = cute.get_iter(%view_1049) : !memref_smem_bf16_14
      %view_1051 = cute.make_view(%iter_1050) : !memref_smem_bf16_15
      %606 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
      %view_1052 = cute.make_view(%iter_1048, %606) : !memref_rmem_bf16_9
      %iter_1053 = cute.get_iter(%view_1052) : !memref_rmem_bf16_9
      %view_1054 = cute.make_view(%iter_1053) : !memref_rmem_bf16_10
      %607 = cute.static : !cute.layout<"1:0">
      %iter_1055 = cute.get_iter(%view_1051) : !memref_smem_bf16_15
      %iter_1056 = cute.get_iter(%view_1054) : !memref_rmem_bf16_10
      %608 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %609 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %610 = cute.static : !cute.int_tuple<"4">
      %611 = cute.get_scalars(%610) : !cute.int_tuple<"4">
      %c0_i32_1057 = arith.constant 0 : i32
      %c1_i32_1058 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1057 to %611 step %c1_i32_1058  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %608) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_1055, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %609) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_1056, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %612 = cute.static : !cute.int_tuple<"112">
      %iter_1059 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %ptr_1060 = cute.add_offset(%iter_1059, %612) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
      %view_1061 = cute.make_view(%ptr_1060) : !memref_rmem_bf16_12
      %613 = cute.static : !cute.int_tuple<"224">
      %iter_1062 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
      %ptr_1063 = cute.add_offset(%iter_1062, %613) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1064 = cute.make_view(%ptr_1063) : !memref_rmem_bf16_13
      %iter_1065 = cute.get_iter(%view_1061) : !memref_rmem_bf16_12
      %iter_1066 = cute.get_iter(%view_1064) : !memref_rmem_bf16_13
      %iter_1067 = cute.get_iter(%rmem_628) : !memref_rmem_f32_2
      %614 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %615 = cute.static : !cute.layout<"1:0">
      %616 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %617 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %618 = cute.static : !cute.int_tuple<"1">
      %619 = cute.static : !cute.int_tuple<"2">
      %620 = cute.static : !cute.int_tuple<"8">
      %621 = cute.get_scalars(%618) : !cute.int_tuple<"1">
      %622 = cute.get_scalars(%619) : !cute.int_tuple<"2">
      %623 = cute.get_scalars(%620) : !cute.int_tuple<"8">
      %c0_i32_1068 = arith.constant 0 : i32
      %c1_i32_1069 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1068 to %621 step %c1_i32_1069  : i32 {
        scf.for %arg6 = %c0_i32_1068 to %622 step %c1_i32_1069  : i32 {
          scf.for %arg7 = %c0_i32_1068 to %623 step %c1_i32_1069  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
            %idx_2579 = cute.crd2idx(%coord_2576, %616) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
            %ptr_2580 = cute.add_offset(%iter_1065, %idx_2579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_14
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %617) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_1066, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %614) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_1067, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_14
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[2] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[3] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %c1_i32_1070 = arith.constant 1 : i32
      %c128_i32_1071 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_1070 number_of_threads = %c128_i32_1071
      %624 = arith.cmpi sgt, %363, %c0_i32_627 : i32
      scf.if %624 {
        %c1_i32_2576 = arith.constant 1 : i32
        %1582 = arith.subi %363, %c1_i32_2576 : i32
        %coord_2577 = cute.make_coord(%1582) : (i32) -> !cute.coord<"(_,_,_,?)">
        %lay_2578 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
        %1583:3 = cute.get_scalars(%lay_2578) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %1584 = cute.static : !cute.shape<"((8,1),4,2)">
        %iv_2579 = cute.assume(%1583#1) : (i64) -> !cute.i64<divby 128>
        %stride_2580 = cute.make_stride(%iv_2579) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
        %lay_2581 = cute.make_layout(%1584, %stride_2580) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %idx_2582 = cute.crd2idx(%coord_2577, %lay_2578) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %iter_2583 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
        %ptr_2584 = cute.add_offset(%iter_2583, %idx_2582) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584, %lay_2581) : !memref_gmem_bf16_9
        %iter_2586 = cute.get_iter(%view_2585) : !memref_gmem_bf16_9
        %lay_2587 = cute.get_layout(%view_2585) : !memref_gmem_bf16_9
        %1585 = cute.static : !cute.layout<"1:0">
        %append_2588 = cute.append_to_rank<2> (%lay_2587, %1585) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
        %view_2589 = cute.make_view(%iter_2586, %append_2588) : !memref_gmem_bf16_9
        %iter_2590 = cute.get_iter(%view_2589) : !memref_gmem_bf16_9
        %lay_2591 = cute.get_layout(%view_2589) : !memref_gmem_bf16_9
        %1586 = cute.get_scalars(%lay_2591) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %1587 = cute.static : !cute.shape<"((8,1),(4,2))">
        %iv_2592 = cute.assume(%1586) : (i64) -> !cute.i64<divby 128>
        %stride_2593 = cute.make_stride(%iv_2592) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
        %lay_2594 = cute.make_layout(%1587, %stride_2593) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
        %view_2595 = cute.make_view(%iter_2590, %lay_2594) : !memref_gmem_bf16_10
        %1588 = cute.static : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
        %view_2596 = cute.make_view(%iter_146, %1588) : !memref_smem_bf16_4
        %iter_2597 = cute.get_iter(%view_2596) : !memref_smem_bf16_4
        %view_2598 = cute.make_view(%iter_2597) : !memref_smem_bf16_13
        %1589 = cute.static : !cute.layout<"(1,4,2):(2,0,1)">
        %view_2599 = cute.make_view(%iter_351, %1589) : !memref_rmem_i8_1
        %iter_2600 = cute.get_iter(%view_2599) : !memref_rmem_i8_1
        %view_2601 = cute.make_view(%iter_2600) : !memref_rmem_i8_5
        %1590 = cute.static : !cute.layout<"1:0">
        %iter_2602 = cute.get_iter(%view_2595) : !memref_gmem_bf16_10
        %iter_2603 = cute.get_iter(%view_2598) : !memref_smem_bf16_13
        %lay_2604 = cute.get_layout(%view_2595) : !memref_gmem_bf16_10
        %append_2605 = cute.append_to_rank<2> (%lay_2604, %1590) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
        %1591 = cute.get_scalars(%append_2605) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
        %1592 = cute.static : !cute.shape<"((8,1),((4,2)))">
        %iv_2606 = cute.assume(%1591) : (i64) -> !cute.i64<divby 128>
        %stride_2607 = cute.make_stride(%iv_2606) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
        %lay_2608 = cute.make_layout(%1592, %stride_2607) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
        %1593 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
        %iter_2609 = cute.get_iter(%view_2601) : !memref_rmem_i8_5
        %1594 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
        %1595 = cute.static : !cute.int_tuple<"8">
        %1596 = cute.get_scalars(%1595) : !cute.int_tuple<"8">
        %c0_i32_2610 = arith.constant 0 : i32
        %c1_i32_2611 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2610 to %1596 step %c1_i32_2611  : i32 {
          %coord_2612 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1597 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2613 = cute.crd2idx(%coord_2612, %lay_2608) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
          %ptr_2614 = cute.add_offset(%iter_2602, %idx_2613) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2615 = cute.make_view(%ptr_2614, %1597) : !memref_gmem_bf16_8
          %1598 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2616 = cute.crd2idx(%coord_2612, %1593) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_2617 = cute.add_offset(%iter_2603, %idx_2616) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_2618 = cute.make_view(%ptr_2617, %1598) : !memref_smem_bf16_10
          %1599 = cute.static : !cute.layout<"(1):(2)">
          %idx_2619 = cute.crd2idx(%coord_2612, %1594) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_2620 = cute.add_offset(%iter_2609, %idx_2619) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2621 = cute.make_view(%ptr_2620, %1599) : !memref_rmem_i8_4
          %iter_2622 = cute.get_iter(%view_2615) : !memref_gmem_bf16_8
          %iter_2623 = cute.get_iter(%view_2618) : !memref_smem_bf16_10
          %iter_2624 = cute.get_iter(%view_2621) : !memref_rmem_i8_4
          %1600 = builtin.unrealized_conversion_cast %iter_2624 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1601 = llvm.load %1600 : !llvm.ptr -> i8
          %1602 = llvm.trunc %1601 : i8 to i1
          %iter_2625 = cute.recast_iter(%iter_2622) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_2626 = cute.recast_iter(%iter_2623) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_2626 : !cute.ptr<i128, smem>, %iter_2625 : !cute.ptr<i128, gmem>, %1602 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.commit.group
      }
      %625 = cute.static : !cute.layout<"((2,2),(2,8)):((2,4),(1,8))">
      %view_1072 = cute.make_view(%iter_629, %625) : !memref_rmem_f32_4
      %lay_1073 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %626 = cute.get_shape(%lay_1073) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1074, %e1_1075, %e2_1076, %e3_1077 = cute.get_leaves(%626) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1078 = cute.to_int_tuple(%e0_1074) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1079 = cute.to_int_tuple(%e1_1075) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1080 = cute.to_int_tuple(%e2_1076) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %lay_1081 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %627 = cute.get_shape(%lay_1081) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1082, %e1_1083, %e2_1084, %e3_1085 = cute.get_leaves(%627) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1086 = cute.to_int_tuple(%e1_1083) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_1087 = cute.make_shape(%itup_1078, %itup_1079, %itup_1080, %itup_1086) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?)">
      %628 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %629 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %lay_1088 = cute.make_layout(%shape_1087, %629) : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %view_1089 = cute.make_view(%628, %lay_1088) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %coord_1090 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_1091 = cute.get_layout(%view_1089) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %630:4 = cute.get_scalars(%lay_1091) <{only_dynamic}> : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %shape_1092 = cute.make_shape(%630#1, %630#3) : (i32, i32) -> !cute.shape<"(?,?)">
      %631 = cute.static : !cute.stride<"(1@1,1@3)">
      %lay_1093 = cute.make_layout(%shape_1092, %631) : !cute.layout<"(?,?):(1@1,1@3)">
      %idx_1094 = cute.crd2idx(%coord_1090, %lay_1091) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %632 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %tup_1095 = cute.add_offset(%632, %idx_1094) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %view_1096 = cute.make_view(%tup_1095, %lay_1093) : !cute.coord_tensor<"(?,0,?,0)", "(?,?):(1@1,1@3)">
      %coord_1097 = cute.make_coord(%24, %363) : (i32, i32) -> !cute.coord<"(?,?)">
      %633:2 = cute.get_scalars(%coord_1097) <{only_dynamic}> : !cute.coord<"(?,?)">
      %coord_1098 = cute.make_coord(%633#0, %633#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_1099 = cute.get_layout(%view_1096) : !cute.coord_tensor<"(?,0,?,0)", "(?,?):(1@1,1@3)">
      %634:2 = cute.get_scalars(%lay_1099) <{only_dynamic}> : !cute.layout<"(?,?):(1@1,1@3)">
      %c128_i32_1100 = arith.constant 128 : i32
      %635 = arith.ceildivsi %634#0, %c128_i32_1100 : i32
      %c64_i32_1101 = arith.constant 64 : i32
      %636 = arith.ceildivsi %634#1, %c64_i32_1101 : i32
      %shape_1102 = cute.make_shape(%635, %636) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %637 = cute.static : !cute.stride<"((1@1,1@3),(128@1,64@3))">
      %lay_1103 = cute.make_layout(%shape_1102, %637) : !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">
      %idx_1104 = cute.crd2idx(%coord_1098, %lay_1103) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">) -> !cute.int_tuple<"(0,?{div=128},0,?{div=64})">
      %iter_1105 = cute.get_iter(%view_1096) : !cute.coord_tensor<"(?,0,?,0)", "(?,?):(1@1,1@3)">
      %tup_1106 = cute.add_offset(%iter_1105, %idx_1104) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,?{div=64})">) -> !cute.int_tuple<"(?,?{div=128},?,?{div=64})">
      %view_1107 = cute.make_view(%tup_1106) : !cute.coord_tensor<"(?,?{div=128},?,?{div=64})", "(128,64):(1@1,1@3)">
      %coord_1108 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_1109 = cute.get_iter(%view_1107) : !cute.coord_tensor<"(?,?{div=128},?,?{div=64})", "(128,64):(1@1,1@3)">
      %638 = cute.get_scalars(%coord_1108) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32 = arith.constant 32 : i32
      %639 = arith.remsi %638, %c32_i32 : i32
      %c32_i32_1110 = arith.constant 32 : i32
      %640 = arith.divsi %638, %c32_i32_1110 : i32
      %c4_i32 = arith.constant 4 : i32
      %641 = arith.remsi %640, %c4_i32 : i32
      %c32_i32_1111 = arith.constant 32 : i32
      %642 = arith.remsi %639, %c32_i32_1111 : i32
      %c4_i32_1112 = arith.constant 4 : i32
      %643 = arith.remsi %641, %c4_i32_1112 : i32
      %c4_i32_1113 = arith.constant 4 : i32
      %644 = arith.divsi %642, %c4_i32_1113 : i32
      %c4_i32_1114 = arith.constant 4 : i32
      %645 = arith.remsi %642, %c4_i32_1114 : i32
      %c2_i32_1115 = arith.constant 2 : i32
      %646 = arith.muli %645, %c2_i32_1115 : i32
      %c16_i32_1116 = arith.constant 16 : i32
      %647 = arith.muli %643, %c16_i32_1116 : i32
      %648 = arith.addi %644, %647 : i32
      %iv_1117 = cute.assume(%646) : (i32) -> !cute.i32<divby 2>
      %int_tuple_1118 = cute.make_int_tuple(%648, %iv_1117) : (i32, !cute.i32<divby 2>) -> !cute.int_tuple<"(0,?,0,?{div=2})">
      %tup_1119 = cute.add_offset(%iter_1109, %int_tuple_1118) : (!cute.int_tuple<"(?,?{div=128},?,?{div=64})">, !cute.int_tuple<"(0,?,0,?{div=2})">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1120 = cute.make_view(%tup_1119) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),2,8):((1@3,8@1),64@1,8@3)">
      %iter_1121 = cute.get_iter(%view_1120) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),2,8):((1@3,8@1),64@1,8@3)">
      %e0_1122, %e1_1123, %e2_1124, %e3_1125 = cute.get_leaves(%iter_1121) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %649 = cute.static : !cute.layout<"((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %int_tuple_1126 = cute.make_int_tuple(%e0_1122, %e1_1123, %e2_1124, %e3_1125) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1127 = cute.make_view(%int_tuple_1126, %649) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %650 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_1128 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1129 = cute.add_offset(%iter_1128, %650) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1130 = cute.make_view(%tup_1129) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1131 = cute.get_iter(%view_1130) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1132, %e1_1133, %e2_1134, %e3_1135 = cute.get_leaves(%iter_1131) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %651 = cute.static : !cute.int_tuple<"1">
      %tup_1136 = cute.add_offset(%e3_1135, %651) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1137 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1138 = cute.make_coord(%tup_1136) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %652 = cute.get_scalars(%coord_1137) : !cute.coord<"?">
      %653 = cute.get_scalars(%coord_1138) : !cute.coord<"?">
      %true_1139 = arith.constant true
      %654 = arith.cmpi slt, %652, %653 : i32
      %655 = arith.andi %true_1139, %654 : i1
      %656 = scf.if %655 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,0)">
        cute.memref.store(%view_1072, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,0)">, f32) -> ()
        scf.yield %view_1072 : !memref_rmem_f32_4
      } else {
        scf.yield %view_1072 : !memref_rmem_f32_4
      }
      %657 = cute.static : !cute.int_tuple<"(0,0,0,1)">
      %iter_1140 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1141 = cute.add_offset(%iter_1140, %657) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1142 = cute.make_view(%tup_1141) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1143 = cute.get_iter(%view_1142) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1144, %e1_1145, %e2_1146, %e3_1147 = cute.get_leaves(%iter_1143) : !cute.int_tuple<"(?,?,?,?)">
      %658 = cute.static : !cute.int_tuple<"1">
      %tup_1148 = cute.add_offset(%e3_1147, %658) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1149 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1150 = cute.make_coord(%tup_1148) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %659 = cute.get_scalars(%coord_1149) : !cute.coord<"?">
      %660 = cute.get_scalars(%coord_1150) : !cute.coord<"?">
      %true_1151 = arith.constant true
      %661 = arith.cmpi slt, %659, %660 : i32
      %662 = arith.andi %true_1151, %661 : i1
      %663 = scf.if %662 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,1)">
        cute.memref.store(%656, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,1)">, f32) -> ()
        scf.yield %656 : !memref_rmem_f32_4
      } else {
        scf.yield %656 : !memref_rmem_f32_4
      }
      %664 = cute.static : !cute.int_tuple<"(0,0,0,8)">
      %iter_1152 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1153 = cute.add_offset(%iter_1152, %664) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1154 = cute.make_view(%tup_1153) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1155 = cute.get_iter(%view_1154) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1156, %e1_1157, %e2_1158, %e3_1159 = cute.get_leaves(%iter_1155) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %665 = cute.static : !cute.int_tuple<"1">
      %tup_1160 = cute.add_offset(%e3_1159, %665) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1161 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1162 = cute.make_coord(%tup_1160) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %666 = cute.get_scalars(%coord_1161) : !cute.coord<"?">
      %667 = cute.get_scalars(%coord_1162) : !cute.coord<"?">
      %true_1163 = arith.constant true
      %668 = arith.cmpi slt, %666, %667 : i32
      %669 = arith.andi %true_1163, %668 : i1
      %670 = scf.if %669 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,2)">
        cute.memref.store(%663, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,2)">, f32) -> ()
        scf.yield %663 : !memref_rmem_f32_4
      } else {
        scf.yield %663 : !memref_rmem_f32_4
      }
      %671 = cute.static : !cute.int_tuple<"(0,0,0,9)">
      %iter_1164 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1165 = cute.add_offset(%iter_1164, %671) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1166 = cute.make_view(%tup_1165) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1167 = cute.get_iter(%view_1166) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1168, %e1_1169, %e2_1170, %e3_1171 = cute.get_leaves(%iter_1167) : !cute.int_tuple<"(?,?,?,?)">
      %672 = cute.static : !cute.int_tuple<"1">
      %tup_1172 = cute.add_offset(%e3_1171, %672) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1173 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1174 = cute.make_coord(%tup_1172) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %673 = cute.get_scalars(%coord_1173) : !cute.coord<"?">
      %674 = cute.get_scalars(%coord_1174) : !cute.coord<"?">
      %true_1175 = arith.constant true
      %675 = arith.cmpi slt, %673, %674 : i32
      %676 = arith.andi %true_1175, %675 : i1
      %677 = scf.if %676 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,3)">
        cute.memref.store(%670, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,3)">, f32) -> ()
        scf.yield %670 : !memref_rmem_f32_4
      } else {
        scf.yield %670 : !memref_rmem_f32_4
      }
      %678 = cute.static : !cute.int_tuple<"(0,0,0,16)">
      %iter_1176 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1177 = cute.add_offset(%iter_1176, %678) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1178 = cute.make_view(%tup_1177) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1179 = cute.get_iter(%view_1178) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1180, %e1_1181, %e2_1182, %e3_1183 = cute.get_leaves(%iter_1179) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %679 = cute.static : !cute.int_tuple<"1">
      %tup_1184 = cute.add_offset(%e3_1183, %679) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1185 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1186 = cute.make_coord(%tup_1184) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %680 = cute.get_scalars(%coord_1185) : !cute.coord<"?">
      %681 = cute.get_scalars(%coord_1186) : !cute.coord<"?">
      %true_1187 = arith.constant true
      %682 = arith.cmpi slt, %680, %681 : i32
      %683 = arith.andi %true_1187, %682 : i1
      %684 = scf.if %683 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,4)">
        cute.memref.store(%677, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,4)">, f32) -> ()
        scf.yield %677 : !memref_rmem_f32_4
      } else {
        scf.yield %677 : !memref_rmem_f32_4
      }
      %685 = cute.static : !cute.int_tuple<"(0,0,0,17)">
      %iter_1188 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1189 = cute.add_offset(%iter_1188, %685) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1190 = cute.make_view(%tup_1189) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1191 = cute.get_iter(%view_1190) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1192, %e1_1193, %e2_1194, %e3_1195 = cute.get_leaves(%iter_1191) : !cute.int_tuple<"(?,?,?,?)">
      %686 = cute.static : !cute.int_tuple<"1">
      %tup_1196 = cute.add_offset(%e3_1195, %686) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1197 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1198 = cute.make_coord(%tup_1196) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %687 = cute.get_scalars(%coord_1197) : !cute.coord<"?">
      %688 = cute.get_scalars(%coord_1198) : !cute.coord<"?">
      %true_1199 = arith.constant true
      %689 = arith.cmpi slt, %687, %688 : i32
      %690 = arith.andi %true_1199, %689 : i1
      %691 = scf.if %690 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,5)">
        cute.memref.store(%684, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,5)">, f32) -> ()
        scf.yield %684 : !memref_rmem_f32_4
      } else {
        scf.yield %684 : !memref_rmem_f32_4
      }
      %692 = cute.static : !cute.int_tuple<"(0,0,0,24)">
      %iter_1200 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1201 = cute.add_offset(%iter_1200, %692) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1202 = cute.make_view(%tup_1201) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1203 = cute.get_iter(%view_1202) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1204, %e1_1205, %e2_1206, %e3_1207 = cute.get_leaves(%iter_1203) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %693 = cute.static : !cute.int_tuple<"1">
      %tup_1208 = cute.add_offset(%e3_1207, %693) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1209 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1210 = cute.make_coord(%tup_1208) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %694 = cute.get_scalars(%coord_1209) : !cute.coord<"?">
      %695 = cute.get_scalars(%coord_1210) : !cute.coord<"?">
      %true_1211 = arith.constant true
      %696 = arith.cmpi slt, %694, %695 : i32
      %697 = arith.andi %true_1211, %696 : i1
      %698 = scf.if %697 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,6)">
        cute.memref.store(%691, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,6)">, f32) -> ()
        scf.yield %691 : !memref_rmem_f32_4
      } else {
        scf.yield %691 : !memref_rmem_f32_4
      }
      %699 = cute.static : !cute.int_tuple<"(0,0,0,25)">
      %iter_1212 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1213 = cute.add_offset(%iter_1212, %699) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1214 = cute.make_view(%tup_1213) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1215 = cute.get_iter(%view_1214) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1216, %e1_1217, %e2_1218, %e3_1219 = cute.get_leaves(%iter_1215) : !cute.int_tuple<"(?,?,?,?)">
      %700 = cute.static : !cute.int_tuple<"1">
      %tup_1220 = cute.add_offset(%e3_1219, %700) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1221 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1222 = cute.make_coord(%tup_1220) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %701 = cute.get_scalars(%coord_1221) : !cute.coord<"?">
      %702 = cute.get_scalars(%coord_1222) : !cute.coord<"?">
      %true_1223 = arith.constant true
      %703 = arith.cmpi slt, %701, %702 : i32
      %704 = arith.andi %true_1223, %703 : i1
      %705 = scf.if %704 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,7)">
        cute.memref.store(%698, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,7)">, f32) -> ()
        scf.yield %698 : !memref_rmem_f32_4
      } else {
        scf.yield %698 : !memref_rmem_f32_4
      }
      %706 = cute.static : !cute.int_tuple<"(0,0,0,32)">
      %iter_1224 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1225 = cute.add_offset(%iter_1224, %706) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1226 = cute.make_view(%tup_1225) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1227 = cute.get_iter(%view_1226) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1228, %e1_1229, %e2_1230, %e3_1231 = cute.get_leaves(%iter_1227) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %707 = cute.static : !cute.int_tuple<"1">
      %tup_1232 = cute.add_offset(%e3_1231, %707) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1233 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1234 = cute.make_coord(%tup_1232) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %708 = cute.get_scalars(%coord_1233) : !cute.coord<"?">
      %709 = cute.get_scalars(%coord_1234) : !cute.coord<"?">
      %true_1235 = arith.constant true
      %710 = arith.cmpi slt, %708, %709 : i32
      %711 = arith.andi %true_1235, %710 : i1
      %712 = scf.if %711 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,8)">
        cute.memref.store(%705, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,8)">, f32) -> ()
        scf.yield %705 : !memref_rmem_f32_4
      } else {
        scf.yield %705 : !memref_rmem_f32_4
      }
      %713 = cute.static : !cute.int_tuple<"(0,0,0,33)">
      %iter_1236 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1237 = cute.add_offset(%iter_1236, %713) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1238 = cute.make_view(%tup_1237) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1239 = cute.get_iter(%view_1238) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1240, %e1_1241, %e2_1242, %e3_1243 = cute.get_leaves(%iter_1239) : !cute.int_tuple<"(?,?,?,?)">
      %714 = cute.static : !cute.int_tuple<"1">
      %tup_1244 = cute.add_offset(%e3_1243, %714) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1245 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1246 = cute.make_coord(%tup_1244) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %715 = cute.get_scalars(%coord_1245) : !cute.coord<"?">
      %716 = cute.get_scalars(%coord_1246) : !cute.coord<"?">
      %true_1247 = arith.constant true
      %717 = arith.cmpi slt, %715, %716 : i32
      %718 = arith.andi %true_1247, %717 : i1
      %719 = scf.if %718 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,9)">
        cute.memref.store(%712, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,9)">, f32) -> ()
        scf.yield %712 : !memref_rmem_f32_4
      } else {
        scf.yield %712 : !memref_rmem_f32_4
      }
      %720 = cute.static : !cute.int_tuple<"(0,0,0,40)">
      %iter_1248 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1249 = cute.add_offset(%iter_1248, %720) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1250 = cute.make_view(%tup_1249) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1251 = cute.get_iter(%view_1250) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1252, %e1_1253, %e2_1254, %e3_1255 = cute.get_leaves(%iter_1251) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %721 = cute.static : !cute.int_tuple<"1">
      %tup_1256 = cute.add_offset(%e3_1255, %721) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1257 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1258 = cute.make_coord(%tup_1256) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %722 = cute.get_scalars(%coord_1257) : !cute.coord<"?">
      %723 = cute.get_scalars(%coord_1258) : !cute.coord<"?">
      %true_1259 = arith.constant true
      %724 = arith.cmpi slt, %722, %723 : i32
      %725 = arith.andi %true_1259, %724 : i1
      %726 = scf.if %725 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,10)">
        cute.memref.store(%719, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,10)">, f32) -> ()
        scf.yield %719 : !memref_rmem_f32_4
      } else {
        scf.yield %719 : !memref_rmem_f32_4
      }
      %727 = cute.static : !cute.int_tuple<"(0,0,0,41)">
      %iter_1260 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1261 = cute.add_offset(%iter_1260, %727) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1262 = cute.make_view(%tup_1261) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1263 = cute.get_iter(%view_1262) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1264, %e1_1265, %e2_1266, %e3_1267 = cute.get_leaves(%iter_1263) : !cute.int_tuple<"(?,?,?,?)">
      %728 = cute.static : !cute.int_tuple<"1">
      %tup_1268 = cute.add_offset(%e3_1267, %728) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1269 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1270 = cute.make_coord(%tup_1268) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %729 = cute.get_scalars(%coord_1269) : !cute.coord<"?">
      %730 = cute.get_scalars(%coord_1270) : !cute.coord<"?">
      %true_1271 = arith.constant true
      %731 = arith.cmpi slt, %729, %730 : i32
      %732 = arith.andi %true_1271, %731 : i1
      %733 = scf.if %732 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,11)">
        cute.memref.store(%726, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,11)">, f32) -> ()
        scf.yield %726 : !memref_rmem_f32_4
      } else {
        scf.yield %726 : !memref_rmem_f32_4
      }
      %734 = cute.static : !cute.int_tuple<"(0,0,0,48)">
      %iter_1272 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1273 = cute.add_offset(%iter_1272, %734) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1274 = cute.make_view(%tup_1273) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1275 = cute.get_iter(%view_1274) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1276, %e1_1277, %e2_1278, %e3_1279 = cute.get_leaves(%iter_1275) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %735 = cute.static : !cute.int_tuple<"1">
      %tup_1280 = cute.add_offset(%e3_1279, %735) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1281 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1282 = cute.make_coord(%tup_1280) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %736 = cute.get_scalars(%coord_1281) : !cute.coord<"?">
      %737 = cute.get_scalars(%coord_1282) : !cute.coord<"?">
      %true_1283 = arith.constant true
      %738 = arith.cmpi slt, %736, %737 : i32
      %739 = arith.andi %true_1283, %738 : i1
      %740 = scf.if %739 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,12)">
        cute.memref.store(%733, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,12)">, f32) -> ()
        scf.yield %733 : !memref_rmem_f32_4
      } else {
        scf.yield %733 : !memref_rmem_f32_4
      }
      %741 = cute.static : !cute.int_tuple<"(0,0,0,49)">
      %iter_1284 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1285 = cute.add_offset(%iter_1284, %741) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1286 = cute.make_view(%tup_1285) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1287 = cute.get_iter(%view_1286) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1288, %e1_1289, %e2_1290, %e3_1291 = cute.get_leaves(%iter_1287) : !cute.int_tuple<"(?,?,?,?)">
      %742 = cute.static : !cute.int_tuple<"1">
      %tup_1292 = cute.add_offset(%e3_1291, %742) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1293 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1294 = cute.make_coord(%tup_1292) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %743 = cute.get_scalars(%coord_1293) : !cute.coord<"?">
      %744 = cute.get_scalars(%coord_1294) : !cute.coord<"?">
      %true_1295 = arith.constant true
      %745 = arith.cmpi slt, %743, %744 : i32
      %746 = arith.andi %true_1295, %745 : i1
      %747 = scf.if %746 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,13)">
        cute.memref.store(%740, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,13)">, f32) -> ()
        scf.yield %740 : !memref_rmem_f32_4
      } else {
        scf.yield %740 : !memref_rmem_f32_4
      }
      %748 = cute.static : !cute.int_tuple<"(0,0,0,56)">
      %iter_1296 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1297 = cute.add_offset(%iter_1296, %748) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1298 = cute.make_view(%tup_1297) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1299 = cute.get_iter(%view_1298) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1300, %e1_1301, %e2_1302, %e3_1303 = cute.get_leaves(%iter_1299) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %749 = cute.static : !cute.int_tuple<"1">
      %tup_1304 = cute.add_offset(%e3_1303, %749) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1305 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1306 = cute.make_coord(%tup_1304) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %750 = cute.get_scalars(%coord_1305) : !cute.coord<"?">
      %751 = cute.get_scalars(%coord_1306) : !cute.coord<"?">
      %true_1307 = arith.constant true
      %752 = arith.cmpi slt, %750, %751 : i32
      %753 = arith.andi %true_1307, %752 : i1
      %754 = scf.if %753 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,14)">
        cute.memref.store(%747, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,14)">, f32) -> ()
        scf.yield %747 : !memref_rmem_f32_4
      } else {
        scf.yield %747 : !memref_rmem_f32_4
      }
      %755 = cute.static : !cute.int_tuple<"(0,0,0,57)">
      %iter_1308 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1309 = cute.add_offset(%iter_1308, %755) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1310 = cute.make_view(%tup_1309) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1311 = cute.get_iter(%view_1310) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1312, %e1_1313, %e2_1314, %e3_1315 = cute.get_leaves(%iter_1311) : !cute.int_tuple<"(?,?,?,?)">
      %756 = cute.static : !cute.int_tuple<"1">
      %tup_1316 = cute.add_offset(%e3_1315, %756) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1317 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1318 = cute.make_coord(%tup_1316) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %757 = cute.get_scalars(%coord_1317) : !cute.coord<"?">
      %758 = cute.get_scalars(%coord_1318) : !cute.coord<"?">
      %true_1319 = arith.constant true
      %759 = arith.cmpi slt, %757, %758 : i32
      %760 = arith.andi %true_1319, %759 : i1
      %761 = scf.if %760 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(0,15)">
        cute.memref.store(%754, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(0,15)">, f32) -> ()
        scf.yield %754 : !memref_rmem_f32_4
      } else {
        scf.yield %754 : !memref_rmem_f32_4
      }
      %762 = cute.static : !cute.int_tuple<"0">
      %iter_1320 = cute.get_iter(%761) : !memref_rmem_f32_4
      %ptr_1321 = cute.add_offset(%iter_1320, %762) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
      %view_1322 = cute.make_view(%ptr_1321) : !memref_rmem_f32_5
      %763 = cute.memref.load_vec %view_1322 : !memref_rmem_f32_5
      %cst_1323 = arith.constant 0xFF800000 : f32
      %764 = vector.reduction <maximumf>, %763, %cst_1323 : vector<16xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c2_i32_1324 = arith.constant 2 : i32
      %c31_i32 = arith.constant 31 : i32
      %765 = nvvm.shfl.sync  bfly %c-1_i32, %764, %c2_i32_1324, %c31_i32 : f32 -> f32
      %766 = nvvm.fmax %764, %765
      %c-1_i32_1325 = arith.constant -1 : i32
      %c1_i32_1326 = arith.constant 1 : i32
      %c31_i32_1327 = arith.constant 31 : i32
      %767 = nvvm.shfl.sync  bfly %c-1_i32_1325, %766, %c1_i32_1326, %c31_i32_1327 : f32 -> f32
      %768 = nvvm.fmax %766, %767
      %769 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %770 = arith.mulf %763, %769 : vector<16xf32>
      %771 = arith.mulf %768, %arg4 : f32
      %772 = vector.broadcast %771 : f32 to vector<16xf32>
      %773 = arith.subf %770, %772 : vector<16xf32>
      %774 = math.exp2 %773 fastmath<fast> : vector<16xf32>
      %cst_1328 = arith.constant 0.000000e+00 : f32
      %775 = vector.reduction <add>, %774, %cst_1328 : vector<16xf32> into f32
      %776 = cute.static : !cute.coord<"0">
      cute.memref.store(%rmem_623, %776, %768) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      %777 = cute.static : !cute.coord<"0">
      cute.memref.store(%rmem_624, %777, %775) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      %778 = cute.static : !cute.int_tuple<"0">
      %iter_1329 = cute.get_iter(%761) : !memref_rmem_f32_4
      %ptr_1330 = cute.add_offset(%iter_1329, %778) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
      %view_1331 = cute.make_view(%ptr_1330) : !memref_rmem_f32_5
      cute.memref.store_vec %774, %view_1331 : !memref_rmem_f32_5
      %779 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_1332 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1333 = cute.add_offset(%iter_1332, %779) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1334 = cute.make_view(%tup_1333) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1335 = cute.get_iter(%view_1334) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1336, %e1_1337, %e2_1338, %e3_1339 = cute.get_leaves(%iter_1335) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %780 = cute.static : !cute.int_tuple<"1">
      %tup_1340 = cute.add_offset(%e3_1339, %780) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1341 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1342 = cute.make_coord(%tup_1340) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %781 = cute.get_scalars(%coord_1341) : !cute.coord<"?">
      %782 = cute.get_scalars(%coord_1342) : !cute.coord<"?">
      %true_1343 = arith.constant true
      %783 = arith.cmpi slt, %781, %782 : i32
      %784 = arith.andi %true_1343, %783 : i1
      %785 = scf.if %784 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,0)">
        cute.memref.store(%761, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,0)">, f32) -> ()
        scf.yield %761 : !memref_rmem_f32_4
      } else {
        scf.yield %761 : !memref_rmem_f32_4
      }
      %786 = cute.static : !cute.int_tuple<"(0,0,0,1)">
      %iter_1344 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1345 = cute.add_offset(%iter_1344, %786) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1346 = cute.make_view(%tup_1345) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1347 = cute.get_iter(%view_1346) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1348, %e1_1349, %e2_1350, %e3_1351 = cute.get_leaves(%iter_1347) : !cute.int_tuple<"(?,?,?,?)">
      %787 = cute.static : !cute.int_tuple<"1">
      %tup_1352 = cute.add_offset(%e3_1351, %787) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1353 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1354 = cute.make_coord(%tup_1352) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %788 = cute.get_scalars(%coord_1353) : !cute.coord<"?">
      %789 = cute.get_scalars(%coord_1354) : !cute.coord<"?">
      %true_1355 = arith.constant true
      %790 = arith.cmpi slt, %788, %789 : i32
      %791 = arith.andi %true_1355, %790 : i1
      %792 = scf.if %791 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,1)">
        cute.memref.store(%785, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,1)">, f32) -> ()
        scf.yield %785 : !memref_rmem_f32_4
      } else {
        scf.yield %785 : !memref_rmem_f32_4
      }
      %793 = cute.static : !cute.int_tuple<"(0,0,0,8)">
      %iter_1356 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1357 = cute.add_offset(%iter_1356, %793) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1358 = cute.make_view(%tup_1357) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1359 = cute.get_iter(%view_1358) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1360, %e1_1361, %e2_1362, %e3_1363 = cute.get_leaves(%iter_1359) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %794 = cute.static : !cute.int_tuple<"1">
      %tup_1364 = cute.add_offset(%e3_1363, %794) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1365 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1366 = cute.make_coord(%tup_1364) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %795 = cute.get_scalars(%coord_1365) : !cute.coord<"?">
      %796 = cute.get_scalars(%coord_1366) : !cute.coord<"?">
      %true_1367 = arith.constant true
      %797 = arith.cmpi slt, %795, %796 : i32
      %798 = arith.andi %true_1367, %797 : i1
      %799 = scf.if %798 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,2)">
        cute.memref.store(%792, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,2)">, f32) -> ()
        scf.yield %792 : !memref_rmem_f32_4
      } else {
        scf.yield %792 : !memref_rmem_f32_4
      }
      %800 = cute.static : !cute.int_tuple<"(0,0,0,9)">
      %iter_1368 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1369 = cute.add_offset(%iter_1368, %800) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1370 = cute.make_view(%tup_1369) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1371 = cute.get_iter(%view_1370) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1372, %e1_1373, %e2_1374, %e3_1375 = cute.get_leaves(%iter_1371) : !cute.int_tuple<"(?,?,?,?)">
      %801 = cute.static : !cute.int_tuple<"1">
      %tup_1376 = cute.add_offset(%e3_1375, %801) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1377 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1378 = cute.make_coord(%tup_1376) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %802 = cute.get_scalars(%coord_1377) : !cute.coord<"?">
      %803 = cute.get_scalars(%coord_1378) : !cute.coord<"?">
      %true_1379 = arith.constant true
      %804 = arith.cmpi slt, %802, %803 : i32
      %805 = arith.andi %true_1379, %804 : i1
      %806 = scf.if %805 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,3)">
        cute.memref.store(%799, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,3)">, f32) -> ()
        scf.yield %799 : !memref_rmem_f32_4
      } else {
        scf.yield %799 : !memref_rmem_f32_4
      }
      %807 = cute.static : !cute.int_tuple<"(0,0,0,16)">
      %iter_1380 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1381 = cute.add_offset(%iter_1380, %807) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1382 = cute.make_view(%tup_1381) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1383 = cute.get_iter(%view_1382) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1384, %e1_1385, %e2_1386, %e3_1387 = cute.get_leaves(%iter_1383) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %808 = cute.static : !cute.int_tuple<"1">
      %tup_1388 = cute.add_offset(%e3_1387, %808) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1389 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1390 = cute.make_coord(%tup_1388) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %809 = cute.get_scalars(%coord_1389) : !cute.coord<"?">
      %810 = cute.get_scalars(%coord_1390) : !cute.coord<"?">
      %true_1391 = arith.constant true
      %811 = arith.cmpi slt, %809, %810 : i32
      %812 = arith.andi %true_1391, %811 : i1
      %813 = scf.if %812 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,4)">
        cute.memref.store(%806, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,4)">, f32) -> ()
        scf.yield %806 : !memref_rmem_f32_4
      } else {
        scf.yield %806 : !memref_rmem_f32_4
      }
      %814 = cute.static : !cute.int_tuple<"(0,0,0,17)">
      %iter_1392 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1393 = cute.add_offset(%iter_1392, %814) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1394 = cute.make_view(%tup_1393) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1395 = cute.get_iter(%view_1394) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1396, %e1_1397, %e2_1398, %e3_1399 = cute.get_leaves(%iter_1395) : !cute.int_tuple<"(?,?,?,?)">
      %815 = cute.static : !cute.int_tuple<"1">
      %tup_1400 = cute.add_offset(%e3_1399, %815) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1401 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1402 = cute.make_coord(%tup_1400) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %816 = cute.get_scalars(%coord_1401) : !cute.coord<"?">
      %817 = cute.get_scalars(%coord_1402) : !cute.coord<"?">
      %true_1403 = arith.constant true
      %818 = arith.cmpi slt, %816, %817 : i32
      %819 = arith.andi %true_1403, %818 : i1
      %820 = scf.if %819 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,5)">
        cute.memref.store(%813, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,5)">, f32) -> ()
        scf.yield %813 : !memref_rmem_f32_4
      } else {
        scf.yield %813 : !memref_rmem_f32_4
      }
      %821 = cute.static : !cute.int_tuple<"(0,0,0,24)">
      %iter_1404 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1405 = cute.add_offset(%iter_1404, %821) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1406 = cute.make_view(%tup_1405) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1407 = cute.get_iter(%view_1406) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1408, %e1_1409, %e2_1410, %e3_1411 = cute.get_leaves(%iter_1407) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %822 = cute.static : !cute.int_tuple<"1">
      %tup_1412 = cute.add_offset(%e3_1411, %822) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1413 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1414 = cute.make_coord(%tup_1412) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %823 = cute.get_scalars(%coord_1413) : !cute.coord<"?">
      %824 = cute.get_scalars(%coord_1414) : !cute.coord<"?">
      %true_1415 = arith.constant true
      %825 = arith.cmpi slt, %823, %824 : i32
      %826 = arith.andi %true_1415, %825 : i1
      %827 = scf.if %826 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,6)">
        cute.memref.store(%820, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,6)">, f32) -> ()
        scf.yield %820 : !memref_rmem_f32_4
      } else {
        scf.yield %820 : !memref_rmem_f32_4
      }
      %828 = cute.static : !cute.int_tuple<"(0,0,0,25)">
      %iter_1416 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1417 = cute.add_offset(%iter_1416, %828) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1418 = cute.make_view(%tup_1417) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1419 = cute.get_iter(%view_1418) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1420, %e1_1421, %e2_1422, %e3_1423 = cute.get_leaves(%iter_1419) : !cute.int_tuple<"(?,?,?,?)">
      %829 = cute.static : !cute.int_tuple<"1">
      %tup_1424 = cute.add_offset(%e3_1423, %829) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1425 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1426 = cute.make_coord(%tup_1424) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %830 = cute.get_scalars(%coord_1425) : !cute.coord<"?">
      %831 = cute.get_scalars(%coord_1426) : !cute.coord<"?">
      %true_1427 = arith.constant true
      %832 = arith.cmpi slt, %830, %831 : i32
      %833 = arith.andi %true_1427, %832 : i1
      %834 = scf.if %833 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,7)">
        cute.memref.store(%827, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,7)">, f32) -> ()
        scf.yield %827 : !memref_rmem_f32_4
      } else {
        scf.yield %827 : !memref_rmem_f32_4
      }
      %835 = cute.static : !cute.int_tuple<"(0,0,0,32)">
      %iter_1428 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1429 = cute.add_offset(%iter_1428, %835) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1430 = cute.make_view(%tup_1429) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1431 = cute.get_iter(%view_1430) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1432, %e1_1433, %e2_1434, %e3_1435 = cute.get_leaves(%iter_1431) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %836 = cute.static : !cute.int_tuple<"1">
      %tup_1436 = cute.add_offset(%e3_1435, %836) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1437 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1438 = cute.make_coord(%tup_1436) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %837 = cute.get_scalars(%coord_1437) : !cute.coord<"?">
      %838 = cute.get_scalars(%coord_1438) : !cute.coord<"?">
      %true_1439 = arith.constant true
      %839 = arith.cmpi slt, %837, %838 : i32
      %840 = arith.andi %true_1439, %839 : i1
      %841 = scf.if %840 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,8)">
        cute.memref.store(%834, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,8)">, f32) -> ()
        scf.yield %834 : !memref_rmem_f32_4
      } else {
        scf.yield %834 : !memref_rmem_f32_4
      }
      %842 = cute.static : !cute.int_tuple<"(0,0,0,33)">
      %iter_1440 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1441 = cute.add_offset(%iter_1440, %842) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1442 = cute.make_view(%tup_1441) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1443 = cute.get_iter(%view_1442) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1444, %e1_1445, %e2_1446, %e3_1447 = cute.get_leaves(%iter_1443) : !cute.int_tuple<"(?,?,?,?)">
      %843 = cute.static : !cute.int_tuple<"1">
      %tup_1448 = cute.add_offset(%e3_1447, %843) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1449 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1450 = cute.make_coord(%tup_1448) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %844 = cute.get_scalars(%coord_1449) : !cute.coord<"?">
      %845 = cute.get_scalars(%coord_1450) : !cute.coord<"?">
      %true_1451 = arith.constant true
      %846 = arith.cmpi slt, %844, %845 : i32
      %847 = arith.andi %true_1451, %846 : i1
      %848 = scf.if %847 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,9)">
        cute.memref.store(%841, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,9)">, f32) -> ()
        scf.yield %841 : !memref_rmem_f32_4
      } else {
        scf.yield %841 : !memref_rmem_f32_4
      }
      %849 = cute.static : !cute.int_tuple<"(0,0,0,40)">
      %iter_1452 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1453 = cute.add_offset(%iter_1452, %849) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1454 = cute.make_view(%tup_1453) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1455 = cute.get_iter(%view_1454) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1456, %e1_1457, %e2_1458, %e3_1459 = cute.get_leaves(%iter_1455) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %850 = cute.static : !cute.int_tuple<"1">
      %tup_1460 = cute.add_offset(%e3_1459, %850) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1461 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1462 = cute.make_coord(%tup_1460) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %851 = cute.get_scalars(%coord_1461) : !cute.coord<"?">
      %852 = cute.get_scalars(%coord_1462) : !cute.coord<"?">
      %true_1463 = arith.constant true
      %853 = arith.cmpi slt, %851, %852 : i32
      %854 = arith.andi %true_1463, %853 : i1
      %855 = scf.if %854 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,10)">
        cute.memref.store(%848, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,10)">, f32) -> ()
        scf.yield %848 : !memref_rmem_f32_4
      } else {
        scf.yield %848 : !memref_rmem_f32_4
      }
      %856 = cute.static : !cute.int_tuple<"(0,0,0,41)">
      %iter_1464 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1465 = cute.add_offset(%iter_1464, %856) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1466 = cute.make_view(%tup_1465) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1467 = cute.get_iter(%view_1466) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1468, %e1_1469, %e2_1470, %e3_1471 = cute.get_leaves(%iter_1467) : !cute.int_tuple<"(?,?,?,?)">
      %857 = cute.static : !cute.int_tuple<"1">
      %tup_1472 = cute.add_offset(%e3_1471, %857) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1473 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1474 = cute.make_coord(%tup_1472) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %858 = cute.get_scalars(%coord_1473) : !cute.coord<"?">
      %859 = cute.get_scalars(%coord_1474) : !cute.coord<"?">
      %true_1475 = arith.constant true
      %860 = arith.cmpi slt, %858, %859 : i32
      %861 = arith.andi %true_1475, %860 : i1
      %862 = scf.if %861 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,11)">
        cute.memref.store(%855, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,11)">, f32) -> ()
        scf.yield %855 : !memref_rmem_f32_4
      } else {
        scf.yield %855 : !memref_rmem_f32_4
      }
      %863 = cute.static : !cute.int_tuple<"(0,0,0,48)">
      %iter_1476 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1477 = cute.add_offset(%iter_1476, %863) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1478 = cute.make_view(%tup_1477) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1479 = cute.get_iter(%view_1478) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1480, %e1_1481, %e2_1482, %e3_1483 = cute.get_leaves(%iter_1479) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %864 = cute.static : !cute.int_tuple<"1">
      %tup_1484 = cute.add_offset(%e3_1483, %864) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1485 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1486 = cute.make_coord(%tup_1484) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %865 = cute.get_scalars(%coord_1485) : !cute.coord<"?">
      %866 = cute.get_scalars(%coord_1486) : !cute.coord<"?">
      %true_1487 = arith.constant true
      %867 = arith.cmpi slt, %865, %866 : i32
      %868 = arith.andi %true_1487, %867 : i1
      %869 = scf.if %868 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,12)">
        cute.memref.store(%862, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,12)">, f32) -> ()
        scf.yield %862 : !memref_rmem_f32_4
      } else {
        scf.yield %862 : !memref_rmem_f32_4
      }
      %870 = cute.static : !cute.int_tuple<"(0,0,0,49)">
      %iter_1488 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1489 = cute.add_offset(%iter_1488, %870) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1490 = cute.make_view(%tup_1489) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1491 = cute.get_iter(%view_1490) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1492, %e1_1493, %e2_1494, %e3_1495 = cute.get_leaves(%iter_1491) : !cute.int_tuple<"(?,?,?,?)">
      %871 = cute.static : !cute.int_tuple<"1">
      %tup_1496 = cute.add_offset(%e3_1495, %871) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1497 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1498 = cute.make_coord(%tup_1496) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %872 = cute.get_scalars(%coord_1497) : !cute.coord<"?">
      %873 = cute.get_scalars(%coord_1498) : !cute.coord<"?">
      %true_1499 = arith.constant true
      %874 = arith.cmpi slt, %872, %873 : i32
      %875 = arith.andi %true_1499, %874 : i1
      %876 = scf.if %875 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,13)">
        cute.memref.store(%869, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,13)">, f32) -> ()
        scf.yield %869 : !memref_rmem_f32_4
      } else {
        scf.yield %869 : !memref_rmem_f32_4
      }
      %877 = cute.static : !cute.int_tuple<"(0,0,0,56)">
      %iter_1500 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1501 = cute.add_offset(%iter_1500, %877) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1502 = cute.make_view(%tup_1501) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1503 = cute.get_iter(%view_1502) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1504, %e1_1505, %e2_1506, %e3_1507 = cute.get_leaves(%iter_1503) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %878 = cute.static : !cute.int_tuple<"1">
      %tup_1508 = cute.add_offset(%e3_1507, %878) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1509 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1510 = cute.make_coord(%tup_1508) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %879 = cute.get_scalars(%coord_1509) : !cute.coord<"?">
      %880 = cute.get_scalars(%coord_1510) : !cute.coord<"?">
      %true_1511 = arith.constant true
      %881 = arith.cmpi slt, %879, %880 : i32
      %882 = arith.andi %true_1511, %881 : i1
      %883 = scf.if %882 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,14)">
        cute.memref.store(%876, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,14)">, f32) -> ()
        scf.yield %876 : !memref_rmem_f32_4
      } else {
        scf.yield %876 : !memref_rmem_f32_4
      }
      %884 = cute.static : !cute.int_tuple<"(0,0,0,57)">
      %iter_1512 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1513 = cute.add_offset(%iter_1512, %884) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1514 = cute.make_view(%tup_1513) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1515 = cute.get_iter(%view_1514) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1516, %e1_1517, %e2_1518, %e3_1519 = cute.get_leaves(%iter_1515) : !cute.int_tuple<"(?,?,?,?)">
      %885 = cute.static : !cute.int_tuple<"1">
      %tup_1520 = cute.add_offset(%e3_1519, %885) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1521 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1522 = cute.make_coord(%tup_1520) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %886 = cute.get_scalars(%coord_1521) : !cute.coord<"?">
      %887 = cute.get_scalars(%coord_1522) : !cute.coord<"?">
      %true_1523 = arith.constant true
      %888 = arith.cmpi slt, %886, %887 : i32
      %889 = arith.andi %true_1523, %888 : i1
      %890 = scf.if %889 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(1,15)">
        cute.memref.store(%883, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(1,15)">, f32) -> ()
        scf.yield %883 : !memref_rmem_f32_4
      } else {
        scf.yield %883 : !memref_rmem_f32_4
      }
      %891 = cute.static : !cute.int_tuple<"2">
      %iter_1524 = cute.get_iter(%890) : !memref_rmem_f32_4
      %ptr_1525 = cute.add_offset(%iter_1524, %891) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1526 = cute.make_view(%ptr_1525) : !memref_rmem_f32_6
      %892 = cute.memref.load_vec %view_1526 : !memref_rmem_f32_6
      %cst_1527 = arith.constant 0xFF800000 : f32
      %893 = vector.reduction <maximumf>, %892, %cst_1527 : vector<16xf32> into f32
      %c-1_i32_1528 = arith.constant -1 : i32
      %c2_i32_1529 = arith.constant 2 : i32
      %c31_i32_1530 = arith.constant 31 : i32
      %894 = nvvm.shfl.sync  bfly %c-1_i32_1528, %893, %c2_i32_1529, %c31_i32_1530 : f32 -> f32
      %895 = nvvm.fmax %893, %894
      %c-1_i32_1531 = arith.constant -1 : i32
      %c1_i32_1532 = arith.constant 1 : i32
      %c31_i32_1533 = arith.constant 31 : i32
      %896 = nvvm.shfl.sync  bfly %c-1_i32_1531, %895, %c1_i32_1532, %c31_i32_1533 : f32 -> f32
      %897 = nvvm.fmax %895, %896
      %898 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %899 = arith.mulf %892, %898 : vector<16xf32>
      %900 = arith.mulf %897, %arg4 : f32
      %901 = vector.broadcast %900 : f32 to vector<16xf32>
      %902 = arith.subf %899, %901 : vector<16xf32>
      %903 = math.exp2 %902 fastmath<fast> : vector<16xf32>
      %cst_1534 = arith.constant 0.000000e+00 : f32
      %904 = vector.reduction <add>, %903, %cst_1534 : vector<16xf32> into f32
      %905 = cute.static : !cute.coord<"1">
      cute.memref.store(%rmem_623, %905, %897) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      %906 = cute.static : !cute.coord<"1">
      cute.memref.store(%rmem_624, %906, %904) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      %907 = cute.static : !cute.int_tuple<"2">
      %iter_1535 = cute.get_iter(%890) : !memref_rmem_f32_4
      %ptr_1536 = cute.add_offset(%iter_1535, %907) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1537 = cute.make_view(%ptr_1536) : !memref_rmem_f32_6
      cute.memref.store_vec %903, %view_1537 : !memref_rmem_f32_6
      %908 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_1538 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1539 = cute.add_offset(%iter_1538, %908) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1540 = cute.make_view(%tup_1539) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1541 = cute.get_iter(%view_1540) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1542, %e1_1543, %e2_1544, %e3_1545 = cute.get_leaves(%iter_1541) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %909 = cute.static : !cute.int_tuple<"1">
      %tup_1546 = cute.add_offset(%e3_1545, %909) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1547 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1548 = cute.make_coord(%tup_1546) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %910 = cute.get_scalars(%coord_1547) : !cute.coord<"?">
      %911 = cute.get_scalars(%coord_1548) : !cute.coord<"?">
      %true_1549 = arith.constant true
      %912 = arith.cmpi slt, %910, %911 : i32
      %913 = arith.andi %true_1549, %912 : i1
      %914 = scf.if %913 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,0)">
        cute.memref.store(%890, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,0)">, f32) -> ()
        scf.yield %890 : !memref_rmem_f32_4
      } else {
        scf.yield %890 : !memref_rmem_f32_4
      }
      %915 = cute.static : !cute.int_tuple<"(0,0,0,1)">
      %iter_1550 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1551 = cute.add_offset(%iter_1550, %915) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1552 = cute.make_view(%tup_1551) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1553 = cute.get_iter(%view_1552) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1554, %e1_1555, %e2_1556, %e3_1557 = cute.get_leaves(%iter_1553) : !cute.int_tuple<"(?,?,?,?)">
      %916 = cute.static : !cute.int_tuple<"1">
      %tup_1558 = cute.add_offset(%e3_1557, %916) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1559 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1560 = cute.make_coord(%tup_1558) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %917 = cute.get_scalars(%coord_1559) : !cute.coord<"?">
      %918 = cute.get_scalars(%coord_1560) : !cute.coord<"?">
      %true_1561 = arith.constant true
      %919 = arith.cmpi slt, %917, %918 : i32
      %920 = arith.andi %true_1561, %919 : i1
      %921 = scf.if %920 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,1)">
        cute.memref.store(%914, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,1)">, f32) -> ()
        scf.yield %914 : !memref_rmem_f32_4
      } else {
        scf.yield %914 : !memref_rmem_f32_4
      }
      %922 = cute.static : !cute.int_tuple<"(0,0,0,8)">
      %iter_1562 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1563 = cute.add_offset(%iter_1562, %922) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1564 = cute.make_view(%tup_1563) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1565 = cute.get_iter(%view_1564) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1566, %e1_1567, %e2_1568, %e3_1569 = cute.get_leaves(%iter_1565) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %923 = cute.static : !cute.int_tuple<"1">
      %tup_1570 = cute.add_offset(%e3_1569, %923) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1571 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1572 = cute.make_coord(%tup_1570) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %924 = cute.get_scalars(%coord_1571) : !cute.coord<"?">
      %925 = cute.get_scalars(%coord_1572) : !cute.coord<"?">
      %true_1573 = arith.constant true
      %926 = arith.cmpi slt, %924, %925 : i32
      %927 = arith.andi %true_1573, %926 : i1
      %928 = scf.if %927 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,2)">
        cute.memref.store(%921, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,2)">, f32) -> ()
        scf.yield %921 : !memref_rmem_f32_4
      } else {
        scf.yield %921 : !memref_rmem_f32_4
      }
      %929 = cute.static : !cute.int_tuple<"(0,0,0,9)">
      %iter_1574 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1575 = cute.add_offset(%iter_1574, %929) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1576 = cute.make_view(%tup_1575) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1577 = cute.get_iter(%view_1576) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1578, %e1_1579, %e2_1580, %e3_1581 = cute.get_leaves(%iter_1577) : !cute.int_tuple<"(?,?,?,?)">
      %930 = cute.static : !cute.int_tuple<"1">
      %tup_1582 = cute.add_offset(%e3_1581, %930) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1583 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1584 = cute.make_coord(%tup_1582) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %931 = cute.get_scalars(%coord_1583) : !cute.coord<"?">
      %932 = cute.get_scalars(%coord_1584) : !cute.coord<"?">
      %true_1585 = arith.constant true
      %933 = arith.cmpi slt, %931, %932 : i32
      %934 = arith.andi %true_1585, %933 : i1
      %935 = scf.if %934 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,3)">
        cute.memref.store(%928, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,3)">, f32) -> ()
        scf.yield %928 : !memref_rmem_f32_4
      } else {
        scf.yield %928 : !memref_rmem_f32_4
      }
      %936 = cute.static : !cute.int_tuple<"(0,0,0,16)">
      %iter_1586 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1587 = cute.add_offset(%iter_1586, %936) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1588 = cute.make_view(%tup_1587) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1589 = cute.get_iter(%view_1588) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1590, %e1_1591, %e2_1592, %e3_1593 = cute.get_leaves(%iter_1589) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %937 = cute.static : !cute.int_tuple<"1">
      %tup_1594 = cute.add_offset(%e3_1593, %937) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1595 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1596 = cute.make_coord(%tup_1594) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %938 = cute.get_scalars(%coord_1595) : !cute.coord<"?">
      %939 = cute.get_scalars(%coord_1596) : !cute.coord<"?">
      %true_1597 = arith.constant true
      %940 = arith.cmpi slt, %938, %939 : i32
      %941 = arith.andi %true_1597, %940 : i1
      %942 = scf.if %941 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,4)">
        cute.memref.store(%935, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,4)">, f32) -> ()
        scf.yield %935 : !memref_rmem_f32_4
      } else {
        scf.yield %935 : !memref_rmem_f32_4
      }
      %943 = cute.static : !cute.int_tuple<"(0,0,0,17)">
      %iter_1598 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1599 = cute.add_offset(%iter_1598, %943) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1600 = cute.make_view(%tup_1599) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1601 = cute.get_iter(%view_1600) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1602, %e1_1603, %e2_1604, %e3_1605 = cute.get_leaves(%iter_1601) : !cute.int_tuple<"(?,?,?,?)">
      %944 = cute.static : !cute.int_tuple<"1">
      %tup_1606 = cute.add_offset(%e3_1605, %944) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1607 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1608 = cute.make_coord(%tup_1606) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %945 = cute.get_scalars(%coord_1607) : !cute.coord<"?">
      %946 = cute.get_scalars(%coord_1608) : !cute.coord<"?">
      %true_1609 = arith.constant true
      %947 = arith.cmpi slt, %945, %946 : i32
      %948 = arith.andi %true_1609, %947 : i1
      %949 = scf.if %948 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,5)">
        cute.memref.store(%942, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,5)">, f32) -> ()
        scf.yield %942 : !memref_rmem_f32_4
      } else {
        scf.yield %942 : !memref_rmem_f32_4
      }
      %950 = cute.static : !cute.int_tuple<"(0,0,0,24)">
      %iter_1610 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1611 = cute.add_offset(%iter_1610, %950) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1612 = cute.make_view(%tup_1611) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1613 = cute.get_iter(%view_1612) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1614, %e1_1615, %e2_1616, %e3_1617 = cute.get_leaves(%iter_1613) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %951 = cute.static : !cute.int_tuple<"1">
      %tup_1618 = cute.add_offset(%e3_1617, %951) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1619 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1620 = cute.make_coord(%tup_1618) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %952 = cute.get_scalars(%coord_1619) : !cute.coord<"?">
      %953 = cute.get_scalars(%coord_1620) : !cute.coord<"?">
      %true_1621 = arith.constant true
      %954 = arith.cmpi slt, %952, %953 : i32
      %955 = arith.andi %true_1621, %954 : i1
      %956 = scf.if %955 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,6)">
        cute.memref.store(%949, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,6)">, f32) -> ()
        scf.yield %949 : !memref_rmem_f32_4
      } else {
        scf.yield %949 : !memref_rmem_f32_4
      }
      %957 = cute.static : !cute.int_tuple<"(0,0,0,25)">
      %iter_1622 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1623 = cute.add_offset(%iter_1622, %957) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1624 = cute.make_view(%tup_1623) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1625 = cute.get_iter(%view_1624) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1626, %e1_1627, %e2_1628, %e3_1629 = cute.get_leaves(%iter_1625) : !cute.int_tuple<"(?,?,?,?)">
      %958 = cute.static : !cute.int_tuple<"1">
      %tup_1630 = cute.add_offset(%e3_1629, %958) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1631 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1632 = cute.make_coord(%tup_1630) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %959 = cute.get_scalars(%coord_1631) : !cute.coord<"?">
      %960 = cute.get_scalars(%coord_1632) : !cute.coord<"?">
      %true_1633 = arith.constant true
      %961 = arith.cmpi slt, %959, %960 : i32
      %962 = arith.andi %true_1633, %961 : i1
      %963 = scf.if %962 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,7)">
        cute.memref.store(%956, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,7)">, f32) -> ()
        scf.yield %956 : !memref_rmem_f32_4
      } else {
        scf.yield %956 : !memref_rmem_f32_4
      }
      %964 = cute.static : !cute.int_tuple<"(0,0,0,32)">
      %iter_1634 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1635 = cute.add_offset(%iter_1634, %964) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1636 = cute.make_view(%tup_1635) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1637 = cute.get_iter(%view_1636) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1638, %e1_1639, %e2_1640, %e3_1641 = cute.get_leaves(%iter_1637) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %965 = cute.static : !cute.int_tuple<"1">
      %tup_1642 = cute.add_offset(%e3_1641, %965) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1643 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1644 = cute.make_coord(%tup_1642) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %966 = cute.get_scalars(%coord_1643) : !cute.coord<"?">
      %967 = cute.get_scalars(%coord_1644) : !cute.coord<"?">
      %true_1645 = arith.constant true
      %968 = arith.cmpi slt, %966, %967 : i32
      %969 = arith.andi %true_1645, %968 : i1
      %970 = scf.if %969 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,8)">
        cute.memref.store(%963, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,8)">, f32) -> ()
        scf.yield %963 : !memref_rmem_f32_4
      } else {
        scf.yield %963 : !memref_rmem_f32_4
      }
      %971 = cute.static : !cute.int_tuple<"(0,0,0,33)">
      %iter_1646 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1647 = cute.add_offset(%iter_1646, %971) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1648 = cute.make_view(%tup_1647) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1649 = cute.get_iter(%view_1648) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1650, %e1_1651, %e2_1652, %e3_1653 = cute.get_leaves(%iter_1649) : !cute.int_tuple<"(?,?,?,?)">
      %972 = cute.static : !cute.int_tuple<"1">
      %tup_1654 = cute.add_offset(%e3_1653, %972) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1655 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1656 = cute.make_coord(%tup_1654) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %973 = cute.get_scalars(%coord_1655) : !cute.coord<"?">
      %974 = cute.get_scalars(%coord_1656) : !cute.coord<"?">
      %true_1657 = arith.constant true
      %975 = arith.cmpi slt, %973, %974 : i32
      %976 = arith.andi %true_1657, %975 : i1
      %977 = scf.if %976 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,9)">
        cute.memref.store(%970, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,9)">, f32) -> ()
        scf.yield %970 : !memref_rmem_f32_4
      } else {
        scf.yield %970 : !memref_rmem_f32_4
      }
      %978 = cute.static : !cute.int_tuple<"(0,0,0,40)">
      %iter_1658 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1659 = cute.add_offset(%iter_1658, %978) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1660 = cute.make_view(%tup_1659) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1661 = cute.get_iter(%view_1660) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1662, %e1_1663, %e2_1664, %e3_1665 = cute.get_leaves(%iter_1661) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %979 = cute.static : !cute.int_tuple<"1">
      %tup_1666 = cute.add_offset(%e3_1665, %979) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1667 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1668 = cute.make_coord(%tup_1666) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %980 = cute.get_scalars(%coord_1667) : !cute.coord<"?">
      %981 = cute.get_scalars(%coord_1668) : !cute.coord<"?">
      %true_1669 = arith.constant true
      %982 = arith.cmpi slt, %980, %981 : i32
      %983 = arith.andi %true_1669, %982 : i1
      %984 = scf.if %983 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,10)">
        cute.memref.store(%977, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,10)">, f32) -> ()
        scf.yield %977 : !memref_rmem_f32_4
      } else {
        scf.yield %977 : !memref_rmem_f32_4
      }
      %985 = cute.static : !cute.int_tuple<"(0,0,0,41)">
      %iter_1670 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1671 = cute.add_offset(%iter_1670, %985) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1672 = cute.make_view(%tup_1671) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1673 = cute.get_iter(%view_1672) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1674, %e1_1675, %e2_1676, %e3_1677 = cute.get_leaves(%iter_1673) : !cute.int_tuple<"(?,?,?,?)">
      %986 = cute.static : !cute.int_tuple<"1">
      %tup_1678 = cute.add_offset(%e3_1677, %986) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1679 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1680 = cute.make_coord(%tup_1678) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %987 = cute.get_scalars(%coord_1679) : !cute.coord<"?">
      %988 = cute.get_scalars(%coord_1680) : !cute.coord<"?">
      %true_1681 = arith.constant true
      %989 = arith.cmpi slt, %987, %988 : i32
      %990 = arith.andi %true_1681, %989 : i1
      %991 = scf.if %990 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,11)">
        cute.memref.store(%984, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,11)">, f32) -> ()
        scf.yield %984 : !memref_rmem_f32_4
      } else {
        scf.yield %984 : !memref_rmem_f32_4
      }
      %992 = cute.static : !cute.int_tuple<"(0,0,0,48)">
      %iter_1682 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1683 = cute.add_offset(%iter_1682, %992) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1684 = cute.make_view(%tup_1683) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1685 = cute.get_iter(%view_1684) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1686, %e1_1687, %e2_1688, %e3_1689 = cute.get_leaves(%iter_1685) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %993 = cute.static : !cute.int_tuple<"1">
      %tup_1690 = cute.add_offset(%e3_1689, %993) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1691 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1692 = cute.make_coord(%tup_1690) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %994 = cute.get_scalars(%coord_1691) : !cute.coord<"?">
      %995 = cute.get_scalars(%coord_1692) : !cute.coord<"?">
      %true_1693 = arith.constant true
      %996 = arith.cmpi slt, %994, %995 : i32
      %997 = arith.andi %true_1693, %996 : i1
      %998 = scf.if %997 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,12)">
        cute.memref.store(%991, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,12)">, f32) -> ()
        scf.yield %991 : !memref_rmem_f32_4
      } else {
        scf.yield %991 : !memref_rmem_f32_4
      }
      %999 = cute.static : !cute.int_tuple<"(0,0,0,49)">
      %iter_1694 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1695 = cute.add_offset(%iter_1694, %999) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1696 = cute.make_view(%tup_1695) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1697 = cute.get_iter(%view_1696) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1698, %e1_1699, %e2_1700, %e3_1701 = cute.get_leaves(%iter_1697) : !cute.int_tuple<"(?,?,?,?)">
      %1000 = cute.static : !cute.int_tuple<"1">
      %tup_1702 = cute.add_offset(%e3_1701, %1000) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1703 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1704 = cute.make_coord(%tup_1702) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1001 = cute.get_scalars(%coord_1703) : !cute.coord<"?">
      %1002 = cute.get_scalars(%coord_1704) : !cute.coord<"?">
      %true_1705 = arith.constant true
      %1003 = arith.cmpi slt, %1001, %1002 : i32
      %1004 = arith.andi %true_1705, %1003 : i1
      %1005 = scf.if %1004 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,13)">
        cute.memref.store(%998, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,13)">, f32) -> ()
        scf.yield %998 : !memref_rmem_f32_4
      } else {
        scf.yield %998 : !memref_rmem_f32_4
      }
      %1006 = cute.static : !cute.int_tuple<"(0,0,0,56)">
      %iter_1706 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1707 = cute.add_offset(%iter_1706, %1006) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1708 = cute.make_view(%tup_1707) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1709 = cute.get_iter(%view_1708) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1710, %e1_1711, %e2_1712, %e3_1713 = cute.get_leaves(%iter_1709) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1007 = cute.static : !cute.int_tuple<"1">
      %tup_1714 = cute.add_offset(%e3_1713, %1007) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1715 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1716 = cute.make_coord(%tup_1714) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1008 = cute.get_scalars(%coord_1715) : !cute.coord<"?">
      %1009 = cute.get_scalars(%coord_1716) : !cute.coord<"?">
      %true_1717 = arith.constant true
      %1010 = arith.cmpi slt, %1008, %1009 : i32
      %1011 = arith.andi %true_1717, %1010 : i1
      %1012 = scf.if %1011 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,14)">
        cute.memref.store(%1005, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,14)">, f32) -> ()
        scf.yield %1005 : !memref_rmem_f32_4
      } else {
        scf.yield %1005 : !memref_rmem_f32_4
      }
      %1013 = cute.static : !cute.int_tuple<"(0,0,0,57)">
      %iter_1718 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1719 = cute.add_offset(%iter_1718, %1013) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1720 = cute.make_view(%tup_1719) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1721 = cute.get_iter(%view_1720) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1722, %e1_1723, %e2_1724, %e3_1725 = cute.get_leaves(%iter_1721) : !cute.int_tuple<"(?,?,?,?)">
      %1014 = cute.static : !cute.int_tuple<"1">
      %tup_1726 = cute.add_offset(%e3_1725, %1014) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1727 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1728 = cute.make_coord(%tup_1726) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1015 = cute.get_scalars(%coord_1727) : !cute.coord<"?">
      %1016 = cute.get_scalars(%coord_1728) : !cute.coord<"?">
      %true_1729 = arith.constant true
      %1017 = arith.cmpi slt, %1015, %1016 : i32
      %1018 = arith.andi %true_1729, %1017 : i1
      %1019 = scf.if %1018 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(2,15)">
        cute.memref.store(%1012, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(2,15)">, f32) -> ()
        scf.yield %1012 : !memref_rmem_f32_4
      } else {
        scf.yield %1012 : !memref_rmem_f32_4
      }
      %1020 = cute.static : !cute.int_tuple<"4">
      %iter_1730 = cute.get_iter(%1019) : !memref_rmem_f32_4
      %ptr_1731 = cute.add_offset(%iter_1730, %1020) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1732 = cute.make_view(%ptr_1731) : !memref_rmem_f32_7
      %1021 = cute.memref.load_vec %view_1732 : !memref_rmem_f32_7
      %cst_1733 = arith.constant 0xFF800000 : f32
      %1022 = vector.reduction <maximumf>, %1021, %cst_1733 : vector<16xf32> into f32
      %c-1_i32_1734 = arith.constant -1 : i32
      %c2_i32_1735 = arith.constant 2 : i32
      %c31_i32_1736 = arith.constant 31 : i32
      %1023 = nvvm.shfl.sync  bfly %c-1_i32_1734, %1022, %c2_i32_1735, %c31_i32_1736 : f32 -> f32
      %1024 = nvvm.fmax %1022, %1023
      %c-1_i32_1737 = arith.constant -1 : i32
      %c1_i32_1738 = arith.constant 1 : i32
      %c31_i32_1739 = arith.constant 31 : i32
      %1025 = nvvm.shfl.sync  bfly %c-1_i32_1737, %1024, %c1_i32_1738, %c31_i32_1739 : f32 -> f32
      %1026 = nvvm.fmax %1024, %1025
      %1027 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %1028 = arith.mulf %1021, %1027 : vector<16xf32>
      %1029 = arith.mulf %1026, %arg4 : f32
      %1030 = vector.broadcast %1029 : f32 to vector<16xf32>
      %1031 = arith.subf %1028, %1030 : vector<16xf32>
      %1032 = math.exp2 %1031 fastmath<fast> : vector<16xf32>
      %cst_1740 = arith.constant 0.000000e+00 : f32
      %1033 = vector.reduction <add>, %1032, %cst_1740 : vector<16xf32> into f32
      %1034 = cute.static : !cute.coord<"2">
      cute.memref.store(%rmem_623, %1034, %1026) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      %1035 = cute.static : !cute.coord<"2">
      cute.memref.store(%rmem_624, %1035, %1033) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      %1036 = cute.static : !cute.int_tuple<"4">
      %iter_1741 = cute.get_iter(%1019) : !memref_rmem_f32_4
      %ptr_1742 = cute.add_offset(%iter_1741, %1036) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1743 = cute.make_view(%ptr_1742) : !memref_rmem_f32_7
      cute.memref.store_vec %1032, %view_1743 : !memref_rmem_f32_7
      %1037 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_1744 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1745 = cute.add_offset(%iter_1744, %1037) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1746 = cute.make_view(%tup_1745) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1747 = cute.get_iter(%view_1746) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1748, %e1_1749, %e2_1750, %e3_1751 = cute.get_leaves(%iter_1747) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1038 = cute.static : !cute.int_tuple<"1">
      %tup_1752 = cute.add_offset(%e3_1751, %1038) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1753 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1754 = cute.make_coord(%tup_1752) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1039 = cute.get_scalars(%coord_1753) : !cute.coord<"?">
      %1040 = cute.get_scalars(%coord_1754) : !cute.coord<"?">
      %true_1755 = arith.constant true
      %1041 = arith.cmpi slt, %1039, %1040 : i32
      %1042 = arith.andi %true_1755, %1041 : i1
      %1043 = scf.if %1042 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,0)">
        cute.memref.store(%1019, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,0)">, f32) -> ()
        scf.yield %1019 : !memref_rmem_f32_4
      } else {
        scf.yield %1019 : !memref_rmem_f32_4
      }
      %1044 = cute.static : !cute.int_tuple<"(0,0,0,1)">
      %iter_1756 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1757 = cute.add_offset(%iter_1756, %1044) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1758 = cute.make_view(%tup_1757) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1759 = cute.get_iter(%view_1758) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1760, %e1_1761, %e2_1762, %e3_1763 = cute.get_leaves(%iter_1759) : !cute.int_tuple<"(?,?,?,?)">
      %1045 = cute.static : !cute.int_tuple<"1">
      %tup_1764 = cute.add_offset(%e3_1763, %1045) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1765 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1766 = cute.make_coord(%tup_1764) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1046 = cute.get_scalars(%coord_1765) : !cute.coord<"?">
      %1047 = cute.get_scalars(%coord_1766) : !cute.coord<"?">
      %true_1767 = arith.constant true
      %1048 = arith.cmpi slt, %1046, %1047 : i32
      %1049 = arith.andi %true_1767, %1048 : i1
      %1050 = scf.if %1049 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,1)">
        cute.memref.store(%1043, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,1)">, f32) -> ()
        scf.yield %1043 : !memref_rmem_f32_4
      } else {
        scf.yield %1043 : !memref_rmem_f32_4
      }
      %1051 = cute.static : !cute.int_tuple<"(0,0,0,8)">
      %iter_1768 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1769 = cute.add_offset(%iter_1768, %1051) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1770 = cute.make_view(%tup_1769) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1771 = cute.get_iter(%view_1770) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1772, %e1_1773, %e2_1774, %e3_1775 = cute.get_leaves(%iter_1771) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1052 = cute.static : !cute.int_tuple<"1">
      %tup_1776 = cute.add_offset(%e3_1775, %1052) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1777 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1778 = cute.make_coord(%tup_1776) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1053 = cute.get_scalars(%coord_1777) : !cute.coord<"?">
      %1054 = cute.get_scalars(%coord_1778) : !cute.coord<"?">
      %true_1779 = arith.constant true
      %1055 = arith.cmpi slt, %1053, %1054 : i32
      %1056 = arith.andi %true_1779, %1055 : i1
      %1057 = scf.if %1056 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,2)">
        cute.memref.store(%1050, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,2)">, f32) -> ()
        scf.yield %1050 : !memref_rmem_f32_4
      } else {
        scf.yield %1050 : !memref_rmem_f32_4
      }
      %1058 = cute.static : !cute.int_tuple<"(0,0,0,9)">
      %iter_1780 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1781 = cute.add_offset(%iter_1780, %1058) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1782 = cute.make_view(%tup_1781) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1783 = cute.get_iter(%view_1782) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1784, %e1_1785, %e2_1786, %e3_1787 = cute.get_leaves(%iter_1783) : !cute.int_tuple<"(?,?,?,?)">
      %1059 = cute.static : !cute.int_tuple<"1">
      %tup_1788 = cute.add_offset(%e3_1787, %1059) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1789 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1790 = cute.make_coord(%tup_1788) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1060 = cute.get_scalars(%coord_1789) : !cute.coord<"?">
      %1061 = cute.get_scalars(%coord_1790) : !cute.coord<"?">
      %true_1791 = arith.constant true
      %1062 = arith.cmpi slt, %1060, %1061 : i32
      %1063 = arith.andi %true_1791, %1062 : i1
      %1064 = scf.if %1063 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,3)">
        cute.memref.store(%1057, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,3)">, f32) -> ()
        scf.yield %1057 : !memref_rmem_f32_4
      } else {
        scf.yield %1057 : !memref_rmem_f32_4
      }
      %1065 = cute.static : !cute.int_tuple<"(0,0,0,16)">
      %iter_1792 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1793 = cute.add_offset(%iter_1792, %1065) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1794 = cute.make_view(%tup_1793) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1795 = cute.get_iter(%view_1794) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1796, %e1_1797, %e2_1798, %e3_1799 = cute.get_leaves(%iter_1795) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1066 = cute.static : !cute.int_tuple<"1">
      %tup_1800 = cute.add_offset(%e3_1799, %1066) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1801 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1802 = cute.make_coord(%tup_1800) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1067 = cute.get_scalars(%coord_1801) : !cute.coord<"?">
      %1068 = cute.get_scalars(%coord_1802) : !cute.coord<"?">
      %true_1803 = arith.constant true
      %1069 = arith.cmpi slt, %1067, %1068 : i32
      %1070 = arith.andi %true_1803, %1069 : i1
      %1071 = scf.if %1070 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,4)">
        cute.memref.store(%1064, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,4)">, f32) -> ()
        scf.yield %1064 : !memref_rmem_f32_4
      } else {
        scf.yield %1064 : !memref_rmem_f32_4
      }
      %1072 = cute.static : !cute.int_tuple<"(0,0,0,17)">
      %iter_1804 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1805 = cute.add_offset(%iter_1804, %1072) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1806 = cute.make_view(%tup_1805) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1807 = cute.get_iter(%view_1806) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1808, %e1_1809, %e2_1810, %e3_1811 = cute.get_leaves(%iter_1807) : !cute.int_tuple<"(?,?,?,?)">
      %1073 = cute.static : !cute.int_tuple<"1">
      %tup_1812 = cute.add_offset(%e3_1811, %1073) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1813 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1814 = cute.make_coord(%tup_1812) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1074 = cute.get_scalars(%coord_1813) : !cute.coord<"?">
      %1075 = cute.get_scalars(%coord_1814) : !cute.coord<"?">
      %true_1815 = arith.constant true
      %1076 = arith.cmpi slt, %1074, %1075 : i32
      %1077 = arith.andi %true_1815, %1076 : i1
      %1078 = scf.if %1077 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,5)">
        cute.memref.store(%1071, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,5)">, f32) -> ()
        scf.yield %1071 : !memref_rmem_f32_4
      } else {
        scf.yield %1071 : !memref_rmem_f32_4
      }
      %1079 = cute.static : !cute.int_tuple<"(0,0,0,24)">
      %iter_1816 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1817 = cute.add_offset(%iter_1816, %1079) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1818 = cute.make_view(%tup_1817) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1819 = cute.get_iter(%view_1818) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1820, %e1_1821, %e2_1822, %e3_1823 = cute.get_leaves(%iter_1819) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1080 = cute.static : !cute.int_tuple<"1">
      %tup_1824 = cute.add_offset(%e3_1823, %1080) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1825 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1826 = cute.make_coord(%tup_1824) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1081 = cute.get_scalars(%coord_1825) : !cute.coord<"?">
      %1082 = cute.get_scalars(%coord_1826) : !cute.coord<"?">
      %true_1827 = arith.constant true
      %1083 = arith.cmpi slt, %1081, %1082 : i32
      %1084 = arith.andi %true_1827, %1083 : i1
      %1085 = scf.if %1084 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,6)">
        cute.memref.store(%1078, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,6)">, f32) -> ()
        scf.yield %1078 : !memref_rmem_f32_4
      } else {
        scf.yield %1078 : !memref_rmem_f32_4
      }
      %1086 = cute.static : !cute.int_tuple<"(0,0,0,25)">
      %iter_1828 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1829 = cute.add_offset(%iter_1828, %1086) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1830 = cute.make_view(%tup_1829) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1831 = cute.get_iter(%view_1830) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1832, %e1_1833, %e2_1834, %e3_1835 = cute.get_leaves(%iter_1831) : !cute.int_tuple<"(?,?,?,?)">
      %1087 = cute.static : !cute.int_tuple<"1">
      %tup_1836 = cute.add_offset(%e3_1835, %1087) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1837 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1838 = cute.make_coord(%tup_1836) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1088 = cute.get_scalars(%coord_1837) : !cute.coord<"?">
      %1089 = cute.get_scalars(%coord_1838) : !cute.coord<"?">
      %true_1839 = arith.constant true
      %1090 = arith.cmpi slt, %1088, %1089 : i32
      %1091 = arith.andi %true_1839, %1090 : i1
      %1092 = scf.if %1091 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,7)">
        cute.memref.store(%1085, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,7)">, f32) -> ()
        scf.yield %1085 : !memref_rmem_f32_4
      } else {
        scf.yield %1085 : !memref_rmem_f32_4
      }
      %1093 = cute.static : !cute.int_tuple<"(0,0,0,32)">
      %iter_1840 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1841 = cute.add_offset(%iter_1840, %1093) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1842 = cute.make_view(%tup_1841) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1843 = cute.get_iter(%view_1842) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1844, %e1_1845, %e2_1846, %e3_1847 = cute.get_leaves(%iter_1843) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1094 = cute.static : !cute.int_tuple<"1">
      %tup_1848 = cute.add_offset(%e3_1847, %1094) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1849 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1850 = cute.make_coord(%tup_1848) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1095 = cute.get_scalars(%coord_1849) : !cute.coord<"?">
      %1096 = cute.get_scalars(%coord_1850) : !cute.coord<"?">
      %true_1851 = arith.constant true
      %1097 = arith.cmpi slt, %1095, %1096 : i32
      %1098 = arith.andi %true_1851, %1097 : i1
      %1099 = scf.if %1098 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,8)">
        cute.memref.store(%1092, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,8)">, f32) -> ()
        scf.yield %1092 : !memref_rmem_f32_4
      } else {
        scf.yield %1092 : !memref_rmem_f32_4
      }
      %1100 = cute.static : !cute.int_tuple<"(0,0,0,33)">
      %iter_1852 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1853 = cute.add_offset(%iter_1852, %1100) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1854 = cute.make_view(%tup_1853) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1855 = cute.get_iter(%view_1854) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1856, %e1_1857, %e2_1858, %e3_1859 = cute.get_leaves(%iter_1855) : !cute.int_tuple<"(?,?,?,?)">
      %1101 = cute.static : !cute.int_tuple<"1">
      %tup_1860 = cute.add_offset(%e3_1859, %1101) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1861 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1862 = cute.make_coord(%tup_1860) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1102 = cute.get_scalars(%coord_1861) : !cute.coord<"?">
      %1103 = cute.get_scalars(%coord_1862) : !cute.coord<"?">
      %true_1863 = arith.constant true
      %1104 = arith.cmpi slt, %1102, %1103 : i32
      %1105 = arith.andi %true_1863, %1104 : i1
      %1106 = scf.if %1105 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,9)">
        cute.memref.store(%1099, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,9)">, f32) -> ()
        scf.yield %1099 : !memref_rmem_f32_4
      } else {
        scf.yield %1099 : !memref_rmem_f32_4
      }
      %1107 = cute.static : !cute.int_tuple<"(0,0,0,40)">
      %iter_1864 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1865 = cute.add_offset(%iter_1864, %1107) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1866 = cute.make_view(%tup_1865) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1867 = cute.get_iter(%view_1866) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1868, %e1_1869, %e2_1870, %e3_1871 = cute.get_leaves(%iter_1867) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1108 = cute.static : !cute.int_tuple<"1">
      %tup_1872 = cute.add_offset(%e3_1871, %1108) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1873 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1874 = cute.make_coord(%tup_1872) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1109 = cute.get_scalars(%coord_1873) : !cute.coord<"?">
      %1110 = cute.get_scalars(%coord_1874) : !cute.coord<"?">
      %true_1875 = arith.constant true
      %1111 = arith.cmpi slt, %1109, %1110 : i32
      %1112 = arith.andi %true_1875, %1111 : i1
      %1113 = scf.if %1112 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,10)">
        cute.memref.store(%1106, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,10)">, f32) -> ()
        scf.yield %1106 : !memref_rmem_f32_4
      } else {
        scf.yield %1106 : !memref_rmem_f32_4
      }
      %1114 = cute.static : !cute.int_tuple<"(0,0,0,41)">
      %iter_1876 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1877 = cute.add_offset(%iter_1876, %1114) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1878 = cute.make_view(%tup_1877) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1879 = cute.get_iter(%view_1878) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1880, %e1_1881, %e2_1882, %e3_1883 = cute.get_leaves(%iter_1879) : !cute.int_tuple<"(?,?,?,?)">
      %1115 = cute.static : !cute.int_tuple<"1">
      %tup_1884 = cute.add_offset(%e3_1883, %1115) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1885 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1886 = cute.make_coord(%tup_1884) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1116 = cute.get_scalars(%coord_1885) : !cute.coord<"?">
      %1117 = cute.get_scalars(%coord_1886) : !cute.coord<"?">
      %true_1887 = arith.constant true
      %1118 = arith.cmpi slt, %1116, %1117 : i32
      %1119 = arith.andi %true_1887, %1118 : i1
      %1120 = scf.if %1119 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,11)">
        cute.memref.store(%1113, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,11)">, f32) -> ()
        scf.yield %1113 : !memref_rmem_f32_4
      } else {
        scf.yield %1113 : !memref_rmem_f32_4
      }
      %1121 = cute.static : !cute.int_tuple<"(0,0,0,48)">
      %iter_1888 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1889 = cute.add_offset(%iter_1888, %1121) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1890 = cute.make_view(%tup_1889) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1891 = cute.get_iter(%view_1890) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1892, %e1_1893, %e2_1894, %e3_1895 = cute.get_leaves(%iter_1891) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1122 = cute.static : !cute.int_tuple<"1">
      %tup_1896 = cute.add_offset(%e3_1895, %1122) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1897 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1898 = cute.make_coord(%tup_1896) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1123 = cute.get_scalars(%coord_1897) : !cute.coord<"?">
      %1124 = cute.get_scalars(%coord_1898) : !cute.coord<"?">
      %true_1899 = arith.constant true
      %1125 = arith.cmpi slt, %1123, %1124 : i32
      %1126 = arith.andi %true_1899, %1125 : i1
      %1127 = scf.if %1126 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,12)">
        cute.memref.store(%1120, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,12)">, f32) -> ()
        scf.yield %1120 : !memref_rmem_f32_4
      } else {
        scf.yield %1120 : !memref_rmem_f32_4
      }
      %1128 = cute.static : !cute.int_tuple<"(0,0,0,49)">
      %iter_1900 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1901 = cute.add_offset(%iter_1900, %1128) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1902 = cute.make_view(%tup_1901) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1903 = cute.get_iter(%view_1902) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1904, %e1_1905, %e2_1906, %e3_1907 = cute.get_leaves(%iter_1903) : !cute.int_tuple<"(?,?,?,?)">
      %1129 = cute.static : !cute.int_tuple<"1">
      %tup_1908 = cute.add_offset(%e3_1907, %1129) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1909 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1910 = cute.make_coord(%tup_1908) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1130 = cute.get_scalars(%coord_1909) : !cute.coord<"?">
      %1131 = cute.get_scalars(%coord_1910) : !cute.coord<"?">
      %true_1911 = arith.constant true
      %1132 = arith.cmpi slt, %1130, %1131 : i32
      %1133 = arith.andi %true_1911, %1132 : i1
      %1134 = scf.if %1133 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,13)">
        cute.memref.store(%1127, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,13)">, f32) -> ()
        scf.yield %1127 : !memref_rmem_f32_4
      } else {
        scf.yield %1127 : !memref_rmem_f32_4
      }
      %1135 = cute.static : !cute.int_tuple<"(0,0,0,56)">
      %iter_1912 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1913 = cute.add_offset(%iter_1912, %1135) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %view_1914 = cute.make_view(%tup_1913) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %iter_1915 = cute.get_iter(%view_1914) : !cute.coord_tensor<"(?,?,?,?{div=2})", "():()">
      %e0_1916, %e1_1917, %e2_1918, %e3_1919 = cute.get_leaves(%iter_1915) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %1136 = cute.static : !cute.int_tuple<"1">
      %tup_1920 = cute.add_offset(%e3_1919, %1136) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1921 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1922 = cute.make_coord(%tup_1920) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1137 = cute.get_scalars(%coord_1921) : !cute.coord<"?">
      %1138 = cute.get_scalars(%coord_1922) : !cute.coord<"?">
      %true_1923 = arith.constant true
      %1139 = arith.cmpi slt, %1137, %1138 : i32
      %1140 = arith.andi %true_1923, %1139 : i1
      %1141 = scf.if %1140 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,14)">
        cute.memref.store(%1134, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,14)">, f32) -> ()
        scf.yield %1134 : !memref_rmem_f32_4
      } else {
        scf.yield %1134 : !memref_rmem_f32_4
      }
      %1142 = cute.static : !cute.int_tuple<"(0,0,0,57)">
      %iter_1924 = cute.get_iter(%view_1127) : !cute.coord_tensor<"(?,?,?,?{div=2})", "((2,2),(2,8)):((8@1,64@1),(1@3,8@3))">
      %tup_1925 = cute.add_offset(%iter_1924, %1142) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %view_1926 = cute.make_view(%tup_1925) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %iter_1927 = cute.get_iter(%view_1926) : !cute.coord_tensor<"(?,?,?,?)", "():()">
      %e0_1928, %e1_1929, %e2_1930, %e3_1931 = cute.get_leaves(%iter_1927) : !cute.int_tuple<"(?,?,?,?)">
      %1143 = cute.static : !cute.int_tuple<"1">
      %tup_1932 = cute.add_offset(%e3_1931, %1143) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_1933 = cute.make_coord(%itup_1086) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1934 = cute.make_coord(%tup_1932) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1144 = cute.get_scalars(%coord_1933) : !cute.coord<"?">
      %1145 = cute.get_scalars(%coord_1934) : !cute.coord<"?">
      %true_1935 = arith.constant true
      %1146 = arith.cmpi slt, %1144, %1145 : i32
      %1147 = arith.andi %true_1935, %1146 : i1
      %1148 = scf.if %1147 -> (!memref_rmem_f32_4) {
        %cst_2576 = arith.constant 0xFF800000 : f32
        %1582 = cute.static : !cute.coord<"(3,15)">
        cute.memref.store(%1141, %1582, %cst_2576) : (!memref_rmem_f32_4, !cute.coord<"(3,15)">, f32) -> ()
        scf.yield %1141 : !memref_rmem_f32_4
      } else {
        scf.yield %1141 : !memref_rmem_f32_4
      }
      %1149 = cute.static : !cute.int_tuple<"6">
      %iter_1936 = cute.get_iter(%1148) : !memref_rmem_f32_4
      %ptr_1937 = cute.add_offset(%iter_1936, %1149) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1938 = cute.make_view(%ptr_1937) : !memref_rmem_f32_6
      %1150 = cute.memref.load_vec %view_1938 : !memref_rmem_f32_6
      %cst_1939 = arith.constant 0xFF800000 : f32
      %1151 = vector.reduction <maximumf>, %1150, %cst_1939 : vector<16xf32> into f32
      %c-1_i32_1940 = arith.constant -1 : i32
      %c2_i32_1941 = arith.constant 2 : i32
      %c31_i32_1942 = arith.constant 31 : i32
      %1152 = nvvm.shfl.sync  bfly %c-1_i32_1940, %1151, %c2_i32_1941, %c31_i32_1942 : f32 -> f32
      %1153 = nvvm.fmax %1151, %1152
      %c-1_i32_1943 = arith.constant -1 : i32
      %c1_i32_1944 = arith.constant 1 : i32
      %c31_i32_1945 = arith.constant 31 : i32
      %1154 = nvvm.shfl.sync  bfly %c-1_i32_1943, %1153, %c1_i32_1944, %c31_i32_1945 : f32 -> f32
      %1155 = nvvm.fmax %1153, %1154
      %1156 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %1157 = arith.mulf %1150, %1156 : vector<16xf32>
      %1158 = arith.mulf %1155, %arg4 : f32
      %1159 = vector.broadcast %1158 : f32 to vector<16xf32>
      %1160 = arith.subf %1157, %1159 : vector<16xf32>
      %1161 = math.exp2 %1160 fastmath<fast> : vector<16xf32>
      %cst_1946 = arith.constant 0.000000e+00 : f32
      %1162 = vector.reduction <add>, %1161, %cst_1946 : vector<16xf32> into f32
      %1163 = cute.static : !cute.coord<"3">
      cute.memref.store(%rmem_623, %1163, %1155) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      %1164 = cute.static : !cute.coord<"3">
      cute.memref.store(%rmem_624, %1164, %1162) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      %1165 = cute.static : !cute.int_tuple<"6">
      %iter_1947 = cute.get_iter(%1148) : !memref_rmem_f32_4
      %ptr_1948 = cute.add_offset(%iter_1947, %1165) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1949 = cute.make_view(%ptr_1948) : !memref_rmem_f32_6
      cute.memref.store_vec %1161, %view_1949 : !memref_rmem_f32_6
      %1166 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %rmem_1950 = cute.memref.alloca(%1166) : !memref_rmem_bf16_16
      %iter_1951 = cute.get_iter(%rmem_1950) : !memref_rmem_bf16_16
      %1167 = cute.memref.load_vec %rmem_628 : !memref_rmem_f32_2
      %1168 = arith.truncf %1167 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1168, %rmem_1950 : !memref_rmem_bf16_16
      %1169 = cute.static : !cute.layout<"(((2,2),2),2,4):(((1,2),8),4,16)">
      %view_1952 = cute.make_view(%iter_1951, %1169) : !memref_rmem_bf16_17
      %lay_1953 = cute.get_layout(%view_267) : !memref_smem_bf16_7
      %1170:2 = cute.get_scalars(%lay_1953) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %1171 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %iv_1954 = cute.assume(%1170#0) : (i32) -> !cute.i32<divby 16>
      %iv_1955 = cute.assume(%1170#1) : (i32) -> !cute.i32<divby 32>
      %stride_1956 = cute.make_stride(%iv_1954, %iv_1955) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_1957 = cute.make_layout(%1171, %stride_1956) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1172 = cute.static : !cute.int_tuple<"0">
      %iter_1958 = cute.get_iter(%view_267) : !memref_smem_bf16_7
      %ptr_1959 = cute.add_offset(%iter_1958, %1172) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_1960 = cute.make_view(%ptr_1959, %lay_1957) : !memref_smem_bf16_16
      %iter_1961 = cute.get_iter(%view_1960) : !memref_smem_bf16_16
      %1173 = cute.static : !cute.int_tuple<"0">
      %iter_1962 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
      %ptr_1963 = cute.add_offset(%iter_1962, %1173) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1964 = cute.make_view(%ptr_1963) : !memref_rmem_bf16_18
      %iter_1965 = cute.get_iter(%view_1964) : !memref_rmem_bf16_18
      %lay_1966 = cute.get_layout(%view_1960) : !memref_smem_bf16_16
      %1174 = cute.static : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_1966, %1174) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %view_1967 = cute.make_view(%iter_1961, %append) : !memref_smem_bf16_16
      %iter_1968 = cute.get_iter(%view_1967) : !memref_smem_bf16_16
      %lay_1969 = cute.get_layout(%view_1967) : !memref_smem_bf16_16
      %1175:2 = cute.get_scalars(%lay_1969) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1176 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %iv_1970 = cute.assume(%1175#0) : (i32) -> !cute.i32<divby 16>
      %iv_1971 = cute.assume(%1175#1) : (i32) -> !cute.i32<divby 32>
      %stride_1972 = cute.make_stride(%iv_1970, %iv_1971) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_1973 = cute.make_layout(%1176, %stride_1972) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %view_1974 = cute.make_view(%iter_1968, %lay_1973) : !memref_smem_bf16_17
      %1177 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
      %view_1975 = cute.make_view(%iter_1965, %1177) : !memref_rmem_bf16_18
      %iter_1976 = cute.get_iter(%view_1975) : !memref_rmem_bf16_18
      %view_1977 = cute.make_view(%iter_1976) : !memref_rmem_bf16_19
      %1178 = cute.static : !cute.layout<"1:0">
      %iter_1978 = cute.get_iter(%view_1974) : !memref_smem_bf16_17
      %iter_1979 = cute.get_iter(%view_1977) : !memref_rmem_bf16_19
      %lay_1980 = cute.get_layout(%view_1974) : !memref_smem_bf16_17
      %append_1981 = cute.append_to_rank<2> (%lay_1980, %1178) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1179:2 = cute.get_scalars(%append_1981) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %1180 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %iv_1982 = cute.assume(%1179#0) : (i32) -> !cute.i32<divby 16>
      %iv_1983 = cute.assume(%1179#1) : (i32) -> !cute.i32<divby 32>
      %stride_1984 = cute.make_stride(%iv_1982, %iv_1983) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_1985 = cute.make_layout(%1180, %stride_1984) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %1181 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %1182 = cute.static : !cute.int_tuple<"8">
      %1183 = cute.get_scalars(%1182) : !cute.int_tuple<"8">
      %c0_i32_1986 = arith.constant 0 : i32
      %c1_i32_1987 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_1986 to %1183 step %c1_i32_1987  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %lay_1985) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2578 = cute.add_offset(%iter_1978, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1181) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_1979, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %lay_1988 = cute.get_layout(%view_267) : !memref_smem_bf16_7
      %1184:2 = cute.get_scalars(%lay_1988) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %1185 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %iv_1989 = cute.assume(%1184#0) : (i32) -> !cute.i32<divby 16>
      %iv_1990 = cute.assume(%1184#1) : (i32) -> !cute.i32<divby 32>
      %stride_1991 = cute.make_stride(%iv_1989, %iv_1990) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_1992 = cute.make_layout(%1185, %stride_1991) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1186 = cute.static : !cute.int_tuple<"1024">
      %iter_1993 = cute.get_iter(%view_267) : !memref_smem_bf16_7
      %ptr_1994 = cute.add_offset(%iter_1993, %1186) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_1995 = cute.make_view(%ptr_1994, %lay_1992) : !memref_smem_bf16_16
      %iter_1996 = cute.get_iter(%view_1995) : !memref_smem_bf16_16
      %1187 = cute.static : !cute.int_tuple<"32">
      %iter_1997 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
      %ptr_1998 = cute.add_offset(%iter_1997, %1187) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_1999 = cute.make_view(%ptr_1998) : !memref_rmem_bf16_18
      %iter_2000 = cute.get_iter(%view_1999) : !memref_rmem_bf16_18
      %lay_2001 = cute.get_layout(%view_1995) : !memref_smem_bf16_16
      %1188 = cute.static : !cute.layout<"1:0">
      %append_2002 = cute.append_to_rank<2> (%lay_2001, %1188) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %view_2003 = cute.make_view(%iter_1996, %append_2002) : !memref_smem_bf16_16
      %iter_2004 = cute.get_iter(%view_2003) : !memref_smem_bf16_16
      %lay_2005 = cute.get_layout(%view_2003) : !memref_smem_bf16_16
      %1189:2 = cute.get_scalars(%lay_2005) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1190 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %iv_2006 = cute.assume(%1189#0) : (i32) -> !cute.i32<divby 16>
      %iv_2007 = cute.assume(%1189#1) : (i32) -> !cute.i32<divby 32>
      %stride_2008 = cute.make_stride(%iv_2006, %iv_2007) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_2009 = cute.make_layout(%1190, %stride_2008) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %view_2010 = cute.make_view(%iter_2004, %lay_2009) : !memref_smem_bf16_17
      %1191 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
      %view_2011 = cute.make_view(%iter_2000, %1191) : !memref_rmem_bf16_18
      %iter_2012 = cute.get_iter(%view_2011) : !memref_rmem_bf16_18
      %view_2013 = cute.make_view(%iter_2012) : !memref_rmem_bf16_19
      %1192 = cute.static : !cute.layout<"1:0">
      %iter_2014 = cute.get_iter(%view_2010) : !memref_smem_bf16_17
      %iter_2015 = cute.get_iter(%view_2013) : !memref_rmem_bf16_19
      %lay_2016 = cute.get_layout(%view_2010) : !memref_smem_bf16_17
      %append_2017 = cute.append_to_rank<2> (%lay_2016, %1192) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1193:2 = cute.get_scalars(%append_2017) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %1194 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %iv_2018 = cute.assume(%1193#0) : (i32) -> !cute.i32<divby 16>
      %iv_2019 = cute.assume(%1193#1) : (i32) -> !cute.i32<divby 32>
      %stride_2020 = cute.make_stride(%iv_2018, %iv_2019) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_2021 = cute.make_layout(%1194, %stride_2020) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %1195 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %1196 = cute.static : !cute.int_tuple<"8">
      %1197 = cute.get_scalars(%1196) : !cute.int_tuple<"8">
      %c0_i32_2022 = arith.constant 0 : i32
      %c1_i32_2023 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2022 to %1197 step %c1_i32_2023  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %lay_2021) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2578 = cute.add_offset(%iter_2014, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1195) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_2015, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %1198 = cute.static : !cute.int_tuple<"0">
      %iter_2024 = cute.get_iter(%view_1952) : !memref_rmem_bf16_17
      %ptr_2025 = cute.add_offset(%iter_2024, %1198) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_2026 = cute.make_view(%ptr_2025) : !memref_rmem_bf16_20
      %1199 = cute.static : !cute.int_tuple<"0">
      %iter_2027 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
      %ptr_2028 = cute.add_offset(%iter_2027, %1199) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2029 = cute.make_view(%ptr_2028) : !memref_rmem_bf16_21
      %iter_2030 = cute.get_iter(%view_2026) : !memref_rmem_bf16_20
      %iter_2031 = cute.get_iter(%view_2029) : !memref_rmem_bf16_21
      %iter_2032 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
      %1200 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %1201 = cute.static : !cute.layout<"1:0">
      %1202 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
      %1203 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %1204 = cute.static : !cute.int_tuple<"1">
      %1205 = cute.static : !cute.int_tuple<"2">
      %1206 = cute.static : !cute.int_tuple<"16">
      %1207 = cute.get_scalars(%1204) : !cute.int_tuple<"1">
      %1208 = cute.get_scalars(%1205) : !cute.int_tuple<"2">
      %1209 = cute.get_scalars(%1206) : !cute.int_tuple<"16">
      %c0_i32_2033 = arith.constant 0 : i32
      %c1_i32_2034 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2033 to %1207 step %c1_i32_2034  : i32 {
        scf.for %arg6 = %c0_i32_2033 to %1208 step %c1_i32_2034  : i32 {
          scf.for %arg7 = %c0_i32_2033 to %1209 step %c1_i32_2034  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
            %idx_2579 = cute.crd2idx(%coord_2576, %1202) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2580 = cute.add_offset(%iter_2030, %idx_2579) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_22
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %1203) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_2031, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %1200) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_2032, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_22
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[4] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[5] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %lay_2035 = cute.get_layout(%view_267) : !memref_smem_bf16_7
      %1210:2 = cute.get_scalars(%lay_2035) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %1211 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %iv_2036 = cute.assume(%1210#0) : (i32) -> !cute.i32<divby 16>
      %iv_2037 = cute.assume(%1210#1) : (i32) -> !cute.i32<divby 32>
      %stride_2038 = cute.make_stride(%iv_2036, %iv_2037) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_2039 = cute.make_layout(%1211, %stride_2038) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1212 = cute.static : !cute.int_tuple<"2048">
      %iter_2040 = cute.get_iter(%view_267) : !memref_smem_bf16_7
      %ptr_2041 = cute.add_offset(%iter_2040, %1212) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_2042 = cute.make_view(%ptr_2041, %lay_2039) : !memref_smem_bf16_16
      %iter_2043 = cute.get_iter(%view_2042) : !memref_smem_bf16_16
      %1213 = cute.static : !cute.int_tuple<"64">
      %iter_2044 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
      %ptr_2045 = cute.add_offset(%iter_2044, %1213) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2046 = cute.make_view(%ptr_2045) : !memref_rmem_bf16_18
      %iter_2047 = cute.get_iter(%view_2046) : !memref_rmem_bf16_18
      %lay_2048 = cute.get_layout(%view_2042) : !memref_smem_bf16_16
      %1214 = cute.static : !cute.layout<"1:0">
      %append_2049 = cute.append_to_rank<2> (%lay_2048, %1214) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %view_2050 = cute.make_view(%iter_2043, %append_2049) : !memref_smem_bf16_16
      %iter_2051 = cute.get_iter(%view_2050) : !memref_smem_bf16_16
      %lay_2052 = cute.get_layout(%view_2050) : !memref_smem_bf16_16
      %1215:2 = cute.get_scalars(%lay_2052) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1216 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %iv_2053 = cute.assume(%1215#0) : (i32) -> !cute.i32<divby 16>
      %iv_2054 = cute.assume(%1215#1) : (i32) -> !cute.i32<divby 32>
      %stride_2055 = cute.make_stride(%iv_2053, %iv_2054) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_2056 = cute.make_layout(%1216, %stride_2055) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %view_2057 = cute.make_view(%iter_2051, %lay_2056) : !memref_smem_bf16_17
      %1217 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
      %view_2058 = cute.make_view(%iter_2047, %1217) : !memref_rmem_bf16_18
      %iter_2059 = cute.get_iter(%view_2058) : !memref_rmem_bf16_18
      %view_2060 = cute.make_view(%iter_2059) : !memref_rmem_bf16_19
      %1218 = cute.static : !cute.layout<"1:0">
      %iter_2061 = cute.get_iter(%view_2057) : !memref_smem_bf16_17
      %iter_2062 = cute.get_iter(%view_2060) : !memref_rmem_bf16_19
      %lay_2063 = cute.get_layout(%view_2057) : !memref_smem_bf16_17
      %append_2064 = cute.append_to_rank<2> (%lay_2063, %1218) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1219:2 = cute.get_scalars(%append_2064) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %1220 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %iv_2065 = cute.assume(%1219#0) : (i32) -> !cute.i32<divby 16>
      %iv_2066 = cute.assume(%1219#1) : (i32) -> !cute.i32<divby 32>
      %stride_2067 = cute.make_stride(%iv_2065, %iv_2066) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_2068 = cute.make_layout(%1220, %stride_2067) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %1221 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %1222 = cute.static : !cute.int_tuple<"8">
      %1223 = cute.get_scalars(%1222) : !cute.int_tuple<"8">
      %c0_i32_2069 = arith.constant 0 : i32
      %c1_i32_2070 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2069 to %1223 step %c1_i32_2070  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %lay_2068) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2578 = cute.add_offset(%iter_2061, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1221) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_2062, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %1224 = cute.static : !cute.int_tuple<"16">
      %iter_2071 = cute.get_iter(%view_1952) : !memref_rmem_bf16_17
      %ptr_2072 = cute.add_offset(%iter_2071, %1224) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_2073 = cute.make_view(%ptr_2072) : !memref_rmem_bf16_20
      %1225 = cute.static : !cute.int_tuple<"32">
      %iter_2074 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
      %ptr_2075 = cute.add_offset(%iter_2074, %1225) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2076 = cute.make_view(%ptr_2075) : !memref_rmem_bf16_21
      %iter_2077 = cute.get_iter(%view_2073) : !memref_rmem_bf16_20
      %iter_2078 = cute.get_iter(%view_2076) : !memref_rmem_bf16_21
      %iter_2079 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
      %1226 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %1227 = cute.static : !cute.layout<"1:0">
      %1228 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
      %1229 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %1230 = cute.static : !cute.int_tuple<"1">
      %1231 = cute.static : !cute.int_tuple<"2">
      %1232 = cute.static : !cute.int_tuple<"16">
      %1233 = cute.get_scalars(%1230) : !cute.int_tuple<"1">
      %1234 = cute.get_scalars(%1231) : !cute.int_tuple<"2">
      %1235 = cute.get_scalars(%1232) : !cute.int_tuple<"16">
      %c0_i32_2080 = arith.constant 0 : i32
      %c1_i32_2081 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2080 to %1233 step %c1_i32_2081  : i32 {
        scf.for %arg6 = %c0_i32_2080 to %1234 step %c1_i32_2081  : i32 {
          scf.for %arg7 = %c0_i32_2080 to %1235 step %c1_i32_2081  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
            %idx_2579 = cute.crd2idx(%coord_2576, %1228) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2580 = cute.add_offset(%iter_2077, %idx_2579) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_22
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %1229) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_2078, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %1226) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_2079, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_22
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[4] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[5] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %lay_2082 = cute.get_layout(%view_267) : !memref_smem_bf16_7
      %1236:2 = cute.get_scalars(%lay_2082) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %1237 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %iv_2083 = cute.assume(%1236#0) : (i32) -> !cute.i32<divby 16>
      %iv_2084 = cute.assume(%1236#1) : (i32) -> !cute.i32<divby 32>
      %stride_2085 = cute.make_stride(%iv_2083, %iv_2084) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_2086 = cute.make_layout(%1237, %stride_2085) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1238 = cute.static : !cute.int_tuple<"3072">
      %iter_2087 = cute.get_iter(%view_267) : !memref_smem_bf16_7
      %ptr_2088 = cute.add_offset(%iter_2087, %1238) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_2089 = cute.make_view(%ptr_2088, %lay_2086) : !memref_smem_bf16_16
      %iter_2090 = cute.get_iter(%view_2089) : !memref_smem_bf16_16
      %1239 = cute.static : !cute.int_tuple<"96">
      %iter_2091 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
      %ptr_2092 = cute.add_offset(%iter_2091, %1239) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2093 = cute.make_view(%ptr_2092) : !memref_rmem_bf16_18
      %iter_2094 = cute.get_iter(%view_2093) : !memref_rmem_bf16_18
      %lay_2095 = cute.get_layout(%view_2089) : !memref_smem_bf16_16
      %1240 = cute.static : !cute.layout<"1:0">
      %append_2096 = cute.append_to_rank<2> (%lay_2095, %1240) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %view_2097 = cute.make_view(%iter_2090, %append_2096) : !memref_smem_bf16_16
      %iter_2098 = cute.get_iter(%view_2097) : !memref_smem_bf16_16
      %lay_2099 = cute.get_layout(%view_2097) : !memref_smem_bf16_16
      %1241:2 = cute.get_scalars(%lay_2099) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1242 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %iv_2100 = cute.assume(%1241#0) : (i32) -> !cute.i32<divby 16>
      %iv_2101 = cute.assume(%1241#1) : (i32) -> !cute.i32<divby 32>
      %stride_2102 = cute.make_stride(%iv_2100, %iv_2101) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_2103 = cute.make_layout(%1242, %stride_2102) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %view_2104 = cute.make_view(%iter_2098, %lay_2103) : !memref_smem_bf16_17
      %1243 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
      %view_2105 = cute.make_view(%iter_2094, %1243) : !memref_rmem_bf16_18
      %iter_2106 = cute.get_iter(%view_2105) : !memref_rmem_bf16_18
      %view_2107 = cute.make_view(%iter_2106) : !memref_rmem_bf16_19
      %1244 = cute.static : !cute.layout<"1:0">
      %iter_2108 = cute.get_iter(%view_2104) : !memref_smem_bf16_17
      %iter_2109 = cute.get_iter(%view_2107) : !memref_rmem_bf16_19
      %lay_2110 = cute.get_layout(%view_2104) : !memref_smem_bf16_17
      %append_2111 = cute.append_to_rank<2> (%lay_2110, %1244) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1245:2 = cute.get_scalars(%append_2111) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %1246 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %iv_2112 = cute.assume(%1245#0) : (i32) -> !cute.i32<divby 16>
      %iv_2113 = cute.assume(%1245#1) : (i32) -> !cute.i32<divby 32>
      %stride_2114 = cute.make_stride(%iv_2112, %iv_2113) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_2115 = cute.make_layout(%1246, %stride_2114) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %1247 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %1248 = cute.static : !cute.int_tuple<"8">
      %1249 = cute.get_scalars(%1248) : !cute.int_tuple<"8">
      %c0_i32_2116 = arith.constant 0 : i32
      %c1_i32_2117 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2116 to %1249 step %c1_i32_2117  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %lay_2115) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2578 = cute.add_offset(%iter_2108, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1247) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_2109, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %1250 = cute.static : !cute.int_tuple<"32">
      %iter_2118 = cute.get_iter(%view_1952) : !memref_rmem_bf16_17
      %ptr_2119 = cute.add_offset(%iter_2118, %1250) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_2120 = cute.make_view(%ptr_2119) : !memref_rmem_bf16_20
      %1251 = cute.static : !cute.int_tuple<"64">
      %iter_2121 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
      %ptr_2122 = cute.add_offset(%iter_2121, %1251) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2123 = cute.make_view(%ptr_2122) : !memref_rmem_bf16_21
      %iter_2124 = cute.get_iter(%view_2120) : !memref_rmem_bf16_20
      %iter_2125 = cute.get_iter(%view_2123) : !memref_rmem_bf16_21
      %iter_2126 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
      %1252 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %1253 = cute.static : !cute.layout<"1:0">
      %1254 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
      %1255 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %1256 = cute.static : !cute.int_tuple<"1">
      %1257 = cute.static : !cute.int_tuple<"2">
      %1258 = cute.static : !cute.int_tuple<"16">
      %1259 = cute.get_scalars(%1256) : !cute.int_tuple<"1">
      %1260 = cute.get_scalars(%1257) : !cute.int_tuple<"2">
      %1261 = cute.get_scalars(%1258) : !cute.int_tuple<"16">
      %c0_i32_2127 = arith.constant 0 : i32
      %c1_i32_2128 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2127 to %1259 step %c1_i32_2128  : i32 {
        scf.for %arg6 = %c0_i32_2127 to %1260 step %c1_i32_2128  : i32 {
          scf.for %arg7 = %c0_i32_2127 to %1261 step %c1_i32_2128  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
            %idx_2579 = cute.crd2idx(%coord_2576, %1254) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2580 = cute.add_offset(%iter_2124, %idx_2579) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_22
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %1255) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_2125, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %1252) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_2126, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_22
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[4] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[5] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %lay_2129 = cute.get_layout(%view_267) : !memref_smem_bf16_7
      %1262:2 = cute.get_scalars(%lay_2129) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %1263 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %iv_2130 = cute.assume(%1262#0) : (i32) -> !cute.i32<divby 16>
      %iv_2131 = cute.assume(%1262#1) : (i32) -> !cute.i32<divby 32>
      %stride_2132 = cute.make_stride(%iv_2130, %iv_2131) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_2133 = cute.make_layout(%1263, %stride_2132) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1264 = cute.static : !cute.int_tuple<"0">
      %iter_2134 = cute.get_iter(%view_267) : !memref_smem_bf16_7
      %ptr_2135 = cute.add_offset(%iter_2134, %1264) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
      %view_2136 = cute.make_view(%ptr_2135, %lay_2133) : !memref_smem_bf16_16
      %iter_2137 = cute.get_iter(%view_2136) : !memref_smem_bf16_16
      %1265 = cute.static : !cute.int_tuple<"0">
      %iter_2138 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
      %ptr_2139 = cute.add_offset(%iter_2138, %1265) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2140 = cute.make_view(%ptr_2139) : !memref_rmem_bf16_18
      %iter_2141 = cute.get_iter(%view_2140) : !memref_rmem_bf16_18
      %lay_2142 = cute.get_layout(%view_2136) : !memref_smem_bf16_16
      %1266 = cute.static : !cute.layout<"1:0">
      %append_2143 = cute.append_to_rank<2> (%lay_2142, %1266) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %view_2144 = cute.make_view(%iter_2137, %append_2143) : !memref_smem_bf16_16
      %iter_2145 = cute.get_iter(%view_2144) : !memref_smem_bf16_16
      %lay_2146 = cute.get_layout(%view_2144) : !memref_smem_bf16_16
      %1267:2 = cute.get_scalars(%lay_2146) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %1268 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %iv_2147 = cute.assume(%1267#0) : (i32) -> !cute.i32<divby 16>
      %iv_2148 = cute.assume(%1267#1) : (i32) -> !cute.i32<divby 32>
      %stride_2149 = cute.make_stride(%iv_2147, %iv_2148) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_2150 = cute.make_layout(%1268, %stride_2149) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %view_2151 = cute.make_view(%iter_2145, %lay_2150) : !memref_smem_bf16_17
      %1269 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
      %view_2152 = cute.make_view(%iter_2141, %1269) : !memref_rmem_bf16_18
      %iter_2153 = cute.get_iter(%view_2152) : !memref_rmem_bf16_18
      %view_2154 = cute.make_view(%iter_2153) : !memref_rmem_bf16_19
      %1270 = cute.static : !cute.layout<"1:0">
      %iter_2155 = cute.get_iter(%view_2151) : !memref_smem_bf16_17
      %iter_2156 = cute.get_iter(%view_2154) : !memref_rmem_bf16_19
      %lay_2157 = cute.get_layout(%view_2151) : !memref_smem_bf16_17
      %append_2158 = cute.append_to_rank<2> (%lay_2157, %1270) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1271:2 = cute.get_scalars(%append_2158) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %1272 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %iv_2159 = cute.assume(%1271#0) : (i32) -> !cute.i32<divby 16>
      %iv_2160 = cute.assume(%1271#1) : (i32) -> !cute.i32<divby 32>
      %stride_2161 = cute.make_stride(%iv_2159, %iv_2160) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_2162 = cute.make_layout(%1272, %stride_2161) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %1273 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %1274 = cute.static : !cute.int_tuple<"8">
      %1275 = cute.get_scalars(%1274) : !cute.int_tuple<"8">
      %c0_i32_2163 = arith.constant 0 : i32
      %c1_i32_2164 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2163 to %1275 step %c1_i32_2164  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %lay_2162) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2578 = cute.add_offset(%iter_2155, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1273) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_2156, %idx_2580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_11
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_11
        %swizzled = cute.apply_swizzle(%iter_2583) : !cute.ptr<bf16, smem, align<16>>
        %1584 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
        %1585 = llvm.mlir.constant(0 : i32) : i32
        %1586 = vector.extractelement %1584[%1585 : i32] : vector<4xi32>
        %1587 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1586, %1587 : i32, !llvm.ptr
        %1588 = llvm.mlir.constant(1 : i32) : i32
        %1589 = vector.extractelement %1584[%1588 : i32] : vector<4xi32>
        %1590 = cute.static : !cute.int_tuple<"2">
        %ptr_2585 = cute.add_offset(%iter_2584, %1590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2585 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1589, %1591 : i32, !llvm.ptr
        %1592 = llvm.mlir.constant(2 : i32) : i32
        %1593 = vector.extractelement %1584[%1592 : i32] : vector<4xi32>
        %1594 = cute.static : !cute.int_tuple<"4">
        %ptr_2586 = cute.add_offset(%iter_2584, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        llvm.store %1593, %1595 : i32, !llvm.ptr
        %1596 = llvm.mlir.constant(3 : i32) : i32
        %1597 = vector.extractelement %1584[%1596 : i32] : vector<4xi32>
        %1598 = cute.static : !cute.int_tuple<"6">
        %ptr_2587 = cute.add_offset(%iter_2584, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1599 = builtin.unrealized_conversion_cast %ptr_2587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        llvm.store %1597, %1599 : i32, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %1276 = cute.static : !cute.int_tuple<"48">
      %iter_2165 = cute.get_iter(%view_1952) : !memref_rmem_bf16_17
      %ptr_2166 = cute.add_offset(%iter_2165, %1276) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_2167 = cute.make_view(%ptr_2166) : !memref_rmem_bf16_20
      %1277 = cute.static : !cute.int_tuple<"96">
      %iter_2168 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
      %ptr_2169 = cute.add_offset(%iter_2168, %1277) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      %view_2170 = cute.make_view(%ptr_2169) : !memref_rmem_bf16_21
      %iter_2171 = cute.get_iter(%view_2167) : !memref_rmem_bf16_20
      %iter_2172 = cute.get_iter(%view_2170) : !memref_rmem_bf16_21
      %iter_2173 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
      %1278 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %1279 = cute.static : !cute.layout<"1:0">
      %1280 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
      %1281 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %1282 = cute.static : !cute.int_tuple<"1">
      %1283 = cute.static : !cute.int_tuple<"2">
      %1284 = cute.static : !cute.int_tuple<"16">
      %1285 = cute.get_scalars(%1282) : !cute.int_tuple<"1">
      %1286 = cute.get_scalars(%1283) : !cute.int_tuple<"2">
      %1287 = cute.get_scalars(%1284) : !cute.int_tuple<"16">
      %c0_i32_2174 = arith.constant 0 : i32
      %c1_i32_2175 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2174 to %1285 step %c1_i32_2175  : i32 {
        scf.for %arg6 = %c0_i32_2174 to %1286 step %c1_i32_2175  : i32 {
          scf.for %arg7 = %c0_i32_2174 to %1287 step %c1_i32_2175  : i32 {
            %coord_2576 = cute.make_coord(%arg6, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2577 = cute.make_coord(%arg7, %arg5) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %coord_2578 = cute.make_coord(%arg6, %arg7) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %1582 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
            %idx_2579 = cute.crd2idx(%coord_2576, %1280) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2580 = cute.add_offset(%iter_2171, %idx_2579) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2581 = cute.make_view(%ptr_2580, %1582) : !memref_rmem_bf16_22
            %1583 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2582 = cute.crd2idx(%coord_2577, %1281) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2583 = cute.add_offset(%iter_2172, %idx_2582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %view_2584 = cute.make_view(%ptr_2583, %1583) : !memref_rmem_bf16_15
            %1584 = cute.static : !cute.layout<"((2,2)):((1,2))">
            %idx_2585 = cute.crd2idx(%coord_2578, %1278) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
            %ptr_2586 = cute.add_offset(%iter_2173, %idx_2585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
            %view_2587 = cute.make_view(%ptr_2586, %1584) : !memref_rmem_f32_3
            %iter_2588 = cute.get_iter(%view_2581) : !memref_rmem_bf16_22
            %iter_2589 = cute.get_iter(%view_2584) : !memref_rmem_bf16_15
            %iter_2590 = cute.get_iter(%view_2587) : !memref_rmem_f32_3
            %1585 = builtin.unrealized_conversion_cast %iter_2588 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1586 = llvm.load %1585 : !llvm.ptr -> i32
            %1587 = llvm.getelementptr %1585[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1588 = llvm.load %1587 : !llvm.ptr -> i32
            %1589 = llvm.getelementptr %1585[4] : (!llvm.ptr) -> !llvm.ptr, i32
            %1590 = llvm.load %1589 : !llvm.ptr -> i32
            %1591 = llvm.getelementptr %1585[5] : (!llvm.ptr) -> !llvm.ptr, i32
            %1592 = llvm.load %1591 : !llvm.ptr -> i32
            %1593 = builtin.unrealized_conversion_cast %iter_2589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
            %1594 = llvm.load %1593 : !llvm.ptr -> i32
            %1595 = llvm.getelementptr %1593[1] : (!llvm.ptr) -> !llvm.ptr, i32
            %1596 = llvm.load %1595 : !llvm.ptr -> i32
            %1597 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %1598 = llvm.load %1597 : !llvm.ptr -> f32
            %1599 = llvm.getelementptr %1597[1] : (!llvm.ptr) -> !llvm.ptr, f32
            %1600 = llvm.load %1599 : !llvm.ptr -> f32
            %1601 = llvm.getelementptr %1597[2] : (!llvm.ptr) -> !llvm.ptr, f32
            %1602 = llvm.load %1601 : !llvm.ptr -> f32
            %1603 = llvm.getelementptr %1597[3] : (!llvm.ptr) -> !llvm.ptr, f32
            %1604 = llvm.load %1603 : !llvm.ptr -> f32
            %1605:4 = cute_nvgpu.arch.mma.SM80 A[%1586, %1588, %1590, %1592]  B[%1594, %1596]  C[%1598, %1600, %1602, %1604] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
            %1606 = builtin.unrealized_conversion_cast %iter_2590 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            llvm.store %1605#0, %1606 : f32, !llvm.ptr
            %1607 = llvm.getelementptr %1606[1] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#1, %1607 : f32, !llvm.ptr
            %1608 = llvm.getelementptr %1606[2] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#2, %1608 : f32, !llvm.ptr
            %1609 = llvm.getelementptr %1606[3] : (!llvm.ptr) -> !llvm.ptr, f32
            llvm.store %1605#3, %1609 : f32, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      } {llvm.loop_annotation = #loop_annotation}
      %c1_i32_2176 = arith.constant 1 : i32
      %1288:7 = scf.for %arg5 = %c1_i32_2176 to %31 step %c1_i32_2176 iter_args(%arg6 = %363, %arg7 = %24, %arg8 = %363, %arg9 = %arg0, %arg10 = %arg1, %arg11 = %25, %arg12 = %26) -> (i32, i32, i32, !memref_gmem_bf16_, !memref_gmem_bf16_, i32, i32)  : i32 {
        %1582 = arith.subi %31, %arg5 : i32
        %c1_i32_2576 = arith.constant 1 : i32
        %1583 = arith.subi %1582, %c1_i32_2576 : i32
        %1584 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %rmem_2577 = cute.memref.alloca(%1584) : !memref_rmem_f32_2
        %iter_2578 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %cst_2579 = arith.constant 0.000000e+00 : f32
        %1585 = vector.splat %cst_2579 : vector<64xf32>
        cute.memref.store_vec %1585, %rmem_2577 : !memref_rmem_f32_2
        nvvm.cp.async.wait.group 0
        %c1_i32_2580 = arith.constant 1 : i32
        %c128_i32_2581 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_2580 number_of_threads = %c128_i32_2581
        %false_2582 = arith.constant false
        scf.if %false_2582 {
          %2105 = cute.static : !cute.int_tuple<"(0,0,0,0)">
          %iter_3336 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
          %tup_3337 = cute.add_offset(%iter_3336, %2105) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %view_3338 = cute.make_view(%tup_3337) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %iter_3339 = cute.get_iter(%view_3338) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_3340, %e1_3341, %e2_3342, %e3_3343 = cute.get_leaves(%iter_3339) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_3344 = cute.get_layout(%arg10) : !memref_gmem_bf16_
          %2106 = cute.get_shape(%lay_3344) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_3345, %e1_3346, %e2_3347, %e3_3348 = cute.get_leaves(%2106) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_3349 = cute.to_int_tuple(%e1_3346) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_3350 = cute.make_coord(%e1_3341) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3351 = cute.make_coord(%itup_3349) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2107 = cute.get_scalars(%coord_3350) : !cute.coord<"?">
          %2108 = cute.get_scalars(%coord_3351) : !cute.coord<"?">
          %true_3352 = arith.constant true
          %2109 = arith.cmpi slt, %2107, %2108 : i32
          %2110 = arith.andi %true_3352, %2109 : i1
          scf.if %2110 {
            %coord_3404 = cute.make_coord(%1583) : (i32) -> !cute.coord<"(_,0,_,?)">
            %lay_3405 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
            %idx_3406 = cute.crd2idx(%coord_3404, %lay_3405) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
            %iter_3407 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
            %ptr_3408 = cute.add_offset(%iter_3407, %idx_3406) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3409 = cute.make_view(%ptr_3408) : !memref_gmem_bf16_6
            %iter_3410 = cute.get_iter(%view_3409) : !memref_gmem_bf16_6
            %2129 = cute.static : !cute.int_tuple<"0">
            %iter_3411 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3412 = cute.add_offset(%iter_3411, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3413 = cute.make_view(%ptr_3412) : !memref_smem_bf16_11
            %iter_3414 = cute.get_iter(%view_3413) : !memref_smem_bf16_11
            %2130 = cute.static : !cute.int_tuple<"0">
            %iter_3415 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
            %ptr_3416 = cute.add_offset(%iter_3415, %2130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_3417 = cute.make_view(%ptr_3416) : !memref_rmem_i8_2
            %iter_3418 = cute.get_iter(%view_3417) : !memref_rmem_i8_2
            %2131 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
            %view_3419 = cute.make_view(%iter_3410, %2131) : !memref_gmem_bf16_6
            %iter_3420 = cute.get_iter(%view_3419) : !memref_gmem_bf16_6
            %view_3421 = cute.make_view(%iter_3420) : !memref_gmem_bf16_7
            %2132 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
            %view_3422 = cute.make_view(%iter_3414, %2132) : !memref_smem_bf16_11
            %iter_3423 = cute.get_iter(%view_3422) : !memref_smem_bf16_11
            %view_3424 = cute.make_view(%iter_3423) : !memref_smem_bf16_12
            %2133 = cute.static : !cute.layout<"(1,2):(2,1)">
            %view_3425 = cute.make_view(%iter_3418, %2133) : !memref_rmem_i8_2
            %iter_3426 = cute.get_iter(%view_3425) : !memref_rmem_i8_2
            %view_3427 = cute.make_view(%iter_3426) : !memref_rmem_i8_3
            %2134 = cute.static : !cute.layout<"1:0">
            %iter_3428 = cute.get_iter(%view_3421) : !memref_gmem_bf16_7
            %iter_3429 = cute.get_iter(%view_3424) : !memref_smem_bf16_12
            %2135 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %2136 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %iter_3430 = cute.get_iter(%view_3427) : !memref_rmem_i8_3
            %2137 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
            %2138 = cute.static : !cute.int_tuple<"2">
            %2139 = cute.get_scalars(%2138) : !cute.int_tuple<"2">
            %c0_i32_3431 = arith.constant 0 : i32
            %c1_i32_3432 = arith.constant 1 : i32
            scf.for %arg13 = %c0_i32_3431 to %2139 step %c1_i32_3432  : i32 {
              %coord_3433 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
              %2140 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3434 = cute.crd2idx(%coord_3433, %2135) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_3435 = cute.add_offset(%iter_3428, %idx_3434) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %view_3436 = cute.make_view(%ptr_3435, %2140) : !memref_gmem_bf16_8
              %2141 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3437 = cute.crd2idx(%coord_3433, %2136) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_3438 = cute.add_offset(%iter_3429, %idx_3437) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %view_3439 = cute.make_view(%ptr_3438, %2141) : !memref_smem_bf16_10
              %2142 = cute.static : !cute.layout<"(1):(2)">
              %idx_3440 = cute.crd2idx(%coord_3433, %2137) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_3441 = cute.add_offset(%iter_3430, %idx_3440) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %view_3442 = cute.make_view(%ptr_3441, %2142) : !memref_rmem_i8_4
              %iter_3443 = cute.get_iter(%view_3436) : !memref_gmem_bf16_8
              %iter_3444 = cute.get_iter(%view_3439) : !memref_smem_bf16_10
              %iter_3445 = cute.get_iter(%view_3442) : !memref_rmem_i8_4
              %2143 = builtin.unrealized_conversion_cast %iter_3445 : !cute.ptr<i8, rmem> to !llvm.ptr
              %2144 = llvm.load %2143 : !llvm.ptr -> i8
              %2145 = llvm.trunc %2144 : i8 to i1
              %iter_3446 = cute.recast_iter(%iter_3443) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_3447 = cute.recast_iter(%iter_3444) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_3447 : !cute.ptr<i128, smem>, %iter_3446 : !cute.ptr<i128, gmem>, %2145 : i1) {cache_mode = <global>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %2129 = cute.static : !cute.int_tuple<"0">
            %iter_3404 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3405 = cute.add_offset(%iter_3404, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3406 = cute.make_view(%ptr_3405) : !memref_smem_bf16_11
            %cst_3407 = arith.constant 0.000000e+00 : bf16
            %2130 = vector.splat %cst_3407 : vector<16xbf16>
            cute.memref.store_vec %2130, %view_3406 : !memref_smem_bf16_11
          }
          %2111 = cute.static : !cute.int_tuple<"(0,16,0,0)">
          %iter_3353 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
          %tup_3354 = cute.add_offset(%iter_3353, %2111) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %view_3355 = cute.make_view(%tup_3354) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %iter_3356 = cute.get_iter(%view_3355) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_3357, %e1_3358, %e2_3359, %e3_3360 = cute.get_leaves(%iter_3356) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_3361 = cute.get_layout(%arg10) : !memref_gmem_bf16_
          %2112 = cute.get_shape(%lay_3361) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_3362, %e1_3363, %e2_3364, %e3_3365 = cute.get_leaves(%2112) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_3366 = cute.to_int_tuple(%e1_3363) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_3367 = cute.make_coord(%e1_3358) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3368 = cute.make_coord(%itup_3366) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2113 = cute.get_scalars(%coord_3367) : !cute.coord<"?">
          %2114 = cute.get_scalars(%coord_3368) : !cute.coord<"?">
          %true_3369 = arith.constant true
          %2115 = arith.cmpi slt, %2113, %2114 : i32
          %2116 = arith.andi %true_3369, %2115 : i1
          scf.if %2116 {
            %coord_3404 = cute.make_coord(%1583) : (i32) -> !cute.coord<"(_,1,_,?)">
            %lay_3405 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
            %idx_3406 = cute.crd2idx(%coord_3404, %lay_3405) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %iter_3407 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
            %ptr_3408 = cute.add_offset(%iter_3407, %idx_3406) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3409 = cute.make_view(%ptr_3408) : !memref_gmem_bf16_6
            %iter_3410 = cute.get_iter(%view_3409) : !memref_gmem_bf16_6
            %2129 = cute.static : !cute.int_tuple<"1024">
            %iter_3411 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3412 = cute.add_offset(%iter_3411, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3413 = cute.make_view(%ptr_3412) : !memref_smem_bf16_11
            %iter_3414 = cute.get_iter(%view_3413) : !memref_smem_bf16_11
            %2130 = cute.static : !cute.int_tuple<"0">
            %iter_3415 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
            %ptr_3416 = cute.add_offset(%iter_3415, %2130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_3417 = cute.make_view(%ptr_3416) : !memref_rmem_i8_2
            %iter_3418 = cute.get_iter(%view_3417) : !memref_rmem_i8_2
            %2131 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
            %view_3419 = cute.make_view(%iter_3410, %2131) : !memref_gmem_bf16_6
            %iter_3420 = cute.get_iter(%view_3419) : !memref_gmem_bf16_6
            %view_3421 = cute.make_view(%iter_3420) : !memref_gmem_bf16_7
            %2132 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
            %view_3422 = cute.make_view(%iter_3414, %2132) : !memref_smem_bf16_11
            %iter_3423 = cute.get_iter(%view_3422) : !memref_smem_bf16_11
            %view_3424 = cute.make_view(%iter_3423) : !memref_smem_bf16_12
            %2133 = cute.static : !cute.layout<"(1,2):(2,1)">
            %view_3425 = cute.make_view(%iter_3418, %2133) : !memref_rmem_i8_2
            %iter_3426 = cute.get_iter(%view_3425) : !memref_rmem_i8_2
            %view_3427 = cute.make_view(%iter_3426) : !memref_rmem_i8_3
            %2134 = cute.static : !cute.layout<"1:0">
            %iter_3428 = cute.get_iter(%view_3421) : !memref_gmem_bf16_7
            %iter_3429 = cute.get_iter(%view_3424) : !memref_smem_bf16_12
            %2135 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %2136 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %iter_3430 = cute.get_iter(%view_3427) : !memref_rmem_i8_3
            %2137 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
            %2138 = cute.static : !cute.int_tuple<"2">
            %2139 = cute.get_scalars(%2138) : !cute.int_tuple<"2">
            %c0_i32_3431 = arith.constant 0 : i32
            %c1_i32_3432 = arith.constant 1 : i32
            scf.for %arg13 = %c0_i32_3431 to %2139 step %c1_i32_3432  : i32 {
              %coord_3433 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
              %2140 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3434 = cute.crd2idx(%coord_3433, %2135) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_3435 = cute.add_offset(%iter_3428, %idx_3434) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %view_3436 = cute.make_view(%ptr_3435, %2140) : !memref_gmem_bf16_8
              %2141 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3437 = cute.crd2idx(%coord_3433, %2136) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_3438 = cute.add_offset(%iter_3429, %idx_3437) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %view_3439 = cute.make_view(%ptr_3438, %2141) : !memref_smem_bf16_10
              %2142 = cute.static : !cute.layout<"(1):(2)">
              %idx_3440 = cute.crd2idx(%coord_3433, %2137) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_3441 = cute.add_offset(%iter_3430, %idx_3440) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %view_3442 = cute.make_view(%ptr_3441, %2142) : !memref_rmem_i8_4
              %iter_3443 = cute.get_iter(%view_3436) : !memref_gmem_bf16_8
              %iter_3444 = cute.get_iter(%view_3439) : !memref_smem_bf16_10
              %iter_3445 = cute.get_iter(%view_3442) : !memref_rmem_i8_4
              %2143 = builtin.unrealized_conversion_cast %iter_3445 : !cute.ptr<i8, rmem> to !llvm.ptr
              %2144 = llvm.load %2143 : !llvm.ptr -> i8
              %2145 = llvm.trunc %2144 : i8 to i1
              %iter_3446 = cute.recast_iter(%iter_3443) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_3447 = cute.recast_iter(%iter_3444) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_3447 : !cute.ptr<i128, smem>, %iter_3446 : !cute.ptr<i128, gmem>, %2145 : i1) {cache_mode = <global>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %2129 = cute.static : !cute.int_tuple<"1024">
            %iter_3404 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3405 = cute.add_offset(%iter_3404, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3406 = cute.make_view(%ptr_3405) : !memref_smem_bf16_11
            %cst_3407 = arith.constant 0.000000e+00 : bf16
            %2130 = vector.splat %cst_3407 : vector<16xbf16>
            cute.memref.store_vec %2130, %view_3406 : !memref_smem_bf16_11
          }
          %2117 = cute.static : !cute.int_tuple<"(0,32,0,0)">
          %iter_3370 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
          %tup_3371 = cute.add_offset(%iter_3370, %2117) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %view_3372 = cute.make_view(%tup_3371) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %iter_3373 = cute.get_iter(%view_3372) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_3374, %e1_3375, %e2_3376, %e3_3377 = cute.get_leaves(%iter_3373) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_3378 = cute.get_layout(%arg10) : !memref_gmem_bf16_
          %2118 = cute.get_shape(%lay_3378) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_3379, %e1_3380, %e2_3381, %e3_3382 = cute.get_leaves(%2118) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_3383 = cute.to_int_tuple(%e1_3380) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_3384 = cute.make_coord(%e1_3375) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3385 = cute.make_coord(%itup_3383) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2119 = cute.get_scalars(%coord_3384) : !cute.coord<"?">
          %2120 = cute.get_scalars(%coord_3385) : !cute.coord<"?">
          %true_3386 = arith.constant true
          %2121 = arith.cmpi slt, %2119, %2120 : i32
          %2122 = arith.andi %true_3386, %2121 : i1
          scf.if %2122 {
            %coord_3404 = cute.make_coord(%1583) : (i32) -> !cute.coord<"(_,2,_,?)">
            %lay_3405 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
            %idx_3406 = cute.crd2idx(%coord_3404, %lay_3405) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
            %iter_3407 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
            %ptr_3408 = cute.add_offset(%iter_3407, %idx_3406) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3409 = cute.make_view(%ptr_3408) : !memref_gmem_bf16_6
            %iter_3410 = cute.get_iter(%view_3409) : !memref_gmem_bf16_6
            %2129 = cute.static : !cute.int_tuple<"2048">
            %iter_3411 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3412 = cute.add_offset(%iter_3411, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3413 = cute.make_view(%ptr_3412) : !memref_smem_bf16_11
            %iter_3414 = cute.get_iter(%view_3413) : !memref_smem_bf16_11
            %2130 = cute.static : !cute.int_tuple<"0">
            %iter_3415 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
            %ptr_3416 = cute.add_offset(%iter_3415, %2130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_3417 = cute.make_view(%ptr_3416) : !memref_rmem_i8_2
            %iter_3418 = cute.get_iter(%view_3417) : !memref_rmem_i8_2
            %2131 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
            %view_3419 = cute.make_view(%iter_3410, %2131) : !memref_gmem_bf16_6
            %iter_3420 = cute.get_iter(%view_3419) : !memref_gmem_bf16_6
            %view_3421 = cute.make_view(%iter_3420) : !memref_gmem_bf16_7
            %2132 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
            %view_3422 = cute.make_view(%iter_3414, %2132) : !memref_smem_bf16_11
            %iter_3423 = cute.get_iter(%view_3422) : !memref_smem_bf16_11
            %view_3424 = cute.make_view(%iter_3423) : !memref_smem_bf16_12
            %2133 = cute.static : !cute.layout<"(1,2):(2,1)">
            %view_3425 = cute.make_view(%iter_3418, %2133) : !memref_rmem_i8_2
            %iter_3426 = cute.get_iter(%view_3425) : !memref_rmem_i8_2
            %view_3427 = cute.make_view(%iter_3426) : !memref_rmem_i8_3
            %2134 = cute.static : !cute.layout<"1:0">
            %iter_3428 = cute.get_iter(%view_3421) : !memref_gmem_bf16_7
            %iter_3429 = cute.get_iter(%view_3424) : !memref_smem_bf16_12
            %2135 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %2136 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %iter_3430 = cute.get_iter(%view_3427) : !memref_rmem_i8_3
            %2137 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
            %2138 = cute.static : !cute.int_tuple<"2">
            %2139 = cute.get_scalars(%2138) : !cute.int_tuple<"2">
            %c0_i32_3431 = arith.constant 0 : i32
            %c1_i32_3432 = arith.constant 1 : i32
            scf.for %arg13 = %c0_i32_3431 to %2139 step %c1_i32_3432  : i32 {
              %coord_3433 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
              %2140 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3434 = cute.crd2idx(%coord_3433, %2135) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_3435 = cute.add_offset(%iter_3428, %idx_3434) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %view_3436 = cute.make_view(%ptr_3435, %2140) : !memref_gmem_bf16_8
              %2141 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3437 = cute.crd2idx(%coord_3433, %2136) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_3438 = cute.add_offset(%iter_3429, %idx_3437) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %view_3439 = cute.make_view(%ptr_3438, %2141) : !memref_smem_bf16_10
              %2142 = cute.static : !cute.layout<"(1):(2)">
              %idx_3440 = cute.crd2idx(%coord_3433, %2137) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_3441 = cute.add_offset(%iter_3430, %idx_3440) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %view_3442 = cute.make_view(%ptr_3441, %2142) : !memref_rmem_i8_4
              %iter_3443 = cute.get_iter(%view_3436) : !memref_gmem_bf16_8
              %iter_3444 = cute.get_iter(%view_3439) : !memref_smem_bf16_10
              %iter_3445 = cute.get_iter(%view_3442) : !memref_rmem_i8_4
              %2143 = builtin.unrealized_conversion_cast %iter_3445 : !cute.ptr<i8, rmem> to !llvm.ptr
              %2144 = llvm.load %2143 : !llvm.ptr -> i8
              %2145 = llvm.trunc %2144 : i8 to i1
              %iter_3446 = cute.recast_iter(%iter_3443) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_3447 = cute.recast_iter(%iter_3444) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_3447 : !cute.ptr<i128, smem>, %iter_3446 : !cute.ptr<i128, gmem>, %2145 : i1) {cache_mode = <global>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %2129 = cute.static : !cute.int_tuple<"2048">
            %iter_3404 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3405 = cute.add_offset(%iter_3404, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3406 = cute.make_view(%ptr_3405) : !memref_smem_bf16_11
            %cst_3407 = arith.constant 0.000000e+00 : bf16
            %2130 = vector.splat %cst_3407 : vector<16xbf16>
            cute.memref.store_vec %2130, %view_3406 : !memref_smem_bf16_11
          }
          %2123 = cute.static : !cute.int_tuple<"(0,48,0,0)">
          %iter_3387 = cute.get_iter(%view_348) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
          %tup_3388 = cute.add_offset(%iter_3387, %2123) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %view_3389 = cute.make_view(%tup_3388) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %iter_3390 = cute.get_iter(%view_3389) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %e0_3391, %e1_3392, %e2_3393, %e3_3394 = cute.get_leaves(%iter_3390) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_3395 = cute.get_layout(%arg10) : !memref_gmem_bf16_
          %2124 = cute.get_shape(%lay_3395) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_3396, %e1_3397, %e2_3398, %e3_3399 = cute.get_leaves(%2124) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_3400 = cute.to_int_tuple(%e1_3397) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_3401 = cute.make_coord(%e1_3392) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_3402 = cute.make_coord(%itup_3400) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2125 = cute.get_scalars(%coord_3401) : !cute.coord<"?">
          %2126 = cute.get_scalars(%coord_3402) : !cute.coord<"?">
          %true_3403 = arith.constant true
          %2127 = arith.cmpi slt, %2125, %2126 : i32
          %2128 = arith.andi %true_3403, %2127 : i1
          scf.if %2128 {
            %coord_3404 = cute.make_coord(%1583) : (i32) -> !cute.coord<"(_,3,_,?)">
            %lay_3405 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
            %idx_3406 = cute.crd2idx(%coord_3404, %lay_3405) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %iter_3407 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
            %ptr_3408 = cute.add_offset(%iter_3407, %idx_3406) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3409 = cute.make_view(%ptr_3408) : !memref_gmem_bf16_6
            %iter_3410 = cute.get_iter(%view_3409) : !memref_gmem_bf16_6
            %2129 = cute.static : !cute.int_tuple<"3072">
            %iter_3411 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3412 = cute.add_offset(%iter_3411, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3413 = cute.make_view(%ptr_3412) : !memref_smem_bf16_11
            %iter_3414 = cute.get_iter(%view_3413) : !memref_smem_bf16_11
            %2130 = cute.static : !cute.int_tuple<"0">
            %iter_3415 = cute.get_iter(%rmem_350) : !memref_rmem_i8_1
            %ptr_3416 = cute.add_offset(%iter_3415, %2130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_3417 = cute.make_view(%ptr_3416) : !memref_rmem_i8_2
            %iter_3418 = cute.get_iter(%view_3417) : !memref_rmem_i8_2
            %2131 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
            %view_3419 = cute.make_view(%iter_3410, %2131) : !memref_gmem_bf16_6
            %iter_3420 = cute.get_iter(%view_3419) : !memref_gmem_bf16_6
            %view_3421 = cute.make_view(%iter_3420) : !memref_gmem_bf16_7
            %2132 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
            %view_3422 = cute.make_view(%iter_3414, %2132) : !memref_smem_bf16_11
            %iter_3423 = cute.get_iter(%view_3422) : !memref_smem_bf16_11
            %view_3424 = cute.make_view(%iter_3423) : !memref_smem_bf16_12
            %2133 = cute.static : !cute.layout<"(1,2):(2,1)">
            %view_3425 = cute.make_view(%iter_3418, %2133) : !memref_rmem_i8_2
            %iter_3426 = cute.get_iter(%view_3425) : !memref_rmem_i8_2
            %view_3427 = cute.make_view(%iter_3426) : !memref_rmem_i8_3
            %2134 = cute.static : !cute.layout<"1:0">
            %iter_3428 = cute.get_iter(%view_3421) : !memref_gmem_bf16_7
            %iter_3429 = cute.get_iter(%view_3424) : !memref_smem_bf16_12
            %2135 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %2136 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %iter_3430 = cute.get_iter(%view_3427) : !memref_rmem_i8_3
            %2137 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
            %2138 = cute.static : !cute.int_tuple<"2">
            %2139 = cute.get_scalars(%2138) : !cute.int_tuple<"2">
            %c0_i32_3431 = arith.constant 0 : i32
            %c1_i32_3432 = arith.constant 1 : i32
            scf.for %arg13 = %c0_i32_3431 to %2139 step %c1_i32_3432  : i32 {
              %coord_3433 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
              %2140 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3434 = cute.crd2idx(%coord_3433, %2135) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_3435 = cute.add_offset(%iter_3428, %idx_3434) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %view_3436 = cute.make_view(%ptr_3435, %2140) : !memref_gmem_bf16_8
              %2141 = cute.static : !cute.layout<"((8,1)):((1,0))">
              %idx_3437 = cute.crd2idx(%coord_3433, %2136) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_3438 = cute.add_offset(%iter_3429, %idx_3437) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %view_3439 = cute.make_view(%ptr_3438, %2141) : !memref_smem_bf16_10
              %2142 = cute.static : !cute.layout<"(1):(2)">
              %idx_3440 = cute.crd2idx(%coord_3433, %2137) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_3441 = cute.add_offset(%iter_3430, %idx_3440) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %view_3442 = cute.make_view(%ptr_3441, %2142) : !memref_rmem_i8_4
              %iter_3443 = cute.get_iter(%view_3436) : !memref_gmem_bf16_8
              %iter_3444 = cute.get_iter(%view_3439) : !memref_smem_bf16_10
              %iter_3445 = cute.get_iter(%view_3442) : !memref_rmem_i8_4
              %2143 = builtin.unrealized_conversion_cast %iter_3445 : !cute.ptr<i8, rmem> to !llvm.ptr
              %2144 = llvm.load %2143 : !llvm.ptr -> i8
              %2145 = llvm.trunc %2144 : i8 to i1
              %iter_3446 = cute.recast_iter(%iter_3443) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_3447 = cute.recast_iter(%iter_3444) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_3447 : !cute.ptr<i128, smem>, %iter_3446 : !cute.ptr<i128, gmem>, %2145 : i1) {cache_mode = <global>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %2129 = cute.static : !cute.int_tuple<"3072">
            %iter_3404 = cute.get_iter(%view_179) : !memref_smem_bf16_4
            %ptr_3405 = cute.add_offset(%iter_3404, %2129) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3406 = cute.make_view(%ptr_3405) : !memref_smem_bf16_11
            %cst_3407 = arith.constant 0.000000e+00 : bf16
            %2130 = vector.splat %cst_3407 : vector<16xbf16>
            cute.memref.store_vec %2130, %view_3406 : !memref_smem_bf16_11
          }
        } else {
          %coord_3336 = cute.make_coord(%1583) : (i32) -> !cute.coord<"(_,_,_,?)">
          %lay_3337 = cute.get_layout(%view_162) : !memref_gmem_bf16_5
          %2105:3 = cute.get_scalars(%lay_3337) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %2106 = cute.static : !cute.shape<"((8,1),4,2)">
          %iv_3338 = cute.assume(%2105#1) : (i64) -> !cute.i64<divby 128>
          %stride_3339 = cute.make_stride(%iv_3338) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_3340 = cute.make_layout(%2106, %stride_3339) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_3341 = cute.crd2idx(%coord_3336, %lay_3337) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %iter_3342 = cute.get_iter(%view_162) : !memref_gmem_bf16_5
          %ptr_3343 = cute.add_offset(%iter_3342, %idx_3341) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_3344 = cute.make_view(%ptr_3343, %lay_3340) : !memref_gmem_bf16_9
          %iter_3345 = cute.get_iter(%view_3344) : !memref_gmem_bf16_9
          %lay_3346 = cute.get_layout(%view_3344) : !memref_gmem_bf16_9
          %2107 = cute.static : !cute.layout<"1:0">
          %append_3347 = cute.append_to_rank<2> (%lay_3346, %2107) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_3348 = cute.make_view(%iter_3345, %append_3347) : !memref_gmem_bf16_9
          %iter_3349 = cute.get_iter(%view_3348) : !memref_gmem_bf16_9
          %lay_3350 = cute.get_layout(%view_3348) : !memref_gmem_bf16_9
          %2108 = cute.get_scalars(%lay_3350) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %2109 = cute.static : !cute.shape<"((8,1),(4,2))">
          %iv_3351 = cute.assume(%2108) : (i64) -> !cute.i64<divby 128>
          %stride_3352 = cute.make_stride(%iv_3351) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_3353 = cute.make_layout(%2109, %stride_3352) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %view_3354 = cute.make_view(%iter_3349, %lay_3353) : !memref_gmem_bf16_10
          %2110 = cute.static : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
          %view_3355 = cute.make_view(%iter_180, %2110) : !memref_smem_bf16_4
          %iter_3356 = cute.get_iter(%view_3355) : !memref_smem_bf16_4
          %view_3357 = cute.make_view(%iter_3356) : !memref_smem_bf16_13
          %2111 = cute.static : !cute.layout<"(1,4,2):(2,0,1)">
          %view_3358 = cute.make_view(%iter_351, %2111) : !memref_rmem_i8_1
          %iter_3359 = cute.get_iter(%view_3358) : !memref_rmem_i8_1
          %view_3360 = cute.make_view(%iter_3359) : !memref_rmem_i8_5
          %2112 = cute.static : !cute.layout<"1:0">
          %iter_3361 = cute.get_iter(%view_3354) : !memref_gmem_bf16_10
          %iter_3362 = cute.get_iter(%view_3357) : !memref_smem_bf16_13
          %lay_3363 = cute.get_layout(%view_3354) : !memref_gmem_bf16_10
          %append_3364 = cute.append_to_rank<2> (%lay_3363, %2112) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %2113 = cute.get_scalars(%append_3364) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %2114 = cute.static : !cute.shape<"((8,1),((4,2)))">
          %iv_3365 = cute.assume(%2113) : (i64) -> !cute.i64<divby 128>
          %stride_3366 = cute.make_stride(%iv_3365) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_3367 = cute.make_layout(%2114, %stride_3366) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %2115 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
          %iter_3368 = cute.get_iter(%view_3360) : !memref_rmem_i8_5
          %2116 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
          %2117 = cute.static : !cute.int_tuple<"8">
          %2118 = cute.get_scalars(%2117) : !cute.int_tuple<"8">
          %c0_i32_3369 = arith.constant 0 : i32
          %c1_i32_3370 = arith.constant 1 : i32
          scf.for %arg13 = %c0_i32_3369 to %2118 step %c1_i32_3370  : i32 {
            %coord_3371 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
            %2119 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_3372 = cute.crd2idx(%coord_3371, %lay_3367) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_3373 = cute.add_offset(%iter_3361, %idx_3372) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3374 = cute.make_view(%ptr_3373, %2119) : !memref_gmem_bf16_8
            %2120 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_3375 = cute.crd2idx(%coord_3371, %2115) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_3376 = cute.add_offset(%iter_3362, %idx_3375) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3377 = cute.make_view(%ptr_3376, %2120) : !memref_smem_bf16_10
            %2121 = cute.static : !cute.layout<"(1):(2)">
            %idx_3378 = cute.crd2idx(%coord_3371, %2116) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_3379 = cute.add_offset(%iter_3368, %idx_3378) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_3380 = cute.make_view(%ptr_3379, %2121) : !memref_rmem_i8_4
            %iter_3381 = cute.get_iter(%view_3374) : !memref_gmem_bf16_8
            %iter_3382 = cute.get_iter(%view_3377) : !memref_smem_bf16_10
            %iter_3383 = cute.get_iter(%view_3380) : !memref_rmem_i8_4
            %2122 = builtin.unrealized_conversion_cast %iter_3383 : !cute.ptr<i8, rmem> to !llvm.ptr
            %2123 = llvm.load %2122 : !llvm.ptr -> i8
            %2124 = llvm.trunc %2123 : i8 to i1
            %iter_3384 = cute.recast_iter(%iter_3381) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_3385 = cute.recast_iter(%iter_3382) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_3385 : !cute.ptr<i128, smem>, %iter_3384 : !cute.ptr<i128, gmem>, %2124 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %1586 = cute.static : !cute.int_tuple<"0">
        %iter_2583 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2584 = cute.add_offset(%iter_2583, %1586) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2585 = cute.make_view(%ptr_2584) : !memref_smem_bf16_11
        %iter_2586 = cute.get_iter(%view_2585) : !memref_smem_bf16_11
        %1587 = cute.static : !cute.int_tuple<"0">
        %iter_2587 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2588 = cute.add_offset(%iter_2587, %1587) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2589 = cute.make_view(%ptr_2588) : !memref_rmem_bf16_6
        %iter_2590 = cute.get_iter(%view_2589) : !memref_rmem_bf16_6
        %1588 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2591 = cute.make_view(%iter_2586, %1588) : !memref_smem_bf16_11
        %iter_2592 = cute.get_iter(%view_2591) : !memref_smem_bf16_11
        %view_2593 = cute.make_view(%iter_2592) : !memref_smem_bf16_12
        %1589 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2594 = cute.make_view(%iter_2590, %1589) : !memref_rmem_bf16_6
        %iter_2595 = cute.get_iter(%view_2594) : !memref_rmem_bf16_6
        %view_2596 = cute.make_view(%iter_2595) : !memref_rmem_bf16_7
        %1590 = cute.static : !cute.layout<"1:0">
        %iter_2597 = cute.get_iter(%view_2593) : !memref_smem_bf16_12
        %iter_2598 = cute.get_iter(%view_2596) : !memref_rmem_bf16_7
        %1591 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1592 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1593 = cute.static : !cute.int_tuple<"2">
        %1594 = cute.get_scalars(%1593) : !cute.int_tuple<"2">
        %c0_i32_2599 = arith.constant 0 : i32
        %c1_i32_2600 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2599 to %1594 step %c1_i32_2600  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2597, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1592) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2598, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1595 = cute.static : !cute.int_tuple<"0">
        %iter_2601 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2602 = cute.add_offset(%iter_2601, %1595) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2603 = cute.make_view(%ptr_2602) : !memref_smem_bf16_14
        %iter_2604 = cute.get_iter(%view_2603) : !memref_smem_bf16_14
        %1596 = cute.static : !cute.int_tuple<"0">
        %iter_2605 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2606 = cute.add_offset(%iter_2605, %1596) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2607 = cute.make_view(%ptr_2606) : !memref_rmem_bf16_9
        %iter_2608 = cute.get_iter(%view_2607) : !memref_rmem_bf16_9
        %1597 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2609 = cute.make_view(%iter_2604, %1597) : !memref_smem_bf16_14
        %iter_2610 = cute.get_iter(%view_2609) : !memref_smem_bf16_14
        %view_2611 = cute.make_view(%iter_2610) : !memref_smem_bf16_15
        %1598 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2612 = cute.make_view(%iter_2608, %1598) : !memref_rmem_bf16_9
        %iter_2613 = cute.get_iter(%view_2612) : !memref_rmem_bf16_9
        %view_2614 = cute.make_view(%iter_2613) : !memref_rmem_bf16_10
        %1599 = cute.static : !cute.layout<"1:0">
        %iter_2615 = cute.get_iter(%view_2611) : !memref_smem_bf16_15
        %iter_2616 = cute.get_iter(%view_2614) : !memref_rmem_bf16_10
        %1600 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1601 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1602 = cute.static : !cute.int_tuple<"4">
        %1603 = cute.get_scalars(%1602) : !cute.int_tuple<"4">
        %c0_i32_2617 = arith.constant 0 : i32
        %c1_i32_2618 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2617 to %1603 step %c1_i32_2618  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1600) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2615, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1601) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2616, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1604 = cute.static : !cute.coord<"(_,_,1)">
        %lay_2619 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2620 = cute.crd2idx(%1604, %lay_2619) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2621 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2622 = cute.add_offset(%iter_2621, %idx_2620) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2623 = cute.make_view(%ptr_2622) : !memref_smem_bf16_11
        %iter_2624 = cute.get_iter(%view_2623) : !memref_smem_bf16_11
        %1605 = cute.static : !cute.int_tuple<"32">
        %iter_2625 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2626 = cute.add_offset(%iter_2625, %1605) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2627 = cute.make_view(%ptr_2626) : !memref_rmem_bf16_6
        %iter_2628 = cute.get_iter(%view_2627) : !memref_rmem_bf16_6
        %1606 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2629 = cute.make_view(%iter_2624, %1606) : !memref_smem_bf16_11
        %iter_2630 = cute.get_iter(%view_2629) : !memref_smem_bf16_11
        %view_2631 = cute.make_view(%iter_2630) : !memref_smem_bf16_12
        %1607 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2632 = cute.make_view(%iter_2628, %1607) : !memref_rmem_bf16_6
        %iter_2633 = cute.get_iter(%view_2632) : !memref_rmem_bf16_6
        %view_2634 = cute.make_view(%iter_2633) : !memref_rmem_bf16_7
        %1608 = cute.static : !cute.layout<"1:0">
        %iter_2635 = cute.get_iter(%view_2631) : !memref_smem_bf16_12
        %iter_2636 = cute.get_iter(%view_2634) : !memref_rmem_bf16_7
        %1609 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1610 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1611 = cute.static : !cute.int_tuple<"2">
        %1612 = cute.get_scalars(%1611) : !cute.int_tuple<"2">
        %c0_i32_2637 = arith.constant 0 : i32
        %c1_i32_2638 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2637 to %1612 step %c1_i32_2638  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1609) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2635, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1610) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2636, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1613 = cute.static : !cute.coord<"(_,_,1)">
        %lay_2639 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2640 = cute.crd2idx(%1613, %lay_2639) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2641 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2642 = cute.add_offset(%iter_2641, %idx_2640) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2643 = cute.make_view(%ptr_2642) : !memref_smem_bf16_14
        %iter_2644 = cute.get_iter(%view_2643) : !memref_smem_bf16_14
        %1614 = cute.static : !cute.int_tuple<"64">
        %iter_2645 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2646 = cute.add_offset(%iter_2645, %1614) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2647 = cute.make_view(%ptr_2646) : !memref_rmem_bf16_9
        %iter_2648 = cute.get_iter(%view_2647) : !memref_rmem_bf16_9
        %1615 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2649 = cute.make_view(%iter_2644, %1615) : !memref_smem_bf16_14
        %iter_2650 = cute.get_iter(%view_2649) : !memref_smem_bf16_14
        %view_2651 = cute.make_view(%iter_2650) : !memref_smem_bf16_15
        %1616 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2652 = cute.make_view(%iter_2648, %1616) : !memref_rmem_bf16_9
        %iter_2653 = cute.get_iter(%view_2652) : !memref_rmem_bf16_9
        %view_2654 = cute.make_view(%iter_2653) : !memref_rmem_bf16_10
        %1617 = cute.static : !cute.layout<"1:0">
        %iter_2655 = cute.get_iter(%view_2651) : !memref_smem_bf16_15
        %iter_2656 = cute.get_iter(%view_2654) : !memref_rmem_bf16_10
        %1618 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1619 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1620 = cute.static : !cute.int_tuple<"4">
        %1621 = cute.get_scalars(%1620) : !cute.int_tuple<"4">
        %c0_i32_2657 = arith.constant 0 : i32
        %c1_i32_2658 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2657 to %1621 step %c1_i32_2658  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1618) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2655, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1619) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2656, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1622 = cute.static : !cute.int_tuple<"0">
        %iter_2659 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2660 = cute.add_offset(%iter_2659, %1622) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2661 = cute.make_view(%ptr_2660) : !memref_rmem_bf16_12
        %1623 = cute.static : !cute.int_tuple<"0">
        %iter_2662 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2663 = cute.add_offset(%iter_2662, %1623) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2664 = cute.make_view(%ptr_2663) : !memref_rmem_bf16_13
        %iter_2665 = cute.get_iter(%view_2661) : !memref_rmem_bf16_12
        %iter_2666 = cute.get_iter(%view_2664) : !memref_rmem_bf16_13
        %iter_2667 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1624 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1625 = cute.static : !cute.layout<"1:0">
        %1626 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1627 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1628 = cute.static : !cute.int_tuple<"1">
        %1629 = cute.static : !cute.int_tuple<"2">
        %1630 = cute.static : !cute.int_tuple<"8">
        %1631 = cute.get_scalars(%1628) : !cute.int_tuple<"1">
        %1632 = cute.get_scalars(%1629) : !cute.int_tuple<"2">
        %1633 = cute.get_scalars(%1630) : !cute.int_tuple<"8">
        %c0_i32_2668 = arith.constant 0 : i32
        %c1_i32_2669 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2668 to %1631 step %c1_i32_2669  : i32 {
          scf.for %arg14 = %c0_i32_2668 to %1632 step %c1_i32_2669  : i32 {
            scf.for %arg15 = %c0_i32_2668 to %1633 step %c1_i32_2669  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1626) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2665, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1627) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2666, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1624) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2667, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1634 = cute.static : !cute.coord<"(_,_,2)">
        %lay_2670 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2671 = cute.crd2idx(%1634, %lay_2670) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
        %iter_2672 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2673 = cute.add_offset(%iter_2672, %idx_2671) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2674 = cute.make_view(%ptr_2673) : !memref_smem_bf16_11
        %iter_2675 = cute.get_iter(%view_2674) : !memref_smem_bf16_11
        %1635 = cute.static : !cute.int_tuple<"64">
        %iter_2676 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2677 = cute.add_offset(%iter_2676, %1635) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2678 = cute.make_view(%ptr_2677) : !memref_rmem_bf16_6
        %iter_2679 = cute.get_iter(%view_2678) : !memref_rmem_bf16_6
        %1636 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2680 = cute.make_view(%iter_2675, %1636) : !memref_smem_bf16_11
        %iter_2681 = cute.get_iter(%view_2680) : !memref_smem_bf16_11
        %view_2682 = cute.make_view(%iter_2681) : !memref_smem_bf16_12
        %1637 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2683 = cute.make_view(%iter_2679, %1637) : !memref_rmem_bf16_6
        %iter_2684 = cute.get_iter(%view_2683) : !memref_rmem_bf16_6
        %view_2685 = cute.make_view(%iter_2684) : !memref_rmem_bf16_7
        %1638 = cute.static : !cute.layout<"1:0">
        %iter_2686 = cute.get_iter(%view_2682) : !memref_smem_bf16_12
        %iter_2687 = cute.get_iter(%view_2685) : !memref_rmem_bf16_7
        %1639 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1640 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1641 = cute.static : !cute.int_tuple<"2">
        %1642 = cute.get_scalars(%1641) : !cute.int_tuple<"2">
        %c0_i32_2688 = arith.constant 0 : i32
        %c1_i32_2689 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2688 to %1642 step %c1_i32_2689  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1639) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2686, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1640) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2687, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1643 = cute.static : !cute.coord<"(_,_,2)">
        %lay_2690 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2691 = cute.crd2idx(%1643, %lay_2690) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %iter_2692 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2693 = cute.add_offset(%iter_2692, %idx_2691) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2694 = cute.make_view(%ptr_2693) : !memref_smem_bf16_14
        %iter_2695 = cute.get_iter(%view_2694) : !memref_smem_bf16_14
        %1644 = cute.static : !cute.int_tuple<"128">
        %iter_2696 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2697 = cute.add_offset(%iter_2696, %1644) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2698 = cute.make_view(%ptr_2697) : !memref_rmem_bf16_9
        %iter_2699 = cute.get_iter(%view_2698) : !memref_rmem_bf16_9
        %1645 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2700 = cute.make_view(%iter_2695, %1645) : !memref_smem_bf16_14
        %iter_2701 = cute.get_iter(%view_2700) : !memref_smem_bf16_14
        %view_2702 = cute.make_view(%iter_2701) : !memref_smem_bf16_15
        %1646 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2703 = cute.make_view(%iter_2699, %1646) : !memref_rmem_bf16_9
        %iter_2704 = cute.get_iter(%view_2703) : !memref_rmem_bf16_9
        %view_2705 = cute.make_view(%iter_2704) : !memref_rmem_bf16_10
        %1647 = cute.static : !cute.layout<"1:0">
        %iter_2706 = cute.get_iter(%view_2702) : !memref_smem_bf16_15
        %iter_2707 = cute.get_iter(%view_2705) : !memref_rmem_bf16_10
        %1648 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1649 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1650 = cute.static : !cute.int_tuple<"4">
        %1651 = cute.get_scalars(%1650) : !cute.int_tuple<"4">
        %c0_i32_2708 = arith.constant 0 : i32
        %c1_i32_2709 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2708 to %1651 step %c1_i32_2709  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1648) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2706, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1649) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2707, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1652 = cute.static : !cute.int_tuple<"32">
        %iter_2710 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2711 = cute.add_offset(%iter_2710, %1652) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2712 = cute.make_view(%ptr_2711) : !memref_rmem_bf16_12
        %1653 = cute.static : !cute.int_tuple<"64">
        %iter_2713 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2714 = cute.add_offset(%iter_2713, %1653) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2715 = cute.make_view(%ptr_2714) : !memref_rmem_bf16_13
        %iter_2716 = cute.get_iter(%view_2712) : !memref_rmem_bf16_12
        %iter_2717 = cute.get_iter(%view_2715) : !memref_rmem_bf16_13
        %iter_2718 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1654 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1655 = cute.static : !cute.layout<"1:0">
        %1656 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1657 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1658 = cute.static : !cute.int_tuple<"1">
        %1659 = cute.static : !cute.int_tuple<"2">
        %1660 = cute.static : !cute.int_tuple<"8">
        %1661 = cute.get_scalars(%1658) : !cute.int_tuple<"1">
        %1662 = cute.get_scalars(%1659) : !cute.int_tuple<"2">
        %1663 = cute.get_scalars(%1660) : !cute.int_tuple<"8">
        %c0_i32_2719 = arith.constant 0 : i32
        %c1_i32_2720 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2719 to %1661 step %c1_i32_2720  : i32 {
          scf.for %arg14 = %c0_i32_2719 to %1662 step %c1_i32_2720  : i32 {
            scf.for %arg15 = %c0_i32_2719 to %1663 step %c1_i32_2720  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1656) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2716, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1657) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2717, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1654) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2718, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1664 = cute.static : !cute.coord<"(_,_,3)">
        %lay_2721 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2722 = cute.crd2idx(%1664, %lay_2721) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2723 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2724 = cute.add_offset(%iter_2723, %idx_2722) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2725 = cute.make_view(%ptr_2724) : !memref_smem_bf16_11
        %iter_2726 = cute.get_iter(%view_2725) : !memref_smem_bf16_11
        %1665 = cute.static : !cute.int_tuple<"96">
        %iter_2727 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2728 = cute.add_offset(%iter_2727, %1665) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2729 = cute.make_view(%ptr_2728) : !memref_rmem_bf16_6
        %iter_2730 = cute.get_iter(%view_2729) : !memref_rmem_bf16_6
        %1666 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2731 = cute.make_view(%iter_2726, %1666) : !memref_smem_bf16_11
        %iter_2732 = cute.get_iter(%view_2731) : !memref_smem_bf16_11
        %view_2733 = cute.make_view(%iter_2732) : !memref_smem_bf16_12
        %1667 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2734 = cute.make_view(%iter_2730, %1667) : !memref_rmem_bf16_6
        %iter_2735 = cute.get_iter(%view_2734) : !memref_rmem_bf16_6
        %view_2736 = cute.make_view(%iter_2735) : !memref_rmem_bf16_7
        %1668 = cute.static : !cute.layout<"1:0">
        %iter_2737 = cute.get_iter(%view_2733) : !memref_smem_bf16_12
        %iter_2738 = cute.get_iter(%view_2736) : !memref_rmem_bf16_7
        %1669 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1670 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1671 = cute.static : !cute.int_tuple<"2">
        %1672 = cute.get_scalars(%1671) : !cute.int_tuple<"2">
        %c0_i32_2739 = arith.constant 0 : i32
        %c1_i32_2740 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2739 to %1672 step %c1_i32_2740  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1669) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2737, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1670) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2738, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1673 = cute.static : !cute.coord<"(_,_,3)">
        %lay_2741 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2742 = cute.crd2idx(%1673, %lay_2741) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2743 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2744 = cute.add_offset(%iter_2743, %idx_2742) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2745 = cute.make_view(%ptr_2744) : !memref_smem_bf16_14
        %iter_2746 = cute.get_iter(%view_2745) : !memref_smem_bf16_14
        %1674 = cute.static : !cute.int_tuple<"192">
        %iter_2747 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2748 = cute.add_offset(%iter_2747, %1674) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2749 = cute.make_view(%ptr_2748) : !memref_rmem_bf16_9
        %iter_2750 = cute.get_iter(%view_2749) : !memref_rmem_bf16_9
        %1675 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2751 = cute.make_view(%iter_2746, %1675) : !memref_smem_bf16_14
        %iter_2752 = cute.get_iter(%view_2751) : !memref_smem_bf16_14
        %view_2753 = cute.make_view(%iter_2752) : !memref_smem_bf16_15
        %1676 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2754 = cute.make_view(%iter_2750, %1676) : !memref_rmem_bf16_9
        %iter_2755 = cute.get_iter(%view_2754) : !memref_rmem_bf16_9
        %view_2756 = cute.make_view(%iter_2755) : !memref_rmem_bf16_10
        %1677 = cute.static : !cute.layout<"1:0">
        %iter_2757 = cute.get_iter(%view_2753) : !memref_smem_bf16_15
        %iter_2758 = cute.get_iter(%view_2756) : !memref_rmem_bf16_10
        %1678 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1679 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1680 = cute.static : !cute.int_tuple<"4">
        %1681 = cute.get_scalars(%1680) : !cute.int_tuple<"4">
        %c0_i32_2759 = arith.constant 0 : i32
        %c1_i32_2760 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2759 to %1681 step %c1_i32_2760  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1678) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2757, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1679) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2758, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1682 = cute.static : !cute.int_tuple<"64">
        %iter_2761 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2762 = cute.add_offset(%iter_2761, %1682) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2763 = cute.make_view(%ptr_2762) : !memref_rmem_bf16_12
        %1683 = cute.static : !cute.int_tuple<"128">
        %iter_2764 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2765 = cute.add_offset(%iter_2764, %1683) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2766 = cute.make_view(%ptr_2765) : !memref_rmem_bf16_13
        %iter_2767 = cute.get_iter(%view_2763) : !memref_rmem_bf16_12
        %iter_2768 = cute.get_iter(%view_2766) : !memref_rmem_bf16_13
        %iter_2769 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1684 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1685 = cute.static : !cute.layout<"1:0">
        %1686 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1687 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1688 = cute.static : !cute.int_tuple<"1">
        %1689 = cute.static : !cute.int_tuple<"2">
        %1690 = cute.static : !cute.int_tuple<"8">
        %1691 = cute.get_scalars(%1688) : !cute.int_tuple<"1">
        %1692 = cute.get_scalars(%1689) : !cute.int_tuple<"2">
        %1693 = cute.get_scalars(%1690) : !cute.int_tuple<"8">
        %c0_i32_2770 = arith.constant 0 : i32
        %c1_i32_2771 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2770 to %1691 step %c1_i32_2771  : i32 {
          scf.for %arg14 = %c0_i32_2770 to %1692 step %c1_i32_2771  : i32 {
            scf.for %arg15 = %c0_i32_2770 to %1693 step %c1_i32_2771  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1686) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2767, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1687) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2768, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1684) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2769, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1694 = cute.static : !cute.int_tuple<"8192">
        %iter_2772 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2773 = cute.add_offset(%iter_2772, %1694) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2774 = cute.make_view(%ptr_2773) : !memref_smem_bf16_11
        %iter_2775 = cute.get_iter(%view_2774) : !memref_smem_bf16_11
        %1695 = cute.static : !cute.int_tuple<"16">
        %iter_2776 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2777 = cute.add_offset(%iter_2776, %1695) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2778 = cute.make_view(%ptr_2777) : !memref_rmem_bf16_6
        %iter_2779 = cute.get_iter(%view_2778) : !memref_rmem_bf16_6
        %1696 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2780 = cute.make_view(%iter_2775, %1696) : !memref_smem_bf16_11
        %iter_2781 = cute.get_iter(%view_2780) : !memref_smem_bf16_11
        %view_2782 = cute.make_view(%iter_2781) : !memref_smem_bf16_12
        %1697 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2783 = cute.make_view(%iter_2779, %1697) : !memref_rmem_bf16_6
        %iter_2784 = cute.get_iter(%view_2783) : !memref_rmem_bf16_6
        %view_2785 = cute.make_view(%iter_2784) : !memref_rmem_bf16_7
        %1698 = cute.static : !cute.layout<"1:0">
        %iter_2786 = cute.get_iter(%view_2782) : !memref_smem_bf16_12
        %iter_2787 = cute.get_iter(%view_2785) : !memref_rmem_bf16_7
        %1699 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1700 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1701 = cute.static : !cute.int_tuple<"2">
        %1702 = cute.get_scalars(%1701) : !cute.int_tuple<"2">
        %c0_i32_2788 = arith.constant 0 : i32
        %c1_i32_2789 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2788 to %1702 step %c1_i32_2789  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1699) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2786, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1700) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2787, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1703 = cute.static : !cute.int_tuple<"4096">
        %iter_2790 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2791 = cute.add_offset(%iter_2790, %1703) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2792 = cute.make_view(%ptr_2791) : !memref_smem_bf16_14
        %iter_2793 = cute.get_iter(%view_2792) : !memref_smem_bf16_14
        %1704 = cute.static : !cute.int_tuple<"32">
        %iter_2794 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2795 = cute.add_offset(%iter_2794, %1704) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2796 = cute.make_view(%ptr_2795) : !memref_rmem_bf16_9
        %iter_2797 = cute.get_iter(%view_2796) : !memref_rmem_bf16_9
        %1705 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2798 = cute.make_view(%iter_2793, %1705) : !memref_smem_bf16_14
        %iter_2799 = cute.get_iter(%view_2798) : !memref_smem_bf16_14
        %view_2800 = cute.make_view(%iter_2799) : !memref_smem_bf16_15
        %1706 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2801 = cute.make_view(%iter_2797, %1706) : !memref_rmem_bf16_9
        %iter_2802 = cute.get_iter(%view_2801) : !memref_rmem_bf16_9
        %view_2803 = cute.make_view(%iter_2802) : !memref_rmem_bf16_10
        %1707 = cute.static : !cute.layout<"1:0">
        %iter_2804 = cute.get_iter(%view_2800) : !memref_smem_bf16_15
        %iter_2805 = cute.get_iter(%view_2803) : !memref_rmem_bf16_10
        %1708 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1709 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1710 = cute.static : !cute.int_tuple<"4">
        %1711 = cute.get_scalars(%1710) : !cute.int_tuple<"4">
        %c0_i32_2806 = arith.constant 0 : i32
        %c1_i32_2807 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2806 to %1711 step %c1_i32_2807  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1708) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2804, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1709) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2805, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1712 = cute.static : !cute.int_tuple<"96">
        %iter_2808 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2809 = cute.add_offset(%iter_2808, %1712) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2810 = cute.make_view(%ptr_2809) : !memref_rmem_bf16_12
        %1713 = cute.static : !cute.int_tuple<"192">
        %iter_2811 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2812 = cute.add_offset(%iter_2811, %1713) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2813 = cute.make_view(%ptr_2812) : !memref_rmem_bf16_13
        %iter_2814 = cute.get_iter(%view_2810) : !memref_rmem_bf16_12
        %iter_2815 = cute.get_iter(%view_2813) : !memref_rmem_bf16_13
        %iter_2816 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1714 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1715 = cute.static : !cute.layout<"1:0">
        %1716 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1717 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1718 = cute.static : !cute.int_tuple<"1">
        %1719 = cute.static : !cute.int_tuple<"2">
        %1720 = cute.static : !cute.int_tuple<"8">
        %1721 = cute.get_scalars(%1718) : !cute.int_tuple<"1">
        %1722 = cute.get_scalars(%1719) : !cute.int_tuple<"2">
        %1723 = cute.get_scalars(%1720) : !cute.int_tuple<"8">
        %c0_i32_2817 = arith.constant 0 : i32
        %c1_i32_2818 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2817 to %1721 step %c1_i32_2818  : i32 {
          scf.for %arg14 = %c0_i32_2817 to %1722 step %c1_i32_2818  : i32 {
            scf.for %arg15 = %c0_i32_2817 to %1723 step %c1_i32_2818  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1716) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2814, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1717) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2815, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1714) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2816, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1724 = cute.static : !cute.coord<"(_,_,5)">
        %lay_2819 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2820 = cute.crd2idx(%1724, %lay_2819) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2821 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2822 = cute.add_offset(%iter_2821, %idx_2820) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2823 = cute.make_view(%ptr_2822) : !memref_smem_bf16_11
        %iter_2824 = cute.get_iter(%view_2823) : !memref_smem_bf16_11
        %1725 = cute.static : !cute.int_tuple<"48">
        %iter_2825 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2826 = cute.add_offset(%iter_2825, %1725) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2827 = cute.make_view(%ptr_2826) : !memref_rmem_bf16_6
        %iter_2828 = cute.get_iter(%view_2827) : !memref_rmem_bf16_6
        %1726 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2829 = cute.make_view(%iter_2824, %1726) : !memref_smem_bf16_11
        %iter_2830 = cute.get_iter(%view_2829) : !memref_smem_bf16_11
        %view_2831 = cute.make_view(%iter_2830) : !memref_smem_bf16_12
        %1727 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2832 = cute.make_view(%iter_2828, %1727) : !memref_rmem_bf16_6
        %iter_2833 = cute.get_iter(%view_2832) : !memref_rmem_bf16_6
        %view_2834 = cute.make_view(%iter_2833) : !memref_rmem_bf16_7
        %1728 = cute.static : !cute.layout<"1:0">
        %iter_2835 = cute.get_iter(%view_2831) : !memref_smem_bf16_12
        %iter_2836 = cute.get_iter(%view_2834) : !memref_rmem_bf16_7
        %1729 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1730 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1731 = cute.static : !cute.int_tuple<"2">
        %1732 = cute.get_scalars(%1731) : !cute.int_tuple<"2">
        %c0_i32_2837 = arith.constant 0 : i32
        %c1_i32_2838 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2837 to %1732 step %c1_i32_2838  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1729) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2835, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1730) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2836, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1733 = cute.static : !cute.coord<"(_,_,5)">
        %lay_2839 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2840 = cute.crd2idx(%1733, %lay_2839) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2841 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2842 = cute.add_offset(%iter_2841, %idx_2840) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2843 = cute.make_view(%ptr_2842) : !memref_smem_bf16_14
        %iter_2844 = cute.get_iter(%view_2843) : !memref_smem_bf16_14
        %1734 = cute.static : !cute.int_tuple<"96">
        %iter_2845 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2846 = cute.add_offset(%iter_2845, %1734) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2847 = cute.make_view(%ptr_2846) : !memref_rmem_bf16_9
        %iter_2848 = cute.get_iter(%view_2847) : !memref_rmem_bf16_9
        %1735 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2849 = cute.make_view(%iter_2844, %1735) : !memref_smem_bf16_14
        %iter_2850 = cute.get_iter(%view_2849) : !memref_smem_bf16_14
        %view_2851 = cute.make_view(%iter_2850) : !memref_smem_bf16_15
        %1736 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2852 = cute.make_view(%iter_2848, %1736) : !memref_rmem_bf16_9
        %iter_2853 = cute.get_iter(%view_2852) : !memref_rmem_bf16_9
        %view_2854 = cute.make_view(%iter_2853) : !memref_rmem_bf16_10
        %1737 = cute.static : !cute.layout<"1:0">
        %iter_2855 = cute.get_iter(%view_2851) : !memref_smem_bf16_15
        %iter_2856 = cute.get_iter(%view_2854) : !memref_rmem_bf16_10
        %1738 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1739 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1740 = cute.static : !cute.int_tuple<"4">
        %1741 = cute.get_scalars(%1740) : !cute.int_tuple<"4">
        %c0_i32_2857 = arith.constant 0 : i32
        %c1_i32_2858 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2857 to %1741 step %c1_i32_2858  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1738) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2855, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1739) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2856, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1742 = cute.static : !cute.int_tuple<"16">
        %iter_2859 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2860 = cute.add_offset(%iter_2859, %1742) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2861 = cute.make_view(%ptr_2860) : !memref_rmem_bf16_12
        %1743 = cute.static : !cute.int_tuple<"32">
        %iter_2862 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2863 = cute.add_offset(%iter_2862, %1743) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2864 = cute.make_view(%ptr_2863) : !memref_rmem_bf16_13
        %iter_2865 = cute.get_iter(%view_2861) : !memref_rmem_bf16_12
        %iter_2866 = cute.get_iter(%view_2864) : !memref_rmem_bf16_13
        %iter_2867 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1744 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1745 = cute.static : !cute.layout<"1:0">
        %1746 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1747 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1748 = cute.static : !cute.int_tuple<"1">
        %1749 = cute.static : !cute.int_tuple<"2">
        %1750 = cute.static : !cute.int_tuple<"8">
        %1751 = cute.get_scalars(%1748) : !cute.int_tuple<"1">
        %1752 = cute.get_scalars(%1749) : !cute.int_tuple<"2">
        %1753 = cute.get_scalars(%1750) : !cute.int_tuple<"8">
        %c0_i32_2868 = arith.constant 0 : i32
        %c1_i32_2869 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2868 to %1751 step %c1_i32_2869  : i32 {
          scf.for %arg14 = %c0_i32_2868 to %1752 step %c1_i32_2869  : i32 {
            scf.for %arg15 = %c0_i32_2868 to %1753 step %c1_i32_2869  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1746) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2865, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1747) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2866, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1744) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2867, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1754 = cute.static : !cute.coord<"(_,_,6)">
        %lay_2870 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2871 = cute.crd2idx(%1754, %lay_2870) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
        %iter_2872 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2873 = cute.add_offset(%iter_2872, %idx_2871) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2874 = cute.make_view(%ptr_2873) : !memref_smem_bf16_11
        %iter_2875 = cute.get_iter(%view_2874) : !memref_smem_bf16_11
        %1755 = cute.static : !cute.int_tuple<"80">
        %iter_2876 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2877 = cute.add_offset(%iter_2876, %1755) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2878 = cute.make_view(%ptr_2877) : !memref_rmem_bf16_6
        %iter_2879 = cute.get_iter(%view_2878) : !memref_rmem_bf16_6
        %1756 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2880 = cute.make_view(%iter_2875, %1756) : !memref_smem_bf16_11
        %iter_2881 = cute.get_iter(%view_2880) : !memref_smem_bf16_11
        %view_2882 = cute.make_view(%iter_2881) : !memref_smem_bf16_12
        %1757 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2883 = cute.make_view(%iter_2879, %1757) : !memref_rmem_bf16_6
        %iter_2884 = cute.get_iter(%view_2883) : !memref_rmem_bf16_6
        %view_2885 = cute.make_view(%iter_2884) : !memref_rmem_bf16_7
        %1758 = cute.static : !cute.layout<"1:0">
        %iter_2886 = cute.get_iter(%view_2882) : !memref_smem_bf16_12
        %iter_2887 = cute.get_iter(%view_2885) : !memref_rmem_bf16_7
        %1759 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1760 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1761 = cute.static : !cute.int_tuple<"2">
        %1762 = cute.get_scalars(%1761) : !cute.int_tuple<"2">
        %c0_i32_2888 = arith.constant 0 : i32
        %c1_i32_2889 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2888 to %1762 step %c1_i32_2889  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1759) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2886, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1760) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2887, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1763 = cute.static : !cute.coord<"(_,_,6)">
        %lay_2890 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2891 = cute.crd2idx(%1763, %lay_2890) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %iter_2892 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2893 = cute.add_offset(%iter_2892, %idx_2891) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2894 = cute.make_view(%ptr_2893) : !memref_smem_bf16_14
        %iter_2895 = cute.get_iter(%view_2894) : !memref_smem_bf16_14
        %1764 = cute.static : !cute.int_tuple<"160">
        %iter_2896 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2897 = cute.add_offset(%iter_2896, %1764) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2898 = cute.make_view(%ptr_2897) : !memref_rmem_bf16_9
        %iter_2899 = cute.get_iter(%view_2898) : !memref_rmem_bf16_9
        %1765 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2900 = cute.make_view(%iter_2895, %1765) : !memref_smem_bf16_14
        %iter_2901 = cute.get_iter(%view_2900) : !memref_smem_bf16_14
        %view_2902 = cute.make_view(%iter_2901) : !memref_smem_bf16_15
        %1766 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2903 = cute.make_view(%iter_2899, %1766) : !memref_rmem_bf16_9
        %iter_2904 = cute.get_iter(%view_2903) : !memref_rmem_bf16_9
        %view_2905 = cute.make_view(%iter_2904) : !memref_rmem_bf16_10
        %1767 = cute.static : !cute.layout<"1:0">
        %iter_2906 = cute.get_iter(%view_2902) : !memref_smem_bf16_15
        %iter_2907 = cute.get_iter(%view_2905) : !memref_rmem_bf16_10
        %1768 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1769 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1770 = cute.static : !cute.int_tuple<"4">
        %1771 = cute.get_scalars(%1770) : !cute.int_tuple<"4">
        %c0_i32_2908 = arith.constant 0 : i32
        %c1_i32_2909 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2908 to %1771 step %c1_i32_2909  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1768) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2906, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1769) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2907, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1772 = cute.static : !cute.int_tuple<"48">
        %iter_2910 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2911 = cute.add_offset(%iter_2910, %1772) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2912 = cute.make_view(%ptr_2911) : !memref_rmem_bf16_12
        %1773 = cute.static : !cute.int_tuple<"96">
        %iter_2913 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2914 = cute.add_offset(%iter_2913, %1773) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2915 = cute.make_view(%ptr_2914) : !memref_rmem_bf16_13
        %iter_2916 = cute.get_iter(%view_2912) : !memref_rmem_bf16_12
        %iter_2917 = cute.get_iter(%view_2915) : !memref_rmem_bf16_13
        %iter_2918 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1774 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1775 = cute.static : !cute.layout<"1:0">
        %1776 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1777 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1778 = cute.static : !cute.int_tuple<"1">
        %1779 = cute.static : !cute.int_tuple<"2">
        %1780 = cute.static : !cute.int_tuple<"8">
        %1781 = cute.get_scalars(%1778) : !cute.int_tuple<"1">
        %1782 = cute.get_scalars(%1779) : !cute.int_tuple<"2">
        %1783 = cute.get_scalars(%1780) : !cute.int_tuple<"8">
        %c0_i32_2919 = arith.constant 0 : i32
        %c1_i32_2920 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2919 to %1781 step %c1_i32_2920  : i32 {
          scf.for %arg14 = %c0_i32_2919 to %1782 step %c1_i32_2920  : i32 {
            scf.for %arg15 = %c0_i32_2919 to %1783 step %c1_i32_2920  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1776) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2916, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1777) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2917, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1774) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2918, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1784 = cute.static : !cute.coord<"(_,_,7)">
        %lay_2921 = cute.get_layout(%view_211) : !memref_smem_bf16_5
        %idx_2922 = cute.crd2idx(%1784, %lay_2921) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2923 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2924 = cute.add_offset(%iter_2923, %idx_2922) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2925 = cute.make_view(%ptr_2924) : !memref_smem_bf16_11
        %iter_2926 = cute.get_iter(%view_2925) : !memref_smem_bf16_11
        %1785 = cute.static : !cute.int_tuple<"112">
        %iter_2927 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2928 = cute.add_offset(%iter_2927, %1785) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2929 = cute.make_view(%ptr_2928) : !memref_rmem_bf16_6
        %iter_2930 = cute.get_iter(%view_2929) : !memref_rmem_bf16_6
        %1786 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2931 = cute.make_view(%iter_2926, %1786) : !memref_smem_bf16_11
        %iter_2932 = cute.get_iter(%view_2931) : !memref_smem_bf16_11
        %view_2933 = cute.make_view(%iter_2932) : !memref_smem_bf16_12
        %1787 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2934 = cute.make_view(%iter_2930, %1787) : !memref_rmem_bf16_6
        %iter_2935 = cute.get_iter(%view_2934) : !memref_rmem_bf16_6
        %view_2936 = cute.make_view(%iter_2935) : !memref_rmem_bf16_7
        %1788 = cute.static : !cute.layout<"1:0">
        %iter_2937 = cute.get_iter(%view_2933) : !memref_smem_bf16_12
        %iter_2938 = cute.get_iter(%view_2936) : !memref_rmem_bf16_7
        %1789 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1790 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1791 = cute.static : !cute.int_tuple<"2">
        %1792 = cute.get_scalars(%1791) : !cute.int_tuple<"2">
        %c0_i32_2939 = arith.constant 0 : i32
        %c1_i32_2940 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2939 to %1792 step %c1_i32_2940  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1789) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2937, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1790) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2938, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1793 = cute.static : !cute.coord<"(_,_,7)">
        %lay_2941 = cute.get_layout(%view_239) : !memref_smem_bf16_6
        %idx_2942 = cute.crd2idx(%1793, %lay_2941) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %iter_2943 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2944 = cute.add_offset(%iter_2943, %idx_2942) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2945 = cute.make_view(%ptr_2944) : !memref_smem_bf16_14
        %iter_2946 = cute.get_iter(%view_2945) : !memref_smem_bf16_14
        %1794 = cute.static : !cute.int_tuple<"224">
        %iter_2947 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2948 = cute.add_offset(%iter_2947, %1794) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2949 = cute.make_view(%ptr_2948) : !memref_rmem_bf16_9
        %iter_2950 = cute.get_iter(%view_2949) : !memref_rmem_bf16_9
        %1795 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2951 = cute.make_view(%iter_2946, %1795) : !memref_smem_bf16_14
        %iter_2952 = cute.get_iter(%view_2951) : !memref_smem_bf16_14
        %view_2953 = cute.make_view(%iter_2952) : !memref_smem_bf16_15
        %1796 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_2954 = cute.make_view(%iter_2950, %1796) : !memref_rmem_bf16_9
        %iter_2955 = cute.get_iter(%view_2954) : !memref_rmem_bf16_9
        %view_2956 = cute.make_view(%iter_2955) : !memref_rmem_bf16_10
        %1797 = cute.static : !cute.layout<"1:0">
        %iter_2957 = cute.get_iter(%view_2953) : !memref_smem_bf16_15
        %iter_2958 = cute.get_iter(%view_2956) : !memref_rmem_bf16_10
        %1798 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1799 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1800 = cute.static : !cute.int_tuple<"4">
        %1801 = cute.get_scalars(%1800) : !cute.int_tuple<"4">
        %c0_i32_2959 = arith.constant 0 : i32
        %c1_i32_2960 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2959 to %1801 step %c1_i32_2960  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1798) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_2957, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1799) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2958, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1802 = cute.static : !cute.int_tuple<"80">
        %iter_2961 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_2962 = cute.add_offset(%iter_2961, %1802) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2963 = cute.make_view(%ptr_2962) : !memref_rmem_bf16_12
        %1803 = cute.static : !cute.int_tuple<"160">
        %iter_2964 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_2965 = cute.add_offset(%iter_2964, %1803) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2966 = cute.make_view(%ptr_2965) : !memref_rmem_bf16_13
        %iter_2967 = cute.get_iter(%view_2963) : !memref_rmem_bf16_12
        %iter_2968 = cute.get_iter(%view_2966) : !memref_rmem_bf16_13
        %iter_2969 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1804 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1805 = cute.static : !cute.layout<"1:0">
        %1806 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1807 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1808 = cute.static : !cute.int_tuple<"1">
        %1809 = cute.static : !cute.int_tuple<"2">
        %1810 = cute.static : !cute.int_tuple<"8">
        %1811 = cute.get_scalars(%1808) : !cute.int_tuple<"1">
        %1812 = cute.get_scalars(%1809) : !cute.int_tuple<"2">
        %1813 = cute.get_scalars(%1810) : !cute.int_tuple<"8">
        %c0_i32_2970 = arith.constant 0 : i32
        %c1_i32_2971 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2970 to %1811 step %c1_i32_2971  : i32 {
          scf.for %arg14 = %c0_i32_2970 to %1812 step %c1_i32_2971  : i32 {
            scf.for %arg15 = %c0_i32_2970 to %1813 step %c1_i32_2971  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1806) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_2967, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1807) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_2968, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1804) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_2969, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %1814 = cute.static : !cute.int_tuple<"0">
        %iter_2972 = cute.get_iter(%view_211) : !memref_smem_bf16_5
        %ptr_2973 = cute.add_offset(%iter_2972, %1814) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2974 = cute.make_view(%ptr_2973) : !memref_smem_bf16_11
        %iter_2975 = cute.get_iter(%view_2974) : !memref_smem_bf16_11
        %1815 = cute.static : !cute.int_tuple<"0">
        %iter_2976 = cute.get_iter(%view_213) : !memref_rmem_bf16_3
        %ptr_2977 = cute.add_offset(%iter_2976, %1815) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2978 = cute.make_view(%ptr_2977) : !memref_rmem_bf16_6
        %iter_2979 = cute.get_iter(%view_2978) : !memref_rmem_bf16_6
        %1816 = cute.static : !cute.layout<"((8,1),2):((1,0),4096)">
        %view_2980 = cute.make_view(%iter_2975, %1816) : !memref_smem_bf16_11
        %iter_2981 = cute.get_iter(%view_2980) : !memref_smem_bf16_11
        %view_2982 = cute.make_view(%iter_2981) : !memref_smem_bf16_12
        %1817 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2983 = cute.make_view(%iter_2979, %1817) : !memref_rmem_bf16_6
        %iter_2984 = cute.get_iter(%view_2983) : !memref_rmem_bf16_6
        %view_2985 = cute.make_view(%iter_2984) : !memref_rmem_bf16_7
        %1818 = cute.static : !cute.layout<"1:0">
        %iter_2986 = cute.get_iter(%view_2982) : !memref_smem_bf16_12
        %iter_2987 = cute.get_iter(%view_2985) : !memref_rmem_bf16_7
        %1819 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %1820 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1821 = cute.static : !cute.int_tuple<"2">
        %1822 = cute.get_scalars(%1821) : !cute.int_tuple<"2">
        %c0_i32_2988 = arith.constant 0 : i32
        %c1_i32_2989 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_2988 to %1822 step %c1_i32_2989  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1819) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_3338 = cute.add_offset(%iter_2986, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1820) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_2987, %idx_3340) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_8
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_8
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1823 = cute.static : !cute.int_tuple<"0">
        %iter_2990 = cute.get_iter(%view_239) : !memref_smem_bf16_6
        %ptr_2991 = cute.add_offset(%iter_2990, %1823) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2992 = cute.make_view(%ptr_2991) : !memref_smem_bf16_14
        %iter_2993 = cute.get_iter(%view_2992) : !memref_smem_bf16_14
        %1824 = cute.static : !cute.int_tuple<"0">
        %iter_2994 = cute.get_iter(%view_241) : !memref_rmem_bf16_4
        %ptr_2995 = cute.add_offset(%iter_2994, %1824) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2996 = cute.make_view(%ptr_2995) : !memref_rmem_bf16_9
        %iter_2997 = cute.get_iter(%view_2996) : !memref_rmem_bf16_9
        %1825 = cute.static : !cute.layout<"((8,1),4):((1,0),1024)">
        %view_2998 = cute.make_view(%iter_2993, %1825) : !memref_smem_bf16_14
        %iter_2999 = cute.get_iter(%view_2998) : !memref_smem_bf16_14
        %view_3000 = cute.make_view(%iter_2999) : !memref_smem_bf16_15
        %1826 = cute.static : !cute.layout<"((8,1),4):((1,0),8)">
        %view_3001 = cute.make_view(%iter_2997, %1826) : !memref_rmem_bf16_9
        %iter_3002 = cute.get_iter(%view_3001) : !memref_rmem_bf16_9
        %view_3003 = cute.make_view(%iter_3002) : !memref_rmem_bf16_10
        %1827 = cute.static : !cute.layout<"1:0">
        %iter_3004 = cute.get_iter(%view_3000) : !memref_smem_bf16_15
        %iter_3005 = cute.get_iter(%view_3003) : !memref_rmem_bf16_10
        %1828 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %1829 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
        %1830 = cute.static : !cute.int_tuple<"4">
        %1831 = cute.get_scalars(%1830) : !cute.int_tuple<"4">
        %c0_i32_3006 = arith.constant 0 : i32
        %c1_i32_3007 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3006 to %1831 step %c1_i32_3007  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %1828) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_3338 = cute.add_offset(%iter_3004, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1829) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3005, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1832 = cute.static : !cute.int_tuple<"112">
        %iter_3008 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_3009 = cute.add_offset(%iter_3008, %1832) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_3010 = cute.make_view(%ptr_3009) : !memref_rmem_bf16_12
        %1833 = cute.static : !cute.int_tuple<"224">
        %iter_3011 = cute.get_iter(%rmem_181) : !memref_rmem_bf16_1
        %ptr_3012 = cute.add_offset(%iter_3011, %1833) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3013 = cute.make_view(%ptr_3012) : !memref_rmem_bf16_13
        %iter_3014 = cute.get_iter(%view_3010) : !memref_rmem_bf16_12
        %iter_3015 = cute.get_iter(%view_3013) : !memref_rmem_bf16_13
        %iter_3016 = cute.get_iter(%rmem_2577) : !memref_rmem_f32_2
        %1834 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %1835 = cute.static : !cute.layout<"1:0">
        %1836 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
        %1837 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
        %1838 = cute.static : !cute.int_tuple<"1">
        %1839 = cute.static : !cute.int_tuple<"2">
        %1840 = cute.static : !cute.int_tuple<"8">
        %1841 = cute.get_scalars(%1838) : !cute.int_tuple<"1">
        %1842 = cute.get_scalars(%1839) : !cute.int_tuple<"2">
        %1843 = cute.get_scalars(%1840) : !cute.int_tuple<"8">
        %c0_i32_3017 = arith.constant 0 : i32
        %c1_i32_3018 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3017 to %1841 step %c1_i32_3018  : i32 {
          scf.for %arg14 = %c0_i32_3017 to %1842 step %c1_i32_3018  : i32 {
            scf.for %arg15 = %c0_i32_3017 to %1843 step %c1_i32_3018  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"((2,2,2)):((1,2,4))">
              %idx_3339 = cute.crd2idx(%coord_3336, %1836) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
              %ptr_3340 = cute.add_offset(%iter_3014, %idx_3339) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_14
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %1837) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_3015, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %1834) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_3016, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_14
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.wait.group 0
        %c1_i32_3019 = arith.constant 1 : i32
        %c128_i32_3020 = arith.constant 128 : i32
        nvvm.barrier id = %c1_i32_3019 number_of_threads = %c128_i32_3020
        %c0_i32_3021 = arith.constant 0 : i32
        %1844 = arith.cmpi sgt, %1583, %c0_i32_3021 : i32
        scf.if %1844 {
          %c1_i32_3336 = arith.constant 1 : i32
          %2105 = arith.subi %1583, %c1_i32_3336 : i32
          %coord_3337 = cute.make_coord(%2105) : (i32) -> !cute.coord<"(_,_,_,?)">
          %lay_3338 = cute.get_layout(%view_128) : !memref_gmem_bf16_5
          %2106:3 = cute.get_scalars(%lay_3338) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %2107 = cute.static : !cute.shape<"((8,1),4,2)">
          %iv_3339 = cute.assume(%2106#1) : (i64) -> !cute.i64<divby 128>
          %stride_3340 = cute.make_stride(%iv_3339) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_3341 = cute.make_layout(%2107, %stride_3340) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_3342 = cute.crd2idx(%coord_3337, %lay_3338) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %iter_3343 = cute.get_iter(%view_128) : !memref_gmem_bf16_5
          %ptr_3344 = cute.add_offset(%iter_3343, %idx_3342) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_3345 = cute.make_view(%ptr_3344, %lay_3341) : !memref_gmem_bf16_9
          %iter_3346 = cute.get_iter(%view_3345) : !memref_gmem_bf16_9
          %lay_3347 = cute.get_layout(%view_3345) : !memref_gmem_bf16_9
          %2108 = cute.static : !cute.layout<"1:0">
          %append_3348 = cute.append_to_rank<2> (%lay_3347, %2108) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %view_3349 = cute.make_view(%iter_3346, %append_3348) : !memref_gmem_bf16_9
          %iter_3350 = cute.get_iter(%view_3349) : !memref_gmem_bf16_9
          %lay_3351 = cute.get_layout(%view_3349) : !memref_gmem_bf16_9
          %2109 = cute.get_scalars(%lay_3351) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %2110 = cute.static : !cute.shape<"((8,1),(4,2))">
          %iv_3352 = cute.assume(%2109) : (i64) -> !cute.i64<divby 128>
          %stride_3353 = cute.make_stride(%iv_3352) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_3354 = cute.make_layout(%2110, %stride_3353) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %view_3355 = cute.make_view(%iter_3350, %lay_3354) : !memref_gmem_bf16_10
          %2111 = cute.static : !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
          %view_3356 = cute.make_view(%iter_146, %2111) : !memref_smem_bf16_4
          %iter_3357 = cute.get_iter(%view_3356) : !memref_smem_bf16_4
          %view_3358 = cute.make_view(%iter_3357) : !memref_smem_bf16_13
          %2112 = cute.static : !cute.layout<"(1,4,2):(2,0,1)">
          %view_3359 = cute.make_view(%iter_351, %2112) : !memref_rmem_i8_1
          %iter_3360 = cute.get_iter(%view_3359) : !memref_rmem_i8_1
          %view_3361 = cute.make_view(%iter_3360) : !memref_rmem_i8_5
          %2113 = cute.static : !cute.layout<"1:0">
          %iter_3362 = cute.get_iter(%view_3355) : !memref_gmem_bf16_10
          %iter_3363 = cute.get_iter(%view_3358) : !memref_smem_bf16_13
          %lay_3364 = cute.get_layout(%view_3355) : !memref_gmem_bf16_10
          %append_3365 = cute.append_to_rank<2> (%lay_3364, %2113) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %2114 = cute.get_scalars(%append_3365) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %2115 = cute.static : !cute.shape<"((8,1),((4,2)))">
          %iv_3366 = cute.assume(%2114) : (i64) -> !cute.i64<divby 128>
          %stride_3367 = cute.make_stride(%iv_3366) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_3368 = cute.make_layout(%2115, %stride_3367) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %2116 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
          %iter_3369 = cute.get_iter(%view_3361) : !memref_rmem_i8_5
          %2117 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
          %2118 = cute.static : !cute.int_tuple<"8">
          %2119 = cute.get_scalars(%2118) : !cute.int_tuple<"8">
          %c0_i32_3370 = arith.constant 0 : i32
          %c1_i32_3371 = arith.constant 1 : i32
          scf.for %arg13 = %c0_i32_3370 to %2119 step %c1_i32_3371  : i32 {
            %coord_3372 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
            %2120 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_3373 = cute.crd2idx(%coord_3372, %lay_3368) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_3374 = cute.add_offset(%iter_3362, %idx_3373) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %view_3375 = cute.make_view(%ptr_3374, %2120) : !memref_gmem_bf16_8
            %2121 = cute.static : !cute.layout<"((8,1)):((1,0))">
            %idx_3376 = cute.crd2idx(%coord_3372, %2116) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_3377 = cute.add_offset(%iter_3363, %idx_3376) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %view_3378 = cute.make_view(%ptr_3377, %2121) : !memref_smem_bf16_10
            %2122 = cute.static : !cute.layout<"(1):(2)">
            %idx_3379 = cute.crd2idx(%coord_3372, %2117) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_3380 = cute.add_offset(%iter_3369, %idx_3379) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %view_3381 = cute.make_view(%ptr_3380, %2122) : !memref_rmem_i8_4
            %iter_3382 = cute.get_iter(%view_3375) : !memref_gmem_bf16_8
            %iter_3383 = cute.get_iter(%view_3378) : !memref_smem_bf16_10
            %iter_3384 = cute.get_iter(%view_3381) : !memref_rmem_i8_4
            %2123 = builtin.unrealized_conversion_cast %iter_3384 : !cute.ptr<i8, rmem> to !llvm.ptr
            %2124 = llvm.load %2123 : !llvm.ptr -> i8
            %2125 = llvm.trunc %2124 : i8 to i1
            %iter_3385 = cute.recast_iter(%iter_3382) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_3386 = cute.recast_iter(%iter_3383) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_3386 : !cute.ptr<i128, smem>, %iter_3385 : !cute.ptr<i128, gmem>, %2125 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
          nvvm.cp.async.commit.group
        }
        %1845 = cute.static : !cute.layout<"((2,2),(2,8)):((2,4),(1,8))">
        %view_3022 = cute.make_view(%iter_2578, %1845) : !memref_rmem_f32_4
        %1846 = cute.static : !cute.layout<"((2,2),(2,16)):((2,4),(1,8))">
        %view_3023 = cute.make_view(%iter_184, %1846) : !memref_rmem_f32_8
        %1847 = cute.static : !cute.layout<"4:1">
        %rmem_3024 = cute.memref.alloca(%1847) : !memref_rmem_f32_1
        %1848 = cute.static : !cute.layout<"1:0">
        %iter_3025 = cute.get_iter(%rmem_623) : !memref_rmem_f32_1
        %iter_3026 = cute.get_iter(%rmem_3024) : !memref_rmem_f32_1
        %1849 = cute.static : !cute.int_tuple<"1">
        %1850 = cute.get_scalars(%1849) : !cute.int_tuple<"1">
        %c0_i32_3027 = arith.constant 0 : i32
        %c1_i32_3028 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3027 to %1850 step %c1_i32_3028  : i32 {
          %2105 = cute.static : !cute.layout<"(4):(1)">
          %2106 = cute.static : !cute.int_tuple<"0">
          %ptr_3336 = cute.add_offset(%iter_3025, %2106) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_3337 = cute.make_view(%ptr_3336, %2105) : !memref_rmem_f32_9
          %2107 = cute.static : !cute.layout<"(4):(1)">
          %2108 = cute.static : !cute.int_tuple<"0">
          %ptr_3338 = cute.add_offset(%iter_3026, %2108) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_3339 = cute.make_view(%ptr_3338, %2107) : !memref_rmem_f32_9
          %iter_3340 = cute.get_iter(%view_3337) : !memref_rmem_f32_9
          %iter_3341 = cute.get_iter(%view_3339) : !memref_rmem_f32_9
          %2109 = builtin.unrealized_conversion_cast %iter_3340 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %2110 = builtin.unrealized_conversion_cast %iter_3341 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %2111 = llvm.load %2109 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %2111, %2110 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
          %2112 = cute.static : !cute.int_tuple<"1">
          %ptr_3342 = cute.add_offset(%iter_3340, %2112) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %2113 = cute.static : !cute.int_tuple<"1">
          %ptr_3343 = cute.add_offset(%iter_3341, %2113) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %2114 = builtin.unrealized_conversion_cast %ptr_3342 : !cute.ptr<f32, rmem> to !llvm.ptr
          %2115 = builtin.unrealized_conversion_cast %ptr_3343 : !cute.ptr<f32, rmem> to !llvm.ptr
          %2116 = llvm.load %2114 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %2116, %2115 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
          %2117 = cute.static : !cute.int_tuple<"2">
          %ptr_3344 = cute.add_offset(%iter_3340, %2117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %2118 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3341, %2118) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %2119 = builtin.unrealized_conversion_cast %ptr_3344 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %2120 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %2121 = llvm.load %2119 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %2121, %2120 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
          %2122 = cute.static : !cute.int_tuple<"3">
          %ptr_3346 = cute.add_offset(%iter_3340, %2122) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %2123 = cute.static : !cute.int_tuple<"3">
          %ptr_3347 = cute.add_offset(%iter_3341, %2123) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %2124 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<f32, rmem> to !llvm.ptr
          %2125 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<f32, rmem> to !llvm.ptr
          %2126 = llvm.load %2124 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %2126, %2125 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %1851 = cute.static : !cute.int_tuple<"0">
        %iter_3029 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3030 = cute.add_offset(%iter_3029, %1851) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_3031 = cute.make_view(%ptr_3030) : !memref_rmem_f32_5
        %1852 = cute.memref.load_vec %view_3031 : !memref_rmem_f32_5
        %cst_3032 = arith.constant 0xFF800000 : f32
        %1853 = vector.reduction <maximumf>, %1852, %cst_3032 : vector<16xf32> into f32
        %c-1_i32_3033 = arith.constant -1 : i32
        %c2_i32_3034 = arith.constant 2 : i32
        %c31_i32_3035 = arith.constant 31 : i32
        %1854 = nvvm.shfl.sync  bfly %c-1_i32_3033, %1853, %c2_i32_3034, %c31_i32_3035 : f32 -> f32
        %1855 = nvvm.fmax %1853, %1854
        %c-1_i32_3036 = arith.constant -1 : i32
        %c1_i32_3037 = arith.constant 1 : i32
        %c31_i32_3038 = arith.constant 31 : i32
        %1856 = nvvm.shfl.sync  bfly %c-1_i32_3036, %1855, %c1_i32_3037, %c31_i32_3038 : f32 -> f32
        %1857 = nvvm.fmax %1855, %1856
        %1858 = cute.static : !cute.coord<"0">
        %1859 = cute.memref.load(%rmem_3024, %1858) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
        %1860 = nvvm.fmax %1859, %1857
        %1861 = vector.broadcast %arg4 : f32 to vector<16xf32>
        %1862 = arith.mulf %1852, %1861 : vector<16xf32>
        %1863 = arith.mulf %1860, %arg4 : f32
        %1864 = vector.broadcast %1863 : f32 to vector<16xf32>
        %1865 = arith.subf %1862, %1864 : vector<16xf32>
        %1866 = math.exp2 %1865 fastmath<fast> : vector<16xf32>
        %cst_3039 = arith.constant 0.000000e+00 : f32
        %1867 = vector.reduction <add>, %1866, %cst_3039 : vector<16xf32> into f32
        %1868 = arith.mulf %1859, %arg4 : f32
        %1869 = arith.mulf %1860, %arg4 : f32
        %1870 = arith.subf %1868, %1869 : f32
        %1871 = math.exp2 %1870 fastmath<fast> : f32
        %1872 = cute.static : !cute.coord<"0">
        %1873 = cute.memref.load(%rmem_624, %1872) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
        %1874 = arith.mulf %1873, %1871 : f32
        %1875 = arith.addf %1874, %1867 : f32
        %1876 = cute.static : !cute.int_tuple<"0">
        %iter_3040 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3041 = cute.add_offset(%iter_3040, %1876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_3042 = cute.make_view(%ptr_3041) : !memref_rmem_f32_10
        %1877 = cute.memref.load_vec %view_3042 : !memref_rmem_f32_10
        %1878 = vector.broadcast %1871 : f32 to vector<32xf32>
        %1879 = arith.mulf %1877, %1878 : vector<32xf32>
        %1880 = cute.static : !cute.int_tuple<"0">
        %iter_3043 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3044 = cute.add_offset(%iter_3043, %1880) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_3045 = cute.make_view(%ptr_3044) : !memref_rmem_f32_10
        cute.memref.store_vec %1879, %view_3045 : !memref_rmem_f32_10
        %1881 = cute.static : !cute.coord<"0">
        cute.memref.store(%rmem_623, %1881, %1860) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
        %1882 = cute.static : !cute.coord<"0">
        cute.memref.store(%rmem_624, %1882, %1875) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
        %1883 = cute.static : !cute.int_tuple<"0">
        %iter_3046 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3047 = cute.add_offset(%iter_3046, %1883) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_3048 = cute.make_view(%ptr_3047) : !memref_rmem_f32_5
        cute.memref.store_vec %1866, %view_3048 : !memref_rmem_f32_5
        %1884 = cute.static : !cute.int_tuple<"2">
        %iter_3049 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3050 = cute.add_offset(%iter_3049, %1884) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3051 = cute.make_view(%ptr_3050) : !memref_rmem_f32_6
        %1885 = cute.memref.load_vec %view_3051 : !memref_rmem_f32_6
        %cst_3052 = arith.constant 0xFF800000 : f32
        %1886 = vector.reduction <maximumf>, %1885, %cst_3052 : vector<16xf32> into f32
        %c-1_i32_3053 = arith.constant -1 : i32
        %c2_i32_3054 = arith.constant 2 : i32
        %c31_i32_3055 = arith.constant 31 : i32
        %1887 = nvvm.shfl.sync  bfly %c-1_i32_3053, %1886, %c2_i32_3054, %c31_i32_3055 : f32 -> f32
        %1888 = nvvm.fmax %1886, %1887
        %c-1_i32_3056 = arith.constant -1 : i32
        %c1_i32_3057 = arith.constant 1 : i32
        %c31_i32_3058 = arith.constant 31 : i32
        %1889 = nvvm.shfl.sync  bfly %c-1_i32_3056, %1888, %c1_i32_3057, %c31_i32_3058 : f32 -> f32
        %1890 = nvvm.fmax %1888, %1889
        %1891 = cute.static : !cute.coord<"1">
        %1892 = cute.memref.load(%rmem_3024, %1891) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
        %1893 = nvvm.fmax %1892, %1890
        %1894 = vector.broadcast %arg4 : f32 to vector<16xf32>
        %1895 = arith.mulf %1885, %1894 : vector<16xf32>
        %1896 = arith.mulf %1893, %arg4 : f32
        %1897 = vector.broadcast %1896 : f32 to vector<16xf32>
        %1898 = arith.subf %1895, %1897 : vector<16xf32>
        %1899 = math.exp2 %1898 fastmath<fast> : vector<16xf32>
        %cst_3059 = arith.constant 0.000000e+00 : f32
        %1900 = vector.reduction <add>, %1899, %cst_3059 : vector<16xf32> into f32
        %1901 = arith.mulf %1892, %arg4 : f32
        %1902 = arith.mulf %1893, %arg4 : f32
        %1903 = arith.subf %1901, %1902 : f32
        %1904 = math.exp2 %1903 fastmath<fast> : f32
        %1905 = cute.static : !cute.coord<"1">
        %1906 = cute.memref.load(%rmem_624, %1905) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
        %1907 = arith.mulf %1906, %1904 : f32
        %1908 = arith.addf %1907, %1900 : f32
        %1909 = cute.static : !cute.int_tuple<"2">
        %iter_3060 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3061 = cute.add_offset(%iter_3060, %1909) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3062 = cute.make_view(%ptr_3061) : !memref_rmem_f32_11
        %1910 = cute.memref.load_vec %view_3062 : !memref_rmem_f32_11
        %1911 = vector.broadcast %1904 : f32 to vector<32xf32>
        %1912 = arith.mulf %1910, %1911 : vector<32xf32>
        %1913 = cute.static : !cute.int_tuple<"2">
        %iter_3063 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3064 = cute.add_offset(%iter_3063, %1913) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3065 = cute.make_view(%ptr_3064) : !memref_rmem_f32_11
        cute.memref.store_vec %1912, %view_3065 : !memref_rmem_f32_11
        %1914 = cute.static : !cute.coord<"1">
        cute.memref.store(%rmem_623, %1914, %1893) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
        %1915 = cute.static : !cute.coord<"1">
        cute.memref.store(%rmem_624, %1915, %1908) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
        %1916 = cute.static : !cute.int_tuple<"2">
        %iter_3066 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3067 = cute.add_offset(%iter_3066, %1916) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3068 = cute.make_view(%ptr_3067) : !memref_rmem_f32_6
        cute.memref.store_vec %1899, %view_3068 : !memref_rmem_f32_6
        %1917 = cute.static : !cute.int_tuple<"4">
        %iter_3069 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3070 = cute.add_offset(%iter_3069, %1917) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %view_3071 = cute.make_view(%ptr_3070) : !memref_rmem_f32_7
        %1918 = cute.memref.load_vec %view_3071 : !memref_rmem_f32_7
        %cst_3072 = arith.constant 0xFF800000 : f32
        %1919 = vector.reduction <maximumf>, %1918, %cst_3072 : vector<16xf32> into f32
        %c-1_i32_3073 = arith.constant -1 : i32
        %c2_i32_3074 = arith.constant 2 : i32
        %c31_i32_3075 = arith.constant 31 : i32
        %1920 = nvvm.shfl.sync  bfly %c-1_i32_3073, %1919, %c2_i32_3074, %c31_i32_3075 : f32 -> f32
        %1921 = nvvm.fmax %1919, %1920
        %c-1_i32_3076 = arith.constant -1 : i32
        %c1_i32_3077 = arith.constant 1 : i32
        %c31_i32_3078 = arith.constant 31 : i32
        %1922 = nvvm.shfl.sync  bfly %c-1_i32_3076, %1921, %c1_i32_3077, %c31_i32_3078 : f32 -> f32
        %1923 = nvvm.fmax %1921, %1922
        %1924 = cute.static : !cute.coord<"2">
        %1925 = cute.memref.load(%rmem_3024, %1924) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
        %1926 = nvvm.fmax %1925, %1923
        %1927 = vector.broadcast %arg4 : f32 to vector<16xf32>
        %1928 = arith.mulf %1918, %1927 : vector<16xf32>
        %1929 = arith.mulf %1926, %arg4 : f32
        %1930 = vector.broadcast %1929 : f32 to vector<16xf32>
        %1931 = arith.subf %1928, %1930 : vector<16xf32>
        %1932 = math.exp2 %1931 fastmath<fast> : vector<16xf32>
        %cst_3079 = arith.constant 0.000000e+00 : f32
        %1933 = vector.reduction <add>, %1932, %cst_3079 : vector<16xf32> into f32
        %1934 = arith.mulf %1925, %arg4 : f32
        %1935 = arith.mulf %1926, %arg4 : f32
        %1936 = arith.subf %1934, %1935 : f32
        %1937 = math.exp2 %1936 fastmath<fast> : f32
        %1938 = cute.static : !cute.coord<"2">
        %1939 = cute.memref.load(%rmem_624, %1938) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
        %1940 = arith.mulf %1939, %1937 : f32
        %1941 = arith.addf %1940, %1933 : f32
        %1942 = cute.static : !cute.int_tuple<"4">
        %iter_3080 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3081 = cute.add_offset(%iter_3080, %1942) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %view_3082 = cute.make_view(%ptr_3081) : !memref_rmem_f32_12
        %1943 = cute.memref.load_vec %view_3082 : !memref_rmem_f32_12
        %1944 = vector.broadcast %1937 : f32 to vector<32xf32>
        %1945 = arith.mulf %1943, %1944 : vector<32xf32>
        %1946 = cute.static : !cute.int_tuple<"4">
        %iter_3083 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3084 = cute.add_offset(%iter_3083, %1946) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %view_3085 = cute.make_view(%ptr_3084) : !memref_rmem_f32_12
        cute.memref.store_vec %1945, %view_3085 : !memref_rmem_f32_12
        %1947 = cute.static : !cute.coord<"2">
        cute.memref.store(%rmem_623, %1947, %1926) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
        %1948 = cute.static : !cute.coord<"2">
        cute.memref.store(%rmem_624, %1948, %1941) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
        %1949 = cute.static : !cute.int_tuple<"4">
        %iter_3086 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3087 = cute.add_offset(%iter_3086, %1949) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %view_3088 = cute.make_view(%ptr_3087) : !memref_rmem_f32_7
        cute.memref.store_vec %1932, %view_3088 : !memref_rmem_f32_7
        %1950 = cute.static : !cute.int_tuple<"6">
        %iter_3089 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3090 = cute.add_offset(%iter_3089, %1950) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3091 = cute.make_view(%ptr_3090) : !memref_rmem_f32_6
        %1951 = cute.memref.load_vec %view_3091 : !memref_rmem_f32_6
        %cst_3092 = arith.constant 0xFF800000 : f32
        %1952 = vector.reduction <maximumf>, %1951, %cst_3092 : vector<16xf32> into f32
        %c-1_i32_3093 = arith.constant -1 : i32
        %c2_i32_3094 = arith.constant 2 : i32
        %c31_i32_3095 = arith.constant 31 : i32
        %1953 = nvvm.shfl.sync  bfly %c-1_i32_3093, %1952, %c2_i32_3094, %c31_i32_3095 : f32 -> f32
        %1954 = nvvm.fmax %1952, %1953
        %c-1_i32_3096 = arith.constant -1 : i32
        %c1_i32_3097 = arith.constant 1 : i32
        %c31_i32_3098 = arith.constant 31 : i32
        %1955 = nvvm.shfl.sync  bfly %c-1_i32_3096, %1954, %c1_i32_3097, %c31_i32_3098 : f32 -> f32
        %1956 = nvvm.fmax %1954, %1955
        %1957 = cute.static : !cute.coord<"3">
        %1958 = cute.memref.load(%rmem_3024, %1957) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
        %1959 = nvvm.fmax %1958, %1956
        %1960 = vector.broadcast %arg4 : f32 to vector<16xf32>
        %1961 = arith.mulf %1951, %1960 : vector<16xf32>
        %1962 = arith.mulf %1959, %arg4 : f32
        %1963 = vector.broadcast %1962 : f32 to vector<16xf32>
        %1964 = arith.subf %1961, %1963 : vector<16xf32>
        %1965 = math.exp2 %1964 fastmath<fast> : vector<16xf32>
        %cst_3099 = arith.constant 0.000000e+00 : f32
        %1966 = vector.reduction <add>, %1965, %cst_3099 : vector<16xf32> into f32
        %1967 = arith.mulf %1958, %arg4 : f32
        %1968 = arith.mulf %1959, %arg4 : f32
        %1969 = arith.subf %1967, %1968 : f32
        %1970 = math.exp2 %1969 fastmath<fast> : f32
        %1971 = cute.static : !cute.coord<"3">
        %1972 = cute.memref.load(%rmem_624, %1971) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
        %1973 = arith.mulf %1972, %1970 : f32
        %1974 = arith.addf %1973, %1966 : f32
        %1975 = cute.static : !cute.int_tuple<"6">
        %iter_3100 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3101 = cute.add_offset(%iter_3100, %1975) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3102 = cute.make_view(%ptr_3101) : !memref_rmem_f32_11
        %1976 = cute.memref.load_vec %view_3102 : !memref_rmem_f32_11
        %1977 = vector.broadcast %1970 : f32 to vector<32xf32>
        %1978 = arith.mulf %1976, %1977 : vector<32xf32>
        %1979 = cute.static : !cute.int_tuple<"6">
        %iter_3103 = cute.get_iter(%view_3023) : !memref_rmem_f32_8
        %ptr_3104 = cute.add_offset(%iter_3103, %1979) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3105 = cute.make_view(%ptr_3104) : !memref_rmem_f32_11
        cute.memref.store_vec %1978, %view_3105 : !memref_rmem_f32_11
        %1980 = cute.static : !cute.coord<"3">
        cute.memref.store(%rmem_623, %1980, %1959) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
        %1981 = cute.static : !cute.coord<"3">
        cute.memref.store(%rmem_624, %1981, %1974) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
        %1982 = cute.static : !cute.int_tuple<"6">
        %iter_3106 = cute.get_iter(%view_3022) : !memref_rmem_f32_4
        %ptr_3107 = cute.add_offset(%iter_3106, %1982) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %view_3108 = cute.make_view(%ptr_3107) : !memref_rmem_f32_6
        cute.memref.store_vec %1965, %view_3108 : !memref_rmem_f32_6
        %1983 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
        %rmem_3109 = cute.memref.alloca(%1983) : !memref_rmem_bf16_16
        %iter_3110 = cute.get_iter(%rmem_3109) : !memref_rmem_bf16_16
        %1984 = cute.memref.load_vec %rmem_2577 : !memref_rmem_f32_2
        %1985 = arith.truncf %1984 : vector<64xf32> to vector<64xbf16>
        cute.memref.store_vec %1985, %rmem_3109 : !memref_rmem_bf16_16
        %1986 = cute.static : !cute.layout<"(((2,2),2),2,4):(((1,2),8),4,16)">
        %view_3111 = cute.make_view(%iter_3110, %1986) : !memref_rmem_bf16_17
        %lay_3112 = cute.get_layout(%view_267) : !memref_smem_bf16_7
        %1987:2 = cute.get_scalars(%lay_3112) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %1988 = cute.static : !cute.shape<"((8,1),((2,2),2))">
        %iv_3113 = cute.assume(%1987#0) : (i32) -> !cute.i32<divby 16>
        %iv_3114 = cute.assume(%1987#1) : (i32) -> !cute.i32<divby 32>
        %stride_3115 = cute.make_stride(%iv_3113, %iv_3114) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_3116 = cute.make_layout(%1988, %stride_3115) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %1989 = cute.static : !cute.int_tuple<"0">
        %iter_3117 = cute.get_iter(%view_267) : !memref_smem_bf16_7
        %ptr_3118 = cute.add_offset(%iter_3117, %1989) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_3119 = cute.make_view(%ptr_3118, %lay_3116) : !memref_smem_bf16_16
        %iter_3120 = cute.get_iter(%view_3119) : !memref_smem_bf16_16
        %1990 = cute.static : !cute.int_tuple<"0">
        %iter_3121 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
        %ptr_3122 = cute.add_offset(%iter_3121, %1990) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3123 = cute.make_view(%ptr_3122) : !memref_rmem_bf16_18
        %iter_3124 = cute.get_iter(%view_3123) : !memref_rmem_bf16_18
        %lay_3125 = cute.get_layout(%view_3119) : !memref_smem_bf16_16
        %1991 = cute.static : !cute.layout<"1:0">
        %append_3126 = cute.append_to_rank<2> (%lay_3125, %1991) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_3127 = cute.make_view(%iter_3120, %append_3126) : !memref_smem_bf16_16
        %iter_3128 = cute.get_iter(%view_3127) : !memref_smem_bf16_16
        %lay_3129 = cute.get_layout(%view_3127) : !memref_smem_bf16_16
        %1992:2 = cute.get_scalars(%lay_3129) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %1993 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
        %iv_3130 = cute.assume(%1992#0) : (i32) -> !cute.i32<divby 16>
        %iv_3131 = cute.assume(%1992#1) : (i32) -> !cute.i32<divby 32>
        %stride_3132 = cute.make_stride(%iv_3130, %iv_3131) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_3133 = cute.make_layout(%1993, %stride_3132) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %view_3134 = cute.make_view(%iter_3128, %lay_3133) : !memref_smem_bf16_17
        %1994 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %view_3135 = cute.make_view(%iter_3124, %1994) : !memref_rmem_bf16_18
        %iter_3136 = cute.get_iter(%view_3135) : !memref_rmem_bf16_18
        %view_3137 = cute.make_view(%iter_3136) : !memref_rmem_bf16_19
        %1995 = cute.static : !cute.layout<"1:0">
        %iter_3138 = cute.get_iter(%view_3134) : !memref_smem_bf16_17
        %iter_3139 = cute.get_iter(%view_3137) : !memref_rmem_bf16_19
        %lay_3140 = cute.get_layout(%view_3134) : !memref_smem_bf16_17
        %append_3141 = cute.append_to_rank<2> (%lay_3140, %1995) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %1996:2 = cute.get_scalars(%append_3141) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %1997 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
        %iv_3142 = cute.assume(%1996#0) : (i32) -> !cute.i32<divby 16>
        %iv_3143 = cute.assume(%1996#1) : (i32) -> !cute.i32<divby 32>
        %stride_3144 = cute.make_stride(%iv_3142, %iv_3143) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_3145 = cute.make_layout(%1997, %stride_3144) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %1998 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %1999 = cute.static : !cute.int_tuple<"8">
        %2000 = cute.get_scalars(%1999) : !cute.int_tuple<"8">
        %c0_i32_3146 = arith.constant 0 : i32
        %c1_i32_3147 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3146 to %2000 step %c1_i32_3147  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %lay_3145) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_3338 = cute.add_offset(%iter_3138, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %1998) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3139, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %lay_3148 = cute.get_layout(%view_267) : !memref_smem_bf16_7
        %2001:2 = cute.get_scalars(%lay_3148) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %2002 = cute.static : !cute.shape<"((8,1),((2,2),2))">
        %iv_3149 = cute.assume(%2001#0) : (i32) -> !cute.i32<divby 16>
        %iv_3150 = cute.assume(%2001#1) : (i32) -> !cute.i32<divby 32>
        %stride_3151 = cute.make_stride(%iv_3149, %iv_3150) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_3152 = cute.make_layout(%2002, %stride_3151) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2003 = cute.static : !cute.int_tuple<"1024">
        %iter_3153 = cute.get_iter(%view_267) : !memref_smem_bf16_7
        %ptr_3154 = cute.add_offset(%iter_3153, %2003) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view_3155 = cute.make_view(%ptr_3154, %lay_3152) : !memref_smem_bf16_16
        %iter_3156 = cute.get_iter(%view_3155) : !memref_smem_bf16_16
        %2004 = cute.static : !cute.int_tuple<"32">
        %iter_3157 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
        %ptr_3158 = cute.add_offset(%iter_3157, %2004) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3159 = cute.make_view(%ptr_3158) : !memref_rmem_bf16_18
        %iter_3160 = cute.get_iter(%view_3159) : !memref_rmem_bf16_18
        %lay_3161 = cute.get_layout(%view_3155) : !memref_smem_bf16_16
        %2005 = cute.static : !cute.layout<"1:0">
        %append_3162 = cute.append_to_rank<2> (%lay_3161, %2005) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_3163 = cute.make_view(%iter_3156, %append_3162) : !memref_smem_bf16_16
        %iter_3164 = cute.get_iter(%view_3163) : !memref_smem_bf16_16
        %lay_3165 = cute.get_layout(%view_3163) : !memref_smem_bf16_16
        %2006:2 = cute.get_scalars(%lay_3165) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2007 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
        %iv_3166 = cute.assume(%2006#0) : (i32) -> !cute.i32<divby 16>
        %iv_3167 = cute.assume(%2006#1) : (i32) -> !cute.i32<divby 32>
        %stride_3168 = cute.make_stride(%iv_3166, %iv_3167) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_3169 = cute.make_layout(%2007, %stride_3168) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %view_3170 = cute.make_view(%iter_3164, %lay_3169) : !memref_smem_bf16_17
        %2008 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %view_3171 = cute.make_view(%iter_3160, %2008) : !memref_rmem_bf16_18
        %iter_3172 = cute.get_iter(%view_3171) : !memref_rmem_bf16_18
        %view_3173 = cute.make_view(%iter_3172) : !memref_rmem_bf16_19
        %2009 = cute.static : !cute.layout<"1:0">
        %iter_3174 = cute.get_iter(%view_3170) : !memref_smem_bf16_17
        %iter_3175 = cute.get_iter(%view_3173) : !memref_rmem_bf16_19
        %lay_3176 = cute.get_layout(%view_3170) : !memref_smem_bf16_17
        %append_3177 = cute.append_to_rank<2> (%lay_3176, %2009) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %2010:2 = cute.get_scalars(%append_3177) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2011 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
        %iv_3178 = cute.assume(%2010#0) : (i32) -> !cute.i32<divby 16>
        %iv_3179 = cute.assume(%2010#1) : (i32) -> !cute.i32<divby 32>
        %stride_3180 = cute.make_stride(%iv_3178, %iv_3179) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_3181 = cute.make_layout(%2011, %stride_3180) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %2012 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %2013 = cute.static : !cute.int_tuple<"8">
        %2014 = cute.get_scalars(%2013) : !cute.int_tuple<"8">
        %c0_i32_3182 = arith.constant 0 : i32
        %c1_i32_3183 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3182 to %2014 step %c1_i32_3183  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %lay_3181) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_3338 = cute.add_offset(%iter_3174, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %2012) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3175, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %2015 = cute.static : !cute.int_tuple<"0">
        %iter_3184 = cute.get_iter(%view_3111) : !memref_rmem_bf16_17
        %ptr_3185 = cute.add_offset(%iter_3184, %2015) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_3186 = cute.make_view(%ptr_3185) : !memref_rmem_bf16_20
        %2016 = cute.static : !cute.int_tuple<"0">
        %iter_3187 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
        %ptr_3188 = cute.add_offset(%iter_3187, %2016) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3189 = cute.make_view(%ptr_3188) : !memref_rmem_bf16_21
        %iter_3190 = cute.get_iter(%view_3186) : !memref_rmem_bf16_20
        %iter_3191 = cute.get_iter(%view_3189) : !memref_rmem_bf16_21
        %iter_3192 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
        %2017 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
        %2018 = cute.static : !cute.layout<"1:0">
        %2019 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
        %2020 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2021 = cute.static : !cute.int_tuple<"1">
        %2022 = cute.static : !cute.int_tuple<"2">
        %2023 = cute.static : !cute.int_tuple<"16">
        %2024 = cute.get_scalars(%2021) : !cute.int_tuple<"1">
        %2025 = cute.get_scalars(%2022) : !cute.int_tuple<"2">
        %2026 = cute.get_scalars(%2023) : !cute.int_tuple<"16">
        %c0_i32_3193 = arith.constant 0 : i32
        %c1_i32_3194 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3193 to %2024 step %c1_i32_3194  : i32 {
          scf.for %arg14 = %c0_i32_3193 to %2025 step %c1_i32_3194  : i32 {
            scf.for %arg15 = %c0_i32_3193 to %2026 step %c1_i32_3194  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
              %idx_3339 = cute.crd2idx(%coord_3336, %2019) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3340 = cute.add_offset(%iter_3190, %idx_3339) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_22
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %2020) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_3191, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %2017) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_3192, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_22
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[4] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[5] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %lay_3195 = cute.get_layout(%view_267) : !memref_smem_bf16_7
        %2027:2 = cute.get_scalars(%lay_3195) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %2028 = cute.static : !cute.shape<"((8,1),((2,2),2))">
        %iv_3196 = cute.assume(%2027#0) : (i32) -> !cute.i32<divby 16>
        %iv_3197 = cute.assume(%2027#1) : (i32) -> !cute.i32<divby 32>
        %stride_3198 = cute.make_stride(%iv_3196, %iv_3197) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_3199 = cute.make_layout(%2028, %stride_3198) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2029 = cute.static : !cute.int_tuple<"2048">
        %iter_3200 = cute.get_iter(%view_267) : !memref_smem_bf16_7
        %ptr_3201 = cute.add_offset(%iter_3200, %2029) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view_3202 = cute.make_view(%ptr_3201, %lay_3199) : !memref_smem_bf16_16
        %iter_3203 = cute.get_iter(%view_3202) : !memref_smem_bf16_16
        %2030 = cute.static : !cute.int_tuple<"64">
        %iter_3204 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
        %ptr_3205 = cute.add_offset(%iter_3204, %2030) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3206 = cute.make_view(%ptr_3205) : !memref_rmem_bf16_18
        %iter_3207 = cute.get_iter(%view_3206) : !memref_rmem_bf16_18
        %lay_3208 = cute.get_layout(%view_3202) : !memref_smem_bf16_16
        %2031 = cute.static : !cute.layout<"1:0">
        %append_3209 = cute.append_to_rank<2> (%lay_3208, %2031) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_3210 = cute.make_view(%iter_3203, %append_3209) : !memref_smem_bf16_16
        %iter_3211 = cute.get_iter(%view_3210) : !memref_smem_bf16_16
        %lay_3212 = cute.get_layout(%view_3210) : !memref_smem_bf16_16
        %2032:2 = cute.get_scalars(%lay_3212) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2033 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
        %iv_3213 = cute.assume(%2032#0) : (i32) -> !cute.i32<divby 16>
        %iv_3214 = cute.assume(%2032#1) : (i32) -> !cute.i32<divby 32>
        %stride_3215 = cute.make_stride(%iv_3213, %iv_3214) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_3216 = cute.make_layout(%2033, %stride_3215) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %view_3217 = cute.make_view(%iter_3211, %lay_3216) : !memref_smem_bf16_17
        %2034 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %view_3218 = cute.make_view(%iter_3207, %2034) : !memref_rmem_bf16_18
        %iter_3219 = cute.get_iter(%view_3218) : !memref_rmem_bf16_18
        %view_3220 = cute.make_view(%iter_3219) : !memref_rmem_bf16_19
        %2035 = cute.static : !cute.layout<"1:0">
        %iter_3221 = cute.get_iter(%view_3217) : !memref_smem_bf16_17
        %iter_3222 = cute.get_iter(%view_3220) : !memref_rmem_bf16_19
        %lay_3223 = cute.get_layout(%view_3217) : !memref_smem_bf16_17
        %append_3224 = cute.append_to_rank<2> (%lay_3223, %2035) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %2036:2 = cute.get_scalars(%append_3224) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2037 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
        %iv_3225 = cute.assume(%2036#0) : (i32) -> !cute.i32<divby 16>
        %iv_3226 = cute.assume(%2036#1) : (i32) -> !cute.i32<divby 32>
        %stride_3227 = cute.make_stride(%iv_3225, %iv_3226) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_3228 = cute.make_layout(%2037, %stride_3227) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %2038 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %2039 = cute.static : !cute.int_tuple<"8">
        %2040 = cute.get_scalars(%2039) : !cute.int_tuple<"8">
        %c0_i32_3229 = arith.constant 0 : i32
        %c1_i32_3230 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3229 to %2040 step %c1_i32_3230  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %lay_3228) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_3338 = cute.add_offset(%iter_3221, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %2038) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3222, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %2041 = cute.static : !cute.int_tuple<"16">
        %iter_3231 = cute.get_iter(%view_3111) : !memref_rmem_bf16_17
        %ptr_3232 = cute.add_offset(%iter_3231, %2041) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_3233 = cute.make_view(%ptr_3232) : !memref_rmem_bf16_20
        %2042 = cute.static : !cute.int_tuple<"32">
        %iter_3234 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
        %ptr_3235 = cute.add_offset(%iter_3234, %2042) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3236 = cute.make_view(%ptr_3235) : !memref_rmem_bf16_21
        %iter_3237 = cute.get_iter(%view_3233) : !memref_rmem_bf16_20
        %iter_3238 = cute.get_iter(%view_3236) : !memref_rmem_bf16_21
        %iter_3239 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
        %2043 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
        %2044 = cute.static : !cute.layout<"1:0">
        %2045 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
        %2046 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2047 = cute.static : !cute.int_tuple<"1">
        %2048 = cute.static : !cute.int_tuple<"2">
        %2049 = cute.static : !cute.int_tuple<"16">
        %2050 = cute.get_scalars(%2047) : !cute.int_tuple<"1">
        %2051 = cute.get_scalars(%2048) : !cute.int_tuple<"2">
        %2052 = cute.get_scalars(%2049) : !cute.int_tuple<"16">
        %c0_i32_3240 = arith.constant 0 : i32
        %c1_i32_3241 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3240 to %2050 step %c1_i32_3241  : i32 {
          scf.for %arg14 = %c0_i32_3240 to %2051 step %c1_i32_3241  : i32 {
            scf.for %arg15 = %c0_i32_3240 to %2052 step %c1_i32_3241  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
              %idx_3339 = cute.crd2idx(%coord_3336, %2045) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3340 = cute.add_offset(%iter_3237, %idx_3339) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_22
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %2046) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_3238, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %2043) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_3239, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_22
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[4] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[5] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %lay_3242 = cute.get_layout(%view_267) : !memref_smem_bf16_7
        %2053:2 = cute.get_scalars(%lay_3242) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %2054 = cute.static : !cute.shape<"((8,1),((2,2),2))">
        %iv_3243 = cute.assume(%2053#0) : (i32) -> !cute.i32<divby 16>
        %iv_3244 = cute.assume(%2053#1) : (i32) -> !cute.i32<divby 32>
        %stride_3245 = cute.make_stride(%iv_3243, %iv_3244) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_3246 = cute.make_layout(%2054, %stride_3245) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2055 = cute.static : !cute.int_tuple<"3072">
        %iter_3247 = cute.get_iter(%view_267) : !memref_smem_bf16_7
        %ptr_3248 = cute.add_offset(%iter_3247, %2055) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view_3249 = cute.make_view(%ptr_3248, %lay_3246) : !memref_smem_bf16_16
        %iter_3250 = cute.get_iter(%view_3249) : !memref_smem_bf16_16
        %2056 = cute.static : !cute.int_tuple<"96">
        %iter_3251 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
        %ptr_3252 = cute.add_offset(%iter_3251, %2056) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3253 = cute.make_view(%ptr_3252) : !memref_rmem_bf16_18
        %iter_3254 = cute.get_iter(%view_3253) : !memref_rmem_bf16_18
        %lay_3255 = cute.get_layout(%view_3249) : !memref_smem_bf16_16
        %2057 = cute.static : !cute.layout<"1:0">
        %append_3256 = cute.append_to_rank<2> (%lay_3255, %2057) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_3257 = cute.make_view(%iter_3250, %append_3256) : !memref_smem_bf16_16
        %iter_3258 = cute.get_iter(%view_3257) : !memref_smem_bf16_16
        %lay_3259 = cute.get_layout(%view_3257) : !memref_smem_bf16_16
        %2058:2 = cute.get_scalars(%lay_3259) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2059 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
        %iv_3260 = cute.assume(%2058#0) : (i32) -> !cute.i32<divby 16>
        %iv_3261 = cute.assume(%2058#1) : (i32) -> !cute.i32<divby 32>
        %stride_3262 = cute.make_stride(%iv_3260, %iv_3261) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_3263 = cute.make_layout(%2059, %stride_3262) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %view_3264 = cute.make_view(%iter_3258, %lay_3263) : !memref_smem_bf16_17
        %2060 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %view_3265 = cute.make_view(%iter_3254, %2060) : !memref_rmem_bf16_18
        %iter_3266 = cute.get_iter(%view_3265) : !memref_rmem_bf16_18
        %view_3267 = cute.make_view(%iter_3266) : !memref_rmem_bf16_19
        %2061 = cute.static : !cute.layout<"1:0">
        %iter_3268 = cute.get_iter(%view_3264) : !memref_smem_bf16_17
        %iter_3269 = cute.get_iter(%view_3267) : !memref_rmem_bf16_19
        %lay_3270 = cute.get_layout(%view_3264) : !memref_smem_bf16_17
        %append_3271 = cute.append_to_rank<2> (%lay_3270, %2061) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %2062:2 = cute.get_scalars(%append_3271) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2063 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
        %iv_3272 = cute.assume(%2062#0) : (i32) -> !cute.i32<divby 16>
        %iv_3273 = cute.assume(%2062#1) : (i32) -> !cute.i32<divby 32>
        %stride_3274 = cute.make_stride(%iv_3272, %iv_3273) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_3275 = cute.make_layout(%2063, %stride_3274) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %2064 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %2065 = cute.static : !cute.int_tuple<"8">
        %2066 = cute.get_scalars(%2065) : !cute.int_tuple<"8">
        %c0_i32_3276 = arith.constant 0 : i32
        %c1_i32_3277 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3276 to %2066 step %c1_i32_3277  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %lay_3275) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_3338 = cute.add_offset(%iter_3268, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %2064) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3269, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %2067 = cute.static : !cute.int_tuple<"32">
        %iter_3278 = cute.get_iter(%view_3111) : !memref_rmem_bf16_17
        %ptr_3279 = cute.add_offset(%iter_3278, %2067) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_3280 = cute.make_view(%ptr_3279) : !memref_rmem_bf16_20
        %2068 = cute.static : !cute.int_tuple<"64">
        %iter_3281 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
        %ptr_3282 = cute.add_offset(%iter_3281, %2068) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3283 = cute.make_view(%ptr_3282) : !memref_rmem_bf16_21
        %iter_3284 = cute.get_iter(%view_3280) : !memref_rmem_bf16_20
        %iter_3285 = cute.get_iter(%view_3283) : !memref_rmem_bf16_21
        %iter_3286 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
        %2069 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
        %2070 = cute.static : !cute.layout<"1:0">
        %2071 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
        %2072 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2073 = cute.static : !cute.int_tuple<"1">
        %2074 = cute.static : !cute.int_tuple<"2">
        %2075 = cute.static : !cute.int_tuple<"16">
        %2076 = cute.get_scalars(%2073) : !cute.int_tuple<"1">
        %2077 = cute.get_scalars(%2074) : !cute.int_tuple<"2">
        %2078 = cute.get_scalars(%2075) : !cute.int_tuple<"16">
        %c0_i32_3287 = arith.constant 0 : i32
        %c1_i32_3288 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3287 to %2076 step %c1_i32_3288  : i32 {
          scf.for %arg14 = %c0_i32_3287 to %2077 step %c1_i32_3288  : i32 {
            scf.for %arg15 = %c0_i32_3287 to %2078 step %c1_i32_3288  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
              %idx_3339 = cute.crd2idx(%coord_3336, %2071) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3340 = cute.add_offset(%iter_3284, %idx_3339) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_22
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %2072) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_3285, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %2069) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_3286, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_22
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[4] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[5] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %lay_3289 = cute.get_layout(%view_267) : !memref_smem_bf16_7
        %2079:2 = cute.get_scalars(%lay_3289) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %2080 = cute.static : !cute.shape<"((8,1),((2,2),2))">
        %iv_3290 = cute.assume(%2079#0) : (i32) -> !cute.i32<divby 16>
        %iv_3291 = cute.assume(%2079#1) : (i32) -> !cute.i32<divby 32>
        %stride_3292 = cute.make_stride(%iv_3290, %iv_3291) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_3293 = cute.make_layout(%2080, %stride_3292) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2081 = cute.static : !cute.int_tuple<"0">
        %iter_3294 = cute.get_iter(%view_267) : !memref_smem_bf16_7
        %ptr_3295 = cute.add_offset(%iter_3294, %2081) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %view_3296 = cute.make_view(%ptr_3295, %lay_3293) : !memref_smem_bf16_16
        %iter_3297 = cute.get_iter(%view_3296) : !memref_smem_bf16_16
        %2082 = cute.static : !cute.int_tuple<"0">
        %iter_3298 = cute.get_iter(%view_269) : !memref_rmem_bf16_5
        %ptr_3299 = cute.add_offset(%iter_3298, %2082) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3300 = cute.make_view(%ptr_3299) : !memref_rmem_bf16_18
        %iter_3301 = cute.get_iter(%view_3300) : !memref_rmem_bf16_18
        %lay_3302 = cute.get_layout(%view_3296) : !memref_smem_bf16_16
        %2083 = cute.static : !cute.layout<"1:0">
        %append_3303 = cute.append_to_rank<2> (%lay_3302, %2083) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %view_3304 = cute.make_view(%iter_3297, %append_3303) : !memref_smem_bf16_16
        %iter_3305 = cute.get_iter(%view_3304) : !memref_smem_bf16_16
        %lay_3306 = cute.get_layout(%view_3304) : !memref_smem_bf16_16
        %2084:2 = cute.get_scalars(%lay_3306) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2085 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
        %iv_3307 = cute.assume(%2084#0) : (i32) -> !cute.i32<divby 16>
        %iv_3308 = cute.assume(%2084#1) : (i32) -> !cute.i32<divby 32>
        %stride_3309 = cute.make_stride(%iv_3307, %iv_3308) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_3310 = cute.make_layout(%2085, %stride_3309) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %view_3311 = cute.make_view(%iter_3305, %lay_3310) : !memref_smem_bf16_17
        %2086 = cute.static : !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %view_3312 = cute.make_view(%iter_3301, %2086) : !memref_rmem_bf16_18
        %iter_3313 = cute.get_iter(%view_3312) : !memref_rmem_bf16_18
        %view_3314 = cute.make_view(%iter_3313) : !memref_rmem_bf16_19
        %2087 = cute.static : !cute.layout<"1:0">
        %iter_3315 = cute.get_iter(%view_3311) : !memref_smem_bf16_17
        %iter_3316 = cute.get_iter(%view_3314) : !memref_rmem_bf16_19
        %lay_3317 = cute.get_layout(%view_3311) : !memref_smem_bf16_17
        %append_3318 = cute.append_to_rank<2> (%lay_3317, %2087) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %2088:2 = cute.get_scalars(%append_3318) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2089 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
        %iv_3319 = cute.assume(%2088#0) : (i32) -> !cute.i32<divby 16>
        %iv_3320 = cute.assume(%2088#1) : (i32) -> !cute.i32<divby 32>
        %stride_3321 = cute.make_stride(%iv_3319, %iv_3320) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_3322 = cute.make_layout(%2089, %stride_3321) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %2090 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %2091 = cute.static : !cute.int_tuple<"8">
        %2092 = cute.get_scalars(%2091) : !cute.int_tuple<"8">
        %c0_i32_3323 = arith.constant 0 : i32
        %c1_i32_3324 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3323 to %2092 step %c1_i32_3324  : i32 {
          %coord_3336 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %2105 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3337 = cute.crd2idx(%coord_3336, %lay_3322) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_3338 = cute.add_offset(%iter_3315, %idx_3337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %view_3339 = cute.make_view(%ptr_3338, %2105) : !memref_smem_bf16_10
          %2106 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_3340 = cute.crd2idx(%coord_3336, %2090) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_3341 = cute.add_offset(%iter_3316, %idx_3340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %view_3342 = cute.make_view(%ptr_3341, %2106) : !memref_rmem_bf16_11
          %iter_3343 = cute.get_iter(%view_3339) : !memref_smem_bf16_10
          %iter_3344 = cute.get_iter(%view_3342) : !memref_rmem_bf16_11
          %swizzled = cute.apply_swizzle(%iter_3343) : !cute.ptr<bf16, smem, align<16>>
          %2107 = cute_nvgpu.arch.copy.ldsm %swizzled{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %2108 = llvm.mlir.constant(0 : i32) : i32
          %2109 = vector.extractelement %2107[%2108 : i32] : vector<4xi32>
          %2110 = builtin.unrealized_conversion_cast %iter_3344 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2109, %2110 : i32, !llvm.ptr
          %2111 = llvm.mlir.constant(1 : i32) : i32
          %2112 = vector.extractelement %2107[%2111 : i32] : vector<4xi32>
          %2113 = cute.static : !cute.int_tuple<"2">
          %ptr_3345 = cute.add_offset(%iter_3344, %2113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2114 = builtin.unrealized_conversion_cast %ptr_3345 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2112, %2114 : i32, !llvm.ptr
          %2115 = llvm.mlir.constant(2 : i32) : i32
          %2116 = vector.extractelement %2107[%2115 : i32] : vector<4xi32>
          %2117 = cute.static : !cute.int_tuple<"4">
          %ptr_3346 = cute.add_offset(%iter_3344, %2117) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2118 = builtin.unrealized_conversion_cast %ptr_3346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %2116, %2118 : i32, !llvm.ptr
          %2119 = llvm.mlir.constant(3 : i32) : i32
          %2120 = vector.extractelement %2107[%2119 : i32] : vector<4xi32>
          %2121 = cute.static : !cute.int_tuple<"6">
          %ptr_3347 = cute.add_offset(%iter_3344, %2121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2122 = builtin.unrealized_conversion_cast %ptr_3347 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %2120, %2122 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %2093 = cute.static : !cute.int_tuple<"48">
        %iter_3325 = cute.get_iter(%view_3111) : !memref_rmem_bf16_17
        %ptr_3326 = cute.add_offset(%iter_3325, %2093) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_3327 = cute.make_view(%ptr_3326) : !memref_rmem_bf16_20
        %2094 = cute.static : !cute.int_tuple<"96">
        %iter_3328 = cute.get_iter(%rmem_182) : !memref_rmem_bf16_2
        %ptr_3329 = cute.add_offset(%iter_3328, %2094) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_3330 = cute.make_view(%ptr_3329) : !memref_rmem_bf16_21
        %iter_3331 = cute.get_iter(%view_3327) : !memref_rmem_bf16_20
        %iter_3332 = cute.get_iter(%view_3330) : !memref_rmem_bf16_21
        %iter_3333 = cute.get_iter(%rmem_183) : !memref_rmem_f32_
        %2095 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
        %2096 = cute.static : !cute.layout<"1:0">
        %2097 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
        %2098 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2099 = cute.static : !cute.int_tuple<"1">
        %2100 = cute.static : !cute.int_tuple<"2">
        %2101 = cute.static : !cute.int_tuple<"16">
        %2102 = cute.get_scalars(%2099) : !cute.int_tuple<"1">
        %2103 = cute.get_scalars(%2100) : !cute.int_tuple<"2">
        %2104 = cute.get_scalars(%2101) : !cute.int_tuple<"16">
        %c0_i32_3334 = arith.constant 0 : i32
        %c1_i32_3335 = arith.constant 1 : i32
        scf.for %arg13 = %c0_i32_3334 to %2102 step %c1_i32_3335  : i32 {
          scf.for %arg14 = %c0_i32_3334 to %2103 step %c1_i32_3335  : i32 {
            scf.for %arg15 = %c0_i32_3334 to %2104 step %c1_i32_3335  : i32 {
              %coord_3336 = cute.make_coord(%arg14, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3337 = cute.make_coord(%arg15, %arg13) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_3338 = cute.make_coord(%arg14, %arg15) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2105 = cute.static : !cute.layout<"(((2,2),2)):(((1,2),8))">
              %idx_3339 = cute.crd2idx(%coord_3336, %2097) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3340 = cute.add_offset(%iter_3331, %idx_3339) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3341 = cute.make_view(%ptr_3340, %2105) : !memref_rmem_bf16_22
              %2106 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3342 = cute.crd2idx(%coord_3337, %2098) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3343 = cute.add_offset(%iter_3332, %idx_3342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %view_3344 = cute.make_view(%ptr_3343, %2106) : !memref_rmem_bf16_15
              %2107 = cute.static : !cute.layout<"((2,2)):((1,2))">
              %idx_3345 = cute.crd2idx(%coord_3338, %2095) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_3346 = cute.add_offset(%iter_3333, %idx_3345) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %view_3347 = cute.make_view(%ptr_3346, %2107) : !memref_rmem_f32_3
              %iter_3348 = cute.get_iter(%view_3341) : !memref_rmem_bf16_22
              %iter_3349 = cute.get_iter(%view_3344) : !memref_rmem_bf16_15
              %iter_3350 = cute.get_iter(%view_3347) : !memref_rmem_f32_3
              %2108 = builtin.unrealized_conversion_cast %iter_3348 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2109 = llvm.load %2108 : !llvm.ptr -> i32
              %2110 = llvm.getelementptr %2108[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2111 = llvm.load %2110 : !llvm.ptr -> i32
              %2112 = llvm.getelementptr %2108[4] : (!llvm.ptr) -> !llvm.ptr, i32
              %2113 = llvm.load %2112 : !llvm.ptr -> i32
              %2114 = llvm.getelementptr %2108[5] : (!llvm.ptr) -> !llvm.ptr, i32
              %2115 = llvm.load %2114 : !llvm.ptr -> i32
              %2116 = builtin.unrealized_conversion_cast %iter_3349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %2117 = llvm.load %2116 : !llvm.ptr -> i32
              %2118 = llvm.getelementptr %2116[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %2119 = llvm.load %2118 : !llvm.ptr -> i32
              %2120 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %2121 = llvm.load %2120 : !llvm.ptr -> f32
              %2122 = llvm.getelementptr %2120[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %2123 = llvm.load %2122 : !llvm.ptr -> f32
              %2124 = llvm.getelementptr %2120[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %2125 = llvm.load %2124 : !llvm.ptr -> f32
              %2126 = llvm.getelementptr %2120[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %2127 = llvm.load %2126 : !llvm.ptr -> f32
              %2128:4 = cute_nvgpu.arch.mma.SM80 A[%2109, %2111, %2113, %2115]  B[%2117, %2119]  C[%2121, %2123, %2125, %2127] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %2129 = builtin.unrealized_conversion_cast %iter_3350 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %2128#0, %2129 : f32, !llvm.ptr
              %2130 = llvm.getelementptr %2129[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#1, %2130 : f32, !llvm.ptr
              %2131 = llvm.getelementptr %2129[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#2, %2131 : f32, !llvm.ptr
              %2132 = llvm.getelementptr %2129[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %2128#3, %2132 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.yield %1583, %arg7, %1583, %arg9, %arg10, %arg11, %arg12 : i32, i32, i32, !memref_gmem_bf16_, !memref_gmem_bf16_, i32, i32
      }
      %1289 = cute.static : !cute.layout<"((2,2),(2,16)):((2,4),(1,8))">
      %view_2177 = cute.make_view(%iter_184, %1289) : !memref_rmem_f32_8
      %1290 = cute.static : !cute.coord<"0">
      %1291 = cute.memref.load(%rmem_624, %1290) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %c-1_i32_2178 = arith.constant -1 : i32
      %c2_i32_2179 = arith.constant 2 : i32
      %c31_i32_2180 = arith.constant 31 : i32
      %1292 = nvvm.shfl.sync  bfly %c-1_i32_2178, %1291, %c2_i32_2179, %c31_i32_2180 : f32 -> f32
      %1293 = arith.addf %1291, %1292 : f32
      %c-1_i32_2181 = arith.constant -1 : i32
      %c1_i32_2182 = arith.constant 1 : i32
      %c31_i32_2183 = arith.constant 31 : i32
      %1294 = nvvm.shfl.sync  bfly %c-1_i32_2181, %1293, %c1_i32_2182, %c31_i32_2183 : f32 -> f32
      %1295 = arith.addf %1293, %1294 : f32
      %1296 = cute.static : !cute.coord<"0">
      cute.memref.store(%rmem_624, %1296, %1295) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      %1297 = cute.static : !cute.coord<"0">
      %1298 = cute.memref.load(%rmem_624, %1297) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %cst_2184 = arith.constant 0.000000e+00 : f32
      %1299 = cute.static : !cute.coord<"0">
      %1300 = cute.memref.load(%rmem_624, %1299) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1301 = arith.cmpf oeq, %1300, %cst_2184 : f32
      %1302 = cute.static : !cute.coord<"0">
      %1303 = cute.memref.load(%rmem_624, %1302) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1304 = cute.static : !cute.coord<"0">
      %1305 = cute.memref.load(%rmem_624, %1304) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1306 = arith.cmpf une, %1303, %1305 : f32
      %1307 = arith.extui %1301 : i1 to i32
      %c0_i32_2185 = arith.constant 0 : i32
      %1308 = arith.cmpi ne, %1307, %c0_i32_2185 : i32
      %1309 = arith.extui %1301 : i1 to i32
      %1310 = arith.extui %1306 : i1 to i32
      %1311 = arith.select %1308, %1309, %1310 : i32
      %c0_i32_2186 = arith.constant 0 : i32
      %1312 = arith.cmpi ne, %1311, %c0_i32_2186 : i32
      %1313 = cute.static : !cute.coord<"0">
      %1314 = cute.memref.load(%rmem_624, %1313) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1315 = nvvm.rcp.approx.ftz.f %1314 : f32
      %cst_2187 = arith.constant 1.000000e+00 : f32
      %1316 = arith.select %1312, %cst_2187, %1315 : f32
      %1317 = cute.static : !cute.int_tuple<"0">
      %iter_2188 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2189 = cute.add_offset(%iter_2188, %1317) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
      %view_2190 = cute.make_view(%ptr_2189) : !memref_rmem_f32_10
      %1318 = cute.memref.load_vec %view_2190 : !memref_rmem_f32_10
      %1319 = vector.broadcast %1316 : f32 to vector<32xf32>
      %1320 = arith.mulf %1318, %1319 : vector<32xf32>
      %1321 = cute.static : !cute.int_tuple<"0">
      %iter_2191 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2192 = cute.add_offset(%iter_2191, %1321) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
      %view_2193 = cute.make_view(%ptr_2192) : !memref_rmem_f32_10
      cute.memref.store_vec %1320, %view_2193 : !memref_rmem_f32_10
      %1322 = cute.static : !cute.coord<"1">
      %1323 = cute.memref.load(%rmem_624, %1322) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %c-1_i32_2194 = arith.constant -1 : i32
      %c2_i32_2195 = arith.constant 2 : i32
      %c31_i32_2196 = arith.constant 31 : i32
      %1324 = nvvm.shfl.sync  bfly %c-1_i32_2194, %1323, %c2_i32_2195, %c31_i32_2196 : f32 -> f32
      %1325 = arith.addf %1323, %1324 : f32
      %c-1_i32_2197 = arith.constant -1 : i32
      %c1_i32_2198 = arith.constant 1 : i32
      %c31_i32_2199 = arith.constant 31 : i32
      %1326 = nvvm.shfl.sync  bfly %c-1_i32_2197, %1325, %c1_i32_2198, %c31_i32_2199 : f32 -> f32
      %1327 = arith.addf %1325, %1326 : f32
      %1328 = cute.static : !cute.coord<"1">
      cute.memref.store(%rmem_624, %1328, %1327) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      %1329 = cute.static : !cute.coord<"1">
      %1330 = cute.memref.load(%rmem_624, %1329) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1331 = cute.static : !cute.coord<"1">
      %1332 = cute.memref.load(%rmem_624, %1331) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1333 = arith.cmpf oeq, %1332, %cst_2184 : f32
      %1334 = cute.static : !cute.coord<"1">
      %1335 = cute.memref.load(%rmem_624, %1334) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1336 = cute.static : !cute.coord<"1">
      %1337 = cute.memref.load(%rmem_624, %1336) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1338 = arith.cmpf une, %1335, %1337 : f32
      %1339 = arith.extui %1333 : i1 to i32
      %1340 = arith.cmpi ne, %1339, %c0_i32_2185 : i32
      %1341 = arith.extui %1333 : i1 to i32
      %1342 = arith.extui %1338 : i1 to i32
      %1343 = arith.select %1340, %1341, %1342 : i32
      %1344 = arith.cmpi ne, %1343, %c0_i32_2186 : i32
      %1345 = cute.static : !cute.coord<"1">
      %1346 = cute.memref.load(%rmem_624, %1345) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1347 = nvvm.rcp.approx.ftz.f %1346 : f32
      %1348 = arith.select %1344, %cst_2187, %1347 : f32
      %1349 = cute.static : !cute.int_tuple<"2">
      %iter_2200 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2201 = cute.add_offset(%iter_2200, %1349) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_2202 = cute.make_view(%ptr_2201) : !memref_rmem_f32_11
      %1350 = cute.memref.load_vec %view_2202 : !memref_rmem_f32_11
      %1351 = vector.broadcast %1348 : f32 to vector<32xf32>
      %1352 = arith.mulf %1350, %1351 : vector<32xf32>
      %1353 = cute.static : !cute.int_tuple<"2">
      %iter_2203 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2204 = cute.add_offset(%iter_2203, %1353) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_2205 = cute.make_view(%ptr_2204) : !memref_rmem_f32_11
      cute.memref.store_vec %1352, %view_2205 : !memref_rmem_f32_11
      %1354 = cute.static : !cute.coord<"2">
      %1355 = cute.memref.load(%rmem_624, %1354) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %c-1_i32_2206 = arith.constant -1 : i32
      %c2_i32_2207 = arith.constant 2 : i32
      %c31_i32_2208 = arith.constant 31 : i32
      %1356 = nvvm.shfl.sync  bfly %c-1_i32_2206, %1355, %c2_i32_2207, %c31_i32_2208 : f32 -> f32
      %1357 = arith.addf %1355, %1356 : f32
      %c-1_i32_2209 = arith.constant -1 : i32
      %c1_i32_2210 = arith.constant 1 : i32
      %c31_i32_2211 = arith.constant 31 : i32
      %1358 = nvvm.shfl.sync  bfly %c-1_i32_2209, %1357, %c1_i32_2210, %c31_i32_2211 : f32 -> f32
      %1359 = arith.addf %1357, %1358 : f32
      %1360 = cute.static : !cute.coord<"2">
      cute.memref.store(%rmem_624, %1360, %1359) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      %1361 = cute.static : !cute.coord<"2">
      %1362 = cute.memref.load(%rmem_624, %1361) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1363 = cute.static : !cute.coord<"2">
      %1364 = cute.memref.load(%rmem_624, %1363) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1365 = arith.cmpf oeq, %1364, %cst_2184 : f32
      %1366 = cute.static : !cute.coord<"2">
      %1367 = cute.memref.load(%rmem_624, %1366) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1368 = cute.static : !cute.coord<"2">
      %1369 = cute.memref.load(%rmem_624, %1368) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1370 = arith.cmpf une, %1367, %1369 : f32
      %1371 = arith.extui %1365 : i1 to i32
      %1372 = arith.cmpi ne, %1371, %c0_i32_2185 : i32
      %1373 = arith.extui %1365 : i1 to i32
      %1374 = arith.extui %1370 : i1 to i32
      %1375 = arith.select %1372, %1373, %1374 : i32
      %1376 = arith.cmpi ne, %1375, %c0_i32_2186 : i32
      %1377 = cute.static : !cute.coord<"2">
      %1378 = cute.memref.load(%rmem_624, %1377) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1379 = nvvm.rcp.approx.ftz.f %1378 : f32
      %1380 = arith.select %1376, %cst_2187, %1379 : f32
      %1381 = cute.static : !cute.int_tuple<"4">
      %iter_2212 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2213 = cute.add_offset(%iter_2212, %1381) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_2214 = cute.make_view(%ptr_2213) : !memref_rmem_f32_12
      %1382 = cute.memref.load_vec %view_2214 : !memref_rmem_f32_12
      %1383 = vector.broadcast %1380 : f32 to vector<32xf32>
      %1384 = arith.mulf %1382, %1383 : vector<32xf32>
      %1385 = cute.static : !cute.int_tuple<"4">
      %iter_2215 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2216 = cute.add_offset(%iter_2215, %1385) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_2217 = cute.make_view(%ptr_2216) : !memref_rmem_f32_12
      cute.memref.store_vec %1384, %view_2217 : !memref_rmem_f32_12
      %1386 = cute.static : !cute.coord<"3">
      %1387 = cute.memref.load(%rmem_624, %1386) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %c-1_i32_2218 = arith.constant -1 : i32
      %c2_i32_2219 = arith.constant 2 : i32
      %c31_i32_2220 = arith.constant 31 : i32
      %1388 = nvvm.shfl.sync  bfly %c-1_i32_2218, %1387, %c2_i32_2219, %c31_i32_2220 : f32 -> f32
      %1389 = arith.addf %1387, %1388 : f32
      %c-1_i32_2221 = arith.constant -1 : i32
      %c1_i32_2222 = arith.constant 1 : i32
      %c31_i32_2223 = arith.constant 31 : i32
      %1390 = nvvm.shfl.sync  bfly %c-1_i32_2221, %1389, %c1_i32_2222, %c31_i32_2223 : f32 -> f32
      %1391 = arith.addf %1389, %1390 : f32
      %1392 = cute.static : !cute.coord<"3">
      cute.memref.store(%rmem_624, %1392, %1391) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      %1393 = cute.static : !cute.coord<"3">
      %1394 = cute.memref.load(%rmem_624, %1393) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1395 = cute.static : !cute.coord<"3">
      %1396 = cute.memref.load(%rmem_624, %1395) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1397 = arith.cmpf oeq, %1396, %cst_2184 : f32
      %1398 = cute.static : !cute.coord<"3">
      %1399 = cute.memref.load(%rmem_624, %1398) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1400 = cute.static : !cute.coord<"3">
      %1401 = cute.memref.load(%rmem_624, %1400) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1402 = arith.cmpf une, %1399, %1401 : f32
      %1403 = arith.extui %1397 : i1 to i32
      %1404 = arith.cmpi ne, %1403, %c0_i32_2185 : i32
      %1405 = arith.extui %1397 : i1 to i32
      %1406 = arith.extui %1402 : i1 to i32
      %1407 = arith.select %1404, %1405, %1406 : i32
      %1408 = arith.cmpi ne, %1407, %c0_i32_2186 : i32
      %1409 = cute.static : !cute.coord<"3">
      %1410 = cute.memref.load(%rmem_624, %1409) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1411 = nvvm.rcp.approx.ftz.f %1410 : f32
      %1412 = arith.select %1408, %cst_2187, %1411 : f32
      %1413 = cute.static : !cute.int_tuple<"6">
      %iter_2224 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2225 = cute.add_offset(%iter_2224, %1413) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_2226 = cute.make_view(%ptr_2225) : !memref_rmem_f32_11
      %1414 = cute.memref.load_vec %view_2226 : !memref_rmem_f32_11
      %1415 = vector.broadcast %1412 : f32 to vector<32xf32>
      %1416 = arith.mulf %1414, %1415 : vector<32xf32>
      %1417 = cute.static : !cute.int_tuple<"6">
      %iter_2227 = cute.get_iter(%view_2177) : !memref_rmem_f32_8
      %ptr_2228 = cute.add_offset(%iter_2227, %1417) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_2229 = cute.make_view(%ptr_2228) : !memref_rmem_f32_11
      cute.memref.store_vec %1416, %view_2229 : !memref_rmem_f32_11
      %1418 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %rmem_2230 = cute.memref.alloca(%1418) : !memref_rmem_bf16_23
      %1419 = cute.memref.load_vec %rmem_183 : !memref_rmem_f32_
      %1420 = arith.truncf %1419 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %1420, %rmem_2230 : !memref_rmem_bf16_23
      %view_2231 = cute.make_view(%iter_81, %2) : !memref_smem_bf16_
      %atom_2232 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %1421 = cute.static : !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %1422 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %1423 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
      %1424 = cute.make_tiled_copy(%atom_2232) : !copy_simt1
      %iter_2233 = cute.get_iter(%rmem_2230) : !memref_rmem_bf16_23
      %view_2234 = cute.make_view(%iter_2233) : !memref_rmem_bf16_24
      %iter_2235 = cute.get_iter(%view_2234) : !memref_rmem_bf16_24
      %coord_2236 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_2237 = cute.get_iter(%view_2231) : !memref_smem_bf16_
      %1425 = cute.get_scalars(%coord_2236) <{only_dynamic}> : !cute.coord<"?">
      %c4_i32_2238 = arith.constant 4 : i32
      %1426 = arith.divsi %1425, %c4_i32_2238 : i32
      %c8_i32_2239 = arith.constant 8 : i32
      %1427 = arith.remsi %1426, %c8_i32_2239 : i32
      %c64_i32_2240 = arith.constant 64 : i32
      %1428 = arith.muli %1427, %c64_i32_2240 : i32
      %c0_i32_2241 = arith.constant 0 : i32
      %1429 = arith.xori %1428, %c0_i32_2241 : i32
      %c4_i32_2242 = arith.constant 4 : i32
      %1430 = arith.divsi %1425, %c4_i32_2242 : i32
      %c4_i32_2243 = arith.constant 4 : i32
      %1431 = arith.remsi %1425, %c4_i32_2243 : i32
      %c2_i32_2244 = arith.constant 2 : i32
      %1432 = arith.muli %1431, %c2_i32_2244 : i32
      %c8_i32_2245 = arith.constant 8 : i32
      %1433 = arith.divsi %1430, %c8_i32_2245 : i32
      %c1024_i32_2246 = arith.constant 1024 : i32
      %1434 = arith.muli %1433, %c1024_i32_2246 : i32
      %1435 = arith.addi %1432, %1434 : i32
      %c64_i32_2247 = arith.constant 64 : i32
      %1436 = arith.andi %1429, %c64_i32_2247 : i32
      %c0_i32_2248 = arith.constant 0 : i32
      %1437 = arith.cmpi eq, %1436, %c0_i32_2248 : i32
      %1438 = scf.if %1437 -> (i32) {
        %c8_i32_2576 = arith.constant 8 : i32
        scf.yield %c8_i32_2576 : i32
      } else {
        %c-8_i32 = arith.constant -8 : i32
        scf.yield %c-8_i32 : i32
      }
      %c128_i32_2249 = arith.constant 128 : i32
      %1439 = arith.andi %1429, %c128_i32_2249 : i32
      %c0_i32_2250 = arith.constant 0 : i32
      %1440 = arith.cmpi eq, %1439, %c0_i32_2250 : i32
      %1441 = scf.if %1440 -> (i32) {
        %c16_i32_2576 = arith.constant 16 : i32
        scf.yield %c16_i32_2576 : i32
      } else {
        %c-16_i32 = arith.constant -16 : i32
        scf.yield %c-16_i32 : i32
      }
      %c256_i32_2251 = arith.constant 256 : i32
      %1442 = arith.andi %1429, %c256_i32_2251 : i32
      %c0_i32_2252 = arith.constant 0 : i32
      %1443 = arith.cmpi eq, %1442, %c0_i32_2252 : i32
      %1444 = scf.if %1443 -> (i32) {
        %c32_i32_2576 = arith.constant 32 : i32
        scf.yield %c32_i32_2576 : i32
      } else {
        %c-32_i32 = arith.constant -32 : i32
        scf.yield %c-32_i32 : i32
      }
      %c448_i32_2253 = arith.constant 448 : i32
      %1445 = arith.andi %1429, %c448_i32_2253 : i32
      %c3_i32_2254 = arith.constant 3 : i32
      %1446 = arith.shrsi %1445, %c3_i32_2254 : i32
      %1447 = arith.xori %1429, %1446 : i32
      %1448 = arith.addi %1447, %1435 : i32
      %iv_2255 = cute.assume(%1448) : (i32) -> !cute.i32<divby 2>
      %int_tuple_2256 = cute.make_int_tuple(%iv_2255) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_2257 = cute.add_offset(%iter_2237, %int_tuple_2256) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>>
      %1449 = cute.static : !cute.shape<"((1,(2,2,2)),2,((2,2),2))">
      %iv_2258 = cute.assume(%1438) : (i32) -> !cute.i32<divby 8>
      %iv_2259 = cute.assume(%1441) : (i32) -> !cute.i32<divby 16>
      %iv_2260 = cute.assume(%1444) : (i32) -> !cute.i32<divby 32>
      %stride_2261 = cute.make_stride(%iv_2258, %iv_2259, %iv_2260) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %lay_2262 = cute.make_layout(%1449, %stride_2261) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %view_2263 = cute.make_view(%ptr_2257, %lay_2262) : !memref_smem_bf16_18
      %iter_2264 = cute.get_iter(%view_2263) : !memref_smem_bf16_18
      %1450 = cute.static : !cute.layout<"((1,(4,2)),2,8):((0,(1,8)),4,16)">
      %view_2265 = cute.make_view(%iter_2235, %1450) : !memref_rmem_bf16_24
      %iter_2266 = cute.get_iter(%view_2265) : !memref_rmem_bf16_24
      %view_2267 = cute.make_view(%iter_2266) : !memref_rmem_bf16_25
      %lay_2268 = cute.get_layout(%view_2263) : !memref_smem_bf16_18
      %1451 = cute.static : !cute.layout<"1:0">
      %append_2269 = cute.append_to_rank<2> (%lay_2268, %1451) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">, !cute.layout<"1:0">
      %view_2270 = cute.make_view(%iter_2264, %append_2269) : !memref_smem_bf16_18
      %iter_2271 = cute.get_iter(%view_2270) : !memref_smem_bf16_18
      %lay_2272 = cute.get_layout(%view_2270) : !memref_smem_bf16_18
      %1452:3 = cute.get_scalars(%lay_2272) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %1453 = cute.static : !cute.shape<"((1,(2,2,2)),(2,((2,2),2)))">
      %iv_2273 = cute.assume(%1452#0) : (i32) -> !cute.i32<divby 8>
      %iv_2274 = cute.assume(%1452#1) : (i32) -> !cute.i32<divby 16>
      %iv_2275 = cute.assume(%1452#2) : (i32) -> !cute.i32<divby 32>
      %stride_2276 = cute.make_stride(%iv_2273, %iv_2274, %iv_2275) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %lay_2277 = cute.make_layout(%1453, %stride_2276) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %view_2278 = cute.make_view(%iter_2271, %lay_2277) : !memref_smem_bf16_19
      %1454 = cute.static : !cute.layout<"1:0">
      %iter_2279 = cute.get_iter(%view_2267) : !memref_rmem_bf16_25
      %iter_2280 = cute.get_iter(%view_2278) : !memref_smem_bf16_19
      %lay_2281 = cute.get_layout(%view_2278) : !memref_smem_bf16_19
      %append_2282 = cute.append_to_rank<2> (%lay_2281, %1454) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">, !cute.layout<"1:0">
      %1455 = cute.static : !cute.layout<"((1,(4,2)),((2,8))):((0,(1,8)),((4,16)))">
      %1456:3 = cute.get_scalars(%append_2282) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %1457 = cute.static : !cute.shape<"((1,(2,2,2)),((2,((2,2),2))))">
      %iv_2283 = cute.assume(%1456#0) : (i32) -> !cute.i32<divby 8>
      %iv_2284 = cute.assume(%1456#1) : (i32) -> !cute.i32<divby 16>
      %iv_2285 = cute.assume(%1456#2) : (i32) -> !cute.i32<divby 32>
      %stride_2286 = cute.make_stride(%iv_2283, %iv_2284, %iv_2285) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %lay_2287 = cute.make_layout(%1457, %stride_2286) : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %1458 = cute.static : !cute.int_tuple<"16">
      %1459 = cute.get_scalars(%1458) : !cute.int_tuple<"16">
      %c0_i32_2288 = arith.constant 0 : i32
      %c1_i32_2289 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2288 to %1459 step %c1_i32_2289  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((1,(4,2))):((0,(1,8)))">
        %idx_2577 = cute.crd2idx(%coord_2576, %1455) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,2)),((2,8))):((0,(1,8)),((4,16)))">) -> !cute.int_tuple<"?{div=4}">
        %ptr_2578 = cute.add_offset(%iter_2279, %idx_2577) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_rmem_bf16_26
        %1583:3 = cute.get_scalars(%lay_2287) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
        %1584 = cute.static : !cute.shape<"((1,(2,2,2)))">
        %iv_2580 = cute.assume(%1583#0) : (i32) -> !cute.i32<divby 8>
        %stride_2581 = cute.make_stride(%iv_2580) : (!cute.i32<divby 8>) -> !cute.stride<"((0,(1,512,?{div=8})))">
        %lay_2582 = cute.make_layout(%1584, %stride_2581) : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
        %idx_2583 = cute.crd2idx(%coord_2576, %lay_2287) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_2584 = cute.add_offset(%iter_2280, %idx_2583) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>>
        %view_2585 = cute.make_view(%ptr_2584, %lay_2582) : !memref_smem_bf16_20
        %iter_2586 = cute.get_iter(%view_2579) : !memref_rmem_bf16_26
        %iter_2587 = cute.get_iter(%view_2585) : !memref_smem_bf16_20
        %lay_2588 = cute.get_layout(%view_2585) : !memref_smem_bf16_20
        %1585 = cute.get_scalars(%lay_2588) <{only_dynamic}> : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
        %1586 = builtin.unrealized_conversion_cast %iter_2586 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        %1587 = builtin.unrealized_conversion_cast %iter_2587 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
        %1588 = llvm.load %1586 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %1588, %1587 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %1589 = cute.static : !cute.int_tuple<"2">
        %ptr_2589 = cute.add_offset(%iter_2586, %1589) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1590 = cute.static : !cute.int_tuple<"512">
        %ptr_2590 = cute.add_offset(%iter_2587, %1590) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>>
        %1591 = builtin.unrealized_conversion_cast %ptr_2589 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %1592 = builtin.unrealized_conversion_cast %ptr_2590 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
        %1593 = llvm.load %1591 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %1593, %1592 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %1594 = cute.static : !cute.int_tuple<"8">
        %ptr_2591 = cute.add_offset(%iter_2586, %1594) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<8>>
        %iv_2592 = cute.assume(%1585) : (i32) -> !cute.i32<divby 8>
        %int_tuple_2593 = cute.make_int_tuple(%iv_2592) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_2594 = cute.add_offset(%iter_2587, %int_tuple_2593) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
        %1595 = builtin.unrealized_conversion_cast %ptr_2591 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        %1596 = builtin.unrealized_conversion_cast %ptr_2594 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
        %1597 = llvm.load %1595 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %1597, %1596 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %1598 = cute.static : !cute.int_tuple<"10">
        %ptr_2595 = cute.add_offset(%iter_2586, %1598) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
        %c512_i32_2596 = arith.constant 512 : i32
        %1599 = arith.addi %1585, %c512_i32_2596 : i32
        %iv_2597 = cute.assume(%1599) : (i32) -> !cute.i32<divby 8>
        %int_tuple_2598 = cute.make_int_tuple(%iv_2597) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_2599 = cute.add_offset(%iter_2587, %int_tuple_2598) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
        %1600 = builtin.unrealized_conversion_cast %ptr_2595 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %1601 = builtin.unrealized_conversion_cast %ptr_2599 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
        %1602 = llvm.load %1600 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %1602, %1601 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      } {llvm.loop_annotation = #loop_annotation}
      %coord_2290 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_2291 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1460:7 = cute.get_scalars(%lay_2291) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_2292 = cute.assume(%1460#3) : (i32) -> !cute.i32<divby 8>
      %shape_2293 = cute.make_shape(%1460#1, %iv_2292) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_2294 = cute.assume(%1460#5) : (i64) -> !cute.i64<divby 8>
      %stride_2295 = cute.make_stride(%iv_2294) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_2296 = cute.make_layout(%shape_2293, %stride_2295) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_2297 = cute.crd2idx(%coord_2290, %lay_2291) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_2298 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_2299 = cute.add_offset(%iter_2298, %idx_2297) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_2300 = cute.make_view(%ptr_2299, %lay_2296) : !memref_gmem_bf16_1
      %coord_2301 = cute.make_coord(%24) : (i32) -> !cute.coord<"(?,0)">
      %1461 = cute.get_scalars(%coord_2301) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_2302 = cute.make_coord(%1461) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_2303 = cute.get_layout(%view_2300) : !memref_gmem_bf16_1
      %1462:3 = cute.get_scalars(%lay_2303) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c128_i32_2304 = arith.constant 128 : i32
      %1463 = arith.ceildivsi %1462#0, %c128_i32_2304 : i32
      %c128_i64_2305 = arith.constant 128 : i64
      %1464 = arith.muli %1462#2, %c128_i64_2305 : i64
      %c128_i32_2306 = arith.constant 128 : i32
      %1465 = arith.ceildivsi %1462#1, %c128_i32_2306 : i32
      %shape_2307 = cute.make_shape(%1463, %1465) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_2308 = cute.assume(%1462#2) : (i64) -> !cute.i64<divby 8>
      %iv_2309 = cute.assume(%1464) : (i64) -> !cute.i64<divby 1024>
      %stride_2310 = cute.make_stride(%iv_2308, %iv_2309) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_2311 = cute.make_layout(%shape_2307, %stride_2310) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %1466:4 = cute.get_scalars(%lay_2311) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %1467 = cute.static : !cute.shape<"(128,128)">
      %iv_2312 = cute.assume(%1466#2) : (i64) -> !cute.i64<divby 8>
      %stride_2313 = cute.make_stride(%iv_2312) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_2314 = cute.make_layout(%1467, %stride_2313) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_2315 = cute.crd2idx(%coord_2302, %lay_2311) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %iter_2316 = cute.get_iter(%view_2300) : !memref_gmem_bf16_1
      %ptr_2317 = cute.add_offset(%iter_2316, %idx_2315) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_2318 = cute.make_view(%ptr_2317, %lay_2314) : !memref_gmem_bf16_2
      %coord_2319 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_2320 = cute.get_iter(%view_2231) : !memref_smem_bf16_
      %1468 = cute.get_scalars(%coord_2319) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_2321 = arith.constant 8 : i32
      %1469 = arith.divsi %1468, %c8_i32_2321 : i32
      %c8_i32_2322 = arith.constant 8 : i32
      %1470 = arith.remsi %1468, %c8_i32_2322 : i32
      %c8_i32_2323 = arith.constant 8 : i32
      %1471 = arith.muli %1470, %c8_i32_2323 : i32
      %c8_i32_2324 = arith.constant 8 : i32
      %1472 = arith.remsi %1469, %c8_i32_2324 : i32
      %c64_i32_2325 = arith.constant 64 : i32
      %1473 = arith.muli %1472, %c64_i32_2325 : i32
      %1474 = arith.addi %1471, %1473 : i32
      %c0_i32_2326 = arith.constant 0 : i32
      %1475 = arith.xori %1474, %c0_i32_2326 : i32
      %c8_i32_2327 = arith.constant 8 : i32
      %1476 = arith.divsi %1468, %c8_i32_2327 : i32
      %c8_i32_2328 = arith.constant 8 : i32
      %1477 = arith.divsi %1476, %c8_i32_2328 : i32
      %c512_i32_2329 = arith.constant 512 : i32
      %1478 = arith.muli %1477, %c512_i32_2329 : i32
      %c448_i32_2330 = arith.constant 448 : i32
      %1479 = arith.andi %1475, %c448_i32_2330 : i32
      %c3_i32_2331 = arith.constant 3 : i32
      %1480 = arith.shrsi %1479, %c3_i32_2331 : i32
      %1481 = arith.xori %1475, %1480 : i32
      %1482 = arith.addi %1481, %1478 : i32
      %iv_2332 = cute.assume(%1482) : (i32) -> !cute.i32<divby 8>
      %int_tuple_2333 = cute.make_int_tuple(%iv_2332) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_2334 = cute.add_offset(%iter_2320, %int_tuple_2333) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_2335 = cute.make_view(%ptr_2334) : !memref_smem_bf16_3
      %iter_2336 = cute.get_iter(%view_2335) : !memref_smem_bf16_3
      %coord_2337 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_2338 = cute.get_iter(%view_2318) : !memref_gmem_bf16_2
      %lay_2339 = cute.get_layout(%view_2318) : !memref_gmem_bf16_2
      %1483 = cute.get_scalars(%lay_2339) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %1484 = cute.get_scalars(%coord_2337) <{only_dynamic}> : !cute.coord<"?">
      %c16_i64_2340 = arith.constant 16 : i64
      %1485 = arith.muli %1483, %c16_i64_2340 : i64
      %c8_i32_2341 = arith.constant 8 : i32
      %1486 = arith.divsi %1484, %c8_i32_2341 : i32
      %c8_i32_2342 = arith.constant 8 : i32
      %1487 = arith.remsi %1484, %c8_i32_2342 : i32
      %c8_i32_2343 = arith.constant 8 : i32
      %1488 = arith.muli %1487, %c8_i32_2343 : i32
      %1489 = arith.extsi %1486 : i32 to i64
      %1490 = arith.muli %1489, %1483 : i64
      %1491 = arith.extsi %1488 : i32 to i64
      %1492 = arith.addi %1491, %1490 : i64
      %iv_2344 = cute.assume(%1492) : (i64) -> !cute.i64<divby 8>
      %int_tuple_2345 = cute.make_int_tuple(%iv_2344) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_2346 = cute.add_offset(%iter_2338, %int_tuple_2345) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1493 = cute.static : !cute.shape<"((8,1),8,2)">
      %iv_2347 = cute.assume(%1485) : (i64) -> !cute.i64<divby 128>
      %stride_2348 = cute.make_stride(%iv_2347) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_2349 = cute.make_layout(%1493, %stride_2348) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %view_2350 = cute.make_view(%ptr_2346, %lay_2349) : !memref_gmem_bf16_4
      %1494 = cute.static : !cute.layout<"((8,1),8,2):((1,0),16,8)">
      %rmem_2351 = cute.memref.alloca(%1494) : !memref_rmem_bf16_27
      %iter_2352 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
      %c1_i32_2353 = arith.constant 1 : i32
      %c128_i32_2354 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_2353 number_of_threads = %c128_i32_2354
      %1495 = cute.static : !cute.layout<"((8,1),8,2):((1,0),1024,8192)">
      %view_2355 = cute.make_view(%iter_2336, %1495) : !memref_smem_bf16_3
      %iter_2356 = cute.get_iter(%view_2355) : !memref_smem_bf16_3
      %view_2357 = cute.make_view(%iter_2356) : !memref_smem_bf16_21
      %1496 = cute.static : !cute.layout<"((8,1),8,2):((1,0),16,8)">
      %view_2358 = cute.make_view(%iter_2352, %1496) : !memref_rmem_bf16_27
      %iter_2359 = cute.get_iter(%view_2358) : !memref_rmem_bf16_27
      %view_2360 = cute.make_view(%iter_2359) : !memref_rmem_bf16_28
      %1497 = cute.static : !cute.layout<"1:0">
      %iter_2361 = cute.get_iter(%view_2357) : !memref_smem_bf16_21
      %iter_2362 = cute.get_iter(%view_2360) : !memref_rmem_bf16_28
      %1498 = cute.static : !cute.layout<"((8,1),((8,2))):((1,0),((1024,8192)))">
      %1499 = cute.static : !cute.layout<"((8,1),((8,2))):((1,0),((16,8)))">
      %1500 = cute.static : !cute.int_tuple<"16">
      %1501 = cute.get_scalars(%1500) : !cute.int_tuple<"16">
      %c0_i32_2363 = arith.constant 0 : i32
      %c1_i32_2364 = arith.constant 1 : i32
      scf.for %arg5 = %c0_i32_2363 to %1501 step %c1_i32_2364  : i32 {
        %coord_2576 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %1582 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2577 = cute.crd2idx(%coord_2576, %1498) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((1024,8192)))">) -> !cute.int_tuple<"?{div=1024}">
        %ptr_2578 = cute.add_offset(%iter_2361, %idx_2577) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_2579 = cute.make_view(%ptr_2578, %1582) : !memref_smem_bf16_10
        %1583 = cute.static : !cute.layout<"((8,1)):((1,0))">
        %idx_2580 = cute.crd2idx(%coord_2576, %1499) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_2581 = cute.add_offset(%iter_2362, %idx_2580) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581, %1583) : !memref_rmem_bf16_8
        %iter_2583 = cute.get_iter(%view_2579) : !memref_smem_bf16_10
        %iter_2584 = cute.get_iter(%view_2582) : !memref_rmem_bf16_8
        %1584 = builtin.unrealized_conversion_cast %iter_2583 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %1585 = builtin.unrealized_conversion_cast %iter_2584 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %1586 = llvm.load %1584 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %1586, %1585 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %lay_2365 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1502 = cute.get_shape(%lay_2365) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2366, %e1_2367, %e2_2368, %e3_2369 = cute.get_leaves(%1502) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2370 = cute.to_int_tuple(%e0_2366) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_2371 = cute.to_int_tuple(%e1_2367) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_2372 = cute.to_int_tuple(%e2_2368) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_2373 = cute.to_int_tuple(%e3_2369) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_2374 = cute.make_shape(%itup_2370, %itup_2371, %itup_2372, %itup_2373) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1503 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %1504 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %lay_2375 = cute.make_layout(%shape_2374, %1504) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %view_2376 = cute.make_view(%1503, %lay_2375) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %coord_2377 = cute.make_coord(%25, %26) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_2378 = cute.get_layout(%view_2376) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1505:4 = cute.get_scalars(%lay_2378) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_2379 = cute.assume(%1505#3) : (i32) -> !cute.i32<divby 8>
      %shape_2380 = cute.make_shape(%1505#1, %iv_2379) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %1506 = cute.static : !cute.stride<"(1@1,1@3)">
      %lay_2381 = cute.make_layout(%shape_2380, %1506) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_2382 = cute.crd2idx(%coord_2377, %lay_2378) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %1507 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %tup_2383 = cute.add_offset(%1507, %idx_2382) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %view_2384 = cute.make_view(%tup_2383, %lay_2381) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %coord_2385 = cute.make_coord(%24) : (i32) -> !cute.coord<"(?,0)">
      %1508 = cute.get_scalars(%coord_2385) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_2386 = cute.make_coord(%1508) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_2387 = cute.get_layout(%view_2384) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %1509:2 = cute.get_scalars(%lay_2387) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c128_i32_2388 = arith.constant 128 : i32
      %1510 = arith.ceildivsi %1509#0, %c128_i32_2388 : i32
      %c128_i32_2389 = arith.constant 128 : i32
      %1511 = arith.ceildivsi %1509#1, %c128_i32_2389 : i32
      %shape_2390 = cute.make_shape(%1510, %1511) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %1512 = cute.static : !cute.stride<"((1@1,1@3),(128@1,128@3))">
      %lay_2391 = cute.make_layout(%shape_2390, %1512) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_2392 = cute.crd2idx(%coord_2386, %lay_2391) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %iter_2393 = cute.get_iter(%view_2384) : !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %tup_2394 = cute.add_offset(%iter_2393, %idx_2392) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %view_2395 = cute.make_view(%tup_2394) : !cute.coord_tensor<"(?,?{div=128},?,0)", "(128,128):(1@1,1@3)">
      %coord_2396 = cute.make_coord(%23) : (i32) -> !cute.coord<"?">
      %iter_2397 = cute.get_iter(%view_2395) : !cute.coord_tensor<"(?,?{div=128},?,0)", "(128,128):(1@1,1@3)">
      %1513 = cute.get_scalars(%coord_2396) <{only_dynamic}> : !cute.coord<"?">
      %c8_i32_2398 = arith.constant 8 : i32
      %1514 = arith.divsi %1513, %c8_i32_2398 : i32
      %c8_i32_2399 = arith.constant 8 : i32
      %1515 = arith.remsi %1513, %c8_i32_2399 : i32
      %c8_i32_2400 = arith.constant 8 : i32
      %1516 = arith.muli %1515, %c8_i32_2400 : i32
      %iv_2401 = cute.assume(%1516) : (i32) -> !cute.i32<divby 8>
      %int_tuple_2402 = cute.make_int_tuple(%1514, %iv_2401) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_2403 = cute.add_offset(%iter_2397, %int_tuple_2402) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2404 = cute.make_view(%tup_2403) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %1517 = cute.static : !cute.layout<"(1,8,2):(2,0,1)">
      %rmem_2405 = cute.memref.alloca(%1517) : !memref_rmem_i8_
      %1518 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_2406 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2407 = cute.add_offset(%iter_2406, %1518) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2408 = cute.make_view(%tup_2407) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2409 = cute.get_iter(%view_2408) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2410, %e1_2411, %e2_2412, %e3_2413 = cute.get_leaves(%iter_2409) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2414 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1519 = cute.get_shape(%lay_2414) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2415, %e1_2416, %e2_2417, %e3_2418 = cute.get_leaves(%1519) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2419 = cute.to_int_tuple(%e3_2418) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_2420 = cute.make_coord(%e3_2413) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_2421 = cute.make_coord(%itup_2419) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1520 = cute.get_scalars(%coord_2420) : !cute.coord<"?{div=8}">
      %1521 = cute.get_scalars(%coord_2421) : !cute.coord<"?{div=8}">
      %true_2422 = arith.constant true
      %1522 = arith.cmpi slt, %1520, %1521 : i32
      %1523 = arith.andi %true_2422, %1522 : i1
      %1524 = arith.extui %1523 : i1 to i8
      %1525 = cute.static : !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_2405, %1525, %1524) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %1526 = cute.static : !cute.int_tuple<"(0,0,0,64)">
      %iter_2423 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2424 = cute.add_offset(%iter_2423, %1526) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2425 = cute.make_view(%tup_2424) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2426 = cute.get_iter(%view_2425) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2427, %e1_2428, %e2_2429, %e3_2430 = cute.get_leaves(%iter_2426) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2431 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1527 = cute.get_shape(%lay_2431) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2432, %e1_2433, %e2_2434, %e3_2435 = cute.get_leaves(%1527) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2436 = cute.to_int_tuple(%e3_2435) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_2437 = cute.make_coord(%e3_2430) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_2438 = cute.make_coord(%itup_2436) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1528 = cute.get_scalars(%coord_2437) : !cute.coord<"?{div=8}">
      %1529 = cute.get_scalars(%coord_2438) : !cute.coord<"?{div=8}">
      %true_2439 = arith.constant true
      %1530 = arith.cmpi slt, %1528, %1529 : i32
      %1531 = arith.andi %true_2439, %1530 : i1
      %1532 = arith.extui %1531 : i1 to i8
      %1533 = cute.static : !cute.coord<"(0,0,1)">
      cute.memref.store(%rmem_2405, %1533, %1532) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %1534 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %iter_2440 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2441 = cute.add_offset(%iter_2440, %1534) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2442 = cute.make_view(%tup_2441) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2443 = cute.get_iter(%view_2442) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2444, %e1_2445, %e2_2446, %e3_2447 = cute.get_leaves(%iter_2443) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2448 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1535 = cute.get_shape(%lay_2448) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2449, %e1_2450, %e2_2451, %e3_2452 = cute.get_leaves(%1535) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2453 = cute.to_int_tuple(%e1_2450) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2454 = cute.make_coord(%e1_2445) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2455 = cute.make_coord(%itup_2453) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1536 = cute.get_scalars(%coord_2454) : !cute.coord<"?">
      %1537 = cute.get_scalars(%coord_2455) : !cute.coord<"?">
      %true_2456 = arith.constant true
      %1538 = arith.cmpi slt, %1536, %1537 : i32
      %1539 = arith.andi %true_2456, %1538 : i1
      scf.if %1539 {
        %1582 = cute.static : !cute.int_tuple<"0">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.int_tuple<"0">
        %iter_2580 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2581 = cute.add_offset(%iter_2580, %1583) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2582 = cute.make_view(%ptr_2581) : !memref_gmem_bf16_6
        %iter_2583 = cute.get_iter(%view_2582) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2584 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2585 = cute.add_offset(%iter_2584, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2586 = cute.make_view(%ptr_2585) : !memref_rmem_i8_2
        %iter_2587 = cute.get_iter(%view_2586) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2588 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_bf16_29
        %view_2590 = cute.make_view(%iter_2589) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2591 = cute.make_view(%iter_2583, %1586) : !memref_gmem_bf16_6
        %iter_2592 = cute.get_iter(%view_2591) : !memref_gmem_bf16_6
        %view_2593 = cute.make_view(%iter_2592) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2594 = cute.make_view(%iter_2587, %1587) : !memref_rmem_i8_2
        %iter_2595 = cute.get_iter(%view_2594) : !memref_rmem_i8_2
        %view_2596 = cute.make_view(%iter_2595) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2597 = cute.get_iter(%view_2590) : !memref_rmem_bf16_30
        %iter_2598 = cute.get_iter(%view_2593) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2599 = cute.get_iter(%view_2596) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2600 = arith.constant 0 : i32
        %c1_i32_2601 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2600 to %1593 step %c1_i32_2601  : i32 {
          %coord_2602 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2603 = cute.crd2idx(%coord_2602, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2604 = cute.add_offset(%iter_2597, %idx_2603) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2605 = cute.make_view(%ptr_2604, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2606 = cute.crd2idx(%coord_2602, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2607 = cute.add_offset(%iter_2598, %idx_2606) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2608 = cute.make_view(%ptr_2607, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2609 = cute.crd2idx(%coord_2602, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2610 = cute.add_offset(%iter_2599, %idx_2609) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2611 = cute.make_view(%ptr_2610, %1596) : !memref_rmem_i8_4
          %iter_2612 = cute.get_iter(%view_2605) : !memref_rmem_bf16_8
          %iter_2613 = cute.get_iter(%view_2608) : !memref_gmem_bf16_8
          %iter_2614 = cute.get_iter(%view_2611) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2612 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2613 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1540 = cute.static : !cute.int_tuple<"(0,16,0,0)">
      %iter_2457 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2458 = cute.add_offset(%iter_2457, %1540) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2459 = cute.make_view(%tup_2458) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2460 = cute.get_iter(%view_2459) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2461, %e1_2462, %e2_2463, %e3_2464 = cute.get_leaves(%iter_2460) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2465 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1541 = cute.get_shape(%lay_2465) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2466, %e1_2467, %e2_2468, %e3_2469 = cute.get_leaves(%1541) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2470 = cute.to_int_tuple(%e1_2467) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2471 = cute.make_coord(%e1_2462) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2472 = cute.make_coord(%itup_2470) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1542 = cute.get_scalars(%coord_2471) : !cute.coord<"?">
      %1543 = cute.get_scalars(%coord_2472) : !cute.coord<"?">
      %true_2473 = arith.constant true
      %1544 = arith.cmpi slt, %1542, %1543 : i32
      %1545 = arith.andi %true_2473, %1544 : i1
      scf.if %1545 {
        %1582 = cute.static : !cute.int_tuple<"16">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,1,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1546 = cute.static : !cute.int_tuple<"(0,32,0,0)">
      %iter_2474 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2475 = cute.add_offset(%iter_2474, %1546) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2476 = cute.make_view(%tup_2475) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2477 = cute.get_iter(%view_2476) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2478, %e1_2479, %e2_2480, %e3_2481 = cute.get_leaves(%iter_2477) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2482 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1547 = cute.get_shape(%lay_2482) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2483, %e1_2484, %e2_2485, %e3_2486 = cute.get_leaves(%1547) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2487 = cute.to_int_tuple(%e1_2484) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2488 = cute.make_coord(%e1_2479) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2489 = cute.make_coord(%itup_2487) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1548 = cute.get_scalars(%coord_2488) : !cute.coord<"?">
      %1549 = cute.get_scalars(%coord_2489) : !cute.coord<"?">
      %true_2490 = arith.constant true
      %1550 = arith.cmpi slt, %1548, %1549 : i32
      %1551 = arith.andi %true_2490, %1550 : i1
      scf.if %1551 {
        %1582 = cute.static : !cute.int_tuple<"32">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,2,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1552 = cute.static : !cute.int_tuple<"(0,48,0,0)">
      %iter_2491 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2492 = cute.add_offset(%iter_2491, %1552) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2493 = cute.make_view(%tup_2492) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2494 = cute.get_iter(%view_2493) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2495, %e1_2496, %e2_2497, %e3_2498 = cute.get_leaves(%iter_2494) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2499 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1553 = cute.get_shape(%lay_2499) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2500, %e1_2501, %e2_2502, %e3_2503 = cute.get_leaves(%1553) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2504 = cute.to_int_tuple(%e1_2501) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2505 = cute.make_coord(%e1_2496) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2506 = cute.make_coord(%itup_2504) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1554 = cute.get_scalars(%coord_2505) : !cute.coord<"?">
      %1555 = cute.get_scalars(%coord_2506) : !cute.coord<"?">
      %true_2507 = arith.constant true
      %1556 = arith.cmpi slt, %1554, %1555 : i32
      %1557 = arith.andi %true_2507, %1556 : i1
      scf.if %1557 {
        %1582 = cute.static : !cute.int_tuple<"48">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,3,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1558 = cute.static : !cute.int_tuple<"(0,64,0,0)">
      %iter_2508 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2509 = cute.add_offset(%iter_2508, %1558) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2510 = cute.make_view(%tup_2509) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2511 = cute.get_iter(%view_2510) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2512, %e1_2513, %e2_2514, %e3_2515 = cute.get_leaves(%iter_2511) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2516 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1559 = cute.get_shape(%lay_2516) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2517, %e1_2518, %e2_2519, %e3_2520 = cute.get_leaves(%1559) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2521 = cute.to_int_tuple(%e1_2518) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2522 = cute.make_coord(%e1_2513) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2523 = cute.make_coord(%itup_2521) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1560 = cute.get_scalars(%coord_2522) : !cute.coord<"?">
      %1561 = cute.get_scalars(%coord_2523) : !cute.coord<"?">
      %true_2524 = arith.constant true
      %1562 = arith.cmpi slt, %1560, %1561 : i32
      %1563 = arith.andi %true_2524, %1562 : i1
      scf.if %1563 {
        %1582 = cute.static : !cute.int_tuple<"64">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,4,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1564 = cute.static : !cute.int_tuple<"(0,80,0,0)">
      %iter_2525 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2526 = cute.add_offset(%iter_2525, %1564) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2527 = cute.make_view(%tup_2526) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2528 = cute.get_iter(%view_2527) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2529, %e1_2530, %e2_2531, %e3_2532 = cute.get_leaves(%iter_2528) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2533 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1565 = cute.get_shape(%lay_2533) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2534, %e1_2535, %e2_2536, %e3_2537 = cute.get_leaves(%1565) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2538 = cute.to_int_tuple(%e1_2535) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2539 = cute.make_coord(%e1_2530) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2540 = cute.make_coord(%itup_2538) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1566 = cute.get_scalars(%coord_2539) : !cute.coord<"?">
      %1567 = cute.get_scalars(%coord_2540) : !cute.coord<"?">
      %true_2541 = arith.constant true
      %1568 = arith.cmpi slt, %1566, %1567 : i32
      %1569 = arith.andi %true_2541, %1568 : i1
      scf.if %1569 {
        %1582 = cute.static : !cute.int_tuple<"80">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,5,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1570 = cute.static : !cute.int_tuple<"(0,96,0,0)">
      %iter_2542 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2543 = cute.add_offset(%iter_2542, %1570) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2544 = cute.make_view(%tup_2543) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2545 = cute.get_iter(%view_2544) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2546, %e1_2547, %e2_2548, %e3_2549 = cute.get_leaves(%iter_2545) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2550 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1571 = cute.get_shape(%lay_2550) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2551, %e1_2552, %e2_2553, %e3_2554 = cute.get_leaves(%1571) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2555 = cute.to_int_tuple(%e1_2552) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2556 = cute.make_coord(%e1_2547) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2557 = cute.make_coord(%itup_2555) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1572 = cute.get_scalars(%coord_2556) : !cute.coord<"?">
      %1573 = cute.get_scalars(%coord_2557) : !cute.coord<"?">
      %true_2558 = arith.constant true
      %1574 = arith.cmpi slt, %1572, %1573 : i32
      %1575 = arith.andi %true_2558, %1574 : i1
      scf.if %1575 {
        %1582 = cute.static : !cute.int_tuple<"96">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,6,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %1576 = cute.static : !cute.int_tuple<"(0,112,0,0)">
      %iter_2559 = cute.get_iter(%view_2404) : !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),8,2):((1@3,0),16@1,64@3)">
      %tup_2560 = cute.add_offset(%iter_2559, %1576) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %view_2561 = cute.make_view(%tup_2560) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %iter_2562 = cute.get_iter(%view_2561) : !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %e0_2563, %e1_2564, %e2_2565, %e3_2566 = cute.get_leaves(%iter_2562) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_2567 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1577 = cute.get_shape(%lay_2567) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_2568, %e1_2569, %e2_2570, %e3_2571 = cute.get_leaves(%1577) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_2572 = cute.to_int_tuple(%e1_2569) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_2573 = cute.make_coord(%e1_2564) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_2574 = cute.make_coord(%itup_2572) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1578 = cute.get_scalars(%coord_2573) : !cute.coord<"?">
      %1579 = cute.get_scalars(%coord_2574) : !cute.coord<"?">
      %true_2575 = arith.constant true
      %1580 = arith.cmpi slt, %1578, %1579 : i32
      %1581 = arith.andi %true_2575, %1580 : i1
      scf.if %1581 {
        %1582 = cute.static : !cute.int_tuple<"112">
        %iter_2576 = cute.get_iter(%rmem_2351) : !memref_rmem_bf16_27
        %ptr_2577 = cute.add_offset(%iter_2576, %1582) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_2578 = cute.make_view(%ptr_2577) : !memref_rmem_bf16_29
        %iter_2579 = cute.get_iter(%view_2578) : !memref_rmem_bf16_29
        %1583 = cute.static : !cute.coord<"(_,7,_)">
        %lay_2580 = cute.get_layout(%view_2350) : !memref_gmem_bf16_4
        %idx_2581 = cute.crd2idx(%1583, %lay_2580) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
        %iter_2582 = cute.get_iter(%view_2350) : !memref_gmem_bf16_4
        %ptr_2583 = cute.add_offset(%iter_2582, %idx_2581) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_2584 = cute.make_view(%ptr_2583) : !memref_gmem_bf16_6
        %iter_2585 = cute.get_iter(%view_2584) : !memref_gmem_bf16_6
        %1584 = cute.static : !cute.int_tuple<"0">
        %iter_2586 = cute.get_iter(%rmem_2405) : !memref_rmem_i8_
        %ptr_2587 = cute.add_offset(%iter_2586, %1584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_2588 = cute.make_view(%ptr_2587) : !memref_rmem_i8_2
        %iter_2589 = cute.get_iter(%view_2588) : !memref_rmem_i8_2
        %1585 = cute.static : !cute.layout<"((8,1),2):((1,0),8)">
        %view_2590 = cute.make_view(%iter_2579, %1585) : !memref_rmem_bf16_29
        %iter_2591 = cute.get_iter(%view_2590) : !memref_rmem_bf16_29
        %view_2592 = cute.make_view(%iter_2591) : !memref_rmem_bf16_30
        %1586 = cute.static : !cute.layout<"((8,1),2):((1,0),64)">
        %view_2593 = cute.make_view(%iter_2585, %1586) : !memref_gmem_bf16_6
        %iter_2594 = cute.get_iter(%view_2593) : !memref_gmem_bf16_6
        %view_2595 = cute.make_view(%iter_2594) : !memref_gmem_bf16_7
        %1587 = cute.static : !cute.layout<"(1,2):(2,1)">
        %view_2596 = cute.make_view(%iter_2589, %1587) : !memref_rmem_i8_2
        %iter_2597 = cute.get_iter(%view_2596) : !memref_rmem_i8_2
        %view_2598 = cute.make_view(%iter_2597) : !memref_rmem_i8_3
        %1588 = cute.static : !cute.layout<"1:0">
        %iter_2599 = cute.get_iter(%view_2592) : !memref_rmem_bf16_30
        %iter_2600 = cute.get_iter(%view_2595) : !memref_gmem_bf16_7
        %1589 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1590 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %iter_2601 = cute.get_iter(%view_2598) : !memref_rmem_i8_3
        %1591 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
        %1592 = cute.static : !cute.int_tuple<"2">
        %1593 = cute.get_scalars(%1592) : !cute.int_tuple<"2">
        %c0_i32_2602 = arith.constant 0 : i32
        %c1_i32_2603 = arith.constant 1 : i32
        scf.for %arg5 = %c0_i32_2602 to %1593 step %c1_i32_2603  : i32 {
          %coord_2604 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %1594 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2605 = cute.crd2idx(%coord_2604, %1589) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_2606 = cute.add_offset(%iter_2599, %idx_2605) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %view_2607 = cute.make_view(%ptr_2606, %1594) : !memref_rmem_bf16_8
          %1595 = cute.static : !cute.layout<"((8,1)):((1,0))">
          %idx_2608 = cute.crd2idx(%coord_2604, %1590) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_2609 = cute.add_offset(%iter_2600, %idx_2608) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_2610 = cute.make_view(%ptr_2609, %1595) : !memref_gmem_bf16_8
          %1596 = cute.static : !cute.layout<"(1):(2)">
          %idx_2611 = cute.crd2idx(%coord_2604, %1591) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_2612 = cute.add_offset(%iter_2601, %idx_2611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_2613 = cute.make_view(%ptr_2612, %1596) : !memref_rmem_i8_4
          %iter_2614 = cute.get_iter(%view_2607) : !memref_rmem_bf16_8
          %iter_2615 = cute.get_iter(%view_2610) : !memref_gmem_bf16_8
          %iter_2616 = cute.get_iter(%view_2613) : !memref_rmem_i8_4
          %1597 = builtin.unrealized_conversion_cast %iter_2616 : !cute.ptr<i8, rmem> to !llvm.ptr
          %1598 = llvm.load %1597 : !llvm.ptr -> i8
          %1599 = llvm.mlir.constant(0 : i8) : i8
          %1600 = llvm.icmp "ne" %1598, %1599 : i8
          scf.if %1600 {
            %1601 = builtin.unrealized_conversion_cast %iter_2614 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %1602 = builtin.unrealized_conversion_cast %iter_2615 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %1603 = llvm.load %1601 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %1603, %1602 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass___call_____main__FlashAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Te(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %0 = cute.static : !cute.swizzle<"S<3,3,3>">
    %1 = cute.static : !cute.composed_layout<"S<3,3,3> o 0 o ((8,16),(64,2)):((64,512),(1,8192))">
    %2 = cute.static : !cute.composed_layout<"S<3,3,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = global, 128 b>
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
    %3 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %4 = cute.make_tiled_copy(%atom_0) : !copy_simt
    %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %5 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0, %e1, %e2, %e3 = cute.get_leaves(%5) : !cute.shape<"(?,?,?,?{div=8})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup_1) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %6 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %c128_i32 = arith.constant 128 : i32
    %7 = arith.ceildivsi %6, %c128_i32 : i32
    %int_tuple_3 = cute.make_int_tuple(%7) : (i32) -> !cute.int_tuple<"?">
    %e0_4 = cute.get_leaves(%int_tuple_3) : !cute.int_tuple<"?">
    %8 = cute.get_scalars(%e0_4) : !cute.int_tuple<"?">
    %int_tuple_5 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_5) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_6 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %9 = cute.get_scalars(%e0_6) : !cute.int_tuple<"?">
    %int_tuple_7 = cute.make_int_tuple(%itup_2) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_8 = cute.size(%int_tuple_7) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_9 = cute.get_leaves(%sz_8) : !cute.int_tuple<"?">
    %10 = cute.get_scalars(%e0_9) : !cute.int_tuple<"?">
    %cst = arith.constant 1.44269502 : f32
    %11 = arith.mulf %arg4, %cst : f32
    %12 = cute.static : !cute.tile<"[16:1;64:1]">
    %13 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
    %14 = cute.static : !cute.layout<"1:0">
    %15 = cute.static : !cute.layout<"(1,8):(0,1)">
    %16 = cute.static : !cute.layout<"(1,8):(0,1)">
    %17 = cute.static : !cute.tile<"[16:1;64:1]">
    %18 = cute.static : !cute.layout<"((8,16),8):((128,1),16)">
    %19 = cute.static : !cute.layout<"1:0">
    %20 = cute.static : !cute.layout<"(1,8):(0,1)">
    %21 = cute.static : !cute.layout<"(1,8):(0,1)">
    %22 = cute.static : !cute.layout<"(32,4,1,1):(1,32,0,0)">
    %23 = cute.static : !cute.tile<"[64:1;16:1;16:1]">
    %24 = cute.static : !cute.layout<"32:1">
    %25 = cute.static : !cute.shape<"(16,8,16)">
    %26 = cute.static : !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
    %27 = cute.static : !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
    %28 = cute.static : !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
    %c65536_i32 = arith.constant 65536 : i32
    %29 = arith.extsi %c65536_i32 : i32 to i64
    %c128_i32_10 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %30 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_10, %c1_i32, %c1_i32), dynamicSmemBytes = %29, gridDim = (%8, %9, %10), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %31 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__FlashAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16g_0<%30> (%arg0, %arg1, %arg2, %arg3, %11) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, f32) -> !cuda.result
    %32 = cuda.cast %31 : !cuda.result -> i32
    cuda.return_if_error %32 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
