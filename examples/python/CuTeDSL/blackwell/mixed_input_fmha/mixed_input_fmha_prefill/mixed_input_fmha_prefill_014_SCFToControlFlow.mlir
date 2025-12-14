!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((32,2,2),(32,1)):((2,1,64),(128,0))">, tiler_mn = <"[(2,32):(32,1);(2,32):(128,1)]">>
!copy_simt1 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<i8, 32 b>, layout_copy_tv = <"((4,64),16):((1024,1),64)">, tiler_mn = <"[(64,16):(1,128);1:0;4:1]">>
!copy_simt2 = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<i8, 32 b>, layout_copy_tv = <"((4,(16,4)),16):((1,(4,1024)),64)">, tiler_mn = <"[(4,16,16):(16,128,1);1:0;4:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<128>, "(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((32,1),1,4):((1,0),0,32)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((32,1)):((1,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1,2):((1,4),16,0,0,32)">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1,(8,1)):((0,0),1,0,0,(0,0))">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1):((0,0),1,0,0)">
!memref_rmem_bf16_5 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1):((1,4),16,0,0)">
!memref_rmem_bf16_6 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">
!memref_rmem_bf16_7 = !cute.memref<bf16, rmem, align<32>, "((4,4),2,1,1):((0,0),0,0,0)">
!memref_rmem_bf16_8 = !cute.memref<bf16, rmem, "((4,4),2,1,1):((0,0),0,0,0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((32,1),1,4):((1,0),0,32)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(32,4):(1,32)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((32,1)):((1,0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((4,4),2,1,1,2):((1,4),16,0,0,32)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((4,4),2,1,1):((1,4),16,0,0)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<256>, "128:1">
!mma_bf16_bf16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
!mma_bf16_bf16_f32_128x256x16_1 = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_unroll2 = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_unroll3 = #llvm.loop_unroll<count = 4 : i32>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
#loop_annotation2 = #llvm.loop_annotation<unroll = #loop_unroll2>
#loop_annotation3 = #llvm.loop_annotation<unroll = #loop_unroll3>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__MixedInputFusedMultiHeadAttentionPrefill_object_at__TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK12825616_TVLayoutA26416641128_TV_0(%arg0: !mma_bf16_bf16_f32_128x256x16_, %arg1: !mma_bf16_bf16_f32_128x256x16_1, %arg2: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>, %arg3: !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">, %arg4: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>, %arg5: !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">, %arg6: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, %arg7: !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, %arg8: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>, %arg9: !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">, %arg10: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, %arg11: !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, %arg12: !memref_gmem_bf16_, %arg13: f32, %arg14: f32, %arg15: i32, %arg16: i32, %arg17: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.minctasm = 1 : i32, nvvm.reqntid = array<i32: 512, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg1 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %cst = arith.constant dense<0.000000e+00> : vector<2xf32>
      %1 = cute.static : !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,0)),1))">
      %2 = cute.static : !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,1)),64))">
      %3 = cute.static : !cute.layout<"((4,4),2,1,1,(2,(2,1)),(4,5)):((0,0),0,0,0,(0,(0,1)),(64,256))">
      %4 = cute.static : !cute.layout<"((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">
      %c1024_i32 = arith.constant 1024 : i32
      %5 = cute.static : !cute.int_tuple<"32">
      %6 = cute.static : !cute.layout<"(8,((2,2))):(1,((8,4096)))">
      %7 = cute.static : !cute.layout<"(8,(4)):(1,(8))">
      %8 = cute.static : !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">
      %c16777216_i32 = arith.constant 16777216 : i32
      %c65536_i32 = arith.constant 65536 : i32
      %9 = llvm.mlir.zero : vector<32xbf16>
      %10 = cute.static : !cute.layout<"(16,(2)):(1,(4096))">
      %11 = cute.static : !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">
      %12 = cute.static : !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(1,0,0,(0,0)))">
      %13 = cute.static : !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(64,0,0,(0,1)))">
      %14 = cute.static : !cute.layout<"((4,4),2,1,1,(8,1),5):((0,0),64,0,0,(0,1),128)">
      %15 = cute.static : !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">
      %c16_i32 = arith.constant 16 : i32
      %16 = cute.static : !cute.layout<"(16,(2)):(1,(16))">
      %17 = cute.static : !cute.layout<"((32,1),1,4):((1@1,0),0,32@1)">
      %18 = cute.static : !cute.shape<"((64,(32,2)),(1,4))">
      %19 = cute.static : !cute.shape<"(64,256)">
      %20 = cute.static : !cute.coord<"(31,3)">
      %21 = cute.static : !cute.coord<"(30,3)">
      %22 = cute.static : !cute.coord<"(31,2)">
      %23 = cute.static : !cute.coord<"(30,2)">
      %24 = cute.static : !cute.coord<"(31,1)">
      %25 = cute.static : !cute.coord<"(30,1)">
      %26 = cute.static : !cute.coord<"(31,0)">
      %27 = cute.static : !cute.coord<"(30,0)">
      %28 = cute.static : !cute.coord<"(29,3)">
      %29 = cute.static : !cute.coord<"(28,3)">
      %30 = cute.static : !cute.coord<"(29,2)">
      %31 = cute.static : !cute.coord<"(28,2)">
      %32 = cute.static : !cute.coord<"(29,1)">
      %33 = cute.static : !cute.coord<"(28,1)">
      %34 = cute.static : !cute.coord<"(29,0)">
      %35 = cute.static : !cute.coord<"(28,0)">
      %36 = cute.static : !cute.coord<"(27,3)">
      %37 = cute.static : !cute.coord<"(26,3)">
      %38 = cute.static : !cute.coord<"(27,2)">
      %39 = cute.static : !cute.coord<"(26,2)">
      %40 = cute.static : !cute.coord<"(27,1)">
      %41 = cute.static : !cute.coord<"(26,1)">
      %42 = cute.static : !cute.coord<"(27,0)">
      %43 = cute.static : !cute.coord<"(26,0)">
      %44 = cute.static : !cute.coord<"(25,3)">
      %45 = cute.static : !cute.coord<"(24,3)">
      %46 = cute.static : !cute.coord<"(25,2)">
      %47 = cute.static : !cute.coord<"(24,2)">
      %48 = cute.static : !cute.coord<"(25,1)">
      %49 = cute.static : !cute.coord<"(24,1)">
      %50 = cute.static : !cute.coord<"(25,0)">
      %51 = cute.static : !cute.coord<"(24,0)">
      %52 = cute.static : !cute.coord<"(23,3)">
      %53 = cute.static : !cute.coord<"(22,3)">
      %54 = cute.static : !cute.coord<"(23,2)">
      %55 = cute.static : !cute.coord<"(22,2)">
      %56 = cute.static : !cute.coord<"(23,1)">
      %57 = cute.static : !cute.coord<"(22,1)">
      %58 = cute.static : !cute.coord<"(23,0)">
      %59 = cute.static : !cute.coord<"(22,0)">
      %60 = cute.static : !cute.coord<"(21,3)">
      %61 = cute.static : !cute.coord<"(20,3)">
      %62 = cute.static : !cute.coord<"(21,2)">
      %63 = cute.static : !cute.coord<"(20,2)">
      %64 = cute.static : !cute.coord<"(21,1)">
      %65 = cute.static : !cute.coord<"(20,1)">
      %66 = cute.static : !cute.coord<"(21,0)">
      %67 = cute.static : !cute.coord<"(20,0)">
      %68 = cute.static : !cute.coord<"(19,3)">
      %69 = cute.static : !cute.coord<"(18,3)">
      %70 = cute.static : !cute.coord<"(19,2)">
      %71 = cute.static : !cute.coord<"(18,2)">
      %72 = cute.static : !cute.coord<"(19,1)">
      %73 = cute.static : !cute.coord<"(18,1)">
      %74 = cute.static : !cute.coord<"(19,0)">
      %75 = cute.static : !cute.coord<"(18,0)">
      %76 = cute.static : !cute.coord<"(17,3)">
      %77 = cute.static : !cute.coord<"(16,3)">
      %78 = cute.static : !cute.coord<"(17,2)">
      %79 = cute.static : !cute.coord<"(16,2)">
      %80 = cute.static : !cute.coord<"(17,1)">
      %81 = cute.static : !cute.coord<"(16,1)">
      %82 = cute.static : !cute.coord<"(17,0)">
      %83 = cute.static : !cute.coord<"(16,0)">
      %84 = cute.static : !cute.coord<"(15,3)">
      %85 = cute.static : !cute.coord<"(14,3)">
      %86 = cute.static : !cute.coord<"(15,2)">
      %87 = cute.static : !cute.coord<"(14,2)">
      %88 = cute.static : !cute.coord<"(15,1)">
      %89 = cute.static : !cute.coord<"(14,1)">
      %90 = cute.static : !cute.coord<"(15,0)">
      %91 = cute.static : !cute.coord<"(14,0)">
      %92 = cute.static : !cute.coord<"(13,3)">
      %93 = cute.static : !cute.coord<"(12,3)">
      %94 = cute.static : !cute.coord<"(13,2)">
      %95 = cute.static : !cute.coord<"(12,2)">
      %96 = cute.static : !cute.coord<"(13,1)">
      %97 = cute.static : !cute.coord<"(12,1)">
      %98 = cute.static : !cute.coord<"(13,0)">
      %99 = cute.static : !cute.coord<"(12,0)">
      %100 = cute.static : !cute.coord<"(11,3)">
      %101 = cute.static : !cute.coord<"(10,3)">
      %102 = cute.static : !cute.coord<"(11,2)">
      %103 = cute.static : !cute.coord<"(10,2)">
      %104 = cute.static : !cute.coord<"(11,1)">
      %105 = cute.static : !cute.coord<"(10,1)">
      %106 = cute.static : !cute.coord<"(11,0)">
      %107 = cute.static : !cute.coord<"(10,0)">
      %108 = cute.static : !cute.coord<"(9,3)">
      %109 = cute.static : !cute.coord<"(8,3)">
      %110 = cute.static : !cute.coord<"(9,2)">
      %111 = cute.static : !cute.coord<"(8,2)">
      %112 = cute.static : !cute.coord<"(9,1)">
      %113 = cute.static : !cute.coord<"(8,1)">
      %114 = cute.static : !cute.coord<"(9,0)">
      %115 = cute.static : !cute.coord<"(8,0)">
      %116 = cute.static : !cute.coord<"(7,3)">
      %117 = cute.static : !cute.coord<"(6,3)">
      %118 = cute.static : !cute.coord<"(7,2)">
      %119 = cute.static : !cute.coord<"(6,2)">
      %120 = cute.static : !cute.coord<"(7,1)">
      %121 = cute.static : !cute.coord<"(6,1)">
      %122 = cute.static : !cute.coord<"(7,0)">
      %123 = cute.static : !cute.coord<"(6,0)">
      %124 = cute.static : !cute.coord<"(5,3)">
      %125 = cute.static : !cute.coord<"(4,3)">
      %126 = cute.static : !cute.coord<"(5,2)">
      %127 = cute.static : !cute.coord<"(4,2)">
      %128 = cute.static : !cute.coord<"(5,1)">
      %129 = cute.static : !cute.coord<"(4,1)">
      %130 = cute.static : !cute.coord<"(5,0)">
      %131 = cute.static : !cute.coord<"(4,0)">
      %132 = cute.static : !cute.coord<"(3,3)">
      %133 = cute.static : !cute.coord<"(2,3)">
      %134 = cute.static : !cute.coord<"(3,2)">
      %135 = cute.static : !cute.coord<"(2,2)">
      %136 = cute.static : !cute.coord<"(3,1)">
      %137 = cute.static : !cute.coord<"(2,1)">
      %138 = cute.static : !cute.coord<"(3,0)">
      %139 = cute.static : !cute.coord<"(2,0)">
      %140 = cute.static : !cute.coord<"(1,3)">
      %141 = cute.static : !cute.coord<"(0,3)">
      %142 = cute.static : !cute.coord<"(1,2)">
      %143 = cute.static : !cute.coord<"(0,2)">
      %144 = cute.static : !cute.coord<"(1,1)">
      %145 = cute.static : !cute.coord<"(0,1)">
      %146 = cute.static : !cute.coord<"(1,0)">
      %147 = cute.static : !cute.coord<"(0,0)">
      %cst_0 = arith.constant 5.000000e-01 : f32
      %148 = cute.static : !cute.int_tuple<"24">
      %149 = cute.static : !cute.int_tuple<"16">
      %150 = cute.static : !cute.layout<"((8,4),((1,(2,2)))):((1,8),((0,(32,4096))))">
      %151 = cute.static : !cute.layout<"((8,4),((1,4))):((1,8),((0,32)))">
      %c2048_i32 = arith.constant 2048 : i32
      %cst_1 = arith.constant 0.000000e+00 : f32
      %cst_2 = arith.constant 0xFF800000 : f32
      %152 = cute.static : !cute.layout<"((32,1),((1,4))):((1,0),((0,32)))">
      %153 = cute.static : !cute.layout<"(((32,32),1),((1,4))):(((1,65536),0),((0,32)))">
      %154 = cute.static : !cute.layout<"(((32,32),1),1,4):(((1,65536),0),0,32)">
      %155 = cute.static : !cute.layout<"((32,1),1,4):((1,0),0,32)">
      %c4194304_i32 = arith.constant 4194304 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %156 = cute.static : !cute.stride<"(1@0,1@1,256@1)">
      %c138478736_i32 = arith.constant 138478736 : i32
      %157 = cute.static : !cute.layout<"(1,1,4):(0,0,128)">
      %158 = cute.static : !cute.layout<"(1,1,4,3):(0,0,128,1024)">
      %159 = cute.static : !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">
      %c3_i16 = arith.constant 3 : i16
      %c14_i32 = arith.constant 14 : i32
      %c138413200_i32 = arith.constant 138413200 : i32
      %160 = cute.static : !cute.layout<"(1,1,4):(0,0,2)">
      %161 = cute.static : !cute.layout<"(1,1,4,3):(0,0,2,1024)">
      %c3_i32 = arith.constant 3 : i32
      %162 = cute.static : !cute.layout<"(1,1,4,8):(0,0,2,512)">
      %c160_i32 = arith.constant 160 : i32
      %c12_i32 = arith.constant 12 : i32
      %false = arith.constant false
      %163 = cute.static : !cute.int_tuple<"4096">
      %164 = cute.static : !cute.int_tuple<"(64,0)">
      %165 = cute.static : !cute.layout<"((4096,2),5):((1,4096),8192)">
      %c4_i32 = arith.constant 4 : i32
      %166 = cute.static : !cute.layout<"((8192,1),5):((1,0),8192)">
      %c8192_i32 = arith.constant 8192 : i32
      %167 = cute.static : !cute.layout<"((4096,1),8):((1,0),4096)">
      %c16384_i32 = arith.constant 16384 : i32
      %c5_i32 = arith.constant 5 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %168 = cute.static : !cute.stride<"(((1@0,0),0),64@0)">
      %169 = cute.static : !cute.stride<"(((1@0,1@1),64@0),256@0,64@1)">
      %170 = cute.static : !cute.stride<"(((1@0,0),0),256@0)">
      %171 = cute.static : !cute.stride<"(((1@0,1@1),0),256@1,64@0)">
      %172 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %true = arith.constant true
      %173 = cute.static : !cute.stride<"(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %174 = cute.static : !cute.stride<"(1@0,1@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %175 = cute.static : !cute.int_tuple<"(0,0,((0,0),0))">
      %176 = cute.static : !cute.stride<"(((1@0,0),0),64@0,((0,1@1),1@2))">
      %177 = cute.static : !cute.layout<"(((64,1),1),(4,5)):(((1,0),0),(64,256))">
      %178 = cute.static : !cute.stride<"((1@0,0),64@0,((0,1@1),1@2))">
      %179 = cute.static : !cute.stride<"(1@0,64@0,((0,1@1),1@2))">
      %180 = cute.static : !cute.stride<"(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">
      %181 = cute.static : !cute.stride<"(((1@0,1@1),0,16@1),256@0,64@1,((0,1@2),1@3))">
      %182 = cute.static : !cute.stride<"((1@0,1@1),0,16@1,256@0,64@1,((0,1@2),1@3))">
      %183 = cute.static : !cute.stride<"(1@0,1@1,256@0,64@1,((0,1@2),1@3))">
      %184 = cute.static : !cute.stride<"(((1@0,0),0),256@0,((0,1@1),1@2))">
      %185 = cute.static : !cute.layout<"(((128,1),1),5):(((1,0),0),128)">
      %186 = cute.static : !cute.stride<"((1@0,0),256@0,((0,1@1),1@2))">
      %187 = cute.static : !cute.stride<"((1@0,128@0),256@0,((0,1@1),1@2))">
      %188 = cute.static : !cute.stride<"(1@0,256@0,((0,1@1),1@2))">
      %189 = cute.static : !cute.int_tuple<"(0,0,0)">
      %190 = cute.static : !cute.stride<"(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">
      %191 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),256@1,64@0,((0,1@2),1@3))">
      %192 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,256@1,64@0,((0,1@2),1@3))">
      %193 = cute.static : !cute.stride<"(1@1,1@0,256@1,64@0,((0,1@2),1@3))">
      %194 = cute.static : !cute.int_tuple<"(0,0,0,0)">
      %195 = cute.static : !cute.stride<"(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">
      %196 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),128@1,64@0,((1@2,1@3),1@4))">
      %197 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,128@1,64@0,((1@2,1@3),1@4))">
      %198 = cute.static : !cute.stride<"(1@1,1@0,128@1,64@0,((1@2,1@3),1@4))">
      %c64_i32 = arith.constant 64 : i32
      %c128_i32 = arith.constant 128 : i32
      %199 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
      %200 = cute.static : !cute.int_tuple<"256">
      %201 = cute.static : !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">
      %202 = llvm.mlir.constant(0 : i32) : i32
      %203 = cute.static : !cute.layout<"128:1">
      %204 = cute.static : !cute.layout<"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">
      %c8_i32 = arith.constant 8 : i32
      %c512_i32 = arith.constant 512 : i32
      %c256_i32 = arith.constant 256 : i32
      %205 = cute.static : !cute.int_tuple<"8">
      %206 = cute.static : !cute.int_tuple<"7">
      %207 = cute.static : !cute.int_tuple<"6">
      %208 = cute.static : !cute.int_tuple<"5">
      %209 = cute.static : !cute.int_tuple<"4">
      %210 = cute.static : !cute.int_tuple<"3">
      %211 = cute.static : !cute.int_tuple<"2">
      %212 = cute.static : !cute.int_tuple<"1">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %213 = cute.static : !cute.int_tuple<"504">
      %214 = cute.static : !cute.int_tuple<"496">
      %215 = cute.static : !cute.int_tuple<"480">
      %216 = cute.static : !cute.int_tuple<"448">
      %217 = cute.static : !cute.int_tuple<"416">
      %218 = cute.static : !cute.int_tuple<"368">
      %219 = cute.static : !cute.int_tuple<"288">
      %220 = cute.static : !cute.int_tuple<"208">
      %221 = cute.static : !cute.int_tuple<"128">
      %222 = cute.static : !cute.int_tuple<"0">
      %223 = cute.static : !cute.int_tuple<"512">
      %c2_i32 = arith.constant 2 : i32
      %c13_i32 = arith.constant 13 : i32
      %c32_i32 = arith.constant 32 : i32
      %224 = cute.static : !cute.layout<"((2),1,1,1):((1),0,0,0)">
      %225 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %226 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %227 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %228 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %229 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %230 = arith.muli %226, %228 : i32
      %231 = arith.addi %225, %230 : i32
      %232 = arith.muli %227, %228 : i32
      %233 = arith.muli %232, %229 : i32
      %234 = arith.addi %231, %233 : i32
      %235 = arith.floordivsi %234, %c32_i32 : i32
      %236 = cute_nvgpu.arch.make_warp_uniform(%235) : i32
      %237 = arith.cmpi eq, %236, %c13_i32 : i32
      cf.cond_br %237, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %238 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %239 = arith.remsi %238, %c2_i32 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %223) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<512>>
      %ptr_3 = cute.add_offset(%smem_ptr, %221) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_4 = cute.add_offset(%smem_ptr, %220) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"208">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_5 = cute.add_offset(%smem_ptr, %219) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"288">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_6 = cute.add_offset(%smem_ptr, %218) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"368">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_7 = cute.add_offset(%smem_ptr, %217) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"416">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_8 = cute.add_offset(%smem_ptr, %216) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"448">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_9 = cute.add_offset(%smem_ptr, %215) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"480">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_10 = cute.add_offset(%smem_ptr, %214) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"496">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_10) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %ptr_11 = cute.add_offset(%smem_ptr, %213) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"504">) -> !cute.ptr<i8, smem, align<8>>
      %iter_12 = cute.recast_iter(%ptr_11) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %iter_13 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %240 = arith.cmpi eq, %236, %c0_i32 : i32
      cf.cond_br %240, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %241 = builtin.unrealized_conversion_cast %iter_13 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %241, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_14 = cute.add_offset(%iter_13, %212) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %242 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %242, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_15 = cute.add_offset(%iter_13, %211) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %243 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %243, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter_13, %210) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %244 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %244, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_17 = cute.add_offset(%iter_13, %209) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %245 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %245, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_18 = cute.add_offset(%iter_13, %208) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %246 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %246, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_19 = cute.add_offset(%iter_13, %207) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %247 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %247, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_20 = cute.add_offset(%iter_13, %206) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %248 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %248, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_21 = cute.add_offset(%iter_13, %205) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      cf.cond_br %240, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %249 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %249, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_22 = cute.add_offset(%iter_13, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %250 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %250, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_23 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_24 = cute.add_offset(%iter_13, %int_tuple_23) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %251 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %251, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_25 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_26 = cute.add_offset(%iter_13, %int_tuple_25) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %252 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %252, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_28 = cute.add_offset(%iter_13, %int_tuple_27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %253 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %253, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_29 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_30 = cute.add_offset(%iter_13, %int_tuple_29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %254 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %254, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_31 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
      %ptr_32 = cute.add_offset(%iter_13, %int_tuple_31) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"14">) -> !cute.ptr<i64, smem, align<16>>
      %255 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %255, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_33 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
      %ptr_34 = cute.add_offset(%iter_13, %int_tuple_33) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"15">) -> !cute.ptr<i64, smem>
      %256 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %256, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %257 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %258 = cute_nvgpu.arch.make_warp_uniform(%257) : i32
      %259 = cute.get_flat_coord(%258, %224) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%259) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %260 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %224) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_35 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %261 = cute.get_scalars(%e0_35) : !cute.int_tuple<"?">
      %262 = arith.shli %c1_i32, %261 : i32
      %263 = arith.trunci %262 : i32 to i16
      %coord_36 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_37 = cute.crd2idx(%coord_36, %224) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_38 = cute.get_leaves(%idx_37) : !cute.int_tuple<"?">
      %264 = cute.get_scalars(%e0_38) : !cute.int_tuple<"?">
      %265 = arith.shli %c1_i32, %264 : i32
      %266 = arith.trunci %265 : i32 to i16
      %267 = arith.xori %260, %c1_i32 : i32
      %coord_39 = cute.make_coord(%267) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_40 = cute.crd2idx(%coord_39, %224) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_41 = cute.get_leaves(%idx_40) : !cute.int_tuple<"?">
      %268 = cute.get_scalars(%e0_41) : !cute.int_tuple<"?">
      %269 = arith.shli %c1_i32, %268 : i32
      %270 = arith.trunci %269 : i32 to i16
      %coord_42 = cute.make_coord(%267) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_43 = cute.crd2idx(%coord_42, %224) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_44 = cute.get_leaves(%idx_43) : !cute.int_tuple<"?">
      %271 = cute.get_scalars(%e0_44) : !cute.int_tuple<"?">
      %272 = arith.shli %c1_i32, %271 : i32
      %273 = arith.trunci %272 : i32 to i16
      %274 = arith.ori %263, %266 : i16
      %275 = arith.ori %274, %270 : i16
      %276 = arith.ori %275, %273 : i16
      %277 = arith.cmpi eq, %239, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_45 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      cf.cond_br %240, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %278 = builtin.unrealized_conversion_cast %iter_45 : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %278, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_46 = cute.add_offset(%iter_45, %212) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %279 = builtin.unrealized_conversion_cast %ptr_46 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %279, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_47 = cute.add_offset(%iter_45, %211) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %280 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %280, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_48 = cute.add_offset(%iter_45, %210) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %281 = builtin.unrealized_conversion_cast %ptr_48 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %281, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_49 = cute.add_offset(%iter_45, %209) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %282 = builtin.unrealized_conversion_cast %ptr_49 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %282, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_50 = cute.add_offset(%iter_45, %208) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %240, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %283 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %283, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_51 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_52 = cute.add_offset(%iter_45, %int_tuple_51) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn = cute.derefine(%ptr_52) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %284 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %284, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_53 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_54 = cute.add_offset(%iter_45, %int_tuple_53) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %285 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %285, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_56 = cute.add_offset(%iter_45, %int_tuple_55) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn_57 = cute.derefine(%ptr_56) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %286 = builtin.unrealized_conversion_cast %dyn_57 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %286, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_58 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_59 = cute.add_offset(%iter_45, %int_tuple_58) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %287 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %287, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      nvvm.barrier
      %iter_60 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %240, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      %288 = builtin.unrealized_conversion_cast %iter_60 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %288, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_61 = cute.add_offset(%iter_60, %212) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %289 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %289, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_62 = cute.add_offset(%iter_60, %211) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %290 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %290, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_63 = cute.add_offset(%iter_60, %210) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %291 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %291, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_64 = cute.add_offset(%iter_60, %209) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<16>>
      %292 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %292, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %ptr_65 = cute.add_offset(%iter_60, %208) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %240, ^bb13, ^bb14
    ^bb13:  // pred: ^bb12
      %293 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %293, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_66 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_67 = cute.add_offset(%iter_60, %int_tuple_66) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_68 = cute.derefine(%ptr_67) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %294 = builtin.unrealized_conversion_cast %dyn_68 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %294, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_69 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_70 = cute.add_offset(%iter_60, %int_tuple_69) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %295 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %295, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_71 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_72 = cute.add_offset(%iter_60, %int_tuple_71) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_73 = cute.derefine(%ptr_72) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %296 = builtin.unrealized_conversion_cast %dyn_73 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %296, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_74 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_75 = cute.add_offset(%iter_60, %int_tuple_74) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %297 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %297, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb12, ^bb13
      nvvm.barrier
      %iter_76 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %240, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      %298 = builtin.unrealized_conversion_cast %iter_76 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %298, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_77 = cute.add_offset(%iter_76, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %299 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %299, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_78 = cute.add_offset(%iter_76, %211) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %300 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %300, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_79 = cute.add_offset(%iter_76, %210) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %301 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %301, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_80 = cute.add_offset(%iter_76, %209) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %302 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %302, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %ptr_81 = cute.add_offset(%iter_76, %208) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %240, ^bb17, ^bb18
    ^bb17:  // pred: ^bb16
      %303 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %303, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_82 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_83 = cute.add_offset(%iter_76, %int_tuple_82) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_84 = cute.derefine(%ptr_83) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %304 = builtin.unrealized_conversion_cast %dyn_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %304, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_85 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_86 = cute.add_offset(%iter_76, %int_tuple_85) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %305 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %305, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_87 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_88 = cute.add_offset(%iter_76, %int_tuple_87) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_89 = cute.derefine(%ptr_88) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %306 = builtin.unrealized_conversion_cast %dyn_89 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %306, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_90 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_91 = cute.add_offset(%iter_76, %int_tuple_90) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %307 = builtin.unrealized_conversion_cast %ptr_91 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %307, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      nvvm.barrier
      %iter_92 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %240, ^bb19, ^bb20
    ^bb19:  // pred: ^bb18
      %308 = builtin.unrealized_conversion_cast %iter_92 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %308, %c512_i32 : !llvm.ptr<3>, i32
      %ptr_93 = cute.add_offset(%iter_92, %212) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %309 = builtin.unrealized_conversion_cast %ptr_93 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %309, %c512_i32 : !llvm.ptr<3>, i32
      %ptr_94 = cute.add_offset(%iter_92, %211) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %310 = builtin.unrealized_conversion_cast %ptr_94 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %310, %c512_i32 : !llvm.ptr<3>, i32
      cf.br ^bb20
    ^bb20:  // 2 preds: ^bb18, ^bb19
      %ptr_95 = cute.add_offset(%iter_92, %210) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      cf.cond_br %240, ^bb21, ^bb22
    ^bb21:  // pred: ^bb20
      %311 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %311, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_96 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %ptr_97 = cute.add_offset(%iter_92, %int_tuple_96) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_98 = cute.derefine(%ptr_97) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %312 = builtin.unrealized_conversion_cast %dyn_98 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %312, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_99 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_100 = cute.add_offset(%iter_92, %int_tuple_99) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %313 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %313, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb22
    ^bb22:  // 2 preds: ^bb20, ^bb21
      %314 = arith.floordivsi %258, %c2_i32 : i32
      %315 = arith.muli %314, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_101 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %240, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %316 = builtin.unrealized_conversion_cast %iter_101 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %316, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_102 = cute.add_offset(%iter_101, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %317 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %317, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %ptr_103 = cute.add_offset(%iter_101, %211) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %240, ^bb25, ^bb26
    ^bb25:  // pred: ^bb24
      %318 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %318, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_104 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_105 = cute.add_offset(%iter_101, %int_tuple_104) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %319 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %319, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb26
    ^bb26:  // 2 preds: ^bb24, ^bb25
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_106 = cute.recast_iter(%ptr_8) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      cf.cond_br %240, ^bb27, ^bb28
    ^bb27:  // pred: ^bb26
      %320 = builtin.unrealized_conversion_cast %iter_106 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %320, %c256_i32 : !llvm.ptr<3>, i32
      %ptr_107 = cute.add_offset(%iter_106, %212) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %321 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %321, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb28
    ^bb28:  // 2 preds: ^bb26, ^bb27
      %ptr_108 = cute.add_offset(%iter_106, %211) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %240, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %322 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %322, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_109 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_110 = cute.add_offset(%iter_106, %int_tuple_109) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %323 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %323, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_111 = cute.recast_iter(%ptr_9) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %240, ^bb31, ^bb32
    ^bb31:  // pred: ^bb30
      %324 = builtin.unrealized_conversion_cast %iter_111 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %324, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb32
    ^bb32:  // 2 preds: ^bb30, ^bb31
      %ptr_112 = cute.add_offset(%iter_111, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %240, ^bb33, ^bb34
    ^bb33:  // pred: ^bb32
      %325 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %325, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb34
    ^bb34:  // 2 preds: ^bb32, ^bb33
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %326 = arith.cmpi eq, %236, %c8_i32 : i32
      cf.cond_br %326, ^bb35, ^bb38
    ^bb35:  // pred: ^bb34
      %327 = nvvm.elect.sync -> i1
      cf.cond_br %327, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %328 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %328, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      cf.br ^bb38
    ^bb38:  // 2 preds: ^bb34, ^bb37
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      %int_tuple_113 = cute.make_int_tuple() : () -> !cute.int_tuple<"66048">
      %ptr_114 = cute.add_offset(%smem_ptr, %int_tuple_113) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"66048">) -> !cute.ptr<i8, smem, align<512>>
      %iter_115 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %int_tuple_116 = cute.make_int_tuple() : () -> !cute.int_tuple<"115200">
      %ptr_117 = cute.add_offset(%smem_ptr, %int_tuple_116) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"115200">) -> !cute.ptr<i8, smem, align<512>>
      %iter_118 = cute.recast_iter(%ptr_114) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %iter_119 = cute.recast_iter(%iter_118) : !cute.ptr<bf16, smem, align<512>, S<3,4,3>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %int_tuple_120 = cute.make_int_tuple() : () -> !cute.int_tuple<"116480">
      %ptr_121 = cute.add_offset(%smem_ptr, %int_tuple_120) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"116480">) -> !cute.ptr<i8, smem, align<256>>
      %iter_122 = cute.recast_iter(%ptr_117) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>>
      %int_tuple_123 = cute.make_int_tuple() : () -> !cute.int_tuple<"119040">
      %ptr_124 = cute.add_offset(%smem_ptr, %int_tuple_123) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"119040">) -> !cute.ptr<i8, smem, align<256>>
      %iter_125 = cute.recast_iter(%ptr_121) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<bf16, smem, align<256>>
      %int_tuple_126 = cute.make_int_tuple() : () -> !cute.int_tuple<"184576">
      %ptr_127 = cute.add_offset(%smem_ptr, %int_tuple_126) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"184576">) -> !cute.ptr<i8, smem, align<256>>
      %iter_128 = cute.recast_iter(%ptr_124) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<bf16, smem, align<256>, S<3,4,3>>
      %int_tuple_129 = cute.make_int_tuple() : () -> !cute.int_tuple<"185088">
      %ptr_130 = cute.add_offset(%smem_ptr, %int_tuple_129) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"185088">) -> !cute.ptr<i8, smem, align<256>>
      %iter_131 = cute.recast_iter(%ptr_127) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<f32, smem, align<256>>
      %view = cute.make_view(%iter_131, %203) : !memref_smem_f32_
      %iter_132 = cute.recast_iter(%ptr_130) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %iter_133 = cute.recast_iter(%iter_132) : !cute.ptr<i8, smem, align<256>, S<2,4,3>> to !cute.ptr<i8, smem, align<256>>
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_115 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"((64,16),1,4,8):((64,1),0,16,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_134 = cute_nvgpu.make_umma_smem_desc(%iter_128 : !cute.ptr<bf16, smem, align<256>, S<3,4,3>>) layout = <"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_135 = cute_nvgpu.make_umma_smem_desc(%iter_118 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"((128,16),1,4,3):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_136 = cute_nvgpu.make_umma_smem_desc(%iter_119 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"(((64,2),16),1,4,3):(((1,4096),64),0,1024,8192)">, major = <mn> -> !cute_nvgpu.smem_desc
      %329 = cute.inttoptr(%202) : i32 to !cute.ptr<f32, tmem, align<1>>
      %ptr_137 = cute.add_offset(%329, %200) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"256">) -> !cute.ptr<f32, tmem, align<1>>
      %lay = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
      %330:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
      %331 = arith.ceildivsi %330#0, %c128_i32 : i32
      %332 = arith.ceildivsi %330#1, %c64_i32 : i32
      %shape = cute.make_shape(%331, %332, %330#2, %330#3, %330#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(128,64,?,?,((?,?),?))">
      %lay_138 = cute.make_layout(%shape, %198) : !cute.layout<"(128,64,?,?,((?,?),?)):(1@1,1@0,128@1,64@0,((1@2,1@3),1@4))">
      %coord_139 = cute.make_coord(%239) : (i32) -> !cute.coord<"?">
      %333:5 = cute.get_scalars(%lay_138) <{only_dynamic}> : !cute.layout<"(128,64,?,?,((?,?),?)):(1@1,1@0,128@1,64@0,((1@2,1@3),1@4))">
      %334 = cute.get_scalars(%coord_139) <{only_dynamic}> : !cute.coord<"?">
      %335 = arith.remsi %334, %c2_i32 : i32
      %336 = arith.remsi %335, %c2_i32 : i32
      %337 = arith.muli %336, %c64_i32 : i32
      %iv = cute.assume(%337) : (i32) -> !cute.i32<divby 64>
      %int_tuple_140 = cute.make_int_tuple(%iv) : (!cute.i32<divby 64>) -> !cute.int_tuple<"(0,?{div=64},0,0,0)">
      %tup = cute.add_offset(%199, %int_tuple_140) : (!cute.int_tuple<"(0,0,0,0,0)">, !cute.int_tuple<"(0,?{div=64},0,0,0)">) -> !cute.int_tuple<"(0,?{div=64},0,0,0)">
      %shape_141 = cute.make_shape(%333#0, %333#1, %333#2, %333#3, %333#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((64,16),1,4,?,?,((?,?),?))">
      %lay_142 = cute.make_layout(%shape_141, %197) : !cute.layout<"((64,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,128@1,64@0,((1@2,1@3),1@4))">
      %338:5 = cute.get_scalars(%lay_142) <{only_dynamic}> : !cute.layout<"((64,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,128@1,64@0,((1@2,1@3),1@4))">
      %shape_143 = cute.make_shape(%338#0, %338#1, %338#2, %338#3, %338#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,16),1,4),?,?,((?,?),?))">
      %lay_144 = cute.make_layout(%shape_143, %196) : !cute.layout<"(((64,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),128@1,64@0,((1@2,1@3),1@4))">
      %339:5 = cute.get_scalars(%lay_144) <{only_dynamic}> : !cute.layout<"(((64,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),128@1,64@0,((1@2,1@3),1@4))">
      %shape_145 = cute.make_shape(%339#0, %339#1, %339#2, %339#3, %339#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,((?,?),?))">
      %lay_146 = cute.make_layout(%shape_145, %195) : !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">
      %lay_147 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
      %340:5 = cute.get_scalars(%lay_147) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
      %341 = arith.ceildivsi %340#0, %c256_i32 : i32
      %342 = arith.ceildivsi %340#1, %c64_i32 : i32
      %shape_148 = cute.make_shape(%341, %342, %340#2, %340#3, %340#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(256,64,?,?,((?,?),?))">
      %lay_149 = cute.make_layout(%shape_148, %193) : !cute.layout<"(256,64,?,?,((?,?),?)):(1@1,1@0,256@1,64@0,((0,1@2),1@3))">
      %343:5 = cute.get_scalars(%lay_149) <{only_dynamic}> : !cute.layout<"(256,64,?,?,((?,?),?)):(1@1,1@0,256@1,64@0,((0,1@2),1@3))">
      %344 = arith.muli %336, %c128_i32 : i32
      %iv_150 = cute.assume(%344) : (i32) -> !cute.i32<divby 128>
      %int_tuple_151 = cute.make_int_tuple(%iv_150) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_152 = cute.add_offset(%194, %int_tuple_151) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %shape_153 = cute.make_shape(%343#0, %343#1, %343#2, %343#3, %343#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,((?,?),?))">
      %lay_154 = cute.make_layout(%shape_153, %192) : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,256@1,64@0,((0,1@2),1@3))">
      %345:5 = cute.get_scalars(%lay_154) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,256@1,64@0,((0,1@2),1@3))">
      %shape_155 = cute.make_shape(%345#0, %345#1, %345#2, %345#3, %345#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,((?,?),?))">
      %lay_156 = cute.make_layout(%shape_155, %191) : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),256@1,64@0,((0,1@2),1@3))">
      %346:5 = cute.get_scalars(%lay_156) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),256@1,64@0,((0,1@2),1@3))">
      %shape_157 = cute.make_shape(%346#0, %346#1, %346#2, %346#3, %346#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,((?,?),?))">
      %lay_158 = cute.make_layout(%shape_157, %190) : !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">
      %lay_159 = cute.get_layout(%arg7) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %347:4 = cute.get_scalars(%lay_159) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %348 = arith.ceildivsi %347#0, %c256_i32 : i32
      %shape_160 = cute.make_shape(%348, %347#1, %347#2, %347#3) : (i32, i32, i32, i32) -> !cute.shape<"(256,?,((?,?),?))">
      %lay_161 = cute.make_layout(%shape_160, %188) : !cute.layout<"(256,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %349:4 = cute.get_scalars(%lay_161) <{only_dynamic}> : !cute.layout<"(256,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %shape_162 = cute.make_shape(%349#0, %349#1, %349#2, %349#3) : (i32, i32, i32, i32) -> !cute.shape<"((128,2),?,((?,?),?))">
      %lay_163 = cute.make_layout(%shape_162, %187) : !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">
      %coord_164 = cute.make_coord(%239) : (i32) -> !cute.coord<"((_,?),_,_)">
      %350:4 = cute.get_scalars(%lay_163) <{only_dynamic}> : !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">
      %shape_165 = cute.make_shape(%350#0, %350#1, %350#2, %350#3) : (i32, i32, i32, i32) -> !cute.shape<"(128,?,((?,?),?))">
      %lay_166 = cute.make_layout(%shape_165, %188) : !cute.layout<"(128,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %idx_167 = cute.crd2idx(%coord_164, %lay_163) : (!cute.coord<"((_,?),_,_)">, !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %tup_168 = cute.add_offset(%189, %idx_167) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},0,0)">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %351:4 = cute.get_scalars(%lay_166) <{only_dynamic}> : !cute.layout<"(128,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %shape_169 = cute.make_shape(%351#0, %351#1, %351#2, %351#3) : (i32, i32, i32, i32) -> !cute.shape<"((128,1),?,((?,?),?))">
      %lay_170 = cute.make_layout(%shape_169, %186) : !cute.layout<"((128,1),?,((?,?),?)):((1@0,0),256@0,((0,1@1),1@2))">
      %e0_171, %e1_172, %e2_173 = cute.get_leaves(%tup_168) : !cute.int_tuple<"(?{div=128},0,0)">
      %352 = cute.get_shape(%lay_170) : (!cute.layout<"((128,1),?,((?,?),?)):((1@0,0),256@0,((0,1@1),1@2))">) -> !cute.shape<"((128,1),?,((?,?),?))">
      %e0_174, %e1_175, %e2_176, %e3_177, %e4, %e5 = cute.get_leaves(%352) : !cute.shape<"((128,1),?,((?,?),?))">
      %itup_178 = cute.to_int_tuple(%e2_176) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_179 = cute.to_int_tuple(%e3_177) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_180 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_181 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_182 = cute.make_shape(%itup_178, %itup_179, %itup_180, %itup_181) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(((128,1),1),?,((?,?),?))">
      %lay_183 = cute.make_layout(%shape_182, %184) : !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">
      %int_tuple_184 = cute.make_int_tuple(%e0_171) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %lay_185 = cute.get_layout(%arg9) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
      %353:5 = cute.get_scalars(%lay_185) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
      %354 = arith.ceildivsi %353#0, %c256_i32 : i32
      %355 = arith.ceildivsi %353#1, %c64_i32 : i32
      %shape_186 = cute.make_shape(%354, %355, %353#2, %353#3, %353#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(256,64,?,?,((?,?),?))">
      %lay_187 = cute.make_layout(%shape_186, %183) : !cute.layout<"(256,64,?,?,((?,?),?)):(1@0,1@1,256@0,64@1,((0,1@2),1@3))">
      %356:5 = cute.get_scalars(%lay_187) <{only_dynamic}> : !cute.layout<"(256,64,?,?,((?,?),?)):(1@0,1@1,256@0,64@1,((0,1@2),1@3))">
      %int_tuple_188 = cute.make_int_tuple(%iv_150) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(?{div=128},0,0,0)">
      %tup_189 = cute.add_offset(%194, %int_tuple_188) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?{div=128},0,0,0)">) -> !cute.int_tuple<"(?{div=128},0,0,0)">
      %shape_190 = cute.make_shape(%356#0, %356#1, %356#2, %356#3, %356#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,((?,?),?))">
      %lay_191 = cute.make_layout(%shape_190, %182) : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@0,1@1),0,16@1,256@0,64@1,((0,1@2),1@3))">
      %357:5 = cute.get_scalars(%lay_191) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@0,1@1),0,16@1,256@0,64@1,((0,1@2),1@3))">
      %shape_192 = cute.make_shape(%357#0, %357#1, %357#2, %357#3, %357#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,((?,?),?))">
      %lay_193 = cute.make_layout(%shape_192, %181) : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@0,1@1),0,16@1),256@0,64@1,((0,1@2),1@3))">
      %358:5 = cute.get_scalars(%lay_193) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@0,1@1),0,16@1),256@0,64@1,((0,1@2),1@3))">
      %shape_194 = cute.make_shape(%358#0, %358#1, %358#2, %358#3, %358#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,64),2),?,?,((?,?),?))">
      %lay_195 = cute.make_layout(%shape_194, %180) : !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">
      %lay_196 = cute.get_layout(%arg11) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %359:4 = cute.get_scalars(%lay_196) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %360 = arith.ceildivsi %359#0, %c64_i32 : i32
      %shape_197 = cute.make_shape(%360, %359#1, %359#2, %359#3) : (i32, i32, i32, i32) -> !cute.shape<"(64,?,((?,?),?))">
      %lay_198 = cute.make_layout(%shape_197, %179) : !cute.layout<"(64,?,((?,?),?)):(1@0,64@0,((0,1@1),1@2))">
      %361:4 = cute.get_scalars(%lay_198) <{only_dynamic}> : !cute.layout<"(64,?,((?,?),?)):(1@0,64@0,((0,1@1),1@2))">
      %shape_199 = cute.make_shape(%361#0, %361#1, %361#2, %361#3) : (i32, i32, i32, i32) -> !cute.shape<"((64,1),?,((?,?),?))">
      %lay_200 = cute.make_layout(%shape_199, %178) : !cute.layout<"((64,1),?,((?,?),?)):((1@0,0),64@0,((0,1@1),1@2))">
      %362 = cute.get_shape(%lay_200) : (!cute.layout<"((64,1),?,((?,?),?)):((1@0,0),64@0,((0,1@1),1@2))">) -> !cute.shape<"((64,1),?,((?,?),?))">
      %e0_201, %e1_202, %e2_203, %e3_204, %e4_205, %e5_206 = cute.get_leaves(%362) : !cute.shape<"((64,1),?,((?,?),?))">
      %itup_207 = cute.to_int_tuple(%e2_203) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_208 = cute.to_int_tuple(%e3_204) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_209 = cute.to_int_tuple(%e4_205) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_210 = cute.to_int_tuple(%e5_206) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_211 = cute.make_shape(%itup_207, %itup_208, %itup_209, %itup_210) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(((64,1),1),?,((?,?),?))">
      %lay_212 = cute.make_layout(%shape_211, %176) : !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">
      %iter_213 = cute.get_iter(%arg12) : !memref_gmem_bf16_
      %lay_214 = cute.get_layout(%arg12) : !memref_gmem_bf16_
      %363:9 = cute.get_scalars(%lay_214) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
      %364 = arith.ceildivsi %363#0, %c64_i32 : i32
      %365 = arith.muli %363#5, %c64_i32 : i32
      %366 = arith.ceildivsi %363#1, %c256_i32 : i32
      %shape_215 = cute.make_shape(%364, %366, %363#2, %363#3, %363#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(64,256,?,?,((?,?),?))">
      %iv_216 = cute.assume(%363#5) : (i32) -> !cute.i32<divby 256>
      %iv_217 = cute.assume(%365) : (i32) -> !cute.i32<divby 16384>
      %iv_218 = cute.assume(%363#6) : (i32) -> !cute.i32<divby 256>
      %iv_219 = cute.assume(%363#7) : (i32) -> !cute.i32<divby 256>
      %iv_220 = cute.assume(%363#8) : (i32) -> !cute.i32<divby 256>
      %stride = cute.make_stride(%iv_216, %iv_217, %iv_218, %iv_219, %iv_220) : (!cute.i32<divby 256>, !cute.i32<divby 16384>, !cute.i32<divby 256>, !cute.i32<divby 256>, !cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %lay_221 = cute.make_layout(%shape_215, %stride) : !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %367 = cute.get_shape(%lay_214) : (!cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_222, %e1_223, %e2_224, %e3_225, %e4_226 = cute.get_leaves(%367) : !cute.shape<"(?,?,((?,?),?))">
      %itup_227 = cute.to_int_tuple(%e0_222) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_228 = cute.to_int_tuple(%e1_223) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_229 = cute.to_int_tuple(%e2_224) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_230 = cute.to_int_tuple(%e3_225) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_231 = cute.to_int_tuple(%e4_226) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_232 = cute.make_shape(%itup_227, %itup_228, %itup_229, %itup_230, %itup_231) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,((?,?),?))">
      %lay_233 = cute.make_layout(%shape_232, %174) : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %368:5 = cute.get_scalars(%lay_233) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %369 = arith.ceildivsi %368#0, %c64_i32 : i32
      %370 = arith.ceildivsi %368#1, %c256_i32 : i32
      %shape_234 = cute.make_shape(%369, %370, %368#2, %368#3, %368#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(64,256,?,?,((?,?),?))">
      %lay_235 = cute.make_layout(%shape_234, %173) : !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %371 = cute.get_shape(%lay) : (!cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_236, %e1_237, %e2_238, %e3_239, %e4_240 = cute.get_leaves(%371) : !cute.shape<"(?,?,((?,?),?))">
      %itup_241 = cute.to_int_tuple(%e0_236) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %372 = cute.get_shape(%lay_147) : (!cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_242, %e1_243, %e2_244, %e3_245, %e4_246 = cute.get_leaves(%372) : !cute.shape<"(?,?,((?,?),?))">
      %itup_247 = cute.to_int_tuple(%e0_242) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %373 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %374 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      nvvm.cluster.wait
      cf.cond_br %237, ^bb39, ^bb239
    ^bb39:  // pred: ^bb38
      nvvm.setmaxregister  decrease 96
      %375 = arith.floordivsi %238, %c2_i32 : i32
      %int_tuple_248 = cute.make_int_tuple(%itup_247) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %376 = cute.get_scalars(%int_tuple_248) <{only_dynamic}> : !cute.int_tuple<"?">
      %377 = arith.ceildivsi %376, %c256_i32 : i32
      %int_tuple_249 = cute.make_int_tuple(%377) : (i32) -> !cute.int_tuple<"?">
      %e0_250 = cute.get_leaves(%int_tuple_249) : !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_250, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %378 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %coord_251 = cute.make_coord(%375, %373, %374) : (i32, i32, i32) -> !cute.coord<"(_,?,_,(?,?))">
      %379:5 = cute.get_scalars(%lay_146) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">
      %shape_252 = cute.make_shape(%379#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_253 = cute.make_layout(%shape_252, %172) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@0)">
      %idx_254 = cute.crd2idx(%coord_251, %lay_146) : (!cute.coord<"(_,?,_,(?,?))">, !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">) -> !cute.int_tuple<"(0,?{div=128},?,?,?)">
      %tup_255 = cute.add_offset(%tup, %idx_254) : (!cute.int_tuple<"(0,?{div=64},0,0,0)">, !cute.int_tuple<"(0,?{div=128},?,?,?)">) -> !cute.int_tuple<"(0,?{div=64},?,?,?)">
      %coord_256 = cute.make_coord(%373, %374) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %380:5 = cute.get_scalars(%lay_158) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">
      %shape_257 = cute.make_shape(%380#0, %380#1) : (i32, i32) -> !cute.shape<"(((64,128),1),?,?)">
      %lay_258 = cute.make_layout(%shape_257, %171) : !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">
      %idx_259 = cute.crd2idx(%coord_256, %lay_158) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">) -> !cute.int_tuple<"(0,0,?,?)">
      %tup_260 = cute.add_offset(%tup_152, %idx_259) : (!cute.int_tuple<"(0,?{div=128},0,0)">, !cute.int_tuple<"(0,0,?,?)">) -> !cute.int_tuple<"(0,?{div=128},?,?)">
      %coord_261 = cute.make_coord(%373, %374) : (i32, i32) -> !cute.coord<"(_,_,(?,?))">
      %381:4 = cute.get_scalars(%lay_183) <{only_dynamic}> : !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">
      %shape_262 = cute.make_shape(%381#0) : (i32) -> !cute.shape<"(((128,1),1),?)">
      %lay_263 = cute.make_layout(%shape_262, %170) : !cute.layout<"(((128,1),1),?):(((1@0,0),0),256@0)">
      %idx_264 = cute.crd2idx(%coord_261, %lay_183) : (!cute.coord<"(_,_,(?,?))">, !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(0,?,?)">
      %tup_265 = cute.add_offset(%int_tuple_184, %idx_264) : (!cute.int_tuple<"(?{div=128},0,0)">, !cute.int_tuple<"(0,?,?)">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %382:5 = cute.get_scalars(%lay_195) <{only_dynamic}> : !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">
      %shape_266 = cute.make_shape(%382#0, %382#1) : (i32, i32) -> !cute.shape<"(((64,64),2),?,?)">
      %lay_267 = cute.make_layout(%shape_266, %169) : !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">
      %idx_268 = cute.crd2idx(%coord_256, %lay_195) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">) -> !cute.int_tuple<"(0,0,?,?)">
      %tup_269 = cute.add_offset(%tup_189, %idx_268) : (!cute.int_tuple<"(?{div=128},0,0,0)">, !cute.int_tuple<"(0,0,?,?)">) -> !cute.int_tuple<"(?{div=128},0,?,?)">
      %383:4 = cute.get_scalars(%lay_212) <{only_dynamic}> : !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">
      %shape_270 = cute.make_shape(%383#0) : (i32) -> !cute.shape<"(((64,1),1),?)">
      %lay_271 = cute.make_layout(%shape_270, %168) : !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">
      %idx_272 = cute.crd2idx(%coord_261, %lay_212) : (!cute.coord<"(_,_,(?,?))">, !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(0,?,?)">
      %tup_273 = cute.add_offset(%189, %idx_272) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?,?)">) -> !cute.int_tuple<"(0,?,?)">
      %e0_274, %e1_275, %e2_276 = cute.get_leaves(%tup_265) : !cute.int_tuple<"(?{div=128},?,?)">
      %int_tuple_277 = cute.make_int_tuple(%e0_274, %e1_275, %e2_276) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %384 = cute_nvgpu.atom.make_exec_tma(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %385 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %386:3 = cute.get_scalars(%int_tuple_277) : !cute.int_tuple<"(?{div=128},?,?)">
      %387 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>
      %388 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %389 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %390 = cute_nvgpu.atom.make_exec_tma(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %391 = cute_nvgpu.atom.make_exec_tma(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %sub_278 = cute.tuple_sub(%sub, %212) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%sub_278, %209) : (!cute.int_tuple<"?">, !cute.int_tuple<"4">) -> !cute.int_tuple<"?{div=4}">
      %392 = cute_nvgpu.atom.make_exec_tma(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %mul_279 = cute.tuple_mul(%sub_278, %209) : (!cute.int_tuple<"?">, !cute.int_tuple<"4">) -> !cute.int_tuple<"?{div=4}">
      %393 = cute_nvgpu.atom.make_exec_tma(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      cf.br ^bb40(%c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %true : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb40(%394: i32, %395: i32, %396: i32, %397: i32, %398: i32, %399: i32, %400: i32, %401: i32, %402: i32, %403: i32, %404: i32, %405: i32, %406: i1):  // 2 preds: ^bb39, ^bb151
      cf.cond_br %406, ^bb41(%394, %395, %396, %397, %398, %399, %400, %401, %402, %403, %404, %405, %406 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1), ^bb152
    ^bb41(%407: i32, %408: i32, %409: i32, %410: i32, %411: i32, %412: i32, %413: i32, %414: i32, %415: i32, %416: i32, %417: i32, %418: i32, %419: i1):  // pred: ^bb40
      %int_tuple_280 = cute.make_int_tuple(%411) : (i32) -> !cute.int_tuple<"?">
      %ptr_281 = cute.add_offset(%ptr_65, %int_tuple_280) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %420 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %420, %412, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %421 = nvvm.elect.sync -> i1
      cf.cond_br %421, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %ptr_282 = cute.add_offset(%iter_60, %int_tuple_280) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %422 = builtin.unrealized_conversion_cast %ptr_282 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %422, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %423 = arith.addi %411, %c1_i32 : i32
      %424 = arith.addi %410, %c1_i32 : i32
      %425 = arith.cmpi eq, %423, %c5_i32 : i32
      %426 = arith.select %425, %c0_i32, %423 : i32
      cf.cond_br %425, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %427 = arith.xori %412, %c1_i32 : i32
      cf.br ^bb46(%427 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%412 : i32)
    ^bb46(%428: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_283 = cute.make_coord(%411) : (i32) -> !cute.coord<"(_,?)">
      %idx_284 = cute.crd2idx(%coord_283, %185) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),5):(((1,0),0),128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_285 = cute.add_offset(%iter_122, %idx_284) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem, align<256>>
      %ptr_286 = cute.add_offset(%iter_60, %int_tuple_280) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %429 = cute_nvgpu.atom.set_value(%384, %ptr_286 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %430 = cute_nvgpu.atom.get_value(%429 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %431 = cute_nvgpu.atom.get_value(%429 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%429 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%432: i32):  // 2 preds: ^bb47, ^bb49
      %433 = arith.cmpi slt, %432, %385 : i32
      cf.cond_br %433, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_285 : !cute.ptr<bf16, smem, align<256>>, %430 : !cute.ptr<smem, align<8>>, [%386#0, %386#1, %386#2] : i32, i32, i32) cache_policy = %431 mode = <tiled> num_cta = 1 : i32
      %434 = arith.addi %432, %c1_i32 : i32
      cf.br ^bb48(%434 : i32)
    ^bb50:  // pred: ^bb48
      cf.br ^bb51(%c0_i32, %413, %414, %415, %407, %408, %409 : i32, i32, i32, i32, i32, i32, i32)
    ^bb51(%435: i32, %436: i32, %437: i32, %438: i32, %439: i32, %440: i32, %441: i32):  // 2 preds: ^bb50, ^bb72
      %442 = arith.cmpi slt, %435, %c8_i32 : i32
      cf.cond_br %442, ^bb52, ^bb73 {loop_annotation = #loop_annotation1}
    ^bb52:  // pred: ^bb51
      %int_tuple_287 = cute.make_int_tuple(%437) : (i32) -> !cute.int_tuple<"?">
      %ptr_288 = cute.add_offset(%ptr_21, %int_tuple_287) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %443 = builtin.unrealized_conversion_cast %ptr_288 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %443, %438, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %277, ^bb53, ^bb56
    ^bb53:  // pred: ^bb52
      %444 = nvvm.elect.sync -> i1
      cf.cond_br %444, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %ptr_289 = cute.add_offset(%iter_13, %int_tuple_287) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %445 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %445, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // 2 preds: ^bb52, ^bb55
      %446 = arith.addi %437, %c1_i32 : i32
      %447 = arith.addi %436, %c1_i32 : i32
      %448 = arith.cmpi eq, %446, %c8_i32 : i32
      %449 = arith.select %448, %c0_i32, %446 : i32
      cf.cond_br %448, ^bb57, ^bb58
    ^bb57:  // pred: ^bb56
      %450 = arith.xori %438, %c1_i32 : i32
      cf.br ^bb59(%450 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb59(%438 : i32)
    ^bb59(%451: i32):  // 2 preds: ^bb57, ^bb58
      cf.br ^bb60
    ^bb60:  // pred: ^bb59
      %coord_290 = cute.make_coord(%435) : (i32) -> !cute.coord<"(_,?)">
      %idx_291 = cute.crd2idx(%coord_290, %lay_253) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_292 = cute.add_offset(%tup_255, %idx_291) : (!cute.int_tuple<"(0,?{div=64},?,?,?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%tup_292) : !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %coord_298 = cute.make_coord(%437) : (i32) -> !cute.coord<"(_,?)">
      %idx_299 = cute.crd2idx(%coord_298, %167) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),8):((1,0),4096)">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_300 = cute.add_offset(%iter_115, %idx_299) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %ptr_301 = cute.add_offset(%iter_13, %int_tuple_287) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_302 = cute.make_int_tuple(%e0_293, %e1_294, %e2_295, %e3_296, %e4_297) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %452 = cute_nvgpu.atom.set_value(%387, %ptr_301 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>
      %453 = cute_nvgpu.atom.get_value(%452 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %454 = cute_nvgpu.atom.get_value(%452 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_303 = cute_nvgpu.get_tma_desc_addr(%452 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) -> !cute.ptr<generic, align<64>>
      %455:5 = cute.get_scalars(%int_tuple_302) : !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      cf.br ^bb61(%c0_i32 : i32)
    ^bb61(%456: i32):  // 2 preds: ^bb60, ^bb62
      %457 = arith.cmpi slt, %456, %385 : i32
      cf.cond_br %457, ^bb62, ^bb63 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_303 : !cute.ptr<generic, align<64>>, %ptr_300 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>, %453 : !cute.ptr<smem, align<8>>, [%455#0, %455#1, %455#2, %455#3, %455#4] : i32, i32, i32, i32, i32) cache_policy = %454 mode = <tiled> num_cta = 2 : i32
      %458 = arith.addi %456, %c1_i32 : i32
      cf.br ^bb61(%458 : i32)
    ^bb63:  // pred: ^bb61
      %int_tuple_304 = cute.make_int_tuple(%440) : (i32) -> !cute.int_tuple<"?">
      %ptr_305 = cute.add_offset(%ptr_50, %int_tuple_304) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %459 = builtin.unrealized_conversion_cast %ptr_305 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %459, %441, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %460 = nvvm.elect.sync -> i1
      cf.cond_br %460, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      %ptr_306 = cute.add_offset(%iter_45, %int_tuple_304) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %461 = builtin.unrealized_conversion_cast %ptr_306 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %461, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %462 = arith.addi %440, %c1_i32 : i32
      %463 = arith.addi %439, %c1_i32 : i32
      %464 = arith.cmpi eq, %462, %c5_i32 : i32
      %465 = arith.select %464, %c0_i32, %462 : i32
      cf.cond_br %464, ^bb66, ^bb67
    ^bb66:  // pred: ^bb65
      %466 = arith.xori %441, %c1_i32 : i32
      cf.br ^bb68(%466 : i32)
    ^bb67:  // pred: ^bb65
      cf.br ^bb68(%441 : i32)
    ^bb68(%467: i32):  // 2 preds: ^bb66, ^bb67
      cf.br ^bb69
    ^bb69:  // pred: ^bb68
      %coord_307 = cute.make_coord(%435) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_308 = cute.crd2idx(%coord_307, %lay_258) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_309 = cute.add_offset(%tup_260, %idx_308) : (!cute.int_tuple<"(0,?{div=128},?,?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %e0_310, %e1_311, %e2_312, %e3_313 = cute.get_leaves(%tup_309) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %coord_314 = cute.make_coord(%440) : (i32) -> !cute.coord<"(_,?)">
      %idx_315 = cute.crd2idx(%coord_314, %166) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),5):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_316 = cute.add_offset(%iter_132, %idx_315) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %ptr_317 = cute.add_offset(%iter_45, %int_tuple_304) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_318 = cute.make_int_tuple(%e0_310, %e1_311, %e2_312, %e3_313) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %468 = cute_nvgpu.atom.set_value(%388, %ptr_317 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %469 = cute_nvgpu.atom.get_value(%468 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %470 = cute_nvgpu.atom.get_value(%468 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_319 = cute_nvgpu.get_tma_desc_addr(%468 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %471:4 = cute.get_scalars(%int_tuple_318) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      cf.br ^bb70(%c0_i32 : i32)
    ^bb70(%472: i32):  // 2 preds: ^bb69, ^bb71
      %473 = arith.cmpi slt, %472, %385 : i32
      cf.cond_br %473, ^bb71, ^bb72 {llvm.loop_annotation = #loop_annotation}
    ^bb71:  // pred: ^bb70
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_319 : !cute.ptr<generic, align<64>>, %ptr_316 : !cute.ptr<i8, smem, align<256>, S<2,4,3>>, %469 : !cute.ptr<smem, align<8>>, [%471#0, %471#1, %471#2, %471#3] : i32, i32, i32, i32) cache_policy = %470 mode = <tiled> num_cta = 1 : i32
      %474 = arith.addi %472, %c1_i32 : i32
      cf.br ^bb70(%474 : i32)
    ^bb72:  // pred: ^bb70
      %475 = arith.addi %435, %c1_i32 : i32
      cf.br ^bb51(%475, %447, %449, %451, %463, %465, %467 : i32, i32, i32, i32, i32, i32, i32)
    ^bb73:  // pred: ^bb51
      cf.br ^bb74(%c1_i32, %439, %440, %441, %424, %426, %428, %416, %417, %418 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb74(%476: i32, %477: i32, %478: i32, %479: i32, %480: i32, %481: i32, %482: i32, %483: i32, %484: i32, %485: i32):  // 2 preds: ^bb73, ^bb123
      %486 = arith.cmpi slt, %476, %378 : i32
      cf.cond_br %486, ^bb75, ^bb124 {loop_annotation = #loop_annotation2}
    ^bb75:  // pred: ^bb74
      %int_tuple_320 = cute.make_int_tuple(%481) : (i32) -> !cute.int_tuple<"?">
      %ptr_321 = cute.add_offset(%ptr_65, %int_tuple_320) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %487 = builtin.unrealized_conversion_cast %ptr_321 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %487, %482, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %488 = nvvm.elect.sync -> i1
      cf.cond_br %488, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %ptr_322 = cute.add_offset(%iter_60, %int_tuple_320) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %489 = builtin.unrealized_conversion_cast %ptr_322 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %489, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %490 = arith.addi %481, %c1_i32 : i32
      %491 = arith.addi %480, %c1_i32 : i32
      %492 = arith.cmpi eq, %490, %c5_i32 : i32
      %493 = arith.select %492, %c0_i32, %490 : i32
      cf.cond_br %492, ^bb78, ^bb79
    ^bb78:  // pred: ^bb77
      %494 = arith.xori %482, %c1_i32 : i32
      cf.br ^bb80(%494 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%482 : i32)
    ^bb80(%495: i32):  // 2 preds: ^bb78, ^bb79
      cf.br ^bb81
    ^bb81:  // pred: ^bb80
      %coord_323 = cute.make_coord(%476) : (i32) -> !cute.coord<"(_,?)">
      %idx_324 = cute.crd2idx(%coord_323, %lay_263) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),?):(((1@0,0),0),256@0)">) -> !cute.int_tuple<"(?{div=256})">
      %tup_325 = cute.add_offset(%tup_265, %idx_324) : (!cute.int_tuple<"(?{div=128},?,?)">, !cute.int_tuple<"(?{div=256})">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %e0_326, %e1_327, %e2_328 = cute.get_leaves(%tup_325) : !cute.int_tuple<"(?{div=128},?,?)">
      %coord_329 = cute.make_coord(%481) : (i32) -> !cute.coord<"(_,?)">
      %idx_330 = cute.crd2idx(%coord_329, %185) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),5):(((1,0),0),128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_331 = cute.add_offset(%iter_122, %idx_330) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem, align<256>>
      %ptr_332 = cute.add_offset(%iter_60, %int_tuple_320) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_333 = cute.make_int_tuple(%e0_326, %e1_327, %e2_328) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %496 = cute_nvgpu.atom.set_value(%384, %ptr_332 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %497 = cute_nvgpu.atom.get_value(%496 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %498 = cute_nvgpu.atom.get_value(%496 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_334 = cute_nvgpu.get_tma_desc_addr(%496 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      %499:3 = cute.get_scalars(%int_tuple_333) : !cute.int_tuple<"(?{div=128},?,?)">
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%500: i32):  // 2 preds: ^bb81, ^bb83
      %501 = arith.cmpi slt, %500, %385 : i32
      cf.cond_br %501, ^bb83, ^bb84 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_334 : !cute.ptr<generic, align<64>>, %ptr_331 : !cute.ptr<bf16, smem, align<256>>, %497 : !cute.ptr<smem, align<8>>, [%499#0, %499#1, %499#2] : i32, i32, i32) cache_policy = %498 mode = <tiled> num_cta = 1 : i32
      %502 = arith.addi %500, %c1_i32 : i32
      cf.br ^bb82(%502 : i32)
    ^bb84:  // pred: ^bb82
      cf.br ^bb85(%c0_i32, %477, %478, %479 : i32, i32, i32, i32)
    ^bb85(%503: i32, %504: i32, %505: i32, %506: i32):  // 2 preds: ^bb84, ^bb95
      %507 = arith.cmpi slt, %503, %c8_i32 : i32
      cf.cond_br %507, ^bb86, ^bb96 {loop_annotation = #loop_annotation1}
    ^bb86:  // pred: ^bb85
      %int_tuple_335 = cute.make_int_tuple(%505) : (i32) -> !cute.int_tuple<"?">
      %ptr_336 = cute.add_offset(%ptr_50, %int_tuple_335) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %508 = builtin.unrealized_conversion_cast %ptr_336 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %508, %506, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %509 = nvvm.elect.sync -> i1
      cf.cond_br %509, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %ptr_337 = cute.add_offset(%iter_45, %int_tuple_335) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %510 = builtin.unrealized_conversion_cast %ptr_337 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %510, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %511 = arith.addi %505, %c1_i32 : i32
      %512 = arith.addi %504, %c1_i32 : i32
      %513 = arith.cmpi eq, %511, %c5_i32 : i32
      %514 = arith.select %513, %c0_i32, %511 : i32
      cf.cond_br %513, ^bb89, ^bb90
    ^bb89:  // pred: ^bb88
      %515 = arith.xori %506, %c1_i32 : i32
      cf.br ^bb91(%515 : i32)
    ^bb90:  // pred: ^bb88
      cf.br ^bb91(%506 : i32)
    ^bb91(%516: i32):  // 2 preds: ^bb89, ^bb90
      cf.br ^bb92
    ^bb92:  // pred: ^bb91
      %coord_338 = cute.make_coord(%476, %503) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_339 = cute.crd2idx(%coord_338, %lay_258) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %tup_340 = cute.add_offset(%tup_260, %idx_339) : (!cute.int_tuple<"(0,?{div=128},?,?)">, !cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %e0_341, %e1_342, %e2_343, %e3_344 = cute.get_leaves(%tup_340) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %coord_345 = cute.make_coord(%505) : (i32) -> !cute.coord<"(_,?)">
      %idx_346 = cute.crd2idx(%coord_345, %166) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),5):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_347 = cute.add_offset(%iter_132, %idx_346) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %ptr_348 = cute.add_offset(%iter_45, %int_tuple_335) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_349 = cute.make_int_tuple(%e0_341, %e1_342, %e2_343, %e3_344) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %517 = cute_nvgpu.atom.set_value(%389, %ptr_348 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %518 = cute_nvgpu.atom.get_value(%517 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %519 = cute_nvgpu.atom.get_value(%517 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_350 = cute_nvgpu.get_tma_desc_addr(%517 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %520:4 = cute.get_scalars(%int_tuple_349) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%521: i32):  // 2 preds: ^bb92, ^bb94
      %522 = arith.cmpi slt, %521, %385 : i32
      cf.cond_br %522, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_350 : !cute.ptr<generic, align<64>>, %ptr_347 : !cute.ptr<i8, smem, align<256>, S<2,4,3>>, %518 : !cute.ptr<smem, align<8>>, [%520#0, %520#1, %520#2, %520#3] : i32, i32, i32, i32) cache_policy = %519 mode = <tiled> num_cta = 1 : i32
      %523 = arith.addi %521, %c1_i32 : i32
      cf.br ^bb93(%523 : i32)
    ^bb95:  // pred: ^bb93
      %524 = arith.addi %503, %c1_i32 : i32
      cf.br ^bb85(%524, %512, %514, %516 : i32, i32, i32, i32)
    ^bb96:  // pred: ^bb85
      %525 = arith.subi %476, %c1_i32 : i32
      %int_tuple_351 = cute.make_int_tuple(%484) : (i32) -> !cute.int_tuple<"?">
      %ptr_352 = cute.add_offset(%ptr_81, %int_tuple_351) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %526 = builtin.unrealized_conversion_cast %ptr_352 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %526, %485, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %527 = nvvm.elect.sync -> i1
      cf.cond_br %527, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      %ptr_353 = cute.add_offset(%iter_76, %int_tuple_351) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %528 = builtin.unrealized_conversion_cast %ptr_353 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %528, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %529 = arith.addi %484, %c1_i32 : i32
      %530 = arith.addi %483, %c1_i32 : i32
      %531 = arith.cmpi eq, %529, %c5_i32 : i32
      %532 = arith.select %531, %c0_i32, %529 : i32
      cf.cond_br %531, ^bb99, ^bb100
    ^bb99:  // pred: ^bb98
      %533 = arith.xori %485, %c1_i32 : i32
      cf.br ^bb101(%533 : i32)
    ^bb100:  // pred: ^bb98
      cf.br ^bb101(%485 : i32)
    ^bb101(%534: i32):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %535 = arith.muli %525, %c4_i32 : i32
      %ptr_354 = cute.add_offset(%iter_76, %int_tuple_351) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %536 = cute_nvgpu.atom.set_value(%390, %ptr_354 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %537 = cute_nvgpu.atom.get_value(%536 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %538 = cute_nvgpu.atom.get_value(%536 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_355 = cute_nvgpu.get_tma_desc_addr(%536 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%539: i32):  // 2 preds: ^bb102, ^bb107
      %540 = arith.cmpi slt, %539, %c4_i32 : i32
      cf.cond_br %540, ^bb104, ^bb108 {loop_annotation = #loop_annotation1}
    ^bb104:  // pred: ^bb103
      %541 = arith.addi %535, %539 : i32
      %coord_356 = cute.make_coord(%541) : (i32) -> !cute.coord<"(_,?)">
      %idx_357 = cute.crd2idx(%coord_356, %lay_271) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">) -> !cute.int_tuple<"(?{div=64})">
      %tup_358 = cute.add_offset(%tup_273, %idx_357) : (!cute.int_tuple<"(0,?,?)">, !cute.int_tuple<"(?{div=64})">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %e0_359, %e1_360, %e2_361 = cute.get_leaves(%tup_358) : !cute.int_tuple<"(?{div=64},?,?)">
      %coord_362 = cute.make_coord(%539, %484) : (i32, i32) -> !cute.coord<"(_,(?,?))">
      %idx_363 = cute.crd2idx(%coord_362, %177) : (!cute.coord<"(_,(?,?))">, !cute.layout<"(((64,1),1),(4,5)):(((1,0),0),(64,256))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_364 = cute.add_offset(%iter_125, %idx_363) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>>
      %int_tuple_365 = cute.make_int_tuple(%e0_359, %e1_360, %e2_361) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %542:3 = cute.get_scalars(%int_tuple_365) : !cute.int_tuple<"(?{div=64},?,?)">
      cf.br ^bb105(%c0_i32 : i32)
    ^bb105(%543: i32):  // 2 preds: ^bb104, ^bb106
      %544 = arith.cmpi slt, %543, %385 : i32
      cf.cond_br %544, ^bb106, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb106:  // pred: ^bb105
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_355 : !cute.ptr<generic, align<64>>, %ptr_364 : !cute.ptr<bf16, smem, align<128>>, %537 : !cute.ptr<smem, align<8>>, [%542#0, %542#1, %542#2] : i32, i32, i32) cache_policy = %538 mode = <tiled> num_cta = 1 : i32
      %545 = arith.addi %543, %c1_i32 : i32
      cf.br ^bb105(%545 : i32)
    ^bb107:  // pred: ^bb105
      %546 = arith.addi %539, %c1_i32 : i32
      cf.br ^bb103(%546 : i32)
    ^bb108:  // pred: ^bb103
      %547 = arith.muli %525, %c4_i32 : i32
      cf.br ^bb109(%c0_i32, %504, %505, %506 : i32, i32, i32, i32)
    ^bb109(%548: i32, %549: i32, %550: i32, %551: i32):  // 2 preds: ^bb108, ^bb122
      %552 = arith.cmpi slt, %548, %c4_i32 : i32
      cf.cond_br %552, ^bb110, ^bb123 {loop_annotation = #loop_annotation1}
    ^bb110:  // pred: ^bb109
      %553 = arith.addi %547, %548 : i32
      cf.br ^bb111(%c0_i32, %549, %550, %551 : i32, i32, i32, i32)
    ^bb111(%554: i32, %555: i32, %556: i32, %557: i32):  // 2 preds: ^bb110, ^bb121
      %558 = arith.cmpi slt, %554, %c2_i32 : i32
      cf.cond_br %558, ^bb112, ^bb122 {loop_annotation = #loop_annotation1}
    ^bb112:  // pred: ^bb111
      %int_tuple_366 = cute.make_int_tuple(%556) : (i32) -> !cute.int_tuple<"?">
      %ptr_367 = cute.add_offset(%ptr_50, %int_tuple_366) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %559 = builtin.unrealized_conversion_cast %ptr_367 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %559, %557, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %560 = nvvm.elect.sync -> i1
      cf.cond_br %560, ^bb113, ^bb114
    ^bb113:  // pred: ^bb112
      %ptr_368 = cute.add_offset(%iter_45, %int_tuple_366) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %561 = builtin.unrealized_conversion_cast %ptr_368 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %561, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb112, ^bb113
      %562 = arith.addi %556, %c1_i32 : i32
      %563 = arith.addi %555, %c1_i32 : i32
      %564 = arith.cmpi eq, %562, %c5_i32 : i32
      %565 = arith.select %564, %c0_i32, %562 : i32
      cf.cond_br %564, ^bb115, ^bb116
    ^bb115:  // pred: ^bb114
      %566 = arith.xori %557, %c1_i32 : i32
      cf.br ^bb117(%566 : i32)
    ^bb116:  // pred: ^bb114
      cf.br ^bb117(%557 : i32)
    ^bb117(%567: i32):  // 2 preds: ^bb115, ^bb116
      cf.br ^bb118
    ^bb118:  // pred: ^bb117
      %coord_369 = cute.make_coord(%554, %553) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_370 = cute.crd2idx(%coord_369, %lay_267) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">) -> !cute.int_tuple<"(?{div=256},?{div=64})">
      %tup_371 = cute.add_offset(%tup_269, %idx_370) : (!cute.int_tuple<"(?{div=128},0,?,?)">, !cute.int_tuple<"(?{div=256},?{div=64})">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %e0_372, %e1_373, %e2_374, %e3_375 = cute.get_leaves(%tup_371) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %coord_376 = cute.make_coord(%556) : (i32) -> !cute.coord<"(_,?)">
      %idx_377 = cute.crd2idx(%coord_376, %165) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,2),5):((1,4096),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_378 = cute.add_offset(%iter_133, %idx_377) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>>
      %ptr_379 = cute.add_offset(%iter_45, %int_tuple_366) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_380 = cute.make_int_tuple(%e0_372, %e1_373, %e2_374, %e3_375) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %568 = cute_nvgpu.atom.set_value(%391, %ptr_379 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %569 = cute_nvgpu.atom.get_value(%568 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %570 = cute_nvgpu.atom.get_value(%568 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_381 = cute_nvgpu.get_tma_desc_addr(%568 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %571:4 = cute.get_scalars(%int_tuple_380) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %tup_382 = cute.add_offset(%int_tuple_380, %164) : (!cute.int_tuple<"(?{div=128},?{div=64},?,?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      %ptr_383 = cute.add_offset(%ptr_378, %163) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"4096">) -> !cute.ptr<i8, smem, align<256>>
      %572:4 = cute.get_scalars(%tup_382) : !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      cf.br ^bb119(%c0_i32 : i32)
    ^bb119(%573: i32):  // 2 preds: ^bb118, ^bb120
      %574 = arith.cmpi slt, %573, %385 : i32
      cf.cond_br %574, ^bb120, ^bb121 {llvm.loop_annotation = #loop_annotation}
    ^bb120:  // pred: ^bb119
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_381 : !cute.ptr<generic, align<64>>, %ptr_378 : !cute.ptr<i8, smem, align<256>>, %569 : !cute.ptr<smem, align<8>>, [%571#0, %571#1, %571#2, %571#3] : i32, i32, i32, i32) cache_policy = %570 mode = <tiled> num_cta = 1 : i32
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_381 : !cute.ptr<generic, align<64>>, %ptr_383 : !cute.ptr<i8, smem, align<256>>, %569 : !cute.ptr<smem, align<8>>, [%572#0, %572#1, %572#2, %572#3] : i32, i32, i32, i32) cache_policy = %570 mode = <tiled> num_cta = 1 : i32
      %575 = arith.addi %573, %c1_i32 : i32
      cf.br ^bb119(%575 : i32)
    ^bb121:  // pred: ^bb119
      %576 = arith.addi %554, %c1_i32 : i32
      cf.br ^bb111(%576, %563, %565, %567 : i32, i32, i32, i32)
    ^bb122:  // pred: ^bb111
      %577 = arith.addi %548, %c1_i32 : i32
      cf.br ^bb109(%577, %555, %556, %557 : i32, i32, i32, i32)
    ^bb123:  // pred: ^bb109
      %578 = arith.addi %476, %c1_i32 : i32
      cf.br ^bb74(%578, %549, %550, %551, %491, %493, %495, %530, %532, %534 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb124:  // pred: ^bb74
      %int_tuple_384 = cute.make_int_tuple(%484) : (i32) -> !cute.int_tuple<"?">
      %ptr_385 = cute.add_offset(%ptr_81, %int_tuple_384) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %579 = builtin.unrealized_conversion_cast %ptr_385 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %579, %485, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %580 = nvvm.elect.sync -> i1
      cf.cond_br %580, ^bb125, ^bb126
    ^bb125:  // pred: ^bb124
      %ptr_386 = cute.add_offset(%iter_76, %int_tuple_384) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %581 = builtin.unrealized_conversion_cast %ptr_386 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %581, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb126
    ^bb126:  // 2 preds: ^bb124, ^bb125
      %582 = arith.addi %484, %c1_i32 : i32
      %583 = arith.addi %483, %c1_i32 : i32
      %584 = arith.cmpi eq, %582, %c5_i32 : i32
      %585 = arith.select %584, %c0_i32, %582 : i32
      cf.cond_br %584, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %586 = arith.xori %485, %c1_i32 : i32
      cf.br ^bb129(%586 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%485 : i32)
    ^bb129(%587: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %ptr_387 = cute.add_offset(%iter_76, %int_tuple_384) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %588 = cute_nvgpu.atom.set_value(%392, %ptr_387 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %589 = cute_nvgpu.atom.get_value(%588 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %590 = cute_nvgpu.atom.get_value(%588 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_388 = cute_nvgpu.get_tma_desc_addr(%588 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%591: i32):  // 2 preds: ^bb130, ^bb135
      %592 = arith.cmpi slt, %591, %c4_i32 : i32
      cf.cond_br %592, ^bb132, ^bb136 {loop_annotation = #loop_annotation1}
    ^bb132:  // pred: ^bb131
      %int_tuple_389 = cute.make_int_tuple(%591) : (i32) -> !cute.int_tuple<"?">
      %tup_390 = cute.add_offset(%mul, %int_tuple_389) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %coord_391 = cute.make_coord(%tup_390) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?)">
      %idx_392 = cute.crd2idx(%coord_391, %lay_271) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">) -> !cute.int_tuple<"(?{div=64})">
      %tup_393 = cute.add_offset(%tup_273, %idx_392) : (!cute.int_tuple<"(0,?,?)">, !cute.int_tuple<"(?{div=64})">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %e0_394, %e1_395, %e2_396 = cute.get_leaves(%tup_393) : !cute.int_tuple<"(?{div=64},?,?)">
      %coord_397 = cute.make_coord(%591, %484) : (i32, i32) -> !cute.coord<"(_,(?,?))">
      %idx_398 = cute.crd2idx(%coord_397, %177) : (!cute.coord<"(_,(?,?))">, !cute.layout<"(((64,1),1),(4,5)):(((1,0),0),(64,256))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_399 = cute.add_offset(%iter_125, %idx_398) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>>
      %int_tuple_400 = cute.make_int_tuple(%e0_394, %e1_395, %e2_396) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %593:3 = cute.get_scalars(%int_tuple_400) : !cute.int_tuple<"(?{div=64},?,?)">
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%594: i32):  // 2 preds: ^bb132, ^bb134
      %595 = arith.cmpi slt, %594, %385 : i32
      cf.cond_br %595, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_388 : !cute.ptr<generic, align<64>>, %ptr_399 : !cute.ptr<bf16, smem, align<128>>, %589 : !cute.ptr<smem, align<8>>, [%593#0, %593#1, %593#2] : i32, i32, i32) cache_policy = %590 mode = <tiled> num_cta = 1 : i32
      %596 = arith.addi %594, %c1_i32 : i32
      cf.br ^bb133(%596 : i32)
    ^bb135:  // pred: ^bb133
      %597 = arith.addi %591, %c1_i32 : i32
      cf.br ^bb131(%597 : i32)
    ^bb136:  // pred: ^bb131
      cf.br ^bb137(%c0_i32, %477, %478, %479 : i32, i32, i32, i32)
    ^bb137(%598: i32, %599: i32, %600: i32, %601: i32):  // 2 preds: ^bb136, ^bb150
      %602 = arith.cmpi slt, %598, %c4_i32 : i32
      cf.cond_br %602, ^bb138, ^bb151 {loop_annotation = #loop_annotation1}
    ^bb138:  // pred: ^bb137
      %int_tuple_401 = cute.make_int_tuple(%598) : (i32) -> !cute.int_tuple<"?">
      %tup_402 = cute.add_offset(%mul_279, %int_tuple_401) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      cf.br ^bb139(%c0_i32, %599, %600, %601 : i32, i32, i32, i32)
    ^bb139(%603: i32, %604: i32, %605: i32, %606: i32):  // 2 preds: ^bb138, ^bb149
      %607 = arith.cmpi slt, %603, %c2_i32 : i32
      cf.cond_br %607, ^bb140, ^bb150 {loop_annotation = #loop_annotation1}
    ^bb140:  // pred: ^bb139
      %int_tuple_403 = cute.make_int_tuple(%605) : (i32) -> !cute.int_tuple<"?">
      %ptr_404 = cute.add_offset(%ptr_50, %int_tuple_403) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %608 = builtin.unrealized_conversion_cast %ptr_404 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %608, %606, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %609 = nvvm.elect.sync -> i1
      cf.cond_br %609, ^bb141, ^bb142
    ^bb141:  // pred: ^bb140
      %ptr_405 = cute.add_offset(%iter_45, %int_tuple_403) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %610 = builtin.unrealized_conversion_cast %ptr_405 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %610, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb142
    ^bb142:  // 2 preds: ^bb140, ^bb141
      %611 = arith.addi %605, %c1_i32 : i32
      %612 = arith.addi %604, %c1_i32 : i32
      %613 = arith.cmpi eq, %611, %c5_i32 : i32
      %614 = arith.select %613, %c0_i32, %611 : i32
      cf.cond_br %613, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %615 = arith.xori %606, %c1_i32 : i32
      cf.br ^bb145(%615 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%606 : i32)
    ^bb145(%616: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %coord_406 = cute.make_coord(%603, %tup_402) : (i32, !cute.int_tuple<"?">) -> !cute.coord<"(_,?,?)">
      %idx_407 = cute.crd2idx(%coord_406, %lay_267) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">) -> !cute.int_tuple<"(?{div=256},?{div=64})">
      %tup_408 = cute.add_offset(%tup_269, %idx_407) : (!cute.int_tuple<"(?{div=128},0,?,?)">, !cute.int_tuple<"(?{div=256},?{div=64})">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %e0_409, %e1_410, %e2_411, %e3_412 = cute.get_leaves(%tup_408) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %coord_413 = cute.make_coord(%605) : (i32) -> !cute.coord<"(_,?)">
      %idx_414 = cute.crd2idx(%coord_413, %165) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,2),5):((1,4096),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_415 = cute.add_offset(%iter_133, %idx_414) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>>
      %ptr_416 = cute.add_offset(%iter_45, %int_tuple_403) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_417 = cute.make_int_tuple(%e0_409, %e1_410, %e2_411, %e3_412) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %617 = cute_nvgpu.atom.set_value(%393, %ptr_416 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %618 = cute_nvgpu.atom.get_value(%617 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %619 = cute_nvgpu.atom.get_value(%617 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_418 = cute_nvgpu.get_tma_desc_addr(%617 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %620:4 = cute.get_scalars(%int_tuple_417) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %tup_419 = cute.add_offset(%int_tuple_417, %164) : (!cute.int_tuple<"(?{div=128},?{div=64},?,?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      %ptr_420 = cute.add_offset(%ptr_415, %163) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"4096">) -> !cute.ptr<i8, smem, align<256>>
      %621:4 = cute.get_scalars(%tup_419) : !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%622: i32):  // 2 preds: ^bb146, ^bb148
      %623 = arith.cmpi slt, %622, %385 : i32
      cf.cond_br %623, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation}
    ^bb148:  // pred: ^bb147
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_418 : !cute.ptr<generic, align<64>>, %ptr_415 : !cute.ptr<i8, smem, align<256>>, %618 : !cute.ptr<smem, align<8>>, [%620#0, %620#1, %620#2, %620#3] : i32, i32, i32, i32) cache_policy = %619 mode = <tiled> num_cta = 1 : i32
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_418 : !cute.ptr<generic, align<64>>, %ptr_420 : !cute.ptr<i8, smem, align<256>>, %618 : !cute.ptr<smem, align<8>>, [%621#0, %621#1, %621#2, %621#3] : i32, i32, i32, i32) cache_policy = %619 mode = <tiled> num_cta = 1 : i32
      %624 = arith.addi %622, %c1_i32 : i32
      cf.br ^bb147(%624 : i32)
    ^bb149:  // pred: ^bb147
      %625 = arith.addi %603, %c1_i32 : i32
      cf.br ^bb139(%625, %612, %614, %616 : i32, i32, i32, i32)
    ^bb150:  // pred: ^bb139
      %626 = arith.addi %598, %c1_i32 : i32
      cf.br ^bb137(%626, %604, %605, %606 : i32, i32, i32, i32)
    ^bb151:  // pred: ^bb137
      cf.br ^bb40(%599, %600, %601, %480, %481, %482, %436, %437, %438, %583, %585, %587, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb152:  // pred: ^bb40
      %627 = arith.addi %395, %c1_i32 : i32
      %628 = arith.cmpi eq, %627, %c5_i32 : i32
      %629 = arith.select %628, %c0_i32, %627 : i32
      cf.cond_br %628, ^bb153, ^bb154
    ^bb153:  // pred: ^bb152
      %630 = arith.xori %396, %c1_i32 : i32
      cf.br ^bb155(%630 : i32)
    ^bb154:  // pred: ^bb152
      cf.br ^bb155(%396 : i32)
    ^bb155(%631: i32):  // 2 preds: ^bb153, ^bb154
      cf.br ^bb156
    ^bb156:  // pred: ^bb155
      %632 = arith.addi %629, %c1_i32 : i32
      %633 = arith.cmpi eq, %632, %c5_i32 : i32
      %634 = arith.select %633, %c0_i32, %632 : i32
      cf.cond_br %633, ^bb157, ^bb158
    ^bb157:  // pred: ^bb156
      %635 = arith.xori %631, %c1_i32 : i32
      cf.br ^bb159(%635 : i32)
    ^bb158:  // pred: ^bb156
      cf.br ^bb159(%631 : i32)
    ^bb159(%636: i32):  // 2 preds: ^bb157, ^bb158
      cf.br ^bb160
    ^bb160:  // pred: ^bb159
      %637 = arith.addi %634, %c1_i32 : i32
      %638 = arith.cmpi eq, %637, %c5_i32 : i32
      %639 = arith.select %638, %c0_i32, %637 : i32
      cf.cond_br %638, ^bb161, ^bb162
    ^bb161:  // pred: ^bb160
      %640 = arith.xori %636, %c1_i32 : i32
      cf.br ^bb163(%640 : i32)
    ^bb162:  // pred: ^bb160
      cf.br ^bb163(%636 : i32)
    ^bb163(%641: i32):  // 2 preds: ^bb161, ^bb162
      cf.br ^bb164
    ^bb164:  // pred: ^bb163
      %642 = arith.addi %639, %c1_i32 : i32
      %643 = arith.cmpi eq, %642, %c5_i32 : i32
      %644 = arith.select %643, %c0_i32, %642 : i32
      cf.cond_br %643, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %645 = arith.xori %641, %c1_i32 : i32
      cf.br ^bb167(%645 : i32)
    ^bb166:  // pred: ^bb164
      cf.br ^bb167(%641 : i32)
    ^bb167(%646: i32):  // 2 preds: ^bb165, ^bb166
      cf.br ^bb168
    ^bb168:  // pred: ^bb167
      %int_tuple_421 = cute.make_int_tuple(%644) : (i32) -> !cute.int_tuple<"?">
      %ptr_422 = cute.add_offset(%ptr_50, %int_tuple_421) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %647 = builtin.unrealized_conversion_cast %ptr_422 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %647, %646, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %648 = nvvm.elect.sync -> i1
      cf.cond_br %648, ^bb169, ^bb170
    ^bb169:  // pred: ^bb168
      %ptr_423 = cute.add_offset(%iter_45, %int_tuple_421) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %649 = builtin.unrealized_conversion_cast %ptr_423 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %649, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb170
    ^bb170:  // 2 preds: ^bb168, ^bb169
      %650 = arith.addi %398, %c1_i32 : i32
      %651 = arith.cmpi eq, %650, %c5_i32 : i32
      %652 = arith.select %651, %c0_i32, %650 : i32
      cf.cond_br %651, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      %653 = arith.xori %399, %c1_i32 : i32
      cf.br ^bb173(%653 : i32)
    ^bb172:  // pred: ^bb170
      cf.br ^bb173(%399 : i32)
    ^bb173(%654: i32):  // 2 preds: ^bb171, ^bb172
      cf.br ^bb174
    ^bb174:  // pred: ^bb173
      %655 = arith.addi %652, %c1_i32 : i32
      %656 = arith.cmpi eq, %655, %c5_i32 : i32
      %657 = arith.select %656, %c0_i32, %655 : i32
      cf.cond_br %656, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      %658 = arith.xori %654, %c1_i32 : i32
      cf.br ^bb177(%658 : i32)
    ^bb176:  // pred: ^bb174
      cf.br ^bb177(%654 : i32)
    ^bb177(%659: i32):  // 2 preds: ^bb175, ^bb176
      cf.br ^bb178
    ^bb178:  // pred: ^bb177
      %660 = arith.addi %657, %c1_i32 : i32
      %661 = arith.cmpi eq, %660, %c5_i32 : i32
      %662 = arith.select %661, %c0_i32, %660 : i32
      cf.cond_br %661, ^bb179, ^bb180
    ^bb179:  // pred: ^bb178
      %663 = arith.xori %659, %c1_i32 : i32
      cf.br ^bb181(%663 : i32)
    ^bb180:  // pred: ^bb178
      cf.br ^bb181(%659 : i32)
    ^bb181(%664: i32):  // 2 preds: ^bb179, ^bb180
      cf.br ^bb182
    ^bb182:  // pred: ^bb181
      %665 = arith.addi %662, %c1_i32 : i32
      %666 = arith.cmpi eq, %665, %c5_i32 : i32
      %667 = arith.select %666, %c0_i32, %665 : i32
      cf.cond_br %666, ^bb183, ^bb184
    ^bb183:  // pred: ^bb182
      %668 = arith.xori %664, %c1_i32 : i32
      cf.br ^bb185(%668 : i32)
    ^bb184:  // pred: ^bb182
      cf.br ^bb185(%664 : i32)
    ^bb185(%669: i32):  // 2 preds: ^bb183, ^bb184
      cf.br ^bb186
    ^bb186:  // pred: ^bb185
      %int_tuple_424 = cute.make_int_tuple(%667) : (i32) -> !cute.int_tuple<"?">
      %ptr_425 = cute.add_offset(%ptr_65, %int_tuple_424) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %670 = builtin.unrealized_conversion_cast %ptr_425 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %670, %669, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %671 = nvvm.elect.sync -> i1
      cf.cond_br %671, ^bb187, ^bb188
    ^bb187:  // pred: ^bb186
      %ptr_426 = cute.add_offset(%iter_60, %int_tuple_424) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %672 = builtin.unrealized_conversion_cast %ptr_426 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %672, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb188
    ^bb188:  // 2 preds: ^bb186, ^bb187
      %673 = arith.addi %404, %c1_i32 : i32
      %674 = arith.cmpi eq, %673, %c5_i32 : i32
      %675 = arith.select %674, %c0_i32, %673 : i32
      cf.cond_br %674, ^bb189, ^bb190
    ^bb189:  // pred: ^bb188
      %676 = arith.xori %405, %c1_i32 : i32
      cf.br ^bb191(%676 : i32)
    ^bb190:  // pred: ^bb188
      cf.br ^bb191(%405 : i32)
    ^bb191(%677: i32):  // 2 preds: ^bb189, ^bb190
      cf.br ^bb192
    ^bb192:  // pred: ^bb191
      %678 = arith.addi %675, %c1_i32 : i32
      %679 = arith.cmpi eq, %678, %c5_i32 : i32
      %680 = arith.select %679, %c0_i32, %678 : i32
      cf.cond_br %679, ^bb193, ^bb194
    ^bb193:  // pred: ^bb192
      %681 = arith.xori %677, %c1_i32 : i32
      cf.br ^bb195(%681 : i32)
    ^bb194:  // pred: ^bb192
      cf.br ^bb195(%677 : i32)
    ^bb195(%682: i32):  // 2 preds: ^bb193, ^bb194
      cf.br ^bb196
    ^bb196:  // pred: ^bb195
      %683 = arith.addi %680, %c1_i32 : i32
      %684 = arith.cmpi eq, %683, %c5_i32 : i32
      %685 = arith.select %684, %c0_i32, %683 : i32
      cf.cond_br %684, ^bb197, ^bb198
    ^bb197:  // pred: ^bb196
      %686 = arith.xori %682, %c1_i32 : i32
      cf.br ^bb199(%686 : i32)
    ^bb198:  // pred: ^bb196
      cf.br ^bb199(%682 : i32)
    ^bb199(%687: i32):  // 2 preds: ^bb197, ^bb198
      cf.br ^bb200
    ^bb200:  // pred: ^bb199
      %688 = arith.addi %685, %c1_i32 : i32
      %689 = arith.cmpi eq, %688, %c5_i32 : i32
      %690 = arith.select %689, %c0_i32, %688 : i32
      cf.cond_br %689, ^bb201, ^bb202
    ^bb201:  // pred: ^bb200
      %691 = arith.xori %687, %c1_i32 : i32
      cf.br ^bb203(%691 : i32)
    ^bb202:  // pred: ^bb200
      cf.br ^bb203(%687 : i32)
    ^bb203(%692: i32):  // 2 preds: ^bb201, ^bb202
      cf.br ^bb204
    ^bb204:  // pred: ^bb203
      %int_tuple_427 = cute.make_int_tuple(%690) : (i32) -> !cute.int_tuple<"?">
      %ptr_428 = cute.add_offset(%ptr_81, %int_tuple_427) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %693 = builtin.unrealized_conversion_cast %ptr_428 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %693, %692, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %694 = nvvm.elect.sync -> i1
      cf.cond_br %694, ^bb205, ^bb206
    ^bb205:  // pred: ^bb204
      %ptr_429 = cute.add_offset(%iter_76, %int_tuple_427) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %695 = builtin.unrealized_conversion_cast %ptr_429 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %695, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb206
    ^bb206:  // 2 preds: ^bb204, ^bb205
      %696 = arith.addi %401, %c1_i32 : i32
      %697 = arith.cmpi eq, %696, %c8_i32 : i32
      %698 = arith.select %697, %c0_i32, %696 : i32
      cf.cond_br %697, ^bb207, ^bb208
    ^bb207:  // pred: ^bb206
      %699 = arith.xori %402, %c1_i32 : i32
      cf.br ^bb209(%699 : i32)
    ^bb208:  // pred: ^bb206
      cf.br ^bb209(%402 : i32)
    ^bb209(%700: i32):  // 2 preds: ^bb207, ^bb208
      cf.br ^bb210
    ^bb210:  // pred: ^bb209
      %701 = arith.addi %698, %c1_i32 : i32
      %702 = arith.cmpi eq, %701, %c8_i32 : i32
      %703 = arith.select %702, %c0_i32, %701 : i32
      cf.cond_br %702, ^bb211, ^bb212
    ^bb211:  // pred: ^bb210
      %704 = arith.xori %700, %c1_i32 : i32
      cf.br ^bb213(%704 : i32)
    ^bb212:  // pred: ^bb210
      cf.br ^bb213(%700 : i32)
    ^bb213(%705: i32):  // 2 preds: ^bb211, ^bb212
      cf.br ^bb214
    ^bb214:  // pred: ^bb213
      %706 = arith.addi %703, %c1_i32 : i32
      %707 = arith.cmpi eq, %706, %c8_i32 : i32
      %708 = arith.select %707, %c0_i32, %706 : i32
      cf.cond_br %707, ^bb215, ^bb216
    ^bb215:  // pred: ^bb214
      %709 = arith.xori %705, %c1_i32 : i32
      cf.br ^bb217(%709 : i32)
    ^bb216:  // pred: ^bb214
      cf.br ^bb217(%705 : i32)
    ^bb217(%710: i32):  // 2 preds: ^bb215, ^bb216
      cf.br ^bb218
    ^bb218:  // pred: ^bb217
      %711 = arith.addi %708, %c1_i32 : i32
      %712 = arith.cmpi eq, %711, %c8_i32 : i32
      %713 = arith.select %712, %c0_i32, %711 : i32
      cf.cond_br %712, ^bb219, ^bb220
    ^bb219:  // pred: ^bb218
      %714 = arith.xori %710, %c1_i32 : i32
      cf.br ^bb221(%714 : i32)
    ^bb220:  // pred: ^bb218
      cf.br ^bb221(%710 : i32)
    ^bb221(%715: i32):  // 2 preds: ^bb219, ^bb220
      cf.br ^bb222
    ^bb222:  // pred: ^bb221
      %716 = arith.addi %713, %c1_i32 : i32
      %717 = arith.cmpi eq, %716, %c8_i32 : i32
      %718 = arith.select %717, %c0_i32, %716 : i32
      cf.cond_br %717, ^bb223, ^bb224
    ^bb223:  // pred: ^bb222
      %719 = arith.xori %715, %c1_i32 : i32
      cf.br ^bb225(%719 : i32)
    ^bb224:  // pred: ^bb222
      cf.br ^bb225(%715 : i32)
    ^bb225(%720: i32):  // 2 preds: ^bb223, ^bb224
      cf.br ^bb226
    ^bb226:  // pred: ^bb225
      %721 = arith.addi %718, %c1_i32 : i32
      %722 = arith.cmpi eq, %721, %c8_i32 : i32
      %723 = arith.select %722, %c0_i32, %721 : i32
      cf.cond_br %722, ^bb227, ^bb228
    ^bb227:  // pred: ^bb226
      %724 = arith.xori %720, %c1_i32 : i32
      cf.br ^bb229(%724 : i32)
    ^bb228:  // pred: ^bb226
      cf.br ^bb229(%720 : i32)
    ^bb229(%725: i32):  // 2 preds: ^bb227, ^bb228
      cf.br ^bb230
    ^bb230:  // pred: ^bb229
      %726 = arith.addi %723, %c1_i32 : i32
      %727 = arith.cmpi eq, %726, %c8_i32 : i32
      %728 = arith.select %727, %c0_i32, %726 : i32
      cf.cond_br %727, ^bb231, ^bb232
    ^bb231:  // pred: ^bb230
      %729 = arith.xori %725, %c1_i32 : i32
      cf.br ^bb233(%729 : i32)
    ^bb232:  // pred: ^bb230
      cf.br ^bb233(%725 : i32)
    ^bb233(%730: i32):  // 2 preds: ^bb231, ^bb232
      cf.br ^bb234
    ^bb234:  // pred: ^bb233
      %int_tuple_430 = cute.make_int_tuple(%728) : (i32) -> !cute.int_tuple<"?">
      %ptr_431 = cute.add_offset(%ptr_21, %int_tuple_430) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %731 = builtin.unrealized_conversion_cast %ptr_431 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %731, %730, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %277, ^bb235, ^bb238
    ^bb235:  // pred: ^bb234
      %732 = nvvm.elect.sync -> i1
      cf.cond_br %732, ^bb236, ^bb237
    ^bb236:  // pred: ^bb235
      %ptr_432 = cute.add_offset(%iter_13, %int_tuple_430) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %733 = builtin.unrealized_conversion_cast %ptr_432 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %733, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      cf.br ^bb238
    ^bb238:  // 2 preds: ^bb234, ^bb237
      cf.br ^bb240(%406 : i1)
    ^bb239:  // pred: ^bb38
      cf.br ^bb240(%true : i1)
    ^bb240(%734: i1):  // 2 preds: ^bb238, ^bb239
      cf.br ^bb241
    ^bb241:  // pred: ^bb240
      %735 = arith.cmpi eq, %236, %c12_i32 : i32
      cf.cond_br %735, ^bb242, ^bb529
    ^bb242:  // pred: ^bb241
      cf.cond_br %326, ^bb243, ^bb246
    ^bb243:  // pred: ^bb242
      %736 = nvvm.elect.sync -> i1
      cf.cond_br %736, ^bb244, ^bb245
    ^bb244:  // pred: ^bb243
      %737 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %737, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb245
    ^bb245:  // 2 preds: ^bb243, ^bb244
      cf.br ^bb246
    ^bb246:  // 2 preds: ^bb242, ^bb245
      nvvm.fence.mbarrier.init
      nvvm.setmaxregister  decrease 96
      nvvm.barrier id = %c1_i32 number_of_threads = %c160_i32
      %int_tuple_433 = cute.make_int_tuple(%itup_247) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %738 = cute.get_scalars(%int_tuple_433) <{only_dynamic}> : !cute.int_tuple<"?">
      %739 = arith.ceildivsi %738, %c256_i32 : i32
      %int_tuple_434 = cute.make_int_tuple(%739) : (i32) -> !cute.int_tuple<"?">
      %e0_435 = cute.get_leaves(%int_tuple_434) : !cute.int_tuple<"?">
      %sub_436 = cute.tuple_sub(%e0_435, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %740 = cute.get_scalars(%sub_436) : !cute.int_tuple<"?">
      %741 = arith.cmpi sgt, %740, %c1_i32 : i32
      %742 = arith.remsi %258, %c2_i32 : i32
      %743 = arith.cmpi eq, %742, %c0_i32 : i32
      cf.br ^bb247(%c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %0, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %734 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1)
    ^bb247(%744: i32, %745: i32, %746: i32, %747: i32, %748: i32, %749: i32, %750: i32, %751: i32, %752: i32, %753: !llvm.struct<(i1, i1, i1)>, %754: i32, %755: i32, %756: i32, %757: i32, %758: i32, %759: i32, %760: i1):  // 2 preds: ^bb246, ^bb519
      cf.cond_br %760, ^bb248(%744, %745, %746, %747, %748, %749, %750, %751, %752, %753, %754, %755, %756, %757, %758, %759, %760 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1), ^bb520
    ^bb248(%761: i32, %762: i32, %763: i32, %764: i32, %765: i32, %766: i32, %767: i32, %768: i32, %769: i32, %770: !llvm.struct<(i1, i1, i1)>, %771: i32, %772: i32, %773: i32, %774: i32, %775: i32, %776: i32, %777: i1):  // pred: ^bb247
      %778 = builtin.unrealized_conversion_cast %770 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %779 = cute_nvgpu.atom.set_value(%778, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %780 = builtin.unrealized_conversion_cast %779 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      cf.cond_br %741, ^bb249, ^bb436
    ^bb249:  // pred: ^bb248
      %781 = arith.remsi %258, %c2_i32 : i32
      %782 = arith.cmpi eq, %781, %c0_i32 : i32
      cf.cond_br %782, ^bb250, ^bb282
    ^bb250:  // pred: ^bb249
      %int_tuple_437 = cute.make_int_tuple(%762) : (i32) -> !cute.int_tuple<"?">
      %ptr_438 = cute.add_offset(%ptr_103, %int_tuple_437) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %783 = builtin.unrealized_conversion_cast %ptr_438 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %783, %763, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %784 = arith.addi %762, %c1_i32 : i32
      %785 = arith.addi %761, %c1_i32 : i32
      %786 = arith.cmpi eq, %784, %c2_i32 : i32
      %787 = arith.select %786, %c0_i32, %784 : i32
      cf.cond_br %786, ^bb251, ^bb252
    ^bb251:  // pred: ^bb250
      %788 = arith.xori %763, %c1_i32 : i32
      cf.br ^bb253(%788 : i32)
    ^bb252:  // pred: ^bb250
      cf.br ^bb253(%763 : i32)
    ^bb253(%789: i32):  // 2 preds: ^bb251, ^bb252
      cf.br ^bb254
    ^bb254:  // pred: ^bb253
      %coord_439 = cute.make_coord(%762) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_440 = cute.crd2idx(%coord_439, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_441 = cute.add_offset(%329, %idx_440) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %790 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %791 = builtin.unrealized_conversion_cast %790 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %792 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb255(%c0_i32, %764, %765, %766, %767, %768, %769, %791 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb255(%793: i32, %794: i32, %795: i32, %796: i32, %797: i32, %798: i32, %799: i32, %800: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb254, ^bb278
      %801 = arith.cmpi slt, %793, %c8_i32 : i32
      cf.cond_br %801, ^bb256, ^bb279 {loop_annotation = #loop_annotation3}
    ^bb256:  // pred: ^bb255
      %int_tuple_442 = cute.make_int_tuple(%795) : (i32) -> !cute.int_tuple<"?">
      %ptr_443 = cute.add_offset(%iter_13, %int_tuple_442) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %802 = builtin.unrealized_conversion_cast %ptr_443 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %802, %796, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %803 = arith.addi %795, %c1_i32 : i32
      %804 = arith.addi %794, %c1_i32 : i32
      %805 = arith.cmpi eq, %803, %c8_i32 : i32
      %806 = arith.select %805, %c0_i32, %803 : i32
      cf.cond_br %805, ^bb257, ^bb258
    ^bb257:  // pred: ^bb256
      %807 = arith.xori %796, %c1_i32 : i32
      cf.br ^bb259(%807 : i32)
    ^bb258:  // pred: ^bb256
      cf.br ^bb259(%796 : i32)
    ^bb259(%808: i32):  // 2 preds: ^bb257, ^bb258
      cf.br ^bb260
    ^bb260:  // pred: ^bb259
      %coord_444 = cute.make_coord(%793) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_445 = cute.crd2idx(%coord_444, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_446 = cute.add_offset(%ummaSmemDesc, %idx_445) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_447 = cute.make_int_tuple(%798) : (i32) -> !cute.int_tuple<"?">
      %ptr_448 = cute.add_offset(%iter_92, %int_tuple_447) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %809 = builtin.unrealized_conversion_cast %ptr_448 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %809, %799, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %810 = arith.addi %798, %c1_i32 : i32
      %811 = arith.addi %797, %c1_i32 : i32
      %812 = arith.cmpi eq, %810, %c3_i32 : i32
      %813 = arith.select %812, %c0_i32, %810 : i32
      cf.cond_br %812, ^bb261, ^bb262
    ^bb261:  // pred: ^bb260
      %814 = arith.xori %799, %c1_i32 : i32
      cf.br ^bb263(%814 : i32)
    ^bb262:  // pred: ^bb260
      cf.br ^bb263(%799 : i32)
    ^bb263(%815: i32):  // 2 preds: ^bb261, ^bb262
      cf.br ^bb264
    ^bb264:  // pred: ^bb263
      %coord_449 = cute.make_coord(%798) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_450 = cute.crd2idx(%coord_449, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_451 = cute.add_offset(%ummaSmemDesc_135, %idx_450) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb265(%c0_i32, %800 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb265(%816: i32, %817: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb264, ^bb275
      %818 = arith.cmpi slt, %816, %c4_i32 : i32
      cf.cond_br %818, ^bb266, ^bb276 {loop_annotation = #loop_annotation1}
    ^bb266:  // pred: ^bb265
      %819 = builtin.unrealized_conversion_cast %817 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_452 = cute.make_coord(%816) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_453 = cute.crd2idx(%coord_452, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_454 = cute.add_offset(%tup_446, %idx_453) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_455 = cute.add_offset(%tup_451, %idx_453) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %820 = cute_nvgpu.atom.get_value(%819 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %821 = cute_nvgpu.atom.get_value(%819 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %822 = cute_nvgpu.atom.get_value(%819 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %823 = arith.extui %820 : i1 to i32
      %824 = arith.extui %821 : i1 to i32
      %825 = arith.shli %823, %c13_i32 : i32
      %826 = arith.shli %824, %c14_i32 : i32
      %827 = arith.ori %825, %c138413200_i32 : i32
      %828 = arith.ori %827, %826 : i32
      cf.br ^bb267(%c0_i32 : i32)
    ^bb267(%829: i32):  // 2 preds: ^bb266, ^bb274
      %830 = arith.cmpi slt, %829, %792 : i32
      cf.cond_br %830, ^bb268, ^bb275 {llvm.loop_annotation = #loop_annotation}
    ^bb268:  // pred: ^bb267
      cf.br ^bb269(%c0_i32 : i32)
    ^bb269(%831: i32):  // 2 preds: ^bb268, ^bb273
      %832 = arith.cmpi slt, %831, %792 : i32
      cf.cond_br %832, ^bb270, ^bb274 {llvm.loop_annotation = #loop_annotation}
    ^bb270:  // pred: ^bb269
      cf.br ^bb271(%c0_i32 : i32)
    ^bb271(%833: i32):  // 2 preds: ^bb270, ^bb272
      %834 = arith.cmpi slt, %833, %792 : i32
      cf.cond_br %834, ^bb272, ^bb273 {llvm.loop_annotation = #loop_annotation}
    ^bb272:  // pred: ^bb271
      cute_nvgpu.arch.mma.SM100.umma(%tup_454, %tup_455, %ptr_441, %828, %822) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %835 = arith.addi %833, %c1_i32 : i32
      cf.br ^bb271(%835 : i32)
    ^bb273:  // pred: ^bb271
      %836 = arith.addi %831, %c1_i32 : i32
      cf.br ^bb269(%836 : i32)
    ^bb274:  // pred: ^bb269
      %837 = arith.addi %829, %c1_i32 : i32
      cf.br ^bb267(%837 : i32)
    ^bb275:  // pred: ^bb267
      %838 = cute_nvgpu.atom.set_value(%819, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %839 = builtin.unrealized_conversion_cast %838 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %840 = arith.addi %816, %c1_i32 : i32
      cf.br ^bb265(%840, %839 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb276:  // pred: ^bb265
      %841 = nvvm.elect.sync -> i1
      cf.cond_br %841, ^bb277, ^bb278
    ^bb277:  // pred: ^bb276
      %ptr_456 = cute.add_offset(%ptr_95, %int_tuple_447) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %842 = builtin.unrealized_conversion_cast %ptr_456 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %842, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb278
    ^bb278:  // 2 preds: ^bb276, ^bb277
      %843 = arith.addi %793, %c1_i32 : i32
      cf.br ^bb255(%843, %804, %806, %808, %811, %813, %815, %817 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb279:  // pred: ^bb255
      %844 = nvvm.elect.sync -> i1
      cf.cond_br %844, ^bb280, ^bb281
    ^bb280:  // pred: ^bb279
      %ptr_457 = cute.add_offset(%iter_101, %int_tuple_437) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %845 = builtin.unrealized_conversion_cast %ptr_457 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %845, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb281
    ^bb281:  // 2 preds: ^bb279, ^bb280
      cf.br ^bb283(%785, %787, %789, %794, %795, %796, %797, %798, %799 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb282:  // pred: ^bb249
      cf.br ^bb283(%761, %762, %763, %764, %765, %766, %767, %768, %769 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb283(%846: i32, %847: i32, %848: i32, %849: i32, %850: i32, %851: i32, %852: i32, %853: i32, %854: i32):  // 2 preds: ^bb281, ^bb282
      cf.br ^bb284
    ^bb284:  // pred: ^bb283
      %sub_458 = cute.tuple_sub(%sub_436, %212) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %855 = cute.get_scalars(%sub_458) : !cute.int_tuple<"?">
      cf.br ^bb285(%c1_i32, %846, %847, %848, %852, %853, %854, %780, %771, %772, %773, %774, %775, %776 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb285(%856: i32, %857: i32, %858: i32, %859: i32, %860: i32, %861: i32, %862: i32, %863: !llvm.struct<(i1, i1, i1)>, %864: i32, %865: i32, %866: i32, %867: i32, %868: i32, %869: i32):  // 2 preds: ^bb284, ^bb357
      %870 = arith.cmpi slt, %856, %855 : i32
      cf.cond_br %870, ^bb286, ^bb358 {loop_annotation = #loop_annotation2}
    ^bb286:  // pred: ^bb285
      cf.cond_br %782, ^bb287, ^bb315
    ^bb287:  // pred: ^bb286
      %int_tuple_459 = cute.make_int_tuple(%858) : (i32) -> !cute.int_tuple<"?">
      %ptr_460 = cute.add_offset(%ptr_103, %int_tuple_459) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %871 = builtin.unrealized_conversion_cast %ptr_460 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %871, %859, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %872 = arith.addi %858, %c1_i32 : i32
      %873 = arith.addi %857, %c1_i32 : i32
      %874 = arith.cmpi eq, %872, %c2_i32 : i32
      %875 = arith.select %874, %c0_i32, %872 : i32
      cf.cond_br %874, ^bb288, ^bb289
    ^bb288:  // pred: ^bb287
      %876 = arith.xori %859, %c1_i32 : i32
      cf.br ^bb290(%876 : i32)
    ^bb289:  // pred: ^bb287
      cf.br ^bb290(%859 : i32)
    ^bb290(%877: i32):  // 2 preds: ^bb288, ^bb289
      cf.br ^bb291
    ^bb291:  // pred: ^bb290
      %coord_461 = cute.make_coord(%858) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_462 = cute.crd2idx(%coord_461, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_463 = cute.add_offset(%329, %idx_462) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %878 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %879 = builtin.unrealized_conversion_cast %878 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %880 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb292(%c0_i32, %860, %861, %862, %879 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb292(%881: i32, %882: i32, %883: i32, %884: i32, %885: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb291, ^bb311
      %886 = arith.cmpi slt, %881, %c8_i32 : i32
      cf.cond_br %886, ^bb293, ^bb312 {loop_annotation = #loop_annotation3}
    ^bb293:  // pred: ^bb292
      %coord_464 = cute.make_coord(%881) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_465 = cute.crd2idx(%coord_464, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_466 = cute.add_offset(%ummaSmemDesc, %idx_465) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_467 = cute.make_int_tuple(%883) : (i32) -> !cute.int_tuple<"?">
      %ptr_468 = cute.add_offset(%iter_92, %int_tuple_467) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %887 = builtin.unrealized_conversion_cast %ptr_468 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %887, %884, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %888 = arith.addi %883, %c1_i32 : i32
      %889 = arith.addi %882, %c1_i32 : i32
      %890 = arith.cmpi eq, %888, %c3_i32 : i32
      %891 = arith.select %890, %c0_i32, %888 : i32
      cf.cond_br %890, ^bb294, ^bb295
    ^bb294:  // pred: ^bb293
      %892 = arith.xori %884, %c1_i32 : i32
      cf.br ^bb296(%892 : i32)
    ^bb295:  // pred: ^bb293
      cf.br ^bb296(%884 : i32)
    ^bb296(%893: i32):  // 2 preds: ^bb294, ^bb295
      cf.br ^bb297
    ^bb297:  // pred: ^bb296
      %coord_469 = cute.make_coord(%883) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_470 = cute.crd2idx(%coord_469, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_471 = cute.add_offset(%ummaSmemDesc_135, %idx_470) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb298(%c0_i32, %885 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb298(%894: i32, %895: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb297, ^bb308
      %896 = arith.cmpi slt, %894, %c4_i32 : i32
      cf.cond_br %896, ^bb299, ^bb309 {loop_annotation = #loop_annotation1}
    ^bb299:  // pred: ^bb298
      %897 = builtin.unrealized_conversion_cast %895 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_472 = cute.make_coord(%894) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_473 = cute.crd2idx(%coord_472, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_474 = cute.add_offset(%tup_466, %idx_473) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_475 = cute.add_offset(%tup_471, %idx_473) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %898 = cute_nvgpu.atom.get_value(%897 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %899 = cute_nvgpu.atom.get_value(%897 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %900 = cute_nvgpu.atom.get_value(%897 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %901 = arith.extui %898 : i1 to i32
      %902 = arith.extui %899 : i1 to i32
      %903 = arith.shli %901, %c13_i32 : i32
      %904 = arith.shli %902, %c14_i32 : i32
      %905 = arith.ori %903, %c138413200_i32 : i32
      %906 = arith.ori %905, %904 : i32
      cf.br ^bb300(%c0_i32 : i32)
    ^bb300(%907: i32):  // 2 preds: ^bb299, ^bb307
      %908 = arith.cmpi slt, %907, %880 : i32
      cf.cond_br %908, ^bb301, ^bb308 {llvm.loop_annotation = #loop_annotation}
    ^bb301:  // pred: ^bb300
      cf.br ^bb302(%c0_i32 : i32)
    ^bb302(%909: i32):  // 2 preds: ^bb301, ^bb306
      %910 = arith.cmpi slt, %909, %880 : i32
      cf.cond_br %910, ^bb303, ^bb307 {llvm.loop_annotation = #loop_annotation}
    ^bb303:  // pred: ^bb302
      cf.br ^bb304(%c0_i32 : i32)
    ^bb304(%911: i32):  // 2 preds: ^bb303, ^bb305
      %912 = arith.cmpi slt, %911, %880 : i32
      cf.cond_br %912, ^bb305, ^bb306 {llvm.loop_annotation = #loop_annotation}
    ^bb305:  // pred: ^bb304
      cute_nvgpu.arch.mma.SM100.umma(%tup_474, %tup_475, %ptr_463, %906, %900) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %913 = arith.addi %911, %c1_i32 : i32
      cf.br ^bb304(%913 : i32)
    ^bb306:  // pred: ^bb304
      %914 = arith.addi %909, %c1_i32 : i32
      cf.br ^bb302(%914 : i32)
    ^bb307:  // pred: ^bb302
      %915 = arith.addi %907, %c1_i32 : i32
      cf.br ^bb300(%915 : i32)
    ^bb308:  // pred: ^bb300
      %916 = cute_nvgpu.atom.set_value(%897, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %917 = builtin.unrealized_conversion_cast %916 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %918 = arith.addi %894, %c1_i32 : i32
      cf.br ^bb298(%918, %917 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb309:  // pred: ^bb298
      %919 = nvvm.elect.sync -> i1
      cf.cond_br %919, ^bb310, ^bb311
    ^bb310:  // pred: ^bb309
      %ptr_476 = cute.add_offset(%ptr_95, %int_tuple_467) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %920 = builtin.unrealized_conversion_cast %ptr_476 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %920, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb311
    ^bb311:  // 2 preds: ^bb309, ^bb310
      %921 = arith.addi %881, %c1_i32 : i32
      cf.br ^bb292(%921, %889, %891, %893, %895 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb312:  // pred: ^bb292
      %922 = nvvm.elect.sync -> i1
      cf.cond_br %922, ^bb313, ^bb314
    ^bb313:  // pred: ^bb312
      %ptr_477 = cute.add_offset(%iter_101, %int_tuple_459) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %923 = builtin.unrealized_conversion_cast %ptr_477 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %923, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb314
    ^bb314:  // 2 preds: ^bb312, ^bb313
      cf.br ^bb316(%873, %875, %877, %882, %883, %884 : i32, i32, i32, i32, i32, i32)
    ^bb315:  // pred: ^bb286
      cf.br ^bb316(%857, %858, %859, %860, %861, %862 : i32, i32, i32, i32, i32, i32)
    ^bb316(%924: i32, %925: i32, %926: i32, %927: i32, %928: i32, %929: i32):  // 2 preds: ^bb314, ^bb315
      cf.br ^bb317
    ^bb317:  // pred: ^bb316
      cf.cond_br %782, ^bb318, ^bb355
    ^bb318:  // pred: ^bb317
      %int_tuple_478 = cute.make_int_tuple(%865) : (i32) -> !cute.int_tuple<"?">
      %ptr_479 = cute.add_offset(%iter_106, %int_tuple_478) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %930 = builtin.unrealized_conversion_cast %ptr_479 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %930, %866, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %931 = arith.addi %865, %c1_i32 : i32
      %932 = arith.addi %864, %c1_i32 : i32
      %933 = arith.cmpi eq, %931, %c2_i32 : i32
      %934 = arith.select %933, %c0_i32, %931 : i32
      cf.cond_br %933, ^bb319, ^bb320
    ^bb319:  // pred: ^bb318
      %935 = arith.xori %866, %c1_i32 : i32
      cf.br ^bb321(%935 : i32)
    ^bb320:  // pred: ^bb318
      cf.br ^bb321(%866 : i32)
    ^bb321(%936: i32):  // 2 preds: ^bb319, ^bb320
      cf.br ^bb322
    ^bb322:  // pred: ^bb321
      %int_tuple_480 = cute.make_int_tuple(%868) : (i32) -> !cute.int_tuple<"?">
      %ptr_481 = cute.add_offset(%ptr_112, %int_tuple_480) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %937 = builtin.unrealized_conversion_cast %ptr_481 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %937, %869, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %938 = arith.addi %868, %c1_i32 : i32
      %939 = arith.addi %867, %c1_i32 : i32
      %940 = arith.cmpi eq, %938, %c1_i32 : i32
      %941 = arith.select %940, %c0_i32, %938 : i32
      cf.cond_br %940, ^bb323, ^bb324
    ^bb323:  // pred: ^bb322
      %942 = arith.xori %869, %c1_i32 : i32
      cf.br ^bb325(%942 : i32)
    ^bb324:  // pred: ^bb322
      cf.br ^bb325(%869 : i32)
    ^bb325(%943: i32):  // 2 preds: ^bb323, ^bb324
      cf.br ^bb326
    ^bb326:  // pred: ^bb325
      %944 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb327(%c0_i32, %863, %927, %928, %929 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb327(%945: i32, %946: !llvm.struct<(i1, i1, i1)>, %947: i32, %948: i32, %949: i32):  // 2 preds: ^bb326, ^bb349
      %950 = arith.cmpi slt, %945, %c4_i32 : i32
      cf.cond_br %950, ^bb328, ^bb350 {loop_annotation = #loop_annotation2}
    ^bb328:  // pred: ^bb327
      %951 = builtin.unrealized_conversion_cast %946 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %952 = cute_nvgpu.atom.get_value(%951 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_482 = cute.make_coord(%945, %865) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_483 = cute.crd2idx(%coord_482, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_484 = cute.add_offset(%ummaSmemDesc_134, %idx_483) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb329(%c0_i32, %947, %948, %949, %946 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb329(%953: i32, %954: i32, %955: i32, %956: i32, %957: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb328, ^bb348
      %958 = arith.cmpi slt, %953, %c2_i32 : i32
      cf.cond_br %958, ^bb330, ^bb349 {loop_annotation = #loop_annotation3}
    ^bb330:  // pred: ^bb329
      %959 = builtin.unrealized_conversion_cast %957 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_485 = cute.make_int_tuple(%955) : (i32) -> !cute.int_tuple<"?">
      %ptr_486 = cute.add_offset(%iter_92, %int_tuple_485) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %960 = builtin.unrealized_conversion_cast %ptr_486 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %960, %956, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %961 = arith.addi %955, %c1_i32 : i32
      %962 = arith.addi %954, %c1_i32 : i32
      %963 = arith.cmpi eq, %961, %c3_i32 : i32
      %964 = arith.select %963, %c0_i32, %961 : i32
      cf.cond_br %963, ^bb331, ^bb332
    ^bb331:  // pred: ^bb330
      %965 = arith.xori %956, %c1_i32 : i32
      cf.br ^bb333(%965 : i32)
    ^bb332:  // pred: ^bb330
      cf.br ^bb333(%956 : i32)
    ^bb333(%966: i32):  // 2 preds: ^bb331, ^bb332
      cf.br ^bb334
    ^bb334:  // pred: ^bb333
      %967 = cute_nvgpu.atom.set_value(%959, %952 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %968 = builtin.unrealized_conversion_cast %967 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_487 = cute.make_coord(%953) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_488 = cute.crd2idx(%coord_487, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_489 = cute.add_offset(%ptr_137, %idx_488) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_490 = cute.make_coord(%955) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_491 = cute.crd2idx(%coord_490, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_492 = cute.add_offset(%ummaSmemDesc_136, %idx_491) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb335(%c0_i32, %968 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb335(%969: i32, %970: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb334, ^bb345
      %971 = arith.cmpi slt, %969, %c4_i32 : i32
      cf.cond_br %971, ^bb336, ^bb346 {loop_annotation = #loop_annotation1}
    ^bb336:  // pred: ^bb335
      %972 = builtin.unrealized_conversion_cast %970 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_493 = cute.make_coord(%969) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_494 = cute.crd2idx(%coord_493, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_495 = cute.add_offset(%tup_484, %idx_494) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_496 = cute.crd2idx(%coord_493, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_497 = cute.add_offset(%tup_492, %idx_496) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %973 = cute_nvgpu.atom.get_value(%972 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %974 = cute_nvgpu.atom.get_value(%972 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %975 = cute_nvgpu.atom.get_value(%972 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %976 = arith.extui %973 : i1 to i32
      %977 = arith.extui %974 : i1 to i32
      %978 = arith.shli %976, %c13_i32 : i32
      %979 = arith.shli %977, %c14_i32 : i32
      %980 = arith.ori %978, %c138478736_i32 : i32
      %981 = arith.ori %980, %979 : i32
      cf.br ^bb337(%c0_i32 : i32)
    ^bb337(%982: i32):  // 2 preds: ^bb336, ^bb344
      %983 = arith.cmpi slt, %982, %944 : i32
      cf.cond_br %983, ^bb338, ^bb345 {llvm.loop_annotation = #loop_annotation}
    ^bb338:  // pred: ^bb337
      cf.br ^bb339(%c0_i32 : i32)
    ^bb339(%984: i32):  // 2 preds: ^bb338, ^bb343
      %985 = arith.cmpi slt, %984, %944 : i32
      cf.cond_br %985, ^bb340, ^bb344 {llvm.loop_annotation = #loop_annotation}
    ^bb340:  // pred: ^bb339
      cf.br ^bb341(%c0_i32 : i32)
    ^bb341(%986: i32):  // 2 preds: ^bb340, ^bb342
      %987 = arith.cmpi slt, %986, %944 : i32
      cf.cond_br %987, ^bb342, ^bb343 {llvm.loop_annotation = #loop_annotation}
    ^bb342:  // pred: ^bb341
      cute_nvgpu.arch.mma.SM100.umma(%tup_495, %tup_497, %ptr_489, %981, %975) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %988 = arith.addi %986, %c1_i32 : i32
      cf.br ^bb341(%988 : i32)
    ^bb343:  // pred: ^bb341
      %989 = arith.addi %984, %c1_i32 : i32
      cf.br ^bb339(%989 : i32)
    ^bb344:  // pred: ^bb339
      %990 = arith.addi %982, %c1_i32 : i32
      cf.br ^bb337(%990 : i32)
    ^bb345:  // pred: ^bb337
      %991 = cute_nvgpu.atom.set_value(%972, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %992 = builtin.unrealized_conversion_cast %991 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %993 = arith.addi %969, %c1_i32 : i32
      cf.br ^bb335(%993, %992 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb346:  // pred: ^bb335
      %994 = nvvm.elect.sync -> i1
      cf.cond_br %994, ^bb347, ^bb348
    ^bb347:  // pred: ^bb346
      %ptr_498 = cute.add_offset(%ptr_95, %int_tuple_485) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %995 = builtin.unrealized_conversion_cast %ptr_498 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %995, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb348
    ^bb348:  // 2 preds: ^bb346, ^bb347
      %996 = arith.addi %953, %c1_i32 : i32
      cf.br ^bb329(%996, %962, %964, %966, %970 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb349:  // pred: ^bb329
      %997 = arith.addi %945, %c1_i32 : i32
      cf.br ^bb327(%997, %957, %954, %955, %956 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb350:  // pred: ^bb327
      %998 = nvvm.elect.sync -> i1
      cf.cond_br %998, ^bb351, ^bb352
    ^bb351:  // pred: ^bb350
      %ptr_499 = cute.add_offset(%iter_111, %int_tuple_480) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %999 = builtin.unrealized_conversion_cast %ptr_499 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %999, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb352
    ^bb352:  // 2 preds: ^bb350, ^bb351
      %1000 = nvvm.elect.sync -> i1
      cf.cond_br %1000, ^bb353, ^bb354
    ^bb353:  // pred: ^bb352
      %ptr_500 = cute.add_offset(%ptr_108, %int_tuple_478) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1001 = builtin.unrealized_conversion_cast %ptr_500 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1001, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb354
    ^bb354:  // 2 preds: ^bb352, ^bb353
      cf.br ^bb356(%932, %934, %936, %939, %941, %943, %946, %947, %948, %949 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb355:  // pred: ^bb317
      cf.br ^bb356(%864, %865, %866, %867, %868, %869, %863, %927, %928, %929 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb356(%1002: i32, %1003: i32, %1004: i32, %1005: i32, %1006: i32, %1007: i32, %1008: !llvm.struct<(i1, i1, i1)>, %1009: i32, %1010: i32, %1011: i32):  // 2 preds: ^bb354, ^bb355
      cf.br ^bb357
    ^bb357:  // pred: ^bb356
      %1012 = arith.addi %856, %c1_i32 : i32
      cf.br ^bb285(%1012, %924, %925, %926, %1009, %1010, %1011, %1008, %1002, %1003, %1004, %1005, %1006, %1007 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb358:  // pred: ^bb285
      cf.cond_br %782, ^bb359, ^bb393
    ^bb359:  // pred: ^bb358
      %int_tuple_501 = cute.make_int_tuple(%858) : (i32) -> !cute.int_tuple<"?">
      %ptr_502 = cute.add_offset(%ptr_103, %int_tuple_501) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1013 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1013, %859, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1014 = arith.addi %858, %c1_i32 : i32
      %1015 = arith.addi %857, %c1_i32 : i32
      %1016 = arith.cmpi eq, %1014, %c2_i32 : i32
      %1017 = arith.select %1016, %c0_i32, %1014 : i32
      cf.cond_br %1016, ^bb360, ^bb361
    ^bb360:  // pred: ^bb359
      %1018 = arith.xori %859, %c1_i32 : i32
      cf.br ^bb362(%1018 : i32)
    ^bb361:  // pred: ^bb359
      cf.br ^bb362(%859 : i32)
    ^bb362(%1019: i32):  // 2 preds: ^bb360, ^bb361
      cf.br ^bb363
    ^bb363:  // pred: ^bb362
      %coord_503 = cute.make_coord(%858) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_504 = cute.crd2idx(%coord_503, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_505 = cute.add_offset(%329, %idx_504) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1020 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1021 = builtin.unrealized_conversion_cast %1020 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1022 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb364(%c0_i32, %860, %861, %862, %1021, %764, %765, %766 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb364(%1023: i32, %1024: i32, %1025: i32, %1026: i32, %1027: !llvm.struct<(i1, i1, i1)>, %1028: i32, %1029: i32, %1030: i32):  // 2 preds: ^bb363, ^bb389
      %1031 = arith.cmpi slt, %1023, %c8_i32 : i32
      cf.cond_br %1031, ^bb365, ^bb390 {loop_annotation = #loop_annotation3}
    ^bb365:  // pred: ^bb364
      %coord_506 = cute.make_coord(%1023) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_507 = cute.crd2idx(%coord_506, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_508 = cute.add_offset(%ummaSmemDesc, %idx_507) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_509 = cute.make_int_tuple(%1025) : (i32) -> !cute.int_tuple<"?">
      %ptr_510 = cute.add_offset(%iter_92, %int_tuple_509) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1032 = builtin.unrealized_conversion_cast %ptr_510 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1032, %1026, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1033 = arith.addi %1025, %c1_i32 : i32
      %1034 = arith.addi %1024, %c1_i32 : i32
      %1035 = arith.cmpi eq, %1033, %c3_i32 : i32
      %1036 = arith.select %1035, %c0_i32, %1033 : i32
      cf.cond_br %1035, ^bb366, ^bb367
    ^bb366:  // pred: ^bb365
      %1037 = arith.xori %1026, %c1_i32 : i32
      cf.br ^bb368(%1037 : i32)
    ^bb367:  // pred: ^bb365
      cf.br ^bb368(%1026 : i32)
    ^bb368(%1038: i32):  // 2 preds: ^bb366, ^bb367
      cf.br ^bb369
    ^bb369:  // pred: ^bb368
      %coord_511 = cute.make_coord(%1025) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_512 = cute.crd2idx(%coord_511, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_513 = cute.add_offset(%ummaSmemDesc_135, %idx_512) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb370(%c0_i32, %1027 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb370(%1039: i32, %1040: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb369, ^bb380
      %1041 = arith.cmpi slt, %1039, %c4_i32 : i32
      cf.cond_br %1041, ^bb371, ^bb381 {loop_annotation = #loop_annotation1}
    ^bb371:  // pred: ^bb370
      %1042 = builtin.unrealized_conversion_cast %1040 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_514 = cute.make_coord(%1039) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_515 = cute.crd2idx(%coord_514, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_516 = cute.add_offset(%tup_508, %idx_515) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_517 = cute.add_offset(%tup_513, %idx_515) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1043 = cute_nvgpu.atom.get_value(%1042 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1044 = cute_nvgpu.atom.get_value(%1042 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1045 = cute_nvgpu.atom.get_value(%1042 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1046 = arith.extui %1043 : i1 to i32
      %1047 = arith.extui %1044 : i1 to i32
      %1048 = arith.shli %1046, %c13_i32 : i32
      %1049 = arith.shli %1047, %c14_i32 : i32
      %1050 = arith.ori %1048, %c138413200_i32 : i32
      %1051 = arith.ori %1050, %1049 : i32
      cf.br ^bb372(%c0_i32 : i32)
    ^bb372(%1052: i32):  // 2 preds: ^bb371, ^bb379
      %1053 = arith.cmpi slt, %1052, %1022 : i32
      cf.cond_br %1053, ^bb373, ^bb380 {llvm.loop_annotation = #loop_annotation}
    ^bb373:  // pred: ^bb372
      cf.br ^bb374(%c0_i32 : i32)
    ^bb374(%1054: i32):  // 2 preds: ^bb373, ^bb378
      %1055 = arith.cmpi slt, %1054, %1022 : i32
      cf.cond_br %1055, ^bb375, ^bb379 {llvm.loop_annotation = #loop_annotation}
    ^bb375:  // pred: ^bb374
      cf.br ^bb376(%c0_i32 : i32)
    ^bb376(%1056: i32):  // 2 preds: ^bb375, ^bb377
      %1057 = arith.cmpi slt, %1056, %1022 : i32
      cf.cond_br %1057, ^bb377, ^bb378 {llvm.loop_annotation = #loop_annotation}
    ^bb377:  // pred: ^bb376
      cute_nvgpu.arch.mma.SM100.umma(%tup_516, %tup_517, %ptr_505, %1051, %1045) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1058 = arith.addi %1056, %c1_i32 : i32
      cf.br ^bb376(%1058 : i32)
    ^bb378:  // pred: ^bb376
      %1059 = arith.addi %1054, %c1_i32 : i32
      cf.br ^bb374(%1059 : i32)
    ^bb379:  // pred: ^bb374
      %1060 = arith.addi %1052, %c1_i32 : i32
      cf.br ^bb372(%1060 : i32)
    ^bb380:  // pred: ^bb372
      %1061 = cute_nvgpu.atom.set_value(%1042, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1062 = builtin.unrealized_conversion_cast %1061 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1063 = arith.addi %1039, %c1_i32 : i32
      cf.br ^bb370(%1063, %1062 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb381:  // pred: ^bb370
      %1064 = nvvm.elect.sync -> i1
      cf.cond_br %1064, ^bb382, ^bb383
    ^bb382:  // pred: ^bb381
      %ptr_518 = cute.add_offset(%ptr_95, %int_tuple_509) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1065 = builtin.unrealized_conversion_cast %ptr_518 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1065, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb383
    ^bb383:  // 2 preds: ^bb381, ^bb382
      %1066 = nvvm.elect.sync -> i1
      cf.cond_br %1066, ^bb384, ^bb385
    ^bb384:  // pred: ^bb383
      %int_tuple_519 = cute.make_int_tuple(%1029) : (i32) -> !cute.int_tuple<"?">
      %ptr_520 = cute.add_offset(%ptr_21, %int_tuple_519) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1067 = builtin.unrealized_conversion_cast %ptr_520 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1067, multicast_mask = %276 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb385
    ^bb385:  // 2 preds: ^bb383, ^bb384
      %1068 = arith.addi %1029, %c1_i32 : i32
      %1069 = arith.addi %1028, %c1_i32 : i32
      %1070 = arith.cmpi eq, %1068, %c8_i32 : i32
      %1071 = arith.select %1070, %c0_i32, %1068 : i32
      cf.cond_br %1070, ^bb386, ^bb387
    ^bb386:  // pred: ^bb385
      %1072 = arith.xori %1030, %c1_i32 : i32
      cf.br ^bb388(%1072 : i32)
    ^bb387:  // pred: ^bb385
      cf.br ^bb388(%1030 : i32)
    ^bb388(%1073: i32):  // 2 preds: ^bb386, ^bb387
      cf.br ^bb389
    ^bb389:  // pred: ^bb388
      %1074 = arith.addi %1023, %c1_i32 : i32
      cf.br ^bb364(%1074, %1034, %1036, %1038, %1040, %1069, %1071, %1073 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb390:  // pred: ^bb364
      %1075 = nvvm.elect.sync -> i1
      cf.cond_br %1075, ^bb391, ^bb392
    ^bb391:  // pred: ^bb390
      %ptr_521 = cute.add_offset(%iter_101, %int_tuple_501) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1076 = builtin.unrealized_conversion_cast %ptr_521 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1076, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb392
    ^bb392:  // 2 preds: ^bb390, ^bb391
      cf.br ^bb394(%1015, %1017, %1019, %1024, %1025, %1026 : i32, i32, i32, i32, i32, i32)
    ^bb393:  // pred: ^bb358
      cf.br ^bb394(%857, %858, %859, %860, %861, %862 : i32, i32, i32, i32, i32, i32)
    ^bb394(%1077: i32, %1078: i32, %1079: i32, %1080: i32, %1081: i32, %1082: i32):  // 2 preds: ^bb392, ^bb393
      cf.br ^bb395
    ^bb395:  // pred: ^bb394
      cf.cond_br %782, ^bb396, ^bb433
    ^bb396:  // pred: ^bb395
      %int_tuple_522 = cute.make_int_tuple(%865) : (i32) -> !cute.int_tuple<"?">
      %ptr_523 = cute.add_offset(%iter_106, %int_tuple_522) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1083 = builtin.unrealized_conversion_cast %ptr_523 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1083, %866, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1084 = arith.addi %865, %c1_i32 : i32
      %1085 = arith.addi %864, %c1_i32 : i32
      %1086 = arith.cmpi eq, %1084, %c2_i32 : i32
      %1087 = arith.select %1086, %c0_i32, %1084 : i32
      cf.cond_br %1086, ^bb397, ^bb398
    ^bb397:  // pred: ^bb396
      %1088 = arith.xori %866, %c1_i32 : i32
      cf.br ^bb399(%1088 : i32)
    ^bb398:  // pred: ^bb396
      cf.br ^bb399(%866 : i32)
    ^bb399(%1089: i32):  // 2 preds: ^bb397, ^bb398
      cf.br ^bb400
    ^bb400:  // pred: ^bb399
      %int_tuple_524 = cute.make_int_tuple(%868) : (i32) -> !cute.int_tuple<"?">
      %ptr_525 = cute.add_offset(%ptr_112, %int_tuple_524) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1090 = builtin.unrealized_conversion_cast %ptr_525 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1090, %869, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1091 = arith.addi %868, %c1_i32 : i32
      %1092 = arith.addi %867, %c1_i32 : i32
      %1093 = arith.cmpi eq, %1091, %c1_i32 : i32
      %1094 = arith.select %1093, %c0_i32, %1091 : i32
      cf.cond_br %1093, ^bb401, ^bb402
    ^bb401:  // pred: ^bb400
      %1095 = arith.xori %869, %c1_i32 : i32
      cf.br ^bb403(%1095 : i32)
    ^bb402:  // pred: ^bb400
      cf.br ^bb403(%869 : i32)
    ^bb403(%1096: i32):  // 2 preds: ^bb401, ^bb402
      cf.br ^bb404
    ^bb404:  // pred: ^bb403
      %1097 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb405(%c0_i32, %863, %1080, %1081, %1082 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb405(%1098: i32, %1099: !llvm.struct<(i1, i1, i1)>, %1100: i32, %1101: i32, %1102: i32):  // 2 preds: ^bb404, ^bb427
      %1103 = arith.cmpi slt, %1098, %c4_i32 : i32
      cf.cond_br %1103, ^bb406, ^bb428 {loop_annotation = #loop_annotation2}
    ^bb406:  // pred: ^bb405
      %1104 = builtin.unrealized_conversion_cast %1099 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1105 = cute_nvgpu.atom.get_value(%1104 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_526 = cute.make_coord(%1098, %865) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_527 = cute.crd2idx(%coord_526, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_528 = cute.add_offset(%ummaSmemDesc_134, %idx_527) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb407(%c0_i32, %1100, %1101, %1102, %1099 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb407(%1106: i32, %1107: i32, %1108: i32, %1109: i32, %1110: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb406, ^bb426
      %1111 = arith.cmpi slt, %1106, %c2_i32 : i32
      cf.cond_br %1111, ^bb408, ^bb427 {loop_annotation = #loop_annotation3}
    ^bb408:  // pred: ^bb407
      %1112 = builtin.unrealized_conversion_cast %1110 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_529 = cute.make_int_tuple(%1108) : (i32) -> !cute.int_tuple<"?">
      %ptr_530 = cute.add_offset(%iter_92, %int_tuple_529) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1113 = builtin.unrealized_conversion_cast %ptr_530 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1113, %1109, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1114 = arith.addi %1108, %c1_i32 : i32
      %1115 = arith.addi %1107, %c1_i32 : i32
      %1116 = arith.cmpi eq, %1114, %c3_i32 : i32
      %1117 = arith.select %1116, %c0_i32, %1114 : i32
      cf.cond_br %1116, ^bb409, ^bb410
    ^bb409:  // pred: ^bb408
      %1118 = arith.xori %1109, %c1_i32 : i32
      cf.br ^bb411(%1118 : i32)
    ^bb410:  // pred: ^bb408
      cf.br ^bb411(%1109 : i32)
    ^bb411(%1119: i32):  // 2 preds: ^bb409, ^bb410
      cf.br ^bb412
    ^bb412:  // pred: ^bb411
      %1120 = cute_nvgpu.atom.set_value(%1112, %1105 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1121 = builtin.unrealized_conversion_cast %1120 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_531 = cute.make_coord(%1106) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_532 = cute.crd2idx(%coord_531, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_533 = cute.add_offset(%ptr_137, %idx_532) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_534 = cute.make_coord(%1108) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_535 = cute.crd2idx(%coord_534, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_536 = cute.add_offset(%ummaSmemDesc_136, %idx_535) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb413(%c0_i32, %1121 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb413(%1122: i32, %1123: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb412, ^bb423
      %1124 = arith.cmpi slt, %1122, %c4_i32 : i32
      cf.cond_br %1124, ^bb414, ^bb424 {loop_annotation = #loop_annotation1}
    ^bb414:  // pred: ^bb413
      %1125 = builtin.unrealized_conversion_cast %1123 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_537 = cute.make_coord(%1122) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_538 = cute.crd2idx(%coord_537, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_539 = cute.add_offset(%tup_528, %idx_538) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_540 = cute.crd2idx(%coord_537, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_541 = cute.add_offset(%tup_536, %idx_540) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %1126 = cute_nvgpu.atom.get_value(%1125 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1127 = cute_nvgpu.atom.get_value(%1125 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1128 = cute_nvgpu.atom.get_value(%1125 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1129 = arith.extui %1126 : i1 to i32
      %1130 = arith.extui %1127 : i1 to i32
      %1131 = arith.shli %1129, %c13_i32 : i32
      %1132 = arith.shli %1130, %c14_i32 : i32
      %1133 = arith.ori %1131, %c138478736_i32 : i32
      %1134 = arith.ori %1133, %1132 : i32
      cf.br ^bb415(%c0_i32 : i32)
    ^bb415(%1135: i32):  // 2 preds: ^bb414, ^bb422
      %1136 = arith.cmpi slt, %1135, %1097 : i32
      cf.cond_br %1136, ^bb416, ^bb423 {llvm.loop_annotation = #loop_annotation}
    ^bb416:  // pred: ^bb415
      cf.br ^bb417(%c0_i32 : i32)
    ^bb417(%1137: i32):  // 2 preds: ^bb416, ^bb421
      %1138 = arith.cmpi slt, %1137, %1097 : i32
      cf.cond_br %1138, ^bb418, ^bb422 {llvm.loop_annotation = #loop_annotation}
    ^bb418:  // pred: ^bb417
      cf.br ^bb419(%c0_i32 : i32)
    ^bb419(%1139: i32):  // 2 preds: ^bb418, ^bb420
      %1140 = arith.cmpi slt, %1139, %1097 : i32
      cf.cond_br %1140, ^bb420, ^bb421 {llvm.loop_annotation = #loop_annotation}
    ^bb420:  // pred: ^bb419
      cute_nvgpu.arch.mma.SM100.umma(%tup_539, %tup_541, %ptr_533, %1134, %1128) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1141 = arith.addi %1139, %c1_i32 : i32
      cf.br ^bb419(%1141 : i32)
    ^bb421:  // pred: ^bb419
      %1142 = arith.addi %1137, %c1_i32 : i32
      cf.br ^bb417(%1142 : i32)
    ^bb422:  // pred: ^bb417
      %1143 = arith.addi %1135, %c1_i32 : i32
      cf.br ^bb415(%1143 : i32)
    ^bb423:  // pred: ^bb415
      %1144 = cute_nvgpu.atom.set_value(%1125, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1145 = builtin.unrealized_conversion_cast %1144 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %1146 = arith.addi %1122, %c1_i32 : i32
      cf.br ^bb413(%1146, %1145 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb424:  // pred: ^bb413
      %1147 = nvvm.elect.sync -> i1
      cf.cond_br %1147, ^bb425, ^bb426
    ^bb425:  // pred: ^bb424
      %ptr_542 = cute.add_offset(%ptr_95, %int_tuple_529) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1148 = builtin.unrealized_conversion_cast %ptr_542 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1148, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb426
    ^bb426:  // 2 preds: ^bb424, ^bb425
      %1149 = arith.addi %1106, %c1_i32 : i32
      cf.br ^bb407(%1149, %1115, %1117, %1119, %1123 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb427:  // pred: ^bb407
      %1150 = arith.addi %1098, %c1_i32 : i32
      cf.br ^bb405(%1150, %1110, %1107, %1108, %1109 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb428:  // pred: ^bb405
      %1151 = nvvm.elect.sync -> i1
      cf.cond_br %1151, ^bb429, ^bb430
    ^bb429:  // pred: ^bb428
      %ptr_543 = cute.add_offset(%iter_111, %int_tuple_524) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1152 = builtin.unrealized_conversion_cast %ptr_543 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1152, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb430
    ^bb430:  // 2 preds: ^bb428, ^bb429
      %1153 = nvvm.elect.sync -> i1
      cf.cond_br %1153, ^bb431, ^bb432
    ^bb431:  // pred: ^bb430
      %ptr_544 = cute.add_offset(%ptr_108, %int_tuple_522) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1154 = builtin.unrealized_conversion_cast %ptr_544 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1154, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb432
    ^bb432:  // 2 preds: ^bb430, ^bb431
      cf.br ^bb434(%1085, %1087, %1089, %1092, %1094, %1096, %1099, %1100, %1101, %1102 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb433:  // pred: ^bb395
      cf.br ^bb434(%864, %865, %866, %867, %868, %869, %863, %1080, %1081, %1082 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb434(%1155: i32, %1156: i32, %1157: i32, %1158: i32, %1159: i32, %1160: i32, %1161: !llvm.struct<(i1, i1, i1)>, %1162: i32, %1163: i32, %1164: i32):  // 2 preds: ^bb432, ^bb433
      cf.br ^bb435
    ^bb435:  // pred: ^bb434
      cf.br ^bb478(%1077, %1078, %1079, %849, %850, %851, %1162, %1163, %1164, %1161, %1155, %1156, %1157, %1158, %1159, %1160 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb436:  // pred: ^bb248
      %1165 = arith.remsi %258, %c2_i32 : i32
      %1166 = arith.cmpi eq, %1165, %c0_i32 : i32
      cf.cond_br %1166, ^bb437, ^bb475
    ^bb437:  // pred: ^bb436
      %int_tuple_545 = cute.make_int_tuple(%762) : (i32) -> !cute.int_tuple<"?">
      %ptr_546 = cute.add_offset(%ptr_103, %int_tuple_545) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1167 = builtin.unrealized_conversion_cast %ptr_546 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1167, %763, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1168 = arith.addi %762, %c1_i32 : i32
      %1169 = arith.addi %761, %c1_i32 : i32
      %1170 = arith.cmpi eq, %1168, %c2_i32 : i32
      %1171 = arith.select %1170, %c0_i32, %1168 : i32
      cf.cond_br %1170, ^bb438, ^bb439
    ^bb438:  // pred: ^bb437
      %1172 = arith.xori %763, %c1_i32 : i32
      cf.br ^bb440(%1172 : i32)
    ^bb439:  // pred: ^bb437
      cf.br ^bb440(%763 : i32)
    ^bb440(%1173: i32):  // 2 preds: ^bb438, ^bb439
      cf.br ^bb441
    ^bb441:  // pred: ^bb440
      %coord_547 = cute.make_coord(%762) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_548 = cute.crd2idx(%coord_547, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_549 = cute.add_offset(%329, %idx_548) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1174 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1175 = builtin.unrealized_conversion_cast %1174 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1176 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb442(%c0_i32, %764, %765, %766, %767, %768, %769, %1175, %764, %765, %766 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb442(%1177: i32, %1178: i32, %1179: i32, %1180: i32, %1181: i32, %1182: i32, %1183: i32, %1184: !llvm.struct<(i1, i1, i1)>, %1185: i32, %1186: i32, %1187: i32):  // 2 preds: ^bb441, ^bb471
      %1188 = arith.cmpi slt, %1177, %c8_i32 : i32
      cf.cond_br %1188, ^bb443, ^bb472 {loop_annotation = #loop_annotation3}
    ^bb443:  // pred: ^bb442
      %int_tuple_550 = cute.make_int_tuple(%1179) : (i32) -> !cute.int_tuple<"?">
      %ptr_551 = cute.add_offset(%iter_13, %int_tuple_550) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1189 = builtin.unrealized_conversion_cast %ptr_551 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1189, %1180, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1190 = arith.addi %1179, %c1_i32 : i32
      %1191 = arith.addi %1178, %c1_i32 : i32
      %1192 = arith.cmpi eq, %1190, %c8_i32 : i32
      %1193 = arith.select %1192, %c0_i32, %1190 : i32
      cf.cond_br %1192, ^bb444, ^bb445
    ^bb444:  // pred: ^bb443
      %1194 = arith.xori %1180, %c1_i32 : i32
      cf.br ^bb446(%1194 : i32)
    ^bb445:  // pred: ^bb443
      cf.br ^bb446(%1180 : i32)
    ^bb446(%1195: i32):  // 2 preds: ^bb444, ^bb445
      cf.br ^bb447
    ^bb447:  // pred: ^bb446
      %coord_552 = cute.make_coord(%1177) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_553 = cute.crd2idx(%coord_552, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_554 = cute.add_offset(%ummaSmemDesc, %idx_553) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_555 = cute.make_int_tuple(%1182) : (i32) -> !cute.int_tuple<"?">
      %ptr_556 = cute.add_offset(%iter_92, %int_tuple_555) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1196 = builtin.unrealized_conversion_cast %ptr_556 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1196, %1183, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1197 = arith.addi %1182, %c1_i32 : i32
      %1198 = arith.addi %1181, %c1_i32 : i32
      %1199 = arith.cmpi eq, %1197, %c3_i32 : i32
      %1200 = arith.select %1199, %c0_i32, %1197 : i32
      cf.cond_br %1199, ^bb448, ^bb449
    ^bb448:  // pred: ^bb447
      %1201 = arith.xori %1183, %c1_i32 : i32
      cf.br ^bb450(%1201 : i32)
    ^bb449:  // pred: ^bb447
      cf.br ^bb450(%1183 : i32)
    ^bb450(%1202: i32):  // 2 preds: ^bb448, ^bb449
      cf.br ^bb451
    ^bb451:  // pred: ^bb450
      %coord_557 = cute.make_coord(%1182) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_558 = cute.crd2idx(%coord_557, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_559 = cute.add_offset(%ummaSmemDesc_135, %idx_558) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb452(%c0_i32, %1184 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb452(%1203: i32, %1204: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb451, ^bb462
      %1205 = arith.cmpi slt, %1203, %c4_i32 : i32
      cf.cond_br %1205, ^bb453, ^bb463 {loop_annotation = #loop_annotation1}
    ^bb453:  // pred: ^bb452
      %1206 = builtin.unrealized_conversion_cast %1204 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_560 = cute.make_coord(%1203) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_561 = cute.crd2idx(%coord_560, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_562 = cute.add_offset(%tup_554, %idx_561) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_563 = cute.add_offset(%tup_559, %idx_561) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1207 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1208 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1209 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1210 = arith.extui %1207 : i1 to i32
      %1211 = arith.extui %1208 : i1 to i32
      %1212 = arith.shli %1210, %c13_i32 : i32
      %1213 = arith.shli %1211, %c14_i32 : i32
      %1214 = arith.ori %1212, %c138413200_i32 : i32
      %1215 = arith.ori %1214, %1213 : i32
      cf.br ^bb454(%c0_i32 : i32)
    ^bb454(%1216: i32):  // 2 preds: ^bb453, ^bb461
      %1217 = arith.cmpi slt, %1216, %1176 : i32
      cf.cond_br %1217, ^bb455, ^bb462 {llvm.loop_annotation = #loop_annotation}
    ^bb455:  // pred: ^bb454
      cf.br ^bb456(%c0_i32 : i32)
    ^bb456(%1218: i32):  // 2 preds: ^bb455, ^bb460
      %1219 = arith.cmpi slt, %1218, %1176 : i32
      cf.cond_br %1219, ^bb457, ^bb461 {llvm.loop_annotation = #loop_annotation}
    ^bb457:  // pred: ^bb456
      cf.br ^bb458(%c0_i32 : i32)
    ^bb458(%1220: i32):  // 2 preds: ^bb457, ^bb459
      %1221 = arith.cmpi slt, %1220, %1176 : i32
      cf.cond_br %1221, ^bb459, ^bb460 {llvm.loop_annotation = #loop_annotation}
    ^bb459:  // pred: ^bb458
      cute_nvgpu.arch.mma.SM100.umma(%tup_562, %tup_563, %ptr_549, %1215, %1209) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1222 = arith.addi %1220, %c1_i32 : i32
      cf.br ^bb458(%1222 : i32)
    ^bb460:  // pred: ^bb458
      %1223 = arith.addi %1218, %c1_i32 : i32
      cf.br ^bb456(%1223 : i32)
    ^bb461:  // pred: ^bb456
      %1224 = arith.addi %1216, %c1_i32 : i32
      cf.br ^bb454(%1224 : i32)
    ^bb462:  // pred: ^bb454
      %1225 = cute_nvgpu.atom.set_value(%1206, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1226 = builtin.unrealized_conversion_cast %1225 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1227 = arith.addi %1203, %c1_i32 : i32
      cf.br ^bb452(%1227, %1226 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb463:  // pred: ^bb452
      %1228 = nvvm.elect.sync -> i1
      cf.cond_br %1228, ^bb464, ^bb465
    ^bb464:  // pred: ^bb463
      %ptr_564 = cute.add_offset(%ptr_95, %int_tuple_555) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1229 = builtin.unrealized_conversion_cast %ptr_564 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1229, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb465
    ^bb465:  // 2 preds: ^bb463, ^bb464
      %1230 = nvvm.elect.sync -> i1
      cf.cond_br %1230, ^bb466, ^bb467
    ^bb466:  // pred: ^bb465
      %int_tuple_565 = cute.make_int_tuple(%1186) : (i32) -> !cute.int_tuple<"?">
      %ptr_566 = cute.add_offset(%ptr_21, %int_tuple_565) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1231 = builtin.unrealized_conversion_cast %ptr_566 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1231, multicast_mask = %276 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb467
    ^bb467:  // 2 preds: ^bb465, ^bb466
      %1232 = arith.addi %1186, %c1_i32 : i32
      %1233 = arith.addi %1185, %c1_i32 : i32
      %1234 = arith.cmpi eq, %1232, %c8_i32 : i32
      %1235 = arith.select %1234, %c0_i32, %1232 : i32
      cf.cond_br %1234, ^bb468, ^bb469
    ^bb468:  // pred: ^bb467
      %1236 = arith.xori %1187, %c1_i32 : i32
      cf.br ^bb470(%1236 : i32)
    ^bb469:  // pred: ^bb467
      cf.br ^bb470(%1187 : i32)
    ^bb470(%1237: i32):  // 2 preds: ^bb468, ^bb469
      cf.br ^bb471
    ^bb471:  // pred: ^bb470
      %1238 = arith.addi %1177, %c1_i32 : i32
      cf.br ^bb442(%1238, %1191, %1193, %1195, %1198, %1200, %1202, %1204, %1233, %1235, %1237 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb472:  // pred: ^bb442
      %1239 = nvvm.elect.sync -> i1
      cf.cond_br %1239, ^bb473, ^bb474
    ^bb473:  // pred: ^bb472
      %ptr_567 = cute.add_offset(%iter_101, %int_tuple_545) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1240 = builtin.unrealized_conversion_cast %ptr_567 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1240, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb474
    ^bb474:  // 2 preds: ^bb472, ^bb473
      cf.br ^bb476(%1169, %1171, %1173, %1178, %1179, %1180, %1181, %1182, %1183 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb475:  // pred: ^bb436
      cf.br ^bb476(%761, %762, %763, %764, %765, %766, %767, %768, %769 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb476(%1241: i32, %1242: i32, %1243: i32, %1244: i32, %1245: i32, %1246: i32, %1247: i32, %1248: i32, %1249: i32):  // 2 preds: ^bb474, ^bb475
      cf.br ^bb477
    ^bb477:  // pred: ^bb476
      cf.br ^bb478(%1241, %1242, %1243, %1244, %1245, %1246, %1247, %1248, %1249, %780, %771, %772, %773, %774, %775, %776 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb478(%1250: i32, %1251: i32, %1252: i32, %1253: i32, %1254: i32, %1255: i32, %1256: i32, %1257: i32, %1258: i32, %1259: !llvm.struct<(i1, i1, i1)>, %1260: i32, %1261: i32, %1262: i32, %1263: i32, %1264: i32, %1265: i32):  // 2 preds: ^bb435, ^bb477
      cf.br ^bb479
    ^bb479:  // pred: ^bb478
      cf.cond_br %743, ^bb480, ^bb517
    ^bb480:  // pred: ^bb479
      %int_tuple_568 = cute.make_int_tuple(%1261) : (i32) -> !cute.int_tuple<"?">
      %ptr_569 = cute.add_offset(%iter_106, %int_tuple_568) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1266 = builtin.unrealized_conversion_cast %ptr_569 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1266, %1262, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1267 = arith.addi %1261, %c1_i32 : i32
      %1268 = arith.addi %1260, %c1_i32 : i32
      %1269 = arith.cmpi eq, %1267, %c2_i32 : i32
      %1270 = arith.select %1269, %c0_i32, %1267 : i32
      cf.cond_br %1269, ^bb481, ^bb482
    ^bb481:  // pred: ^bb480
      %1271 = arith.xori %1262, %c1_i32 : i32
      cf.br ^bb483(%1271 : i32)
    ^bb482:  // pred: ^bb480
      cf.br ^bb483(%1262 : i32)
    ^bb483(%1272: i32):  // 2 preds: ^bb481, ^bb482
      cf.br ^bb484
    ^bb484:  // pred: ^bb483
      %int_tuple_570 = cute.make_int_tuple(%1264) : (i32) -> !cute.int_tuple<"?">
      %ptr_571 = cute.add_offset(%ptr_112, %int_tuple_570) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1273 = builtin.unrealized_conversion_cast %ptr_571 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1273, %1265, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1274 = arith.addi %1264, %c1_i32 : i32
      %1275 = arith.addi %1263, %c1_i32 : i32
      %1276 = arith.cmpi eq, %1274, %c1_i32 : i32
      %1277 = arith.select %1276, %c0_i32, %1274 : i32
      cf.cond_br %1276, ^bb485, ^bb486
    ^bb485:  // pred: ^bb484
      %1278 = arith.xori %1265, %c1_i32 : i32
      cf.br ^bb487(%1278 : i32)
    ^bb486:  // pred: ^bb484
      cf.br ^bb487(%1265 : i32)
    ^bb487(%1279: i32):  // 2 preds: ^bb485, ^bb486
      cf.br ^bb488
    ^bb488:  // pred: ^bb487
      %1280 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb489(%c0_i32, %1259, %1256, %1257, %1258 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb489(%1281: i32, %1282: !llvm.struct<(i1, i1, i1)>, %1283: i32, %1284: i32, %1285: i32):  // 2 preds: ^bb488, ^bb511
      %1286 = arith.cmpi slt, %1281, %c4_i32 : i32
      cf.cond_br %1286, ^bb490, ^bb512 {loop_annotation = #loop_annotation2}
    ^bb490:  // pred: ^bb489
      %1287 = builtin.unrealized_conversion_cast %1282 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1288 = cute_nvgpu.atom.get_value(%1287 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_572 = cute.make_coord(%1281, %1261) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_573 = cute.crd2idx(%coord_572, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_574 = cute.add_offset(%ummaSmemDesc_134, %idx_573) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb491(%c0_i32, %1283, %1284, %1285, %1282 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb491(%1289: i32, %1290: i32, %1291: i32, %1292: i32, %1293: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb490, ^bb510
      %1294 = arith.cmpi slt, %1289, %c2_i32 : i32
      cf.cond_br %1294, ^bb492, ^bb511 {loop_annotation = #loop_annotation3}
    ^bb492:  // pred: ^bb491
      %1295 = builtin.unrealized_conversion_cast %1293 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_575 = cute.make_int_tuple(%1291) : (i32) -> !cute.int_tuple<"?">
      %ptr_576 = cute.add_offset(%iter_92, %int_tuple_575) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1296 = builtin.unrealized_conversion_cast %ptr_576 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1296, %1292, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1297 = arith.addi %1291, %c1_i32 : i32
      %1298 = arith.addi %1290, %c1_i32 : i32
      %1299 = arith.cmpi eq, %1297, %c3_i32 : i32
      %1300 = arith.select %1299, %c0_i32, %1297 : i32
      cf.cond_br %1299, ^bb493, ^bb494
    ^bb493:  // pred: ^bb492
      %1301 = arith.xori %1292, %c1_i32 : i32
      cf.br ^bb495(%1301 : i32)
    ^bb494:  // pred: ^bb492
      cf.br ^bb495(%1292 : i32)
    ^bb495(%1302: i32):  // 2 preds: ^bb493, ^bb494
      cf.br ^bb496
    ^bb496:  // pred: ^bb495
      %1303 = cute_nvgpu.atom.set_value(%1295, %1288 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1304 = builtin.unrealized_conversion_cast %1303 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_577 = cute.make_coord(%1289) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_578 = cute.crd2idx(%coord_577, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_579 = cute.add_offset(%ptr_137, %idx_578) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_580 = cute.make_coord(%1291) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_581 = cute.crd2idx(%coord_580, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_582 = cute.add_offset(%ummaSmemDesc_136, %idx_581) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb497(%c0_i32, %1304 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb497(%1305: i32, %1306: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb496, ^bb507
      %1307 = arith.cmpi slt, %1305, %c4_i32 : i32
      cf.cond_br %1307, ^bb498, ^bb508 {loop_annotation = #loop_annotation1}
    ^bb498:  // pred: ^bb497
      %1308 = builtin.unrealized_conversion_cast %1306 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_583 = cute.make_coord(%1305) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_584 = cute.crd2idx(%coord_583, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_585 = cute.add_offset(%tup_574, %idx_584) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_586 = cute.crd2idx(%coord_583, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_587 = cute.add_offset(%tup_582, %idx_586) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %1309 = cute_nvgpu.atom.get_value(%1308 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1310 = cute_nvgpu.atom.get_value(%1308 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1311 = cute_nvgpu.atom.get_value(%1308 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1312 = arith.extui %1309 : i1 to i32
      %1313 = arith.extui %1310 : i1 to i32
      %1314 = arith.shli %1312, %c13_i32 : i32
      %1315 = arith.shli %1313, %c14_i32 : i32
      %1316 = arith.ori %1314, %c138478736_i32 : i32
      %1317 = arith.ori %1316, %1315 : i32
      cf.br ^bb499(%c0_i32 : i32)
    ^bb499(%1318: i32):  // 2 preds: ^bb498, ^bb506
      %1319 = arith.cmpi slt, %1318, %1280 : i32
      cf.cond_br %1319, ^bb500, ^bb507 {llvm.loop_annotation = #loop_annotation}
    ^bb500:  // pred: ^bb499
      cf.br ^bb501(%c0_i32 : i32)
    ^bb501(%1320: i32):  // 2 preds: ^bb500, ^bb505
      %1321 = arith.cmpi slt, %1320, %1280 : i32
      cf.cond_br %1321, ^bb502, ^bb506 {llvm.loop_annotation = #loop_annotation}
    ^bb502:  // pred: ^bb501
      cf.br ^bb503(%c0_i32 : i32)
    ^bb503(%1322: i32):  // 2 preds: ^bb502, ^bb504
      %1323 = arith.cmpi slt, %1322, %1280 : i32
      cf.cond_br %1323, ^bb504, ^bb505 {llvm.loop_annotation = #loop_annotation}
    ^bb504:  // pred: ^bb503
      cute_nvgpu.arch.mma.SM100.umma(%tup_585, %tup_587, %ptr_579, %1317, %1311) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1324 = arith.addi %1322, %c1_i32 : i32
      cf.br ^bb503(%1324 : i32)
    ^bb505:  // pred: ^bb503
      %1325 = arith.addi %1320, %c1_i32 : i32
      cf.br ^bb501(%1325 : i32)
    ^bb506:  // pred: ^bb501
      %1326 = arith.addi %1318, %c1_i32 : i32
      cf.br ^bb499(%1326 : i32)
    ^bb507:  // pred: ^bb499
      %1327 = cute_nvgpu.atom.set_value(%1308, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1328 = builtin.unrealized_conversion_cast %1327 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %1329 = arith.addi %1305, %c1_i32 : i32
      cf.br ^bb497(%1329, %1328 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb508:  // pred: ^bb497
      %1330 = nvvm.elect.sync -> i1
      cf.cond_br %1330, ^bb509, ^bb510
    ^bb509:  // pred: ^bb508
      %ptr_588 = cute.add_offset(%ptr_95, %int_tuple_575) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1331 = builtin.unrealized_conversion_cast %ptr_588 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1331, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb510
    ^bb510:  // 2 preds: ^bb508, ^bb509
      %1332 = arith.addi %1289, %c1_i32 : i32
      cf.br ^bb491(%1332, %1298, %1300, %1302, %1306 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb511:  // pred: ^bb491
      %1333 = arith.addi %1281, %c1_i32 : i32
      cf.br ^bb489(%1333, %1293, %1290, %1291, %1292 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb512:  // pred: ^bb489
      %1334 = nvvm.elect.sync -> i1
      cf.cond_br %1334, ^bb513, ^bb514
    ^bb513:  // pred: ^bb512
      %ptr_589 = cute.add_offset(%iter_111, %int_tuple_570) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1335 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1335, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb514
    ^bb514:  // 2 preds: ^bb512, ^bb513
      %1336 = nvvm.elect.sync -> i1
      cf.cond_br %1336, ^bb515, ^bb516
    ^bb515:  // pred: ^bb514
      %ptr_590 = cute.add_offset(%ptr_108, %int_tuple_568) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1337 = builtin.unrealized_conversion_cast %ptr_590 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1337, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb516
    ^bb516:  // 2 preds: ^bb514, ^bb515
      cf.br ^bb518(%1268, %1270, %1272, %1275, %1277, %1279, %1282, %1283, %1284, %1285 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb517:  // pred: ^bb479
      cf.br ^bb518(%1260, %1261, %1262, %1263, %1264, %1265, %1259, %1256, %1257, %1258 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb518(%1338: i32, %1339: i32, %1340: i32, %1341: i32, %1342: i32, %1343: i32, %1344: !llvm.struct<(i1, i1, i1)>, %1345: i32, %1346: i32, %1347: i32):  // 2 preds: ^bb516, ^bb517
      cf.br ^bb519
    ^bb519:  // pred: ^bb518
      cf.br ^bb247(%1250, %1251, %1252, %1253, %1254, %1255, %1345, %1346, %1347, %1344, %1338, %1339, %1340, %1341, %1342, %1343, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1)
    ^bb520:  // pred: ^bb247
      %1348 = arith.remsi %258, %c2_i32 : i32
      %1349 = arith.cmpi eq, %1348, %c0_i32 : i32
      cf.cond_br %1349, ^bb521, ^bb526
    ^bb521:  // pred: ^bb520
      %1350 = arith.addi %745, %c1_i32 : i32
      %1351 = arith.cmpi eq, %1350, %c2_i32 : i32
      %1352 = arith.select %1351, %c0_i32, %1350 : i32
      cf.cond_br %1351, ^bb522, ^bb523
    ^bb522:  // pred: ^bb521
      %1353 = arith.xori %746, %c1_i32 : i32
      cf.br ^bb524(%1353 : i32)
    ^bb523:  // pred: ^bb521
      cf.br ^bb524(%746 : i32)
    ^bb524(%1354: i32):  // 2 preds: ^bb522, ^bb523
      cf.br ^bb525
    ^bb525:  // pred: ^bb524
      %int_tuple_591 = cute.make_int_tuple(%1352) : (i32) -> !cute.int_tuple<"?">
      %ptr_592 = cute.add_offset(%ptr_103, %int_tuple_591) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1355 = builtin.unrealized_conversion_cast %ptr_592 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1355, %1354, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb526
    ^bb526:  // 2 preds: ^bb520, ^bb525
      cf.cond_br %1349, ^bb527, ^bb528
    ^bb527:  // pred: ^bb526
      %int_tuple_593 = cute.make_int_tuple(%758) : (i32) -> !cute.int_tuple<"?">
      %ptr_594 = cute.add_offset(%ptr_112, %int_tuple_593) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1356 = builtin.unrealized_conversion_cast %ptr_594 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1356, %759, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb528
    ^bb528:  // 2 preds: ^bb526, ^bb527
      cf.br ^bb534(%760 : i1)
    ^bb529:  // pred: ^bb241
      cf.cond_br %326, ^bb530, ^bb533
    ^bb530:  // pred: ^bb529
      %1357 = nvvm.elect.sync -> i1
      cf.cond_br %1357, ^bb531, ^bb532
    ^bb531:  // pred: ^bb530
      %1358 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1358, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb532
    ^bb532:  // 2 preds: ^bb530, ^bb531
      cf.br ^bb533
    ^bb533:  // 2 preds: ^bb529, ^bb532
      nvvm.fence.mbarrier.init
      cf.br ^bb534(%734 : i1)
    ^bb534(%1359: i1):  // 2 preds: ^bb528, ^bb533
      cf.br ^bb535
    ^bb535:  // pred: ^bb534
      cf.cond_br %326, ^bb536, ^bb539
    ^bb536:  // pred: ^bb535
      %1360 = nvvm.elect.sync -> i1
      cf.cond_br %1360, ^bb537, ^bb538
    ^bb537:  // pred: ^bb536
      %1361 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1361, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb538
    ^bb538:  // 2 preds: ^bb536, ^bb537
      cf.br ^bb539
    ^bb539:  // 2 preds: ^bb535, ^bb538
      nvvm.fence.mbarrier.init
      %1362 = arith.cmpi slt, %236, %c12_i32 : i32
      %1363 = arith.cmpi sge, %236, %c8_i32 : i32
      %1364 = arith.extui %1362 : i1 to i32
      %1365 = arith.extui %1363 : i1 to i32
      %1366 = arith.select %1362, %1365, %1364 : i32
      %1367 = arith.cmpi ne, %1366, %c0_i32 : i32
      cf.cond_br %1367, ^bb540, ^bb635
    ^bb540:  // pred: ^bb539
      cf.cond_br %326, ^bb541, ^bb544
    ^bb541:  // pred: ^bb540
      %1368 = nvvm.elect.sync -> i1
      cf.cond_br %1368, ^bb542, ^bb543
    ^bb542:  // pred: ^bb541
      %1369 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1369, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb543
    ^bb543:  // 2 preds: ^bb541, ^bb542
      cf.br ^bb544
    ^bb544:  // 2 preds: ^bb540, ^bb543
      nvvm.fence.mbarrier.init
      nvvm.setmaxregister  increase 192
      cf.cond_br %326, ^bb545, ^bb546
    ^bb545:  // pred: ^bb544
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_12) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb546
    ^bb546:  // 2 preds: ^bb544, ^bb545
      nvvm.barrier id = %c1_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_12) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_595 = cute.make_int_tuple(%itup_247) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %1370 = cute.get_scalars(%int_tuple_595) <{only_dynamic}> : !cute.int_tuple<"?">
      %1371 = arith.ceildivsi %1370, %c256_i32 : i32
      %int_tuple_596 = cute.make_int_tuple(%1371) : (i32) -> !cute.int_tuple<"?">
      %e0_597 = cute.get_leaves(%int_tuple_596) : !cute.int_tuple<"?">
      %sub_598 = cute.tuple_sub(%e0_597, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %1372 = cute.get_scalars(%sub_598) : !cute.int_tuple<"?">
      %coord_599 = cute.make_coord(%238, %373, %374) : (i32, i32, i32) -> !cute.coord<"(_,_,?,_,(?,?))">
      %1373:10 = cute.get_scalars(%lay_221) <{only_dynamic}> : !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %shape_600 = cute.make_shape(%1373#1) : (i32) -> !cute.shape<"(64,256,?)">
      %iv_601 = cute.assume(%1373#5) : (i32) -> !cute.i32<divby 256>
      %stride_602 = cute.make_stride(%iv_601) : (!cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1,256)">
      %lay_603 = cute.make_layout(%shape_600, %stride_602) : !cute.layout<"(64,256,?):(?{div=256},1,256)">
      %idx_604 = cute.crd2idx(%coord_599, %lay_221) : (!cute.coord<"(_,_,?,_,(?,?))">, !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.int_tuple<"?{div=256}">
      %ptr_605 = cute.add_offset(%iter_213, %idx_604) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, gmem, align<128>>
      %1374:5 = cute.get_scalars(%lay_235) <{only_dynamic}> : !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %shape_606 = cute.make_shape(%1374#1) : (i32) -> !cute.shape<"(64,256,?)">
      %lay_607 = cute.make_layout(%shape_606, %156) : !cute.layout<"(64,256,?):(1@0,1@1,256@1)">
      %idx_608 = cute.crd2idx(%coord_599, %lay_235) : (!cute.coord<"(_,_,?,_,(?,?))">, !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">) -> !cute.int_tuple<"(?{div=64},0,((?,?),?))">
      %tup_609 = cute.add_offset(%175, %idx_608) : (!cute.int_tuple<"(0,0,((0,0),0))">, !cute.int_tuple<"(?{div=64},0,((?,?),?))">) -> !cute.int_tuple<"(?{div=64},0,((?,?),?))">
      %1375 = arith.remsi %225, %c128_i32 : i32
      %coord_610 = cute.make_coord(%1375) : (i32) -> !cute.coord<"?">
      %1376 = cute.get_scalars(%coord_610) <{only_dynamic}> : !cute.coord<"?">
      %1377 = arith.divsi %1376, %c32_i32 : i32
      %1378 = arith.divsi %1377, %c2_i32 : i32
      %1379 = arith.remsi %1377, %c2_i32 : i32
      %1380 = arith.muli %1379, %c2097152_i32 : i32
      %1381 = arith.muli %1378, %c4194304_i32 : i32
      %1382 = arith.addi %1380, %1381 : i32
      %iv_611 = cute.assume(%1382) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_612 = cute.make_int_tuple(%iv_611) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1383 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %1384 = arith.addi %1375, %c64_i32 : i32
      %1385 = arith.remsi %1384, %c128_i32 : i32
      %coord_613 = cute.make_coord(%1385) : (i32) -> !cute.coord<"?">
      %1386 = vector.splat %arg13 : vector<2xf32>
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %1387 = arith.remsi %1376, %c32_i32 : i32
      %1388 = arith.muli %1387, %c64_i32 : i32
      %1389 = arith.muli %1379, %c2048_i32 : i32
      %1390 = arith.addi %1388, %1389 : i32
      %1391 = arith.muli %1378, %c8192_i32 : i32
      %1392 = arith.addi %1390, %1391 : i32
      %iv_614 = cute.assume(%1392) : (i32) -> !cute.i32<divby 64>
      %int_tuple_615 = cute.make_int_tuple(%iv_614) : (!cute.i32<divby 64>) -> !cute.int_tuple<"?{div=64}">
      %ptr_616 = cute.add_offset(%iter_128, %int_tuple_615) : (!cute.ptr<bf16, smem, align<256>, S<3,4,3>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>, S<3,4,3>>
      %1393 = vector.splat %arg13 : vector<2xf32>
      %1394 = arith.muli %1377, %c2097152_i32 : i32
      %iv_617 = cute.assume(%1394) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_618 = cute.make_int_tuple(%iv_617) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1395 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %1396:2 = cute.get_scalars(%lay_603) <{only_dynamic}> : !cute.layout<"(64,256,?):(?{div=256},1,256)">
      %iv_619 = cute.assume(%1396#1) : (i32) -> !cute.i32<divby 256>
      %stride_620 = cute.make_stride(%iv_619) : (!cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1)">
      %lay_621 = cute.make_layout(%19, %stride_620) : !cute.layout<"(64,256):(?{div=256},1)">
      %1397 = cute.get_scalars(%lay_621) <{only_dynamic}> : !cute.layout<"(64,256):(?{div=256},1)">
      %iv_622 = cute.assume(%1397) : (i32) -> !cute.i32<divby 256>
      %stride_623 = cute.make_stride(%iv_622) : (!cute.i32<divby 256>) -> !cute.stride<"((?{div=256},(1,128)),(0,32))">
      %lay_624 = cute.make_layout(%18, %stride_623) : !cute.layout<"((64,(32,2)),(1,4)):((?{div=256},(1,128)),(0,32))">
      %1398 = arith.muli %1377, %c2097152_i32 : i32
      %iv_625 = cute.assume(%1398) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_626 = cute.make_int_tuple(%iv_625) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1399 = cute.get_scalars(%lay_624) <{only_dynamic}> : !cute.layout<"((64,(32,2)),(1,4)):((?{div=256},(1,128)),(0,32))">
      %1400 = arith.muli %1399, %c32_i32 : i32
      %1401 = arith.muli %1387, %1399 : i32
      %1402 = arith.muli %1379, %1400 : i32
      %1403 = arith.muli %1378, %c128_i32 : i32
      %1404 = arith.addi %1402, %1403 : i32
      %1405 = arith.addi %1401, %1404 : i32
      %iv_627 = cute.assume(%1405) : (i32) -> !cute.i32<divby 128>
      %int_tuple_628 = cute.make_int_tuple(%iv_627) : (!cute.i32<divby 128>) -> !cute.int_tuple<"?{div=128}">
      %1406 = arith.muli %1379, %c32_i32 : i32
      %1407 = arith.addi %1387, %1406 : i32
      %iv_629 = cute.assume(%1403) : (i32) -> !cute.i32<divby 128>
      %int_tuple_630 = cute.make_int_tuple(%1407, %iv_629) : (i32, !cute.i32<divby 128>) -> !cute.int_tuple<"(?,?{div=128})">
      %1408 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %coord_631 = cute.make_coord(%itup_241) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1409 = cute.get_scalars(%coord_631) : !cute.coord<"?">
      cf.br ^bb547(%c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %1359 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb547(%1410: i32, %1411: i32, %1412: i32, %1413: i32, %1414: i32, %1415: i32, %1416: i32, %1417: i32, %1418: i32, %1419: i1):  // 2 preds: ^bb546, ^bb625
      cf.cond_br %1419, ^bb548(%1410, %1411, %1412, %1413, %1414, %1415, %1416, %1417, %1418, %1419 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1), ^bb626
    ^bb548(%1420: i32, %1421: i32, %1422: i32, %1423: i32, %1424: i32, %1425: i32, %1426: i32, %1427: i32, %1428: i32, %1429: i1):  // pred: ^bb547
      %int_tuple_632 = cute.make_int_tuple(%1421) : (i32) -> !cute.int_tuple<"?">
      %ptr_633 = cute.add_offset(%iter_101, %int_tuple_632) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1430 = builtin.unrealized_conversion_cast %ptr_633 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1430, %1422, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1431 = arith.addi %1421, %c1_i32 : i32
      %1432 = arith.addi %1420, %c1_i32 : i32
      %1433 = arith.cmpi eq, %1431, %c2_i32 : i32
      %1434 = arith.select %1433, %c0_i32, %1431 : i32
      cf.cond_br %1433, ^bb549, ^bb550
    ^bb549:  // pred: ^bb548
      %1435 = arith.xori %1422, %c1_i32 : i32
      cf.br ^bb551(%1435 : i32)
    ^bb550:  // pred: ^bb548
      cf.br ^bb551(%1422 : i32)
    ^bb551(%1436: i32):  // 2 preds: ^bb549, ^bb550
      cf.br ^bb552
    ^bb552:  // pred: ^bb551
      %coord_634 = cute.make_coord(%1421) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_635 = cute.crd2idx(%coord_634, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_636 = cute.add_offset(%329, %idx_635) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_637 = cute.add_offset(%ptr_636, %int_tuple_612) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_638 = cute.get_iter(%rmem) : !memref_rmem_f32_
      cf.br ^bb553(%c0_i32 : i32)
    ^bb553(%1437: i32):  // 2 preds: ^bb552, ^bb554
      %1438 = arith.cmpi slt, %1437, %1383 : i32
      cf.cond_br %1438, ^bb554, ^bb555 {llvm.loop_annotation = #loop_annotation}
    ^bb554:  // pred: ^bb553
      %coord_639 = cute.make_coord(%1437) : (i32) -> !cute.coord<"(_,?)">
      %idx_640 = cute.crd2idx(%coord_639, %153) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,32),1),((1,4))):(((1,65536),0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_641 = cute.add_offset(%ptr_637, %idx_640) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_642 = cute.crd2idx(%coord_639, %152) : (!cute.coord<"(_,?)">, !cute.layout<"((32,1),((1,4))):((1,0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_643 = cute.add_offset(%iter_638, %idx_642) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, rmem, align<32>>
      %1439 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_641) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      %1440 = builtin.unrealized_conversion_cast %ptr_643 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      llvm.store %1439, %1440 : vector<32xi32>, !llvm.ptr
      %1441 = arith.addi %1437, %c1_i32 : i32
      cf.br ^bb553(%1441 : i32)
    ^bb555:  // pred: ^bb553
      nvvm.tcgen05.wait <load>
      %ptr_644 = cute.add_offset(%ptr_103, %int_tuple_632) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1442 = builtin.unrealized_conversion_cast %ptr_644 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %1443 = nvvm.mapa.shared.cluster %1442, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %1443, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %1444 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %1445 = vector.reduction <maximumf>, %1444, %cst_2 : vector<128xf32> into f32
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_610, %1445) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %1446 = cute.memref.load(%view, %coord_613) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %1447 = nvvm.fmax %1445, %1446
      %1448 = arith.cmpf oeq, %1447, %cst_2 : f32
      %1449 = arith.select %1448, %cst_1, %1447 : f32
      %1450 = arith.subf %cst_1, %1449 : f32
      %1451 = arith.mulf %1450, %arg13 : f32
      %rmem_645 = cute.memref.alloca() : !memref_rmem_bf16_
      %1452 = vector.splat %1451 : vector<2xf32>
      cf.br ^bb556(%c0_i32 : i32)
    ^bb556(%1453: i32):  // 2 preds: ^bb555, ^bb557
      %1454 = arith.cmpi slt, %1453, %c128_i32 : i32
      cf.cond_br %1454, ^bb557, ^bb558
    ^bb557:  // pred: ^bb556
      %coord_646 = cute.make_coord(%1453) : (i32) -> !cute.coord<"?">
      %1455 = cute.memref.load(%rmem, %coord_646) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1456 = arith.addi %1453, %c1_i32 : i32
      %coord_647 = cute.make_coord(%1456) : (i32) -> !cute.coord<"?">
      %1457 = cute.memref.load(%rmem, %coord_647) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1458 = vector.from_elements %1455, %1457 : vector<2xf32>
      %1459 = nvvm.fma.packed.f32x2 %1458, %1386, %1452 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1460 = vector.extract %1459[0] : f32 from vector<2xf32>
      %1461 = vector.extract %1459[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem, %coord_646, %1460) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem, %coord_647, %1461) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1462 = cute.memref.load(%rmem, %coord_646) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1463 = math.exp2 %1462 fastmath<fast> : f32
      cute.memref.store(%rmem, %coord_646, %1463) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1464 = cute.memref.load(%rmem, %coord_647) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1465 = math.exp2 %1464 fastmath<fast> : f32
      cute.memref.store(%rmem, %coord_647, %1465) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1466 = arith.addi %1453, %c2_i32 : i32
      cf.br ^bb556(%1466 : i32)
    ^bb558:  // pred: ^bb556
      %1467 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %1468 = arith.truncf %1467 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %1468, %rmem_645 : !memref_rmem_bf16_
      %int_tuple_648 = cute.make_int_tuple(%1424) : (i32) -> !cute.int_tuple<"?">
      %ptr_649 = cute.add_offset(%ptr_108, %int_tuple_648) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1469 = builtin.unrealized_conversion_cast %ptr_649 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1469, %1425, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1470 = arith.addi %1424, %c1_i32 : i32
      %1471 = arith.addi %1423, %c1_i32 : i32
      %1472 = arith.cmpi eq, %1470, %c2_i32 : i32
      %1473 = arith.select %1472, %c0_i32, %1470 : i32
      cf.cond_br %1472, ^bb559, ^bb560
    ^bb559:  // pred: ^bb558
      %1474 = arith.xori %1425, %c1_i32 : i32
      cf.br ^bb561(%1474 : i32)
    ^bb560:  // pred: ^bb558
      cf.br ^bb561(%1425 : i32)
    ^bb561(%1475: i32):  // 2 preds: ^bb559, ^bb560
      cf.br ^bb562
    ^bb562:  // pred: ^bb561
      %coord_650 = cute.make_coord(%1424) : (i32) -> !cute.coord<"(_,_,_,(_,?))">
      %idx_651 = cute.crd2idx(%coord_650, %204) : (!cute.coord<"(_,_,_,(_,?))">, !cute.layout<"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">) -> !cute.int_tuple<"?{div=16384}">
      %1476 = cute.make_tiled_copy(%atom) : !copy_simt
      %iter_652 = cute.get_iter(%rmem_645) : !memref_rmem_bf16_
      cf.br ^bb563(%c0_i32 : i32)
    ^bb563(%1477: i32):  // 2 preds: ^bb562, ^bb564
      %1478 = arith.cmpi slt, %1477, %1383 : i32
      cf.cond_br %1478, ^bb564, ^bb565 {llvm.loop_annotation = #loop_annotation}
    ^bb564:  // pred: ^bb563
      %coord_653 = cute.make_coord(%1477) : (i32) -> !cute.coord<"(_,?)">
      %idx_654 = cute.crd2idx(%coord_653, %151) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,4))):((1,8),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_655 = cute.add_offset(%iter_652, %idx_654) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_656 = cute.crd2idx(%coord_653, %150) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,(2,2)))):((1,8),((0,(32,4096))))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_657 = cute.add_offset(%ptr_616, %idx_656) : (!cute.ptr<bf16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %swizzled = cute.apply_swizzle(%ptr_657) : !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %ptr_658 = cute.add_offset(%swizzled, %idx_651) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %1479 = builtin.unrealized_conversion_cast %ptr_655 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1480 = builtin.unrealized_conversion_cast %ptr_658 : !cute.ptr<bf16, smem, align<64>, S<3,4,3>> to !llvm.ptr<3>
      %1481 = llvm.load %1479 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1481, %1480 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_659 = cute.add_offset(%ptr_655, %205) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_660 = cute.add_offset(%ptr_657, %205) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_661 = cute.apply_swizzle(%ptr_660) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_662 = cute.add_offset(%swizzled_661, %idx_651) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1482 = builtin.unrealized_conversion_cast %ptr_659 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1483 = builtin.unrealized_conversion_cast %ptr_662 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1484 = llvm.load %1482 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1484, %1483 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_663 = cute.add_offset(%ptr_655, %149) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_664 = cute.add_offset(%ptr_657, %149) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %swizzled_665 = cute.apply_swizzle(%ptr_664) : !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %ptr_666 = cute.add_offset(%swizzled_665, %idx_651) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %1485 = builtin.unrealized_conversion_cast %ptr_663 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1486 = builtin.unrealized_conversion_cast %ptr_666 : !cute.ptr<bf16, smem, align<32>, S<3,4,3>> to !llvm.ptr<3>
      %1487 = llvm.load %1485 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1487, %1486 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_667 = cute.add_offset(%ptr_655, %148) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_668 = cute.add_offset(%ptr_657, %148) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_669 = cute.apply_swizzle(%ptr_668) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_670 = cute.add_offset(%swizzled_669, %idx_651) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1488 = builtin.unrealized_conversion_cast %ptr_667 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1489 = builtin.unrealized_conversion_cast %ptr_670 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1490 = llvm.load %1488 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1490, %1489 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %1491 = arith.addi %1477, %c1_i32 : i32
      cf.br ^bb563(%1491 : i32)
    ^bb565:  // pred: ^bb563
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_671 = cute.add_offset(%iter_106, %int_tuple_648) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1492 = builtin.unrealized_conversion_cast %ptr_671 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %1493 = nvvm.mapa.shared.cluster %1492, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %1493, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %1494 = arith.subf %cst_2, %1449 : f32
      %1495 = arith.mulf %arg13, %1494 : f32
      %1496 = math.exp2 %1495 fastmath<fast> : f32
      %1497 = arith.mulf %1496, %cst_0 : f32
      %1498 = arith.mulf %1497, %cst_1 : f32
      %view_672 = cute.make_view(%iter_638) : !memref_rmem_f32_1
      %1499 = cute.memref.load(%view_672, %147) : (!memref_rmem_f32_1, !cute.coord<"(0,0)">) -> f32
      %1500 = cute.memref.load(%view_672, %146) : (!memref_rmem_f32_1, !cute.coord<"(1,0)">) -> f32
      %1501 = vector.splat %1498 : vector<2xf32>
      %1502 = vector.from_elements %1499, %1500 : vector<2xf32>
      %1503 = nvvm.add.packed.f32x2 %1501, %1502 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1504 = vector.extract %1503[0] : f32 from vector<2xf32>
      %1505 = vector.extract %1503[1] : f32 from vector<2xf32>
      %1506 = cute.memref.load(%view_672, %145) : (!memref_rmem_f32_1, !cute.coord<"(0,1)">) -> f32
      %1507 = cute.memref.load(%view_672, %144) : (!memref_rmem_f32_1, !cute.coord<"(1,1)">) -> f32
      %1508 = vector.from_elements %1506, %1507 : vector<2xf32>
      %1509 = nvvm.add.packed.f32x2 %cst, %1508 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1510 = vector.extract %1509[0] : f32 from vector<2xf32>
      %1511 = vector.extract %1509[1] : f32 from vector<2xf32>
      %1512 = cute.memref.load(%view_672, %143) : (!memref_rmem_f32_1, !cute.coord<"(0,2)">) -> f32
      %1513 = cute.memref.load(%view_672, %142) : (!memref_rmem_f32_1, !cute.coord<"(1,2)">) -> f32
      %1514 = vector.from_elements %1512, %1513 : vector<2xf32>
      %1515 = nvvm.add.packed.f32x2 %cst, %1514 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1516 = vector.extract %1515[0] : f32 from vector<2xf32>
      %1517 = vector.extract %1515[1] : f32 from vector<2xf32>
      %1518 = cute.memref.load(%view_672, %141) : (!memref_rmem_f32_1, !cute.coord<"(0,3)">) -> f32
      %1519 = cute.memref.load(%view_672, %140) : (!memref_rmem_f32_1, !cute.coord<"(1,3)">) -> f32
      %1520 = vector.from_elements %1518, %1519 : vector<2xf32>
      %1521 = nvvm.add.packed.f32x2 %cst, %1520 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1522 = vector.extract %1521[0] : f32 from vector<2xf32>
      %1523 = vector.extract %1521[1] : f32 from vector<2xf32>
      %1524 = cute.memref.load(%view_672, %139) : (!memref_rmem_f32_1, !cute.coord<"(2,0)">) -> f32
      %1525 = cute.memref.load(%view_672, %138) : (!memref_rmem_f32_1, !cute.coord<"(3,0)">) -> f32
      %1526 = vector.from_elements %1504, %1505 : vector<2xf32>
      %1527 = vector.from_elements %1524, %1525 : vector<2xf32>
      %1528 = nvvm.add.packed.f32x2 %1526, %1527 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1529 = vector.extract %1528[0] : f32 from vector<2xf32>
      %1530 = vector.extract %1528[1] : f32 from vector<2xf32>
      %1531 = cute.memref.load(%view_672, %137) : (!memref_rmem_f32_1, !cute.coord<"(2,1)">) -> f32
      %1532 = cute.memref.load(%view_672, %136) : (!memref_rmem_f32_1, !cute.coord<"(3,1)">) -> f32
      %1533 = vector.from_elements %1510, %1511 : vector<2xf32>
      %1534 = vector.from_elements %1531, %1532 : vector<2xf32>
      %1535 = nvvm.add.packed.f32x2 %1533, %1534 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1536 = vector.extract %1535[0] : f32 from vector<2xf32>
      %1537 = vector.extract %1535[1] : f32 from vector<2xf32>
      %1538 = cute.memref.load(%view_672, %135) : (!memref_rmem_f32_1, !cute.coord<"(2,2)">) -> f32
      %1539 = cute.memref.load(%view_672, %134) : (!memref_rmem_f32_1, !cute.coord<"(3,2)">) -> f32
      %1540 = vector.from_elements %1516, %1517 : vector<2xf32>
      %1541 = vector.from_elements %1538, %1539 : vector<2xf32>
      %1542 = nvvm.add.packed.f32x2 %1540, %1541 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1543 = vector.extract %1542[0] : f32 from vector<2xf32>
      %1544 = vector.extract %1542[1] : f32 from vector<2xf32>
      %1545 = cute.memref.load(%view_672, %133) : (!memref_rmem_f32_1, !cute.coord<"(2,3)">) -> f32
      %1546 = cute.memref.load(%view_672, %132) : (!memref_rmem_f32_1, !cute.coord<"(3,3)">) -> f32
      %1547 = vector.from_elements %1522, %1523 : vector<2xf32>
      %1548 = vector.from_elements %1545, %1546 : vector<2xf32>
      %1549 = nvvm.add.packed.f32x2 %1547, %1548 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1550 = vector.extract %1549[0] : f32 from vector<2xf32>
      %1551 = vector.extract %1549[1] : f32 from vector<2xf32>
      %1552 = cute.memref.load(%view_672, %131) : (!memref_rmem_f32_1, !cute.coord<"(4,0)">) -> f32
      %1553 = cute.memref.load(%view_672, %130) : (!memref_rmem_f32_1, !cute.coord<"(5,0)">) -> f32
      %1554 = vector.from_elements %1529, %1530 : vector<2xf32>
      %1555 = vector.from_elements %1552, %1553 : vector<2xf32>
      %1556 = nvvm.add.packed.f32x2 %1554, %1555 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1557 = vector.extract %1556[0] : f32 from vector<2xf32>
      %1558 = vector.extract %1556[1] : f32 from vector<2xf32>
      %1559 = cute.memref.load(%view_672, %129) : (!memref_rmem_f32_1, !cute.coord<"(4,1)">) -> f32
      %1560 = cute.memref.load(%view_672, %128) : (!memref_rmem_f32_1, !cute.coord<"(5,1)">) -> f32
      %1561 = vector.from_elements %1536, %1537 : vector<2xf32>
      %1562 = vector.from_elements %1559, %1560 : vector<2xf32>
      %1563 = nvvm.add.packed.f32x2 %1561, %1562 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1564 = vector.extract %1563[0] : f32 from vector<2xf32>
      %1565 = vector.extract %1563[1] : f32 from vector<2xf32>
      %1566 = cute.memref.load(%view_672, %127) : (!memref_rmem_f32_1, !cute.coord<"(4,2)">) -> f32
      %1567 = cute.memref.load(%view_672, %126) : (!memref_rmem_f32_1, !cute.coord<"(5,2)">) -> f32
      %1568 = vector.from_elements %1543, %1544 : vector<2xf32>
      %1569 = vector.from_elements %1566, %1567 : vector<2xf32>
      %1570 = nvvm.add.packed.f32x2 %1568, %1569 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1571 = vector.extract %1570[0] : f32 from vector<2xf32>
      %1572 = vector.extract %1570[1] : f32 from vector<2xf32>
      %1573 = cute.memref.load(%view_672, %125) : (!memref_rmem_f32_1, !cute.coord<"(4,3)">) -> f32
      %1574 = cute.memref.load(%view_672, %124) : (!memref_rmem_f32_1, !cute.coord<"(5,3)">) -> f32
      %1575 = vector.from_elements %1550, %1551 : vector<2xf32>
      %1576 = vector.from_elements %1573, %1574 : vector<2xf32>
      %1577 = nvvm.add.packed.f32x2 %1575, %1576 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1578 = vector.extract %1577[0] : f32 from vector<2xf32>
      %1579 = vector.extract %1577[1] : f32 from vector<2xf32>
      %1580 = cute.memref.load(%view_672, %123) : (!memref_rmem_f32_1, !cute.coord<"(6,0)">) -> f32
      %1581 = cute.memref.load(%view_672, %122) : (!memref_rmem_f32_1, !cute.coord<"(7,0)">) -> f32
      %1582 = vector.from_elements %1557, %1558 : vector<2xf32>
      %1583 = vector.from_elements %1580, %1581 : vector<2xf32>
      %1584 = nvvm.add.packed.f32x2 %1582, %1583 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1585 = vector.extract %1584[0] : f32 from vector<2xf32>
      %1586 = vector.extract %1584[1] : f32 from vector<2xf32>
      %1587 = cute.memref.load(%view_672, %121) : (!memref_rmem_f32_1, !cute.coord<"(6,1)">) -> f32
      %1588 = cute.memref.load(%view_672, %120) : (!memref_rmem_f32_1, !cute.coord<"(7,1)">) -> f32
      %1589 = vector.from_elements %1564, %1565 : vector<2xf32>
      %1590 = vector.from_elements %1587, %1588 : vector<2xf32>
      %1591 = nvvm.add.packed.f32x2 %1589, %1590 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1592 = vector.extract %1591[0] : f32 from vector<2xf32>
      %1593 = vector.extract %1591[1] : f32 from vector<2xf32>
      %1594 = cute.memref.load(%view_672, %119) : (!memref_rmem_f32_1, !cute.coord<"(6,2)">) -> f32
      %1595 = cute.memref.load(%view_672, %118) : (!memref_rmem_f32_1, !cute.coord<"(7,2)">) -> f32
      %1596 = vector.from_elements %1571, %1572 : vector<2xf32>
      %1597 = vector.from_elements %1594, %1595 : vector<2xf32>
      %1598 = nvvm.add.packed.f32x2 %1596, %1597 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1599 = vector.extract %1598[0] : f32 from vector<2xf32>
      %1600 = vector.extract %1598[1] : f32 from vector<2xf32>
      %1601 = cute.memref.load(%view_672, %117) : (!memref_rmem_f32_1, !cute.coord<"(6,3)">) -> f32
      %1602 = cute.memref.load(%view_672, %116) : (!memref_rmem_f32_1, !cute.coord<"(7,3)">) -> f32
      %1603 = vector.from_elements %1578, %1579 : vector<2xf32>
      %1604 = vector.from_elements %1601, %1602 : vector<2xf32>
      %1605 = nvvm.add.packed.f32x2 %1603, %1604 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1606 = vector.extract %1605[0] : f32 from vector<2xf32>
      %1607 = vector.extract %1605[1] : f32 from vector<2xf32>
      %1608 = cute.memref.load(%view_672, %115) : (!memref_rmem_f32_1, !cute.coord<"(8,0)">) -> f32
      %1609 = cute.memref.load(%view_672, %114) : (!memref_rmem_f32_1, !cute.coord<"(9,0)">) -> f32
      %1610 = vector.from_elements %1585, %1586 : vector<2xf32>
      %1611 = vector.from_elements %1608, %1609 : vector<2xf32>
      %1612 = nvvm.add.packed.f32x2 %1610, %1611 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1613 = vector.extract %1612[0] : f32 from vector<2xf32>
      %1614 = vector.extract %1612[1] : f32 from vector<2xf32>
      %1615 = cute.memref.load(%view_672, %113) : (!memref_rmem_f32_1, !cute.coord<"(8,1)">) -> f32
      %1616 = cute.memref.load(%view_672, %112) : (!memref_rmem_f32_1, !cute.coord<"(9,1)">) -> f32
      %1617 = vector.from_elements %1592, %1593 : vector<2xf32>
      %1618 = vector.from_elements %1615, %1616 : vector<2xf32>
      %1619 = nvvm.add.packed.f32x2 %1617, %1618 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1620 = vector.extract %1619[0] : f32 from vector<2xf32>
      %1621 = vector.extract %1619[1] : f32 from vector<2xf32>
      %1622 = cute.memref.load(%view_672, %111) : (!memref_rmem_f32_1, !cute.coord<"(8,2)">) -> f32
      %1623 = cute.memref.load(%view_672, %110) : (!memref_rmem_f32_1, !cute.coord<"(9,2)">) -> f32
      %1624 = vector.from_elements %1599, %1600 : vector<2xf32>
      %1625 = vector.from_elements %1622, %1623 : vector<2xf32>
      %1626 = nvvm.add.packed.f32x2 %1624, %1625 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1627 = vector.extract %1626[0] : f32 from vector<2xf32>
      %1628 = vector.extract %1626[1] : f32 from vector<2xf32>
      %1629 = cute.memref.load(%view_672, %109) : (!memref_rmem_f32_1, !cute.coord<"(8,3)">) -> f32
      %1630 = cute.memref.load(%view_672, %108) : (!memref_rmem_f32_1, !cute.coord<"(9,3)">) -> f32
      %1631 = vector.from_elements %1606, %1607 : vector<2xf32>
      %1632 = vector.from_elements %1629, %1630 : vector<2xf32>
      %1633 = nvvm.add.packed.f32x2 %1631, %1632 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1634 = vector.extract %1633[0] : f32 from vector<2xf32>
      %1635 = vector.extract %1633[1] : f32 from vector<2xf32>
      %1636 = cute.memref.load(%view_672, %107) : (!memref_rmem_f32_1, !cute.coord<"(10,0)">) -> f32
      %1637 = cute.memref.load(%view_672, %106) : (!memref_rmem_f32_1, !cute.coord<"(11,0)">) -> f32
      %1638 = vector.from_elements %1613, %1614 : vector<2xf32>
      %1639 = vector.from_elements %1636, %1637 : vector<2xf32>
      %1640 = nvvm.add.packed.f32x2 %1638, %1639 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1641 = vector.extract %1640[0] : f32 from vector<2xf32>
      %1642 = vector.extract %1640[1] : f32 from vector<2xf32>
      %1643 = cute.memref.load(%view_672, %105) : (!memref_rmem_f32_1, !cute.coord<"(10,1)">) -> f32
      %1644 = cute.memref.load(%view_672, %104) : (!memref_rmem_f32_1, !cute.coord<"(11,1)">) -> f32
      %1645 = vector.from_elements %1620, %1621 : vector<2xf32>
      %1646 = vector.from_elements %1643, %1644 : vector<2xf32>
      %1647 = nvvm.add.packed.f32x2 %1645, %1646 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1648 = vector.extract %1647[0] : f32 from vector<2xf32>
      %1649 = vector.extract %1647[1] : f32 from vector<2xf32>
      %1650 = cute.memref.load(%view_672, %103) : (!memref_rmem_f32_1, !cute.coord<"(10,2)">) -> f32
      %1651 = cute.memref.load(%view_672, %102) : (!memref_rmem_f32_1, !cute.coord<"(11,2)">) -> f32
      %1652 = vector.from_elements %1627, %1628 : vector<2xf32>
      %1653 = vector.from_elements %1650, %1651 : vector<2xf32>
      %1654 = nvvm.add.packed.f32x2 %1652, %1653 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1655 = vector.extract %1654[0] : f32 from vector<2xf32>
      %1656 = vector.extract %1654[1] : f32 from vector<2xf32>
      %1657 = cute.memref.load(%view_672, %101) : (!memref_rmem_f32_1, !cute.coord<"(10,3)">) -> f32
      %1658 = cute.memref.load(%view_672, %100) : (!memref_rmem_f32_1, !cute.coord<"(11,3)">) -> f32
      %1659 = vector.from_elements %1634, %1635 : vector<2xf32>
      %1660 = vector.from_elements %1657, %1658 : vector<2xf32>
      %1661 = nvvm.add.packed.f32x2 %1659, %1660 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1662 = vector.extract %1661[0] : f32 from vector<2xf32>
      %1663 = vector.extract %1661[1] : f32 from vector<2xf32>
      %1664 = cute.memref.load(%view_672, %99) : (!memref_rmem_f32_1, !cute.coord<"(12,0)">) -> f32
      %1665 = cute.memref.load(%view_672, %98) : (!memref_rmem_f32_1, !cute.coord<"(13,0)">) -> f32
      %1666 = vector.from_elements %1641, %1642 : vector<2xf32>
      %1667 = vector.from_elements %1664, %1665 : vector<2xf32>
      %1668 = nvvm.add.packed.f32x2 %1666, %1667 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1669 = vector.extract %1668[0] : f32 from vector<2xf32>
      %1670 = vector.extract %1668[1] : f32 from vector<2xf32>
      %1671 = cute.memref.load(%view_672, %97) : (!memref_rmem_f32_1, !cute.coord<"(12,1)">) -> f32
      %1672 = cute.memref.load(%view_672, %96) : (!memref_rmem_f32_1, !cute.coord<"(13,1)">) -> f32
      %1673 = vector.from_elements %1648, %1649 : vector<2xf32>
      %1674 = vector.from_elements %1671, %1672 : vector<2xf32>
      %1675 = nvvm.add.packed.f32x2 %1673, %1674 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1676 = vector.extract %1675[0] : f32 from vector<2xf32>
      %1677 = vector.extract %1675[1] : f32 from vector<2xf32>
      %1678 = cute.memref.load(%view_672, %95) : (!memref_rmem_f32_1, !cute.coord<"(12,2)">) -> f32
      %1679 = cute.memref.load(%view_672, %94) : (!memref_rmem_f32_1, !cute.coord<"(13,2)">) -> f32
      %1680 = vector.from_elements %1655, %1656 : vector<2xf32>
      %1681 = vector.from_elements %1678, %1679 : vector<2xf32>
      %1682 = nvvm.add.packed.f32x2 %1680, %1681 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1683 = vector.extract %1682[0] : f32 from vector<2xf32>
      %1684 = vector.extract %1682[1] : f32 from vector<2xf32>
      %1685 = cute.memref.load(%view_672, %93) : (!memref_rmem_f32_1, !cute.coord<"(12,3)">) -> f32
      %1686 = cute.memref.load(%view_672, %92) : (!memref_rmem_f32_1, !cute.coord<"(13,3)">) -> f32
      %1687 = vector.from_elements %1662, %1663 : vector<2xf32>
      %1688 = vector.from_elements %1685, %1686 : vector<2xf32>
      %1689 = nvvm.add.packed.f32x2 %1687, %1688 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1690 = vector.extract %1689[0] : f32 from vector<2xf32>
      %1691 = vector.extract %1689[1] : f32 from vector<2xf32>
      %1692 = cute.memref.load(%view_672, %91) : (!memref_rmem_f32_1, !cute.coord<"(14,0)">) -> f32
      %1693 = cute.memref.load(%view_672, %90) : (!memref_rmem_f32_1, !cute.coord<"(15,0)">) -> f32
      %1694 = vector.from_elements %1669, %1670 : vector<2xf32>
      %1695 = vector.from_elements %1692, %1693 : vector<2xf32>
      %1696 = nvvm.add.packed.f32x2 %1694, %1695 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1697 = vector.extract %1696[0] : f32 from vector<2xf32>
      %1698 = vector.extract %1696[1] : f32 from vector<2xf32>
      %1699 = cute.memref.load(%view_672, %89) : (!memref_rmem_f32_1, !cute.coord<"(14,1)">) -> f32
      %1700 = cute.memref.load(%view_672, %88) : (!memref_rmem_f32_1, !cute.coord<"(15,1)">) -> f32
      %1701 = vector.from_elements %1676, %1677 : vector<2xf32>
      %1702 = vector.from_elements %1699, %1700 : vector<2xf32>
      %1703 = nvvm.add.packed.f32x2 %1701, %1702 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1704 = vector.extract %1703[0] : f32 from vector<2xf32>
      %1705 = vector.extract %1703[1] : f32 from vector<2xf32>
      %1706 = cute.memref.load(%view_672, %87) : (!memref_rmem_f32_1, !cute.coord<"(14,2)">) -> f32
      %1707 = cute.memref.load(%view_672, %86) : (!memref_rmem_f32_1, !cute.coord<"(15,2)">) -> f32
      %1708 = vector.from_elements %1683, %1684 : vector<2xf32>
      %1709 = vector.from_elements %1706, %1707 : vector<2xf32>
      %1710 = nvvm.add.packed.f32x2 %1708, %1709 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1711 = vector.extract %1710[0] : f32 from vector<2xf32>
      %1712 = vector.extract %1710[1] : f32 from vector<2xf32>
      %1713 = cute.memref.load(%view_672, %85) : (!memref_rmem_f32_1, !cute.coord<"(14,3)">) -> f32
      %1714 = cute.memref.load(%view_672, %84) : (!memref_rmem_f32_1, !cute.coord<"(15,3)">) -> f32
      %1715 = vector.from_elements %1690, %1691 : vector<2xf32>
      %1716 = vector.from_elements %1713, %1714 : vector<2xf32>
      %1717 = nvvm.add.packed.f32x2 %1715, %1716 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1718 = vector.extract %1717[0] : f32 from vector<2xf32>
      %1719 = vector.extract %1717[1] : f32 from vector<2xf32>
      %1720 = cute.memref.load(%view_672, %83) : (!memref_rmem_f32_1, !cute.coord<"(16,0)">) -> f32
      %1721 = cute.memref.load(%view_672, %82) : (!memref_rmem_f32_1, !cute.coord<"(17,0)">) -> f32
      %1722 = vector.from_elements %1697, %1698 : vector<2xf32>
      %1723 = vector.from_elements %1720, %1721 : vector<2xf32>
      %1724 = nvvm.add.packed.f32x2 %1722, %1723 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1725 = vector.extract %1724[0] : f32 from vector<2xf32>
      %1726 = vector.extract %1724[1] : f32 from vector<2xf32>
      %1727 = cute.memref.load(%view_672, %81) : (!memref_rmem_f32_1, !cute.coord<"(16,1)">) -> f32
      %1728 = cute.memref.load(%view_672, %80) : (!memref_rmem_f32_1, !cute.coord<"(17,1)">) -> f32
      %1729 = vector.from_elements %1704, %1705 : vector<2xf32>
      %1730 = vector.from_elements %1727, %1728 : vector<2xf32>
      %1731 = nvvm.add.packed.f32x2 %1729, %1730 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1732 = vector.extract %1731[0] : f32 from vector<2xf32>
      %1733 = vector.extract %1731[1] : f32 from vector<2xf32>
      %1734 = cute.memref.load(%view_672, %79) : (!memref_rmem_f32_1, !cute.coord<"(16,2)">) -> f32
      %1735 = cute.memref.load(%view_672, %78) : (!memref_rmem_f32_1, !cute.coord<"(17,2)">) -> f32
      %1736 = vector.from_elements %1711, %1712 : vector<2xf32>
      %1737 = vector.from_elements %1734, %1735 : vector<2xf32>
      %1738 = nvvm.add.packed.f32x2 %1736, %1737 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1739 = vector.extract %1738[0] : f32 from vector<2xf32>
      %1740 = vector.extract %1738[1] : f32 from vector<2xf32>
      %1741 = cute.memref.load(%view_672, %77) : (!memref_rmem_f32_1, !cute.coord<"(16,3)">) -> f32
      %1742 = cute.memref.load(%view_672, %76) : (!memref_rmem_f32_1, !cute.coord<"(17,3)">) -> f32
      %1743 = vector.from_elements %1718, %1719 : vector<2xf32>
      %1744 = vector.from_elements %1741, %1742 : vector<2xf32>
      %1745 = nvvm.add.packed.f32x2 %1743, %1744 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1746 = vector.extract %1745[0] : f32 from vector<2xf32>
      %1747 = vector.extract %1745[1] : f32 from vector<2xf32>
      %1748 = cute.memref.load(%view_672, %75) : (!memref_rmem_f32_1, !cute.coord<"(18,0)">) -> f32
      %1749 = cute.memref.load(%view_672, %74) : (!memref_rmem_f32_1, !cute.coord<"(19,0)">) -> f32
      %1750 = vector.from_elements %1725, %1726 : vector<2xf32>
      %1751 = vector.from_elements %1748, %1749 : vector<2xf32>
      %1752 = nvvm.add.packed.f32x2 %1750, %1751 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1753 = vector.extract %1752[0] : f32 from vector<2xf32>
      %1754 = vector.extract %1752[1] : f32 from vector<2xf32>
      %1755 = cute.memref.load(%view_672, %73) : (!memref_rmem_f32_1, !cute.coord<"(18,1)">) -> f32
      %1756 = cute.memref.load(%view_672, %72) : (!memref_rmem_f32_1, !cute.coord<"(19,1)">) -> f32
      %1757 = vector.from_elements %1732, %1733 : vector<2xf32>
      %1758 = vector.from_elements %1755, %1756 : vector<2xf32>
      %1759 = nvvm.add.packed.f32x2 %1757, %1758 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1760 = vector.extract %1759[0] : f32 from vector<2xf32>
      %1761 = vector.extract %1759[1] : f32 from vector<2xf32>
      %1762 = cute.memref.load(%view_672, %71) : (!memref_rmem_f32_1, !cute.coord<"(18,2)">) -> f32
      %1763 = cute.memref.load(%view_672, %70) : (!memref_rmem_f32_1, !cute.coord<"(19,2)">) -> f32
      %1764 = vector.from_elements %1739, %1740 : vector<2xf32>
      %1765 = vector.from_elements %1762, %1763 : vector<2xf32>
      %1766 = nvvm.add.packed.f32x2 %1764, %1765 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1767 = vector.extract %1766[0] : f32 from vector<2xf32>
      %1768 = vector.extract %1766[1] : f32 from vector<2xf32>
      %1769 = cute.memref.load(%view_672, %69) : (!memref_rmem_f32_1, !cute.coord<"(18,3)">) -> f32
      %1770 = cute.memref.load(%view_672, %68) : (!memref_rmem_f32_1, !cute.coord<"(19,3)">) -> f32
      %1771 = vector.from_elements %1746, %1747 : vector<2xf32>
      %1772 = vector.from_elements %1769, %1770 : vector<2xf32>
      %1773 = nvvm.add.packed.f32x2 %1771, %1772 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1774 = vector.extract %1773[0] : f32 from vector<2xf32>
      %1775 = vector.extract %1773[1] : f32 from vector<2xf32>
      %1776 = cute.memref.load(%view_672, %67) : (!memref_rmem_f32_1, !cute.coord<"(20,0)">) -> f32
      %1777 = cute.memref.load(%view_672, %66) : (!memref_rmem_f32_1, !cute.coord<"(21,0)">) -> f32
      %1778 = vector.from_elements %1753, %1754 : vector<2xf32>
      %1779 = vector.from_elements %1776, %1777 : vector<2xf32>
      %1780 = nvvm.add.packed.f32x2 %1778, %1779 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1781 = vector.extract %1780[0] : f32 from vector<2xf32>
      %1782 = vector.extract %1780[1] : f32 from vector<2xf32>
      %1783 = cute.memref.load(%view_672, %65) : (!memref_rmem_f32_1, !cute.coord<"(20,1)">) -> f32
      %1784 = cute.memref.load(%view_672, %64) : (!memref_rmem_f32_1, !cute.coord<"(21,1)">) -> f32
      %1785 = vector.from_elements %1760, %1761 : vector<2xf32>
      %1786 = vector.from_elements %1783, %1784 : vector<2xf32>
      %1787 = nvvm.add.packed.f32x2 %1785, %1786 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1788 = vector.extract %1787[0] : f32 from vector<2xf32>
      %1789 = vector.extract %1787[1] : f32 from vector<2xf32>
      %1790 = cute.memref.load(%view_672, %63) : (!memref_rmem_f32_1, !cute.coord<"(20,2)">) -> f32
      %1791 = cute.memref.load(%view_672, %62) : (!memref_rmem_f32_1, !cute.coord<"(21,2)">) -> f32
      %1792 = vector.from_elements %1767, %1768 : vector<2xf32>
      %1793 = vector.from_elements %1790, %1791 : vector<2xf32>
      %1794 = nvvm.add.packed.f32x2 %1792, %1793 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1795 = vector.extract %1794[0] : f32 from vector<2xf32>
      %1796 = vector.extract %1794[1] : f32 from vector<2xf32>
      %1797 = cute.memref.load(%view_672, %61) : (!memref_rmem_f32_1, !cute.coord<"(20,3)">) -> f32
      %1798 = cute.memref.load(%view_672, %60) : (!memref_rmem_f32_1, !cute.coord<"(21,3)">) -> f32
      %1799 = vector.from_elements %1774, %1775 : vector<2xf32>
      %1800 = vector.from_elements %1797, %1798 : vector<2xf32>
      %1801 = nvvm.add.packed.f32x2 %1799, %1800 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1802 = vector.extract %1801[0] : f32 from vector<2xf32>
      %1803 = vector.extract %1801[1] : f32 from vector<2xf32>
      %1804 = cute.memref.load(%view_672, %59) : (!memref_rmem_f32_1, !cute.coord<"(22,0)">) -> f32
      %1805 = cute.memref.load(%view_672, %58) : (!memref_rmem_f32_1, !cute.coord<"(23,0)">) -> f32
      %1806 = vector.from_elements %1781, %1782 : vector<2xf32>
      %1807 = vector.from_elements %1804, %1805 : vector<2xf32>
      %1808 = nvvm.add.packed.f32x2 %1806, %1807 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1809 = vector.extract %1808[0] : f32 from vector<2xf32>
      %1810 = vector.extract %1808[1] : f32 from vector<2xf32>
      %1811 = cute.memref.load(%view_672, %57) : (!memref_rmem_f32_1, !cute.coord<"(22,1)">) -> f32
      %1812 = cute.memref.load(%view_672, %56) : (!memref_rmem_f32_1, !cute.coord<"(23,1)">) -> f32
      %1813 = vector.from_elements %1788, %1789 : vector<2xf32>
      %1814 = vector.from_elements %1811, %1812 : vector<2xf32>
      %1815 = nvvm.add.packed.f32x2 %1813, %1814 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1816 = vector.extract %1815[0] : f32 from vector<2xf32>
      %1817 = vector.extract %1815[1] : f32 from vector<2xf32>
      %1818 = cute.memref.load(%view_672, %55) : (!memref_rmem_f32_1, !cute.coord<"(22,2)">) -> f32
      %1819 = cute.memref.load(%view_672, %54) : (!memref_rmem_f32_1, !cute.coord<"(23,2)">) -> f32
      %1820 = vector.from_elements %1795, %1796 : vector<2xf32>
      %1821 = vector.from_elements %1818, %1819 : vector<2xf32>
      %1822 = nvvm.add.packed.f32x2 %1820, %1821 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1823 = vector.extract %1822[0] : f32 from vector<2xf32>
      %1824 = vector.extract %1822[1] : f32 from vector<2xf32>
      %1825 = cute.memref.load(%view_672, %53) : (!memref_rmem_f32_1, !cute.coord<"(22,3)">) -> f32
      %1826 = cute.memref.load(%view_672, %52) : (!memref_rmem_f32_1, !cute.coord<"(23,3)">) -> f32
      %1827 = vector.from_elements %1802, %1803 : vector<2xf32>
      %1828 = vector.from_elements %1825, %1826 : vector<2xf32>
      %1829 = nvvm.add.packed.f32x2 %1827, %1828 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1830 = vector.extract %1829[0] : f32 from vector<2xf32>
      %1831 = vector.extract %1829[1] : f32 from vector<2xf32>
      %1832 = cute.memref.load(%view_672, %51) : (!memref_rmem_f32_1, !cute.coord<"(24,0)">) -> f32
      %1833 = cute.memref.load(%view_672, %50) : (!memref_rmem_f32_1, !cute.coord<"(25,0)">) -> f32
      %1834 = vector.from_elements %1809, %1810 : vector<2xf32>
      %1835 = vector.from_elements %1832, %1833 : vector<2xf32>
      %1836 = nvvm.add.packed.f32x2 %1834, %1835 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1837 = vector.extract %1836[0] : f32 from vector<2xf32>
      %1838 = vector.extract %1836[1] : f32 from vector<2xf32>
      %1839 = cute.memref.load(%view_672, %49) : (!memref_rmem_f32_1, !cute.coord<"(24,1)">) -> f32
      %1840 = cute.memref.load(%view_672, %48) : (!memref_rmem_f32_1, !cute.coord<"(25,1)">) -> f32
      %1841 = vector.from_elements %1816, %1817 : vector<2xf32>
      %1842 = vector.from_elements %1839, %1840 : vector<2xf32>
      %1843 = nvvm.add.packed.f32x2 %1841, %1842 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1844 = vector.extract %1843[0] : f32 from vector<2xf32>
      %1845 = vector.extract %1843[1] : f32 from vector<2xf32>
      %1846 = cute.memref.load(%view_672, %47) : (!memref_rmem_f32_1, !cute.coord<"(24,2)">) -> f32
      %1847 = cute.memref.load(%view_672, %46) : (!memref_rmem_f32_1, !cute.coord<"(25,2)">) -> f32
      %1848 = vector.from_elements %1823, %1824 : vector<2xf32>
      %1849 = vector.from_elements %1846, %1847 : vector<2xf32>
      %1850 = nvvm.add.packed.f32x2 %1848, %1849 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1851 = vector.extract %1850[0] : f32 from vector<2xf32>
      %1852 = vector.extract %1850[1] : f32 from vector<2xf32>
      %1853 = cute.memref.load(%view_672, %45) : (!memref_rmem_f32_1, !cute.coord<"(24,3)">) -> f32
      %1854 = cute.memref.load(%view_672, %44) : (!memref_rmem_f32_1, !cute.coord<"(25,3)">) -> f32
      %1855 = vector.from_elements %1830, %1831 : vector<2xf32>
      %1856 = vector.from_elements %1853, %1854 : vector<2xf32>
      %1857 = nvvm.add.packed.f32x2 %1855, %1856 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1858 = vector.extract %1857[0] : f32 from vector<2xf32>
      %1859 = vector.extract %1857[1] : f32 from vector<2xf32>
      %1860 = cute.memref.load(%view_672, %43) : (!memref_rmem_f32_1, !cute.coord<"(26,0)">) -> f32
      %1861 = cute.memref.load(%view_672, %42) : (!memref_rmem_f32_1, !cute.coord<"(27,0)">) -> f32
      %1862 = vector.from_elements %1837, %1838 : vector<2xf32>
      %1863 = vector.from_elements %1860, %1861 : vector<2xf32>
      %1864 = nvvm.add.packed.f32x2 %1862, %1863 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1865 = vector.extract %1864[0] : f32 from vector<2xf32>
      %1866 = vector.extract %1864[1] : f32 from vector<2xf32>
      %1867 = cute.memref.load(%view_672, %41) : (!memref_rmem_f32_1, !cute.coord<"(26,1)">) -> f32
      %1868 = cute.memref.load(%view_672, %40) : (!memref_rmem_f32_1, !cute.coord<"(27,1)">) -> f32
      %1869 = vector.from_elements %1844, %1845 : vector<2xf32>
      %1870 = vector.from_elements %1867, %1868 : vector<2xf32>
      %1871 = nvvm.add.packed.f32x2 %1869, %1870 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1872 = vector.extract %1871[0] : f32 from vector<2xf32>
      %1873 = vector.extract %1871[1] : f32 from vector<2xf32>
      %1874 = cute.memref.load(%view_672, %39) : (!memref_rmem_f32_1, !cute.coord<"(26,2)">) -> f32
      %1875 = cute.memref.load(%view_672, %38) : (!memref_rmem_f32_1, !cute.coord<"(27,2)">) -> f32
      %1876 = vector.from_elements %1851, %1852 : vector<2xf32>
      %1877 = vector.from_elements %1874, %1875 : vector<2xf32>
      %1878 = nvvm.add.packed.f32x2 %1876, %1877 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1879 = vector.extract %1878[0] : f32 from vector<2xf32>
      %1880 = vector.extract %1878[1] : f32 from vector<2xf32>
      %1881 = cute.memref.load(%view_672, %37) : (!memref_rmem_f32_1, !cute.coord<"(26,3)">) -> f32
      %1882 = cute.memref.load(%view_672, %36) : (!memref_rmem_f32_1, !cute.coord<"(27,3)">) -> f32
      %1883 = vector.from_elements %1858, %1859 : vector<2xf32>
      %1884 = vector.from_elements %1881, %1882 : vector<2xf32>
      %1885 = nvvm.add.packed.f32x2 %1883, %1884 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1886 = vector.extract %1885[0] : f32 from vector<2xf32>
      %1887 = vector.extract %1885[1] : f32 from vector<2xf32>
      %1888 = cute.memref.load(%view_672, %35) : (!memref_rmem_f32_1, !cute.coord<"(28,0)">) -> f32
      %1889 = cute.memref.load(%view_672, %34) : (!memref_rmem_f32_1, !cute.coord<"(29,0)">) -> f32
      %1890 = vector.from_elements %1865, %1866 : vector<2xf32>
      %1891 = vector.from_elements %1888, %1889 : vector<2xf32>
      %1892 = nvvm.add.packed.f32x2 %1890, %1891 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1893 = vector.extract %1892[0] : f32 from vector<2xf32>
      %1894 = vector.extract %1892[1] : f32 from vector<2xf32>
      %1895 = cute.memref.load(%view_672, %33) : (!memref_rmem_f32_1, !cute.coord<"(28,1)">) -> f32
      %1896 = cute.memref.load(%view_672, %32) : (!memref_rmem_f32_1, !cute.coord<"(29,1)">) -> f32
      %1897 = vector.from_elements %1872, %1873 : vector<2xf32>
      %1898 = vector.from_elements %1895, %1896 : vector<2xf32>
      %1899 = nvvm.add.packed.f32x2 %1897, %1898 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1900 = vector.extract %1899[0] : f32 from vector<2xf32>
      %1901 = vector.extract %1899[1] : f32 from vector<2xf32>
      %1902 = cute.memref.load(%view_672, %31) : (!memref_rmem_f32_1, !cute.coord<"(28,2)">) -> f32
      %1903 = cute.memref.load(%view_672, %30) : (!memref_rmem_f32_1, !cute.coord<"(29,2)">) -> f32
      %1904 = vector.from_elements %1879, %1880 : vector<2xf32>
      %1905 = vector.from_elements %1902, %1903 : vector<2xf32>
      %1906 = nvvm.add.packed.f32x2 %1904, %1905 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1907 = vector.extract %1906[0] : f32 from vector<2xf32>
      %1908 = vector.extract %1906[1] : f32 from vector<2xf32>
      %1909 = cute.memref.load(%view_672, %29) : (!memref_rmem_f32_1, !cute.coord<"(28,3)">) -> f32
      %1910 = cute.memref.load(%view_672, %28) : (!memref_rmem_f32_1, !cute.coord<"(29,3)">) -> f32
      %1911 = vector.from_elements %1886, %1887 : vector<2xf32>
      %1912 = vector.from_elements %1909, %1910 : vector<2xf32>
      %1913 = nvvm.add.packed.f32x2 %1911, %1912 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1914 = vector.extract %1913[0] : f32 from vector<2xf32>
      %1915 = vector.extract %1913[1] : f32 from vector<2xf32>
      %1916 = cute.memref.load(%view_672, %27) : (!memref_rmem_f32_1, !cute.coord<"(30,0)">) -> f32
      %1917 = cute.memref.load(%view_672, %26) : (!memref_rmem_f32_1, !cute.coord<"(31,0)">) -> f32
      %1918 = vector.from_elements %1893, %1894 : vector<2xf32>
      %1919 = vector.from_elements %1916, %1917 : vector<2xf32>
      %1920 = nvvm.add.packed.f32x2 %1918, %1919 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1921 = vector.extract %1920[0] : f32 from vector<2xf32>
      %1922 = vector.extract %1920[1] : f32 from vector<2xf32>
      %1923 = cute.memref.load(%view_672, %25) : (!memref_rmem_f32_1, !cute.coord<"(30,1)">) -> f32
      %1924 = cute.memref.load(%view_672, %24) : (!memref_rmem_f32_1, !cute.coord<"(31,1)">) -> f32
      %1925 = vector.from_elements %1900, %1901 : vector<2xf32>
      %1926 = vector.from_elements %1923, %1924 : vector<2xf32>
      %1927 = nvvm.add.packed.f32x2 %1925, %1926 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1928 = vector.extract %1927[0] : f32 from vector<2xf32>
      %1929 = vector.extract %1927[1] : f32 from vector<2xf32>
      %1930 = cute.memref.load(%view_672, %23) : (!memref_rmem_f32_1, !cute.coord<"(30,2)">) -> f32
      %1931 = cute.memref.load(%view_672, %22) : (!memref_rmem_f32_1, !cute.coord<"(31,2)">) -> f32
      %1932 = vector.from_elements %1907, %1908 : vector<2xf32>
      %1933 = vector.from_elements %1930, %1931 : vector<2xf32>
      %1934 = nvvm.add.packed.f32x2 %1932, %1933 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1935 = vector.extract %1934[0] : f32 from vector<2xf32>
      %1936 = vector.extract %1934[1] : f32 from vector<2xf32>
      %1937 = cute.memref.load(%view_672, %21) : (!memref_rmem_f32_1, !cute.coord<"(30,3)">) -> f32
      %1938 = cute.memref.load(%view_672, %20) : (!memref_rmem_f32_1, !cute.coord<"(31,3)">) -> f32
      %1939 = vector.from_elements %1914, %1915 : vector<2xf32>
      %1940 = vector.from_elements %1937, %1938 : vector<2xf32>
      %1941 = nvvm.add.packed.f32x2 %1939, %1940 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1942 = vector.extract %1941[0] : f32 from vector<2xf32>
      %1943 = vector.extract %1941[1] : f32 from vector<2xf32>
      %1944 = vector.from_elements %1921, %1922 : vector<2xf32>
      %1945 = vector.from_elements %1928, %1929 : vector<2xf32>
      %1946 = nvvm.add.packed.f32x2 %1944, %1945 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1947 = vector.extract %1946[0] : f32 from vector<2xf32>
      %1948 = vector.extract %1946[1] : f32 from vector<2xf32>
      %1949 = vector.from_elements %1935, %1936 : vector<2xf32>
      %1950 = vector.from_elements %1942, %1943 : vector<2xf32>
      %1951 = nvvm.add.packed.f32x2 %1949, %1950 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1952 = vector.extract %1951[0] : f32 from vector<2xf32>
      %1953 = vector.extract %1951[1] : f32 from vector<2xf32>
      %1954 = vector.from_elements %1947, %1948 : vector<2xf32>
      %1955 = vector.from_elements %1952, %1953 : vector<2xf32>
      %1956 = nvvm.add.packed.f32x2 %1954, %1955 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1957 = vector.extract %1956[0] : f32 from vector<2xf32>
      %1958 = vector.extract %1956[1] : f32 from vector<2xf32>
      %1959 = arith.addf %1957, %1958 : f32
      cf.br ^bb566(%c1_i32, %1959, %1432, %1434, %1436, %1471, %1473, %1475, %1426, %1427, %1428, %1447 : i32, f32, i32, i32, i32, i32, i32, i32, i32, i32, i32, f32)
    ^bb566(%1960: i32, %1961: f32, %1962: i32, %1963: i32, %1964: i32, %1965: i32, %1966: i32, %1967: i32, %1968: i32, %1969: i32, %1970: i32, %1971: f32):  // 2 preds: ^bb565, ^bb603
      %1972 = arith.cmpi slt, %1960, %1372 : i32
      cf.cond_br %1972, ^bb567, ^bb604 {loop_annotation = #loop_annotation2}
    ^bb567:  // pred: ^bb566
      %int_tuple_673 = cute.make_int_tuple(%1963) : (i32) -> !cute.int_tuple<"?">
      %ptr_674 = cute.add_offset(%iter_101, %int_tuple_673) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1973 = builtin.unrealized_conversion_cast %ptr_674 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1973, %1964, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1974 = arith.addi %1963, %c1_i32 : i32
      %1975 = arith.addi %1962, %c1_i32 : i32
      %1976 = arith.cmpi eq, %1974, %c2_i32 : i32
      %1977 = arith.select %1976, %c0_i32, %1974 : i32
      cf.cond_br %1976, ^bb568, ^bb569
    ^bb568:  // pred: ^bb567
      %1978 = arith.xori %1964, %c1_i32 : i32
      cf.br ^bb570(%1978 : i32)
    ^bb569:  // pred: ^bb567
      cf.br ^bb570(%1964 : i32)
    ^bb570(%1979: i32):  // 2 preds: ^bb568, ^bb569
      cf.br ^bb571
    ^bb571:  // pred: ^bb570
      %coord_675 = cute.make_coord(%1963) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_676 = cute.crd2idx(%coord_675, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_677 = cute.add_offset(%329, %idx_676) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_678 = cute.add_offset(%ptr_677, %int_tuple_612) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem_679 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_680 = cute.get_iter(%rmem_679) : !memref_rmem_f32_
      cf.br ^bb572(%c0_i32 : i32)
    ^bb572(%1980: i32):  // 2 preds: ^bb571, ^bb573
      %1981 = arith.cmpi slt, %1980, %1383 : i32
      cf.cond_br %1981, ^bb573, ^bb574 {llvm.loop_annotation = #loop_annotation}
    ^bb573:  // pred: ^bb572
      %coord_681 = cute.make_coord(%1980) : (i32) -> !cute.coord<"(_,?)">
      %idx_682 = cute.crd2idx(%coord_681, %153) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,32),1),((1,4))):(((1,65536),0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_683 = cute.add_offset(%ptr_678, %idx_682) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_684 = cute.crd2idx(%coord_681, %152) : (!cute.coord<"(_,?)">, !cute.layout<"((32,1),((1,4))):((1,0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_685 = cute.add_offset(%iter_680, %idx_684) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, rmem, align<32>>
      %1982 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_683) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      %1983 = builtin.unrealized_conversion_cast %ptr_685 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      llvm.store %1982, %1983 : vector<32xi32>, !llvm.ptr
      %1984 = arith.addi %1980, %c1_i32 : i32
      cf.br ^bb572(%1984 : i32)
    ^bb574:  // pred: ^bb572
      nvvm.tcgen05.wait <load>
      %ptr_686 = cute.add_offset(%ptr_103, %int_tuple_673) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1985 = builtin.unrealized_conversion_cast %ptr_686 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %1986 = nvvm.mapa.shared.cluster %1985, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %1986, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %1987 = cute.memref.load_vec %rmem_679 : !memref_rmem_f32_
      %1988 = vector.reduction <maximumf>, %1987, %1971 : vector<128xf32> into f32
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_610, %1988) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %1989 = cute.memref.load(%view, %coord_613) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %1990 = nvvm.fmax %1988, %1989
      %1991 = arith.cmpf oeq, %1990, %cst_2 : f32
      %1992 = arith.select %1991, %cst_1, %1990 : f32
      %1993 = arith.subf %cst_1, %1992 : f32
      %1994 = arith.mulf %1993, %arg13 : f32
      %rmem_687 = cute.memref.alloca() : !memref_rmem_bf16_
      %1995 = vector.splat %1994 : vector<2xf32>
      cf.br ^bb575(%c0_i32 : i32)
    ^bb575(%1996: i32):  // 2 preds: ^bb574, ^bb576
      %1997 = arith.cmpi slt, %1996, %c128_i32 : i32
      cf.cond_br %1997, ^bb576, ^bb577
    ^bb576:  // pred: ^bb575
      %coord_688 = cute.make_coord(%1996) : (i32) -> !cute.coord<"?">
      %1998 = cute.memref.load(%rmem_679, %coord_688) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1999 = arith.addi %1996, %c1_i32 : i32
      %coord_689 = cute.make_coord(%1999) : (i32) -> !cute.coord<"?">
      %2000 = cute.memref.load(%rmem_679, %coord_689) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2001 = vector.from_elements %1998, %2000 : vector<2xf32>
      %2002 = nvvm.fma.packed.f32x2 %2001, %1393, %1995 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2003 = vector.extract %2002[0] : f32 from vector<2xf32>
      %2004 = vector.extract %2002[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_679, %coord_688, %2003) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_679, %coord_689, %2004) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2005 = cute.memref.load(%rmem_679, %coord_688) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2006 = math.exp2 %2005 fastmath<fast> : f32
      cute.memref.store(%rmem_679, %coord_688, %2006) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2007 = cute.memref.load(%rmem_679, %coord_689) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2008 = math.exp2 %2007 fastmath<fast> : f32
      cute.memref.store(%rmem_679, %coord_689, %2008) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2009 = arith.addi %1996, %c2_i32 : i32
      cf.br ^bb575(%2009 : i32)
    ^bb577:  // pred: ^bb575
      %2010 = cute.memref.load_vec %rmem_679 : !memref_rmem_f32_
      %2011 = arith.truncf %2010 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %2011, %rmem_687 : !memref_rmem_bf16_
      %int_tuple_690 = cute.make_int_tuple(%1966) : (i32) -> !cute.int_tuple<"?">
      %ptr_691 = cute.add_offset(%ptr_108, %int_tuple_690) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2012 = builtin.unrealized_conversion_cast %ptr_691 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2012, %1967, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2013 = arith.addi %1966, %c1_i32 : i32
      %2014 = arith.addi %1965, %c1_i32 : i32
      %2015 = arith.cmpi eq, %2013, %c2_i32 : i32
      %2016 = arith.select %2015, %c0_i32, %2013 : i32
      cf.cond_br %2015, ^bb578, ^bb579
    ^bb578:  // pred: ^bb577
      %2017 = arith.xori %1967, %c1_i32 : i32
      cf.br ^bb580(%2017 : i32)
    ^bb579:  // pred: ^bb577
      cf.br ^bb580(%1967 : i32)
    ^bb580(%2018: i32):  // 2 preds: ^bb578, ^bb579
      cf.br ^bb581
    ^bb581:  // pred: ^bb580
      %coord_692 = cute.make_coord(%1966) : (i32) -> !cute.coord<"(_,_,_,(_,?))">
      %idx_693 = cute.crd2idx(%coord_692, %204) : (!cute.coord<"(_,_,_,(_,?))">, !cute.layout<"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">) -> !cute.int_tuple<"?{div=16384}">
      %2019 = cute.make_tiled_copy(%atom) : !copy_simt
      %iter_694 = cute.get_iter(%rmem_687) : !memref_rmem_bf16_
      cf.br ^bb582(%c0_i32 : i32)
    ^bb582(%2020: i32):  // 2 preds: ^bb581, ^bb583
      %2021 = arith.cmpi slt, %2020, %1383 : i32
      cf.cond_br %2021, ^bb583, ^bb584 {llvm.loop_annotation = #loop_annotation}
    ^bb583:  // pred: ^bb582
      %coord_695 = cute.make_coord(%2020) : (i32) -> !cute.coord<"(_,?)">
      %idx_696 = cute.crd2idx(%coord_695, %151) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,4))):((1,8),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_697 = cute.add_offset(%iter_694, %idx_696) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_698 = cute.crd2idx(%coord_695, %150) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,(2,2)))):((1,8),((0,(32,4096))))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_699 = cute.add_offset(%ptr_616, %idx_698) : (!cute.ptr<bf16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %swizzled_700 = cute.apply_swizzle(%ptr_699) : !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %ptr_701 = cute.add_offset(%swizzled_700, %idx_693) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %2022 = builtin.unrealized_conversion_cast %ptr_697 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2023 = builtin.unrealized_conversion_cast %ptr_701 : !cute.ptr<bf16, smem, align<64>, S<3,4,3>> to !llvm.ptr<3>
      %2024 = llvm.load %2022 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2024, %2023 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_702 = cute.add_offset(%ptr_697, %205) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_703 = cute.add_offset(%ptr_699, %205) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_704 = cute.apply_swizzle(%ptr_703) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_705 = cute.add_offset(%swizzled_704, %idx_693) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %2025 = builtin.unrealized_conversion_cast %ptr_702 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2026 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %2027 = llvm.load %2025 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2027, %2026 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_706 = cute.add_offset(%ptr_697, %149) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_707 = cute.add_offset(%ptr_699, %149) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %swizzled_708 = cute.apply_swizzle(%ptr_707) : !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %ptr_709 = cute.add_offset(%swizzled_708, %idx_693) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2028 = builtin.unrealized_conversion_cast %ptr_706 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2029 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<bf16, smem, align<32>, S<3,4,3>> to !llvm.ptr<3>
      %2030 = llvm.load %2028 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2030, %2029 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_710 = cute.add_offset(%ptr_697, %148) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_711 = cute.add_offset(%ptr_699, %148) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_712 = cute.apply_swizzle(%ptr_711) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_713 = cute.add_offset(%swizzled_712, %idx_693) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %2031 = builtin.unrealized_conversion_cast %ptr_710 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2032 = builtin.unrealized_conversion_cast %ptr_713 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %2033 = llvm.load %2031 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2033, %2032 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %2034 = arith.addi %2020, %c1_i32 : i32
      cf.br ^bb582(%2034 : i32)
    ^bb584:  // pred: ^bb582
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_714 = cute.add_offset(%iter_106, %int_tuple_690) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2035 = builtin.unrealized_conversion_cast %ptr_714 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2036 = nvvm.mapa.shared.cluster %2035, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2036, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %2037 = arith.subf %1971, %1992 : f32
      %2038 = arith.mulf %arg13, %2037 : f32
      %2039 = math.exp2 %2038 fastmath<fast> : f32
      %2040 = arith.mulf %2039, %cst_0 : f32
      %2041 = arith.mulf %1961, %2040 : f32
      %view_715 = cute.make_view(%iter_680) : !memref_rmem_f32_1
      %2042 = cute.memref.load(%view_715, %147) : (!memref_rmem_f32_1, !cute.coord<"(0,0)">) -> f32
      %2043 = cute.memref.load(%view_715, %146) : (!memref_rmem_f32_1, !cute.coord<"(1,0)">) -> f32
      %2044 = vector.splat %2041 : vector<2xf32>
      %2045 = vector.from_elements %2042, %2043 : vector<2xf32>
      %2046 = nvvm.add.packed.f32x2 %2044, %2045 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2047 = vector.extract %2046[0] : f32 from vector<2xf32>
      %2048 = vector.extract %2046[1] : f32 from vector<2xf32>
      %2049 = cute.memref.load(%view_715, %145) : (!memref_rmem_f32_1, !cute.coord<"(0,1)">) -> f32
      %2050 = cute.memref.load(%view_715, %144) : (!memref_rmem_f32_1, !cute.coord<"(1,1)">) -> f32
      %2051 = vector.from_elements %2049, %2050 : vector<2xf32>
      %2052 = nvvm.add.packed.f32x2 %cst, %2051 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2053 = vector.extract %2052[0] : f32 from vector<2xf32>
      %2054 = vector.extract %2052[1] : f32 from vector<2xf32>
      %2055 = cute.memref.load(%view_715, %143) : (!memref_rmem_f32_1, !cute.coord<"(0,2)">) -> f32
      %2056 = cute.memref.load(%view_715, %142) : (!memref_rmem_f32_1, !cute.coord<"(1,2)">) -> f32
      %2057 = vector.from_elements %2055, %2056 : vector<2xf32>
      %2058 = nvvm.add.packed.f32x2 %cst, %2057 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2059 = vector.extract %2058[0] : f32 from vector<2xf32>
      %2060 = vector.extract %2058[1] : f32 from vector<2xf32>
      %2061 = cute.memref.load(%view_715, %141) : (!memref_rmem_f32_1, !cute.coord<"(0,3)">) -> f32
      %2062 = cute.memref.load(%view_715, %140) : (!memref_rmem_f32_1, !cute.coord<"(1,3)">) -> f32
      %2063 = vector.from_elements %2061, %2062 : vector<2xf32>
      %2064 = nvvm.add.packed.f32x2 %cst, %2063 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2065 = vector.extract %2064[0] : f32 from vector<2xf32>
      %2066 = vector.extract %2064[1] : f32 from vector<2xf32>
      %2067 = cute.memref.load(%view_715, %139) : (!memref_rmem_f32_1, !cute.coord<"(2,0)">) -> f32
      %2068 = cute.memref.load(%view_715, %138) : (!memref_rmem_f32_1, !cute.coord<"(3,0)">) -> f32
      %2069 = vector.from_elements %2047, %2048 : vector<2xf32>
      %2070 = vector.from_elements %2067, %2068 : vector<2xf32>
      %2071 = nvvm.add.packed.f32x2 %2069, %2070 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2072 = vector.extract %2071[0] : f32 from vector<2xf32>
      %2073 = vector.extract %2071[1] : f32 from vector<2xf32>
      %2074 = cute.memref.load(%view_715, %137) : (!memref_rmem_f32_1, !cute.coord<"(2,1)">) -> f32
      %2075 = cute.memref.load(%view_715, %136) : (!memref_rmem_f32_1, !cute.coord<"(3,1)">) -> f32
      %2076 = vector.from_elements %2053, %2054 : vector<2xf32>
      %2077 = vector.from_elements %2074, %2075 : vector<2xf32>
      %2078 = nvvm.add.packed.f32x2 %2076, %2077 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2079 = vector.extract %2078[0] : f32 from vector<2xf32>
      %2080 = vector.extract %2078[1] : f32 from vector<2xf32>
      %2081 = cute.memref.load(%view_715, %135) : (!memref_rmem_f32_1, !cute.coord<"(2,2)">) -> f32
      %2082 = cute.memref.load(%view_715, %134) : (!memref_rmem_f32_1, !cute.coord<"(3,2)">) -> f32
      %2083 = vector.from_elements %2059, %2060 : vector<2xf32>
      %2084 = vector.from_elements %2081, %2082 : vector<2xf32>
      %2085 = nvvm.add.packed.f32x2 %2083, %2084 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2086 = vector.extract %2085[0] : f32 from vector<2xf32>
      %2087 = vector.extract %2085[1] : f32 from vector<2xf32>
      %2088 = cute.memref.load(%view_715, %133) : (!memref_rmem_f32_1, !cute.coord<"(2,3)">) -> f32
      %2089 = cute.memref.load(%view_715, %132) : (!memref_rmem_f32_1, !cute.coord<"(3,3)">) -> f32
      %2090 = vector.from_elements %2065, %2066 : vector<2xf32>
      %2091 = vector.from_elements %2088, %2089 : vector<2xf32>
      %2092 = nvvm.add.packed.f32x2 %2090, %2091 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2093 = vector.extract %2092[0] : f32 from vector<2xf32>
      %2094 = vector.extract %2092[1] : f32 from vector<2xf32>
      %2095 = cute.memref.load(%view_715, %131) : (!memref_rmem_f32_1, !cute.coord<"(4,0)">) -> f32
      %2096 = cute.memref.load(%view_715, %130) : (!memref_rmem_f32_1, !cute.coord<"(5,0)">) -> f32
      %2097 = vector.from_elements %2072, %2073 : vector<2xf32>
      %2098 = vector.from_elements %2095, %2096 : vector<2xf32>
      %2099 = nvvm.add.packed.f32x2 %2097, %2098 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2100 = vector.extract %2099[0] : f32 from vector<2xf32>
      %2101 = vector.extract %2099[1] : f32 from vector<2xf32>
      %2102 = cute.memref.load(%view_715, %129) : (!memref_rmem_f32_1, !cute.coord<"(4,1)">) -> f32
      %2103 = cute.memref.load(%view_715, %128) : (!memref_rmem_f32_1, !cute.coord<"(5,1)">) -> f32
      %2104 = vector.from_elements %2079, %2080 : vector<2xf32>
      %2105 = vector.from_elements %2102, %2103 : vector<2xf32>
      %2106 = nvvm.add.packed.f32x2 %2104, %2105 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2107 = vector.extract %2106[0] : f32 from vector<2xf32>
      %2108 = vector.extract %2106[1] : f32 from vector<2xf32>
      %2109 = cute.memref.load(%view_715, %127) : (!memref_rmem_f32_1, !cute.coord<"(4,2)">) -> f32
      %2110 = cute.memref.load(%view_715, %126) : (!memref_rmem_f32_1, !cute.coord<"(5,2)">) -> f32
      %2111 = vector.from_elements %2086, %2087 : vector<2xf32>
      %2112 = vector.from_elements %2109, %2110 : vector<2xf32>
      %2113 = nvvm.add.packed.f32x2 %2111, %2112 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2114 = vector.extract %2113[0] : f32 from vector<2xf32>
      %2115 = vector.extract %2113[1] : f32 from vector<2xf32>
      %2116 = cute.memref.load(%view_715, %125) : (!memref_rmem_f32_1, !cute.coord<"(4,3)">) -> f32
      %2117 = cute.memref.load(%view_715, %124) : (!memref_rmem_f32_1, !cute.coord<"(5,3)">) -> f32
      %2118 = vector.from_elements %2093, %2094 : vector<2xf32>
      %2119 = vector.from_elements %2116, %2117 : vector<2xf32>
      %2120 = nvvm.add.packed.f32x2 %2118, %2119 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2121 = vector.extract %2120[0] : f32 from vector<2xf32>
      %2122 = vector.extract %2120[1] : f32 from vector<2xf32>
      %2123 = cute.memref.load(%view_715, %123) : (!memref_rmem_f32_1, !cute.coord<"(6,0)">) -> f32
      %2124 = cute.memref.load(%view_715, %122) : (!memref_rmem_f32_1, !cute.coord<"(7,0)">) -> f32
      %2125 = vector.from_elements %2100, %2101 : vector<2xf32>
      %2126 = vector.from_elements %2123, %2124 : vector<2xf32>
      %2127 = nvvm.add.packed.f32x2 %2125, %2126 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2128 = vector.extract %2127[0] : f32 from vector<2xf32>
      %2129 = vector.extract %2127[1] : f32 from vector<2xf32>
      %2130 = cute.memref.load(%view_715, %121) : (!memref_rmem_f32_1, !cute.coord<"(6,1)">) -> f32
      %2131 = cute.memref.load(%view_715, %120) : (!memref_rmem_f32_1, !cute.coord<"(7,1)">) -> f32
      %2132 = vector.from_elements %2107, %2108 : vector<2xf32>
      %2133 = vector.from_elements %2130, %2131 : vector<2xf32>
      %2134 = nvvm.add.packed.f32x2 %2132, %2133 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2135 = vector.extract %2134[0] : f32 from vector<2xf32>
      %2136 = vector.extract %2134[1] : f32 from vector<2xf32>
      %2137 = cute.memref.load(%view_715, %119) : (!memref_rmem_f32_1, !cute.coord<"(6,2)">) -> f32
      %2138 = cute.memref.load(%view_715, %118) : (!memref_rmem_f32_1, !cute.coord<"(7,2)">) -> f32
      %2139 = vector.from_elements %2114, %2115 : vector<2xf32>
      %2140 = vector.from_elements %2137, %2138 : vector<2xf32>
      %2141 = nvvm.add.packed.f32x2 %2139, %2140 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2142 = vector.extract %2141[0] : f32 from vector<2xf32>
      %2143 = vector.extract %2141[1] : f32 from vector<2xf32>
      %2144 = cute.memref.load(%view_715, %117) : (!memref_rmem_f32_1, !cute.coord<"(6,3)">) -> f32
      %2145 = cute.memref.load(%view_715, %116) : (!memref_rmem_f32_1, !cute.coord<"(7,3)">) -> f32
      %2146 = vector.from_elements %2121, %2122 : vector<2xf32>
      %2147 = vector.from_elements %2144, %2145 : vector<2xf32>
      %2148 = nvvm.add.packed.f32x2 %2146, %2147 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2149 = vector.extract %2148[0] : f32 from vector<2xf32>
      %2150 = vector.extract %2148[1] : f32 from vector<2xf32>
      %2151 = cute.memref.load(%view_715, %115) : (!memref_rmem_f32_1, !cute.coord<"(8,0)">) -> f32
      %2152 = cute.memref.load(%view_715, %114) : (!memref_rmem_f32_1, !cute.coord<"(9,0)">) -> f32
      %2153 = vector.from_elements %2128, %2129 : vector<2xf32>
      %2154 = vector.from_elements %2151, %2152 : vector<2xf32>
      %2155 = nvvm.add.packed.f32x2 %2153, %2154 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2156 = vector.extract %2155[0] : f32 from vector<2xf32>
      %2157 = vector.extract %2155[1] : f32 from vector<2xf32>
      %2158 = cute.memref.load(%view_715, %113) : (!memref_rmem_f32_1, !cute.coord<"(8,1)">) -> f32
      %2159 = cute.memref.load(%view_715, %112) : (!memref_rmem_f32_1, !cute.coord<"(9,1)">) -> f32
      %2160 = vector.from_elements %2135, %2136 : vector<2xf32>
      %2161 = vector.from_elements %2158, %2159 : vector<2xf32>
      %2162 = nvvm.add.packed.f32x2 %2160, %2161 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2163 = vector.extract %2162[0] : f32 from vector<2xf32>
      %2164 = vector.extract %2162[1] : f32 from vector<2xf32>
      %2165 = cute.memref.load(%view_715, %111) : (!memref_rmem_f32_1, !cute.coord<"(8,2)">) -> f32
      %2166 = cute.memref.load(%view_715, %110) : (!memref_rmem_f32_1, !cute.coord<"(9,2)">) -> f32
      %2167 = vector.from_elements %2142, %2143 : vector<2xf32>
      %2168 = vector.from_elements %2165, %2166 : vector<2xf32>
      %2169 = nvvm.add.packed.f32x2 %2167, %2168 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2170 = vector.extract %2169[0] : f32 from vector<2xf32>
      %2171 = vector.extract %2169[1] : f32 from vector<2xf32>
      %2172 = cute.memref.load(%view_715, %109) : (!memref_rmem_f32_1, !cute.coord<"(8,3)">) -> f32
      %2173 = cute.memref.load(%view_715, %108) : (!memref_rmem_f32_1, !cute.coord<"(9,3)">) -> f32
      %2174 = vector.from_elements %2149, %2150 : vector<2xf32>
      %2175 = vector.from_elements %2172, %2173 : vector<2xf32>
      %2176 = nvvm.add.packed.f32x2 %2174, %2175 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2177 = vector.extract %2176[0] : f32 from vector<2xf32>
      %2178 = vector.extract %2176[1] : f32 from vector<2xf32>
      %2179 = cute.memref.load(%view_715, %107) : (!memref_rmem_f32_1, !cute.coord<"(10,0)">) -> f32
      %2180 = cute.memref.load(%view_715, %106) : (!memref_rmem_f32_1, !cute.coord<"(11,0)">) -> f32
      %2181 = vector.from_elements %2156, %2157 : vector<2xf32>
      %2182 = vector.from_elements %2179, %2180 : vector<2xf32>
      %2183 = nvvm.add.packed.f32x2 %2181, %2182 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2184 = vector.extract %2183[0] : f32 from vector<2xf32>
      %2185 = vector.extract %2183[1] : f32 from vector<2xf32>
      %2186 = cute.memref.load(%view_715, %105) : (!memref_rmem_f32_1, !cute.coord<"(10,1)">) -> f32
      %2187 = cute.memref.load(%view_715, %104) : (!memref_rmem_f32_1, !cute.coord<"(11,1)">) -> f32
      %2188 = vector.from_elements %2163, %2164 : vector<2xf32>
      %2189 = vector.from_elements %2186, %2187 : vector<2xf32>
      %2190 = nvvm.add.packed.f32x2 %2188, %2189 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2191 = vector.extract %2190[0] : f32 from vector<2xf32>
      %2192 = vector.extract %2190[1] : f32 from vector<2xf32>
      %2193 = cute.memref.load(%view_715, %103) : (!memref_rmem_f32_1, !cute.coord<"(10,2)">) -> f32
      %2194 = cute.memref.load(%view_715, %102) : (!memref_rmem_f32_1, !cute.coord<"(11,2)">) -> f32
      %2195 = vector.from_elements %2170, %2171 : vector<2xf32>
      %2196 = vector.from_elements %2193, %2194 : vector<2xf32>
      %2197 = nvvm.add.packed.f32x2 %2195, %2196 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2198 = vector.extract %2197[0] : f32 from vector<2xf32>
      %2199 = vector.extract %2197[1] : f32 from vector<2xf32>
      %2200 = cute.memref.load(%view_715, %101) : (!memref_rmem_f32_1, !cute.coord<"(10,3)">) -> f32
      %2201 = cute.memref.load(%view_715, %100) : (!memref_rmem_f32_1, !cute.coord<"(11,3)">) -> f32
      %2202 = vector.from_elements %2177, %2178 : vector<2xf32>
      %2203 = vector.from_elements %2200, %2201 : vector<2xf32>
      %2204 = nvvm.add.packed.f32x2 %2202, %2203 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2205 = vector.extract %2204[0] : f32 from vector<2xf32>
      %2206 = vector.extract %2204[1] : f32 from vector<2xf32>
      %2207 = cute.memref.load(%view_715, %99) : (!memref_rmem_f32_1, !cute.coord<"(12,0)">) -> f32
      %2208 = cute.memref.load(%view_715, %98) : (!memref_rmem_f32_1, !cute.coord<"(13,0)">) -> f32
      %2209 = vector.from_elements %2184, %2185 : vector<2xf32>
      %2210 = vector.from_elements %2207, %2208 : vector<2xf32>
      %2211 = nvvm.add.packed.f32x2 %2209, %2210 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2212 = vector.extract %2211[0] : f32 from vector<2xf32>
      %2213 = vector.extract %2211[1] : f32 from vector<2xf32>
      %2214 = cute.memref.load(%view_715, %97) : (!memref_rmem_f32_1, !cute.coord<"(12,1)">) -> f32
      %2215 = cute.memref.load(%view_715, %96) : (!memref_rmem_f32_1, !cute.coord<"(13,1)">) -> f32
      %2216 = vector.from_elements %2191, %2192 : vector<2xf32>
      %2217 = vector.from_elements %2214, %2215 : vector<2xf32>
      %2218 = nvvm.add.packed.f32x2 %2216, %2217 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2219 = vector.extract %2218[0] : f32 from vector<2xf32>
      %2220 = vector.extract %2218[1] : f32 from vector<2xf32>
      %2221 = cute.memref.load(%view_715, %95) : (!memref_rmem_f32_1, !cute.coord<"(12,2)">) -> f32
      %2222 = cute.memref.load(%view_715, %94) : (!memref_rmem_f32_1, !cute.coord<"(13,2)">) -> f32
      %2223 = vector.from_elements %2198, %2199 : vector<2xf32>
      %2224 = vector.from_elements %2221, %2222 : vector<2xf32>
      %2225 = nvvm.add.packed.f32x2 %2223, %2224 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2226 = vector.extract %2225[0] : f32 from vector<2xf32>
      %2227 = vector.extract %2225[1] : f32 from vector<2xf32>
      %2228 = cute.memref.load(%view_715, %93) : (!memref_rmem_f32_1, !cute.coord<"(12,3)">) -> f32
      %2229 = cute.memref.load(%view_715, %92) : (!memref_rmem_f32_1, !cute.coord<"(13,3)">) -> f32
      %2230 = vector.from_elements %2205, %2206 : vector<2xf32>
      %2231 = vector.from_elements %2228, %2229 : vector<2xf32>
      %2232 = nvvm.add.packed.f32x2 %2230, %2231 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2233 = vector.extract %2232[0] : f32 from vector<2xf32>
      %2234 = vector.extract %2232[1] : f32 from vector<2xf32>
      %2235 = cute.memref.load(%view_715, %91) : (!memref_rmem_f32_1, !cute.coord<"(14,0)">) -> f32
      %2236 = cute.memref.load(%view_715, %90) : (!memref_rmem_f32_1, !cute.coord<"(15,0)">) -> f32
      %2237 = vector.from_elements %2212, %2213 : vector<2xf32>
      %2238 = vector.from_elements %2235, %2236 : vector<2xf32>
      %2239 = nvvm.add.packed.f32x2 %2237, %2238 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2240 = vector.extract %2239[0] : f32 from vector<2xf32>
      %2241 = vector.extract %2239[1] : f32 from vector<2xf32>
      %2242 = cute.memref.load(%view_715, %89) : (!memref_rmem_f32_1, !cute.coord<"(14,1)">) -> f32
      %2243 = cute.memref.load(%view_715, %88) : (!memref_rmem_f32_1, !cute.coord<"(15,1)">) -> f32
      %2244 = vector.from_elements %2219, %2220 : vector<2xf32>
      %2245 = vector.from_elements %2242, %2243 : vector<2xf32>
      %2246 = nvvm.add.packed.f32x2 %2244, %2245 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2247 = vector.extract %2246[0] : f32 from vector<2xf32>
      %2248 = vector.extract %2246[1] : f32 from vector<2xf32>
      %2249 = cute.memref.load(%view_715, %87) : (!memref_rmem_f32_1, !cute.coord<"(14,2)">) -> f32
      %2250 = cute.memref.load(%view_715, %86) : (!memref_rmem_f32_1, !cute.coord<"(15,2)">) -> f32
      %2251 = vector.from_elements %2226, %2227 : vector<2xf32>
      %2252 = vector.from_elements %2249, %2250 : vector<2xf32>
      %2253 = nvvm.add.packed.f32x2 %2251, %2252 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2254 = vector.extract %2253[0] : f32 from vector<2xf32>
      %2255 = vector.extract %2253[1] : f32 from vector<2xf32>
      %2256 = cute.memref.load(%view_715, %85) : (!memref_rmem_f32_1, !cute.coord<"(14,3)">) -> f32
      %2257 = cute.memref.load(%view_715, %84) : (!memref_rmem_f32_1, !cute.coord<"(15,3)">) -> f32
      %2258 = vector.from_elements %2233, %2234 : vector<2xf32>
      %2259 = vector.from_elements %2256, %2257 : vector<2xf32>
      %2260 = nvvm.add.packed.f32x2 %2258, %2259 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2261 = vector.extract %2260[0] : f32 from vector<2xf32>
      %2262 = vector.extract %2260[1] : f32 from vector<2xf32>
      %2263 = cute.memref.load(%view_715, %83) : (!memref_rmem_f32_1, !cute.coord<"(16,0)">) -> f32
      %2264 = cute.memref.load(%view_715, %82) : (!memref_rmem_f32_1, !cute.coord<"(17,0)">) -> f32
      %2265 = vector.from_elements %2240, %2241 : vector<2xf32>
      %2266 = vector.from_elements %2263, %2264 : vector<2xf32>
      %2267 = nvvm.add.packed.f32x2 %2265, %2266 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2268 = vector.extract %2267[0] : f32 from vector<2xf32>
      %2269 = vector.extract %2267[1] : f32 from vector<2xf32>
      %2270 = cute.memref.load(%view_715, %81) : (!memref_rmem_f32_1, !cute.coord<"(16,1)">) -> f32
      %2271 = cute.memref.load(%view_715, %80) : (!memref_rmem_f32_1, !cute.coord<"(17,1)">) -> f32
      %2272 = vector.from_elements %2247, %2248 : vector<2xf32>
      %2273 = vector.from_elements %2270, %2271 : vector<2xf32>
      %2274 = nvvm.add.packed.f32x2 %2272, %2273 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2275 = vector.extract %2274[0] : f32 from vector<2xf32>
      %2276 = vector.extract %2274[1] : f32 from vector<2xf32>
      %2277 = cute.memref.load(%view_715, %79) : (!memref_rmem_f32_1, !cute.coord<"(16,2)">) -> f32
      %2278 = cute.memref.load(%view_715, %78) : (!memref_rmem_f32_1, !cute.coord<"(17,2)">) -> f32
      %2279 = vector.from_elements %2254, %2255 : vector<2xf32>
      %2280 = vector.from_elements %2277, %2278 : vector<2xf32>
      %2281 = nvvm.add.packed.f32x2 %2279, %2280 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2282 = vector.extract %2281[0] : f32 from vector<2xf32>
      %2283 = vector.extract %2281[1] : f32 from vector<2xf32>
      %2284 = cute.memref.load(%view_715, %77) : (!memref_rmem_f32_1, !cute.coord<"(16,3)">) -> f32
      %2285 = cute.memref.load(%view_715, %76) : (!memref_rmem_f32_1, !cute.coord<"(17,3)">) -> f32
      %2286 = vector.from_elements %2261, %2262 : vector<2xf32>
      %2287 = vector.from_elements %2284, %2285 : vector<2xf32>
      %2288 = nvvm.add.packed.f32x2 %2286, %2287 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2289 = vector.extract %2288[0] : f32 from vector<2xf32>
      %2290 = vector.extract %2288[1] : f32 from vector<2xf32>
      %2291 = cute.memref.load(%view_715, %75) : (!memref_rmem_f32_1, !cute.coord<"(18,0)">) -> f32
      %2292 = cute.memref.load(%view_715, %74) : (!memref_rmem_f32_1, !cute.coord<"(19,0)">) -> f32
      %2293 = vector.from_elements %2268, %2269 : vector<2xf32>
      %2294 = vector.from_elements %2291, %2292 : vector<2xf32>
      %2295 = nvvm.add.packed.f32x2 %2293, %2294 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2296 = vector.extract %2295[0] : f32 from vector<2xf32>
      %2297 = vector.extract %2295[1] : f32 from vector<2xf32>
      %2298 = cute.memref.load(%view_715, %73) : (!memref_rmem_f32_1, !cute.coord<"(18,1)">) -> f32
      %2299 = cute.memref.load(%view_715, %72) : (!memref_rmem_f32_1, !cute.coord<"(19,1)">) -> f32
      %2300 = vector.from_elements %2275, %2276 : vector<2xf32>
      %2301 = vector.from_elements %2298, %2299 : vector<2xf32>
      %2302 = nvvm.add.packed.f32x2 %2300, %2301 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2303 = vector.extract %2302[0] : f32 from vector<2xf32>
      %2304 = vector.extract %2302[1] : f32 from vector<2xf32>
      %2305 = cute.memref.load(%view_715, %71) : (!memref_rmem_f32_1, !cute.coord<"(18,2)">) -> f32
      %2306 = cute.memref.load(%view_715, %70) : (!memref_rmem_f32_1, !cute.coord<"(19,2)">) -> f32
      %2307 = vector.from_elements %2282, %2283 : vector<2xf32>
      %2308 = vector.from_elements %2305, %2306 : vector<2xf32>
      %2309 = nvvm.add.packed.f32x2 %2307, %2308 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2310 = vector.extract %2309[0] : f32 from vector<2xf32>
      %2311 = vector.extract %2309[1] : f32 from vector<2xf32>
      %2312 = cute.memref.load(%view_715, %69) : (!memref_rmem_f32_1, !cute.coord<"(18,3)">) -> f32
      %2313 = cute.memref.load(%view_715, %68) : (!memref_rmem_f32_1, !cute.coord<"(19,3)">) -> f32
      %2314 = vector.from_elements %2289, %2290 : vector<2xf32>
      %2315 = vector.from_elements %2312, %2313 : vector<2xf32>
      %2316 = nvvm.add.packed.f32x2 %2314, %2315 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2317 = vector.extract %2316[0] : f32 from vector<2xf32>
      %2318 = vector.extract %2316[1] : f32 from vector<2xf32>
      %2319 = cute.memref.load(%view_715, %67) : (!memref_rmem_f32_1, !cute.coord<"(20,0)">) -> f32
      %2320 = cute.memref.load(%view_715, %66) : (!memref_rmem_f32_1, !cute.coord<"(21,0)">) -> f32
      %2321 = vector.from_elements %2296, %2297 : vector<2xf32>
      %2322 = vector.from_elements %2319, %2320 : vector<2xf32>
      %2323 = nvvm.add.packed.f32x2 %2321, %2322 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2324 = vector.extract %2323[0] : f32 from vector<2xf32>
      %2325 = vector.extract %2323[1] : f32 from vector<2xf32>
      %2326 = cute.memref.load(%view_715, %65) : (!memref_rmem_f32_1, !cute.coord<"(20,1)">) -> f32
      %2327 = cute.memref.load(%view_715, %64) : (!memref_rmem_f32_1, !cute.coord<"(21,1)">) -> f32
      %2328 = vector.from_elements %2303, %2304 : vector<2xf32>
      %2329 = vector.from_elements %2326, %2327 : vector<2xf32>
      %2330 = nvvm.add.packed.f32x2 %2328, %2329 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2331 = vector.extract %2330[0] : f32 from vector<2xf32>
      %2332 = vector.extract %2330[1] : f32 from vector<2xf32>
      %2333 = cute.memref.load(%view_715, %63) : (!memref_rmem_f32_1, !cute.coord<"(20,2)">) -> f32
      %2334 = cute.memref.load(%view_715, %62) : (!memref_rmem_f32_1, !cute.coord<"(21,2)">) -> f32
      %2335 = vector.from_elements %2310, %2311 : vector<2xf32>
      %2336 = vector.from_elements %2333, %2334 : vector<2xf32>
      %2337 = nvvm.add.packed.f32x2 %2335, %2336 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2338 = vector.extract %2337[0] : f32 from vector<2xf32>
      %2339 = vector.extract %2337[1] : f32 from vector<2xf32>
      %2340 = cute.memref.load(%view_715, %61) : (!memref_rmem_f32_1, !cute.coord<"(20,3)">) -> f32
      %2341 = cute.memref.load(%view_715, %60) : (!memref_rmem_f32_1, !cute.coord<"(21,3)">) -> f32
      %2342 = vector.from_elements %2317, %2318 : vector<2xf32>
      %2343 = vector.from_elements %2340, %2341 : vector<2xf32>
      %2344 = nvvm.add.packed.f32x2 %2342, %2343 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2345 = vector.extract %2344[0] : f32 from vector<2xf32>
      %2346 = vector.extract %2344[1] : f32 from vector<2xf32>
      %2347 = cute.memref.load(%view_715, %59) : (!memref_rmem_f32_1, !cute.coord<"(22,0)">) -> f32
      %2348 = cute.memref.load(%view_715, %58) : (!memref_rmem_f32_1, !cute.coord<"(23,0)">) -> f32
      %2349 = vector.from_elements %2324, %2325 : vector<2xf32>
      %2350 = vector.from_elements %2347, %2348 : vector<2xf32>
      %2351 = nvvm.add.packed.f32x2 %2349, %2350 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2352 = vector.extract %2351[0] : f32 from vector<2xf32>
      %2353 = vector.extract %2351[1] : f32 from vector<2xf32>
      %2354 = cute.memref.load(%view_715, %57) : (!memref_rmem_f32_1, !cute.coord<"(22,1)">) -> f32
      %2355 = cute.memref.load(%view_715, %56) : (!memref_rmem_f32_1, !cute.coord<"(23,1)">) -> f32
      %2356 = vector.from_elements %2331, %2332 : vector<2xf32>
      %2357 = vector.from_elements %2354, %2355 : vector<2xf32>
      %2358 = nvvm.add.packed.f32x2 %2356, %2357 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2359 = vector.extract %2358[0] : f32 from vector<2xf32>
      %2360 = vector.extract %2358[1] : f32 from vector<2xf32>
      %2361 = cute.memref.load(%view_715, %55) : (!memref_rmem_f32_1, !cute.coord<"(22,2)">) -> f32
      %2362 = cute.memref.load(%view_715, %54) : (!memref_rmem_f32_1, !cute.coord<"(23,2)">) -> f32
      %2363 = vector.from_elements %2338, %2339 : vector<2xf32>
      %2364 = vector.from_elements %2361, %2362 : vector<2xf32>
      %2365 = nvvm.add.packed.f32x2 %2363, %2364 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2366 = vector.extract %2365[0] : f32 from vector<2xf32>
      %2367 = vector.extract %2365[1] : f32 from vector<2xf32>
      %2368 = cute.memref.load(%view_715, %53) : (!memref_rmem_f32_1, !cute.coord<"(22,3)">) -> f32
      %2369 = cute.memref.load(%view_715, %52) : (!memref_rmem_f32_1, !cute.coord<"(23,3)">) -> f32
      %2370 = vector.from_elements %2345, %2346 : vector<2xf32>
      %2371 = vector.from_elements %2368, %2369 : vector<2xf32>
      %2372 = nvvm.add.packed.f32x2 %2370, %2371 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2373 = vector.extract %2372[0] : f32 from vector<2xf32>
      %2374 = vector.extract %2372[1] : f32 from vector<2xf32>
      %2375 = cute.memref.load(%view_715, %51) : (!memref_rmem_f32_1, !cute.coord<"(24,0)">) -> f32
      %2376 = cute.memref.load(%view_715, %50) : (!memref_rmem_f32_1, !cute.coord<"(25,0)">) -> f32
      %2377 = vector.from_elements %2352, %2353 : vector<2xf32>
      %2378 = vector.from_elements %2375, %2376 : vector<2xf32>
      %2379 = nvvm.add.packed.f32x2 %2377, %2378 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2380 = vector.extract %2379[0] : f32 from vector<2xf32>
      %2381 = vector.extract %2379[1] : f32 from vector<2xf32>
      %2382 = cute.memref.load(%view_715, %49) : (!memref_rmem_f32_1, !cute.coord<"(24,1)">) -> f32
      %2383 = cute.memref.load(%view_715, %48) : (!memref_rmem_f32_1, !cute.coord<"(25,1)">) -> f32
      %2384 = vector.from_elements %2359, %2360 : vector<2xf32>
      %2385 = vector.from_elements %2382, %2383 : vector<2xf32>
      %2386 = nvvm.add.packed.f32x2 %2384, %2385 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2387 = vector.extract %2386[0] : f32 from vector<2xf32>
      %2388 = vector.extract %2386[1] : f32 from vector<2xf32>
      %2389 = cute.memref.load(%view_715, %47) : (!memref_rmem_f32_1, !cute.coord<"(24,2)">) -> f32
      %2390 = cute.memref.load(%view_715, %46) : (!memref_rmem_f32_1, !cute.coord<"(25,2)">) -> f32
      %2391 = vector.from_elements %2366, %2367 : vector<2xf32>
      %2392 = vector.from_elements %2389, %2390 : vector<2xf32>
      %2393 = nvvm.add.packed.f32x2 %2391, %2392 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2394 = vector.extract %2393[0] : f32 from vector<2xf32>
      %2395 = vector.extract %2393[1] : f32 from vector<2xf32>
      %2396 = cute.memref.load(%view_715, %45) : (!memref_rmem_f32_1, !cute.coord<"(24,3)">) -> f32
      %2397 = cute.memref.load(%view_715, %44) : (!memref_rmem_f32_1, !cute.coord<"(25,3)">) -> f32
      %2398 = vector.from_elements %2373, %2374 : vector<2xf32>
      %2399 = vector.from_elements %2396, %2397 : vector<2xf32>
      %2400 = nvvm.add.packed.f32x2 %2398, %2399 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2401 = vector.extract %2400[0] : f32 from vector<2xf32>
      %2402 = vector.extract %2400[1] : f32 from vector<2xf32>
      %2403 = cute.memref.load(%view_715, %43) : (!memref_rmem_f32_1, !cute.coord<"(26,0)">) -> f32
      %2404 = cute.memref.load(%view_715, %42) : (!memref_rmem_f32_1, !cute.coord<"(27,0)">) -> f32
      %2405 = vector.from_elements %2380, %2381 : vector<2xf32>
      %2406 = vector.from_elements %2403, %2404 : vector<2xf32>
      %2407 = nvvm.add.packed.f32x2 %2405, %2406 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2408 = vector.extract %2407[0] : f32 from vector<2xf32>
      %2409 = vector.extract %2407[1] : f32 from vector<2xf32>
      %2410 = cute.memref.load(%view_715, %41) : (!memref_rmem_f32_1, !cute.coord<"(26,1)">) -> f32
      %2411 = cute.memref.load(%view_715, %40) : (!memref_rmem_f32_1, !cute.coord<"(27,1)">) -> f32
      %2412 = vector.from_elements %2387, %2388 : vector<2xf32>
      %2413 = vector.from_elements %2410, %2411 : vector<2xf32>
      %2414 = nvvm.add.packed.f32x2 %2412, %2413 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2415 = vector.extract %2414[0] : f32 from vector<2xf32>
      %2416 = vector.extract %2414[1] : f32 from vector<2xf32>
      %2417 = cute.memref.load(%view_715, %39) : (!memref_rmem_f32_1, !cute.coord<"(26,2)">) -> f32
      %2418 = cute.memref.load(%view_715, %38) : (!memref_rmem_f32_1, !cute.coord<"(27,2)">) -> f32
      %2419 = vector.from_elements %2394, %2395 : vector<2xf32>
      %2420 = vector.from_elements %2417, %2418 : vector<2xf32>
      %2421 = nvvm.add.packed.f32x2 %2419, %2420 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2422 = vector.extract %2421[0] : f32 from vector<2xf32>
      %2423 = vector.extract %2421[1] : f32 from vector<2xf32>
      %2424 = cute.memref.load(%view_715, %37) : (!memref_rmem_f32_1, !cute.coord<"(26,3)">) -> f32
      %2425 = cute.memref.load(%view_715, %36) : (!memref_rmem_f32_1, !cute.coord<"(27,3)">) -> f32
      %2426 = vector.from_elements %2401, %2402 : vector<2xf32>
      %2427 = vector.from_elements %2424, %2425 : vector<2xf32>
      %2428 = nvvm.add.packed.f32x2 %2426, %2427 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2429 = vector.extract %2428[0] : f32 from vector<2xf32>
      %2430 = vector.extract %2428[1] : f32 from vector<2xf32>
      %2431 = cute.memref.load(%view_715, %35) : (!memref_rmem_f32_1, !cute.coord<"(28,0)">) -> f32
      %2432 = cute.memref.load(%view_715, %34) : (!memref_rmem_f32_1, !cute.coord<"(29,0)">) -> f32
      %2433 = vector.from_elements %2408, %2409 : vector<2xf32>
      %2434 = vector.from_elements %2431, %2432 : vector<2xf32>
      %2435 = nvvm.add.packed.f32x2 %2433, %2434 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2436 = vector.extract %2435[0] : f32 from vector<2xf32>
      %2437 = vector.extract %2435[1] : f32 from vector<2xf32>
      %2438 = cute.memref.load(%view_715, %33) : (!memref_rmem_f32_1, !cute.coord<"(28,1)">) -> f32
      %2439 = cute.memref.load(%view_715, %32) : (!memref_rmem_f32_1, !cute.coord<"(29,1)">) -> f32
      %2440 = vector.from_elements %2415, %2416 : vector<2xf32>
      %2441 = vector.from_elements %2438, %2439 : vector<2xf32>
      %2442 = nvvm.add.packed.f32x2 %2440, %2441 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2443 = vector.extract %2442[0] : f32 from vector<2xf32>
      %2444 = vector.extract %2442[1] : f32 from vector<2xf32>
      %2445 = cute.memref.load(%view_715, %31) : (!memref_rmem_f32_1, !cute.coord<"(28,2)">) -> f32
      %2446 = cute.memref.load(%view_715, %30) : (!memref_rmem_f32_1, !cute.coord<"(29,2)">) -> f32
      %2447 = vector.from_elements %2422, %2423 : vector<2xf32>
      %2448 = vector.from_elements %2445, %2446 : vector<2xf32>
      %2449 = nvvm.add.packed.f32x2 %2447, %2448 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2450 = vector.extract %2449[0] : f32 from vector<2xf32>
      %2451 = vector.extract %2449[1] : f32 from vector<2xf32>
      %2452 = cute.memref.load(%view_715, %29) : (!memref_rmem_f32_1, !cute.coord<"(28,3)">) -> f32
      %2453 = cute.memref.load(%view_715, %28) : (!memref_rmem_f32_1, !cute.coord<"(29,3)">) -> f32
      %2454 = vector.from_elements %2429, %2430 : vector<2xf32>
      %2455 = vector.from_elements %2452, %2453 : vector<2xf32>
      %2456 = nvvm.add.packed.f32x2 %2454, %2455 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2457 = vector.extract %2456[0] : f32 from vector<2xf32>
      %2458 = vector.extract %2456[1] : f32 from vector<2xf32>
      %2459 = cute.memref.load(%view_715, %27) : (!memref_rmem_f32_1, !cute.coord<"(30,0)">) -> f32
      %2460 = cute.memref.load(%view_715, %26) : (!memref_rmem_f32_1, !cute.coord<"(31,0)">) -> f32
      %2461 = vector.from_elements %2436, %2437 : vector<2xf32>
      %2462 = vector.from_elements %2459, %2460 : vector<2xf32>
      %2463 = nvvm.add.packed.f32x2 %2461, %2462 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2464 = vector.extract %2463[0] : f32 from vector<2xf32>
      %2465 = vector.extract %2463[1] : f32 from vector<2xf32>
      %2466 = cute.memref.load(%view_715, %25) : (!memref_rmem_f32_1, !cute.coord<"(30,1)">) -> f32
      %2467 = cute.memref.load(%view_715, %24) : (!memref_rmem_f32_1, !cute.coord<"(31,1)">) -> f32
      %2468 = vector.from_elements %2443, %2444 : vector<2xf32>
      %2469 = vector.from_elements %2466, %2467 : vector<2xf32>
      %2470 = nvvm.add.packed.f32x2 %2468, %2469 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2471 = vector.extract %2470[0] : f32 from vector<2xf32>
      %2472 = vector.extract %2470[1] : f32 from vector<2xf32>
      %2473 = cute.memref.load(%view_715, %23) : (!memref_rmem_f32_1, !cute.coord<"(30,2)">) -> f32
      %2474 = cute.memref.load(%view_715, %22) : (!memref_rmem_f32_1, !cute.coord<"(31,2)">) -> f32
      %2475 = vector.from_elements %2450, %2451 : vector<2xf32>
      %2476 = vector.from_elements %2473, %2474 : vector<2xf32>
      %2477 = nvvm.add.packed.f32x2 %2475, %2476 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2478 = vector.extract %2477[0] : f32 from vector<2xf32>
      %2479 = vector.extract %2477[1] : f32 from vector<2xf32>
      %2480 = cute.memref.load(%view_715, %21) : (!memref_rmem_f32_1, !cute.coord<"(30,3)">) -> f32
      %2481 = cute.memref.load(%view_715, %20) : (!memref_rmem_f32_1, !cute.coord<"(31,3)">) -> f32
      %2482 = vector.from_elements %2457, %2458 : vector<2xf32>
      %2483 = vector.from_elements %2480, %2481 : vector<2xf32>
      %2484 = nvvm.add.packed.f32x2 %2482, %2483 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2485 = vector.extract %2484[0] : f32 from vector<2xf32>
      %2486 = vector.extract %2484[1] : f32 from vector<2xf32>
      %2487 = vector.from_elements %2464, %2465 : vector<2xf32>
      %2488 = vector.from_elements %2471, %2472 : vector<2xf32>
      %2489 = nvvm.add.packed.f32x2 %2487, %2488 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2490 = vector.extract %2489[0] : f32 from vector<2xf32>
      %2491 = vector.extract %2489[1] : f32 from vector<2xf32>
      %2492 = vector.from_elements %2478, %2479 : vector<2xf32>
      %2493 = vector.from_elements %2485, %2486 : vector<2xf32>
      %2494 = nvvm.add.packed.f32x2 %2492, %2493 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2495 = vector.extract %2494[0] : f32 from vector<2xf32>
      %2496 = vector.extract %2494[1] : f32 from vector<2xf32>
      %2497 = vector.from_elements %2490, %2491 : vector<2xf32>
      %2498 = vector.from_elements %2495, %2496 : vector<2xf32>
      %2499 = nvvm.add.packed.f32x2 %2497, %2498 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2500 = vector.extract %2499[0] : f32 from vector<2xf32>
      %2501 = vector.extract %2499[1] : f32 from vector<2xf32>
      %2502 = arith.addf %2500, %2501 : f32
      %2503 = arith.subf %1971, %1990 : f32
      %2504 = arith.mulf %arg13, %2503 : f32
      %2505 = math.exp2 %2504 fastmath<fast> : f32
      %int_tuple_716 = cute.make_int_tuple(%1969) : (i32) -> !cute.int_tuple<"?">
      %ptr_717 = cute.add_offset(%iter_111, %int_tuple_716) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2506 = builtin.unrealized_conversion_cast %ptr_717 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2506, %1970, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2507 = arith.addi %1969, %c1_i32 : i32
      %2508 = arith.addi %1968, %c1_i32 : i32
      %2509 = arith.cmpi eq, %2507, %c1_i32 : i32
      %2510 = arith.select %2509, %c0_i32, %2507 : i32
      cf.cond_br %2509, ^bb585, ^bb586
    ^bb585:  // pred: ^bb584
      %2511 = arith.xori %1970, %c1_i32 : i32
      cf.br ^bb587(%2511 : i32)
    ^bb586:  // pred: ^bb584
      cf.br ^bb587(%1970 : i32)
    ^bb587(%2512: i32):  // 2 preds: ^bb585, ^bb586
      cf.br ^bb588
    ^bb588:  // pred: ^bb587
      %2513 = vector.splat %2505 : vector<2xf32>
      cf.br ^bb589(%c0_i32 : i32)
    ^bb589(%2514: i32):  // 2 preds: ^bb588, ^bb602
      %2515 = arith.cmpi slt, %2514, %c2_i32 : i32
      cf.cond_br %2515, ^bb590, ^bb603
    ^bb590:  // pred: ^bb589
      %coord_718 = cute.make_coord(%2514) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_719 = cute.crd2idx(%coord_718, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_720 = cute.add_offset(%ptr_137, %idx_719) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_721 = cute.add_offset(%ptr_720, %int_tuple_618) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      cf.br ^bb591(%c0_i32 : i32)
    ^bb591(%2516: i32):  // 2 preds: ^bb590, ^bb601
      %2517 = arith.cmpi slt, %2516, %c4_i32 : i32
      cf.cond_br %2517, ^bb592, ^bb602 {loop_annotation = #loop_annotation1}
    ^bb592:  // pred: ^bb591
      %coord_722 = cute.make_coord(%2516) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_723 = cute.crd2idx(%coord_722, %154) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((32,32),1),1,4):(((1,65536),0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_724 = cute.add_offset(%ptr_721, %idx_723) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem_725 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_726 = cute.get_iter(%rmem_725) : !memref_rmem_f32_2
      %2518 = builtin.unrealized_conversion_cast %iter_726 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb593(%c0_i32 : i32)
    ^bb593(%2519: i32):  // 2 preds: ^bb592, ^bb594
      %2520 = arith.cmpi slt, %2519, %1395 : i32
      cf.cond_br %2520, ^bb594, ^bb595 {llvm.loop_annotation = #loop_annotation}
    ^bb594:  // pred: ^bb593
      %2521 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_724) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      llvm.store %2521, %2518 : vector<32xi32>, !llvm.ptr
      %2522 = arith.addi %2519, %c1_i32 : i32
      cf.br ^bb593(%2522 : i32)
    ^bb595:  // pred: ^bb593
      cf.br ^bb596(%c0_i32 : i32)
    ^bb596(%2523: i32):  // 2 preds: ^bb595, ^bb597
      %2524 = arith.cmpi slt, %2523, %c32_i32 : i32
      cf.cond_br %2524, ^bb597, ^bb598 {loop_annotation = #loop_annotation1}
    ^bb597:  // pred: ^bb596
      %coord_727 = cute.make_coord(%2523) : (i32) -> !cute.coord<"?">
      %2525 = cute.memref.load(%rmem_725, %coord_727) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2526 = arith.addi %2523, %c1_i32 : i32
      %coord_728 = cute.make_coord(%2526) : (i32) -> !cute.coord<"?">
      %2527 = cute.memref.load(%rmem_725, %coord_728) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2528 = vector.from_elements %2525, %2527 : vector<2xf32>
      %2529 = nvvm.mul.packed.f32x2 %2528, %2513 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2530 = vector.extract %2529[0] : f32 from vector<2xf32>
      %2531 = vector.extract %2529[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_725, %coord_727, %2530) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_725, %coord_728, %2531) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      %2532 = arith.addi %2523, %c2_i32 : i32
      cf.br ^bb596(%2532 : i32)
    ^bb598:  // pred: ^bb596
      %2533 = builtin.unrealized_conversion_cast %iter_726 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb599(%c0_i32 : i32)
    ^bb599(%2534: i32):  // 2 preds: ^bb598, ^bb600
      %2535 = arith.cmpi slt, %2534, %1395 : i32
      cf.cond_br %2535, ^bb600, ^bb601 {llvm.loop_annotation = #loop_annotation}
    ^bb600:  // pred: ^bb599
      %2536 = llvm.load %2533 : !llvm.ptr -> vector<32xi32>
      "cute_nvgpu.arch.copy.SM100.tmem_store"(%ptr_724, %2536) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>, vector<32xi32>) -> ()
      %2537 = arith.addi %2534, %c1_i32 : i32
      cf.br ^bb599(%2537 : i32)
    ^bb601:  // pred: ^bb599
      %2538 = arith.addi %2516, %c1_i32 : i32
      cf.br ^bb591(%2538 : i32)
    ^bb602:  // pred: ^bb591
      %2539 = arith.addi %2514, %c1_i32 : i32
      cf.br ^bb589(%2539 : i32)
    ^bb603:  // pred: ^bb589
      nvvm.tcgen05.wait <store>
      %ptr_729 = cute.add_offset(%ptr_112, %int_tuple_716) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2540 = builtin.unrealized_conversion_cast %ptr_729 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2541 = nvvm.mapa.shared.cluster %2540, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2541, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %2542 = arith.addi %1960, %c1_i32 : i32
      cf.br ^bb566(%2542, %2502, %1975, %1977, %1979, %2014, %2016, %2018, %2508, %2510, %2512, %1990 : i32, f32, i32, i32, i32, i32, i32, i32, i32, i32, i32, f32)
    ^bb604:  // pred: ^bb566
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_610, %1961) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %2543 = cute.memref.load(%view, %coord_613) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %2544 = arith.addf %1961, %2543 : f32
      %2545 = arith.divf %arg14, %2544 : f32
      %int_tuple_730 = cute.make_int_tuple(%1969) : (i32) -> !cute.int_tuple<"?">
      %ptr_731 = cute.add_offset(%iter_111, %int_tuple_730) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2546 = builtin.unrealized_conversion_cast %ptr_731 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2546, %1970, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2547 = arith.addi %1969, %c1_i32 : i32
      %2548 = arith.addi %1968, %c1_i32 : i32
      %2549 = arith.cmpi eq, %2547, %c1_i32 : i32
      %2550 = arith.select %2549, %c0_i32, %2547 : i32
      cf.cond_br %2549, ^bb605, ^bb606
    ^bb605:  // pred: ^bb604
      %2551 = arith.xori %1970, %c1_i32 : i32
      cf.br ^bb607(%2551 : i32)
    ^bb606:  // pred: ^bb604
      cf.br ^bb607(%1970 : i32)
    ^bb607(%2552: i32):  // 2 preds: ^bb605, ^bb606
      cf.br ^bb608
    ^bb608:  // pred: ^bb607
      %2553 = vector.splat %2545 : vector<2xf32>
      cf.br ^bb609(%c0_i32 : i32)
    ^bb609(%2554: i32):  // 2 preds: ^bb608, ^bb624
      %2555 = arith.cmpi slt, %2554, %c2_i32 : i32
      cf.cond_br %2555, ^bb610, ^bb625
    ^bb610:  // pred: ^bb609
      %coord_732 = cute.make_coord(%2554) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_733 = cute.crd2idx(%coord_732, %lay_603) : (!cute.coord<"(_,_,?)">, !cute.layout<"(64,256,?):(?{div=256},1,256)">) -> !cute.int_tuple<"?{div=256}">
      %ptr_734 = cute.add_offset(%ptr_605, %idx_733) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, gmem, align<128>>
      %idx_735 = cute.crd2idx(%coord_732, %lay_607) : (!cute.coord<"(_,_,?)">, !cute.layout<"(64,256,?):(1@0,1@1,256@1)">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_736 = cute.add_offset(%tup_609, %idx_735) : (!cute.int_tuple<"(?{div=64},0,((?,?),?))">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256},((?,?),?))">
      %coord_737 = cute.make_coord(%2554) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_738 = cute.crd2idx(%coord_737, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_739 = cute.add_offset(%ptr_137, %idx_738) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_740 = cute.add_offset(%ptr_739, %int_tuple_626) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_741 = cute.add_offset(%ptr_734, %int_tuple_628) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, gmem, align<128>>
      %tup_742 = cute.add_offset(%tup_736, %int_tuple_630) : (!cute.int_tuple<"(?{div=64},?{div=256},((?,?),?))">, !cute.int_tuple<"(?,?{div=128})">) -> !cute.int_tuple<"(?,?{div=128},((?,?),?))">
      cf.br ^bb611(%c0_i32 : i32)
    ^bb611(%2556: i32):  // 2 preds: ^bb610, ^bb623
      %2557 = arith.cmpi slt, %2556, %c4_i32 : i32
      cf.cond_br %2557, ^bb612, ^bb624 {loop_annotation = #loop_annotation1}
    ^bb612:  // pred: ^bb611
      %coord_743 = cute.make_coord(%2556) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_744 = cute.crd2idx(%coord_743, %154) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((32,32),1),1,4):(((1,65536),0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_745 = cute.add_offset(%ptr_740, %idx_744) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_746 = cute.crd2idx(%coord_743, %155) : (!cute.coord<"(_,0,?)">, !cute.layout<"((32,1),1,4):((1,0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_747 = cute.add_offset(%ptr_741, %idx_746) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, gmem, align<64>>
      %idx_748 = cute.crd2idx(%coord_743, %17) : (!cute.coord<"(_,0,?)">, !cute.layout<"((32,1),1,4):((1@1,0),0,32@1)">) -> !cute.int_tuple<"(0,?{div=32})">
      %tup_749 = cute.add_offset(%tup_742, %idx_748) : (!cute.int_tuple<"(?,?{div=128},((?,?),?))">, !cute.int_tuple<"(0,?{div=32})">) -> !cute.int_tuple<"(?,?{div=32},((?,?),?))">
      %rmem_750 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_751 = cute.get_iter(%rmem_750) : !memref_rmem_f32_2
      %2558 = builtin.unrealized_conversion_cast %iter_751 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb613(%c0_i32 : i32)
    ^bb613(%2559: i32):  // 2 preds: ^bb612, ^bb614
      %2560 = arith.cmpi slt, %2559, %1408 : i32
      cf.cond_br %2560, ^bb614, ^bb615 {llvm.loop_annotation = #loop_annotation}
    ^bb614:  // pred: ^bb613
      %2561 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_745) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      llvm.store %2561, %2558 : vector<32xi32>, !llvm.ptr
      %2562 = arith.addi %2559, %c1_i32 : i32
      cf.br ^bb613(%2562 : i32)
    ^bb615:  // pred: ^bb613
      cf.br ^bb616(%c0_i32 : i32)
    ^bb616(%2563: i32):  // 2 preds: ^bb615, ^bb617
      %2564 = arith.cmpi slt, %2563, %c32_i32 : i32
      cf.cond_br %2564, ^bb617, ^bb618 {loop_annotation = #loop_annotation1}
    ^bb617:  // pred: ^bb616
      %coord_752 = cute.make_coord(%2563) : (i32) -> !cute.coord<"?">
      %2565 = cute.memref.load(%rmem_750, %coord_752) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2566 = arith.addi %2563, %c1_i32 : i32
      %coord_753 = cute.make_coord(%2566) : (i32) -> !cute.coord<"?">
      %2567 = cute.memref.load(%rmem_750, %coord_753) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2568 = vector.from_elements %2565, %2567 : vector<2xf32>
      %2569 = nvvm.mul.packed.f32x2 %2568, %2553 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2570 = vector.extract %2569[0] : f32 from vector<2xf32>
      %2571 = vector.extract %2569[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_750, %coord_752, %2570) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_750, %coord_753, %2571) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      %2572 = arith.addi %2563, %c2_i32 : i32
      cf.br ^bb616(%2572 : i32)
    ^bb618:  // pred: ^bb616
      %rmem_754 = cute.memref.alloca() : !memref_rmem_bf16_1
      %2573 = cute.memref.load_vec %rmem_750 : !memref_rmem_f32_2
      %2574 = arith.truncf %2573 : vector<32xf32> to vector<32xbf16>
      cute.memref.store_vec %2574, %rmem_754 : !memref_rmem_bf16_1
      %e0_755, %e1_756, %e2_757, %e3_758, %e4_759 = cute.get_leaves(%tup_749) : !cute.int_tuple<"(?,?{div=32},((?,?),?))">
      %coord_760 = cute.make_coord(%e0_755) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2575 = cute.get_scalars(%coord_760) : !cute.coord<"?">
      %2576 = arith.cmpi slt, %2575, %1409 : i32
      cf.cond_br %2576, ^bb619, ^bb623
    ^bb619:  // pred: ^bb618
      %iter_761 = cute.get_iter(%rmem_754) : !memref_rmem_bf16_1
      %2577 = cute.get_scalars(%211) : !cute.int_tuple<"2">
      cf.br ^bb620(%c0_i32 : i32)
    ^bb620(%2578: i32):  // 2 preds: ^bb619, ^bb621
      %2579 = arith.cmpi slt, %2578, %2577 : i32
      cf.cond_br %2579, ^bb621, ^bb622 {llvm.loop_annotation = #loop_annotation}
    ^bb621:  // pred: ^bb620
      %coord_762 = cute.make_coord(%2578) : (i32) -> !cute.coord<"(_,?)">
      %idx_763 = cute.crd2idx(%coord_762, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_764 = cute.add_offset(%iter_761, %idx_763) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_765 = cute.add_offset(%ptr_747, %idx_763) : (!cute.ptr<bf16, gmem, align<64>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, gmem, align<32>>
      %2580 = builtin.unrealized_conversion_cast %ptr_764 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2581 = builtin.unrealized_conversion_cast %ptr_765 : !cute.ptr<bf16, gmem, align<32>> to !llvm.ptr<1>
      %2582 = llvm.load %2580 {alignment = 32 : i64} : !llvm.ptr -> vector<16xbf16>
      llvm.store %2582, %2581 {alignment = 32 : i64} : vector<16xbf16>, !llvm.ptr<1>
      %2583 = arith.addi %2578, %c1_i32 : i32
      cf.br ^bb620(%2583 : i32)
    ^bb622:  // pred: ^bb620
      cf.br ^bb623
    ^bb623:  // 2 preds: ^bb618, ^bb622
      %2584 = arith.addi %2556, %c1_i32 : i32
      cf.br ^bb611(%2584 : i32)
    ^bb624:  // pred: ^bb611
      %2585 = arith.addi %2554, %c1_i32 : i32
      cf.br ^bb609(%2585 : i32)
    ^bb625:  // pred: ^bb609
      %ptr_766 = cute.add_offset(%ptr_112, %int_tuple_730) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2586 = builtin.unrealized_conversion_cast %ptr_766 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2587 = nvvm.mapa.shared.cluster %2586, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2587, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.br ^bb547(%1962, %1963, %1964, %1965, %1966, %1967, %2548, %2550, %2552, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb626:  // pred: ^bb547
      %2588 = arith.addi %1414, %c1_i32 : i32
      %2589 = arith.cmpi eq, %2588, %c2_i32 : i32
      %2590 = arith.select %2589, %c0_i32, %2588 : i32
      cf.cond_br %2589, ^bb627, ^bb628
    ^bb627:  // pred: ^bb626
      %2591 = arith.xori %1415, %c1_i32 : i32
      cf.br ^bb629(%2591 : i32)
    ^bb628:  // pred: ^bb626
      cf.br ^bb629(%1415 : i32)
    ^bb629(%2592: i32):  // 2 preds: ^bb627, ^bb628
      cf.br ^bb630
    ^bb630:  // pred: ^bb629
      %int_tuple_767 = cute.make_int_tuple(%2590) : (i32) -> !cute.int_tuple<"?">
      %ptr_768 = cute.add_offset(%ptr_108, %int_tuple_767) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2593 = builtin.unrealized_conversion_cast %ptr_768 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2593, %2592, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %326, ^bb631, ^bb632
    ^bb631:  // pred: ^bb630
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb632
    ^bb632:  // 2 preds: ^bb630, ^bb631
      cf.cond_br %326, ^bb633, ^bb634
    ^bb633:  // pred: ^bb632
      %2594 = arith.xori %258, %c1_i32 : i32
      %2595 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      %2596 = nvvm.mapa.shared.cluster %2595, %2594 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2596, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %2595, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb634
    ^bb634:  // 2 preds: ^bb632, ^bb633
      cf.br ^bb640(%1419 : i1)
    ^bb635:  // pred: ^bb539
      cf.cond_br %326, ^bb636, ^bb639
    ^bb636:  // pred: ^bb635
      %2597 = nvvm.elect.sync -> i1
      cf.cond_br %2597, ^bb637, ^bb638
    ^bb637:  // pred: ^bb636
      %2598 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %2598, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb638
    ^bb638:  // 2 preds: ^bb636, ^bb637
      cf.br ^bb639
    ^bb639:  // 2 preds: ^bb635, ^bb638
      nvvm.fence.mbarrier.init
      cf.br ^bb640(%1359 : i1)
    ^bb640(%2599: i1):  // 2 preds: ^bb634, ^bb639
      cf.br ^bb641
    ^bb641:  // pred: ^bb640
      cf.cond_br %326, ^bb642, ^bb645
    ^bb642:  // pred: ^bb641
      %2600 = nvvm.elect.sync -> i1
      cf.cond_br %2600, ^bb643, ^bb644
    ^bb643:  // pred: ^bb642
      %2601 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %2601, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb644
    ^bb644:  // 2 preds: ^bb642, ^bb643
      cf.br ^bb645
    ^bb645:  // 2 preds: ^bb641, ^bb644
      nvvm.fence.mbarrier.init
      %2602 = arith.cmpi slt, %236, %c8_i32 : i32
      cf.cond_br %2602, ^bb646, ^bb813
    ^bb646:  // pred: ^bb645
      nvvm.setmaxregister  decrease 112
      %int_tuple_769 = cute.make_int_tuple(%itup_247) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %2603 = cute.get_scalars(%int_tuple_769) <{only_dynamic}> : !cute.int_tuple<"?">
      %2604 = arith.ceildivsi %2603, %c256_i32 : i32
      %int_tuple_770 = cute.make_int_tuple(%2604) : (i32) -> !cute.int_tuple<"?">
      %e0_771 = cute.get_leaves(%int_tuple_770) : !cute.int_tuple<"?">
      %sub_772 = cute.tuple_sub(%e0_771, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %2605 = cute.get_scalars(%sub_772) : !cute.int_tuple<"?">
      %2606 = arith.remsi %225, %c256_i32 : i32
      %atom_773 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8, 32 b>
      %coord_774 = cute.make_coord(%2606) : (i32) -> !cute.coord<"?">
      %2607 = cute.get_scalars(%coord_774) <{only_dynamic}> : !cute.coord<"?">
      %2608 = arith.divsi %2607, %c4_i32 : i32
      %2609 = arith.remsi %2607, %c4_i32 : i32
      %2610 = arith.muli %2609, %c16_i32 : i32
      %2611 = arith.muli %2608, %c64_i32 : i32
      %2612 = arith.addi %2610, %2611 : i32
      %iv_775 = cute.assume(%2612) : (i32) -> !cute.i32<divby 16>
      %int_tuple_776 = cute.make_int_tuple(%iv_775) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_777 = cute.add_offset(%iter_132, %int_tuple_776) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %ptr_778 = cute.add_offset(%iter_118, %int_tuple_776) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %int_tuple_779 = cute.make_int_tuple(%2608) : (i32) -> !cute.int_tuple<"?">
      %ptr_780 = cute.add_offset(%iter_122, %int_tuple_779) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2613 = cute.get_scalars(%149) : !cute.int_tuple<"16">
      %2614 = cute.get_scalars(%211) : !cute.int_tuple<"2">
      %swizzled_781 = cute.apply_swizzle(%ptr_777) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2615 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %swizzled_782 = cute.apply_swizzle(%ptr_777) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2616 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %swizzled_783 = cute.apply_swizzle(%ptr_777) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %swizzled_784 = cute.apply_swizzle(%ptr_777) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2617 = arith.divsi %2607, %c64_i32 : i32
      %2618 = arith.remsi %2607, %c64_i32 : i32
      %2619 = arith.muli %2618, %c16_i32 : i32
      %2620 = arith.muli %2617, %c1024_i32 : i32
      %2621 = arith.addi %2619, %2620 : i32
      %iv_785 = cute.assume(%2621) : (i32) -> !cute.i32<divby 16>
      %int_tuple_786 = cute.make_int_tuple(%iv_785) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_787 = cute.add_offset(%iter_133, %int_tuple_786) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_788 = cute.add_offset(%iter_119, %int_tuple_786) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2622 = arith.divsi %2618, %c4_i32 : i32
      %2623 = arith.muli %2617, %c16_i32 : i32
      %2624 = arith.addi %2622, %2623 : i32
      %int_tuple_789 = cute.make_int_tuple(%2624) : (i32) -> !cute.int_tuple<"?">
      %ptr_790 = cute.add_offset(%iter_125, %int_tuple_789) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2625 = cute.get_scalars(%5) : !cute.int_tuple<"32">
      %2626 = arith.divsi %2607, %c64_i32 : i32
      %2627 = arith.remsi %2607, %c64_i32 : i32
      %2628 = arith.muli %2627, %c16_i32 : i32
      %2629 = arith.muli %2626, %c1024_i32 : i32
      %2630 = arith.addi %2628, %2629 : i32
      %iv_791 = cute.assume(%2630) : (i32) -> !cute.i32<divby 16>
      %int_tuple_792 = cute.make_int_tuple(%iv_791) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_793 = cute.add_offset(%iter_133, %int_tuple_792) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_794 = cute.add_offset(%iter_119, %int_tuple_792) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2631 = arith.divsi %2627, %c4_i32 : i32
      %2632 = arith.muli %2626, %c16_i32 : i32
      %2633 = arith.addi %2631, %2632 : i32
      %int_tuple_795 = cute.make_int_tuple(%2633) : (i32) -> !cute.int_tuple<"?">
      %ptr_796 = cute.add_offset(%iter_125, %int_tuple_795) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2634 = cute.get_scalars(%5) : !cute.int_tuple<"32">
      cf.br ^bb647(%c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %2599 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb647(%2635: i32, %2636: i32, %2637: i32, %2638: i32, %2639: i32, %2640: i32, %2641: i32, %2642: i32, %2643: i32, %2644: i32, %2645: i32, %2646: i32, %2647: i1):  // 2 preds: ^bb646, ^bb803
      cf.cond_br %2647, ^bb648(%2635, %2636, %2637, %2638, %2639, %2640, %2641, %2642, %2643, %2644, %2645, %2646 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32), ^bb804
    ^bb648(%2648: i32, %2649: i32, %2650: i32, %2651: i32, %2652: i32, %2653: i32, %2654: i32, %2655: i32, %2656: i32, %2657: i32, %2658: i32, %2659: i32):  // pred: ^bb647
      %2660 = cute.make_tiled_copy(%atom_773) : !copy_simt1
      %rmem_797 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_798 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_799 = cute.memref.alloca() : !memref_rmem_bf16_3
      %int_tuple_800 = cute.make_int_tuple(%2652) : (i32) -> !cute.int_tuple<"?">
      %ptr_801 = cute.add_offset(%iter_60, %int_tuple_800) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2661 = builtin.unrealized_conversion_cast %ptr_801 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2661, %2653, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2662 = arith.addi %2652, %c1_i32 : i32
      %2663 = arith.addi %2651, %c1_i32 : i32
      %2664 = arith.cmpi eq, %2662, %c5_i32 : i32
      %2665 = arith.select %2664, %c0_i32, %2662 : i32
      cf.cond_br %2664, ^bb649, ^bb650
    ^bb649:  // pred: ^bb648
      %2666 = arith.xori %2653, %c1_i32 : i32
      cf.br ^bb651(%2666 : i32)
    ^bb650:  // pred: ^bb648
      cf.br ^bb651(%2653 : i32)
    ^bb651(%2667: i32):  // 2 preds: ^bb649, ^bb650
      cf.br ^bb652
    ^bb652:  // pred: ^bb651
      %coord_802 = cute.make_coord(%2652) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_803 = cute.crd2idx(%coord_802, %14) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,(8,1),5):((0,0),64,0,0,(0,1),128)">) -> !cute.int_tuple<"?{div=128}">
      %iter_804 = cute.get_iter(%rmem_799) : !memref_rmem_bf16_3
      cf.br ^bb653(%c0_i32 : i32)
    ^bb653(%2668: i32):  // 2 preds: ^bb652, ^bb654
      %2669 = arith.cmpi slt, %2668, %2613 : i32
      cf.cond_br %2669, ^bb654, ^bb655 {llvm.loop_annotation = #loop_annotation}
    ^bb654:  // pred: ^bb653
      %coord_805 = cute.make_coord(%2668) : (i32) -> !cute.coord<"(_,?)">
      %idx_806 = cute.crd2idx(%coord_805, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(64,0,0,(0,1)))">) -> !cute.int_tuple<"?">
      %ptr_807 = cute.add_offset(%ptr_780, %idx_806) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_808 = cute.add_offset(%ptr_807, %idx_803) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem>
      %idx_809 = cute.crd2idx(%coord_805, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(1,0,0,(0,0)))">) -> !cute.int_tuple<"?">
      %ptr_810 = cute.add_offset(%iter_804, %idx_809) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %2670 = builtin.unrealized_conversion_cast %ptr_808 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %2671 = builtin.unrealized_conversion_cast %ptr_810 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %2672 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2672, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2673 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2673, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2674 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2674, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2675 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2675, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2676 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2676, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2677 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2677, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2678 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2678, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2679 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2679, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2680 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2680, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2681 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2681, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2682 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2682, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2683 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2683, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2684 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2684, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2685 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2685, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2686 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2686, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2687 = llvm.load %2670 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2687, %2671 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2688 = arith.addi %2668, %c1_i32 : i32
      cf.br ^bb653(%2688 : i32)
    ^bb655:  // pred: ^bb653
      %int_tuple_811 = cute.make_int_tuple(%2649) : (i32) -> !cute.int_tuple<"?">
      %ptr_812 = cute.add_offset(%iter_45, %int_tuple_811) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2689 = builtin.unrealized_conversion_cast %ptr_812 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2689, %2650, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2690 = arith.addi %2649, %c1_i32 : i32
      %2691 = arith.addi %2648, %c1_i32 : i32
      %2692 = arith.cmpi eq, %2690, %c5_i32 : i32
      %2693 = arith.select %2692, %c0_i32, %2690 : i32
      cf.cond_br %2692, ^bb656, ^bb657
    ^bb656:  // pred: ^bb655
      %2694 = arith.xori %2650, %c1_i32 : i32
      cf.br ^bb658(%2694 : i32)
    ^bb657:  // pred: ^bb655
      cf.br ^bb658(%2650 : i32)
    ^bb658(%2695: i32):  // 2 preds: ^bb656, ^bb657
      cf.br ^bb659
    ^bb659:  // pred: ^bb658
      %coord_813 = cute.make_coord(%2649) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_814 = cute.crd2idx(%coord_813, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %iter_815 = cute.get_iter(%rmem_797) : !memref_rmem_i8_
      %ptr_816 = cute.add_offset(%swizzled_781, %idx_814) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb660(%c0_i32 : i32)
    ^bb660(%2696: i32):  // 2 preds: ^bb659, ^bb661
      %2697 = arith.cmpi slt, %2696, %2614 : i32
      cf.cond_br %2697, ^bb661, ^bb662 {llvm.loop_annotation = #loop_annotation}
    ^bb661:  // pred: ^bb660
      %coord_817 = cute.make_coord(%2696) : (i32) -> !cute.coord<"(_,?)">
      %idx_818 = cute.crd2idx(%coord_817, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_819 = cute.crd2idx(%coord_817, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_820 = cute.add_offset(%iter_815, %idx_819) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_821 = cute.add_offset(%ptr_816, %idx_818) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2698 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %2699 = builtin.unrealized_conversion_cast %ptr_820 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %2700 = llvm.load %2698 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %2700, %2699 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %2701 = arith.addi %2696, %c1_i32 : i32
      cf.br ^bb660(%2701 : i32)
    ^bb662:  // pred: ^bb660
      %view_822 = cute.make_view(%iter_815) : !memref_rmem_i8_1
      %2702 = cute.memref.load_vec %view_822 : !memref_rmem_i8_1
      %2703 = vector.extract_strided_slice %2702 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2704 = llvm.bitcast %2703 : vector<4xi8> to i32
      %2705 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2704, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2706 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2704, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2707 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2704, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2708 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2704, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2709 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2705 : (i32) -> f32
      %2710 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2706 : (i32) -> f32
      %2711 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2707 : (i32) -> f32
      %2712 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2708 : (i32) -> f32
      %2713 = vector.from_elements %2709, %2710, %2711, %2712 : vector<4xf32>
      %2714 = vector.extract_strided_slice %2713 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2715 = vector.extract_strided_slice %2713 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2716 = vector.extractelement %2714[%c0_i32 : i32] : vector<2xf32>
      %2717 = vector.extractelement %2714[%c1_i32 : i32] : vector<2xf32>
      %2718 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2717, %2716 : (f32, f32) -> i32
      %2719 = llvm.bitcast %2718 : i32 to vector<2xbf16>
      %2720 = vector.extractelement %2715[%c0_i32 : i32] : vector<2xf32>
      %2721 = vector.extractelement %2715[%c1_i32 : i32] : vector<2xf32>
      %2722 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2721, %2720 : (f32, f32) -> i32
      %2723 = llvm.bitcast %2722 : i32 to vector<2xbf16>
      %2724 = vector.insert_strided_slice %2719, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2725 = vector.insert_strided_slice %2723, %2724 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2726 = vector.extract_strided_slice %2702 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2727 = llvm.bitcast %2726 : vector<4xi8> to i32
      %2728 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2727, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2729 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2727, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2730 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2727, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2731 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2727, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2732 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2728 : (i32) -> f32
      %2733 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2729 : (i32) -> f32
      %2734 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2730 : (i32) -> f32
      %2735 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2731 : (i32) -> f32
      %2736 = vector.from_elements %2732, %2733, %2734, %2735 : vector<4xf32>
      %2737 = vector.extract_strided_slice %2736 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2738 = vector.extract_strided_slice %2736 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2739 = vector.extractelement %2737[%c0_i32 : i32] : vector<2xf32>
      %2740 = vector.extractelement %2737[%c1_i32 : i32] : vector<2xf32>
      %2741 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2740, %2739 : (f32, f32) -> i32
      %2742 = llvm.bitcast %2741 : i32 to vector<2xbf16>
      %2743 = vector.extractelement %2738[%c0_i32 : i32] : vector<2xf32>
      %2744 = vector.extractelement %2738[%c1_i32 : i32] : vector<2xf32>
      %2745 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2744, %2743 : (f32, f32) -> i32
      %2746 = llvm.bitcast %2745 : i32 to vector<2xbf16>
      %2747 = vector.insert_strided_slice %2742, %2725 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2748 = vector.insert_strided_slice %2746, %2747 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2749 = vector.extract_strided_slice %2702 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2750 = llvm.bitcast %2749 : vector<4xi8> to i32
      %2751 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2750, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2752 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2750, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2753 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2750, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2754 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2750, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2755 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2751 : (i32) -> f32
      %2756 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2752 : (i32) -> f32
      %2757 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2753 : (i32) -> f32
      %2758 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2754 : (i32) -> f32
      %2759 = vector.from_elements %2755, %2756, %2757, %2758 : vector<4xf32>
      %2760 = vector.extract_strided_slice %2759 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2761 = vector.extract_strided_slice %2759 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2762 = vector.extractelement %2760[%c0_i32 : i32] : vector<2xf32>
      %2763 = vector.extractelement %2760[%c1_i32 : i32] : vector<2xf32>
      %2764 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2763, %2762 : (f32, f32) -> i32
      %2765 = llvm.bitcast %2764 : i32 to vector<2xbf16>
      %2766 = vector.extractelement %2761[%c0_i32 : i32] : vector<2xf32>
      %2767 = vector.extractelement %2761[%c1_i32 : i32] : vector<2xf32>
      %2768 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2767, %2766 : (f32, f32) -> i32
      %2769 = llvm.bitcast %2768 : i32 to vector<2xbf16>
      %2770 = vector.insert_strided_slice %2765, %2748 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2771 = vector.insert_strided_slice %2769, %2770 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2772 = vector.extract_strided_slice %2702 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2773 = llvm.bitcast %2772 : vector<4xi8> to i32
      %2774 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2773, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2775 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2773, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2776 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2773, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2777 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2773, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2778 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2774 : (i32) -> f32
      %2779 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2775 : (i32) -> f32
      %2780 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2776 : (i32) -> f32
      %2781 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2777 : (i32) -> f32
      %2782 = vector.from_elements %2778, %2779, %2780, %2781 : vector<4xf32>
      %2783 = vector.extract_strided_slice %2782 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2784 = vector.extract_strided_slice %2782 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2785 = vector.extractelement %2783[%c0_i32 : i32] : vector<2xf32>
      %2786 = vector.extractelement %2783[%c1_i32 : i32] : vector<2xf32>
      %2787 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2786, %2785 : (f32, f32) -> i32
      %2788 = llvm.bitcast %2787 : i32 to vector<2xbf16>
      %2789 = vector.extractelement %2784[%c0_i32 : i32] : vector<2xf32>
      %2790 = vector.extractelement %2784[%c1_i32 : i32] : vector<2xf32>
      %2791 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2790, %2789 : (f32, f32) -> i32
      %2792 = llvm.bitcast %2791 : i32 to vector<2xbf16>
      %2793 = vector.insert_strided_slice %2788, %2771 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2794 = vector.insert_strided_slice %2792, %2793 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2795 = vector.extract_strided_slice %2702 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2796 = llvm.bitcast %2795 : vector<4xi8> to i32
      %2797 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2796, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2798 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2796, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2799 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2796, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2800 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2796, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2801 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2797 : (i32) -> f32
      %2802 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2798 : (i32) -> f32
      %2803 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2799 : (i32) -> f32
      %2804 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2800 : (i32) -> f32
      %2805 = vector.from_elements %2801, %2802, %2803, %2804 : vector<4xf32>
      %2806 = vector.extract_strided_slice %2805 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2807 = vector.extract_strided_slice %2805 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2808 = vector.extractelement %2806[%c0_i32 : i32] : vector<2xf32>
      %2809 = vector.extractelement %2806[%c1_i32 : i32] : vector<2xf32>
      %2810 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2809, %2808 : (f32, f32) -> i32
      %2811 = llvm.bitcast %2810 : i32 to vector<2xbf16>
      %2812 = vector.extractelement %2807[%c0_i32 : i32] : vector<2xf32>
      %2813 = vector.extractelement %2807[%c1_i32 : i32] : vector<2xf32>
      %2814 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2813, %2812 : (f32, f32) -> i32
      %2815 = llvm.bitcast %2814 : i32 to vector<2xbf16>
      %2816 = vector.insert_strided_slice %2811, %2794 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2817 = vector.insert_strided_slice %2815, %2816 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2818 = vector.extract_strided_slice %2702 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2819 = llvm.bitcast %2818 : vector<4xi8> to i32
      %2820 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2819, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2821 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2819, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2822 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2819, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2823 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2819, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2824 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2820 : (i32) -> f32
      %2825 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2821 : (i32) -> f32
      %2826 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2822 : (i32) -> f32
      %2827 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2823 : (i32) -> f32
      %2828 = vector.from_elements %2824, %2825, %2826, %2827 : vector<4xf32>
      %2829 = vector.extract_strided_slice %2828 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2830 = vector.extract_strided_slice %2828 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2831 = vector.extractelement %2829[%c0_i32 : i32] : vector<2xf32>
      %2832 = vector.extractelement %2829[%c1_i32 : i32] : vector<2xf32>
      %2833 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2832, %2831 : (f32, f32) -> i32
      %2834 = llvm.bitcast %2833 : i32 to vector<2xbf16>
      %2835 = vector.extractelement %2830[%c0_i32 : i32] : vector<2xf32>
      %2836 = vector.extractelement %2830[%c1_i32 : i32] : vector<2xf32>
      %2837 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2836, %2835 : (f32, f32) -> i32
      %2838 = llvm.bitcast %2837 : i32 to vector<2xbf16>
      %2839 = vector.insert_strided_slice %2834, %2817 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2840 = vector.insert_strided_slice %2838, %2839 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2841 = vector.extract_strided_slice %2702 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2842 = llvm.bitcast %2841 : vector<4xi8> to i32
      %2843 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2842, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2844 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2842, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2845 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2842, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2846 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2842, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2847 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2843 : (i32) -> f32
      %2848 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2844 : (i32) -> f32
      %2849 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2845 : (i32) -> f32
      %2850 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2846 : (i32) -> f32
      %2851 = vector.from_elements %2847, %2848, %2849, %2850 : vector<4xf32>
      %2852 = vector.extract_strided_slice %2851 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2853 = vector.extract_strided_slice %2851 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2854 = vector.extractelement %2852[%c0_i32 : i32] : vector<2xf32>
      %2855 = vector.extractelement %2852[%c1_i32 : i32] : vector<2xf32>
      %2856 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2855, %2854 : (f32, f32) -> i32
      %2857 = llvm.bitcast %2856 : i32 to vector<2xbf16>
      %2858 = vector.extractelement %2853[%c0_i32 : i32] : vector<2xf32>
      %2859 = vector.extractelement %2853[%c1_i32 : i32] : vector<2xf32>
      %2860 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2859, %2858 : (f32, f32) -> i32
      %2861 = llvm.bitcast %2860 : i32 to vector<2xbf16>
      %2862 = vector.insert_strided_slice %2857, %2840 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2863 = vector.insert_strided_slice %2861, %2862 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2864 = vector.extract_strided_slice %2702 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2865 = llvm.bitcast %2864 : vector<4xi8> to i32
      %2866 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2865, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2867 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2865, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2868 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2865, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2869 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2865, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2870 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2866 : (i32) -> f32
      %2871 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2867 : (i32) -> f32
      %2872 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2868 : (i32) -> f32
      %2873 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2869 : (i32) -> f32
      %2874 = vector.from_elements %2870, %2871, %2872, %2873 : vector<4xf32>
      %2875 = vector.extract_strided_slice %2874 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2876 = vector.extract_strided_slice %2874 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2877 = vector.extractelement %2875[%c0_i32 : i32] : vector<2xf32>
      %2878 = vector.extractelement %2875[%c1_i32 : i32] : vector<2xf32>
      %2879 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2878, %2877 : (f32, f32) -> i32
      %2880 = llvm.bitcast %2879 : i32 to vector<2xbf16>
      %2881 = vector.extractelement %2876[%c0_i32 : i32] : vector<2xf32>
      %2882 = vector.extractelement %2876[%c1_i32 : i32] : vector<2xf32>
      %2883 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2882, %2881 : (f32, f32) -> i32
      %2884 = llvm.bitcast %2883 : i32 to vector<2xbf16>
      %2885 = vector.insert_strided_slice %2880, %2863 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2886 = vector.insert_strided_slice %2884, %2885 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_823 = cute.make_view(%iter_804) : !memref_rmem_bf16_4
      %2887 = cute.memref.load_vec %view_823 : !memref_rmem_bf16_4
      %2888 = arith.mulf %2886, %2887 : vector<32xbf16>
      %iter_824 = cute.get_iter(%rmem_798) : !memref_rmem_bf16_2
      %view_825 = cute.make_view(%iter_824) : !memref_rmem_bf16_5
      cute.memref.store_vec %2888, %view_825 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_826 = cute.add_offset(%ptr_50, %int_tuple_811) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2889 = builtin.unrealized_conversion_cast %ptr_826 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %2889, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb663(%c1_i32, %2654, %2655, %2656, %2691, %2693, %2695 : i32, i32, i32, i32, i32, i32, i32)
    ^bb663(%2890: i32, %2891: i32, %2892: i32, %2893: i32, %2894: i32, %2895: i32, %2896: i32):  // 2 preds: ^bb662, ^bb678
      %2897 = arith.cmpi slt, %2890, %c8_i32 : i32
      cf.cond_br %2897, ^bb664, ^bb679 {loop_annotation = #loop_annotation1}
    ^bb664:  // pred: ^bb663
      %int_tuple_827 = cute.make_int_tuple(%2892) : (i32) -> !cute.int_tuple<"?">
      %ptr_828 = cute.add_offset(%ptr_95, %int_tuple_827) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2898 = builtin.unrealized_conversion_cast %ptr_828 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2898, %2893, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2899 = arith.addi %2892, %c1_i32 : i32
      %2900 = arith.addi %2891, %c1_i32 : i32
      %2901 = arith.cmpi eq, %2899, %c3_i32 : i32
      %2902 = arith.select %2901, %c0_i32, %2899 : i32
      cf.cond_br %2901, ^bb665, ^bb666
    ^bb665:  // pred: ^bb664
      %2903 = arith.xori %2893, %c1_i32 : i32
      cf.br ^bb667(%2903 : i32)
    ^bb666:  // pred: ^bb664
      cf.br ^bb667(%2893 : i32)
    ^bb667(%2904: i32):  // 2 preds: ^bb665, ^bb666
      cf.br ^bb668
    ^bb668:  // pred: ^bb667
      %2905 = arith.subi %2890, %c1_i32 : i32
      %2906 = arith.remsi %2905, %c2_i32 : i32
      %coord_829 = cute.make_coord(%2906) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_830 = cute.crd2idx(%coord_829, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_831 = cute.add_offset(%iter_824, %idx_830) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_832 = cute.make_coord(%2892) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_833 = cute.crd2idx(%coord_832, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb669(%c0_i32 : i32)
    ^bb669(%2907: i32):  // 2 preds: ^bb668, ^bb670
      %2908 = arith.cmpi slt, %2907, %2615 : i32
      cf.cond_br %2908, ^bb670, ^bb671 {llvm.loop_annotation = #loop_annotation}
    ^bb670:  // pred: ^bb669
      %coord_834 = cute.make_coord(%2907) : (i32) -> !cute.coord<"(_,?)">
      %idx_835 = cute.crd2idx(%coord_834, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_836 = cute.add_offset(%ptr_831, %idx_835) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_837 = cute.crd2idx(%coord_834, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_838 = cute.add_offset(%ptr_778, %idx_837) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_839 = cute.apply_swizzle(%ptr_838) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_840 = cute.add_offset(%swizzled_839, %idx_833) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %2909 = builtin.unrealized_conversion_cast %ptr_836 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2910 = builtin.unrealized_conversion_cast %ptr_840 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %2911 = llvm.load %2909 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2911, %2910 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %2912 = arith.addi %2907, %c1_i32 : i32
      cf.br ^bb669(%2912 : i32)
    ^bb671:  // pred: ^bb669
      %int_tuple_841 = cute.make_int_tuple(%2895) : (i32) -> !cute.int_tuple<"?">
      %ptr_842 = cute.add_offset(%iter_45, %int_tuple_841) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2913 = builtin.unrealized_conversion_cast %ptr_842 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2913, %2896, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2914 = arith.addi %2895, %c1_i32 : i32
      %2915 = arith.addi %2894, %c1_i32 : i32
      %2916 = arith.cmpi eq, %2914, %c5_i32 : i32
      %2917 = arith.select %2916, %c0_i32, %2914 : i32
      cf.cond_br %2916, ^bb672, ^bb673
    ^bb672:  // pred: ^bb671
      %2918 = arith.xori %2896, %c1_i32 : i32
      cf.br ^bb674(%2918 : i32)
    ^bb673:  // pred: ^bb671
      cf.br ^bb674(%2896 : i32)
    ^bb674(%2919: i32):  // 2 preds: ^bb672, ^bb673
      cf.br ^bb675
    ^bb675:  // pred: ^bb674
      %coord_843 = cute.make_coord(%2895) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_844 = cute.crd2idx(%coord_843, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %2920 = arith.remsi %2890, %c2_i32 : i32
      %coord_845 = cute.make_coord(%2920) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_846 = cute.crd2idx(%coord_845, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_847 = cute.add_offset(%iter_815, %idx_846) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      %ptr_848 = cute.add_offset(%swizzled_782, %idx_844) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb676(%c0_i32 : i32)
    ^bb676(%2921: i32):  // 2 preds: ^bb675, ^bb677
      %2922 = arith.cmpi slt, %2921, %2614 : i32
      cf.cond_br %2922, ^bb677, ^bb678 {llvm.loop_annotation = #loop_annotation}
    ^bb677:  // pred: ^bb676
      %coord_849 = cute.make_coord(%2921) : (i32) -> !cute.coord<"(_,?)">
      %idx_850 = cute.crd2idx(%coord_849, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_851 = cute.crd2idx(%coord_849, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_852 = cute.add_offset(%ptr_847, %idx_851) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_853 = cute.add_offset(%ptr_848, %idx_850) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2923 = builtin.unrealized_conversion_cast %ptr_853 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %2924 = builtin.unrealized_conversion_cast %ptr_852 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %2925 = llvm.load %2923 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %2925, %2924 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %2926 = arith.addi %2921, %c1_i32 : i32
      cf.br ^bb676(%2926 : i32)
    ^bb678:  // pred: ^bb676
      %view_854 = cute.make_view(%ptr_847) : !memref_rmem_i8_1
      %2927 = cute.memref.load_vec %view_854 : !memref_rmem_i8_1
      %2928 = vector.extract_strided_slice %2927 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2929 = llvm.bitcast %2928 : vector<4xi8> to i32
      %2930 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2929, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2931 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2929, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2932 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2929, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2933 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2929, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2934 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2930 : (i32) -> f32
      %2935 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2931 : (i32) -> f32
      %2936 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2932 : (i32) -> f32
      %2937 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2933 : (i32) -> f32
      %2938 = vector.from_elements %2934, %2935, %2936, %2937 : vector<4xf32>
      %2939 = vector.extract_strided_slice %2938 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2940 = vector.extract_strided_slice %2938 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2941 = vector.extractelement %2939[%c0_i32 : i32] : vector<2xf32>
      %2942 = vector.extractelement %2939[%c1_i32 : i32] : vector<2xf32>
      %2943 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2942, %2941 : (f32, f32) -> i32
      %2944 = llvm.bitcast %2943 : i32 to vector<2xbf16>
      %2945 = vector.extractelement %2940[%c0_i32 : i32] : vector<2xf32>
      %2946 = vector.extractelement %2940[%c1_i32 : i32] : vector<2xf32>
      %2947 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2946, %2945 : (f32, f32) -> i32
      %2948 = llvm.bitcast %2947 : i32 to vector<2xbf16>
      %2949 = vector.insert_strided_slice %2944, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2950 = vector.insert_strided_slice %2948, %2949 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2951 = vector.extract_strided_slice %2927 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2952 = llvm.bitcast %2951 : vector<4xi8> to i32
      %2953 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2952, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2954 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2952, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2955 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2952, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2956 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2952, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2957 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2953 : (i32) -> f32
      %2958 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2954 : (i32) -> f32
      %2959 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2955 : (i32) -> f32
      %2960 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2956 : (i32) -> f32
      %2961 = vector.from_elements %2957, %2958, %2959, %2960 : vector<4xf32>
      %2962 = vector.extract_strided_slice %2961 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2963 = vector.extract_strided_slice %2961 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2964 = vector.extractelement %2962[%c0_i32 : i32] : vector<2xf32>
      %2965 = vector.extractelement %2962[%c1_i32 : i32] : vector<2xf32>
      %2966 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2965, %2964 : (f32, f32) -> i32
      %2967 = llvm.bitcast %2966 : i32 to vector<2xbf16>
      %2968 = vector.extractelement %2963[%c0_i32 : i32] : vector<2xf32>
      %2969 = vector.extractelement %2963[%c1_i32 : i32] : vector<2xf32>
      %2970 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2969, %2968 : (f32, f32) -> i32
      %2971 = llvm.bitcast %2970 : i32 to vector<2xbf16>
      %2972 = vector.insert_strided_slice %2967, %2950 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2973 = vector.insert_strided_slice %2971, %2972 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2974 = vector.extract_strided_slice %2927 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2975 = llvm.bitcast %2974 : vector<4xi8> to i32
      %2976 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2975, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2977 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2975, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2978 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2975, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2979 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2975, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2980 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2976 : (i32) -> f32
      %2981 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2977 : (i32) -> f32
      %2982 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2978 : (i32) -> f32
      %2983 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2979 : (i32) -> f32
      %2984 = vector.from_elements %2980, %2981, %2982, %2983 : vector<4xf32>
      %2985 = vector.extract_strided_slice %2984 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2986 = vector.extract_strided_slice %2984 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2987 = vector.extractelement %2985[%c0_i32 : i32] : vector<2xf32>
      %2988 = vector.extractelement %2985[%c1_i32 : i32] : vector<2xf32>
      %2989 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2988, %2987 : (f32, f32) -> i32
      %2990 = llvm.bitcast %2989 : i32 to vector<2xbf16>
      %2991 = vector.extractelement %2986[%c0_i32 : i32] : vector<2xf32>
      %2992 = vector.extractelement %2986[%c1_i32 : i32] : vector<2xf32>
      %2993 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2992, %2991 : (f32, f32) -> i32
      %2994 = llvm.bitcast %2993 : i32 to vector<2xbf16>
      %2995 = vector.insert_strided_slice %2990, %2973 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2996 = vector.insert_strided_slice %2994, %2995 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2997 = vector.extract_strided_slice %2927 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2998 = llvm.bitcast %2997 : vector<4xi8> to i32
      %2999 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2998, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3000 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2998, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3001 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2998, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3002 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2998, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3003 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2999 : (i32) -> f32
      %3004 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3000 : (i32) -> f32
      %3005 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3001 : (i32) -> f32
      %3006 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3002 : (i32) -> f32
      %3007 = vector.from_elements %3003, %3004, %3005, %3006 : vector<4xf32>
      %3008 = vector.extract_strided_slice %3007 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3009 = vector.extract_strided_slice %3007 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3010 = vector.extractelement %3008[%c0_i32 : i32] : vector<2xf32>
      %3011 = vector.extractelement %3008[%c1_i32 : i32] : vector<2xf32>
      %3012 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3011, %3010 : (f32, f32) -> i32
      %3013 = llvm.bitcast %3012 : i32 to vector<2xbf16>
      %3014 = vector.extractelement %3009[%c0_i32 : i32] : vector<2xf32>
      %3015 = vector.extractelement %3009[%c1_i32 : i32] : vector<2xf32>
      %3016 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3015, %3014 : (f32, f32) -> i32
      %3017 = llvm.bitcast %3016 : i32 to vector<2xbf16>
      %3018 = vector.insert_strided_slice %3013, %2996 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3019 = vector.insert_strided_slice %3017, %3018 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3020 = vector.extract_strided_slice %2927 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3021 = llvm.bitcast %3020 : vector<4xi8> to i32
      %3022 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3021, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3023 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3021, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3024 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3021, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3025 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3021, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3026 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3022 : (i32) -> f32
      %3027 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3023 : (i32) -> f32
      %3028 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3024 : (i32) -> f32
      %3029 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3025 : (i32) -> f32
      %3030 = vector.from_elements %3026, %3027, %3028, %3029 : vector<4xf32>
      %3031 = vector.extract_strided_slice %3030 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3032 = vector.extract_strided_slice %3030 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3033 = vector.extractelement %3031[%c0_i32 : i32] : vector<2xf32>
      %3034 = vector.extractelement %3031[%c1_i32 : i32] : vector<2xf32>
      %3035 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3034, %3033 : (f32, f32) -> i32
      %3036 = llvm.bitcast %3035 : i32 to vector<2xbf16>
      %3037 = vector.extractelement %3032[%c0_i32 : i32] : vector<2xf32>
      %3038 = vector.extractelement %3032[%c1_i32 : i32] : vector<2xf32>
      %3039 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3038, %3037 : (f32, f32) -> i32
      %3040 = llvm.bitcast %3039 : i32 to vector<2xbf16>
      %3041 = vector.insert_strided_slice %3036, %3019 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3042 = vector.insert_strided_slice %3040, %3041 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3043 = vector.extract_strided_slice %2927 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3044 = llvm.bitcast %3043 : vector<4xi8> to i32
      %3045 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3044, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3046 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3044, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3047 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3044, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3048 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3044, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3049 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3045 : (i32) -> f32
      %3050 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3046 : (i32) -> f32
      %3051 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3047 : (i32) -> f32
      %3052 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3048 : (i32) -> f32
      %3053 = vector.from_elements %3049, %3050, %3051, %3052 : vector<4xf32>
      %3054 = vector.extract_strided_slice %3053 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3055 = vector.extract_strided_slice %3053 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3056 = vector.extractelement %3054[%c0_i32 : i32] : vector<2xf32>
      %3057 = vector.extractelement %3054[%c1_i32 : i32] : vector<2xf32>
      %3058 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3057, %3056 : (f32, f32) -> i32
      %3059 = llvm.bitcast %3058 : i32 to vector<2xbf16>
      %3060 = vector.extractelement %3055[%c0_i32 : i32] : vector<2xf32>
      %3061 = vector.extractelement %3055[%c1_i32 : i32] : vector<2xf32>
      %3062 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3061, %3060 : (f32, f32) -> i32
      %3063 = llvm.bitcast %3062 : i32 to vector<2xbf16>
      %3064 = vector.insert_strided_slice %3059, %3042 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3065 = vector.insert_strided_slice %3063, %3064 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3066 = vector.extract_strided_slice %2927 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3067 = llvm.bitcast %3066 : vector<4xi8> to i32
      %3068 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3067, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3069 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3067, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3070 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3067, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3071 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3067, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3072 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3068 : (i32) -> f32
      %3073 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3069 : (i32) -> f32
      %3074 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3070 : (i32) -> f32
      %3075 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3071 : (i32) -> f32
      %3076 = vector.from_elements %3072, %3073, %3074, %3075 : vector<4xf32>
      %3077 = vector.extract_strided_slice %3076 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3078 = vector.extract_strided_slice %3076 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3079 = vector.extractelement %3077[%c0_i32 : i32] : vector<2xf32>
      %3080 = vector.extractelement %3077[%c1_i32 : i32] : vector<2xf32>
      %3081 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3080, %3079 : (f32, f32) -> i32
      %3082 = llvm.bitcast %3081 : i32 to vector<2xbf16>
      %3083 = vector.extractelement %3078[%c0_i32 : i32] : vector<2xf32>
      %3084 = vector.extractelement %3078[%c1_i32 : i32] : vector<2xf32>
      %3085 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3084, %3083 : (f32, f32) -> i32
      %3086 = llvm.bitcast %3085 : i32 to vector<2xbf16>
      %3087 = vector.insert_strided_slice %3082, %3065 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3088 = vector.insert_strided_slice %3086, %3087 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3089 = vector.extract_strided_slice %2927 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3090 = llvm.bitcast %3089 : vector<4xi8> to i32
      %3091 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3090, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3092 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3090, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3093 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3090, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3094 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3090, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3095 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3091 : (i32) -> f32
      %3096 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3092 : (i32) -> f32
      %3097 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3093 : (i32) -> f32
      %3098 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3094 : (i32) -> f32
      %3099 = vector.from_elements %3095, %3096, %3097, %3098 : vector<4xf32>
      %3100 = vector.extract_strided_slice %3099 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3101 = vector.extract_strided_slice %3099 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3102 = vector.extractelement %3100[%c0_i32 : i32] : vector<2xf32>
      %3103 = vector.extractelement %3100[%c1_i32 : i32] : vector<2xf32>
      %3104 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3103, %3102 : (f32, f32) -> i32
      %3105 = llvm.bitcast %3104 : i32 to vector<2xbf16>
      %3106 = vector.extractelement %3101[%c0_i32 : i32] : vector<2xf32>
      %3107 = vector.extractelement %3101[%c1_i32 : i32] : vector<2xf32>
      %3108 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3107, %3106 : (f32, f32) -> i32
      %3109 = llvm.bitcast %3108 : i32 to vector<2xbf16>
      %3110 = vector.insert_strided_slice %3105, %3088 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3111 = vector.insert_strided_slice %3109, %3110 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3112 = cute.memref.load_vec %view_823 : !memref_rmem_bf16_4
      %3113 = arith.mulf %3111, %3112 : vector<32xbf16>
      %ptr_855 = cute.add_offset(%iter_824, %idx_846) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_856 = cute.make_view(%ptr_855) : !memref_rmem_bf16_5
      cute.memref.store_vec %3113, %view_856 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_857 = cute.add_offset(%ptr_50, %int_tuple_841) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3114 = builtin.unrealized_conversion_cast %ptr_857 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3114, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_858 = cute.add_offset(%iter_92, %int_tuple_827) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3115 = builtin.unrealized_conversion_cast %ptr_858 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3116 = nvvm.mapa.shared.cluster %3115, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3116, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %3117 = arith.addi %2890, %c1_i32 : i32
      cf.br ^bb663(%3117, %2900, %2902, %2904, %2915, %2917, %2919 : i32, i32, i32, i32, i32, i32, i32)
    ^bb679:  // pred: ^bb663
      %int_tuple_859 = cute.make_int_tuple(%2892) : (i32) -> !cute.int_tuple<"?">
      %ptr_860 = cute.add_offset(%ptr_95, %int_tuple_859) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3118 = builtin.unrealized_conversion_cast %ptr_860 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3118, %2893, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3119 = arith.addi %2892, %c1_i32 : i32
      %3120 = arith.addi %2891, %c1_i32 : i32
      %3121 = arith.cmpi eq, %3119, %c3_i32 : i32
      %3122 = arith.select %3121, %c0_i32, %3119 : i32
      cf.cond_br %3121, ^bb680, ^bb681
    ^bb680:  // pred: ^bb679
      %3123 = arith.xori %2893, %c1_i32 : i32
      cf.br ^bb682(%3123 : i32)
    ^bb681:  // pred: ^bb679
      cf.br ^bb682(%2893 : i32)
    ^bb682(%3124: i32):  // 2 preds: ^bb680, ^bb681
      cf.br ^bb683
    ^bb683:  // pred: ^bb682
      %ptr_861 = cute.add_offset(%iter_824, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_862 = cute.make_coord(%2892) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_863 = cute.crd2idx(%coord_862, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb684(%c0_i32 : i32)
    ^bb684(%3125: i32):  // 2 preds: ^bb683, ^bb685
      %3126 = arith.cmpi slt, %3125, %2616 : i32
      cf.cond_br %3126, ^bb685, ^bb686 {llvm.loop_annotation = #loop_annotation}
    ^bb685:  // pred: ^bb684
      %coord_864 = cute.make_coord(%3125) : (i32) -> !cute.coord<"(_,?)">
      %idx_865 = cute.crd2idx(%coord_864, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_866 = cute.add_offset(%ptr_861, %idx_865) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_867 = cute.crd2idx(%coord_864, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_868 = cute.add_offset(%ptr_778, %idx_867) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_869 = cute.apply_swizzle(%ptr_868) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_870 = cute.add_offset(%swizzled_869, %idx_863) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3127 = builtin.unrealized_conversion_cast %ptr_866 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3128 = builtin.unrealized_conversion_cast %ptr_870 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3129 = llvm.load %3127 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3129, %3128 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3130 = arith.addi %3125, %c1_i32 : i32
      cf.br ^bb684(%3130 : i32)
    ^bb686:  // pred: ^bb684
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_871 = cute.add_offset(%iter_92, %int_tuple_859) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3131 = builtin.unrealized_conversion_cast %ptr_871 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3132 = nvvm.mapa.shared.cluster %3131, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3132, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_872 = cute.add_offset(%ptr_65, %int_tuple_800) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3133 = builtin.unrealized_conversion_cast %ptr_872 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3133, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb687(%c1_i32, %2894, %2895, %2896, %2663, %2665, %2667, %3120, %3122, %3124, %2657, %2658, %2659 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb687(%3134: i32, %3135: i32, %3136: i32, %3137: i32, %3138: i32, %3139: i32, %3140: i32, %3141: i32, %3142: i32, %3143: i32, %3144: i32, %3145: i32, %3146: i32):  // 2 preds: ^bb686, ^bb764
      %3147 = arith.cmpi slt, %3134, %2605 : i32
      cf.cond_br %3147, ^bb688, ^bb765 {loop_annotation = #loop_annotation2}
    ^bb688:  // pred: ^bb687
      %3148 = cute.make_tiled_copy(%atom_773) : !copy_simt1
      %rmem_873 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_874 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_875 = cute.memref.alloca() : !memref_rmem_bf16_3
      %int_tuple_876 = cute.make_int_tuple(%3139) : (i32) -> !cute.int_tuple<"?">
      %ptr_877 = cute.add_offset(%iter_60, %int_tuple_876) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3149 = builtin.unrealized_conversion_cast %ptr_877 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3149, %3140, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3150 = arith.addi %3139, %c1_i32 : i32
      %3151 = arith.addi %3138, %c1_i32 : i32
      %3152 = arith.cmpi eq, %3150, %c5_i32 : i32
      %3153 = arith.select %3152, %c0_i32, %3150 : i32
      cf.cond_br %3152, ^bb689, ^bb690
    ^bb689:  // pred: ^bb688
      %3154 = arith.xori %3140, %c1_i32 : i32
      cf.br ^bb691(%3154 : i32)
    ^bb690:  // pred: ^bb688
      cf.br ^bb691(%3140 : i32)
    ^bb691(%3155: i32):  // 2 preds: ^bb689, ^bb690
      cf.br ^bb692
    ^bb692:  // pred: ^bb691
      %coord_878 = cute.make_coord(%3139) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_879 = cute.crd2idx(%coord_878, %14) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,(8,1),5):((0,0),64,0,0,(0,1),128)">) -> !cute.int_tuple<"?{div=128}">
      %iter_880 = cute.get_iter(%rmem_875) : !memref_rmem_bf16_3
      cf.br ^bb693(%c0_i32 : i32)
    ^bb693(%3156: i32):  // 2 preds: ^bb692, ^bb694
      %3157 = arith.cmpi slt, %3156, %2613 : i32
      cf.cond_br %3157, ^bb694, ^bb695 {llvm.loop_annotation = #loop_annotation}
    ^bb694:  // pred: ^bb693
      %coord_881 = cute.make_coord(%3156) : (i32) -> !cute.coord<"(_,?)">
      %idx_882 = cute.crd2idx(%coord_881, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(64,0,0,(0,1)))">) -> !cute.int_tuple<"?">
      %ptr_883 = cute.add_offset(%ptr_780, %idx_882) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_884 = cute.add_offset(%ptr_883, %idx_879) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem>
      %idx_885 = cute.crd2idx(%coord_881, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(1,0,0,(0,0)))">) -> !cute.int_tuple<"?">
      %ptr_886 = cute.add_offset(%iter_880, %idx_885) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %3158 = builtin.unrealized_conversion_cast %ptr_884 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %3159 = builtin.unrealized_conversion_cast %ptr_886 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %3160 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3160, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3161 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3161, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3162 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3162, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3163 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3163, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3164 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3164, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3165 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3165, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3166 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3166, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3167 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3167, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3168 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3168, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3169 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3169, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3170 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3170, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3171 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3171, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3172 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3172, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3173 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3173, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3174 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3174, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3175 = llvm.load %3158 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3175, %3159 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3176 = arith.addi %3156, %c1_i32 : i32
      cf.br ^bb693(%3176 : i32)
    ^bb695:  // pred: ^bb693
      %int_tuple_887 = cute.make_int_tuple(%3136) : (i32) -> !cute.int_tuple<"?">
      %ptr_888 = cute.add_offset(%iter_45, %int_tuple_887) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3177 = builtin.unrealized_conversion_cast %ptr_888 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3177, %3137, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3178 = arith.addi %3136, %c1_i32 : i32
      %3179 = arith.addi %3135, %c1_i32 : i32
      %3180 = arith.cmpi eq, %3178, %c5_i32 : i32
      %3181 = arith.select %3180, %c0_i32, %3178 : i32
      cf.cond_br %3180, ^bb696, ^bb697
    ^bb696:  // pred: ^bb695
      %3182 = arith.xori %3137, %c1_i32 : i32
      cf.br ^bb698(%3182 : i32)
    ^bb697:  // pred: ^bb695
      cf.br ^bb698(%3137 : i32)
    ^bb698(%3183: i32):  // 2 preds: ^bb696, ^bb697
      cf.br ^bb699
    ^bb699:  // pred: ^bb698
      %coord_889 = cute.make_coord(%3136) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_890 = cute.crd2idx(%coord_889, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %iter_891 = cute.get_iter(%rmem_873) : !memref_rmem_i8_
      %ptr_892 = cute.add_offset(%swizzled_783, %idx_890) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb700(%c0_i32 : i32)
    ^bb700(%3184: i32):  // 2 preds: ^bb699, ^bb701
      %3185 = arith.cmpi slt, %3184, %2614 : i32
      cf.cond_br %3185, ^bb701, ^bb702 {llvm.loop_annotation = #loop_annotation}
    ^bb701:  // pred: ^bb700
      %coord_893 = cute.make_coord(%3184) : (i32) -> !cute.coord<"(_,?)">
      %idx_894 = cute.crd2idx(%coord_893, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_895 = cute.crd2idx(%coord_893, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_896 = cute.add_offset(%iter_891, %idx_895) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_897 = cute.add_offset(%ptr_892, %idx_894) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %3186 = builtin.unrealized_conversion_cast %ptr_897 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %3187 = builtin.unrealized_conversion_cast %ptr_896 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3188 = llvm.load %3186 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3188, %3187 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3189 = arith.addi %3184, %c1_i32 : i32
      cf.br ^bb700(%3189 : i32)
    ^bb702:  // pred: ^bb700
      %view_898 = cute.make_view(%iter_891) : !memref_rmem_i8_1
      %3190 = cute.memref.load_vec %view_898 : !memref_rmem_i8_1
      %3191 = vector.extract_strided_slice %3190 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3192 = llvm.bitcast %3191 : vector<4xi8> to i32
      %3193 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3192, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3194 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3192, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3195 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3192, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3196 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3192, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3197 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3193 : (i32) -> f32
      %3198 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3194 : (i32) -> f32
      %3199 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3195 : (i32) -> f32
      %3200 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3196 : (i32) -> f32
      %3201 = vector.from_elements %3197, %3198, %3199, %3200 : vector<4xf32>
      %3202 = vector.extract_strided_slice %3201 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3203 = vector.extract_strided_slice %3201 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3204 = vector.extractelement %3202[%c0_i32 : i32] : vector<2xf32>
      %3205 = vector.extractelement %3202[%c1_i32 : i32] : vector<2xf32>
      %3206 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3205, %3204 : (f32, f32) -> i32
      %3207 = llvm.bitcast %3206 : i32 to vector<2xbf16>
      %3208 = vector.extractelement %3203[%c0_i32 : i32] : vector<2xf32>
      %3209 = vector.extractelement %3203[%c1_i32 : i32] : vector<2xf32>
      %3210 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3209, %3208 : (f32, f32) -> i32
      %3211 = llvm.bitcast %3210 : i32 to vector<2xbf16>
      %3212 = vector.insert_strided_slice %3207, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3213 = vector.insert_strided_slice %3211, %3212 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3214 = vector.extract_strided_slice %3190 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3215 = llvm.bitcast %3214 : vector<4xi8> to i32
      %3216 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3215, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3217 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3215, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3218 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3215, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3219 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3215, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3220 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3216 : (i32) -> f32
      %3221 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3217 : (i32) -> f32
      %3222 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3218 : (i32) -> f32
      %3223 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3219 : (i32) -> f32
      %3224 = vector.from_elements %3220, %3221, %3222, %3223 : vector<4xf32>
      %3225 = vector.extract_strided_slice %3224 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3226 = vector.extract_strided_slice %3224 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3227 = vector.extractelement %3225[%c0_i32 : i32] : vector<2xf32>
      %3228 = vector.extractelement %3225[%c1_i32 : i32] : vector<2xf32>
      %3229 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3228, %3227 : (f32, f32) -> i32
      %3230 = llvm.bitcast %3229 : i32 to vector<2xbf16>
      %3231 = vector.extractelement %3226[%c0_i32 : i32] : vector<2xf32>
      %3232 = vector.extractelement %3226[%c1_i32 : i32] : vector<2xf32>
      %3233 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3232, %3231 : (f32, f32) -> i32
      %3234 = llvm.bitcast %3233 : i32 to vector<2xbf16>
      %3235 = vector.insert_strided_slice %3230, %3213 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3236 = vector.insert_strided_slice %3234, %3235 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3237 = vector.extract_strided_slice %3190 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3238 = llvm.bitcast %3237 : vector<4xi8> to i32
      %3239 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3238, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3240 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3238, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3241 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3238, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3242 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3238, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3243 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3239 : (i32) -> f32
      %3244 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3240 : (i32) -> f32
      %3245 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3241 : (i32) -> f32
      %3246 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3242 : (i32) -> f32
      %3247 = vector.from_elements %3243, %3244, %3245, %3246 : vector<4xf32>
      %3248 = vector.extract_strided_slice %3247 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3249 = vector.extract_strided_slice %3247 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3250 = vector.extractelement %3248[%c0_i32 : i32] : vector<2xf32>
      %3251 = vector.extractelement %3248[%c1_i32 : i32] : vector<2xf32>
      %3252 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3251, %3250 : (f32, f32) -> i32
      %3253 = llvm.bitcast %3252 : i32 to vector<2xbf16>
      %3254 = vector.extractelement %3249[%c0_i32 : i32] : vector<2xf32>
      %3255 = vector.extractelement %3249[%c1_i32 : i32] : vector<2xf32>
      %3256 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3255, %3254 : (f32, f32) -> i32
      %3257 = llvm.bitcast %3256 : i32 to vector<2xbf16>
      %3258 = vector.insert_strided_slice %3253, %3236 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3259 = vector.insert_strided_slice %3257, %3258 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3260 = vector.extract_strided_slice %3190 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3261 = llvm.bitcast %3260 : vector<4xi8> to i32
      %3262 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3261, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3263 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3261, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3264 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3261, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3265 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3261, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3266 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3262 : (i32) -> f32
      %3267 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3263 : (i32) -> f32
      %3268 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3264 : (i32) -> f32
      %3269 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3265 : (i32) -> f32
      %3270 = vector.from_elements %3266, %3267, %3268, %3269 : vector<4xf32>
      %3271 = vector.extract_strided_slice %3270 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3272 = vector.extract_strided_slice %3270 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3273 = vector.extractelement %3271[%c0_i32 : i32] : vector<2xf32>
      %3274 = vector.extractelement %3271[%c1_i32 : i32] : vector<2xf32>
      %3275 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3274, %3273 : (f32, f32) -> i32
      %3276 = llvm.bitcast %3275 : i32 to vector<2xbf16>
      %3277 = vector.extractelement %3272[%c0_i32 : i32] : vector<2xf32>
      %3278 = vector.extractelement %3272[%c1_i32 : i32] : vector<2xf32>
      %3279 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3278, %3277 : (f32, f32) -> i32
      %3280 = llvm.bitcast %3279 : i32 to vector<2xbf16>
      %3281 = vector.insert_strided_slice %3276, %3259 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3282 = vector.insert_strided_slice %3280, %3281 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3283 = vector.extract_strided_slice %3190 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3284 = llvm.bitcast %3283 : vector<4xi8> to i32
      %3285 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3284, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3286 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3284, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3287 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3284, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3288 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3284, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3289 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3285 : (i32) -> f32
      %3290 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3286 : (i32) -> f32
      %3291 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3287 : (i32) -> f32
      %3292 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3288 : (i32) -> f32
      %3293 = vector.from_elements %3289, %3290, %3291, %3292 : vector<4xf32>
      %3294 = vector.extract_strided_slice %3293 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3295 = vector.extract_strided_slice %3293 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3296 = vector.extractelement %3294[%c0_i32 : i32] : vector<2xf32>
      %3297 = vector.extractelement %3294[%c1_i32 : i32] : vector<2xf32>
      %3298 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3297, %3296 : (f32, f32) -> i32
      %3299 = llvm.bitcast %3298 : i32 to vector<2xbf16>
      %3300 = vector.extractelement %3295[%c0_i32 : i32] : vector<2xf32>
      %3301 = vector.extractelement %3295[%c1_i32 : i32] : vector<2xf32>
      %3302 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3301, %3300 : (f32, f32) -> i32
      %3303 = llvm.bitcast %3302 : i32 to vector<2xbf16>
      %3304 = vector.insert_strided_slice %3299, %3282 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3305 = vector.insert_strided_slice %3303, %3304 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3306 = vector.extract_strided_slice %3190 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3307 = llvm.bitcast %3306 : vector<4xi8> to i32
      %3308 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3307, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3309 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3307, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3310 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3307, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3311 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3307, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3312 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3308 : (i32) -> f32
      %3313 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3309 : (i32) -> f32
      %3314 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3310 : (i32) -> f32
      %3315 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3311 : (i32) -> f32
      %3316 = vector.from_elements %3312, %3313, %3314, %3315 : vector<4xf32>
      %3317 = vector.extract_strided_slice %3316 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3318 = vector.extract_strided_slice %3316 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3319 = vector.extractelement %3317[%c0_i32 : i32] : vector<2xf32>
      %3320 = vector.extractelement %3317[%c1_i32 : i32] : vector<2xf32>
      %3321 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3320, %3319 : (f32, f32) -> i32
      %3322 = llvm.bitcast %3321 : i32 to vector<2xbf16>
      %3323 = vector.extractelement %3318[%c0_i32 : i32] : vector<2xf32>
      %3324 = vector.extractelement %3318[%c1_i32 : i32] : vector<2xf32>
      %3325 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3324, %3323 : (f32, f32) -> i32
      %3326 = llvm.bitcast %3325 : i32 to vector<2xbf16>
      %3327 = vector.insert_strided_slice %3322, %3305 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3328 = vector.insert_strided_slice %3326, %3327 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3329 = vector.extract_strided_slice %3190 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3330 = llvm.bitcast %3329 : vector<4xi8> to i32
      %3331 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3330, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3332 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3330, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3333 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3330, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3334 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3330, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3335 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3331 : (i32) -> f32
      %3336 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3332 : (i32) -> f32
      %3337 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3333 : (i32) -> f32
      %3338 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3334 : (i32) -> f32
      %3339 = vector.from_elements %3335, %3336, %3337, %3338 : vector<4xf32>
      %3340 = vector.extract_strided_slice %3339 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3341 = vector.extract_strided_slice %3339 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3342 = vector.extractelement %3340[%c0_i32 : i32] : vector<2xf32>
      %3343 = vector.extractelement %3340[%c1_i32 : i32] : vector<2xf32>
      %3344 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3343, %3342 : (f32, f32) -> i32
      %3345 = llvm.bitcast %3344 : i32 to vector<2xbf16>
      %3346 = vector.extractelement %3341[%c0_i32 : i32] : vector<2xf32>
      %3347 = vector.extractelement %3341[%c1_i32 : i32] : vector<2xf32>
      %3348 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3347, %3346 : (f32, f32) -> i32
      %3349 = llvm.bitcast %3348 : i32 to vector<2xbf16>
      %3350 = vector.insert_strided_slice %3345, %3328 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3351 = vector.insert_strided_slice %3349, %3350 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3352 = vector.extract_strided_slice %3190 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3353 = llvm.bitcast %3352 : vector<4xi8> to i32
      %3354 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3353, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3355 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3353, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3356 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3353, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3357 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3353, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3358 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3354 : (i32) -> f32
      %3359 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3355 : (i32) -> f32
      %3360 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3356 : (i32) -> f32
      %3361 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3357 : (i32) -> f32
      %3362 = vector.from_elements %3358, %3359, %3360, %3361 : vector<4xf32>
      %3363 = vector.extract_strided_slice %3362 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3364 = vector.extract_strided_slice %3362 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3365 = vector.extractelement %3363[%c0_i32 : i32] : vector<2xf32>
      %3366 = vector.extractelement %3363[%c1_i32 : i32] : vector<2xf32>
      %3367 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3366, %3365 : (f32, f32) -> i32
      %3368 = llvm.bitcast %3367 : i32 to vector<2xbf16>
      %3369 = vector.extractelement %3364[%c0_i32 : i32] : vector<2xf32>
      %3370 = vector.extractelement %3364[%c1_i32 : i32] : vector<2xf32>
      %3371 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3370, %3369 : (f32, f32) -> i32
      %3372 = llvm.bitcast %3371 : i32 to vector<2xbf16>
      %3373 = vector.insert_strided_slice %3368, %3351 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3374 = vector.insert_strided_slice %3372, %3373 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_899 = cute.make_view(%iter_880) : !memref_rmem_bf16_4
      %3375 = cute.memref.load_vec %view_899 : !memref_rmem_bf16_4
      %3376 = arith.mulf %3374, %3375 : vector<32xbf16>
      %iter_900 = cute.get_iter(%rmem_874) : !memref_rmem_bf16_2
      %view_901 = cute.make_view(%iter_900) : !memref_rmem_bf16_5
      cute.memref.store_vec %3376, %view_901 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_902 = cute.add_offset(%ptr_50, %int_tuple_887) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3377 = builtin.unrealized_conversion_cast %ptr_902 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3377, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb703(%c1_i32, %3141, %3142, %3143, %3179, %3181, %3183 : i32, i32, i32, i32, i32, i32, i32)
    ^bb703(%3378: i32, %3379: i32, %3380: i32, %3381: i32, %3382: i32, %3383: i32, %3384: i32):  // 2 preds: ^bb702, ^bb718
      %3385 = arith.cmpi slt, %3378, %c8_i32 : i32
      cf.cond_br %3385, ^bb704, ^bb719 {loop_annotation = #loop_annotation1}
    ^bb704:  // pred: ^bb703
      %int_tuple_903 = cute.make_int_tuple(%3380) : (i32) -> !cute.int_tuple<"?">
      %ptr_904 = cute.add_offset(%ptr_95, %int_tuple_903) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3386 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3386, %3381, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3387 = arith.addi %3380, %c1_i32 : i32
      %3388 = arith.addi %3379, %c1_i32 : i32
      %3389 = arith.cmpi eq, %3387, %c3_i32 : i32
      %3390 = arith.select %3389, %c0_i32, %3387 : i32
      cf.cond_br %3389, ^bb705, ^bb706
    ^bb705:  // pred: ^bb704
      %3391 = arith.xori %3381, %c1_i32 : i32
      cf.br ^bb707(%3391 : i32)
    ^bb706:  // pred: ^bb704
      cf.br ^bb707(%3381 : i32)
    ^bb707(%3392: i32):  // 2 preds: ^bb705, ^bb706
      cf.br ^bb708
    ^bb708:  // pred: ^bb707
      %3393 = arith.subi %3378, %c1_i32 : i32
      %3394 = arith.remsi %3393, %c2_i32 : i32
      %coord_905 = cute.make_coord(%3394) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_906 = cute.crd2idx(%coord_905, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_907 = cute.add_offset(%iter_900, %idx_906) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_908 = cute.make_coord(%3380) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_909 = cute.crd2idx(%coord_908, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb709(%c0_i32 : i32)
    ^bb709(%3395: i32):  // 2 preds: ^bb708, ^bb710
      %3396 = arith.cmpi slt, %3395, %2616 : i32
      cf.cond_br %3396, ^bb710, ^bb711 {llvm.loop_annotation = #loop_annotation}
    ^bb710:  // pred: ^bb709
      %coord_910 = cute.make_coord(%3395) : (i32) -> !cute.coord<"(_,?)">
      %idx_911 = cute.crd2idx(%coord_910, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_912 = cute.add_offset(%ptr_907, %idx_911) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_913 = cute.crd2idx(%coord_910, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_914 = cute.add_offset(%ptr_778, %idx_913) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_915 = cute.apply_swizzle(%ptr_914) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_916 = cute.add_offset(%swizzled_915, %idx_909) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3397 = builtin.unrealized_conversion_cast %ptr_912 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3398 = builtin.unrealized_conversion_cast %ptr_916 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3399 = llvm.load %3397 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3399, %3398 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3400 = arith.addi %3395, %c1_i32 : i32
      cf.br ^bb709(%3400 : i32)
    ^bb711:  // pred: ^bb709
      %int_tuple_917 = cute.make_int_tuple(%3383) : (i32) -> !cute.int_tuple<"?">
      %ptr_918 = cute.add_offset(%iter_45, %int_tuple_917) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3401 = builtin.unrealized_conversion_cast %ptr_918 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3401, %3384, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3402 = arith.addi %3383, %c1_i32 : i32
      %3403 = arith.addi %3382, %c1_i32 : i32
      %3404 = arith.cmpi eq, %3402, %c5_i32 : i32
      %3405 = arith.select %3404, %c0_i32, %3402 : i32
      cf.cond_br %3404, ^bb712, ^bb713
    ^bb712:  // pred: ^bb711
      %3406 = arith.xori %3384, %c1_i32 : i32
      cf.br ^bb714(%3406 : i32)
    ^bb713:  // pred: ^bb711
      cf.br ^bb714(%3384 : i32)
    ^bb714(%3407: i32):  // 2 preds: ^bb712, ^bb713
      cf.br ^bb715
    ^bb715:  // pred: ^bb714
      %coord_919 = cute.make_coord(%3383) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_920 = cute.crd2idx(%coord_919, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %3408 = arith.remsi %3378, %c2_i32 : i32
      %coord_921 = cute.make_coord(%3408) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_922 = cute.crd2idx(%coord_921, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_923 = cute.add_offset(%iter_891, %idx_922) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      %ptr_924 = cute.add_offset(%swizzled_784, %idx_920) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb716(%c0_i32 : i32)
    ^bb716(%3409: i32):  // 2 preds: ^bb715, ^bb717
      %3410 = arith.cmpi slt, %3409, %2614 : i32
      cf.cond_br %3410, ^bb717, ^bb718 {llvm.loop_annotation = #loop_annotation}
    ^bb717:  // pred: ^bb716
      %coord_925 = cute.make_coord(%3409) : (i32) -> !cute.coord<"(_,?)">
      %idx_926 = cute.crd2idx(%coord_925, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_927 = cute.crd2idx(%coord_925, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_928 = cute.add_offset(%ptr_923, %idx_927) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_929 = cute.add_offset(%ptr_924, %idx_926) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %3411 = builtin.unrealized_conversion_cast %ptr_929 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %3412 = builtin.unrealized_conversion_cast %ptr_928 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3413 = llvm.load %3411 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3413, %3412 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3414 = arith.addi %3409, %c1_i32 : i32
      cf.br ^bb716(%3414 : i32)
    ^bb718:  // pred: ^bb716
      %view_930 = cute.make_view(%ptr_923) : !memref_rmem_i8_1
      %3415 = cute.memref.load_vec %view_930 : !memref_rmem_i8_1
      %3416 = vector.extract_strided_slice %3415 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3417 = llvm.bitcast %3416 : vector<4xi8> to i32
      %3418 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3417, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3419 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3417, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3420 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3417, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3421 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3417, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3422 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3418 : (i32) -> f32
      %3423 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3419 : (i32) -> f32
      %3424 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3420 : (i32) -> f32
      %3425 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3421 : (i32) -> f32
      %3426 = vector.from_elements %3422, %3423, %3424, %3425 : vector<4xf32>
      %3427 = vector.extract_strided_slice %3426 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3428 = vector.extract_strided_slice %3426 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3429 = vector.extractelement %3427[%c0_i32 : i32] : vector<2xf32>
      %3430 = vector.extractelement %3427[%c1_i32 : i32] : vector<2xf32>
      %3431 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3430, %3429 : (f32, f32) -> i32
      %3432 = llvm.bitcast %3431 : i32 to vector<2xbf16>
      %3433 = vector.extractelement %3428[%c0_i32 : i32] : vector<2xf32>
      %3434 = vector.extractelement %3428[%c1_i32 : i32] : vector<2xf32>
      %3435 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3434, %3433 : (f32, f32) -> i32
      %3436 = llvm.bitcast %3435 : i32 to vector<2xbf16>
      %3437 = vector.insert_strided_slice %3432, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3438 = vector.insert_strided_slice %3436, %3437 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3439 = vector.extract_strided_slice %3415 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3440 = llvm.bitcast %3439 : vector<4xi8> to i32
      %3441 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3440, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3442 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3440, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3443 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3440, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3444 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3440, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3445 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3441 : (i32) -> f32
      %3446 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3442 : (i32) -> f32
      %3447 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3443 : (i32) -> f32
      %3448 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3444 : (i32) -> f32
      %3449 = vector.from_elements %3445, %3446, %3447, %3448 : vector<4xf32>
      %3450 = vector.extract_strided_slice %3449 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3451 = vector.extract_strided_slice %3449 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3452 = vector.extractelement %3450[%c0_i32 : i32] : vector<2xf32>
      %3453 = vector.extractelement %3450[%c1_i32 : i32] : vector<2xf32>
      %3454 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3453, %3452 : (f32, f32) -> i32
      %3455 = llvm.bitcast %3454 : i32 to vector<2xbf16>
      %3456 = vector.extractelement %3451[%c0_i32 : i32] : vector<2xf32>
      %3457 = vector.extractelement %3451[%c1_i32 : i32] : vector<2xf32>
      %3458 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3457, %3456 : (f32, f32) -> i32
      %3459 = llvm.bitcast %3458 : i32 to vector<2xbf16>
      %3460 = vector.insert_strided_slice %3455, %3438 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3461 = vector.insert_strided_slice %3459, %3460 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3462 = vector.extract_strided_slice %3415 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3463 = llvm.bitcast %3462 : vector<4xi8> to i32
      %3464 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3463, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3465 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3463, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3466 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3463, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3467 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3463, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3468 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3464 : (i32) -> f32
      %3469 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3465 : (i32) -> f32
      %3470 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3466 : (i32) -> f32
      %3471 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3467 : (i32) -> f32
      %3472 = vector.from_elements %3468, %3469, %3470, %3471 : vector<4xf32>
      %3473 = vector.extract_strided_slice %3472 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3474 = vector.extract_strided_slice %3472 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3475 = vector.extractelement %3473[%c0_i32 : i32] : vector<2xf32>
      %3476 = vector.extractelement %3473[%c1_i32 : i32] : vector<2xf32>
      %3477 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3476, %3475 : (f32, f32) -> i32
      %3478 = llvm.bitcast %3477 : i32 to vector<2xbf16>
      %3479 = vector.extractelement %3474[%c0_i32 : i32] : vector<2xf32>
      %3480 = vector.extractelement %3474[%c1_i32 : i32] : vector<2xf32>
      %3481 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3480, %3479 : (f32, f32) -> i32
      %3482 = llvm.bitcast %3481 : i32 to vector<2xbf16>
      %3483 = vector.insert_strided_slice %3478, %3461 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3484 = vector.insert_strided_slice %3482, %3483 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3485 = vector.extract_strided_slice %3415 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3486 = llvm.bitcast %3485 : vector<4xi8> to i32
      %3487 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3486, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3488 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3486, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3489 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3486, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3490 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3486, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3491 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3487 : (i32) -> f32
      %3492 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3488 : (i32) -> f32
      %3493 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3489 : (i32) -> f32
      %3494 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3490 : (i32) -> f32
      %3495 = vector.from_elements %3491, %3492, %3493, %3494 : vector<4xf32>
      %3496 = vector.extract_strided_slice %3495 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3497 = vector.extract_strided_slice %3495 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3498 = vector.extractelement %3496[%c0_i32 : i32] : vector<2xf32>
      %3499 = vector.extractelement %3496[%c1_i32 : i32] : vector<2xf32>
      %3500 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3499, %3498 : (f32, f32) -> i32
      %3501 = llvm.bitcast %3500 : i32 to vector<2xbf16>
      %3502 = vector.extractelement %3497[%c0_i32 : i32] : vector<2xf32>
      %3503 = vector.extractelement %3497[%c1_i32 : i32] : vector<2xf32>
      %3504 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3503, %3502 : (f32, f32) -> i32
      %3505 = llvm.bitcast %3504 : i32 to vector<2xbf16>
      %3506 = vector.insert_strided_slice %3501, %3484 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3507 = vector.insert_strided_slice %3505, %3506 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3508 = vector.extract_strided_slice %3415 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3509 = llvm.bitcast %3508 : vector<4xi8> to i32
      %3510 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3509, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3511 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3509, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3512 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3509, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3513 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3509, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3514 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3510 : (i32) -> f32
      %3515 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3511 : (i32) -> f32
      %3516 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3512 : (i32) -> f32
      %3517 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3513 : (i32) -> f32
      %3518 = vector.from_elements %3514, %3515, %3516, %3517 : vector<4xf32>
      %3519 = vector.extract_strided_slice %3518 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3520 = vector.extract_strided_slice %3518 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3521 = vector.extractelement %3519[%c0_i32 : i32] : vector<2xf32>
      %3522 = vector.extractelement %3519[%c1_i32 : i32] : vector<2xf32>
      %3523 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3522, %3521 : (f32, f32) -> i32
      %3524 = llvm.bitcast %3523 : i32 to vector<2xbf16>
      %3525 = vector.extractelement %3520[%c0_i32 : i32] : vector<2xf32>
      %3526 = vector.extractelement %3520[%c1_i32 : i32] : vector<2xf32>
      %3527 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3526, %3525 : (f32, f32) -> i32
      %3528 = llvm.bitcast %3527 : i32 to vector<2xbf16>
      %3529 = vector.insert_strided_slice %3524, %3507 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3530 = vector.insert_strided_slice %3528, %3529 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3531 = vector.extract_strided_slice %3415 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3532 = llvm.bitcast %3531 : vector<4xi8> to i32
      %3533 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3532, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3534 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3532, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3535 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3532, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3536 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3532, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3537 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3533 : (i32) -> f32
      %3538 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3534 : (i32) -> f32
      %3539 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3535 : (i32) -> f32
      %3540 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3536 : (i32) -> f32
      %3541 = vector.from_elements %3537, %3538, %3539, %3540 : vector<4xf32>
      %3542 = vector.extract_strided_slice %3541 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3543 = vector.extract_strided_slice %3541 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3544 = vector.extractelement %3542[%c0_i32 : i32] : vector<2xf32>
      %3545 = vector.extractelement %3542[%c1_i32 : i32] : vector<2xf32>
      %3546 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3545, %3544 : (f32, f32) -> i32
      %3547 = llvm.bitcast %3546 : i32 to vector<2xbf16>
      %3548 = vector.extractelement %3543[%c0_i32 : i32] : vector<2xf32>
      %3549 = vector.extractelement %3543[%c1_i32 : i32] : vector<2xf32>
      %3550 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3549, %3548 : (f32, f32) -> i32
      %3551 = llvm.bitcast %3550 : i32 to vector<2xbf16>
      %3552 = vector.insert_strided_slice %3547, %3530 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3553 = vector.insert_strided_slice %3551, %3552 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3554 = vector.extract_strided_slice %3415 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3555 = llvm.bitcast %3554 : vector<4xi8> to i32
      %3556 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3555, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3557 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3555, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3558 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3555, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3559 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3555, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3560 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3556 : (i32) -> f32
      %3561 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3557 : (i32) -> f32
      %3562 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3558 : (i32) -> f32
      %3563 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3559 : (i32) -> f32
      %3564 = vector.from_elements %3560, %3561, %3562, %3563 : vector<4xf32>
      %3565 = vector.extract_strided_slice %3564 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3566 = vector.extract_strided_slice %3564 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3567 = vector.extractelement %3565[%c0_i32 : i32] : vector<2xf32>
      %3568 = vector.extractelement %3565[%c1_i32 : i32] : vector<2xf32>
      %3569 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3568, %3567 : (f32, f32) -> i32
      %3570 = llvm.bitcast %3569 : i32 to vector<2xbf16>
      %3571 = vector.extractelement %3566[%c0_i32 : i32] : vector<2xf32>
      %3572 = vector.extractelement %3566[%c1_i32 : i32] : vector<2xf32>
      %3573 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3572, %3571 : (f32, f32) -> i32
      %3574 = llvm.bitcast %3573 : i32 to vector<2xbf16>
      %3575 = vector.insert_strided_slice %3570, %3553 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3576 = vector.insert_strided_slice %3574, %3575 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3577 = vector.extract_strided_slice %3415 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3578 = llvm.bitcast %3577 : vector<4xi8> to i32
      %3579 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3578, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3580 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3578, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3581 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3578, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3582 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3578, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3583 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3579 : (i32) -> f32
      %3584 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3580 : (i32) -> f32
      %3585 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3581 : (i32) -> f32
      %3586 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3582 : (i32) -> f32
      %3587 = vector.from_elements %3583, %3584, %3585, %3586 : vector<4xf32>
      %3588 = vector.extract_strided_slice %3587 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3589 = vector.extract_strided_slice %3587 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3590 = vector.extractelement %3588[%c0_i32 : i32] : vector<2xf32>
      %3591 = vector.extractelement %3588[%c1_i32 : i32] : vector<2xf32>
      %3592 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3591, %3590 : (f32, f32) -> i32
      %3593 = llvm.bitcast %3592 : i32 to vector<2xbf16>
      %3594 = vector.extractelement %3589[%c0_i32 : i32] : vector<2xf32>
      %3595 = vector.extractelement %3589[%c1_i32 : i32] : vector<2xf32>
      %3596 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3595, %3594 : (f32, f32) -> i32
      %3597 = llvm.bitcast %3596 : i32 to vector<2xbf16>
      %3598 = vector.insert_strided_slice %3593, %3576 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3599 = vector.insert_strided_slice %3597, %3598 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3600 = cute.memref.load_vec %view_899 : !memref_rmem_bf16_4
      %3601 = arith.mulf %3599, %3600 : vector<32xbf16>
      %ptr_931 = cute.add_offset(%iter_900, %idx_922) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_932 = cute.make_view(%ptr_931) : !memref_rmem_bf16_5
      cute.memref.store_vec %3601, %view_932 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_933 = cute.add_offset(%ptr_50, %int_tuple_917) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3602 = builtin.unrealized_conversion_cast %ptr_933 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3602, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_934 = cute.add_offset(%iter_92, %int_tuple_903) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3603 = builtin.unrealized_conversion_cast %ptr_934 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3604 = nvvm.mapa.shared.cluster %3603, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3604, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %3605 = arith.addi %3378, %c1_i32 : i32
      cf.br ^bb703(%3605, %3388, %3390, %3392, %3403, %3405, %3407 : i32, i32, i32, i32, i32, i32, i32)
    ^bb719:  // pred: ^bb703
      %int_tuple_935 = cute.make_int_tuple(%3380) : (i32) -> !cute.int_tuple<"?">
      %ptr_936 = cute.add_offset(%ptr_95, %int_tuple_935) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3606 = builtin.unrealized_conversion_cast %ptr_936 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3606, %3381, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3607 = arith.addi %3380, %c1_i32 : i32
      %3608 = arith.addi %3379, %c1_i32 : i32
      %3609 = arith.cmpi eq, %3607, %c3_i32 : i32
      %3610 = arith.select %3609, %c0_i32, %3607 : i32
      cf.cond_br %3609, ^bb720, ^bb721
    ^bb720:  // pred: ^bb719
      %3611 = arith.xori %3381, %c1_i32 : i32
      cf.br ^bb722(%3611 : i32)
    ^bb721:  // pred: ^bb719
      cf.br ^bb722(%3381 : i32)
    ^bb722(%3612: i32):  // 2 preds: ^bb720, ^bb721
      cf.br ^bb723
    ^bb723:  // pred: ^bb722
      %ptr_937 = cute.add_offset(%iter_900, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_938 = cute.make_coord(%3380) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_939 = cute.crd2idx(%coord_938, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb724(%c0_i32 : i32)
    ^bb724(%3613: i32):  // 2 preds: ^bb723, ^bb725
      %3614 = arith.cmpi slt, %3613, %2616 : i32
      cf.cond_br %3614, ^bb725, ^bb726 {llvm.loop_annotation = #loop_annotation}
    ^bb725:  // pred: ^bb724
      %coord_940 = cute.make_coord(%3613) : (i32) -> !cute.coord<"(_,?)">
      %idx_941 = cute.crd2idx(%coord_940, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_942 = cute.add_offset(%ptr_937, %idx_941) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_943 = cute.crd2idx(%coord_940, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_944 = cute.add_offset(%ptr_778, %idx_943) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_945 = cute.apply_swizzle(%ptr_944) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_946 = cute.add_offset(%swizzled_945, %idx_939) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3615 = builtin.unrealized_conversion_cast %ptr_942 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3616 = builtin.unrealized_conversion_cast %ptr_946 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3617 = llvm.load %3615 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3617, %3616 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3618 = arith.addi %3613, %c1_i32 : i32
      cf.br ^bb724(%3618 : i32)
    ^bb726:  // pred: ^bb724
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_947 = cute.add_offset(%iter_92, %int_tuple_935) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3619 = builtin.unrealized_conversion_cast %ptr_947 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3620 = nvvm.mapa.shared.cluster %3619, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3620, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_948 = cute.add_offset(%ptr_65, %int_tuple_876) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3621 = builtin.unrealized_conversion_cast %ptr_948 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3621, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %3622 = cute.make_tiled_copy(%atom_773) : !copy_simt2
      %rmem_949 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_950 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_951 = cute.memref.alloca() : !memref_rmem_bf16_6
      %int_tuple_952 = cute.make_int_tuple(%3145) : (i32) -> !cute.int_tuple<"?">
      %ptr_953 = cute.add_offset(%iter_76, %int_tuple_952) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3623 = builtin.unrealized_conversion_cast %ptr_953 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3623, %3146, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3624 = arith.addi %3145, %c1_i32 : i32
      %3625 = arith.addi %3144, %c1_i32 : i32
      %3626 = arith.cmpi eq, %3624, %c5_i32 : i32
      %3627 = arith.select %3626, %c0_i32, %3624 : i32
      cf.cond_br %3626, ^bb727, ^bb728
    ^bb727:  // pred: ^bb726
      %3628 = arith.xori %3146, %c1_i32 : i32
      cf.br ^bb729(%3628 : i32)
    ^bb728:  // pred: ^bb726
      cf.br ^bb729(%3146 : i32)
    ^bb729(%3629: i32):  // 2 preds: ^bb727, ^bb728
      cf.br ^bb730
    ^bb730:  // pred: ^bb729
      %coord_954 = cute.make_coord(%3145) : (i32) -> !cute.coord<"(_,_,_,_,_,(_,?))">
      %idx_955 = cute.crd2idx(%coord_954, %3) : (!cute.coord<"(_,_,_,_,_,(_,?))">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),(4,5)):((0,0),0,0,0,(0,(0,1)),(64,256))">) -> !cute.int_tuple<"?{div=256}">
      %iter_956 = cute.get_iter(%rmem_951) : !memref_rmem_bf16_6
      cf.br ^bb731(%c0_i32 : i32)
    ^bb731(%3630: i32):  // 2 preds: ^bb730, ^bb732
      %3631 = arith.cmpi slt, %3630, %2625 : i32
      cf.cond_br %3631, ^bb732, ^bb733 {llvm.loop_annotation = #loop_annotation}
    ^bb732:  // pred: ^bb731
      %coord_957 = cute.make_coord(%3630) : (i32) -> !cute.coord<"(_,?)">
      %idx_958 = cute.crd2idx(%coord_957, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,1)),64))">) -> !cute.int_tuple<"?">
      %ptr_959 = cute.add_offset(%ptr_790, %idx_958) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_960 = cute.add_offset(%ptr_959, %idx_955) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, smem>
      %idx_961 = cute.crd2idx(%coord_957, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,0)),1))">) -> !cute.int_tuple<"?">
      %ptr_962 = cute.add_offset(%iter_956, %idx_961) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %3632 = builtin.unrealized_conversion_cast %ptr_960 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %3633 = builtin.unrealized_conversion_cast %ptr_962 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %3634 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3634, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3635 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3635, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3636 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3636, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3637 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3637, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3638 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3638, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3639 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3639, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3640 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3640, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3641 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3641, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3642 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3642, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3643 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3643, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3644 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3644, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3645 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3645, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3646 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3646, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3647 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3647, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3648 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3648, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3649 = llvm.load %3632 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3649, %3633 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3650 = arith.addi %3630, %c1_i32 : i32
      cf.br ^bb731(%3650 : i32)
    ^bb733:  // pred: ^bb731
      %int_tuple_963 = cute.make_int_tuple(%3383) : (i32) -> !cute.int_tuple<"?">
      %ptr_964 = cute.add_offset(%iter_45, %int_tuple_963) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3651 = builtin.unrealized_conversion_cast %ptr_964 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3651, %3384, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3652 = arith.addi %3383, %c1_i32 : i32
      %3653 = arith.addi %3382, %c1_i32 : i32
      %3654 = arith.cmpi eq, %3652, %c5_i32 : i32
      %3655 = arith.select %3654, %c0_i32, %3652 : i32
      cf.cond_br %3654, ^bb734, ^bb735
    ^bb734:  // pred: ^bb733
      %3656 = arith.xori %3384, %c1_i32 : i32
      cf.br ^bb736(%3656 : i32)
    ^bb735:  // pred: ^bb733
      cf.br ^bb736(%3384 : i32)
    ^bb736(%3657: i32):  // 2 preds: ^bb734, ^bb735
      cf.br ^bb737
    ^bb737:  // pred: ^bb736
      %coord_965 = cute.make_coord(%3383) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_966 = cute.crd2idx(%coord_965, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_967 = cute.add_offset(%ptr_787, %idx_966) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %iter_968 = cute.get_iter(%rmem_949) : !memref_rmem_i8_
      cf.br ^bb738(%c0_i32 : i32)
    ^bb738(%3658: i32):  // 2 preds: ^bb737, ^bb739
      %3659 = arith.cmpi slt, %3658, %2614 : i32
      cf.cond_br %3659, ^bb739, ^bb740 {llvm.loop_annotation = #loop_annotation}
    ^bb739:  // pred: ^bb738
      %coord_969 = cute.make_coord(%3658) : (i32) -> !cute.coord<"(_,?)">
      %idx_970 = cute.crd2idx(%coord_969, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_971 = cute.add_offset(%ptr_967, %idx_970) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_972 = cute.crd2idx(%coord_969, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_973 = cute.add_offset(%iter_968, %idx_972) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %3660 = builtin.unrealized_conversion_cast %ptr_971 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %3661 = builtin.unrealized_conversion_cast %ptr_973 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3662 = llvm.load %3660 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3662, %3661 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3663 = arith.addi %3658, %c1_i32 : i32
      cf.br ^bb738(%3663 : i32)
    ^bb740:  // pred: ^bb738
      %view_974 = cute.make_view(%iter_968) : !memref_rmem_i8_1
      %3664 = cute.memref.load_vec %view_974 : !memref_rmem_i8_1
      %3665 = vector.extract_strided_slice %3664 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3666 = llvm.bitcast %3665 : vector<4xi8> to i32
      %3667 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3666, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3668 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3666, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3669 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3666, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3670 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3666, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3671 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3667 : (i32) -> f32
      %3672 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3668 : (i32) -> f32
      %3673 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3669 : (i32) -> f32
      %3674 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3670 : (i32) -> f32
      %3675 = vector.from_elements %3671, %3672, %3673, %3674 : vector<4xf32>
      %3676 = vector.extract_strided_slice %3675 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3677 = vector.extract_strided_slice %3675 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3678 = vector.extractelement %3676[%c0_i32 : i32] : vector<2xf32>
      %3679 = vector.extractelement %3676[%c1_i32 : i32] : vector<2xf32>
      %3680 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3679, %3678 : (f32, f32) -> i32
      %3681 = llvm.bitcast %3680 : i32 to vector<2xbf16>
      %3682 = vector.extractelement %3677[%c0_i32 : i32] : vector<2xf32>
      %3683 = vector.extractelement %3677[%c1_i32 : i32] : vector<2xf32>
      %3684 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3683, %3682 : (f32, f32) -> i32
      %3685 = llvm.bitcast %3684 : i32 to vector<2xbf16>
      %3686 = vector.insert_strided_slice %3681, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3687 = vector.insert_strided_slice %3685, %3686 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3688 = vector.extract_strided_slice %3664 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3689 = llvm.bitcast %3688 : vector<4xi8> to i32
      %3690 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3689, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3691 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3689, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3692 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3689, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3693 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3689, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3694 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3690 : (i32) -> f32
      %3695 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3691 : (i32) -> f32
      %3696 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3692 : (i32) -> f32
      %3697 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3693 : (i32) -> f32
      %3698 = vector.from_elements %3694, %3695, %3696, %3697 : vector<4xf32>
      %3699 = vector.extract_strided_slice %3698 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3700 = vector.extract_strided_slice %3698 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3701 = vector.extractelement %3699[%c0_i32 : i32] : vector<2xf32>
      %3702 = vector.extractelement %3699[%c1_i32 : i32] : vector<2xf32>
      %3703 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3702, %3701 : (f32, f32) -> i32
      %3704 = llvm.bitcast %3703 : i32 to vector<2xbf16>
      %3705 = vector.extractelement %3700[%c0_i32 : i32] : vector<2xf32>
      %3706 = vector.extractelement %3700[%c1_i32 : i32] : vector<2xf32>
      %3707 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3706, %3705 : (f32, f32) -> i32
      %3708 = llvm.bitcast %3707 : i32 to vector<2xbf16>
      %3709 = vector.insert_strided_slice %3704, %3687 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3710 = vector.insert_strided_slice %3708, %3709 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3711 = vector.extract_strided_slice %3664 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3712 = llvm.bitcast %3711 : vector<4xi8> to i32
      %3713 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3712, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3714 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3712, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3715 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3712, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3716 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3712, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3717 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3713 : (i32) -> f32
      %3718 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3714 : (i32) -> f32
      %3719 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3715 : (i32) -> f32
      %3720 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3716 : (i32) -> f32
      %3721 = vector.from_elements %3717, %3718, %3719, %3720 : vector<4xf32>
      %3722 = vector.extract_strided_slice %3721 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3723 = vector.extract_strided_slice %3721 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3724 = vector.extractelement %3722[%c0_i32 : i32] : vector<2xf32>
      %3725 = vector.extractelement %3722[%c1_i32 : i32] : vector<2xf32>
      %3726 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3725, %3724 : (f32, f32) -> i32
      %3727 = llvm.bitcast %3726 : i32 to vector<2xbf16>
      %3728 = vector.extractelement %3723[%c0_i32 : i32] : vector<2xf32>
      %3729 = vector.extractelement %3723[%c1_i32 : i32] : vector<2xf32>
      %3730 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3729, %3728 : (f32, f32) -> i32
      %3731 = llvm.bitcast %3730 : i32 to vector<2xbf16>
      %3732 = vector.insert_strided_slice %3727, %3710 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3733 = vector.insert_strided_slice %3731, %3732 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3734 = vector.extract_strided_slice %3664 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3735 = llvm.bitcast %3734 : vector<4xi8> to i32
      %3736 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3735, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3737 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3735, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3738 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3735, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3739 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3735, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3740 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3736 : (i32) -> f32
      %3741 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3737 : (i32) -> f32
      %3742 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3738 : (i32) -> f32
      %3743 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3739 : (i32) -> f32
      %3744 = vector.from_elements %3740, %3741, %3742, %3743 : vector<4xf32>
      %3745 = vector.extract_strided_slice %3744 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3746 = vector.extract_strided_slice %3744 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3747 = vector.extractelement %3745[%c0_i32 : i32] : vector<2xf32>
      %3748 = vector.extractelement %3745[%c1_i32 : i32] : vector<2xf32>
      %3749 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3748, %3747 : (f32, f32) -> i32
      %3750 = llvm.bitcast %3749 : i32 to vector<2xbf16>
      %3751 = vector.extractelement %3746[%c0_i32 : i32] : vector<2xf32>
      %3752 = vector.extractelement %3746[%c1_i32 : i32] : vector<2xf32>
      %3753 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3752, %3751 : (f32, f32) -> i32
      %3754 = llvm.bitcast %3753 : i32 to vector<2xbf16>
      %3755 = vector.insert_strided_slice %3750, %3733 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3756 = vector.insert_strided_slice %3754, %3755 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3757 = vector.extract_strided_slice %3664 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3758 = llvm.bitcast %3757 : vector<4xi8> to i32
      %3759 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3758, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3760 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3758, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3761 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3758, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3762 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3758, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3763 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3759 : (i32) -> f32
      %3764 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3760 : (i32) -> f32
      %3765 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3761 : (i32) -> f32
      %3766 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3762 : (i32) -> f32
      %3767 = vector.from_elements %3763, %3764, %3765, %3766 : vector<4xf32>
      %3768 = vector.extract_strided_slice %3767 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3769 = vector.extract_strided_slice %3767 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3770 = vector.extractelement %3768[%c0_i32 : i32] : vector<2xf32>
      %3771 = vector.extractelement %3768[%c1_i32 : i32] : vector<2xf32>
      %3772 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3771, %3770 : (f32, f32) -> i32
      %3773 = llvm.bitcast %3772 : i32 to vector<2xbf16>
      %3774 = vector.extractelement %3769[%c0_i32 : i32] : vector<2xf32>
      %3775 = vector.extractelement %3769[%c1_i32 : i32] : vector<2xf32>
      %3776 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3775, %3774 : (f32, f32) -> i32
      %3777 = llvm.bitcast %3776 : i32 to vector<2xbf16>
      %3778 = vector.insert_strided_slice %3773, %3756 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3779 = vector.insert_strided_slice %3777, %3778 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3780 = vector.extract_strided_slice %3664 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3781 = llvm.bitcast %3780 : vector<4xi8> to i32
      %3782 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3781, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3783 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3781, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3784 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3781, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3785 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3781, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3786 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3782 : (i32) -> f32
      %3787 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3783 : (i32) -> f32
      %3788 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3784 : (i32) -> f32
      %3789 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3785 : (i32) -> f32
      %3790 = vector.from_elements %3786, %3787, %3788, %3789 : vector<4xf32>
      %3791 = vector.extract_strided_slice %3790 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3792 = vector.extract_strided_slice %3790 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3793 = vector.extractelement %3791[%c0_i32 : i32] : vector<2xf32>
      %3794 = vector.extractelement %3791[%c1_i32 : i32] : vector<2xf32>
      %3795 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3794, %3793 : (f32, f32) -> i32
      %3796 = llvm.bitcast %3795 : i32 to vector<2xbf16>
      %3797 = vector.extractelement %3792[%c0_i32 : i32] : vector<2xf32>
      %3798 = vector.extractelement %3792[%c1_i32 : i32] : vector<2xf32>
      %3799 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3798, %3797 : (f32, f32) -> i32
      %3800 = llvm.bitcast %3799 : i32 to vector<2xbf16>
      %3801 = vector.insert_strided_slice %3796, %3779 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3802 = vector.insert_strided_slice %3800, %3801 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3803 = vector.extract_strided_slice %3664 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3804 = llvm.bitcast %3803 : vector<4xi8> to i32
      %3805 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3804, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3806 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3804, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3807 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3804, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3808 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3804, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3809 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3805 : (i32) -> f32
      %3810 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3806 : (i32) -> f32
      %3811 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3807 : (i32) -> f32
      %3812 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3808 : (i32) -> f32
      %3813 = vector.from_elements %3809, %3810, %3811, %3812 : vector<4xf32>
      %3814 = vector.extract_strided_slice %3813 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3815 = vector.extract_strided_slice %3813 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3816 = vector.extractelement %3814[%c0_i32 : i32] : vector<2xf32>
      %3817 = vector.extractelement %3814[%c1_i32 : i32] : vector<2xf32>
      %3818 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3817, %3816 : (f32, f32) -> i32
      %3819 = llvm.bitcast %3818 : i32 to vector<2xbf16>
      %3820 = vector.extractelement %3815[%c0_i32 : i32] : vector<2xf32>
      %3821 = vector.extractelement %3815[%c1_i32 : i32] : vector<2xf32>
      %3822 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3821, %3820 : (f32, f32) -> i32
      %3823 = llvm.bitcast %3822 : i32 to vector<2xbf16>
      %3824 = vector.insert_strided_slice %3819, %3802 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3825 = vector.insert_strided_slice %3823, %3824 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3826 = vector.extract_strided_slice %3664 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3827 = llvm.bitcast %3826 : vector<4xi8> to i32
      %3828 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3827, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3829 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3827, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3830 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3827, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3831 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3827, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3832 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3828 : (i32) -> f32
      %3833 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3829 : (i32) -> f32
      %3834 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3830 : (i32) -> f32
      %3835 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3831 : (i32) -> f32
      %3836 = vector.from_elements %3832, %3833, %3834, %3835 : vector<4xf32>
      %3837 = vector.extract_strided_slice %3836 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3838 = vector.extract_strided_slice %3836 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3839 = vector.extractelement %3837[%c0_i32 : i32] : vector<2xf32>
      %3840 = vector.extractelement %3837[%c1_i32 : i32] : vector<2xf32>
      %3841 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3840, %3839 : (f32, f32) -> i32
      %3842 = llvm.bitcast %3841 : i32 to vector<2xbf16>
      %3843 = vector.extractelement %3838[%c0_i32 : i32] : vector<2xf32>
      %3844 = vector.extractelement %3838[%c1_i32 : i32] : vector<2xf32>
      %3845 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3844, %3843 : (f32, f32) -> i32
      %3846 = llvm.bitcast %3845 : i32 to vector<2xbf16>
      %3847 = vector.insert_strided_slice %3842, %3825 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3848 = vector.insert_strided_slice %3846, %3847 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_975 = cute.make_view(%iter_956) : !memref_rmem_bf16_7
      %3849 = cute.memref.load_vec %view_975 : !memref_rmem_bf16_7
      %3850 = arith.mulf %3848, %3849 : vector<32xbf16>
      %iter_976 = cute.get_iter(%rmem_950) : !memref_rmem_bf16_2
      %view_977 = cute.make_view(%iter_976) : !memref_rmem_bf16_5
      cute.memref.store_vec %3850, %view_977 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_978 = cute.add_offset(%ptr_50, %int_tuple_963) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3851 = builtin.unrealized_conversion_cast %ptr_978 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3851, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb741(%c1_i32, %3608, %3610, %3612, %3653, %3655, %3657 : i32, i32, i32, i32, i32, i32, i32)
    ^bb741(%3852: i32, %3853: i32, %3854: i32, %3855: i32, %3856: i32, %3857: i32, %3858: i32):  // 2 preds: ^bb740, ^bb756
      %3859 = arith.cmpi slt, %3852, %c8_i32 : i32
      cf.cond_br %3859, ^bb742, ^bb757 {loop_annotation = #loop_annotation1}
    ^bb742:  // pred: ^bb741
      %int_tuple_979 = cute.make_int_tuple(%3854) : (i32) -> !cute.int_tuple<"?">
      %ptr_980 = cute.add_offset(%ptr_95, %int_tuple_979) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3860 = builtin.unrealized_conversion_cast %ptr_980 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3860, %3855, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3861 = arith.addi %3854, %c1_i32 : i32
      %3862 = arith.addi %3853, %c1_i32 : i32
      %3863 = arith.cmpi eq, %3861, %c3_i32 : i32
      %3864 = arith.select %3863, %c0_i32, %3861 : i32
      cf.cond_br %3863, ^bb743, ^bb744
    ^bb743:  // pred: ^bb742
      %3865 = arith.xori %3855, %c1_i32 : i32
      cf.br ^bb745(%3865 : i32)
    ^bb744:  // pred: ^bb742
      cf.br ^bb745(%3855 : i32)
    ^bb745(%3866: i32):  // 2 preds: ^bb743, ^bb744
      cf.br ^bb746
    ^bb746:  // pred: ^bb745
      %3867 = arith.subi %3852, %c1_i32 : i32
      %3868 = arith.remsi %3867, %c2_i32 : i32
      %coord_981 = cute.make_coord(%3868) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_982 = cute.crd2idx(%coord_981, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_983 = cute.add_offset(%iter_976, %idx_982) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_984 = cute.make_coord(%3854) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_985 = cute.crd2idx(%coord_984, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb747(%c0_i32 : i32)
    ^bb747(%3869: i32):  // 2 preds: ^bb746, ^bb748
      %3870 = arith.cmpi slt, %3869, %2616 : i32
      cf.cond_br %3870, ^bb748, ^bb749 {llvm.loop_annotation = #loop_annotation}
    ^bb748:  // pred: ^bb747
      %coord_986 = cute.make_coord(%3869) : (i32) -> !cute.coord<"(_,?)">
      %idx_987 = cute.crd2idx(%coord_986, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_988 = cute.add_offset(%ptr_983, %idx_987) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_989 = cute.crd2idx(%coord_986, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_990 = cute.add_offset(%ptr_788, %idx_989) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_991 = cute.apply_swizzle(%ptr_990) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_992 = cute.add_offset(%swizzled_991, %idx_985) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3871 = builtin.unrealized_conversion_cast %ptr_988 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3872 = builtin.unrealized_conversion_cast %ptr_992 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3873 = llvm.load %3871 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3873, %3872 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3874 = arith.addi %3869, %c1_i32 : i32
      cf.br ^bb747(%3874 : i32)
    ^bb749:  // pred: ^bb747
      %int_tuple_993 = cute.make_int_tuple(%3857) : (i32) -> !cute.int_tuple<"?">
      %ptr_994 = cute.add_offset(%iter_45, %int_tuple_993) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3875 = builtin.unrealized_conversion_cast %ptr_994 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3875, %3858, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3876 = arith.addi %3857, %c1_i32 : i32
      %3877 = arith.addi %3856, %c1_i32 : i32
      %3878 = arith.cmpi eq, %3876, %c5_i32 : i32
      %3879 = arith.select %3878, %c0_i32, %3876 : i32
      cf.cond_br %3878, ^bb750, ^bb751
    ^bb750:  // pred: ^bb749
      %3880 = arith.xori %3858, %c1_i32 : i32
      cf.br ^bb752(%3880 : i32)
    ^bb751:  // pred: ^bb749
      cf.br ^bb752(%3858 : i32)
    ^bb752(%3881: i32):  // 2 preds: ^bb750, ^bb751
      cf.br ^bb753
    ^bb753:  // pred: ^bb752
      %coord_995 = cute.make_coord(%3857) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_996 = cute.crd2idx(%coord_995, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_997 = cute.add_offset(%ptr_787, %idx_996) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %3882 = arith.remsi %3852, %c2_i32 : i32
      %coord_998 = cute.make_coord(%3882) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_999 = cute.crd2idx(%coord_998, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1000 = cute.add_offset(%iter_968, %idx_999) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      cf.br ^bb754(%c0_i32 : i32)
    ^bb754(%3883: i32):  // 2 preds: ^bb753, ^bb755
      %3884 = arith.cmpi slt, %3883, %2614 : i32
      cf.cond_br %3884, ^bb755, ^bb756 {llvm.loop_annotation = #loop_annotation}
    ^bb755:  // pred: ^bb754
      %coord_1001 = cute.make_coord(%3883) : (i32) -> !cute.coord<"(_,?)">
      %idx_1002 = cute.crd2idx(%coord_1001, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1003 = cute.add_offset(%ptr_997, %idx_1002) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1004 = cute.crd2idx(%coord_1001, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1005 = cute.add_offset(%ptr_1000, %idx_1004) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %3885 = builtin.unrealized_conversion_cast %ptr_1003 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %3886 = builtin.unrealized_conversion_cast %ptr_1005 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3887 = llvm.load %3885 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3887, %3886 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3888 = arith.addi %3883, %c1_i32 : i32
      cf.br ^bb754(%3888 : i32)
    ^bb756:  // pred: ^bb754
      %view_1006 = cute.make_view(%ptr_1000) : !memref_rmem_i8_1
      %3889 = cute.memref.load_vec %view_1006 : !memref_rmem_i8_1
      %3890 = vector.extract_strided_slice %3889 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3891 = llvm.bitcast %3890 : vector<4xi8> to i32
      %3892 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3891, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3893 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3891, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3894 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3891, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3895 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3891, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3896 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3892 : (i32) -> f32
      %3897 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3893 : (i32) -> f32
      %3898 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3894 : (i32) -> f32
      %3899 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3895 : (i32) -> f32
      %3900 = vector.from_elements %3896, %3897, %3898, %3899 : vector<4xf32>
      %3901 = vector.extract_strided_slice %3900 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3902 = vector.extract_strided_slice %3900 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3903 = vector.extractelement %3901[%c0_i32 : i32] : vector<2xf32>
      %3904 = vector.extractelement %3901[%c1_i32 : i32] : vector<2xf32>
      %3905 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3904, %3903 : (f32, f32) -> i32
      %3906 = llvm.bitcast %3905 : i32 to vector<2xbf16>
      %3907 = vector.extractelement %3902[%c0_i32 : i32] : vector<2xf32>
      %3908 = vector.extractelement %3902[%c1_i32 : i32] : vector<2xf32>
      %3909 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3908, %3907 : (f32, f32) -> i32
      %3910 = llvm.bitcast %3909 : i32 to vector<2xbf16>
      %3911 = vector.insert_strided_slice %3906, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3912 = vector.insert_strided_slice %3910, %3911 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3913 = vector.extract_strided_slice %3889 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3914 = llvm.bitcast %3913 : vector<4xi8> to i32
      %3915 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3914, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3916 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3914, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3917 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3914, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3918 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3914, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3919 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3915 : (i32) -> f32
      %3920 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3916 : (i32) -> f32
      %3921 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3917 : (i32) -> f32
      %3922 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3918 : (i32) -> f32
      %3923 = vector.from_elements %3919, %3920, %3921, %3922 : vector<4xf32>
      %3924 = vector.extract_strided_slice %3923 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3925 = vector.extract_strided_slice %3923 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3926 = vector.extractelement %3924[%c0_i32 : i32] : vector<2xf32>
      %3927 = vector.extractelement %3924[%c1_i32 : i32] : vector<2xf32>
      %3928 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3927, %3926 : (f32, f32) -> i32
      %3929 = llvm.bitcast %3928 : i32 to vector<2xbf16>
      %3930 = vector.extractelement %3925[%c0_i32 : i32] : vector<2xf32>
      %3931 = vector.extractelement %3925[%c1_i32 : i32] : vector<2xf32>
      %3932 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3931, %3930 : (f32, f32) -> i32
      %3933 = llvm.bitcast %3932 : i32 to vector<2xbf16>
      %3934 = vector.insert_strided_slice %3929, %3912 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3935 = vector.insert_strided_slice %3933, %3934 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3936 = vector.extract_strided_slice %3889 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3937 = llvm.bitcast %3936 : vector<4xi8> to i32
      %3938 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3937, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3939 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3937, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3940 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3937, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3941 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3937, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3942 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3938 : (i32) -> f32
      %3943 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3939 : (i32) -> f32
      %3944 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3940 : (i32) -> f32
      %3945 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3941 : (i32) -> f32
      %3946 = vector.from_elements %3942, %3943, %3944, %3945 : vector<4xf32>
      %3947 = vector.extract_strided_slice %3946 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3948 = vector.extract_strided_slice %3946 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3949 = vector.extractelement %3947[%c0_i32 : i32] : vector<2xf32>
      %3950 = vector.extractelement %3947[%c1_i32 : i32] : vector<2xf32>
      %3951 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3950, %3949 : (f32, f32) -> i32
      %3952 = llvm.bitcast %3951 : i32 to vector<2xbf16>
      %3953 = vector.extractelement %3948[%c0_i32 : i32] : vector<2xf32>
      %3954 = vector.extractelement %3948[%c1_i32 : i32] : vector<2xf32>
      %3955 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3954, %3953 : (f32, f32) -> i32
      %3956 = llvm.bitcast %3955 : i32 to vector<2xbf16>
      %3957 = vector.insert_strided_slice %3952, %3935 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3958 = vector.insert_strided_slice %3956, %3957 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3959 = vector.extract_strided_slice %3889 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3960 = llvm.bitcast %3959 : vector<4xi8> to i32
      %3961 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3960, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3962 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3960, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3963 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3960, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3964 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3960, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3965 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3961 : (i32) -> f32
      %3966 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3962 : (i32) -> f32
      %3967 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3963 : (i32) -> f32
      %3968 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3964 : (i32) -> f32
      %3969 = vector.from_elements %3965, %3966, %3967, %3968 : vector<4xf32>
      %3970 = vector.extract_strided_slice %3969 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3971 = vector.extract_strided_slice %3969 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3972 = vector.extractelement %3970[%c0_i32 : i32] : vector<2xf32>
      %3973 = vector.extractelement %3970[%c1_i32 : i32] : vector<2xf32>
      %3974 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3973, %3972 : (f32, f32) -> i32
      %3975 = llvm.bitcast %3974 : i32 to vector<2xbf16>
      %3976 = vector.extractelement %3971[%c0_i32 : i32] : vector<2xf32>
      %3977 = vector.extractelement %3971[%c1_i32 : i32] : vector<2xf32>
      %3978 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3977, %3976 : (f32, f32) -> i32
      %3979 = llvm.bitcast %3978 : i32 to vector<2xbf16>
      %3980 = vector.insert_strided_slice %3975, %3958 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3981 = vector.insert_strided_slice %3979, %3980 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3982 = vector.extract_strided_slice %3889 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3983 = llvm.bitcast %3982 : vector<4xi8> to i32
      %3984 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3983, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3985 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3983, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3986 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3983, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3987 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3983, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3988 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3984 : (i32) -> f32
      %3989 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3985 : (i32) -> f32
      %3990 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3986 : (i32) -> f32
      %3991 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3987 : (i32) -> f32
      %3992 = vector.from_elements %3988, %3989, %3990, %3991 : vector<4xf32>
      %3993 = vector.extract_strided_slice %3992 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3994 = vector.extract_strided_slice %3992 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3995 = vector.extractelement %3993[%c0_i32 : i32] : vector<2xf32>
      %3996 = vector.extractelement %3993[%c1_i32 : i32] : vector<2xf32>
      %3997 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3996, %3995 : (f32, f32) -> i32
      %3998 = llvm.bitcast %3997 : i32 to vector<2xbf16>
      %3999 = vector.extractelement %3994[%c0_i32 : i32] : vector<2xf32>
      %4000 = vector.extractelement %3994[%c1_i32 : i32] : vector<2xf32>
      %4001 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4000, %3999 : (f32, f32) -> i32
      %4002 = llvm.bitcast %4001 : i32 to vector<2xbf16>
      %4003 = vector.insert_strided_slice %3998, %3981 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4004 = vector.insert_strided_slice %4002, %4003 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4005 = vector.extract_strided_slice %3889 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4006 = llvm.bitcast %4005 : vector<4xi8> to i32
      %4007 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4006, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4008 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4006, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4009 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4006, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4010 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4006, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4011 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4007 : (i32) -> f32
      %4012 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4008 : (i32) -> f32
      %4013 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4009 : (i32) -> f32
      %4014 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4010 : (i32) -> f32
      %4015 = vector.from_elements %4011, %4012, %4013, %4014 : vector<4xf32>
      %4016 = vector.extract_strided_slice %4015 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4017 = vector.extract_strided_slice %4015 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4018 = vector.extractelement %4016[%c0_i32 : i32] : vector<2xf32>
      %4019 = vector.extractelement %4016[%c1_i32 : i32] : vector<2xf32>
      %4020 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4019, %4018 : (f32, f32) -> i32
      %4021 = llvm.bitcast %4020 : i32 to vector<2xbf16>
      %4022 = vector.extractelement %4017[%c0_i32 : i32] : vector<2xf32>
      %4023 = vector.extractelement %4017[%c1_i32 : i32] : vector<2xf32>
      %4024 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4023, %4022 : (f32, f32) -> i32
      %4025 = llvm.bitcast %4024 : i32 to vector<2xbf16>
      %4026 = vector.insert_strided_slice %4021, %4004 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4027 = vector.insert_strided_slice %4025, %4026 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4028 = vector.extract_strided_slice %3889 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4029 = llvm.bitcast %4028 : vector<4xi8> to i32
      %4030 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4029, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4031 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4029, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4032 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4029, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4033 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4029, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4034 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4030 : (i32) -> f32
      %4035 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4031 : (i32) -> f32
      %4036 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4032 : (i32) -> f32
      %4037 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4033 : (i32) -> f32
      %4038 = vector.from_elements %4034, %4035, %4036, %4037 : vector<4xf32>
      %4039 = vector.extract_strided_slice %4038 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4040 = vector.extract_strided_slice %4038 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4041 = vector.extractelement %4039[%c0_i32 : i32] : vector<2xf32>
      %4042 = vector.extractelement %4039[%c1_i32 : i32] : vector<2xf32>
      %4043 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4042, %4041 : (f32, f32) -> i32
      %4044 = llvm.bitcast %4043 : i32 to vector<2xbf16>
      %4045 = vector.extractelement %4040[%c0_i32 : i32] : vector<2xf32>
      %4046 = vector.extractelement %4040[%c1_i32 : i32] : vector<2xf32>
      %4047 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4046, %4045 : (f32, f32) -> i32
      %4048 = llvm.bitcast %4047 : i32 to vector<2xbf16>
      %4049 = vector.insert_strided_slice %4044, %4027 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4050 = vector.insert_strided_slice %4048, %4049 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4051 = vector.extract_strided_slice %3889 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4052 = llvm.bitcast %4051 : vector<4xi8> to i32
      %4053 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4052, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4054 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4052, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4055 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4052, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4056 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4052, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4057 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4053 : (i32) -> f32
      %4058 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4054 : (i32) -> f32
      %4059 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4055 : (i32) -> f32
      %4060 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4056 : (i32) -> f32
      %4061 = vector.from_elements %4057, %4058, %4059, %4060 : vector<4xf32>
      %4062 = vector.extract_strided_slice %4061 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4063 = vector.extract_strided_slice %4061 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4064 = vector.extractelement %4062[%c0_i32 : i32] : vector<2xf32>
      %4065 = vector.extractelement %4062[%c1_i32 : i32] : vector<2xf32>
      %4066 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4065, %4064 : (f32, f32) -> i32
      %4067 = llvm.bitcast %4066 : i32 to vector<2xbf16>
      %4068 = vector.extractelement %4063[%c0_i32 : i32] : vector<2xf32>
      %4069 = vector.extractelement %4063[%c1_i32 : i32] : vector<2xf32>
      %4070 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4069, %4068 : (f32, f32) -> i32
      %4071 = llvm.bitcast %4070 : i32 to vector<2xbf16>
      %4072 = vector.insert_strided_slice %4067, %4050 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4073 = vector.insert_strided_slice %4071, %4072 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4074 = arith.floordivsi %3852, %c2_i32 : i32
      %coord_1007 = cute.make_coord(%239, %3882, %4074) : (i32, i32, i32) -> !cute.coord<"(_,_,_,_,(?,?),?)">
      %idx_1008 = cute.crd2idx(%coord_1007, %4) : (!cute.coord<"(_,_,_,_,(?,?),?)">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">) -> !cute.int_tuple<"?">
      %ptr_1009 = cute.add_offset(%iter_956, %idx_1008) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %view_1010 = cute.make_view(%ptr_1009) : !memref_rmem_bf16_8
      %4075 = cute.memref.load_vec %view_1010 : !memref_rmem_bf16_8
      %4076 = arith.mulf %4073, %4075 : vector<32xbf16>
      %ptr_1011 = cute.add_offset(%iter_976, %idx_999) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_1012 = cute.make_view(%ptr_1011) : !memref_rmem_bf16_5
      cute.memref.store_vec %4076, %view_1012 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1013 = cute.add_offset(%ptr_50, %int_tuple_993) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4077 = builtin.unrealized_conversion_cast %ptr_1013 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4077, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_1014 = cute.add_offset(%iter_92, %int_tuple_979) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4078 = builtin.unrealized_conversion_cast %ptr_1014 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4079 = nvvm.mapa.shared.cluster %4078, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4079, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %4080 = arith.addi %3852, %c1_i32 : i32
      cf.br ^bb741(%4080, %3862, %3864, %3866, %3877, %3879, %3881 : i32, i32, i32, i32, i32, i32, i32)
    ^bb757:  // pred: ^bb741
      %int_tuple_1015 = cute.make_int_tuple(%3854) : (i32) -> !cute.int_tuple<"?">
      %ptr_1016 = cute.add_offset(%ptr_95, %int_tuple_1015) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4081 = builtin.unrealized_conversion_cast %ptr_1016 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4081, %3855, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4082 = arith.addi %3854, %c1_i32 : i32
      %4083 = arith.addi %3853, %c1_i32 : i32
      %4084 = arith.cmpi eq, %4082, %c3_i32 : i32
      %4085 = arith.select %4084, %c0_i32, %4082 : i32
      cf.cond_br %4084, ^bb758, ^bb759
    ^bb758:  // pred: ^bb757
      %4086 = arith.xori %3855, %c1_i32 : i32
      cf.br ^bb760(%4086 : i32)
    ^bb759:  // pred: ^bb757
      cf.br ^bb760(%3855 : i32)
    ^bb760(%4087: i32):  // 2 preds: ^bb758, ^bb759
      cf.br ^bb761
    ^bb761:  // pred: ^bb760
      %ptr_1017 = cute.add_offset(%iter_976, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1018 = cute.make_coord(%3854) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1019 = cute.crd2idx(%coord_1018, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb762(%c0_i32 : i32)
    ^bb762(%4088: i32):  // 2 preds: ^bb761, ^bb763
      %4089 = arith.cmpi slt, %4088, %2616 : i32
      cf.cond_br %4089, ^bb763, ^bb764 {llvm.loop_annotation = #loop_annotation}
    ^bb763:  // pred: ^bb762
      %coord_1020 = cute.make_coord(%4088) : (i32) -> !cute.coord<"(_,?)">
      %idx_1021 = cute.crd2idx(%coord_1020, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1022 = cute.add_offset(%ptr_1017, %idx_1021) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1023 = cute.crd2idx(%coord_1020, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1024 = cute.add_offset(%ptr_788, %idx_1023) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1025 = cute.apply_swizzle(%ptr_1024) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1026 = cute.add_offset(%swizzled_1025, %idx_1019) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4090 = builtin.unrealized_conversion_cast %ptr_1022 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4091 = builtin.unrealized_conversion_cast %ptr_1026 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4092 = llvm.load %4090 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4092, %4091 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4093 = arith.addi %4088, %c1_i32 : i32
      cf.br ^bb762(%4093 : i32)
    ^bb764:  // pred: ^bb762
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1027 = cute.add_offset(%iter_92, %int_tuple_1015) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4094 = builtin.unrealized_conversion_cast %ptr_1027 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4095 = nvvm.mapa.shared.cluster %4094, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4095, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_1028 = cute.add_offset(%ptr_81, %int_tuple_952) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4096 = builtin.unrealized_conversion_cast %ptr_1028 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4096, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %4097 = arith.addi %3134, %c1_i32 : i32
      cf.br ^bb687(%4097, %3856, %3857, %3858, %3151, %3153, %3155, %4083, %4085, %4087, %3625, %3627, %3629 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb765:  // pred: ^bb687
      %4098 = cute.make_tiled_copy(%atom_773) : !copy_simt2
      %rmem_1029 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_1030 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_1031 = cute.memref.alloca() : !memref_rmem_bf16_6
      %int_tuple_1032 = cute.make_int_tuple(%3145) : (i32) -> !cute.int_tuple<"?">
      %ptr_1033 = cute.add_offset(%iter_76, %int_tuple_1032) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4099 = builtin.unrealized_conversion_cast %ptr_1033 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4099, %3146, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4100 = arith.addi %3145, %c1_i32 : i32
      %4101 = arith.addi %3144, %c1_i32 : i32
      %4102 = arith.cmpi eq, %4100, %c5_i32 : i32
      %4103 = arith.select %4102, %c0_i32, %4100 : i32
      cf.cond_br %4102, ^bb766, ^bb767
    ^bb766:  // pred: ^bb765
      %4104 = arith.xori %3146, %c1_i32 : i32
      cf.br ^bb768(%4104 : i32)
    ^bb767:  // pred: ^bb765
      cf.br ^bb768(%3146 : i32)
    ^bb768(%4105: i32):  // 2 preds: ^bb766, ^bb767
      cf.br ^bb769
    ^bb769:  // pred: ^bb768
      %coord_1034 = cute.make_coord(%3145) : (i32) -> !cute.coord<"(_,_,_,_,_,(_,?))">
      %idx_1035 = cute.crd2idx(%coord_1034, %3) : (!cute.coord<"(_,_,_,_,_,(_,?))">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),(4,5)):((0,0),0,0,0,(0,(0,1)),(64,256))">) -> !cute.int_tuple<"?{div=256}">
      %iter_1036 = cute.get_iter(%rmem_1031) : !memref_rmem_bf16_6
      cf.br ^bb770(%c0_i32 : i32)
    ^bb770(%4106: i32):  // 2 preds: ^bb769, ^bb771
      %4107 = arith.cmpi slt, %4106, %2634 : i32
      cf.cond_br %4107, ^bb771, ^bb772 {llvm.loop_annotation = #loop_annotation}
    ^bb771:  // pred: ^bb770
      %coord_1037 = cute.make_coord(%4106) : (i32) -> !cute.coord<"(_,?)">
      %idx_1038 = cute.crd2idx(%coord_1037, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,1)),64))">) -> !cute.int_tuple<"?">
      %ptr_1039 = cute.add_offset(%ptr_796, %idx_1038) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_1040 = cute.add_offset(%ptr_1039, %idx_1035) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, smem>
      %idx_1041 = cute.crd2idx(%coord_1037, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,0)),1))">) -> !cute.int_tuple<"?">
      %ptr_1042 = cute.add_offset(%iter_1036, %idx_1041) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %4108 = builtin.unrealized_conversion_cast %ptr_1040 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %4109 = builtin.unrealized_conversion_cast %ptr_1042 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %4110 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4110, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4111 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4111, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4112 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4112, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4113 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4113, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4114 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4114, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4115 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4115, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4116 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4116, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4117 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4117, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4118 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4118, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4119 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4119, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4120 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4120, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4121 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4121, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4122 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4122, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4123 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4123, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4124 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4124, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4125 = llvm.load %4108 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4125, %4109 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4126 = arith.addi %4106, %c1_i32 : i32
      cf.br ^bb770(%4126 : i32)
    ^bb772:  // pred: ^bb770
      %int_tuple_1043 = cute.make_int_tuple(%3136) : (i32) -> !cute.int_tuple<"?">
      %ptr_1044 = cute.add_offset(%iter_45, %int_tuple_1043) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4127 = builtin.unrealized_conversion_cast %ptr_1044 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4127, %3137, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4128 = arith.addi %3136, %c1_i32 : i32
      %4129 = arith.addi %3135, %c1_i32 : i32
      %4130 = arith.cmpi eq, %4128, %c5_i32 : i32
      %4131 = arith.select %4130, %c0_i32, %4128 : i32
      cf.cond_br %4130, ^bb773, ^bb774
    ^bb773:  // pred: ^bb772
      %4132 = arith.xori %3137, %c1_i32 : i32
      cf.br ^bb775(%4132 : i32)
    ^bb774:  // pred: ^bb772
      cf.br ^bb775(%3137 : i32)
    ^bb775(%4133: i32):  // 2 preds: ^bb773, ^bb774
      cf.br ^bb776
    ^bb776:  // pred: ^bb775
      %coord_1045 = cute.make_coord(%3136) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1046 = cute.crd2idx(%coord_1045, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1047 = cute.add_offset(%ptr_793, %idx_1046) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %iter_1048 = cute.get_iter(%rmem_1029) : !memref_rmem_i8_
      cf.br ^bb777(%c0_i32 : i32)
    ^bb777(%4134: i32):  // 2 preds: ^bb776, ^bb778
      %4135 = arith.cmpi slt, %4134, %2614 : i32
      cf.cond_br %4135, ^bb778, ^bb779 {llvm.loop_annotation = #loop_annotation}
    ^bb778:  // pred: ^bb777
      %coord_1049 = cute.make_coord(%4134) : (i32) -> !cute.coord<"(_,?)">
      %idx_1050 = cute.crd2idx(%coord_1049, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1051 = cute.add_offset(%ptr_1047, %idx_1050) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1052 = cute.crd2idx(%coord_1049, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1053 = cute.add_offset(%iter_1048, %idx_1052) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %4136 = builtin.unrealized_conversion_cast %ptr_1051 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %4137 = builtin.unrealized_conversion_cast %ptr_1053 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %4138 = llvm.load %4136 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %4138, %4137 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %4139 = arith.addi %4134, %c1_i32 : i32
      cf.br ^bb777(%4139 : i32)
    ^bb779:  // pred: ^bb777
      %view_1054 = cute.make_view(%iter_1048) : !memref_rmem_i8_1
      %4140 = cute.memref.load_vec %view_1054 : !memref_rmem_i8_1
      %4141 = vector.extract_strided_slice %4140 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4142 = llvm.bitcast %4141 : vector<4xi8> to i32
      %4143 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4142, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4144 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4142, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4145 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4142, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4146 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4142, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4147 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4143 : (i32) -> f32
      %4148 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4144 : (i32) -> f32
      %4149 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4145 : (i32) -> f32
      %4150 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4146 : (i32) -> f32
      %4151 = vector.from_elements %4147, %4148, %4149, %4150 : vector<4xf32>
      %4152 = vector.extract_strided_slice %4151 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4153 = vector.extract_strided_slice %4151 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4154 = vector.extractelement %4152[%c0_i32 : i32] : vector<2xf32>
      %4155 = vector.extractelement %4152[%c1_i32 : i32] : vector<2xf32>
      %4156 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4155, %4154 : (f32, f32) -> i32
      %4157 = llvm.bitcast %4156 : i32 to vector<2xbf16>
      %4158 = vector.extractelement %4153[%c0_i32 : i32] : vector<2xf32>
      %4159 = vector.extractelement %4153[%c1_i32 : i32] : vector<2xf32>
      %4160 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4159, %4158 : (f32, f32) -> i32
      %4161 = llvm.bitcast %4160 : i32 to vector<2xbf16>
      %4162 = vector.insert_strided_slice %4157, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4163 = vector.insert_strided_slice %4161, %4162 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4164 = vector.extract_strided_slice %4140 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4165 = llvm.bitcast %4164 : vector<4xi8> to i32
      %4166 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4165, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4167 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4165, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4168 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4165, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4169 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4165, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4170 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4166 : (i32) -> f32
      %4171 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4167 : (i32) -> f32
      %4172 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4168 : (i32) -> f32
      %4173 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4169 : (i32) -> f32
      %4174 = vector.from_elements %4170, %4171, %4172, %4173 : vector<4xf32>
      %4175 = vector.extract_strided_slice %4174 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4176 = vector.extract_strided_slice %4174 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4177 = vector.extractelement %4175[%c0_i32 : i32] : vector<2xf32>
      %4178 = vector.extractelement %4175[%c1_i32 : i32] : vector<2xf32>
      %4179 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4178, %4177 : (f32, f32) -> i32
      %4180 = llvm.bitcast %4179 : i32 to vector<2xbf16>
      %4181 = vector.extractelement %4176[%c0_i32 : i32] : vector<2xf32>
      %4182 = vector.extractelement %4176[%c1_i32 : i32] : vector<2xf32>
      %4183 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4182, %4181 : (f32, f32) -> i32
      %4184 = llvm.bitcast %4183 : i32 to vector<2xbf16>
      %4185 = vector.insert_strided_slice %4180, %4163 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4186 = vector.insert_strided_slice %4184, %4185 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4187 = vector.extract_strided_slice %4140 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4188 = llvm.bitcast %4187 : vector<4xi8> to i32
      %4189 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4188, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4190 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4188, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4191 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4188, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4192 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4188, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4193 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4189 : (i32) -> f32
      %4194 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4190 : (i32) -> f32
      %4195 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4191 : (i32) -> f32
      %4196 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4192 : (i32) -> f32
      %4197 = vector.from_elements %4193, %4194, %4195, %4196 : vector<4xf32>
      %4198 = vector.extract_strided_slice %4197 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4199 = vector.extract_strided_slice %4197 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4200 = vector.extractelement %4198[%c0_i32 : i32] : vector<2xf32>
      %4201 = vector.extractelement %4198[%c1_i32 : i32] : vector<2xf32>
      %4202 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4201, %4200 : (f32, f32) -> i32
      %4203 = llvm.bitcast %4202 : i32 to vector<2xbf16>
      %4204 = vector.extractelement %4199[%c0_i32 : i32] : vector<2xf32>
      %4205 = vector.extractelement %4199[%c1_i32 : i32] : vector<2xf32>
      %4206 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4205, %4204 : (f32, f32) -> i32
      %4207 = llvm.bitcast %4206 : i32 to vector<2xbf16>
      %4208 = vector.insert_strided_slice %4203, %4186 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4209 = vector.insert_strided_slice %4207, %4208 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4210 = vector.extract_strided_slice %4140 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4211 = llvm.bitcast %4210 : vector<4xi8> to i32
      %4212 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4211, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4213 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4211, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4214 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4211, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4215 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4211, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4216 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4212 : (i32) -> f32
      %4217 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4213 : (i32) -> f32
      %4218 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4214 : (i32) -> f32
      %4219 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4215 : (i32) -> f32
      %4220 = vector.from_elements %4216, %4217, %4218, %4219 : vector<4xf32>
      %4221 = vector.extract_strided_slice %4220 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4222 = vector.extract_strided_slice %4220 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4223 = vector.extractelement %4221[%c0_i32 : i32] : vector<2xf32>
      %4224 = vector.extractelement %4221[%c1_i32 : i32] : vector<2xf32>
      %4225 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4224, %4223 : (f32, f32) -> i32
      %4226 = llvm.bitcast %4225 : i32 to vector<2xbf16>
      %4227 = vector.extractelement %4222[%c0_i32 : i32] : vector<2xf32>
      %4228 = vector.extractelement %4222[%c1_i32 : i32] : vector<2xf32>
      %4229 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4228, %4227 : (f32, f32) -> i32
      %4230 = llvm.bitcast %4229 : i32 to vector<2xbf16>
      %4231 = vector.insert_strided_slice %4226, %4209 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4232 = vector.insert_strided_slice %4230, %4231 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4233 = vector.extract_strided_slice %4140 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4234 = llvm.bitcast %4233 : vector<4xi8> to i32
      %4235 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4234, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4236 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4234, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4237 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4234, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4238 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4234, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4239 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4235 : (i32) -> f32
      %4240 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4236 : (i32) -> f32
      %4241 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4237 : (i32) -> f32
      %4242 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4238 : (i32) -> f32
      %4243 = vector.from_elements %4239, %4240, %4241, %4242 : vector<4xf32>
      %4244 = vector.extract_strided_slice %4243 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4245 = vector.extract_strided_slice %4243 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4246 = vector.extractelement %4244[%c0_i32 : i32] : vector<2xf32>
      %4247 = vector.extractelement %4244[%c1_i32 : i32] : vector<2xf32>
      %4248 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4247, %4246 : (f32, f32) -> i32
      %4249 = llvm.bitcast %4248 : i32 to vector<2xbf16>
      %4250 = vector.extractelement %4245[%c0_i32 : i32] : vector<2xf32>
      %4251 = vector.extractelement %4245[%c1_i32 : i32] : vector<2xf32>
      %4252 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4251, %4250 : (f32, f32) -> i32
      %4253 = llvm.bitcast %4252 : i32 to vector<2xbf16>
      %4254 = vector.insert_strided_slice %4249, %4232 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4255 = vector.insert_strided_slice %4253, %4254 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4256 = vector.extract_strided_slice %4140 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4257 = llvm.bitcast %4256 : vector<4xi8> to i32
      %4258 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4257, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4259 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4257, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4260 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4257, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4261 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4257, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4262 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4258 : (i32) -> f32
      %4263 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4259 : (i32) -> f32
      %4264 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4260 : (i32) -> f32
      %4265 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4261 : (i32) -> f32
      %4266 = vector.from_elements %4262, %4263, %4264, %4265 : vector<4xf32>
      %4267 = vector.extract_strided_slice %4266 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4268 = vector.extract_strided_slice %4266 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4269 = vector.extractelement %4267[%c0_i32 : i32] : vector<2xf32>
      %4270 = vector.extractelement %4267[%c1_i32 : i32] : vector<2xf32>
      %4271 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4270, %4269 : (f32, f32) -> i32
      %4272 = llvm.bitcast %4271 : i32 to vector<2xbf16>
      %4273 = vector.extractelement %4268[%c0_i32 : i32] : vector<2xf32>
      %4274 = vector.extractelement %4268[%c1_i32 : i32] : vector<2xf32>
      %4275 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4274, %4273 : (f32, f32) -> i32
      %4276 = llvm.bitcast %4275 : i32 to vector<2xbf16>
      %4277 = vector.insert_strided_slice %4272, %4255 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4278 = vector.insert_strided_slice %4276, %4277 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4279 = vector.extract_strided_slice %4140 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4280 = llvm.bitcast %4279 : vector<4xi8> to i32
      %4281 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4280, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4282 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4280, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4283 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4280, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4284 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4280, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4285 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4281 : (i32) -> f32
      %4286 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4282 : (i32) -> f32
      %4287 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4283 : (i32) -> f32
      %4288 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4284 : (i32) -> f32
      %4289 = vector.from_elements %4285, %4286, %4287, %4288 : vector<4xf32>
      %4290 = vector.extract_strided_slice %4289 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4291 = vector.extract_strided_slice %4289 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4292 = vector.extractelement %4290[%c0_i32 : i32] : vector<2xf32>
      %4293 = vector.extractelement %4290[%c1_i32 : i32] : vector<2xf32>
      %4294 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4293, %4292 : (f32, f32) -> i32
      %4295 = llvm.bitcast %4294 : i32 to vector<2xbf16>
      %4296 = vector.extractelement %4291[%c0_i32 : i32] : vector<2xf32>
      %4297 = vector.extractelement %4291[%c1_i32 : i32] : vector<2xf32>
      %4298 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4297, %4296 : (f32, f32) -> i32
      %4299 = llvm.bitcast %4298 : i32 to vector<2xbf16>
      %4300 = vector.insert_strided_slice %4295, %4278 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4301 = vector.insert_strided_slice %4299, %4300 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4302 = vector.extract_strided_slice %4140 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4303 = llvm.bitcast %4302 : vector<4xi8> to i32
      %4304 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4303, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4305 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4303, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4306 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4303, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4307 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4303, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4308 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4304 : (i32) -> f32
      %4309 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4305 : (i32) -> f32
      %4310 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4306 : (i32) -> f32
      %4311 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4307 : (i32) -> f32
      %4312 = vector.from_elements %4308, %4309, %4310, %4311 : vector<4xf32>
      %4313 = vector.extract_strided_slice %4312 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4314 = vector.extract_strided_slice %4312 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4315 = vector.extractelement %4313[%c0_i32 : i32] : vector<2xf32>
      %4316 = vector.extractelement %4313[%c1_i32 : i32] : vector<2xf32>
      %4317 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4316, %4315 : (f32, f32) -> i32
      %4318 = llvm.bitcast %4317 : i32 to vector<2xbf16>
      %4319 = vector.extractelement %4314[%c0_i32 : i32] : vector<2xf32>
      %4320 = vector.extractelement %4314[%c1_i32 : i32] : vector<2xf32>
      %4321 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4320, %4319 : (f32, f32) -> i32
      %4322 = llvm.bitcast %4321 : i32 to vector<2xbf16>
      %4323 = vector.insert_strided_slice %4318, %4301 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4324 = vector.insert_strided_slice %4322, %4323 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_1055 = cute.make_view(%iter_1036) : !memref_rmem_bf16_7
      %4325 = cute.memref.load_vec %view_1055 : !memref_rmem_bf16_7
      %4326 = arith.mulf %4324, %4325 : vector<32xbf16>
      %iter_1056 = cute.get_iter(%rmem_1030) : !memref_rmem_bf16_2
      %view_1057 = cute.make_view(%iter_1056) : !memref_rmem_bf16_5
      cute.memref.store_vec %4326, %view_1057 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1058 = cute.add_offset(%ptr_50, %int_tuple_1043) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4327 = builtin.unrealized_conversion_cast %ptr_1058 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4327, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb780(%c1_i32, %3141, %3142, %3143, %4129, %4131, %4133 : i32, i32, i32, i32, i32, i32, i32)
    ^bb780(%4328: i32, %4329: i32, %4330: i32, %4331: i32, %4332: i32, %4333: i32, %4334: i32):  // 2 preds: ^bb779, ^bb795
      %4335 = arith.cmpi slt, %4328, %c8_i32 : i32
      cf.cond_br %4335, ^bb781, ^bb796 {loop_annotation = #loop_annotation1}
    ^bb781:  // pred: ^bb780
      %int_tuple_1059 = cute.make_int_tuple(%4330) : (i32) -> !cute.int_tuple<"?">
      %ptr_1060 = cute.add_offset(%ptr_95, %int_tuple_1059) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4336 = builtin.unrealized_conversion_cast %ptr_1060 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4336, %4331, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4337 = arith.addi %4330, %c1_i32 : i32
      %4338 = arith.addi %4329, %c1_i32 : i32
      %4339 = arith.cmpi eq, %4337, %c3_i32 : i32
      %4340 = arith.select %4339, %c0_i32, %4337 : i32
      cf.cond_br %4339, ^bb782, ^bb783
    ^bb782:  // pred: ^bb781
      %4341 = arith.xori %4331, %c1_i32 : i32
      cf.br ^bb784(%4341 : i32)
    ^bb783:  // pred: ^bb781
      cf.br ^bb784(%4331 : i32)
    ^bb784(%4342: i32):  // 2 preds: ^bb782, ^bb783
      cf.br ^bb785
    ^bb785:  // pred: ^bb784
      %4343 = arith.subi %4328, %c1_i32 : i32
      %4344 = arith.remsi %4343, %c2_i32 : i32
      %coord_1061 = cute.make_coord(%4344) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1062 = cute.crd2idx(%coord_1061, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1063 = cute.add_offset(%iter_1056, %idx_1062) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1064 = cute.make_coord(%4330) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1065 = cute.crd2idx(%coord_1064, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb786(%c0_i32 : i32)
    ^bb786(%4345: i32):  // 2 preds: ^bb785, ^bb787
      %4346 = arith.cmpi slt, %4345, %2616 : i32
      cf.cond_br %4346, ^bb787, ^bb788 {llvm.loop_annotation = #loop_annotation}
    ^bb787:  // pred: ^bb786
      %coord_1066 = cute.make_coord(%4345) : (i32) -> !cute.coord<"(_,?)">
      %idx_1067 = cute.crd2idx(%coord_1066, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1068 = cute.add_offset(%ptr_1063, %idx_1067) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1069 = cute.crd2idx(%coord_1066, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1070 = cute.add_offset(%ptr_794, %idx_1069) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1071 = cute.apply_swizzle(%ptr_1070) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1072 = cute.add_offset(%swizzled_1071, %idx_1065) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4347 = builtin.unrealized_conversion_cast %ptr_1068 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4348 = builtin.unrealized_conversion_cast %ptr_1072 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4349 = llvm.load %4347 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4349, %4348 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4350 = arith.addi %4345, %c1_i32 : i32
      cf.br ^bb786(%4350 : i32)
    ^bb788:  // pred: ^bb786
      %int_tuple_1073 = cute.make_int_tuple(%4333) : (i32) -> !cute.int_tuple<"?">
      %ptr_1074 = cute.add_offset(%iter_45, %int_tuple_1073) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4351 = builtin.unrealized_conversion_cast %ptr_1074 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4351, %4334, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4352 = arith.addi %4333, %c1_i32 : i32
      %4353 = arith.addi %4332, %c1_i32 : i32
      %4354 = arith.cmpi eq, %4352, %c5_i32 : i32
      %4355 = arith.select %4354, %c0_i32, %4352 : i32
      cf.cond_br %4354, ^bb789, ^bb790
    ^bb789:  // pred: ^bb788
      %4356 = arith.xori %4334, %c1_i32 : i32
      cf.br ^bb791(%4356 : i32)
    ^bb790:  // pred: ^bb788
      cf.br ^bb791(%4334 : i32)
    ^bb791(%4357: i32):  // 2 preds: ^bb789, ^bb790
      cf.br ^bb792
    ^bb792:  // pred: ^bb791
      %coord_1075 = cute.make_coord(%4333) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1076 = cute.crd2idx(%coord_1075, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1077 = cute.add_offset(%ptr_793, %idx_1076) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %4358 = arith.remsi %4328, %c2_i32 : i32
      %coord_1078 = cute.make_coord(%4358) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1079 = cute.crd2idx(%coord_1078, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1080 = cute.add_offset(%iter_1048, %idx_1079) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      cf.br ^bb793(%c0_i32 : i32)
    ^bb793(%4359: i32):  // 2 preds: ^bb792, ^bb794
      %4360 = arith.cmpi slt, %4359, %2614 : i32
      cf.cond_br %4360, ^bb794, ^bb795 {llvm.loop_annotation = #loop_annotation}
    ^bb794:  // pred: ^bb793
      %coord_1081 = cute.make_coord(%4359) : (i32) -> !cute.coord<"(_,?)">
      %idx_1082 = cute.crd2idx(%coord_1081, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1083 = cute.add_offset(%ptr_1077, %idx_1082) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1084 = cute.crd2idx(%coord_1081, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1085 = cute.add_offset(%ptr_1080, %idx_1084) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %4361 = builtin.unrealized_conversion_cast %ptr_1083 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %4362 = builtin.unrealized_conversion_cast %ptr_1085 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %4363 = llvm.load %4361 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %4363, %4362 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %4364 = arith.addi %4359, %c1_i32 : i32
      cf.br ^bb793(%4364 : i32)
    ^bb795:  // pred: ^bb793
      %view_1086 = cute.make_view(%ptr_1080) : !memref_rmem_i8_1
      %4365 = cute.memref.load_vec %view_1086 : !memref_rmem_i8_1
      %4366 = vector.extract_strided_slice %4365 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4367 = llvm.bitcast %4366 : vector<4xi8> to i32
      %4368 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4367, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4369 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4367, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4370 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4367, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4371 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4367, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4372 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4368 : (i32) -> f32
      %4373 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4369 : (i32) -> f32
      %4374 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4370 : (i32) -> f32
      %4375 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4371 : (i32) -> f32
      %4376 = vector.from_elements %4372, %4373, %4374, %4375 : vector<4xf32>
      %4377 = vector.extract_strided_slice %4376 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4378 = vector.extract_strided_slice %4376 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4379 = vector.extractelement %4377[%c0_i32 : i32] : vector<2xf32>
      %4380 = vector.extractelement %4377[%c1_i32 : i32] : vector<2xf32>
      %4381 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4380, %4379 : (f32, f32) -> i32
      %4382 = llvm.bitcast %4381 : i32 to vector<2xbf16>
      %4383 = vector.extractelement %4378[%c0_i32 : i32] : vector<2xf32>
      %4384 = vector.extractelement %4378[%c1_i32 : i32] : vector<2xf32>
      %4385 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4384, %4383 : (f32, f32) -> i32
      %4386 = llvm.bitcast %4385 : i32 to vector<2xbf16>
      %4387 = vector.insert_strided_slice %4382, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4388 = vector.insert_strided_slice %4386, %4387 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4389 = vector.extract_strided_slice %4365 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4390 = llvm.bitcast %4389 : vector<4xi8> to i32
      %4391 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4390, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4392 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4390, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4393 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4390, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4394 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4390, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4395 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4391 : (i32) -> f32
      %4396 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4392 : (i32) -> f32
      %4397 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4393 : (i32) -> f32
      %4398 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4394 : (i32) -> f32
      %4399 = vector.from_elements %4395, %4396, %4397, %4398 : vector<4xf32>
      %4400 = vector.extract_strided_slice %4399 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4401 = vector.extract_strided_slice %4399 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4402 = vector.extractelement %4400[%c0_i32 : i32] : vector<2xf32>
      %4403 = vector.extractelement %4400[%c1_i32 : i32] : vector<2xf32>
      %4404 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4403, %4402 : (f32, f32) -> i32
      %4405 = llvm.bitcast %4404 : i32 to vector<2xbf16>
      %4406 = vector.extractelement %4401[%c0_i32 : i32] : vector<2xf32>
      %4407 = vector.extractelement %4401[%c1_i32 : i32] : vector<2xf32>
      %4408 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4407, %4406 : (f32, f32) -> i32
      %4409 = llvm.bitcast %4408 : i32 to vector<2xbf16>
      %4410 = vector.insert_strided_slice %4405, %4388 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4411 = vector.insert_strided_slice %4409, %4410 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4412 = vector.extract_strided_slice %4365 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4413 = llvm.bitcast %4412 : vector<4xi8> to i32
      %4414 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4413, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4415 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4413, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4416 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4413, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4417 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4413, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4418 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4414 : (i32) -> f32
      %4419 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4415 : (i32) -> f32
      %4420 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4416 : (i32) -> f32
      %4421 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4417 : (i32) -> f32
      %4422 = vector.from_elements %4418, %4419, %4420, %4421 : vector<4xf32>
      %4423 = vector.extract_strided_slice %4422 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4424 = vector.extract_strided_slice %4422 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4425 = vector.extractelement %4423[%c0_i32 : i32] : vector<2xf32>
      %4426 = vector.extractelement %4423[%c1_i32 : i32] : vector<2xf32>
      %4427 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4426, %4425 : (f32, f32) -> i32
      %4428 = llvm.bitcast %4427 : i32 to vector<2xbf16>
      %4429 = vector.extractelement %4424[%c0_i32 : i32] : vector<2xf32>
      %4430 = vector.extractelement %4424[%c1_i32 : i32] : vector<2xf32>
      %4431 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4430, %4429 : (f32, f32) -> i32
      %4432 = llvm.bitcast %4431 : i32 to vector<2xbf16>
      %4433 = vector.insert_strided_slice %4428, %4411 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4434 = vector.insert_strided_slice %4432, %4433 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4435 = vector.extract_strided_slice %4365 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4436 = llvm.bitcast %4435 : vector<4xi8> to i32
      %4437 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4436, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4438 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4436, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4439 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4436, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4440 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4436, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4441 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4437 : (i32) -> f32
      %4442 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4438 : (i32) -> f32
      %4443 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4439 : (i32) -> f32
      %4444 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4440 : (i32) -> f32
      %4445 = vector.from_elements %4441, %4442, %4443, %4444 : vector<4xf32>
      %4446 = vector.extract_strided_slice %4445 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4447 = vector.extract_strided_slice %4445 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4448 = vector.extractelement %4446[%c0_i32 : i32] : vector<2xf32>
      %4449 = vector.extractelement %4446[%c1_i32 : i32] : vector<2xf32>
      %4450 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4449, %4448 : (f32, f32) -> i32
      %4451 = llvm.bitcast %4450 : i32 to vector<2xbf16>
      %4452 = vector.extractelement %4447[%c0_i32 : i32] : vector<2xf32>
      %4453 = vector.extractelement %4447[%c1_i32 : i32] : vector<2xf32>
      %4454 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4453, %4452 : (f32, f32) -> i32
      %4455 = llvm.bitcast %4454 : i32 to vector<2xbf16>
      %4456 = vector.insert_strided_slice %4451, %4434 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4457 = vector.insert_strided_slice %4455, %4456 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4458 = vector.extract_strided_slice %4365 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4459 = llvm.bitcast %4458 : vector<4xi8> to i32
      %4460 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4459, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4461 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4459, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4462 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4459, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4463 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4459, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4464 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4460 : (i32) -> f32
      %4465 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4461 : (i32) -> f32
      %4466 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4462 : (i32) -> f32
      %4467 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4463 : (i32) -> f32
      %4468 = vector.from_elements %4464, %4465, %4466, %4467 : vector<4xf32>
      %4469 = vector.extract_strided_slice %4468 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4470 = vector.extract_strided_slice %4468 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4471 = vector.extractelement %4469[%c0_i32 : i32] : vector<2xf32>
      %4472 = vector.extractelement %4469[%c1_i32 : i32] : vector<2xf32>
      %4473 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4472, %4471 : (f32, f32) -> i32
      %4474 = llvm.bitcast %4473 : i32 to vector<2xbf16>
      %4475 = vector.extractelement %4470[%c0_i32 : i32] : vector<2xf32>
      %4476 = vector.extractelement %4470[%c1_i32 : i32] : vector<2xf32>
      %4477 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4476, %4475 : (f32, f32) -> i32
      %4478 = llvm.bitcast %4477 : i32 to vector<2xbf16>
      %4479 = vector.insert_strided_slice %4474, %4457 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4480 = vector.insert_strided_slice %4478, %4479 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4481 = vector.extract_strided_slice %4365 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4482 = llvm.bitcast %4481 : vector<4xi8> to i32
      %4483 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4482, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4484 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4482, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4485 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4482, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4486 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4482, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4487 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4483 : (i32) -> f32
      %4488 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4484 : (i32) -> f32
      %4489 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4485 : (i32) -> f32
      %4490 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4486 : (i32) -> f32
      %4491 = vector.from_elements %4487, %4488, %4489, %4490 : vector<4xf32>
      %4492 = vector.extract_strided_slice %4491 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4493 = vector.extract_strided_slice %4491 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4494 = vector.extractelement %4492[%c0_i32 : i32] : vector<2xf32>
      %4495 = vector.extractelement %4492[%c1_i32 : i32] : vector<2xf32>
      %4496 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4495, %4494 : (f32, f32) -> i32
      %4497 = llvm.bitcast %4496 : i32 to vector<2xbf16>
      %4498 = vector.extractelement %4493[%c0_i32 : i32] : vector<2xf32>
      %4499 = vector.extractelement %4493[%c1_i32 : i32] : vector<2xf32>
      %4500 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4499, %4498 : (f32, f32) -> i32
      %4501 = llvm.bitcast %4500 : i32 to vector<2xbf16>
      %4502 = vector.insert_strided_slice %4497, %4480 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4503 = vector.insert_strided_slice %4501, %4502 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4504 = vector.extract_strided_slice %4365 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4505 = llvm.bitcast %4504 : vector<4xi8> to i32
      %4506 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4505, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4507 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4505, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4508 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4505, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4509 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4505, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4510 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4506 : (i32) -> f32
      %4511 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4507 : (i32) -> f32
      %4512 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4508 : (i32) -> f32
      %4513 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4509 : (i32) -> f32
      %4514 = vector.from_elements %4510, %4511, %4512, %4513 : vector<4xf32>
      %4515 = vector.extract_strided_slice %4514 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4516 = vector.extract_strided_slice %4514 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4517 = vector.extractelement %4515[%c0_i32 : i32] : vector<2xf32>
      %4518 = vector.extractelement %4515[%c1_i32 : i32] : vector<2xf32>
      %4519 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4518, %4517 : (f32, f32) -> i32
      %4520 = llvm.bitcast %4519 : i32 to vector<2xbf16>
      %4521 = vector.extractelement %4516[%c0_i32 : i32] : vector<2xf32>
      %4522 = vector.extractelement %4516[%c1_i32 : i32] : vector<2xf32>
      %4523 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4522, %4521 : (f32, f32) -> i32
      %4524 = llvm.bitcast %4523 : i32 to vector<2xbf16>
      %4525 = vector.insert_strided_slice %4520, %4503 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4526 = vector.insert_strided_slice %4524, %4525 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4527 = vector.extract_strided_slice %4365 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4528 = llvm.bitcast %4527 : vector<4xi8> to i32
      %4529 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4528, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4530 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4528, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4531 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4528, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4532 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4528, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4533 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4529 : (i32) -> f32
      %4534 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4530 : (i32) -> f32
      %4535 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4531 : (i32) -> f32
      %4536 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4532 : (i32) -> f32
      %4537 = vector.from_elements %4533, %4534, %4535, %4536 : vector<4xf32>
      %4538 = vector.extract_strided_slice %4537 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4539 = vector.extract_strided_slice %4537 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4540 = vector.extractelement %4538[%c0_i32 : i32] : vector<2xf32>
      %4541 = vector.extractelement %4538[%c1_i32 : i32] : vector<2xf32>
      %4542 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4541, %4540 : (f32, f32) -> i32
      %4543 = llvm.bitcast %4542 : i32 to vector<2xbf16>
      %4544 = vector.extractelement %4539[%c0_i32 : i32] : vector<2xf32>
      %4545 = vector.extractelement %4539[%c1_i32 : i32] : vector<2xf32>
      %4546 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4545, %4544 : (f32, f32) -> i32
      %4547 = llvm.bitcast %4546 : i32 to vector<2xbf16>
      %4548 = vector.insert_strided_slice %4543, %4526 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4549 = vector.insert_strided_slice %4547, %4548 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4550 = arith.floordivsi %4328, %c2_i32 : i32
      %coord_1087 = cute.make_coord(%239, %4358, %4550) : (i32, i32, i32) -> !cute.coord<"(_,_,_,_,(?,?),?)">
      %idx_1088 = cute.crd2idx(%coord_1087, %4) : (!cute.coord<"(_,_,_,_,(?,?),?)">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">) -> !cute.int_tuple<"?">
      %ptr_1089 = cute.add_offset(%iter_1036, %idx_1088) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %view_1090 = cute.make_view(%ptr_1089) : !memref_rmem_bf16_8
      %4551 = cute.memref.load_vec %view_1090 : !memref_rmem_bf16_8
      %4552 = arith.mulf %4549, %4551 : vector<32xbf16>
      %ptr_1091 = cute.add_offset(%iter_1056, %idx_1079) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_1092 = cute.make_view(%ptr_1091) : !memref_rmem_bf16_5
      cute.memref.store_vec %4552, %view_1092 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1093 = cute.add_offset(%ptr_50, %int_tuple_1073) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4553 = builtin.unrealized_conversion_cast %ptr_1093 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4553, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_1094 = cute.add_offset(%iter_92, %int_tuple_1059) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4554 = builtin.unrealized_conversion_cast %ptr_1094 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4555 = nvvm.mapa.shared.cluster %4554, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4555, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %4556 = arith.addi %4328, %c1_i32 : i32
      cf.br ^bb780(%4556, %4338, %4340, %4342, %4353, %4355, %4357 : i32, i32, i32, i32, i32, i32, i32)
    ^bb796:  // pred: ^bb780
      %int_tuple_1095 = cute.make_int_tuple(%4330) : (i32) -> !cute.int_tuple<"?">
      %ptr_1096 = cute.add_offset(%ptr_95, %int_tuple_1095) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4557 = builtin.unrealized_conversion_cast %ptr_1096 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4557, %4331, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4558 = arith.addi %4330, %c1_i32 : i32
      %4559 = arith.addi %4329, %c1_i32 : i32
      %4560 = arith.cmpi eq, %4558, %c3_i32 : i32
      %4561 = arith.select %4560, %c0_i32, %4558 : i32
      cf.cond_br %4560, ^bb797, ^bb798
    ^bb797:  // pred: ^bb796
      %4562 = arith.xori %4331, %c1_i32 : i32
      cf.br ^bb799(%4562 : i32)
    ^bb798:  // pred: ^bb796
      cf.br ^bb799(%4331 : i32)
    ^bb799(%4563: i32):  // 2 preds: ^bb797, ^bb798
      cf.br ^bb800
    ^bb800:  // pred: ^bb799
      %ptr_1097 = cute.add_offset(%iter_1056, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1098 = cute.make_coord(%4330) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1099 = cute.crd2idx(%coord_1098, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb801(%c0_i32 : i32)
    ^bb801(%4564: i32):  // 2 preds: ^bb800, ^bb802
      %4565 = arith.cmpi slt, %4564, %2616 : i32
      cf.cond_br %4565, ^bb802, ^bb803 {llvm.loop_annotation = #loop_annotation}
    ^bb802:  // pred: ^bb801
      %coord_1100 = cute.make_coord(%4564) : (i32) -> !cute.coord<"(_,?)">
      %idx_1101 = cute.crd2idx(%coord_1100, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1102 = cute.add_offset(%ptr_1097, %idx_1101) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1103 = cute.crd2idx(%coord_1100, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1104 = cute.add_offset(%ptr_794, %idx_1103) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1105 = cute.apply_swizzle(%ptr_1104) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1106 = cute.add_offset(%swizzled_1105, %idx_1099) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4566 = builtin.unrealized_conversion_cast %ptr_1102 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4567 = builtin.unrealized_conversion_cast %ptr_1106 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4568 = llvm.load %4566 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4568, %4567 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4569 = arith.addi %4564, %c1_i32 : i32
      cf.br ^bb801(%4569 : i32)
    ^bb803:  // pred: ^bb801
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1107 = cute.add_offset(%iter_92, %int_tuple_1095) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4570 = builtin.unrealized_conversion_cast %ptr_1107 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4571 = nvvm.mapa.shared.cluster %4570, %315 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4571, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_1108 = cute.add_offset(%ptr_81, %int_tuple_1032) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4572 = builtin.unrealized_conversion_cast %ptr_1108 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4572, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb647(%4332, %4333, %4334, %3138, %3139, %3140, %4559, %4561, %4563, %4101, %4103, %4105, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb804:  // pred: ^bb647
      %4573 = arith.addi %2642, %c1_i32 : i32
      %4574 = arith.cmpi eq, %4573, %c3_i32 : i32
      %4575 = arith.select %4574, %c0_i32, %4573 : i32
      cf.cond_br %4574, ^bb805, ^bb806
    ^bb805:  // pred: ^bb804
      %4576 = arith.xori %2643, %c1_i32 : i32
      cf.br ^bb807(%4576 : i32)
    ^bb806:  // pred: ^bb804
      cf.br ^bb807(%2643 : i32)
    ^bb807(%4577: i32):  // 2 preds: ^bb805, ^bb806
      cf.br ^bb808
    ^bb808:  // pred: ^bb807
      %4578 = arith.addi %4575, %c1_i32 : i32
      %4579 = arith.cmpi eq, %4578, %c3_i32 : i32
      %4580 = arith.select %4579, %c0_i32, %4578 : i32
      cf.cond_br %4579, ^bb809, ^bb810
    ^bb809:  // pred: ^bb808
      %4581 = arith.xori %4577, %c1_i32 : i32
      cf.br ^bb811(%4581 : i32)
    ^bb810:  // pred: ^bb808
      cf.br ^bb811(%4577 : i32)
    ^bb811(%4582: i32):  // 2 preds: ^bb809, ^bb810
      cf.br ^bb812
    ^bb812:  // pred: ^bb811
      %int_tuple_1109 = cute.make_int_tuple(%4580) : (i32) -> !cute.int_tuple<"?">
      %ptr_1110 = cute.add_offset(%ptr_95, %int_tuple_1109) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4583 = builtin.unrealized_conversion_cast %ptr_1110 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4583, %4582, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb813
    ^bb813:  // 2 preds: ^bb645, ^bb812
      %4584 = arith.cmpi sgt, %236, %c13_i32 : i32
      cf.cond_br %4584, ^bb814, ^bb815
    ^bb814:  // pred: ^bb813
      nvvm.setmaxregister  decrease 96
      cf.br ^bb815
    ^bb815:  // 2 preds: ^bb813, ^bb814
      return
    }
  }
  func.func @cutlass___call_____main__MixedInputFusedMultiHeadAttentionPrefill_object_at__Ptr1_Ptr1_Ptr1_Ptr1_Ptr1_Ptr1_1_256_256_8_8_512_006375871541229934_10_None_None_CUstream0x0(%arg0: !cute.ptr<bf16, gmem, align<128>>, %arg1: !cute.ptr<i8, gmem, align<128>>, %arg2: !cute.ptr<i8, gmem, align<128>>, %arg3: !cute.ptr<bf16, gmem, align<128>>, %arg4: !cute.ptr<bf16, gmem, align<128>>, %arg5: !cute.ptr<bf16, gmem, align<128>>, %arg6: i32, %arg7: i32, %arg8: i32, %arg9: i32, %arg10: i32, %arg11: i32, %arg12: f32, %arg13: f32, %arg14: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c226048_i64 = arith.constant 226048 : i64
    %0 = llvm.mlir.constant(262194 : i64) : i64
    %1 = llvm.mlir.constant(0 : i64) : i64
    %2 = llvm.mlir.constant(9151314442816847872 : i64) : i64
    %3 = llvm.mlir.constant(263458 : i64) : i64
    %4 = llvm.mlir.constant(127 : i64) : i64
    %5 = llvm.mlir.constant(278578 : i64) : i64
    %6 = llvm.mlir.constant(63 : i64) : i64
    %7 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %8 = llvm.mlir.constant(288066 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c2_i32 = arith.constant 2 : i32
    %c512_i32 = arith.constant 512 : i32
    %9 = cute.static : !cute.stride<"(1@0,1@1,((0,1@2),1@3))">
    %10 = cute.static : !cute.int_tuple<"(0,0,0)">
    %11 = cute.static : !cute.stride<"(1@0,((0,1@1),1@2))">
    %12 = cute.static : !cute.int_tuple<"(0,0,0,0)">
    %13 = cute.static : !cute.stride<"(1@1,1@0,((0,1@2),1@3))">
    %14 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
    %15 = cute.static : !cute.stride<"(1@1,1@0,((1@2,1@3),1@4))">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c32_i64 = arith.constant 32 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4_i64 = arith.constant 4 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c2_i64 = arith.constant 2 : i64
    %c16_i32 = arith.constant 16 : i32
    %false = arith.constant false
    %c64_i32 = arith.constant 64 : i32
    %c1_i32 = arith.constant 1 : i32
    %16 = arith.floordivsi %arg9, %arg10 : i32
    %17 = arith.muli %arg11, %arg7 : i32
    %18 = arith.muli %17, %16 : i32
    %19 = arith.muli %16, %arg10 : i32
    %20 = arith.muli %19, %arg7 : i32
    %21 = arith.muli %20, %arg11 : i32
    %shape = cute.make_shape(%arg7, %arg11, %16, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride = cute.make_stride(%arg11, %17, %18, %21) : (i32, i32, i32, i32) -> !cute.stride<"(?,1,((?,?),?))">
    %lay = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">
    %22 = arith.muli %arg11, %arg8 : i32
    %23 = arith.muli %arg10, %arg8 : i32
    %24 = arith.muli %23, %arg11 : i32
    %shape_0 = cute.make_shape(%arg8, %arg11, %16, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride_1 = cute.make_stride(%arg11, %22, %24) : (i32, i32, i32) -> !cute.stride<"(?,1,((0,?),?))">
    %lay_2 = cute.make_layout(%shape_0, %stride_1) : !cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">
    %shape_3 = cute.make_shape(%arg11, %arg8, %16, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride_4 = cute.make_stride(%arg11, %22, %24) : (i32, i32, i32) -> !cute.stride<"(1,?,((0,?),?))">
    %lay_5 = cute.make_layout(%shape_3, %stride_4) : !cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">
    %iv = cute.assume(%arg11) : (i32) -> !cute.i32<divby 256>
    %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_6 = cute.assume(%17) : (i32) -> !cute.i32<divby 256>
    %int_tuple_7 = cute.make_int_tuple(%iv_6) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_8 = cute.assume(%18) : (i32) -> !cute.i32<divby 256>
    %int_tuple_9 = cute.make_int_tuple(%iv_8) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_10 = cute.assume(%21) : (i32) -> !cute.i32<divby 256>
    %int_tuple_11 = cute.make_int_tuple(%iv_10) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %stride_12 = cute.make_stride(%int_tuple, %int_tuple_7, %int_tuple_9, %int_tuple_11) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">) -> !cute.stride<"(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
    %lay_13 = cute.make_layout(%shape, %stride_12) : !cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
    %view = cute.make_view(%arg3, %lay_13) : !memref_gmem_bf16_
    %shape_14 = cute.make_shape(%arg8, %16, %arg10, %arg6) : (i32, i32, i32, i32) -> !cute.shape<"(?,((?,?),?))">
    %stride_15 = cute.make_stride(%arg8, %23) : (i32, i32) -> !cute.stride<"(1,((0,?),?))">
    %lay_16 = cute.make_layout(%shape_14, %stride_15) : !cute.layout<"(?,((?,?),?)):(1,((0,?),?))">
    %25 = cute.get_shape(%lay_13) : (!cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.shape<"(?,?,((?,?),?))">
    %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%25) : !cute.shape<"(?,?,((?,?),?))">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_17 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_18 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_19 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_20 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_20) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_21 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %int_tuple_22 = cute.make_int_tuple(%e0_21) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %26 = cute.get_scalars(%int_tuple_22) <{only_dynamic}> : !cute.int_tuple<"?">
    %27 = arith.ceildivsi %26, %c64_i32 : i32
    %int_tuple_23 = cute.make_int_tuple(%27) : (i32) -> !cute.int_tuple<"?">
    %e0_24 = cute.get_leaves(%int_tuple_23) : !cute.int_tuple<"?">
    %28 = cute.get_scalars(%e0_24) : !cute.int_tuple<"?">
    %int_tuple_25 = cute.make_int_tuple(%itup_17, %itup_18) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?)">
    %sz_26 = cute.size(%int_tuple_25) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
    %e0_27 = cute.get_leaves(%sz_26) : !cute.int_tuple<"?">
    %29 = cute.get_scalars(%e0_27) : !cute.int_tuple<"?">
    %int_tuple_28 = cute.make_int_tuple(%itup_19) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_29 = cute.size(%int_tuple_28) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_30 = cute.get_leaves(%sz_29) : !cute.int_tuple<"?">
    %30 = cute.get_scalars(%e0_30) : !cute.int_tuple<"?">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %31 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %32 = cute_nvgpu.atom.set_value(%31, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %33 = cute_nvgpu.atom.set_value(%32, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %34 = cute.make_tiled_mma(%33) : !mma_bf16_bf16_f32_128x256x16_
    %atom_31 = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %35 = cute_nvgpu.atom.set_value(%atom_31, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %36 = cute_nvgpu.atom.set_value(%35, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %37 = cute_nvgpu.atom.set_value(%36, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %38 = cute.make_tiled_mma(%37) : !mma_bf16_bf16_f32_128x256x16_1
    %39 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %40:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">
    %41 = arith.extui %40#1 : i32 to i64
    %42 = arith.extui %40#0 : i32 to i64
    %43 = arith.extui %40#5 : i32 to i64
    %44 = llvm.mul %43, %c2_i64 : i64
    %45 = arith.extui %40#2 : i32 to i64
    %46 = arith.extui %40#6 : i32 to i64
    %47 = llvm.mul %46, %c2_i64 : i64
    %48 = arith.extui %40#3 : i32 to i64
    %49 = arith.extui %40#7 : i32 to i64
    %50 = llvm.mul %49, %c2_i64 : i64
    %51 = arith.extui %40#4 : i32 to i64
    %52 = arith.extui %40#8 : i32 to i64
    %53 = llvm.mul %52, %c2_i64 : i64
    %54 = cute.ptrtoint(%arg0) : !cute.ptr<bf16, gmem, align<128>> to i64
    %55 = llvm.getelementptr %39[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %55 : i64, !llvm.ptr
    %56 = llvm.getelementptr %39[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %56 : i64, !llvm.ptr
    %57 = llvm.getelementptr %39[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %57 : i64, !llvm.ptr
    %58 = llvm.getelementptr %39[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %58 : i64, !llvm.ptr
    %59 = llvm.getelementptr %39[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %59 : i64, !llvm.ptr
    %60 = llvm.getelementptr %39[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %60 : i64, !llvm.ptr
    %61 = llvm.getelementptr %39[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %61 : i64, !llvm.ptr
    %62 = llvm.getelementptr %39[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %62 : i64, !llvm.ptr
    %63 = llvm.getelementptr %39[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %63 : i64, !llvm.ptr
    %64 = llvm.getelementptr %39[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %64 : i64, !llvm.ptr
    %65 = llvm.getelementptr %39[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %65 : i64, !llvm.ptr
    %66 = llvm.getelementptr %39[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %66 : i64, !llvm.ptr
    %67 = llvm.getelementptr %39[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %67 : i64, !llvm.ptr
    %68 = llvm.getelementptr %39[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %68 : i64, !llvm.ptr
    %69 = llvm.getelementptr %39[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %69 : i64, !llvm.ptr
    %70 = llvm.getelementptr %39[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %70 : i64, !llvm.ptr
    %71 = llvm.udiv %54, %c16_i64 : i64
    %72 = llvm.and %71, %c9007199254740991_i64 : i64
    %73 = llvm.shl %72, %c4_i64 : i64
    llvm.store %73, %55 : i64, !llvm.ptr
    %74 = llvm.sub %42, %c1_i64 : i64
    %75 = llvm.sub %45, %c1_i64 : i64
    %76 = llvm.sub %48, %c1_i64 : i64
    %77 = llvm.sub %51, %c1_i64 : i64
    %78 = llvm.mul %74, %44 : i64
    %79 = llvm.mul %75, %47 : i64
    %80 = llvm.mul %76, %50 : i64
    %81 = llvm.mul %77, %53 : i64
    %82 = llvm.add %78, %79 : i64
    %83 = llvm.add %80, %81 : i64
    %84 = llvm.mul %41, %c16_i64 : i64
    %85 = llvm.udiv %84, %c8_i64 : i64
    %86 = llvm.add %85, %82 : i64
    %87 = llvm.add %86, %83 : i64
    %88 = llvm.icmp "uge" %87, %c131072_i64 : i64
    %89 = llvm.zext %88 : i1 to i64
    %90 = llvm.shl %89, %c21_i64 : i64
    %91 = llvm.udiv %44, %c16_i64 : i64
    %92 = llvm.shl %91, %c32_i64 : i64
    %93 = llvm.or %c0_i64, %90 : i64
    %94 = llvm.or %93, %92 : i64
    %95 = llvm.or %8, %94 : i64
    llvm.store %95, %56 : i64, !llvm.ptr
    %96 = llvm.udiv %47, %c16_i64 : i64
    %97 = llvm.and %96, %c4294967295_i64 : i64
    %98 = llvm.shl %97, %c0_i64 : i64
    %99 = llvm.udiv %50, %c16_i64 : i64
    %100 = llvm.shl %99, %c32_i64 : i64
    %101 = llvm.or %98, %100 : i64
    llvm.store %101, %57 : i64, !llvm.ptr
    %102 = llvm.udiv %53, %c16_i64 : i64
    %103 = llvm.and %102, %c4294967295_i64 : i64
    %104 = llvm.shl %103, %c0_i64 : i64
    %105 = llvm.lshr %44, %c36_i64 : i64
    %106 = llvm.and %105, %c15_i64 : i64
    %107 = llvm.shl %106, %c32_i64 : i64
    %108 = llvm.lshr %47, %c36_i64 : i64
    %109 = llvm.and %108, %c15_i64 : i64
    %110 = llvm.shl %109, %c36_i64 : i64
    %111 = llvm.lshr %50, %c36_i64 : i64
    %112 = llvm.and %111, %c15_i64 : i64
    %113 = llvm.shl %112, %c40_i64 : i64
    %114 = llvm.lshr %53, %c36_i64 : i64
    %115 = llvm.shl %114, %c44_i64 : i64
    %116 = llvm.or %107, %110 : i64
    %117 = llvm.or %113, %115 : i64
    %118 = llvm.or %116, %117 : i64
    %119 = llvm.or %104, %118 : i64
    llvm.store %119, %58 : i64, !llvm.ptr
    %120 = llvm.sub %41, %c1_i64 : i64
    %121 = llvm.and %120, %c4294967295_i64 : i64
    %122 = llvm.shl %121, %c0_i64 : i64
    %123 = llvm.shl %74, %c32_i64 : i64
    %124 = llvm.or %122, %123 : i64
    llvm.store %124, %59 : i64, !llvm.ptr
    %125 = llvm.and %75, %c4294967295_i64 : i64
    %126 = llvm.shl %125, %c0_i64 : i64
    %127 = llvm.shl %76, %c32_i64 : i64
    %128 = llvm.or %126, %127 : i64
    llvm.store %128, %60 : i64, !llvm.ptr
    %129 = llvm.and %77, %c4294967295_i64 : i64
    %130 = llvm.or %129, %c0_i64 : i64
    %131 = llvm.or %130, %7 : i64
    llvm.store %131, %61 : i64, !llvm.ptr
    llvm.store %6, %62 : i64, !llvm.ptr
    %132 = builtin.unrealized_conversion_cast %39 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %133 = cute.ptrtoint(%132) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %134 = llvm.inttoptr %133 : i64 to !llvm.ptr
    %135 = llvm.load %134 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %136 = builtin.unrealized_conversion_cast %135 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_32 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>
    %137 = cute_nvgpu.atom.set_value(%atom_32, %136 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>
    %138 = cute.get_shape(%lay) : (!cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_33 = cute.make_layout(%138, %15) : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
    %view_34 = cute.make_view(%14, %lay_33) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
    %139 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %140:8 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">
    %141 = arith.extui %140#1 : i32 to i64
    %142 = arith.extui %140#0 : i32 to i64
    %143 = arith.extui %140#5 : i32 to i64
    %144 = llvm.mul %143, %c1_i64 : i64
    %145 = arith.extui %140#3 : i32 to i64
    %146 = arith.extui %140#6 : i32 to i64
    %147 = llvm.mul %146, %c1_i64 : i64
    %148 = arith.extui %140#4 : i32 to i64
    %149 = arith.extui %140#7 : i32 to i64
    %150 = llvm.mul %149, %c1_i64 : i64
    %151 = cute.ptrtoint(%arg1) : !cute.ptr<i8, gmem, align<128>> to i64
    %152 = llvm.getelementptr %139[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %152 : i64, !llvm.ptr
    %153 = llvm.getelementptr %139[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %153 : i64, !llvm.ptr
    %154 = llvm.getelementptr %139[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %154 : i64, !llvm.ptr
    %155 = llvm.getelementptr %139[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %155 : i64, !llvm.ptr
    %156 = llvm.getelementptr %139[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %156 : i64, !llvm.ptr
    %157 = llvm.getelementptr %139[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %157 : i64, !llvm.ptr
    %158 = llvm.getelementptr %139[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %158 : i64, !llvm.ptr
    %159 = llvm.getelementptr %139[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %159 : i64, !llvm.ptr
    %160 = llvm.getelementptr %139[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %160 : i64, !llvm.ptr
    %161 = llvm.getelementptr %139[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %161 : i64, !llvm.ptr
    %162 = llvm.getelementptr %139[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %162 : i64, !llvm.ptr
    %163 = llvm.getelementptr %139[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %163 : i64, !llvm.ptr
    %164 = llvm.getelementptr %139[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %164 : i64, !llvm.ptr
    %165 = llvm.getelementptr %139[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %165 : i64, !llvm.ptr
    %166 = llvm.getelementptr %139[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %166 : i64, !llvm.ptr
    %167 = llvm.getelementptr %139[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %167 : i64, !llvm.ptr
    %168 = llvm.udiv %151, %c16_i64 : i64
    %169 = llvm.and %168, %c9007199254740991_i64 : i64
    %170 = llvm.shl %169, %c4_i64 : i64
    llvm.store %170, %152 : i64, !llvm.ptr
    %171 = llvm.sub %142, %c1_i64 : i64
    %172 = llvm.sub %145, %c1_i64 : i64
    %173 = llvm.sub %148, %c1_i64 : i64
    %174 = llvm.sub %c1_i64, %c1_i64 : i64
    %175 = llvm.mul %171, %144 : i64
    %176 = llvm.mul %172, %147 : i64
    %177 = llvm.mul %173, %150 : i64
    %178 = llvm.mul %174, %c0_i64 : i64
    %179 = llvm.add %175, %176 : i64
    %180 = llvm.add %177, %178 : i64
    %181 = llvm.mul %141, %c8_i64 : i64
    %182 = llvm.udiv %181, %c8_i64 : i64
    %183 = llvm.add %182, %179 : i64
    %184 = llvm.add %183, %180 : i64
    %185 = llvm.icmp "uge" %184, %c131072_i64 : i64
    %186 = llvm.zext %185 : i1 to i64
    %187 = llvm.shl %186, %c21_i64 : i64
    %188 = llvm.udiv %144, %c16_i64 : i64
    %189 = llvm.shl %188, %c32_i64 : i64
    %190 = llvm.or %c0_i64, %187 : i64
    %191 = llvm.or %190, %189 : i64
    %192 = llvm.or %5, %191 : i64
    llvm.store %192, %153 : i64, !llvm.ptr
    %193 = llvm.udiv %147, %c16_i64 : i64
    %194 = llvm.and %193, %c4294967295_i64 : i64
    %195 = llvm.shl %194, %c0_i64 : i64
    %196 = llvm.udiv %150, %c16_i64 : i64
    %197 = llvm.shl %196, %c32_i64 : i64
    %198 = llvm.or %195, %197 : i64
    llvm.store %198, %154 : i64, !llvm.ptr
    %199 = llvm.udiv %c0_i64, %c16_i64 : i64
    %200 = llvm.and %199, %c4294967295_i64 : i64
    %201 = llvm.shl %200, %c0_i64 : i64
    %202 = llvm.lshr %144, %c36_i64 : i64
    %203 = llvm.and %202, %c15_i64 : i64
    %204 = llvm.shl %203, %c32_i64 : i64
    %205 = llvm.lshr %147, %c36_i64 : i64
    %206 = llvm.and %205, %c15_i64 : i64
    %207 = llvm.shl %206, %c36_i64 : i64
    %208 = llvm.lshr %150, %c36_i64 : i64
    %209 = llvm.and %208, %c15_i64 : i64
    %210 = llvm.shl %209, %c40_i64 : i64
    %211 = llvm.lshr %c0_i64, %c36_i64 : i64
    %212 = llvm.shl %211, %c44_i64 : i64
    %213 = llvm.or %204, %207 : i64
    %214 = llvm.or %210, %212 : i64
    %215 = llvm.or %213, %214 : i64
    %216 = llvm.or %201, %215 : i64
    llvm.store %216, %155 : i64, !llvm.ptr
    %217 = llvm.sub %141, %c1_i64 : i64
    %218 = llvm.and %217, %c4294967295_i64 : i64
    %219 = llvm.shl %218, %c0_i64 : i64
    %220 = llvm.shl %171, %c32_i64 : i64
    %221 = llvm.or %219, %220 : i64
    llvm.store %221, %156 : i64, !llvm.ptr
    %222 = llvm.and %172, %c4294967295_i64 : i64
    %223 = llvm.shl %222, %c0_i64 : i64
    %224 = llvm.shl %173, %c32_i64 : i64
    %225 = llvm.or %223, %224 : i64
    llvm.store %225, %157 : i64, !llvm.ptr
    %226 = llvm.and %174, %c4294967295_i64 : i64
    %227 = llvm.or %226, %c0_i64 : i64
    %228 = llvm.or %227, %7 : i64
    llvm.store %228, %158 : i64, !llvm.ptr
    llvm.store %4, %159 : i64, !llvm.ptr
    %229 = builtin.unrealized_conversion_cast %139 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %230 = cute.ptrtoint(%229) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %231 = llvm.inttoptr %230 : i64 to !llvm.ptr
    %232 = llvm.load %231 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %233 = builtin.unrealized_conversion_cast %232 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_35 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %234 = cute_nvgpu.atom.set_value(%atom_35, %233 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %235 = cute.get_shape(%lay_2) : (!cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_36 = cute.make_layout(%235, %13) : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
    %view_37 = cute.make_view(%12, %lay_36) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
    %236 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %237:6 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1,((0,?),?))">
    %238 = arith.extui %237#0 : i32 to i64
    %239 = arith.extui %237#2 : i32 to i64
    %240 = arith.extui %237#4 : i32 to i64
    %241 = llvm.mul %240, %c2_i64 : i64
    %242 = arith.extui %237#3 : i32 to i64
    %243 = arith.extui %237#5 : i32 to i64
    %244 = llvm.mul %243, %c2_i64 : i64
    %245 = cute.ptrtoint(%arg4) : !cute.ptr<bf16, gmem, align<128>> to i64
    %246 = llvm.getelementptr %236[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %246 : i64, !llvm.ptr
    %247 = llvm.getelementptr %236[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %247 : i64, !llvm.ptr
    %248 = llvm.getelementptr %236[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %248 : i64, !llvm.ptr
    %249 = llvm.getelementptr %236[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %249 : i64, !llvm.ptr
    %250 = llvm.getelementptr %236[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %250 : i64, !llvm.ptr
    %251 = llvm.getelementptr %236[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %251 : i64, !llvm.ptr
    %252 = llvm.getelementptr %236[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %252 : i64, !llvm.ptr
    %253 = llvm.getelementptr %236[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %253 : i64, !llvm.ptr
    %254 = llvm.getelementptr %236[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %254 : i64, !llvm.ptr
    %255 = llvm.getelementptr %236[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %255 : i64, !llvm.ptr
    %256 = llvm.getelementptr %236[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %256 : i64, !llvm.ptr
    %257 = llvm.getelementptr %236[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %257 : i64, !llvm.ptr
    %258 = llvm.getelementptr %236[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %258 : i64, !llvm.ptr
    %259 = llvm.getelementptr %236[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %259 : i64, !llvm.ptr
    %260 = llvm.getelementptr %236[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %260 : i64, !llvm.ptr
    %261 = llvm.getelementptr %236[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %261 : i64, !llvm.ptr
    %262 = llvm.udiv %245, %c16_i64 : i64
    %263 = llvm.and %262, %c9007199254740991_i64 : i64
    %264 = llvm.shl %263, %c4_i64 : i64
    llvm.store %264, %246 : i64, !llvm.ptr
    %265 = llvm.sub %239, %c1_i64 : i64
    %266 = llvm.sub %242, %c1_i64 : i64
    %267 = llvm.mul %265, %241 : i64
    %268 = llvm.mul %266, %244 : i64
    %269 = llvm.add %267, %268 : i64
    %270 = llvm.add %178, %178 : i64
    %271 = llvm.mul %238, %c16_i64 : i64
    %272 = llvm.udiv %271, %c8_i64 : i64
    %273 = llvm.add %272, %269 : i64
    %274 = llvm.add %273, %270 : i64
    %275 = llvm.icmp "uge" %274, %c131072_i64 : i64
    %276 = llvm.zext %275 : i1 to i64
    %277 = llvm.shl %276, %c21_i64 : i64
    %278 = llvm.udiv %241, %c16_i64 : i64
    %279 = llvm.shl %278, %c32_i64 : i64
    %280 = llvm.or %c0_i64, %277 : i64
    %281 = llvm.or %280, %279 : i64
    %282 = llvm.or %3, %281 : i64
    llvm.store %282, %247 : i64, !llvm.ptr
    %283 = llvm.udiv %244, %c16_i64 : i64
    %284 = llvm.and %283, %c4294967295_i64 : i64
    %285 = llvm.shl %284, %c0_i64 : i64
    %286 = llvm.shl %199, %c32_i64 : i64
    %287 = llvm.or %285, %286 : i64
    llvm.store %287, %248 : i64, !llvm.ptr
    %288 = llvm.lshr %241, %c36_i64 : i64
    %289 = llvm.and %288, %c15_i64 : i64
    %290 = llvm.shl %289, %c32_i64 : i64
    %291 = llvm.lshr %244, %c36_i64 : i64
    %292 = llvm.and %291, %c15_i64 : i64
    %293 = llvm.shl %292, %c36_i64 : i64
    %294 = llvm.and %211, %c15_i64 : i64
    %295 = llvm.shl %294, %c40_i64 : i64
    %296 = llvm.or %290, %293 : i64
    %297 = llvm.or %295, %212 : i64
    %298 = llvm.or %296, %297 : i64
    %299 = llvm.or %201, %298 : i64
    llvm.store %299, %249 : i64, !llvm.ptr
    %300 = llvm.sub %238, %c1_i64 : i64
    %301 = llvm.and %300, %c4294967295_i64 : i64
    %302 = llvm.shl %301, %c0_i64 : i64
    %303 = llvm.shl %265, %c32_i64 : i64
    %304 = llvm.or %302, %303 : i64
    llvm.store %304, %250 : i64, !llvm.ptr
    %305 = llvm.and %266, %c4294967295_i64 : i64
    %306 = llvm.shl %305, %c0_i64 : i64
    %307 = llvm.shl %174, %c32_i64 : i64
    %308 = llvm.or %306, %307 : i64
    llvm.store %308, %251 : i64, !llvm.ptr
    %309 = llvm.or %227, %2 : i64
    llvm.store %309, %252 : i64, !llvm.ptr
    llvm.store %1, %253 : i64, !llvm.ptr
    %310 = builtin.unrealized_conversion_cast %236 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %311 = cute.ptrtoint(%310) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %312 = llvm.inttoptr %311 : i64 to !llvm.ptr
    %313 = llvm.load %312 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %314 = builtin.unrealized_conversion_cast %313 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_38 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %315 = cute_nvgpu.atom.set_value(%atom_38, %314 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %316 = cute.get_shape(%lay_16) : (!cute.layout<"(?,((?,?),?)):(1,((0,?),?))">) -> !cute.shape<"(?,((?,?),?))">
    %lay_39 = cute.make_layout(%316, %11) : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
    %view_40 = cute.make_view(%10, %lay_39) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
    %317 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %318:8 = cute.get_scalars(%lay_5) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">
    %319 = arith.extui %318#0 : i32 to i64
    %320 = arith.extui %318#1 : i32 to i64
    %321 = arith.extui %318#5 : i32 to i64
    %322 = llvm.mul %321, %c1_i64 : i64
    %323 = arith.extui %318#3 : i32 to i64
    %324 = arith.extui %318#6 : i32 to i64
    %325 = llvm.mul %324, %c1_i64 : i64
    %326 = arith.extui %318#4 : i32 to i64
    %327 = arith.extui %318#7 : i32 to i64
    %328 = llvm.mul %327, %c1_i64 : i64
    %329 = cute.ptrtoint(%arg2) : !cute.ptr<i8, gmem, align<128>> to i64
    %330 = llvm.getelementptr %317[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %330 : i64, !llvm.ptr
    %331 = llvm.getelementptr %317[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %331 : i64, !llvm.ptr
    %332 = llvm.getelementptr %317[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %332 : i64, !llvm.ptr
    %333 = llvm.getelementptr %317[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %333 : i64, !llvm.ptr
    %334 = llvm.getelementptr %317[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %334 : i64, !llvm.ptr
    %335 = llvm.getelementptr %317[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %335 : i64, !llvm.ptr
    %336 = llvm.getelementptr %317[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %336 : i64, !llvm.ptr
    %337 = llvm.getelementptr %317[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %337 : i64, !llvm.ptr
    %338 = llvm.getelementptr %317[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %338 : i64, !llvm.ptr
    %339 = llvm.getelementptr %317[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %339 : i64, !llvm.ptr
    %340 = llvm.getelementptr %317[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %340 : i64, !llvm.ptr
    %341 = llvm.getelementptr %317[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %341 : i64, !llvm.ptr
    %342 = llvm.getelementptr %317[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %342 : i64, !llvm.ptr
    %343 = llvm.getelementptr %317[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %343 : i64, !llvm.ptr
    %344 = llvm.getelementptr %317[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %344 : i64, !llvm.ptr
    %345 = llvm.getelementptr %317[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %345 : i64, !llvm.ptr
    %346 = llvm.udiv %329, %c16_i64 : i64
    %347 = llvm.and %346, %c9007199254740991_i64 : i64
    %348 = llvm.shl %347, %c4_i64 : i64
    llvm.store %348, %330 : i64, !llvm.ptr
    %349 = llvm.sub %320, %c1_i64 : i64
    %350 = llvm.sub %323, %c1_i64 : i64
    %351 = llvm.sub %326, %c1_i64 : i64
    %352 = llvm.mul %349, %322 : i64
    %353 = llvm.mul %350, %325 : i64
    %354 = llvm.mul %351, %328 : i64
    %355 = llvm.add %352, %353 : i64
    %356 = llvm.add %354, %178 : i64
    %357 = llvm.mul %319, %c8_i64 : i64
    %358 = llvm.udiv %357, %c8_i64 : i64
    %359 = llvm.add %358, %355 : i64
    %360 = llvm.add %359, %356 : i64
    %361 = llvm.icmp "uge" %360, %c131072_i64 : i64
    %362 = llvm.zext %361 : i1 to i64
    %363 = llvm.shl %362, %c21_i64 : i64
    %364 = llvm.udiv %322, %c16_i64 : i64
    %365 = llvm.shl %364, %c32_i64 : i64
    %366 = llvm.or %c0_i64, %363 : i64
    %367 = llvm.or %366, %365 : i64
    %368 = llvm.or %0, %367 : i64
    llvm.store %368, %331 : i64, !llvm.ptr
    %369 = llvm.udiv %325, %c16_i64 : i64
    %370 = llvm.and %369, %c4294967295_i64 : i64
    %371 = llvm.shl %370, %c0_i64 : i64
    %372 = llvm.udiv %328, %c16_i64 : i64
    %373 = llvm.shl %372, %c32_i64 : i64
    %374 = llvm.or %371, %373 : i64
    llvm.store %374, %332 : i64, !llvm.ptr
    %375 = llvm.lshr %322, %c36_i64 : i64
    %376 = llvm.and %375, %c15_i64 : i64
    %377 = llvm.shl %376, %c32_i64 : i64
    %378 = llvm.lshr %325, %c36_i64 : i64
    %379 = llvm.and %378, %c15_i64 : i64
    %380 = llvm.shl %379, %c36_i64 : i64
    %381 = llvm.lshr %328, %c36_i64 : i64
    %382 = llvm.and %381, %c15_i64 : i64
    %383 = llvm.shl %382, %c40_i64 : i64
    %384 = llvm.or %377, %380 : i64
    %385 = llvm.or %383, %212 : i64
    %386 = llvm.or %384, %385 : i64
    %387 = llvm.or %201, %386 : i64
    llvm.store %387, %333 : i64, !llvm.ptr
    %388 = llvm.sub %319, %c1_i64 : i64
    %389 = llvm.and %388, %c4294967295_i64 : i64
    %390 = llvm.shl %389, %c0_i64 : i64
    %391 = llvm.shl %349, %c32_i64 : i64
    %392 = llvm.or %390, %391 : i64
    llvm.store %392, %334 : i64, !llvm.ptr
    %393 = llvm.and %350, %c4294967295_i64 : i64
    %394 = llvm.shl %393, %c0_i64 : i64
    %395 = llvm.shl %351, %c32_i64 : i64
    %396 = llvm.or %394, %395 : i64
    llvm.store %396, %335 : i64, !llvm.ptr
    llvm.store %228, %336 : i64, !llvm.ptr
    llvm.store %6, %337 : i64, !llvm.ptr
    %397 = builtin.unrealized_conversion_cast %317 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %398 = cute.ptrtoint(%397) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %399 = llvm.inttoptr %398 : i64 to !llvm.ptr
    %400 = llvm.load %399 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %401 = builtin.unrealized_conversion_cast %400 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_41 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %402 = cute_nvgpu.atom.set_value(%atom_41, %401 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %403 = cute.get_shape(%lay_5) : (!cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_42 = cute.make_layout(%403, %9) : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
    %view_43 = cute.make_view(%12, %lay_42) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
    %404 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %405 = cute.ptrtoint(%arg5) : !cute.ptr<bf16, gmem, align<128>> to i64
    %406 = llvm.getelementptr %404[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %406 : i64, !llvm.ptr
    %407 = llvm.getelementptr %404[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %407 : i64, !llvm.ptr
    %408 = llvm.getelementptr %404[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %408 : i64, !llvm.ptr
    %409 = llvm.getelementptr %404[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %409 : i64, !llvm.ptr
    %410 = llvm.getelementptr %404[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %410 : i64, !llvm.ptr
    %411 = llvm.getelementptr %404[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %411 : i64, !llvm.ptr
    %412 = llvm.getelementptr %404[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %412 : i64, !llvm.ptr
    %413 = llvm.getelementptr %404[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %413 : i64, !llvm.ptr
    %414 = llvm.getelementptr %404[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %414 : i64, !llvm.ptr
    %415 = llvm.getelementptr %404[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %415 : i64, !llvm.ptr
    %416 = llvm.getelementptr %404[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %416 : i64, !llvm.ptr
    %417 = llvm.getelementptr %404[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %417 : i64, !llvm.ptr
    %418 = llvm.getelementptr %404[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %418 : i64, !llvm.ptr
    %419 = llvm.getelementptr %404[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %419 : i64, !llvm.ptr
    %420 = llvm.getelementptr %404[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %420 : i64, !llvm.ptr
    %421 = llvm.getelementptr %404[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %421 : i64, !llvm.ptr
    %422 = llvm.udiv %405, %c16_i64 : i64
    %423 = llvm.and %422, %c9007199254740991_i64 : i64
    %424 = llvm.shl %423, %c4_i64 : i64
    llvm.store %424, %406 : i64, !llvm.ptr
    llvm.store %282, %407 : i64, !llvm.ptr
    llvm.store %287, %408 : i64, !llvm.ptr
    llvm.store %299, %409 : i64, !llvm.ptr
    llvm.store %304, %410 : i64, !llvm.ptr
    llvm.store %308, %411 : i64, !llvm.ptr
    llvm.store %228, %412 : i64, !llvm.ptr
    llvm.store %1, %413 : i64, !llvm.ptr
    %425 = builtin.unrealized_conversion_cast %404 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %426 = cute.ptrtoint(%425) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %427 = llvm.inttoptr %426 : i64 to !llvm.ptr
    %428 = llvm.load %427 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %429 = builtin.unrealized_conversion_cast %428 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_44 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %430 = cute_nvgpu.atom.set_value(%atom_44, %429 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %431 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c512_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c226048_i64, gridDim = (%28, %29, %30), stream = %arg14) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%431] (%c2_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %432 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__MixedInputFusedMultiHeadAttentionPrefill_object_at__TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK12825616_TVLayoutA26416641128_TV_0<%431> (%34, %38, %137, %view_34, %234, %view_37, %315, %view_40, %402, %view_43, %430, %view_40, %view, %arg12, %arg13, %28, %29, %30) : !cuda.launch_cfg<max_attrs = 2>, (!mma_bf16_bf16_f32_128x256x16_, !mma_bf16_bf16_f32_128x256x16_1, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>, !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>, !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, !memref_gmem_bf16_, f32, f32, i32, i32, i32) -> !cuda.result
    %433 = cuda.cast %432 : !cuda.result -> i32
    cuda.return_if_error %433 : i32
    return %c0_i32 : i32
  }
}
