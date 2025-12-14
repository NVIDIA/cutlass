!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">, tiler_mn = <"[64:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_2 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_3 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!copy_simt1 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<16>, "((2,2,2),1,((2,2),2)):((1,2,4),0,((16,32),8))">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<8>, "((2,2),(2,4),((2,2),2)):((1,2),(32,4),((64,128),16))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2),4):((1,2),(4,128),32)">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "((2,2),1,8):((1,2),0,4)">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_bf16_5 = !cute.memref<bf16, rmem, align<32>, "((8,1),4,2):((1,0),16,8)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),1,16):((1,2),0,4)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((2,2),1,8):((1,2),0,4)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,4,2):(2,0,1)">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),4096)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,1)):((1,0))">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,1),1):((1,0),0)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %cst = arith.constant dense<5.000000e-01> : vector<32xf32>
      %cst_0 = arith.constant dense<0.000000e+00> : vector<8xbf16>
      %cst_1 = arith.constant dense<0.000000e+00> : vector<16xbf16>
      %cst_2 = arith.constant dense<0.000000e+00> : vector<64xf32>
      %0 = llvm.mlir.constant(0 : i8) : i8
      %1 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %2 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">
      %3 = cute.static : !cute.int_tuple<"520">
      %4 = cute.static : !cute.int_tuple<"512">
      %5 = cute.static : !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">
      %6 = cute.static : !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">
      %7 = cute.static : !cute.int_tuple<"96">
      %8 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %9 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %10 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %11 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %12 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %c4_i32 = arith.constant 4 : i32
      %13 = cute.static : !cute.coord<"(3,0,7)">
      %14 = cute.static : !cute.coord<"(3,0,6)">
      %15 = cute.static : !cute.coord<"(3,0,5)">
      %16 = cute.static : !cute.coord<"(3,0,4)">
      %17 = cute.static : !cute.coord<"(3,0,3)">
      %18 = cute.static : !cute.coord<"(3,0,2)">
      %19 = cute.static : !cute.coord<"(3,0,1)">
      %20 = cute.static : !cute.coord<"(3,0,0)">
      %21 = cute.static : !cute.coord<"(2,0,7)">
      %22 = cute.static : !cute.coord<"(2,0,6)">
      %23 = cute.static : !cute.coord<"(2,0,5)">
      %24 = cute.static : !cute.coord<"(2,0,4)">
      %25 = cute.static : !cute.coord<"(2,0,3)">
      %26 = cute.static : !cute.coord<"(2,0,2)">
      %27 = cute.static : !cute.coord<"(2,0,1)">
      %28 = cute.static : !cute.coord<"(2,0,0)">
      %29 = cute.static : !cute.coord<"(1,0,7)">
      %30 = cute.static : !cute.coord<"(1,0,6)">
      %31 = cute.static : !cute.coord<"(1,0,5)">
      %32 = cute.static : !cute.coord<"(1,0,4)">
      %33 = cute.static : !cute.coord<"(1,0,3)">
      %34 = cute.static : !cute.coord<"(1,0,2)">
      %35 = cute.static : !cute.coord<"(1,0,1)">
      %36 = cute.static : !cute.coord<"(1,0,0)">
      %37 = cute.static : !cute.coord<"(0,0,7)">
      %38 = cute.static : !cute.coord<"(0,0,6)">
      %39 = cute.static : !cute.coord<"(0,0,5)">
      %40 = cute.static : !cute.coord<"(0,0,4)">
      %41 = cute.static : !cute.coord<"(0,0,3)">
      %42 = cute.static : !cute.coord<"(0,0,2)">
      %43 = cute.static : !cute.int_tuple<"208">
      %44 = cute.static : !cute.int_tuple<"56">
      %45 = cute.static : !cute.coord<"(_,_,7)">
      %46 = cute.static : !cute.int_tuple<"144">
      %47 = cute.static : !cute.int_tuple<"40">
      %48 = cute.static : !cute.coord<"(_,_,6)">
      %49 = cute.static : !cute.int_tuple<"80">
      %50 = cute.static : !cute.int_tuple<"24">
      %51 = cute.static : !cute.coord<"(_,_,5)">
      %52 = cute.static : !cute.int_tuple<"4096">
      %53 = cute.static : !cute.int_tuple<"192">
      %54 = cute.static : !cute.int_tuple<"48">
      %55 = cute.static : !cute.coord<"(_,_,3)">
      %56 = cute.static : !cute.int_tuple<"128">
      %57 = cute.static : !cute.coord<"(_,_,2)">
      %58 = cute.static : !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">
      %59 = cute.static : !cute.int_tuple<"64">
      %60 = cute.static : !cute.int_tuple<"16">
      %61 = cute.static : !cute.coord<"(_,_,1)">
      %62 = cute.static : !cute.int_tuple<"34">
      %63 = cute.static : !cute.int_tuple<"32">
      %64 = cute.static : !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">
      %65 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %66 = cute.static : !cute.int_tuple<"6">
      %67 = llvm.mlir.constant(3 : i32) : i32
      %68 = llvm.mlir.constant(2 : i32) : i32
      %69 = llvm.mlir.constant(1 : i32) : i32
      %70 = llvm.mlir.constant(0 : i32) : i32
      %71 = cute.static : !cute.int_tuple<"4">
      %72 = cute.static : !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">
      %73 = cute.static : !cute.shape<"((8,1),((1,(2,2))))">
      %74 = cute.static : !cute.shape<"((8,1),(1,(2,2)))">
      %75 = cute.static : !cute.layout<"((2,2),1,8):((1,2),0,4)">
      %76 = cute.static : !cute.int_tuple<"8">
      %77 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
      %78 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
      %79 = cute.static : !cute.shape<"((8,1),((4,2)))">
      %80 = cute.static : !cute.shape<"((8,1),(4,2))">
      %c-1_i32 = arith.constant -1 : i32
      %81 = cute.static : !cute.int_tuple<"-1">
      %82 = cute.static : !cute.int_tuple<"3072">
      %83 = cute.static : !cute.coord<"(_,3,_)">
      %84 = cute.static : !cute.int_tuple<"(0,48,0,0)">
      %85 = cute.static : !cute.int_tuple<"2048">
      %86 = cute.static : !cute.coord<"(_,2,_)">
      %87 = cute.static : !cute.int_tuple<"(0,32,0,0)">
      %88 = cute.static : !cute.int_tuple<"1024">
      %89 = cute.static : !cute.coord<"(_,1,_)">
      %90 = cute.static : !cute.int_tuple<"(0,16,0,0)">
      %c1_i32 = arith.constant 1 : i32
      %91 = cute.static : !cute.int_tuple<"2">
      %92 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
      %93 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %94 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
      %95 = cute.static : !cute.coord<"(0,0,1)">
      %96 = cute.static : !cute.int_tuple<"(0,0,0,64)">
      %97 = cute.static : !cute.coord<"(0,0,0)">
      %98 = cute.static : !cute.stride<"((1@3,0),16@2,0,64@3)">
      %99 = cute.static : !cute.stride<"(1@2,1@3,64@3)">
      %100 = cute.static : !cute.stride<"((1@2,1@3),(64@2,64@3))">
      %101 = cute.static : !cute.stride<"(1@2,1@3)">
      %102 = cute.static : !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %103 = cute.static : !cute.stride<"(1@1,1@3)">
      %104 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %105 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %106 = cute.static : !cute.shape<"((8,1),1,(2,2))">
      %107 = cute.static : !cute.shape<"((8,1),((2,2),2),4)">
      %108 = cute.static : !cute.shape<"((8,1),4,((2,2),2))">
      %c512_i32 = arith.constant 512 : i32
      %109 = cute.static : !cute.shape<"((8,1),1,((2,2),2))">
      %c-32_i32 = arith.constant -32 : i32
      %c32_i32 = arith.constant 32 : i32
      %c256_i32 = arith.constant 256 : i32
      %c-16_i32 = arith.constant -16 : i32
      %c1024_i32 = arith.constant 1024 : i32
      %110 = cute.static : !cute.layout<"((2,2),1,16):((1,2),0,4)">
      %c3_i32 = arith.constant 3 : i32
      %c896_i32 = arith.constant 896 : i32
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c2_i32 = arith.constant 2 : i32
      %111 = cute.static : !cute.shape<"((8,1),4,2)">
      %c8_i32 = arith.constant 8 : i32
      %c16_i64 = arith.constant 16 : i64
      %112 = cute.static : !cute.int_tuple<"49152">
      %113 = cute.static : !cute.int_tuple<"32768">
      %114 = cute.static : !cute.int_tuple<"16384">
      %115 = cute.static : !cute.shape<"(64,128)">
      %c128_i32 = arith.constant 128 : i32
      %c64_i64 = arith.constant 64 : i64
      %116 = cute.static : !cute.int_tuple<"1">
      %c64_i32 = arith.constant 64 : i32
      %117 = cute.static : !cute.layout<"1:0">
      %118 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %119 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %120 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %121 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %122 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%122) : !cute.shape<"(?,?,?,?{div=8})">
      %itup = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %int_tuple = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %123 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
      %124 = arith.ceildivsi %123, %c64_i32 : i32
      %int_tuple_3 = cute.make_int_tuple(%124) : (i32) -> !cute.int_tuple<"?">
      %e0_4 = cute.get_leaves(%int_tuple_3) : !cute.int_tuple<"?">
      %int_tuple_5 = cute.make_int_tuple(%121) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_4, %int_tuple_5) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %sub_6 = cute.tuple_sub(%sub, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %lay_7 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %125 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_8, %e1_9, %e2_10, %e3_11 = cute.get_leaves(%125) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_12 = cute.to_int_tuple(%e1_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %int_tuple_13 = cute.make_int_tuple(%itup_12) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %126 = cute.get_scalars(%int_tuple_13) <{only_dynamic}> : !cute.int_tuple<"?">
      %127 = arith.ceildivsi %126, %c64_i32 : i32
      %int_tuple_14 = cute.make_int_tuple(%127) : (i32) -> !cute.int_tuple<"?">
      %e0_15 = cute.get_leaves(%int_tuple_14) : !cute.int_tuple<"?">
      %sub_16 = cute.tuple_sub(%e0_15, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %128 = cute.get_scalars(%sub_16) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_17 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %129:7 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%129#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%129#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_18 = cute.assume(%129#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_18) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_19 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay_17) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_20 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %130 = cute.get_scalars(%coord_20) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_21 = cute.make_coord(%130) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %131:3 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %132 = arith.ceildivsi %131#0, %c64_i32 : i32
      %133 = arith.muli %131#2, %c64_i64 : i64
      %134 = arith.ceildivsi %131#1, %c128_i32 : i32
      %shape_22 = cute.make_shape(%132, %134) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_23 = cute.assume(%131#2) : (i64) -> !cute.i64<divby 8>
      %iv_24 = cute.assume(%133) : (i64) -> !cute.i64<divby 512>
      %stride_25 = cute.make_stride(%iv_23, %iv_24) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_26 = cute.make_layout(%shape_22, %stride_25) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %135:4 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_27 = cute.assume(%135#2) : (i64) -> !cute.i64<divby 8>
      %stride_28 = cute.make_stride(%iv_27) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_29 = cute.make_layout(%115, %stride_28) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_30 = cute.crd2idx(%coord_21, %lay_26) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_31 = cute.add_offset(%ptr, %idx_30) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_32 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_33 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %136:7 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_34 = cute.assume(%136#3) : (i32) -> !cute.i32<divby 8>
      %shape_35 = cute.make_shape(%136#1, %iv_34) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_36 = cute.assume(%136#5) : (i64) -> !cute.i64<divby 8>
      %stride_37 = cute.make_stride(%iv_36) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_38 = cute.make_layout(%shape_35, %stride_37) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_39 = cute.crd2idx(%coord_32, %lay_33) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_40 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_41 = cute.add_offset(%iter_40, %idx_39) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %137:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %138 = arith.ceildivsi %137#0, %c64_i32 : i32
      %139 = arith.muli %137#2, %c64_i64 : i64
      %140 = arith.ceildivsi %137#1, %c128_i32 : i32
      %shape_42 = cute.make_shape(%138, %140) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_43 = cute.assume(%137#2) : (i64) -> !cute.i64<divby 8>
      %iv_44 = cute.assume(%139) : (i64) -> !cute.i64<divby 512>
      %stride_45 = cute.make_stride(%iv_43, %iv_44) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_46 = cute.make_layout(%shape_42, %stride_45) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %141:4 = cute.get_scalars(%lay_46) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_47 = cute.make_shape(%141#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_48 = cute.assume(%141#2) : (i64) -> !cute.i64<divby 8>
      %iv_49 = cute.assume(%141#3) : (i64) -> !cute.i64<divby 512>
      %stride_50 = cute.make_stride(%iv_48, %iv_49) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_51 = cute.make_layout(%shape_47, %stride_50) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %coord_52 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_53 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %142:7 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_54 = cute.assume(%142#3) : (i32) -> !cute.i32<divby 8>
      %shape_55 = cute.make_shape(%142#1, %iv_54) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_56 = cute.assume(%142#5) : (i64) -> !cute.i64<divby 8>
      %stride_57 = cute.make_stride(%iv_56) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_58 = cute.make_layout(%shape_55, %stride_57) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_59 = cute.crd2idx(%coord_52, %lay_53) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_60 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_61 = cute.add_offset(%iter_60, %idx_59) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %143:3 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %144 = arith.ceildivsi %143#0, %c64_i32 : i32
      %145 = arith.muli %143#2, %c64_i64 : i64
      %146 = arith.ceildivsi %143#1, %c128_i32 : i32
      %shape_62 = cute.make_shape(%144, %146) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_63 = cute.assume(%143#2) : (i64) -> !cute.i64<divby 8>
      %iv_64 = cute.assume(%145) : (i64) -> !cute.i64<divby 512>
      %stride_65 = cute.make_stride(%iv_63, %iv_64) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_66 = cute.make_layout(%shape_62, %stride_65) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %147:4 = cute.get_scalars(%lay_66) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_67 = cute.make_shape(%147#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_68 = cute.assume(%147#2) : (i64) -> !cute.i64<divby 8>
      %iv_69 = cute.assume(%147#3) : (i64) -> !cute.i64<divby 512>
      %stride_70 = cute.make_stride(%iv_68, %iv_69) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_71 = cute.make_layout(%shape_67, %stride_70) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %coord_72 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %lay_73 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %148:7 = cute.get_scalars(%lay_73) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_74 = cute.assume(%148#3) : (i32) -> !cute.i32<divby 8>
      %shape_75 = cute.make_shape(%148#2, %iv_74) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_76 = cute.assume(%148#6) : (i64) -> !cute.i64<divby 8>
      %stride_77 = cute.make_stride(%iv_76) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_78 = cute.make_layout(%shape_75, %stride_77) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_79 = cute.crd2idx(%coord_72, %lay_73) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_80 = cute.get_iter(%arg4) : !memref_gmem_bf16_
      %ptr_81 = cute.add_offset(%iter_80, %idx_79) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_82 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %149 = cute.get_scalars(%coord_82) <{only_dynamic}> : !cute.coord<"(?,_)">
      %coord_83 = cute.make_coord(%149) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %150:3 = cute.get_scalars(%lay_78) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %151 = arith.ceildivsi %150#0, %c64_i32 : i32
      %152 = arith.muli %150#2, %c64_i64 : i64
      %153 = arith.ceildivsi %150#1, %c64_i32 : i32
      %shape_84 = cute.make_shape(%151, %153) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %iv_85 = cute.assume(%150#2) : (i64) -> !cute.i64<divby 8>
      %iv_86 = cute.assume(%152) : (i64) -> !cute.i64<divby 512>
      %stride_87 = cute.make_stride(%iv_85, %iv_86) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},64))">
      %lay_88 = cute.make_layout(%shape_84, %stride_87) : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %154:4 = cute.get_scalars(%lay_88) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %shape_89 = cute.make_shape(%154#1) : (i32) -> !cute.shape<"(64,64,?)">
      %iv_90 = cute.assume(%154#2) : (i64) -> !cute.i64<divby 8>
      %stride_91 = cute.make_stride(%iv_90) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1,64)">
      %lay_92 = cute.make_layout(%shape_89, %stride_91) : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %idx_93 = cute.crd2idx(%coord_83, %lay_88) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_94 = cute.add_offset(%ptr_81, %idx_93) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_95 = cute.add_offset(%smem_ptr, %114) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_96 = cute.add_offset(%smem_ptr, %113) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_97 = cute.add_offset(%smem_ptr, %112) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_98 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_99 = cute.recast_iter(%ptr_95) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_100 = cute.recast_iter(%ptr_96) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_101 = cute.recast_iter(%ptr_97) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %coord_102 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %155 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %156 = cute.get_scalars(%coord_102) <{only_dynamic}> : !cute.coord<"?">
      %157 = arith.muli %155, %c16_i64 : i64
      %158 = arith.divsi %156, %c8_i32 : i32
      %159 = arith.remsi %156, %c8_i32 : i32
      %160 = arith.muli %159, %c8_i32 : i32
      %161 = arith.extsi %158 : i32 to i64
      %162 = arith.muli %161, %155 : i64
      %163 = arith.extsi %160 : i32 to i64
      %164 = arith.addi %163, %162 : i64
      %iv_103 = cute.assume(%164) : (i64) -> !cute.i64<divby 8>
      %int_tuple_104 = cute.make_int_tuple(%iv_103) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_105 = cute.add_offset(%ptr_31, %int_tuple_104) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_106 = cute.assume(%157) : (i64) -> !cute.i64<divby 128>
      %stride_107 = cute.make_stride(%iv_106) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_108 = cute.make_layout(%111, %stride_107) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %coord_109 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %165 = cute.get_scalars(%coord_109) <{only_dynamic}> : !cute.coord<"?">
      %166 = arith.divsi %165, %c8_i32 : i32
      %167 = arith.remsi %165, %c8_i32 : i32
      %168 = arith.divsi %167, %c2_i32 : i32
      %169 = arith.muli %168, %c16_i32 : i32
      %170 = arith.muli %166, %c64_i32 : i32
      %171 = arith.addi %169, %170 : i32
      %172 = arith.remsi %165, %c8_i32 : i32
      %173 = arith.remsi %172, %c2_i32 : i32
      %174 = arith.muli %173, %c8_i32 : i32
      %175 = arith.andi %171, %c896_i32 : i32
      %176 = arith.shrsi %175, %c3_i32 : i32
      %177 = arith.xori %171, %176 : i32
      %178 = arith.addi %177, %174 : i32
      %iv_110 = cute.assume(%178) : (i32) -> !cute.i32<divby 8>
      %int_tuple_111 = cute.make_int_tuple(%iv_110) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_112 = cute.add_offset(%iter_98, %int_tuple_111) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %coord_113 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %179:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %180 = cute.get_scalars(%coord_113) <{only_dynamic}> : !cute.coord<"?">
      %181 = arith.muli %179#1, %c16_i64 : i64
      %182 = arith.divsi %180, %c8_i32 : i32
      %183 = arith.remsi %180, %c8_i32 : i32
      %184 = arith.muli %183, %c8_i32 : i32
      %185 = arith.extsi %182 : i32 to i64
      %186 = arith.muli %185, %179#1 : i64
      %187 = arith.extsi %184 : i32 to i64
      %188 = arith.addi %187, %186 : i64
      %iv_114 = cute.assume(%188) : (i64) -> !cute.i64<divby 8>
      %int_tuple_115 = cute.make_int_tuple(%iv_114) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_116 = cute.add_offset(%ptr_41, %int_tuple_115) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_117 = cute.make_shape(%179#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_118 = cute.assume(%181) : (i64) -> !cute.i64<divby 128>
      %iv_119 = cute.assume(%179#2) : (i64) -> !cute.i64<divby 512>
      %stride_120 = cute.make_stride(%iv_118, %iv_119) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_121 = cute.make_layout(%shape_117, %stride_120) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %coord_122 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %189 = cute.get_scalars(%coord_122) <{only_dynamic}> : !cute.coord<"?">
      %190 = arith.divsi %189, %c8_i32 : i32
      %191 = arith.remsi %189, %c8_i32 : i32
      %192 = arith.divsi %191, %c2_i32 : i32
      %193 = arith.muli %192, %c16_i32 : i32
      %194 = arith.muli %190, %c64_i32 : i32
      %195 = arith.addi %193, %194 : i32
      %196 = arith.remsi %189, %c8_i32 : i32
      %197 = arith.remsi %196, %c2_i32 : i32
      %198 = arith.muli %197, %c8_i32 : i32
      %199 = arith.andi %195, %c896_i32 : i32
      %200 = arith.shrsi %199, %c3_i32 : i32
      %201 = arith.xori %195, %200 : i32
      %202 = arith.addi %201, %198 : i32
      %iv_123 = cute.assume(%202) : (i32) -> !cute.i32<divby 8>
      %int_tuple_124 = cute.make_int_tuple(%iv_123) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_125 = cute.add_offset(%iter_99, %int_tuple_124) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %coord_126 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %203:3 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %204 = cute.get_scalars(%coord_126) <{only_dynamic}> : !cute.coord<"?">
      %205 = arith.muli %203#1, %c16_i64 : i64
      %206 = arith.divsi %204, %c8_i32 : i32
      %207 = arith.remsi %204, %c8_i32 : i32
      %208 = arith.muli %207, %c8_i32 : i32
      %209 = arith.extsi %206 : i32 to i64
      %210 = arith.muli %209, %203#1 : i64
      %211 = arith.extsi %208 : i32 to i64
      %212 = arith.addi %211, %210 : i64
      %iv_127 = cute.assume(%212) : (i64) -> !cute.i64<divby 8>
      %int_tuple_128 = cute.make_int_tuple(%iv_127) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_129 = cute.add_offset(%ptr_61, %int_tuple_128) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_130 = cute.make_shape(%203#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_131 = cute.assume(%205) : (i64) -> !cute.i64<divby 128>
      %iv_132 = cute.assume(%203#2) : (i64) -> !cute.i64<divby 512>
      %stride_133 = cute.make_stride(%iv_131, %iv_132) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_134 = cute.make_layout(%shape_130, %stride_133) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %coord_135 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %213 = cute.get_scalars(%coord_135) <{only_dynamic}> : !cute.coord<"?">
      %214 = arith.divsi %213, %c8_i32 : i32
      %215 = arith.remsi %213, %c8_i32 : i32
      %216 = arith.divsi %215, %c2_i32 : i32
      %217 = arith.muli %216, %c16_i32 : i32
      %218 = arith.muli %214, %c64_i32 : i32
      %219 = arith.addi %217, %218 : i32
      %220 = arith.remsi %213, %c8_i32 : i32
      %221 = arith.remsi %220, %c2_i32 : i32
      %222 = arith.muli %221, %c8_i32 : i32
      %223 = arith.andi %219, %c896_i32 : i32
      %224 = arith.shrsi %223, %c3_i32 : i32
      %225 = arith.xori %219, %224 : i32
      %226 = arith.addi %225, %222 : i32
      %iv_136 = cute.assume(%226) : (i32) -> !cute.i32<divby 8>
      %int_tuple_137 = cute.make_int_tuple(%iv_136) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_138 = cute.add_offset(%iter_100, %int_tuple_137) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %coord_139 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %227:2 = cute.get_scalars(%lay_92) <{only_dynamic}> : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %228 = cute.get_scalars(%coord_139) <{only_dynamic}> : !cute.coord<"?">
      %229 = arith.muli %227#1, %c16_i64 : i64
      %230 = arith.divsi %228, %c8_i32 : i32
      %231 = arith.remsi %228, %c8_i32 : i32
      %232 = arith.muli %231, %c8_i32 : i32
      %233 = arith.extsi %230 : i32 to i64
      %234 = arith.muli %233, %227#1 : i64
      %235 = arith.extsi %232 : i32 to i64
      %236 = arith.addi %235, %234 : i64
      %iv_140 = cute.assume(%236) : (i64) -> !cute.i64<divby 8>
      %int_tuple_141 = cute.make_int_tuple(%iv_140) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_142 = cute.add_offset(%ptr_94, %int_tuple_141) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_143 = cute.make_shape(%227#0) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %iv_144 = cute.assume(%229) : (i64) -> !cute.i64<divby 128>
      %stride_145 = cute.make_stride(%iv_144) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},0,64)">
      %lay_146 = cute.make_layout(%shape_143, %stride_145) : !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
      %coord_147 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %237 = cute.get_scalars(%coord_147) <{only_dynamic}> : !cute.coord<"?">
      %238 = arith.divsi %237, %c8_i32 : i32
      %239 = arith.remsi %237, %c8_i32 : i32
      %240 = arith.divsi %239, %c2_i32 : i32
      %241 = arith.muli %240, %c16_i32 : i32
      %242 = arith.muli %238, %c64_i32 : i32
      %243 = arith.addi %241, %242 : i32
      %244 = arith.remsi %237, %c8_i32 : i32
      %245 = arith.remsi %244, %c2_i32 : i32
      %246 = arith.muli %245, %c8_i32 : i32
      %247 = arith.andi %243, %c896_i32 : i32
      %248 = arith.shrsi %247, %c3_i32 : i32
      %249 = arith.xori %243, %248 : i32
      %250 = arith.addi %249, %246 : i32
      %iv_148 = cute.assume(%250) : (i32) -> !cute.i32<divby 8>
      %int_tuple_149 = cute.make_int_tuple(%iv_148) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_150 = cute.add_offset(%iter_101, %int_tuple_149) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_151 = cute.memref.alloca() : !memref_rmem_bf16_1
      %rmem_152 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_153 = cute.memref.alloca() : !memref_rmem_f32_
      cute.memref.store_vec %cst_2, %rmem_153 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_154 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_155 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %atom_156 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %251 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %252 = cute.make_tiled_copy(%atom_154) : !copy_ldsm_4_1
      %253 = cute.make_tiled_copy(%atom_155) : !copy_ldsm_4_2
      %254 = cute.make_tiled_copy(%atom_156) : !copy_ldsm_4_3
      %coord_157 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %255 = cute.get_scalars(%coord_157) <{only_dynamic}> : !cute.coord<"?">
      %256 = arith.remsi %255, %c16_i32 : i32
      %257 = arith.muli %256, %c64_i32 : i32
      %258 = arith.divsi %255, %c16_i32 : i32
      %259 = arith.divsi %258, %c2_i32 : i32
      %260 = arith.remsi %258, %c2_i32 : i32
      %261 = arith.muli %260, %c8_i32 : i32
      %262 = arith.muli %259, %c1024_i32 : i32
      %263 = arith.addi %261, %262 : i32
      %264 = arith.andi %257, %c128_i32 : i32
      %265 = arith.cmpi eq, %264, %c0_i32 : i32
      %266 = arith.select %265, %c16_i32, %c-16_i32 : i32
      %267 = arith.andi %257, %c256_i32 : i32
      %268 = arith.cmpi eq, %267, %c0_i32 : i32
      %269 = arith.select %268, %c32_i32, %c-32_i32 : i32
      %270 = arith.andi %257, %c896_i32 : i32
      %271 = arith.shrsi %270, %c3_i32 : i32
      %272 = arith.xori %257, %271 : i32
      %273 = arith.addi %272, %263 : i32
      %iv_158 = cute.assume(%273) : (i32) -> !cute.i32<divby 8>
      %int_tuple_159 = cute.make_int_tuple(%iv_158) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_160 = cute.add_offset(%iter_98, %int_tuple_159) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_161 = cute.assume(%266) : (i32) -> !cute.i32<divby 16>
      %iv_162 = cute.assume(%269) : (i32) -> !cute.i32<divby 32>
      %stride_163 = cute.make_stride(%iv_161, %iv_162) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,((?{div=16},?{div=32}),4096))">
      %lay_164 = cute.make_layout(%109, %stride_163) : !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
      %iter_165 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %coord_166 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %274 = cute.get_scalars(%coord_166) <{only_dynamic}> : !cute.coord<"?">
      %275 = arith.divsi %274, %c8_i32 : i32
      %276 = arith.remsi %274, %c8_i32 : i32
      %277 = arith.muli %276, %c64_i32 : i32
      %278 = arith.divsi %275, %c2_i32 : i32
      %279 = arith.remsi %278, %c2_i32 : i32
      %280 = arith.muli %279, %c512_i32 : i32
      %281 = arith.addi %277, %280 : i32
      %282 = arith.divsi %274, %c8_i32 : i32
      %283 = arith.remsi %282, %c2_i32 : i32
      %284 = arith.muli %283, %c8_i32 : i32
      %285 = arith.andi %281, %c128_i32 : i32
      %286 = arith.cmpi eq, %285, %c0_i32 : i32
      %287 = arith.select %286, %c16_i32, %c-16_i32 : i32
      %288 = arith.andi %281, %c256_i32 : i32
      %289 = arith.cmpi eq, %288, %c0_i32 : i32
      %290 = arith.select %289, %c32_i32, %c-32_i32 : i32
      %291 = arith.andi %281, %c896_i32 : i32
      %292 = arith.shrsi %291, %c3_i32 : i32
      %293 = arith.xori %281, %292 : i32
      %294 = arith.addi %293, %284 : i32
      %iv_167 = cute.assume(%294) : (i32) -> !cute.i32<divby 8>
      %int_tuple_168 = cute.make_int_tuple(%iv_167) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_169 = cute.add_offset(%iter_99, %int_tuple_168) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_170 = cute.assume(%287) : (i32) -> !cute.i32<divby 16>
      %iv_171 = cute.assume(%290) : (i32) -> !cute.i32<divby 32>
      %stride_172 = cute.make_stride(%iv_170, %iv_171) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_173 = cute.make_layout(%108, %stride_172) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %iter_174 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
      %coord_175 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %295 = cute.get_scalars(%coord_175) <{only_dynamic}> : !cute.coord<"?">
      %296 = arith.remsi %295, %c16_i32 : i32
      %297 = arith.muli %296, %c64_i32 : i32
      %298 = arith.divsi %295, %c16_i32 : i32
      %299 = arith.remsi %298, %c2_i32 : i32
      %300 = arith.muli %299, %c8_i32 : i32
      %301 = arith.andi %297, %c128_i32 : i32
      %302 = arith.cmpi eq, %301, %c0_i32 : i32
      %303 = arith.select %302, %c16_i32, %c-16_i32 : i32
      %304 = arith.andi %297, %c256_i32 : i32
      %305 = arith.cmpi eq, %304, %c0_i32 : i32
      %306 = arith.select %305, %c32_i32, %c-32_i32 : i32
      %307 = arith.andi %297, %c896_i32 : i32
      %308 = arith.shrsi %307, %c3_i32 : i32
      %309 = arith.xori %297, %308 : i32
      %310 = arith.addi %309, %300 : i32
      %iv_176 = cute.assume(%310) : (i32) -> !cute.i32<divby 8>
      %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_178 = cute.add_offset(%iter_100, %int_tuple_177) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_179 = cute.assume(%303) : (i32) -> !cute.i32<divby 16>
      %iv_180 = cute.assume(%306) : (i32) -> !cute.i32<divby 32>
      %stride_181 = cute.make_stride(%iv_179, %iv_180) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_182 = cute.make_layout(%107, %stride_181) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iter_183 = cute.get_iter(%rmem_152) : !memref_rmem_bf16_2
      %coord_184 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %311 = cute.get_scalars(%coord_184) <{only_dynamic}> : !cute.coord<"?">
      %312 = arith.remsi %311, %c16_i32 : i32
      %313 = arith.muli %312, %c64_i32 : i32
      %314 = arith.divsi %311, %c16_i32 : i32
      %315 = arith.divsi %314, %c2_i32 : i32
      %316 = arith.remsi %314, %c2_i32 : i32
      %317 = arith.muli %316, %c8_i32 : i32
      %318 = arith.muli %315, %c1024_i32 : i32
      %319 = arith.addi %317, %318 : i32
      %320 = arith.andi %313, %c128_i32 : i32
      %321 = arith.cmpi eq, %320, %c0_i32 : i32
      %322 = arith.select %321, %c16_i32, %c-16_i32 : i32
      %323 = arith.andi %313, %c256_i32 : i32
      %324 = arith.cmpi eq, %323, %c0_i32 : i32
      %325 = arith.select %324, %c32_i32, %c-32_i32 : i32
      %326 = arith.andi %313, %c896_i32 : i32
      %327 = arith.shrsi %326, %c3_i32 : i32
      %328 = arith.xori %313, %327 : i32
      %329 = arith.addi %328, %319 : i32
      %iv_185 = cute.assume(%329) : (i32) -> !cute.i32<divby 8>
      %int_tuple_186 = cute.make_int_tuple(%iv_185) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_187 = cute.add_offset(%iter_101, %int_tuple_186) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_188 = cute.assume(%322) : (i32) -> !cute.i32<divby 16>
      %iv_189 = cute.assume(%325) : (i32) -> !cute.i32<divby 32>
      %stride_190 = cute.make_stride(%iv_188, %iv_189) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_191 = cute.make_layout(%106, %stride_190) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %lay_192 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %330 = cute.get_shape(%lay_192) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_193, %e1_194, %e2_195, %e3_196 = cute.get_leaves(%330) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_197 = cute.to_int_tuple(%e0_193) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_198 = cute.to_int_tuple(%e1_194) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_199 = cute.to_int_tuple(%e2_195) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_200 = cute.to_int_tuple(%e3_196) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_201 = cute.make_shape(%itup_197, %itup_198, %itup_199, %itup_200) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_202 = cute.make_layout(%shape_201, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %lay_203 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %331 = cute.get_shape(%lay_203) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_204, %e1_205, %e2_206, %e3_207 = cute.get_leaves(%331) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_208 = cute.to_int_tuple(%e0_204) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_209 = cute.to_int_tuple(%e1_205) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_210 = cute.to_int_tuple(%e2_206) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_211 = cute.to_int_tuple(%e3_207) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_212 = cute.make_shape(%itup_208, %itup_209, %itup_210, %itup_211) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_213 = cute.make_layout(%shape_212, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %lay_214 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %332 = cute.get_shape(%lay_214) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_215, %e1_216, %e2_217, %e3_218 = cute.get_leaves(%332) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_219 = cute.to_int_tuple(%e0_215) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_220 = cute.to_int_tuple(%e1_216) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_221 = cute.to_int_tuple(%e2_217) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_222 = cute.to_int_tuple(%e3_218) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_223 = cute.make_shape(%itup_219, %itup_220, %itup_221, %itup_222) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_224 = cute.make_layout(%shape_223, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %coord_225 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %333:4 = cute.get_scalars(%lay_202) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_226 = cute.assume(%333#3) : (i32) -> !cute.i32<divby 8>
      %shape_227 = cute.make_shape(%333#1, %iv_226) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_228 = cute.make_layout(%shape_227, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_229 = cute.crd2idx(%coord_225, %lay_202) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup = cute.add_offset(%105, %idx_229) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_230 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %334 = cute.get_scalars(%coord_230) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_231 = cute.make_coord(%334) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %335:2 = cute.get_scalars(%lay_228) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %336 = arith.ceildivsi %335#0, %c64_i32 : i32
      %337 = arith.ceildivsi %335#1, %c128_i32 : i32
      %shape_232 = cute.make_shape(%336, %337) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_233 = cute.make_layout(%shape_232, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_234 = cute.crd2idx(%coord_231, %lay_233) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_235 = cute.add_offset(%tup, %idx_234) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %coord_236 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %338:4 = cute.get_scalars(%lay_213) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_237 = cute.assume(%338#3) : (i32) -> !cute.i32<divby 8>
      %shape_238 = cute.make_shape(%338#1, %iv_237) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_239 = cute.make_layout(%shape_238, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_240 = cute.crd2idx(%coord_236, %lay_213) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_241 = cute.add_offset(%105, %idx_240) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_242 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %339 = cute.get_scalars(%coord_242) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_243 = cute.make_coord(%339) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %340:2 = cute.get_scalars(%lay_239) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %341 = arith.ceildivsi %340#0, %c64_i32 : i32
      %342 = arith.ceildivsi %340#1, %c128_i32 : i32
      %shape_244 = cute.make_shape(%341, %342) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_245 = cute.make_layout(%shape_244, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_246 = cute.crd2idx(%coord_243, %lay_245) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_247 = cute.add_offset(%tup_241, %idx_246) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %coord_248 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %343:4 = cute.get_scalars(%lay_224) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_249 = cute.assume(%343#3) : (i32) -> !cute.i32<divby 8>
      %shape_250 = cute.make_shape(%343#2, %iv_249) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_251 = cute.make_layout(%shape_250, %101) : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %idx_252 = cute.crd2idx(%coord_248, %lay_224) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,?,0,0)">
      %tup_253 = cute.add_offset(%105, %idx_252) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,?,0,0)">) -> !cute.int_tuple<"(?,?,0,0)">
      %coord_254 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %344 = cute.get_scalars(%coord_254) <{only_dynamic}> : !cute.coord<"(?,_)">
      %coord_255 = cute.make_coord(%344) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %345:2 = cute.get_scalars(%lay_251) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %346 = arith.ceildivsi %345#0, %c64_i32 : i32
      %347 = arith.ceildivsi %345#1, %c64_i32 : i32
      %shape_256 = cute.make_shape(%346, %347) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %lay_257 = cute.make_layout(%shape_256, %100) : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %348:2 = cute.get_scalars(%lay_257) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %shape_258 = cute.make_shape(%348#1) : (i32) -> !cute.shape<"(64,64,?)">
      %lay_259 = cute.make_layout(%shape_258, %99) : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %idx_260 = cute.crd2idx(%coord_255, %lay_257) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">) -> !cute.int_tuple<"(0,0,?{div=64},0)">
      %tup_261 = cute.add_offset(%tup_253, %idx_260) : (!cute.int_tuple<"(?,?,0,0)">, !cute.int_tuple<"(0,0,?{div=64},0)">) -> !cute.int_tuple<"(?,?,?{div=64},0)">
      %coord_262 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %349 = cute.get_scalars(%coord_262) <{only_dynamic}> : !cute.coord<"?">
      %350 = arith.divsi %349, %c8_i32 : i32
      %351 = arith.remsi %349, %c8_i32 : i32
      %352 = arith.muli %351, %c8_i32 : i32
      %iv_263 = cute.assume(%352) : (i32) -> !cute.i32<divby 8>
      %int_tuple_264 = cute.make_int_tuple(%350, %iv_263) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_265 = cute.add_offset(%tup_235, %int_tuple_264) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_266 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %353 = cute.get_scalars(%coord_266) <{only_dynamic}> : !cute.coord<"?">
      %354 = arith.divsi %353, %c8_i32 : i32
      %355 = arith.remsi %353, %c8_i32 : i32
      %356 = arith.muli %355, %c8_i32 : i32
      %iv_267 = cute.assume(%356) : (i32) -> !cute.i32<divby 8>
      %int_tuple_268 = cute.make_int_tuple(%354, %iv_267) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_269 = cute.add_offset(%tup_247, %int_tuple_268) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_270 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %357 = cute.get_scalars(%lay_259) <{only_dynamic}> : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %358 = cute.get_scalars(%coord_270) <{only_dynamic}> : !cute.coord<"?">
      %359 = arith.divsi %358, %c8_i32 : i32
      %360 = arith.remsi %358, %c8_i32 : i32
      %361 = arith.muli %360, %c8_i32 : i32
      %iv_271 = cute.assume(%361) : (i32) -> !cute.i32<divby 8>
      %int_tuple_272 = cute.make_int_tuple(%359, %iv_271) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,0,?,?{div=8})">
      %tup_273 = cute.add_offset(%tup_261, %int_tuple_272) : (!cute.int_tuple<"(?,?,?{div=64},0)">, !cute.int_tuple<"(0,0,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %shape_274 = cute.make_shape(%357) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %lay_275 = cute.make_layout(%shape_274, %98) : !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %rmem_276 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_277 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_278, %e1_279, %e2_280, %e3_281 = cute.get_leaves(%tup_265) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_282 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %362 = cute.get_shape(%lay_282) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_283, %e1_284, %e2_285, %e3_286 = cute.get_leaves(%362) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_287 = cute.to_int_tuple(%e3_286) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_288 = cute.make_coord(%e3_281) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_289 = cute.make_coord(%itup_287) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %363 = cute.get_scalars(%coord_288) : !cute.coord<"?{div=8}">
      %364 = cute.get_scalars(%coord_289) : !cute.coord<"?{div=8}">
      %365 = arith.cmpi slt, %363, %364 : i32
      %366 = arith.extui %365 : i1 to i8
      cute.memref.store(%rmem_276, %97, %366) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_290 = cute.add_offset(%tup_265, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_291, %e1_292, %e2_293, %e3_294 = cute.get_leaves(%tup_290) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_295 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %367 = cute.get_shape(%lay_295) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_296, %e1_297, %e2_298, %e3_299 = cute.get_leaves(%367) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_300 = cute.to_int_tuple(%e3_299) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_301 = cute.make_coord(%e3_294) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_302 = cute.make_coord(%itup_300) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %368 = cute.get_scalars(%coord_301) : !cute.coord<"?{div=8}">
      %369 = cute.get_scalars(%coord_302) : !cute.coord<"?{div=8}">
      %370 = arith.cmpi slt, %368, %369 : i32
      %371 = arith.extui %370 : i1 to i8
      cute.memref.store(%rmem_276, %95, %371) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_303, %e1_304, %e2_305, %e3_306 = cute.get_leaves(%tup_269) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_307 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %372 = cute.get_shape(%lay_307) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_308, %e1_309, %e2_310, %e3_311 = cute.get_leaves(%372) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_312 = cute.to_int_tuple(%e3_311) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_313 = cute.make_coord(%e3_306) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_314 = cute.make_coord(%itup_312) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %373 = cute.get_scalars(%coord_313) : !cute.coord<"?{div=8}">
      %374 = cute.get_scalars(%coord_314) : !cute.coord<"?{div=8}">
      %375 = arith.cmpi slt, %373, %374 : i32
      %376 = arith.extui %375 : i1 to i8
      cute.memref.store(%rmem_277, %97, %376) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_315 = cute.add_offset(%tup_269, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_316, %e1_317, %e2_318, %e3_319 = cute.get_leaves(%tup_315) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_320 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %377 = cute.get_shape(%lay_320) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_321, %e1_322, %e2_323, %e3_324 = cute.get_leaves(%377) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_325 = cute.to_int_tuple(%e3_324) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_326 = cute.make_coord(%e3_319) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_327 = cute.make_coord(%itup_325) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %378 = cute.get_scalars(%coord_326) : !cute.coord<"?{div=8}">
      %379 = cute.get_scalars(%coord_327) : !cute.coord<"?{div=8}">
      %380 = arith.cmpi slt, %378, %379 : i32
      %381 = arith.extui %380 : i1 to i8
      cute.memref.store(%rmem_277, %95, %381) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_328, %e1_329, %e2_330, %e3_331 = cute.get_leaves(%tup_265) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_332 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %382 = cute.get_shape(%lay_332) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_333, %e1_334, %e2_335, %e3_336 = cute.get_leaves(%382) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_337 = cute.to_int_tuple(%e1_334) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_338 = cute.make_coord(%e1_329) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_339 = cute.make_coord(%itup_337) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %383 = cute.get_scalars(%coord_338) : !cute.coord<"?">
      %384 = cute.get_scalars(%coord_339) : !cute.coord<"?">
      %385 = arith.cmpi slt, %383, %384 : i32
      scf.if %385 {
        %iter_698 = cute.get_iter(%rmem_276) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_699 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_700 = cute.crd2idx(%coord_699, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_701 = cute.add_offset(%ptr_105, %idx_700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_702 = cute.crd2idx(%coord_699, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_703 = cute.add_offset(%ptr_112, %idx_702) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_704 = cute.crd2idx(%coord_699, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_705 = cute.add_offset(%iter_698, %idx_704) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_706 = cute.recast_iter(%ptr_701) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_707 = cute.recast_iter(%ptr_703) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_707 : !cute.ptr<i128, smem>, %iter_706 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_112) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_340 = cute.add_offset(%tup_265, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_341, %e1_342, %e2_343, %e3_344 = cute.get_leaves(%tup_340) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_345 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %386 = cute.get_shape(%lay_345) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_346, %e1_347, %e2_348, %e3_349 = cute.get_leaves(%386) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_350 = cute.to_int_tuple(%e1_347) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_351 = cute.make_coord(%e1_342) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_352 = cute.make_coord(%itup_350) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %387 = cute.get_scalars(%coord_351) : !cute.coord<"?">
      %388 = cute.get_scalars(%coord_352) : !cute.coord<"?">
      %389 = arith.cmpi slt, %387, %388 : i32
      scf.if %389 {
        %idx_698 = cute.crd2idx(%89, %lay_108) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_699 = cute.add_offset(%ptr_105, %idx_698) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_700 = cute.add_offset(%ptr_112, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_701 = cute.get_iter(%rmem_276) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_702 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_703 = cute.crd2idx(%coord_702, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_704 = cute.add_offset(%ptr_699, %idx_703) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_705 = cute.crd2idx(%coord_702, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_706 = cute.add_offset(%ptr_700, %idx_705) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_707 = cute.crd2idx(%coord_702, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_708 = cute.add_offset(%iter_701, %idx_707) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_709 = cute.recast_iter(%ptr_704) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_710 = cute.recast_iter(%ptr_706) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_710 : !cute.ptr<i128, smem>, %iter_709 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_112, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_353 = cute.add_offset(%tup_265, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_354, %e1_355, %e2_356, %e3_357 = cute.get_leaves(%tup_353) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_358 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %390 = cute.get_shape(%lay_358) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_359, %e1_360, %e2_361, %e3_362 = cute.get_leaves(%390) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_363 = cute.to_int_tuple(%e1_360) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_364 = cute.make_coord(%e1_355) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_365 = cute.make_coord(%itup_363) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %391 = cute.get_scalars(%coord_364) : !cute.coord<"?">
      %392 = cute.get_scalars(%coord_365) : !cute.coord<"?">
      %393 = arith.cmpi slt, %391, %392 : i32
      scf.if %393 {
        %idx_698 = cute.crd2idx(%86, %lay_108) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_699 = cute.add_offset(%ptr_105, %idx_698) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_700 = cute.add_offset(%ptr_112, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_701 = cute.get_iter(%rmem_276) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_702 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_703 = cute.crd2idx(%coord_702, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_704 = cute.add_offset(%ptr_699, %idx_703) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_705 = cute.crd2idx(%coord_702, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_706 = cute.add_offset(%ptr_700, %idx_705) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_707 = cute.crd2idx(%coord_702, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_708 = cute.add_offset(%iter_701, %idx_707) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_709 = cute.recast_iter(%ptr_704) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_710 = cute.recast_iter(%ptr_706) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_710 : !cute.ptr<i128, smem>, %iter_709 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_112, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_366 = cute.add_offset(%tup_265, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_367, %e1_368, %e2_369, %e3_370 = cute.get_leaves(%tup_366) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_371 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %394 = cute.get_shape(%lay_371) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_372, %e1_373, %e2_374, %e3_375 = cute.get_leaves(%394) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_376 = cute.to_int_tuple(%e1_373) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_377 = cute.make_coord(%e1_368) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_378 = cute.make_coord(%itup_376) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %395 = cute.get_scalars(%coord_377) : !cute.coord<"?">
      %396 = cute.get_scalars(%coord_378) : !cute.coord<"?">
      %397 = arith.cmpi slt, %395, %396 : i32
      scf.if %397 {
        %idx_698 = cute.crd2idx(%83, %lay_108) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_699 = cute.add_offset(%ptr_105, %idx_698) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_700 = cute.add_offset(%ptr_112, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_701 = cute.get_iter(%rmem_276) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_702 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_703 = cute.crd2idx(%coord_702, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_704 = cute.add_offset(%ptr_699, %idx_703) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_705 = cute.crd2idx(%coord_702, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_706 = cute.add_offset(%ptr_700, %idx_705) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_707 = cute.crd2idx(%coord_702, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_708 = cute.add_offset(%iter_701, %idx_707) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_709 = cute.recast_iter(%ptr_704) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_710 = cute.recast_iter(%ptr_706) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_710 : !cute.ptr<i128, smem>, %iter_709 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_112, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %e0_379, %e1_380, %e2_381, %e3_382 = cute.get_leaves(%tup_269) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_383 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %398 = cute.get_shape(%lay_383) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_384, %e1_385, %e2_386, %e3_387 = cute.get_leaves(%398) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_388 = cute.to_int_tuple(%e1_385) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_389 = cute.make_coord(%e1_380) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_390 = cute.make_coord(%itup_388) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %399 = cute.get_scalars(%coord_389) : !cute.coord<"?">
      %400 = cute.get_scalars(%coord_390) : !cute.coord<"?">
      %401 = arith.cmpi slt, %399, %400 : i32
      scf.if %401 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_121) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %ptr_700 = cute.add_offset(%ptr_116, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_701 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_702 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_703 = cute.crd2idx(%coord_702, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_704 = cute.add_offset(%ptr_700, %idx_703) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_705 = cute.crd2idx(%coord_702, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_706 = cute.add_offset(%ptr_125, %idx_705) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_707 = cute.crd2idx(%coord_702, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_708 = cute.add_offset(%iter_701, %idx_707) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_709 = cute.recast_iter(%ptr_704) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_710 = cute.recast_iter(%ptr_706) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_710 : !cute.ptr<i128, smem>, %iter_709 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_125) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_391 = cute.add_offset(%tup_269, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_392, %e1_393, %e2_394, %e3_395 = cute.get_leaves(%tup_391) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_396 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %402 = cute.get_shape(%lay_396) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_397, %e1_398, %e2_399, %e3_400 = cute.get_leaves(%402) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_401 = cute.to_int_tuple(%e1_398) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_402 = cute.make_coord(%e1_393) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_403 = cute.make_coord(%itup_401) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %403 = cute.get_scalars(%coord_402) : !cute.coord<"?">
      %404 = cute.get_scalars(%coord_403) : !cute.coord<"?">
      %405 = arith.cmpi slt, %403, %404 : i32
      scf.if %405 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_121) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_700 = cute.add_offset(%ptr_116, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_702 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_705 = cute.add_offset(%ptr_700, %idx_704) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_710 = cute.recast_iter(%ptr_705) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_711 = cute.recast_iter(%ptr_707) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_711 : !cute.ptr<i128, smem>, %iter_710 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_404 = cute.add_offset(%tup_269, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_405, %e1_406, %e2_407, %e3_408 = cute.get_leaves(%tup_404) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_409 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %406 = cute.get_shape(%lay_409) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_410, %e1_411, %e2_412, %e3_413 = cute.get_leaves(%406) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_414 = cute.to_int_tuple(%e1_411) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_415 = cute.make_coord(%e1_406) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_416 = cute.make_coord(%itup_414) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %407 = cute.get_scalars(%coord_415) : !cute.coord<"?">
      %408 = cute.get_scalars(%coord_416) : !cute.coord<"?">
      %409 = arith.cmpi slt, %407, %408 : i32
      scf.if %409 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_121) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_700 = cute.add_offset(%ptr_116, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_702 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_705 = cute.add_offset(%ptr_700, %idx_704) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_710 = cute.recast_iter(%ptr_705) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_711 = cute.recast_iter(%ptr_707) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_711 : !cute.ptr<i128, smem>, %iter_710 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_417 = cute.add_offset(%tup_269, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_418, %e1_419, %e2_420, %e3_421 = cute.get_leaves(%tup_417) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_422 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %410 = cute.get_shape(%lay_422) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_423, %e1_424, %e2_425, %e3_426 = cute.get_leaves(%410) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_427 = cute.to_int_tuple(%e1_424) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_428 = cute.make_coord(%e1_419) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_429 = cute.make_coord(%itup_427) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %411 = cute.get_scalars(%coord_428) : !cute.coord<"?">
      %412 = cute.get_scalars(%coord_429) : !cute.coord<"?">
      %413 = arith.cmpi slt, %411, %412 : i32
      scf.if %413 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_121) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_700 = cute.add_offset(%ptr_116, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_702 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_705 = cute.add_offset(%ptr_700, %idx_704) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.trunc %538 : i8 to i1
          %iter_710 = cute.recast_iter(%ptr_705) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_711 = cute.recast_iter(%ptr_707) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_711 : !cute.ptr<i128, smem>, %iter_710 : !cute.ptr<i128, gmem>, %539 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %coord_430 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %idx_431 = cute.crd2idx(%coord_430, %lay_275) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %tup_432 = cute.add_offset(%tup_273, %idx_431) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_433, %e1_434, %e2_435, %e3_436 = cute.get_leaves(%tup_432) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_437 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %414 = cute.get_shape(%lay_437) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_438, %e1_439, %e2_440, %e3_441 = cute.get_leaves(%414) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_442 = cute.to_int_tuple(%e2_440) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_443 = cute.make_coord(%e1_434) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_444 = cute.make_coord(%itup_442) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %415 = cute.get_scalars(%coord_443) : !cute.coord<"?">
      %416 = cute.get_scalars(%coord_444) : !cute.coord<"?">
      %417 = arith.cmpi slt, %415, %416 : i32
      %coord_445 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %idx_446 = cute.crd2idx(%coord_445, %lay_275) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %tup_447 = cute.add_offset(%tup_273, %idx_446) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_448, %e1_449, %e2_450, %e3_451 = cute.get_leaves(%tup_447) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_452 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %418 = cute.get_shape(%lay_452) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_453, %e1_454, %e2_455, %e3_456 = cute.get_leaves(%418) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_457 = cute.to_int_tuple(%e3_456) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_458 = cute.make_coord(%e2_450) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_459 = cute.make_coord(%itup_457) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %419 = cute.get_scalars(%coord_458) : !cute.coord<"?">
      %420 = cute.get_scalars(%coord_459) : !cute.coord<"?{div=8}">
      %421 = arith.cmpi slt, %419, %420 : i32
      %422 = arith.extui %417 : i1 to i32
      %423 = arith.extui %421 : i1 to i32
      %424 = arith.select %417, %423, %422 : i32
      %425 = arith.cmpi ne, %424, %c0_i32 : i32
      scf.if %425 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_146) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
        %ptr_700 = cute.add_offset(%ptr_142, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %536 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %iter_701 = cute.recast_iter(%ptr_700) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_702 = cute.recast_iter(%ptr_150) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_702 : !cute.ptr<i128, smem>, %iter_701 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_150) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_460 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %idx_461 = cute.crd2idx(%coord_460, %lay_275) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %tup_462 = cute.add_offset(%tup_273, %idx_461) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_463, %e1_464, %e2_465, %e3_466 = cute.get_leaves(%tup_462) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_467 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %426 = cute.get_shape(%lay_467) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_468, %e1_469, %e2_470, %e3_471 = cute.get_leaves(%426) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_472 = cute.to_int_tuple(%e2_470) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_473 = cute.make_coord(%e1_464) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_474 = cute.make_coord(%itup_472) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %427 = cute.get_scalars(%coord_473) : !cute.coord<"?">
      %428 = cute.get_scalars(%coord_474) : !cute.coord<"?">
      %429 = arith.cmpi slt, %427, %428 : i32
      %coord_475 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %idx_476 = cute.crd2idx(%coord_475, %lay_275) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %tup_477 = cute.add_offset(%tup_273, %idx_476) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_478, %e1_479, %e2_480, %e3_481 = cute.get_leaves(%tup_477) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_482 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %430 = cute.get_shape(%lay_482) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_483, %e1_484, %e2_485, %e3_486 = cute.get_leaves(%430) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_487 = cute.to_int_tuple(%e3_486) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_488 = cute.make_coord(%e2_480) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_489 = cute.make_coord(%itup_487) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %431 = cute.get_scalars(%coord_488) : !cute.coord<"?">
      %432 = cute.get_scalars(%coord_489) : !cute.coord<"?{div=8}">
      %433 = arith.cmpi slt, %431, %432 : i32
      %434 = arith.extui %429 : i1 to i32
      %435 = arith.extui %433 : i1 to i32
      %436 = arith.select %429, %435, %434 : i32
      %437 = arith.cmpi ne, %436, %c0_i32 : i32
      scf.if %437 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_146) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_700 = cute.add_offset(%ptr_142, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_150, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %536 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %iter_702 = cute.recast_iter(%ptr_700) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_703 = cute.recast_iter(%ptr_701) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_703 : !cute.ptr<i128, smem>, %iter_702 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_150, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_490 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %idx_491 = cute.crd2idx(%coord_490, %lay_275) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %tup_492 = cute.add_offset(%tup_273, %idx_491) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_493, %e1_494, %e2_495, %e3_496 = cute.get_leaves(%tup_492) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_497 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %438 = cute.get_shape(%lay_497) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_498, %e1_499, %e2_500, %e3_501 = cute.get_leaves(%438) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_502 = cute.to_int_tuple(%e2_500) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_503 = cute.make_coord(%e1_494) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_504 = cute.make_coord(%itup_502) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %439 = cute.get_scalars(%coord_503) : !cute.coord<"?">
      %440 = cute.get_scalars(%coord_504) : !cute.coord<"?">
      %441 = arith.cmpi slt, %439, %440 : i32
      %coord_505 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %idx_506 = cute.crd2idx(%coord_505, %lay_275) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %tup_507 = cute.add_offset(%tup_273, %idx_506) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_508, %e1_509, %e2_510, %e3_511 = cute.get_leaves(%tup_507) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_512 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %442 = cute.get_shape(%lay_512) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_513, %e1_514, %e2_515, %e3_516 = cute.get_leaves(%442) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_517 = cute.to_int_tuple(%e3_516) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_518 = cute.make_coord(%e2_510) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_519 = cute.make_coord(%itup_517) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %443 = cute.get_scalars(%coord_518) : !cute.coord<"?">
      %444 = cute.get_scalars(%coord_519) : !cute.coord<"?{div=8}">
      %445 = arith.cmpi slt, %443, %444 : i32
      %446 = arith.extui %441 : i1 to i32
      %447 = arith.extui %445 : i1 to i32
      %448 = arith.select %441, %447, %446 : i32
      %449 = arith.cmpi ne, %448, %c0_i32 : i32
      scf.if %449 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_146) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_700 = cute.add_offset(%ptr_142, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_150, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %536 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %iter_702 = cute.recast_iter(%ptr_700) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_703 = cute.recast_iter(%ptr_701) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_703 : !cute.ptr<i128, smem>, %iter_702 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_150, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_520 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %idx_521 = cute.crd2idx(%coord_520, %lay_275) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %tup_522 = cute.add_offset(%tup_273, %idx_521) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_523, %e1_524, %e2_525, %e3_526 = cute.get_leaves(%tup_522) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_527 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %450 = cute.get_shape(%lay_527) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_528, %e1_529, %e2_530, %e3_531 = cute.get_leaves(%450) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_532 = cute.to_int_tuple(%e2_530) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_533 = cute.make_coord(%e1_524) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_534 = cute.make_coord(%itup_532) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %451 = cute.get_scalars(%coord_533) : !cute.coord<"?">
      %452 = cute.get_scalars(%coord_534) : !cute.coord<"?">
      %453 = arith.cmpi slt, %451, %452 : i32
      %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %idx_536 = cute.crd2idx(%coord_535, %lay_275) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %tup_537 = cute.add_offset(%tup_273, %idx_536) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_538, %e1_539, %e2_540, %e3_541 = cute.get_leaves(%tup_537) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_542 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %454 = cute.get_shape(%lay_542) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_543, %e1_544, %e2_545, %e3_546 = cute.get_leaves(%454) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_547 = cute.to_int_tuple(%e3_546) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_548 = cute.make_coord(%e2_540) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_549 = cute.make_coord(%itup_547) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %455 = cute.get_scalars(%coord_548) : !cute.coord<"?">
      %456 = cute.get_scalars(%coord_549) : !cute.coord<"?{div=8}">
      %457 = arith.cmpi slt, %455, %456 : i32
      %458 = arith.extui %453 : i1 to i32
      %459 = arith.extui %457 : i1 to i32
      %460 = arith.select %453, %459, %458 : i32
      %461 = arith.cmpi ne, %460, %c0_i32 : i32
      scf.if %461 {
        %coord_698 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %idx_699 = cute.crd2idx(%coord_698, %lay_146) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_700 = cute.add_offset(%ptr_142, %idx_699) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_701 = cute.add_offset(%ptr_150, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %536 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %iter_702 = cute.recast_iter(%ptr_700) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_703 = cute.recast_iter(%ptr_701) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_703 : !cute.ptr<i128, smem>, %iter_702 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_698 = cute.add_offset(%ptr_150, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_698) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      nvvm.cp.async.commit.group
      %tup_550 = cute.add_offset(%sub_16, %81) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      scf.for %arg5 = %c-1_i32 to %128 step %c1_i32  : i32 {
        %int_tuple_698 = cute.make_int_tuple(%arg5) : (i32) -> !cute.int_tuple<"?">
        %sub_699 = cute.tuple_sub(%tup_550, %int_tuple_698) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %536 = cute.get_scalars(%sub_699) : !cute.int_tuple<"?">
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %537 = arith.cmpi eq, %536, %128 : i32
        scf.if %537 {
          %e0_872, %e1_873, %e2_874, %e3_875 = cute.get_leaves(%tup_269) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_876 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %684 = cute.get_shape(%lay_876) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_877, %e1_878, %e2_879, %e3_880 = cute.get_leaves(%684) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_881 = cute.to_int_tuple(%e1_878) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_882 = cute.make_coord(%e1_873) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_883 = cute.make_coord(%itup_881) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %685 = cute.get_scalars(%coord_882) : !cute.coord<"?">
          %686 = cute.get_scalars(%coord_883) : !cute.coord<"?">
          %687 = arith.cmpi slt, %685, %686 : i32
          scf.if %687 {
            %coord_923 = cute.make_coord(%sub_699) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_924 = cute.crd2idx(%coord_923, %lay_134) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
            %ptr_925 = cute.add_offset(%ptr_129, %idx_924) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
            %iter_926 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
            %700 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %700 step %c1_i32  : i32 {
              %coord_927 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_928 = cute.crd2idx(%coord_927, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_929 = cute.add_offset(%ptr_925, %idx_928) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_930 = cute.crd2idx(%coord_927, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_931 = cute.add_offset(%ptr_138, %idx_930) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_932 = cute.crd2idx(%coord_927, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_933 = cute.add_offset(%iter_926, %idx_932) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %701 = builtin.unrealized_conversion_cast %ptr_933 : !cute.ptr<i8, rmem> to !llvm.ptr
              %702 = llvm.load %701 : !llvm.ptr -> i8
              %703 = llvm.trunc %702 : i8 to i1
              %iter_934 = cute.recast_iter(%ptr_929) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_935 = cute.recast_iter(%ptr_931) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_935 : !cute.ptr<i128, smem>, %iter_934 : !cute.ptr<i128, gmem>, %703 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_138) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %tup_884 = cute.add_offset(%tup_269, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_885, %e1_886, %e2_887, %e3_888 = cute.get_leaves(%tup_884) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_889 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %688 = cute.get_shape(%lay_889) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_890, %e1_891, %e2_892, %e3_893 = cute.get_leaves(%688) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_894 = cute.to_int_tuple(%e1_891) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_895 = cute.make_coord(%e1_886) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_896 = cute.make_coord(%itup_894) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %689 = cute.get_scalars(%coord_895) : !cute.coord<"?">
          %690 = cute.get_scalars(%coord_896) : !cute.coord<"?">
          %691 = arith.cmpi slt, %689, %690 : i32
          scf.if %691 {
            %coord_923 = cute.make_coord(%sub_699) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_924 = cute.crd2idx(%coord_923, %lay_134) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_925 = cute.add_offset(%ptr_129, %idx_924) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_926 = cute.add_offset(%ptr_138, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_927 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
            %700 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %700 step %c1_i32  : i32 {
              %coord_928 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_929 = cute.crd2idx(%coord_928, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_930 = cute.add_offset(%ptr_925, %idx_929) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_931 = cute.crd2idx(%coord_928, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_932 = cute.add_offset(%ptr_926, %idx_931) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_933 = cute.crd2idx(%coord_928, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_934 = cute.add_offset(%iter_927, %idx_933) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %701 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<i8, rmem> to !llvm.ptr
              %702 = llvm.load %701 : !llvm.ptr -> i8
              %703 = llvm.trunc %702 : i8 to i1
              %iter_935 = cute.recast_iter(%ptr_930) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_936 = cute.recast_iter(%ptr_932) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_936 : !cute.ptr<i128, smem>, %iter_935 : !cute.ptr<i128, gmem>, %703 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_923 = cute.add_offset(%ptr_138, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_923) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %tup_897 = cute.add_offset(%tup_269, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_898, %e1_899, %e2_900, %e3_901 = cute.get_leaves(%tup_897) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_902 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %692 = cute.get_shape(%lay_902) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_903, %e1_904, %e2_905, %e3_906 = cute.get_leaves(%692) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_907 = cute.to_int_tuple(%e1_904) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_908 = cute.make_coord(%e1_899) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_909 = cute.make_coord(%itup_907) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %693 = cute.get_scalars(%coord_908) : !cute.coord<"?">
          %694 = cute.get_scalars(%coord_909) : !cute.coord<"?">
          %695 = arith.cmpi slt, %693, %694 : i32
          scf.if %695 {
            %coord_923 = cute.make_coord(%sub_699) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_924 = cute.crd2idx(%coord_923, %lay_134) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
            %ptr_925 = cute.add_offset(%ptr_129, %idx_924) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_926 = cute.add_offset(%ptr_138, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_927 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
            %700 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %700 step %c1_i32  : i32 {
              %coord_928 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_929 = cute.crd2idx(%coord_928, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_930 = cute.add_offset(%ptr_925, %idx_929) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_931 = cute.crd2idx(%coord_928, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_932 = cute.add_offset(%ptr_926, %idx_931) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_933 = cute.crd2idx(%coord_928, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_934 = cute.add_offset(%iter_927, %idx_933) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %701 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<i8, rmem> to !llvm.ptr
              %702 = llvm.load %701 : !llvm.ptr -> i8
              %703 = llvm.trunc %702 : i8 to i1
              %iter_935 = cute.recast_iter(%ptr_930) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_936 = cute.recast_iter(%ptr_932) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_936 : !cute.ptr<i128, smem>, %iter_935 : !cute.ptr<i128, gmem>, %703 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_923 = cute.add_offset(%ptr_138, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_923) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %tup_910 = cute.add_offset(%tup_269, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_911, %e1_912, %e2_913, %e3_914 = cute.get_leaves(%tup_910) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_915 = cute.get_layout(%arg2) : !memref_gmem_bf16_
          %696 = cute.get_shape(%lay_915) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_916, %e1_917, %e2_918, %e3_919 = cute.get_leaves(%696) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_920 = cute.to_int_tuple(%e1_917) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_921 = cute.make_coord(%e1_912) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_922 = cute.make_coord(%itup_920) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %697 = cute.get_scalars(%coord_921) : !cute.coord<"?">
          %698 = cute.get_scalars(%coord_922) : !cute.coord<"?">
          %699 = arith.cmpi slt, %697, %698 : i32
          scf.if %699 {
            %coord_923 = cute.make_coord(%sub_699) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_924 = cute.crd2idx(%coord_923, %lay_134) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_925 = cute.add_offset(%ptr_129, %idx_924) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_926 = cute.add_offset(%ptr_138, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_927 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
            %700 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %700 step %c1_i32  : i32 {
              %coord_928 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_929 = cute.crd2idx(%coord_928, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_930 = cute.add_offset(%ptr_925, %idx_929) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_931 = cute.crd2idx(%coord_928, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_932 = cute.add_offset(%ptr_926, %idx_931) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_933 = cute.crd2idx(%coord_928, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_934 = cute.add_offset(%iter_927, %idx_933) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %701 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<i8, rmem> to !llvm.ptr
              %702 = llvm.load %701 : !llvm.ptr -> i8
              %703 = llvm.trunc %702 : i8 to i1
              %iter_935 = cute.recast_iter(%ptr_930) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_936 = cute.recast_iter(%ptr_932) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_936 : !cute.ptr<i128, smem>, %iter_935 : !cute.ptr<i128, gmem>, %703 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_923 = cute.add_offset(%ptr_138, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_923) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
        } else {
          %coord_872 = cute.make_coord(%sub_699) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %684:3 = cute.get_scalars(%lay_134) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_873 = cute.assume(%684#1) : (i64) -> !cute.i64<divby 128>
          %stride_874 = cute.make_stride(%iv_873) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_875 = cute.make_layout(%111, %stride_874) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_876 = cute.crd2idx(%coord_872, %lay_134) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_877 = cute.add_offset(%ptr_129, %idx_876) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_878 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
          %append_879 = cute.append_to_rank<2> (%lay_875, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %685 = cute.get_scalars(%append_879) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_880 = cute.assume(%685) : (i64) -> !cute.i64<divby 128>
          %stride_881 = cute.make_stride(%iv_880) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_882 = cute.make_layout(%80, %stride_881) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_883 = cute.append_to_rank<2> (%lay_882, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %686 = cute.get_scalars(%append_883) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_884 = cute.assume(%686) : (i64) -> !cute.i64<divby 128>
          %stride_885 = cute.make_stride(%iv_884) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_886 = cute.make_layout(%79, %stride_885) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %687 = cute.get_scalars(%76) : !cute.int_tuple<"8">
          scf.for %arg6 = %c0_i32 to %687 step %c1_i32  : i32 {
            %coord_887 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_888 = cute.crd2idx(%coord_887, %lay_886) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_889 = cute.add_offset(%ptr_877, %idx_888) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_890 = cute.crd2idx(%coord_887, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_891 = cute.add_offset(%ptr_138, %idx_890) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_892 = cute.crd2idx(%coord_887, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_893 = cute.add_offset(%iter_878, %idx_892) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %688 = builtin.unrealized_conversion_cast %ptr_893 : !cute.ptr<i8, rmem> to !llvm.ptr
            %689 = llvm.load %688 : !llvm.ptr -> i8
            %690 = llvm.trunc %689 : i8 to i1
            %iter_894 = cute.recast_iter(%ptr_889) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_895 = cute.recast_iter(%ptr_891) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_895 : !cute.ptr<i128, smem>, %iter_894 : !cute.ptr<i128, gmem>, %690 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %rmem_700 = cute.memref.alloca() : !memref_rmem_f32_1
        %rmem_701 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_702 = cute.get_iter(%rmem_701) : !memref_rmem_bf16_3
        %538:2 = cute.get_scalars(%lay_191) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %iv_703 = cute.assume(%538#0) : (i32) -> !cute.i32<divby 16>
        %iv_704 = cute.assume(%538#1) : (i32) -> !cute.i32<divby 32>
        %stride_705 = cute.make_stride(%iv_703, %iv_704) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
        %lay_706 = cute.make_layout(%106, %stride_705) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %append = cute.append_to_rank<2> (%lay_706, %117) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
        %539:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %iv_707 = cute.assume(%539#0) : (i32) -> !cute.i32<divby 16>
        %iv_708 = cute.assume(%539#1) : (i32) -> !cute.i32<divby 32>
        %stride_709 = cute.make_stride(%iv_707, %iv_708) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
        %lay_710 = cute.make_layout(%74, %stride_709) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %append_711 = cute.append_to_rank<2> (%lay_710, %117) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">
        %540:2 = cute.get_scalars(%append_711) <{only_dynamic}> : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %iv_712 = cute.assume(%540#0) : (i32) -> !cute.i32<divby 16>
        %iv_713 = cute.assume(%540#1) : (i32) -> !cute.i32<divby 32>
        %stride_714 = cute.make_stride(%iv_712, %iv_713) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
        %lay_715 = cute.make_layout(%73, %stride_714) : !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
        %541 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %541 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %lay_715) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_874 = cute.add_offset(%ptr_187, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_876 = cute.add_offset(%iter_702, %idx_875) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %542 = cute.memref.load_vec %rmem_701 : !memref_rmem_bf16_3
        %543 = arith.extf %542 : vector<32xbf16> to vector<32xf32>
        cute.memref.store_vec %543, %rmem_700 : !memref_rmem_f32_1
        %544 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %544 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_160{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %iter_165 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_872 = cute.add_offset(%iter_165, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_872 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_873 = cute.add_offset(%iter_165, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_874 = cute.add_offset(%iter_165, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_874 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %545 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %545 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_169, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%iter_174, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_716 = cute.crd2idx(%61, %lay_164) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_717 = cute.add_offset(%ptr_160, %idx_716) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_718 = cute.add_offset(%iter_165, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        %546 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %546 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_717{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_718 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"18">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"18">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"20">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"20">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"22">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"22">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_719 = cute.crd2idx(%61, %lay_173) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_720 = cute.add_offset(%ptr_169, %idx_719) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_721 = cute.add_offset(%iter_174, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %547 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %547 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_720, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_721, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_722 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %iter_723 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %iter_724 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %548 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %549 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %550 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %548 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %549 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %550 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%iter_723, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_724, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %iter_722 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_725 = cute.crd2idx(%57, %lay_164) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_726 = cute.add_offset(%ptr_160, %idx_725) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_727 = cute.add_offset(%iter_165, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        %551 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %551 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_726{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_727 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"34">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"36">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"36">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"38">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"38">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_728 = cute.crd2idx(%57, %lay_173) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_729 = cute.add_offset(%ptr_169, %idx_728) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_730 = cute.add_offset(%iter_174, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        %552 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %552 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_729, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_730, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_731 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_732 = cute.add_offset(%iter_731, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_733 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_734 = cute.add_offset(%iter_733, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_735 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %553 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %554 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %555 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %553 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %554 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %555 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_734, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_735, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_732 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_736 = cute.crd2idx(%55, %lay_164) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_737 = cute.add_offset(%ptr_160, %idx_736) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_738 = cute.add_offset(%iter_165, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        %556 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %556 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_737{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_738 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"50">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"50">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"52">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"52">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"54">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"54">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_739 = cute.crd2idx(%55, %lay_173) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_740 = cute.add_offset(%ptr_169, %idx_739) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_741 = cute.add_offset(%iter_174, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        %557 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %557 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_740, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_741, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_742 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_743 = cute.add_offset(%iter_742, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_744 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_745 = cute.add_offset(%iter_744, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_746 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %558 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %559 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %560 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %558 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %559 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %560 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_745, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_746, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_743 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_747 = cute.add_offset(%ptr_160, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_748 = cute.add_offset(%iter_165, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %561 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %561 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_747{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_748 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"12">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"14">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_749 = cute.add_offset(%ptr_169, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_750 = cute.add_offset(%iter_174, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
        %562 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %562 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_749, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_750, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_751 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_752 = cute.add_offset(%iter_751, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_753 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_754 = cute.add_offset(%iter_753, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_755 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %563 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %564 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %565 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %563 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %564 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %565 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_754, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_755, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_752 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_756 = cute.crd2idx(%51, %lay_164) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_757 = cute.add_offset(%ptr_160, %idx_756) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_758 = cute.add_offset(%iter_165, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %566 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %566 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_757{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_758 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"26">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"26">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"28">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"28">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"30">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"30">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_759 = cute.crd2idx(%51, %lay_173) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_760 = cute.add_offset(%ptr_169, %idx_759) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_761 = cute.add_offset(%iter_174, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
        %567 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %567 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_760, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_761, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_762 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_763 = cute.add_offset(%iter_762, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_764 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_765 = cute.add_offset(%iter_764, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_766 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %568 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %569 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %570 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %568 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %569 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %570 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_765, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_766, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_763 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_767 = cute.crd2idx(%48, %lay_164) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_768 = cute.add_offset(%ptr_160, %idx_767) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_769 = cute.add_offset(%iter_165, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        %571 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %571 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_768{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_769 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"42">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"42">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"44">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"44">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"46">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"46">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_770 = cute.crd2idx(%48, %lay_173) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_771 = cute.add_offset(%ptr_169, %idx_770) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_772 = cute.add_offset(%iter_174, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
        %572 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %572 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_771, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_772, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_773 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_774 = cute.add_offset(%iter_773, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_775 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_776 = cute.add_offset(%iter_775, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_777 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %573 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %574 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %575 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %573 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %574 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %575 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_776, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_777, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_774 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_778 = cute.crd2idx(%45, %lay_164) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_779 = cute.add_offset(%ptr_160, %idx_778) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_780 = cute.add_offset(%iter_165, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        %576 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %576 step %c1_i32  : i32 {
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_779{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_780 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %int_tuple_872 = cute.make_int_tuple() : () -> !cute.int_tuple<"58">
          %ptr_873 = cute.add_offset(%iter_165, %int_tuple_872) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"58">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %int_tuple_874 = cute.make_int_tuple() : () -> !cute.int_tuple<"60">
          %ptr_875 = cute.add_offset(%iter_165, %int_tuple_874) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"60">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %int_tuple_876 = cute.make_int_tuple() : () -> !cute.int_tuple<"62">
          %ptr_877 = cute.add_offset(%iter_165, %int_tuple_876) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"62">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_781 = cute.crd2idx(%45, %lay_173) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_782 = cute.add_offset(%ptr_169, %idx_781) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_783 = cute.add_offset(%iter_174, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
        %577 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %577 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_874 = cute.add_offset(%ptr_782, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_876 = cute.add_offset(%ptr_783, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_784 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_785 = cute.add_offset(%iter_784, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_786 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_787 = cute.add_offset(%iter_786, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_788 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %578 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %579 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %580 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %578 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %579 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %580 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_787, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_788, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_785 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %iter_789 = cute.get_iter(%rmem) : !memref_rmem_bf16_
        %ptr_790 = cute.add_offset(%iter_789, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_791 = cute.get_iter(%rmem_151) : !memref_rmem_bf16_1
        %ptr_792 = cute.add_offset(%iter_791, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_793 = cute.get_iter(%rmem_700) : !memref_rmem_f32_1
        %581 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %582 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %583 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %581 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %582 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %583 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_792, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_793, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_790 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %584 = arith.cmpi sgt, %536, %c0_i32 : i32
        scf.if %584 {
          %sub_872 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_873 = cute.make_coord(%sub_872) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %684:3 = cute.get_scalars(%lay_121) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_874 = cute.assume(%684#1) : (i64) -> !cute.i64<divby 128>
          %stride_875 = cute.make_stride(%iv_874) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_876 = cute.make_layout(%111, %stride_875) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_877 = cute.crd2idx(%coord_873, %lay_121) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_878 = cute.add_offset(%ptr_116, %idx_877) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_879 = cute.get_iter(%rmem_277) : !memref_rmem_i8_
          %append_880 = cute.append_to_rank<2> (%lay_876, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %685 = cute.get_scalars(%append_880) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_881 = cute.assume(%685) : (i64) -> !cute.i64<divby 128>
          %stride_882 = cute.make_stride(%iv_881) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_883 = cute.make_layout(%80, %stride_882) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_884 = cute.append_to_rank<2> (%lay_883, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %686 = cute.get_scalars(%append_884) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_885 = cute.assume(%686) : (i64) -> !cute.i64<divby 128>
          %stride_886 = cute.make_stride(%iv_885) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_887 = cute.make_layout(%79, %stride_886) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %687 = cute.get_scalars(%76) : !cute.int_tuple<"8">
          scf.for %arg6 = %c0_i32 to %687 step %c1_i32  : i32 {
            %coord_952 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_953 = cute.crd2idx(%coord_952, %lay_887) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_954 = cute.add_offset(%ptr_878, %idx_953) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_955 = cute.crd2idx(%coord_952, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_956 = cute.add_offset(%ptr_125, %idx_955) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_957 = cute.crd2idx(%coord_952, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_958 = cute.add_offset(%iter_879, %idx_957) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %704 = builtin.unrealized_conversion_cast %ptr_958 : !cute.ptr<i8, rmem> to !llvm.ptr
            %705 = llvm.load %704 : !llvm.ptr -> i8
            %706 = llvm.trunc %705 : i8 to i1
            %iter_959 = cute.recast_iter(%ptr_954) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_960 = cute.recast_iter(%ptr_956) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_960 : !cute.ptr<i128, smem>, %iter_959 : !cute.ptr<i128, gmem>, %706 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
          %sub_888 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_889 = cute.make_coord(%sub_888) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %idx_890 = cute.crd2idx(%coord_889, %lay_275) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
          %tup_891 = cute.add_offset(%tup_273, %idx_890) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_892, %e1_893, %e2_894, %e3_895 = cute.get_leaves(%tup_891) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_896 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %688 = cute.get_shape(%lay_896) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_897, %e1_898, %e2_899, %e3_900 = cute.get_leaves(%688) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_901 = cute.to_int_tuple(%e2_899) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_902 = cute.make_coord(%e1_893) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_903 = cute.make_coord(%itup_901) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %689 = cute.get_scalars(%coord_902) : !cute.coord<"?">
          %690 = cute.get_scalars(%coord_903) : !cute.coord<"?">
          %691 = arith.cmpi slt, %689, %690 : i32
          scf.if %691 {
            %sub_952 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %coord_953 = cute.make_coord(%sub_952) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_954 = cute.crd2idx(%coord_953, %lay_146) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
            %ptr_955 = cute.add_offset(%ptr_142, %idx_954) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %704 = cute.get_scalars(%116) : !cute.int_tuple<"1">
            scf.for %arg6 = %c0_i32 to %704 step %c1_i32  : i32 {
              %iter_956 = cute.recast_iter(%ptr_955) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_957 = cute.recast_iter(%ptr_150) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_957 : !cute.ptr<i128, smem>, %iter_956 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_150) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %sub_904 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_905 = cute.make_coord(%sub_904) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %idx_906 = cute.crd2idx(%coord_905, %lay_275) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
          %tup_907 = cute.add_offset(%tup_273, %idx_906) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_908, %e1_909, %e2_910, %e3_911 = cute.get_leaves(%tup_907) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_912 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %692 = cute.get_shape(%lay_912) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_913, %e1_914, %e2_915, %e3_916 = cute.get_leaves(%692) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_917 = cute.to_int_tuple(%e2_915) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_918 = cute.make_coord(%e1_909) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_919 = cute.make_coord(%itup_917) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %693 = cute.get_scalars(%coord_918) : !cute.coord<"?">
          %694 = cute.get_scalars(%coord_919) : !cute.coord<"?">
          %695 = arith.cmpi slt, %693, %694 : i32
          scf.if %695 {
            %sub_952 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %coord_953 = cute.make_coord(%sub_952) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_954 = cute.crd2idx(%coord_953, %lay_146) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_955 = cute.add_offset(%ptr_142, %idx_954) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_956 = cute.add_offset(%ptr_150, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %704 = cute.get_scalars(%116) : !cute.int_tuple<"1">
            scf.for %arg6 = %c0_i32 to %704 step %c1_i32  : i32 {
              %iter_957 = cute.recast_iter(%ptr_955) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_958 = cute.recast_iter(%ptr_956) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_958 : !cute.ptr<i128, smem>, %iter_957 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_952 = cute.add_offset(%ptr_150, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_952) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %sub_920 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_921 = cute.make_coord(%sub_920) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %idx_922 = cute.crd2idx(%coord_921, %lay_275) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
          %tup_923 = cute.add_offset(%tup_273, %idx_922) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_924, %e1_925, %e2_926, %e3_927 = cute.get_leaves(%tup_923) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_928 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %696 = cute.get_shape(%lay_928) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_929, %e1_930, %e2_931, %e3_932 = cute.get_leaves(%696) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_933 = cute.to_int_tuple(%e2_931) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_934 = cute.make_coord(%e1_925) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_935 = cute.make_coord(%itup_933) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %697 = cute.get_scalars(%coord_934) : !cute.coord<"?">
          %698 = cute.get_scalars(%coord_935) : !cute.coord<"?">
          %699 = arith.cmpi slt, %697, %698 : i32
          scf.if %699 {
            %sub_952 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %coord_953 = cute.make_coord(%sub_952) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_954 = cute.crd2idx(%coord_953, %lay_146) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_955 = cute.add_offset(%ptr_142, %idx_954) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_956 = cute.add_offset(%ptr_150, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %704 = cute.get_scalars(%116) : !cute.int_tuple<"1">
            scf.for %arg6 = %c0_i32 to %704 step %c1_i32  : i32 {
              %iter_957 = cute.recast_iter(%ptr_955) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_958 = cute.recast_iter(%ptr_956) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_958 : !cute.ptr<i128, smem>, %iter_957 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_952 = cute.add_offset(%ptr_150, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_952) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %sub_936 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_937 = cute.make_coord(%sub_936) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %idx_938 = cute.crd2idx(%coord_937, %lay_275) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
          %tup_939 = cute.add_offset(%tup_273, %idx_938) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_940, %e1_941, %e2_942, %e3_943 = cute.get_leaves(%tup_939) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %lay_944 = cute.get_layout(%arg4) : !memref_gmem_bf16_
          %700 = cute.get_shape(%lay_944) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_945, %e1_946, %e2_947, %e3_948 = cute.get_leaves(%700) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_949 = cute.to_int_tuple(%e2_947) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_950 = cute.make_coord(%e1_941) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %coord_951 = cute.make_coord(%itup_949) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %701 = cute.get_scalars(%coord_950) : !cute.coord<"?">
          %702 = cute.get_scalars(%coord_951) : !cute.coord<"?">
          %703 = arith.cmpi slt, %701, %702 : i32
          scf.if %703 {
            %sub_952 = cute.tuple_sub(%sub_699, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
            %coord_953 = cute.make_coord(%sub_952) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_954 = cute.crd2idx(%coord_953, %lay_146) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_955 = cute.add_offset(%ptr_142, %idx_954) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_956 = cute.add_offset(%ptr_150, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %704 = cute.get_scalars(%116) : !cute.int_tuple<"1">
            scf.for %arg6 = %c0_i32 to %704 step %c1_i32  : i32 {
              %iter_957 = cute.recast_iter(%ptr_955) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_958 = cute.recast_iter(%ptr_956) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_958 : !cute.ptr<i128, smem>, %iter_957 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_952 = cute.add_offset(%ptr_150, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_952) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          nvvm.cp.async.commit.group
        }
        %585 = cute.memref.load_vec %rmem_700 : !memref_rmem_f32_1
        %586 = arith.mulf %585, %cst : vector<32xf32>
        cute.memref.store_vec %586, %rmem_700 : !memref_rmem_f32_1
        %587 = cute.memref.load(%rmem_700, %97) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
        %588 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %587 : (f32) -> f32
        cute.memref.store(%rmem_700, %97, %588) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
        %589 = cute.memref.load(%rmem_700, %95) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
        %590 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %589 : (f32) -> f32
        cute.memref.store(%rmem_700, %95, %590) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
        %591 = cute.memref.load(%rmem_700, %42) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
        %592 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %591 : (f32) -> f32
        cute.memref.store(%rmem_700, %42, %592) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
        %593 = cute.memref.load(%rmem_700, %41) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
        %594 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %593 : (f32) -> f32
        cute.memref.store(%rmem_700, %41, %594) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
        %595 = cute.memref.load(%rmem_700, %40) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
        %596 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %595 : (f32) -> f32
        cute.memref.store(%rmem_700, %40, %596) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
        %597 = cute.memref.load(%rmem_700, %39) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
        %598 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %597 : (f32) -> f32
        cute.memref.store(%rmem_700, %39, %598) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
        %599 = cute.memref.load(%rmem_700, %38) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
        %600 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %599 : (f32) -> f32
        cute.memref.store(%rmem_700, %38, %600) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
        %601 = cute.memref.load(%rmem_700, %37) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
        %602 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %601 : (f32) -> f32
        cute.memref.store(%rmem_700, %37, %602) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
        %603 = cute.memref.load(%rmem_700, %36) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
        %604 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %603 : (f32) -> f32
        cute.memref.store(%rmem_700, %36, %604) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
        %605 = cute.memref.load(%rmem_700, %35) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
        %606 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %605 : (f32) -> f32
        cute.memref.store(%rmem_700, %35, %606) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
        %607 = cute.memref.load(%rmem_700, %34) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
        %608 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %607 : (f32) -> f32
        cute.memref.store(%rmem_700, %34, %608) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
        %609 = cute.memref.load(%rmem_700, %33) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
        %610 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %609 : (f32) -> f32
        cute.memref.store(%rmem_700, %33, %610) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
        %611 = cute.memref.load(%rmem_700, %32) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
        %612 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %611 : (f32) -> f32
        cute.memref.store(%rmem_700, %32, %612) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
        %613 = cute.memref.load(%rmem_700, %31) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
        %614 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %613 : (f32) -> f32
        cute.memref.store(%rmem_700, %31, %614) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
        %615 = cute.memref.load(%rmem_700, %30) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
        %616 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %615 : (f32) -> f32
        cute.memref.store(%rmem_700, %30, %616) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
        %617 = cute.memref.load(%rmem_700, %29) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
        %618 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %617 : (f32) -> f32
        cute.memref.store(%rmem_700, %29, %618) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
        %619 = cute.memref.load(%rmem_700, %28) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
        %620 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %619 : (f32) -> f32
        cute.memref.store(%rmem_700, %28, %620) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
        %621 = cute.memref.load(%rmem_700, %27) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
        %622 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %621 : (f32) -> f32
        cute.memref.store(%rmem_700, %27, %622) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
        %623 = cute.memref.load(%rmem_700, %26) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
        %624 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %623 : (f32) -> f32
        cute.memref.store(%rmem_700, %26, %624) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
        %625 = cute.memref.load(%rmem_700, %25) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
        %626 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %625 : (f32) -> f32
        cute.memref.store(%rmem_700, %25, %626) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
        %627 = cute.memref.load(%rmem_700, %24) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
        %628 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %627 : (f32) -> f32
        cute.memref.store(%rmem_700, %24, %628) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
        %629 = cute.memref.load(%rmem_700, %23) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
        %630 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %629 : (f32) -> f32
        cute.memref.store(%rmem_700, %23, %630) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
        %631 = cute.memref.load(%rmem_700, %22) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
        %632 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %631 : (f32) -> f32
        cute.memref.store(%rmem_700, %22, %632) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
        %633 = cute.memref.load(%rmem_700, %21) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
        %634 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %633 : (f32) -> f32
        cute.memref.store(%rmem_700, %21, %634) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
        %635 = cute.memref.load(%rmem_700, %20) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
        %636 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %635 : (f32) -> f32
        cute.memref.store(%rmem_700, %20, %636) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
        %637 = cute.memref.load(%rmem_700, %19) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
        %638 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %637 : (f32) -> f32
        cute.memref.store(%rmem_700, %19, %638) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
        %639 = cute.memref.load(%rmem_700, %18) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
        %640 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %639 : (f32) -> f32
        cute.memref.store(%rmem_700, %18, %640) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
        %641 = cute.memref.load(%rmem_700, %17) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
        %642 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %641 : (f32) -> f32
        cute.memref.store(%rmem_700, %17, %642) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
        %643 = cute.memref.load(%rmem_700, %16) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
        %644 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %643 : (f32) -> f32
        cute.memref.store(%rmem_700, %16, %644) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
        %645 = cute.memref.load(%rmem_700, %15) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
        %646 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %645 : (f32) -> f32
        cute.memref.store(%rmem_700, %15, %646) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
        %647 = cute.memref.load(%rmem_700, %14) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
        %648 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %647 : (f32) -> f32
        cute.memref.store(%rmem_700, %14, %648) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
        %649 = cute.memref.load(%rmem_700, %13) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
        %650 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %649 : (f32) -> f32
        cute.memref.store(%rmem_700, %13, %650) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
        %651 = cute.memref.load_vec %rmem_700 : !memref_rmem_f32_1
        %652 = arith.mulf %586, %651 : vector<32xf32>
        %653 = arith.addf %652, %586 : vector<32xf32>
        cute.memref.store_vec %653, %rmem_700 : !memref_rmem_f32_1
        %rmem_794 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_795 = cute.get_iter(%rmem_794) : !memref_rmem_bf16_3
        %654 = cute.memref.load_vec %rmem_700 : !memref_rmem_f32_1
        %655 = arith.truncf %654 : vector<32xf32> to vector<32xbf16>
        cute.memref.store_vec %655, %rmem_794 : !memref_rmem_bf16_3
        %656:2 = cute.get_scalars(%lay_182) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %iv_796 = cute.assume(%656#0) : (i32) -> !cute.i32<divby 16>
        %iv_797 = cute.assume(%656#1) : (i32) -> !cute.i32<divby 32>
        %stride_798 = cute.make_stride(%iv_796, %iv_797) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_799 = cute.make_layout(%12, %stride_798) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %append_800 = cute.append_to_rank<2> (%lay_799, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %657:2 = cute.get_scalars(%append_800) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %iv_801 = cute.assume(%657#0) : (i32) -> !cute.i32<divby 16>
        %iv_802 = cute.assume(%657#1) : (i32) -> !cute.i32<divby 32>
        %stride_803 = cute.make_stride(%iv_801, %iv_802) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_804 = cute.make_layout(%11, %stride_803) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %append_805 = cute.append_to_rank<2> (%lay_804, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %658:2 = cute.get_scalars(%append_805) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %iv_806 = cute.assume(%658#0) : (i32) -> !cute.i32<divby 16>
        %iv_807 = cute.assume(%658#1) : (i32) -> !cute.i32<divby 32>
        %stride_808 = cute.make_stride(%iv_806, %iv_807) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_809 = cute.make_layout(%10, %stride_808) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %659 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %659 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %lay_809) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_874 = cute.add_offset(%ptr_178, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_876 = cute.add_offset(%iter_183, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %660:2 = cute.get_scalars(%lay_182) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %iv_810 = cute.assume(%660#0) : (i32) -> !cute.i32<divby 16>
        %iv_811 = cute.assume(%660#1) : (i32) -> !cute.i32<divby 32>
        %stride_812 = cute.make_stride(%iv_810, %iv_811) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_813 = cute.make_layout(%12, %stride_812) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %ptr_814 = cute.add_offset(%ptr_178, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_815 = cute.add_offset(%iter_183, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %append_816 = cute.append_to_rank<2> (%lay_813, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %661:2 = cute.get_scalars(%append_816) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %iv_817 = cute.assume(%661#0) : (i32) -> !cute.i32<divby 16>
        %iv_818 = cute.assume(%661#1) : (i32) -> !cute.i32<divby 32>
        %stride_819 = cute.make_stride(%iv_817, %iv_818) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_820 = cute.make_layout(%11, %stride_819) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %append_821 = cute.append_to_rank<2> (%lay_820, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %662:2 = cute.get_scalars(%append_821) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %iv_822 = cute.assume(%662#0) : (i32) -> !cute.i32<divby 16>
        %iv_823 = cute.assume(%662#1) : (i32) -> !cute.i32<divby 32>
        %stride_824 = cute.make_stride(%iv_822, %iv_823) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_825 = cute.make_layout(%10, %stride_824) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %663 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %663 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %lay_825) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_874 = cute.add_offset(%ptr_814, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_876 = cute.add_offset(%ptr_815, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_826 = cute.get_iter(%rmem_152) : !memref_rmem_bf16_2
        %iter_827 = cute.get_iter(%rmem_153) : !memref_rmem_f32_
        %664 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %665 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %666 = cute.get_scalars(%60) : !cute.int_tuple<"16">
        scf.for %arg6 = %c0_i32 to %664 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %665 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %666 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%iter_826, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_827, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %iter_795 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %667:2 = cute.get_scalars(%lay_182) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %iv_828 = cute.assume(%667#0) : (i32) -> !cute.i32<divby 16>
        %iv_829 = cute.assume(%667#1) : (i32) -> !cute.i32<divby 32>
        %stride_830 = cute.make_stride(%iv_828, %iv_829) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_831 = cute.make_layout(%12, %stride_830) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %ptr_832 = cute.add_offset(%ptr_178, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_833 = cute.add_offset(%iter_183, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %append_834 = cute.append_to_rank<2> (%lay_831, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %668:2 = cute.get_scalars(%append_834) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %iv_835 = cute.assume(%668#0) : (i32) -> !cute.i32<divby 16>
        %iv_836 = cute.assume(%668#1) : (i32) -> !cute.i32<divby 32>
        %stride_837 = cute.make_stride(%iv_835, %iv_836) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_838 = cute.make_layout(%11, %stride_837) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %append_839 = cute.append_to_rank<2> (%lay_838, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %669:2 = cute.get_scalars(%append_839) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %iv_840 = cute.assume(%669#0) : (i32) -> !cute.i32<divby 16>
        %iv_841 = cute.assume(%669#1) : (i32) -> !cute.i32<divby 32>
        %stride_842 = cute.make_stride(%iv_840, %iv_841) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_843 = cute.make_layout(%10, %stride_842) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %670 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %670 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %lay_843) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_874 = cute.add_offset(%ptr_832, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_876 = cute.add_offset(%ptr_833, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_844 = cute.add_offset(%iter_795, %76) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_845 = cute.get_iter(%rmem_152) : !memref_rmem_bf16_2
        %ptr_846 = cute.add_offset(%iter_845, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_847 = cute.get_iter(%rmem_153) : !memref_rmem_f32_
        %671 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %672 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %673 = cute.get_scalars(%60) : !cute.int_tuple<"16">
        scf.for %arg6 = %c0_i32 to %671 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %672 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %673 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_846, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_847, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_844 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %674:2 = cute.get_scalars(%lay_182) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %iv_848 = cute.assume(%674#0) : (i32) -> !cute.i32<divby 16>
        %iv_849 = cute.assume(%674#1) : (i32) -> !cute.i32<divby 32>
        %stride_850 = cute.make_stride(%iv_848, %iv_849) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_851 = cute.make_layout(%12, %stride_850) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %ptr_852 = cute.add_offset(%ptr_178, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_853 = cute.add_offset(%iter_183, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %append_854 = cute.append_to_rank<2> (%lay_851, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %675:2 = cute.get_scalars(%append_854) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %iv_855 = cute.assume(%675#0) : (i32) -> !cute.i32<divby 16>
        %iv_856 = cute.assume(%675#1) : (i32) -> !cute.i32<divby 32>
        %stride_857 = cute.make_stride(%iv_855, %iv_856) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_858 = cute.make_layout(%11, %stride_857) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %append_859 = cute.append_to_rank<2> (%lay_858, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %676:2 = cute.get_scalars(%append_859) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %iv_860 = cute.assume(%676#0) : (i32) -> !cute.i32<divby 16>
        %iv_861 = cute.assume(%676#1) : (i32) -> !cute.i32<divby 32>
        %stride_862 = cute.make_stride(%iv_860, %iv_861) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_863 = cute.make_layout(%10, %stride_862) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        %677 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %677 step %c1_i32  : i32 {
          %coord_872 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_873 = cute.crd2idx(%coord_872, %lay_863) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_874 = cute.add_offset(%ptr_852, %idx_873) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_875 = cute.crd2idx(%coord_872, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_876 = cute.add_offset(%ptr_853, %idx_875) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %684 = cute_nvgpu.arch.copy.ldsm %ptr_874{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %685 = vector.extractelement %684[%70 : i32] : vector<4xi32>
          %686 = builtin.unrealized_conversion_cast %ptr_876 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %685, %686 : i32, !llvm.ptr
          %687 = vector.extractelement %684[%69 : i32] : vector<4xi32>
          %ptr_877 = cute.add_offset(%ptr_876, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %688 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %687, %688 : i32, !llvm.ptr
          %689 = vector.extractelement %684[%68 : i32] : vector<4xi32>
          %ptr_878 = cute.add_offset(%ptr_876, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %690 = builtin.unrealized_conversion_cast %ptr_878 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %689, %690 : i32, !llvm.ptr
          %691 = vector.extractelement %684[%67 : i32] : vector<4xi32>
          %ptr_879 = cute.add_offset(%ptr_876, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %692 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %691, %692 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_864 = cute.add_offset(%iter_795, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %iter_865 = cute.get_iter(%rmem_152) : !memref_rmem_bf16_2
        %ptr_866 = cute.add_offset(%iter_865, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_867 = cute.get_iter(%rmem_153) : !memref_rmem_f32_
        %678 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %679 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %680 = cute.get_scalars(%60) : !cute.int_tuple<"16">
        scf.for %arg6 = %c0_i32 to %678 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %679 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %680 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_866, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_867, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_864 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_868 = cute.add_offset(%iter_795, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %iter_869 = cute.get_iter(%rmem_152) : !memref_rmem_bf16_2
        %ptr_870 = cute.add_offset(%iter_869, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        %iter_871 = cute.get_iter(%rmem_153) : !memref_rmem_f32_
        %681 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %682 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %683 = cute.get_scalars(%60) : !cute.int_tuple<"16">
        scf.for %arg6 = %c0_i32 to %681 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %682 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %683 step %c1_i32  : i32 {
              %coord_872 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_873 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_874 = cute.crd2idx(%coord_872, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_875 = cute.add_offset(%ptr_870, %idx_874) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_876 = cute.crd2idx(%coord_873, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_877 = cute.add_offset(%iter_871, %idx_876) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %684 = builtin.unrealized_conversion_cast %ptr_868 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %685 = llvm.load %684 : !llvm.ptr -> i32
              %686 = llvm.getelementptr %684[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %687 = llvm.load %686 : !llvm.ptr -> i32
              %688 = llvm.getelementptr %684[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %689 = llvm.load %688 : !llvm.ptr -> i32
              %690 = llvm.getelementptr %684[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %691 = llvm.load %690 : !llvm.ptr -> i32
              %692 = builtin.unrealized_conversion_cast %ptr_875 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %693 = llvm.load %692 : !llvm.ptr -> i32
              %694 = llvm.getelementptr %692[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %695 = llvm.load %694 : !llvm.ptr -> i32
              %696 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %697 = llvm.load %696 : !llvm.ptr -> f32
              %698 = llvm.getelementptr %696[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %699 = llvm.load %698 : !llvm.ptr -> f32
              %700 = llvm.getelementptr %696[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %701 = llvm.load %700 : !llvm.ptr -> f32
              %702 = llvm.getelementptr %696[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %703 = llvm.load %702 : !llvm.ptr -> f32
              %704:4 = cute_nvgpu.arch.mma.SM80 A[%685, %687, %689, %691]  B[%693, %695]  C[%697, %699, %701, %703] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              %705 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              llvm.store %704#0, %705 : f32, !llvm.ptr
              %706 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#1, %706 : f32, !llvm.ptr
              %707 = llvm.getelementptr %705[2] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#2, %707 : f32, !llvm.ptr
              %708 = llvm.getelementptr %705[3] : (!llvm.ptr) -> !llvm.ptr, f32
              llvm.store %704#3, %708 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      }
      %rmem_551 = cute.memref.alloca() : !memref_rmem_bf16_4
      %462 = cute.memref.load_vec %rmem_153 : !memref_rmem_f32_
      %463 = arith.truncf %462 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %463, %rmem_551 : !memref_rmem_bf16_4
      %iter_552 = cute.recast_iter(%iter_98) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %atom_553 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %464 = cute.make_tiled_copy(%atom_553) : !copy_simt
      %iter_554 = cute.get_iter(%rmem_551) : !memref_rmem_bf16_4
      %coord_555 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %465 = cute.get_scalars(%coord_555) <{only_dynamic}> : !cute.coord<"?">
      %466 = arith.divsi %465, %c4_i32 : i32
      %467 = arith.remsi %465, %c4_i32 : i32
      %468 = arith.muli %467, %c2_i32 : i32
      %469 = arith.divsi %466, %c8_i32 : i32
      %470 = arith.remsi %466, %c8_i32 : i32
      %471 = arith.muli %470, %c64_i32 : i32
      %472 = arith.addi %468, %471 : i32
      %473 = arith.muli %469, %c1024_i32 : i32
      %474 = arith.addi %472, %473 : i32
      %iv_556 = cute.assume(%474) : (i32) -> !cute.i32<divby 2>
      %int_tuple_557 = cute.make_int_tuple(%iv_556) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_558 = cute.add_offset(%iter_552, %int_tuple_557) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %475 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      scf.for %arg5 = %c0_i32 to %475 step %c1_i32  : i32 {
        %coord_698 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_700 = cute.add_offset(%iter_554, %idx_699) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %idx_701 = cute.crd2idx(%coord_698, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_702 = cute.add_offset(%ptr_558, %idx_701) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled = cute.apply_swizzle(%ptr_702) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %536 = builtin.unrealized_conversion_cast %ptr_700 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %537 = builtin.unrealized_conversion_cast %swizzled : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %538 = llvm.load %536 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %538, %537 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_703 = cute.add_offset(%ptr_700, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_704 = cute.add_offset(%ptr_702, %4) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_705 = cute.apply_swizzle(%ptr_704) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %539 = builtin.unrealized_conversion_cast %ptr_703 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %540 = builtin.unrealized_conversion_cast %swizzled_705 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %541 = llvm.load %539 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %541, %540 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_706 = cute.add_offset(%ptr_700, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %ptr_707 = cute.add_offset(%ptr_702, %76) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_708 = cute.apply_swizzle(%ptr_707) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %542 = builtin.unrealized_conversion_cast %ptr_706 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        %543 = builtin.unrealized_conversion_cast %swizzled_708 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %544 = llvm.load %542 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %544, %543 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_709 = cute.add_offset(%ptr_700, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_710 = cute.add_offset(%ptr_702, %3) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_711 = cute.apply_swizzle(%ptr_710) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %545 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %546 = builtin.unrealized_conversion_cast %swizzled_711 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %547 = llvm.load %545 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %547, %546 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      } {llvm.loop_annotation = #loop_annotation}
      %coord_559 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_560 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %476:7 = cute.get_scalars(%lay_560) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_561 = cute.assume(%476#3) : (i32) -> !cute.i32<divby 8>
      %shape_562 = cute.make_shape(%476#1, %iv_561) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_563 = cute.assume(%476#5) : (i64) -> !cute.i64<divby 8>
      %stride_564 = cute.make_stride(%iv_563) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_565 = cute.make_layout(%shape_562, %stride_564) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_566 = cute.crd2idx(%coord_559, %lay_560) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_567 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_568 = cute.add_offset(%iter_567, %idx_566) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_569 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %477 = cute.get_scalars(%coord_569) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_570 = cute.make_coord(%477) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %478:3 = cute.get_scalars(%lay_565) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %479 = arith.ceildivsi %478#0, %c64_i32 : i32
      %480 = arith.muli %478#2, %c64_i64 : i64
      %481 = arith.ceildivsi %478#1, %c128_i32 : i32
      %shape_571 = cute.make_shape(%479, %481) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_572 = cute.assume(%478#2) : (i64) -> !cute.i64<divby 8>
      %iv_573 = cute.assume(%480) : (i64) -> !cute.i64<divby 512>
      %stride_574 = cute.make_stride(%iv_572, %iv_573) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_575 = cute.make_layout(%shape_571, %stride_574) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %482:4 = cute.get_scalars(%lay_575) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_576 = cute.assume(%482#2) : (i64) -> !cute.i64<divby 8>
      %stride_577 = cute.make_stride(%iv_576) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_578 = cute.make_layout(%115, %stride_577) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_579 = cute.crd2idx(%coord_570, %lay_575) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_580 = cute.add_offset(%ptr_568, %idx_579) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_581 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %483 = cute.get_scalars(%coord_581) <{only_dynamic}> : !cute.coord<"?">
      %484 = arith.divsi %483, %c8_i32 : i32
      %485 = arith.remsi %483, %c8_i32 : i32
      %486 = arith.muli %485, %c8_i32 : i32
      %487 = arith.muli %484, %c64_i32 : i32
      %488 = arith.addi %486, %487 : i32
      %iv_582 = cute.assume(%488) : (i32) -> !cute.i32<divby 8>
      %int_tuple_583 = cute.make_int_tuple(%iv_582) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_584 = cute.add_offset(%iter_552, %int_tuple_583) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %coord_585 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %489 = cute.get_scalars(%lay_578) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %490 = cute.get_scalars(%coord_585) <{only_dynamic}> : !cute.coord<"?">
      %491 = arith.muli %489, %c16_i64 : i64
      %492 = arith.divsi %490, %c8_i32 : i32
      %493 = arith.remsi %490, %c8_i32 : i32
      %494 = arith.muli %493, %c8_i32 : i32
      %495 = arith.extsi %492 : i32 to i64
      %496 = arith.muli %495, %489 : i64
      %497 = arith.extsi %494 : i32 to i64
      %498 = arith.addi %497, %496 : i64
      %iv_586 = cute.assume(%498) : (i64) -> !cute.i64<divby 8>
      %int_tuple_587 = cute.make_int_tuple(%iv_586) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_588 = cute.add_offset(%ptr_580, %int_tuple_587) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_589 = cute.assume(%491) : (i64) -> !cute.i64<divby 128>
      %stride_590 = cute.make_stride(%iv_589) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_591 = cute.make_layout(%111, %stride_590) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %rmem_592 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_593 = cute.get_iter(%rmem_592) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %499 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      scf.for %arg5 = %c0_i32 to %499 step %c1_i32  : i32 {
        %coord_698 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_699 = cute.crd2idx(%coord_698, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
        %idx_700 = cute.crd2idx(%coord_698, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_701 = cute.add_offset(%iter_593, %idx_700) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %swizzled = cute.apply_swizzle(%ptr_584) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %ptr_702 = cute.add_offset(%swizzled, %idx_699) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %536 = builtin.unrealized_conversion_cast %ptr_702 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
        %537 = builtin.unrealized_conversion_cast %ptr_701 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %538 = llvm.load %536 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %538, %537 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %lay_594 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %500 = cute.get_shape(%lay_594) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_595, %e1_596, %e2_597, %e3_598 = cute.get_leaves(%500) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_599 = cute.to_int_tuple(%e0_595) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_600 = cute.to_int_tuple(%e1_596) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_601 = cute.to_int_tuple(%e2_597) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_602 = cute.to_int_tuple(%e3_598) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_603 = cute.make_shape(%itup_599, %itup_600, %itup_601, %itup_602) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_604 = cute.make_layout(%shape_603, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %coord_605 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %501:4 = cute.get_scalars(%lay_604) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_606 = cute.assume(%501#3) : (i32) -> !cute.i32<divby 8>
      %shape_607 = cute.make_shape(%501#1, %iv_606) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_608 = cute.make_layout(%shape_607, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_609 = cute.crd2idx(%coord_605, %lay_604) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_610 = cute.add_offset(%105, %idx_609) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_611 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %502 = cute.get_scalars(%coord_611) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_612 = cute.make_coord(%502) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %503:2 = cute.get_scalars(%lay_608) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %504 = arith.ceildivsi %503#0, %c64_i32 : i32
      %505 = arith.ceildivsi %503#1, %c128_i32 : i32
      %shape_613 = cute.make_shape(%504, %505) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_614 = cute.make_layout(%shape_613, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_615 = cute.crd2idx(%coord_612, %lay_614) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_616 = cute.add_offset(%tup_610, %idx_615) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %coord_617 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %506 = cute.get_scalars(%coord_617) <{only_dynamic}> : !cute.coord<"?">
      %507 = arith.divsi %506, %c8_i32 : i32
      %508 = arith.remsi %506, %c8_i32 : i32
      %509 = arith.muli %508, %c8_i32 : i32
      %iv_618 = cute.assume(%509) : (i32) -> !cute.i32<divby 8>
      %int_tuple_619 = cute.make_int_tuple(%507, %iv_618) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_620 = cute.add_offset(%tup_616, %int_tuple_619) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_621 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_622, %e1_623, %e2_624, %e3_625 = cute.get_leaves(%tup_620) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_626 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %510 = cute.get_shape(%lay_626) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_627, %e1_628, %e2_629, %e3_630 = cute.get_leaves(%510) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_631 = cute.to_int_tuple(%e3_630) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_632 = cute.make_coord(%e3_625) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_633 = cute.make_coord(%itup_631) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %511 = cute.get_scalars(%coord_632) : !cute.coord<"?{div=8}">
      %512 = cute.get_scalars(%coord_633) : !cute.coord<"?{div=8}">
      %513 = arith.cmpi slt, %511, %512 : i32
      %514 = arith.extui %513 : i1 to i8
      cute.memref.store(%rmem_621, %97, %514) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_634 = cute.add_offset(%tup_620, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_635, %e1_636, %e2_637, %e3_638 = cute.get_leaves(%tup_634) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_639 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %515 = cute.get_shape(%lay_639) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_640, %e1_641, %e2_642, %e3_643 = cute.get_leaves(%515) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_644 = cute.to_int_tuple(%e3_643) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %coord_645 = cute.make_coord(%e3_638) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_646 = cute.make_coord(%itup_644) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %516 = cute.get_scalars(%coord_645) : !cute.coord<"?{div=8}">
      %517 = cute.get_scalars(%coord_646) : !cute.coord<"?{div=8}">
      %518 = arith.cmpi slt, %516, %517 : i32
      %519 = arith.extui %518 : i1 to i8
      cute.memref.store(%rmem_621, %95, %519) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_647, %e1_648, %e2_649, %e3_650 = cute.get_leaves(%tup_620) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_651 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %520 = cute.get_shape(%lay_651) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_652, %e1_653, %e2_654, %e3_655 = cute.get_leaves(%520) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_656 = cute.to_int_tuple(%e1_653) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_657 = cute.make_coord(%e1_648) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_658 = cute.make_coord(%itup_656) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %521 = cute.get_scalars(%coord_657) : !cute.coord<"?">
      %522 = cute.get_scalars(%coord_658) : !cute.coord<"?">
      %523 = arith.cmpi slt, %521, %522 : i32
      scf.if %523 {
        %iter_698 = cute.get_iter(%rmem_592) : !memref_rmem_bf16_5
        %iter_699 = cute.get_iter(%rmem_621) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_700 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_701 = cute.crd2idx(%coord_700, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_702 = cute.add_offset(%iter_698, %idx_701) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_703 = cute.crd2idx(%coord_700, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_704 = cute.add_offset(%ptr_588, %idx_703) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_705 = cute.crd2idx(%coord_700, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_706 = cute.add_offset(%iter_699, %idx_705) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_706 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.icmp "ne" %538, %0 : i8
          scf.if %539 {
            %540 = builtin.unrealized_conversion_cast %ptr_702 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %541 = builtin.unrealized_conversion_cast %ptr_704 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %542 = llvm.load %540 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %542, %541 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_659 = cute.add_offset(%tup_620, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_660, %e1_661, %e2_662, %e3_663 = cute.get_leaves(%tup_659) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_664 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %524 = cute.get_shape(%lay_664) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_665, %e1_666, %e2_667, %e3_668 = cute.get_leaves(%524) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_669 = cute.to_int_tuple(%e1_666) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_670 = cute.make_coord(%e1_661) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_671 = cute.make_coord(%itup_669) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %525 = cute.get_scalars(%coord_670) : !cute.coord<"?">
      %526 = cute.get_scalars(%coord_671) : !cute.coord<"?">
      %527 = arith.cmpi slt, %525, %526 : i32
      scf.if %527 {
        %iter_698 = cute.get_iter(%rmem_592) : !memref_rmem_bf16_5
        %ptr_699 = cute.add_offset(%iter_698, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_700 = cute.crd2idx(%89, %lay_591) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_701 = cute.add_offset(%ptr_588, %idx_700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_702 = cute.get_iter(%rmem_621) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_705 = cute.add_offset(%ptr_699, %idx_704) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.icmp "ne" %538, %0 : i8
          scf.if %539 {
            %540 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %541 = builtin.unrealized_conversion_cast %ptr_707 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %542 = llvm.load %540 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %542, %541 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_672 = cute.add_offset(%tup_620, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_673, %e1_674, %e2_675, %e3_676 = cute.get_leaves(%tup_672) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_677 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %528 = cute.get_shape(%lay_677) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_678, %e1_679, %e2_680, %e3_681 = cute.get_leaves(%528) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_682 = cute.to_int_tuple(%e1_679) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_683 = cute.make_coord(%e1_674) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_684 = cute.make_coord(%itup_682) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %529 = cute.get_scalars(%coord_683) : !cute.coord<"?">
      %530 = cute.get_scalars(%coord_684) : !cute.coord<"?">
      %531 = arith.cmpi slt, %529, %530 : i32
      scf.if %531 {
        %iter_698 = cute.get_iter(%rmem_592) : !memref_rmem_bf16_5
        %ptr_699 = cute.add_offset(%iter_698, %63) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_700 = cute.crd2idx(%86, %lay_591) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_701 = cute.add_offset(%ptr_588, %idx_700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_702 = cute.get_iter(%rmem_621) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_705 = cute.add_offset(%ptr_699, %idx_704) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.icmp "ne" %538, %0 : i8
          scf.if %539 {
            %540 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %541 = builtin.unrealized_conversion_cast %ptr_707 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %542 = llvm.load %540 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %542, %541 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_685 = cute.add_offset(%tup_620, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_686, %e1_687, %e2_688, %e3_689 = cute.get_leaves(%tup_685) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %lay_690 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %532 = cute.get_shape(%lay_690) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_691, %e1_692, %e2_693, %e3_694 = cute.get_leaves(%532) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_695 = cute.to_int_tuple(%e1_692) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_696 = cute.make_coord(%e1_687) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_697 = cute.make_coord(%itup_695) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %533 = cute.get_scalars(%coord_696) : !cute.coord<"?">
      %534 = cute.get_scalars(%coord_697) : !cute.coord<"?">
      %535 = arith.cmpi slt, %533, %534 : i32
      scf.if %535 {
        %iter_698 = cute.get_iter(%rmem_592) : !memref_rmem_bf16_5
        %ptr_699 = cute.add_offset(%iter_698, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_700 = cute.crd2idx(%83, %lay_591) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_701 = cute.add_offset(%ptr_588, %idx_700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_702 = cute.get_iter(%rmem_621) : !memref_rmem_i8_
        %536 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %536 step %c1_i32  : i32 {
          %coord_703 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_704 = cute.crd2idx(%coord_703, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_705 = cute.add_offset(%ptr_699, %idx_704) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_706 = cute.crd2idx(%coord_703, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_707 = cute.add_offset(%ptr_701, %idx_706) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_708 = cute.crd2idx(%coord_703, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_709 = cute.add_offset(%iter_702, %idx_708) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %537 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<i8, rmem> to !llvm.ptr
          %538 = llvm.load %537 : !llvm.ptr -> i8
          %539 = llvm.icmp "ne" %538, %0 : i8
          scf.if %539 {
            %540 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %541 = builtin.unrealized_conversion_cast %ptr_707 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %542 = llvm.load %540 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %542, %541 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass___call_____main__HSTUAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Ten(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c57344_i64 = arith.constant 57344 : i64
    %c0_i32 = arith.constant 0 : i32
    %c4_i32 = arith.constant 4 : i32
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c64_i32 = arith.constant 64 : i32
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
    %0 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %1 = cute.make_tiled_copy(%atom_0) : !copy_simt1
    %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %2 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0, %e1, %e2, %e3 = cute.get_leaves(%2) : !cute.shape<"(?,?,?,?{div=8})">
    %itup = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %4 = arith.ceildivsi %3, %c64_i32 : i32
    %int_tuple_1 = cute.make_int_tuple(%4) : (i32) -> !cute.int_tuple<"?">
    %e0_2 = cute.get_leaves(%int_tuple_1) : !cute.int_tuple<"?">
    %5 = cute.get_scalars(%e0_2) : !cute.int_tuple<"?">
    %6 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c57344_i64, gridDim = (%c4_i32, %c4_i32, %5), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %7 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gm_0<%6> (%arg0, %arg1, %arg2, %arg3, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_) -> !cuda.result
    %8 = cuda.cast %7 : !cuda.result -> i32
    cuda.return_if_error %8 : i32
    return %c0_i32 : i32
  }
}
