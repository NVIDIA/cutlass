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
      cf.cond_br %259, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %iter_249 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
      %260 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%261: i32):  // 2 preds: ^bb1, ^bb3
      %262 = arith.cmpi slt, %261, %260 : i32
      cf.cond_br %262, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_250 = cute.make_coord(%261) : (i32) -> !cute.coord<"(_,?)">
      %idx_251 = cute.crd2idx(%coord_250, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_252 = cute.add_offset(%ptr_101, %idx_251) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_253 = cute.crd2idx(%coord_250, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_254 = cute.add_offset(%ptr_107, %idx_253) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_255 = cute.crd2idx(%coord_250, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_256 = cute.add_offset(%iter_249, %idx_255) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %263 = builtin.unrealized_conversion_cast %ptr_256 : !cute.ptr<i8, rmem> to !llvm.ptr
      %264 = llvm.load %263 : !llvm.ptr -> i8
      %265 = llvm.trunc %264 : i8 to i1
      %iter_257 = cute.recast_iter(%ptr_252) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_258 = cute.recast_iter(%ptr_254) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_258 : !cute.ptr<i128, smem>, %iter_257 : !cute.ptr<i128, gmem>, %265 : i1) {cache_mode = <always>}
      %266 = arith.addi %261, %c1_i32 : i32
      cf.br ^bb2(%266 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb6
    ^bb5:  // pred: ^bb0
      %view = cute.make_view(%ptr_107) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view : !memref_smem_bf16_
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %tup_259 = cute.add_offset(%tup_215, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_260, %e1_261, %e2_262, %e3_263 = cute.get_leaves(%tup_259) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_264 = cute.make_coord(%e1_261) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %267 = cute.get_scalars(%coord_264) : !cute.coord<"?">
      %268 = arith.cmpi slt, %267, %258 : i32
      cf.cond_br %268, ^bb7, ^bb11
    ^bb7:  // pred: ^bb6
      %idx_265 = cute.crd2idx(%89, %lay_104) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_266 = cute.add_offset(%ptr_101, %idx_265) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_267 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_268 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
      %269 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb8(%c0_i32 : i32)
    ^bb8(%270: i32):  // 2 preds: ^bb7, ^bb9
      %271 = arith.cmpi slt, %270, %269 : i32
      cf.cond_br %271, ^bb9, ^bb10 {llvm.loop_annotation = #loop_annotation}
    ^bb9:  // pred: ^bb8
      %coord_269 = cute.make_coord(%270) : (i32) -> !cute.coord<"(_,?)">
      %idx_270 = cute.crd2idx(%coord_269, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_271 = cute.add_offset(%ptr_266, %idx_270) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_272 = cute.crd2idx(%coord_269, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_273 = cute.add_offset(%ptr_267, %idx_272) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_274 = cute.crd2idx(%coord_269, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_275 = cute.add_offset(%iter_268, %idx_274) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %272 = builtin.unrealized_conversion_cast %ptr_275 : !cute.ptr<i8, rmem> to !llvm.ptr
      %273 = llvm.load %272 : !llvm.ptr -> i8
      %274 = llvm.trunc %273 : i8 to i1
      %iter_276 = cute.recast_iter(%ptr_271) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_277 = cute.recast_iter(%ptr_273) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_277 : !cute.ptr<i128, smem>, %iter_276 : !cute.ptr<i128, gmem>, %274 : i1) {cache_mode = <always>}
      %275 = arith.addi %270, %c1_i32 : i32
      cf.br ^bb8(%275 : i32)
    ^bb10:  // pred: ^bb8
      cf.br ^bb12
    ^bb11:  // pred: ^bb6
      %ptr_278 = cute.add_offset(%ptr_107, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_279 = cute.make_view(%ptr_278) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_279 : !memref_smem_bf16_
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %tup_280 = cute.add_offset(%tup_215, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_281, %e1_282, %e2_283, %e3_284 = cute.get_leaves(%tup_280) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_285 = cute.make_coord(%e1_282) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %276 = cute.get_scalars(%coord_285) : !cute.coord<"?">
      %277 = arith.cmpi slt, %276, %258 : i32
      cf.cond_br %277, ^bb13, ^bb17
    ^bb13:  // pred: ^bb12
      %idx_286 = cute.crd2idx(%86, %lay_104) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_287 = cute.add_offset(%ptr_101, %idx_286) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_288 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_289 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
      %278 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb14(%c0_i32 : i32)
    ^bb14(%279: i32):  // 2 preds: ^bb13, ^bb15
      %280 = arith.cmpi slt, %279, %278 : i32
      cf.cond_br %280, ^bb15, ^bb16 {llvm.loop_annotation = #loop_annotation}
    ^bb15:  // pred: ^bb14
      %coord_290 = cute.make_coord(%279) : (i32) -> !cute.coord<"(_,?)">
      %idx_291 = cute.crd2idx(%coord_290, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_292 = cute.add_offset(%ptr_287, %idx_291) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_293 = cute.crd2idx(%coord_290, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_294 = cute.add_offset(%ptr_288, %idx_293) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_295 = cute.crd2idx(%coord_290, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_296 = cute.add_offset(%iter_289, %idx_295) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %281 = builtin.unrealized_conversion_cast %ptr_296 : !cute.ptr<i8, rmem> to !llvm.ptr
      %282 = llvm.load %281 : !llvm.ptr -> i8
      %283 = llvm.trunc %282 : i8 to i1
      %iter_297 = cute.recast_iter(%ptr_292) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_298 = cute.recast_iter(%ptr_294) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_298 : !cute.ptr<i128, smem>, %iter_297 : !cute.ptr<i128, gmem>, %283 : i1) {cache_mode = <always>}
      %284 = arith.addi %279, %c1_i32 : i32
      cf.br ^bb14(%284 : i32)
    ^bb16:  // pred: ^bb14
      cf.br ^bb18
    ^bb17:  // pred: ^bb12
      %ptr_299 = cute.add_offset(%ptr_107, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_300 = cute.make_view(%ptr_299) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_300 : !memref_smem_bf16_
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      %tup_301 = cute.add_offset(%tup_215, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_302, %e1_303, %e2_304, %e3_305 = cute.get_leaves(%tup_301) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_306 = cute.make_coord(%e1_303) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %285 = cute.get_scalars(%coord_306) : !cute.coord<"?">
      %286 = arith.cmpi slt, %285, %258 : i32
      cf.cond_br %286, ^bb19, ^bb23
    ^bb19:  // pred: ^bb18
      %idx_307 = cute.crd2idx(%83, %lay_104) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_308 = cute.add_offset(%ptr_101, %idx_307) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_309 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_310 = cute.get_iter(%rmem_221) : !memref_rmem_i8_
      %287 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb20(%c0_i32 : i32)
    ^bb20(%288: i32):  // 2 preds: ^bb19, ^bb21
      %289 = arith.cmpi slt, %288, %287 : i32
      cf.cond_br %289, ^bb21, ^bb22 {llvm.loop_annotation = #loop_annotation}
    ^bb21:  // pred: ^bb20
      %coord_311 = cute.make_coord(%288) : (i32) -> !cute.coord<"(_,?)">
      %idx_312 = cute.crd2idx(%coord_311, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_313 = cute.add_offset(%ptr_308, %idx_312) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_314 = cute.crd2idx(%coord_311, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_315 = cute.add_offset(%ptr_309, %idx_314) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_316 = cute.crd2idx(%coord_311, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_317 = cute.add_offset(%iter_310, %idx_316) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %290 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<i8, rmem> to !llvm.ptr
      %291 = llvm.load %290 : !llvm.ptr -> i8
      %292 = llvm.trunc %291 : i8 to i1
      %iter_318 = cute.recast_iter(%ptr_313) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_319 = cute.recast_iter(%ptr_315) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_319 : !cute.ptr<i128, smem>, %iter_318 : !cute.ptr<i128, gmem>, %292 : i1) {cache_mode = <always>}
      %293 = arith.addi %288, %c1_i32 : i32
      cf.br ^bb20(%293 : i32)
    ^bb22:  // pred: ^bb20
      cf.br ^bb24
    ^bb23:  // pred: ^bb18
      %ptr_320 = cute.add_offset(%ptr_107, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_321 = cute.make_view(%ptr_320) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_321 : !memref_smem_bf16_
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %coord_322 = cute.make_coord(%e1_236) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_323 = cute.make_coord(%itup_12) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %294 = cute.get_scalars(%coord_322) : !cute.coord<"?">
      %295 = cute.get_scalars(%coord_323) : !cute.coord<"?">
      %296 = arith.cmpi slt, %294, %295 : i32
      cf.cond_br %296, ^bb25, ^bb29
    ^bb25:  // pred: ^bb24
      %coord_324 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_325 = cute.crd2idx(%coord_324, %lay_115) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_326 = cute.add_offset(%ptr_110, %idx_325) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_327 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %297 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb26(%c0_i32 : i32)
    ^bb26(%298: i32):  // 2 preds: ^bb25, ^bb27
      %299 = arith.cmpi slt, %298, %297 : i32
      cf.cond_br %299, ^bb27, ^bb28 {llvm.loop_annotation = #loop_annotation}
    ^bb27:  // pred: ^bb26
      %coord_328 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,?)">
      %idx_329 = cute.crd2idx(%coord_328, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_330 = cute.add_offset(%ptr_326, %idx_329) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_331 = cute.crd2idx(%coord_328, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_332 = cute.add_offset(%ptr_116, %idx_331) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_333 = cute.crd2idx(%coord_328, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_334 = cute.add_offset(%iter_327, %idx_333) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %300 = builtin.unrealized_conversion_cast %ptr_334 : !cute.ptr<i8, rmem> to !llvm.ptr
      %301 = llvm.load %300 : !llvm.ptr -> i8
      %302 = llvm.trunc %301 : i8 to i1
      %iter_335 = cute.recast_iter(%ptr_330) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_336 = cute.recast_iter(%ptr_332) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_336 : !cute.ptr<i128, smem>, %iter_335 : !cute.ptr<i128, gmem>, %302 : i1) {cache_mode = <always>}
      %303 = arith.addi %298, %c1_i32 : i32
      cf.br ^bb26(%303 : i32)
    ^bb28:  // pred: ^bb26
      cf.br ^bb30
    ^bb29:  // pred: ^bb24
      %view_337 = cute.make_view(%ptr_116) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_337 : !memref_smem_bf16_
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %tup_338 = cute.add_offset(%tup_216, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_339, %e1_340, %e2_341, %e3_342 = cute.get_leaves(%tup_338) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_343 = cute.make_coord(%e1_340) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %304 = cute.get_scalars(%coord_343) : !cute.coord<"?">
      %305 = arith.cmpi slt, %304, %295 : i32
      cf.cond_br %305, ^bb31, ^bb35
    ^bb31:  // pred: ^bb30
      %coord_344 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_345 = cute.crd2idx(%coord_344, %lay_115) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_346 = cute.add_offset(%ptr_110, %idx_345) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_347 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_348 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %306 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%307: i32):  // 2 preds: ^bb31, ^bb33
      %308 = arith.cmpi slt, %307, %306 : i32
      cf.cond_br %308, ^bb33, ^bb34 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_349 = cute.make_coord(%307) : (i32) -> !cute.coord<"(_,?)">
      %idx_350 = cute.crd2idx(%coord_349, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_351 = cute.add_offset(%ptr_346, %idx_350) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_352 = cute.crd2idx(%coord_349, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_353 = cute.add_offset(%ptr_347, %idx_352) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_354 = cute.crd2idx(%coord_349, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_355 = cute.add_offset(%iter_348, %idx_354) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %309 = builtin.unrealized_conversion_cast %ptr_355 : !cute.ptr<i8, rmem> to !llvm.ptr
      %310 = llvm.load %309 : !llvm.ptr -> i8
      %311 = llvm.trunc %310 : i8 to i1
      %iter_356 = cute.recast_iter(%ptr_351) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_357 = cute.recast_iter(%ptr_353) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_357 : !cute.ptr<i128, smem>, %iter_356 : !cute.ptr<i128, gmem>, %311 : i1) {cache_mode = <always>}
      %312 = arith.addi %307, %c1_i32 : i32
      cf.br ^bb32(%312 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb36
    ^bb35:  // pred: ^bb30
      %ptr_358 = cute.add_offset(%ptr_116, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_359 = cute.make_view(%ptr_358) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_359 : !memref_smem_bf16_
      cf.br ^bb36
    ^bb36:  // 2 preds: ^bb34, ^bb35
      %tup_360 = cute.add_offset(%tup_216, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_361, %e1_362, %e2_363, %e3_364 = cute.get_leaves(%tup_360) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_365 = cute.make_coord(%e1_362) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %313 = cute.get_scalars(%coord_365) : !cute.coord<"?">
      %314 = arith.cmpi slt, %313, %295 : i32
      cf.cond_br %314, ^bb37, ^bb41
    ^bb37:  // pred: ^bb36
      %coord_366 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_367 = cute.crd2idx(%coord_366, %lay_115) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_368 = cute.add_offset(%ptr_110, %idx_367) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_369 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_370 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %315 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%316: i32):  // 2 preds: ^bb37, ^bb39
      %317 = arith.cmpi slt, %316, %315 : i32
      cf.cond_br %317, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_371 = cute.make_coord(%316) : (i32) -> !cute.coord<"(_,?)">
      %idx_372 = cute.crd2idx(%coord_371, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_373 = cute.add_offset(%ptr_368, %idx_372) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_374 = cute.crd2idx(%coord_371, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_375 = cute.add_offset(%ptr_369, %idx_374) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_376 = cute.crd2idx(%coord_371, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_377 = cute.add_offset(%iter_370, %idx_376) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %318 = builtin.unrealized_conversion_cast %ptr_377 : !cute.ptr<i8, rmem> to !llvm.ptr
      %319 = llvm.load %318 : !llvm.ptr -> i8
      %320 = llvm.trunc %319 : i8 to i1
      %iter_378 = cute.recast_iter(%ptr_373) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_379 = cute.recast_iter(%ptr_375) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_379 : !cute.ptr<i128, smem>, %iter_378 : !cute.ptr<i128, gmem>, %320 : i1) {cache_mode = <always>}
      %321 = arith.addi %316, %c1_i32 : i32
      cf.br ^bb38(%321 : i32)
    ^bb40:  // pred: ^bb38
      cf.br ^bb42
    ^bb41:  // pred: ^bb36
      %ptr_380 = cute.add_offset(%ptr_116, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_381 = cute.make_view(%ptr_380) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_381 : !memref_smem_bf16_
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      %tup_382 = cute.add_offset(%tup_216, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_383, %e1_384, %e2_385, %e3_386 = cute.get_leaves(%tup_382) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_387 = cute.make_coord(%e1_384) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %322 = cute.get_scalars(%coord_387) : !cute.coord<"?">
      %323 = arith.cmpi slt, %322, %295 : i32
      cf.cond_br %323, ^bb43, ^bb47
    ^bb43:  // pred: ^bb42
      %coord_388 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_389 = cute.crd2idx(%coord_388, %lay_115) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_390 = cute.add_offset(%ptr_110, %idx_389) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_391 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_392 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %324 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%325: i32):  // 2 preds: ^bb43, ^bb45
      %326 = arith.cmpi slt, %325, %324 : i32
      cf.cond_br %326, ^bb45, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %coord_393 = cute.make_coord(%325) : (i32) -> !cute.coord<"(_,?)">
      %idx_394 = cute.crd2idx(%coord_393, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_395 = cute.add_offset(%ptr_390, %idx_394) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_396 = cute.crd2idx(%coord_393, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_397 = cute.add_offset(%ptr_391, %idx_396) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_398 = cute.crd2idx(%coord_393, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_399 = cute.add_offset(%iter_392, %idx_398) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %327 = builtin.unrealized_conversion_cast %ptr_399 : !cute.ptr<i8, rmem> to !llvm.ptr
      %328 = llvm.load %327 : !llvm.ptr -> i8
      %329 = llvm.trunc %328 : i8 to i1
      %iter_400 = cute.recast_iter(%ptr_395) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_401 = cute.recast_iter(%ptr_397) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_401 : !cute.ptr<i128, smem>, %iter_400 : !cute.ptr<i128, gmem>, %329 : i1) {cache_mode = <always>}
      %330 = arith.addi %325, %c1_i32 : i32
      cf.br ^bb44(%330 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb48
    ^bb47:  // pred: ^bb42
      %ptr_402 = cute.add_offset(%ptr_116, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_403 = cute.make_view(%ptr_402) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_403 : !memref_smem_bf16_
      cf.br ^bb48
    ^bb48:  // 2 preds: ^bb46, ^bb47
      %coord_404 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %idx_405 = cute.crd2idx(%coord_404, %lay_220) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %tup_406 = cute.add_offset(%tup_218, %idx_405) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_407, %e1_408, %e2_409, %e3_410 = cute.get_leaves(%tup_406) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_411 = cute.make_coord(%e1_408) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_412 = cute.make_coord(%itup_179) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %331 = cute.get_scalars(%coord_411) : !cute.coord<"?">
      %332 = cute.get_scalars(%coord_412) : !cute.coord<"?">
      %333 = arith.cmpi slt, %331, %332 : i32
      %coord_413 = cute.make_coord(%e2_409) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_414 = cute.make_coord(%itup_180) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %334 = cute.get_scalars(%coord_413) : !cute.coord<"?">
      %335 = cute.get_scalars(%coord_414) : !cute.coord<"?{div=8}">
      %336 = arith.cmpi slt, %334, %335 : i32
      %337 = arith.extui %333 : i1 to i32
      %338 = arith.extui %336 : i1 to i32
      %339 = arith.select %333, %338, %337 : i32
      %340 = arith.cmpi ne, %339, %c0_i32 : i32
      cf.cond_br %340, ^bb49, ^bb53
    ^bb49:  // pred: ^bb48
      %coord_415 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
      %idx_416 = cute.crd2idx(%coord_415, %lay_132) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_417 = cute.add_offset(%ptr_128, %idx_416) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %341 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_418 = cute.recast_iter(%ptr_417) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_419 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb50(%c0_i32 : i32)
    ^bb50(%342: i32):  // 2 preds: ^bb49, ^bb51
      %343 = arith.cmpi slt, %342, %341 : i32
      cf.cond_br %343, ^bb51, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb51:  // pred: ^bb50
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_419 : !cute.ptr<i128, smem>, %iter_418 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %344 = arith.addi %342, %c1_i32 : i32
      cf.br ^bb50(%344 : i32)
    ^bb52:  // pred: ^bb50
      cf.br ^bb54
    ^bb53:  // pred: ^bb48
      %view_420 = cute.make_view(%ptr_133) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_420 : !memref_smem_bf16_1
      cf.br ^bb54
    ^bb54:  // 2 preds: ^bb52, ^bb53
      %coord_421 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %idx_422 = cute.crd2idx(%coord_421, %lay_220) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %tup_423 = cute.add_offset(%tup_218, %idx_422) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_424, %e1_425, %e2_426, %e3_427 = cute.get_leaves(%tup_423) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_428 = cute.make_coord(%e1_425) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %345 = cute.get_scalars(%coord_428) : !cute.coord<"?">
      %346 = arith.cmpi slt, %345, %332 : i32
      %coord_429 = cute.make_coord(%e2_426) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %347 = cute.get_scalars(%coord_429) : !cute.coord<"?">
      %348 = arith.cmpi slt, %347, %335 : i32
      %349 = arith.extui %346 : i1 to i32
      %350 = arith.extui %348 : i1 to i32
      %351 = arith.select %346, %350, %349 : i32
      %352 = arith.cmpi ne, %351, %c0_i32 : i32
      cf.cond_br %352, ^bb55, ^bb59
    ^bb55:  // pred: ^bb54
      %coord_430 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
      %idx_431 = cute.crd2idx(%coord_430, %lay_132) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_432 = cute.add_offset(%ptr_128, %idx_431) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_433 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %353 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_434 = cute.recast_iter(%ptr_432) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_435 = cute.recast_iter(%ptr_433) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%354: i32):  // 2 preds: ^bb55, ^bb57
      %355 = arith.cmpi slt, %354, %353 : i32
      cf.cond_br %355, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_435 : !cute.ptr<i128, smem>, %iter_434 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %356 = arith.addi %354, %c1_i32 : i32
      cf.br ^bb56(%356 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb60
    ^bb59:  // pred: ^bb54
      %ptr_436 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_437 = cute.make_view(%ptr_436) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_437 : !memref_smem_bf16_1
      cf.br ^bb60
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %coord_438 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %idx_439 = cute.crd2idx(%coord_438, %lay_220) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %tup_440 = cute.add_offset(%tup_218, %idx_439) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_441, %e1_442, %e2_443, %e3_444 = cute.get_leaves(%tup_440) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_445 = cute.make_coord(%e1_442) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %357 = cute.get_scalars(%coord_445) : !cute.coord<"?">
      %358 = arith.cmpi slt, %357, %332 : i32
      %coord_446 = cute.make_coord(%e2_443) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %359 = cute.get_scalars(%coord_446) : !cute.coord<"?">
      %360 = arith.cmpi slt, %359, %335 : i32
      %361 = arith.extui %358 : i1 to i32
      %362 = arith.extui %360 : i1 to i32
      %363 = arith.select %358, %362, %361 : i32
      %364 = arith.cmpi ne, %363, %c0_i32 : i32
      cf.cond_br %364, ^bb61, ^bb65
    ^bb61:  // pred: ^bb60
      %coord_447 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
      %idx_448 = cute.crd2idx(%coord_447, %lay_132) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_449 = cute.add_offset(%ptr_128, %idx_448) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_450 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %365 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_451 = cute.recast_iter(%ptr_449) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_452 = cute.recast_iter(%ptr_450) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%366: i32):  // 2 preds: ^bb61, ^bb63
      %367 = arith.cmpi slt, %366, %365 : i32
      cf.cond_br %367, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_452 : !cute.ptr<i128, smem>, %iter_451 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %368 = arith.addi %366, %c1_i32 : i32
      cf.br ^bb62(%368 : i32)
    ^bb64:  // pred: ^bb62
      cf.br ^bb66
    ^bb65:  // pred: ^bb60
      %ptr_453 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_454 = cute.make_view(%ptr_453) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_454 : !memref_smem_bf16_1
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %coord_455 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %idx_456 = cute.crd2idx(%coord_455, %lay_220) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %tup_457 = cute.add_offset(%tup_218, %idx_456) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_458, %e1_459, %e2_460, %e3_461 = cute.get_leaves(%tup_457) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_462 = cute.make_coord(%e1_459) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %369 = cute.get_scalars(%coord_462) : !cute.coord<"?">
      %370 = arith.cmpi slt, %369, %332 : i32
      %coord_463 = cute.make_coord(%e2_460) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %371 = cute.get_scalars(%coord_463) : !cute.coord<"?">
      %372 = arith.cmpi slt, %371, %335 : i32
      %373 = arith.extui %370 : i1 to i32
      %374 = arith.extui %372 : i1 to i32
      %375 = arith.select %370, %374, %373 : i32
      %376 = arith.cmpi ne, %375, %c0_i32 : i32
      cf.cond_br %376, ^bb67, ^bb71
    ^bb67:  // pred: ^bb66
      %coord_464 = cute.make_coord(%sub_16) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
      %idx_465 = cute.crd2idx(%coord_464, %lay_132) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_466 = cute.add_offset(%ptr_128, %idx_465) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_467 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %377 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_468 = cute.recast_iter(%ptr_466) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_469 = cute.recast_iter(%ptr_467) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb68(%c0_i32 : i32)
    ^bb68(%378: i32):  // 2 preds: ^bb67, ^bb69
      %379 = arith.cmpi slt, %378, %377 : i32
      cf.cond_br %379, ^bb69, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb69:  // pred: ^bb68
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_469 : !cute.ptr<i128, smem>, %iter_468 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %380 = arith.addi %378, %c1_i32 : i32
      cf.br ^bb68(%380 : i32)
    ^bb70:  // pred: ^bb68
      cf.br ^bb72
    ^bb71:  // pred: ^bb66
      %ptr_470 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_471 = cute.make_view(%ptr_470) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_471 : !memref_smem_bf16_1
      cf.br ^bb72
    ^bb72:  // 2 preds: ^bb70, ^bb71
      nvvm.cp.async.commit.group
      %tup_472 = cute.add_offset(%sub_16, %81) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %381:2 = cute.get_scalars(%lay_162) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_473 = cute.assume(%381#0) : (i32) -> !cute.i32<divby 16>
      %iv_474 = cute.assume(%381#1) : (i32) -> !cute.i32<divby 32>
      %stride_475 = cute.make_stride(%iv_473, %iv_474) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_476 = cute.make_layout(%106, %stride_475) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %append = cute.append_to_rank<2> (%lay_476, %117) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
      %382:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_477 = cute.assume(%382#0) : (i32) -> !cute.i32<divby 16>
      %iv_478 = cute.assume(%382#1) : (i32) -> !cute.i32<divby 32>
      %stride_479 = cute.make_stride(%iv_477, %iv_478) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
      %lay_480 = cute.make_layout(%74, %stride_479) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %append_481 = cute.append_to_rank<2> (%lay_480, %117) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">
      %383:2 = cute.get_scalars(%append_481) <{only_dynamic}> : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %iv_482 = cute.assume(%383#0) : (i32) -> !cute.i32<divby 16>
      %iv_483 = cute.assume(%383#1) : (i32) -> !cute.i32<divby 32>
      %stride_484 = cute.make_stride(%iv_482, %iv_483) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
      %lay_485 = cute.make_layout(%73, %stride_484) : !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
      %384 = cute.get_scalars(%71) : !cute.int_tuple<"4">
      %385 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %386 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %ptr_486 = cute.add_offset(%iter_145, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %387 = builtin.unrealized_conversion_cast %ptr_486 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_487 = cute.add_offset(%iter_145, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %388 = builtin.unrealized_conversion_cast %ptr_487 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %ptr_488 = cute.add_offset(%iter_145, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %389 = builtin.unrealized_conversion_cast %ptr_488 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_489 = cute.crd2idx(%61, %lay_144) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_490 = cute.add_offset(%ptr_140, %idx_489) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_491 = cute.add_offset(%iter_145, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      %390 = builtin.unrealized_conversion_cast %ptr_491 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_492 = cute.make_int_tuple() : () -> !cute.int_tuple<"18">
      %ptr_493 = cute.add_offset(%iter_145, %int_tuple_492) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"18">) -> !cute.ptr<bf16, rmem, align<4>>
      %391 = builtin.unrealized_conversion_cast %ptr_493 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_494 = cute.make_int_tuple() : () -> !cute.int_tuple<"20">
      %ptr_495 = cute.add_offset(%iter_145, %int_tuple_494) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"20">) -> !cute.ptr<bf16, rmem, align<8>>
      %392 = builtin.unrealized_conversion_cast %ptr_495 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_496 = cute.make_int_tuple() : () -> !cute.int_tuple<"22">
      %ptr_497 = cute.add_offset(%iter_145, %int_tuple_496) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"22">) -> !cute.ptr<bf16, rmem, align<4>>
      %393 = builtin.unrealized_conversion_cast %ptr_497 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_498 = cute.crd2idx(%61, %lay_152) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_499 = cute.add_offset(%ptr_148, %idx_498) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_500 = cute.add_offset(%iter_153, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %394 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      %395 = builtin.unrealized_conversion_cast %iter_145 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %396 = llvm.getelementptr %395[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %397 = llvm.getelementptr %395[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %398 = llvm.getelementptr %395[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_501 = cute.crd2idx(%57, %lay_144) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_502 = cute.add_offset(%ptr_140, %idx_501) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_503 = cute.add_offset(%iter_145, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      %399 = builtin.unrealized_conversion_cast %ptr_503 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_504 = cute.make_int_tuple() : () -> !cute.int_tuple<"34">
      %ptr_505 = cute.add_offset(%iter_145, %int_tuple_504) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %400 = builtin.unrealized_conversion_cast %ptr_505 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_506 = cute.make_int_tuple() : () -> !cute.int_tuple<"36">
      %ptr_507 = cute.add_offset(%iter_145, %int_tuple_506) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"36">) -> !cute.ptr<bf16, rmem, align<8>>
      %401 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_508 = cute.make_int_tuple() : () -> !cute.int_tuple<"38">
      %ptr_509 = cute.add_offset(%iter_145, %int_tuple_508) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"38">) -> !cute.ptr<bf16, rmem, align<4>>
      %402 = builtin.unrealized_conversion_cast %ptr_509 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_510 = cute.crd2idx(%57, %lay_152) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_511 = cute.add_offset(%ptr_148, %idx_510) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_512 = cute.add_offset(%iter_153, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      %403 = builtin.unrealized_conversion_cast %ptr_491 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %404 = llvm.getelementptr %403[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %405 = llvm.getelementptr %403[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %406 = llvm.getelementptr %403[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_513 = cute.crd2idx(%55, %lay_144) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_514 = cute.add_offset(%ptr_140, %idx_513) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_515 = cute.add_offset(%iter_145, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      %407 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_516 = cute.make_int_tuple() : () -> !cute.int_tuple<"50">
      %ptr_517 = cute.add_offset(%iter_145, %int_tuple_516) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"50">) -> !cute.ptr<bf16, rmem, align<4>>
      %408 = builtin.unrealized_conversion_cast %ptr_517 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_518 = cute.make_int_tuple() : () -> !cute.int_tuple<"52">
      %ptr_519 = cute.add_offset(%iter_145, %int_tuple_518) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"52">) -> !cute.ptr<bf16, rmem, align<8>>
      %409 = builtin.unrealized_conversion_cast %ptr_519 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_520 = cute.make_int_tuple() : () -> !cute.int_tuple<"54">
      %ptr_521 = cute.add_offset(%iter_145, %int_tuple_520) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"54">) -> !cute.ptr<bf16, rmem, align<4>>
      %410 = builtin.unrealized_conversion_cast %ptr_521 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_522 = cute.crd2idx(%55, %lay_152) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_523 = cute.add_offset(%ptr_148, %idx_522) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_524 = cute.add_offset(%iter_153, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      %411 = builtin.unrealized_conversion_cast %ptr_503 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %412 = llvm.getelementptr %411[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %413 = llvm.getelementptr %411[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %414 = llvm.getelementptr %411[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %ptr_525 = cute.add_offset(%ptr_140, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_526 = cute.add_offset(%iter_145, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %415 = builtin.unrealized_conversion_cast %ptr_526 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_527 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_528 = cute.add_offset(%iter_145, %int_tuple_527) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
      %416 = builtin.unrealized_conversion_cast %ptr_528 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_529 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_530 = cute.add_offset(%iter_145, %int_tuple_529) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"12">) -> !cute.ptr<bf16, rmem, align<8>>
      %417 = builtin.unrealized_conversion_cast %ptr_530 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_531 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
      %ptr_532 = cute.add_offset(%iter_145, %int_tuple_531) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"14">) -> !cute.ptr<bf16, rmem, align<4>>
      %418 = builtin.unrealized_conversion_cast %ptr_532 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_533 = cute.add_offset(%ptr_148, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_534 = cute.add_offset(%iter_153, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
      %419 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %420 = llvm.getelementptr %419[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %421 = llvm.getelementptr %419[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %422 = llvm.getelementptr %419[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_535 = cute.crd2idx(%51, %lay_144) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_536 = cute.add_offset(%ptr_140, %idx_535) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_537 = cute.add_offset(%iter_145, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %423 = builtin.unrealized_conversion_cast %ptr_537 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_538 = cute.make_int_tuple() : () -> !cute.int_tuple<"26">
      %ptr_539 = cute.add_offset(%iter_145, %int_tuple_538) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"26">) -> !cute.ptr<bf16, rmem, align<4>>
      %424 = builtin.unrealized_conversion_cast %ptr_539 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_540 = cute.make_int_tuple() : () -> !cute.int_tuple<"28">
      %ptr_541 = cute.add_offset(%iter_145, %int_tuple_540) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"28">) -> !cute.ptr<bf16, rmem, align<8>>
      %425 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_542 = cute.make_int_tuple() : () -> !cute.int_tuple<"30">
      %ptr_543 = cute.add_offset(%iter_145, %int_tuple_542) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"30">) -> !cute.ptr<bf16, rmem, align<4>>
      %426 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_544 = cute.crd2idx(%51, %lay_152) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_545 = cute.add_offset(%ptr_148, %idx_544) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_546 = cute.add_offset(%iter_153, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
      %427 = builtin.unrealized_conversion_cast %ptr_526 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %428 = llvm.getelementptr %427[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %429 = llvm.getelementptr %427[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %430 = llvm.getelementptr %427[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_547 = cute.crd2idx(%48, %lay_144) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_548 = cute.add_offset(%ptr_140, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_549 = cute.add_offset(%iter_145, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %431 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_550 = cute.make_int_tuple() : () -> !cute.int_tuple<"42">
      %ptr_551 = cute.add_offset(%iter_145, %int_tuple_550) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"42">) -> !cute.ptr<bf16, rmem, align<4>>
      %432 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_552 = cute.make_int_tuple() : () -> !cute.int_tuple<"44">
      %ptr_553 = cute.add_offset(%iter_145, %int_tuple_552) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"44">) -> !cute.ptr<bf16, rmem, align<8>>
      %433 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_554 = cute.make_int_tuple() : () -> !cute.int_tuple<"46">
      %ptr_555 = cute.add_offset(%iter_145, %int_tuple_554) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"46">) -> !cute.ptr<bf16, rmem, align<4>>
      %434 = builtin.unrealized_conversion_cast %ptr_555 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_556 = cute.crd2idx(%48, %lay_152) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_557 = cute.add_offset(%ptr_148, %idx_556) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_558 = cute.add_offset(%iter_153, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
      %435 = builtin.unrealized_conversion_cast %ptr_537 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %436 = llvm.getelementptr %435[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %437 = llvm.getelementptr %435[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %438 = llvm.getelementptr %435[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_559 = cute.crd2idx(%45, %lay_144) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_560 = cute.add_offset(%ptr_140, %idx_559) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_561 = cute.add_offset(%iter_145, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %439 = builtin.unrealized_conversion_cast %ptr_561 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_562 = cute.make_int_tuple() : () -> !cute.int_tuple<"58">
      %ptr_563 = cute.add_offset(%iter_145, %int_tuple_562) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"58">) -> !cute.ptr<bf16, rmem, align<4>>
      %440 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_564 = cute.make_int_tuple() : () -> !cute.int_tuple<"60">
      %ptr_565 = cute.add_offset(%iter_145, %int_tuple_564) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"60">) -> !cute.ptr<bf16, rmem, align<8>>
      %441 = builtin.unrealized_conversion_cast %ptr_565 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_566 = cute.make_int_tuple() : () -> !cute.int_tuple<"62">
      %ptr_567 = cute.add_offset(%iter_145, %int_tuple_566) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"62">) -> !cute.ptr<bf16, rmem, align<4>>
      %442 = builtin.unrealized_conversion_cast %ptr_567 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_568 = cute.crd2idx(%45, %lay_152) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_569 = cute.add_offset(%ptr_148, %idx_568) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_570 = cute.add_offset(%iter_153, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
      %443 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %444 = llvm.getelementptr %443[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %445 = llvm.getelementptr %443[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %446 = llvm.getelementptr %443[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %447 = builtin.unrealized_conversion_cast %ptr_561 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %448 = llvm.getelementptr %447[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %449 = llvm.getelementptr %447[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %450 = llvm.getelementptr %447[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %451:2 = cute.get_scalars(%lay_158) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iv_571 = cute.assume(%451#0) : (i32) -> !cute.i32<divby 16>
      %iv_572 = cute.assume(%451#1) : (i32) -> !cute.i32<divby 32>
      %stride_573 = cute.make_stride(%iv_571, %iv_572) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_574 = cute.make_layout(%12, %stride_573) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %append_575 = cute.append_to_rank<2> (%lay_574, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %452:2 = cute.get_scalars(%append_575) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %iv_576 = cute.assume(%452#0) : (i32) -> !cute.i32<divby 16>
      %iv_577 = cute.assume(%452#1) : (i32) -> !cute.i32<divby 32>
      %stride_578 = cute.make_stride(%iv_576, %iv_577) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_579 = cute.make_layout(%11, %stride_578) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %append_580 = cute.append_to_rank<2> (%lay_579, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %453:2 = cute.get_scalars(%append_580) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %iv_581 = cute.assume(%453#0) : (i32) -> !cute.i32<divby 16>
      %iv_582 = cute.assume(%453#1) : (i32) -> !cute.i32<divby 32>
      %stride_583 = cute.make_stride(%iv_581, %iv_582) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_584 = cute.make_layout(%10, %stride_583) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %ptr_585 = cute.add_offset(%ptr_156, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_586 = cute.add_offset(%iter_159, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %iter_587 = cute.get_iter(%rmem_136) : !memref_rmem_f32_
      %454 = cute.get_scalars(%60) : !cute.int_tuple<"16">
      %ptr_588 = cute.add_offset(%ptr_156, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_589 = cute.add_offset(%iter_159, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_590 = cute.add_offset(%ptr_156, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_591 = cute.add_offset(%iter_159, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb73(%c-1_i32 : i32)
    ^bb73(%455: i32):  // 2 preds: ^bb72, ^bb304
      %456 = arith.cmpi slt, %455, %128 : i32
      cf.cond_br %456, ^bb74, ^bb305
    ^bb74:  // pred: ^bb73
      %int_tuple_592 = cute.make_int_tuple(%455) : (i32) -> !cute.int_tuple<"?">
      %sub_593 = cute.tuple_sub(%tup_472, %int_tuple_592) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %457 = cute.get_scalars(%sub_593) : !cute.int_tuple<"?">
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %458 = arith.cmpi eq, %457, %128 : i32
      cf.cond_br %458, ^bb75, ^bb100
    ^bb75:  // pred: ^bb74
      %459 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_594, %e1_595, %e2_596, %e3_597 = cute.get_leaves(%459) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_598 = cute.to_int_tuple(%e1_595) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_599 = cute.make_coord(%itup_598) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %460 = cute.get_scalars(%coord_599) : !cute.coord<"?">
      %461 = arith.cmpi slt, %294, %460 : i32
      cf.cond_br %461, ^bb76, ^bb80
    ^bb76:  // pred: ^bb75
      %coord_600 = cute.make_coord(%sub_593) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_601 = cute.crd2idx(%coord_600, %lay_124) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_602 = cute.add_offset(%ptr_119, %idx_601) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_603 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %462 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb77(%c0_i32 : i32)
    ^bb77(%463: i32):  // 2 preds: ^bb76, ^bb78
      %464 = arith.cmpi slt, %463, %462 : i32
      cf.cond_br %464, ^bb78, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb78:  // pred: ^bb77
      %coord_604 = cute.make_coord(%463) : (i32) -> !cute.coord<"(_,?)">
      %idx_605 = cute.crd2idx(%coord_604, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_606 = cute.add_offset(%ptr_602, %idx_605) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_607 = cute.crd2idx(%coord_604, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_608 = cute.add_offset(%ptr_125, %idx_607) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_609 = cute.crd2idx(%coord_604, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_610 = cute.add_offset(%iter_603, %idx_609) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %465 = builtin.unrealized_conversion_cast %ptr_610 : !cute.ptr<i8, rmem> to !llvm.ptr
      %466 = llvm.load %465 : !llvm.ptr -> i8
      %467 = llvm.trunc %466 : i8 to i1
      %iter_611 = cute.recast_iter(%ptr_606) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_612 = cute.recast_iter(%ptr_608) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_612 : !cute.ptr<i128, smem>, %iter_611 : !cute.ptr<i128, gmem>, %467 : i1) {cache_mode = <always>}
      %468 = arith.addi %463, %c1_i32 : i32
      cf.br ^bb77(%468 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb81
    ^bb80:  // pred: ^bb75
      %view_613 = cute.make_view(%ptr_125) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_613 : !memref_smem_bf16_
      cf.br ^bb81
    ^bb81:  // 2 preds: ^bb79, ^bb80
      %469 = arith.cmpi slt, %304, %460 : i32
      cf.cond_br %469, ^bb82, ^bb86
    ^bb82:  // pred: ^bb81
      %coord_614 = cute.make_coord(%sub_593) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_615 = cute.crd2idx(%coord_614, %lay_124) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_616 = cute.add_offset(%ptr_119, %idx_615) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_617 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_618 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %470 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb83(%c0_i32 : i32)
    ^bb83(%471: i32):  // 2 preds: ^bb82, ^bb84
      %472 = arith.cmpi slt, %471, %470 : i32
      cf.cond_br %472, ^bb84, ^bb85 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      %coord_619 = cute.make_coord(%471) : (i32) -> !cute.coord<"(_,?)">
      %idx_620 = cute.crd2idx(%coord_619, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_621 = cute.add_offset(%ptr_616, %idx_620) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_622 = cute.crd2idx(%coord_619, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_623 = cute.add_offset(%ptr_617, %idx_622) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_624 = cute.crd2idx(%coord_619, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_625 = cute.add_offset(%iter_618, %idx_624) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %473 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<i8, rmem> to !llvm.ptr
      %474 = llvm.load %473 : !llvm.ptr -> i8
      %475 = llvm.trunc %474 : i8 to i1
      %iter_626 = cute.recast_iter(%ptr_621) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_627 = cute.recast_iter(%ptr_623) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_627 : !cute.ptr<i128, smem>, %iter_626 : !cute.ptr<i128, gmem>, %475 : i1) {cache_mode = <always>}
      %476 = arith.addi %471, %c1_i32 : i32
      cf.br ^bb83(%476 : i32)
    ^bb85:  // pred: ^bb83
      cf.br ^bb87
    ^bb86:  // pred: ^bb81
      %ptr_628 = cute.add_offset(%ptr_125, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_629 = cute.make_view(%ptr_628) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_629 : !memref_smem_bf16_
      cf.br ^bb87
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %477 = arith.cmpi slt, %313, %460 : i32
      cf.cond_br %477, ^bb88, ^bb92
    ^bb88:  // pred: ^bb87
      %coord_630 = cute.make_coord(%sub_593) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_631 = cute.crd2idx(%coord_630, %lay_124) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_632 = cute.add_offset(%ptr_119, %idx_631) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_633 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_634 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %478 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%479: i32):  // 2 preds: ^bb88, ^bb90
      %480 = arith.cmpi slt, %479, %478 : i32
      cf.cond_br %480, ^bb90, ^bb91 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      %coord_635 = cute.make_coord(%479) : (i32) -> !cute.coord<"(_,?)">
      %idx_636 = cute.crd2idx(%coord_635, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_637 = cute.add_offset(%ptr_632, %idx_636) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_638 = cute.crd2idx(%coord_635, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_639 = cute.add_offset(%ptr_633, %idx_638) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_640 = cute.crd2idx(%coord_635, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_641 = cute.add_offset(%iter_634, %idx_640) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %481 = builtin.unrealized_conversion_cast %ptr_641 : !cute.ptr<i8, rmem> to !llvm.ptr
      %482 = llvm.load %481 : !llvm.ptr -> i8
      %483 = llvm.trunc %482 : i8 to i1
      %iter_642 = cute.recast_iter(%ptr_637) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_643 = cute.recast_iter(%ptr_639) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_643 : !cute.ptr<i128, smem>, %iter_642 : !cute.ptr<i128, gmem>, %483 : i1) {cache_mode = <always>}
      %484 = arith.addi %479, %c1_i32 : i32
      cf.br ^bb89(%484 : i32)
    ^bb91:  // pred: ^bb89
      cf.br ^bb93
    ^bb92:  // pred: ^bb87
      %ptr_644 = cute.add_offset(%ptr_125, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_645 = cute.make_view(%ptr_644) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_645 : !memref_smem_bf16_
      cf.br ^bb93
    ^bb93:  // 2 preds: ^bb91, ^bb92
      %485 = arith.cmpi slt, %322, %460 : i32
      cf.cond_br %485, ^bb94, ^bb98
    ^bb94:  // pred: ^bb93
      %coord_646 = cute.make_coord(%sub_593) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_647 = cute.crd2idx(%coord_646, %lay_124) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_648 = cute.add_offset(%ptr_119, %idx_647) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_649 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_650 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %486 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb95(%c0_i32 : i32)
    ^bb95(%487: i32):  // 2 preds: ^bb94, ^bb96
      %488 = arith.cmpi slt, %487, %486 : i32
      cf.cond_br %488, ^bb96, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb96:  // pred: ^bb95
      %coord_651 = cute.make_coord(%487) : (i32) -> !cute.coord<"(_,?)">
      %idx_652 = cute.crd2idx(%coord_651, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_653 = cute.add_offset(%ptr_648, %idx_652) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_654 = cute.crd2idx(%coord_651, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_655 = cute.add_offset(%ptr_649, %idx_654) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_656 = cute.crd2idx(%coord_651, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_657 = cute.add_offset(%iter_650, %idx_656) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %489 = builtin.unrealized_conversion_cast %ptr_657 : !cute.ptr<i8, rmem> to !llvm.ptr
      %490 = llvm.load %489 : !llvm.ptr -> i8
      %491 = llvm.trunc %490 : i8 to i1
      %iter_658 = cute.recast_iter(%ptr_653) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_659 = cute.recast_iter(%ptr_655) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_659 : !cute.ptr<i128, smem>, %iter_658 : !cute.ptr<i128, gmem>, %491 : i1) {cache_mode = <always>}
      %492 = arith.addi %487, %c1_i32 : i32
      cf.br ^bb95(%492 : i32)
    ^bb97:  // pred: ^bb95
      cf.br ^bb99
    ^bb98:  // pred: ^bb93
      %ptr_660 = cute.add_offset(%ptr_125, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_661 = cute.make_view(%ptr_660) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_661 : !memref_smem_bf16_
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb104
    ^bb100:  // pred: ^bb74
      %coord_662 = cute.make_coord(%sub_593) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
      %493:3 = cute.get_scalars(%lay_124) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_663 = cute.assume(%493#1) : (i64) -> !cute.i64<divby 128>
      %stride_664 = cute.make_stride(%iv_663) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_665 = cute.make_layout(%111, %stride_664) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_666 = cute.crd2idx(%coord_662, %lay_124) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_667 = cute.add_offset(%ptr_119, %idx_666) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_668 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %append_669 = cute.append_to_rank<2> (%lay_665, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %494 = cute.get_scalars(%append_669) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_670 = cute.assume(%494) : (i64) -> !cute.i64<divby 128>
      %stride_671 = cute.make_stride(%iv_670) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_672 = cute.make_layout(%80, %stride_671) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_673 = cute.append_to_rank<2> (%lay_672, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %495 = cute.get_scalars(%append_673) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_674 = cute.assume(%495) : (i64) -> !cute.i64<divby 128>
      %stride_675 = cute.make_stride(%iv_674) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_676 = cute.make_layout(%79, %stride_675) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      %496 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      cf.br ^bb101(%c0_i32 : i32)
    ^bb101(%497: i32):  // 2 preds: ^bb100, ^bb102
      %498 = arith.cmpi slt, %497, %496 : i32
      cf.cond_br %498, ^bb102, ^bb103 {llvm.loop_annotation = #loop_annotation}
    ^bb102:  // pred: ^bb101
      %coord_677 = cute.make_coord(%497) : (i32) -> !cute.coord<"(_,?)">
      %idx_678 = cute.crd2idx(%coord_677, %lay_676) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_679 = cute.add_offset(%ptr_667, %idx_678) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_680 = cute.crd2idx(%coord_677, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_681 = cute.add_offset(%ptr_125, %idx_680) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_682 = cute.crd2idx(%coord_677, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_683 = cute.add_offset(%iter_668, %idx_682) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %499 = builtin.unrealized_conversion_cast %ptr_683 : !cute.ptr<i8, rmem> to !llvm.ptr
      %500 = llvm.load %499 : !llvm.ptr -> i8
      %501 = llvm.trunc %500 : i8 to i1
      %iter_684 = cute.recast_iter(%ptr_679) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_685 = cute.recast_iter(%ptr_681) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_685 : !cute.ptr<i128, smem>, %iter_684 : !cute.ptr<i128, gmem>, %501 : i1) {cache_mode = <always>}
      %502 = arith.addi %497, %c1_i32 : i32
      cf.br ^bb101(%502 : i32)
    ^bb103:  // pred: ^bb101
      cf.br ^bb104
    ^bb104:  // 2 preds: ^bb99, ^bb103
      nvvm.cp.async.commit.group
      %rmem_686 = cute.memref.alloca() : !memref_rmem_f32_1
      %rmem_687 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_688 = cute.get_iter(%rmem_687) : !memref_rmem_bf16_3
      cf.br ^bb105(%c0_i32 : i32)
    ^bb105(%503: i32):  // 2 preds: ^bb104, ^bb106
      %504 = arith.cmpi slt, %503, %384 : i32
      cf.cond_br %504, ^bb106, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb106:  // pred: ^bb105
      %coord_689 = cute.make_coord(%503) : (i32) -> !cute.coord<"(_,?)">
      %idx_690 = cute.crd2idx(%coord_689, %lay_485) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_691 = cute.add_offset(%ptr_160, %idx_690) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_692 = cute.crd2idx(%coord_689, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_693 = cute.add_offset(%iter_688, %idx_692) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %505 = cute_nvgpu.arch.copy.ldsm %ptr_691{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %506 = vector.extractelement %505[%70 : i32] : vector<4xi32>
      %507 = builtin.unrealized_conversion_cast %ptr_693 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %506, %507 : i32, !llvm.ptr
      %508 = vector.extractelement %505[%69 : i32] : vector<4xi32>
      %ptr_694 = cute.add_offset(%ptr_693, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %509 = builtin.unrealized_conversion_cast %ptr_694 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %508, %509 : i32, !llvm.ptr
      %510 = vector.extractelement %505[%68 : i32] : vector<4xi32>
      %ptr_695 = cute.add_offset(%ptr_693, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %511 = builtin.unrealized_conversion_cast %ptr_695 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %510, %511 : i32, !llvm.ptr
      %512 = vector.extractelement %505[%67 : i32] : vector<4xi32>
      %ptr_696 = cute.add_offset(%ptr_693, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %513 = builtin.unrealized_conversion_cast %ptr_696 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %512, %513 : i32, !llvm.ptr
      %514 = arith.addi %503, %c1_i32 : i32
      cf.br ^bb105(%514 : i32)
    ^bb107:  // pred: ^bb105
      %515 = cute.memref.load_vec %rmem_687 : !memref_rmem_bf16_3
      %516 = arith.extf %515 : vector<32xbf16> to vector<32xf32>
      cute.memref.store_vec %516, %rmem_686 : !memref_rmem_f32_1
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%517: i32):  // 2 preds: ^bb107, ^bb109
      %518 = arith.cmpi slt, %517, %385 : i32
      cf.cond_br %518, ^bb109, ^bb110 {llvm.loop_annotation = #loop_annotation}
    ^bb109:  // pred: ^bb108
      %519 = cute_nvgpu.arch.copy.ldsm %ptr_140{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %520 = vector.extractelement %519[%70 : i32] : vector<4xi32>
      llvm.store %520, %386 : i32, !llvm.ptr
      %521 = vector.extractelement %519[%69 : i32] : vector<4xi32>
      llvm.store %521, %387 : i32, !llvm.ptr
      %522 = vector.extractelement %519[%68 : i32] : vector<4xi32>
      llvm.store %522, %388 : i32, !llvm.ptr
      %523 = vector.extractelement %519[%67 : i32] : vector<4xi32>
      llvm.store %523, %389 : i32, !llvm.ptr
      %524 = arith.addi %517, %c1_i32 : i32
      cf.br ^bb108(%524 : i32)
    ^bb110:  // pred: ^bb108
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%525: i32):  // 2 preds: ^bb110, ^bb112
      %526 = arith.cmpi slt, %525, %384 : i32
      cf.cond_br %526, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_697 = cute.make_coord(%525) : (i32) -> !cute.coord<"(_,?)">
      %idx_698 = cute.crd2idx(%coord_697, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_699 = cute.add_offset(%ptr_148, %idx_698) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_700 = cute.crd2idx(%coord_697, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_701 = cute.add_offset(%iter_153, %idx_700) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %527 = cute_nvgpu.arch.copy.ldsm %ptr_699{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %528 = vector.extractelement %527[%70 : i32] : vector<4xi32>
      %529 = builtin.unrealized_conversion_cast %ptr_701 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %528, %529 : i32, !llvm.ptr
      %530 = vector.extractelement %527[%69 : i32] : vector<4xi32>
      %ptr_702 = cute.add_offset(%ptr_701, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %531 = builtin.unrealized_conversion_cast %ptr_702 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %530, %531 : i32, !llvm.ptr
      %532 = vector.extractelement %527[%68 : i32] : vector<4xi32>
      %ptr_703 = cute.add_offset(%ptr_701, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %533 = builtin.unrealized_conversion_cast %ptr_703 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %532, %533 : i32, !llvm.ptr
      %534 = vector.extractelement %527[%67 : i32] : vector<4xi32>
      %ptr_704 = cute.add_offset(%ptr_701, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %535 = builtin.unrealized_conversion_cast %ptr_704 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %534, %535 : i32, !llvm.ptr
      %536 = arith.addi %525, %c1_i32 : i32
      cf.br ^bb111(%536 : i32)
    ^bb113:  // pred: ^bb111
      cf.br ^bb114(%c0_i32 : i32)
    ^bb114(%537: i32):  // 2 preds: ^bb113, ^bb115
      %538 = arith.cmpi slt, %537, %385 : i32
      cf.cond_br %538, ^bb115, ^bb116 {llvm.loop_annotation = #loop_annotation}
    ^bb115:  // pred: ^bb114
      %539 = cute_nvgpu.arch.copy.ldsm %ptr_490{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %540 = vector.extractelement %539[%70 : i32] : vector<4xi32>
      llvm.store %540, %390 : i32, !llvm.ptr
      %541 = vector.extractelement %539[%69 : i32] : vector<4xi32>
      llvm.store %541, %391 : i32, !llvm.ptr
      %542 = vector.extractelement %539[%68 : i32] : vector<4xi32>
      llvm.store %542, %392 : i32, !llvm.ptr
      %543 = vector.extractelement %539[%67 : i32] : vector<4xi32>
      llvm.store %543, %393 : i32, !llvm.ptr
      %544 = arith.addi %537, %c1_i32 : i32
      cf.br ^bb114(%544 : i32)
    ^bb116:  // pred: ^bb114
      cf.br ^bb117(%c0_i32 : i32)
    ^bb117(%545: i32):  // 2 preds: ^bb116, ^bb118
      %546 = arith.cmpi slt, %545, %384 : i32
      cf.cond_br %546, ^bb118, ^bb119 {llvm.loop_annotation = #loop_annotation}
    ^bb118:  // pred: ^bb117
      %coord_705 = cute.make_coord(%545) : (i32) -> !cute.coord<"(_,?)">
      %idx_706 = cute.crd2idx(%coord_705, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_707 = cute.add_offset(%ptr_499, %idx_706) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_708 = cute.crd2idx(%coord_705, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_709 = cute.add_offset(%ptr_500, %idx_708) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %547 = cute_nvgpu.arch.copy.ldsm %ptr_707{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %548 = vector.extractelement %547[%70 : i32] : vector<4xi32>
      %549 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %548, %549 : i32, !llvm.ptr
      %550 = vector.extractelement %547[%69 : i32] : vector<4xi32>
      %ptr_710 = cute.add_offset(%ptr_709, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %551 = builtin.unrealized_conversion_cast %ptr_710 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %550, %551 : i32, !llvm.ptr
      %552 = vector.extractelement %547[%68 : i32] : vector<4xi32>
      %ptr_711 = cute.add_offset(%ptr_709, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %553 = builtin.unrealized_conversion_cast %ptr_711 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %552, %553 : i32, !llvm.ptr
      %554 = vector.extractelement %547[%67 : i32] : vector<4xi32>
      %ptr_712 = cute.add_offset(%ptr_709, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %555 = builtin.unrealized_conversion_cast %ptr_712 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %554, %555 : i32, !llvm.ptr
      %556 = arith.addi %545, %c1_i32 : i32
      cf.br ^bb117(%556 : i32)
    ^bb119:  // pred: ^bb117
      %iter_713 = cute.get_iter(%rmem_686) : !memref_rmem_f32_1
      cf.br ^bb120(%c0_i32 : i32)
    ^bb120(%557: i32):  // 2 preds: ^bb119, ^bb127
      %558 = arith.cmpi slt, %557, %385 : i32
      cf.cond_br %558, ^bb121, ^bb128 {llvm.loop_annotation = #loop_annotation}
    ^bb121:  // pred: ^bb120
      cf.br ^bb122(%c0_i32 : i32)
    ^bb122(%559: i32):  // 2 preds: ^bb121, ^bb126
      %560 = arith.cmpi slt, %559, %385 : i32
      cf.cond_br %560, ^bb123, ^bb127 {llvm.loop_annotation = #loop_annotation}
    ^bb123:  // pred: ^bb122
      cf.br ^bb124(%c0_i32 : i32)
    ^bb124(%561: i32):  // 2 preds: ^bb123, ^bb125
      %562 = arith.cmpi slt, %561, %394 : i32
      cf.cond_br %562, ^bb125, ^bb126 {llvm.loop_annotation = #loop_annotation}
    ^bb125:  // pred: ^bb124
      %coord_714 = cute.make_coord(%561, %557) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_715 = cute.make_coord(%559, %561) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_716 = cute.crd2idx(%coord_714, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_717 = cute.add_offset(%iter_153, %idx_716) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_718 = cute.crd2idx(%coord_715, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_719 = cute.add_offset(%iter_713, %idx_718) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %563 = llvm.load %395 : !llvm.ptr -> i32
      %564 = llvm.load %396 : !llvm.ptr -> i32
      %565 = llvm.load %397 : !llvm.ptr -> i32
      %566 = llvm.load %398 : !llvm.ptr -> i32
      %567 = builtin.unrealized_conversion_cast %ptr_717 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %568 = llvm.load %567 : !llvm.ptr -> i32
      %569 = llvm.getelementptr %567[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %570 = llvm.load %569 : !llvm.ptr -> i32
      %571 = builtin.unrealized_conversion_cast %ptr_719 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %572 = llvm.load %571 : !llvm.ptr -> f32
      %573 = llvm.getelementptr %571[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %574 = llvm.load %573 : !llvm.ptr -> f32
      %575 = llvm.getelementptr %571[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %576 = llvm.load %575 : !llvm.ptr -> f32
      %577 = llvm.getelementptr %571[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %578 = llvm.load %577 : !llvm.ptr -> f32
      %579:4 = cute_nvgpu.arch.mma.SM80 A[%563, %564, %565, %566]  B[%568, %570]  C[%572, %574, %576, %578] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %579#0, %571 : f32, !llvm.ptr
      llvm.store %579#1, %573 : f32, !llvm.ptr
      llvm.store %579#2, %575 : f32, !llvm.ptr
      llvm.store %579#3, %577 : f32, !llvm.ptr
      %580 = arith.addi %561, %c1_i32 : i32
      cf.br ^bb124(%580 : i32)
    ^bb126:  // pred: ^bb124
      %581 = arith.addi %559, %c1_i32 : i32
      cf.br ^bb122(%581 : i32)
    ^bb127:  // pred: ^bb122
      %582 = arith.addi %557, %c1_i32 : i32
      cf.br ^bb120(%582 : i32)
    ^bb128:  // pred: ^bb120
      cf.br ^bb129(%c0_i32 : i32)
    ^bb129(%583: i32):  // 2 preds: ^bb128, ^bb130
      %584 = arith.cmpi slt, %583, %385 : i32
      cf.cond_br %584, ^bb130, ^bb131 {llvm.loop_annotation = #loop_annotation}
    ^bb130:  // pred: ^bb129
      %585 = cute_nvgpu.arch.copy.ldsm %ptr_502{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %586 = vector.extractelement %585[%70 : i32] : vector<4xi32>
      llvm.store %586, %399 : i32, !llvm.ptr
      %587 = vector.extractelement %585[%69 : i32] : vector<4xi32>
      llvm.store %587, %400 : i32, !llvm.ptr
      %588 = vector.extractelement %585[%68 : i32] : vector<4xi32>
      llvm.store %588, %401 : i32, !llvm.ptr
      %589 = vector.extractelement %585[%67 : i32] : vector<4xi32>
      llvm.store %589, %402 : i32, !llvm.ptr
      %590 = arith.addi %583, %c1_i32 : i32
      cf.br ^bb129(%590 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%c0_i32 : i32)
    ^bb132(%591: i32):  // 2 preds: ^bb131, ^bb133
      %592 = arith.cmpi slt, %591, %384 : i32
      cf.cond_br %592, ^bb133, ^bb134 {llvm.loop_annotation = #loop_annotation}
    ^bb133:  // pred: ^bb132
      %coord_720 = cute.make_coord(%591) : (i32) -> !cute.coord<"(_,?)">
      %idx_721 = cute.crd2idx(%coord_720, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_722 = cute.add_offset(%ptr_511, %idx_721) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_723 = cute.crd2idx(%coord_720, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_724 = cute.add_offset(%ptr_512, %idx_723) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %593 = cute_nvgpu.arch.copy.ldsm %ptr_722{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %594 = vector.extractelement %593[%70 : i32] : vector<4xi32>
      %595 = builtin.unrealized_conversion_cast %ptr_724 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %594, %595 : i32, !llvm.ptr
      %596 = vector.extractelement %593[%69 : i32] : vector<4xi32>
      %ptr_725 = cute.add_offset(%ptr_724, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %597 = builtin.unrealized_conversion_cast %ptr_725 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %596, %597 : i32, !llvm.ptr
      %598 = vector.extractelement %593[%68 : i32] : vector<4xi32>
      %ptr_726 = cute.add_offset(%ptr_724, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %599 = builtin.unrealized_conversion_cast %ptr_726 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %598, %599 : i32, !llvm.ptr
      %600 = vector.extractelement %593[%67 : i32] : vector<4xi32>
      %ptr_727 = cute.add_offset(%ptr_724, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %601 = builtin.unrealized_conversion_cast %ptr_727 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %600, %601 : i32, !llvm.ptr
      %602 = arith.addi %591, %c1_i32 : i32
      cf.br ^bb132(%602 : i32)
    ^bb134:  // pred: ^bb132
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%603: i32):  // 2 preds: ^bb134, ^bb142
      %604 = arith.cmpi slt, %603, %385 : i32
      cf.cond_br %604, ^bb136, ^bb143 {llvm.loop_annotation = #loop_annotation}
    ^bb136:  // pred: ^bb135
      cf.br ^bb137(%c0_i32 : i32)
    ^bb137(%605: i32):  // 2 preds: ^bb136, ^bb141
      %606 = arith.cmpi slt, %605, %385 : i32
      cf.cond_br %606, ^bb138, ^bb142 {llvm.loop_annotation = #loop_annotation}
    ^bb138:  // pred: ^bb137
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%607: i32):  // 2 preds: ^bb138, ^bb140
      %608 = arith.cmpi slt, %607, %394 : i32
      cf.cond_br %608, ^bb140, ^bb141 {llvm.loop_annotation = #loop_annotation}
    ^bb140:  // pred: ^bb139
      %coord_728 = cute.make_coord(%607, %603) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_729 = cute.make_coord(%605, %607) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_730 = cute.crd2idx(%coord_728, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_731 = cute.add_offset(%ptr_500, %idx_730) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_732 = cute.crd2idx(%coord_729, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_733 = cute.add_offset(%iter_713, %idx_732) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %609 = llvm.load %403 : !llvm.ptr -> i32
      %610 = llvm.load %404 : !llvm.ptr -> i32
      %611 = llvm.load %405 : !llvm.ptr -> i32
      %612 = llvm.load %406 : !llvm.ptr -> i32
      %613 = builtin.unrealized_conversion_cast %ptr_731 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %614 = llvm.load %613 : !llvm.ptr -> i32
      %615 = llvm.getelementptr %613[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %616 = llvm.load %615 : !llvm.ptr -> i32
      %617 = builtin.unrealized_conversion_cast %ptr_733 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %618 = llvm.load %617 : !llvm.ptr -> f32
      %619 = llvm.getelementptr %617[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %620 = llvm.load %619 : !llvm.ptr -> f32
      %621 = llvm.getelementptr %617[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %622 = llvm.load %621 : !llvm.ptr -> f32
      %623 = llvm.getelementptr %617[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %624 = llvm.load %623 : !llvm.ptr -> f32
      %625:4 = cute_nvgpu.arch.mma.SM80 A[%609, %610, %611, %612]  B[%614, %616]  C[%618, %620, %622, %624] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %625#0, %617 : f32, !llvm.ptr
      llvm.store %625#1, %619 : f32, !llvm.ptr
      llvm.store %625#2, %621 : f32, !llvm.ptr
      llvm.store %625#3, %623 : f32, !llvm.ptr
      %626 = arith.addi %607, %c1_i32 : i32
      cf.br ^bb139(%626 : i32)
    ^bb141:  // pred: ^bb139
      %627 = arith.addi %605, %c1_i32 : i32
      cf.br ^bb137(%627 : i32)
    ^bb142:  // pred: ^bb137
      %628 = arith.addi %603, %c1_i32 : i32
      cf.br ^bb135(%628 : i32)
    ^bb143:  // pred: ^bb135
      cf.br ^bb144(%c0_i32 : i32)
    ^bb144(%629: i32):  // 2 preds: ^bb143, ^bb145
      %630 = arith.cmpi slt, %629, %385 : i32
      cf.cond_br %630, ^bb145, ^bb146 {llvm.loop_annotation = #loop_annotation}
    ^bb145:  // pred: ^bb144
      %631 = cute_nvgpu.arch.copy.ldsm %ptr_514{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %632 = vector.extractelement %631[%70 : i32] : vector<4xi32>
      llvm.store %632, %407 : i32, !llvm.ptr
      %633 = vector.extractelement %631[%69 : i32] : vector<4xi32>
      llvm.store %633, %408 : i32, !llvm.ptr
      %634 = vector.extractelement %631[%68 : i32] : vector<4xi32>
      llvm.store %634, %409 : i32, !llvm.ptr
      %635 = vector.extractelement %631[%67 : i32] : vector<4xi32>
      llvm.store %635, %410 : i32, !llvm.ptr
      %636 = arith.addi %629, %c1_i32 : i32
      cf.br ^bb144(%636 : i32)
    ^bb146:  // pred: ^bb144
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%637: i32):  // 2 preds: ^bb146, ^bb148
      %638 = arith.cmpi slt, %637, %384 : i32
      cf.cond_br %638, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation}
    ^bb148:  // pred: ^bb147
      %coord_734 = cute.make_coord(%637) : (i32) -> !cute.coord<"(_,?)">
      %idx_735 = cute.crd2idx(%coord_734, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_736 = cute.add_offset(%ptr_523, %idx_735) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_737 = cute.crd2idx(%coord_734, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_738 = cute.add_offset(%ptr_524, %idx_737) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %639 = cute_nvgpu.arch.copy.ldsm %ptr_736{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %640 = vector.extractelement %639[%70 : i32] : vector<4xi32>
      %641 = builtin.unrealized_conversion_cast %ptr_738 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %640, %641 : i32, !llvm.ptr
      %642 = vector.extractelement %639[%69 : i32] : vector<4xi32>
      %ptr_739 = cute.add_offset(%ptr_738, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %643 = builtin.unrealized_conversion_cast %ptr_739 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %642, %643 : i32, !llvm.ptr
      %644 = vector.extractelement %639[%68 : i32] : vector<4xi32>
      %ptr_740 = cute.add_offset(%ptr_738, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %645 = builtin.unrealized_conversion_cast %ptr_740 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %644, %645 : i32, !llvm.ptr
      %646 = vector.extractelement %639[%67 : i32] : vector<4xi32>
      %ptr_741 = cute.add_offset(%ptr_738, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %647 = builtin.unrealized_conversion_cast %ptr_741 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %646, %647 : i32, !llvm.ptr
      %648 = arith.addi %637, %c1_i32 : i32
      cf.br ^bb147(%648 : i32)
    ^bb149:  // pred: ^bb147
      cf.br ^bb150(%c0_i32 : i32)
    ^bb150(%649: i32):  // 2 preds: ^bb149, ^bb157
      %650 = arith.cmpi slt, %649, %385 : i32
      cf.cond_br %650, ^bb151, ^bb158 {llvm.loop_annotation = #loop_annotation}
    ^bb151:  // pred: ^bb150
      cf.br ^bb152(%c0_i32 : i32)
    ^bb152(%651: i32):  // 2 preds: ^bb151, ^bb156
      %652 = arith.cmpi slt, %651, %385 : i32
      cf.cond_br %652, ^bb153, ^bb157 {llvm.loop_annotation = #loop_annotation}
    ^bb153:  // pred: ^bb152
      cf.br ^bb154(%c0_i32 : i32)
    ^bb154(%653: i32):  // 2 preds: ^bb153, ^bb155
      %654 = arith.cmpi slt, %653, %394 : i32
      cf.cond_br %654, ^bb155, ^bb156 {llvm.loop_annotation = #loop_annotation}
    ^bb155:  // pred: ^bb154
      %coord_742 = cute.make_coord(%653, %649) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_743 = cute.make_coord(%651, %653) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_744 = cute.crd2idx(%coord_742, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_745 = cute.add_offset(%ptr_512, %idx_744) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_746 = cute.crd2idx(%coord_743, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_747 = cute.add_offset(%iter_713, %idx_746) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %655 = llvm.load %411 : !llvm.ptr -> i32
      %656 = llvm.load %412 : !llvm.ptr -> i32
      %657 = llvm.load %413 : !llvm.ptr -> i32
      %658 = llvm.load %414 : !llvm.ptr -> i32
      %659 = builtin.unrealized_conversion_cast %ptr_745 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %660 = llvm.load %659 : !llvm.ptr -> i32
      %661 = llvm.getelementptr %659[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %662 = llvm.load %661 : !llvm.ptr -> i32
      %663 = builtin.unrealized_conversion_cast %ptr_747 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %664 = llvm.load %663 : !llvm.ptr -> f32
      %665 = llvm.getelementptr %663[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %666 = llvm.load %665 : !llvm.ptr -> f32
      %667 = llvm.getelementptr %663[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %668 = llvm.load %667 : !llvm.ptr -> f32
      %669 = llvm.getelementptr %663[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %670 = llvm.load %669 : !llvm.ptr -> f32
      %671:4 = cute_nvgpu.arch.mma.SM80 A[%655, %656, %657, %658]  B[%660, %662]  C[%664, %666, %668, %670] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %671#0, %663 : f32, !llvm.ptr
      llvm.store %671#1, %665 : f32, !llvm.ptr
      llvm.store %671#2, %667 : f32, !llvm.ptr
      llvm.store %671#3, %669 : f32, !llvm.ptr
      %672 = arith.addi %653, %c1_i32 : i32
      cf.br ^bb154(%672 : i32)
    ^bb156:  // pred: ^bb154
      %673 = arith.addi %651, %c1_i32 : i32
      cf.br ^bb152(%673 : i32)
    ^bb157:  // pred: ^bb152
      %674 = arith.addi %649, %c1_i32 : i32
      cf.br ^bb150(%674 : i32)
    ^bb158:  // pred: ^bb150
      cf.br ^bb159(%c0_i32 : i32)
    ^bb159(%675: i32):  // 2 preds: ^bb158, ^bb160
      %676 = arith.cmpi slt, %675, %385 : i32
      cf.cond_br %676, ^bb160, ^bb161 {llvm.loop_annotation = #loop_annotation}
    ^bb160:  // pred: ^bb159
      %677 = cute_nvgpu.arch.copy.ldsm %ptr_525{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %678 = vector.extractelement %677[%70 : i32] : vector<4xi32>
      llvm.store %678, %415 : i32, !llvm.ptr
      %679 = vector.extractelement %677[%69 : i32] : vector<4xi32>
      llvm.store %679, %416 : i32, !llvm.ptr
      %680 = vector.extractelement %677[%68 : i32] : vector<4xi32>
      llvm.store %680, %417 : i32, !llvm.ptr
      %681 = vector.extractelement %677[%67 : i32] : vector<4xi32>
      llvm.store %681, %418 : i32, !llvm.ptr
      %682 = arith.addi %675, %c1_i32 : i32
      cf.br ^bb159(%682 : i32)
    ^bb161:  // pred: ^bb159
      cf.br ^bb162(%c0_i32 : i32)
    ^bb162(%683: i32):  // 2 preds: ^bb161, ^bb163
      %684 = arith.cmpi slt, %683, %384 : i32
      cf.cond_br %684, ^bb163, ^bb164 {llvm.loop_annotation = #loop_annotation}
    ^bb163:  // pred: ^bb162
      %coord_748 = cute.make_coord(%683) : (i32) -> !cute.coord<"(_,?)">
      %idx_749 = cute.crd2idx(%coord_748, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_750 = cute.add_offset(%ptr_533, %idx_749) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_751 = cute.crd2idx(%coord_748, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_752 = cute.add_offset(%ptr_534, %idx_751) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %685 = cute_nvgpu.arch.copy.ldsm %ptr_750{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %686 = vector.extractelement %685[%70 : i32] : vector<4xi32>
      %687 = builtin.unrealized_conversion_cast %ptr_752 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %686, %687 : i32, !llvm.ptr
      %688 = vector.extractelement %685[%69 : i32] : vector<4xi32>
      %ptr_753 = cute.add_offset(%ptr_752, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %689 = builtin.unrealized_conversion_cast %ptr_753 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %688, %689 : i32, !llvm.ptr
      %690 = vector.extractelement %685[%68 : i32] : vector<4xi32>
      %ptr_754 = cute.add_offset(%ptr_752, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %691 = builtin.unrealized_conversion_cast %ptr_754 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %690, %691 : i32, !llvm.ptr
      %692 = vector.extractelement %685[%67 : i32] : vector<4xi32>
      %ptr_755 = cute.add_offset(%ptr_752, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %693 = builtin.unrealized_conversion_cast %ptr_755 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %692, %693 : i32, !llvm.ptr
      %694 = arith.addi %683, %c1_i32 : i32
      cf.br ^bb162(%694 : i32)
    ^bb164:  // pred: ^bb162
      cf.br ^bb165(%c0_i32 : i32)
    ^bb165(%695: i32):  // 2 preds: ^bb164, ^bb172
      %696 = arith.cmpi slt, %695, %385 : i32
      cf.cond_br %696, ^bb166, ^bb173 {llvm.loop_annotation = #loop_annotation}
    ^bb166:  // pred: ^bb165
      cf.br ^bb167(%c0_i32 : i32)
    ^bb167(%697: i32):  // 2 preds: ^bb166, ^bb171
      %698 = arith.cmpi slt, %697, %385 : i32
      cf.cond_br %698, ^bb168, ^bb172 {llvm.loop_annotation = #loop_annotation}
    ^bb168:  // pred: ^bb167
      cf.br ^bb169(%c0_i32 : i32)
    ^bb169(%699: i32):  // 2 preds: ^bb168, ^bb170
      %700 = arith.cmpi slt, %699, %394 : i32
      cf.cond_br %700, ^bb170, ^bb171 {llvm.loop_annotation = #loop_annotation}
    ^bb170:  // pred: ^bb169
      %coord_756 = cute.make_coord(%699, %695) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_757 = cute.make_coord(%697, %699) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_758 = cute.crd2idx(%coord_756, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_759 = cute.add_offset(%ptr_524, %idx_758) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_760 = cute.crd2idx(%coord_757, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_761 = cute.add_offset(%iter_713, %idx_760) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %701 = llvm.load %419 : !llvm.ptr -> i32
      %702 = llvm.load %420 : !llvm.ptr -> i32
      %703 = llvm.load %421 : !llvm.ptr -> i32
      %704 = llvm.load %422 : !llvm.ptr -> i32
      %705 = builtin.unrealized_conversion_cast %ptr_759 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %706 = llvm.load %705 : !llvm.ptr -> i32
      %707 = llvm.getelementptr %705[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %708 = llvm.load %707 : !llvm.ptr -> i32
      %709 = builtin.unrealized_conversion_cast %ptr_761 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %710 = llvm.load %709 : !llvm.ptr -> f32
      %711 = llvm.getelementptr %709[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %712 = llvm.load %711 : !llvm.ptr -> f32
      %713 = llvm.getelementptr %709[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %714 = llvm.load %713 : !llvm.ptr -> f32
      %715 = llvm.getelementptr %709[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %716 = llvm.load %715 : !llvm.ptr -> f32
      %717:4 = cute_nvgpu.arch.mma.SM80 A[%701, %702, %703, %704]  B[%706, %708]  C[%710, %712, %714, %716] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %717#0, %709 : f32, !llvm.ptr
      llvm.store %717#1, %711 : f32, !llvm.ptr
      llvm.store %717#2, %713 : f32, !llvm.ptr
      llvm.store %717#3, %715 : f32, !llvm.ptr
      %718 = arith.addi %699, %c1_i32 : i32
      cf.br ^bb169(%718 : i32)
    ^bb171:  // pred: ^bb169
      %719 = arith.addi %697, %c1_i32 : i32
      cf.br ^bb167(%719 : i32)
    ^bb172:  // pred: ^bb167
      %720 = arith.addi %695, %c1_i32 : i32
      cf.br ^bb165(%720 : i32)
    ^bb173:  // pred: ^bb165
      cf.br ^bb174(%c0_i32 : i32)
    ^bb174(%721: i32):  // 2 preds: ^bb173, ^bb175
      %722 = arith.cmpi slt, %721, %385 : i32
      cf.cond_br %722, ^bb175, ^bb176 {llvm.loop_annotation = #loop_annotation}
    ^bb175:  // pred: ^bb174
      %723 = cute_nvgpu.arch.copy.ldsm %ptr_536{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %724 = vector.extractelement %723[%70 : i32] : vector<4xi32>
      llvm.store %724, %423 : i32, !llvm.ptr
      %725 = vector.extractelement %723[%69 : i32] : vector<4xi32>
      llvm.store %725, %424 : i32, !llvm.ptr
      %726 = vector.extractelement %723[%68 : i32] : vector<4xi32>
      llvm.store %726, %425 : i32, !llvm.ptr
      %727 = vector.extractelement %723[%67 : i32] : vector<4xi32>
      llvm.store %727, %426 : i32, !llvm.ptr
      %728 = arith.addi %721, %c1_i32 : i32
      cf.br ^bb174(%728 : i32)
    ^bb176:  // pred: ^bb174
      cf.br ^bb177(%c0_i32 : i32)
    ^bb177(%729: i32):  // 2 preds: ^bb176, ^bb178
      %730 = arith.cmpi slt, %729, %384 : i32
      cf.cond_br %730, ^bb178, ^bb179 {llvm.loop_annotation = #loop_annotation}
    ^bb178:  // pred: ^bb177
      %coord_762 = cute.make_coord(%729) : (i32) -> !cute.coord<"(_,?)">
      %idx_763 = cute.crd2idx(%coord_762, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_764 = cute.add_offset(%ptr_545, %idx_763) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_765 = cute.crd2idx(%coord_762, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_766 = cute.add_offset(%ptr_546, %idx_765) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %731 = cute_nvgpu.arch.copy.ldsm %ptr_764{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %732 = vector.extractelement %731[%70 : i32] : vector<4xi32>
      %733 = builtin.unrealized_conversion_cast %ptr_766 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %732, %733 : i32, !llvm.ptr
      %734 = vector.extractelement %731[%69 : i32] : vector<4xi32>
      %ptr_767 = cute.add_offset(%ptr_766, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %735 = builtin.unrealized_conversion_cast %ptr_767 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %734, %735 : i32, !llvm.ptr
      %736 = vector.extractelement %731[%68 : i32] : vector<4xi32>
      %ptr_768 = cute.add_offset(%ptr_766, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %737 = builtin.unrealized_conversion_cast %ptr_768 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %736, %737 : i32, !llvm.ptr
      %738 = vector.extractelement %731[%67 : i32] : vector<4xi32>
      %ptr_769 = cute.add_offset(%ptr_766, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %739 = builtin.unrealized_conversion_cast %ptr_769 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %738, %739 : i32, !llvm.ptr
      %740 = arith.addi %729, %c1_i32 : i32
      cf.br ^bb177(%740 : i32)
    ^bb179:  // pred: ^bb177
      cf.br ^bb180(%c0_i32 : i32)
    ^bb180(%741: i32):  // 2 preds: ^bb179, ^bb187
      %742 = arith.cmpi slt, %741, %385 : i32
      cf.cond_br %742, ^bb181, ^bb188 {llvm.loop_annotation = #loop_annotation}
    ^bb181:  // pred: ^bb180
      cf.br ^bb182(%c0_i32 : i32)
    ^bb182(%743: i32):  // 2 preds: ^bb181, ^bb186
      %744 = arith.cmpi slt, %743, %385 : i32
      cf.cond_br %744, ^bb183, ^bb187 {llvm.loop_annotation = #loop_annotation}
    ^bb183:  // pred: ^bb182
      cf.br ^bb184(%c0_i32 : i32)
    ^bb184(%745: i32):  // 2 preds: ^bb183, ^bb185
      %746 = arith.cmpi slt, %745, %394 : i32
      cf.cond_br %746, ^bb185, ^bb186 {llvm.loop_annotation = #loop_annotation}
    ^bb185:  // pred: ^bb184
      %coord_770 = cute.make_coord(%745, %741) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_771 = cute.make_coord(%743, %745) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_772 = cute.crd2idx(%coord_770, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_773 = cute.add_offset(%ptr_534, %idx_772) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_774 = cute.crd2idx(%coord_771, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_775 = cute.add_offset(%iter_713, %idx_774) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %747 = llvm.load %427 : !llvm.ptr -> i32
      %748 = llvm.load %428 : !llvm.ptr -> i32
      %749 = llvm.load %429 : !llvm.ptr -> i32
      %750 = llvm.load %430 : !llvm.ptr -> i32
      %751 = builtin.unrealized_conversion_cast %ptr_773 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %752 = llvm.load %751 : !llvm.ptr -> i32
      %753 = llvm.getelementptr %751[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %754 = llvm.load %753 : !llvm.ptr -> i32
      %755 = builtin.unrealized_conversion_cast %ptr_775 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %756 = llvm.load %755 : !llvm.ptr -> f32
      %757 = llvm.getelementptr %755[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %758 = llvm.load %757 : !llvm.ptr -> f32
      %759 = llvm.getelementptr %755[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %760 = llvm.load %759 : !llvm.ptr -> f32
      %761 = llvm.getelementptr %755[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %762 = llvm.load %761 : !llvm.ptr -> f32
      %763:4 = cute_nvgpu.arch.mma.SM80 A[%747, %748, %749, %750]  B[%752, %754]  C[%756, %758, %760, %762] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %763#0, %755 : f32, !llvm.ptr
      llvm.store %763#1, %757 : f32, !llvm.ptr
      llvm.store %763#2, %759 : f32, !llvm.ptr
      llvm.store %763#3, %761 : f32, !llvm.ptr
      %764 = arith.addi %745, %c1_i32 : i32
      cf.br ^bb184(%764 : i32)
    ^bb186:  // pred: ^bb184
      %765 = arith.addi %743, %c1_i32 : i32
      cf.br ^bb182(%765 : i32)
    ^bb187:  // pred: ^bb182
      %766 = arith.addi %741, %c1_i32 : i32
      cf.br ^bb180(%766 : i32)
    ^bb188:  // pred: ^bb180
      cf.br ^bb189(%c0_i32 : i32)
    ^bb189(%767: i32):  // 2 preds: ^bb188, ^bb190
      %768 = arith.cmpi slt, %767, %385 : i32
      cf.cond_br %768, ^bb190, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb190:  // pred: ^bb189
      %769 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %770 = vector.extractelement %769[%70 : i32] : vector<4xi32>
      llvm.store %770, %431 : i32, !llvm.ptr
      %771 = vector.extractelement %769[%69 : i32] : vector<4xi32>
      llvm.store %771, %432 : i32, !llvm.ptr
      %772 = vector.extractelement %769[%68 : i32] : vector<4xi32>
      llvm.store %772, %433 : i32, !llvm.ptr
      %773 = vector.extractelement %769[%67 : i32] : vector<4xi32>
      llvm.store %773, %434 : i32, !llvm.ptr
      %774 = arith.addi %767, %c1_i32 : i32
      cf.br ^bb189(%774 : i32)
    ^bb191:  // pred: ^bb189
      cf.br ^bb192(%c0_i32 : i32)
    ^bb192(%775: i32):  // 2 preds: ^bb191, ^bb193
      %776 = arith.cmpi slt, %775, %384 : i32
      cf.cond_br %776, ^bb193, ^bb194 {llvm.loop_annotation = #loop_annotation}
    ^bb193:  // pred: ^bb192
      %coord_776 = cute.make_coord(%775) : (i32) -> !cute.coord<"(_,?)">
      %idx_777 = cute.crd2idx(%coord_776, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_778 = cute.add_offset(%ptr_557, %idx_777) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_779 = cute.crd2idx(%coord_776, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_780 = cute.add_offset(%ptr_558, %idx_779) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %777 = cute_nvgpu.arch.copy.ldsm %ptr_778{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %778 = vector.extractelement %777[%70 : i32] : vector<4xi32>
      %779 = builtin.unrealized_conversion_cast %ptr_780 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %778, %779 : i32, !llvm.ptr
      %780 = vector.extractelement %777[%69 : i32] : vector<4xi32>
      %ptr_781 = cute.add_offset(%ptr_780, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %781 = builtin.unrealized_conversion_cast %ptr_781 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %780, %781 : i32, !llvm.ptr
      %782 = vector.extractelement %777[%68 : i32] : vector<4xi32>
      %ptr_782 = cute.add_offset(%ptr_780, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %783 = builtin.unrealized_conversion_cast %ptr_782 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %782, %783 : i32, !llvm.ptr
      %784 = vector.extractelement %777[%67 : i32] : vector<4xi32>
      %ptr_783 = cute.add_offset(%ptr_780, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %785 = builtin.unrealized_conversion_cast %ptr_783 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %784, %785 : i32, !llvm.ptr
      %786 = arith.addi %775, %c1_i32 : i32
      cf.br ^bb192(%786 : i32)
    ^bb194:  // pred: ^bb192
      cf.br ^bb195(%c0_i32 : i32)
    ^bb195(%787: i32):  // 2 preds: ^bb194, ^bb202
      %788 = arith.cmpi slt, %787, %385 : i32
      cf.cond_br %788, ^bb196, ^bb203 {llvm.loop_annotation = #loop_annotation}
    ^bb196:  // pred: ^bb195
      cf.br ^bb197(%c0_i32 : i32)
    ^bb197(%789: i32):  // 2 preds: ^bb196, ^bb201
      %790 = arith.cmpi slt, %789, %385 : i32
      cf.cond_br %790, ^bb198, ^bb202 {llvm.loop_annotation = #loop_annotation}
    ^bb198:  // pred: ^bb197
      cf.br ^bb199(%c0_i32 : i32)
    ^bb199(%791: i32):  // 2 preds: ^bb198, ^bb200
      %792 = arith.cmpi slt, %791, %394 : i32
      cf.cond_br %792, ^bb200, ^bb201 {llvm.loop_annotation = #loop_annotation}
    ^bb200:  // pred: ^bb199
      %coord_784 = cute.make_coord(%791, %787) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_785 = cute.make_coord(%789, %791) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_786 = cute.crd2idx(%coord_784, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_787 = cute.add_offset(%ptr_546, %idx_786) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_788 = cute.crd2idx(%coord_785, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_789 = cute.add_offset(%iter_713, %idx_788) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %793 = llvm.load %435 : !llvm.ptr -> i32
      %794 = llvm.load %436 : !llvm.ptr -> i32
      %795 = llvm.load %437 : !llvm.ptr -> i32
      %796 = llvm.load %438 : !llvm.ptr -> i32
      %797 = builtin.unrealized_conversion_cast %ptr_787 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %798 = llvm.load %797 : !llvm.ptr -> i32
      %799 = llvm.getelementptr %797[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %800 = llvm.load %799 : !llvm.ptr -> i32
      %801 = builtin.unrealized_conversion_cast %ptr_789 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %802 = llvm.load %801 : !llvm.ptr -> f32
      %803 = llvm.getelementptr %801[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %804 = llvm.load %803 : !llvm.ptr -> f32
      %805 = llvm.getelementptr %801[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %806 = llvm.load %805 : !llvm.ptr -> f32
      %807 = llvm.getelementptr %801[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %808 = llvm.load %807 : !llvm.ptr -> f32
      %809:4 = cute_nvgpu.arch.mma.SM80 A[%793, %794, %795, %796]  B[%798, %800]  C[%802, %804, %806, %808] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %809#0, %801 : f32, !llvm.ptr
      llvm.store %809#1, %803 : f32, !llvm.ptr
      llvm.store %809#2, %805 : f32, !llvm.ptr
      llvm.store %809#3, %807 : f32, !llvm.ptr
      %810 = arith.addi %791, %c1_i32 : i32
      cf.br ^bb199(%810 : i32)
    ^bb201:  // pred: ^bb199
      %811 = arith.addi %789, %c1_i32 : i32
      cf.br ^bb197(%811 : i32)
    ^bb202:  // pred: ^bb197
      %812 = arith.addi %787, %c1_i32 : i32
      cf.br ^bb195(%812 : i32)
    ^bb203:  // pred: ^bb195
      cf.br ^bb204(%c0_i32 : i32)
    ^bb204(%813: i32):  // 2 preds: ^bb203, ^bb205
      %814 = arith.cmpi slt, %813, %385 : i32
      cf.cond_br %814, ^bb205, ^bb206 {llvm.loop_annotation = #loop_annotation}
    ^bb205:  // pred: ^bb204
      %815 = cute_nvgpu.arch.copy.ldsm %ptr_560{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %816 = vector.extractelement %815[%70 : i32] : vector<4xi32>
      llvm.store %816, %439 : i32, !llvm.ptr
      %817 = vector.extractelement %815[%69 : i32] : vector<4xi32>
      llvm.store %817, %440 : i32, !llvm.ptr
      %818 = vector.extractelement %815[%68 : i32] : vector<4xi32>
      llvm.store %818, %441 : i32, !llvm.ptr
      %819 = vector.extractelement %815[%67 : i32] : vector<4xi32>
      llvm.store %819, %442 : i32, !llvm.ptr
      %820 = arith.addi %813, %c1_i32 : i32
      cf.br ^bb204(%820 : i32)
    ^bb206:  // pred: ^bb204
      cf.br ^bb207(%c0_i32 : i32)
    ^bb207(%821: i32):  // 2 preds: ^bb206, ^bb208
      %822 = arith.cmpi slt, %821, %384 : i32
      cf.cond_br %822, ^bb208, ^bb209 {llvm.loop_annotation = #loop_annotation}
    ^bb208:  // pred: ^bb207
      %coord_790 = cute.make_coord(%821) : (i32) -> !cute.coord<"(_,?)">
      %idx_791 = cute.crd2idx(%coord_790, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_792 = cute.add_offset(%ptr_569, %idx_791) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_793 = cute.crd2idx(%coord_790, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_794 = cute.add_offset(%ptr_570, %idx_793) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %823 = cute_nvgpu.arch.copy.ldsm %ptr_792{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %824 = vector.extractelement %823[%70 : i32] : vector<4xi32>
      %825 = builtin.unrealized_conversion_cast %ptr_794 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %824, %825 : i32, !llvm.ptr
      %826 = vector.extractelement %823[%69 : i32] : vector<4xi32>
      %ptr_795 = cute.add_offset(%ptr_794, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %827 = builtin.unrealized_conversion_cast %ptr_795 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %826, %827 : i32, !llvm.ptr
      %828 = vector.extractelement %823[%68 : i32] : vector<4xi32>
      %ptr_796 = cute.add_offset(%ptr_794, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %829 = builtin.unrealized_conversion_cast %ptr_796 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %828, %829 : i32, !llvm.ptr
      %830 = vector.extractelement %823[%67 : i32] : vector<4xi32>
      %ptr_797 = cute.add_offset(%ptr_794, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %831 = builtin.unrealized_conversion_cast %ptr_797 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %830, %831 : i32, !llvm.ptr
      %832 = arith.addi %821, %c1_i32 : i32
      cf.br ^bb207(%832 : i32)
    ^bb209:  // pred: ^bb207
      cf.br ^bb210(%c0_i32 : i32)
    ^bb210(%833: i32):  // 2 preds: ^bb209, ^bb217
      %834 = arith.cmpi slt, %833, %385 : i32
      cf.cond_br %834, ^bb211, ^bb218 {llvm.loop_annotation = #loop_annotation}
    ^bb211:  // pred: ^bb210
      cf.br ^bb212(%c0_i32 : i32)
    ^bb212(%835: i32):  // 2 preds: ^bb211, ^bb216
      %836 = arith.cmpi slt, %835, %385 : i32
      cf.cond_br %836, ^bb213, ^bb217 {llvm.loop_annotation = #loop_annotation}
    ^bb213:  // pred: ^bb212
      cf.br ^bb214(%c0_i32 : i32)
    ^bb214(%837: i32):  // 2 preds: ^bb213, ^bb215
      %838 = arith.cmpi slt, %837, %394 : i32
      cf.cond_br %838, ^bb215, ^bb216 {llvm.loop_annotation = #loop_annotation}
    ^bb215:  // pred: ^bb214
      %coord_798 = cute.make_coord(%837, %833) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_799 = cute.make_coord(%835, %837) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_800 = cute.crd2idx(%coord_798, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_801 = cute.add_offset(%ptr_558, %idx_800) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_802 = cute.crd2idx(%coord_799, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_803 = cute.add_offset(%iter_713, %idx_802) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %839 = llvm.load %443 : !llvm.ptr -> i32
      %840 = llvm.load %444 : !llvm.ptr -> i32
      %841 = llvm.load %445 : !llvm.ptr -> i32
      %842 = llvm.load %446 : !llvm.ptr -> i32
      %843 = builtin.unrealized_conversion_cast %ptr_801 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %844 = llvm.load %843 : !llvm.ptr -> i32
      %845 = llvm.getelementptr %843[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %846 = llvm.load %845 : !llvm.ptr -> i32
      %847 = builtin.unrealized_conversion_cast %ptr_803 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %848 = llvm.load %847 : !llvm.ptr -> f32
      %849 = llvm.getelementptr %847[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %850 = llvm.load %849 : !llvm.ptr -> f32
      %851 = llvm.getelementptr %847[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %852 = llvm.load %851 : !llvm.ptr -> f32
      %853 = llvm.getelementptr %847[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %854 = llvm.load %853 : !llvm.ptr -> f32
      %855:4 = cute_nvgpu.arch.mma.SM80 A[%839, %840, %841, %842]  B[%844, %846]  C[%848, %850, %852, %854] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %855#0, %847 : f32, !llvm.ptr
      llvm.store %855#1, %849 : f32, !llvm.ptr
      llvm.store %855#2, %851 : f32, !llvm.ptr
      llvm.store %855#3, %853 : f32, !llvm.ptr
      %856 = arith.addi %837, %c1_i32 : i32
      cf.br ^bb214(%856 : i32)
    ^bb216:  // pred: ^bb214
      %857 = arith.addi %835, %c1_i32 : i32
      cf.br ^bb212(%857 : i32)
    ^bb217:  // pred: ^bb212
      %858 = arith.addi %833, %c1_i32 : i32
      cf.br ^bb210(%858 : i32)
    ^bb218:  // pred: ^bb210
      cf.br ^bb219(%c0_i32 : i32)
    ^bb219(%859: i32):  // 2 preds: ^bb218, ^bb226
      %860 = arith.cmpi slt, %859, %385 : i32
      cf.cond_br %860, ^bb220, ^bb227 {llvm.loop_annotation = #loop_annotation}
    ^bb220:  // pred: ^bb219
      cf.br ^bb221(%c0_i32 : i32)
    ^bb221(%861: i32):  // 2 preds: ^bb220, ^bb225
      %862 = arith.cmpi slt, %861, %385 : i32
      cf.cond_br %862, ^bb222, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb222:  // pred: ^bb221
      cf.br ^bb223(%c0_i32 : i32)
    ^bb223(%863: i32):  // 2 preds: ^bb222, ^bb224
      %864 = arith.cmpi slt, %863, %394 : i32
      cf.cond_br %864, ^bb224, ^bb225 {llvm.loop_annotation = #loop_annotation}
    ^bb224:  // pred: ^bb223
      %coord_804 = cute.make_coord(%863, %859) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_805 = cute.make_coord(%861, %863) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_806 = cute.crd2idx(%coord_804, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_807 = cute.add_offset(%ptr_570, %idx_806) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_808 = cute.crd2idx(%coord_805, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_809 = cute.add_offset(%iter_713, %idx_808) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %865 = llvm.load %447 : !llvm.ptr -> i32
      %866 = llvm.load %448 : !llvm.ptr -> i32
      %867 = llvm.load %449 : !llvm.ptr -> i32
      %868 = llvm.load %450 : !llvm.ptr -> i32
      %869 = builtin.unrealized_conversion_cast %ptr_807 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %870 = llvm.load %869 : !llvm.ptr -> i32
      %871 = llvm.getelementptr %869[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %872 = llvm.load %871 : !llvm.ptr -> i32
      %873 = builtin.unrealized_conversion_cast %ptr_809 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %874 = llvm.load %873 : !llvm.ptr -> f32
      %875 = llvm.getelementptr %873[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %876 = llvm.load %875 : !llvm.ptr -> f32
      %877 = llvm.getelementptr %873[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %878 = llvm.load %877 : !llvm.ptr -> f32
      %879 = llvm.getelementptr %873[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %880 = llvm.load %879 : !llvm.ptr -> f32
      %881:4 = cute_nvgpu.arch.mma.SM80 A[%865, %866, %867, %868]  B[%870, %872]  C[%874, %876, %878, %880] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %881#0, %873 : f32, !llvm.ptr
      llvm.store %881#1, %875 : f32, !llvm.ptr
      llvm.store %881#2, %877 : f32, !llvm.ptr
      llvm.store %881#3, %879 : f32, !llvm.ptr
      %882 = arith.addi %863, %c1_i32 : i32
      cf.br ^bb223(%882 : i32)
    ^bb225:  // pred: ^bb223
      %883 = arith.addi %861, %c1_i32 : i32
      cf.br ^bb221(%883 : i32)
    ^bb226:  // pred: ^bb221
      %884 = arith.addi %859, %c1_i32 : i32
      cf.br ^bb219(%884 : i32)
    ^bb227:  // pred: ^bb219
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %885 = arith.cmpi sgt, %457, %c0_i32 : i32
      cf.cond_br %885, ^bb228, ^bb256
    ^bb228:  // pred: ^bb227
      %sub_810 = cute.tuple_sub(%sub_593, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_811 = cute.make_coord(%sub_810) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
      %886:3 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_812 = cute.assume(%886#1) : (i64) -> !cute.i64<divby 128>
      %stride_813 = cute.make_stride(%iv_812) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_814 = cute.make_layout(%111, %stride_813) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_815 = cute.crd2idx(%coord_811, %lay_115) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_816 = cute.add_offset(%ptr_110, %idx_815) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_817 = cute.get_iter(%rmem_222) : !memref_rmem_i8_
      %append_818 = cute.append_to_rank<2> (%lay_814, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %887 = cute.get_scalars(%append_818) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_819 = cute.assume(%887) : (i64) -> !cute.i64<divby 128>
      %stride_820 = cute.make_stride(%iv_819) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_821 = cute.make_layout(%80, %stride_820) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_822 = cute.append_to_rank<2> (%lay_821, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %888 = cute.get_scalars(%append_822) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_823 = cute.assume(%888) : (i64) -> !cute.i64<divby 128>
      %stride_824 = cute.make_stride(%iv_823) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_825 = cute.make_layout(%79, %stride_824) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb229(%c0_i32 : i32)
    ^bb229(%889: i32):  // 2 preds: ^bb228, ^bb230
      %890 = arith.cmpi slt, %889, %394 : i32
      cf.cond_br %890, ^bb230, ^bb231 {llvm.loop_annotation = #loop_annotation}
    ^bb230:  // pred: ^bb229
      %coord_826 = cute.make_coord(%889) : (i32) -> !cute.coord<"(_,?)">
      %idx_827 = cute.crd2idx(%coord_826, %lay_825) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_828 = cute.add_offset(%ptr_816, %idx_827) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_829 = cute.crd2idx(%coord_826, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_830 = cute.add_offset(%ptr_116, %idx_829) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_831 = cute.crd2idx(%coord_826, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_832 = cute.add_offset(%iter_817, %idx_831) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %891 = builtin.unrealized_conversion_cast %ptr_832 : !cute.ptr<i8, rmem> to !llvm.ptr
      %892 = llvm.load %891 : !llvm.ptr -> i8
      %893 = llvm.trunc %892 : i8 to i1
      %iter_833 = cute.recast_iter(%ptr_828) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_834 = cute.recast_iter(%ptr_830) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_834 : !cute.ptr<i128, smem>, %iter_833 : !cute.ptr<i128, gmem>, %893 : i1) {cache_mode = <always>}
      %894 = arith.addi %889, %c1_i32 : i32
      cf.br ^bb229(%894 : i32)
    ^bb231:  // pred: ^bb229
      cf.cond_br %333, ^bb232, ^bb236
    ^bb232:  // pred: ^bb231
      %coord_835 = cute.make_coord(%sub_810) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_836 = cute.crd2idx(%coord_835, %lay_132) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_837 = cute.add_offset(%ptr_128, %idx_836) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_838 = cute.recast_iter(%ptr_837) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_839 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb233(%c0_i32 : i32)
    ^bb233(%895: i32):  // 2 preds: ^bb232, ^bb234
      %896 = arith.cmpi slt, %895, %385 : i32
      cf.cond_br %896, ^bb234, ^bb235 {llvm.loop_annotation = #loop_annotation}
    ^bb234:  // pred: ^bb233
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_839 : !cute.ptr<i128, smem>, %iter_838 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %897 = arith.addi %895, %c1_i32 : i32
      cf.br ^bb233(%897 : i32)
    ^bb235:  // pred: ^bb233
      cf.br ^bb237
    ^bb236:  // pred: ^bb231
      %view_840 = cute.make_view(%ptr_133) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_840 : !memref_smem_bf16_2
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      cf.cond_br %346, ^bb238, ^bb242
    ^bb238:  // pred: ^bb237
      %coord_841 = cute.make_coord(%sub_810) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_842 = cute.crd2idx(%coord_841, %lay_132) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_843 = cute.add_offset(%ptr_128, %idx_842) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_844 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_845 = cute.recast_iter(%ptr_843) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_846 = cute.recast_iter(%ptr_844) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb239(%c0_i32 : i32)
    ^bb239(%898: i32):  // 2 preds: ^bb238, ^bb240
      %899 = arith.cmpi slt, %898, %385 : i32
      cf.cond_br %899, ^bb240, ^bb241 {llvm.loop_annotation = #loop_annotation}
    ^bb240:  // pred: ^bb239
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_846 : !cute.ptr<i128, smem>, %iter_845 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %900 = arith.addi %898, %c1_i32 : i32
      cf.br ^bb239(%900 : i32)
    ^bb241:  // pred: ^bb239
      cf.br ^bb243
    ^bb242:  // pred: ^bb237
      %ptr_847 = cute.add_offset(%ptr_133, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_848 = cute.make_view(%ptr_847) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_848 : !memref_smem_bf16_2
      cf.br ^bb243
    ^bb243:  // 2 preds: ^bb241, ^bb242
      cf.cond_br %358, ^bb244, ^bb248
    ^bb244:  // pred: ^bb243
      %coord_849 = cute.make_coord(%sub_810) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_850 = cute.crd2idx(%coord_849, %lay_132) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_851 = cute.add_offset(%ptr_128, %idx_850) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_852 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_853 = cute.recast_iter(%ptr_851) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_854 = cute.recast_iter(%ptr_852) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb245(%c0_i32 : i32)
    ^bb245(%901: i32):  // 2 preds: ^bb244, ^bb246
      %902 = arith.cmpi slt, %901, %385 : i32
      cf.cond_br %902, ^bb246, ^bb247 {llvm.loop_annotation = #loop_annotation}
    ^bb246:  // pred: ^bb245
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_854 : !cute.ptr<i128, smem>, %iter_853 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %903 = arith.addi %901, %c1_i32 : i32
      cf.br ^bb245(%903 : i32)
    ^bb247:  // pred: ^bb245
      cf.br ^bb249
    ^bb248:  // pred: ^bb243
      %ptr_855 = cute.add_offset(%ptr_133, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_856 = cute.make_view(%ptr_855) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_856 : !memref_smem_bf16_2
      cf.br ^bb249
    ^bb249:  // 2 preds: ^bb247, ^bb248
      cf.cond_br %370, ^bb250, ^bb254
    ^bb250:  // pred: ^bb249
      %coord_857 = cute.make_coord(%sub_810) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_858 = cute.crd2idx(%coord_857, %lay_132) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_859 = cute.add_offset(%ptr_128, %idx_858) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_860 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_861 = cute.recast_iter(%ptr_859) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_862 = cute.recast_iter(%ptr_860) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb251(%c0_i32 : i32)
    ^bb251(%904: i32):  // 2 preds: ^bb250, ^bb252
      %905 = arith.cmpi slt, %904, %385 : i32
      cf.cond_br %905, ^bb252, ^bb253 {llvm.loop_annotation = #loop_annotation}
    ^bb252:  // pred: ^bb251
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_862 : !cute.ptr<i128, smem>, %iter_861 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %906 = arith.addi %904, %c1_i32 : i32
      cf.br ^bb251(%906 : i32)
    ^bb253:  // pred: ^bb251
      cf.br ^bb255
    ^bb254:  // pred: ^bb249
      %ptr_863 = cute.add_offset(%ptr_133, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_864 = cute.make_view(%ptr_863) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_864 : !memref_smem_bf16_2
      cf.br ^bb255
    ^bb255:  // 2 preds: ^bb253, ^bb254
      nvvm.cp.async.commit.group
      cf.br ^bb256
    ^bb256:  // 2 preds: ^bb227, ^bb255
      %907 = cute.memref.load_vec %rmem_686 : !memref_rmem_f32_1
      %908 = arith.mulf %907, %cst : vector<32xf32>
      cute.memref.store_vec %908, %rmem_686 : !memref_rmem_f32_1
      %909 = cute.memref.load(%rmem_686, %97) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
      %910 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %909 : (f32) -> f32
      cute.memref.store(%rmem_686, %97, %910) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
      %911 = cute.memref.load(%rmem_686, %95) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
      %912 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %911 : (f32) -> f32
      cute.memref.store(%rmem_686, %95, %912) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
      %913 = cute.memref.load(%rmem_686, %42) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
      %914 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %913 : (f32) -> f32
      cute.memref.store(%rmem_686, %42, %914) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
      %915 = cute.memref.load(%rmem_686, %41) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
      %916 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %915 : (f32) -> f32
      cute.memref.store(%rmem_686, %41, %916) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
      %917 = cute.memref.load(%rmem_686, %40) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
      %918 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %917 : (f32) -> f32
      cute.memref.store(%rmem_686, %40, %918) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
      %919 = cute.memref.load(%rmem_686, %39) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
      %920 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %919 : (f32) -> f32
      cute.memref.store(%rmem_686, %39, %920) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
      %921 = cute.memref.load(%rmem_686, %38) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
      %922 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %921 : (f32) -> f32
      cute.memref.store(%rmem_686, %38, %922) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
      %923 = cute.memref.load(%rmem_686, %37) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
      %924 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %923 : (f32) -> f32
      cute.memref.store(%rmem_686, %37, %924) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
      %925 = cute.memref.load(%rmem_686, %36) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
      %926 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %925 : (f32) -> f32
      cute.memref.store(%rmem_686, %36, %926) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
      %927 = cute.memref.load(%rmem_686, %35) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
      %928 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %927 : (f32) -> f32
      cute.memref.store(%rmem_686, %35, %928) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
      %929 = cute.memref.load(%rmem_686, %34) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
      %930 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %929 : (f32) -> f32
      cute.memref.store(%rmem_686, %34, %930) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
      %931 = cute.memref.load(%rmem_686, %33) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
      %932 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %931 : (f32) -> f32
      cute.memref.store(%rmem_686, %33, %932) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
      %933 = cute.memref.load(%rmem_686, %32) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
      %934 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %933 : (f32) -> f32
      cute.memref.store(%rmem_686, %32, %934) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
      %935 = cute.memref.load(%rmem_686, %31) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
      %936 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %935 : (f32) -> f32
      cute.memref.store(%rmem_686, %31, %936) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
      %937 = cute.memref.load(%rmem_686, %30) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
      %938 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %937 : (f32) -> f32
      cute.memref.store(%rmem_686, %30, %938) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
      %939 = cute.memref.load(%rmem_686, %29) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
      %940 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %939 : (f32) -> f32
      cute.memref.store(%rmem_686, %29, %940) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
      %941 = cute.memref.load(%rmem_686, %28) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
      %942 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %941 : (f32) -> f32
      cute.memref.store(%rmem_686, %28, %942) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
      %943 = cute.memref.load(%rmem_686, %27) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
      %944 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %943 : (f32) -> f32
      cute.memref.store(%rmem_686, %27, %944) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
      %945 = cute.memref.load(%rmem_686, %26) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
      %946 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %945 : (f32) -> f32
      cute.memref.store(%rmem_686, %26, %946) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
      %947 = cute.memref.load(%rmem_686, %25) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
      %948 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %947 : (f32) -> f32
      cute.memref.store(%rmem_686, %25, %948) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
      %949 = cute.memref.load(%rmem_686, %24) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
      %950 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %949 : (f32) -> f32
      cute.memref.store(%rmem_686, %24, %950) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
      %951 = cute.memref.load(%rmem_686, %23) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
      %952 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %951 : (f32) -> f32
      cute.memref.store(%rmem_686, %23, %952) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
      %953 = cute.memref.load(%rmem_686, %22) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
      %954 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %953 : (f32) -> f32
      cute.memref.store(%rmem_686, %22, %954) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
      %955 = cute.memref.load(%rmem_686, %21) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
      %956 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %955 : (f32) -> f32
      cute.memref.store(%rmem_686, %21, %956) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
      %957 = cute.memref.load(%rmem_686, %20) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
      %958 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %957 : (f32) -> f32
      cute.memref.store(%rmem_686, %20, %958) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
      %959 = cute.memref.load(%rmem_686, %19) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
      %960 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %959 : (f32) -> f32
      cute.memref.store(%rmem_686, %19, %960) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
      %961 = cute.memref.load(%rmem_686, %18) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
      %962 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %961 : (f32) -> f32
      cute.memref.store(%rmem_686, %18, %962) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
      %963 = cute.memref.load(%rmem_686, %17) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
      %964 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %963 : (f32) -> f32
      cute.memref.store(%rmem_686, %17, %964) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
      %965 = cute.memref.load(%rmem_686, %16) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
      %966 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %965 : (f32) -> f32
      cute.memref.store(%rmem_686, %16, %966) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
      %967 = cute.memref.load(%rmem_686, %15) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
      %968 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %967 : (f32) -> f32
      cute.memref.store(%rmem_686, %15, %968) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
      %969 = cute.memref.load(%rmem_686, %14) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
      %970 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %969 : (f32) -> f32
      cute.memref.store(%rmem_686, %14, %970) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
      %971 = cute.memref.load(%rmem_686, %13) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
      %972 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %971 : (f32) -> f32
      cute.memref.store(%rmem_686, %13, %972) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
      %973 = cute.memref.load_vec %rmem_686 : !memref_rmem_f32_1
      %974 = arith.mulf %908, %973 : vector<32xf32>
      %975 = arith.addf %974, %908 : vector<32xf32>
      cute.memref.store_vec %975, %rmem_686 : !memref_rmem_f32_1
      %rmem_865 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_866 = cute.get_iter(%rmem_865) : !memref_rmem_bf16_3
      %976 = cute.memref.load_vec %rmem_686 : !memref_rmem_f32_1
      %977 = arith.truncf %976 : vector<32xf32> to vector<32xbf16>
      cute.memref.store_vec %977, %rmem_865 : !memref_rmem_bf16_3
      cf.br ^bb257(%c0_i32 : i32)
    ^bb257(%978: i32):  // 2 preds: ^bb256, ^bb258
      %979 = arith.cmpi slt, %978, %394 : i32
      cf.cond_br %979, ^bb258, ^bb259 {llvm.loop_annotation = #loop_annotation}
    ^bb258:  // pred: ^bb257
      %coord_867 = cute.make_coord(%978) : (i32) -> !cute.coord<"(_,?)">
      %idx_868 = cute.crd2idx(%coord_867, %lay_584) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_869 = cute.add_offset(%ptr_156, %idx_868) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_870 = cute.crd2idx(%coord_867, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_871 = cute.add_offset(%iter_159, %idx_870) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %980 = cute_nvgpu.arch.copy.ldsm %ptr_869{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %981 = vector.extractelement %980[%70 : i32] : vector<4xi32>
      %982 = builtin.unrealized_conversion_cast %ptr_871 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %981, %982 : i32, !llvm.ptr
      %983 = vector.extractelement %980[%69 : i32] : vector<4xi32>
      %ptr_872 = cute.add_offset(%ptr_871, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %984 = builtin.unrealized_conversion_cast %ptr_872 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %983, %984 : i32, !llvm.ptr
      %985 = vector.extractelement %980[%68 : i32] : vector<4xi32>
      %ptr_873 = cute.add_offset(%ptr_871, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %986 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %985, %986 : i32, !llvm.ptr
      %987 = vector.extractelement %980[%67 : i32] : vector<4xi32>
      %ptr_874 = cute.add_offset(%ptr_871, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %988 = builtin.unrealized_conversion_cast %ptr_874 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %987, %988 : i32, !llvm.ptr
      %989 = arith.addi %978, %c1_i32 : i32
      cf.br ^bb257(%989 : i32)
    ^bb259:  // pred: ^bb257
      cf.br ^bb260(%c0_i32 : i32)
    ^bb260(%990: i32):  // 2 preds: ^bb259, ^bb261
      %991 = arith.cmpi slt, %990, %394 : i32
      cf.cond_br %991, ^bb261, ^bb262 {llvm.loop_annotation = #loop_annotation}
    ^bb261:  // pred: ^bb260
      %coord_875 = cute.make_coord(%990) : (i32) -> !cute.coord<"(_,?)">
      %idx_876 = cute.crd2idx(%coord_875, %lay_584) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_877 = cute.add_offset(%ptr_585, %idx_876) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_878 = cute.crd2idx(%coord_875, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_879 = cute.add_offset(%ptr_586, %idx_878) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %992 = cute_nvgpu.arch.copy.ldsm %ptr_877{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %993 = vector.extractelement %992[%70 : i32] : vector<4xi32>
      %994 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %993, %994 : i32, !llvm.ptr
      %995 = vector.extractelement %992[%69 : i32] : vector<4xi32>
      %ptr_880 = cute.add_offset(%ptr_879, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %996 = builtin.unrealized_conversion_cast %ptr_880 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %995, %996 : i32, !llvm.ptr
      %997 = vector.extractelement %992[%68 : i32] : vector<4xi32>
      %ptr_881 = cute.add_offset(%ptr_879, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %998 = builtin.unrealized_conversion_cast %ptr_881 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %997, %998 : i32, !llvm.ptr
      %999 = vector.extractelement %992[%67 : i32] : vector<4xi32>
      %ptr_882 = cute.add_offset(%ptr_879, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1000 = builtin.unrealized_conversion_cast %ptr_882 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %999, %1000 : i32, !llvm.ptr
      %1001 = arith.addi %990, %c1_i32 : i32
      cf.br ^bb260(%1001 : i32)
    ^bb262:  // pred: ^bb260
      %1002 = builtin.unrealized_conversion_cast %iter_866 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1003 = llvm.getelementptr %1002[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1004 = llvm.getelementptr %1002[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1005 = llvm.getelementptr %1002[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb263(%c0_i32 : i32)
    ^bb263(%1006: i32):  // 2 preds: ^bb262, ^bb270
      %1007 = arith.cmpi slt, %1006, %385 : i32
      cf.cond_br %1007, ^bb264, ^bb271 {llvm.loop_annotation = #loop_annotation}
    ^bb264:  // pred: ^bb263
      cf.br ^bb265(%c0_i32 : i32)
    ^bb265(%1008: i32):  // 2 preds: ^bb264, ^bb269
      %1009 = arith.cmpi slt, %1008, %385 : i32
      cf.cond_br %1009, ^bb266, ^bb270 {llvm.loop_annotation = #loop_annotation}
    ^bb266:  // pred: ^bb265
      cf.br ^bb267(%c0_i32 : i32)
    ^bb267(%1010: i32):  // 2 preds: ^bb266, ^bb268
      %1011 = arith.cmpi slt, %1010, %454 : i32
      cf.cond_br %1011, ^bb268, ^bb269 {llvm.loop_annotation = #loop_annotation}
    ^bb268:  // pred: ^bb267
      %coord_883 = cute.make_coord(%1010, %1006) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_884 = cute.make_coord(%1008, %1010) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_885 = cute.crd2idx(%coord_883, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_886 = cute.add_offset(%iter_159, %idx_885) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_887 = cute.crd2idx(%coord_884, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_888 = cute.add_offset(%iter_587, %idx_887) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1012 = llvm.load %1002 : !llvm.ptr -> i32
      %1013 = llvm.load %1003 : !llvm.ptr -> i32
      %1014 = llvm.load %1004 : !llvm.ptr -> i32
      %1015 = llvm.load %1005 : !llvm.ptr -> i32
      %1016 = builtin.unrealized_conversion_cast %ptr_886 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1017 = llvm.load %1016 : !llvm.ptr -> i32
      %1018 = llvm.getelementptr %1016[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1019 = llvm.load %1018 : !llvm.ptr -> i32
      %1020 = builtin.unrealized_conversion_cast %ptr_888 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1021 = llvm.load %1020 : !llvm.ptr -> f32
      %1022 = llvm.getelementptr %1020[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1023 = llvm.load %1022 : !llvm.ptr -> f32
      %1024 = llvm.getelementptr %1020[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1025 = llvm.load %1024 : !llvm.ptr -> f32
      %1026 = llvm.getelementptr %1020[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1027 = llvm.load %1026 : !llvm.ptr -> f32
      %1028:4 = cute_nvgpu.arch.mma.SM80 A[%1012, %1013, %1014, %1015]  B[%1017, %1019]  C[%1021, %1023, %1025, %1027] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1028#0, %1020 : f32, !llvm.ptr
      llvm.store %1028#1, %1022 : f32, !llvm.ptr
      llvm.store %1028#2, %1024 : f32, !llvm.ptr
      llvm.store %1028#3, %1026 : f32, !llvm.ptr
      %1029 = arith.addi %1010, %c1_i32 : i32
      cf.br ^bb267(%1029 : i32)
    ^bb269:  // pred: ^bb267
      %1030 = arith.addi %1008, %c1_i32 : i32
      cf.br ^bb265(%1030 : i32)
    ^bb270:  // pred: ^bb265
      %1031 = arith.addi %1006, %c1_i32 : i32
      cf.br ^bb263(%1031 : i32)
    ^bb271:  // pred: ^bb263
      cf.br ^bb272(%c0_i32 : i32)
    ^bb272(%1032: i32):  // 2 preds: ^bb271, ^bb273
      %1033 = arith.cmpi slt, %1032, %394 : i32
      cf.cond_br %1033, ^bb273, ^bb274 {llvm.loop_annotation = #loop_annotation}
    ^bb273:  // pred: ^bb272
      %coord_889 = cute.make_coord(%1032) : (i32) -> !cute.coord<"(_,?)">
      %idx_890 = cute.crd2idx(%coord_889, %lay_584) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_891 = cute.add_offset(%ptr_588, %idx_890) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_892 = cute.crd2idx(%coord_889, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_893 = cute.add_offset(%ptr_589, %idx_892) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1034 = cute_nvgpu.arch.copy.ldsm %ptr_891{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1035 = vector.extractelement %1034[%70 : i32] : vector<4xi32>
      %1036 = builtin.unrealized_conversion_cast %ptr_893 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1035, %1036 : i32, !llvm.ptr
      %1037 = vector.extractelement %1034[%69 : i32] : vector<4xi32>
      %ptr_894 = cute.add_offset(%ptr_893, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1038 = builtin.unrealized_conversion_cast %ptr_894 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1037, %1038 : i32, !llvm.ptr
      %1039 = vector.extractelement %1034[%68 : i32] : vector<4xi32>
      %ptr_895 = cute.add_offset(%ptr_893, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1040 = builtin.unrealized_conversion_cast %ptr_895 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1039, %1040 : i32, !llvm.ptr
      %1041 = vector.extractelement %1034[%67 : i32] : vector<4xi32>
      %ptr_896 = cute.add_offset(%ptr_893, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1042 = builtin.unrealized_conversion_cast %ptr_896 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1041, %1042 : i32, !llvm.ptr
      %1043 = arith.addi %1032, %c1_i32 : i32
      cf.br ^bb272(%1043 : i32)
    ^bb274:  // pred: ^bb272
      %ptr_897 = cute.add_offset(%iter_866, %76) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %1044 = builtin.unrealized_conversion_cast %ptr_897 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1045 = llvm.getelementptr %1044[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1046 = llvm.getelementptr %1044[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1047 = llvm.getelementptr %1044[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb275(%c0_i32 : i32)
    ^bb275(%1048: i32):  // 2 preds: ^bb274, ^bb282
      %1049 = arith.cmpi slt, %1048, %385 : i32
      cf.cond_br %1049, ^bb276, ^bb283 {llvm.loop_annotation = #loop_annotation}
    ^bb276:  // pred: ^bb275
      cf.br ^bb277(%c0_i32 : i32)
    ^bb277(%1050: i32):  // 2 preds: ^bb276, ^bb281
      %1051 = arith.cmpi slt, %1050, %385 : i32
      cf.cond_br %1051, ^bb278, ^bb282 {llvm.loop_annotation = #loop_annotation}
    ^bb278:  // pred: ^bb277
      cf.br ^bb279(%c0_i32 : i32)
    ^bb279(%1052: i32):  // 2 preds: ^bb278, ^bb280
      %1053 = arith.cmpi slt, %1052, %454 : i32
      cf.cond_br %1053, ^bb280, ^bb281 {llvm.loop_annotation = #loop_annotation}
    ^bb280:  // pred: ^bb279
      %coord_898 = cute.make_coord(%1052, %1048) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_899 = cute.make_coord(%1050, %1052) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_900 = cute.crd2idx(%coord_898, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_901 = cute.add_offset(%ptr_586, %idx_900) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_902 = cute.crd2idx(%coord_899, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_903 = cute.add_offset(%iter_587, %idx_902) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1054 = llvm.load %1044 : !llvm.ptr -> i32
      %1055 = llvm.load %1045 : !llvm.ptr -> i32
      %1056 = llvm.load %1046 : !llvm.ptr -> i32
      %1057 = llvm.load %1047 : !llvm.ptr -> i32
      %1058 = builtin.unrealized_conversion_cast %ptr_901 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1059 = llvm.load %1058 : !llvm.ptr -> i32
      %1060 = llvm.getelementptr %1058[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1061 = llvm.load %1060 : !llvm.ptr -> i32
      %1062 = builtin.unrealized_conversion_cast %ptr_903 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1063 = llvm.load %1062 : !llvm.ptr -> f32
      %1064 = llvm.getelementptr %1062[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1065 = llvm.load %1064 : !llvm.ptr -> f32
      %1066 = llvm.getelementptr %1062[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1067 = llvm.load %1066 : !llvm.ptr -> f32
      %1068 = llvm.getelementptr %1062[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1069 = llvm.load %1068 : !llvm.ptr -> f32
      %1070:4 = cute_nvgpu.arch.mma.SM80 A[%1054, %1055, %1056, %1057]  B[%1059, %1061]  C[%1063, %1065, %1067, %1069] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1070#0, %1062 : f32, !llvm.ptr
      llvm.store %1070#1, %1064 : f32, !llvm.ptr
      llvm.store %1070#2, %1066 : f32, !llvm.ptr
      llvm.store %1070#3, %1068 : f32, !llvm.ptr
      %1071 = arith.addi %1052, %c1_i32 : i32
      cf.br ^bb279(%1071 : i32)
    ^bb281:  // pred: ^bb279
      %1072 = arith.addi %1050, %c1_i32 : i32
      cf.br ^bb277(%1072 : i32)
    ^bb282:  // pred: ^bb277
      %1073 = arith.addi %1048, %c1_i32 : i32
      cf.br ^bb275(%1073 : i32)
    ^bb283:  // pred: ^bb275
      cf.br ^bb284(%c0_i32 : i32)
    ^bb284(%1074: i32):  // 2 preds: ^bb283, ^bb285
      %1075 = arith.cmpi slt, %1074, %394 : i32
      cf.cond_br %1075, ^bb285, ^bb286 {llvm.loop_annotation = #loop_annotation}
    ^bb285:  // pred: ^bb284
      %coord_904 = cute.make_coord(%1074) : (i32) -> !cute.coord<"(_,?)">
      %idx_905 = cute.crd2idx(%coord_904, %lay_584) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_906 = cute.add_offset(%ptr_590, %idx_905) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_907 = cute.crd2idx(%coord_904, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_908 = cute.add_offset(%ptr_591, %idx_907) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1076 = cute_nvgpu.arch.copy.ldsm %ptr_906{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1077 = vector.extractelement %1076[%70 : i32] : vector<4xi32>
      %1078 = builtin.unrealized_conversion_cast %ptr_908 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1077, %1078 : i32, !llvm.ptr
      %1079 = vector.extractelement %1076[%69 : i32] : vector<4xi32>
      %ptr_909 = cute.add_offset(%ptr_908, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1080 = builtin.unrealized_conversion_cast %ptr_909 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1079, %1080 : i32, !llvm.ptr
      %1081 = vector.extractelement %1076[%68 : i32] : vector<4xi32>
      %ptr_910 = cute.add_offset(%ptr_908, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1082 = builtin.unrealized_conversion_cast %ptr_910 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1081, %1082 : i32, !llvm.ptr
      %1083 = vector.extractelement %1076[%67 : i32] : vector<4xi32>
      %ptr_911 = cute.add_offset(%ptr_908, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1084 = builtin.unrealized_conversion_cast %ptr_911 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1083, %1084 : i32, !llvm.ptr
      %1085 = arith.addi %1074, %c1_i32 : i32
      cf.br ^bb284(%1085 : i32)
    ^bb286:  // pred: ^bb284
      %ptr_912 = cute.add_offset(%iter_866, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %1086 = builtin.unrealized_conversion_cast %ptr_912 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1087 = llvm.getelementptr %1086[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1088 = llvm.getelementptr %1086[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1089 = llvm.getelementptr %1086[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb287(%c0_i32 : i32)
    ^bb287(%1090: i32):  // 2 preds: ^bb286, ^bb294
      %1091 = arith.cmpi slt, %1090, %385 : i32
      cf.cond_br %1091, ^bb288, ^bb295 {llvm.loop_annotation = #loop_annotation}
    ^bb288:  // pred: ^bb287
      cf.br ^bb289(%c0_i32 : i32)
    ^bb289(%1092: i32):  // 2 preds: ^bb288, ^bb293
      %1093 = arith.cmpi slt, %1092, %385 : i32
      cf.cond_br %1093, ^bb290, ^bb294 {llvm.loop_annotation = #loop_annotation}
    ^bb290:  // pred: ^bb289
      cf.br ^bb291(%c0_i32 : i32)
    ^bb291(%1094: i32):  // 2 preds: ^bb290, ^bb292
      %1095 = arith.cmpi slt, %1094, %454 : i32
      cf.cond_br %1095, ^bb292, ^bb293 {llvm.loop_annotation = #loop_annotation}
    ^bb292:  // pred: ^bb291
      %coord_913 = cute.make_coord(%1094, %1090) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_914 = cute.make_coord(%1092, %1094) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_915 = cute.crd2idx(%coord_913, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_916 = cute.add_offset(%ptr_589, %idx_915) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_917 = cute.crd2idx(%coord_914, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_918 = cute.add_offset(%iter_587, %idx_917) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1096 = llvm.load %1086 : !llvm.ptr -> i32
      %1097 = llvm.load %1087 : !llvm.ptr -> i32
      %1098 = llvm.load %1088 : !llvm.ptr -> i32
      %1099 = llvm.load %1089 : !llvm.ptr -> i32
      %1100 = builtin.unrealized_conversion_cast %ptr_916 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1101 = llvm.load %1100 : !llvm.ptr -> i32
      %1102 = llvm.getelementptr %1100[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1103 = llvm.load %1102 : !llvm.ptr -> i32
      %1104 = builtin.unrealized_conversion_cast %ptr_918 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1105 = llvm.load %1104 : !llvm.ptr -> f32
      %1106 = llvm.getelementptr %1104[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1107 = llvm.load %1106 : !llvm.ptr -> f32
      %1108 = llvm.getelementptr %1104[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1109 = llvm.load %1108 : !llvm.ptr -> f32
      %1110 = llvm.getelementptr %1104[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1111 = llvm.load %1110 : !llvm.ptr -> f32
      %1112:4 = cute_nvgpu.arch.mma.SM80 A[%1096, %1097, %1098, %1099]  B[%1101, %1103]  C[%1105, %1107, %1109, %1111] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1112#0, %1104 : f32, !llvm.ptr
      llvm.store %1112#1, %1106 : f32, !llvm.ptr
      llvm.store %1112#2, %1108 : f32, !llvm.ptr
      llvm.store %1112#3, %1110 : f32, !llvm.ptr
      %1113 = arith.addi %1094, %c1_i32 : i32
      cf.br ^bb291(%1113 : i32)
    ^bb293:  // pred: ^bb291
      %1114 = arith.addi %1092, %c1_i32 : i32
      cf.br ^bb289(%1114 : i32)
    ^bb294:  // pred: ^bb289
      %1115 = arith.addi %1090, %c1_i32 : i32
      cf.br ^bb287(%1115 : i32)
    ^bb295:  // pred: ^bb287
      %ptr_919 = cute.add_offset(%iter_866, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %1116 = builtin.unrealized_conversion_cast %ptr_919 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1117 = llvm.getelementptr %1116[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1118 = llvm.getelementptr %1116[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1119 = llvm.getelementptr %1116[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb296(%c0_i32 : i32)
    ^bb296(%1120: i32):  // 2 preds: ^bb295, ^bb303
      %1121 = arith.cmpi slt, %1120, %385 : i32
      cf.cond_br %1121, ^bb297, ^bb304 {llvm.loop_annotation = #loop_annotation}
    ^bb297:  // pred: ^bb296
      cf.br ^bb298(%c0_i32 : i32)
    ^bb298(%1122: i32):  // 2 preds: ^bb297, ^bb302
      %1123 = arith.cmpi slt, %1122, %385 : i32
      cf.cond_br %1123, ^bb299, ^bb303 {llvm.loop_annotation = #loop_annotation}
    ^bb299:  // pred: ^bb298
      cf.br ^bb300(%c0_i32 : i32)
    ^bb300(%1124: i32):  // 2 preds: ^bb299, ^bb301
      %1125 = arith.cmpi slt, %1124, %454 : i32
      cf.cond_br %1125, ^bb301, ^bb302 {llvm.loop_annotation = #loop_annotation}
    ^bb301:  // pred: ^bb300
      %coord_920 = cute.make_coord(%1124, %1120) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_921 = cute.make_coord(%1122, %1124) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_922 = cute.crd2idx(%coord_920, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_923 = cute.add_offset(%ptr_591, %idx_922) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_924 = cute.crd2idx(%coord_921, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_925 = cute.add_offset(%iter_587, %idx_924) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1126 = llvm.load %1116 : !llvm.ptr -> i32
      %1127 = llvm.load %1117 : !llvm.ptr -> i32
      %1128 = llvm.load %1118 : !llvm.ptr -> i32
      %1129 = llvm.load %1119 : !llvm.ptr -> i32
      %1130 = builtin.unrealized_conversion_cast %ptr_923 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1131 = llvm.load %1130 : !llvm.ptr -> i32
      %1132 = llvm.getelementptr %1130[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1133 = llvm.load %1132 : !llvm.ptr -> i32
      %1134 = builtin.unrealized_conversion_cast %ptr_925 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1135 = llvm.load %1134 : !llvm.ptr -> f32
      %1136 = llvm.getelementptr %1134[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1137 = llvm.load %1136 : !llvm.ptr -> f32
      %1138 = llvm.getelementptr %1134[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1139 = llvm.load %1138 : !llvm.ptr -> f32
      %1140 = llvm.getelementptr %1134[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1141 = llvm.load %1140 : !llvm.ptr -> f32
      %1142:4 = cute_nvgpu.arch.mma.SM80 A[%1126, %1127, %1128, %1129]  B[%1131, %1133]  C[%1135, %1137, %1139, %1141] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1142#0, %1134 : f32, !llvm.ptr
      llvm.store %1142#1, %1136 : f32, !llvm.ptr
      llvm.store %1142#2, %1138 : f32, !llvm.ptr
      llvm.store %1142#3, %1140 : f32, !llvm.ptr
      %1143 = arith.addi %1124, %c1_i32 : i32
      cf.br ^bb300(%1143 : i32)
    ^bb302:  // pred: ^bb300
      %1144 = arith.addi %1122, %c1_i32 : i32
      cf.br ^bb298(%1144 : i32)
    ^bb303:  // pred: ^bb298
      %1145 = arith.addi %1120, %c1_i32 : i32
      cf.br ^bb296(%1145 : i32)
    ^bb304:  // pred: ^bb296
      %1146 = arith.addi %455, %c1_i32 : i32
      cf.br ^bb73(%1146 : i32)
    ^bb305:  // pred: ^bb73
      %rmem_926 = cute.memref.alloca() : !memref_rmem_bf16_4
      %1147 = cute.memref.load_vec %rmem_136 : !memref_rmem_f32_
      %1148 = arith.truncf %1147 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1148, %rmem_926 : !memref_rmem_bf16_4
      %iter_927 = cute.recast_iter(%iter_94) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %atom_928 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %1149 = cute.make_tiled_copy(%atom_928) : !copy_simt
      %iter_929 = cute.get_iter(%rmem_926) : !memref_rmem_bf16_4
      %1150 = arith.divsi %156, %c4_i32 : i32
      %1151 = arith.remsi %156, %c4_i32 : i32
      %1152 = arith.muli %1151, %c2_i32 : i32
      %1153 = arith.divsi %1150, %c8_i32 : i32
      %1154 = arith.remsi %1150, %c8_i32 : i32
      %1155 = arith.muli %1154, %c64_i32 : i32
      %1156 = arith.addi %1152, %1155 : i32
      %1157 = arith.muli %1153, %c1024_i32 : i32
      %1158 = arith.addi %1156, %1157 : i32
      %iv_930 = cute.assume(%1158) : (i32) -> !cute.i32<divby 2>
      %int_tuple_931 = cute.make_int_tuple(%iv_930) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_932 = cute.add_offset(%iter_927, %int_tuple_931) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1159 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      cf.br ^bb306(%c0_i32 : i32)
    ^bb306(%1160: i32):  // 2 preds: ^bb305, ^bb307
      %1161 = arith.cmpi slt, %1160, %1159 : i32
      cf.cond_br %1161, ^bb307, ^bb308 {llvm.loop_annotation = #loop_annotation}
    ^bb307:  // pred: ^bb306
      %coord_933 = cute.make_coord(%1160) : (i32) -> !cute.coord<"(_,?)">
      %idx_934 = cute.crd2idx(%coord_933, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_935 = cute.add_offset(%iter_929, %idx_934) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_936 = cute.crd2idx(%coord_933, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_937 = cute.add_offset(%ptr_932, %idx_936) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled = cute.apply_swizzle(%ptr_937) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1162 = builtin.unrealized_conversion_cast %ptr_935 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1163 = builtin.unrealized_conversion_cast %swizzled : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1164 = llvm.load %1162 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1164, %1163 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_938 = cute.add_offset(%ptr_935, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_939 = cute.add_offset(%ptr_937, %4) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_940 = cute.apply_swizzle(%ptr_939) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1165 = builtin.unrealized_conversion_cast %ptr_938 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %1166 = builtin.unrealized_conversion_cast %swizzled_940 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1167 = llvm.load %1165 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1167, %1166 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_941 = cute.add_offset(%ptr_935, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_942 = cute.add_offset(%ptr_937, %76) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_943 = cute.apply_swizzle(%ptr_942) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1168 = builtin.unrealized_conversion_cast %ptr_941 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1169 = builtin.unrealized_conversion_cast %swizzled_943 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1170 = llvm.load %1168 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1170, %1169 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_944 = cute.add_offset(%ptr_935, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_945 = cute.add_offset(%ptr_937, %3) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_946 = cute.apply_swizzle(%ptr_945) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1171 = builtin.unrealized_conversion_cast %ptr_944 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %1172 = builtin.unrealized_conversion_cast %swizzled_946 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1173 = llvm.load %1171 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1173, %1172 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %1174 = arith.addi %1160, %c1_i32 : i32
      cf.br ^bb306(%1174 : i32)
    ^bb308:  // pred: ^bb306
      %lay_947 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1175:7 = cute.get_scalars(%lay_947) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_948 = cute.assume(%1175#3) : (i32) -> !cute.i32<divby 8>
      %shape_949 = cute.make_shape(%1175#1, %iv_948) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_950 = cute.assume(%1175#5) : (i64) -> !cute.i64<divby 8>
      %stride_951 = cute.make_stride(%iv_950) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_952 = cute.make_layout(%shape_949, %stride_951) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_953 = cute.crd2idx(%coord, %lay_947) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_954 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_955 = cute.add_offset(%iter_954, %idx_953) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1176:3 = cute.get_scalars(%lay_952) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %1177 = arith.ceildivsi %1176#0, %c64_i32 : i32
      %1178 = arith.muli %1176#2, %c64_i64 : i64
      %1179 = arith.ceildivsi %1176#1, %c128_i32 : i32
      %shape_956 = cute.make_shape(%1177, %1179) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_957 = cute.assume(%1176#2) : (i64) -> !cute.i64<divby 8>
      %iv_958 = cute.assume(%1178) : (i64) -> !cute.i64<divby 512>
      %stride_959 = cute.make_stride(%iv_957, %iv_958) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_960 = cute.make_layout(%shape_956, %stride_959) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %1180:4 = cute.get_scalars(%lay_960) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_961 = cute.assume(%1180#2) : (i64) -> !cute.i64<divby 8>
      %stride_962 = cute.make_stride(%iv_961) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_963 = cute.make_layout(%115, %stride_962) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_964 = cute.crd2idx(%coord_20, %lay_960) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_965 = cute.add_offset(%ptr_955, %idx_964) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1181 = arith.addi %160, %167 : i32
      %iv_966 = cute.assume(%1181) : (i32) -> !cute.i32<divby 8>
      %int_tuple_967 = cute.make_int_tuple(%iv_966) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_968 = cute.add_offset(%iter_927, %int_tuple_967) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1182 = cute.get_scalars(%lay_963) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %1183 = arith.muli %1182, %c16_i64 : i64
      %1184 = arith.muli %161, %1182 : i64
      %1185 = arith.addi %163, %1184 : i64
      %iv_969 = cute.assume(%1185) : (i64) -> !cute.i64<divby 8>
      %int_tuple_970 = cute.make_int_tuple(%iv_969) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_971 = cute.add_offset(%ptr_965, %int_tuple_970) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_972 = cute.assume(%1183) : (i64) -> !cute.i64<divby 128>
      %stride_973 = cute.make_stride(%iv_972) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_974 = cute.make_layout(%111, %stride_973) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %rmem_975 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_976 = cute.get_iter(%rmem_975) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %swizzled_977 = cute.apply_swizzle(%ptr_968) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      cf.br ^bb309(%c0_i32 : i32)
    ^bb309(%1186: i32):  // 2 preds: ^bb308, ^bb310
      %1187 = arith.cmpi slt, %1186, %1159 : i32
      cf.cond_br %1187, ^bb310, ^bb311 {llvm.loop_annotation = #loop_annotation}
    ^bb310:  // pred: ^bb309
      %coord_978 = cute.make_coord(%1186) : (i32) -> !cute.coord<"(_,?)">
      %idx_979 = cute.crd2idx(%coord_978, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %idx_980 = cute.crd2idx(%coord_978, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_981 = cute.add_offset(%iter_976, %idx_980) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_982 = cute.add_offset(%swizzled_977, %idx_979) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1188 = builtin.unrealized_conversion_cast %ptr_982 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1189 = builtin.unrealized_conversion_cast %ptr_981 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1190 = llvm.load %1188 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %1190, %1189 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %1191 = arith.addi %1186, %c1_i32 : i32
      cf.br ^bb309(%1191 : i32)
    ^bb311:  // pred: ^bb309
      %1192 = cute.get_shape(%lay_947) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_983, %e1_984, %e2_985, %e3_986 = cute.get_leaves(%1192) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_987 = cute.to_int_tuple(%e0_983) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_988 = cute.to_int_tuple(%e1_984) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_989 = cute.to_int_tuple(%e2_985) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_990 = cute.to_int_tuple(%e3_986) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_991 = cute.make_shape(%itup_987, %itup_988, %itup_989, %itup_990) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_992 = cute.make_layout(%shape_991, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1193:4 = cute.get_scalars(%lay_992) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_993 = cute.assume(%1193#3) : (i32) -> !cute.i32<divby 8>
      %shape_994 = cute.make_shape(%1193#1, %iv_993) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_995 = cute.make_layout(%shape_994, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_996 = cute.crd2idx(%coord, %lay_992) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_997 = cute.add_offset(%105, %idx_996) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %1194:2 = cute.get_scalars(%lay_995) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %1195 = arith.ceildivsi %1194#0, %c64_i32 : i32
      %1196 = arith.ceildivsi %1194#1, %c128_i32 : i32
      %shape_998 = cute.make_shape(%1195, %1196) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_999 = cute.make_layout(%shape_998, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_1000 = cute.crd2idx(%coord_20, %lay_999) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_1001 = cute.add_offset(%tup_997, %idx_1000) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %tup_1002 = cute.add_offset(%tup_1001, %int_tuple_214) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_1003 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_1004, %e1_1005, %e2_1006, %e3_1007 = cute.get_leaves(%tup_1002) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1008 = cute.make_coord(%e3_1007) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1009 = cute.make_coord(%itup_990) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1197 = cute.get_scalars(%coord_1008) : !cute.coord<"?{div=8}">
      %1198 = cute.get_scalars(%coord_1009) : !cute.coord<"?{div=8}">
      %1199 = arith.cmpi slt, %1197, %1198 : i32
      %1200 = arith.extui %1199 : i1 to i8
      cute.memref.store(%rmem_1003, %97, %1200) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_1010 = cute.add_offset(%tup_1002, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1011, %e1_1012, %e2_1013, %e3_1014 = cute.get_leaves(%tup_1010) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1015 = cute.make_coord(%e3_1014) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1201 = cute.get_scalars(%coord_1015) : !cute.coord<"?{div=8}">
      %1202 = arith.cmpi slt, %1201, %1198 : i32
      %1203 = arith.extui %1202 : i1 to i8
      cute.memref.store(%rmem_1003, %95, %1203) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_1016 = cute.make_coord(%e1_1005) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1017 = cute.make_coord(%itup_988) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1204 = cute.get_scalars(%coord_1016) : !cute.coord<"?">
      %1205 = cute.get_scalars(%coord_1017) : !cute.coord<"?">
      %1206 = arith.cmpi slt, %1204, %1205 : i32
      cf.cond_br %1206, ^bb312, ^bb318
    ^bb312:  // pred: ^bb311
      %iter_1018 = cute.get_iter(%rmem_1003) : !memref_rmem_i8_
      %1207 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb313(%c0_i32 : i32)
    ^bb313(%1208: i32):  // 2 preds: ^bb312, ^bb316
      %1209 = arith.cmpi slt, %1208, %1207 : i32
      cf.cond_br %1209, ^bb314, ^bb317 {llvm.loop_annotation = #loop_annotation}
    ^bb314:  // pred: ^bb313
      %coord_1019 = cute.make_coord(%1208) : (i32) -> !cute.coord<"(_,?)">
      %idx_1020 = cute.crd2idx(%coord_1019, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1021 = cute.add_offset(%iter_976, %idx_1020) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1022 = cute.crd2idx(%coord_1019, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1023 = cute.add_offset(%ptr_971, %idx_1022) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1024 = cute.crd2idx(%coord_1019, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1025 = cute.add_offset(%iter_1018, %idx_1024) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1210 = builtin.unrealized_conversion_cast %ptr_1025 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1211 = llvm.load %1210 : !llvm.ptr -> i8
      %1212 = llvm.icmp "ne" %1211, %0 : i8
      cf.cond_br %1212, ^bb315, ^bb316
    ^bb315:  // pred: ^bb314
      %1213 = builtin.unrealized_conversion_cast %ptr_1021 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1214 = builtin.unrealized_conversion_cast %ptr_1023 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1215 = llvm.load %1213 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1215, %1214 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb316
    ^bb316:  // 2 preds: ^bb314, ^bb315
      %1216 = arith.addi %1208, %c1_i32 : i32
      cf.br ^bb313(%1216 : i32)
    ^bb317:  // pred: ^bb313
      cf.br ^bb318
    ^bb318:  // 2 preds: ^bb311, ^bb317
      %tup_1026 = cute.add_offset(%tup_1002, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1027, %e1_1028, %e2_1029, %e3_1030 = cute.get_leaves(%tup_1026) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1031 = cute.make_coord(%e1_1028) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1217 = cute.get_scalars(%coord_1031) : !cute.coord<"?">
      %1218 = arith.cmpi slt, %1217, %1205 : i32
      cf.cond_br %1218, ^bb319, ^bb325
    ^bb319:  // pred: ^bb318
      %ptr_1032 = cute.add_offset(%iter_976, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1033 = cute.crd2idx(%89, %lay_974) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_1034 = cute.add_offset(%ptr_971, %idx_1033) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1035 = cute.get_iter(%rmem_1003) : !memref_rmem_i8_
      %1219 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb320(%c0_i32 : i32)
    ^bb320(%1220: i32):  // 2 preds: ^bb319, ^bb323
      %1221 = arith.cmpi slt, %1220, %1219 : i32
      cf.cond_br %1221, ^bb321, ^bb324 {llvm.loop_annotation = #loop_annotation}
    ^bb321:  // pred: ^bb320
      %coord_1036 = cute.make_coord(%1220) : (i32) -> !cute.coord<"(_,?)">
      %idx_1037 = cute.crd2idx(%coord_1036, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1038 = cute.add_offset(%ptr_1032, %idx_1037) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1039 = cute.crd2idx(%coord_1036, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1040 = cute.add_offset(%ptr_1034, %idx_1039) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1041 = cute.crd2idx(%coord_1036, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1042 = cute.add_offset(%iter_1035, %idx_1041) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1222 = builtin.unrealized_conversion_cast %ptr_1042 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1223 = llvm.load %1222 : !llvm.ptr -> i8
      %1224 = llvm.icmp "ne" %1223, %0 : i8
      cf.cond_br %1224, ^bb322, ^bb323
    ^bb322:  // pred: ^bb321
      %1225 = builtin.unrealized_conversion_cast %ptr_1038 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1226 = builtin.unrealized_conversion_cast %ptr_1040 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1227 = llvm.load %1225 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1227, %1226 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb323
    ^bb323:  // 2 preds: ^bb321, ^bb322
      %1228 = arith.addi %1220, %c1_i32 : i32
      cf.br ^bb320(%1228 : i32)
    ^bb324:  // pred: ^bb320
      cf.br ^bb325
    ^bb325:  // 2 preds: ^bb318, ^bb324
      %tup_1043 = cute.add_offset(%tup_1002, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1044, %e1_1045, %e2_1046, %e3_1047 = cute.get_leaves(%tup_1043) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1048 = cute.make_coord(%e1_1045) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1229 = cute.get_scalars(%coord_1048) : !cute.coord<"?">
      %1230 = arith.cmpi slt, %1229, %1205 : i32
      cf.cond_br %1230, ^bb326, ^bb332
    ^bb326:  // pred: ^bb325
      %ptr_1049 = cute.add_offset(%iter_976, %63) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1050 = cute.crd2idx(%86, %lay_974) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_1051 = cute.add_offset(%ptr_971, %idx_1050) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1052 = cute.get_iter(%rmem_1003) : !memref_rmem_i8_
      %1231 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb327(%c0_i32 : i32)
    ^bb327(%1232: i32):  // 2 preds: ^bb326, ^bb330
      %1233 = arith.cmpi slt, %1232, %1231 : i32
      cf.cond_br %1233, ^bb328, ^bb331 {llvm.loop_annotation = #loop_annotation}
    ^bb328:  // pred: ^bb327
      %coord_1053 = cute.make_coord(%1232) : (i32) -> !cute.coord<"(_,?)">
      %idx_1054 = cute.crd2idx(%coord_1053, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1055 = cute.add_offset(%ptr_1049, %idx_1054) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1056 = cute.crd2idx(%coord_1053, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1057 = cute.add_offset(%ptr_1051, %idx_1056) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1058 = cute.crd2idx(%coord_1053, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1059 = cute.add_offset(%iter_1052, %idx_1058) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1234 = builtin.unrealized_conversion_cast %ptr_1059 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1235 = llvm.load %1234 : !llvm.ptr -> i8
      %1236 = llvm.icmp "ne" %1235, %0 : i8
      cf.cond_br %1236, ^bb329, ^bb330
    ^bb329:  // pred: ^bb328
      %1237 = builtin.unrealized_conversion_cast %ptr_1055 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1238 = builtin.unrealized_conversion_cast %ptr_1057 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1239 = llvm.load %1237 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1239, %1238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb330
    ^bb330:  // 2 preds: ^bb328, ^bb329
      %1240 = arith.addi %1232, %c1_i32 : i32
      cf.br ^bb327(%1240 : i32)
    ^bb331:  // pred: ^bb327
      cf.br ^bb332
    ^bb332:  // 2 preds: ^bb325, ^bb331
      %tup_1060 = cute.add_offset(%tup_1002, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1061, %e1_1062, %e2_1063, %e3_1064 = cute.get_leaves(%tup_1060) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1065 = cute.make_coord(%e1_1062) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1241 = cute.get_scalars(%coord_1065) : !cute.coord<"?">
      %1242 = arith.cmpi slt, %1241, %1205 : i32
      cf.cond_br %1242, ^bb333, ^bb339
    ^bb333:  // pred: ^bb332
      %ptr_1066 = cute.add_offset(%iter_976, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1067 = cute.crd2idx(%83, %lay_974) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_1068 = cute.add_offset(%ptr_971, %idx_1067) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1069 = cute.get_iter(%rmem_1003) : !memref_rmem_i8_
      %1243 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb334(%c0_i32 : i32)
    ^bb334(%1244: i32):  // 2 preds: ^bb333, ^bb337
      %1245 = arith.cmpi slt, %1244, %1243 : i32
      cf.cond_br %1245, ^bb335, ^bb338 {llvm.loop_annotation = #loop_annotation}
    ^bb335:  // pred: ^bb334
      %coord_1070 = cute.make_coord(%1244) : (i32) -> !cute.coord<"(_,?)">
      %idx_1071 = cute.crd2idx(%coord_1070, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1072 = cute.add_offset(%ptr_1066, %idx_1071) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1073 = cute.crd2idx(%coord_1070, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1074 = cute.add_offset(%ptr_1068, %idx_1073) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1075 = cute.crd2idx(%coord_1070, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1076 = cute.add_offset(%iter_1069, %idx_1075) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1246 = builtin.unrealized_conversion_cast %ptr_1076 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1247 = llvm.load %1246 : !llvm.ptr -> i8
      %1248 = llvm.icmp "ne" %1247, %0 : i8
      cf.cond_br %1248, ^bb336, ^bb337
    ^bb336:  // pred: ^bb335
      %1249 = builtin.unrealized_conversion_cast %ptr_1072 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1250 = builtin.unrealized_conversion_cast %ptr_1074 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1251 = llvm.load %1249 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1251, %1250 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb337
    ^bb337:  // 2 preds: ^bb335, ^bb336
      %1252 = arith.addi %1244, %c1_i32 : i32
      cf.br ^bb334(%1252 : i32)
    ^bb338:  // pred: ^bb334
      cf.br ^bb339
    ^bb339:  // 2 preds: ^bb332, ^bb338
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
