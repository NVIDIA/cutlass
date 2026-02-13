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
      %c1_i32_7 = arith.constant 1 : i32
      %c0_i32_8 = arith.constant 0 : i32
      %c-1_i32_9 = arith.constant -1 : i32
      %188 = arith.cmpi sgt, %c64_i32, %c0_i32_8 : i32
      %189 = arith.select %188, %c-1_i32_9, %c1_i32_7 : i32
      %190 = arith.addi %189, %187 : i32
      %191 = arith.divsi %190, %c64_i32 : i32
      %192 = arith.addi %c1_i32_7, %191 : i32
      %193 = arith.subi %c0_i32_8, %187 : i32
      %194 = arith.divsi %193, %c64_i32 : i32
      %195 = arith.subi %c0_i32_8, %194 : i32
      %196 = arith.cmpi slt, %187, %c0_i32_8 : i32
      %197 = arith.cmpi sgt, %187, %c0_i32_8 : i32
      %198 = arith.cmpi slt, %c64_i32, %c0_i32_8 : i32
      %199 = arith.cmpi sgt, %c64_i32, %c0_i32_8 : i32
      %200 = arith.andi %196, %198 : i1
      %201 = arith.andi %197, %199 : i1
      %202 = arith.ori %200, %201 : i1
      %203 = arith.select %202, %192, %195 : i32
      %int_tuple_10 = cute.make_int_tuple(%203) : (i32) -> !cute.int_tuple<"?">
      %e0_11 = cute.get_leaves(%int_tuple_10) : !cute.int_tuple<"?">
      %204 = cute.get_scalars(%e0_11) : !cute.int_tuple<"?">
      %205 = arith.subi %204, %c1_i32 : i32
      %coord = cute.make_coord(%184, %185) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %lay_12 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %206:7 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%206#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%206#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_13 = cute.assume(%206#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_13) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_14 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay_12) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_15 = cute.make_coord(%183) : (i32) -> !cute.coord<"(?,0)">
      %207 = cute.get_scalars(%coord_15) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_16 = cute.make_coord(%207) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %208:3 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_17 = arith.constant 1 : i32
      %c0_i32_18 = arith.constant 0 : i32
      %c-1_i32_19 = arith.constant -1 : i32
      %209 = arith.cmpi sgt, %c128_i32, %c0_i32_18 : i32
      %210 = arith.select %209, %c-1_i32_19, %c1_i32_17 : i32
      %211 = arith.addi %210, %208#0 : i32
      %212 = arith.divsi %211, %c128_i32 : i32
      %213 = arith.addi %c1_i32_17, %212 : i32
      %214 = arith.subi %c0_i32_18, %208#0 : i32
      %215 = arith.divsi %214, %c128_i32 : i32
      %216 = arith.subi %c0_i32_18, %215 : i32
      %217 = arith.cmpi slt, %208#0, %c0_i32_18 : i32
      %218 = arith.cmpi sgt, %208#0, %c0_i32_18 : i32
      %219 = arith.cmpi slt, %c128_i32, %c0_i32_18 : i32
      %220 = arith.cmpi sgt, %c128_i32, %c0_i32_18 : i32
      %221 = arith.andi %217, %219 : i1
      %222 = arith.andi %218, %220 : i1
      %223 = arith.ori %221, %222 : i1
      %224 = arith.select %223, %213, %216 : i32
      %225 = arith.muli %208#2, %c128_i64 : i64
      %c1_i32_20 = arith.constant 1 : i32
      %c0_i32_21 = arith.constant 0 : i32
      %c-1_i32_22 = arith.constant -1 : i32
      %226 = arith.cmpi sgt, %c128_i32, %c0_i32_21 : i32
      %227 = arith.select %226, %c-1_i32_22, %c1_i32_20 : i32
      %228 = arith.addi %227, %208#1 : i32
      %229 = arith.divsi %228, %c128_i32 : i32
      %230 = arith.addi %c1_i32_20, %229 : i32
      %231 = arith.subi %c0_i32_21, %208#1 : i32
      %232 = arith.divsi %231, %c128_i32 : i32
      %233 = arith.subi %c0_i32_21, %232 : i32
      %234 = arith.cmpi slt, %208#1, %c0_i32_21 : i32
      %235 = arith.cmpi sgt, %208#1, %c0_i32_21 : i32
      %236 = arith.cmpi slt, %c128_i32, %c0_i32_21 : i32
      %237 = arith.cmpi sgt, %c128_i32, %c0_i32_21 : i32
      %238 = arith.andi %234, %236 : i1
      %239 = arith.andi %235, %237 : i1
      %240 = arith.ori %238, %239 : i1
      %241 = arith.select %240, %230, %233 : i32
      %shape_23 = cute.make_shape(%224, %241) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_24 = cute.assume(%208#2) : (i64) -> !cute.i64<divby 8>
      %iv_25 = cute.assume(%225) : (i64) -> !cute.i64<divby 1024>
      %stride_26 = cute.make_stride(%iv_24, %iv_25) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_27 = cute.make_layout(%shape_23, %stride_26) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %242:4 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %iv_28 = cute.assume(%242#2) : (i64) -> !cute.i64<divby 8>
      %stride_29 = cute.make_stride(%iv_28) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_30 = cute.make_layout(%180, %stride_29) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_31 = cute.crd2idx(%coord_16, %lay_27) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %ptr_32 = cute.add_offset(%ptr, %idx_31) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %243:7 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_33 = cute.assume(%243#3) : (i32) -> !cute.i32<divby 8>
      %shape_34 = cute.make_shape(%243#1, %iv_33) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_35 = cute.assume(%243#5) : (i64) -> !cute.i64<divby 8>
      %stride_36 = cute.make_stride(%iv_35) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_37 = cute.make_layout(%shape_34, %stride_36) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_38 = cute.crd2idx(%coord, %lay) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_39 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_40 = cute.add_offset(%iter_39, %idx_38) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %244:3 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_41 = arith.constant 1 : i32
      %c0_i32_42 = arith.constant 0 : i32
      %c-1_i32_43 = arith.constant -1 : i32
      %245 = arith.cmpi sgt, %c64_i32, %c0_i32_42 : i32
      %246 = arith.select %245, %c-1_i32_43, %c1_i32_41 : i32
      %247 = arith.addi %246, %244#0 : i32
      %248 = arith.divsi %247, %c64_i32 : i32
      %249 = arith.addi %c1_i32_41, %248 : i32
      %250 = arith.subi %c0_i32_42, %244#0 : i32
      %251 = arith.divsi %250, %c64_i32 : i32
      %252 = arith.subi %c0_i32_42, %251 : i32
      %253 = arith.cmpi slt, %244#0, %c0_i32_42 : i32
      %254 = arith.cmpi sgt, %244#0, %c0_i32_42 : i32
      %255 = arith.cmpi slt, %c64_i32, %c0_i32_42 : i32
      %256 = arith.cmpi sgt, %c64_i32, %c0_i32_42 : i32
      %257 = arith.andi %253, %255 : i1
      %258 = arith.andi %254, %256 : i1
      %259 = arith.ori %257, %258 : i1
      %260 = arith.select %259, %249, %252 : i32
      %261 = arith.muli %244#2, %c64_i64 : i64
      %c1_i32_44 = arith.constant 1 : i32
      %c0_i32_45 = arith.constant 0 : i32
      %c-1_i32_46 = arith.constant -1 : i32
      %262 = arith.cmpi sgt, %c128_i32, %c0_i32_45 : i32
      %263 = arith.select %262, %c-1_i32_46, %c1_i32_44 : i32
      %264 = arith.addi %263, %244#1 : i32
      %265 = arith.divsi %264, %c128_i32 : i32
      %266 = arith.addi %c1_i32_44, %265 : i32
      %267 = arith.subi %c0_i32_45, %244#1 : i32
      %268 = arith.divsi %267, %c128_i32 : i32
      %269 = arith.subi %c0_i32_45, %268 : i32
      %270 = arith.cmpi slt, %244#1, %c0_i32_45 : i32
      %271 = arith.cmpi sgt, %244#1, %c0_i32_45 : i32
      %272 = arith.cmpi slt, %c128_i32, %c0_i32_45 : i32
      %273 = arith.cmpi sgt, %c128_i32, %c0_i32_45 : i32
      %274 = arith.andi %270, %272 : i1
      %275 = arith.andi %271, %273 : i1
      %276 = arith.ori %274, %275 : i1
      %277 = arith.select %276, %266, %269 : i32
      %shape_47 = cute.make_shape(%260, %277) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_48 = cute.assume(%244#2) : (i64) -> !cute.i64<divby 8>
      %iv_49 = cute.assume(%261) : (i64) -> !cute.i64<divby 512>
      %stride_50 = cute.make_stride(%iv_48, %iv_49) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_51 = cute.make_layout(%shape_47, %stride_50) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %278:4 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_52 = cute.make_shape(%278#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_53 = cute.assume(%278#2) : (i64) -> !cute.i64<divby 8>
      %iv_54 = cute.assume(%278#3) : (i64) -> !cute.i64<divby 512>
      %stride_55 = cute.make_stride(%iv_53, %iv_54) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_56 = cute.make_layout(%shape_52, %stride_55) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %lay_57 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %279:7 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_58 = cute.assume(%279#3) : (i32) -> !cute.i32<divby 8>
      %shape_59 = cute.make_shape(%279#1, %iv_58) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_60 = cute.assume(%279#5) : (i64) -> !cute.i64<divby 8>
      %stride_61 = cute.make_stride(%iv_60) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_62 = cute.make_layout(%shape_59, %stride_61) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_63 = cute.crd2idx(%coord, %lay_57) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_64 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_65 = cute.add_offset(%iter_64, %idx_63) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %280:3 = cute.get_scalars(%lay_62) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_66 = arith.constant 1 : i32
      %c0_i32_67 = arith.constant 0 : i32
      %c-1_i32_68 = arith.constant -1 : i32
      %281 = arith.cmpi sgt, %c64_i32, %c0_i32_67 : i32
      %282 = arith.select %281, %c-1_i32_68, %c1_i32_66 : i32
      %283 = arith.addi %282, %280#0 : i32
      %284 = arith.divsi %283, %c64_i32 : i32
      %285 = arith.addi %c1_i32_66, %284 : i32
      %286 = arith.subi %c0_i32_67, %280#0 : i32
      %287 = arith.divsi %286, %c64_i32 : i32
      %288 = arith.subi %c0_i32_67, %287 : i32
      %289 = arith.cmpi slt, %280#0, %c0_i32_67 : i32
      %290 = arith.cmpi sgt, %280#0, %c0_i32_67 : i32
      %291 = arith.cmpi slt, %c64_i32, %c0_i32_67 : i32
      %292 = arith.cmpi sgt, %c64_i32, %c0_i32_67 : i32
      %293 = arith.andi %289, %291 : i1
      %294 = arith.andi %290, %292 : i1
      %295 = arith.ori %293, %294 : i1
      %296 = arith.select %295, %285, %288 : i32
      %297 = arith.muli %280#2, %c64_i64 : i64
      %c1_i32_69 = arith.constant 1 : i32
      %c0_i32_70 = arith.constant 0 : i32
      %c-1_i32_71 = arith.constant -1 : i32
      %298 = arith.cmpi sgt, %c128_i32, %c0_i32_70 : i32
      %299 = arith.select %298, %c-1_i32_71, %c1_i32_69 : i32
      %300 = arith.addi %299, %280#1 : i32
      %301 = arith.divsi %300, %c128_i32 : i32
      %302 = arith.addi %c1_i32_69, %301 : i32
      %303 = arith.subi %c0_i32_70, %280#1 : i32
      %304 = arith.divsi %303, %c128_i32 : i32
      %305 = arith.subi %c0_i32_70, %304 : i32
      %306 = arith.cmpi slt, %280#1, %c0_i32_70 : i32
      %307 = arith.cmpi sgt, %280#1, %c0_i32_70 : i32
      %308 = arith.cmpi slt, %c128_i32, %c0_i32_70 : i32
      %309 = arith.cmpi sgt, %c128_i32, %c0_i32_70 : i32
      %310 = arith.andi %306, %308 : i1
      %311 = arith.andi %307, %309 : i1
      %312 = arith.ori %310, %311 : i1
      %313 = arith.select %312, %302, %305 : i32
      %shape_72 = cute.make_shape(%296, %313) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_73 = cute.assume(%280#2) : (i64) -> !cute.i64<divby 8>
      %iv_74 = cute.assume(%297) : (i64) -> !cute.i64<divby 512>
      %stride_75 = cute.make_stride(%iv_73, %iv_74) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_76 = cute.make_layout(%shape_72, %stride_75) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %314:4 = cute.get_scalars(%lay_76) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_77 = cute.make_shape(%314#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_78 = cute.assume(%314#2) : (i64) -> !cute.i64<divby 8>
      %iv_79 = cute.assume(%314#3) : (i64) -> !cute.i64<divby 512>
      %stride_80 = cute.make_stride(%iv_78, %iv_79) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_81 = cute.make_layout(%shape_77, %stride_80) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_82 = cute.add_offset(%smem_ptr, %179) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_83 = cute.add_offset(%smem_ptr, %178) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_84 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_85 = cute.recast_iter(%ptr_82) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_86 = cute.recast_iter(%ptr_83) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %coord_87 = cute.make_coord(%182) : (i32) -> !cute.coord<"?">
      %315 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %316 = cute.get_scalars(%coord_87) <{only_dynamic}> : !cute.coord<"?">
      %317 = arith.muli %315, %c16_i64 : i64
      %318 = arith.divsi %316, %c8_i32 : i32
      %319 = arith.remsi %316, %c8_i32 : i32
      %320 = arith.muli %319, %c8_i32 : i32
      %321 = arith.extsi %318 : i32 to i64
      %322 = arith.muli %321, %315 : i64
      %323 = arith.extsi %320 : i32 to i64
      %324 = arith.addi %323, %322 : i64
      %iv_88 = cute.assume(%324) : (i64) -> !cute.i64<divby 8>
      %int_tuple_89 = cute.make_int_tuple(%iv_88) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_90 = cute.add_offset(%ptr_32, %int_tuple_89) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_91 = cute.assume(%317) : (i64) -> !cute.i64<divby 128>
      %stride_92 = cute.make_stride(%iv_91) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_93 = cute.make_layout(%177, %stride_92) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %325 = arith.remsi %318, %c8_i32 : i32
      %326 = arith.muli %325, %c64_i32 : i32
      %327 = arith.addi %320, %326 : i32
      %328 = arith.divsi %318, %c8_i32 : i32
      %329 = arith.muli %328, %c512_i32 : i32
      %330 = arith.andi %327, %c448_i32 : i32
      %331 = arith.shrsi %330, %c3_i32 : i32
      %332 = arith.xori %327, %331 : i32
      %333 = arith.addi %332, %329 : i32
      %iv_94 = cute.assume(%333) : (i32) -> !cute.i32<divby 8>
      %int_tuple_95 = cute.make_int_tuple(%iv_94) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_96 = cute.add_offset(%iter_84, %int_tuple_95) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %334:3 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %335 = arith.muli %334#1, %c16_i64 : i64
      %336 = arith.muli %321, %334#1 : i64
      %337 = arith.addi %323, %336 : i64
      %iv_97 = cute.assume(%337) : (i64) -> !cute.i64<divby 8>
      %int_tuple_98 = cute.make_int_tuple(%iv_97) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_99 = cute.add_offset(%ptr_40, %int_tuple_98) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_100 = cute.make_shape(%334#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_101 = cute.assume(%335) : (i64) -> !cute.i64<divby 128>
      %iv_102 = cute.assume(%334#2) : (i64) -> !cute.i64<divby 512>
      %stride_103 = cute.make_stride(%iv_101, %iv_102) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_104 = cute.make_layout(%shape_100, %stride_103) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_105 = cute.add_offset(%iter_85, %int_tuple_95) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %338:3 = cute.get_scalars(%lay_81) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %339 = arith.muli %338#1, %c16_i64 : i64
      %340 = arith.muli %321, %338#1 : i64
      %341 = arith.addi %323, %340 : i64
      %iv_106 = cute.assume(%341) : (i64) -> !cute.i64<divby 8>
      %int_tuple_107 = cute.make_int_tuple(%iv_106) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_108 = cute.add_offset(%ptr_65, %int_tuple_107) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_109 = cute.make_shape(%338#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_110 = cute.assume(%339) : (i64) -> !cute.i64<divby 128>
      %iv_111 = cute.assume(%338#2) : (i64) -> !cute.i64<divby 512>
      %stride_112 = cute.make_stride(%iv_110, %iv_111) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_113 = cute.make_layout(%shape_109, %stride_112) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_114 = cute.add_offset(%iter_86, %int_tuple_95) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_115 = cute.memref.alloca() : !memref_rmem_bf16_1
      %rmem_116 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_117 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_118 = cute.get_iter(%rmem_117) : !memref_rmem_f32_
      cute.memref.store_vec %cst_3, %rmem_117 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_119 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %342 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %343 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %344 = cute.make_tiled_copy(%atom_119) : !copy_ldsm_4_2
      %345 = arith.divsi %316, %c16_i32 : i32
      %346 = arith.remsi %316, %c16_i32 : i32
      %347 = arith.remsi %346, %c8_i32 : i32
      %348 = arith.muli %347, %c64_i32 : i32
      %349 = arith.remsi %345, %c2_i32 : i32
      %350 = arith.muli %349, %c8_i32 : i32
      %351 = arith.addi %348, %350 : i32
      %352 = arith.divsi %346, %c8_i32 : i32
      %353 = arith.muli %352, %c512_i32 : i32
      %354 = arith.divsi %345, %c2_i32 : i32
      %355 = arith.muli %354, %c1024_i32 : i32
      %356 = arith.addi %353, %355 : i32
      %357 = arith.andi %351, %c128_i32 : i32
      %358 = arith.cmpi eq, %357, %c0_i32 : i32
      %359 = arith.select %358, %c16_i32, %c-16_i32 : i32
      %360 = arith.andi %351, %c256_i32 : i32
      %361 = arith.cmpi eq, %360, %c0_i32 : i32
      %362 = arith.select %361, %c32_i32, %c-32_i32 : i32
      %363 = arith.andi %351, %c448_i32 : i32
      %364 = arith.shrsi %363, %c3_i32 : i32
      %365 = arith.xori %351, %364 : i32
      %366 = arith.addi %365, %356 : i32
      %iv_120 = cute.assume(%366) : (i32) -> !cute.i32<divby 8>
      %int_tuple_121 = cute.make_int_tuple(%iv_120) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_122 = cute.add_offset(%iter_84, %int_tuple_121) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_123 = cute.assume(%359) : (i32) -> !cute.i32<divby 16>
      %iv_124 = cute.assume(%362) : (i32) -> !cute.i32<divby 32>
      %stride_125 = cute.make_stride(%iv_123, %iv_124) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),4096,((?{div=16},?{div=32}),8192))">
      %lay_126 = cute.make_layout(%175, %stride_125) : !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">
      %iter_127 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %367 = arith.muli %319, %c64_i32 : i32
      %368 = arith.remsi %318, %c2_i32 : i32
      %369 = arith.muli %368, %c8_i32 : i32
      %370 = arith.addi %367, %369 : i32
      %371 = arith.divsi %318, %c2_i32 : i32
      %372 = arith.remsi %371, %c2_i32 : i32
      %373 = arith.muli %372, %c512_i32 : i32
      %374 = arith.andi %370, %c128_i32 : i32
      %375 = arith.cmpi eq, %374, %c0_i32 : i32
      %376 = arith.select %375, %c16_i32, %c-16_i32 : i32
      %377 = arith.andi %370, %c256_i32 : i32
      %378 = arith.cmpi eq, %377, %c0_i32 : i32
      %379 = arith.select %378, %c32_i32, %c-32_i32 : i32
      %380 = arith.andi %370, %c448_i32 : i32
      %381 = arith.shrsi %380, %c3_i32 : i32
      %382 = arith.xori %370, %381 : i32
      %383 = arith.addi %382, %373 : i32
      %iv_128 = cute.assume(%383) : (i32) -> !cute.i32<divby 8>
      %int_tuple_129 = cute.make_int_tuple(%iv_128) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_130 = cute.add_offset(%iter_85, %int_tuple_129) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_131 = cute.assume(%376) : (i32) -> !cute.i32<divby 16>
      %iv_132 = cute.assume(%379) : (i32) -> !cute.i32<divby 32>
      %stride_133 = cute.make_stride(%iv_131, %iv_132) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_134 = cute.make_layout(%174, %stride_133) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %iter_135 = cute.get_iter(%rmem_115) : !memref_rmem_bf16_1
      %384 = arith.addi %365, %353 : i32
      %iv_136 = cute.assume(%384) : (i32) -> !cute.i32<divby 8>
      %int_tuple_137 = cute.make_int_tuple(%iv_136) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_138 = cute.add_offset(%iter_86, %int_tuple_137) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_139 = cute.make_stride(%iv_123, %iv_124) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_140 = cute.make_layout(%173, %stride_139) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iter_141 = cute.get_iter(%rmem_116) : !memref_rmem_bf16_2
      %385 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_142, %e1_143, %e2_144, %e3_145 = cute.get_leaves(%385) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_146 = cute.to_int_tuple(%e0_142) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_147 = cute.to_int_tuple(%e1_143) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_148 = cute.to_int_tuple(%e2_144) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_149 = cute.to_int_tuple(%e3_145) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_150 = cute.make_shape(%itup_146, %itup_147, %itup_148, %itup_149) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_151 = cute.make_layout(%shape_150, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %itup_152 = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_153 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_154 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_155 = cute.make_shape(%itup_152, %itup, %itup_153, %itup_154) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_156 = cute.make_layout(%shape_155, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %386:4 = cute.get_scalars(%lay_151) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_157 = cute.assume(%386#3) : (i32) -> !cute.i32<divby 8>
      %shape_158 = cute.make_shape(%386#1, %iv_157) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_159 = cute.make_layout(%shape_158, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_160 = cute.crd2idx(%coord, %lay_151) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup = cute.add_offset(%172, %idx_160) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %387:2 = cute.get_scalars(%lay_159) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_161 = arith.constant 1 : i32
      %c0_i32_162 = arith.constant 0 : i32
      %c-1_i32_163 = arith.constant -1 : i32
      %388 = arith.cmpi sgt, %c128_i32, %c0_i32_162 : i32
      %389 = arith.select %388, %c-1_i32_163, %c1_i32_161 : i32
      %390 = arith.addi %389, %387#0 : i32
      %391 = arith.divsi %390, %c128_i32 : i32
      %392 = arith.addi %c1_i32_161, %391 : i32
      %393 = arith.subi %c0_i32_162, %387#0 : i32
      %394 = arith.divsi %393, %c128_i32 : i32
      %395 = arith.subi %c0_i32_162, %394 : i32
      %396 = arith.cmpi slt, %387#0, %c0_i32_162 : i32
      %397 = arith.cmpi sgt, %387#0, %c0_i32_162 : i32
      %398 = arith.cmpi slt, %c128_i32, %c0_i32_162 : i32
      %399 = arith.cmpi sgt, %c128_i32, %c0_i32_162 : i32
      %400 = arith.andi %396, %398 : i1
      %401 = arith.andi %397, %399 : i1
      %402 = arith.ori %400, %401 : i1
      %403 = arith.select %402, %392, %395 : i32
      %c1_i32_164 = arith.constant 1 : i32
      %c0_i32_165 = arith.constant 0 : i32
      %c-1_i32_166 = arith.constant -1 : i32
      %404 = arith.cmpi sgt, %c128_i32, %c0_i32_165 : i32
      %405 = arith.select %404, %c-1_i32_166, %c1_i32_164 : i32
      %406 = arith.addi %405, %387#1 : i32
      %407 = arith.divsi %406, %c128_i32 : i32
      %408 = arith.addi %c1_i32_164, %407 : i32
      %409 = arith.subi %c0_i32_165, %387#1 : i32
      %410 = arith.divsi %409, %c128_i32 : i32
      %411 = arith.subi %c0_i32_165, %410 : i32
      %412 = arith.cmpi slt, %387#1, %c0_i32_165 : i32
      %413 = arith.cmpi sgt, %387#1, %c0_i32_165 : i32
      %414 = arith.cmpi slt, %c128_i32, %c0_i32_165 : i32
      %415 = arith.cmpi sgt, %c128_i32, %c0_i32_165 : i32
      %416 = arith.andi %412, %414 : i1
      %417 = arith.andi %413, %415 : i1
      %418 = arith.ori %416, %417 : i1
      %419 = arith.select %418, %408, %411 : i32
      %shape_167 = cute.make_shape(%403, %419) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %lay_168 = cute.make_layout(%shape_167, %169) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_169 = cute.crd2idx(%coord_16, %lay_168) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_170 = cute.add_offset(%tup, %idx_169) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %420:4 = cute.get_scalars(%lay_156) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_171 = cute.assume(%420#3) : (i32) -> !cute.i32<divby 8>
      %shape_172 = cute.make_shape(%420#1, %iv_171) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_173 = cute.make_layout(%shape_172, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_174 = cute.crd2idx(%coord, %lay_156) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_175 = cute.add_offset(%172, %idx_174) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_176 = cute.make_coord(%205) : (i32) -> !cute.coord<"(?,0)">
      %421 = cute.get_scalars(%coord_176) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_177 = cute.make_coord(%421) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %422:2 = cute.get_scalars(%lay_173) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_178 = arith.constant 1 : i32
      %c0_i32_179 = arith.constant 0 : i32
      %c-1_i32_180 = arith.constant -1 : i32
      %423 = arith.cmpi sgt, %c64_i32, %c0_i32_179 : i32
      %424 = arith.select %423, %c-1_i32_180, %c1_i32_178 : i32
      %425 = arith.addi %424, %422#0 : i32
      %426 = arith.divsi %425, %c64_i32 : i32
      %427 = arith.addi %c1_i32_178, %426 : i32
      %428 = arith.subi %c0_i32_179, %422#0 : i32
      %429 = arith.divsi %428, %c64_i32 : i32
      %430 = arith.subi %c0_i32_179, %429 : i32
      %431 = arith.cmpi slt, %422#0, %c0_i32_179 : i32
      %432 = arith.cmpi sgt, %422#0, %c0_i32_179 : i32
      %433 = arith.cmpi slt, %c64_i32, %c0_i32_179 : i32
      %434 = arith.cmpi sgt, %c64_i32, %c0_i32_179 : i32
      %435 = arith.andi %431, %433 : i1
      %436 = arith.andi %432, %434 : i1
      %437 = arith.ori %435, %436 : i1
      %438 = arith.select %437, %427, %430 : i32
      %c1_i32_181 = arith.constant 1 : i32
      %c0_i32_182 = arith.constant 0 : i32
      %c-1_i32_183 = arith.constant -1 : i32
      %439 = arith.cmpi sgt, %c128_i32, %c0_i32_182 : i32
      %440 = arith.select %439, %c-1_i32_183, %c1_i32_181 : i32
      %441 = arith.addi %440, %422#1 : i32
      %442 = arith.divsi %441, %c128_i32 : i32
      %443 = arith.addi %c1_i32_181, %442 : i32
      %444 = arith.subi %c0_i32_182, %422#1 : i32
      %445 = arith.divsi %444, %c128_i32 : i32
      %446 = arith.subi %c0_i32_182, %445 : i32
      %447 = arith.cmpi slt, %422#1, %c0_i32_182 : i32
      %448 = arith.cmpi sgt, %422#1, %c0_i32_182 : i32
      %449 = arith.cmpi slt, %c128_i32, %c0_i32_182 : i32
      %450 = arith.cmpi sgt, %c128_i32, %c0_i32_182 : i32
      %451 = arith.andi %447, %449 : i1
      %452 = arith.andi %448, %450 : i1
      %453 = arith.ori %451, %452 : i1
      %454 = arith.select %453, %443, %446 : i32
      %shape_184 = cute.make_shape(%438, %454) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_185 = cute.make_layout(%shape_184, %168) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_186 = cute.crd2idx(%coord_177, %lay_185) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_187 = cute.add_offset(%tup_175, %idx_186) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %iv_188 = cute.assume(%320) : (i32) -> !cute.i32<divby 8>
      %int_tuple_189 = cute.make_int_tuple(%318, %iv_188) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_190 = cute.add_offset(%tup_170, %int_tuple_189) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %tup_191 = cute.add_offset(%tup_187, %int_tuple_189) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_192 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_193 = cute.memref.alloca() : !memref_rmem_i8_1
      %iter_194 = cute.get_iter(%rmem_193) : !memref_rmem_i8_1
      %e0_195, %e1_196, %e2_197, %e3_198 = cute.get_leaves(%tup_190) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_199 = cute.make_coord(%e3_198) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_200 = cute.make_coord(%itup_149) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %455 = cute.get_scalars(%coord_199) : !cute.coord<"?{div=8}">
      %456 = cute.get_scalars(%coord_200) : !cute.coord<"?{div=8}">
      %457 = arith.cmpi slt, %455, %456 : i32
      %458 = arith.extui %457 : i1 to i8
      cute.memref.store(%rmem_192, %167, %458) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_201 = cute.add_offset(%tup_190, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_202, %e1_203, %e2_204, %e3_205 = cute.get_leaves(%tup_201) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_206 = cute.make_coord(%e3_205) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %459 = cute.get_scalars(%coord_206) : !cute.coord<"?{div=8}">
      %460 = arith.cmpi slt, %459, %456 : i32
      %461 = arith.extui %460 : i1 to i8
      cute.memref.store(%rmem_192, %165, %461) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_207, %e1_208, %e2_209, %e3_210 = cute.get_leaves(%tup_191) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_211 = cute.make_coord(%e3_210) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_212 = cute.make_coord(%itup_154) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %462 = cute.get_scalars(%coord_211) : !cute.coord<"?{div=8}">
      %463 = cute.get_scalars(%coord_212) : !cute.coord<"?{div=8}">
      %464 = arith.cmpi slt, %462, %463 : i32
      %465 = arith.extui %464 : i1 to i8
      cute.memref.store(%rmem_193, %167, %465) : (!memref_rmem_i8_1, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_213 = cute.add_offset(%tup_191, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_214, %e1_215, %e2_216, %e3_217 = cute.get_leaves(%tup_213) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_218 = cute.make_coord(%e3_217) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %466 = cute.get_scalars(%coord_218) : !cute.coord<"?{div=8}">
      %467 = arith.cmpi slt, %466, %463 : i32
      %468 = arith.extui %467 : i1 to i8
      cute.memref.store(%rmem_193, %165, %468) : (!memref_rmem_i8_1, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_219 = cute.make_coord(%e1_196) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_220 = cute.make_coord(%itup_147) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %469 = cute.get_scalars(%coord_219) : !cute.coord<"?">
      %470 = cute.get_scalars(%coord_220) : !cute.coord<"?">
      %471 = arith.cmpi slt, %469, %470 : i32
      cf.cond_br %471, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %iter_221 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %472 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%473: i32):  // 2 preds: ^bb1, ^bb3
      %474 = arith.cmpi slt, %473, %472 : i32
      cf.cond_br %474, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_222 = cute.make_coord(%473) : (i32) -> !cute.coord<"(_,?)">
      %idx_223 = cute.crd2idx(%coord_222, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_224 = cute.add_offset(%ptr_90, %idx_223) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_225 = cute.crd2idx(%coord_222, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_226 = cute.add_offset(%ptr_96, %idx_225) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_227 = cute.crd2idx(%coord_222, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_228 = cute.add_offset(%iter_221, %idx_227) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %475 = builtin.unrealized_conversion_cast %ptr_228 : !cute.ptr<i8, rmem> to !llvm.ptr
      %476 = llvm.load %475 : !llvm.ptr -> i8
      %477 = llvm.trunc %476 : i8 to i1
      %iter_229 = cute.recast_iter(%ptr_224) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_230 = cute.recast_iter(%ptr_226) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_230 : !cute.ptr<i128, smem>, %iter_229 : !cute.ptr<i128, gmem>, %477 : i1) {cache_mode = <global>}
      %478 = arith.addi %473, %c1_i32 : i32
      cf.br ^bb2(%478 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb6
    ^bb5:  // pred: ^bb0
      %view = cute.make_view(%ptr_96) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view : !memref_smem_bf16_
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %tup_231 = cute.add_offset(%tup_190, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_232, %e1_233, %e2_234, %e3_235 = cute.get_leaves(%tup_231) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_236 = cute.make_coord(%e1_233) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %479 = cute.get_scalars(%coord_236) : !cute.coord<"?">
      %480 = arith.cmpi slt, %479, %470 : i32
      cf.cond_br %480, ^bb7, ^bb11
    ^bb7:  // pred: ^bb6
      %idx_237 = cute.crd2idx(%159, %lay_93) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_238 = cute.add_offset(%ptr_90, %idx_237) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_239 = cute.add_offset(%ptr_96, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_240 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %481 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb8(%c0_i32 : i32)
    ^bb8(%482: i32):  // 2 preds: ^bb7, ^bb9
      %483 = arith.cmpi slt, %482, %481 : i32
      cf.cond_br %483, ^bb9, ^bb10 {llvm.loop_annotation = #loop_annotation}
    ^bb9:  // pred: ^bb8
      %coord_241 = cute.make_coord(%482) : (i32) -> !cute.coord<"(_,?)">
      %idx_242 = cute.crd2idx(%coord_241, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_243 = cute.add_offset(%ptr_238, %idx_242) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_244 = cute.crd2idx(%coord_241, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_245 = cute.add_offset(%ptr_239, %idx_244) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_246 = cute.crd2idx(%coord_241, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_247 = cute.add_offset(%iter_240, %idx_246) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %484 = builtin.unrealized_conversion_cast %ptr_247 : !cute.ptr<i8, rmem> to !llvm.ptr
      %485 = llvm.load %484 : !llvm.ptr -> i8
      %486 = llvm.trunc %485 : i8 to i1
      %iter_248 = cute.recast_iter(%ptr_243) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_249 = cute.recast_iter(%ptr_245) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_249 : !cute.ptr<i128, smem>, %iter_248 : !cute.ptr<i128, gmem>, %486 : i1) {cache_mode = <global>}
      %487 = arith.addi %482, %c1_i32 : i32
      cf.br ^bb8(%487 : i32)
    ^bb10:  // pred: ^bb8
      cf.br ^bb12
    ^bb11:  // pred: ^bb6
      %ptr_250 = cute.add_offset(%ptr_96, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_251 = cute.make_view(%ptr_250) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_251 : !memref_smem_bf16_
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %tup_252 = cute.add_offset(%tup_190, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_253, %e1_254, %e2_255, %e3_256 = cute.get_leaves(%tup_252) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_257 = cute.make_coord(%e1_254) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %488 = cute.get_scalars(%coord_257) : !cute.coord<"?">
      %489 = arith.cmpi slt, %488, %470 : i32
      cf.cond_br %489, ^bb13, ^bb17
    ^bb13:  // pred: ^bb12
      %idx_258 = cute.crd2idx(%156, %lay_93) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_259 = cute.add_offset(%ptr_90, %idx_258) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_260 = cute.add_offset(%ptr_96, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_261 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %490 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb14(%c0_i32 : i32)
    ^bb14(%491: i32):  // 2 preds: ^bb13, ^bb15
      %492 = arith.cmpi slt, %491, %490 : i32
      cf.cond_br %492, ^bb15, ^bb16 {llvm.loop_annotation = #loop_annotation}
    ^bb15:  // pred: ^bb14
      %coord_262 = cute.make_coord(%491) : (i32) -> !cute.coord<"(_,?)">
      %idx_263 = cute.crd2idx(%coord_262, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_264 = cute.add_offset(%ptr_259, %idx_263) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_265 = cute.crd2idx(%coord_262, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_266 = cute.add_offset(%ptr_260, %idx_265) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_267 = cute.crd2idx(%coord_262, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_268 = cute.add_offset(%iter_261, %idx_267) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %493 = builtin.unrealized_conversion_cast %ptr_268 : !cute.ptr<i8, rmem> to !llvm.ptr
      %494 = llvm.load %493 : !llvm.ptr -> i8
      %495 = llvm.trunc %494 : i8 to i1
      %iter_269 = cute.recast_iter(%ptr_264) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_270 = cute.recast_iter(%ptr_266) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_270 : !cute.ptr<i128, smem>, %iter_269 : !cute.ptr<i128, gmem>, %495 : i1) {cache_mode = <global>}
      %496 = arith.addi %491, %c1_i32 : i32
      cf.br ^bb14(%496 : i32)
    ^bb16:  // pred: ^bb14
      cf.br ^bb18
    ^bb17:  // pred: ^bb12
      %ptr_271 = cute.add_offset(%ptr_96, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_272 = cute.make_view(%ptr_271) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_272 : !memref_smem_bf16_
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      %tup_273 = cute.add_offset(%tup_190, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_274, %e1_275, %e2_276, %e3_277 = cute.get_leaves(%tup_273) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_278 = cute.make_coord(%e1_275) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %497 = cute.get_scalars(%coord_278) : !cute.coord<"?">
      %498 = arith.cmpi slt, %497, %470 : i32
      cf.cond_br %498, ^bb19, ^bb23
    ^bb19:  // pred: ^bb18
      %idx_279 = cute.crd2idx(%153, %lay_93) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_280 = cute.add_offset(%ptr_90, %idx_279) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_281 = cute.add_offset(%ptr_96, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_282 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %499 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb20(%c0_i32 : i32)
    ^bb20(%500: i32):  // 2 preds: ^bb19, ^bb21
      %501 = arith.cmpi slt, %500, %499 : i32
      cf.cond_br %501, ^bb21, ^bb22 {llvm.loop_annotation = #loop_annotation}
    ^bb21:  // pred: ^bb20
      %coord_283 = cute.make_coord(%500) : (i32) -> !cute.coord<"(_,?)">
      %idx_284 = cute.crd2idx(%coord_283, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_285 = cute.add_offset(%ptr_280, %idx_284) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_286 = cute.crd2idx(%coord_283, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_287 = cute.add_offset(%ptr_281, %idx_286) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_288 = cute.crd2idx(%coord_283, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_289 = cute.add_offset(%iter_282, %idx_288) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %502 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<i8, rmem> to !llvm.ptr
      %503 = llvm.load %502 : !llvm.ptr -> i8
      %504 = llvm.trunc %503 : i8 to i1
      %iter_290 = cute.recast_iter(%ptr_285) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_291 = cute.recast_iter(%ptr_287) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_291 : !cute.ptr<i128, smem>, %iter_290 : !cute.ptr<i128, gmem>, %504 : i1) {cache_mode = <global>}
      %505 = arith.addi %500, %c1_i32 : i32
      cf.br ^bb20(%505 : i32)
    ^bb22:  // pred: ^bb20
      cf.br ^bb24
    ^bb23:  // pred: ^bb18
      %ptr_292 = cute.add_offset(%ptr_96, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_293 = cute.make_view(%ptr_292) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_293 : !memref_smem_bf16_
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %tup_294 = cute.add_offset(%tup_190, %151) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_295, %e1_296, %e2_297, %e3_298 = cute.get_leaves(%tup_294) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_299 = cute.make_coord(%e1_296) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %506 = cute.get_scalars(%coord_299) : !cute.coord<"?">
      %507 = arith.cmpi slt, %506, %470 : i32
      cf.cond_br %507, ^bb25, ^bb29
    ^bb25:  // pred: ^bb24
      %idx_300 = cute.crd2idx(%150, %lay_93) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_301 = cute.add_offset(%ptr_90, %idx_300) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_302 = cute.add_offset(%ptr_96, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_303 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %508 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb26(%c0_i32 : i32)
    ^bb26(%509: i32):  // 2 preds: ^bb25, ^bb27
      %510 = arith.cmpi slt, %509, %508 : i32
      cf.cond_br %510, ^bb27, ^bb28 {llvm.loop_annotation = #loop_annotation}
    ^bb27:  // pred: ^bb26
      %coord_304 = cute.make_coord(%509) : (i32) -> !cute.coord<"(_,?)">
      %idx_305 = cute.crd2idx(%coord_304, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_306 = cute.add_offset(%ptr_301, %idx_305) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_307 = cute.crd2idx(%coord_304, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_308 = cute.add_offset(%ptr_302, %idx_307) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_309 = cute.crd2idx(%coord_304, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_310 = cute.add_offset(%iter_303, %idx_309) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %511 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<i8, rmem> to !llvm.ptr
      %512 = llvm.load %511 : !llvm.ptr -> i8
      %513 = llvm.trunc %512 : i8 to i1
      %iter_311 = cute.recast_iter(%ptr_306) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_312 = cute.recast_iter(%ptr_308) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_312 : !cute.ptr<i128, smem>, %iter_311 : !cute.ptr<i128, gmem>, %513 : i1) {cache_mode = <global>}
      %514 = arith.addi %509, %c1_i32 : i32
      cf.br ^bb26(%514 : i32)
    ^bb28:  // pred: ^bb26
      cf.br ^bb30
    ^bb29:  // pred: ^bb24
      %ptr_313 = cute.add_offset(%ptr_96, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %view_314 = cute.make_view(%ptr_313) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_314 : !memref_smem_bf16_
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %tup_315 = cute.add_offset(%tup_190, %148) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_316, %e1_317, %e2_318, %e3_319 = cute.get_leaves(%tup_315) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_320 = cute.make_coord(%e1_317) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %515 = cute.get_scalars(%coord_320) : !cute.coord<"?">
      %516 = arith.cmpi slt, %515, %470 : i32
      cf.cond_br %516, ^bb31, ^bb35
    ^bb31:  // pred: ^bb30
      %idx_321 = cute.crd2idx(%147, %lay_93) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
      %ptr_322 = cute.add_offset(%ptr_90, %idx_321) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_323 = cute.add_offset(%ptr_96, %146) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_324 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %517 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%518: i32):  // 2 preds: ^bb31, ^bb33
      %519 = arith.cmpi slt, %518, %517 : i32
      cf.cond_br %519, ^bb33, ^bb34 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_325 = cute.make_coord(%518) : (i32) -> !cute.coord<"(_,?)">
      %idx_326 = cute.crd2idx(%coord_325, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_327 = cute.add_offset(%ptr_322, %idx_326) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_328 = cute.crd2idx(%coord_325, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_329 = cute.add_offset(%ptr_323, %idx_328) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_330 = cute.crd2idx(%coord_325, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_331 = cute.add_offset(%iter_324, %idx_330) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %520 = builtin.unrealized_conversion_cast %ptr_331 : !cute.ptr<i8, rmem> to !llvm.ptr
      %521 = llvm.load %520 : !llvm.ptr -> i8
      %522 = llvm.trunc %521 : i8 to i1
      %iter_332 = cute.recast_iter(%ptr_327) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_333 = cute.recast_iter(%ptr_329) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_333 : !cute.ptr<i128, smem>, %iter_332 : !cute.ptr<i128, gmem>, %522 : i1) {cache_mode = <global>}
      %523 = arith.addi %518, %c1_i32 : i32
      cf.br ^bb32(%523 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb36
    ^bb35:  // pred: ^bb30
      %ptr_334 = cute.add_offset(%ptr_96, %146) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"5120">) -> !cute.ptr<bf16, smem, align<16>>
      %view_335 = cute.make_view(%ptr_334) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_335 : !memref_smem_bf16_
      cf.br ^bb36
    ^bb36:  // 2 preds: ^bb34, ^bb35
      %tup_336 = cute.add_offset(%tup_190, %145) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_337, %e1_338, %e2_339, %e3_340 = cute.get_leaves(%tup_336) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_341 = cute.make_coord(%e1_338) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %524 = cute.get_scalars(%coord_341) : !cute.coord<"?">
      %525 = arith.cmpi slt, %524, %470 : i32
      cf.cond_br %525, ^bb37, ^bb41
    ^bb37:  // pred: ^bb36
      %idx_342 = cute.crd2idx(%144, %lay_93) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
      %ptr_343 = cute.add_offset(%ptr_90, %idx_342) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_344 = cute.add_offset(%ptr_96, %143) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_345 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %526 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%527: i32):  // 2 preds: ^bb37, ^bb39
      %528 = arith.cmpi slt, %527, %526 : i32
      cf.cond_br %528, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_346 = cute.make_coord(%527) : (i32) -> !cute.coord<"(_,?)">
      %idx_347 = cute.crd2idx(%coord_346, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_348 = cute.add_offset(%ptr_343, %idx_347) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_349 = cute.crd2idx(%coord_346, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_350 = cute.add_offset(%ptr_344, %idx_349) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_351 = cute.crd2idx(%coord_346, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_352 = cute.add_offset(%iter_345, %idx_351) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %529 = builtin.unrealized_conversion_cast %ptr_352 : !cute.ptr<i8, rmem> to !llvm.ptr
      %530 = llvm.load %529 : !llvm.ptr -> i8
      %531 = llvm.trunc %530 : i8 to i1
      %iter_353 = cute.recast_iter(%ptr_348) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_354 = cute.recast_iter(%ptr_350) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_354 : !cute.ptr<i128, smem>, %iter_353 : !cute.ptr<i128, gmem>, %531 : i1) {cache_mode = <global>}
      %532 = arith.addi %527, %c1_i32 : i32
      cf.br ^bb38(%532 : i32)
    ^bb40:  // pred: ^bb38
      cf.br ^bb42
    ^bb41:  // pred: ^bb36
      %ptr_355 = cute.add_offset(%ptr_96, %143) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"6144">) -> !cute.ptr<bf16, smem, align<16>>
      %view_356 = cute.make_view(%ptr_355) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_356 : !memref_smem_bf16_
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      %tup_357 = cute.add_offset(%tup_190, %142) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_358, %e1_359, %e2_360, %e3_361 = cute.get_leaves(%tup_357) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_362 = cute.make_coord(%e1_359) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %533 = cute.get_scalars(%coord_362) : !cute.coord<"?">
      %534 = arith.cmpi slt, %533, %470 : i32
      cf.cond_br %534, ^bb43, ^bb47
    ^bb43:  // pred: ^bb42
      %idx_363 = cute.crd2idx(%141, %lay_93) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
      %ptr_364 = cute.add_offset(%ptr_90, %idx_363) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_365 = cute.add_offset(%ptr_96, %140) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_366 = cute.get_iter(%rmem_192) : !memref_rmem_i8_
      %535 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%536: i32):  // 2 preds: ^bb43, ^bb45
      %537 = arith.cmpi slt, %536, %535 : i32
      cf.cond_br %537, ^bb45, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %coord_367 = cute.make_coord(%536) : (i32) -> !cute.coord<"(_,?)">
      %idx_368 = cute.crd2idx(%coord_367, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_369 = cute.add_offset(%ptr_364, %idx_368) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_370 = cute.crd2idx(%coord_367, %163) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8192)))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_371 = cute.add_offset(%ptr_365, %idx_370) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_372 = cute.crd2idx(%coord_367, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_373 = cute.add_offset(%iter_366, %idx_372) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %538 = builtin.unrealized_conversion_cast %ptr_373 : !cute.ptr<i8, rmem> to !llvm.ptr
      %539 = llvm.load %538 : !llvm.ptr -> i8
      %540 = llvm.trunc %539 : i8 to i1
      %iter_374 = cute.recast_iter(%ptr_369) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_375 = cute.recast_iter(%ptr_371) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_375 : !cute.ptr<i128, smem>, %iter_374 : !cute.ptr<i128, gmem>, %540 : i1) {cache_mode = <global>}
      %541 = arith.addi %536, %c1_i32 : i32
      cf.br ^bb44(%541 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb48
    ^bb47:  // pred: ^bb42
      %ptr_376 = cute.add_offset(%ptr_96, %140) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"7168">) -> !cute.ptr<bf16, smem, align<16>>
      %view_377 = cute.make_view(%ptr_376) : !memref_smem_bf16_
      cute.memref.store_vec %cst_2, %view_377 : !memref_smem_bf16_
      cf.br ^bb48
    ^bb48:  // 2 preds: ^bb46, ^bb47
      %coord_378 = cute.make_coord(%e1_208) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_379 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %542 = cute.get_scalars(%coord_378) : !cute.coord<"?">
      %543 = cute.get_scalars(%coord_379) : !cute.coord<"?">
      %544 = arith.cmpi slt, %542, %543 : i32
      cf.cond_br %544, ^bb49, ^bb53
    ^bb49:  // pred: ^bb48
      %coord_380 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,0,_,?)">
      %idx_381 = cute.crd2idx(%coord_380, %lay_104) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_382 = cute.add_offset(%ptr_99, %idx_381) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %545 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb50(%c0_i32 : i32)
    ^bb50(%546: i32):  // 2 preds: ^bb49, ^bb51
      %547 = arith.cmpi slt, %546, %545 : i32
      cf.cond_br %547, ^bb51, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb51:  // pred: ^bb50
      %coord_383 = cute.make_coord(%546) : (i32) -> !cute.coord<"(_,?)">
      %idx_384 = cute.crd2idx(%coord_383, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_385 = cute.add_offset(%ptr_382, %idx_384) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_386 = cute.crd2idx(%coord_383, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_387 = cute.add_offset(%ptr_105, %idx_386) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_388 = cute.crd2idx(%coord_383, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_389 = cute.add_offset(%iter_194, %idx_388) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %548 = builtin.unrealized_conversion_cast %ptr_389 : !cute.ptr<i8, rmem> to !llvm.ptr
      %549 = llvm.load %548 : !llvm.ptr -> i8
      %550 = llvm.trunc %549 : i8 to i1
      %iter_390 = cute.recast_iter(%ptr_385) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_391 = cute.recast_iter(%ptr_387) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_391 : !cute.ptr<i128, smem>, %iter_390 : !cute.ptr<i128, gmem>, %550 : i1) {cache_mode = <global>}
      %551 = arith.addi %546, %c1_i32 : i32
      cf.br ^bb50(%551 : i32)
    ^bb52:  // pred: ^bb50
      cf.br ^bb54
    ^bb53:  // pred: ^bb48
      %view_392 = cute.make_view(%ptr_105) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_392 : !memref_smem_bf16_1
      cf.br ^bb54
    ^bb54:  // 2 preds: ^bb52, ^bb53
      %tup_393 = cute.add_offset(%tup_191, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_394, %e1_395, %e2_396, %e3_397 = cute.get_leaves(%tup_393) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_398 = cute.make_coord(%e1_395) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %552 = cute.get_scalars(%coord_398) : !cute.coord<"?">
      %553 = arith.cmpi slt, %552, %543 : i32
      cf.cond_br %553, ^bb55, ^bb59
    ^bb55:  // pred: ^bb54
      %coord_399 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,1,_,?)">
      %idx_400 = cute.crd2idx(%coord_399, %lay_104) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_401 = cute.add_offset(%ptr_99, %idx_400) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_402 = cute.add_offset(%ptr_105, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %554 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%555: i32):  // 2 preds: ^bb55, ^bb57
      %556 = arith.cmpi slt, %555, %554 : i32
      cf.cond_br %556, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      %coord_403 = cute.make_coord(%555) : (i32) -> !cute.coord<"(_,?)">
      %idx_404 = cute.crd2idx(%coord_403, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_405 = cute.add_offset(%ptr_401, %idx_404) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_406 = cute.crd2idx(%coord_403, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_407 = cute.add_offset(%ptr_402, %idx_406) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_408 = cute.crd2idx(%coord_403, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_409 = cute.add_offset(%iter_194, %idx_408) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %557 = builtin.unrealized_conversion_cast %ptr_409 : !cute.ptr<i8, rmem> to !llvm.ptr
      %558 = llvm.load %557 : !llvm.ptr -> i8
      %559 = llvm.trunc %558 : i8 to i1
      %iter_410 = cute.recast_iter(%ptr_405) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_411 = cute.recast_iter(%ptr_407) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_411 : !cute.ptr<i128, smem>, %iter_410 : !cute.ptr<i128, gmem>, %559 : i1) {cache_mode = <global>}
      %560 = arith.addi %555, %c1_i32 : i32
      cf.br ^bb56(%560 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb60
    ^bb59:  // pred: ^bb54
      %ptr_412 = cute.add_offset(%ptr_105, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_413 = cute.make_view(%ptr_412) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_413 : !memref_smem_bf16_1
      cf.br ^bb60
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %tup_414 = cute.add_offset(%tup_191, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_415, %e1_416, %e2_417, %e3_418 = cute.get_leaves(%tup_414) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_419 = cute.make_coord(%e1_416) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %561 = cute.get_scalars(%coord_419) : !cute.coord<"?">
      %562 = arith.cmpi slt, %561, %543 : i32
      cf.cond_br %562, ^bb61, ^bb65
    ^bb61:  // pred: ^bb60
      %coord_420 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,2,_,?)">
      %idx_421 = cute.crd2idx(%coord_420, %lay_104) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_422 = cute.add_offset(%ptr_99, %idx_421) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_423 = cute.add_offset(%ptr_105, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %563 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%564: i32):  // 2 preds: ^bb61, ^bb63
      %565 = arith.cmpi slt, %564, %563 : i32
      cf.cond_br %565, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %coord_424 = cute.make_coord(%564) : (i32) -> !cute.coord<"(_,?)">
      %idx_425 = cute.crd2idx(%coord_424, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_426 = cute.add_offset(%ptr_422, %idx_425) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_427 = cute.crd2idx(%coord_424, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_428 = cute.add_offset(%ptr_423, %idx_427) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_429 = cute.crd2idx(%coord_424, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_430 = cute.add_offset(%iter_194, %idx_429) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %566 = builtin.unrealized_conversion_cast %ptr_430 : !cute.ptr<i8, rmem> to !llvm.ptr
      %567 = llvm.load %566 : !llvm.ptr -> i8
      %568 = llvm.trunc %567 : i8 to i1
      %iter_431 = cute.recast_iter(%ptr_426) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_432 = cute.recast_iter(%ptr_428) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_432 : !cute.ptr<i128, smem>, %iter_431 : !cute.ptr<i128, gmem>, %568 : i1) {cache_mode = <global>}
      %569 = arith.addi %564, %c1_i32 : i32
      cf.br ^bb62(%569 : i32)
    ^bb64:  // pred: ^bb62
      cf.br ^bb66
    ^bb65:  // pred: ^bb60
      %ptr_433 = cute.add_offset(%ptr_105, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_434 = cute.make_view(%ptr_433) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_434 : !memref_smem_bf16_1
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %tup_435 = cute.add_offset(%tup_191, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_436, %e1_437, %e2_438, %e3_439 = cute.get_leaves(%tup_435) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_440 = cute.make_coord(%e1_437) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %570 = cute.get_scalars(%coord_440) : !cute.coord<"?">
      %571 = arith.cmpi slt, %570, %543 : i32
      cf.cond_br %571, ^bb67, ^bb71
    ^bb67:  // pred: ^bb66
      %coord_441 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,3,_,?)">
      %idx_442 = cute.crd2idx(%coord_441, %lay_104) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_443 = cute.add_offset(%ptr_99, %idx_442) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_444 = cute.add_offset(%ptr_105, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %572 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb68(%c0_i32 : i32)
    ^bb68(%573: i32):  // 2 preds: ^bb67, ^bb69
      %574 = arith.cmpi slt, %573, %572 : i32
      cf.cond_br %574, ^bb69, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb69:  // pred: ^bb68
      %coord_445 = cute.make_coord(%573) : (i32) -> !cute.coord<"(_,?)">
      %idx_446 = cute.crd2idx(%coord_445, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_447 = cute.add_offset(%ptr_443, %idx_446) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_448 = cute.crd2idx(%coord_445, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_449 = cute.add_offset(%ptr_444, %idx_448) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_450 = cute.crd2idx(%coord_445, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_451 = cute.add_offset(%iter_194, %idx_450) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %575 = builtin.unrealized_conversion_cast %ptr_451 : !cute.ptr<i8, rmem> to !llvm.ptr
      %576 = llvm.load %575 : !llvm.ptr -> i8
      %577 = llvm.trunc %576 : i8 to i1
      %iter_452 = cute.recast_iter(%ptr_447) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_453 = cute.recast_iter(%ptr_449) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_453 : !cute.ptr<i128, smem>, %iter_452 : !cute.ptr<i128, gmem>, %577 : i1) {cache_mode = <global>}
      %578 = arith.addi %573, %c1_i32 : i32
      cf.br ^bb68(%578 : i32)
    ^bb70:  // pred: ^bb68
      cf.br ^bb72
    ^bb71:  // pred: ^bb66
      %ptr_454 = cute.add_offset(%ptr_105, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_455 = cute.make_view(%ptr_454) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_455 : !memref_smem_bf16_1
      cf.br ^bb72
    ^bb72:  // 2 preds: ^bb70, ^bb71
      nvvm.cp.async.commit.group
      %rmem_456 = cute.memref.alloca() : !memref_rmem_f32_1
      %rmem_457 = cute.memref.alloca() : !memref_rmem_f32_1
      cute.memref.store_vec %cst_1, %rmem_456 : !memref_rmem_f32_1
      cute.memref.store_vec %cst_0, %rmem_457 : !memref_rmem_f32_1
      %rmem_458 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_459 = cute.get_iter(%rmem_458) : !memref_rmem_f32_2
      cute.memref.store_vec %cst, %rmem_458 : !memref_rmem_f32_2
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.cond_br %544, ^bb73, ^bb77
    ^bb73:  // pred: ^bb72
      %coord_460 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,0,_,?)">
      %idx_461 = cute.crd2idx(%coord_460, %lay_113) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_462 = cute.add_offset(%ptr_108, %idx_461) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %579 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb74(%c0_i32 : i32)
    ^bb74(%580: i32):  // 2 preds: ^bb73, ^bb75
      %581 = arith.cmpi slt, %580, %579 : i32
      cf.cond_br %581, ^bb75, ^bb76 {llvm.loop_annotation = #loop_annotation}
    ^bb75:  // pred: ^bb74
      %coord_463 = cute.make_coord(%580) : (i32) -> !cute.coord<"(_,?)">
      %idx_464 = cute.crd2idx(%coord_463, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_465 = cute.add_offset(%ptr_462, %idx_464) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_466 = cute.crd2idx(%coord_463, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_467 = cute.add_offset(%ptr_114, %idx_466) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_468 = cute.crd2idx(%coord_463, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_469 = cute.add_offset(%iter_194, %idx_468) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %582 = builtin.unrealized_conversion_cast %ptr_469 : !cute.ptr<i8, rmem> to !llvm.ptr
      %583 = llvm.load %582 : !llvm.ptr -> i8
      %584 = llvm.trunc %583 : i8 to i1
      %iter_470 = cute.recast_iter(%ptr_465) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_471 = cute.recast_iter(%ptr_467) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_471 : !cute.ptr<i128, smem>, %iter_470 : !cute.ptr<i128, gmem>, %584 : i1) {cache_mode = <global>}
      %585 = arith.addi %580, %c1_i32 : i32
      cf.br ^bb74(%585 : i32)
    ^bb76:  // pred: ^bb74
      cf.br ^bb78
    ^bb77:  // pred: ^bb72
      %view_472 = cute.make_view(%ptr_114) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_472 : !memref_smem_bf16_1
      cf.br ^bb78
    ^bb78:  // 2 preds: ^bb76, ^bb77
      cf.cond_br %553, ^bb79, ^bb83
    ^bb79:  // pred: ^bb78
      %coord_473 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,1,_,?)">
      %idx_474 = cute.crd2idx(%coord_473, %lay_113) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_475 = cute.add_offset(%ptr_108, %idx_474) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_476 = cute.add_offset(%ptr_114, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %586 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%587: i32):  // 2 preds: ^bb79, ^bb81
      %588 = arith.cmpi slt, %587, %586 : i32
      cf.cond_br %588, ^bb81, ^bb82 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      %coord_477 = cute.make_coord(%587) : (i32) -> !cute.coord<"(_,?)">
      %idx_478 = cute.crd2idx(%coord_477, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_479 = cute.add_offset(%ptr_475, %idx_478) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_480 = cute.crd2idx(%coord_477, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_481 = cute.add_offset(%ptr_476, %idx_480) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_482 = cute.crd2idx(%coord_477, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_483 = cute.add_offset(%iter_194, %idx_482) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %589 = builtin.unrealized_conversion_cast %ptr_483 : !cute.ptr<i8, rmem> to !llvm.ptr
      %590 = llvm.load %589 : !llvm.ptr -> i8
      %591 = llvm.trunc %590 : i8 to i1
      %iter_484 = cute.recast_iter(%ptr_479) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_485 = cute.recast_iter(%ptr_481) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_485 : !cute.ptr<i128, smem>, %iter_484 : !cute.ptr<i128, gmem>, %591 : i1) {cache_mode = <global>}
      %592 = arith.addi %587, %c1_i32 : i32
      cf.br ^bb80(%592 : i32)
    ^bb82:  // pred: ^bb80
      cf.br ^bb84
    ^bb83:  // pred: ^bb78
      %ptr_486 = cute.add_offset(%ptr_114, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_487 = cute.make_view(%ptr_486) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_487 : !memref_smem_bf16_1
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      cf.cond_br %562, ^bb85, ^bb89
    ^bb85:  // pred: ^bb84
      %coord_488 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,2,_,?)">
      %idx_489 = cute.crd2idx(%coord_488, %lay_113) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_490 = cute.add_offset(%ptr_108, %idx_489) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_491 = cute.add_offset(%ptr_114, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %593 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb86(%c0_i32 : i32)
    ^bb86(%594: i32):  // 2 preds: ^bb85, ^bb87
      %595 = arith.cmpi slt, %594, %593 : i32
      cf.cond_br %595, ^bb87, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb87:  // pred: ^bb86
      %coord_492 = cute.make_coord(%594) : (i32) -> !cute.coord<"(_,?)">
      %idx_493 = cute.crd2idx(%coord_492, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_494 = cute.add_offset(%ptr_490, %idx_493) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_495 = cute.crd2idx(%coord_492, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_496 = cute.add_offset(%ptr_491, %idx_495) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_497 = cute.crd2idx(%coord_492, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_498 = cute.add_offset(%iter_194, %idx_497) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %596 = builtin.unrealized_conversion_cast %ptr_498 : !cute.ptr<i8, rmem> to !llvm.ptr
      %597 = llvm.load %596 : !llvm.ptr -> i8
      %598 = llvm.trunc %597 : i8 to i1
      %iter_499 = cute.recast_iter(%ptr_494) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_500 = cute.recast_iter(%ptr_496) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_500 : !cute.ptr<i128, smem>, %iter_499 : !cute.ptr<i128, gmem>, %598 : i1) {cache_mode = <global>}
      %599 = arith.addi %594, %c1_i32 : i32
      cf.br ^bb86(%599 : i32)
    ^bb88:  // pred: ^bb86
      cf.br ^bb90
    ^bb89:  // pred: ^bb84
      %ptr_501 = cute.add_offset(%ptr_114, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_502 = cute.make_view(%ptr_501) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_502 : !memref_smem_bf16_1
      cf.br ^bb90
    ^bb90:  // 2 preds: ^bb88, ^bb89
      cf.cond_br %571, ^bb91, ^bb95
    ^bb91:  // pred: ^bb90
      %coord_503 = cute.make_coord(%205) : (i32) -> !cute.coord<"(_,3,_,?)">
      %idx_504 = cute.crd2idx(%coord_503, %lay_113) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_505 = cute.add_offset(%ptr_108, %idx_504) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_506 = cute.add_offset(%ptr_114, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %600 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb92(%c0_i32 : i32)
    ^bb92(%601: i32):  // 2 preds: ^bb91, ^bb93
      %602 = arith.cmpi slt, %601, %600 : i32
      cf.cond_br %602, ^bb93, ^bb94 {llvm.loop_annotation = #loop_annotation}
    ^bb93:  // pred: ^bb92
      %coord_507 = cute.make_coord(%601) : (i32) -> !cute.coord<"(_,?)">
      %idx_508 = cute.crd2idx(%coord_507, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_509 = cute.add_offset(%ptr_505, %idx_508) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_510 = cute.crd2idx(%coord_507, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_511 = cute.add_offset(%ptr_506, %idx_510) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_512 = cute.crd2idx(%coord_507, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_513 = cute.add_offset(%iter_194, %idx_512) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %603 = builtin.unrealized_conversion_cast %ptr_513 : !cute.ptr<i8, rmem> to !llvm.ptr
      %604 = llvm.load %603 : !llvm.ptr -> i8
      %605 = llvm.trunc %604 : i8 to i1
      %iter_514 = cute.recast_iter(%ptr_509) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_515 = cute.recast_iter(%ptr_511) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_515 : !cute.ptr<i128, smem>, %iter_514 : !cute.ptr<i128, gmem>, %605 : i1) {cache_mode = <global>}
      %606 = arith.addi %601, %c1_i32 : i32
      cf.br ^bb92(%606 : i32)
    ^bb94:  // pred: ^bb92
      cf.br ^bb96
    ^bb95:  // pred: ^bb90
      %ptr_516 = cute.add_offset(%ptr_114, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_517 = cute.make_view(%ptr_516) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_2, %view_517 : !memref_smem_bf16_1
      cf.br ^bb96
    ^bb96:  // 2 preds: ^bb94, ^bb95
      nvvm.cp.async.commit.group
      %607 = cute.get_scalars(%161) : !cute.int_tuple<"2">
      cf.br ^bb97(%c0_i32 : i32)
    ^bb97(%608: i32):  // 2 preds: ^bb96, ^bb98
      %609 = arith.cmpi slt, %608, %607 : i32
      cf.cond_br %609, ^bb98, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb98:  // pred: ^bb97
      %coord_518 = cute.make_coord(%608) : (i32) -> !cute.coord<"(_,?)">
      %idx_519 = cute.crd2idx(%coord_518, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_520 = cute.add_offset(%ptr_122, %idx_519) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_521 = cute.crd2idx(%coord_518, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_522 = cute.add_offset(%iter_127, %idx_521) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %610 = cute_nvgpu.arch.copy.ldsm %ptr_520{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %611 = vector.extractelement %610[%130 : i32] : vector<4xi32>
      %612 = builtin.unrealized_conversion_cast %ptr_522 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %611, %612 : i32, !llvm.ptr
      %613 = vector.extractelement %610[%129 : i32] : vector<4xi32>
      %ptr_523 = cute.add_offset(%ptr_522, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %614 = builtin.unrealized_conversion_cast %ptr_523 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %613, %614 : i32, !llvm.ptr
      %615 = vector.extractelement %610[%128 : i32] : vector<4xi32>
      %ptr_524 = cute.add_offset(%ptr_522, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %616 = builtin.unrealized_conversion_cast %ptr_524 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %615, %616 : i32, !llvm.ptr
      %617 = vector.extractelement %610[%126 : i32] : vector<4xi32>
      %ptr_525 = cute.add_offset(%ptr_522, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %618 = builtin.unrealized_conversion_cast %ptr_525 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %617, %618 : i32, !llvm.ptr
      %619 = arith.addi %608, %c1_i32 : i32
      cf.br ^bb97(%619 : i32)
    ^bb99:  // pred: ^bb97
      %620 = cute.get_scalars(%127) : !cute.int_tuple<"4">
      cf.br ^bb100(%c0_i32 : i32)
    ^bb100(%621: i32):  // 2 preds: ^bb99, ^bb101
      %622 = arith.cmpi slt, %621, %620 : i32
      cf.cond_br %622, ^bb101, ^bb102 {llvm.loop_annotation = #loop_annotation}
    ^bb101:  // pred: ^bb100
      %coord_526 = cute.make_coord(%621) : (i32) -> !cute.coord<"(_,?)">
      %idx_527 = cute.crd2idx(%coord_526, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_528 = cute.add_offset(%ptr_130, %idx_527) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_529 = cute.crd2idx(%coord_526, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_530 = cute.add_offset(%iter_135, %idx_529) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %623 = cute_nvgpu.arch.copy.ldsm %ptr_528{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %624 = vector.extractelement %623[%130 : i32] : vector<4xi32>
      %625 = builtin.unrealized_conversion_cast %ptr_530 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %624, %625 : i32, !llvm.ptr
      %626 = vector.extractelement %623[%129 : i32] : vector<4xi32>
      %ptr_531 = cute.add_offset(%ptr_530, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %627 = builtin.unrealized_conversion_cast %ptr_531 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %626, %627 : i32, !llvm.ptr
      %628 = vector.extractelement %623[%128 : i32] : vector<4xi32>
      %ptr_532 = cute.add_offset(%ptr_530, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %629 = builtin.unrealized_conversion_cast %ptr_532 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %628, %629 : i32, !llvm.ptr
      %630 = vector.extractelement %623[%126 : i32] : vector<4xi32>
      %ptr_533 = cute.add_offset(%ptr_530, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %631 = builtin.unrealized_conversion_cast %ptr_533 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %630, %631 : i32, !llvm.ptr
      %632 = arith.addi %621, %c1_i32 : i32
      cf.br ^bb100(%632 : i32)
    ^bb102:  // pred: ^bb100
      %idx_534 = cute.crd2idx(%122, %lay_126) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_535 = cute.add_offset(%ptr_122, %idx_534) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_536 = cute.add_offset(%iter_127, %121) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%633: i32):  // 2 preds: ^bb102, ^bb104
      %634 = arith.cmpi slt, %633, %607 : i32
      cf.cond_br %634, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation}
    ^bb104:  // pred: ^bb103
      %coord_537 = cute.make_coord(%633) : (i32) -> !cute.coord<"(_,?)">
      %idx_538 = cute.crd2idx(%coord_537, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_539 = cute.add_offset(%ptr_535, %idx_538) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_540 = cute.crd2idx(%coord_537, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_541 = cute.add_offset(%ptr_536, %idx_540) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %635 = cute_nvgpu.arch.copy.ldsm %ptr_539{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %636 = vector.extractelement %635[%130 : i32] : vector<4xi32>
      %637 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %636, %637 : i32, !llvm.ptr
      %638 = vector.extractelement %635[%129 : i32] : vector<4xi32>
      %ptr_542 = cute.add_offset(%ptr_541, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %639 = builtin.unrealized_conversion_cast %ptr_542 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %638, %639 : i32, !llvm.ptr
      %640 = vector.extractelement %635[%128 : i32] : vector<4xi32>
      %ptr_543 = cute.add_offset(%ptr_541, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %641 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %640, %641 : i32, !llvm.ptr
      %642 = vector.extractelement %635[%126 : i32] : vector<4xi32>
      %ptr_544 = cute.add_offset(%ptr_541, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %643 = builtin.unrealized_conversion_cast %ptr_544 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %642, %643 : i32, !llvm.ptr
      %644 = arith.addi %633, %c1_i32 : i32
      cf.br ^bb103(%644 : i32)
    ^bb105:  // pred: ^bb103
      %idx_545 = cute.crd2idx(%122, %lay_134) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_546 = cute.add_offset(%ptr_130, %idx_545) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_547 = cute.add_offset(%iter_135, %120) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb106(%c0_i32 : i32)
    ^bb106(%645: i32):  // 2 preds: ^bb105, ^bb107
      %646 = arith.cmpi slt, %645, %620 : i32
      cf.cond_br %646, ^bb107, ^bb108 {llvm.loop_annotation = #loop_annotation}
    ^bb107:  // pred: ^bb106
      %coord_548 = cute.make_coord(%645) : (i32) -> !cute.coord<"(_,?)">
      %idx_549 = cute.crd2idx(%coord_548, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_550 = cute.add_offset(%ptr_546, %idx_549) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_551 = cute.crd2idx(%coord_548, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_552 = cute.add_offset(%ptr_547, %idx_551) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %647 = cute_nvgpu.arch.copy.ldsm %ptr_550{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %648 = vector.extractelement %647[%130 : i32] : vector<4xi32>
      %649 = builtin.unrealized_conversion_cast %ptr_552 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %648, %649 : i32, !llvm.ptr
      %650 = vector.extractelement %647[%129 : i32] : vector<4xi32>
      %ptr_553 = cute.add_offset(%ptr_552, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %651 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %650, %651 : i32, !llvm.ptr
      %652 = vector.extractelement %647[%128 : i32] : vector<4xi32>
      %ptr_554 = cute.add_offset(%ptr_552, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %653 = builtin.unrealized_conversion_cast %ptr_554 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %652, %653 : i32, !llvm.ptr
      %654 = vector.extractelement %647[%126 : i32] : vector<4xi32>
      %ptr_555 = cute.add_offset(%ptr_552, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %655 = builtin.unrealized_conversion_cast %ptr_555 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %654, %655 : i32, !llvm.ptr
      %656 = arith.addi %645, %c1_i32 : i32
      cf.br ^bb106(%656 : i32)
    ^bb108:  // pred: ^bb106
      %657 = cute.get_scalars(%117) : !cute.int_tuple<"1">
      %658 = cute.get_scalars(%132) : !cute.int_tuple<"8">
      cf.br ^bb109(%c0_i32 : i32)
    ^bb109(%659: i32):  // 2 preds: ^bb108, ^bb116
      %660 = arith.cmpi slt, %659, %657 : i32
      cf.cond_br %660, ^bb110, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb110:  // pred: ^bb109
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%661: i32):  // 2 preds: ^bb110, ^bb115
      %662 = arith.cmpi slt, %661, %607 : i32
      cf.cond_br %662, ^bb112, ^bb116 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_556 = cute.make_coord(%661, %659) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_557 = cute.crd2idx(%coord_556, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_558 = cute.add_offset(%iter_127, %idx_557) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %663 = builtin.unrealized_conversion_cast %ptr_558 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %664 = llvm.getelementptr %663[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %665 = llvm.getelementptr %663[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %666 = llvm.getelementptr %663[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%667: i32):  // 2 preds: ^bb112, ^bb114
      %668 = arith.cmpi slt, %667, %658 : i32
      cf.cond_br %668, ^bb114, ^bb115 {llvm.loop_annotation = #loop_annotation}
    ^bb114:  // pred: ^bb113
      %coord_559 = cute.make_coord(%667, %659) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_560 = cute.make_coord(%661, %667) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_561 = cute.crd2idx(%coord_559, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_562 = cute.add_offset(%iter_135, %idx_561) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_563 = cute.crd2idx(%coord_560, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_564 = cute.add_offset(%iter_459, %idx_563) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %669 = llvm.load %663 : !llvm.ptr -> i32
      %670 = llvm.load %664 : !llvm.ptr -> i32
      %671 = llvm.load %665 : !llvm.ptr -> i32
      %672 = llvm.load %666 : !llvm.ptr -> i32
      %673 = builtin.unrealized_conversion_cast %ptr_562 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %674 = llvm.load %673 : !llvm.ptr -> i32
      %675 = llvm.getelementptr %673[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %676 = llvm.load %675 : !llvm.ptr -> i32
      %677 = builtin.unrealized_conversion_cast %ptr_564 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %678 = llvm.load %677 : !llvm.ptr -> f32
      %679 = llvm.getelementptr %677[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %680 = llvm.load %679 : !llvm.ptr -> f32
      %681 = llvm.getelementptr %677[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %682 = llvm.load %681 : !llvm.ptr -> f32
      %683 = llvm.getelementptr %677[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %684 = llvm.load %683 : !llvm.ptr -> f32
      %685:4 = cute_nvgpu.arch.mma.SM80 A[%669, %670, %671, %672]  B[%674, %676]  C[%678, %680, %682, %684] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %685#0, %677 : f32, !llvm.ptr
      llvm.store %685#1, %679 : f32, !llvm.ptr
      llvm.store %685#2, %681 : f32, !llvm.ptr
      llvm.store %685#3, %683 : f32, !llvm.ptr
      %686 = arith.addi %667, %c1_i32 : i32
      cf.br ^bb113(%686 : i32)
    ^bb115:  // pred: ^bb113
      %687 = arith.addi %661, %c1_i32 : i32
      cf.br ^bb111(%687 : i32)
    ^bb116:  // pred: ^bb111
      %688 = arith.addi %659, %c1_i32 : i32
      cf.br ^bb109(%688 : i32)
    ^bb117:  // pred: ^bb109
      %idx_565 = cute.crd2idx(%116, %lay_126) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_566 = cute.add_offset(%ptr_122, %idx_565) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_567 = cute.add_offset(%iter_127, %120) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%689: i32):  // 2 preds: ^bb117, ^bb119
      %690 = arith.cmpi slt, %689, %607 : i32
      cf.cond_br %690, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_568 = cute.make_coord(%689) : (i32) -> !cute.coord<"(_,?)">
      %idx_569 = cute.crd2idx(%coord_568, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_570 = cute.add_offset(%ptr_566, %idx_569) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_571 = cute.crd2idx(%coord_568, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_572 = cute.add_offset(%ptr_567, %idx_571) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %691 = cute_nvgpu.arch.copy.ldsm %ptr_570{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %692 = vector.extractelement %691[%130 : i32] : vector<4xi32>
      %693 = builtin.unrealized_conversion_cast %ptr_572 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %692, %693 : i32, !llvm.ptr
      %694 = vector.extractelement %691[%129 : i32] : vector<4xi32>
      %ptr_573 = cute.add_offset(%ptr_572, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %695 = builtin.unrealized_conversion_cast %ptr_573 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %694, %695 : i32, !llvm.ptr
      %696 = vector.extractelement %691[%128 : i32] : vector<4xi32>
      %ptr_574 = cute.add_offset(%ptr_572, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %697 = builtin.unrealized_conversion_cast %ptr_574 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %696, %697 : i32, !llvm.ptr
      %698 = vector.extractelement %691[%126 : i32] : vector<4xi32>
      %ptr_575 = cute.add_offset(%ptr_572, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %699 = builtin.unrealized_conversion_cast %ptr_575 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %698, %699 : i32, !llvm.ptr
      %700 = arith.addi %689, %c1_i32 : i32
      cf.br ^bb118(%700 : i32)
    ^bb120:  // pred: ^bb118
      %idx_576 = cute.crd2idx(%116, %lay_134) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_577 = cute.add_offset(%ptr_130, %idx_576) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_578 = cute.add_offset(%iter_135, %115) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb121(%c0_i32 : i32)
    ^bb121(%701: i32):  // 2 preds: ^bb120, ^bb122
      %702 = arith.cmpi slt, %701, %620 : i32
      cf.cond_br %702, ^bb122, ^bb123 {llvm.loop_annotation = #loop_annotation}
    ^bb122:  // pred: ^bb121
      %coord_579 = cute.make_coord(%701) : (i32) -> !cute.coord<"(_,?)">
      %idx_580 = cute.crd2idx(%coord_579, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_581 = cute.add_offset(%ptr_577, %idx_580) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_582 = cute.crd2idx(%coord_579, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_583 = cute.add_offset(%ptr_578, %idx_582) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %703 = cute_nvgpu.arch.copy.ldsm %ptr_581{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %704 = vector.extractelement %703[%130 : i32] : vector<4xi32>
      %705 = builtin.unrealized_conversion_cast %ptr_583 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %704, %705 : i32, !llvm.ptr
      %706 = vector.extractelement %703[%129 : i32] : vector<4xi32>
      %ptr_584 = cute.add_offset(%ptr_583, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %707 = builtin.unrealized_conversion_cast %ptr_584 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %706, %707 : i32, !llvm.ptr
      %708 = vector.extractelement %703[%128 : i32] : vector<4xi32>
      %ptr_585 = cute.add_offset(%ptr_583, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %709 = builtin.unrealized_conversion_cast %ptr_585 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %708, %709 : i32, !llvm.ptr
      %710 = vector.extractelement %703[%126 : i32] : vector<4xi32>
      %ptr_586 = cute.add_offset(%ptr_583, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %711 = builtin.unrealized_conversion_cast %ptr_586 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %710, %711 : i32, !llvm.ptr
      %712 = arith.addi %701, %c1_i32 : i32
      cf.br ^bb121(%712 : i32)
    ^bb123:  // pred: ^bb121
      cf.br ^bb124(%c0_i32 : i32)
    ^bb124(%713: i32):  // 2 preds: ^bb123, ^bb131
      %714 = arith.cmpi slt, %713, %657 : i32
      cf.cond_br %714, ^bb125, ^bb132 {llvm.loop_annotation = #loop_annotation}
    ^bb125:  // pred: ^bb124
      cf.br ^bb126(%c0_i32 : i32)
    ^bb126(%715: i32):  // 2 preds: ^bb125, ^bb130
      %716 = arith.cmpi slt, %715, %607 : i32
      cf.cond_br %716, ^bb127, ^bb131 {llvm.loop_annotation = #loop_annotation}
    ^bb127:  // pred: ^bb126
      %coord_587 = cute.make_coord(%715, %713) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_588 = cute.crd2idx(%coord_587, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_589 = cute.add_offset(%ptr_536, %idx_588) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %717 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %718 = llvm.getelementptr %717[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %719 = llvm.getelementptr %717[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %720 = llvm.getelementptr %717[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb128(%c0_i32 : i32)
    ^bb128(%721: i32):  // 2 preds: ^bb127, ^bb129
      %722 = arith.cmpi slt, %721, %658 : i32
      cf.cond_br %722, ^bb129, ^bb130 {llvm.loop_annotation = #loop_annotation}
    ^bb129:  // pred: ^bb128
      %coord_590 = cute.make_coord(%721, %713) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_591 = cute.make_coord(%715, %721) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_592 = cute.crd2idx(%coord_590, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_593 = cute.add_offset(%ptr_547, %idx_592) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_594 = cute.crd2idx(%coord_591, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_595 = cute.add_offset(%iter_459, %idx_594) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %723 = llvm.load %717 : !llvm.ptr -> i32
      %724 = llvm.load %718 : !llvm.ptr -> i32
      %725 = llvm.load %719 : !llvm.ptr -> i32
      %726 = llvm.load %720 : !llvm.ptr -> i32
      %727 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %728 = llvm.load %727 : !llvm.ptr -> i32
      %729 = llvm.getelementptr %727[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %730 = llvm.load %729 : !llvm.ptr -> i32
      %731 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %732 = llvm.load %731 : !llvm.ptr -> f32
      %733 = llvm.getelementptr %731[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %734 = llvm.load %733 : !llvm.ptr -> f32
      %735 = llvm.getelementptr %731[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %736 = llvm.load %735 : !llvm.ptr -> f32
      %737 = llvm.getelementptr %731[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %738 = llvm.load %737 : !llvm.ptr -> f32
      %739:4 = cute_nvgpu.arch.mma.SM80 A[%723, %724, %725, %726]  B[%728, %730]  C[%732, %734, %736, %738] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %739#0, %731 : f32, !llvm.ptr
      llvm.store %739#1, %733 : f32, !llvm.ptr
      llvm.store %739#2, %735 : f32, !llvm.ptr
      llvm.store %739#3, %737 : f32, !llvm.ptr
      %740 = arith.addi %721, %c1_i32 : i32
      cf.br ^bb128(%740 : i32)
    ^bb130:  // pred: ^bb128
      %741 = arith.addi %715, %c1_i32 : i32
      cf.br ^bb126(%741 : i32)
    ^bb131:  // pred: ^bb126
      %742 = arith.addi %713, %c1_i32 : i32
      cf.br ^bb124(%742 : i32)
    ^bb132:  // pred: ^bb124
      %idx_596 = cute.crd2idx(%114, %lay_126) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_597 = cute.add_offset(%ptr_122, %idx_596) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_598 = cute.add_offset(%iter_127, %113) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%743: i32):  // 2 preds: ^bb132, ^bb134
      %744 = arith.cmpi slt, %743, %607 : i32
      cf.cond_br %744, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      %coord_599 = cute.make_coord(%743) : (i32) -> !cute.coord<"(_,?)">
      %idx_600 = cute.crd2idx(%coord_599, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_601 = cute.add_offset(%ptr_597, %idx_600) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_602 = cute.crd2idx(%coord_599, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_603 = cute.add_offset(%ptr_598, %idx_602) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %745 = cute_nvgpu.arch.copy.ldsm %ptr_601{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %746 = vector.extractelement %745[%130 : i32] : vector<4xi32>
      %747 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %746, %747 : i32, !llvm.ptr
      %748 = vector.extractelement %745[%129 : i32] : vector<4xi32>
      %ptr_604 = cute.add_offset(%ptr_603, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %749 = builtin.unrealized_conversion_cast %ptr_604 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %748, %749 : i32, !llvm.ptr
      %750 = vector.extractelement %745[%128 : i32] : vector<4xi32>
      %ptr_605 = cute.add_offset(%ptr_603, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %751 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %750, %751 : i32, !llvm.ptr
      %752 = vector.extractelement %745[%126 : i32] : vector<4xi32>
      %ptr_606 = cute.add_offset(%ptr_603, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %753 = builtin.unrealized_conversion_cast %ptr_606 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %752, %753 : i32, !llvm.ptr
      %754 = arith.addi %743, %c1_i32 : i32
      cf.br ^bb133(%754 : i32)
    ^bb135:  // pred: ^bb133
      %idx_607 = cute.crd2idx(%114, %lay_134) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_608 = cute.add_offset(%ptr_130, %idx_607) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_609 = cute.add_offset(%iter_135, %112) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb136(%c0_i32 : i32)
    ^bb136(%755: i32):  // 2 preds: ^bb135, ^bb137
      %756 = arith.cmpi slt, %755, %620 : i32
      cf.cond_br %756, ^bb137, ^bb138 {llvm.loop_annotation = #loop_annotation}
    ^bb137:  // pred: ^bb136
      %coord_610 = cute.make_coord(%755) : (i32) -> !cute.coord<"(_,?)">
      %idx_611 = cute.crd2idx(%coord_610, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_612 = cute.add_offset(%ptr_608, %idx_611) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_613 = cute.crd2idx(%coord_610, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_614 = cute.add_offset(%ptr_609, %idx_613) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %757 = cute_nvgpu.arch.copy.ldsm %ptr_612{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %758 = vector.extractelement %757[%130 : i32] : vector<4xi32>
      %759 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %758, %759 : i32, !llvm.ptr
      %760 = vector.extractelement %757[%129 : i32] : vector<4xi32>
      %ptr_615 = cute.add_offset(%ptr_614, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %761 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %760, %761 : i32, !llvm.ptr
      %762 = vector.extractelement %757[%128 : i32] : vector<4xi32>
      %ptr_616 = cute.add_offset(%ptr_614, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %763 = builtin.unrealized_conversion_cast %ptr_616 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %762, %763 : i32, !llvm.ptr
      %764 = vector.extractelement %757[%126 : i32] : vector<4xi32>
      %ptr_617 = cute.add_offset(%ptr_614, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %765 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %764, %765 : i32, !llvm.ptr
      %766 = arith.addi %755, %c1_i32 : i32
      cf.br ^bb136(%766 : i32)
    ^bb138:  // pred: ^bb136
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%767: i32):  // 2 preds: ^bb138, ^bb146
      %768 = arith.cmpi slt, %767, %657 : i32
      cf.cond_br %768, ^bb140, ^bb147 {llvm.loop_annotation = #loop_annotation}
    ^bb140:  // pred: ^bb139
      cf.br ^bb141(%c0_i32 : i32)
    ^bb141(%769: i32):  // 2 preds: ^bb140, ^bb145
      %770 = arith.cmpi slt, %769, %607 : i32
      cf.cond_br %770, ^bb142, ^bb146 {llvm.loop_annotation = #loop_annotation}
    ^bb142:  // pred: ^bb141
      %coord_618 = cute.make_coord(%769, %767) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_619 = cute.crd2idx(%coord_618, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_620 = cute.add_offset(%ptr_567, %idx_619) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %771 = builtin.unrealized_conversion_cast %ptr_620 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %772 = llvm.getelementptr %771[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %773 = llvm.getelementptr %771[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %774 = llvm.getelementptr %771[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb143(%c0_i32 : i32)
    ^bb143(%775: i32):  // 2 preds: ^bb142, ^bb144
      %776 = arith.cmpi slt, %775, %658 : i32
      cf.cond_br %776, ^bb144, ^bb145 {llvm.loop_annotation = #loop_annotation}
    ^bb144:  // pred: ^bb143
      %coord_621 = cute.make_coord(%775, %767) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_622 = cute.make_coord(%769, %775) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_623 = cute.crd2idx(%coord_621, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_624 = cute.add_offset(%ptr_578, %idx_623) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_625 = cute.crd2idx(%coord_622, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_626 = cute.add_offset(%iter_459, %idx_625) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %777 = llvm.load %771 : !llvm.ptr -> i32
      %778 = llvm.load %772 : !llvm.ptr -> i32
      %779 = llvm.load %773 : !llvm.ptr -> i32
      %780 = llvm.load %774 : !llvm.ptr -> i32
      %781 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %782 = llvm.load %781 : !llvm.ptr -> i32
      %783 = llvm.getelementptr %781[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %784 = llvm.load %783 : !llvm.ptr -> i32
      %785 = builtin.unrealized_conversion_cast %ptr_626 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %786 = llvm.load %785 : !llvm.ptr -> f32
      %787 = llvm.getelementptr %785[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %788 = llvm.load %787 : !llvm.ptr -> f32
      %789 = llvm.getelementptr %785[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %790 = llvm.load %789 : !llvm.ptr -> f32
      %791 = llvm.getelementptr %785[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %792 = llvm.load %791 : !llvm.ptr -> f32
      %793:4 = cute_nvgpu.arch.mma.SM80 A[%777, %778, %779, %780]  B[%782, %784]  C[%786, %788, %790, %792] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %793#0, %785 : f32, !llvm.ptr
      llvm.store %793#1, %787 : f32, !llvm.ptr
      llvm.store %793#2, %789 : f32, !llvm.ptr
      llvm.store %793#3, %791 : f32, !llvm.ptr
      %794 = arith.addi %775, %c1_i32 : i32
      cf.br ^bb143(%794 : i32)
    ^bb145:  // pred: ^bb143
      %795 = arith.addi %769, %c1_i32 : i32
      cf.br ^bb141(%795 : i32)
    ^bb146:  // pred: ^bb141
      %796 = arith.addi %767, %c1_i32 : i32
      cf.br ^bb139(%796 : i32)
    ^bb147:  // pred: ^bb139
      %ptr_627 = cute.add_offset(%ptr_122, %111) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"8192">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_628 = cute.add_offset(%iter_127, %110) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%797: i32):  // 2 preds: ^bb147, ^bb149
      %798 = arith.cmpi slt, %797, %607 : i32
      cf.cond_br %798, ^bb149, ^bb150 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      %coord_629 = cute.make_coord(%797) : (i32) -> !cute.coord<"(_,?)">
      %idx_630 = cute.crd2idx(%coord_629, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_631 = cute.add_offset(%ptr_627, %idx_630) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_632 = cute.crd2idx(%coord_629, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_633 = cute.add_offset(%ptr_628, %idx_632) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %799 = cute_nvgpu.arch.copy.ldsm %ptr_631{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %800 = vector.extractelement %799[%130 : i32] : vector<4xi32>
      %801 = builtin.unrealized_conversion_cast %ptr_633 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %800, %801 : i32, !llvm.ptr
      %802 = vector.extractelement %799[%129 : i32] : vector<4xi32>
      %ptr_634 = cute.add_offset(%ptr_633, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %803 = builtin.unrealized_conversion_cast %ptr_634 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %802, %803 : i32, !llvm.ptr
      %804 = vector.extractelement %799[%128 : i32] : vector<4xi32>
      %ptr_635 = cute.add_offset(%ptr_633, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %805 = builtin.unrealized_conversion_cast %ptr_635 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %804, %805 : i32, !llvm.ptr
      %806 = vector.extractelement %799[%126 : i32] : vector<4xi32>
      %ptr_636 = cute.add_offset(%ptr_633, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %807 = builtin.unrealized_conversion_cast %ptr_636 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %806, %807 : i32, !llvm.ptr
      %808 = arith.addi %797, %c1_i32 : i32
      cf.br ^bb148(%808 : i32)
    ^bb150:  // pred: ^bb148
      %ptr_637 = cute.add_offset(%ptr_130, %149) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_638 = cute.add_offset(%iter_135, %121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb151(%c0_i32 : i32)
    ^bb151(%809: i32):  // 2 preds: ^bb150, ^bb152
      %810 = arith.cmpi slt, %809, %620 : i32
      cf.cond_br %810, ^bb152, ^bb153 {llvm.loop_annotation = #loop_annotation}
    ^bb152:  // pred: ^bb151
      %coord_639 = cute.make_coord(%809) : (i32) -> !cute.coord<"(_,?)">
      %idx_640 = cute.crd2idx(%coord_639, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_641 = cute.add_offset(%ptr_637, %idx_640) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_642 = cute.crd2idx(%coord_639, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_643 = cute.add_offset(%ptr_638, %idx_642) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %811 = cute_nvgpu.arch.copy.ldsm %ptr_641{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %812 = vector.extractelement %811[%130 : i32] : vector<4xi32>
      %813 = builtin.unrealized_conversion_cast %ptr_643 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %812, %813 : i32, !llvm.ptr
      %814 = vector.extractelement %811[%129 : i32] : vector<4xi32>
      %ptr_644 = cute.add_offset(%ptr_643, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %815 = builtin.unrealized_conversion_cast %ptr_644 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %814, %815 : i32, !llvm.ptr
      %816 = vector.extractelement %811[%128 : i32] : vector<4xi32>
      %ptr_645 = cute.add_offset(%ptr_643, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %817 = builtin.unrealized_conversion_cast %ptr_645 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %816, %817 : i32, !llvm.ptr
      %818 = vector.extractelement %811[%126 : i32] : vector<4xi32>
      %ptr_646 = cute.add_offset(%ptr_643, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %819 = builtin.unrealized_conversion_cast %ptr_646 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %818, %819 : i32, !llvm.ptr
      %820 = arith.addi %809, %c1_i32 : i32
      cf.br ^bb151(%820 : i32)
    ^bb153:  // pred: ^bb151
      cf.br ^bb154(%c0_i32 : i32)
    ^bb154(%821: i32):  // 2 preds: ^bb153, ^bb161
      %822 = arith.cmpi slt, %821, %657 : i32
      cf.cond_br %822, ^bb155, ^bb162 {llvm.loop_annotation = #loop_annotation}
    ^bb155:  // pred: ^bb154
      cf.br ^bb156(%c0_i32 : i32)
    ^bb156(%823: i32):  // 2 preds: ^bb155, ^bb160
      %824 = arith.cmpi slt, %823, %607 : i32
      cf.cond_br %824, ^bb157, ^bb161 {llvm.loop_annotation = #loop_annotation}
    ^bb157:  // pred: ^bb156
      %coord_647 = cute.make_coord(%823, %821) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_648 = cute.crd2idx(%coord_647, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_649 = cute.add_offset(%ptr_598, %idx_648) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %825 = builtin.unrealized_conversion_cast %ptr_649 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %826 = llvm.getelementptr %825[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %827 = llvm.getelementptr %825[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %828 = llvm.getelementptr %825[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb158(%c0_i32 : i32)
    ^bb158(%829: i32):  // 2 preds: ^bb157, ^bb159
      %830 = arith.cmpi slt, %829, %658 : i32
      cf.cond_br %830, ^bb159, ^bb160 {llvm.loop_annotation = #loop_annotation}
    ^bb159:  // pred: ^bb158
      %coord_650 = cute.make_coord(%829, %821) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_651 = cute.make_coord(%823, %829) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_652 = cute.crd2idx(%coord_650, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_653 = cute.add_offset(%ptr_609, %idx_652) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_654 = cute.crd2idx(%coord_651, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_655 = cute.add_offset(%iter_459, %idx_654) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %831 = llvm.load %825 : !llvm.ptr -> i32
      %832 = llvm.load %826 : !llvm.ptr -> i32
      %833 = llvm.load %827 : !llvm.ptr -> i32
      %834 = llvm.load %828 : !llvm.ptr -> i32
      %835 = builtin.unrealized_conversion_cast %ptr_653 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %836 = llvm.load %835 : !llvm.ptr -> i32
      %837 = llvm.getelementptr %835[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %838 = llvm.load %837 : !llvm.ptr -> i32
      %839 = builtin.unrealized_conversion_cast %ptr_655 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %840 = llvm.load %839 : !llvm.ptr -> f32
      %841 = llvm.getelementptr %839[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %842 = llvm.load %841 : !llvm.ptr -> f32
      %843 = llvm.getelementptr %839[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %844 = llvm.load %843 : !llvm.ptr -> f32
      %845 = llvm.getelementptr %839[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %846 = llvm.load %845 : !llvm.ptr -> f32
      %847:4 = cute_nvgpu.arch.mma.SM80 A[%831, %832, %833, %834]  B[%836, %838]  C[%840, %842, %844, %846] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %847#0, %839 : f32, !llvm.ptr
      llvm.store %847#1, %841 : f32, !llvm.ptr
      llvm.store %847#2, %843 : f32, !llvm.ptr
      llvm.store %847#3, %845 : f32, !llvm.ptr
      %848 = arith.addi %829, %c1_i32 : i32
      cf.br ^bb158(%848 : i32)
    ^bb160:  // pred: ^bb158
      %849 = arith.addi %823, %c1_i32 : i32
      cf.br ^bb156(%849 : i32)
    ^bb161:  // pred: ^bb156
      %850 = arith.addi %821, %c1_i32 : i32
      cf.br ^bb154(%850 : i32)
    ^bb162:  // pred: ^bb154
      %idx_656 = cute.crd2idx(%109, %lay_126) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_657 = cute.add_offset(%ptr_122, %idx_656) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_658 = cute.add_offset(%iter_127, %108) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb163(%c0_i32 : i32)
    ^bb163(%851: i32):  // 2 preds: ^bb162, ^bb164
      %852 = arith.cmpi slt, %851, %607 : i32
      cf.cond_br %852, ^bb164, ^bb165 {llvm.loop_annotation = #loop_annotation}
    ^bb164:  // pred: ^bb163
      %coord_659 = cute.make_coord(%851) : (i32) -> !cute.coord<"(_,?)">
      %idx_660 = cute.crd2idx(%coord_659, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_661 = cute.add_offset(%ptr_657, %idx_660) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_662 = cute.crd2idx(%coord_659, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_663 = cute.add_offset(%ptr_658, %idx_662) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %853 = cute_nvgpu.arch.copy.ldsm %ptr_661{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %854 = vector.extractelement %853[%130 : i32] : vector<4xi32>
      %855 = builtin.unrealized_conversion_cast %ptr_663 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %854, %855 : i32, !llvm.ptr
      %856 = vector.extractelement %853[%129 : i32] : vector<4xi32>
      %ptr_664 = cute.add_offset(%ptr_663, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %857 = builtin.unrealized_conversion_cast %ptr_664 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %856, %857 : i32, !llvm.ptr
      %858 = vector.extractelement %853[%128 : i32] : vector<4xi32>
      %ptr_665 = cute.add_offset(%ptr_663, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %859 = builtin.unrealized_conversion_cast %ptr_665 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %858, %859 : i32, !llvm.ptr
      %860 = vector.extractelement %853[%126 : i32] : vector<4xi32>
      %ptr_666 = cute.add_offset(%ptr_663, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %861 = builtin.unrealized_conversion_cast %ptr_666 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %860, %861 : i32, !llvm.ptr
      %862 = arith.addi %851, %c1_i32 : i32
      cf.br ^bb163(%862 : i32)
    ^bb165:  // pred: ^bb163
      %idx_667 = cute.crd2idx(%109, %lay_134) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_668 = cute.add_offset(%ptr_130, %idx_667) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_669 = cute.add_offset(%iter_135, %113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb166(%c0_i32 : i32)
    ^bb166(%863: i32):  // 2 preds: ^bb165, ^bb167
      %864 = arith.cmpi slt, %863, %620 : i32
      cf.cond_br %864, ^bb167, ^bb168 {llvm.loop_annotation = #loop_annotation}
    ^bb167:  // pred: ^bb166
      %coord_670 = cute.make_coord(%863) : (i32) -> !cute.coord<"(_,?)">
      %idx_671 = cute.crd2idx(%coord_670, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_672 = cute.add_offset(%ptr_668, %idx_671) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_673 = cute.crd2idx(%coord_670, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_674 = cute.add_offset(%ptr_669, %idx_673) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %865 = cute_nvgpu.arch.copy.ldsm %ptr_672{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %866 = vector.extractelement %865[%130 : i32] : vector<4xi32>
      %867 = builtin.unrealized_conversion_cast %ptr_674 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %866, %867 : i32, !llvm.ptr
      %868 = vector.extractelement %865[%129 : i32] : vector<4xi32>
      %ptr_675 = cute.add_offset(%ptr_674, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %869 = builtin.unrealized_conversion_cast %ptr_675 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %868, %869 : i32, !llvm.ptr
      %870 = vector.extractelement %865[%128 : i32] : vector<4xi32>
      %ptr_676 = cute.add_offset(%ptr_674, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %871 = builtin.unrealized_conversion_cast %ptr_676 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %870, %871 : i32, !llvm.ptr
      %872 = vector.extractelement %865[%126 : i32] : vector<4xi32>
      %ptr_677 = cute.add_offset(%ptr_674, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %873 = builtin.unrealized_conversion_cast %ptr_677 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %872, %873 : i32, !llvm.ptr
      %874 = arith.addi %863, %c1_i32 : i32
      cf.br ^bb166(%874 : i32)
    ^bb168:  // pred: ^bb166
      cf.br ^bb169(%c0_i32 : i32)
    ^bb169(%875: i32):  // 2 preds: ^bb168, ^bb176
      %876 = arith.cmpi slt, %875, %657 : i32
      cf.cond_br %876, ^bb170, ^bb177 {llvm.loop_annotation = #loop_annotation}
    ^bb170:  // pred: ^bb169
      cf.br ^bb171(%c0_i32 : i32)
    ^bb171(%877: i32):  // 2 preds: ^bb170, ^bb175
      %878 = arith.cmpi slt, %877, %607 : i32
      cf.cond_br %878, ^bb172, ^bb176 {llvm.loop_annotation = #loop_annotation}
    ^bb172:  // pred: ^bb171
      %coord_678 = cute.make_coord(%877, %875) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_679 = cute.crd2idx(%coord_678, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_680 = cute.add_offset(%ptr_628, %idx_679) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %879 = builtin.unrealized_conversion_cast %ptr_680 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %880 = llvm.getelementptr %879[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %881 = llvm.getelementptr %879[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %882 = llvm.getelementptr %879[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb173(%c0_i32 : i32)
    ^bb173(%883: i32):  // 2 preds: ^bb172, ^bb174
      %884 = arith.cmpi slt, %883, %658 : i32
      cf.cond_br %884, ^bb174, ^bb175 {llvm.loop_annotation = #loop_annotation}
    ^bb174:  // pred: ^bb173
      %coord_681 = cute.make_coord(%883, %875) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_682 = cute.make_coord(%877, %883) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_683 = cute.crd2idx(%coord_681, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_684 = cute.add_offset(%ptr_638, %idx_683) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_685 = cute.crd2idx(%coord_682, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_686 = cute.add_offset(%iter_459, %idx_685) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %885 = llvm.load %879 : !llvm.ptr -> i32
      %886 = llvm.load %880 : !llvm.ptr -> i32
      %887 = llvm.load %881 : !llvm.ptr -> i32
      %888 = llvm.load %882 : !llvm.ptr -> i32
      %889 = builtin.unrealized_conversion_cast %ptr_684 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %890 = llvm.load %889 : !llvm.ptr -> i32
      %891 = llvm.getelementptr %889[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %892 = llvm.load %891 : !llvm.ptr -> i32
      %893 = builtin.unrealized_conversion_cast %ptr_686 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %894 = llvm.load %893 : !llvm.ptr -> f32
      %895 = llvm.getelementptr %893[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %896 = llvm.load %895 : !llvm.ptr -> f32
      %897 = llvm.getelementptr %893[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %898 = llvm.load %897 : !llvm.ptr -> f32
      %899 = llvm.getelementptr %893[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %900 = llvm.load %899 : !llvm.ptr -> f32
      %901:4 = cute_nvgpu.arch.mma.SM80 A[%885, %886, %887, %888]  B[%890, %892]  C[%894, %896, %898, %900] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %901#0, %893 : f32, !llvm.ptr
      llvm.store %901#1, %895 : f32, !llvm.ptr
      llvm.store %901#2, %897 : f32, !llvm.ptr
      llvm.store %901#3, %899 : f32, !llvm.ptr
      %902 = arith.addi %883, %c1_i32 : i32
      cf.br ^bb173(%902 : i32)
    ^bb175:  // pred: ^bb173
      %903 = arith.addi %877, %c1_i32 : i32
      cf.br ^bb171(%903 : i32)
    ^bb176:  // pred: ^bb171
      %904 = arith.addi %875, %c1_i32 : i32
      cf.br ^bb169(%904 : i32)
    ^bb177:  // pred: ^bb169
      %idx_687 = cute.crd2idx(%107, %lay_126) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_688 = cute.add_offset(%ptr_122, %idx_687) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_689 = cute.add_offset(%iter_127, %106) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb178(%c0_i32 : i32)
    ^bb178(%905: i32):  // 2 preds: ^bb177, ^bb179
      %906 = arith.cmpi slt, %905, %607 : i32
      cf.cond_br %906, ^bb179, ^bb180 {llvm.loop_annotation = #loop_annotation}
    ^bb179:  // pred: ^bb178
      %coord_690 = cute.make_coord(%905) : (i32) -> !cute.coord<"(_,?)">
      %idx_691 = cute.crd2idx(%coord_690, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_692 = cute.add_offset(%ptr_688, %idx_691) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_693 = cute.crd2idx(%coord_690, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_694 = cute.add_offset(%ptr_689, %idx_693) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %907 = cute_nvgpu.arch.copy.ldsm %ptr_692{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %908 = vector.extractelement %907[%130 : i32] : vector<4xi32>
      %909 = builtin.unrealized_conversion_cast %ptr_694 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %908, %909 : i32, !llvm.ptr
      %910 = vector.extractelement %907[%129 : i32] : vector<4xi32>
      %ptr_695 = cute.add_offset(%ptr_694, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %911 = builtin.unrealized_conversion_cast %ptr_695 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %910, %911 : i32, !llvm.ptr
      %912 = vector.extractelement %907[%128 : i32] : vector<4xi32>
      %ptr_696 = cute.add_offset(%ptr_694, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %913 = builtin.unrealized_conversion_cast %ptr_696 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %912, %913 : i32, !llvm.ptr
      %914 = vector.extractelement %907[%126 : i32] : vector<4xi32>
      %ptr_697 = cute.add_offset(%ptr_694, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %915 = builtin.unrealized_conversion_cast %ptr_697 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %914, %915 : i32, !llvm.ptr
      %916 = arith.addi %905, %c1_i32 : i32
      cf.br ^bb178(%916 : i32)
    ^bb180:  // pred: ^bb178
      %idx_698 = cute.crd2idx(%107, %lay_134) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_699 = cute.add_offset(%ptr_130, %idx_698) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_700 = cute.add_offset(%iter_135, %105) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"160">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb181(%c0_i32 : i32)
    ^bb181(%917: i32):  // 2 preds: ^bb180, ^bb182
      %918 = arith.cmpi slt, %917, %620 : i32
      cf.cond_br %918, ^bb182, ^bb183 {llvm.loop_annotation = #loop_annotation}
    ^bb182:  // pred: ^bb181
      %coord_701 = cute.make_coord(%917) : (i32) -> !cute.coord<"(_,?)">
      %idx_702 = cute.crd2idx(%coord_701, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_703 = cute.add_offset(%ptr_699, %idx_702) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_704 = cute.crd2idx(%coord_701, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_705 = cute.add_offset(%ptr_700, %idx_704) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %919 = cute_nvgpu.arch.copy.ldsm %ptr_703{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %920 = vector.extractelement %919[%130 : i32] : vector<4xi32>
      %921 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %920, %921 : i32, !llvm.ptr
      %922 = vector.extractelement %919[%129 : i32] : vector<4xi32>
      %ptr_706 = cute.add_offset(%ptr_705, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %923 = builtin.unrealized_conversion_cast %ptr_706 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %922, %923 : i32, !llvm.ptr
      %924 = vector.extractelement %919[%128 : i32] : vector<4xi32>
      %ptr_707 = cute.add_offset(%ptr_705, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %925 = builtin.unrealized_conversion_cast %ptr_707 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %924, %925 : i32, !llvm.ptr
      %926 = vector.extractelement %919[%126 : i32] : vector<4xi32>
      %ptr_708 = cute.add_offset(%ptr_705, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %927 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %926, %927 : i32, !llvm.ptr
      %928 = arith.addi %917, %c1_i32 : i32
      cf.br ^bb181(%928 : i32)
    ^bb183:  // pred: ^bb181
      cf.br ^bb184(%c0_i32 : i32)
    ^bb184(%929: i32):  // 2 preds: ^bb183, ^bb191
      %930 = arith.cmpi slt, %929, %657 : i32
      cf.cond_br %930, ^bb185, ^bb192 {llvm.loop_annotation = #loop_annotation}
    ^bb185:  // pred: ^bb184
      cf.br ^bb186(%c0_i32 : i32)
    ^bb186(%931: i32):  // 2 preds: ^bb185, ^bb190
      %932 = arith.cmpi slt, %931, %607 : i32
      cf.cond_br %932, ^bb187, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb187:  // pred: ^bb186
      %coord_709 = cute.make_coord(%931, %929) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_710 = cute.crd2idx(%coord_709, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_711 = cute.add_offset(%ptr_658, %idx_710) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %933 = builtin.unrealized_conversion_cast %ptr_711 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %934 = llvm.getelementptr %933[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %935 = llvm.getelementptr %933[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %936 = llvm.getelementptr %933[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb188(%c0_i32 : i32)
    ^bb188(%937: i32):  // 2 preds: ^bb187, ^bb189
      %938 = arith.cmpi slt, %937, %658 : i32
      cf.cond_br %938, ^bb189, ^bb190 {llvm.loop_annotation = #loop_annotation}
    ^bb189:  // pred: ^bb188
      %coord_712 = cute.make_coord(%937, %929) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_713 = cute.make_coord(%931, %937) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_714 = cute.crd2idx(%coord_712, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_715 = cute.add_offset(%ptr_669, %idx_714) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_716 = cute.crd2idx(%coord_713, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_717 = cute.add_offset(%iter_459, %idx_716) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %939 = llvm.load %933 : !llvm.ptr -> i32
      %940 = llvm.load %934 : !llvm.ptr -> i32
      %941 = llvm.load %935 : !llvm.ptr -> i32
      %942 = llvm.load %936 : !llvm.ptr -> i32
      %943 = builtin.unrealized_conversion_cast %ptr_715 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %944 = llvm.load %943 : !llvm.ptr -> i32
      %945 = llvm.getelementptr %943[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %946 = llvm.load %945 : !llvm.ptr -> i32
      %947 = builtin.unrealized_conversion_cast %ptr_717 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %948 = llvm.load %947 : !llvm.ptr -> f32
      %949 = llvm.getelementptr %947[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %950 = llvm.load %949 : !llvm.ptr -> f32
      %951 = llvm.getelementptr %947[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %952 = llvm.load %951 : !llvm.ptr -> f32
      %953 = llvm.getelementptr %947[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %954 = llvm.load %953 : !llvm.ptr -> f32
      %955:4 = cute_nvgpu.arch.mma.SM80 A[%939, %940, %941, %942]  B[%944, %946]  C[%948, %950, %952, %954] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %955#0, %947 : f32, !llvm.ptr
      llvm.store %955#1, %949 : f32, !llvm.ptr
      llvm.store %955#2, %951 : f32, !llvm.ptr
      llvm.store %955#3, %953 : f32, !llvm.ptr
      %956 = arith.addi %937, %c1_i32 : i32
      cf.br ^bb188(%956 : i32)
    ^bb190:  // pred: ^bb188
      %957 = arith.addi %931, %c1_i32 : i32
      cf.br ^bb186(%957 : i32)
    ^bb191:  // pred: ^bb186
      %958 = arith.addi %929, %c1_i32 : i32
      cf.br ^bb184(%958 : i32)
    ^bb192:  // pred: ^bb184
      %idx_718 = cute.crd2idx(%104, %lay_126) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),2,((2,2),2)):((1,0),4096,((?{div=16},?{div=32}),8192))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_719 = cute.add_offset(%ptr_122, %idx_718) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_720 = cute.add_offset(%iter_127, %103) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<16>>
      cf.br ^bb193(%c0_i32 : i32)
    ^bb193(%959: i32):  // 2 preds: ^bb192, ^bb194
      %960 = arith.cmpi slt, %959, %607 : i32
      cf.cond_br %960, ^bb194, ^bb195 {llvm.loop_annotation = #loop_annotation}
    ^bb194:  // pred: ^bb193
      %coord_721 = cute.make_coord(%959) : (i32) -> !cute.coord<"(_,?)">
      %idx_722 = cute.crd2idx(%coord_721, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_723 = cute.add_offset(%ptr_719, %idx_722) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_724 = cute.crd2idx(%coord_721, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_725 = cute.add_offset(%ptr_720, %idx_724) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %961 = cute_nvgpu.arch.copy.ldsm %ptr_723{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %962 = vector.extractelement %961[%130 : i32] : vector<4xi32>
      %963 = builtin.unrealized_conversion_cast %ptr_725 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %962, %963 : i32, !llvm.ptr
      %964 = vector.extractelement %961[%129 : i32] : vector<4xi32>
      %ptr_726 = cute.add_offset(%ptr_725, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %965 = builtin.unrealized_conversion_cast %ptr_726 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %964, %965 : i32, !llvm.ptr
      %966 = vector.extractelement %961[%128 : i32] : vector<4xi32>
      %ptr_727 = cute.add_offset(%ptr_725, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %967 = builtin.unrealized_conversion_cast %ptr_727 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %966, %967 : i32, !llvm.ptr
      %968 = vector.extractelement %961[%126 : i32] : vector<4xi32>
      %ptr_728 = cute.add_offset(%ptr_725, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %969 = builtin.unrealized_conversion_cast %ptr_728 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %968, %969 : i32, !llvm.ptr
      %970 = arith.addi %959, %c1_i32 : i32
      cf.br ^bb193(%970 : i32)
    ^bb195:  // pred: ^bb193
      %idx_729 = cute.crd2idx(%104, %lay_134) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_730 = cute.add_offset(%ptr_130, %idx_729) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_731 = cute.add_offset(%iter_135, %102) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"224">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb196(%c0_i32 : i32)
    ^bb196(%971: i32):  // 2 preds: ^bb195, ^bb197
      %972 = arith.cmpi slt, %971, %620 : i32
      cf.cond_br %972, ^bb197, ^bb198 {llvm.loop_annotation = #loop_annotation}
    ^bb197:  // pred: ^bb196
      %coord_732 = cute.make_coord(%971) : (i32) -> !cute.coord<"(_,?)">
      %idx_733 = cute.crd2idx(%coord_732, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_734 = cute.add_offset(%ptr_730, %idx_733) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_735 = cute.crd2idx(%coord_732, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_736 = cute.add_offset(%ptr_731, %idx_735) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %973 = cute_nvgpu.arch.copy.ldsm %ptr_734{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %974 = vector.extractelement %973[%130 : i32] : vector<4xi32>
      %975 = builtin.unrealized_conversion_cast %ptr_736 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %974, %975 : i32, !llvm.ptr
      %976 = vector.extractelement %973[%129 : i32] : vector<4xi32>
      %ptr_737 = cute.add_offset(%ptr_736, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %977 = builtin.unrealized_conversion_cast %ptr_737 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %976, %977 : i32, !llvm.ptr
      %978 = vector.extractelement %973[%128 : i32] : vector<4xi32>
      %ptr_738 = cute.add_offset(%ptr_736, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %979 = builtin.unrealized_conversion_cast %ptr_738 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %978, %979 : i32, !llvm.ptr
      %980 = vector.extractelement %973[%126 : i32] : vector<4xi32>
      %ptr_739 = cute.add_offset(%ptr_736, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %981 = builtin.unrealized_conversion_cast %ptr_739 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %980, %981 : i32, !llvm.ptr
      %982 = arith.addi %971, %c1_i32 : i32
      cf.br ^bb196(%982 : i32)
    ^bb198:  // pred: ^bb196
      cf.br ^bb199(%c0_i32 : i32)
    ^bb199(%983: i32):  // 2 preds: ^bb198, ^bb206
      %984 = arith.cmpi slt, %983, %657 : i32
      cf.cond_br %984, ^bb200, ^bb207 {llvm.loop_annotation = #loop_annotation}
    ^bb200:  // pred: ^bb199
      cf.br ^bb201(%c0_i32 : i32)
    ^bb201(%985: i32):  // 2 preds: ^bb200, ^bb205
      %986 = arith.cmpi slt, %985, %607 : i32
      cf.cond_br %986, ^bb202, ^bb206 {llvm.loop_annotation = #loop_annotation}
    ^bb202:  // pred: ^bb201
      %coord_740 = cute.make_coord(%985, %983) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_741 = cute.crd2idx(%coord_740, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_742 = cute.add_offset(%ptr_689, %idx_741) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %987 = builtin.unrealized_conversion_cast %ptr_742 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %988 = llvm.getelementptr %987[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %989 = llvm.getelementptr %987[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %990 = llvm.getelementptr %987[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb203(%c0_i32 : i32)
    ^bb203(%991: i32):  // 2 preds: ^bb202, ^bb204
      %992 = arith.cmpi slt, %991, %658 : i32
      cf.cond_br %992, ^bb204, ^bb205 {llvm.loop_annotation = #loop_annotation}
    ^bb204:  // pred: ^bb203
      %coord_743 = cute.make_coord(%991, %983) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_744 = cute.make_coord(%985, %991) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_745 = cute.crd2idx(%coord_743, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_746 = cute.add_offset(%ptr_700, %idx_745) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_747 = cute.crd2idx(%coord_744, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_748 = cute.add_offset(%iter_459, %idx_747) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %993 = llvm.load %987 : !llvm.ptr -> i32
      %994 = llvm.load %988 : !llvm.ptr -> i32
      %995 = llvm.load %989 : !llvm.ptr -> i32
      %996 = llvm.load %990 : !llvm.ptr -> i32
      %997 = builtin.unrealized_conversion_cast %ptr_746 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %998 = llvm.load %997 : !llvm.ptr -> i32
      %999 = llvm.getelementptr %997[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1000 = llvm.load %999 : !llvm.ptr -> i32
      %1001 = builtin.unrealized_conversion_cast %ptr_748 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1002 = llvm.load %1001 : !llvm.ptr -> f32
      %1003 = llvm.getelementptr %1001[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1004 = llvm.load %1003 : !llvm.ptr -> f32
      %1005 = llvm.getelementptr %1001[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1006 = llvm.load %1005 : !llvm.ptr -> f32
      %1007 = llvm.getelementptr %1001[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1008 = llvm.load %1007 : !llvm.ptr -> f32
      %1009:4 = cute_nvgpu.arch.mma.SM80 A[%993, %994, %995, %996]  B[%998, %1000]  C[%1002, %1004, %1006, %1008] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1009#0, %1001 : f32, !llvm.ptr
      llvm.store %1009#1, %1003 : f32, !llvm.ptr
      llvm.store %1009#2, %1005 : f32, !llvm.ptr
      llvm.store %1009#3, %1007 : f32, !llvm.ptr
      %1010 = arith.addi %991, %c1_i32 : i32
      cf.br ^bb203(%1010 : i32)
    ^bb205:  // pred: ^bb203
      %1011 = arith.addi %985, %c1_i32 : i32
      cf.br ^bb201(%1011 : i32)
    ^bb206:  // pred: ^bb201
      %1012 = arith.addi %983, %c1_i32 : i32
      cf.br ^bb199(%1012 : i32)
    ^bb207:  // pred: ^bb199
      cf.br ^bb208(%c0_i32 : i32)
    ^bb208(%1013: i32):  // 2 preds: ^bb207, ^bb209
      %1014 = arith.cmpi slt, %1013, %607 : i32
      cf.cond_br %1014, ^bb209, ^bb210 {llvm.loop_annotation = #loop_annotation}
    ^bb209:  // pred: ^bb208
      %coord_749 = cute.make_coord(%1013) : (i32) -> !cute.coord<"(_,?)">
      %idx_750 = cute.crd2idx(%coord_749, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_751 = cute.add_offset(%ptr_122, %idx_750) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_752 = cute.crd2idx(%coord_749, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_753 = cute.add_offset(%iter_127, %idx_752) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1015 = cute_nvgpu.arch.copy.ldsm %ptr_751{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1016 = vector.extractelement %1015[%130 : i32] : vector<4xi32>
      %1017 = builtin.unrealized_conversion_cast %ptr_753 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1016, %1017 : i32, !llvm.ptr
      %1018 = vector.extractelement %1015[%129 : i32] : vector<4xi32>
      %ptr_754 = cute.add_offset(%ptr_753, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1019 = builtin.unrealized_conversion_cast %ptr_754 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1018, %1019 : i32, !llvm.ptr
      %1020 = vector.extractelement %1015[%128 : i32] : vector<4xi32>
      %ptr_755 = cute.add_offset(%ptr_753, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1021 = builtin.unrealized_conversion_cast %ptr_755 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1020, %1021 : i32, !llvm.ptr
      %1022 = vector.extractelement %1015[%126 : i32] : vector<4xi32>
      %ptr_756 = cute.add_offset(%ptr_753, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1023 = builtin.unrealized_conversion_cast %ptr_756 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1022, %1023 : i32, !llvm.ptr
      %1024 = arith.addi %1013, %c1_i32 : i32
      cf.br ^bb208(%1024 : i32)
    ^bb210:  // pred: ^bb208
      cf.br ^bb211(%c0_i32 : i32)
    ^bb211(%1025: i32):  // 2 preds: ^bb210, ^bb212
      %1026 = arith.cmpi slt, %1025, %620 : i32
      cf.cond_br %1026, ^bb212, ^bb213 {llvm.loop_annotation = #loop_annotation}
    ^bb212:  // pred: ^bb211
      %coord_757 = cute.make_coord(%1025) : (i32) -> !cute.coord<"(_,?)">
      %idx_758 = cute.crd2idx(%coord_757, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_759 = cute.add_offset(%ptr_130, %idx_758) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_760 = cute.crd2idx(%coord_757, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_761 = cute.add_offset(%iter_135, %idx_760) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1027 = cute_nvgpu.arch.copy.ldsm %ptr_759{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1028 = vector.extractelement %1027[%130 : i32] : vector<4xi32>
      %1029 = builtin.unrealized_conversion_cast %ptr_761 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1028, %1029 : i32, !llvm.ptr
      %1030 = vector.extractelement %1027[%129 : i32] : vector<4xi32>
      %ptr_762 = cute.add_offset(%ptr_761, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1031 = builtin.unrealized_conversion_cast %ptr_762 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1030, %1031 : i32, !llvm.ptr
      %1032 = vector.extractelement %1027[%128 : i32] : vector<4xi32>
      %ptr_763 = cute.add_offset(%ptr_761, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1033 = builtin.unrealized_conversion_cast %ptr_763 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1032, %1033 : i32, !llvm.ptr
      %1034 = vector.extractelement %1027[%126 : i32] : vector<4xi32>
      %ptr_764 = cute.add_offset(%ptr_761, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1035 = builtin.unrealized_conversion_cast %ptr_764 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1034, %1035 : i32, !llvm.ptr
      %1036 = arith.addi %1025, %c1_i32 : i32
      cf.br ^bb211(%1036 : i32)
    ^bb213:  // pred: ^bb211
      cf.br ^bb214(%c0_i32 : i32)
    ^bb214(%1037: i32):  // 2 preds: ^bb213, ^bb221
      %1038 = arith.cmpi slt, %1037, %657 : i32
      cf.cond_br %1038, ^bb215, ^bb222 {llvm.loop_annotation = #loop_annotation}
    ^bb215:  // pred: ^bb214
      cf.br ^bb216(%c0_i32 : i32)
    ^bb216(%1039: i32):  // 2 preds: ^bb215, ^bb220
      %1040 = arith.cmpi slt, %1039, %607 : i32
      cf.cond_br %1040, ^bb217, ^bb221 {llvm.loop_annotation = #loop_annotation}
    ^bb217:  // pred: ^bb216
      %coord_765 = cute.make_coord(%1039, %1037) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_766 = cute.crd2idx(%coord_765, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_767 = cute.add_offset(%ptr_720, %idx_766) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1041 = builtin.unrealized_conversion_cast %ptr_767 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1042 = llvm.getelementptr %1041[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1043 = llvm.getelementptr %1041[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1044 = llvm.getelementptr %1041[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb218(%c0_i32 : i32)
    ^bb218(%1045: i32):  // 2 preds: ^bb217, ^bb219
      %1046 = arith.cmpi slt, %1045, %658 : i32
      cf.cond_br %1046, ^bb219, ^bb220 {llvm.loop_annotation = #loop_annotation}
    ^bb219:  // pred: ^bb218
      %coord_768 = cute.make_coord(%1045, %1037) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_769 = cute.make_coord(%1039, %1045) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_770 = cute.crd2idx(%coord_768, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_771 = cute.add_offset(%ptr_731, %idx_770) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_772 = cute.crd2idx(%coord_769, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_773 = cute.add_offset(%iter_459, %idx_772) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1047 = llvm.load %1041 : !llvm.ptr -> i32
      %1048 = llvm.load %1042 : !llvm.ptr -> i32
      %1049 = llvm.load %1043 : !llvm.ptr -> i32
      %1050 = llvm.load %1044 : !llvm.ptr -> i32
      %1051 = builtin.unrealized_conversion_cast %ptr_771 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1052 = llvm.load %1051 : !llvm.ptr -> i32
      %1053 = llvm.getelementptr %1051[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1054 = llvm.load %1053 : !llvm.ptr -> i32
      %1055 = builtin.unrealized_conversion_cast %ptr_773 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1056 = llvm.load %1055 : !llvm.ptr -> f32
      %1057 = llvm.getelementptr %1055[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1058 = llvm.load %1057 : !llvm.ptr -> f32
      %1059 = llvm.getelementptr %1055[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1060 = llvm.load %1059 : !llvm.ptr -> f32
      %1061 = llvm.getelementptr %1055[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1062 = llvm.load %1061 : !llvm.ptr -> f32
      %1063:4 = cute_nvgpu.arch.mma.SM80 A[%1047, %1048, %1049, %1050]  B[%1052, %1054]  C[%1056, %1058, %1060, %1062] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1063#0, %1055 : f32, !llvm.ptr
      llvm.store %1063#1, %1057 : f32, !llvm.ptr
      llvm.store %1063#2, %1059 : f32, !llvm.ptr
      llvm.store %1063#3, %1061 : f32, !llvm.ptr
      %1064 = arith.addi %1045, %c1_i32 : i32
      cf.br ^bb218(%1064 : i32)
    ^bb220:  // pred: ^bb218
      %1065 = arith.addi %1039, %c1_i32 : i32
      cf.br ^bb216(%1065 : i32)
    ^bb221:  // pred: ^bb216
      %1066 = arith.addi %1037, %c1_i32 : i32
      cf.br ^bb214(%1066 : i32)
    ^bb222:  // pred: ^bb214
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %1067 = arith.cmpi sgt, %205, %c0_i32 : i32
      cf.cond_br %1067, ^bb223, ^bb227
    ^bb223:  // pred: ^bb222
      %1068 = arith.subi %204, %c2_i32 : i32
      %coord_774 = cute.make_coord(%1068) : (i32) -> !cute.coord<"(_,_,_,?)">
      %1069:3 = cute.get_scalars(%lay_104) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_775 = cute.assume(%1069#1) : (i64) -> !cute.i64<divby 128>
      %stride_776 = cute.make_stride(%iv_775) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_777 = cute.make_layout(%137, %stride_776) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_778 = cute.crd2idx(%coord_774, %lay_104) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_779 = cute.add_offset(%ptr_99, %idx_778) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %append = cute.append_to_rank<2> (%lay_777, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1070 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_780 = cute.assume(%1070) : (i64) -> !cute.i64<divby 128>
      %stride_781 = cute.make_stride(%iv_780) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_782 = cute.make_layout(%136, %stride_781) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_783 = cute.append_to_rank<2> (%lay_782, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1071 = cute.get_scalars(%append_783) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_784 = cute.assume(%1071) : (i64) -> !cute.i64<divby 128>
      %stride_785 = cute.make_stride(%iv_784) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_786 = cute.make_layout(%135, %stride_785) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb224(%c0_i32 : i32)
    ^bb224(%1072: i32):  // 2 preds: ^bb223, ^bb225
      %1073 = arith.cmpi slt, %1072, %658 : i32
      cf.cond_br %1073, ^bb225, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb225:  // pred: ^bb224
      %coord_787 = cute.make_coord(%1072) : (i32) -> !cute.coord<"(_,?)">
      %idx_788 = cute.crd2idx(%coord_787, %lay_786) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_789 = cute.add_offset(%ptr_779, %idx_788) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_790 = cute.crd2idx(%coord_787, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_791 = cute.add_offset(%ptr_105, %idx_790) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_792 = cute.crd2idx(%coord_787, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_793 = cute.add_offset(%iter_194, %idx_792) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1074 = builtin.unrealized_conversion_cast %ptr_793 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1075 = llvm.load %1074 : !llvm.ptr -> i8
      %1076 = llvm.trunc %1075 : i8 to i1
      %iter_794 = cute.recast_iter(%ptr_789) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_795 = cute.recast_iter(%ptr_791) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_795 : !cute.ptr<i128, smem>, %iter_794 : !cute.ptr<i128, gmem>, %1076 : i1) {cache_mode = <global>}
      %1077 = arith.addi %1072, %c1_i32 : i32
      cf.br ^bb224(%1077 : i32)
    ^bb226:  // pred: ^bb224
      nvvm.cp.async.commit.group
      cf.br ^bb227
    ^bb227:  // 2 preds: ^bb222, ^bb226
      %view_796 = cute.make_view(%iter_459, %101) : !memref_rmem_f32_3
      %shape_797 = cute.make_shape(%itup_146, %itup_147, %itup_148, %itup) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?)">
      %lay_798 = cute.make_layout(%shape_797, %171) : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %1078:4 = cute.get_scalars(%lay_798) <{only_dynamic}> : !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">
      %shape_799 = cute.make_shape(%1078#1, %1078#3) : (i32, i32) -> !cute.shape<"(?,?)">
      %lay_800 = cute.make_layout(%shape_799, %170) : !cute.layout<"(?,?):(1@1,1@3)">
      %idx_801 = cute.crd2idx(%coord, %lay_798) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_802 = cute.add_offset(%172, %idx_801) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_803 = cute.make_coord(%183, %205) : (i32, i32) -> !cute.coord<"(?,?)">
      %1079:2 = cute.get_scalars(%coord_803) <{only_dynamic}> : !cute.coord<"(?,?)">
      %coord_804 = cute.make_coord(%1079#0, %1079#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %1080:2 = cute.get_scalars(%lay_800) <{only_dynamic}> : !cute.layout<"(?,?):(1@1,1@3)">
      %c1_i32_805 = arith.constant 1 : i32
      %c0_i32_806 = arith.constant 0 : i32
      %c-1_i32_807 = arith.constant -1 : i32
      %1081 = arith.cmpi sgt, %c128_i32, %c0_i32_806 : i32
      %1082 = arith.select %1081, %c-1_i32_807, %c1_i32_805 : i32
      %1083 = arith.addi %1082, %1080#0 : i32
      %1084 = arith.divsi %1083, %c128_i32 : i32
      %1085 = arith.addi %c1_i32_805, %1084 : i32
      %1086 = arith.subi %c0_i32_806, %1080#0 : i32
      %1087 = arith.divsi %1086, %c128_i32 : i32
      %1088 = arith.subi %c0_i32_806, %1087 : i32
      %1089 = arith.cmpi slt, %1080#0, %c0_i32_806 : i32
      %1090 = arith.cmpi sgt, %1080#0, %c0_i32_806 : i32
      %1091 = arith.cmpi slt, %c128_i32, %c0_i32_806 : i32
      %1092 = arith.cmpi sgt, %c128_i32, %c0_i32_806 : i32
      %1093 = arith.andi %1089, %1091 : i1
      %1094 = arith.andi %1090, %1092 : i1
      %1095 = arith.ori %1093, %1094 : i1
      %1096 = arith.select %1095, %1085, %1088 : i32
      %c1_i32_808 = arith.constant 1 : i32
      %c0_i32_809 = arith.constant 0 : i32
      %c-1_i32_810 = arith.constant -1 : i32
      %1097 = arith.cmpi sgt, %c64_i32, %c0_i32_809 : i32
      %1098 = arith.select %1097, %c-1_i32_810, %c1_i32_808 : i32
      %1099 = arith.addi %1098, %1080#1 : i32
      %1100 = arith.divsi %1099, %c64_i32 : i32
      %1101 = arith.addi %c1_i32_808, %1100 : i32
      %1102 = arith.subi %c0_i32_809, %1080#1 : i32
      %1103 = arith.divsi %1102, %c64_i32 : i32
      %1104 = arith.subi %c0_i32_809, %1103 : i32
      %1105 = arith.cmpi slt, %1080#1, %c0_i32_809 : i32
      %1106 = arith.cmpi sgt, %1080#1, %c0_i32_809 : i32
      %1107 = arith.cmpi slt, %c64_i32, %c0_i32_809 : i32
      %1108 = arith.cmpi sgt, %c64_i32, %c0_i32_809 : i32
      %1109 = arith.andi %1105, %1107 : i1
      %1110 = arith.andi %1106, %1108 : i1
      %1111 = arith.ori %1109, %1110 : i1
      %1112 = arith.select %1111, %1101, %1104 : i32
      %shape_811 = cute.make_shape(%1096, %1112) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_812 = cute.make_layout(%shape_811, %100) : !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">
      %idx_813 = cute.crd2idx(%coord_804, %lay_812) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,64),(?,?)):((1@1,1@3),(128@1,64@3))">) -> !cute.int_tuple<"(0,?{div=128},0,?{div=64})">
      %tup_814 = cute.add_offset(%tup_802, %idx_813) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,?{div=64})">) -> !cute.int_tuple<"(?,?{div=128},?,?{div=64})">
      %1113 = arith.remsi %316, %c32_i32 : i32
      %1114 = arith.divsi %316, %c32_i32 : i32
      %1115 = arith.remsi %1114, %c4_i32 : i32
      %1116 = arith.remsi %1113, %c32_i32 : i32
      %1117 = arith.remsi %1115, %c4_i32 : i32
      %1118 = arith.divsi %1116, %c4_i32 : i32
      %1119 = arith.remsi %1116, %c4_i32 : i32
      %1120 = arith.muli %1119, %c2_i32 : i32
      %1121 = arith.muli %1117, %c16_i32 : i32
      %1122 = arith.addi %1118, %1121 : i32
      %iv_815 = cute.assume(%1120) : (i32) -> !cute.i32<divby 2>
      %int_tuple_816 = cute.make_int_tuple(%1122, %iv_815) : (i32, !cute.i32<divby 2>) -> !cute.int_tuple<"(0,?,0,?{div=2})">
      %tup_817 = cute.add_offset(%tup_814, %int_tuple_816) : (!cute.int_tuple<"(?,?{div=128},?,?{div=64})">, !cute.int_tuple<"(0,?,0,?{div=2})">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_818, %e1_819, %e2_820, %e3_821 = cute.get_leaves(%tup_817) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %int_tuple_822 = cute.make_int_tuple(%e0_818, %e1_819, %e2_820, %e3_821) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_823, %e1_824, %e2_825, %e3_826 = cute.get_leaves(%int_tuple_822) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_827 = cute.add_offset(%e3_826, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_828 = cute.make_coord(%tup_827) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1123 = cute.get_scalars(%coord_828) : !cute.coord<"?">
      %1124 = arith.cmpi slt, %543, %1123 : i32
      cf.cond_br %1124, ^bb228, ^bb229
    ^bb228:  // pred: ^bb227
      cute.memref.store(%view_796, %99, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,0)">, f32) -> ()
      cf.br ^bb229
    ^bb229:  // 2 preds: ^bb227, ^bb228
      %tup_829 = cute.add_offset(%int_tuple_822, %98) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,1)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_830, %e1_831, %e2_832, %e3_833 = cute.get_leaves(%tup_829) : !cute.int_tuple<"(?,?,?,?)">
      %tup_834 = cute.add_offset(%e3_833, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_835 = cute.make_coord(%tup_834) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1125 = cute.get_scalars(%coord_835) : !cute.coord<"?">
      %1126 = arith.cmpi slt, %543, %1125 : i32
      cf.cond_br %1126, ^bb230, ^bb231
    ^bb230:  // pred: ^bb229
      cute.memref.store(%view_796, %97, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,1)">, f32) -> ()
      cf.br ^bb231
    ^bb231:  // 2 preds: ^bb229, ^bb230
      %tup_836 = cute.add_offset(%int_tuple_822, %96) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,8)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_837, %e1_838, %e2_839, %e3_840 = cute.get_leaves(%tup_836) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_841 = cute.add_offset(%e3_840, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_842 = cute.make_coord(%tup_841) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1127 = cute.get_scalars(%coord_842) : !cute.coord<"?">
      %1128 = arith.cmpi slt, %543, %1127 : i32
      cf.cond_br %1128, ^bb232, ^bb233
    ^bb232:  // pred: ^bb231
      cute.memref.store(%view_796, %95, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,2)">, f32) -> ()
      cf.br ^bb233
    ^bb233:  // 2 preds: ^bb231, ^bb232
      %tup_843 = cute.add_offset(%int_tuple_822, %94) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,9)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_844, %e1_845, %e2_846, %e3_847 = cute.get_leaves(%tup_843) : !cute.int_tuple<"(?,?,?,?)">
      %tup_848 = cute.add_offset(%e3_847, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_849 = cute.make_coord(%tup_848) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1129 = cute.get_scalars(%coord_849) : !cute.coord<"?">
      %1130 = arith.cmpi slt, %543, %1129 : i32
      cf.cond_br %1130, ^bb234, ^bb235
    ^bb234:  // pred: ^bb233
      cute.memref.store(%view_796, %93, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,3)">, f32) -> ()
      cf.br ^bb235
    ^bb235:  // 2 preds: ^bb233, ^bb234
      %tup_850 = cute.add_offset(%int_tuple_822, %92) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,16)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_851, %e1_852, %e2_853, %e3_854 = cute.get_leaves(%tup_850) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_855 = cute.add_offset(%e3_854, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_856 = cute.make_coord(%tup_855) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1131 = cute.get_scalars(%coord_856) : !cute.coord<"?">
      %1132 = arith.cmpi slt, %543, %1131 : i32
      cf.cond_br %1132, ^bb236, ^bb237
    ^bb236:  // pred: ^bb235
      cute.memref.store(%view_796, %91, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,4)">, f32) -> ()
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      %tup_857 = cute.add_offset(%int_tuple_822, %90) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,17)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_858, %e1_859, %e2_860, %e3_861 = cute.get_leaves(%tup_857) : !cute.int_tuple<"(?,?,?,?)">
      %tup_862 = cute.add_offset(%e3_861, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_863 = cute.make_coord(%tup_862) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1133 = cute.get_scalars(%coord_863) : !cute.coord<"?">
      %1134 = arith.cmpi slt, %543, %1133 : i32
      cf.cond_br %1134, ^bb238, ^bb239
    ^bb238:  // pred: ^bb237
      cute.memref.store(%view_796, %89, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,5)">, f32) -> ()
      cf.br ^bb239
    ^bb239:  // 2 preds: ^bb237, ^bb238
      %tup_864 = cute.add_offset(%int_tuple_822, %88) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,24)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_865, %e1_866, %e2_867, %e3_868 = cute.get_leaves(%tup_864) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_869 = cute.add_offset(%e3_868, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_870 = cute.make_coord(%tup_869) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1135 = cute.get_scalars(%coord_870) : !cute.coord<"?">
      %1136 = arith.cmpi slt, %543, %1135 : i32
      cf.cond_br %1136, ^bb240, ^bb241
    ^bb240:  // pred: ^bb239
      cute.memref.store(%view_796, %87, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,6)">, f32) -> ()
      cf.br ^bb241
    ^bb241:  // 2 preds: ^bb239, ^bb240
      %tup_871 = cute.add_offset(%int_tuple_822, %86) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,25)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_872, %e1_873, %e2_874, %e3_875 = cute.get_leaves(%tup_871) : !cute.int_tuple<"(?,?,?,?)">
      %tup_876 = cute.add_offset(%e3_875, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_877 = cute.make_coord(%tup_876) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1137 = cute.get_scalars(%coord_877) : !cute.coord<"?">
      %1138 = arith.cmpi slt, %543, %1137 : i32
      cf.cond_br %1138, ^bb242, ^bb243
    ^bb242:  // pred: ^bb241
      cute.memref.store(%view_796, %85, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,7)">, f32) -> ()
      cf.br ^bb243
    ^bb243:  // 2 preds: ^bb241, ^bb242
      %tup_878 = cute.add_offset(%int_tuple_822, %84) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,32)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_879, %e1_880, %e2_881, %e3_882 = cute.get_leaves(%tup_878) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_883 = cute.add_offset(%e3_882, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_884 = cute.make_coord(%tup_883) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1139 = cute.get_scalars(%coord_884) : !cute.coord<"?">
      %1140 = arith.cmpi slt, %543, %1139 : i32
      cf.cond_br %1140, ^bb244, ^bb245
    ^bb244:  // pred: ^bb243
      cute.memref.store(%view_796, %83, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,8)">, f32) -> ()
      cf.br ^bb245
    ^bb245:  // 2 preds: ^bb243, ^bb244
      %tup_885 = cute.add_offset(%int_tuple_822, %82) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,33)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_886, %e1_887, %e2_888, %e3_889 = cute.get_leaves(%tup_885) : !cute.int_tuple<"(?,?,?,?)">
      %tup_890 = cute.add_offset(%e3_889, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_891 = cute.make_coord(%tup_890) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1141 = cute.get_scalars(%coord_891) : !cute.coord<"?">
      %1142 = arith.cmpi slt, %543, %1141 : i32
      cf.cond_br %1142, ^bb246, ^bb247
    ^bb246:  // pred: ^bb245
      cute.memref.store(%view_796, %81, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,9)">, f32) -> ()
      cf.br ^bb247
    ^bb247:  // 2 preds: ^bb245, ^bb246
      %tup_892 = cute.add_offset(%int_tuple_822, %80) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,40)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_893, %e1_894, %e2_895, %e3_896 = cute.get_leaves(%tup_892) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_897 = cute.add_offset(%e3_896, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_898 = cute.make_coord(%tup_897) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1143 = cute.get_scalars(%coord_898) : !cute.coord<"?">
      %1144 = arith.cmpi slt, %543, %1143 : i32
      cf.cond_br %1144, ^bb248, ^bb249
    ^bb248:  // pred: ^bb247
      cute.memref.store(%view_796, %79, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,10)">, f32) -> ()
      cf.br ^bb249
    ^bb249:  // 2 preds: ^bb247, ^bb248
      %tup_899 = cute.add_offset(%int_tuple_822, %78) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,41)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_900, %e1_901, %e2_902, %e3_903 = cute.get_leaves(%tup_899) : !cute.int_tuple<"(?,?,?,?)">
      %tup_904 = cute.add_offset(%e3_903, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_905 = cute.make_coord(%tup_904) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1145 = cute.get_scalars(%coord_905) : !cute.coord<"?">
      %1146 = arith.cmpi slt, %543, %1145 : i32
      cf.cond_br %1146, ^bb250, ^bb251
    ^bb250:  // pred: ^bb249
      cute.memref.store(%view_796, %77, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,11)">, f32) -> ()
      cf.br ^bb251
    ^bb251:  // 2 preds: ^bb249, ^bb250
      %tup_906 = cute.add_offset(%int_tuple_822, %76) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,48)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_907, %e1_908, %e2_909, %e3_910 = cute.get_leaves(%tup_906) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_911 = cute.add_offset(%e3_910, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_912 = cute.make_coord(%tup_911) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1147 = cute.get_scalars(%coord_912) : !cute.coord<"?">
      %1148 = arith.cmpi slt, %543, %1147 : i32
      cf.cond_br %1148, ^bb252, ^bb253
    ^bb252:  // pred: ^bb251
      cute.memref.store(%view_796, %75, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,12)">, f32) -> ()
      cf.br ^bb253
    ^bb253:  // 2 preds: ^bb251, ^bb252
      %tup_913 = cute.add_offset(%int_tuple_822, %74) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,49)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_914, %e1_915, %e2_916, %e3_917 = cute.get_leaves(%tup_913) : !cute.int_tuple<"(?,?,?,?)">
      %tup_918 = cute.add_offset(%e3_917, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_919 = cute.make_coord(%tup_918) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1149 = cute.get_scalars(%coord_919) : !cute.coord<"?">
      %1150 = arith.cmpi slt, %543, %1149 : i32
      cf.cond_br %1150, ^bb254, ^bb255
    ^bb254:  // pred: ^bb253
      cute.memref.store(%view_796, %73, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,13)">, f32) -> ()
      cf.br ^bb255
    ^bb255:  // 2 preds: ^bb253, ^bb254
      %tup_920 = cute.add_offset(%int_tuple_822, %72) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,56)">) -> !cute.int_tuple<"(?,?,?,?{div=2})">
      %e0_921, %e1_922, %e2_923, %e3_924 = cute.get_leaves(%tup_920) : !cute.int_tuple<"(?,?,?,?{div=2})">
      %tup_925 = cute.add_offset(%e3_924, %117) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_926 = cute.make_coord(%tup_925) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1151 = cute.get_scalars(%coord_926) : !cute.coord<"?">
      %1152 = arith.cmpi slt, %543, %1151 : i32
      cf.cond_br %1152, ^bb256, ^bb257
    ^bb256:  // pred: ^bb255
      cute.memref.store(%view_796, %71, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,14)">, f32) -> ()
      cf.br ^bb257
    ^bb257:  // 2 preds: ^bb255, ^bb256
      %tup_927 = cute.add_offset(%int_tuple_822, %70) : (!cute.int_tuple<"(?,?,?,?{div=2})">, !cute.int_tuple<"(0,0,0,57)">) -> !cute.int_tuple<"(?,?,?,?)">
      %e0_928, %e1_929, %e2_930, %e3_931 = cute.get_leaves(%tup_927) : !cute.int_tuple<"(?,?,?,?)">
      %tup_932 = cute.add_offset(%e3_931, %117) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_933 = cute.make_coord(%tup_932) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1153 = cute.get_scalars(%coord_933) : !cute.coord<"?">
      %1154 = arith.cmpi slt, %543, %1153 : i32
      cf.cond_br %1154, ^bb258, ^bb259
    ^bb258:  // pred: ^bb257
      cute.memref.store(%view_796, %69, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(0,15)">, f32) -> ()
      cf.br ^bb259
    ^bb259:  // 2 preds: ^bb257, ^bb258
      %view_934 = cute.make_view(%iter_459) : !memref_rmem_f32_4
      %1155 = cute.memref.load_vec %view_934 : !memref_rmem_f32_4
      %1156 = vector.reduction <maximumf>, %1155, %cst_5 : vector<16xf32> into f32
      %1157 = nvvm.shfl.sync  bfly %c-1_i32, %1156, %c2_i32, %c31_i32 : f32 -> f32
      %1158 = nvvm.fmax %1156, %1157
      %1159 = nvvm.shfl.sync  bfly %c-1_i32, %1158, %c1_i32, %c31_i32 : f32 -> f32
      %1160 = nvvm.fmax %1158, %1159
      %1161 = vector.broadcast %arg4 : f32 to vector<16xf32>
      %1162 = arith.mulf %1155, %1161 : vector<16xf32>
      %1163 = arith.mulf %1160, %arg4 : f32
      %1164 = vector.broadcast %1163 : f32 to vector<16xf32>
      %1165 = arith.subf %1162, %1164 : vector<16xf32>
      %1166 = math.exp2 %1165 fastmath<fast> : vector<16xf32>
      %1167 = vector.reduction <add>, %1166, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_456, %68, %1160) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store(%rmem_457, %68, %1167) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store_vec %1166, %view_934 : !memref_rmem_f32_4
      cf.cond_br %1124, ^bb260, ^bb261
    ^bb260:  // pred: ^bb259
      cute.memref.store(%view_796, %67, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,0)">, f32) -> ()
      cf.br ^bb261
    ^bb261:  // 2 preds: ^bb259, ^bb260
      cf.cond_br %1126, ^bb262, ^bb263
    ^bb262:  // pred: ^bb261
      cute.memref.store(%view_796, %66, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,1)">, f32) -> ()
      cf.br ^bb263
    ^bb263:  // 2 preds: ^bb261, ^bb262
      cf.cond_br %1128, ^bb264, ^bb265
    ^bb264:  // pred: ^bb263
      cute.memref.store(%view_796, %65, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,2)">, f32) -> ()
      cf.br ^bb265
    ^bb265:  // 2 preds: ^bb263, ^bb264
      cf.cond_br %1130, ^bb266, ^bb267
    ^bb266:  // pred: ^bb265
      cute.memref.store(%view_796, %64, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,3)">, f32) -> ()
      cf.br ^bb267
    ^bb267:  // 2 preds: ^bb265, ^bb266
      cf.cond_br %1132, ^bb268, ^bb269
    ^bb268:  // pred: ^bb267
      cute.memref.store(%view_796, %63, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,4)">, f32) -> ()
      cf.br ^bb269
    ^bb269:  // 2 preds: ^bb267, ^bb268
      cf.cond_br %1134, ^bb270, ^bb271
    ^bb270:  // pred: ^bb269
      cute.memref.store(%view_796, %62, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,5)">, f32) -> ()
      cf.br ^bb271
    ^bb271:  // 2 preds: ^bb269, ^bb270
      cf.cond_br %1136, ^bb272, ^bb273
    ^bb272:  // pred: ^bb271
      cute.memref.store(%view_796, %61, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,6)">, f32) -> ()
      cf.br ^bb273
    ^bb273:  // 2 preds: ^bb271, ^bb272
      cf.cond_br %1138, ^bb274, ^bb275
    ^bb274:  // pred: ^bb273
      cute.memref.store(%view_796, %60, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,7)">, f32) -> ()
      cf.br ^bb275
    ^bb275:  // 2 preds: ^bb273, ^bb274
      cf.cond_br %1140, ^bb276, ^bb277
    ^bb276:  // pred: ^bb275
      cute.memref.store(%view_796, %59, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,8)">, f32) -> ()
      cf.br ^bb277
    ^bb277:  // 2 preds: ^bb275, ^bb276
      cf.cond_br %1142, ^bb278, ^bb279
    ^bb278:  // pred: ^bb277
      cute.memref.store(%view_796, %58, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,9)">, f32) -> ()
      cf.br ^bb279
    ^bb279:  // 2 preds: ^bb277, ^bb278
      cf.cond_br %1144, ^bb280, ^bb281
    ^bb280:  // pred: ^bb279
      cute.memref.store(%view_796, %57, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,10)">, f32) -> ()
      cf.br ^bb281
    ^bb281:  // 2 preds: ^bb279, ^bb280
      cf.cond_br %1146, ^bb282, ^bb283
    ^bb282:  // pred: ^bb281
      cute.memref.store(%view_796, %56, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,11)">, f32) -> ()
      cf.br ^bb283
    ^bb283:  // 2 preds: ^bb281, ^bb282
      cf.cond_br %1148, ^bb284, ^bb285
    ^bb284:  // pred: ^bb283
      cute.memref.store(%view_796, %55, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,12)">, f32) -> ()
      cf.br ^bb285
    ^bb285:  // 2 preds: ^bb283, ^bb284
      cf.cond_br %1150, ^bb286, ^bb287
    ^bb286:  // pred: ^bb285
      cute.memref.store(%view_796, %54, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,13)">, f32) -> ()
      cf.br ^bb287
    ^bb287:  // 2 preds: ^bb285, ^bb286
      cf.cond_br %1152, ^bb288, ^bb289
    ^bb288:  // pred: ^bb287
      cute.memref.store(%view_796, %53, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,14)">, f32) -> ()
      cf.br ^bb289
    ^bb289:  // 2 preds: ^bb287, ^bb288
      cf.cond_br %1154, ^bb290, ^bb291
    ^bb290:  // pred: ^bb289
      cute.memref.store(%view_796, %52, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(1,15)">, f32) -> ()
      cf.br ^bb291
    ^bb291:  // 2 preds: ^bb289, ^bb290
      %ptr_935 = cute.add_offset(%iter_459, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_936 = cute.make_view(%ptr_935) : !memref_rmem_f32_5
      %1168 = cute.memref.load_vec %view_936 : !memref_rmem_f32_5
      %1169 = vector.reduction <maximumf>, %1168, %cst_5 : vector<16xf32> into f32
      %1170 = nvvm.shfl.sync  bfly %c-1_i32, %1169, %c2_i32, %c31_i32 : f32 -> f32
      %1171 = nvvm.fmax %1169, %1170
      %1172 = nvvm.shfl.sync  bfly %c-1_i32, %1171, %c1_i32, %c31_i32 : f32 -> f32
      %1173 = nvvm.fmax %1171, %1172
      %1174 = arith.mulf %1168, %1161 : vector<16xf32>
      %1175 = arith.mulf %1173, %arg4 : f32
      %1176 = vector.broadcast %1175 : f32 to vector<16xf32>
      %1177 = arith.subf %1174, %1176 : vector<16xf32>
      %1178 = math.exp2 %1177 fastmath<fast> : vector<16xf32>
      %1179 = vector.reduction <add>, %1178, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_456, %51, %1173) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store(%rmem_457, %51, %1179) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store_vec %1178, %view_936 : !memref_rmem_f32_5
      cf.cond_br %1124, ^bb292, ^bb293
    ^bb292:  // pred: ^bb291
      cute.memref.store(%view_796, %50, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,0)">, f32) -> ()
      cf.br ^bb293
    ^bb293:  // 2 preds: ^bb291, ^bb292
      cf.cond_br %1126, ^bb294, ^bb295
    ^bb294:  // pred: ^bb293
      cute.memref.store(%view_796, %49, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,1)">, f32) -> ()
      cf.br ^bb295
    ^bb295:  // 2 preds: ^bb293, ^bb294
      cf.cond_br %1128, ^bb296, ^bb297
    ^bb296:  // pred: ^bb295
      cute.memref.store(%view_796, %48, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,2)">, f32) -> ()
      cf.br ^bb297
    ^bb297:  // 2 preds: ^bb295, ^bb296
      cf.cond_br %1130, ^bb298, ^bb299
    ^bb298:  // pred: ^bb297
      cute.memref.store(%view_796, %47, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,3)">, f32) -> ()
      cf.br ^bb299
    ^bb299:  // 2 preds: ^bb297, ^bb298
      cf.cond_br %1132, ^bb300, ^bb301
    ^bb300:  // pred: ^bb299
      cute.memref.store(%view_796, %46, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,4)">, f32) -> ()
      cf.br ^bb301
    ^bb301:  // 2 preds: ^bb299, ^bb300
      cf.cond_br %1134, ^bb302, ^bb303
    ^bb302:  // pred: ^bb301
      cute.memref.store(%view_796, %45, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,5)">, f32) -> ()
      cf.br ^bb303
    ^bb303:  // 2 preds: ^bb301, ^bb302
      cf.cond_br %1136, ^bb304, ^bb305
    ^bb304:  // pred: ^bb303
      cute.memref.store(%view_796, %44, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,6)">, f32) -> ()
      cf.br ^bb305
    ^bb305:  // 2 preds: ^bb303, ^bb304
      cf.cond_br %1138, ^bb306, ^bb307
    ^bb306:  // pred: ^bb305
      cute.memref.store(%view_796, %43, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,7)">, f32) -> ()
      cf.br ^bb307
    ^bb307:  // 2 preds: ^bb305, ^bb306
      cf.cond_br %1140, ^bb308, ^bb309
    ^bb308:  // pred: ^bb307
      cute.memref.store(%view_796, %42, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,8)">, f32) -> ()
      cf.br ^bb309
    ^bb309:  // 2 preds: ^bb307, ^bb308
      cf.cond_br %1142, ^bb310, ^bb311
    ^bb310:  // pred: ^bb309
      cute.memref.store(%view_796, %41, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,9)">, f32) -> ()
      cf.br ^bb311
    ^bb311:  // 2 preds: ^bb309, ^bb310
      cf.cond_br %1144, ^bb312, ^bb313
    ^bb312:  // pred: ^bb311
      cute.memref.store(%view_796, %40, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,10)">, f32) -> ()
      cf.br ^bb313
    ^bb313:  // 2 preds: ^bb311, ^bb312
      cf.cond_br %1146, ^bb314, ^bb315
    ^bb314:  // pred: ^bb313
      cute.memref.store(%view_796, %39, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,11)">, f32) -> ()
      cf.br ^bb315
    ^bb315:  // 2 preds: ^bb313, ^bb314
      cf.cond_br %1148, ^bb316, ^bb317
    ^bb316:  // pred: ^bb315
      cute.memref.store(%view_796, %38, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,12)">, f32) -> ()
      cf.br ^bb317
    ^bb317:  // 2 preds: ^bb315, ^bb316
      cf.cond_br %1150, ^bb318, ^bb319
    ^bb318:  // pred: ^bb317
      cute.memref.store(%view_796, %37, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,13)">, f32) -> ()
      cf.br ^bb319
    ^bb319:  // 2 preds: ^bb317, ^bb318
      cf.cond_br %1152, ^bb320, ^bb321
    ^bb320:  // pred: ^bb319
      cute.memref.store(%view_796, %36, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,14)">, f32) -> ()
      cf.br ^bb321
    ^bb321:  // 2 preds: ^bb319, ^bb320
      cf.cond_br %1154, ^bb322, ^bb323
    ^bb322:  // pred: ^bb321
      cute.memref.store(%view_796, %35, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(2,15)">, f32) -> ()
      cf.br ^bb323
    ^bb323:  // 2 preds: ^bb321, ^bb322
      %ptr_937 = cute.add_offset(%iter_459, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_938 = cute.make_view(%ptr_937) : !memref_rmem_f32_6
      %1180 = cute.memref.load_vec %view_938 : !memref_rmem_f32_6
      %1181 = vector.reduction <maximumf>, %1180, %cst_5 : vector<16xf32> into f32
      %1182 = nvvm.shfl.sync  bfly %c-1_i32, %1181, %c2_i32, %c31_i32 : f32 -> f32
      %1183 = nvvm.fmax %1181, %1182
      %1184 = nvvm.shfl.sync  bfly %c-1_i32, %1183, %c1_i32, %c31_i32 : f32 -> f32
      %1185 = nvvm.fmax %1183, %1184
      %1186 = arith.mulf %1180, %1161 : vector<16xf32>
      %1187 = arith.mulf %1185, %arg4 : f32
      %1188 = vector.broadcast %1187 : f32 to vector<16xf32>
      %1189 = arith.subf %1186, %1188 : vector<16xf32>
      %1190 = math.exp2 %1189 fastmath<fast> : vector<16xf32>
      %1191 = vector.reduction <add>, %1190, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_456, %34, %1185) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store(%rmem_457, %34, %1191) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store_vec %1190, %view_938 : !memref_rmem_f32_6
      cf.cond_br %1124, ^bb324, ^bb325
    ^bb324:  // pred: ^bb323
      cute.memref.store(%view_796, %33, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,0)">, f32) -> ()
      cf.br ^bb325
    ^bb325:  // 2 preds: ^bb323, ^bb324
      cf.cond_br %1126, ^bb326, ^bb327
    ^bb326:  // pred: ^bb325
      cute.memref.store(%view_796, %32, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,1)">, f32) -> ()
      cf.br ^bb327
    ^bb327:  // 2 preds: ^bb325, ^bb326
      cf.cond_br %1128, ^bb328, ^bb329
    ^bb328:  // pred: ^bb327
      cute.memref.store(%view_796, %31, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,2)">, f32) -> ()
      cf.br ^bb329
    ^bb329:  // 2 preds: ^bb327, ^bb328
      cf.cond_br %1130, ^bb330, ^bb331
    ^bb330:  // pred: ^bb329
      cute.memref.store(%view_796, %30, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,3)">, f32) -> ()
      cf.br ^bb331
    ^bb331:  // 2 preds: ^bb329, ^bb330
      cf.cond_br %1132, ^bb332, ^bb333
    ^bb332:  // pred: ^bb331
      cute.memref.store(%view_796, %29, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,4)">, f32) -> ()
      cf.br ^bb333
    ^bb333:  // 2 preds: ^bb331, ^bb332
      cf.cond_br %1134, ^bb334, ^bb335
    ^bb334:  // pred: ^bb333
      cute.memref.store(%view_796, %28, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,5)">, f32) -> ()
      cf.br ^bb335
    ^bb335:  // 2 preds: ^bb333, ^bb334
      cf.cond_br %1136, ^bb336, ^bb337
    ^bb336:  // pred: ^bb335
      cute.memref.store(%view_796, %27, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,6)">, f32) -> ()
      cf.br ^bb337
    ^bb337:  // 2 preds: ^bb335, ^bb336
      cf.cond_br %1138, ^bb338, ^bb339
    ^bb338:  // pred: ^bb337
      cute.memref.store(%view_796, %26, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,7)">, f32) -> ()
      cf.br ^bb339
    ^bb339:  // 2 preds: ^bb337, ^bb338
      cf.cond_br %1140, ^bb340, ^bb341
    ^bb340:  // pred: ^bb339
      cute.memref.store(%view_796, %25, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,8)">, f32) -> ()
      cf.br ^bb341
    ^bb341:  // 2 preds: ^bb339, ^bb340
      cf.cond_br %1142, ^bb342, ^bb343
    ^bb342:  // pred: ^bb341
      cute.memref.store(%view_796, %24, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,9)">, f32) -> ()
      cf.br ^bb343
    ^bb343:  // 2 preds: ^bb341, ^bb342
      cf.cond_br %1144, ^bb344, ^bb345
    ^bb344:  // pred: ^bb343
      cute.memref.store(%view_796, %23, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,10)">, f32) -> ()
      cf.br ^bb345
    ^bb345:  // 2 preds: ^bb343, ^bb344
      cf.cond_br %1146, ^bb346, ^bb347
    ^bb346:  // pred: ^bb345
      cute.memref.store(%view_796, %22, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,11)">, f32) -> ()
      cf.br ^bb347
    ^bb347:  // 2 preds: ^bb345, ^bb346
      cf.cond_br %1148, ^bb348, ^bb349
    ^bb348:  // pred: ^bb347
      cute.memref.store(%view_796, %21, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,12)">, f32) -> ()
      cf.br ^bb349
    ^bb349:  // 2 preds: ^bb347, ^bb348
      cf.cond_br %1150, ^bb350, ^bb351
    ^bb350:  // pred: ^bb349
      cute.memref.store(%view_796, %20, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,13)">, f32) -> ()
      cf.br ^bb351
    ^bb351:  // 2 preds: ^bb349, ^bb350
      cf.cond_br %1152, ^bb352, ^bb353
    ^bb352:  // pred: ^bb351
      cute.memref.store(%view_796, %19, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,14)">, f32) -> ()
      cf.br ^bb353
    ^bb353:  // 2 preds: ^bb351, ^bb352
      cf.cond_br %1154, ^bb354, ^bb355
    ^bb354:  // pred: ^bb353
      cute.memref.store(%view_796, %18, %cst_5) : (!memref_rmem_f32_3, !cute.coord<"(3,15)">, f32) -> ()
      cf.br ^bb355
    ^bb355:  // 2 preds: ^bb353, ^bb354
      %ptr_939 = cute.add_offset(%iter_459, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_940 = cute.make_view(%ptr_939) : !memref_rmem_f32_5
      %1192 = cute.memref.load_vec %view_940 : !memref_rmem_f32_5
      %1193 = vector.reduction <maximumf>, %1192, %cst_5 : vector<16xf32> into f32
      %1194 = nvvm.shfl.sync  bfly %c-1_i32, %1193, %c2_i32, %c31_i32 : f32 -> f32
      %1195 = nvvm.fmax %1193, %1194
      %1196 = nvvm.shfl.sync  bfly %c-1_i32, %1195, %c1_i32, %c31_i32 : f32 -> f32
      %1197 = nvvm.fmax %1195, %1196
      %1198 = arith.mulf %1192, %1161 : vector<16xf32>
      %1199 = arith.mulf %1197, %arg4 : f32
      %1200 = vector.broadcast %1199 : f32 to vector<16xf32>
      %1201 = arith.subf %1198, %1200 : vector<16xf32>
      %1202 = math.exp2 %1201 fastmath<fast> : vector<16xf32>
      %1203 = vector.reduction <add>, %1202, %cst_6 : vector<16xf32> into f32
      cute.memref.store(%rmem_456, %17, %1197) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store(%rmem_457, %17, %1203) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store_vec %1202, %view_940 : !memref_rmem_f32_5
      %rmem_941 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_942 = cute.get_iter(%rmem_941) : !memref_rmem_bf16_3
      %1204 = cute.memref.load_vec %rmem_458 : !memref_rmem_f32_2
      %1205 = arith.truncf %1204 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1205, %rmem_941 : !memref_rmem_bf16_3
      %1206:2 = cute.get_scalars(%lay_140) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iv_943 = cute.assume(%1206#0) : (i32) -> !cute.i32<divby 16>
      %iv_944 = cute.assume(%1206#1) : (i32) -> !cute.i32<divby 32>
      %stride_945 = cute.make_stride(%iv_943, %iv_944) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_946 = cute.make_layout(%16, %stride_945) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %append_947 = cute.append_to_rank<2> (%lay_946, %181) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %1207:2 = cute.get_scalars(%append_947) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %iv_948 = cute.assume(%1207#0) : (i32) -> !cute.i32<divby 16>
      %iv_949 = cute.assume(%1207#1) : (i32) -> !cute.i32<divby 32>
      %stride_950 = cute.make_stride(%iv_948, %iv_949) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_951 = cute.make_layout(%15, %stride_950) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %append_952 = cute.append_to_rank<2> (%lay_951, %181) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %1208:2 = cute.get_scalars(%append_952) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %iv_953 = cute.assume(%1208#0) : (i32) -> !cute.i32<divby 16>
      %iv_954 = cute.assume(%1208#1) : (i32) -> !cute.i32<divby 32>
      %stride_955 = cute.make_stride(%iv_953, %iv_954) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_956 = cute.make_layout(%14, %stride_955) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      cf.br ^bb356(%c0_i32 : i32)
    ^bb356(%1209: i32):  // 2 preds: ^bb355, ^bb357
      %1210 = arith.cmpi slt, %1209, %658 : i32
      cf.cond_br %1210, ^bb357, ^bb358 {llvm.loop_annotation = #loop_annotation}
    ^bb357:  // pred: ^bb356
      %coord_957 = cute.make_coord(%1209) : (i32) -> !cute.coord<"(_,?)">
      %idx_958 = cute.crd2idx(%coord_957, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_959 = cute.add_offset(%ptr_138, %idx_958) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_960 = cute.crd2idx(%coord_957, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_961 = cute.add_offset(%iter_141, %idx_960) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1211 = cute_nvgpu.arch.copy.ldsm %ptr_959{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1212 = vector.extractelement %1211[%130 : i32] : vector<4xi32>
      %1213 = builtin.unrealized_conversion_cast %ptr_961 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1212, %1213 : i32, !llvm.ptr
      %1214 = vector.extractelement %1211[%129 : i32] : vector<4xi32>
      %ptr_962 = cute.add_offset(%ptr_961, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1215 = builtin.unrealized_conversion_cast %ptr_962 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1214, %1215 : i32, !llvm.ptr
      %1216 = vector.extractelement %1211[%128 : i32] : vector<4xi32>
      %ptr_963 = cute.add_offset(%ptr_961, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1217 = builtin.unrealized_conversion_cast %ptr_963 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1216, %1217 : i32, !llvm.ptr
      %1218 = vector.extractelement %1211[%126 : i32] : vector<4xi32>
      %ptr_964 = cute.add_offset(%ptr_961, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1219 = builtin.unrealized_conversion_cast %ptr_964 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1218, %1219 : i32, !llvm.ptr
      %1220 = arith.addi %1209, %c1_i32 : i32
      cf.br ^bb356(%1220 : i32)
    ^bb358:  // pred: ^bb356
      %ptr_965 = cute.add_offset(%ptr_138, %158) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_966 = cute.add_offset(%iter_141, %121) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb359(%c0_i32 : i32)
    ^bb359(%1221: i32):  // 2 preds: ^bb358, ^bb360
      %1222 = arith.cmpi slt, %1221, %658 : i32
      cf.cond_br %1222, ^bb360, ^bb361 {llvm.loop_annotation = #loop_annotation}
    ^bb360:  // pred: ^bb359
      %coord_967 = cute.make_coord(%1221) : (i32) -> !cute.coord<"(_,?)">
      %idx_968 = cute.crd2idx(%coord_967, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_969 = cute.add_offset(%ptr_965, %idx_968) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_970 = cute.crd2idx(%coord_967, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_971 = cute.add_offset(%ptr_966, %idx_970) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1223 = cute_nvgpu.arch.copy.ldsm %ptr_969{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1224 = vector.extractelement %1223[%130 : i32] : vector<4xi32>
      %1225 = builtin.unrealized_conversion_cast %ptr_971 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1224, %1225 : i32, !llvm.ptr
      %1226 = vector.extractelement %1223[%129 : i32] : vector<4xi32>
      %ptr_972 = cute.add_offset(%ptr_971, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1227 = builtin.unrealized_conversion_cast %ptr_972 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1226, %1227 : i32, !llvm.ptr
      %1228 = vector.extractelement %1223[%128 : i32] : vector<4xi32>
      %ptr_973 = cute.add_offset(%ptr_971, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1229 = builtin.unrealized_conversion_cast %ptr_973 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1228, %1229 : i32, !llvm.ptr
      %1230 = vector.extractelement %1223[%126 : i32] : vector<4xi32>
      %ptr_974 = cute.add_offset(%ptr_971, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1231 = builtin.unrealized_conversion_cast %ptr_974 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1230, %1231 : i32, !llvm.ptr
      %1232 = arith.addi %1221, %c1_i32 : i32
      cf.br ^bb359(%1232 : i32)
    ^bb361:  // pred: ^bb359
      %1233 = cute.get_scalars(%110) : !cute.int_tuple<"16">
      cf.br ^bb362(%c0_i32 : i32)
    ^bb362(%1234: i32):  // 2 preds: ^bb361, ^bb369
      %1235 = arith.cmpi slt, %1234, %657 : i32
      cf.cond_br %1235, ^bb363, ^bb370 {llvm.loop_annotation = #loop_annotation}
    ^bb363:  // pred: ^bb362
      cf.br ^bb364(%c0_i32 : i32)
    ^bb364(%1236: i32):  // 2 preds: ^bb363, ^bb368
      %1237 = arith.cmpi slt, %1236, %607 : i32
      cf.cond_br %1237, ^bb365, ^bb369 {llvm.loop_annotation = #loop_annotation}
    ^bb365:  // pred: ^bb364
      %coord_975 = cute.make_coord(%1236, %1234) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_976 = cute.crd2idx(%coord_975, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_977 = cute.add_offset(%iter_942, %idx_976) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1238 = builtin.unrealized_conversion_cast %ptr_977 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1239 = llvm.getelementptr %1238[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1240 = llvm.getelementptr %1238[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1241 = llvm.getelementptr %1238[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb366(%c0_i32 : i32)
    ^bb366(%1242: i32):  // 2 preds: ^bb365, ^bb367
      %1243 = arith.cmpi slt, %1242, %1233 : i32
      cf.cond_br %1243, ^bb367, ^bb368 {llvm.loop_annotation = #loop_annotation}
    ^bb367:  // pred: ^bb366
      %coord_978 = cute.make_coord(%1242, %1234) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_979 = cute.make_coord(%1236, %1242) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_980 = cute.crd2idx(%coord_978, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_981 = cute.add_offset(%iter_141, %idx_980) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_982 = cute.crd2idx(%coord_979, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_983 = cute.add_offset(%iter_118, %idx_982) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1244 = llvm.load %1238 : !llvm.ptr -> i32
      %1245 = llvm.load %1239 : !llvm.ptr -> i32
      %1246 = llvm.load %1240 : !llvm.ptr -> i32
      %1247 = llvm.load %1241 : !llvm.ptr -> i32
      %1248 = builtin.unrealized_conversion_cast %ptr_981 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1249 = llvm.load %1248 : !llvm.ptr -> i32
      %1250 = llvm.getelementptr %1248[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1251 = llvm.load %1250 : !llvm.ptr -> i32
      %1252 = builtin.unrealized_conversion_cast %ptr_983 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1253 = llvm.load %1252 : !llvm.ptr -> f32
      %1254 = llvm.getelementptr %1252[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1255 = llvm.load %1254 : !llvm.ptr -> f32
      %1256 = llvm.getelementptr %1252[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1257 = llvm.load %1256 : !llvm.ptr -> f32
      %1258 = llvm.getelementptr %1252[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1259 = llvm.load %1258 : !llvm.ptr -> f32
      %1260:4 = cute_nvgpu.arch.mma.SM80 A[%1244, %1245, %1246, %1247]  B[%1249, %1251]  C[%1253, %1255, %1257, %1259] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1260#0, %1252 : f32, !llvm.ptr
      llvm.store %1260#1, %1254 : f32, !llvm.ptr
      llvm.store %1260#2, %1256 : f32, !llvm.ptr
      llvm.store %1260#3, %1258 : f32, !llvm.ptr
      %1261 = arith.addi %1242, %c1_i32 : i32
      cf.br ^bb366(%1261 : i32)
    ^bb368:  // pred: ^bb366
      %1262 = arith.addi %1236, %c1_i32 : i32
      cf.br ^bb364(%1262 : i32)
    ^bb369:  // pred: ^bb364
      %1263 = arith.addi %1234, %c1_i32 : i32
      cf.br ^bb362(%1263 : i32)
    ^bb370:  // pred: ^bb362
      %ptr_984 = cute.add_offset(%ptr_138, %155) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_985 = cute.add_offset(%iter_141, %120) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb371(%c0_i32 : i32)
    ^bb371(%1264: i32):  // 2 preds: ^bb370, ^bb372
      %1265 = arith.cmpi slt, %1264, %658 : i32
      cf.cond_br %1265, ^bb372, ^bb373 {llvm.loop_annotation = #loop_annotation}
    ^bb372:  // pred: ^bb371
      %coord_986 = cute.make_coord(%1264) : (i32) -> !cute.coord<"(_,?)">
      %idx_987 = cute.crd2idx(%coord_986, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_988 = cute.add_offset(%ptr_984, %idx_987) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_989 = cute.crd2idx(%coord_986, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_990 = cute.add_offset(%ptr_985, %idx_989) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1266 = cute_nvgpu.arch.copy.ldsm %ptr_988{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1267 = vector.extractelement %1266[%130 : i32] : vector<4xi32>
      %1268 = builtin.unrealized_conversion_cast %ptr_990 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1267, %1268 : i32, !llvm.ptr
      %1269 = vector.extractelement %1266[%129 : i32] : vector<4xi32>
      %ptr_991 = cute.add_offset(%ptr_990, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1270 = builtin.unrealized_conversion_cast %ptr_991 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1269, %1270 : i32, !llvm.ptr
      %1271 = vector.extractelement %1266[%128 : i32] : vector<4xi32>
      %ptr_992 = cute.add_offset(%ptr_990, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1272 = builtin.unrealized_conversion_cast %ptr_992 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1271, %1272 : i32, !llvm.ptr
      %1273 = vector.extractelement %1266[%126 : i32] : vector<4xi32>
      %ptr_993 = cute.add_offset(%ptr_990, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1274 = builtin.unrealized_conversion_cast %ptr_993 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1273, %1274 : i32, !llvm.ptr
      %1275 = arith.addi %1264, %c1_i32 : i32
      cf.br ^bb371(%1275 : i32)
    ^bb373:  // pred: ^bb371
      %ptr_994 = cute.add_offset(%iter_942, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb374(%c0_i32 : i32)
    ^bb374(%1276: i32):  // 2 preds: ^bb373, ^bb381
      %1277 = arith.cmpi slt, %1276, %657 : i32
      cf.cond_br %1277, ^bb375, ^bb382 {llvm.loop_annotation = #loop_annotation}
    ^bb375:  // pred: ^bb374
      cf.br ^bb376(%c0_i32 : i32)
    ^bb376(%1278: i32):  // 2 preds: ^bb375, ^bb380
      %1279 = arith.cmpi slt, %1278, %607 : i32
      cf.cond_br %1279, ^bb377, ^bb381 {llvm.loop_annotation = #loop_annotation}
    ^bb377:  // pred: ^bb376
      %coord_995 = cute.make_coord(%1278, %1276) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_996 = cute.crd2idx(%coord_995, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_997 = cute.add_offset(%ptr_994, %idx_996) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1280 = builtin.unrealized_conversion_cast %ptr_997 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1281 = llvm.getelementptr %1280[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1282 = llvm.getelementptr %1280[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1283 = llvm.getelementptr %1280[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb378(%c0_i32 : i32)
    ^bb378(%1284: i32):  // 2 preds: ^bb377, ^bb379
      %1285 = arith.cmpi slt, %1284, %1233 : i32
      cf.cond_br %1285, ^bb379, ^bb380 {llvm.loop_annotation = #loop_annotation}
    ^bb379:  // pred: ^bb378
      %coord_998 = cute.make_coord(%1284, %1276) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_999 = cute.make_coord(%1278, %1284) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1000 = cute.crd2idx(%coord_998, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1001 = cute.add_offset(%ptr_966, %idx_1000) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1002 = cute.crd2idx(%coord_999, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1003 = cute.add_offset(%iter_118, %idx_1002) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1286 = llvm.load %1280 : !llvm.ptr -> i32
      %1287 = llvm.load %1281 : !llvm.ptr -> i32
      %1288 = llvm.load %1282 : !llvm.ptr -> i32
      %1289 = llvm.load %1283 : !llvm.ptr -> i32
      %1290 = builtin.unrealized_conversion_cast %ptr_1001 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1291 = llvm.load %1290 : !llvm.ptr -> i32
      %1292 = llvm.getelementptr %1290[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1293 = llvm.load %1292 : !llvm.ptr -> i32
      %1294 = builtin.unrealized_conversion_cast %ptr_1003 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1295 = llvm.load %1294 : !llvm.ptr -> f32
      %1296 = llvm.getelementptr %1294[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1297 = llvm.load %1296 : !llvm.ptr -> f32
      %1298 = llvm.getelementptr %1294[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1299 = llvm.load %1298 : !llvm.ptr -> f32
      %1300 = llvm.getelementptr %1294[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1301 = llvm.load %1300 : !llvm.ptr -> f32
      %1302:4 = cute_nvgpu.arch.mma.SM80 A[%1286, %1287, %1288, %1289]  B[%1291, %1293]  C[%1295, %1297, %1299, %1301] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1302#0, %1294 : f32, !llvm.ptr
      llvm.store %1302#1, %1296 : f32, !llvm.ptr
      llvm.store %1302#2, %1298 : f32, !llvm.ptr
      llvm.store %1302#3, %1300 : f32, !llvm.ptr
      %1303 = arith.addi %1284, %c1_i32 : i32
      cf.br ^bb378(%1303 : i32)
    ^bb380:  // pred: ^bb378
      %1304 = arith.addi %1278, %c1_i32 : i32
      cf.br ^bb376(%1304 : i32)
    ^bb381:  // pred: ^bb376
      %1305 = arith.addi %1276, %c1_i32 : i32
      cf.br ^bb374(%1305 : i32)
    ^bb382:  // pred: ^bb374
      %ptr_1004 = cute.add_offset(%ptr_138, %152) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_1005 = cute.add_offset(%iter_141, %113) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb383(%c0_i32 : i32)
    ^bb383(%1306: i32):  // 2 preds: ^bb382, ^bb384
      %1307 = arith.cmpi slt, %1306, %658 : i32
      cf.cond_br %1307, ^bb384, ^bb385 {llvm.loop_annotation = #loop_annotation}
    ^bb384:  // pred: ^bb383
      %coord_1006 = cute.make_coord(%1306) : (i32) -> !cute.coord<"(_,?)">
      %idx_1007 = cute.crd2idx(%coord_1006, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1008 = cute.add_offset(%ptr_1004, %idx_1007) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1009 = cute.crd2idx(%coord_1006, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1010 = cute.add_offset(%ptr_1005, %idx_1009) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1308 = cute_nvgpu.arch.copy.ldsm %ptr_1008{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1309 = vector.extractelement %1308[%130 : i32] : vector<4xi32>
      %1310 = builtin.unrealized_conversion_cast %ptr_1010 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1309, %1310 : i32, !llvm.ptr
      %1311 = vector.extractelement %1308[%129 : i32] : vector<4xi32>
      %ptr_1011 = cute.add_offset(%ptr_1010, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1312 = builtin.unrealized_conversion_cast %ptr_1011 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1311, %1312 : i32, !llvm.ptr
      %1313 = vector.extractelement %1308[%128 : i32] : vector<4xi32>
      %ptr_1012 = cute.add_offset(%ptr_1010, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1314 = builtin.unrealized_conversion_cast %ptr_1012 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1313, %1314 : i32, !llvm.ptr
      %1315 = vector.extractelement %1308[%126 : i32] : vector<4xi32>
      %ptr_1013 = cute.add_offset(%ptr_1010, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1316 = builtin.unrealized_conversion_cast %ptr_1013 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1315, %1316 : i32, !llvm.ptr
      %1317 = arith.addi %1306, %c1_i32 : i32
      cf.br ^bb383(%1317 : i32)
    ^bb385:  // pred: ^bb383
      %ptr_1014 = cute.add_offset(%iter_942, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb386(%c0_i32 : i32)
    ^bb386(%1318: i32):  // 2 preds: ^bb385, ^bb393
      %1319 = arith.cmpi slt, %1318, %657 : i32
      cf.cond_br %1319, ^bb387, ^bb394 {llvm.loop_annotation = #loop_annotation}
    ^bb387:  // pred: ^bb386
      cf.br ^bb388(%c0_i32 : i32)
    ^bb388(%1320: i32):  // 2 preds: ^bb387, ^bb392
      %1321 = arith.cmpi slt, %1320, %607 : i32
      cf.cond_br %1321, ^bb389, ^bb393 {llvm.loop_annotation = #loop_annotation}
    ^bb389:  // pred: ^bb388
      %coord_1015 = cute.make_coord(%1320, %1318) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1016 = cute.crd2idx(%coord_1015, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1017 = cute.add_offset(%ptr_1014, %idx_1016) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1322 = builtin.unrealized_conversion_cast %ptr_1017 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1323 = llvm.getelementptr %1322[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1324 = llvm.getelementptr %1322[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1325 = llvm.getelementptr %1322[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb390(%c0_i32 : i32)
    ^bb390(%1326: i32):  // 2 preds: ^bb389, ^bb391
      %1327 = arith.cmpi slt, %1326, %1233 : i32
      cf.cond_br %1327, ^bb391, ^bb392 {llvm.loop_annotation = #loop_annotation}
    ^bb391:  // pred: ^bb390
      %coord_1018 = cute.make_coord(%1326, %1318) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1019 = cute.make_coord(%1320, %1326) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1020 = cute.crd2idx(%coord_1018, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1021 = cute.add_offset(%ptr_985, %idx_1020) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1022 = cute.crd2idx(%coord_1019, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1023 = cute.add_offset(%iter_118, %idx_1022) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1328 = llvm.load %1322 : !llvm.ptr -> i32
      %1329 = llvm.load %1323 : !llvm.ptr -> i32
      %1330 = llvm.load %1324 : !llvm.ptr -> i32
      %1331 = llvm.load %1325 : !llvm.ptr -> i32
      %1332 = builtin.unrealized_conversion_cast %ptr_1021 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1333 = llvm.load %1332 : !llvm.ptr -> i32
      %1334 = llvm.getelementptr %1332[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1335 = llvm.load %1334 : !llvm.ptr -> i32
      %1336 = builtin.unrealized_conversion_cast %ptr_1023 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1337 = llvm.load %1336 : !llvm.ptr -> f32
      %1338 = llvm.getelementptr %1336[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1339 = llvm.load %1338 : !llvm.ptr -> f32
      %1340 = llvm.getelementptr %1336[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1341 = llvm.load %1340 : !llvm.ptr -> f32
      %1342 = llvm.getelementptr %1336[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1343 = llvm.load %1342 : !llvm.ptr -> f32
      %1344:4 = cute_nvgpu.arch.mma.SM80 A[%1328, %1329, %1330, %1331]  B[%1333, %1335]  C[%1337, %1339, %1341, %1343] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1344#0, %1336 : f32, !llvm.ptr
      llvm.store %1344#1, %1338 : f32, !llvm.ptr
      llvm.store %1344#2, %1340 : f32, !llvm.ptr
      llvm.store %1344#3, %1342 : f32, !llvm.ptr
      %1345 = arith.addi %1326, %c1_i32 : i32
      cf.br ^bb390(%1345 : i32)
    ^bb392:  // pred: ^bb390
      %1346 = arith.addi %1320, %c1_i32 : i32
      cf.br ^bb388(%1346 : i32)
    ^bb393:  // pred: ^bb388
      %1347 = arith.addi %1318, %c1_i32 : i32
      cf.br ^bb386(%1347 : i32)
    ^bb394:  // pred: ^bb386
      cf.br ^bb395(%c0_i32 : i32)
    ^bb395(%1348: i32):  // 2 preds: ^bb394, ^bb396
      %1349 = arith.cmpi slt, %1348, %658 : i32
      cf.cond_br %1349, ^bb396, ^bb397 {llvm.loop_annotation = #loop_annotation}
    ^bb396:  // pred: ^bb395
      %coord_1024 = cute.make_coord(%1348) : (i32) -> !cute.coord<"(_,?)">
      %idx_1025 = cute.crd2idx(%coord_1024, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1026 = cute.add_offset(%ptr_138, %idx_1025) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1027 = cute.crd2idx(%coord_1024, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1028 = cute.add_offset(%iter_141, %idx_1027) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1350 = cute_nvgpu.arch.copy.ldsm %ptr_1026{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1351 = vector.extractelement %1350[%130 : i32] : vector<4xi32>
      %1352 = builtin.unrealized_conversion_cast %ptr_1028 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1351, %1352 : i32, !llvm.ptr
      %1353 = vector.extractelement %1350[%129 : i32] : vector<4xi32>
      %ptr_1029 = cute.add_offset(%ptr_1028, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1354 = builtin.unrealized_conversion_cast %ptr_1029 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1353, %1354 : i32, !llvm.ptr
      %1355 = vector.extractelement %1350[%128 : i32] : vector<4xi32>
      %ptr_1030 = cute.add_offset(%ptr_1028, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1356 = builtin.unrealized_conversion_cast %ptr_1030 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1355, %1356 : i32, !llvm.ptr
      %1357 = vector.extractelement %1350[%126 : i32] : vector<4xi32>
      %ptr_1031 = cute.add_offset(%ptr_1028, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1358 = builtin.unrealized_conversion_cast %ptr_1031 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1357, %1358 : i32, !llvm.ptr
      %1359 = arith.addi %1348, %c1_i32 : i32
      cf.br ^bb395(%1359 : i32)
    ^bb397:  // pred: ^bb395
      %ptr_1032 = cute.add_offset(%iter_942, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb398(%c0_i32 : i32)
    ^bb398(%1360: i32):  // 2 preds: ^bb397, ^bb405
      %1361 = arith.cmpi slt, %1360, %657 : i32
      cf.cond_br %1361, ^bb399, ^bb406 {llvm.loop_annotation = #loop_annotation}
    ^bb399:  // pred: ^bb398
      cf.br ^bb400(%c0_i32 : i32)
    ^bb400(%1362: i32):  // 2 preds: ^bb399, ^bb404
      %1363 = arith.cmpi slt, %1362, %607 : i32
      cf.cond_br %1363, ^bb401, ^bb405 {llvm.loop_annotation = #loop_annotation}
    ^bb401:  // pred: ^bb400
      %coord_1033 = cute.make_coord(%1362, %1360) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1034 = cute.crd2idx(%coord_1033, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1035 = cute.add_offset(%ptr_1032, %idx_1034) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1364 = builtin.unrealized_conversion_cast %ptr_1035 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1365 = llvm.getelementptr %1364[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1366 = llvm.getelementptr %1364[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %1367 = llvm.getelementptr %1364[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb402(%c0_i32 : i32)
    ^bb402(%1368: i32):  // 2 preds: ^bb401, ^bb403
      %1369 = arith.cmpi slt, %1368, %1233 : i32
      cf.cond_br %1369, ^bb403, ^bb404 {llvm.loop_annotation = #loop_annotation}
    ^bb403:  // pred: ^bb402
      %coord_1036 = cute.make_coord(%1368, %1360) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1037 = cute.make_coord(%1362, %1368) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1038 = cute.crd2idx(%coord_1036, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1039 = cute.add_offset(%ptr_1005, %idx_1038) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1040 = cute.crd2idx(%coord_1037, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1041 = cute.add_offset(%iter_118, %idx_1040) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1370 = llvm.load %1364 : !llvm.ptr -> i32
      %1371 = llvm.load %1365 : !llvm.ptr -> i32
      %1372 = llvm.load %1366 : !llvm.ptr -> i32
      %1373 = llvm.load %1367 : !llvm.ptr -> i32
      %1374 = builtin.unrealized_conversion_cast %ptr_1039 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1375 = llvm.load %1374 : !llvm.ptr -> i32
      %1376 = llvm.getelementptr %1374[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1377 = llvm.load %1376 : !llvm.ptr -> i32
      %1378 = builtin.unrealized_conversion_cast %ptr_1041 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1379 = llvm.load %1378 : !llvm.ptr -> f32
      %1380 = llvm.getelementptr %1378[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1381 = llvm.load %1380 : !llvm.ptr -> f32
      %1382 = llvm.getelementptr %1378[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1383 = llvm.load %1382 : !llvm.ptr -> f32
      %1384 = llvm.getelementptr %1378[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1385 = llvm.load %1384 : !llvm.ptr -> f32
      %1386:4 = cute_nvgpu.arch.mma.SM80 A[%1370, %1371, %1372, %1373]  B[%1375, %1377]  C[%1379, %1381, %1383, %1385] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1386#0, %1378 : f32, !llvm.ptr
      llvm.store %1386#1, %1380 : f32, !llvm.ptr
      llvm.store %1386#2, %1382 : f32, !llvm.ptr
      llvm.store %1386#3, %1384 : f32, !llvm.ptr
      %1387 = arith.addi %1368, %c1_i32 : i32
      cf.br ^bb402(%1387 : i32)
    ^bb404:  // pred: ^bb402
      %1388 = arith.addi %1362, %c1_i32 : i32
      cf.br ^bb400(%1388 : i32)
    ^bb405:  // pred: ^bb400
      %1389 = arith.addi %1360, %c1_i32 : i32
      cf.br ^bb398(%1389 : i32)
    ^bb406:  // pred: ^bb398
      %1390:3 = cute.get_scalars(%lay_113) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_1042 = cute.assume(%1390#1) : (i64) -> !cute.i64<divby 128>
      %stride_1043 = cute.make_stride(%iv_1042) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1044 = cute.make_layout(%137, %stride_1043) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %append_1045 = cute.append_to_rank<2> (%lay_1044, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1391 = cute.get_scalars(%append_1045) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_1046 = cute.assume(%1391) : (i64) -> !cute.i64<divby 128>
      %stride_1047 = cute.make_stride(%iv_1046) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_1048 = cute.make_layout(%136, %stride_1047) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_1049 = cute.append_to_rank<2> (%lay_1048, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1392 = cute.get_scalars(%append_1049) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_1050 = cute.assume(%1392) : (i64) -> !cute.i64<divby 128>
      %stride_1051 = cute.make_stride(%iv_1050) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_1052 = cute.make_layout(%135, %stride_1051) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      %iter_1053 = cute.get_iter(%rmem_456) : !memref_rmem_f32_1
      %1393 = builtin.unrealized_conversion_cast %iter_1053 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_1054 = cute.add_offset(%iter_1053, %117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %1394 = builtin.unrealized_conversion_cast %ptr_1054 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_1055 = cute.add_offset(%iter_1053, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %1395 = builtin.unrealized_conversion_cast %ptr_1055 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_1056 = cute.add_offset(%iter_1053, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %1396 = builtin.unrealized_conversion_cast %ptr_1056 : !cute.ptr<f32, rmem> to !llvm.ptr
      %view_1057 = cute.make_view(%iter_118) : !memref_rmem_f32_7
      %ptr_1058 = cute.add_offset(%iter_118, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1059 = cute.make_view(%ptr_1058) : !memref_rmem_f32_8
      %ptr_1060 = cute.add_offset(%iter_118, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1061 = cute.make_view(%ptr_1060) : !memref_rmem_f32_9
      %ptr_1062 = cute.add_offset(%iter_118, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1063 = cute.make_view(%ptr_1062) : !memref_rmem_f32_8
      cf.br ^bb407(%c1_i32 : i32)
    ^bb407(%1397: i32):  // 2 preds: ^bb406, ^bb596
      %1398 = arith.cmpi slt, %1397, %204 : i32
      cf.cond_br %1398, ^bb408, ^bb597
    ^bb408:  // pred: ^bb407
      %1399 = arith.subi %204, %1397 : i32
      %1400 = arith.subi %1399, %c1_i32 : i32
      %rmem_1064 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_1065 = cute.get_iter(%rmem_1064) : !memref_rmem_f32_2
      cute.memref.store_vec %cst, %rmem_1064 : !memref_rmem_f32_2
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %coord_1066 = cute.make_coord(%1400) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_1067 = cute.crd2idx(%coord_1066, %lay_113) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1068 = cute.add_offset(%ptr_108, %idx_1067) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      cf.br ^bb409(%c0_i32 : i32)
    ^bb409(%1401: i32):  // 2 preds: ^bb408, ^bb410
      %1402 = arith.cmpi slt, %1401, %658 : i32
      cf.cond_br %1402, ^bb410, ^bb411 {llvm.loop_annotation = #loop_annotation}
    ^bb410:  // pred: ^bb409
      %coord_1069 = cute.make_coord(%1401) : (i32) -> !cute.coord<"(_,?)">
      %idx_1070 = cute.crd2idx(%coord_1069, %lay_1052) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_1071 = cute.add_offset(%ptr_1068, %idx_1070) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1072 = cute.crd2idx(%coord_1069, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1073 = cute.add_offset(%ptr_114, %idx_1072) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1074 = cute.crd2idx(%coord_1069, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_1075 = cute.add_offset(%iter_194, %idx_1074) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1403 = builtin.unrealized_conversion_cast %ptr_1075 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1404 = llvm.load %1403 : !llvm.ptr -> i8
      %1405 = llvm.trunc %1404 : i8 to i1
      %iter_1076 = cute.recast_iter(%ptr_1071) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_1077 = cute.recast_iter(%ptr_1073) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_1077 : !cute.ptr<i128, smem>, %iter_1076 : !cute.ptr<i128, gmem>, %1405 : i1) {cache_mode = <global>}
      %1406 = arith.addi %1401, %c1_i32 : i32
      cf.br ^bb409(%1406 : i32)
    ^bb411:  // pred: ^bb409
      nvvm.cp.async.commit.group
      cf.br ^bb412(%c0_i32 : i32)
    ^bb412(%1407: i32):  // 2 preds: ^bb411, ^bb413
      %1408 = arith.cmpi slt, %1407, %607 : i32
      cf.cond_br %1408, ^bb413, ^bb414 {llvm.loop_annotation = #loop_annotation}
    ^bb413:  // pred: ^bb412
      %coord_1078 = cute.make_coord(%1407) : (i32) -> !cute.coord<"(_,?)">
      %idx_1079 = cute.crd2idx(%coord_1078, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1080 = cute.add_offset(%ptr_122, %idx_1079) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1081 = cute.crd2idx(%coord_1078, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1082 = cute.add_offset(%iter_127, %idx_1081) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1409 = cute_nvgpu.arch.copy.ldsm %ptr_1080{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1410 = vector.extractelement %1409[%130 : i32] : vector<4xi32>
      %1411 = builtin.unrealized_conversion_cast %ptr_1082 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1410, %1411 : i32, !llvm.ptr
      %1412 = vector.extractelement %1409[%129 : i32] : vector<4xi32>
      %ptr_1083 = cute.add_offset(%ptr_1082, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1413 = builtin.unrealized_conversion_cast %ptr_1083 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1412, %1413 : i32, !llvm.ptr
      %1414 = vector.extractelement %1409[%128 : i32] : vector<4xi32>
      %ptr_1084 = cute.add_offset(%ptr_1082, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1415 = builtin.unrealized_conversion_cast %ptr_1084 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1414, %1415 : i32, !llvm.ptr
      %1416 = vector.extractelement %1409[%126 : i32] : vector<4xi32>
      %ptr_1085 = cute.add_offset(%ptr_1082, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1417 = builtin.unrealized_conversion_cast %ptr_1085 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1416, %1417 : i32, !llvm.ptr
      %1418 = arith.addi %1407, %c1_i32 : i32
      cf.br ^bb412(%1418 : i32)
    ^bb414:  // pred: ^bb412
      cf.br ^bb415(%c0_i32 : i32)
    ^bb415(%1419: i32):  // 2 preds: ^bb414, ^bb416
      %1420 = arith.cmpi slt, %1419, %620 : i32
      cf.cond_br %1420, ^bb416, ^bb417 {llvm.loop_annotation = #loop_annotation}
    ^bb416:  // pred: ^bb415
      %coord_1086 = cute.make_coord(%1419) : (i32) -> !cute.coord<"(_,?)">
      %idx_1087 = cute.crd2idx(%coord_1086, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1088 = cute.add_offset(%ptr_130, %idx_1087) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1089 = cute.crd2idx(%coord_1086, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1090 = cute.add_offset(%iter_135, %idx_1089) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1421 = cute_nvgpu.arch.copy.ldsm %ptr_1088{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1422 = vector.extractelement %1421[%130 : i32] : vector<4xi32>
      %1423 = builtin.unrealized_conversion_cast %ptr_1090 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1422, %1423 : i32, !llvm.ptr
      %1424 = vector.extractelement %1421[%129 : i32] : vector<4xi32>
      %ptr_1091 = cute.add_offset(%ptr_1090, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1425 = builtin.unrealized_conversion_cast %ptr_1091 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1424, %1425 : i32, !llvm.ptr
      %1426 = vector.extractelement %1421[%128 : i32] : vector<4xi32>
      %ptr_1092 = cute.add_offset(%ptr_1090, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1427 = builtin.unrealized_conversion_cast %ptr_1092 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1426, %1427 : i32, !llvm.ptr
      %1428 = vector.extractelement %1421[%126 : i32] : vector<4xi32>
      %ptr_1093 = cute.add_offset(%ptr_1090, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1429 = builtin.unrealized_conversion_cast %ptr_1093 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1428, %1429 : i32, !llvm.ptr
      %1430 = arith.addi %1419, %c1_i32 : i32
      cf.br ^bb415(%1430 : i32)
    ^bb417:  // pred: ^bb415
      cf.br ^bb418(%c0_i32 : i32)
    ^bb418(%1431: i32):  // 2 preds: ^bb417, ^bb419
      %1432 = arith.cmpi slt, %1431, %607 : i32
      cf.cond_br %1432, ^bb419, ^bb420 {llvm.loop_annotation = #loop_annotation}
    ^bb419:  // pred: ^bb418
      %coord_1094 = cute.make_coord(%1431) : (i32) -> !cute.coord<"(_,?)">
      %idx_1095 = cute.crd2idx(%coord_1094, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1096 = cute.add_offset(%ptr_535, %idx_1095) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1097 = cute.crd2idx(%coord_1094, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1098 = cute.add_offset(%ptr_536, %idx_1097) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1433 = cute_nvgpu.arch.copy.ldsm %ptr_1096{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1434 = vector.extractelement %1433[%130 : i32] : vector<4xi32>
      %1435 = builtin.unrealized_conversion_cast %ptr_1098 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1434, %1435 : i32, !llvm.ptr
      %1436 = vector.extractelement %1433[%129 : i32] : vector<4xi32>
      %ptr_1099 = cute.add_offset(%ptr_1098, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1437 = builtin.unrealized_conversion_cast %ptr_1099 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1436, %1437 : i32, !llvm.ptr
      %1438 = vector.extractelement %1433[%128 : i32] : vector<4xi32>
      %ptr_1100 = cute.add_offset(%ptr_1098, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1439 = builtin.unrealized_conversion_cast %ptr_1100 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1438, %1439 : i32, !llvm.ptr
      %1440 = vector.extractelement %1433[%126 : i32] : vector<4xi32>
      %ptr_1101 = cute.add_offset(%ptr_1098, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1441 = builtin.unrealized_conversion_cast %ptr_1101 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1440, %1441 : i32, !llvm.ptr
      %1442 = arith.addi %1431, %c1_i32 : i32
      cf.br ^bb418(%1442 : i32)
    ^bb420:  // pred: ^bb418
      cf.br ^bb421(%c0_i32 : i32)
    ^bb421(%1443: i32):  // 2 preds: ^bb420, ^bb422
      %1444 = arith.cmpi slt, %1443, %620 : i32
      cf.cond_br %1444, ^bb422, ^bb423 {llvm.loop_annotation = #loop_annotation}
    ^bb422:  // pred: ^bb421
      %coord_1102 = cute.make_coord(%1443) : (i32) -> !cute.coord<"(_,?)">
      %idx_1103 = cute.crd2idx(%coord_1102, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1104 = cute.add_offset(%ptr_546, %idx_1103) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1105 = cute.crd2idx(%coord_1102, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1106 = cute.add_offset(%ptr_547, %idx_1105) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1445 = cute_nvgpu.arch.copy.ldsm %ptr_1104{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1446 = vector.extractelement %1445[%130 : i32] : vector<4xi32>
      %1447 = builtin.unrealized_conversion_cast %ptr_1106 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1446, %1447 : i32, !llvm.ptr
      %1448 = vector.extractelement %1445[%129 : i32] : vector<4xi32>
      %ptr_1107 = cute.add_offset(%ptr_1106, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1449 = builtin.unrealized_conversion_cast %ptr_1107 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1448, %1449 : i32, !llvm.ptr
      %1450 = vector.extractelement %1445[%128 : i32] : vector<4xi32>
      %ptr_1108 = cute.add_offset(%ptr_1106, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1451 = builtin.unrealized_conversion_cast %ptr_1108 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1450, %1451 : i32, !llvm.ptr
      %1452 = vector.extractelement %1445[%126 : i32] : vector<4xi32>
      %ptr_1109 = cute.add_offset(%ptr_1106, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1453 = builtin.unrealized_conversion_cast %ptr_1109 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1452, %1453 : i32, !llvm.ptr
      %1454 = arith.addi %1443, %c1_i32 : i32
      cf.br ^bb421(%1454 : i32)
    ^bb423:  // pred: ^bb421
      cf.br ^bb424(%c0_i32 : i32)
    ^bb424(%1455: i32):  // 2 preds: ^bb423, ^bb431
      %1456 = arith.cmpi slt, %1455, %657 : i32
      cf.cond_br %1456, ^bb425, ^bb432 {llvm.loop_annotation = #loop_annotation}
    ^bb425:  // pred: ^bb424
      cf.br ^bb426(%c0_i32 : i32)
    ^bb426(%1457: i32):  // 2 preds: ^bb425, ^bb430
      %1458 = arith.cmpi slt, %1457, %607 : i32
      cf.cond_br %1458, ^bb427, ^bb431 {llvm.loop_annotation = #loop_annotation}
    ^bb427:  // pred: ^bb426
      %coord_1110 = cute.make_coord(%1457, %1455) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1111 = cute.crd2idx(%coord_1110, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1112 = cute.add_offset(%iter_127, %idx_1111) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1459 = builtin.unrealized_conversion_cast %ptr_1112 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1460 = llvm.getelementptr %1459[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1461 = llvm.getelementptr %1459[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1462 = llvm.getelementptr %1459[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb428(%c0_i32 : i32)
    ^bb428(%1463: i32):  // 2 preds: ^bb427, ^bb429
      %1464 = arith.cmpi slt, %1463, %658 : i32
      cf.cond_br %1464, ^bb429, ^bb430 {llvm.loop_annotation = #loop_annotation}
    ^bb429:  // pred: ^bb428
      %coord_1113 = cute.make_coord(%1463, %1455) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1114 = cute.make_coord(%1457, %1463) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1115 = cute.crd2idx(%coord_1113, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1116 = cute.add_offset(%iter_135, %idx_1115) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1117 = cute.crd2idx(%coord_1114, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1118 = cute.add_offset(%iter_1065, %idx_1117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1465 = llvm.load %1459 : !llvm.ptr -> i32
      %1466 = llvm.load %1460 : !llvm.ptr -> i32
      %1467 = llvm.load %1461 : !llvm.ptr -> i32
      %1468 = llvm.load %1462 : !llvm.ptr -> i32
      %1469 = builtin.unrealized_conversion_cast %ptr_1116 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1470 = llvm.load %1469 : !llvm.ptr -> i32
      %1471 = llvm.getelementptr %1469[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1472 = llvm.load %1471 : !llvm.ptr -> i32
      %1473 = builtin.unrealized_conversion_cast %ptr_1118 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1474 = llvm.load %1473 : !llvm.ptr -> f32
      %1475 = llvm.getelementptr %1473[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1476 = llvm.load %1475 : !llvm.ptr -> f32
      %1477 = llvm.getelementptr %1473[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1478 = llvm.load %1477 : !llvm.ptr -> f32
      %1479 = llvm.getelementptr %1473[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1480 = llvm.load %1479 : !llvm.ptr -> f32
      %1481:4 = cute_nvgpu.arch.mma.SM80 A[%1465, %1466, %1467, %1468]  B[%1470, %1472]  C[%1474, %1476, %1478, %1480] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1481#0, %1473 : f32, !llvm.ptr
      llvm.store %1481#1, %1475 : f32, !llvm.ptr
      llvm.store %1481#2, %1477 : f32, !llvm.ptr
      llvm.store %1481#3, %1479 : f32, !llvm.ptr
      %1482 = arith.addi %1463, %c1_i32 : i32
      cf.br ^bb428(%1482 : i32)
    ^bb430:  // pred: ^bb428
      %1483 = arith.addi %1457, %c1_i32 : i32
      cf.br ^bb426(%1483 : i32)
    ^bb431:  // pred: ^bb426
      %1484 = arith.addi %1455, %c1_i32 : i32
      cf.br ^bb424(%1484 : i32)
    ^bb432:  // pred: ^bb424
      cf.br ^bb433(%c0_i32 : i32)
    ^bb433(%1485: i32):  // 2 preds: ^bb432, ^bb434
      %1486 = arith.cmpi slt, %1485, %607 : i32
      cf.cond_br %1486, ^bb434, ^bb435 {llvm.loop_annotation = #loop_annotation}
    ^bb434:  // pred: ^bb433
      %coord_1119 = cute.make_coord(%1485) : (i32) -> !cute.coord<"(_,?)">
      %idx_1120 = cute.crd2idx(%coord_1119, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1121 = cute.add_offset(%ptr_566, %idx_1120) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1122 = cute.crd2idx(%coord_1119, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1123 = cute.add_offset(%ptr_567, %idx_1122) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1487 = cute_nvgpu.arch.copy.ldsm %ptr_1121{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1488 = vector.extractelement %1487[%130 : i32] : vector<4xi32>
      %1489 = builtin.unrealized_conversion_cast %ptr_1123 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1488, %1489 : i32, !llvm.ptr
      %1490 = vector.extractelement %1487[%129 : i32] : vector<4xi32>
      %ptr_1124 = cute.add_offset(%ptr_1123, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1491 = builtin.unrealized_conversion_cast %ptr_1124 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1490, %1491 : i32, !llvm.ptr
      %1492 = vector.extractelement %1487[%128 : i32] : vector<4xi32>
      %ptr_1125 = cute.add_offset(%ptr_1123, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1493 = builtin.unrealized_conversion_cast %ptr_1125 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1492, %1493 : i32, !llvm.ptr
      %1494 = vector.extractelement %1487[%126 : i32] : vector<4xi32>
      %ptr_1126 = cute.add_offset(%ptr_1123, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1495 = builtin.unrealized_conversion_cast %ptr_1126 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1494, %1495 : i32, !llvm.ptr
      %1496 = arith.addi %1485, %c1_i32 : i32
      cf.br ^bb433(%1496 : i32)
    ^bb435:  // pred: ^bb433
      cf.br ^bb436(%c0_i32 : i32)
    ^bb436(%1497: i32):  // 2 preds: ^bb435, ^bb437
      %1498 = arith.cmpi slt, %1497, %620 : i32
      cf.cond_br %1498, ^bb437, ^bb438 {llvm.loop_annotation = #loop_annotation}
    ^bb437:  // pred: ^bb436
      %coord_1127 = cute.make_coord(%1497) : (i32) -> !cute.coord<"(_,?)">
      %idx_1128 = cute.crd2idx(%coord_1127, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1129 = cute.add_offset(%ptr_577, %idx_1128) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1130 = cute.crd2idx(%coord_1127, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1131 = cute.add_offset(%ptr_578, %idx_1130) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1499 = cute_nvgpu.arch.copy.ldsm %ptr_1129{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1500 = vector.extractelement %1499[%130 : i32] : vector<4xi32>
      %1501 = builtin.unrealized_conversion_cast %ptr_1131 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1500, %1501 : i32, !llvm.ptr
      %1502 = vector.extractelement %1499[%129 : i32] : vector<4xi32>
      %ptr_1132 = cute.add_offset(%ptr_1131, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1503 = builtin.unrealized_conversion_cast %ptr_1132 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1502, %1503 : i32, !llvm.ptr
      %1504 = vector.extractelement %1499[%128 : i32] : vector<4xi32>
      %ptr_1133 = cute.add_offset(%ptr_1131, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1505 = builtin.unrealized_conversion_cast %ptr_1133 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1504, %1505 : i32, !llvm.ptr
      %1506 = vector.extractelement %1499[%126 : i32] : vector<4xi32>
      %ptr_1134 = cute.add_offset(%ptr_1131, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1507 = builtin.unrealized_conversion_cast %ptr_1134 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1506, %1507 : i32, !llvm.ptr
      %1508 = arith.addi %1497, %c1_i32 : i32
      cf.br ^bb436(%1508 : i32)
    ^bb438:  // pred: ^bb436
      cf.br ^bb439(%c0_i32 : i32)
    ^bb439(%1509: i32):  // 2 preds: ^bb438, ^bb446
      %1510 = arith.cmpi slt, %1509, %657 : i32
      cf.cond_br %1510, ^bb440, ^bb447 {llvm.loop_annotation = #loop_annotation}
    ^bb440:  // pred: ^bb439
      cf.br ^bb441(%c0_i32 : i32)
    ^bb441(%1511: i32):  // 2 preds: ^bb440, ^bb445
      %1512 = arith.cmpi slt, %1511, %607 : i32
      cf.cond_br %1512, ^bb442, ^bb446 {llvm.loop_annotation = #loop_annotation}
    ^bb442:  // pred: ^bb441
      %coord_1135 = cute.make_coord(%1511, %1509) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1136 = cute.crd2idx(%coord_1135, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1137 = cute.add_offset(%ptr_536, %idx_1136) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1513 = builtin.unrealized_conversion_cast %ptr_1137 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1514 = llvm.getelementptr %1513[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1515 = llvm.getelementptr %1513[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1516 = llvm.getelementptr %1513[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb443(%c0_i32 : i32)
    ^bb443(%1517: i32):  // 2 preds: ^bb442, ^bb444
      %1518 = arith.cmpi slt, %1517, %658 : i32
      cf.cond_br %1518, ^bb444, ^bb445 {llvm.loop_annotation = #loop_annotation}
    ^bb444:  // pred: ^bb443
      %coord_1138 = cute.make_coord(%1517, %1509) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1139 = cute.make_coord(%1511, %1517) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1140 = cute.crd2idx(%coord_1138, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1141 = cute.add_offset(%ptr_547, %idx_1140) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1142 = cute.crd2idx(%coord_1139, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1143 = cute.add_offset(%iter_1065, %idx_1142) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1519 = llvm.load %1513 : !llvm.ptr -> i32
      %1520 = llvm.load %1514 : !llvm.ptr -> i32
      %1521 = llvm.load %1515 : !llvm.ptr -> i32
      %1522 = llvm.load %1516 : !llvm.ptr -> i32
      %1523 = builtin.unrealized_conversion_cast %ptr_1141 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1524 = llvm.load %1523 : !llvm.ptr -> i32
      %1525 = llvm.getelementptr %1523[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1526 = llvm.load %1525 : !llvm.ptr -> i32
      %1527 = builtin.unrealized_conversion_cast %ptr_1143 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1528 = llvm.load %1527 : !llvm.ptr -> f32
      %1529 = llvm.getelementptr %1527[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1530 = llvm.load %1529 : !llvm.ptr -> f32
      %1531 = llvm.getelementptr %1527[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1532 = llvm.load %1531 : !llvm.ptr -> f32
      %1533 = llvm.getelementptr %1527[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1534 = llvm.load %1533 : !llvm.ptr -> f32
      %1535:4 = cute_nvgpu.arch.mma.SM80 A[%1519, %1520, %1521, %1522]  B[%1524, %1526]  C[%1528, %1530, %1532, %1534] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1535#0, %1527 : f32, !llvm.ptr
      llvm.store %1535#1, %1529 : f32, !llvm.ptr
      llvm.store %1535#2, %1531 : f32, !llvm.ptr
      llvm.store %1535#3, %1533 : f32, !llvm.ptr
      %1536 = arith.addi %1517, %c1_i32 : i32
      cf.br ^bb443(%1536 : i32)
    ^bb445:  // pred: ^bb443
      %1537 = arith.addi %1511, %c1_i32 : i32
      cf.br ^bb441(%1537 : i32)
    ^bb446:  // pred: ^bb441
      %1538 = arith.addi %1509, %c1_i32 : i32
      cf.br ^bb439(%1538 : i32)
    ^bb447:  // pred: ^bb439
      cf.br ^bb448(%c0_i32 : i32)
    ^bb448(%1539: i32):  // 2 preds: ^bb447, ^bb449
      %1540 = arith.cmpi slt, %1539, %607 : i32
      cf.cond_br %1540, ^bb449, ^bb450 {llvm.loop_annotation = #loop_annotation}
    ^bb449:  // pred: ^bb448
      %coord_1144 = cute.make_coord(%1539) : (i32) -> !cute.coord<"(_,?)">
      %idx_1145 = cute.crd2idx(%coord_1144, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1146 = cute.add_offset(%ptr_597, %idx_1145) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1147 = cute.crd2idx(%coord_1144, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1148 = cute.add_offset(%ptr_598, %idx_1147) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1541 = cute_nvgpu.arch.copy.ldsm %ptr_1146{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1542 = vector.extractelement %1541[%130 : i32] : vector<4xi32>
      %1543 = builtin.unrealized_conversion_cast %ptr_1148 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1542, %1543 : i32, !llvm.ptr
      %1544 = vector.extractelement %1541[%129 : i32] : vector<4xi32>
      %ptr_1149 = cute.add_offset(%ptr_1148, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1545 = builtin.unrealized_conversion_cast %ptr_1149 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1544, %1545 : i32, !llvm.ptr
      %1546 = vector.extractelement %1541[%128 : i32] : vector<4xi32>
      %ptr_1150 = cute.add_offset(%ptr_1148, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1547 = builtin.unrealized_conversion_cast %ptr_1150 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1546, %1547 : i32, !llvm.ptr
      %1548 = vector.extractelement %1541[%126 : i32] : vector<4xi32>
      %ptr_1151 = cute.add_offset(%ptr_1148, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1549 = builtin.unrealized_conversion_cast %ptr_1151 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1548, %1549 : i32, !llvm.ptr
      %1550 = arith.addi %1539, %c1_i32 : i32
      cf.br ^bb448(%1550 : i32)
    ^bb450:  // pred: ^bb448
      cf.br ^bb451(%c0_i32 : i32)
    ^bb451(%1551: i32):  // 2 preds: ^bb450, ^bb452
      %1552 = arith.cmpi slt, %1551, %620 : i32
      cf.cond_br %1552, ^bb452, ^bb453 {llvm.loop_annotation = #loop_annotation}
    ^bb452:  // pred: ^bb451
      %coord_1152 = cute.make_coord(%1551) : (i32) -> !cute.coord<"(_,?)">
      %idx_1153 = cute.crd2idx(%coord_1152, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1154 = cute.add_offset(%ptr_608, %idx_1153) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1155 = cute.crd2idx(%coord_1152, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1156 = cute.add_offset(%ptr_609, %idx_1155) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1553 = cute_nvgpu.arch.copy.ldsm %ptr_1154{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1554 = vector.extractelement %1553[%130 : i32] : vector<4xi32>
      %1555 = builtin.unrealized_conversion_cast %ptr_1156 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1554, %1555 : i32, !llvm.ptr
      %1556 = vector.extractelement %1553[%129 : i32] : vector<4xi32>
      %ptr_1157 = cute.add_offset(%ptr_1156, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1557 = builtin.unrealized_conversion_cast %ptr_1157 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1556, %1557 : i32, !llvm.ptr
      %1558 = vector.extractelement %1553[%128 : i32] : vector<4xi32>
      %ptr_1158 = cute.add_offset(%ptr_1156, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1559 = builtin.unrealized_conversion_cast %ptr_1158 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1558, %1559 : i32, !llvm.ptr
      %1560 = vector.extractelement %1553[%126 : i32] : vector<4xi32>
      %ptr_1159 = cute.add_offset(%ptr_1156, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1561 = builtin.unrealized_conversion_cast %ptr_1159 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1560, %1561 : i32, !llvm.ptr
      %1562 = arith.addi %1551, %c1_i32 : i32
      cf.br ^bb451(%1562 : i32)
    ^bb453:  // pred: ^bb451
      cf.br ^bb454(%c0_i32 : i32)
    ^bb454(%1563: i32):  // 2 preds: ^bb453, ^bb461
      %1564 = arith.cmpi slt, %1563, %657 : i32
      cf.cond_br %1564, ^bb455, ^bb462 {llvm.loop_annotation = #loop_annotation}
    ^bb455:  // pred: ^bb454
      cf.br ^bb456(%c0_i32 : i32)
    ^bb456(%1565: i32):  // 2 preds: ^bb455, ^bb460
      %1566 = arith.cmpi slt, %1565, %607 : i32
      cf.cond_br %1566, ^bb457, ^bb461 {llvm.loop_annotation = #loop_annotation}
    ^bb457:  // pred: ^bb456
      %coord_1160 = cute.make_coord(%1565, %1563) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1161 = cute.crd2idx(%coord_1160, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1162 = cute.add_offset(%ptr_567, %idx_1161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1567 = builtin.unrealized_conversion_cast %ptr_1162 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1568 = llvm.getelementptr %1567[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1569 = llvm.getelementptr %1567[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1570 = llvm.getelementptr %1567[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb458(%c0_i32 : i32)
    ^bb458(%1571: i32):  // 2 preds: ^bb457, ^bb459
      %1572 = arith.cmpi slt, %1571, %658 : i32
      cf.cond_br %1572, ^bb459, ^bb460 {llvm.loop_annotation = #loop_annotation}
    ^bb459:  // pred: ^bb458
      %coord_1163 = cute.make_coord(%1571, %1563) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1164 = cute.make_coord(%1565, %1571) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1165 = cute.crd2idx(%coord_1163, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1166 = cute.add_offset(%ptr_578, %idx_1165) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1167 = cute.crd2idx(%coord_1164, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1168 = cute.add_offset(%iter_1065, %idx_1167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1573 = llvm.load %1567 : !llvm.ptr -> i32
      %1574 = llvm.load %1568 : !llvm.ptr -> i32
      %1575 = llvm.load %1569 : !llvm.ptr -> i32
      %1576 = llvm.load %1570 : !llvm.ptr -> i32
      %1577 = builtin.unrealized_conversion_cast %ptr_1166 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1578 = llvm.load %1577 : !llvm.ptr -> i32
      %1579 = llvm.getelementptr %1577[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1580 = llvm.load %1579 : !llvm.ptr -> i32
      %1581 = builtin.unrealized_conversion_cast %ptr_1168 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1582 = llvm.load %1581 : !llvm.ptr -> f32
      %1583 = llvm.getelementptr %1581[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1584 = llvm.load %1583 : !llvm.ptr -> f32
      %1585 = llvm.getelementptr %1581[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1586 = llvm.load %1585 : !llvm.ptr -> f32
      %1587 = llvm.getelementptr %1581[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1588 = llvm.load %1587 : !llvm.ptr -> f32
      %1589:4 = cute_nvgpu.arch.mma.SM80 A[%1573, %1574, %1575, %1576]  B[%1578, %1580]  C[%1582, %1584, %1586, %1588] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1589#0, %1581 : f32, !llvm.ptr
      llvm.store %1589#1, %1583 : f32, !llvm.ptr
      llvm.store %1589#2, %1585 : f32, !llvm.ptr
      llvm.store %1589#3, %1587 : f32, !llvm.ptr
      %1590 = arith.addi %1571, %c1_i32 : i32
      cf.br ^bb458(%1590 : i32)
    ^bb460:  // pred: ^bb458
      %1591 = arith.addi %1565, %c1_i32 : i32
      cf.br ^bb456(%1591 : i32)
    ^bb461:  // pred: ^bb456
      %1592 = arith.addi %1563, %c1_i32 : i32
      cf.br ^bb454(%1592 : i32)
    ^bb462:  // pred: ^bb454
      cf.br ^bb463(%c0_i32 : i32)
    ^bb463(%1593: i32):  // 2 preds: ^bb462, ^bb464
      %1594 = arith.cmpi slt, %1593, %607 : i32
      cf.cond_br %1594, ^bb464, ^bb465 {llvm.loop_annotation = #loop_annotation}
    ^bb464:  // pred: ^bb463
      %coord_1169 = cute.make_coord(%1593) : (i32) -> !cute.coord<"(_,?)">
      %idx_1170 = cute.crd2idx(%coord_1169, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1171 = cute.add_offset(%ptr_627, %idx_1170) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1172 = cute.crd2idx(%coord_1169, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1173 = cute.add_offset(%ptr_628, %idx_1172) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1595 = cute_nvgpu.arch.copy.ldsm %ptr_1171{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1596 = vector.extractelement %1595[%130 : i32] : vector<4xi32>
      %1597 = builtin.unrealized_conversion_cast %ptr_1173 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1596, %1597 : i32, !llvm.ptr
      %1598 = vector.extractelement %1595[%129 : i32] : vector<4xi32>
      %ptr_1174 = cute.add_offset(%ptr_1173, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1599 = builtin.unrealized_conversion_cast %ptr_1174 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1598, %1599 : i32, !llvm.ptr
      %1600 = vector.extractelement %1595[%128 : i32] : vector<4xi32>
      %ptr_1175 = cute.add_offset(%ptr_1173, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1601 = builtin.unrealized_conversion_cast %ptr_1175 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1600, %1601 : i32, !llvm.ptr
      %1602 = vector.extractelement %1595[%126 : i32] : vector<4xi32>
      %ptr_1176 = cute.add_offset(%ptr_1173, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1603 = builtin.unrealized_conversion_cast %ptr_1176 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1602, %1603 : i32, !llvm.ptr
      %1604 = arith.addi %1593, %c1_i32 : i32
      cf.br ^bb463(%1604 : i32)
    ^bb465:  // pred: ^bb463
      cf.br ^bb466(%c0_i32 : i32)
    ^bb466(%1605: i32):  // 2 preds: ^bb465, ^bb467
      %1606 = arith.cmpi slt, %1605, %620 : i32
      cf.cond_br %1606, ^bb467, ^bb468 {llvm.loop_annotation = #loop_annotation}
    ^bb467:  // pred: ^bb466
      %coord_1177 = cute.make_coord(%1605) : (i32) -> !cute.coord<"(_,?)">
      %idx_1178 = cute.crd2idx(%coord_1177, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1179 = cute.add_offset(%ptr_637, %idx_1178) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1180 = cute.crd2idx(%coord_1177, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1181 = cute.add_offset(%ptr_638, %idx_1180) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1607 = cute_nvgpu.arch.copy.ldsm %ptr_1179{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1608 = vector.extractelement %1607[%130 : i32] : vector<4xi32>
      %1609 = builtin.unrealized_conversion_cast %ptr_1181 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1608, %1609 : i32, !llvm.ptr
      %1610 = vector.extractelement %1607[%129 : i32] : vector<4xi32>
      %ptr_1182 = cute.add_offset(%ptr_1181, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1611 = builtin.unrealized_conversion_cast %ptr_1182 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1610, %1611 : i32, !llvm.ptr
      %1612 = vector.extractelement %1607[%128 : i32] : vector<4xi32>
      %ptr_1183 = cute.add_offset(%ptr_1181, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1613 = builtin.unrealized_conversion_cast %ptr_1183 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1612, %1613 : i32, !llvm.ptr
      %1614 = vector.extractelement %1607[%126 : i32] : vector<4xi32>
      %ptr_1184 = cute.add_offset(%ptr_1181, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1615 = builtin.unrealized_conversion_cast %ptr_1184 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1614, %1615 : i32, !llvm.ptr
      %1616 = arith.addi %1605, %c1_i32 : i32
      cf.br ^bb466(%1616 : i32)
    ^bb468:  // pred: ^bb466
      cf.br ^bb469(%c0_i32 : i32)
    ^bb469(%1617: i32):  // 2 preds: ^bb468, ^bb476
      %1618 = arith.cmpi slt, %1617, %657 : i32
      cf.cond_br %1618, ^bb470, ^bb477 {llvm.loop_annotation = #loop_annotation}
    ^bb470:  // pred: ^bb469
      cf.br ^bb471(%c0_i32 : i32)
    ^bb471(%1619: i32):  // 2 preds: ^bb470, ^bb475
      %1620 = arith.cmpi slt, %1619, %607 : i32
      cf.cond_br %1620, ^bb472, ^bb476 {llvm.loop_annotation = #loop_annotation}
    ^bb472:  // pred: ^bb471
      %coord_1185 = cute.make_coord(%1619, %1617) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1186 = cute.crd2idx(%coord_1185, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1187 = cute.add_offset(%ptr_598, %idx_1186) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1621 = builtin.unrealized_conversion_cast %ptr_1187 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1622 = llvm.getelementptr %1621[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1623 = llvm.getelementptr %1621[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1624 = llvm.getelementptr %1621[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb473(%c0_i32 : i32)
    ^bb473(%1625: i32):  // 2 preds: ^bb472, ^bb474
      %1626 = arith.cmpi slt, %1625, %658 : i32
      cf.cond_br %1626, ^bb474, ^bb475 {llvm.loop_annotation = #loop_annotation}
    ^bb474:  // pred: ^bb473
      %coord_1188 = cute.make_coord(%1625, %1617) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1189 = cute.make_coord(%1619, %1625) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1190 = cute.crd2idx(%coord_1188, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1191 = cute.add_offset(%ptr_609, %idx_1190) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1192 = cute.crd2idx(%coord_1189, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1193 = cute.add_offset(%iter_1065, %idx_1192) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1627 = llvm.load %1621 : !llvm.ptr -> i32
      %1628 = llvm.load %1622 : !llvm.ptr -> i32
      %1629 = llvm.load %1623 : !llvm.ptr -> i32
      %1630 = llvm.load %1624 : !llvm.ptr -> i32
      %1631 = builtin.unrealized_conversion_cast %ptr_1191 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1632 = llvm.load %1631 : !llvm.ptr -> i32
      %1633 = llvm.getelementptr %1631[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1634 = llvm.load %1633 : !llvm.ptr -> i32
      %1635 = builtin.unrealized_conversion_cast %ptr_1193 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1636 = llvm.load %1635 : !llvm.ptr -> f32
      %1637 = llvm.getelementptr %1635[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1638 = llvm.load %1637 : !llvm.ptr -> f32
      %1639 = llvm.getelementptr %1635[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1640 = llvm.load %1639 : !llvm.ptr -> f32
      %1641 = llvm.getelementptr %1635[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1642 = llvm.load %1641 : !llvm.ptr -> f32
      %1643:4 = cute_nvgpu.arch.mma.SM80 A[%1627, %1628, %1629, %1630]  B[%1632, %1634]  C[%1636, %1638, %1640, %1642] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1643#0, %1635 : f32, !llvm.ptr
      llvm.store %1643#1, %1637 : f32, !llvm.ptr
      llvm.store %1643#2, %1639 : f32, !llvm.ptr
      llvm.store %1643#3, %1641 : f32, !llvm.ptr
      %1644 = arith.addi %1625, %c1_i32 : i32
      cf.br ^bb473(%1644 : i32)
    ^bb475:  // pred: ^bb473
      %1645 = arith.addi %1619, %c1_i32 : i32
      cf.br ^bb471(%1645 : i32)
    ^bb476:  // pred: ^bb471
      %1646 = arith.addi %1617, %c1_i32 : i32
      cf.br ^bb469(%1646 : i32)
    ^bb477:  // pred: ^bb469
      cf.br ^bb478(%c0_i32 : i32)
    ^bb478(%1647: i32):  // 2 preds: ^bb477, ^bb479
      %1648 = arith.cmpi slt, %1647, %607 : i32
      cf.cond_br %1648, ^bb479, ^bb480 {llvm.loop_annotation = #loop_annotation}
    ^bb479:  // pred: ^bb478
      %coord_1194 = cute.make_coord(%1647) : (i32) -> !cute.coord<"(_,?)">
      %idx_1195 = cute.crd2idx(%coord_1194, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1196 = cute.add_offset(%ptr_657, %idx_1195) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1197 = cute.crd2idx(%coord_1194, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1198 = cute.add_offset(%ptr_658, %idx_1197) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1649 = cute_nvgpu.arch.copy.ldsm %ptr_1196{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1650 = vector.extractelement %1649[%130 : i32] : vector<4xi32>
      %1651 = builtin.unrealized_conversion_cast %ptr_1198 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1650, %1651 : i32, !llvm.ptr
      %1652 = vector.extractelement %1649[%129 : i32] : vector<4xi32>
      %ptr_1199 = cute.add_offset(%ptr_1198, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1653 = builtin.unrealized_conversion_cast %ptr_1199 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1652, %1653 : i32, !llvm.ptr
      %1654 = vector.extractelement %1649[%128 : i32] : vector<4xi32>
      %ptr_1200 = cute.add_offset(%ptr_1198, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1655 = builtin.unrealized_conversion_cast %ptr_1200 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1654, %1655 : i32, !llvm.ptr
      %1656 = vector.extractelement %1649[%126 : i32] : vector<4xi32>
      %ptr_1201 = cute.add_offset(%ptr_1198, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1657 = builtin.unrealized_conversion_cast %ptr_1201 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1656, %1657 : i32, !llvm.ptr
      %1658 = arith.addi %1647, %c1_i32 : i32
      cf.br ^bb478(%1658 : i32)
    ^bb480:  // pred: ^bb478
      cf.br ^bb481(%c0_i32 : i32)
    ^bb481(%1659: i32):  // 2 preds: ^bb480, ^bb482
      %1660 = arith.cmpi slt, %1659, %620 : i32
      cf.cond_br %1660, ^bb482, ^bb483 {llvm.loop_annotation = #loop_annotation}
    ^bb482:  // pred: ^bb481
      %coord_1202 = cute.make_coord(%1659) : (i32) -> !cute.coord<"(_,?)">
      %idx_1203 = cute.crd2idx(%coord_1202, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1204 = cute.add_offset(%ptr_668, %idx_1203) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1205 = cute.crd2idx(%coord_1202, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1206 = cute.add_offset(%ptr_669, %idx_1205) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1661 = cute_nvgpu.arch.copy.ldsm %ptr_1204{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1662 = vector.extractelement %1661[%130 : i32] : vector<4xi32>
      %1663 = builtin.unrealized_conversion_cast %ptr_1206 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1662, %1663 : i32, !llvm.ptr
      %1664 = vector.extractelement %1661[%129 : i32] : vector<4xi32>
      %ptr_1207 = cute.add_offset(%ptr_1206, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1665 = builtin.unrealized_conversion_cast %ptr_1207 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1664, %1665 : i32, !llvm.ptr
      %1666 = vector.extractelement %1661[%128 : i32] : vector<4xi32>
      %ptr_1208 = cute.add_offset(%ptr_1206, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1667 = builtin.unrealized_conversion_cast %ptr_1208 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1666, %1667 : i32, !llvm.ptr
      %1668 = vector.extractelement %1661[%126 : i32] : vector<4xi32>
      %ptr_1209 = cute.add_offset(%ptr_1206, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1669 = builtin.unrealized_conversion_cast %ptr_1209 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1668, %1669 : i32, !llvm.ptr
      %1670 = arith.addi %1659, %c1_i32 : i32
      cf.br ^bb481(%1670 : i32)
    ^bb483:  // pred: ^bb481
      cf.br ^bb484(%c0_i32 : i32)
    ^bb484(%1671: i32):  // 2 preds: ^bb483, ^bb491
      %1672 = arith.cmpi slt, %1671, %657 : i32
      cf.cond_br %1672, ^bb485, ^bb492 {llvm.loop_annotation = #loop_annotation}
    ^bb485:  // pred: ^bb484
      cf.br ^bb486(%c0_i32 : i32)
    ^bb486(%1673: i32):  // 2 preds: ^bb485, ^bb490
      %1674 = arith.cmpi slt, %1673, %607 : i32
      cf.cond_br %1674, ^bb487, ^bb491 {llvm.loop_annotation = #loop_annotation}
    ^bb487:  // pred: ^bb486
      %coord_1210 = cute.make_coord(%1673, %1671) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1211 = cute.crd2idx(%coord_1210, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1212 = cute.add_offset(%ptr_628, %idx_1211) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1675 = builtin.unrealized_conversion_cast %ptr_1212 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1676 = llvm.getelementptr %1675[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1677 = llvm.getelementptr %1675[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1678 = llvm.getelementptr %1675[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb488(%c0_i32 : i32)
    ^bb488(%1679: i32):  // 2 preds: ^bb487, ^bb489
      %1680 = arith.cmpi slt, %1679, %658 : i32
      cf.cond_br %1680, ^bb489, ^bb490 {llvm.loop_annotation = #loop_annotation}
    ^bb489:  // pred: ^bb488
      %coord_1213 = cute.make_coord(%1679, %1671) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1214 = cute.make_coord(%1673, %1679) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1215 = cute.crd2idx(%coord_1213, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1216 = cute.add_offset(%ptr_638, %idx_1215) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1217 = cute.crd2idx(%coord_1214, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1218 = cute.add_offset(%iter_1065, %idx_1217) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1681 = llvm.load %1675 : !llvm.ptr -> i32
      %1682 = llvm.load %1676 : !llvm.ptr -> i32
      %1683 = llvm.load %1677 : !llvm.ptr -> i32
      %1684 = llvm.load %1678 : !llvm.ptr -> i32
      %1685 = builtin.unrealized_conversion_cast %ptr_1216 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1686 = llvm.load %1685 : !llvm.ptr -> i32
      %1687 = llvm.getelementptr %1685[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1688 = llvm.load %1687 : !llvm.ptr -> i32
      %1689 = builtin.unrealized_conversion_cast %ptr_1218 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1690 = llvm.load %1689 : !llvm.ptr -> f32
      %1691 = llvm.getelementptr %1689[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1692 = llvm.load %1691 : !llvm.ptr -> f32
      %1693 = llvm.getelementptr %1689[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1694 = llvm.load %1693 : !llvm.ptr -> f32
      %1695 = llvm.getelementptr %1689[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1696 = llvm.load %1695 : !llvm.ptr -> f32
      %1697:4 = cute_nvgpu.arch.mma.SM80 A[%1681, %1682, %1683, %1684]  B[%1686, %1688]  C[%1690, %1692, %1694, %1696] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1697#0, %1689 : f32, !llvm.ptr
      llvm.store %1697#1, %1691 : f32, !llvm.ptr
      llvm.store %1697#2, %1693 : f32, !llvm.ptr
      llvm.store %1697#3, %1695 : f32, !llvm.ptr
      %1698 = arith.addi %1679, %c1_i32 : i32
      cf.br ^bb488(%1698 : i32)
    ^bb490:  // pred: ^bb488
      %1699 = arith.addi %1673, %c1_i32 : i32
      cf.br ^bb486(%1699 : i32)
    ^bb491:  // pred: ^bb486
      %1700 = arith.addi %1671, %c1_i32 : i32
      cf.br ^bb484(%1700 : i32)
    ^bb492:  // pred: ^bb484
      cf.br ^bb493(%c0_i32 : i32)
    ^bb493(%1701: i32):  // 2 preds: ^bb492, ^bb494
      %1702 = arith.cmpi slt, %1701, %607 : i32
      cf.cond_br %1702, ^bb494, ^bb495 {llvm.loop_annotation = #loop_annotation}
    ^bb494:  // pred: ^bb493
      %coord_1219 = cute.make_coord(%1701) : (i32) -> !cute.coord<"(_,?)">
      %idx_1220 = cute.crd2idx(%coord_1219, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1221 = cute.add_offset(%ptr_688, %idx_1220) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1222 = cute.crd2idx(%coord_1219, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1223 = cute.add_offset(%ptr_689, %idx_1222) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1703 = cute_nvgpu.arch.copy.ldsm %ptr_1221{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1704 = vector.extractelement %1703[%130 : i32] : vector<4xi32>
      %1705 = builtin.unrealized_conversion_cast %ptr_1223 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1704, %1705 : i32, !llvm.ptr
      %1706 = vector.extractelement %1703[%129 : i32] : vector<4xi32>
      %ptr_1224 = cute.add_offset(%ptr_1223, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1707 = builtin.unrealized_conversion_cast %ptr_1224 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1706, %1707 : i32, !llvm.ptr
      %1708 = vector.extractelement %1703[%128 : i32] : vector<4xi32>
      %ptr_1225 = cute.add_offset(%ptr_1223, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1709 = builtin.unrealized_conversion_cast %ptr_1225 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1708, %1709 : i32, !llvm.ptr
      %1710 = vector.extractelement %1703[%126 : i32] : vector<4xi32>
      %ptr_1226 = cute.add_offset(%ptr_1223, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1711 = builtin.unrealized_conversion_cast %ptr_1226 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1710, %1711 : i32, !llvm.ptr
      %1712 = arith.addi %1701, %c1_i32 : i32
      cf.br ^bb493(%1712 : i32)
    ^bb495:  // pred: ^bb493
      cf.br ^bb496(%c0_i32 : i32)
    ^bb496(%1713: i32):  // 2 preds: ^bb495, ^bb497
      %1714 = arith.cmpi slt, %1713, %620 : i32
      cf.cond_br %1714, ^bb497, ^bb498 {llvm.loop_annotation = #loop_annotation}
    ^bb497:  // pred: ^bb496
      %coord_1227 = cute.make_coord(%1713) : (i32) -> !cute.coord<"(_,?)">
      %idx_1228 = cute.crd2idx(%coord_1227, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1229 = cute.add_offset(%ptr_699, %idx_1228) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1230 = cute.crd2idx(%coord_1227, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1231 = cute.add_offset(%ptr_700, %idx_1230) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1715 = cute_nvgpu.arch.copy.ldsm %ptr_1229{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1716 = vector.extractelement %1715[%130 : i32] : vector<4xi32>
      %1717 = builtin.unrealized_conversion_cast %ptr_1231 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1716, %1717 : i32, !llvm.ptr
      %1718 = vector.extractelement %1715[%129 : i32] : vector<4xi32>
      %ptr_1232 = cute.add_offset(%ptr_1231, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1719 = builtin.unrealized_conversion_cast %ptr_1232 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1718, %1719 : i32, !llvm.ptr
      %1720 = vector.extractelement %1715[%128 : i32] : vector<4xi32>
      %ptr_1233 = cute.add_offset(%ptr_1231, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1721 = builtin.unrealized_conversion_cast %ptr_1233 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1720, %1721 : i32, !llvm.ptr
      %1722 = vector.extractelement %1715[%126 : i32] : vector<4xi32>
      %ptr_1234 = cute.add_offset(%ptr_1231, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1723 = builtin.unrealized_conversion_cast %ptr_1234 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1722, %1723 : i32, !llvm.ptr
      %1724 = arith.addi %1713, %c1_i32 : i32
      cf.br ^bb496(%1724 : i32)
    ^bb498:  // pred: ^bb496
      cf.br ^bb499(%c0_i32 : i32)
    ^bb499(%1725: i32):  // 2 preds: ^bb498, ^bb506
      %1726 = arith.cmpi slt, %1725, %657 : i32
      cf.cond_br %1726, ^bb500, ^bb507 {llvm.loop_annotation = #loop_annotation}
    ^bb500:  // pred: ^bb499
      cf.br ^bb501(%c0_i32 : i32)
    ^bb501(%1727: i32):  // 2 preds: ^bb500, ^bb505
      %1728 = arith.cmpi slt, %1727, %607 : i32
      cf.cond_br %1728, ^bb502, ^bb506 {llvm.loop_annotation = #loop_annotation}
    ^bb502:  // pred: ^bb501
      %coord_1235 = cute.make_coord(%1727, %1725) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1236 = cute.crd2idx(%coord_1235, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1237 = cute.add_offset(%ptr_658, %idx_1236) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1729 = builtin.unrealized_conversion_cast %ptr_1237 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1730 = llvm.getelementptr %1729[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1731 = llvm.getelementptr %1729[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1732 = llvm.getelementptr %1729[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb503(%c0_i32 : i32)
    ^bb503(%1733: i32):  // 2 preds: ^bb502, ^bb504
      %1734 = arith.cmpi slt, %1733, %658 : i32
      cf.cond_br %1734, ^bb504, ^bb505 {llvm.loop_annotation = #loop_annotation}
    ^bb504:  // pred: ^bb503
      %coord_1238 = cute.make_coord(%1733, %1725) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1239 = cute.make_coord(%1727, %1733) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1240 = cute.crd2idx(%coord_1238, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1241 = cute.add_offset(%ptr_669, %idx_1240) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1242 = cute.crd2idx(%coord_1239, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1243 = cute.add_offset(%iter_1065, %idx_1242) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1735 = llvm.load %1729 : !llvm.ptr -> i32
      %1736 = llvm.load %1730 : !llvm.ptr -> i32
      %1737 = llvm.load %1731 : !llvm.ptr -> i32
      %1738 = llvm.load %1732 : !llvm.ptr -> i32
      %1739 = builtin.unrealized_conversion_cast %ptr_1241 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1740 = llvm.load %1739 : !llvm.ptr -> i32
      %1741 = llvm.getelementptr %1739[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1742 = llvm.load %1741 : !llvm.ptr -> i32
      %1743 = builtin.unrealized_conversion_cast %ptr_1243 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1744 = llvm.load %1743 : !llvm.ptr -> f32
      %1745 = llvm.getelementptr %1743[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1746 = llvm.load %1745 : !llvm.ptr -> f32
      %1747 = llvm.getelementptr %1743[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1748 = llvm.load %1747 : !llvm.ptr -> f32
      %1749 = llvm.getelementptr %1743[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1750 = llvm.load %1749 : !llvm.ptr -> f32
      %1751:4 = cute_nvgpu.arch.mma.SM80 A[%1735, %1736, %1737, %1738]  B[%1740, %1742]  C[%1744, %1746, %1748, %1750] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1751#0, %1743 : f32, !llvm.ptr
      llvm.store %1751#1, %1745 : f32, !llvm.ptr
      llvm.store %1751#2, %1747 : f32, !llvm.ptr
      llvm.store %1751#3, %1749 : f32, !llvm.ptr
      %1752 = arith.addi %1733, %c1_i32 : i32
      cf.br ^bb503(%1752 : i32)
    ^bb505:  // pred: ^bb503
      %1753 = arith.addi %1727, %c1_i32 : i32
      cf.br ^bb501(%1753 : i32)
    ^bb506:  // pred: ^bb501
      %1754 = arith.addi %1725, %c1_i32 : i32
      cf.br ^bb499(%1754 : i32)
    ^bb507:  // pred: ^bb499
      cf.br ^bb508(%c0_i32 : i32)
    ^bb508(%1755: i32):  // 2 preds: ^bb507, ^bb509
      %1756 = arith.cmpi slt, %1755, %607 : i32
      cf.cond_br %1756, ^bb509, ^bb510 {llvm.loop_annotation = #loop_annotation}
    ^bb509:  // pred: ^bb508
      %coord_1244 = cute.make_coord(%1755) : (i32) -> !cute.coord<"(_,?)">
      %idx_1245 = cute.crd2idx(%coord_1244, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1246 = cute.add_offset(%ptr_719, %idx_1245) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1247 = cute.crd2idx(%coord_1244, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1248 = cute.add_offset(%ptr_720, %idx_1247) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1757 = cute_nvgpu.arch.copy.ldsm %ptr_1246{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1758 = vector.extractelement %1757[%130 : i32] : vector<4xi32>
      %1759 = builtin.unrealized_conversion_cast %ptr_1248 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1758, %1759 : i32, !llvm.ptr
      %1760 = vector.extractelement %1757[%129 : i32] : vector<4xi32>
      %ptr_1249 = cute.add_offset(%ptr_1248, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1761 = builtin.unrealized_conversion_cast %ptr_1249 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1760, %1761 : i32, !llvm.ptr
      %1762 = vector.extractelement %1757[%128 : i32] : vector<4xi32>
      %ptr_1250 = cute.add_offset(%ptr_1248, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1763 = builtin.unrealized_conversion_cast %ptr_1250 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1762, %1763 : i32, !llvm.ptr
      %1764 = vector.extractelement %1757[%126 : i32] : vector<4xi32>
      %ptr_1251 = cute.add_offset(%ptr_1248, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1765 = builtin.unrealized_conversion_cast %ptr_1251 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1764, %1765 : i32, !llvm.ptr
      %1766 = arith.addi %1755, %c1_i32 : i32
      cf.br ^bb508(%1766 : i32)
    ^bb510:  // pred: ^bb508
      cf.br ^bb511(%c0_i32 : i32)
    ^bb511(%1767: i32):  // 2 preds: ^bb510, ^bb512
      %1768 = arith.cmpi slt, %1767, %620 : i32
      cf.cond_br %1768, ^bb512, ^bb513 {llvm.loop_annotation = #loop_annotation}
    ^bb512:  // pred: ^bb511
      %coord_1252 = cute.make_coord(%1767) : (i32) -> !cute.coord<"(_,?)">
      %idx_1253 = cute.crd2idx(%coord_1252, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1254 = cute.add_offset(%ptr_730, %idx_1253) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1255 = cute.crd2idx(%coord_1252, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1256 = cute.add_offset(%ptr_731, %idx_1255) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1769 = cute_nvgpu.arch.copy.ldsm %ptr_1254{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1770 = vector.extractelement %1769[%130 : i32] : vector<4xi32>
      %1771 = builtin.unrealized_conversion_cast %ptr_1256 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1770, %1771 : i32, !llvm.ptr
      %1772 = vector.extractelement %1769[%129 : i32] : vector<4xi32>
      %ptr_1257 = cute.add_offset(%ptr_1256, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1773 = builtin.unrealized_conversion_cast %ptr_1257 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1772, %1773 : i32, !llvm.ptr
      %1774 = vector.extractelement %1769[%128 : i32] : vector<4xi32>
      %ptr_1258 = cute.add_offset(%ptr_1256, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1775 = builtin.unrealized_conversion_cast %ptr_1258 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1774, %1775 : i32, !llvm.ptr
      %1776 = vector.extractelement %1769[%126 : i32] : vector<4xi32>
      %ptr_1259 = cute.add_offset(%ptr_1256, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1777 = builtin.unrealized_conversion_cast %ptr_1259 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1776, %1777 : i32, !llvm.ptr
      %1778 = arith.addi %1767, %c1_i32 : i32
      cf.br ^bb511(%1778 : i32)
    ^bb513:  // pred: ^bb511
      cf.br ^bb514(%c0_i32 : i32)
    ^bb514(%1779: i32):  // 2 preds: ^bb513, ^bb521
      %1780 = arith.cmpi slt, %1779, %657 : i32
      cf.cond_br %1780, ^bb515, ^bb522 {llvm.loop_annotation = #loop_annotation}
    ^bb515:  // pred: ^bb514
      cf.br ^bb516(%c0_i32 : i32)
    ^bb516(%1781: i32):  // 2 preds: ^bb515, ^bb520
      %1782 = arith.cmpi slt, %1781, %607 : i32
      cf.cond_br %1782, ^bb517, ^bb521 {llvm.loop_annotation = #loop_annotation}
    ^bb517:  // pred: ^bb516
      %coord_1260 = cute.make_coord(%1781, %1779) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1261 = cute.crd2idx(%coord_1260, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1262 = cute.add_offset(%ptr_689, %idx_1261) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1783 = builtin.unrealized_conversion_cast %ptr_1262 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1784 = llvm.getelementptr %1783[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1785 = llvm.getelementptr %1783[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1786 = llvm.getelementptr %1783[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb518(%c0_i32 : i32)
    ^bb518(%1787: i32):  // 2 preds: ^bb517, ^bb519
      %1788 = arith.cmpi slt, %1787, %658 : i32
      cf.cond_br %1788, ^bb519, ^bb520 {llvm.loop_annotation = #loop_annotation}
    ^bb519:  // pred: ^bb518
      %coord_1263 = cute.make_coord(%1787, %1779) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1264 = cute.make_coord(%1781, %1787) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1265 = cute.crd2idx(%coord_1263, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1266 = cute.add_offset(%ptr_700, %idx_1265) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1267 = cute.crd2idx(%coord_1264, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1268 = cute.add_offset(%iter_1065, %idx_1267) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1789 = llvm.load %1783 : !llvm.ptr -> i32
      %1790 = llvm.load %1784 : !llvm.ptr -> i32
      %1791 = llvm.load %1785 : !llvm.ptr -> i32
      %1792 = llvm.load %1786 : !llvm.ptr -> i32
      %1793 = builtin.unrealized_conversion_cast %ptr_1266 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1794 = llvm.load %1793 : !llvm.ptr -> i32
      %1795 = llvm.getelementptr %1793[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1796 = llvm.load %1795 : !llvm.ptr -> i32
      %1797 = builtin.unrealized_conversion_cast %ptr_1268 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1798 = llvm.load %1797 : !llvm.ptr -> f32
      %1799 = llvm.getelementptr %1797[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1800 = llvm.load %1799 : !llvm.ptr -> f32
      %1801 = llvm.getelementptr %1797[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1802 = llvm.load %1801 : !llvm.ptr -> f32
      %1803 = llvm.getelementptr %1797[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1804 = llvm.load %1803 : !llvm.ptr -> f32
      %1805:4 = cute_nvgpu.arch.mma.SM80 A[%1789, %1790, %1791, %1792]  B[%1794, %1796]  C[%1798, %1800, %1802, %1804] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1805#0, %1797 : f32, !llvm.ptr
      llvm.store %1805#1, %1799 : f32, !llvm.ptr
      llvm.store %1805#2, %1801 : f32, !llvm.ptr
      llvm.store %1805#3, %1803 : f32, !llvm.ptr
      %1806 = arith.addi %1787, %c1_i32 : i32
      cf.br ^bb518(%1806 : i32)
    ^bb520:  // pred: ^bb518
      %1807 = arith.addi %1781, %c1_i32 : i32
      cf.br ^bb516(%1807 : i32)
    ^bb521:  // pred: ^bb516
      %1808 = arith.addi %1779, %c1_i32 : i32
      cf.br ^bb514(%1808 : i32)
    ^bb522:  // pred: ^bb514
      cf.br ^bb523(%c0_i32 : i32)
    ^bb523(%1809: i32):  // 2 preds: ^bb522, ^bb524
      %1810 = arith.cmpi slt, %1809, %607 : i32
      cf.cond_br %1810, ^bb524, ^bb525 {llvm.loop_annotation = #loop_annotation}
    ^bb524:  // pred: ^bb523
      %coord_1269 = cute.make_coord(%1809) : (i32) -> !cute.coord<"(_,?)">
      %idx_1270 = cute.crd2idx(%coord_1269, %139) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1271 = cute.add_offset(%ptr_122, %idx_1270) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1272 = cute.crd2idx(%coord_1269, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1273 = cute.add_offset(%iter_127, %idx_1272) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1811 = cute_nvgpu.arch.copy.ldsm %ptr_1271{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1812 = vector.extractelement %1811[%130 : i32] : vector<4xi32>
      %1813 = builtin.unrealized_conversion_cast %ptr_1273 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %1812, %1813 : i32, !llvm.ptr
      %1814 = vector.extractelement %1811[%129 : i32] : vector<4xi32>
      %ptr_1274 = cute.add_offset(%ptr_1273, %161) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1815 = builtin.unrealized_conversion_cast %ptr_1274 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1814, %1815 : i32, !llvm.ptr
      %1816 = vector.extractelement %1811[%128 : i32] : vector<4xi32>
      %ptr_1275 = cute.add_offset(%ptr_1273, %127) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1817 = builtin.unrealized_conversion_cast %ptr_1275 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1816, %1817 : i32, !llvm.ptr
      %1818 = vector.extractelement %1811[%126 : i32] : vector<4xi32>
      %ptr_1276 = cute.add_offset(%ptr_1273, %125) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1819 = builtin.unrealized_conversion_cast %ptr_1276 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1818, %1819 : i32, !llvm.ptr
      %1820 = arith.addi %1809, %c1_i32 : i32
      cf.br ^bb523(%1820 : i32)
    ^bb525:  // pred: ^bb523
      cf.br ^bb526(%c0_i32 : i32)
    ^bb526(%1821: i32):  // 2 preds: ^bb525, ^bb527
      %1822 = arith.cmpi slt, %1821, %620 : i32
      cf.cond_br %1822, ^bb527, ^bb528 {llvm.loop_annotation = #loop_annotation}
    ^bb527:  // pred: ^bb526
      %coord_1277 = cute.make_coord(%1821) : (i32) -> !cute.coord<"(_,?)">
      %idx_1278 = cute.crd2idx(%coord_1277, %124) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1279 = cute.add_offset(%ptr_130, %idx_1278) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1280 = cute.crd2idx(%coord_1277, %123) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1281 = cute.add_offset(%iter_135, %idx_1280) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1823 = cute_nvgpu.arch.copy.ldsm %ptr_1279{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1824 = vector.extractelement %1823[%130 : i32] : vector<4xi32>
      %1825 = builtin.unrealized_conversion_cast %ptr_1281 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1824, %1825 : i32, !llvm.ptr
      %1826 = vector.extractelement %1823[%129 : i32] : vector<4xi32>
      %ptr_1282 = cute.add_offset(%ptr_1281, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1827 = builtin.unrealized_conversion_cast %ptr_1282 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1826, %1827 : i32, !llvm.ptr
      %1828 = vector.extractelement %1823[%128 : i32] : vector<4xi32>
      %ptr_1283 = cute.add_offset(%ptr_1281, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1829 = builtin.unrealized_conversion_cast %ptr_1283 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1828, %1829 : i32, !llvm.ptr
      %1830 = vector.extractelement %1823[%126 : i32] : vector<4xi32>
      %ptr_1284 = cute.add_offset(%ptr_1281, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1831 = builtin.unrealized_conversion_cast %ptr_1284 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1830, %1831 : i32, !llvm.ptr
      %1832 = arith.addi %1821, %c1_i32 : i32
      cf.br ^bb526(%1832 : i32)
    ^bb528:  // pred: ^bb526
      cf.br ^bb529(%c0_i32 : i32)
    ^bb529(%1833: i32):  // 2 preds: ^bb528, ^bb536
      %1834 = arith.cmpi slt, %1833, %657 : i32
      cf.cond_br %1834, ^bb530, ^bb537 {llvm.loop_annotation = #loop_annotation}
    ^bb530:  // pred: ^bb529
      cf.br ^bb531(%c0_i32 : i32)
    ^bb531(%1835: i32):  // 2 preds: ^bb530, ^bb535
      %1836 = arith.cmpi slt, %1835, %607 : i32
      cf.cond_br %1836, ^bb532, ^bb536 {llvm.loop_annotation = #loop_annotation}
    ^bb532:  // pred: ^bb531
      %coord_1285 = cute.make_coord(%1835, %1833) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1286 = cute.crd2idx(%coord_1285, %119) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1287 = cute.add_offset(%ptr_720, %idx_1286) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %1837 = builtin.unrealized_conversion_cast %ptr_1287 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1838 = llvm.getelementptr %1837[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1839 = llvm.getelementptr %1837[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1840 = llvm.getelementptr %1837[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb533(%c0_i32 : i32)
    ^bb533(%1841: i32):  // 2 preds: ^bb532, ^bb534
      %1842 = arith.cmpi slt, %1841, %658 : i32
      cf.cond_br %1842, ^bb534, ^bb535 {llvm.loop_annotation = #loop_annotation}
    ^bb534:  // pred: ^bb533
      %coord_1288 = cute.make_coord(%1841, %1833) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1289 = cute.make_coord(%1835, %1841) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1290 = cute.crd2idx(%coord_1288, %118) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1291 = cute.add_offset(%ptr_731, %idx_1290) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1292 = cute.crd2idx(%coord_1289, %138) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,8):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1293 = cute.add_offset(%iter_1065, %idx_1292) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1843 = llvm.load %1837 : !llvm.ptr -> i32
      %1844 = llvm.load %1838 : !llvm.ptr -> i32
      %1845 = llvm.load %1839 : !llvm.ptr -> i32
      %1846 = llvm.load %1840 : !llvm.ptr -> i32
      %1847 = builtin.unrealized_conversion_cast %ptr_1291 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1848 = llvm.load %1847 : !llvm.ptr -> i32
      %1849 = llvm.getelementptr %1847[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1850 = llvm.load %1849 : !llvm.ptr -> i32
      %1851 = builtin.unrealized_conversion_cast %ptr_1293 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1852 = llvm.load %1851 : !llvm.ptr -> f32
      %1853 = llvm.getelementptr %1851[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1854 = llvm.load %1853 : !llvm.ptr -> f32
      %1855 = llvm.getelementptr %1851[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1856 = llvm.load %1855 : !llvm.ptr -> f32
      %1857 = llvm.getelementptr %1851[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1858 = llvm.load %1857 : !llvm.ptr -> f32
      %1859:4 = cute_nvgpu.arch.mma.SM80 A[%1843, %1844, %1845, %1846]  B[%1848, %1850]  C[%1852, %1854, %1856, %1858] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1859#0, %1851 : f32, !llvm.ptr
      llvm.store %1859#1, %1853 : f32, !llvm.ptr
      llvm.store %1859#2, %1855 : f32, !llvm.ptr
      llvm.store %1859#3, %1857 : f32, !llvm.ptr
      %1860 = arith.addi %1841, %c1_i32 : i32
      cf.br ^bb533(%1860 : i32)
    ^bb535:  // pred: ^bb533
      %1861 = arith.addi %1835, %c1_i32 : i32
      cf.br ^bb531(%1861 : i32)
    ^bb536:  // pred: ^bb531
      %1862 = arith.addi %1833, %c1_i32 : i32
      cf.br ^bb529(%1862 : i32)
    ^bb537:  // pred: ^bb529
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %1863 = arith.cmpi sgt, %1400, %c0_i32 : i32
      cf.cond_br %1863, ^bb538, ^bb542
    ^bb538:  // pred: ^bb537
      %1864 = arith.subi %1399, %c2_i32 : i32
      %coord_1294 = cute.make_coord(%1864) : (i32) -> !cute.coord<"(_,_,_,?)">
      %1865:3 = cute.get_scalars(%lay_104) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_1295 = cute.assume(%1865#1) : (i64) -> !cute.i64<divby 128>
      %stride_1296 = cute.make_stride(%iv_1295) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1297 = cute.make_layout(%137, %stride_1296) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_1298 = cute.crd2idx(%coord_1294, %lay_104) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1299 = cute.add_offset(%ptr_99, %idx_1298) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %append_1300 = cute.append_to_rank<2> (%lay_1297, %181) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1866 = cute.get_scalars(%append_1300) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_1301 = cute.assume(%1866) : (i64) -> !cute.i64<divby 128>
      %stride_1302 = cute.make_stride(%iv_1301) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_1303 = cute.make_layout(%136, %stride_1302) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_1304 = cute.append_to_rank<2> (%lay_1303, %181) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1867 = cute.get_scalars(%append_1304) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_1305 = cute.assume(%1867) : (i64) -> !cute.i64<divby 128>
      %stride_1306 = cute.make_stride(%iv_1305) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_1307 = cute.make_layout(%135, %stride_1306) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb539(%c0_i32 : i32)
    ^bb539(%1868: i32):  // 2 preds: ^bb538, ^bb540
      %1869 = arith.cmpi slt, %1868, %658 : i32
      cf.cond_br %1869, ^bb540, ^bb541 {llvm.loop_annotation = #loop_annotation}
    ^bb540:  // pred: ^bb539
      %coord_1308 = cute.make_coord(%1868) : (i32) -> !cute.coord<"(_,?)">
      %idx_1309 = cute.crd2idx(%coord_1308, %lay_1307) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_1310 = cute.add_offset(%ptr_1299, %idx_1309) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1311 = cute.crd2idx(%coord_1308, %134) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1312 = cute.add_offset(%ptr_105, %idx_1311) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1313 = cute.crd2idx(%coord_1308, %133) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_1314 = cute.add_offset(%iter_194, %idx_1313) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1870 = builtin.unrealized_conversion_cast %ptr_1314 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1871 = llvm.load %1870 : !llvm.ptr -> i8
      %1872 = llvm.trunc %1871 : i8 to i1
      %iter_1315 = cute.recast_iter(%ptr_1310) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_1316 = cute.recast_iter(%ptr_1312) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_1316 : !cute.ptr<i128, smem>, %iter_1315 : !cute.ptr<i128, gmem>, %1872 : i1) {cache_mode = <global>}
      %1873 = arith.addi %1868, %c1_i32 : i32
      cf.br ^bb539(%1873 : i32)
    ^bb541:  // pred: ^bb539
      nvvm.cp.async.commit.group
      cf.br ^bb542
    ^bb542:  // 2 preds: ^bb537, ^bb541
      %rmem_1317 = cute.memref.alloca() : !memref_rmem_f32_1
      %iter_1318 = cute.get_iter(%rmem_1317) : !memref_rmem_f32_1
      %1874 = builtin.unrealized_conversion_cast %iter_1318 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_1319 = cute.add_offset(%iter_1318, %117) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %1875 = builtin.unrealized_conversion_cast %ptr_1319 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_1320 = cute.add_offset(%iter_1318, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %1876 = builtin.unrealized_conversion_cast %ptr_1320 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_1321 = cute.add_offset(%iter_1318, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %1877 = builtin.unrealized_conversion_cast %ptr_1321 : !cute.ptr<f32, rmem> to !llvm.ptr
      cf.br ^bb543(%c0_i32 : i32)
    ^bb543(%1878: i32):  // 2 preds: ^bb542, ^bb544
      %1879 = arith.cmpi slt, %1878, %657 : i32
      cf.cond_br %1879, ^bb544, ^bb545 {llvm.loop_annotation = #loop_annotation}
    ^bb544:  // pred: ^bb543
      %1880 = llvm.load %1393 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1880, %1874 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1881 = llvm.load %1394 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1881, %1875 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1882 = llvm.load %1395 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1882, %1876 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1883 = llvm.load %1396 {alignment = 16 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %1883, %1877 {alignment = 16 : i64} : vector<1xf32>, !llvm.ptr
      %1884 = arith.addi %1878, %c1_i32 : i32
      cf.br ^bb543(%1884 : i32)
    ^bb545:  // pred: ^bb543
      %view_1322 = cute.make_view(%iter_1065) : !memref_rmem_f32_4
      %1885 = cute.memref.load_vec %view_1322 : !memref_rmem_f32_4
      %1886 = vector.reduction <maximumf>, %1885, %cst_5 : vector<16xf32> into f32
      %1887 = nvvm.shfl.sync  bfly %c-1_i32, %1886, %c2_i32, %c31_i32 : f32 -> f32
      %1888 = nvvm.fmax %1886, %1887
      %1889 = nvvm.shfl.sync  bfly %c-1_i32, %1888, %c1_i32, %c31_i32 : f32 -> f32
      %1890 = nvvm.fmax %1888, %1889
      %1891 = cute.memref.load(%rmem_1317, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1892 = nvvm.fmax %1891, %1890
      %1893 = arith.mulf %1885, %1161 : vector<16xf32>
      %1894 = arith.mulf %1892, %arg4 : f32
      %1895 = vector.broadcast %1894 : f32 to vector<16xf32>
      %1896 = arith.subf %1893, %1895 : vector<16xf32>
      %1897 = math.exp2 %1896 fastmath<fast> : vector<16xf32>
      %1898 = vector.reduction <add>, %1897, %cst_6 : vector<16xf32> into f32
      %1899 = arith.mulf %1891, %arg4 : f32
      %1900 = arith.subf %1899, %1894 : f32
      %1901 = math.exp2 %1900 fastmath<fast> : f32
      %1902 = cute.memref.load(%rmem_457, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %1903 = arith.mulf %1902, %1901 : f32
      %1904 = arith.addf %1903, %1898 : f32
      %1905 = cute.memref.load_vec %view_1057 : !memref_rmem_f32_7
      %1906 = vector.broadcast %1901 : f32 to vector<32xf32>
      %1907 = arith.mulf %1905, %1906 : vector<32xf32>
      cute.memref.store_vec %1907, %view_1057 : !memref_rmem_f32_7
      cute.memref.store(%rmem_456, %68, %1892) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store(%rmem_457, %68, %1904) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      cute.memref.store_vec %1897, %view_1322 : !memref_rmem_f32_4
      %ptr_1323 = cute.add_offset(%iter_1065, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1324 = cute.make_view(%ptr_1323) : !memref_rmem_f32_5
      %1908 = cute.memref.load_vec %view_1324 : !memref_rmem_f32_5
      %1909 = vector.reduction <maximumf>, %1908, %cst_5 : vector<16xf32> into f32
      %1910 = nvvm.shfl.sync  bfly %c-1_i32, %1909, %c2_i32, %c31_i32 : f32 -> f32
      %1911 = nvvm.fmax %1909, %1910
      %1912 = nvvm.shfl.sync  bfly %c-1_i32, %1911, %c1_i32, %c31_i32 : f32 -> f32
      %1913 = nvvm.fmax %1911, %1912
      %1914 = cute.memref.load(%rmem_1317, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1915 = nvvm.fmax %1914, %1913
      %1916 = arith.mulf %1908, %1161 : vector<16xf32>
      %1917 = arith.mulf %1915, %arg4 : f32
      %1918 = vector.broadcast %1917 : f32 to vector<16xf32>
      %1919 = arith.subf %1916, %1918 : vector<16xf32>
      %1920 = math.exp2 %1919 fastmath<fast> : vector<16xf32>
      %1921 = vector.reduction <add>, %1920, %cst_6 : vector<16xf32> into f32
      %1922 = arith.mulf %1914, %arg4 : f32
      %1923 = arith.subf %1922, %1917 : f32
      %1924 = math.exp2 %1923 fastmath<fast> : f32
      %1925 = cute.memref.load(%rmem_457, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %1926 = arith.mulf %1925, %1924 : f32
      %1927 = arith.addf %1926, %1921 : f32
      %1928 = cute.memref.load_vec %view_1059 : !memref_rmem_f32_8
      %1929 = vector.broadcast %1924 : f32 to vector<32xf32>
      %1930 = arith.mulf %1928, %1929 : vector<32xf32>
      cute.memref.store_vec %1930, %view_1059 : !memref_rmem_f32_8
      cute.memref.store(%rmem_456, %51, %1915) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store(%rmem_457, %51, %1927) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      cute.memref.store_vec %1920, %view_1324 : !memref_rmem_f32_5
      %ptr_1325 = cute.add_offset(%iter_1065, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1326 = cute.make_view(%ptr_1325) : !memref_rmem_f32_6
      %1931 = cute.memref.load_vec %view_1326 : !memref_rmem_f32_6
      %1932 = vector.reduction <maximumf>, %1931, %cst_5 : vector<16xf32> into f32
      %1933 = nvvm.shfl.sync  bfly %c-1_i32, %1932, %c2_i32, %c31_i32 : f32 -> f32
      %1934 = nvvm.fmax %1932, %1933
      %1935 = nvvm.shfl.sync  bfly %c-1_i32, %1934, %c1_i32, %c31_i32 : f32 -> f32
      %1936 = nvvm.fmax %1934, %1935
      %1937 = cute.memref.load(%rmem_1317, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1938 = nvvm.fmax %1937, %1936
      %1939 = arith.mulf %1931, %1161 : vector<16xf32>
      %1940 = arith.mulf %1938, %arg4 : f32
      %1941 = vector.broadcast %1940 : f32 to vector<16xf32>
      %1942 = arith.subf %1939, %1941 : vector<16xf32>
      %1943 = math.exp2 %1942 fastmath<fast> : vector<16xf32>
      %1944 = vector.reduction <add>, %1943, %cst_6 : vector<16xf32> into f32
      %1945 = arith.mulf %1937, %arg4 : f32
      %1946 = arith.subf %1945, %1940 : f32
      %1947 = math.exp2 %1946 fastmath<fast> : f32
      %1948 = cute.memref.load(%rmem_457, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %1949 = arith.mulf %1948, %1947 : f32
      %1950 = arith.addf %1949, %1944 : f32
      %1951 = cute.memref.load_vec %view_1061 : !memref_rmem_f32_9
      %1952 = vector.broadcast %1947 : f32 to vector<32xf32>
      %1953 = arith.mulf %1951, %1952 : vector<32xf32>
      cute.memref.store_vec %1953, %view_1061 : !memref_rmem_f32_9
      cute.memref.store(%rmem_456, %34, %1938) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store(%rmem_457, %34, %1950) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      cute.memref.store_vec %1943, %view_1326 : !memref_rmem_f32_6
      %ptr_1327 = cute.add_offset(%iter_1065, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1328 = cute.make_view(%ptr_1327) : !memref_rmem_f32_5
      %1954 = cute.memref.load_vec %view_1328 : !memref_rmem_f32_5
      %1955 = vector.reduction <maximumf>, %1954, %cst_5 : vector<16xf32> into f32
      %1956 = nvvm.shfl.sync  bfly %c-1_i32, %1955, %c2_i32, %c31_i32 : f32 -> f32
      %1957 = nvvm.fmax %1955, %1956
      %1958 = nvvm.shfl.sync  bfly %c-1_i32, %1957, %c1_i32, %c31_i32 : f32 -> f32
      %1959 = nvvm.fmax %1957, %1958
      %1960 = cute.memref.load(%rmem_1317, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1961 = nvvm.fmax %1960, %1959
      %1962 = arith.mulf %1954, %1161 : vector<16xf32>
      %1963 = arith.mulf %1961, %arg4 : f32
      %1964 = vector.broadcast %1963 : f32 to vector<16xf32>
      %1965 = arith.subf %1962, %1964 : vector<16xf32>
      %1966 = math.exp2 %1965 fastmath<fast> : vector<16xf32>
      %1967 = vector.reduction <add>, %1966, %cst_6 : vector<16xf32> into f32
      %1968 = arith.mulf %1960, %arg4 : f32
      %1969 = arith.subf %1968, %1963 : f32
      %1970 = math.exp2 %1969 fastmath<fast> : f32
      %1971 = cute.memref.load(%rmem_457, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %1972 = arith.mulf %1971, %1970 : f32
      %1973 = arith.addf %1972, %1967 : f32
      %1974 = cute.memref.load_vec %view_1063 : !memref_rmem_f32_8
      %1975 = vector.broadcast %1970 : f32 to vector<32xf32>
      %1976 = arith.mulf %1974, %1975 : vector<32xf32>
      cute.memref.store_vec %1976, %view_1063 : !memref_rmem_f32_8
      cute.memref.store(%rmem_456, %17, %1961) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store(%rmem_457, %17, %1973) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      cute.memref.store_vec %1966, %view_1328 : !memref_rmem_f32_5
      %rmem_1329 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_1330 = cute.get_iter(%rmem_1329) : !memref_rmem_bf16_3
      %1977 = cute.memref.load_vec %rmem_1064 : !memref_rmem_f32_2
      %1978 = arith.truncf %1977 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1978, %rmem_1329 : !memref_rmem_bf16_3
      cf.br ^bb546(%c0_i32 : i32)
    ^bb546(%1979: i32):  // 2 preds: ^bb545, ^bb547
      %1980 = arith.cmpi slt, %1979, %658 : i32
      cf.cond_br %1980, ^bb547, ^bb548 {llvm.loop_annotation = #loop_annotation}
    ^bb547:  // pred: ^bb546
      %coord_1331 = cute.make_coord(%1979) : (i32) -> !cute.coord<"(_,?)">
      %idx_1332 = cute.crd2idx(%coord_1331, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1333 = cute.add_offset(%ptr_138, %idx_1332) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1334 = cute.crd2idx(%coord_1331, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1335 = cute.add_offset(%iter_141, %idx_1334) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1981 = cute_nvgpu.arch.copy.ldsm %ptr_1333{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1982 = vector.extractelement %1981[%130 : i32] : vector<4xi32>
      %1983 = builtin.unrealized_conversion_cast %ptr_1335 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1982, %1983 : i32, !llvm.ptr
      %1984 = vector.extractelement %1981[%129 : i32] : vector<4xi32>
      %ptr_1336 = cute.add_offset(%ptr_1335, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1985 = builtin.unrealized_conversion_cast %ptr_1336 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1984, %1985 : i32, !llvm.ptr
      %1986 = vector.extractelement %1981[%128 : i32] : vector<4xi32>
      %ptr_1337 = cute.add_offset(%ptr_1335, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1987 = builtin.unrealized_conversion_cast %ptr_1337 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1986, %1987 : i32, !llvm.ptr
      %1988 = vector.extractelement %1981[%126 : i32] : vector<4xi32>
      %ptr_1338 = cute.add_offset(%ptr_1335, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1989 = builtin.unrealized_conversion_cast %ptr_1338 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1988, %1989 : i32, !llvm.ptr
      %1990 = arith.addi %1979, %c1_i32 : i32
      cf.br ^bb546(%1990 : i32)
    ^bb548:  // pred: ^bb546
      cf.br ^bb549(%c0_i32 : i32)
    ^bb549(%1991: i32):  // 2 preds: ^bb548, ^bb550
      %1992 = arith.cmpi slt, %1991, %658 : i32
      cf.cond_br %1992, ^bb550, ^bb551 {llvm.loop_annotation = #loop_annotation}
    ^bb550:  // pred: ^bb549
      %coord_1339 = cute.make_coord(%1991) : (i32) -> !cute.coord<"(_,?)">
      %idx_1340 = cute.crd2idx(%coord_1339, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1341 = cute.add_offset(%ptr_965, %idx_1340) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1342 = cute.crd2idx(%coord_1339, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1343 = cute.add_offset(%ptr_966, %idx_1342) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1993 = cute_nvgpu.arch.copy.ldsm %ptr_1341{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1994 = vector.extractelement %1993[%130 : i32] : vector<4xi32>
      %1995 = builtin.unrealized_conversion_cast %ptr_1343 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1994, %1995 : i32, !llvm.ptr
      %1996 = vector.extractelement %1993[%129 : i32] : vector<4xi32>
      %ptr_1344 = cute.add_offset(%ptr_1343, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1997 = builtin.unrealized_conversion_cast %ptr_1344 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1996, %1997 : i32, !llvm.ptr
      %1998 = vector.extractelement %1993[%128 : i32] : vector<4xi32>
      %ptr_1345 = cute.add_offset(%ptr_1343, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1999 = builtin.unrealized_conversion_cast %ptr_1345 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1998, %1999 : i32, !llvm.ptr
      %2000 = vector.extractelement %1993[%126 : i32] : vector<4xi32>
      %ptr_1346 = cute.add_offset(%ptr_1343, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %2001 = builtin.unrealized_conversion_cast %ptr_1346 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2000, %2001 : i32, !llvm.ptr
      %2002 = arith.addi %1991, %c1_i32 : i32
      cf.br ^bb549(%2002 : i32)
    ^bb551:  // pred: ^bb549
      cf.br ^bb552(%c0_i32 : i32)
    ^bb552(%2003: i32):  // 2 preds: ^bb551, ^bb559
      %2004 = arith.cmpi slt, %2003, %657 : i32
      cf.cond_br %2004, ^bb553, ^bb560 {llvm.loop_annotation = #loop_annotation}
    ^bb553:  // pred: ^bb552
      cf.br ^bb554(%c0_i32 : i32)
    ^bb554(%2005: i32):  // 2 preds: ^bb553, ^bb558
      %2006 = arith.cmpi slt, %2005, %607 : i32
      cf.cond_br %2006, ^bb555, ^bb559 {llvm.loop_annotation = #loop_annotation}
    ^bb555:  // pred: ^bb554
      %coord_1347 = cute.make_coord(%2005, %2003) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1348 = cute.crd2idx(%coord_1347, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1349 = cute.add_offset(%iter_1330, %idx_1348) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2007 = builtin.unrealized_conversion_cast %ptr_1349 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2008 = llvm.getelementptr %2007[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2009 = llvm.getelementptr %2007[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %2010 = llvm.getelementptr %2007[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb556(%c0_i32 : i32)
    ^bb556(%2011: i32):  // 2 preds: ^bb555, ^bb557
      %2012 = arith.cmpi slt, %2011, %1233 : i32
      cf.cond_br %2012, ^bb557, ^bb558 {llvm.loop_annotation = #loop_annotation}
    ^bb557:  // pred: ^bb556
      %coord_1350 = cute.make_coord(%2011, %2003) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1351 = cute.make_coord(%2005, %2011) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1352 = cute.crd2idx(%coord_1350, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1353 = cute.add_offset(%iter_141, %idx_1352) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1354 = cute.crd2idx(%coord_1351, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1355 = cute.add_offset(%iter_118, %idx_1354) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %2013 = llvm.load %2007 : !llvm.ptr -> i32
      %2014 = llvm.load %2008 : !llvm.ptr -> i32
      %2015 = llvm.load %2009 : !llvm.ptr -> i32
      %2016 = llvm.load %2010 : !llvm.ptr -> i32
      %2017 = builtin.unrealized_conversion_cast %ptr_1353 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2018 = llvm.load %2017 : !llvm.ptr -> i32
      %2019 = llvm.getelementptr %2017[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2020 = llvm.load %2019 : !llvm.ptr -> i32
      %2021 = builtin.unrealized_conversion_cast %ptr_1355 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %2022 = llvm.load %2021 : !llvm.ptr -> f32
      %2023 = llvm.getelementptr %2021[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %2024 = llvm.load %2023 : !llvm.ptr -> f32
      %2025 = llvm.getelementptr %2021[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %2026 = llvm.load %2025 : !llvm.ptr -> f32
      %2027 = llvm.getelementptr %2021[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %2028 = llvm.load %2027 : !llvm.ptr -> f32
      %2029:4 = cute_nvgpu.arch.mma.SM80 A[%2013, %2014, %2015, %2016]  B[%2018, %2020]  C[%2022, %2024, %2026, %2028] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %2029#0, %2021 : f32, !llvm.ptr
      llvm.store %2029#1, %2023 : f32, !llvm.ptr
      llvm.store %2029#2, %2025 : f32, !llvm.ptr
      llvm.store %2029#3, %2027 : f32, !llvm.ptr
      %2030 = arith.addi %2011, %c1_i32 : i32
      cf.br ^bb556(%2030 : i32)
    ^bb558:  // pred: ^bb556
      %2031 = arith.addi %2005, %c1_i32 : i32
      cf.br ^bb554(%2031 : i32)
    ^bb559:  // pred: ^bb554
      %2032 = arith.addi %2003, %c1_i32 : i32
      cf.br ^bb552(%2032 : i32)
    ^bb560:  // pred: ^bb552
      cf.br ^bb561(%c0_i32 : i32)
    ^bb561(%2033: i32):  // 2 preds: ^bb560, ^bb562
      %2034 = arith.cmpi slt, %2033, %658 : i32
      cf.cond_br %2034, ^bb562, ^bb563 {llvm.loop_annotation = #loop_annotation}
    ^bb562:  // pred: ^bb561
      %coord_1356 = cute.make_coord(%2033) : (i32) -> !cute.coord<"(_,?)">
      %idx_1357 = cute.crd2idx(%coord_1356, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1358 = cute.add_offset(%ptr_984, %idx_1357) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1359 = cute.crd2idx(%coord_1356, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1360 = cute.add_offset(%ptr_985, %idx_1359) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2035 = cute_nvgpu.arch.copy.ldsm %ptr_1358{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %2036 = vector.extractelement %2035[%130 : i32] : vector<4xi32>
      %2037 = builtin.unrealized_conversion_cast %ptr_1360 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2036, %2037 : i32, !llvm.ptr
      %2038 = vector.extractelement %2035[%129 : i32] : vector<4xi32>
      %ptr_1361 = cute.add_offset(%ptr_1360, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %2039 = builtin.unrealized_conversion_cast %ptr_1361 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2038, %2039 : i32, !llvm.ptr
      %2040 = vector.extractelement %2035[%128 : i32] : vector<4xi32>
      %ptr_1362 = cute.add_offset(%ptr_1360, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %2041 = builtin.unrealized_conversion_cast %ptr_1362 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2040, %2041 : i32, !llvm.ptr
      %2042 = vector.extractelement %2035[%126 : i32] : vector<4xi32>
      %ptr_1363 = cute.add_offset(%ptr_1360, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %2043 = builtin.unrealized_conversion_cast %ptr_1363 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2042, %2043 : i32, !llvm.ptr
      %2044 = arith.addi %2033, %c1_i32 : i32
      cf.br ^bb561(%2044 : i32)
    ^bb563:  // pred: ^bb561
      %ptr_1364 = cute.add_offset(%iter_1330, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb564(%c0_i32 : i32)
    ^bb564(%2045: i32):  // 2 preds: ^bb563, ^bb571
      %2046 = arith.cmpi slt, %2045, %657 : i32
      cf.cond_br %2046, ^bb565, ^bb572 {llvm.loop_annotation = #loop_annotation}
    ^bb565:  // pred: ^bb564
      cf.br ^bb566(%c0_i32 : i32)
    ^bb566(%2047: i32):  // 2 preds: ^bb565, ^bb570
      %2048 = arith.cmpi slt, %2047, %607 : i32
      cf.cond_br %2048, ^bb567, ^bb571 {llvm.loop_annotation = #loop_annotation}
    ^bb567:  // pred: ^bb566
      %coord_1365 = cute.make_coord(%2047, %2045) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1366 = cute.crd2idx(%coord_1365, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1367 = cute.add_offset(%ptr_1364, %idx_1366) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2049 = builtin.unrealized_conversion_cast %ptr_1367 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2050 = llvm.getelementptr %2049[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2051 = llvm.getelementptr %2049[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %2052 = llvm.getelementptr %2049[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb568(%c0_i32 : i32)
    ^bb568(%2053: i32):  // 2 preds: ^bb567, ^bb569
      %2054 = arith.cmpi slt, %2053, %1233 : i32
      cf.cond_br %2054, ^bb569, ^bb570 {llvm.loop_annotation = #loop_annotation}
    ^bb569:  // pred: ^bb568
      %coord_1368 = cute.make_coord(%2053, %2045) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1369 = cute.make_coord(%2047, %2053) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1370 = cute.crd2idx(%coord_1368, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1371 = cute.add_offset(%ptr_966, %idx_1370) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1372 = cute.crd2idx(%coord_1369, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1373 = cute.add_offset(%iter_118, %idx_1372) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %2055 = llvm.load %2049 : !llvm.ptr -> i32
      %2056 = llvm.load %2050 : !llvm.ptr -> i32
      %2057 = llvm.load %2051 : !llvm.ptr -> i32
      %2058 = llvm.load %2052 : !llvm.ptr -> i32
      %2059 = builtin.unrealized_conversion_cast %ptr_1371 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2060 = llvm.load %2059 : !llvm.ptr -> i32
      %2061 = llvm.getelementptr %2059[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2062 = llvm.load %2061 : !llvm.ptr -> i32
      %2063 = builtin.unrealized_conversion_cast %ptr_1373 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %2064 = llvm.load %2063 : !llvm.ptr -> f32
      %2065 = llvm.getelementptr %2063[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %2066 = llvm.load %2065 : !llvm.ptr -> f32
      %2067 = llvm.getelementptr %2063[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %2068 = llvm.load %2067 : !llvm.ptr -> f32
      %2069 = llvm.getelementptr %2063[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %2070 = llvm.load %2069 : !llvm.ptr -> f32
      %2071:4 = cute_nvgpu.arch.mma.SM80 A[%2055, %2056, %2057, %2058]  B[%2060, %2062]  C[%2064, %2066, %2068, %2070] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %2071#0, %2063 : f32, !llvm.ptr
      llvm.store %2071#1, %2065 : f32, !llvm.ptr
      llvm.store %2071#2, %2067 : f32, !llvm.ptr
      llvm.store %2071#3, %2069 : f32, !llvm.ptr
      %2072 = arith.addi %2053, %c1_i32 : i32
      cf.br ^bb568(%2072 : i32)
    ^bb570:  // pred: ^bb568
      %2073 = arith.addi %2047, %c1_i32 : i32
      cf.br ^bb566(%2073 : i32)
    ^bb571:  // pred: ^bb566
      %2074 = arith.addi %2045, %c1_i32 : i32
      cf.br ^bb564(%2074 : i32)
    ^bb572:  // pred: ^bb564
      cf.br ^bb573(%c0_i32 : i32)
    ^bb573(%2075: i32):  // 2 preds: ^bb572, ^bb574
      %2076 = arith.cmpi slt, %2075, %658 : i32
      cf.cond_br %2076, ^bb574, ^bb575 {llvm.loop_annotation = #loop_annotation}
    ^bb574:  // pred: ^bb573
      %coord_1374 = cute.make_coord(%2075) : (i32) -> !cute.coord<"(_,?)">
      %idx_1375 = cute.crd2idx(%coord_1374, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1376 = cute.add_offset(%ptr_1004, %idx_1375) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1377 = cute.crd2idx(%coord_1374, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1378 = cute.add_offset(%ptr_1005, %idx_1377) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2077 = cute_nvgpu.arch.copy.ldsm %ptr_1376{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %2078 = vector.extractelement %2077[%130 : i32] : vector<4xi32>
      %2079 = builtin.unrealized_conversion_cast %ptr_1378 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2078, %2079 : i32, !llvm.ptr
      %2080 = vector.extractelement %2077[%129 : i32] : vector<4xi32>
      %ptr_1379 = cute.add_offset(%ptr_1378, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %2081 = builtin.unrealized_conversion_cast %ptr_1379 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2080, %2081 : i32, !llvm.ptr
      %2082 = vector.extractelement %2077[%128 : i32] : vector<4xi32>
      %ptr_1380 = cute.add_offset(%ptr_1378, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %2083 = builtin.unrealized_conversion_cast %ptr_1380 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2082, %2083 : i32, !llvm.ptr
      %2084 = vector.extractelement %2077[%126 : i32] : vector<4xi32>
      %ptr_1381 = cute.add_offset(%ptr_1378, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %2085 = builtin.unrealized_conversion_cast %ptr_1381 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2084, %2085 : i32, !llvm.ptr
      %2086 = arith.addi %2075, %c1_i32 : i32
      cf.br ^bb573(%2086 : i32)
    ^bb575:  // pred: ^bb573
      %ptr_1382 = cute.add_offset(%iter_1330, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb576(%c0_i32 : i32)
    ^bb576(%2087: i32):  // 2 preds: ^bb575, ^bb583
      %2088 = arith.cmpi slt, %2087, %657 : i32
      cf.cond_br %2088, ^bb577, ^bb584 {llvm.loop_annotation = #loop_annotation}
    ^bb577:  // pred: ^bb576
      cf.br ^bb578(%c0_i32 : i32)
    ^bb578(%2089: i32):  // 2 preds: ^bb577, ^bb582
      %2090 = arith.cmpi slt, %2089, %607 : i32
      cf.cond_br %2090, ^bb579, ^bb583 {llvm.loop_annotation = #loop_annotation}
    ^bb579:  // pred: ^bb578
      %coord_1383 = cute.make_coord(%2089, %2087) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1384 = cute.crd2idx(%coord_1383, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1385 = cute.add_offset(%ptr_1382, %idx_1384) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2091 = builtin.unrealized_conversion_cast %ptr_1385 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2092 = llvm.getelementptr %2091[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2093 = llvm.getelementptr %2091[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %2094 = llvm.getelementptr %2091[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb580(%c0_i32 : i32)
    ^bb580(%2095: i32):  // 2 preds: ^bb579, ^bb581
      %2096 = arith.cmpi slt, %2095, %1233 : i32
      cf.cond_br %2096, ^bb581, ^bb582 {llvm.loop_annotation = #loop_annotation}
    ^bb581:  // pred: ^bb580
      %coord_1386 = cute.make_coord(%2095, %2087) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1387 = cute.make_coord(%2089, %2095) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1388 = cute.crd2idx(%coord_1386, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1389 = cute.add_offset(%ptr_985, %idx_1388) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1390 = cute.crd2idx(%coord_1387, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1391 = cute.add_offset(%iter_118, %idx_1390) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %2097 = llvm.load %2091 : !llvm.ptr -> i32
      %2098 = llvm.load %2092 : !llvm.ptr -> i32
      %2099 = llvm.load %2093 : !llvm.ptr -> i32
      %2100 = llvm.load %2094 : !llvm.ptr -> i32
      %2101 = builtin.unrealized_conversion_cast %ptr_1389 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2102 = llvm.load %2101 : !llvm.ptr -> i32
      %2103 = llvm.getelementptr %2101[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2104 = llvm.load %2103 : !llvm.ptr -> i32
      %2105 = builtin.unrealized_conversion_cast %ptr_1391 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %2106 = llvm.load %2105 : !llvm.ptr -> f32
      %2107 = llvm.getelementptr %2105[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %2108 = llvm.load %2107 : !llvm.ptr -> f32
      %2109 = llvm.getelementptr %2105[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %2110 = llvm.load %2109 : !llvm.ptr -> f32
      %2111 = llvm.getelementptr %2105[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %2112 = llvm.load %2111 : !llvm.ptr -> f32
      %2113:4 = cute_nvgpu.arch.mma.SM80 A[%2097, %2098, %2099, %2100]  B[%2102, %2104]  C[%2106, %2108, %2110, %2112] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %2113#0, %2105 : f32, !llvm.ptr
      llvm.store %2113#1, %2107 : f32, !llvm.ptr
      llvm.store %2113#2, %2109 : f32, !llvm.ptr
      llvm.store %2113#3, %2111 : f32, !llvm.ptr
      %2114 = arith.addi %2095, %c1_i32 : i32
      cf.br ^bb580(%2114 : i32)
    ^bb582:  // pred: ^bb580
      %2115 = arith.addi %2089, %c1_i32 : i32
      cf.br ^bb578(%2115 : i32)
    ^bb583:  // pred: ^bb578
      %2116 = arith.addi %2087, %c1_i32 : i32
      cf.br ^bb576(%2116 : i32)
    ^bb584:  // pred: ^bb576
      cf.br ^bb585(%c0_i32 : i32)
    ^bb585(%2117: i32):  // 2 preds: ^bb584, ^bb586
      %2118 = arith.cmpi slt, %2117, %658 : i32
      cf.cond_br %2118, ^bb586, ^bb587 {llvm.loop_annotation = #loop_annotation}
    ^bb586:  // pred: ^bb585
      %coord_1392 = cute.make_coord(%2117) : (i32) -> !cute.coord<"(_,?)">
      %idx_1393 = cute.crd2idx(%coord_1392, %lay_956) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1394 = cute.add_offset(%ptr_138, %idx_1393) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1395 = cute.crd2idx(%coord_1392, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1396 = cute.add_offset(%iter_141, %idx_1395) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2119 = cute_nvgpu.arch.copy.ldsm %ptr_1394{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %2120 = vector.extractelement %2119[%130 : i32] : vector<4xi32>
      %2121 = builtin.unrealized_conversion_cast %ptr_1396 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2120, %2121 : i32, !llvm.ptr
      %2122 = vector.extractelement %2119[%129 : i32] : vector<4xi32>
      %ptr_1397 = cute.add_offset(%ptr_1396, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %2123 = builtin.unrealized_conversion_cast %ptr_1397 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2122, %2123 : i32, !llvm.ptr
      %2124 = vector.extractelement %2119[%128 : i32] : vector<4xi32>
      %ptr_1398 = cute.add_offset(%ptr_1396, %127) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %2125 = builtin.unrealized_conversion_cast %ptr_1398 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %2124, %2125 : i32, !llvm.ptr
      %2126 = vector.extractelement %2119[%126 : i32] : vector<4xi32>
      %ptr_1399 = cute.add_offset(%ptr_1396, %125) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %2127 = builtin.unrealized_conversion_cast %ptr_1399 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %2126, %2127 : i32, !llvm.ptr
      %2128 = arith.addi %2117, %c1_i32 : i32
      cf.br ^bb585(%2128 : i32)
    ^bb587:  // pred: ^bb585
      %ptr_1400 = cute.add_offset(%iter_1330, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      cf.br ^bb588(%c0_i32 : i32)
    ^bb588(%2129: i32):  // 2 preds: ^bb587, ^bb595
      %2130 = arith.cmpi slt, %2129, %657 : i32
      cf.cond_br %2130, ^bb589, ^bb596 {llvm.loop_annotation = #loop_annotation}
    ^bb589:  // pred: ^bb588
      cf.br ^bb590(%c0_i32 : i32)
    ^bb590(%2131: i32):  // 2 preds: ^bb589, ^bb594
      %2132 = arith.cmpi slt, %2131, %607 : i32
      cf.cond_br %2132, ^bb591, ^bb595 {llvm.loop_annotation = #loop_annotation}
    ^bb591:  // pred: ^bb590
      %coord_1401 = cute.make_coord(%2131, %2129) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1402 = cute.crd2idx(%coord_1401, %12) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((2,2),2),2,1):(((1,2),8),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1403 = cute.add_offset(%ptr_1400, %idx_1402) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %2133 = builtin.unrealized_conversion_cast %ptr_1403 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2134 = llvm.getelementptr %2133[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2135 = llvm.getelementptr %2133[4] : (!llvm.ptr) -> !llvm.ptr, i32
      %2136 = llvm.getelementptr %2133[5] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb592(%c0_i32 : i32)
    ^bb592(%2137: i32):  // 2 preds: ^bb591, ^bb593
      %2138 = arith.cmpi slt, %2137, %1233 : i32
      cf.cond_br %2138, ^bb593, ^bb594 {llvm.loop_annotation = #loop_annotation}
    ^bb593:  // pred: ^bb592
      %coord_1404 = cute.make_coord(%2137, %2129) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_1405 = cute.make_coord(%2131, %2137) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_1406 = cute.crd2idx(%coord_1404, %11) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1407 = cute.add_offset(%ptr_1005, %idx_1406) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1408 = cute.crd2idx(%coord_1405, %176) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,16):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1409 = cute.add_offset(%iter_118, %idx_1408) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %2139 = llvm.load %2133 : !llvm.ptr -> i32
      %2140 = llvm.load %2134 : !llvm.ptr -> i32
      %2141 = llvm.load %2135 : !llvm.ptr -> i32
      %2142 = llvm.load %2136 : !llvm.ptr -> i32
      %2143 = builtin.unrealized_conversion_cast %ptr_1407 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2144 = llvm.load %2143 : !llvm.ptr -> i32
      %2145 = llvm.getelementptr %2143[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %2146 = llvm.load %2145 : !llvm.ptr -> i32
      %2147 = builtin.unrealized_conversion_cast %ptr_1409 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %2148 = llvm.load %2147 : !llvm.ptr -> f32
      %2149 = llvm.getelementptr %2147[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %2150 = llvm.load %2149 : !llvm.ptr -> f32
      %2151 = llvm.getelementptr %2147[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %2152 = llvm.load %2151 : !llvm.ptr -> f32
      %2153 = llvm.getelementptr %2147[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %2154 = llvm.load %2153 : !llvm.ptr -> f32
      %2155:4 = cute_nvgpu.arch.mma.SM80 A[%2139, %2140, %2141, %2142]  B[%2144, %2146]  C[%2148, %2150, %2152, %2154] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %2155#0, %2147 : f32, !llvm.ptr
      llvm.store %2155#1, %2149 : f32, !llvm.ptr
      llvm.store %2155#2, %2151 : f32, !llvm.ptr
      llvm.store %2155#3, %2153 : f32, !llvm.ptr
      %2156 = arith.addi %2137, %c1_i32 : i32
      cf.br ^bb592(%2156 : i32)
    ^bb594:  // pred: ^bb592
      %2157 = arith.addi %2131, %c1_i32 : i32
      cf.br ^bb590(%2157 : i32)
    ^bb595:  // pred: ^bb590
      %2158 = arith.addi %2129, %c1_i32 : i32
      cf.br ^bb588(%2158 : i32)
    ^bb596:  // pred: ^bb588
      %2159 = arith.addi %1397, %c1_i32 : i32
      cf.br ^bb407(%2159 : i32)
    ^bb597:  // pred: ^bb407
      %2160 = cute.memref.load(%rmem_457, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %2161 = nvvm.shfl.sync  bfly %c-1_i32, %2160, %c2_i32, %c31_i32 : f32 -> f32
      %2162 = arith.addf %2160, %2161 : f32
      %2163 = nvvm.shfl.sync  bfly %c-1_i32, %2162, %c1_i32, %c31_i32 : f32 -> f32
      %2164 = arith.addf %2162, %2163 : f32
      cute.memref.store(%rmem_457, %68, %2164) : (!memref_rmem_f32_1, !cute.coord<"0">, f32) -> ()
      %2165 = cute.memref.load(%rmem_457, %68) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      %2166 = arith.cmpf oeq, %2165, %cst_6 : f32
      %2167 = arith.cmpf une, %2165, %2165 : f32
      %2168 = arith.extui %2166 : i1 to i32
      %2169 = arith.extui %2167 : i1 to i32
      %2170 = arith.select %2166, %2168, %2169 : i32
      %2171 = arith.cmpi ne, %2170, %c0_i32 : i32
      %2172 = nvvm.rcp.approx.ftz.f %2165 : f32
      %2173 = arith.select %2171, %cst_4, %2172 : f32
      %view_1410 = cute.make_view(%iter_118) : !memref_rmem_f32_7
      %2174 = cute.memref.load_vec %view_1410 : !memref_rmem_f32_7
      %2175 = vector.broadcast %2173 : f32 to vector<32xf32>
      %2176 = arith.mulf %2174, %2175 : vector<32xf32>
      cute.memref.store_vec %2176, %view_1410 : !memref_rmem_f32_7
      %2177 = cute.memref.load(%rmem_457, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %2178 = nvvm.shfl.sync  bfly %c-1_i32, %2177, %c2_i32, %c31_i32 : f32 -> f32
      %2179 = arith.addf %2177, %2178 : f32
      %2180 = nvvm.shfl.sync  bfly %c-1_i32, %2179, %c1_i32, %c31_i32 : f32 -> f32
      %2181 = arith.addf %2179, %2180 : f32
      cute.memref.store(%rmem_457, %51, %2181) : (!memref_rmem_f32_1, !cute.coord<"1">, f32) -> ()
      %2182 = cute.memref.load(%rmem_457, %51) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      %2183 = arith.cmpf oeq, %2182, %cst_6 : f32
      %2184 = arith.cmpf une, %2182, %2182 : f32
      %2185 = arith.extui %2183 : i1 to i32
      %2186 = arith.extui %2184 : i1 to i32
      %2187 = arith.select %2183, %2185, %2186 : i32
      %2188 = arith.cmpi ne, %2187, %c0_i32 : i32
      %2189 = nvvm.rcp.approx.ftz.f %2182 : f32
      %2190 = arith.select %2188, %cst_4, %2189 : f32
      %ptr_1411 = cute.add_offset(%iter_118, %161) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1412 = cute.make_view(%ptr_1411) : !memref_rmem_f32_8
      %2191 = cute.memref.load_vec %view_1412 : !memref_rmem_f32_8
      %2192 = vector.broadcast %2190 : f32 to vector<32xf32>
      %2193 = arith.mulf %2191, %2192 : vector<32xf32>
      cute.memref.store_vec %2193, %view_1412 : !memref_rmem_f32_8
      %2194 = cute.memref.load(%rmem_457, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %2195 = nvvm.shfl.sync  bfly %c-1_i32, %2194, %c2_i32, %c31_i32 : f32 -> f32
      %2196 = arith.addf %2194, %2195 : f32
      %2197 = nvvm.shfl.sync  bfly %c-1_i32, %2196, %c1_i32, %c31_i32 : f32 -> f32
      %2198 = arith.addf %2196, %2197 : f32
      cute.memref.store(%rmem_457, %34, %2198) : (!memref_rmem_f32_1, !cute.coord<"2">, f32) -> ()
      %2199 = cute.memref.load(%rmem_457, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      %2200 = arith.cmpf oeq, %2199, %cst_6 : f32
      %2201 = arith.cmpf une, %2199, %2199 : f32
      %2202 = arith.extui %2200 : i1 to i32
      %2203 = arith.extui %2201 : i1 to i32
      %2204 = arith.select %2200, %2202, %2203 : i32
      %2205 = arith.cmpi ne, %2204, %c0_i32 : i32
      %2206 = nvvm.rcp.approx.ftz.f %2199 : f32
      %2207 = arith.select %2205, %cst_4, %2206 : f32
      %ptr_1413 = cute.add_offset(%iter_118, %127) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %view_1414 = cute.make_view(%ptr_1413) : !memref_rmem_f32_9
      %2208 = cute.memref.load_vec %view_1414 : !memref_rmem_f32_9
      %2209 = vector.broadcast %2207 : f32 to vector<32xf32>
      %2210 = arith.mulf %2208, %2209 : vector<32xf32>
      cute.memref.store_vec %2210, %view_1414 : !memref_rmem_f32_9
      %2211 = cute.memref.load(%rmem_457, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %2212 = nvvm.shfl.sync  bfly %c-1_i32, %2211, %c2_i32, %c31_i32 : f32 -> f32
      %2213 = arith.addf %2211, %2212 : f32
      %2214 = nvvm.shfl.sync  bfly %c-1_i32, %2213, %c1_i32, %c31_i32 : f32 -> f32
      %2215 = arith.addf %2213, %2214 : f32
      cute.memref.store(%rmem_457, %17, %2215) : (!memref_rmem_f32_1, !cute.coord<"3">, f32) -> ()
      %2216 = cute.memref.load(%rmem_457, %17) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      %2217 = arith.cmpf oeq, %2216, %cst_6 : f32
      %2218 = arith.cmpf une, %2216, %2216 : f32
      %2219 = arith.extui %2217 : i1 to i32
      %2220 = arith.extui %2218 : i1 to i32
      %2221 = arith.select %2217, %2219, %2220 : i32
      %2222 = arith.cmpi ne, %2221, %c0_i32 : i32
      %2223 = nvvm.rcp.approx.ftz.f %2216 : f32
      %2224 = arith.select %2222, %cst_4, %2223 : f32
      %ptr_1415 = cute.add_offset(%iter_118, %125) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %view_1416 = cute.make_view(%ptr_1415) : !memref_rmem_f32_8
      %2225 = cute.memref.load_vec %view_1416 : !memref_rmem_f32_8
      %2226 = vector.broadcast %2224 : f32 to vector<32xf32>
      %2227 = arith.mulf %2225, %2226 : vector<32xf32>
      cute.memref.store_vec %2227, %view_1416 : !memref_rmem_f32_8
      %rmem_1417 = cute.memref.alloca() : !memref_rmem_bf16_4
      %2228 = cute.memref.load_vec %rmem_117 : !memref_rmem_f32_
      %2229 = arith.truncf %2228 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %2229, %rmem_1417 : !memref_rmem_bf16_4
      %atom_1418 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %2230 = cute.make_tiled_copy(%atom_1418) : !copy_simt
      %iter_1419 = cute.get_iter(%rmem_1417) : !memref_rmem_bf16_4
      %2231 = arith.divsi %316, %c4_i32 : i32
      %2232 = arith.remsi %2231, %c8_i32 : i32
      %2233 = arith.muli %2232, %c64_i32 : i32
      %2234 = arith.remsi %316, %c4_i32 : i32
      %2235 = arith.muli %2234, %c2_i32 : i32
      %2236 = arith.divsi %2231, %c8_i32 : i32
      %2237 = arith.muli %2236, %c1024_i32 : i32
      %2238 = arith.addi %2235, %2237 : i32
      %2239 = arith.andi %2233, %c64_i32 : i32
      %2240 = arith.cmpi eq, %2239, %c0_i32 : i32
      %2241 = arith.select %2240, %c8_i32, %c-8_i32 : i32
      %2242 = arith.andi %2233, %c128_i32 : i32
      %2243 = arith.cmpi eq, %2242, %c0_i32 : i32
      %2244 = arith.select %2243, %c16_i32, %c-16_i32 : i32
      %2245 = arith.andi %2233, %c256_i32 : i32
      %2246 = arith.cmpi eq, %2245, %c0_i32 : i32
      %2247 = arith.select %2246, %c32_i32, %c-32_i32 : i32
      %2248 = arith.andi %2233, %c448_i32 : i32
      %2249 = arith.shrsi %2248, %c3_i32 : i32
      %2250 = arith.xori %2233, %2249 : i32
      %2251 = arith.addi %2250, %2238 : i32
      %iv_1420 = cute.assume(%2251) : (i32) -> !cute.i32<divby 2>
      %int_tuple_1421 = cute.make_int_tuple(%iv_1420) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_1422 = cute.add_offset(%iter_84, %int_tuple_1421) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>>
      %iv_1423 = cute.assume(%2241) : (i32) -> !cute.i32<divby 8>
      %iv_1424 = cute.assume(%2244) : (i32) -> !cute.i32<divby 16>
      %iv_1425 = cute.assume(%2247) : (i32) -> !cute.i32<divby 32>
      %stride_1426 = cute.make_stride(%iv_1423, %iv_1424, %iv_1425) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %lay_1427 = cute.make_layout(%9, %stride_1426) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %append_1428 = cute.append_to_rank<2> (%lay_1427, %181) : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">, !cute.layout<"1:0">
      %2252:3 = cute.get_scalars(%append_1428) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),2,((2,2),2)):((0,(1,512,?{div=8})),4096,((?{div=16},?{div=32}),8192))">
      %iv_1429 = cute.assume(%2252#0) : (i32) -> !cute.i32<divby 8>
      %iv_1430 = cute.assume(%2252#1) : (i32) -> !cute.i32<divby 16>
      %iv_1431 = cute.assume(%2252#2) : (i32) -> !cute.i32<divby 32>
      %stride_1432 = cute.make_stride(%iv_1429, %iv_1430, %iv_1431) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %lay_1433 = cute.make_layout(%8, %stride_1432) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %append_1434 = cute.append_to_rank<2> (%lay_1433, %181) : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">, !cute.layout<"1:0">
      %2253:3 = cute.get_scalars(%append_1434) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),(2,((2,2),2))):((0,(1,512,?{div=8})),(4096,((?{div=16},?{div=32}),8192)))">
      %iv_1435 = cute.assume(%2253#0) : (i32) -> !cute.i32<divby 8>
      %iv_1436 = cute.assume(%2253#1) : (i32) -> !cute.i32<divby 16>
      %iv_1437 = cute.assume(%2253#2) : (i32) -> !cute.i32<divby 32>
      %stride_1438 = cute.make_stride(%iv_1435, %iv_1436, %iv_1437) : (!cute.i32<divby 8>, !cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %lay_1439 = cute.make_layout(%6, %stride_1438) : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %2254:3 = cute.get_scalars(%lay_1439) <{only_dynamic}> : !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">
      %iv_1440 = cute.assume(%2254#0) : (i32) -> !cute.i32<divby 8>
      %stride_1441 = cute.make_stride(%iv_1440) : (!cute.i32<divby 8>) -> !cute.stride<"((0,(1,512,?{div=8})))">
      %lay_1442 = cute.make_layout(%5, %stride_1441) : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
      %2255 = cute.get_scalars(%lay_1442) <{only_dynamic}> : !cute.layout<"((1,(2,2,2))):((0,(1,512,?{div=8})))">
      %iv_1443 = cute.assume(%2255) : (i32) -> !cute.i32<divby 8>
      %int_tuple_1444 = cute.make_int_tuple(%iv_1443) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %2256 = arith.addi %2255, %c512_i32 : i32
      %iv_1445 = cute.assume(%2256) : (i32) -> !cute.i32<divby 8>
      %int_tuple_1446 = cute.make_int_tuple(%iv_1445) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      cf.br ^bb598(%c0_i32 : i32)
    ^bb598(%2257: i32):  // 2 preds: ^bb597, ^bb599
      %2258 = arith.cmpi slt, %2257, %1233 : i32
      cf.cond_br %2258, ^bb599, ^bb600 {llvm.loop_annotation = #loop_annotation}
    ^bb599:  // pred: ^bb598
      %coord_1447 = cute.make_coord(%2257) : (i32) -> !cute.coord<"(_,?)">
      %idx_1448 = cute.crd2idx(%coord_1447, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,2)),((2,8))):((0,(1,8)),((4,16)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_1449 = cute.add_offset(%iter_1419, %idx_1448) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_1450 = cute.crd2idx(%coord_1447, %lay_1439) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((2,((2,2),2)))):((0,(1,512,?{div=8})),((4096,((?{div=16},?{div=32}),8192))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1451 = cute.add_offset(%ptr_1422, %idx_1450) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>>
      %2259 = builtin.unrealized_conversion_cast %ptr_1449 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2260 = builtin.unrealized_conversion_cast %ptr_1451 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2261 = llvm.load %2259 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2261, %2260 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1452 = cute.add_offset(%ptr_1449, %161) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_1453 = cute.add_offset(%ptr_1451, %4) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>>
      %2262 = builtin.unrealized_conversion_cast %ptr_1452 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %2263 = builtin.unrealized_conversion_cast %ptr_1453 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2264 = llvm.load %2262 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2264, %2263 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1454 = cute.add_offset(%ptr_1449, %132) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_1455 = cute.add_offset(%ptr_1451, %int_tuple_1444) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
      %2265 = builtin.unrealized_conversion_cast %ptr_1454 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %2266 = builtin.unrealized_conversion_cast %ptr_1455 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2267 = llvm.load %2265 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2267, %2266 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_1456 = cute.add_offset(%ptr_1449, %3) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_1457 = cute.add_offset(%ptr_1451, %int_tuple_1446) : (!cute.ptr<bf16, smem, align<4>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<4>>
      %2268 = builtin.unrealized_conversion_cast %ptr_1456 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %2269 = builtin.unrealized_conversion_cast %ptr_1457 : !cute.ptr<bf16, smem, align<4>> to !llvm.ptr<3>
      %2270 = llvm.load %2268 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %2270, %2269 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %2271 = arith.addi %2257, %c1_i32 : i32
      cf.br ^bb598(%2271 : i32)
    ^bb600:  // pred: ^bb598
      %lay_1458 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %2272:7 = cute.get_scalars(%lay_1458) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_1459 = cute.assume(%2272#3) : (i32) -> !cute.i32<divby 8>
      %shape_1460 = cute.make_shape(%2272#1, %iv_1459) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_1461 = cute.assume(%2272#5) : (i64) -> !cute.i64<divby 8>
      %stride_1462 = cute.make_stride(%iv_1461) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1463 = cute.make_layout(%shape_1460, %stride_1462) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_1464 = cute.crd2idx(%coord, %lay_1458) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_1465 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_1466 = cute.add_offset(%iter_1465, %idx_1464) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %2273:3 = cute.get_scalars(%lay_1463) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_1467 = arith.constant 1 : i32
      %c0_i32_1468 = arith.constant 0 : i32
      %c-1_i32_1469 = arith.constant -1 : i32
      %2274 = arith.cmpi sgt, %c128_i32, %c0_i32_1468 : i32
      %2275 = arith.select %2274, %c-1_i32_1469, %c1_i32_1467 : i32
      %2276 = arith.addi %2275, %2273#0 : i32
      %2277 = arith.divsi %2276, %c128_i32 : i32
      %2278 = arith.addi %c1_i32_1467, %2277 : i32
      %2279 = arith.subi %c0_i32_1468, %2273#0 : i32
      %2280 = arith.divsi %2279, %c128_i32 : i32
      %2281 = arith.subi %c0_i32_1468, %2280 : i32
      %2282 = arith.cmpi slt, %2273#0, %c0_i32_1468 : i32
      %2283 = arith.cmpi sgt, %2273#0, %c0_i32_1468 : i32
      %2284 = arith.cmpi slt, %c128_i32, %c0_i32_1468 : i32
      %2285 = arith.cmpi sgt, %c128_i32, %c0_i32_1468 : i32
      %2286 = arith.andi %2282, %2284 : i1
      %2287 = arith.andi %2283, %2285 : i1
      %2288 = arith.ori %2286, %2287 : i1
      %2289 = arith.select %2288, %2278, %2281 : i32
      %2290 = arith.muli %2273#2, %c128_i64 : i64
      %c1_i32_1470 = arith.constant 1 : i32
      %c0_i32_1471 = arith.constant 0 : i32
      %c-1_i32_1472 = arith.constant -1 : i32
      %2291 = arith.cmpi sgt, %c128_i32, %c0_i32_1471 : i32
      %2292 = arith.select %2291, %c-1_i32_1472, %c1_i32_1470 : i32
      %2293 = arith.addi %2292, %2273#1 : i32
      %2294 = arith.divsi %2293, %c128_i32 : i32
      %2295 = arith.addi %c1_i32_1470, %2294 : i32
      %2296 = arith.subi %c0_i32_1471, %2273#1 : i32
      %2297 = arith.divsi %2296, %c128_i32 : i32
      %2298 = arith.subi %c0_i32_1471, %2297 : i32
      %2299 = arith.cmpi slt, %2273#1, %c0_i32_1471 : i32
      %2300 = arith.cmpi sgt, %2273#1, %c0_i32_1471 : i32
      %2301 = arith.cmpi slt, %c128_i32, %c0_i32_1471 : i32
      %2302 = arith.cmpi sgt, %c128_i32, %c0_i32_1471 : i32
      %2303 = arith.andi %2299, %2301 : i1
      %2304 = arith.andi %2300, %2302 : i1
      %2305 = arith.ori %2303, %2304 : i1
      %2306 = arith.select %2305, %2295, %2298 : i32
      %shape_1473 = cute.make_shape(%2289, %2306) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %iv_1474 = cute.assume(%2273#2) : (i64) -> !cute.i64<divby 8>
      %iv_1475 = cute.assume(%2290) : (i64) -> !cute.i64<divby 1024>
      %stride_1476 = cute.make_stride(%iv_1474, %iv_1475) : (!cute.i64<divby 8>, !cute.i64<divby 1024>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=1024},128))">
      %lay_1477 = cute.make_layout(%shape_1473, %stride_1476) : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %2307:4 = cute.get_scalars(%lay_1477) <{only_dynamic}> : !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">
      %iv_1478 = cute.assume(%2307#2) : (i64) -> !cute.i64<divby 8>
      %stride_1479 = cute.make_stride(%iv_1478) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1480 = cute.make_layout(%180, %stride_1479) : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %idx_1481 = cute.crd2idx(%coord_16, %lay_1477) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((?{i64 div=8},1),(?{i64 div=1024},128))">) -> !cute.int_tuple<"?{i64 div=1024}">
      %ptr_1482 = cute.add_offset(%ptr_1466, %idx_1481) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=1024}">) -> !cute.ptr<bf16, gmem, align<16>>
      %2308 = cute.get_scalars(%lay_1480) <{only_dynamic}> : !cute.layout<"(128,128):(?{i64 div=8},1)">
      %2309 = arith.muli %2308, %c16_i64 : i64
      %2310 = arith.muli %321, %2308 : i64
      %2311 = arith.addi %323, %2310 : i64
      %iv_1483 = cute.assume(%2311) : (i64) -> !cute.i64<divby 8>
      %int_tuple_1484 = cute.make_int_tuple(%iv_1483) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_1485 = cute.add_offset(%ptr_1482, %int_tuple_1484) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_1486 = cute.assume(%2309) : (i64) -> !cute.i64<divby 128>
      %stride_1487 = cute.make_stride(%iv_1486) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1488 = cute.make_layout(%177, %stride_1487) : !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">
      %rmem_1489 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_1490 = cute.get_iter(%rmem_1489) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.br ^bb601(%c0_i32 : i32)
    ^bb601(%2312: i32):  // 2 preds: ^bb600, ^bb602
      %2313 = arith.cmpi slt, %2312, %1233 : i32
      cf.cond_br %2313, ^bb602, ^bb603 {llvm.loop_annotation = #loop_annotation}
    ^bb602:  // pred: ^bb601
      %coord_1491 = cute.make_coord(%2312) : (i32) -> !cute.coord<"(_,?)">
      %idx_1492 = cute.crd2idx(%coord_1491, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((1024,8192)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_1493 = cute.add_offset(%ptr_96, %idx_1492) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_1494 = cute.crd2idx(%coord_1491, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((8,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1495 = cute.add_offset(%iter_1490, %idx_1494) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %2314 = builtin.unrealized_conversion_cast %ptr_1493 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %2315 = builtin.unrealized_conversion_cast %ptr_1495 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2316 = llvm.load %2314 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %2316, %2315 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %2317 = arith.addi %2312, %c1_i32 : i32
      cf.br ^bb601(%2317 : i32)
    ^bb603:  // pred: ^bb601
      %2318 = cute.get_shape(%lay_1458) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1496, %e1_1497, %e2_1498, %e3_1499 = cute.get_leaves(%2318) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1500 = cute.to_int_tuple(%e0_1496) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1501 = cute.to_int_tuple(%e1_1497) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1502 = cute.to_int_tuple(%e2_1498) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1503 = cute.to_int_tuple(%e3_1499) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_1504 = cute.make_shape(%itup_1500, %itup_1501, %itup_1502, %itup_1503) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_1505 = cute.make_layout(%shape_1504, %171) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %2319:4 = cute.get_scalars(%lay_1505) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_1506 = cute.assume(%2319#3) : (i32) -> !cute.i32<divby 8>
      %shape_1507 = cute.make_shape(%2319#1, %iv_1506) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_1508 = cute.make_layout(%shape_1507, %170) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_1509 = cute.crd2idx(%coord, %lay_1505) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_1510 = cute.add_offset(%172, %idx_1509) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %2320:2 = cute.get_scalars(%lay_1508) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_1511 = arith.constant 1 : i32
      %c0_i32_1512 = arith.constant 0 : i32
      %c-1_i32_1513 = arith.constant -1 : i32
      %2321 = arith.cmpi sgt, %c128_i32, %c0_i32_1512 : i32
      %2322 = arith.select %2321, %c-1_i32_1513, %c1_i32_1511 : i32
      %2323 = arith.addi %2322, %2320#0 : i32
      %2324 = arith.divsi %2323, %c128_i32 : i32
      %2325 = arith.addi %c1_i32_1511, %2324 : i32
      %2326 = arith.subi %c0_i32_1512, %2320#0 : i32
      %2327 = arith.divsi %2326, %c128_i32 : i32
      %2328 = arith.subi %c0_i32_1512, %2327 : i32
      %2329 = arith.cmpi slt, %2320#0, %c0_i32_1512 : i32
      %2330 = arith.cmpi sgt, %2320#0, %c0_i32_1512 : i32
      %2331 = arith.cmpi slt, %c128_i32, %c0_i32_1512 : i32
      %2332 = arith.cmpi sgt, %c128_i32, %c0_i32_1512 : i32
      %2333 = arith.andi %2329, %2331 : i1
      %2334 = arith.andi %2330, %2332 : i1
      %2335 = arith.ori %2333, %2334 : i1
      %2336 = arith.select %2335, %2325, %2328 : i32
      %c1_i32_1514 = arith.constant 1 : i32
      %c0_i32_1515 = arith.constant 0 : i32
      %c-1_i32_1516 = arith.constant -1 : i32
      %2337 = arith.cmpi sgt, %c128_i32, %c0_i32_1515 : i32
      %2338 = arith.select %2337, %c-1_i32_1516, %c1_i32_1514 : i32
      %2339 = arith.addi %2338, %2320#1 : i32
      %2340 = arith.divsi %2339, %c128_i32 : i32
      %2341 = arith.addi %c1_i32_1514, %2340 : i32
      %2342 = arith.subi %c0_i32_1515, %2320#1 : i32
      %2343 = arith.divsi %2342, %c128_i32 : i32
      %2344 = arith.subi %c0_i32_1515, %2343 : i32
      %2345 = arith.cmpi slt, %2320#1, %c0_i32_1515 : i32
      %2346 = arith.cmpi sgt, %2320#1, %c0_i32_1515 : i32
      %2347 = arith.cmpi slt, %c128_i32, %c0_i32_1515 : i32
      %2348 = arith.cmpi sgt, %c128_i32, %c0_i32_1515 : i32
      %2349 = arith.andi %2345, %2347 : i1
      %2350 = arith.andi %2346, %2348 : i1
      %2351 = arith.ori %2349, %2350 : i1
      %2352 = arith.select %2351, %2341, %2344 : i32
      %shape_1517 = cute.make_shape(%2336, %2352) : (i32, i32) -> !cute.shape<"((128,128),(?,?))">
      %lay_1518 = cute.make_layout(%shape_1517, %169) : !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">
      %idx_1519 = cute.crd2idx(%coord_16, %lay_1518) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((128,128),(?,?)):((1@1,1@3),(128@1,128@3))">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_1520 = cute.add_offset(%tup_1510, %idx_1519) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(?,?{div=128},?,0)">
      %tup_1521 = cute.add_offset(%tup_1520, %int_tuple_189) : (!cute.int_tuple<"(?,?{div=128},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_1522 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_1523, %e1_1524, %e2_1525, %e3_1526 = cute.get_leaves(%tup_1521) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1527 = cute.make_coord(%e3_1526) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1528 = cute.make_coord(%itup_1503) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %2353 = cute.get_scalars(%coord_1527) : !cute.coord<"?{div=8}">
      %2354 = cute.get_scalars(%coord_1528) : !cute.coord<"?{div=8}">
      %2355 = arith.cmpi slt, %2353, %2354 : i32
      %2356 = arith.extui %2355 : i1 to i8
      cute.memref.store(%rmem_1522, %167, %2356) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_1529 = cute.add_offset(%tup_1521, %166) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1530, %e1_1531, %e2_1532, %e3_1533 = cute.get_leaves(%tup_1529) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1534 = cute.make_coord(%e3_1533) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %2357 = cute.get_scalars(%coord_1534) : !cute.coord<"?{div=8}">
      %2358 = arith.cmpi slt, %2357, %2354 : i32
      %2359 = arith.extui %2358 : i1 to i8
      cute.memref.store(%rmem_1522, %165, %2359) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_1535 = cute.make_coord(%e1_1524) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1536 = cute.make_coord(%itup_1501) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2360 = cute.get_scalars(%coord_1535) : !cute.coord<"?">
      %2361 = cute.get_scalars(%coord_1536) : !cute.coord<"?">
      %2362 = arith.cmpi slt, %2360, %2361 : i32
      cf.cond_br %2362, ^bb604, ^bb610
    ^bb604:  // pred: ^bb603
      %iter_1537 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb605(%c0_i32 : i32)
    ^bb605(%2363: i32):  // 2 preds: ^bb604, ^bb608
      %2364 = arith.cmpi slt, %2363, %607 : i32
      cf.cond_br %2364, ^bb606, ^bb609 {llvm.loop_annotation = #loop_annotation}
    ^bb606:  // pred: ^bb605
      %coord_1538 = cute.make_coord(%2363) : (i32) -> !cute.coord<"(_,?)">
      %idx_1539 = cute.crd2idx(%coord_1538, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1540 = cute.add_offset(%iter_1490, %idx_1539) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1541 = cute.crd2idx(%coord_1538, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1542 = cute.add_offset(%ptr_1485, %idx_1541) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1543 = cute.crd2idx(%coord_1538, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1544 = cute.add_offset(%iter_1537, %idx_1543) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2365 = builtin.unrealized_conversion_cast %ptr_1544 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2366 = llvm.load %2365 : !llvm.ptr -> i8
      %2367 = llvm.icmp "ne" %2366, %0 : i8
      cf.cond_br %2367, ^bb607, ^bb608
    ^bb607:  // pred: ^bb606
      %2368 = builtin.unrealized_conversion_cast %ptr_1540 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2369 = builtin.unrealized_conversion_cast %ptr_1542 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2370 = llvm.load %2368 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2370, %2369 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb608
    ^bb608:  // 2 preds: ^bb606, ^bb607
      %2371 = arith.addi %2363, %c1_i32 : i32
      cf.br ^bb605(%2371 : i32)
    ^bb609:  // pred: ^bb605
      cf.br ^bb610
    ^bb610:  // 2 preds: ^bb603, ^bb609
      %tup_1545 = cute.add_offset(%tup_1521, %160) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1546, %e1_1547, %e2_1548, %e3_1549 = cute.get_leaves(%tup_1545) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1550 = cute.make_coord(%e1_1547) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2372 = cute.get_scalars(%coord_1550) : !cute.coord<"?">
      %2373 = arith.cmpi slt, %2372, %2361 : i32
      cf.cond_br %2373, ^bb611, ^bb617
    ^bb611:  // pred: ^bb610
      %ptr_1551 = cute.add_offset(%iter_1490, %110) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1552 = cute.crd2idx(%159, %lay_1488) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_1553 = cute.add_offset(%ptr_1485, %idx_1552) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1554 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb612(%c0_i32 : i32)
    ^bb612(%2374: i32):  // 2 preds: ^bb611, ^bb615
      %2375 = arith.cmpi slt, %2374, %607 : i32
      cf.cond_br %2375, ^bb613, ^bb616 {llvm.loop_annotation = #loop_annotation}
    ^bb613:  // pred: ^bb612
      %coord_1555 = cute.make_coord(%2374) : (i32) -> !cute.coord<"(_,?)">
      %idx_1556 = cute.crd2idx(%coord_1555, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1557 = cute.add_offset(%ptr_1551, %idx_1556) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1558 = cute.crd2idx(%coord_1555, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1559 = cute.add_offset(%ptr_1553, %idx_1558) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1560 = cute.crd2idx(%coord_1555, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1561 = cute.add_offset(%iter_1554, %idx_1560) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2376 = builtin.unrealized_conversion_cast %ptr_1561 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2377 = llvm.load %2376 : !llvm.ptr -> i8
      %2378 = llvm.icmp "ne" %2377, %0 : i8
      cf.cond_br %2378, ^bb614, ^bb615
    ^bb614:  // pred: ^bb613
      %2379 = builtin.unrealized_conversion_cast %ptr_1557 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2380 = builtin.unrealized_conversion_cast %ptr_1559 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2381 = llvm.load %2379 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2381, %2380 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb615
    ^bb615:  // 2 preds: ^bb613, ^bb614
      %2382 = arith.addi %2374, %c1_i32 : i32
      cf.br ^bb612(%2382 : i32)
    ^bb616:  // pred: ^bb612
      cf.br ^bb617
    ^bb617:  // 2 preds: ^bb610, ^bb616
      %tup_1562 = cute.add_offset(%tup_1521, %157) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1563, %e1_1564, %e2_1565, %e3_1566 = cute.get_leaves(%tup_1562) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1567 = cute.make_coord(%e1_1564) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2383 = cute.get_scalars(%coord_1567) : !cute.coord<"?">
      %2384 = arith.cmpi slt, %2383, %2361 : i32
      cf.cond_br %2384, ^bb618, ^bb624
    ^bb618:  // pred: ^bb617
      %ptr_1568 = cute.add_offset(%iter_1490, %121) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1569 = cute.crd2idx(%156, %lay_1488) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_1570 = cute.add_offset(%ptr_1485, %idx_1569) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1571 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb619(%c0_i32 : i32)
    ^bb619(%2385: i32):  // 2 preds: ^bb618, ^bb622
      %2386 = arith.cmpi slt, %2385, %607 : i32
      cf.cond_br %2386, ^bb620, ^bb623 {llvm.loop_annotation = #loop_annotation}
    ^bb620:  // pred: ^bb619
      %coord_1572 = cute.make_coord(%2385) : (i32) -> !cute.coord<"(_,?)">
      %idx_1573 = cute.crd2idx(%coord_1572, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1574 = cute.add_offset(%ptr_1568, %idx_1573) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1575 = cute.crd2idx(%coord_1572, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1576 = cute.add_offset(%ptr_1570, %idx_1575) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1577 = cute.crd2idx(%coord_1572, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1578 = cute.add_offset(%iter_1571, %idx_1577) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2387 = builtin.unrealized_conversion_cast %ptr_1578 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2388 = llvm.load %2387 : !llvm.ptr -> i8
      %2389 = llvm.icmp "ne" %2388, %0 : i8
      cf.cond_br %2389, ^bb621, ^bb622
    ^bb621:  // pred: ^bb620
      %2390 = builtin.unrealized_conversion_cast %ptr_1574 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2391 = builtin.unrealized_conversion_cast %ptr_1576 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2392 = llvm.load %2390 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2392, %2391 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb622
    ^bb622:  // 2 preds: ^bb620, ^bb621
      %2393 = arith.addi %2385, %c1_i32 : i32
      cf.br ^bb619(%2393 : i32)
    ^bb623:  // pred: ^bb619
      cf.br ^bb624
    ^bb624:  // 2 preds: ^bb617, ^bb623
      %tup_1579 = cute.add_offset(%tup_1521, %154) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1580, %e1_1581, %e2_1582, %e3_1583 = cute.get_leaves(%tup_1579) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1584 = cute.make_coord(%e1_1581) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2394 = cute.get_scalars(%coord_1584) : !cute.coord<"?">
      %2395 = arith.cmpi slt, %2394, %2361 : i32
      cf.cond_br %2395, ^bb625, ^bb631
    ^bb625:  // pred: ^bb624
      %ptr_1585 = cute.add_offset(%iter_1490, %108) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1586 = cute.crd2idx(%153, %lay_1488) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_1587 = cute.add_offset(%ptr_1485, %idx_1586) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1588 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb626(%c0_i32 : i32)
    ^bb626(%2396: i32):  // 2 preds: ^bb625, ^bb629
      %2397 = arith.cmpi slt, %2396, %607 : i32
      cf.cond_br %2397, ^bb627, ^bb630 {llvm.loop_annotation = #loop_annotation}
    ^bb627:  // pred: ^bb626
      %coord_1589 = cute.make_coord(%2396) : (i32) -> !cute.coord<"(_,?)">
      %idx_1590 = cute.crd2idx(%coord_1589, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1591 = cute.add_offset(%ptr_1585, %idx_1590) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1592 = cute.crd2idx(%coord_1589, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1593 = cute.add_offset(%ptr_1587, %idx_1592) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1594 = cute.crd2idx(%coord_1589, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1595 = cute.add_offset(%iter_1588, %idx_1594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2398 = builtin.unrealized_conversion_cast %ptr_1595 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2399 = llvm.load %2398 : !llvm.ptr -> i8
      %2400 = llvm.icmp "ne" %2399, %0 : i8
      cf.cond_br %2400, ^bb628, ^bb629
    ^bb628:  // pred: ^bb627
      %2401 = builtin.unrealized_conversion_cast %ptr_1591 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2402 = builtin.unrealized_conversion_cast %ptr_1593 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2403 = llvm.load %2401 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2403, %2402 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb629
    ^bb629:  // 2 preds: ^bb627, ^bb628
      %2404 = arith.addi %2396, %c1_i32 : i32
      cf.br ^bb626(%2404 : i32)
    ^bb630:  // pred: ^bb626
      cf.br ^bb631
    ^bb631:  // 2 preds: ^bb624, ^bb630
      %tup_1596 = cute.add_offset(%tup_1521, %151) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,64,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1597, %e1_1598, %e2_1599, %e3_1600 = cute.get_leaves(%tup_1596) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1601 = cute.make_coord(%e1_1598) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2405 = cute.get_scalars(%coord_1601) : !cute.coord<"?">
      %2406 = arith.cmpi slt, %2405, %2361 : i32
      cf.cond_br %2406, ^bb632, ^bb638
    ^bb632:  // pred: ^bb631
      %ptr_1602 = cute.add_offset(%iter_1490, %120) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1603 = cute.crd2idx(%150, %lay_1488) : (!cute.coord<"(_,4,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1604 = cute.add_offset(%ptr_1485, %idx_1603) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1605 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb633(%c0_i32 : i32)
    ^bb633(%2407: i32):  // 2 preds: ^bb632, ^bb636
      %2408 = arith.cmpi slt, %2407, %607 : i32
      cf.cond_br %2408, ^bb634, ^bb637 {llvm.loop_annotation = #loop_annotation}
    ^bb634:  // pred: ^bb633
      %coord_1606 = cute.make_coord(%2407) : (i32) -> !cute.coord<"(_,?)">
      %idx_1607 = cute.crd2idx(%coord_1606, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1608 = cute.add_offset(%ptr_1602, %idx_1607) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1609 = cute.crd2idx(%coord_1606, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1610 = cute.add_offset(%ptr_1604, %idx_1609) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1611 = cute.crd2idx(%coord_1606, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1612 = cute.add_offset(%iter_1605, %idx_1611) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2409 = builtin.unrealized_conversion_cast %ptr_1612 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2410 = llvm.load %2409 : !llvm.ptr -> i8
      %2411 = llvm.icmp "ne" %2410, %0 : i8
      cf.cond_br %2411, ^bb635, ^bb636
    ^bb635:  // pred: ^bb634
      %2412 = builtin.unrealized_conversion_cast %ptr_1608 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2413 = builtin.unrealized_conversion_cast %ptr_1610 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2414 = llvm.load %2412 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2414, %2413 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb636
    ^bb636:  // 2 preds: ^bb634, ^bb635
      %2415 = arith.addi %2407, %c1_i32 : i32
      cf.br ^bb633(%2415 : i32)
    ^bb637:  // pred: ^bb633
      cf.br ^bb638
    ^bb638:  // 2 preds: ^bb631, ^bb637
      %tup_1613 = cute.add_offset(%tup_1521, %148) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,80,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1614, %e1_1615, %e2_1616, %e3_1617 = cute.get_leaves(%tup_1613) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1618 = cute.make_coord(%e1_1615) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2416 = cute.get_scalars(%coord_1618) : !cute.coord<"?">
      %2417 = arith.cmpi slt, %2416, %2361 : i32
      cf.cond_br %2417, ^bb639, ^bb645
    ^bb639:  // pred: ^bb638
      %ptr_1619 = cute.add_offset(%iter_1490, %106) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1620 = cute.crd2idx(%147, %lay_1488) : (!cute.coord<"(_,5,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=640}">
      %ptr_1621 = cute.add_offset(%ptr_1485, %idx_1620) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=640}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1622 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb640(%c0_i32 : i32)
    ^bb640(%2418: i32):  // 2 preds: ^bb639, ^bb643
      %2419 = arith.cmpi slt, %2418, %607 : i32
      cf.cond_br %2419, ^bb641, ^bb644 {llvm.loop_annotation = #loop_annotation}
    ^bb641:  // pred: ^bb640
      %coord_1623 = cute.make_coord(%2418) : (i32) -> !cute.coord<"(_,?)">
      %idx_1624 = cute.crd2idx(%coord_1623, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1625 = cute.add_offset(%ptr_1619, %idx_1624) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1626 = cute.crd2idx(%coord_1623, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1627 = cute.add_offset(%ptr_1621, %idx_1626) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1628 = cute.crd2idx(%coord_1623, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1629 = cute.add_offset(%iter_1622, %idx_1628) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2420 = builtin.unrealized_conversion_cast %ptr_1629 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2421 = llvm.load %2420 : !llvm.ptr -> i8
      %2422 = llvm.icmp "ne" %2421, %0 : i8
      cf.cond_br %2422, ^bb642, ^bb643
    ^bb642:  // pred: ^bb641
      %2423 = builtin.unrealized_conversion_cast %ptr_1625 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2424 = builtin.unrealized_conversion_cast %ptr_1627 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2425 = llvm.load %2423 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2425, %2424 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb643
    ^bb643:  // 2 preds: ^bb641, ^bb642
      %2426 = arith.addi %2418, %c1_i32 : i32
      cf.br ^bb640(%2426 : i32)
    ^bb644:  // pred: ^bb640
      cf.br ^bb645
    ^bb645:  // 2 preds: ^bb638, ^bb644
      %tup_1630 = cute.add_offset(%tup_1521, %145) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,96,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1631, %e1_1632, %e2_1633, %e3_1634 = cute.get_leaves(%tup_1630) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1635 = cute.make_coord(%e1_1632) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2427 = cute.get_scalars(%coord_1635) : !cute.coord<"?">
      %2428 = arith.cmpi slt, %2427, %2361 : i32
      cf.cond_br %2428, ^bb646, ^bb652
    ^bb646:  // pred: ^bb645
      %ptr_1636 = cute.add_offset(%iter_1490, %113) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1637 = cute.crd2idx(%144, %lay_1488) : (!cute.coord<"(_,6,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=768}">
      %ptr_1638 = cute.add_offset(%ptr_1485, %idx_1637) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=768}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1639 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb647(%c0_i32 : i32)
    ^bb647(%2429: i32):  // 2 preds: ^bb646, ^bb650
      %2430 = arith.cmpi slt, %2429, %607 : i32
      cf.cond_br %2430, ^bb648, ^bb651 {llvm.loop_annotation = #loop_annotation}
    ^bb648:  // pred: ^bb647
      %coord_1640 = cute.make_coord(%2429) : (i32) -> !cute.coord<"(_,?)">
      %idx_1641 = cute.crd2idx(%coord_1640, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1642 = cute.add_offset(%ptr_1636, %idx_1641) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1643 = cute.crd2idx(%coord_1640, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1644 = cute.add_offset(%ptr_1638, %idx_1643) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1645 = cute.crd2idx(%coord_1640, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1646 = cute.add_offset(%iter_1639, %idx_1645) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2431 = builtin.unrealized_conversion_cast %ptr_1646 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2432 = llvm.load %2431 : !llvm.ptr -> i8
      %2433 = llvm.icmp "ne" %2432, %0 : i8
      cf.cond_br %2433, ^bb649, ^bb650
    ^bb649:  // pred: ^bb648
      %2434 = builtin.unrealized_conversion_cast %ptr_1642 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2435 = builtin.unrealized_conversion_cast %ptr_1644 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2436 = llvm.load %2434 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2436, %2435 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb650
    ^bb650:  // 2 preds: ^bb648, ^bb649
      %2437 = arith.addi %2429, %c1_i32 : i32
      cf.br ^bb647(%2437 : i32)
    ^bb651:  // pred: ^bb647
      cf.br ^bb652
    ^bb652:  // 2 preds: ^bb645, ^bb651
      %tup_1647 = cute.add_offset(%tup_1521, %142) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,112,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1648, %e1_1649, %e2_1650, %e3_1651 = cute.get_leaves(%tup_1647) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1652 = cute.make_coord(%e1_1649) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2438 = cute.get_scalars(%coord_1652) : !cute.coord<"?">
      %2439 = arith.cmpi slt, %2438, %2361 : i32
      cf.cond_br %2439, ^bb653, ^bb659
    ^bb653:  // pred: ^bb652
      %ptr_1653 = cute.add_offset(%iter_1490, %103) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"112">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1654 = cute.crd2idx(%141, %lay_1488) : (!cute.coord<"(_,7,_)">, !cute.layout<"((8,1),8,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=896}">
      %ptr_1655 = cute.add_offset(%ptr_1485, %idx_1654) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=896}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1656 = cute.get_iter(%rmem_1522) : !memref_rmem_i8_
      cf.br ^bb654(%c0_i32 : i32)
    ^bb654(%2440: i32):  // 2 preds: ^bb653, ^bb657
      %2441 = arith.cmpi slt, %2440, %607 : i32
      cf.cond_br %2441, ^bb655, ^bb658 {llvm.loop_annotation = #loop_annotation}
    ^bb655:  // pred: ^bb654
      %coord_1657 = cute.make_coord(%2440) : (i32) -> !cute.coord<"(_,?)">
      %idx_1658 = cute.crd2idx(%coord_1657, %131) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1659 = cute.add_offset(%ptr_1653, %idx_1658) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1660 = cute.crd2idx(%coord_1657, %164) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1661 = cute.add_offset(%ptr_1655, %idx_1660) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1662 = cute.crd2idx(%coord_1657, %162) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1663 = cute.add_offset(%iter_1656, %idx_1662) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %2442 = builtin.unrealized_conversion_cast %ptr_1663 : !cute.ptr<i8, rmem> to !llvm.ptr
      %2443 = llvm.load %2442 : !llvm.ptr -> i8
      %2444 = llvm.icmp "ne" %2443, %0 : i8
      cf.cond_br %2444, ^bb656, ^bb657
    ^bb656:  // pred: ^bb655
      %2445 = builtin.unrealized_conversion_cast %ptr_1659 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2446 = builtin.unrealized_conversion_cast %ptr_1661 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %2447 = llvm.load %2445 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2447, %2446 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb657
    ^bb657:  // 2 preds: ^bb655, ^bb656
      %2448 = arith.addi %2440, %c1_i32 : i32
      cf.br ^bb654(%2448 : i32)
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
    %c1_i32_3 = arith.constant 1 : i32
    %c0_i32_4 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %4 = arith.cmpi sgt, %c128_i32, %c0_i32_4 : i32
    %5 = arith.select %4, %c-1_i32, %c1_i32_3 : i32
    %6 = arith.addi %5, %3 : i32
    %7 = arith.divsi %6, %c128_i32 : i32
    %8 = arith.addi %c1_i32_3, %7 : i32
    %9 = arith.subi %c0_i32_4, %3 : i32
    %10 = arith.divsi %9, %c128_i32 : i32
    %11 = arith.subi %c0_i32_4, %10 : i32
    %12 = arith.cmpi slt, %3, %c0_i32_4 : i32
    %13 = arith.cmpi sgt, %3, %c0_i32_4 : i32
    %14 = arith.cmpi slt, %c128_i32, %c0_i32_4 : i32
    %15 = arith.cmpi sgt, %c128_i32, %c0_i32_4 : i32
    %16 = arith.andi %12, %14 : i1
    %17 = arith.andi %13, %15 : i1
    %18 = arith.ori %16, %17 : i1
    %19 = arith.select %18, %8, %11 : i32
    %int_tuple_5 = cute.make_int_tuple(%19) : (i32) -> !cute.int_tuple<"?">
    %e0_6 = cute.get_leaves(%int_tuple_5) : !cute.int_tuple<"?">
    %20 = cute.get_scalars(%e0_6) : !cute.int_tuple<"?">
    %int_tuple_7 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_7) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_8 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %21 = cute.get_scalars(%e0_8) : !cute.int_tuple<"?">
    %int_tuple_9 = cute.make_int_tuple(%itup_2) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_10 = cute.size(%int_tuple_9) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_11 = cute.get_leaves(%sz_10) : !cute.int_tuple<"?">
    %22 = cute.get_scalars(%e0_11) : !cute.int_tuple<"?">
    %23 = arith.mulf %arg4, %cst : f32
    %24 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c65536_i64, gridDim = (%20, %21, %22), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %25 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__FlashAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16gmemalign16odiv8i64div8i64div8i64div81_tensorptrbf16g_0<%24> (%arg0, %arg1, %arg2, %arg3, %23) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, !memref_gmem_bf16_, f32) -> !cuda.result
    %26 = cuda.cast %25 : !cuda.result -> i32
    cuda.return_if_error %26 : i32
    return %c0_i32 : i32
  }
}
