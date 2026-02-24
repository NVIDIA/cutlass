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
!memref_rmem_bf16_9 = !cute.memref<bf16, rmem, align<16>, "((8,1)):((1,0))">
!memref_rmem_bf16_10 = !cute.memref<bf16, rmem, align<16>, "((8,1),1):((1,0),0)">
!memref_rmem_bf16_11 = !cute.memref<bf16, rmem, align<16>, "((8,1),(1)):((1,0),(0))">
!memref_rmem_bf16_12 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1),4):(((1,32),0),4)">
!memref_rmem_bf16_13 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1),(4)):(((1,32),0),(4))">
!memref_rmem_bf16_14 = !cute.memref<bf16, rmem, align<8>, "(((4,2),1)):(((1,32),0))">
!memref_rmem_bf16_15 = !cute.memref<bf16, rmem, align<16>, "((2,2,2),1):((1,2,4),0)">
!memref_rmem_bf16_16 = !cute.memref<bf16, rmem, align<8>, "((2,2),(2,4)):((1,2),(32,4))">
!memref_rmem_bf16_17 = !cute.memref<bf16, rmem, align<16>, "((2,2,2)):((1,2,4))">
!memref_rmem_bf16_18 = !cute.memref<bf16, rmem, align<8>, "((2,2)):((1,2))">
!memref_rmem_bf16_19 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),1,4):(((1,2),4),0,8)">
!memref_rmem_bf16_20 = !cute.memref<bf16, rmem, align<8>, "((8,1),(4,2)):((1,0),(8,128))">
!memref_rmem_bf16_21 = !cute.memref<bf16, rmem, align<8>, "((8,1),((4,2))):((1,0),((8,128)))">
!memref_rmem_bf16_22 = !cute.memref<bf16, rmem, align<8>, "((8,1)):((1,0))">
!memref_rmem_bf16_23 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2),1):(((1,2),4),0)">
!memref_rmem_bf16_24 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2)):((1,2),(4,128))">
!memref_rmem_bf16_25 = !cute.memref<bf16, rmem, align<32>, "(((2,2),2)):(((1,2),4))">
!memref_rmem_bf16_26 = !cute.memref<bf16, rmem, align<16>, "(((2,2),2),1):(((1,2),4),0)">
!memref_rmem_bf16_27 = !cute.memref<bf16, rmem, align<16>, "(((2,2),2)):(((1,2),4))">
!memref_rmem_bf16_28 = !cute.memref<bf16, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_bf16_29 = !cute.memref<bf16, rmem, align<32>, "((1,8),1,8):((0,1),0,8)">
!memref_rmem_bf16_30 = !cute.memref<bf16, rmem, align<32>, "((1,8),(1,8)):((0,1),(0,8))">
!memref_rmem_bf16_31 = !cute.memref<bf16, rmem, align<16>, "((1,8)):((0,1))">
!memref_rmem_bf16_32 = !cute.memref<bf16, rmem, align<32>, "((8,1),4,2):((1,0),16,8)">
!memref_rmem_bf16_33 = !cute.memref<bf16, rmem, align<32>, "((8,1),(4,2)):((1,0),(16,8))">
!memref_rmem_bf16_34 = !cute.memref<bf16, rmem, align<32>, "((8,1),2):((1,0),8)">
!memref_rmem_bf16_35 = !cute.memref<bf16, rmem, align<32>, "((8,1),(2)):((1,0),(8))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((2,2),1,8):((1,2),0,4)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<16>, "((2,2)):((1,2))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,4,2):(2,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,2):(2,1)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(1,(2)):(2,(1))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, "(1):(2)">
!memref_rmem_i8_4 = !cute.memref<i8, rmem, align<32>, "(1,(4,2)):(2,(0,1))">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<1024>, "S<3,4,3> o 0 o ((64,2),64):((1,4096),64)">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,1),4,2):((1,0),1024,4096)">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "((8,1),4,1):((1,0),1024,0)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<16>, "((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_6 = !cute.memref<bf16, smem, align<16>, "((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_7 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
!memref_smem_bf16_8 = !cute.memref<bf16, smem, align<16>, "((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
!memref_smem_bf16_9 = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),4096)">
!memref_smem_bf16_10 = !cute.memref<bf16, smem, align<16>, "((8,1),(2)):((1,0),(4096))">
!memref_smem_bf16_11 = !cute.memref<bf16, smem, align<16>, "((8,1)):((1,0))">
!memref_smem_bf16_12 = !cute.memref<bf16, smem, align<16>, "((8,1),1):((1,0),0)">
!memref_smem_bf16_13 = !cute.memref<bf16, smem, align<16>, "((8,1),(1)):((1,0),(0))">
!memref_smem_bf16_14 = !cute.memref<bf16, smem, align<16>, "((8,1),(4,2)):((1,0),(1024,4096))">
!memref_smem_bf16_15 = !cute.memref<bf16, smem, align<16>, "((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
!memref_smem_bf16_16 = !cute.memref<bf16, smem, align<16>, "((8,1),4):((1,0),1024)">
!memref_smem_bf16_17 = !cute.memref<bf16, smem, align<16>, "((8,1),(4)):((1,0),(1024))">
!memref_smem_bf16_18 = !cute.memref<bf16, smem, align<16>, "((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
!memref_smem_bf16_19 = !cute.memref<bf16, smem, align<16>, "((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
!memref_smem_bf16_20 = !cute.memref<bf16, smem, align<1024>, S<3,4,3>, "((8,8),(64,2)):((64,512),(1,4096))">
!memref_smem_bf16_21 = !cute.memref<bf16, smem, align<4>, S<3,4,3>, "((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">
!memref_smem_bf16_22 = !cute.memref<bf16, smem, align<4>, S<3,4,3>, "((1,(2,2,2)),(1,(4,2))):((0,(1,512,8)),(0,(16,4096)))">
!memref_smem_bf16_23 = !cute.memref<bf16, smem, align<4>, S<3,4,3>, "((1,(2,2,2))):((0,(1,512,8)))">
!memref_smem_bf16_24 = !cute.memref<bf16, smem, align<16>, S<3,4,3>, "((8,1),4,2):((1,0),1024,4096)">
!memref_smem_bf16_25 = !cute.memref<bf16, smem, align<16>, S<3,4,3>, "((8,1),(4,2)):((1,0),(1024,4096))">
!memref_smem_bf16_26 = !cute.memref<bf16, smem, align<16>, S<3,4,3>, "((8,1)):((1,0))">
!mma_bf16_bf16_f32_16x8x16_ = !cute.tiled_mma<!cute_nvgpu.sm80.mma<16x8x16, elem_type = (bf16, bf16, f32) >, atom_layout_MNK = <"(4,1,1):(1,0,0)">, permutation_MNK = <"[64:1;16:1;16:1]">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_) -> (), sym_name = "kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0"}> ({
    ^bb0(%arg6: !memref_gmem_bf16_, %arg7: !memref_gmem_bf16_, %arg8: !memref_gmem_bf16_, %arg9: !memref_gmem_bf16_, %arg10: !memref_gmem_bf16_):
      %47 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %48 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %49 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
      %50 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
      %51 = "cute.static"() : () -> !copy_ldgsts
      %52 = "cute.static"() : () -> !copy_simt
      %53 = "cute.static"() : () -> !mma_bf16_bf16_f32_16x8x16_
      %54 = "cute.static"() : () -> !cute.tile<"[16:1;64:1]">
      %55 = "cute.static"() : () -> !cute.layout<"((8,16),8):((128,1),16)">
      %56 = "cute.static"() : () -> !cute.layout<"1:0">
      %57 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
      %58 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
      %59 = "cute.static"() : () -> !cute.tile<"[16:1;64:1]">
      %60 = "cute.static"() : () -> !cute.layout<"((8,16),8):((128,1),16)">
      %61 = "cute.static"() : () -> !cute.layout<"1:0">
      %62 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
      %63 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
      %64 = "cute.static"() : () -> !cute.layout<"(32,4,1,1):(1,32,0,0)">
      %65 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %66 = "cute.static"() : () -> !cute.layout<"32:1">
      %67 = "cute.static"() : () -> !cute.shape<"(16,8,16)">
      %68 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
      %69 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
      %70 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
      %71 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %72 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %73 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %74 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %75 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %76 = "cute.get_shape"(%75) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %77:4 = "cute.get_leaves"(%76) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %78 = "cute.to_int_tuple"(%77#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %79 = "cute.make_int_tuple"(%78) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %80 = "cute.get_scalars"(%79) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
      %81 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %82 = "arith.ceildivsi"(%80, %81) : (i32, i32) -> i32
      %83 = "cute.make_int_tuple"(%82) : (i32) -> !cute.int_tuple<"?">
      %84 = "cute.get_leaves"(%83) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %85 = "cute.make_int_tuple"(%74) : (i32) -> !cute.int_tuple<"?">
      %86 = "cute.tuple_sub"(%84, %85) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %87 = "cute.static"() : () -> !cute.int_tuple<"1">
      %88 = "cute.tuple_sub"(%86, %87) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %89 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %90 = "cute.get_shape"(%89) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %91:4 = "cute.get_leaves"(%90) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %92 = "cute.to_int_tuple"(%91#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %93 = "cute.make_int_tuple"(%92) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %94 = "cute.get_scalars"(%93) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
      %95 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %96 = "arith.ceildivsi"(%94, %95) : (i32, i32) -> i32
      %97 = "cute.make_int_tuple"(%96) : (i32) -> !cute.int_tuple<"?">
      %98 = "cute.get_leaves"(%97) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %99 = "cute.static"() : () -> !cute.int_tuple<"1">
      %100 = "cute.tuple_sub"(%98, %99) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %101 = "cute.get_scalars"(%100) : (!cute.int_tuple<"?">) -> i32
      %102 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %103 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %104:7 = "cute.get_scalars"(%103) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> (i32, i32, i32, i32, i64, i64, i64)
      %105 = "cute.assume"(%104#3) : (i32) -> !cute.i32<divby 8>
      %106 = "cute.make_shape"(%104#1, %105) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %107 = "cute.assume"(%104#5) : (i64) -> !cute.i64<divby 8>
      %108 = "cute.make_stride"(%107) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %109 = "cute.make_layout"(%106, %108) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %110 = "cute.crd2idx"(%102, %103) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %111 = "cute.get_iter"(%arg6) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %112 = "cute.add_offset"(%111, %110) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %113 = "cute.make_view"(%112, %109) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> !memref_gmem_bf16_1
      %114 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %115 = "cute.get_scalars"(%114) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %116 = "cute.make_coord"(%115) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %117 = "cute.get_layout"(%113) : (!memref_gmem_bf16_1) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %118:3 = "cute.get_scalars"(%117) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> (i32, i32, i64)
      %119 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %120 = "arith.ceildivsi"(%118#0, %119) : (i32, i32) -> i32
      %121 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %122 = "arith.muli"(%118#2, %121) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %123 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %124 = "arith.ceildivsi"(%118#1, %123) : (i32, i32) -> i32
      %125 = "cute.make_shape"(%120, %124) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %126 = "cute.assume"(%118#2) : (i64) -> !cute.i64<divby 8>
      %127 = "cute.assume"(%122) : (i64) -> !cute.i64<divby 512>
      %128 = "cute.make_stride"(%126, %127) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %129 = "cute.make_layout"(%125, %128) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %130:4 = "cute.get_scalars"(%129) <{only_dynamic}> : (!cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> (i32, i32, i64, i64)
      %131 = "cute.static"() : () -> !cute.shape<"(64,128)">
      %132 = "cute.assume"(%130#2) : (i64) -> !cute.i64<divby 8>
      %133 = "cute.make_stride"(%132) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %134 = "cute.make_layout"(%131, %133) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,128)">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(64,128):(?{i64 div=8},1)">
      %135 = "cute.crd2idx"(%116, %129) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %136 = "cute.get_iter"(%113) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %137 = "cute.add_offset"(%136, %135) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %138 = "cute.make_view"(%137, %134) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(64,128):(?{i64 div=8},1)">) -> !memref_gmem_bf16_2
      %139 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %140 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %141:7 = "cute.get_scalars"(%140) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> (i32, i32, i32, i32, i64, i64, i64)
      %142 = "cute.assume"(%141#3) : (i32) -> !cute.i32<divby 8>
      %143 = "cute.make_shape"(%141#1, %142) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %144 = "cute.assume"(%141#5) : (i64) -> !cute.i64<divby 8>
      %145 = "cute.make_stride"(%144) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %146 = "cute.make_layout"(%143, %145) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %147 = "cute.crd2idx"(%139, %140) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %148 = "cute.get_iter"(%arg7) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %149 = "cute.add_offset"(%148, %147) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %150 = "cute.make_view"(%149, %146) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> !memref_gmem_bf16_1
      %151 = "cute.get_layout"(%150) : (!memref_gmem_bf16_1) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %152:3 = "cute.get_scalars"(%151) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> (i32, i32, i64)
      %153 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %154 = "arith.ceildivsi"(%152#0, %153) : (i32, i32) -> i32
      %155 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %156 = "arith.muli"(%152#2, %155) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %157 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %158 = "arith.ceildivsi"(%152#1, %157) : (i32, i32) -> i32
      %159 = "cute.make_shape"(%154, %158) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %160 = "cute.assume"(%152#2) : (i64) -> !cute.i64<divby 8>
      %161 = "cute.assume"(%156) : (i64) -> !cute.i64<divby 512>
      %162 = "cute.make_stride"(%160, %161) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %163 = "cute.make_layout"(%159, %162) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %164:4 = "cute.get_scalars"(%163) <{only_dynamic}> : (!cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> (i32, i32, i64, i64)
      %165 = "cute.make_shape"(%164#0) : (i32) -> !cute.shape<"(64,128,?)">
      %166 = "cute.assume"(%164#2) : (i64) -> !cute.i64<divby 8>
      %167 = "cute.assume"(%164#3) : (i64) -> !cute.i64<divby 512>
      %168 = "cute.make_stride"(%166, %167) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %169 = "cute.make_layout"(%165, %168) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,128,?)">, !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">) -> !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %170 = "cute.static"() : () -> !cute.int_tuple<"0">
      %171 = "cute.get_iter"(%150) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %172 = "cute.add_offset"(%171, %170) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %173 = "cute.make_view"(%172, %169) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">) -> !memref_gmem_bf16_3
      %174 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %175 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %176:7 = "cute.get_scalars"(%175) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> (i32, i32, i32, i32, i64, i64, i64)
      %177 = "cute.assume"(%176#3) : (i32) -> !cute.i32<divby 8>
      %178 = "cute.make_shape"(%176#1, %177) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %179 = "cute.assume"(%176#5) : (i64) -> !cute.i64<divby 8>
      %180 = "cute.make_stride"(%179) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %181 = "cute.make_layout"(%178, %180) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %182 = "cute.crd2idx"(%174, %175) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %183 = "cute.get_iter"(%arg8) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %184 = "cute.add_offset"(%183, %182) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %185 = "cute.make_view"(%184, %181) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> !memref_gmem_bf16_1
      %186 = "cute.get_layout"(%185) : (!memref_gmem_bf16_1) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %187:3 = "cute.get_scalars"(%186) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> (i32, i32, i64)
      %188 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %189 = "arith.ceildivsi"(%187#0, %188) : (i32, i32) -> i32
      %190 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %191 = "arith.muli"(%187#2, %190) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %192 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %193 = "arith.ceildivsi"(%187#1, %192) : (i32, i32) -> i32
      %194 = "cute.make_shape"(%189, %193) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %195 = "cute.assume"(%187#2) : (i64) -> !cute.i64<divby 8>
      %196 = "cute.assume"(%191) : (i64) -> !cute.i64<divby 512>
      %197 = "cute.make_stride"(%195, %196) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %198 = "cute.make_layout"(%194, %197) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %199:4 = "cute.get_scalars"(%198) <{only_dynamic}> : (!cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> (i32, i32, i64, i64)
      %200 = "cute.make_shape"(%199#0) : (i32) -> !cute.shape<"(64,128,?)">
      %201 = "cute.assume"(%199#2) : (i64) -> !cute.i64<divby 8>
      %202 = "cute.assume"(%199#3) : (i64) -> !cute.i64<divby 512>
      %203 = "cute.make_stride"(%201, %202) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %204 = "cute.make_layout"(%200, %203) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,128,?)">, !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">) -> !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %205 = "cute.static"() : () -> !cute.int_tuple<"0">
      %206 = "cute.get_iter"(%185) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %207 = "cute.add_offset"(%206, %205) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %208 = "cute.make_view"(%207, %204) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">) -> !memref_gmem_bf16_3
      %209 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %210 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %211:7 = "cute.get_scalars"(%210) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> (i32, i32, i32, i32, i64, i64, i64)
      %212 = "cute.assume"(%211#3) : (i32) -> !cute.i32<divby 8>
      %213 = "cute.make_shape"(%211#2, %212) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %214 = "cute.assume"(%211#6) : (i64) -> !cute.i64<divby 8>
      %215 = "cute.make_stride"(%214) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %216 = "cute.make_layout"(%213, %215) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %217 = "cute.crd2idx"(%209, %210) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %218 = "cute.get_iter"(%arg10) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %219 = "cute.add_offset"(%218, %217) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %220 = "cute.make_view"(%219, %216) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> !memref_gmem_bf16_1
      %221 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %222 = "cute.get_scalars"(%221) <{only_dynamic}> : (!cute.coord<"(?,_)">) -> i32
      %223 = "cute.make_coord"(%222) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %224 = "cute.get_layout"(%220) : (!memref_gmem_bf16_1) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %225:3 = "cute.get_scalars"(%224) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> (i32, i32, i64)
      %226 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %227 = "arith.ceildivsi"(%225#0, %226) : (i32, i32) -> i32
      %228 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %229 = "arith.muli"(%225#2, %228) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %230 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %231 = "arith.ceildivsi"(%225#1, %230) : (i32, i32) -> i32
      %232 = "cute.make_shape"(%227, %231) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %233 = "cute.assume"(%225#2) : (i64) -> !cute.i64<divby 8>
      %234 = "cute.assume"(%229) : (i64) -> !cute.i64<divby 512>
      %235 = "cute.make_stride"(%233, %234) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},64))">
      %236 = "cute.make_layout"(%232, %235) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,64),(?,?))">, !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},64))">) -> !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %237:4 = "cute.get_scalars"(%236) <{only_dynamic}> : (!cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">) -> (i32, i32, i64, i64)
      %238 = "cute.make_shape"(%237#1) : (i32) -> !cute.shape<"(64,64,?)">
      %239 = "cute.assume"(%237#2) : (i64) -> !cute.i64<divby 8>
      %240 = "cute.make_stride"(%239) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1,64)">
      %241 = "cute.make_layout"(%238, %240) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,64,?)">, !cute.stride<"(?{i64 div=8},1,64)">) -> !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %242 = "cute.crd2idx"(%223, %236) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">) -> !cute.int_tuple<"?{i64 div=512}">
      %243 = "cute.get_iter"(%220) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %244 = "cute.add_offset"(%243, %242) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %245 = "cute.make_view"(%244, %241) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">) -> !memref_gmem_bf16_4
      %246 = "cute_nvgpu.arch.get_dyn_smem"() : () -> !cute.ptr<i8, smem, align<1024>>
      %247 = "cute.static"() : () -> !cute.int_tuple<"0">
      %248 = "cute.add_offset"(%246, %247) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %249 = "cute.static"() : () -> !cute.int_tuple<"16384">
      %250 = "cute.add_offset"(%246, %249) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %251 = "cute.static"() : () -> !cute.int_tuple<"32768">
      %252 = "cute.add_offset"(%246, %251) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %253 = "cute.static"() : () -> !cute.int_tuple<"49152">
      %254 = "cute.add_offset"(%246, %253) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %255 = "cute.recast_iter"(%248) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %256 = "cute.make_view"(%255, %47) : (!cute.ptr<bf16, smem, align<1024>>, !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !memref_smem_bf16_
      %257 = "cute.get_iter"(%256) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %258 = "cute.recast_iter"(%250) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %259 = "cute.make_view"(%258, %48) : (!cute.ptr<bf16, smem, align<1024>>, !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !memref_smem_bf16_
      %260 = "cute.recast_iter"(%252) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %261 = "cute.make_view"(%260, %48) : (!cute.ptr<bf16, smem, align<1024>>, !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">) -> !memref_smem_bf16_
      %262 = "cute.recast_iter"(%254) : (!cute.ptr<i8, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>>
      %263 = "cute.make_view"(%262, %49) : (!cute.ptr<bf16, smem, align<1024>>, !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">) -> !memref_smem_bf16_1
      %264 = "cute.get_iter"(%261) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %265 = "cute.make_view"(%264) : (!cute.ptr<bf16, smem, align<1024>>) -> !memref_smem_bf16_2
      %266 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %267 = "cute.get_iter"(%138) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %268 = "cute.get_layout"(%138) : (!memref_gmem_bf16_2) -> !cute.layout<"(64,128):(?{i64 div=8},1)">
      %269 = "cute.get_scalars"(%268) <{only_dynamic}> : (!cute.layout<"(64,128):(?{i64 div=8},1)">) -> i64
      %270 = "cute.get_scalars"(%266) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %271 = "arith.constant"() <{value = 16 : i64}> : () -> i64
      %272 = "arith.muli"(%269, %271) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %273 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %274 = "arith.divsi"(%270, %273) : (i32, i32) -> i32
      %275 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %276 = "arith.remsi"(%270, %275) : (i32, i32) -> i32
      %277 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %278 = "arith.muli"(%276, %277) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %279 = "arith.extsi"(%274) : (i32) -> i64
      %280 = "arith.muli"(%279, %269) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %281 = "arith.extsi"(%278) : (i32) -> i64
      %282 = "arith.addi"(%281, %280) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %283 = "cute.assume"(%282) : (i64) -> !cute.i64<divby 8>
      %284 = "cute.make_int_tuple"(%283) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %285 = "cute.add_offset"(%267, %284) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %286 = "cute.static"() : () -> !cute.shape<"((8,1),4,2)">
      %287 = "cute.assume"(%272) : (i64) -> !cute.i64<divby 128>
      %288 = "cute.make_stride"(%287) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %289 = "cute.make_layout"(%286, %288) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2)">, !cute.stride<"((1,0),?{i64 div=128},64)">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %290 = "cute.make_view"(%285, %289) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
      %291 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %292 = "cute.get_iter"(%256) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %293 = "cute.get_scalars"(%291) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %294 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %295 = "arith.divsi"(%293, %294) : (i32, i32) -> i32
      %296 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %297 = "arith.remsi"(%293, %296) : (i32, i32) -> i32
      %298 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %299 = "arith.divsi"(%297, %298) : (i32, i32) -> i32
      %300 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %301 = "arith.muli"(%299, %300) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %302 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %303 = "arith.muli"(%295, %302) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %304 = "arith.addi"(%301, %303) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %305 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %306 = "arith.xori"(%304, %305) : (i32, i32) -> i32
      %307 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %308 = "arith.remsi"(%293, %307) : (i32, i32) -> i32
      %309 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %310 = "arith.remsi"(%308, %309) : (i32, i32) -> i32
      %311 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %312 = "arith.muli"(%310, %311) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %313 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %314 = "arith.andi"(%306, %313) : (i32, i32) -> i32
      %315 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %316 = "arith.shrsi"(%314, %315) : (i32, i32) -> i32
      %317 = "arith.xori"(%306, %316) : (i32, i32) -> i32
      %318 = "arith.addi"(%317, %312) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %319 = "cute.assume"(%318) : (i32) -> !cute.i32<divby 8>
      %320 = "cute.make_int_tuple"(%319) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %321 = "cute.add_offset"(%292, %320) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %322 = "cute.make_view"(%321) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_3
      %323 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %324 = "cute.get_iter"(%173) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %325 = "cute.get_layout"(%173) : (!memref_gmem_bf16_3) -> !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %326:3 = "cute.get_scalars"(%325) <{only_dynamic}> : (!cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">) -> (i32, i64, i64)
      %327 = "cute.get_scalars"(%323) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %328 = "arith.constant"() <{value = 16 : i64}> : () -> i64
      %329 = "arith.muli"(%326#1, %328) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %330 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %331 = "arith.divsi"(%327, %330) : (i32, i32) -> i32
      %332 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %333 = "arith.remsi"(%327, %332) : (i32, i32) -> i32
      %334 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %335 = "arith.muli"(%333, %334) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %336 = "arith.extsi"(%331) : (i32) -> i64
      %337 = "arith.muli"(%336, %326#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %338 = "arith.extsi"(%335) : (i32) -> i64
      %339 = "arith.addi"(%338, %337) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %340 = "cute.assume"(%339) : (i64) -> !cute.i64<divby 8>
      %341 = "cute.make_int_tuple"(%340) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %342 = "cute.add_offset"(%324, %341) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %343 = "cute.make_shape"(%326#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %344 = "cute.assume"(%329) : (i64) -> !cute.i64<divby 128>
      %345 = "cute.assume"(%326#2) : (i64) -> !cute.i64<divby 512>
      %346 = "cute.make_stride"(%344, %345) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %347 = "cute.make_layout"(%343, %346) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2,?)">, !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %348 = "cute.make_view"(%342, %347) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !memref_gmem_bf16_6
      %349 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %350 = "cute.get_iter"(%259) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %351 = "cute.get_scalars"(%349) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %352 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %353 = "arith.divsi"(%351, %352) : (i32, i32) -> i32
      %354 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %355 = "arith.remsi"(%351, %354) : (i32, i32) -> i32
      %356 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %357 = "arith.divsi"(%355, %356) : (i32, i32) -> i32
      %358 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %359 = "arith.muli"(%357, %358) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %360 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %361 = "arith.muli"(%353, %360) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %362 = "arith.addi"(%359, %361) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %363 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %364 = "arith.xori"(%362, %363) : (i32, i32) -> i32
      %365 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %366 = "arith.remsi"(%351, %365) : (i32, i32) -> i32
      %367 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %368 = "arith.remsi"(%366, %367) : (i32, i32) -> i32
      %369 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %370 = "arith.muli"(%368, %369) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %371 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %372 = "arith.andi"(%364, %371) : (i32, i32) -> i32
      %373 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %374 = "arith.shrsi"(%372, %373) : (i32, i32) -> i32
      %375 = "arith.xori"(%364, %374) : (i32, i32) -> i32
      %376 = "arith.addi"(%375, %370) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %377 = "cute.assume"(%376) : (i32) -> !cute.i32<divby 8>
      %378 = "cute.make_int_tuple"(%377) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %379 = "cute.add_offset"(%350, %378) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %380 = "cute.make_view"(%379) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_3
      %381 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %382 = "cute.get_iter"(%208) : (!memref_gmem_bf16_3) -> !cute.ptr<bf16, gmem, align<16>>
      %383 = "cute.get_layout"(%208) : (!memref_gmem_bf16_3) -> !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %384:3 = "cute.get_scalars"(%383) <{only_dynamic}> : (!cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">) -> (i32, i64, i64)
      %385 = "cute.get_scalars"(%381) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %386 = "arith.constant"() <{value = 16 : i64}> : () -> i64
      %387 = "arith.muli"(%384#1, %386) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %388 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %389 = "arith.divsi"(%385, %388) : (i32, i32) -> i32
      %390 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %391 = "arith.remsi"(%385, %390) : (i32, i32) -> i32
      %392 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %393 = "arith.muli"(%391, %392) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %394 = "arith.extsi"(%389) : (i32) -> i64
      %395 = "arith.muli"(%394, %384#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %396 = "arith.extsi"(%393) : (i32) -> i64
      %397 = "arith.addi"(%396, %395) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %398 = "cute.assume"(%397) : (i64) -> !cute.i64<divby 8>
      %399 = "cute.make_int_tuple"(%398) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %400 = "cute.add_offset"(%382, %399) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %401 = "cute.make_shape"(%384#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %402 = "cute.assume"(%387) : (i64) -> !cute.i64<divby 128>
      %403 = "cute.assume"(%384#2) : (i64) -> !cute.i64<divby 512>
      %404 = "cute.make_stride"(%402, %403) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %405 = "cute.make_layout"(%401, %404) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2,?)">, !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %406 = "cute.make_view"(%400, %405) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !memref_gmem_bf16_6
      %407 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %408 = "cute.get_iter"(%261) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %409 = "cute.get_scalars"(%407) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %410 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %411 = "arith.divsi"(%409, %410) : (i32, i32) -> i32
      %412 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %413 = "arith.remsi"(%409, %412) : (i32, i32) -> i32
      %414 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %415 = "arith.divsi"(%413, %414) : (i32, i32) -> i32
      %416 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %417 = "arith.muli"(%415, %416) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %418 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %419 = "arith.muli"(%411, %418) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %420 = "arith.addi"(%417, %419) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %421 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %422 = "arith.xori"(%420, %421) : (i32, i32) -> i32
      %423 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %424 = "arith.remsi"(%409, %423) : (i32, i32) -> i32
      %425 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %426 = "arith.remsi"(%424, %425) : (i32, i32) -> i32
      %427 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %428 = "arith.muli"(%426, %427) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %429 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %430 = "arith.andi"(%422, %429) : (i32, i32) -> i32
      %431 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %432 = "arith.shrsi"(%430, %431) : (i32, i32) -> i32
      %433 = "arith.xori"(%422, %432) : (i32, i32) -> i32
      %434 = "arith.addi"(%433, %428) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %435 = "cute.assume"(%434) : (i32) -> !cute.i32<divby 8>
      %436 = "cute.make_int_tuple"(%435) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %437 = "cute.add_offset"(%408, %436) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %438 = "cute.make_view"(%437) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_3
      %439 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %440 = "cute.get_iter"(%245) : (!memref_gmem_bf16_4) -> !cute.ptr<bf16, gmem, align<16>>
      %441 = "cute.get_layout"(%245) : (!memref_gmem_bf16_4) -> !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %442:2 = "cute.get_scalars"(%441) <{only_dynamic}> : (!cute.layout<"(64,64,?):(?{i64 div=8},1,64)">) -> (i32, i64)
      %443 = "cute.get_scalars"(%439) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %444 = "arith.constant"() <{value = 16 : i64}> : () -> i64
      %445 = "arith.muli"(%442#1, %444) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %446 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %447 = "arith.divsi"(%443, %446) : (i32, i32) -> i32
      %448 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %449 = "arith.remsi"(%443, %448) : (i32, i32) -> i32
      %450 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %451 = "arith.muli"(%449, %450) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %452 = "arith.extsi"(%447) : (i32) -> i64
      %453 = "arith.muli"(%452, %442#1) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %454 = "arith.extsi"(%451) : (i32) -> i64
      %455 = "arith.addi"(%454, %453) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %456 = "cute.assume"(%455) : (i64) -> !cute.i64<divby 8>
      %457 = "cute.make_int_tuple"(%456) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %458 = "cute.add_offset"(%440, %457) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %459 = "cute.make_shape"(%442#0) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %460 = "cute.assume"(%445) : (i64) -> !cute.i64<divby 128>
      %461 = "cute.make_stride"(%460) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},0,64)">
      %462 = "cute.make_layout"(%459, %461) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,1,?)">, !cute.stride<"((1,0),?{i64 div=128},0,64)">) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
      %463 = "cute.make_view"(%458, %462) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !memref_gmem_bf16_7
      %464 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %465 = "cute.get_iter"(%263) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<1024>>
      %466 = "cute.get_scalars"(%464) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %467 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %468 = "arith.divsi"(%466, %467) : (i32, i32) -> i32
      %469 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %470 = "arith.remsi"(%466, %469) : (i32, i32) -> i32
      %471 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %472 = "arith.divsi"(%470, %471) : (i32, i32) -> i32
      %473 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %474 = "arith.muli"(%472, %473) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %475 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %476 = "arith.muli"(%468, %475) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %477 = "arith.addi"(%474, %476) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %478 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %479 = "arith.xori"(%477, %478) : (i32, i32) -> i32
      %480 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %481 = "arith.remsi"(%466, %480) : (i32, i32) -> i32
      %482 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %483 = "arith.remsi"(%481, %482) : (i32, i32) -> i32
      %484 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %485 = "arith.muli"(%483, %484) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %486 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %487 = "arith.andi"(%479, %486) : (i32, i32) -> i32
      %488 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %489 = "arith.shrsi"(%487, %488) : (i32, i32) -> i32
      %490 = "arith.xori"(%479, %489) : (i32, i32) -> i32
      %491 = "arith.addi"(%490, %485) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %492 = "cute.assume"(%491) : (i32) -> !cute.i32<divby 8>
      %493 = "cute.make_int_tuple"(%492) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %494 = "cute.add_offset"(%465, %493) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %495 = "cute.make_view"(%494) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_4
      %496 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_
      %497 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_1
      %498 = "cute.static"() : () -> !cute.swizzle<"S<3,4,3>">
      %499 = "cute.memref.alloca"() : () -> !memref_rmem_bf16_2
      %500 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
      %501 = "cute.memref.alloca"(%500) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !memref_rmem_f32_
      %502 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
      %503 = "vector.splat"(%502) : (f32) -> vector<64xf32>
      "cute.memref.store_vec"(%503, %501) : (vector<64xf32>, !memref_rmem_f32_) -> ()
      %504 = "cute.make_atom"() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %505 = "cute.make_atom"() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %506 = "cute.make_atom"() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %507 = "cute.make_atom"() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %508 = "cute.static"() : () -> !cute.layout<"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">
      %509 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %510 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %511 = "cute.make_tiled_copy"(%504) : (!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>) -> !copy_ldsm_4_
      %512 = "cute.static"() : () -> !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %513 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %514 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %515 = "cute.make_tiled_copy"(%505) : (!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>) -> !copy_ldsm_4_1
      %516 = "cute.static"() : () -> !cute.layout<"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">
      %517 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %518 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %519 = "cute.make_tiled_copy"(%506) : (!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>) -> !copy_ldsm_4_2
      %520 = "cute.static"() : () -> !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %521 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %522 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %523 = "cute.make_tiled_copy"(%507) : (!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>) -> !copy_ldsm_4_3
      %524 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %525 = "cute.get_iter"(%256) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %526 = "cute.get_scalars"(%524) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %527 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %528 = "arith.remsi"(%526, %527) : (i32, i32) -> i32
      %529 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %530 = "arith.muli"(%528, %529) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %531 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %532 = "arith.xori"(%530, %531) : (i32, i32) -> i32
      %533 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %534 = "arith.divsi"(%526, %533) : (i32, i32) -> i32
      %535 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %536 = "arith.divsi"(%534, %535) : (i32, i32) -> i32
      %537 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %538 = "arith.remsi"(%534, %537) : (i32, i32) -> i32
      %539 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %540 = "arith.muli"(%538, %539) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %541 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
      %542 = "arith.muli"(%536, %541) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %543 = "arith.addi"(%540, %542) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %544 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %545 = "arith.andi"(%532, %544) : (i32, i32) -> i32
      %546 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %547 = "arith.cmpi"(%545, %546) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %548 = "scf.if"(%547) ({
        %6726 = "arith.constant"() <{value = 16 : i32}> : () -> i32
        "scf.yield"(%6726) : (i32) -> ()
      }, {
        %6725 = "arith.constant"() <{value = -16 : i32}> : () -> i32
        "scf.yield"(%6725) : (i32) -> ()
      }) : (i1) -> i32
      %549 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %550 = "arith.andi"(%532, %549) : (i32, i32) -> i32
      %551 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %552 = "arith.cmpi"(%550, %551) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %553 = "scf.if"(%552) ({
        %6724 = "arith.constant"() <{value = 32 : i32}> : () -> i32
        "scf.yield"(%6724) : (i32) -> ()
      }, {
        %6723 = "arith.constant"() <{value = -32 : i32}> : () -> i32
        "scf.yield"(%6723) : (i32) -> ()
      }) : (i1) -> i32
      %554 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %555 = "arith.andi"(%532, %554) : (i32, i32) -> i32
      %556 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %557 = "arith.shrsi"(%555, %556) : (i32, i32) -> i32
      %558 = "arith.xori"(%532, %557) : (i32, i32) -> i32
      %559 = "arith.addi"(%558, %543) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %560 = "cute.assume"(%559) : (i32) -> !cute.i32<divby 8>
      %561 = "cute.make_int_tuple"(%560) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %562 = "cute.add_offset"(%525, %561) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %563 = "cute.static"() : () -> !cute.shape<"((8,1),1,((2,2),2))">
      %564 = "cute.assume"(%548) : (i32) -> !cute.i32<divby 16>
      %565 = "cute.assume"(%553) : (i32) -> !cute.i32<divby 32>
      %566 = "cute.make_stride"(%564, %565) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,((?{div=16},?{div=32}),4096))">
      %567 = "cute.make_layout"(%563, %566) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),1,((2,2),2))">, !cute.stride<"((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
      %568 = "cute.make_view"(%562, %567) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_5
      %569 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
      %570 = "cute.make_view"(%569) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_3
      %571 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %572 = "cute.get_iter"(%259) : (!memref_smem_bf16_) -> !cute.ptr<bf16, smem, align<1024>>
      %573 = "cute.get_scalars"(%571) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %574 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %575 = "arith.divsi"(%573, %574) : (i32, i32) -> i32
      %576 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %577 = "arith.remsi"(%573, %576) : (i32, i32) -> i32
      %578 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %579 = "arith.muli"(%577, %578) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %580 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %581 = "arith.divsi"(%575, %580) : (i32, i32) -> i32
      %582 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %583 = "arith.remsi"(%581, %582) : (i32, i32) -> i32
      %584 = "arith.constant"() <{value = 512 : i32}> : () -> i32
      %585 = "arith.muli"(%583, %584) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %586 = "arith.addi"(%579, %585) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %587 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %588 = "arith.xori"(%586, %587) : (i32, i32) -> i32
      %589 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %590 = "arith.divsi"(%573, %589) : (i32, i32) -> i32
      %591 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %592 = "arith.remsi"(%590, %591) : (i32, i32) -> i32
      %593 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %594 = "arith.muli"(%592, %593) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %595 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %596 = "arith.andi"(%588, %595) : (i32, i32) -> i32
      %597 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %598 = "arith.cmpi"(%596, %597) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %599 = "scf.if"(%598) ({
        %6722 = "arith.constant"() <{value = 16 : i32}> : () -> i32
        "scf.yield"(%6722) : (i32) -> ()
      }, {
        %6721 = "arith.constant"() <{value = -16 : i32}> : () -> i32
        "scf.yield"(%6721) : (i32) -> ()
      }) : (i1) -> i32
      %600 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %601 = "arith.andi"(%588, %600) : (i32, i32) -> i32
      %602 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %603 = "arith.cmpi"(%601, %602) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %604 = "scf.if"(%603) ({
        %6720 = "arith.constant"() <{value = 32 : i32}> : () -> i32
        "scf.yield"(%6720) : (i32) -> ()
      }, {
        %6719 = "arith.constant"() <{value = -32 : i32}> : () -> i32
        "scf.yield"(%6719) : (i32) -> ()
      }) : (i1) -> i32
      %605 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %606 = "arith.andi"(%588, %605) : (i32, i32) -> i32
      %607 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %608 = "arith.shrsi"(%606, %607) : (i32, i32) -> i32
      %609 = "arith.xori"(%588, %608) : (i32, i32) -> i32
      %610 = "arith.addi"(%609, %594) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %611 = "cute.assume"(%610) : (i32) -> !cute.i32<divby 8>
      %612 = "cute.make_int_tuple"(%611) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %613 = "cute.add_offset"(%572, %612) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %614 = "cute.static"() : () -> !cute.shape<"((8,1),4,((2,2),2))">
      %615 = "cute.assume"(%599) : (i32) -> !cute.i32<divby 16>
      %616 = "cute.assume"(%604) : (i32) -> !cute.i32<divby 32>
      %617 = "cute.make_stride"(%615, %616) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %618 = "cute.make_layout"(%614, %617) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,((2,2),2))">, !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %619 = "cute.make_view"(%613, %618) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_6
      %620 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
      %621 = "cute.make_view"(%620) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_4
      %622 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %623 = "cute.get_iter"(%265) : (!memref_smem_bf16_2) -> !cute.ptr<bf16, smem, align<1024>>
      %624 = "cute.get_scalars"(%622) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %625 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %626 = "arith.remsi"(%624, %625) : (i32, i32) -> i32
      %627 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %628 = "arith.muli"(%626, %627) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %629 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %630 = "arith.xori"(%628, %629) : (i32, i32) -> i32
      %631 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %632 = "arith.divsi"(%624, %631) : (i32, i32) -> i32
      %633 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %634 = "arith.remsi"(%632, %633) : (i32, i32) -> i32
      %635 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %636 = "arith.muli"(%634, %635) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %637 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %638 = "arith.andi"(%630, %637) : (i32, i32) -> i32
      %639 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %640 = "arith.cmpi"(%638, %639) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %641 = "scf.if"(%640) ({
        %6718 = "arith.constant"() <{value = 16 : i32}> : () -> i32
        "scf.yield"(%6718) : (i32) -> ()
      }, {
        %6717 = "arith.constant"() <{value = -16 : i32}> : () -> i32
        "scf.yield"(%6717) : (i32) -> ()
      }) : (i1) -> i32
      %642 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %643 = "arith.andi"(%630, %642) : (i32, i32) -> i32
      %644 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %645 = "arith.cmpi"(%643, %644) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %646 = "scf.if"(%645) ({
        %6716 = "arith.constant"() <{value = 32 : i32}> : () -> i32
        "scf.yield"(%6716) : (i32) -> ()
      }, {
        %6715 = "arith.constant"() <{value = -32 : i32}> : () -> i32
        "scf.yield"(%6715) : (i32) -> ()
      }) : (i1) -> i32
      %647 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %648 = "arith.andi"(%630, %647) : (i32, i32) -> i32
      %649 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %650 = "arith.shrsi"(%648, %649) : (i32, i32) -> i32
      %651 = "arith.xori"(%630, %650) : (i32, i32) -> i32
      %652 = "arith.addi"(%651, %636) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %653 = "cute.assume"(%652) : (i32) -> !cute.i32<divby 8>
      %654 = "cute.make_int_tuple"(%653) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %655 = "cute.add_offset"(%623, %654) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %656 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2),4)">
      %657 = "cute.assume"(%641) : (i32) -> !cute.i32<divby 16>
      %658 = "cute.assume"(%646) : (i32) -> !cute.i32<divby 32>
      %659 = "cute.make_stride"(%657, %658) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %660 = "cute.make_layout"(%656, %659) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2),4)">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %661 = "cute.make_view"(%655, %660) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> !memref_smem_bf16_7
      %662 = "cute.get_iter"(%499) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<8>>
      %663 = "cute.make_view"(%662) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_5
      %664 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %665 = "cute.get_iter"(%263) : (!memref_smem_bf16_1) -> !cute.ptr<bf16, smem, align<1024>>
      %666 = "cute.get_scalars"(%664) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %667 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %668 = "arith.remsi"(%666, %667) : (i32, i32) -> i32
      %669 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %670 = "arith.muli"(%668, %669) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %671 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %672 = "arith.xori"(%670, %671) : (i32, i32) -> i32
      %673 = "arith.constant"() <{value = 16 : i32}> : () -> i32
      %674 = "arith.divsi"(%666, %673) : (i32, i32) -> i32
      %675 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %676 = "arith.divsi"(%674, %675) : (i32, i32) -> i32
      %677 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %678 = "arith.remsi"(%674, %677) : (i32, i32) -> i32
      %679 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %680 = "arith.muli"(%678, %679) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %681 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
      %682 = "arith.muli"(%676, %681) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %683 = "arith.addi"(%680, %682) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %684 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %685 = "arith.andi"(%672, %684) : (i32, i32) -> i32
      %686 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %687 = "arith.cmpi"(%685, %686) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %688 = "scf.if"(%687) ({
        %6714 = "arith.constant"() <{value = 16 : i32}> : () -> i32
        "scf.yield"(%6714) : (i32) -> ()
      }, {
        %6713 = "arith.constant"() <{value = -16 : i32}> : () -> i32
        "scf.yield"(%6713) : (i32) -> ()
      }) : (i1) -> i32
      %689 = "arith.constant"() <{value = 256 : i32}> : () -> i32
      %690 = "arith.andi"(%672, %689) : (i32, i32) -> i32
      %691 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %692 = "arith.cmpi"(%690, %691) <{predicate = 0 : i64}> : (i32, i32) -> i1
      %693 = "scf.if"(%692) ({
        %6712 = "arith.constant"() <{value = 32 : i32}> : () -> i32
        "scf.yield"(%6712) : (i32) -> ()
      }, {
        %6711 = "arith.constant"() <{value = -32 : i32}> : () -> i32
        "scf.yield"(%6711) : (i32) -> ()
      }) : (i1) -> i32
      %694 = "arith.constant"() <{value = 896 : i32}> : () -> i32
      %695 = "arith.andi"(%672, %694) : (i32, i32) -> i32
      %696 = "arith.constant"() <{value = 3 : i32}> : () -> i32
      %697 = "arith.shrsi"(%695, %696) : (i32, i32) -> i32
      %698 = "arith.xori"(%672, %697) : (i32, i32) -> i32
      %699 = "arith.addi"(%698, %683) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %700 = "cute.assume"(%699) : (i32) -> !cute.i32<divby 8>
      %701 = "cute.make_int_tuple"(%700) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %702 = "cute.add_offset"(%665, %701) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %703 = "cute.static"() : () -> !cute.shape<"((8,1),1,(2,2))">
      %704 = "cute.assume"(%688) : (i32) -> !cute.i32<divby 16>
      %705 = "cute.assume"(%693) : (i32) -> !cute.i32<divby 32>
      %706 = "cute.make_stride"(%704, %705) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %707 = "cute.make_layout"(%703, %706) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),1,(2,2))">, !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %708 = "cute.make_view"(%702, %707) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !memref_smem_bf16_8
      %709 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %710 = "cute.get_shape"(%709) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %711:4 = "cute.get_leaves"(%710) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %712 = "cute.to_int_tuple"(%711#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %713 = "cute.to_int_tuple"(%711#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %714 = "cute.to_int_tuple"(%711#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %715 = "cute.to_int_tuple"(%711#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %716 = "cute.make_shape"(%712, %713, %714, %715) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %717 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %718 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3)">
      %719 = "cute.make_layout"(%716, %718) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?{div=8})">, !cute.stride<"(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %720 = "cute.make_view"(%717, %719) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %721 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %722 = "cute.get_shape"(%721) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %723:4 = "cute.get_leaves"(%722) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %724 = "cute.to_int_tuple"(%723#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %725 = "cute.to_int_tuple"(%723#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %726 = "cute.to_int_tuple"(%723#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %727 = "cute.to_int_tuple"(%723#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %728 = "cute.make_shape"(%724, %725, %726, %727) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %729 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %730 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3)">
      %731 = "cute.make_layout"(%728, %730) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?{div=8})">, !cute.stride<"(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %732 = "cute.make_view"(%729, %731) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %733 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %734 = "cute.get_shape"(%733) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %735:4 = "cute.get_leaves"(%734) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %736 = "cute.to_int_tuple"(%735#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %737 = "cute.to_int_tuple"(%735#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %738 = "cute.to_int_tuple"(%735#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %739 = "cute.to_int_tuple"(%735#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %740 = "cute.make_shape"(%736, %737, %738, %739) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %741 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %742 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3)">
      %743 = "cute.make_layout"(%740, %742) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?{div=8})">, !cute.stride<"(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %744 = "cute.make_view"(%741, %743) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %745 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %746 = "cute.get_layout"(%720) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %747:4 = "cute.get_scalars"(%746) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> (i32, i32, i32, i32)
      %748 = "cute.assume"(%747#3) : (i32) -> !cute.i32<divby 8>
      %749 = "cute.make_shape"(%747#1, %748) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %750 = "cute.static"() : () -> !cute.stride<"(1@1,1@3)">
      %751 = "cute.make_layout"(%749, %750) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %752 = "cute.crd2idx"(%745, %746) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %753 = "cute.get_iter"(%720) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %754 = "cute.add_offset"(%753, %752) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %755 = "cute.make_view"(%754, %751) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %756 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %757 = "cute.get_scalars"(%756) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %758 = "cute.make_coord"(%757) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %759 = "cute.get_layout"(%755) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %760:2 = "cute.get_scalars"(%759) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> (i32, i32)
      %761 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %762 = "arith.ceildivsi"(%760#0, %761) : (i32, i32) -> i32
      %763 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %764 = "arith.ceildivsi"(%760#1, %763) : (i32, i32) -> i32
      %765 = "cute.make_shape"(%762, %764) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %766 = "cute.static"() : () -> !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %767 = "cute.make_layout"(%765, %766) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((1@1,1@3),(64@1,128@3))">) -> !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %768 = "cute.crd2idx"(%758, %767) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %769 = "cute.get_iter"(%755) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %770 = "cute.add_offset"(%769, %768) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %771 = "cute.make_view"(%770) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %772 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %773 = "cute.get_layout"(%732) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %774:4 = "cute.get_scalars"(%773) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> (i32, i32, i32, i32)
      %775 = "cute.assume"(%774#3) : (i32) -> !cute.i32<divby 8>
      %776 = "cute.make_shape"(%774#1, %775) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %777 = "cute.static"() : () -> !cute.stride<"(1@1,1@3)">
      %778 = "cute.make_layout"(%776, %777) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %779 = "cute.crd2idx"(%772, %773) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %780 = "cute.get_iter"(%732) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %781 = "cute.add_offset"(%780, %779) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %782 = "cute.make_view"(%781, %778) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %783 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %784 = "cute.get_scalars"(%783) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %785 = "cute.make_coord"(%784) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %786 = "cute.get_layout"(%782) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %787:2 = "cute.get_scalars"(%786) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> (i32, i32)
      %788 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %789 = "arith.ceildivsi"(%787#0, %788) : (i32, i32) -> i32
      %790 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %791 = "arith.ceildivsi"(%787#1, %790) : (i32, i32) -> i32
      %792 = "cute.make_shape"(%789, %791) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %793 = "cute.static"() : () -> !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %794 = "cute.make_layout"(%792, %793) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((1@1,1@3),(64@1,128@3))">) -> !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %795 = "cute.crd2idx"(%785, %794) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %796 = "cute.get_iter"(%782) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %797 = "cute.add_offset"(%796, %795) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %798 = "cute.make_view"(%797) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %799 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %800 = "cute.get_layout"(%744) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %801:4 = "cute.get_scalars"(%800) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> (i32, i32, i32, i32)
      %802 = "cute.assume"(%801#3) : (i32) -> !cute.i32<divby 8>
      %803 = "cute.make_shape"(%801#2, %802) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %804 = "cute.static"() : () -> !cute.stride<"(1@2,1@3)">
      %805 = "cute.make_layout"(%803, %804) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@2,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %806 = "cute.crd2idx"(%799, %800) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,?,0,0)">
      %807 = "cute.get_iter"(%744) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %808 = "cute.add_offset"(%807, %806) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.int_tuple<"(?,?,0,0)">) -> !cute.arith_tuple_iter<"(?,?,0,0)">
      %809 = "cute.make_view"(%808, %805) : (!cute.arith_tuple_iter<"(?,?,0,0)">, !cute.layout<"(?,?{div=8}):(1@2,1@3)">) -> !cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">
      %810 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %811 = "cute.get_scalars"(%810) <{only_dynamic}> : (!cute.coord<"(?,_)">) -> i32
      %812 = "cute.make_coord"(%811) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %813 = "cute.get_layout"(%809) : (!cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %814:2 = "cute.get_scalars"(%813) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@2,1@3)">) -> (i32, i32)
      %815 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %816 = "arith.ceildivsi"(%814#0, %815) : (i32, i32) -> i32
      %817 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %818 = "arith.ceildivsi"(%814#1, %817) : (i32, i32) -> i32
      %819 = "cute.make_shape"(%816, %818) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %820 = "cute.static"() : () -> !cute.stride<"((1@2,1@3),(64@2,64@3))">
      %821 = "cute.make_layout"(%819, %820) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,64),(?,?))">, !cute.stride<"((1@2,1@3),(64@2,64@3))">) -> !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %822:2 = "cute.get_scalars"(%821) <{only_dynamic}> : (!cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">) -> (i32, i32)
      %823 = "cute.make_shape"(%822#1) : (i32) -> !cute.shape<"(64,64,?)">
      %824 = "cute.static"() : () -> !cute.stride<"(1@2,1@3,64@3)">
      %825 = "cute.make_layout"(%823, %824) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,64,?)">, !cute.stride<"(1@2,1@3,64@3)">) -> !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %826 = "cute.crd2idx"(%812, %821) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">) -> !cute.int_tuple<"(0,0,?{div=64},0)">
      %827 = "cute.get_iter"(%809) : (!cute.coord_tensor<"(?,?,0,0)", "(?,?{div=8}):(1@2,1@3)">) -> !cute.arith_tuple_iter<"(?,?,0,0)">
      %828 = "cute.add_offset"(%827, %826) : (!cute.arith_tuple_iter<"(?,?,0,0)">, !cute.int_tuple<"(0,0,?{div=64},0)">) -> !cute.arith_tuple_iter<"(?,?,?{div=64},0)">
      %829 = "cute.make_view"(%828, %825) : (!cute.arith_tuple_iter<"(?,?,?{div=64},0)">, !cute.layout<"(64,64,?):(1@2,1@3,64@3)">) -> !cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">
      %830 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %831 = "cute.get_iter"(%771) : (!cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %832 = "cute.get_scalars"(%830) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %833 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %834 = "arith.divsi"(%832, %833) : (i32, i32) -> i32
      %835 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %836 = "arith.remsi"(%832, %835) : (i32, i32) -> i32
      %837 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %838 = "arith.muli"(%836, %837) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %839 = "cute.assume"(%838) : (i32) -> !cute.i32<divby 8>
      %840 = "cute.make_int_tuple"(%834, %839) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %841 = "cute.add_offset"(%831, %840) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %842 = "cute.make_view"(%841) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %843 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %844 = "cute.get_iter"(%798) : (!cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %845 = "cute.get_scalars"(%843) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %846 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %847 = "arith.divsi"(%845, %846) : (i32, i32) -> i32
      %848 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %849 = "arith.remsi"(%845, %848) : (i32, i32) -> i32
      %850 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %851 = "arith.muli"(%849, %850) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %852 = "cute.assume"(%851) : (i32) -> !cute.i32<divby 8>
      %853 = "cute.make_int_tuple"(%847, %852) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %854 = "cute.add_offset"(%844, %853) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %855 = "cute.make_view"(%854) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %856 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %857 = "cute.get_iter"(%829) : (!cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?{div=64},0)">
      %858 = "cute.get_layout"(%829) : (!cute.coord_tensor<"(?,?,?{div=64},0)", "(64,64,?):(1@2,1@3,64@3)">) -> !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %859 = "cute.get_scalars"(%858) <{only_dynamic}> : (!cute.layout<"(64,64,?):(1@2,1@3,64@3)">) -> i32
      %860 = "cute.get_scalars"(%856) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %861 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %862 = "arith.divsi"(%860, %861) : (i32, i32) -> i32
      %863 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %864 = "arith.remsi"(%860, %863) : (i32, i32) -> i32
      %865 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %866 = "arith.muli"(%864, %865) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %867 = "cute.assume"(%866) : (i32) -> !cute.i32<divby 8>
      %868 = "cute.make_int_tuple"(%862, %867) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,0,?,?{div=8})">
      %869 = "cute.add_offset"(%857, %868) : (!cute.arith_tuple_iter<"(?,?,?{div=64},0)">, !cute.int_tuple<"(0,0,?,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %870 = "cute.make_shape"(%859) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %871 = "cute.static"() : () -> !cute.stride<"((1@3,0),16@2,0,64@3)">
      %872 = "cute.make_layout"(%870, %871) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,1,?)">, !cute.stride<"((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %873 = "cute.make_view"(%869, %872) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %874 = "cute.static"() : () -> !cute.layout<"(1,4,2):(2,0,1)">
      %875 = "cute.memref.alloca"(%874) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !memref_rmem_i8_
      %876 = "cute.static"() : () -> !cute.layout<"(1,4,2):(2,0,1)">
      %877 = "cute.memref.alloca"(%876) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !memref_rmem_i8_
      %878 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %879 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %880 = "cute.add_offset"(%879, %878) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %881 = "cute.make_view"(%880) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %882 = "cute.get_iter"(%881) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %883 = "cute.deref_arith_tuple_iter"(%882) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %884:4 = "cute.get_leaves"(%883) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %885 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %886 = "cute.get_shape"(%885) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %887:4 = "cute.get_leaves"(%886) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %888 = "cute.to_int_tuple"(%887#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %889 = "cute.make_coord"(%884#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %890 = "cute.make_coord"(%888) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %891 = "cute.get_scalars"(%889) : (!cute.coord<"?{div=8}">) -> i32
      %892 = "cute.get_scalars"(%890) : (!cute.coord<"?{div=8}">) -> i32
      %893 = "arith.constant"() <{value = true}> : () -> i1
      %894 = "arith.cmpi"(%891, %892) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %895 = "arith.andi"(%893, %894) : (i1, i1) -> i1
      %896 = "arith.extui"(%895) : (i1) -> i8
      %897 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%875, %897, %896) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %898 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,64)">
      %899 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %900 = "cute.add_offset"(%899, %898) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %901 = "cute.make_view"(%900) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %902 = "cute.get_iter"(%901) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %903 = "cute.deref_arith_tuple_iter"(%902) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %904:4 = "cute.get_leaves"(%903) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %905 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %906 = "cute.get_shape"(%905) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %907:4 = "cute.get_leaves"(%906) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %908 = "cute.to_int_tuple"(%907#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %909 = "cute.make_coord"(%904#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %910 = "cute.make_coord"(%908) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %911 = "cute.get_scalars"(%909) : (!cute.coord<"?{div=8}">) -> i32
      %912 = "cute.get_scalars"(%910) : (!cute.coord<"?{div=8}">) -> i32
      %913 = "arith.constant"() <{value = true}> : () -> i1
      %914 = "arith.cmpi"(%911, %912) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %915 = "arith.andi"(%913, %914) : (i1, i1) -> i1
      %916 = "arith.extui"(%915) : (i1) -> i8
      %917 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
      "cute.memref.store"(%875, %917, %916) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %918 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %919 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %920 = "cute.add_offset"(%919, %918) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %921 = "cute.make_view"(%920) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %922 = "cute.get_iter"(%921) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %923 = "cute.deref_arith_tuple_iter"(%922) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %924:4 = "cute.get_leaves"(%923) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %925 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %926 = "cute.get_shape"(%925) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %927:4 = "cute.get_leaves"(%926) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %928 = "cute.to_int_tuple"(%927#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %929 = "cute.make_coord"(%924#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %930 = "cute.make_coord"(%928) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %931 = "cute.get_scalars"(%929) : (!cute.coord<"?{div=8}">) -> i32
      %932 = "cute.get_scalars"(%930) : (!cute.coord<"?{div=8}">) -> i32
      %933 = "arith.constant"() <{value = true}> : () -> i1
      %934 = "arith.cmpi"(%931, %932) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %935 = "arith.andi"(%933, %934) : (i1, i1) -> i1
      %936 = "arith.extui"(%935) : (i1) -> i8
      %937 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%877, %937, %936) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %938 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,64)">
      %939 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %940 = "cute.add_offset"(%939, %938) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %941 = "cute.make_view"(%940) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %942 = "cute.get_iter"(%941) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %943 = "cute.deref_arith_tuple_iter"(%942) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %944:4 = "cute.get_leaves"(%943) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %945 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %946 = "cute.get_shape"(%945) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %947:4 = "cute.get_leaves"(%946) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %948 = "cute.to_int_tuple"(%947#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %949 = "cute.make_coord"(%944#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %950 = "cute.make_coord"(%948) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %951 = "cute.get_scalars"(%949) : (!cute.coord<"?{div=8}">) -> i32
      %952 = "cute.get_scalars"(%950) : (!cute.coord<"?{div=8}">) -> i32
      %953 = "arith.constant"() <{value = true}> : () -> i1
      %954 = "arith.cmpi"(%951, %952) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %955 = "arith.andi"(%953, %954) : (i1, i1) -> i1
      %956 = "arith.extui"(%955) : (i1) -> i8
      %957 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
      "cute.memref.store"(%877, %957, %956) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %958 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %959 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %960 = "cute.add_offset"(%959, %958) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %961 = "cute.make_view"(%960) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %962 = "cute.get_iter"(%961) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %963 = "cute.deref_arith_tuple_iter"(%962) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %964:4 = "cute.get_leaves"(%963) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %965 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %966 = "cute.get_shape"(%965) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %967:4 = "cute.get_leaves"(%966) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %968 = "cute.to_int_tuple"(%967#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %969 = "cute.make_coord"(%964#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %970 = "cute.make_coord"(%968) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %971 = "cute.get_scalars"(%969) : (!cute.coord<"?">) -> i32
      %972 = "cute.get_scalars"(%970) : (!cute.coord<"?">) -> i32
      %973 = "arith.constant"() <{value = true}> : () -> i1
      %974 = "arith.cmpi"(%971, %972) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %975 = "arith.andi"(%973, %974) : (i1, i1) -> i1
      "scf.if"(%975) ({
        %6652 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6653 = "cute.get_iter"(%290) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %6654 = "cute.add_offset"(%6653, %6652) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %6655 = "cute.make_view"(%6654) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6656 = "cute.get_iter"(%6655) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6657 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6658 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6659 = "cute.add_offset"(%6658, %6657) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6660 = "cute.make_view"(%6659) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6661 = "cute.get_iter"(%6660) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6662 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6663 = "cute.get_iter"(%875) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6664 = "cute.add_offset"(%6663, %6662) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6665 = "cute.make_view"(%6664) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6666 = "cute.get_iter"(%6665) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6667 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6668 = "cute.make_view"(%6656, %6667) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6669 = "cute.get_iter"(%6668) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6670 = "cute.make_view"(%6669) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6671 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6672 = "cute.make_view"(%6661, %6671) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6673 = "cute.get_iter"(%6672) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6674 = "cute.make_view"(%6673) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6675 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6676 = "cute.make_view"(%6666, %6675) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6677 = "cute.get_iter"(%6676) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6678 = "cute.make_view"(%6677) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6679 = "cute.static"() : () -> !cute.layout<"1:0">
        %6680 = "cute.get_iter"(%6670) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6681 = "cute.get_iter"(%6674) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6682 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6683 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6684 = "cute.get_iter"(%6678) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6685 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6686 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6687 = "cute.get_scalars"(%6686) : (!cute.int_tuple<"2">) -> i32
        %6688 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6689 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6688, %6687, %6689) ({
        ^bb0(%arg101: i32):
          %6690 = "cute.make_coord"(%arg101) : (i32) -> !cute.coord<"(_,?)">
          %6691 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6692 = "cute.crd2idx"(%6690, %6682) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6693 = "cute.add_offset"(%6680, %6692) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6694 = "cute.make_view"(%6693, %6691) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6695 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6696 = "cute.crd2idx"(%6690, %6683) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6697 = "cute.add_offset"(%6681, %6696) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6698 = "cute.make_view"(%6697, %6695) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6699 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6700 = "cute.crd2idx"(%6690, %6685) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6701 = "cute.add_offset"(%6684, %6700) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6702 = "cute.make_view"(%6701, %6699) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6703 = "cute.get_iter"(%6694) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6704 = "cute.get_iter"(%6698) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6705 = "cute.get_iter"(%6702) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6706 = "builtin.unrealized_conversion_cast"(%6705) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6707 = "llvm.load"(%6706) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6708 = "llvm.trunc"(%6707) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6709 = "cute.recast_iter"(%6703) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6710 = "cute.recast_iter"(%6704) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6710, %6709, %6708) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6646 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6647 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6648 = "cute.add_offset"(%6647, %6646) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6649 = "cute.make_view"(%6648) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6650 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6651 = "vector.splat"(%6650) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6651, %6649) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %976 = "cute.static"() : () -> !cute.int_tuple<"(0,16,0,0)">
      %977 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %978 = "cute.add_offset"(%977, %976) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %979 = "cute.make_view"(%978) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %980 = "cute.get_iter"(%979) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %981 = "cute.deref_arith_tuple_iter"(%980) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %982:4 = "cute.get_leaves"(%981) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %983 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %984 = "cute.get_shape"(%983) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %985:4 = "cute.get_leaves"(%984) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %986 = "cute.to_int_tuple"(%985#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %987 = "cute.make_coord"(%982#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %988 = "cute.make_coord"(%986) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %989 = "cute.get_scalars"(%987) : (!cute.coord<"?">) -> i32
      %990 = "cute.get_scalars"(%988) : (!cute.coord<"?">) -> i32
      %991 = "arith.constant"() <{value = true}> : () -> i1
      %992 = "arith.cmpi"(%989, %990) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %993 = "arith.andi"(%991, %992) : (i1, i1) -> i1
      "scf.if"(%993) ({
        %6585 = "cute.static"() : () -> !cute.coord<"(_,1,_)">
        %6586 = "cute.get_layout"(%290) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %6587 = "cute.crd2idx"(%6585, %6586) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %6588 = "cute.get_iter"(%290) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %6589 = "cute.add_offset"(%6588, %6587) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6590 = "cute.make_view"(%6589) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6591 = "cute.get_iter"(%6590) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6592 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6593 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6594 = "cute.add_offset"(%6593, %6592) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6595 = "cute.make_view"(%6594) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6596 = "cute.get_iter"(%6595) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6597 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6598 = "cute.get_iter"(%875) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6599 = "cute.add_offset"(%6598, %6597) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6600 = "cute.make_view"(%6599) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6601 = "cute.get_iter"(%6600) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6602 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6603 = "cute.make_view"(%6591, %6602) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6604 = "cute.get_iter"(%6603) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6605 = "cute.make_view"(%6604) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6606 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6607 = "cute.make_view"(%6596, %6606) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6608 = "cute.get_iter"(%6607) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6609 = "cute.make_view"(%6608) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6610 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6611 = "cute.make_view"(%6601, %6610) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6612 = "cute.get_iter"(%6611) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6613 = "cute.make_view"(%6612) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6614 = "cute.static"() : () -> !cute.layout<"1:0">
        %6615 = "cute.get_iter"(%6605) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6616 = "cute.get_iter"(%6609) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6617 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6618 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6619 = "cute.get_iter"(%6613) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6620 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6621 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6622 = "cute.get_scalars"(%6621) : (!cute.int_tuple<"2">) -> i32
        %6623 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6624 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6623, %6622, %6624) ({
        ^bb0(%arg100: i32):
          %6625 = "cute.make_coord"(%arg100) : (i32) -> !cute.coord<"(_,?)">
          %6626 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6627 = "cute.crd2idx"(%6625, %6617) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6628 = "cute.add_offset"(%6615, %6627) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6629 = "cute.make_view"(%6628, %6626) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6630 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6631 = "cute.crd2idx"(%6625, %6618) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6632 = "cute.add_offset"(%6616, %6631) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6633 = "cute.make_view"(%6632, %6630) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6634 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6635 = "cute.crd2idx"(%6625, %6620) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6636 = "cute.add_offset"(%6619, %6635) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6637 = "cute.make_view"(%6636, %6634) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6638 = "cute.get_iter"(%6629) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6639 = "cute.get_iter"(%6633) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6640 = "cute.get_iter"(%6637) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6641 = "builtin.unrealized_conversion_cast"(%6640) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6642 = "llvm.load"(%6641) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6643 = "llvm.trunc"(%6642) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6644 = "cute.recast_iter"(%6638) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6645 = "cute.recast_iter"(%6639) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6645, %6644, %6643) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6579 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6580 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6581 = "cute.add_offset"(%6580, %6579) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6582 = "cute.make_view"(%6581) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6583 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6584 = "vector.splat"(%6583) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6584, %6582) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %994 = "cute.static"() : () -> !cute.int_tuple<"(0,32,0,0)">
      %995 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %996 = "cute.add_offset"(%995, %994) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %997 = "cute.make_view"(%996) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %998 = "cute.get_iter"(%997) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %999 = "cute.deref_arith_tuple_iter"(%998) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1000:4 = "cute.get_leaves"(%999) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1001 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1002 = "cute.get_shape"(%1001) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1003:4 = "cute.get_leaves"(%1002) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1004 = "cute.to_int_tuple"(%1003#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1005 = "cute.make_coord"(%1000#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1006 = "cute.make_coord"(%1004) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1007 = "cute.get_scalars"(%1005) : (!cute.coord<"?">) -> i32
      %1008 = "cute.get_scalars"(%1006) : (!cute.coord<"?">) -> i32
      %1009 = "arith.constant"() <{value = true}> : () -> i1
      %1010 = "arith.cmpi"(%1007, %1008) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1011 = "arith.andi"(%1009, %1010) : (i1, i1) -> i1
      "scf.if"(%1011) ({
        %6518 = "cute.static"() : () -> !cute.coord<"(_,2,_)">
        %6519 = "cute.get_layout"(%290) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %6520 = "cute.crd2idx"(%6518, %6519) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %6521 = "cute.get_iter"(%290) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %6522 = "cute.add_offset"(%6521, %6520) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6523 = "cute.make_view"(%6522) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6524 = "cute.get_iter"(%6523) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6525 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6526 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6527 = "cute.add_offset"(%6526, %6525) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6528 = "cute.make_view"(%6527) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6529 = "cute.get_iter"(%6528) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6530 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6531 = "cute.get_iter"(%875) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6532 = "cute.add_offset"(%6531, %6530) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6533 = "cute.make_view"(%6532) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6534 = "cute.get_iter"(%6533) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6535 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6536 = "cute.make_view"(%6524, %6535) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6537 = "cute.get_iter"(%6536) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6538 = "cute.make_view"(%6537) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6539 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6540 = "cute.make_view"(%6529, %6539) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6541 = "cute.get_iter"(%6540) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6542 = "cute.make_view"(%6541) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6543 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6544 = "cute.make_view"(%6534, %6543) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6545 = "cute.get_iter"(%6544) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6546 = "cute.make_view"(%6545) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6547 = "cute.static"() : () -> !cute.layout<"1:0">
        %6548 = "cute.get_iter"(%6538) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6549 = "cute.get_iter"(%6542) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6550 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6551 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6552 = "cute.get_iter"(%6546) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6553 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6554 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6555 = "cute.get_scalars"(%6554) : (!cute.int_tuple<"2">) -> i32
        %6556 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6557 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6556, %6555, %6557) ({
        ^bb0(%arg99: i32):
          %6558 = "cute.make_coord"(%arg99) : (i32) -> !cute.coord<"(_,?)">
          %6559 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6560 = "cute.crd2idx"(%6558, %6550) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6561 = "cute.add_offset"(%6548, %6560) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6562 = "cute.make_view"(%6561, %6559) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6563 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6564 = "cute.crd2idx"(%6558, %6551) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6565 = "cute.add_offset"(%6549, %6564) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6566 = "cute.make_view"(%6565, %6563) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6567 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6568 = "cute.crd2idx"(%6558, %6553) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6569 = "cute.add_offset"(%6552, %6568) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6570 = "cute.make_view"(%6569, %6567) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6571 = "cute.get_iter"(%6562) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6572 = "cute.get_iter"(%6566) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6573 = "cute.get_iter"(%6570) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6574 = "builtin.unrealized_conversion_cast"(%6573) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6575 = "llvm.load"(%6574) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6576 = "llvm.trunc"(%6575) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6577 = "cute.recast_iter"(%6571) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6578 = "cute.recast_iter"(%6572) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6578, %6577, %6576) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6512 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6513 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6514 = "cute.add_offset"(%6513, %6512) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6515 = "cute.make_view"(%6514) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6516 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6517 = "vector.splat"(%6516) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6517, %6515) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1012 = "cute.static"() : () -> !cute.int_tuple<"(0,48,0,0)">
      %1013 = "cute.get_iter"(%842) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1014 = "cute.add_offset"(%1013, %1012) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1015 = "cute.make_view"(%1014) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1016 = "cute.get_iter"(%1015) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1017 = "cute.deref_arith_tuple_iter"(%1016) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1018:4 = "cute.get_leaves"(%1017) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1019 = "cute.get_layout"(%arg6) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1020 = "cute.get_shape"(%1019) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1021:4 = "cute.get_leaves"(%1020) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1022 = "cute.to_int_tuple"(%1021#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1023 = "cute.make_coord"(%1018#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1024 = "cute.make_coord"(%1022) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1025 = "cute.get_scalars"(%1023) : (!cute.coord<"?">) -> i32
      %1026 = "cute.get_scalars"(%1024) : (!cute.coord<"?">) -> i32
      %1027 = "arith.constant"() <{value = true}> : () -> i1
      %1028 = "arith.cmpi"(%1025, %1026) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1029 = "arith.andi"(%1027, %1028) : (i1, i1) -> i1
      "scf.if"(%1029) ({
        %6451 = "cute.static"() : () -> !cute.coord<"(_,3,_)">
        %6452 = "cute.get_layout"(%290) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %6453 = "cute.crd2idx"(%6451, %6452) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %6454 = "cute.get_iter"(%290) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %6455 = "cute.add_offset"(%6454, %6453) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6456 = "cute.make_view"(%6455) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6457 = "cute.get_iter"(%6456) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6458 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %6459 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6460 = "cute.add_offset"(%6459, %6458) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6461 = "cute.make_view"(%6460) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6462 = "cute.get_iter"(%6461) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6463 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6464 = "cute.get_iter"(%875) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6465 = "cute.add_offset"(%6464, %6463) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6466 = "cute.make_view"(%6465) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6467 = "cute.get_iter"(%6466) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6468 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6469 = "cute.make_view"(%6457, %6468) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6470 = "cute.get_iter"(%6469) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6471 = "cute.make_view"(%6470) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6472 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6473 = "cute.make_view"(%6462, %6472) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6474 = "cute.get_iter"(%6473) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6475 = "cute.make_view"(%6474) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6476 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6477 = "cute.make_view"(%6467, %6476) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6478 = "cute.get_iter"(%6477) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6479 = "cute.make_view"(%6478) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6480 = "cute.static"() : () -> !cute.layout<"1:0">
        %6481 = "cute.get_iter"(%6471) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6482 = "cute.get_iter"(%6475) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6483 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6484 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6485 = "cute.get_iter"(%6479) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6486 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6487 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6488 = "cute.get_scalars"(%6487) : (!cute.int_tuple<"2">) -> i32
        %6489 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6490 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6489, %6488, %6490) ({
        ^bb0(%arg98: i32):
          %6491 = "cute.make_coord"(%arg98) : (i32) -> !cute.coord<"(_,?)">
          %6492 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6493 = "cute.crd2idx"(%6491, %6483) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6494 = "cute.add_offset"(%6481, %6493) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6495 = "cute.make_view"(%6494, %6492) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6496 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6497 = "cute.crd2idx"(%6491, %6484) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6498 = "cute.add_offset"(%6482, %6497) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6499 = "cute.make_view"(%6498, %6496) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6500 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6501 = "cute.crd2idx"(%6491, %6486) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6502 = "cute.add_offset"(%6485, %6501) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6503 = "cute.make_view"(%6502, %6500) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6504 = "cute.get_iter"(%6495) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6505 = "cute.get_iter"(%6499) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6506 = "cute.get_iter"(%6503) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6507 = "builtin.unrealized_conversion_cast"(%6506) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6508 = "llvm.load"(%6507) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6509 = "llvm.trunc"(%6508) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6510 = "cute.recast_iter"(%6504) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6511 = "cute.recast_iter"(%6505) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6511, %6510, %6509) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6445 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %6446 = "cute.get_iter"(%322) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6447 = "cute.add_offset"(%6446, %6445) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6448 = "cute.make_view"(%6447) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6449 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6450 = "vector.splat"(%6449) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6450, %6448) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1030 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %1031 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1032 = "cute.add_offset"(%1031, %1030) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1033 = "cute.make_view"(%1032) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1034 = "cute.get_iter"(%1033) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1035 = "cute.deref_arith_tuple_iter"(%1034) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1036:4 = "cute.get_leaves"(%1035) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1037 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1038 = "cute.get_shape"(%1037) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1039:4 = "cute.get_leaves"(%1038) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1040 = "cute.to_int_tuple"(%1039#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1041 = "cute.make_coord"(%1036#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1042 = "cute.make_coord"(%1040) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1043 = "cute.get_scalars"(%1041) : (!cute.coord<"?">) -> i32
      %1044 = "cute.get_scalars"(%1042) : (!cute.coord<"?">) -> i32
      %1045 = "arith.constant"() <{value = true}> : () -> i1
      %1046 = "arith.cmpi"(%1043, %1044) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1047 = "arith.andi"(%1045, %1046) : (i1, i1) -> i1
      "scf.if"(%1047) ({
        %6384 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %6385 = "cute.get_layout"(%348) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %6386 = "cute.crd2idx"(%6384, %6385) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %6387 = "cute.get_iter"(%348) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %6388 = "cute.add_offset"(%6387, %6386) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6389 = "cute.make_view"(%6388) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6390 = "cute.get_iter"(%6389) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6391 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6392 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6393 = "cute.add_offset"(%6392, %6391) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6394 = "cute.make_view"(%6393) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6395 = "cute.get_iter"(%6394) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6396 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6397 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6398 = "cute.add_offset"(%6397, %6396) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6399 = "cute.make_view"(%6398) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6400 = "cute.get_iter"(%6399) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6401 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6402 = "cute.make_view"(%6390, %6401) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6403 = "cute.get_iter"(%6402) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6404 = "cute.make_view"(%6403) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6405 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6406 = "cute.make_view"(%6395, %6405) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6407 = "cute.get_iter"(%6406) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6408 = "cute.make_view"(%6407) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6409 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6410 = "cute.make_view"(%6400, %6409) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6411 = "cute.get_iter"(%6410) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6412 = "cute.make_view"(%6411) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6413 = "cute.static"() : () -> !cute.layout<"1:0">
        %6414 = "cute.get_iter"(%6404) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6415 = "cute.get_iter"(%6408) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6416 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6417 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6418 = "cute.get_iter"(%6412) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6419 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6420 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6421 = "cute.get_scalars"(%6420) : (!cute.int_tuple<"2">) -> i32
        %6422 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6423 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6422, %6421, %6423) ({
        ^bb0(%arg97: i32):
          %6424 = "cute.make_coord"(%arg97) : (i32) -> !cute.coord<"(_,?)">
          %6425 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6426 = "cute.crd2idx"(%6424, %6416) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6427 = "cute.add_offset"(%6414, %6426) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6428 = "cute.make_view"(%6427, %6425) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6429 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6430 = "cute.crd2idx"(%6424, %6417) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6431 = "cute.add_offset"(%6415, %6430) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6432 = "cute.make_view"(%6431, %6429) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6433 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6434 = "cute.crd2idx"(%6424, %6419) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6435 = "cute.add_offset"(%6418, %6434) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6436 = "cute.make_view"(%6435, %6433) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6437 = "cute.get_iter"(%6428) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6438 = "cute.get_iter"(%6432) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6439 = "cute.get_iter"(%6436) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6440 = "builtin.unrealized_conversion_cast"(%6439) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6441 = "llvm.load"(%6440) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6442 = "llvm.trunc"(%6441) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6443 = "cute.recast_iter"(%6437) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6444 = "cute.recast_iter"(%6438) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6444, %6443, %6442) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6378 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6379 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6380 = "cute.add_offset"(%6379, %6378) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6381 = "cute.make_view"(%6380) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6382 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6383 = "vector.splat"(%6382) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6383, %6381) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1048 = "cute.static"() : () -> !cute.int_tuple<"(0,16,0,0)">
      %1049 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1050 = "cute.add_offset"(%1049, %1048) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1051 = "cute.make_view"(%1050) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1052 = "cute.get_iter"(%1051) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1053 = "cute.deref_arith_tuple_iter"(%1052) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1054:4 = "cute.get_leaves"(%1053) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1055 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1056 = "cute.get_shape"(%1055) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1057:4 = "cute.get_leaves"(%1056) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1058 = "cute.to_int_tuple"(%1057#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1059 = "cute.make_coord"(%1054#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1060 = "cute.make_coord"(%1058) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1061 = "cute.get_scalars"(%1059) : (!cute.coord<"?">) -> i32
      %1062 = "cute.get_scalars"(%1060) : (!cute.coord<"?">) -> i32
      %1063 = "arith.constant"() <{value = true}> : () -> i1
      %1064 = "arith.cmpi"(%1061, %1062) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1065 = "arith.andi"(%1063, %1064) : (i1, i1) -> i1
      "scf.if"(%1065) ({
        %6317 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %6318 = "cute.get_layout"(%348) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %6319 = "cute.crd2idx"(%6317, %6318) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %6320 = "cute.get_iter"(%348) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %6321 = "cute.add_offset"(%6320, %6319) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6322 = "cute.make_view"(%6321) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6323 = "cute.get_iter"(%6322) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6324 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6325 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6326 = "cute.add_offset"(%6325, %6324) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6327 = "cute.make_view"(%6326) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6328 = "cute.get_iter"(%6327) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6329 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6330 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6331 = "cute.add_offset"(%6330, %6329) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6332 = "cute.make_view"(%6331) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6333 = "cute.get_iter"(%6332) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6334 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6335 = "cute.make_view"(%6323, %6334) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6336 = "cute.get_iter"(%6335) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6337 = "cute.make_view"(%6336) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6338 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6339 = "cute.make_view"(%6328, %6338) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6340 = "cute.get_iter"(%6339) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6341 = "cute.make_view"(%6340) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6342 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6343 = "cute.make_view"(%6333, %6342) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6344 = "cute.get_iter"(%6343) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6345 = "cute.make_view"(%6344) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6346 = "cute.static"() : () -> !cute.layout<"1:0">
        %6347 = "cute.get_iter"(%6337) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6348 = "cute.get_iter"(%6341) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6349 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6350 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6351 = "cute.get_iter"(%6345) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6352 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6353 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6354 = "cute.get_scalars"(%6353) : (!cute.int_tuple<"2">) -> i32
        %6355 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6356 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6355, %6354, %6356) ({
        ^bb0(%arg96: i32):
          %6357 = "cute.make_coord"(%arg96) : (i32) -> !cute.coord<"(_,?)">
          %6358 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6359 = "cute.crd2idx"(%6357, %6349) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6360 = "cute.add_offset"(%6347, %6359) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6361 = "cute.make_view"(%6360, %6358) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6362 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6363 = "cute.crd2idx"(%6357, %6350) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6364 = "cute.add_offset"(%6348, %6363) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6365 = "cute.make_view"(%6364, %6362) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6366 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6367 = "cute.crd2idx"(%6357, %6352) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6368 = "cute.add_offset"(%6351, %6367) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6369 = "cute.make_view"(%6368, %6366) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6370 = "cute.get_iter"(%6361) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6371 = "cute.get_iter"(%6365) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6372 = "cute.get_iter"(%6369) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6373 = "builtin.unrealized_conversion_cast"(%6372) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6374 = "llvm.load"(%6373) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6375 = "llvm.trunc"(%6374) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6376 = "cute.recast_iter"(%6370) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6377 = "cute.recast_iter"(%6371) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6377, %6376, %6375) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6311 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6312 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6313 = "cute.add_offset"(%6312, %6311) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6314 = "cute.make_view"(%6313) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6315 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6316 = "vector.splat"(%6315) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6316, %6314) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1066 = "cute.static"() : () -> !cute.int_tuple<"(0,32,0,0)">
      %1067 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1068 = "cute.add_offset"(%1067, %1066) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1069 = "cute.make_view"(%1068) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1070 = "cute.get_iter"(%1069) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1071 = "cute.deref_arith_tuple_iter"(%1070) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1072:4 = "cute.get_leaves"(%1071) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1073 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1074 = "cute.get_shape"(%1073) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1075:4 = "cute.get_leaves"(%1074) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1076 = "cute.to_int_tuple"(%1075#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1077 = "cute.make_coord"(%1072#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1078 = "cute.make_coord"(%1076) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1079 = "cute.get_scalars"(%1077) : (!cute.coord<"?">) -> i32
      %1080 = "cute.get_scalars"(%1078) : (!cute.coord<"?">) -> i32
      %1081 = "arith.constant"() <{value = true}> : () -> i1
      %1082 = "arith.cmpi"(%1079, %1080) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1083 = "arith.andi"(%1081, %1082) : (i1, i1) -> i1
      "scf.if"(%1083) ({
        %6250 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %6251 = "cute.get_layout"(%348) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %6252 = "cute.crd2idx"(%6250, %6251) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
        %6253 = "cute.get_iter"(%348) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %6254 = "cute.add_offset"(%6253, %6252) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6255 = "cute.make_view"(%6254) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6256 = "cute.get_iter"(%6255) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6257 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6258 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6259 = "cute.add_offset"(%6258, %6257) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6260 = "cute.make_view"(%6259) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6261 = "cute.get_iter"(%6260) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6262 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6263 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6264 = "cute.add_offset"(%6263, %6262) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6265 = "cute.make_view"(%6264) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6266 = "cute.get_iter"(%6265) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6267 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6268 = "cute.make_view"(%6256, %6267) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6269 = "cute.get_iter"(%6268) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6270 = "cute.make_view"(%6269) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6271 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6272 = "cute.make_view"(%6261, %6271) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6273 = "cute.get_iter"(%6272) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6274 = "cute.make_view"(%6273) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6275 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6276 = "cute.make_view"(%6266, %6275) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6277 = "cute.get_iter"(%6276) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6278 = "cute.make_view"(%6277) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6279 = "cute.static"() : () -> !cute.layout<"1:0">
        %6280 = "cute.get_iter"(%6270) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6281 = "cute.get_iter"(%6274) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6282 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6283 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6284 = "cute.get_iter"(%6278) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6285 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6286 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6287 = "cute.get_scalars"(%6286) : (!cute.int_tuple<"2">) -> i32
        %6288 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6289 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6288, %6287, %6289) ({
        ^bb0(%arg95: i32):
          %6290 = "cute.make_coord"(%arg95) : (i32) -> !cute.coord<"(_,?)">
          %6291 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6292 = "cute.crd2idx"(%6290, %6282) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6293 = "cute.add_offset"(%6280, %6292) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6294 = "cute.make_view"(%6293, %6291) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6295 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6296 = "cute.crd2idx"(%6290, %6283) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6297 = "cute.add_offset"(%6281, %6296) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6298 = "cute.make_view"(%6297, %6295) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6299 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6300 = "cute.crd2idx"(%6290, %6285) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6301 = "cute.add_offset"(%6284, %6300) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6302 = "cute.make_view"(%6301, %6299) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6303 = "cute.get_iter"(%6294) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6304 = "cute.get_iter"(%6298) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6305 = "cute.get_iter"(%6302) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6306 = "builtin.unrealized_conversion_cast"(%6305) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6307 = "llvm.load"(%6306) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6308 = "llvm.trunc"(%6307) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6309 = "cute.recast_iter"(%6303) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6310 = "cute.recast_iter"(%6304) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6310, %6309, %6308) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6244 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6245 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6246 = "cute.add_offset"(%6245, %6244) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6247 = "cute.make_view"(%6246) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6248 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6249 = "vector.splat"(%6248) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6249, %6247) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1084 = "cute.static"() : () -> !cute.int_tuple<"(0,48,0,0)">
      %1085 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1086 = "cute.add_offset"(%1085, %1084) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1087 = "cute.make_view"(%1086) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1088 = "cute.get_iter"(%1087) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1089 = "cute.deref_arith_tuple_iter"(%1088) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1090:4 = "cute.get_leaves"(%1089) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1091 = "cute.get_layout"(%arg7) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1092 = "cute.get_shape"(%1091) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1093:4 = "cute.get_leaves"(%1092) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1094 = "cute.to_int_tuple"(%1093#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1095 = "cute.make_coord"(%1090#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1096 = "cute.make_coord"(%1094) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1097 = "cute.get_scalars"(%1095) : (!cute.coord<"?">) -> i32
      %1098 = "cute.get_scalars"(%1096) : (!cute.coord<"?">) -> i32
      %1099 = "arith.constant"() <{value = true}> : () -> i1
      %1100 = "arith.cmpi"(%1097, %1098) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1101 = "arith.andi"(%1099, %1100) : (i1, i1) -> i1
      "scf.if"(%1101) ({
        %6183 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %6184 = "cute.get_layout"(%348) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
        %6185 = "cute.crd2idx"(%6183, %6184) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %6186 = "cute.get_iter"(%348) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
        %6187 = "cute.add_offset"(%6186, %6185) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6188 = "cute.make_view"(%6187) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %6189 = "cute.get_iter"(%6188) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6190 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %6191 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6192 = "cute.add_offset"(%6191, %6190) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6193 = "cute.make_view"(%6192) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6194 = "cute.get_iter"(%6193) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6195 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6196 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %6197 = "cute.add_offset"(%6196, %6195) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %6198 = "cute.make_view"(%6197) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %6199 = "cute.get_iter"(%6198) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6200 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %6201 = "cute.make_view"(%6189, %6200) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %6202 = "cute.get_iter"(%6201) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %6203 = "cute.make_view"(%6202) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %6204 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
        %6205 = "cute.make_view"(%6194, %6204) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
        %6206 = "cute.get_iter"(%6205) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
        %6207 = "cute.make_view"(%6206) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
        %6208 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %6209 = "cute.make_view"(%6199, %6208) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %6210 = "cute.get_iter"(%6209) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %6211 = "cute.make_view"(%6210) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %6212 = "cute.static"() : () -> !cute.layout<"1:0">
        %6213 = "cute.get_iter"(%6203) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %6214 = "cute.get_iter"(%6207) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
        %6215 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %6216 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
        %6217 = "cute.get_iter"(%6211) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %6218 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %6219 = "cute.static"() : () -> !cute.int_tuple<"2">
        %6220 = "cute.get_scalars"(%6219) : (!cute.int_tuple<"2">) -> i32
        %6221 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6222 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6221, %6220, %6222) ({
        ^bb0(%arg94: i32):
          %6223 = "cute.make_coord"(%arg94) : (i32) -> !cute.coord<"(_,?)">
          %6224 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6225 = "cute.crd2idx"(%6223, %6215) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %6226 = "cute.add_offset"(%6213, %6225) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %6227 = "cute.make_view"(%6226, %6224) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6228 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6229 = "cute.crd2idx"(%6223, %6216) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %6230 = "cute.add_offset"(%6214, %6229) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %6231 = "cute.make_view"(%6230, %6228) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6232 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %6233 = "cute.crd2idx"(%6223, %6218) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %6234 = "cute.add_offset"(%6217, %6233) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %6235 = "cute.make_view"(%6234, %6232) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %6236 = "cute.get_iter"(%6227) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6237 = "cute.get_iter"(%6231) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6238 = "cute.get_iter"(%6235) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %6239 = "builtin.unrealized_conversion_cast"(%6238) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %6240 = "llvm.load"(%6239) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %6241 = "llvm.trunc"(%6240) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
          %6242 = "cute.recast_iter"(%6236) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6243 = "cute.recast_iter"(%6237) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6243, %6242, %6241) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6177 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %6178 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
        %6179 = "cute.add_offset"(%6178, %6177) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6180 = "cute.make_view"(%6179) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
        %6181 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6182 = "vector.splat"(%6181) : (bf16) -> vector<16xbf16>
        "cute.memref.store_vec"(%6182, %6180) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1102 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %1103 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1104 = "cute.crd2idx"(%1102, %1103) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %1105 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1106 = "cute.add_offset"(%1105, %1104) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1107 = "cute.make_view"(%1106) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1108 = "cute.get_iter"(%1107) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1109 = "cute.deref_arith_tuple_iter"(%1108) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1110:4 = "cute.get_leaves"(%1109) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1111 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1112 = "cute.get_shape"(%1111) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1113:4 = "cute.get_leaves"(%1112) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1114 = "cute.to_int_tuple"(%1113#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1115 = "cute.make_coord"(%1110#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1116 = "cute.make_coord"(%1114) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1117 = "cute.get_scalars"(%1115) : (!cute.coord<"?">) -> i32
      %1118 = "cute.get_scalars"(%1116) : (!cute.coord<"?">) -> i32
      %1119 = "arith.constant"() <{value = true}> : () -> i1
      %1120 = "arith.cmpi"(%1117, %1118) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1121 = "arith.andi"(%1119, %1120) : (i1, i1) -> i1
      %1122 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %1123 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1124 = "cute.crd2idx"(%1122, %1123) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %1125 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1126 = "cute.add_offset"(%1125, %1124) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1127 = "cute.make_view"(%1126) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1128 = "cute.get_iter"(%1127) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1129 = "cute.deref_arith_tuple_iter"(%1128) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1130:4 = "cute.get_leaves"(%1129) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1131 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1132 = "cute.get_shape"(%1131) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1133:4 = "cute.get_leaves"(%1132) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1134 = "cute.to_int_tuple"(%1133#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1135 = "cute.make_coord"(%1130#2) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1136 = "cute.make_coord"(%1134) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1137 = "cute.get_scalars"(%1135) : (!cute.coord<"?">) -> i32
      %1138 = "cute.get_scalars"(%1136) : (!cute.coord<"?{div=8}">) -> i32
      %1139 = "arith.constant"() <{value = true}> : () -> i1
      %1140 = "arith.cmpi"(%1137, %1138) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1141 = "arith.andi"(%1139, %1140) : (i1, i1) -> i1
      %1142 = "arith.extui"(%1121) : (i1) -> i32
      %1143 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1144 = "arith.cmpi"(%1142, %1143) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %1145 = "arith.extui"(%1121) : (i1) -> i32
      %1146 = "arith.extui"(%1141) : (i1) -> i32
      %1147 = "arith.select"(%1144, %1146, %1145) : (i1, i32, i32) -> i32
      %1148 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1149 = "arith.cmpi"(%1147, %1148) <{predicate = 1 : i64}> : (i32, i32) -> i1
      "scf.if"(%1149) ({
        %6138 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %6139 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
        %6140 = "cute.crd2idx"(%6138, %6139) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
        %6141 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %6142 = "cute.add_offset"(%6141, %6140) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6143 = "cute.make_view"(%6142) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_10
        %6144 = "cute.get_iter"(%6143) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
        %6145 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6146 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6147 = "cute.add_offset"(%6146, %6145) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6148 = "cute.make_view"(%6147) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6149 = "cute.get_iter"(%6148) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
        %6150 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6151 = "cute.make_view"(%6144, %6150) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
        %6152 = "cute.get_iter"(%6151) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
        %6153 = "cute.make_view"(%6152) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
        %6154 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6155 = "cute.make_view"(%6149, %6154) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
        %6156 = "cute.get_iter"(%6155) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %6157 = "cute.make_view"(%6156) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
        %6158 = "cute.static"() : () -> !cute.layout<"1:0">
        %6159 = "cute.get_iter"(%6153) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
        %6160 = "cute.get_iter"(%6157) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
        %6161 = "cute.static"() : () -> !cute.int_tuple<"1">
        %6162 = "cute.get_scalars"(%6161) : (!cute.int_tuple<"1">) -> i32
        %6163 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6164 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6163, %6162, %6164) ({
        ^bb0(%arg93: i32):
          %6165 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6166 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6167 = "cute.add_offset"(%6159, %6166) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %6168 = "cute.make_view"(%6167, %6165) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6169 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6170 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6171 = "cute.add_offset"(%6160, %6170) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %6172 = "cute.make_view"(%6171, %6169) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6173 = "cute.get_iter"(%6168) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6174 = "cute.get_iter"(%6172) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6175 = "cute.recast_iter"(%6173) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6176 = "cute.recast_iter"(%6174) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6176, %6175) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6132 = "cute.static"() : () -> !cute.int_tuple<"0">
        %6133 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6134 = "cute.add_offset"(%6133, %6132) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %6135 = "cute.make_view"(%6134) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6136 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6137 = "vector.splat"(%6136) : (bf16) -> vector<8xbf16>
        "cute.memref.store_vec"(%6137, %6135) : (vector<8xbf16>, !memref_smem_bf16_11) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1150 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %1151 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1152 = "cute.crd2idx"(%1150, %1151) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %1153 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1154 = "cute.add_offset"(%1153, %1152) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1155 = "cute.make_view"(%1154) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1156 = "cute.get_iter"(%1155) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1157 = "cute.deref_arith_tuple_iter"(%1156) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1158:4 = "cute.get_leaves"(%1157) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1159 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1160 = "cute.get_shape"(%1159) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1161:4 = "cute.get_leaves"(%1160) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1162 = "cute.to_int_tuple"(%1161#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1163 = "cute.make_coord"(%1158#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1164 = "cute.make_coord"(%1162) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1165 = "cute.get_scalars"(%1163) : (!cute.coord<"?">) -> i32
      %1166 = "cute.get_scalars"(%1164) : (!cute.coord<"?">) -> i32
      %1167 = "arith.constant"() <{value = true}> : () -> i1
      %1168 = "arith.cmpi"(%1165, %1166) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1169 = "arith.andi"(%1167, %1168) : (i1, i1) -> i1
      %1170 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %1171 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1172 = "cute.crd2idx"(%1170, %1171) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %1173 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1174 = "cute.add_offset"(%1173, %1172) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1175 = "cute.make_view"(%1174) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1176 = "cute.get_iter"(%1175) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1177 = "cute.deref_arith_tuple_iter"(%1176) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1178:4 = "cute.get_leaves"(%1177) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1179 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1180 = "cute.get_shape"(%1179) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1181:4 = "cute.get_leaves"(%1180) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1182 = "cute.to_int_tuple"(%1181#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1183 = "cute.make_coord"(%1178#2) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1184 = "cute.make_coord"(%1182) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1185 = "cute.get_scalars"(%1183) : (!cute.coord<"?">) -> i32
      %1186 = "cute.get_scalars"(%1184) : (!cute.coord<"?{div=8}">) -> i32
      %1187 = "arith.constant"() <{value = true}> : () -> i1
      %1188 = "arith.cmpi"(%1185, %1186) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1189 = "arith.andi"(%1187, %1188) : (i1, i1) -> i1
      %1190 = "arith.extui"(%1169) : (i1) -> i32
      %1191 = "arith.cmpi"(%1190, %1143) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %1192 = "arith.extui"(%1169) : (i1) -> i32
      %1193 = "arith.extui"(%1189) : (i1) -> i32
      %1194 = "arith.select"(%1191, %1193, %1192) : (i1, i32, i32) -> i32
      %1195 = "arith.cmpi"(%1194, %1148) <{predicate = 1 : i64}> : (i32, i32) -> i1
      "scf.if"(%1195) ({
        %6093 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %6094 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
        %6095 = "cute.crd2idx"(%6093, %6094) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %6096 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %6097 = "cute.add_offset"(%6096, %6095) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6098 = "cute.make_view"(%6097) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_10
        %6099 = "cute.get_iter"(%6098) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
        %6100 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6101 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6102 = "cute.add_offset"(%6101, %6100) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6103 = "cute.make_view"(%6102) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6104 = "cute.get_iter"(%6103) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
        %6105 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6106 = "cute.make_view"(%6099, %6105) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
        %6107 = "cute.get_iter"(%6106) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
        %6108 = "cute.make_view"(%6107) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
        %6109 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6110 = "cute.make_view"(%6104, %6109) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
        %6111 = "cute.get_iter"(%6110) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %6112 = "cute.make_view"(%6111) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
        %6113 = "cute.static"() : () -> !cute.layout<"1:0">
        %6114 = "cute.get_iter"(%6108) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
        %6115 = "cute.get_iter"(%6112) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
        %6116 = "cute.static"() : () -> !cute.int_tuple<"1">
        %6117 = "cute.get_scalars"(%6116) : (!cute.int_tuple<"1">) -> i32
        %6118 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6119 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6118, %6117, %6119) ({
        ^bb0(%arg92: i32):
          %6120 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6121 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6122 = "cute.add_offset"(%6114, %6121) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %6123 = "cute.make_view"(%6122, %6120) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6124 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6125 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6126 = "cute.add_offset"(%6115, %6125) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %6127 = "cute.make_view"(%6126, %6124) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6128 = "cute.get_iter"(%6123) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6129 = "cute.get_iter"(%6127) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6130 = "cute.recast_iter"(%6128) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6131 = "cute.recast_iter"(%6129) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6131, %6130) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6087 = "cute.static"() : () -> !cute.int_tuple<"1024">
        %6088 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6089 = "cute.add_offset"(%6088, %6087) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %6090 = "cute.make_view"(%6089) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6091 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6092 = "vector.splat"(%6091) : (bf16) -> vector<8xbf16>
        "cute.memref.store_vec"(%6092, %6090) : (vector<8xbf16>, !memref_smem_bf16_11) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1196 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %1197 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1198 = "cute.crd2idx"(%1196, %1197) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %1199 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1200 = "cute.add_offset"(%1199, %1198) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1201 = "cute.make_view"(%1200) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1202 = "cute.get_iter"(%1201) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1203 = "cute.deref_arith_tuple_iter"(%1202) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1204:4 = "cute.get_leaves"(%1203) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1205 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1206 = "cute.get_shape"(%1205) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1207:4 = "cute.get_leaves"(%1206) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1208 = "cute.to_int_tuple"(%1207#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1209 = "cute.make_coord"(%1204#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1210 = "cute.make_coord"(%1208) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1211 = "cute.get_scalars"(%1209) : (!cute.coord<"?">) -> i32
      %1212 = "cute.get_scalars"(%1210) : (!cute.coord<"?">) -> i32
      %1213 = "arith.constant"() <{value = true}> : () -> i1
      %1214 = "arith.cmpi"(%1211, %1212) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1215 = "arith.andi"(%1213, %1214) : (i1, i1) -> i1
      %1216 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %1217 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1218 = "cute.crd2idx"(%1216, %1217) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %1219 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1220 = "cute.add_offset"(%1219, %1218) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1221 = "cute.make_view"(%1220) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1222 = "cute.get_iter"(%1221) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1223 = "cute.deref_arith_tuple_iter"(%1222) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1224:4 = "cute.get_leaves"(%1223) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1225 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1226 = "cute.get_shape"(%1225) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1227:4 = "cute.get_leaves"(%1226) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1228 = "cute.to_int_tuple"(%1227#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1229 = "cute.make_coord"(%1224#2) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1230 = "cute.make_coord"(%1228) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1231 = "cute.get_scalars"(%1229) : (!cute.coord<"?">) -> i32
      %1232 = "cute.get_scalars"(%1230) : (!cute.coord<"?{div=8}">) -> i32
      %1233 = "arith.constant"() <{value = true}> : () -> i1
      %1234 = "arith.cmpi"(%1231, %1232) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1235 = "arith.andi"(%1233, %1234) : (i1, i1) -> i1
      %1236 = "arith.extui"(%1215) : (i1) -> i32
      %1237 = "arith.cmpi"(%1236, %1143) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %1238 = "arith.extui"(%1215) : (i1) -> i32
      %1239 = "arith.extui"(%1235) : (i1) -> i32
      %1240 = "arith.select"(%1237, %1239, %1238) : (i1, i32, i32) -> i32
      %1241 = "arith.cmpi"(%1240, %1148) <{predicate = 1 : i64}> : (i32, i32) -> i1
      "scf.if"(%1241) ({
        %6048 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %6049 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
        %6050 = "cute.crd2idx"(%6048, %6049) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %6051 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %6052 = "cute.add_offset"(%6051, %6050) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6053 = "cute.make_view"(%6052) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_10
        %6054 = "cute.get_iter"(%6053) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
        %6055 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6056 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6057 = "cute.add_offset"(%6056, %6055) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6058 = "cute.make_view"(%6057) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6059 = "cute.get_iter"(%6058) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
        %6060 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6061 = "cute.make_view"(%6054, %6060) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
        %6062 = "cute.get_iter"(%6061) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
        %6063 = "cute.make_view"(%6062) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
        %6064 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6065 = "cute.make_view"(%6059, %6064) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
        %6066 = "cute.get_iter"(%6065) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %6067 = "cute.make_view"(%6066) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
        %6068 = "cute.static"() : () -> !cute.layout<"1:0">
        %6069 = "cute.get_iter"(%6063) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
        %6070 = "cute.get_iter"(%6067) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
        %6071 = "cute.static"() : () -> !cute.int_tuple<"1">
        %6072 = "cute.get_scalars"(%6071) : (!cute.int_tuple<"1">) -> i32
        %6073 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6074 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6073, %6072, %6074) ({
        ^bb0(%arg91: i32):
          %6075 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6076 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6077 = "cute.add_offset"(%6069, %6076) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %6078 = "cute.make_view"(%6077, %6075) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6079 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6080 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6081 = "cute.add_offset"(%6070, %6080) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %6082 = "cute.make_view"(%6081, %6079) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6083 = "cute.get_iter"(%6078) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6084 = "cute.get_iter"(%6082) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6085 = "cute.recast_iter"(%6083) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6086 = "cute.recast_iter"(%6084) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6086, %6085) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %6042 = "cute.static"() : () -> !cute.int_tuple<"2048">
        %6043 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6044 = "cute.add_offset"(%6043, %6042) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %6045 = "cute.make_view"(%6044) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6046 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6047 = "vector.splat"(%6046) : (bf16) -> vector<8xbf16>
        "cute.memref.store_vec"(%6047, %6045) : (vector<8xbf16>, !memref_smem_bf16_11) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      %1242 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %1243 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1244 = "cute.crd2idx"(%1242, %1243) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %1245 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1246 = "cute.add_offset"(%1245, %1244) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1247 = "cute.make_view"(%1246) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1248 = "cute.get_iter"(%1247) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1249 = "cute.deref_arith_tuple_iter"(%1248) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1250:4 = "cute.get_leaves"(%1249) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1251 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1252 = "cute.get_shape"(%1251) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1253:4 = "cute.get_leaves"(%1252) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1254 = "cute.to_int_tuple"(%1253#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1255 = "cute.make_coord"(%1250#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1256 = "cute.make_coord"(%1254) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1257 = "cute.get_scalars"(%1255) : (!cute.coord<"?">) -> i32
      %1258 = "cute.get_scalars"(%1256) : (!cute.coord<"?">) -> i32
      %1259 = "arith.constant"() <{value = true}> : () -> i1
      %1260 = "arith.cmpi"(%1257, %1258) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1261 = "arith.andi"(%1259, %1260) : (i1, i1) -> i1
      %1262 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %1263 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %1264 = "cute.crd2idx"(%1262, %1263) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %1265 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1266 = "cute.add_offset"(%1265, %1264) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1267 = "cute.make_view"(%1266) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1268 = "cute.get_iter"(%1267) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1269 = "cute.deref_arith_tuple_iter"(%1268) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1270:4 = "cute.get_leaves"(%1269) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1271 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1272 = "cute.get_shape"(%1271) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1273:4 = "cute.get_leaves"(%1272) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1274 = "cute.to_int_tuple"(%1273#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1275 = "cute.make_coord"(%1270#2) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1276 = "cute.make_coord"(%1274) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1277 = "cute.get_scalars"(%1275) : (!cute.coord<"?">) -> i32
      %1278 = "cute.get_scalars"(%1276) : (!cute.coord<"?{div=8}">) -> i32
      %1279 = "arith.constant"() <{value = true}> : () -> i1
      %1280 = "arith.cmpi"(%1277, %1278) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1281 = "arith.andi"(%1279, %1280) : (i1, i1) -> i1
      %1282 = "arith.extui"(%1261) : (i1) -> i32
      %1283 = "arith.cmpi"(%1282, %1143) <{predicate = 1 : i64}> : (i32, i32) -> i1
      %1284 = "arith.extui"(%1261) : (i1) -> i32
      %1285 = "arith.extui"(%1281) : (i1) -> i32
      %1286 = "arith.select"(%1283, %1285, %1284) : (i1, i32, i32) -> i32
      %1287 = "arith.cmpi"(%1286, %1148) <{predicate = 1 : i64}> : (i32, i32) -> i1
      "scf.if"(%1287) ({
        %6003 = "cute.make_coord"(%100) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %6004 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
        %6005 = "cute.crd2idx"(%6003, %6004) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %6006 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
        %6007 = "cute.add_offset"(%6006, %6005) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %6008 = "cute.make_view"(%6007) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_10
        %6009 = "cute.get_iter"(%6008) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
        %6010 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %6011 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %6012 = "cute.add_offset"(%6011, %6010) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6013 = "cute.make_view"(%6012) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6014 = "cute.get_iter"(%6013) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
        %6015 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6016 = "cute.make_view"(%6009, %6015) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
        %6017 = "cute.get_iter"(%6016) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
        %6018 = "cute.make_view"(%6017) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
        %6019 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %6020 = "cute.make_view"(%6014, %6019) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
        %6021 = "cute.get_iter"(%6020) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %6022 = "cute.make_view"(%6021) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
        %6023 = "cute.static"() : () -> !cute.layout<"1:0">
        %6024 = "cute.get_iter"(%6018) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
        %6025 = "cute.get_iter"(%6022) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
        %6026 = "cute.static"() : () -> !cute.int_tuple<"1">
        %6027 = "cute.get_scalars"(%6026) : (!cute.int_tuple<"1">) -> i32
        %6028 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %6029 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%6028, %6027, %6029) ({
        ^bb0(%arg90: i32):
          %6030 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6031 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6032 = "cute.add_offset"(%6024, %6031) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %6033 = "cute.make_view"(%6032, %6030) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %6034 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %6035 = "cute.static"() : () -> !cute.int_tuple<"0">
          %6036 = "cute.add_offset"(%6025, %6035) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %6037 = "cute.make_view"(%6036, %6034) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %6038 = "cute.get_iter"(%6033) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %6039 = "cute.get_iter"(%6037) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %6040 = "cute.recast_iter"(%6038) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
          %6041 = "cute.recast_iter"(%6039) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
          "cute_nvgpu.arch.copy.SM80.cp_async"(%6041, %6040) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
        %5997 = "cute.static"() : () -> !cute.int_tuple<"3072">
        %5998 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
        %5999 = "cute.add_offset"(%5998, %5997) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %6000 = "cute.make_view"(%5999) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_11
        %6001 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
        %6002 = "vector.splat"(%6001) : (bf16) -> vector<8xbf16>
        "cute.memref.store_vec"(%6002, %6000) : (vector<8xbf16>, !memref_smem_bf16_11) -> ()
        "scf.yield"() : () -> ()
      }) : (i1) -> ()
      "nvvm.cp.async.commit.group"() : () -> ()
      %1288 = "cute.static"() : () -> !cute.int_tuple<"-1">
      %1289 = "cute.tuple_add"(%100, %1288) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %1290 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %1291 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %1292:2 = "scf.for"(%1290, %101, %1291, %53, %523) ({
      ^bb0(%arg17: i32, %arg18: !mma_bf16_bf16_f32_16x8x16_, %arg19: !copy_ldsm_4_3):
        %1920 = "cute.make_int_tuple"(%arg17) : (i32) -> !cute.int_tuple<"?">
        %1921 = "cute.tuple_sub"(%1289, %1920) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %1922 = "cute.get_scalars"(%1921) : (!cute.int_tuple<"?">) -> i32
        "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
        %1923 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %1924 = "arith.constant"() <{value = 128 : i32}> : () -> i32
        "llvm.inline_asm"(%1923, %1924) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
        %1925 = "arith.cmpi"(%1922, %101) <{predicate = 0 : i64}> : (i32, i32) -> i1
        "scf.if"(%1925) ({
          %5657 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
          %5658 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5659 = "cute.add_offset"(%5658, %5657) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5660 = "cute.make_view"(%5659) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %5661 = "cute.get_iter"(%5660) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5662 = "cute.deref_arith_tuple_iter"(%5661) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %5663:4 = "cute.get_leaves"(%5662) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %5664 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %5665 = "cute.get_shape"(%5664) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %5666:4 = "cute.get_leaves"(%5665) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %5667 = "cute.to_int_tuple"(%5666#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %5668 = "cute.make_coord"(%5663#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5669 = "cute.make_coord"(%5667) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5670 = "cute.get_scalars"(%5668) : (!cute.coord<"?">) -> i32
          %5671 = "cute.get_scalars"(%5669) : (!cute.coord<"?">) -> i32
          %5672 = "arith.constant"() <{value = true}> : () -> i1
          %5673 = "arith.cmpi"(%5670, %5671) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %5674 = "arith.andi"(%5672, %5673) : (i1, i1) -> i1
          "scf.if"(%5674) ({
            %5936 = "cute.make_coord"(%1921) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %5937 = "cute.get_layout"(%406) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
            %5938 = "cute.crd2idx"(%5936, %5937) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
            %5939 = "cute.get_iter"(%406) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
            %5940 = "cute.add_offset"(%5939, %5938) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
            %5941 = "cute.make_view"(%5940) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
            %5942 = "cute.get_iter"(%5941) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5943 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5944 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5945 = "cute.add_offset"(%5944, %5943) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %5946 = "cute.make_view"(%5945) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5947 = "cute.get_iter"(%5946) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5948 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5949 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
            %5950 = "cute.add_offset"(%5949, %5948) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %5951 = "cute.make_view"(%5950) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
            %5952 = "cute.get_iter"(%5951) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5953 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
            %5954 = "cute.make_view"(%5942, %5953) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
            %5955 = "cute.get_iter"(%5954) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5956 = "cute.make_view"(%5955) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
            %5957 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
            %5958 = "cute.make_view"(%5947, %5957) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
            %5959 = "cute.get_iter"(%5958) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5960 = "cute.make_view"(%5959) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
            %5961 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
            %5962 = "cute.make_view"(%5952, %5961) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
            %5963 = "cute.get_iter"(%5962) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5964 = "cute.make_view"(%5963) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
            %5965 = "cute.static"() : () -> !cute.layout<"1:0">
            %5966 = "cute.get_iter"(%5956) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
            %5967 = "cute.get_iter"(%5960) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
            %5968 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %5969 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %5970 = "cute.get_iter"(%5964) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
            %5971 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
            %5972 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5973 = "cute.get_scalars"(%5972) : (!cute.int_tuple<"2">) -> i32
            %5974 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %5975 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%5974, %5973, %5975) ({
            ^bb0(%arg89: i32):
              %5976 = "cute.make_coord"(%arg89) : (i32) -> !cute.coord<"(_,?)">
              %5977 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5978 = "cute.crd2idx"(%5976, %5968) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %5979 = "cute.add_offset"(%5966, %5978) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %5980 = "cute.make_view"(%5979, %5977) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %5981 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5982 = "cute.crd2idx"(%5976, %5969) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %5983 = "cute.add_offset"(%5967, %5982) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %5984 = "cute.make_view"(%5983, %5981) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %5985 = "cute.static"() : () -> !cute.layout<"(1):(2)">
              %5986 = "cute.crd2idx"(%5976, %5971) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %5987 = "cute.add_offset"(%5970, %5986) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %5988 = "cute.make_view"(%5987, %5985) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
              %5989 = "cute.get_iter"(%5980) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %5990 = "cute.get_iter"(%5984) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %5991 = "cute.get_iter"(%5988) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
              %5992 = "builtin.unrealized_conversion_cast"(%5991) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %5993 = "llvm.load"(%5992) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %5994 = "llvm.trunc"(%5993) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %5995 = "cute.recast_iter"(%5989) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %5996 = "cute.recast_iter"(%5990) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%5996, %5995, %5994) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %5930 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5931 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5932 = "cute.add_offset"(%5931, %5930) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %5933 = "cute.make_view"(%5932) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5934 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %5935 = "vector.splat"(%5934) : (bf16) -> vector<16xbf16>
            "cute.memref.store_vec"(%5935, %5933) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %5675 = "cute.static"() : () -> !cute.int_tuple<"(0,16,0,0)">
          %5676 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5677 = "cute.add_offset"(%5676, %5675) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5678 = "cute.make_view"(%5677) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %5679 = "cute.get_iter"(%5678) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5680 = "cute.deref_arith_tuple_iter"(%5679) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %5681:4 = "cute.get_leaves"(%5680) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %5682 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %5683 = "cute.get_shape"(%5682) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %5684:4 = "cute.get_leaves"(%5683) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %5685 = "cute.to_int_tuple"(%5684#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %5686 = "cute.make_coord"(%5681#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5687 = "cute.make_coord"(%5685) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5688 = "cute.get_scalars"(%5686) : (!cute.coord<"?">) -> i32
          %5689 = "cute.get_scalars"(%5687) : (!cute.coord<"?">) -> i32
          %5690 = "arith.constant"() <{value = true}> : () -> i1
          %5691 = "arith.cmpi"(%5688, %5689) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %5692 = "arith.andi"(%5690, %5691) : (i1, i1) -> i1
          "scf.if"(%5692) ({
            %5869 = "cute.make_coord"(%1921) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %5870 = "cute.get_layout"(%406) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
            %5871 = "cute.crd2idx"(%5869, %5870) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %5872 = "cute.get_iter"(%406) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
            %5873 = "cute.add_offset"(%5872, %5871) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %5874 = "cute.make_view"(%5873) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
            %5875 = "cute.get_iter"(%5874) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5876 = "cute.static"() : () -> !cute.int_tuple<"1024">
            %5877 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5878 = "cute.add_offset"(%5877, %5876) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %5879 = "cute.make_view"(%5878) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5880 = "cute.get_iter"(%5879) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5881 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5882 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
            %5883 = "cute.add_offset"(%5882, %5881) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %5884 = "cute.make_view"(%5883) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
            %5885 = "cute.get_iter"(%5884) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5886 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
            %5887 = "cute.make_view"(%5875, %5886) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
            %5888 = "cute.get_iter"(%5887) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5889 = "cute.make_view"(%5888) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
            %5890 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
            %5891 = "cute.make_view"(%5880, %5890) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
            %5892 = "cute.get_iter"(%5891) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5893 = "cute.make_view"(%5892) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
            %5894 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
            %5895 = "cute.make_view"(%5885, %5894) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
            %5896 = "cute.get_iter"(%5895) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5897 = "cute.make_view"(%5896) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
            %5898 = "cute.static"() : () -> !cute.layout<"1:0">
            %5899 = "cute.get_iter"(%5889) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
            %5900 = "cute.get_iter"(%5893) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
            %5901 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %5902 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %5903 = "cute.get_iter"(%5897) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
            %5904 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
            %5905 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5906 = "cute.get_scalars"(%5905) : (!cute.int_tuple<"2">) -> i32
            %5907 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %5908 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%5907, %5906, %5908) ({
            ^bb0(%arg88: i32):
              %5909 = "cute.make_coord"(%arg88) : (i32) -> !cute.coord<"(_,?)">
              %5910 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5911 = "cute.crd2idx"(%5909, %5901) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %5912 = "cute.add_offset"(%5899, %5911) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %5913 = "cute.make_view"(%5912, %5910) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %5914 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5915 = "cute.crd2idx"(%5909, %5902) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %5916 = "cute.add_offset"(%5900, %5915) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %5917 = "cute.make_view"(%5916, %5914) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %5918 = "cute.static"() : () -> !cute.layout<"(1):(2)">
              %5919 = "cute.crd2idx"(%5909, %5904) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %5920 = "cute.add_offset"(%5903, %5919) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %5921 = "cute.make_view"(%5920, %5918) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
              %5922 = "cute.get_iter"(%5913) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %5923 = "cute.get_iter"(%5917) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %5924 = "cute.get_iter"(%5921) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
              %5925 = "builtin.unrealized_conversion_cast"(%5924) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %5926 = "llvm.load"(%5925) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %5927 = "llvm.trunc"(%5926) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %5928 = "cute.recast_iter"(%5922) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %5929 = "cute.recast_iter"(%5923) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%5929, %5928, %5927) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %5863 = "cute.static"() : () -> !cute.int_tuple<"1024">
            %5864 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5865 = "cute.add_offset"(%5864, %5863) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %5866 = "cute.make_view"(%5865) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5867 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %5868 = "vector.splat"(%5867) : (bf16) -> vector<16xbf16>
            "cute.memref.store_vec"(%5868, %5866) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %5693 = "cute.static"() : () -> !cute.int_tuple<"(0,32,0,0)">
          %5694 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5695 = "cute.add_offset"(%5694, %5693) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5696 = "cute.make_view"(%5695) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %5697 = "cute.get_iter"(%5696) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5698 = "cute.deref_arith_tuple_iter"(%5697) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %5699:4 = "cute.get_leaves"(%5698) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %5700 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %5701 = "cute.get_shape"(%5700) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %5702:4 = "cute.get_leaves"(%5701) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %5703 = "cute.to_int_tuple"(%5702#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %5704 = "cute.make_coord"(%5699#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5705 = "cute.make_coord"(%5703) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5706 = "cute.get_scalars"(%5704) : (!cute.coord<"?">) -> i32
          %5707 = "cute.get_scalars"(%5705) : (!cute.coord<"?">) -> i32
          %5708 = "arith.constant"() <{value = true}> : () -> i1
          %5709 = "arith.cmpi"(%5706, %5707) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %5710 = "arith.andi"(%5708, %5709) : (i1, i1) -> i1
          "scf.if"(%5710) ({
            %5802 = "cute.make_coord"(%1921) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %5803 = "cute.get_layout"(%406) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
            %5804 = "cute.crd2idx"(%5802, %5803) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
            %5805 = "cute.get_iter"(%406) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
            %5806 = "cute.add_offset"(%5805, %5804) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
            %5807 = "cute.make_view"(%5806) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
            %5808 = "cute.get_iter"(%5807) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5809 = "cute.static"() : () -> !cute.int_tuple<"2048">
            %5810 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5811 = "cute.add_offset"(%5810, %5809) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %5812 = "cute.make_view"(%5811) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5813 = "cute.get_iter"(%5812) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5814 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5815 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
            %5816 = "cute.add_offset"(%5815, %5814) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %5817 = "cute.make_view"(%5816) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
            %5818 = "cute.get_iter"(%5817) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5819 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
            %5820 = "cute.make_view"(%5808, %5819) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
            %5821 = "cute.get_iter"(%5820) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5822 = "cute.make_view"(%5821) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
            %5823 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
            %5824 = "cute.make_view"(%5813, %5823) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
            %5825 = "cute.get_iter"(%5824) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5826 = "cute.make_view"(%5825) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
            %5827 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
            %5828 = "cute.make_view"(%5818, %5827) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
            %5829 = "cute.get_iter"(%5828) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5830 = "cute.make_view"(%5829) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
            %5831 = "cute.static"() : () -> !cute.layout<"1:0">
            %5832 = "cute.get_iter"(%5822) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
            %5833 = "cute.get_iter"(%5826) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
            %5834 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %5835 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %5836 = "cute.get_iter"(%5830) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
            %5837 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
            %5838 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5839 = "cute.get_scalars"(%5838) : (!cute.int_tuple<"2">) -> i32
            %5840 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %5841 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%5840, %5839, %5841) ({
            ^bb0(%arg87: i32):
              %5842 = "cute.make_coord"(%arg87) : (i32) -> !cute.coord<"(_,?)">
              %5843 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5844 = "cute.crd2idx"(%5842, %5834) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %5845 = "cute.add_offset"(%5832, %5844) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %5846 = "cute.make_view"(%5845, %5843) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %5847 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5848 = "cute.crd2idx"(%5842, %5835) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %5849 = "cute.add_offset"(%5833, %5848) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %5850 = "cute.make_view"(%5849, %5847) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %5851 = "cute.static"() : () -> !cute.layout<"(1):(2)">
              %5852 = "cute.crd2idx"(%5842, %5837) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %5853 = "cute.add_offset"(%5836, %5852) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %5854 = "cute.make_view"(%5853, %5851) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
              %5855 = "cute.get_iter"(%5846) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %5856 = "cute.get_iter"(%5850) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %5857 = "cute.get_iter"(%5854) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
              %5858 = "builtin.unrealized_conversion_cast"(%5857) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %5859 = "llvm.load"(%5858) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %5860 = "llvm.trunc"(%5859) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %5861 = "cute.recast_iter"(%5855) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %5862 = "cute.recast_iter"(%5856) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%5862, %5861, %5860) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %5796 = "cute.static"() : () -> !cute.int_tuple<"2048">
            %5797 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5798 = "cute.add_offset"(%5797, %5796) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %5799 = "cute.make_view"(%5798) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5800 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %5801 = "vector.splat"(%5800) : (bf16) -> vector<16xbf16>
            "cute.memref.store_vec"(%5801, %5799) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %5711 = "cute.static"() : () -> !cute.int_tuple<"(0,48,0,0)">
          %5712 = "cute.get_iter"(%855) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5713 = "cute.add_offset"(%5712, %5711) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5714 = "cute.make_view"(%5713) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %5715 = "cute.get_iter"(%5714) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %5716 = "cute.deref_arith_tuple_iter"(%5715) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %5717:4 = "cute.get_leaves"(%5716) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %5718 = "cute.get_layout"(%arg8) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %5719 = "cute.get_shape"(%5718) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %5720:4 = "cute.get_leaves"(%5719) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %5721 = "cute.to_int_tuple"(%5720#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %5722 = "cute.make_coord"(%5717#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5723 = "cute.make_coord"(%5721) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %5724 = "cute.get_scalars"(%5722) : (!cute.coord<"?">) -> i32
          %5725 = "cute.get_scalars"(%5723) : (!cute.coord<"?">) -> i32
          %5726 = "arith.constant"() <{value = true}> : () -> i1
          %5727 = "arith.cmpi"(%5724, %5725) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %5728 = "arith.andi"(%5726, %5727) : (i1, i1) -> i1
          "scf.if"(%5728) ({
            %5735 = "cute.make_coord"(%1921) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %5736 = "cute.get_layout"(%406) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
            %5737 = "cute.crd2idx"(%5735, %5736) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %5738 = "cute.get_iter"(%406) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
            %5739 = "cute.add_offset"(%5738, %5737) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %5740 = "cute.make_view"(%5739) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
            %5741 = "cute.get_iter"(%5740) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5742 = "cute.static"() : () -> !cute.int_tuple<"3072">
            %5743 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5744 = "cute.add_offset"(%5743, %5742) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %5745 = "cute.make_view"(%5744) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5746 = "cute.get_iter"(%5745) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5747 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5748 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
            %5749 = "cute.add_offset"(%5748, %5747) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %5750 = "cute.make_view"(%5749) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
            %5751 = "cute.get_iter"(%5750) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5752 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
            %5753 = "cute.make_view"(%5741, %5752) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
            %5754 = "cute.get_iter"(%5753) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
            %5755 = "cute.make_view"(%5754) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
            %5756 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),4096)">
            %5757 = "cute.make_view"(%5746, %5756) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),2):((1,0),4096)">) -> !memref_smem_bf16_9
            %5758 = "cute.get_iter"(%5757) : (!memref_smem_bf16_9) -> !cute.ptr<bf16, smem, align<16>>
            %5759 = "cute.make_view"(%5758) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_10
            %5760 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
            %5761 = "cute.make_view"(%5751, %5760) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
            %5762 = "cute.get_iter"(%5761) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
            %5763 = "cute.make_view"(%5762) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
            %5764 = "cute.static"() : () -> !cute.layout<"1:0">
            %5765 = "cute.get_iter"(%5755) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
            %5766 = "cute.get_iter"(%5759) : (!memref_smem_bf16_10) -> !cute.ptr<bf16, smem, align<16>>
            %5767 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
            %5768 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((4096)))">
            %5769 = "cute.get_iter"(%5763) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
            %5770 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
            %5771 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5772 = "cute.get_scalars"(%5771) : (!cute.int_tuple<"2">) -> i32
            %5773 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %5774 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%5773, %5772, %5774) ({
            ^bb0(%arg86: i32):
              %5775 = "cute.make_coord"(%arg86) : (i32) -> !cute.coord<"(_,?)">
              %5776 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5777 = "cute.crd2idx"(%5775, %5767) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %5778 = "cute.add_offset"(%5765, %5777) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %5779 = "cute.make_view"(%5778, %5776) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %5780 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %5781 = "cute.crd2idx"(%5775, %5768) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %5782 = "cute.add_offset"(%5766, %5781) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %5783 = "cute.make_view"(%5782, %5780) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %5784 = "cute.static"() : () -> !cute.layout<"(1):(2)">
              %5785 = "cute.crd2idx"(%5775, %5770) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %5786 = "cute.add_offset"(%5769, %5785) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %5787 = "cute.make_view"(%5786, %5784) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
              %5788 = "cute.get_iter"(%5779) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %5789 = "cute.get_iter"(%5783) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %5790 = "cute.get_iter"(%5787) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
              %5791 = "builtin.unrealized_conversion_cast"(%5790) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
              %5792 = "llvm.load"(%5791) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
              %5793 = "llvm.trunc"(%5792) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
              %5794 = "cute.recast_iter"(%5788) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %5795 = "cute.recast_iter"(%5789) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%5795, %5794, %5793) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %5729 = "cute.static"() : () -> !cute.int_tuple<"3072">
            %5730 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
            %5731 = "cute.add_offset"(%5730, %5729) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %5732 = "cute.make_view"(%5731) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_9
            %5733 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %5734 = "vector.splat"(%5733) : (bf16) -> vector<16xbf16>
            "cute.memref.store_vec"(%5734, %5732) : (vector<16xbf16>, !memref_smem_bf16_9) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }, {
          %5577 = "cute.make_coord"(%1921) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %5578 = "cute.get_layout"(%406) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %5579:3 = "cute.get_scalars"(%5578) <{only_dynamic}> : (!cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> (i32, i64, i64)
          %5580 = "cute.static"() : () -> !cute.shape<"((8,1),4,2)">
          %5581 = "cute.assume"(%5579#1) : (i64) -> !cute.i64<divby 128>
          %5582 = "cute.make_stride"(%5581) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %5583 = "cute.make_layout"(%5580, %5582) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2)">, !cute.stride<"((1,0),?{i64 div=128},64)">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %5584 = "cute.crd2idx"(%5577, %5578) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %5585 = "cute.get_iter"(%406) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
          %5586 = "cute.add_offset"(%5585, %5584) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %5587 = "cute.make_view"(%5586, %5583) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
          %5588 = "cute.get_iter"(%5587) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
          %5589 = "cute.static"() : () -> !cute.int_tuple<"0">
          %5590 = "cute.get_iter"(%438) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %5591 = "cute.add_offset"(%5590, %5589) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %5592 = "cute.make_view"(%5591) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_3
          %5593 = "cute.get_iter"(%5592) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %5594 = "cute.static"() : () -> !cute.int_tuple<"0">
          %5595 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %5596 = "cute.add_offset"(%5595, %5594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %5597 = "cute.make_view"(%5596) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_
          %5598 = "cute.get_iter"(%5597) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %5599 = "cute.get_layout"(%5587) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %5600 = "cute.static"() : () -> !cute.layout<"1:0">
          %5601 = "cute.append_to_rank"(%5599, %5600) <{rank = 2 : si32}> : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %5602 = "cute.make_view"(%5588, %5601) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
          %5603 = "cute.get_iter"(%5602) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
          %5604 = "cute.get_layout"(%5602) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %5605 = "cute.get_scalars"(%5604) <{only_dynamic}> : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> i64
          %5606 = "cute.static"() : () -> !cute.shape<"((8,1),(4,2))">
          %5607 = "cute.assume"(%5605) : (i64) -> !cute.i64<divby 128>
          %5608 = "cute.make_stride"(%5607) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %5609 = "cute.make_layout"(%5606, %5608) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(4,2))">, !cute.stride<"((1,0),(?{i64 div=128},64))">) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %5610 = "cute.make_view"(%5603, %5609) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !memref_gmem_bf16_13
          %5611 = "cute.static"() : () -> !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
          %5612 = "cute.make_view"(%5593, %5611) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !memref_smem_bf16_3
          %5613 = "cute.get_iter"(%5612) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %5614 = "cute.make_view"(%5613) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_14
          %5615 = "cute.static"() : () -> !cute.layout<"(1,4,2):(2,0,1)">
          %5616 = "cute.make_view"(%5598, %5615) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,4,2):(2,0,1)">) -> !memref_rmem_i8_
          %5617 = "cute.get_iter"(%5616) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %5618 = "cute.make_view"(%5617) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_4
          %5619 = "cute.static"() : () -> !cute.layout<"1:0">
          %5620 = "cute.get_iter"(%5610) : (!memref_gmem_bf16_13) -> !cute.ptr<bf16, gmem, align<16>>
          %5621 = "cute.get_iter"(%5614) : (!memref_smem_bf16_14) -> !cute.ptr<bf16, smem, align<16>>
          %5622 = "cute.get_layout"(%5610) : (!memref_gmem_bf16_13) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %5623 = "cute.append_to_rank"(%5622, %5619) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %5624 = "cute.get_scalars"(%5623) <{only_dynamic}> : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> i64
          %5625 = "cute.static"() : () -> !cute.shape<"((8,1),((4,2)))">
          %5626 = "cute.assume"(%5624) : (i64) -> !cute.i64<divby 128>
          %5627 = "cute.make_stride"(%5626) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %5628 = "cute.make_layout"(%5625, %5627) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((4,2)))">, !cute.stride<"((1,0),((?{i64 div=128},64)))">) -> !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %5629 = "cute.static"() : () -> !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
          %5630 = "cute.get_iter"(%5618) : (!memref_rmem_i8_4) -> !cute.ptr<i8, rmem, align<32>>
          %5631 = "cute.static"() : () -> !cute.layout<"(1,((4,2))):(2,((0,1)))">
          %5632 = "cute.static"() : () -> !cute.int_tuple<"8">
          %5633 = "cute.get_scalars"(%5632) : (!cute.int_tuple<"8">) -> i32
          %5634 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5635 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5634, %5633, %5635) ({
          ^bb0(%arg85: i32):
            %5636 = "cute.make_coord"(%arg85) : (i32) -> !cute.coord<"(_,?)">
            %5637 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5638 = "cute.crd2idx"(%5636, %5628) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %5639 = "cute.add_offset"(%5620, %5638) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %5640 = "cute.make_view"(%5639, %5637) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
            %5641 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5642 = "cute.crd2idx"(%5636, %5629) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %5643 = "cute.add_offset"(%5621, %5642) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %5644 = "cute.make_view"(%5643, %5641) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5645 = "cute.static"() : () -> !cute.layout<"(1):(2)">
            %5646 = "cute.crd2idx"(%5636, %5631) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %5647 = "cute.add_offset"(%5630, %5646) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %5648 = "cute.make_view"(%5647, %5645) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
            %5649 = "cute.get_iter"(%5640) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
            %5650 = "cute.get_iter"(%5644) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5651 = "cute.get_iter"(%5648) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
            %5652 = "builtin.unrealized_conversion_cast"(%5651) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
            %5653 = "llvm.load"(%5652) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
            %5654 = "llvm.trunc"(%5653) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
            %5655 = "cute.recast_iter"(%5649) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
            %5656 = "cute.recast_iter"(%5650) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
            "cute_nvgpu.arch.copy.SM80.cp_async"(%5656, %5655, %5654) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) : (i1) -> ()
        "nvvm.cp.async.commit.group"() : () -> ()
        %1926 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %1927 = "cute.memref.alloca"(%1926) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !memref_rmem_f32_1
        %1928 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %1929 = "cute.memref.alloca"(%1928) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !memref_rmem_bf16_6
        %1930 = "cute.get_iter"(%1929) : (!memref_rmem_bf16_6) -> !cute.ptr<bf16, rmem, align<32>>
        %1931 = "cute.make_view"(%1930) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_7
        %1932 = "cute.get_layout"(%708) : (!memref_smem_bf16_8) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %1933:2 = "cute.get_scalars"(%1932) <{only_dynamic}> : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> (i32, i32)
        %1934 = "cute.static"() : () -> !cute.shape<"((8,1),1,(2,2))">
        %1935 = "cute.assume"(%1933#0) : (i32) -> !cute.i32<divby 16>
        %1936 = "cute.assume"(%1933#1) : (i32) -> !cute.i32<divby 32>
        %1937 = "cute.make_stride"(%1935, %1936) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
        %1938 = "cute.make_layout"(%1934, %1937) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),1,(2,2))">, !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %1939 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1940 = "cute.get_iter"(%708) : (!memref_smem_bf16_8) -> !cute.ptr<bf16, smem, align<16>>
        %1941 = "cute.add_offset"(%1940, %1939) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %1942 = "cute.make_view"(%1941, %1938) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !memref_smem_bf16_8
        %1943 = "cute.get_iter"(%1942) : (!memref_smem_bf16_8) -> !cute.ptr<bf16, smem, align<16>>
        %1944 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1945 = "cute.get_iter"(%1931) : (!memref_rmem_bf16_7) -> !cute.ptr<bf16, rmem, align<32>>
        %1946 = "cute.add_offset"(%1945, %1944) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %1947 = "cute.make_view"(%1946) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_7
        %1948 = "cute.get_iter"(%1947) : (!memref_rmem_bf16_7) -> !cute.ptr<bf16, rmem, align<32>>
        %1949 = "cute.get_layout"(%1942) : (!memref_smem_bf16_8) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %1950 = "cute.static"() : () -> !cute.layout<"1:0">
        %1951 = "cute.append_to_rank"(%1949, %1950) <{rank = 2 : si32}> : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %1952 = "cute.make_view"(%1943, %1951) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> !memref_smem_bf16_8
        %1953 = "cute.get_iter"(%1952) : (!memref_smem_bf16_8) -> !cute.ptr<bf16, smem, align<16>>
        %1954 = "cute.get_layout"(%1952) : (!memref_smem_bf16_8) -> !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %1955:2 = "cute.get_scalars"(%1954) <{only_dynamic}> : (!cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">) -> (i32, i32)
        %1956 = "cute.static"() : () -> !cute.shape<"((8,1),(1,(2,2)))">
        %1957 = "cute.assume"(%1955#0) : (i32) -> !cute.i32<divby 16>
        %1958 = "cute.assume"(%1955#1) : (i32) -> !cute.i32<divby 32>
        %1959 = "cute.make_stride"(%1957, %1958) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
        %1960 = "cute.make_layout"(%1956, %1959) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(1,(2,2)))">, !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">) -> !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %1961 = "cute.make_view"(%1953, %1960) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">) -> !memref_smem_bf16_15
        %1962 = "cute.static"() : () -> !cute.layout<"((8,1),1,4):((1,0),0,8)">
        %1963 = "cute.make_view"(%1948, %1962) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),1,4):((1,0),0,8)">) -> !memref_rmem_bf16_7
        %1964 = "cute.get_iter"(%1963) : (!memref_rmem_bf16_7) -> !cute.ptr<bf16, rmem, align<32>>
        %1965 = "cute.make_view"(%1964) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_8
        %1966 = "cute.static"() : () -> !cute.layout<"1:0">
        %1967 = "cute.get_iter"(%1961) : (!memref_smem_bf16_15) -> !cute.ptr<bf16, smem, align<16>>
        %1968 = "cute.get_iter"(%1965) : (!memref_rmem_bf16_8) -> !cute.ptr<bf16, rmem, align<32>>
        %1969 = "cute.get_layout"(%1961) : (!memref_smem_bf16_15) -> !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %1970 = "cute.append_to_rank"(%1969, %1966) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %1971:2 = "cute.get_scalars"(%1970) <{only_dynamic}> : (!cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">) -> (i32, i32)
        %1972 = "cute.static"() : () -> !cute.shape<"((8,1),((1,(2,2))))">
        %1973 = "cute.assume"(%1971#0) : (i32) -> !cute.i32<divby 16>
        %1974 = "cute.assume"(%1971#1) : (i32) -> !cute.i32<divby 32>
        %1975 = "cute.make_stride"(%1973, %1974) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
        %1976 = "cute.make_layout"(%1972, %1975) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((1,(2,2))))">, !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
        %1977 = "cute.static"() : () -> !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">
        %1978 = "cute.static"() : () -> !cute.int_tuple<"4">
        %1979 = "cute.get_scalars"(%1978) : (!cute.int_tuple<"4">) -> i32
        %1980 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1981 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1980, %1979, %1981) ({
        ^bb0(%arg84: i32):
          %5546 = "cute.make_coord"(%arg84) : (i32) -> !cute.coord<"(_,?)">
          %5547 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %5548 = "cute.crd2idx"(%5546, %1976) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
          %5549 = "cute.add_offset"(%1967, %5548) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %5550 = "cute.make_view"(%5549, %5547) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %5551 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %5552 = "cute.crd2idx"(%5546, %1977) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
          %5553 = "cute.add_offset"(%1968, %5552) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %5554 = "cute.make_view"(%5553, %5551) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %5555 = "cute.get_iter"(%5550) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %5556 = "cute.get_iter"(%5554) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %5557 = "cute.apply_swizzle"(%5555) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
          %5558 = "cute_nvgpu.arch.copy.ldsm"(%5557) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
          %5559 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
          %5560 = "vector.extractelement"(%5558, %5559) : (vector<4xi32>, i32) -> i32
          %5561 = "builtin.unrealized_conversion_cast"(%5556) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          "llvm.store"(%5560, %5561) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5562 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
          %5563 = "vector.extractelement"(%5558, %5562) : (vector<4xi32>, i32) -> i32
          %5564 = "cute.static"() : () -> !cute.int_tuple<"2">
          %5565 = "cute.add_offset"(%5556, %5564) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %5566 = "builtin.unrealized_conversion_cast"(%5565) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5563, %5566) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5567 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
          %5568 = "vector.extractelement"(%5558, %5567) : (vector<4xi32>, i32) -> i32
          %5569 = "cute.static"() : () -> !cute.int_tuple<"4">
          %5570 = "cute.add_offset"(%5556, %5569) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %5571 = "builtin.unrealized_conversion_cast"(%5570) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%5568, %5571) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5572 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
          %5573 = "vector.extractelement"(%5558, %5572) : (vector<4xi32>, i32) -> i32
          %5574 = "cute.static"() : () -> !cute.int_tuple<"6">
          %5575 = "cute.add_offset"(%5556, %5574) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %5576 = "builtin.unrealized_conversion_cast"(%5575) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5573, %5576) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %1982 = "cute.memref.load_vec"(%1929) : (!memref_rmem_bf16_6) -> vector<32xbf16>
        %1983 = "arith.extf"(%1982) : (vector<32xbf16>) -> vector<32xf32>
        "cute.memref.store_vec"(%1983, %1927) : (vector<32xf32>, !memref_rmem_f32_1) -> ()
        %1984 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1985 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
        %1986 = "cute.add_offset"(%1985, %1984) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %1987 = "cute.make_view"(%1986) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
        %1988 = "cute.get_iter"(%1987) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %1989 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1990 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
        %1991 = "cute.add_offset"(%1990, %1989) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
        %1992 = "cute.make_view"(%1991) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
        %1993 = "cute.get_iter"(%1992) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
        %1994 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %1995 = "cute.make_view"(%1988, %1994) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
        %1996 = "cute.get_iter"(%1995) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
        %1997 = "cute.make_view"(%1996) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
        %1998 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
        %1999 = "cute.make_view"(%1993, %1998) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
        %2000 = "cute.get_iter"(%1999) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
        %2001 = "cute.make_view"(%2000) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
        %2002 = "cute.static"() : () -> !cute.layout<"1:0">
        %2003 = "cute.get_iter"(%1997) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
        %2004 = "cute.get_iter"(%2001) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
        %2005 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2006 = "cute.get_scalars"(%2005) : (!cute.int_tuple<"1">) -> i32
        %2007 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2008 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2007, %2006, %2008) ({
        ^bb0(%arg83: i32):
          %5516 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %5517 = "cute.static"() : () -> !cute.int_tuple<"0">
          %5518 = "cute.add_offset"(%2003, %5517) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %5519 = "cute.make_view"(%5518, %5516) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %5520 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %5521 = "cute.static"() : () -> !cute.int_tuple<"0">
          %5522 = "cute.add_offset"(%2004, %5521) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
          %5523 = "cute.make_view"(%5522, %5520) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %5524 = "cute.get_iter"(%5519) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %5525 = "cute.get_iter"(%5523) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %5526 = "cute.apply_swizzle"(%5524) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
          %5527 = "cute_nvgpu.arch.copy.ldsm"(%5526) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
          %5528 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
          %5529 = "vector.extractelement"(%5527, %5528) : (vector<4xi32>, i32) -> i32
          %5530 = "builtin.unrealized_conversion_cast"(%5525) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
          "llvm.store"(%5529, %5530) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5531 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
          %5532 = "vector.extractelement"(%5527, %5531) : (vector<4xi32>, i32) -> i32
          %5533 = "cute.static"() : () -> !cute.int_tuple<"2">
          %5534 = "cute.add_offset"(%5525, %5533) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %5535 = "builtin.unrealized_conversion_cast"(%5534) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5532, %5535) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5536 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
          %5537 = "vector.extractelement"(%5527, %5536) : (vector<4xi32>, i32) -> i32
          %5538 = "cute.static"() : () -> !cute.int_tuple<"4">
          %5539 = "cute.add_offset"(%5525, %5538) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %5540 = "builtin.unrealized_conversion_cast"(%5539) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%5537, %5540) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5541 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
          %5542 = "vector.extractelement"(%5527, %5541) : (vector<4xi32>, i32) -> i32
          %5543 = "cute.static"() : () -> !cute.int_tuple<"6">
          %5544 = "cute.add_offset"(%5525, %5543) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %5545 = "builtin.unrealized_conversion_cast"(%5544) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5542, %5545) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %2009 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2010 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
        %2011 = "cute.add_offset"(%2010, %2009) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %2012 = "cute.make_view"(%2011) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
        %2013 = "cute.get_iter"(%2012) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
        %2014 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2015 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
        %2016 = "cute.add_offset"(%2015, %2014) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %2017 = "cute.make_view"(%2016) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
        %2018 = "cute.get_iter"(%2017) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
        %2019 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
        %2020 = "cute.make_view"(%2013, %2019) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
        %2021 = "cute.get_iter"(%2020) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
        %2022 = "cute.make_view"(%2021) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
        %2023 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
        %2024 = "cute.make_view"(%2018, %2023) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
        %2025 = "cute.get_iter"(%2024) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
        %2026 = "cute.make_view"(%2025) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
        %2027 = "cute.static"() : () -> !cute.layout<"1:0">
        %2028 = "cute.get_iter"(%2022) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
        %2029 = "cute.get_iter"(%2026) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
        %2030 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
        %2031 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
        %2032 = "cute.static"() : () -> !cute.int_tuple<"4">
        %2033 = "cute.get_scalars"(%2032) : (!cute.int_tuple<"4">) -> i32
        %2034 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2035 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2034, %2033, %2035) ({
        ^bb0(%arg82: i32):
          %5485 = "cute.make_coord"(%arg82) : (i32) -> !cute.coord<"(_,?)">
          %5486 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %5487 = "cute.crd2idx"(%5485, %2030) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %5488 = "cute.add_offset"(%2028, %5487) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %5489 = "cute.make_view"(%5488, %5486) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %5490 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
          %5491 = "cute.crd2idx"(%5485, %2031) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %5492 = "cute.add_offset"(%2029, %5491) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %5493 = "cute.make_view"(%5492, %5490) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
          %5494 = "cute.get_iter"(%5489) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %5495 = "cute.get_iter"(%5493) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
          %5496 = "cute.apply_swizzle"(%5494) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
          %5497 = "cute_nvgpu.arch.copy.ldsm"(%5496) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
          %5498 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
          %5499 = "vector.extractelement"(%5497, %5498) : (vector<4xi32>, i32) -> i32
          %5500 = "builtin.unrealized_conversion_cast"(%5495) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%5499, %5500) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5501 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
          %5502 = "vector.extractelement"(%5497, %5501) : (vector<4xi32>, i32) -> i32
          %5503 = "cute.static"() : () -> !cute.int_tuple<"2">
          %5504 = "cute.add_offset"(%5495, %5503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %5505 = "builtin.unrealized_conversion_cast"(%5504) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5502, %5505) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5506 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
          %5507 = "vector.extractelement"(%5497, %5506) : (vector<4xi32>, i32) -> i32
          %5508 = "cute.static"() : () -> !cute.int_tuple<"32">
          %5509 = "cute.add_offset"(%5495, %5508) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %5510 = "builtin.unrealized_conversion_cast"(%5509) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%5507, %5510) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %5511 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
          %5512 = "vector.extractelement"(%5497, %5511) : (vector<4xi32>, i32) -> i32
          %5513 = "cute.static"() : () -> !cute.int_tuple<"34">
          %5514 = "cute.add_offset"(%5495, %5513) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %5515 = "builtin.unrealized_conversion_cast"(%5514) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%5512, %5515) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %2036 = "arith.constant"() <{value = true}> : () -> i1
        "scf.if"(%2036) ({
          %5368 = "cute.static"() : () -> !cute.coord<"(_,_,1)">
          %5369 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %5370 = "cute.crd2idx"(%5368, %5369) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %5371 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %5372 = "cute.add_offset"(%5371, %5370) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %5373 = "cute.make_view"(%5372) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %5374 = "cute.get_iter"(%5373) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5375 = "cute.static"() : () -> !cute.int_tuple<"16">
          %5376 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %5377 = "cute.add_offset"(%5376, %5375) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
          %5378 = "cute.make_view"(%5377) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %5379 = "cute.get_iter"(%5378) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5380 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5381 = "cute.make_view"(%5374, %5380) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %5382 = "cute.get_iter"(%5381) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5383 = "cute.make_view"(%5382) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %5384 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5385 = "cute.make_view"(%5379, %5384) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %5386 = "cute.get_iter"(%5385) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5387 = "cute.make_view"(%5386) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %5388 = "cute.static"() : () -> !cute.layout<"1:0">
          %5389 = "cute.get_iter"(%5383) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %5390 = "cute.get_iter"(%5387) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %5391 = "cute.static"() : () -> !cute.int_tuple<"1">
          %5392 = "cute.get_scalars"(%5391) : (!cute.int_tuple<"1">) -> i32
          %5393 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5394 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5393, %5392, %5394) ({
          ^bb0(%arg81: i32):
            %5455 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5456 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5457 = "cute.add_offset"(%5389, %5456) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %5458 = "cute.make_view"(%5457, %5455) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5459 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5460 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5461 = "cute.add_offset"(%5390, %5460) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %5462 = "cute.make_view"(%5461, %5459) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %5463 = "cute.get_iter"(%5458) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5464 = "cute.get_iter"(%5462) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %5465 = "cute.apply_swizzle"(%5463) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5466 = "cute_nvgpu.arch.copy.ldsm"(%5465) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5467 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5468 = "vector.extractelement"(%5466, %5467) : (vector<4xi32>, i32) -> i32
            %5469 = "builtin.unrealized_conversion_cast"(%5464) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%5468, %5469) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5470 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5471 = "vector.extractelement"(%5466, %5470) : (vector<4xi32>, i32) -> i32
            %5472 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5473 = "cute.add_offset"(%5464, %5472) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5474 = "builtin.unrealized_conversion_cast"(%5473) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5471, %5474) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5475 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5476 = "vector.extractelement"(%5466, %5475) : (vector<4xi32>, i32) -> i32
            %5477 = "cute.static"() : () -> !cute.int_tuple<"4">
            %5478 = "cute.add_offset"(%5464, %5477) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %5479 = "builtin.unrealized_conversion_cast"(%5478) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5476, %5479) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5480 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5481 = "vector.extractelement"(%5466, %5480) : (vector<4xi32>, i32) -> i32
            %5482 = "cute.static"() : () -> !cute.int_tuple<"6">
            %5483 = "cute.add_offset"(%5464, %5482) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %5484 = "builtin.unrealized_conversion_cast"(%5483) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5481, %5484) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %5395 = "cute.static"() : () -> !cute.coord<"(_,_,1)">
          %5396 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %5397 = "cute.crd2idx"(%5395, %5396) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %5398 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %5399 = "cute.add_offset"(%5398, %5397) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %5400 = "cute.make_view"(%5399) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %5401 = "cute.get_iter"(%5400) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5402 = "cute.static"() : () -> !cute.int_tuple<"64">
          %5403 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %5404 = "cute.add_offset"(%5403, %5402) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
          %5405 = "cute.make_view"(%5404) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %5406 = "cute.get_iter"(%5405) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5407 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %5408 = "cute.make_view"(%5401, %5407) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %5409 = "cute.get_iter"(%5408) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5410 = "cute.make_view"(%5409) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %5411 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %5412 = "cute.make_view"(%5406, %5411) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %5413 = "cute.get_iter"(%5412) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5414 = "cute.make_view"(%5413) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %5415 = "cute.static"() : () -> !cute.layout<"1:0">
          %5416 = "cute.get_iter"(%5410) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %5417 = "cute.get_iter"(%5414) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %5418 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %5419 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %5420 = "cute.static"() : () -> !cute.int_tuple<"4">
          %5421 = "cute.get_scalars"(%5420) : (!cute.int_tuple<"4">) -> i32
          %5422 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5423 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5422, %5421, %5423) ({
          ^bb0(%arg80: i32):
            %5424 = "cute.make_coord"(%arg80) : (i32) -> !cute.coord<"(_,?)">
            %5425 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5426 = "cute.crd2idx"(%5424, %5418) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %5427 = "cute.add_offset"(%5416, %5426) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %5428 = "cute.make_view"(%5427, %5425) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5429 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %5430 = "cute.crd2idx"(%5424, %5419) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %5431 = "cute.add_offset"(%5417, %5430) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %5432 = "cute.make_view"(%5431, %5429) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %5433 = "cute.get_iter"(%5428) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5434 = "cute.get_iter"(%5432) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %5435 = "cute.apply_swizzle"(%5433) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5436 = "cute_nvgpu.arch.copy.ldsm"(%5435) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5437 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5438 = "vector.extractelement"(%5436, %5437) : (vector<4xi32>, i32) -> i32
            %5439 = "builtin.unrealized_conversion_cast"(%5434) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5438, %5439) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5440 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5441 = "vector.extractelement"(%5436, %5440) : (vector<4xi32>, i32) -> i32
            %5442 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5443 = "cute.add_offset"(%5434, %5442) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5444 = "builtin.unrealized_conversion_cast"(%5443) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5441, %5444) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5445 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5446 = "vector.extractelement"(%5436, %5445) : (vector<4xi32>, i32) -> i32
            %5447 = "cute.static"() : () -> !cute.int_tuple<"32">
            %5448 = "cute.add_offset"(%5434, %5447) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %5449 = "builtin.unrealized_conversion_cast"(%5448) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5446, %5449) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5450 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5451 = "vector.extractelement"(%5436, %5450) : (vector<4xi32>, i32) -> i32
            %5452 = "cute.static"() : () -> !cute.int_tuple<"34">
            %5453 = "cute.add_offset"(%5434, %5452) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %5454 = "builtin.unrealized_conversion_cast"(%5453) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5451, %5454) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2037 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2038 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2039 = "cute.add_offset"(%2038, %2037) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
        %2040 = "cute.make_view"(%2039) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2041 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2042 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2043 = "cute.add_offset"(%2042, %2041) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %2044 = "cute.make_view"(%2043) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2045 = "cute.get_iter"(%2040) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2046 = "cute.get_iter"(%2044) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2047 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2048 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2049 = "cute.static"() : () -> !cute.layout<"1:0">
        %2050 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2051 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2052 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2053 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2054 = "cute.get_scalars"(%2051) : (!cute.int_tuple<"1">) -> i32
        %2055 = "cute.get_scalars"(%2052) : (!cute.int_tuple<"1">) -> i32
        %2056 = "cute.get_scalars"(%2053) : (!cute.int_tuple<"8">) -> i32
        %2057 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2058 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2057, %2054, %2058) ({
        ^bb0(%arg77: i32):
          "scf.for"(%2057, %2055, %2058) ({
          ^bb0(%arg78: i32):
            "scf.for"(%2057, %2056, %2058) ({
            ^bb0(%arg79: i32):
              %5326 = "cute.make_coord"(%arg79, %arg77) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5327 = "cute.make_coord"(%arg78, %arg79) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5328 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %5329 = "cute.static"() : () -> !cute.int_tuple<"0">
              %5330 = "cute.add_offset"(%2045, %5329) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %5331 = "cute.make_view"(%5330, %5328) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %5332 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5333 = "cute.crd2idx"(%5326, %2050) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %5334 = "cute.add_offset"(%2046, %5333) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %5335 = "cute.make_view"(%5334, %5332) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %5336 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5337 = "cute.crd2idx"(%5327, %2048) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %5338 = "cute.add_offset"(%2047, %5337) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %5339 = "cute.make_view"(%5338, %5336) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %5340 = "cute.get_iter"(%5331) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %5341 = "cute.get_iter"(%5335) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %5342 = "cute.get_iter"(%5339) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %5343 = "builtin.unrealized_conversion_cast"(%5340) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %5344 = "llvm.load"(%5343) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5345 = "llvm.getelementptr"(%5343) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5346 = "llvm.load"(%5345) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5347 = "llvm.getelementptr"(%5343) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5348 = "llvm.load"(%5347) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5349 = "llvm.getelementptr"(%5343) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5350 = "llvm.load"(%5349) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5351 = "builtin.unrealized_conversion_cast"(%5341) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %5352 = "llvm.load"(%5351) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5353 = "llvm.getelementptr"(%5351) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5354 = "llvm.load"(%5353) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5355 = "builtin.unrealized_conversion_cast"(%5342) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %5356 = "llvm.load"(%5355) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5357 = "llvm.getelementptr"(%5355) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5358 = "llvm.load"(%5357) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5359 = "llvm.getelementptr"(%5355) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5360 = "llvm.load"(%5359) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5361 = "llvm.getelementptr"(%5355) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5362 = "llvm.load"(%5361) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5363:4 = "cute_nvgpu.arch.mma.SM80"(%5344, %5346, %5348, %5350, %5352, %5354, %5356, %5358, %5360, %5362) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %5364 = "builtin.unrealized_conversion_cast"(%5342) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%5363#0, %5364) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5365 = "llvm.getelementptr"(%5364) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5363#1, %5365) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5366 = "llvm.getelementptr"(%5364) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5363#2, %5366) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5367 = "llvm.getelementptr"(%5364) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5363#3, %5367) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %5209 = "cute.static"() : () -> !cute.coord<"(_,_,2)">
          %5210 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %5211 = "cute.crd2idx"(%5209, %5210) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
          %5212 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %5213 = "cute.add_offset"(%5212, %5211) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
          %5214 = "cute.make_view"(%5213) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %5215 = "cute.get_iter"(%5214) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5216 = "cute.static"() : () -> !cute.int_tuple<"32">
          %5217 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %5218 = "cute.add_offset"(%5217, %5216) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
          %5219 = "cute.make_view"(%5218) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %5220 = "cute.get_iter"(%5219) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5221 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5222 = "cute.make_view"(%5215, %5221) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %5223 = "cute.get_iter"(%5222) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5224 = "cute.make_view"(%5223) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %5225 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5226 = "cute.make_view"(%5220, %5225) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %5227 = "cute.get_iter"(%5226) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5228 = "cute.make_view"(%5227) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %5229 = "cute.static"() : () -> !cute.layout<"1:0">
          %5230 = "cute.get_iter"(%5224) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %5231 = "cute.get_iter"(%5228) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %5232 = "cute.static"() : () -> !cute.int_tuple<"1">
          %5233 = "cute.get_scalars"(%5232) : (!cute.int_tuple<"1">) -> i32
          %5234 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5235 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5234, %5233, %5235) ({
          ^bb0(%arg76: i32):
            %5296 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5297 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5298 = "cute.add_offset"(%5230, %5297) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %5299 = "cute.make_view"(%5298, %5296) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5300 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5301 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5302 = "cute.add_offset"(%5231, %5301) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %5303 = "cute.make_view"(%5302, %5300) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %5304 = "cute.get_iter"(%5299) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5305 = "cute.get_iter"(%5303) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %5306 = "cute.apply_swizzle"(%5304) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5307 = "cute_nvgpu.arch.copy.ldsm"(%5306) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5308 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5309 = "vector.extractelement"(%5307, %5308) : (vector<4xi32>, i32) -> i32
            %5310 = "builtin.unrealized_conversion_cast"(%5305) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%5309, %5310) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5311 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5312 = "vector.extractelement"(%5307, %5311) : (vector<4xi32>, i32) -> i32
            %5313 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5314 = "cute.add_offset"(%5305, %5313) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5315 = "builtin.unrealized_conversion_cast"(%5314) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5312, %5315) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5316 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5317 = "vector.extractelement"(%5307, %5316) : (vector<4xi32>, i32) -> i32
            %5318 = "cute.static"() : () -> !cute.int_tuple<"4">
            %5319 = "cute.add_offset"(%5305, %5318) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %5320 = "builtin.unrealized_conversion_cast"(%5319) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5317, %5320) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5321 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5322 = "vector.extractelement"(%5307, %5321) : (vector<4xi32>, i32) -> i32
            %5323 = "cute.static"() : () -> !cute.int_tuple<"6">
            %5324 = "cute.add_offset"(%5305, %5323) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %5325 = "builtin.unrealized_conversion_cast"(%5324) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5322, %5325) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %5236 = "cute.static"() : () -> !cute.coord<"(_,_,2)">
          %5237 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %5238 = "cute.crd2idx"(%5236, %5237) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
          %5239 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %5240 = "cute.add_offset"(%5239, %5238) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
          %5241 = "cute.make_view"(%5240) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %5242 = "cute.get_iter"(%5241) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5243 = "cute.static"() : () -> !cute.int_tuple<"128">
          %5244 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %5245 = "cute.add_offset"(%5244, %5243) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
          %5246 = "cute.make_view"(%5245) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %5247 = "cute.get_iter"(%5246) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5248 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %5249 = "cute.make_view"(%5242, %5248) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %5250 = "cute.get_iter"(%5249) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5251 = "cute.make_view"(%5250) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %5252 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %5253 = "cute.make_view"(%5247, %5252) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %5254 = "cute.get_iter"(%5253) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5255 = "cute.make_view"(%5254) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %5256 = "cute.static"() : () -> !cute.layout<"1:0">
          %5257 = "cute.get_iter"(%5251) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %5258 = "cute.get_iter"(%5255) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %5259 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %5260 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %5261 = "cute.static"() : () -> !cute.int_tuple<"4">
          %5262 = "cute.get_scalars"(%5261) : (!cute.int_tuple<"4">) -> i32
          %5263 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5264 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5263, %5262, %5264) ({
          ^bb0(%arg75: i32):
            %5265 = "cute.make_coord"(%arg75) : (i32) -> !cute.coord<"(_,?)">
            %5266 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5267 = "cute.crd2idx"(%5265, %5259) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %5268 = "cute.add_offset"(%5257, %5267) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %5269 = "cute.make_view"(%5268, %5266) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5270 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %5271 = "cute.crd2idx"(%5265, %5260) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %5272 = "cute.add_offset"(%5258, %5271) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %5273 = "cute.make_view"(%5272, %5270) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %5274 = "cute.get_iter"(%5269) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5275 = "cute.get_iter"(%5273) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %5276 = "cute.apply_swizzle"(%5274) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5277 = "cute_nvgpu.arch.copy.ldsm"(%5276) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5278 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5279 = "vector.extractelement"(%5277, %5278) : (vector<4xi32>, i32) -> i32
            %5280 = "builtin.unrealized_conversion_cast"(%5275) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5279, %5280) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5281 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5282 = "vector.extractelement"(%5277, %5281) : (vector<4xi32>, i32) -> i32
            %5283 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5284 = "cute.add_offset"(%5275, %5283) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5285 = "builtin.unrealized_conversion_cast"(%5284) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5282, %5285) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5286 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5287 = "vector.extractelement"(%5277, %5286) : (vector<4xi32>, i32) -> i32
            %5288 = "cute.static"() : () -> !cute.int_tuple<"32">
            %5289 = "cute.add_offset"(%5275, %5288) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %5290 = "builtin.unrealized_conversion_cast"(%5289) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5287, %5290) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5291 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5292 = "vector.extractelement"(%5277, %5291) : (vector<4xi32>, i32) -> i32
            %5293 = "cute.static"() : () -> !cute.int_tuple<"34">
            %5294 = "cute.add_offset"(%5275, %5293) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %5295 = "builtin.unrealized_conversion_cast"(%5294) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5292, %5295) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2059 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2060 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2061 = "cute.add_offset"(%2060, %2059) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        %2062 = "cute.make_view"(%2061) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2063 = "cute.static"() : () -> !cute.int_tuple<"64">
        %2064 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2065 = "cute.add_offset"(%2064, %2063) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %2066 = "cute.make_view"(%2065) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2067 = "cute.get_iter"(%2062) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2068 = "cute.get_iter"(%2066) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2069 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2070 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2071 = "cute.static"() : () -> !cute.layout<"1:0">
        %2072 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2073 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2074 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2075 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2076 = "cute.get_scalars"(%2073) : (!cute.int_tuple<"1">) -> i32
        %2077 = "cute.get_scalars"(%2074) : (!cute.int_tuple<"1">) -> i32
        %2078 = "cute.get_scalars"(%2075) : (!cute.int_tuple<"8">) -> i32
        %2079 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2080 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2079, %2076, %2080) ({
        ^bb0(%arg72: i32):
          "scf.for"(%2079, %2077, %2080) ({
          ^bb0(%arg73: i32):
            "scf.for"(%2079, %2078, %2080) ({
            ^bb0(%arg74: i32):
              %5167 = "cute.make_coord"(%arg74, %arg72) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5168 = "cute.make_coord"(%arg73, %arg74) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5169 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %5170 = "cute.static"() : () -> !cute.int_tuple<"0">
              %5171 = "cute.add_offset"(%2067, %5170) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %5172 = "cute.make_view"(%5171, %5169) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %5173 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5174 = "cute.crd2idx"(%5167, %2072) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %5175 = "cute.add_offset"(%2068, %5174) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %5176 = "cute.make_view"(%5175, %5173) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %5177 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5178 = "cute.crd2idx"(%5168, %2070) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %5179 = "cute.add_offset"(%2069, %5178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %5180 = "cute.make_view"(%5179, %5177) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %5181 = "cute.get_iter"(%5172) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %5182 = "cute.get_iter"(%5176) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %5183 = "cute.get_iter"(%5180) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %5184 = "builtin.unrealized_conversion_cast"(%5181) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %5185 = "llvm.load"(%5184) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5186 = "llvm.getelementptr"(%5184) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5187 = "llvm.load"(%5186) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5188 = "llvm.getelementptr"(%5184) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5189 = "llvm.load"(%5188) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5190 = "llvm.getelementptr"(%5184) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5191 = "llvm.load"(%5190) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5192 = "builtin.unrealized_conversion_cast"(%5182) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %5193 = "llvm.load"(%5192) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5194 = "llvm.getelementptr"(%5192) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5195 = "llvm.load"(%5194) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5196 = "builtin.unrealized_conversion_cast"(%5183) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %5197 = "llvm.load"(%5196) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5198 = "llvm.getelementptr"(%5196) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5199 = "llvm.load"(%5198) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5200 = "llvm.getelementptr"(%5196) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5201 = "llvm.load"(%5200) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5202 = "llvm.getelementptr"(%5196) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5203 = "llvm.load"(%5202) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5204:4 = "cute_nvgpu.arch.mma.SM80"(%5185, %5187, %5189, %5191, %5193, %5195, %5197, %5199, %5201, %5203) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %5205 = "builtin.unrealized_conversion_cast"(%5183) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%5204#0, %5205) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5206 = "llvm.getelementptr"(%5205) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5204#1, %5206) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5207 = "llvm.getelementptr"(%5205) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5204#2, %5207) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5208 = "llvm.getelementptr"(%5205) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5204#3, %5208) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %5050 = "cute.static"() : () -> !cute.coord<"(_,_,3)">
          %5051 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %5052 = "cute.crd2idx"(%5050, %5051) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %5053 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %5054 = "cute.add_offset"(%5053, %5052) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %5055 = "cute.make_view"(%5054) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %5056 = "cute.get_iter"(%5055) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5057 = "cute.static"() : () -> !cute.int_tuple<"48">
          %5058 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %5059 = "cute.add_offset"(%5058, %5057) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
          %5060 = "cute.make_view"(%5059) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %5061 = "cute.get_iter"(%5060) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5062 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5063 = "cute.make_view"(%5056, %5062) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %5064 = "cute.get_iter"(%5063) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %5065 = "cute.make_view"(%5064) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %5066 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %5067 = "cute.make_view"(%5061, %5066) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %5068 = "cute.get_iter"(%5067) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %5069 = "cute.make_view"(%5068) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %5070 = "cute.static"() : () -> !cute.layout<"1:0">
          %5071 = "cute.get_iter"(%5065) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %5072 = "cute.get_iter"(%5069) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %5073 = "cute.static"() : () -> !cute.int_tuple<"1">
          %5074 = "cute.get_scalars"(%5073) : (!cute.int_tuple<"1">) -> i32
          %5075 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5076 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5075, %5074, %5076) ({
          ^bb0(%arg71: i32):
            %5137 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5138 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5139 = "cute.add_offset"(%5071, %5138) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %5140 = "cute.make_view"(%5139, %5137) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5141 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5142 = "cute.static"() : () -> !cute.int_tuple<"0">
            %5143 = "cute.add_offset"(%5072, %5142) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %5144 = "cute.make_view"(%5143, %5141) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %5145 = "cute.get_iter"(%5140) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5146 = "cute.get_iter"(%5144) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %5147 = "cute.apply_swizzle"(%5145) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5148 = "cute_nvgpu.arch.copy.ldsm"(%5147) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5149 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5150 = "vector.extractelement"(%5148, %5149) : (vector<4xi32>, i32) -> i32
            %5151 = "builtin.unrealized_conversion_cast"(%5146) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%5150, %5151) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5152 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5153 = "vector.extractelement"(%5148, %5152) : (vector<4xi32>, i32) -> i32
            %5154 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5155 = "cute.add_offset"(%5146, %5154) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5156 = "builtin.unrealized_conversion_cast"(%5155) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5153, %5156) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5157 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5158 = "vector.extractelement"(%5148, %5157) : (vector<4xi32>, i32) -> i32
            %5159 = "cute.static"() : () -> !cute.int_tuple<"4">
            %5160 = "cute.add_offset"(%5146, %5159) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %5161 = "builtin.unrealized_conversion_cast"(%5160) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5158, %5161) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5162 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5163 = "vector.extractelement"(%5148, %5162) : (vector<4xi32>, i32) -> i32
            %5164 = "cute.static"() : () -> !cute.int_tuple<"6">
            %5165 = "cute.add_offset"(%5146, %5164) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %5166 = "builtin.unrealized_conversion_cast"(%5165) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5163, %5166) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %5077 = "cute.static"() : () -> !cute.coord<"(_,_,3)">
          %5078 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %5079 = "cute.crd2idx"(%5077, %5078) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %5080 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %5081 = "cute.add_offset"(%5080, %5079) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %5082 = "cute.make_view"(%5081) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %5083 = "cute.get_iter"(%5082) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5084 = "cute.static"() : () -> !cute.int_tuple<"192">
          %5085 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %5086 = "cute.add_offset"(%5085, %5084) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
          %5087 = "cute.make_view"(%5086) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %5088 = "cute.get_iter"(%5087) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5089 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %5090 = "cute.make_view"(%5083, %5089) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %5091 = "cute.get_iter"(%5090) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %5092 = "cute.make_view"(%5091) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %5093 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %5094 = "cute.make_view"(%5088, %5093) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %5095 = "cute.get_iter"(%5094) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %5096 = "cute.make_view"(%5095) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %5097 = "cute.static"() : () -> !cute.layout<"1:0">
          %5098 = "cute.get_iter"(%5092) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %5099 = "cute.get_iter"(%5096) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %5100 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %5101 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %5102 = "cute.static"() : () -> !cute.int_tuple<"4">
          %5103 = "cute.get_scalars"(%5102) : (!cute.int_tuple<"4">) -> i32
          %5104 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %5105 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%5104, %5103, %5105) ({
          ^bb0(%arg70: i32):
            %5106 = "cute.make_coord"(%arg70) : (i32) -> !cute.coord<"(_,?)">
            %5107 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %5108 = "cute.crd2idx"(%5106, %5100) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %5109 = "cute.add_offset"(%5098, %5108) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %5110 = "cute.make_view"(%5109, %5107) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %5111 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %5112 = "cute.crd2idx"(%5106, %5101) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %5113 = "cute.add_offset"(%5099, %5112) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %5114 = "cute.make_view"(%5113, %5111) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %5115 = "cute.get_iter"(%5110) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %5116 = "cute.get_iter"(%5114) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %5117 = "cute.apply_swizzle"(%5115) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %5118 = "cute_nvgpu.arch.copy.ldsm"(%5117) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %5119 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %5120 = "vector.extractelement"(%5118, %5119) : (vector<4xi32>, i32) -> i32
            %5121 = "builtin.unrealized_conversion_cast"(%5116) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5120, %5121) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5122 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %5123 = "vector.extractelement"(%5118, %5122) : (vector<4xi32>, i32) -> i32
            %5124 = "cute.static"() : () -> !cute.int_tuple<"2">
            %5125 = "cute.add_offset"(%5116, %5124) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %5126 = "builtin.unrealized_conversion_cast"(%5125) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5123, %5126) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5127 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %5128 = "vector.extractelement"(%5118, %5127) : (vector<4xi32>, i32) -> i32
            %5129 = "cute.static"() : () -> !cute.int_tuple<"32">
            %5130 = "cute.add_offset"(%5116, %5129) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %5131 = "builtin.unrealized_conversion_cast"(%5130) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%5128, %5131) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5132 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5133 = "vector.extractelement"(%5118, %5132) : (vector<4xi32>, i32) -> i32
            %5134 = "cute.static"() : () -> !cute.int_tuple<"34">
            %5135 = "cute.add_offset"(%5116, %5134) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %5136 = "builtin.unrealized_conversion_cast"(%5135) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5133, %5136) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2081 = "cute.static"() : () -> !cute.int_tuple<"32">
        %2082 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2083 = "cute.add_offset"(%2082, %2081) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        %2084 = "cute.make_view"(%2083) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2085 = "cute.static"() : () -> !cute.int_tuple<"128">
        %2086 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2087 = "cute.add_offset"(%2086, %2085) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        %2088 = "cute.make_view"(%2087) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2089 = "cute.get_iter"(%2084) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2090 = "cute.get_iter"(%2088) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2091 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2092 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2093 = "cute.static"() : () -> !cute.layout<"1:0">
        %2094 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2095 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2096 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2097 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2098 = "cute.get_scalars"(%2095) : (!cute.int_tuple<"1">) -> i32
        %2099 = "cute.get_scalars"(%2096) : (!cute.int_tuple<"1">) -> i32
        %2100 = "cute.get_scalars"(%2097) : (!cute.int_tuple<"8">) -> i32
        %2101 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2102 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2101, %2098, %2102) ({
        ^bb0(%arg67: i32):
          "scf.for"(%2101, %2099, %2102) ({
          ^bb0(%arg68: i32):
            "scf.for"(%2101, %2100, %2102) ({
            ^bb0(%arg69: i32):
              %5008 = "cute.make_coord"(%arg69, %arg67) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5009 = "cute.make_coord"(%arg68, %arg69) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %5010 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %5011 = "cute.static"() : () -> !cute.int_tuple<"0">
              %5012 = "cute.add_offset"(%2089, %5011) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %5013 = "cute.make_view"(%5012, %5010) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %5014 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5015 = "cute.crd2idx"(%5008, %2094) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %5016 = "cute.add_offset"(%2090, %5015) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %5017 = "cute.make_view"(%5016, %5014) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %5018 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %5019 = "cute.crd2idx"(%5009, %2092) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %5020 = "cute.add_offset"(%2091, %5019) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %5021 = "cute.make_view"(%5020, %5018) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %5022 = "cute.get_iter"(%5013) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %5023 = "cute.get_iter"(%5017) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %5024 = "cute.get_iter"(%5021) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %5025 = "builtin.unrealized_conversion_cast"(%5022) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %5026 = "llvm.load"(%5025) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5027 = "llvm.getelementptr"(%5025) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5028 = "llvm.load"(%5027) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5029 = "llvm.getelementptr"(%5025) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5030 = "llvm.load"(%5029) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5031 = "llvm.getelementptr"(%5025) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5032 = "llvm.load"(%5031) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5033 = "builtin.unrealized_conversion_cast"(%5023) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %5034 = "llvm.load"(%5033) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5035 = "llvm.getelementptr"(%5033) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5036 = "llvm.load"(%5035) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %5037 = "builtin.unrealized_conversion_cast"(%5024) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %5038 = "llvm.load"(%5037) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5039 = "llvm.getelementptr"(%5037) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %5040 = "llvm.load"(%5039) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5041 = "llvm.getelementptr"(%5037) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %5042 = "llvm.load"(%5041) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5043 = "llvm.getelementptr"(%5037) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %5044 = "llvm.load"(%5043) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %5045:4 = "cute_nvgpu.arch.mma.SM80"(%5026, %5028, %5030, %5032, %5034, %5036, %5038, %5040, %5042, %5044) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %5046 = "builtin.unrealized_conversion_cast"(%5024) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%5045#0, %5046) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5047 = "llvm.getelementptr"(%5046) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5045#1, %5047) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5048 = "llvm.getelementptr"(%5046) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5045#2, %5048) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %5049 = "llvm.getelementptr"(%5046) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%5045#3, %5049) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %4895 = "cute.static"() : () -> !cute.int_tuple<"4096">
          %4896 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %4897 = "cute.add_offset"(%4896, %4895) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
          %4898 = "cute.make_view"(%4897) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %4899 = "cute.get_iter"(%4898) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4900 = "cute.static"() : () -> !cute.int_tuple<"8">
          %4901 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %4902 = "cute.add_offset"(%4901, %4900) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %4903 = "cute.make_view"(%4902) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %4904 = "cute.get_iter"(%4903) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4905 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4906 = "cute.make_view"(%4899, %4905) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %4907 = "cute.get_iter"(%4906) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4908 = "cute.make_view"(%4907) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %4909 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4910 = "cute.make_view"(%4904, %4909) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %4911 = "cute.get_iter"(%4910) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4912 = "cute.make_view"(%4911) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %4913 = "cute.static"() : () -> !cute.layout<"1:0">
          %4914 = "cute.get_iter"(%4908) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %4915 = "cute.get_iter"(%4912) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %4916 = "cute.static"() : () -> !cute.int_tuple<"1">
          %4917 = "cute.get_scalars"(%4916) : (!cute.int_tuple<"1">) -> i32
          %4918 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4919 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4918, %4917, %4919) ({
          ^bb0(%arg66: i32):
            %4978 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4979 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4980 = "cute.add_offset"(%4914, %4979) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4981 = "cute.make_view"(%4980, %4978) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4982 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4983 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4984 = "cute.add_offset"(%4915, %4983) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %4985 = "cute.make_view"(%4984, %4982) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %4986 = "cute.get_iter"(%4981) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4987 = "cute.get_iter"(%4985) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %4988 = "cute.apply_swizzle"(%4986) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4989 = "cute_nvgpu.arch.copy.ldsm"(%4988) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4990 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4991 = "vector.extractelement"(%4989, %4990) : (vector<4xi32>, i32) -> i32
            %4992 = "builtin.unrealized_conversion_cast"(%4987) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%4991, %4992) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4993 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4994 = "vector.extractelement"(%4989, %4993) : (vector<4xi32>, i32) -> i32
            %4995 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4996 = "cute.add_offset"(%4987, %4995) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4997 = "builtin.unrealized_conversion_cast"(%4996) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4994, %4997) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4998 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4999 = "vector.extractelement"(%4989, %4998) : (vector<4xi32>, i32) -> i32
            %5000 = "cute.static"() : () -> !cute.int_tuple<"4">
            %5001 = "cute.add_offset"(%4987, %5000) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %5002 = "builtin.unrealized_conversion_cast"(%5001) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4999, %5002) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %5003 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %5004 = "vector.extractelement"(%4989, %5003) : (vector<4xi32>, i32) -> i32
            %5005 = "cute.static"() : () -> !cute.int_tuple<"6">
            %5006 = "cute.add_offset"(%4987, %5005) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %5007 = "builtin.unrealized_conversion_cast"(%5006) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%5004, %5007) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %4920 = "cute.static"() : () -> !cute.int_tuple<"4096">
          %4921 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %4922 = "cute.add_offset"(%4921, %4920) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
          %4923 = "cute.make_view"(%4922) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %4924 = "cute.get_iter"(%4923) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4925 = "cute.static"() : () -> !cute.int_tuple<"16">
          %4926 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %4927 = "cute.add_offset"(%4926, %4925) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
          %4928 = "cute.make_view"(%4927) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %4929 = "cute.get_iter"(%4928) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4930 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %4931 = "cute.make_view"(%4924, %4930) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %4932 = "cute.get_iter"(%4931) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4933 = "cute.make_view"(%4932) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %4934 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %4935 = "cute.make_view"(%4929, %4934) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %4936 = "cute.get_iter"(%4935) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4937 = "cute.make_view"(%4936) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %4938 = "cute.static"() : () -> !cute.layout<"1:0">
          %4939 = "cute.get_iter"(%4933) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %4940 = "cute.get_iter"(%4937) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %4941 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %4942 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %4943 = "cute.static"() : () -> !cute.int_tuple<"4">
          %4944 = "cute.get_scalars"(%4943) : (!cute.int_tuple<"4">) -> i32
          %4945 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4946 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4945, %4944, %4946) ({
          ^bb0(%arg65: i32):
            %4947 = "cute.make_coord"(%arg65) : (i32) -> !cute.coord<"(_,?)">
            %4948 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4949 = "cute.crd2idx"(%4947, %4941) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %4950 = "cute.add_offset"(%4939, %4949) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4951 = "cute.make_view"(%4950, %4948) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4952 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %4953 = "cute.crd2idx"(%4947, %4942) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %4954 = "cute.add_offset"(%4940, %4953) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %4955 = "cute.make_view"(%4954, %4952) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %4956 = "cute.get_iter"(%4951) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4957 = "cute.get_iter"(%4955) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %4958 = "cute.apply_swizzle"(%4956) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4959 = "cute_nvgpu.arch.copy.ldsm"(%4958) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4960 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4961 = "vector.extractelement"(%4959, %4960) : (vector<4xi32>, i32) -> i32
            %4962 = "builtin.unrealized_conversion_cast"(%4957) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4961, %4962) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4963 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4964 = "vector.extractelement"(%4959, %4963) : (vector<4xi32>, i32) -> i32
            %4965 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4966 = "cute.add_offset"(%4957, %4965) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4967 = "builtin.unrealized_conversion_cast"(%4966) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4964, %4967) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4968 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4969 = "vector.extractelement"(%4959, %4968) : (vector<4xi32>, i32) -> i32
            %4970 = "cute.static"() : () -> !cute.int_tuple<"32">
            %4971 = "cute.add_offset"(%4957, %4970) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %4972 = "builtin.unrealized_conversion_cast"(%4971) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4969, %4972) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4973 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4974 = "vector.extractelement"(%4959, %4973) : (vector<4xi32>, i32) -> i32
            %4975 = "cute.static"() : () -> !cute.int_tuple<"34">
            %4976 = "cute.add_offset"(%4957, %4975) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %4977 = "builtin.unrealized_conversion_cast"(%4976) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4974, %4977) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2103 = "cute.static"() : () -> !cute.int_tuple<"48">
        %2104 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2105 = "cute.add_offset"(%2104, %2103) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        %2106 = "cute.make_view"(%2105) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2107 = "cute.static"() : () -> !cute.int_tuple<"192">
        %2108 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2109 = "cute.add_offset"(%2108, %2107) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        %2110 = "cute.make_view"(%2109) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2111 = "cute.get_iter"(%2106) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2112 = "cute.get_iter"(%2110) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2113 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2114 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2115 = "cute.static"() : () -> !cute.layout<"1:0">
        %2116 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2117 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2118 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2119 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2120 = "cute.get_scalars"(%2117) : (!cute.int_tuple<"1">) -> i32
        %2121 = "cute.get_scalars"(%2118) : (!cute.int_tuple<"1">) -> i32
        %2122 = "cute.get_scalars"(%2119) : (!cute.int_tuple<"8">) -> i32
        %2123 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2124 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2123, %2120, %2124) ({
        ^bb0(%arg62: i32):
          "scf.for"(%2123, %2121, %2124) ({
          ^bb0(%arg63: i32):
            "scf.for"(%2123, %2122, %2124) ({
            ^bb0(%arg64: i32):
              %4853 = "cute.make_coord"(%arg64, %arg62) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4854 = "cute.make_coord"(%arg63, %arg64) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4855 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %4856 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4857 = "cute.add_offset"(%2111, %4856) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %4858 = "cute.make_view"(%4857, %4855) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %4859 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4860 = "cute.crd2idx"(%4853, %2116) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %4861 = "cute.add_offset"(%2112, %4860) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %4862 = "cute.make_view"(%4861, %4859) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %4863 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4864 = "cute.crd2idx"(%4854, %2114) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %4865 = "cute.add_offset"(%2113, %4864) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %4866 = "cute.make_view"(%4865, %4863) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %4867 = "cute.get_iter"(%4858) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %4868 = "cute.get_iter"(%4862) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %4869 = "cute.get_iter"(%4866) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %4870 = "builtin.unrealized_conversion_cast"(%4867) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %4871 = "llvm.load"(%4870) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4872 = "llvm.getelementptr"(%4870) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4873 = "llvm.load"(%4872) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4874 = "llvm.getelementptr"(%4870) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4875 = "llvm.load"(%4874) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4876 = "llvm.getelementptr"(%4870) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4877 = "llvm.load"(%4876) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4878 = "builtin.unrealized_conversion_cast"(%4868) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %4879 = "llvm.load"(%4878) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4880 = "llvm.getelementptr"(%4878) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4881 = "llvm.load"(%4880) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4882 = "builtin.unrealized_conversion_cast"(%4869) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %4883 = "llvm.load"(%4882) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4884 = "llvm.getelementptr"(%4882) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4885 = "llvm.load"(%4884) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4886 = "llvm.getelementptr"(%4882) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4887 = "llvm.load"(%4886) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4888 = "llvm.getelementptr"(%4882) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4889 = "llvm.load"(%4888) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4890:4 = "cute_nvgpu.arch.mma.SM80"(%4871, %4873, %4875, %4877, %4879, %4881, %4883, %4885, %4887, %4889) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %4891 = "builtin.unrealized_conversion_cast"(%4869) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%4890#0, %4891) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4892 = "llvm.getelementptr"(%4891) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4890#1, %4892) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4893 = "llvm.getelementptr"(%4891) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4890#2, %4893) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4894 = "llvm.getelementptr"(%4891) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4890#3, %4894) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %4736 = "cute.static"() : () -> !cute.coord<"(_,_,5)">
          %4737 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %4738 = "cute.crd2idx"(%4736, %4737) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %4739 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %4740 = "cute.add_offset"(%4739, %4738) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %4741 = "cute.make_view"(%4740) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %4742 = "cute.get_iter"(%4741) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4743 = "cute.static"() : () -> !cute.int_tuple<"24">
          %4744 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %4745 = "cute.add_offset"(%4744, %4743) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %4746 = "cute.make_view"(%4745) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %4747 = "cute.get_iter"(%4746) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4748 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4749 = "cute.make_view"(%4742, %4748) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %4750 = "cute.get_iter"(%4749) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4751 = "cute.make_view"(%4750) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %4752 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4753 = "cute.make_view"(%4747, %4752) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %4754 = "cute.get_iter"(%4753) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4755 = "cute.make_view"(%4754) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %4756 = "cute.static"() : () -> !cute.layout<"1:0">
          %4757 = "cute.get_iter"(%4751) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %4758 = "cute.get_iter"(%4755) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %4759 = "cute.static"() : () -> !cute.int_tuple<"1">
          %4760 = "cute.get_scalars"(%4759) : (!cute.int_tuple<"1">) -> i32
          %4761 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4762 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4761, %4760, %4762) ({
          ^bb0(%arg61: i32):
            %4823 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4824 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4825 = "cute.add_offset"(%4757, %4824) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4826 = "cute.make_view"(%4825, %4823) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4827 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4828 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4829 = "cute.add_offset"(%4758, %4828) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %4830 = "cute.make_view"(%4829, %4827) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %4831 = "cute.get_iter"(%4826) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4832 = "cute.get_iter"(%4830) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %4833 = "cute.apply_swizzle"(%4831) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4834 = "cute_nvgpu.arch.copy.ldsm"(%4833) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4835 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4836 = "vector.extractelement"(%4834, %4835) : (vector<4xi32>, i32) -> i32
            %4837 = "builtin.unrealized_conversion_cast"(%4832) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%4836, %4837) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4838 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4839 = "vector.extractelement"(%4834, %4838) : (vector<4xi32>, i32) -> i32
            %4840 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4841 = "cute.add_offset"(%4832, %4840) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4842 = "builtin.unrealized_conversion_cast"(%4841) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4839, %4842) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4843 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4844 = "vector.extractelement"(%4834, %4843) : (vector<4xi32>, i32) -> i32
            %4845 = "cute.static"() : () -> !cute.int_tuple<"4">
            %4846 = "cute.add_offset"(%4832, %4845) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %4847 = "builtin.unrealized_conversion_cast"(%4846) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4844, %4847) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4848 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4849 = "vector.extractelement"(%4834, %4848) : (vector<4xi32>, i32) -> i32
            %4850 = "cute.static"() : () -> !cute.int_tuple<"6">
            %4851 = "cute.add_offset"(%4832, %4850) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %4852 = "builtin.unrealized_conversion_cast"(%4851) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4849, %4852) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %4763 = "cute.static"() : () -> !cute.coord<"(_,_,5)">
          %4764 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %4765 = "cute.crd2idx"(%4763, %4764) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %4766 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %4767 = "cute.add_offset"(%4766, %4765) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %4768 = "cute.make_view"(%4767) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %4769 = "cute.get_iter"(%4768) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4770 = "cute.static"() : () -> !cute.int_tuple<"80">
          %4771 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %4772 = "cute.add_offset"(%4771, %4770) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
          %4773 = "cute.make_view"(%4772) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %4774 = "cute.get_iter"(%4773) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4775 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %4776 = "cute.make_view"(%4769, %4775) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %4777 = "cute.get_iter"(%4776) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4778 = "cute.make_view"(%4777) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %4779 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %4780 = "cute.make_view"(%4774, %4779) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %4781 = "cute.get_iter"(%4780) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4782 = "cute.make_view"(%4781) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %4783 = "cute.static"() : () -> !cute.layout<"1:0">
          %4784 = "cute.get_iter"(%4778) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %4785 = "cute.get_iter"(%4782) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %4786 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %4787 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %4788 = "cute.static"() : () -> !cute.int_tuple<"4">
          %4789 = "cute.get_scalars"(%4788) : (!cute.int_tuple<"4">) -> i32
          %4790 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4791 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4790, %4789, %4791) ({
          ^bb0(%arg60: i32):
            %4792 = "cute.make_coord"(%arg60) : (i32) -> !cute.coord<"(_,?)">
            %4793 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4794 = "cute.crd2idx"(%4792, %4786) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %4795 = "cute.add_offset"(%4784, %4794) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4796 = "cute.make_view"(%4795, %4793) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4797 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %4798 = "cute.crd2idx"(%4792, %4787) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %4799 = "cute.add_offset"(%4785, %4798) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %4800 = "cute.make_view"(%4799, %4797) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %4801 = "cute.get_iter"(%4796) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4802 = "cute.get_iter"(%4800) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %4803 = "cute.apply_swizzle"(%4801) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4804 = "cute_nvgpu.arch.copy.ldsm"(%4803) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4805 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4806 = "vector.extractelement"(%4804, %4805) : (vector<4xi32>, i32) -> i32
            %4807 = "builtin.unrealized_conversion_cast"(%4802) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4806, %4807) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4808 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4809 = "vector.extractelement"(%4804, %4808) : (vector<4xi32>, i32) -> i32
            %4810 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4811 = "cute.add_offset"(%4802, %4810) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4812 = "builtin.unrealized_conversion_cast"(%4811) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4809, %4812) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4813 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4814 = "vector.extractelement"(%4804, %4813) : (vector<4xi32>, i32) -> i32
            %4815 = "cute.static"() : () -> !cute.int_tuple<"32">
            %4816 = "cute.add_offset"(%4802, %4815) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %4817 = "builtin.unrealized_conversion_cast"(%4816) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4814, %4817) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4818 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4819 = "vector.extractelement"(%4804, %4818) : (vector<4xi32>, i32) -> i32
            %4820 = "cute.static"() : () -> !cute.int_tuple<"34">
            %4821 = "cute.add_offset"(%4802, %4820) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %4822 = "builtin.unrealized_conversion_cast"(%4821) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4819, %4822) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2125 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2126 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2127 = "cute.add_offset"(%2126, %2125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %2128 = "cute.make_view"(%2127) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2129 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2130 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2131 = "cute.add_offset"(%2130, %2129) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
        %2132 = "cute.make_view"(%2131) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2133 = "cute.get_iter"(%2128) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2134 = "cute.get_iter"(%2132) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2135 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2136 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2137 = "cute.static"() : () -> !cute.layout<"1:0">
        %2138 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2139 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2140 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2141 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2142 = "cute.get_scalars"(%2139) : (!cute.int_tuple<"1">) -> i32
        %2143 = "cute.get_scalars"(%2140) : (!cute.int_tuple<"1">) -> i32
        %2144 = "cute.get_scalars"(%2141) : (!cute.int_tuple<"8">) -> i32
        %2145 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2146 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2145, %2142, %2146) ({
        ^bb0(%arg57: i32):
          "scf.for"(%2145, %2143, %2146) ({
          ^bb0(%arg58: i32):
            "scf.for"(%2145, %2144, %2146) ({
            ^bb0(%arg59: i32):
              %4694 = "cute.make_coord"(%arg59, %arg57) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4695 = "cute.make_coord"(%arg58, %arg59) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4696 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %4697 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4698 = "cute.add_offset"(%2133, %4697) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %4699 = "cute.make_view"(%4698, %4696) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %4700 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4701 = "cute.crd2idx"(%4694, %2138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %4702 = "cute.add_offset"(%2134, %4701) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %4703 = "cute.make_view"(%4702, %4700) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %4704 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4705 = "cute.crd2idx"(%4695, %2136) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %4706 = "cute.add_offset"(%2135, %4705) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %4707 = "cute.make_view"(%4706, %4704) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %4708 = "cute.get_iter"(%4699) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %4709 = "cute.get_iter"(%4703) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %4710 = "cute.get_iter"(%4707) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %4711 = "builtin.unrealized_conversion_cast"(%4708) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %4712 = "llvm.load"(%4711) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4713 = "llvm.getelementptr"(%4711) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4714 = "llvm.load"(%4713) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4715 = "llvm.getelementptr"(%4711) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4716 = "llvm.load"(%4715) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4717 = "llvm.getelementptr"(%4711) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4718 = "llvm.load"(%4717) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4719 = "builtin.unrealized_conversion_cast"(%4709) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %4720 = "llvm.load"(%4719) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4721 = "llvm.getelementptr"(%4719) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4722 = "llvm.load"(%4721) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4723 = "builtin.unrealized_conversion_cast"(%4710) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %4724 = "llvm.load"(%4723) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4725 = "llvm.getelementptr"(%4723) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4726 = "llvm.load"(%4725) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4727 = "llvm.getelementptr"(%4723) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4728 = "llvm.load"(%4727) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4729 = "llvm.getelementptr"(%4723) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4730 = "llvm.load"(%4729) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4731:4 = "cute_nvgpu.arch.mma.SM80"(%4712, %4714, %4716, %4718, %4720, %4722, %4724, %4726, %4728, %4730) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %4732 = "builtin.unrealized_conversion_cast"(%4710) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%4731#0, %4732) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4733 = "llvm.getelementptr"(%4732) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4731#1, %4733) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4734 = "llvm.getelementptr"(%4732) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4731#2, %4734) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4735 = "llvm.getelementptr"(%4732) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4731#3, %4735) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %4577 = "cute.static"() : () -> !cute.coord<"(_,_,6)">
          %4578 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %4579 = "cute.crd2idx"(%4577, %4578) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
          %4580 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %4581 = "cute.add_offset"(%4580, %4579) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
          %4582 = "cute.make_view"(%4581) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %4583 = "cute.get_iter"(%4582) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4584 = "cute.static"() : () -> !cute.int_tuple<"40">
          %4585 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %4586 = "cute.add_offset"(%4585, %4584) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %4587 = "cute.make_view"(%4586) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %4588 = "cute.get_iter"(%4587) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4589 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4590 = "cute.make_view"(%4583, %4589) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %4591 = "cute.get_iter"(%4590) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4592 = "cute.make_view"(%4591) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %4593 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4594 = "cute.make_view"(%4588, %4593) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %4595 = "cute.get_iter"(%4594) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4596 = "cute.make_view"(%4595) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %4597 = "cute.static"() : () -> !cute.layout<"1:0">
          %4598 = "cute.get_iter"(%4592) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %4599 = "cute.get_iter"(%4596) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %4600 = "cute.static"() : () -> !cute.int_tuple<"1">
          %4601 = "cute.get_scalars"(%4600) : (!cute.int_tuple<"1">) -> i32
          %4602 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4603 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4602, %4601, %4603) ({
          ^bb0(%arg56: i32):
            %4664 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4665 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4666 = "cute.add_offset"(%4598, %4665) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4667 = "cute.make_view"(%4666, %4664) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4668 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4669 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4670 = "cute.add_offset"(%4599, %4669) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %4671 = "cute.make_view"(%4670, %4668) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %4672 = "cute.get_iter"(%4667) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4673 = "cute.get_iter"(%4671) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %4674 = "cute.apply_swizzle"(%4672) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4675 = "cute_nvgpu.arch.copy.ldsm"(%4674) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4676 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4677 = "vector.extractelement"(%4675, %4676) : (vector<4xi32>, i32) -> i32
            %4678 = "builtin.unrealized_conversion_cast"(%4673) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%4677, %4678) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4679 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4680 = "vector.extractelement"(%4675, %4679) : (vector<4xi32>, i32) -> i32
            %4681 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4682 = "cute.add_offset"(%4673, %4681) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4683 = "builtin.unrealized_conversion_cast"(%4682) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4680, %4683) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4684 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4685 = "vector.extractelement"(%4675, %4684) : (vector<4xi32>, i32) -> i32
            %4686 = "cute.static"() : () -> !cute.int_tuple<"4">
            %4687 = "cute.add_offset"(%4673, %4686) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %4688 = "builtin.unrealized_conversion_cast"(%4687) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4685, %4688) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4689 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4690 = "vector.extractelement"(%4675, %4689) : (vector<4xi32>, i32) -> i32
            %4691 = "cute.static"() : () -> !cute.int_tuple<"6">
            %4692 = "cute.add_offset"(%4673, %4691) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %4693 = "builtin.unrealized_conversion_cast"(%4692) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4690, %4693) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %4604 = "cute.static"() : () -> !cute.coord<"(_,_,6)">
          %4605 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %4606 = "cute.crd2idx"(%4604, %4605) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
          %4607 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %4608 = "cute.add_offset"(%4607, %4606) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
          %4609 = "cute.make_view"(%4608) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %4610 = "cute.get_iter"(%4609) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4611 = "cute.static"() : () -> !cute.int_tuple<"144">
          %4612 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %4613 = "cute.add_offset"(%4612, %4611) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
          %4614 = "cute.make_view"(%4613) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %4615 = "cute.get_iter"(%4614) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4616 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %4617 = "cute.make_view"(%4610, %4616) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %4618 = "cute.get_iter"(%4617) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4619 = "cute.make_view"(%4618) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %4620 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %4621 = "cute.make_view"(%4615, %4620) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %4622 = "cute.get_iter"(%4621) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4623 = "cute.make_view"(%4622) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %4624 = "cute.static"() : () -> !cute.layout<"1:0">
          %4625 = "cute.get_iter"(%4619) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %4626 = "cute.get_iter"(%4623) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %4627 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %4628 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %4629 = "cute.static"() : () -> !cute.int_tuple<"4">
          %4630 = "cute.get_scalars"(%4629) : (!cute.int_tuple<"4">) -> i32
          %4631 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4632 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4631, %4630, %4632) ({
          ^bb0(%arg55: i32):
            %4633 = "cute.make_coord"(%arg55) : (i32) -> !cute.coord<"(_,?)">
            %4634 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4635 = "cute.crd2idx"(%4633, %4627) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %4636 = "cute.add_offset"(%4625, %4635) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4637 = "cute.make_view"(%4636, %4634) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4638 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %4639 = "cute.crd2idx"(%4633, %4628) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %4640 = "cute.add_offset"(%4626, %4639) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %4641 = "cute.make_view"(%4640, %4638) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %4642 = "cute.get_iter"(%4637) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4643 = "cute.get_iter"(%4641) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %4644 = "cute.apply_swizzle"(%4642) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4645 = "cute_nvgpu.arch.copy.ldsm"(%4644) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4646 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4647 = "vector.extractelement"(%4645, %4646) : (vector<4xi32>, i32) -> i32
            %4648 = "builtin.unrealized_conversion_cast"(%4643) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4647, %4648) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4649 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4650 = "vector.extractelement"(%4645, %4649) : (vector<4xi32>, i32) -> i32
            %4651 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4652 = "cute.add_offset"(%4643, %4651) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4653 = "builtin.unrealized_conversion_cast"(%4652) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4650, %4653) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4654 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4655 = "vector.extractelement"(%4645, %4654) : (vector<4xi32>, i32) -> i32
            %4656 = "cute.static"() : () -> !cute.int_tuple<"32">
            %4657 = "cute.add_offset"(%4643, %4656) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %4658 = "builtin.unrealized_conversion_cast"(%4657) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4655, %4658) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4659 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4660 = "vector.extractelement"(%4645, %4659) : (vector<4xi32>, i32) -> i32
            %4661 = "cute.static"() : () -> !cute.int_tuple<"34">
            %4662 = "cute.add_offset"(%4643, %4661) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %4663 = "builtin.unrealized_conversion_cast"(%4662) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4660, %4663) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2147 = "cute.static"() : () -> !cute.int_tuple<"24">
        %2148 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2149 = "cute.add_offset"(%2148, %2147) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %2150 = "cute.make_view"(%2149) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2151 = "cute.static"() : () -> !cute.int_tuple<"80">
        %2152 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2153 = "cute.add_offset"(%2152, %2151) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
        %2154 = "cute.make_view"(%2153) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2155 = "cute.get_iter"(%2150) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2156 = "cute.get_iter"(%2154) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2157 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2158 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2159 = "cute.static"() : () -> !cute.layout<"1:0">
        %2160 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2161 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2162 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2163 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2164 = "cute.get_scalars"(%2161) : (!cute.int_tuple<"1">) -> i32
        %2165 = "cute.get_scalars"(%2162) : (!cute.int_tuple<"1">) -> i32
        %2166 = "cute.get_scalars"(%2163) : (!cute.int_tuple<"8">) -> i32
        %2167 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2168 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2167, %2164, %2168) ({
        ^bb0(%arg52: i32):
          "scf.for"(%2167, %2165, %2168) ({
          ^bb0(%arg53: i32):
            "scf.for"(%2167, %2166, %2168) ({
            ^bb0(%arg54: i32):
              %4535 = "cute.make_coord"(%arg54, %arg52) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4536 = "cute.make_coord"(%arg53, %arg54) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4537 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %4538 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4539 = "cute.add_offset"(%2155, %4538) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %4540 = "cute.make_view"(%4539, %4537) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %4541 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4542 = "cute.crd2idx"(%4535, %2160) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %4543 = "cute.add_offset"(%2156, %4542) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %4544 = "cute.make_view"(%4543, %4541) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %4545 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4546 = "cute.crd2idx"(%4536, %2158) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %4547 = "cute.add_offset"(%2157, %4546) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %4548 = "cute.make_view"(%4547, %4545) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %4549 = "cute.get_iter"(%4540) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %4550 = "cute.get_iter"(%4544) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %4551 = "cute.get_iter"(%4548) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %4552 = "builtin.unrealized_conversion_cast"(%4549) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %4553 = "llvm.load"(%4552) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4554 = "llvm.getelementptr"(%4552) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4555 = "llvm.load"(%4554) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4556 = "llvm.getelementptr"(%4552) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4557 = "llvm.load"(%4556) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4558 = "llvm.getelementptr"(%4552) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4559 = "llvm.load"(%4558) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4560 = "builtin.unrealized_conversion_cast"(%4550) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %4561 = "llvm.load"(%4560) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4562 = "llvm.getelementptr"(%4560) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4563 = "llvm.load"(%4562) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4564 = "builtin.unrealized_conversion_cast"(%4551) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %4565 = "llvm.load"(%4564) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4566 = "llvm.getelementptr"(%4564) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4567 = "llvm.load"(%4566) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4568 = "llvm.getelementptr"(%4564) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4569 = "llvm.load"(%4568) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4570 = "llvm.getelementptr"(%4564) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4571 = "llvm.load"(%4570) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4572:4 = "cute_nvgpu.arch.mma.SM80"(%4553, %4555, %4557, %4559, %4561, %4563, %4565, %4567, %4569, %4571) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %4573 = "builtin.unrealized_conversion_cast"(%4551) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%4572#0, %4573) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4574 = "llvm.getelementptr"(%4573) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4572#1, %4574) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4575 = "llvm.getelementptr"(%4573) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4572#2, %4575) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4576 = "llvm.getelementptr"(%4573) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4572#3, %4576) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %4418 = "cute.static"() : () -> !cute.coord<"(_,_,7)">
          %4419 = "cute.get_layout"(%568) : (!memref_smem_bf16_5) -> !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
          %4420 = "cute.crd2idx"(%4418, %4419) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %4421 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %4422 = "cute.add_offset"(%4421, %4420) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %4423 = "cute.make_view"(%4422) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %4424 = "cute.get_iter"(%4423) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4425 = "cute.static"() : () -> !cute.int_tuple<"56">
          %4426 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %4427 = "cute.add_offset"(%4426, %4425) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %4428 = "cute.make_view"(%4427) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %4429 = "cute.get_iter"(%4428) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4430 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4431 = "cute.make_view"(%4424, %4430) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %4432 = "cute.get_iter"(%4431) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4433 = "cute.make_view"(%4432) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %4434 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4435 = "cute.make_view"(%4429, %4434) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %4436 = "cute.get_iter"(%4435) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4437 = "cute.make_view"(%4436) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %4438 = "cute.static"() : () -> !cute.layout<"1:0">
          %4439 = "cute.get_iter"(%4433) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %4440 = "cute.get_iter"(%4437) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %4441 = "cute.static"() : () -> !cute.int_tuple<"1">
          %4442 = "cute.get_scalars"(%4441) : (!cute.int_tuple<"1">) -> i32
          %4443 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4444 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4443, %4442, %4444) ({
          ^bb0(%arg51: i32):
            %4505 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4506 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4507 = "cute.add_offset"(%4439, %4506) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4508 = "cute.make_view"(%4507, %4505) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4509 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4510 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4511 = "cute.add_offset"(%4440, %4510) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %4512 = "cute.make_view"(%4511, %4509) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %4513 = "cute.get_iter"(%4508) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4514 = "cute.get_iter"(%4512) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %4515 = "cute.apply_swizzle"(%4513) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4516 = "cute_nvgpu.arch.copy.ldsm"(%4515) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4517 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4518 = "vector.extractelement"(%4516, %4517) : (vector<4xi32>, i32) -> i32
            %4519 = "builtin.unrealized_conversion_cast"(%4514) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%4518, %4519) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4520 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4521 = "vector.extractelement"(%4516, %4520) : (vector<4xi32>, i32) -> i32
            %4522 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4523 = "cute.add_offset"(%4514, %4522) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4524 = "builtin.unrealized_conversion_cast"(%4523) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4521, %4524) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4525 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4526 = "vector.extractelement"(%4516, %4525) : (vector<4xi32>, i32) -> i32
            %4527 = "cute.static"() : () -> !cute.int_tuple<"4">
            %4528 = "cute.add_offset"(%4514, %4527) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %4529 = "builtin.unrealized_conversion_cast"(%4528) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4526, %4529) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4530 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4531 = "vector.extractelement"(%4516, %4530) : (vector<4xi32>, i32) -> i32
            %4532 = "cute.static"() : () -> !cute.int_tuple<"6">
            %4533 = "cute.add_offset"(%4514, %4532) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %4534 = "builtin.unrealized_conversion_cast"(%4533) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4531, %4534) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %4445 = "cute.static"() : () -> !cute.coord<"(_,_,7)">
          %4446 = "cute.get_layout"(%619) : (!memref_smem_bf16_6) -> !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
          %4447 = "cute.crd2idx"(%4445, %4446) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
          %4448 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %4449 = "cute.add_offset"(%4448, %4447) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %4450 = "cute.make_view"(%4449) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %4451 = "cute.get_iter"(%4450) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4452 = "cute.static"() : () -> !cute.int_tuple<"208">
          %4453 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %4454 = "cute.add_offset"(%4453, %4452) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
          %4455 = "cute.make_view"(%4454) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %4456 = "cute.get_iter"(%4455) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4457 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %4458 = "cute.make_view"(%4451, %4457) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %4459 = "cute.get_iter"(%4458) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4460 = "cute.make_view"(%4459) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %4461 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %4462 = "cute.make_view"(%4456, %4461) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %4463 = "cute.get_iter"(%4462) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4464 = "cute.make_view"(%4463) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %4465 = "cute.static"() : () -> !cute.layout<"1:0">
          %4466 = "cute.get_iter"(%4460) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %4467 = "cute.get_iter"(%4464) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %4468 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %4469 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %4470 = "cute.static"() : () -> !cute.int_tuple<"4">
          %4471 = "cute.get_scalars"(%4470) : (!cute.int_tuple<"4">) -> i32
          %4472 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4473 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4472, %4471, %4473) ({
          ^bb0(%arg50: i32):
            %4474 = "cute.make_coord"(%arg50) : (i32) -> !cute.coord<"(_,?)">
            %4475 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4476 = "cute.crd2idx"(%4474, %4468) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %4477 = "cute.add_offset"(%4466, %4476) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4478 = "cute.make_view"(%4477, %4475) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4479 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %4480 = "cute.crd2idx"(%4474, %4469) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %4481 = "cute.add_offset"(%4467, %4480) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %4482 = "cute.make_view"(%4481, %4479) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %4483 = "cute.get_iter"(%4478) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4484 = "cute.get_iter"(%4482) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %4485 = "cute.apply_swizzle"(%4483) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4486 = "cute_nvgpu.arch.copy.ldsm"(%4485) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4487 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4488 = "vector.extractelement"(%4486, %4487) : (vector<4xi32>, i32) -> i32
            %4489 = "builtin.unrealized_conversion_cast"(%4484) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4488, %4489) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4490 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4491 = "vector.extractelement"(%4486, %4490) : (vector<4xi32>, i32) -> i32
            %4492 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4493 = "cute.add_offset"(%4484, %4492) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4494 = "builtin.unrealized_conversion_cast"(%4493) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4491, %4494) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4495 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4496 = "vector.extractelement"(%4486, %4495) : (vector<4xi32>, i32) -> i32
            %4497 = "cute.static"() : () -> !cute.int_tuple<"32">
            %4498 = "cute.add_offset"(%4484, %4497) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %4499 = "builtin.unrealized_conversion_cast"(%4498) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4496, %4499) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4500 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4501 = "vector.extractelement"(%4486, %4500) : (vector<4xi32>, i32) -> i32
            %4502 = "cute.static"() : () -> !cute.int_tuple<"34">
            %4503 = "cute.add_offset"(%4484, %4502) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %4504 = "builtin.unrealized_conversion_cast"(%4503) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4501, %4504) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2169 = "cute.static"() : () -> !cute.int_tuple<"40">
        %2170 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2171 = "cute.add_offset"(%2170, %2169) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        %2172 = "cute.make_view"(%2171) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2173 = "cute.static"() : () -> !cute.int_tuple<"144">
        %2174 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2175 = "cute.add_offset"(%2174, %2173) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
        %2176 = "cute.make_view"(%2175) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2177 = "cute.get_iter"(%2172) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2178 = "cute.get_iter"(%2176) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2179 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2180 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2181 = "cute.static"() : () -> !cute.layout<"1:0">
        %2182 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2183 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2184 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2185 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2186 = "cute.get_scalars"(%2183) : (!cute.int_tuple<"1">) -> i32
        %2187 = "cute.get_scalars"(%2184) : (!cute.int_tuple<"1">) -> i32
        %2188 = "cute.get_scalars"(%2185) : (!cute.int_tuple<"8">) -> i32
        %2189 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2190 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2189, %2186, %2190) ({
        ^bb0(%arg47: i32):
          "scf.for"(%2189, %2187, %2190) ({
          ^bb0(%arg48: i32):
            "scf.for"(%2189, %2188, %2190) ({
            ^bb0(%arg49: i32):
              %4376 = "cute.make_coord"(%arg49, %arg47) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4377 = "cute.make_coord"(%arg48, %arg49) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4378 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %4379 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4380 = "cute.add_offset"(%2177, %4379) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %4381 = "cute.make_view"(%4380, %4378) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %4382 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4383 = "cute.crd2idx"(%4376, %2182) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %4384 = "cute.add_offset"(%2178, %4383) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %4385 = "cute.make_view"(%4384, %4382) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %4386 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4387 = "cute.crd2idx"(%4377, %2180) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %4388 = "cute.add_offset"(%2179, %4387) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %4389 = "cute.make_view"(%4388, %4386) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %4390 = "cute.get_iter"(%4381) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %4391 = "cute.get_iter"(%4385) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %4392 = "cute.get_iter"(%4389) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %4393 = "builtin.unrealized_conversion_cast"(%4390) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %4394 = "llvm.load"(%4393) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4395 = "llvm.getelementptr"(%4393) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4396 = "llvm.load"(%4395) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4397 = "llvm.getelementptr"(%4393) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4398 = "llvm.load"(%4397) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4399 = "llvm.getelementptr"(%4393) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4400 = "llvm.load"(%4399) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4401 = "builtin.unrealized_conversion_cast"(%4391) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %4402 = "llvm.load"(%4401) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4403 = "llvm.getelementptr"(%4401) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4404 = "llvm.load"(%4403) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4405 = "builtin.unrealized_conversion_cast"(%4392) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %4406 = "llvm.load"(%4405) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4407 = "llvm.getelementptr"(%4405) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4408 = "llvm.load"(%4407) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4409 = "llvm.getelementptr"(%4405) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4410 = "llvm.load"(%4409) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4411 = "llvm.getelementptr"(%4405) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4412 = "llvm.load"(%4411) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4413:4 = "cute_nvgpu.arch.mma.SM80"(%4394, %4396, %4398, %4400, %4402, %4404, %4406, %4408, %4410, %4412) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %4414 = "builtin.unrealized_conversion_cast"(%4392) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%4413#0, %4414) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4415 = "llvm.getelementptr"(%4414) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4413#1, %4415) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4416 = "llvm.getelementptr"(%4414) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4413#2, %4416) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4417 = "llvm.getelementptr"(%4414) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4413#3, %4417) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        %2191 = "arith.constant"() <{value = false}> : () -> i1
        "scf.if"(%2191) ({
          %4263 = "cute.static"() : () -> !cute.int_tuple<"8192">
          %4264 = "cute.get_iter"(%568) : (!memref_smem_bf16_5) -> !cute.ptr<bf16, smem, align<16>>
          %4265 = "cute.add_offset"(%4264, %4263) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
          %4266 = "cute.make_view"(%4265) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
          %4267 = "cute.get_iter"(%4266) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4268 = "cute.static"() : () -> !cute.int_tuple<"16">
          %4269 = "cute.get_iter"(%570) : (!memref_rmem_bf16_3) -> !cute.ptr<bf16, rmem, align<16>>
          %4270 = "cute.add_offset"(%4269, %4268) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
          %4271 = "cute.make_view"(%4270) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_10
          %4272 = "cute.get_iter"(%4271) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4273 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4274 = "cute.make_view"(%4267, %4273) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
          %4275 = "cute.get_iter"(%4274) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
          %4276 = "cute.make_view"(%4275) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
          %4277 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
          %4278 = "cute.make_view"(%4272, %4277) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_rmem_bf16_10
          %4279 = "cute.get_iter"(%4278) : (!memref_rmem_bf16_10) -> !cute.ptr<bf16, rmem, align<16>>
          %4280 = "cute.make_view"(%4279) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_11
          %4281 = "cute.static"() : () -> !cute.layout<"1:0">
          %4282 = "cute.get_iter"(%4276) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
          %4283 = "cute.get_iter"(%4280) : (!memref_rmem_bf16_11) -> !cute.ptr<bf16, rmem, align<16>>
          %4284 = "cute.static"() : () -> !cute.int_tuple<"1">
          %4285 = "cute.get_scalars"(%4284) : (!cute.int_tuple<"1">) -> i32
          %4286 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4287 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4286, %4285, %4287) ({
          ^bb0(%arg46: i32):
            %4346 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4347 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4348 = "cute.add_offset"(%4282, %4347) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4349 = "cute.make_view"(%4348, %4346) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4350 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4351 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4352 = "cute.add_offset"(%4283, %4351) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
            %4353 = "cute.make_view"(%4352, %4350) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
            %4354 = "cute.get_iter"(%4349) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4355 = "cute.get_iter"(%4353) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
            %4356 = "cute.apply_swizzle"(%4354) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4357 = "cute_nvgpu.arch.copy.ldsm"(%4356) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4358 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4359 = "vector.extractelement"(%4357, %4358) : (vector<4xi32>, i32) -> i32
            %4360 = "builtin.unrealized_conversion_cast"(%4355) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            "llvm.store"(%4359, %4360) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4361 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4362 = "vector.extractelement"(%4357, %4361) : (vector<4xi32>, i32) -> i32
            %4363 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4364 = "cute.add_offset"(%4355, %4363) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4365 = "builtin.unrealized_conversion_cast"(%4364) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4362, %4365) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4366 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4367 = "vector.extractelement"(%4357, %4366) : (vector<4xi32>, i32) -> i32
            %4368 = "cute.static"() : () -> !cute.int_tuple<"4">
            %4369 = "cute.add_offset"(%4355, %4368) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %4370 = "builtin.unrealized_conversion_cast"(%4369) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4367, %4370) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4371 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4372 = "vector.extractelement"(%4357, %4371) : (vector<4xi32>, i32) -> i32
            %4373 = "cute.static"() : () -> !cute.int_tuple<"6">
            %4374 = "cute.add_offset"(%4355, %4373) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %4375 = "builtin.unrealized_conversion_cast"(%4374) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4372, %4375) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %4288 = "cute.static"() : () -> !cute.int_tuple<"8192">
          %4289 = "cute.get_iter"(%619) : (!memref_smem_bf16_6) -> !cute.ptr<bf16, smem, align<16>>
          %4290 = "cute.add_offset"(%4289, %4288) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
          %4291 = "cute.make_view"(%4290) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_16
          %4292 = "cute.get_iter"(%4291) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4293 = "cute.static"() : () -> !cute.int_tuple<"32">
          %4294 = "cute.get_iter"(%621) : (!memref_rmem_bf16_4) -> !cute.ptr<bf16, rmem, align<8>>
          %4295 = "cute.add_offset"(%4294, %4293) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %4296 = "cute.make_view"(%4295) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_12
          %4297 = "cute.get_iter"(%4296) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4298 = "cute.static"() : () -> !cute.layout<"((8,1),4):((1,0),1024)">
          %4299 = "cute.make_view"(%4292, %4298) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4):((1,0),1024)">) -> !memref_smem_bf16_16
          %4300 = "cute.get_iter"(%4299) : (!memref_smem_bf16_16) -> !cute.ptr<bf16, smem, align<16>>
          %4301 = "cute.make_view"(%4300) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_17
          %4302 = "cute.static"() : () -> !cute.layout<"(((4,2),1),4):(((1,32),0),4)">
          %4303 = "cute.make_view"(%4297, %4302) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1),4):(((1,32),0),4)">) -> !memref_rmem_bf16_12
          %4304 = "cute.get_iter"(%4303) : (!memref_rmem_bf16_12) -> !cute.ptr<bf16, rmem, align<8>>
          %4305 = "cute.make_view"(%4304) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_13
          %4306 = "cute.static"() : () -> !cute.layout<"1:0">
          %4307 = "cute.get_iter"(%4301) : (!memref_smem_bf16_17) -> !cute.ptr<bf16, smem, align<16>>
          %4308 = "cute.get_iter"(%4305) : (!memref_rmem_bf16_13) -> !cute.ptr<bf16, rmem, align<8>>
          %4309 = "cute.static"() : () -> !cute.layout<"((8,1),((4))):((1,0),((1024)))">
          %4310 = "cute.static"() : () -> !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
          %4311 = "cute.static"() : () -> !cute.int_tuple<"4">
          %4312 = "cute.get_scalars"(%4311) : (!cute.int_tuple<"4">) -> i32
          %4313 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %4314 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%4313, %4312, %4314) ({
          ^bb0(%arg45: i32):
            %4315 = "cute.make_coord"(%arg45) : (i32) -> !cute.coord<"(_,?)">
            %4316 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4317 = "cute.crd2idx"(%4315, %4309) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %4318 = "cute.add_offset"(%4307, %4317) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4319 = "cute.make_view"(%4318, %4316) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4320 = "cute.static"() : () -> !cute.layout<"(((4,2),1)):(((1,32),0))">
            %4321 = "cute.crd2idx"(%4315, %4310) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
            %4322 = "cute.add_offset"(%4308, %4321) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
            %4323 = "cute.make_view"(%4322, %4320) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"(((4,2),1)):(((1,32),0))">) -> !memref_rmem_bf16_14
            %4324 = "cute.get_iter"(%4319) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4325 = "cute.get_iter"(%4323) : (!memref_rmem_bf16_14) -> !cute.ptr<bf16, rmem, align<8>>
            %4326 = "cute.apply_swizzle"(%4324) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %4327 = "cute_nvgpu.arch.copy.ldsm"(%4326) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %4328 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %4329 = "vector.extractelement"(%4327, %4328) : (vector<4xi32>, i32) -> i32
            %4330 = "builtin.unrealized_conversion_cast"(%4325) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4329, %4330) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4331 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %4332 = "vector.extractelement"(%4327, %4331) : (vector<4xi32>, i32) -> i32
            %4333 = "cute.static"() : () -> !cute.int_tuple<"2">
            %4334 = "cute.add_offset"(%4325, %4333) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %4335 = "builtin.unrealized_conversion_cast"(%4334) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4332, %4335) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4336 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %4337 = "vector.extractelement"(%4327, %4336) : (vector<4xi32>, i32) -> i32
            %4338 = "cute.static"() : () -> !cute.int_tuple<"32">
            %4339 = "cute.add_offset"(%4325, %4338) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
            %4340 = "builtin.unrealized_conversion_cast"(%4339) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%4337, %4340) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %4341 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %4342 = "vector.extractelement"(%4327, %4341) : (vector<4xi32>, i32) -> i32
            %4343 = "cute.static"() : () -> !cute.int_tuple<"34">
            %4344 = "cute.add_offset"(%4325, %4343) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
            %4345 = "builtin.unrealized_conversion_cast"(%4344) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%4342, %4345) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2192 = "cute.static"() : () -> !cute.int_tuple<"56">
        %2193 = "cute.get_iter"(%496) : (!memref_rmem_bf16_) -> !cute.ptr<bf16, rmem, align<16>>
        %2194 = "cute.add_offset"(%2193, %2192) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        %2195 = "cute.make_view"(%2194) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_15
        %2196 = "cute.static"() : () -> !cute.int_tuple<"208">
        %2197 = "cute.get_iter"(%497) : (!memref_rmem_bf16_1) -> !cute.ptr<bf16, rmem, align<8>>
        %2198 = "cute.add_offset"(%2197, %2196) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
        %2199 = "cute.make_view"(%2198) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_16
        %2200 = "cute.get_iter"(%2195) : (!memref_rmem_bf16_15) -> !cute.ptr<bf16, rmem, align<16>>
        %2201 = "cute.get_iter"(%2199) : (!memref_rmem_bf16_16) -> !cute.ptr<bf16, rmem, align<8>>
        %2202 = "cute.get_iter"(%1927) : (!memref_rmem_f32_1) -> !cute.ptr<f32, rmem, align<32>>
        %2203 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2204 = "cute.static"() : () -> !cute.layout<"1:0">
        %2205 = "cute.static"() : () -> !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
        %2206 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2207 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2208 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2209 = "cute.get_scalars"(%2206) : (!cute.int_tuple<"1">) -> i32
        %2210 = "cute.get_scalars"(%2207) : (!cute.int_tuple<"1">) -> i32
        %2211 = "cute.get_scalars"(%2208) : (!cute.int_tuple<"8">) -> i32
        %2212 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2213 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2212, %2209, %2213) ({
        ^bb0(%arg42: i32):
          "scf.for"(%2212, %2210, %2213) ({
          ^bb0(%arg43: i32):
            "scf.for"(%2212, %2211, %2213) ({
            ^bb0(%arg44: i32):
              %4221 = "cute.make_coord"(%arg44, %arg42) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4222 = "cute.make_coord"(%arg43, %arg44) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %4223 = "cute.static"() : () -> !cute.layout<"((2,2,2)):((1,2,4))">
              %4224 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4225 = "cute.add_offset"(%2200, %4224) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %4226 = "cute.make_view"(%4225, %4223) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((2,2,2)):((1,2,4))">) -> !memref_rmem_bf16_17
              %4227 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4228 = "cute.crd2idx"(%4221, %2205) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %4229 = "cute.add_offset"(%2201, %4228) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %4230 = "cute.make_view"(%4229, %4227) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %4231 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %4232 = "cute.crd2idx"(%4222, %2203) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %4233 = "cute.add_offset"(%2202, %4232) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %4234 = "cute.make_view"(%4233, %4231) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %4235 = "cute.get_iter"(%4226) : (!memref_rmem_bf16_17) -> !cute.ptr<bf16, rmem, align<16>>
              %4236 = "cute.get_iter"(%4230) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %4237 = "cute.get_iter"(%4234) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %4238 = "builtin.unrealized_conversion_cast"(%4235) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %4239 = "llvm.load"(%4238) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4240 = "llvm.getelementptr"(%4238) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4241 = "llvm.load"(%4240) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4242 = "llvm.getelementptr"(%4238) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4243 = "llvm.load"(%4242) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4244 = "llvm.getelementptr"(%4238) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4245 = "llvm.load"(%4244) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4246 = "builtin.unrealized_conversion_cast"(%4236) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %4247 = "llvm.load"(%4246) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4248 = "llvm.getelementptr"(%4246) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4249 = "llvm.load"(%4248) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %4250 = "builtin.unrealized_conversion_cast"(%4237) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %4251 = "llvm.load"(%4250) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4252 = "llvm.getelementptr"(%4250) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %4253 = "llvm.load"(%4252) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4254 = "llvm.getelementptr"(%4250) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %4255 = "llvm.load"(%4254) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4256 = "llvm.getelementptr"(%4250) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %4257 = "llvm.load"(%4256) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %4258:4 = "cute_nvgpu.arch.mma.SM80"(%4239, %4241, %4243, %4245, %4247, %4249, %4251, %4253, %4255, %4257) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %4259 = "builtin.unrealized_conversion_cast"(%4237) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%4258#0, %4259) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4260 = "llvm.getelementptr"(%4259) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4258#1, %4260) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4261 = "llvm.getelementptr"(%4259) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4258#2, %4261) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %4262 = "llvm.getelementptr"(%4259) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%4258#3, %4262) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
        %2214 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        %2215 = "arith.constant"() <{value = 128 : i32}> : () -> i32
        "llvm.inline_asm"(%2214, %2215) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
        %2216 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2217 = "arith.cmpi"(%1922, %2216) <{predicate = 4 : i64}> : (i32, i32) -> i1
        "scf.if"(%2217) ({
          %3863 = "cute.static"() : () -> !cute.int_tuple<"1">
          %3864 = "cute.tuple_sub"(%1921, %3863) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %3865 = "cute.make_coord"(%3864) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %3866 = "cute.get_layout"(%348) : (!memref_gmem_bf16_6) -> !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %3867:3 = "cute.get_scalars"(%3866) <{only_dynamic}> : (!cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> (i32, i64, i64)
          %3868 = "cute.static"() : () -> !cute.shape<"((8,1),4,2)">
          %3869 = "cute.assume"(%3867#1) : (i64) -> !cute.i64<divby 128>
          %3870 = "cute.make_stride"(%3869) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %3871 = "cute.make_layout"(%3868, %3870) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2)">, !cute.stride<"((1,0),?{i64 div=128},64)">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %3872 = "cute.crd2idx"(%3865, %3866) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %3873 = "cute.get_iter"(%348) : (!memref_gmem_bf16_6) -> !cute.ptr<bf16, gmem, align<16>>
          %3874 = "cute.add_offset"(%3873, %3872) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %3875 = "cute.make_view"(%3874, %3871) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
          %3876 = "cute.get_iter"(%3875) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
          %3877 = "cute.static"() : () -> !cute.int_tuple<"0">
          %3878 = "cute.get_iter"(%380) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %3879 = "cute.add_offset"(%3878, %3877) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %3880 = "cute.make_view"(%3879) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_3
          %3881 = "cute.get_iter"(%3880) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %3882 = "cute.static"() : () -> !cute.int_tuple<"0">
          %3883 = "cute.get_iter"(%877) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %3884 = "cute.add_offset"(%3883, %3882) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %3885 = "cute.make_view"(%3884) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_
          %3886 = "cute.get_iter"(%3885) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %3887 = "cute.get_layout"(%3875) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %3888 = "cute.static"() : () -> !cute.layout<"1:0">
          %3889 = "cute.append_to_rank"(%3887, %3888) <{rank = 2 : si32}> : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %3890 = "cute.make_view"(%3876, %3889) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
          %3891 = "cute.get_iter"(%3890) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
          %3892 = "cute.get_layout"(%3890) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %3893 = "cute.get_scalars"(%3892) <{only_dynamic}> : (!cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> i64
          %3894 = "cute.static"() : () -> !cute.shape<"((8,1),(4,2))">
          %3895 = "cute.assume"(%3893) : (i64) -> !cute.i64<divby 128>
          %3896 = "cute.make_stride"(%3895) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %3897 = "cute.make_layout"(%3894, %3896) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(4,2))">, !cute.stride<"((1,0),(?{i64 div=128},64))">) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %3898 = "cute.make_view"(%3891, %3897) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> !memref_gmem_bf16_13
          %3899 = "cute.static"() : () -> !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
          %3900 = "cute.make_view"(%3881, %3899) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !memref_smem_bf16_3
          %3901 = "cute.get_iter"(%3900) : (!memref_smem_bf16_3) -> !cute.ptr<bf16, smem, align<16>>
          %3902 = "cute.make_view"(%3901) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_14
          %3903 = "cute.static"() : () -> !cute.layout<"(1,4,2):(2,0,1)">
          %3904 = "cute.make_view"(%3886, %3903) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,4,2):(2,0,1)">) -> !memref_rmem_i8_
          %3905 = "cute.get_iter"(%3904) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
          %3906 = "cute.make_view"(%3905) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_4
          %3907 = "cute.static"() : () -> !cute.layout<"1:0">
          %3908 = "cute.get_iter"(%3898) : (!memref_gmem_bf16_13) -> !cute.ptr<bf16, gmem, align<16>>
          %3909 = "cute.get_iter"(%3902) : (!memref_smem_bf16_14) -> !cute.ptr<bf16, smem, align<16>>
          %3910 = "cute.get_layout"(%3898) : (!memref_gmem_bf16_13) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %3911 = "cute.append_to_rank"(%3910, %3907) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %3912 = "cute.get_scalars"(%3911) <{only_dynamic}> : (!cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">) -> i64
          %3913 = "cute.static"() : () -> !cute.shape<"((8,1),((4,2)))">
          %3914 = "cute.assume"(%3912) : (i64) -> !cute.i64<divby 128>
          %3915 = "cute.make_stride"(%3914) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %3916 = "cute.make_layout"(%3913, %3915) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((4,2)))">, !cute.stride<"((1,0),((?{i64 div=128},64)))">) -> !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %3917 = "cute.static"() : () -> !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
          %3918 = "cute.get_iter"(%3906) : (!memref_rmem_i8_4) -> !cute.ptr<i8, rmem, align<32>>
          %3919 = "cute.static"() : () -> !cute.layout<"(1,((4,2))):(2,((0,1)))">
          %3920 = "cute.static"() : () -> !cute.int_tuple<"8">
          %3921 = "cute.get_scalars"(%3920) : (!cute.int_tuple<"8">) -> i32
          %3922 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %3923 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%3922, %3921, %3923) ({
          ^bb0(%arg41: i32):
            %4200 = "cute.make_coord"(%arg41) : (i32) -> !cute.coord<"(_,?)">
            %4201 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4202 = "cute.crd2idx"(%4200, %3916) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %4203 = "cute.add_offset"(%3908, %4202) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %4204 = "cute.make_view"(%4203, %4201) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
            %4205 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %4206 = "cute.crd2idx"(%4200, %3917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %4207 = "cute.add_offset"(%3909, %4206) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %4208 = "cute.make_view"(%4207, %4205) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %4209 = "cute.static"() : () -> !cute.layout<"(1):(2)">
            %4210 = "cute.crd2idx"(%4200, %3919) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %4211 = "cute.add_offset"(%3918, %4210) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %4212 = "cute.make_view"(%4211, %4209) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
            %4213 = "cute.get_iter"(%4204) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
            %4214 = "cute.get_iter"(%4208) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %4215 = "cute.get_iter"(%4212) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
            %4216 = "builtin.unrealized_conversion_cast"(%4215) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
            %4217 = "llvm.load"(%4216) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
            %4218 = "llvm.trunc"(%4217) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
            %4219 = "cute.recast_iter"(%4213) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
            %4220 = "cute.recast_iter"(%4214) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
            "cute_nvgpu.arch.copy.SM80.cp_async"(%4220, %4219, %4218) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>, i1) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          %3924 = "cute.static"() : () -> !cute.int_tuple<"1">
          %3925 = "cute.tuple_sub"(%1921, %3924) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %3926 = "cute.make_coord"(%3925) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %3927 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %3928 = "cute.crd2idx"(%3926, %3927) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
          %3929 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3930 = "cute.add_offset"(%3929, %3928) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3931 = "cute.make_view"(%3930) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %3932 = "cute.get_iter"(%3931) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3933 = "cute.deref_arith_tuple_iter"(%3932) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %3934:4 = "cute.get_leaves"(%3933) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %3935 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %3936 = "cute.get_shape"(%3935) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %3937:4 = "cute.get_leaves"(%3936) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %3938 = "cute.to_int_tuple"(%3937#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %3939 = "cute.make_coord"(%3934#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3940 = "cute.make_coord"(%3938) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3941 = "cute.get_scalars"(%3939) : (!cute.coord<"?">) -> i32
          %3942 = "cute.get_scalars"(%3940) : (!cute.coord<"?">) -> i32
          %3943 = "arith.constant"() <{value = true}> : () -> i1
          %3944 = "arith.cmpi"(%3941, %3942) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3945 = "arith.andi"(%3943, %3944) : (i1, i1) -> i1
          "scf.if"(%3945) ({
            %4159 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4160 = "cute.tuple_sub"(%1921, %4159) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %4161 = "cute.make_coord"(%4160) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %4162 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
            %4163 = "cute.crd2idx"(%4161, %4162) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
            %4164 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
            %4165 = "cute.add_offset"(%4164, %4163) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %4166 = "cute.make_view"(%4165) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_11
            %4167 = "cute.get_iter"(%4166) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4168 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4169 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4170 = "cute.add_offset"(%4169, %4168) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4171 = "cute.make_view"(%4170) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4172 = "cute.get_iter"(%4171) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4173 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4174 = "cute.make_view"(%4167, %4173) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
            %4175 = "cute.get_iter"(%4174) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4176 = "cute.make_view"(%4175) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
            %4177 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4178 = "cute.make_view"(%4172, %4177) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
            %4179 = "cute.get_iter"(%4178) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4180 = "cute.make_view"(%4179) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
            %4181 = "cute.static"() : () -> !cute.layout<"1:0">
            %4182 = "cute.get_iter"(%4176) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
            %4183 = "cute.get_iter"(%4180) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
            %4184 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4185 = "cute.get_scalars"(%4184) : (!cute.int_tuple<"1">) -> i32
            %4186 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %4187 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%4186, %4185, %4187) ({
            ^bb0(%arg40: i32):
              %4188 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4189 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4190 = "cute.add_offset"(%4182, %4189) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
              %4191 = "cute.make_view"(%4190, %4188) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %4192 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4193 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4194 = "cute.add_offset"(%4183, %4193) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
              %4195 = "cute.make_view"(%4194, %4192) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %4196 = "cute.get_iter"(%4191) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %4197 = "cute.get_iter"(%4195) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %4198 = "cute.recast_iter"(%4196) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %4199 = "cute.recast_iter"(%4197) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%4199, %4198) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %4153 = "cute.static"() : () -> !cute.int_tuple<"0">
            %4154 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4155 = "cute.add_offset"(%4154, %4153) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
            %4156 = "cute.make_view"(%4155) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4157 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %4158 = "vector.splat"(%4157) : (bf16) -> vector<8xbf16>
            "cute.memref.store_vec"(%4158, %4156) : (vector<8xbf16>, !memref_smem_bf16_12) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %3946 = "cute.static"() : () -> !cute.int_tuple<"1">
          %3947 = "cute.tuple_sub"(%1921, %3946) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %3948 = "cute.make_coord"(%3947) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %3949 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %3950 = "cute.crd2idx"(%3948, %3949) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
          %3951 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3952 = "cute.add_offset"(%3951, %3950) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3953 = "cute.make_view"(%3952) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %3954 = "cute.get_iter"(%3953) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3955 = "cute.deref_arith_tuple_iter"(%3954) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %3956:4 = "cute.get_leaves"(%3955) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %3957 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %3958 = "cute.get_shape"(%3957) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %3959:4 = "cute.get_leaves"(%3958) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %3960 = "cute.to_int_tuple"(%3959#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %3961 = "cute.make_coord"(%3956#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3962 = "cute.make_coord"(%3960) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3963 = "cute.get_scalars"(%3961) : (!cute.coord<"?">) -> i32
          %3964 = "cute.get_scalars"(%3962) : (!cute.coord<"?">) -> i32
          %3965 = "arith.constant"() <{value = true}> : () -> i1
          %3966 = "arith.cmpi"(%3963, %3964) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3967 = "arith.andi"(%3965, %3966) : (i1, i1) -> i1
          "scf.if"(%3967) ({
            %4112 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4113 = "cute.tuple_sub"(%1921, %4112) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %4114 = "cute.make_coord"(%4113) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %4115 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
            %4116 = "cute.crd2idx"(%4114, %4115) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %4117 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
            %4118 = "cute.add_offset"(%4117, %4116) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %4119 = "cute.make_view"(%4118) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_11
            %4120 = "cute.get_iter"(%4119) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4121 = "cute.static"() : () -> !cute.int_tuple<"1024">
            %4122 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4123 = "cute.add_offset"(%4122, %4121) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %4124 = "cute.make_view"(%4123) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4125 = "cute.get_iter"(%4124) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4126 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4127 = "cute.make_view"(%4120, %4126) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
            %4128 = "cute.get_iter"(%4127) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4129 = "cute.make_view"(%4128) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
            %4130 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4131 = "cute.make_view"(%4125, %4130) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
            %4132 = "cute.get_iter"(%4131) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4133 = "cute.make_view"(%4132) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
            %4134 = "cute.static"() : () -> !cute.layout<"1:0">
            %4135 = "cute.get_iter"(%4129) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
            %4136 = "cute.get_iter"(%4133) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
            %4137 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4138 = "cute.get_scalars"(%4137) : (!cute.int_tuple<"1">) -> i32
            %4139 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %4140 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%4139, %4138, %4140) ({
            ^bb0(%arg39: i32):
              %4141 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4142 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4143 = "cute.add_offset"(%4135, %4142) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
              %4144 = "cute.make_view"(%4143, %4141) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %4145 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4146 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4147 = "cute.add_offset"(%4136, %4146) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
              %4148 = "cute.make_view"(%4147, %4145) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %4149 = "cute.get_iter"(%4144) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %4150 = "cute.get_iter"(%4148) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %4151 = "cute.recast_iter"(%4149) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %4152 = "cute.recast_iter"(%4150) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%4152, %4151) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %4106 = "cute.static"() : () -> !cute.int_tuple<"1024">
            %4107 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4108 = "cute.add_offset"(%4107, %4106) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %4109 = "cute.make_view"(%4108) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4110 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %4111 = "vector.splat"(%4110) : (bf16) -> vector<8xbf16>
            "cute.memref.store_vec"(%4111, %4109) : (vector<8xbf16>, !memref_smem_bf16_12) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %3968 = "cute.static"() : () -> !cute.int_tuple<"1">
          %3969 = "cute.tuple_sub"(%1921, %3968) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %3970 = "cute.make_coord"(%3969) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %3971 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %3972 = "cute.crd2idx"(%3970, %3971) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
          %3973 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3974 = "cute.add_offset"(%3973, %3972) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3975 = "cute.make_view"(%3974) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %3976 = "cute.get_iter"(%3975) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3977 = "cute.deref_arith_tuple_iter"(%3976) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %3978:4 = "cute.get_leaves"(%3977) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %3979 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %3980 = "cute.get_shape"(%3979) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %3981:4 = "cute.get_leaves"(%3980) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %3982 = "cute.to_int_tuple"(%3981#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %3983 = "cute.make_coord"(%3978#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3984 = "cute.make_coord"(%3982) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3985 = "cute.get_scalars"(%3983) : (!cute.coord<"?">) -> i32
          %3986 = "cute.get_scalars"(%3984) : (!cute.coord<"?">) -> i32
          %3987 = "arith.constant"() <{value = true}> : () -> i1
          %3988 = "arith.cmpi"(%3985, %3986) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3989 = "arith.andi"(%3987, %3988) : (i1, i1) -> i1
          "scf.if"(%3989) ({
            %4065 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4066 = "cute.tuple_sub"(%1921, %4065) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %4067 = "cute.make_coord"(%4066) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %4068 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
            %4069 = "cute.crd2idx"(%4067, %4068) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %4070 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
            %4071 = "cute.add_offset"(%4070, %4069) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %4072 = "cute.make_view"(%4071) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_11
            %4073 = "cute.get_iter"(%4072) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4074 = "cute.static"() : () -> !cute.int_tuple<"2048">
            %4075 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4076 = "cute.add_offset"(%4075, %4074) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %4077 = "cute.make_view"(%4076) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4078 = "cute.get_iter"(%4077) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4079 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4080 = "cute.make_view"(%4073, %4079) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
            %4081 = "cute.get_iter"(%4080) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4082 = "cute.make_view"(%4081) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
            %4083 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4084 = "cute.make_view"(%4078, %4083) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
            %4085 = "cute.get_iter"(%4084) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4086 = "cute.make_view"(%4085) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
            %4087 = "cute.static"() : () -> !cute.layout<"1:0">
            %4088 = "cute.get_iter"(%4082) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
            %4089 = "cute.get_iter"(%4086) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
            %4090 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4091 = "cute.get_scalars"(%4090) : (!cute.int_tuple<"1">) -> i32
            %4092 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %4093 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%4092, %4091, %4093) ({
            ^bb0(%arg38: i32):
              %4094 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4095 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4096 = "cute.add_offset"(%4088, %4095) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
              %4097 = "cute.make_view"(%4096, %4094) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %4098 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4099 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4100 = "cute.add_offset"(%4089, %4099) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
              %4101 = "cute.make_view"(%4100, %4098) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %4102 = "cute.get_iter"(%4097) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %4103 = "cute.get_iter"(%4101) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %4104 = "cute.recast_iter"(%4102) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %4105 = "cute.recast_iter"(%4103) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%4105, %4104) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %4059 = "cute.static"() : () -> !cute.int_tuple<"2048">
            %4060 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4061 = "cute.add_offset"(%4060, %4059) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %4062 = "cute.make_view"(%4061) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4063 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %4064 = "vector.splat"(%4063) : (bf16) -> vector<8xbf16>
            "cute.memref.store_vec"(%4064, %4062) : (vector<8xbf16>, !memref_smem_bf16_12) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          %3990 = "cute.static"() : () -> !cute.int_tuple<"1">
          %3991 = "cute.tuple_sub"(%1921, %3990) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %3992 = "cute.make_coord"(%3991) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %3993 = "cute.get_layout"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
          %3994 = "cute.crd2idx"(%3992, %3993) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
          %3995 = "cute.get_iter"(%873) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3996 = "cute.add_offset"(%3995, %3994) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3997 = "cute.make_view"(%3996) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
          %3998 = "cute.get_iter"(%3997) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
          %3999 = "cute.deref_arith_tuple_iter"(%3998) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %4000:4 = "cute.get_leaves"(%3999) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
          %4001 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
          %4002 = "cute.get_shape"(%4001) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %4003:4 = "cute.get_leaves"(%4002) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
          %4004 = "cute.to_int_tuple"(%4003#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
          %4005 = "cute.make_coord"(%4000#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %4006 = "cute.make_coord"(%4004) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %4007 = "cute.get_scalars"(%4005) : (!cute.coord<"?">) -> i32
          %4008 = "cute.get_scalars"(%4006) : (!cute.coord<"?">) -> i32
          %4009 = "arith.constant"() <{value = true}> : () -> i1
          %4010 = "arith.cmpi"(%4007, %4008) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %4011 = "arith.andi"(%4009, %4010) : (i1, i1) -> i1
          "scf.if"(%4011) ({
            %4018 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4019 = "cute.tuple_sub"(%1921, %4018) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %4020 = "cute.make_coord"(%4019) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %4021 = "cute.get_layout"(%463) : (!memref_gmem_bf16_7) -> !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
            %4022 = "cute.crd2idx"(%4020, %4021) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %4023 = "cute.get_iter"(%463) : (!memref_gmem_bf16_7) -> !cute.ptr<bf16, gmem, align<16>>
            %4024 = "cute.add_offset"(%4023, %4022) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %4025 = "cute.make_view"(%4024) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_11
            %4026 = "cute.get_iter"(%4025) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4027 = "cute.static"() : () -> !cute.int_tuple<"3072">
            %4028 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4029 = "cute.add_offset"(%4028, %4027) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %4030 = "cute.make_view"(%4029) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4031 = "cute.get_iter"(%4030) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4032 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4033 = "cute.make_view"(%4026, %4032) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_gmem_bf16_11
            %4034 = "cute.get_iter"(%4033) : (!memref_gmem_bf16_11) -> !cute.ptr<bf16, gmem, align<16>>
            %4035 = "cute.make_view"(%4034) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_12
            %4036 = "cute.static"() : () -> !cute.layout<"((8,1),1):((1,0),0)">
            %4037 = "cute.make_view"(%4031, %4036) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),1):((1,0),0)">) -> !memref_smem_bf16_12
            %4038 = "cute.get_iter"(%4037) : (!memref_smem_bf16_12) -> !cute.ptr<bf16, smem, align<16>>
            %4039 = "cute.make_view"(%4038) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_13
            %4040 = "cute.static"() : () -> !cute.layout<"1:0">
            %4041 = "cute.get_iter"(%4035) : (!memref_gmem_bf16_12) -> !cute.ptr<bf16, gmem, align<16>>
            %4042 = "cute.get_iter"(%4039) : (!memref_smem_bf16_13) -> !cute.ptr<bf16, smem, align<16>>
            %4043 = "cute.static"() : () -> !cute.int_tuple<"1">
            %4044 = "cute.get_scalars"(%4043) : (!cute.int_tuple<"1">) -> i32
            %4045 = "arith.constant"() <{value = 0 : i32}> : () -> i32
            %4046 = "arith.constant"() <{value = 1 : i32}> : () -> i32
            "scf.for"(%4045, %4044, %4046) ({
            ^bb0(%arg37: i32):
              %4047 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4048 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4049 = "cute.add_offset"(%4041, %4048) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
              %4050 = "cute.make_view"(%4049, %4047) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
              %4051 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
              %4052 = "cute.static"() : () -> !cute.int_tuple<"0">
              %4053 = "cute.add_offset"(%4042, %4052) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
              %4054 = "cute.make_view"(%4053, %4051) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
              %4055 = "cute.get_iter"(%4050) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
              %4056 = "cute.get_iter"(%4054) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
              %4057 = "cute.recast_iter"(%4055) : (!cute.ptr<bf16, gmem, align<16>>) -> !cute.ptr<i128, gmem>
              %4058 = "cute.recast_iter"(%4056) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<i128, smem>
              "cute_nvgpu.arch.copy.SM80.cp_async"(%4058, %4057) <{cache_mode = #cute_nvgpu.load_cache_mode<always>}> : (!cute.ptr<i128, smem>, !cute.ptr<i128, gmem>) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }, {
            %4012 = "cute.static"() : () -> !cute.int_tuple<"3072">
            %4013 = "cute.get_iter"(%495) : (!memref_smem_bf16_4) -> !cute.ptr<bf16, smem, align<16>>
            %4014 = "cute.add_offset"(%4013, %4012) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %4015 = "cute.make_view"(%4014) : (!cute.ptr<bf16, smem, align<16>>) -> !memref_smem_bf16_12
            %4016 = "arith.constant"() <{value = 0.000000e+00 : bf16}> : () -> bf16
            %4017 = "vector.splat"(%4016) : (bf16) -> vector<8xbf16>
            "cute.memref.store_vec"(%4017, %4015) : (vector<8xbf16>, !memref_smem_bf16_12) -> ()
            "scf.yield"() : () -> ()
          }) : (i1) -> ()
          "nvvm.cp.async.commit.group"() : () -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2218 = "scf.if"(%2036) ({
          %3728 = "cute.memref.load_vec"(%1927) : (!memref_rmem_f32_1) -> vector<32xf32>
          %3729 = "arith.constant"() <{value = 5.000000e-01 : f32}> : () -> f32
          %3730 = "vector.broadcast"(%3729) : (f32) -> vector<32xf32>
          %3731 = "arith.mulf"(%3728, %3730) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          "cute.memref.store_vec"(%3731, %1927) : (vector<32xf32>, !memref_rmem_f32_1) -> ()
          %3732 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
          %3733 = "cute.memref.load"(%1927, %3732) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
          %3734 = "llvm.inline_asm"(%3733) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3735 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
          "cute.memref.store"(%1927, %3735, %3734) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
          %3736 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
          %3737 = "cute.memref.load"(%1927, %3736) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
          %3738 = "llvm.inline_asm"(%3737) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3739 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
          "cute.memref.store"(%1927, %3739, %3738) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
          %3740 = "cute.static"() : () -> !cute.coord<"(0,0,2)">
          %3741 = "cute.memref.load"(%1927, %3740) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
          %3742 = "llvm.inline_asm"(%3741) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3743 = "cute.static"() : () -> !cute.coord<"(0,0,2)">
          "cute.memref.store"(%1927, %3743, %3742) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
          %3744 = "cute.static"() : () -> !cute.coord<"(0,0,3)">
          %3745 = "cute.memref.load"(%1927, %3744) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
          %3746 = "llvm.inline_asm"(%3745) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3747 = "cute.static"() : () -> !cute.coord<"(0,0,3)">
          "cute.memref.store"(%1927, %3747, %3746) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
          %3748 = "cute.static"() : () -> !cute.coord<"(0,0,4)">
          %3749 = "cute.memref.load"(%1927, %3748) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
          %3750 = "llvm.inline_asm"(%3749) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3751 = "cute.static"() : () -> !cute.coord<"(0,0,4)">
          "cute.memref.store"(%1927, %3751, %3750) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
          %3752 = "cute.static"() : () -> !cute.coord<"(0,0,5)">
          %3753 = "cute.memref.load"(%1927, %3752) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
          %3754 = "llvm.inline_asm"(%3753) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3755 = "cute.static"() : () -> !cute.coord<"(0,0,5)">
          "cute.memref.store"(%1927, %3755, %3754) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
          %3756 = "cute.static"() : () -> !cute.coord<"(0,0,6)">
          %3757 = "cute.memref.load"(%1927, %3756) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
          %3758 = "llvm.inline_asm"(%3757) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3759 = "cute.static"() : () -> !cute.coord<"(0,0,6)">
          "cute.memref.store"(%1927, %3759, %3758) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
          %3760 = "cute.static"() : () -> !cute.coord<"(0,0,7)">
          %3761 = "cute.memref.load"(%1927, %3760) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
          %3762 = "llvm.inline_asm"(%3761) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3763 = "cute.static"() : () -> !cute.coord<"(0,0,7)">
          "cute.memref.store"(%1927, %3763, %3762) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
          %3764 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
          %3765 = "cute.memref.load"(%1927, %3764) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
          %3766 = "llvm.inline_asm"(%3765) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3767 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
          "cute.memref.store"(%1927, %3767, %3766) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
          %3768 = "cute.static"() : () -> !cute.coord<"(1,0,1)">
          %3769 = "cute.memref.load"(%1927, %3768) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
          %3770 = "llvm.inline_asm"(%3769) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3771 = "cute.static"() : () -> !cute.coord<"(1,0,1)">
          "cute.memref.store"(%1927, %3771, %3770) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
          %3772 = "cute.static"() : () -> !cute.coord<"(1,0,2)">
          %3773 = "cute.memref.load"(%1927, %3772) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
          %3774 = "llvm.inline_asm"(%3773) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3775 = "cute.static"() : () -> !cute.coord<"(1,0,2)">
          "cute.memref.store"(%1927, %3775, %3774) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
          %3776 = "cute.static"() : () -> !cute.coord<"(1,0,3)">
          %3777 = "cute.memref.load"(%1927, %3776) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
          %3778 = "llvm.inline_asm"(%3777) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3779 = "cute.static"() : () -> !cute.coord<"(1,0,3)">
          "cute.memref.store"(%1927, %3779, %3778) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
          %3780 = "cute.static"() : () -> !cute.coord<"(1,0,4)">
          %3781 = "cute.memref.load"(%1927, %3780) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
          %3782 = "llvm.inline_asm"(%3781) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3783 = "cute.static"() : () -> !cute.coord<"(1,0,4)">
          "cute.memref.store"(%1927, %3783, %3782) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
          %3784 = "cute.static"() : () -> !cute.coord<"(1,0,5)">
          %3785 = "cute.memref.load"(%1927, %3784) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
          %3786 = "llvm.inline_asm"(%3785) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3787 = "cute.static"() : () -> !cute.coord<"(1,0,5)">
          "cute.memref.store"(%1927, %3787, %3786) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
          %3788 = "cute.static"() : () -> !cute.coord<"(1,0,6)">
          %3789 = "cute.memref.load"(%1927, %3788) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
          %3790 = "llvm.inline_asm"(%3789) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3791 = "cute.static"() : () -> !cute.coord<"(1,0,6)">
          "cute.memref.store"(%1927, %3791, %3790) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
          %3792 = "cute.static"() : () -> !cute.coord<"(1,0,7)">
          %3793 = "cute.memref.load"(%1927, %3792) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
          %3794 = "llvm.inline_asm"(%3793) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3795 = "cute.static"() : () -> !cute.coord<"(1,0,7)">
          "cute.memref.store"(%1927, %3795, %3794) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
          %3796 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
          %3797 = "cute.memref.load"(%1927, %3796) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
          %3798 = "llvm.inline_asm"(%3797) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3799 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
          "cute.memref.store"(%1927, %3799, %3798) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
          %3800 = "cute.static"() : () -> !cute.coord<"(2,0,1)">
          %3801 = "cute.memref.load"(%1927, %3800) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
          %3802 = "llvm.inline_asm"(%3801) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3803 = "cute.static"() : () -> !cute.coord<"(2,0,1)">
          "cute.memref.store"(%1927, %3803, %3802) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
          %3804 = "cute.static"() : () -> !cute.coord<"(2,0,2)">
          %3805 = "cute.memref.load"(%1927, %3804) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
          %3806 = "llvm.inline_asm"(%3805) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3807 = "cute.static"() : () -> !cute.coord<"(2,0,2)">
          "cute.memref.store"(%1927, %3807, %3806) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
          %3808 = "cute.static"() : () -> !cute.coord<"(2,0,3)">
          %3809 = "cute.memref.load"(%1927, %3808) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
          %3810 = "llvm.inline_asm"(%3809) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3811 = "cute.static"() : () -> !cute.coord<"(2,0,3)">
          "cute.memref.store"(%1927, %3811, %3810) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
          %3812 = "cute.static"() : () -> !cute.coord<"(2,0,4)">
          %3813 = "cute.memref.load"(%1927, %3812) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
          %3814 = "llvm.inline_asm"(%3813) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3815 = "cute.static"() : () -> !cute.coord<"(2,0,4)">
          "cute.memref.store"(%1927, %3815, %3814) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
          %3816 = "cute.static"() : () -> !cute.coord<"(2,0,5)">
          %3817 = "cute.memref.load"(%1927, %3816) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
          %3818 = "llvm.inline_asm"(%3817) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3819 = "cute.static"() : () -> !cute.coord<"(2,0,5)">
          "cute.memref.store"(%1927, %3819, %3818) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
          %3820 = "cute.static"() : () -> !cute.coord<"(2,0,6)">
          %3821 = "cute.memref.load"(%1927, %3820) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
          %3822 = "llvm.inline_asm"(%3821) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3823 = "cute.static"() : () -> !cute.coord<"(2,0,6)">
          "cute.memref.store"(%1927, %3823, %3822) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
          %3824 = "cute.static"() : () -> !cute.coord<"(2,0,7)">
          %3825 = "cute.memref.load"(%1927, %3824) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
          %3826 = "llvm.inline_asm"(%3825) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3827 = "cute.static"() : () -> !cute.coord<"(2,0,7)">
          "cute.memref.store"(%1927, %3827, %3826) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
          %3828 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
          %3829 = "cute.memref.load"(%1927, %3828) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
          %3830 = "llvm.inline_asm"(%3829) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3831 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
          "cute.memref.store"(%1927, %3831, %3830) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
          %3832 = "cute.static"() : () -> !cute.coord<"(3,0,1)">
          %3833 = "cute.memref.load"(%1927, %3832) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
          %3834 = "llvm.inline_asm"(%3833) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3835 = "cute.static"() : () -> !cute.coord<"(3,0,1)">
          "cute.memref.store"(%1927, %3835, %3834) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
          %3836 = "cute.static"() : () -> !cute.coord<"(3,0,2)">
          %3837 = "cute.memref.load"(%1927, %3836) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
          %3838 = "llvm.inline_asm"(%3837) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3839 = "cute.static"() : () -> !cute.coord<"(3,0,2)">
          "cute.memref.store"(%1927, %3839, %3838) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
          %3840 = "cute.static"() : () -> !cute.coord<"(3,0,3)">
          %3841 = "cute.memref.load"(%1927, %3840) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
          %3842 = "llvm.inline_asm"(%3841) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3843 = "cute.static"() : () -> !cute.coord<"(3,0,3)">
          "cute.memref.store"(%1927, %3843, %3842) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
          %3844 = "cute.static"() : () -> !cute.coord<"(3,0,4)">
          %3845 = "cute.memref.load"(%1927, %3844) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
          %3846 = "llvm.inline_asm"(%3845) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3847 = "cute.static"() : () -> !cute.coord<"(3,0,4)">
          "cute.memref.store"(%1927, %3847, %3846) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
          %3848 = "cute.static"() : () -> !cute.coord<"(3,0,5)">
          %3849 = "cute.memref.load"(%1927, %3848) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
          %3850 = "llvm.inline_asm"(%3849) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3851 = "cute.static"() : () -> !cute.coord<"(3,0,5)">
          "cute.memref.store"(%1927, %3851, %3850) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
          %3852 = "cute.static"() : () -> !cute.coord<"(3,0,6)">
          %3853 = "cute.memref.load"(%1927, %3852) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
          %3854 = "llvm.inline_asm"(%3853) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3855 = "cute.static"() : () -> !cute.coord<"(3,0,6)">
          "cute.memref.store"(%1927, %3855, %3854) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
          %3856 = "cute.static"() : () -> !cute.coord<"(3,0,7)">
          %3857 = "cute.memref.load"(%1927, %3856) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
          %3858 = "llvm.inline_asm"(%3857) <{asm_dialect = 0 : i64, asm_string = "tanh.approx.f32 $0, $1;", constraints = "=f,f"}> : (f32) -> f32
          %3859 = "cute.static"() : () -> !cute.coord<"(3,0,7)">
          "cute.memref.store"(%1927, %3859, %3858) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
          %3860 = "cute.memref.load_vec"(%1927) : (!memref_rmem_f32_1) -> vector<32xf32>
          %3861 = "arith.mulf"(%3731, %3860) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          %3862 = "arith.addf"(%3861, %3731) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          "cute.memref.store_vec"(%3862, %1927) : (vector<32xf32>, !memref_rmem_f32_1) -> ()
          "scf.yield"(%1927) : (!memref_rmem_f32_1) -> ()
        }, {
          %3719 = "cute.memref.load_vec"(%1927) : (!memref_rmem_f32_1) -> vector<32xf32>
          %3720 = "arith.constant"() <{value = -1.44269502 : f32}> : () -> f32
          %3721 = "vector.broadcast"(%3720) : (f32) -> vector<32xf32>
          %3722 = "arith.mulf"(%3719, %3721) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          %3723 = "math.exp2"(%3722) <{fastmath = #arith.fastmath<fast>}> : (vector<32xf32>) -> vector<32xf32>
          %3724 = "arith.constant"() <{value = 1.000000e+00 : f32}> : () -> f32
          %3725 = "vector.broadcast"(%3724) : (f32) -> vector<32xf32>
          %3726 = "arith.addf"(%3723, %3725) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          %3727 = "arith.divf"(%3719, %3726) <{fastmath = #arith.fastmath<none>}> : (vector<32xf32>, vector<32xf32>) -> vector<32xf32>
          "cute.memref.store_vec"(%3727, %1927) : (vector<32xf32>, !memref_rmem_f32_1) -> ()
          "scf.yield"(%1927) : (!memref_rmem_f32_1) -> ()
        }) : (i1) -> !memref_rmem_f32_1
        %2219 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
        %2220 = "cute.get_shape"(%2219) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %2221:4 = "cute.get_leaves"(%2220) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
        %2222 = "cute.to_int_tuple"(%2221#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
        %2223 = "cute.get_layout"(%arg10) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
        %2224 = "cute.get_shape"(%2223) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
        %2225:4 = "cute.get_leaves"(%2224) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
        %2226 = "cute.to_int_tuple"(%2225#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
        %2227 = "cute.make_shape"(%2222, %2226) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?{div=8})">
        %2228 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
        %2229 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
        %2230 = "cute.make_layout"(%2227, %2229) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?{div=8}):(1@0,1@1)">
        %2231 = "cute.make_view"(%2228, %2230) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?{div=8}):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %2232 = "cute.get_layout"(%2231) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">) -> !cute.layout<"(?,?{div=8}):(1@0,1@1)">
        %2233:2 = "cute.get_scalars"(%2232) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@0,1@1)">) -> (i32, i32)
        %2234 = "cute.assume"(%2233#1) : (i32) -> !cute.i32<divby 8>
        %2235 = "cute.make_shape"(%2233#0, %2234) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
        %2236 = "cute.static"() : () -> !cute.stride<"(1@0,1@1)">
        %2237 = "cute.make_layout"(%2235, %2236) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(?,?{div=8}):(1@0,1@1)">
        %2238 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0)">
        %2239 = "cute.make_view"(%2238, %2237) : (!cute.arith_tuple_iter<"(0,0)">, !cute.layout<"(?,?{div=8}):(1@0,1@1)">) -> !cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">
        %2240 = "cute.make_coord"(%88, %1921) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %2241:2 = "cute.get_scalars"(%2240) <{only_dynamic}> : (!cute.coord<"(?,?)">) -> (i32, i32)
        %2242 = "cute.make_coord"(%2241#0, %2241#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
        %2243 = "cute.get_layout"(%2239) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">) -> !cute.layout<"(?,?{div=8}):(1@0,1@1)">
        %2244:2 = "cute.get_scalars"(%2243) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@0,1@1)">) -> (i32, i32)
        %2245 = "arith.constant"() <{value = 64 : i32}> : () -> i32
        %2246 = "arith.ceildivsi"(%2244#0, %2245) : (i32, i32) -> i32
        %2247 = "arith.constant"() <{value = 64 : i32}> : () -> i32
        %2248 = "arith.ceildivsi"(%2244#1, %2247) : (i32, i32) -> i32
        %2249 = "cute.make_shape"(%2246, %2248) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
        %2250 = "cute.static"() : () -> !cute.stride<"((1@0,1@1),(64@0,64@1))">
        %2251 = "cute.make_layout"(%2249, %2250) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,64),(?,?))">, !cute.stride<"((1@0,1@1),(64@0,64@1))">) -> !cute.layout<"((64,64),(?,?)):((1@0,1@1),(64@0,64@1))">
        %2252 = "cute.crd2idx"(%2242, %2251) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,64),(?,?)):((1@0,1@1),(64@0,64@1))">) -> !cute.int_tuple<"(?{div=64},?{div=64})">
        %2253 = "cute.get_iter"(%2239) : (!cute.coord_tensor<"(0,0)", "(?,?{div=8}):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(0,0)">
        %2254 = "cute.add_offset"(%2253, %2252) : (!cute.arith_tuple_iter<"(0,0)">, !cute.int_tuple<"(?{div=64},?{div=64})">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=64})">
        %2255 = "cute.make_view"(%2254) : (!cute.arith_tuple_iter<"(?{div=64},?{div=64})">) -> !cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">
        %2256:2 = "scf.if"(%2191) ({
          %2925 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
          %2926 = "cute.get_iter"(%2255) : (!cute.coord_tensor<"(?{div=64},?{div=64})", "(64,64):(1@0,1@1)">) -> !cute.arith_tuple_iter<"(?{div=64},?{div=64})">
          %2927 = "cute.get_scalars"(%2925) <{only_dynamic}> : (!cute.coord<"?">) -> i32
          %2928 = "arith.constant"() <{value = 32 : i32}> : () -> i32
          %2929 = "arith.remsi"(%2927, %2928) : (i32, i32) -> i32
          %2930 = "arith.constant"() <{value = 32 : i32}> : () -> i32
          %2931 = "arith.divsi"(%2927, %2930) : (i32, i32) -> i32
          %2932 = "arith.constant"() <{value = 4 : i32}> : () -> i32
          %2933 = "arith.remsi"(%2931, %2932) : (i32, i32) -> i32
          %2934 = "arith.constant"() <{value = 32 : i32}> : () -> i32
          %2935 = "arith.remsi"(%2929, %2934) : (i32, i32) -> i32
          %2936 = "arith.constant"() <{value = 4 : i32}> : () -> i32
          %2937 = "arith.remsi"(%2933, %2936) : (i32, i32) -> i32
          %2938 = "arith.constant"() <{value = 4 : i32}> : () -> i32
          %2939 = "arith.divsi"(%2935, %2938) : (i32, i32) -> i32
          %2940 = "arith.constant"() <{value = 4 : i32}> : () -> i32
          %2941 = "arith.remsi"(%2935, %2940) : (i32, i32) -> i32
          %2942 = "arith.constant"() <{value = 2 : i32}> : () -> i32
          %2943 = "arith.muli"(%2941, %2942) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %2944 = "arith.constant"() <{value = 16 : i32}> : () -> i32
          %2945 = "arith.muli"(%2937, %2944) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %2946 = "arith.addi"(%2939, %2945) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
          %2947 = "cute.assume"(%2943) : (i32) -> !cute.i32<divby 2>
          %2948 = "cute.make_int_tuple"(%2946, %2947) : (i32, !cute.i32<divby 2>) -> !cute.int_tuple<"(?,?{div=2})">
          %2949 = "cute.add_offset"(%2926, %2948) : (!cute.arith_tuple_iter<"(?{div=64},?{div=64})">, !cute.int_tuple<"(?,?{div=2})">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2950 = "cute.make_view"(%2949) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">
          %2951 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
          %2952 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2953 = "cute.add_offset"(%2952, %2951) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2954 = "cute.make_view"(%2953) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %2955 = "cute.get_iter"(%2954) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2956 = "cute.deref_arith_tuple_iter"(%2955) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %2957:2 = "cute.get_leaves"(%2956) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %2958 = "cute.static"() : () -> !cute.int_tuple<"(0,0)">
          %2959 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2960 = "cute.add_offset"(%2959, %2958) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2961 = "cute.make_view"(%2960) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %2962 = "cute.get_iter"(%2961) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2963 = "cute.deref_arith_tuple_iter"(%2962) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %2964:2 = "cute.get_leaves"(%2963) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %2965 = "cute.make_coord"(%2957#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2966 = "cute.make_coord"(%2964#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %2967 = "cute.get_scalars"(%2965) : (!cute.coord<"?">) -> i32
          %2968 = "cute.get_scalars"(%2966) : (!cute.coord<"?{div=2}">) -> i32
          %2969 = "arith.constant"() <{value = true}> : () -> i1
          %2970 = "arith.cmpi"(%2967, %2968) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %2971 = "arith.andi"(%2969, %2970) : (i1, i1) -> i1
          %2972 = "scf.if"(%2971) ({
            %3717 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3718 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
            "cute.memref.store"(%2218, %3718, %3717) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
            "scf.yield"(%2218) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%2218) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %2973 = "cute.static"() : () -> !cute.int_tuple<"(0,8)">
          %2974 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2975 = "cute.add_offset"(%2974, %2973) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,8)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2976 = "cute.make_view"(%2975) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %2977 = "cute.get_iter"(%2976) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2978 = "cute.deref_arith_tuple_iter"(%2977) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %2979:2 = "cute.get_leaves"(%2978) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %2980 = "cute.static"() : () -> !cute.int_tuple<"(0,8)">
          %2981 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2982 = "cute.add_offset"(%2981, %2980) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,8)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2983 = "cute.make_view"(%2982) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %2984 = "cute.get_iter"(%2983) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2985 = "cute.deref_arith_tuple_iter"(%2984) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %2986:2 = "cute.get_leaves"(%2985) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %2987 = "cute.make_coord"(%2979#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %2988 = "cute.make_coord"(%2986#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %2989 = "cute.get_scalars"(%2987) : (!cute.coord<"?">) -> i32
          %2990 = "cute.get_scalars"(%2988) : (!cute.coord<"?{div=2}">) -> i32
          %2991 = "arith.constant"() <{value = true}> : () -> i1
          %2992 = "arith.cmpi"(%2989, %2990) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %2993 = "arith.andi"(%2991, %2992) : (i1, i1) -> i1
          %2994 = "scf.if"(%2993) ({
            %3715 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3716 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
            "cute.memref.store"(%2972, %3716, %3715) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
            "scf.yield"(%2972) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%2972) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %2995 = "cute.static"() : () -> !cute.int_tuple<"(0,16)">
          %2996 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2997 = "cute.add_offset"(%2996, %2995) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,16)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %2998 = "cute.make_view"(%2997) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %2999 = "cute.get_iter"(%2998) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3000 = "cute.deref_arith_tuple_iter"(%2999) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3001:2 = "cute.get_leaves"(%3000) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3002 = "cute.static"() : () -> !cute.int_tuple<"(0,16)">
          %3003 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3004 = "cute.add_offset"(%3003, %3002) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,16)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3005 = "cute.make_view"(%3004) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3006 = "cute.get_iter"(%3005) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3007 = "cute.deref_arith_tuple_iter"(%3006) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3008:2 = "cute.get_leaves"(%3007) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3009 = "cute.make_coord"(%3001#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3010 = "cute.make_coord"(%3008#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3011 = "cute.get_scalars"(%3009) : (!cute.coord<"?">) -> i32
          %3012 = "cute.get_scalars"(%3010) : (!cute.coord<"?{div=2}">) -> i32
          %3013 = "arith.constant"() <{value = true}> : () -> i1
          %3014 = "arith.cmpi"(%3011, %3012) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3015 = "arith.andi"(%3013, %3014) : (i1, i1) -> i1
          %3016 = "scf.if"(%3015) ({
            %3713 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3714 = "cute.static"() : () -> !cute.coord<"(0,0,2)">
            "cute.memref.store"(%2994, %3714, %3713) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
            "scf.yield"(%2994) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%2994) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3017 = "cute.static"() : () -> !cute.int_tuple<"(0,24)">
          %3018 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3019 = "cute.add_offset"(%3018, %3017) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,24)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3020 = "cute.make_view"(%3019) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3021 = "cute.get_iter"(%3020) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3022 = "cute.deref_arith_tuple_iter"(%3021) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3023:2 = "cute.get_leaves"(%3022) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3024 = "cute.static"() : () -> !cute.int_tuple<"(0,24)">
          %3025 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3026 = "cute.add_offset"(%3025, %3024) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,24)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3027 = "cute.make_view"(%3026) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3028 = "cute.get_iter"(%3027) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3029 = "cute.deref_arith_tuple_iter"(%3028) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3030:2 = "cute.get_leaves"(%3029) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3031 = "cute.make_coord"(%3023#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3032 = "cute.make_coord"(%3030#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3033 = "cute.get_scalars"(%3031) : (!cute.coord<"?">) -> i32
          %3034 = "cute.get_scalars"(%3032) : (!cute.coord<"?{div=2}">) -> i32
          %3035 = "arith.constant"() <{value = true}> : () -> i1
          %3036 = "arith.cmpi"(%3033, %3034) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3037 = "arith.andi"(%3035, %3036) : (i1, i1) -> i1
          %3038 = "scf.if"(%3037) ({
            %3711 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3712 = "cute.static"() : () -> !cute.coord<"(0,0,3)">
            "cute.memref.store"(%3016, %3712, %3711) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
            "scf.yield"(%3016) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3016) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3039 = "cute.static"() : () -> !cute.int_tuple<"(0,32)">
          %3040 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3041 = "cute.add_offset"(%3040, %3039) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,32)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3042 = "cute.make_view"(%3041) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3043 = "cute.get_iter"(%3042) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3044 = "cute.deref_arith_tuple_iter"(%3043) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3045:2 = "cute.get_leaves"(%3044) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3046 = "cute.static"() : () -> !cute.int_tuple<"(0,32)">
          %3047 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3048 = "cute.add_offset"(%3047, %3046) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,32)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3049 = "cute.make_view"(%3048) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3050 = "cute.get_iter"(%3049) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3051 = "cute.deref_arith_tuple_iter"(%3050) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3052:2 = "cute.get_leaves"(%3051) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3053 = "cute.make_coord"(%3045#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3054 = "cute.make_coord"(%3052#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3055 = "cute.get_scalars"(%3053) : (!cute.coord<"?">) -> i32
          %3056 = "cute.get_scalars"(%3054) : (!cute.coord<"?{div=2}">) -> i32
          %3057 = "arith.constant"() <{value = true}> : () -> i1
          %3058 = "arith.cmpi"(%3055, %3056) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3059 = "arith.andi"(%3057, %3058) : (i1, i1) -> i1
          %3060 = "scf.if"(%3059) ({
            %3709 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3710 = "cute.static"() : () -> !cute.coord<"(0,0,4)">
            "cute.memref.store"(%3038, %3710, %3709) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
            "scf.yield"(%3038) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3038) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3061 = "cute.static"() : () -> !cute.int_tuple<"(0,40)">
          %3062 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3063 = "cute.add_offset"(%3062, %3061) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,40)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3064 = "cute.make_view"(%3063) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3065 = "cute.get_iter"(%3064) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3066 = "cute.deref_arith_tuple_iter"(%3065) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3067:2 = "cute.get_leaves"(%3066) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3068 = "cute.static"() : () -> !cute.int_tuple<"(0,40)">
          %3069 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3070 = "cute.add_offset"(%3069, %3068) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,40)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3071 = "cute.make_view"(%3070) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3072 = "cute.get_iter"(%3071) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3073 = "cute.deref_arith_tuple_iter"(%3072) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3074:2 = "cute.get_leaves"(%3073) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3075 = "cute.make_coord"(%3067#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3076 = "cute.make_coord"(%3074#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3077 = "cute.get_scalars"(%3075) : (!cute.coord<"?">) -> i32
          %3078 = "cute.get_scalars"(%3076) : (!cute.coord<"?{div=2}">) -> i32
          %3079 = "arith.constant"() <{value = true}> : () -> i1
          %3080 = "arith.cmpi"(%3077, %3078) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3081 = "arith.andi"(%3079, %3080) : (i1, i1) -> i1
          %3082 = "scf.if"(%3081) ({
            %3707 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3708 = "cute.static"() : () -> !cute.coord<"(0,0,5)">
            "cute.memref.store"(%3060, %3708, %3707) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
            "scf.yield"(%3060) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3060) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3083 = "cute.static"() : () -> !cute.int_tuple<"(0,48)">
          %3084 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3085 = "cute.add_offset"(%3084, %3083) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,48)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3086 = "cute.make_view"(%3085) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3087 = "cute.get_iter"(%3086) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3088 = "cute.deref_arith_tuple_iter"(%3087) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3089:2 = "cute.get_leaves"(%3088) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3090 = "cute.static"() : () -> !cute.int_tuple<"(0,48)">
          %3091 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3092 = "cute.add_offset"(%3091, %3090) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,48)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3093 = "cute.make_view"(%3092) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3094 = "cute.get_iter"(%3093) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3095 = "cute.deref_arith_tuple_iter"(%3094) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3096:2 = "cute.get_leaves"(%3095) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3097 = "cute.make_coord"(%3089#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3098 = "cute.make_coord"(%3096#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3099 = "cute.get_scalars"(%3097) : (!cute.coord<"?">) -> i32
          %3100 = "cute.get_scalars"(%3098) : (!cute.coord<"?{div=2}">) -> i32
          %3101 = "arith.constant"() <{value = true}> : () -> i1
          %3102 = "arith.cmpi"(%3099, %3100) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3103 = "arith.andi"(%3101, %3102) : (i1, i1) -> i1
          %3104 = "scf.if"(%3103) ({
            %3705 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3706 = "cute.static"() : () -> !cute.coord<"(0,0,6)">
            "cute.memref.store"(%3082, %3706, %3705) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
            "scf.yield"(%3082) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3082) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3105 = "cute.static"() : () -> !cute.int_tuple<"(0,56)">
          %3106 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3107 = "cute.add_offset"(%3106, %3105) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,56)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3108 = "cute.make_view"(%3107) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3109 = "cute.get_iter"(%3108) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3110 = "cute.deref_arith_tuple_iter"(%3109) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3111:2 = "cute.get_leaves"(%3110) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3112 = "cute.static"() : () -> !cute.int_tuple<"(0,56)">
          %3113 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3114 = "cute.add_offset"(%3113, %3112) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,56)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3115 = "cute.make_view"(%3114) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3116 = "cute.get_iter"(%3115) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3117 = "cute.deref_arith_tuple_iter"(%3116) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3118:2 = "cute.get_leaves"(%3117) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3119 = "cute.make_coord"(%3111#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3120 = "cute.make_coord"(%3118#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3121 = "cute.get_scalars"(%3119) : (!cute.coord<"?">) -> i32
          %3122 = "cute.get_scalars"(%3120) : (!cute.coord<"?{div=2}">) -> i32
          %3123 = "arith.constant"() <{value = true}> : () -> i1
          %3124 = "arith.cmpi"(%3121, %3122) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3125 = "arith.andi"(%3123, %3124) : (i1, i1) -> i1
          %3126 = "scf.if"(%3125) ({
            %3703 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3704 = "cute.static"() : () -> !cute.coord<"(0,0,7)">
            "cute.memref.store"(%3104, %3704, %3703) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
            "scf.yield"(%3104) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3104) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3127 = "cute.static"() : () -> !cute.int_tuple<"(0,1)">
          %3128 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3129 = "cute.add_offset"(%3128, %3127) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,1)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3130 = "cute.make_view"(%3129) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3131 = "cute.get_iter"(%3130) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3132 = "cute.deref_arith_tuple_iter"(%3131) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3133:2 = "cute.get_leaves"(%3132) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3134 = "cute.static"() : () -> !cute.int_tuple<"(0,1)">
          %3135 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3136 = "cute.add_offset"(%3135, %3134) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,1)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3137 = "cute.make_view"(%3136) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3138 = "cute.get_iter"(%3137) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3139 = "cute.deref_arith_tuple_iter"(%3138) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3140:2 = "cute.get_leaves"(%3139) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3141 = "cute.make_coord"(%3133#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3142 = "cute.make_coord"(%3140#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3143 = "cute.get_scalars"(%3141) : (!cute.coord<"?">) -> i32
          %3144 = "cute.get_scalars"(%3142) : (!cute.coord<"?">) -> i32
          %3145 = "arith.constant"() <{value = true}> : () -> i1
          %3146 = "arith.cmpi"(%3143, %3144) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3147 = "arith.andi"(%3145, %3146) : (i1, i1) -> i1
          %3148 = "scf.if"(%3147) ({
            %3701 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3702 = "cute.static"() : () -> !cute.coord<"(1,0,0)">
            "cute.memref.store"(%3126, %3702, %3701) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
            "scf.yield"(%3126) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3126) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3149 = "cute.static"() : () -> !cute.int_tuple<"(0,9)">
          %3150 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3151 = "cute.add_offset"(%3150, %3149) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,9)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3152 = "cute.make_view"(%3151) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3153 = "cute.get_iter"(%3152) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3154 = "cute.deref_arith_tuple_iter"(%3153) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3155:2 = "cute.get_leaves"(%3154) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3156 = "cute.static"() : () -> !cute.int_tuple<"(0,9)">
          %3157 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3158 = "cute.add_offset"(%3157, %3156) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,9)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3159 = "cute.make_view"(%3158) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3160 = "cute.get_iter"(%3159) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3161 = "cute.deref_arith_tuple_iter"(%3160) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3162:2 = "cute.get_leaves"(%3161) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3163 = "cute.make_coord"(%3155#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3164 = "cute.make_coord"(%3162#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3165 = "cute.get_scalars"(%3163) : (!cute.coord<"?">) -> i32
          %3166 = "cute.get_scalars"(%3164) : (!cute.coord<"?">) -> i32
          %3167 = "arith.constant"() <{value = true}> : () -> i1
          %3168 = "arith.cmpi"(%3165, %3166) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3169 = "arith.andi"(%3167, %3168) : (i1, i1) -> i1
          %3170 = "scf.if"(%3169) ({
            %3699 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3700 = "cute.static"() : () -> !cute.coord<"(1,0,1)">
            "cute.memref.store"(%3148, %3700, %3699) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
            "scf.yield"(%3148) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3148) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3171 = "cute.static"() : () -> !cute.int_tuple<"(0,17)">
          %3172 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3173 = "cute.add_offset"(%3172, %3171) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,17)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3174 = "cute.make_view"(%3173) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3175 = "cute.get_iter"(%3174) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3176 = "cute.deref_arith_tuple_iter"(%3175) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3177:2 = "cute.get_leaves"(%3176) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3178 = "cute.static"() : () -> !cute.int_tuple<"(0,17)">
          %3179 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3180 = "cute.add_offset"(%3179, %3178) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,17)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3181 = "cute.make_view"(%3180) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3182 = "cute.get_iter"(%3181) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3183 = "cute.deref_arith_tuple_iter"(%3182) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3184:2 = "cute.get_leaves"(%3183) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3185 = "cute.make_coord"(%3177#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3186 = "cute.make_coord"(%3184#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3187 = "cute.get_scalars"(%3185) : (!cute.coord<"?">) -> i32
          %3188 = "cute.get_scalars"(%3186) : (!cute.coord<"?">) -> i32
          %3189 = "arith.constant"() <{value = true}> : () -> i1
          %3190 = "arith.cmpi"(%3187, %3188) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3191 = "arith.andi"(%3189, %3190) : (i1, i1) -> i1
          %3192 = "scf.if"(%3191) ({
            %3697 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3698 = "cute.static"() : () -> !cute.coord<"(1,0,2)">
            "cute.memref.store"(%3170, %3698, %3697) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
            "scf.yield"(%3170) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3170) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3193 = "cute.static"() : () -> !cute.int_tuple<"(0,25)">
          %3194 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3195 = "cute.add_offset"(%3194, %3193) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,25)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3196 = "cute.make_view"(%3195) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3197 = "cute.get_iter"(%3196) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3198 = "cute.deref_arith_tuple_iter"(%3197) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3199:2 = "cute.get_leaves"(%3198) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3200 = "cute.static"() : () -> !cute.int_tuple<"(0,25)">
          %3201 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3202 = "cute.add_offset"(%3201, %3200) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,25)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3203 = "cute.make_view"(%3202) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3204 = "cute.get_iter"(%3203) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3205 = "cute.deref_arith_tuple_iter"(%3204) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3206:2 = "cute.get_leaves"(%3205) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3207 = "cute.make_coord"(%3199#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3208 = "cute.make_coord"(%3206#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3209 = "cute.get_scalars"(%3207) : (!cute.coord<"?">) -> i32
          %3210 = "cute.get_scalars"(%3208) : (!cute.coord<"?">) -> i32
          %3211 = "arith.constant"() <{value = true}> : () -> i1
          %3212 = "arith.cmpi"(%3209, %3210) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3213 = "arith.andi"(%3211, %3212) : (i1, i1) -> i1
          %3214 = "scf.if"(%3213) ({
            %3695 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3696 = "cute.static"() : () -> !cute.coord<"(1,0,3)">
            "cute.memref.store"(%3192, %3696, %3695) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
            "scf.yield"(%3192) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3192) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3215 = "cute.static"() : () -> !cute.int_tuple<"(0,33)">
          %3216 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3217 = "cute.add_offset"(%3216, %3215) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,33)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3218 = "cute.make_view"(%3217) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3219 = "cute.get_iter"(%3218) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3220 = "cute.deref_arith_tuple_iter"(%3219) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3221:2 = "cute.get_leaves"(%3220) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3222 = "cute.static"() : () -> !cute.int_tuple<"(0,33)">
          %3223 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3224 = "cute.add_offset"(%3223, %3222) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,33)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3225 = "cute.make_view"(%3224) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3226 = "cute.get_iter"(%3225) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3227 = "cute.deref_arith_tuple_iter"(%3226) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3228:2 = "cute.get_leaves"(%3227) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3229 = "cute.make_coord"(%3221#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3230 = "cute.make_coord"(%3228#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3231 = "cute.get_scalars"(%3229) : (!cute.coord<"?">) -> i32
          %3232 = "cute.get_scalars"(%3230) : (!cute.coord<"?">) -> i32
          %3233 = "arith.constant"() <{value = true}> : () -> i1
          %3234 = "arith.cmpi"(%3231, %3232) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3235 = "arith.andi"(%3233, %3234) : (i1, i1) -> i1
          %3236 = "scf.if"(%3235) ({
            %3693 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3694 = "cute.static"() : () -> !cute.coord<"(1,0,4)">
            "cute.memref.store"(%3214, %3694, %3693) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
            "scf.yield"(%3214) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3214) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3237 = "cute.static"() : () -> !cute.int_tuple<"(0,41)">
          %3238 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3239 = "cute.add_offset"(%3238, %3237) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,41)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3240 = "cute.make_view"(%3239) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3241 = "cute.get_iter"(%3240) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3242 = "cute.deref_arith_tuple_iter"(%3241) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3243:2 = "cute.get_leaves"(%3242) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3244 = "cute.static"() : () -> !cute.int_tuple<"(0,41)">
          %3245 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3246 = "cute.add_offset"(%3245, %3244) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,41)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3247 = "cute.make_view"(%3246) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3248 = "cute.get_iter"(%3247) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3249 = "cute.deref_arith_tuple_iter"(%3248) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3250:2 = "cute.get_leaves"(%3249) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3251 = "cute.make_coord"(%3243#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3252 = "cute.make_coord"(%3250#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3253 = "cute.get_scalars"(%3251) : (!cute.coord<"?">) -> i32
          %3254 = "cute.get_scalars"(%3252) : (!cute.coord<"?">) -> i32
          %3255 = "arith.constant"() <{value = true}> : () -> i1
          %3256 = "arith.cmpi"(%3253, %3254) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3257 = "arith.andi"(%3255, %3256) : (i1, i1) -> i1
          %3258 = "scf.if"(%3257) ({
            %3691 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3692 = "cute.static"() : () -> !cute.coord<"(1,0,5)">
            "cute.memref.store"(%3236, %3692, %3691) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
            "scf.yield"(%3236) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3236) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3259 = "cute.static"() : () -> !cute.int_tuple<"(0,49)">
          %3260 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3261 = "cute.add_offset"(%3260, %3259) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,49)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3262 = "cute.make_view"(%3261) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3263 = "cute.get_iter"(%3262) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3264 = "cute.deref_arith_tuple_iter"(%3263) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3265:2 = "cute.get_leaves"(%3264) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3266 = "cute.static"() : () -> !cute.int_tuple<"(0,49)">
          %3267 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3268 = "cute.add_offset"(%3267, %3266) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,49)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3269 = "cute.make_view"(%3268) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3270 = "cute.get_iter"(%3269) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3271 = "cute.deref_arith_tuple_iter"(%3270) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3272:2 = "cute.get_leaves"(%3271) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3273 = "cute.make_coord"(%3265#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3274 = "cute.make_coord"(%3272#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3275 = "cute.get_scalars"(%3273) : (!cute.coord<"?">) -> i32
          %3276 = "cute.get_scalars"(%3274) : (!cute.coord<"?">) -> i32
          %3277 = "arith.constant"() <{value = true}> : () -> i1
          %3278 = "arith.cmpi"(%3275, %3276) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3279 = "arith.andi"(%3277, %3278) : (i1, i1) -> i1
          %3280 = "scf.if"(%3279) ({
            %3689 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3690 = "cute.static"() : () -> !cute.coord<"(1,0,6)">
            "cute.memref.store"(%3258, %3690, %3689) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
            "scf.yield"(%3258) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3258) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3281 = "cute.static"() : () -> !cute.int_tuple<"(0,57)">
          %3282 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3283 = "cute.add_offset"(%3282, %3281) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,57)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3284 = "cute.make_view"(%3283) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3285 = "cute.get_iter"(%3284) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3286 = "cute.deref_arith_tuple_iter"(%3285) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3287:2 = "cute.get_leaves"(%3286) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3288 = "cute.static"() : () -> !cute.int_tuple<"(0,57)">
          %3289 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3290 = "cute.add_offset"(%3289, %3288) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(0,57)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3291 = "cute.make_view"(%3290) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3292 = "cute.get_iter"(%3291) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3293 = "cute.deref_arith_tuple_iter"(%3292) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3294:2 = "cute.get_leaves"(%3293) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3295 = "cute.make_coord"(%3287#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3296 = "cute.make_coord"(%3294#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3297 = "cute.get_scalars"(%3295) : (!cute.coord<"?">) -> i32
          %3298 = "cute.get_scalars"(%3296) : (!cute.coord<"?">) -> i32
          %3299 = "arith.constant"() <{value = true}> : () -> i1
          %3300 = "arith.cmpi"(%3297, %3298) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3301 = "arith.andi"(%3299, %3300) : (i1, i1) -> i1
          %3302 = "scf.if"(%3301) ({
            %3687 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3688 = "cute.static"() : () -> !cute.coord<"(1,0,7)">
            "cute.memref.store"(%3280, %3688, %3687) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
            "scf.yield"(%3280) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3280) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3303 = "cute.static"() : () -> !cute.int_tuple<"(8,0)">
          %3304 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3305 = "cute.add_offset"(%3304, %3303) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,0)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3306 = "cute.make_view"(%3305) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3307 = "cute.get_iter"(%3306) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3308 = "cute.deref_arith_tuple_iter"(%3307) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3309:2 = "cute.get_leaves"(%3308) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3310 = "cute.static"() : () -> !cute.int_tuple<"(8,0)">
          %3311 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3312 = "cute.add_offset"(%3311, %3310) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,0)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3313 = "cute.make_view"(%3312) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3314 = "cute.get_iter"(%3313) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3315 = "cute.deref_arith_tuple_iter"(%3314) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3316:2 = "cute.get_leaves"(%3315) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3317 = "cute.make_coord"(%3309#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3318 = "cute.make_coord"(%3316#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3319 = "cute.get_scalars"(%3317) : (!cute.coord<"?">) -> i32
          %3320 = "cute.get_scalars"(%3318) : (!cute.coord<"?{div=2}">) -> i32
          %3321 = "arith.constant"() <{value = true}> : () -> i1
          %3322 = "arith.cmpi"(%3319, %3320) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3323 = "arith.andi"(%3321, %3322) : (i1, i1) -> i1
          %3324 = "scf.if"(%3323) ({
            %3685 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3686 = "cute.static"() : () -> !cute.coord<"(2,0,0)">
            "cute.memref.store"(%3302, %3686, %3685) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
            "scf.yield"(%3302) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3302) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3325 = "cute.static"() : () -> !cute.int_tuple<"(8,8)">
          %3326 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3327 = "cute.add_offset"(%3326, %3325) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,8)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3328 = "cute.make_view"(%3327) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3329 = "cute.get_iter"(%3328) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3330 = "cute.deref_arith_tuple_iter"(%3329) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3331:2 = "cute.get_leaves"(%3330) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3332 = "cute.static"() : () -> !cute.int_tuple<"(8,8)">
          %3333 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3334 = "cute.add_offset"(%3333, %3332) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,8)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3335 = "cute.make_view"(%3334) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3336 = "cute.get_iter"(%3335) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3337 = "cute.deref_arith_tuple_iter"(%3336) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3338:2 = "cute.get_leaves"(%3337) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3339 = "cute.make_coord"(%3331#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3340 = "cute.make_coord"(%3338#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3341 = "cute.get_scalars"(%3339) : (!cute.coord<"?">) -> i32
          %3342 = "cute.get_scalars"(%3340) : (!cute.coord<"?{div=2}">) -> i32
          %3343 = "arith.constant"() <{value = true}> : () -> i1
          %3344 = "arith.cmpi"(%3341, %3342) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3345 = "arith.andi"(%3343, %3344) : (i1, i1) -> i1
          %3346 = "scf.if"(%3345) ({
            %3683 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3684 = "cute.static"() : () -> !cute.coord<"(2,0,1)">
            "cute.memref.store"(%3324, %3684, %3683) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
            "scf.yield"(%3324) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3324) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3347 = "cute.static"() : () -> !cute.int_tuple<"(8,16)">
          %3348 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3349 = "cute.add_offset"(%3348, %3347) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,16)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3350 = "cute.make_view"(%3349) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3351 = "cute.get_iter"(%3350) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3352 = "cute.deref_arith_tuple_iter"(%3351) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3353:2 = "cute.get_leaves"(%3352) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3354 = "cute.static"() : () -> !cute.int_tuple<"(8,16)">
          %3355 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3356 = "cute.add_offset"(%3355, %3354) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,16)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3357 = "cute.make_view"(%3356) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3358 = "cute.get_iter"(%3357) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3359 = "cute.deref_arith_tuple_iter"(%3358) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3360:2 = "cute.get_leaves"(%3359) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3361 = "cute.make_coord"(%3353#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3362 = "cute.make_coord"(%3360#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3363 = "cute.get_scalars"(%3361) : (!cute.coord<"?">) -> i32
          %3364 = "cute.get_scalars"(%3362) : (!cute.coord<"?{div=2}">) -> i32
          %3365 = "arith.constant"() <{value = true}> : () -> i1
          %3366 = "arith.cmpi"(%3363, %3364) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3367 = "arith.andi"(%3365, %3366) : (i1, i1) -> i1
          %3368 = "scf.if"(%3367) ({
            %3681 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3682 = "cute.static"() : () -> !cute.coord<"(2,0,2)">
            "cute.memref.store"(%3346, %3682, %3681) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
            "scf.yield"(%3346) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3346) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3369 = "cute.static"() : () -> !cute.int_tuple<"(8,24)">
          %3370 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3371 = "cute.add_offset"(%3370, %3369) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,24)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3372 = "cute.make_view"(%3371) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3373 = "cute.get_iter"(%3372) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3374 = "cute.deref_arith_tuple_iter"(%3373) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3375:2 = "cute.get_leaves"(%3374) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3376 = "cute.static"() : () -> !cute.int_tuple<"(8,24)">
          %3377 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3378 = "cute.add_offset"(%3377, %3376) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,24)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3379 = "cute.make_view"(%3378) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3380 = "cute.get_iter"(%3379) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3381 = "cute.deref_arith_tuple_iter"(%3380) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3382:2 = "cute.get_leaves"(%3381) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3383 = "cute.make_coord"(%3375#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3384 = "cute.make_coord"(%3382#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3385 = "cute.get_scalars"(%3383) : (!cute.coord<"?">) -> i32
          %3386 = "cute.get_scalars"(%3384) : (!cute.coord<"?{div=2}">) -> i32
          %3387 = "arith.constant"() <{value = true}> : () -> i1
          %3388 = "arith.cmpi"(%3385, %3386) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3389 = "arith.andi"(%3387, %3388) : (i1, i1) -> i1
          %3390 = "scf.if"(%3389) ({
            %3679 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3680 = "cute.static"() : () -> !cute.coord<"(2,0,3)">
            "cute.memref.store"(%3368, %3680, %3679) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
            "scf.yield"(%3368) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3368) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3391 = "cute.static"() : () -> !cute.int_tuple<"(8,32)">
          %3392 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3393 = "cute.add_offset"(%3392, %3391) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,32)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3394 = "cute.make_view"(%3393) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3395 = "cute.get_iter"(%3394) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3396 = "cute.deref_arith_tuple_iter"(%3395) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3397:2 = "cute.get_leaves"(%3396) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3398 = "cute.static"() : () -> !cute.int_tuple<"(8,32)">
          %3399 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3400 = "cute.add_offset"(%3399, %3398) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,32)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3401 = "cute.make_view"(%3400) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3402 = "cute.get_iter"(%3401) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3403 = "cute.deref_arith_tuple_iter"(%3402) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3404:2 = "cute.get_leaves"(%3403) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3405 = "cute.make_coord"(%3397#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3406 = "cute.make_coord"(%3404#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3407 = "cute.get_scalars"(%3405) : (!cute.coord<"?">) -> i32
          %3408 = "cute.get_scalars"(%3406) : (!cute.coord<"?{div=2}">) -> i32
          %3409 = "arith.constant"() <{value = true}> : () -> i1
          %3410 = "arith.cmpi"(%3407, %3408) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3411 = "arith.andi"(%3409, %3410) : (i1, i1) -> i1
          %3412 = "scf.if"(%3411) ({
            %3677 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3678 = "cute.static"() : () -> !cute.coord<"(2,0,4)">
            "cute.memref.store"(%3390, %3678, %3677) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
            "scf.yield"(%3390) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3390) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3413 = "cute.static"() : () -> !cute.int_tuple<"(8,40)">
          %3414 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3415 = "cute.add_offset"(%3414, %3413) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,40)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3416 = "cute.make_view"(%3415) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3417 = "cute.get_iter"(%3416) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3418 = "cute.deref_arith_tuple_iter"(%3417) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3419:2 = "cute.get_leaves"(%3418) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3420 = "cute.static"() : () -> !cute.int_tuple<"(8,40)">
          %3421 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3422 = "cute.add_offset"(%3421, %3420) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,40)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3423 = "cute.make_view"(%3422) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3424 = "cute.get_iter"(%3423) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3425 = "cute.deref_arith_tuple_iter"(%3424) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3426:2 = "cute.get_leaves"(%3425) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3427 = "cute.make_coord"(%3419#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3428 = "cute.make_coord"(%3426#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3429 = "cute.get_scalars"(%3427) : (!cute.coord<"?">) -> i32
          %3430 = "cute.get_scalars"(%3428) : (!cute.coord<"?{div=2}">) -> i32
          %3431 = "arith.constant"() <{value = true}> : () -> i1
          %3432 = "arith.cmpi"(%3429, %3430) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3433 = "arith.andi"(%3431, %3432) : (i1, i1) -> i1
          %3434 = "scf.if"(%3433) ({
            %3675 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3676 = "cute.static"() : () -> !cute.coord<"(2,0,5)">
            "cute.memref.store"(%3412, %3676, %3675) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
            "scf.yield"(%3412) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3412) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3435 = "cute.static"() : () -> !cute.int_tuple<"(8,48)">
          %3436 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3437 = "cute.add_offset"(%3436, %3435) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,48)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3438 = "cute.make_view"(%3437) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3439 = "cute.get_iter"(%3438) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3440 = "cute.deref_arith_tuple_iter"(%3439) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3441:2 = "cute.get_leaves"(%3440) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3442 = "cute.static"() : () -> !cute.int_tuple<"(8,48)">
          %3443 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3444 = "cute.add_offset"(%3443, %3442) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,48)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3445 = "cute.make_view"(%3444) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3446 = "cute.get_iter"(%3445) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3447 = "cute.deref_arith_tuple_iter"(%3446) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3448:2 = "cute.get_leaves"(%3447) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3449 = "cute.make_coord"(%3441#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3450 = "cute.make_coord"(%3448#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3451 = "cute.get_scalars"(%3449) : (!cute.coord<"?">) -> i32
          %3452 = "cute.get_scalars"(%3450) : (!cute.coord<"?{div=2}">) -> i32
          %3453 = "arith.constant"() <{value = true}> : () -> i1
          %3454 = "arith.cmpi"(%3451, %3452) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3455 = "arith.andi"(%3453, %3454) : (i1, i1) -> i1
          %3456 = "scf.if"(%3455) ({
            %3673 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3674 = "cute.static"() : () -> !cute.coord<"(2,0,6)">
            "cute.memref.store"(%3434, %3674, %3673) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
            "scf.yield"(%3434) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3434) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3457 = "cute.static"() : () -> !cute.int_tuple<"(8,56)">
          %3458 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3459 = "cute.add_offset"(%3458, %3457) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,56)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3460 = "cute.make_view"(%3459) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3461 = "cute.get_iter"(%3460) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3462 = "cute.deref_arith_tuple_iter"(%3461) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3463:2 = "cute.get_leaves"(%3462) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3464 = "cute.static"() : () -> !cute.int_tuple<"(8,56)">
          %3465 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3466 = "cute.add_offset"(%3465, %3464) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,56)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3467 = "cute.make_view"(%3466) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.coord_tensor<"(?,?{div=2})", "():()">
          %3468 = "cute.get_iter"(%3467) : (!cute.coord_tensor<"(?,?{div=2})", "():()">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3469 = "cute.deref_arith_tuple_iter"(%3468) : (!cute.arith_tuple_iter<"(?,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2})">
          %3470:2 = "cute.get_leaves"(%3469) : (!cute.int_tuple<"(?,?{div=2})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">)
          %3471 = "cute.make_coord"(%3463#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3472 = "cute.make_coord"(%3470#1) : (!cute.int_tuple<"?{div=2}">) -> !cute.coord<"?{div=2}">
          %3473 = "cute.get_scalars"(%3471) : (!cute.coord<"?">) -> i32
          %3474 = "cute.get_scalars"(%3472) : (!cute.coord<"?{div=2}">) -> i32
          %3475 = "arith.constant"() <{value = true}> : () -> i1
          %3476 = "arith.cmpi"(%3473, %3474) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3477 = "arith.andi"(%3475, %3476) : (i1, i1) -> i1
          %3478 = "scf.if"(%3477) ({
            %3671 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3672 = "cute.static"() : () -> !cute.coord<"(2,0,7)">
            "cute.memref.store"(%3456, %3672, %3671) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
            "scf.yield"(%3456) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3456) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3479 = "cute.static"() : () -> !cute.int_tuple<"(8,1)">
          %3480 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3481 = "cute.add_offset"(%3480, %3479) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,1)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3482 = "cute.make_view"(%3481) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3483 = "cute.get_iter"(%3482) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3484 = "cute.deref_arith_tuple_iter"(%3483) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3485:2 = "cute.get_leaves"(%3484) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3486 = "cute.static"() : () -> !cute.int_tuple<"(8,1)">
          %3487 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3488 = "cute.add_offset"(%3487, %3486) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,1)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3489 = "cute.make_view"(%3488) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3490 = "cute.get_iter"(%3489) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3491 = "cute.deref_arith_tuple_iter"(%3490) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3492:2 = "cute.get_leaves"(%3491) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3493 = "cute.make_coord"(%3485#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3494 = "cute.make_coord"(%3492#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3495 = "cute.get_scalars"(%3493) : (!cute.coord<"?">) -> i32
          %3496 = "cute.get_scalars"(%3494) : (!cute.coord<"?">) -> i32
          %3497 = "arith.constant"() <{value = true}> : () -> i1
          %3498 = "arith.cmpi"(%3495, %3496) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3499 = "arith.andi"(%3497, %3498) : (i1, i1) -> i1
          %3500 = "scf.if"(%3499) ({
            %3669 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3670 = "cute.static"() : () -> !cute.coord<"(3,0,0)">
            "cute.memref.store"(%3478, %3670, %3669) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
            "scf.yield"(%3478) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3478) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3501 = "cute.static"() : () -> !cute.int_tuple<"(8,9)">
          %3502 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3503 = "cute.add_offset"(%3502, %3501) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,9)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3504 = "cute.make_view"(%3503) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3505 = "cute.get_iter"(%3504) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3506 = "cute.deref_arith_tuple_iter"(%3505) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3507:2 = "cute.get_leaves"(%3506) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3508 = "cute.static"() : () -> !cute.int_tuple<"(8,9)">
          %3509 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3510 = "cute.add_offset"(%3509, %3508) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,9)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3511 = "cute.make_view"(%3510) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3512 = "cute.get_iter"(%3511) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3513 = "cute.deref_arith_tuple_iter"(%3512) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3514:2 = "cute.get_leaves"(%3513) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3515 = "cute.make_coord"(%3507#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3516 = "cute.make_coord"(%3514#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3517 = "cute.get_scalars"(%3515) : (!cute.coord<"?">) -> i32
          %3518 = "cute.get_scalars"(%3516) : (!cute.coord<"?">) -> i32
          %3519 = "arith.constant"() <{value = true}> : () -> i1
          %3520 = "arith.cmpi"(%3517, %3518) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3521 = "arith.andi"(%3519, %3520) : (i1, i1) -> i1
          %3522 = "scf.if"(%3521) ({
            %3667 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3668 = "cute.static"() : () -> !cute.coord<"(3,0,1)">
            "cute.memref.store"(%3500, %3668, %3667) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
            "scf.yield"(%3500) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3500) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3523 = "cute.static"() : () -> !cute.int_tuple<"(8,17)">
          %3524 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3525 = "cute.add_offset"(%3524, %3523) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,17)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3526 = "cute.make_view"(%3525) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3527 = "cute.get_iter"(%3526) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3528 = "cute.deref_arith_tuple_iter"(%3527) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3529:2 = "cute.get_leaves"(%3528) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3530 = "cute.static"() : () -> !cute.int_tuple<"(8,17)">
          %3531 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3532 = "cute.add_offset"(%3531, %3530) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,17)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3533 = "cute.make_view"(%3532) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3534 = "cute.get_iter"(%3533) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3535 = "cute.deref_arith_tuple_iter"(%3534) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3536:2 = "cute.get_leaves"(%3535) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3537 = "cute.make_coord"(%3529#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3538 = "cute.make_coord"(%3536#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3539 = "cute.get_scalars"(%3537) : (!cute.coord<"?">) -> i32
          %3540 = "cute.get_scalars"(%3538) : (!cute.coord<"?">) -> i32
          %3541 = "arith.constant"() <{value = true}> : () -> i1
          %3542 = "arith.cmpi"(%3539, %3540) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3543 = "arith.andi"(%3541, %3542) : (i1, i1) -> i1
          %3544 = "scf.if"(%3543) ({
            %3665 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3666 = "cute.static"() : () -> !cute.coord<"(3,0,2)">
            "cute.memref.store"(%3522, %3666, %3665) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
            "scf.yield"(%3522) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3522) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3545 = "cute.static"() : () -> !cute.int_tuple<"(8,25)">
          %3546 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3547 = "cute.add_offset"(%3546, %3545) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,25)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3548 = "cute.make_view"(%3547) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3549 = "cute.get_iter"(%3548) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3550 = "cute.deref_arith_tuple_iter"(%3549) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3551:2 = "cute.get_leaves"(%3550) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3552 = "cute.static"() : () -> !cute.int_tuple<"(8,25)">
          %3553 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3554 = "cute.add_offset"(%3553, %3552) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,25)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3555 = "cute.make_view"(%3554) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3556 = "cute.get_iter"(%3555) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3557 = "cute.deref_arith_tuple_iter"(%3556) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3558:2 = "cute.get_leaves"(%3557) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3559 = "cute.make_coord"(%3551#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3560 = "cute.make_coord"(%3558#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3561 = "cute.get_scalars"(%3559) : (!cute.coord<"?">) -> i32
          %3562 = "cute.get_scalars"(%3560) : (!cute.coord<"?">) -> i32
          %3563 = "arith.constant"() <{value = true}> : () -> i1
          %3564 = "arith.cmpi"(%3561, %3562) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3565 = "arith.andi"(%3563, %3564) : (i1, i1) -> i1
          %3566 = "scf.if"(%3565) ({
            %3663 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3664 = "cute.static"() : () -> !cute.coord<"(3,0,3)">
            "cute.memref.store"(%3544, %3664, %3663) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
            "scf.yield"(%3544) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3544) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3567 = "cute.static"() : () -> !cute.int_tuple<"(8,33)">
          %3568 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3569 = "cute.add_offset"(%3568, %3567) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,33)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3570 = "cute.make_view"(%3569) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3571 = "cute.get_iter"(%3570) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3572 = "cute.deref_arith_tuple_iter"(%3571) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3573:2 = "cute.get_leaves"(%3572) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3574 = "cute.static"() : () -> !cute.int_tuple<"(8,33)">
          %3575 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3576 = "cute.add_offset"(%3575, %3574) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,33)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3577 = "cute.make_view"(%3576) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3578 = "cute.get_iter"(%3577) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3579 = "cute.deref_arith_tuple_iter"(%3578) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3580:2 = "cute.get_leaves"(%3579) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3581 = "cute.make_coord"(%3573#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3582 = "cute.make_coord"(%3580#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3583 = "cute.get_scalars"(%3581) : (!cute.coord<"?">) -> i32
          %3584 = "cute.get_scalars"(%3582) : (!cute.coord<"?">) -> i32
          %3585 = "arith.constant"() <{value = true}> : () -> i1
          %3586 = "arith.cmpi"(%3583, %3584) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3587 = "arith.andi"(%3585, %3586) : (i1, i1) -> i1
          %3588 = "scf.if"(%3587) ({
            %3661 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3662 = "cute.static"() : () -> !cute.coord<"(3,0,4)">
            "cute.memref.store"(%3566, %3662, %3661) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
            "scf.yield"(%3566) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3566) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3589 = "cute.static"() : () -> !cute.int_tuple<"(8,41)">
          %3590 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3591 = "cute.add_offset"(%3590, %3589) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,41)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3592 = "cute.make_view"(%3591) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3593 = "cute.get_iter"(%3592) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3594 = "cute.deref_arith_tuple_iter"(%3593) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3595:2 = "cute.get_leaves"(%3594) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3596 = "cute.static"() : () -> !cute.int_tuple<"(8,41)">
          %3597 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3598 = "cute.add_offset"(%3597, %3596) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,41)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3599 = "cute.make_view"(%3598) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3600 = "cute.get_iter"(%3599) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3601 = "cute.deref_arith_tuple_iter"(%3600) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3602:2 = "cute.get_leaves"(%3601) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3603 = "cute.make_coord"(%3595#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3604 = "cute.make_coord"(%3602#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3605 = "cute.get_scalars"(%3603) : (!cute.coord<"?">) -> i32
          %3606 = "cute.get_scalars"(%3604) : (!cute.coord<"?">) -> i32
          %3607 = "arith.constant"() <{value = true}> : () -> i1
          %3608 = "arith.cmpi"(%3605, %3606) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3609 = "arith.andi"(%3607, %3608) : (i1, i1) -> i1
          %3610 = "scf.if"(%3609) ({
            %3659 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3660 = "cute.static"() : () -> !cute.coord<"(3,0,5)">
            "cute.memref.store"(%3588, %3660, %3659) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
            "scf.yield"(%3588) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3588) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3611 = "cute.static"() : () -> !cute.int_tuple<"(8,49)">
          %3612 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3613 = "cute.add_offset"(%3612, %3611) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,49)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3614 = "cute.make_view"(%3613) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3615 = "cute.get_iter"(%3614) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3616 = "cute.deref_arith_tuple_iter"(%3615) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3617:2 = "cute.get_leaves"(%3616) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3618 = "cute.static"() : () -> !cute.int_tuple<"(8,49)">
          %3619 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3620 = "cute.add_offset"(%3619, %3618) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,49)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3621 = "cute.make_view"(%3620) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3622 = "cute.get_iter"(%3621) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3623 = "cute.deref_arith_tuple_iter"(%3622) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3624:2 = "cute.get_leaves"(%3623) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3625 = "cute.make_coord"(%3617#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3626 = "cute.make_coord"(%3624#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3627 = "cute.get_scalars"(%3625) : (!cute.coord<"?">) -> i32
          %3628 = "cute.get_scalars"(%3626) : (!cute.coord<"?">) -> i32
          %3629 = "arith.constant"() <{value = true}> : () -> i1
          %3630 = "arith.cmpi"(%3627, %3628) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3631 = "arith.andi"(%3629, %3630) : (i1, i1) -> i1
          %3632 = "scf.if"(%3631) ({
            %3657 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3658 = "cute.static"() : () -> !cute.coord<"(3,0,6)">
            "cute.memref.store"(%3610, %3658, %3657) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
            "scf.yield"(%3610) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3610) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          %3633 = "cute.static"() : () -> !cute.int_tuple<"(8,57)">
          %3634 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3635 = "cute.add_offset"(%3634, %3633) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,57)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3636 = "cute.make_view"(%3635) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3637 = "cute.get_iter"(%3636) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3638 = "cute.deref_arith_tuple_iter"(%3637) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3639:2 = "cute.get_leaves"(%3638) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3640 = "cute.static"() : () -> !cute.int_tuple<"(8,57)">
          %3641 = "cute.get_iter"(%2950) : (!cute.coord_tensor<"(?,?{div=2})", "((2,2),1,8):((1@1,8@0),0,8@1)">) -> !cute.arith_tuple_iter<"(?,?{div=2})">
          %3642 = "cute.add_offset"(%3641, %3640) : (!cute.arith_tuple_iter<"(?,?{div=2})">, !cute.int_tuple<"(8,57)">) -> !cute.arith_tuple_iter<"(?,?)">
          %3643 = "cute.make_view"(%3642) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.coord_tensor<"(?,?)", "():()">
          %3644 = "cute.get_iter"(%3643) : (!cute.coord_tensor<"(?,?)", "():()">) -> !cute.arith_tuple_iter<"(?,?)">
          %3645 = "cute.deref_arith_tuple_iter"(%3644) : (!cute.arith_tuple_iter<"(?,?)">) -> !cute.int_tuple<"(?,?)">
          %3646:2 = "cute.get_leaves"(%3645) : (!cute.int_tuple<"(?,?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
          %3647 = "cute.make_coord"(%3639#0) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3648 = "cute.make_coord"(%3646#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %3649 = "cute.get_scalars"(%3647) : (!cute.coord<"?">) -> i32
          %3650 = "cute.get_scalars"(%3648) : (!cute.coord<"?">) -> i32
          %3651 = "arith.constant"() <{value = true}> : () -> i1
          %3652 = "arith.cmpi"(%3649, %3650) <{predicate = 2 : i64}> : (i32, i32) -> i1
          %3653 = "arith.andi"(%3651, %3652) : (i1, i1) -> i1
          %3654 = "scf.if"(%3653) ({
            %3655 = "arith.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
            %3656 = "cute.static"() : () -> !cute.coord<"(3,0,7)">
            "cute.memref.store"(%3632, %3656, %3655) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
            "scf.yield"(%3632) : (!memref_rmem_f32_1) -> ()
          }, {
            "scf.yield"(%3632) : (!memref_rmem_f32_1) -> ()
          }) : (i1) -> !memref_rmem_f32_1
          "scf.yield"(%3654, %arg18) : (!memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_) -> ()
        }, {
          "scf.yield"(%2218, %arg18) : (!memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_) -> ()
        }) : (i1) -> (!memref_rmem_f32_1, !mma_bf16_bf16_f32_16x8x16_)
        %2257 = "cute.static"() : () -> !cute.layout<"((2,2),1,8):((1,2),0,4)">
        %2258 = "cute.memref.alloca"(%2257) : (!cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !memref_rmem_bf16_6
        %2259 = "cute.get_iter"(%2258) : (!memref_rmem_bf16_6) -> !cute.ptr<bf16, rmem, align<32>>
        %2260 = "cute.memref.load_vec"(%2256#0) : (!memref_rmem_f32_1) -> vector<32xf32>
        %2261 = "arith.truncf"(%2260) : (vector<32xf32>) -> vector<32xbf16>
        "cute.memref.store_vec"(%2261, %2258) : (vector<32xbf16>, !memref_rmem_bf16_6) -> ()
        %2262 = "cute.static"() : () -> !cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">
        %2263 = "cute.make_view"(%2259, %2262) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"(((2,2),2),1,4):(((1,2),4),0,8)">) -> !memref_rmem_bf16_19
        %2264 = "cute.get_layout"(%661) : (!memref_smem_bf16_7) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %2265:2 = "cute.get_scalars"(%2264) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> (i32, i32)
        %2266 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2))">
        %2267 = "cute.assume"(%2265#0) : (i32) -> !cute.i32<divby 16>
        %2268 = "cute.assume"(%2265#1) : (i32) -> !cute.i32<divby 32>
        %2269 = "cute.make_stride"(%2267, %2268) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %2270 = "cute.make_layout"(%2266, %2269) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2))">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2271 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2272 = "cute.get_iter"(%661) : (!memref_smem_bf16_7) -> !cute.ptr<bf16, smem, align<16>>
        %2273 = "cute.add_offset"(%2272, %2271) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
        %2274 = "cute.make_view"(%2273, %2270) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
        %2275 = "cute.get_iter"(%2274) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
        %2276 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2277 = "cute.get_iter"(%663) : (!memref_rmem_bf16_5) -> !cute.ptr<bf16, rmem, align<8>>
        %2278 = "cute.add_offset"(%2277, %2276) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %2279 = "cute.make_view"(%2278) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_20
        %2280 = "cute.get_iter"(%2279) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
        %2281 = "cute.get_layout"(%2274) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2282 = "cute.static"() : () -> !cute.layout<"1:0">
        %2283 = "cute.append_to_rank"(%2281, %2282) <{rank = 2 : si32}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2284 = "cute.make_view"(%2275, %2283) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
        %2285 = "cute.get_iter"(%2284) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
        %2286 = "cute.get_layout"(%2284) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %2287:2 = "cute.get_scalars"(%2286) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> (i32, i32)
        %2288 = "cute.static"() : () -> !cute.shape<"((8,1),(((2,2),2)))">
        %2289 = "cute.assume"(%2287#0) : (i32) -> !cute.i32<divby 16>
        %2290 = "cute.assume"(%2287#1) : (i32) -> !cute.i32<divby 32>
        %2291 = "cute.make_stride"(%2289, %2290) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %2292 = "cute.make_layout"(%2288, %2291) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(((2,2),2)))">, !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2293 = "cute.make_view"(%2285, %2292) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !memref_smem_bf16_19
        %2294 = "cute.static"() : () -> !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
        %2295 = "cute.make_view"(%2280, %2294) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !memref_rmem_bf16_20
        %2296 = "cute.get_iter"(%2295) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
        %2297 = "cute.make_view"(%2296) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_21
        %2298 = "cute.static"() : () -> !cute.layout<"1:0">
        %2299 = "cute.get_iter"(%2293) : (!memref_smem_bf16_19) -> !cute.ptr<bf16, smem, align<16>>
        %2300 = "cute.get_iter"(%2297) : (!memref_rmem_bf16_21) -> !cute.ptr<bf16, rmem, align<8>>
        %2301 = "cute.get_layout"(%2293) : (!memref_smem_bf16_19) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2302 = "cute.append_to_rank"(%2301, %2298) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %2303:2 = "cute.get_scalars"(%2302) <{only_dynamic}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> (i32, i32)
        %2304 = "cute.static"() : () -> !cute.shape<"((8,1),((((2,2),2))))">
        %2305 = "cute.assume"(%2303#0) : (i32) -> !cute.i32<divby 16>
        %2306 = "cute.assume"(%2303#1) : (i32) -> !cute.i32<divby 32>
        %2307 = "cute.make_stride"(%2305, %2306) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %2308 = "cute.make_layout"(%2304, %2307) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((((2,2),2))))">, !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %2309 = "cute.static"() : () -> !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
        %2310 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2311 = "cute.get_scalars"(%2310) : (!cute.int_tuple<"8">) -> i32
        %2312 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2313 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2312, %2311, %2313) ({
        ^bb0(%arg36: i32):
          %2894 = "cute.make_coord"(%arg36) : (i32) -> !cute.coord<"(_,?)">
          %2895 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %2896 = "cute.crd2idx"(%2894, %2308) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %2897 = "cute.add_offset"(%2299, %2896) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %2898 = "cute.make_view"(%2897, %2895) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
          %2899 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %2900 = "cute.crd2idx"(%2894, %2309) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %2901 = "cute.add_offset"(%2300, %2900) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %2902 = "cute.make_view"(%2901, %2899) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_22
          %2903 = "cute.get_iter"(%2898) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
          %2904 = "cute.get_iter"(%2902) : (!memref_rmem_bf16_22) -> !cute.ptr<bf16, rmem, align<8>>
          %2905 = "cute.apply_swizzle"(%2903) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
          %2906 = "cute_nvgpu.arch.copy.ldsm"(%2905) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>, transpose}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
          %2907 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
          %2908 = "vector.extractelement"(%2906, %2907) : (vector<4xi32>, i32) -> i32
          %2909 = "builtin.unrealized_conversion_cast"(%2904) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%2908, %2909) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %2910 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
          %2911 = "vector.extractelement"(%2906, %2910) : (vector<4xi32>, i32) -> i32
          %2912 = "cute.static"() : () -> !cute.int_tuple<"2">
          %2913 = "cute.add_offset"(%2904, %2912) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %2914 = "builtin.unrealized_conversion_cast"(%2913) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%2911, %2914) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %2915 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
          %2916 = "vector.extractelement"(%2906, %2915) : (vector<4xi32>, i32) -> i32
          %2917 = "cute.static"() : () -> !cute.int_tuple<"4">
          %2918 = "cute.add_offset"(%2904, %2917) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %2919 = "builtin.unrealized_conversion_cast"(%2918) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
          "llvm.store"(%2916, %2919) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          %2920 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
          %2921 = "vector.extractelement"(%2906, %2920) : (vector<4xi32>, i32) -> i32
          %2922 = "cute.static"() : () -> !cute.int_tuple<"6">
          %2923 = "cute.add_offset"(%2904, %2922) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %2924 = "builtin.unrealized_conversion_cast"(%2923) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
          "llvm.store"(%2921, %2924) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %2813 = "cute.get_layout"(%661) : (!memref_smem_bf16_7) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
          %2814:2 = "cute.get_scalars"(%2813) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> (i32, i32)
          %2815 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2))">
          %2816 = "cute.assume"(%2814#0) : (i32) -> !cute.i32<divby 16>
          %2817 = "cute.assume"(%2814#1) : (i32) -> !cute.i32<divby 32>
          %2818 = "cute.make_stride"(%2816, %2817) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
          %2819 = "cute.make_layout"(%2815, %2818) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2))">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2820 = "cute.static"() : () -> !cute.int_tuple<"1024">
          %2821 = "cute.get_iter"(%661) : (!memref_smem_bf16_7) -> !cute.ptr<bf16, smem, align<16>>
          %2822 = "cute.add_offset"(%2821, %2820) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %2823 = "cute.make_view"(%2822, %2819) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2824 = "cute.get_iter"(%2823) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2825 = "cute.static"() : () -> !cute.int_tuple<"32">
          %2826 = "cute.get_iter"(%663) : (!memref_rmem_bf16_5) -> !cute.ptr<bf16, rmem, align<8>>
          %2827 = "cute.add_offset"(%2826, %2825) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %2828 = "cute.make_view"(%2827) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_20
          %2829 = "cute.get_iter"(%2828) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2830 = "cute.get_layout"(%2823) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2831 = "cute.static"() : () -> !cute.layout<"1:0">
          %2832 = "cute.append_to_rank"(%2830, %2831) <{rank = 2 : si32}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2833 = "cute.make_view"(%2824, %2832) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2834 = "cute.get_iter"(%2833) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2835 = "cute.get_layout"(%2833) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2836:2 = "cute.get_scalars"(%2835) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> (i32, i32)
          %2837 = "cute.static"() : () -> !cute.shape<"((8,1),(((2,2),2)))">
          %2838 = "cute.assume"(%2836#0) : (i32) -> !cute.i32<divby 16>
          %2839 = "cute.assume"(%2836#1) : (i32) -> !cute.i32<divby 32>
          %2840 = "cute.make_stride"(%2838, %2839) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
          %2841 = "cute.make_layout"(%2837, %2840) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(((2,2),2)))">, !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2842 = "cute.make_view"(%2834, %2841) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !memref_smem_bf16_19
          %2843 = "cute.static"() : () -> !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
          %2844 = "cute.make_view"(%2829, %2843) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !memref_rmem_bf16_20
          %2845 = "cute.get_iter"(%2844) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2846 = "cute.make_view"(%2845) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_21
          %2847 = "cute.static"() : () -> !cute.layout<"1:0">
          %2848 = "cute.get_iter"(%2842) : (!memref_smem_bf16_19) -> !cute.ptr<bf16, smem, align<16>>
          %2849 = "cute.get_iter"(%2846) : (!memref_rmem_bf16_21) -> !cute.ptr<bf16, rmem, align<8>>
          %2850 = "cute.get_layout"(%2842) : (!memref_smem_bf16_19) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2851 = "cute.append_to_rank"(%2850, %2847) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2852:2 = "cute.get_scalars"(%2851) <{only_dynamic}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> (i32, i32)
          %2853 = "cute.static"() : () -> !cute.shape<"((8,1),((((2,2),2))))">
          %2854 = "cute.assume"(%2852#0) : (i32) -> !cute.i32<divby 16>
          %2855 = "cute.assume"(%2852#1) : (i32) -> !cute.i32<divby 32>
          %2856 = "cute.make_stride"(%2854, %2855) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
          %2857 = "cute.make_layout"(%2853, %2856) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((((2,2),2))))">, !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
          %2858 = "cute.static"() : () -> !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
          %2859 = "cute.static"() : () -> !cute.int_tuple<"8">
          %2860 = "cute.get_scalars"(%2859) : (!cute.int_tuple<"8">) -> i32
          %2861 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %2862 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%2861, %2860, %2862) ({
          ^bb0(%arg35: i32):
            %2863 = "cute.make_coord"(%arg35) : (i32) -> !cute.coord<"(_,?)">
            %2864 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2865 = "cute.crd2idx"(%2863, %2857) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
            %2866 = "cute.add_offset"(%2848, %2865) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
            %2867 = "cute.make_view"(%2866, %2864) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %2868 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2869 = "cute.crd2idx"(%2863, %2858) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
            %2870 = "cute.add_offset"(%2849, %2869) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
            %2871 = "cute.make_view"(%2870, %2868) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_22
            %2872 = "cute.get_iter"(%2867) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %2873 = "cute.get_iter"(%2871) : (!memref_rmem_bf16_22) -> !cute.ptr<bf16, rmem, align<8>>
            %2874 = "cute.apply_swizzle"(%2872) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %2875 = "cute_nvgpu.arch.copy.ldsm"(%2874) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>, transpose}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %2876 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %2877 = "vector.extractelement"(%2875, %2876) : (vector<4xi32>, i32) -> i32
            %2878 = "builtin.unrealized_conversion_cast"(%2873) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2877, %2878) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2879 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %2880 = "vector.extractelement"(%2875, %2879) : (vector<4xi32>, i32) -> i32
            %2881 = "cute.static"() : () -> !cute.int_tuple<"2">
            %2882 = "cute.add_offset"(%2873, %2881) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %2883 = "builtin.unrealized_conversion_cast"(%2882) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2880, %2883) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2884 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %2885 = "vector.extractelement"(%2875, %2884) : (vector<4xi32>, i32) -> i32
            %2886 = "cute.static"() : () -> !cute.int_tuple<"4">
            %2887 = "cute.add_offset"(%2873, %2886) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %2888 = "builtin.unrealized_conversion_cast"(%2887) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2885, %2888) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2889 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %2890 = "vector.extractelement"(%2875, %2889) : (vector<4xi32>, i32) -> i32
            %2891 = "cute.static"() : () -> !cute.int_tuple<"6">
            %2892 = "cute.add_offset"(%2873, %2891) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %2893 = "builtin.unrealized_conversion_cast"(%2892) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2890, %2893) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2314 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2315 = "cute.get_iter"(%2263) : (!memref_rmem_bf16_19) -> !cute.ptr<bf16, rmem, align<32>>
        %2316 = "cute.add_offset"(%2315, %2314) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %2317 = "cute.make_view"(%2316) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_23
        %2318 = "cute.static"() : () -> !cute.int_tuple<"0">
        %2319 = "cute.get_iter"(%499) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<8>>
        %2320 = "cute.add_offset"(%2319, %2318) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<8>>
        %2321 = "cute.make_view"(%2320) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_24
        %2322 = "cute.get_iter"(%2317) : (!memref_rmem_bf16_23) -> !cute.ptr<bf16, rmem, align<32>>
        %2323 = "cute.get_iter"(%2321) : (!memref_rmem_bf16_24) -> !cute.ptr<bf16, rmem, align<8>>
        %2324 = "cute.get_iter"(%501) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %2325 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
        %2326 = "cute.static"() : () -> !cute.layout<"1:0">
        %2327 = "cute.static"() : () -> !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2328 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2329 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2330 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2331 = "cute.get_scalars"(%2328) : (!cute.int_tuple<"1">) -> i32
        %2332 = "cute.get_scalars"(%2329) : (!cute.int_tuple<"1">) -> i32
        %2333 = "cute.get_scalars"(%2330) : (!cute.int_tuple<"16">) -> i32
        %2334 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2335 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2334, %2331, %2335) ({
        ^bb0(%arg32: i32):
          "scf.for"(%2334, %2332, %2335) ({
          ^bb0(%arg33: i32):
            "scf.for"(%2334, %2333, %2335) ({
            ^bb0(%arg34: i32):
              %2771 = "cute.make_coord"(%arg34, %arg32) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2772 = "cute.make_coord"(%arg33, %arg34) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2773 = "cute.static"() : () -> !cute.layout<"(((2,2),2)):(((1,2),4))">
              %2774 = "cute.static"() : () -> !cute.int_tuple<"0">
              %2775 = "cute.add_offset"(%2322, %2774) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
              %2776 = "cute.make_view"(%2775, %2773) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"(((2,2),2)):(((1,2),4))">) -> !memref_rmem_bf16_25
              %2777 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2778 = "cute.crd2idx"(%2771, %2327) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %2779 = "cute.add_offset"(%2323, %2778) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %2780 = "cute.make_view"(%2779, %2777) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %2781 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2782 = "cute.crd2idx"(%2772, %2325) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %2783 = "cute.add_offset"(%2324, %2782) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %2784 = "cute.make_view"(%2783, %2781) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %2785 = "cute.get_iter"(%2776) : (!memref_rmem_bf16_25) -> !cute.ptr<bf16, rmem, align<32>>
              %2786 = "cute.get_iter"(%2780) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %2787 = "cute.get_iter"(%2784) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %2788 = "builtin.unrealized_conversion_cast"(%2785) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
              %2789 = "llvm.load"(%2788) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2790 = "llvm.getelementptr"(%2788) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2791 = "llvm.load"(%2790) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2792 = "llvm.getelementptr"(%2788) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2793 = "llvm.load"(%2792) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2794 = "llvm.getelementptr"(%2788) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2795 = "llvm.load"(%2794) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2796 = "builtin.unrealized_conversion_cast"(%2786) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %2797 = "llvm.load"(%2796) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2798 = "llvm.getelementptr"(%2796) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2799 = "llvm.load"(%2798) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2800 = "builtin.unrealized_conversion_cast"(%2787) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %2801 = "llvm.load"(%2800) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2802 = "llvm.getelementptr"(%2800) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2803 = "llvm.load"(%2802) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2804 = "llvm.getelementptr"(%2800) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2805 = "llvm.load"(%2804) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2806 = "llvm.getelementptr"(%2800) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2807 = "llvm.load"(%2806) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2808:4 = "cute_nvgpu.arch.mma.SM80"(%2789, %2791, %2793, %2795, %2797, %2799, %2801, %2803, %2805, %2807) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %2809 = "builtin.unrealized_conversion_cast"(%2787) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%2808#0, %2809) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2810 = "llvm.getelementptr"(%2809) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2808#1, %2810) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2811 = "llvm.getelementptr"(%2809) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2808#2, %2811) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2812 = "llvm.getelementptr"(%2809) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2808#3, %2812) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %2690 = "cute.get_layout"(%661) : (!memref_smem_bf16_7) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
          %2691:2 = "cute.get_scalars"(%2690) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> (i32, i32)
          %2692 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2))">
          %2693 = "cute.assume"(%2691#0) : (i32) -> !cute.i32<divby 16>
          %2694 = "cute.assume"(%2691#1) : (i32) -> !cute.i32<divby 32>
          %2695 = "cute.make_stride"(%2693, %2694) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
          %2696 = "cute.make_layout"(%2692, %2695) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2))">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2697 = "cute.static"() : () -> !cute.int_tuple<"2048">
          %2698 = "cute.get_iter"(%661) : (!memref_smem_bf16_7) -> !cute.ptr<bf16, smem, align<16>>
          %2699 = "cute.add_offset"(%2698, %2697) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %2700 = "cute.make_view"(%2699, %2696) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2701 = "cute.get_iter"(%2700) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2702 = "cute.static"() : () -> !cute.int_tuple<"64">
          %2703 = "cute.get_iter"(%663) : (!memref_rmem_bf16_5) -> !cute.ptr<bf16, rmem, align<8>>
          %2704 = "cute.add_offset"(%2703, %2702) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
          %2705 = "cute.make_view"(%2704) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_20
          %2706 = "cute.get_iter"(%2705) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2707 = "cute.get_layout"(%2700) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2708 = "cute.static"() : () -> !cute.layout<"1:0">
          %2709 = "cute.append_to_rank"(%2707, %2708) <{rank = 2 : si32}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2710 = "cute.make_view"(%2701, %2709) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2711 = "cute.get_iter"(%2710) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2712 = "cute.get_layout"(%2710) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2713:2 = "cute.get_scalars"(%2712) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> (i32, i32)
          %2714 = "cute.static"() : () -> !cute.shape<"((8,1),(((2,2),2)))">
          %2715 = "cute.assume"(%2713#0) : (i32) -> !cute.i32<divby 16>
          %2716 = "cute.assume"(%2713#1) : (i32) -> !cute.i32<divby 32>
          %2717 = "cute.make_stride"(%2715, %2716) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
          %2718 = "cute.make_layout"(%2714, %2717) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(((2,2),2)))">, !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2719 = "cute.make_view"(%2711, %2718) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !memref_smem_bf16_19
          %2720 = "cute.static"() : () -> !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
          %2721 = "cute.make_view"(%2706, %2720) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !memref_rmem_bf16_20
          %2722 = "cute.get_iter"(%2721) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2723 = "cute.make_view"(%2722) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_21
          %2724 = "cute.static"() : () -> !cute.layout<"1:0">
          %2725 = "cute.get_iter"(%2719) : (!memref_smem_bf16_19) -> !cute.ptr<bf16, smem, align<16>>
          %2726 = "cute.get_iter"(%2723) : (!memref_rmem_bf16_21) -> !cute.ptr<bf16, rmem, align<8>>
          %2727 = "cute.get_layout"(%2719) : (!memref_smem_bf16_19) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2728 = "cute.append_to_rank"(%2727, %2724) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2729:2 = "cute.get_scalars"(%2728) <{only_dynamic}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> (i32, i32)
          %2730 = "cute.static"() : () -> !cute.shape<"((8,1),((((2,2),2))))">
          %2731 = "cute.assume"(%2729#0) : (i32) -> !cute.i32<divby 16>
          %2732 = "cute.assume"(%2729#1) : (i32) -> !cute.i32<divby 32>
          %2733 = "cute.make_stride"(%2731, %2732) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
          %2734 = "cute.make_layout"(%2730, %2733) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((((2,2),2))))">, !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
          %2735 = "cute.static"() : () -> !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
          %2736 = "cute.static"() : () -> !cute.int_tuple<"8">
          %2737 = "cute.get_scalars"(%2736) : (!cute.int_tuple<"8">) -> i32
          %2738 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %2739 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%2738, %2737, %2739) ({
          ^bb0(%arg31: i32):
            %2740 = "cute.make_coord"(%arg31) : (i32) -> !cute.coord<"(_,?)">
            %2741 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2742 = "cute.crd2idx"(%2740, %2734) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
            %2743 = "cute.add_offset"(%2725, %2742) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
            %2744 = "cute.make_view"(%2743, %2741) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %2745 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2746 = "cute.crd2idx"(%2740, %2735) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
            %2747 = "cute.add_offset"(%2726, %2746) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
            %2748 = "cute.make_view"(%2747, %2745) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_22
            %2749 = "cute.get_iter"(%2744) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %2750 = "cute.get_iter"(%2748) : (!memref_rmem_bf16_22) -> !cute.ptr<bf16, rmem, align<8>>
            %2751 = "cute.apply_swizzle"(%2749) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %2752 = "cute_nvgpu.arch.copy.ldsm"(%2751) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>, transpose}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %2753 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %2754 = "vector.extractelement"(%2752, %2753) : (vector<4xi32>, i32) -> i32
            %2755 = "builtin.unrealized_conversion_cast"(%2750) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2754, %2755) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2756 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %2757 = "vector.extractelement"(%2752, %2756) : (vector<4xi32>, i32) -> i32
            %2758 = "cute.static"() : () -> !cute.int_tuple<"2">
            %2759 = "cute.add_offset"(%2750, %2758) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %2760 = "builtin.unrealized_conversion_cast"(%2759) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2757, %2760) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2761 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %2762 = "vector.extractelement"(%2752, %2761) : (vector<4xi32>, i32) -> i32
            %2763 = "cute.static"() : () -> !cute.int_tuple<"4">
            %2764 = "cute.add_offset"(%2750, %2763) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %2765 = "builtin.unrealized_conversion_cast"(%2764) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2762, %2765) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2766 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %2767 = "vector.extractelement"(%2752, %2766) : (vector<4xi32>, i32) -> i32
            %2768 = "cute.static"() : () -> !cute.int_tuple<"6">
            %2769 = "cute.add_offset"(%2750, %2768) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %2770 = "builtin.unrealized_conversion_cast"(%2769) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2767, %2770) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2336 = "cute.static"() : () -> !cute.int_tuple<"8">
        %2337 = "cute.get_iter"(%2263) : (!memref_rmem_bf16_19) -> !cute.ptr<bf16, rmem, align<32>>
        %2338 = "cute.add_offset"(%2337, %2336) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %2339 = "cute.make_view"(%2338) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_26
        %2340 = "cute.static"() : () -> !cute.int_tuple<"32">
        %2341 = "cute.get_iter"(%499) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<8>>
        %2342 = "cute.add_offset"(%2341, %2340) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %2343 = "cute.make_view"(%2342) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_24
        %2344 = "cute.get_iter"(%2339) : (!memref_rmem_bf16_26) -> !cute.ptr<bf16, rmem, align<16>>
        %2345 = "cute.get_iter"(%2343) : (!memref_rmem_bf16_24) -> !cute.ptr<bf16, rmem, align<8>>
        %2346 = "cute.get_iter"(%501) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %2347 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
        %2348 = "cute.static"() : () -> !cute.layout<"1:0">
        %2349 = "cute.static"() : () -> !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2350 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2351 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2352 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2353 = "cute.get_scalars"(%2350) : (!cute.int_tuple<"1">) -> i32
        %2354 = "cute.get_scalars"(%2351) : (!cute.int_tuple<"1">) -> i32
        %2355 = "cute.get_scalars"(%2352) : (!cute.int_tuple<"16">) -> i32
        %2356 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2357 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2356, %2353, %2357) ({
        ^bb0(%arg28: i32):
          "scf.for"(%2356, %2354, %2357) ({
          ^bb0(%arg29: i32):
            "scf.for"(%2356, %2355, %2357) ({
            ^bb0(%arg30: i32):
              %2648 = "cute.make_coord"(%arg30, %arg28) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2649 = "cute.make_coord"(%arg29, %arg30) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2650 = "cute.static"() : () -> !cute.layout<"(((2,2),2)):(((1,2),4))">
              %2651 = "cute.static"() : () -> !cute.int_tuple<"0">
              %2652 = "cute.add_offset"(%2344, %2651) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %2653 = "cute.make_view"(%2652, %2650) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(((2,2),2)):(((1,2),4))">) -> !memref_rmem_bf16_27
              %2654 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2655 = "cute.crd2idx"(%2648, %2349) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %2656 = "cute.add_offset"(%2345, %2655) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %2657 = "cute.make_view"(%2656, %2654) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %2658 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2659 = "cute.crd2idx"(%2649, %2347) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %2660 = "cute.add_offset"(%2346, %2659) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %2661 = "cute.make_view"(%2660, %2658) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %2662 = "cute.get_iter"(%2653) : (!memref_rmem_bf16_27) -> !cute.ptr<bf16, rmem, align<16>>
              %2663 = "cute.get_iter"(%2657) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %2664 = "cute.get_iter"(%2661) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %2665 = "builtin.unrealized_conversion_cast"(%2662) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %2666 = "llvm.load"(%2665) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2667 = "llvm.getelementptr"(%2665) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2668 = "llvm.load"(%2667) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2669 = "llvm.getelementptr"(%2665) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2670 = "llvm.load"(%2669) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2671 = "llvm.getelementptr"(%2665) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2672 = "llvm.load"(%2671) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2673 = "builtin.unrealized_conversion_cast"(%2663) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %2674 = "llvm.load"(%2673) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2675 = "llvm.getelementptr"(%2673) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2676 = "llvm.load"(%2675) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2677 = "builtin.unrealized_conversion_cast"(%2664) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %2678 = "llvm.load"(%2677) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2679 = "llvm.getelementptr"(%2677) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2680 = "llvm.load"(%2679) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2681 = "llvm.getelementptr"(%2677) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2682 = "llvm.load"(%2681) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2683 = "llvm.getelementptr"(%2677) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2684 = "llvm.load"(%2683) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2685:4 = "cute_nvgpu.arch.mma.SM80"(%2666, %2668, %2670, %2672, %2674, %2676, %2678, %2680, %2682, %2684) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %2686 = "builtin.unrealized_conversion_cast"(%2664) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%2685#0, %2686) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2687 = "llvm.getelementptr"(%2686) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2685#1, %2687) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2688 = "llvm.getelementptr"(%2686) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2685#2, %2688) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2689 = "llvm.getelementptr"(%2686) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2685#3, %2689) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2036) ({
          %2567 = "cute.get_layout"(%661) : (!memref_smem_bf16_7) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
          %2568:2 = "cute.get_scalars"(%2567) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> (i32, i32)
          %2569 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2))">
          %2570 = "cute.assume"(%2568#0) : (i32) -> !cute.i32<divby 16>
          %2571 = "cute.assume"(%2568#1) : (i32) -> !cute.i32<divby 32>
          %2572 = "cute.make_stride"(%2570, %2571) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
          %2573 = "cute.make_layout"(%2569, %2572) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2))">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2574 = "cute.static"() : () -> !cute.int_tuple<"3072">
          %2575 = "cute.get_iter"(%661) : (!memref_smem_bf16_7) -> !cute.ptr<bf16, smem, align<16>>
          %2576 = "cute.add_offset"(%2575, %2574) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %2577 = "cute.make_view"(%2576, %2573) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2578 = "cute.get_iter"(%2577) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2579 = "cute.static"() : () -> !cute.int_tuple<"96">
          %2580 = "cute.get_iter"(%663) : (!memref_rmem_bf16_5) -> !cute.ptr<bf16, rmem, align<8>>
          %2581 = "cute.add_offset"(%2580, %2579) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
          %2582 = "cute.make_view"(%2581) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_20
          %2583 = "cute.get_iter"(%2582) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2584 = "cute.get_layout"(%2577) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2585 = "cute.static"() : () -> !cute.layout<"1:0">
          %2586 = "cute.append_to_rank"(%2584, %2585) <{rank = 2 : si32}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2587 = "cute.make_view"(%2578, %2586) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2588 = "cute.get_iter"(%2587) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2589 = "cute.get_layout"(%2587) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2590:2 = "cute.get_scalars"(%2589) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> (i32, i32)
          %2591 = "cute.static"() : () -> !cute.shape<"((8,1),(((2,2),2)))">
          %2592 = "cute.assume"(%2590#0) : (i32) -> !cute.i32<divby 16>
          %2593 = "cute.assume"(%2590#1) : (i32) -> !cute.i32<divby 32>
          %2594 = "cute.make_stride"(%2592, %2593) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
          %2595 = "cute.make_layout"(%2591, %2594) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(((2,2),2)))">, !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2596 = "cute.make_view"(%2588, %2595) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !memref_smem_bf16_19
          %2597 = "cute.static"() : () -> !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
          %2598 = "cute.make_view"(%2583, %2597) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !memref_rmem_bf16_20
          %2599 = "cute.get_iter"(%2598) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2600 = "cute.make_view"(%2599) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_21
          %2601 = "cute.static"() : () -> !cute.layout<"1:0">
          %2602 = "cute.get_iter"(%2596) : (!memref_smem_bf16_19) -> !cute.ptr<bf16, smem, align<16>>
          %2603 = "cute.get_iter"(%2600) : (!memref_rmem_bf16_21) -> !cute.ptr<bf16, rmem, align<8>>
          %2604 = "cute.get_layout"(%2596) : (!memref_smem_bf16_19) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2605 = "cute.append_to_rank"(%2604, %2601) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2606:2 = "cute.get_scalars"(%2605) <{only_dynamic}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> (i32, i32)
          %2607 = "cute.static"() : () -> !cute.shape<"((8,1),((((2,2),2))))">
          %2608 = "cute.assume"(%2606#0) : (i32) -> !cute.i32<divby 16>
          %2609 = "cute.assume"(%2606#1) : (i32) -> !cute.i32<divby 32>
          %2610 = "cute.make_stride"(%2608, %2609) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
          %2611 = "cute.make_layout"(%2607, %2610) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((((2,2),2))))">, !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
          %2612 = "cute.static"() : () -> !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
          %2613 = "cute.static"() : () -> !cute.int_tuple<"8">
          %2614 = "cute.get_scalars"(%2613) : (!cute.int_tuple<"8">) -> i32
          %2615 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %2616 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%2615, %2614, %2616) ({
          ^bb0(%arg27: i32):
            %2617 = "cute.make_coord"(%arg27) : (i32) -> !cute.coord<"(_,?)">
            %2618 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2619 = "cute.crd2idx"(%2617, %2611) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
            %2620 = "cute.add_offset"(%2602, %2619) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
            %2621 = "cute.make_view"(%2620, %2618) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %2622 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2623 = "cute.crd2idx"(%2617, %2612) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
            %2624 = "cute.add_offset"(%2603, %2623) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
            %2625 = "cute.make_view"(%2624, %2622) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_22
            %2626 = "cute.get_iter"(%2621) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %2627 = "cute.get_iter"(%2625) : (!memref_rmem_bf16_22) -> !cute.ptr<bf16, rmem, align<8>>
            %2628 = "cute.apply_swizzle"(%2626) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %2629 = "cute_nvgpu.arch.copy.ldsm"(%2628) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>, transpose}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %2630 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %2631 = "vector.extractelement"(%2629, %2630) : (vector<4xi32>, i32) -> i32
            %2632 = "builtin.unrealized_conversion_cast"(%2627) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2631, %2632) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2633 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %2634 = "vector.extractelement"(%2629, %2633) : (vector<4xi32>, i32) -> i32
            %2635 = "cute.static"() : () -> !cute.int_tuple<"2">
            %2636 = "cute.add_offset"(%2627, %2635) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %2637 = "builtin.unrealized_conversion_cast"(%2636) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2634, %2637) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2638 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %2639 = "vector.extractelement"(%2629, %2638) : (vector<4xi32>, i32) -> i32
            %2640 = "cute.static"() : () -> !cute.int_tuple<"4">
            %2641 = "cute.add_offset"(%2627, %2640) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %2642 = "builtin.unrealized_conversion_cast"(%2641) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2639, %2642) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2643 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %2644 = "vector.extractelement"(%2629, %2643) : (vector<4xi32>, i32) -> i32
            %2645 = "cute.static"() : () -> !cute.int_tuple<"6">
            %2646 = "cute.add_offset"(%2627, %2645) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %2647 = "builtin.unrealized_conversion_cast"(%2646) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2644, %2647) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2358 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2359 = "cute.get_iter"(%2263) : (!memref_rmem_bf16_19) -> !cute.ptr<bf16, rmem, align<32>>
        %2360 = "cute.add_offset"(%2359, %2358) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %2361 = "cute.make_view"(%2360) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_23
        %2362 = "cute.static"() : () -> !cute.int_tuple<"64">
        %2363 = "cute.get_iter"(%499) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<8>>
        %2364 = "cute.add_offset"(%2363, %2362) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %2365 = "cute.make_view"(%2364) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_24
        %2366 = "cute.get_iter"(%2361) : (!memref_rmem_bf16_23) -> !cute.ptr<bf16, rmem, align<32>>
        %2367 = "cute.get_iter"(%2365) : (!memref_rmem_bf16_24) -> !cute.ptr<bf16, rmem, align<8>>
        %2368 = "cute.get_iter"(%501) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %2369 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
        %2370 = "cute.static"() : () -> !cute.layout<"1:0">
        %2371 = "cute.static"() : () -> !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2372 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2373 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2374 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2375 = "cute.get_scalars"(%2372) : (!cute.int_tuple<"1">) -> i32
        %2376 = "cute.get_scalars"(%2373) : (!cute.int_tuple<"1">) -> i32
        %2377 = "cute.get_scalars"(%2374) : (!cute.int_tuple<"16">) -> i32
        %2378 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2379 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2378, %2375, %2379) ({
        ^bb0(%arg24: i32):
          "scf.for"(%2378, %2376, %2379) ({
          ^bb0(%arg25: i32):
            "scf.for"(%2378, %2377, %2379) ({
            ^bb0(%arg26: i32):
              %2525 = "cute.make_coord"(%arg26, %arg24) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2526 = "cute.make_coord"(%arg25, %arg26) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2527 = "cute.static"() : () -> !cute.layout<"(((2,2),2)):(((1,2),4))">
              %2528 = "cute.static"() : () -> !cute.int_tuple<"0">
              %2529 = "cute.add_offset"(%2366, %2528) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
              %2530 = "cute.make_view"(%2529, %2527) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"(((2,2),2)):(((1,2),4))">) -> !memref_rmem_bf16_25
              %2531 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2532 = "cute.crd2idx"(%2525, %2371) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %2533 = "cute.add_offset"(%2367, %2532) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %2534 = "cute.make_view"(%2533, %2531) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %2535 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2536 = "cute.crd2idx"(%2526, %2369) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %2537 = "cute.add_offset"(%2368, %2536) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %2538 = "cute.make_view"(%2537, %2535) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %2539 = "cute.get_iter"(%2530) : (!memref_rmem_bf16_25) -> !cute.ptr<bf16, rmem, align<32>>
              %2540 = "cute.get_iter"(%2534) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %2541 = "cute.get_iter"(%2538) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %2542 = "builtin.unrealized_conversion_cast"(%2539) : (!cute.ptr<bf16, rmem, align<32>>) -> !llvm.ptr
              %2543 = "llvm.load"(%2542) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2544 = "llvm.getelementptr"(%2542) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2545 = "llvm.load"(%2544) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2546 = "llvm.getelementptr"(%2542) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2547 = "llvm.load"(%2546) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2548 = "llvm.getelementptr"(%2542) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2549 = "llvm.load"(%2548) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2550 = "builtin.unrealized_conversion_cast"(%2540) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %2551 = "llvm.load"(%2550) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2552 = "llvm.getelementptr"(%2550) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2553 = "llvm.load"(%2552) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2554 = "builtin.unrealized_conversion_cast"(%2541) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %2555 = "llvm.load"(%2554) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2556 = "llvm.getelementptr"(%2554) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2557 = "llvm.load"(%2556) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2558 = "llvm.getelementptr"(%2554) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2559 = "llvm.load"(%2558) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2560 = "llvm.getelementptr"(%2554) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2561 = "llvm.load"(%2560) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2562:4 = "cute_nvgpu.arch.mma.SM80"(%2543, %2545, %2547, %2549, %2551, %2553, %2555, %2557, %2559, %2561) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %2563 = "builtin.unrealized_conversion_cast"(%2541) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%2562#0, %2563) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2564 = "llvm.getelementptr"(%2563) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2562#1, %2564) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2565 = "llvm.getelementptr"(%2563) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2562#2, %2565) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2566 = "llvm.getelementptr"(%2563) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2562#3, %2566) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.if"(%2191) ({
          %2444 = "cute.get_layout"(%661) : (!memref_smem_bf16_7) -> !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
          %2445:2 = "cute.get_scalars"(%2444) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">) -> (i32, i32)
          %2446 = "cute.static"() : () -> !cute.shape<"((8,1),((2,2),2))">
          %2447 = "cute.assume"(%2445#0) : (i32) -> !cute.i32<divby 16>
          %2448 = "cute.assume"(%2445#1) : (i32) -> !cute.i32<divby 32>
          %2449 = "cute.make_stride"(%2447, %2448) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
          %2450 = "cute.make_layout"(%2446, %2449) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((2,2),2))">, !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2451 = "cute.static"() : () -> !cute.int_tuple<"4096">
          %2452 = "cute.get_iter"(%661) : (!memref_smem_bf16_7) -> !cute.ptr<bf16, smem, align<16>>
          %2453 = "cute.add_offset"(%2452, %2451) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
          %2454 = "cute.make_view"(%2453, %2450) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2455 = "cute.get_iter"(%2454) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2456 = "cute.static"() : () -> !cute.int_tuple<"128">
          %2457 = "cute.get_iter"(%663) : (!memref_rmem_bf16_5) -> !cute.ptr<bf16, rmem, align<8>>
          %2458 = "cute.add_offset"(%2457, %2456) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
          %2459 = "cute.make_view"(%2458) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_20
          %2460 = "cute.get_iter"(%2459) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2461 = "cute.get_layout"(%2454) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2462 = "cute.static"() : () -> !cute.layout<"1:0">
          %2463 = "cute.append_to_rank"(%2461, %2462) <{rank = 2 : si32}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2464 = "cute.make_view"(%2455, %2463) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> !memref_smem_bf16_18
          %2465 = "cute.get_iter"(%2464) : (!memref_smem_bf16_18) -> !cute.ptr<bf16, smem, align<16>>
          %2466 = "cute.get_layout"(%2464) : (!memref_smem_bf16_18) -> !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
          %2467:2 = "cute.get_scalars"(%2466) <{only_dynamic}> : (!cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">) -> (i32, i32)
          %2468 = "cute.static"() : () -> !cute.shape<"((8,1),(((2,2),2)))">
          %2469 = "cute.assume"(%2467#0) : (i32) -> !cute.i32<divby 16>
          %2470 = "cute.assume"(%2467#1) : (i32) -> !cute.i32<divby 32>
          %2471 = "cute.make_stride"(%2469, %2470) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
          %2472 = "cute.make_layout"(%2468, %2471) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),(((2,2),2)))">, !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2473 = "cute.make_view"(%2465, %2472) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> !memref_smem_bf16_19
          %2474 = "cute.static"() : () -> !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">
          %2475 = "cute.make_view"(%2460, %2474) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1),(4,2)):((1,0),(8,128))">) -> !memref_rmem_bf16_20
          %2476 = "cute.get_iter"(%2475) : (!memref_rmem_bf16_20) -> !cute.ptr<bf16, rmem, align<8>>
          %2477 = "cute.make_view"(%2476) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_21
          %2478 = "cute.static"() : () -> !cute.layout<"1:0">
          %2479 = "cute.get_iter"(%2473) : (!memref_smem_bf16_19) -> !cute.ptr<bf16, smem, align<16>>
          %2480 = "cute.get_iter"(%2477) : (!memref_rmem_bf16_21) -> !cute.ptr<bf16, rmem, align<8>>
          %2481 = "cute.get_layout"(%2473) : (!memref_smem_bf16_19) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2482 = "cute.append_to_rank"(%2481, %2478) <{rank = 2 : si32}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">) -> !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
          %2483:2 = "cute.get_scalars"(%2482) <{only_dynamic}> : (!cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">) -> (i32, i32)
          %2484 = "cute.static"() : () -> !cute.shape<"((8,1),((((2,2),2))))">
          %2485 = "cute.assume"(%2483#0) : (i32) -> !cute.i32<divby 16>
          %2486 = "cute.assume"(%2483#1) : (i32) -> !cute.i32<divby 32>
          %2487 = "cute.make_stride"(%2485, %2486) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
          %2488 = "cute.make_layout"(%2484, %2487) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),((((2,2),2))))">, !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
          %2489 = "cute.static"() : () -> !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
          %2490 = "cute.static"() : () -> !cute.int_tuple<"8">
          %2491 = "cute.get_scalars"(%2490) : (!cute.int_tuple<"8">) -> i32
          %2492 = "arith.constant"() <{value = 0 : i32}> : () -> i32
          %2493 = "arith.constant"() <{value = 1 : i32}> : () -> i32
          "scf.for"(%2492, %2491, %2493) ({
          ^bb0(%arg23: i32):
            %2494 = "cute.make_coord"(%arg23) : (i32) -> !cute.coord<"(_,?)">
            %2495 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2496 = "cute.crd2idx"(%2494, %2488) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
            %2497 = "cute.add_offset"(%2479, %2496) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
            %2498 = "cute.make_view"(%2497, %2495) : (!cute.ptr<bf16, smem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_11
            %2499 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
            %2500 = "cute.crd2idx"(%2494, %2489) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
            %2501 = "cute.add_offset"(%2480, %2500) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
            %2502 = "cute.make_view"(%2501, %2499) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_22
            %2503 = "cute.get_iter"(%2498) : (!memref_smem_bf16_11) -> !cute.ptr<bf16, smem, align<16>>
            %2504 = "cute.get_iter"(%2502) : (!memref_rmem_bf16_22) -> !cute.ptr<bf16, rmem, align<8>>
            %2505 = "cute.apply_swizzle"(%2503) : (!cute.ptr<bf16, smem, align<16>>) -> !cute.ptr<bf16, smem, align<16>>
            %2506 = "cute_nvgpu.arch.copy.ldsm"(%2505) <{matrix_shape = #cute.shape<"(8,8)">, num_matrices = 4 : i32, sz_pattern = #cute_nvgpu.ldsm_sz_pattern<u16>, transpose}> : (!cute.ptr<bf16, smem, align<16>>) -> vector<4xi32>
            %2507 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
            %2508 = "vector.extractelement"(%2506, %2507) : (vector<4xi32>, i32) -> i32
            %2509 = "builtin.unrealized_conversion_cast"(%2504) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2508, %2509) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2510 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
            %2511 = "vector.extractelement"(%2506, %2510) : (vector<4xi32>, i32) -> i32
            %2512 = "cute.static"() : () -> !cute.int_tuple<"2">
            %2513 = "cute.add_offset"(%2504, %2512) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
            %2514 = "builtin.unrealized_conversion_cast"(%2513) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2511, %2514) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2515 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
            %2516 = "vector.extractelement"(%2506, %2515) : (vector<4xi32>, i32) -> i32
            %2517 = "cute.static"() : () -> !cute.int_tuple<"4">
            %2518 = "cute.add_offset"(%2504, %2517) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
            %2519 = "builtin.unrealized_conversion_cast"(%2518) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
            "llvm.store"(%2516, %2519) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            %2520 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
            %2521 = "vector.extractelement"(%2506, %2520) : (vector<4xi32>, i32) -> i32
            %2522 = "cute.static"() : () -> !cute.int_tuple<"6">
            %2523 = "cute.add_offset"(%2504, %2522) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
            %2524 = "builtin.unrealized_conversion_cast"(%2523) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
            "llvm.store"(%2521, %2524) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }, {
        }) : (i1) -> ()
        %2380 = "cute.static"() : () -> !cute.int_tuple<"24">
        %2381 = "cute.get_iter"(%2263) : (!memref_rmem_bf16_19) -> !cute.ptr<bf16, rmem, align<32>>
        %2382 = "cute.add_offset"(%2381, %2380) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %2383 = "cute.make_view"(%2382) : (!cute.ptr<bf16, rmem, align<16>>) -> !memref_rmem_bf16_26
        %2384 = "cute.static"() : () -> !cute.int_tuple<"96">
        %2385 = "cute.get_iter"(%499) : (!memref_rmem_bf16_2) -> !cute.ptr<bf16, rmem, align<8>>
        %2386 = "cute.add_offset"(%2385, %2384) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %2387 = "cute.make_view"(%2386) : (!cute.ptr<bf16, rmem, align<8>>) -> !memref_rmem_bf16_24
        %2388 = "cute.get_iter"(%2383) : (!memref_rmem_bf16_26) -> !cute.ptr<bf16, rmem, align<16>>
        %2389 = "cute.get_iter"(%2387) : (!memref_rmem_bf16_24) -> !cute.ptr<bf16, rmem, align<8>>
        %2390 = "cute.get_iter"(%501) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %2391 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
        %2392 = "cute.static"() : () -> !cute.layout<"1:0">
        %2393 = "cute.static"() : () -> !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
        %2394 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2395 = "cute.static"() : () -> !cute.int_tuple<"1">
        %2396 = "cute.static"() : () -> !cute.int_tuple<"16">
        %2397 = "cute.get_scalars"(%2394) : (!cute.int_tuple<"1">) -> i32
        %2398 = "cute.get_scalars"(%2395) : (!cute.int_tuple<"1">) -> i32
        %2399 = "cute.get_scalars"(%2396) : (!cute.int_tuple<"16">) -> i32
        %2400 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %2401 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%2400, %2397, %2401) ({
        ^bb0(%arg20: i32):
          "scf.for"(%2400, %2398, %2401) ({
          ^bb0(%arg21: i32):
            "scf.for"(%2400, %2399, %2401) ({
            ^bb0(%arg22: i32):
              %2402 = "cute.make_coord"(%arg22, %arg20) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2403 = "cute.make_coord"(%arg21, %arg22) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %2404 = "cute.static"() : () -> !cute.layout<"(((2,2),2)):(((1,2),4))">
              %2405 = "cute.static"() : () -> !cute.int_tuple<"0">
              %2406 = "cute.add_offset"(%2388, %2405) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<16>>
              %2407 = "cute.make_view"(%2406, %2404) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"(((2,2),2)):(((1,2),4))">) -> !memref_rmem_bf16_27
              %2408 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2409 = "cute.crd2idx"(%2402, %2393) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %2410 = "cute.add_offset"(%2389, %2409) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %2411 = "cute.make_view"(%2410, %2408) : (!cute.ptr<bf16, rmem, align<8>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_bf16_18
              %2412 = "cute.static"() : () -> !cute.layout<"((2,2)):((1,2))">
              %2413 = "cute.crd2idx"(%2403, %2391) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %2414 = "cute.add_offset"(%2390, %2413) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %2415 = "cute.make_view"(%2414, %2412) : (!cute.ptr<f32, rmem, align<16>>, !cute.layout<"((2,2)):((1,2))">) -> !memref_rmem_f32_2
              %2416 = "cute.get_iter"(%2407) : (!memref_rmem_bf16_27) -> !cute.ptr<bf16, rmem, align<16>>
              %2417 = "cute.get_iter"(%2411) : (!memref_rmem_bf16_18) -> !cute.ptr<bf16, rmem, align<8>>
              %2418 = "cute.get_iter"(%2415) : (!memref_rmem_f32_2) -> !cute.ptr<f32, rmem, align<16>>
              %2419 = "builtin.unrealized_conversion_cast"(%2416) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
              %2420 = "llvm.load"(%2419) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2421 = "llvm.getelementptr"(%2419) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2422 = "llvm.load"(%2421) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2423 = "llvm.getelementptr"(%2419) <{elem_type = i32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2424 = "llvm.load"(%2423) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2425 = "llvm.getelementptr"(%2419) <{elem_type = i32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2426 = "llvm.load"(%2425) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2427 = "builtin.unrealized_conversion_cast"(%2417) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
              %2428 = "llvm.load"(%2427) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2429 = "llvm.getelementptr"(%2427) <{elem_type = i32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2430 = "llvm.load"(%2429) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
              %2431 = "builtin.unrealized_conversion_cast"(%2418) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              %2432 = "llvm.load"(%2431) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2433 = "llvm.getelementptr"(%2431) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              %2434 = "llvm.load"(%2433) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2435 = "llvm.getelementptr"(%2431) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              %2436 = "llvm.load"(%2435) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2437 = "llvm.getelementptr"(%2431) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              %2438 = "llvm.load"(%2437) <{ordering = 0 : i64}> : (!llvm.ptr) -> f32
              %2439:4 = "cute_nvgpu.arch.mma.SM80"(%2420, %2422, %2424, %2426, %2428, %2430, %2432, %2434, %2436, %2438) <{a_type = bf16, b_type = bf16, operandSegmentSizes = array<i32: 4, 2, 4>, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, i32, i32, i32, i32, f32, f32, f32, f32) -> (f32, f32, f32, f32)
              %2440 = "builtin.unrealized_conversion_cast"(%2418) : (!cute.ptr<f32, rmem, align<16>>) -> !llvm.ptr
              "llvm.store"(%2439#0, %2440) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2441 = "llvm.getelementptr"(%2440) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2439#1, %2441) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2442 = "llvm.getelementptr"(%2440) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2439#2, %2442) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              %2443 = "llvm.getelementptr"(%2440) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
              "llvm.store"(%2439#3, %2443) <{ordering = 0 : i64}> : (f32, !llvm.ptr) -> ()
              "scf.yield"() : () -> ()
            }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
            "scf.yield"() : () -> ()
          }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"(%2256#1, %arg19) : (!mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3) -> ()
      }) : (i32, i32, i32, !mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3) -> (!mma_bf16_bf16_f32_16x8x16_, !copy_ldsm_4_3)
      %1293 = "cute.static"() : () -> !cute.layout<"((2,2),1,16):((1,2),0,4)">
      %1294 = "cute.memref.alloca"(%1293) : (!cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !memref_rmem_bf16_28
      %1295 = "cute.memref.load_vec"(%501) : (!memref_rmem_f32_) -> vector<64xf32>
      %1296 = "arith.truncf"(%1295) : (vector<64xf32>) -> vector<64xbf16>
      "cute.memref.store_vec"(%1296, %1294) : (vector<64xbf16>, !memref_rmem_bf16_28) -> ()
      %1297 = "cute.recast_iter"(%257) : (!cute.ptr<bf16, smem, align<1024>>) -> !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %1298 = "cute.static"() : () -> !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">
      %1299 = "cute.make_view"(%1297, %1298) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.layout<"((8,8),(64,2)):((64,512),(1,4096))">) -> !memref_smem_bf16_20
      %1300 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %1301 = "cute.static"() : () -> !cute.layout<"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">
      %1302 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %1303 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
      %1304 = "cute.make_tiled_copy"(%1300) : (!cute_nvgpu.atom.universal_copy<bf16>) -> !copy_simt1
      %1305 = "cute.get_iter"(%1294) : (!memref_rmem_bf16_28) -> !cute.ptr<bf16, rmem, align<32>>
      %1306 = "cute.make_view"(%1305) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_29
      %1307 = "cute.get_iter"(%1306) : (!memref_rmem_bf16_29) -> !cute.ptr<bf16, rmem, align<32>>
      %1308 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %1309 = "cute.get_iter"(%1299) : (!memref_smem_bf16_20) -> !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %1310 = "cute.get_scalars"(%1308) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %1311 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %1312 = "arith.divsi"(%1310, %1311) : (i32, i32) -> i32
      %1313 = "arith.constant"() <{value = 4 : i32}> : () -> i32
      %1314 = "arith.remsi"(%1310, %1313) : (i32, i32) -> i32
      %1315 = "arith.constant"() <{value = 2 : i32}> : () -> i32
      %1316 = "arith.muli"(%1314, %1315) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1317 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1318 = "arith.divsi"(%1312, %1317) : (i32, i32) -> i32
      %1319 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1320 = "arith.remsi"(%1312, %1319) : (i32, i32) -> i32
      %1321 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %1322 = "arith.muli"(%1320, %1321) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1323 = "arith.addi"(%1316, %1322) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1324 = "arith.constant"() <{value = 1024 : i32}> : () -> i32
      %1325 = "arith.muli"(%1318, %1324) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1326 = "arith.addi"(%1323, %1325) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1327 = "cute.assume"(%1326) : (i32) -> !cute.i32<divby 2>
      %1328 = "cute.make_int_tuple"(%1327) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %1329 = "cute.add_offset"(%1309, %1328) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1330 = "cute.make_view"(%1329) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !memref_smem_bf16_21
      %1331 = "cute.get_iter"(%1330) : (!memref_smem_bf16_21) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1332 = "cute.static"() : () -> !cute.layout<"((1,8),1,8):((0,1),0,8)">
      %1333 = "cute.make_view"(%1307, %1332) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((1,8),1,8):((0,1),0,8)">) -> !memref_rmem_bf16_29
      %1334 = "cute.get_iter"(%1333) : (!memref_rmem_bf16_29) -> !cute.ptr<bf16, rmem, align<32>>
      %1335 = "cute.make_view"(%1334) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_30
      %1336 = "cute.static"() : () -> !cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">
      %1337 = "cute.make_view"(%1331, %1336) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.layout<"((1,(2,2,2)),1,(4,2)):((0,(1,512,8)),0,(16,4096))">) -> !memref_smem_bf16_21
      %1338 = "cute.get_iter"(%1337) : (!memref_smem_bf16_21) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1339 = "cute.make_view"(%1338) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !memref_smem_bf16_22
      %1340 = "cute.static"() : () -> !cute.layout<"1:0">
      %1341 = "cute.get_iter"(%1335) : (!memref_rmem_bf16_30) -> !cute.ptr<bf16, rmem, align<32>>
      %1342 = "cute.get_iter"(%1339) : (!memref_smem_bf16_22) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1343 = "cute.static"() : () -> !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">
      %1344 = "cute.static"() : () -> !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">
      %1345 = "cute.static"() : () -> !cute.int_tuple<"8">
      %1346 = "cute.get_scalars"(%1345) : (!cute.int_tuple<"8">) -> i32
      %1347 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1348 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%1347, %1346, %1348) ({
      ^bb0(%arg16: i32):
        %1881 = "cute.make_coord"(%arg16) : (i32) -> !cute.coord<"(_,?)">
        %1882 = "cute.static"() : () -> !cute.layout<"((1,8)):((0,1))">
        %1883 = "cute.crd2idx"(%1881, %1343) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %1884 = "cute.add_offset"(%1341, %1883) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1885 = "cute.make_view"(%1884, %1882) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((1,8)):((0,1))">) -> !memref_rmem_bf16_31
        %1886 = "cute.static"() : () -> !cute.layout<"((1,(2,2,2))):((0,(1,512,8)))">
        %1887 = "cute.crd2idx"(%1881, %1344) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
        %1888 = "cute.add_offset"(%1342, %1887) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1889 = "cute.make_view"(%1888, %1886) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.layout<"((1,(2,2,2))):((0,(1,512,8)))">) -> !memref_smem_bf16_23
        %1890 = "cute.get_iter"(%1885) : (!memref_rmem_bf16_31) -> !cute.ptr<bf16, rmem, align<16>>
        %1891 = "cute.get_iter"(%1889) : (!memref_smem_bf16_23) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1892 = "cute.apply_swizzle"(%1891) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1893 = "builtin.unrealized_conversion_cast"(%1890) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %1894 = "builtin.unrealized_conversion_cast"(%1892) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !llvm.ptr<3>
        %1895 = "llvm.load"(%1893) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<2xbf16>
        "llvm.store"(%1895, %1894) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<2xbf16>, !llvm.ptr<3>) -> ()
        %1896 = "cute.static"() : () -> !cute.int_tuple<"2">
        %1897 = "cute.add_offset"(%1890, %1896) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %1898 = "cute.static"() : () -> !cute.int_tuple<"512">
        %1899 = "cute.add_offset"(%1891, %1898) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1900 = "cute.apply_swizzle"(%1899) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1901 = "builtin.unrealized_conversion_cast"(%1897) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
        %1902 = "builtin.unrealized_conversion_cast"(%1900) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !llvm.ptr<3>
        %1903 = "llvm.load"(%1901) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<2xbf16>
        "llvm.store"(%1903, %1902) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<2xbf16>, !llvm.ptr<3>) -> ()
        %1904 = "cute.static"() : () -> !cute.int_tuple<"4">
        %1905 = "cute.add_offset"(%1890, %1904) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %1906 = "cute.static"() : () -> !cute.int_tuple<"8">
        %1907 = "cute.add_offset"(%1891, %1906) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1908 = "cute.apply_swizzle"(%1907) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1909 = "builtin.unrealized_conversion_cast"(%1905) : (!cute.ptr<bf16, rmem, align<8>>) -> !llvm.ptr
        %1910 = "builtin.unrealized_conversion_cast"(%1908) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !llvm.ptr<3>
        %1911 = "llvm.load"(%1909) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<2xbf16>
        "llvm.store"(%1911, %1910) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<2xbf16>, !llvm.ptr<3>) -> ()
        %1912 = "cute.static"() : () -> !cute.int_tuple<"6">
        %1913 = "cute.add_offset"(%1890, %1912) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %1914 = "cute.static"() : () -> !cute.int_tuple<"520">
        %1915 = "cute.add_offset"(%1891, %1914) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1916 = "cute.apply_swizzle"(%1915) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %1917 = "builtin.unrealized_conversion_cast"(%1913) : (!cute.ptr<bf16, rmem, align<4>>) -> !llvm.ptr
        %1918 = "builtin.unrealized_conversion_cast"(%1916) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>) -> !llvm.ptr<3>
        %1919 = "llvm.load"(%1917) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<2xbf16>
        "llvm.store"(%1919, %1918) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<2xbf16>, !llvm.ptr<3>) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %1349 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %1350 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1351:7 = "cute.get_scalars"(%1350) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> (i32, i32, i32, i32, i64, i64, i64)
      %1352 = "cute.assume"(%1351#3) : (i32) -> !cute.i32<divby 8>
      %1353 = "cute.make_shape"(%1351#1, %1352) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %1354 = "cute.assume"(%1351#5) : (i64) -> !cute.i64<divby 8>
      %1355 = "cute.make_stride"(%1354) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %1356 = "cute.make_layout"(%1353, %1355) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %1357 = "cute.crd2idx"(%1349, %1350) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %1358 = "cute.get_iter"(%arg9) : (!memref_gmem_bf16_) -> !cute.ptr<bf16, gmem, align<16>>
      %1359 = "cute.add_offset"(%1358, %1357) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1360 = "cute.make_view"(%1359, %1356) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> !memref_gmem_bf16_1
      %1361 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %1362 = "cute.get_scalars"(%1361) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %1363 = "cute.make_coord"(%1362) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %1364 = "cute.get_layout"(%1360) : (!memref_gmem_bf16_1) -> !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %1365:3 = "cute.get_scalars"(%1364) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">) -> (i32, i32, i64)
      %1366 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %1367 = "arith.ceildivsi"(%1365#0, %1366) : (i32, i32) -> i32
      %1368 = "arith.constant"() <{value = 64 : i64}> : () -> i64
      %1369 = "arith.muli"(%1365#2, %1368) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %1370 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %1371 = "arith.ceildivsi"(%1365#1, %1370) : (i32, i32) -> i32
      %1372 = "cute.make_shape"(%1367, %1371) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %1373 = "cute.assume"(%1365#2) : (i64) -> !cute.i64<divby 8>
      %1374 = "cute.assume"(%1369) : (i64) -> !cute.i64<divby 512>
      %1375 = "cute.make_stride"(%1373, %1374) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %1376 = "cute.make_layout"(%1372, %1375) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %1377:4 = "cute.get_scalars"(%1376) <{only_dynamic}> : (!cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> (i32, i32, i64, i64)
      %1378 = "cute.static"() : () -> !cute.shape<"(64,128)">
      %1379 = "cute.assume"(%1377#2) : (i64) -> !cute.i64<divby 8>
      %1380 = "cute.make_stride"(%1379) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %1381 = "cute.make_layout"(%1378, %1380) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(64,128)">, !cute.stride<"(?{i64 div=8},1)">) -> !cute.layout<"(64,128):(?{i64 div=8},1)">
      %1382 = "cute.crd2idx"(%1363, %1376) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %1383 = "cute.get_iter"(%1360) : (!memref_gmem_bf16_1) -> !cute.ptr<bf16, gmem, align<16>>
      %1384 = "cute.add_offset"(%1383, %1382) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1385 = "cute.make_view"(%1384, %1381) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"(64,128):(?{i64 div=8},1)">) -> !memref_gmem_bf16_2
      %1386 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %1387 = "cute.get_iter"(%1299) : (!memref_smem_bf16_20) -> !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %1388 = "cute.get_scalars"(%1386) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %1389 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1390 = "arith.divsi"(%1388, %1389) : (i32, i32) -> i32
      %1391 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1392 = "arith.remsi"(%1388, %1391) : (i32, i32) -> i32
      %1393 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1394 = "arith.muli"(%1392, %1393) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1395 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %1396 = "arith.muli"(%1390, %1395) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1397 = "arith.addi"(%1394, %1396) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1398 = "cute.assume"(%1397) : (i32) -> !cute.i32<divby 8>
      %1399 = "cute.make_int_tuple"(%1398) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %1400 = "cute.add_offset"(%1387, %1399) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1401 = "cute.make_view"(%1400) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>) -> !memref_smem_bf16_24
      %1402 = "cute.get_iter"(%1401) : (!memref_smem_bf16_24) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1403 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %1404 = "cute.get_iter"(%1385) : (!memref_gmem_bf16_2) -> !cute.ptr<bf16, gmem, align<16>>
      %1405 = "cute.get_layout"(%1385) : (!memref_gmem_bf16_2) -> !cute.layout<"(64,128):(?{i64 div=8},1)">
      %1406 = "cute.get_scalars"(%1405) <{only_dynamic}> : (!cute.layout<"(64,128):(?{i64 div=8},1)">) -> i64
      %1407 = "cute.get_scalars"(%1403) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %1408 = "arith.constant"() <{value = 16 : i64}> : () -> i64
      %1409 = "arith.muli"(%1406, %1408) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %1410 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1411 = "arith.divsi"(%1407, %1410) : (i32, i32) -> i32
      %1412 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1413 = "arith.remsi"(%1407, %1412) : (i32, i32) -> i32
      %1414 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1415 = "arith.muli"(%1413, %1414) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1416 = "arith.extsi"(%1411) : (i32) -> i64
      %1417 = "arith.muli"(%1416, %1406) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %1418 = "arith.extsi"(%1415) : (i32) -> i64
      %1419 = "arith.addi"(%1418, %1417) <{overflowFlags = #arith.overflow<none>}> : (i64, i64) -> i64
      %1420 = "cute.assume"(%1419) : (i64) -> !cute.i64<divby 8>
      %1421 = "cute.make_int_tuple"(%1420) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %1422 = "cute.add_offset"(%1404, %1421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1423 = "cute.static"() : () -> !cute.shape<"((8,1),4,2)">
      %1424 = "cute.assume"(%1409) : (i64) -> !cute.i64<divby 128>
      %1425 = "cute.make_stride"(%1424) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %1426 = "cute.make_layout"(%1423, %1425) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((8,1),4,2)">, !cute.stride<"((1,0),?{i64 div=128},64)">) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %1427 = "cute.make_view"(%1422, %1426) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !memref_gmem_bf16_5
      %1428 = "cute.static"() : () -> !cute.layout<"((8,1),4,2):((1,0),16,8)">
      %1429 = "cute.memref.alloca"(%1428) : (!cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !memref_rmem_bf16_32
      %1430 = "cute.get_iter"(%1429) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
      %1431 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      %1432 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      "llvm.inline_asm"(%1431, %1432) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
      %1433 = "cute.static"() : () -> !cute.layout<"((8,1),4,2):((1,0),1024,4096)">
      %1434 = "cute.make_view"(%1402, %1433) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.layout<"((8,1),4,2):((1,0),1024,4096)">) -> !memref_smem_bf16_24
      %1435 = "cute.get_iter"(%1434) : (!memref_smem_bf16_24) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1436 = "cute.make_view"(%1435) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>) -> !memref_smem_bf16_25
      %1437 = "cute.static"() : () -> !cute.layout<"((8,1),4,2):((1,0),16,8)">
      %1438 = "cute.make_view"(%1430, %1437) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),4,2):((1,0),16,8)">) -> !memref_rmem_bf16_32
      %1439 = "cute.get_iter"(%1438) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
      %1440 = "cute.make_view"(%1439) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_33
      %1441 = "cute.static"() : () -> !cute.layout<"1:0">
      %1442 = "cute.get_iter"(%1436) : (!memref_smem_bf16_25) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1443 = "cute.get_iter"(%1440) : (!memref_rmem_bf16_33) -> !cute.ptr<bf16, rmem, align<32>>
      %1444 = "cute.static"() : () -> !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
      %1445 = "cute.static"() : () -> !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">
      %1446 = "cute.static"() : () -> !cute.int_tuple<"8">
      %1447 = "cute.get_scalars"(%1446) : (!cute.int_tuple<"8">) -> i32
      %1448 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %1449 = "arith.constant"() <{value = 1 : i32}> : () -> i32
      "scf.for"(%1448, %1447, %1449) ({
      ^bb0(%arg15: i32):
        %1866 = "cute.make_coord"(%arg15) : (i32) -> !cute.coord<"(_,?)">
        %1867 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
        %1868 = "cute.crd2idx"(%1866, %1444) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
        %1869 = "cute.add_offset"(%1442, %1868) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %1870 = "cute.make_view"(%1869, %1867) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_smem_bf16_26
        %1871 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
        %1872 = "cute.crd2idx"(%1866, %1445) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
        %1873 = "cute.add_offset"(%1443, %1872) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %1874 = "cute.make_view"(%1873, %1871) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
        %1875 = "cute.get_iter"(%1870) : (!memref_smem_bf16_26) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %1876 = "cute.get_iter"(%1874) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
        %1877 = "cute.apply_swizzle"(%1875) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %1878 = "builtin.unrealized_conversion_cast"(%1877) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>) -> !llvm.ptr<3>
        %1879 = "builtin.unrealized_conversion_cast"(%1876) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
        %1880 = "llvm.load"(%1878) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
        "llvm.store"(%1880, %1879) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
        "scf.yield"() : () -> ()
      }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
      %1450 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1451 = "cute.get_shape"(%1450) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1452:4 = "cute.get_leaves"(%1451) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1453 = "cute.to_int_tuple"(%1452#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1454 = "cute.to_int_tuple"(%1452#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1455 = "cute.to_int_tuple"(%1452#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1456 = "cute.to_int_tuple"(%1452#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1457 = "cute.make_shape"(%1453, %1454, %1455, %1456) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1458 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %1459 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2,1@3)">
      %1460 = "cute.make_layout"(%1457, %1459) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?,?{div=8})">, !cute.stride<"(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1461 = "cute.make_view"(%1458, %1460) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1462 = "cute.make_coord"(%72, %73) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %1463 = "cute.get_layout"(%1461) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1464:4 = "cute.get_scalars"(%1463) <{only_dynamic}> : (!cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> (i32, i32, i32, i32)
      %1465 = "cute.assume"(%1464#3) : (i32) -> !cute.i32<divby 8>
      %1466 = "cute.make_shape"(%1464#1, %1465) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %1467 = "cute.static"() : () -> !cute.stride<"(1@1,1@3)">
      %1468 = "cute.make_layout"(%1466, %1467) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?{div=8})">, !cute.stride<"(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %1469 = "cute.crd2idx"(%1462, %1463) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %1470 = "cute.get_iter"(%1461) : (!cute.coord_tensor<"(0,0,0,0)", "(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.arith_tuple_iter<"(0,0,0,0)">
      %1471 = "cute.add_offset"(%1470, %1469) : (!cute.arith_tuple_iter<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %1472 = "cute.make_view"(%1471, %1468) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> !cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">
      %1473 = "cute.make_coord"(%88) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %1474 = "cute.get_scalars"(%1473) <{only_dynamic}> : (!cute.coord<"(?,0)">) -> i32
      %1475 = "cute.make_coord"(%1474) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %1476 = "cute.get_layout"(%1472) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %1477:2 = "cute.get_scalars"(%1476) <{only_dynamic}> : (!cute.layout<"(?,?{div=8}):(1@1,1@3)">) -> (i32, i32)
      %1478 = "arith.constant"() <{value = 64 : i32}> : () -> i32
      %1479 = "arith.ceildivsi"(%1477#0, %1478) : (i32, i32) -> i32
      %1480 = "arith.constant"() <{value = 128 : i32}> : () -> i32
      %1481 = "arith.ceildivsi"(%1477#1, %1480) : (i32, i32) -> i32
      %1482 = "cute.make_shape"(%1479, %1481) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %1483 = "cute.static"() : () -> !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %1484 = "cute.make_layout"(%1482, %1483) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((64,128),(?,?))">, !cute.stride<"((1@1,1@3),(64@1,128@3))">) -> !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %1485 = "cute.crd2idx"(%1475, %1484) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %1486 = "cute.get_iter"(%1472) : (!cute.coord_tensor<"(?,0,?,0)", "(?,?{div=8}):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,0,?,0)">
      %1487 = "cute.add_offset"(%1486, %1485) : (!cute.arith_tuple_iter<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %1488 = "cute.make_view"(%1487) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">) -> !cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">
      %1489 = "cute.make_coord"(%71) : (i32) -> !cute.coord<"?">
      %1490 = "cute.get_iter"(%1488) : (!cute.coord_tensor<"(?,?{div=64},?,0)", "(64,128):(1@1,1@3)">) -> !cute.arith_tuple_iter<"(?,?{div=64},?,0)">
      %1491 = "cute.get_scalars"(%1489) <{only_dynamic}> : (!cute.coord<"?">) -> i32
      %1492 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1493 = "arith.divsi"(%1491, %1492) : (i32, i32) -> i32
      %1494 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1495 = "arith.remsi"(%1491, %1494) : (i32, i32) -> i32
      %1496 = "arith.constant"() <{value = 8 : i32}> : () -> i32
      %1497 = "arith.muli"(%1495, %1496) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
      %1498 = "cute.assume"(%1497) : (i32) -> !cute.i32<divby 8>
      %1499 = "cute.make_int_tuple"(%1493, %1498) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %1500 = "cute.add_offset"(%1490, %1499) : (!cute.arith_tuple_iter<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1501 = "cute.make_view"(%1500) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">
      %1502 = "cute.static"() : () -> !cute.layout<"(1,4,2):(2,0,1)">
      %1503 = "cute.memref.alloca"(%1502) : (!cute.layout<"(1,4,2):(2,0,1)">) -> !memref_rmem_i8_
      %1504 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %1505 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1506 = "cute.add_offset"(%1505, %1504) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1507 = "cute.make_view"(%1506) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1508 = "cute.get_iter"(%1507) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1509 = "cute.deref_arith_tuple_iter"(%1508) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1510:4 = "cute.get_leaves"(%1509) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1511 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1512 = "cute.get_shape"(%1511) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1513:4 = "cute.get_leaves"(%1512) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1514 = "cute.to_int_tuple"(%1513#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1515 = "cute.make_coord"(%1510#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1516 = "cute.make_coord"(%1514) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1517 = "cute.get_scalars"(%1515) : (!cute.coord<"?{div=8}">) -> i32
      %1518 = "cute.get_scalars"(%1516) : (!cute.coord<"?{div=8}">) -> i32
      %1519 = "arith.constant"() <{value = true}> : () -> i1
      %1520 = "arith.cmpi"(%1517, %1518) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1521 = "arith.andi"(%1519, %1520) : (i1, i1) -> i1
      %1522 = "arith.extui"(%1521) : (i1) -> i8
      %1523 = "cute.static"() : () -> !cute.coord<"(0,0,0)">
      "cute.memref.store"(%1503, %1523, %1522) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %1524 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,64)">
      %1525 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1526 = "cute.add_offset"(%1525, %1524) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1527 = "cute.make_view"(%1526) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1528 = "cute.get_iter"(%1527) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1529 = "cute.deref_arith_tuple_iter"(%1528) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1530:4 = "cute.get_leaves"(%1529) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1531 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1532 = "cute.get_shape"(%1531) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1533:4 = "cute.get_leaves"(%1532) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1534 = "cute.to_int_tuple"(%1533#3) : (!cute.shape<"?{div=8}">) -> !cute.int_tuple<"?{div=8}">
      %1535 = "cute.make_coord"(%1530#3) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1536 = "cute.make_coord"(%1534) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1537 = "cute.get_scalars"(%1535) : (!cute.coord<"?{div=8}">) -> i32
      %1538 = "cute.get_scalars"(%1536) : (!cute.coord<"?{div=8}">) -> i32
      %1539 = "arith.constant"() <{value = true}> : () -> i1
      %1540 = "arith.cmpi"(%1537, %1538) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1541 = "arith.andi"(%1539, %1540) : (i1, i1) -> i1
      %1542 = "arith.extui"(%1541) : (i1) -> i8
      %1543 = "cute.static"() : () -> !cute.coord<"(0,0,1)">
      "cute.memref.store"(%1503, %1543, %1542) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %1544 = "cute.static"() : () -> !cute.int_tuple<"(0,0,0,0)">
      %1545 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1546 = "cute.add_offset"(%1545, %1544) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1547 = "cute.make_view"(%1546) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1548 = "cute.get_iter"(%1547) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1549 = "cute.deref_arith_tuple_iter"(%1548) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1550:4 = "cute.get_leaves"(%1549) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1551 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1552 = "cute.get_shape"(%1551) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1553:4 = "cute.get_leaves"(%1552) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1554 = "cute.to_int_tuple"(%1553#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1555 = "cute.make_coord"(%1550#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1556 = "cute.make_coord"(%1554) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1557 = "cute.get_scalars"(%1555) : (!cute.coord<"?">) -> i32
      %1558 = "cute.get_scalars"(%1556) : (!cute.coord<"?">) -> i32
      %1559 = "arith.constant"() <{value = true}> : () -> i1
      %1560 = "arith.cmpi"(%1557, %1558) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1561 = "arith.andi"(%1559, %1560) : (i1, i1) -> i1
      "scf.if"(%1561) ({
        %1805 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1806 = "cute.get_iter"(%1429) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
        %1807 = "cute.add_offset"(%1806, %1805) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %1808 = "cute.make_view"(%1807) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_34
        %1809 = "cute.get_iter"(%1808) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1810 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1811 = "cute.get_iter"(%1427) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1812 = "cute.add_offset"(%1811, %1810) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %1813 = "cute.make_view"(%1812) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %1814 = "cute.get_iter"(%1813) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1815 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1816 = "cute.get_iter"(%1503) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1817 = "cute.add_offset"(%1816, %1815) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %1818 = "cute.make_view"(%1817) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1819 = "cute.get_iter"(%1818) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1820 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),8)">
        %1821 = "cute.make_view"(%1809, %1820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),2):((1,0),8)">) -> !memref_rmem_bf16_34
        %1822 = "cute.get_iter"(%1821) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1823 = "cute.make_view"(%1822) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_35
        %1824 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %1825 = "cute.make_view"(%1814, %1824) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %1826 = "cute.get_iter"(%1825) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1827 = "cute.make_view"(%1826) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %1828 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %1829 = "cute.make_view"(%1819, %1828) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %1830 = "cute.get_iter"(%1829) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1831 = "cute.make_view"(%1830) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %1832 = "cute.static"() : () -> !cute.layout<"1:0">
        %1833 = "cute.get_iter"(%1823) : (!memref_rmem_bf16_35) -> !cute.ptr<bf16, rmem, align<32>>
        %1834 = "cute.get_iter"(%1827) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %1835 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1836 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1837 = "cute.get_iter"(%1831) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %1838 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %1839 = "cute.static"() : () -> !cute.int_tuple<"2">
        %1840 = "cute.get_scalars"(%1839) : (!cute.int_tuple<"2">) -> i32
        %1841 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1842 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1841, %1840, %1842) ({
        ^bb0(%arg14: i32):
          %1843 = "cute.make_coord"(%arg14) : (i32) -> !cute.coord<"(_,?)">
          %1844 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1845 = "cute.crd2idx"(%1843, %1835) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %1846 = "cute.add_offset"(%1833, %1845) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %1847 = "cute.make_view"(%1846, %1844) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %1848 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1849 = "cute.crd2idx"(%1843, %1836) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %1850 = "cute.add_offset"(%1834, %1849) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %1851 = "cute.make_view"(%1850, %1848) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %1852 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %1853 = "cute.crd2idx"(%1843, %1838) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %1854 = "cute.add_offset"(%1837, %1853) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1855 = "cute.make_view"(%1854, %1852) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %1856 = "cute.get_iter"(%1847) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %1857 = "cute.get_iter"(%1851) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %1858 = "cute.get_iter"(%1855) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %1859 = "builtin.unrealized_conversion_cast"(%1858) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1860 = "llvm.load"(%1859) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1861 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1862 = "llvm.icmp"(%1860, %1861) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1862) ({
            %1863 = "builtin.unrealized_conversion_cast"(%1856) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1864 = "builtin.unrealized_conversion_cast"(%1857) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1865 = "llvm.load"(%1863) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1865, %1864) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %1562 = "cute.static"() : () -> !cute.int_tuple<"(0,16,0,0)">
      %1563 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1564 = "cute.add_offset"(%1563, %1562) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1565 = "cute.make_view"(%1564) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1566 = "cute.get_iter"(%1565) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1567 = "cute.deref_arith_tuple_iter"(%1566) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1568:4 = "cute.get_leaves"(%1567) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1569 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1570 = "cute.get_shape"(%1569) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1571:4 = "cute.get_leaves"(%1570) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1572 = "cute.to_int_tuple"(%1571#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1573 = "cute.make_coord"(%1568#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1574 = "cute.make_coord"(%1572) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1575 = "cute.get_scalars"(%1573) : (!cute.coord<"?">) -> i32
      %1576 = "cute.get_scalars"(%1574) : (!cute.coord<"?">) -> i32
      %1577 = "arith.constant"() <{value = true}> : () -> i1
      %1578 = "arith.cmpi"(%1575, %1576) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1579 = "arith.andi"(%1577, %1578) : (i1, i1) -> i1
      "scf.if"(%1579) ({
        %1742 = "cute.static"() : () -> !cute.int_tuple<"16">
        %1743 = "cute.get_iter"(%1429) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
        %1744 = "cute.add_offset"(%1743, %1742) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %1745 = "cute.make_view"(%1744) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_34
        %1746 = "cute.get_iter"(%1745) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1747 = "cute.static"() : () -> !cute.coord<"(_,1,_)">
        %1748 = "cute.get_layout"(%1427) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %1749 = "cute.crd2idx"(%1747, %1748) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %1750 = "cute.get_iter"(%1427) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1751 = "cute.add_offset"(%1750, %1749) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %1752 = "cute.make_view"(%1751) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %1753 = "cute.get_iter"(%1752) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1754 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1755 = "cute.get_iter"(%1503) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1756 = "cute.add_offset"(%1755, %1754) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %1757 = "cute.make_view"(%1756) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1758 = "cute.get_iter"(%1757) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1759 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),8)">
        %1760 = "cute.make_view"(%1746, %1759) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),2):((1,0),8)">) -> !memref_rmem_bf16_34
        %1761 = "cute.get_iter"(%1760) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1762 = "cute.make_view"(%1761) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_35
        %1763 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %1764 = "cute.make_view"(%1753, %1763) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %1765 = "cute.get_iter"(%1764) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1766 = "cute.make_view"(%1765) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %1767 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %1768 = "cute.make_view"(%1758, %1767) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %1769 = "cute.get_iter"(%1768) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1770 = "cute.make_view"(%1769) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %1771 = "cute.static"() : () -> !cute.layout<"1:0">
        %1772 = "cute.get_iter"(%1762) : (!memref_rmem_bf16_35) -> !cute.ptr<bf16, rmem, align<32>>
        %1773 = "cute.get_iter"(%1766) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %1774 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1775 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1776 = "cute.get_iter"(%1770) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %1777 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %1778 = "cute.static"() : () -> !cute.int_tuple<"2">
        %1779 = "cute.get_scalars"(%1778) : (!cute.int_tuple<"2">) -> i32
        %1780 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1781 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1780, %1779, %1781) ({
        ^bb0(%arg13: i32):
          %1782 = "cute.make_coord"(%arg13) : (i32) -> !cute.coord<"(_,?)">
          %1783 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1784 = "cute.crd2idx"(%1782, %1774) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %1785 = "cute.add_offset"(%1772, %1784) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %1786 = "cute.make_view"(%1785, %1783) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %1787 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1788 = "cute.crd2idx"(%1782, %1775) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %1789 = "cute.add_offset"(%1773, %1788) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %1790 = "cute.make_view"(%1789, %1787) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %1791 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %1792 = "cute.crd2idx"(%1782, %1777) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %1793 = "cute.add_offset"(%1776, %1792) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1794 = "cute.make_view"(%1793, %1791) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %1795 = "cute.get_iter"(%1786) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %1796 = "cute.get_iter"(%1790) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %1797 = "cute.get_iter"(%1794) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %1798 = "builtin.unrealized_conversion_cast"(%1797) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1799 = "llvm.load"(%1798) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1800 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1801 = "llvm.icmp"(%1799, %1800) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1801) ({
            %1802 = "builtin.unrealized_conversion_cast"(%1795) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1803 = "builtin.unrealized_conversion_cast"(%1796) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1804 = "llvm.load"(%1802) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1804, %1803) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %1580 = "cute.static"() : () -> !cute.int_tuple<"(0,32,0,0)">
      %1581 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1582 = "cute.add_offset"(%1581, %1580) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1583 = "cute.make_view"(%1582) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1584 = "cute.get_iter"(%1583) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1585 = "cute.deref_arith_tuple_iter"(%1584) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1586:4 = "cute.get_leaves"(%1585) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1587 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1588 = "cute.get_shape"(%1587) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1589:4 = "cute.get_leaves"(%1588) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1590 = "cute.to_int_tuple"(%1589#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1591 = "cute.make_coord"(%1586#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1592 = "cute.make_coord"(%1590) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1593 = "cute.get_scalars"(%1591) : (!cute.coord<"?">) -> i32
      %1594 = "cute.get_scalars"(%1592) : (!cute.coord<"?">) -> i32
      %1595 = "arith.constant"() <{value = true}> : () -> i1
      %1596 = "arith.cmpi"(%1593, %1594) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1597 = "arith.andi"(%1595, %1596) : (i1, i1) -> i1
      "scf.if"(%1597) ({
        %1679 = "cute.static"() : () -> !cute.int_tuple<"32">
        %1680 = "cute.get_iter"(%1429) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
        %1681 = "cute.add_offset"(%1680, %1679) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %1682 = "cute.make_view"(%1681) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_34
        %1683 = "cute.get_iter"(%1682) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1684 = "cute.static"() : () -> !cute.coord<"(_,2,_)">
        %1685 = "cute.get_layout"(%1427) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %1686 = "cute.crd2idx"(%1684, %1685) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %1687 = "cute.get_iter"(%1427) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1688 = "cute.add_offset"(%1687, %1686) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %1689 = "cute.make_view"(%1688) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %1690 = "cute.get_iter"(%1689) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1691 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1692 = "cute.get_iter"(%1503) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1693 = "cute.add_offset"(%1692, %1691) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %1694 = "cute.make_view"(%1693) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1695 = "cute.get_iter"(%1694) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1696 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),8)">
        %1697 = "cute.make_view"(%1683, %1696) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),2):((1,0),8)">) -> !memref_rmem_bf16_34
        %1698 = "cute.get_iter"(%1697) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1699 = "cute.make_view"(%1698) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_35
        %1700 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %1701 = "cute.make_view"(%1690, %1700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %1702 = "cute.get_iter"(%1701) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1703 = "cute.make_view"(%1702) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %1704 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %1705 = "cute.make_view"(%1695, %1704) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %1706 = "cute.get_iter"(%1705) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1707 = "cute.make_view"(%1706) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %1708 = "cute.static"() : () -> !cute.layout<"1:0">
        %1709 = "cute.get_iter"(%1699) : (!memref_rmem_bf16_35) -> !cute.ptr<bf16, rmem, align<32>>
        %1710 = "cute.get_iter"(%1703) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %1711 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1712 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1713 = "cute.get_iter"(%1707) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %1714 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %1715 = "cute.static"() : () -> !cute.int_tuple<"2">
        %1716 = "cute.get_scalars"(%1715) : (!cute.int_tuple<"2">) -> i32
        %1717 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1718 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1717, %1716, %1718) ({
        ^bb0(%arg12: i32):
          %1719 = "cute.make_coord"(%arg12) : (i32) -> !cute.coord<"(_,?)">
          %1720 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1721 = "cute.crd2idx"(%1719, %1711) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %1722 = "cute.add_offset"(%1709, %1721) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %1723 = "cute.make_view"(%1722, %1720) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %1724 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1725 = "cute.crd2idx"(%1719, %1712) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %1726 = "cute.add_offset"(%1710, %1725) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %1727 = "cute.make_view"(%1726, %1724) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %1728 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %1729 = "cute.crd2idx"(%1719, %1714) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %1730 = "cute.add_offset"(%1713, %1729) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1731 = "cute.make_view"(%1730, %1728) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %1732 = "cute.get_iter"(%1723) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %1733 = "cute.get_iter"(%1727) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %1734 = "cute.get_iter"(%1731) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %1735 = "builtin.unrealized_conversion_cast"(%1734) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1736 = "llvm.load"(%1735) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1737 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1738 = "llvm.icmp"(%1736, %1737) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1738) ({
            %1739 = "builtin.unrealized_conversion_cast"(%1732) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1740 = "builtin.unrealized_conversion_cast"(%1733) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1741 = "llvm.load"(%1739) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1741, %1740) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      %1598 = "cute.static"() : () -> !cute.int_tuple<"(0,48,0,0)">
      %1599 = "cute.get_iter"(%1501) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "((8,1),4,2):((1@3,0),16@1,64@3)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1600 = "cute.add_offset"(%1599, %1598) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1601 = "cute.make_view"(%1600) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.coord_tensor<"(?,?,?,?{div=8})", "():()">
      %1602 = "cute.get_iter"(%1601) : (!cute.coord_tensor<"(?,?,?,?{div=8})", "():()">) -> !cute.arith_tuple_iter<"(?,?,?,?{div=8})">
      %1603 = "cute.deref_arith_tuple_iter"(%1602) : (!cute.arith_tuple_iter<"(?,?,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %1604:4 = "cute.get_leaves"(%1603) : (!cute.int_tuple<"(?,?,?,?{div=8})">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">)
      %1605 = "cute.get_layout"(%arg9) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %1606 = "cute.get_shape"(%1605) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %1607:4 = "cute.get_leaves"(%1606) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
      %1608 = "cute.to_int_tuple"(%1607#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
      %1609 = "cute.make_coord"(%1604#1) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1610 = "cute.make_coord"(%1608) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1611 = "cute.get_scalars"(%1609) : (!cute.coord<"?">) -> i32
      %1612 = "cute.get_scalars"(%1610) : (!cute.coord<"?">) -> i32
      %1613 = "arith.constant"() <{value = true}> : () -> i1
      %1614 = "arith.cmpi"(%1611, %1612) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %1615 = "arith.andi"(%1613, %1614) : (i1, i1) -> i1
      "scf.if"(%1615) ({
        %1616 = "cute.static"() : () -> !cute.int_tuple<"48">
        %1617 = "cute.get_iter"(%1429) : (!memref_rmem_bf16_32) -> !cute.ptr<bf16, rmem, align<32>>
        %1618 = "cute.add_offset"(%1617, %1616) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %1619 = "cute.make_view"(%1618) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_34
        %1620 = "cute.get_iter"(%1619) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1621 = "cute.static"() : () -> !cute.coord<"(_,3,_)">
        %1622 = "cute.get_layout"(%1427) : (!memref_gmem_bf16_5) -> !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
        %1623 = "cute.crd2idx"(%1621, %1622) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %1624 = "cute.get_iter"(%1427) : (!memref_gmem_bf16_5) -> !cute.ptr<bf16, gmem, align<16>>
        %1625 = "cute.add_offset"(%1624, %1623) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %1626 = "cute.make_view"(%1625) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_8
        %1627 = "cute.get_iter"(%1626) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1628 = "cute.static"() : () -> !cute.int_tuple<"0">
        %1629 = "cute.get_iter"(%1503) : (!memref_rmem_i8_) -> !cute.ptr<i8, rmem, align<32>>
        %1630 = "cute.add_offset"(%1629, %1628) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %1631 = "cute.make_view"(%1630) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_1
        %1632 = "cute.get_iter"(%1631) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1633 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),8)">
        %1634 = "cute.make_view"(%1620, %1633) : (!cute.ptr<bf16, rmem, align<32>>, !cute.layout<"((8,1),2):((1,0),8)">) -> !memref_rmem_bf16_34
        %1635 = "cute.get_iter"(%1634) : (!memref_rmem_bf16_34) -> !cute.ptr<bf16, rmem, align<32>>
        %1636 = "cute.make_view"(%1635) : (!cute.ptr<bf16, rmem, align<32>>) -> !memref_rmem_bf16_35
        %1637 = "cute.static"() : () -> !cute.layout<"((8,1),2):((1,0),64)">
        %1638 = "cute.make_view"(%1627, %1637) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1),2):((1,0),64)">) -> !memref_gmem_bf16_8
        %1639 = "cute.get_iter"(%1638) : (!memref_gmem_bf16_8) -> !cute.ptr<bf16, gmem, align<16>>
        %1640 = "cute.make_view"(%1639) : (!cute.ptr<bf16, gmem, align<16>>) -> !memref_gmem_bf16_9
        %1641 = "cute.static"() : () -> !cute.layout<"(1,2):(2,1)">
        %1642 = "cute.make_view"(%1632, %1641) : (!cute.ptr<i8, rmem, align<32>>, !cute.layout<"(1,2):(2,1)">) -> !memref_rmem_i8_1
        %1643 = "cute.get_iter"(%1642) : (!memref_rmem_i8_1) -> !cute.ptr<i8, rmem, align<32>>
        %1644 = "cute.make_view"(%1643) : (!cute.ptr<i8, rmem, align<32>>) -> !memref_rmem_i8_2
        %1645 = "cute.static"() : () -> !cute.layout<"1:0">
        %1646 = "cute.get_iter"(%1636) : (!memref_rmem_bf16_35) -> !cute.ptr<bf16, rmem, align<32>>
        %1647 = "cute.get_iter"(%1640) : (!memref_gmem_bf16_9) -> !cute.ptr<bf16, gmem, align<16>>
        %1648 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((8)))">
        %1649 = "cute.static"() : () -> !cute.layout<"((8,1),((2))):((1,0),((64)))">
        %1650 = "cute.get_iter"(%1644) : (!memref_rmem_i8_2) -> !cute.ptr<i8, rmem, align<32>>
        %1651 = "cute.static"() : () -> !cute.layout<"(1,((2))):(2,((1)))">
        %1652 = "cute.static"() : () -> !cute.int_tuple<"2">
        %1653 = "cute.get_scalars"(%1652) : (!cute.int_tuple<"2">) -> i32
        %1654 = "arith.constant"() <{value = 0 : i32}> : () -> i32
        %1655 = "arith.constant"() <{value = 1 : i32}> : () -> i32
        "scf.for"(%1654, %1653, %1655) ({
        ^bb0(%arg11: i32):
          %1656 = "cute.make_coord"(%arg11) : (i32) -> !cute.coord<"(_,?)">
          %1657 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1658 = "cute.crd2idx"(%1656, %1648) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %1659 = "cute.add_offset"(%1646, %1658) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %1660 = "cute.make_view"(%1659, %1657) : (!cute.ptr<bf16, rmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_rmem_bf16_9
          %1661 = "cute.static"() : () -> !cute.layout<"((8,1)):((1,0))">
          %1662 = "cute.crd2idx"(%1656, %1649) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %1663 = "cute.add_offset"(%1647, %1662) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %1664 = "cute.make_view"(%1663, %1661) : (!cute.ptr<bf16, gmem, align<16>>, !cute.layout<"((8,1)):((1,0))">) -> !memref_gmem_bf16_10
          %1665 = "cute.static"() : () -> !cute.layout<"(1):(2)">
          %1666 = "cute.crd2idx"(%1656, %1651) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %1667 = "cute.add_offset"(%1650, %1666) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %1668 = "cute.make_view"(%1667, %1665) : (!cute.ptr<i8, rmem>, !cute.layout<"(1):(2)">) -> !memref_rmem_i8_3
          %1669 = "cute.get_iter"(%1660) : (!memref_rmem_bf16_9) -> !cute.ptr<bf16, rmem, align<16>>
          %1670 = "cute.get_iter"(%1664) : (!memref_gmem_bf16_10) -> !cute.ptr<bf16, gmem, align<16>>
          %1671 = "cute.get_iter"(%1668) : (!memref_rmem_i8_3) -> !cute.ptr<i8, rmem>
          %1672 = "builtin.unrealized_conversion_cast"(%1671) : (!cute.ptr<i8, rmem>) -> !llvm.ptr
          %1673 = "llvm.load"(%1672) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
          %1674 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
          %1675 = "llvm.icmp"(%1673, %1674) <{predicate = 1 : i64}> : (i8, i8) -> i1
          "scf.if"(%1675) ({
            %1676 = "builtin.unrealized_conversion_cast"(%1669) : (!cute.ptr<bf16, rmem, align<16>>) -> !llvm.ptr
            %1677 = "builtin.unrealized_conversion_cast"(%1670) : (!cute.ptr<bf16, gmem, align<16>>) -> !llvm.ptr<1>
            %1678 = "llvm.load"(%1676) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
            "llvm.store"(%1678, %1677) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
            "scf.yield"() : () -> ()
          }, {
          }) : (i1) -> ()
          "scf.yield"() : () -> ()
        }) {llvm.loop_annotation = #loop_annotation} : (i32, i32, i32) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !cuda.stream) -> i32, sym_name = "cutlass___call_____main__HSTUAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Ten"}> ({
  ^bb0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !cuda.stream):
    %0 = "cute.static"() : () -> !cute.swizzle<"S<3,4,3>">
    %1 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
    %2 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,2)):((64,512),(1,4096))">
    %3 = "cute.static"() : () -> !cute.composed_layout<"S<3,4,3> o 0 o ((8,8),(64,1)):((64,512),(1,0))">
    %4 = "cute.make_atom"() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
    %5 = "cute.make_atom"() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
    %6 = "cute.make_tiled_copy"(%4) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>) -> !copy_ldgsts
    %7 = "cute.make_tiled_copy"(%5) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>) -> !copy_simt
    %8 = "cute.get_layout"(%arg0) : (!memref_gmem_bf16_) -> !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
    %9 = "cute.get_shape"(%8) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %10:4 = "cute.get_leaves"(%9) : (!cute.shape<"(?,?,?,?{div=8})">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?{div=8}">)
    %11 = "cute.to_int_tuple"(%10#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %12 = "cute.make_int_tuple"(%11) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.get_scalars"(%12) <{only_dynamic}> : (!cute.int_tuple<"?">) -> i32
    %14 = "arith.constant"() <{value = 64 : i32}> : () -> i32
    %15 = "arith.ceildivsi"(%13, %14) : (i32, i32) -> i32
    %16 = "cute.make_int_tuple"(%15) : (i32) -> !cute.int_tuple<"?">
    %17 = "cute.get_leaves"(%16) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %18 = "cute.get_scalars"(%17) : (!cute.int_tuple<"?">) -> i32
    %19 = "cute.static"() : () -> !cute.tile<"[16:1;64:1]">
    %20 = "cute.static"() : () -> !cute.layout<"((8,16),8):((128,1),16)">
    %21 = "cute.static"() : () -> !cute.layout<"1:0">
    %22 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
    %23 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
    %24 = "cute.static"() : () -> !cute.tile<"[16:1;64:1]">
    %25 = "cute.static"() : () -> !cute.layout<"((8,16),8):((128,1),16)">
    %26 = "cute.static"() : () -> !cute.layout<"1:0">
    %27 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
    %28 = "cute.static"() : () -> !cute.layout<"(1,8):(0,1)">
    %29 = "cute.static"() : () -> !cute.layout<"(32,4,1,1):(1,32,0,0)">
    %30 = "cute.static"() : () -> !cute.tile<"[64:1;16:1;16:1]">
    %31 = "cute.static"() : () -> !cute.layout<"32:1">
    %32 = "cute.static"() : () -> !cute.shape<"(16,8,16)">
    %33 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2,2)):((32,1),(16,8,128))">
    %34 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2)):((16,1),(8,64))">
    %35 = "cute.static"() : () -> !cute.layout<"((4,8),(2,2)):((32,1),(16,8))">
    %36 = "arith.constant"() <{value = 57344 : i32}> : () -> i32
    %37 = "arith.extsi"(%36) : (i32) -> i64
    %38 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %39 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %40 = "arith.constant"() <{value = 4 : i32}> : () -> i32
    %41 = "cuda.launch_cfg.create"(%38, %39, %39, %37, %40, %40, %18, %arg5) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %42 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%41, %42) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %43 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%41, %43) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %44 = "cuda.launch_ex"(%41, %arg0, %arg1, %arg2, %arg3, %arg4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_) -> !cuda.result
    %45 = "cuda.cast"(%44) : (!cuda.result) -> i32
    "cuda.return_if_error"(%45) : (i32) -> ()
    %46 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%46) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
