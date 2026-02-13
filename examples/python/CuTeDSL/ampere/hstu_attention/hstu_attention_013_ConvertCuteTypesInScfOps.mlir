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
        %iter_535 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_536 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_537 = cute.crd2idx(%coord_536, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_538 = cute.add_offset(%ptr_101, %idx_537) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_539 = cute.crd2idx(%coord_536, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_540 = cute.add_offset(%ptr_107, %idx_539) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_541 = cute.crd2idx(%coord_536, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_542 = cute.add_offset(%iter_535, %idx_541) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_542 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_543 = cute.recast_iter(%ptr_538) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_544 = cute.recast_iter(%ptr_540) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_544 : !cute.ptr<i128, smem>, %iter_543 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
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
        %idx_535 = cute.crd2idx(%89, %lay_104) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_536 = cute.add_offset(%ptr_101, %idx_535) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_537 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_538 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_541 = cute.add_offset(%ptr_536, %idx_540) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_546 = cute.recast_iter(%ptr_541) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_547 = cute.recast_iter(%ptr_543) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_547 : !cute.ptr<i128, smem>, %iter_546 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_255 = cute.add_offset(%tup_215, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_256, %e1_257, %e2_258, %e3_259 = cute.get_leaves(%tup_255) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_260 = cute.make_coord(%e1_257) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %262 = cute.get_scalars(%coord_260) : !cute.coord<"?">
      %263 = arith.cmpi slt, %262, %258 : i32
      scf.if %263 {
        %idx_535 = cute.crd2idx(%86, %lay_104) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_536 = cute.add_offset(%ptr_101, %idx_535) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_537 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_538 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_541 = cute.add_offset(%ptr_536, %idx_540) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_546 = cute.recast_iter(%ptr_541) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_547 = cute.recast_iter(%ptr_543) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_547 : !cute.ptr<i128, smem>, %iter_546 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_261 = cute.add_offset(%tup_215, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_262, %e1_263, %e2_264, %e3_265 = cute.get_leaves(%tup_261) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_266 = cute.make_coord(%e1_263) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %264 = cute.get_scalars(%coord_266) : !cute.coord<"?">
      %265 = arith.cmpi slt, %264, %258 : i32
      scf.if %265 {
        %idx_535 = cute.crd2idx(%83, %lay_104) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_536 = cute.add_offset(%ptr_101, %idx_535) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_537 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_538 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_541 = cute.add_offset(%ptr_536, %idx_540) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_546 = cute.recast_iter(%ptr_541) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_547 = cute.recast_iter(%ptr_543) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_547 : !cute.ptr<i128, smem>, %iter_546 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %coord_267 = cute.make_coord(%e1_236) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_268 = cute.make_coord(%itup_12) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %266 = cute.get_scalars(%coord_267) : !cute.coord<"?">
      %267 = cute.get_scalars(%coord_268) : !cute.coord<"?">
      %268 = arith.cmpi slt, %266, %267 : i32
      scf.if %268 {
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_115) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
        %ptr_537 = cute.add_offset(%ptr_110, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_538 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_541 = cute.add_offset(%ptr_537, %idx_540) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_543 = cute.add_offset(%ptr_116, %idx_542) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_546 = cute.recast_iter(%ptr_541) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_547 = cute.recast_iter(%ptr_543) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_547 : !cute.ptr<i128, smem>, %iter_546 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
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
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_115) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_537 = cute.add_offset(%ptr_110, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_539 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_540 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_541 = cute.crd2idx(%coord_540, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_542 = cute.add_offset(%ptr_537, %idx_541) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_543 = cute.crd2idx(%coord_540, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_544 = cute.add_offset(%ptr_538, %idx_543) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_545 = cute.crd2idx(%coord_540, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_546 = cute.add_offset(%iter_539, %idx_545) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_546 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_547 = cute.recast_iter(%ptr_542) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_548 = cute.recast_iter(%ptr_544) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_548 : !cute.ptr<i128, smem>, %iter_547 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_275 = cute.add_offset(%tup_216, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_276, %e1_277, %e2_278, %e3_279 = cute.get_leaves(%tup_275) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_280 = cute.make_coord(%e1_277) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %271 = cute.get_scalars(%coord_280) : !cute.coord<"?">
      %272 = arith.cmpi slt, %271, %267 : i32
      scf.if %272 {
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_115) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_537 = cute.add_offset(%ptr_110, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_539 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_540 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_541 = cute.crd2idx(%coord_540, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_542 = cute.add_offset(%ptr_537, %idx_541) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_543 = cute.crd2idx(%coord_540, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_544 = cute.add_offset(%ptr_538, %idx_543) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_545 = cute.crd2idx(%coord_540, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_546 = cute.add_offset(%iter_539, %idx_545) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_546 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_547 = cute.recast_iter(%ptr_542) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_548 = cute.recast_iter(%ptr_544) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_548 : !cute.ptr<i128, smem>, %iter_547 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
        cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      }
      %tup_281 = cute.add_offset(%tup_216, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_282, %e1_283, %e2_284, %e3_285 = cute.get_leaves(%tup_281) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_286 = cute.make_coord(%e1_283) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %273 = cute.get_scalars(%coord_286) : !cute.coord<"?">
      %274 = arith.cmpi slt, %273, %267 : i32
      scf.if %274 {
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_115) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_537 = cute.add_offset(%ptr_110, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_539 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_540 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_541 = cute.crd2idx(%coord_540, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_542 = cute.add_offset(%ptr_537, %idx_541) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_543 = cute.crd2idx(%coord_540, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_544 = cute.add_offset(%ptr_538, %idx_543) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_545 = cute.crd2idx(%coord_540, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_546 = cute.add_offset(%iter_539, %idx_545) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_546 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.trunc %430 : i8 to i1
          %iter_547 = cute.recast_iter(%ptr_542) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_548 = cute.recast_iter(%ptr_544) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_548 : !cute.ptr<i128, smem>, %iter_547 : !cute.ptr<i128, gmem>, %431 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_
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
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_132) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
        %ptr_537 = cute.add_offset(%ptr_128, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %428 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %iter_538 = cute.recast_iter(%ptr_537) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_539 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_539 : !cute.ptr<i128, smem>, %iter_538 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
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
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_132) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_537 = cute.add_offset(%ptr_128, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %428 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %iter_539 = cute.recast_iter(%ptr_537) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_540 = cute.recast_iter(%ptr_538) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_540 : !cute.ptr<i128, smem>, %iter_539 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_1
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
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_132) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_537 = cute.add_offset(%ptr_128, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %428 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %iter_539 = cute.recast_iter(%ptr_537) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_540 = cute.recast_iter(%ptr_538) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_540 : !cute.ptr<i128, smem>, %iter_539 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_1
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
        %coord_535 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
        %idx_536 = cute.crd2idx(%coord_535, %lay_132) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
        %ptr_537 = cute.add_offset(%ptr_128, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_538 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %428 = cute.get_scalars(%116) : !cute.int_tuple<"1">
        %iter_539 = cute.recast_iter(%ptr_537) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_540 = cute.recast_iter(%ptr_538) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_540 : !cute.ptr<i128, smem>, %iter_539 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      } else {
        %ptr_535 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %view = cute.make_view(%ptr_535) : !memref_smem_bf16_1
        cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_1
      }
      nvvm.cp.async.commit.group
      %tup_325 = cute.add_offset(%sub_16, %81) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %309:2 = cute.get_scalars(%lay_162) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_326 = cute.assume(%309#0) : (i32) -> !cute.i32<divby 16>
      %iv_327 = cute.assume(%309#1) : (i32) -> !cute.i32<divby 32>
      %stride_328 = cute.make_stride(%iv_326, %iv_327) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_329 = cute.make_layout(%106, %stride_328) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %append = cute.append_to_rank<2> (%lay_329, %117) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
      %310:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_330 = cute.assume(%310#0) : (i32) -> !cute.i32<divby 16>
      %iv_331 = cute.assume(%310#1) : (i32) -> !cute.i32<divby 32>
      %stride_332 = cute.make_stride(%iv_330, %iv_331) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
      %lay_333 = cute.make_layout(%74, %stride_332) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %append_334 = cute.append_to_rank<2> (%lay_333, %117) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">
      %311:2 = cute.get_scalars(%append_334) <{only_dynamic}> : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %iv_335 = cute.assume(%311#0) : (i32) -> !cute.i32<divby 16>
      %iv_336 = cute.assume(%311#1) : (i32) -> !cute.i32<divby 32>
      %stride_337 = cute.make_stride(%iv_335, %iv_336) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
      %lay_338 = cute.make_layout(%73, %stride_337) : !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
      %312 = cute.get_scalars(%71) : !cute.int_tuple<"4">
      %313 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %314 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %ptr_339 = cute.add_offset(%iter_145, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %315 = builtin.unrealized_conversion_cast %ptr_339 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_340 = cute.add_offset(%iter_145, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %316 = builtin.unrealized_conversion_cast %ptr_340 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %ptr_341 = cute.add_offset(%iter_145, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %317 = builtin.unrealized_conversion_cast %ptr_341 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_342 = cute.crd2idx(%61, %lay_144) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_343 = cute.add_offset(%ptr_140, %idx_342) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_344 = cute.add_offset(%iter_145, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      %318 = builtin.unrealized_conversion_cast %ptr_344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_345 = cute.make_int_tuple() : () -> !cute.int_tuple<"18">
      %ptr_346 = cute.add_offset(%iter_145, %int_tuple_345) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"18">) -> !cute.ptr<bf16, rmem, align<4>>
      %319 = builtin.unrealized_conversion_cast %ptr_346 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_347 = cute.make_int_tuple() : () -> !cute.int_tuple<"20">
      %ptr_348 = cute.add_offset(%iter_145, %int_tuple_347) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"20">) -> !cute.ptr<bf16, rmem, align<8>>
      %320 = builtin.unrealized_conversion_cast %ptr_348 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_349 = cute.make_int_tuple() : () -> !cute.int_tuple<"22">
      %ptr_350 = cute.add_offset(%iter_145, %int_tuple_349) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"22">) -> !cute.ptr<bf16, rmem, align<4>>
      %321 = builtin.unrealized_conversion_cast %ptr_350 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_351 = cute.crd2idx(%61, %lay_152) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_352 = cute.add_offset(%ptr_148, %idx_351) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_353 = cute.add_offset(%iter_153, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %322 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      %323 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %324 = llvm.getelementptr %323[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %325 = llvm.getelementptr %323[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %326 = llvm.getelementptr %323[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_354 = cute.crd2idx(%57, %lay_144) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_355 = cute.add_offset(%ptr_140, %idx_354) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_356 = cute.add_offset(%iter_145, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      %327 = builtin.unrealized_conversion_cast %ptr_356 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_357 = cute.make_int_tuple() : () -> !cute.int_tuple<"34">
      %ptr_358 = cute.add_offset(%iter_145, %int_tuple_357) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %328 = builtin.unrealized_conversion_cast %ptr_358 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_359 = cute.make_int_tuple() : () -> !cute.int_tuple<"36">
      %ptr_360 = cute.add_offset(%iter_145, %int_tuple_359) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"36">) -> !cute.ptr<bf16, rmem, align<8>>
      %329 = builtin.unrealized_conversion_cast %ptr_360 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_361 = cute.make_int_tuple() : () -> !cute.int_tuple<"38">
      %ptr_362 = cute.add_offset(%iter_145, %int_tuple_361) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"38">) -> !cute.ptr<bf16, rmem, align<4>>
      %330 = builtin.unrealized_conversion_cast %ptr_362 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_363 = cute.crd2idx(%57, %lay_152) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_364 = cute.add_offset(%ptr_148, %idx_363) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_365 = cute.add_offset(%iter_153, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      %331 = builtin.unrealized_conversion_cast %ptr_344 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %332 = llvm.getelementptr %331[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %333 = llvm.getelementptr %331[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %334 = llvm.getelementptr %331[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_366 = cute.crd2idx(%55, %lay_144) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_367 = cute.add_offset(%ptr_140, %idx_366) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_368 = cute.add_offset(%iter_145, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      %335 = builtin.unrealized_conversion_cast %ptr_368 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_369 = cute.make_int_tuple() : () -> !cute.int_tuple<"50">
      %ptr_370 = cute.add_offset(%iter_145, %int_tuple_369) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"50">) -> !cute.ptr<bf16, rmem, align<4>>
      %336 = builtin.unrealized_conversion_cast %ptr_370 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_371 = cute.make_int_tuple() : () -> !cute.int_tuple<"52">
      %ptr_372 = cute.add_offset(%iter_145, %int_tuple_371) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"52">) -> !cute.ptr<bf16, rmem, align<8>>
      %337 = builtin.unrealized_conversion_cast %ptr_372 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_373 = cute.make_int_tuple() : () -> !cute.int_tuple<"54">
      %ptr_374 = cute.add_offset(%iter_145, %int_tuple_373) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"54">) -> !cute.ptr<bf16, rmem, align<4>>
      %338 = builtin.unrealized_conversion_cast %ptr_374 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_375 = cute.crd2idx(%55, %lay_152) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_376 = cute.add_offset(%ptr_148, %idx_375) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_377 = cute.add_offset(%iter_153, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      %339 = builtin.unrealized_conversion_cast %ptr_356 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %340 = llvm.getelementptr %339[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %341 = llvm.getelementptr %339[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %342 = llvm.getelementptr %339[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %ptr_378 = cute.add_offset(%ptr_140, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_379 = cute.add_offset(%iter_145, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %343 = builtin.unrealized_conversion_cast %ptr_379 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_380 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_381 = cute.add_offset(%iter_145, %int_tuple_380) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
      %344 = builtin.unrealized_conversion_cast %ptr_381 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_382 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_383 = cute.add_offset(%iter_145, %int_tuple_382) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"12">) -> !cute.ptr<bf16, rmem, align<8>>
      %345 = builtin.unrealized_conversion_cast %ptr_383 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_384 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
      %ptr_385 = cute.add_offset(%iter_145, %int_tuple_384) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"14">) -> !cute.ptr<bf16, rmem, align<4>>
      %346 = builtin.unrealized_conversion_cast %ptr_385 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_386 = cute.add_offset(%ptr_148, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_387 = cute.add_offset(%iter_153, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
      %347 = builtin.unrealized_conversion_cast %ptr_368 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %348 = llvm.getelementptr %347[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %349 = llvm.getelementptr %347[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %350 = llvm.getelementptr %347[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_388 = cute.crd2idx(%51, %lay_144) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_389 = cute.add_offset(%ptr_140, %idx_388) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_390 = cute.add_offset(%iter_145, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %351 = builtin.unrealized_conversion_cast %ptr_390 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_391 = cute.make_int_tuple() : () -> !cute.int_tuple<"26">
      %ptr_392 = cute.add_offset(%iter_145, %int_tuple_391) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"26">) -> !cute.ptr<bf16, rmem, align<4>>
      %352 = builtin.unrealized_conversion_cast %ptr_392 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_393 = cute.make_int_tuple() : () -> !cute.int_tuple<"28">
      %ptr_394 = cute.add_offset(%iter_145, %int_tuple_393) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"28">) -> !cute.ptr<bf16, rmem, align<8>>
      %353 = builtin.unrealized_conversion_cast %ptr_394 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_395 = cute.make_int_tuple() : () -> !cute.int_tuple<"30">
      %ptr_396 = cute.add_offset(%iter_145, %int_tuple_395) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"30">) -> !cute.ptr<bf16, rmem, align<4>>
      %354 = builtin.unrealized_conversion_cast %ptr_396 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_397 = cute.crd2idx(%51, %lay_152) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_398 = cute.add_offset(%ptr_148, %idx_397) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_399 = cute.add_offset(%iter_153, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
      %355 = builtin.unrealized_conversion_cast %ptr_379 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %356 = llvm.getelementptr %355[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %357 = llvm.getelementptr %355[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %358 = llvm.getelementptr %355[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_400 = cute.crd2idx(%48, %lay_144) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_401 = cute.add_offset(%ptr_140, %idx_400) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_402 = cute.add_offset(%iter_145, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %359 = builtin.unrealized_conversion_cast %ptr_402 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_403 = cute.make_int_tuple() : () -> !cute.int_tuple<"42">
      %ptr_404 = cute.add_offset(%iter_145, %int_tuple_403) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"42">) -> !cute.ptr<bf16, rmem, align<4>>
      %360 = builtin.unrealized_conversion_cast %ptr_404 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_405 = cute.make_int_tuple() : () -> !cute.int_tuple<"44">
      %ptr_406 = cute.add_offset(%iter_145, %int_tuple_405) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"44">) -> !cute.ptr<bf16, rmem, align<8>>
      %361 = builtin.unrealized_conversion_cast %ptr_406 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_407 = cute.make_int_tuple() : () -> !cute.int_tuple<"46">
      %ptr_408 = cute.add_offset(%iter_145, %int_tuple_407) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"46">) -> !cute.ptr<bf16, rmem, align<4>>
      %362 = builtin.unrealized_conversion_cast %ptr_408 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_409 = cute.crd2idx(%48, %lay_152) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_410 = cute.add_offset(%ptr_148, %idx_409) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_411 = cute.add_offset(%iter_153, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
      %363 = builtin.unrealized_conversion_cast %ptr_390 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %364 = llvm.getelementptr %363[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %365 = llvm.getelementptr %363[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %366 = llvm.getelementptr %363[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_412 = cute.crd2idx(%45, %lay_144) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_413 = cute.add_offset(%ptr_140, %idx_412) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_414 = cute.add_offset(%iter_145, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %367 = builtin.unrealized_conversion_cast %ptr_414 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_415 = cute.make_int_tuple() : () -> !cute.int_tuple<"58">
      %ptr_416 = cute.add_offset(%iter_145, %int_tuple_415) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"58">) -> !cute.ptr<bf16, rmem, align<4>>
      %368 = builtin.unrealized_conversion_cast %ptr_416 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_417 = cute.make_int_tuple() : () -> !cute.int_tuple<"60">
      %ptr_418 = cute.add_offset(%iter_145, %int_tuple_417) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"60">) -> !cute.ptr<bf16, rmem, align<8>>
      %369 = builtin.unrealized_conversion_cast %ptr_418 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_419 = cute.make_int_tuple() : () -> !cute.int_tuple<"62">
      %ptr_420 = cute.add_offset(%iter_145, %int_tuple_419) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"62">) -> !cute.ptr<bf16, rmem, align<4>>
      %370 = builtin.unrealized_conversion_cast %ptr_420 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_421 = cute.crd2idx(%45, %lay_152) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_422 = cute.add_offset(%ptr_148, %idx_421) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_423 = cute.add_offset(%iter_153, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
      %371 = builtin.unrealized_conversion_cast %ptr_402 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %372 = llvm.getelementptr %371[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %373 = llvm.getelementptr %371[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %374 = llvm.getelementptr %371[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %375 = builtin.unrealized_conversion_cast %ptr_414 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %376 = llvm.getelementptr %375[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %377 = llvm.getelementptr %375[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %378 = llvm.getelementptr %375[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %379:2 = cute.get_scalars(%lay_158) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iv_424 = cute.assume(%379#0) : (i32) -> !cute.i32<divby 16>
      %iv_425 = cute.assume(%379#1) : (i32) -> !cute.i32<divby 32>
      %stride_426 = cute.make_stride(%iv_424, %iv_425) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_427 = cute.make_layout(%12, %stride_426) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %append_428 = cute.append_to_rank<2> (%lay_427, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %380:2 = cute.get_scalars(%append_428) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %iv_429 = cute.assume(%380#0) : (i32) -> !cute.i32<divby 16>
      %iv_430 = cute.assume(%380#1) : (i32) -> !cute.i32<divby 32>
      %stride_431 = cute.make_stride(%iv_429, %iv_430) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_432 = cute.make_layout(%11, %stride_431) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %append_433 = cute.append_to_rank<2> (%lay_432, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %381:2 = cute.get_scalars(%append_433) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %iv_434 = cute.assume(%381#0) : (i32) -> !cute.i32<divby 16>
      %iv_435 = cute.assume(%381#1) : (i32) -> !cute.i32<divby 32>
      %stride_436 = cute.make_stride(%iv_434, %iv_435) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_437 = cute.make_layout(%10, %stride_436) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %ptr_438 = cute.add_offset(%ptr_156, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_439 = cute.add_offset(%iter_159, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %iter_440 = cute.get_iter(%rmem_136) : !memref_rmem_f32_
      %382 = cute.get_scalars(%60) : !cute.int_tuple<"16">
      %ptr_441 = cute.add_offset(%ptr_156, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_442 = cute.add_offset(%iter_159, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_443 = cute.add_offset(%ptr_156, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_444 = cute.add_offset(%iter_159, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      scf.for %arg5 = %c-1_i32 to %128 step %c1_i32  : i32 {
        %int_tuple_535 = cute.make_int_tuple(%arg5) : (i32) -> !cute.int_tuple<"?">
        %sub_536 = cute.tuple_sub(%tup_325, %int_tuple_535) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %428 = cute.get_scalars(%sub_536) : !cute.int_tuple<"?">
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %429 = arith.cmpi eq, %428, %128 : i32
        scf.if %429 {
          %520 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
          %e0_546, %e1_547, %e2_548, %e3_549 = cute.get_leaves(%520) : !cute.shape<"(?,?,?,?{div=8})">
          %itup_550 = cute.to_int_tuple(%e1_547) : !cute.shape<"?"> to !cute.int_tuple<"?">
          %coord_551 = cute.make_coord(%itup_550) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %521 = cute.get_scalars(%coord_551) : !cute.coord<"?">
          %522 = arith.cmpi slt, %266, %521 : i32
          scf.if %522 {
            %coord_552 = cute.make_coord(%sub_536) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_553 = cute.crd2idx(%coord_552, %lay_124) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
            %ptr_554 = cute.add_offset(%ptr_119, %idx_553) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
            %iter_555 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %526 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %526 step %c1_i32  : i32 {
              %coord_556 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_557 = cute.crd2idx(%coord_556, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_558 = cute.add_offset(%ptr_554, %idx_557) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_559 = cute.crd2idx(%coord_556, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_560 = cute.add_offset(%ptr_125, %idx_559) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_561 = cute.crd2idx(%coord_556, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_562 = cute.add_offset(%iter_555, %idx_561) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %527 = builtin.unrealized_conversion_cast %ptr_562 : !cute.ptr<i8, rmem> to !llvm.ptr
              %528 = llvm.load %527 : !llvm.ptr -> i8
              %529 = llvm.trunc %528 : i8 to i1
              %iter_563 = cute.recast_iter(%ptr_558) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_564 = cute.recast_iter(%ptr_560) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_564 : !cute.ptr<i128, smem>, %iter_563 : !cute.ptr<i128, gmem>, %529 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_125) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %523 = arith.cmpi slt, %269, %521 : i32
          scf.if %523 {
            %coord_552 = cute.make_coord(%sub_536) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_553 = cute.crd2idx(%coord_552, %lay_124) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_554 = cute.add_offset(%ptr_119, %idx_553) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_555 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_556 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %526 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %526 step %c1_i32  : i32 {
              %coord_557 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_558 = cute.crd2idx(%coord_557, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_559 = cute.add_offset(%ptr_554, %idx_558) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_560 = cute.crd2idx(%coord_557, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_561 = cute.add_offset(%ptr_555, %idx_560) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_562 = cute.crd2idx(%coord_557, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_563 = cute.add_offset(%iter_556, %idx_562) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %527 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<i8, rmem> to !llvm.ptr
              %528 = llvm.load %527 : !llvm.ptr -> i8
              %529 = llvm.trunc %528 : i8 to i1
              %iter_564 = cute.recast_iter(%ptr_559) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_565 = cute.recast_iter(%ptr_561) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_565 : !cute.ptr<i128, smem>, %iter_564 : !cute.ptr<i128, gmem>, %529 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_552 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_552) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %524 = arith.cmpi slt, %271, %521 : i32
          scf.if %524 {
            %coord_552 = cute.make_coord(%sub_536) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_553 = cute.crd2idx(%coord_552, %lay_124) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
            %ptr_554 = cute.add_offset(%ptr_119, %idx_553) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_555 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_556 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %526 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %526 step %c1_i32  : i32 {
              %coord_557 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_558 = cute.crd2idx(%coord_557, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_559 = cute.add_offset(%ptr_554, %idx_558) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_560 = cute.crd2idx(%coord_557, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_561 = cute.add_offset(%ptr_555, %idx_560) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_562 = cute.crd2idx(%coord_557, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_563 = cute.add_offset(%iter_556, %idx_562) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %527 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<i8, rmem> to !llvm.ptr
              %528 = llvm.load %527 : !llvm.ptr -> i8
              %529 = llvm.trunc %528 : i8 to i1
              %iter_564 = cute.recast_iter(%ptr_559) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_565 = cute.recast_iter(%ptr_561) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_565 : !cute.ptr<i128, smem>, %iter_564 : !cute.ptr<i128, gmem>, %529 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_552 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_552) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
          %525 = arith.cmpi slt, %273, %521 : i32
          scf.if %525 {
            %coord_552 = cute.make_coord(%sub_536) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_553 = cute.crd2idx(%coord_552, %lay_124) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
            %ptr_554 = cute.add_offset(%ptr_119, %idx_553) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_555 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_556 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
            %526 = cute.get_scalars(%91) : !cute.int_tuple<"2">
            scf.for %arg6 = %c0_i32 to %526 step %c1_i32  : i32 {
              %coord_557 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
              %idx_558 = cute.crd2idx(%coord_557, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
              %ptr_559 = cute.add_offset(%ptr_554, %idx_558) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
              %idx_560 = cute.crd2idx(%coord_557, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_561 = cute.add_offset(%ptr_555, %idx_560) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
              %idx_562 = cute.crd2idx(%coord_557, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
              %ptr_563 = cute.add_offset(%iter_556, %idx_562) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
              %527 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<i8, rmem> to !llvm.ptr
              %528 = llvm.load %527 : !llvm.ptr -> i8
              %529 = llvm.trunc %528 : i8 to i1
              %iter_564 = cute.recast_iter(%ptr_559) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
              %iter_565 = cute.recast_iter(%ptr_561) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_565 : !cute.ptr<i128, smem>, %iter_564 : !cute.ptr<i128, gmem>, %529 : i1) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_552 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_552) : !memref_smem_bf16_
            cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
          }
        } else {
          %coord_546 = cute.make_coord(%sub_536) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %520:3 = cute.get_scalars(%lay_124) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_547 = cute.assume(%520#1) : (i64) -> !cute.i64<divby 128>
          %stride_548 = cute.make_stride(%iv_547) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_549 = cute.make_layout(%111, %stride_548) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_550 = cute.crd2idx(%coord_546, %lay_124) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_551 = cute.add_offset(%ptr_119, %idx_550) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_552 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
          %append_553 = cute.append_to_rank<2> (%lay_549, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %521 = cute.get_scalars(%append_553) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_554 = cute.assume(%521) : (i64) -> !cute.i64<divby 128>
          %stride_555 = cute.make_stride(%iv_554) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_556 = cute.make_layout(%80, %stride_555) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_557 = cute.append_to_rank<2> (%lay_556, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %522 = cute.get_scalars(%append_557) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_558 = cute.assume(%522) : (i64) -> !cute.i64<divby 128>
          %stride_559 = cute.make_stride(%iv_558) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_560 = cute.make_layout(%79, %stride_559) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          %523 = cute.get_scalars(%76) : !cute.int_tuple<"8">
          scf.for %arg6 = %c0_i32 to %523 step %c1_i32  : i32 {
            %coord_561 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_562 = cute.crd2idx(%coord_561, %lay_560) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_563 = cute.add_offset(%ptr_551, %idx_562) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_564 = cute.crd2idx(%coord_561, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_565 = cute.add_offset(%ptr_125, %idx_564) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_566 = cute.crd2idx(%coord_561, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_567 = cute.add_offset(%iter_552, %idx_566) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %524 = builtin.unrealized_conversion_cast %ptr_567 : !cute.ptr<i8, rmem> to !llvm.ptr
            %525 = llvm.load %524 : !llvm.ptr -> i8
            %526 = llvm.trunc %525 : i8 to i1
            %iter_568 = cute.recast_iter(%ptr_563) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_569 = cute.recast_iter(%ptr_565) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_569 : !cute.ptr<i128, smem>, %iter_568 : !cute.ptr<i128, gmem>, %526 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %rmem_537 = cute.memref.alloca() : !memref_rmem_f32_1
        %rmem_538 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_539 = cute.get_iter(%rmem_538) : !memref_rmem_bf16_3
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %lay_338) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_548 = cute.add_offset(%ptr_160, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_550 = cute.add_offset(%iter_539, %idx_549) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %430 = cute.memref.load_vec %rmem_538 : !memref_rmem_bf16_3
        %431 = arith.extf %430 : vector<32xbf16> to vector<32xf32>
        cute.memref.store_vec %431, %rmem_537 : !memref_rmem_f32_1
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_140{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %314 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %315 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %316 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %317 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_148, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%iter_153, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_343{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %318 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %319 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %320 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %321 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_352, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_353, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_540 = cute.get_iter(%rmem_537) : !memref_rmem_f32_1
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%iter_153, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %323 : !llvm.ptr -> i32
              %521 = llvm.load %324 : !llvm.ptr -> i32
              %522 = llvm.load %325 : !llvm.ptr -> i32
              %523 = llvm.load %326 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_355{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %327 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %328 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %329 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %330 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_364, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_365, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_353, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %331 : !llvm.ptr -> i32
              %521 = llvm.load %332 : !llvm.ptr -> i32
              %522 = llvm.load %333 : !llvm.ptr -> i32
              %523 = llvm.load %334 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_367{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %335 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %336 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %337 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %338 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_376, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_377, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_365, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %339 : !llvm.ptr -> i32
              %521 = llvm.load %340 : !llvm.ptr -> i32
              %522 = llvm.load %341 : !llvm.ptr -> i32
              %523 = llvm.load %342 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_378{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %343 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %344 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %345 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %346 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_386, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_387, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_377, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %347 : !llvm.ptr -> i32
              %521 = llvm.load %348 : !llvm.ptr -> i32
              %522 = llvm.load %349 : !llvm.ptr -> i32
              %523 = llvm.load %350 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_389{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %351 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %352 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %353 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %354 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_398, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_399, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_387, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %355 : !llvm.ptr -> i32
              %521 = llvm.load %356 : !llvm.ptr -> i32
              %522 = llvm.load %357 : !llvm.ptr -> i32
              %523 = llvm.load %358 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_401{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %359 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %360 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %361 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %362 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_410, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_411, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_399, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %363 : !llvm.ptr -> i32
              %521 = llvm.load %364 : !llvm.ptr -> i32
              %522 = llvm.load %365 : !llvm.ptr -> i32
              %523 = llvm.load %366 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_413{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          llvm.store %521, %367 : i32, !llvm.ptr
          %522 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          llvm.store %522, %368 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          llvm.store %523, %369 : i32, !llvm.ptr
          %524 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          llvm.store %524, %370 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %312 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_548 = cute.add_offset(%ptr_422, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
          %ptr_550 = cute.add_offset(%ptr_423, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_411, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %371 : !llvm.ptr -> i32
              %521 = llvm.load %372 : !llvm.ptr -> i32
              %522 = llvm.load %373 : !llvm.ptr -> i32
              %523 = llvm.load %374 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %322 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_423, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_540, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %375 : !llvm.ptr -> i32
              %521 = llvm.load %376 : !llvm.ptr -> i32
              %522 = llvm.load %377 : !llvm.ptr -> i32
              %523 = llvm.load %378 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.wait.group 0
        nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
        %432 = arith.cmpi sgt, %428, %c0_i32 : i32
        scf.if %432 {
          %sub_546 = cute.tuple_sub(%sub_536, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_547 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
          %520:3 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
          %iv_548 = cute.assume(%520#1) : (i64) -> !cute.i64<divby 128>
          %stride_549 = cute.make_stride(%iv_548) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
          %lay_550 = cute.make_layout(%111, %stride_549) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %idx_551 = cute.crd2idx(%coord_547, %lay_115) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
          %ptr_552 = cute.add_offset(%ptr_110, %idx_551) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
          %iter_553 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
          %append_554 = cute.append_to_rank<2> (%lay_550, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
          %521 = cute.get_scalars(%append_554) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
          %iv_555 = cute.assume(%521) : (i64) -> !cute.i64<divby 128>
          %stride_556 = cute.make_stride(%iv_555) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
          %lay_557 = cute.make_layout(%80, %stride_556) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %append_558 = cute.append_to_rank<2> (%lay_557, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
          %522 = cute.get_scalars(%append_558) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
          %iv_559 = cute.assume(%522) : (i64) -> !cute.i64<divby 128>
          %stride_560 = cute.make_stride(%iv_559) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
          %lay_561 = cute.make_layout(%79, %stride_560) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
          scf.for %arg6 = %c0_i32 to %322 step %c1_i32  : i32 {
            %coord_594 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
            %idx_595 = cute.crd2idx(%coord_594, %lay_561) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_596 = cute.add_offset(%ptr_552, %idx_595) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %idx_597 = cute.crd2idx(%coord_594, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_598 = cute.add_offset(%ptr_116, %idx_597) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
            %idx_599 = cute.crd2idx(%coord_594, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
            %ptr_600 = cute.add_offset(%iter_553, %idx_599) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %531 = builtin.unrealized_conversion_cast %ptr_600 : !cute.ptr<i8, rmem> to !llvm.ptr
            %532 = llvm.load %531 : !llvm.ptr -> i8
            %533 = llvm.trunc %532 : i8 to i1
            %iter_601 = cute.recast_iter(%ptr_596) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_602 = cute.recast_iter(%ptr_598) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_602 : !cute.ptr<i128, smem>, %iter_601 : !cute.ptr<i128, gmem>, %533 : i1) {cache_mode = <always>}
          } {llvm.loop_annotation = #loop_annotation}
          %coord_562 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
          %idx_563 = cute.crd2idx(%coord_562, %lay_220) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
          %tup_564 = cute.add_offset(%tup_218, %idx_563) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_565, %e1_566, %e2_567, %e3_568 = cute.get_leaves(%tup_564) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_569 = cute.make_coord(%e1_566) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %523 = cute.get_scalars(%coord_569) : !cute.coord<"?">
          %524 = arith.cmpi slt, %523, %276 : i32
          scf.if %524 {
            %coord_594 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
            %idx_595 = cute.crd2idx(%coord_594, %lay_132) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
            %ptr_596 = cute.add_offset(%ptr_128, %idx_595) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %iter_597 = cute.recast_iter(%ptr_596) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_598 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_598 : !cute.ptr<i128, smem>, %iter_597 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %view = cute.make_view(%ptr_133) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_570 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
          %idx_571 = cute.crd2idx(%coord_570, %lay_220) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
          %tup_572 = cute.add_offset(%tup_218, %idx_571) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_573, %e1_574, %e2_575, %e3_576 = cute.get_leaves(%tup_572) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_577 = cute.make_coord(%e1_574) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %525 = cute.get_scalars(%coord_577) : !cute.coord<"?">
          %526 = arith.cmpi slt, %525, %276 : i32
          scf.if %526 {
            %coord_594 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
            %idx_595 = cute.crd2idx(%coord_594, %lay_132) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_596 = cute.add_offset(%ptr_128, %idx_595) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_597 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_598 = cute.recast_iter(%ptr_596) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_599 = cute.recast_iter(%ptr_597) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_599 : !cute.ptr<i128, smem>, %iter_598 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_594 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_594) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_578 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
          %idx_579 = cute.crd2idx(%coord_578, %lay_220) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
          %tup_580 = cute.add_offset(%tup_218, %idx_579) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_581, %e1_582, %e2_583, %e3_584 = cute.get_leaves(%tup_580) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_585 = cute.make_coord(%e1_582) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %527 = cute.get_scalars(%coord_585) : !cute.coord<"?">
          %528 = arith.cmpi slt, %527, %276 : i32
          scf.if %528 {
            %coord_594 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
            %idx_595 = cute.crd2idx(%coord_594, %lay_132) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_596 = cute.add_offset(%ptr_128, %idx_595) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_597 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_598 = cute.recast_iter(%ptr_596) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_599 = cute.recast_iter(%ptr_597) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_599 : !cute.ptr<i128, smem>, %iter_598 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_594 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_594) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          %coord_586 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
          %idx_587 = cute.crd2idx(%coord_586, %lay_220) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
          %tup_588 = cute.add_offset(%tup_218, %idx_587) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
          %e0_589, %e1_590, %e2_591, %e3_592 = cute.get_leaves(%tup_588) : !cute.int_tuple<"(?,?,?,?{div=8})">
          %coord_593 = cute.make_coord(%e1_590) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %529 = cute.get_scalars(%coord_593) : !cute.coord<"?">
          %530 = arith.cmpi slt, %529, %276 : i32
          scf.if %530 {
            %coord_594 = cute.make_coord(%sub_546) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
            %idx_595 = cute.crd2idx(%coord_594, %lay_132) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
            %ptr_596 = cute.add_offset(%ptr_128, %idx_595) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
            %ptr_597 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %iter_598 = cute.recast_iter(%ptr_596) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_599 = cute.recast_iter(%ptr_597) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
            scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM80.cp_async(%iter_599 : !cute.ptr<i128, smem>, %iter_598 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
            } {llvm.loop_annotation = #loop_annotation}
          } else {
            %ptr_594 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
            %view = cute.make_view(%ptr_594) : !memref_smem_bf16_2
            cute.memref.store_vec %cst_0, %view : !memref_smem_bf16_2
          }
          nvvm.cp.async.commit.group
        }
        %433 = cute.memref.load_vec %rmem_537 : !memref_rmem_f32_1
        %434 = arith.mulf %433, %cst : vector<32xf32>
        cute.memref.store_vec %434, %rmem_537 : !memref_rmem_f32_1
        %435 = cute.memref.load(%rmem_537, %97) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
        %436 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %435 : (f32) -> f32
        cute.memref.store(%rmem_537, %97, %436) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
        %437 = cute.memref.load(%rmem_537, %95) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
        %438 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %437 : (f32) -> f32
        cute.memref.store(%rmem_537, %95, %438) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
        %439 = cute.memref.load(%rmem_537, %42) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
        %440 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %439 : (f32) -> f32
        cute.memref.store(%rmem_537, %42, %440) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
        %441 = cute.memref.load(%rmem_537, %41) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
        %442 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %441 : (f32) -> f32
        cute.memref.store(%rmem_537, %41, %442) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
        %443 = cute.memref.load(%rmem_537, %40) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
        %444 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %443 : (f32) -> f32
        cute.memref.store(%rmem_537, %40, %444) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
        %445 = cute.memref.load(%rmem_537, %39) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
        %446 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %445 : (f32) -> f32
        cute.memref.store(%rmem_537, %39, %446) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
        %447 = cute.memref.load(%rmem_537, %38) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
        %448 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %447 : (f32) -> f32
        cute.memref.store(%rmem_537, %38, %448) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
        %449 = cute.memref.load(%rmem_537, %37) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
        %450 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %449 : (f32) -> f32
        cute.memref.store(%rmem_537, %37, %450) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
        %451 = cute.memref.load(%rmem_537, %36) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
        %452 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %451 : (f32) -> f32
        cute.memref.store(%rmem_537, %36, %452) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
        %453 = cute.memref.load(%rmem_537, %35) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
        %454 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %453 : (f32) -> f32
        cute.memref.store(%rmem_537, %35, %454) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
        %455 = cute.memref.load(%rmem_537, %34) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
        %456 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %455 : (f32) -> f32
        cute.memref.store(%rmem_537, %34, %456) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
        %457 = cute.memref.load(%rmem_537, %33) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
        %458 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %457 : (f32) -> f32
        cute.memref.store(%rmem_537, %33, %458) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
        %459 = cute.memref.load(%rmem_537, %32) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
        %460 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %459 : (f32) -> f32
        cute.memref.store(%rmem_537, %32, %460) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
        %461 = cute.memref.load(%rmem_537, %31) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
        %462 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %461 : (f32) -> f32
        cute.memref.store(%rmem_537, %31, %462) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
        %463 = cute.memref.load(%rmem_537, %30) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
        %464 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %463 : (f32) -> f32
        cute.memref.store(%rmem_537, %30, %464) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
        %465 = cute.memref.load(%rmem_537, %29) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
        %466 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %465 : (f32) -> f32
        cute.memref.store(%rmem_537, %29, %466) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
        %467 = cute.memref.load(%rmem_537, %28) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
        %468 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %467 : (f32) -> f32
        cute.memref.store(%rmem_537, %28, %468) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
        %469 = cute.memref.load(%rmem_537, %27) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
        %470 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %469 : (f32) -> f32
        cute.memref.store(%rmem_537, %27, %470) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
        %471 = cute.memref.load(%rmem_537, %26) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
        %472 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %471 : (f32) -> f32
        cute.memref.store(%rmem_537, %26, %472) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
        %473 = cute.memref.load(%rmem_537, %25) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
        %474 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %473 : (f32) -> f32
        cute.memref.store(%rmem_537, %25, %474) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
        %475 = cute.memref.load(%rmem_537, %24) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
        %476 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %475 : (f32) -> f32
        cute.memref.store(%rmem_537, %24, %476) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
        %477 = cute.memref.load(%rmem_537, %23) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
        %478 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %477 : (f32) -> f32
        cute.memref.store(%rmem_537, %23, %478) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
        %479 = cute.memref.load(%rmem_537, %22) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
        %480 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %479 : (f32) -> f32
        cute.memref.store(%rmem_537, %22, %480) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
        %481 = cute.memref.load(%rmem_537, %21) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
        %482 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %481 : (f32) -> f32
        cute.memref.store(%rmem_537, %21, %482) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
        %483 = cute.memref.load(%rmem_537, %20) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
        %484 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %483 : (f32) -> f32
        cute.memref.store(%rmem_537, %20, %484) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
        %485 = cute.memref.load(%rmem_537, %19) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
        %486 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %485 : (f32) -> f32
        cute.memref.store(%rmem_537, %19, %486) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
        %487 = cute.memref.load(%rmem_537, %18) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
        %488 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %487 : (f32) -> f32
        cute.memref.store(%rmem_537, %18, %488) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
        %489 = cute.memref.load(%rmem_537, %17) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
        %490 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %489 : (f32) -> f32
        cute.memref.store(%rmem_537, %17, %490) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
        %491 = cute.memref.load(%rmem_537, %16) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
        %492 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %491 : (f32) -> f32
        cute.memref.store(%rmem_537, %16, %492) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
        %493 = cute.memref.load(%rmem_537, %15) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
        %494 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %493 : (f32) -> f32
        cute.memref.store(%rmem_537, %15, %494) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
        %495 = cute.memref.load(%rmem_537, %14) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
        %496 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %495 : (f32) -> f32
        cute.memref.store(%rmem_537, %14, %496) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
        %497 = cute.memref.load(%rmem_537, %13) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
        %498 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %497 : (f32) -> f32
        cute.memref.store(%rmem_537, %13, %498) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
        %499 = cute.memref.load_vec %rmem_537 : !memref_rmem_f32_1
        %500 = arith.mulf %434, %499 : vector<32xf32>
        %501 = arith.addf %500, %434 : vector<32xf32>
        cute.memref.store_vec %501, %rmem_537 : !memref_rmem_f32_1
        %rmem_541 = cute.memref.alloca() : !memref_rmem_bf16_3
        %iter_542 = cute.get_iter(%rmem_541) : !memref_rmem_bf16_3
        %502 = cute.memref.load_vec %rmem_537 : !memref_rmem_f32_1
        %503 = arith.truncf %502 : vector<32xf32> to vector<32xbf16>
        cute.memref.store_vec %503, %rmem_541 : !memref_rmem_bf16_3
        scf.for %arg6 = %c0_i32 to %322 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %lay_437) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_548 = cute.add_offset(%ptr_156, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_550 = cute.add_offset(%iter_159, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %322 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %lay_437) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_548 = cute.add_offset(%ptr_438, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_550 = cute.add_offset(%ptr_439, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %504 = builtin.unrealized_conversion_cast %iter_542 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
        %505 = llvm.getelementptr %504[1] : (!llvm.ptr) -> !llvm.ptr, i32
        %506 = llvm.getelementptr %504[2] : (!llvm.ptr) -> !llvm.ptr, i32
        %507 = llvm.getelementptr %504[3] : (!llvm.ptr) -> !llvm.ptr, i32
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %382 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%iter_159, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_440, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %504 : !llvm.ptr -> i32
              %521 = llvm.load %505 : !llvm.ptr -> i32
              %522 = llvm.load %506 : !llvm.ptr -> i32
              %523 = llvm.load %507 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %322 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %lay_437) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_548 = cute.add_offset(%ptr_441, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_550 = cute.add_offset(%ptr_442, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_543 = cute.add_offset(%iter_542, %76) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
        %508 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %509 = llvm.getelementptr %508[1] : (!llvm.ptr) -> !llvm.ptr, i32
        %510 = llvm.getelementptr %508[2] : (!llvm.ptr) -> !llvm.ptr, i32
        %511 = llvm.getelementptr %508[3] : (!llvm.ptr) -> !llvm.ptr, i32
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %382 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_439, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_440, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %508 : !llvm.ptr -> i32
              %521 = llvm.load %509 : !llvm.ptr -> i32
              %522 = llvm.load %510 : !llvm.ptr -> i32
              %523 = llvm.load %511 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg6 = %c0_i32 to %322 step %c1_i32  : i32 {
          %coord_546 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %idx_547 = cute.crd2idx(%coord_546, %lay_437) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_548 = cute.add_offset(%ptr_443, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
          %idx_549 = cute.crd2idx(%coord_546, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_550 = cute.add_offset(%ptr_444, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
          %520 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
          %521 = vector.extractelement %520[%70 : i32] : vector<4xi32>
          %522 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %521, %522 : i32, !llvm.ptr
          %523 = vector.extractelement %520[%69 : i32] : vector<4xi32>
          %ptr_551 = cute.add_offset(%ptr_550, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
          %524 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %523, %524 : i32, !llvm.ptr
          %525 = vector.extractelement %520[%68 : i32] : vector<4xi32>
          %ptr_552 = cute.add_offset(%ptr_550, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
          %526 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
          llvm.store %525, %526 : i32, !llvm.ptr
          %527 = vector.extractelement %520[%67 : i32] : vector<4xi32>
          %ptr_553 = cute.add_offset(%ptr_550, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
          %528 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
          llvm.store %527, %528 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_544 = cute.add_offset(%iter_542, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %512 = builtin.unrealized_conversion_cast %ptr_544 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
        %513 = llvm.getelementptr %512[1] : (!llvm.ptr) -> !llvm.ptr, i32
        %514 = llvm.getelementptr %512[2] : (!llvm.ptr) -> !llvm.ptr, i32
        %515 = llvm.getelementptr %512[3] : (!llvm.ptr) -> !llvm.ptr, i32
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %382 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_442, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_440, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %512 : !llvm.ptr -> i32
              %521 = llvm.load %513 : !llvm.ptr -> i32
              %522 = llvm.load %514 : !llvm.ptr -> i32
              %523 = llvm.load %515 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_545 = cute.add_offset(%iter_542, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
        %516 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %517 = llvm.getelementptr %516[1] : (!llvm.ptr) -> !llvm.ptr, i32
        %518 = llvm.getelementptr %516[2] : (!llvm.ptr) -> !llvm.ptr, i32
        %519 = llvm.getelementptr %516[3] : (!llvm.ptr) -> !llvm.ptr, i32
        scf.for %arg6 = %c0_i32 to %313 step %c1_i32  : i32 {
          scf.for %arg7 = %c0_i32 to %313 step %c1_i32  : i32 {
            scf.for %arg8 = %c0_i32 to %382 step %c1_i32  : i32 {
              %coord_546 = cute.make_coord(%arg8, %arg6) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %coord_547 = cute.make_coord(%arg7, %arg8) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_548 = cute.crd2idx(%coord_546, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_549 = cute.add_offset(%ptr_444, %idx_548) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
              %idx_550 = cute.crd2idx(%coord_547, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
              %ptr_551 = cute.add_offset(%iter_440, %idx_550) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
              %520 = llvm.load %516 : !llvm.ptr -> i32
              %521 = llvm.load %517 : !llvm.ptr -> i32
              %522 = llvm.load %518 : !llvm.ptr -> i32
              %523 = llvm.load %519 : !llvm.ptr -> i32
              %524 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
              %525 = llvm.load %524 : !llvm.ptr -> i32
              %526 = llvm.getelementptr %524[1] : (!llvm.ptr) -> !llvm.ptr, i32
              %527 = llvm.load %526 : !llvm.ptr -> i32
              %528 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %529 = llvm.load %528 : !llvm.ptr -> f32
              %530 = llvm.getelementptr %528[1] : (!llvm.ptr) -> !llvm.ptr, f32
              %531 = llvm.load %530 : !llvm.ptr -> f32
              %532 = llvm.getelementptr %528[2] : (!llvm.ptr) -> !llvm.ptr, f32
              %533 = llvm.load %532 : !llvm.ptr -> f32
              %534 = llvm.getelementptr %528[3] : (!llvm.ptr) -> !llvm.ptr, f32
              %535 = llvm.load %534 : !llvm.ptr -> f32
              %536:4 = cute_nvgpu.arch.mma.SM80 A[%520, %521, %522, %523]  B[%525, %527]  C[%529, %531, %533, %535] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
              llvm.store %536#0, %528 : f32, !llvm.ptr
              llvm.store %536#1, %530 : f32, !llvm.ptr
              llvm.store %536#2, %532 : f32, !llvm.ptr
              llvm.store %536#3, %534 : f32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
      }
      %rmem_445 = cute.memref.alloca() : !memref_rmem_bf16_4
      %383 = cute.memref.load_vec %rmem_136 : !memref_rmem_f32_
      %384 = arith.truncf %383 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %384, %rmem_445 : !memref_rmem_bf16_4
      %iter_446 = cute.recast_iter(%iter_94) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %atom_447 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %385 = cute.make_tiled_copy(%atom_447) : !copy_simt
      %iter_448 = cute.get_iter(%rmem_445) : !memref_rmem_bf16_4
      %386 = arith.divsi %156, %c4_i32 : i32
      %387 = arith.remsi %156, %c4_i32 : i32
      %388 = arith.muli %387, %c2_i32 : i32
      %389 = arith.divsi %386, %c8_i32 : i32
      %390 = arith.remsi %386, %c8_i32 : i32
      %391 = arith.muli %390, %c64_i32 : i32
      %392 = arith.addi %388, %391 : i32
      %393 = arith.muli %389, %c1024_i32 : i32
      %394 = arith.addi %392, %393 : i32
      %iv_449 = cute.assume(%394) : (i32) -> !cute.i32<divby 2>
      %int_tuple_450 = cute.make_int_tuple(%iv_449) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_451 = cute.add_offset(%iter_446, %int_tuple_450) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %395 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      scf.for %arg5 = %c0_i32 to %395 step %c1_i32  : i32 {
        %coord_535 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_537 = cute.add_offset(%iter_448, %idx_536) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %idx_538 = cute.crd2idx(%coord_535, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_539 = cute.add_offset(%ptr_451, %idx_538) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_540 = cute.apply_swizzle(%ptr_539) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %428 = builtin.unrealized_conversion_cast %ptr_537 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %429 = builtin.unrealized_conversion_cast %swizzled_540 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %430 = llvm.load %428 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %430, %429 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_541 = cute.add_offset(%ptr_537, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_542 = cute.add_offset(%ptr_539, %4) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_543 = cute.apply_swizzle(%ptr_542) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %431 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %432 = builtin.unrealized_conversion_cast %swizzled_543 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %433 = llvm.load %431 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %433, %432 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_544 = cute.add_offset(%ptr_537, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
        %ptr_545 = cute.add_offset(%ptr_539, %76) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_546 = cute.apply_swizzle(%ptr_545) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %434 = builtin.unrealized_conversion_cast %ptr_544 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
        %435 = builtin.unrealized_conversion_cast %swizzled_546 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %436 = llvm.load %434 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %436, %435 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
        %ptr_547 = cute.add_offset(%ptr_537, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
        %ptr_548 = cute.add_offset(%ptr_539, %3) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %swizzled_549 = cute.apply_swizzle(%ptr_548) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
        %437 = builtin.unrealized_conversion_cast %ptr_547 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
        %438 = builtin.unrealized_conversion_cast %swizzled_549 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
        %439 = llvm.load %437 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
        llvm.store %439, %438 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      } {llvm.loop_annotation = #loop_annotation}
      %lay_452 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %396:7 = cute.get_scalars(%lay_452) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_453 = cute.assume(%396#3) : (i32) -> !cute.i32<divby 8>
      %shape_454 = cute.make_shape(%396#1, %iv_453) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_455 = cute.assume(%396#5) : (i64) -> !cute.i64<divby 8>
      %stride_456 = cute.make_stride(%iv_455) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_457 = cute.make_layout(%shape_454, %stride_456) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_458 = cute.crd2idx(%coord, %lay_452) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_459 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_460 = cute.add_offset(%iter_459, %idx_458) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %397:3 = cute.get_scalars(%lay_457) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %398 = arith.ceildivsi %397#0, %c64_i32 : i32
      %399 = arith.muli %397#2, %c64_i64 : i64
      %400 = arith.ceildivsi %397#1, %c128_i32 : i32
      %shape_461 = cute.make_shape(%398, %400) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_462 = cute.assume(%397#2) : (i64) -> !cute.i64<divby 8>
      %iv_463 = cute.assume(%399) : (i64) -> !cute.i64<divby 512>
      %stride_464 = cute.make_stride(%iv_462, %iv_463) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_465 = cute.make_layout(%shape_461, %stride_464) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %401:4 = cute.get_scalars(%lay_465) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_466 = cute.assume(%401#2) : (i64) -> !cute.i64<divby 8>
      %stride_467 = cute.make_stride(%iv_466) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_468 = cute.make_layout(%115, %stride_467) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_469 = cute.crd2idx(%coord_20, %lay_465) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_470 = cute.add_offset(%ptr_460, %idx_469) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %402 = arith.addi %160, %167 : i32
      %iv_471 = cute.assume(%402) : (i32) -> !cute.i32<divby 8>
      %int_tuple_472 = cute.make_int_tuple(%iv_471) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_473 = cute.add_offset(%iter_446, %int_tuple_472) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %403 = cute.get_scalars(%lay_468) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %404 = arith.muli %403, %c16_i64 : i64
      %405 = arith.muli %161, %403 : i64
      %406 = arith.addi %163, %405 : i64
      %iv_474 = cute.assume(%406) : (i64) -> !cute.i64<divby 8>
      %int_tuple_475 = cute.make_int_tuple(%iv_474) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_476 = cute.add_offset(%ptr_470, %int_tuple_475) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_477 = cute.assume(%404) : (i64) -> !cute.i64<divby 128>
      %stride_478 = cute.make_stride(%iv_477) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_479 = cute.make_layout(%111, %stride_478) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %rmem_480 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_481 = cute.get_iter(%rmem_480) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %swizzled = cute.apply_swizzle(%ptr_473) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      scf.for %arg5 = %c0_i32 to %395 step %c1_i32  : i32 {
        %coord_535 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
        %idx_536 = cute.crd2idx(%coord_535, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
        %idx_537 = cute.crd2idx(%coord_535, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_538 = cute.add_offset(%iter_481, %idx_537) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %ptr_539 = cute.add_offset(%swizzled, %idx_536) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
        %428 = builtin.unrealized_conversion_cast %ptr_539 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
        %429 = builtin.unrealized_conversion_cast %ptr_538 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %430 = llvm.load %428 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %430, %429 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %407 = cute.get_shape(%lay_452) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_482, %e1_483, %e2_484, %e3_485 = cute.get_leaves(%407) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_486 = cute.to_int_tuple(%e0_482) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_487 = cute.to_int_tuple(%e1_483) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_488 = cute.to_int_tuple(%e2_484) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_489 = cute.to_int_tuple(%e3_485) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_490 = cute.make_shape(%itup_486, %itup_487, %itup_488, %itup_489) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_491 = cute.make_layout(%shape_490, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %408:4 = cute.get_scalars(%lay_491) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_492 = cute.assume(%408#3) : (i32) -> !cute.i32<divby 8>
      %shape_493 = cute.make_shape(%408#1, %iv_492) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_494 = cute.make_layout(%shape_493, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_495 = cute.crd2idx(%coord, %lay_491) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_496 = cute.add_offset(%105, %idx_495) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %409:2 = cute.get_scalars(%lay_494) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %410 = arith.ceildivsi %409#0, %c64_i32 : i32
      %411 = arith.ceildivsi %409#1, %c128_i32 : i32
      %shape_497 = cute.make_shape(%410, %411) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_498 = cute.make_layout(%shape_497, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_499 = cute.crd2idx(%coord_20, %lay_498) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_500 = cute.add_offset(%tup_496, %idx_499) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %tup_501 = cute.add_offset(%tup_500, %int_tuple_214) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_502 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_503, %e1_504, %e2_505, %e3_506 = cute.get_leaves(%tup_501) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_507 = cute.make_coord(%e3_506) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_508 = cute.make_coord(%itup_489) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %412 = cute.get_scalars(%coord_507) : !cute.coord<"?{div=8}">
      %413 = cute.get_scalars(%coord_508) : !cute.coord<"?{div=8}">
      %414 = arith.cmpi slt, %412, %413 : i32
      %415 = arith.extui %414 : i1 to i8
      cute.memref.store(%rmem_502, %97, %415) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_509 = cute.add_offset(%tup_501, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_510, %e1_511, %e2_512, %e3_513 = cute.get_leaves(%tup_509) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_514 = cute.make_coord(%e3_513) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %416 = cute.get_scalars(%coord_514) : !cute.coord<"?{div=8}">
      %417 = arith.cmpi slt, %416, %413 : i32
      %418 = arith.extui %417 : i1 to i8
      cute.memref.store(%rmem_502, %95, %418) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_515 = cute.make_coord(%e1_504) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_516 = cute.make_coord(%itup_487) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %419 = cute.get_scalars(%coord_515) : !cute.coord<"?">
      %420 = cute.get_scalars(%coord_516) : !cute.coord<"?">
      %421 = arith.cmpi slt, %419, %420 : i32
      scf.if %421 {
        %iter_535 = cute.get_iter(%rmem_502) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_536 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_537 = cute.crd2idx(%coord_536, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_538 = cute.add_offset(%iter_481, %idx_537) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_539 = cute.crd2idx(%coord_536, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_540 = cute.add_offset(%ptr_476, %idx_539) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_541 = cute.crd2idx(%coord_536, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_542 = cute.add_offset(%iter_535, %idx_541) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_542 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.icmp "ne" %430, %0 : i8
          scf.if %431 {
            %432 = builtin.unrealized_conversion_cast %ptr_538 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %433 = builtin.unrealized_conversion_cast %ptr_540 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %434 = llvm.load %432 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %434, %433 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_517 = cute.add_offset(%tup_501, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_518, %e1_519, %e2_520, %e3_521 = cute.get_leaves(%tup_517) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_522 = cute.make_coord(%e1_519) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %422 = cute.get_scalars(%coord_522) : !cute.coord<"?">
      %423 = arith.cmpi slt, %422, %420 : i32
      scf.if %423 {
        %ptr_535 = cute.add_offset(%iter_481, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_536 = cute.crd2idx(%89, %lay_479) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
        %ptr_537 = cute.add_offset(%ptr_476, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_538 = cute.get_iter(%rmem_502) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_541 = cute.add_offset(%ptr_535, %idx_540) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.icmp "ne" %430, %0 : i8
          scf.if %431 {
            %432 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %433 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %434 = llvm.load %432 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %434, %433 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_523 = cute.add_offset(%tup_501, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_524, %e1_525, %e2_526, %e3_527 = cute.get_leaves(%tup_523) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_528 = cute.make_coord(%e1_525) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %424 = cute.get_scalars(%coord_528) : !cute.coord<"?">
      %425 = arith.cmpi slt, %424, %420 : i32
      scf.if %425 {
        %ptr_535 = cute.add_offset(%iter_481, %63) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_536 = cute.crd2idx(%86, %lay_479) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
        %ptr_537 = cute.add_offset(%ptr_476, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_538 = cute.get_iter(%rmem_502) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_541 = cute.add_offset(%ptr_535, %idx_540) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.icmp "ne" %430, %0 : i8
          scf.if %431 {
            %432 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %433 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %434 = llvm.load %432 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %434, %433 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      %tup_529 = cute.add_offset(%tup_501, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_530, %e1_531, %e2_532, %e3_533 = cute.get_leaves(%tup_529) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_534 = cute.make_coord(%e1_531) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %426 = cute.get_scalars(%coord_534) : !cute.coord<"?">
      %427 = arith.cmpi slt, %426, %420 : i32
      scf.if %427 {
        %ptr_535 = cute.add_offset(%iter_481, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
        %idx_536 = cute.crd2idx(%83, %lay_479) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
        %ptr_537 = cute.add_offset(%ptr_476, %idx_536) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
        %iter_538 = cute.get_iter(%rmem_502) : !memref_rmem_i8_
        %428 = cute.get_scalars(%91) : !cute.int_tuple<"2">
        scf.for %arg5 = %c0_i32 to %428 step %c1_i32  : i32 {
          %coord_539 = cute.make_coord(%arg5) : (i32) -> !cute.coord<"(_,?)">
          %idx_540 = cute.crd2idx(%coord_539, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_541 = cute.add_offset(%ptr_535, %idx_540) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
          %idx_542 = cute.crd2idx(%coord_539, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
          %ptr_543 = cute.add_offset(%ptr_537, %idx_542) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
          %idx_544 = cute.crd2idx(%coord_539, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
          %ptr_545 = cute.add_offset(%iter_538, %idx_544) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %429 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i8, rmem> to !llvm.ptr
          %430 = llvm.load %429 : !llvm.ptr -> i8
          %431 = llvm.icmp "ne" %430, %0 : i8
          scf.if %431 {
            %432 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %433 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %434 = llvm.load %432 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %434, %433 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
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
