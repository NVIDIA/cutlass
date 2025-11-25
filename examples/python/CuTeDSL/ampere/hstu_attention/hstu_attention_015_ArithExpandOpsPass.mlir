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
    func.func public @kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %c1_i32_3 = arith.constant 1 : i32
      %c0_i32_4 = arith.constant 0 : i32
      %c-1_i32_5 = arith.constant -1 : i32
      %124 = arith.cmpi sgt, %c64_i32, %c0_i32_4 : i32
      %125 = arith.select %124, %c-1_i32_5, %c1_i32_3 : i32
      %126 = arith.addi %125, %123 : i32
      %127 = arith.divsi %126, %c64_i32 : i32
      %128 = arith.addi %c1_i32_3, %127 : i32
      %129 = arith.subi %c0_i32_4, %123 : i32
      %130 = arith.divsi %129, %c64_i32 : i32
      %131 = arith.subi %c0_i32_4, %130 : i32
      %132 = arith.cmpi slt, %123, %c0_i32_4 : i32
      %133 = arith.cmpi sgt, %123, %c0_i32_4 : i32
      %134 = arith.cmpi slt, %c64_i32, %c0_i32_4 : i32
      %135 = arith.cmpi sgt, %c64_i32, %c0_i32_4 : i32
      %136 = arith.andi %132, %134 : i1
      %137 = arith.andi %133, %135 : i1
      %138 = arith.ori %136, %137 : i1
      %139 = arith.select %138, %128, %131 : i32
      %int_tuple_6 = cute.make_int_tuple(%139) : (i32) -> !cute.int_tuple<"?">
      %e0_7 = cute.get_leaves(%int_tuple_6) : !cute.int_tuple<"?">
      %int_tuple_8 = cute.make_int_tuple(%121) : (i32) -> !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_7, %int_tuple_8) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %sub_9 = cute.tuple_sub(%sub, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %lay_10 = cute.get_layout(%arg1) : !memref_gmem_bf16_
      %140 = cute.get_shape(%lay_10) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_11, %e1_12, %e2_13, %e3_14 = cute.get_leaves(%140) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_15 = cute.to_int_tuple(%e1_12) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %int_tuple_16 = cute.make_int_tuple(%itup_15) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %141 = cute.get_scalars(%int_tuple_16) <{only_dynamic}> : !cute.int_tuple<"?">
      %c1_i32_17 = arith.constant 1 : i32
      %c0_i32_18 = arith.constant 0 : i32
      %c-1_i32_19 = arith.constant -1 : i32
      %142 = arith.cmpi sgt, %c64_i32, %c0_i32_18 : i32
      %143 = arith.select %142, %c-1_i32_19, %c1_i32_17 : i32
      %144 = arith.addi %143, %141 : i32
      %145 = arith.divsi %144, %c64_i32 : i32
      %146 = arith.addi %c1_i32_17, %145 : i32
      %147 = arith.subi %c0_i32_18, %141 : i32
      %148 = arith.divsi %147, %c64_i32 : i32
      %149 = arith.subi %c0_i32_18, %148 : i32
      %150 = arith.cmpi slt, %141, %c0_i32_18 : i32
      %151 = arith.cmpi sgt, %141, %c0_i32_18 : i32
      %152 = arith.cmpi slt, %c64_i32, %c0_i32_18 : i32
      %153 = arith.cmpi sgt, %c64_i32, %c0_i32_18 : i32
      %154 = arith.andi %150, %152 : i1
      %155 = arith.andi %151, %153 : i1
      %156 = arith.ori %154, %155 : i1
      %157 = arith.select %156, %146, %149 : i32
      %int_tuple_20 = cute.make_int_tuple(%157) : (i32) -> !cute.int_tuple<"?">
      %e0_21 = cute.get_leaves(%int_tuple_20) : !cute.int_tuple<"?">
      %sub_22 = cute.tuple_sub(%e0_21, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %158 = cute.get_scalars(%sub_22) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,_,?,_)">
      %159:7 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv = cute.assume(%159#3) : (i32) -> !cute.i32<divby 8>
      %shape = cute.make_shape(%159#1, %iv) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_23 = cute.assume(%159#5) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv_23) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_24 = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_25 = cute.make_coord(%sub_9) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %160 = cute.get_scalars(%coord_25) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_26 = cute.make_coord(%160) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %161:3 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_27 = arith.constant 1 : i32
      %c0_i32_28 = arith.constant 0 : i32
      %c-1_i32_29 = arith.constant -1 : i32
      %162 = arith.cmpi sgt, %c64_i32, %c0_i32_28 : i32
      %163 = arith.select %162, %c-1_i32_29, %c1_i32_27 : i32
      %164 = arith.addi %163, %161#0 : i32
      %165 = arith.divsi %164, %c64_i32 : i32
      %166 = arith.addi %c1_i32_27, %165 : i32
      %167 = arith.subi %c0_i32_28, %161#0 : i32
      %168 = arith.divsi %167, %c64_i32 : i32
      %169 = arith.subi %c0_i32_28, %168 : i32
      %170 = arith.cmpi slt, %161#0, %c0_i32_28 : i32
      %171 = arith.cmpi sgt, %161#0, %c0_i32_28 : i32
      %172 = arith.cmpi slt, %c64_i32, %c0_i32_28 : i32
      %173 = arith.cmpi sgt, %c64_i32, %c0_i32_28 : i32
      %174 = arith.andi %170, %172 : i1
      %175 = arith.andi %171, %173 : i1
      %176 = arith.ori %174, %175 : i1
      %177 = arith.select %176, %166, %169 : i32
      %178 = arith.muli %161#2, %c64_i64 : i64
      %c1_i32_30 = arith.constant 1 : i32
      %c0_i32_31 = arith.constant 0 : i32
      %c-1_i32_32 = arith.constant -1 : i32
      %179 = arith.cmpi sgt, %c128_i32, %c0_i32_31 : i32
      %180 = arith.select %179, %c-1_i32_32, %c1_i32_30 : i32
      %181 = arith.addi %180, %161#1 : i32
      %182 = arith.divsi %181, %c128_i32 : i32
      %183 = arith.addi %c1_i32_30, %182 : i32
      %184 = arith.subi %c0_i32_31, %161#1 : i32
      %185 = arith.divsi %184, %c128_i32 : i32
      %186 = arith.subi %c0_i32_31, %185 : i32
      %187 = arith.cmpi slt, %161#1, %c0_i32_31 : i32
      %188 = arith.cmpi sgt, %161#1, %c0_i32_31 : i32
      %189 = arith.cmpi slt, %c128_i32, %c0_i32_31 : i32
      %190 = arith.cmpi sgt, %c128_i32, %c0_i32_31 : i32
      %191 = arith.andi %187, %189 : i1
      %192 = arith.andi %188, %190 : i1
      %193 = arith.ori %191, %192 : i1
      %194 = arith.select %193, %183, %186 : i32
      %shape_33 = cute.make_shape(%177, %194) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_34 = cute.assume(%161#2) : (i64) -> !cute.i64<divby 8>
      %iv_35 = cute.assume(%178) : (i64) -> !cute.i64<divby 512>
      %stride_36 = cute.make_stride(%iv_34, %iv_35) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_37 = cute.make_layout(%shape_33, %stride_36) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %195:4 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_38 = cute.assume(%195#2) : (i64) -> !cute.i64<divby 8>
      %stride_39 = cute.make_stride(%iv_38) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_40 = cute.make_layout(%115, %stride_39) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_41 = cute.crd2idx(%coord_26, %lay_37) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_42 = cute.add_offset(%ptr, %idx_41) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %196:7 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_43 = cute.assume(%196#3) : (i32) -> !cute.i32<divby 8>
      %shape_44 = cute.make_shape(%196#1, %iv_43) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_45 = cute.assume(%196#5) : (i64) -> !cute.i64<divby 8>
      %stride_46 = cute.make_stride(%iv_45) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_47 = cute.make_layout(%shape_44, %stride_46) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_48 = cute.crd2idx(%coord, %lay_10) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_49 = cute.get_iter(%arg1) : !memref_gmem_bf16_
      %ptr_50 = cute.add_offset(%iter_49, %idx_48) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %197:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_51 = arith.constant 1 : i32
      %c0_i32_52 = arith.constant 0 : i32
      %c-1_i32_53 = arith.constant -1 : i32
      %198 = arith.cmpi sgt, %c64_i32, %c0_i32_52 : i32
      %199 = arith.select %198, %c-1_i32_53, %c1_i32_51 : i32
      %200 = arith.addi %199, %197#0 : i32
      %201 = arith.divsi %200, %c64_i32 : i32
      %202 = arith.addi %c1_i32_51, %201 : i32
      %203 = arith.subi %c0_i32_52, %197#0 : i32
      %204 = arith.divsi %203, %c64_i32 : i32
      %205 = arith.subi %c0_i32_52, %204 : i32
      %206 = arith.cmpi slt, %197#0, %c0_i32_52 : i32
      %207 = arith.cmpi sgt, %197#0, %c0_i32_52 : i32
      %208 = arith.cmpi slt, %c64_i32, %c0_i32_52 : i32
      %209 = arith.cmpi sgt, %c64_i32, %c0_i32_52 : i32
      %210 = arith.andi %206, %208 : i1
      %211 = arith.andi %207, %209 : i1
      %212 = arith.ori %210, %211 : i1
      %213 = arith.select %212, %202, %205 : i32
      %214 = arith.muli %197#2, %c64_i64 : i64
      %c1_i32_54 = arith.constant 1 : i32
      %c0_i32_55 = arith.constant 0 : i32
      %c-1_i32_56 = arith.constant -1 : i32
      %215 = arith.cmpi sgt, %c128_i32, %c0_i32_55 : i32
      %216 = arith.select %215, %c-1_i32_56, %c1_i32_54 : i32
      %217 = arith.addi %216, %197#1 : i32
      %218 = arith.divsi %217, %c128_i32 : i32
      %219 = arith.addi %c1_i32_54, %218 : i32
      %220 = arith.subi %c0_i32_55, %197#1 : i32
      %221 = arith.divsi %220, %c128_i32 : i32
      %222 = arith.subi %c0_i32_55, %221 : i32
      %223 = arith.cmpi slt, %197#1, %c0_i32_55 : i32
      %224 = arith.cmpi sgt, %197#1, %c0_i32_55 : i32
      %225 = arith.cmpi slt, %c128_i32, %c0_i32_55 : i32
      %226 = arith.cmpi sgt, %c128_i32, %c0_i32_55 : i32
      %227 = arith.andi %223, %225 : i1
      %228 = arith.andi %224, %226 : i1
      %229 = arith.ori %227, %228 : i1
      %230 = arith.select %229, %219, %222 : i32
      %shape_57 = cute.make_shape(%213, %230) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_58 = cute.assume(%197#2) : (i64) -> !cute.i64<divby 8>
      %iv_59 = cute.assume(%214) : (i64) -> !cute.i64<divby 512>
      %stride_60 = cute.make_stride(%iv_58, %iv_59) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_61 = cute.make_layout(%shape_57, %stride_60) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %231:4 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_62 = cute.make_shape(%231#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_63 = cute.assume(%231#2) : (i64) -> !cute.i64<divby 8>
      %iv_64 = cute.assume(%231#3) : (i64) -> !cute.i64<divby 512>
      %stride_65 = cute.make_stride(%iv_63, %iv_64) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_66 = cute.make_layout(%shape_62, %stride_65) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %lay_67 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %232:7 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_68 = cute.assume(%232#3) : (i32) -> !cute.i32<divby 8>
      %shape_69 = cute.make_shape(%232#1, %iv_68) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_70 = cute.assume(%232#5) : (i64) -> !cute.i64<divby 8>
      %stride_71 = cute.make_stride(%iv_70) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_72 = cute.make_layout(%shape_69, %stride_71) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_73 = cute.crd2idx(%coord, %lay_67) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_74 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_75 = cute.add_offset(%iter_74, %idx_73) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %233:3 = cute.get_scalars(%lay_72) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_76 = arith.constant 1 : i32
      %c0_i32_77 = arith.constant 0 : i32
      %c-1_i32_78 = arith.constant -1 : i32
      %234 = arith.cmpi sgt, %c64_i32, %c0_i32_77 : i32
      %235 = arith.select %234, %c-1_i32_78, %c1_i32_76 : i32
      %236 = arith.addi %235, %233#0 : i32
      %237 = arith.divsi %236, %c64_i32 : i32
      %238 = arith.addi %c1_i32_76, %237 : i32
      %239 = arith.subi %c0_i32_77, %233#0 : i32
      %240 = arith.divsi %239, %c64_i32 : i32
      %241 = arith.subi %c0_i32_77, %240 : i32
      %242 = arith.cmpi slt, %233#0, %c0_i32_77 : i32
      %243 = arith.cmpi sgt, %233#0, %c0_i32_77 : i32
      %244 = arith.cmpi slt, %c64_i32, %c0_i32_77 : i32
      %245 = arith.cmpi sgt, %c64_i32, %c0_i32_77 : i32
      %246 = arith.andi %242, %244 : i1
      %247 = arith.andi %243, %245 : i1
      %248 = arith.ori %246, %247 : i1
      %249 = arith.select %248, %238, %241 : i32
      %250 = arith.muli %233#2, %c64_i64 : i64
      %c1_i32_79 = arith.constant 1 : i32
      %c0_i32_80 = arith.constant 0 : i32
      %c-1_i32_81 = arith.constant -1 : i32
      %251 = arith.cmpi sgt, %c128_i32, %c0_i32_80 : i32
      %252 = arith.select %251, %c-1_i32_81, %c1_i32_79 : i32
      %253 = arith.addi %252, %233#1 : i32
      %254 = arith.divsi %253, %c128_i32 : i32
      %255 = arith.addi %c1_i32_79, %254 : i32
      %256 = arith.subi %c0_i32_80, %233#1 : i32
      %257 = arith.divsi %256, %c128_i32 : i32
      %258 = arith.subi %c0_i32_80, %257 : i32
      %259 = arith.cmpi slt, %233#1, %c0_i32_80 : i32
      %260 = arith.cmpi sgt, %233#1, %c0_i32_80 : i32
      %261 = arith.cmpi slt, %c128_i32, %c0_i32_80 : i32
      %262 = arith.cmpi sgt, %c128_i32, %c0_i32_80 : i32
      %263 = arith.andi %259, %261 : i1
      %264 = arith.andi %260, %262 : i1
      %265 = arith.ori %263, %264 : i1
      %266 = arith.select %265, %255, %258 : i32
      %shape_82 = cute.make_shape(%249, %266) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_83 = cute.assume(%233#2) : (i64) -> !cute.i64<divby 8>
      %iv_84 = cute.assume(%250) : (i64) -> !cute.i64<divby 512>
      %stride_85 = cute.make_stride(%iv_83, %iv_84) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_86 = cute.make_layout(%shape_82, %stride_85) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %267:4 = cute.get_scalars(%lay_86) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %shape_87 = cute.make_shape(%267#0) : (i32) -> !cute.shape<"(64,128,?)">
      %iv_88 = cute.assume(%267#2) : (i64) -> !cute.i64<divby 8>
      %iv_89 = cute.assume(%267#3) : (i64) -> !cute.i64<divby 512>
      %stride_90 = cute.make_stride(%iv_88, %iv_89) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"(?{i64 div=8},1,?{i64 div=512})">
      %lay_91 = cute.make_layout(%shape_87, %stride_90) : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %coord_92 = cute.make_coord(%119, %120) : (i32, i32) -> !cute.coord<"(?,?,_,_)">
      %lay_93 = cute.get_layout(%arg4) : !memref_gmem_bf16_
      %268:7 = cute.get_scalars(%lay_93) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_94 = cute.assume(%268#3) : (i32) -> !cute.i32<divby 8>
      %shape_95 = cute.make_shape(%268#2, %iv_94) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_96 = cute.assume(%268#6) : (i64) -> !cute.i64<divby 8>
      %stride_97 = cute.make_stride(%iv_96) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_98 = cute.make_layout(%shape_95, %stride_97) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_99 = cute.crd2idx(%coord_92, %lay_93) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_100 = cute.get_iter(%arg4) : !memref_gmem_bf16_
      %ptr_101 = cute.add_offset(%iter_100, %idx_99) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_102 = cute.make_coord(%sub_9) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_)">
      %269 = cute.get_scalars(%coord_102) <{only_dynamic}> : !cute.coord<"(?,_)">
      %coord_103 = cute.make_coord(%269) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %270:3 = cute.get_scalars(%lay_98) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_104 = arith.constant 1 : i32
      %c0_i32_105 = arith.constant 0 : i32
      %c-1_i32_106 = arith.constant -1 : i32
      %271 = arith.cmpi sgt, %c64_i32, %c0_i32_105 : i32
      %272 = arith.select %271, %c-1_i32_106, %c1_i32_104 : i32
      %273 = arith.addi %272, %270#0 : i32
      %274 = arith.divsi %273, %c64_i32 : i32
      %275 = arith.addi %c1_i32_104, %274 : i32
      %276 = arith.subi %c0_i32_105, %270#0 : i32
      %277 = arith.divsi %276, %c64_i32 : i32
      %278 = arith.subi %c0_i32_105, %277 : i32
      %279 = arith.cmpi slt, %270#0, %c0_i32_105 : i32
      %280 = arith.cmpi sgt, %270#0, %c0_i32_105 : i32
      %281 = arith.cmpi slt, %c64_i32, %c0_i32_105 : i32
      %282 = arith.cmpi sgt, %c64_i32, %c0_i32_105 : i32
      %283 = arith.andi %279, %281 : i1
      %284 = arith.andi %280, %282 : i1
      %285 = arith.ori %283, %284 : i1
      %286 = arith.select %285, %275, %278 : i32
      %287 = arith.muli %270#2, %c64_i64 : i64
      %c1_i32_107 = arith.constant 1 : i32
      %c0_i32_108 = arith.constant 0 : i32
      %c-1_i32_109 = arith.constant -1 : i32
      %288 = arith.cmpi sgt, %c64_i32, %c0_i32_108 : i32
      %289 = arith.select %288, %c-1_i32_109, %c1_i32_107 : i32
      %290 = arith.addi %289, %270#1 : i32
      %291 = arith.divsi %290, %c64_i32 : i32
      %292 = arith.addi %c1_i32_107, %291 : i32
      %293 = arith.subi %c0_i32_108, %270#1 : i32
      %294 = arith.divsi %293, %c64_i32 : i32
      %295 = arith.subi %c0_i32_108, %294 : i32
      %296 = arith.cmpi slt, %270#1, %c0_i32_108 : i32
      %297 = arith.cmpi sgt, %270#1, %c0_i32_108 : i32
      %298 = arith.cmpi slt, %c64_i32, %c0_i32_108 : i32
      %299 = arith.cmpi sgt, %c64_i32, %c0_i32_108 : i32
      %300 = arith.andi %296, %298 : i1
      %301 = arith.andi %297, %299 : i1
      %302 = arith.ori %300, %301 : i1
      %303 = arith.select %302, %292, %295 : i32
      %shape_110 = cute.make_shape(%286, %303) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %iv_111 = cute.assume(%270#2) : (i64) -> !cute.i64<divby 8>
      %iv_112 = cute.assume(%287) : (i64) -> !cute.i64<divby 512>
      %stride_113 = cute.make_stride(%iv_111, %iv_112) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},64))">
      %lay_114 = cute.make_layout(%shape_110, %stride_113) : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %304:4 = cute.get_scalars(%lay_114) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">
      %shape_115 = cute.make_shape(%304#1) : (i32) -> !cute.shape<"(64,64,?)">
      %iv_116 = cute.assume(%304#2) : (i64) -> !cute.i64<divby 8>
      %stride_117 = cute.make_stride(%iv_116) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1,64)">
      %lay_118 = cute.make_layout(%shape_115, %stride_117) : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %idx_119 = cute.crd2idx(%coord_103, %lay_114) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((?{i64 div=8},1),(?{i64 div=512},64))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_120 = cute.add_offset(%ptr_101, %idx_119) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_121 = cute.add_offset(%smem_ptr, %114) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_122 = cute.add_offset(%smem_ptr, %113) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"32768">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_123 = cute.add_offset(%smem_ptr, %112) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"49152">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_124 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_125 = cute.recast_iter(%ptr_121) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_126 = cute.recast_iter(%ptr_122) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_127 = cute.recast_iter(%ptr_123) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %coord_128 = cute.make_coord(%118) : (i32) -> !cute.coord<"?">
      %305 = cute.get_scalars(%lay_40) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %306 = cute.get_scalars(%coord_128) <{only_dynamic}> : !cute.coord<"?">
      %307 = arith.muli %305, %c16_i64 : i64
      %308 = arith.divsi %306, %c8_i32 : i32
      %309 = arith.remsi %306, %c8_i32 : i32
      %310 = arith.muli %309, %c8_i32 : i32
      %311 = arith.extsi %308 : i32 to i64
      %312 = arith.muli %311, %305 : i64
      %313 = arith.extsi %310 : i32 to i64
      %314 = arith.addi %313, %312 : i64
      %iv_129 = cute.assume(%314) : (i64) -> !cute.i64<divby 8>
      %int_tuple_130 = cute.make_int_tuple(%iv_129) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_131 = cute.add_offset(%ptr_42, %int_tuple_130) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_132 = cute.assume(%307) : (i64) -> !cute.i64<divby 128>
      %stride_133 = cute.make_stride(%iv_132) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_134 = cute.make_layout(%111, %stride_133) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %315 = arith.divsi %309, %c2_i32 : i32
      %316 = arith.muli %315, %c16_i32 : i32
      %317 = arith.muli %308, %c64_i32 : i32
      %318 = arith.addi %316, %317 : i32
      %319 = arith.remsi %309, %c2_i32 : i32
      %320 = arith.muli %319, %c8_i32 : i32
      %321 = arith.andi %318, %c896_i32 : i32
      %322 = arith.shrsi %321, %c3_i32 : i32
      %323 = arith.xori %318, %322 : i32
      %324 = arith.addi %323, %320 : i32
      %iv_135 = cute.assume(%324) : (i32) -> !cute.i32<divby 8>
      %int_tuple_136 = cute.make_int_tuple(%iv_135) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_137 = cute.add_offset(%iter_124, %int_tuple_136) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %325:3 = cute.get_scalars(%lay_66) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %326 = arith.muli %325#1, %c16_i64 : i64
      %327 = arith.muli %311, %325#1 : i64
      %328 = arith.addi %313, %327 : i64
      %iv_138 = cute.assume(%328) : (i64) -> !cute.i64<divby 8>
      %int_tuple_139 = cute.make_int_tuple(%iv_138) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_140 = cute.add_offset(%ptr_50, %int_tuple_139) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_141 = cute.make_shape(%325#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_142 = cute.assume(%326) : (i64) -> !cute.i64<divby 128>
      %iv_143 = cute.assume(%325#2) : (i64) -> !cute.i64<divby 512>
      %stride_144 = cute.make_stride(%iv_142, %iv_143) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_145 = cute.make_layout(%shape_141, %stride_144) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_146 = cute.add_offset(%iter_125, %int_tuple_136) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %329:3 = cute.get_scalars(%lay_91) <{only_dynamic}> : !cute.layout<"(64,128,?):(?{i64 div=8},1,?{i64 div=512})">
      %330 = arith.muli %329#1, %c16_i64 : i64
      %331 = arith.muli %311, %329#1 : i64
      %332 = arith.addi %313, %331 : i64
      %iv_147 = cute.assume(%332) : (i64) -> !cute.i64<divby 8>
      %int_tuple_148 = cute.make_int_tuple(%iv_147) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_149 = cute.add_offset(%ptr_75, %int_tuple_148) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_150 = cute.make_shape(%329#0) : (i32) -> !cute.shape<"((8,1),4,2,?)">
      %iv_151 = cute.assume(%330) : (i64) -> !cute.i64<divby 128>
      %iv_152 = cute.assume(%329#2) : (i64) -> !cute.i64<divby 512>
      %stride_153 = cute.make_stride(%iv_151, %iv_152) : (!cute.i64<divby 128>, !cute.i64<divby 512>) -> !cute.stride<"((1,0),?{i64 div=128},64,?{i64 div=512})">
      %lay_154 = cute.make_layout(%shape_150, %stride_153) : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %ptr_155 = cute.add_offset(%iter_126, %int_tuple_136) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %333:2 = cute.get_scalars(%lay_118) <{only_dynamic}> : !cute.layout<"(64,64,?):(?{i64 div=8},1,64)">
      %334 = arith.muli %333#1, %c16_i64 : i64
      %335 = arith.muli %311, %333#1 : i64
      %336 = arith.addi %313, %335 : i64
      %iv_156 = cute.assume(%336) : (i64) -> !cute.i64<divby 8>
      %int_tuple_157 = cute.make_int_tuple(%iv_156) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_158 = cute.add_offset(%ptr_120, %int_tuple_157) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %shape_159 = cute.make_shape(%333#0) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %iv_160 = cute.assume(%334) : (i64) -> !cute.i64<divby 128>
      %stride_161 = cute.make_stride(%iv_160) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},0,64)">
      %lay_162 = cute.make_layout(%shape_159, %stride_161) : !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">
      %ptr_163 = cute.add_offset(%iter_127, %int_tuple_136) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_164 = cute.memref.alloca() : !memref_rmem_bf16_1
      %rmem_165 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_166 = cute.memref.alloca() : !memref_rmem_f32_
      cute.memref.store_vec %cst_2, %rmem_166, row_major : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %atom_167 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = bf16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %337 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %338 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %339 = cute.make_tiled_copy(%atom_167) : !copy_ldsm_4_2
      %340 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_3
      %341 = arith.remsi %306, %c16_i32 : i32
      %342 = arith.muli %341, %c64_i32 : i32
      %343 = arith.divsi %306, %c16_i32 : i32
      %344 = arith.divsi %343, %c2_i32 : i32
      %345 = arith.remsi %343, %c2_i32 : i32
      %346 = arith.muli %345, %c8_i32 : i32
      %347 = arith.muli %344, %c1024_i32 : i32
      %348 = arith.addi %346, %347 : i32
      %349 = arith.andi %342, %c128_i32 : i32
      %350 = arith.cmpi eq, %349, %c0_i32 : i32
      %351 = arith.select %350, %c16_i32, %c-16_i32 : i32
      %352 = arith.andi %342, %c256_i32 : i32
      %353 = arith.cmpi eq, %352, %c0_i32 : i32
      %354 = arith.select %353, %c32_i32, %c-32_i32 : i32
      %355 = arith.andi %342, %c896_i32 : i32
      %356 = arith.shrsi %355, %c3_i32 : i32
      %357 = arith.xori %342, %356 : i32
      %358 = arith.addi %357, %348 : i32
      %iv_168 = cute.assume(%358) : (i32) -> !cute.i32<divby 8>
      %int_tuple_169 = cute.make_int_tuple(%iv_168) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_170 = cute.add_offset(%iter_124, %int_tuple_169) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_171 = cute.assume(%351) : (i32) -> !cute.i32<divby 16>
      %iv_172 = cute.assume(%354) : (i32) -> !cute.i32<divby 32>
      %stride_173 = cute.make_stride(%iv_171, %iv_172) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,((?{div=16},?{div=32}),4096))">
      %lay_174 = cute.make_layout(%109, %stride_173) : !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">
      %iter_175 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %359 = arith.muli %309, %c64_i32 : i32
      %360 = arith.divsi %308, %c2_i32 : i32
      %361 = arith.remsi %360, %c2_i32 : i32
      %362 = arith.muli %361, %c512_i32 : i32
      %363 = arith.addi %359, %362 : i32
      %364 = arith.remsi %308, %c2_i32 : i32
      %365 = arith.muli %364, %c8_i32 : i32
      %366 = arith.andi %363, %c128_i32 : i32
      %367 = arith.cmpi eq, %366, %c0_i32 : i32
      %368 = arith.select %367, %c16_i32, %c-16_i32 : i32
      %369 = arith.andi %363, %c256_i32 : i32
      %370 = arith.cmpi eq, %369, %c0_i32 : i32
      %371 = arith.select %370, %c32_i32, %c-32_i32 : i32
      %372 = arith.andi %363, %c896_i32 : i32
      %373 = arith.shrsi %372, %c3_i32 : i32
      %374 = arith.xori %363, %373 : i32
      %375 = arith.addi %374, %365 : i32
      %iv_176 = cute.assume(%375) : (i32) -> !cute.i32<divby 8>
      %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_178 = cute.add_offset(%iter_125, %int_tuple_177) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %iv_179 = cute.assume(%368) : (i32) -> !cute.i32<divby 16>
      %iv_180 = cute.assume(%371) : (i32) -> !cute.i32<divby 32>
      %stride_181 = cute.make_stride(%iv_179, %iv_180) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),1024,((?{div=16},?{div=32}),4096))">
      %lay_182 = cute.make_layout(%108, %stride_181) : !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">
      %iter_183 = cute.get_iter(%rmem_164) : !memref_rmem_bf16_1
      %376 = arith.addi %357, %346 : i32
      %iv_184 = cute.assume(%376) : (i32) -> !cute.i32<divby 8>
      %int_tuple_185 = cute.make_int_tuple(%iv_184) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_186 = cute.add_offset(%iter_126, %int_tuple_185) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_187 = cute.make_stride(%iv_171, %iv_172) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096),1024)">
      %lay_188 = cute.make_layout(%107, %stride_187) : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iter_189 = cute.get_iter(%rmem_165) : !memref_rmem_bf16_2
      %ptr_190 = cute.add_offset(%iter_127, %int_tuple_169) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %stride_191 = cute.make_stride(%iv_171, %iv_172) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_192 = cute.make_layout(%106, %stride_191) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %itup_193 = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_194 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_195 = cute.to_int_tuple(%e3) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_196 = cute.make_shape(%itup_193, %itup, %itup_194, %itup_195) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_197 = cute.make_layout(%shape_196, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %itup_198 = cute.to_int_tuple(%e0_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_199 = cute.to_int_tuple(%e2_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_200 = cute.to_int_tuple(%e3_14) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_201 = cute.make_shape(%itup_198, %itup_15, %itup_199, %itup_200) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_202 = cute.make_layout(%shape_201, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %377 = cute.get_shape(%lay_93) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_203, %e1_204, %e2_205, %e3_206 = cute.get_leaves(%377) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_207 = cute.to_int_tuple(%e0_203) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_208 = cute.to_int_tuple(%e1_204) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_209 = cute.to_int_tuple(%e2_205) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_210 = cute.to_int_tuple(%e3_206) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_211 = cute.make_shape(%itup_207, %itup_208, %itup_209, %itup_210) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_212 = cute.make_layout(%shape_211, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %378:4 = cute.get_scalars(%lay_197) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_213 = cute.assume(%378#3) : (i32) -> !cute.i32<divby 8>
      %shape_214 = cute.make_shape(%378#1, %iv_213) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_215 = cute.make_layout(%shape_214, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_216 = cute.crd2idx(%coord, %lay_197) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup = cute.add_offset(%105, %idx_216) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %379:2 = cute.get_scalars(%lay_215) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_217 = arith.constant 1 : i32
      %c0_i32_218 = arith.constant 0 : i32
      %c-1_i32_219 = arith.constant -1 : i32
      %380 = arith.cmpi sgt, %c64_i32, %c0_i32_218 : i32
      %381 = arith.select %380, %c-1_i32_219, %c1_i32_217 : i32
      %382 = arith.addi %381, %379#0 : i32
      %383 = arith.divsi %382, %c64_i32 : i32
      %384 = arith.addi %c1_i32_217, %383 : i32
      %385 = arith.subi %c0_i32_218, %379#0 : i32
      %386 = arith.divsi %385, %c64_i32 : i32
      %387 = arith.subi %c0_i32_218, %386 : i32
      %388 = arith.cmpi slt, %379#0, %c0_i32_218 : i32
      %389 = arith.cmpi sgt, %379#0, %c0_i32_218 : i32
      %390 = arith.cmpi slt, %c64_i32, %c0_i32_218 : i32
      %391 = arith.cmpi sgt, %c64_i32, %c0_i32_218 : i32
      %392 = arith.andi %388, %390 : i1
      %393 = arith.andi %389, %391 : i1
      %394 = arith.ori %392, %393 : i1
      %395 = arith.select %394, %384, %387 : i32
      %c1_i32_220 = arith.constant 1 : i32
      %c0_i32_221 = arith.constant 0 : i32
      %c-1_i32_222 = arith.constant -1 : i32
      %396 = arith.cmpi sgt, %c128_i32, %c0_i32_221 : i32
      %397 = arith.select %396, %c-1_i32_222, %c1_i32_220 : i32
      %398 = arith.addi %397, %379#1 : i32
      %399 = arith.divsi %398, %c128_i32 : i32
      %400 = arith.addi %c1_i32_220, %399 : i32
      %401 = arith.subi %c0_i32_221, %379#1 : i32
      %402 = arith.divsi %401, %c128_i32 : i32
      %403 = arith.subi %c0_i32_221, %402 : i32
      %404 = arith.cmpi slt, %379#1, %c0_i32_221 : i32
      %405 = arith.cmpi sgt, %379#1, %c0_i32_221 : i32
      %406 = arith.cmpi slt, %c128_i32, %c0_i32_221 : i32
      %407 = arith.cmpi sgt, %c128_i32, %c0_i32_221 : i32
      %408 = arith.andi %404, %406 : i1
      %409 = arith.andi %405, %407 : i1
      %410 = arith.ori %408, %409 : i1
      %411 = arith.select %410, %400, %403 : i32
      %shape_223 = cute.make_shape(%395, %411) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_224 = cute.make_layout(%shape_223, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_225 = cute.crd2idx(%coord_26, %lay_224) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_226 = cute.add_offset(%tup, %idx_225) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %412:4 = cute.get_scalars(%lay_202) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_227 = cute.assume(%412#3) : (i32) -> !cute.i32<divby 8>
      %shape_228 = cute.make_shape(%412#1, %iv_227) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_229 = cute.make_layout(%shape_228, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_230 = cute.crd2idx(%coord, %lay_202) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_231 = cute.add_offset(%105, %idx_230) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %coord_232 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0)">
      %413 = cute.get_scalars(%coord_232) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_233 = cute.make_coord(%413) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %414:2 = cute.get_scalars(%lay_229) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_234 = arith.constant 1 : i32
      %c0_i32_235 = arith.constant 0 : i32
      %c-1_i32_236 = arith.constant -1 : i32
      %415 = arith.cmpi sgt, %c64_i32, %c0_i32_235 : i32
      %416 = arith.select %415, %c-1_i32_236, %c1_i32_234 : i32
      %417 = arith.addi %416, %414#0 : i32
      %418 = arith.divsi %417, %c64_i32 : i32
      %419 = arith.addi %c1_i32_234, %418 : i32
      %420 = arith.subi %c0_i32_235, %414#0 : i32
      %421 = arith.divsi %420, %c64_i32 : i32
      %422 = arith.subi %c0_i32_235, %421 : i32
      %423 = arith.cmpi slt, %414#0, %c0_i32_235 : i32
      %424 = arith.cmpi sgt, %414#0, %c0_i32_235 : i32
      %425 = arith.cmpi slt, %c64_i32, %c0_i32_235 : i32
      %426 = arith.cmpi sgt, %c64_i32, %c0_i32_235 : i32
      %427 = arith.andi %423, %425 : i1
      %428 = arith.andi %424, %426 : i1
      %429 = arith.ori %427, %428 : i1
      %430 = arith.select %429, %419, %422 : i32
      %c1_i32_237 = arith.constant 1 : i32
      %c0_i32_238 = arith.constant 0 : i32
      %c-1_i32_239 = arith.constant -1 : i32
      %431 = arith.cmpi sgt, %c128_i32, %c0_i32_238 : i32
      %432 = arith.select %431, %c-1_i32_239, %c1_i32_237 : i32
      %433 = arith.addi %432, %414#1 : i32
      %434 = arith.divsi %433, %c128_i32 : i32
      %435 = arith.addi %c1_i32_237, %434 : i32
      %436 = arith.subi %c0_i32_238, %414#1 : i32
      %437 = arith.divsi %436, %c128_i32 : i32
      %438 = arith.subi %c0_i32_238, %437 : i32
      %439 = arith.cmpi slt, %414#1, %c0_i32_238 : i32
      %440 = arith.cmpi sgt, %414#1, %c0_i32_238 : i32
      %441 = arith.cmpi slt, %c128_i32, %c0_i32_238 : i32
      %442 = arith.cmpi sgt, %c128_i32, %c0_i32_238 : i32
      %443 = arith.andi %439, %441 : i1
      %444 = arith.andi %440, %442 : i1
      %445 = arith.ori %443, %444 : i1
      %446 = arith.select %445, %435, %438 : i32
      %shape_240 = cute.make_shape(%430, %446) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_241 = cute.make_layout(%shape_240, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_242 = cute.crd2idx(%coord_233, %lay_241) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_243 = cute.add_offset(%tup_231, %idx_242) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %447:4 = cute.get_scalars(%lay_212) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_244 = cute.assume(%447#3) : (i32) -> !cute.i32<divby 8>
      %shape_245 = cute.make_shape(%447#2, %iv_244) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_246 = cute.make_layout(%shape_245, %101) : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %idx_247 = cute.crd2idx(%coord_92, %lay_212) : (!cute.coord<"(?,?,_,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,?,0,0)">
      %tup_248 = cute.add_offset(%105, %idx_247) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,?,0,0)">) -> !cute.int_tuple<"(?,?,0,0)">
      %448:2 = cute.get_scalars(%lay_246) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@2,1@3)">
      %c1_i32_249 = arith.constant 1 : i32
      %c0_i32_250 = arith.constant 0 : i32
      %c-1_i32_251 = arith.constant -1 : i32
      %449 = arith.cmpi sgt, %c64_i32, %c0_i32_250 : i32
      %450 = arith.select %449, %c-1_i32_251, %c1_i32_249 : i32
      %451 = arith.addi %450, %448#0 : i32
      %452 = arith.divsi %451, %c64_i32 : i32
      %453 = arith.addi %c1_i32_249, %452 : i32
      %454 = arith.subi %c0_i32_250, %448#0 : i32
      %455 = arith.divsi %454, %c64_i32 : i32
      %456 = arith.subi %c0_i32_250, %455 : i32
      %457 = arith.cmpi slt, %448#0, %c0_i32_250 : i32
      %458 = arith.cmpi sgt, %448#0, %c0_i32_250 : i32
      %459 = arith.cmpi slt, %c64_i32, %c0_i32_250 : i32
      %460 = arith.cmpi sgt, %c64_i32, %c0_i32_250 : i32
      %461 = arith.andi %457, %459 : i1
      %462 = arith.andi %458, %460 : i1
      %463 = arith.ori %461, %462 : i1
      %464 = arith.select %463, %453, %456 : i32
      %c1_i32_252 = arith.constant 1 : i32
      %c0_i32_253 = arith.constant 0 : i32
      %c-1_i32_254 = arith.constant -1 : i32
      %465 = arith.cmpi sgt, %c64_i32, %c0_i32_253 : i32
      %466 = arith.select %465, %c-1_i32_254, %c1_i32_252 : i32
      %467 = arith.addi %466, %448#1 : i32
      %468 = arith.divsi %467, %c64_i32 : i32
      %469 = arith.addi %c1_i32_252, %468 : i32
      %470 = arith.subi %c0_i32_253, %448#1 : i32
      %471 = arith.divsi %470, %c64_i32 : i32
      %472 = arith.subi %c0_i32_253, %471 : i32
      %473 = arith.cmpi slt, %448#1, %c0_i32_253 : i32
      %474 = arith.cmpi sgt, %448#1, %c0_i32_253 : i32
      %475 = arith.cmpi slt, %c64_i32, %c0_i32_253 : i32
      %476 = arith.cmpi sgt, %c64_i32, %c0_i32_253 : i32
      %477 = arith.andi %473, %475 : i1
      %478 = arith.andi %474, %476 : i1
      %479 = arith.ori %477, %478 : i1
      %480 = arith.select %479, %469, %472 : i32
      %shape_255 = cute.make_shape(%464, %480) : (i32, i32) -> !cute.shape<"((64,64),(?,?))">
      %lay_256 = cute.make_layout(%shape_255, %100) : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %481:2 = cute.get_scalars(%lay_256) <{only_dynamic}> : !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">
      %shape_257 = cute.make_shape(%481#1) : (i32) -> !cute.shape<"(64,64,?)">
      %lay_258 = cute.make_layout(%shape_257, %99) : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %idx_259 = cute.crd2idx(%coord_103, %lay_256) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((64,64),(?,?)):((1@2,1@3),(64@2,64@3))">) -> !cute.int_tuple<"(0,0,?{div=64},0)">
      %tup_260 = cute.add_offset(%tup_248, %idx_259) : (!cute.int_tuple<"(?,?,0,0)">, !cute.int_tuple<"(0,0,?{div=64},0)">) -> !cute.int_tuple<"(?,?,?{div=64},0)">
      %iv_261 = cute.assume(%310) : (i32) -> !cute.i32<divby 8>
      %int_tuple_262 = cute.make_int_tuple(%308, %iv_261) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,?,0,?{div=8})">
      %tup_263 = cute.add_offset(%tup_226, %int_tuple_262) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %tup_264 = cute.add_offset(%tup_243, %int_tuple_262) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %482 = cute.get_scalars(%lay_258) <{only_dynamic}> : !cute.layout<"(64,64,?):(1@2,1@3,64@3)">
      %int_tuple_265 = cute.make_int_tuple(%308, %iv_261) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(0,0,?,?{div=8})">
      %tup_266 = cute.add_offset(%tup_260, %int_tuple_265) : (!cute.int_tuple<"(?,?,?{div=64},0)">, !cute.int_tuple<"(0,0,?,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %shape_267 = cute.make_shape(%482) : (i32) -> !cute.shape<"((8,1),4,1,?)">
      %lay_268 = cute.make_layout(%shape_267, %98) : !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">
      %rmem_269 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_270 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_271, %e1_272, %e2_273, %e3_274 = cute.get_leaves(%tup_263) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_275 = cute.make_coord(%e3_274) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_276 = cute.make_coord(%itup_195) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %483 = cute.get_scalars(%coord_275) : !cute.coord<"?{div=8}">
      %484 = cute.get_scalars(%coord_276) : !cute.coord<"?{div=8}">
      %485 = arith.cmpi slt, %483, %484 : i32
      %486 = arith.extui %485 : i1 to i8
      cute.memref.store(%rmem_269, %97, %486) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_277 = cute.add_offset(%tup_263, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_278, %e1_279, %e2_280, %e3_281 = cute.get_leaves(%tup_277) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_282 = cute.make_coord(%e3_281) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %487 = cute.get_scalars(%coord_282) : !cute.coord<"?{div=8}">
      %488 = arith.cmpi slt, %487, %484 : i32
      %489 = arith.extui %488 : i1 to i8
      cute.memref.store(%rmem_269, %95, %489) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %e0_283, %e1_284, %e2_285, %e3_286 = cute.get_leaves(%tup_264) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_287 = cute.make_coord(%e3_286) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_288 = cute.make_coord(%itup_200) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %490 = cute.get_scalars(%coord_287) : !cute.coord<"?{div=8}">
      %491 = cute.get_scalars(%coord_288) : !cute.coord<"?{div=8}">
      %492 = arith.cmpi slt, %490, %491 : i32
      %493 = arith.extui %492 : i1 to i8
      cute.memref.store(%rmem_270, %97, %493) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_289 = cute.add_offset(%tup_264, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_290, %e1_291, %e2_292, %e3_293 = cute.get_leaves(%tup_289) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_294 = cute.make_coord(%e3_293) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %494 = cute.get_scalars(%coord_294) : !cute.coord<"?{div=8}">
      %495 = arith.cmpi slt, %494, %491 : i32
      %496 = arith.extui %495 : i1 to i8
      cute.memref.store(%rmem_270, %95, %496) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_295 = cute.make_coord(%e1_272) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_296 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %497 = cute.get_scalars(%coord_295) : !cute.coord<"?">
      %498 = cute.get_scalars(%coord_296) : !cute.coord<"?">
      %499 = arith.cmpi slt, %497, %498 : i32
      cf.cond_br %499, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %iter_297 = cute.get_iter(%rmem_269) : !memref_rmem_i8_
      %500 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%501: i32):  // 2 preds: ^bb1, ^bb3
      %502 = arith.cmpi slt, %501, %500 : i32
      cf.cond_br %502, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_298 = cute.make_coord(%501) : (i32) -> !cute.coord<"(_,?)">
      %idx_299 = cute.crd2idx(%coord_298, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_300 = cute.add_offset(%ptr_131, %idx_299) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_301 = cute.crd2idx(%coord_298, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_302 = cute.add_offset(%ptr_137, %idx_301) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_303 = cute.crd2idx(%coord_298, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_304 = cute.add_offset(%iter_297, %idx_303) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %503 = builtin.unrealized_conversion_cast %ptr_304 : !cute.ptr<i8, rmem> to !llvm.ptr
      %504 = llvm.load %503 : !llvm.ptr -> i8
      %505 = llvm.trunc %504 : i8 to i1
      %iter_305 = cute.recast_iter(%ptr_300) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_306 = cute.recast_iter(%ptr_302) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_306 : !cute.ptr<i128, smem>, %iter_305 : !cute.ptr<i128, gmem>, %505 : i1) {cache_mode = <always>}
      %506 = arith.addi %501, %c1_i32 : i32
      cf.br ^bb2(%506 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb6
    ^bb5:  // pred: ^bb0
      %view = cute.make_view(%ptr_137) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view, row_major : !memref_smem_bf16_
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %tup_307 = cute.add_offset(%tup_263, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_308, %e1_309, %e2_310, %e3_311 = cute.get_leaves(%tup_307) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_312 = cute.make_coord(%e1_309) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %507 = cute.get_scalars(%coord_312) : !cute.coord<"?">
      %508 = arith.cmpi slt, %507, %498 : i32
      cf.cond_br %508, ^bb7, ^bb11
    ^bb7:  // pred: ^bb6
      %idx_313 = cute.crd2idx(%89, %lay_134) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_314 = cute.add_offset(%ptr_131, %idx_313) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_315 = cute.add_offset(%ptr_137, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_316 = cute.get_iter(%rmem_269) : !memref_rmem_i8_
      %509 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb8(%c0_i32 : i32)
    ^bb8(%510: i32):  // 2 preds: ^bb7, ^bb9
      %511 = arith.cmpi slt, %510, %509 : i32
      cf.cond_br %511, ^bb9, ^bb10 {llvm.loop_annotation = #loop_annotation}
    ^bb9:  // pred: ^bb8
      %coord_317 = cute.make_coord(%510) : (i32) -> !cute.coord<"(_,?)">
      %idx_318 = cute.crd2idx(%coord_317, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_319 = cute.add_offset(%ptr_314, %idx_318) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_320 = cute.crd2idx(%coord_317, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_321 = cute.add_offset(%ptr_315, %idx_320) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_322 = cute.crd2idx(%coord_317, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_323 = cute.add_offset(%iter_316, %idx_322) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %512 = builtin.unrealized_conversion_cast %ptr_323 : !cute.ptr<i8, rmem> to !llvm.ptr
      %513 = llvm.load %512 : !llvm.ptr -> i8
      %514 = llvm.trunc %513 : i8 to i1
      %iter_324 = cute.recast_iter(%ptr_319) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_325 = cute.recast_iter(%ptr_321) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_325 : !cute.ptr<i128, smem>, %iter_324 : !cute.ptr<i128, gmem>, %514 : i1) {cache_mode = <always>}
      %515 = arith.addi %510, %c1_i32 : i32
      cf.br ^bb8(%515 : i32)
    ^bb10:  // pred: ^bb8
      cf.br ^bb12
    ^bb11:  // pred: ^bb6
      %ptr_326 = cute.add_offset(%ptr_137, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_327 = cute.make_view(%ptr_326) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_327, row_major : !memref_smem_bf16_
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %tup_328 = cute.add_offset(%tup_263, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_329, %e1_330, %e2_331, %e3_332 = cute.get_leaves(%tup_328) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_333 = cute.make_coord(%e1_330) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %516 = cute.get_scalars(%coord_333) : !cute.coord<"?">
      %517 = arith.cmpi slt, %516, %498 : i32
      cf.cond_br %517, ^bb13, ^bb17
    ^bb13:  // pred: ^bb12
      %idx_334 = cute.crd2idx(%86, %lay_134) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_335 = cute.add_offset(%ptr_131, %idx_334) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_336 = cute.add_offset(%ptr_137, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_337 = cute.get_iter(%rmem_269) : !memref_rmem_i8_
      %518 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb14(%c0_i32 : i32)
    ^bb14(%519: i32):  // 2 preds: ^bb13, ^bb15
      %520 = arith.cmpi slt, %519, %518 : i32
      cf.cond_br %520, ^bb15, ^bb16 {llvm.loop_annotation = #loop_annotation}
    ^bb15:  // pred: ^bb14
      %coord_338 = cute.make_coord(%519) : (i32) -> !cute.coord<"(_,?)">
      %idx_339 = cute.crd2idx(%coord_338, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_340 = cute.add_offset(%ptr_335, %idx_339) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_341 = cute.crd2idx(%coord_338, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_342 = cute.add_offset(%ptr_336, %idx_341) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_343 = cute.crd2idx(%coord_338, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_344 = cute.add_offset(%iter_337, %idx_343) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %521 = builtin.unrealized_conversion_cast %ptr_344 : !cute.ptr<i8, rmem> to !llvm.ptr
      %522 = llvm.load %521 : !llvm.ptr -> i8
      %523 = llvm.trunc %522 : i8 to i1
      %iter_345 = cute.recast_iter(%ptr_340) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_346 = cute.recast_iter(%ptr_342) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_346 : !cute.ptr<i128, smem>, %iter_345 : !cute.ptr<i128, gmem>, %523 : i1) {cache_mode = <always>}
      %524 = arith.addi %519, %c1_i32 : i32
      cf.br ^bb14(%524 : i32)
    ^bb16:  // pred: ^bb14
      cf.br ^bb18
    ^bb17:  // pred: ^bb12
      %ptr_347 = cute.add_offset(%ptr_137, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_348 = cute.make_view(%ptr_347) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_348, row_major : !memref_smem_bf16_
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      %tup_349 = cute.add_offset(%tup_263, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_350, %e1_351, %e2_352, %e3_353 = cute.get_leaves(%tup_349) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_354 = cute.make_coord(%e1_351) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %525 = cute.get_scalars(%coord_354) : !cute.coord<"?">
      %526 = arith.cmpi slt, %525, %498 : i32
      cf.cond_br %526, ^bb19, ^bb23
    ^bb19:  // pred: ^bb18
      %idx_355 = cute.crd2idx(%83, %lay_134) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_356 = cute.add_offset(%ptr_131, %idx_355) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_357 = cute.add_offset(%ptr_137, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_358 = cute.get_iter(%rmem_269) : !memref_rmem_i8_
      %527 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb20(%c0_i32 : i32)
    ^bb20(%528: i32):  // 2 preds: ^bb19, ^bb21
      %529 = arith.cmpi slt, %528, %527 : i32
      cf.cond_br %529, ^bb21, ^bb22 {llvm.loop_annotation = #loop_annotation}
    ^bb21:  // pred: ^bb20
      %coord_359 = cute.make_coord(%528) : (i32) -> !cute.coord<"(_,?)">
      %idx_360 = cute.crd2idx(%coord_359, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_361 = cute.add_offset(%ptr_356, %idx_360) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_362 = cute.crd2idx(%coord_359, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_363 = cute.add_offset(%ptr_357, %idx_362) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_364 = cute.crd2idx(%coord_359, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_365 = cute.add_offset(%iter_358, %idx_364) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %530 = builtin.unrealized_conversion_cast %ptr_365 : !cute.ptr<i8, rmem> to !llvm.ptr
      %531 = llvm.load %530 : !llvm.ptr -> i8
      %532 = llvm.trunc %531 : i8 to i1
      %iter_366 = cute.recast_iter(%ptr_361) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_367 = cute.recast_iter(%ptr_363) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_367 : !cute.ptr<i128, smem>, %iter_366 : !cute.ptr<i128, gmem>, %532 : i1) {cache_mode = <always>}
      %533 = arith.addi %528, %c1_i32 : i32
      cf.br ^bb20(%533 : i32)
    ^bb22:  // pred: ^bb20
      cf.br ^bb24
    ^bb23:  // pred: ^bb18
      %ptr_368 = cute.add_offset(%ptr_137, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_369 = cute.make_view(%ptr_368) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_369, row_major : !memref_smem_bf16_
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %coord_370 = cute.make_coord(%e1_284) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_371 = cute.make_coord(%itup_15) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %534 = cute.get_scalars(%coord_370) : !cute.coord<"?">
      %535 = cute.get_scalars(%coord_371) : !cute.coord<"?">
      %536 = arith.cmpi slt, %534, %535 : i32
      cf.cond_br %536, ^bb25, ^bb29
    ^bb25:  // pred: ^bb24
      %coord_372 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_373 = cute.crd2idx(%coord_372, %lay_145) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_374 = cute.add_offset(%ptr_140, %idx_373) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_375 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %537 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb26(%c0_i32 : i32)
    ^bb26(%538: i32):  // 2 preds: ^bb25, ^bb27
      %539 = arith.cmpi slt, %538, %537 : i32
      cf.cond_br %539, ^bb27, ^bb28 {llvm.loop_annotation = #loop_annotation}
    ^bb27:  // pred: ^bb26
      %coord_376 = cute.make_coord(%538) : (i32) -> !cute.coord<"(_,?)">
      %idx_377 = cute.crd2idx(%coord_376, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_378 = cute.add_offset(%ptr_374, %idx_377) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_379 = cute.crd2idx(%coord_376, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_380 = cute.add_offset(%ptr_146, %idx_379) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_381 = cute.crd2idx(%coord_376, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_382 = cute.add_offset(%iter_375, %idx_381) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %540 = builtin.unrealized_conversion_cast %ptr_382 : !cute.ptr<i8, rmem> to !llvm.ptr
      %541 = llvm.load %540 : !llvm.ptr -> i8
      %542 = llvm.trunc %541 : i8 to i1
      %iter_383 = cute.recast_iter(%ptr_378) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_384 = cute.recast_iter(%ptr_380) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_384 : !cute.ptr<i128, smem>, %iter_383 : !cute.ptr<i128, gmem>, %542 : i1) {cache_mode = <always>}
      %543 = arith.addi %538, %c1_i32 : i32
      cf.br ^bb26(%543 : i32)
    ^bb28:  // pred: ^bb26
      cf.br ^bb30
    ^bb29:  // pred: ^bb24
      %view_385 = cute.make_view(%ptr_146) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_385, row_major : !memref_smem_bf16_
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      %tup_386 = cute.add_offset(%tup_264, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_387, %e1_388, %e2_389, %e3_390 = cute.get_leaves(%tup_386) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_391 = cute.make_coord(%e1_388) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %544 = cute.get_scalars(%coord_391) : !cute.coord<"?">
      %545 = arith.cmpi slt, %544, %535 : i32
      cf.cond_br %545, ^bb31, ^bb35
    ^bb31:  // pred: ^bb30
      %coord_392 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_393 = cute.crd2idx(%coord_392, %lay_145) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_394 = cute.add_offset(%ptr_140, %idx_393) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_395 = cute.add_offset(%ptr_146, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_396 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %546 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%547: i32):  // 2 preds: ^bb31, ^bb33
      %548 = arith.cmpi slt, %547, %546 : i32
      cf.cond_br %548, ^bb33, ^bb34 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_397 = cute.make_coord(%547) : (i32) -> !cute.coord<"(_,?)">
      %idx_398 = cute.crd2idx(%coord_397, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_399 = cute.add_offset(%ptr_394, %idx_398) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_400 = cute.crd2idx(%coord_397, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_401 = cute.add_offset(%ptr_395, %idx_400) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_402 = cute.crd2idx(%coord_397, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_403 = cute.add_offset(%iter_396, %idx_402) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %549 = builtin.unrealized_conversion_cast %ptr_403 : !cute.ptr<i8, rmem> to !llvm.ptr
      %550 = llvm.load %549 : !llvm.ptr -> i8
      %551 = llvm.trunc %550 : i8 to i1
      %iter_404 = cute.recast_iter(%ptr_399) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_405 = cute.recast_iter(%ptr_401) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_405 : !cute.ptr<i128, smem>, %iter_404 : !cute.ptr<i128, gmem>, %551 : i1) {cache_mode = <always>}
      %552 = arith.addi %547, %c1_i32 : i32
      cf.br ^bb32(%552 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb36
    ^bb35:  // pred: ^bb30
      %ptr_406 = cute.add_offset(%ptr_146, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_407 = cute.make_view(%ptr_406) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_407, row_major : !memref_smem_bf16_
      cf.br ^bb36
    ^bb36:  // 2 preds: ^bb34, ^bb35
      %tup_408 = cute.add_offset(%tup_264, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_409, %e1_410, %e2_411, %e3_412 = cute.get_leaves(%tup_408) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_413 = cute.make_coord(%e1_410) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %553 = cute.get_scalars(%coord_413) : !cute.coord<"?">
      %554 = arith.cmpi slt, %553, %535 : i32
      cf.cond_br %554, ^bb37, ^bb41
    ^bb37:  // pred: ^bb36
      %coord_414 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_415 = cute.crd2idx(%coord_414, %lay_145) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_416 = cute.add_offset(%ptr_140, %idx_415) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_417 = cute.add_offset(%ptr_146, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_418 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %555 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%556: i32):  // 2 preds: ^bb37, ^bb39
      %557 = arith.cmpi slt, %556, %555 : i32
      cf.cond_br %557, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_419 = cute.make_coord(%556) : (i32) -> !cute.coord<"(_,?)">
      %idx_420 = cute.crd2idx(%coord_419, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_421 = cute.add_offset(%ptr_416, %idx_420) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_422 = cute.crd2idx(%coord_419, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_423 = cute.add_offset(%ptr_417, %idx_422) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_424 = cute.crd2idx(%coord_419, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_425 = cute.add_offset(%iter_418, %idx_424) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %558 = builtin.unrealized_conversion_cast %ptr_425 : !cute.ptr<i8, rmem> to !llvm.ptr
      %559 = llvm.load %558 : !llvm.ptr -> i8
      %560 = llvm.trunc %559 : i8 to i1
      %iter_426 = cute.recast_iter(%ptr_421) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_427 = cute.recast_iter(%ptr_423) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_427 : !cute.ptr<i128, smem>, %iter_426 : !cute.ptr<i128, gmem>, %560 : i1) {cache_mode = <always>}
      %561 = arith.addi %556, %c1_i32 : i32
      cf.br ^bb38(%561 : i32)
    ^bb40:  // pred: ^bb38
      cf.br ^bb42
    ^bb41:  // pred: ^bb36
      %ptr_428 = cute.add_offset(%ptr_146, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_429 = cute.make_view(%ptr_428) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_429, row_major : !memref_smem_bf16_
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      %tup_430 = cute.add_offset(%tup_264, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_431, %e1_432, %e2_433, %e3_434 = cute.get_leaves(%tup_430) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_435 = cute.make_coord(%e1_432) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %562 = cute.get_scalars(%coord_435) : !cute.coord<"?">
      %563 = arith.cmpi slt, %562, %535 : i32
      cf.cond_br %563, ^bb43, ^bb47
    ^bb43:  // pred: ^bb42
      %coord_436 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_437 = cute.crd2idx(%coord_436, %lay_145) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_438 = cute.add_offset(%ptr_140, %idx_437) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_439 = cute.add_offset(%ptr_146, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_440 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %564 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%565: i32):  // 2 preds: ^bb43, ^bb45
      %566 = arith.cmpi slt, %565, %564 : i32
      cf.cond_br %566, ^bb45, ^bb46 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %coord_441 = cute.make_coord(%565) : (i32) -> !cute.coord<"(_,?)">
      %idx_442 = cute.crd2idx(%coord_441, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_443 = cute.add_offset(%ptr_438, %idx_442) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_444 = cute.crd2idx(%coord_441, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_445 = cute.add_offset(%ptr_439, %idx_444) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_446 = cute.crd2idx(%coord_441, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_447 = cute.add_offset(%iter_440, %idx_446) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %567 = builtin.unrealized_conversion_cast %ptr_447 : !cute.ptr<i8, rmem> to !llvm.ptr
      %568 = llvm.load %567 : !llvm.ptr -> i8
      %569 = llvm.trunc %568 : i8 to i1
      %iter_448 = cute.recast_iter(%ptr_443) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_449 = cute.recast_iter(%ptr_445) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_449 : !cute.ptr<i128, smem>, %iter_448 : !cute.ptr<i128, gmem>, %569 : i1) {cache_mode = <always>}
      %570 = arith.addi %565, %c1_i32 : i32
      cf.br ^bb44(%570 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb48
    ^bb47:  // pred: ^bb42
      %ptr_450 = cute.add_offset(%ptr_146, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_451 = cute.make_view(%ptr_450) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_451, row_major : !memref_smem_bf16_
      cf.br ^bb48
    ^bb48:  // 2 preds: ^bb46, ^bb47
      %coord_452 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,0,0,?)">
      %idx_453 = cute.crd2idx(%coord_452, %lay_268) : (!cute.coord<"(0,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,0,?{div=64})">
      %tup_454 = cute.add_offset(%tup_266, %idx_453) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_455, %e1_456, %e2_457, %e3_458 = cute.get_leaves(%tup_454) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_459 = cute.make_coord(%e1_456) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_460 = cute.make_coord(%itup_209) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %571 = cute.get_scalars(%coord_459) : !cute.coord<"?">
      %572 = cute.get_scalars(%coord_460) : !cute.coord<"?">
      %573 = arith.cmpi slt, %571, %572 : i32
      %coord_461 = cute.make_coord(%e2_457) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_462 = cute.make_coord(%itup_210) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %574 = cute.get_scalars(%coord_461) : !cute.coord<"?">
      %575 = cute.get_scalars(%coord_462) : !cute.coord<"?{div=8}">
      %576 = arith.cmpi slt, %574, %575 : i32
      %577 = arith.extui %573 : i1 to i32
      %578 = arith.extui %576 : i1 to i32
      %579 = arith.select %573, %578, %577 : i32
      %580 = arith.cmpi ne, %579, %c0_i32 : i32
      cf.cond_br %580, ^bb49, ^bb53
    ^bb49:  // pred: ^bb48
      %coord_463 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,0,?)">
      %idx_464 = cute.crd2idx(%coord_463, %lay_162) : (!cute.coord<"(_,0,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_465 = cute.add_offset(%ptr_158, %idx_464) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %581 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_466 = cute.recast_iter(%ptr_465) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_467 = cute.recast_iter(%ptr_163) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb50(%c0_i32 : i32)
    ^bb50(%582: i32):  // 2 preds: ^bb49, ^bb51
      %583 = arith.cmpi slt, %582, %581 : i32
      cf.cond_br %583, ^bb51, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb51:  // pred: ^bb50
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_467 : !cute.ptr<i128, smem>, %iter_466 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %584 = arith.addi %582, %c1_i32 : i32
      cf.br ^bb50(%584 : i32)
    ^bb52:  // pred: ^bb50
      cf.br ^bb54
    ^bb53:  // pred: ^bb48
      %view_468 = cute.make_view(%ptr_163) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_468, row_major : !memref_smem_bf16_1
      cf.br ^bb54
    ^bb54:  // 2 preds: ^bb52, ^bb53
      %coord_469 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,1,0,?)">
      %idx_470 = cute.crd2idx(%coord_469, %lay_268) : (!cute.coord<"(0,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,16,?{div=64})">
      %tup_471 = cute.add_offset(%tup_266, %idx_470) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,16,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_472, %e1_473, %e2_474, %e3_475 = cute.get_leaves(%tup_471) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_476 = cute.make_coord(%e1_473) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %585 = cute.get_scalars(%coord_476) : !cute.coord<"?">
      %586 = arith.cmpi slt, %585, %572 : i32
      %coord_477 = cute.make_coord(%e2_474) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %587 = cute.get_scalars(%coord_477) : !cute.coord<"?">
      %588 = arith.cmpi slt, %587, %575 : i32
      %589 = arith.extui %586 : i1 to i32
      %590 = arith.extui %588 : i1 to i32
      %591 = arith.select %586, %590, %589 : i32
      %592 = arith.cmpi ne, %591, %c0_i32 : i32
      cf.cond_br %592, ^bb55, ^bb59
    ^bb55:  // pred: ^bb54
      %coord_478 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,0,?)">
      %idx_479 = cute.crd2idx(%coord_478, %lay_162) : (!cute.coord<"(_,1,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_480 = cute.add_offset(%ptr_158, %idx_479) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_481 = cute.add_offset(%ptr_163, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %593 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_482 = cute.recast_iter(%ptr_480) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_483 = cute.recast_iter(%ptr_481) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%594: i32):  // 2 preds: ^bb55, ^bb57
      %595 = arith.cmpi slt, %594, %593 : i32
      cf.cond_br %595, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_483 : !cute.ptr<i128, smem>, %iter_482 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %596 = arith.addi %594, %c1_i32 : i32
      cf.br ^bb56(%596 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb60
    ^bb59:  // pred: ^bb54
      %ptr_484 = cute.add_offset(%ptr_163, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_485 = cute.make_view(%ptr_484) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_485, row_major : !memref_smem_bf16_1
      cf.br ^bb60
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %coord_486 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,2,0,?)">
      %idx_487 = cute.crd2idx(%coord_486, %lay_268) : (!cute.coord<"(0,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,32,?{div=64})">
      %tup_488 = cute.add_offset(%tup_266, %idx_487) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,32,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_489, %e1_490, %e2_491, %e3_492 = cute.get_leaves(%tup_488) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_493 = cute.make_coord(%e1_490) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %597 = cute.get_scalars(%coord_493) : !cute.coord<"?">
      %598 = arith.cmpi slt, %597, %572 : i32
      %coord_494 = cute.make_coord(%e2_491) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %599 = cute.get_scalars(%coord_494) : !cute.coord<"?">
      %600 = arith.cmpi slt, %599, %575 : i32
      %601 = arith.extui %598 : i1 to i32
      %602 = arith.extui %600 : i1 to i32
      %603 = arith.select %598, %602, %601 : i32
      %604 = arith.cmpi ne, %603, %c0_i32 : i32
      cf.cond_br %604, ^bb61, ^bb65
    ^bb61:  // pred: ^bb60
      %coord_495 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,0,?)">
      %idx_496 = cute.crd2idx(%coord_495, %lay_162) : (!cute.coord<"(_,2,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_497 = cute.add_offset(%ptr_158, %idx_496) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_498 = cute.add_offset(%ptr_163, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %605 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_499 = cute.recast_iter(%ptr_497) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_500 = cute.recast_iter(%ptr_498) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%606: i32):  // 2 preds: ^bb61, ^bb63
      %607 = arith.cmpi slt, %606, %605 : i32
      cf.cond_br %607, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_500 : !cute.ptr<i128, smem>, %iter_499 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %608 = arith.addi %606, %c1_i32 : i32
      cf.br ^bb62(%608 : i32)
    ^bb64:  // pred: ^bb62
      cf.br ^bb66
    ^bb65:  // pred: ^bb60
      %ptr_501 = cute.add_offset(%ptr_163, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_502 = cute.make_view(%ptr_501) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_502, row_major : !memref_smem_bf16_1
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %coord_503 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(0,3,0,?)">
      %idx_504 = cute.crd2idx(%coord_503, %lay_268) : (!cute.coord<"(0,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1@3,0),16@2,0,64@3)">) -> !cute.int_tuple<"(0,0,48,?{div=64})">
      %tup_505 = cute.add_offset(%tup_266, %idx_504) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,48,?{div=64})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_506, %e1_507, %e2_508, %e3_509 = cute.get_leaves(%tup_505) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_510 = cute.make_coord(%e1_507) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %609 = cute.get_scalars(%coord_510) : !cute.coord<"?">
      %610 = arith.cmpi slt, %609, %572 : i32
      %coord_511 = cute.make_coord(%e2_508) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %611 = cute.get_scalars(%coord_511) : !cute.coord<"?">
      %612 = arith.cmpi slt, %611, %575 : i32
      %613 = arith.extui %610 : i1 to i32
      %614 = arith.extui %612 : i1 to i32
      %615 = arith.select %610, %614, %613 : i32
      %616 = arith.cmpi ne, %615, %c0_i32 : i32
      cf.cond_br %616, ^bb67, ^bb71
    ^bb67:  // pred: ^bb66
      %coord_512 = cute.make_coord(%sub_22) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,0,?)">
      %idx_513 = cute.crd2idx(%coord_512, %lay_162) : (!cute.coord<"(_,3,0,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_514 = cute.add_offset(%ptr_158, %idx_513) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_515 = cute.add_offset(%ptr_163, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %617 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %iter_516 = cute.recast_iter(%ptr_514) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_517 = cute.recast_iter(%ptr_515) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb68(%c0_i32 : i32)
    ^bb68(%618: i32):  // 2 preds: ^bb67, ^bb69
      %619 = arith.cmpi slt, %618, %617 : i32
      cf.cond_br %619, ^bb69, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb69:  // pred: ^bb68
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_517 : !cute.ptr<i128, smem>, %iter_516 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %620 = arith.addi %618, %c1_i32 : i32
      cf.br ^bb68(%620 : i32)
    ^bb70:  // pred: ^bb68
      cf.br ^bb72
    ^bb71:  // pred: ^bb66
      %ptr_518 = cute.add_offset(%ptr_163, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_519 = cute.make_view(%ptr_518) : !memref_smem_bf16_1
      cute.memref.store_vec %cst_0, %view_519, row_major : !memref_smem_bf16_1
      cf.br ^bb72
    ^bb72:  // 2 preds: ^bb70, ^bb71
      nvvm.cp.async.commit.group
      %tup_520 = cute.add_offset(%sub_22, %81) : (!cute.int_tuple<"?">, !cute.int_tuple<"-1">) -> !cute.int_tuple<"?">
      %621:2 = cute.get_scalars(%lay_192) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_521 = cute.assume(%621#0) : (i32) -> !cute.i32<divby 16>
      %iv_522 = cute.assume(%621#1) : (i32) -> !cute.i32<divby 32>
      %stride_523 = cute.make_stride(%iv_521, %iv_522) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),0,(?{div=16},?{div=32}))">
      %lay_524 = cute.make_layout(%106, %stride_523) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %append = cute.append_to_rank<2> (%lay_524, %117) : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">, !cute.layout<"1:0">
      %622:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((8,1),1,(2,2)):((1,0),0,(?{div=16},?{div=32}))">
      %iv_525 = cute.assume(%622#0) : (i32) -> !cute.i32<divby 16>
      %iv_526 = cute.assume(%622#1) : (i32) -> !cute.i32<divby 32>
      %stride_527 = cute.make_stride(%iv_525, %iv_526) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(0,(?{div=16},?{div=32})))">
      %lay_528 = cute.make_layout(%74, %stride_527) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %append_529 = cute.append_to_rank<2> (%lay_528, %117) : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">, !cute.layout<"1:0">
      %623:2 = cute.get_scalars(%append_529) <{only_dynamic}> : !cute.layout<"((8,1),(1,(2,2))):((1,0),(0,(?{div=16},?{div=32})))">
      %iv_530 = cute.assume(%623#0) : (i32) -> !cute.i32<divby 16>
      %iv_531 = cute.assume(%623#1) : (i32) -> !cute.i32<divby 32>
      %stride_532 = cute.make_stride(%iv_530, %iv_531) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((0,(?{div=16},?{div=32}))))">
      %lay_533 = cute.make_layout(%73, %stride_532) : !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">
      %624 = cute.get_scalars(%71) : !cute.int_tuple<"4">
      %625 = cute.get_scalars(%116) : !cute.int_tuple<"1">
      %626 = builtin.unrealized_conversion_cast %iter_175 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %ptr_534 = cute.add_offset(%iter_175, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %627 = builtin.unrealized_conversion_cast %ptr_534 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_535 = cute.add_offset(%iter_175, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %628 = builtin.unrealized_conversion_cast %ptr_535 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %ptr_536 = cute.add_offset(%iter_175, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %629 = builtin.unrealized_conversion_cast %ptr_536 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_537 = cute.crd2idx(%61, %lay_174) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_538 = cute.add_offset(%ptr_170, %idx_537) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_539 = cute.add_offset(%iter_175, %60) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<16>>
      %630 = builtin.unrealized_conversion_cast %ptr_539 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_540 = cute.make_int_tuple() : () -> !cute.int_tuple<"18">
      %ptr_541 = cute.add_offset(%iter_175, %int_tuple_540) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"18">) -> !cute.ptr<bf16, rmem, align<4>>
      %631 = builtin.unrealized_conversion_cast %ptr_541 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_542 = cute.make_int_tuple() : () -> !cute.int_tuple<"20">
      %ptr_543 = cute.add_offset(%iter_175, %int_tuple_542) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"20">) -> !cute.ptr<bf16, rmem, align<8>>
      %632 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_544 = cute.make_int_tuple() : () -> !cute.int_tuple<"22">
      %ptr_545 = cute.add_offset(%iter_175, %int_tuple_544) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"22">) -> !cute.ptr<bf16, rmem, align<4>>
      %633 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_546 = cute.crd2idx(%61, %lay_182) : (!cute.coord<"(_,_,1)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_547 = cute.add_offset(%ptr_178, %idx_546) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_548 = cute.add_offset(%iter_183, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %634 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      %635 = builtin.unrealized_conversion_cast %iter_175 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %636 = llvm.getelementptr %635[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %637 = llvm.getelementptr %635[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %638 = llvm.getelementptr %635[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_549 = cute.crd2idx(%57, %lay_174) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_550 = cute.add_offset(%ptr_170, %idx_549) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_551 = cute.add_offset(%iter_175, %63) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<16>>
      %639 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_552 = cute.make_int_tuple() : () -> !cute.int_tuple<"34">
      %ptr_553 = cute.add_offset(%iter_175, %int_tuple_552) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %640 = builtin.unrealized_conversion_cast %ptr_553 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_554 = cute.make_int_tuple() : () -> !cute.int_tuple<"36">
      %ptr_555 = cute.add_offset(%iter_175, %int_tuple_554) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"36">) -> !cute.ptr<bf16, rmem, align<8>>
      %641 = builtin.unrealized_conversion_cast %ptr_555 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_556 = cute.make_int_tuple() : () -> !cute.int_tuple<"38">
      %ptr_557 = cute.add_offset(%iter_175, %int_tuple_556) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"38">) -> !cute.ptr<bf16, rmem, align<4>>
      %642 = builtin.unrealized_conversion_cast %ptr_557 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_558 = cute.crd2idx(%57, %lay_182) : (!cute.coord<"(_,_,2)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_559 = cute.add_offset(%ptr_178, %idx_558) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_560 = cute.add_offset(%iter_183, %56) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"128">) -> !cute.ptr<bf16, rmem, align<8>>
      %643 = builtin.unrealized_conversion_cast %ptr_539 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %644 = llvm.getelementptr %643[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %645 = llvm.getelementptr %643[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %646 = llvm.getelementptr %643[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_561 = cute.crd2idx(%55, %lay_174) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_562 = cute.add_offset(%ptr_170, %idx_561) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_563 = cute.add_offset(%iter_175, %54) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<16>>
      %647 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_564 = cute.make_int_tuple() : () -> !cute.int_tuple<"50">
      %ptr_565 = cute.add_offset(%iter_175, %int_tuple_564) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"50">) -> !cute.ptr<bf16, rmem, align<4>>
      %648 = builtin.unrealized_conversion_cast %ptr_565 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_566 = cute.make_int_tuple() : () -> !cute.int_tuple<"52">
      %ptr_567 = cute.add_offset(%iter_175, %int_tuple_566) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"52">) -> !cute.ptr<bf16, rmem, align<8>>
      %649 = builtin.unrealized_conversion_cast %ptr_567 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_568 = cute.make_int_tuple() : () -> !cute.int_tuple<"54">
      %ptr_569 = cute.add_offset(%iter_175, %int_tuple_568) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"54">) -> !cute.ptr<bf16, rmem, align<4>>
      %650 = builtin.unrealized_conversion_cast %ptr_569 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_570 = cute.crd2idx(%55, %lay_182) : (!cute.coord<"(_,_,3)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_571 = cute.add_offset(%ptr_178, %idx_570) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_572 = cute.add_offset(%iter_183, %53) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"192">) -> !cute.ptr<bf16, rmem, align<8>>
      %651 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %652 = llvm.getelementptr %651[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %653 = llvm.getelementptr %651[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %654 = llvm.getelementptr %651[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %ptr_573 = cute.add_offset(%ptr_170, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_574 = cute.add_offset(%iter_175, %76) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %655 = builtin.unrealized_conversion_cast %ptr_574 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_575 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_576 = cute.add_offset(%iter_175, %int_tuple_575) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"10">) -> !cute.ptr<bf16, rmem, align<4>>
      %656 = builtin.unrealized_conversion_cast %ptr_576 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_577 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_578 = cute.add_offset(%iter_175, %int_tuple_577) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"12">) -> !cute.ptr<bf16, rmem, align<8>>
      %657 = builtin.unrealized_conversion_cast %ptr_578 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_579 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
      %ptr_580 = cute.add_offset(%iter_175, %int_tuple_579) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"14">) -> !cute.ptr<bf16, rmem, align<4>>
      %658 = builtin.unrealized_conversion_cast %ptr_580 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %ptr_581 = cute.add_offset(%ptr_178, %52) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_582 = cute.add_offset(%iter_183, %60) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<8>>
      %659 = builtin.unrealized_conversion_cast %ptr_563 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %660 = llvm.getelementptr %659[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %661 = llvm.getelementptr %659[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %662 = llvm.getelementptr %659[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_583 = cute.crd2idx(%51, %lay_174) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_584 = cute.add_offset(%ptr_170, %idx_583) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_585 = cute.add_offset(%iter_175, %50) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %663 = builtin.unrealized_conversion_cast %ptr_585 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_586 = cute.make_int_tuple() : () -> !cute.int_tuple<"26">
      %ptr_587 = cute.add_offset(%iter_175, %int_tuple_586) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"26">) -> !cute.ptr<bf16, rmem, align<4>>
      %664 = builtin.unrealized_conversion_cast %ptr_587 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_588 = cute.make_int_tuple() : () -> !cute.int_tuple<"28">
      %ptr_589 = cute.add_offset(%iter_175, %int_tuple_588) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"28">) -> !cute.ptr<bf16, rmem, align<8>>
      %665 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"30">
      %ptr_591 = cute.add_offset(%iter_175, %int_tuple_590) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"30">) -> !cute.ptr<bf16, rmem, align<4>>
      %666 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_592 = cute.crd2idx(%51, %lay_182) : (!cute.coord<"(_,_,5)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_593 = cute.add_offset(%ptr_178, %idx_592) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_594 = cute.add_offset(%iter_183, %49) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"80">) -> !cute.ptr<bf16, rmem, align<8>>
      %667 = builtin.unrealized_conversion_cast %ptr_574 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %668 = llvm.getelementptr %667[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %669 = llvm.getelementptr %667[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %670 = llvm.getelementptr %667[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_595 = cute.crd2idx(%48, %lay_174) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_596 = cute.add_offset(%ptr_170, %idx_595) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_597 = cute.add_offset(%iter_175, %47) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %671 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"42">
      %ptr_599 = cute.add_offset(%iter_175, %int_tuple_598) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"42">) -> !cute.ptr<bf16, rmem, align<4>>
      %672 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"44">
      %ptr_601 = cute.add_offset(%iter_175, %int_tuple_600) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"44">) -> !cute.ptr<bf16, rmem, align<8>>
      %673 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"46">
      %ptr_603 = cute.add_offset(%iter_175, %int_tuple_602) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"46">) -> !cute.ptr<bf16, rmem, align<4>>
      %674 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_604 = cute.crd2idx(%48, %lay_182) : (!cute.coord<"(_,_,6)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_605 = cute.add_offset(%ptr_178, %idx_604) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_606 = cute.add_offset(%iter_183, %46) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"144">) -> !cute.ptr<bf16, rmem, align<8>>
      %675 = builtin.unrealized_conversion_cast %ptr_585 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %676 = llvm.getelementptr %675[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %677 = llvm.getelementptr %675[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %678 = llvm.getelementptr %675[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %idx_607 = cute.crd2idx(%45, %lay_174) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),1,((2,2),2)):((1,0),0,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_608 = cute.add_offset(%ptr_170, %idx_607) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_609 = cute.add_offset(%iter_175, %44) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %679 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"58">
      %ptr_611 = cute.add_offset(%iter_175, %int_tuple_610) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"58">) -> !cute.ptr<bf16, rmem, align<4>>
      %680 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"60">
      %ptr_613 = cute.add_offset(%iter_175, %int_tuple_612) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"60">) -> !cute.ptr<bf16, rmem, align<8>>
      %681 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"62">
      %ptr_615 = cute.add_offset(%iter_175, %int_tuple_614) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"62">) -> !cute.ptr<bf16, rmem, align<4>>
      %682 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %idx_616 = cute.crd2idx(%45, %lay_182) : (!cute.coord<"(_,_,7)">, !cute.layout<"((8,1),4,((2,2),2)):((1,0),1024,((?{div=16},?{div=32}),4096))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_617 = cute.add_offset(%ptr_178, %idx_616) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_618 = cute.add_offset(%iter_183, %43) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"208">) -> !cute.ptr<bf16, rmem, align<8>>
      %683 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %684 = llvm.getelementptr %683[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %685 = llvm.getelementptr %683[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %686 = llvm.getelementptr %683[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %687 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %688 = llvm.getelementptr %687[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %689 = llvm.getelementptr %687[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %690 = llvm.getelementptr %687[3] : (!llvm.ptr) -> !llvm.ptr, i32
      %691:2 = cute.get_scalars(%lay_188) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2),4):((1,0),((?{div=16},?{div=32}),4096),1024)">
      %iv_619 = cute.assume(%691#0) : (i32) -> !cute.i32<divby 16>
      %iv_620 = cute.assume(%691#1) : (i32) -> !cute.i32<divby 32>
      %stride_621 = cute.make_stride(%iv_619, %iv_620) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((?{div=16},?{div=32}),4096))">
      %lay_622 = cute.make_layout(%12, %stride_621) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %append_623 = cute.append_to_rank<2> (%lay_622, %117) : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">, !cute.layout<"1:0">
      %692:2 = cute.get_scalars(%append_623) <{only_dynamic}> : !cute.layout<"((8,1),((2,2),2)):((1,0),((?{div=16},?{div=32}),4096))">
      %iv_624 = cute.assume(%692#0) : (i32) -> !cute.i32<divby 16>
      %iv_625 = cute.assume(%692#1) : (i32) -> !cute.i32<divby 32>
      %stride_626 = cute.make_stride(%iv_624, %iv_625) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),(((?{div=16},?{div=32}),4096)))">
      %lay_627 = cute.make_layout(%11, %stride_626) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %append_628 = cute.append_to_rank<2> (%lay_627, %117) : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">, !cute.layout<"1:0">
      %693:2 = cute.get_scalars(%append_628) <{only_dynamic}> : !cute.layout<"((8,1),(((2,2),2))):((1,0),(((?{div=16},?{div=32}),4096)))">
      %iv_629 = cute.assume(%693#0) : (i32) -> !cute.i32<divby 16>
      %iv_630 = cute.assume(%693#1) : (i32) -> !cute.i32<divby 32>
      %stride_631 = cute.make_stride(%iv_629, %iv_630) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,0),((((?{div=16},?{div=32}),4096))))">
      %lay_632 = cute.make_layout(%10, %stride_631) : !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">
      %ptr_633 = cute.add_offset(%ptr_186, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_634 = cute.add_offset(%iter_189, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %iter_635 = cute.get_iter(%rmem_166) : !memref_rmem_f32_
      %694 = cute.get_scalars(%60) : !cute.int_tuple<"16">
      %ptr_636 = cute.add_offset(%ptr_186, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_637 = cute.add_offset(%iter_189, %59) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"64">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_638 = cute.add_offset(%ptr_186, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_639 = cute.add_offset(%iter_189, %7) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"96">) -> !cute.ptr<bf16, rmem, align<8>>
      cf.br ^bb73(%c-1_i32 : i32)
    ^bb73(%695: i32):  // 2 preds: ^bb72, ^bb304
      %696 = arith.cmpi slt, %695, %158 : i32
      cf.cond_br %696, ^bb74, ^bb305
    ^bb74:  // pred: ^bb73
      %int_tuple_640 = cute.make_int_tuple(%695) : (i32) -> !cute.int_tuple<"?">
      %sub_641 = cute.tuple_sub(%tup_520, %int_tuple_640) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %697 = cute.get_scalars(%sub_641) : !cute.int_tuple<"?">
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %698 = arith.cmpi eq, %697, %158 : i32
      cf.cond_br %698, ^bb75, ^bb100
    ^bb75:  // pred: ^bb74
      %699 = cute.get_shape(%lay_67) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_642, %e1_643, %e2_644, %e3_645 = cute.get_leaves(%699) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_646 = cute.to_int_tuple(%e1_643) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %coord_647 = cute.make_coord(%itup_646) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %700 = cute.get_scalars(%coord_647) : !cute.coord<"?">
      %701 = arith.cmpi slt, %534, %700 : i32
      cf.cond_br %701, ^bb76, ^bb80
    ^bb76:  // pred: ^bb75
      %coord_648 = cute.make_coord(%sub_641) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_649 = cute.crd2idx(%coord_648, %lay_154) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_650 = cute.add_offset(%ptr_149, %idx_649) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_651 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %702 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb77(%c0_i32 : i32)
    ^bb77(%703: i32):  // 2 preds: ^bb76, ^bb78
      %704 = arith.cmpi slt, %703, %702 : i32
      cf.cond_br %704, ^bb78, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb78:  // pred: ^bb77
      %coord_652 = cute.make_coord(%703) : (i32) -> !cute.coord<"(_,?)">
      %idx_653 = cute.crd2idx(%coord_652, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_654 = cute.add_offset(%ptr_650, %idx_653) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_655 = cute.crd2idx(%coord_652, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_656 = cute.add_offset(%ptr_155, %idx_655) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_657 = cute.crd2idx(%coord_652, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_658 = cute.add_offset(%iter_651, %idx_657) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %705 = builtin.unrealized_conversion_cast %ptr_658 : !cute.ptr<i8, rmem> to !llvm.ptr
      %706 = llvm.load %705 : !llvm.ptr -> i8
      %707 = llvm.trunc %706 : i8 to i1
      %iter_659 = cute.recast_iter(%ptr_654) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_660 = cute.recast_iter(%ptr_656) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_660 : !cute.ptr<i128, smem>, %iter_659 : !cute.ptr<i128, gmem>, %707 : i1) {cache_mode = <always>}
      %708 = arith.addi %703, %c1_i32 : i32
      cf.br ^bb77(%708 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb81
    ^bb80:  // pred: ^bb75
      %view_661 = cute.make_view(%ptr_155) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_661, row_major : !memref_smem_bf16_
      cf.br ^bb81
    ^bb81:  // 2 preds: ^bb79, ^bb80
      %709 = arith.cmpi slt, %544, %700 : i32
      cf.cond_br %709, ^bb82, ^bb86
    ^bb82:  // pred: ^bb81
      %coord_662 = cute.make_coord(%sub_641) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_663 = cute.crd2idx(%coord_662, %lay_154) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_664 = cute.add_offset(%ptr_149, %idx_663) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_665 = cute.add_offset(%ptr_155, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_666 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %710 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb83(%c0_i32 : i32)
    ^bb83(%711: i32):  // 2 preds: ^bb82, ^bb84
      %712 = arith.cmpi slt, %711, %710 : i32
      cf.cond_br %712, ^bb84, ^bb85 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      %coord_667 = cute.make_coord(%711) : (i32) -> !cute.coord<"(_,?)">
      %idx_668 = cute.crd2idx(%coord_667, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_669 = cute.add_offset(%ptr_664, %idx_668) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_670 = cute.crd2idx(%coord_667, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_671 = cute.add_offset(%ptr_665, %idx_670) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_672 = cute.crd2idx(%coord_667, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_673 = cute.add_offset(%iter_666, %idx_672) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %713 = builtin.unrealized_conversion_cast %ptr_673 : !cute.ptr<i8, rmem> to !llvm.ptr
      %714 = llvm.load %713 : !llvm.ptr -> i8
      %715 = llvm.trunc %714 : i8 to i1
      %iter_674 = cute.recast_iter(%ptr_669) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_675 = cute.recast_iter(%ptr_671) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_675 : !cute.ptr<i128, smem>, %iter_674 : !cute.ptr<i128, gmem>, %715 : i1) {cache_mode = <always>}
      %716 = arith.addi %711, %c1_i32 : i32
      cf.br ^bb83(%716 : i32)
    ^bb85:  // pred: ^bb83
      cf.br ^bb87
    ^bb86:  // pred: ^bb81
      %ptr_676 = cute.add_offset(%ptr_155, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_677 = cute.make_view(%ptr_676) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_677, row_major : !memref_smem_bf16_
      cf.br ^bb87
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %717 = arith.cmpi slt, %553, %700 : i32
      cf.cond_br %717, ^bb88, ^bb92
    ^bb88:  // pred: ^bb87
      %coord_678 = cute.make_coord(%sub_641) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_679 = cute.crd2idx(%coord_678, %lay_154) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_680 = cute.add_offset(%ptr_149, %idx_679) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_681 = cute.add_offset(%ptr_155, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_682 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %718 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%719: i32):  // 2 preds: ^bb88, ^bb90
      %720 = arith.cmpi slt, %719, %718 : i32
      cf.cond_br %720, ^bb90, ^bb91 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      %coord_683 = cute.make_coord(%719) : (i32) -> !cute.coord<"(_,?)">
      %idx_684 = cute.crd2idx(%coord_683, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_685 = cute.add_offset(%ptr_680, %idx_684) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_686 = cute.crd2idx(%coord_683, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_687 = cute.add_offset(%ptr_681, %idx_686) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_688 = cute.crd2idx(%coord_683, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_689 = cute.add_offset(%iter_682, %idx_688) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %721 = builtin.unrealized_conversion_cast %ptr_689 : !cute.ptr<i8, rmem> to !llvm.ptr
      %722 = llvm.load %721 : !llvm.ptr -> i8
      %723 = llvm.trunc %722 : i8 to i1
      %iter_690 = cute.recast_iter(%ptr_685) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_691 = cute.recast_iter(%ptr_687) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_691 : !cute.ptr<i128, smem>, %iter_690 : !cute.ptr<i128, gmem>, %723 : i1) {cache_mode = <always>}
      %724 = arith.addi %719, %c1_i32 : i32
      cf.br ^bb89(%724 : i32)
    ^bb91:  // pred: ^bb89
      cf.br ^bb93
    ^bb92:  // pred: ^bb87
      %ptr_692 = cute.add_offset(%ptr_155, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_693 = cute.make_view(%ptr_692) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_693, row_major : !memref_smem_bf16_
      cf.br ^bb93
    ^bb93:  // 2 preds: ^bb91, ^bb92
      %725 = arith.cmpi slt, %562, %700 : i32
      cf.cond_br %725, ^bb94, ^bb98
    ^bb94:  // pred: ^bb93
      %coord_694 = cute.make_coord(%sub_641) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_695 = cute.crd2idx(%coord_694, %lay_154) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_696 = cute.add_offset(%ptr_149, %idx_695) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_697 = cute.add_offset(%ptr_155, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_698 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %726 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb95(%c0_i32 : i32)
    ^bb95(%727: i32):  // 2 preds: ^bb94, ^bb96
      %728 = arith.cmpi slt, %727, %726 : i32
      cf.cond_br %728, ^bb96, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb96:  // pred: ^bb95
      %coord_699 = cute.make_coord(%727) : (i32) -> !cute.coord<"(_,?)">
      %idx_700 = cute.crd2idx(%coord_699, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_701 = cute.add_offset(%ptr_696, %idx_700) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_702 = cute.crd2idx(%coord_699, %93) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_703 = cute.add_offset(%ptr_697, %idx_702) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_704 = cute.crd2idx(%coord_699, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_705 = cute.add_offset(%iter_698, %idx_704) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %729 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<i8, rmem> to !llvm.ptr
      %730 = llvm.load %729 : !llvm.ptr -> i8
      %731 = llvm.trunc %730 : i8 to i1
      %iter_706 = cute.recast_iter(%ptr_701) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_707 = cute.recast_iter(%ptr_703) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_707 : !cute.ptr<i128, smem>, %iter_706 : !cute.ptr<i128, gmem>, %731 : i1) {cache_mode = <always>}
      %732 = arith.addi %727, %c1_i32 : i32
      cf.br ^bb95(%732 : i32)
    ^bb97:  // pred: ^bb95
      cf.br ^bb99
    ^bb98:  // pred: ^bb93
      %ptr_708 = cute.add_offset(%ptr_155, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_709 = cute.make_view(%ptr_708) : !memref_smem_bf16_
      cute.memref.store_vec %cst_1, %view_709, row_major : !memref_smem_bf16_
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb104
    ^bb100:  // pred: ^bb74
      %coord_710 = cute.make_coord(%sub_641) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
      %733:3 = cute.get_scalars(%lay_154) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_711 = cute.assume(%733#1) : (i64) -> !cute.i64<divby 128>
      %stride_712 = cute.make_stride(%iv_711) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_713 = cute.make_layout(%111, %stride_712) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_714 = cute.crd2idx(%coord_710, %lay_154) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_715 = cute.add_offset(%ptr_149, %idx_714) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_716 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %append_717 = cute.append_to_rank<2> (%lay_713, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %734 = cute.get_scalars(%append_717) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_718 = cute.assume(%734) : (i64) -> !cute.i64<divby 128>
      %stride_719 = cute.make_stride(%iv_718) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_720 = cute.make_layout(%80, %stride_719) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_721 = cute.append_to_rank<2> (%lay_720, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %735 = cute.get_scalars(%append_721) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_722 = cute.assume(%735) : (i64) -> !cute.i64<divby 128>
      %stride_723 = cute.make_stride(%iv_722) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_724 = cute.make_layout(%79, %stride_723) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      %736 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      cf.br ^bb101(%c0_i32 : i32)
    ^bb101(%737: i32):  // 2 preds: ^bb100, ^bb102
      %738 = arith.cmpi slt, %737, %736 : i32
      cf.cond_br %738, ^bb102, ^bb103 {llvm.loop_annotation = #loop_annotation}
    ^bb102:  // pred: ^bb101
      %coord_725 = cute.make_coord(%737) : (i32) -> !cute.coord<"(_,?)">
      %idx_726 = cute.crd2idx(%coord_725, %lay_724) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_727 = cute.add_offset(%ptr_715, %idx_726) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_728 = cute.crd2idx(%coord_725, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_729 = cute.add_offset(%ptr_155, %idx_728) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_730 = cute.crd2idx(%coord_725, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_731 = cute.add_offset(%iter_716, %idx_730) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %739 = builtin.unrealized_conversion_cast %ptr_731 : !cute.ptr<i8, rmem> to !llvm.ptr
      %740 = llvm.load %739 : !llvm.ptr -> i8
      %741 = llvm.trunc %740 : i8 to i1
      %iter_732 = cute.recast_iter(%ptr_727) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_733 = cute.recast_iter(%ptr_729) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_733 : !cute.ptr<i128, smem>, %iter_732 : !cute.ptr<i128, gmem>, %741 : i1) {cache_mode = <always>}
      %742 = arith.addi %737, %c1_i32 : i32
      cf.br ^bb101(%742 : i32)
    ^bb103:  // pred: ^bb101
      cf.br ^bb104
    ^bb104:  // 2 preds: ^bb99, ^bb103
      nvvm.cp.async.commit.group
      %rmem_734 = cute.memref.alloca() : !memref_rmem_f32_1
      %rmem_735 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_736 = cute.get_iter(%rmem_735) : !memref_rmem_bf16_3
      cf.br ^bb105(%c0_i32 : i32)
    ^bb105(%743: i32):  // 2 preds: ^bb104, ^bb106
      %744 = arith.cmpi slt, %743, %624 : i32
      cf.cond_br %744, ^bb106, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb106:  // pred: ^bb105
      %coord_737 = cute.make_coord(%743) : (i32) -> !cute.coord<"(_,?)">
      %idx_738 = cute.crd2idx(%coord_737, %lay_533) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,(2,2)))):((1,0),((0,(?{div=16},?{div=32}))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_739 = cute.add_offset(%ptr_190, %idx_738) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_740 = cute.crd2idx(%coord_737, %72) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((1,4))):((1,0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_741 = cute.add_offset(%iter_736, %idx_740) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %745 = cute_nvgpu.arch.copy.ldsm %ptr_739{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %746 = vector.extractelement %745[%70 : i32] : vector<4xi32>
      %747 = builtin.unrealized_conversion_cast %ptr_741 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      llvm.store %746, %747 : i32, !llvm.ptr
      %748 = vector.extractelement %745[%69 : i32] : vector<4xi32>
      %ptr_742 = cute.add_offset(%ptr_741, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %749 = builtin.unrealized_conversion_cast %ptr_742 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %748, %749 : i32, !llvm.ptr
      %750 = vector.extractelement %745[%68 : i32] : vector<4xi32>
      %ptr_743 = cute.add_offset(%ptr_741, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %751 = builtin.unrealized_conversion_cast %ptr_743 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %750, %751 : i32, !llvm.ptr
      %752 = vector.extractelement %745[%67 : i32] : vector<4xi32>
      %ptr_744 = cute.add_offset(%ptr_741, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %753 = builtin.unrealized_conversion_cast %ptr_744 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %752, %753 : i32, !llvm.ptr
      %754 = arith.addi %743, %c1_i32 : i32
      cf.br ^bb105(%754 : i32)
    ^bb107:  // pred: ^bb105
      %755 = cute.memref.load_vec %rmem_735, row_major : !memref_rmem_bf16_3
      %756 = arith.extf %755 : vector<32xbf16> to vector<32xf32>
      cute.memref.store_vec %756, %rmem_734, row_major : !memref_rmem_f32_1
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%757: i32):  // 2 preds: ^bb107, ^bb109
      %758 = arith.cmpi slt, %757, %625 : i32
      cf.cond_br %758, ^bb109, ^bb110 {llvm.loop_annotation = #loop_annotation}
    ^bb109:  // pred: ^bb108
      %759 = cute_nvgpu.arch.copy.ldsm %ptr_170{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %760 = vector.extractelement %759[%70 : i32] : vector<4xi32>
      llvm.store %760, %626 : i32, !llvm.ptr
      %761 = vector.extractelement %759[%69 : i32] : vector<4xi32>
      llvm.store %761, %627 : i32, !llvm.ptr
      %762 = vector.extractelement %759[%68 : i32] : vector<4xi32>
      llvm.store %762, %628 : i32, !llvm.ptr
      %763 = vector.extractelement %759[%67 : i32] : vector<4xi32>
      llvm.store %763, %629 : i32, !llvm.ptr
      %764 = arith.addi %757, %c1_i32 : i32
      cf.br ^bb108(%764 : i32)
    ^bb110:  // pred: ^bb108
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%765: i32):  // 2 preds: ^bb110, ^bb112
      %766 = arith.cmpi slt, %765, %624 : i32
      cf.cond_br %766, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_745 = cute.make_coord(%765) : (i32) -> !cute.coord<"(_,?)">
      %idx_746 = cute.crd2idx(%coord_745, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_747 = cute.add_offset(%ptr_178, %idx_746) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_748 = cute.crd2idx(%coord_745, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_749 = cute.add_offset(%iter_183, %idx_748) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %767 = cute_nvgpu.arch.copy.ldsm %ptr_747{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %768 = vector.extractelement %767[%70 : i32] : vector<4xi32>
      %769 = builtin.unrealized_conversion_cast %ptr_749 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %768, %769 : i32, !llvm.ptr
      %770 = vector.extractelement %767[%69 : i32] : vector<4xi32>
      %ptr_750 = cute.add_offset(%ptr_749, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %771 = builtin.unrealized_conversion_cast %ptr_750 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %770, %771 : i32, !llvm.ptr
      %772 = vector.extractelement %767[%68 : i32] : vector<4xi32>
      %ptr_751 = cute.add_offset(%ptr_749, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %773 = builtin.unrealized_conversion_cast %ptr_751 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %772, %773 : i32, !llvm.ptr
      %774 = vector.extractelement %767[%67 : i32] : vector<4xi32>
      %ptr_752 = cute.add_offset(%ptr_749, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %775 = builtin.unrealized_conversion_cast %ptr_752 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %774, %775 : i32, !llvm.ptr
      %776 = arith.addi %765, %c1_i32 : i32
      cf.br ^bb111(%776 : i32)
    ^bb113:  // pred: ^bb111
      cf.br ^bb114(%c0_i32 : i32)
    ^bb114(%777: i32):  // 2 preds: ^bb113, ^bb115
      %778 = arith.cmpi slt, %777, %625 : i32
      cf.cond_br %778, ^bb115, ^bb116 {llvm.loop_annotation = #loop_annotation}
    ^bb115:  // pred: ^bb114
      %779 = cute_nvgpu.arch.copy.ldsm %ptr_538{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %780 = vector.extractelement %779[%70 : i32] : vector<4xi32>
      llvm.store %780, %630 : i32, !llvm.ptr
      %781 = vector.extractelement %779[%69 : i32] : vector<4xi32>
      llvm.store %781, %631 : i32, !llvm.ptr
      %782 = vector.extractelement %779[%68 : i32] : vector<4xi32>
      llvm.store %782, %632 : i32, !llvm.ptr
      %783 = vector.extractelement %779[%67 : i32] : vector<4xi32>
      llvm.store %783, %633 : i32, !llvm.ptr
      %784 = arith.addi %777, %c1_i32 : i32
      cf.br ^bb114(%784 : i32)
    ^bb116:  // pred: ^bb114
      cf.br ^bb117(%c0_i32 : i32)
    ^bb117(%785: i32):  // 2 preds: ^bb116, ^bb118
      %786 = arith.cmpi slt, %785, %624 : i32
      cf.cond_br %786, ^bb118, ^bb119 {llvm.loop_annotation = #loop_annotation}
    ^bb118:  // pred: ^bb117
      %coord_753 = cute.make_coord(%785) : (i32) -> !cute.coord<"(_,?)">
      %idx_754 = cute.crd2idx(%coord_753, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_755 = cute.add_offset(%ptr_547, %idx_754) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_756 = cute.crd2idx(%coord_753, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_757 = cute.add_offset(%ptr_548, %idx_756) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %787 = cute_nvgpu.arch.copy.ldsm %ptr_755{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %788 = vector.extractelement %787[%70 : i32] : vector<4xi32>
      %789 = builtin.unrealized_conversion_cast %ptr_757 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %788, %789 : i32, !llvm.ptr
      %790 = vector.extractelement %787[%69 : i32] : vector<4xi32>
      %ptr_758 = cute.add_offset(%ptr_757, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %791 = builtin.unrealized_conversion_cast %ptr_758 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %790, %791 : i32, !llvm.ptr
      %792 = vector.extractelement %787[%68 : i32] : vector<4xi32>
      %ptr_759 = cute.add_offset(%ptr_757, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %793 = builtin.unrealized_conversion_cast %ptr_759 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %792, %793 : i32, !llvm.ptr
      %794 = vector.extractelement %787[%67 : i32] : vector<4xi32>
      %ptr_760 = cute.add_offset(%ptr_757, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %795 = builtin.unrealized_conversion_cast %ptr_760 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %794, %795 : i32, !llvm.ptr
      %796 = arith.addi %785, %c1_i32 : i32
      cf.br ^bb117(%796 : i32)
    ^bb119:  // pred: ^bb117
      %iter_761 = cute.get_iter(%rmem_734) : !memref_rmem_f32_1
      cf.br ^bb120(%c0_i32 : i32)
    ^bb120(%797: i32):  // 2 preds: ^bb119, ^bb127
      %798 = arith.cmpi slt, %797, %625 : i32
      cf.cond_br %798, ^bb121, ^bb128 {llvm.loop_annotation = #loop_annotation}
    ^bb121:  // pred: ^bb120
      cf.br ^bb122(%c0_i32 : i32)
    ^bb122(%799: i32):  // 2 preds: ^bb121, ^bb126
      %800 = arith.cmpi slt, %799, %625 : i32
      cf.cond_br %800, ^bb123, ^bb127 {llvm.loop_annotation = #loop_annotation}
    ^bb123:  // pred: ^bb122
      cf.br ^bb124(%c0_i32 : i32)
    ^bb124(%801: i32):  // 2 preds: ^bb123, ^bb125
      %802 = arith.cmpi slt, %801, %634 : i32
      cf.cond_br %802, ^bb125, ^bb126 {llvm.loop_annotation = #loop_annotation}
    ^bb125:  // pred: ^bb124
      %coord_762 = cute.make_coord(%801, %797) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_763 = cute.make_coord(%799, %801) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_764 = cute.crd2idx(%coord_762, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_765 = cute.add_offset(%iter_183, %idx_764) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_766 = cute.crd2idx(%coord_763, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_767 = cute.add_offset(%iter_761, %idx_766) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %803 = llvm.load %635 : !llvm.ptr -> i32
      %804 = llvm.load %636 : !llvm.ptr -> i32
      %805 = llvm.load %637 : !llvm.ptr -> i32
      %806 = llvm.load %638 : !llvm.ptr -> i32
      %807 = builtin.unrealized_conversion_cast %ptr_765 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %808 = llvm.load %807 : !llvm.ptr -> i32
      %809 = llvm.getelementptr %807[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %810 = llvm.load %809 : !llvm.ptr -> i32
      %811 = builtin.unrealized_conversion_cast %ptr_767 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %812 = llvm.load %811 : !llvm.ptr -> f32
      %813 = llvm.getelementptr %811[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %814 = llvm.load %813 : !llvm.ptr -> f32
      %815 = llvm.getelementptr %811[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %816 = llvm.load %815 : !llvm.ptr -> f32
      %817 = llvm.getelementptr %811[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %818 = llvm.load %817 : !llvm.ptr -> f32
      %819:4 = cute_nvgpu.arch.mma.SM80 A[%803, %804, %805, %806]  B[%808, %810]  C[%812, %814, %816, %818] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %819#0, %811 : f32, !llvm.ptr
      llvm.store %819#1, %813 : f32, !llvm.ptr
      llvm.store %819#2, %815 : f32, !llvm.ptr
      llvm.store %819#3, %817 : f32, !llvm.ptr
      %820 = arith.addi %801, %c1_i32 : i32
      cf.br ^bb124(%820 : i32)
    ^bb126:  // pred: ^bb124
      %821 = arith.addi %799, %c1_i32 : i32
      cf.br ^bb122(%821 : i32)
    ^bb127:  // pred: ^bb122
      %822 = arith.addi %797, %c1_i32 : i32
      cf.br ^bb120(%822 : i32)
    ^bb128:  // pred: ^bb120
      cf.br ^bb129(%c0_i32 : i32)
    ^bb129(%823: i32):  // 2 preds: ^bb128, ^bb130
      %824 = arith.cmpi slt, %823, %625 : i32
      cf.cond_br %824, ^bb130, ^bb131 {llvm.loop_annotation = #loop_annotation}
    ^bb130:  // pred: ^bb129
      %825 = cute_nvgpu.arch.copy.ldsm %ptr_550{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %826 = vector.extractelement %825[%70 : i32] : vector<4xi32>
      llvm.store %826, %639 : i32, !llvm.ptr
      %827 = vector.extractelement %825[%69 : i32] : vector<4xi32>
      llvm.store %827, %640 : i32, !llvm.ptr
      %828 = vector.extractelement %825[%68 : i32] : vector<4xi32>
      llvm.store %828, %641 : i32, !llvm.ptr
      %829 = vector.extractelement %825[%67 : i32] : vector<4xi32>
      llvm.store %829, %642 : i32, !llvm.ptr
      %830 = arith.addi %823, %c1_i32 : i32
      cf.br ^bb129(%830 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%c0_i32 : i32)
    ^bb132(%831: i32):  // 2 preds: ^bb131, ^bb133
      %832 = arith.cmpi slt, %831, %624 : i32
      cf.cond_br %832, ^bb133, ^bb134 {llvm.loop_annotation = #loop_annotation}
    ^bb133:  // pred: ^bb132
      %coord_768 = cute.make_coord(%831) : (i32) -> !cute.coord<"(_,?)">
      %idx_769 = cute.crd2idx(%coord_768, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_770 = cute.add_offset(%ptr_559, %idx_769) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_771 = cute.crd2idx(%coord_768, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_772 = cute.add_offset(%ptr_560, %idx_771) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %833 = cute_nvgpu.arch.copy.ldsm %ptr_770{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %834 = vector.extractelement %833[%70 : i32] : vector<4xi32>
      %835 = builtin.unrealized_conversion_cast %ptr_772 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %834, %835 : i32, !llvm.ptr
      %836 = vector.extractelement %833[%69 : i32] : vector<4xi32>
      %ptr_773 = cute.add_offset(%ptr_772, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %837 = builtin.unrealized_conversion_cast %ptr_773 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %836, %837 : i32, !llvm.ptr
      %838 = vector.extractelement %833[%68 : i32] : vector<4xi32>
      %ptr_774 = cute.add_offset(%ptr_772, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %839 = builtin.unrealized_conversion_cast %ptr_774 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %838, %839 : i32, !llvm.ptr
      %840 = vector.extractelement %833[%67 : i32] : vector<4xi32>
      %ptr_775 = cute.add_offset(%ptr_772, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %841 = builtin.unrealized_conversion_cast %ptr_775 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %840, %841 : i32, !llvm.ptr
      %842 = arith.addi %831, %c1_i32 : i32
      cf.br ^bb132(%842 : i32)
    ^bb134:  // pred: ^bb132
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%843: i32):  // 2 preds: ^bb134, ^bb142
      %844 = arith.cmpi slt, %843, %625 : i32
      cf.cond_br %844, ^bb136, ^bb143 {llvm.loop_annotation = #loop_annotation}
    ^bb136:  // pred: ^bb135
      cf.br ^bb137(%c0_i32 : i32)
    ^bb137(%845: i32):  // 2 preds: ^bb136, ^bb141
      %846 = arith.cmpi slt, %845, %625 : i32
      cf.cond_br %846, ^bb138, ^bb142 {llvm.loop_annotation = #loop_annotation}
    ^bb138:  // pred: ^bb137
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%847: i32):  // 2 preds: ^bb138, ^bb140
      %848 = arith.cmpi slt, %847, %634 : i32
      cf.cond_br %848, ^bb140, ^bb141 {llvm.loop_annotation = #loop_annotation}
    ^bb140:  // pred: ^bb139
      %coord_776 = cute.make_coord(%847, %843) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_777 = cute.make_coord(%845, %847) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_778 = cute.crd2idx(%coord_776, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_779 = cute.add_offset(%ptr_548, %idx_778) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_780 = cute.crd2idx(%coord_777, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_781 = cute.add_offset(%iter_761, %idx_780) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %849 = llvm.load %643 : !llvm.ptr -> i32
      %850 = llvm.load %644 : !llvm.ptr -> i32
      %851 = llvm.load %645 : !llvm.ptr -> i32
      %852 = llvm.load %646 : !llvm.ptr -> i32
      %853 = builtin.unrealized_conversion_cast %ptr_779 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %854 = llvm.load %853 : !llvm.ptr -> i32
      %855 = llvm.getelementptr %853[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %856 = llvm.load %855 : !llvm.ptr -> i32
      %857 = builtin.unrealized_conversion_cast %ptr_781 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %858 = llvm.load %857 : !llvm.ptr -> f32
      %859 = llvm.getelementptr %857[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %860 = llvm.load %859 : !llvm.ptr -> f32
      %861 = llvm.getelementptr %857[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %862 = llvm.load %861 : !llvm.ptr -> f32
      %863 = llvm.getelementptr %857[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %864 = llvm.load %863 : !llvm.ptr -> f32
      %865:4 = cute_nvgpu.arch.mma.SM80 A[%849, %850, %851, %852]  B[%854, %856]  C[%858, %860, %862, %864] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %865#0, %857 : f32, !llvm.ptr
      llvm.store %865#1, %859 : f32, !llvm.ptr
      llvm.store %865#2, %861 : f32, !llvm.ptr
      llvm.store %865#3, %863 : f32, !llvm.ptr
      %866 = arith.addi %847, %c1_i32 : i32
      cf.br ^bb139(%866 : i32)
    ^bb141:  // pred: ^bb139
      %867 = arith.addi %845, %c1_i32 : i32
      cf.br ^bb137(%867 : i32)
    ^bb142:  // pred: ^bb137
      %868 = arith.addi %843, %c1_i32 : i32
      cf.br ^bb135(%868 : i32)
    ^bb143:  // pred: ^bb135
      cf.br ^bb144(%c0_i32 : i32)
    ^bb144(%869: i32):  // 2 preds: ^bb143, ^bb145
      %870 = arith.cmpi slt, %869, %625 : i32
      cf.cond_br %870, ^bb145, ^bb146 {llvm.loop_annotation = #loop_annotation}
    ^bb145:  // pred: ^bb144
      %871 = cute_nvgpu.arch.copy.ldsm %ptr_562{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %872 = vector.extractelement %871[%70 : i32] : vector<4xi32>
      llvm.store %872, %647 : i32, !llvm.ptr
      %873 = vector.extractelement %871[%69 : i32] : vector<4xi32>
      llvm.store %873, %648 : i32, !llvm.ptr
      %874 = vector.extractelement %871[%68 : i32] : vector<4xi32>
      llvm.store %874, %649 : i32, !llvm.ptr
      %875 = vector.extractelement %871[%67 : i32] : vector<4xi32>
      llvm.store %875, %650 : i32, !llvm.ptr
      %876 = arith.addi %869, %c1_i32 : i32
      cf.br ^bb144(%876 : i32)
    ^bb146:  // pred: ^bb144
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%877: i32):  // 2 preds: ^bb146, ^bb148
      %878 = arith.cmpi slt, %877, %624 : i32
      cf.cond_br %878, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation}
    ^bb148:  // pred: ^bb147
      %coord_782 = cute.make_coord(%877) : (i32) -> !cute.coord<"(_,?)">
      %idx_783 = cute.crd2idx(%coord_782, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_784 = cute.add_offset(%ptr_571, %idx_783) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_785 = cute.crd2idx(%coord_782, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_786 = cute.add_offset(%ptr_572, %idx_785) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %879 = cute_nvgpu.arch.copy.ldsm %ptr_784{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %880 = vector.extractelement %879[%70 : i32] : vector<4xi32>
      %881 = builtin.unrealized_conversion_cast %ptr_786 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %880, %881 : i32, !llvm.ptr
      %882 = vector.extractelement %879[%69 : i32] : vector<4xi32>
      %ptr_787 = cute.add_offset(%ptr_786, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %883 = builtin.unrealized_conversion_cast %ptr_787 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %882, %883 : i32, !llvm.ptr
      %884 = vector.extractelement %879[%68 : i32] : vector<4xi32>
      %ptr_788 = cute.add_offset(%ptr_786, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %885 = builtin.unrealized_conversion_cast %ptr_788 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %884, %885 : i32, !llvm.ptr
      %886 = vector.extractelement %879[%67 : i32] : vector<4xi32>
      %ptr_789 = cute.add_offset(%ptr_786, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %887 = builtin.unrealized_conversion_cast %ptr_789 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %886, %887 : i32, !llvm.ptr
      %888 = arith.addi %877, %c1_i32 : i32
      cf.br ^bb147(%888 : i32)
    ^bb149:  // pred: ^bb147
      cf.br ^bb150(%c0_i32 : i32)
    ^bb150(%889: i32):  // 2 preds: ^bb149, ^bb157
      %890 = arith.cmpi slt, %889, %625 : i32
      cf.cond_br %890, ^bb151, ^bb158 {llvm.loop_annotation = #loop_annotation}
    ^bb151:  // pred: ^bb150
      cf.br ^bb152(%c0_i32 : i32)
    ^bb152(%891: i32):  // 2 preds: ^bb151, ^bb156
      %892 = arith.cmpi slt, %891, %625 : i32
      cf.cond_br %892, ^bb153, ^bb157 {llvm.loop_annotation = #loop_annotation}
    ^bb153:  // pred: ^bb152
      cf.br ^bb154(%c0_i32 : i32)
    ^bb154(%893: i32):  // 2 preds: ^bb153, ^bb155
      %894 = arith.cmpi slt, %893, %634 : i32
      cf.cond_br %894, ^bb155, ^bb156 {llvm.loop_annotation = #loop_annotation}
    ^bb155:  // pred: ^bb154
      %coord_790 = cute.make_coord(%893, %889) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_791 = cute.make_coord(%891, %893) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_792 = cute.crd2idx(%coord_790, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_793 = cute.add_offset(%ptr_560, %idx_792) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_794 = cute.crd2idx(%coord_791, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_795 = cute.add_offset(%iter_761, %idx_794) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %895 = llvm.load %651 : !llvm.ptr -> i32
      %896 = llvm.load %652 : !llvm.ptr -> i32
      %897 = llvm.load %653 : !llvm.ptr -> i32
      %898 = llvm.load %654 : !llvm.ptr -> i32
      %899 = builtin.unrealized_conversion_cast %ptr_793 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %900 = llvm.load %899 : !llvm.ptr -> i32
      %901 = llvm.getelementptr %899[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %902 = llvm.load %901 : !llvm.ptr -> i32
      %903 = builtin.unrealized_conversion_cast %ptr_795 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %904 = llvm.load %903 : !llvm.ptr -> f32
      %905 = llvm.getelementptr %903[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %906 = llvm.load %905 : !llvm.ptr -> f32
      %907 = llvm.getelementptr %903[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %908 = llvm.load %907 : !llvm.ptr -> f32
      %909 = llvm.getelementptr %903[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %910 = llvm.load %909 : !llvm.ptr -> f32
      %911:4 = cute_nvgpu.arch.mma.SM80 A[%895, %896, %897, %898]  B[%900, %902]  C[%904, %906, %908, %910] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %911#0, %903 : f32, !llvm.ptr
      llvm.store %911#1, %905 : f32, !llvm.ptr
      llvm.store %911#2, %907 : f32, !llvm.ptr
      llvm.store %911#3, %909 : f32, !llvm.ptr
      %912 = arith.addi %893, %c1_i32 : i32
      cf.br ^bb154(%912 : i32)
    ^bb156:  // pred: ^bb154
      %913 = arith.addi %891, %c1_i32 : i32
      cf.br ^bb152(%913 : i32)
    ^bb157:  // pred: ^bb152
      %914 = arith.addi %889, %c1_i32 : i32
      cf.br ^bb150(%914 : i32)
    ^bb158:  // pred: ^bb150
      cf.br ^bb159(%c0_i32 : i32)
    ^bb159(%915: i32):  // 2 preds: ^bb158, ^bb160
      %916 = arith.cmpi slt, %915, %625 : i32
      cf.cond_br %916, ^bb160, ^bb161 {llvm.loop_annotation = #loop_annotation}
    ^bb160:  // pred: ^bb159
      %917 = cute_nvgpu.arch.copy.ldsm %ptr_573{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %918 = vector.extractelement %917[%70 : i32] : vector<4xi32>
      llvm.store %918, %655 : i32, !llvm.ptr
      %919 = vector.extractelement %917[%69 : i32] : vector<4xi32>
      llvm.store %919, %656 : i32, !llvm.ptr
      %920 = vector.extractelement %917[%68 : i32] : vector<4xi32>
      llvm.store %920, %657 : i32, !llvm.ptr
      %921 = vector.extractelement %917[%67 : i32] : vector<4xi32>
      llvm.store %921, %658 : i32, !llvm.ptr
      %922 = arith.addi %915, %c1_i32 : i32
      cf.br ^bb159(%922 : i32)
    ^bb161:  // pred: ^bb159
      cf.br ^bb162(%c0_i32 : i32)
    ^bb162(%923: i32):  // 2 preds: ^bb161, ^bb163
      %924 = arith.cmpi slt, %923, %624 : i32
      cf.cond_br %924, ^bb163, ^bb164 {llvm.loop_annotation = #loop_annotation}
    ^bb163:  // pred: ^bb162
      %coord_796 = cute.make_coord(%923) : (i32) -> !cute.coord<"(_,?)">
      %idx_797 = cute.crd2idx(%coord_796, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_798 = cute.add_offset(%ptr_581, %idx_797) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_799 = cute.crd2idx(%coord_796, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_800 = cute.add_offset(%ptr_582, %idx_799) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %925 = cute_nvgpu.arch.copy.ldsm %ptr_798{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %926 = vector.extractelement %925[%70 : i32] : vector<4xi32>
      %927 = builtin.unrealized_conversion_cast %ptr_800 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %926, %927 : i32, !llvm.ptr
      %928 = vector.extractelement %925[%69 : i32] : vector<4xi32>
      %ptr_801 = cute.add_offset(%ptr_800, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %929 = builtin.unrealized_conversion_cast %ptr_801 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %928, %929 : i32, !llvm.ptr
      %930 = vector.extractelement %925[%68 : i32] : vector<4xi32>
      %ptr_802 = cute.add_offset(%ptr_800, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %931 = builtin.unrealized_conversion_cast %ptr_802 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %930, %931 : i32, !llvm.ptr
      %932 = vector.extractelement %925[%67 : i32] : vector<4xi32>
      %ptr_803 = cute.add_offset(%ptr_800, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %933 = builtin.unrealized_conversion_cast %ptr_803 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %932, %933 : i32, !llvm.ptr
      %934 = arith.addi %923, %c1_i32 : i32
      cf.br ^bb162(%934 : i32)
    ^bb164:  // pred: ^bb162
      cf.br ^bb165(%c0_i32 : i32)
    ^bb165(%935: i32):  // 2 preds: ^bb164, ^bb172
      %936 = arith.cmpi slt, %935, %625 : i32
      cf.cond_br %936, ^bb166, ^bb173 {llvm.loop_annotation = #loop_annotation}
    ^bb166:  // pred: ^bb165
      cf.br ^bb167(%c0_i32 : i32)
    ^bb167(%937: i32):  // 2 preds: ^bb166, ^bb171
      %938 = arith.cmpi slt, %937, %625 : i32
      cf.cond_br %938, ^bb168, ^bb172 {llvm.loop_annotation = #loop_annotation}
    ^bb168:  // pred: ^bb167
      cf.br ^bb169(%c0_i32 : i32)
    ^bb169(%939: i32):  // 2 preds: ^bb168, ^bb170
      %940 = arith.cmpi slt, %939, %634 : i32
      cf.cond_br %940, ^bb170, ^bb171 {llvm.loop_annotation = #loop_annotation}
    ^bb170:  // pred: ^bb169
      %coord_804 = cute.make_coord(%939, %935) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_805 = cute.make_coord(%937, %939) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_806 = cute.crd2idx(%coord_804, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_807 = cute.add_offset(%ptr_572, %idx_806) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_808 = cute.crd2idx(%coord_805, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_809 = cute.add_offset(%iter_761, %idx_808) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %941 = llvm.load %659 : !llvm.ptr -> i32
      %942 = llvm.load %660 : !llvm.ptr -> i32
      %943 = llvm.load %661 : !llvm.ptr -> i32
      %944 = llvm.load %662 : !llvm.ptr -> i32
      %945 = builtin.unrealized_conversion_cast %ptr_807 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %946 = llvm.load %945 : !llvm.ptr -> i32
      %947 = llvm.getelementptr %945[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %948 = llvm.load %947 : !llvm.ptr -> i32
      %949 = builtin.unrealized_conversion_cast %ptr_809 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %950 = llvm.load %949 : !llvm.ptr -> f32
      %951 = llvm.getelementptr %949[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %952 = llvm.load %951 : !llvm.ptr -> f32
      %953 = llvm.getelementptr %949[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %954 = llvm.load %953 : !llvm.ptr -> f32
      %955 = llvm.getelementptr %949[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %956 = llvm.load %955 : !llvm.ptr -> f32
      %957:4 = cute_nvgpu.arch.mma.SM80 A[%941, %942, %943, %944]  B[%946, %948]  C[%950, %952, %954, %956] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %957#0, %949 : f32, !llvm.ptr
      llvm.store %957#1, %951 : f32, !llvm.ptr
      llvm.store %957#2, %953 : f32, !llvm.ptr
      llvm.store %957#3, %955 : f32, !llvm.ptr
      %958 = arith.addi %939, %c1_i32 : i32
      cf.br ^bb169(%958 : i32)
    ^bb171:  // pred: ^bb169
      %959 = arith.addi %937, %c1_i32 : i32
      cf.br ^bb167(%959 : i32)
    ^bb172:  // pred: ^bb167
      %960 = arith.addi %935, %c1_i32 : i32
      cf.br ^bb165(%960 : i32)
    ^bb173:  // pred: ^bb165
      cf.br ^bb174(%c0_i32 : i32)
    ^bb174(%961: i32):  // 2 preds: ^bb173, ^bb175
      %962 = arith.cmpi slt, %961, %625 : i32
      cf.cond_br %962, ^bb175, ^bb176 {llvm.loop_annotation = #loop_annotation}
    ^bb175:  // pred: ^bb174
      %963 = cute_nvgpu.arch.copy.ldsm %ptr_584{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %964 = vector.extractelement %963[%70 : i32] : vector<4xi32>
      llvm.store %964, %663 : i32, !llvm.ptr
      %965 = vector.extractelement %963[%69 : i32] : vector<4xi32>
      llvm.store %965, %664 : i32, !llvm.ptr
      %966 = vector.extractelement %963[%68 : i32] : vector<4xi32>
      llvm.store %966, %665 : i32, !llvm.ptr
      %967 = vector.extractelement %963[%67 : i32] : vector<4xi32>
      llvm.store %967, %666 : i32, !llvm.ptr
      %968 = arith.addi %961, %c1_i32 : i32
      cf.br ^bb174(%968 : i32)
    ^bb176:  // pred: ^bb174
      cf.br ^bb177(%c0_i32 : i32)
    ^bb177(%969: i32):  // 2 preds: ^bb176, ^bb178
      %970 = arith.cmpi slt, %969, %624 : i32
      cf.cond_br %970, ^bb178, ^bb179 {llvm.loop_annotation = #loop_annotation}
    ^bb178:  // pred: ^bb177
      %coord_810 = cute.make_coord(%969) : (i32) -> !cute.coord<"(_,?)">
      %idx_811 = cute.crd2idx(%coord_810, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_812 = cute.add_offset(%ptr_593, %idx_811) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_813 = cute.crd2idx(%coord_810, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_814 = cute.add_offset(%ptr_594, %idx_813) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %971 = cute_nvgpu.arch.copy.ldsm %ptr_812{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %972 = vector.extractelement %971[%70 : i32] : vector<4xi32>
      %973 = builtin.unrealized_conversion_cast %ptr_814 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %972, %973 : i32, !llvm.ptr
      %974 = vector.extractelement %971[%69 : i32] : vector<4xi32>
      %ptr_815 = cute.add_offset(%ptr_814, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %975 = builtin.unrealized_conversion_cast %ptr_815 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %974, %975 : i32, !llvm.ptr
      %976 = vector.extractelement %971[%68 : i32] : vector<4xi32>
      %ptr_816 = cute.add_offset(%ptr_814, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %977 = builtin.unrealized_conversion_cast %ptr_816 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %976, %977 : i32, !llvm.ptr
      %978 = vector.extractelement %971[%67 : i32] : vector<4xi32>
      %ptr_817 = cute.add_offset(%ptr_814, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %979 = builtin.unrealized_conversion_cast %ptr_817 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %978, %979 : i32, !llvm.ptr
      %980 = arith.addi %969, %c1_i32 : i32
      cf.br ^bb177(%980 : i32)
    ^bb179:  // pred: ^bb177
      cf.br ^bb180(%c0_i32 : i32)
    ^bb180(%981: i32):  // 2 preds: ^bb179, ^bb187
      %982 = arith.cmpi slt, %981, %625 : i32
      cf.cond_br %982, ^bb181, ^bb188 {llvm.loop_annotation = #loop_annotation}
    ^bb181:  // pred: ^bb180
      cf.br ^bb182(%c0_i32 : i32)
    ^bb182(%983: i32):  // 2 preds: ^bb181, ^bb186
      %984 = arith.cmpi slt, %983, %625 : i32
      cf.cond_br %984, ^bb183, ^bb187 {llvm.loop_annotation = #loop_annotation}
    ^bb183:  // pred: ^bb182
      cf.br ^bb184(%c0_i32 : i32)
    ^bb184(%985: i32):  // 2 preds: ^bb183, ^bb185
      %986 = arith.cmpi slt, %985, %634 : i32
      cf.cond_br %986, ^bb185, ^bb186 {llvm.loop_annotation = #loop_annotation}
    ^bb185:  // pred: ^bb184
      %coord_818 = cute.make_coord(%985, %981) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_819 = cute.make_coord(%983, %985) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_820 = cute.crd2idx(%coord_818, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_821 = cute.add_offset(%ptr_582, %idx_820) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_822 = cute.crd2idx(%coord_819, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_823 = cute.add_offset(%iter_761, %idx_822) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %987 = llvm.load %667 : !llvm.ptr -> i32
      %988 = llvm.load %668 : !llvm.ptr -> i32
      %989 = llvm.load %669 : !llvm.ptr -> i32
      %990 = llvm.load %670 : !llvm.ptr -> i32
      %991 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %992 = llvm.load %991 : !llvm.ptr -> i32
      %993 = llvm.getelementptr %991[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %994 = llvm.load %993 : !llvm.ptr -> i32
      %995 = builtin.unrealized_conversion_cast %ptr_823 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %996 = llvm.load %995 : !llvm.ptr -> f32
      %997 = llvm.getelementptr %995[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %998 = llvm.load %997 : !llvm.ptr -> f32
      %999 = llvm.getelementptr %995[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1000 = llvm.load %999 : !llvm.ptr -> f32
      %1001 = llvm.getelementptr %995[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1002 = llvm.load %1001 : !llvm.ptr -> f32
      %1003:4 = cute_nvgpu.arch.mma.SM80 A[%987, %988, %989, %990]  B[%992, %994]  C[%996, %998, %1000, %1002] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1003#0, %995 : f32, !llvm.ptr
      llvm.store %1003#1, %997 : f32, !llvm.ptr
      llvm.store %1003#2, %999 : f32, !llvm.ptr
      llvm.store %1003#3, %1001 : f32, !llvm.ptr
      %1004 = arith.addi %985, %c1_i32 : i32
      cf.br ^bb184(%1004 : i32)
    ^bb186:  // pred: ^bb184
      %1005 = arith.addi %983, %c1_i32 : i32
      cf.br ^bb182(%1005 : i32)
    ^bb187:  // pred: ^bb182
      %1006 = arith.addi %981, %c1_i32 : i32
      cf.br ^bb180(%1006 : i32)
    ^bb188:  // pred: ^bb180
      cf.br ^bb189(%c0_i32 : i32)
    ^bb189(%1007: i32):  // 2 preds: ^bb188, ^bb190
      %1008 = arith.cmpi slt, %1007, %625 : i32
      cf.cond_br %1008, ^bb190, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb190:  // pred: ^bb189
      %1009 = cute_nvgpu.arch.copy.ldsm %ptr_596{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1010 = vector.extractelement %1009[%70 : i32] : vector<4xi32>
      llvm.store %1010, %671 : i32, !llvm.ptr
      %1011 = vector.extractelement %1009[%69 : i32] : vector<4xi32>
      llvm.store %1011, %672 : i32, !llvm.ptr
      %1012 = vector.extractelement %1009[%68 : i32] : vector<4xi32>
      llvm.store %1012, %673 : i32, !llvm.ptr
      %1013 = vector.extractelement %1009[%67 : i32] : vector<4xi32>
      llvm.store %1013, %674 : i32, !llvm.ptr
      %1014 = arith.addi %1007, %c1_i32 : i32
      cf.br ^bb189(%1014 : i32)
    ^bb191:  // pred: ^bb189
      cf.br ^bb192(%c0_i32 : i32)
    ^bb192(%1015: i32):  // 2 preds: ^bb191, ^bb193
      %1016 = arith.cmpi slt, %1015, %624 : i32
      cf.cond_br %1016, ^bb193, ^bb194 {llvm.loop_annotation = #loop_annotation}
    ^bb193:  // pred: ^bb192
      %coord_824 = cute.make_coord(%1015) : (i32) -> !cute.coord<"(_,?)">
      %idx_825 = cute.crd2idx(%coord_824, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_826 = cute.add_offset(%ptr_605, %idx_825) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_827 = cute.crd2idx(%coord_824, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_828 = cute.add_offset(%ptr_606, %idx_827) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1017 = cute_nvgpu.arch.copy.ldsm %ptr_826{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1018 = vector.extractelement %1017[%70 : i32] : vector<4xi32>
      %1019 = builtin.unrealized_conversion_cast %ptr_828 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1018, %1019 : i32, !llvm.ptr
      %1020 = vector.extractelement %1017[%69 : i32] : vector<4xi32>
      %ptr_829 = cute.add_offset(%ptr_828, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1021 = builtin.unrealized_conversion_cast %ptr_829 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1020, %1021 : i32, !llvm.ptr
      %1022 = vector.extractelement %1017[%68 : i32] : vector<4xi32>
      %ptr_830 = cute.add_offset(%ptr_828, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %1023 = builtin.unrealized_conversion_cast %ptr_830 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1022, %1023 : i32, !llvm.ptr
      %1024 = vector.extractelement %1017[%67 : i32] : vector<4xi32>
      %ptr_831 = cute.add_offset(%ptr_828, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %1025 = builtin.unrealized_conversion_cast %ptr_831 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1024, %1025 : i32, !llvm.ptr
      %1026 = arith.addi %1015, %c1_i32 : i32
      cf.br ^bb192(%1026 : i32)
    ^bb194:  // pred: ^bb192
      cf.br ^bb195(%c0_i32 : i32)
    ^bb195(%1027: i32):  // 2 preds: ^bb194, ^bb202
      %1028 = arith.cmpi slt, %1027, %625 : i32
      cf.cond_br %1028, ^bb196, ^bb203 {llvm.loop_annotation = #loop_annotation}
    ^bb196:  // pred: ^bb195
      cf.br ^bb197(%c0_i32 : i32)
    ^bb197(%1029: i32):  // 2 preds: ^bb196, ^bb201
      %1030 = arith.cmpi slt, %1029, %625 : i32
      cf.cond_br %1030, ^bb198, ^bb202 {llvm.loop_annotation = #loop_annotation}
    ^bb198:  // pred: ^bb197
      cf.br ^bb199(%c0_i32 : i32)
    ^bb199(%1031: i32):  // 2 preds: ^bb198, ^bb200
      %1032 = arith.cmpi slt, %1031, %634 : i32
      cf.cond_br %1032, ^bb200, ^bb201 {llvm.loop_annotation = #loop_annotation}
    ^bb200:  // pred: ^bb199
      %coord_832 = cute.make_coord(%1031, %1027) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_833 = cute.make_coord(%1029, %1031) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_834 = cute.crd2idx(%coord_832, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_835 = cute.add_offset(%ptr_594, %idx_834) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_836 = cute.crd2idx(%coord_833, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_837 = cute.add_offset(%iter_761, %idx_836) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1033 = llvm.load %675 : !llvm.ptr -> i32
      %1034 = llvm.load %676 : !llvm.ptr -> i32
      %1035 = llvm.load %677 : !llvm.ptr -> i32
      %1036 = llvm.load %678 : !llvm.ptr -> i32
      %1037 = builtin.unrealized_conversion_cast %ptr_835 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1038 = llvm.load %1037 : !llvm.ptr -> i32
      %1039 = llvm.getelementptr %1037[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1040 = llvm.load %1039 : !llvm.ptr -> i32
      %1041 = builtin.unrealized_conversion_cast %ptr_837 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1042 = llvm.load %1041 : !llvm.ptr -> f32
      %1043 = llvm.getelementptr %1041[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1044 = llvm.load %1043 : !llvm.ptr -> f32
      %1045 = llvm.getelementptr %1041[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1046 = llvm.load %1045 : !llvm.ptr -> f32
      %1047 = llvm.getelementptr %1041[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1048 = llvm.load %1047 : !llvm.ptr -> f32
      %1049:4 = cute_nvgpu.arch.mma.SM80 A[%1033, %1034, %1035, %1036]  B[%1038, %1040]  C[%1042, %1044, %1046, %1048] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1049#0, %1041 : f32, !llvm.ptr
      llvm.store %1049#1, %1043 : f32, !llvm.ptr
      llvm.store %1049#2, %1045 : f32, !llvm.ptr
      llvm.store %1049#3, %1047 : f32, !llvm.ptr
      %1050 = arith.addi %1031, %c1_i32 : i32
      cf.br ^bb199(%1050 : i32)
    ^bb201:  // pred: ^bb199
      %1051 = arith.addi %1029, %c1_i32 : i32
      cf.br ^bb197(%1051 : i32)
    ^bb202:  // pred: ^bb197
      %1052 = arith.addi %1027, %c1_i32 : i32
      cf.br ^bb195(%1052 : i32)
    ^bb203:  // pred: ^bb195
      cf.br ^bb204(%c0_i32 : i32)
    ^bb204(%1053: i32):  // 2 preds: ^bb203, ^bb205
      %1054 = arith.cmpi slt, %1053, %625 : i32
      cf.cond_br %1054, ^bb205, ^bb206 {llvm.loop_annotation = #loop_annotation}
    ^bb205:  // pred: ^bb204
      %1055 = cute_nvgpu.arch.copy.ldsm %ptr_608{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1056 = vector.extractelement %1055[%70 : i32] : vector<4xi32>
      llvm.store %1056, %679 : i32, !llvm.ptr
      %1057 = vector.extractelement %1055[%69 : i32] : vector<4xi32>
      llvm.store %1057, %680 : i32, !llvm.ptr
      %1058 = vector.extractelement %1055[%68 : i32] : vector<4xi32>
      llvm.store %1058, %681 : i32, !llvm.ptr
      %1059 = vector.extractelement %1055[%67 : i32] : vector<4xi32>
      llvm.store %1059, %682 : i32, !llvm.ptr
      %1060 = arith.addi %1053, %c1_i32 : i32
      cf.br ^bb204(%1060 : i32)
    ^bb206:  // pred: ^bb204
      cf.br ^bb207(%c0_i32 : i32)
    ^bb207(%1061: i32):  // 2 preds: ^bb206, ^bb208
      %1062 = arith.cmpi slt, %1061, %624 : i32
      cf.cond_br %1062, ^bb208, ^bb209 {llvm.loop_annotation = #loop_annotation}
    ^bb208:  // pred: ^bb207
      %coord_838 = cute.make_coord(%1061) : (i32) -> !cute.coord<"(_,?)">
      %idx_839 = cute.crd2idx(%coord_838, %65) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_840 = cute.add_offset(%ptr_617, %idx_839) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_841 = cute.crd2idx(%coord_838, %64) : (!cute.coord<"(_,?)">, !cute.layout<"(((4,2),1),((4))):(((1,32),0),((4)))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_842 = cute.add_offset(%ptr_618, %idx_841) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1063 = cute_nvgpu.arch.copy.ldsm %ptr_840{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <bf16, smem, align<16>> -> vector<4xi32>
      %1064 = vector.extractelement %1063[%70 : i32] : vector<4xi32>
      %1065 = builtin.unrealized_conversion_cast %ptr_842 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1064, %1065 : i32, !llvm.ptr
      %1066 = vector.extractelement %1063[%69 : i32] : vector<4xi32>
      %ptr_843 = cute.add_offset(%ptr_842, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1067 = builtin.unrealized_conversion_cast %ptr_843 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1066, %1067 : i32, !llvm.ptr
      %1068 = vector.extractelement %1063[%68 : i32] : vector<4xi32>
      %ptr_844 = cute.add_offset(%ptr_842, %63) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<8>>
      %1069 = builtin.unrealized_conversion_cast %ptr_844 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1068, %1069 : i32, !llvm.ptr
      %1070 = vector.extractelement %1063[%67 : i32] : vector<4xi32>
      %ptr_845 = cute.add_offset(%ptr_842, %62) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"34">) -> !cute.ptr<bf16, rmem, align<4>>
      %1071 = builtin.unrealized_conversion_cast %ptr_845 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1070, %1071 : i32, !llvm.ptr
      %1072 = arith.addi %1061, %c1_i32 : i32
      cf.br ^bb207(%1072 : i32)
    ^bb209:  // pred: ^bb207
      cf.br ^bb210(%c0_i32 : i32)
    ^bb210(%1073: i32):  // 2 preds: ^bb209, ^bb217
      %1074 = arith.cmpi slt, %1073, %625 : i32
      cf.cond_br %1074, ^bb211, ^bb218 {llvm.loop_annotation = #loop_annotation}
    ^bb211:  // pred: ^bb210
      cf.br ^bb212(%c0_i32 : i32)
    ^bb212(%1075: i32):  // 2 preds: ^bb211, ^bb216
      %1076 = arith.cmpi slt, %1075, %625 : i32
      cf.cond_br %1076, ^bb213, ^bb217 {llvm.loop_annotation = #loop_annotation}
    ^bb213:  // pred: ^bb212
      cf.br ^bb214(%c0_i32 : i32)
    ^bb214(%1077: i32):  // 2 preds: ^bb213, ^bb215
      %1078 = arith.cmpi slt, %1077, %634 : i32
      cf.cond_br %1078, ^bb215, ^bb216 {llvm.loop_annotation = #loop_annotation}
    ^bb215:  // pred: ^bb214
      %coord_846 = cute.make_coord(%1077, %1073) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_847 = cute.make_coord(%1075, %1077) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_848 = cute.crd2idx(%coord_846, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_849 = cute.add_offset(%ptr_606, %idx_848) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_850 = cute.crd2idx(%coord_847, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_851 = cute.add_offset(%iter_761, %idx_850) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1079 = llvm.load %683 : !llvm.ptr -> i32
      %1080 = llvm.load %684 : !llvm.ptr -> i32
      %1081 = llvm.load %685 : !llvm.ptr -> i32
      %1082 = llvm.load %686 : !llvm.ptr -> i32
      %1083 = builtin.unrealized_conversion_cast %ptr_849 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1084 = llvm.load %1083 : !llvm.ptr -> i32
      %1085 = llvm.getelementptr %1083[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1086 = llvm.load %1085 : !llvm.ptr -> i32
      %1087 = builtin.unrealized_conversion_cast %ptr_851 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1088 = llvm.load %1087 : !llvm.ptr -> f32
      %1089 = llvm.getelementptr %1087[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1090 = llvm.load %1089 : !llvm.ptr -> f32
      %1091 = llvm.getelementptr %1087[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1092 = llvm.load %1091 : !llvm.ptr -> f32
      %1093 = llvm.getelementptr %1087[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1094 = llvm.load %1093 : !llvm.ptr -> f32
      %1095:4 = cute_nvgpu.arch.mma.SM80 A[%1079, %1080, %1081, %1082]  B[%1084, %1086]  C[%1088, %1090, %1092, %1094] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1095#0, %1087 : f32, !llvm.ptr
      llvm.store %1095#1, %1089 : f32, !llvm.ptr
      llvm.store %1095#2, %1091 : f32, !llvm.ptr
      llvm.store %1095#3, %1093 : f32, !llvm.ptr
      %1096 = arith.addi %1077, %c1_i32 : i32
      cf.br ^bb214(%1096 : i32)
    ^bb216:  // pred: ^bb214
      %1097 = arith.addi %1075, %c1_i32 : i32
      cf.br ^bb212(%1097 : i32)
    ^bb217:  // pred: ^bb212
      %1098 = arith.addi %1073, %c1_i32 : i32
      cf.br ^bb210(%1098 : i32)
    ^bb218:  // pred: ^bb210
      cf.br ^bb219(%c0_i32 : i32)
    ^bb219(%1099: i32):  // 2 preds: ^bb218, ^bb226
      %1100 = arith.cmpi slt, %1099, %625 : i32
      cf.cond_br %1100, ^bb220, ^bb227 {llvm.loop_annotation = #loop_annotation}
    ^bb220:  // pred: ^bb219
      cf.br ^bb221(%c0_i32 : i32)
    ^bb221(%1101: i32):  // 2 preds: ^bb220, ^bb225
      %1102 = arith.cmpi slt, %1101, %625 : i32
      cf.cond_br %1102, ^bb222, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb222:  // pred: ^bb221
      cf.br ^bb223(%c0_i32 : i32)
    ^bb223(%1103: i32):  // 2 preds: ^bb222, ^bb224
      %1104 = arith.cmpi slt, %1103, %634 : i32
      cf.cond_br %1104, ^bb224, ^bb225 {llvm.loop_annotation = #loop_annotation}
    ^bb224:  // pred: ^bb223
      %coord_852 = cute.make_coord(%1103, %1099) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_853 = cute.make_coord(%1101, %1103) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_854 = cute.crd2idx(%coord_852, %58) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(2,4),1):((1,2),(32,4),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_855 = cute.add_offset(%ptr_618, %idx_854) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_856 = cute.crd2idx(%coord_853, %75) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,8):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_857 = cute.add_offset(%iter_761, %idx_856) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1105 = llvm.load %687 : !llvm.ptr -> i32
      %1106 = llvm.load %688 : !llvm.ptr -> i32
      %1107 = llvm.load %689 : !llvm.ptr -> i32
      %1108 = llvm.load %690 : !llvm.ptr -> i32
      %1109 = builtin.unrealized_conversion_cast %ptr_855 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1110 = llvm.load %1109 : !llvm.ptr -> i32
      %1111 = llvm.getelementptr %1109[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1112 = llvm.load %1111 : !llvm.ptr -> i32
      %1113 = builtin.unrealized_conversion_cast %ptr_857 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1114 = llvm.load %1113 : !llvm.ptr -> f32
      %1115 = llvm.getelementptr %1113[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1116 = llvm.load %1115 : !llvm.ptr -> f32
      %1117 = llvm.getelementptr %1113[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1118 = llvm.load %1117 : !llvm.ptr -> f32
      %1119 = llvm.getelementptr %1113[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1120 = llvm.load %1119 : !llvm.ptr -> f32
      %1121:4 = cute_nvgpu.arch.mma.SM80 A[%1105, %1106, %1107, %1108]  B[%1110, %1112]  C[%1114, %1116, %1118, %1120] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1121#0, %1113 : f32, !llvm.ptr
      llvm.store %1121#1, %1115 : f32, !llvm.ptr
      llvm.store %1121#2, %1117 : f32, !llvm.ptr
      llvm.store %1121#3, %1119 : f32, !llvm.ptr
      %1122 = arith.addi %1103, %c1_i32 : i32
      cf.br ^bb223(%1122 : i32)
    ^bb225:  // pred: ^bb223
      %1123 = arith.addi %1101, %c1_i32 : i32
      cf.br ^bb221(%1123 : i32)
    ^bb226:  // pred: ^bb221
      %1124 = arith.addi %1099, %c1_i32 : i32
      cf.br ^bb219(%1124 : i32)
    ^bb227:  // pred: ^bb219
      nvvm.cp.async.wait.group 0
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %1125 = arith.cmpi sgt, %697, %c0_i32 : i32
      cf.cond_br %1125, ^bb228, ^bb256
    ^bb228:  // pred: ^bb227
      %sub_858 = cute.tuple_sub(%sub_641, %116) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_859 = cute.make_coord(%sub_858) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?)">
      %1126:3 = cute.get_scalars(%lay_145) <{only_dynamic}> : !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">
      %iv_860 = cute.assume(%1126#1) : (i64) -> !cute.i64<divby 128>
      %stride_861 = cute.make_stride(%iv_860) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_862 = cute.make_layout(%111, %stride_861) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %idx_863 = cute.crd2idx(%coord_859, %lay_145) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,?):((1,0),?{i64 div=128},64,?{i64 div=512})">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_864 = cute.add_offset(%ptr_140, %idx_863) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_865 = cute.get_iter(%rmem_270) : !memref_rmem_i8_
      %append_866 = cute.append_to_rank<2> (%lay_862, %117) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">, !cute.layout<"1:0">
      %1127 = cute.get_scalars(%append_866) <{only_dynamic}> : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %iv_867 = cute.assume(%1127) : (i64) -> !cute.i64<divby 128>
      %stride_868 = cute.make_stride(%iv_867) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),(?{i64 div=128},64))">
      %lay_869 = cute.make_layout(%80, %stride_868) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %append_870 = cute.append_to_rank<2> (%lay_869, %117) : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">, !cute.layout<"1:0">
      %1128 = cute.get_scalars(%append_870) <{only_dynamic}> : !cute.layout<"((8,1),(4,2)):((1,0),(?{i64 div=128},64))">
      %iv_871 = cute.assume(%1128) : (i64) -> !cute.i64<divby 128>
      %stride_872 = cute.make_stride(%iv_871) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),((?{i64 div=128},64)))">
      %lay_873 = cute.make_layout(%79, %stride_872) : !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">
      cf.br ^bb229(%c0_i32 : i32)
    ^bb229(%1129: i32):  // 2 preds: ^bb228, ^bb230
      %1130 = arith.cmpi slt, %1129, %634 : i32
      cf.cond_br %1130, ^bb230, ^bb231 {llvm.loop_annotation = #loop_annotation}
    ^bb230:  // pred: ^bb229
      %coord_874 = cute.make_coord(%1129) : (i32) -> !cute.coord<"(_,?)">
      %idx_875 = cute.crd2idx(%coord_874, %lay_873) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((?{i64 div=128},64)))">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_876 = cute.add_offset(%ptr_864, %idx_875) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_877 = cute.crd2idx(%coord_874, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_878 = cute.add_offset(%ptr_146, %idx_877) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_879 = cute.crd2idx(%coord_874, %77) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,2))):(2,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_880 = cute.add_offset(%iter_865, %idx_879) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1131 = builtin.unrealized_conversion_cast %ptr_880 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1132 = llvm.load %1131 : !llvm.ptr -> i8
      %1133 = llvm.trunc %1132 : i8 to i1
      %iter_881 = cute.recast_iter(%ptr_876) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_882 = cute.recast_iter(%ptr_878) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_882 : !cute.ptr<i128, smem>, %iter_881 : !cute.ptr<i128, gmem>, %1133 : i1) {cache_mode = <always>}
      %1134 = arith.addi %1129, %c1_i32 : i32
      cf.br ^bb229(%1134 : i32)
    ^bb231:  // pred: ^bb229
      cf.cond_br %573, ^bb232, ^bb236
    ^bb232:  // pred: ^bb231
      %coord_883 = cute.make_coord(%sub_858) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,0,_,?)">
      %idx_884 = cute.crd2idx(%coord_883, %lay_162) : (!cute.coord<"(_,0,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_885 = cute.add_offset(%ptr_158, %idx_884) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_886 = cute.recast_iter(%ptr_885) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_887 = cute.recast_iter(%ptr_163) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb233(%c0_i32 : i32)
    ^bb233(%1135: i32):  // 2 preds: ^bb232, ^bb234
      %1136 = arith.cmpi slt, %1135, %625 : i32
      cf.cond_br %1136, ^bb234, ^bb235 {llvm.loop_annotation = #loop_annotation}
    ^bb234:  // pred: ^bb233
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_887 : !cute.ptr<i128, smem>, %iter_886 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %1137 = arith.addi %1135, %c1_i32 : i32
      cf.br ^bb233(%1137 : i32)
    ^bb235:  // pred: ^bb233
      cf.br ^bb237
    ^bb236:  // pred: ^bb231
      %view_888 = cute.make_view(%ptr_163) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_888, row_major : !memref_smem_bf16_2
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      cf.cond_br %586, ^bb238, ^bb242
    ^bb238:  // pred: ^bb237
      %coord_889 = cute.make_coord(%sub_858) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,1,_,?)">
      %idx_890 = cute.crd2idx(%coord_889, %lay_162) : (!cute.coord<"(_,1,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_891 = cute.add_offset(%ptr_158, %idx_890) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_892 = cute.add_offset(%ptr_163, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_893 = cute.recast_iter(%ptr_891) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_894 = cute.recast_iter(%ptr_892) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb239(%c0_i32 : i32)
    ^bb239(%1138: i32):  // 2 preds: ^bb238, ^bb240
      %1139 = arith.cmpi slt, %1138, %625 : i32
      cf.cond_br %1139, ^bb240, ^bb241 {llvm.loop_annotation = #loop_annotation}
    ^bb240:  // pred: ^bb239
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_894 : !cute.ptr<i128, smem>, %iter_893 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %1140 = arith.addi %1138, %c1_i32 : i32
      cf.br ^bb239(%1140 : i32)
    ^bb241:  // pred: ^bb239
      cf.br ^bb243
    ^bb242:  // pred: ^bb237
      %ptr_895 = cute.add_offset(%ptr_163, %88) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %view_896 = cute.make_view(%ptr_895) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_896, row_major : !memref_smem_bf16_2
      cf.br ^bb243
    ^bb243:  // 2 preds: ^bb241, ^bb242
      cf.cond_br %598, ^bb244, ^bb248
    ^bb244:  // pred: ^bb243
      %coord_897 = cute.make_coord(%sub_858) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,2,_,?)">
      %idx_898 = cute.crd2idx(%coord_897, %lay_162) : (!cute.coord<"(_,2,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_899 = cute.add_offset(%ptr_158, %idx_898) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_900 = cute.add_offset(%ptr_163, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_901 = cute.recast_iter(%ptr_899) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_902 = cute.recast_iter(%ptr_900) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb245(%c0_i32 : i32)
    ^bb245(%1141: i32):  // 2 preds: ^bb244, ^bb246
      %1142 = arith.cmpi slt, %1141, %625 : i32
      cf.cond_br %1142, ^bb246, ^bb247 {llvm.loop_annotation = #loop_annotation}
    ^bb246:  // pred: ^bb245
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_902 : !cute.ptr<i128, smem>, %iter_901 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %1143 = arith.addi %1141, %c1_i32 : i32
      cf.br ^bb245(%1143 : i32)
    ^bb247:  // pred: ^bb245
      cf.br ^bb249
    ^bb248:  // pred: ^bb243
      %ptr_903 = cute.add_offset(%ptr_163, %85) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %view_904 = cute.make_view(%ptr_903) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_904, row_major : !memref_smem_bf16_2
      cf.br ^bb249
    ^bb249:  // 2 preds: ^bb247, ^bb248
      cf.cond_br %610, ^bb250, ^bb254
    ^bb250:  // pred: ^bb249
      %coord_905 = cute.make_coord(%sub_858) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,3,_,?)">
      %idx_906 = cute.crd2idx(%coord_905, %lay_162) : (!cute.coord<"(_,3,_,?)">, !cute.layout<"((8,1),4,1,?):((1,0),?{i64 div=128},0,64)">) -> !cute.int_tuple<"?{i64 div=64}">
      %ptr_907 = cute.add_offset(%ptr_158, %idx_906) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_908 = cute.add_offset(%ptr_163, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_909 = cute.recast_iter(%ptr_907) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_910 = cute.recast_iter(%ptr_908) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb251(%c0_i32 : i32)
    ^bb251(%1144: i32):  // 2 preds: ^bb250, ^bb252
      %1145 = arith.cmpi slt, %1144, %625 : i32
      cf.cond_br %1145, ^bb252, ^bb253 {llvm.loop_annotation = #loop_annotation}
    ^bb252:  // pred: ^bb251
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_910 : !cute.ptr<i128, smem>, %iter_909 : !cute.ptr<i128, gmem>) {cache_mode = <always>}
      %1146 = arith.addi %1144, %c1_i32 : i32
      cf.br ^bb251(%1146 : i32)
    ^bb253:  // pred: ^bb251
      cf.br ^bb255
    ^bb254:  // pred: ^bb249
      %ptr_911 = cute.add_offset(%ptr_163, %82) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %view_912 = cute.make_view(%ptr_911) : !memref_smem_bf16_2
      cute.memref.store_vec %cst_0, %view_912, row_major : !memref_smem_bf16_2
      cf.br ^bb255
    ^bb255:  // 2 preds: ^bb253, ^bb254
      nvvm.cp.async.commit.group
      cf.br ^bb256
    ^bb256:  // 2 preds: ^bb227, ^bb255
      %1147 = cute.memref.load_vec %rmem_734, row_major : !memref_rmem_f32_1
      %1148 = arith.mulf %1147, %cst : vector<32xf32>
      cute.memref.store_vec %1148, %rmem_734, row_major : !memref_rmem_f32_1
      %1149 = cute.memref.load(%rmem_734, %97) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">) -> f32
      %1150 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1149 : (f32) -> f32
      cute.memref.store(%rmem_734, %97, %1150) : (!memref_rmem_f32_1, !cute.coord<"(0,0,0)">, f32) -> ()
      %1151 = cute.memref.load(%rmem_734, %95) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">) -> f32
      %1152 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1151 : (f32) -> f32
      cute.memref.store(%rmem_734, %95, %1152) : (!memref_rmem_f32_1, !cute.coord<"(0,0,1)">, f32) -> ()
      %1153 = cute.memref.load(%rmem_734, %42) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">) -> f32
      %1154 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1153 : (f32) -> f32
      cute.memref.store(%rmem_734, %42, %1154) : (!memref_rmem_f32_1, !cute.coord<"(0,0,2)">, f32) -> ()
      %1155 = cute.memref.load(%rmem_734, %41) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">) -> f32
      %1156 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1155 : (f32) -> f32
      cute.memref.store(%rmem_734, %41, %1156) : (!memref_rmem_f32_1, !cute.coord<"(0,0,3)">, f32) -> ()
      %1157 = cute.memref.load(%rmem_734, %40) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">) -> f32
      %1158 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1157 : (f32) -> f32
      cute.memref.store(%rmem_734, %40, %1158) : (!memref_rmem_f32_1, !cute.coord<"(0,0,4)">, f32) -> ()
      %1159 = cute.memref.load(%rmem_734, %39) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">) -> f32
      %1160 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1159 : (f32) -> f32
      cute.memref.store(%rmem_734, %39, %1160) : (!memref_rmem_f32_1, !cute.coord<"(0,0,5)">, f32) -> ()
      %1161 = cute.memref.load(%rmem_734, %38) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">) -> f32
      %1162 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1161 : (f32) -> f32
      cute.memref.store(%rmem_734, %38, %1162) : (!memref_rmem_f32_1, !cute.coord<"(0,0,6)">, f32) -> ()
      %1163 = cute.memref.load(%rmem_734, %37) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">) -> f32
      %1164 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1163 : (f32) -> f32
      cute.memref.store(%rmem_734, %37, %1164) : (!memref_rmem_f32_1, !cute.coord<"(0,0,7)">, f32) -> ()
      %1165 = cute.memref.load(%rmem_734, %36) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">) -> f32
      %1166 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1165 : (f32) -> f32
      cute.memref.store(%rmem_734, %36, %1166) : (!memref_rmem_f32_1, !cute.coord<"(1,0,0)">, f32) -> ()
      %1167 = cute.memref.load(%rmem_734, %35) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">) -> f32
      %1168 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1167 : (f32) -> f32
      cute.memref.store(%rmem_734, %35, %1168) : (!memref_rmem_f32_1, !cute.coord<"(1,0,1)">, f32) -> ()
      %1169 = cute.memref.load(%rmem_734, %34) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">) -> f32
      %1170 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1169 : (f32) -> f32
      cute.memref.store(%rmem_734, %34, %1170) : (!memref_rmem_f32_1, !cute.coord<"(1,0,2)">, f32) -> ()
      %1171 = cute.memref.load(%rmem_734, %33) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">) -> f32
      %1172 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1171 : (f32) -> f32
      cute.memref.store(%rmem_734, %33, %1172) : (!memref_rmem_f32_1, !cute.coord<"(1,0,3)">, f32) -> ()
      %1173 = cute.memref.load(%rmem_734, %32) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">) -> f32
      %1174 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1173 : (f32) -> f32
      cute.memref.store(%rmem_734, %32, %1174) : (!memref_rmem_f32_1, !cute.coord<"(1,0,4)">, f32) -> ()
      %1175 = cute.memref.load(%rmem_734, %31) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">) -> f32
      %1176 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1175 : (f32) -> f32
      cute.memref.store(%rmem_734, %31, %1176) : (!memref_rmem_f32_1, !cute.coord<"(1,0,5)">, f32) -> ()
      %1177 = cute.memref.load(%rmem_734, %30) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">) -> f32
      %1178 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1177 : (f32) -> f32
      cute.memref.store(%rmem_734, %30, %1178) : (!memref_rmem_f32_1, !cute.coord<"(1,0,6)">, f32) -> ()
      %1179 = cute.memref.load(%rmem_734, %29) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">) -> f32
      %1180 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1179 : (f32) -> f32
      cute.memref.store(%rmem_734, %29, %1180) : (!memref_rmem_f32_1, !cute.coord<"(1,0,7)">, f32) -> ()
      %1181 = cute.memref.load(%rmem_734, %28) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">) -> f32
      %1182 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1181 : (f32) -> f32
      cute.memref.store(%rmem_734, %28, %1182) : (!memref_rmem_f32_1, !cute.coord<"(2,0,0)">, f32) -> ()
      %1183 = cute.memref.load(%rmem_734, %27) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">) -> f32
      %1184 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1183 : (f32) -> f32
      cute.memref.store(%rmem_734, %27, %1184) : (!memref_rmem_f32_1, !cute.coord<"(2,0,1)">, f32) -> ()
      %1185 = cute.memref.load(%rmem_734, %26) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">) -> f32
      %1186 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1185 : (f32) -> f32
      cute.memref.store(%rmem_734, %26, %1186) : (!memref_rmem_f32_1, !cute.coord<"(2,0,2)">, f32) -> ()
      %1187 = cute.memref.load(%rmem_734, %25) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">) -> f32
      %1188 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1187 : (f32) -> f32
      cute.memref.store(%rmem_734, %25, %1188) : (!memref_rmem_f32_1, !cute.coord<"(2,0,3)">, f32) -> ()
      %1189 = cute.memref.load(%rmem_734, %24) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">) -> f32
      %1190 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1189 : (f32) -> f32
      cute.memref.store(%rmem_734, %24, %1190) : (!memref_rmem_f32_1, !cute.coord<"(2,0,4)">, f32) -> ()
      %1191 = cute.memref.load(%rmem_734, %23) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">) -> f32
      %1192 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1191 : (f32) -> f32
      cute.memref.store(%rmem_734, %23, %1192) : (!memref_rmem_f32_1, !cute.coord<"(2,0,5)">, f32) -> ()
      %1193 = cute.memref.load(%rmem_734, %22) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">) -> f32
      %1194 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1193 : (f32) -> f32
      cute.memref.store(%rmem_734, %22, %1194) : (!memref_rmem_f32_1, !cute.coord<"(2,0,6)">, f32) -> ()
      %1195 = cute.memref.load(%rmem_734, %21) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">) -> f32
      %1196 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1195 : (f32) -> f32
      cute.memref.store(%rmem_734, %21, %1196) : (!memref_rmem_f32_1, !cute.coord<"(2,0,7)">, f32) -> ()
      %1197 = cute.memref.load(%rmem_734, %20) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">) -> f32
      %1198 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1197 : (f32) -> f32
      cute.memref.store(%rmem_734, %20, %1198) : (!memref_rmem_f32_1, !cute.coord<"(3,0,0)">, f32) -> ()
      %1199 = cute.memref.load(%rmem_734, %19) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">) -> f32
      %1200 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1199 : (f32) -> f32
      cute.memref.store(%rmem_734, %19, %1200) : (!memref_rmem_f32_1, !cute.coord<"(3,0,1)">, f32) -> ()
      %1201 = cute.memref.load(%rmem_734, %18) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">) -> f32
      %1202 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1201 : (f32) -> f32
      cute.memref.store(%rmem_734, %18, %1202) : (!memref_rmem_f32_1, !cute.coord<"(3,0,2)">, f32) -> ()
      %1203 = cute.memref.load(%rmem_734, %17) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">) -> f32
      %1204 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1203 : (f32) -> f32
      cute.memref.store(%rmem_734, %17, %1204) : (!memref_rmem_f32_1, !cute.coord<"(3,0,3)">, f32) -> ()
      %1205 = cute.memref.load(%rmem_734, %16) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">) -> f32
      %1206 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1205 : (f32) -> f32
      cute.memref.store(%rmem_734, %16, %1206) : (!memref_rmem_f32_1, !cute.coord<"(3,0,4)">, f32) -> ()
      %1207 = cute.memref.load(%rmem_734, %15) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">) -> f32
      %1208 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1207 : (f32) -> f32
      cute.memref.store(%rmem_734, %15, %1208) : (!memref_rmem_f32_1, !cute.coord<"(3,0,5)">, f32) -> ()
      %1209 = cute.memref.load(%rmem_734, %14) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">) -> f32
      %1210 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1209 : (f32) -> f32
      cute.memref.store(%rmem_734, %14, %1210) : (!memref_rmem_f32_1, !cute.coord<"(3,0,6)">, f32) -> ()
      %1211 = cute.memref.load(%rmem_734, %13) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">) -> f32
      %1212 = llvm.inline_asm asm_dialect = att "tanh.approx.f32 $0, $1;", "=f,f" %1211 : (f32) -> f32
      cute.memref.store(%rmem_734, %13, %1212) : (!memref_rmem_f32_1, !cute.coord<"(3,0,7)">, f32) -> ()
      %1213 = cute.memref.load_vec %rmem_734, row_major : !memref_rmem_f32_1
      %1214 = arith.mulf %1148, %1213 : vector<32xf32>
      %1215 = arith.addf %1214, %1148 : vector<32xf32>
      cute.memref.store_vec %1215, %rmem_734, row_major : !memref_rmem_f32_1
      %rmem_913 = cute.memref.alloca() : !memref_rmem_bf16_3
      %iter_914 = cute.get_iter(%rmem_913) : !memref_rmem_bf16_3
      %1216 = cute.memref.load_vec %rmem_734, row_major : !memref_rmem_f32_1
      %1217 = arith.truncf %1216 : vector<32xf32> to vector<32xbf16>
      cute.memref.store_vec %1217, %rmem_913, row_major : !memref_rmem_bf16_3
      cf.br ^bb257(%c0_i32 : i32)
    ^bb257(%1218: i32):  // 2 preds: ^bb256, ^bb258
      %1219 = arith.cmpi slt, %1218, %634 : i32
      cf.cond_br %1219, ^bb258, ^bb259 {llvm.loop_annotation = #loop_annotation}
    ^bb258:  // pred: ^bb257
      %coord_915 = cute.make_coord(%1218) : (i32) -> !cute.coord<"(_,?)">
      %idx_916 = cute.crd2idx(%coord_915, %lay_632) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_917 = cute.add_offset(%ptr_186, %idx_916) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_918 = cute.crd2idx(%coord_915, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_919 = cute.add_offset(%iter_189, %idx_918) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1220 = cute_nvgpu.arch.copy.ldsm %ptr_917{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1221 = vector.extractelement %1220[%70 : i32] : vector<4xi32>
      %1222 = builtin.unrealized_conversion_cast %ptr_919 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1221, %1222 : i32, !llvm.ptr
      %1223 = vector.extractelement %1220[%69 : i32] : vector<4xi32>
      %ptr_920 = cute.add_offset(%ptr_919, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1224 = builtin.unrealized_conversion_cast %ptr_920 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1223, %1224 : i32, !llvm.ptr
      %1225 = vector.extractelement %1220[%68 : i32] : vector<4xi32>
      %ptr_921 = cute.add_offset(%ptr_919, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1226 = builtin.unrealized_conversion_cast %ptr_921 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1225, %1226 : i32, !llvm.ptr
      %1227 = vector.extractelement %1220[%67 : i32] : vector<4xi32>
      %ptr_922 = cute.add_offset(%ptr_919, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1228 = builtin.unrealized_conversion_cast %ptr_922 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1227, %1228 : i32, !llvm.ptr
      %1229 = arith.addi %1218, %c1_i32 : i32
      cf.br ^bb257(%1229 : i32)
    ^bb259:  // pred: ^bb257
      cf.br ^bb260(%c0_i32 : i32)
    ^bb260(%1230: i32):  // 2 preds: ^bb259, ^bb261
      %1231 = arith.cmpi slt, %1230, %634 : i32
      cf.cond_br %1231, ^bb261, ^bb262 {llvm.loop_annotation = #loop_annotation}
    ^bb261:  // pred: ^bb260
      %coord_923 = cute.make_coord(%1230) : (i32) -> !cute.coord<"(_,?)">
      %idx_924 = cute.crd2idx(%coord_923, %lay_632) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_925 = cute.add_offset(%ptr_633, %idx_924) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_926 = cute.crd2idx(%coord_923, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_927 = cute.add_offset(%ptr_634, %idx_926) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1232 = cute_nvgpu.arch.copy.ldsm %ptr_925{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1233 = vector.extractelement %1232[%70 : i32] : vector<4xi32>
      %1234 = builtin.unrealized_conversion_cast %ptr_927 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1233, %1234 : i32, !llvm.ptr
      %1235 = vector.extractelement %1232[%69 : i32] : vector<4xi32>
      %ptr_928 = cute.add_offset(%ptr_927, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1236 = builtin.unrealized_conversion_cast %ptr_928 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1235, %1236 : i32, !llvm.ptr
      %1237 = vector.extractelement %1232[%68 : i32] : vector<4xi32>
      %ptr_929 = cute.add_offset(%ptr_927, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1238 = builtin.unrealized_conversion_cast %ptr_929 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1237, %1238 : i32, !llvm.ptr
      %1239 = vector.extractelement %1232[%67 : i32] : vector<4xi32>
      %ptr_930 = cute.add_offset(%ptr_927, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1240 = builtin.unrealized_conversion_cast %ptr_930 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1239, %1240 : i32, !llvm.ptr
      %1241 = arith.addi %1230, %c1_i32 : i32
      cf.br ^bb260(%1241 : i32)
    ^bb262:  // pred: ^bb260
      %1242 = builtin.unrealized_conversion_cast %iter_914 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1243 = llvm.getelementptr %1242[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1244 = llvm.getelementptr %1242[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1245 = llvm.getelementptr %1242[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb263(%c0_i32 : i32)
    ^bb263(%1246: i32):  // 2 preds: ^bb262, ^bb270
      %1247 = arith.cmpi slt, %1246, %625 : i32
      cf.cond_br %1247, ^bb264, ^bb271 {llvm.loop_annotation = #loop_annotation}
    ^bb264:  // pred: ^bb263
      cf.br ^bb265(%c0_i32 : i32)
    ^bb265(%1248: i32):  // 2 preds: ^bb264, ^bb269
      %1249 = arith.cmpi slt, %1248, %625 : i32
      cf.cond_br %1249, ^bb266, ^bb270 {llvm.loop_annotation = #loop_annotation}
    ^bb266:  // pred: ^bb265
      cf.br ^bb267(%c0_i32 : i32)
    ^bb267(%1250: i32):  // 2 preds: ^bb266, ^bb268
      %1251 = arith.cmpi slt, %1250, %694 : i32
      cf.cond_br %1251, ^bb268, ^bb269 {llvm.loop_annotation = #loop_annotation}
    ^bb268:  // pred: ^bb267
      %coord_931 = cute.make_coord(%1250, %1246) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_932 = cute.make_coord(%1248, %1250) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_933 = cute.crd2idx(%coord_931, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_934 = cute.add_offset(%iter_189, %idx_933) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_935 = cute.crd2idx(%coord_932, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_936 = cute.add_offset(%iter_635, %idx_935) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1252 = llvm.load %1242 : !llvm.ptr -> i32
      %1253 = llvm.load %1243 : !llvm.ptr -> i32
      %1254 = llvm.load %1244 : !llvm.ptr -> i32
      %1255 = llvm.load %1245 : !llvm.ptr -> i32
      %1256 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1257 = llvm.load %1256 : !llvm.ptr -> i32
      %1258 = llvm.getelementptr %1256[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1259 = llvm.load %1258 : !llvm.ptr -> i32
      %1260 = builtin.unrealized_conversion_cast %ptr_936 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1261 = llvm.load %1260 : !llvm.ptr -> f32
      %1262 = llvm.getelementptr %1260[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1263 = llvm.load %1262 : !llvm.ptr -> f32
      %1264 = llvm.getelementptr %1260[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1265 = llvm.load %1264 : !llvm.ptr -> f32
      %1266 = llvm.getelementptr %1260[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1267 = llvm.load %1266 : !llvm.ptr -> f32
      %1268:4 = cute_nvgpu.arch.mma.SM80 A[%1252, %1253, %1254, %1255]  B[%1257, %1259]  C[%1261, %1263, %1265, %1267] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1268#0, %1260 : f32, !llvm.ptr
      llvm.store %1268#1, %1262 : f32, !llvm.ptr
      llvm.store %1268#2, %1264 : f32, !llvm.ptr
      llvm.store %1268#3, %1266 : f32, !llvm.ptr
      %1269 = arith.addi %1250, %c1_i32 : i32
      cf.br ^bb267(%1269 : i32)
    ^bb269:  // pred: ^bb267
      %1270 = arith.addi %1248, %c1_i32 : i32
      cf.br ^bb265(%1270 : i32)
    ^bb270:  // pred: ^bb265
      %1271 = arith.addi %1246, %c1_i32 : i32
      cf.br ^bb263(%1271 : i32)
    ^bb271:  // pred: ^bb263
      cf.br ^bb272(%c0_i32 : i32)
    ^bb272(%1272: i32):  // 2 preds: ^bb271, ^bb273
      %1273 = arith.cmpi slt, %1272, %634 : i32
      cf.cond_br %1273, ^bb273, ^bb274 {llvm.loop_annotation = #loop_annotation}
    ^bb273:  // pred: ^bb272
      %coord_937 = cute.make_coord(%1272) : (i32) -> !cute.coord<"(_,?)">
      %idx_938 = cute.crd2idx(%coord_937, %lay_632) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_939 = cute.add_offset(%ptr_636, %idx_938) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_940 = cute.crd2idx(%coord_937, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_941 = cute.add_offset(%ptr_637, %idx_940) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1274 = cute_nvgpu.arch.copy.ldsm %ptr_939{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1275 = vector.extractelement %1274[%70 : i32] : vector<4xi32>
      %1276 = builtin.unrealized_conversion_cast %ptr_941 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1275, %1276 : i32, !llvm.ptr
      %1277 = vector.extractelement %1274[%69 : i32] : vector<4xi32>
      %ptr_942 = cute.add_offset(%ptr_941, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1278 = builtin.unrealized_conversion_cast %ptr_942 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1277, %1278 : i32, !llvm.ptr
      %1279 = vector.extractelement %1274[%68 : i32] : vector<4xi32>
      %ptr_943 = cute.add_offset(%ptr_941, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1280 = builtin.unrealized_conversion_cast %ptr_943 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1279, %1280 : i32, !llvm.ptr
      %1281 = vector.extractelement %1274[%67 : i32] : vector<4xi32>
      %ptr_944 = cute.add_offset(%ptr_941, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1282 = builtin.unrealized_conversion_cast %ptr_944 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1281, %1282 : i32, !llvm.ptr
      %1283 = arith.addi %1272, %c1_i32 : i32
      cf.br ^bb272(%1283 : i32)
    ^bb274:  // pred: ^bb272
      %ptr_945 = cute.add_offset(%iter_914, %76) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %1284 = builtin.unrealized_conversion_cast %ptr_945 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1285 = llvm.getelementptr %1284[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1286 = llvm.getelementptr %1284[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1287 = llvm.getelementptr %1284[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb275(%c0_i32 : i32)
    ^bb275(%1288: i32):  // 2 preds: ^bb274, ^bb282
      %1289 = arith.cmpi slt, %1288, %625 : i32
      cf.cond_br %1289, ^bb276, ^bb283 {llvm.loop_annotation = #loop_annotation}
    ^bb276:  // pred: ^bb275
      cf.br ^bb277(%c0_i32 : i32)
    ^bb277(%1290: i32):  // 2 preds: ^bb276, ^bb281
      %1291 = arith.cmpi slt, %1290, %625 : i32
      cf.cond_br %1291, ^bb278, ^bb282 {llvm.loop_annotation = #loop_annotation}
    ^bb278:  // pred: ^bb277
      cf.br ^bb279(%c0_i32 : i32)
    ^bb279(%1292: i32):  // 2 preds: ^bb278, ^bb280
      %1293 = arith.cmpi slt, %1292, %694 : i32
      cf.cond_br %1293, ^bb280, ^bb281 {llvm.loop_annotation = #loop_annotation}
    ^bb280:  // pred: ^bb279
      %coord_946 = cute.make_coord(%1292, %1288) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_947 = cute.make_coord(%1290, %1292) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_948 = cute.crd2idx(%coord_946, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_949 = cute.add_offset(%ptr_634, %idx_948) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_950 = cute.crd2idx(%coord_947, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_951 = cute.add_offset(%iter_635, %idx_950) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1294 = llvm.load %1284 : !llvm.ptr -> i32
      %1295 = llvm.load %1285 : !llvm.ptr -> i32
      %1296 = llvm.load %1286 : !llvm.ptr -> i32
      %1297 = llvm.load %1287 : !llvm.ptr -> i32
      %1298 = builtin.unrealized_conversion_cast %ptr_949 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1299 = llvm.load %1298 : !llvm.ptr -> i32
      %1300 = llvm.getelementptr %1298[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1301 = llvm.load %1300 : !llvm.ptr -> i32
      %1302 = builtin.unrealized_conversion_cast %ptr_951 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1303 = llvm.load %1302 : !llvm.ptr -> f32
      %1304 = llvm.getelementptr %1302[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1305 = llvm.load %1304 : !llvm.ptr -> f32
      %1306 = llvm.getelementptr %1302[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1307 = llvm.load %1306 : !llvm.ptr -> f32
      %1308 = llvm.getelementptr %1302[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1309 = llvm.load %1308 : !llvm.ptr -> f32
      %1310:4 = cute_nvgpu.arch.mma.SM80 A[%1294, %1295, %1296, %1297]  B[%1299, %1301]  C[%1303, %1305, %1307, %1309] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1310#0, %1302 : f32, !llvm.ptr
      llvm.store %1310#1, %1304 : f32, !llvm.ptr
      llvm.store %1310#2, %1306 : f32, !llvm.ptr
      llvm.store %1310#3, %1308 : f32, !llvm.ptr
      %1311 = arith.addi %1292, %c1_i32 : i32
      cf.br ^bb279(%1311 : i32)
    ^bb281:  // pred: ^bb279
      %1312 = arith.addi %1290, %c1_i32 : i32
      cf.br ^bb277(%1312 : i32)
    ^bb282:  // pred: ^bb277
      %1313 = arith.addi %1288, %c1_i32 : i32
      cf.br ^bb275(%1313 : i32)
    ^bb283:  // pred: ^bb275
      cf.br ^bb284(%c0_i32 : i32)
    ^bb284(%1314: i32):  // 2 preds: ^bb283, ^bb285
      %1315 = arith.cmpi slt, %1314, %634 : i32
      cf.cond_br %1315, ^bb285, ^bb286 {llvm.loop_annotation = #loop_annotation}
    ^bb285:  // pred: ^bb284
      %coord_952 = cute.make_coord(%1314) : (i32) -> !cute.coord<"(_,?)">
      %idx_953 = cute.crd2idx(%coord_952, %lay_632) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((((2,2),2)))):((1,0),((((?{div=16},?{div=32}),4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_954 = cute.add_offset(%ptr_638, %idx_953) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_955 = cute.crd2idx(%coord_952, %9) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),(((4,2)))):((1,0),(((8,128))))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_956 = cute.add_offset(%ptr_639, %idx_955) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<8>>
      %1316 = cute_nvgpu.arch.copy.ldsm %ptr_954{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <bf16, smem, align<16>> -> vector<4xi32>
      %1317 = vector.extractelement %1316[%70 : i32] : vector<4xi32>
      %1318 = builtin.unrealized_conversion_cast %ptr_956 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1317, %1318 : i32, !llvm.ptr
      %1319 = vector.extractelement %1316[%69 : i32] : vector<4xi32>
      %ptr_957 = cute.add_offset(%ptr_956, %91) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %1320 = builtin.unrealized_conversion_cast %ptr_957 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1319, %1320 : i32, !llvm.ptr
      %1321 = vector.extractelement %1316[%68 : i32] : vector<4xi32>
      %ptr_958 = cute.add_offset(%ptr_956, %71) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %1322 = builtin.unrealized_conversion_cast %ptr_958 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      llvm.store %1321, %1322 : i32, !llvm.ptr
      %1323 = vector.extractelement %1316[%67 : i32] : vector<4xi32>
      %ptr_959 = cute.add_offset(%ptr_956, %66) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %1324 = builtin.unrealized_conversion_cast %ptr_959 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      llvm.store %1323, %1324 : i32, !llvm.ptr
      %1325 = arith.addi %1314, %c1_i32 : i32
      cf.br ^bb284(%1325 : i32)
    ^bb286:  // pred: ^bb284
      %ptr_960 = cute.add_offset(%iter_914, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %1326 = builtin.unrealized_conversion_cast %ptr_960 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1327 = llvm.getelementptr %1326[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1328 = llvm.getelementptr %1326[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1329 = llvm.getelementptr %1326[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb287(%c0_i32 : i32)
    ^bb287(%1330: i32):  // 2 preds: ^bb286, ^bb294
      %1331 = arith.cmpi slt, %1330, %625 : i32
      cf.cond_br %1331, ^bb288, ^bb295 {llvm.loop_annotation = #loop_annotation}
    ^bb288:  // pred: ^bb287
      cf.br ^bb289(%c0_i32 : i32)
    ^bb289(%1332: i32):  // 2 preds: ^bb288, ^bb293
      %1333 = arith.cmpi slt, %1332, %625 : i32
      cf.cond_br %1333, ^bb290, ^bb294 {llvm.loop_annotation = #loop_annotation}
    ^bb290:  // pred: ^bb289
      cf.br ^bb291(%c0_i32 : i32)
    ^bb291(%1334: i32):  // 2 preds: ^bb290, ^bb292
      %1335 = arith.cmpi slt, %1334, %694 : i32
      cf.cond_br %1335, ^bb292, ^bb293 {llvm.loop_annotation = #loop_annotation}
    ^bb292:  // pred: ^bb291
      %coord_961 = cute.make_coord(%1334, %1330) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_962 = cute.make_coord(%1332, %1334) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_963 = cute.crd2idx(%coord_961, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_964 = cute.add_offset(%ptr_637, %idx_963) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_965 = cute.crd2idx(%coord_962, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_966 = cute.add_offset(%iter_635, %idx_965) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1336 = llvm.load %1326 : !llvm.ptr -> i32
      %1337 = llvm.load %1327 : !llvm.ptr -> i32
      %1338 = llvm.load %1328 : !llvm.ptr -> i32
      %1339 = llvm.load %1329 : !llvm.ptr -> i32
      %1340 = builtin.unrealized_conversion_cast %ptr_964 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1341 = llvm.load %1340 : !llvm.ptr -> i32
      %1342 = llvm.getelementptr %1340[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1343 = llvm.load %1342 : !llvm.ptr -> i32
      %1344 = builtin.unrealized_conversion_cast %ptr_966 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1345 = llvm.load %1344 : !llvm.ptr -> f32
      %1346 = llvm.getelementptr %1344[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1347 = llvm.load %1346 : !llvm.ptr -> f32
      %1348 = llvm.getelementptr %1344[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1349 = llvm.load %1348 : !llvm.ptr -> f32
      %1350 = llvm.getelementptr %1344[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1351 = llvm.load %1350 : !llvm.ptr -> f32
      %1352:4 = cute_nvgpu.arch.mma.SM80 A[%1336, %1337, %1338, %1339]  B[%1341, %1343]  C[%1345, %1347, %1349, %1351] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1352#0, %1344 : f32, !llvm.ptr
      llvm.store %1352#1, %1346 : f32, !llvm.ptr
      llvm.store %1352#2, %1348 : f32, !llvm.ptr
      llvm.store %1352#3, %1350 : f32, !llvm.ptr
      %1353 = arith.addi %1334, %c1_i32 : i32
      cf.br ^bb291(%1353 : i32)
    ^bb293:  // pred: ^bb291
      %1354 = arith.addi %1332, %c1_i32 : i32
      cf.br ^bb289(%1354 : i32)
    ^bb294:  // pred: ^bb289
      %1355 = arith.addi %1330, %c1_i32 : i32
      cf.br ^bb287(%1355 : i32)
    ^bb295:  // pred: ^bb287
      %ptr_967 = cute.add_offset(%iter_914, %50) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %1356 = builtin.unrealized_conversion_cast %ptr_967 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1357 = llvm.getelementptr %1356[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1358 = llvm.getelementptr %1356[2] : (!llvm.ptr) -> !llvm.ptr, i32
      %1359 = llvm.getelementptr %1356[3] : (!llvm.ptr) -> !llvm.ptr, i32
      cf.br ^bb296(%c0_i32 : i32)
    ^bb296(%1360: i32):  // 2 preds: ^bb295, ^bb303
      %1361 = arith.cmpi slt, %1360, %625 : i32
      cf.cond_br %1361, ^bb297, ^bb304 {llvm.loop_annotation = #loop_annotation}
    ^bb297:  // pred: ^bb296
      cf.br ^bb298(%c0_i32 : i32)
    ^bb298(%1362: i32):  // 2 preds: ^bb297, ^bb302
      %1363 = arith.cmpi slt, %1362, %625 : i32
      cf.cond_br %1363, ^bb299, ^bb303 {llvm.loop_annotation = #loop_annotation}
    ^bb299:  // pred: ^bb298
      cf.br ^bb300(%c0_i32 : i32)
    ^bb300(%1364: i32):  // 2 preds: ^bb299, ^bb301
      %1365 = arith.cmpi slt, %1364, %694 : i32
      cf.cond_br %1365, ^bb301, ^bb302 {llvm.loop_annotation = #loop_annotation}
    ^bb301:  // pred: ^bb300
      %coord_968 = cute.make_coord(%1364, %1360) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_969 = cute.make_coord(%1362, %1364) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_970 = cute.crd2idx(%coord_968, %8) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),(8,2),1):((1,2),(4,128),0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_971 = cute.add_offset(%ptr_639, %idx_970) : (!cute.ptr<bf16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<bf16, rmem, align<8>>
      %idx_972 = cute.crd2idx(%coord_969, %110) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),1,16):((1,2),0,4)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_973 = cute.add_offset(%iter_635, %idx_972) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %1366 = llvm.load %1356 : !llvm.ptr -> i32
      %1367 = llvm.load %1357 : !llvm.ptr -> i32
      %1368 = llvm.load %1358 : !llvm.ptr -> i32
      %1369 = llvm.load %1359 : !llvm.ptr -> i32
      %1370 = builtin.unrealized_conversion_cast %ptr_971 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1371 = llvm.load %1370 : !llvm.ptr -> i32
      %1372 = llvm.getelementptr %1370[1] : (!llvm.ptr) -> !llvm.ptr, i32
      %1373 = llvm.load %1372 : !llvm.ptr -> i32
      %1374 = builtin.unrealized_conversion_cast %ptr_973 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %1375 = llvm.load %1374 : !llvm.ptr -> f32
      %1376 = llvm.getelementptr %1374[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %1377 = llvm.load %1376 : !llvm.ptr -> f32
      %1378 = llvm.getelementptr %1374[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %1379 = llvm.load %1378 : !llvm.ptr -> f32
      %1380 = llvm.getelementptr %1374[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %1381 = llvm.load %1380 : !llvm.ptr -> f32
      %1382:4 = cute_nvgpu.arch.mma.SM80 A[%1366, %1367, %1368, %1369]  B[%1371, %1373]  C[%1375, %1377, %1379, %1381] < {a_type = bf16, b_type = bf16, shape_MNK = #cute.shape<"(16,8,16)">}> : (i32, i32, f32) -> (f32, f32, f32, f32)
      llvm.store %1382#0, %1374 : f32, !llvm.ptr
      llvm.store %1382#1, %1376 : f32, !llvm.ptr
      llvm.store %1382#2, %1378 : f32, !llvm.ptr
      llvm.store %1382#3, %1380 : f32, !llvm.ptr
      %1383 = arith.addi %1364, %c1_i32 : i32
      cf.br ^bb300(%1383 : i32)
    ^bb302:  // pred: ^bb300
      %1384 = arith.addi %1362, %c1_i32 : i32
      cf.br ^bb298(%1384 : i32)
    ^bb303:  // pred: ^bb298
      %1385 = arith.addi %1360, %c1_i32 : i32
      cf.br ^bb296(%1385 : i32)
    ^bb304:  // pred: ^bb296
      %1386 = arith.addi %695, %c1_i32 : i32
      cf.br ^bb73(%1386 : i32)
    ^bb305:  // pred: ^bb73
      %rmem_974 = cute.memref.alloca() : !memref_rmem_bf16_4
      %1387 = cute.memref.load_vec %rmem_166, row_major : !memref_rmem_f32_
      %1388 = arith.truncf %1387 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %1388, %rmem_974, row_major : !memref_rmem_bf16_4
      %iter_975 = cute.recast_iter(%iter_124) : !cute.ptr<bf16, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>, S<3,4,3>>
      %atom_976 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16>
      %1389 = cute.make_tiled_copy(%atom_976) : !copy_simt
      %iter_977 = cute.get_iter(%rmem_974) : !memref_rmem_bf16_4
      %1390 = arith.divsi %306, %c4_i32 : i32
      %1391 = arith.remsi %306, %c4_i32 : i32
      %1392 = arith.muli %1391, %c2_i32 : i32
      %1393 = arith.divsi %1390, %c8_i32 : i32
      %1394 = arith.remsi %1390, %c8_i32 : i32
      %1395 = arith.muli %1394, %c64_i32 : i32
      %1396 = arith.addi %1392, %1395 : i32
      %1397 = arith.muli %1393, %c1024_i32 : i32
      %1398 = arith.addi %1396, %1397 : i32
      %iv_978 = cute.assume(%1398) : (i32) -> !cute.i32<divby 2>
      %int_tuple_979 = cute.make_int_tuple(%iv_978) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_980 = cute.add_offset(%iter_975, %int_tuple_979) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1399 = cute.get_scalars(%76) : !cute.int_tuple<"8">
      cf.br ^bb306(%c0_i32 : i32)
    ^bb306(%1400: i32):  // 2 preds: ^bb305, ^bb307
      %1401 = arith.cmpi slt, %1400, %1399 : i32
      cf.cond_br %1401, ^bb307, ^bb308 {llvm.loop_annotation = #loop_annotation}
    ^bb307:  // pred: ^bb306
      %coord_981 = cute.make_coord(%1400) : (i32) -> !cute.coord<"(_,?)">
      %idx_982 = cute.crd2idx(%coord_981, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,8),((1,8))):((0,1),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_983 = cute.add_offset(%iter_977, %idx_982) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_984 = cute.crd2idx(%coord_981, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(2,2,2)),((1,(4,2)))):((0,(1,512,8)),((0,(16,4096))))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_985 = cute.add_offset(%ptr_980, %idx_984) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled = cute.apply_swizzle(%ptr_985) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1402 = builtin.unrealized_conversion_cast %ptr_983 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1403 = builtin.unrealized_conversion_cast %swizzled : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1404 = llvm.load %1402 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1404, %1403 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_986 = cute.add_offset(%ptr_983, %91) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_987 = cute.add_offset(%ptr_985, %4) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_988 = cute.apply_swizzle(%ptr_987) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1405 = builtin.unrealized_conversion_cast %ptr_986 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %1406 = builtin.unrealized_conversion_cast %swizzled_988 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1407 = llvm.load %1405 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1407, %1406 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_989 = cute.add_offset(%ptr_983, %71) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<bf16, rmem, align<8>>
      %ptr_990 = cute.add_offset(%ptr_985, %76) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_991 = cute.apply_swizzle(%ptr_990) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1408 = builtin.unrealized_conversion_cast %ptr_989 : !cute.ptr<bf16, rmem, align<8>> to !llvm.ptr
      %1409 = builtin.unrealized_conversion_cast %swizzled_991 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1410 = llvm.load %1408 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1410, %1409 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %ptr_992 = cute.add_offset(%ptr_983, %66) : (!cute.ptr<bf16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<bf16, rmem, align<4>>
      %ptr_993 = cute.add_offset(%ptr_985, %3) : (!cute.ptr<bf16, smem, align<4>, S<3,4,3>>, !cute.int_tuple<"520">) -> !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %swizzled_994 = cute.apply_swizzle(%ptr_993) : !cute.ptr<bf16, smem, align<4>, S<3,4,3>>
      %1411 = builtin.unrealized_conversion_cast %ptr_992 : !cute.ptr<bf16, rmem, align<4>> to !llvm.ptr
      %1412 = builtin.unrealized_conversion_cast %swizzled_994 : !cute.ptr<bf16, smem, align<4>, S<3,4,3>> to !llvm.ptr<3>
      %1413 = llvm.load %1411 {alignment = 4 : i64} : !llvm.ptr -> vector<2xbf16>
      llvm.store %1413, %1412 {alignment = 4 : i64} : vector<2xbf16>, !llvm.ptr<3>
      %1414 = arith.addi %1400, %c1_i32 : i32
      cf.br ^bb306(%1414 : i32)
    ^bb308:  // pred: ^bb306
      %lay_995 = cute.get_layout(%arg3) : !memref_gmem_bf16_
      %1415:7 = cute.get_scalars(%lay_995) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">
      %iv_996 = cute.assume(%1415#3) : (i32) -> !cute.i32<divby 8>
      %shape_997 = cute.make_shape(%1415#1, %iv_996) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %iv_998 = cute.assume(%1415#5) : (i64) -> !cute.i64<divby 8>
      %stride_999 = cute.make_stride(%iv_998) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1000 = cute.make_layout(%shape_997, %stride_999) : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %idx_1001 = cute.crd2idx(%coord, %lay_995) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_1002 = cute.get_iter(%arg3) : !memref_gmem_bf16_
      %ptr_1003 = cute.add_offset(%iter_1002, %idx_1001) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1416:3 = cute.get_scalars(%lay_1000) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(?{i64 div=8},1)">
      %c1_i32_1004 = arith.constant 1 : i32
      %c0_i32_1005 = arith.constant 0 : i32
      %c-1_i32_1006 = arith.constant -1 : i32
      %1417 = arith.cmpi sgt, %c64_i32, %c0_i32_1005 : i32
      %1418 = arith.select %1417, %c-1_i32_1006, %c1_i32_1004 : i32
      %1419 = arith.addi %1418, %1416#0 : i32
      %1420 = arith.divsi %1419, %c64_i32 : i32
      %1421 = arith.addi %c1_i32_1004, %1420 : i32
      %1422 = arith.subi %c0_i32_1005, %1416#0 : i32
      %1423 = arith.divsi %1422, %c64_i32 : i32
      %1424 = arith.subi %c0_i32_1005, %1423 : i32
      %1425 = arith.cmpi slt, %1416#0, %c0_i32_1005 : i32
      %1426 = arith.cmpi sgt, %1416#0, %c0_i32_1005 : i32
      %1427 = arith.cmpi slt, %c64_i32, %c0_i32_1005 : i32
      %1428 = arith.cmpi sgt, %c64_i32, %c0_i32_1005 : i32
      %1429 = arith.andi %1425, %1427 : i1
      %1430 = arith.andi %1426, %1428 : i1
      %1431 = arith.ori %1429, %1430 : i1
      %1432 = arith.select %1431, %1421, %1424 : i32
      %1433 = arith.muli %1416#2, %c64_i64 : i64
      %c1_i32_1007 = arith.constant 1 : i32
      %c0_i32_1008 = arith.constant 0 : i32
      %c-1_i32_1009 = arith.constant -1 : i32
      %1434 = arith.cmpi sgt, %c128_i32, %c0_i32_1008 : i32
      %1435 = arith.select %1434, %c-1_i32_1009, %c1_i32_1007 : i32
      %1436 = arith.addi %1435, %1416#1 : i32
      %1437 = arith.divsi %1436, %c128_i32 : i32
      %1438 = arith.addi %c1_i32_1007, %1437 : i32
      %1439 = arith.subi %c0_i32_1008, %1416#1 : i32
      %1440 = arith.divsi %1439, %c128_i32 : i32
      %1441 = arith.subi %c0_i32_1008, %1440 : i32
      %1442 = arith.cmpi slt, %1416#1, %c0_i32_1008 : i32
      %1443 = arith.cmpi sgt, %1416#1, %c0_i32_1008 : i32
      %1444 = arith.cmpi slt, %c128_i32, %c0_i32_1008 : i32
      %1445 = arith.cmpi sgt, %c128_i32, %c0_i32_1008 : i32
      %1446 = arith.andi %1442, %1444 : i1
      %1447 = arith.andi %1443, %1445 : i1
      %1448 = arith.ori %1446, %1447 : i1
      %1449 = arith.select %1448, %1438, %1441 : i32
      %shape_1010 = cute.make_shape(%1432, %1449) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %iv_1011 = cute.assume(%1416#2) : (i64) -> !cute.i64<divby 8>
      %iv_1012 = cute.assume(%1433) : (i64) -> !cute.i64<divby 512>
      %stride_1013 = cute.make_stride(%iv_1011, %iv_1012) : (!cute.i64<divby 8>, !cute.i64<divby 512>) -> !cute.stride<"((?{i64 div=8},1),(?{i64 div=512},128))">
      %lay_1014 = cute.make_layout(%shape_1010, %stride_1013) : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %1450:4 = cute.get_scalars(%lay_1014) <{only_dynamic}> : !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">
      %iv_1015 = cute.assume(%1450#2) : (i64) -> !cute.i64<divby 8>
      %stride_1016 = cute.make_stride(%iv_1015) : (!cute.i64<divby 8>) -> !cute.stride<"(?{i64 div=8},1)">
      %lay_1017 = cute.make_layout(%115, %stride_1016) : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %idx_1018 = cute.crd2idx(%coord_26, %lay_1014) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((?{i64 div=8},1),(?{i64 div=512},128))">) -> !cute.int_tuple<"?{i64 div=512}">
      %ptr_1019 = cute.add_offset(%ptr_1003, %idx_1018) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=512}">) -> !cute.ptr<bf16, gmem, align<16>>
      %1451 = arith.addi %310, %317 : i32
      %iv_1020 = cute.assume(%1451) : (i32) -> !cute.i32<divby 8>
      %int_tuple_1021 = cute.make_int_tuple(%iv_1020) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_1022 = cute.add_offset(%iter_975, %int_tuple_1021) : (!cute.ptr<bf16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1452 = cute.get_scalars(%lay_1017) <{only_dynamic}> : !cute.layout<"(64,128):(?{i64 div=8},1)">
      %1453 = arith.muli %1452, %c16_i64 : i64
      %1454 = arith.muli %311, %1452 : i64
      %1455 = arith.addi %313, %1454 : i64
      %iv_1023 = cute.assume(%1455) : (i64) -> !cute.i64<divby 8>
      %int_tuple_1024 = cute.make_int_tuple(%iv_1023) : (!cute.i64<divby 8>) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_1025 = cute.add_offset(%ptr_1019, %int_tuple_1024) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_1026 = cute.assume(%1453) : (i64) -> !cute.i64<divby 128>
      %stride_1027 = cute.make_stride(%iv_1026) : (!cute.i64<divby 128>) -> !cute.stride<"((1,0),?{i64 div=128},64)">
      %lay_1028 = cute.make_layout(%111, %stride_1027) : !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">
      %rmem_1029 = cute.memref.alloca() : !memref_rmem_bf16_5
      %iter_1030 = cute.get_iter(%rmem_1029) : !memref_rmem_bf16_5
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %swizzled_1031 = cute.apply_swizzle(%ptr_1022) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      cf.br ^bb309(%c0_i32 : i32)
    ^bb309(%1456: i32):  // 2 preds: ^bb308, ^bb310
      %1457 = arith.cmpi slt, %1456, %1399 : i32
      cf.cond_br %1457, ^bb310, ^bb311 {llvm.loop_annotation = #loop_annotation}
    ^bb310:  // pred: ^bb309
      %coord_1032 = cute.make_coord(%1456) : (i32) -> !cute.coord<"(_,?)">
      %idx_1033 = cute.crd2idx(%coord_1032, %78) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((1024,4096)))">) -> !cute.int_tuple<"?{div=1024}">
      %idx_1034 = cute.crd2idx(%coord_1032, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,2))):((1,0),((16,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1035 = cute.add_offset(%iter_1030, %idx_1034) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_1036 = cute.add_offset(%swizzled_1031, %idx_1033) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1458 = builtin.unrealized_conversion_cast %ptr_1036 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1459 = builtin.unrealized_conversion_cast %ptr_1035 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1460 = llvm.load %1458 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %1460, %1459 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %1461 = arith.addi %1456, %c1_i32 : i32
      cf.br ^bb309(%1461 : i32)
    ^bb311:  // pred: ^bb309
      %1462 = cute.get_shape(%lay_995) : (!cute.layout<"(?,?,?,?{div=8}):(?{i64 div=8},?{i64 div=8},?{i64 div=8},1)">) -> !cute.shape<"(?,?,?,?{div=8})">
      %e0_1037, %e1_1038, %e2_1039, %e3_1040 = cute.get_leaves(%1462) : !cute.shape<"(?,?,?,?{div=8})">
      %itup_1041 = cute.to_int_tuple(%e0_1037) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1042 = cute.to_int_tuple(%e1_1038) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1043 = cute.to_int_tuple(%e2_1039) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_1044 = cute.to_int_tuple(%e3_1040) : !cute.shape<"?{div=8}"> to !cute.int_tuple<"?{div=8}">
      %shape_1045 = cute.make_shape(%itup_1041, %itup_1042, %itup_1043, %itup_1044) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.shape<"(?,?,?,?{div=8})">
      %lay_1046 = cute.make_layout(%shape_1045, %104) : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %1463:4 = cute.get_scalars(%lay_1046) <{only_dynamic}> : !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">
      %iv_1047 = cute.assume(%1463#3) : (i32) -> !cute.i32<divby 8>
      %shape_1048 = cute.make_shape(%1463#1, %iv_1047) : (i32, !cute.i32<divby 8>) -> !cute.shape<"(?,?{div=8})">
      %lay_1049 = cute.make_layout(%shape_1048, %103) : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %idx_1050 = cute.crd2idx(%coord, %lay_1046) : (!cute.coord<"(?,_,?,_)">, !cute.layout<"(?,?,?,?{div=8}):(1@0,1@1,1@2,1@3)">) -> !cute.int_tuple<"(?,0,?,0)">
      %tup_1051 = cute.add_offset(%105, %idx_1050) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?,0,?,0)">) -> !cute.int_tuple<"(?,0,?,0)">
      %1464:2 = cute.get_scalars(%lay_1049) <{only_dynamic}> : !cute.layout<"(?,?{div=8}):(1@1,1@3)">
      %c1_i32_1052 = arith.constant 1 : i32
      %c0_i32_1053 = arith.constant 0 : i32
      %c-1_i32_1054 = arith.constant -1 : i32
      %1465 = arith.cmpi sgt, %c64_i32, %c0_i32_1053 : i32
      %1466 = arith.select %1465, %c-1_i32_1054, %c1_i32_1052 : i32
      %1467 = arith.addi %1466, %1464#0 : i32
      %1468 = arith.divsi %1467, %c64_i32 : i32
      %1469 = arith.addi %c1_i32_1052, %1468 : i32
      %1470 = arith.subi %c0_i32_1053, %1464#0 : i32
      %1471 = arith.divsi %1470, %c64_i32 : i32
      %1472 = arith.subi %c0_i32_1053, %1471 : i32
      %1473 = arith.cmpi slt, %1464#0, %c0_i32_1053 : i32
      %1474 = arith.cmpi sgt, %1464#0, %c0_i32_1053 : i32
      %1475 = arith.cmpi slt, %c64_i32, %c0_i32_1053 : i32
      %1476 = arith.cmpi sgt, %c64_i32, %c0_i32_1053 : i32
      %1477 = arith.andi %1473, %1475 : i1
      %1478 = arith.andi %1474, %1476 : i1
      %1479 = arith.ori %1477, %1478 : i1
      %1480 = arith.select %1479, %1469, %1472 : i32
      %c1_i32_1055 = arith.constant 1 : i32
      %c0_i32_1056 = arith.constant 0 : i32
      %c-1_i32_1057 = arith.constant -1 : i32
      %1481 = arith.cmpi sgt, %c128_i32, %c0_i32_1056 : i32
      %1482 = arith.select %1481, %c-1_i32_1057, %c1_i32_1055 : i32
      %1483 = arith.addi %1482, %1464#1 : i32
      %1484 = arith.divsi %1483, %c128_i32 : i32
      %1485 = arith.addi %c1_i32_1055, %1484 : i32
      %1486 = arith.subi %c0_i32_1056, %1464#1 : i32
      %1487 = arith.divsi %1486, %c128_i32 : i32
      %1488 = arith.subi %c0_i32_1056, %1487 : i32
      %1489 = arith.cmpi slt, %1464#1, %c0_i32_1056 : i32
      %1490 = arith.cmpi sgt, %1464#1, %c0_i32_1056 : i32
      %1491 = arith.cmpi slt, %c128_i32, %c0_i32_1056 : i32
      %1492 = arith.cmpi sgt, %c128_i32, %c0_i32_1056 : i32
      %1493 = arith.andi %1489, %1491 : i1
      %1494 = arith.andi %1490, %1492 : i1
      %1495 = arith.ori %1493, %1494 : i1
      %1496 = arith.select %1495, %1485, %1488 : i32
      %shape_1058 = cute.make_shape(%1480, %1496) : (i32, i32) -> !cute.shape<"((64,128),(?,?))">
      %lay_1059 = cute.make_layout(%shape_1058, %102) : !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">
      %idx_1060 = cute.crd2idx(%coord_26, %lay_1059) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((64,128),(?,?)):((1@1,1@3),(64@1,128@3))">) -> !cute.int_tuple<"(0,?{div=64},0,0)">
      %tup_1061 = cute.add_offset(%tup_1051, %idx_1060) : (!cute.int_tuple<"(?,0,?,0)">, !cute.int_tuple<"(0,?{div=64},0,0)">) -> !cute.int_tuple<"(?,?{div=64},?,0)">
      %tup_1062 = cute.add_offset(%tup_1061, %int_tuple_262) : (!cute.int_tuple<"(?,?{div=64},?,0)">, !cute.int_tuple<"(0,?,0,?{div=8})">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %rmem_1063 = cute.memref.alloca() : !memref_rmem_i8_
      %e0_1064, %e1_1065, %e2_1066, %e3_1067 = cute.get_leaves(%tup_1062) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1068 = cute.make_coord(%e3_1067) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_1069 = cute.make_coord(%itup_1044) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1497 = cute.get_scalars(%coord_1068) : !cute.coord<"?{div=8}">
      %1498 = cute.get_scalars(%coord_1069) : !cute.coord<"?{div=8}">
      %1499 = arith.cmpi slt, %1497, %1498 : i32
      %1500 = arith.extui %1499 : i1 to i8
      cute.memref.store(%rmem_1063, %97, %1500) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_1070 = cute.add_offset(%tup_1062, %96) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,0,0,64)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1071, %e1_1072, %e2_1073, %e3_1074 = cute.get_leaves(%tup_1070) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1075 = cute.make_coord(%e3_1074) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %1501 = cute.get_scalars(%coord_1075) : !cute.coord<"?{div=8}">
      %1502 = arith.cmpi slt, %1501, %1498 : i32
      %1503 = arith.extui %1502 : i1 to i8
      cute.memref.store(%rmem_1063, %95, %1503) : (!memref_rmem_i8_, !cute.coord<"(0,0,1)">, i8) -> ()
      %coord_1076 = cute.make_coord(%e1_1065) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %coord_1077 = cute.make_coord(%itup_1042) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1504 = cute.get_scalars(%coord_1076) : !cute.coord<"?">
      %1505 = cute.get_scalars(%coord_1077) : !cute.coord<"?">
      %1506 = arith.cmpi slt, %1504, %1505 : i32
      cf.cond_br %1506, ^bb312, ^bb318
    ^bb312:  // pred: ^bb311
      %iter_1078 = cute.get_iter(%rmem_1063) : !memref_rmem_i8_
      %1507 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb313(%c0_i32 : i32)
    ^bb313(%1508: i32):  // 2 preds: ^bb312, ^bb316
      %1509 = arith.cmpi slt, %1508, %1507 : i32
      cf.cond_br %1509, ^bb314, ^bb317 {llvm.loop_annotation = #loop_annotation}
    ^bb314:  // pred: ^bb313
      %coord_1079 = cute.make_coord(%1508) : (i32) -> !cute.coord<"(_,?)">
      %idx_1080 = cute.crd2idx(%coord_1079, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1081 = cute.add_offset(%iter_1030, %idx_1080) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1082 = cute.crd2idx(%coord_1079, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1083 = cute.add_offset(%ptr_1025, %idx_1082) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1084 = cute.crd2idx(%coord_1079, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1085 = cute.add_offset(%iter_1078, %idx_1084) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1510 = builtin.unrealized_conversion_cast %ptr_1085 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1511 = llvm.load %1510 : !llvm.ptr -> i8
      %1512 = llvm.icmp "ne" %1511, %0 : i8
      cf.cond_br %1512, ^bb315, ^bb316
    ^bb315:  // pred: ^bb314
      %1513 = builtin.unrealized_conversion_cast %ptr_1081 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1514 = builtin.unrealized_conversion_cast %ptr_1083 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1515 = llvm.load %1513 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1515, %1514 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb316
    ^bb316:  // 2 preds: ^bb314, ^bb315
      %1516 = arith.addi %1508, %c1_i32 : i32
      cf.br ^bb313(%1516 : i32)
    ^bb317:  // pred: ^bb313
      cf.br ^bb318
    ^bb318:  // 2 preds: ^bb311, ^bb317
      %tup_1086 = cute.add_offset(%tup_1062, %90) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,16,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1087, %e1_1088, %e2_1089, %e3_1090 = cute.get_leaves(%tup_1086) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1091 = cute.make_coord(%e1_1088) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1517 = cute.get_scalars(%coord_1091) : !cute.coord<"?">
      %1518 = arith.cmpi slt, %1517, %1505 : i32
      cf.cond_br %1518, ^bb319, ^bb325
    ^bb319:  // pred: ^bb318
      %ptr_1092 = cute.add_offset(%iter_1030, %60) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1093 = cute.crd2idx(%89, %lay_1028) : (!cute.coord<"(_,1,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=128}">
      %ptr_1094 = cute.add_offset(%ptr_1025, %idx_1093) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=128}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1095 = cute.get_iter(%rmem_1063) : !memref_rmem_i8_
      %1519 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb320(%c0_i32 : i32)
    ^bb320(%1520: i32):  // 2 preds: ^bb319, ^bb323
      %1521 = arith.cmpi slt, %1520, %1519 : i32
      cf.cond_br %1521, ^bb321, ^bb324 {llvm.loop_annotation = #loop_annotation}
    ^bb321:  // pred: ^bb320
      %coord_1096 = cute.make_coord(%1520) : (i32) -> !cute.coord<"(_,?)">
      %idx_1097 = cute.crd2idx(%coord_1096, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1098 = cute.add_offset(%ptr_1092, %idx_1097) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1099 = cute.crd2idx(%coord_1096, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1100 = cute.add_offset(%ptr_1094, %idx_1099) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1101 = cute.crd2idx(%coord_1096, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1102 = cute.add_offset(%iter_1095, %idx_1101) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1522 = builtin.unrealized_conversion_cast %ptr_1102 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1523 = llvm.load %1522 : !llvm.ptr -> i8
      %1524 = llvm.icmp "ne" %1523, %0 : i8
      cf.cond_br %1524, ^bb322, ^bb323
    ^bb322:  // pred: ^bb321
      %1525 = builtin.unrealized_conversion_cast %ptr_1098 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1526 = builtin.unrealized_conversion_cast %ptr_1100 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1527 = llvm.load %1525 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1527, %1526 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb323
    ^bb323:  // 2 preds: ^bb321, ^bb322
      %1528 = arith.addi %1520, %c1_i32 : i32
      cf.br ^bb320(%1528 : i32)
    ^bb324:  // pred: ^bb320
      cf.br ^bb325
    ^bb325:  // 2 preds: ^bb318, ^bb324
      %tup_1103 = cute.add_offset(%tup_1062, %87) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,32,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1104, %e1_1105, %e2_1106, %e3_1107 = cute.get_leaves(%tup_1103) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1108 = cute.make_coord(%e1_1105) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1529 = cute.get_scalars(%coord_1108) : !cute.coord<"?">
      %1530 = arith.cmpi slt, %1529, %1505 : i32
      cf.cond_br %1530, ^bb326, ^bb332
    ^bb326:  // pred: ^bb325
      %ptr_1109 = cute.add_offset(%iter_1030, %63) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1110 = cute.crd2idx(%86, %lay_1028) : (!cute.coord<"(_,2,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=256}">
      %ptr_1111 = cute.add_offset(%ptr_1025, %idx_1110) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1112 = cute.get_iter(%rmem_1063) : !memref_rmem_i8_
      %1531 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb327(%c0_i32 : i32)
    ^bb327(%1532: i32):  // 2 preds: ^bb326, ^bb330
      %1533 = arith.cmpi slt, %1532, %1531 : i32
      cf.cond_br %1533, ^bb328, ^bb331 {llvm.loop_annotation = #loop_annotation}
    ^bb328:  // pred: ^bb327
      %coord_1113 = cute.make_coord(%1532) : (i32) -> !cute.coord<"(_,?)">
      %idx_1114 = cute.crd2idx(%coord_1113, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1115 = cute.add_offset(%ptr_1109, %idx_1114) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1116 = cute.crd2idx(%coord_1113, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1117 = cute.add_offset(%ptr_1111, %idx_1116) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1118 = cute.crd2idx(%coord_1113, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1119 = cute.add_offset(%iter_1112, %idx_1118) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1534 = builtin.unrealized_conversion_cast %ptr_1119 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1535 = llvm.load %1534 : !llvm.ptr -> i8
      %1536 = llvm.icmp "ne" %1535, %0 : i8
      cf.cond_br %1536, ^bb329, ^bb330
    ^bb329:  // pred: ^bb328
      %1537 = builtin.unrealized_conversion_cast %ptr_1115 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1538 = builtin.unrealized_conversion_cast %ptr_1117 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1539 = llvm.load %1537 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1539, %1538 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb330
    ^bb330:  // 2 preds: ^bb328, ^bb329
      %1540 = arith.addi %1532, %c1_i32 : i32
      cf.br ^bb327(%1540 : i32)
    ^bb331:  // pred: ^bb327
      cf.br ^bb332
    ^bb332:  // 2 preds: ^bb325, ^bb331
      %tup_1120 = cute.add_offset(%tup_1062, %84) : (!cute.int_tuple<"(?,?,?,?{div=8})">, !cute.int_tuple<"(0,48,0,0)">) -> !cute.int_tuple<"(?,?,?,?{div=8})">
      %e0_1121, %e1_1122, %e2_1123, %e3_1124 = cute.get_leaves(%tup_1120) : !cute.int_tuple<"(?,?,?,?{div=8})">
      %coord_1125 = cute.make_coord(%e1_1122) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1541 = cute.get_scalars(%coord_1125) : !cute.coord<"?">
      %1542 = arith.cmpi slt, %1541, %1505 : i32
      cf.cond_br %1542, ^bb333, ^bb339
    ^bb333:  // pred: ^bb332
      %ptr_1126 = cute.add_offset(%iter_1030, %54) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_1127 = cute.crd2idx(%83, %lay_1028) : (!cute.coord<"(_,3,_)">, !cute.layout<"((8,1),4,2):((1,0),?{i64 div=128},64)">) -> !cute.int_tuple<"?{i64 div=384}">
      %ptr_1128 = cute.add_offset(%ptr_1025, %idx_1127) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{i64 div=384}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iter_1129 = cute.get_iter(%rmem_1063) : !memref_rmem_i8_
      %1543 = cute.get_scalars(%91) : !cute.int_tuple<"2">
      cf.br ^bb334(%c0_i32 : i32)
    ^bb334(%1544: i32):  // 2 preds: ^bb333, ^bb337
      %1545 = arith.cmpi slt, %1544, %1543 : i32
      cf.cond_br %1545, ^bb335, ^bb338 {llvm.loop_annotation = #loop_annotation}
    ^bb335:  // pred: ^bb334
      %coord_1130 = cute.make_coord(%1544) : (i32) -> !cute.coord<"(_,?)">
      %idx_1131 = cute.crd2idx(%coord_1130, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1132 = cute.add_offset(%ptr_1126, %idx_1131) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1133 = cute.crd2idx(%coord_1130, %94) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((64)))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_1134 = cute.add_offset(%ptr_1128, %idx_1133) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, gmem, align<16>>
      %idx_1135 = cute.crd2idx(%coord_1130, %92) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((2))):(2,((1)))">) -> !cute.int_tuple<"?">
      %ptr_1136 = cute.add_offset(%iter_1129, %idx_1135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %1546 = builtin.unrealized_conversion_cast %ptr_1136 : !cute.ptr<i8, rmem> to !llvm.ptr
      %1547 = llvm.load %1546 : !llvm.ptr -> i8
      %1548 = llvm.icmp "ne" %1547, %0 : i8
      cf.cond_br %1548, ^bb336, ^bb337
    ^bb336:  // pred: ^bb335
      %1549 = builtin.unrealized_conversion_cast %ptr_1132 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1550 = builtin.unrealized_conversion_cast %ptr_1134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %1551 = llvm.load %1549 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1551, %1550 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb337
    ^bb337:  // 2 preds: ^bb335, ^bb336
      %1552 = arith.addi %1544, %c1_i32 : i32
      cf.br ^bb334(%1552 : i32)
    ^bb338:  // pred: ^bb334
      cf.br ^bb339
    ^bb339:  // 2 preds: ^bb332, ^bb338
      return
    }
  }
  func.func @cutlass___call_____main__HSTUAttentionForwardAmpere_object_at__Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Tensorgmemodiv8i64div8i64div8i64div81_Ten(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_, %arg2: !memref_gmem_bf16_, %arg3: !memref_gmem_bf16_, %arg4: !memref_gmem_bf16_, %arg5: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %c57344_i32 = arith.constant 57344 : i32
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c4 = arith.constant 4 : index
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
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %4 = arith.cmpi sgt, %c64_i32, %c0_i32 : i32
    %5 = arith.select %4, %c-1_i32, %c1_i32 : i32
    %6 = arith.addi %5, %3 : i32
    %7 = arith.divsi %6, %c64_i32 : i32
    %8 = arith.addi %c1_i32, %7 : i32
    %9 = arith.subi %c0_i32, %3 : i32
    %10 = arith.divsi %9, %c64_i32 : i32
    %11 = arith.subi %c0_i32, %10 : i32
    %12 = arith.cmpi slt, %3, %c0_i32 : i32
    %13 = arith.cmpi sgt, %3, %c0_i32 : i32
    %14 = arith.cmpi slt, %c64_i32, %c0_i32 : i32
    %15 = arith.cmpi sgt, %c64_i32, %c0_i32 : i32
    %16 = arith.andi %12, %14 : i1
    %17 = arith.andi %13, %15 : i1
    %18 = arith.ori %16, %17 : i1
    %19 = arith.select %18, %8, %11 : i32
    %int_tuple_1 = cute.make_int_tuple(%19) : (i32) -> !cute.int_tuple<"?">
    %e0_2 = cute.get_leaves(%int_tuple_1) : !cute.int_tuple<"?">
    %20 = cute.get_scalars(%e0_2) : !cute.int_tuple<"?">
    %21 = arith.index_cast %20 : i32 to index
    %22 = gpu.launch_func async [%arg5] @kernels::@kernel_cutlass_kernel___main__HSTUAttentionForwardAmpere_object_at__tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8div8div81_tensorptrbf16gmemalign16odiv8div8_0 blocks in (%c4, %c4, %21) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c57344_i32 args(%arg0 : !memref_gmem_bf16_, %arg1 : !memref_gmem_bf16_, %arg2 : !memref_gmem_bf16_, %arg3 : !memref_gmem_bf16_, %arg4 : !memref_gmem_bf16_) {use_pdl = false}
    return
  }
}
