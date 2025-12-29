!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = global, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2,2),(1,1))):((128,1,16),((64,8,512),(0,0)))">, tiler_mn = <"[64:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_ldsm_4_2 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,4),((2,2),(2,1))):((32,1,0),((16,128),(8,0)))">, tiler_mn = <"[16:1;16:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16>, layout_copy_tv = <"((4,8,4),((2,2),(1,2))):((128,1,16),((64,8),(0,512)))">, tiler_mn = <"[64:1;16:1]">>
!copy_simt1 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((8,16),8):((128,1),16)">, tiler_mn = <"[16:1;64:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<16>, "((2,2,2),2,((2,2),2)):((1,2,4),8,((32,64),16))">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<8>, "((2,2),8,((2,2),2)):((1,2),4,((64,128),32))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<8>, "((2,2),(8,2),4):((1,2),(4,128),32)">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "((2,2),2,8):((1,2),4,8)">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<32>, "((2,2),2,16):((1,2),4,8)">
!memref_rmem_bf16_5 = !cute.memref<bf16, rmem, align<32>, "((8,1),8,2):((1,0),16,8)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),2,16):((1,2),4,8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((2,2),2,8):((1,2),4,8)">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "((2,2),(2,8)):((2,4),(1,8))">
!memref_rmem_f32_4 = !cute.memref<f32, rmem, align<32>, "((2,8)):((1,8))">
!memref_rmem_f32_5 = !cute.memref<f32, rmem, align<8>, "((2,8)):((1,8))">
!memref_rmem_f32_6 = !cute.memref<f32, rmem, align<16>, "((2,8)):((1,8))">
!memref_rmem_f32_7 = !cute.memref<f32, rmem, align<32>, "((2,16)):((1,8))">
!memref_rmem_f32_8 = !cute.memref<f32, rmem, align<8>, "((2,16)):((1,8))">
!memref_rmem_f32_9 = !cute.memref<f32, rmem, align<16>, "((2,16)):((1,8))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,8,2):(2,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,4,2):(2,0,1)">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),8192)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,1),2):((1,0),4096)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__FlashAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16g_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %cst = arith.constant dense<0.000000e+00> : vector<64xf32>
      %cst_0 = arith.constant dense<0.000000e+00> : vector<4xf32>
      %cst_1 = arith.constant dense<0xFF800000> : vector<4xf32>
      %cst_2 = arith.constant dense<0.000000e+00> : vector<16xbf16>
      %cst_3 = arith.constant dense<0.000000e+00> : vector<128xf32>
      %0 = llvm.mlir.constant(0 : i8) : i8
      %1 = cute.static : !cute.layout<"((8,1),((8,2))):((1,0),((16,8)))">
      %2 = cute.static : !cute.layout<"((8,1),((8,2))):((1,0),((1024,8192)))">
      %3 = cute.static : !cute.int_tuple<"10">
      %4 = cute.static : !cute.int_tuple<"512">
      %5 = cute.static : !cute.shape<"((1,(2,2,2)))">
      %6 = cute.static : !cute.shape<"((1,(2,2,2)),((2,((2,2),2))))">
      %7 = cute.static : !cute.layout<"((1,(4,2)),((2,8))):((0,(1,8)),((4,16)))">
      %8 = cute.static : !cute.shape<"((1,(2,2,2)),(2,((2,2),2)))">
      %9 = cute.static : !cute.shape<"((1,(2,2,2)),2,((2,2),2))">
      %c-8_i32 = arith.constant -8 : i32
      %cst_4 = arith.constant 1.000000e+00 : f32
      %10 = cute.static : !cute.int_tuple<"3">
      %11 = cute.static : !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">
      %12 = cute.static : !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">
      %13 = cute.static : !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">
      %14 = cute.static : !cute.shape<"((8,1),((((2,2),2))))">
      %15 = cute.static : !cute.shape<"((8,1),(((2,2),2)))">
      %16 = cute.static : !cute.shape<"((8,1),((2,2),2))">
      %17 = cute.static : !cute.coord<"3">
      %18 = cute.static : !cute.coord<"(3,15)">
      %19 = cute.static : !cute.coord<"(3,14)">
      %20 = cute.static : !cute.coord<"(3,13)">
      %21 = cute.static : !cute.coord<"(3,12)">
      %22 = cute.static : !cute.coord<"(3,11)">
      %23 = cute.static : !cute.coord<"(3,10)">
      %24 = cute.static : !cute.coord<"(3,9)">
      %25 = cute.static : !cute.coord<"(3,8)">
      %26 = cute.static : !cute.coord<"(3,7)">
      %27 = cute.static : !cute.coord<"(3,6)">
      %28 = cute.static : !cute.coord<"(3,5)">
      %29 = cute.static : !cute.coord<"(3,4)">
      %30 = cute.static : !cute.coord<"(3,3)">
      %31 = cute.static : !cute.coord<"(3,2)">
      %32 = cute.static : !cute.coord<"(3,1)">
      %33 = cute.static : !cute.coord<"(3,0)">
      %34 = cute.static : !cute.coord<"2">
      %35 = cute.static : !cute.coord<"(2,15)">
      %36 = cute.static : !cute.coord<"(2,14)">
      %37 = cute.static : !cute.coord<"(2,13)">
      %38 = cute.static : !cute.coord<"(2,12)">
      %39 = cute.static : !cute.coord<"(2,11)">
      %40 = cute.static : !cute.coord<"(2,10)">
      %41 = cute.static : !cute.coord<"(2,9)">
      %42 = cute.static : !cute.coord<"(2,8)">
      %43 = cute.static : !cute.coord<"(2,7)">
      %44 = cute.static : !cute.coord<"(2,6)">
      %45 = cute.static : !cute.coord<"(2,5)">
      %46 = cute.static : !cute.coord<"(2,4)">
      %47 = cute.static : !cute.coord<"(2,3)">
      %48 = cute.static : !cute.coord<"(2,2)">
      %49 = cute.static : !cute.coord<"(2,1)">
      %50 = cute.static : !cute.coord<"(2,0)">
      %51 = cute.static : !cute.coord<"1">
      %52 = cute.static : !cute.coord<"(1,15)">
      %53 = cute.static : !cute.coord<"(1,14)">
      %54 = cute.static : !cute.coord<"(1,13)">
      %55 = cute.static : !cute.coord<"(1,12)">
      %56 = cute.static : !cute.coord<"(1,11)">
      %57 = cute.static : !cute.coord<"(1,10)">
      %58 = cute.static : !cute.coord<"(1,9)">
      %59 = cute.static : !cute.coord<"(1,8)">
      %60 = cute.static : !cute.coord<"(1,7)">
      %61 = cute.static : !cute.coord<"(1,6)">
      %62 = cute.static : !cute.coord<"(1,5)">
      %63 = cute.static : !cute.coord<"(1,4)">
      %64 = cute.static : !cute.coord<"(1,3)">
      %65 = cute.static : !cute.coord<"(1,2)">
      %66 = cute.static : !cute.coord<"(1,1)">
      %67 = cute.static : !cute.coord<"(1,0)">
      %68 = cute.static : !cute.coord<"0">
      %c31_i32 = arith.constant 31 : i32
      %c-1_i32 = arith.constant -1 : i32
      %69 = cute.static : !cute.coord<"(0,15)">
      %70 = cute.static : !cute.int_tuple<"(0,0,0,57)">
      %71 = cute.static : !cute.coord<"(0,14)">
      %72 = cute.static : !cute.int_tuple<"(0,0,0,56)">
      %73 = cute.static : !cute.coord<"(0,13)">
      %74 = cute.static : !cute.int_tuple<"(0,0,0,49)">
      %75 = cute.static : !cute.coord<"(0,12)">
      %76 = cute.static : !cute.int_tuple<"(0,0,0,48)">
      %77 = cute.static : !cute.coord<"(0,11)">
      %78 = cute.static : !cute.int_tuple<"(0,0,0,41)">
      %79 = cute.static : !cute.coord<"(0,10)">
      %80 = cute.static : !cute.int_tuple<"(0,0,0,40)">
      %81 = cute.static : !cute.coord<"(0,9)">
      %82 = cute.static : !cute.int_tuple<"(0,0,0,33)">
      %83 = cute.static : !cute.coord<"(0,8)">
      %84 = cute.static : !cute.int_tuple<"(0,0,0,32)">
      %85 = cute.static : !cute.coord<"(0,7)">
      %86 = cute.static : !cute.int_tuple<"(0,0,0,25)">
      %87 = cute.static : !cute.coord<"(0,6)">
      %88 = cute.static : !cute.int_tuple<"(0,0,0,24)">
      %89 = cute.static : !cute.coord<"(0,5)">
      %90 = cute.static : !cute.int_tuple<"(0,0,0,17)">
      %91 = cute.static : !cute.coord<"(0,4)">
      %92 = cute.static : !cute.int_tuple<"(0,0,0,16)">
      %93 = cute.static : !cute.coord<"(0,3)">
      %94 = cute.static : !cute.int_tuple<"(0,0,0,9)">
      %95 = cute.static : !cute.coord<"(0,2)">
      %96 = cute.static : !cute.int_tuple<"(0,0,0,8)">
      %97 = cute.static : !cute.coord<"(0,1)">
      %98 = cute.static : !cute.int_tuple<"(0,0,0,1)">
      %99 = cute.static : !cute.coord<"(0,0)">
      %c4_i32 = arith.constant 4 : i32
      %100 = cute.static : !cute.stride<"((1@1,1@3),(128@1,64@3))">
      %101 = cute.static : !cute.layout<"((2,2),(2,8)):((2,4),(1,8))">
      %102 = cute.static : !cute.int_tuple<"224">
      %103 = cute.static : !cute.int_tuple<"112">
      %104 = cute.static : !cute.coord<"(_,_,7)">
      %105 = cute.static : !cute.int_tuple<"160">
      %106 = cute.static : !cute.int_tuple<"80">
      %107 = cute.static : !cute.coord<"(_,_,6)">
      %108 = cute.static : !cute.int_tuple<"48">
      %109 = cute.static : !cute.coord<"(_,_,5)">
      %110 = cute.static : !cute.int_tuple<"16">
      %111 = cute.static : !cute.int_tuple<"8192">
      %112 = cute.static : !cute.int_tuple<"192">
      %113 = cute.static : !cute.int_tuple<"96">
      %114 = cute.static : !cute.coord<"(_,_,3)">
      %115 = cute.static : !cute.int_tuple<"128">
      %116 = cute.static : !cute.coord<"(_,_,2)">
      %117 = cute.static : !cute.int_tuple<"1">
      %118 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %119 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %120 = cute.static : !cute.int_tuple<"64">
      %121 = cute.static : !cute.int_tuple<"32">
      %122 = cute.static : !cute.coord<"(_,_,1)">
      %123 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %124 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %125 = cute.static : !cute.int_tuple<"6">
      %126 = llvm.mlir.constant(3 : i32) : i32
      %127 = cute.static : !cute.int_tuple<"4">
      %128 = llvm.mlir.constant(2 : i32) : i32
      %129 = llvm.mlir.constant(1 : i32) : i32
      %130 = llvm.mlir.constant(0 : i32) : i32
      %131 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %132 = cute.static : !cute.int_tuple<"8">
      %133 = cute.static : !cute.layout<"(1,((4,2))):(2,((0,1)))">
      %134 = cute.static : !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">
      %135 = cute.static : !cute.shape<"((8,1),((4,2)))">
      %136 = cute.static : !cute.shape<"((8,1),(4,2))">
      %137 = cute.static : !cute.shape<"((8,1),4,2)">
      %138 = cute.static : !cute.layout<"((2,2),2,8):((1,2),4,8)">
      %cst_5 = arith.constant 0xFF800000 : f32
      %139 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((4096)))">
      %140 = cute.static : !cute.int_tuple<"7168">
      %141 = cute.static : !cute.coord<"(_,7,_)">
      %142 = cute.static : !cute.int_tuple<"(0,112,0,0)">
      %143 = cute.static : !cute.int_tuple<"6144">
      %144 = cute.static : !cute.coord<"(_,6,_)">
      %145 = cute.static : !cute.int_tuple<"(0,96,0,0)">
      %146 = cute.static : !cute.int_tuple<"5120">
      %147 = cute.static : !cute.coord<"(_,5,_)">
      %148 = cute.static : !cute.int_tuple<"(0,80,0,0)">
      %149 = cute.static : !cute.int_tuple<"4096">
      %150 = cute.static : !cute.coord<"(_,4,_)">
      %151 = cute.static : !cute.int_tuple<"(0,64,0,0)">
      %152 = cute.static : !cute.int_tuple<"3072">
      %153 = cute.static : !cute.coord<"(_,3,_)">
      %154 = cute.static : !cute.int_tuple<"(0,48,0,0)">
      %155 = cute.static : !cute.int_tuple<"2048">
      %156 = cute.static : !cute.coord<"(_,2,_)">
      %157 = cute.static : !cute.int_tuple<"(0,32,0,0)">
      %158 = cute.static : !cute.int_tuple<"1024">
      %159 = cute.static : !cute.coord<"(_,1,_)">
      %160 = cute.static : !cute.int_tuple<"(0,16,0,0)">
      %161 = cute.static : !cute.int_tuple<"2">
      %162 = cute.static : !cute.layout<"(1,((2))):(2,((1)))">
      %163 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8192)))">
      %164 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((64)))">
      %165 = cute.static : !cute.coord<"(0,0,1)">
      %166 = cute.static : !cute.int_tuple<"(0,0,0,64)">
      %167 = cute.static : !cute.coord<"(0,0,0)">
      %168 = cute.static : !cute.stride<"((1@1,1@3),(64@1,128@3))">
      %169 = cute.static : !cute.stride<"((1@1,1@3),(128@1,128@3))">
      %170 = cute.static : !cute.stride<"(1@1,1@3)">
      %171 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3)">
      %172 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %173 = cute.static : !cute.shape<"((8,1),((2,2),2),4)">
      %174 = cute.static : !cute.shape<"((8,1),4,((2,2),2))">
      %175 = cute.static : !cute.shape<"((8,1),2,((2,2),2))">
      %c-32_i32 = arith.constant -32 : i32
      %c32_i32 = arith.constant 32 : i32
      %c256_i32 = arith.constant 256 : i32
      %c-16_i32 = arith.constant -16 : i32
      %c1024_i32 = arith.constant 1024 : i32
      %c2_i32 = arith.constant 2 : i32
      %c16_i32 = arith.constant 16 : i32
      %cst_6 = arith.constant 0.000000e+00 : f32
      %176 = cute.static : !cute.layout<"((2,2),2,16):((1,2),4,8)">
      %c3_i32 = arith.constant 3 : i32
      %c448_i32 = arith.constant 448 : i32
      %c512_i32 = arith.constant 512 : i32
      %c0_i32 = arith.constant 0 : i32
      %177 = cute.static : !cute.shape<"((8,1),8,2)">
      %c8_i32 = arith.constant 8 : i32
      %c16_i64 = arith.constant 16 : i64
      %178 = cute.static : !cute.int_tuple<"49152">
      %179 = cute.static : !cute.int_tuple<"32768">
      %c64_i64 = arith.constant 64 : i64
      %180 = cute.static : !cute.shape<"(128,128)">
      %c128_i64 = arith.constant 128 : i64
      %c128_i32 = arith.constant 128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c64_i32 = arith.constant 64 : i32
      %181 = cute.static : !cute.layout<"1:0">
      %182 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %183 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %184 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %185 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %lay = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %186 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%186) : !cute.shape<"(?,?,?,?{div=8})">
      %itup = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %int_tuple = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %187 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
      %188 = arith.ceildivsi %187, %c64_i32 : i32
      %int_tuple_7 = cute.make_int_tuple(%188) : (i32) -> !cute.int_tuple<"?">
      %e0_8 = cute.get_leaves(%int_tuple_7) : !cute.int_tuple<"?">
      %189 = cute.get_scalars(%e0_8) : !cute.int_tuple<"?">
      %190 = arith.subi %189, %c1_i32 : i32
      %coord = cute.make_coord(%184, %185) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_9 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %191:7 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%191#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%191#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_10 = cute.assume(%191#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_10) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_11 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay_9) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_12 = cute.make_coord(%183) : (i32) -> !cute.coord<"(?,0)">
      %192 = cute.get_scalars(%coord_12) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_13 = cute.make_coord(%192) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %193:3 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %194 = arith.ceildivsi %193#0, %c128_i32 : i32
      %195 = arith.muli %193#2, %c128_i64 : i64
      %196 = arith.ceildivsi %193#1, %c128_i32 : i32
      %shape_14 = cute.make_shape(%194, %196) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_15 = cute.assume(%193#2) : (i64) -> !cute.i64<divby 8>
      %iv_16 = cute.assume(%195) : (i64) -> !cute.i64<divby 1024>
      %stride_17 = cute.make_stride(%iv_15, %iv_16) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_18 = cute.make_layout(%shape_14, %stride_17) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %197:4 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %iv_19 = cute.assume(%197#2) : (i64) -> !cute.i64<divby 8>
      %stride_20 = cute.make_stride(%iv_19) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_21 = cute.make_layout(%180, %stride_20) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_22 = cute.crd2idx(%coord_13, %lay_18) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %ptr_23 = cute.add_offset(%ptr, %idx_22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %198:7 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_24 = cute.assume(%198#3) : (i32) -> !cute.i32<divby 8>
      %shape_25 = cute.make_shape(%198#1, %iv_24) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_26 = cute.assume(%198#5) : (i64) -> !cute.i64<divby 8>
      %stride_27 = cute.make_stride(%iv_26) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_28 = cute.make_layout(%shape_25, %stride_27) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_29 = cute.crd2idx(%coord, %lay) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_30 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_31 = cute.add_offset(%iter_30, %idx_29) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %199:3 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %200 = arith.ceildivsi %199#0, %c64_i32 : i32
      %201 = arith.muli %199#2, %c64_i64 : i64
      %202 = arith.ceildivsi %199#1, %c128_i32 : i32
      %shape_32 = cute.make_shape(%200, %202) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_33 = cute.assume(%199#2) : (i64) -> !cute.i64<divby 8>
      %iv_34 = cute.assume(%201) : (i64) -> !cute.i64<divby 512>
      %stride_35 = cute.make_stride(%iv_33, %iv_34) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_36 = cute.make_layout(%shape_32, %stride_35) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %203:4 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_37 = cute.make_shape(%203#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_38 = cute.assume(%203#2) : (i64) -> !cute.i64<divby 8>
      %iv_39 = cute.assume(%203#3) : (i64) -> !cute.i64<divby 512>
      %stride_40 = cute.make_stride(%iv_38, %iv_39) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_41 = cute.make_layout(%shape_37, %stride_40) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %lay_42 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %204:7 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_43 = cute.assume(%204#3) : (i32) -> !cute.i32<divby 8>
      %shape_44 = cute.make_shape(%204#1, %iv_43) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_45 = cute.assume(%204#5) : (i64) -> !cute.i64<divby 8>
      %stride_46 = cute.make_stride(%iv_45) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_47 = cute.make_layout(%shape_44, %stride_46) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_48 = cute.crd2idx(%coord, %lay_42) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_49 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_50 = cute.add_offset(%iter_49, %idx_48) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %205:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %206 = arith.ceildivsi %205#0, %c64_i32 : i32
      %207 = arith.muli %205#2, %c64_i64 : i64
      %208 = arith.ceildivsi %205#1, %c128_i32 : i32
      %shape_51 = cute.make_shape(%206, %208) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_52 = cute.assume(%205#2) : (i64) -> !cute.i64<divby 8>
      %iv_53 = cute.assume(%207) : (i64) -> !cute.i64<divby 512>
      %stride_54 = cute.make_stride(%iv_52, %iv_53) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_55 = cute.make_layout(%shape_51, %stride_54) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %209:4 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_56 = cute.make_shape(%209#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_57 = cute.assume(%209#2) : (i64) -> !cute.i64<divby 8>
      %iv_58 = cute.assume(%209#3) : (i64) -> !cute.i64<divby 512>
      %stride_59 = cute.make_stride(%iv_57, %iv_58) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_60 = cute.make_layout(%shape_56, %stride_59) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_61 = cute.add_offset(%smem_ptr, %179) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_62 = cute.add_offset(%smem_ptr, %178) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_63 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_64 = cute.recast_iter(%ptr_61) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_65 = cute.recast_iter(%ptr_62) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %coord_66 = cute.make_coord(%182) : (i32) -> !cute.coord<"?">
      %210 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %211 = cute.get_scalars(%coord_66) <{only_dynamic}> : !cute.coord<"?">
      %212 = arith.muli %210, %c16_i64 : i64
      %213 = arith.divsi %211, %c8_i32 : i32
      %214 = arith.remsi %211, %c8_i32 : i32
      %215 = arith.muli %214, %c8_i32 : i32
      %216 = arith.extsi %213 : i32 to i64
      %217 = arith.muli %216, %210 : i64
      %218 = arith.extsi %215 : i32 to i64
      %219 = arith.addi %218, %217 : i64
      %iv_67 = cute.assume(%219) : (i64) -> !cute.i64<divby 8>
      %int_tuple_68 = cute.make_int_tuple(%iv_67) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_69 = cute.add_offset(%ptr_23, %int_tuple_68) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_70 = cute.assume(%212) : (i64) -> !cute.i64<divby 128>
      %stride_71 = cute.make_stride(%iv_70) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_72 = cute.make_layout(%177, %stride_71) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %220 = arith.remsi %213, %c8_i32 : i32
      %221 = arith.muli %220, %c64_i32 : i32
      %222 = arith.addi %215, %221 : i32
      %223 = arith.divsi %213, %c8_i32 : i32
      %224 = arith.muli %223, %c512_i32 : i32
      %225 = arith.andi %222, %c448_i32 : i32
      %226 = arith.shrsi %225, %c3_i32 : i32
      %227 = arith.xori %222, %226 : i32
      %228 = arith.addi %227, %224 : i32
      %iv_73 = cute.assume(%228) : (i32) -> !cute.i32<divby 8>
      %int_tuple_74 = cute.make_int_tuple(%iv_73) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_75 = cute.add_offset(%iter_63, %int_tuple_74) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %229:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %230 = arith.muli %229#1, %c16_i64 : i64
      %231 = arith.muli %216, %229#1 : i64
      %232 = arith.addi %218, %231 : i64
      %iv_76 = cute.assume(%232) : (i64) -> !cute.i64<divby 8>
      %int_tuple_77 = cute.make_int_tuple(%iv_76) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_78 = cute.add_offset(%ptr_31, %int_tuple_77) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_79 = cute.make_shape(%229#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_80 = cute.assume(%230) : (i64) -> !cute.i64<divby 128>
      %iv_81 = cute.assume(%229#2) : (i64) -> !cute.i64<divby 512>
      %stride_82 = cute.make_stride(%iv_80, %iv_81) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_83 = cute.make_layout(%shape_79, %stride_82) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_84 = cute.add_offset(%iter_64, %int_tuple_74) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %233:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %234 = arith.muli %233#1, %c16_i64 : i64
      %235 = arith.muli %216, %233#1 : i64
      %236 = arith.addi %218, %235 : i64
      %iv_85 = cute.assume(%236) : (i64) -> !cute.i64<divby 8>
      %int_tuple_86 = cute.make_int_tuple(%iv_85) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_87 = cute.add_offset(%ptr_50, %int_tuple_86) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_88 = cute.make_shape(%233#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_89 = cute.assume(%234) : (i64) -> !cute.i64<divby 128>
      %iv_90 = cute.assume(%233#2) : (i64) -> !cute.i64<divby 512>
      %stride_91 = cute.make_stride(%iv_89, %iv_90) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_92 = cute.make_layout(%shape_88, %stride_91) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_93 = cute.add_offset(%iter_65, %int_tuple_74) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_94 = cute.memref.alloca() : !memref_rmem_bf16_1
      %rmem_95 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_96 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_97 = cute.get_iter(%rmem_96) : !memref_rmem_f32_
      cute.memref.store_vec %cst_3, %rmem_96 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_98 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %237 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %238 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %239 = cute.make_tiled_copy(%atom_98) : !copy_ldsm_4_2
      %240 = arith.divsi %211, %c16_i32 : i32
      %241 = arith.remsi %211, %c16_i32 : i32
      %242 = arith.remsi %241, %c8_i32 : i32
      %243 = arith.muli %242, %c64_i32 : i32
      %244 = arith.remsi %240, %c2_i32 : i32
      %245 = arith.muli %244, %c8_i32 : i32
      %246 = arith.addi %243, %245 : i32
      %247 = arith.divsi %241, %c8_i32 : i32
      %248 = arith.muli %247, %c512_i32 : i32
      %249 = arith.divsi %240, %c2_i32 : i32
      %250 = arith.muli %249, %c1024_i32 : i32
      %251 = arith.addi %248, %250 : i32
      %252 = arith.andi %246, %c128_i32 : i32
      %253 = arith.cmpi eq, %252, %c0_i32 : i32
      %254 = arith.select %253, %c16_i32, %c-16_i32 : i32
      %255 = arith.andi %246, %c256_i32 : i32
      %256 = arith.cmpi eq, %255, %c0_i32 : i32
      %257 = arith.select %256, %c32_i32, %c-32_i32 : i32
      %258 = arith.andi %246, %c448_i32 : i32
      %259 = arith.shrsi %258, %c3_i32 : i32
      %260 = arith.xori %246, %259 : i32
      %261 = arith.addi %260, %251 : i32
      %iv_99 = cute.assume(%261) : (i32) -> !cute.i32<divby 8>
      %int_tuple_100 = cute.make_int_tuple(%iv_99) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_101 = cute.add_offset(%iter_63, %int_tuple_100) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_102 = cute.assume(%254) : (i32) -> !cute.i32<divby 16>
      %iv_103 = cute.assume(%257) : (i32) -> !cute.i32<divby 32>
      %stride_104 = cute.make_stride(%iv_102, %iv_103) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),4096,((?{div=16},?{div=32}),8192))">
      %lay_105 = cute.make_layout(%175, %stride_104) : !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">
      %iter_106 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %262 = arith.muli %214, %c64_i32 : i32
      %263 = arith.remsi %213, %c2_i32 : i32
      %264 = arith.muli %263, %c8_i32 : i32
      %265 = arith.addi %262, %264 : i32
      %266 = arith.divsi %213, %c2_i32 : i32
      %267 = arith.remsi %266, %c2_i32 : i32
      %268 = arith.muli %267, %c512_i32 : i32
      %269 = arith.andi %265, %c128_i32 : i32
      %270 = arith.cmpi eq, %269, %c0_i32 : i32
      %271 = arith.select %270, %c16_i32, %c-16_i32 : i32
      %272 = arith.andi %265, %c256_i32 : i32
      %273 = arith.cmpi eq, %272, %c0_i32 : i32
      %274 = arith.select %273, %c32_i32, %c-32_i32 : i32
      %275 = arith.andi %265, %c448_i32 : i32
      %276 = arith.shrsi %275, %c3_i32 : i32
      %277 = arith.xori %265, %276 : i32
      %278 = arith.addi %277, %268 : i32
      %iv_107 = cute.assume(%278) : (i32) -> !cute.i32<divby 8>
      %int_tuple_108 = cute.make_int_tuple(%iv_107) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_109 = cute.add_offset(%iter_64, %int_tuple_108) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_110 = cute.assume(%271) : (i32) -> !cute.i32<divby 16>
      %iv_111 = cute.assume(%274) : (i32) -> !cute.i32<divby 32>
      %stride_112 = cute.make_stride(%iv_110, %iv_111) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_113 = cute.make_layout(%174, %stride_112) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %iter_114 = cute.get_iter(%rmem_94) : !memref_rmem_bf16_1
      %279 = arith.addi %260, %248 : i32
      %iv_115 = cute.assume(%279) : (i32) -> !cute.i32<divby 8>
      %int_tuple_116 = cute.make_int_tuple(%iv_115) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_117 = cute.add_offset(%iter_65, %int_tuple_116) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_118 = cute.make_stride(%iv_102, %iv_103) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_119 = cute.make_layout(%173, %stride_118) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iter_120 = cute.get_iter(%rmem_95) : !memref_rmem_bf16_2
      %280 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_121, %e1_122, %e2_123, %e3_124 = cute.get_leaves(%280) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_125 = cute.to_int_tuple(%e0_121) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_126 = cute.to_int_tuple(%e1_122) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_127 = cute.to_int_tuple(%e2_123) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_128 = cute.to_int_tuple(%e3_124) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_129 = cute.make_shape(%itup_125, %itup_126, %itup_127, %itup_128) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_130 = cute.make_layout(%shape_129, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %itup_131 = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_132 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_133 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_134 = cute.make_shape(%itup_131, %itup, %itup_132, %itup_133) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_135 = cute.make_layout(%shape_134, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %281:4 = cute.get_scalars(%lay_130) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_136 = cute.assume(%281#3) : (i32) -> !cute.i32<divby 8>
      %shape_137 = cute.make_shape(%281#1, %iv_136) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_138 = cute.make_layout(%shape_137, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_139 = cute.crd2idx(%coord, %lay_130) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup = cute.add_offset(%172, %idx_139) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %282:2 = cute.get_scalars(%lay_138) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %283 = arith.ceildivsi %282#0, %c128_i32 : i32
      %284 = arith.ceildivsi %282#1, %c128_i32 : i32
      %shape_140 = cute.make_shape(%283, %284) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %lay_141 = cute.make_layout(%shape_140, %169) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_142 = cute.crd2idx(%coord_13, %lay_141) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_143 = cute.add_offset(%tup, %idx_142) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %285:4 = cute.get_scalars(%lay_135) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_144 = cute.assume(%285#3) : (i32) -> !cute.i32<divby 8>
      %shape_145 = cute.make_shape(%285#1, %iv_144) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_146 = cute.make_layout(%shape_145, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_147 = cute.crd2idx(%coord, %lay_135) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_148 = cute.add_offset(%172, %idx_147) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_149 = cute.make_coord(%190) : (i32) -> !cute.coord<"(?,0)">
      %286 = cute.get_scalars(%coord_149) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_150 = cute.make_coord(%286) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %287:2 = cute.get_scalars(%lay_146) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %288 = arith.ceildivsi %287#0, %c64_i32 : i32
      %289 = arith.ceildivsi %287#1, %c128_i32 : i32
      %shape_151 = cute.make_shape(%288, %289) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_152 = cute.make_layout(%shape_151, %168) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_153 = cute.crd2idx(%coord_150, %lay_152) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_154 = cute.add_offset(%tup_148, %idx_153) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %iv_155 = cute.assume(%215) : (i32) -> !cute.i32<divby 8>
      %int_tuple_156 = cute.make_int_tuple(%213, %iv_155) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_157 = cute.add_offset(%tup_143, %int_tuple_156) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %tup_158 = cute.add_offset(%tup_154, %int_tuple_156) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_159 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_160 = cute.memref.alloca() : !memref_rmem_i8_1
      %iter_161 = cute.get_iter(%rmem_160) : !memref_rmem_i8_1
      %e0_162, %e1_163, %e2_164, %e3_165 = cute.get_leaves(%tup_157) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_166 = cute.make_coord(%e3_165) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_167 = cute.make_coord(%itup_128) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %290 = cute.get_scalars(%coord_166) : !cute.coord<"?{div=8}">
      %291 = cute.get_scalars(%coord_167) : !cute.coord<"?{div=8}">
      %292 = arith.cmpi slt, %290, %291 : i32
      %293 = arith.extui %292 : i1 to i8
      cute.memref.store(%rmem_159, %167, %293) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_168 = cute.add_offset(%tup_157, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_169, %e1_170, %e2_171, %e3_172 = cute.get_leaves(%tup_168) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_173 = cute.make_coord(%e3_172) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %294 = cute.get_scalars(%coord_173) : !cute.coord<"?{div=8}">
      %295 = arith.cmpi slt, %294, %291 : i32
      %296 = arith.extui %295 : i1 to i8
      cute.memref.store(%rmem_159, %165, %296) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_174, %e1_175, %e2_176, %e3_177 = cute.get_leaves(%tup_158) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_178 = cute.make_coord(%e3_177) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_179 = cute.make_coord(%itup_133) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %297 = cute.get_scalars(%coord_178) : !cute.coord<"?{div=8}">
      %298 = cute.get_scalars(%coord_179) : !cute.coord<"?{div=8}">
      %299 = arith.cmpi slt, %297, %298 : i32
      %300 = arith.extui %299 : i1 to i8
      cute.memref.store(%rmem_160, %167, %300) : (!memref_rmem_i8_1, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_180 = cute.add_offset(%tup_158, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_181, %e1_182, %e2_183, %e3_184 = cute.get_leaves(%tup_180) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_185 = cute.make_coord(%e3_184) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %301 = cute.get_scalars(%coord_185) : !cute.coord<"?{div=8}">
      %302 = arith.cmpi slt, %301, %298 : i32
      %303 = arith.extui %302 : i1 to i8
      cute.memref.store(%rmem_160, %165, %303) : (!memref_rmem_i8_1, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_186 = cute.make_coord(%e1_163) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_187 = cute.make_coord(%itup_126) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %304 = cute.get_scalars(%coord_186) : !cute.coord<"?">
      %305 = cute.get_scalars(%coord_187) : !cute.coord<"?">
      %306 = arith.cmpi slt, %304, %305 : i32
      cf.cond_br %306, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %iter_188 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %307 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%308: i32):  // 2 preds: ^bb1, ^bb3
      %309 = arith.cmpi slt, %308, %307 : i32
      cf.cond_br %309, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_189 = cute.make_coord(%308) : (i32) -> !cute.coord<"(_,?)">
      %idx_190 = cute.crd2idx(%coord_189, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_191 = cute.add_offset(%ptr_69, %idx_190) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_192 = cute.crd2idx(%coord_189, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_193 = cute.add_offset(%ptr_75, %idx_192) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_194 = cute.crd2idx(%coord_189, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_195 = cute.add_offset(%iter_188, %idx_194) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %310 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<i8, rmem> to !llvm.ptr
      %311 = llvm.load %310 : !llvm.ptr -> i8
      %312 = llvm.trunc %311 : i8 to i1
      %iter_196 = cute.recast_iter(%ptr_191) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_197 = cute.recast_iter(%ptr_193) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_197 : !cute.ptr<i128, smem>, %iter_196 : !cute.ptr<i128, gmem>, %312 : i1) {cache_mode = <global>}
      %313 = arith.addi %308, %c1_i32 : i32
      cf.br ^bb2(%313 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb6
    ^bb5:  // pred: ^bb0
      %view = cute.make_view(%ptr_75) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view : !memref_smem_bf16_
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %tup_198 = cute.add_offset(%tup_157, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_199, %e1_200, %e2_201, %e3_202 = cute.get_leaves(%tup_198) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_203 = cute.make_coord(%e1_200) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %314 = cute.get_scalars(%coord_203) : !cute.coord<"?">
      %315 = arith.cmpi slt, %314, %305 : i32
      cf.cond_br %315, ^bb7, ^bb11
    ^bb7:  // pred: ^bb6
      %idx_204 = cute.crd2idx(%159, %lay_72) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_205 = cute.add_offset(%ptr_69, %idx_204) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_206 = cute.add_offset(%ptr_75, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_207 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %316 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb8(%c0_i32 : i32)
    ^bb8(%317: i32):  // 2 preds: ^bb7, ^bb9
      %318 = arith.cmpi slt, %317, %316 : i32
      cf.cond_br %318, ^bb9, ^bb10 {llvm.loop_annotation = #loop_annotation}
    ^bb9:  // pred: ^bb8
      %coord_208 = cute.make_coord(%317) : (i32) -> !cute.coord<"(_,?)">
      %idx_209 = cute.crd2idx(%coord_208, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_210 = cute.add_offset(%ptr_205, %idx_209) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_211 = cute.crd2idx(%coord_208, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_212 = cute.add_offset(%ptr_206, %idx_211) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_213 = cute.crd2idx(%coord_208, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_214 = cute.add_offset(%iter_207, %idx_213) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %319 = builtin.unrealized_conversion_cast %ptr_214 : !cute.ptr<i8, rmem> to !llvm.ptr
      %320 = llvm.load %319 : !llvm.ptr -> i8
      %321 = llvm.trunc %320 : i8 to i1
      %iter_215 = cute.recast_iter(%ptr_210) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_216 = cute.recast_iter(%ptr_212) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_216 : !cute.ptr<i128, smem>, %iter_215 : !cute.ptr<i128, gmem>, %321 : i1) {cache_mode = <global>}
      %322 = arith.addi %317, %c1_i32 : i32
      cf.br ^bb8(%322 : i32)
    ^bb10:  // pred: ^bb8
      cf.br ^bb12
    ^bb11:  // pred: ^bb6
      %ptr_217 = cute.add_offset(%ptr_75, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_218 = cute.make_view(%ptr_217) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_218 : !memref_smem_bf16_
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %tup_219 = cute.add_offset(%tup_157, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_220, %e1_221, %e2_222, %e3_223 = cute.get_leaves(%tup_219) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_224 = cute.make_coord(%e1_221) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %323 = cute.get_scalars(%coord_224) : !cute.coord<"?">
      %324 = arith.cmpi slt, %323, %305 : i32
      cf.cond_br %324, ^bb13, ^bb17
    ^bb13:  // pred: ^bb12
      %idx_225 = cute.crd2idx(%156, %lay_72) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_226 = cute.add_offset(%ptr_69, %idx_225) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_227 = cute.add_offset(%ptr_75, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_228 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %325 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb14(%c0_i32 : i32)
    ^bb14(%326: i32):  // 2 preds: ^bb13, ^bb15
      %327 = arith.cmpi slt, %326, %325 : i32
      cf.cond_br %327, ^bb15, ^bb16 {llvm.loop_annotation = #loop_annotation}
    ^bb15:  // pred: ^bb14
      %coord_229 = cute.make_coord(%326) : (i32) -> !cute.coord<"(_,?)">
      %idx_230 = cute.crd2idx(%coord_229, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_231 = cute.add_offset(%ptr_226, %idx_230) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_232 = cute.crd2idx(%coord_229, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_233 = cute.add_offset(%ptr_227, %idx_232) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_234 = cute.crd2idx(%coord_229, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_235 = cute.add_offset(%iter_228, %idx_234) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %328 = builtin.unrealized_conversion_cast %ptr_235 : !cute.ptr<i8, rmem> to !llvm.ptr
      %329 = llvm.load %328 : !llvm.ptr -> i8
      %330 = llvm.trunc %329 : i8 to i1
      %iter_236 = cute.recast_iter(%ptr_231) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_237 = cute.recast_iter(%ptr_233) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_237 : !cute.ptr<i128, smem>, %iter_236 : !cute.ptr<i128, gmem>, %330 : i1) {cache_mode = <global>}
      %331 = arith.addi %326, %c1_i32 : i32
      cf.br ^bb14(%331 : i32)
    ^bb16:  // pred: ^bb14
      cf.br ^bb18
    ^bb17:  // pred: ^bb12
      %ptr_238 = cute.add_offset(%ptr_75, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_239 = cute.make_view(%ptr_238) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_239 : !memref_smem_bf16_
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      %tup_240 = cute.add_offset(%tup_157, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_241, %e1_242, %e2_243, %e3_244 = cute.get_leaves(%tup_240) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_245 = cute.make_coord(%e1_242) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %332 = cute.get_scalars(%coord_245) : !cute.coord<"?">
      %333 = arith.cmpi slt, %332, %305 : i32
      cf.cond_br %333, ^bb19, ^bb23
    ^bb19:  // pred: ^bb18
      %idx_246 = cute.crd2idx(%153, %lay_72) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_247 = cute.add_offset(%ptr_69, %idx_246) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_248 = cute.add_offset(%ptr_75, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_249 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %334 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb20(%c0_i32 : i32)
    ^bb20(%335: i32):  // 2 preds: ^bb19, ^bb21
      %336 = arith.cmpi slt, %335, %334 : i32
      cf.cond_br %336, ^bb21, ^bb22 {llvm.loop_annotation = #loop_annotation}
    ^bb21:  // pred: ^bb20
      %coord_250 = cute.make_coord(%335) : (i32) -> !cute.coord<"(_,?)">
      %idx_251 = cute.crd2idx(%coord_250, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_252 = cute.add_offset(%ptr_247, %idx_251) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_253 = cute.crd2idx(%coord_250, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_254 = cute.add_offset(%ptr_248, %idx_253) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_255 = cute.crd2idx(%coord_250, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_256 = cute.add_offset(%iter_249, %idx_255) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %337 = builtin.unrealized_conversion_cast %ptr_256 : !cute.ptr<i8, rmem> to !llvm.ptr
      %338 = llvm.load %337 : !llvm.ptr -> i8
      %339 = llvm.trunc %338 : i8 to i1
      %iter_257 = cute.recast_iter(%ptr_252) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_258 = cute.recast_iter(%ptr_254) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_258 : !cute.ptr<i128, smem>, %iter_257 : !cute.ptr<i128, gmem>, %339 : i1) {cache_mode = <global>}
      %340 = arith.addi %335, %c1_i32 : i32
      cf.br ^bb20(%340 : i32)
    ^bb22:  // pred: ^bb20
      cf.br ^bb24
    ^bb23:  // pred: ^bb18
      %ptr_259 = cute.add_offset(%ptr_75, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_260 = cute.make_view(%ptr_259) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_260 : !memref_smem_bf16_
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %tup_261 = cute.add_offset(%tup_157, %151) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_262, %e1_263, %e2_264, %e3_265 = cute.get_leaves(%tup_261) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_266 = cute.make_coord(%e1_263) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %341 = cute.get_scalars(%coord_266) : !cute.coord<"?">
      %342 = arith.cmpi slt, %341, %305 : i32
      cf.cond_br %342, ^bb25, ^bb29
    ^bb25:  // pred: ^bb24
      %idx_267 = cute.crd2idx(%150, %lay_72) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_268 = cute.add_offset(%ptr_69, %idx_267) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_269 = cute.add_offset(%ptr_75, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_270 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %343 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb26(%c0_i32 : i32)
    ^bb26(%344: i32):  // 2 preds: ^bb25, ^bb27
      %345 = arith.cmpi slt, %344, %343 : i32
      cf.cond_br %345, ^bb27, ^bb28 {llvm.loop_annotation = #loop_annotation}
    ^bb27:  // pred: ^bb26
      %coord_271 = cute.make_coord(%344) : (i32) -> !cute.coord<"(_,?)">
      %idx_272 = cute.crd2idx(%coord_271, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_273 = cute.add_offset(%ptr_268, %idx_272) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_274 = cute.crd2idx(%coord_271, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_275 = cute.add_offset(%ptr_269, %idx_274) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_276 = cute.crd2idx(%coord_271, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_277 = cute.add_offset(%iter_270, %idx_276) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %346 = builtin.unrealized_conversion_cast %ptr_277 : !cute.ptr<i8, rmem> to !llvm.ptr
      %347 = llvm.load %346 : !llvm.ptr -> i8
      %348 = llvm.trunc %347 : i8 to i1
      %iter_278 = cute.recast_iter(%ptr_273) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_279 = cute.recast_iter(%ptr_275) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_279 : !cute.ptr<i128, smem>, %iter_278 : !cute.ptr<i128, gmem>, %348 : i1) {cache_mode = <global>}
      %349 = arith.addi %344, %c1_i32 : i32
      cf.br ^bb26(%349 : i32)
    ^bb28:  // pred: ^bb26
      cf.br ^bb30
    ^bb29:  // pred: ^bb24
      %ptr_280 = cute.add_offset(%ptr_75, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %view_281 = cute.make_view(%ptr_280) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_281 : !memref_smem_bf16_
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %tup_282 = cute.add_offset(%tup_157, %148) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_283, %e1_284, %e2_285, %e3_286 = cute.get_leaves(%tup_282) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_287 = cute.make_coord(%e1_284) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %350 = cute.get_scalars(%coord_287) : !cute.coord<"?">
      %351 = arith.cmpi slt, %350, %305 : i32
      cf.cond_br %351, ^bb31, ^bb35
    ^bb31:  // pred: ^bb30
      %idx_288 = cute.crd2idx(%147, %lay_72) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
      %ptr_289 = cute.add_offset(%ptr_69, %idx_288) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_290 = cute.add_offset(%ptr_75, %146) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_291 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %352 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%353: i32):  // 2 preds: ^bb31, ^bb33
      %354 = arith.cmpi slt, %353, %352 : i32
      cf.cond_br %354, ^bb33, ^bb34 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_292 = cute.make_coord(%353) : (i32) -> !cute.coord<"(_,?)">
      %idx_293 = cute.crd2idx(%coord_292, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_294 = cute.add_offset(%ptr_289, %idx_293) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_295 = cute.crd2idx(%coord_292, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_296 = cute.add_offset(%ptr_290, %idx_295) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_297 = cute.crd2idx(%coord_292, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_298 = cute.add_offset(%iter_291, %idx_297) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %355 = builtin.unrealized_conversion_cast %ptr_298 : !cute.ptr<i8, rmem> to !llvm.ptr
      %356 = llvm.load %355 : !llvm.ptr -> i8
      %357 = llvm.trunc %356 : i8 to i1
      %iter_299 = cute.recast_iter(%ptr_294) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_300 = cute.recast_iter(%ptr_296) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_300 : !cute.ptr<i128, smem>, %iter_299 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <global>}
      %358 = arith.addi %353, %c1_i32 : i32
      cf.br ^bb32(%358 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb36
    ^bb35:  // pred: ^bb30
      %ptr_301 = cute.add_offset(%ptr_75, %146) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
      %view_302 = cute.make_view(%ptr_301) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_302 : !memref_smem_bf16_
      cf.br ^bb36
    ^bb36:  // 2 preds: ^bb34, ^bb35
      %tup_303 = cute.add_offset(%tup_157, %145) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_304, %e1_305, %e2_306, %e3_307 = cute.get_leaves(%tup_303) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_308 = cute.make_coord(%e1_305) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %359 = cute.get_scalars(%coord_308) : !cute.coord<"?">
      %360 = arith.cmpi slt, %359, %305 : i32
      cf.cond_br %360, ^bb37, ^bb41
    ^bb37:  // pred: ^bb36
      %idx_309 = cute.crd2idx(%144, %lay_72) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
      %ptr_310 = cute.add_offset(%ptr_69, %idx_309) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_311 = cute.add_offset(%ptr_75, %143) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_312 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %361 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%362: i32):  // 2 preds: ^bb37, ^bb39
      %363 = arith.cmpi slt, %362, %361 : i32
      cf.cond_br %363, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_313 = cute.make_coord(%362) : (i32) -> !cute.coord<"(_,?)">
      %idx_314 = cute.crd2idx(%coord_313, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_315 = cute.add_offset(%ptr_310, %idx_314) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_316 = cute.crd2idx(%coord_313, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_317 = cute.add_offset(%ptr_311, %idx_316) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_318 = cute.crd2idx(%coord_313, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_319 = cute.add_offset(%iter_312, %idx_318) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %364 = builtin.unrealized_conversion_cast %ptr_319 : !cute.ptr<i8, rmem> to !llvm.ptr
      %365 = llvm.load %364 : !llvm.ptr -> i8
      %366 = llvm.trunc %365 : i8 to i1
      %iter_320 = cute.recast_iter(%ptr_315) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_321 = cute.recast_iter(%ptr_317) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_321 : !cute.ptr<i128, smem>, %iter_320 : !cute.ptr<i128, gmem>, %366 : i1) {cache_mode = <global>}
      %367 = arith.addi %362, %c1_i32 : i32
      cf.br ^bb38(%367 : i32)
    ^bb40:  // pred: ^bb38
      cf.br ^bb42
    ^bb41:  // pred: ^bb36
      %ptr_322 = cute.add_offset(%ptr_75, %143) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
      %view_323 = cute.make_view(%ptr_322) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_323 : !memref_smem_bf16_
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      %tup_324 = cute.add_offset(%tup_157, %142) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_325, %e1_326, %e2_327, %e3_328 = cute.get_leaves(%tup_324) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_329 = cute.make_coord(%e1_326) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %368 = cute.get_scalars(%coord_329) : !cute.coord<"?">
      %369 = arith.cmpi slt, %368, %305 : i32
      cf.cond_br %369, ^bb43, ^bb47
    ^bb43:  // pred: ^bb42
      %idx_330 = cute.crd2idx(%141, %lay_72) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
      %ptr_331 = cute.add_offset(%ptr_69, %idx_330) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_332 = cute.add_offset(%ptr_75, %140) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_333 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
      %370 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%371: i32):  // 2 preds: ^bb43, ^bb45
      %372 = arith.cmpi slt, %371, %370 : i32
      cf.cond_br %372, ^bb45, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %coord_334 = cute.make_coord(%371) : (i32) -> !cute.coord<"(_,?)">
      %idx_335 = cute.crd2idx(%coord_334, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_336 = cute.add_offset(%ptr_331, %idx_335) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_337 = cute.crd2idx(%coord_334, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_338 = cute.add_offset(%ptr_332, %idx_337) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_339 = cute.crd2idx(%coord_334, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_340 = cute.add_offset(%iter_333, %idx_339) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %373 = builtin.unrealized_conversion_cast %ptr_340 : !cute.ptr<i8, rmem> to !llvm.ptr
      %374 = llvm.load %373 : !llvm.ptr -> i8
      %375 = llvm.trunc %374 : i8 to i1
      %iter_341 = cute.recast_iter(%ptr_336) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_342 = cute.recast_iter(%ptr_338) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_342 : !cute.ptr<i128, smem>, %iter_341 : !cute.ptr<i128, gmem>, %375 : i1) {cache_mode = <global>}
      %376 = arith.addi %371, %c1_i32 : i32
      cf.br ^bb44(%376 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb48
    ^bb47:  // pred: ^bb42
      %ptr_343 = cute.add_offset(%ptr_75, %140) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
      %view_344 = cute.make_view(%ptr_343) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_344 : !memref_smem_bf16_
      cf.br ^bb48
    ^bb48:  // 2 preds: ^bb46, ^bb47
      %coord_345 = cute.make_coord(%e1_175) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_346 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %377 = cute.get_scalars(%coord_345) : !cute.coord<"?">
      %378 = cute.get_scalars(%coord_346) : !cute.coord<"?">
      %379 = arith.cmpi slt, %377, %378 : i32
      cf.cond_br %379, ^bb49, ^bb53
    ^bb49:  // pred: ^bb48
      %coord_347 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,0,_,?)">
      %idx_348 = cute.crd2idx(%coord_347, %lay_83) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_349 = cute.add_offset(%ptr_78, %idx_348) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %380 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb50(%c0_i32 : i32)
    ^bb50(%381: i32):  // 2 preds: ^bb49, ^bb51
      %382 = arith.cmpi slt, %381, %380 : i32
      cf.cond_br %382, ^bb51, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb51:  // pred: ^bb50
      %coord_350 = cute.make_coord(%381) : (i32) -> !cute.coord<"(_,?)">
      %idx_351 = cute.crd2idx(%coord_350, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_352 = cute.add_offset(%ptr_349, %idx_351) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_353 = cute.crd2idx(%coord_350, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_354 = cute.add_offset(%ptr_84, %idx_353) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_355 = cute.crd2idx(%coord_350, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_356 = cute.add_offset(%iter_161, %idx_355) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %383 = builtin.unrealized_conversion_cast %ptr_356 : !cute.ptr<i8, rmem> to !llvm.ptr
      %384 = llvm.load %383 : !llvm.ptr -> i8
      %385 = llvm.trunc %384 : i8 to i1
      %iter_357 = cute.recast_iter(%ptr_352) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_358 = cute.recast_iter(%ptr_354) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_358 : !cute.ptr<i128, smem>, %iter_357 : !cute.ptr<i128, gmem>, %385 : i1) {cache_mode = <global>}
      %386 = arith.addi %381, %c1_i32 : i32
      cf.br ^bb50(%386 : i32)
    ^bb52:  // pred: ^bb50
      cf.br ^bb54
    ^bb53:  // pred: ^bb48
      %view_359 = cute.make_view(%ptr_84) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_359 : !memref_smem_bf16_1
      cf.br ^bb54
    ^bb54:  // 2 preds: ^bb52, ^bb53
      %tup_360 = cute.add_offset(%tup_158, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_361, %e1_362, %e2_363, %e3_364 = cute.get_leaves(%tup_360) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_365 = cute.make_coord(%e1_362) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %387 = cute.get_scalars(%coord_365) : !cute.coord<"?">
      %388 = arith.cmpi slt, %387, %378 : i32
      cf.cond_br %388, ^bb55, ^bb59
    ^bb55:  // pred: ^bb54
      %coord_366 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,1,_,?)">
      %idx_367 = cute.crd2idx(%coord_366, %lay_83) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_368 = cute.add_offset(%ptr_78, %idx_367) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_369 = cute.add_offset(%ptr_84, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %389 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%390: i32):  // 2 preds: ^bb55, ^bb57
      %391 = arith.cmpi slt, %390, %389 : i32
      cf.cond_br %391, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      %coord_370 = cute.make_coord(%390) : (i32) -> !cute.coord<"(_,?)">
      %idx_371 = cute.crd2idx(%coord_370, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_372 = cute.add_offset(%ptr_368, %idx_371) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_373 = cute.crd2idx(%coord_370, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_374 = cute.add_offset(%ptr_369, %idx_373) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_375 = cute.crd2idx(%coord_370, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_376 = cute.add_offset(%iter_161, %idx_375) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %392 = builtin.unrealized_conversion_cast %ptr_376 : !cute.ptr<i8, rmem> to !llvm.ptr
      %393 = llvm.load %392 : !llvm.ptr -> i8
      %394 = llvm.trunc %393 : i8 to i1
      %iter_377 = cute.recast_iter(%ptr_372) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_378 = cute.recast_iter(%ptr_374) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_378 : !cute.ptr<i128, smem>, %iter_377 : !cute.ptr<i128, gmem>, %394 : i1) {cache_mode = <global>}
      %395 = arith.addi %390, %c1_i32 : i32
      cf.br ^bb56(%395 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb60
    ^bb59:  // pred: ^bb54
      %ptr_379 = cute.add_offset(%ptr_84, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_380 = cute.make_view(%ptr_379) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_380 : !memref_smem_bf16_1
      cf.br ^bb60
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %tup_381 = cute.add_offset(%tup_158, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_382, %e1_383, %e2_384, %e3_385 = cute.get_leaves(%tup_381) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_386 = cute.make_coord(%e1_383) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %396 = cute.get_scalars(%coord_386) : !cute.coord<"?">
      %397 = arith.cmpi slt, %396, %378 : i32
      cf.cond_br %397, ^bb61, ^bb65
    ^bb61:  // pred: ^bb60
      %coord_387 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,2,_,?)">
      %idx_388 = cute.crd2idx(%coord_387, %lay_83) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_389 = cute.add_offset(%ptr_78, %idx_388) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_390 = cute.add_offset(%ptr_84, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %398 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%399: i32):  // 2 preds: ^bb61, ^bb63
      %400 = arith.cmpi slt, %399, %398 : i32
      cf.cond_br %400, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %coord_391 = cute.make_coord(%399) : (i32) -> !cute.coord<"(_,?)">
      %idx_392 = cute.crd2idx(%coord_391, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_393 = cute.add_offset(%ptr_389, %idx_392) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_394 = cute.crd2idx(%coord_391, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_395 = cute.add_offset(%ptr_390, %idx_394) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_396 = cute.crd2idx(%coord_391, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_397 = cute.add_offset(%iter_161, %idx_396) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %401 = builtin.unrealized_conversion_cast %ptr_397 : !cute.ptr<i8, rmem> to !llvm.ptr
      %402 = llvm.load %401 : !llvm.ptr -> i8
      %403 = llvm.trunc %402 : i8 to i1
      %iter_398 = cute.recast_iter(%ptr_393) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_399 = cute.recast_iter(%ptr_395) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_399 : !cute.ptr<i128, smem>, %iter_398 : !cute.ptr<i128, gmem>, %403 : i1) {cache_mode = <global>}
      %404 = arith.addi %399, %c1_i32 : i32
      cf.br ^bb62(%404 : i32)
    ^bb64:  // pred: ^bb62
      cf.br ^bb66
    ^bb65:  // pred: ^bb60
      %ptr_400 = cute.add_offset(%ptr_84, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_401 = cute.make_view(%ptr_400) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_401 : !memref_smem_bf16_1
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %tup_402 = cute.add_offset(%tup_158, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_403, %e1_404, %e2_405, %e3_406 = cute.get_leaves(%tup_402) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_407 = cute.make_coord(%e1_404) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %405 = cute.get_scalars(%coord_407) : !cute.coord<"?">
      %406 = arith.cmpi slt, %405, %378 : i32
      cf.cond_br %406, ^bb67, ^bb71
    ^bb67:  // pred: ^bb66
      %coord_408 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,3,_,?)">
      %idx_409 = cute.crd2idx(%coord_408, %lay_83) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_410 = cute.add_offset(%ptr_78, %idx_409) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_411 = cute.add_offset(%ptr_84, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %407 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb68(%c0_i32 : i32)
    ^bb68(%408: i32):  // 2 preds: ^bb67, ^bb69
      %409 = arith.cmpi slt, %408, %407 : i32
      cf.cond_br %409, ^bb69, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb69:  // pred: ^bb68
      %coord_412 = cute.make_coord(%408) : (i32) -> !cute.coord<"(_,?)">
      %idx_413 = cute.crd2idx(%coord_412, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_414 = cute.add_offset(%ptr_410, %idx_413) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_415 = cute.crd2idx(%coord_412, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_416 = cute.add_offset(%ptr_411, %idx_415) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_417 = cute.crd2idx(%coord_412, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_418 = cute.add_offset(%iter_161, %idx_417) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %410 = builtin.unrealized_conversion_cast %ptr_418 : !cute.ptr<i8, rmem> to !llvm.ptr
      %411 = llvm.load %410 : !llvm.ptr -> i8
      %412 = llvm.trunc %411 : i8 to i1
      %iter_419 = cute.recast_iter(%ptr_414) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_420 = cute.recast_iter(%ptr_416) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_420 : !cute.ptr<i128, smem>, %iter_419 : !cute.ptr<i128, gmem>, %412 : i1) {cache_mode = <global>}
      %413 = arith.addi %408, %c1_i32 : i32
      cf.br ^bb68(%413 : i32)
    ^bb70:  // pred: ^bb68
      cf.br ^bb72
    ^bb71:  // pred: ^bb66
      %ptr_421 = cute.add_offset(%ptr_84, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_422 = cute.make_view(%ptr_421) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_422 : !memref_smem_bf16_1
      cf.br ^bb72
    ^bb72:  // 2 preds: ^bb70, ^bb71
      nvvm.cp.async.commit.group
      %rmem_423 = cute.memref.alloca() : !memref_rmem_f32_1
      %rmem_424 = cute.memref.alloca() : !memref_rmem_f32_1
      cute.memref.store_vec %cst_1, %rmem_423 : !memref_rmem_f32_1
      cute.memref.store_vec %cst_0, %rmem_424 : !memref_rmem_f32_1
      %rmem_425 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_426 = cute.get_iter(%rmem_425) : !memref_rmem_f32_2
      cute.memref.store_vec %cst, %rmem_425 : !memref_rmem_f32_2
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.cond_br %379, ^bb73, ^bb77
    ^bb73:  // pred: ^bb72
      %coord_427 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,0,_,?)">
      %idx_428 = cute.crd2idx(%coord_427, %lay_92) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_429 = cute.add_offset(%ptr_87, %idx_428) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %414 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb74(%c0_i32 : i32)
    ^bb74(%415: i32):  // 2 preds: ^bb73, ^bb75
      %416 = arith.cmpi slt, %415, %414 : i32
      cf.cond_br %416, ^bb75, ^bb76 {llvm.loop_annotation = #loop_annotation}
    ^bb75:  // pred: ^bb74
      %coord_430 = cute.make_coord(%415) : (i32) -> !cute.coord<"(_,?)">
      %idx_431 = cute.crd2idx(%coord_430, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_432 = cute.add_offset(%ptr_429, %idx_431) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_433 = cute.crd2idx(%coord_430, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_434 = cute.add_offset(%ptr_93, %idx_433) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_435 = cute.crd2idx(%coord_430, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_436 = cute.add_offset(%iter_161, %idx_435) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %417 = builtin.unrealized_conversion_cast %ptr_436 : !cute.ptr<i8, rmem> to !llvm.ptr
      %418 = llvm.load %417 : !llvm.ptr -> i8
      %419 = llvm.trunc %418 : i8 to i1
      %iter_437 = cute.recast_iter(%ptr_432) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_438 = cute.recast_iter(%ptr_434) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_438 : !cute.ptr<i128, smem>, %iter_437 : !cute.ptr<i128, gmem>, %419 : i1) {cache_mode = <global>}
      %420 = arith.addi %415, %c1_i32 : i32
      cf.br ^bb74(%420 : i32)
    ^bb76:  // pred: ^bb74
      cf.br ^bb78
    ^bb77:  // pred: ^bb72
      %view_439 = cute.make_view(%ptr_93) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_439 : !memref_smem_bf16_1
      cf.br ^bb78
    ^bb78:  // 2 preds: ^bb76, ^bb77
      cf.cond_br %388, ^bb79, ^bb83
    ^bb79:  // pred: ^bb78
      %coord_440 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,1,_,?)">
      %idx_441 = cute.crd2idx(%coord_440, %lay_92) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_442 = cute.add_offset(%ptr_87, %idx_441) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_443 = cute.add_offset(%ptr_93, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %421 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%422: i32):  // 2 preds: ^bb79, ^bb81
      %423 = arith.cmpi slt, %422, %421 : i32
      cf.cond_br %423, ^bb81, ^bb82 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      %coord_444 = cute.make_coord(%422) : (i32) -> !cute.coord<"(_,?)">
      %idx_445 = cute.crd2idx(%coord_444, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_446 = cute.add_offset(%ptr_442, %idx_445) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_447 = cute.crd2idx(%coord_444, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_448 = cute.add_offset(%ptr_443, %idx_447) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_449 = cute.crd2idx(%coord_444, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_450 = cute.add_offset(%iter_161, %idx_449) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %424 = builtin.unrealized_conversion_cast %ptr_450 : !cute.ptr<i8, rmem> to !llvm.ptr
      %425 = llvm.load %424 : !llvm.ptr -> i8
      %426 = llvm.trunc %425 : i8 to i1
      %iter_451 = cute.recast_iter(%ptr_446) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_452 = cute.recast_iter(%ptr_448) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_452 : !cute.ptr<i128, smem>, %iter_451 : !cute.ptr<i128, gmem>, %426 : i1) {cache_mode = <global>}
      %427 = arith.addi %422, %c1_i32 : i32
      cf.br ^bb80(%427 : i32)
    ^bb82:  // pred: ^bb80
      cf.br ^bb84
    ^bb83:  // pred: ^bb78
      %ptr_453 = cute.add_offset(%ptr_93, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_454 = cute.make_view(%ptr_453) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_454 : !memref_smem_bf16_1
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      cf.cond_br %397, ^bb85, ^bb89
    ^bb85:  // pred: ^bb84
      %coord_455 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,2,_,?)">
      %idx_456 = cute.crd2idx(%coord_455, %lay_92) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_457 = cute.add_offset(%ptr_87, %idx_456) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_458 = cute.add_offset(%ptr_93, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %428 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb86(%c0_i32 : i32)
    ^bb86(%429: i32):  // 2 preds: ^bb85, ^bb87
      %430 = arith.cmpi slt, %429, %428 : i32
      cf.cond_br %430, ^bb87, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb87:  // pred: ^bb86
      %coord_459 = cute.make_coord(%429) : (i32) -> !cute.coord<"(_,?)">
      %idx_460 = cute.crd2idx(%coord_459, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_461 = cute.add_offset(%ptr_457, %idx_460) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_462 = cute.crd2idx(%coord_459, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_463 = cute.add_offset(%ptr_458, %idx_462) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_464 = cute.crd2idx(%coord_459, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_465 = cute.add_offset(%iter_161, %idx_464) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %431 = builtin.unrealized_conversion_cast %ptr_465 : !cute.ptr<i8, rmem> to !llvm.ptr
      %432 = llvm.load %431 : !llvm.ptr -> i8
      %433 = llvm.trunc %432 : i8 to i1
      %iter_466 = cute.recast_iter(%ptr_461) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_467 = cute.recast_iter(%ptr_463) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_467 : !cute.ptr<i128, smem>, %iter_466 : !cute.ptr<i128, gmem>, %433 : i1) {cache_mode = <global>}
      %434 = arith.addi %429, %c1_i32 : i32
      cf.br ^bb86(%434 : i32)
    ^bb88:  // pred: ^bb86
      cf.br ^bb90
    ^bb89:  // pred: ^bb84
      %ptr_468 = cute.add_offset(%ptr_93, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_469 = cute.make_view(%ptr_468) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_469 : !memref_smem_bf16_1
      cf.br ^bb90
    ^bb90:  // 2 preds: ^bb88, ^bb89
      cf.cond_br %406, ^bb91, ^bb95
    ^bb91:  // pred: ^bb90
      %coord_470 = cute.make_coord(%190) : (i32) -> !cute.coord<"(_,3,_,?)">
      %idx_471 = cute.crd2idx(%coord_470, %lay_92) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_472 = cute.add_offset(%ptr_87, %idx_471) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_473 = cute.add_offset(%ptr_93, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %435 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb92(%c0_i32 : i32)
    ^bb92(%436: i32):  // 2 preds: ^bb91, ^bb93
      %437 = arith.cmpi slt, %436, %435 : i32
      cf.cond_br %437, ^bb93, ^bb94 {llvm.loop_annotation = #loop_annotation}
    ^bb93:  // pred: ^bb92
      %coord_474 = cute.make_coord(%436) : (i32) -> !cute.coord<"(_,?)">
      %idx_475 = cute.crd2idx(%coord_474, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_476 = cute.add_offset(%ptr_472, %idx_475) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_477 = cute.crd2idx(%coord_474, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_478 = cute.add_offset(%ptr_473, %idx_477) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_479 = cute.crd2idx(%coord_474, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_480 = cute.add_offset(%iter_161, %idx_479) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %438 = builtin.unrealized_conversion_cast %ptr_480 : !cute.ptr<i8, rmem> to !llvm.ptr
      %439 = llvm.load %438 : !llvm.ptr -> i8
      %440 = llvm.trunc %439 : i8 to i1
      %iter_481 = cute.recast_iter(%ptr_476) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_482 = cute.recast_iter(%ptr_478) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_482 : !cute.ptr<i128, smem>, %iter_481 : !cute.ptr<i128, gmem>, %440 : i1) {cache_mode = <global>}
      %441 = arith.addi %436, %c1_i32 : i32
      cf.br ^bb92(%441 : i32)
    ^bb94:  // pred: ^bb92
      cf.br ^bb96
    ^bb95:  // pred: ^bb90
      %ptr_483 = cute.add_offset(%ptr_93, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_484 = cute.make_view(%ptr_483) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_484 : !memref_smem_bf16_1
      cf.br ^bb96
    ^bb96:  // 2 preds: ^bb94, ^bb95
      nvvm.cp.async.commit.group
      %442 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb97(%c0_i32 : i32)
    ^bb97(%443: i32):  // 2 preds: ^bb96, ^bb98
      %444 = arith.cmpi slt, %443, %442 : i32
      cf.cond_br %444, ^bb98, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb98:  // pred: ^bb97
      %coord_485 = cute.make_coord(%443) : (i32) -> !cute.coord<"(_,?)">
      %idx_486 = cute.crd2idx(%coord_485, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_487 = cute.add_offset(%ptr_101, %idx_486) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_488 = cute.crd2idx(%coord_485, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_489 = cute.add_offset(%iter_106, %idx_488) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %445 = cute_nvgpu.arch.copy.ldsm %ptr_487{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %446 = vector.extractelement %445[%130 : i32] : vector<4xi32>
      %447 = builtin.unrealized_conversion_cast %ptr_489 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %446, %447 : i32, !llvm.ptr
      %448 = vector.extractelement %445[%129 : i32] : vector<4xi32>
      %ptr_490 = cute.add_offset(%ptr_489, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %449 = builtin.unrealized_conversion_cast %ptr_490 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %448, %449 : i32, !llvm.ptr
      %450 = vector.extractelement %445[%128 : i32] : vector<4xi32>
      %ptr_491 = cute.add_offset(%ptr_489, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %451 = builtin.unrealized_conversion_cast %ptr_491 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %450, %451 : i32, !llvm.ptr
      %452 = vector.extractelement %445[%126 : i32] : vector<4xi32>
      %ptr_492 = cute.add_offset(%ptr_489, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %453 = builtin.unrealized_conversion_cast %ptr_492 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %452, %453 : i32, !llvm.ptr
      %454 = arith.addi %443, %c1_i32 : i32
      cf.br ^bb97(%454 : i32)
    ^bb99:  // pred: ^bb97
      %455 = cute.get_scalars(%127) : !cute.int_tuple<"4">
      cf.br ^bb100(%c0_i32 : i32)
    ^bb100(%456: i32):  // 2 preds: ^bb99, ^bb101
      %457 = arith.cmpi slt, %456, %455 : i32
      cf.cond_br %457, ^bb101, ^bb102 {llvm.loop_annotation = #loop_annotation}
    ^bb101:  // pred: ^bb100
      %coord_493 = cute.make_coord(%456) : (i32) -> !cute.coord<"(_,?)">
      %idx_494 = cute.crd2idx(%coord_493, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_495 = cute.add_offset(%ptr_109, %idx_494) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_496 = cute.crd2idx(%coord_493, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_497 = cute.add_offset(%iter_114, %idx_496) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %458 = cute_nvgpu.arch.copy.ldsm %ptr_495{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %459 = vector.extractelement %458[%130 : i32] : vector<4xi32>
      %460 = builtin.unrealized_conversion_cast %ptr_497 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %459, %460 : i32, !llvm.ptr
      %461 = vector.extractelement %458[%129 : i32] : vector<4xi32>
      %ptr_498 = cute.add_offset(%ptr_497, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %462 = builtin.unrealized_conversion_cast %ptr_498 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %461, %462 : i32, !llvm.ptr
      %463 = vector.extractelement %458[%128 : i32] : vector<4xi32>
      %ptr_499 = cute.add_offset(%ptr_497, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %464 = builtin.unrealized_conversion_cast %ptr_499 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %463, %464 : i32, !llvm.ptr
      %465 = vector.extractelement %458[%126 : i32] : vector<4xi32>
      %ptr_500 = cute.add_offset(%ptr_497, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %466 = builtin.unrealized_conversion_cast %ptr_500 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %465, %466 : i32, !llvm.ptr
      %467 = arith.addi %456, %c1_i32 : i32
      cf.br ^bb100(%467 : i32)
    ^bb102:  // pred: ^bb100
      %idx_501 = cute.crd2idx(%122, %lay_105) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_502 = cute.add_offset(%ptr_101, %idx_501) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_503 = cute.add_offset(%iter_106, %121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%468: i32):  // 2 preds: ^bb102, ^bb104
      %469 = arith.cmpi slt, %468, %442 : i32
      cf.cond_br %469, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation}
    ^bb104:  // pred: ^bb103
      %coord_504 = cute.make_coord(%468) : (i32) -> !cute.coord<"(_,?)">
      %idx_505 = cute.crd2idx(%coord_504, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_506 = cute.add_offset(%ptr_502, %idx_505) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_507 = cute.crd2idx(%coord_504, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_508 = cute.add_offset(%ptr_503, %idx_507) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %470 = cute_nvgpu.arch.copy.ldsm %ptr_506{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %471 = vector.extractelement %470[%130 : i32] : vector<4xi32>
      %472 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %471, %472 : i32, !llvm.ptr
      %473 = vector.extractelement %470[%129 : i32] : vector<4xi32>
      %ptr_509 = cute.add_offset(%ptr_508, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %474 = builtin.unrealized_conversion_cast %ptr_509 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %473, %474 : i32, !llvm.ptr
      %475 = vector.extractelement %470[%128 : i32] : vector<4xi32>
      %ptr_510 = cute.add_offset(%ptr_508, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %476 = builtin.unrealized_conversion_cast %ptr_510 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %475, %476 : i32, !llvm.ptr
      %477 = vector.extractelement %470[%126 : i32] : vector<4xi32>
      %ptr_511 = cute.add_offset(%ptr_508, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %478 = builtin.unrealized_conversion_cast %ptr_511 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %477, %478 : i32, !llvm.ptr
      %479 = arith.addi %468, %c1_i32 : i32
      cf.br ^bb103(%479 : i32)
    ^bb105:  // pred: ^bb103
      %idx_512 = cute.crd2idx(%122, %lay_113) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_513 = cute.add_offset(%ptr_109, %idx_512) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_514 = cute.add_offset(%iter_114, %120) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb106(%c0_i32 : i32)
    ^bb106(%480: i32):  // 2 preds: ^bb105, ^bb107
      %481 = arith.cmpi slt, %480, %455 : i32
      cf.cond_br %481, ^bb107, ^bb108 {llvm.loop_annotation = #loop_annotation}
    ^bb107:  // pred: ^bb106
      %coord_515 = cute.make_coord(%480) : (i32) -> !cute.coord<"(_,?)">
      %idx_516 = cute.crd2idx(%coord_515, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_517 = cute.add_offset(%ptr_513, %idx_516) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_518 = cute.crd2idx(%coord_515, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_519 = cute.add_offset(%ptr_514, %idx_518) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %482 = cute_nvgpu.arch.copy.ldsm %ptr_517{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %483 = vector.extractelement %482[%130 : i32] : vector<4xi32>
      %484 = builtin.unrealized_conversion_cast %ptr_519 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %483, %484 : i32, !llvm.ptr
      %485 = vector.extractelement %482[%129 : i32] : vector<4xi32>
      %ptr_520 = cute.add_offset(%ptr_519, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %486 = builtin.unrealized_conversion_cast %ptr_520 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %485, %486 : i32, !llvm.ptr
      %487 = vector.extractelement %482[%128 : i32] : vector<4xi32>
      %ptr_521 = cute.add_offset(%ptr_519, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %488 = builtin.unrealized_conversion_cast %ptr_521 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %487, %488 : i32, !llvm.ptr
      %489 = vector.extractelement %482[%126 : i32] : vector<4xi32>
      %ptr_522 = cute.add_offset(%ptr_519, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %490 = builtin.unrealized_conversion_cast %ptr_522 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %489, %490 : i32, !llvm.ptr
      %491 = arith.addi %480, %c1_i32 : i32
      cf.br ^bb106(%491 : i32)
    ^bb108:  // pred: ^bb106
      %492 = cute.get_scalars(%117) : !cute.int_tuple<"1">
      %493 = cute.get_scalars(%132) : !cute.int_tuple<"8">
      cf.br ^bb109(%c0_i32 : i32)
    ^bb109(%494: i32):  // 2 preds: ^bb108, ^bb116
      %495 = arith.cmpi slt, %494, %492 : i32
      cf.cond_br %495, ^bb110, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb110:  // pred: ^bb109
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%496: i32):  // 2 preds: ^bb110, ^bb115
      %497 = arith.cmpi slt, %496, %442 : i32
      cf.cond_br %497, ^bb112, ^bb116 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_523 = cute.make_coord(%496, %494) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_524 = cute.crd2idx(%coord_523, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_525 = cute.add_offset(%iter_106, %idx_524) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %498 = builtin.unrealized_conversion_cast %ptr_525 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %499 = llvm.getelementptr %498[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %500 = llvm.getelementptr %498[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %501 = llvm.getelementptr %498[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%502: i32):  // 2 preds: ^bb112, ^bb114
      %503 = arith.cmpi slt, %502, %493 : i32
      cf.cond_br %503, ^bb114, ^bb115 {llvm.loop_annotation = #loop_annotation}
    ^bb114:  // pred: ^bb113
      %coord_526 = cute.make_coord(%502, %494) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_527 = cute.make_coord(%496, %502) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_528 = cute.crd2idx(%coord_526, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_529 = cute.add_offset(%iter_114, %idx_528) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_530 = cute.crd2idx(%coord_527, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_531 = cute.add_offset(%iter_426, %idx_530) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %504 = llvm.load %498 : !llvm.ptr -> i32
      %505 = llvm.load %499 : !llvm.ptr -> i32
      %506 = llvm.load %500 : !llvm.ptr -> i32
      %507 = llvm.load %501 : !llvm.ptr -> i32
      %508 = builtin.unrealized_conversion_cast %ptr_529 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %509 = llvm.load %508 : !llvm.ptr -> i32
      %510 = llvm.getelementptr %508[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %511 = llvm.load %510 : !llvm.ptr -> i32
      %512 = builtin.unrealized_conversion_cast %ptr_531 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %513 = llvm.load %512 : !llvm.ptr -> f32
      %514 = llvm.getelementptr %512[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %515 = llvm.load %514 : !llvm.ptr -> f32
      %516 = llvm.getelementptr %512[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %517 = llvm.load %516 : !llvm.ptr -> f32
      %518 = llvm.getelementptr %512[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %519 = llvm.load %518 : !llvm.ptr -> f32
      %520:4 = cute_nvgpu.arch.mma.SM80 A[%504, %505, %506, %507]  B[%509, %511]  C[%513, %515, %517, %519] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %520#0, %512 : f32, !llvm.ptr
      llvm.store %520#1, %514 : f32, !llvm.ptr
      llvm.store %520#2, %516 : f32, !llvm.ptr
      llvm.store %520#3, %518 : f32, !llvm.ptr
      %521 = arith.addi %502, %c1_i32 : i32
      cf.br ^bb113(%521 : i32)
    ^bb115:  // pred: ^bb113
      %522 = arith.addi %496, %c1_i32 : i32
      cf.br ^bb111(%522 : i32)
    ^bb116:  // pred: ^bb111
      %523 = arith.addi %494, %c1_i32 : i32
      cf.br ^bb109(%523 : i32)
    ^bb117:  // pred: ^bb109
      %idx_532 = cute.crd2idx(%116, %lay_105) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_533 = cute.add_offset(%ptr_101, %idx_532) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_534 = cute.add_offset(%iter_106, %120) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%524: i32):  // 2 preds: ^bb117, ^bb119
      %525 = arith.cmpi slt, %524, %442 : i32
      cf.cond_br %525, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_535 = cute.make_coord(%524) : (i32) -> !cute.coord<"(_,?)">
      %idx_536 = cute.crd2idx(%coord_535, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_537 = cute.add_offset(%ptr_533, %idx_536) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_538 = cute.crd2idx(%coord_535, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_539 = cute.add_offset(%ptr_534, %idx_538) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %526 = cute_nvgpu.arch.copy.ldsm %ptr_537{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %527 = vector.extractelement %526[%130 : i32] : vector<4xi32>
      %528 = builtin.unrealized_conversion_cast %ptr_539 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %527, %528 : i32, !llvm.ptr
      %529 = vector.extractelement %526[%129 : i32] : vector<4xi32>
      %ptr_540 = cute.add_offset(%ptr_539, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %530 = builtin.unrealized_conversion_cast %ptr_540 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %529, %530 : i32, !llvm.ptr
      %531 = vector.extractelement %526[%128 : i32] : vector<4xi32>
      %ptr_541 = cute.add_offset(%ptr_539, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %532 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %531, %532 : i32, !llvm.ptr
      %533 = vector.extractelement %526[%126 : i32] : vector<4xi32>
      %ptr_542 = cute.add_offset(%ptr_539, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %534 = builtin.unrealized_conversion_cast %ptr_542 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %533, %534 : i32, !llvm.ptr
      %535 = arith.addi %524, %c1_i32 : i32
      cf.br ^bb118(%535 : i32)
    ^bb120:  // pred: ^bb118
      %idx_543 = cute.crd2idx(%116, %lay_113) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_544 = cute.add_offset(%ptr_109, %idx_543) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_545 = cute.add_offset(%iter_114, %115) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb121(%c0_i32 : i32)
    ^bb121(%536: i32):  // 2 preds: ^bb120, ^bb122
      %537 = arith.cmpi slt, %536, %455 : i32
      cf.cond_br %537, ^bb122, ^bb123 {llvm.loop_annotation = #loop_annotation}
    ^bb122:  // pred: ^bb121
      %coord_546 = cute.make_coord(%536) : (i32) -> !cute.coord<"(_,?)">
      %idx_547 = cute.crd2idx(%coord_546, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_548 = cute.add_offset(%ptr_544, %idx_547) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_549 = cute.crd2idx(%coord_546, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_550 = cute.add_offset(%ptr_545, %idx_549) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %538 = cute_nvgpu.arch.copy.ldsm %ptr_548{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %539 = vector.extractelement %538[%130 : i32] : vector<4xi32>
      %540 = builtin.unrealized_conversion_cast %ptr_550 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %539, %540 : i32, !llvm.ptr
      %541 = vector.extractelement %538[%129 : i32] : vector<4xi32>
      %ptr_551 = cute.add_offset(%ptr_550, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %542 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %541, %542 : i32, !llvm.ptr
      %543 = vector.extractelement %538[%128 : i32] : vector<4xi32>
      %ptr_552 = cute.add_offset(%ptr_550, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %544 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %543, %544 : i32, !llvm.ptr
      %545 = vector.extractelement %538[%126 : i32] : vector<4xi32>
      %ptr_553 = cute.add_offset(%ptr_550, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %546 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %545, %546 : i32, !llvm.ptr
      %547 = arith.addi %536, %c1_i32 : i32
      cf.br ^bb121(%547 : i32)
    ^bb123:  // pred: ^bb121
      cf.br ^bb124(%c0_i32 : i32)
    ^bb124(%548: i32):  // 2 preds: ^bb123, ^bb131
      %549 = arith.cmpi slt, %548, %492 : i32
      cf.cond_br %549, ^bb125, ^bb132 {llvm.loop_annotation = #loop_annotation}
    ^bb125:  // pred: ^bb124
      cf.br ^bb126(%c0_i32 : i32)
    ^bb126(%550: i32):  // 2 preds: ^bb125, ^bb130
      %551 = arith.cmpi slt, %550, %442 : i32
      cf.cond_br %551, ^bb127, ^bb131 {llvm.loop_annotation = #loop_annotation}
    ^bb127:  // pred: ^bb126
      %coord_554 = cute.make_coord(%550, %548) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_555 = cute.crd2idx(%coord_554, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_556 = cute.add_offset(%ptr_503, %idx_555) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %552 = builtin.unrealized_conversion_cast %ptr_556 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %553 = llvm.getelementptr %552[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %554 = llvm.getelementptr %552[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %555 = llvm.getelementptr %552[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb128(%c0_i32 : i32)
    ^bb128(%556: i32):  // 2 preds: ^bb127, ^bb129
      %557 = arith.cmpi slt, %556, %493 : i32
      cf.cond_br %557, ^bb129, ^bb130 {llvm.loop_annotation = #loop_annotation}
    ^bb129:  // pred: ^bb128
      %coord_557 = cute.make_coord(%556, %548) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_558 = cute.make_coord(%550, %556) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_559 = cute.crd2idx(%coord_557, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_560 = cute.add_offset(%ptr_514, %idx_559) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_561 = cute.crd2idx(%coord_558, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_562 = cute.add_offset(%iter_426, %idx_561) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %558 = llvm.load %552 : !llvm.ptr -> i32
      %559 = llvm.load %553 : !llvm.ptr -> i32
      %560 = llvm.load %554 : !llvm.ptr -> i32
      %561 = llvm.load %555 : !llvm.ptr -> i32
      %562 = builtin.unrealized_conversion_cast %ptr_560 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %563 = llvm.load %562 : !llvm.ptr -> i32
      %564 = llvm.getelementptr %562[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %565 = llvm.load %564 : !llvm.ptr -> i32
      %566 = builtin.unrealized_conversion_cast %ptr_562 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %567 = llvm.load %566 : !llvm.ptr -> f32
      %568 = llvm.getelementptr %566[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %569 = llvm.load %568 : !llvm.ptr -> f32
      %570 = llvm.getelementptr %566[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %571 = llvm.load %570 : !llvm.ptr -> f32
      %572 = llvm.getelementptr %566[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %573 = llvm.load %572 : !llvm.ptr -> f32
      %574:4 = cute_nvgpu.arch.mma.SM80 A[%558, %559, %560, %561]  B[%563, %565]  C[%567, %569, %571, %573] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %574#0, %566 : f32, !llvm.ptr
      llvm.store %574#1, %568 : f32, !llvm.ptr
      llvm.store %574#2, %570 : f32, !llvm.ptr
      llvm.store %574#3, %572 : f32, !llvm.ptr
      %575 = arith.addi %556, %c1_i32 : i32
      cf.br ^bb128(%575 : i32)
    ^bb130:  // pred: ^bb128
      %576 = arith.addi %550, %c1_i32 : i32
      cf.br ^bb126(%576 : i32)
    ^bb131:  // pred: ^bb126
      %577 = arith.addi %548, %c1_i32 : i32
      cf.br ^bb124(%577 : i32)
    ^bb132:  // pred: ^bb124
      %idx_563 = cute.crd2idx(%114, %lay_105) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_564 = cute.add_offset(%ptr_101, %idx_563) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_565 = cute.add_offset(%iter_106, %113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%578: i32):  // 2 preds: ^bb132, ^bb134
      %579 = arith.cmpi slt, %578, %442 : i32
      cf.cond_br %579, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      %coord_566 = cute.make_coord(%578) : (i32) -> !cute.coord<"(_,?)">
      %idx_567 = cute.crd2idx(%coord_566, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_568 = cute.add_offset(%ptr_564, %idx_567) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_569 = cute.crd2idx(%coord_566, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_570 = cute.add_offset(%ptr_565, %idx_569) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %580 = cute_nvgpu.arch.copy.ldsm %ptr_568{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %581 = vector.extractelement %580[%130 : i32] : vector<4xi32>
      %582 = builtin.unrealized_conversion_cast %ptr_570 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %581, %582 : i32, !llvm.ptr
      %583 = vector.extractelement %580[%129 : i32] : vector<4xi32>
      %ptr_571 = cute.add_offset(%ptr_570, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %584 = builtin.unrealized_conversion_cast %ptr_571 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %583, %584 : i32, !llvm.ptr
      %585 = vector.extractelement %580[%128 : i32] : vector<4xi32>
      %ptr_572 = cute.add_offset(%ptr_570, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %586 = builtin.unrealized_conversion_cast %ptr_572 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %585, %586 : i32, !llvm.ptr
      %587 = vector.extractelement %580[%126 : i32] : vector<4xi32>
      %ptr_573 = cute.add_offset(%ptr_570, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %588 = builtin.unrealized_conversion_cast %ptr_573 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %587, %588 : i32, !llvm.ptr
      %589 = arith.addi %578, %c1_i32 : i32
      cf.br ^bb133(%589 : i32)
    ^bb135:  // pred: ^bb133
      %idx_574 = cute.crd2idx(%114, %lay_113) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_575 = cute.add_offset(%ptr_109, %idx_574) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_576 = cute.add_offset(%iter_114, %112) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb136(%c0_i32 : i32)
    ^bb136(%590: i32):  // 2 preds: ^bb135, ^bb137
      %591 = arith.cmpi slt, %590, %455 : i32
      cf.cond_br %591, ^bb137, ^bb138 {llvm.loop_annotation = #loop_annotation}
    ^bb137:  // pred: ^bb136
      %coord_577 = cute.make_coord(%590) : (i32) -> !cute.coord<"(_,?)">
      %idx_578 = cute.crd2idx(%coord_577, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_579 = cute.add_offset(%ptr_575, %idx_578) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_580 = cute.crd2idx(%coord_577, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_581 = cute.add_offset(%ptr_576, %idx_580) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %592 = cute_nvgpu.arch.copy.ldsm %ptr_579{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %593 = vector.extractelement %592[%130 : i32] : vector<4xi32>
      %594 = builtin.unrealized_conversion_cast %ptr_581 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %593, %594 : i32, !llvm.ptr
      %595 = vector.extractelement %592[%129 : i32] : vector<4xi32>
      %ptr_582 = cute.add_offset(%ptr_581, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %596 = builtin.unrealized_conversion_cast %ptr_582 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %595, %596 : i32, !llvm.ptr
      %597 = vector.extractelement %592[%128 : i32] : vector<4xi32>
      %ptr_583 = cute.add_offset(%ptr_581, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %598 = builtin.unrealized_conversion_cast %ptr_583 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %597, %598 : i32, !llvm.ptr
      %599 = vector.extractelement %592[%126 : i32] : vector<4xi32>
      %ptr_584 = cute.add_offset(%ptr_581, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %600 = builtin.unrealized_conversion_cast %ptr_584 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %599, %600 : i32, !llvm.ptr
      %601 = arith.addi %590, %c1_i32 : i32
      cf.br ^bb136(%601 : i32)
    ^bb138:  // pred: ^bb136
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%602: i32):  // 2 preds: ^bb138, ^bb146
      %603 = arith.cmpi slt, %602, %492 : i32
      cf.cond_br %603, ^bb140, ^bb147 {llvm.loop_annotation = #loop_annotation}
    ^bb140:  // pred: ^bb139
      cf.br ^bb141(%c0_i32 : i32)
    ^bb141(%604: i32):  // 2 preds: ^bb140, ^bb145
      %605 = arith.cmpi slt, %604, %442 : i32
      cf.cond_br %605, ^bb142, ^bb146 {llvm.loop_annotation = #loop_annotation}
    ^bb142:  // pred: ^bb141
      %coord_585 = cute.make_coord(%604, %602) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_586 = cute.crd2idx(%coord_585, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_587 = cute.add_offset(%ptr_534, %idx_586) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %606 = builtin.unrealized_conversion_cast %ptr_587 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %607 = llvm.getelementptr %606[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %608 = llvm.getelementptr %606[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %609 = llvm.getelementptr %606[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb143(%c0_i32 : i32)
    ^bb143(%610: i32):  // 2 preds: ^bb142, ^bb144
      %611 = arith.cmpi slt, %610, %493 : i32
      cf.cond_br %611, ^bb144, ^bb145 {llvm.loop_annotation = #loop_annotation}
    ^bb144:  // pred: ^bb143
      %coord_588 = cute.make_coord(%610, %602) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_589 = cute.make_coord(%604, %610) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_590 = cute.crd2idx(%coord_588, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_591 = cute.add_offset(%ptr_545, %idx_590) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_592 = cute.crd2idx(%coord_589, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_593 = cute.add_offset(%iter_426, %idx_592) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %612 = llvm.load %606 : !llvm.ptr -> i32
      %613 = llvm.load %607 : !llvm.ptr -> i32
      %614 = llvm.load %608 : !llvm.ptr -> i32
      %615 = llvm.load %609 : !llvm.ptr -> i32
      %616 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %617 = llvm.load %616 : !llvm.ptr -> i32
      %618 = llvm.getelementptr %616[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %619 = llvm.load %618 : !llvm.ptr -> i32
      %620 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %621 = llvm.load %620 : !llvm.ptr -> f32
      %622 = llvm.getelementptr %620[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %623 = llvm.load %622 : !llvm.ptr -> f32
      %624 = llvm.getelementptr %620[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %625 = llvm.load %624 : !llvm.ptr -> f32
      %626 = llvm.getelementptr %620[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %627 = llvm.load %626 : !llvm.ptr -> f32
      %628:4 = cute_nvgpu.arch.mma.SM80 A[%612, %613, %614, %615]  B[%617, %619]  C[%621, %623, %625, %627] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %628#0, %620 : f32, !llvm.ptr
      llvm.store %628#1, %622 : f32, !llvm.ptr
      llvm.store %628#2, %624 : f32, !llvm.ptr
      llvm.store %628#3, %626 : f32, !llvm.ptr
      %629 = arith.addi %610, %c1_i32 : i32
      cf.br ^bb143(%629 : i32)
    ^bb145:  // pred: ^bb143
      %630 = arith.addi %604, %c1_i32 : i32
      cf.br ^bb141(%630 : i32)
    ^bb146:  // pred: ^bb141
      %631 = arith.addi %602, %c1_i32 : i32
      cf.br ^bb139(%631 : i32)
    ^bb147:  // pred: ^bb139
      %ptr_594 = cute.add_offset(%ptr_101, %111) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_595 = cute.add_offset(%iter_106, %110) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%632: i32):  // 2 preds: ^bb147, ^bb149
      %633 = arith.cmpi slt, %632, %442 : i32
      cf.cond_br %633, ^bb149, ^bb150 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      %coord_596 = cute.make_coord(%632) : (i32) -> !cute.coord<"(_,?)">
      %idx_597 = cute.crd2idx(%coord_596, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_598 = cute.add_offset(%ptr_594, %idx_597) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_599 = cute.crd2idx(%coord_596, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_600 = cute.add_offset(%ptr_595, %idx_599) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %634 = cute_nvgpu.arch.copy.ldsm %ptr_598{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %635 = vector.extractelement %634[%130 : i32] : vector<4xi32>
      %636 = builtin.unrealized_conversion_cast %ptr_600 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %635, %636 : i32, !llvm.ptr
      %637 = vector.extractelement %634[%129 : i32] : vector<4xi32>
      %ptr_601 = cute.add_offset(%ptr_600, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %638 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %637, %638 : i32, !llvm.ptr
      %639 = vector.extractelement %634[%128 : i32] : vector<4xi32>
      %ptr_602 = cute.add_offset(%ptr_600, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %640 = builtin.unrealized_conversion_cast %ptr_602 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %639, %640 : i32, !llvm.ptr
      %641 = vector.extractelement %634[%126 : i32] : vector<4xi32>
      %ptr_603 = cute.add_offset(%ptr_600, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %642 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %641, %642 : i32, !llvm.ptr
      %643 = arith.addi %632, %c1_i32 : i32
      cf.br ^bb148(%643 : i32)
    ^bb150:  // pred: ^bb148
      %ptr_604 = cute.add_offset(%ptr_109, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_605 = cute.add_offset(%iter_114, %121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb151(%c0_i32 : i32)
    ^bb151(%644: i32):  // 2 preds: ^bb150, ^bb152
      %645 = arith.cmpi slt, %644, %455 : i32
      cf.cond_br %645, ^bb152, ^bb153 {llvm.loop_annotation = #loop_annotation}
    ^bb152:  // pred: ^bb151
      %coord_606 = cute.make_coord(%644) : (i32) -> !cute.coord<"(_,?)">
      %idx_607 = cute.crd2idx(%coord_606, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_608 = cute.add_offset(%ptr_604, %idx_607) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_609 = cute.crd2idx(%coord_606, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_610 = cute.add_offset(%ptr_605, %idx_609) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %646 = cute_nvgpu.arch.copy.ldsm %ptr_608{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %647 = vector.extractelement %646[%130 : i32] : vector<4xi32>
      %648 = builtin.unrealized_conversion_cast %ptr_610 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %647, %648 : i32, !llvm.ptr
      %649 = vector.extractelement %646[%129 : i32] : vector<4xi32>
      %ptr_611 = cute.add_offset(%ptr_610, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %650 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %649, %650 : i32, !llvm.ptr
      %651 = vector.extractelement %646[%128 : i32] : vector<4xi32>
      %ptr_612 = cute.add_offset(%ptr_610, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %652 = builtin.unrealized_conversion_cast %ptr_612 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %651, %652 : i32, !llvm.ptr
      %653 = vector.extractelement %646[%126 : i32] : vector<4xi32>
      %ptr_613 = cute.add_offset(%ptr_610, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %654 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %653, %654 : i32, !llvm.ptr
      %655 = arith.addi %644, %c1_i32 : i32
      cf.br ^bb151(%655 : i32)
    ^bb153:  // pred: ^bb151
      cf.br ^bb154(%c0_i32 : i32)
    ^bb154(%656: i32):  // 2 preds: ^bb153, ^bb161
      %657 = arith.cmpi slt, %656, %492 : i32
      cf.cond_br %657, ^bb155, ^bb162 {llvm.loop_annotation = #loop_annotation}
    ^bb155:  // pred: ^bb154
      cf.br ^bb156(%c0_i32 : i32)
    ^bb156(%658: i32):  // 2 preds: ^bb155, ^bb160
      %659 = arith.cmpi slt, %658, %442 : i32
      cf.cond_br %659, ^bb157, ^bb161 {llvm.loop_annotation = #loop_annotation}
    ^bb157:  // pred: ^bb156
      %coord_614 = cute.make_coord(%658, %656) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_615 = cute.crd2idx(%coord_614, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_616 = cute.add_offset(%ptr_565, %idx_615) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %660 = builtin.unrealized_conversion_cast %ptr_616 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %661 = llvm.getelementptr %660[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %662 = llvm.getelementptr %660[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %663 = llvm.getelementptr %660[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb158(%c0_i32 : i32)
    ^bb158(%664: i32):  // 2 preds: ^bb157, ^bb159
      %665 = arith.cmpi slt, %664, %493 : i32
      cf.cond_br %665, ^bb159, ^bb160 {llvm.loop_annotation = #loop_annotation}
    ^bb159:  // pred: ^bb158
      %coord_617 = cute.make_coord(%664, %656) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_618 = cute.make_coord(%658, %664) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_619 = cute.crd2idx(%coord_617, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_620 = cute.add_offset(%ptr_576, %idx_619) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_621 = cute.crd2idx(%coord_618, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_622 = cute.add_offset(%iter_426, %idx_621) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %666 = llvm.load %660 : !llvm.ptr -> i32
      %667 = llvm.load %661 : !llvm.ptr -> i32
      %668 = llvm.load %662 : !llvm.ptr -> i32
      %669 = llvm.load %663 : !llvm.ptr -> i32
      %670 = builtin.unrealized_conversion_cast %ptr_620 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %671 = llvm.load %670 : !llvm.ptr -> i32
      %672 = llvm.getelementptr %670[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %673 = llvm.load %672 : !llvm.ptr -> i32
      %674 = builtin.unrealized_conversion_cast %ptr_622 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %675 = llvm.load %674 : !llvm.ptr -> f32
      %676 = llvm.getelementptr %674[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %677 = llvm.load %676 : !llvm.ptr -> f32
      %678 = llvm.getelementptr %674[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %679 = llvm.load %678 : !llvm.ptr -> f32
      %680 = llvm.getelementptr %674[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %681 = llvm.load %680 : !llvm.ptr -> f32
      %682:4 = cute_nvgpu.arch.mma.SM80 A[%666, %667, %668, %669]  B[%671, %673]  C[%675, %677, %679, %681] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %682#0, %674 : f32, !llvm.ptr
      llvm.store %682#1, %676 : f32, !llvm.ptr
      llvm.store %682#2, %678 : f32, !llvm.ptr
      llvm.store %682#3, %680 : f32, !llvm.ptr
      %683 = arith.addi %664, %c1_i32 : i32
      cf.br ^bb158(%683 : i32)
    ^bb160:  // pred: ^bb158
      %684 = arith.addi %658, %c1_i32 : i32
      cf.br ^bb156(%684 : i32)
    ^bb161:  // pred: ^bb156
      %685 = arith.addi %656, %c1_i32 : i32
      cf.br ^bb154(%685 : i32)
    ^bb162:  // pred: ^bb154
      %idx_623 = cute.crd2idx(%109, %lay_105) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_624 = cute.add_offset(%ptr_101, %idx_623) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_625 = cute.add_offset(%iter_106, %108) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb163(%c0_i32 : i32)
    ^bb163(%686: i32):  // 2 preds: ^bb162, ^bb164
      %687 = arith.cmpi slt, %686, %442 : i32
      cf.cond_br %687, ^bb164, ^bb165 {llvm.loop_annotation = #loop_annotation}
    ^bb164:  // pred: ^bb163
      %coord_626 = cute.make_coord(%686) : (i32) -> !cute.coord<"(_,?)">
      %idx_627 = cute.crd2idx(%coord_626, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_628 = cute.add_offset(%ptr_624, %idx_627) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_629 = cute.crd2idx(%coord_626, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_630 = cute.add_offset(%ptr_625, %idx_629) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %688 = cute_nvgpu.arch.copy.ldsm %ptr_628{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %689 = vector.extractelement %688[%130 : i32] : vector<4xi32>
      %690 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %689, %690 : i32, !llvm.ptr
      %691 = vector.extractelement %688[%129 : i32] : vector<4xi32>
      %ptr_631 = cute.add_offset(%ptr_630, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %692 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %691, %692 : i32, !llvm.ptr
      %693 = vector.extractelement %688[%128 : i32] : vector<4xi32>
      %ptr_632 = cute.add_offset(%ptr_630, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %694 = builtin.unrealized_conversion_cast %ptr_632 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %693, %694 : i32, !llvm.ptr
      %695 = vector.extractelement %688[%126 : i32] : vector<4xi32>
      %ptr_633 = cute.add_offset(%ptr_630, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %696 = builtin.unrealized_conversion_cast %ptr_633 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %695, %696 : i32, !llvm.ptr
      %697 = arith.addi %686, %c1_i32 : i32
      cf.br ^bb163(%697 : i32)
    ^bb165:  // pred: ^bb163
      %idx_634 = cute.crd2idx(%109, %lay_113) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_635 = cute.add_offset(%ptr_109, %idx_634) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_636 = cute.add_offset(%iter_114, %113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb166(%c0_i32 : i32)
    ^bb166(%698: i32):  // 2 preds: ^bb165, ^bb167
      %699 = arith.cmpi slt, %698, %455 : i32
      cf.cond_br %699, ^bb167, ^bb168 {llvm.loop_annotation = #loop_annotation}
    ^bb167:  // pred: ^bb166
      %coord_637 = cute.make_coord(%698) : (i32) -> !cute.coord<"(_,?)">
      %idx_638 = cute.crd2idx(%coord_637, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_639 = cute.add_offset(%ptr_635, %idx_638) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_640 = cute.crd2idx(%coord_637, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_641 = cute.add_offset(%ptr_636, %idx_640) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %700 = cute_nvgpu.arch.copy.ldsm %ptr_639{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %701 = vector.extractelement %700[%130 : i32] : vector<4xi32>
      %702 = builtin.unrealized_conversion_cast %ptr_641 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %701, %702 : i32, !llvm.ptr
      %703 = vector.extractelement %700[%129 : i32] : vector<4xi32>
      %ptr_642 = cute.add_offset(%ptr_641, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %704 = builtin.unrealized_conversion_cast %ptr_642 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %703, %704 : i32, !llvm.ptr
      %705 = vector.extractelement %700[%128 : i32] : vector<4xi32>
      %ptr_643 = cute.add_offset(%ptr_641, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %706 = builtin.unrealized_conversion_cast %ptr_643 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %705, %706 : i32, !llvm.ptr
      %707 = vector.extractelement %700[%126 : i32] : vector<4xi32>
      %ptr_644 = cute.add_offset(%ptr_641, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %708 = builtin.unrealized_conversion_cast %ptr_644 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %707, %708 : i32, !llvm.ptr
      %709 = arith.addi %698, %c1_i32 : i32
      cf.br ^bb166(%709 : i32)
    ^bb168:  // pred: ^bb166
      cf.br ^bb169(%c0_i32 : i32)
    ^bb169(%710: i32):  // 2 preds: ^bb168, ^bb176
      %711 = arith.cmpi slt, %710, %492 : i32
      cf.cond_br %711, ^bb170, ^bb177 {llvm.loop_annotation = #loop_annotation}
    ^bb170:  // pred: ^bb169
      cf.br ^bb171(%c0_i32 : i32)
    ^bb171(%712: i32):  // 2 preds: ^bb170, ^bb175
      %713 = arith.cmpi slt, %712, %442 : i32
      cf.cond_br %713, ^bb172, ^bb176 {llvm.loop_annotation = #loop_annotation}
    ^bb172:  // pred: ^bb171
      %coord_645 = cute.make_coord(%712, %710) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_646 = cute.crd2idx(%coord_645, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_647 = cute.add_offset(%ptr_595, %idx_646) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %714 = builtin.unrealized_conversion_cast %ptr_647 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %715 = llvm.getelementptr %714[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %716 = llvm.getelementptr %714[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %717 = llvm.getelementptr %714[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb173(%c0_i32 : i32)
    ^bb173(%718: i32):  // 2 preds: ^bb172, ^bb174
      %719 = arith.cmpi slt, %718, %493 : i32
      cf.cond_br %719, ^bb174, ^bb175 {llvm.loop_annotation = #loop_annotation}
    ^bb174:  // pred: ^bb173
      %coord_648 = cute.make_coord(%718, %710) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_649 = cute.make_coord(%712, %718) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_650 = cute.crd2idx(%coord_648, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_651 = cute.add_offset(%ptr_605, %idx_650) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_652 = cute.crd2idx(%coord_649, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_653 = cute.add_offset(%iter_426, %idx_652) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %720 = llvm.load %714 : !llvm.ptr -> i32
      %721 = llvm.load %715 : !llvm.ptr -> i32
      %722 = llvm.load %716 : !llvm.ptr -> i32
      %723 = llvm.load %717 : !llvm.ptr -> i32
      %724 = builtin.unrealized_conversion_cast %ptr_651 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %725 = llvm.load %724 : !llvm.ptr -> i32
      %726 = llvm.getelementptr %724[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %727 = llvm.load %726 : !llvm.ptr -> i32
      %728 = builtin.unrealized_conversion_cast %ptr_653 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %729 = llvm.load %728 : !llvm.ptr -> f32
      %730 = llvm.getelementptr %728[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %731 = llvm.load %730 : !llvm.ptr -> f32
      %732 = llvm.getelementptr %728[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %733 = llvm.load %732 : !llvm.ptr -> f32
      %734 = llvm.getelementptr %728[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %735 = llvm.load %734 : !llvm.ptr -> f32
      %736:4 = cute_nvgpu.arch.mma.SM80 A[%720, %721, %722, %723]  B[%725, %727]  C[%729, %731, %733, %735] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %736#0, %728 : f32, !llvm.ptr
      llvm.store %736#1, %730 : f32, !llvm.ptr
      llvm.store %736#2, %732 : f32, !llvm.ptr
      llvm.store %736#3, %734 : f32, !llvm.ptr
      %737 = arith.addi %718, %c1_i32 : i32
      cf.br ^bb173(%737 : i32)
    ^bb175:  // pred: ^bb173
      %738 = arith.addi %712, %c1_i32 : i32
      cf.br ^bb171(%738 : i32)
    ^bb176:  // pred: ^bb171
      %739 = arith.addi %710, %c1_i32 : i32
      cf.br ^bb169(%739 : i32)
    ^bb177:  // pred: ^bb169
      %idx_654 = cute.crd2idx(%107, %lay_105) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_655 = cute.add_offset(%ptr_101, %idx_654) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_656 = cute.add_offset(%iter_106, %106) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb178(%c0_i32 : i32)
    ^bb178(%740: i32):  // 2 preds: ^bb177, ^bb179
      %741 = arith.cmpi slt, %740, %442 : i32
      cf.cond_br %741, ^bb179, ^bb180 {llvm.loop_annotation = #loop_annotation}
    ^bb179:  // pred: ^bb178
      %coord_657 = cute.make_coord(%740) : (i32) -> !cute.coord<"(_,?)">
      %idx_658 = cute.crd2idx(%coord_657, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_659 = cute.add_offset(%ptr_655, %idx_658) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_660 = cute.crd2idx(%coord_657, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_661 = cute.add_offset(%ptr_656, %idx_660) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %742 = cute_nvgpu.arch.copy.ldsm %ptr_659{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %743 = vector.extractelement %742[%130 : i32] : vector<4xi32>
      %744 = builtin.unrealized_conversion_cast %ptr_661 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %743, %744 : i32, !llvm.ptr
      %745 = vector.extractelement %742[%129 : i32] : vector<4xi32>
      %ptr_662 = cute.add_offset(%ptr_661, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %746 = builtin.unrealized_conversion_cast %ptr_662 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %745, %746 : i32, !llvm.ptr
      %747 = vector.extractelement %742[%128 : i32] : vector<4xi32>
      %ptr_663 = cute.add_offset(%ptr_661, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %748 = builtin.unrealized_conversion_cast %ptr_663 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %747, %748 : i32, !llvm.ptr
      %749 = vector.extractelement %742[%126 : i32] : vector<4xi32>
      %ptr_664 = cute.add_offset(%ptr_661, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %750 = builtin.unrealized_conversion_cast %ptr_664 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %749, %750 : i32, !llvm.ptr
      %751 = arith.addi %740, %c1_i32 : i32
      cf.br ^bb178(%751 : i32)
    ^bb180:  // pred: ^bb178
      %idx_665 = cute.crd2idx(%107, %lay_113) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_666 = cute.add_offset(%ptr_109, %idx_665) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_667 = cute.add_offset(%iter_114, %105) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb181(%c0_i32 : i32)
    ^bb181(%752: i32):  // 2 preds: ^bb180, ^bb182
      %753 = arith.cmpi slt, %752, %455 : i32
      cf.cond_br %753, ^bb182, ^bb183 {llvm.loop_annotation = #loop_annotation}
    ^bb182:  // pred: ^bb181
      %coord_668 = cute.make_coord(%752) : (i32) -> !cute.coord<"(_,?)">
      %idx_669 = cute.crd2idx(%coord_668, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_670 = cute.add_offset(%ptr_666, %idx_669) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_671 = cute.crd2idx(%coord_668, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_672 = cute.add_offset(%ptr_667, %idx_671) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %754 = cute_nvgpu.arch.copy.ldsm %ptr_670{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %755 = vector.extractelement %754[%130 : i32] : vector<4xi32>
      %756 = builtin.unrealized_conversion_cast %ptr_672 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %755, %756 : i32, !llvm.ptr
      %757 = vector.extractelement %754[%129 : i32] : vector<4xi32>
      %ptr_673 = cute.add_offset(%ptr_672, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %758 = builtin.unrealized_conversion_cast %ptr_673 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %757, %758 : i32, !llvm.ptr
      %759 = vector.extractelement %754[%128 : i32] : vector<4xi32>
      %ptr_674 = cute.add_offset(%ptr_672, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %760 = builtin.unrealized_conversion_cast %ptr_674 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %759, %760 : i32, !llvm.ptr
      %761 = vector.extractelement %754[%126 : i32] : vector<4xi32>
      %ptr_675 = cute.add_offset(%ptr_672, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %762 = builtin.unrealized_conversion_cast %ptr_675 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %761, %762 : i32, !llvm.ptr
      %763 = arith.addi %752, %c1_i32 : i32
      cf.br ^bb181(%763 : i32)
    ^bb183:  // pred: ^bb181
      cf.br ^bb184(%c0_i32 : i32)
    ^bb184(%764: i32):  // 2 preds: ^bb183, ^bb191
      %765 = arith.cmpi slt, %764, %492 : i32
      cf.cond_br %765, ^bb185, ^bb192 {llvm.loop_annotation = #loop_annotation}
    ^bb185:  // pred: ^bb184
      cf.br ^bb186(%c0_i32 : i32)
    ^bb186(%766: i32):  // 2 preds: ^bb185, ^bb190
      %767 = arith.cmpi slt, %766, %442 : i32
      cf.cond_br %767, ^bb187, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb187:  // pred: ^bb186
      %coord_676 = cute.make_coord(%766, %764) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_677 = cute.crd2idx(%coord_676, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_678 = cute.add_offset(%ptr_625, %idx_677) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %768 = builtin.unrealized_conversion_cast %ptr_678 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %769 = llvm.getelementptr %768[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %770 = llvm.getelementptr %768[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %771 = llvm.getelementptr %768[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb188(%c0_i32 : i32)
    ^bb188(%772: i32):  // 2 preds: ^bb187, ^bb189
      %773 = arith.cmpi slt, %772, %493 : i32
      cf.cond_br %773, ^bb189, ^bb190 {llvm.loop_annotation = #loop_annotation}
    ^bb189:  // pred: ^bb188
      %coord_679 = cute.make_coord(%772, %764) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_680 = cute.make_coord(%766, %772) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_681 = cute.crd2idx(%coord_679, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_682 = cute.add_offset(%ptr_636, %idx_681) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_683 = cute.crd2idx(%coord_680, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_684 = cute.add_offset(%iter_426, %idx_683) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %774 = llvm.load %768 : !llvm.ptr -> i32
      %775 = llvm.load %769 : !llvm.ptr -> i32
      %776 = llvm.load %770 : !llvm.ptr -> i32
      %777 = llvm.load %771 : !llvm.ptr -> i32
      %778 = builtin.unrealized_conversion_cast %ptr_682 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %779 = llvm.load %778 : !llvm.ptr -> i32
      %780 = llvm.getelementptr %778[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %781 = llvm.load %780 : !llvm.ptr -> i32
      %782 = builtin.unrealized_conversion_cast %ptr_684 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %783 = llvm.load %782 : !llvm.ptr -> f32
      %784 = llvm.getelementptr %782[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %785 = llvm.load %784 : !llvm.ptr -> f32
      %786 = llvm.getelementptr %782[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %787 = llvm.load %786 : !llvm.ptr -> f32
      %788 = llvm.getelementptr %782[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %789 = llvm.load %788 : !llvm.ptr -> f32
      %790:4 = cute_nvgpu.arch.mma.SM80 A[%774, %775, %776, %777]  B[%779, %781]  C[%783, %785, %787, %789] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %790#0, %782 : f32, !llvm.ptr
      llvm.store %790#1, %784 : f32, !llvm.ptr
      llvm.store %790#2, %786 : f32, !llvm.ptr
      llvm.store %790#3, %788 : f32, !llvm.ptr
      %791 = arith.addi %772, %c1_i32 : i32
      cf.br ^bb188(%791 : i32)
    ^bb190:  // pred: ^bb188
      %792 = arith.addi %766, %c1_i32 : i32
      cf.br ^bb186(%792 : i32)
    ^bb191:  // pred: ^bb186
      %793 = arith.addi %764, %c1_i32 : i32
      cf.br ^bb184(%793 : i32)
    ^bb192:  // pred: ^bb184
      %idx_685 = cute.crd2idx(%104, %lay_105) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_686 = cute.add_offset(%ptr_101, %idx_685) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_687 = cute.add_offset(%iter_106, %103) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb193(%c0_i32 : i32)
    ^bb193(%794: i32):  // 2 preds: ^bb192, ^bb194
      %795 = arith.cmpi slt, %794, %442 : i32
      cf.cond_br %795, ^bb194, ^bb195 {llvm.loop_annotation = #loop_annotation}
    ^bb194:  // pred: ^bb193
      %coord_688 = cute.make_coord(%794) : (i32) -> !cute.coord<"(_,?)">
      %idx_689 = cute.crd2idx(%coord_688, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_690 = cute.add_offset(%ptr_686, %idx_689) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_691 = cute.crd2idx(%coord_688, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_692 = cute.add_offset(%ptr_687, %idx_691) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %796 = cute_nvgpu.arch.copy.ldsm %ptr_690{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %797 = vector.extractelement %796[%130 : i32] : vector<4xi32>
      %798 = builtin.unrealized_conversion_cast %ptr_692 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %797, %798 : i32, !llvm.ptr
      %799 = vector.extractelement %796[%129 : i32] : vector<4xi32>
      %ptr_693 = cute.add_offset(%ptr_692, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %800 = builtin.unrealized_conversion_cast %ptr_693 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %799, %800 : i32, !llvm.ptr
      %801 = vector.extractelement %796[%128 : i32] : vector<4xi32>
      %ptr_694 = cute.add_offset(%ptr_692, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %802 = builtin.unrealized_conversion_cast %ptr_694 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %801, %802 : i32, !llvm.ptr
      %803 = vector.extractelement %796[%126 : i32] : vector<4xi32>
      %ptr_695 = cute.add_offset(%ptr_692, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %804 = builtin.unrealized_conversion_cast %ptr_695 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %803, %804 : i32, !llvm.ptr
      %805 = arith.addi %794, %c1_i32 : i32
      cf.br ^bb193(%805 : i32)
    ^bb195:  // pred: ^bb193
      %idx_696 = cute.crd2idx(%104, %lay_113) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_697 = cute.add_offset(%ptr_109, %idx_696) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_698 = cute.add_offset(%iter_114, %102) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb196(%c0_i32 : i32)
    ^bb196(%806: i32):  // 2 preds: ^bb195, ^bb197
      %807 = arith.cmpi slt, %806, %455 : i32
      cf.cond_br %807, ^bb197, ^bb198 {llvm.loop_annotation = #loop_annotation}
    ^bb197:  // pred: ^bb196
      %coord_699 = cute.make_coord(%806) : (i32) -> !cute.coord<"(_,?)">
      %idx_700 = cute.crd2idx(%coord_699, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_701 = cute.add_offset(%ptr_697, %idx_700) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_702 = cute.crd2idx(%coord_699, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_703 = cute.add_offset(%ptr_698, %idx_702) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %808 = cute_nvgpu.arch.copy.ldsm %ptr_701{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %809 = vector.extractelement %808[%130 : i32] : vector<4xi32>
      %810 = builtin.unrealized_conversion_cast %ptr_703 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %809, %810 : i32, !llvm.ptr
      %811 = vector.extractelement %808[%129 : i32] : vector<4xi32>
      %ptr_704 = cute.add_offset(%ptr_703, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %812 = builtin.unrealized_conversion_cast %ptr_704 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %811, %812 : i32, !llvm.ptr
      %813 = vector.extractelement %808[%128 : i32] : vector<4xi32>
      %ptr_705 = cute.add_offset(%ptr_703, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %814 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %813, %814 : i32, !llvm.ptr
      %815 = vector.extractelement %808[%126 : i32] : vector<4xi32>
      %ptr_706 = cute.add_offset(%ptr_703, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %816 = builtin.unrealized_conversion_cast %ptr_706 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %815, %816 : i32, !llvm.ptr
      %817 = arith.addi %806, %c1_i32 : i32
      cf.br ^bb196(%817 : i32)
    ^bb198:  // pred: ^bb196
      cf.br ^bb199(%c0_i32 : i32)
    ^bb199(%818: i32):  // 2 preds: ^bb198, ^bb206
      %819 = arith.cmpi slt, %818, %492 : i32
      cf.cond_br %819, ^bb200, ^bb207 {llvm.loop_annotation = #loop_annotation}
    ^bb200:  // pred: ^bb199
      cf.br ^bb201(%c0_i32 : i32)
    ^bb201(%820: i32):  // 2 preds: ^bb200, ^bb205
      %821 = arith.cmpi slt, %820, %442 : i32
      cf.cond_br %821, ^bb202, ^bb206 {llvm.loop_annotation = #loop_annotation}
    ^bb202:  // pred: ^bb201
      %coord_707 = cute.make_coord(%820, %818) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_708 = cute.crd2idx(%coord_707, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_709 = cute.add_offset(%ptr_656, %idx_708) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %822 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %823 = llvm.getelementptr %822[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %824 = llvm.getelementptr %822[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %825 = llvm.getelementptr %822[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb203(%c0_i32 : i32)
    ^bb203(%826: i32):  // 2 preds: ^bb202, ^bb204
      %827 = arith.cmpi slt, %826, %493 : i32
      cf.cond_br %827, ^bb204, ^bb205 {llvm.loop_annotation = #loop_annotation}
    ^bb204:  // pred: ^bb203
      %coord_710 = cute.make_coord(%826, %818) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_711 = cute.make_coord(%820, %826) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_712 = cute.crd2idx(%coord_710, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_713 = cute.add_offset(%ptr_667, %idx_712) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_714 = cute.crd2idx(%coord_711, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_715 = cute.add_offset(%iter_426, %idx_714) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %828 = llvm.load %822 : !llvm.ptr -> i32
      %829 = llvm.load %823 : !llvm.ptr -> i32
      %830 = llvm.load %824 : !llvm.ptr -> i32
      %831 = llvm.load %825 : !llvm.ptr -> i32
      %832 = builtin.unrealized_conversion_cast %ptr_713 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %833 = llvm.load %832 : !llvm.ptr -> i32
      %834 = llvm.getelementptr %832[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %835 = llvm.load %834 : !llvm.ptr -> i32
      %836 = builtin.unrealized_conversion_cast %ptr_715 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %837 = llvm.load %836 : !llvm.ptr -> f32
      %838 = llvm.getelementptr %836[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %839 = llvm.load %838 : !llvm.ptr -> f32
      %840 = llvm.getelementptr %836[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %841 = llvm.load %840 : !llvm.ptr -> f32
      %842 = llvm.getelementptr %836[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %843 = llvm.load %842 : !llvm.ptr -> f32
      %844:4 = cute_nvgpu.arch.mma.SM80 A[%828, %829, %830, %831]  B[%833, %835]  C[%837, %839, %841, %843] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %844#0, %836 : f32, !llvm.ptr
      llvm.store %844#1, %838 : f32, !llvm.ptr
      llvm.store %844#2, %840 : f32, !llvm.ptr
      llvm.store %844#3, %842 : f32, !llvm.ptr
      %845 = arith.addi %826, %c1_i32 : i32
      cf.br ^bb203(%845 : i32)
    ^bb205:  // pred: ^bb203
      %846 = arith.addi %820, %c1_i32 : i32
      cf.br ^bb201(%846 : i32)
    ^bb206:  // pred: ^bb201
      %847 = arith.addi %818, %c1_i32 : i32
      cf.br ^bb199(%847 : i32)
    ^bb207:  // pred: ^bb199
      cf.br ^bb208(%c0_i32 : i32)
    ^bb208(%848: i32):  // 2 preds: ^bb207, ^bb209
      %849 = arith.cmpi slt, %848, %442 : i32
      cf.cond_br %849, ^bb209, ^bb210 {llvm.loop_annotation = #loop_annotation}
    ^bb209:  // pred: ^bb208
      %coord_716 = cute.make_coord(%848) : (i32) -> !cute.coord<"(_,?)">
      %idx_717 = cute.crd2idx(%coord_716, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_718 = cute.add_offset(%ptr_101, %idx_717) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_719 = cute.crd2idx(%coord_716, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_720 = cute.add_offset(%iter_106, %idx_719) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %850 = cute_nvgpu.arch.copy.ldsm %ptr_718{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %851 = vector.extractelement %850[%130 : i32] : vector<4xi32>
      %852 = builtin.unrealized_conversion_cast %ptr_720 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %851, %852 : i32, !llvm.ptr
      %853 = vector.extractelement %850[%129 : i32] : vector<4xi32>
      %ptr_721 = cute.add_offset(%ptr_720, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %854 = builtin.unrealized_conversion_cast %ptr_721 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %853, %854 : i32, !llvm.ptr
      %855 = vector.extractelement %850[%128 : i32] : vector<4xi32>
      %ptr_722 = cute.add_offset(%ptr_720, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %856 = builtin.unrealized_conversion_cast %ptr_722 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %855, %856 : i32, !llvm.ptr
      %857 = vector.extractelement %850[%126 : i32] : vector<4xi32>
      %ptr_723 = cute.add_offset(%ptr_720, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %858 = builtin.unrealized_conversion_cast %ptr_723 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %857, %858 : i32, !llvm.ptr
      %859 = arith.addi %848, %c1_i32 : i32
      cf.br ^bb208(%859 : i32)
    ^bb210:  // pred: ^bb208
      cf.br ^bb211(%c0_i32 : i32)
    ^bb211(%860: i32):  // 2 preds: ^bb210, ^bb212
      %861 = arith.cmpi slt, %860, %455 : i32
      cf.cond_br %861, ^bb212, ^bb213 {llvm.loop_annotation = #loop_annotation}
    ^bb212:  // pred: ^bb211
      %coord_724 = cute.make_coord(%860) : (i32) -> !cute.coord<"(_,?)">
      %idx_725 = cute.crd2idx(%coord_724, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_726 = cute.add_offset(%ptr_109, %idx_725) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_727 = cute.crd2idx(%coord_724, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_728 = cute.add_offset(%iter_114, %idx_727) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %862 = cute_nvgpu.arch.copy.ldsm %ptr_726{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %863 = vector.extractelement %862[%130 : i32] : vector<4xi32>
      %864 = builtin.unrealized_conversion_cast %ptr_728 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %863, %864 : i32, !llvm.ptr
      %865 = vector.extractelement %862[%129 : i32] : vector<4xi32>
      %ptr_729 = cute.add_offset(%ptr_728, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %866 = builtin.unrealized_conversion_cast %ptr_729 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %865, %866 : i32, !llvm.ptr
      %867 = vector.extractelement %862[%128 : i32] : vector<4xi32>
      %ptr_730 = cute.add_offset(%ptr_728, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %868 = builtin.unrealized_conversion_cast %ptr_730 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %867, %868 : i32, !llvm.ptr
      %869 = vector.extractelement %862[%126 : i32] : vector<4xi32>
      %ptr_731 = cute.add_offset(%ptr_728, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %870 = builtin.unrealized_conversion_cast %ptr_731 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %869, %870 : i32, !llvm.ptr
      %871 = arith.addi %860, %c1_i32 : i32
      cf.br ^bb211(%871 : i32)
    ^bb213:  // pred: ^bb211
      cf.br ^bb214(%c0_i32 : i32)
    ^bb214(%872: i32):  // 2 preds: ^bb213, ^bb221
      %873 = arith.cmpi slt, %872, %492 : i32
      cf.cond_br %873, ^bb215, ^bb222 {llvm.loop_annotation = #loop_annotation}
    ^bb215:  // pred: ^bb214
      cf.br ^bb216(%c0_i32 : i32)
    ^bb216(%874: i32):  // 2 preds: ^bb215, ^bb220
      %875 = arith.cmpi slt, %874, %442 : i32
      cf.cond_br %875, ^bb217, ^bb221 {llvm.loop_annotation = #loop_annotation}
    ^bb217:  // pred: ^bb216
      %coord_732 = cute.make_coord(%874, %872) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_733 = cute.crd2idx(%coord_732, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_734 = cute.add_offset(%ptr_687, %idx_733) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %876 = builtin.unrealized_conversion_cast %ptr_734 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %877 = llvm.getelementptr %876[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %878 = llvm.getelementptr %876[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %879 = llvm.getelementptr %876[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb218(%c0_i32 : i32)
    ^bb218(%880: i32):  // 2 preds: ^bb217, ^bb219
      %881 = arith.cmpi slt, %880, %493 : i32
      cf.cond_br %881, ^bb219, ^bb220 {llvm.loop_annotation = #loop_annotation}
    ^bb219:  // pred: ^bb218
      %coord_735 = cute.make_coord(%880, %872) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_736 = cute.make_coord(%874, %880) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_737 = cute.crd2idx(%coord_735, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_738 = cute.add_offset(%ptr_698, %idx_737) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_739 = cute.crd2idx(%coord_736, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_740 = cute.add_offset(%iter_426, %idx_739) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %882 = llvm.load %876 : !llvm.ptr -> i32
      %883 = llvm.load %877 : !llvm.ptr -> i32
      %884 = llvm.load %878 : !llvm.ptr -> i32
      %885 = llvm.load %879 : !llvm.ptr -> i32
      %886 = builtin.unrealized_conversion_cast %ptr_738 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %887 = llvm.load %886 : !llvm.ptr -> i32
      %888 = llvm.getelementptr %886[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %889 = llvm.load %888 : !llvm.ptr -> i32
      %890 = builtin.unrealized_conversion_cast %ptr_740 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %891 = llvm.load %890 : !llvm.ptr -> f32
      %892 = llvm.getelementptr %890[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %893 = llvm.load %892 : !llvm.ptr -> f32
      %894 = llvm.getelementptr %890[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %895 = llvm.load %894 : !llvm.ptr -> f32
      %896 = llvm.getelementptr %890[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %897 = llvm.load %896 : !llvm.ptr -> f32
      %898:4 = cute_nvgpu.arch.mma.SM80 A[%882, %883, %884, %885]  B[%887, %889]  C[%891, %893, %895, %897] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %898#0, %890 : f32, !llvm.ptr
      llvm.store %898#1, %892 : f32, !llvm.ptr
      llvm.store %898#2, %894 : f32, !llvm.ptr
      llvm.store %898#3, %896 : f32, !llvm.ptr
      %899 = arith.addi %880, %c1_i32 : i32
      cf.br ^bb218(%899 : i32)
    ^bb220:  // pred: ^bb218
      %900 = arith.addi %874, %c1_i32 : i32
      cf.br ^bb216(%900 : i32)
    ^bb221:  // pred: ^bb216
      %901 = arith.addi %872, %c1_i32 : i32
      cf.br ^bb214(%901 : i32)
    ^bb222:  // pred: ^bb214
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %902 = arith.cmpi sgt, %190, %c0_i32 : i32
      cf.cond_br %902, ^bb223, ^bb227
    ^bb223:  // pred: ^bb222
      %903 = arith.subi %189, %c2_i32 : i32
      %coord_741 = cute.make_coord(%903) : (i32) -> !cute.coord<"(_,_,_,?)">
      %904:3 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_742 = cute.assume(%904#1) : (i64) -> !cute.i64<divby 128>
      %stride_743 = cute.make_stride(%iv_742) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_744 = cute.make_layout(%137, %stride_743) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_745 = cute.crd2idx(%coord_741, %lay_83) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_746 = cute.add_offset(%ptr_78, %idx_745) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %append = cute.append_to_rank<2> (%lay_744, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %905 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_747 = cute.assume(%905) : (i64) -> !cute.i64<divby 128>
      %stride_748 = cute.make_stride(%iv_747) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_749 = cute.make_layout(%136, %stride_748) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_750 = cute.append_to_rank<2> (%lay_749, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %906 = cute.get_scalars(%append_750) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_751 = cute.assume(%906) : (i64) -> !cute.i64<divby 128>
      %stride_752 = cute.make_stride(%iv_751) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_753 = cute.make_layout(%135, %stride_752) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb224(%c0_i32 : i32)
    ^bb224(%907: i32):  // 2 preds: ^bb223, ^bb225
      %908 = arith.cmpi slt, %907, %493 : i32
      cf.cond_br %908, ^bb225, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb225:  // pred: ^bb224
      %coord_754 = cute.make_coord(%907) : (i32) -> !cute.coord<"(_,?)">
      %idx_755 = cute.crd2idx(%coord_754, %lay_753) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_756 = cute.add_offset(%ptr_746, %idx_755) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_757 = cute.crd2idx(%coord_754, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_758 = cute.add_offset(%ptr_84, %idx_757) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_759 = cute.crd2idx(%coord_754, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_760 = cute.add_offset(%iter_161, %idx_759) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %909 = builtin.unrealized_conversion_cast %ptr_760 : !cute.ptr<i8, rmem> to !llvm.ptr
      %910 = llvm.load %909 : !llvm.ptr -> i8
      %911 = llvm.trunc %910 : i8 to i1
      %iter_761 = cute.recast_iter(%ptr_756) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_762 = cute.recast_iter(%ptr_758) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_762 : !cute.ptr<i128, smem>, %iter_761 : !cute.ptr<i128, gmem>, %911 : i1) {cache_mode = <global>}
      %912 = arith.addi %907, %c1_i32 : i32
      cf.br ^bb224(%912 : i32)
    ^bb226:  // pred: ^bb224
      nvvm.cp.async.commit.group
      cf.br ^bb227
    ^bb227:  // 2 preds: ^bb222, ^bb226
      %view_763 = cute.make_view(%iter_426, %101) : !memref_rmem_f32_3
      %shape_764 = cute.make_shape(%itup_125, %itup_126, %itup_127, %itup) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?)">
      %lay_765 = cute.make_layout(%shape_764, %171) : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %913:4 = cute.get_scalars(%lay_765) <{only_dynamic}> : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %shape_766 = cute.make_shape(%913#1, %913#3) : (i32, i32) -> !cute.shape<"(?,?)">
      %lay_767 = cute.make_layout(%shape_766, %170) : !cute.layout<"(?,?):(1@1,1@3)">
      %idx_768 = cute.crd2idx(%coord, %lay_765) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_769 = cute.add_offset(%172, %idx_768) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_770 = cute.make_coord(%183, %190) : (i32, i32) -> !cute.coord<"(?,?)">
      %914:2 = cute.get_scalars(%coord_770) <{only_dynamic}> : !cute.coord<"(?,?)">
      %coord_771 = cute.make_coord(%914#0, %914#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %915:2 = cute.get_scalars(%lay_767) <{only_dynamic}> : !cute.layout<"(?,?):(1@1,1@3)">
      %916 = arith.ceildivsi %915#0, %c128_i32 : i32
      %917 = arith.ceildivsi %915#1, %c64_i32 : i32
      %shape_772 = cute.make_shape(%916, %917) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_773 = cute.make_layout(%shape_772, %100) : !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">
      %idx_774 = cute.crd2idx(%coord_771, %lay_773) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">) -> !cute.int_tuple<"(0,?{div=128},0,?{div=64})">
      %tup_775 = cute.add_offset(%tup_769, %idx_774) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,?{div=64})">) -> !cute.int_tuple<"(?,?{div=128},?,?{div=64})">
      %918 = arith.remsi %211, %c32_i32 : i32
      %919 = arith.divsi %211, %c32_i32 : i32
      %920 = arith.remsi %919, %c4_i32 : i32
      %921 = arith.remsi %918, %c32_i32 : i32
      %922 = arith.remsi %920, %c4_i32 : i32
      %923 = arith.divsi %921, %c4_i32 : i32
      %924 = arith.remsi %921, %c4_i32 : i32
      %925 = arith.muli %924, %c2_i32 : i32
      %926 = arith.muli %922, %c16_i32 : i32
      %927 = arith.addi %923, %926 : i32
      %iv_776 = cute.assume(%925) : (i32) -> !cute.i32<divby 2>
      %int_tuple_777 = cute.make_int_tuple(%927, %iv_776) : (i32, !cute.i32<divby 2>) -> !cute.int_tuple<"(0,?,0,?{div=2})">
      %tup_778 = cute.add_offset(%tup_775, %int_tuple_777) : (!cute.int_tuple<"(?,?{div=128},?,?{div=64})">, !cute.int_tuple<"(0,?,0,?{div=2})">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_779, %e1_780, %e2_781, %e3_782 = cute.get_leaves(%tup_778) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %int_tuple_783 = cute.make_int_tuple(%e0_779, %e1_780, %e2_781, %e3_782) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_784, %e1_785, %e2_786, %e3_787 = cute.get_leaves(%int_tuple_783) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_788 = cute.add_offset(%e3_787, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_789 = cute.make_coord(%tup_788) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %928 = cute.get_scalars(%coord_789) : !cute.coord<"?">
      %929 = arith.cmpi slt, %378, %928 : i32
      cf.cond_br %929, ^bb228, ^bb229
    ^bb228:  // pred: ^bb227
      cute.memref.store(%view_763, %99, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,0)">, f32) -> ()
      cf.br ^bb229
    ^bb229:  // 2 preds: ^bb227, ^bb228
      %tup_790 = cute.add_offset(%int_tuple_783, %98) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_791, %e1_792, %e2_793, %e3_794 = cute.get_leaves(%tup_790) : !cute.int_tuple<"(?,?,?,?)">
      %tup_795 = cute.add_offset(%e3_794, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_796 = cute.make_coord(%tup_795) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %930 = cute.get_scalars(%coord_796) : !cute.coord<"?">
      %931 = arith.cmpi slt, %378, %930 : i32
      cf.cond_br %931, ^bb230, ^bb231
    ^bb230:  // pred: ^bb229
      cute.memref.store(%view_763, %97, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,1)">, f32) -> ()
      cf.br ^bb231
    ^bb231:  // 2 preds: ^bb229, ^bb230
      %tup_797 = cute.add_offset(%int_tuple_783, %96) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_798, %e1_799, %e2_800, %e3_801 = cute.get_leaves(%tup_797) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_802 = cute.add_offset(%e3_801, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_803 = cute.make_coord(%tup_802) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %932 = cute.get_scalars(%coord_803) : !cute.coord<"?">
      %933 = arith.cmpi slt, %378, %932 : i32
      cf.cond_br %933, ^bb232, ^bb233
    ^bb232:  // pred: ^bb231
      cute.memref.store(%view_763, %95, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,2)">, f32) -> ()
      cf.br ^bb233
    ^bb233:  // 2 preds: ^bb231, ^bb232
      %tup_804 = cute.add_offset(%int_tuple_783, %94) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_805, %e1_806, %e2_807, %e3_808 = cute.get_leaves(%tup_804) : !cute.int_tuple<"(?,?,?,?)">
      %tup_809 = cute.add_offset(%e3_808, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_810 = cute.make_coord(%tup_809) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %934 = cute.get_scalars(%coord_810) : !cute.coord<"?">
      %935 = arith.cmpi slt, %378, %934 : i32
      cf.cond_br %935, ^bb234, ^bb235
    ^bb234:  // pred: ^bb233
      cute.memref.store(%view_763, %93, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,3)">, f32) -> ()
      cf.br ^bb235
    ^bb235:  // 2 preds: ^bb233, ^bb234
      %tup_811 = cute.add_offset(%int_tuple_783, %92) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_812, %e1_813, %e2_814, %e3_815 = cute.get_leaves(%tup_811) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_816 = cute.add_offset(%e3_815, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_817 = cute.make_coord(%tup_816) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %936 = cute.get_scalars(%coord_817) : !cute.coord<"?">
      %937 = arith.cmpi slt, %378, %936 : i32
      cf.cond_br %937, ^bb236, ^bb237
    ^bb236:  // pred: ^bb235
      cute.memref.store(%view_763, %91, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,4)">, f32) -> ()
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      %tup_818 = cute.add_offset(%int_tuple_783, %90) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_819, %e1_820, %e2_821, %e3_822 = cute.get_leaves(%tup_818) : !cute.int_tuple<"(?,?,?,?)">
      %tup_823 = cute.add_offset(%e3_822, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_824 = cute.make_coord(%tup_823) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %938 = cute.get_scalars(%coord_824) : !cute.coord<"?">
      %939 = arith.cmpi slt, %378, %938 : i32
      cf.cond_br %939, ^bb238, ^bb239
    ^bb238:  // pred: ^bb237
      cute.memref.store(%view_763, %89, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,5)">, f32) -> ()
      cf.br ^bb239
    ^bb239:  // 2 preds: ^bb237, ^bb238
      %tup_825 = cute.add_offset(%int_tuple_783, %88) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_826, %e1_827, %e2_828, %e3_829 = cute.get_leaves(%tup_825) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_830 = cute.add_offset(%e3_829, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_831 = cute.make_coord(%tup_830) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %940 = cute.get_scalars(%coord_831) : !cute.coord<"?">
      %941 = arith.cmpi slt, %378, %940 : i32
      cf.cond_br %941, ^bb240, ^bb241
    ^bb240:  // pred: ^bb239
      cute.memref.store(%view_763, %87, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,6)">, f32) -> ()
      cf.br ^bb241
    ^bb241:  // 2 preds: ^bb239, ^bb240
      %tup_832 = cute.add_offset(%int_tuple_783, %86) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_833, %e1_834, %e2_835, %e3_836 = cute.get_leaves(%tup_832) : !cute.int_tuple<"(?,?,?,?)">
      %tup_837 = cute.add_offset(%e3_836, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_838 = cute.make_coord(%tup_837) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %942 = cute.get_scalars(%coord_838) : !cute.coord<"?">
      %943 = arith.cmpi slt, %378, %942 : i32
      cf.cond_br %943, ^bb242, ^bb243
    ^bb242:  // pred: ^bb241
      cute.memref.store(%view_763, %85, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,7)">, f32) -> ()
      cf.br ^bb243
    ^bb243:  // 2 preds: ^bb241, ^bb242
      %tup_839 = cute.add_offset(%int_tuple_783, %84) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_840, %e1_841, %e2_842, %e3_843 = cute.get_leaves(%tup_839) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_844 = cute.add_offset(%e3_843, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_845 = cute.make_coord(%tup_844) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %944 = cute.get_scalars(%coord_845) : !cute.coord<"?">
      %945 = arith.cmpi slt, %378, %944 : i32
      cf.cond_br %945, ^bb244, ^bb245
    ^bb244:  // pred: ^bb243
      cute.memref.store(%view_763, %83, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,8)">, f32) -> ()
      cf.br ^bb245
    ^bb245:  // 2 preds: ^bb243, ^bb244
      %tup_846 = cute.add_offset(%int_tuple_783, %82) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_847, %e1_848, %e2_849, %e3_850 = cute.get_leaves(%tup_846) : !cute.int_tuple<"(?,?,?,?)">
      %tup_851 = cute.add_offset(%e3_850, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_852 = cute.make_coord(%tup_851) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %946 = cute.get_scalars(%coord_852) : !cute.coord<"?">
      %947 = arith.cmpi slt, %378, %946 : i32
      cf.cond_br %947, ^bb246, ^bb247
    ^bb246:  // pred: ^bb245
      cute.memref.store(%view_763, %81, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,9)">, f32) -> ()
      cf.br ^bb247
    ^bb247:  // 2 preds: ^bb245, ^bb246
      %tup_853 = cute.add_offset(%int_tuple_783, %80) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_854, %e1_855, %e2_856, %e3_857 = cute.get_leaves(%tup_853) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_858 = cute.add_offset(%e3_857, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_859 = cute.make_coord(%tup_858) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %948 = cute.get_scalars(%coord_859) : !cute.coord<"?">
      %949 = arith.cmpi slt, %378, %948 : i32
      cf.cond_br %949, ^bb248, ^bb249
    ^bb248:  // pred: ^bb247
      cute.memref.store(%view_763, %79, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,10)">, f32) -> ()
      cf.br ^bb249
    ^bb249:  // 2 preds: ^bb247, ^bb248
      %tup_860 = cute.add_offset(%int_tuple_783, %78) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_861, %e1_862, %e2_863, %e3_864 = cute.get_leaves(%tup_860) : !cute.int_tuple<"(?,?,?,?)">
      %tup_865 = cute.add_offset(%e3_864, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_866 = cute.make_coord(%tup_865) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %950 = cute.get_scalars(%coord_866) : !cute.coord<"?">
      %951 = arith.cmpi slt, %378, %950 : i32
      cf.cond_br %951, ^bb250, ^bb251
    ^bb250:  // pred: ^bb249
      cute.memref.store(%view_763, %77, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,11)">, f32) -> ()
      cf.br ^bb251
    ^bb251:  // 2 preds: ^bb249, ^bb250
      %tup_867 = cute.add_offset(%int_tuple_783, %76) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_868, %e1_869, %e2_870, %e3_871 = cute.get_leaves(%tup_867) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_872 = cute.add_offset(%e3_871, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_873 = cute.make_coord(%tup_872) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %952 = cute.get_scalars(%coord_873) : !cute.coord<"?">
      %953 = arith.cmpi slt, %378, %952 : i32
      cf.cond_br %953, ^bb252, ^bb253
    ^bb252:  // pred: ^bb251
      cute.memref.store(%view_763, %75, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,12)">, f32) -> ()
      cf.br ^bb253
    ^bb253:  // 2 preds: ^bb251, ^bb252
      %tup_874 = cute.add_offset(%int_tuple_783, %74) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_875, %e1_876, %e2_877, %e3_878 = cute.get_leaves(%tup_874) : !cute.int_tuple<"(?,?,?,?)">
      %tup_879 = cute.add_offset(%e3_878, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_880 = cute.make_coord(%tup_879) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %954 = cute.get_scalars(%coord_880) : !cute.coord<"?">
      %955 = arith.cmpi slt, %378, %954 : i32
      cf.cond_br %955, ^bb254, ^bb255
    ^bb254:  // pred: ^bb253
      cute.memref.store(%view_763, %73, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,13)">, f32) -> ()
      cf.br ^bb255
    ^bb255:  // 2 preds: ^bb253, ^bb254
      %tup_881 = cute.add_offset(%int_tuple_783, %72) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_882, %e1_883, %e2_884, %e3_885 = cute.get_leaves(%tup_881) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_886 = cute.add_offset(%e3_885, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_887 = cute.make_coord(%tup_886) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %956 = cute.get_scalars(%coord_887) : !cute.coord<"?">
      %957 = arith.cmpi slt, %378, %956 : i32
      cf.cond_br %957, ^bb256, ^bb257
    ^bb256:  // pred: ^bb255
      cute.memref.store(%view_763, %71, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,14)">, f32) -> ()
      cf.br ^bb257
    ^bb257:  // 2 preds: ^bb255, ^bb256
      %tup_888 = cute.add_offset(%int_tuple_783, %70) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_889, %e1_890, %e2_891, %e3_892 = cute.get_leaves(%tup_888) : !cute.int_tuple<"(?,?,?,?)">
      %tup_893 = cute.add_offset(%e3_892, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_894 = cute.make_coord(%tup_893) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %958 = cute.get_scalars(%coord_894) : !cute.coord<"?">
      %959 = arith.cmpi slt, %378, %958 : i32
      cf.cond_br %959, ^bb258, ^bb259
    ^bb258:  // pred: ^bb257
      cute.memref.store(%view_763, %69, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,15)">, f32) -> ()
      cf.br ^bb259
    ^bb259:  // 2 preds: ^bb257, ^bb258
      %view_895 = cute.make_view(%iter_426) : !memref_rmem_f32_4
      %960 = cute.memref.load_vec %view_895 : !memref_rmem_f32_4
      %961 = vector.reduction <maximumf>, %960, %cst_5 : vector<16xf32> into f32
      %962 = nvvm.shfl.sync  bfly %c-1_i32, %961, %c2_i32, %c31_i32 : f32 -> f32
      %963 = nvvm.fmax %961, %962
      %964 = nvvm.shfl.sync  bfly %c-1_i32, %963, %c1_i32, %c31_i32 : f32 -> f32
      %965 = nvvm.fmax %963, %964
      %966 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %967 = arith.mulf %960, %966 : vector<16xf32>
      %968 = arith.mulf %965, %arg4 : f32
      %969 = vector.broadcast %968 : f32 to vector<16xf32>
      %970 = arith.subf %967, %969 : vector<16xf32>
      %971 = math.exp2 %970 fastmath<fast> : vector<16xf32>
      %972 = vector.reduction <add>, %971, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_423, %68, %965) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store(%rmem_424, %68, %972) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store_vec %971, %view_895 : !memref_rmem_f32_4
      cf.cond_br %929, ^bb260, ^bb261
    ^bb260:  // pred: ^bb259
      cute.memref.store(%view_763, %67, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,0)">, f32) -> ()
      cf.br ^bb261
    ^bb261:  // 2 preds: ^bb259, ^bb260
      cf.cond_br %931, ^bb262, ^bb263
    ^bb262:  // pred: ^bb261
      cute.memref.store(%view_763, %66, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,1)">, f32) -> ()
      cf.br ^bb263
    ^bb263:  // 2 preds: ^bb261, ^bb262
      cf.cond_br %933, ^bb264, ^bb265
    ^bb264:  // pred: ^bb263
      cute.memref.store(%view_763, %65, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,2)">, f32) -> ()
      cf.br ^bb265
    ^bb265:  // 2 preds: ^bb263, ^bb264
      cf.cond_br %935, ^bb266, ^bb267
    ^bb266:  // pred: ^bb265
      cute.memref.store(%view_763, %64, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,3)">, f32) -> ()
      cf.br ^bb267
    ^bb267:  // 2 preds: ^bb265, ^bb266
      cf.cond_br %937, ^bb268, ^bb269
    ^bb268:  // pred: ^bb267
      cute.memref.store(%view_763, %63, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,4)">, f32) -> ()
      cf.br ^bb269
    ^bb269:  // 2 preds: ^bb267, ^bb268
      cf.cond_br %939, ^bb270, ^bb271
    ^bb270:  // pred: ^bb269
      cute.memref.store(%view_763, %62, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,5)">, f32) -> ()
      cf.br ^bb271
    ^bb271:  // 2 preds: ^bb269, ^bb270
      cf.cond_br %941, ^bb272, ^bb273
    ^bb272:  // pred: ^bb271
      cute.memref.store(%view_763, %61, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,6)">, f32) -> ()
      cf.br ^bb273
    ^bb273:  // 2 preds: ^bb271, ^bb272
      cf.cond_br %943, ^bb274, ^bb275
    ^bb274:  // pred: ^bb273
      cute.memref.store(%view_763, %60, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,7)">, f32) -> ()
      cf.br ^bb275
    ^bb275:  // 2 preds: ^bb273, ^bb274
      cf.cond_br %945, ^bb276, ^bb277
    ^bb276:  // pred: ^bb275
      cute.memref.store(%view_763, %59, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,8)">, f32) -> ()
      cf.br ^bb277
    ^bb277:  // 2 preds: ^bb275, ^bb276
      cf.cond_br %947, ^bb278, ^bb279
    ^bb278:  // pred: ^bb277
      cute.memref.store(%view_763, %58, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,9)">, f32) -> ()
      cf.br ^bb279
    ^bb279:  // 2 preds: ^bb277, ^bb278
      cf.cond_br %949, ^bb280, ^bb281
    ^bb280:  // pred: ^bb279
      cute.memref.store(%view_763, %57, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,10)">, f32) -> ()
      cf.br ^bb281
    ^bb281:  // 2 preds: ^bb279, ^bb280
      cf.cond_br %951, ^bb282, ^bb283
    ^bb282:  // pred: ^bb281
      cute.memref.store(%view_763, %56, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,11)">, f32) -> ()
      cf.br ^bb283
    ^bb283:  // 2 preds: ^bb281, ^bb282
      cf.cond_br %953, ^bb284, ^bb285
    ^bb284:  // pred: ^bb283
      cute.memref.store(%view_763, %55, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,12)">, f32) -> ()
      cf.br ^bb285
    ^bb285:  // 2 preds: ^bb283, ^bb284
      cf.cond_br %955, ^bb286, ^bb287
    ^bb286:  // pred: ^bb285
      cute.memref.store(%view_763, %54, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,13)">, f32) -> ()
      cf.br ^bb287
    ^bb287:  // 2 preds: ^bb285, ^bb286
      cf.cond_br %957, ^bb288, ^bb289
    ^bb288:  // pred: ^bb287
      cute.memref.store(%view_763, %53, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,14)">, f32) -> ()
      cf.br ^bb289
    ^bb289:  // 2 preds: ^bb287, ^bb288
      cf.cond_br %959, ^bb290, ^bb291
    ^bb290:  // pred: ^bb289
      cute.memref.store(%view_763, %52, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,15)">, f32) -> ()
      cf.br ^bb291
    ^bb291:  // 2 preds: ^bb289, ^bb290
      %ptr_896 = cute.add_offset(%iter_426, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_897 = cute.make_view(%ptr_896) : !memref_rmem_f32_5
      %973 = cute.memref.load_vec %view_897 : !memref_rmem_f32_5
      %974 = vector.reduction <maximumf>, %973, %cst_5 : vector<16xf32> into f32
      %975 = nvvm.shfl.sync  bfly %c-1_i32, %974, %c2_i32, %c31_i32 : f32 -> f32
      %976 = nvvm.fmax %974, %975
      %977 = nvvm.shfl.sync  bfly %c-1_i32, %976, %c1_i32, %c31_i32 : f32 -> f32
      %978 = nvvm.fmax %976, %977
      %979 = arith.mulf %973, %966 : vector<16xf32>
      %980 = arith.mulf %978, %arg4 : f32
      %981 = vector.broadcast %980 : f32 to vector<16xf32>
      %982 = arith.subf %979, %981 : vector<16xf32>
      %983 = math.exp2 %982 fastmath<fast> : vector<16xf32>
      %984 = vector.reduction <add>, %983, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_423, %51, %978) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store(%rmem_424, %51, %984) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store_vec %983, %view_897 : !memref_rmem_f32_5
      cf.cond_br %929, ^bb292, ^bb293
    ^bb292:  // pred: ^bb291
      cute.memref.store(%view_763, %50, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,0)">, f32) -> ()
      cf.br ^bb293
    ^bb293:  // 2 preds: ^bb291, ^bb292
      cf.cond_br %931, ^bb294, ^bb295
    ^bb294:  // pred: ^bb293
      cute.memref.store(%view_763, %49, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,1)">, f32) -> ()
      cf.br ^bb295
    ^bb295:  // 2 preds: ^bb293, ^bb294
      cf.cond_br %933, ^bb296, ^bb297
    ^bb296:  // pred: ^bb295
      cute.memref.store(%view_763, %48, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,2)">, f32) -> ()
      cf.br ^bb297
    ^bb297:  // 2 preds: ^bb295, ^bb296
      cf.cond_br %935, ^bb298, ^bb299
    ^bb298:  // pred: ^bb297
      cute.memref.store(%view_763, %47, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,3)">, f32) -> ()
      cf.br ^bb299
    ^bb299:  // 2 preds: ^bb297, ^bb298
      cf.cond_br %937, ^bb300, ^bb301
    ^bb300:  // pred: ^bb299
      cute.memref.store(%view_763, %46, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,4)">, f32) -> ()
      cf.br ^bb301
    ^bb301:  // 2 preds: ^bb299, ^bb300
      cf.cond_br %939, ^bb302, ^bb303
    ^bb302:  // pred: ^bb301
      cute.memref.store(%view_763, %45, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,5)">, f32) -> ()
      cf.br ^bb303
    ^bb303:  // 2 preds: ^bb301, ^bb302
      cf.cond_br %941, ^bb304, ^bb305
    ^bb304:  // pred: ^bb303
      cute.memref.store(%view_763, %44, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,6)">, f32) -> ()
      cf.br ^bb305
    ^bb305:  // 2 preds: ^bb303, ^bb304
      cf.cond_br %943, ^bb306, ^bb307
    ^bb306:  // pred: ^bb305
      cute.memref.store(%view_763, %43, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,7)">, f32) -> ()
      cf.br ^bb307
    ^bb307:  // 2 preds: ^bb305, ^bb306
      cf.cond_br %945, ^bb308, ^bb309
    ^bb308:  // pred: ^bb307
      cute.memref.store(%view_763, %42, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,8)">, f32) -> ()
      cf.br ^bb309
    ^bb309:  // 2 preds: ^bb307, ^bb308
      cf.cond_br %947, ^bb310, ^bb311
    ^bb310:  // pred: ^bb309
      cute.memref.store(%view_763, %41, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,9)">, f32) -> ()
      cf.br ^bb311
    ^bb311:  // 2 preds: ^bb309, ^bb310
      cf.cond_br %949, ^bb312, ^bb313
    ^bb312:  // pred: ^bb311
      cute.memref.store(%view_763, %40, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,10)">, f32) -> ()
      cf.br ^bb313
    ^bb313:  // 2 preds: ^bb311, ^bb312
      cf.cond_br %951, ^bb314, ^bb315
    ^bb314:  // pred: ^bb313
      cute.memref.store(%view_763, %39, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,11)">, f32) -> ()
      cf.br ^bb315
    ^bb315:  // 2 preds: ^bb313, ^bb314
      cf.cond_br %953, ^bb316, ^bb317
    ^bb316:  // pred: ^bb315
      cute.memref.store(%view_763, %38, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,12)">, f32) -> ()
      cf.br ^bb317
    ^bb317:  // 2 preds: ^bb315, ^bb316
      cf.cond_br %955, ^bb318, ^bb319
    ^bb318:  // pred: ^bb317
      cute.memref.store(%view_763, %37, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,13)">, f32) -> ()
      cf.br ^bb319
    ^bb319:  // 2 preds: ^bb317, ^bb318
      cf.cond_br %957, ^bb320, ^bb321
    ^bb320:  // pred: ^bb319
      cute.memref.store(%view_763, %36, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,14)">, f32) -> ()
      cf.br ^bb321
    ^bb321:  // 2 preds: ^bb319, ^bb320
      cf.cond_br %959, ^bb322, ^bb323
    ^bb322:  // pred: ^bb321
      cute.memref.store(%view_763, %35, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,15)">, f32) -> ()
      cf.br ^bb323
    ^bb323:  // 2 preds: ^bb321, ^bb322
      %ptr_898 = cute.add_offset(%iter_426, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_899 = cute.make_view(%ptr_898) : !memref_rmem_f32_6
      %985 = cute.memref.load_vec %view_899 : !memref_rmem_f32_6
      %986 = vector.reduction <maximumf>, %985, %cst_5 : vector<16xf32> into f32
      %987 = nvvm.shfl.sync  bfly %c-1_i32, %986, %c2_i32, %c31_i32 : f32 -> f32
      %988 = nvvm.fmax %986, %987
      %989 = nvvm.shfl.sync  bfly %c-1_i32, %988, %c1_i32, %c31_i32 : f32 -> f32
      %990 = nvvm.fmax %988, %989
      %991 = arith.mulf %985, %966 : vector<16xf32>
      %992 = arith.mulf %990, %arg4 : f32
      %993 = vector.broadcast %992 : f32 to vector<16xf32>
      %994 = arith.subf %991, %993 : vector<16xf32>
      %995 = math.exp2 %994 fastmath<fast> : vector<16xf32>
      %996 = vector.reduction <add>, %995, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_423, %34, %990) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store(%rmem_424, %34, %996) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store_vec %995, %view_899 : !memref_rmem_f32_6
      cf.cond_br %929, ^bb324, ^bb325
    ^bb324:  // pred: ^bb323
      cute.memref.store(%view_763, %33, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,0)">, f32) -> ()
      cf.br ^bb325
    ^bb325:  // 2 preds: ^bb323, ^bb324
      cf.cond_br %931, ^bb326, ^bb327
    ^bb326:  // pred: ^bb325
      cute.memref.store(%view_763, %32, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,1)">, f32) -> ()
      cf.br ^bb327
    ^bb327:  // 2 preds: ^bb325, ^bb326
      cf.cond_br %933, ^bb328, ^bb329
    ^bb328:  // pred: ^bb327
      cute.memref.store(%view_763, %31, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,2)">, f32) -> ()
      cf.br ^bb329
    ^bb329:  // 2 preds: ^bb327, ^bb328
      cf.cond_br %935, ^bb330, ^bb331
    ^bb330:  // pred: ^bb329
      cute.memref.store(%view_763, %30, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,3)">, f32) -> ()
      cf.br ^bb331
    ^bb331:  // 2 preds: ^bb329, ^bb330
      cf.cond_br %937, ^bb332, ^bb333
    ^bb332:  // pred: ^bb331
      cute.memref.store(%view_763, %29, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,4)">, f32) -> ()
      cf.br ^bb333
    ^bb333:  // 2 preds: ^bb331, ^bb332
      cf.cond_br %939, ^bb334, ^bb335
    ^bb334:  // pred: ^bb333
      cute.memref.store(%view_763, %28, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,5)">, f32) -> ()
      cf.br ^bb335
    ^bb335:  // 2 preds: ^bb333, ^bb334
      cf.cond_br %941, ^bb336, ^bb337
    ^bb336:  // pred: ^bb335
      cute.memref.store(%view_763, %27, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,6)">, f32) -> ()
      cf.br ^bb337
    ^bb337:  // 2 preds: ^bb335, ^bb336
      cf.cond_br %943, ^bb338, ^bb339
    ^bb338:  // pred: ^bb337
      cute.memref.store(%view_763, %26, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,7)">, f32) -> ()
      cf.br ^bb339
    ^bb339:  // 2 preds: ^bb337, ^bb338
      cf.cond_br %945, ^bb340, ^bb341
    ^bb340:  // pred: ^bb339
      cute.memref.store(%view_763, %25, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,8)">, f32) -> ()
      cf.br ^bb341
    ^bb341:  // 2 preds: ^bb339, ^bb340
      cf.cond_br %947, ^bb342, ^bb343
    ^bb342:  // pred: ^bb341
      cute.memref.store(%view_763, %24, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,9)">, f32) -> ()
      cf.br ^bb343
    ^bb343:  // 2 preds: ^bb341, ^bb342
      cf.cond_br %949, ^bb344, ^bb345
    ^bb344:  // pred: ^bb343
      cute.memref.store(%view_763, %23, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,10)">, f32) -> ()
      cf.br ^bb345
    ^bb345:  // 2 preds: ^bb343, ^bb344
      cf.cond_br %951, ^bb346, ^bb347
    ^bb346:  // pred: ^bb345
      cute.memref.store(%view_763, %22, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,11)">, f32) -> ()
      cf.br ^bb347
    ^bb347:  // 2 preds: ^bb345, ^bb346
      cf.cond_br %953, ^bb348, ^bb349
    ^bb348:  // pred: ^bb347
      cute.memref.store(%view_763, %21, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,12)">, f32) -> ()
      cf.br ^bb349
    ^bb349:  // 2 preds: ^bb347, ^bb348
      cf.cond_br %955, ^bb350, ^bb351
    ^bb350:  // pred: ^bb349
      cute.memref.store(%view_763, %20, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,13)">, f32) -> ()
      cf.br ^bb351
    ^bb351:  // 2 preds: ^bb349, ^bb350
      cf.cond_br %957, ^bb352, ^bb353
    ^bb352:  // pred: ^bb351
      cute.memref.store(%view_763, %19, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,14)">, f32) -> ()
      cf.br ^bb353
    ^bb353:  // 2 preds: ^bb351, ^bb352
      cf.cond_br %959, ^bb354, ^bb355
    ^bb354:  // pred: ^bb353
      cute.memref.store(%view_763, %18, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,15)">, f32) -> ()
      cf.br ^bb355
    ^bb355:  // 2 preds: ^bb353, ^bb354
      %ptr_900 = cute.add_offset(%iter_426, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_901 = cute.make_view(%ptr_900) : !memref_rmem_f32_5
      %997 = cute.memref.load_vec %view_901 : !memref_rmem_f32_5
      %998 = vector.reduction <maximumf>, %997, %cst_5 : vector<16xf32> into f32
      %999 = nvvm.shfl.sync  bfly %c-1_i32, %998, %c2_i32, %c31_i32 : f32 -> f32
      %1000 = nvvm.fmax %998, %999
      %1001 = nvvm.shfl.sync  bfly %c-1_i32, %1000, %c1_i32, %c31_i32 : f32 -> f32
      %1002 = nvvm.fmax %1000, %1001
      %1003 = arith.mulf %997, %966 : vector<16xf32>
      %1004 = arith.mulf %1002, %arg4 : f32
      %1005 = vector.broadcast %1004 : f32 to vector<16xf32>
      %1006 = arith.subf %1003, %1005 : vector<16xf32>
      %1007 = math.exp2 %1006 fastmath<fast> : vector<16xf32>
      %1008 = vector.reduction <add>, %1007, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_423, %17, %1002) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store(%rmem_424, %17, %1008) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store_vec %1007, %view_901 : !memref_rmem_f32_5
      %rmem_902 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_903 = cute.get_iter(%rmem_902) : !memref_rmem_bf16_3
      %1009 = cute.memref.load_vec %rmem_425 : !memref_rmem_f32_2
      %1010 = arith.truncf %1009 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1010, %rmem_902 : !memref_rmem_bf16_3
      %1011:2 = cute.get_scalars(%lay_119) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iv_904 = cute.assume(%1011#0) : (i32) -> !cute.i32<divby 16>
      %iv_905 = cute.assume(%1011#1) : (i32) -> !cute.i32<divby 32>
      %stride_906 = cute.make_stride(%iv_904, %iv_905) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_907 = cute.make_layout(%16, %stride_906) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %append_908 = cute.append_to_rank<2> (%lay_907, %181) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %1012:2 = cute.get_scalars(%append_908) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %iv_909 = cute.assume(%1012#0) : (i32) -> !cute.i32<divby 16>
      %iv_910 = cute.assume(%1012#1) : (i32) -> !cute.i32<divby 32>
      %stride_911 = cute.make_stride(%iv_909, %iv_910) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_912 = cute.make_layout(%15, %stride_911) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %append_913 = cute.append_to_rank<2> (%lay_912, %181) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1013:2 = cute.get_scalars(%append_913) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %iv_914 = cute.assume(%1013#0) : (i32) -> !cute.i32<divby 16>
      %iv_915 = cute.assume(%1013#1) : (i32) -> !cute.i32<divby 32>
      %stride_916 = cute.make_stride(%iv_914, %iv_915) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_917 = cute.make_layout(%14, %stride_916) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      cf.br ^bb356(%c0_i32 : i32)
    ^bb356(%1014: i32):  // 2 preds: ^bb355, ^bb357
      %1015 = arith.cmpi slt, %1014, %493 : i32
      cf.cond_br %1015, ^bb357, ^bb358 {llvm.loop_annotation = #loop_annotation}
    ^bb357:  // pred: ^bb356
      %coord_918 = cute.make_coord(%1014) : (i32) -> !cute.coord<"(_,?)">
      %idx_919 = cute.crd2idx(%coord_918, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_920 = cute.add_offset(%ptr_117, %idx_919) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_921 = cute.crd2idx(%coord_918, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_922 = cute.add_offset(%iter_120, %idx_921) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1016 = cute_nvgpu.arch.copy.ldsm %ptr_920{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1017 = vector.extractelement %1016[%130 : i32] : vector<4xi32>
      %1018 = builtin.unrealized_conversion_cast %ptr_922 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1017, %1018 : i32, !llvm.ptr
      %1019 = vector.extractelement %1016[%129 : i32] : vector<4xi32>
      %ptr_923 = cute.add_offset(%ptr_922, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1020 = builtin.unrealized_conversion_cast %ptr_923 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1019, %1020 : i32, !llvm.ptr
      %1021 = vector.extractelement %1016[%128 : i32] : vector<4xi32>
      %ptr_924 = cute.add_offset(%ptr_922, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1022 = builtin.unrealized_conversion_cast %ptr_924 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1021, %1022 : i32, !llvm.ptr
      %1023 = vector.extractelement %1016[%126 : i32] : vector<4xi32>
      %ptr_925 = cute.add_offset(%ptr_922, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1024 = builtin.unrealized_conversion_cast %ptr_925 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1023, %1024 : i32, !llvm.ptr
      %1025 = arith.addi %1014, %c1_i32 : i32
      cf.br ^bb356(%1025 : i32)
    ^bb358:  // pred: ^bb356
      %ptr_926 = cute.add_offset(%ptr_117, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_927 = cute.add_offset(%iter_120, %121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb359(%c0_i32 : i32)
    ^bb359(%1026: i32):  // 2 preds: ^bb358, ^bb360
      %1027 = arith.cmpi slt, %1026, %493 : i32
      cf.cond_br %1027, ^bb360, ^bb361 {llvm.loop_annotation = #loop_annotation}
    ^bb360:  // pred: ^bb359
      %coord_928 = cute.make_coord(%1026) : (i32) -> !cute.coord<"(_,?)">
      %idx_929 = cute.crd2idx(%coord_928, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_930 = cute.add_offset(%ptr_926, %idx_929) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_931 = cute.crd2idx(%coord_928, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_932 = cute.add_offset(%ptr_927, %idx_931) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1028 = cute_nvgpu.arch.copy.ldsm %ptr_930{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1029 = vector.extractelement %1028[%130 : i32] : vector<4xi32>
      %1030 = builtin.unrealized_conversion_cast %ptr_932 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1029, %1030 : i32, !llvm.ptr
      %1031 = vector.extractelement %1028[%129 : i32] : vector<4xi32>
      %ptr_933 = cute.add_offset(%ptr_932, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1032 = builtin.unrealized_conversion_cast %ptr_933 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1031, %1032 : i32, !llvm.ptr
      %1033 = vector.extractelement %1028[%128 : i32] : vector<4xi32>
      %ptr_934 = cute.add_offset(%ptr_932, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1034 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1033, %1034 : i32, !llvm.ptr
      %1035 = vector.extractelement %1028[%126 : i32] : vector<4xi32>
      %ptr_935 = cute.add_offset(%ptr_932, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1036 = builtin.unrealized_conversion_cast %ptr_935 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1035, %1036 : i32, !llvm.ptr
      %1037 = arith.addi %1026, %c1_i32 : i32
      cf.br ^bb359(%1037 : i32)
    ^bb361:  // pred: ^bb359
      %1038 = cute.get_scalars(%110) : !cute.int_tuple<"16">
      cf.br ^bb362(%c0_i32 : i32)
    ^bb362(%1039: i32):  // 2 preds: ^bb361, ^bb369
      %1040 = arith.cmpi slt, %1039, %492 : i32
      cf.cond_br %1040, ^bb363, ^bb370 {llvm.loop_annotation = #loop_annotation}
    ^bb363:  // pred: ^bb362
      cf.br ^bb364(%c0_i32 : i32)
    ^bb364(%1041: i32):  // 2 preds: ^bb363, ^bb368
      %1042 = arith.cmpi slt, %1041, %442 : i32
      cf.cond_br %1042, ^bb365, ^bb369 {llvm.loop_annotation = #loop_annotation}
    ^bb365:  // pred: ^bb364
      %coord_936 = cute.make_coord(%1041, %1039) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_937 = cute.crd2idx(%coord_936, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_938 = cute.add_offset(%iter_903, %idx_937) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1043 = builtin.unrealized_conversion_cast %ptr_938 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1044 = llvm.getelementptr %1043[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1045 = llvm.getelementptr %1043[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1046 = llvm.getelementptr %1043[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb366(%c0_i32 : i32)
    ^bb366(%1047: i32):  // 2 preds: ^bb365, ^bb367
      %1048 = arith.cmpi slt, %1047, %1038 : i32
      cf.cond_br %1048, ^bb367, ^bb368 {llvm.loop_annotation = #loop_annotation}
    ^bb367:  // pred: ^bb366
      %coord_939 = cute.make_coord(%1047, %1039) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_940 = cute.make_coord(%1041, %1047) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_941 = cute.crd2idx(%coord_939, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_942 = cute.add_offset(%iter_120, %idx_941) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_943 = cute.crd2idx(%coord_940, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_944 = cute.add_offset(%iter_97, %idx_943) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1049 = llvm.load %1043 : !llvm.ptr -> i32
      %1050 = llvm.load %1044 : !llvm.ptr -> i32
      %1051 = llvm.load %1045 : !llvm.ptr -> i32
      %1052 = llvm.load %1046 : !llvm.ptr -> i32
      %1053 = builtin.unrealized_conversion_cast %ptr_942 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1054 = llvm.load %1053 : !llvm.ptr -> i32
      %1055 = llvm.getelementptr %1053[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1056 = llvm.load %1055 : !llvm.ptr -> i32
      %1057 = builtin.unrealized_conversion_cast %ptr_944 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1058 = llvm.load %1057 : !llvm.ptr -> f32
      %1059 = llvm.getelementptr %1057[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1060 = llvm.load %1059 : !llvm.ptr -> f32
      %1061 = llvm.getelementptr %1057[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1062 = llvm.load %1061 : !llvm.ptr -> f32
      %1063 = llvm.getelementptr %1057[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1064 = llvm.load %1063 : !llvm.ptr -> f32
      %1065:4 = cute_nvgpu.arch.mma.SM80 A[%1049, %1050, %1051, %1052]  B[%1054, %1056]  C[%1058, %1060, %1062, %1064] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1065#0, %1057 : f32, !llvm.ptr
      llvm.store %1065#1, %1059 : f32, !llvm.ptr
      llvm.store %1065#2, %1061 : f32, !llvm.ptr
      llvm.store %1065#3, %1063 : f32, !llvm.ptr
      %1066 = arith.addi %1047, %c1_i32 : i32
      cf.br ^bb366(%1066 : i32)
    ^bb368:  // pred: ^bb366
      %1067 = arith.addi %1041, %c1_i32 : i32
      cf.br ^bb364(%1067 : i32)
    ^bb369:  // pred: ^bb364
      %1068 = arith.addi %1039, %c1_i32 : i32
      cf.br ^bb362(%1068 : i32)
    ^bb370:  // pred: ^bb362
      %ptr_945 = cute.add_offset(%ptr_117, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_946 = cute.add_offset(%iter_120, %120) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb371(%c0_i32 : i32)
    ^bb371(%1069: i32):  // 2 preds: ^bb370, ^bb372
      %1070 = arith.cmpi slt, %1069, %493 : i32
      cf.cond_br %1070, ^bb372, ^bb373 {llvm.loop_annotation = #loop_annotation}
    ^bb372:  // pred: ^bb371
      %coord_947 = cute.make_coord(%1069) : (i32) -> !cute.coord<"(_,?)">
      %idx_948 = cute.crd2idx(%coord_947, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_949 = cute.add_offset(%ptr_945, %idx_948) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_950 = cute.crd2idx(%coord_947, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_951 = cute.add_offset(%ptr_946, %idx_950) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1071 = cute_nvgpu.arch.copy.ldsm %ptr_949{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1072 = vector.extractelement %1071[%130 : i32] : vector<4xi32>
      %1073 = builtin.unrealized_conversion_cast %ptr_951 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1072, %1073 : i32, !llvm.ptr
      %1074 = vector.extractelement %1071[%129 : i32] : vector<4xi32>
      %ptr_952 = cute.add_offset(%ptr_951, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1075 = builtin.unrealized_conversion_cast %ptr_952 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1074, %1075 : i32, !llvm.ptr
      %1076 = vector.extractelement %1071[%128 : i32] : vector<4xi32>
      %ptr_953 = cute.add_offset(%ptr_951, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1077 = builtin.unrealized_conversion_cast %ptr_953 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1076, %1077 : i32, !llvm.ptr
      %1078 = vector.extractelement %1071[%126 : i32] : vector<4xi32>
      %ptr_954 = cute.add_offset(%ptr_951, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1079 = builtin.unrealized_conversion_cast %ptr_954 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1078, %1079 : i32, !llvm.ptr
      %1080 = arith.addi %1069, %c1_i32 : i32
      cf.br ^bb371(%1080 : i32)
    ^bb373:  // pred: ^bb371
      %ptr_955 = cute.add_offset(%iter_903, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb374(%c0_i32 : i32)
    ^bb374(%1081: i32):  // 2 preds: ^bb373, ^bb381
      %1082 = arith.cmpi slt, %1081, %492 : i32
      cf.cond_br %1082, ^bb375, ^bb382 {llvm.loop_annotation = #loop_annotation}
    ^bb375:  // pred: ^bb374
      cf.br ^bb376(%c0_i32 : i32)
    ^bb376(%1083: i32):  // 2 preds: ^bb375, ^bb380
      %1084 = arith.cmpi slt, %1083, %442 : i32
      cf.cond_br %1084, ^bb377, ^bb381 {llvm.loop_annotation = #loop_annotation}
    ^bb377:  // pred: ^bb376
      %coord_956 = cute.make_coord(%1083, %1081) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_957 = cute.crd2idx(%coord_956, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_958 = cute.add_offset(%ptr_955, %idx_957) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1085 = builtin.unrealized_conversion_cast %ptr_958 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1086 = llvm.getelementptr %1085[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1087 = llvm.getelementptr %1085[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1088 = llvm.getelementptr %1085[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb378(%c0_i32 : i32)
    ^bb378(%1089: i32):  // 2 preds: ^bb377, ^bb379
      %1090 = arith.cmpi slt, %1089, %1038 : i32
      cf.cond_br %1090, ^bb379, ^bb380 {llvm.loop_annotation = #loop_annotation}
    ^bb379:  // pred: ^bb378
      %coord_959 = cute.make_coord(%1089, %1081) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_960 = cute.make_coord(%1083, %1089) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_961 = cute.crd2idx(%coord_959, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_962 = cute.add_offset(%ptr_927, %idx_961) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_963 = cute.crd2idx(%coord_960, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_964 = cute.add_offset(%iter_97, %idx_963) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1091 = llvm.load %1085 : !llvm.ptr -> i32
      %1092 = llvm.load %1086 : !llvm.ptr -> i32
      %1093 = llvm.load %1087 : !llvm.ptr -> i32
      %1094 = llvm.load %1088 : !llvm.ptr -> i32
      %1095 = builtin.unrealized_conversion_cast %ptr_962 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1096 = llvm.load %1095 : !llvm.ptr -> i32
      %1097 = llvm.getelementptr %1095[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1098 = llvm.load %1097 : !llvm.ptr -> i32
      %1099 = builtin.unrealized_conversion_cast %ptr_964 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1100 = llvm.load %1099 : !llvm.ptr -> f32
      %1101 = llvm.getelementptr %1099[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1102 = llvm.load %1101 : !llvm.ptr -> f32
      %1103 = llvm.getelementptr %1099[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1104 = llvm.load %1103 : !llvm.ptr -> f32
      %1105 = llvm.getelementptr %1099[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1106 = llvm.load %1105 : !llvm.ptr -> f32
      %1107:4 = cute_nvgpu.arch.mma.SM80 A[%1091, %1092, %1093, %1094]  B[%1096, %1098]  C[%1100, %1102, %1104, %1106] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1107#0, %1099 : f32, !llvm.ptr
      llvm.store %1107#1, %1101 : f32, !llvm.ptr
      llvm.store %1107#2, %1103 : f32, !llvm.ptr
      llvm.store %1107#3, %1105 : f32, !llvm.ptr
      %1108 = arith.addi %1089, %c1_i32 : i32
      cf.br ^bb378(%1108 : i32)
    ^bb380:  // pred: ^bb378
      %1109 = arith.addi %1083, %c1_i32 : i32
      cf.br ^bb376(%1109 : i32)
    ^bb381:  // pred: ^bb376
      %1110 = arith.addi %1081, %c1_i32 : i32
      cf.br ^bb374(%1110 : i32)
    ^bb382:  // pred: ^bb374
      %ptr_965 = cute.add_offset(%ptr_117, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_966 = cute.add_offset(%iter_120, %113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb383(%c0_i32 : i32)
    ^bb383(%1111: i32):  // 2 preds: ^bb382, ^bb384
      %1112 = arith.cmpi slt, %1111, %493 : i32
      cf.cond_br %1112, ^bb384, ^bb385 {llvm.loop_annotation = #loop_annotation}
    ^bb384:  // pred: ^bb383
      %coord_967 = cute.make_coord(%1111) : (i32) -> !cute.coord<"(_,?)">
      %idx_968 = cute.crd2idx(%coord_967, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_969 = cute.add_offset(%ptr_965, %idx_968) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_970 = cute.crd2idx(%coord_967, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_971 = cute.add_offset(%ptr_966, %idx_970) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1113 = cute_nvgpu.arch.copy.ldsm %ptr_969{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1114 = vector.extractelement %1113[%130 : i32] : vector<4xi32>
      %1115 = builtin.unrealized_conversion_cast %ptr_971 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1114, %1115 : i32, !llvm.ptr
      %1116 = vector.extractelement %1113[%129 : i32] : vector<4xi32>
      %ptr_972 = cute.add_offset(%ptr_971, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1117 = builtin.unrealized_conversion_cast %ptr_972 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1116, %1117 : i32, !llvm.ptr
      %1118 = vector.extractelement %1113[%128 : i32] : vector<4xi32>
      %ptr_973 = cute.add_offset(%ptr_971, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1119 = builtin.unrealized_conversion_cast %ptr_973 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1118, %1119 : i32, !llvm.ptr
      %1120 = vector.extractelement %1113[%126 : i32] : vector<4xi32>
      %ptr_974 = cute.add_offset(%ptr_971, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1121 = builtin.unrealized_conversion_cast %ptr_974 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1120, %1121 : i32, !llvm.ptr
      %1122 = arith.addi %1111, %c1_i32 : i32
      cf.br ^bb383(%1122 : i32)
    ^bb385:  // pred: ^bb383
      %ptr_975 = cute.add_offset(%iter_903, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb386(%c0_i32 : i32)
    ^bb386(%1123: i32):  // 2 preds: ^bb385, ^bb393
      %1124 = arith.cmpi slt, %1123, %492 : i32
      cf.cond_br %1124, ^bb387, ^bb394 {llvm.loop_annotation = #loop_annotation}
    ^bb387:  // pred: ^bb386
      cf.br ^bb388(%c0_i32 : i32)
    ^bb388(%1125: i32):  // 2 preds: ^bb387, ^bb392
      %1126 = arith.cmpi slt, %1125, %442 : i32
      cf.cond_br %1126, ^bb389, ^bb393 {llvm.loop_annotation = #loop_annotation}
    ^bb389:  // pred: ^bb388
      %coord_976 = cute.make_coord(%1125, %1123) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_977 = cute.crd2idx(%coord_976, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_978 = cute.add_offset(%ptr_975, %idx_977) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1127 = builtin.unrealized_conversion_cast %ptr_978 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1128 = llvm.getelementptr %1127[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1129 = llvm.getelementptr %1127[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1130 = llvm.getelementptr %1127[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb390(%c0_i32 : i32)
    ^bb390(%1131: i32):  // 2 preds: ^bb389, ^bb391
      %1132 = arith.cmpi slt, %1131, %1038 : i32
      cf.cond_br %1132, ^bb391, ^bb392 {llvm.loop_annotation = #loop_annotation}
    ^bb391:  // pred: ^bb390
      %coord_979 = cute.make_coord(%1131, %1123) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_980 = cute.make_coord(%1125, %1131) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_981 = cute.crd2idx(%coord_979, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_982 = cute.add_offset(%ptr_946, %idx_981) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_983 = cute.crd2idx(%coord_980, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_984 = cute.add_offset(%iter_97, %idx_983) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1133 = llvm.load %1127 : !llvm.ptr -> i32
      %1134 = llvm.load %1128 : !llvm.ptr -> i32
      %1135 = llvm.load %1129 : !llvm.ptr -> i32
      %1136 = llvm.load %1130 : !llvm.ptr -> i32
      %1137 = builtin.unrealized_conversion_cast %ptr_982 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1138 = llvm.load %1137 : !llvm.ptr -> i32
      %1139 = llvm.getelementptr %1137[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1140 = llvm.load %1139 : !llvm.ptr -> i32
      %1141 = builtin.unrealized_conversion_cast %ptr_984 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1142 = llvm.load %1141 : !llvm.ptr -> f32
      %1143 = llvm.getelementptr %1141[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1144 = llvm.load %1143 : !llvm.ptr -> f32
      %1145 = llvm.getelementptr %1141[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1146 = llvm.load %1145 : !llvm.ptr -> f32
      %1147 = llvm.getelementptr %1141[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1148 = llvm.load %1147 : !llvm.ptr -> f32
      %1149:4 = cute_nvgpu.arch.mma.SM80 A[%1133, %1134, %1135, %1136]  B[%1138, %1140]  C[%1142, %1144, %1146, %1148] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1149#0, %1141 : f32, !llvm.ptr
      llvm.store %1149#1, %1143 : f32, !llvm.ptr
      llvm.store %1149#2, %1145 : f32, !llvm.ptr
      llvm.store %1149#3, %1147 : f32, !llvm.ptr
      %1150 = arith.addi %1131, %c1_i32 : i32
      cf.br ^bb390(%1150 : i32)
    ^bb392:  // pred: ^bb390
      %1151 = arith.addi %1125, %c1_i32 : i32
      cf.br ^bb388(%1151 : i32)
    ^bb393:  // pred: ^bb388
      %1152 = arith.addi %1123, %c1_i32 : i32
      cf.br ^bb386(%1152 : i32)
    ^bb394:  // pred: ^bb386
      cf.br ^bb395(%c0_i32 : i32)
    ^bb395(%1153: i32):  // 2 preds: ^bb394, ^bb396
      %1154 = arith.cmpi slt, %1153, %493 : i32
      cf.cond_br %1154, ^bb396, ^bb397 {llvm.loop_annotation = #loop_annotation}
    ^bb396:  // pred: ^bb395
      %coord_985 = cute.make_coord(%1153) : (i32) -> !cute.coord<"(_,?)">
      %idx_986 = cute.crd2idx(%coord_985, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_987 = cute.add_offset(%ptr_117, %idx_986) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_988 = cute.crd2idx(%coord_985, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_989 = cute.add_offset(%iter_120, %idx_988) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1155 = cute_nvgpu.arch.copy.ldsm %ptr_987{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1156 = vector.extractelement %1155[%130 : i32] : vector<4xi32>
      %1157 = builtin.unrealized_conversion_cast %ptr_989 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1156, %1157 : i32, !llvm.ptr
      %1158 = vector.extractelement %1155[%129 : i32] : vector<4xi32>
      %ptr_990 = cute.add_offset(%ptr_989, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1159 = builtin.unrealized_conversion_cast %ptr_990 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1158, %1159 : i32, !llvm.ptr
      %1160 = vector.extractelement %1155[%128 : i32] : vector<4xi32>
      %ptr_991 = cute.add_offset(%ptr_989, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1161 = builtin.unrealized_conversion_cast %ptr_991 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1160, %1161 : i32, !llvm.ptr
      %1162 = vector.extractelement %1155[%126 : i32] : vector<4xi32>
      %ptr_992 = cute.add_offset(%ptr_989, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1163 = builtin.unrealized_conversion_cast %ptr_992 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1162, %1163 : i32, !llvm.ptr
      %1164 = arith.addi %1153, %c1_i32 : i32
      cf.br ^bb395(%1164 : i32)
    ^bb397:  // pred: ^bb395
      %ptr_993 = cute.add_offset(%iter_903, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb398(%c0_i32 : i32)
    ^bb398(%1165: i32):  // 2 preds: ^bb397, ^bb405
      %1166 = arith.cmpi slt, %1165, %492 : i32
      cf.cond_br %1166, ^bb399, ^bb406 {llvm.loop_annotation = #loop_annotation}
    ^bb399:  // pred: ^bb398
      cf.br ^bb400(%c0_i32 : i32)
    ^bb400(%1167: i32):  // 2 preds: ^bb399, ^bb404
      %1168 = arith.cmpi slt, %1167, %442 : i32
      cf.cond_br %1168, ^bb401, ^bb405 {llvm.loop_annotation = #loop_annotation}
    ^bb401:  // pred: ^bb400
      %coord_994 = cute.make_coord(%1167, %1165) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_995 = cute.crd2idx(%coord_994, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_996 = cute.add_offset(%ptr_993, %idx_995) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1169 = builtin.unrealized_conversion_cast %ptr_996 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1170 = llvm.getelementptr %1169[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1171 = llvm.getelementptr %1169[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1172 = llvm.getelementptr %1169[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb402(%c0_i32 : i32)
    ^bb402(%1173: i32):  // 2 preds: ^bb401, ^bb403
      %1174 = arith.cmpi slt, %1173, %1038 : i32
      cf.cond_br %1174, ^bb403, ^bb404 {llvm.loop_annotation = #loop_annotation}
    ^bb403:  // pred: ^bb402
      %coord_997 = cute.make_coord(%1173, %1165) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_998 = cute.make_coord(%1167, %1173) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_999 = cute.crd2idx(%coord_997, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1000 = cute.add_offset(%ptr_966, %idx_999) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1001 = cute.crd2idx(%coord_998, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1002 = cute.add_offset(%iter_97, %idx_1001) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1175 = llvm.load %1169 : !llvm.ptr -> i32
      %1176 = llvm.load %1170 : !llvm.ptr -> i32
      %1177 = llvm.load %1171 : !llvm.ptr -> i32
      %1178 = llvm.load %1172 : !llvm.ptr -> i32
      %1179 = builtin.unrealized_conversion_cast %ptr_1000 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1180 = llvm.load %1179 : !llvm.ptr -> i32
      %1181 = llvm.getelementptr %1179[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1182 = llvm.load %1181 : !llvm.ptr -> i32
      %1183 = builtin.unrealized_conversion_cast %ptr_1002 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1184 = llvm.load %1183 : !llvm.ptr -> f32
      %1185 = llvm.getelementptr %1183[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1186 = llvm.load %1185 : !llvm.ptr -> f32
      %1187 = llvm.getelementptr %1183[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1188 = llvm.load %1187 : !llvm.ptr -> f32
      %1189 = llvm.getelementptr %1183[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1190 = llvm.load %1189 : !llvm.ptr -> f32
      %1191:4 = cute_nvgpu.arch.mma.SM80 A[%1175, %1176, %1177, %1178]  B[%1180, %1182]  C[%1184, %1186, %1188, %1190] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1191#0, %1183 : f32, !llvm.ptr
      llvm.store %1191#1, %1185 : f32, !llvm.ptr
      llvm.store %1191#2, %1187 : f32, !llvm.ptr
      llvm.store %1191#3, %1189 : f32, !llvm.ptr
      %1192 = arith.addi %1173, %c1_i32 : i32
      cf.br ^bb402(%1192 : i32)
    ^bb404:  // pred: ^bb402
      %1193 = arith.addi %1167, %c1_i32 : i32
      cf.br ^bb400(%1193 : i32)
    ^bb405:  // pred: ^bb400
      %1194 = arith.addi %1165, %c1_i32 : i32
      cf.br ^bb398(%1194 : i32)
    ^bb406:  // pred: ^bb398
      %1195:3 = cute.get_scalars(%lay_92) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_1003 = cute.assume(%1195#1) : (i64) -> !cute.i64<divby 128>
      %stride_1004 = cute.make_stride(%iv_1003) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1005 = cute.make_layout(%137, %stride_1004) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %append_1006 = cute.append_to_rank<2> (%lay_1005, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1196 = cute.get_scalars(%append_1006) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_1007 = cute.assume(%1196) : (i64) -> !cute.i64<divby 128>
      %stride_1008 = cute.make_stride(%iv_1007) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_1009 = cute.make_layout(%136, %stride_1008) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_1010 = cute.append_to_rank<2> (%lay_1009, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1197 = cute.get_scalars(%append_1010) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_1011 = cute.assume(%1197) : (i64) -> !cute.i64<divby 128>
      %stride_1012 = cute.make_stride(%iv_1011) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_1013 = cute.make_layout(%135, %stride_1012) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      %iter_1014 = cute.get_iter(%rmem_423) : !memref_rmem_f32_1
      %1198 = builtin.unrealized_conversion_cast %iter_1014 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_1015 = cute.add_offset(%iter_1014, %117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %1199 = builtin.unrealized_conversion_cast %ptr_1015 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_1016 = cute.add_offset(%iter_1014, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %1200 = builtin.unrealized_conversion_cast %ptr_1016 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_1017 = cute.add_offset(%iter_1014, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %1201 = builtin.unrealized_conversion_cast %ptr_1017 : !cute.ptr<f32, rmem> to !llvm.ptr
      %view_1018 = cute.make_view(%iter_97) : !memref_rmem_f32_7
      %ptr_1019 = cute.add_offset(%iter_97, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1020 = cute.make_view(%ptr_1019) : !memref_rmem_f32_8
      %ptr_1021 = cute.add_offset(%iter_97, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1022 = cute.make_view(%ptr_1021) : !memref_rmem_f32_9
      %ptr_1023 = cute.add_offset(%iter_97, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1024 = cute.make_view(%ptr_1023) : !memref_rmem_f32_8
      cf.br ^bb407(%c1_i32 : i32)
    ^bb407(%1202: i32):  // 2 preds: ^bb406, ^bb596
      %1203 = arith.cmpi slt, %1202, %189 : i32
      cf.cond_br %1203, ^bb408, ^bb597
    ^bb408:  // pred: ^bb407
      %1204 = arith.subi %189, %1202 : i32
      %1205 = arith.subi %1204, %c1_i32 : i32
      %rmem_1025 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_1026 = cute.get_iter(%rmem_1025) : !memref_rmem_f32_2
      cute.memref.store_vec %cst, %rmem_1025 : !memref_rmem_f32_2
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %coord_1027 = cute.make_coord(%1205) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_1028 = cute.crd2idx(%coord_1027, %lay_92) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1029 = cute.add_offset(%ptr_87, %idx_1028) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      cf.br ^bb409(%c0_i32 : i32)
    ^bb409(%1206: i32):  // 2 preds: ^bb408, ^bb410
      %1207 = arith.cmpi slt, %1206, %493 : i32
      cf.cond_br %1207, ^bb410, ^bb411 {llvm.loop_annotation = #loop_annotation}
    ^bb410:  // pred: ^bb409
      %coord_1030 = cute.make_coord(%1206) : (i32) -> !cute.coord<"(_,?)">
      %idx_1031 = cute.crd2idx(%coord_1030, %lay_1013) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_1032 = cute.add_offset(%ptr_1029, %idx_1031) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1033 = cute.crd2idx(%coord_1030, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1034 = cute.add_offset(%ptr_93, %idx_1033) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1035 = cute.crd2idx(%coord_1030, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_1036 = cute.add_offset(%iter_161, %idx_1035) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1208 = builtin.unrealized_conversion_cast %ptr_1036 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1209 = llvm.load %1208 : !llvm.ptr -> i8
      %1210 = llvm.trunc %1209 : i8 to i1
      %iter_1037 = cute.recast_iter(%ptr_1032) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_1038 = cute.recast_iter(%ptr_1034) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_1038 : !cute.ptr<i128, smem>, %iter_1037 : !cute.ptr<i128, gmem>, %1210 : i1) {cache_mode = <global>}
      %1211 = arith.addi %1206, %c1_i32 : i32
      cf.br ^bb409(%1211 : i32)
    ^bb411:  // pred: ^bb409
      nvvm.cp.async.commit.group
      cf.br ^bb412(%c0_i32 : i32)
    ^bb412(%1212: i32):  // 2 preds: ^bb411, ^bb413
      %1213 = arith.cmpi slt, %1212, %442 : i32
      cf.cond_br %1213, ^bb413, ^bb414 {llvm.loop_annotation = #loop_annotation}
    ^bb413:  // pred: ^bb412
      %coord_1039 = cute.make_coord(%1212) : (i32) -> !cute.coord<"(_,?)">
      %idx_1040 = cute.crd2idx(%coord_1039, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1041 = cute.add_offset(%ptr_101, %idx_1040) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1042 = cute.crd2idx(%coord_1039, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1043 = cute.add_offset(%iter_106, %idx_1042) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1214 = cute_nvgpu.arch.copy.ldsm %ptr_1041{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1215 = vector.extractelement %1214[%130 : i32] : vector<4xi32>
      %1216 = builtin.unrealized_conversion_cast %ptr_1043 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1215, %1216 : i32, !llvm.ptr
      %1217 = vector.extractelement %1214[%129 : i32] : vector<4xi32>
      %ptr_1044 = cute.add_offset(%ptr_1043, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1218 = builtin.unrealized_conversion_cast %ptr_1044 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1217, %1218 : i32, !llvm.ptr
      %1219 = vector.extractelement %1214[%128 : i32] : vector<4xi32>
      %ptr_1045 = cute.add_offset(%ptr_1043, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1220 = builtin.unrealized_conversion_cast %ptr_1045 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1219, %1220 : i32, !llvm.ptr
      %1221 = vector.extractelement %1214[%126 : i32] : vector<4xi32>
      %ptr_1046 = cute.add_offset(%ptr_1043, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1222 = builtin.unrealized_conversion_cast %ptr_1046 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1221, %1222 : i32, !llvm.ptr
      %1223 = arith.addi %1212, %c1_i32 : i32
      cf.br ^bb412(%1223 : i32)
    ^bb414:  // pred: ^bb412
      cf.br ^bb415(%c0_i32 : i32)
    ^bb415(%1224: i32):  // 2 preds: ^bb414, ^bb416
      %1225 = arith.cmpi slt, %1224, %455 : i32
      cf.cond_br %1225, ^bb416, ^bb417 {llvm.loop_annotation = #loop_annotation}
    ^bb416:  // pred: ^bb415
      %coord_1047 = cute.make_coord(%1224) : (i32) -> !cute.coord<"(_,?)">
      %idx_1048 = cute.crd2idx(%coord_1047, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1049 = cute.add_offset(%ptr_109, %idx_1048) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1050 = cute.crd2idx(%coord_1047, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1051 = cute.add_offset(%iter_114, %idx_1050) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1226 = cute_nvgpu.arch.copy.ldsm %ptr_1049{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1227 = vector.extractelement %1226[%130 : i32] : vector<4xi32>
      %1228 = builtin.unrealized_conversion_cast %ptr_1051 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1227, %1228 : i32, !llvm.ptr
      %1229 = vector.extractelement %1226[%129 : i32] : vector<4xi32>
      %ptr_1052 = cute.add_offset(%ptr_1051, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1230 = builtin.unrealized_conversion_cast %ptr_1052 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1229, %1230 : i32, !llvm.ptr
      %1231 = vector.extractelement %1226[%128 : i32] : vector<4xi32>
      %ptr_1053 = cute.add_offset(%ptr_1051, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1232 = builtin.unrealized_conversion_cast %ptr_1053 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1231, %1232 : i32, !llvm.ptr
      %1233 = vector.extractelement %1226[%126 : i32] : vector<4xi32>
      %ptr_1054 = cute.add_offset(%ptr_1051, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1234 = builtin.unrealized_conversion_cast %ptr_1054 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1233, %1234 : i32, !llvm.ptr
      %1235 = arith.addi %1224, %c1_i32 : i32
      cf.br ^bb415(%1235 : i32)
    ^bb417:  // pred: ^bb415
      cf.br ^bb418(%c0_i32 : i32)
    ^bb418(%1236: i32):  // 2 preds: ^bb417, ^bb419
      %1237 = arith.cmpi slt, %1236, %442 : i32
      cf.cond_br %1237, ^bb419, ^bb420 {llvm.loop_annotation = #loop_annotation}
    ^bb419:  // pred: ^bb418
      %coord_1055 = cute.make_coord(%1236) : (i32) -> !cute.coord<"(_,?)">
      %idx_1056 = cute.crd2idx(%coord_1055, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1057 = cute.add_offset(%ptr_502, %idx_1056) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1058 = cute.crd2idx(%coord_1055, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1059 = cute.add_offset(%ptr_503, %idx_1058) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1238 = cute_nvgpu.arch.copy.ldsm %ptr_1057{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1239 = vector.extractelement %1238[%130 : i32] : vector<4xi32>
      %1240 = builtin.unrealized_conversion_cast %ptr_1059 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1239, %1240 : i32, !llvm.ptr
      %1241 = vector.extractelement %1238[%129 : i32] : vector<4xi32>
      %ptr_1060 = cute.add_offset(%ptr_1059, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1242 = builtin.unrealized_conversion_cast %ptr_1060 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1241, %1242 : i32, !llvm.ptr
      %1243 = vector.extractelement %1238[%128 : i32] : vector<4xi32>
      %ptr_1061 = cute.add_offset(%ptr_1059, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1244 = builtin.unrealized_conversion_cast %ptr_1061 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1243, %1244 : i32, !llvm.ptr
      %1245 = vector.extractelement %1238[%126 : i32] : vector<4xi32>
      %ptr_1062 = cute.add_offset(%ptr_1059, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1246 = builtin.unrealized_conversion_cast %ptr_1062 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1245, %1246 : i32, !llvm.ptr
      %1247 = arith.addi %1236, %c1_i32 : i32
      cf.br ^bb418(%1247 : i32)
    ^bb420:  // pred: ^bb418
      cf.br ^bb421(%c0_i32 : i32)
    ^bb421(%1248: i32):  // 2 preds: ^bb420, ^bb422
      %1249 = arith.cmpi slt, %1248, %455 : i32
      cf.cond_br %1249, ^bb422, ^bb423 {llvm.loop_annotation = #loop_annotation}
    ^bb422:  // pred: ^bb421
      %coord_1063 = cute.make_coord(%1248) : (i32) -> !cute.coord<"(_,?)">
      %idx_1064 = cute.crd2idx(%coord_1063, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1065 = cute.add_offset(%ptr_513, %idx_1064) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1066 = cute.crd2idx(%coord_1063, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1067 = cute.add_offset(%ptr_514, %idx_1066) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1250 = cute_nvgpu.arch.copy.ldsm %ptr_1065{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1251 = vector.extractelement %1250[%130 : i32] : vector<4xi32>
      %1252 = builtin.unrealized_conversion_cast %ptr_1067 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1251, %1252 : i32, !llvm.ptr
      %1253 = vector.extractelement %1250[%129 : i32] : vector<4xi32>
      %ptr_1068 = cute.add_offset(%ptr_1067, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1254 = builtin.unrealized_conversion_cast %ptr_1068 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1253, %1254 : i32, !llvm.ptr
      %1255 = vector.extractelement %1250[%128 : i32] : vector<4xi32>
      %ptr_1069 = cute.add_offset(%ptr_1067, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1256 = builtin.unrealized_conversion_cast %ptr_1069 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1255, %1256 : i32, !llvm.ptr
      %1257 = vector.extractelement %1250[%126 : i32] : vector<4xi32>
      %ptr_1070 = cute.add_offset(%ptr_1067, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1258 = builtin.unrealized_conversion_cast %ptr_1070 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1257, %1258 : i32, !llvm.ptr
      %1259 = arith.addi %1248, %c1_i32 : i32
      cf.br ^bb421(%1259 : i32)
    ^bb423:  // pred: ^bb421
      cf.br ^bb424(%c0_i32 : i32)
    ^bb424(%1260: i32):  // 2 preds: ^bb423, ^bb431
      %1261 = arith.cmpi slt, %1260, %492 : i32
      cf.cond_br %1261, ^bb425, ^bb432 {llvm.loop_annotation = #loop_annotation}
    ^bb425:  // pred: ^bb424
      cf.br ^bb426(%c0_i32 : i32)
    ^bb426(%1262: i32):  // 2 preds: ^bb425, ^bb430
      %1263 = arith.cmpi slt, %1262, %442 : i32
      cf.cond_br %1263, ^bb427, ^bb431 {llvm.loop_annotation = #loop_annotation}
    ^bb427:  // pred: ^bb426
      %coord_1071 = cute.make_coord(%1262, %1260) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1072 = cute.crd2idx(%coord_1071, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1073 = cute.add_offset(%iter_106, %idx_1072) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1264 = builtin.unrealized_conversion_cast %ptr_1073 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1265 = llvm.getelementptr %1264[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1266 = llvm.getelementptr %1264[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1267 = llvm.getelementptr %1264[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb428(%c0_i32 : i32)
    ^bb428(%1268: i32):  // 2 preds: ^bb427, ^bb429
      %1269 = arith.cmpi slt, %1268, %493 : i32
      cf.cond_br %1269, ^bb429, ^bb430 {llvm.loop_annotation = #loop_annotation}
    ^bb429:  // pred: ^bb428
      %coord_1074 = cute.make_coord(%1268, %1260) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1075 = cute.make_coord(%1262, %1268) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1076 = cute.crd2idx(%coord_1074, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1077 = cute.add_offset(%iter_114, %idx_1076) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1078 = cute.crd2idx(%coord_1075, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1079 = cute.add_offset(%iter_1026, %idx_1078) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1270 = llvm.load %1264 : !llvm.ptr -> i32
      %1271 = llvm.load %1265 : !llvm.ptr -> i32
      %1272 = llvm.load %1266 : !llvm.ptr -> i32
      %1273 = llvm.load %1267 : !llvm.ptr -> i32
      %1274 = builtin.unrealized_conversion_cast %ptr_1077 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1275 = llvm.load %1274 : !llvm.ptr -> i32
      %1276 = llvm.getelementptr %1274[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1277 = llvm.load %1276 : !llvm.ptr -> i32
      %1278 = builtin.unrealized_conversion_cast %ptr_1079 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1279 = llvm.load %1278 : !llvm.ptr -> f32
      %1280 = llvm.getelementptr %1278[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1281 = llvm.load %1280 : !llvm.ptr -> f32
      %1282 = llvm.getelementptr %1278[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1283 = llvm.load %1282 : !llvm.ptr -> f32
      %1284 = llvm.getelementptr %1278[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1285 = llvm.load %1284 : !llvm.ptr -> f32
      %1286:4 = cute_nvgpu.arch.mma.SM80 A[%1270, %1271, %1272, %1273]  B[%1275, %1277]  C[%1279, %1281, %1283, %1285] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1286#0, %1278 : f32, !llvm.ptr
      llvm.store %1286#1, %1280 : f32, !llvm.ptr
      llvm.store %1286#2, %1282 : f32, !llvm.ptr
      llvm.store %1286#3, %1284 : f32, !llvm.ptr
      %1287 = arith.addi %1268, %c1_i32 : i32
      cf.br ^bb428(%1287 : i32)
    ^bb430:  // pred: ^bb428
      %1288 = arith.addi %1262, %c1_i32 : i32
      cf.br ^bb426(%1288 : i32)
    ^bb431:  // pred: ^bb426
      %1289 = arith.addi %1260, %c1_i32 : i32
      cf.br ^bb424(%1289 : i32)
    ^bb432:  // pred: ^bb424
      cf.br ^bb433(%c0_i32 : i32)
    ^bb433(%1290: i32):  // 2 preds: ^bb432, ^bb434
      %1291 = arith.cmpi slt, %1290, %442 : i32
      cf.cond_br %1291, ^bb434, ^bb435 {llvm.loop_annotation = #loop_annotation}
    ^bb434:  // pred: ^bb433
      %coord_1080 = cute.make_coord(%1290) : (i32) -> !cute.coord<"(_,?)">
      %idx_1081 = cute.crd2idx(%coord_1080, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1082 = cute.add_offset(%ptr_533, %idx_1081) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1083 = cute.crd2idx(%coord_1080, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1084 = cute.add_offset(%ptr_534, %idx_1083) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1292 = cute_nvgpu.arch.copy.ldsm %ptr_1082{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1293 = vector.extractelement %1292[%130 : i32] : vector<4xi32>
      %1294 = builtin.unrealized_conversion_cast %ptr_1084 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1293, %1294 : i32, !llvm.ptr
      %1295 = vector.extractelement %1292[%129 : i32] : vector<4xi32>
      %ptr_1085 = cute.add_offset(%ptr_1084, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1296 = builtin.unrealized_conversion_cast %ptr_1085 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1295, %1296 : i32, !llvm.ptr
      %1297 = vector.extractelement %1292[%128 : i32] : vector<4xi32>
      %ptr_1086 = cute.add_offset(%ptr_1084, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1298 = builtin.unrealized_conversion_cast %ptr_1086 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1297, %1298 : i32, !llvm.ptr
      %1299 = vector.extractelement %1292[%126 : i32] : vector<4xi32>
      %ptr_1087 = cute.add_offset(%ptr_1084, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1300 = builtin.unrealized_conversion_cast %ptr_1087 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1299, %1300 : i32, !llvm.ptr
      %1301 = arith.addi %1290, %c1_i32 : i32
      cf.br ^bb433(%1301 : i32)
    ^bb435:  // pred: ^bb433
      cf.br ^bb436(%c0_i32 : i32)
    ^bb436(%1302: i32):  // 2 preds: ^bb435, ^bb437
      %1303 = arith.cmpi slt, %1302, %455 : i32
      cf.cond_br %1303, ^bb437, ^bb438 {llvm.loop_annotation = #loop_annotation}
    ^bb437:  // pred: ^bb436
      %coord_1088 = cute.make_coord(%1302) : (i32) -> !cute.coord<"(_,?)">
      %idx_1089 = cute.crd2idx(%coord_1088, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1090 = cute.add_offset(%ptr_544, %idx_1089) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1091 = cute.crd2idx(%coord_1088, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1092 = cute.add_offset(%ptr_545, %idx_1091) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1304 = cute_nvgpu.arch.copy.ldsm %ptr_1090{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1305 = vector.extractelement %1304[%130 : i32] : vector<4xi32>
      %1306 = builtin.unrealized_conversion_cast %ptr_1092 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1305, %1306 : i32, !llvm.ptr
      %1307 = vector.extractelement %1304[%129 : i32] : vector<4xi32>
      %ptr_1093 = cute.add_offset(%ptr_1092, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1308 = builtin.unrealized_conversion_cast %ptr_1093 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1307, %1308 : i32, !llvm.ptr
      %1309 = vector.extractelement %1304[%128 : i32] : vector<4xi32>
      %ptr_1094 = cute.add_offset(%ptr_1092, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1310 = builtin.unrealized_conversion_cast %ptr_1094 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1309, %1310 : i32, !llvm.ptr
      %1311 = vector.extractelement %1304[%126 : i32] : vector<4xi32>
      %ptr_1095 = cute.add_offset(%ptr_1092, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1312 = builtin.unrealized_conversion_cast %ptr_1095 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1311, %1312 : i32, !llvm.ptr
      %1313 = arith.addi %1302, %c1_i32 : i32
      cf.br ^bb436(%1313 : i32)
    ^bb438:  // pred: ^bb436
      cf.br ^bb439(%c0_i32 : i32)
    ^bb439(%1314: i32):  // 2 preds: ^bb438, ^bb446
      %1315 = arith.cmpi slt, %1314, %492 : i32
      cf.cond_br %1315, ^bb440, ^bb447 {llvm.loop_annotation = #loop_annotation}
    ^bb440:  // pred: ^bb439
      cf.br ^bb441(%c0_i32 : i32)
    ^bb441(%1316: i32):  // 2 preds: ^bb440, ^bb445
      %1317 = arith.cmpi slt, %1316, %442 : i32
      cf.cond_br %1317, ^bb442, ^bb446 {llvm.loop_annotation = #loop_annotation}
    ^bb442:  // pred: ^bb441
      %coord_1096 = cute.make_coord(%1316, %1314) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1097 = cute.crd2idx(%coord_1096, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1098 = cute.add_offset(%ptr_503, %idx_1097) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1318 = builtin.unrealized_conversion_cast %ptr_1098 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1319 = llvm.getelementptr %1318[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1320 = llvm.getelementptr %1318[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1321 = llvm.getelementptr %1318[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb443(%c0_i32 : i32)
    ^bb443(%1322: i32):  // 2 preds: ^bb442, ^bb444
      %1323 = arith.cmpi slt, %1322, %493 : i32
      cf.cond_br %1323, ^bb444, ^bb445 {llvm.loop_annotation = #loop_annotation}
    ^bb444:  // pred: ^bb443
      %coord_1099 = cute.make_coord(%1322, %1314) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1100 = cute.make_coord(%1316, %1322) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1101 = cute.crd2idx(%coord_1099, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1102 = cute.add_offset(%ptr_514, %idx_1101) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1103 = cute.crd2idx(%coord_1100, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1104 = cute.add_offset(%iter_1026, %idx_1103) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1324 = llvm.load %1318 : !llvm.ptr -> i32
      %1325 = llvm.load %1319 : !llvm.ptr -> i32
      %1326 = llvm.load %1320 : !llvm.ptr -> i32
      %1327 = llvm.load %1321 : !llvm.ptr -> i32
      %1328 = builtin.unrealized_conversion_cast %ptr_1102 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1329 = llvm.load %1328 : !llvm.ptr -> i32
      %1330 = llvm.getelementptr %1328[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1331 = llvm.load %1330 : !llvm.ptr -> i32
      %1332 = builtin.unrealized_conversion_cast %ptr_1104 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1333 = llvm.load %1332 : !llvm.ptr -> f32
      %1334 = llvm.getelementptr %1332[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1335 = llvm.load %1334 : !llvm.ptr -> f32
      %1336 = llvm.getelementptr %1332[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1337 = llvm.load %1336 : !llvm.ptr -> f32
      %1338 = llvm.getelementptr %1332[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1339 = llvm.load %1338 : !llvm.ptr -> f32
      %1340:4 = cute_nvgpu.arch.mma.SM80 A[%1324, %1325, %1326, %1327]  B[%1329, %1331]  C[%1333, %1335, %1337, %1339] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1340#0, %1332 : f32, !llvm.ptr
      llvm.store %1340#1, %1334 : f32, !llvm.ptr
      llvm.store %1340#2, %1336 : f32, !llvm.ptr
      llvm.store %1340#3, %1338 : f32, !llvm.ptr
      %1341 = arith.addi %1322, %c1_i32 : i32
      cf.br ^bb443(%1341 : i32)
    ^bb445:  // pred: ^bb443
      %1342 = arith.addi %1316, %c1_i32 : i32
      cf.br ^bb441(%1342 : i32)
    ^bb446:  // pred: ^bb441
      %1343 = arith.addi %1314, %c1_i32 : i32
      cf.br ^bb439(%1343 : i32)
    ^bb447:  // pred: ^bb439
      cf.br ^bb448(%c0_i32 : i32)
    ^bb448(%1344: i32):  // 2 preds: ^bb447, ^bb449
      %1345 = arith.cmpi slt, %1344, %442 : i32
      cf.cond_br %1345, ^bb449, ^bb450 {llvm.loop_annotation = #loop_annotation}
    ^bb449:  // pred: ^bb448
      %coord_1105 = cute.make_coord(%1344) : (i32) -> !cute.coord<"(_,?)">
      %idx_1106 = cute.crd2idx(%coord_1105, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1107 = cute.add_offset(%ptr_564, %idx_1106) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1108 = cute.crd2idx(%coord_1105, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1109 = cute.add_offset(%ptr_565, %idx_1108) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1346 = cute_nvgpu.arch.copy.ldsm %ptr_1107{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1347 = vector.extractelement %1346[%130 : i32] : vector<4xi32>
      %1348 = builtin.unrealized_conversion_cast %ptr_1109 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1347, %1348 : i32, !llvm.ptr
      %1349 = vector.extractelement %1346[%129 : i32] : vector<4xi32>
      %ptr_1110 = cute.add_offset(%ptr_1109, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1350 = builtin.unrealized_conversion_cast %ptr_1110 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1349, %1350 : i32, !llvm.ptr
      %1351 = vector.extractelement %1346[%128 : i32] : vector<4xi32>
      %ptr_1111 = cute.add_offset(%ptr_1109, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1352 = builtin.unrealized_conversion_cast %ptr_1111 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1351, %1352 : i32, !llvm.ptr
      %1353 = vector.extractelement %1346[%126 : i32] : vector<4xi32>
      %ptr_1112 = cute.add_offset(%ptr_1109, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1354 = builtin.unrealized_conversion_cast %ptr_1112 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1353, %1354 : i32, !llvm.ptr
      %1355 = arith.addi %1344, %c1_i32 : i32
      cf.br ^bb448(%1355 : i32)
    ^bb450:  // pred: ^bb448
      cf.br ^bb451(%c0_i32 : i32)
    ^bb451(%1356: i32):  // 2 preds: ^bb450, ^bb452
      %1357 = arith.cmpi slt, %1356, %455 : i32
      cf.cond_br %1357, ^bb452, ^bb453 {llvm.loop_annotation = #loop_annotation}
    ^bb452:  // pred: ^bb451
      %coord_1113 = cute.make_coord(%1356) : (i32) -> !cute.coord<"(_,?)">
      %idx_1114 = cute.crd2idx(%coord_1113, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1115 = cute.add_offset(%ptr_575, %idx_1114) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1116 = cute.crd2idx(%coord_1113, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1117 = cute.add_offset(%ptr_576, %idx_1116) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1358 = cute_nvgpu.arch.copy.ldsm %ptr_1115{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1359 = vector.extractelement %1358[%130 : i32] : vector<4xi32>
      %1360 = builtin.unrealized_conversion_cast %ptr_1117 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1359, %1360 : i32, !llvm.ptr
      %1361 = vector.extractelement %1358[%129 : i32] : vector<4xi32>
      %ptr_1118 = cute.add_offset(%ptr_1117, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1362 = builtin.unrealized_conversion_cast %ptr_1118 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1361, %1362 : i32, !llvm.ptr
      %1363 = vector.extractelement %1358[%128 : i32] : vector<4xi32>
      %ptr_1119 = cute.add_offset(%ptr_1117, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1364 = builtin.unrealized_conversion_cast %ptr_1119 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1363, %1364 : i32, !llvm.ptr
      %1365 = vector.extractelement %1358[%126 : i32] : vector<4xi32>
      %ptr_1120 = cute.add_offset(%ptr_1117, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1366 = builtin.unrealized_conversion_cast %ptr_1120 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1365, %1366 : i32, !llvm.ptr
      %1367 = arith.addi %1356, %c1_i32 : i32
      cf.br ^bb451(%1367 : i32)
    ^bb453:  // pred: ^bb451
      cf.br ^bb454(%c0_i32 : i32)
    ^bb454(%1368: i32):  // 2 preds: ^bb453, ^bb461
      %1369 = arith.cmpi slt, %1368, %492 : i32
      cf.cond_br %1369, ^bb455, ^bb462 {llvm.loop_annotation = #loop_annotation}
    ^bb455:  // pred: ^bb454
      cf.br ^bb456(%c0_i32 : i32)
    ^bb456(%1370: i32):  // 2 preds: ^bb455, ^bb460
      %1371 = arith.cmpi slt, %1370, %442 : i32
      cf.cond_br %1371, ^bb457, ^bb461 {llvm.loop_annotation = #loop_annotation}
    ^bb457:  // pred: ^bb456
      %coord_1121 = cute.make_coord(%1370, %1368) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1122 = cute.crd2idx(%coord_1121, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1123 = cute.add_offset(%ptr_534, %idx_1122) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1372 = builtin.unrealized_conversion_cast %ptr_1123 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1373 = llvm.getelementptr %1372[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1374 = llvm.getelementptr %1372[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1375 = llvm.getelementptr %1372[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb458(%c0_i32 : i32)
    ^bb458(%1376: i32):  // 2 preds: ^bb457, ^bb459
      %1377 = arith.cmpi slt, %1376, %493 : i32
      cf.cond_br %1377, ^bb459, ^bb460 {llvm.loop_annotation = #loop_annotation}
    ^bb459:  // pred: ^bb458
      %coord_1124 = cute.make_coord(%1376, %1368) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1125 = cute.make_coord(%1370, %1376) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1126 = cute.crd2idx(%coord_1124, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1127 = cute.add_offset(%ptr_545, %idx_1126) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1128 = cute.crd2idx(%coord_1125, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1129 = cute.add_offset(%iter_1026, %idx_1128) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1378 = llvm.load %1372 : !llvm.ptr -> i32
      %1379 = llvm.load %1373 : !llvm.ptr -> i32
      %1380 = llvm.load %1374 : !llvm.ptr -> i32
      %1381 = llvm.load %1375 : !llvm.ptr -> i32
      %1382 = builtin.unrealized_conversion_cast %ptr_1127 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1383 = llvm.load %1382 : !llvm.ptr -> i32
      %1384 = llvm.getelementptr %1382[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1385 = llvm.load %1384 : !llvm.ptr -> i32
      %1386 = builtin.unrealized_conversion_cast %ptr_1129 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1387 = llvm.load %1386 : !llvm.ptr -> f32
      %1388 = llvm.getelementptr %1386[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1389 = llvm.load %1388 : !llvm.ptr -> f32
      %1390 = llvm.getelementptr %1386[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1391 = llvm.load %1390 : !llvm.ptr -> f32
      %1392 = llvm.getelementptr %1386[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1393 = llvm.load %1392 : !llvm.ptr -> f32
      %1394:4 = cute_nvgpu.arch.mma.SM80 A[%1378, %1379, %1380, %1381]  B[%1383, %1385]  C[%1387, %1389, %1391, %1393] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1394#0, %1386 : f32, !llvm.ptr
      llvm.store %1394#1, %1388 : f32, !llvm.ptr
      llvm.store %1394#2, %1390 : f32, !llvm.ptr
      llvm.store %1394#3, %1392 : f32, !llvm.ptr
      %1395 = arith.addi %1376, %c1_i32 : i32
      cf.br ^bb458(%1395 : i32)
    ^bb460:  // pred: ^bb458
      %1396 = arith.addi %1370, %c1_i32 : i32
      cf.br ^bb456(%1396 : i32)
    ^bb461:  // pred: ^bb456
      %1397 = arith.addi %1368, %c1_i32 : i32
      cf.br ^bb454(%1397 : i32)
    ^bb462:  // pred: ^bb454
      cf.br ^bb463(%c0_i32 : i32)
    ^bb463(%1398: i32):  // 2 preds: ^bb462, ^bb464
      %1399 = arith.cmpi slt, %1398, %442 : i32
      cf.cond_br %1399, ^bb464, ^bb465 {llvm.loop_annotation = #loop_annotation}
    ^bb464:  // pred: ^bb463
      %coord_1130 = cute.make_coord(%1398) : (i32) -> !cute.coord<"(_,?)">
      %idx_1131 = cute.crd2idx(%coord_1130, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1132 = cute.add_offset(%ptr_594, %idx_1131) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1133 = cute.crd2idx(%coord_1130, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1134 = cute.add_offset(%ptr_595, %idx_1133) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1400 = cute_nvgpu.arch.copy.ldsm %ptr_1132{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1401 = vector.extractelement %1400[%130 : i32] : vector<4xi32>
      %1402 = builtin.unrealized_conversion_cast %ptr_1134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1401, %1402 : i32, !llvm.ptr
      %1403 = vector.extractelement %1400[%129 : i32] : vector<4xi32>
      %ptr_1135 = cute.add_offset(%ptr_1134, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1404 = builtin.unrealized_conversion_cast %ptr_1135 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1403, %1404 : i32, !llvm.ptr
      %1405 = vector.extractelement %1400[%128 : i32] : vector<4xi32>
      %ptr_1136 = cute.add_offset(%ptr_1134, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1406 = builtin.unrealized_conversion_cast %ptr_1136 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1405, %1406 : i32, !llvm.ptr
      %1407 = vector.extractelement %1400[%126 : i32] : vector<4xi32>
      %ptr_1137 = cute.add_offset(%ptr_1134, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1408 = builtin.unrealized_conversion_cast %ptr_1137 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1407, %1408 : i32, !llvm.ptr
      %1409 = arith.addi %1398, %c1_i32 : i32
      cf.br ^bb463(%1409 : i32)
    ^bb465:  // pred: ^bb463
      cf.br ^bb466(%c0_i32 : i32)
    ^bb466(%1410: i32):  // 2 preds: ^bb465, ^bb467
      %1411 = arith.cmpi slt, %1410, %455 : i32
      cf.cond_br %1411, ^bb467, ^bb468 {llvm.loop_annotation = #loop_annotation}
    ^bb467:  // pred: ^bb466
      %coord_1138 = cute.make_coord(%1410) : (i32) -> !cute.coord<"(_,?)">
      %idx_1139 = cute.crd2idx(%coord_1138, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1140 = cute.add_offset(%ptr_604, %idx_1139) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1141 = cute.crd2idx(%coord_1138, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1142 = cute.add_offset(%ptr_605, %idx_1141) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1412 = cute_nvgpu.arch.copy.ldsm %ptr_1140{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1413 = vector.extractelement %1412[%130 : i32] : vector<4xi32>
      %1414 = builtin.unrealized_conversion_cast %ptr_1142 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1413, %1414 : i32, !llvm.ptr
      %1415 = vector.extractelement %1412[%129 : i32] : vector<4xi32>
      %ptr_1143 = cute.add_offset(%ptr_1142, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1416 = builtin.unrealized_conversion_cast %ptr_1143 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1415, %1416 : i32, !llvm.ptr
      %1417 = vector.extractelement %1412[%128 : i32] : vector<4xi32>
      %ptr_1144 = cute.add_offset(%ptr_1142, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1418 = builtin.unrealized_conversion_cast %ptr_1144 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1417, %1418 : i32, !llvm.ptr
      %1419 = vector.extractelement %1412[%126 : i32] : vector<4xi32>
      %ptr_1145 = cute.add_offset(%ptr_1142, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1420 = builtin.unrealized_conversion_cast %ptr_1145 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1419, %1420 : i32, !llvm.ptr
      %1421 = arith.addi %1410, %c1_i32 : i32
      cf.br ^bb466(%1421 : i32)
    ^bb468:  // pred: ^bb466
      cf.br ^bb469(%c0_i32 : i32)
    ^bb469(%1422: i32):  // 2 preds: ^bb468, ^bb476
      %1423 = arith.cmpi slt, %1422, %492 : i32
      cf.cond_br %1423, ^bb470, ^bb477 {llvm.loop_annotation = #loop_annotation}
    ^bb470:  // pred: ^bb469
      cf.br ^bb471(%c0_i32 : i32)
    ^bb471(%1424: i32):  // 2 preds: ^bb470, ^bb475
      %1425 = arith.cmpi slt, %1424, %442 : i32
      cf.cond_br %1425, ^bb472, ^bb476 {llvm.loop_annotation = #loop_annotation}
    ^bb472:  // pred: ^bb471
      %coord_1146 = cute.make_coord(%1424, %1422) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1147 = cute.crd2idx(%coord_1146, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1148 = cute.add_offset(%ptr_565, %idx_1147) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1426 = builtin.unrealized_conversion_cast %ptr_1148 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1427 = llvm.getelementptr %1426[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1428 = llvm.getelementptr %1426[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1429 = llvm.getelementptr %1426[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb473(%c0_i32 : i32)
    ^bb473(%1430: i32):  // 2 preds: ^bb472, ^bb474
      %1431 = arith.cmpi slt, %1430, %493 : i32
      cf.cond_br %1431, ^bb474, ^bb475 {llvm.loop_annotation = #loop_annotation}
    ^bb474:  // pred: ^bb473
      %coord_1149 = cute.make_coord(%1430, %1422) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1150 = cute.make_coord(%1424, %1430) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1151 = cute.crd2idx(%coord_1149, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1152 = cute.add_offset(%ptr_576, %idx_1151) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1153 = cute.crd2idx(%coord_1150, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1154 = cute.add_offset(%iter_1026, %idx_1153) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1432 = llvm.load %1426 : !llvm.ptr -> i32
      %1433 = llvm.load %1427 : !llvm.ptr -> i32
      %1434 = llvm.load %1428 : !llvm.ptr -> i32
      %1435 = llvm.load %1429 : !llvm.ptr -> i32
      %1436 = builtin.unrealized_conversion_cast %ptr_1152 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1437 = llvm.load %1436 : !llvm.ptr -> i32
      %1438 = llvm.getelementptr %1436[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1439 = llvm.load %1438 : !llvm.ptr -> i32
      %1440 = builtin.unrealized_conversion_cast %ptr_1154 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1441 = llvm.load %1440 : !llvm.ptr -> f32
      %1442 = llvm.getelementptr %1440[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1443 = llvm.load %1442 : !llvm.ptr -> f32
      %1444 = llvm.getelementptr %1440[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1445 = llvm.load %1444 : !llvm.ptr -> f32
      %1446 = llvm.getelementptr %1440[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1447 = llvm.load %1446 : !llvm.ptr -> f32
      %1448:4 = cute_nvgpu.arch.mma.SM80 A[%1432, %1433, %1434, %1435]  B[%1437, %1439]  C[%1441, %1443, %1445, %1447] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1448#0, %1440 : f32, !llvm.ptr
      llvm.store %1448#1, %1442 : f32, !llvm.ptr
      llvm.store %1448#2, %1444 : f32, !llvm.ptr
      llvm.store %1448#3, %1446 : f32, !llvm.ptr
      %1449 = arith.addi %1430, %c1_i32 : i32
      cf.br ^bb473(%1449 : i32)
    ^bb475:  // pred: ^bb473
      %1450 = arith.addi %1424, %c1_i32 : i32
      cf.br ^bb471(%1450 : i32)
    ^bb476:  // pred: ^bb471
      %1451 = arith.addi %1422, %c1_i32 : i32
      cf.br ^bb469(%1451 : i32)
    ^bb477:  // pred: ^bb469
      cf.br ^bb478(%c0_i32 : i32)
    ^bb478(%1452: i32):  // 2 preds: ^bb477, ^bb479
      %1453 = arith.cmpi slt, %1452, %442 : i32
      cf.cond_br %1453, ^bb479, ^bb480 {llvm.loop_annotation = #loop_annotation}
    ^bb479:  // pred: ^bb478
      %coord_1155 = cute.make_coord(%1452) : (i32) -> !cute.coord<"(_,?)">
      %idx_1156 = cute.crd2idx(%coord_1155, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1157 = cute.add_offset(%ptr_624, %idx_1156) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1158 = cute.crd2idx(%coord_1155, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1159 = cute.add_offset(%ptr_625, %idx_1158) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1454 = cute_nvgpu.arch.copy.ldsm %ptr_1157{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1455 = vector.extractelement %1454[%130 : i32] : vector<4xi32>
      %1456 = builtin.unrealized_conversion_cast %ptr_1159 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1455, %1456 : i32, !llvm.ptr
      %1457 = vector.extractelement %1454[%129 : i32] : vector<4xi32>
      %ptr_1160 = cute.add_offset(%ptr_1159, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1458 = builtin.unrealized_conversion_cast %ptr_1160 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1457, %1458 : i32, !llvm.ptr
      %1459 = vector.extractelement %1454[%128 : i32] : vector<4xi32>
      %ptr_1161 = cute.add_offset(%ptr_1159, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1460 = builtin.unrealized_conversion_cast %ptr_1161 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1459, %1460 : i32, !llvm.ptr
      %1461 = vector.extractelement %1454[%126 : i32] : vector<4xi32>
      %ptr_1162 = cute.add_offset(%ptr_1159, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1462 = builtin.unrealized_conversion_cast %ptr_1162 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1461, %1462 : i32, !llvm.ptr
      %1463 = arith.addi %1452, %c1_i32 : i32
      cf.br ^bb478(%1463 : i32)
    ^bb480:  // pred: ^bb478
      cf.br ^bb481(%c0_i32 : i32)
    ^bb481(%1464: i32):  // 2 preds: ^bb480, ^bb482
      %1465 = arith.cmpi slt, %1464, %455 : i32
      cf.cond_br %1465, ^bb482, ^bb483 {llvm.loop_annotation = #loop_annotation}
    ^bb482:  // pred: ^bb481
      %coord_1163 = cute.make_coord(%1464) : (i32) -> !cute.coord<"(_,?)">
      %idx_1164 = cute.crd2idx(%coord_1163, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1165 = cute.add_offset(%ptr_635, %idx_1164) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1166 = cute.crd2idx(%coord_1163, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1167 = cute.add_offset(%ptr_636, %idx_1166) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1466 = cute_nvgpu.arch.copy.ldsm %ptr_1165{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1467 = vector.extractelement %1466[%130 : i32] : vector<4xi32>
      %1468 = builtin.unrealized_conversion_cast %ptr_1167 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1467, %1468 : i32, !llvm.ptr
      %1469 = vector.extractelement %1466[%129 : i32] : vector<4xi32>
      %ptr_1168 = cute.add_offset(%ptr_1167, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1470 = builtin.unrealized_conversion_cast %ptr_1168 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1469, %1470 : i32, !llvm.ptr
      %1471 = vector.extractelement %1466[%128 : i32] : vector<4xi32>
      %ptr_1169 = cute.add_offset(%ptr_1167, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1472 = builtin.unrealized_conversion_cast %ptr_1169 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1471, %1472 : i32, !llvm.ptr
      %1473 = vector.extractelement %1466[%126 : i32] : vector<4xi32>
      %ptr_1170 = cute.add_offset(%ptr_1167, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1474 = builtin.unrealized_conversion_cast %ptr_1170 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1473, %1474 : i32, !llvm.ptr
      %1475 = arith.addi %1464, %c1_i32 : i32
      cf.br ^bb481(%1475 : i32)
    ^bb483:  // pred: ^bb481
      cf.br ^bb484(%c0_i32 : i32)
    ^bb484(%1476: i32):  // 2 preds: ^bb483, ^bb491
      %1477 = arith.cmpi slt, %1476, %492 : i32
      cf.cond_br %1477, ^bb485, ^bb492 {llvm.loop_annotation = #loop_annotation}
    ^bb485:  // pred: ^bb484
      cf.br ^bb486(%c0_i32 : i32)
    ^bb486(%1478: i32):  // 2 preds: ^bb485, ^bb490
      %1479 = arith.cmpi slt, %1478, %442 : i32
      cf.cond_br %1479, ^bb487, ^bb491 {llvm.loop_annotation = #loop_annotation}
    ^bb487:  // pred: ^bb486
      %coord_1171 = cute.make_coord(%1478, %1476) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1172 = cute.crd2idx(%coord_1171, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1173 = cute.add_offset(%ptr_595, %idx_1172) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1480 = builtin.unrealized_conversion_cast %ptr_1173 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1481 = llvm.getelementptr %1480[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1482 = llvm.getelementptr %1480[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1483 = llvm.getelementptr %1480[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb488(%c0_i32 : i32)
    ^bb488(%1484: i32):  // 2 preds: ^bb487, ^bb489
      %1485 = arith.cmpi slt, %1484, %493 : i32
      cf.cond_br %1485, ^bb489, ^bb490 {llvm.loop_annotation = #loop_annotation}
    ^bb489:  // pred: ^bb488
      %coord_1174 = cute.make_coord(%1484, %1476) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1175 = cute.make_coord(%1478, %1484) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1176 = cute.crd2idx(%coord_1174, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1177 = cute.add_offset(%ptr_605, %idx_1176) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1178 = cute.crd2idx(%coord_1175, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1179 = cute.add_offset(%iter_1026, %idx_1178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1486 = llvm.load %1480 : !llvm.ptr -> i32
      %1487 = llvm.load %1481 : !llvm.ptr -> i32
      %1488 = llvm.load %1482 : !llvm.ptr -> i32
      %1489 = llvm.load %1483 : !llvm.ptr -> i32
      %1490 = builtin.unrealized_conversion_cast %ptr_1177 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1491 = llvm.load %1490 : !llvm.ptr -> i32
      %1492 = llvm.getelementptr %1490[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1493 = llvm.load %1492 : !llvm.ptr -> i32
      %1494 = builtin.unrealized_conversion_cast %ptr_1179 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1495 = llvm.load %1494 : !llvm.ptr -> f32
      %1496 = llvm.getelementptr %1494[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1497 = llvm.load %1496 : !llvm.ptr -> f32
      %1498 = llvm.getelementptr %1494[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1499 = llvm.load %1498 : !llvm.ptr -> f32
      %1500 = llvm.getelementptr %1494[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1501 = llvm.load %1500 : !llvm.ptr -> f32
      %1502:4 = cute_nvgpu.arch.mma.SM80 A[%1486, %1487, %1488, %1489]  B[%1491, %1493]  C[%1495, %1497, %1499, %1501] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1502#0, %1494 : f32, !llvm.ptr
      llvm.store %1502#1, %1496 : f32, !llvm.ptr
      llvm.store %1502#2, %1498 : f32, !llvm.ptr
      llvm.store %1502#3, %1500 : f32, !llvm.ptr
      %1503 = arith.addi %1484, %c1_i32 : i32
      cf.br ^bb488(%1503 : i32)
    ^bb490:  // pred: ^bb488
      %1504 = arith.addi %1478, %c1_i32 : i32
      cf.br ^bb486(%1504 : i32)
    ^bb491:  // pred: ^bb486
      %1505 = arith.addi %1476, %c1_i32 : i32
      cf.br ^bb484(%1505 : i32)
    ^bb492:  // pred: ^bb484
      cf.br ^bb493(%c0_i32 : i32)
    ^bb493(%1506: i32):  // 2 preds: ^bb492, ^bb494
      %1507 = arith.cmpi slt, %1506, %442 : i32
      cf.cond_br %1507, ^bb494, ^bb495 {llvm.loop_annotation = #loop_annotation}
    ^bb494:  // pred: ^bb493
      %coord_1180 = cute.make_coord(%1506) : (i32) -> !cute.coord<"(_,?)">
      %idx_1181 = cute.crd2idx(%coord_1180, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1182 = cute.add_offset(%ptr_655, %idx_1181) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1183 = cute.crd2idx(%coord_1180, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1184 = cute.add_offset(%ptr_656, %idx_1183) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1508 = cute_nvgpu.arch.copy.ldsm %ptr_1182{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1509 = vector.extractelement %1508[%130 : i32] : vector<4xi32>
      %1510 = builtin.unrealized_conversion_cast %ptr_1184 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1509, %1510 : i32, !llvm.ptr
      %1511 = vector.extractelement %1508[%129 : i32] : vector<4xi32>
      %ptr_1185 = cute.add_offset(%ptr_1184, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1512 = builtin.unrealized_conversion_cast %ptr_1185 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1511, %1512 : i32, !llvm.ptr
      %1513 = vector.extractelement %1508[%128 : i32] : vector<4xi32>
      %ptr_1186 = cute.add_offset(%ptr_1184, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1514 = builtin.unrealized_conversion_cast %ptr_1186 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1513, %1514 : i32, !llvm.ptr
      %1515 = vector.extractelement %1508[%126 : i32] : vector<4xi32>
      %ptr_1187 = cute.add_offset(%ptr_1184, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1516 = builtin.unrealized_conversion_cast %ptr_1187 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1515, %1516 : i32, !llvm.ptr
      %1517 = arith.addi %1506, %c1_i32 : i32
      cf.br ^bb493(%1517 : i32)
    ^bb495:  // pred: ^bb493
      cf.br ^bb496(%c0_i32 : i32)
    ^bb496(%1518: i32):  // 2 preds: ^bb495, ^bb497
      %1519 = arith.cmpi slt, %1518, %455 : i32
      cf.cond_br %1519, ^bb497, ^bb498 {llvm.loop_annotation = #loop_annotation}
    ^bb497:  // pred: ^bb496
      %coord_1188 = cute.make_coord(%1518) : (i32) -> !cute.coord<"(_,?)">
      %idx_1189 = cute.crd2idx(%coord_1188, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1190 = cute.add_offset(%ptr_666, %idx_1189) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1191 = cute.crd2idx(%coord_1188, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1192 = cute.add_offset(%ptr_667, %idx_1191) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1520 = cute_nvgpu.arch.copy.ldsm %ptr_1190{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1521 = vector.extractelement %1520[%130 : i32] : vector<4xi32>
      %1522 = builtin.unrealized_conversion_cast %ptr_1192 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1521, %1522 : i32, !llvm.ptr
      %1523 = vector.extractelement %1520[%129 : i32] : vector<4xi32>
      %ptr_1193 = cute.add_offset(%ptr_1192, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1524 = builtin.unrealized_conversion_cast %ptr_1193 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1523, %1524 : i32, !llvm.ptr
      %1525 = vector.extractelement %1520[%128 : i32] : vector<4xi32>
      %ptr_1194 = cute.add_offset(%ptr_1192, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1526 = builtin.unrealized_conversion_cast %ptr_1194 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1525, %1526 : i32, !llvm.ptr
      %1527 = vector.extractelement %1520[%126 : i32] : vector<4xi32>
      %ptr_1195 = cute.add_offset(%ptr_1192, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1528 = builtin.unrealized_conversion_cast %ptr_1195 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1527, %1528 : i32, !llvm.ptr
      %1529 = arith.addi %1518, %c1_i32 : i32
      cf.br ^bb496(%1529 : i32)
    ^bb498:  // pred: ^bb496
      cf.br ^bb499(%c0_i32 : i32)
    ^bb499(%1530: i32):  // 2 preds: ^bb498, ^bb506
      %1531 = arith.cmpi slt, %1530, %492 : i32
      cf.cond_br %1531, ^bb500, ^bb507 {llvm.loop_annotation = #loop_annotation}
    ^bb500:  // pred: ^bb499
      cf.br ^bb501(%c0_i32 : i32)
    ^bb501(%1532: i32):  // 2 preds: ^bb500, ^bb505
      %1533 = arith.cmpi slt, %1532, %442 : i32
      cf.cond_br %1533, ^bb502, ^bb506 {llvm.loop_annotation = #loop_annotation}
    ^bb502:  // pred: ^bb501
      %coord_1196 = cute.make_coord(%1532, %1530) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1197 = cute.crd2idx(%coord_1196, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1198 = cute.add_offset(%ptr_625, %idx_1197) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1534 = builtin.unrealized_conversion_cast %ptr_1198 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1535 = llvm.getelementptr %1534[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1536 = llvm.getelementptr %1534[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1537 = llvm.getelementptr %1534[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb503(%c0_i32 : i32)
    ^bb503(%1538: i32):  // 2 preds: ^bb502, ^bb504
      %1539 = arith.cmpi slt, %1538, %493 : i32
      cf.cond_br %1539, ^bb504, ^bb505 {llvm.loop_annotation = #loop_annotation}
    ^bb504:  // pred: ^bb503
      %coord_1199 = cute.make_coord(%1538, %1530) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1200 = cute.make_coord(%1532, %1538) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1201 = cute.crd2idx(%coord_1199, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1202 = cute.add_offset(%ptr_636, %idx_1201) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1203 = cute.crd2idx(%coord_1200, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1204 = cute.add_offset(%iter_1026, %idx_1203) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1540 = llvm.load %1534 : !llvm.ptr -> i32
      %1541 = llvm.load %1535 : !llvm.ptr -> i32
      %1542 = llvm.load %1536 : !llvm.ptr -> i32
      %1543 = llvm.load %1537 : !llvm.ptr -> i32
      %1544 = builtin.unrealized_conversion_cast %ptr_1202 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1545 = llvm.load %1544 : !llvm.ptr -> i32
      %1546 = llvm.getelementptr %1544[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1547 = llvm.load %1546 : !llvm.ptr -> i32
      %1548 = builtin.unrealized_conversion_cast %ptr_1204 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1549 = llvm.load %1548 : !llvm.ptr -> f32
      %1550 = llvm.getelementptr %1548[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1551 = llvm.load %1550 : !llvm.ptr -> f32
      %1552 = llvm.getelementptr %1548[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1553 = llvm.load %1552 : !llvm.ptr -> f32
      %1554 = llvm.getelementptr %1548[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1555 = llvm.load %1554 : !llvm.ptr -> f32
      %1556:4 = cute_nvgpu.arch.mma.SM80 A[%1540, %1541, %1542, %1543]  B[%1545, %1547]  C[%1549, %1551, %1553, %1555] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1556#0, %1548 : f32, !llvm.ptr
      llvm.store %1556#1, %1550 : f32, !llvm.ptr
      llvm.store %1556#2, %1552 : f32, !llvm.ptr
      llvm.store %1556#3, %1554 : f32, !llvm.ptr
      %1557 = arith.addi %1538, %c1_i32 : i32
      cf.br ^bb503(%1557 : i32)
    ^bb505:  // pred: ^bb503
      %1558 = arith.addi %1532, %c1_i32 : i32
      cf.br ^bb501(%1558 : i32)
    ^bb506:  // pred: ^bb501
      %1559 = arith.addi %1530, %c1_i32 : i32
      cf.br ^bb499(%1559 : i32)
    ^bb507:  // pred: ^bb499
      cf.br ^bb508(%c0_i32 : i32)
    ^bb508(%1560: i32):  // 2 preds: ^bb507, ^bb509
      %1561 = arith.cmpi slt, %1560, %442 : i32
      cf.cond_br %1561, ^bb509, ^bb510 {llvm.loop_annotation = #loop_annotation}
    ^bb509:  // pred: ^bb508
      %coord_1205 = cute.make_coord(%1560) : (i32) -> !cute.coord<"(_,?)">
      %idx_1206 = cute.crd2idx(%coord_1205, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1207 = cute.add_offset(%ptr_686, %idx_1206) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1208 = cute.crd2idx(%coord_1205, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1209 = cute.add_offset(%ptr_687, %idx_1208) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1562 = cute_nvgpu.arch.copy.ldsm %ptr_1207{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1563 = vector.extractelement %1562[%130 : i32] : vector<4xi32>
      %1564 = builtin.unrealized_conversion_cast %ptr_1209 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1563, %1564 : i32, !llvm.ptr
      %1565 = vector.extractelement %1562[%129 : i32] : vector<4xi32>
      %ptr_1210 = cute.add_offset(%ptr_1209, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1566 = builtin.unrealized_conversion_cast %ptr_1210 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1565, %1566 : i32, !llvm.ptr
      %1567 = vector.extractelement %1562[%128 : i32] : vector<4xi32>
      %ptr_1211 = cute.add_offset(%ptr_1209, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1568 = builtin.unrealized_conversion_cast %ptr_1211 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1567, %1568 : i32, !llvm.ptr
      %1569 = vector.extractelement %1562[%126 : i32] : vector<4xi32>
      %ptr_1212 = cute.add_offset(%ptr_1209, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1570 = builtin.unrealized_conversion_cast %ptr_1212 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1569, %1570 : i32, !llvm.ptr
      %1571 = arith.addi %1560, %c1_i32 : i32
      cf.br ^bb508(%1571 : i32)
    ^bb510:  // pred: ^bb508
      cf.br ^bb511(%c0_i32 : i32)
    ^bb511(%1572: i32):  // 2 preds: ^bb510, ^bb512
      %1573 = arith.cmpi slt, %1572, %455 : i32
      cf.cond_br %1573, ^bb512, ^bb513 {llvm.loop_annotation = #loop_annotation}
    ^bb512:  // pred: ^bb511
      %coord_1213 = cute.make_coord(%1572) : (i32) -> !cute.coord<"(_,?)">
      %idx_1214 = cute.crd2idx(%coord_1213, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1215 = cute.add_offset(%ptr_697, %idx_1214) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1216 = cute.crd2idx(%coord_1213, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1217 = cute.add_offset(%ptr_698, %idx_1216) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1574 = cute_nvgpu.arch.copy.ldsm %ptr_1215{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1575 = vector.extractelement %1574[%130 : i32] : vector<4xi32>
      %1576 = builtin.unrealized_conversion_cast %ptr_1217 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1575, %1576 : i32, !llvm.ptr
      %1577 = vector.extractelement %1574[%129 : i32] : vector<4xi32>
      %ptr_1218 = cute.add_offset(%ptr_1217, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1578 = builtin.unrealized_conversion_cast %ptr_1218 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1577, %1578 : i32, !llvm.ptr
      %1579 = vector.extractelement %1574[%128 : i32] : vector<4xi32>
      %ptr_1219 = cute.add_offset(%ptr_1217, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1580 = builtin.unrealized_conversion_cast %ptr_1219 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1579, %1580 : i32, !llvm.ptr
      %1581 = vector.extractelement %1574[%126 : i32] : vector<4xi32>
      %ptr_1220 = cute.add_offset(%ptr_1217, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1582 = builtin.unrealized_conversion_cast %ptr_1220 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1581, %1582 : i32, !llvm.ptr
      %1583 = arith.addi %1572, %c1_i32 : i32
      cf.br ^bb511(%1583 : i32)
    ^bb513:  // pred: ^bb511
      cf.br ^bb514(%c0_i32 : i32)
    ^bb514(%1584: i32):  // 2 preds: ^bb513, ^bb521
      %1585 = arith.cmpi slt, %1584, %492 : i32
      cf.cond_br %1585, ^bb515, ^bb522 {llvm.loop_annotation = #loop_annotation}
    ^bb515:  // pred: ^bb514
      cf.br ^bb516(%c0_i32 : i32)
    ^bb516(%1586: i32):  // 2 preds: ^bb515, ^bb520
      %1587 = arith.cmpi slt, %1586, %442 : i32
      cf.cond_br %1587, ^bb517, ^bb521 {llvm.loop_annotation = #loop_annotation}
    ^bb517:  // pred: ^bb516
      %coord_1221 = cute.make_coord(%1586, %1584) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1222 = cute.crd2idx(%coord_1221, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1223 = cute.add_offset(%ptr_656, %idx_1222) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1588 = builtin.unrealized_conversion_cast %ptr_1223 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1589 = llvm.getelementptr %1588[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1590 = llvm.getelementptr %1588[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1591 = llvm.getelementptr %1588[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb518(%c0_i32 : i32)
    ^bb518(%1592: i32):  // 2 preds: ^bb517, ^bb519
      %1593 = arith.cmpi slt, %1592, %493 : i32
      cf.cond_br %1593, ^bb519, ^bb520 {llvm.loop_annotation = #loop_annotation}
    ^bb519:  // pred: ^bb518
      %coord_1224 = cute.make_coord(%1592, %1584) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1225 = cute.make_coord(%1586, %1592) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1226 = cute.crd2idx(%coord_1224, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1227 = cute.add_offset(%ptr_667, %idx_1226) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1228 = cute.crd2idx(%coord_1225, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1229 = cute.add_offset(%iter_1026, %idx_1228) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1594 = llvm.load %1588 : !llvm.ptr -> i32
      %1595 = llvm.load %1589 : !llvm.ptr -> i32
      %1596 = llvm.load %1590 : !llvm.ptr -> i32
      %1597 = llvm.load %1591 : !llvm.ptr -> i32
      %1598 = builtin.unrealized_conversion_cast %ptr_1227 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1599 = llvm.load %1598 : !llvm.ptr -> i32
      %1600 = llvm.getelementptr %1598[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1601 = llvm.load %1600 : !llvm.ptr -> i32
      %1602 = builtin.unrealized_conversion_cast %ptr_1229 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1603 = llvm.load %1602 : !llvm.ptr -> f32
      %1604 = llvm.getelementptr %1602[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1605 = llvm.load %1604 : !llvm.ptr -> f32
      %1606 = llvm.getelementptr %1602[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1607 = llvm.load %1606 : !llvm.ptr -> f32
      %1608 = llvm.getelementptr %1602[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1609 = llvm.load %1608 : !llvm.ptr -> f32
      %1610:4 = cute_nvgpu.arch.mma.SM80 A[%1594, %1595, %1596, %1597]  B[%1599, %1601]  C[%1603, %1605, %1607, %1609] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1610#0, %1602 : f32, !llvm.ptr
      llvm.store %1610#1, %1604 : f32, !llvm.ptr
      llvm.store %1610#2, %1606 : f32, !llvm.ptr
      llvm.store %1610#3, %1608 : f32, !llvm.ptr
      %1611 = arith.addi %1592, %c1_i32 : i32
      cf.br ^bb518(%1611 : i32)
    ^bb520:  // pred: ^bb518
      %1612 = arith.addi %1586, %c1_i32 : i32
      cf.br ^bb516(%1612 : i32)
    ^bb521:  // pred: ^bb516
      %1613 = arith.addi %1584, %c1_i32 : i32
      cf.br ^bb514(%1613 : i32)
    ^bb522:  // pred: ^bb514
      cf.br ^bb523(%c0_i32 : i32)
    ^bb523(%1614: i32):  // 2 preds: ^bb522, ^bb524
      %1615 = arith.cmpi slt, %1614, %442 : i32
      cf.cond_br %1615, ^bb524, ^bb525 {llvm.loop_annotation = #loop_annotation}
    ^bb524:  // pred: ^bb523
      %coord_1230 = cute.make_coord(%1614) : (i32) -> !cute.coord<"(_,?)">
      %idx_1231 = cute.crd2idx(%coord_1230, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1232 = cute.add_offset(%ptr_101, %idx_1231) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1233 = cute.crd2idx(%coord_1230, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1234 = cute.add_offset(%iter_106, %idx_1233) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1616 = cute_nvgpu.arch.copy.ldsm %ptr_1232{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1617 = vector.extractelement %1616[%130 : i32] : vector<4xi32>
      %1618 = builtin.unrealized_conversion_cast %ptr_1234 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1617, %1618 : i32, !llvm.ptr
      %1619 = vector.extractelement %1616[%129 : i32] : vector<4xi32>
      %ptr_1235 = cute.add_offset(%ptr_1234, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1620 = builtin.unrealized_conversion_cast %ptr_1235 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1619, %1620 : i32, !llvm.ptr
      %1621 = vector.extractelement %1616[%128 : i32] : vector<4xi32>
      %ptr_1236 = cute.add_offset(%ptr_1234, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1622 = builtin.unrealized_conversion_cast %ptr_1236 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1621, %1622 : i32, !llvm.ptr
      %1623 = vector.extractelement %1616[%126 : i32] : vector<4xi32>
      %ptr_1237 = cute.add_offset(%ptr_1234, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1624 = builtin.unrealized_conversion_cast %ptr_1237 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1623, %1624 : i32, !llvm.ptr
      %1625 = arith.addi %1614, %c1_i32 : i32
      cf.br ^bb523(%1625 : i32)
    ^bb525:  // pred: ^bb523
      cf.br ^bb526(%c0_i32 : i32)
    ^bb526(%1626: i32):  // 2 preds: ^bb525, ^bb527
      %1627 = arith.cmpi slt, %1626, %455 : i32
      cf.cond_br %1627, ^bb527, ^bb528 {llvm.loop_annotation = #loop_annotation}
    ^bb527:  // pred: ^bb526
      %coord_1238 = cute.make_coord(%1626) : (i32) -> !cute.coord<"(_,?)">
      %idx_1239 = cute.crd2idx(%coord_1238, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1240 = cute.add_offset(%ptr_109, %idx_1239) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1241 = cute.crd2idx(%coord_1238, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1242 = cute.add_offset(%iter_114, %idx_1241) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1628 = cute_nvgpu.arch.copy.ldsm %ptr_1240{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1629 = vector.extractelement %1628[%130 : i32] : vector<4xi32>
      %1630 = builtin.unrealized_conversion_cast %ptr_1242 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1629, %1630 : i32, !llvm.ptr
      %1631 = vector.extractelement %1628[%129 : i32] : vector<4xi32>
      %ptr_1243 = cute.add_offset(%ptr_1242, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1632 = builtin.unrealized_conversion_cast %ptr_1243 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1631, %1632 : i32, !llvm.ptr
      %1633 = vector.extractelement %1628[%128 : i32] : vector<4xi32>
      %ptr_1244 = cute.add_offset(%ptr_1242, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1634 = builtin.unrealized_conversion_cast %ptr_1244 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1633, %1634 : i32, !llvm.ptr
      %1635 = vector.extractelement %1628[%126 : i32] : vector<4xi32>
      %ptr_1245 = cute.add_offset(%ptr_1242, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1636 = builtin.unrealized_conversion_cast %ptr_1245 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1635, %1636 : i32, !llvm.ptr
      %1637 = arith.addi %1626, %c1_i32 : i32
      cf.br ^bb526(%1637 : i32)
    ^bb528:  // pred: ^bb526
      cf.br ^bb529(%c0_i32 : i32)
    ^bb529(%1638: i32):  // 2 preds: ^bb528, ^bb536
      %1639 = arith.cmpi slt, %1638, %492 : i32
      cf.cond_br %1639, ^bb530, ^bb537 {llvm.loop_annotation = #loop_annotation}
    ^bb530:  // pred: ^bb529
      cf.br ^bb531(%c0_i32 : i32)
    ^bb531(%1640: i32):  // 2 preds: ^bb530, ^bb535
      %1641 = arith.cmpi slt, %1640, %442 : i32
      cf.cond_br %1641, ^bb532, ^bb536 {llvm.loop_annotation = #loop_annotation}
    ^bb532:  // pred: ^bb531
      %coord_1246 = cute.make_coord(%1640, %1638) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1247 = cute.crd2idx(%coord_1246, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1248 = cute.add_offset(%ptr_687, %idx_1247) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1642 = builtin.unrealized_conversion_cast %ptr_1248 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1643 = llvm.getelementptr %1642[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1644 = llvm.getelementptr %1642[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1645 = llvm.getelementptr %1642[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb533(%c0_i32 : i32)
    ^bb533(%1646: i32):  // 2 preds: ^bb532, ^bb534
      %1647 = arith.cmpi slt, %1646, %493 : i32
      cf.cond_br %1647, ^bb534, ^bb535 {llvm.loop_annotation = #loop_annotation}
    ^bb534:  // pred: ^bb533
      %coord_1249 = cute.make_coord(%1646, %1638) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1250 = cute.make_coord(%1640, %1646) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1251 = cute.crd2idx(%coord_1249, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1252 = cute.add_offset(%ptr_698, %idx_1251) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1253 = cute.crd2idx(%coord_1250, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1254 = cute.add_offset(%iter_1026, %idx_1253) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1648 = llvm.load %1642 : !llvm.ptr -> i32
      %1649 = llvm.load %1643 : !llvm.ptr -> i32
      %1650 = llvm.load %1644 : !llvm.ptr -> i32
      %1651 = llvm.load %1645 : !llvm.ptr -> i32
      %1652 = builtin.unrealized_conversion_cast %ptr_1252 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1653 = llvm.load %1652 : !llvm.ptr -> i32
      %1654 = llvm.getelementptr %1652[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1655 = llvm.load %1654 : !llvm.ptr -> i32
      %1656 = builtin.unrealized_conversion_cast %ptr_1254 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1657 = llvm.load %1656 : !llvm.ptr -> f32
      %1658 = llvm.getelementptr %1656[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1659 = llvm.load %1658 : !llvm.ptr -> f32
      %1660 = llvm.getelementptr %1656[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1661 = llvm.load %1660 : !llvm.ptr -> f32
      %1662 = llvm.getelementptr %1656[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1663 = llvm.load %1662 : !llvm.ptr -> f32
      %1664:4 = cute_nvgpu.arch.mma.SM80 A[%1648, %1649, %1650, %1651]  B[%1653, %1655]  C[%1657, %1659, %1661, %1663] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1664#0, %1656 : f32, !llvm.ptr
      llvm.store %1664#1, %1658 : f32, !llvm.ptr
      llvm.store %1664#2, %1660 : f32, !llvm.ptr
      llvm.store %1664#3, %1662 : f32, !llvm.ptr
      %1665 = arith.addi %1646, %c1_i32 : i32
      cf.br ^bb533(%1665 : i32)
    ^bb535:  // pred: ^bb533
      %1666 = arith.addi %1640, %c1_i32 : i32
      cf.br ^bb531(%1666 : i32)
    ^bb536:  // pred: ^bb531
      %1667 = arith.addi %1638, %c1_i32 : i32
      cf.br ^bb529(%1667 : i32)
    ^bb537:  // pred: ^bb529
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %1668 = arith.cmpi sgt, %1205, %c0_i32 : i32
      cf.cond_br %1668, ^bb538, ^bb542
    ^bb538:  // pred: ^bb537
      %1669 = arith.subi %1204, %c2_i32 : i32
      %coord_1255 = cute.make_coord(%1669) : (i32) -> !cute.coord<"(_,_,_,?)">
      %1670:3 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_1256 = cute.assume(%1670#1) : (i64) -> !cute.i64<divby 128>
      %stride_1257 = cute.make_stride(%iv_1256) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1258 = cute.make_layout(%137, %stride_1257) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_1259 = cute.crd2idx(%coord_1255, %lay_83) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1260 = cute.add_offset(%ptr_78, %idx_1259) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %append_1261 = cute.append_to_rank<2> (%lay_1258, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1671 = cute.get_scalars(%append_1261) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_1262 = cute.assume(%1671) : (i64) -> !cute.i64<divby 128>
      %stride_1263 = cute.make_stride(%iv_1262) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_1264 = cute.make_layout(%136, %stride_1263) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_1265 = cute.append_to_rank<2> (%lay_1264, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1672 = cute.get_scalars(%append_1265) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_1266 = cute.assume(%1672) : (i64) -> !cute.i64<divby 128>
      %stride_1267 = cute.make_stride(%iv_1266) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_1268 = cute.make_layout(%135, %stride_1267) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb539(%c0_i32 : i32)
    ^bb539(%1673: i32):  // 2 preds: ^bb538, ^bb540
      %1674 = arith.cmpi slt, %1673, %493 : i32
      cf.cond_br %1674, ^bb540, ^bb541 {llvm.loop_annotation = #loop_annotation}
    ^bb540:  // pred: ^bb539
      %coord_1269 = cute.make_coord(%1673) : (i32) -> !cute.coord<"(_,?)">
      %idx_1270 = cute.crd2idx(%coord_1269, %lay_1268) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_1271 = cute.add_offset(%ptr_1260, %idx_1270) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1272 = cute.crd2idx(%coord_1269, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1273 = cute.add_offset(%ptr_84, %idx_1272) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1274 = cute.crd2idx(%coord_1269, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_1275 = cute.add_offset(%iter_161, %idx_1274) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1675 = builtin.unrealized_conversion_cast %ptr_1275 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1676 = llvm.load %1675 : !llvm.ptr -> i8
      %1677 = llvm.trunc %1676 : i8 to i1
      %iter_1276 = cute.recast_iter(%ptr_1271) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_1277 = cute.recast_iter(%ptr_1273) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_1277 : !cute.ptr<i128, smem>, %iter_1276 : !cute.ptr<i128, gmem>, %1677 : i1) {cache_mode = <global>}
      %1678 = arith.addi %1673, %c1_i32 : i32
      cf.br ^bb539(%1678 : i32)
    ^bb541:  // pred: ^bb539
      nvvm.cp.async.commit.group
      cf.br ^bb542
    ^bb542:  // 2 preds: ^bb537, ^bb541
      %rmem_1278 = cute.memref.alloca() : !memref_rmem_f32_1
      %iter_1279 = cute.get_iter(%rmem_1278) : !memref_rmem_f32_1
      %1679 = builtin.unrealized_conversion_cast %iter_1279 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_1280 = cute.add_offset(%iter_1279, %117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %1680 = builtin.unrealized_conversion_cast %ptr_1280 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_1281 = cute.add_offset(%iter_1279, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %1681 = builtin.unrealized_conversion_cast %ptr_1281 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_1282 = cute.add_offset(%iter_1279, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %1682 = builtin.unrealized_conversion_cast %ptr_1282 : !cute.ptr<f32, rmem> to !llvm.ptr
      cf.br ^bb543(%c0_i32 : i32)
    ^bb543(%1683: i32):  // 2 preds: ^bb542, ^bb544
      %1684 = arith.cmpi slt, %1683, %492 : i32
      cf.cond_br %1684, ^bb544, ^bb545 {llvm.loop_annotation = #loop_annotation}
    ^bb544:  // pred: ^bb543
      %1685 = llvm.load %1198 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1685, %1679 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1686 = llvm.load %1199 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1686, %1680 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1687 = llvm.load %1200 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1687, %1681 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1688 = llvm.load %1201 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1688, %1682 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1689 = arith.addi %1683, %c1_i32 : i32
      cf.br ^bb543(%1689 : i32)
    ^bb545:  // pred: ^bb543
      %view_1283 = cute.make_view(%iter_1026) : !memref_rmem_f32_4
      %1690 = cute.memref.load_vec %view_1283 : !memref_rmem_f32_4
      %1691 = vector.reduction <maximumf>, %1690, %cst_5 : vector<16xf32> into f32
      %1692 = nvvm.shfl.sync  bfly %c-1_i32, %1691, %c2_i32, %c31_i32 : f32 -> f32
      %1693 = nvvm.fmax %1691, %1692
      %1694 = nvvm.shfl.sync  bfly %c-1_i32, %1693, %c1_i32, %c31_i32 : f32 -> f32
      %1695 = nvvm.fmax %1693, %1694
      %1696 = cute.memref.load(%rmem_1278, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1697 = nvvm.fmax %1696, %1695
      %1698 = arith.mulf %1690, %966 : vector<16xf32>
      %1699 = arith.mulf %1697, %arg4 : f32
      %1700 = vector.broadcast %1699 : f32 to vector<16xf32>
      %1701 = arith.subf %1698, %1700 : vector<16xf32>
      %1702 = math.exp2 %1701 fastmath<fast> : vector<16xf32>
      %1703 = vector.reduction <add>, %1702, %cst_6 : vector<16xf32> into f32
      %1704 = arith.mulf %1696, %arg4 : f32
      %1705 = arith.subf %1704, %1699 : f32
      %1706 = math.exp2 %1705 fastmath<fast> : f32
      %1707 = cute.memref.load(%rmem_424, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1708 = arith.mulf %1707, %1706 : f32
      %1709 = arith.addf %1708, %1703 : f32
      %1710 = cute.memref.load_vec %view_1018 : !memref_rmem_f32_7
      %1711 = vector.broadcast %1706 : f32 to vector<32xf32>
      %1712 = arith.mulf %1710, %1711 : vector<32xf32>
      cute.memref.store_vec %1712, %view_1018 : !memref_rmem_f32_7
      cute.memref.store(%rmem_423, %68, %1697) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store(%rmem_424, %68, %1709) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store_vec %1702, %view_1283 : !memref_rmem_f32_4
      %ptr_1284 = cute.add_offset(%iter_1026, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1285 = cute.make_view(%ptr_1284) : !memref_rmem_f32_5
      %1713 = cute.memref.load_vec %view_1285 : !memref_rmem_f32_5
      %1714 = vector.reduction <maximumf>, %1713, %cst_5 : vector<16xf32> into f32
      %1715 = nvvm.shfl.sync  bfly %c-1_i32, %1714, %c2_i32, %c31_i32 : f32 -> f32
      %1716 = nvvm.fmax %1714, %1715
      %1717 = nvvm.shfl.sync  bfly %c-1_i32, %1716, %c1_i32, %c31_i32 : f32 -> f32
      %1718 = nvvm.fmax %1716, %1717
      %1719 = cute.memref.load(%rmem_1278, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1720 = nvvm.fmax %1719, %1718
      %1721 = arith.mulf %1713, %966 : vector<16xf32>
      %1722 = arith.mulf %1720, %arg4 : f32
      %1723 = vector.broadcast %1722 : f32 to vector<16xf32>
      %1724 = arith.subf %1721, %1723 : vector<16xf32>
      %1725 = math.exp2 %1724 fastmath<fast> : vector<16xf32>
      %1726 = vector.reduction <add>, %1725, %cst_6 : vector<16xf32> into f32
      %1727 = arith.mulf %1719, %arg4 : f32
      %1728 = arith.subf %1727, %1722 : f32
      %1729 = math.exp2 %1728 fastmath<fast> : f32
      %1730 = cute.memref.load(%rmem_424, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1731 = arith.mulf %1730, %1729 : f32
      %1732 = arith.addf %1731, %1726 : f32
      %1733 = cute.memref.load_vec %view_1020 : !memref_rmem_f32_8
      %1734 = vector.broadcast %1729 : f32 to vector<32xf32>
      %1735 = arith.mulf %1733, %1734 : vector<32xf32>
      cute.memref.store_vec %1735, %view_1020 : !memref_rmem_f32_8
      cute.memref.store(%rmem_423, %51, %1720) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store(%rmem_424, %51, %1732) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store_vec %1725, %view_1285 : !memref_rmem_f32_5
      %ptr_1286 = cute.add_offset(%iter_1026, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1287 = cute.make_view(%ptr_1286) : !memref_rmem_f32_6
      %1736 = cute.memref.load_vec %view_1287 : !memref_rmem_f32_6
      %1737 = vector.reduction <maximumf>, %1736, %cst_5 : vector<16xf32> into f32
      %1738 = nvvm.shfl.sync  bfly %c-1_i32, %1737, %c2_i32, %c31_i32 : f32 -> f32
      %1739 = nvvm.fmax %1737, %1738
      %1740 = nvvm.shfl.sync  bfly %c-1_i32, %1739, %c1_i32, %c31_i32 : f32 -> f32
      %1741 = nvvm.fmax %1739, %1740
      %1742 = cute.memref.load(%rmem_1278, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1743 = nvvm.fmax %1742, %1741
      %1744 = arith.mulf %1736, %966 : vector<16xf32>
      %1745 = arith.mulf %1743, %arg4 : f32
      %1746 = vector.broadcast %1745 : f32 to vector<16xf32>
      %1747 = arith.subf %1744, %1746 : vector<16xf32>
      %1748 = math.exp2 %1747 fastmath<fast> : vector<16xf32>
      %1749 = vector.reduction <add>, %1748, %cst_6 : vector<16xf32> into f32
      %1750 = arith.mulf %1742, %arg4 : f32
      %1751 = arith.subf %1750, %1745 : f32
      %1752 = math.exp2 %1751 fastmath<fast> : f32
      %1753 = cute.memref.load(%rmem_424, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1754 = arith.mulf %1753, %1752 : f32
      %1755 = arith.addf %1754, %1749 : f32
      %1756 = cute.memref.load_vec %view_1022 : !memref_rmem_f32_9
      %1757 = vector.broadcast %1752 : f32 to vector<32xf32>
      %1758 = arith.mulf %1756, %1757 : vector<32xf32>
      cute.memref.store_vec %1758, %view_1022 : !memref_rmem_f32_9
      cute.memref.store(%rmem_423, %34, %1743) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store(%rmem_424, %34, %1755) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store_vec %1748, %view_1287 : !memref_rmem_f32_6
      %ptr_1288 = cute.add_offset(%iter_1026, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1289 = cute.make_view(%ptr_1288) : !memref_rmem_f32_5
      %1759 = cute.memref.load_vec %view_1289 : !memref_rmem_f32_5
      %1760 = vector.reduction <maximumf>, %1759, %cst_5 : vector<16xf32> into f32
      %1761 = nvvm.shfl.sync  bfly %c-1_i32, %1760, %c2_i32, %c31_i32 : f32 -> f32
      %1762 = nvvm.fmax %1760, %1761
      %1763 = nvvm.shfl.sync  bfly %c-1_i32, %1762, %c1_i32, %c31_i32 : f32 -> f32
      %1764 = nvvm.fmax %1762, %1763
      %1765 = cute.memref.load(%rmem_1278, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1766 = nvvm.fmax %1765, %1764
      %1767 = arith.mulf %1759, %966 : vector<16xf32>
      %1768 = arith.mulf %1766, %arg4 : f32
      %1769 = vector.broadcast %1768 : f32 to vector<16xf32>
      %1770 = arith.subf %1767, %1769 : vector<16xf32>
      %1771 = math.exp2 %1770 fastmath<fast> : vector<16xf32>
      %1772 = vector.reduction <add>, %1771, %cst_6 : vector<16xf32> into f32
      %1773 = arith.mulf %1765, %arg4 : f32
      %1774 = arith.subf %1773, %1768 : f32
      %1775 = math.exp2 %1774 fastmath<fast> : f32
      %1776 = cute.memref.load(%rmem_424, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1777 = arith.mulf %1776, %1775 : f32
      %1778 = arith.addf %1777, %1772 : f32
      %1779 = cute.memref.load_vec %view_1024 : !memref_rmem_f32_8
      %1780 = vector.broadcast %1775 : f32 to vector<32xf32>
      %1781 = arith.mulf %1779, %1780 : vector<32xf32>
      cute.memref.store_vec %1781, %view_1024 : !memref_rmem_f32_8
      cute.memref.store(%rmem_423, %17, %1766) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store(%rmem_424, %17, %1778) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store_vec %1771, %view_1289 : !memref_rmem_f32_5
      %rmem_1290 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_1291 = cute.get_iter(%rmem_1290) : !memref_rmem_bf16_3
      %1782 = cute.memref.load_vec %rmem_1025 : !memref_rmem_f32_2
      %1783 = arith.truncf %1782 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1783, %rmem_1290 : !memref_rmem_bf16_3
      cf.br ^bb546(%c0_i32 : i32)
    ^bb546(%1784: i32):  // 2 preds: ^bb545, ^bb547
      %1785 = arith.cmpi slt, %1784, %493 : i32
      cf.cond_br %1785, ^bb547, ^bb548 {llvm.loop_annotation = #loop_annotation}
    ^bb547:  // pred: ^bb546
      %coord_1292 = cute.make_coord(%1784) : (i32) -> !cute.coord<"(_,?)">
      %idx_1293 = cute.crd2idx(%coord_1292, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1294 = cute.add_offset(%ptr_117, %idx_1293) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1295 = cute.crd2idx(%coord_1292, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1296 = cute.add_offset(%iter_120, %idx_1295) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1786 = cute_nvgpu.arch.copy.ldsm %ptr_1294{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1787 = vector.extractelement %1786[%130 : i32] : vector<4xi32>
      %1788 = builtin.unrealized_conversion_cast %ptr_1296 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1787, %1788 : i32, !llvm.ptr
      %1789 = vector.extractelement %1786[%129 : i32] : vector<4xi32>
      %ptr_1297 = cute.add_offset(%ptr_1296, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1790 = builtin.unrealized_conversion_cast %ptr_1297 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1789, %1790 : i32, !llvm.ptr
      %1791 = vector.extractelement %1786[%128 : i32] : vector<4xi32>
      %ptr_1298 = cute.add_offset(%ptr_1296, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1792 = builtin.unrealized_conversion_cast %ptr_1298 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1791, %1792 : i32, !llvm.ptr
      %1793 = vector.extractelement %1786[%126 : i32] : vector<4xi32>
      %ptr_1299 = cute.add_offset(%ptr_1296, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1794 = builtin.unrealized_conversion_cast %ptr_1299 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1793, %1794 : i32, !llvm.ptr
      %1795 = arith.addi %1784, %c1_i32 : i32
      cf.br ^bb546(%1795 : i32)
    ^bb548:  // pred: ^bb546
      cf.br ^bb549(%c0_i32 : i32)
    ^bb549(%1796: i32):  // 2 preds: ^bb548, ^bb550
      %1797 = arith.cmpi slt, %1796, %493 : i32
      cf.cond_br %1797, ^bb550, ^bb551 {llvm.loop_annotation = #loop_annotation}
    ^bb550:  // pred: ^bb549
      %coord_1300 = cute.make_coord(%1796) : (i32) -> !cute.coord<"(_,?)">
      %idx_1301 = cute.crd2idx(%coord_1300, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1302 = cute.add_offset(%ptr_926, %idx_1301) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1303 = cute.crd2idx(%coord_1300, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1304 = cute.add_offset(%ptr_927, %idx_1303) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1798 = cute_nvgpu.arch.copy.ldsm %ptr_1302{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1799 = vector.extractelement %1798[%130 : i32] : vector<4xi32>
      %1800 = builtin.unrealized_conversion_cast %ptr_1304 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1799, %1800 : i32, !llvm.ptr
      %1801 = vector.extractelement %1798[%129 : i32] : vector<4xi32>
      %ptr_1305 = cute.add_offset(%ptr_1304, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1802 = builtin.unrealized_conversion_cast %ptr_1305 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1801, %1802 : i32, !llvm.ptr
      %1803 = vector.extractelement %1798[%128 : i32] : vector<4xi32>
      %ptr_1306 = cute.add_offset(%ptr_1304, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1804 = builtin.unrealized_conversion_cast %ptr_1306 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1803, %1804 : i32, !llvm.ptr
      %1805 = vector.extractelement %1798[%126 : i32] : vector<4xi32>
      %ptr_1307 = cute.add_offset(%ptr_1304, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1806 = builtin.unrealized_conversion_cast %ptr_1307 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1805, %1806 : i32, !llvm.ptr
      %1807 = arith.addi %1796, %c1_i32 : i32
      cf.br ^bb549(%1807 : i32)
    ^bb551:  // pred: ^bb549
      cf.br ^bb552(%c0_i32 : i32)
    ^bb552(%1808: i32):  // 2 preds: ^bb551, ^bb559
      %1809 = arith.cmpi slt, %1808, %492 : i32
      cf.cond_br %1809, ^bb553, ^bb560 {llvm.loop_annotation = #loop_annotation}
    ^bb553:  // pred: ^bb552
      cf.br ^bb554(%c0_i32 : i32)
    ^bb554(%1810: i32):  // 2 preds: ^bb553, ^bb558
      %1811 = arith.cmpi slt, %1810, %442 : i32
      cf.cond_br %1811, ^bb555, ^bb559 {llvm.loop_annotation = #loop_annotation}
    ^bb555:  // pred: ^bb554
      %coord_1308 = cute.make_coord(%1810, %1808) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1309 = cute.crd2idx(%coord_1308, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1310 = cute.add_offset(%iter_1291, %idx_1309) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1812 = builtin.unrealized_conversion_cast %ptr_1310 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1813 = llvm.getelementptr %1812[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1814 = llvm.getelementptr %1812[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1815 = llvm.getelementptr %1812[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb556(%c0_i32 : i32)
    ^bb556(%1816: i32):  // 2 preds: ^bb555, ^bb557
      %1817 = arith.cmpi slt, %1816, %1038 : i32
      cf.cond_br %1817, ^bb557, ^bb558 {llvm.loop_annotation = #loop_annotation}
    ^bb557:  // pred: ^bb556
      %coord_1311 = cute.make_coord(%1816, %1808) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1312 = cute.make_coord(%1810, %1816) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1313 = cute.crd2idx(%coord_1311, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1314 = cute.add_offset(%iter_120, %idx_1313) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1315 = cute.crd2idx(%coord_1312, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1316 = cute.add_offset(%iter_97, %idx_1315) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1818 = llvm.load %1812 : !llvm.ptr -> i32
      %1819 = llvm.load %1813 : !llvm.ptr -> i32
      %1820 = llvm.load %1814 : !llvm.ptr -> i32
      %1821 = llvm.load %1815 : !llvm.ptr -> i32
      %1822 = builtin.unrealized_conversion_cast %ptr_1314 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1823 = llvm.load %1822 : !llvm.ptr -> i32
      %1824 = llvm.getelementptr %1822[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1825 = llvm.load %1824 : !llvm.ptr -> i32
      %1826 = builtin.unrealized_conversion_cast %ptr_1316 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1827 = llvm.load %1826 : !llvm.ptr -> f32
      %1828 = llvm.getelementptr %1826[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1829 = llvm.load %1828 : !llvm.ptr -> f32
      %1830 = llvm.getelementptr %1826[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1831 = llvm.load %1830 : !llvm.ptr -> f32
      %1832 = llvm.getelementptr %1826[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1833 = llvm.load %1832 : !llvm.ptr -> f32
      %1834:4 = cute_nvgpu.arch.mma.SM80 A[%1818, %1819, %1820, %1821]  B[%1823, %1825]  C[%1827, %1829, %1831, %1833] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1834#0, %1826 : f32, !llvm.ptr
      llvm.store %1834#1, %1828 : f32, !llvm.ptr
      llvm.store %1834#2, %1830 : f32, !llvm.ptr
      llvm.store %1834#3, %1832 : f32, !llvm.ptr
      %1835 = arith.addi %1816, %c1_i32 : i32
      cf.br ^bb556(%1835 : i32)
    ^bb558:  // pred: ^bb556
      %1836 = arith.addi %1810, %c1_i32 : i32
      cf.br ^bb554(%1836 : i32)
    ^bb559:  // pred: ^bb554
      %1837 = arith.addi %1808, %c1_i32 : i32
      cf.br ^bb552(%1837 : i32)
    ^bb560:  // pred: ^bb552
      cf.br ^bb561(%c0_i32 : i32)
    ^bb561(%1838: i32):  // 2 preds: ^bb560, ^bb562
      %1839 = arith.cmpi slt, %1838, %493 : i32
      cf.cond_br %1839, ^bb562, ^bb563 {llvm.loop_annotation = #loop_annotation}
    ^bb562:  // pred: ^bb561
      %coord_1317 = cute.make_coord(%1838) : (i32) -> !cute.coord<"(_,?)">
      %idx_1318 = cute.crd2idx(%coord_1317, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1319 = cute.add_offset(%ptr_945, %idx_1318) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1320 = cute.crd2idx(%coord_1317, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1321 = cute.add_offset(%ptr_946, %idx_1320) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1840 = cute_nvgpu.arch.copy.ldsm %ptr_1319{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1841 = vector.extractelement %1840[%130 : i32] : vector<4xi32>
      %1842 = builtin.unrealized_conversion_cast %ptr_1321 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1841, %1842 : i32, !llvm.ptr
      %1843 = vector.extractelement %1840[%129 : i32] : vector<4xi32>
      %ptr_1322 = cute.add_offset(%ptr_1321, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1844 = builtin.unrealized_conversion_cast %ptr_1322 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1843, %1844 : i32, !llvm.ptr
      %1845 = vector.extractelement %1840[%128 : i32] : vector<4xi32>
      %ptr_1323 = cute.add_offset(%ptr_1321, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1846 = builtin.unrealized_conversion_cast %ptr_1323 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1845, %1846 : i32, !llvm.ptr
      %1847 = vector.extractelement %1840[%126 : i32] : vector<4xi32>
      %ptr_1324 = cute.add_offset(%ptr_1321, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1848 = builtin.unrealized_conversion_cast %ptr_1324 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1847, %1848 : i32, !llvm.ptr
      %1849 = arith.addi %1838, %c1_i32 : i32
      cf.br ^bb561(%1849 : i32)
    ^bb563:  // pred: ^bb561
      %ptr_1325 = cute.add_offset(%iter_1291, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb564(%c0_i32 : i32)
    ^bb564(%1850: i32):  // 2 preds: ^bb563, ^bb571
      %1851 = arith.cmpi slt, %1850, %492 : i32
      cf.cond_br %1851, ^bb565, ^bb572 {llvm.loop_annotation = #loop_annotation}
    ^bb565:  // pred: ^bb564
      cf.br ^bb566(%c0_i32 : i32)
    ^bb566(%1852: i32):  // 2 preds: ^bb565, ^bb570
      %1853 = arith.cmpi slt, %1852, %442 : i32
      cf.cond_br %1853, ^bb567, ^bb571 {llvm.loop_annotation = #loop_annotation}
    ^bb567:  // pred: ^bb566
      %coord_1326 = cute.make_coord(%1852, %1850) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1327 = cute.crd2idx(%coord_1326, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1328 = cute.add_offset(%ptr_1325, %idx_1327) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1854 = builtin.unrealized_conversion_cast %ptr_1328 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1855 = llvm.getelementptr %1854[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1856 = llvm.getelementptr %1854[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1857 = llvm.getelementptr %1854[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb568(%c0_i32 : i32)
    ^bb568(%1858: i32):  // 2 preds: ^bb567, ^bb569
      %1859 = arith.cmpi slt, %1858, %1038 : i32
      cf.cond_br %1859, ^bb569, ^bb570 {llvm.loop_annotation = #loop_annotation}
    ^bb569:  // pred: ^bb568
      %coord_1329 = cute.make_coord(%1858, %1850) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1330 = cute.make_coord(%1852, %1858) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1331 = cute.crd2idx(%coord_1329, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1332 = cute.add_offset(%ptr_927, %idx_1331) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1333 = cute.crd2idx(%coord_1330, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1334 = cute.add_offset(%iter_97, %idx_1333) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1860 = llvm.load %1854 : !llvm.ptr -> i32
      %1861 = llvm.load %1855 : !llvm.ptr -> i32
      %1862 = llvm.load %1856 : !llvm.ptr -> i32
      %1863 = llvm.load %1857 : !llvm.ptr -> i32
      %1864 = builtin.unrealized_conversion_cast %ptr_1332 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1865 = llvm.load %1864 : !llvm.ptr -> i32
      %1866 = llvm.getelementptr %1864[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1867 = llvm.load %1866 : !llvm.ptr -> i32
      %1868 = builtin.unrealized_conversion_cast %ptr_1334 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1869 = llvm.load %1868 : !llvm.ptr -> f32
      %1870 = llvm.getelementptr %1868[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1871 = llvm.load %1870 : !llvm.ptr -> f32
      %1872 = llvm.getelementptr %1868[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1873 = llvm.load %1872 : !llvm.ptr -> f32
      %1874 = llvm.getelementptr %1868[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1875 = llvm.load %1874 : !llvm.ptr -> f32
      %1876:4 = cute_nvgpu.arch.mma.SM80 A[%1860, %1861, %1862, %1863]  B[%1865, %1867]  C[%1869, %1871, %1873, %1875] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1876#0, %1868 : f32, !llvm.ptr
      llvm.store %1876#1, %1870 : f32, !llvm.ptr
      llvm.store %1876#2, %1872 : f32, !llvm.ptr
      llvm.store %1876#3, %1874 : f32, !llvm.ptr
      %1877 = arith.addi %1858, %c1_i32 : i32
      cf.br ^bb568(%1877 : i32)
    ^bb570:  // pred: ^bb568
      %1878 = arith.addi %1852, %c1_i32 : i32
      cf.br ^bb566(%1878 : i32)
    ^bb571:  // pred: ^bb566
      %1879 = arith.addi %1850, %c1_i32 : i32
      cf.br ^bb564(%1879 : i32)
    ^bb572:  // pred: ^bb564
      cf.br ^bb573(%c0_i32 : i32)
    ^bb573(%1880: i32):  // 2 preds: ^bb572, ^bb574
      %1881 = arith.cmpi slt, %1880, %493 : i32
      cf.cond_br %1881, ^bb574, ^bb575 {llvm.loop_annotation = #loop_annotation}
    ^bb574:  // pred: ^bb573
      %coord_1335 = cute.make_coord(%1880) : (i32) -> !cute.coord<"(_,?)">
      %idx_1336 = cute.crd2idx(%coord_1335, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1337 = cute.add_offset(%ptr_965, %idx_1336) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1338 = cute.crd2idx(%coord_1335, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1339 = cute.add_offset(%ptr_966, %idx_1338) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1882 = cute_nvgpu.arch.copy.ldsm %ptr_1337{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1883 = vector.extractelement %1882[%130 : i32] : vector<4xi32>
      %1884 = builtin.unrealized_conversion_cast %ptr_1339 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1883, %1884 : i32, !llvm.ptr
      %1885 = vector.extractelement %1882[%129 : i32] : vector<4xi32>
      %ptr_1340 = cute.add_offset(%ptr_1339, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1886 = builtin.unrealized_conversion_cast %ptr_1340 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1885, %1886 : i32, !llvm.ptr
      %1887 = vector.extractelement %1882[%128 : i32] : vector<4xi32>
      %ptr_1341 = cute.add_offset(%ptr_1339, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1888 = builtin.unrealized_conversion_cast %ptr_1341 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1887, %1888 : i32, !llvm.ptr
      %1889 = vector.extractelement %1882[%126 : i32] : vector<4xi32>
      %ptr_1342 = cute.add_offset(%ptr_1339, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1890 = builtin.unrealized_conversion_cast %ptr_1342 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1889, %1890 : i32, !llvm.ptr
      %1891 = arith.addi %1880, %c1_i32 : i32
      cf.br ^bb573(%1891 : i32)
    ^bb575:  // pred: ^bb573
      %ptr_1343 = cute.add_offset(%iter_1291, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb576(%c0_i32 : i32)
    ^bb576(%1892: i32):  // 2 preds: ^bb575, ^bb583
      %1893 = arith.cmpi slt, %1892, %492 : i32
      cf.cond_br %1893, ^bb577, ^bb584 {llvm.loop_annotation = #loop_annotation}
    ^bb577:  // pred: ^bb576
      cf.br ^bb578(%c0_i32 : i32)
    ^bb578(%1894: i32):  // 2 preds: ^bb577, ^bb582
      %1895 = arith.cmpi slt, %1894, %442 : i32
      cf.cond_br %1895, ^bb579, ^bb583 {llvm.loop_annotation = #loop_annotation}
    ^bb579:  // pred: ^bb578
      %coord_1344 = cute.make_coord(%1894, %1892) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1345 = cute.crd2idx(%coord_1344, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1346 = cute.add_offset(%ptr_1343, %idx_1345) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1896 = builtin.unrealized_conversion_cast %ptr_1346 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1897 = llvm.getelementptr %1896[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1898 = llvm.getelementptr %1896[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1899 = llvm.getelementptr %1896[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb580(%c0_i32 : i32)
    ^bb580(%1900: i32):  // 2 preds: ^bb579, ^bb581
      %1901 = arith.cmpi slt, %1900, %1038 : i32
      cf.cond_br %1901, ^bb581, ^bb582 {llvm.loop_annotation = #loop_annotation}
    ^bb581:  // pred: ^bb580
      %coord_1347 = cute.make_coord(%1900, %1892) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1348 = cute.make_coord(%1894, %1900) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1349 = cute.crd2idx(%coord_1347, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1350 = cute.add_offset(%ptr_946, %idx_1349) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1351 = cute.crd2idx(%coord_1348, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1352 = cute.add_offset(%iter_97, %idx_1351) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1902 = llvm.load %1896 : !llvm.ptr -> i32
      %1903 = llvm.load %1897 : !llvm.ptr -> i32
      %1904 = llvm.load %1898 : !llvm.ptr -> i32
      %1905 = llvm.load %1899 : !llvm.ptr -> i32
      %1906 = builtin.unrealized_conversion_cast %ptr_1350 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1907 = llvm.load %1906 : !llvm.ptr -> i32
      %1908 = llvm.getelementptr %1906[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1909 = llvm.load %1908 : !llvm.ptr -> i32
      %1910 = builtin.unrealized_conversion_cast %ptr_1352 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1911 = llvm.load %1910 : !llvm.ptr -> f32
      %1912 = llvm.getelementptr %1910[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1913 = llvm.load %1912 : !llvm.ptr -> f32
      %1914 = llvm.getelementptr %1910[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1915 = llvm.load %1914 : !llvm.ptr -> f32
      %1916 = llvm.getelementptr %1910[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1917 = llvm.load %1916 : !llvm.ptr -> f32
      %1918:4 = cute_nvgpu.arch.mma.SM80 A[%1902, %1903, %1904, %1905]  B[%1907, %1909]  C[%1911, %1913, %1915, %1917] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1918#0, %1910 : f32, !llvm.ptr
      llvm.store %1918#1, %1912 : f32, !llvm.ptr
      llvm.store %1918#2, %1914 : f32, !llvm.ptr
      llvm.store %1918#3, %1916 : f32, !llvm.ptr
      %1919 = arith.addi %1900, %c1_i32 : i32
      cf.br ^bb580(%1919 : i32)
    ^bb582:  // pred: ^bb580
      %1920 = arith.addi %1894, %c1_i32 : i32
      cf.br ^bb578(%1920 : i32)
    ^bb583:  // pred: ^bb578
      %1921 = arith.addi %1892, %c1_i32 : i32
      cf.br ^bb576(%1921 : i32)
    ^bb584:  // pred: ^bb576
      cf.br ^bb585(%c0_i32 : i32)
    ^bb585(%1922: i32):  // 2 preds: ^bb584, ^bb586
      %1923 = arith.cmpi slt, %1922, %493 : i32
      cf.cond_br %1923, ^bb586, ^bb587 {llvm.loop_annotation = #loop_annotation}
    ^bb586:  // pred: ^bb585
      %coord_1353 = cute.make_coord(%1922) : (i32) -> !cute.coord<"(_,?)">
      %idx_1354 = cute.crd2idx(%coord_1353, %lay_917) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1355 = cute.add_offset(%ptr_117, %idx_1354) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1356 = cute.crd2idx(%coord_1353, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1357 = cute.add_offset(%iter_120, %idx_1356) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1924 = cute_nvgpu.arch.copy.ldsm %ptr_1355{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1925 = vector.extractelement %1924[%130 : i32] : vector<4xi32>
      %1926 = builtin.unrealized_conversion_cast %ptr_1357 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1925, %1926 : i32, !llvm.ptr
      %1927 = vector.extractelement %1924[%129 : i32] : vector<4xi32>
      %ptr_1358 = cute.add_offset(%ptr_1357, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1928 = builtin.unrealized_conversion_cast %ptr_1358 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1927, %1928 : i32, !llvm.ptr
      %1929 = vector.extractelement %1924[%128 : i32] : vector<4xi32>
      %ptr_1359 = cute.add_offset(%ptr_1357, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1930 = builtin.unrealized_conversion_cast %ptr_1359 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1929, %1930 : i32, !llvm.ptr
      %1931 = vector.extractelement %1924[%126 : i32] : vector<4xi32>
      %ptr_1360 = cute.add_offset(%ptr_1357, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1932 = builtin.unrealized_conversion_cast %ptr_1360 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1931, %1932 : i32, !llvm.ptr
      %1933 = arith.addi %1922, %c1_i32 : i32
      cf.br ^bb585(%1933 : i32)
    ^bb587:  // pred: ^bb585
      %ptr_1361 = cute.add_offset(%iter_1291, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb588(%c0_i32 : i32)
    ^bb588(%1934: i32):  // 2 preds: ^bb587, ^bb595
      %1935 = arith.cmpi slt, %1934, %492 : i32
      cf.cond_br %1935, ^bb589, ^bb596 {llvm.loop_annotation = #loop_annotation}
    ^bb589:  // pred: ^bb588
      cf.br ^bb590(%c0_i32 : i32)
    ^bb590(%1936: i32):  // 2 preds: ^bb589, ^bb594
      %1937 = arith.cmpi slt, %1936, %442 : i32
      cf.cond_br %1937, ^bb591, ^bb595 {llvm.loop_annotation = #loop_annotation}
    ^bb591:  // pred: ^bb590
      %coord_1362 = cute.make_coord(%1936, %1934) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1363 = cute.crd2idx(%coord_1362, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1364 = cute.add_offset(%ptr_1361, %idx_1363) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1938 = builtin.unrealized_conversion_cast %ptr_1364 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1939 = llvm.getelementptr %1938[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1940 = llvm.getelementptr %1938[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1941 = llvm.getelementptr %1938[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb592(%c0_i32 : i32)
    ^bb592(%1942: i32):  // 2 preds: ^bb591, ^bb593
      %1943 = arith.cmpi slt, %1942, %1038 : i32
      cf.cond_br %1943, ^bb593, ^bb594 {llvm.loop_annotation = #loop_annotation}
    ^bb593:  // pred: ^bb592
      %coord_1365 = cute.make_coord(%1942, %1934) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1366 = cute.make_coord(%1936, %1942) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1367 = cute.crd2idx(%coord_1365, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1368 = cute.add_offset(%ptr_966, %idx_1367) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1369 = cute.crd2idx(%coord_1366, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1370 = cute.add_offset(%iter_97, %idx_1369) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1944 = llvm.load %1938 : !llvm.ptr -> i32
      %1945 = llvm.load %1939 : !llvm.ptr -> i32
      %1946 = llvm.load %1940 : !llvm.ptr -> i32
      %1947 = llvm.load %1941 : !llvm.ptr -> i32
      %1948 = builtin.unrealized_conversion_cast %ptr_1368 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1949 = llvm.load %1948 : !llvm.ptr -> i32
      %1950 = llvm.getelementptr %1948[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1951 = llvm.load %1950 : !llvm.ptr -> i32
      %1952 = builtin.unrealized_conversion_cast %ptr_1370 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1953 = llvm.load %1952 : !llvm.ptr -> f32
      %1954 = llvm.getelementptr %1952[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1955 = llvm.load %1954 : !llvm.ptr -> f32
      %1956 = llvm.getelementptr %1952[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1957 = llvm.load %1956 : !llvm.ptr -> f32
      %1958 = llvm.getelementptr %1952[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1959 = llvm.load %1958 : !llvm.ptr -> f32
      %1960:4 = cute_nvgpu.arch.mma.SM80 A[%1944, %1945, %1946, %1947]  B[%1949, %1951]  C[%1953, %1955, %1957, %1959] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1960#0, %1952 : f32, !llvm.ptr
      llvm.store %1960#1, %1954 : f32, !llvm.ptr
      llvm.store %1960#2, %1956 : f32, !llvm.ptr
      llvm.store %1960#3, %1958 : f32, !llvm.ptr
      %1961 = arith.addi %1942, %c1_i32 : i32
      cf.br ^bb592(%1961 : i32)
    ^bb594:  // pred: ^bb592
      %1962 = arith.addi %1936, %c1_i32 : i32
      cf.br ^bb590(%1962 : i32)
    ^bb595:  // pred: ^bb590
      %1963 = arith.addi %1934, %c1_i32 : i32
      cf.br ^bb588(%1963 : i32)
    ^bb596:  // pred: ^bb588
      %1964 = arith.addi %1202, %c1_i32 : i32
      cf.br ^bb407(%1964 : i32)
    ^bb597:  // pred: ^bb407
      %1965 = cute.memref.load(%rmem_424, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1966 = nvvm.shfl.sync  bfly %c-1_i32, %1965, %c2_i32, %c31_i32 : f32 -> f32
      %1967 = arith.addf %1965, %1966 : f32
      %1968 = nvvm.shfl.sync  bfly %c-1_i32, %1967, %c1_i32, %c31_i32 : f32 -> f32
      %1969 = arith.addf %1967, %1968 : f32
      cute.memref.store(%rmem_424, %68, %1969) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      %1970 = cute.memref.load(%rmem_424, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1971 = arith.cmpf oeq, %1970, %cst_6 : f32
      %1972 = arith.cmpf une, %1970, %1970 : f32
      %1973 = arith.extui %1971 : i1 to i32
      %1974 = arith.extui %1972 : i1 to i32
      %1975 = arith.select %1971, %1973, %1974 : i32
      %1976 = arith.cmpi ne, %1975, %c0_i32 : i32
      %1977 = nvvm.rcp.approx.ftz.f %1970 : f32
      %1978 = arith.select %1976, %cst_4, %1977 : f32
      %view_1371 = cute.make_view(%iter_97) : !memref_rmem_f32_7
      %1979 = cute.memref.load_vec %view_1371 : !memref_rmem_f32_7
      %1980 = vector.broadcast %1978 : f32 to vector<32xf32>
      %1981 = arith.mulf %1979, %1980 : vector<32xf32>
      cute.memref.store_vec %1981, %view_1371 : !memref_rmem_f32_7
      %1982 = cute.memref.load(%rmem_424, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1983 = nvvm.shfl.sync  bfly %c-1_i32, %1982, %c2_i32, %c31_i32 : f32 -> f32
      %1984 = arith.addf %1982, %1983 : f32
      %1985 = nvvm.shfl.sync  bfly %c-1_i32, %1984, %c1_i32, %c31_i32 : f32 -> f32
      %1986 = arith.addf %1984, %1985 : f32
      cute.memref.store(%rmem_424, %51, %1986) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      %1987 = cute.memref.load(%rmem_424, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1988 = arith.cmpf oeq, %1987, %cst_6 : f32
      %1989 = arith.cmpf une, %1987, %1987 : f32
      %1990 = arith.extui %1988 : i1 to i32
      %1991 = arith.extui %1989 : i1 to i32
      %1992 = arith.select %1988, %1990, %1991 : i32
      %1993 = arith.cmpi ne, %1992, %c0_i32 : i32
      %1994 = nvvm.rcp.approx.ftz.f %1987 : f32
      %1995 = arith.select %1993, %cst_4, %1994 : f32
      %ptr_1372 = cute.add_offset(%iter_97, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1373 = cute.make_view(%ptr_1372) : !memref_rmem_f32_8
      %1996 = cute.memref.load_vec %view_1373 : !memref_rmem_f32_8
      %1997 = vector.broadcast %1995 : f32 to vector<32xf32>
      %1998 = arith.mulf %1996, %1997 : vector<32xf32>
      cute.memref.store_vec %1998, %view_1373 : !memref_rmem_f32_8
      %1999 = cute.memref.load(%rmem_424, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %2000 = nvvm.shfl.sync  bfly %c-1_i32, %1999, %c2_i32, %c31_i32 : f32 -> f32
      %2001 = arith.addf %1999, %2000 : f32
      %2002 = nvvm.shfl.sync  bfly %c-1_i32, %2001, %c1_i32, %c31_i32 : f32 -> f32
      %2003 = arith.addf %2001, %2002 : f32
      cute.memref.store(%rmem_424, %34, %2003) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      %2004 = cute.memref.load(%rmem_424, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %2005 = arith.cmpf oeq, %2004, %cst_6 : f32
      %2006 = arith.cmpf une, %2004, %2004 : f32
      %2007 = arith.extui %2005 : i1 to i32
      %2008 = arith.extui %2006 : i1 to i32
      %2009 = arith.select %2005, %2007, %2008 : i32
      %2010 = arith.cmpi ne, %2009, %c0_i32 : i32
      %2011 = nvvm.rcp.approx.ftz.f %2004 : f32
      %2012 = arith.select %2010, %cst_4, %2011 : f32
      %ptr_1374 = cute.add_offset(%iter_97, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1375 = cute.make_view(%ptr_1374) : !memref_rmem_f32_9
      %2013 = cute.memref.load_vec %view_1375 : !memref_rmem_f32_9
      %2014 = vector.broadcast %2012 : f32 to vector<32xf32>
      %2015 = arith.mulf %2013, %2014 : vector<32xf32>
      cute.memref.store_vec %2015, %view_1375 : !memref_rmem_f32_9
      %2016 = cute.memref.load(%rmem_424, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %2017 = nvvm.shfl.sync  bfly %c-1_i32, %2016, %c2_i32, %c31_i32 : f32 -> f32
      %2018 = arith.addf %2016, %2017 : f32
      %2019 = nvvm.shfl.sync  bfly %c-1_i32, %2018, %c1_i32, %c31_i32 : f32 -> f32
      %2020 = arith.addf %2018, %2019 : f32
      cute.memref.store(%rmem_424, %17, %2020) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      %2021 = cute.memref.load(%rmem_424, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %2022 = arith.cmpf oeq, %2021, %cst_6 : f32
      %2023 = arith.cmpf une, %2021, %2021 : f32
      %2024 = arith.extui %2022 : i1 to i32
      %2025 = arith.extui %2023 : i1 to i32
      %2026 = arith.select %2022, %2024, %2025 : i32
      %2027 = arith.cmpi ne, %2026, %c0_i32 : i32
      %2028 = nvvm.rcp.approx.ftz.f %2021 : f32
      %2029 = arith.select %2027, %cst_4, %2028 : f32
      %ptr_1376 = cute.add_offset(%iter_97, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1377 = cute.make_view(%ptr_1376) : !memref_rmem_f32_8
      %2030 = cute.memref.load_vec %view_1377 : !memref_rmem_f32_8
      %2031 = vector.broadcast %2029 : f32 to vector<32xf32>
      %2032 = arith.mulf %2030, %2031 : vector<32xf32>
      cute.memref.store_vec %2032, %view_1377 : !memref_rmem_f32_8
      %rmem_1378 = cute.memref.alloca() : !memref_rmem_bf16_4
      %2033 = cute.memref.load_vec %rmem_96 : !memref_rmem_f32_
      %2034 = arith.truncf %2033 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %2034, %rmem_1378 : !memref_rmem_bf16_4
      %atom_1379 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %2035 = cute.make_tiled_copy(%atom_1379) : !copy_simt
      %iter_1380 = cute.get_iter(%rmem_1378) : !memref_rmem_bf16_4
      %2036 = arith.divsi %211, %c4_i32 : i32
      %2037 = arith.remsi %2036, %c8_i32 : i32
      %2038 = arith.muli %2037, %c64_i32 : i32
      %2039 = arith.remsi %211, %c4_i32 : i32
      %2040 = arith.muli %2039, %c2_i32 : i32
      %2041 = arith.divsi %2036, %c8_i32 : i32
      %2042 = arith.muli %2041, %c1024_i32 : i32
      %2043 = arith.addi %2040, %2042 : i32
      %2044 = arith.andi %2038, %c64_i32 : i32
      %2045 = arith.cmpi eq, %2044, %c0_i32 : i32
      %2046 = arith.select %2045, %c8_i32, %c-8_i32 : i32
      %2047 = arith.andi %2038, %c128_i32 : i32
      %2048 = arith.cmpi eq, %2047, %c0_i32 : i32
      %2049 = arith.select %2048, %c16_i32, %c-16_i32 : i32
      %2050 = arith.andi %2038, %c256_i32 : i32
      %2051 = arith.cmpi eq, %2050, %c0_i32 : i32
      %2052 = arith.select %2051, %c32_i32, %c-32_i32 : i32
      %2053 = arith.andi %2038, %c448_i32 : i32
      %2054 = arith.shrsi %2053, %c3_i32 : i32
      %2055 = arith.xori %2038, %2054 : i32
      %2056 = arith.addi %2055, %2043 : i32
      %iv_1381 = cute.assume(%2056) : (i32) -> !cute.i32<divby 2>
      %int_tuple_1382 = cute.make_int_tuple(%iv_1381) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_1383 = cute.add_offset(%iter_63, %int_tuple_1382) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>>
      %iv_1384 = cute.assume(%2046) : (i32) -> !cute.i32<divby 8>
      %iv_1385 = cute.assume(%2049) : (i32) -> !cute.i32<divby 16>
      %iv_1386 = cute.assume(%2052) : (i32) -> !cute.i32<divby 32>
      %stride_1387 = cute.make_stride(%iv_1384, %iv_1385, %iv_1386) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %lay_1388 = cute.make_layout(%9, %stride_1387) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %append_1389 = cute.append_to_rank<2> (%lay_1388, %181) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">, !cute.layout<"1:0">
      %2057:3 = cute.get_scalars(%append_1389) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %iv_1390 = cute.assume(%2057#0) : (i32) -> !cute.i32<divby 8>
      %iv_1391 = cute.assume(%2057#1) : (i32) -> !cute.i32<divby 16>
      %iv_1392 = cute.assume(%2057#2) : (i32) -> !cute.i32<divby 32>
      %stride_1393 = cute.make_stride(%iv_1390, %iv_1391, %iv_1392) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %lay_1394 = cute.make_layout(%8, %stride_1393) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %append_1395 = cute.append_to_rank<2> (%lay_1394, %181) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">, !cute.layout<"1:0">
      %2058:3 = cute.get_scalars(%append_1395) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %iv_1396 = cute.assume(%2058#0) : (i32) -> !cute.i32<divby 8>
      %iv_1397 = cute.assume(%2058#1) : (i32) -> !cute.i32<divby 16>
      %iv_1398 = cute.assume(%2058#2) : (i32) -> !cute.i32<divby 32>
      %stride_1399 = cute.make_stride(%iv_1396, %iv_1397, %iv_1398) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %lay_1400 = cute.make_layout(%6, %stride_1399) : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %2059:3 = cute.get_scalars(%lay_1400) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %iv_1401 = cute.assume(%2059#0) : (i32) -> !cute.i32<divby 8>
      %stride_1402 = cute.make_stride(%iv_1401) : (!cute.i32<divby 8>) -> !cute.stride<"((0,(1,512,?{div=8})))">
      %lay_1403 = cute.make_layout(%5, %stride_1402) : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
      %2060 = cute.get_scalars(%lay_1403) <{only_dynamic}> : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
      %iv_1404 = cute.assume(%2060) : (i32) -> !cute.i32<divby 8>
      %int_tuple_1405 = cute.make_int_tuple(%iv_1404) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %2061 = arith.addi %2060, %c512_i32 : i32
      %iv_1406 = cute.assume(%2061) : (i32) -> !cute.i32<divby 8>
      %int_tuple_1407 = cute.make_int_tuple(%iv_1406) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      cf.br ^bb598(%c0_i32 : i32)
    ^bb598(%2062: i32):  // 2 preds: ^bb597, ^bb599
      %2063 = arith.cmpi slt, %2062, %1038 : i32
      cf.cond_br %2063, ^bb599, ^bb600 {llvm.loop_annotation = #loop_annotation}
    ^bb599:  // pred: ^bb598
      %coord_1408 = cute.make_coord(%2062) : (i32) -> !cute.coord<"(_,?)">
      %idx_1409 = cute.crd2idx(%coord_1408, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,2)),((2,8))):((0,(1,8)),((4,16)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1410 = cute.add_offset(%iter_1380, %idx_1409) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1411 = cute.crd2idx(%coord_1408, %lay_1400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1412 = cute.add_offset(%ptr_1383, %idx_1411) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>>
      %2064 = builtin.unrealized_conversion_cast %ptr_1410 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2065 = builtin.unrealized_conversion_cast %ptr_1412 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2066 = llvm.load %2064 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2066, %2065 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1413 = cute.add_offset(%ptr_1410, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_1414 = cute.add_offset(%ptr_1412, %4) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>>
      %2067 = builtin.unrealized_conversion_cast %ptr_1413 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %2068 = builtin.unrealized_conversion_cast %ptr_1414 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2069 = llvm.load %2067 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2069, %2068 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1415 = cute.add_offset(%ptr_1410, %132) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_1416 = cute.add_offset(%ptr_1412, %int_tuple_1405) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
      %2070 = builtin.unrealized_conversion_cast %ptr_1415 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2071 = builtin.unrealized_conversion_cast %ptr_1416 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2072 = llvm.load %2070 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2072, %2071 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1417 = cute.add_offset(%ptr_1410, %3) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_1418 = cute.add_offset(%ptr_1412, %int_tuple_1407) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
      %2073 = builtin.unrealized_conversion_cast %ptr_1417 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %2074 = builtin.unrealized_conversion_cast %ptr_1418 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2075 = llvm.load %2073 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2075, %2074 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %2076 = arith.addi %2062, %c1_i32 : i32
      cf.br ^bb598(%2076 : i32)
    ^bb600:  // pred: ^bb598
      %lay_1419 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %2077:7 = cute.get_scalars(%lay_1419) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_1420 = cute.assume(%2077#3) : (i32) -> !cute.i32<divby 8>
      %shape_1421 = cute.make_shape(%2077#1, %iv_1420) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_1422 = cute.assume(%2077#5) : (i64) -> !cute.i64<divby 8>
      %stride_1423 = cute.make_stride(%iv_1422) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1424 = cute.make_layout(%shape_1421, %stride_1423) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_1425 = cute.crd2idx(%coord, %lay_1419) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_1426 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_1427 = cute.add_offset(%iter_1426, %idx_1425) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %2078:3 = cute.get_scalars(%lay_1424) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %2079 = arith.ceildivsi %2078#0, %c128_i32 : i32
      %2080 = arith.muli %2078#2, %c128_i64 : i64
      %2081 = arith.ceildivsi %2078#1, %c128_i32 : i32
      %shape_1428 = cute.make_shape(%2079, %2081) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_1429 = cute.assume(%2078#2) : (i64) -> !cute.i64<divby 8>
      %iv_1430 = cute.assume(%2080) : (i64) -> !cute.i64<divby 1024>
      %stride_1431 = cute.make_stride(%iv_1429, %iv_1430) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_1432 = cute.make_layout(%shape_1428, %stride_1431) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %2082:4 = cute.get_scalars(%lay_1432) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %iv_1433 = cute.assume(%2082#2) : (i64) -> !cute.i64<divby 8>
      %stride_1434 = cute.make_stride(%iv_1433) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1435 = cute.make_layout(%180, %stride_1434) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_1436 = cute.crd2idx(%coord_13, %lay_1432) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %ptr_1437 = cute.add_offset(%ptr_1427, %idx_1436) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %2083 = cute.get_scalars(%lay_1435) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %2084 = arith.muli %2083, %c16_i64 : i64
      %2085 = arith.muli %216, %2083 : i64
      %2086 = arith.addi %218, %2085 : i64
      %iv_1438 = cute.assume(%2086) : (i64) -> !cute.i64<divby 8>
      %int_tuple_1439 = cute.make_int_tuple(%iv_1438) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_1440 = cute.add_offset(%ptr_1437, %int_tuple_1439) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_1441 = cute.assume(%2084) : (i64) -> !cute.i64<divby 128>
      %stride_1442 = cute.make_stride(%iv_1441) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1443 = cute.make_layout(%177, %stride_1442) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %rmem_1444 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_1445 = cute.get_iter(%rmem_1444) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.br ^bb601(%c0_i32 : i32)
    ^bb601(%2087: i32):  // 2 preds: ^bb600, ^bb602
      %2088 = arith.cmpi slt, %2087, %1038 : i32
      cf.cond_br %2088, ^bb602, ^bb603 {llvm.loop_annotation = #loop_annotation}
    ^bb602:  // pred: ^bb601
      %coord_1446 = cute.make_coord(%2087) : (i32) -> !cute.coord<"(_,?)">
      %idx_1447 = cute.crd2idx(%coord_1446, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((1024,8192)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1448 = cute.add_offset(%ptr_75, %idx_1447) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1449 = cute.crd2idx(%coord_1446, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1450 = cute.add_offset(%iter_1445, %idx_1449) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %2089 = builtin.unrealized_conversion_cast %ptr_1448 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %2090 = builtin.unrealized_conversion_cast %ptr_1450 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2091 = llvm.load %2089 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %2091, %2090 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %2092 = arith.addi %2087, %c1_i32 : i32
      cf.br ^bb601(%2092 : i32)
    ^bb603:  // pred: ^bb601
      %2093 = cute.get_shape(%lay_1419) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1451, %e1_1452, %e2_1453, %e3_1454 = cute.get_leaves(%2093) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1455 = cute.to_int_tuple(%e0_1451) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1456 = cute.to_int_tuple(%e1_1452) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1457 = cute.to_int_tuple(%e2_1453) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1458 = cute.to_int_tuple(%e3_1454) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_1459 = cute.make_shape(%itup_1455, %itup_1456, %itup_1457, %itup_1458) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_1460 = cute.make_layout(%shape_1459, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %2094:4 = cute.get_scalars(%lay_1460) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_1461 = cute.assume(%2094#3) : (i32) -> !cute.i32<divby 8>
      %shape_1462 = cute.make_shape(%2094#1, %iv_1461) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_1463 = cute.make_layout(%shape_1462, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_1464 = cute.crd2idx(%coord, %lay_1460) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_1465 = cute.add_offset(%172, %idx_1464) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %2095:2 = cute.get_scalars(%lay_1463) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %2096 = arith.ceildivsi %2095#0, %c128_i32 : i32
      %2097 = arith.ceildivsi %2095#1, %c128_i32 : i32
      %shape_1466 = cute.make_shape(%2096, %2097) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %lay_1467 = cute.make_layout(%shape_1466, %169) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_1468 = cute.crd2idx(%coord_13, %lay_1467) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_1469 = cute.add_offset(%tup_1465, %idx_1468) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %tup_1470 = cute.add_offset(%tup_1469, %int_tuple_156) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_1471 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_1472, %e1_1473, %e2_1474, %e3_1475 = cute.get_leaves(%tup_1470) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1476 = cute.make_coord(%e3_1475) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1477 = cute.make_coord(%itup_1458) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %2098 = cute.get_scalars(%coord_1476) : !cute.coord<"?{div=8}">
      %2099 = cute.get_scalars(%coord_1477) : !cute.coord<"?{div=8}">
      %2100 = arith.cmpi slt, %2098, %2099 : i32
      %2101 = arith.extui %2100 : i1 to i8
      cute.memref.store(%rmem_1471, %167, %2101) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_1478 = cute.add_offset(%tup_1470, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1479, %e1_1480, %e2_1481, %e3_1482 = cute.get_leaves(%tup_1478) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1483 = cute.make_coord(%e3_1482) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %2102 = cute.get_scalars(%coord_1483) : !cute.coord<"?{div=8}">
      %2103 = arith.cmpi slt, %2102, %2099 : i32
      %2104 = arith.extui %2103 : i1 to i8
      cute.memref.store(%rmem_1471, %165, %2104) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_1484 = cute.make_coord(%e1_1473) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1485 = cute.make_coord(%itup_1456) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2105 = cute.get_scalars(%coord_1484) : !cute.coord<"?">
      %2106 = cute.get_scalars(%coord_1485) : !cute.coord<"?">
      %2107 = arith.cmpi slt, %2105, %2106 : i32
      cf.cond_br %2107, ^bb604, ^bb610
    ^bb604:  // pred: ^bb603
      %iter_1486 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb605(%c0_i32 : i32)
    ^bb605(%2108: i32):  // 2 preds: ^bb604, ^bb608
      %2109 = arith.cmpi slt, %2108, %442 : i32
      cf.cond_br %2109, ^bb606, ^bb609 {llvm.loop_annotation = #loop_annotation}
    ^bb606:  // pred: ^bb605
      %coord_1487 = cute.make_coord(%2108) : (i32) -> !cute.coord<"(_,?)">
      %idx_1488 = cute.crd2idx(%coord_1487, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1489 = cute.add_offset(%iter_1445, %idx_1488) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1490 = cute.crd2idx(%coord_1487, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1491 = cute.add_offset(%ptr_1440, %idx_1490) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1492 = cute.crd2idx(%coord_1487, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1493 = cute.add_offset(%iter_1486, %idx_1492) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2110 = builtin.unrealized_conversion_cast %ptr_1493 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2111 = llvm.load %2110 : !llvm.ptr -> i8
      %2112 = llvm.icmp "ne" %2111, %0 : i8
      cf.cond_br %2112, ^bb607, ^bb608
    ^bb607:  // pred: ^bb606
      %2113 = builtin.unrealized_conversion_cast %ptr_1489 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2114 = builtin.unrealized_conversion_cast %ptr_1491 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2115 = llvm.load %2113 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2115, %2114 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb608
    ^bb608:  // 2 preds: ^bb606, ^bb607
      %2116 = arith.addi %2108, %c1_i32 : i32
      cf.br ^bb605(%2116 : i32)
    ^bb609:  // pred: ^bb605
      cf.br ^bb610
    ^bb610:  // 2 preds: ^bb603, ^bb609
      %tup_1494 = cute.add_offset(%tup_1470, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1495, %e1_1496, %e2_1497, %e3_1498 = cute.get_leaves(%tup_1494) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1499 = cute.make_coord(%e1_1496) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2117 = cute.get_scalars(%coord_1499) : !cute.coord<"?">
      %2118 = arith.cmpi slt, %2117, %2106 : i32
      cf.cond_br %2118, ^bb611, ^bb617
    ^bb611:  // pred: ^bb610
      %ptr_1500 = cute.add_offset(%iter_1445, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1501 = cute.crd2idx(%159, %lay_1443) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_1502 = cute.add_offset(%ptr_1440, %idx_1501) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1503 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb612(%c0_i32 : i32)
    ^bb612(%2119: i32):  // 2 preds: ^bb611, ^bb615
      %2120 = arith.cmpi slt, %2119, %442 : i32
      cf.cond_br %2120, ^bb613, ^bb616 {llvm.loop_annotation = #loop_annotation}
    ^bb613:  // pred: ^bb612
      %coord_1504 = cute.make_coord(%2119) : (i32) -> !cute.coord<"(_,?)">
      %idx_1505 = cute.crd2idx(%coord_1504, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1506 = cute.add_offset(%ptr_1500, %idx_1505) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1507 = cute.crd2idx(%coord_1504, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1508 = cute.add_offset(%ptr_1502, %idx_1507) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1509 = cute.crd2idx(%coord_1504, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1510 = cute.add_offset(%iter_1503, %idx_1509) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2121 = builtin.unrealized_conversion_cast %ptr_1510 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2122 = llvm.load %2121 : !llvm.ptr -> i8
      %2123 = llvm.icmp "ne" %2122, %0 : i8
      cf.cond_br %2123, ^bb614, ^bb615
    ^bb614:  // pred: ^bb613
      %2124 = builtin.unrealized_conversion_cast %ptr_1506 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2125 = builtin.unrealized_conversion_cast %ptr_1508 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2126 = llvm.load %2124 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2126, %2125 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb615
    ^bb615:  // 2 preds: ^bb613, ^bb614
      %2127 = arith.addi %2119, %c1_i32 : i32
      cf.br ^bb612(%2127 : i32)
    ^bb616:  // pred: ^bb612
      cf.br ^bb617
    ^bb617:  // 2 preds: ^bb610, ^bb616
      %tup_1511 = cute.add_offset(%tup_1470, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1512, %e1_1513, %e2_1514, %e3_1515 = cute.get_leaves(%tup_1511) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1516 = cute.make_coord(%e1_1513) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2128 = cute.get_scalars(%coord_1516) : !cute.coord<"?">
      %2129 = arith.cmpi slt, %2128, %2106 : i32
      cf.cond_br %2129, ^bb618, ^bb624
    ^bb618:  // pred: ^bb617
      %ptr_1517 = cute.add_offset(%iter_1445, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1518 = cute.crd2idx(%156, %lay_1443) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_1519 = cute.add_offset(%ptr_1440, %idx_1518) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1520 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb619(%c0_i32 : i32)
    ^bb619(%2130: i32):  // 2 preds: ^bb618, ^bb622
      %2131 = arith.cmpi slt, %2130, %442 : i32
      cf.cond_br %2131, ^bb620, ^bb623 {llvm.loop_annotation = #loop_annotation}
    ^bb620:  // pred: ^bb619
      %coord_1521 = cute.make_coord(%2130) : (i32) -> !cute.coord<"(_,?)">
      %idx_1522 = cute.crd2idx(%coord_1521, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1523 = cute.add_offset(%ptr_1517, %idx_1522) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1524 = cute.crd2idx(%coord_1521, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1525 = cute.add_offset(%ptr_1519, %idx_1524) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1526 = cute.crd2idx(%coord_1521, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1527 = cute.add_offset(%iter_1520, %idx_1526) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2132 = builtin.unrealized_conversion_cast %ptr_1527 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2133 = llvm.load %2132 : !llvm.ptr -> i8
      %2134 = llvm.icmp "ne" %2133, %0 : i8
      cf.cond_br %2134, ^bb621, ^bb622
    ^bb621:  // pred: ^bb620
      %2135 = builtin.unrealized_conversion_cast %ptr_1523 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2136 = builtin.unrealized_conversion_cast %ptr_1525 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2137 = llvm.load %2135 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2137, %2136 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb622
    ^bb622:  // 2 preds: ^bb620, ^bb621
      %2138 = arith.addi %2130, %c1_i32 : i32
      cf.br ^bb619(%2138 : i32)
    ^bb623:  // pred: ^bb619
      cf.br ^bb624
    ^bb624:  // 2 preds: ^bb617, ^bb623
      %tup_1528 = cute.add_offset(%tup_1470, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1529, %e1_1530, %e2_1531, %e3_1532 = cute.get_leaves(%tup_1528) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1533 = cute.make_coord(%e1_1530) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2139 = cute.get_scalars(%coord_1533) : !cute.coord<"?">
      %2140 = arith.cmpi slt, %2139, %2106 : i32
      cf.cond_br %2140, ^bb625, ^bb631
    ^bb625:  // pred: ^bb624
      %ptr_1534 = cute.add_offset(%iter_1445, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1535 = cute.crd2idx(%153, %lay_1443) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_1536 = cute.add_offset(%ptr_1440, %idx_1535) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1537 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb626(%c0_i32 : i32)
    ^bb626(%2141: i32):  // 2 preds: ^bb625, ^bb629
      %2142 = arith.cmpi slt, %2141, %442 : i32
      cf.cond_br %2142, ^bb627, ^bb630 {llvm.loop_annotation = #loop_annotation}
    ^bb627:  // pred: ^bb626
      %coord_1538 = cute.make_coord(%2141) : (i32) -> !cute.coord<"(_,?)">
      %idx_1539 = cute.crd2idx(%coord_1538, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1540 = cute.add_offset(%ptr_1534, %idx_1539) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1541 = cute.crd2idx(%coord_1538, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1542 = cute.add_offset(%ptr_1536, %idx_1541) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1543 = cute.crd2idx(%coord_1538, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1544 = cute.add_offset(%iter_1537, %idx_1543) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2143 = builtin.unrealized_conversion_cast %ptr_1544 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2144 = llvm.load %2143 : !llvm.ptr -> i8
      %2145 = llvm.icmp "ne" %2144, %0 : i8
      cf.cond_br %2145, ^bb628, ^bb629
    ^bb628:  // pred: ^bb627
      %2146 = builtin.unrealized_conversion_cast %ptr_1540 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2147 = builtin.unrealized_conversion_cast %ptr_1542 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2148 = llvm.load %2146 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2148, %2147 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb629
    ^bb629:  // 2 preds: ^bb627, ^bb628
      %2149 = arith.addi %2141, %c1_i32 : i32
      cf.br ^bb626(%2149 : i32)
    ^bb630:  // pred: ^bb626
      cf.br ^bb631
    ^bb631:  // 2 preds: ^bb624, ^bb630
      %tup_1545 = cute.add_offset(%tup_1470, %151) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1546, %e1_1547, %e2_1548, %e3_1549 = cute.get_leaves(%tup_1545) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1550 = cute.make_coord(%e1_1547) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2150 = cute.get_scalars(%coord_1550) : !cute.coord<"?">
      %2151 = arith.cmpi slt, %2150, %2106 : i32
      cf.cond_br %2151, ^bb632, ^bb638
    ^bb632:  // pred: ^bb631
      %ptr_1551 = cute.add_offset(%iter_1445, %120) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1552 = cute.crd2idx(%150, %lay_1443) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1553 = cute.add_offset(%ptr_1440, %idx_1552) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1554 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb633(%c0_i32 : i32)
    ^bb633(%2152: i32):  // 2 preds: ^bb632, ^bb636
      %2153 = arith.cmpi slt, %2152, %442 : i32
      cf.cond_br %2153, ^bb634, ^bb637 {llvm.loop_annotation = #loop_annotation}
    ^bb634:  // pred: ^bb633
      %coord_1555 = cute.make_coord(%2152) : (i32) -> !cute.coord<"(_,?)">
      %idx_1556 = cute.crd2idx(%coord_1555, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1557 = cute.add_offset(%ptr_1551, %idx_1556) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1558 = cute.crd2idx(%coord_1555, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1559 = cute.add_offset(%ptr_1553, %idx_1558) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1560 = cute.crd2idx(%coord_1555, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1561 = cute.add_offset(%iter_1554, %idx_1560) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2154 = builtin.unrealized_conversion_cast %ptr_1561 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2155 = llvm.load %2154 : !llvm.ptr -> i8
      %2156 = llvm.icmp "ne" %2155, %0 : i8
      cf.cond_br %2156, ^bb635, ^bb636
    ^bb635:  // pred: ^bb634
      %2157 = builtin.unrealized_conversion_cast %ptr_1557 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2158 = builtin.unrealized_conversion_cast %ptr_1559 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2159 = llvm.load %2157 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2159, %2158 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb636
    ^bb636:  // 2 preds: ^bb634, ^bb635
      %2160 = arith.addi %2152, %c1_i32 : i32
      cf.br ^bb633(%2160 : i32)
    ^bb637:  // pred: ^bb633
      cf.br ^bb638
    ^bb638:  // 2 preds: ^bb631, ^bb637
      %tup_1562 = cute.add_offset(%tup_1470, %148) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1563, %e1_1564, %e2_1565, %e3_1566 = cute.get_leaves(%tup_1562) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1567 = cute.make_coord(%e1_1564) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2161 = cute.get_scalars(%coord_1567) : !cute.coord<"?">
      %2162 = arith.cmpi slt, %2161, %2106 : i32
      cf.cond_br %2162, ^bb639, ^bb645
    ^bb639:  // pred: ^bb638
      %ptr_1568 = cute.add_offset(%iter_1445, %106) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1569 = cute.crd2idx(%147, %lay_1443) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
      %ptr_1570 = cute.add_offset(%ptr_1440, %idx_1569) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1571 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb640(%c0_i32 : i32)
    ^bb640(%2163: i32):  // 2 preds: ^bb639, ^bb643
      %2164 = arith.cmpi slt, %2163, %442 : i32
      cf.cond_br %2164, ^bb641, ^bb644 {llvm.loop_annotation = #loop_annotation}
    ^bb641:  // pred: ^bb640
      %coord_1572 = cute.make_coord(%2163) : (i32) -> !cute.coord<"(_,?)">
      %idx_1573 = cute.crd2idx(%coord_1572, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1574 = cute.add_offset(%ptr_1568, %idx_1573) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1575 = cute.crd2idx(%coord_1572, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1576 = cute.add_offset(%ptr_1570, %idx_1575) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1577 = cute.crd2idx(%coord_1572, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1578 = cute.add_offset(%iter_1571, %idx_1577) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2165 = builtin.unrealized_conversion_cast %ptr_1578 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2166 = llvm.load %2165 : !llvm.ptr -> i8
      %2167 = llvm.icmp "ne" %2166, %0 : i8
      cf.cond_br %2167, ^bb642, ^bb643
    ^bb642:  // pred: ^bb641
      %2168 = builtin.unrealized_conversion_cast %ptr_1574 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2169 = builtin.unrealized_conversion_cast %ptr_1576 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2170 = llvm.load %2168 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2170, %2169 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb643
    ^bb643:  // 2 preds: ^bb641, ^bb642
      %2171 = arith.addi %2163, %c1_i32 : i32
      cf.br ^bb640(%2171 : i32)
    ^bb644:  // pred: ^bb640
      cf.br ^bb645
    ^bb645:  // 2 preds: ^bb638, ^bb644
      %tup_1579 = cute.add_offset(%tup_1470, %145) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1580, %e1_1581, %e2_1582, %e3_1583 = cute.get_leaves(%tup_1579) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1584 = cute.make_coord(%e1_1581) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2172 = cute.get_scalars(%coord_1584) : !cute.coord<"?">
      %2173 = arith.cmpi slt, %2172, %2106 : i32
      cf.cond_br %2173, ^bb646, ^bb652
    ^bb646:  // pred: ^bb645
      %ptr_1585 = cute.add_offset(%iter_1445, %113) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1586 = cute.crd2idx(%144, %lay_1443) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
      %ptr_1587 = cute.add_offset(%ptr_1440, %idx_1586) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1588 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb647(%c0_i32 : i32)
    ^bb647(%2174: i32):  // 2 preds: ^bb646, ^bb650
      %2175 = arith.cmpi slt, %2174, %442 : i32
      cf.cond_br %2175, ^bb648, ^bb651 {llvm.loop_annotation = #loop_annotation}
    ^bb648:  // pred: ^bb647
      %coord_1589 = cute.make_coord(%2174) : (i32) -> !cute.coord<"(_,?)">
      %idx_1590 = cute.crd2idx(%coord_1589, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1591 = cute.add_offset(%ptr_1585, %idx_1590) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1592 = cute.crd2idx(%coord_1589, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1593 = cute.add_offset(%ptr_1587, %idx_1592) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1594 = cute.crd2idx(%coord_1589, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1595 = cute.add_offset(%iter_1588, %idx_1594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2176 = builtin.unrealized_conversion_cast %ptr_1595 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2177 = llvm.load %2176 : !llvm.ptr -> i8
      %2178 = llvm.icmp "ne" %2177, %0 : i8
      cf.cond_br %2178, ^bb649, ^bb650
    ^bb649:  // pred: ^bb648
      %2179 = builtin.unrealized_conversion_cast %ptr_1591 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2180 = builtin.unrealized_conversion_cast %ptr_1593 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2181 = llvm.load %2179 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2181, %2180 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb650
    ^bb650:  // 2 preds: ^bb648, ^bb649
      %2182 = arith.addi %2174, %c1_i32 : i32
      cf.br ^bb647(%2182 : i32)
    ^bb651:  // pred: ^bb647
      cf.br ^bb652
    ^bb652:  // 2 preds: ^bb645, ^bb651
      %tup_1596 = cute.add_offset(%tup_1470, %142) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1597, %e1_1598, %e2_1599, %e3_1600 = cute.get_leaves(%tup_1596) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1601 = cute.make_coord(%e1_1598) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2183 = cute.get_scalars(%coord_1601) : !cute.coord<"?">
      %2184 = arith.cmpi slt, %2183, %2106 : i32
      cf.cond_br %2184, ^bb653, ^bb659
    ^bb653:  // pred: ^bb652
      %ptr_1602 = cute.add_offset(%iter_1445, %103) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1603 = cute.crd2idx(%141, %lay_1443) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
      %ptr_1604 = cute.add_offset(%ptr_1440, %idx_1603) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1605 = cute.get_iter(%rmem_1471) : !memref_rmem_i8_
      cf.br ^bb654(%c0_i32 : i32)
    ^bb654(%2185: i32):  // 2 preds: ^bb653, ^bb657
      %2186 = arith.cmpi slt, %2185, %442 : i32
      cf.cond_br %2186, ^bb655, ^bb658 {llvm.loop_annotation = #loop_annotation}
    ^bb655:  // pred: ^bb654
      %coord_1606 = cute.make_coord(%2185) : (i32) -> !cute.coord<"(_,?)">
      %idx_1607 = cute.crd2idx(%coord_1606, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1608 = cute.add_offset(%ptr_1602, %idx_1607) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1609 = cute.crd2idx(%coord_1606, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1610 = cute.add_offset(%ptr_1604, %idx_1609) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1611 = cute.crd2idx(%coord_1606, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1612 = cute.add_offset(%iter_1605, %idx_1611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2187 = builtin.unrealized_conversion_cast %ptr_1612 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2188 = llvm.load %2187 : !llvm.ptr -> i8
      %2189 = llvm.icmp "ne" %2188, %0 : i8
      cf.cond_br %2189, ^bb656, ^bb657
    ^bb656:  // pred: ^bb655
      %2190 = builtin.unrealized_conversion_cast %ptr_1608 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2191 = builtin.unrealized_conversion_cast %ptr_1610 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2192 = llvm.load %2190 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2192, %2191 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb657
    ^bb657:  // 2 preds: ^bb655, ^bb656
      %2193 = arith.addi %2185, %c1_i32 : i32
      cf.br ^bb654(%2193 : i32)
    ^bb658:  // pred: ^bb654
      cf.br ^bb659
    ^bb659:  // 2 preds: ^bb652, ^bb658
      return
    }
  }
  func.func @cutlass___call_____main__FlashAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Te(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c65536_i64 = arith.constant 65536 : i64
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %cst = arith.constant 1.44269502 : f32
    %c128_i32 = arith.constant 128 : i32
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = global, 128 b>
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
    %0 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %1 = cute.make_tiled_copy(%atom_0) : !copy_simt1
    %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
    %2 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
    %e0, %e1, %e2, %e3 = cute.get_leaves(%2) : !cute.shape<"(?,?,?,?{div=8})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup_1) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %4 = arith.ceildivsi %3, %c128_i32 : i32
    %int_tuple_3 = cute.make_int_tuple(%4) : (i32) -> !cute.int_tuple<"?">
    %e0_4 = cute.get_leaves(%int_tuple_3) : !cute.int_tuple<"?">
    %5 = cute.get_scalars(%e0_4) : !cute.int_tuple<"?">
    %int_tuple_5 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_5) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_6 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %6 = cute.get_scalars(%e0_6) : !cute.int_tuple<"?">
    %int_tuple_7 = cute.make_int_tuple(%itup_2) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_8 = cute.size(%int_tuple_7) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_9 = cute.get_leaves(%sz_8) : !cute.int_tuple<"?">
    %7 = cute.get_scalars(%e0_9) : !cute.int_tuple<"?">
    %8 = arith.mulf %arg4, %cst : f32
    %9 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c65536_i64, gridDim = (%5, %6, %7), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %10 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__FlashAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16g_0<%9> (%arg0, %arg1, %arg2, %arg3, %8) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, f32) -> !cuda.result
    %11 = cuda.cast %10 : !cuda.result -> i32
    cuda.return_if_error %11 : i32
    return %c0_i32 : i32
  }
}
