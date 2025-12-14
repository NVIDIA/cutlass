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
      %129:7 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%129#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%129#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_17 = cute.assume(%129#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_17) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_18 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_19 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %130 = cute.get_scalars(%coord_19) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_20 = cute.make_coord(%130) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %131:3 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %132 = arith.ceildivsi %131#0, %c64_i32 : i32
      %133 = arith.muli %131#2, %c64_i64 : i64
      %134 = arith.ceildivsi %131#1, %c128_i32 : i32
      %shape_21 = cute.make_shape(%132, %134) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_22 = cute.assume(%131#2) : (i64) -> !cute.i64<divby 8>
      %iv_23 = cute.assume(%133) : (i64) -> !cute.i64<divby 512>
      %stride_24 = cute.make_stride(%iv_22, %iv_23) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_25 = cute.make_layout(%shape_21, %stride_24) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %135:4 = cute.get_scalars(%lay_25) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_26 = cute.assume(%135#2) : (i64) -> !cute.i64<divby 8>
      %stride_27 = cute.make_stride(%iv_26) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_28 = cute.make_layout(%115, %stride_27) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_29 = cute.crd2idx(%coord_20, %lay_25) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_30 = cute.add_offset(%ptr, %idx_29) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %136:7 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_31 = cute.assume(%136#3) : (i32) -> !cute.i32<divby 8>
      %shape_32 = cute.make_shape(%136#1, %iv_31) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_33 = cute.assume(%136#5) : (i64) -> !cute.i64<divby 8>
      %stride_34 = cute.make_stride(%iv_33) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_35 = cute.make_layout(%shape_32, %stride_34) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_36 = cute.crd2idx(%coord, %lay_7) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_37 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_38 = cute.add_offset(%iter_37, %idx_36) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %137:3 = cute.get_scalars(%lay_35) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %138 = arith.ceildivsi %137#0, %c64_i32 : i32
      %139 = arith.muli %137#2, %c64_i64 : i64
      %140 = arith.ceildivsi %137#1, %c128_i32 : i32
      %shape_39 = cute.make_shape(%138, %140) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_40 = cute.assume(%137#2) : (i64) -> !cute.i64<divby 8>
      %iv_41 = cute.assume(%139) : (i64) -> !cute.i64<divby 512>
      %stride_42 = cute.make_stride(%iv_40, %iv_41) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_43 = cute.make_layout(%shape_39, %stride_42) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %141:4 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_44 = cute.make_shape(%141#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_45 = cute.assume(%141#2) : (i64) -> !cute.i64<divby 8>
      %iv_46 = cute.assume(%141#3) : (i64) -> !cute.i64<divby 512>
      %stride_47 = cute.make_stride(%iv_45, %iv_46) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_48 = cute.make_layout(%shape_44, %stride_47) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %lay_49 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %142:7 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_50 = cute.assume(%142#3) : (i32) -> !cute.i32<divby 8>
      %shape_51 = cute.make_shape(%142#1, %iv_50) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_52 = cute.assume(%142#5) : (i64) -> !cute.i64<divby 8>
      %stride_53 = cute.make_stride(%iv_52) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_54 = cute.make_layout(%shape_51, %stride_53) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_55 = cute.crd2idx(%coord, %lay_49) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_56 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_57 = cute.add_offset(%iter_56, %idx_55) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %143:3 = cute.get_scalars(%lay_54) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %144 = arith.ceildivsi %143#0, %c64_i32 : i32
      %145 = arith.muli %143#2, %c64_i64 : i64
      %146 = arith.ceildivsi %143#1, %c128_i32 : i32
      %shape_58 = cute.make_shape(%144, %146) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_59 = cute.assume(%143#2) : (i64) -> !cute.i64<divby 8>
      %iv_60 = cute.assume(%145) : (i64) -> !cute.i64<divby 512>
      %stride_61 = cute.make_stride(%iv_59, %iv_60) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_62 = cute.make_layout(%shape_58, %stride_61) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %147:4 = cute.get_scalars(%lay_62) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_63 = cute.make_shape(%147#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_64 = cute.assume(%147#2) : (i64) -> !cute.i64<divby 8>
      %iv_65 = cute.assume(%147#3) : (i64) -> !cute.i64<divby 512>
      %stride_66 = cute.make_stride(%iv_64, %iv_65) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_67 = cute.make_layout(%shape_63, %stride_66) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %coord_68 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %lay_69 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %148:7 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_70 = cute.assume(%148#3) : (i32) -> !cute.i32<divby 8>
      %shape_71 = cute.make_shape(%148#2, %iv_70) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_72 = cute.assume(%148#6) : (i64) -> !cute.i64<divby 8>
      %stride_73 = cute.make_stride(%iv_72) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_74 = cute.make_layout(%shape_71, %stride_73) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_75 = cute.crd2idx(%coord_68, %lay_69) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_76 = cute.get_iter(%arg4) : !memref_gmem_bf16_
      %ptr_77 = cute.add_offset(%iter_76, %idx_75) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_78 = cute.make_coord(%sub_6) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %149 = cute.get_scalars(%coord_78) <{only_dynamic}> : !cute.coord<"(?,_)">
      %coord_79 = cute.make_coord(%149) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %150:3 = cute.get_scalars(%lay_74) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %151 = arith.ceildivsi %150#0, %c64_i32 : i32
      %152 = arith.muli %150#2, %c64_i64 : i64
      %153 = arith.ceildivsi %150#1, %c64_i32 : i32
      %shape_80 = cute.make_shape(%151, %153) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %iv_81 = cute.assume(%150#2) : (i64) -> !cute.i64<divby 8>
      %iv_82 = cute.assume(%152) : (i64) -> !cute.i64<divby 512>
      %stride_83 = cute.make_stride(%iv_81, %iv_82) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},64))">
      %lay_84 = cute.make_layout(%shape_80, %stride_83) : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %154:4 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %shape_85 = cute.make_shape(%154#1) : (i32) -> !cute.shape<"(64,64,?)">
      %iv_86 = cute.assume(%154#2) : (i64) -> !cute.i64<divby 8>
      %stride_87 = cute.make_stride(%iv_86) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1,64)">
      %lay_88 = cute.make_layout(%shape_85, %stride_87) : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %idx_89 = cute.crd2idx(%coord_79, %lay_84) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_90 = cute.add_offset(%ptr_77, %idx_89) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_91 = cute.add_offset(%smem_ptr, %114) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_92 = cute.add_offset(%smem_ptr, %113) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_93 = cute.add_offset(%smem_ptr, %112) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_94 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_95 = cute.recast_iter(%ptr_91) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_96 = cute.recast_iter(%ptr_92) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_97 = cute.recast_iter(%ptr_93) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %coord_98 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %155 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %156 = cute.get_scalars(%coord_98) <{only_dynamic}> : !cute.coord<"?">
      %157 = arith.muli %155, %c16_i64 : i64
      %158 = arith.divsi %156, %c8_i32 : i32
      %159 = arith.remsi %156, %c8_i32 : i32
      %160 = arith.muli %159, %c8_i32 : i32
      %161 = arith.extsi %158 : i32 to i64
      %162 = arith.muli %161, %155 : i64
      %163 = arith.extsi %160 : i32 to i64
      %164 = arith.addi %163, %162 : i64
      %iv_99 = cute.assume(%164) : (i64) -> !cute.i64<divby 8>
      %int_tuple_100 = cute.make_int_tuple(%iv_99) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_101 = cute.add_offset(%ptr_30, %int_tuple_100) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_102 = cute.assume(%157) : (i64) -> !cute.i64<divby 128>
      %stride_103 = cute.make_stride(%iv_102) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_104 = cute.make_layout(%111, %stride_103) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %165 = arith.divsi %159, %c2_i32 : i32
      %166 = arith.muli %165, %c16_i32 : i32
      %167 = arith.muli %158, %c64_i32 : i32
      %168 = arith.addi %166, %167 : i32
      %169 = arith.remsi %159, %c2_i32 : i32
      %170 = arith.muli %169, %c8_i32 : i32
      %171 = arith.andi %168, %c896_i32 : i32
      %172 = arith.shrsi %171, %c3_i32 : i32
      %173 = arith.xori %168, %172 : i32
      %174 = arith.addi %173, %170 : i32
      %iv_105 = cute.assume(%174) : (i32) -> !cute.i32<divby 8>
      %int_tuple_106 = cute.make_int_tuple(%iv_105) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_107 = cute.add_offset(%iter_94, %int_tuple_106) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %175:3 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %176 = arith.muli %175#1, %c16_i64 : i64
      %177 = arith.muli %161, %175#1 : i64
      %178 = arith.addi %163, %177 : i64
      %iv_108 = cute.assume(%178) : (i64) -> !cute.i64<divby 8>
      %int_tuple_109 = cute.make_int_tuple(%iv_108) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_110 = cute.add_offset(%ptr_38, %int_tuple_109) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_111 = cute.make_shape(%175#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_112 = cute.assume(%176) : (i64) -> !cute.i64<divby 128>
      %iv_113 = cute.assume(%175#2) : (i64) -> !cute.i64<divby 512>
      %stride_114 = cute.make_stride(%iv_112, %iv_113) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_115 = cute.make_layout(%shape_111, %stride_114) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_116 = cute.add_offset(%iter_95, %int_tuple_106) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %179:3 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %180 = arith.muli %179#1, %c16_i64 : i64
      %181 = arith.muli %161, %179#1 : i64
      %182 = arith.addi %163, %181 : i64
      %iv_117 = cute.assume(%182) : (i64) -> !cute.i64<divby 8>
      %int_tuple_118 = cute.make_int_tuple(%iv_117) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_119 = cute.add_offset(%ptr_57, %int_tuple_118) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_120 = cute.make_shape(%179#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_121 = cute.assume(%180) : (i64) -> !cute.i64<divby 128>
      %iv_122 = cute.assume(%179#2) : (i64) -> !cute.i64<divby 512>
      %stride_123 = cute.make_stride(%iv_121, %iv_122) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_124 = cute.make_layout(%shape_120, %stride_123) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_125 = cute.add_offset(%iter_96, %int_tuple_106) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %183:2 = cute.get_scalars(%lay_88) <{only_dynamic}> : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %184 = arith.muli %183#1, %c16_i64 : i64
      %185 = arith.muli %161, %183#1 : i64
      %186 = arith.addi %163, %185 : i64
      %iv_126 = cute.assume(%186) : (i64) -> !cute.i64<divby 8>
      %int_tuple_127 = cute.make_int_tuple(%iv_126) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_128 = cute.add_offset(%ptr_90, %int_tuple_127) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_129 = cute.make_shape(%183#0) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %iv_130 = cute.assume(%184) : (i64) -> !cute.i64<divby 128>
      %stride_131 = cute.make_stride(%iv_130) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},0,64)">
      %lay_132 = cute.make_layout(%shape_129, %stride_131) : !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
      %ptr_133 = cute.add_offset(%iter_97, %int_tuple_106) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_134 = cute.memref.alloca() : !memref_rmem_bf16_1
      %rmem_135 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_136 = cute.memref.alloca() : !memref_rmem_f32_
      cute.memref.store_vec %cst_2, %rmem_136 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_137 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %187 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %188 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %189 = cute.make_tiled_copy(%atom_137) : !copy_ldsm_4_2
      %190 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_3
      %191 = arith.remsi %156, %c16_i32 : i32
      %192 = arith.muli %191, %c64_i32 : i32
      %193 = arith.divsi %156, %c16_i32 : i32
      %194 = arith.divsi %193, %c2_i32 : i32
      %195 = arith.remsi %193, %c2_i32 : i32
      %196 = arith.muli %195, %c8_i32 : i32
      %197 = arith.muli %194, %c1024_i32 : i32
      %198 = arith.addi %196, %197 : i32
      %199 = arith.andi %192, %c128_i32 : i32
      %200 = arith.cmpi eq, %199, %c0_i32 : i32
      %201 = arith.select %200, %c16_i32, %c-16_i32 : i32
      %202 = arith.andi %192, %c256_i32 : i32
      %203 = arith.cmpi eq, %202, %c0_i32 : i32
      %204 = arith.select %203, %c32_i32, %c-32_i32 : i32
      %205 = arith.andi %192, %c896_i32 : i32
      %206 = arith.shrsi %205, %c3_i32 : i32
      %207 = arith.xori %192, %206 : i32
      %208 = arith.addi %207, %198 : i32
      %iv_138 = cute.assume(%208) : (i32) -> !cute.i32<divby 8>
      %int_tuple_139 = cute.make_int_tuple(%iv_138) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_140 = cute.add_offset(%iter_94, %int_tuple_139) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_141 = cute.assume(%201) : (i32) -> !cute.i32<divby 16>
      %iv_142 = cute.assume(%204) : (i32) -> !cute.i32<divby 32>
      %stride_143 = cute.make_stride(%iv_141, %iv_142) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,((?{div=16},?{div=32}),4096))">
      %lay_144 = cute.make_layout(%109, %stride_143) : !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
      %iter_145 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %209 = arith.muli %159, %c64_i32 : i32
      %210 = arith.divsi %158, %c2_i32 : i32
      %211 = arith.remsi %210, %c2_i32 : i32
      %212 = arith.muli %211, %c512_i32 : i32
      %213 = arith.addi %209, %212 : i32
      %214 = arith.remsi %158, %c2_i32 : i32
      %215 = arith.muli %214, %c8_i32 : i32
      %216 = arith.andi %213, %c128_i32 : i32
      %217 = arith.cmpi eq, %216, %c0_i32 : i32
      %218 = arith.select %217, %c16_i32, %c-16_i32 : i32
      %219 = arith.andi %213, %c256_i32 : i32
      %220 = arith.cmpi eq, %219, %c0_i32 : i32
      %221 = arith.select %220, %c32_i32, %c-32_i32 : i32
      %222 = arith.andi %213, %c896_i32 : i32
      %223 = arith.shrsi %222, %c3_i32 : i32
      %224 = arith.xori %213, %223 : i32
      %225 = arith.addi %224, %215 : i32
      %iv_146 = cute.assume(%225) : (i32) -> !cute.i32<divby 8>
      %int_tuple_147 = cute.make_int_tuple(%iv_146) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_148 = cute.add_offset(%iter_95, %int_tuple_147) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_149 = cute.assume(%218) : (i32) -> !cute.i32<divby 16>
      %iv_150 = cute.assume(%221) : (i32) -> !cute.i32<divby 32>
      %stride_151 = cute.make_stride(%iv_149, %iv_150) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_152 = cute.make_layout(%108, %stride_151) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %iter_153 = cute.get_iter(%rmem_134) : !memref_rmem_bf16_1
      %226 = arith.addi %207, %196 : i32
      %iv_154 = cute.assume(%226) : (i32) -> !cute.i32<divby 8>
      %int_tuple_155 = cute.make_int_tuple(%iv_154) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_156 = cute.add_offset(%iter_96, %int_tuple_155) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_157 = cute.make_stride(%iv_141, %iv_142) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_158 = cute.make_layout(%107, %stride_157) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iter_159 = cute.get_iter(%rmem_135) : !memref_rmem_bf16_2
      %ptr_160 = cute.add_offset(%iter_97, %int_tuple_139) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_161 = cute.make_stride(%iv_141, %iv_142) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_162 = cute.make_layout(%106, %stride_161) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %itup_163 = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_164 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_165 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_166 = cute.make_shape(%itup_163, %itup, %itup_164, %itup_165) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_167 = cute.make_layout(%shape_166, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %itup_168 = cute.to_int_tuple(%e0_8) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_169 = cute.to_int_tuple(%e2_10) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_170 = cute.to_int_tuple(%e3_11) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_171 = cute.make_shape(%itup_168, %itup_12, %itup_169, %itup_170) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_172 = cute.make_layout(%shape_171, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %227 = cute.get_shape(%lay_69) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_173, %e1_174, %e2_175, %e3_176 = cute.get_leaves(%227) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_177 = cute.to_int_tuple(%e0_173) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_178 = cute.to_int_tuple(%e1_174) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_179 = cute.to_int_tuple(%e2_175) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_180 = cute.to_int_tuple(%e3_176) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_181 = cute.make_shape(%itup_177, %itup_178, %itup_179, %itup_180) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_182 = cute.make_layout(%shape_181, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %228:4 = cute.get_scalars(%lay_167) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_183 = cute.assume(%228#3) : (i32) -> !cute.i32<divby 8>
      %shape_184 = cute.make_shape(%228#1, %iv_183) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_185 = cute.make_layout(%shape_184, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_186 = cute.crd2idx(%coord, %lay_167) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup = cute.add_offset(%105, %idx_186) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %229:2 = cute.get_scalars(%lay_185) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %230 = arith.ceildivsi %229#0, %c64_i32 : i32
      %231 = arith.ceildivsi %229#1, %c128_i32 : i32
      %shape_187 = cute.make_shape(%230, %231) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_188 = cute.make_layout(%shape_187, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_189 = cute.crd2idx(%coord_20, %lay_188) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_190 = cute.add_offset(%tup, %idx_189) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %232:4 = cute.get_scalars(%lay_172) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_191 = cute.assume(%232#3) : (i32) -> !cute.i32<divby 8>
      %shape_192 = cute.make_shape(%232#1, %iv_191) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_193 = cute.make_layout(%shape_192, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_194 = cute.crd2idx(%coord, %lay_172) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_195 = cute.add_offset(%105, %idx_194) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_196 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %233 = cute.get_scalars(%coord_196) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_197 = cute.make_coord(%233) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %234:2 = cute.get_scalars(%lay_193) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %235 = arith.ceildivsi %234#0, %c64_i32 : i32
      %236 = arith.ceildivsi %234#1, %c128_i32 : i32
      %shape_198 = cute.make_shape(%235, %236) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_199 = cute.make_layout(%shape_198, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_200 = cute.crd2idx(%coord_197, %lay_199) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_201 = cute.add_offset(%tup_195, %idx_200) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %237:4 = cute.get_scalars(%lay_182) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_202 = cute.assume(%237#3) : (i32) -> !cute.i32<divby 8>
      %shape_203 = cute.make_shape(%237#2, %iv_202) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_204 = cute.make_layout(%shape_203, %101) : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %idx_205 = cute.crd2idx(%coord_68, %lay_182) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,?,0,0)">
      %tup_206 = cute.add_offset(%105, %idx_205) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,?,0,0)">) -> !cute.int_tuple<"(?,?,0,0)">
      %238:2 = cute.get_scalars(%lay_204) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %239 = arith.ceildivsi %238#0, %c64_i32 : i32
      %240 = arith.ceildivsi %238#1, %c64_i32 : i32
      %shape_207 = cute.make_shape(%239, %240) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %lay_208 = cute.make_layout(%shape_207, %100) : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %241:2 = cute.get_scalars(%lay_208) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %shape_209 = cute.make_shape(%241#1) : (i32) -> !cute.shape<"(64,64,?)">
      %lay_210 = cute.make_layout(%shape_209, %99) : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %idx_211 = cute.crd2idx(%coord_79, %lay_208) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">) -> !cute.int_tuple<"(0,0,?{div=64},0)">
      %tup_212 = cute.add_offset(%tup_206, %idx_211) : (!cute.int_tuple<"(?,?,0,0)">, !cute.int_tuple<"(0,0,?{div=64},0)">) -> !cute.int_tuple<"(?,?,?{div=64},0)">
      %iv_213 = cute.assume(%160) : (i32) -> !cute.i32<divby 8>
      %int_tuple_214 = cute.make_int_tuple(%158, %iv_213) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_215 = cute.add_offset(%tup_190, %int_tuple_214) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %tup_216 = cute.add_offset(%tup_201, %int_tuple_214) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %242 = cute.get_scalars(%lay_210) <{only_dynamic}> : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %int_tuple_217 = cute.make_int_tuple(%158, %iv_213) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,0,?,?{div=8})">
      %tup_218 = cute.add_offset(%tup_212, %int_tuple_217) : (!cute.int_tuple<"(?,?,?{div=64},0)">, !cute.int_tuple<"(0,0,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %shape_219 = cute.make_shape(%242) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %lay_220 = cute.make_layout(%shape_219, %98) : !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %rmem_221 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_222 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_223, %e1_224, %e2_225, %e3_226 = cute.get_leaves(%tup_215) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_227 = cute.make_coord(%e3_226) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_228 = cute.make_coord(%itup_165) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %243 = cute.get_scalars(%coord_227) : !cute.coord<"?{div=8}">
      %244 = cute.get_scalars(%coord_228) : !cute.coord<"?{div=8}">
      %245 = arith.cmpi slt, %243, %244 : i32
      %246 = arith.extui %245 : i1 to i8
      cute.memref.store(%rmem_221, %97, %246) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_229 = cute.add_offset(%tup_215, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_230, %e1_231, %e2_232, %e3_233 = cute.get_leaves(%tup_229) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_234 = cute.make_coord(%e3_233) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %247 = cute.get_scalars(%coord_234) : !cute.coord<"?{div=8}">
      %248 = arith.cmpi slt, %247, %244 : i32
      %249 = arith.extui %248 : i1 to i8
      cute.memref.store(%rmem_221, %95, %249) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_235, %e1_236, %e2_237, %e3_238 = cute.get_leaves(%tup_216) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_239 = cute.make_coord(%e3_238) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_240 = cute.make_coord(%itup_170) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %250 = cute.get_scalars(%coord_239) : !cute.coord<"?{div=8}">
      %251 = cute.get_scalars(%coord_240) : !cute.coord<"?{div=8}">
      %252 = arith.cmpi slt, %250, %251 : i32
      %253 = arith.extui %252 : i1 to i8
      cute.memref.store(%rmem_222, %97, %253) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_241 = cute.add_offset(%tup_216, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_242, %e1_243, %e2_244, %e3_245 = cute.get_leaves(%tup_241) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_246 = cute.make_coord(%e3_245) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %254 = cute.get_scalars(%coord_246) : !cute.coord<"?{div=8}">
      %255 = arith.cmpi slt, %254, %251 : i32
      %256 = arith.extui %255 : i1 to i8
      cute.memref.store(%rmem_222, %95, %256) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_247 = cute.make_coord(%e1_224) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_248 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %257 = cute.get_scalars(%coord_247) : !cute.coord<"?">
      %258 = cute.get_scalars(%coord_248) : !cute.coord<"?">
      %259 = arith.cmpi slt, %257, %258 : i32
      scf.if %259 {
        %iter_416 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_417 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_418 = cute.crd2idx(%coord_417, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_419 = cute.add_offset(%ptr_101, %idx_418) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_420 = cute.crd2idx(%coord_417, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_421 = cute.add_offset(%ptr_107, %idx_420) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_422 = cute.crd2idx(%coord_417, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_423 = cute.add_offset(%iter_416, %idx_422) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_423 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_424 = cute.recast_iter(%ptr_419) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_425 = cute.recast_iter(%ptr_421) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_425 : !cute.ptr<i128, smem>, %iter_424 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_107) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_249 = cute.add_offset(%tup_215, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_250, %e1_251, %e2_252, %e3_253 = cute.get_leaves(%tup_249) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_254 = cute.make_coord(%e1_251) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %260 = cute.get_scalars(%coord_254) : !cute.coord<"?">
      %261 = arith.cmpi slt, %260, %258 : i32
      scf.if %261 {
        %idx_416 = cute.crd2idx(%89, %lay_104) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_417 = cute.add_offset(%ptr_101, %idx_416) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_418 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_419 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_422 = cute.add_offset(%ptr_417, %idx_421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_427 = cute.recast_iter(%ptr_422) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_428 = cute.recast_iter(%ptr_424) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_428 : !cute.ptr<i128, smem>, %iter_427 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_255 = cute.add_offset(%tup_215, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_256, %e1_257, %e2_258, %e3_259 = cute.get_leaves(%tup_255) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_260 = cute.make_coord(%e1_257) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %262 = cute.get_scalars(%coord_260) : !cute.coord<"?">
      %263 = arith.cmpi slt, %262, %258 : i32
      scf.if %263 {
        %idx_416 = cute.crd2idx(%86, %lay_104) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_417 = cute.add_offset(%ptr_101, %idx_416) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_418 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_419 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_422 = cute.add_offset(%ptr_417, %idx_421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_427 = cute.recast_iter(%ptr_422) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_428 = cute.recast_iter(%ptr_424) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_428 : !cute.ptr<i128, smem>, %iter_427 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_261 = cute.add_offset(%tup_215, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_262, %e1_263, %e2_264, %e3_265 = cute.get_leaves(%tup_261) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_266 = cute.make_coord(%e1_263) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %264 = cute.get_scalars(%coord_266) : !cute.coord<"?">
      %265 = arith.cmpi slt, %264, %258 : i32
      scf.if %265 {
        %idx_416 = cute.crd2idx(%83, %lay_104) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_417 = cute.add_offset(%ptr_101, %idx_416) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_418 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_419 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_422 = cute.add_offset(%ptr_417, %idx_421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_427 = cute.recast_iter(%ptr_422) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_428 = cute.recast_iter(%ptr_424) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_428 : !cute.ptr<i128, smem>, %iter_427 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %coord_267 = cute.make_coord(%e1_236) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_268 = cute.make_coord(%itup_12) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %266 = cute.get_scalars(%coord_267) : !cute.coord<"?">
      %267 = cute.get_scalars(%coord_268) : !cute.coord<"?">
      %268 = arith.cmpi slt, %266, %267 : i32
      scf.if %268 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_115) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %ptr_418 = cute.add_offset(%ptr_110, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_419 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_422 = cute.add_offset(%ptr_418, %idx_421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_424 = cute.add_offset(%ptr_116, %idx_423) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_427 = cute.recast_iter(%ptr_422) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_428 = cute.recast_iter(%ptr_424) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_428 : !cute.ptr<i128, smem>, %iter_427 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_116) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_269 = cute.add_offset(%tup_216, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_270, %e1_271, %e2_272, %e3_273 = cute.get_leaves(%tup_269) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_274 = cute.make_coord(%e1_271) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %269 = cute.get_scalars(%coord_274) : !cute.coord<"?">
      %270 = arith.cmpi slt, %269, %267 : i32
      scf.if %270 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_115) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_418 = cute.add_offset(%ptr_110, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_420 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_421 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_422 = cute.crd2idx(%coord_421, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_423 = cute.add_offset(%ptr_418, %idx_422) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_424 = cute.crd2idx(%coord_421, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_425 = cute.add_offset(%ptr_419, %idx_424) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_426 = cute.crd2idx(%coord_421, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_427 = cute.add_offset(%iter_420, %idx_426) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_427 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_428 = cute.recast_iter(%ptr_423) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_429 = cute.recast_iter(%ptr_425) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_429 : !cute.ptr<i128, smem>, %iter_428 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_275 = cute.add_offset(%tup_216, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_276, %e1_277, %e2_278, %e3_279 = cute.get_leaves(%tup_275) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_280 = cute.make_coord(%e1_277) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %271 = cute.get_scalars(%coord_280) : !cute.coord<"?">
      %272 = arith.cmpi slt, %271, %267 : i32
      scf.if %272 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_115) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_418 = cute.add_offset(%ptr_110, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_420 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_421 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_422 = cute.crd2idx(%coord_421, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_423 = cute.add_offset(%ptr_418, %idx_422) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_424 = cute.crd2idx(%coord_421, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_425 = cute.add_offset(%ptr_419, %idx_424) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_426 = cute.crd2idx(%coord_421, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_427 = cute.add_offset(%iter_420, %idx_426) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_427 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_428 = cute.recast_iter(%ptr_423) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_429 = cute.recast_iter(%ptr_425) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_429 : !cute.ptr<i128, smem>, %iter_428 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_281 = cute.add_offset(%tup_216, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_282, %e1_283, %e2_284, %e3_285 = cute.get_leaves(%tup_281) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_286 = cute.make_coord(%e1_283) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %273 = cute.get_scalars(%coord_286) : !cute.coord<"?">
      %274 = arith.cmpi slt, %273, %267 : i32
      scf.if %274 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_115) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_418 = cute.add_offset(%ptr_110, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_420 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_421 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_422 = cute.crd2idx(%coord_421, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_423 = cute.add_offset(%ptr_418, %idx_422) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_424 = cute.crd2idx(%coord_421, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_425 = cute.add_offset(%ptr_419, %idx_424) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_426 = cute.crd2idx(%coord_421, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_427 = cute.add_offset(%iter_420, %idx_426) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_427 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_428 = cute.recast_iter(%ptr_423) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_429 = cute.recast_iter(%ptr_425) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_429 : !cute.ptr<i128, smem>, %iter_428 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %coord_287 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %idx_288 = cute.crd2idx(%coord_287, %lay_220) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %tup_289 = cute.add_offset(%tup_218, %idx_288) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_290, %e1_291, %e2_292, %e3_293 = cute.get_leaves(%tup_289) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_294 = cute.make_coord(%e1_291) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_295 = cute.make_coord(%itup_179) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %275 = cute.get_scalars(%coord_294) : !cute.coord<"?">
      %276 = cute.get_scalars(%coord_295) : !cute.coord<"?">
      %277 = arith.cmpi slt, %275, %276 : i32
      %coord_296 = cute.make_coord(%e2_292) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_297 = cute.make_coord(%itup_180) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %278 = cute.get_scalars(%coord_296) : !cute.coord<"?">
      %279 = cute.get_scalars(%coord_297) : !cute.coord<"?{div=8}">
      %280 = arith.cmpi slt, %278, %279 : i32
      %281 = arith.extui %277 : i1 to i32
      %282 = arith.extui %280 : i1 to i32
      %283 = arith.select %277, %282, %281 : i32
      %284 = arith.cmpi ne, %283, %c0_i32 : i32
      scf.if %284 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_132) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
        %ptr_418 = cute.add_offset(%ptr_128, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %354 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %iter_419 = cute.recast_iter(%ptr_418) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_420 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_420 : !cute.ptr<i128, smem>, %iter_419 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %view = cute.make_view(%ptr_133) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_298 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %idx_299 = cute.crd2idx(%coord_298, %lay_220) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %tup_300 = cute.add_offset(%tup_218, %idx_299) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_301, %e1_302, %e2_303, %e3_304 = cute.get_leaves(%tup_300) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_305 = cute.make_coord(%e1_302) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %285 = cute.get_scalars(%coord_305) : !cute.coord<"?">
      %286 = arith.cmpi slt, %285, %276 : i32
      %coord_306 = cute.make_coord(%e2_303) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %287 = cute.get_scalars(%coord_306) : !cute.coord<"?">
      %288 = arith.cmpi slt, %287, %279 : i32
      %289 = arith.extui %286 : i1 to i32
      %290 = arith.extui %288 : i1 to i32
      %291 = arith.select %286, %290, %289 : i32
      %292 = arith.cmpi ne, %291, %c0_i32 : i32
      scf.if %292 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_132) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_418 = cute.add_offset(%ptr_128, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %354 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %iter_420 = cute.recast_iter(%ptr_418) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_421 = cute.recast_iter(%ptr_419) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_421 : !cute.ptr<i128, smem>, %iter_420 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_307 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %idx_308 = cute.crd2idx(%coord_307, %lay_220) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %tup_309 = cute.add_offset(%tup_218, %idx_308) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_310, %e1_311, %e2_312, %e3_313 = cute.get_leaves(%tup_309) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_314 = cute.make_coord(%e1_311) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %293 = cute.get_scalars(%coord_314) : !cute.coord<"?">
      %294 = arith.cmpi slt, %293, %276 : i32
      %coord_315 = cute.make_coord(%e2_312) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %295 = cute.get_scalars(%coord_315) : !cute.coord<"?">
      %296 = arith.cmpi slt, %295, %279 : i32
      %297 = arith.extui %294 : i1 to i32
      %298 = arith.extui %296 : i1 to i32
      %299 = arith.select %294, %298, %297 : i32
      %300 = arith.cmpi ne, %299, %c0_i32 : i32
      scf.if %300 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_132) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_418 = cute.add_offset(%ptr_128, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %354 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %iter_420 = cute.recast_iter(%ptr_418) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_421 = cute.recast_iter(%ptr_419) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_421 : !cute.ptr<i128, smem>, %iter_420 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      %coord_316 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %idx_317 = cute.crd2idx(%coord_316, %lay_220) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %tup_318 = cute.add_offset(%tup_218, %idx_317) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_319, %e1_320, %e2_321, %e3_322 = cute.get_leaves(%tup_318) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_323 = cute.make_coord(%e1_320) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %301 = cute.get_scalars(%coord_323) : !cute.coord<"?">
      %302 = arith.cmpi slt, %301, %276 : i32
      %coord_324 = cute.make_coord(%e2_321) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %303 = cute.get_scalars(%coord_324) : !cute.coord<"?">
      %304 = arith.cmpi slt, %303, %279 : i32
      %305 = arith.extui %302 : i1 to i32
      %306 = arith.extui %304 : i1 to i32
      %307 = arith.select %302, %306, %305 : i32
      %308 = arith.cmpi ne, %307, %c0_i32 : i32
      scf.if %308 {
        %coord_416 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %idx_417 = cute.crd2idx(%coord_416, %lay_132) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_418 = cute.add_offset(%ptr_128, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_419 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %354 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %iter_420 = cute.recast_iter(%ptr_418) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_421 = cute.recast_iter(%ptr_419) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_421 : !cute.ptr<i128, smem>, %iter_420 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_416 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_416) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      nvvm.cp.async.commit.group
      %tup_325 = cute.add_offset(%sub_16, %81) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      scf.for %arg5 = %c-1_i32 to %128 step %c1_i32  : i32 {
        %int_tuple_416 = cute.make_int_tuple(%arg5) : (i32) -> !cute.int_tuple<"?">
        %sub_417 = cute.tuple_sub(%tup_325, %int_tuple_416) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %354 = cute.get_scalars(%sub_417) : !cute.int_tuple<"?">
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %355 = arith.cmpi eq, %354, %128 : i32
        scf.if %355 {
          %440 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_501, %e1_502, %e2_503, %e3_504 = cute.get_leaves(%440) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_505 = cute.to_int_tuple(%e1_502) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_506 = cute.make_coord(%itup_505) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %441 = cute.get_scalars(%coord_506) : !cute.coord<"?">
          %442 = arith.cmpi slt, %266, %441 : i32
          scf.if %442 {
            %coord_507 = cute.make_coord(%sub_417) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_508 = cute.crd2idx(%coord_507, %lay_124) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
            %ptr_509 = cute.add_offset(%ptr_119, %idx_508) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
            %iter_510 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %446 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %446 step %c1_i32  : i32 {
              %coord_511 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_512 = cute.crd2idx(%coord_511, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_513 = cute.add_offset(%ptr_509, %idx_512) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_514 = cute.crd2idx(%coord_511, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_515 = cute.add_offset(%ptr_125, %idx_514) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_516 = cute.crd2idx(%coord_511, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_517 = cute.add_offset(%iter_510, %idx_516) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %447 = builtin.unrealized_conversion_cast %ptr_517 : !cute.ptr<i8, rmem> to !llvm.ptr
              %448 = llvm.load %447 : !llvm.ptr -> i8
              %449 = llvm.trunc %448 : i8 to i1
              %iter_518 = cute.recast_iter(%ptr_513) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_519 = cute.recast_iter(%ptr_515) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_519 : !cute.ptr<i128, smem>, %iter_518 : !cute.ptr<i128, gmem>, %449 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_125) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %443 = arith.cmpi slt, %269, %441 : i32
          scf.if %443 {
            %coord_507 = cute.make_coord(%sub_417) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_508 = cute.crd2idx(%coord_507, %lay_124) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_509 = cute.add_offset(%ptr_119, %idx_508) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_510 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_511 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %446 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %446 step %c1_i32  : i32 {
              %coord_512 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_513 = cute.crd2idx(%coord_512, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_514 = cute.add_offset(%ptr_509, %idx_513) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_515 = cute.crd2idx(%coord_512, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_516 = cute.add_offset(%ptr_510, %idx_515) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_517 = cute.crd2idx(%coord_512, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_518 = cute.add_offset(%iter_511, %idx_517) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %447 = builtin.unrealized_conversion_cast %ptr_518 : !cute.ptr<i8, rmem> to !llvm.ptr
              %448 = llvm.load %447 : !llvm.ptr -> i8
              %449 = llvm.trunc %448 : i8 to i1
              %iter_519 = cute.recast_iter(%ptr_514) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_520 = cute.recast_iter(%ptr_516) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_520 : !cute.ptr<i128, smem>, %iter_519 : !cute.ptr<i128, gmem>, %449 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_507 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_507) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %444 = arith.cmpi slt, %271, %441 : i32
          scf.if %444 {
            %coord_507 = cute.make_coord(%sub_417) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_508 = cute.crd2idx(%coord_507, %lay_124) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
            %ptr_509 = cute.add_offset(%ptr_119, %idx_508) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_510 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_511 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %446 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %446 step %c1_i32  : i32 {
              %coord_512 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_513 = cute.crd2idx(%coord_512, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_514 = cute.add_offset(%ptr_509, %idx_513) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_515 = cute.crd2idx(%coord_512, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_516 = cute.add_offset(%ptr_510, %idx_515) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_517 = cute.crd2idx(%coord_512, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_518 = cute.add_offset(%iter_511, %idx_517) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %447 = builtin.unrealized_conversion_cast %ptr_518 : !cute.ptr<i8, rmem> to !llvm.ptr
              %448 = llvm.load %447 : !llvm.ptr -> i8
              %449 = llvm.trunc %448 : i8 to i1
              %iter_519 = cute.recast_iter(%ptr_514) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_520 = cute.recast_iter(%ptr_516) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_520 : !cute.ptr<i128, smem>, %iter_519 : !cute.ptr<i128, gmem>, %449 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_507 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_507) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %445 = arith.cmpi slt, %273, %441 : i32
          scf.if %445 {
            %coord_507 = cute.make_coord(%sub_417) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_508 = cute.crd2idx(%coord_507, %lay_124) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_509 = cute.add_offset(%ptr_119, %idx_508) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_510 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_511 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %446 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %446 step %c1_i32  : i32 {
              %coord_512 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_513 = cute.crd2idx(%coord_512, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_514 = cute.add_offset(%ptr_509, %idx_513) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_515 = cute.crd2idx(%coord_512, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_516 = cute.add_offset(%ptr_510, %idx_515) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_517 = cute.crd2idx(%coord_512, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_518 = cute.add_offset(%iter_511, %idx_517) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %447 = builtin.unrealized_conversion_cast %ptr_518 : !cute.ptr<i8, rmem> to !llvm.ptr
              %448 = llvm.load %447 : !llvm.ptr -> i8
              %449 = llvm.trunc %448 : i8 to i1
              %iter_519 = cute.recast_iter(%ptr_514) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_520 = cute.recast_iter(%ptr_516) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_520 : !cute.ptr<i128, smem>, %iter_519 : !cute.ptr<i128, gmem>, %449 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_507 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_507) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
        } else {
          %coord_501 = cute.make_coord(%sub_417) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %440:3 = cute.get_scalars(%lay_124) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_502 = cute.assume(%440#1) : (i64) -> !cute.i64<divby 128>
          %stride_503 = cute.make_stride(%iv_502) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_504 = cute.make_layout(%111, %stride_503) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_505 = cute.crd2idx(%coord_501, %lay_124) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_506 = cute.add_offset(%ptr_119, %idx_505) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_507 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
          %append_508 = cute.append_to_rank<2> (%lay_504, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %441 = cute.get_scalars(%append_508) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_509 = cute.assume(%441) : (i64) -> !cute.i64<divby 128>
          %stride_510 = cute.make_stride(%iv_509) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_511 = cute.make_layout(%80, %stride_510) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_512 = cute.append_to_rank<2> (%lay_511, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %442 = cute.get_scalars(%append_512) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_513 = cute.assume(%442) : (i64) -> !cute.i64<divby 128>
          %stride_514 = cute.make_stride(%iv_513) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_515 = cute.make_layout(%79, %stride_514) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %443 = cute.get_scalars(%76) : !cute.int_tuple<"8">
          scf.for %arg6 = %c0_i32 to %443 step %c1_i32  : i32 {
            %coord_516 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_517 = cute.crd2idx(%coord_516, %lay_515) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_518 = cute.add_offset(%ptr_506, %idx_517) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_519 = cute.crd2idx(%coord_516, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_520 = cute.add_offset(%ptr_125, %idx_519) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_521 = cute.crd2idx(%coord_516, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_522 = cute.add_offset(%iter_507, %idx_521) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %444 = builtin.unrealized_conversion_cast %ptr_522 : !cute.ptr<i8, rmem> to !llvm.ptr
            %445 = llvm.load %444 : !llvm.ptr -> i8
            %446 = llvm.trunc %445 : i8 to i1
            %iter_523 = cute.recast_iter(%ptr_518) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_524 = cute.recast_iter(%ptr_520) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_524 : !cute.ptr<i128, smem>, %iter_523 : !cute.ptr<i128, gmem>, %446 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %rmem_418 = cute.memref.alloca() : !memref_rmem_f32_1
        %rmem_419 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_420 = cute.get_iter(%rmem_419) : !memref_rmem_bf16_3
        %356:2 = cute.get_scalars(%lay_162) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %iv_421 = cute.assume(%356#0) : (i32) -> !cute.i32<divby 16>
        %iv_422 = cute.assume(%356#1) : (i32) -> !cute.i32<divby 32>
        %stride_423 = cute.make_stride(%iv_421, %iv_422) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
        %lay_424 = cute.make_layout(%106, %stride_423) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %append = cute.append_to_rank<2> (%lay_424, %117) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
        %357:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
        %iv_425 = cute.assume(%357#0) : (i32) -> !cute.i32<divby 16>
        %iv_426 = cute.assume(%357#1) : (i32) -> !cute.i32<divby 32>
        %stride_427 = cute.make_stride(%iv_425, %iv_426) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
        %lay_428 = cute.make_layout(%74, %stride_427) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %append_429 = cute.append_to_rank<2> (%lay_428, %117) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">
        %358:2 = cute.get_scalars(%append_429) <{only_dynamic}> : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
        %iv_430 = cute.assume(%358#0) : (i32) -> !cute.i32<divby 16>
        %iv_431 = cute.assume(%358#1) : (i32) -> !cute.i32<divby 32>
        %stride_432 = cute.make_stride(%iv_430, %iv_431) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
        %lay_433 = cute.make_layout(%73, %stride_432) : !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
        %359 = cute.get_scalars(%71) : !cute.int_tuple<"4">
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %lay_433) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_503 = cute.add_offset(%ptr_160, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_505 = cute.add_offset(%iter_420, %idx_504) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %360 = cute.memref.load_vec %rmem_419 : !memref_rmem_bf16_3
        %361 = arith.extf %360 : vector<32xbf16> to vector<32xf32>
        cute.memref.store_vec %361, %rmem_418 : !memref_rmem_f32_1
        %362 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_140{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_501 = cute.add_offset(%iter_145, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_501 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_502 = cute.add_offset(%iter_145, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_503 = cute.add_offset(%iter_145, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_503 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_148, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%iter_153, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_434 = cute.crd2idx(%61, %lay_144) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_435 = cute.add_offset(%ptr_140, %idx_434) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_436 = cute.add_offset(%iter_145, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_435{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_436 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"18">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"18">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"20">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"20">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"22">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"22">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_437 = cute.crd2idx(%61, %lay_152) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_438 = cute.add_offset(%ptr_148, %idx_437) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_439 = cute.add_offset(%iter_153, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_438, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_439, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_440 = cute.get_iter(%rmem_418) : !memref_rmem_f32_1
        %363 = cute.get_scalars(%76) : !cute.int_tuple<"8">
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%iter_153, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_441 = cute.crd2idx(%57, %lay_144) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_442 = cute.add_offset(%ptr_140, %idx_441) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_443 = cute.add_offset(%iter_145, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_442{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_443 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"34">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"36">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"36">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"38">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"38">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_444 = cute.crd2idx(%57, %lay_152) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_445 = cute.add_offset(%ptr_148, %idx_444) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_446 = cute.add_offset(%iter_153, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_445, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_446, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_439, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_436 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_447 = cute.crd2idx(%55, %lay_144) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_448 = cute.add_offset(%ptr_140, %idx_447) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_449 = cute.add_offset(%iter_145, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_448{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_449 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"50">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"50">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"52">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"52">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"54">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"54">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_450 = cute.crd2idx(%55, %lay_152) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_451 = cute.add_offset(%ptr_148, %idx_450) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_452 = cute.add_offset(%iter_153, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_451, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_452, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_446, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_443 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_453 = cute.add_offset(%ptr_140, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_454 = cute.add_offset(%iter_145, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_453{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_454 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"12">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"14">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_455 = cute.add_offset(%ptr_148, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_456 = cute.add_offset(%iter_153, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_455, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_456, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_452, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_449 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_457 = cute.crd2idx(%51, %lay_144) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_458 = cute.add_offset(%ptr_140, %idx_457) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_459 = cute.add_offset(%iter_145, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_458{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_459 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"26">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"26">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"28">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"28">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"30">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"30">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_460 = cute.crd2idx(%51, %lay_152) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_461 = cute.add_offset(%ptr_148, %idx_460) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_462 = cute.add_offset(%iter_153, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_461, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_462, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_456, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_454 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_463 = cute.crd2idx(%48, %lay_144) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_464 = cute.add_offset(%ptr_140, %idx_463) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_465 = cute.add_offset(%iter_145, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_464{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_465 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"42">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"42">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"44">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"44">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"46">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"46">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_466 = cute.crd2idx(%48, %lay_152) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
        %ptr_467 = cute.add_offset(%ptr_148, %idx_466) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_468 = cute.add_offset(%iter_153, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_467, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_468, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_462, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_459 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %idx_469 = cute.crd2idx(%45, %lay_144) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_470 = cute.add_offset(%ptr_140, %idx_469) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_471 = cute.add_offset(%iter_145, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_470{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_471 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"58">
          %ptr_502 = cute.add_offset(%iter_145, %int_tuple_501) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"58">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"60">
          %ptr_504 = cute.add_offset(%iter_145, %int_tuple_503) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"60">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"62">
          %ptr_506 = cute.add_offset(%iter_145, %int_tuple_505) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"62">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %idx_472 = cute.crd2idx(%45, %lay_152) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_473 = cute.add_offset(%ptr_148, %idx_472) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_474 = cute.add_offset(%iter_153, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %359 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_503 = cute.add_offset(%ptr_473, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_505 = cute.add_offset(%ptr_474, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_468, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_465 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %363 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_474, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_440, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_471 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %364 = arith.cmpi sgt, %354, %c0_i32 : i32
        scf.if %364 {
          %sub_501 = cute.tuple_sub(%sub_417, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_502 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %440:3 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_503 = cute.assume(%440#1) : (i64) -> !cute.i64<divby 128>
          %stride_504 = cute.make_stride(%iv_503) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_505 = cute.make_layout(%111, %stride_504) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_506 = cute.crd2idx(%coord_502, %lay_115) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_507 = cute.add_offset(%ptr_110, %idx_506) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_508 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
          %append_509 = cute.append_to_rank<2> (%lay_505, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %441 = cute.get_scalars(%append_509) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_510 = cute.assume(%441) : (i64) -> !cute.i64<divby 128>
          %stride_511 = cute.make_stride(%iv_510) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_512 = cute.make_layout(%80, %stride_511) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_513 = cute.append_to_rank<2> (%lay_512, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %442 = cute.get_scalars(%append_513) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_514 = cute.assume(%442) : (i64) -> !cute.i64<divby 128>
          %stride_515 = cute.make_stride(%iv_514) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_516 = cute.make_layout(%79, %stride_515) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          scf.for %arg6 = %c0_i32 to %363 step %c1_i32  : i32 {
            %coord_549 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_550 = cute.crd2idx(%coord_549, %lay_516) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_551 = cute.add_offset(%ptr_507, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_552 = cute.crd2idx(%coord_549, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_553 = cute.add_offset(%ptr_116, %idx_552) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_554 = cute.crd2idx(%coord_549, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_555 = cute.add_offset(%iter_508, %idx_554) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %451 = builtin.unrealized_conversion_cast %ptr_555 : !cute.ptr<i8, rmem> to !llvm.ptr
            %452 = llvm.load %451 : !llvm.ptr -> i8
            %453 = llvm.trunc %452 : i8 to i1
            %iter_556 = cute.recast_iter(%ptr_551) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_557 = cute.recast_iter(%ptr_553) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_557 : !cute.ptr<i128, smem>, %iter_556 : !cute.ptr<i128, gmem>, %453 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
          %coord_517 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %idx_518 = cute.crd2idx(%coord_517, %lay_220) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
          %tup_519 = cute.add_offset(%tup_218, %idx_518) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_520, %e1_521, %e2_522, %e3_523 = cute.get_leaves(%tup_519) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_524 = cute.make_coord(%e1_521) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %443 = cute.get_scalars(%coord_524) : !cute.coord<"?">
          %444 = arith.cmpi slt, %443, %276 : i32
          scf.if %444 {
            %coord_549 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_550 = cute.crd2idx(%coord_549, %lay_132) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
            %ptr_551 = cute.add_offset(%ptr_128, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
              %iter_552 = cute.recast_iter(%ptr_551) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_553 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_553 : !cute.ptr<i128, smem>, %iter_552 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_133) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_525 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %idx_526 = cute.crd2idx(%coord_525, %lay_220) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
          %tup_527 = cute.add_offset(%tup_218, %idx_526) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_528, %e1_529, %e2_530, %e3_531 = cute.get_leaves(%tup_527) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_532 = cute.make_coord(%e1_529) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %445 = cute.get_scalars(%coord_532) : !cute.coord<"?">
          %446 = arith.cmpi slt, %445, %276 : i32
          scf.if %446 {
            %coord_549 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_550 = cute.crd2idx(%coord_549, %lay_132) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_551 = cute.add_offset(%ptr_128, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_552 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
              %iter_553 = cute.recast_iter(%ptr_551) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_554 = cute.recast_iter(%ptr_552) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_554 : !cute.ptr<i128, smem>, %iter_553 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_549 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_549) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_533 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %idx_534 = cute.crd2idx(%coord_533, %lay_220) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
          %tup_535 = cute.add_offset(%tup_218, %idx_534) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_536, %e1_537, %e2_538, %e3_539 = cute.get_leaves(%tup_535) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_540 = cute.make_coord(%e1_537) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %447 = cute.get_scalars(%coord_540) : !cute.coord<"?">
          %448 = arith.cmpi slt, %447, %276 : i32
          scf.if %448 {
            %coord_549 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_550 = cute.crd2idx(%coord_549, %lay_132) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_551 = cute.add_offset(%ptr_128, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_552 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
              %iter_553 = cute.recast_iter(%ptr_551) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_554 = cute.recast_iter(%ptr_552) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_554 : !cute.ptr<i128, smem>, %iter_553 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_549 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_549) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_541 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %idx_542 = cute.crd2idx(%coord_541, %lay_220) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
          %tup_543 = cute.add_offset(%tup_218, %idx_542) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_544, %e1_545, %e2_546, %e3_547 = cute.get_leaves(%tup_543) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_548 = cute.make_coord(%e1_545) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %449 = cute.get_scalars(%coord_548) : !cute.coord<"?">
          %450 = arith.cmpi slt, %449, %276 : i32
          scf.if %450 {
            %coord_549 = cute.make_coord(%sub_501) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_550 = cute.crd2idx(%coord_549, %lay_132) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_551 = cute.add_offset(%ptr_128, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_552 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
              %iter_553 = cute.recast_iter(%ptr_551) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_554 = cute.recast_iter(%ptr_552) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_554 : !cute.ptr<i128, smem>, %iter_553 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_549 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_549) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          nvvm.cp.async.commit.group
        }
        %365 = cute.memref.load_vec %rmem_418 : !memref_rmem_f32_1
        %366 = arith.mulf %365, %cst : vector<32xf32>
        cute.memref.store_vec %366, %rmem_418 : !memref_rmem_f32_1
        %367 = cute.memref.load(%rmem_418, %97) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
        %368 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %367 : (f32) -> f32
        cute.memref.store(%rmem_418, %97, %368) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
        %369 = cute.memref.load(%rmem_418, %95) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
        %370 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %369 : (f32) -> f32
        cute.memref.store(%rmem_418, %95, %370) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
        %371 = cute.memref.load(%rmem_418, %42) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
        %372 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %371 : (f32) -> f32
        cute.memref.store(%rmem_418, %42, %372) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
        %373 = cute.memref.load(%rmem_418, %41) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
        %374 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %373 : (f32) -> f32
        cute.memref.store(%rmem_418, %41, %374) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
        %375 = cute.memref.load(%rmem_418, %40) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
        %376 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %375 : (f32) -> f32
        cute.memref.store(%rmem_418, %40, %376) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
        %377 = cute.memref.load(%rmem_418, %39) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
        %378 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %377 : (f32) -> f32
        cute.memref.store(%rmem_418, %39, %378) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
        %379 = cute.memref.load(%rmem_418, %38) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
        %380 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %379 : (f32) -> f32
        cute.memref.store(%rmem_418, %38, %380) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
        %381 = cute.memref.load(%rmem_418, %37) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
        %382 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %381 : (f32) -> f32
        cute.memref.store(%rmem_418, %37, %382) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
        %383 = cute.memref.load(%rmem_418, %36) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
        %384 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %383 : (f32) -> f32
        cute.memref.store(%rmem_418, %36, %384) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
        %385 = cute.memref.load(%rmem_418, %35) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
        %386 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %385 : (f32) -> f32
        cute.memref.store(%rmem_418, %35, %386) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
        %387 = cute.memref.load(%rmem_418, %34) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
        %388 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %387 : (f32) -> f32
        cute.memref.store(%rmem_418, %34, %388) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
        %389 = cute.memref.load(%rmem_418, %33) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
        %390 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %389 : (f32) -> f32
        cute.memref.store(%rmem_418, %33, %390) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
        %391 = cute.memref.load(%rmem_418, %32) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
        %392 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %391 : (f32) -> f32
        cute.memref.store(%rmem_418, %32, %392) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
        %393 = cute.memref.load(%rmem_418, %31) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
        %394 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %393 : (f32) -> f32
        cute.memref.store(%rmem_418, %31, %394) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
        %395 = cute.memref.load(%rmem_418, %30) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
        %396 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %395 : (f32) -> f32
        cute.memref.store(%rmem_418, %30, %396) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
        %397 = cute.memref.load(%rmem_418, %29) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
        %398 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %397 : (f32) -> f32
        cute.memref.store(%rmem_418, %29, %398) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
        %399 = cute.memref.load(%rmem_418, %28) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
        %400 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %399 : (f32) -> f32
        cute.memref.store(%rmem_418, %28, %400) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
        %401 = cute.memref.load(%rmem_418, %27) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
        %402 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %401 : (f32) -> f32
        cute.memref.store(%rmem_418, %27, %402) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
        %403 = cute.memref.load(%rmem_418, %26) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
        %404 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %403 : (f32) -> f32
        cute.memref.store(%rmem_418, %26, %404) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
        %405 = cute.memref.load(%rmem_418, %25) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
        %406 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %405 : (f32) -> f32
        cute.memref.store(%rmem_418, %25, %406) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
        %407 = cute.memref.load(%rmem_418, %24) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
        %408 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %407 : (f32) -> f32
        cute.memref.store(%rmem_418, %24, %408) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
        %409 = cute.memref.load(%rmem_418, %23) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
        %410 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %409 : (f32) -> f32
        cute.memref.store(%rmem_418, %23, %410) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
        %411 = cute.memref.load(%rmem_418, %22) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
        %412 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %411 : (f32) -> f32
        cute.memref.store(%rmem_418, %22, %412) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
        %413 = cute.memref.load(%rmem_418, %21) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
        %414 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %413 : (f32) -> f32
        cute.memref.store(%rmem_418, %21, %414) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
        %415 = cute.memref.load(%rmem_418, %20) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
        %416 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %415 : (f32) -> f32
        cute.memref.store(%rmem_418, %20, %416) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
        %417 = cute.memref.load(%rmem_418, %19) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
        %418 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %417 : (f32) -> f32
        cute.memref.store(%rmem_418, %19, %418) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
        %419 = cute.memref.load(%rmem_418, %18) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
        %420 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %419 : (f32) -> f32
        cute.memref.store(%rmem_418, %18, %420) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
        %421 = cute.memref.load(%rmem_418, %17) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
        %422 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %421 : (f32) -> f32
        cute.memref.store(%rmem_418, %17, %422) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
        %423 = cute.memref.load(%rmem_418, %16) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
        %424 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %423 : (f32) -> f32
        cute.memref.store(%rmem_418, %16, %424) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
        %425 = cute.memref.load(%rmem_418, %15) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
        %426 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %425 : (f32) -> f32
        cute.memref.store(%rmem_418, %15, %426) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
        %427 = cute.memref.load(%rmem_418, %14) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
        %428 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %427 : (f32) -> f32
        cute.memref.store(%rmem_418, %14, %428) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
        %429 = cute.memref.load(%rmem_418, %13) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
        %430 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %429 : (f32) -> f32
        cute.memref.store(%rmem_418, %13, %430) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
        %431 = cute.memref.load_vec %rmem_418 : !memref_rmem_f32_1
        %432 = arith.mulf %366, %431 : vector<32xf32>
        %433 = arith.addf %432, %366 : vector<32xf32>
        cute.memref.store_vec %433, %rmem_418 : !memref_rmem_f32_1
        %rmem_475 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_476 = cute.get_iter(%rmem_475) : !memref_rmem_bf16_3
        %434 = cute.memref.load_vec %rmem_418 : !memref_rmem_f32_1
        %435 = arith.truncf %434 : vector<32xf32> to vector<32xbf16>
        cute.memref.store_vec %435, %rmem_475 : !memref_rmem_bf16_3
        %436:2 = cute.get_scalars(%lay_158) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
        %iv_477 = cute.assume(%436#0) : (i32) -> !cute.i32<divby 16>
        %iv_478 = cute.assume(%436#1) : (i32) -> !cute.i32<divby 32>
        %stride_479 = cute.make_stride(%iv_477, %iv_478) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
        %lay_480 = cute.make_layout(%12, %stride_479) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %append_481 = cute.append_to_rank<2> (%lay_480, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
        %437:2 = cute.get_scalars(%append_481) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
        %iv_482 = cute.assume(%437#0) : (i32) -> !cute.i32<divby 16>
        %iv_483 = cute.assume(%437#1) : (i32) -> !cute.i32<divby 32>
        %stride_484 = cute.make_stride(%iv_482, %iv_483) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
        %lay_485 = cute.make_layout(%11, %stride_484) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %append_486 = cute.append_to_rank<2> (%lay_485, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
        %438:2 = cute.get_scalars(%append_486) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
        %iv_487 = cute.assume(%438#0) : (i32) -> !cute.i32<divby 16>
        %iv_488 = cute.assume(%438#1) : (i32) -> !cute.i32<divby 32>
        %stride_489 = cute.make_stride(%iv_487, %iv_488) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
        %lay_490 = cute.make_layout(%10, %stride_489) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
        scf.for %arg6 = %c0_i32 to %363 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %lay_490) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_503 = cute.add_offset(%ptr_156, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_505 = cute.add_offset(%iter_159, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_491 = cute.add_offset(%ptr_156, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_492 = cute.add_offset(%iter_159, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %363 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %lay_490) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_503 = cute.add_offset(%ptr_491, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_505 = cute.add_offset(%ptr_492, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_493 = cute.get_iter(%rmem_136) : !memref_rmem_f32_
        %439 = cute.get_scalars(%60) : !cute.int_tuple<"16">
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %439 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%iter_159, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_493, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %iter_476 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_494 = cute.add_offset(%ptr_156, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_495 = cute.add_offset(%iter_159, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %363 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %lay_490) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_503 = cute.add_offset(%ptr_494, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_505 = cute.add_offset(%ptr_495, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_496 = cute.add_offset(%iter_476, %76) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %439 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_492, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_493, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_496 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_497 = cute.add_offset(%ptr_156, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %ptr_498 = cute.add_offset(%iter_159, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
        scf.for %arg6 = %c0_i32 to %363 step %c1_i32  : i32 {
          %coord_501 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_502 = cute.crd2idx(%coord_501, %lay_490) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_503 = cute.add_offset(%ptr_497, %idx_502) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_504 = cute.crd2idx(%coord_501, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_505 = cute.add_offset(%ptr_498, %idx_504) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %440 = cute_nvgpu.arch.copy.ldsm %ptr_503{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %441 = vector.extractelement %440[%70 : i32] : vector<4xi32>
          %442 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %441, %442 : i32, !llvm.ptr
          %443 = vector.extractelement %440[%69 : i32] : vector<4xi32>
          %ptr_506 = cute.add_offset(%ptr_505, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %444 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %443, %444 : i32, !llvm.ptr
          %445 = vector.extractelement %440[%68 : i32] : vector<4xi32>
          %ptr_507 = cute.add_offset(%ptr_505, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %446 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %445, %446 : i32, !llvm.ptr
          %447 = vector.extractelement %440[%67 : i32] : vector<4xi32>
          %ptr_508 = cute.add_offset(%ptr_505, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %448 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %447, %448 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_499 = cute.add_offset(%iter_476, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %439 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_495, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_493, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_499 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_500 = cute.add_offset(%iter_476, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        scf.for %arg6 = %c0_i32 to %362 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %362 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %439 step %c1_i32  : i32 {
              %coord_501 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_502 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_503 = cute.crd2idx(%coord_501, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_504 = cute.add_offset(%ptr_498, %idx_503) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_505 = cute.crd2idx(%coord_502, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_506 = cute.add_offset(%iter_493, %idx_505) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %440 = builtin.unrealized_conversion_cast %ptr_500 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
              %441 = llvm.load %440 : !llvm.ptr -> i32
              %442 = llvm.getelementptr %440[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %443 = llvm.load %442 : !llvm.ptr -> i32
              %444 = llvm.getelementptr %440[2] : (!llvm.ptr) -> !llvm.ptr, i32
              %445 = llvm.load %444 : !llvm.ptr -> i32
              %446 = llvm.getelementptr %440[3] : (!llvm.ptr) -> !llvm.ptr, i32
              %447 = llvm.load %446 : !llvm.ptr -> i32
              %448 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %449 = llvm.load %448 : !llvm.ptr -> i32
              %450 = llvm.getelementptr %448[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %451 = llvm.load %450 : !llvm.ptr -> i32
              %452 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %453 = llvm.load %452 : !llvm.ptr -> f32
              %454 = llvm.getelementptr %452[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %455 = llvm.load %454 : !llvm.ptr -> f32
              %456 = llvm.getelementptr %452[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %457 = llvm.load %456 : !llvm.ptr -> f32
              %458 = llvm.getelementptr %452[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %459 = llvm.load %458 : !llvm.ptr -> f32
              %460:4 = cute_nvgpu.arch.mma.SM80 A[%441, %443, %445, %447]  B[%449, %451]  C[%453, %455, %457, %459] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %460#0, %452 : f32, !llvm.ptr
              llvm.store %460#1, %454 : f32, !llvm.ptr
              llvm.store %460#2, %456 : f32, !llvm.ptr
              llvm.store %460#3, %458 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      }
      %rmem_326 = cute.memref.alloca() : !memref_rmem_bf16_4
      %309 = cute.memref.load_vec %rmem_136 : !memref_rmem_f32_
      %310 = arith.truncf %309 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %310, %rmem_326 : !memref_rmem_bf16_4
      %iter_327 = cute.recast_iter(%iter_94) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %atom_328 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %311 = cute.make_tiled_copy(%atom_328) : !copy_simt
      %iter_329 = cute.get_iter(%rmem_326) : !memref_rmem_bf16_4
      %312 = arith.divsi %156, %c4_i32 : i32
      %313 = arith.remsi %156, %c4_i32 : i32
      %314 = arith.muli %313, %c2_i32 : i32
      %315 = arith.divsi %312, %c8_i32 : i32
      %316 = arith.remsi %312, %c8_i32 : i32
      %317 = arith.muli %316, %c64_i32 : i32
      %318 = arith.addi %314, %317 : i32
      %319 = arith.muli %315, %c1024_i32 : i32
      %320 = arith.addi %318, %319 : i32
      %iv_330 = cute.assume(%320) : (i32) -> !cute.i32<divby 2>
      %int_tuple_331 = cute.make_int_tuple(%iv_330) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_332 = cute.add_offset(%iter_327, %int_tuple_331) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %321 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      scf.for %arg5 = %c0_i32 to %321 step %c1_i32  : i32 {
        %coord_416 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_418 = cute.add_offset(%iter_329, %idx_417) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %idx_419 = cute.crd2idx(%coord_416, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_420 = cute.add_offset(%ptr_332, %idx_419) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled = cute.apply_swizzle(%ptr_420) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %354 = builtin.unrealized_conversion_cast %ptr_418 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %355 = builtin.unrealized_conversion_cast %swizzled : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %356 = llvm.load %354 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %356, %355 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_421 = cute.add_offset(%ptr_418, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_422 = cute.add_offset(%ptr_420, %4) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_423 = cute.apply_swizzle(%ptr_422) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %357 = builtin.unrealized_conversion_cast %ptr_421 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %358 = builtin.unrealized_conversion_cast %swizzled_423 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %359 = llvm.load %357 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %359, %358 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_424 = cute.add_offset(%ptr_418, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %ptr_425 = cute.add_offset(%ptr_420, %76) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_426 = cute.apply_swizzle(%ptr_425) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %360 = builtin.unrealized_conversion_cast %ptr_424 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        %361 = builtin.unrealized_conversion_cast %swizzled_426 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %362 = llvm.load %360 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %362, %361 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_427 = cute.add_offset(%ptr_418, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_428 = cute.add_offset(%ptr_420, %3) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_429 = cute.apply_swizzle(%ptr_428) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %363 = builtin.unrealized_conversion_cast %ptr_427 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %364 = builtin.unrealized_conversion_cast %swizzled_429 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %365 = llvm.load %363 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %365, %364 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      } {llvm.loop_annotation = #loop_annotation}
      %lay_333 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %322:7 = cute.get_scalars(%lay_333) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_334 = cute.assume(%322#3) : (i32) -> !cute.i32<divby 8>
      %shape_335 = cute.make_shape(%322#1, %iv_334) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_336 = cute.assume(%322#5) : (i64) -> !cute.i64<divby 8>
      %stride_337 = cute.make_stride(%iv_336) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_338 = cute.make_layout(%shape_335, %stride_337) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_339 = cute.crd2idx(%coord, %lay_333) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_340 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_341 = cute.add_offset(%iter_340, %idx_339) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %323:3 = cute.get_scalars(%lay_338) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %324 = arith.ceildivsi %323#0, %c64_i32 : i32
      %325 = arith.muli %323#2, %c64_i64 : i64
      %326 = arith.ceildivsi %323#1, %c128_i32 : i32
      %shape_342 = cute.make_shape(%324, %326) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_343 = cute.assume(%323#2) : (i64) -> !cute.i64<divby 8>
      %iv_344 = cute.assume(%325) : (i64) -> !cute.i64<divby 512>
      %stride_345 = cute.make_stride(%iv_343, %iv_344) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_346 = cute.make_layout(%shape_342, %stride_345) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %327:4 = cute.get_scalars(%lay_346) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_347 = cute.assume(%327#2) : (i64) -> !cute.i64<divby 8>
      %stride_348 = cute.make_stride(%iv_347) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_349 = cute.make_layout(%115, %stride_348) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_350 = cute.crd2idx(%coord_20, %lay_346) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_351 = cute.add_offset(%ptr_341, %idx_350) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %328 = arith.addi %160, %167 : i32
      %iv_352 = cute.assume(%328) : (i32) -> !cute.i32<divby 8>
      %int_tuple_353 = cute.make_int_tuple(%iv_352) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_354 = cute.add_offset(%iter_327, %int_tuple_353) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %329 = cute.get_scalars(%lay_349) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %330 = arith.muli %329, %c16_i64 : i64
      %331 = arith.muli %161, %329 : i64
      %332 = arith.addi %163, %331 : i64
      %iv_355 = cute.assume(%332) : (i64) -> !cute.i64<divby 8>
      %int_tuple_356 = cute.make_int_tuple(%iv_355) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_357 = cute.add_offset(%ptr_351, %int_tuple_356) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_358 = cute.assume(%330) : (i64) -> !cute.i64<divby 128>
      %stride_359 = cute.make_stride(%iv_358) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_360 = cute.make_layout(%111, %stride_359) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %rmem_361 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_362 = cute.get_iter(%rmem_361) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      scf.for %arg5 = %c0_i32 to %321 step %c1_i32  : i32 {
        %coord_416 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_417 = cute.crd2idx(%coord_416, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
        %idx_418 = cute.crd2idx(%coord_416, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_419 = cute.add_offset(%iter_362, %idx_418) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %swizzled = cute.apply_swizzle(%ptr_354) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %ptr_420 = cute.add_offset(%swizzled, %idx_417) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %354 = builtin.unrealized_conversion_cast %ptr_420 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
        %355 = builtin.unrealized_conversion_cast %ptr_419 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %356 = llvm.load %354 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %356, %355 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %333 = cute.get_shape(%lay_333) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_363, %e1_364, %e2_365, %e3_366 = cute.get_leaves(%333) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_367 = cute.to_int_tuple(%e0_363) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_368 = cute.to_int_tuple(%e1_364) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_369 = cute.to_int_tuple(%e2_365) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_370 = cute.to_int_tuple(%e3_366) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_371 = cute.make_shape(%itup_367, %itup_368, %itup_369, %itup_370) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_372 = cute.make_layout(%shape_371, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %334:4 = cute.get_scalars(%lay_372) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_373 = cute.assume(%334#3) : (i32) -> !cute.i32<divby 8>
      %shape_374 = cute.make_shape(%334#1, %iv_373) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_375 = cute.make_layout(%shape_374, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_376 = cute.crd2idx(%coord, %lay_372) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_377 = cute.add_offset(%105, %idx_376) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %335:2 = cute.get_scalars(%lay_375) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %336 = arith.ceildivsi %335#0, %c64_i32 : i32
      %337 = arith.ceildivsi %335#1, %c128_i32 : i32
      %shape_378 = cute.make_shape(%336, %337) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_379 = cute.make_layout(%shape_378, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_380 = cute.crd2idx(%coord_20, %lay_379) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_381 = cute.add_offset(%tup_377, %idx_380) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %tup_382 = cute.add_offset(%tup_381, %int_tuple_214) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_383 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_384, %e1_385, %e2_386, %e3_387 = cute.get_leaves(%tup_382) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_388 = cute.make_coord(%e3_387) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_389 = cute.make_coord(%itup_370) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %338 = cute.get_scalars(%coord_388) : !cute.coord<"?{div=8}">
      %339 = cute.get_scalars(%coord_389) : !cute.coord<"?{div=8}">
      %340 = arith.cmpi slt, %338, %339 : i32
      %341 = arith.extui %340 : i1 to i8
      cute.memref.store(%rmem_383, %97, %341) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_390 = cute.add_offset(%tup_382, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_391, %e1_392, %e2_393, %e3_394 = cute.get_leaves(%tup_390) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_395 = cute.make_coord(%e3_394) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %342 = cute.get_scalars(%coord_395) : !cute.coord<"?{div=8}">
      %343 = arith.cmpi slt, %342, %339 : i32
      %344 = arith.extui %343 : i1 to i8
      cute.memref.store(%rmem_383, %95, %344) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_396 = cute.make_coord(%e1_385) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_397 = cute.make_coord(%itup_368) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %345 = cute.get_scalars(%coord_396) : !cute.coord<"?">
      %346 = cute.get_scalars(%coord_397) : !cute.coord<"?">
      %347 = arith.cmpi slt, %345, %346 : i32
      scf.if %347 {
        %iter_416 = cute.get_iter(%rmem_383) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_417 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_418 = cute.crd2idx(%coord_417, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_419 = cute.add_offset(%iter_362, %idx_418) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_420 = cute.crd2idx(%coord_417, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_421 = cute.add_offset(%ptr_357, %idx_420) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_422 = cute.crd2idx(%coord_417, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_423 = cute.add_offset(%iter_416, %idx_422) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_423 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.icmp "ne" %356, %0 : i8
          scf.if %357 {
            %358 = builtin.unrealized_conversion_cast %ptr_419 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %359 = builtin.unrealized_conversion_cast %ptr_421 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %360 = llvm.load %358 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %360, %359 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_398 = cute.add_offset(%tup_382, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_399, %e1_400, %e2_401, %e3_402 = cute.get_leaves(%tup_398) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_403 = cute.make_coord(%e1_400) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %348 = cute.get_scalars(%coord_403) : !cute.coord<"?">
      %349 = arith.cmpi slt, %348, %346 : i32
      scf.if %349 {
        %ptr_416 = cute.add_offset(%iter_362, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_417 = cute.crd2idx(%89, %lay_360) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_418 = cute.add_offset(%ptr_357, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_419 = cute.get_iter(%rmem_383) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_422 = cute.add_offset(%ptr_416, %idx_421) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.icmp "ne" %356, %0 : i8
          scf.if %357 {
            %358 = builtin.unrealized_conversion_cast %ptr_422 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %359 = builtin.unrealized_conversion_cast %ptr_424 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %360 = llvm.load %358 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %360, %359 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_404 = cute.add_offset(%tup_382, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_405, %e1_406, %e2_407, %e3_408 = cute.get_leaves(%tup_404) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_409 = cute.make_coord(%e1_406) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %350 = cute.get_scalars(%coord_409) : !cute.coord<"?">
      %351 = arith.cmpi slt, %350, %346 : i32
      scf.if %351 {
        %ptr_416 = cute.add_offset(%iter_362, %63) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_417 = cute.crd2idx(%86, %lay_360) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_418 = cute.add_offset(%ptr_357, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_419 = cute.get_iter(%rmem_383) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_422 = cute.add_offset(%ptr_416, %idx_421) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.icmp "ne" %356, %0 : i8
          scf.if %357 {
            %358 = builtin.unrealized_conversion_cast %ptr_422 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %359 = builtin.unrealized_conversion_cast %ptr_424 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %360 = llvm.load %358 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %360, %359 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_410 = cute.add_offset(%tup_382, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_411, %e1_412, %e2_413, %e3_414 = cute.get_leaves(%tup_410) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_415 = cute.make_coord(%e1_412) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %352 = cute.get_scalars(%coord_415) : !cute.coord<"?">
      %353 = arith.cmpi slt, %352, %346 : i32
      scf.if %353 {
        %ptr_416 = cute.add_offset(%iter_362, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_417 = cute.crd2idx(%83, %lay_360) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_418 = cute.add_offset(%ptr_357, %idx_417) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_419 = cute.get_iter(%rmem_383) : !memref_rmem_i8_
        %354 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %354 step %c1_i32  : i32 {
          %coord_420 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_421 = cute.crd2idx(%coord_420, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_422 = cute.add_offset(%ptr_416, %idx_421) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_423 = cute.crd2idx(%coord_420, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_424 = cute.add_offset(%ptr_418, %idx_423) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_425 = cute.crd2idx(%coord_420, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_426 = cute.add_offset(%iter_419, %idx_425) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.icmp "ne" %356, %0 : i8
          scf.if %357 {
            %358 = builtin.unrealized_conversion_cast %ptr_422 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %359 = builtin.unrealized_conversion_cast %ptr_424 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %360 = llvm.load %358 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %360, %359 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
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
