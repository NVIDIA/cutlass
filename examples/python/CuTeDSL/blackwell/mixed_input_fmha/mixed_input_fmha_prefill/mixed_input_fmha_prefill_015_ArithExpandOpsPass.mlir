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
      %235 = arith.divsi %234, %c32_i32 : i32
      %236 = arith.muli %235, %c32_i32 : i32
      %237 = arith.cmpi ne, %234, %236 : i32
      %c0_i32_3 = arith.constant 0 : i32
      %238 = arith.cmpi slt, %234, %c0_i32_3 : i32
      %239 = arith.cmpi slt, %c32_i32, %c0_i32_3 : i32
      %240 = arith.cmpi ne, %238, %239 : i1
      %241 = arith.andi %237, %240 : i1
      %c-1_i32 = arith.constant -1 : i32
      %242 = arith.addi %235, %c-1_i32 : i32
      %243 = arith.select %241, %242, %235 : i32
      %244 = cute_nvgpu.arch.make_warp_uniform(%243) : i32
      %245 = arith.cmpi eq, %244, %c13_i32 : i32
      cf.cond_br %245, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %246 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %247 = arith.remsi %246, %c2_i32 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %223) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<512>>
      %ptr_4 = cute.add_offset(%smem_ptr, %221) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_5 = cute.add_offset(%smem_ptr, %220) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"208">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_6 = cute.add_offset(%smem_ptr, %219) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"288">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_7 = cute.add_offset(%smem_ptr, %218) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"368">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_8 = cute.add_offset(%smem_ptr, %217) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"416">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_9 = cute.add_offset(%smem_ptr, %216) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"448">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_10 = cute.add_offset(%smem_ptr, %215) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"480">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_11 = cute.add_offset(%smem_ptr, %214) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"496">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_11) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %ptr_12 = cute.add_offset(%smem_ptr, %213) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"504">) -> !cute.ptr<i8, smem, align<8>>
      %iter_13 = cute.recast_iter(%ptr_12) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %iter_14 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %248 = arith.cmpi eq, %244, %c0_i32 : i32
      cf.cond_br %248, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %249 = builtin.unrealized_conversion_cast %iter_14 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %249, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_15 = cute.add_offset(%iter_14, %212) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %250 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %250, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter_14, %211) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %251 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %251, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_17 = cute.add_offset(%iter_14, %210) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %252 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %252, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_18 = cute.add_offset(%iter_14, %209) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %253 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %253, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_19 = cute.add_offset(%iter_14, %208) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %254 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %254, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_20 = cute.add_offset(%iter_14, %207) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %255 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %255, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_21 = cute.add_offset(%iter_14, %206) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %256 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %256, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_22 = cute.add_offset(%iter_14, %205) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      cf.cond_br %248, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %257 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %257, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_23 = cute.add_offset(%iter_14, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %258 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %258, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_24 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_25 = cute.add_offset(%iter_14, %int_tuple_24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %259 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %259, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_27 = cute.add_offset(%iter_14, %int_tuple_26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %260 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %260, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_28 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_29 = cute.add_offset(%iter_14, %int_tuple_28) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %261 = builtin.unrealized_conversion_cast %ptr_29 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %261, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_30 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_31 = cute.add_offset(%iter_14, %int_tuple_30) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %262 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %262, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_32 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
      %ptr_33 = cute.add_offset(%iter_14, %int_tuple_32) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"14">) -> !cute.ptr<i64, smem, align<16>>
      %263 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %263, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_34 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
      %ptr_35 = cute.add_offset(%iter_14, %int_tuple_34) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"15">) -> !cute.ptr<i64, smem>
      %264 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %264, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %265 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %266 = cute_nvgpu.arch.make_warp_uniform(%265) : i32
      %267 = cute.get_flat_coord(%266, %224) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%267) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %268 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %224) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_36 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %269 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %270 = arith.shli %c1_i32, %269 : i32
      %271 = arith.trunci %270 : i32 to i16
      %coord_37 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_38 = cute.crd2idx(%coord_37, %224) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_39 = cute.get_leaves(%idx_38) : !cute.int_tuple<"?">
      %272 = cute.get_scalars(%e0_39) : !cute.int_tuple<"?">
      %273 = arith.shli %c1_i32, %272 : i32
      %274 = arith.trunci %273 : i32 to i16
      %275 = arith.xori %268, %c1_i32 : i32
      %coord_40 = cute.make_coord(%275) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_41 = cute.crd2idx(%coord_40, %224) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_42 = cute.get_leaves(%idx_41) : !cute.int_tuple<"?">
      %276 = cute.get_scalars(%e0_42) : !cute.int_tuple<"?">
      %277 = arith.shli %c1_i32, %276 : i32
      %278 = arith.trunci %277 : i32 to i16
      %coord_43 = cute.make_coord(%275) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_44 = cute.crd2idx(%coord_43, %224) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_45 = cute.get_leaves(%idx_44) : !cute.int_tuple<"?">
      %279 = cute.get_scalars(%e0_45) : !cute.int_tuple<"?">
      %280 = arith.shli %c1_i32, %279 : i32
      %281 = arith.trunci %280 : i32 to i16
      %282 = arith.ori %271, %274 : i16
      %283 = arith.ori %282, %278 : i16
      %284 = arith.ori %283, %281 : i16
      %285 = arith.cmpi eq, %247, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_46 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      cf.cond_br %248, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %286 = builtin.unrealized_conversion_cast %iter_46 : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %286, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_47 = cute.add_offset(%iter_46, %212) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %287 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %287, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_48 = cute.add_offset(%iter_46, %211) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %288 = builtin.unrealized_conversion_cast %ptr_48 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %288, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_49 = cute.add_offset(%iter_46, %210) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %289 = builtin.unrealized_conversion_cast %ptr_49 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %289, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_50 = cute.add_offset(%iter_46, %209) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %290 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %290, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_51 = cute.add_offset(%iter_46, %208) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %248, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %291 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %291, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_52 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_53 = cute.add_offset(%iter_46, %int_tuple_52) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn = cute.derefine(%ptr_53) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %292 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %292, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_54 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_55 = cute.add_offset(%iter_46, %int_tuple_54) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %293 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %293, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_56 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_57 = cute.add_offset(%iter_46, %int_tuple_56) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn_58 = cute.derefine(%ptr_57) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %294 = builtin.unrealized_conversion_cast %dyn_58 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %294, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_59 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_60 = cute.add_offset(%iter_46, %int_tuple_59) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %295 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %295, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      nvvm.barrier
      %iter_61 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %248, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      %296 = builtin.unrealized_conversion_cast %iter_61 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %296, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_62 = cute.add_offset(%iter_61, %212) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %297 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %297, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_63 = cute.add_offset(%iter_61, %211) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %298 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %298, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_64 = cute.add_offset(%iter_61, %210) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %299 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %299, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_65 = cute.add_offset(%iter_61, %209) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<16>>
      %300 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %300, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %ptr_66 = cute.add_offset(%iter_61, %208) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %248, ^bb13, ^bb14
    ^bb13:  // pred: ^bb12
      %301 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %301, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_67 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_68 = cute.add_offset(%iter_61, %int_tuple_67) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_69 = cute.derefine(%ptr_68) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %302 = builtin.unrealized_conversion_cast %dyn_69 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %302, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_70 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_71 = cute.add_offset(%iter_61, %int_tuple_70) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %303 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %303, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_72 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_73 = cute.add_offset(%iter_61, %int_tuple_72) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_74 = cute.derefine(%ptr_73) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %304 = builtin.unrealized_conversion_cast %dyn_74 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %304, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_75 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_76 = cute.add_offset(%iter_61, %int_tuple_75) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %305 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %305, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb12, ^bb13
      nvvm.barrier
      %iter_77 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %248, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      %306 = builtin.unrealized_conversion_cast %iter_77 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %306, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_78 = cute.add_offset(%iter_77, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %307 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %307, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_79 = cute.add_offset(%iter_77, %211) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %308 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %308, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_80 = cute.add_offset(%iter_77, %210) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %309 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %309, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_81 = cute.add_offset(%iter_77, %209) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %310 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %310, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      %ptr_82 = cute.add_offset(%iter_77, %208) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      cf.cond_br %248, ^bb17, ^bb18
    ^bb17:  // pred: ^bb16
      %311 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %311, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_83 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_84 = cute.add_offset(%iter_77, %int_tuple_83) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_85 = cute.derefine(%ptr_84) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %312 = builtin.unrealized_conversion_cast %dyn_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %312, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_86 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_87 = cute.add_offset(%iter_77, %int_tuple_86) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %313 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %313, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_88 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_89 = cute.add_offset(%iter_77, %int_tuple_88) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_90 = cute.derefine(%ptr_89) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %314 = builtin.unrealized_conversion_cast %dyn_90 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %314, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_91 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_92 = cute.add_offset(%iter_77, %int_tuple_91) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %315 = builtin.unrealized_conversion_cast %ptr_92 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %315, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb16, ^bb17
      nvvm.barrier
      %iter_93 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %248, ^bb19, ^bb20
    ^bb19:  // pred: ^bb18
      %316 = builtin.unrealized_conversion_cast %iter_93 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %316, %c512_i32 : !llvm.ptr<3>, i32
      %ptr_94 = cute.add_offset(%iter_93, %212) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %317 = builtin.unrealized_conversion_cast %ptr_94 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %317, %c512_i32 : !llvm.ptr<3>, i32
      %ptr_95 = cute.add_offset(%iter_93, %211) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %318 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %318, %c512_i32 : !llvm.ptr<3>, i32
      cf.br ^bb20
    ^bb20:  // 2 preds: ^bb18, ^bb19
      %ptr_96 = cute.add_offset(%iter_93, %210) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      cf.cond_br %248, ^bb21, ^bb22
    ^bb21:  // pred: ^bb20
      %319 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %319, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_97 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
      %ptr_98 = cute.add_offset(%iter_93, %int_tuple_97) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_99 = cute.derefine(%ptr_98) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %320 = builtin.unrealized_conversion_cast %dyn_99 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %320, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_100 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_101 = cute.add_offset(%iter_93, %int_tuple_100) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %321 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %321, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb22
    ^bb22:  // 2 preds: ^bb20, ^bb21
      %322 = arith.divsi %266, %c2_i32 : i32
      %323 = arith.muli %322, %c2_i32 : i32
      %324 = arith.cmpi ne, %266, %323 : i32
      %c0_i32_102 = arith.constant 0 : i32
      %325 = arith.cmpi slt, %266, %c0_i32_102 : i32
      %326 = arith.cmpi slt, %c2_i32, %c0_i32_102 : i32
      %327 = arith.cmpi ne, %325, %326 : i1
      %328 = arith.andi %324, %327 : i1
      %c-1_i32_103 = arith.constant -1 : i32
      %329 = arith.addi %322, %c-1_i32_103 : i32
      %330 = arith.select %328, %329, %322 : i32
      %331 = arith.muli %330, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_104 = cute.recast_iter(%ptr_8) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %248, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %332 = builtin.unrealized_conversion_cast %iter_104 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %332, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_105 = cute.add_offset(%iter_104, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %333 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %333, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      %ptr_106 = cute.add_offset(%iter_104, %211) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %248, ^bb25, ^bb26
    ^bb25:  // pred: ^bb24
      %334 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %334, %c256_i32 : !llvm.ptr<3>, i32
      %int_tuple_107 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_108 = cute.add_offset(%iter_104, %int_tuple_107) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %335 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %335, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb26
    ^bb26:  // 2 preds: ^bb24, ^bb25
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_109 = cute.recast_iter(%ptr_9) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      cf.cond_br %248, ^bb27, ^bb28
    ^bb27:  // pred: ^bb26
      %336 = builtin.unrealized_conversion_cast %iter_109 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %336, %c256_i32 : !llvm.ptr<3>, i32
      %ptr_110 = cute.add_offset(%iter_109, %212) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %337 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %337, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb28
    ^bb28:  // 2 preds: ^bb26, ^bb27
      %ptr_111 = cute.add_offset(%iter_109, %211) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %248, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %338 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %338, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_112 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_113 = cute.add_offset(%iter_109, %int_tuple_112) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %339 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %339, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb30
    ^bb30:  // 2 preds: ^bb28, ^bb29
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_114 = cute.recast_iter(%ptr_10) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %248, ^bb31, ^bb32
    ^bb31:  // pred: ^bb30
      %340 = builtin.unrealized_conversion_cast %iter_114 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %340, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb32
    ^bb32:  // 2 preds: ^bb30, ^bb31
      %ptr_115 = cute.add_offset(%iter_114, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %248, ^bb33, ^bb34
    ^bb33:  // pred: ^bb32
      %341 = builtin.unrealized_conversion_cast %ptr_115 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %341, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb34
    ^bb34:  // 2 preds: ^bb32, ^bb33
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %342 = arith.cmpi eq, %244, %c8_i32 : i32
      cf.cond_br %342, ^bb35, ^bb38
    ^bb35:  // pred: ^bb34
      %343 = nvvm.elect.sync -> i1
      cf.cond_br %343, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %344 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %344, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      cf.br ^bb38
    ^bb38:  // 2 preds: ^bb34, ^bb37
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      %int_tuple_116 = cute.make_int_tuple() : () -> !cute.int_tuple<"66048">
      %ptr_117 = cute.add_offset(%smem_ptr, %int_tuple_116) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"66048">) -> !cute.ptr<i8, smem, align<512>>
      %iter_118 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %int_tuple_119 = cute.make_int_tuple() : () -> !cute.int_tuple<"115200">
      %ptr_120 = cute.add_offset(%smem_ptr, %int_tuple_119) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"115200">) -> !cute.ptr<i8, smem, align<512>>
      %iter_121 = cute.recast_iter(%ptr_117) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %iter_122 = cute.recast_iter(%iter_121) : !cute.ptr<bf16, smem, align<512>, S<3,4,3>> to !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %int_tuple_123 = cute.make_int_tuple() : () -> !cute.int_tuple<"116480">
      %ptr_124 = cute.add_offset(%smem_ptr, %int_tuple_123) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"116480">) -> !cute.ptr<i8, smem, align<256>>
      %iter_125 = cute.recast_iter(%ptr_120) : !cute.ptr<i8, smem, align<512>> to !cute.ptr<bf16, smem, align<512>>
      %int_tuple_126 = cute.make_int_tuple() : () -> !cute.int_tuple<"119040">
      %ptr_127 = cute.add_offset(%smem_ptr, %int_tuple_126) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"119040">) -> !cute.ptr<i8, smem, align<256>>
      %iter_128 = cute.recast_iter(%ptr_124) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<bf16, smem, align<256>>
      %int_tuple_129 = cute.make_int_tuple() : () -> !cute.int_tuple<"184576">
      %ptr_130 = cute.add_offset(%smem_ptr, %int_tuple_129) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"184576">) -> !cute.ptr<i8, smem, align<256>>
      %iter_131 = cute.recast_iter(%ptr_127) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<bf16, smem, align<256>, S<3,4,3>>
      %int_tuple_132 = cute.make_int_tuple() : () -> !cute.int_tuple<"185088">
      %ptr_133 = cute.add_offset(%smem_ptr, %int_tuple_132) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"185088">) -> !cute.ptr<i8, smem, align<256>>
      %iter_134 = cute.recast_iter(%ptr_130) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<f32, smem, align<256>>
      %view = cute.make_view(%iter_134, %203) : !memref_smem_f32_
      %iter_135 = cute.recast_iter(%ptr_133) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %iter_136 = cute.recast_iter(%iter_135) : !cute.ptr<i8, smem, align<256>, S<2,4,3>> to !cute.ptr<i8, smem, align<256>>
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_118 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"((64,16),1,4,8):((64,1),0,16,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_137 = cute_nvgpu.make_umma_smem_desc(%iter_131 : !cute.ptr<bf16, smem, align<256>, S<3,4,3>>) layout = <"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_138 = cute_nvgpu.make_umma_smem_desc(%iter_121 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"((128,16),1,4,3):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_139 = cute_nvgpu.make_umma_smem_desc(%iter_122 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>) layout = <"(((64,2),16),1,4,3):(((1,4096),64),0,1024,8192)">, major = <mn> -> !cute_nvgpu.smem_desc
      %345 = cute.inttoptr(%202) : i32 to !cute.ptr<f32, tmem, align<1>>
      %ptr_140 = cute.add_offset(%345, %200) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"256">) -> !cute.ptr<f32, tmem, align<1>>
      %lay = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
      %346:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
      %c1_i32_141 = arith.constant 1 : i32
      %c0_i32_142 = arith.constant 0 : i32
      %c-1_i32_143 = arith.constant -1 : i32
      %347 = arith.cmpi sgt, %c128_i32, %c0_i32_142 : i32
      %348 = arith.select %347, %c-1_i32_143, %c1_i32_141 : i32
      %349 = arith.addi %348, %346#0 : i32
      %350 = arith.divsi %349, %c128_i32 : i32
      %351 = arith.addi %c1_i32_141, %350 : i32
      %352 = arith.subi %c0_i32_142, %346#0 : i32
      %353 = arith.divsi %352, %c128_i32 : i32
      %354 = arith.subi %c0_i32_142, %353 : i32
      %355 = arith.cmpi slt, %346#0, %c0_i32_142 : i32
      %356 = arith.cmpi sgt, %346#0, %c0_i32_142 : i32
      %357 = arith.cmpi slt, %c128_i32, %c0_i32_142 : i32
      %358 = arith.cmpi sgt, %c128_i32, %c0_i32_142 : i32
      %359 = arith.andi %355, %357 : i1
      %360 = arith.andi %356, %358 : i1
      %361 = arith.ori %359, %360 : i1
      %362 = arith.select %361, %351, %354 : i32
      %c1_i32_144 = arith.constant 1 : i32
      %c0_i32_145 = arith.constant 0 : i32
      %c-1_i32_146 = arith.constant -1 : i32
      %363 = arith.cmpi sgt, %c64_i32, %c0_i32_145 : i32
      %364 = arith.select %363, %c-1_i32_146, %c1_i32_144 : i32
      %365 = arith.addi %364, %346#1 : i32
      %366 = arith.divsi %365, %c64_i32 : i32
      %367 = arith.addi %c1_i32_144, %366 : i32
      %368 = arith.subi %c0_i32_145, %346#1 : i32
      %369 = arith.divsi %368, %c64_i32 : i32
      %370 = arith.subi %c0_i32_145, %369 : i32
      %371 = arith.cmpi slt, %346#1, %c0_i32_145 : i32
      %372 = arith.cmpi sgt, %346#1, %c0_i32_145 : i32
      %373 = arith.cmpi slt, %c64_i32, %c0_i32_145 : i32
      %374 = arith.cmpi sgt, %c64_i32, %c0_i32_145 : i32
      %375 = arith.andi %371, %373 : i1
      %376 = arith.andi %372, %374 : i1
      %377 = arith.ori %375, %376 : i1
      %378 = arith.select %377, %367, %370 : i32
      %shape = cute.make_shape(%362, %378, %346#2, %346#3, %346#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(128,64,?,?,((?,?),?))">
      %lay_147 = cute.make_layout(%shape, %198) : !cute.layout<"(128,64,?,?,((?,?),?)):(1@1,1@0,128@1,64@0,((1@2,1@3),1@4))">
      %coord_148 = cute.make_coord(%247) : (i32) -> !cute.coord<"?">
      %379:5 = cute.get_scalars(%lay_147) <{only_dynamic}> : !cute.layout<"(128,64,?,?,((?,?),?)):(1@1,1@0,128@1,64@0,((1@2,1@3),1@4))">
      %380 = cute.get_scalars(%coord_148) <{only_dynamic}> : !cute.coord<"?">
      %381 = arith.remsi %380, %c2_i32 : i32
      %382 = arith.remsi %381, %c2_i32 : i32
      %383 = arith.muli %382, %c64_i32 : i32
      %iv = cute.assume(%383) : (i32) -> !cute.i32<divby 64>
      %int_tuple_149 = cute.make_int_tuple(%iv) : (!cute.i32<divby 64>) -> !cute.int_tuple<"(0,?{div=64},0,0,0)">
      %tup = cute.add_offset(%199, %int_tuple_149) : (!cute.int_tuple<"(0,0,0,0,0)">, !cute.int_tuple<"(0,?{div=64},0,0,0)">) -> !cute.int_tuple<"(0,?{div=64},0,0,0)">
      %shape_150 = cute.make_shape(%379#0, %379#1, %379#2, %379#3, %379#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((64,16),1,4,?,?,((?,?),?))">
      %lay_151 = cute.make_layout(%shape_150, %197) : !cute.layout<"((64,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,128@1,64@0,((1@2,1@3),1@4))">
      %384:5 = cute.get_scalars(%lay_151) <{only_dynamic}> : !cute.layout<"((64,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,128@1,64@0,((1@2,1@3),1@4))">
      %shape_152 = cute.make_shape(%384#0, %384#1, %384#2, %384#3, %384#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,16),1,4),?,?,((?,?),?))">
      %lay_153 = cute.make_layout(%shape_152, %196) : !cute.layout<"(((64,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),128@1,64@0,((1@2,1@3),1@4))">
      %385:5 = cute.get_scalars(%lay_153) <{only_dynamic}> : !cute.layout<"(((64,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),128@1,64@0,((1@2,1@3),1@4))">
      %shape_154 = cute.make_shape(%385#0, %385#1, %385#2, %385#3, %385#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,((?,?),?))">
      %lay_155 = cute.make_layout(%shape_154, %195) : !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">
      %lay_156 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
      %386:5 = cute.get_scalars(%lay_156) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
      %c1_i32_157 = arith.constant 1 : i32
      %c0_i32_158 = arith.constant 0 : i32
      %c-1_i32_159 = arith.constant -1 : i32
      %387 = arith.cmpi sgt, %c256_i32, %c0_i32_158 : i32
      %388 = arith.select %387, %c-1_i32_159, %c1_i32_157 : i32
      %389 = arith.addi %388, %386#0 : i32
      %390 = arith.divsi %389, %c256_i32 : i32
      %391 = arith.addi %c1_i32_157, %390 : i32
      %392 = arith.subi %c0_i32_158, %386#0 : i32
      %393 = arith.divsi %392, %c256_i32 : i32
      %394 = arith.subi %c0_i32_158, %393 : i32
      %395 = arith.cmpi slt, %386#0, %c0_i32_158 : i32
      %396 = arith.cmpi sgt, %386#0, %c0_i32_158 : i32
      %397 = arith.cmpi slt, %c256_i32, %c0_i32_158 : i32
      %398 = arith.cmpi sgt, %c256_i32, %c0_i32_158 : i32
      %399 = arith.andi %395, %397 : i1
      %400 = arith.andi %396, %398 : i1
      %401 = arith.ori %399, %400 : i1
      %402 = arith.select %401, %391, %394 : i32
      %c1_i32_160 = arith.constant 1 : i32
      %c0_i32_161 = arith.constant 0 : i32
      %c-1_i32_162 = arith.constant -1 : i32
      %403 = arith.cmpi sgt, %c64_i32, %c0_i32_161 : i32
      %404 = arith.select %403, %c-1_i32_162, %c1_i32_160 : i32
      %405 = arith.addi %404, %386#1 : i32
      %406 = arith.divsi %405, %c64_i32 : i32
      %407 = arith.addi %c1_i32_160, %406 : i32
      %408 = arith.subi %c0_i32_161, %386#1 : i32
      %409 = arith.divsi %408, %c64_i32 : i32
      %410 = arith.subi %c0_i32_161, %409 : i32
      %411 = arith.cmpi slt, %386#1, %c0_i32_161 : i32
      %412 = arith.cmpi sgt, %386#1, %c0_i32_161 : i32
      %413 = arith.cmpi slt, %c64_i32, %c0_i32_161 : i32
      %414 = arith.cmpi sgt, %c64_i32, %c0_i32_161 : i32
      %415 = arith.andi %411, %413 : i1
      %416 = arith.andi %412, %414 : i1
      %417 = arith.ori %415, %416 : i1
      %418 = arith.select %417, %407, %410 : i32
      %shape_163 = cute.make_shape(%402, %418, %386#2, %386#3, %386#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(256,64,?,?,((?,?),?))">
      %lay_164 = cute.make_layout(%shape_163, %193) : !cute.layout<"(256,64,?,?,((?,?),?)):(1@1,1@0,256@1,64@0,((0,1@2),1@3))">
      %419:5 = cute.get_scalars(%lay_164) <{only_dynamic}> : !cute.layout<"(256,64,?,?,((?,?),?)):(1@1,1@0,256@1,64@0,((0,1@2),1@3))">
      %420 = arith.muli %382, %c128_i32 : i32
      %iv_165 = cute.assume(%420) : (i32) -> !cute.i32<divby 128>
      %int_tuple_166 = cute.make_int_tuple(%iv_165) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %tup_167 = cute.add_offset(%194, %int_tuple_166) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(0,?{div=128},0,0)">) -> !cute.int_tuple<"(0,?{div=128},0,0)">
      %shape_168 = cute.make_shape(%419#0, %419#1, %419#2, %419#3, %419#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,((?,?),?))">
      %lay_169 = cute.make_layout(%shape_168, %192) : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,256@1,64@0,((0,1@2),1@3))">
      %421:5 = cute.get_scalars(%lay_169) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@1,1@0),0,16@0,256@1,64@0,((0,1@2),1@3))">
      %shape_170 = cute.make_shape(%421#0, %421#1, %421#2, %421#3, %421#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,((?,?),?))">
      %lay_171 = cute.make_layout(%shape_170, %191) : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),256@1,64@0,((0,1@2),1@3))">
      %422:5 = cute.get_scalars(%lay_171) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@1,1@0),0,16@0),256@1,64@0,((0,1@2),1@3))">
      %shape_172 = cute.make_shape(%422#0, %422#1, %422#2, %422#3, %422#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,((?,?),?))">
      %lay_173 = cute.make_layout(%shape_172, %190) : !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">
      %lay_174 = cute.get_layout(%arg7) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %423:4 = cute.get_scalars(%lay_174) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %c1_i32_175 = arith.constant 1 : i32
      %c0_i32_176 = arith.constant 0 : i32
      %c-1_i32_177 = arith.constant -1 : i32
      %424 = arith.cmpi sgt, %c256_i32, %c0_i32_176 : i32
      %425 = arith.select %424, %c-1_i32_177, %c1_i32_175 : i32
      %426 = arith.addi %425, %423#0 : i32
      %427 = arith.divsi %426, %c256_i32 : i32
      %428 = arith.addi %c1_i32_175, %427 : i32
      %429 = arith.subi %c0_i32_176, %423#0 : i32
      %430 = arith.divsi %429, %c256_i32 : i32
      %431 = arith.subi %c0_i32_176, %430 : i32
      %432 = arith.cmpi slt, %423#0, %c0_i32_176 : i32
      %433 = arith.cmpi sgt, %423#0, %c0_i32_176 : i32
      %434 = arith.cmpi slt, %c256_i32, %c0_i32_176 : i32
      %435 = arith.cmpi sgt, %c256_i32, %c0_i32_176 : i32
      %436 = arith.andi %432, %434 : i1
      %437 = arith.andi %433, %435 : i1
      %438 = arith.ori %436, %437 : i1
      %439 = arith.select %438, %428, %431 : i32
      %shape_178 = cute.make_shape(%439, %423#1, %423#2, %423#3) : (i32, i32, i32, i32) -> !cute.shape<"(256,?,((?,?),?))">
      %lay_179 = cute.make_layout(%shape_178, %188) : !cute.layout<"(256,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %440:4 = cute.get_scalars(%lay_179) <{only_dynamic}> : !cute.layout<"(256,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %shape_180 = cute.make_shape(%440#0, %440#1, %440#2, %440#3) : (i32, i32, i32, i32) -> !cute.shape<"((128,2),?,((?,?),?))">
      %lay_181 = cute.make_layout(%shape_180, %187) : !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">
      %coord_182 = cute.make_coord(%247) : (i32) -> !cute.coord<"((_,?),_,_)">
      %441:4 = cute.get_scalars(%lay_181) <{only_dynamic}> : !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">
      %shape_183 = cute.make_shape(%441#0, %441#1, %441#2, %441#3) : (i32, i32, i32, i32) -> !cute.shape<"(128,?,((?,?),?))">
      %lay_184 = cute.make_layout(%shape_183, %188) : !cute.layout<"(128,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %idx_185 = cute.crd2idx(%coord_182, %lay_181) : (!cute.coord<"((_,?),_,_)">, !cute.layout<"((128,2),?,((?,?),?)):((1@0,128@0),256@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %tup_186 = cute.add_offset(%189, %idx_185) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},0,0)">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %442:4 = cute.get_scalars(%lay_184) <{only_dynamic}> : !cute.layout<"(128,?,((?,?),?)):(1@0,256@0,((0,1@1),1@2))">
      %shape_187 = cute.make_shape(%442#0, %442#1, %442#2, %442#3) : (i32, i32, i32, i32) -> !cute.shape<"((128,1),?,((?,?),?))">
      %lay_188 = cute.make_layout(%shape_187, %186) : !cute.layout<"((128,1),?,((?,?),?)):((1@0,0),256@0,((0,1@1),1@2))">
      %e0_189, %e1_190, %e2_191 = cute.get_leaves(%tup_186) : !cute.int_tuple<"(?{div=128},0,0)">
      %443 = cute.get_shape(%lay_188) : (!cute.layout<"((128,1),?,((?,?),?)):((1@0,0),256@0,((0,1@1),1@2))">) -> !cute.shape<"((128,1),?,((?,?),?))">
      %e0_192, %e1_193, %e2_194, %e3_195, %e4, %e5 = cute.get_leaves(%443) : !cute.shape<"((128,1),?,((?,?),?))">
      %itup_196 = cute.to_int_tuple(%e2_194) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_197 = cute.to_int_tuple(%e3_195) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_198 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_199 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_200 = cute.make_shape(%itup_196, %itup_197, %itup_198, %itup_199) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(((128,1),1),?,((?,?),?))">
      %lay_201 = cute.make_layout(%shape_200, %184) : !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">
      %int_tuple_202 = cute.make_int_tuple(%e0_189) : (!cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=128},0,0)">
      %lay_203 = cute.get_layout(%arg9) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
      %444:5 = cute.get_scalars(%lay_203) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
      %c1_i32_204 = arith.constant 1 : i32
      %c0_i32_205 = arith.constant 0 : i32
      %c-1_i32_206 = arith.constant -1 : i32
      %445 = arith.cmpi sgt, %c256_i32, %c0_i32_205 : i32
      %446 = arith.select %445, %c-1_i32_206, %c1_i32_204 : i32
      %447 = arith.addi %446, %444#0 : i32
      %448 = arith.divsi %447, %c256_i32 : i32
      %449 = arith.addi %c1_i32_204, %448 : i32
      %450 = arith.subi %c0_i32_205, %444#0 : i32
      %451 = arith.divsi %450, %c256_i32 : i32
      %452 = arith.subi %c0_i32_205, %451 : i32
      %453 = arith.cmpi slt, %444#0, %c0_i32_205 : i32
      %454 = arith.cmpi sgt, %444#0, %c0_i32_205 : i32
      %455 = arith.cmpi slt, %c256_i32, %c0_i32_205 : i32
      %456 = arith.cmpi sgt, %c256_i32, %c0_i32_205 : i32
      %457 = arith.andi %453, %455 : i1
      %458 = arith.andi %454, %456 : i1
      %459 = arith.ori %457, %458 : i1
      %460 = arith.select %459, %449, %452 : i32
      %c1_i32_207 = arith.constant 1 : i32
      %c0_i32_208 = arith.constant 0 : i32
      %c-1_i32_209 = arith.constant -1 : i32
      %461 = arith.cmpi sgt, %c64_i32, %c0_i32_208 : i32
      %462 = arith.select %461, %c-1_i32_209, %c1_i32_207 : i32
      %463 = arith.addi %462, %444#1 : i32
      %464 = arith.divsi %463, %c64_i32 : i32
      %465 = arith.addi %c1_i32_207, %464 : i32
      %466 = arith.subi %c0_i32_208, %444#1 : i32
      %467 = arith.divsi %466, %c64_i32 : i32
      %468 = arith.subi %c0_i32_208, %467 : i32
      %469 = arith.cmpi slt, %444#1, %c0_i32_208 : i32
      %470 = arith.cmpi sgt, %444#1, %c0_i32_208 : i32
      %471 = arith.cmpi slt, %c64_i32, %c0_i32_208 : i32
      %472 = arith.cmpi sgt, %c64_i32, %c0_i32_208 : i32
      %473 = arith.andi %469, %471 : i1
      %474 = arith.andi %470, %472 : i1
      %475 = arith.ori %473, %474 : i1
      %476 = arith.select %475, %465, %468 : i32
      %shape_210 = cute.make_shape(%460, %476, %444#2, %444#3, %444#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(256,64,?,?,((?,?),?))">
      %lay_211 = cute.make_layout(%shape_210, %183) : !cute.layout<"(256,64,?,?,((?,?),?)):(1@0,1@1,256@0,64@1,((0,1@2),1@3))">
      %477:5 = cute.get_scalars(%lay_211) <{only_dynamic}> : !cute.layout<"(256,64,?,?,((?,?),?)):(1@0,1@1,256@0,64@1,((0,1@2),1@3))">
      %int_tuple_212 = cute.make_int_tuple(%iv_165) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(?{div=128},0,0,0)">
      %tup_213 = cute.add_offset(%194, %int_tuple_212) : (!cute.int_tuple<"(0,0,0,0)">, !cute.int_tuple<"(?{div=128},0,0,0)">) -> !cute.int_tuple<"(?{div=128},0,0,0)">
      %shape_214 = cute.make_shape(%477#0, %477#1, %477#2, %477#3, %477#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,((?,?),?))">
      %lay_215 = cute.make_layout(%shape_214, %182) : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@0,1@1),0,16@1,256@0,64@1,((0,1@2),1@3))">
      %478:5 = cute.get_scalars(%lay_215) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,((?,?),?)):((1@0,1@1),0,16@1,256@0,64@1,((0,1@2),1@3))">
      %shape_216 = cute.make_shape(%478#0, %478#1, %478#2, %478#3, %478#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,((?,?),?))">
      %lay_217 = cute.make_layout(%shape_216, %181) : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@0,1@1),0,16@1),256@0,64@1,((0,1@2),1@3))">
      %479:5 = cute.get_scalars(%lay_217) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,((?,?),?)):(((1@0,1@1),0,16@1),256@0,64@1,((0,1@2),1@3))">
      %shape_218 = cute.make_shape(%479#0, %479#1, %479#2, %479#3, %479#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(((64,64),2),?,?,((?,?),?))">
      %lay_219 = cute.make_layout(%shape_218, %180) : !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">
      %lay_220 = cute.get_layout(%arg11) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %480:4 = cute.get_scalars(%lay_220) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
      %c1_i32_221 = arith.constant 1 : i32
      %c0_i32_222 = arith.constant 0 : i32
      %c-1_i32_223 = arith.constant -1 : i32
      %481 = arith.cmpi sgt, %c64_i32, %c0_i32_222 : i32
      %482 = arith.select %481, %c-1_i32_223, %c1_i32_221 : i32
      %483 = arith.addi %482, %480#0 : i32
      %484 = arith.divsi %483, %c64_i32 : i32
      %485 = arith.addi %c1_i32_221, %484 : i32
      %486 = arith.subi %c0_i32_222, %480#0 : i32
      %487 = arith.divsi %486, %c64_i32 : i32
      %488 = arith.subi %c0_i32_222, %487 : i32
      %489 = arith.cmpi slt, %480#0, %c0_i32_222 : i32
      %490 = arith.cmpi sgt, %480#0, %c0_i32_222 : i32
      %491 = arith.cmpi slt, %c64_i32, %c0_i32_222 : i32
      %492 = arith.cmpi sgt, %c64_i32, %c0_i32_222 : i32
      %493 = arith.andi %489, %491 : i1
      %494 = arith.andi %490, %492 : i1
      %495 = arith.ori %493, %494 : i1
      %496 = arith.select %495, %485, %488 : i32
      %shape_224 = cute.make_shape(%496, %480#1, %480#2, %480#3) : (i32, i32, i32, i32) -> !cute.shape<"(64,?,((?,?),?))">
      %lay_225 = cute.make_layout(%shape_224, %179) : !cute.layout<"(64,?,((?,?),?)):(1@0,64@0,((0,1@1),1@2))">
      %497:4 = cute.get_scalars(%lay_225) <{only_dynamic}> : !cute.layout<"(64,?,((?,?),?)):(1@0,64@0,((0,1@1),1@2))">
      %shape_226 = cute.make_shape(%497#0, %497#1, %497#2, %497#3) : (i32, i32, i32, i32) -> !cute.shape<"((64,1),?,((?,?),?))">
      %lay_227 = cute.make_layout(%shape_226, %178) : !cute.layout<"((64,1),?,((?,?),?)):((1@0,0),64@0,((0,1@1),1@2))">
      %498 = cute.get_shape(%lay_227) : (!cute.layout<"((64,1),?,((?,?),?)):((1@0,0),64@0,((0,1@1),1@2))">) -> !cute.shape<"((64,1),?,((?,?),?))">
      %e0_228, %e1_229, %e2_230, %e3_231, %e4_232, %e5_233 = cute.get_leaves(%498) : !cute.shape<"((64,1),?,((?,?),?))">
      %itup_234 = cute.to_int_tuple(%e2_230) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_235 = cute.to_int_tuple(%e3_231) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_236 = cute.to_int_tuple(%e4_232) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_237 = cute.to_int_tuple(%e5_233) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_238 = cute.make_shape(%itup_234, %itup_235, %itup_236, %itup_237) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(((64,1),1),?,((?,?),?))">
      %lay_239 = cute.make_layout(%shape_238, %176) : !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">
      %iter_240 = cute.get_iter(%arg12) : !memref_gmem_bf16_
      %lay_241 = cute.get_layout(%arg12) : !memref_gmem_bf16_
      %499:9 = cute.get_scalars(%lay_241) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
      %c1_i32_242 = arith.constant 1 : i32
      %c0_i32_243 = arith.constant 0 : i32
      %c-1_i32_244 = arith.constant -1 : i32
      %500 = arith.cmpi sgt, %c64_i32, %c0_i32_243 : i32
      %501 = arith.select %500, %c-1_i32_244, %c1_i32_242 : i32
      %502 = arith.addi %501, %499#0 : i32
      %503 = arith.divsi %502, %c64_i32 : i32
      %504 = arith.addi %c1_i32_242, %503 : i32
      %505 = arith.subi %c0_i32_243, %499#0 : i32
      %506 = arith.divsi %505, %c64_i32 : i32
      %507 = arith.subi %c0_i32_243, %506 : i32
      %508 = arith.cmpi slt, %499#0, %c0_i32_243 : i32
      %509 = arith.cmpi sgt, %499#0, %c0_i32_243 : i32
      %510 = arith.cmpi slt, %c64_i32, %c0_i32_243 : i32
      %511 = arith.cmpi sgt, %c64_i32, %c0_i32_243 : i32
      %512 = arith.andi %508, %510 : i1
      %513 = arith.andi %509, %511 : i1
      %514 = arith.ori %512, %513 : i1
      %515 = arith.select %514, %504, %507 : i32
      %516 = arith.muli %499#5, %c64_i32 : i32
      %c1_i32_245 = arith.constant 1 : i32
      %c0_i32_246 = arith.constant 0 : i32
      %c-1_i32_247 = arith.constant -1 : i32
      %517 = arith.cmpi sgt, %c256_i32, %c0_i32_246 : i32
      %518 = arith.select %517, %c-1_i32_247, %c1_i32_245 : i32
      %519 = arith.addi %518, %499#1 : i32
      %520 = arith.divsi %519, %c256_i32 : i32
      %521 = arith.addi %c1_i32_245, %520 : i32
      %522 = arith.subi %c0_i32_246, %499#1 : i32
      %523 = arith.divsi %522, %c256_i32 : i32
      %524 = arith.subi %c0_i32_246, %523 : i32
      %525 = arith.cmpi slt, %499#1, %c0_i32_246 : i32
      %526 = arith.cmpi sgt, %499#1, %c0_i32_246 : i32
      %527 = arith.cmpi slt, %c256_i32, %c0_i32_246 : i32
      %528 = arith.cmpi sgt, %c256_i32, %c0_i32_246 : i32
      %529 = arith.andi %525, %527 : i1
      %530 = arith.andi %526, %528 : i1
      %531 = arith.ori %529, %530 : i1
      %532 = arith.select %531, %521, %524 : i32
      %shape_248 = cute.make_shape(%515, %532, %499#2, %499#3, %499#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(64,256,?,?,((?,?),?))">
      %iv_249 = cute.assume(%499#5) : (i32) -> !cute.i32<divby 256>
      %iv_250 = cute.assume(%516) : (i32) -> !cute.i32<divby 16384>
      %iv_251 = cute.assume(%499#6) : (i32) -> !cute.i32<divby 256>
      %iv_252 = cute.assume(%499#7) : (i32) -> !cute.i32<divby 256>
      %iv_253 = cute.assume(%499#8) : (i32) -> !cute.i32<divby 256>
      %stride = cute.make_stride(%iv_249, %iv_250, %iv_251, %iv_252, %iv_253) : (!cute.i32<divby 256>, !cute.i32<divby 16384>, !cute.i32<divby 256>, !cute.i32<divby 256>, !cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %lay_254 = cute.make_layout(%shape_248, %stride) : !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %533 = cute.get_shape(%lay_241) : (!cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_255, %e1_256, %e2_257, %e3_258, %e4_259 = cute.get_leaves(%533) : !cute.shape<"(?,?,((?,?),?))">
      %itup_260 = cute.to_int_tuple(%e0_255) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_261 = cute.to_int_tuple(%e1_256) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_262 = cute.to_int_tuple(%e2_257) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_263 = cute.to_int_tuple(%e3_258) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %itup_264 = cute.to_int_tuple(%e4_259) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %shape_265 = cute.make_shape(%itup_260, %itup_261, %itup_262, %itup_263, %itup_264) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,((?,?),?))">
      %lay_266 = cute.make_layout(%shape_265, %174) : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %534:5 = cute.get_scalars(%lay_266) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %c1_i32_267 = arith.constant 1 : i32
      %c0_i32_268 = arith.constant 0 : i32
      %c-1_i32_269 = arith.constant -1 : i32
      %535 = arith.cmpi sgt, %c64_i32, %c0_i32_268 : i32
      %536 = arith.select %535, %c-1_i32_269, %c1_i32_267 : i32
      %537 = arith.addi %536, %534#0 : i32
      %538 = arith.divsi %537, %c64_i32 : i32
      %539 = arith.addi %c1_i32_267, %538 : i32
      %540 = arith.subi %c0_i32_268, %534#0 : i32
      %541 = arith.divsi %540, %c64_i32 : i32
      %542 = arith.subi %c0_i32_268, %541 : i32
      %543 = arith.cmpi slt, %534#0, %c0_i32_268 : i32
      %544 = arith.cmpi sgt, %534#0, %c0_i32_268 : i32
      %545 = arith.cmpi slt, %c64_i32, %c0_i32_268 : i32
      %546 = arith.cmpi sgt, %c64_i32, %c0_i32_268 : i32
      %547 = arith.andi %543, %545 : i1
      %548 = arith.andi %544, %546 : i1
      %549 = arith.ori %547, %548 : i1
      %550 = arith.select %549, %539, %542 : i32
      %c1_i32_270 = arith.constant 1 : i32
      %c0_i32_271 = arith.constant 0 : i32
      %c-1_i32_272 = arith.constant -1 : i32
      %551 = arith.cmpi sgt, %c256_i32, %c0_i32_271 : i32
      %552 = arith.select %551, %c-1_i32_272, %c1_i32_270 : i32
      %553 = arith.addi %552, %534#1 : i32
      %554 = arith.divsi %553, %c256_i32 : i32
      %555 = arith.addi %c1_i32_270, %554 : i32
      %556 = arith.subi %c0_i32_271, %534#1 : i32
      %557 = arith.divsi %556, %c256_i32 : i32
      %558 = arith.subi %c0_i32_271, %557 : i32
      %559 = arith.cmpi slt, %534#1, %c0_i32_271 : i32
      %560 = arith.cmpi sgt, %534#1, %c0_i32_271 : i32
      %561 = arith.cmpi slt, %c256_i32, %c0_i32_271 : i32
      %562 = arith.cmpi sgt, %c256_i32, %c0_i32_271 : i32
      %563 = arith.andi %559, %561 : i1
      %564 = arith.andi %560, %562 : i1
      %565 = arith.ori %563, %564 : i1
      %566 = arith.select %565, %555, %558 : i32
      %shape_273 = cute.make_shape(%550, %566, %534#2, %534#3, %534#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"(64,256,?,?,((?,?),?))">
      %lay_274 = cute.make_layout(%shape_273, %173) : !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %567 = cute.get_shape(%lay) : (!cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_275, %e1_276, %e2_277, %e3_278, %e4_279 = cute.get_leaves(%567) : !cute.shape<"(?,?,((?,?),?))">
      %itup_280 = cute.to_int_tuple(%e0_275) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %568 = cute.get_shape(%lay_156) : (!cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">) -> !cute.shape<"(?,?,((?,?),?))">
      %e0_281, %e1_282, %e2_283, %e3_284, %e4_285 = cute.get_leaves(%568) : !cute.shape<"(?,?,((?,?),?))">
      %itup_286 = cute.to_int_tuple(%e0_281) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %569 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %570 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      nvvm.cluster.wait
      cf.cond_br %245, ^bb39, ^bb239
    ^bb39:  // pred: ^bb38
      nvvm.setmaxregister  decrease 96
      %571 = arith.divsi %246, %c2_i32 : i32
      %572 = arith.muli %571, %c2_i32 : i32
      %573 = arith.cmpi ne, %246, %572 : i32
      %c0_i32_287 = arith.constant 0 : i32
      %574 = arith.cmpi slt, %246, %c0_i32_287 : i32
      %575 = arith.cmpi slt, %c2_i32, %c0_i32_287 : i32
      %576 = arith.cmpi ne, %574, %575 : i1
      %577 = arith.andi %573, %576 : i1
      %c-1_i32_288 = arith.constant -1 : i32
      %578 = arith.addi %571, %c-1_i32_288 : i32
      %579 = arith.select %577, %578, %571 : i32
      %int_tuple_289 = cute.make_int_tuple(%itup_286) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %580 = cute.get_scalars(%int_tuple_289) <{only_dynamic}> : !cute.int_tuple<"?">
      %c1_i32_290 = arith.constant 1 : i32
      %c0_i32_291 = arith.constant 0 : i32
      %c-1_i32_292 = arith.constant -1 : i32
      %581 = arith.cmpi sgt, %c256_i32, %c0_i32_291 : i32
      %582 = arith.select %581, %c-1_i32_292, %c1_i32_290 : i32
      %583 = arith.addi %582, %580 : i32
      %584 = arith.divsi %583, %c256_i32 : i32
      %585 = arith.addi %c1_i32_290, %584 : i32
      %586 = arith.subi %c0_i32_291, %580 : i32
      %587 = arith.divsi %586, %c256_i32 : i32
      %588 = arith.subi %c0_i32_291, %587 : i32
      %589 = arith.cmpi slt, %580, %c0_i32_291 : i32
      %590 = arith.cmpi sgt, %580, %c0_i32_291 : i32
      %591 = arith.cmpi slt, %c256_i32, %c0_i32_291 : i32
      %592 = arith.cmpi sgt, %c256_i32, %c0_i32_291 : i32
      %593 = arith.andi %589, %591 : i1
      %594 = arith.andi %590, %592 : i1
      %595 = arith.ori %593, %594 : i1
      %596 = arith.select %595, %585, %588 : i32
      %int_tuple_293 = cute.make_int_tuple(%596) : (i32) -> !cute.int_tuple<"?">
      %e0_294 = cute.get_leaves(%int_tuple_293) : !cute.int_tuple<"?">
      %sub = cute.tuple_sub(%e0_294, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %597 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %coord_295 = cute.make_coord(%579, %569, %570) : (i32, i32, i32) -> !cute.coord<"(_,?,_,(?,?))">
      %598:5 = cute.get_scalars(%lay_155) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">
      %shape_296 = cute.make_shape(%598#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_297 = cute.make_layout(%shape_296, %172) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@0)">
      %idx_298 = cute.crd2idx(%coord_295, %lay_155) : (!cute.coord<"(_,?,_,(?,?))">, !cute.layout<"(((64,64),1),?,?,((?,?),?)):(((1@0,1@1),0),128@1,64@0,((1@2,1@3),1@4))">) -> !cute.int_tuple<"(0,?{div=128},?,?,?)">
      %tup_299 = cute.add_offset(%tup, %idx_298) : (!cute.int_tuple<"(0,?{div=64},0,0,0)">, !cute.int_tuple<"(0,?{div=128},?,?,?)">) -> !cute.int_tuple<"(0,?{div=64},?,?,?)">
      %coord_300 = cute.make_coord(%569, %570) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %599:5 = cute.get_scalars(%lay_173) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">
      %shape_301 = cute.make_shape(%599#0, %599#1) : (i32, i32) -> !cute.shape<"(((64,128),1),?,?)">
      %lay_302 = cute.make_layout(%shape_301, %171) : !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">
      %idx_303 = cute.crd2idx(%coord_300, %lay_173) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(((64,128),1),?,?,((?,?),?)):(((1@0,1@1),0),256@1,64@0,((0,1@2),1@3))">) -> !cute.int_tuple<"(0,0,?,?)">
      %tup_304 = cute.add_offset(%tup_167, %idx_303) : (!cute.int_tuple<"(0,?{div=128},0,0)">, !cute.int_tuple<"(0,0,?,?)">) -> !cute.int_tuple<"(0,?{div=128},?,?)">
      %coord_305 = cute.make_coord(%569, %570) : (i32, i32) -> !cute.coord<"(_,_,(?,?))">
      %600:4 = cute.get_scalars(%lay_201) <{only_dynamic}> : !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">
      %shape_306 = cute.make_shape(%600#0) : (i32) -> !cute.shape<"(((128,1),1),?)">
      %lay_307 = cute.make_layout(%shape_306, %170) : !cute.layout<"(((128,1),1),?):(((1@0,0),0),256@0)">
      %idx_308 = cute.crd2idx(%coord_305, %lay_201) : (!cute.coord<"(_,_,(?,?))">, !cute.layout<"(((128,1),1),?,((?,?),?)):(((1@0,0),0),256@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(0,?,?)">
      %tup_309 = cute.add_offset(%int_tuple_202, %idx_308) : (!cute.int_tuple<"(?{div=128},0,0)">, !cute.int_tuple<"(0,?,?)">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %601:5 = cute.get_scalars(%lay_219) <{only_dynamic}> : !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">
      %shape_310 = cute.make_shape(%601#0, %601#1) : (i32, i32) -> !cute.shape<"(((64,64),2),?,?)">
      %lay_311 = cute.make_layout(%shape_310, %169) : !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">
      %idx_312 = cute.crd2idx(%coord_300, %lay_219) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(((64,64),2),?,?,((?,?),?)):(((1@0,1@1),64@0),256@0,64@1,((0,1@2),1@3))">) -> !cute.int_tuple<"(0,0,?,?)">
      %tup_313 = cute.add_offset(%tup_213, %idx_312) : (!cute.int_tuple<"(?{div=128},0,0,0)">, !cute.int_tuple<"(0,0,?,?)">) -> !cute.int_tuple<"(?{div=128},0,?,?)">
      %602:4 = cute.get_scalars(%lay_239) <{only_dynamic}> : !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">
      %shape_314 = cute.make_shape(%602#0) : (i32) -> !cute.shape<"(((64,1),1),?)">
      %lay_315 = cute.make_layout(%shape_314, %168) : !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">
      %idx_316 = cute.crd2idx(%coord_305, %lay_239) : (!cute.coord<"(_,_,(?,?))">, !cute.layout<"(((64,1),1),?,((?,?),?)):(((1@0,0),0),64@0,((0,1@1),1@2))">) -> !cute.int_tuple<"(0,?,?)">
      %tup_317 = cute.add_offset(%189, %idx_316) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?,?)">) -> !cute.int_tuple<"(0,?,?)">
      %e0_318, %e1_319, %e2_320 = cute.get_leaves(%tup_309) : !cute.int_tuple<"(?{div=128},?,?)">
      %int_tuple_321 = cute.make_int_tuple(%e0_318, %e1_319, %e2_320) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %603 = cute_nvgpu.atom.make_exec_tma(%arg6) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %604 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %605:3 = cute.get_scalars(%int_tuple_321) : !cute.int_tuple<"(?{div=128},?,?)">
      %606 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>
      %607 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %608 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %609 = cute_nvgpu.atom.make_exec_tma(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %610 = cute_nvgpu.atom.make_exec_tma(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %sub_322 = cute.tuple_sub(%sub, %212) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%sub_322, %209) : (!cute.int_tuple<"?">, !cute.int_tuple<"4">) -> !cute.int_tuple<"?{div=4}">
      %611 = cute_nvgpu.atom.make_exec_tma(%arg10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>) -> !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %mul_323 = cute.tuple_mul(%sub_322, %209) : (!cute.int_tuple<"?">, !cute.int_tuple<"4">) -> !cute.int_tuple<"?{div=4}">
      %612 = cute_nvgpu.atom.make_exec_tma(%arg8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>) -> !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      cf.br ^bb40(%c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c1_i32, %true : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb40(%613: i32, %614: i32, %615: i32, %616: i32, %617: i32, %618: i32, %619: i32, %620: i32, %621: i32, %622: i32, %623: i32, %624: i32, %625: i1):  // 2 preds: ^bb39, ^bb151
      cf.cond_br %625, ^bb41(%613, %614, %615, %616, %617, %618, %619, %620, %621, %622, %623, %624, %625 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1), ^bb152
    ^bb41(%626: i32, %627: i32, %628: i32, %629: i32, %630: i32, %631: i32, %632: i32, %633: i32, %634: i32, %635: i32, %636: i32, %637: i32, %638: i1):  // pred: ^bb40
      %int_tuple_324 = cute.make_int_tuple(%630) : (i32) -> !cute.int_tuple<"?">
      %ptr_325 = cute.add_offset(%ptr_66, %int_tuple_324) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %639 = builtin.unrealized_conversion_cast %ptr_325 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %639, %631, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %640 = nvvm.elect.sync -> i1
      cf.cond_br %640, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %ptr_326 = cute.add_offset(%iter_61, %int_tuple_324) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %641 = builtin.unrealized_conversion_cast %ptr_326 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %641, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %642 = arith.addi %630, %c1_i32 : i32
      %643 = arith.addi %629, %c1_i32 : i32
      %644 = arith.cmpi eq, %642, %c5_i32 : i32
      %645 = arith.select %644, %c0_i32, %642 : i32
      cf.cond_br %644, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %646 = arith.xori %631, %c1_i32 : i32
      cf.br ^bb46(%646 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%631 : i32)
    ^bb46(%647: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_327 = cute.make_coord(%630) : (i32) -> !cute.coord<"(_,?)">
      %idx_328 = cute.crd2idx(%coord_327, %185) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),5):(((1,0),0),128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_329 = cute.add_offset(%iter_125, %idx_328) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem, align<256>>
      %ptr_330 = cute.add_offset(%iter_61, %int_tuple_324) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %648 = cute_nvgpu.atom.set_value(%603, %ptr_330 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %649 = cute_nvgpu.atom.get_value(%648 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %650 = cute_nvgpu.atom.get_value(%648 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%648 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%651: i32):  // 2 preds: ^bb47, ^bb49
      %652 = arith.cmpi slt, %651, %604 : i32
      cf.cond_br %652, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_329 : !cute.ptr<bf16, smem, align<256>>, %649 : !cute.ptr<smem, align<8>>, [%605#0, %605#1, %605#2] : i32, i32, i32) cache_policy = %650 mode = <tiled> num_cta = 1 : i32
      %653 = arith.addi %651, %c1_i32 : i32
      cf.br ^bb48(%653 : i32)
    ^bb50:  // pred: ^bb48
      cf.br ^bb51(%c0_i32, %632, %633, %634, %626, %627, %628 : i32, i32, i32, i32, i32, i32, i32)
    ^bb51(%654: i32, %655: i32, %656: i32, %657: i32, %658: i32, %659: i32, %660: i32):  // 2 preds: ^bb50, ^bb72
      %661 = arith.cmpi slt, %654, %c8_i32 : i32
      cf.cond_br %661, ^bb52, ^bb73 {loop_annotation = #loop_annotation1}
    ^bb52:  // pred: ^bb51
      %int_tuple_331 = cute.make_int_tuple(%656) : (i32) -> !cute.int_tuple<"?">
      %ptr_332 = cute.add_offset(%ptr_22, %int_tuple_331) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %662 = builtin.unrealized_conversion_cast %ptr_332 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %662, %657, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %285, ^bb53, ^bb56
    ^bb53:  // pred: ^bb52
      %663 = nvvm.elect.sync -> i1
      cf.cond_br %663, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %ptr_333 = cute.add_offset(%iter_14, %int_tuple_331) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %664 = builtin.unrealized_conversion_cast %ptr_333 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %664, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // 2 preds: ^bb52, ^bb55
      %665 = arith.addi %656, %c1_i32 : i32
      %666 = arith.addi %655, %c1_i32 : i32
      %667 = arith.cmpi eq, %665, %c8_i32 : i32
      %668 = arith.select %667, %c0_i32, %665 : i32
      cf.cond_br %667, ^bb57, ^bb58
    ^bb57:  // pred: ^bb56
      %669 = arith.xori %657, %c1_i32 : i32
      cf.br ^bb59(%669 : i32)
    ^bb58:  // pred: ^bb56
      cf.br ^bb59(%657 : i32)
    ^bb59(%670: i32):  // 2 preds: ^bb57, ^bb58
      cf.br ^bb60
    ^bb60:  // pred: ^bb59
      %coord_334 = cute.make_coord(%654) : (i32) -> !cute.coord<"(_,?)">
      %idx_335 = cute.crd2idx(%coord_334, %lay_297) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_336 = cute.add_offset(%tup_299, %idx_335) : (!cute.int_tuple<"(0,?{div=64},?,?,?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %e0_337, %e1_338, %e2_339, %e3_340, %e4_341 = cute.get_leaves(%tup_336) : !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %coord_342 = cute.make_coord(%656) : (i32) -> !cute.coord<"(_,?)">
      %idx_343 = cute.crd2idx(%coord_342, %167) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),8):((1,0),4096)">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_344 = cute.add_offset(%iter_118, %idx_343) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<bf16, smem, align<512>, S<3,4,3>>
      %ptr_345 = cute.add_offset(%iter_14, %int_tuple_331) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_346 = cute.make_int_tuple(%e0_337, %e1_338, %e2_339, %e3_340, %e4_341) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      %671 = cute_nvgpu.atom.set_value(%606, %ptr_345 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>
      %672 = cute_nvgpu.atom.get_value(%671 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %673 = cute_nvgpu.atom.get_value(%671 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_347 = cute_nvgpu.get_tma_desc_addr(%671 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 65536, mode = tiled, num_cta = 2, g_stride = <"()"> tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">>) -> !cute.ptr<generic, align<64>>
      %674:5 = cute.get_scalars(%int_tuple_346) : !cute.int_tuple<"(?{div=64},?{div=64},?,?,?)">
      cf.br ^bb61(%c0_i32 : i32)
    ^bb61(%675: i32):  // 2 preds: ^bb60, ^bb62
      %676 = arith.cmpi slt, %675, %604 : i32
      cf.cond_br %676, ^bb62, ^bb63 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_347 : !cute.ptr<generic, align<64>>, %ptr_344 : !cute.ptr<bf16, smem, align<512>, S<3,4,3>>, %672 : !cute.ptr<smem, align<8>>, [%674#0, %674#1, %674#2, %674#3, %674#4] : i32, i32, i32, i32, i32) cache_policy = %673 mode = <tiled> num_cta = 2 : i32
      %677 = arith.addi %675, %c1_i32 : i32
      cf.br ^bb61(%677 : i32)
    ^bb63:  // pred: ^bb61
      %int_tuple_348 = cute.make_int_tuple(%659) : (i32) -> !cute.int_tuple<"?">
      %ptr_349 = cute.add_offset(%ptr_51, %int_tuple_348) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %678 = builtin.unrealized_conversion_cast %ptr_349 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %678, %660, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %679 = nvvm.elect.sync -> i1
      cf.cond_br %679, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      %ptr_350 = cute.add_offset(%iter_46, %int_tuple_348) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %680 = builtin.unrealized_conversion_cast %ptr_350 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %680, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %681 = arith.addi %659, %c1_i32 : i32
      %682 = arith.addi %658, %c1_i32 : i32
      %683 = arith.cmpi eq, %681, %c5_i32 : i32
      %684 = arith.select %683, %c0_i32, %681 : i32
      cf.cond_br %683, ^bb66, ^bb67
    ^bb66:  // pred: ^bb65
      %685 = arith.xori %660, %c1_i32 : i32
      cf.br ^bb68(%685 : i32)
    ^bb67:  // pred: ^bb65
      cf.br ^bb68(%660 : i32)
    ^bb68(%686: i32):  // 2 preds: ^bb66, ^bb67
      cf.br ^bb69
    ^bb69:  // pred: ^bb68
      %coord_351 = cute.make_coord(%654) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_352 = cute.crd2idx(%coord_351, %lay_302) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_353 = cute.add_offset(%tup_304, %idx_352) : (!cute.int_tuple<"(0,?{div=128},?,?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %e0_354, %e1_355, %e2_356, %e3_357 = cute.get_leaves(%tup_353) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %coord_358 = cute.make_coord(%659) : (i32) -> !cute.coord<"(_,?)">
      %idx_359 = cute.crd2idx(%coord_358, %166) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),5):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_360 = cute.add_offset(%iter_135, %idx_359) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %ptr_361 = cute.add_offset(%iter_46, %int_tuple_348) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_362 = cute.make_int_tuple(%e0_354, %e1_355, %e2_356, %e3_357) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %687 = cute_nvgpu.atom.set_value(%607, %ptr_361 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %688 = cute_nvgpu.atom.get_value(%687 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %689 = cute_nvgpu.atom.get_value(%687 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_363 = cute_nvgpu.get_tma_desc_addr(%687 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %690:4 = cute.get_scalars(%int_tuple_362) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      cf.br ^bb70(%c0_i32 : i32)
    ^bb70(%691: i32):  // 2 preds: ^bb69, ^bb71
      %692 = arith.cmpi slt, %691, %604 : i32
      cf.cond_br %692, ^bb71, ^bb72 {llvm.loop_annotation = #loop_annotation}
    ^bb71:  // pred: ^bb70
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_363 : !cute.ptr<generic, align<64>>, %ptr_360 : !cute.ptr<i8, smem, align<256>, S<2,4,3>>, %688 : !cute.ptr<smem, align<8>>, [%690#0, %690#1, %690#2, %690#3] : i32, i32, i32, i32) cache_policy = %689 mode = <tiled> num_cta = 1 : i32
      %693 = arith.addi %691, %c1_i32 : i32
      cf.br ^bb70(%693 : i32)
    ^bb72:  // pred: ^bb70
      %694 = arith.addi %654, %c1_i32 : i32
      cf.br ^bb51(%694, %666, %668, %670, %682, %684, %686 : i32, i32, i32, i32, i32, i32, i32)
    ^bb73:  // pred: ^bb51
      cf.br ^bb74(%c1_i32, %658, %659, %660, %643, %645, %647, %635, %636, %637 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb74(%695: i32, %696: i32, %697: i32, %698: i32, %699: i32, %700: i32, %701: i32, %702: i32, %703: i32, %704: i32):  // 2 preds: ^bb73, ^bb123
      %705 = arith.cmpi slt, %695, %597 : i32
      cf.cond_br %705, ^bb75, ^bb124 {loop_annotation = #loop_annotation2}
    ^bb75:  // pred: ^bb74
      %int_tuple_364 = cute.make_int_tuple(%700) : (i32) -> !cute.int_tuple<"?">
      %ptr_365 = cute.add_offset(%ptr_66, %int_tuple_364) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %706 = builtin.unrealized_conversion_cast %ptr_365 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %706, %701, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %707 = nvvm.elect.sync -> i1
      cf.cond_br %707, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %ptr_366 = cute.add_offset(%iter_61, %int_tuple_364) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %708 = builtin.unrealized_conversion_cast %ptr_366 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %708, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %709 = arith.addi %700, %c1_i32 : i32
      %710 = arith.addi %699, %c1_i32 : i32
      %711 = arith.cmpi eq, %709, %c5_i32 : i32
      %712 = arith.select %711, %c0_i32, %709 : i32
      cf.cond_br %711, ^bb78, ^bb79
    ^bb78:  // pred: ^bb77
      %713 = arith.xori %701, %c1_i32 : i32
      cf.br ^bb80(%713 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%701 : i32)
    ^bb80(%714: i32):  // 2 preds: ^bb78, ^bb79
      cf.br ^bb81
    ^bb81:  // pred: ^bb80
      %coord_367 = cute.make_coord(%695) : (i32) -> !cute.coord<"(_,?)">
      %idx_368 = cute.crd2idx(%coord_367, %lay_307) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),?):(((1@0,0),0),256@0)">) -> !cute.int_tuple<"(?{div=256})">
      %tup_369 = cute.add_offset(%tup_309, %idx_368) : (!cute.int_tuple<"(?{div=128},?,?)">, !cute.int_tuple<"(?{div=256})">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %e0_370, %e1_371, %e2_372 = cute.get_leaves(%tup_369) : !cute.int_tuple<"(?{div=128},?,?)">
      %coord_373 = cute.make_coord(%700) : (i32) -> !cute.coord<"(_,?)">
      %idx_374 = cute.crd2idx(%coord_373, %185) : (!cute.coord<"(_,?)">, !cute.layout<"(((128,1),1),5):(((1,0),0),128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_375 = cute.add_offset(%iter_125, %idx_374) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem, align<256>>
      %ptr_376 = cute.add_offset(%iter_61, %int_tuple_364) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_377 = cute.make_int_tuple(%e0_370, %e1_371, %e2_372) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?,?)">
      %715 = cute_nvgpu.atom.set_value(%603, %ptr_376 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>
      %716 = cute_nvgpu.atom.get_value(%715 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %717 = cute_nvgpu.atom.get_value(%715 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_378 = cute_nvgpu.get_tma_desc_addr(%715 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 2048, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      %718:3 = cute.get_scalars(%int_tuple_377) : !cute.int_tuple<"(?{div=128},?,?)">
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%719: i32):  // 2 preds: ^bb81, ^bb83
      %720 = arith.cmpi slt, %719, %604 : i32
      cf.cond_br %720, ^bb83, ^bb84 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_378 : !cute.ptr<generic, align<64>>, %ptr_375 : !cute.ptr<bf16, smem, align<256>>, %716 : !cute.ptr<smem, align<8>>, [%718#0, %718#1, %718#2] : i32, i32, i32) cache_policy = %717 mode = <tiled> num_cta = 1 : i32
      %721 = arith.addi %719, %c1_i32 : i32
      cf.br ^bb82(%721 : i32)
    ^bb84:  // pred: ^bb82
      cf.br ^bb85(%c0_i32, %696, %697, %698 : i32, i32, i32, i32)
    ^bb85(%722: i32, %723: i32, %724: i32, %725: i32):  // 2 preds: ^bb84, ^bb95
      %726 = arith.cmpi slt, %722, %c8_i32 : i32
      cf.cond_br %726, ^bb86, ^bb96 {loop_annotation = #loop_annotation1}
    ^bb86:  // pred: ^bb85
      %int_tuple_379 = cute.make_int_tuple(%724) : (i32) -> !cute.int_tuple<"?">
      %ptr_380 = cute.add_offset(%ptr_51, %int_tuple_379) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %727 = builtin.unrealized_conversion_cast %ptr_380 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %727, %725, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %728 = nvvm.elect.sync -> i1
      cf.cond_br %728, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %ptr_381 = cute.add_offset(%iter_46, %int_tuple_379) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %729 = builtin.unrealized_conversion_cast %ptr_381 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %729, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %730 = arith.addi %724, %c1_i32 : i32
      %731 = arith.addi %723, %c1_i32 : i32
      %732 = arith.cmpi eq, %730, %c5_i32 : i32
      %733 = arith.select %732, %c0_i32, %730 : i32
      cf.cond_br %732, ^bb89, ^bb90
    ^bb89:  // pred: ^bb88
      %734 = arith.xori %725, %c1_i32 : i32
      cf.br ^bb91(%734 : i32)
    ^bb90:  // pred: ^bb88
      cf.br ^bb91(%725 : i32)
    ^bb91(%735: i32):  // 2 preds: ^bb89, ^bb90
      cf.br ^bb92
    ^bb92:  // pred: ^bb91
      %coord_382 = cute.make_coord(%695, %722) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_383 = cute.crd2idx(%coord_382, %lay_302) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,128),1),?,?):(((1@0,1@1),0),256@1,64@0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %tup_384 = cute.add_offset(%tup_304, %idx_383) : (!cute.int_tuple<"(0,?{div=128},?,?)">, !cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %e0_385, %e1_386, %e2_387, %e3_388 = cute.get_leaves(%tup_384) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %coord_389 = cute.make_coord(%724) : (i32) -> !cute.coord<"(_,?)">
      %idx_390 = cute.crd2idx(%coord_389, %166) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),5):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_391 = cute.add_offset(%iter_135, %idx_390) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>, S<2,4,3>>
      %ptr_392 = cute.add_offset(%iter_46, %int_tuple_379) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_393 = cute.make_int_tuple(%e0_385, %e1_386, %e2_387, %e3_388) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      %736 = cute_nvgpu.atom.set_value(%608, %ptr_392 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>
      %737 = cute_nvgpu.atom.get_value(%736 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %738 = cute_nvgpu.atom.get_value(%736 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_394 = cute_nvgpu.get_tma_desc_addr(%736 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %739:4 = cute.get_scalars(%int_tuple_393) : !cute.int_tuple<"(?{div=64},?{div=128},?,?)">
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%740: i32):  // 2 preds: ^bb92, ^bb94
      %741 = arith.cmpi slt, %740, %604 : i32
      cf.cond_br %741, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_394 : !cute.ptr<generic, align<64>>, %ptr_391 : !cute.ptr<i8, smem, align<256>, S<2,4,3>>, %737 : !cute.ptr<smem, align<8>>, [%739#0, %739#1, %739#2, %739#3] : i32, i32, i32, i32) cache_policy = %738 mode = <tiled> num_cta = 1 : i32
      %742 = arith.addi %740, %c1_i32 : i32
      cf.br ^bb93(%742 : i32)
    ^bb95:  // pred: ^bb93
      %743 = arith.addi %722, %c1_i32 : i32
      cf.br ^bb85(%743, %731, %733, %735 : i32, i32, i32, i32)
    ^bb96:  // pred: ^bb85
      %744 = arith.subi %695, %c1_i32 : i32
      %int_tuple_395 = cute.make_int_tuple(%703) : (i32) -> !cute.int_tuple<"?">
      %ptr_396 = cute.add_offset(%ptr_82, %int_tuple_395) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %745 = builtin.unrealized_conversion_cast %ptr_396 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %745, %704, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %746 = nvvm.elect.sync -> i1
      cf.cond_br %746, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      %ptr_397 = cute.add_offset(%iter_77, %int_tuple_395) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %747 = builtin.unrealized_conversion_cast %ptr_397 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %747, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %748 = arith.addi %703, %c1_i32 : i32
      %749 = arith.addi %702, %c1_i32 : i32
      %750 = arith.cmpi eq, %748, %c5_i32 : i32
      %751 = arith.select %750, %c0_i32, %748 : i32
      cf.cond_br %750, ^bb99, ^bb100
    ^bb99:  // pred: ^bb98
      %752 = arith.xori %704, %c1_i32 : i32
      cf.br ^bb101(%752 : i32)
    ^bb100:  // pred: ^bb98
      cf.br ^bb101(%704 : i32)
    ^bb101(%753: i32):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %754 = arith.muli %744, %c4_i32 : i32
      %ptr_398 = cute.add_offset(%iter_77, %int_tuple_395) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %755 = cute_nvgpu.atom.set_value(%609, %ptr_398 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %756 = cute_nvgpu.atom.get_value(%755 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %757 = cute_nvgpu.atom.get_value(%755 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_399 = cute_nvgpu.get_tma_desc_addr(%755 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%758: i32):  // 2 preds: ^bb102, ^bb107
      %759 = arith.cmpi slt, %758, %c4_i32 : i32
      cf.cond_br %759, ^bb104, ^bb108 {loop_annotation = #loop_annotation1}
    ^bb104:  // pred: ^bb103
      %760 = arith.addi %754, %758 : i32
      %coord_400 = cute.make_coord(%760) : (i32) -> !cute.coord<"(_,?)">
      %idx_401 = cute.crd2idx(%coord_400, %lay_315) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">) -> !cute.int_tuple<"(?{div=64})">
      %tup_402 = cute.add_offset(%tup_317, %idx_401) : (!cute.int_tuple<"(0,?,?)">, !cute.int_tuple<"(?{div=64})">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %e0_403, %e1_404, %e2_405 = cute.get_leaves(%tup_402) : !cute.int_tuple<"(?{div=64},?,?)">
      %coord_406 = cute.make_coord(%758, %703) : (i32, i32) -> !cute.coord<"(_,(?,?))">
      %idx_407 = cute.crd2idx(%coord_406, %177) : (!cute.coord<"(_,(?,?))">, !cute.layout<"(((64,1),1),(4,5)):(((1,0),0),(64,256))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_408 = cute.add_offset(%iter_128, %idx_407) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>>
      %int_tuple_409 = cute.make_int_tuple(%e0_403, %e1_404, %e2_405) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %761:3 = cute.get_scalars(%int_tuple_409) : !cute.int_tuple<"(?{div=64},?,?)">
      cf.br ^bb105(%c0_i32 : i32)
    ^bb105(%762: i32):  // 2 preds: ^bb104, ^bb106
      %763 = arith.cmpi slt, %762, %604 : i32
      cf.cond_br %763, ^bb106, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb106:  // pred: ^bb105
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_399 : !cute.ptr<generic, align<64>>, %ptr_408 : !cute.ptr<bf16, smem, align<128>>, %756 : !cute.ptr<smem, align<8>>, [%761#0, %761#1, %761#2] : i32, i32, i32) cache_policy = %757 mode = <tiled> num_cta = 1 : i32
      %764 = arith.addi %762, %c1_i32 : i32
      cf.br ^bb105(%764 : i32)
    ^bb107:  // pred: ^bb105
      %765 = arith.addi %758, %c1_i32 : i32
      cf.br ^bb103(%765 : i32)
    ^bb108:  // pred: ^bb103
      %766 = arith.muli %744, %c4_i32 : i32
      cf.br ^bb109(%c0_i32, %723, %724, %725 : i32, i32, i32, i32)
    ^bb109(%767: i32, %768: i32, %769: i32, %770: i32):  // 2 preds: ^bb108, ^bb122
      %771 = arith.cmpi slt, %767, %c4_i32 : i32
      cf.cond_br %771, ^bb110, ^bb123 {loop_annotation = #loop_annotation1}
    ^bb110:  // pred: ^bb109
      %772 = arith.addi %766, %767 : i32
      cf.br ^bb111(%c0_i32, %768, %769, %770 : i32, i32, i32, i32)
    ^bb111(%773: i32, %774: i32, %775: i32, %776: i32):  // 2 preds: ^bb110, ^bb121
      %777 = arith.cmpi slt, %773, %c2_i32 : i32
      cf.cond_br %777, ^bb112, ^bb122 {loop_annotation = #loop_annotation1}
    ^bb112:  // pred: ^bb111
      %int_tuple_410 = cute.make_int_tuple(%775) : (i32) -> !cute.int_tuple<"?">
      %ptr_411 = cute.add_offset(%ptr_51, %int_tuple_410) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %778 = builtin.unrealized_conversion_cast %ptr_411 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %778, %776, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %779 = nvvm.elect.sync -> i1
      cf.cond_br %779, ^bb113, ^bb114
    ^bb113:  // pred: ^bb112
      %ptr_412 = cute.add_offset(%iter_46, %int_tuple_410) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %780 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %780, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb112, ^bb113
      %781 = arith.addi %775, %c1_i32 : i32
      %782 = arith.addi %774, %c1_i32 : i32
      %783 = arith.cmpi eq, %781, %c5_i32 : i32
      %784 = arith.select %783, %c0_i32, %781 : i32
      cf.cond_br %783, ^bb115, ^bb116
    ^bb115:  // pred: ^bb114
      %785 = arith.xori %776, %c1_i32 : i32
      cf.br ^bb117(%785 : i32)
    ^bb116:  // pred: ^bb114
      cf.br ^bb117(%776 : i32)
    ^bb117(%786: i32):  // 2 preds: ^bb115, ^bb116
      cf.br ^bb118
    ^bb118:  // pred: ^bb117
      %coord_413 = cute.make_coord(%773, %772) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_414 = cute.crd2idx(%coord_413, %lay_311) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">) -> !cute.int_tuple<"(?{div=256},?{div=64})">
      %tup_415 = cute.add_offset(%tup_313, %idx_414) : (!cute.int_tuple<"(?{div=128},0,?,?)">, !cute.int_tuple<"(?{div=256},?{div=64})">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %e0_416, %e1_417, %e2_418, %e3_419 = cute.get_leaves(%tup_415) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %coord_420 = cute.make_coord(%775) : (i32) -> !cute.coord<"(_,?)">
      %idx_421 = cute.crd2idx(%coord_420, %165) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,2),5):((1,4096),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_422 = cute.add_offset(%iter_136, %idx_421) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>>
      %ptr_423 = cute.add_offset(%iter_46, %int_tuple_410) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_424 = cute.make_int_tuple(%e0_416, %e1_417, %e2_418, %e3_419) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %787 = cute_nvgpu.atom.set_value(%610, %ptr_423 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %788 = cute_nvgpu.atom.get_value(%787 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %789 = cute_nvgpu.atom.get_value(%787 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_425 = cute_nvgpu.get_tma_desc_addr(%787 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %790:4 = cute.get_scalars(%int_tuple_424) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %tup_426 = cute.add_offset(%int_tuple_424, %164) : (!cute.int_tuple<"(?{div=128},?{div=64},?,?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      %ptr_427 = cute.add_offset(%ptr_422, %163) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"4096">) -> !cute.ptr<i8, smem, align<256>>
      %791:4 = cute.get_scalars(%tup_426) : !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      cf.br ^bb119(%c0_i32 : i32)
    ^bb119(%792: i32):  // 2 preds: ^bb118, ^bb120
      %793 = arith.cmpi slt, %792, %604 : i32
      cf.cond_br %793, ^bb120, ^bb121 {llvm.loop_annotation = #loop_annotation}
    ^bb120:  // pred: ^bb119
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_425 : !cute.ptr<generic, align<64>>, %ptr_422 : !cute.ptr<i8, smem, align<256>>, %788 : !cute.ptr<smem, align<8>>, [%790#0, %790#1, %790#2, %790#3] : i32, i32, i32, i32) cache_policy = %789 mode = <tiled> num_cta = 1 : i32
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_425 : !cute.ptr<generic, align<64>>, %ptr_427 : !cute.ptr<i8, smem, align<256>>, %788 : !cute.ptr<smem, align<8>>, [%791#0, %791#1, %791#2, %791#3] : i32, i32, i32, i32) cache_policy = %789 mode = <tiled> num_cta = 1 : i32
      %794 = arith.addi %792, %c1_i32 : i32
      cf.br ^bb119(%794 : i32)
    ^bb121:  // pred: ^bb119
      %795 = arith.addi %773, %c1_i32 : i32
      cf.br ^bb111(%795, %782, %784, %786 : i32, i32, i32, i32)
    ^bb122:  // pred: ^bb111
      %796 = arith.addi %767, %c1_i32 : i32
      cf.br ^bb109(%796, %774, %775, %776 : i32, i32, i32, i32)
    ^bb123:  // pred: ^bb109
      %797 = arith.addi %695, %c1_i32 : i32
      cf.br ^bb74(%797, %768, %769, %770, %710, %712, %714, %749, %751, %753 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb124:  // pred: ^bb74
      %int_tuple_428 = cute.make_int_tuple(%703) : (i32) -> !cute.int_tuple<"?">
      %ptr_429 = cute.add_offset(%ptr_82, %int_tuple_428) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %798 = builtin.unrealized_conversion_cast %ptr_429 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %798, %704, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %799 = nvvm.elect.sync -> i1
      cf.cond_br %799, ^bb125, ^bb126
    ^bb125:  // pred: ^bb124
      %ptr_430 = cute.add_offset(%iter_77, %int_tuple_428) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %800 = builtin.unrealized_conversion_cast %ptr_430 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %800, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb126
    ^bb126:  // 2 preds: ^bb124, ^bb125
      %801 = arith.addi %703, %c1_i32 : i32
      %802 = arith.addi %702, %c1_i32 : i32
      %803 = arith.cmpi eq, %801, %c5_i32 : i32
      %804 = arith.select %803, %c0_i32, %801 : i32
      cf.cond_br %803, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %805 = arith.xori %704, %c1_i32 : i32
      cf.br ^bb129(%805 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%704 : i32)
    ^bb129(%806: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %ptr_431 = cute.add_offset(%iter_77, %int_tuple_428) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %807 = cute_nvgpu.atom.set_value(%611, %ptr_431 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>
      %808 = cute_nvgpu.atom.get_value(%807 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %809 = cute_nvgpu.atom.get_value(%807 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_432 = cute_nvgpu.get_tma_desc_addr(%807 : !cute_nvgpu.atom.tma_load<bf16, copy_bits = 1024, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">>) -> !cute.ptr<generic, align<64>>
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%810: i32):  // 2 preds: ^bb130, ^bb135
      %811 = arith.cmpi slt, %810, %c4_i32 : i32
      cf.cond_br %811, ^bb132, ^bb136 {loop_annotation = #loop_annotation1}
    ^bb132:  // pred: ^bb131
      %int_tuple_433 = cute.make_int_tuple(%810) : (i32) -> !cute.int_tuple<"?">
      %tup_434 = cute.add_offset(%mul, %int_tuple_433) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %coord_435 = cute.make_coord(%tup_434) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?)">
      %idx_436 = cute.crd2idx(%coord_435, %lay_315) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,1),1),?):(((1@0,0),0),64@0)">) -> !cute.int_tuple<"(?{div=64})">
      %tup_437 = cute.add_offset(%tup_317, %idx_436) : (!cute.int_tuple<"(0,?,?)">, !cute.int_tuple<"(?{div=64})">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %e0_438, %e1_439, %e2_440 = cute.get_leaves(%tup_437) : !cute.int_tuple<"(?{div=64},?,?)">
      %coord_441 = cute.make_coord(%810, %703) : (i32, i32) -> !cute.coord<"(_,(?,?))">
      %idx_442 = cute.crd2idx(%coord_441, %177) : (!cute.coord<"(_,(?,?))">, !cute.layout<"(((64,1),1),(4,5)):(((1,0),0),(64,256))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_443 = cute.add_offset(%iter_128, %idx_442) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>>
      %int_tuple_444 = cute.make_int_tuple(%e0_438, %e1_439, %e2_440) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?,?)">
      %812:3 = cute.get_scalars(%int_tuple_444) : !cute.int_tuple<"(?{div=64},?,?)">
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%813: i32):  // 2 preds: ^bb132, ^bb134
      %814 = arith.cmpi slt, %813, %604 : i32
      cf.cond_br %814, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_432 : !cute.ptr<generic, align<64>>, %ptr_443 : !cute.ptr<bf16, smem, align<128>>, %808 : !cute.ptr<smem, align<8>>, [%812#0, %812#1, %812#2] : i32, i32, i32) cache_policy = %809 mode = <tiled> num_cta = 1 : i32
      %815 = arith.addi %813, %c1_i32 : i32
      cf.br ^bb133(%815 : i32)
    ^bb135:  // pred: ^bb133
      %816 = arith.addi %810, %c1_i32 : i32
      cf.br ^bb131(%816 : i32)
    ^bb136:  // pred: ^bb131
      cf.br ^bb137(%c0_i32, %696, %697, %698 : i32, i32, i32, i32)
    ^bb137(%817: i32, %818: i32, %819: i32, %820: i32):  // 2 preds: ^bb136, ^bb150
      %821 = arith.cmpi slt, %817, %c4_i32 : i32
      cf.cond_br %821, ^bb138, ^bb151 {loop_annotation = #loop_annotation1}
    ^bb138:  // pred: ^bb137
      %int_tuple_445 = cute.make_int_tuple(%817) : (i32) -> !cute.int_tuple<"?">
      %tup_446 = cute.add_offset(%mul_323, %int_tuple_445) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      cf.br ^bb139(%c0_i32, %818, %819, %820 : i32, i32, i32, i32)
    ^bb139(%822: i32, %823: i32, %824: i32, %825: i32):  // 2 preds: ^bb138, ^bb149
      %826 = arith.cmpi slt, %822, %c2_i32 : i32
      cf.cond_br %826, ^bb140, ^bb150 {loop_annotation = #loop_annotation1}
    ^bb140:  // pred: ^bb139
      %int_tuple_447 = cute.make_int_tuple(%824) : (i32) -> !cute.int_tuple<"?">
      %ptr_448 = cute.add_offset(%ptr_51, %int_tuple_447) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %827 = builtin.unrealized_conversion_cast %ptr_448 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %827, %825, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %828 = nvvm.elect.sync -> i1
      cf.cond_br %828, ^bb141, ^bb142
    ^bb141:  // pred: ^bb140
      %ptr_449 = cute.add_offset(%iter_46, %int_tuple_447) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %829 = builtin.unrealized_conversion_cast %ptr_449 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %829, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb142
    ^bb142:  // 2 preds: ^bb140, ^bb141
      %830 = arith.addi %824, %c1_i32 : i32
      %831 = arith.addi %823, %c1_i32 : i32
      %832 = arith.cmpi eq, %830, %c5_i32 : i32
      %833 = arith.select %832, %c0_i32, %830 : i32
      cf.cond_br %832, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %834 = arith.xori %825, %c1_i32 : i32
      cf.br ^bb145(%834 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%825 : i32)
    ^bb145(%835: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %coord_450 = cute.make_coord(%822, %tup_446) : (i32, !cute.int_tuple<"?">) -> !cute.coord<"(_,?,?)">
      %idx_451 = cute.crd2idx(%coord_450, %lay_311) : (!cute.coord<"(_,?,?)">, !cute.layout<"(((64,64),2),?,?):(((1@0,1@1),64@0),256@0,64@1)">) -> !cute.int_tuple<"(?{div=256},?{div=64})">
      %tup_452 = cute.add_offset(%tup_313, %idx_451) : (!cute.int_tuple<"(?{div=128},0,?,?)">, !cute.int_tuple<"(?{div=256},?{div=64})">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %e0_453, %e1_454, %e2_455, %e3_456 = cute.get_leaves(%tup_452) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %coord_457 = cute.make_coord(%824) : (i32) -> !cute.coord<"(_,?)">
      %idx_458 = cute.crd2idx(%coord_457, %165) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,2),5):((1,4096),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_459 = cute.add_offset(%iter_136, %idx_458) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<256>>
      %ptr_460 = cute.add_offset(%iter_46, %int_tuple_447) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_461 = cute.make_int_tuple(%e0_453, %e1_454, %e2_455, %e3_456) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %836 = cute_nvgpu.atom.set_value(%612, %ptr_460 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>
      %837 = cute_nvgpu.atom.get_value(%836 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %838 = cute_nvgpu.atom.get_value(%836 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_462 = cute_nvgpu.get_tma_desc_addr(%836 : !cute_nvgpu.atom.tma_load<i8, copy_bits = 32768, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">>) -> !cute.ptr<generic, align<64>>
      %839:4 = cute.get_scalars(%int_tuple_461) : !cute.int_tuple<"(?{div=128},?{div=64},?,?)">
      %tup_463 = cute.add_offset(%int_tuple_461, %164) : (!cute.int_tuple<"(?{div=128},?{div=64},?,?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      %ptr_464 = cute.add_offset(%ptr_459, %163) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"4096">) -> !cute.ptr<i8, smem, align<256>>
      %840:4 = cute.get_scalars(%tup_463) : !cute.int_tuple<"(?{div=64},?{div=64},?,?)">
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%841: i32):  // 2 preds: ^bb146, ^bb148
      %842 = arith.cmpi slt, %841, %604 : i32
      cf.cond_br %842, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation}
    ^bb148:  // pred: ^bb147
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_462 : !cute.ptr<generic, align<64>>, %ptr_459 : !cute.ptr<i8, smem, align<256>>, %837 : !cute.ptr<smem, align<8>>, [%839#0, %839#1, %839#2, %839#3] : i32, i32, i32, i32) cache_policy = %838 mode = <tiled> num_cta = 1 : i32
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_462 : !cute.ptr<generic, align<64>>, %ptr_464 : !cute.ptr<i8, smem, align<256>>, %837 : !cute.ptr<smem, align<8>>, [%840#0, %840#1, %840#2, %840#3] : i32, i32, i32, i32) cache_policy = %838 mode = <tiled> num_cta = 1 : i32
      %843 = arith.addi %841, %c1_i32 : i32
      cf.br ^bb147(%843 : i32)
    ^bb149:  // pred: ^bb147
      %844 = arith.addi %822, %c1_i32 : i32
      cf.br ^bb139(%844, %831, %833, %835 : i32, i32, i32, i32)
    ^bb150:  // pred: ^bb139
      %845 = arith.addi %817, %c1_i32 : i32
      cf.br ^bb137(%845, %823, %824, %825 : i32, i32, i32, i32)
    ^bb151:  // pred: ^bb137
      cf.br ^bb40(%818, %819, %820, %699, %700, %701, %655, %656, %657, %802, %804, %806, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb152:  // pred: ^bb40
      %846 = arith.addi %614, %c1_i32 : i32
      %847 = arith.cmpi eq, %846, %c5_i32 : i32
      %848 = arith.select %847, %c0_i32, %846 : i32
      cf.cond_br %847, ^bb153, ^bb154
    ^bb153:  // pred: ^bb152
      %849 = arith.xori %615, %c1_i32 : i32
      cf.br ^bb155(%849 : i32)
    ^bb154:  // pred: ^bb152
      cf.br ^bb155(%615 : i32)
    ^bb155(%850: i32):  // 2 preds: ^bb153, ^bb154
      cf.br ^bb156
    ^bb156:  // pred: ^bb155
      %851 = arith.addi %848, %c1_i32 : i32
      %852 = arith.cmpi eq, %851, %c5_i32 : i32
      %853 = arith.select %852, %c0_i32, %851 : i32
      cf.cond_br %852, ^bb157, ^bb158
    ^bb157:  // pred: ^bb156
      %854 = arith.xori %850, %c1_i32 : i32
      cf.br ^bb159(%854 : i32)
    ^bb158:  // pred: ^bb156
      cf.br ^bb159(%850 : i32)
    ^bb159(%855: i32):  // 2 preds: ^bb157, ^bb158
      cf.br ^bb160
    ^bb160:  // pred: ^bb159
      %856 = arith.addi %853, %c1_i32 : i32
      %857 = arith.cmpi eq, %856, %c5_i32 : i32
      %858 = arith.select %857, %c0_i32, %856 : i32
      cf.cond_br %857, ^bb161, ^bb162
    ^bb161:  // pred: ^bb160
      %859 = arith.xori %855, %c1_i32 : i32
      cf.br ^bb163(%859 : i32)
    ^bb162:  // pred: ^bb160
      cf.br ^bb163(%855 : i32)
    ^bb163(%860: i32):  // 2 preds: ^bb161, ^bb162
      cf.br ^bb164
    ^bb164:  // pred: ^bb163
      %861 = arith.addi %858, %c1_i32 : i32
      %862 = arith.cmpi eq, %861, %c5_i32 : i32
      %863 = arith.select %862, %c0_i32, %861 : i32
      cf.cond_br %862, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %864 = arith.xori %860, %c1_i32 : i32
      cf.br ^bb167(%864 : i32)
    ^bb166:  // pred: ^bb164
      cf.br ^bb167(%860 : i32)
    ^bb167(%865: i32):  // 2 preds: ^bb165, ^bb166
      cf.br ^bb168
    ^bb168:  // pred: ^bb167
      %int_tuple_465 = cute.make_int_tuple(%863) : (i32) -> !cute.int_tuple<"?">
      %ptr_466 = cute.add_offset(%ptr_51, %int_tuple_465) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %866 = builtin.unrealized_conversion_cast %ptr_466 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %866, %865, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %867 = nvvm.elect.sync -> i1
      cf.cond_br %867, ^bb169, ^bb170
    ^bb169:  // pred: ^bb168
      %ptr_467 = cute.add_offset(%iter_46, %int_tuple_465) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %868 = builtin.unrealized_conversion_cast %ptr_467 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %868, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb170
    ^bb170:  // 2 preds: ^bb168, ^bb169
      %869 = arith.addi %617, %c1_i32 : i32
      %870 = arith.cmpi eq, %869, %c5_i32 : i32
      %871 = arith.select %870, %c0_i32, %869 : i32
      cf.cond_br %870, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      %872 = arith.xori %618, %c1_i32 : i32
      cf.br ^bb173(%872 : i32)
    ^bb172:  // pred: ^bb170
      cf.br ^bb173(%618 : i32)
    ^bb173(%873: i32):  // 2 preds: ^bb171, ^bb172
      cf.br ^bb174
    ^bb174:  // pred: ^bb173
      %874 = arith.addi %871, %c1_i32 : i32
      %875 = arith.cmpi eq, %874, %c5_i32 : i32
      %876 = arith.select %875, %c0_i32, %874 : i32
      cf.cond_br %875, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      %877 = arith.xori %873, %c1_i32 : i32
      cf.br ^bb177(%877 : i32)
    ^bb176:  // pred: ^bb174
      cf.br ^bb177(%873 : i32)
    ^bb177(%878: i32):  // 2 preds: ^bb175, ^bb176
      cf.br ^bb178
    ^bb178:  // pred: ^bb177
      %879 = arith.addi %876, %c1_i32 : i32
      %880 = arith.cmpi eq, %879, %c5_i32 : i32
      %881 = arith.select %880, %c0_i32, %879 : i32
      cf.cond_br %880, ^bb179, ^bb180
    ^bb179:  // pred: ^bb178
      %882 = arith.xori %878, %c1_i32 : i32
      cf.br ^bb181(%882 : i32)
    ^bb180:  // pred: ^bb178
      cf.br ^bb181(%878 : i32)
    ^bb181(%883: i32):  // 2 preds: ^bb179, ^bb180
      cf.br ^bb182
    ^bb182:  // pred: ^bb181
      %884 = arith.addi %881, %c1_i32 : i32
      %885 = arith.cmpi eq, %884, %c5_i32 : i32
      %886 = arith.select %885, %c0_i32, %884 : i32
      cf.cond_br %885, ^bb183, ^bb184
    ^bb183:  // pred: ^bb182
      %887 = arith.xori %883, %c1_i32 : i32
      cf.br ^bb185(%887 : i32)
    ^bb184:  // pred: ^bb182
      cf.br ^bb185(%883 : i32)
    ^bb185(%888: i32):  // 2 preds: ^bb183, ^bb184
      cf.br ^bb186
    ^bb186:  // pred: ^bb185
      %int_tuple_468 = cute.make_int_tuple(%886) : (i32) -> !cute.int_tuple<"?">
      %ptr_469 = cute.add_offset(%ptr_66, %int_tuple_468) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %889 = builtin.unrealized_conversion_cast %ptr_469 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %889, %888, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %890 = nvvm.elect.sync -> i1
      cf.cond_br %890, ^bb187, ^bb188
    ^bb187:  // pred: ^bb186
      %ptr_470 = cute.add_offset(%iter_61, %int_tuple_468) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %891 = builtin.unrealized_conversion_cast %ptr_470 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %891, %c256_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb188
    ^bb188:  // 2 preds: ^bb186, ^bb187
      %892 = arith.addi %623, %c1_i32 : i32
      %893 = arith.cmpi eq, %892, %c5_i32 : i32
      %894 = arith.select %893, %c0_i32, %892 : i32
      cf.cond_br %893, ^bb189, ^bb190
    ^bb189:  // pred: ^bb188
      %895 = arith.xori %624, %c1_i32 : i32
      cf.br ^bb191(%895 : i32)
    ^bb190:  // pred: ^bb188
      cf.br ^bb191(%624 : i32)
    ^bb191(%896: i32):  // 2 preds: ^bb189, ^bb190
      cf.br ^bb192
    ^bb192:  // pred: ^bb191
      %897 = arith.addi %894, %c1_i32 : i32
      %898 = arith.cmpi eq, %897, %c5_i32 : i32
      %899 = arith.select %898, %c0_i32, %897 : i32
      cf.cond_br %898, ^bb193, ^bb194
    ^bb193:  // pred: ^bb192
      %900 = arith.xori %896, %c1_i32 : i32
      cf.br ^bb195(%900 : i32)
    ^bb194:  // pred: ^bb192
      cf.br ^bb195(%896 : i32)
    ^bb195(%901: i32):  // 2 preds: ^bb193, ^bb194
      cf.br ^bb196
    ^bb196:  // pred: ^bb195
      %902 = arith.addi %899, %c1_i32 : i32
      %903 = arith.cmpi eq, %902, %c5_i32 : i32
      %904 = arith.select %903, %c0_i32, %902 : i32
      cf.cond_br %903, ^bb197, ^bb198
    ^bb197:  // pred: ^bb196
      %905 = arith.xori %901, %c1_i32 : i32
      cf.br ^bb199(%905 : i32)
    ^bb198:  // pred: ^bb196
      cf.br ^bb199(%901 : i32)
    ^bb199(%906: i32):  // 2 preds: ^bb197, ^bb198
      cf.br ^bb200
    ^bb200:  // pred: ^bb199
      %907 = arith.addi %904, %c1_i32 : i32
      %908 = arith.cmpi eq, %907, %c5_i32 : i32
      %909 = arith.select %908, %c0_i32, %907 : i32
      cf.cond_br %908, ^bb201, ^bb202
    ^bb201:  // pred: ^bb200
      %910 = arith.xori %906, %c1_i32 : i32
      cf.br ^bb203(%910 : i32)
    ^bb202:  // pred: ^bb200
      cf.br ^bb203(%906 : i32)
    ^bb203(%911: i32):  // 2 preds: ^bb201, ^bb202
      cf.br ^bb204
    ^bb204:  // pred: ^bb203
      %int_tuple_471 = cute.make_int_tuple(%909) : (i32) -> !cute.int_tuple<"?">
      %ptr_472 = cute.add_offset(%ptr_82, %int_tuple_471) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %912 = builtin.unrealized_conversion_cast %ptr_472 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %912, %911, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %913 = nvvm.elect.sync -> i1
      cf.cond_br %913, ^bb205, ^bb206
    ^bb205:  // pred: ^bb204
      %ptr_473 = cute.add_offset(%iter_77, %int_tuple_471) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %914 = builtin.unrealized_conversion_cast %ptr_473 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %914, %c512_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb206
    ^bb206:  // 2 preds: ^bb204, ^bb205
      %915 = arith.addi %620, %c1_i32 : i32
      %916 = arith.cmpi eq, %915, %c8_i32 : i32
      %917 = arith.select %916, %c0_i32, %915 : i32
      cf.cond_br %916, ^bb207, ^bb208
    ^bb207:  // pred: ^bb206
      %918 = arith.xori %621, %c1_i32 : i32
      cf.br ^bb209(%918 : i32)
    ^bb208:  // pred: ^bb206
      cf.br ^bb209(%621 : i32)
    ^bb209(%919: i32):  // 2 preds: ^bb207, ^bb208
      cf.br ^bb210
    ^bb210:  // pred: ^bb209
      %920 = arith.addi %917, %c1_i32 : i32
      %921 = arith.cmpi eq, %920, %c8_i32 : i32
      %922 = arith.select %921, %c0_i32, %920 : i32
      cf.cond_br %921, ^bb211, ^bb212
    ^bb211:  // pred: ^bb210
      %923 = arith.xori %919, %c1_i32 : i32
      cf.br ^bb213(%923 : i32)
    ^bb212:  // pred: ^bb210
      cf.br ^bb213(%919 : i32)
    ^bb213(%924: i32):  // 2 preds: ^bb211, ^bb212
      cf.br ^bb214
    ^bb214:  // pred: ^bb213
      %925 = arith.addi %922, %c1_i32 : i32
      %926 = arith.cmpi eq, %925, %c8_i32 : i32
      %927 = arith.select %926, %c0_i32, %925 : i32
      cf.cond_br %926, ^bb215, ^bb216
    ^bb215:  // pred: ^bb214
      %928 = arith.xori %924, %c1_i32 : i32
      cf.br ^bb217(%928 : i32)
    ^bb216:  // pred: ^bb214
      cf.br ^bb217(%924 : i32)
    ^bb217(%929: i32):  // 2 preds: ^bb215, ^bb216
      cf.br ^bb218
    ^bb218:  // pred: ^bb217
      %930 = arith.addi %927, %c1_i32 : i32
      %931 = arith.cmpi eq, %930, %c8_i32 : i32
      %932 = arith.select %931, %c0_i32, %930 : i32
      cf.cond_br %931, ^bb219, ^bb220
    ^bb219:  // pred: ^bb218
      %933 = arith.xori %929, %c1_i32 : i32
      cf.br ^bb221(%933 : i32)
    ^bb220:  // pred: ^bb218
      cf.br ^bb221(%929 : i32)
    ^bb221(%934: i32):  // 2 preds: ^bb219, ^bb220
      cf.br ^bb222
    ^bb222:  // pred: ^bb221
      %935 = arith.addi %932, %c1_i32 : i32
      %936 = arith.cmpi eq, %935, %c8_i32 : i32
      %937 = arith.select %936, %c0_i32, %935 : i32
      cf.cond_br %936, ^bb223, ^bb224
    ^bb223:  // pred: ^bb222
      %938 = arith.xori %934, %c1_i32 : i32
      cf.br ^bb225(%938 : i32)
    ^bb224:  // pred: ^bb222
      cf.br ^bb225(%934 : i32)
    ^bb225(%939: i32):  // 2 preds: ^bb223, ^bb224
      cf.br ^bb226
    ^bb226:  // pred: ^bb225
      %940 = arith.addi %937, %c1_i32 : i32
      %941 = arith.cmpi eq, %940, %c8_i32 : i32
      %942 = arith.select %941, %c0_i32, %940 : i32
      cf.cond_br %941, ^bb227, ^bb228
    ^bb227:  // pred: ^bb226
      %943 = arith.xori %939, %c1_i32 : i32
      cf.br ^bb229(%943 : i32)
    ^bb228:  // pred: ^bb226
      cf.br ^bb229(%939 : i32)
    ^bb229(%944: i32):  // 2 preds: ^bb227, ^bb228
      cf.br ^bb230
    ^bb230:  // pred: ^bb229
      %945 = arith.addi %942, %c1_i32 : i32
      %946 = arith.cmpi eq, %945, %c8_i32 : i32
      %947 = arith.select %946, %c0_i32, %945 : i32
      cf.cond_br %946, ^bb231, ^bb232
    ^bb231:  // pred: ^bb230
      %948 = arith.xori %944, %c1_i32 : i32
      cf.br ^bb233(%948 : i32)
    ^bb232:  // pred: ^bb230
      cf.br ^bb233(%944 : i32)
    ^bb233(%949: i32):  // 2 preds: ^bb231, ^bb232
      cf.br ^bb234
    ^bb234:  // pred: ^bb233
      %int_tuple_474 = cute.make_int_tuple(%947) : (i32) -> !cute.int_tuple<"?">
      %ptr_475 = cute.add_offset(%ptr_22, %int_tuple_474) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %950 = builtin.unrealized_conversion_cast %ptr_475 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %950, %949, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %285, ^bb235, ^bb238
    ^bb235:  // pred: ^bb234
      %951 = nvvm.elect.sync -> i1
      cf.cond_br %951, ^bb236, ^bb237
    ^bb236:  // pred: ^bb235
      %ptr_476 = cute.add_offset(%iter_14, %int_tuple_474) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %952 = builtin.unrealized_conversion_cast %ptr_476 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %952, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb237
    ^bb237:  // 2 preds: ^bb235, ^bb236
      cf.br ^bb238
    ^bb238:  // 2 preds: ^bb234, ^bb237
      cf.br ^bb240(%625 : i1)
    ^bb239:  // pred: ^bb38
      cf.br ^bb240(%true : i1)
    ^bb240(%953: i1):  // 2 preds: ^bb238, ^bb239
      cf.br ^bb241
    ^bb241:  // pred: ^bb240
      %954 = arith.cmpi eq, %244, %c12_i32 : i32
      cf.cond_br %954, ^bb242, ^bb529
    ^bb242:  // pred: ^bb241
      cf.cond_br %342, ^bb243, ^bb246
    ^bb243:  // pred: ^bb242
      %955 = nvvm.elect.sync -> i1
      cf.cond_br %955, ^bb244, ^bb245
    ^bb244:  // pred: ^bb243
      %956 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %956, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb245
    ^bb245:  // 2 preds: ^bb243, ^bb244
      cf.br ^bb246
    ^bb246:  // 2 preds: ^bb242, ^bb245
      nvvm.fence.mbarrier.init
      nvvm.setmaxregister  decrease 96
      nvvm.barrier id = %c1_i32 number_of_threads = %c160_i32
      %int_tuple_477 = cute.make_int_tuple(%itup_286) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %957 = cute.get_scalars(%int_tuple_477) <{only_dynamic}> : !cute.int_tuple<"?">
      %c1_i32_478 = arith.constant 1 : i32
      %c0_i32_479 = arith.constant 0 : i32
      %c-1_i32_480 = arith.constant -1 : i32
      %958 = arith.cmpi sgt, %c256_i32, %c0_i32_479 : i32
      %959 = arith.select %958, %c-1_i32_480, %c1_i32_478 : i32
      %960 = arith.addi %959, %957 : i32
      %961 = arith.divsi %960, %c256_i32 : i32
      %962 = arith.addi %c1_i32_478, %961 : i32
      %963 = arith.subi %c0_i32_479, %957 : i32
      %964 = arith.divsi %963, %c256_i32 : i32
      %965 = arith.subi %c0_i32_479, %964 : i32
      %966 = arith.cmpi slt, %957, %c0_i32_479 : i32
      %967 = arith.cmpi sgt, %957, %c0_i32_479 : i32
      %968 = arith.cmpi slt, %c256_i32, %c0_i32_479 : i32
      %969 = arith.cmpi sgt, %c256_i32, %c0_i32_479 : i32
      %970 = arith.andi %966, %968 : i1
      %971 = arith.andi %967, %969 : i1
      %972 = arith.ori %970, %971 : i1
      %973 = arith.select %972, %962, %965 : i32
      %int_tuple_481 = cute.make_int_tuple(%973) : (i32) -> !cute.int_tuple<"?">
      %e0_482 = cute.get_leaves(%int_tuple_481) : !cute.int_tuple<"?">
      %sub_483 = cute.tuple_sub(%e0_482, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %974 = cute.get_scalars(%sub_483) : !cute.int_tuple<"?">
      %975 = arith.cmpi sgt, %974, %c1_i32 : i32
      %976 = arith.remsi %266, %c2_i32 : i32
      %977 = arith.cmpi eq, %976, %c0_i32 : i32
      cf.br ^bb247(%c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %0, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %953 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1)
    ^bb247(%978: i32, %979: i32, %980: i32, %981: i32, %982: i32, %983: i32, %984: i32, %985: i32, %986: i32, %987: !llvm.struct<(i1, i1, i1)>, %988: i32, %989: i32, %990: i32, %991: i32, %992: i32, %993: i32, %994: i1):  // 2 preds: ^bb246, ^bb519
      cf.cond_br %994, ^bb248(%978, %979, %980, %981, %982, %983, %984, %985, %986, %987, %988, %989, %990, %991, %992, %993, %994 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1), ^bb520
    ^bb248(%995: i32, %996: i32, %997: i32, %998: i32, %999: i32, %1000: i32, %1001: i32, %1002: i32, %1003: i32, %1004: !llvm.struct<(i1, i1, i1)>, %1005: i32, %1006: i32, %1007: i32, %1008: i32, %1009: i32, %1010: i32, %1011: i1):  // pred: ^bb247
      %1012 = builtin.unrealized_conversion_cast %1004 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1013 = cute_nvgpu.atom.set_value(%1012, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1014 = builtin.unrealized_conversion_cast %1013 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      cf.cond_br %975, ^bb249, ^bb436
    ^bb249:  // pred: ^bb248
      %1015 = arith.remsi %266, %c2_i32 : i32
      %1016 = arith.cmpi eq, %1015, %c0_i32 : i32
      cf.cond_br %1016, ^bb250, ^bb282
    ^bb250:  // pred: ^bb249
      %int_tuple_484 = cute.make_int_tuple(%996) : (i32) -> !cute.int_tuple<"?">
      %ptr_485 = cute.add_offset(%ptr_106, %int_tuple_484) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1017 = builtin.unrealized_conversion_cast %ptr_485 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1017, %997, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1018 = arith.addi %996, %c1_i32 : i32
      %1019 = arith.addi %995, %c1_i32 : i32
      %1020 = arith.cmpi eq, %1018, %c2_i32 : i32
      %1021 = arith.select %1020, %c0_i32, %1018 : i32
      cf.cond_br %1020, ^bb251, ^bb252
    ^bb251:  // pred: ^bb250
      %1022 = arith.xori %997, %c1_i32 : i32
      cf.br ^bb253(%1022 : i32)
    ^bb252:  // pred: ^bb250
      cf.br ^bb253(%997 : i32)
    ^bb253(%1023: i32):  // 2 preds: ^bb251, ^bb252
      cf.br ^bb254
    ^bb254:  // pred: ^bb253
      %coord_486 = cute.make_coord(%996) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_487 = cute.crd2idx(%coord_486, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_488 = cute.add_offset(%345, %idx_487) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1024 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1025 = builtin.unrealized_conversion_cast %1024 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1026 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb255(%c0_i32, %998, %999, %1000, %1001, %1002, %1003, %1025 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb255(%1027: i32, %1028: i32, %1029: i32, %1030: i32, %1031: i32, %1032: i32, %1033: i32, %1034: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb254, ^bb278
      %1035 = arith.cmpi slt, %1027, %c8_i32 : i32
      cf.cond_br %1035, ^bb256, ^bb279 {loop_annotation = #loop_annotation3}
    ^bb256:  // pred: ^bb255
      %int_tuple_489 = cute.make_int_tuple(%1029) : (i32) -> !cute.int_tuple<"?">
      %ptr_490 = cute.add_offset(%iter_14, %int_tuple_489) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1036 = builtin.unrealized_conversion_cast %ptr_490 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1036, %1030, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1037 = arith.addi %1029, %c1_i32 : i32
      %1038 = arith.addi %1028, %c1_i32 : i32
      %1039 = arith.cmpi eq, %1037, %c8_i32 : i32
      %1040 = arith.select %1039, %c0_i32, %1037 : i32
      cf.cond_br %1039, ^bb257, ^bb258
    ^bb257:  // pred: ^bb256
      %1041 = arith.xori %1030, %c1_i32 : i32
      cf.br ^bb259(%1041 : i32)
    ^bb258:  // pred: ^bb256
      cf.br ^bb259(%1030 : i32)
    ^bb259(%1042: i32):  // 2 preds: ^bb257, ^bb258
      cf.br ^bb260
    ^bb260:  // pred: ^bb259
      %coord_491 = cute.make_coord(%1027) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_492 = cute.crd2idx(%coord_491, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_493 = cute.add_offset(%ummaSmemDesc, %idx_492) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_494 = cute.make_int_tuple(%1032) : (i32) -> !cute.int_tuple<"?">
      %ptr_495 = cute.add_offset(%iter_93, %int_tuple_494) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1043 = builtin.unrealized_conversion_cast %ptr_495 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1043, %1033, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1044 = arith.addi %1032, %c1_i32 : i32
      %1045 = arith.addi %1031, %c1_i32 : i32
      %1046 = arith.cmpi eq, %1044, %c3_i32 : i32
      %1047 = arith.select %1046, %c0_i32, %1044 : i32
      cf.cond_br %1046, ^bb261, ^bb262
    ^bb261:  // pred: ^bb260
      %1048 = arith.xori %1033, %c1_i32 : i32
      cf.br ^bb263(%1048 : i32)
    ^bb262:  // pred: ^bb260
      cf.br ^bb263(%1033 : i32)
    ^bb263(%1049: i32):  // 2 preds: ^bb261, ^bb262
      cf.br ^bb264
    ^bb264:  // pred: ^bb263
      %coord_496 = cute.make_coord(%1032) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_497 = cute.crd2idx(%coord_496, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_498 = cute.add_offset(%ummaSmemDesc_138, %idx_497) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb265(%c0_i32, %1034 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb265(%1050: i32, %1051: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb264, ^bb275
      %1052 = arith.cmpi slt, %1050, %c4_i32 : i32
      cf.cond_br %1052, ^bb266, ^bb276 {loop_annotation = #loop_annotation1}
    ^bb266:  // pred: ^bb265
      %1053 = builtin.unrealized_conversion_cast %1051 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_499 = cute.make_coord(%1050) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_500 = cute.crd2idx(%coord_499, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_501 = cute.add_offset(%tup_493, %idx_500) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_502 = cute.add_offset(%tup_498, %idx_500) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1054 = cute_nvgpu.atom.get_value(%1053 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1055 = cute_nvgpu.atom.get_value(%1053 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1056 = cute_nvgpu.atom.get_value(%1053 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1057 = arith.extui %1054 : i1 to i32
      %1058 = arith.extui %1055 : i1 to i32
      %1059 = arith.shli %1057, %c13_i32 : i32
      %1060 = arith.shli %1058, %c14_i32 : i32
      %1061 = arith.ori %1059, %c138413200_i32 : i32
      %1062 = arith.ori %1061, %1060 : i32
      cf.br ^bb267(%c0_i32 : i32)
    ^bb267(%1063: i32):  // 2 preds: ^bb266, ^bb274
      %1064 = arith.cmpi slt, %1063, %1026 : i32
      cf.cond_br %1064, ^bb268, ^bb275 {llvm.loop_annotation = #loop_annotation}
    ^bb268:  // pred: ^bb267
      cf.br ^bb269(%c0_i32 : i32)
    ^bb269(%1065: i32):  // 2 preds: ^bb268, ^bb273
      %1066 = arith.cmpi slt, %1065, %1026 : i32
      cf.cond_br %1066, ^bb270, ^bb274 {llvm.loop_annotation = #loop_annotation}
    ^bb270:  // pred: ^bb269
      cf.br ^bb271(%c0_i32 : i32)
    ^bb271(%1067: i32):  // 2 preds: ^bb270, ^bb272
      %1068 = arith.cmpi slt, %1067, %1026 : i32
      cf.cond_br %1068, ^bb272, ^bb273 {llvm.loop_annotation = #loop_annotation}
    ^bb272:  // pred: ^bb271
      cute_nvgpu.arch.mma.SM100.umma(%tup_501, %tup_502, %ptr_488, %1062, %1056) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1069 = arith.addi %1067, %c1_i32 : i32
      cf.br ^bb271(%1069 : i32)
    ^bb273:  // pred: ^bb271
      %1070 = arith.addi %1065, %c1_i32 : i32
      cf.br ^bb269(%1070 : i32)
    ^bb274:  // pred: ^bb269
      %1071 = arith.addi %1063, %c1_i32 : i32
      cf.br ^bb267(%1071 : i32)
    ^bb275:  // pred: ^bb267
      %1072 = cute_nvgpu.atom.set_value(%1053, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1073 = builtin.unrealized_conversion_cast %1072 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1074 = arith.addi %1050, %c1_i32 : i32
      cf.br ^bb265(%1074, %1073 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb276:  // pred: ^bb265
      %1075 = nvvm.elect.sync -> i1
      cf.cond_br %1075, ^bb277, ^bb278
    ^bb277:  // pred: ^bb276
      %ptr_503 = cute.add_offset(%ptr_96, %int_tuple_494) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1076 = builtin.unrealized_conversion_cast %ptr_503 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1076, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb278
    ^bb278:  // 2 preds: ^bb276, ^bb277
      %1077 = arith.addi %1027, %c1_i32 : i32
      cf.br ^bb255(%1077, %1038, %1040, %1042, %1045, %1047, %1049, %1051 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb279:  // pred: ^bb255
      %1078 = nvvm.elect.sync -> i1
      cf.cond_br %1078, ^bb280, ^bb281
    ^bb280:  // pred: ^bb279
      %ptr_504 = cute.add_offset(%iter_104, %int_tuple_484) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1079 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1079, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb281
    ^bb281:  // 2 preds: ^bb279, ^bb280
      cf.br ^bb283(%1019, %1021, %1023, %1028, %1029, %1030, %1031, %1032, %1033 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb282:  // pred: ^bb249
      cf.br ^bb283(%995, %996, %997, %998, %999, %1000, %1001, %1002, %1003 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb283(%1080: i32, %1081: i32, %1082: i32, %1083: i32, %1084: i32, %1085: i32, %1086: i32, %1087: i32, %1088: i32):  // 2 preds: ^bb281, ^bb282
      cf.br ^bb284
    ^bb284:  // pred: ^bb283
      %sub_505 = cute.tuple_sub(%sub_483, %212) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %1089 = cute.get_scalars(%sub_505) : !cute.int_tuple<"?">
      cf.br ^bb285(%c1_i32, %1080, %1081, %1082, %1086, %1087, %1088, %1014, %1005, %1006, %1007, %1008, %1009, %1010 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb285(%1090: i32, %1091: i32, %1092: i32, %1093: i32, %1094: i32, %1095: i32, %1096: i32, %1097: !llvm.struct<(i1, i1, i1)>, %1098: i32, %1099: i32, %1100: i32, %1101: i32, %1102: i32, %1103: i32):  // 2 preds: ^bb284, ^bb357
      %1104 = arith.cmpi slt, %1090, %1089 : i32
      cf.cond_br %1104, ^bb286, ^bb358 {loop_annotation = #loop_annotation2}
    ^bb286:  // pred: ^bb285
      cf.cond_br %1016, ^bb287, ^bb315
    ^bb287:  // pred: ^bb286
      %int_tuple_506 = cute.make_int_tuple(%1092) : (i32) -> !cute.int_tuple<"?">
      %ptr_507 = cute.add_offset(%ptr_106, %int_tuple_506) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1105 = builtin.unrealized_conversion_cast %ptr_507 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1105, %1093, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1106 = arith.addi %1092, %c1_i32 : i32
      %1107 = arith.addi %1091, %c1_i32 : i32
      %1108 = arith.cmpi eq, %1106, %c2_i32 : i32
      %1109 = arith.select %1108, %c0_i32, %1106 : i32
      cf.cond_br %1108, ^bb288, ^bb289
    ^bb288:  // pred: ^bb287
      %1110 = arith.xori %1093, %c1_i32 : i32
      cf.br ^bb290(%1110 : i32)
    ^bb289:  // pred: ^bb287
      cf.br ^bb290(%1093 : i32)
    ^bb290(%1111: i32):  // 2 preds: ^bb288, ^bb289
      cf.br ^bb291
    ^bb291:  // pred: ^bb290
      %coord_508 = cute.make_coord(%1092) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_509 = cute.crd2idx(%coord_508, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_510 = cute.add_offset(%345, %idx_509) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1112 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1113 = builtin.unrealized_conversion_cast %1112 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1114 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb292(%c0_i32, %1094, %1095, %1096, %1113 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb292(%1115: i32, %1116: i32, %1117: i32, %1118: i32, %1119: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb291, ^bb311
      %1120 = arith.cmpi slt, %1115, %c8_i32 : i32
      cf.cond_br %1120, ^bb293, ^bb312 {loop_annotation = #loop_annotation3}
    ^bb293:  // pred: ^bb292
      %coord_511 = cute.make_coord(%1115) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_512 = cute.crd2idx(%coord_511, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_513 = cute.add_offset(%ummaSmemDesc, %idx_512) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_514 = cute.make_int_tuple(%1117) : (i32) -> !cute.int_tuple<"?">
      %ptr_515 = cute.add_offset(%iter_93, %int_tuple_514) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1121 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1121, %1118, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1122 = arith.addi %1117, %c1_i32 : i32
      %1123 = arith.addi %1116, %c1_i32 : i32
      %1124 = arith.cmpi eq, %1122, %c3_i32 : i32
      %1125 = arith.select %1124, %c0_i32, %1122 : i32
      cf.cond_br %1124, ^bb294, ^bb295
    ^bb294:  // pred: ^bb293
      %1126 = arith.xori %1118, %c1_i32 : i32
      cf.br ^bb296(%1126 : i32)
    ^bb295:  // pred: ^bb293
      cf.br ^bb296(%1118 : i32)
    ^bb296(%1127: i32):  // 2 preds: ^bb294, ^bb295
      cf.br ^bb297
    ^bb297:  // pred: ^bb296
      %coord_516 = cute.make_coord(%1117) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_517 = cute.crd2idx(%coord_516, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_518 = cute.add_offset(%ummaSmemDesc_138, %idx_517) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb298(%c0_i32, %1119 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb298(%1128: i32, %1129: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb297, ^bb308
      %1130 = arith.cmpi slt, %1128, %c4_i32 : i32
      cf.cond_br %1130, ^bb299, ^bb309 {loop_annotation = #loop_annotation1}
    ^bb299:  // pred: ^bb298
      %1131 = builtin.unrealized_conversion_cast %1129 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_519 = cute.make_coord(%1128) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_520 = cute.crd2idx(%coord_519, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_521 = cute.add_offset(%tup_513, %idx_520) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_522 = cute.add_offset(%tup_518, %idx_520) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1132 = cute_nvgpu.atom.get_value(%1131 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1133 = cute_nvgpu.atom.get_value(%1131 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1134 = cute_nvgpu.atom.get_value(%1131 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1135 = arith.extui %1132 : i1 to i32
      %1136 = arith.extui %1133 : i1 to i32
      %1137 = arith.shli %1135, %c13_i32 : i32
      %1138 = arith.shli %1136, %c14_i32 : i32
      %1139 = arith.ori %1137, %c138413200_i32 : i32
      %1140 = arith.ori %1139, %1138 : i32
      cf.br ^bb300(%c0_i32 : i32)
    ^bb300(%1141: i32):  // 2 preds: ^bb299, ^bb307
      %1142 = arith.cmpi slt, %1141, %1114 : i32
      cf.cond_br %1142, ^bb301, ^bb308 {llvm.loop_annotation = #loop_annotation}
    ^bb301:  // pred: ^bb300
      cf.br ^bb302(%c0_i32 : i32)
    ^bb302(%1143: i32):  // 2 preds: ^bb301, ^bb306
      %1144 = arith.cmpi slt, %1143, %1114 : i32
      cf.cond_br %1144, ^bb303, ^bb307 {llvm.loop_annotation = #loop_annotation}
    ^bb303:  // pred: ^bb302
      cf.br ^bb304(%c0_i32 : i32)
    ^bb304(%1145: i32):  // 2 preds: ^bb303, ^bb305
      %1146 = arith.cmpi slt, %1145, %1114 : i32
      cf.cond_br %1146, ^bb305, ^bb306 {llvm.loop_annotation = #loop_annotation}
    ^bb305:  // pred: ^bb304
      cute_nvgpu.arch.mma.SM100.umma(%tup_521, %tup_522, %ptr_510, %1140, %1134) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1147 = arith.addi %1145, %c1_i32 : i32
      cf.br ^bb304(%1147 : i32)
    ^bb306:  // pred: ^bb304
      %1148 = arith.addi %1143, %c1_i32 : i32
      cf.br ^bb302(%1148 : i32)
    ^bb307:  // pred: ^bb302
      %1149 = arith.addi %1141, %c1_i32 : i32
      cf.br ^bb300(%1149 : i32)
    ^bb308:  // pred: ^bb300
      %1150 = cute_nvgpu.atom.set_value(%1131, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1151 = builtin.unrealized_conversion_cast %1150 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1152 = arith.addi %1128, %c1_i32 : i32
      cf.br ^bb298(%1152, %1151 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb309:  // pred: ^bb298
      %1153 = nvvm.elect.sync -> i1
      cf.cond_br %1153, ^bb310, ^bb311
    ^bb310:  // pred: ^bb309
      %ptr_523 = cute.add_offset(%ptr_96, %int_tuple_514) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1154 = builtin.unrealized_conversion_cast %ptr_523 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1154, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb311
    ^bb311:  // 2 preds: ^bb309, ^bb310
      %1155 = arith.addi %1115, %c1_i32 : i32
      cf.br ^bb292(%1155, %1123, %1125, %1127, %1129 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb312:  // pred: ^bb292
      %1156 = nvvm.elect.sync -> i1
      cf.cond_br %1156, ^bb313, ^bb314
    ^bb313:  // pred: ^bb312
      %ptr_524 = cute.add_offset(%iter_104, %int_tuple_506) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1157 = builtin.unrealized_conversion_cast %ptr_524 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1157, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb314
    ^bb314:  // 2 preds: ^bb312, ^bb313
      cf.br ^bb316(%1107, %1109, %1111, %1116, %1117, %1118 : i32, i32, i32, i32, i32, i32)
    ^bb315:  // pred: ^bb286
      cf.br ^bb316(%1091, %1092, %1093, %1094, %1095, %1096 : i32, i32, i32, i32, i32, i32)
    ^bb316(%1158: i32, %1159: i32, %1160: i32, %1161: i32, %1162: i32, %1163: i32):  // 2 preds: ^bb314, ^bb315
      cf.br ^bb317
    ^bb317:  // pred: ^bb316
      cf.cond_br %1016, ^bb318, ^bb355
    ^bb318:  // pred: ^bb317
      %int_tuple_525 = cute.make_int_tuple(%1099) : (i32) -> !cute.int_tuple<"?">
      %ptr_526 = cute.add_offset(%iter_109, %int_tuple_525) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1164 = builtin.unrealized_conversion_cast %ptr_526 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1164, %1100, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1165 = arith.addi %1099, %c1_i32 : i32
      %1166 = arith.addi %1098, %c1_i32 : i32
      %1167 = arith.cmpi eq, %1165, %c2_i32 : i32
      %1168 = arith.select %1167, %c0_i32, %1165 : i32
      cf.cond_br %1167, ^bb319, ^bb320
    ^bb319:  // pred: ^bb318
      %1169 = arith.xori %1100, %c1_i32 : i32
      cf.br ^bb321(%1169 : i32)
    ^bb320:  // pred: ^bb318
      cf.br ^bb321(%1100 : i32)
    ^bb321(%1170: i32):  // 2 preds: ^bb319, ^bb320
      cf.br ^bb322
    ^bb322:  // pred: ^bb321
      %int_tuple_527 = cute.make_int_tuple(%1102) : (i32) -> !cute.int_tuple<"?">
      %ptr_528 = cute.add_offset(%ptr_115, %int_tuple_527) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1171 = builtin.unrealized_conversion_cast %ptr_528 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1171, %1103, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1172 = arith.addi %1102, %c1_i32 : i32
      %1173 = arith.addi %1101, %c1_i32 : i32
      %1174 = arith.cmpi eq, %1172, %c1_i32 : i32
      %1175 = arith.select %1174, %c0_i32, %1172 : i32
      cf.cond_br %1174, ^bb323, ^bb324
    ^bb323:  // pred: ^bb322
      %1176 = arith.xori %1103, %c1_i32 : i32
      cf.br ^bb325(%1176 : i32)
    ^bb324:  // pred: ^bb322
      cf.br ^bb325(%1103 : i32)
    ^bb325(%1177: i32):  // 2 preds: ^bb323, ^bb324
      cf.br ^bb326
    ^bb326:  // pred: ^bb325
      %1178 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb327(%c0_i32, %1097, %1161, %1162, %1163 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb327(%1179: i32, %1180: !llvm.struct<(i1, i1, i1)>, %1181: i32, %1182: i32, %1183: i32):  // 2 preds: ^bb326, ^bb349
      %1184 = arith.cmpi slt, %1179, %c4_i32 : i32
      cf.cond_br %1184, ^bb328, ^bb350 {loop_annotation = #loop_annotation2}
    ^bb328:  // pred: ^bb327
      %1185 = builtin.unrealized_conversion_cast %1180 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1186 = cute_nvgpu.atom.get_value(%1185 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_529 = cute.make_coord(%1179, %1099) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_530 = cute.crd2idx(%coord_529, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_531 = cute.add_offset(%ummaSmemDesc_137, %idx_530) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb329(%c0_i32, %1181, %1182, %1183, %1180 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb329(%1187: i32, %1188: i32, %1189: i32, %1190: i32, %1191: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb328, ^bb348
      %1192 = arith.cmpi slt, %1187, %c2_i32 : i32
      cf.cond_br %1192, ^bb330, ^bb349 {loop_annotation = #loop_annotation3}
    ^bb330:  // pred: ^bb329
      %1193 = builtin.unrealized_conversion_cast %1191 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_532 = cute.make_int_tuple(%1189) : (i32) -> !cute.int_tuple<"?">
      %ptr_533 = cute.add_offset(%iter_93, %int_tuple_532) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1194 = builtin.unrealized_conversion_cast %ptr_533 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1194, %1190, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1195 = arith.addi %1189, %c1_i32 : i32
      %1196 = arith.addi %1188, %c1_i32 : i32
      %1197 = arith.cmpi eq, %1195, %c3_i32 : i32
      %1198 = arith.select %1197, %c0_i32, %1195 : i32
      cf.cond_br %1197, ^bb331, ^bb332
    ^bb331:  // pred: ^bb330
      %1199 = arith.xori %1190, %c1_i32 : i32
      cf.br ^bb333(%1199 : i32)
    ^bb332:  // pred: ^bb330
      cf.br ^bb333(%1190 : i32)
    ^bb333(%1200: i32):  // 2 preds: ^bb331, ^bb332
      cf.br ^bb334
    ^bb334:  // pred: ^bb333
      %1201 = cute_nvgpu.atom.set_value(%1193, %1186 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1202 = builtin.unrealized_conversion_cast %1201 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_534 = cute.make_coord(%1187) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_535 = cute.crd2idx(%coord_534, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_536 = cute.add_offset(%ptr_140, %idx_535) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_537 = cute.make_coord(%1189) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_538 = cute.crd2idx(%coord_537, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_539 = cute.add_offset(%ummaSmemDesc_139, %idx_538) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb335(%c0_i32, %1202 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb335(%1203: i32, %1204: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb334, ^bb345
      %1205 = arith.cmpi slt, %1203, %c4_i32 : i32
      cf.cond_br %1205, ^bb336, ^bb346 {loop_annotation = #loop_annotation1}
    ^bb336:  // pred: ^bb335
      %1206 = builtin.unrealized_conversion_cast %1204 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_540 = cute.make_coord(%1203) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_541 = cute.crd2idx(%coord_540, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_542 = cute.add_offset(%tup_531, %idx_541) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_543 = cute.crd2idx(%coord_540, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_544 = cute.add_offset(%tup_539, %idx_543) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %1207 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1208 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1209 = cute_nvgpu.atom.get_value(%1206 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1210 = arith.extui %1207 : i1 to i32
      %1211 = arith.extui %1208 : i1 to i32
      %1212 = arith.shli %1210, %c13_i32 : i32
      %1213 = arith.shli %1211, %c14_i32 : i32
      %1214 = arith.ori %1212, %c138478736_i32 : i32
      %1215 = arith.ori %1214, %1213 : i32
      cf.br ^bb337(%c0_i32 : i32)
    ^bb337(%1216: i32):  // 2 preds: ^bb336, ^bb344
      %1217 = arith.cmpi slt, %1216, %1178 : i32
      cf.cond_br %1217, ^bb338, ^bb345 {llvm.loop_annotation = #loop_annotation}
    ^bb338:  // pred: ^bb337
      cf.br ^bb339(%c0_i32 : i32)
    ^bb339(%1218: i32):  // 2 preds: ^bb338, ^bb343
      %1219 = arith.cmpi slt, %1218, %1178 : i32
      cf.cond_br %1219, ^bb340, ^bb344 {llvm.loop_annotation = #loop_annotation}
    ^bb340:  // pred: ^bb339
      cf.br ^bb341(%c0_i32 : i32)
    ^bb341(%1220: i32):  // 2 preds: ^bb340, ^bb342
      %1221 = arith.cmpi slt, %1220, %1178 : i32
      cf.cond_br %1221, ^bb342, ^bb343 {llvm.loop_annotation = #loop_annotation}
    ^bb342:  // pred: ^bb341
      cute_nvgpu.arch.mma.SM100.umma(%tup_542, %tup_544, %ptr_536, %1215, %1209) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1222 = arith.addi %1220, %c1_i32 : i32
      cf.br ^bb341(%1222 : i32)
    ^bb343:  // pred: ^bb341
      %1223 = arith.addi %1218, %c1_i32 : i32
      cf.br ^bb339(%1223 : i32)
    ^bb344:  // pred: ^bb339
      %1224 = arith.addi %1216, %c1_i32 : i32
      cf.br ^bb337(%1224 : i32)
    ^bb345:  // pred: ^bb337
      %1225 = cute_nvgpu.atom.set_value(%1206, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1226 = builtin.unrealized_conversion_cast %1225 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %1227 = arith.addi %1203, %c1_i32 : i32
      cf.br ^bb335(%1227, %1226 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb346:  // pred: ^bb335
      %1228 = nvvm.elect.sync -> i1
      cf.cond_br %1228, ^bb347, ^bb348
    ^bb347:  // pred: ^bb346
      %ptr_545 = cute.add_offset(%ptr_96, %int_tuple_532) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1229 = builtin.unrealized_conversion_cast %ptr_545 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1229, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb348
    ^bb348:  // 2 preds: ^bb346, ^bb347
      %1230 = arith.addi %1187, %c1_i32 : i32
      cf.br ^bb329(%1230, %1196, %1198, %1200, %1204 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb349:  // pred: ^bb329
      %1231 = arith.addi %1179, %c1_i32 : i32
      cf.br ^bb327(%1231, %1191, %1188, %1189, %1190 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb350:  // pred: ^bb327
      %1232 = nvvm.elect.sync -> i1
      cf.cond_br %1232, ^bb351, ^bb352
    ^bb351:  // pred: ^bb350
      %ptr_546 = cute.add_offset(%iter_114, %int_tuple_527) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1233 = builtin.unrealized_conversion_cast %ptr_546 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1233, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb352
    ^bb352:  // 2 preds: ^bb350, ^bb351
      %1234 = nvvm.elect.sync -> i1
      cf.cond_br %1234, ^bb353, ^bb354
    ^bb353:  // pred: ^bb352
      %ptr_547 = cute.add_offset(%ptr_111, %int_tuple_525) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1235 = builtin.unrealized_conversion_cast %ptr_547 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1235, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb354
    ^bb354:  // 2 preds: ^bb352, ^bb353
      cf.br ^bb356(%1166, %1168, %1170, %1173, %1175, %1177, %1180, %1181, %1182, %1183 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb355:  // pred: ^bb317
      cf.br ^bb356(%1098, %1099, %1100, %1101, %1102, %1103, %1097, %1161, %1162, %1163 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb356(%1236: i32, %1237: i32, %1238: i32, %1239: i32, %1240: i32, %1241: i32, %1242: !llvm.struct<(i1, i1, i1)>, %1243: i32, %1244: i32, %1245: i32):  // 2 preds: ^bb354, ^bb355
      cf.br ^bb357
    ^bb357:  // pred: ^bb356
      %1246 = arith.addi %1090, %c1_i32 : i32
      cf.br ^bb285(%1246, %1158, %1159, %1160, %1243, %1244, %1245, %1242, %1236, %1237, %1238, %1239, %1240, %1241 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb358:  // pred: ^bb285
      cf.cond_br %1016, ^bb359, ^bb393
    ^bb359:  // pred: ^bb358
      %int_tuple_548 = cute.make_int_tuple(%1092) : (i32) -> !cute.int_tuple<"?">
      %ptr_549 = cute.add_offset(%ptr_106, %int_tuple_548) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1247 = builtin.unrealized_conversion_cast %ptr_549 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1247, %1093, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1248 = arith.addi %1092, %c1_i32 : i32
      %1249 = arith.addi %1091, %c1_i32 : i32
      %1250 = arith.cmpi eq, %1248, %c2_i32 : i32
      %1251 = arith.select %1250, %c0_i32, %1248 : i32
      cf.cond_br %1250, ^bb360, ^bb361
    ^bb360:  // pred: ^bb359
      %1252 = arith.xori %1093, %c1_i32 : i32
      cf.br ^bb362(%1252 : i32)
    ^bb361:  // pred: ^bb359
      cf.br ^bb362(%1093 : i32)
    ^bb362(%1253: i32):  // 2 preds: ^bb360, ^bb361
      cf.br ^bb363
    ^bb363:  // pred: ^bb362
      %coord_550 = cute.make_coord(%1092) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_551 = cute.crd2idx(%coord_550, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_552 = cute.add_offset(%345, %idx_551) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1254 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1255 = builtin.unrealized_conversion_cast %1254 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1256 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb364(%c0_i32, %1094, %1095, %1096, %1255, %998, %999, %1000 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb364(%1257: i32, %1258: i32, %1259: i32, %1260: i32, %1261: !llvm.struct<(i1, i1, i1)>, %1262: i32, %1263: i32, %1264: i32):  // 2 preds: ^bb363, ^bb389
      %1265 = arith.cmpi slt, %1257, %c8_i32 : i32
      cf.cond_br %1265, ^bb365, ^bb390 {loop_annotation = #loop_annotation3}
    ^bb365:  // pred: ^bb364
      %coord_553 = cute.make_coord(%1257) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_554 = cute.crd2idx(%coord_553, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_555 = cute.add_offset(%ummaSmemDesc, %idx_554) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_556 = cute.make_int_tuple(%1259) : (i32) -> !cute.int_tuple<"?">
      %ptr_557 = cute.add_offset(%iter_93, %int_tuple_556) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1266 = builtin.unrealized_conversion_cast %ptr_557 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1266, %1260, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1267 = arith.addi %1259, %c1_i32 : i32
      %1268 = arith.addi %1258, %c1_i32 : i32
      %1269 = arith.cmpi eq, %1267, %c3_i32 : i32
      %1270 = arith.select %1269, %c0_i32, %1267 : i32
      cf.cond_br %1269, ^bb366, ^bb367
    ^bb366:  // pred: ^bb365
      %1271 = arith.xori %1260, %c1_i32 : i32
      cf.br ^bb368(%1271 : i32)
    ^bb367:  // pred: ^bb365
      cf.br ^bb368(%1260 : i32)
    ^bb368(%1272: i32):  // 2 preds: ^bb366, ^bb367
      cf.br ^bb369
    ^bb369:  // pred: ^bb368
      %coord_558 = cute.make_coord(%1259) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_559 = cute.crd2idx(%coord_558, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_560 = cute.add_offset(%ummaSmemDesc_138, %idx_559) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb370(%c0_i32, %1261 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb370(%1273: i32, %1274: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb369, ^bb380
      %1275 = arith.cmpi slt, %1273, %c4_i32 : i32
      cf.cond_br %1275, ^bb371, ^bb381 {loop_annotation = #loop_annotation1}
    ^bb371:  // pred: ^bb370
      %1276 = builtin.unrealized_conversion_cast %1274 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_561 = cute.make_coord(%1273) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_562 = cute.crd2idx(%coord_561, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_563 = cute.add_offset(%tup_555, %idx_562) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_564 = cute.add_offset(%tup_560, %idx_562) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1277 = cute_nvgpu.atom.get_value(%1276 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1278 = cute_nvgpu.atom.get_value(%1276 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1279 = cute_nvgpu.atom.get_value(%1276 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1280 = arith.extui %1277 : i1 to i32
      %1281 = arith.extui %1278 : i1 to i32
      %1282 = arith.shli %1280, %c13_i32 : i32
      %1283 = arith.shli %1281, %c14_i32 : i32
      %1284 = arith.ori %1282, %c138413200_i32 : i32
      %1285 = arith.ori %1284, %1283 : i32
      cf.br ^bb372(%c0_i32 : i32)
    ^bb372(%1286: i32):  // 2 preds: ^bb371, ^bb379
      %1287 = arith.cmpi slt, %1286, %1256 : i32
      cf.cond_br %1287, ^bb373, ^bb380 {llvm.loop_annotation = #loop_annotation}
    ^bb373:  // pred: ^bb372
      cf.br ^bb374(%c0_i32 : i32)
    ^bb374(%1288: i32):  // 2 preds: ^bb373, ^bb378
      %1289 = arith.cmpi slt, %1288, %1256 : i32
      cf.cond_br %1289, ^bb375, ^bb379 {llvm.loop_annotation = #loop_annotation}
    ^bb375:  // pred: ^bb374
      cf.br ^bb376(%c0_i32 : i32)
    ^bb376(%1290: i32):  // 2 preds: ^bb375, ^bb377
      %1291 = arith.cmpi slt, %1290, %1256 : i32
      cf.cond_br %1291, ^bb377, ^bb378 {llvm.loop_annotation = #loop_annotation}
    ^bb377:  // pred: ^bb376
      cute_nvgpu.arch.mma.SM100.umma(%tup_563, %tup_564, %ptr_552, %1285, %1279) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1292 = arith.addi %1290, %c1_i32 : i32
      cf.br ^bb376(%1292 : i32)
    ^bb378:  // pred: ^bb376
      %1293 = arith.addi %1288, %c1_i32 : i32
      cf.br ^bb374(%1293 : i32)
    ^bb379:  // pred: ^bb374
      %1294 = arith.addi %1286, %c1_i32 : i32
      cf.br ^bb372(%1294 : i32)
    ^bb380:  // pred: ^bb372
      %1295 = cute_nvgpu.atom.set_value(%1276, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1296 = builtin.unrealized_conversion_cast %1295 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1297 = arith.addi %1273, %c1_i32 : i32
      cf.br ^bb370(%1297, %1296 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb381:  // pred: ^bb370
      %1298 = nvvm.elect.sync -> i1
      cf.cond_br %1298, ^bb382, ^bb383
    ^bb382:  // pred: ^bb381
      %ptr_565 = cute.add_offset(%ptr_96, %int_tuple_556) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1299 = builtin.unrealized_conversion_cast %ptr_565 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1299, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb383
    ^bb383:  // 2 preds: ^bb381, ^bb382
      %1300 = nvvm.elect.sync -> i1
      cf.cond_br %1300, ^bb384, ^bb385
    ^bb384:  // pred: ^bb383
      %int_tuple_566 = cute.make_int_tuple(%1263) : (i32) -> !cute.int_tuple<"?">
      %ptr_567 = cute.add_offset(%ptr_22, %int_tuple_566) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1301 = builtin.unrealized_conversion_cast %ptr_567 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1301, multicast_mask = %284 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb385
    ^bb385:  // 2 preds: ^bb383, ^bb384
      %1302 = arith.addi %1263, %c1_i32 : i32
      %1303 = arith.addi %1262, %c1_i32 : i32
      %1304 = arith.cmpi eq, %1302, %c8_i32 : i32
      %1305 = arith.select %1304, %c0_i32, %1302 : i32
      cf.cond_br %1304, ^bb386, ^bb387
    ^bb386:  // pred: ^bb385
      %1306 = arith.xori %1264, %c1_i32 : i32
      cf.br ^bb388(%1306 : i32)
    ^bb387:  // pred: ^bb385
      cf.br ^bb388(%1264 : i32)
    ^bb388(%1307: i32):  // 2 preds: ^bb386, ^bb387
      cf.br ^bb389
    ^bb389:  // pred: ^bb388
      %1308 = arith.addi %1257, %c1_i32 : i32
      cf.br ^bb364(%1308, %1268, %1270, %1272, %1274, %1303, %1305, %1307 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb390:  // pred: ^bb364
      %1309 = nvvm.elect.sync -> i1
      cf.cond_br %1309, ^bb391, ^bb392
    ^bb391:  // pred: ^bb390
      %ptr_568 = cute.add_offset(%iter_104, %int_tuple_548) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1310 = builtin.unrealized_conversion_cast %ptr_568 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1310, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb392
    ^bb392:  // 2 preds: ^bb390, ^bb391
      cf.br ^bb394(%1249, %1251, %1253, %1258, %1259, %1260 : i32, i32, i32, i32, i32, i32)
    ^bb393:  // pred: ^bb358
      cf.br ^bb394(%1091, %1092, %1093, %1094, %1095, %1096 : i32, i32, i32, i32, i32, i32)
    ^bb394(%1311: i32, %1312: i32, %1313: i32, %1314: i32, %1315: i32, %1316: i32):  // 2 preds: ^bb392, ^bb393
      cf.br ^bb395
    ^bb395:  // pred: ^bb394
      cf.cond_br %1016, ^bb396, ^bb433
    ^bb396:  // pred: ^bb395
      %int_tuple_569 = cute.make_int_tuple(%1099) : (i32) -> !cute.int_tuple<"?">
      %ptr_570 = cute.add_offset(%iter_109, %int_tuple_569) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1317 = builtin.unrealized_conversion_cast %ptr_570 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1317, %1100, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1318 = arith.addi %1099, %c1_i32 : i32
      %1319 = arith.addi %1098, %c1_i32 : i32
      %1320 = arith.cmpi eq, %1318, %c2_i32 : i32
      %1321 = arith.select %1320, %c0_i32, %1318 : i32
      cf.cond_br %1320, ^bb397, ^bb398
    ^bb397:  // pred: ^bb396
      %1322 = arith.xori %1100, %c1_i32 : i32
      cf.br ^bb399(%1322 : i32)
    ^bb398:  // pred: ^bb396
      cf.br ^bb399(%1100 : i32)
    ^bb399(%1323: i32):  // 2 preds: ^bb397, ^bb398
      cf.br ^bb400
    ^bb400:  // pred: ^bb399
      %int_tuple_571 = cute.make_int_tuple(%1102) : (i32) -> !cute.int_tuple<"?">
      %ptr_572 = cute.add_offset(%ptr_115, %int_tuple_571) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1324 = builtin.unrealized_conversion_cast %ptr_572 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1324, %1103, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1325 = arith.addi %1102, %c1_i32 : i32
      %1326 = arith.addi %1101, %c1_i32 : i32
      %1327 = arith.cmpi eq, %1325, %c1_i32 : i32
      %1328 = arith.select %1327, %c0_i32, %1325 : i32
      cf.cond_br %1327, ^bb401, ^bb402
    ^bb401:  // pred: ^bb400
      %1329 = arith.xori %1103, %c1_i32 : i32
      cf.br ^bb403(%1329 : i32)
    ^bb402:  // pred: ^bb400
      cf.br ^bb403(%1103 : i32)
    ^bb403(%1330: i32):  // 2 preds: ^bb401, ^bb402
      cf.br ^bb404
    ^bb404:  // pred: ^bb403
      %1331 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb405(%c0_i32, %1097, %1314, %1315, %1316 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb405(%1332: i32, %1333: !llvm.struct<(i1, i1, i1)>, %1334: i32, %1335: i32, %1336: i32):  // 2 preds: ^bb404, ^bb427
      %1337 = arith.cmpi slt, %1332, %c4_i32 : i32
      cf.cond_br %1337, ^bb406, ^bb428 {loop_annotation = #loop_annotation2}
    ^bb406:  // pred: ^bb405
      %1338 = builtin.unrealized_conversion_cast %1333 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1339 = cute_nvgpu.atom.get_value(%1338 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_573 = cute.make_coord(%1332, %1099) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_574 = cute.crd2idx(%coord_573, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_575 = cute.add_offset(%ummaSmemDesc_137, %idx_574) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb407(%c0_i32, %1334, %1335, %1336, %1333 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb407(%1340: i32, %1341: i32, %1342: i32, %1343: i32, %1344: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb406, ^bb426
      %1345 = arith.cmpi slt, %1340, %c2_i32 : i32
      cf.cond_br %1345, ^bb408, ^bb427 {loop_annotation = #loop_annotation3}
    ^bb408:  // pred: ^bb407
      %1346 = builtin.unrealized_conversion_cast %1344 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_576 = cute.make_int_tuple(%1342) : (i32) -> !cute.int_tuple<"?">
      %ptr_577 = cute.add_offset(%iter_93, %int_tuple_576) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1347 = builtin.unrealized_conversion_cast %ptr_577 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1347, %1343, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1348 = arith.addi %1342, %c1_i32 : i32
      %1349 = arith.addi %1341, %c1_i32 : i32
      %1350 = arith.cmpi eq, %1348, %c3_i32 : i32
      %1351 = arith.select %1350, %c0_i32, %1348 : i32
      cf.cond_br %1350, ^bb409, ^bb410
    ^bb409:  // pred: ^bb408
      %1352 = arith.xori %1343, %c1_i32 : i32
      cf.br ^bb411(%1352 : i32)
    ^bb410:  // pred: ^bb408
      cf.br ^bb411(%1343 : i32)
    ^bb411(%1353: i32):  // 2 preds: ^bb409, ^bb410
      cf.br ^bb412
    ^bb412:  // pred: ^bb411
      %1354 = cute_nvgpu.atom.set_value(%1346, %1339 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1355 = builtin.unrealized_conversion_cast %1354 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_578 = cute.make_coord(%1340) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_579 = cute.crd2idx(%coord_578, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_580 = cute.add_offset(%ptr_140, %idx_579) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_581 = cute.make_coord(%1342) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_582 = cute.crd2idx(%coord_581, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_583 = cute.add_offset(%ummaSmemDesc_139, %idx_582) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb413(%c0_i32, %1355 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb413(%1356: i32, %1357: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb412, ^bb423
      %1358 = arith.cmpi slt, %1356, %c4_i32 : i32
      cf.cond_br %1358, ^bb414, ^bb424 {loop_annotation = #loop_annotation1}
    ^bb414:  // pred: ^bb413
      %1359 = builtin.unrealized_conversion_cast %1357 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_584 = cute.make_coord(%1356) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_585 = cute.crd2idx(%coord_584, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_586 = cute.add_offset(%tup_575, %idx_585) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_587 = cute.crd2idx(%coord_584, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_588 = cute.add_offset(%tup_583, %idx_587) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %1360 = cute_nvgpu.atom.get_value(%1359 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1361 = cute_nvgpu.atom.get_value(%1359 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1362 = cute_nvgpu.atom.get_value(%1359 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1363 = arith.extui %1360 : i1 to i32
      %1364 = arith.extui %1361 : i1 to i32
      %1365 = arith.shli %1363, %c13_i32 : i32
      %1366 = arith.shli %1364, %c14_i32 : i32
      %1367 = arith.ori %1365, %c138478736_i32 : i32
      %1368 = arith.ori %1367, %1366 : i32
      cf.br ^bb415(%c0_i32 : i32)
    ^bb415(%1369: i32):  // 2 preds: ^bb414, ^bb422
      %1370 = arith.cmpi slt, %1369, %1331 : i32
      cf.cond_br %1370, ^bb416, ^bb423 {llvm.loop_annotation = #loop_annotation}
    ^bb416:  // pred: ^bb415
      cf.br ^bb417(%c0_i32 : i32)
    ^bb417(%1371: i32):  // 2 preds: ^bb416, ^bb421
      %1372 = arith.cmpi slt, %1371, %1331 : i32
      cf.cond_br %1372, ^bb418, ^bb422 {llvm.loop_annotation = #loop_annotation}
    ^bb418:  // pred: ^bb417
      cf.br ^bb419(%c0_i32 : i32)
    ^bb419(%1373: i32):  // 2 preds: ^bb418, ^bb420
      %1374 = arith.cmpi slt, %1373, %1331 : i32
      cf.cond_br %1374, ^bb420, ^bb421 {llvm.loop_annotation = #loop_annotation}
    ^bb420:  // pred: ^bb419
      cute_nvgpu.arch.mma.SM100.umma(%tup_586, %tup_588, %ptr_580, %1368, %1362) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1375 = arith.addi %1373, %c1_i32 : i32
      cf.br ^bb419(%1375 : i32)
    ^bb421:  // pred: ^bb419
      %1376 = arith.addi %1371, %c1_i32 : i32
      cf.br ^bb417(%1376 : i32)
    ^bb422:  // pred: ^bb417
      %1377 = arith.addi %1369, %c1_i32 : i32
      cf.br ^bb415(%1377 : i32)
    ^bb423:  // pred: ^bb415
      %1378 = cute_nvgpu.atom.set_value(%1359, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1379 = builtin.unrealized_conversion_cast %1378 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %1380 = arith.addi %1356, %c1_i32 : i32
      cf.br ^bb413(%1380, %1379 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb424:  // pred: ^bb413
      %1381 = nvvm.elect.sync -> i1
      cf.cond_br %1381, ^bb425, ^bb426
    ^bb425:  // pred: ^bb424
      %ptr_589 = cute.add_offset(%ptr_96, %int_tuple_576) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1382 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1382, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb426
    ^bb426:  // 2 preds: ^bb424, ^bb425
      %1383 = arith.addi %1340, %c1_i32 : i32
      cf.br ^bb407(%1383, %1349, %1351, %1353, %1357 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb427:  // pred: ^bb407
      %1384 = arith.addi %1332, %c1_i32 : i32
      cf.br ^bb405(%1384, %1344, %1341, %1342, %1343 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb428:  // pred: ^bb405
      %1385 = nvvm.elect.sync -> i1
      cf.cond_br %1385, ^bb429, ^bb430
    ^bb429:  // pred: ^bb428
      %ptr_590 = cute.add_offset(%iter_114, %int_tuple_571) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1386 = builtin.unrealized_conversion_cast %ptr_590 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1386, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb430
    ^bb430:  // 2 preds: ^bb428, ^bb429
      %1387 = nvvm.elect.sync -> i1
      cf.cond_br %1387, ^bb431, ^bb432
    ^bb431:  // pred: ^bb430
      %ptr_591 = cute.add_offset(%ptr_111, %int_tuple_569) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1388 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1388, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb432
    ^bb432:  // 2 preds: ^bb430, ^bb431
      cf.br ^bb434(%1319, %1321, %1323, %1326, %1328, %1330, %1333, %1334, %1335, %1336 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb433:  // pred: ^bb395
      cf.br ^bb434(%1098, %1099, %1100, %1101, %1102, %1103, %1097, %1314, %1315, %1316 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb434(%1389: i32, %1390: i32, %1391: i32, %1392: i32, %1393: i32, %1394: i32, %1395: !llvm.struct<(i1, i1, i1)>, %1396: i32, %1397: i32, %1398: i32):  // 2 preds: ^bb432, ^bb433
      cf.br ^bb435
    ^bb435:  // pred: ^bb434
      cf.br ^bb478(%1311, %1312, %1313, %1083, %1084, %1085, %1396, %1397, %1398, %1395, %1389, %1390, %1391, %1392, %1393, %1394 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb436:  // pred: ^bb248
      %1399 = arith.remsi %266, %c2_i32 : i32
      %1400 = arith.cmpi eq, %1399, %c0_i32 : i32
      cf.cond_br %1400, ^bb437, ^bb475
    ^bb437:  // pred: ^bb436
      %int_tuple_592 = cute.make_int_tuple(%996) : (i32) -> !cute.int_tuple<"?">
      %ptr_593 = cute.add_offset(%ptr_106, %int_tuple_592) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1401 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1401, %997, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1402 = arith.addi %996, %c1_i32 : i32
      %1403 = arith.addi %995, %c1_i32 : i32
      %1404 = arith.cmpi eq, %1402, %c2_i32 : i32
      %1405 = arith.select %1404, %c0_i32, %1402 : i32
      cf.cond_br %1404, ^bb438, ^bb439
    ^bb438:  // pred: ^bb437
      %1406 = arith.xori %997, %c1_i32 : i32
      cf.br ^bb440(%1406 : i32)
    ^bb439:  // pred: ^bb437
      cf.br ^bb440(%997 : i32)
    ^bb440(%1407: i32):  // 2 preds: ^bb438, ^bb439
      cf.br ^bb441
    ^bb441:  // pred: ^bb440
      %coord_594 = cute.make_coord(%996) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_595 = cute.crd2idx(%coord_594, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_596 = cute.add_offset(%345, %idx_595) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %1408 = cute_nvgpu.atom.set_value(%arg0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1409 = builtin.unrealized_conversion_cast %1408 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1410 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb442(%c0_i32, %998, %999, %1000, %1001, %1002, %1003, %1409, %998, %999, %1000 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb442(%1411: i32, %1412: i32, %1413: i32, %1414: i32, %1415: i32, %1416: i32, %1417: i32, %1418: !llvm.struct<(i1, i1, i1)>, %1419: i32, %1420: i32, %1421: i32):  // 2 preds: ^bb441, ^bb471
      %1422 = arith.cmpi slt, %1411, %c8_i32 : i32
      cf.cond_br %1422, ^bb443, ^bb472 {loop_annotation = #loop_annotation3}
    ^bb443:  // pred: ^bb442
      %int_tuple_597 = cute.make_int_tuple(%1413) : (i32) -> !cute.int_tuple<"?">
      %ptr_598 = cute.add_offset(%iter_14, %int_tuple_597) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1423 = builtin.unrealized_conversion_cast %ptr_598 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1423, %1414, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1424 = arith.addi %1413, %c1_i32 : i32
      %1425 = arith.addi %1412, %c1_i32 : i32
      %1426 = arith.cmpi eq, %1424, %c8_i32 : i32
      %1427 = arith.select %1426, %c0_i32, %1424 : i32
      cf.cond_br %1426, ^bb444, ^bb445
    ^bb444:  // pred: ^bb443
      %1428 = arith.xori %1414, %c1_i32 : i32
      cf.br ^bb446(%1428 : i32)
    ^bb445:  // pred: ^bb443
      cf.br ^bb446(%1414 : i32)
    ^bb446(%1429: i32):  // 2 preds: ^bb444, ^bb445
      cf.br ^bb447
    ^bb447:  // pred: ^bb446
      %coord_599 = cute.make_coord(%1411) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_600 = cute.crd2idx(%coord_599, %162) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,8):(0,0,2,512)">) -> !cute.int_tuple<"?{div=512}">
      %tup_601 = cute.add_offset(%ummaSmemDesc, %idx_600) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      %int_tuple_602 = cute.make_int_tuple(%1416) : (i32) -> !cute.int_tuple<"?">
      %ptr_603 = cute.add_offset(%iter_93, %int_tuple_602) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1430 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1430, %1417, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1431 = arith.addi %1416, %c1_i32 : i32
      %1432 = arith.addi %1415, %c1_i32 : i32
      %1433 = arith.cmpi eq, %1431, %c3_i32 : i32
      %1434 = arith.select %1433, %c0_i32, %1431 : i32
      cf.cond_br %1433, ^bb448, ^bb449
    ^bb448:  // pred: ^bb447
      %1435 = arith.xori %1417, %c1_i32 : i32
      cf.br ^bb450(%1435 : i32)
    ^bb449:  // pred: ^bb447
      cf.br ^bb450(%1417 : i32)
    ^bb450(%1436: i32):  // 2 preds: ^bb448, ^bb449
      cf.br ^bb451
    ^bb451:  // pred: ^bb450
      %coord_604 = cute.make_coord(%1416) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_605 = cute.crd2idx(%coord_604, %161) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_606 = cute.add_offset(%ummaSmemDesc_138, %idx_605) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb452(%c0_i32, %1418 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb452(%1437: i32, %1438: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb451, ^bb462
      %1439 = arith.cmpi slt, %1437, %c4_i32 : i32
      cf.cond_br %1439, ^bb453, ^bb463 {loop_annotation = #loop_annotation1}
    ^bb453:  // pred: ^bb452
      %1440 = builtin.unrealized_conversion_cast %1438 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_
      %coord_607 = cute.make_coord(%1437) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_608 = cute.crd2idx(%coord_607, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_609 = cute.add_offset(%tup_601, %idx_608) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_610 = cute.add_offset(%tup_606, %idx_608) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %1441 = cute_nvgpu.atom.get_value(%1440 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1442 = cute_nvgpu.atom.get_value(%1440 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1443 = cute_nvgpu.atom.get_value(%1440 : !mma_bf16_bf16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1444 = arith.extui %1441 : i1 to i32
      %1445 = arith.extui %1442 : i1 to i32
      %1446 = arith.shli %1444, %c13_i32 : i32
      %1447 = arith.shli %1445, %c14_i32 : i32
      %1448 = arith.ori %1446, %c138413200_i32 : i32
      %1449 = arith.ori %1448, %1447 : i32
      cf.br ^bb454(%c0_i32 : i32)
    ^bb454(%1450: i32):  // 2 preds: ^bb453, ^bb461
      %1451 = arith.cmpi slt, %1450, %1410 : i32
      cf.cond_br %1451, ^bb455, ^bb462 {llvm.loop_annotation = #loop_annotation}
    ^bb455:  // pred: ^bb454
      cf.br ^bb456(%c0_i32 : i32)
    ^bb456(%1452: i32):  // 2 preds: ^bb455, ^bb460
      %1453 = arith.cmpi slt, %1452, %1410 : i32
      cf.cond_br %1453, ^bb457, ^bb461 {llvm.loop_annotation = #loop_annotation}
    ^bb457:  // pred: ^bb456
      cf.br ^bb458(%c0_i32 : i32)
    ^bb458(%1454: i32):  // 2 preds: ^bb457, ^bb459
      %1455 = arith.cmpi slt, %1454, %1410 : i32
      cf.cond_br %1455, ^bb459, ^bb460 {llvm.loop_annotation = #loop_annotation}
    ^bb459:  // pred: ^bb458
      cute_nvgpu.arch.mma.SM100.umma(%tup_609, %tup_610, %ptr_596, %1449, %1443) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1456 = arith.addi %1454, %c1_i32 : i32
      cf.br ^bb458(%1456 : i32)
    ^bb460:  // pred: ^bb458
      %1457 = arith.addi %1452, %c1_i32 : i32
      cf.br ^bb456(%1457 : i32)
    ^bb461:  // pred: ^bb456
      %1458 = arith.addi %1450, %c1_i32 : i32
      cf.br ^bb454(%1458 : i32)
    ^bb462:  // pred: ^bb454
      %1459 = cute_nvgpu.atom.set_value(%1440, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_
      %1460 = builtin.unrealized_conversion_cast %1459 : !mma_bf16_bf16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %1461 = arith.addi %1437, %c1_i32 : i32
      cf.br ^bb452(%1461, %1460 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb463:  // pred: ^bb452
      %1462 = nvvm.elect.sync -> i1
      cf.cond_br %1462, ^bb464, ^bb465
    ^bb464:  // pred: ^bb463
      %ptr_611 = cute.add_offset(%ptr_96, %int_tuple_602) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1463 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1463, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb465
    ^bb465:  // 2 preds: ^bb463, ^bb464
      %1464 = nvvm.elect.sync -> i1
      cf.cond_br %1464, ^bb466, ^bb467
    ^bb466:  // pred: ^bb465
      %int_tuple_612 = cute.make_int_tuple(%1420) : (i32) -> !cute.int_tuple<"?">
      %ptr_613 = cute.add_offset(%ptr_22, %int_tuple_612) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1465 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1465, multicast_mask = %284 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb467
    ^bb467:  // 2 preds: ^bb465, ^bb466
      %1466 = arith.addi %1420, %c1_i32 : i32
      %1467 = arith.addi %1419, %c1_i32 : i32
      %1468 = arith.cmpi eq, %1466, %c8_i32 : i32
      %1469 = arith.select %1468, %c0_i32, %1466 : i32
      cf.cond_br %1468, ^bb468, ^bb469
    ^bb468:  // pred: ^bb467
      %1470 = arith.xori %1421, %c1_i32 : i32
      cf.br ^bb470(%1470 : i32)
    ^bb469:  // pred: ^bb467
      cf.br ^bb470(%1421 : i32)
    ^bb470(%1471: i32):  // 2 preds: ^bb468, ^bb469
      cf.br ^bb471
    ^bb471:  // pred: ^bb470
      %1472 = arith.addi %1411, %c1_i32 : i32
      cf.br ^bb442(%1472, %1425, %1427, %1429, %1432, %1434, %1436, %1438, %1467, %1469, %1471 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb472:  // pred: ^bb442
      %1473 = nvvm.elect.sync -> i1
      cf.cond_br %1473, ^bb473, ^bb474
    ^bb473:  // pred: ^bb472
      %ptr_614 = cute.add_offset(%iter_104, %int_tuple_592) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1474 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1474, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb474
    ^bb474:  // 2 preds: ^bb472, ^bb473
      cf.br ^bb476(%1403, %1405, %1407, %1412, %1413, %1414, %1415, %1416, %1417 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb475:  // pred: ^bb436
      cf.br ^bb476(%995, %996, %997, %998, %999, %1000, %1001, %1002, %1003 : i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb476(%1475: i32, %1476: i32, %1477: i32, %1478: i32, %1479: i32, %1480: i32, %1481: i32, %1482: i32, %1483: i32):  // 2 preds: ^bb474, ^bb475
      cf.br ^bb477
    ^bb477:  // pred: ^bb476
      cf.br ^bb478(%1475, %1476, %1477, %1478, %1479, %1480, %1481, %1482, %1483, %1014, %1005, %1006, %1007, %1008, %1009, %1010 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32)
    ^bb478(%1484: i32, %1485: i32, %1486: i32, %1487: i32, %1488: i32, %1489: i32, %1490: i32, %1491: i32, %1492: i32, %1493: !llvm.struct<(i1, i1, i1)>, %1494: i32, %1495: i32, %1496: i32, %1497: i32, %1498: i32, %1499: i32):  // 2 preds: ^bb435, ^bb477
      cf.br ^bb479
    ^bb479:  // pred: ^bb478
      cf.cond_br %977, ^bb480, ^bb517
    ^bb480:  // pred: ^bb479
      %int_tuple_615 = cute.make_int_tuple(%1495) : (i32) -> !cute.int_tuple<"?">
      %ptr_616 = cute.add_offset(%iter_109, %int_tuple_615) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1500 = builtin.unrealized_conversion_cast %ptr_616 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1500, %1496, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1501 = arith.addi %1495, %c1_i32 : i32
      %1502 = arith.addi %1494, %c1_i32 : i32
      %1503 = arith.cmpi eq, %1501, %c2_i32 : i32
      %1504 = arith.select %1503, %c0_i32, %1501 : i32
      cf.cond_br %1503, ^bb481, ^bb482
    ^bb481:  // pred: ^bb480
      %1505 = arith.xori %1496, %c1_i32 : i32
      cf.br ^bb483(%1505 : i32)
    ^bb482:  // pred: ^bb480
      cf.br ^bb483(%1496 : i32)
    ^bb483(%1506: i32):  // 2 preds: ^bb481, ^bb482
      cf.br ^bb484
    ^bb484:  // pred: ^bb483
      %int_tuple_617 = cute.make_int_tuple(%1498) : (i32) -> !cute.int_tuple<"?">
      %ptr_618 = cute.add_offset(%ptr_115, %int_tuple_617) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1507 = builtin.unrealized_conversion_cast %ptr_618 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1507, %1499, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1508 = arith.addi %1498, %c1_i32 : i32
      %1509 = arith.addi %1497, %c1_i32 : i32
      %1510 = arith.cmpi eq, %1508, %c1_i32 : i32
      %1511 = arith.select %1510, %c0_i32, %1508 : i32
      cf.cond_br %1510, ^bb485, ^bb486
    ^bb485:  // pred: ^bb484
      %1512 = arith.xori %1499, %c1_i32 : i32
      cf.br ^bb487(%1512 : i32)
    ^bb486:  // pred: ^bb484
      cf.br ^bb487(%1499 : i32)
    ^bb487(%1513: i32):  // 2 preds: ^bb485, ^bb486
      cf.br ^bb488
    ^bb488:  // pred: ^bb487
      %1514 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      cf.br ^bb489(%c0_i32, %1493, %1490, %1491, %1492 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb489(%1515: i32, %1516: !llvm.struct<(i1, i1, i1)>, %1517: i32, %1518: i32, %1519: i32):  // 2 preds: ^bb488, ^bb511
      %1520 = arith.cmpi slt, %1515, %c4_i32 : i32
      cf.cond_br %1520, ^bb490, ^bb512 {loop_annotation = #loop_annotation2}
    ^bb490:  // pred: ^bb489
      %1521 = builtin.unrealized_conversion_cast %1516 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %1522 = cute_nvgpu.atom.get_value(%1521 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %coord_619 = cute.make_coord(%1515, %1495) : (i32, i32) -> !cute.coord<"(_,_,_,(?,?))">
      %idx_620 = cute.crd2idx(%coord_619, %159) : (!cute.coord<"(_,_,_,(?,?))">, !cute.layout<"(1,1,4,(4,2)):(0,0,2,(512,2048))">) -> !cute.int_tuple<"?{div=512}">
      %tup_621 = cute.add_offset(%ummaSmemDesc_137, %idx_620) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb491(%c0_i32, %1517, %1518, %1519, %1516 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb491(%1523: i32, %1524: i32, %1525: i32, %1526: i32, %1527: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb490, ^bb510
      %1528 = arith.cmpi slt, %1523, %c2_i32 : i32
      cf.cond_br %1528, ^bb492, ^bb511 {loop_annotation = #loop_annotation3}
    ^bb492:  // pred: ^bb491
      %1529 = builtin.unrealized_conversion_cast %1527 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %int_tuple_622 = cute.make_int_tuple(%1525) : (i32) -> !cute.int_tuple<"?">
      %ptr_623 = cute.add_offset(%iter_93, %int_tuple_622) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1530 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1530, %1526, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1531 = arith.addi %1525, %c1_i32 : i32
      %1532 = arith.addi %1524, %c1_i32 : i32
      %1533 = arith.cmpi eq, %1531, %c3_i32 : i32
      %1534 = arith.select %1533, %c0_i32, %1531 : i32
      cf.cond_br %1533, ^bb493, ^bb494
    ^bb493:  // pred: ^bb492
      %1535 = arith.xori %1526, %c1_i32 : i32
      cf.br ^bb495(%1535 : i32)
    ^bb494:  // pred: ^bb492
      cf.br ^bb495(%1526 : i32)
    ^bb495(%1536: i32):  // 2 preds: ^bb493, ^bb494
      cf.br ^bb496
    ^bb496:  // pred: ^bb495
      %1537 = cute_nvgpu.atom.set_value(%1529, %1522 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1538 = builtin.unrealized_conversion_cast %1537 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %coord_624 = cute.make_coord(%1523) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_625 = cute.crd2idx(%coord_624, %201) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_626 = cute.add_offset(%ptr_140, %idx_625) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %coord_627 = cute.make_coord(%1525) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_628 = cute.crd2idx(%coord_627, %158) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(1,1,4,3):(0,0,128,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_629 = cute.add_offset(%ummaSmemDesc_139, %idx_628) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb497(%c0_i32, %1538 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb497(%1539: i32, %1540: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb496, ^bb507
      %1541 = arith.cmpi slt, %1539, %c4_i32 : i32
      cf.cond_br %1541, ^bb498, ^bb508 {loop_annotation = #loop_annotation1}
    ^bb498:  // pred: ^bb497
      %1542 = builtin.unrealized_conversion_cast %1540 : !llvm.struct<(i1, i1, i1)> to !mma_bf16_bf16_f32_128x256x16_1
      %coord_630 = cute.make_coord(%1539) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_631 = cute.crd2idx(%coord_630, %160) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,2)">) -> !cute.int_tuple<"?{div=2}">
      %tup_632 = cute.add_offset(%tup_621, %idx_631) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_633 = cute.crd2idx(%coord_630, %157) : (!cute.coord<"(_,_,?)">, !cute.layout<"(1,1,4):(0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %tup_634 = cute.add_offset(%tup_629, %idx_633) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=128}">) -> !cute_nvgpu.smem_desc
      %1543 = cute_nvgpu.atom.get_value(%1542 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %1544 = cute_nvgpu.atom.get_value(%1542 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %1545 = cute_nvgpu.atom.get_value(%1542 : !mma_bf16_bf16_f32_128x256x16_1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %1546 = arith.extui %1543 : i1 to i32
      %1547 = arith.extui %1544 : i1 to i32
      %1548 = arith.shli %1546, %c13_i32 : i32
      %1549 = arith.shli %1547, %c14_i32 : i32
      %1550 = arith.ori %1548, %c138478736_i32 : i32
      %1551 = arith.ori %1550, %1549 : i32
      cf.br ^bb499(%c0_i32 : i32)
    ^bb499(%1552: i32):  // 2 preds: ^bb498, ^bb506
      %1553 = arith.cmpi slt, %1552, %1514 : i32
      cf.cond_br %1553, ^bb500, ^bb507 {llvm.loop_annotation = #loop_annotation}
    ^bb500:  // pred: ^bb499
      cf.br ^bb501(%c0_i32 : i32)
    ^bb501(%1554: i32):  // 2 preds: ^bb500, ^bb505
      %1555 = arith.cmpi slt, %1554, %1514 : i32
      cf.cond_br %1555, ^bb502, ^bb506 {llvm.loop_annotation = #loop_annotation}
    ^bb502:  // pred: ^bb501
      cf.br ^bb503(%c0_i32 : i32)
    ^bb503(%1556: i32):  // 2 preds: ^bb502, ^bb504
      %1557 = arith.cmpi slt, %1556, %1514 : i32
      cf.cond_br %1557, ^bb504, ^bb505 {llvm.loop_annotation = #loop_annotation}
    ^bb504:  // pred: ^bb503
      cute_nvgpu.arch.mma.SM100.umma(%tup_632, %tup_634, %ptr_626, %1551, %1545) {num_cta = 2 : i32, scale = 0 : i32, a_type = bf16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<1>>, i32, i1) -> ()
      %1558 = arith.addi %1556, %c1_i32 : i32
      cf.br ^bb503(%1558 : i32)
    ^bb505:  // pred: ^bb503
      %1559 = arith.addi %1554, %c1_i32 : i32
      cf.br ^bb501(%1559 : i32)
    ^bb506:  // pred: ^bb501
      %1560 = arith.addi %1552, %c1_i32 : i32
      cf.br ^bb499(%1560 : i32)
    ^bb507:  // pred: ^bb499
      %1561 = cute_nvgpu.atom.set_value(%1542, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_bf16_bf16_f32_128x256x16_1
      %1562 = builtin.unrealized_conversion_cast %1561 : !mma_bf16_bf16_f32_128x256x16_1 to !llvm.struct<(i1, i1, i1)>
      %1563 = arith.addi %1539, %c1_i32 : i32
      cf.br ^bb497(%1563, %1562 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb508:  // pred: ^bb497
      %1564 = nvvm.elect.sync -> i1
      cf.cond_br %1564, ^bb509, ^bb510
    ^bb509:  // pred: ^bb508
      %ptr_635 = cute.add_offset(%ptr_96, %int_tuple_622) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1565 = builtin.unrealized_conversion_cast %ptr_635 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1565, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb510
    ^bb510:  // 2 preds: ^bb508, ^bb509
      %1566 = arith.addi %1523, %c1_i32 : i32
      cf.br ^bb491(%1566, %1532, %1534, %1536, %1540 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb511:  // pred: ^bb491
      %1567 = arith.addi %1515, %c1_i32 : i32
      cf.br ^bb489(%1567, %1527, %1524, %1525, %1526 : i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb512:  // pred: ^bb489
      %1568 = nvvm.elect.sync -> i1
      cf.cond_br %1568, ^bb513, ^bb514
    ^bb513:  // pred: ^bb512
      %ptr_636 = cute.add_offset(%iter_114, %int_tuple_617) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1569 = builtin.unrealized_conversion_cast %ptr_636 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1569, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb514
    ^bb514:  // 2 preds: ^bb512, ^bb513
      %1570 = nvvm.elect.sync -> i1
      cf.cond_br %1570, ^bb515, ^bb516
    ^bb515:  // pred: ^bb514
      %ptr_637 = cute.add_offset(%ptr_111, %int_tuple_615) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1571 = builtin.unrealized_conversion_cast %ptr_637 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %1571, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb516
    ^bb516:  // 2 preds: ^bb514, ^bb515
      cf.br ^bb518(%1502, %1504, %1506, %1509, %1511, %1513, %1516, %1517, %1518, %1519 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb517:  // pred: ^bb479
      cf.br ^bb518(%1494, %1495, %1496, %1497, %1498, %1499, %1493, %1490, %1491, %1492 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb518(%1572: i32, %1573: i32, %1574: i32, %1575: i32, %1576: i32, %1577: i32, %1578: !llvm.struct<(i1, i1, i1)>, %1579: i32, %1580: i32, %1581: i32):  // 2 preds: ^bb516, ^bb517
      cf.br ^bb519
    ^bb519:  // pred: ^bb518
      cf.br ^bb247(%1484, %1485, %1486, %1487, %1488, %1489, %1579, %1580, %1581, %1578, %1572, %1573, %1574, %1575, %1576, %1577, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32, i32, i1)
    ^bb520:  // pred: ^bb247
      %1582 = arith.remsi %266, %c2_i32 : i32
      %1583 = arith.cmpi eq, %1582, %c0_i32 : i32
      cf.cond_br %1583, ^bb521, ^bb526
    ^bb521:  // pred: ^bb520
      %1584 = arith.addi %979, %c1_i32 : i32
      %1585 = arith.cmpi eq, %1584, %c2_i32 : i32
      %1586 = arith.select %1585, %c0_i32, %1584 : i32
      cf.cond_br %1585, ^bb522, ^bb523
    ^bb522:  // pred: ^bb521
      %1587 = arith.xori %980, %c1_i32 : i32
      cf.br ^bb524(%1587 : i32)
    ^bb523:  // pred: ^bb521
      cf.br ^bb524(%980 : i32)
    ^bb524(%1588: i32):  // 2 preds: ^bb522, ^bb523
      cf.br ^bb525
    ^bb525:  // pred: ^bb524
      %int_tuple_638 = cute.make_int_tuple(%1586) : (i32) -> !cute.int_tuple<"?">
      %ptr_639 = cute.add_offset(%ptr_106, %int_tuple_638) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1589 = builtin.unrealized_conversion_cast %ptr_639 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1589, %1588, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb526
    ^bb526:  // 2 preds: ^bb520, ^bb525
      cf.cond_br %1583, ^bb527, ^bb528
    ^bb527:  // pred: ^bb526
      %int_tuple_640 = cute.make_int_tuple(%992) : (i32) -> !cute.int_tuple<"?">
      %ptr_641 = cute.add_offset(%ptr_115, %int_tuple_640) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1590 = builtin.unrealized_conversion_cast %ptr_641 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1590, %993, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb528
    ^bb528:  // 2 preds: ^bb526, ^bb527
      cf.br ^bb534(%994 : i1)
    ^bb529:  // pred: ^bb241
      cf.cond_br %342, ^bb530, ^bb533
    ^bb530:  // pred: ^bb529
      %1591 = nvvm.elect.sync -> i1
      cf.cond_br %1591, ^bb531, ^bb532
    ^bb531:  // pred: ^bb530
      %1592 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1592, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb532
    ^bb532:  // 2 preds: ^bb530, ^bb531
      cf.br ^bb533
    ^bb533:  // 2 preds: ^bb529, ^bb532
      nvvm.fence.mbarrier.init
      cf.br ^bb534(%953 : i1)
    ^bb534(%1593: i1):  // 2 preds: ^bb528, ^bb533
      cf.br ^bb535
    ^bb535:  // pred: ^bb534
      cf.cond_br %342, ^bb536, ^bb539
    ^bb536:  // pred: ^bb535
      %1594 = nvvm.elect.sync -> i1
      cf.cond_br %1594, ^bb537, ^bb538
    ^bb537:  // pred: ^bb536
      %1595 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1595, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb538
    ^bb538:  // 2 preds: ^bb536, ^bb537
      cf.br ^bb539
    ^bb539:  // 2 preds: ^bb535, ^bb538
      nvvm.fence.mbarrier.init
      %1596 = arith.cmpi slt, %244, %c12_i32 : i32
      %1597 = arith.cmpi sge, %244, %c8_i32 : i32
      %1598 = arith.extui %1596 : i1 to i32
      %1599 = arith.extui %1597 : i1 to i32
      %1600 = arith.select %1596, %1599, %1598 : i32
      %1601 = arith.cmpi ne, %1600, %c0_i32 : i32
      cf.cond_br %1601, ^bb540, ^bb635
    ^bb540:  // pred: ^bb539
      cf.cond_br %342, ^bb541, ^bb544
    ^bb541:  // pred: ^bb540
      %1602 = nvvm.elect.sync -> i1
      cf.cond_br %1602, ^bb542, ^bb543
    ^bb542:  // pred: ^bb541
      %1603 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %1603, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb543
    ^bb543:  // 2 preds: ^bb541, ^bb542
      cf.br ^bb544
    ^bb544:  // 2 preds: ^bb540, ^bb543
      nvvm.fence.mbarrier.init
      nvvm.setmaxregister  increase 192
      cf.cond_br %342, ^bb545, ^bb546
    ^bb545:  // pred: ^bb544
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_13) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb546
    ^bb546:  // 2 preds: ^bb544, ^bb545
      nvvm.barrier id = %c1_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_13) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_642 = cute.make_int_tuple(%itup_286) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %1604 = cute.get_scalars(%int_tuple_642) <{only_dynamic}> : !cute.int_tuple<"?">
      %c1_i32_643 = arith.constant 1 : i32
      %c0_i32_644 = arith.constant 0 : i32
      %c-1_i32_645 = arith.constant -1 : i32
      %1605 = arith.cmpi sgt, %c256_i32, %c0_i32_644 : i32
      %1606 = arith.select %1605, %c-1_i32_645, %c1_i32_643 : i32
      %1607 = arith.addi %1606, %1604 : i32
      %1608 = arith.divsi %1607, %c256_i32 : i32
      %1609 = arith.addi %c1_i32_643, %1608 : i32
      %1610 = arith.subi %c0_i32_644, %1604 : i32
      %1611 = arith.divsi %1610, %c256_i32 : i32
      %1612 = arith.subi %c0_i32_644, %1611 : i32
      %1613 = arith.cmpi slt, %1604, %c0_i32_644 : i32
      %1614 = arith.cmpi sgt, %1604, %c0_i32_644 : i32
      %1615 = arith.cmpi slt, %c256_i32, %c0_i32_644 : i32
      %1616 = arith.cmpi sgt, %c256_i32, %c0_i32_644 : i32
      %1617 = arith.andi %1613, %1615 : i1
      %1618 = arith.andi %1614, %1616 : i1
      %1619 = arith.ori %1617, %1618 : i1
      %1620 = arith.select %1619, %1609, %1612 : i32
      %int_tuple_646 = cute.make_int_tuple(%1620) : (i32) -> !cute.int_tuple<"?">
      %e0_647 = cute.get_leaves(%int_tuple_646) : !cute.int_tuple<"?">
      %sub_648 = cute.tuple_sub(%e0_647, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %1621 = cute.get_scalars(%sub_648) : !cute.int_tuple<"?">
      %coord_649 = cute.make_coord(%246, %569, %570) : (i32, i32, i32) -> !cute.coord<"(_,_,?,_,(?,?))">
      %1622:10 = cute.get_scalars(%lay_254) <{only_dynamic}> : !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">
      %shape_650 = cute.make_shape(%1622#1) : (i32) -> !cute.shape<"(64,256,?)">
      %iv_651 = cute.assume(%1622#5) : (i32) -> !cute.i32<divby 256>
      %stride_652 = cute.make_stride(%iv_651) : (!cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1,256)">
      %lay_653 = cute.make_layout(%shape_650, %stride_652) : !cute.layout<"(64,256,?):(?{div=256},1,256)">
      %idx_654 = cute.crd2idx(%coord_649, %lay_254) : (!cute.coord<"(_,_,?,_,(?,?))">, !cute.layout<"(64,256,?,?,((?,?),?)):(?{div=256},1,?{div=16384},256,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.int_tuple<"?{div=256}">
      %ptr_655 = cute.add_offset(%iter_240, %idx_654) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, gmem, align<128>>
      %1623:5 = cute.get_scalars(%lay_274) <{only_dynamic}> : !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">
      %shape_656 = cute.make_shape(%1623#1) : (i32) -> !cute.shape<"(64,256,?)">
      %lay_657 = cute.make_layout(%shape_656, %156) : !cute.layout<"(64,256,?):(1@0,1@1,256@1)">
      %idx_658 = cute.crd2idx(%coord_649, %lay_274) : (!cute.coord<"(_,_,?,_,(?,?))">, !cute.layout<"(64,256,?,?,((?,?),?)):(1@0,1@1,64@0,256@1,((1@0@0@2,1@1@0@2),1@1@2))">) -> !cute.int_tuple<"(?{div=64},0,((?,?),?))">
      %tup_659 = cute.add_offset(%175, %idx_658) : (!cute.int_tuple<"(0,0,((0,0),0))">, !cute.int_tuple<"(?{div=64},0,((?,?),?))">) -> !cute.int_tuple<"(?{div=64},0,((?,?),?))">
      %1624 = arith.remsi %225, %c128_i32 : i32
      %coord_660 = cute.make_coord(%1624) : (i32) -> !cute.coord<"?">
      %1625 = cute.get_scalars(%coord_660) <{only_dynamic}> : !cute.coord<"?">
      %1626 = arith.divsi %1625, %c32_i32 : i32
      %1627 = arith.divsi %1626, %c2_i32 : i32
      %1628 = arith.remsi %1626, %c2_i32 : i32
      %1629 = arith.muli %1628, %c2097152_i32 : i32
      %1630 = arith.muli %1627, %c4194304_i32 : i32
      %1631 = arith.addi %1629, %1630 : i32
      %iv_661 = cute.assume(%1631) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_662 = cute.make_int_tuple(%iv_661) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1632 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %1633 = arith.addi %1624, %c64_i32 : i32
      %1634 = arith.remsi %1633, %c128_i32 : i32
      %coord_663 = cute.make_coord(%1634) : (i32) -> !cute.coord<"?">
      %1635 = vector.splat %arg13 : vector<2xf32>
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %1636 = arith.remsi %1625, %c32_i32 : i32
      %1637 = arith.muli %1636, %c64_i32 : i32
      %1638 = arith.muli %1628, %c2048_i32 : i32
      %1639 = arith.addi %1637, %1638 : i32
      %1640 = arith.muli %1627, %c8192_i32 : i32
      %1641 = arith.addi %1639, %1640 : i32
      %iv_664 = cute.assume(%1641) : (i32) -> !cute.i32<divby 64>
      %int_tuple_665 = cute.make_int_tuple(%iv_664) : (!cute.i32<divby 64>) -> !cute.int_tuple<"?{div=64}">
      %ptr_666 = cute.add_offset(%iter_131, %int_tuple_665) : (!cute.ptr<bf16, smem, align<256>, S<3,4,3>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<bf16, smem, align<128>, S<3,4,3>>
      %1642 = vector.splat %arg13 : vector<2xf32>
      %1643 = arith.muli %1626, %c2097152_i32 : i32
      %iv_667 = cute.assume(%1643) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_668 = cute.make_int_tuple(%iv_667) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1644 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %1645:2 = cute.get_scalars(%lay_653) <{only_dynamic}> : !cute.layout<"(64,256,?):(?{div=256},1,256)">
      %iv_669 = cute.assume(%1645#1) : (i32) -> !cute.i32<divby 256>
      %stride_670 = cute.make_stride(%iv_669) : (!cute.i32<divby 256>) -> !cute.stride<"(?{div=256},1)">
      %lay_671 = cute.make_layout(%19, %stride_670) : !cute.layout<"(64,256):(?{div=256},1)">
      %1646 = cute.get_scalars(%lay_671) <{only_dynamic}> : !cute.layout<"(64,256):(?{div=256},1)">
      %iv_672 = cute.assume(%1646) : (i32) -> !cute.i32<divby 256>
      %stride_673 = cute.make_stride(%iv_672) : (!cute.i32<divby 256>) -> !cute.stride<"((?{div=256},(1,128)),(0,32))">
      %lay_674 = cute.make_layout(%18, %stride_673) : !cute.layout<"((64,(32,2)),(1,4)):((?{div=256},(1,128)),(0,32))">
      %1647 = arith.muli %1626, %c2097152_i32 : i32
      %iv_675 = cute.assume(%1647) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_676 = cute.make_int_tuple(%iv_675) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %1648 = cute.get_scalars(%lay_674) <{only_dynamic}> : !cute.layout<"((64,(32,2)),(1,4)):((?{div=256},(1,128)),(0,32))">
      %1649 = arith.muli %1648, %c32_i32 : i32
      %1650 = arith.muli %1636, %1648 : i32
      %1651 = arith.muli %1628, %1649 : i32
      %1652 = arith.muli %1627, %c128_i32 : i32
      %1653 = arith.addi %1651, %1652 : i32
      %1654 = arith.addi %1650, %1653 : i32
      %iv_677 = cute.assume(%1654) : (i32) -> !cute.i32<divby 128>
      %int_tuple_678 = cute.make_int_tuple(%iv_677) : (!cute.i32<divby 128>) -> !cute.int_tuple<"?{div=128}">
      %1655 = arith.muli %1628, %c32_i32 : i32
      %1656 = arith.addi %1636, %1655 : i32
      %iv_679 = cute.assume(%1652) : (i32) -> !cute.i32<divby 128>
      %int_tuple_680 = cute.make_int_tuple(%1656, %iv_679) : (i32, !cute.i32<divby 128>) -> !cute.int_tuple<"(?,?{div=128})">
      %1657 = cute.get_scalars(%212) : !cute.int_tuple<"1">
      %coord_681 = cute.make_coord(%itup_280) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %1658 = cute.get_scalars(%coord_681) : !cute.coord<"?">
      cf.br ^bb547(%c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %1593 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb547(%1659: i32, %1660: i32, %1661: i32, %1662: i32, %1663: i32, %1664: i32, %1665: i32, %1666: i32, %1667: i32, %1668: i1):  // 2 preds: ^bb546, ^bb625
      cf.cond_br %1668, ^bb548(%1659, %1660, %1661, %1662, %1663, %1664, %1665, %1666, %1667, %1668 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1), ^bb626
    ^bb548(%1669: i32, %1670: i32, %1671: i32, %1672: i32, %1673: i32, %1674: i32, %1675: i32, %1676: i32, %1677: i32, %1678: i1):  // pred: ^bb547
      %int_tuple_682 = cute.make_int_tuple(%1670) : (i32) -> !cute.int_tuple<"?">
      %ptr_683 = cute.add_offset(%iter_104, %int_tuple_682) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1679 = builtin.unrealized_conversion_cast %ptr_683 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1679, %1671, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1680 = arith.addi %1670, %c1_i32 : i32
      %1681 = arith.addi %1669, %c1_i32 : i32
      %1682 = arith.cmpi eq, %1680, %c2_i32 : i32
      %1683 = arith.select %1682, %c0_i32, %1680 : i32
      cf.cond_br %1682, ^bb549, ^bb550
    ^bb549:  // pred: ^bb548
      %1684 = arith.xori %1671, %c1_i32 : i32
      cf.br ^bb551(%1684 : i32)
    ^bb550:  // pred: ^bb548
      cf.br ^bb551(%1671 : i32)
    ^bb551(%1685: i32):  // 2 preds: ^bb549, ^bb550
      cf.br ^bb552
    ^bb552:  // pred: ^bb551
      %coord_684 = cute.make_coord(%1670) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_685 = cute.crd2idx(%coord_684, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_686 = cute.add_offset(%345, %idx_685) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_687 = cute.add_offset(%ptr_686, %int_tuple_662) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_688 = cute.get_iter(%rmem) : !memref_rmem_f32_
      cf.br ^bb553(%c0_i32 : i32)
    ^bb553(%1686: i32):  // 2 preds: ^bb552, ^bb554
      %1687 = arith.cmpi slt, %1686, %1632 : i32
      cf.cond_br %1687, ^bb554, ^bb555 {llvm.loop_annotation = #loop_annotation}
    ^bb554:  // pred: ^bb553
      %coord_689 = cute.make_coord(%1686) : (i32) -> !cute.coord<"(_,?)">
      %idx_690 = cute.crd2idx(%coord_689, %153) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,32),1),((1,4))):(((1,65536),0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_691 = cute.add_offset(%ptr_687, %idx_690) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_692 = cute.crd2idx(%coord_689, %152) : (!cute.coord<"(_,?)">, !cute.layout<"((32,1),((1,4))):((1,0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_693 = cute.add_offset(%iter_688, %idx_692) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, rmem, align<32>>
      %1688 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_691) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      %1689 = builtin.unrealized_conversion_cast %ptr_693 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      llvm.store %1688, %1689 : vector<32xi32>, !llvm.ptr
      %1690 = arith.addi %1686, %c1_i32 : i32
      cf.br ^bb553(%1690 : i32)
    ^bb555:  // pred: ^bb553
      nvvm.tcgen05.wait <load>
      %ptr_694 = cute.add_offset(%ptr_106, %int_tuple_682) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1691 = builtin.unrealized_conversion_cast %ptr_694 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %1692 = nvvm.mapa.shared.cluster %1691, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %1692, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %1693 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %1694 = vector.reduction <maximumf>, %1693, %cst_2 : vector<128xf32> into f32
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_660, %1694) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %1695 = cute.memref.load(%view, %coord_663) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %1696 = nvvm.fmax %1694, %1695
      %1697 = arith.cmpf oeq, %1696, %cst_2 : f32
      %1698 = arith.select %1697, %cst_1, %1696 : f32
      %1699 = arith.subf %cst_1, %1698 : f32
      %1700 = arith.mulf %1699, %arg13 : f32
      %rmem_695 = cute.memref.alloca() : !memref_rmem_bf16_
      %1701 = vector.splat %1700 : vector<2xf32>
      cf.br ^bb556(%c0_i32 : i32)
    ^bb556(%1702: i32):  // 2 preds: ^bb555, ^bb557
      %1703 = arith.cmpi slt, %1702, %c128_i32 : i32
      cf.cond_br %1703, ^bb557, ^bb558
    ^bb557:  // pred: ^bb556
      %coord_696 = cute.make_coord(%1702) : (i32) -> !cute.coord<"?">
      %1704 = cute.memref.load(%rmem, %coord_696) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1705 = arith.addi %1702, %c1_i32 : i32
      %coord_697 = cute.make_coord(%1705) : (i32) -> !cute.coord<"?">
      %1706 = cute.memref.load(%rmem, %coord_697) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1707 = vector.from_elements %1704, %1706 : vector<2xf32>
      %1708 = nvvm.fma.packed.f32x2 %1707, %1635, %1701 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1709 = vector.extract %1708[0] : f32 from vector<2xf32>
      %1710 = vector.extract %1708[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem, %coord_696, %1709) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem, %coord_697, %1710) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1711 = cute.memref.load(%rmem, %coord_696) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1712 = math.exp2 %1711 fastmath<fast> : f32
      cute.memref.store(%rmem, %coord_696, %1712) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1713 = cute.memref.load(%rmem, %coord_697) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %1714 = math.exp2 %1713 fastmath<fast> : f32
      cute.memref.store(%rmem, %coord_697, %1714) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %1715 = arith.addi %1702, %c2_i32 : i32
      cf.br ^bb556(%1715 : i32)
    ^bb558:  // pred: ^bb556
      %1716 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %1717 = arith.truncf %1716 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %1717, %rmem_695 : !memref_rmem_bf16_
      %int_tuple_698 = cute.make_int_tuple(%1673) : (i32) -> !cute.int_tuple<"?">
      %ptr_699 = cute.add_offset(%ptr_111, %int_tuple_698) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1718 = builtin.unrealized_conversion_cast %ptr_699 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %1718, %1674, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %1719 = arith.addi %1673, %c1_i32 : i32
      %1720 = arith.addi %1672, %c1_i32 : i32
      %1721 = arith.cmpi eq, %1719, %c2_i32 : i32
      %1722 = arith.select %1721, %c0_i32, %1719 : i32
      cf.cond_br %1721, ^bb559, ^bb560
    ^bb559:  // pred: ^bb558
      %1723 = arith.xori %1674, %c1_i32 : i32
      cf.br ^bb561(%1723 : i32)
    ^bb560:  // pred: ^bb558
      cf.br ^bb561(%1674 : i32)
    ^bb561(%1724: i32):  // 2 preds: ^bb559, ^bb560
      cf.br ^bb562
    ^bb562:  // pred: ^bb561
      %coord_700 = cute.make_coord(%1673) : (i32) -> !cute.coord<"(_,_,_,(_,?))">
      %idx_701 = cute.crd2idx(%coord_700, %204) : (!cute.coord<"(_,_,_,(_,?))">, !cute.layout<"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">) -> !cute.int_tuple<"?{div=16384}">
      %1725 = cute.make_tiled_copy(%atom) : !copy_simt
      %iter_702 = cute.get_iter(%rmem_695) : !memref_rmem_bf16_
      cf.br ^bb563(%c0_i32 : i32)
    ^bb563(%1726: i32):  // 2 preds: ^bb562, ^bb564
      %1727 = arith.cmpi slt, %1726, %1632 : i32
      cf.cond_br %1727, ^bb564, ^bb565 {llvm.loop_annotation = #loop_annotation}
    ^bb564:  // pred: ^bb563
      %coord_703 = cute.make_coord(%1726) : (i32) -> !cute.coord<"(_,?)">
      %idx_704 = cute.crd2idx(%coord_703, %151) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,4))):((1,8),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_705 = cute.add_offset(%iter_702, %idx_704) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_706 = cute.crd2idx(%coord_703, %150) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,(2,2)))):((1,8),((0,(32,4096))))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_707 = cute.add_offset(%ptr_666, %idx_706) : (!cute.ptr<bf16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %swizzled = cute.apply_swizzle(%ptr_707) : !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %ptr_708 = cute.add_offset(%swizzled, %idx_701) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %1728 = builtin.unrealized_conversion_cast %ptr_705 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1729 = builtin.unrealized_conversion_cast %ptr_708 : !cute.ptr<bf16, smem, align<64>, S<3,4,3>> to !llvm.ptr<3>
      %1730 = llvm.load %1728 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1730, %1729 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_709 = cute.add_offset(%ptr_705, %205) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_710 = cute.add_offset(%ptr_707, %205) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_711 = cute.apply_swizzle(%ptr_710) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_712 = cute.add_offset(%swizzled_711, %idx_701) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1731 = builtin.unrealized_conversion_cast %ptr_709 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1732 = builtin.unrealized_conversion_cast %ptr_712 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1733 = llvm.load %1731 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1733, %1732 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_713 = cute.add_offset(%ptr_705, %149) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_714 = cute.add_offset(%ptr_707, %149) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %swizzled_715 = cute.apply_swizzle(%ptr_714) : !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %ptr_716 = cute.add_offset(%swizzled_715, %idx_701) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %1734 = builtin.unrealized_conversion_cast %ptr_713 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %1735 = builtin.unrealized_conversion_cast %ptr_716 : !cute.ptr<bf16, smem, align<32>, S<3,4,3>> to !llvm.ptr<3>
      %1736 = llvm.load %1734 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1736, %1735 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_717 = cute.add_offset(%ptr_705, %148) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_718 = cute.add_offset(%ptr_707, %148) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_719 = cute.apply_swizzle(%ptr_718) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_720 = cute.add_offset(%swizzled_719, %idx_701) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %1737 = builtin.unrealized_conversion_cast %ptr_717 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %1738 = builtin.unrealized_conversion_cast %ptr_720 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %1739 = llvm.load %1737 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %1739, %1738 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %1740 = arith.addi %1726, %c1_i32 : i32
      cf.br ^bb563(%1740 : i32)
    ^bb565:  // pred: ^bb563
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_721 = cute.add_offset(%iter_109, %int_tuple_698) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %1741 = builtin.unrealized_conversion_cast %ptr_721 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %1742 = nvvm.mapa.shared.cluster %1741, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %1742, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %1743 = arith.subf %cst_2, %1698 : f32
      %1744 = arith.mulf %arg13, %1743 : f32
      %1745 = math.exp2 %1744 fastmath<fast> : f32
      %1746 = arith.mulf %1745, %cst_0 : f32
      %1747 = arith.mulf %1746, %cst_1 : f32
      %view_722 = cute.make_view(%iter_688) : !memref_rmem_f32_1
      %1748 = cute.memref.load(%view_722, %147) : (!memref_rmem_f32_1, !cute.coord<"(0,0)">) -> f32
      %1749 = cute.memref.load(%view_722, %146) : (!memref_rmem_f32_1, !cute.coord<"(1,0)">) -> f32
      %1750 = vector.splat %1747 : vector<2xf32>
      %1751 = vector.from_elements %1748, %1749 : vector<2xf32>
      %1752 = nvvm.add.packed.f32x2 %1750, %1751 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1753 = vector.extract %1752[0] : f32 from vector<2xf32>
      %1754 = vector.extract %1752[1] : f32 from vector<2xf32>
      %1755 = cute.memref.load(%view_722, %145) : (!memref_rmem_f32_1, !cute.coord<"(0,1)">) -> f32
      %1756 = cute.memref.load(%view_722, %144) : (!memref_rmem_f32_1, !cute.coord<"(1,1)">) -> f32
      %1757 = vector.from_elements %1755, %1756 : vector<2xf32>
      %1758 = nvvm.add.packed.f32x2 %cst, %1757 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1759 = vector.extract %1758[0] : f32 from vector<2xf32>
      %1760 = vector.extract %1758[1] : f32 from vector<2xf32>
      %1761 = cute.memref.load(%view_722, %143) : (!memref_rmem_f32_1, !cute.coord<"(0,2)">) -> f32
      %1762 = cute.memref.load(%view_722, %142) : (!memref_rmem_f32_1, !cute.coord<"(1,2)">) -> f32
      %1763 = vector.from_elements %1761, %1762 : vector<2xf32>
      %1764 = nvvm.add.packed.f32x2 %cst, %1763 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1765 = vector.extract %1764[0] : f32 from vector<2xf32>
      %1766 = vector.extract %1764[1] : f32 from vector<2xf32>
      %1767 = cute.memref.load(%view_722, %141) : (!memref_rmem_f32_1, !cute.coord<"(0,3)">) -> f32
      %1768 = cute.memref.load(%view_722, %140) : (!memref_rmem_f32_1, !cute.coord<"(1,3)">) -> f32
      %1769 = vector.from_elements %1767, %1768 : vector<2xf32>
      %1770 = nvvm.add.packed.f32x2 %cst, %1769 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1771 = vector.extract %1770[0] : f32 from vector<2xf32>
      %1772 = vector.extract %1770[1] : f32 from vector<2xf32>
      %1773 = cute.memref.load(%view_722, %139) : (!memref_rmem_f32_1, !cute.coord<"(2,0)">) -> f32
      %1774 = cute.memref.load(%view_722, %138) : (!memref_rmem_f32_1, !cute.coord<"(3,0)">) -> f32
      %1775 = vector.from_elements %1753, %1754 : vector<2xf32>
      %1776 = vector.from_elements %1773, %1774 : vector<2xf32>
      %1777 = nvvm.add.packed.f32x2 %1775, %1776 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1778 = vector.extract %1777[0] : f32 from vector<2xf32>
      %1779 = vector.extract %1777[1] : f32 from vector<2xf32>
      %1780 = cute.memref.load(%view_722, %137) : (!memref_rmem_f32_1, !cute.coord<"(2,1)">) -> f32
      %1781 = cute.memref.load(%view_722, %136) : (!memref_rmem_f32_1, !cute.coord<"(3,1)">) -> f32
      %1782 = vector.from_elements %1759, %1760 : vector<2xf32>
      %1783 = vector.from_elements %1780, %1781 : vector<2xf32>
      %1784 = nvvm.add.packed.f32x2 %1782, %1783 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1785 = vector.extract %1784[0] : f32 from vector<2xf32>
      %1786 = vector.extract %1784[1] : f32 from vector<2xf32>
      %1787 = cute.memref.load(%view_722, %135) : (!memref_rmem_f32_1, !cute.coord<"(2,2)">) -> f32
      %1788 = cute.memref.load(%view_722, %134) : (!memref_rmem_f32_1, !cute.coord<"(3,2)">) -> f32
      %1789 = vector.from_elements %1765, %1766 : vector<2xf32>
      %1790 = vector.from_elements %1787, %1788 : vector<2xf32>
      %1791 = nvvm.add.packed.f32x2 %1789, %1790 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1792 = vector.extract %1791[0] : f32 from vector<2xf32>
      %1793 = vector.extract %1791[1] : f32 from vector<2xf32>
      %1794 = cute.memref.load(%view_722, %133) : (!memref_rmem_f32_1, !cute.coord<"(2,3)">) -> f32
      %1795 = cute.memref.load(%view_722, %132) : (!memref_rmem_f32_1, !cute.coord<"(3,3)">) -> f32
      %1796 = vector.from_elements %1771, %1772 : vector<2xf32>
      %1797 = vector.from_elements %1794, %1795 : vector<2xf32>
      %1798 = nvvm.add.packed.f32x2 %1796, %1797 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1799 = vector.extract %1798[0] : f32 from vector<2xf32>
      %1800 = vector.extract %1798[1] : f32 from vector<2xf32>
      %1801 = cute.memref.load(%view_722, %131) : (!memref_rmem_f32_1, !cute.coord<"(4,0)">) -> f32
      %1802 = cute.memref.load(%view_722, %130) : (!memref_rmem_f32_1, !cute.coord<"(5,0)">) -> f32
      %1803 = vector.from_elements %1778, %1779 : vector<2xf32>
      %1804 = vector.from_elements %1801, %1802 : vector<2xf32>
      %1805 = nvvm.add.packed.f32x2 %1803, %1804 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1806 = vector.extract %1805[0] : f32 from vector<2xf32>
      %1807 = vector.extract %1805[1] : f32 from vector<2xf32>
      %1808 = cute.memref.load(%view_722, %129) : (!memref_rmem_f32_1, !cute.coord<"(4,1)">) -> f32
      %1809 = cute.memref.load(%view_722, %128) : (!memref_rmem_f32_1, !cute.coord<"(5,1)">) -> f32
      %1810 = vector.from_elements %1785, %1786 : vector<2xf32>
      %1811 = vector.from_elements %1808, %1809 : vector<2xf32>
      %1812 = nvvm.add.packed.f32x2 %1810, %1811 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1813 = vector.extract %1812[0] : f32 from vector<2xf32>
      %1814 = vector.extract %1812[1] : f32 from vector<2xf32>
      %1815 = cute.memref.load(%view_722, %127) : (!memref_rmem_f32_1, !cute.coord<"(4,2)">) -> f32
      %1816 = cute.memref.load(%view_722, %126) : (!memref_rmem_f32_1, !cute.coord<"(5,2)">) -> f32
      %1817 = vector.from_elements %1792, %1793 : vector<2xf32>
      %1818 = vector.from_elements %1815, %1816 : vector<2xf32>
      %1819 = nvvm.add.packed.f32x2 %1817, %1818 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1820 = vector.extract %1819[0] : f32 from vector<2xf32>
      %1821 = vector.extract %1819[1] : f32 from vector<2xf32>
      %1822 = cute.memref.load(%view_722, %125) : (!memref_rmem_f32_1, !cute.coord<"(4,3)">) -> f32
      %1823 = cute.memref.load(%view_722, %124) : (!memref_rmem_f32_1, !cute.coord<"(5,3)">) -> f32
      %1824 = vector.from_elements %1799, %1800 : vector<2xf32>
      %1825 = vector.from_elements %1822, %1823 : vector<2xf32>
      %1826 = nvvm.add.packed.f32x2 %1824, %1825 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1827 = vector.extract %1826[0] : f32 from vector<2xf32>
      %1828 = vector.extract %1826[1] : f32 from vector<2xf32>
      %1829 = cute.memref.load(%view_722, %123) : (!memref_rmem_f32_1, !cute.coord<"(6,0)">) -> f32
      %1830 = cute.memref.load(%view_722, %122) : (!memref_rmem_f32_1, !cute.coord<"(7,0)">) -> f32
      %1831 = vector.from_elements %1806, %1807 : vector<2xf32>
      %1832 = vector.from_elements %1829, %1830 : vector<2xf32>
      %1833 = nvvm.add.packed.f32x2 %1831, %1832 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1834 = vector.extract %1833[0] : f32 from vector<2xf32>
      %1835 = vector.extract %1833[1] : f32 from vector<2xf32>
      %1836 = cute.memref.load(%view_722, %121) : (!memref_rmem_f32_1, !cute.coord<"(6,1)">) -> f32
      %1837 = cute.memref.load(%view_722, %120) : (!memref_rmem_f32_1, !cute.coord<"(7,1)">) -> f32
      %1838 = vector.from_elements %1813, %1814 : vector<2xf32>
      %1839 = vector.from_elements %1836, %1837 : vector<2xf32>
      %1840 = nvvm.add.packed.f32x2 %1838, %1839 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1841 = vector.extract %1840[0] : f32 from vector<2xf32>
      %1842 = vector.extract %1840[1] : f32 from vector<2xf32>
      %1843 = cute.memref.load(%view_722, %119) : (!memref_rmem_f32_1, !cute.coord<"(6,2)">) -> f32
      %1844 = cute.memref.load(%view_722, %118) : (!memref_rmem_f32_1, !cute.coord<"(7,2)">) -> f32
      %1845 = vector.from_elements %1820, %1821 : vector<2xf32>
      %1846 = vector.from_elements %1843, %1844 : vector<2xf32>
      %1847 = nvvm.add.packed.f32x2 %1845, %1846 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1848 = vector.extract %1847[0] : f32 from vector<2xf32>
      %1849 = vector.extract %1847[1] : f32 from vector<2xf32>
      %1850 = cute.memref.load(%view_722, %117) : (!memref_rmem_f32_1, !cute.coord<"(6,3)">) -> f32
      %1851 = cute.memref.load(%view_722, %116) : (!memref_rmem_f32_1, !cute.coord<"(7,3)">) -> f32
      %1852 = vector.from_elements %1827, %1828 : vector<2xf32>
      %1853 = vector.from_elements %1850, %1851 : vector<2xf32>
      %1854 = nvvm.add.packed.f32x2 %1852, %1853 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1855 = vector.extract %1854[0] : f32 from vector<2xf32>
      %1856 = vector.extract %1854[1] : f32 from vector<2xf32>
      %1857 = cute.memref.load(%view_722, %115) : (!memref_rmem_f32_1, !cute.coord<"(8,0)">) -> f32
      %1858 = cute.memref.load(%view_722, %114) : (!memref_rmem_f32_1, !cute.coord<"(9,0)">) -> f32
      %1859 = vector.from_elements %1834, %1835 : vector<2xf32>
      %1860 = vector.from_elements %1857, %1858 : vector<2xf32>
      %1861 = nvvm.add.packed.f32x2 %1859, %1860 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1862 = vector.extract %1861[0] : f32 from vector<2xf32>
      %1863 = vector.extract %1861[1] : f32 from vector<2xf32>
      %1864 = cute.memref.load(%view_722, %113) : (!memref_rmem_f32_1, !cute.coord<"(8,1)">) -> f32
      %1865 = cute.memref.load(%view_722, %112) : (!memref_rmem_f32_1, !cute.coord<"(9,1)">) -> f32
      %1866 = vector.from_elements %1841, %1842 : vector<2xf32>
      %1867 = vector.from_elements %1864, %1865 : vector<2xf32>
      %1868 = nvvm.add.packed.f32x2 %1866, %1867 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1869 = vector.extract %1868[0] : f32 from vector<2xf32>
      %1870 = vector.extract %1868[1] : f32 from vector<2xf32>
      %1871 = cute.memref.load(%view_722, %111) : (!memref_rmem_f32_1, !cute.coord<"(8,2)">) -> f32
      %1872 = cute.memref.load(%view_722, %110) : (!memref_rmem_f32_1, !cute.coord<"(9,2)">) -> f32
      %1873 = vector.from_elements %1848, %1849 : vector<2xf32>
      %1874 = vector.from_elements %1871, %1872 : vector<2xf32>
      %1875 = nvvm.add.packed.f32x2 %1873, %1874 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1876 = vector.extract %1875[0] : f32 from vector<2xf32>
      %1877 = vector.extract %1875[1] : f32 from vector<2xf32>
      %1878 = cute.memref.load(%view_722, %109) : (!memref_rmem_f32_1, !cute.coord<"(8,3)">) -> f32
      %1879 = cute.memref.load(%view_722, %108) : (!memref_rmem_f32_1, !cute.coord<"(9,3)">) -> f32
      %1880 = vector.from_elements %1855, %1856 : vector<2xf32>
      %1881 = vector.from_elements %1878, %1879 : vector<2xf32>
      %1882 = nvvm.add.packed.f32x2 %1880, %1881 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1883 = vector.extract %1882[0] : f32 from vector<2xf32>
      %1884 = vector.extract %1882[1] : f32 from vector<2xf32>
      %1885 = cute.memref.load(%view_722, %107) : (!memref_rmem_f32_1, !cute.coord<"(10,0)">) -> f32
      %1886 = cute.memref.load(%view_722, %106) : (!memref_rmem_f32_1, !cute.coord<"(11,0)">) -> f32
      %1887 = vector.from_elements %1862, %1863 : vector<2xf32>
      %1888 = vector.from_elements %1885, %1886 : vector<2xf32>
      %1889 = nvvm.add.packed.f32x2 %1887, %1888 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1890 = vector.extract %1889[0] : f32 from vector<2xf32>
      %1891 = vector.extract %1889[1] : f32 from vector<2xf32>
      %1892 = cute.memref.load(%view_722, %105) : (!memref_rmem_f32_1, !cute.coord<"(10,1)">) -> f32
      %1893 = cute.memref.load(%view_722, %104) : (!memref_rmem_f32_1, !cute.coord<"(11,1)">) -> f32
      %1894 = vector.from_elements %1869, %1870 : vector<2xf32>
      %1895 = vector.from_elements %1892, %1893 : vector<2xf32>
      %1896 = nvvm.add.packed.f32x2 %1894, %1895 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1897 = vector.extract %1896[0] : f32 from vector<2xf32>
      %1898 = vector.extract %1896[1] : f32 from vector<2xf32>
      %1899 = cute.memref.load(%view_722, %103) : (!memref_rmem_f32_1, !cute.coord<"(10,2)">) -> f32
      %1900 = cute.memref.load(%view_722, %102) : (!memref_rmem_f32_1, !cute.coord<"(11,2)">) -> f32
      %1901 = vector.from_elements %1876, %1877 : vector<2xf32>
      %1902 = vector.from_elements %1899, %1900 : vector<2xf32>
      %1903 = nvvm.add.packed.f32x2 %1901, %1902 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1904 = vector.extract %1903[0] : f32 from vector<2xf32>
      %1905 = vector.extract %1903[1] : f32 from vector<2xf32>
      %1906 = cute.memref.load(%view_722, %101) : (!memref_rmem_f32_1, !cute.coord<"(10,3)">) -> f32
      %1907 = cute.memref.load(%view_722, %100) : (!memref_rmem_f32_1, !cute.coord<"(11,3)">) -> f32
      %1908 = vector.from_elements %1883, %1884 : vector<2xf32>
      %1909 = vector.from_elements %1906, %1907 : vector<2xf32>
      %1910 = nvvm.add.packed.f32x2 %1908, %1909 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1911 = vector.extract %1910[0] : f32 from vector<2xf32>
      %1912 = vector.extract %1910[1] : f32 from vector<2xf32>
      %1913 = cute.memref.load(%view_722, %99) : (!memref_rmem_f32_1, !cute.coord<"(12,0)">) -> f32
      %1914 = cute.memref.load(%view_722, %98) : (!memref_rmem_f32_1, !cute.coord<"(13,0)">) -> f32
      %1915 = vector.from_elements %1890, %1891 : vector<2xf32>
      %1916 = vector.from_elements %1913, %1914 : vector<2xf32>
      %1917 = nvvm.add.packed.f32x2 %1915, %1916 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1918 = vector.extract %1917[0] : f32 from vector<2xf32>
      %1919 = vector.extract %1917[1] : f32 from vector<2xf32>
      %1920 = cute.memref.load(%view_722, %97) : (!memref_rmem_f32_1, !cute.coord<"(12,1)">) -> f32
      %1921 = cute.memref.load(%view_722, %96) : (!memref_rmem_f32_1, !cute.coord<"(13,1)">) -> f32
      %1922 = vector.from_elements %1897, %1898 : vector<2xf32>
      %1923 = vector.from_elements %1920, %1921 : vector<2xf32>
      %1924 = nvvm.add.packed.f32x2 %1922, %1923 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1925 = vector.extract %1924[0] : f32 from vector<2xf32>
      %1926 = vector.extract %1924[1] : f32 from vector<2xf32>
      %1927 = cute.memref.load(%view_722, %95) : (!memref_rmem_f32_1, !cute.coord<"(12,2)">) -> f32
      %1928 = cute.memref.load(%view_722, %94) : (!memref_rmem_f32_1, !cute.coord<"(13,2)">) -> f32
      %1929 = vector.from_elements %1904, %1905 : vector<2xf32>
      %1930 = vector.from_elements %1927, %1928 : vector<2xf32>
      %1931 = nvvm.add.packed.f32x2 %1929, %1930 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1932 = vector.extract %1931[0] : f32 from vector<2xf32>
      %1933 = vector.extract %1931[1] : f32 from vector<2xf32>
      %1934 = cute.memref.load(%view_722, %93) : (!memref_rmem_f32_1, !cute.coord<"(12,3)">) -> f32
      %1935 = cute.memref.load(%view_722, %92) : (!memref_rmem_f32_1, !cute.coord<"(13,3)">) -> f32
      %1936 = vector.from_elements %1911, %1912 : vector<2xf32>
      %1937 = vector.from_elements %1934, %1935 : vector<2xf32>
      %1938 = nvvm.add.packed.f32x2 %1936, %1937 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1939 = vector.extract %1938[0] : f32 from vector<2xf32>
      %1940 = vector.extract %1938[1] : f32 from vector<2xf32>
      %1941 = cute.memref.load(%view_722, %91) : (!memref_rmem_f32_1, !cute.coord<"(14,0)">) -> f32
      %1942 = cute.memref.load(%view_722, %90) : (!memref_rmem_f32_1, !cute.coord<"(15,0)">) -> f32
      %1943 = vector.from_elements %1918, %1919 : vector<2xf32>
      %1944 = vector.from_elements %1941, %1942 : vector<2xf32>
      %1945 = nvvm.add.packed.f32x2 %1943, %1944 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1946 = vector.extract %1945[0] : f32 from vector<2xf32>
      %1947 = vector.extract %1945[1] : f32 from vector<2xf32>
      %1948 = cute.memref.load(%view_722, %89) : (!memref_rmem_f32_1, !cute.coord<"(14,1)">) -> f32
      %1949 = cute.memref.load(%view_722, %88) : (!memref_rmem_f32_1, !cute.coord<"(15,1)">) -> f32
      %1950 = vector.from_elements %1925, %1926 : vector<2xf32>
      %1951 = vector.from_elements %1948, %1949 : vector<2xf32>
      %1952 = nvvm.add.packed.f32x2 %1950, %1951 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1953 = vector.extract %1952[0] : f32 from vector<2xf32>
      %1954 = vector.extract %1952[1] : f32 from vector<2xf32>
      %1955 = cute.memref.load(%view_722, %87) : (!memref_rmem_f32_1, !cute.coord<"(14,2)">) -> f32
      %1956 = cute.memref.load(%view_722, %86) : (!memref_rmem_f32_1, !cute.coord<"(15,2)">) -> f32
      %1957 = vector.from_elements %1932, %1933 : vector<2xf32>
      %1958 = vector.from_elements %1955, %1956 : vector<2xf32>
      %1959 = nvvm.add.packed.f32x2 %1957, %1958 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1960 = vector.extract %1959[0] : f32 from vector<2xf32>
      %1961 = vector.extract %1959[1] : f32 from vector<2xf32>
      %1962 = cute.memref.load(%view_722, %85) : (!memref_rmem_f32_1, !cute.coord<"(14,3)">) -> f32
      %1963 = cute.memref.load(%view_722, %84) : (!memref_rmem_f32_1, !cute.coord<"(15,3)">) -> f32
      %1964 = vector.from_elements %1939, %1940 : vector<2xf32>
      %1965 = vector.from_elements %1962, %1963 : vector<2xf32>
      %1966 = nvvm.add.packed.f32x2 %1964, %1965 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1967 = vector.extract %1966[0] : f32 from vector<2xf32>
      %1968 = vector.extract %1966[1] : f32 from vector<2xf32>
      %1969 = cute.memref.load(%view_722, %83) : (!memref_rmem_f32_1, !cute.coord<"(16,0)">) -> f32
      %1970 = cute.memref.load(%view_722, %82) : (!memref_rmem_f32_1, !cute.coord<"(17,0)">) -> f32
      %1971 = vector.from_elements %1946, %1947 : vector<2xf32>
      %1972 = vector.from_elements %1969, %1970 : vector<2xf32>
      %1973 = nvvm.add.packed.f32x2 %1971, %1972 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1974 = vector.extract %1973[0] : f32 from vector<2xf32>
      %1975 = vector.extract %1973[1] : f32 from vector<2xf32>
      %1976 = cute.memref.load(%view_722, %81) : (!memref_rmem_f32_1, !cute.coord<"(16,1)">) -> f32
      %1977 = cute.memref.load(%view_722, %80) : (!memref_rmem_f32_1, !cute.coord<"(17,1)">) -> f32
      %1978 = vector.from_elements %1953, %1954 : vector<2xf32>
      %1979 = vector.from_elements %1976, %1977 : vector<2xf32>
      %1980 = nvvm.add.packed.f32x2 %1978, %1979 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1981 = vector.extract %1980[0] : f32 from vector<2xf32>
      %1982 = vector.extract %1980[1] : f32 from vector<2xf32>
      %1983 = cute.memref.load(%view_722, %79) : (!memref_rmem_f32_1, !cute.coord<"(16,2)">) -> f32
      %1984 = cute.memref.load(%view_722, %78) : (!memref_rmem_f32_1, !cute.coord<"(17,2)">) -> f32
      %1985 = vector.from_elements %1960, %1961 : vector<2xf32>
      %1986 = vector.from_elements %1983, %1984 : vector<2xf32>
      %1987 = nvvm.add.packed.f32x2 %1985, %1986 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1988 = vector.extract %1987[0] : f32 from vector<2xf32>
      %1989 = vector.extract %1987[1] : f32 from vector<2xf32>
      %1990 = cute.memref.load(%view_722, %77) : (!memref_rmem_f32_1, !cute.coord<"(16,3)">) -> f32
      %1991 = cute.memref.load(%view_722, %76) : (!memref_rmem_f32_1, !cute.coord<"(17,3)">) -> f32
      %1992 = vector.from_elements %1967, %1968 : vector<2xf32>
      %1993 = vector.from_elements %1990, %1991 : vector<2xf32>
      %1994 = nvvm.add.packed.f32x2 %1992, %1993 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %1995 = vector.extract %1994[0] : f32 from vector<2xf32>
      %1996 = vector.extract %1994[1] : f32 from vector<2xf32>
      %1997 = cute.memref.load(%view_722, %75) : (!memref_rmem_f32_1, !cute.coord<"(18,0)">) -> f32
      %1998 = cute.memref.load(%view_722, %74) : (!memref_rmem_f32_1, !cute.coord<"(19,0)">) -> f32
      %1999 = vector.from_elements %1974, %1975 : vector<2xf32>
      %2000 = vector.from_elements %1997, %1998 : vector<2xf32>
      %2001 = nvvm.add.packed.f32x2 %1999, %2000 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2002 = vector.extract %2001[0] : f32 from vector<2xf32>
      %2003 = vector.extract %2001[1] : f32 from vector<2xf32>
      %2004 = cute.memref.load(%view_722, %73) : (!memref_rmem_f32_1, !cute.coord<"(18,1)">) -> f32
      %2005 = cute.memref.load(%view_722, %72) : (!memref_rmem_f32_1, !cute.coord<"(19,1)">) -> f32
      %2006 = vector.from_elements %1981, %1982 : vector<2xf32>
      %2007 = vector.from_elements %2004, %2005 : vector<2xf32>
      %2008 = nvvm.add.packed.f32x2 %2006, %2007 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2009 = vector.extract %2008[0] : f32 from vector<2xf32>
      %2010 = vector.extract %2008[1] : f32 from vector<2xf32>
      %2011 = cute.memref.load(%view_722, %71) : (!memref_rmem_f32_1, !cute.coord<"(18,2)">) -> f32
      %2012 = cute.memref.load(%view_722, %70) : (!memref_rmem_f32_1, !cute.coord<"(19,2)">) -> f32
      %2013 = vector.from_elements %1988, %1989 : vector<2xf32>
      %2014 = vector.from_elements %2011, %2012 : vector<2xf32>
      %2015 = nvvm.add.packed.f32x2 %2013, %2014 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2016 = vector.extract %2015[0] : f32 from vector<2xf32>
      %2017 = vector.extract %2015[1] : f32 from vector<2xf32>
      %2018 = cute.memref.load(%view_722, %69) : (!memref_rmem_f32_1, !cute.coord<"(18,3)">) -> f32
      %2019 = cute.memref.load(%view_722, %68) : (!memref_rmem_f32_1, !cute.coord<"(19,3)">) -> f32
      %2020 = vector.from_elements %1995, %1996 : vector<2xf32>
      %2021 = vector.from_elements %2018, %2019 : vector<2xf32>
      %2022 = nvvm.add.packed.f32x2 %2020, %2021 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2023 = vector.extract %2022[0] : f32 from vector<2xf32>
      %2024 = vector.extract %2022[1] : f32 from vector<2xf32>
      %2025 = cute.memref.load(%view_722, %67) : (!memref_rmem_f32_1, !cute.coord<"(20,0)">) -> f32
      %2026 = cute.memref.load(%view_722, %66) : (!memref_rmem_f32_1, !cute.coord<"(21,0)">) -> f32
      %2027 = vector.from_elements %2002, %2003 : vector<2xf32>
      %2028 = vector.from_elements %2025, %2026 : vector<2xf32>
      %2029 = nvvm.add.packed.f32x2 %2027, %2028 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2030 = vector.extract %2029[0] : f32 from vector<2xf32>
      %2031 = vector.extract %2029[1] : f32 from vector<2xf32>
      %2032 = cute.memref.load(%view_722, %65) : (!memref_rmem_f32_1, !cute.coord<"(20,1)">) -> f32
      %2033 = cute.memref.load(%view_722, %64) : (!memref_rmem_f32_1, !cute.coord<"(21,1)">) -> f32
      %2034 = vector.from_elements %2009, %2010 : vector<2xf32>
      %2035 = vector.from_elements %2032, %2033 : vector<2xf32>
      %2036 = nvvm.add.packed.f32x2 %2034, %2035 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2037 = vector.extract %2036[0] : f32 from vector<2xf32>
      %2038 = vector.extract %2036[1] : f32 from vector<2xf32>
      %2039 = cute.memref.load(%view_722, %63) : (!memref_rmem_f32_1, !cute.coord<"(20,2)">) -> f32
      %2040 = cute.memref.load(%view_722, %62) : (!memref_rmem_f32_1, !cute.coord<"(21,2)">) -> f32
      %2041 = vector.from_elements %2016, %2017 : vector<2xf32>
      %2042 = vector.from_elements %2039, %2040 : vector<2xf32>
      %2043 = nvvm.add.packed.f32x2 %2041, %2042 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2044 = vector.extract %2043[0] : f32 from vector<2xf32>
      %2045 = vector.extract %2043[1] : f32 from vector<2xf32>
      %2046 = cute.memref.load(%view_722, %61) : (!memref_rmem_f32_1, !cute.coord<"(20,3)">) -> f32
      %2047 = cute.memref.load(%view_722, %60) : (!memref_rmem_f32_1, !cute.coord<"(21,3)">) -> f32
      %2048 = vector.from_elements %2023, %2024 : vector<2xf32>
      %2049 = vector.from_elements %2046, %2047 : vector<2xf32>
      %2050 = nvvm.add.packed.f32x2 %2048, %2049 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2051 = vector.extract %2050[0] : f32 from vector<2xf32>
      %2052 = vector.extract %2050[1] : f32 from vector<2xf32>
      %2053 = cute.memref.load(%view_722, %59) : (!memref_rmem_f32_1, !cute.coord<"(22,0)">) -> f32
      %2054 = cute.memref.load(%view_722, %58) : (!memref_rmem_f32_1, !cute.coord<"(23,0)">) -> f32
      %2055 = vector.from_elements %2030, %2031 : vector<2xf32>
      %2056 = vector.from_elements %2053, %2054 : vector<2xf32>
      %2057 = nvvm.add.packed.f32x2 %2055, %2056 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2058 = vector.extract %2057[0] : f32 from vector<2xf32>
      %2059 = vector.extract %2057[1] : f32 from vector<2xf32>
      %2060 = cute.memref.load(%view_722, %57) : (!memref_rmem_f32_1, !cute.coord<"(22,1)">) -> f32
      %2061 = cute.memref.load(%view_722, %56) : (!memref_rmem_f32_1, !cute.coord<"(23,1)">) -> f32
      %2062 = vector.from_elements %2037, %2038 : vector<2xf32>
      %2063 = vector.from_elements %2060, %2061 : vector<2xf32>
      %2064 = nvvm.add.packed.f32x2 %2062, %2063 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2065 = vector.extract %2064[0] : f32 from vector<2xf32>
      %2066 = vector.extract %2064[1] : f32 from vector<2xf32>
      %2067 = cute.memref.load(%view_722, %55) : (!memref_rmem_f32_1, !cute.coord<"(22,2)">) -> f32
      %2068 = cute.memref.load(%view_722, %54) : (!memref_rmem_f32_1, !cute.coord<"(23,2)">) -> f32
      %2069 = vector.from_elements %2044, %2045 : vector<2xf32>
      %2070 = vector.from_elements %2067, %2068 : vector<2xf32>
      %2071 = nvvm.add.packed.f32x2 %2069, %2070 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2072 = vector.extract %2071[0] : f32 from vector<2xf32>
      %2073 = vector.extract %2071[1] : f32 from vector<2xf32>
      %2074 = cute.memref.load(%view_722, %53) : (!memref_rmem_f32_1, !cute.coord<"(22,3)">) -> f32
      %2075 = cute.memref.load(%view_722, %52) : (!memref_rmem_f32_1, !cute.coord<"(23,3)">) -> f32
      %2076 = vector.from_elements %2051, %2052 : vector<2xf32>
      %2077 = vector.from_elements %2074, %2075 : vector<2xf32>
      %2078 = nvvm.add.packed.f32x2 %2076, %2077 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2079 = vector.extract %2078[0] : f32 from vector<2xf32>
      %2080 = vector.extract %2078[1] : f32 from vector<2xf32>
      %2081 = cute.memref.load(%view_722, %51) : (!memref_rmem_f32_1, !cute.coord<"(24,0)">) -> f32
      %2082 = cute.memref.load(%view_722, %50) : (!memref_rmem_f32_1, !cute.coord<"(25,0)">) -> f32
      %2083 = vector.from_elements %2058, %2059 : vector<2xf32>
      %2084 = vector.from_elements %2081, %2082 : vector<2xf32>
      %2085 = nvvm.add.packed.f32x2 %2083, %2084 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2086 = vector.extract %2085[0] : f32 from vector<2xf32>
      %2087 = vector.extract %2085[1] : f32 from vector<2xf32>
      %2088 = cute.memref.load(%view_722, %49) : (!memref_rmem_f32_1, !cute.coord<"(24,1)">) -> f32
      %2089 = cute.memref.load(%view_722, %48) : (!memref_rmem_f32_1, !cute.coord<"(25,1)">) -> f32
      %2090 = vector.from_elements %2065, %2066 : vector<2xf32>
      %2091 = vector.from_elements %2088, %2089 : vector<2xf32>
      %2092 = nvvm.add.packed.f32x2 %2090, %2091 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2093 = vector.extract %2092[0] : f32 from vector<2xf32>
      %2094 = vector.extract %2092[1] : f32 from vector<2xf32>
      %2095 = cute.memref.load(%view_722, %47) : (!memref_rmem_f32_1, !cute.coord<"(24,2)">) -> f32
      %2096 = cute.memref.load(%view_722, %46) : (!memref_rmem_f32_1, !cute.coord<"(25,2)">) -> f32
      %2097 = vector.from_elements %2072, %2073 : vector<2xf32>
      %2098 = vector.from_elements %2095, %2096 : vector<2xf32>
      %2099 = nvvm.add.packed.f32x2 %2097, %2098 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2100 = vector.extract %2099[0] : f32 from vector<2xf32>
      %2101 = vector.extract %2099[1] : f32 from vector<2xf32>
      %2102 = cute.memref.load(%view_722, %45) : (!memref_rmem_f32_1, !cute.coord<"(24,3)">) -> f32
      %2103 = cute.memref.load(%view_722, %44) : (!memref_rmem_f32_1, !cute.coord<"(25,3)">) -> f32
      %2104 = vector.from_elements %2079, %2080 : vector<2xf32>
      %2105 = vector.from_elements %2102, %2103 : vector<2xf32>
      %2106 = nvvm.add.packed.f32x2 %2104, %2105 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2107 = vector.extract %2106[0] : f32 from vector<2xf32>
      %2108 = vector.extract %2106[1] : f32 from vector<2xf32>
      %2109 = cute.memref.load(%view_722, %43) : (!memref_rmem_f32_1, !cute.coord<"(26,0)">) -> f32
      %2110 = cute.memref.load(%view_722, %42) : (!memref_rmem_f32_1, !cute.coord<"(27,0)">) -> f32
      %2111 = vector.from_elements %2086, %2087 : vector<2xf32>
      %2112 = vector.from_elements %2109, %2110 : vector<2xf32>
      %2113 = nvvm.add.packed.f32x2 %2111, %2112 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2114 = vector.extract %2113[0] : f32 from vector<2xf32>
      %2115 = vector.extract %2113[1] : f32 from vector<2xf32>
      %2116 = cute.memref.load(%view_722, %41) : (!memref_rmem_f32_1, !cute.coord<"(26,1)">) -> f32
      %2117 = cute.memref.load(%view_722, %40) : (!memref_rmem_f32_1, !cute.coord<"(27,1)">) -> f32
      %2118 = vector.from_elements %2093, %2094 : vector<2xf32>
      %2119 = vector.from_elements %2116, %2117 : vector<2xf32>
      %2120 = nvvm.add.packed.f32x2 %2118, %2119 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2121 = vector.extract %2120[0] : f32 from vector<2xf32>
      %2122 = vector.extract %2120[1] : f32 from vector<2xf32>
      %2123 = cute.memref.load(%view_722, %39) : (!memref_rmem_f32_1, !cute.coord<"(26,2)">) -> f32
      %2124 = cute.memref.load(%view_722, %38) : (!memref_rmem_f32_1, !cute.coord<"(27,2)">) -> f32
      %2125 = vector.from_elements %2100, %2101 : vector<2xf32>
      %2126 = vector.from_elements %2123, %2124 : vector<2xf32>
      %2127 = nvvm.add.packed.f32x2 %2125, %2126 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2128 = vector.extract %2127[0] : f32 from vector<2xf32>
      %2129 = vector.extract %2127[1] : f32 from vector<2xf32>
      %2130 = cute.memref.load(%view_722, %37) : (!memref_rmem_f32_1, !cute.coord<"(26,3)">) -> f32
      %2131 = cute.memref.load(%view_722, %36) : (!memref_rmem_f32_1, !cute.coord<"(27,3)">) -> f32
      %2132 = vector.from_elements %2107, %2108 : vector<2xf32>
      %2133 = vector.from_elements %2130, %2131 : vector<2xf32>
      %2134 = nvvm.add.packed.f32x2 %2132, %2133 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2135 = vector.extract %2134[0] : f32 from vector<2xf32>
      %2136 = vector.extract %2134[1] : f32 from vector<2xf32>
      %2137 = cute.memref.load(%view_722, %35) : (!memref_rmem_f32_1, !cute.coord<"(28,0)">) -> f32
      %2138 = cute.memref.load(%view_722, %34) : (!memref_rmem_f32_1, !cute.coord<"(29,0)">) -> f32
      %2139 = vector.from_elements %2114, %2115 : vector<2xf32>
      %2140 = vector.from_elements %2137, %2138 : vector<2xf32>
      %2141 = nvvm.add.packed.f32x2 %2139, %2140 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2142 = vector.extract %2141[0] : f32 from vector<2xf32>
      %2143 = vector.extract %2141[1] : f32 from vector<2xf32>
      %2144 = cute.memref.load(%view_722, %33) : (!memref_rmem_f32_1, !cute.coord<"(28,1)">) -> f32
      %2145 = cute.memref.load(%view_722, %32) : (!memref_rmem_f32_1, !cute.coord<"(29,1)">) -> f32
      %2146 = vector.from_elements %2121, %2122 : vector<2xf32>
      %2147 = vector.from_elements %2144, %2145 : vector<2xf32>
      %2148 = nvvm.add.packed.f32x2 %2146, %2147 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2149 = vector.extract %2148[0] : f32 from vector<2xf32>
      %2150 = vector.extract %2148[1] : f32 from vector<2xf32>
      %2151 = cute.memref.load(%view_722, %31) : (!memref_rmem_f32_1, !cute.coord<"(28,2)">) -> f32
      %2152 = cute.memref.load(%view_722, %30) : (!memref_rmem_f32_1, !cute.coord<"(29,2)">) -> f32
      %2153 = vector.from_elements %2128, %2129 : vector<2xf32>
      %2154 = vector.from_elements %2151, %2152 : vector<2xf32>
      %2155 = nvvm.add.packed.f32x2 %2153, %2154 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2156 = vector.extract %2155[0] : f32 from vector<2xf32>
      %2157 = vector.extract %2155[1] : f32 from vector<2xf32>
      %2158 = cute.memref.load(%view_722, %29) : (!memref_rmem_f32_1, !cute.coord<"(28,3)">) -> f32
      %2159 = cute.memref.load(%view_722, %28) : (!memref_rmem_f32_1, !cute.coord<"(29,3)">) -> f32
      %2160 = vector.from_elements %2135, %2136 : vector<2xf32>
      %2161 = vector.from_elements %2158, %2159 : vector<2xf32>
      %2162 = nvvm.add.packed.f32x2 %2160, %2161 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2163 = vector.extract %2162[0] : f32 from vector<2xf32>
      %2164 = vector.extract %2162[1] : f32 from vector<2xf32>
      %2165 = cute.memref.load(%view_722, %27) : (!memref_rmem_f32_1, !cute.coord<"(30,0)">) -> f32
      %2166 = cute.memref.load(%view_722, %26) : (!memref_rmem_f32_1, !cute.coord<"(31,0)">) -> f32
      %2167 = vector.from_elements %2142, %2143 : vector<2xf32>
      %2168 = vector.from_elements %2165, %2166 : vector<2xf32>
      %2169 = nvvm.add.packed.f32x2 %2167, %2168 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2170 = vector.extract %2169[0] : f32 from vector<2xf32>
      %2171 = vector.extract %2169[1] : f32 from vector<2xf32>
      %2172 = cute.memref.load(%view_722, %25) : (!memref_rmem_f32_1, !cute.coord<"(30,1)">) -> f32
      %2173 = cute.memref.load(%view_722, %24) : (!memref_rmem_f32_1, !cute.coord<"(31,1)">) -> f32
      %2174 = vector.from_elements %2149, %2150 : vector<2xf32>
      %2175 = vector.from_elements %2172, %2173 : vector<2xf32>
      %2176 = nvvm.add.packed.f32x2 %2174, %2175 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2177 = vector.extract %2176[0] : f32 from vector<2xf32>
      %2178 = vector.extract %2176[1] : f32 from vector<2xf32>
      %2179 = cute.memref.load(%view_722, %23) : (!memref_rmem_f32_1, !cute.coord<"(30,2)">) -> f32
      %2180 = cute.memref.load(%view_722, %22) : (!memref_rmem_f32_1, !cute.coord<"(31,2)">) -> f32
      %2181 = vector.from_elements %2156, %2157 : vector<2xf32>
      %2182 = vector.from_elements %2179, %2180 : vector<2xf32>
      %2183 = nvvm.add.packed.f32x2 %2181, %2182 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2184 = vector.extract %2183[0] : f32 from vector<2xf32>
      %2185 = vector.extract %2183[1] : f32 from vector<2xf32>
      %2186 = cute.memref.load(%view_722, %21) : (!memref_rmem_f32_1, !cute.coord<"(30,3)">) -> f32
      %2187 = cute.memref.load(%view_722, %20) : (!memref_rmem_f32_1, !cute.coord<"(31,3)">) -> f32
      %2188 = vector.from_elements %2163, %2164 : vector<2xf32>
      %2189 = vector.from_elements %2186, %2187 : vector<2xf32>
      %2190 = nvvm.add.packed.f32x2 %2188, %2189 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2191 = vector.extract %2190[0] : f32 from vector<2xf32>
      %2192 = vector.extract %2190[1] : f32 from vector<2xf32>
      %2193 = vector.from_elements %2170, %2171 : vector<2xf32>
      %2194 = vector.from_elements %2177, %2178 : vector<2xf32>
      %2195 = nvvm.add.packed.f32x2 %2193, %2194 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2196 = vector.extract %2195[0] : f32 from vector<2xf32>
      %2197 = vector.extract %2195[1] : f32 from vector<2xf32>
      %2198 = vector.from_elements %2184, %2185 : vector<2xf32>
      %2199 = vector.from_elements %2191, %2192 : vector<2xf32>
      %2200 = nvvm.add.packed.f32x2 %2198, %2199 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2201 = vector.extract %2200[0] : f32 from vector<2xf32>
      %2202 = vector.extract %2200[1] : f32 from vector<2xf32>
      %2203 = vector.from_elements %2196, %2197 : vector<2xf32>
      %2204 = vector.from_elements %2201, %2202 : vector<2xf32>
      %2205 = nvvm.add.packed.f32x2 %2203, %2204 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2206 = vector.extract %2205[0] : f32 from vector<2xf32>
      %2207 = vector.extract %2205[1] : f32 from vector<2xf32>
      %2208 = arith.addf %2206, %2207 : f32
      cf.br ^bb566(%c1_i32, %2208, %1681, %1683, %1685, %1720, %1722, %1724, %1675, %1676, %1677, %1696 : i32, f32, i32, i32, i32, i32, i32, i32, i32, i32, i32, f32)
    ^bb566(%2209: i32, %2210: f32, %2211: i32, %2212: i32, %2213: i32, %2214: i32, %2215: i32, %2216: i32, %2217: i32, %2218: i32, %2219: i32, %2220: f32):  // 2 preds: ^bb565, ^bb603
      %2221 = arith.cmpi slt, %2209, %1621 : i32
      cf.cond_br %2221, ^bb567, ^bb604 {loop_annotation = #loop_annotation2}
    ^bb567:  // pred: ^bb566
      %int_tuple_723 = cute.make_int_tuple(%2212) : (i32) -> !cute.int_tuple<"?">
      %ptr_724 = cute.add_offset(%iter_104, %int_tuple_723) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2222 = builtin.unrealized_conversion_cast %ptr_724 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2222, %2213, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2223 = arith.addi %2212, %c1_i32 : i32
      %2224 = arith.addi %2211, %c1_i32 : i32
      %2225 = arith.cmpi eq, %2223, %c2_i32 : i32
      %2226 = arith.select %2225, %c0_i32, %2223 : i32
      cf.cond_br %2225, ^bb568, ^bb569
    ^bb568:  // pred: ^bb567
      %2227 = arith.xori %2213, %c1_i32 : i32
      cf.br ^bb570(%2227 : i32)
    ^bb569:  // pred: ^bb567
      cf.br ^bb570(%2213 : i32)
    ^bb570(%2228: i32):  // 2 preds: ^bb568, ^bb569
      cf.br ^bb571
    ^bb571:  // pred: ^bb570
      %coord_725 = cute.make_coord(%2212) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_726 = cute.crd2idx(%coord_725, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_727 = cute.add_offset(%345, %idx_726) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_728 = cute.add_offset(%ptr_727, %int_tuple_662) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem_729 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_730 = cute.get_iter(%rmem_729) : !memref_rmem_f32_
      cf.br ^bb572(%c0_i32 : i32)
    ^bb572(%2229: i32):  // 2 preds: ^bb571, ^bb573
      %2230 = arith.cmpi slt, %2229, %1632 : i32
      cf.cond_br %2230, ^bb573, ^bb574 {llvm.loop_annotation = #loop_annotation}
    ^bb573:  // pred: ^bb572
      %coord_731 = cute.make_coord(%2229) : (i32) -> !cute.coord<"(_,?)">
      %idx_732 = cute.crd2idx(%coord_731, %153) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,32),1),((1,4))):(((1,65536),0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_733 = cute.add_offset(%ptr_728, %idx_732) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_734 = cute.crd2idx(%coord_731, %152) : (!cute.coord<"(_,?)">, !cute.layout<"((32,1),((1,4))):((1,0),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_735 = cute.add_offset(%iter_730, %idx_734) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, rmem, align<32>>
      %2231 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_733) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      %2232 = builtin.unrealized_conversion_cast %ptr_735 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      llvm.store %2231, %2232 : vector<32xi32>, !llvm.ptr
      %2233 = arith.addi %2229, %c1_i32 : i32
      cf.br ^bb572(%2233 : i32)
    ^bb574:  // pred: ^bb572
      nvvm.tcgen05.wait <load>
      %ptr_736 = cute.add_offset(%ptr_106, %int_tuple_723) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2234 = builtin.unrealized_conversion_cast %ptr_736 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2235 = nvvm.mapa.shared.cluster %2234, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2235, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %2236 = cute.memref.load_vec %rmem_729 : !memref_rmem_f32_
      %2237 = vector.reduction <maximumf>, %2236, %2220 : vector<128xf32> into f32
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_660, %2237) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %2238 = cute.memref.load(%view, %coord_663) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %2239 = nvvm.fmax %2237, %2238
      %2240 = arith.cmpf oeq, %2239, %cst_2 : f32
      %2241 = arith.select %2240, %cst_1, %2239 : f32
      %2242 = arith.subf %cst_1, %2241 : f32
      %2243 = arith.mulf %2242, %arg13 : f32
      %rmem_737 = cute.memref.alloca() : !memref_rmem_bf16_
      %2244 = vector.splat %2243 : vector<2xf32>
      cf.br ^bb575(%c0_i32 : i32)
    ^bb575(%2245: i32):  // 2 preds: ^bb574, ^bb576
      %2246 = arith.cmpi slt, %2245, %c128_i32 : i32
      cf.cond_br %2246, ^bb576, ^bb577
    ^bb576:  // pred: ^bb575
      %coord_738 = cute.make_coord(%2245) : (i32) -> !cute.coord<"?">
      %2247 = cute.memref.load(%rmem_729, %coord_738) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2248 = arith.addi %2245, %c1_i32 : i32
      %coord_739 = cute.make_coord(%2248) : (i32) -> !cute.coord<"?">
      %2249 = cute.memref.load(%rmem_729, %coord_739) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2250 = vector.from_elements %2247, %2249 : vector<2xf32>
      %2251 = nvvm.fma.packed.f32x2 %2250, %1642, %2244 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2252 = vector.extract %2251[0] : f32 from vector<2xf32>
      %2253 = vector.extract %2251[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_729, %coord_738, %2252) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_729, %coord_739, %2253) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2254 = cute.memref.load(%rmem_729, %coord_738) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2255 = math.exp2 %2254 fastmath<fast> : f32
      cute.memref.store(%rmem_729, %coord_738, %2255) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2256 = cute.memref.load(%rmem_729, %coord_739) : (!memref_rmem_f32_, !cute.coord<"?">) -> f32
      %2257 = math.exp2 %2256 fastmath<fast> : f32
      cute.memref.store(%rmem_729, %coord_739, %2257) : (!memref_rmem_f32_, !cute.coord<"?">, f32) -> ()
      %2258 = arith.addi %2245, %c2_i32 : i32
      cf.br ^bb575(%2258 : i32)
    ^bb577:  // pred: ^bb575
      %2259 = cute.memref.load_vec %rmem_729 : !memref_rmem_f32_
      %2260 = arith.truncf %2259 : vector<128xf32> to vector<128xbf16>
      cute.memref.store_vec %2260, %rmem_737 : !memref_rmem_bf16_
      %int_tuple_740 = cute.make_int_tuple(%2215) : (i32) -> !cute.int_tuple<"?">
      %ptr_741 = cute.add_offset(%ptr_111, %int_tuple_740) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2261 = builtin.unrealized_conversion_cast %ptr_741 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2261, %2216, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2262 = arith.addi %2215, %c1_i32 : i32
      %2263 = arith.addi %2214, %c1_i32 : i32
      %2264 = arith.cmpi eq, %2262, %c2_i32 : i32
      %2265 = arith.select %2264, %c0_i32, %2262 : i32
      cf.cond_br %2264, ^bb578, ^bb579
    ^bb578:  // pred: ^bb577
      %2266 = arith.xori %2216, %c1_i32 : i32
      cf.br ^bb580(%2266 : i32)
    ^bb579:  // pred: ^bb577
      cf.br ^bb580(%2216 : i32)
    ^bb580(%2267: i32):  // 2 preds: ^bb578, ^bb579
      cf.br ^bb581
    ^bb581:  // pred: ^bb580
      %coord_742 = cute.make_coord(%2215) : (i32) -> !cute.coord<"(_,_,_,(_,?))">
      %idx_743 = cute.crd2idx(%coord_742, %204) : (!cute.coord<"(_,_,_,(_,?))">, !cute.layout<"((64,16),1,4,(4,2)):((64,1),0,16,(4096,16384))">) -> !cute.int_tuple<"?{div=16384}">
      %2268 = cute.make_tiled_copy(%atom) : !copy_simt
      %iter_744 = cute.get_iter(%rmem_737) : !memref_rmem_bf16_
      cf.br ^bb582(%c0_i32 : i32)
    ^bb582(%2269: i32):  // 2 preds: ^bb581, ^bb583
      %2270 = arith.cmpi slt, %2269, %1632 : i32
      cf.cond_br %2270, ^bb583, ^bb584 {llvm.loop_annotation = #loop_annotation}
    ^bb583:  // pred: ^bb582
      %coord_745 = cute.make_coord(%2269) : (i32) -> !cute.coord<"(_,?)">
      %idx_746 = cute.crd2idx(%coord_745, %151) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,4))):((1,8),((0,32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_747 = cute.add_offset(%iter_744, %idx_746) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %idx_748 = cute.crd2idx(%coord_745, %150) : (!cute.coord<"(_,?)">, !cute.layout<"((8,4),((1,(2,2)))):((1,8),((0,(32,4096))))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_749 = cute.add_offset(%ptr_666, %idx_748) : (!cute.ptr<bf16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %swizzled_750 = cute.apply_swizzle(%ptr_749) : !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %ptr_751 = cute.add_offset(%swizzled_750, %idx_743) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<64>, S<3,4,3>>
      %2271 = builtin.unrealized_conversion_cast %ptr_747 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2272 = builtin.unrealized_conversion_cast %ptr_751 : !cute.ptr<bf16, smem, align<64>, S<3,4,3>> to !llvm.ptr<3>
      %2273 = llvm.load %2271 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2273, %2272 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_752 = cute.add_offset(%ptr_747, %205) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_753 = cute.add_offset(%ptr_749, %205) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_754 = cute.apply_swizzle(%ptr_753) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_755 = cute.add_offset(%swizzled_754, %idx_743) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %2274 = builtin.unrealized_conversion_cast %ptr_752 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2275 = builtin.unrealized_conversion_cast %ptr_755 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %2276 = llvm.load %2274 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2276, %2275 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_756 = cute.add_offset(%ptr_747, %149) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_757 = cute.add_offset(%ptr_749, %149) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %swizzled_758 = cute.apply_swizzle(%ptr_757) : !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %ptr_759 = cute.add_offset(%swizzled_758, %idx_743) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2277 = builtin.unrealized_conversion_cast %ptr_756 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2278 = builtin.unrealized_conversion_cast %ptr_759 : !cute.ptr<bf16, smem, align<32>, S<3,4,3>> to !llvm.ptr<3>
      %2279 = llvm.load %2277 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2279, %2278 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %ptr_760 = cute.add_offset(%ptr_747, %148) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_761 = cute.add_offset(%ptr_749, %148) : (!cute.ptr<bf16, smem, align<64>, S<3,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_762 = cute.apply_swizzle(%ptr_761) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_763 = cute.add_offset(%swizzled_762, %idx_743) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %2280 = builtin.unrealized_conversion_cast %ptr_760 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %2281 = builtin.unrealized_conversion_cast %ptr_763 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %2282 = llvm.load %2280 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %2282, %2281 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %2283 = arith.addi %2269, %c1_i32 : i32
      cf.br ^bb582(%2283 : i32)
    ^bb584:  // pred: ^bb582
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_764 = cute.add_offset(%iter_109, %int_tuple_740) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2284 = builtin.unrealized_conversion_cast %ptr_764 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2285 = nvvm.mapa.shared.cluster %2284, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2285, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %2286 = arith.subf %2220, %2241 : f32
      %2287 = arith.mulf %arg13, %2286 : f32
      %2288 = math.exp2 %2287 fastmath<fast> : f32
      %2289 = arith.mulf %2288, %cst_0 : f32
      %2290 = arith.mulf %2210, %2289 : f32
      %view_765 = cute.make_view(%iter_730) : !memref_rmem_f32_1
      %2291 = cute.memref.load(%view_765, %147) : (!memref_rmem_f32_1, !cute.coord<"(0,0)">) -> f32
      %2292 = cute.memref.load(%view_765, %146) : (!memref_rmem_f32_1, !cute.coord<"(1,0)">) -> f32
      %2293 = vector.splat %2290 : vector<2xf32>
      %2294 = vector.from_elements %2291, %2292 : vector<2xf32>
      %2295 = nvvm.add.packed.f32x2 %2293, %2294 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2296 = vector.extract %2295[0] : f32 from vector<2xf32>
      %2297 = vector.extract %2295[1] : f32 from vector<2xf32>
      %2298 = cute.memref.load(%view_765, %145) : (!memref_rmem_f32_1, !cute.coord<"(0,1)">) -> f32
      %2299 = cute.memref.load(%view_765, %144) : (!memref_rmem_f32_1, !cute.coord<"(1,1)">) -> f32
      %2300 = vector.from_elements %2298, %2299 : vector<2xf32>
      %2301 = nvvm.add.packed.f32x2 %cst, %2300 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2302 = vector.extract %2301[0] : f32 from vector<2xf32>
      %2303 = vector.extract %2301[1] : f32 from vector<2xf32>
      %2304 = cute.memref.load(%view_765, %143) : (!memref_rmem_f32_1, !cute.coord<"(0,2)">) -> f32
      %2305 = cute.memref.load(%view_765, %142) : (!memref_rmem_f32_1, !cute.coord<"(1,2)">) -> f32
      %2306 = vector.from_elements %2304, %2305 : vector<2xf32>
      %2307 = nvvm.add.packed.f32x2 %cst, %2306 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2308 = vector.extract %2307[0] : f32 from vector<2xf32>
      %2309 = vector.extract %2307[1] : f32 from vector<2xf32>
      %2310 = cute.memref.load(%view_765, %141) : (!memref_rmem_f32_1, !cute.coord<"(0,3)">) -> f32
      %2311 = cute.memref.load(%view_765, %140) : (!memref_rmem_f32_1, !cute.coord<"(1,3)">) -> f32
      %2312 = vector.from_elements %2310, %2311 : vector<2xf32>
      %2313 = nvvm.add.packed.f32x2 %cst, %2312 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2314 = vector.extract %2313[0] : f32 from vector<2xf32>
      %2315 = vector.extract %2313[1] : f32 from vector<2xf32>
      %2316 = cute.memref.load(%view_765, %139) : (!memref_rmem_f32_1, !cute.coord<"(2,0)">) -> f32
      %2317 = cute.memref.load(%view_765, %138) : (!memref_rmem_f32_1, !cute.coord<"(3,0)">) -> f32
      %2318 = vector.from_elements %2296, %2297 : vector<2xf32>
      %2319 = vector.from_elements %2316, %2317 : vector<2xf32>
      %2320 = nvvm.add.packed.f32x2 %2318, %2319 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2321 = vector.extract %2320[0] : f32 from vector<2xf32>
      %2322 = vector.extract %2320[1] : f32 from vector<2xf32>
      %2323 = cute.memref.load(%view_765, %137) : (!memref_rmem_f32_1, !cute.coord<"(2,1)">) -> f32
      %2324 = cute.memref.load(%view_765, %136) : (!memref_rmem_f32_1, !cute.coord<"(3,1)">) -> f32
      %2325 = vector.from_elements %2302, %2303 : vector<2xf32>
      %2326 = vector.from_elements %2323, %2324 : vector<2xf32>
      %2327 = nvvm.add.packed.f32x2 %2325, %2326 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2328 = vector.extract %2327[0] : f32 from vector<2xf32>
      %2329 = vector.extract %2327[1] : f32 from vector<2xf32>
      %2330 = cute.memref.load(%view_765, %135) : (!memref_rmem_f32_1, !cute.coord<"(2,2)">) -> f32
      %2331 = cute.memref.load(%view_765, %134) : (!memref_rmem_f32_1, !cute.coord<"(3,2)">) -> f32
      %2332 = vector.from_elements %2308, %2309 : vector<2xf32>
      %2333 = vector.from_elements %2330, %2331 : vector<2xf32>
      %2334 = nvvm.add.packed.f32x2 %2332, %2333 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2335 = vector.extract %2334[0] : f32 from vector<2xf32>
      %2336 = vector.extract %2334[1] : f32 from vector<2xf32>
      %2337 = cute.memref.load(%view_765, %133) : (!memref_rmem_f32_1, !cute.coord<"(2,3)">) -> f32
      %2338 = cute.memref.load(%view_765, %132) : (!memref_rmem_f32_1, !cute.coord<"(3,3)">) -> f32
      %2339 = vector.from_elements %2314, %2315 : vector<2xf32>
      %2340 = vector.from_elements %2337, %2338 : vector<2xf32>
      %2341 = nvvm.add.packed.f32x2 %2339, %2340 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2342 = vector.extract %2341[0] : f32 from vector<2xf32>
      %2343 = vector.extract %2341[1] : f32 from vector<2xf32>
      %2344 = cute.memref.load(%view_765, %131) : (!memref_rmem_f32_1, !cute.coord<"(4,0)">) -> f32
      %2345 = cute.memref.load(%view_765, %130) : (!memref_rmem_f32_1, !cute.coord<"(5,0)">) -> f32
      %2346 = vector.from_elements %2321, %2322 : vector<2xf32>
      %2347 = vector.from_elements %2344, %2345 : vector<2xf32>
      %2348 = nvvm.add.packed.f32x2 %2346, %2347 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2349 = vector.extract %2348[0] : f32 from vector<2xf32>
      %2350 = vector.extract %2348[1] : f32 from vector<2xf32>
      %2351 = cute.memref.load(%view_765, %129) : (!memref_rmem_f32_1, !cute.coord<"(4,1)">) -> f32
      %2352 = cute.memref.load(%view_765, %128) : (!memref_rmem_f32_1, !cute.coord<"(5,1)">) -> f32
      %2353 = vector.from_elements %2328, %2329 : vector<2xf32>
      %2354 = vector.from_elements %2351, %2352 : vector<2xf32>
      %2355 = nvvm.add.packed.f32x2 %2353, %2354 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2356 = vector.extract %2355[0] : f32 from vector<2xf32>
      %2357 = vector.extract %2355[1] : f32 from vector<2xf32>
      %2358 = cute.memref.load(%view_765, %127) : (!memref_rmem_f32_1, !cute.coord<"(4,2)">) -> f32
      %2359 = cute.memref.load(%view_765, %126) : (!memref_rmem_f32_1, !cute.coord<"(5,2)">) -> f32
      %2360 = vector.from_elements %2335, %2336 : vector<2xf32>
      %2361 = vector.from_elements %2358, %2359 : vector<2xf32>
      %2362 = nvvm.add.packed.f32x2 %2360, %2361 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2363 = vector.extract %2362[0] : f32 from vector<2xf32>
      %2364 = vector.extract %2362[1] : f32 from vector<2xf32>
      %2365 = cute.memref.load(%view_765, %125) : (!memref_rmem_f32_1, !cute.coord<"(4,3)">) -> f32
      %2366 = cute.memref.load(%view_765, %124) : (!memref_rmem_f32_1, !cute.coord<"(5,3)">) -> f32
      %2367 = vector.from_elements %2342, %2343 : vector<2xf32>
      %2368 = vector.from_elements %2365, %2366 : vector<2xf32>
      %2369 = nvvm.add.packed.f32x2 %2367, %2368 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2370 = vector.extract %2369[0] : f32 from vector<2xf32>
      %2371 = vector.extract %2369[1] : f32 from vector<2xf32>
      %2372 = cute.memref.load(%view_765, %123) : (!memref_rmem_f32_1, !cute.coord<"(6,0)">) -> f32
      %2373 = cute.memref.load(%view_765, %122) : (!memref_rmem_f32_1, !cute.coord<"(7,0)">) -> f32
      %2374 = vector.from_elements %2349, %2350 : vector<2xf32>
      %2375 = vector.from_elements %2372, %2373 : vector<2xf32>
      %2376 = nvvm.add.packed.f32x2 %2374, %2375 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2377 = vector.extract %2376[0] : f32 from vector<2xf32>
      %2378 = vector.extract %2376[1] : f32 from vector<2xf32>
      %2379 = cute.memref.load(%view_765, %121) : (!memref_rmem_f32_1, !cute.coord<"(6,1)">) -> f32
      %2380 = cute.memref.load(%view_765, %120) : (!memref_rmem_f32_1, !cute.coord<"(7,1)">) -> f32
      %2381 = vector.from_elements %2356, %2357 : vector<2xf32>
      %2382 = vector.from_elements %2379, %2380 : vector<2xf32>
      %2383 = nvvm.add.packed.f32x2 %2381, %2382 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2384 = vector.extract %2383[0] : f32 from vector<2xf32>
      %2385 = vector.extract %2383[1] : f32 from vector<2xf32>
      %2386 = cute.memref.load(%view_765, %119) : (!memref_rmem_f32_1, !cute.coord<"(6,2)">) -> f32
      %2387 = cute.memref.load(%view_765, %118) : (!memref_rmem_f32_1, !cute.coord<"(7,2)">) -> f32
      %2388 = vector.from_elements %2363, %2364 : vector<2xf32>
      %2389 = vector.from_elements %2386, %2387 : vector<2xf32>
      %2390 = nvvm.add.packed.f32x2 %2388, %2389 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2391 = vector.extract %2390[0] : f32 from vector<2xf32>
      %2392 = vector.extract %2390[1] : f32 from vector<2xf32>
      %2393 = cute.memref.load(%view_765, %117) : (!memref_rmem_f32_1, !cute.coord<"(6,3)">) -> f32
      %2394 = cute.memref.load(%view_765, %116) : (!memref_rmem_f32_1, !cute.coord<"(7,3)">) -> f32
      %2395 = vector.from_elements %2370, %2371 : vector<2xf32>
      %2396 = vector.from_elements %2393, %2394 : vector<2xf32>
      %2397 = nvvm.add.packed.f32x2 %2395, %2396 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2398 = vector.extract %2397[0] : f32 from vector<2xf32>
      %2399 = vector.extract %2397[1] : f32 from vector<2xf32>
      %2400 = cute.memref.load(%view_765, %115) : (!memref_rmem_f32_1, !cute.coord<"(8,0)">) -> f32
      %2401 = cute.memref.load(%view_765, %114) : (!memref_rmem_f32_1, !cute.coord<"(9,0)">) -> f32
      %2402 = vector.from_elements %2377, %2378 : vector<2xf32>
      %2403 = vector.from_elements %2400, %2401 : vector<2xf32>
      %2404 = nvvm.add.packed.f32x2 %2402, %2403 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2405 = vector.extract %2404[0] : f32 from vector<2xf32>
      %2406 = vector.extract %2404[1] : f32 from vector<2xf32>
      %2407 = cute.memref.load(%view_765, %113) : (!memref_rmem_f32_1, !cute.coord<"(8,1)">) -> f32
      %2408 = cute.memref.load(%view_765, %112) : (!memref_rmem_f32_1, !cute.coord<"(9,1)">) -> f32
      %2409 = vector.from_elements %2384, %2385 : vector<2xf32>
      %2410 = vector.from_elements %2407, %2408 : vector<2xf32>
      %2411 = nvvm.add.packed.f32x2 %2409, %2410 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2412 = vector.extract %2411[0] : f32 from vector<2xf32>
      %2413 = vector.extract %2411[1] : f32 from vector<2xf32>
      %2414 = cute.memref.load(%view_765, %111) : (!memref_rmem_f32_1, !cute.coord<"(8,2)">) -> f32
      %2415 = cute.memref.load(%view_765, %110) : (!memref_rmem_f32_1, !cute.coord<"(9,2)">) -> f32
      %2416 = vector.from_elements %2391, %2392 : vector<2xf32>
      %2417 = vector.from_elements %2414, %2415 : vector<2xf32>
      %2418 = nvvm.add.packed.f32x2 %2416, %2417 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2419 = vector.extract %2418[0] : f32 from vector<2xf32>
      %2420 = vector.extract %2418[1] : f32 from vector<2xf32>
      %2421 = cute.memref.load(%view_765, %109) : (!memref_rmem_f32_1, !cute.coord<"(8,3)">) -> f32
      %2422 = cute.memref.load(%view_765, %108) : (!memref_rmem_f32_1, !cute.coord<"(9,3)">) -> f32
      %2423 = vector.from_elements %2398, %2399 : vector<2xf32>
      %2424 = vector.from_elements %2421, %2422 : vector<2xf32>
      %2425 = nvvm.add.packed.f32x2 %2423, %2424 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2426 = vector.extract %2425[0] : f32 from vector<2xf32>
      %2427 = vector.extract %2425[1] : f32 from vector<2xf32>
      %2428 = cute.memref.load(%view_765, %107) : (!memref_rmem_f32_1, !cute.coord<"(10,0)">) -> f32
      %2429 = cute.memref.load(%view_765, %106) : (!memref_rmem_f32_1, !cute.coord<"(11,0)">) -> f32
      %2430 = vector.from_elements %2405, %2406 : vector<2xf32>
      %2431 = vector.from_elements %2428, %2429 : vector<2xf32>
      %2432 = nvvm.add.packed.f32x2 %2430, %2431 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2433 = vector.extract %2432[0] : f32 from vector<2xf32>
      %2434 = vector.extract %2432[1] : f32 from vector<2xf32>
      %2435 = cute.memref.load(%view_765, %105) : (!memref_rmem_f32_1, !cute.coord<"(10,1)">) -> f32
      %2436 = cute.memref.load(%view_765, %104) : (!memref_rmem_f32_1, !cute.coord<"(11,1)">) -> f32
      %2437 = vector.from_elements %2412, %2413 : vector<2xf32>
      %2438 = vector.from_elements %2435, %2436 : vector<2xf32>
      %2439 = nvvm.add.packed.f32x2 %2437, %2438 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2440 = vector.extract %2439[0] : f32 from vector<2xf32>
      %2441 = vector.extract %2439[1] : f32 from vector<2xf32>
      %2442 = cute.memref.load(%view_765, %103) : (!memref_rmem_f32_1, !cute.coord<"(10,2)">) -> f32
      %2443 = cute.memref.load(%view_765, %102) : (!memref_rmem_f32_1, !cute.coord<"(11,2)">) -> f32
      %2444 = vector.from_elements %2419, %2420 : vector<2xf32>
      %2445 = vector.from_elements %2442, %2443 : vector<2xf32>
      %2446 = nvvm.add.packed.f32x2 %2444, %2445 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2447 = vector.extract %2446[0] : f32 from vector<2xf32>
      %2448 = vector.extract %2446[1] : f32 from vector<2xf32>
      %2449 = cute.memref.load(%view_765, %101) : (!memref_rmem_f32_1, !cute.coord<"(10,3)">) -> f32
      %2450 = cute.memref.load(%view_765, %100) : (!memref_rmem_f32_1, !cute.coord<"(11,3)">) -> f32
      %2451 = vector.from_elements %2426, %2427 : vector<2xf32>
      %2452 = vector.from_elements %2449, %2450 : vector<2xf32>
      %2453 = nvvm.add.packed.f32x2 %2451, %2452 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2454 = vector.extract %2453[0] : f32 from vector<2xf32>
      %2455 = vector.extract %2453[1] : f32 from vector<2xf32>
      %2456 = cute.memref.load(%view_765, %99) : (!memref_rmem_f32_1, !cute.coord<"(12,0)">) -> f32
      %2457 = cute.memref.load(%view_765, %98) : (!memref_rmem_f32_1, !cute.coord<"(13,0)">) -> f32
      %2458 = vector.from_elements %2433, %2434 : vector<2xf32>
      %2459 = vector.from_elements %2456, %2457 : vector<2xf32>
      %2460 = nvvm.add.packed.f32x2 %2458, %2459 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2461 = vector.extract %2460[0] : f32 from vector<2xf32>
      %2462 = vector.extract %2460[1] : f32 from vector<2xf32>
      %2463 = cute.memref.load(%view_765, %97) : (!memref_rmem_f32_1, !cute.coord<"(12,1)">) -> f32
      %2464 = cute.memref.load(%view_765, %96) : (!memref_rmem_f32_1, !cute.coord<"(13,1)">) -> f32
      %2465 = vector.from_elements %2440, %2441 : vector<2xf32>
      %2466 = vector.from_elements %2463, %2464 : vector<2xf32>
      %2467 = nvvm.add.packed.f32x2 %2465, %2466 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2468 = vector.extract %2467[0] : f32 from vector<2xf32>
      %2469 = vector.extract %2467[1] : f32 from vector<2xf32>
      %2470 = cute.memref.load(%view_765, %95) : (!memref_rmem_f32_1, !cute.coord<"(12,2)">) -> f32
      %2471 = cute.memref.load(%view_765, %94) : (!memref_rmem_f32_1, !cute.coord<"(13,2)">) -> f32
      %2472 = vector.from_elements %2447, %2448 : vector<2xf32>
      %2473 = vector.from_elements %2470, %2471 : vector<2xf32>
      %2474 = nvvm.add.packed.f32x2 %2472, %2473 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2475 = vector.extract %2474[0] : f32 from vector<2xf32>
      %2476 = vector.extract %2474[1] : f32 from vector<2xf32>
      %2477 = cute.memref.load(%view_765, %93) : (!memref_rmem_f32_1, !cute.coord<"(12,3)">) -> f32
      %2478 = cute.memref.load(%view_765, %92) : (!memref_rmem_f32_1, !cute.coord<"(13,3)">) -> f32
      %2479 = vector.from_elements %2454, %2455 : vector<2xf32>
      %2480 = vector.from_elements %2477, %2478 : vector<2xf32>
      %2481 = nvvm.add.packed.f32x2 %2479, %2480 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2482 = vector.extract %2481[0] : f32 from vector<2xf32>
      %2483 = vector.extract %2481[1] : f32 from vector<2xf32>
      %2484 = cute.memref.load(%view_765, %91) : (!memref_rmem_f32_1, !cute.coord<"(14,0)">) -> f32
      %2485 = cute.memref.load(%view_765, %90) : (!memref_rmem_f32_1, !cute.coord<"(15,0)">) -> f32
      %2486 = vector.from_elements %2461, %2462 : vector<2xf32>
      %2487 = vector.from_elements %2484, %2485 : vector<2xf32>
      %2488 = nvvm.add.packed.f32x2 %2486, %2487 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2489 = vector.extract %2488[0] : f32 from vector<2xf32>
      %2490 = vector.extract %2488[1] : f32 from vector<2xf32>
      %2491 = cute.memref.load(%view_765, %89) : (!memref_rmem_f32_1, !cute.coord<"(14,1)">) -> f32
      %2492 = cute.memref.load(%view_765, %88) : (!memref_rmem_f32_1, !cute.coord<"(15,1)">) -> f32
      %2493 = vector.from_elements %2468, %2469 : vector<2xf32>
      %2494 = vector.from_elements %2491, %2492 : vector<2xf32>
      %2495 = nvvm.add.packed.f32x2 %2493, %2494 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2496 = vector.extract %2495[0] : f32 from vector<2xf32>
      %2497 = vector.extract %2495[1] : f32 from vector<2xf32>
      %2498 = cute.memref.load(%view_765, %87) : (!memref_rmem_f32_1, !cute.coord<"(14,2)">) -> f32
      %2499 = cute.memref.load(%view_765, %86) : (!memref_rmem_f32_1, !cute.coord<"(15,2)">) -> f32
      %2500 = vector.from_elements %2475, %2476 : vector<2xf32>
      %2501 = vector.from_elements %2498, %2499 : vector<2xf32>
      %2502 = nvvm.add.packed.f32x2 %2500, %2501 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2503 = vector.extract %2502[0] : f32 from vector<2xf32>
      %2504 = vector.extract %2502[1] : f32 from vector<2xf32>
      %2505 = cute.memref.load(%view_765, %85) : (!memref_rmem_f32_1, !cute.coord<"(14,3)">) -> f32
      %2506 = cute.memref.load(%view_765, %84) : (!memref_rmem_f32_1, !cute.coord<"(15,3)">) -> f32
      %2507 = vector.from_elements %2482, %2483 : vector<2xf32>
      %2508 = vector.from_elements %2505, %2506 : vector<2xf32>
      %2509 = nvvm.add.packed.f32x2 %2507, %2508 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2510 = vector.extract %2509[0] : f32 from vector<2xf32>
      %2511 = vector.extract %2509[1] : f32 from vector<2xf32>
      %2512 = cute.memref.load(%view_765, %83) : (!memref_rmem_f32_1, !cute.coord<"(16,0)">) -> f32
      %2513 = cute.memref.load(%view_765, %82) : (!memref_rmem_f32_1, !cute.coord<"(17,0)">) -> f32
      %2514 = vector.from_elements %2489, %2490 : vector<2xf32>
      %2515 = vector.from_elements %2512, %2513 : vector<2xf32>
      %2516 = nvvm.add.packed.f32x2 %2514, %2515 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2517 = vector.extract %2516[0] : f32 from vector<2xf32>
      %2518 = vector.extract %2516[1] : f32 from vector<2xf32>
      %2519 = cute.memref.load(%view_765, %81) : (!memref_rmem_f32_1, !cute.coord<"(16,1)">) -> f32
      %2520 = cute.memref.load(%view_765, %80) : (!memref_rmem_f32_1, !cute.coord<"(17,1)">) -> f32
      %2521 = vector.from_elements %2496, %2497 : vector<2xf32>
      %2522 = vector.from_elements %2519, %2520 : vector<2xf32>
      %2523 = nvvm.add.packed.f32x2 %2521, %2522 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2524 = vector.extract %2523[0] : f32 from vector<2xf32>
      %2525 = vector.extract %2523[1] : f32 from vector<2xf32>
      %2526 = cute.memref.load(%view_765, %79) : (!memref_rmem_f32_1, !cute.coord<"(16,2)">) -> f32
      %2527 = cute.memref.load(%view_765, %78) : (!memref_rmem_f32_1, !cute.coord<"(17,2)">) -> f32
      %2528 = vector.from_elements %2503, %2504 : vector<2xf32>
      %2529 = vector.from_elements %2526, %2527 : vector<2xf32>
      %2530 = nvvm.add.packed.f32x2 %2528, %2529 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2531 = vector.extract %2530[0] : f32 from vector<2xf32>
      %2532 = vector.extract %2530[1] : f32 from vector<2xf32>
      %2533 = cute.memref.load(%view_765, %77) : (!memref_rmem_f32_1, !cute.coord<"(16,3)">) -> f32
      %2534 = cute.memref.load(%view_765, %76) : (!memref_rmem_f32_1, !cute.coord<"(17,3)">) -> f32
      %2535 = vector.from_elements %2510, %2511 : vector<2xf32>
      %2536 = vector.from_elements %2533, %2534 : vector<2xf32>
      %2537 = nvvm.add.packed.f32x2 %2535, %2536 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2538 = vector.extract %2537[0] : f32 from vector<2xf32>
      %2539 = vector.extract %2537[1] : f32 from vector<2xf32>
      %2540 = cute.memref.load(%view_765, %75) : (!memref_rmem_f32_1, !cute.coord<"(18,0)">) -> f32
      %2541 = cute.memref.load(%view_765, %74) : (!memref_rmem_f32_1, !cute.coord<"(19,0)">) -> f32
      %2542 = vector.from_elements %2517, %2518 : vector<2xf32>
      %2543 = vector.from_elements %2540, %2541 : vector<2xf32>
      %2544 = nvvm.add.packed.f32x2 %2542, %2543 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2545 = vector.extract %2544[0] : f32 from vector<2xf32>
      %2546 = vector.extract %2544[1] : f32 from vector<2xf32>
      %2547 = cute.memref.load(%view_765, %73) : (!memref_rmem_f32_1, !cute.coord<"(18,1)">) -> f32
      %2548 = cute.memref.load(%view_765, %72) : (!memref_rmem_f32_1, !cute.coord<"(19,1)">) -> f32
      %2549 = vector.from_elements %2524, %2525 : vector<2xf32>
      %2550 = vector.from_elements %2547, %2548 : vector<2xf32>
      %2551 = nvvm.add.packed.f32x2 %2549, %2550 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2552 = vector.extract %2551[0] : f32 from vector<2xf32>
      %2553 = vector.extract %2551[1] : f32 from vector<2xf32>
      %2554 = cute.memref.load(%view_765, %71) : (!memref_rmem_f32_1, !cute.coord<"(18,2)">) -> f32
      %2555 = cute.memref.load(%view_765, %70) : (!memref_rmem_f32_1, !cute.coord<"(19,2)">) -> f32
      %2556 = vector.from_elements %2531, %2532 : vector<2xf32>
      %2557 = vector.from_elements %2554, %2555 : vector<2xf32>
      %2558 = nvvm.add.packed.f32x2 %2556, %2557 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2559 = vector.extract %2558[0] : f32 from vector<2xf32>
      %2560 = vector.extract %2558[1] : f32 from vector<2xf32>
      %2561 = cute.memref.load(%view_765, %69) : (!memref_rmem_f32_1, !cute.coord<"(18,3)">) -> f32
      %2562 = cute.memref.load(%view_765, %68) : (!memref_rmem_f32_1, !cute.coord<"(19,3)">) -> f32
      %2563 = vector.from_elements %2538, %2539 : vector<2xf32>
      %2564 = vector.from_elements %2561, %2562 : vector<2xf32>
      %2565 = nvvm.add.packed.f32x2 %2563, %2564 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2566 = vector.extract %2565[0] : f32 from vector<2xf32>
      %2567 = vector.extract %2565[1] : f32 from vector<2xf32>
      %2568 = cute.memref.load(%view_765, %67) : (!memref_rmem_f32_1, !cute.coord<"(20,0)">) -> f32
      %2569 = cute.memref.load(%view_765, %66) : (!memref_rmem_f32_1, !cute.coord<"(21,0)">) -> f32
      %2570 = vector.from_elements %2545, %2546 : vector<2xf32>
      %2571 = vector.from_elements %2568, %2569 : vector<2xf32>
      %2572 = nvvm.add.packed.f32x2 %2570, %2571 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2573 = vector.extract %2572[0] : f32 from vector<2xf32>
      %2574 = vector.extract %2572[1] : f32 from vector<2xf32>
      %2575 = cute.memref.load(%view_765, %65) : (!memref_rmem_f32_1, !cute.coord<"(20,1)">) -> f32
      %2576 = cute.memref.load(%view_765, %64) : (!memref_rmem_f32_1, !cute.coord<"(21,1)">) -> f32
      %2577 = vector.from_elements %2552, %2553 : vector<2xf32>
      %2578 = vector.from_elements %2575, %2576 : vector<2xf32>
      %2579 = nvvm.add.packed.f32x2 %2577, %2578 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2580 = vector.extract %2579[0] : f32 from vector<2xf32>
      %2581 = vector.extract %2579[1] : f32 from vector<2xf32>
      %2582 = cute.memref.load(%view_765, %63) : (!memref_rmem_f32_1, !cute.coord<"(20,2)">) -> f32
      %2583 = cute.memref.load(%view_765, %62) : (!memref_rmem_f32_1, !cute.coord<"(21,2)">) -> f32
      %2584 = vector.from_elements %2559, %2560 : vector<2xf32>
      %2585 = vector.from_elements %2582, %2583 : vector<2xf32>
      %2586 = nvvm.add.packed.f32x2 %2584, %2585 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2587 = vector.extract %2586[0] : f32 from vector<2xf32>
      %2588 = vector.extract %2586[1] : f32 from vector<2xf32>
      %2589 = cute.memref.load(%view_765, %61) : (!memref_rmem_f32_1, !cute.coord<"(20,3)">) -> f32
      %2590 = cute.memref.load(%view_765, %60) : (!memref_rmem_f32_1, !cute.coord<"(21,3)">) -> f32
      %2591 = vector.from_elements %2566, %2567 : vector<2xf32>
      %2592 = vector.from_elements %2589, %2590 : vector<2xf32>
      %2593 = nvvm.add.packed.f32x2 %2591, %2592 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2594 = vector.extract %2593[0] : f32 from vector<2xf32>
      %2595 = vector.extract %2593[1] : f32 from vector<2xf32>
      %2596 = cute.memref.load(%view_765, %59) : (!memref_rmem_f32_1, !cute.coord<"(22,0)">) -> f32
      %2597 = cute.memref.load(%view_765, %58) : (!memref_rmem_f32_1, !cute.coord<"(23,0)">) -> f32
      %2598 = vector.from_elements %2573, %2574 : vector<2xf32>
      %2599 = vector.from_elements %2596, %2597 : vector<2xf32>
      %2600 = nvvm.add.packed.f32x2 %2598, %2599 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2601 = vector.extract %2600[0] : f32 from vector<2xf32>
      %2602 = vector.extract %2600[1] : f32 from vector<2xf32>
      %2603 = cute.memref.load(%view_765, %57) : (!memref_rmem_f32_1, !cute.coord<"(22,1)">) -> f32
      %2604 = cute.memref.load(%view_765, %56) : (!memref_rmem_f32_1, !cute.coord<"(23,1)">) -> f32
      %2605 = vector.from_elements %2580, %2581 : vector<2xf32>
      %2606 = vector.from_elements %2603, %2604 : vector<2xf32>
      %2607 = nvvm.add.packed.f32x2 %2605, %2606 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2608 = vector.extract %2607[0] : f32 from vector<2xf32>
      %2609 = vector.extract %2607[1] : f32 from vector<2xf32>
      %2610 = cute.memref.load(%view_765, %55) : (!memref_rmem_f32_1, !cute.coord<"(22,2)">) -> f32
      %2611 = cute.memref.load(%view_765, %54) : (!memref_rmem_f32_1, !cute.coord<"(23,2)">) -> f32
      %2612 = vector.from_elements %2587, %2588 : vector<2xf32>
      %2613 = vector.from_elements %2610, %2611 : vector<2xf32>
      %2614 = nvvm.add.packed.f32x2 %2612, %2613 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2615 = vector.extract %2614[0] : f32 from vector<2xf32>
      %2616 = vector.extract %2614[1] : f32 from vector<2xf32>
      %2617 = cute.memref.load(%view_765, %53) : (!memref_rmem_f32_1, !cute.coord<"(22,3)">) -> f32
      %2618 = cute.memref.load(%view_765, %52) : (!memref_rmem_f32_1, !cute.coord<"(23,3)">) -> f32
      %2619 = vector.from_elements %2594, %2595 : vector<2xf32>
      %2620 = vector.from_elements %2617, %2618 : vector<2xf32>
      %2621 = nvvm.add.packed.f32x2 %2619, %2620 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2622 = vector.extract %2621[0] : f32 from vector<2xf32>
      %2623 = vector.extract %2621[1] : f32 from vector<2xf32>
      %2624 = cute.memref.load(%view_765, %51) : (!memref_rmem_f32_1, !cute.coord<"(24,0)">) -> f32
      %2625 = cute.memref.load(%view_765, %50) : (!memref_rmem_f32_1, !cute.coord<"(25,0)">) -> f32
      %2626 = vector.from_elements %2601, %2602 : vector<2xf32>
      %2627 = vector.from_elements %2624, %2625 : vector<2xf32>
      %2628 = nvvm.add.packed.f32x2 %2626, %2627 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2629 = vector.extract %2628[0] : f32 from vector<2xf32>
      %2630 = vector.extract %2628[1] : f32 from vector<2xf32>
      %2631 = cute.memref.load(%view_765, %49) : (!memref_rmem_f32_1, !cute.coord<"(24,1)">) -> f32
      %2632 = cute.memref.load(%view_765, %48) : (!memref_rmem_f32_1, !cute.coord<"(25,1)">) -> f32
      %2633 = vector.from_elements %2608, %2609 : vector<2xf32>
      %2634 = vector.from_elements %2631, %2632 : vector<2xf32>
      %2635 = nvvm.add.packed.f32x2 %2633, %2634 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2636 = vector.extract %2635[0] : f32 from vector<2xf32>
      %2637 = vector.extract %2635[1] : f32 from vector<2xf32>
      %2638 = cute.memref.load(%view_765, %47) : (!memref_rmem_f32_1, !cute.coord<"(24,2)">) -> f32
      %2639 = cute.memref.load(%view_765, %46) : (!memref_rmem_f32_1, !cute.coord<"(25,2)">) -> f32
      %2640 = vector.from_elements %2615, %2616 : vector<2xf32>
      %2641 = vector.from_elements %2638, %2639 : vector<2xf32>
      %2642 = nvvm.add.packed.f32x2 %2640, %2641 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2643 = vector.extract %2642[0] : f32 from vector<2xf32>
      %2644 = vector.extract %2642[1] : f32 from vector<2xf32>
      %2645 = cute.memref.load(%view_765, %45) : (!memref_rmem_f32_1, !cute.coord<"(24,3)">) -> f32
      %2646 = cute.memref.load(%view_765, %44) : (!memref_rmem_f32_1, !cute.coord<"(25,3)">) -> f32
      %2647 = vector.from_elements %2622, %2623 : vector<2xf32>
      %2648 = vector.from_elements %2645, %2646 : vector<2xf32>
      %2649 = nvvm.add.packed.f32x2 %2647, %2648 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2650 = vector.extract %2649[0] : f32 from vector<2xf32>
      %2651 = vector.extract %2649[1] : f32 from vector<2xf32>
      %2652 = cute.memref.load(%view_765, %43) : (!memref_rmem_f32_1, !cute.coord<"(26,0)">) -> f32
      %2653 = cute.memref.load(%view_765, %42) : (!memref_rmem_f32_1, !cute.coord<"(27,0)">) -> f32
      %2654 = vector.from_elements %2629, %2630 : vector<2xf32>
      %2655 = vector.from_elements %2652, %2653 : vector<2xf32>
      %2656 = nvvm.add.packed.f32x2 %2654, %2655 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2657 = vector.extract %2656[0] : f32 from vector<2xf32>
      %2658 = vector.extract %2656[1] : f32 from vector<2xf32>
      %2659 = cute.memref.load(%view_765, %41) : (!memref_rmem_f32_1, !cute.coord<"(26,1)">) -> f32
      %2660 = cute.memref.load(%view_765, %40) : (!memref_rmem_f32_1, !cute.coord<"(27,1)">) -> f32
      %2661 = vector.from_elements %2636, %2637 : vector<2xf32>
      %2662 = vector.from_elements %2659, %2660 : vector<2xf32>
      %2663 = nvvm.add.packed.f32x2 %2661, %2662 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2664 = vector.extract %2663[0] : f32 from vector<2xf32>
      %2665 = vector.extract %2663[1] : f32 from vector<2xf32>
      %2666 = cute.memref.load(%view_765, %39) : (!memref_rmem_f32_1, !cute.coord<"(26,2)">) -> f32
      %2667 = cute.memref.load(%view_765, %38) : (!memref_rmem_f32_1, !cute.coord<"(27,2)">) -> f32
      %2668 = vector.from_elements %2643, %2644 : vector<2xf32>
      %2669 = vector.from_elements %2666, %2667 : vector<2xf32>
      %2670 = nvvm.add.packed.f32x2 %2668, %2669 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2671 = vector.extract %2670[0] : f32 from vector<2xf32>
      %2672 = vector.extract %2670[1] : f32 from vector<2xf32>
      %2673 = cute.memref.load(%view_765, %37) : (!memref_rmem_f32_1, !cute.coord<"(26,3)">) -> f32
      %2674 = cute.memref.load(%view_765, %36) : (!memref_rmem_f32_1, !cute.coord<"(27,3)">) -> f32
      %2675 = vector.from_elements %2650, %2651 : vector<2xf32>
      %2676 = vector.from_elements %2673, %2674 : vector<2xf32>
      %2677 = nvvm.add.packed.f32x2 %2675, %2676 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2678 = vector.extract %2677[0] : f32 from vector<2xf32>
      %2679 = vector.extract %2677[1] : f32 from vector<2xf32>
      %2680 = cute.memref.load(%view_765, %35) : (!memref_rmem_f32_1, !cute.coord<"(28,0)">) -> f32
      %2681 = cute.memref.load(%view_765, %34) : (!memref_rmem_f32_1, !cute.coord<"(29,0)">) -> f32
      %2682 = vector.from_elements %2657, %2658 : vector<2xf32>
      %2683 = vector.from_elements %2680, %2681 : vector<2xf32>
      %2684 = nvvm.add.packed.f32x2 %2682, %2683 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2685 = vector.extract %2684[0] : f32 from vector<2xf32>
      %2686 = vector.extract %2684[1] : f32 from vector<2xf32>
      %2687 = cute.memref.load(%view_765, %33) : (!memref_rmem_f32_1, !cute.coord<"(28,1)">) -> f32
      %2688 = cute.memref.load(%view_765, %32) : (!memref_rmem_f32_1, !cute.coord<"(29,1)">) -> f32
      %2689 = vector.from_elements %2664, %2665 : vector<2xf32>
      %2690 = vector.from_elements %2687, %2688 : vector<2xf32>
      %2691 = nvvm.add.packed.f32x2 %2689, %2690 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2692 = vector.extract %2691[0] : f32 from vector<2xf32>
      %2693 = vector.extract %2691[1] : f32 from vector<2xf32>
      %2694 = cute.memref.load(%view_765, %31) : (!memref_rmem_f32_1, !cute.coord<"(28,2)">) -> f32
      %2695 = cute.memref.load(%view_765, %30) : (!memref_rmem_f32_1, !cute.coord<"(29,2)">) -> f32
      %2696 = vector.from_elements %2671, %2672 : vector<2xf32>
      %2697 = vector.from_elements %2694, %2695 : vector<2xf32>
      %2698 = nvvm.add.packed.f32x2 %2696, %2697 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2699 = vector.extract %2698[0] : f32 from vector<2xf32>
      %2700 = vector.extract %2698[1] : f32 from vector<2xf32>
      %2701 = cute.memref.load(%view_765, %29) : (!memref_rmem_f32_1, !cute.coord<"(28,3)">) -> f32
      %2702 = cute.memref.load(%view_765, %28) : (!memref_rmem_f32_1, !cute.coord<"(29,3)">) -> f32
      %2703 = vector.from_elements %2678, %2679 : vector<2xf32>
      %2704 = vector.from_elements %2701, %2702 : vector<2xf32>
      %2705 = nvvm.add.packed.f32x2 %2703, %2704 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2706 = vector.extract %2705[0] : f32 from vector<2xf32>
      %2707 = vector.extract %2705[1] : f32 from vector<2xf32>
      %2708 = cute.memref.load(%view_765, %27) : (!memref_rmem_f32_1, !cute.coord<"(30,0)">) -> f32
      %2709 = cute.memref.load(%view_765, %26) : (!memref_rmem_f32_1, !cute.coord<"(31,0)">) -> f32
      %2710 = vector.from_elements %2685, %2686 : vector<2xf32>
      %2711 = vector.from_elements %2708, %2709 : vector<2xf32>
      %2712 = nvvm.add.packed.f32x2 %2710, %2711 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2713 = vector.extract %2712[0] : f32 from vector<2xf32>
      %2714 = vector.extract %2712[1] : f32 from vector<2xf32>
      %2715 = cute.memref.load(%view_765, %25) : (!memref_rmem_f32_1, !cute.coord<"(30,1)">) -> f32
      %2716 = cute.memref.load(%view_765, %24) : (!memref_rmem_f32_1, !cute.coord<"(31,1)">) -> f32
      %2717 = vector.from_elements %2692, %2693 : vector<2xf32>
      %2718 = vector.from_elements %2715, %2716 : vector<2xf32>
      %2719 = nvvm.add.packed.f32x2 %2717, %2718 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2720 = vector.extract %2719[0] : f32 from vector<2xf32>
      %2721 = vector.extract %2719[1] : f32 from vector<2xf32>
      %2722 = cute.memref.load(%view_765, %23) : (!memref_rmem_f32_1, !cute.coord<"(30,2)">) -> f32
      %2723 = cute.memref.load(%view_765, %22) : (!memref_rmem_f32_1, !cute.coord<"(31,2)">) -> f32
      %2724 = vector.from_elements %2699, %2700 : vector<2xf32>
      %2725 = vector.from_elements %2722, %2723 : vector<2xf32>
      %2726 = nvvm.add.packed.f32x2 %2724, %2725 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2727 = vector.extract %2726[0] : f32 from vector<2xf32>
      %2728 = vector.extract %2726[1] : f32 from vector<2xf32>
      %2729 = cute.memref.load(%view_765, %21) : (!memref_rmem_f32_1, !cute.coord<"(30,3)">) -> f32
      %2730 = cute.memref.load(%view_765, %20) : (!memref_rmem_f32_1, !cute.coord<"(31,3)">) -> f32
      %2731 = vector.from_elements %2706, %2707 : vector<2xf32>
      %2732 = vector.from_elements %2729, %2730 : vector<2xf32>
      %2733 = nvvm.add.packed.f32x2 %2731, %2732 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2734 = vector.extract %2733[0] : f32 from vector<2xf32>
      %2735 = vector.extract %2733[1] : f32 from vector<2xf32>
      %2736 = vector.from_elements %2713, %2714 : vector<2xf32>
      %2737 = vector.from_elements %2720, %2721 : vector<2xf32>
      %2738 = nvvm.add.packed.f32x2 %2736, %2737 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2739 = vector.extract %2738[0] : f32 from vector<2xf32>
      %2740 = vector.extract %2738[1] : f32 from vector<2xf32>
      %2741 = vector.from_elements %2727, %2728 : vector<2xf32>
      %2742 = vector.from_elements %2734, %2735 : vector<2xf32>
      %2743 = nvvm.add.packed.f32x2 %2741, %2742 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2744 = vector.extract %2743[0] : f32 from vector<2xf32>
      %2745 = vector.extract %2743[1] : f32 from vector<2xf32>
      %2746 = vector.from_elements %2739, %2740 : vector<2xf32>
      %2747 = vector.from_elements %2744, %2745 : vector<2xf32>
      %2748 = nvvm.add.packed.f32x2 %2746, %2747 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2749 = vector.extract %2748[0] : f32 from vector<2xf32>
      %2750 = vector.extract %2748[1] : f32 from vector<2xf32>
      %2751 = arith.addf %2749, %2750 : f32
      %2752 = arith.subf %2220, %2239 : f32
      %2753 = arith.mulf %arg13, %2752 : f32
      %2754 = math.exp2 %2753 fastmath<fast> : f32
      %int_tuple_766 = cute.make_int_tuple(%2218) : (i32) -> !cute.int_tuple<"?">
      %ptr_767 = cute.add_offset(%iter_114, %int_tuple_766) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2755 = builtin.unrealized_conversion_cast %ptr_767 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2755, %2219, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2756 = arith.addi %2218, %c1_i32 : i32
      %2757 = arith.addi %2217, %c1_i32 : i32
      %2758 = arith.cmpi eq, %2756, %c1_i32 : i32
      %2759 = arith.select %2758, %c0_i32, %2756 : i32
      cf.cond_br %2758, ^bb585, ^bb586
    ^bb585:  // pred: ^bb584
      %2760 = arith.xori %2219, %c1_i32 : i32
      cf.br ^bb587(%2760 : i32)
    ^bb586:  // pred: ^bb584
      cf.br ^bb587(%2219 : i32)
    ^bb587(%2761: i32):  // 2 preds: ^bb585, ^bb586
      cf.br ^bb588
    ^bb588:  // pred: ^bb587
      %2762 = vector.splat %2754 : vector<2xf32>
      cf.br ^bb589(%c0_i32 : i32)
    ^bb589(%2763: i32):  // 2 preds: ^bb588, ^bb602
      %2764 = arith.cmpi slt, %2763, %c2_i32 : i32
      cf.cond_br %2764, ^bb590, ^bb603
    ^bb590:  // pred: ^bb589
      %coord_768 = cute.make_coord(%2763) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_769 = cute.crd2idx(%coord_768, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_770 = cute.add_offset(%ptr_140, %idx_769) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_771 = cute.add_offset(%ptr_770, %int_tuple_668) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      cf.br ^bb591(%c0_i32 : i32)
    ^bb591(%2765: i32):  // 2 preds: ^bb590, ^bb601
      %2766 = arith.cmpi slt, %2765, %c4_i32 : i32
      cf.cond_br %2766, ^bb592, ^bb602 {loop_annotation = #loop_annotation1}
    ^bb592:  // pred: ^bb591
      %coord_772 = cute.make_coord(%2765) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_773 = cute.crd2idx(%coord_772, %154) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((32,32),1),1,4):(((1,65536),0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_774 = cute.add_offset(%ptr_771, %idx_773) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %rmem_775 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_776 = cute.get_iter(%rmem_775) : !memref_rmem_f32_2
      %2767 = builtin.unrealized_conversion_cast %iter_776 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb593(%c0_i32 : i32)
    ^bb593(%2768: i32):  // 2 preds: ^bb592, ^bb594
      %2769 = arith.cmpi slt, %2768, %1644 : i32
      cf.cond_br %2769, ^bb594, ^bb595 {llvm.loop_annotation = #loop_annotation}
    ^bb594:  // pred: ^bb593
      %2770 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_774) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      llvm.store %2770, %2767 : vector<32xi32>, !llvm.ptr
      %2771 = arith.addi %2768, %c1_i32 : i32
      cf.br ^bb593(%2771 : i32)
    ^bb595:  // pred: ^bb593
      cf.br ^bb596(%c0_i32 : i32)
    ^bb596(%2772: i32):  // 2 preds: ^bb595, ^bb597
      %2773 = arith.cmpi slt, %2772, %c32_i32 : i32
      cf.cond_br %2773, ^bb597, ^bb598 {loop_annotation = #loop_annotation1}
    ^bb597:  // pred: ^bb596
      %coord_777 = cute.make_coord(%2772) : (i32) -> !cute.coord<"?">
      %2774 = cute.memref.load(%rmem_775, %coord_777) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2775 = arith.addi %2772, %c1_i32 : i32
      %coord_778 = cute.make_coord(%2775) : (i32) -> !cute.coord<"?">
      %2776 = cute.memref.load(%rmem_775, %coord_778) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2777 = vector.from_elements %2774, %2776 : vector<2xf32>
      %2778 = nvvm.mul.packed.f32x2 %2777, %2762 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2779 = vector.extract %2778[0] : f32 from vector<2xf32>
      %2780 = vector.extract %2778[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_775, %coord_777, %2779) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_775, %coord_778, %2780) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      %2781 = arith.addi %2772, %c2_i32 : i32
      cf.br ^bb596(%2781 : i32)
    ^bb598:  // pred: ^bb596
      %2782 = builtin.unrealized_conversion_cast %iter_776 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb599(%c0_i32 : i32)
    ^bb599(%2783: i32):  // 2 preds: ^bb598, ^bb600
      %2784 = arith.cmpi slt, %2783, %1644 : i32
      cf.cond_br %2784, ^bb600, ^bb601 {llvm.loop_annotation = #loop_annotation}
    ^bb600:  // pred: ^bb599
      %2785 = llvm.load %2782 : !llvm.ptr -> vector<32xi32>
      "cute_nvgpu.arch.copy.SM100.tmem_store"(%ptr_774, %2785) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>, vector<32xi32>) -> ()
      %2786 = arith.addi %2783, %c1_i32 : i32
      cf.br ^bb599(%2786 : i32)
    ^bb601:  // pred: ^bb599
      %2787 = arith.addi %2765, %c1_i32 : i32
      cf.br ^bb591(%2787 : i32)
    ^bb602:  // pred: ^bb591
      %2788 = arith.addi %2763, %c1_i32 : i32
      cf.br ^bb589(%2788 : i32)
    ^bb603:  // pred: ^bb589
      nvvm.tcgen05.wait <store>
      %ptr_779 = cute.add_offset(%ptr_115, %int_tuple_766) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2789 = builtin.unrealized_conversion_cast %ptr_779 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2790 = nvvm.mapa.shared.cluster %2789, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2790, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %2791 = arith.addi %2209, %c1_i32 : i32
      cf.br ^bb566(%2791, %2751, %2224, %2226, %2228, %2263, %2265, %2267, %2757, %2759, %2761, %2239 : i32, f32, i32, i32, i32, i32, i32, i32, i32, i32, i32, f32)
    ^bb604:  // pred: ^bb566
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cute.memref.store(%view, %coord_660, %2210) : (!memref_smem_f32_, !cute.coord<"?">, f32) -> ()
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %2792 = cute.memref.load(%view, %coord_663) : (!memref_smem_f32_, !cute.coord<"?">) -> f32
      %2793 = arith.addf %2210, %2792 : f32
      %2794 = arith.divf %arg14, %2793 : f32
      %int_tuple_780 = cute.make_int_tuple(%2218) : (i32) -> !cute.int_tuple<"?">
      %ptr_781 = cute.add_offset(%iter_114, %int_tuple_780) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2795 = builtin.unrealized_conversion_cast %ptr_781 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2795, %2219, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2796 = arith.addi %2218, %c1_i32 : i32
      %2797 = arith.addi %2217, %c1_i32 : i32
      %2798 = arith.cmpi eq, %2796, %c1_i32 : i32
      %2799 = arith.select %2798, %c0_i32, %2796 : i32
      cf.cond_br %2798, ^bb605, ^bb606
    ^bb605:  // pred: ^bb604
      %2800 = arith.xori %2219, %c1_i32 : i32
      cf.br ^bb607(%2800 : i32)
    ^bb606:  // pred: ^bb604
      cf.br ^bb607(%2219 : i32)
    ^bb607(%2801: i32):  // 2 preds: ^bb605, ^bb606
      cf.br ^bb608
    ^bb608:  // pred: ^bb607
      %2802 = vector.splat %2794 : vector<2xf32>
      cf.br ^bb609(%c0_i32 : i32)
    ^bb609(%2803: i32):  // 2 preds: ^bb608, ^bb624
      %2804 = arith.cmpi slt, %2803, %c2_i32 : i32
      cf.cond_br %2804, ^bb610, ^bb625
    ^bb610:  // pred: ^bb609
      %coord_782 = cute.make_coord(%2803) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_783 = cute.crd2idx(%coord_782, %lay_653) : (!cute.coord<"(_,_,?)">, !cute.layout<"(64,256,?):(?{div=256},1,256)">) -> !cute.int_tuple<"?{div=256}">
      %ptr_784 = cute.add_offset(%ptr_655, %idx_783) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, gmem, align<128>>
      %idx_785 = cute.crd2idx(%coord_782, %lay_657) : (!cute.coord<"(_,_,?)">, !cute.layout<"(64,256,?):(1@0,1@1,256@1)">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_786 = cute.add_offset(%tup_659, %idx_785) : (!cute.int_tuple<"(?{div=64},0,((?,?),?))">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256},((?,?),?))">
      %coord_787 = cute.make_coord(%2803) : (i32) -> !cute.coord<"((_,_),0,0,?)">
      %idx_788 = cute.crd2idx(%coord_787, %201) : (!cute.coord<"((_,_),0,0,?)">, !cute.layout<"((64,(128,2)),1,1,2):((65536,(1,4194304)),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_789 = cute.add_offset(%ptr_140, %idx_788) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_790 = cute.add_offset(%ptr_789, %int_tuple_676) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<1>>
      %ptr_791 = cute.add_offset(%ptr_784, %int_tuple_678) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, gmem, align<128>>
      %tup_792 = cute.add_offset(%tup_786, %int_tuple_680) : (!cute.int_tuple<"(?{div=64},?{div=256},((?,?),?))">, !cute.int_tuple<"(?,?{div=128})">) -> !cute.int_tuple<"(?,?{div=128},((?,?),?))">
      cf.br ^bb611(%c0_i32 : i32)
    ^bb611(%2805: i32):  // 2 preds: ^bb610, ^bb623
      %2806 = arith.cmpi slt, %2805, %c4_i32 : i32
      cf.cond_br %2806, ^bb612, ^bb624 {loop_annotation = #loop_annotation1}
    ^bb612:  // pred: ^bb611
      %coord_793 = cute.make_coord(%2805) : (i32) -> !cute.coord<"(_,0,?)">
      %idx_794 = cute.crd2idx(%coord_793, %154) : (!cute.coord<"(_,0,?)">, !cute.layout<"(((32,32),1),1,4):(((1,65536),0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_795 = cute.add_offset(%ptr_790, %idx_794) : (!cute.ptr<f32, tmem, align<1>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<1>>
      %idx_796 = cute.crd2idx(%coord_793, %155) : (!cute.coord<"(_,0,?)">, !cute.layout<"((32,1),1,4):((1,0),0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_797 = cute.add_offset(%ptr_791, %idx_796) : (!cute.ptr<bf16, gmem, align<128>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, gmem, align<64>>
      %idx_798 = cute.crd2idx(%coord_793, %17) : (!cute.coord<"(_,0,?)">, !cute.layout<"((32,1),1,4):((1@1,0),0,32@1)">) -> !cute.int_tuple<"(0,?{div=32})">
      %tup_799 = cute.add_offset(%tup_792, %idx_798) : (!cute.int_tuple<"(?,?{div=128},((?,?),?))">, !cute.int_tuple<"(0,?{div=32})">) -> !cute.int_tuple<"(?,?{div=32},((?,?),?))">
      %rmem_800 = cute.memref.alloca() : !memref_rmem_f32_2
      %iter_801 = cute.get_iter(%rmem_800) : !memref_rmem_f32_2
      %2807 = builtin.unrealized_conversion_cast %iter_801 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb613(%c0_i32 : i32)
    ^bb613(%2808: i32):  // 2 preds: ^bb612, ^bb614
      %2809 = arith.cmpi slt, %2808, %1657 : i32
      cf.cond_br %2809, ^bb614, ^bb615 {llvm.loop_annotation = #loop_annotation}
    ^bb614:  // pred: ^bb613
      %2810 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_795) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<1>>) -> vector<32xi32>
      llvm.store %2810, %2807 : vector<32xi32>, !llvm.ptr
      %2811 = arith.addi %2808, %c1_i32 : i32
      cf.br ^bb613(%2811 : i32)
    ^bb615:  // pred: ^bb613
      cf.br ^bb616(%c0_i32 : i32)
    ^bb616(%2812: i32):  // 2 preds: ^bb615, ^bb617
      %2813 = arith.cmpi slt, %2812, %c32_i32 : i32
      cf.cond_br %2813, ^bb617, ^bb618 {loop_annotation = #loop_annotation1}
    ^bb617:  // pred: ^bb616
      %coord_802 = cute.make_coord(%2812) : (i32) -> !cute.coord<"?">
      %2814 = cute.memref.load(%rmem_800, %coord_802) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2815 = arith.addi %2812, %c1_i32 : i32
      %coord_803 = cute.make_coord(%2815) : (i32) -> !cute.coord<"?">
      %2816 = cute.memref.load(%rmem_800, %coord_803) : (!memref_rmem_f32_2, !cute.coord<"?">) -> f32
      %2817 = vector.from_elements %2814, %2816 : vector<2xf32>
      %2818 = nvvm.mul.packed.f32x2 %2817, %2802 {ftz = true, rnd = #nvvm.rnd<rz>} : vector<2xf32>, vector<2xf32> -> vector<2xf32>
      %2819 = vector.extract %2818[0] : f32 from vector<2xf32>
      %2820 = vector.extract %2818[1] : f32 from vector<2xf32>
      cute.memref.store(%rmem_800, %coord_802, %2819) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      cute.memref.store(%rmem_800, %coord_803, %2820) : (!memref_rmem_f32_2, !cute.coord<"?">, f32) -> ()
      %2821 = arith.addi %2812, %c2_i32 : i32
      cf.br ^bb616(%2821 : i32)
    ^bb618:  // pred: ^bb616
      %rmem_804 = cute.memref.alloca() : !memref_rmem_bf16_1
      %2822 = cute.memref.load_vec %rmem_800 : !memref_rmem_f32_2
      %2823 = arith.truncf %2822 : vector<32xf32> to vector<32xbf16>
      cute.memref.store_vec %2823, %rmem_804 : !memref_rmem_bf16_1
      %e0_805, %e1_806, %e2_807, %e3_808, %e4_809 = cute.get_leaves(%tup_799) : !cute.int_tuple<"(?,?{div=32},((?,?),?))">
      %coord_810 = cute.make_coord(%e0_805) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %2824 = cute.get_scalars(%coord_810) : !cute.coord<"?">
      %2825 = arith.cmpi slt, %2824, %1658 : i32
      cf.cond_br %2825, ^bb619, ^bb623
    ^bb619:  // pred: ^bb618
      %iter_811 = cute.get_iter(%rmem_804) : !memref_rmem_bf16_1
      %2826 = cute.get_scalars(%211) : !cute.int_tuple<"2">
      cf.br ^bb620(%c0_i32 : i32)
    ^bb620(%2827: i32):  // 2 preds: ^bb619, ^bb621
      %2828 = arith.cmpi slt, %2827, %2826 : i32
      cf.cond_br %2828, ^bb621, ^bb622 {llvm.loop_annotation = #loop_annotation}
    ^bb621:  // pred: ^bb620
      %coord_812 = cute.make_coord(%2827) : (i32) -> !cute.coord<"(_,?)">
      %idx_813 = cute.crd2idx(%coord_812, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_814 = cute.add_offset(%iter_811, %idx_813) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_815 = cute.add_offset(%ptr_797, %idx_813) : (!cute.ptr<bf16, gmem, align<64>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, gmem, align<32>>
      %2829 = builtin.unrealized_conversion_cast %ptr_814 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %2830 = builtin.unrealized_conversion_cast %ptr_815 : !cute.ptr<bf16, gmem, align<32>> to !llvm.ptr<1>
      %2831 = llvm.load %2829 {alignment = 32 : i64} : !llvm.ptr -> vector<16xbf16>
      llvm.store %2831, %2830 {alignment = 32 : i64} : vector<16xbf16>, !llvm.ptr<1>
      %2832 = arith.addi %2827, %c1_i32 : i32
      cf.br ^bb620(%2832 : i32)
    ^bb622:  // pred: ^bb620
      cf.br ^bb623
    ^bb623:  // 2 preds: ^bb618, ^bb622
      %2833 = arith.addi %2805, %c1_i32 : i32
      cf.br ^bb611(%2833 : i32)
    ^bb624:  // pred: ^bb611
      %2834 = arith.addi %2803, %c1_i32 : i32
      cf.br ^bb609(%2834 : i32)
    ^bb625:  // pred: ^bb609
      %ptr_816 = cute.add_offset(%ptr_115, %int_tuple_780) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2835 = builtin.unrealized_conversion_cast %ptr_816 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %2836 = nvvm.mapa.shared.cluster %2835, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2836, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.br ^bb547(%2211, %2212, %2213, %2214, %2215, %2216, %2797, %2799, %2801, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb626:  // pred: ^bb547
      %2837 = arith.addi %1663, %c1_i32 : i32
      %2838 = arith.cmpi eq, %2837, %c2_i32 : i32
      %2839 = arith.select %2838, %c0_i32, %2837 : i32
      cf.cond_br %2838, ^bb627, ^bb628
    ^bb627:  // pred: ^bb626
      %2840 = arith.xori %1664, %c1_i32 : i32
      cf.br ^bb629(%2840 : i32)
    ^bb628:  // pred: ^bb626
      cf.br ^bb629(%1664 : i32)
    ^bb629(%2841: i32):  // 2 preds: ^bb627, ^bb628
      cf.br ^bb630
    ^bb630:  // pred: ^bb629
      %int_tuple_817 = cute.make_int_tuple(%2839) : (i32) -> !cute.int_tuple<"?">
      %ptr_818 = cute.add_offset(%ptr_111, %int_tuple_817) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2842 = builtin.unrealized_conversion_cast %ptr_818 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2842, %2841, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %342, ^bb631, ^bb632
    ^bb631:  // pred: ^bb630
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb632
    ^bb632:  // 2 preds: ^bb630, ^bb631
      cf.cond_br %342, ^bb633, ^bb634
    ^bb633:  // pred: ^bb632
      %2843 = arith.xori %266, %c1_i32 : i32
      %2844 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      %2845 = nvvm.mapa.shared.cluster %2844, %2843 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %2845, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %2844, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb634
    ^bb634:  // 2 preds: ^bb632, ^bb633
      cf.br ^bb640(%1668 : i1)
    ^bb635:  // pred: ^bb539
      cf.cond_br %342, ^bb636, ^bb639
    ^bb636:  // pred: ^bb635
      %2846 = nvvm.elect.sync -> i1
      cf.cond_br %2846, ^bb637, ^bb638
    ^bb637:  // pred: ^bb636
      %2847 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %2847, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb638
    ^bb638:  // 2 preds: ^bb636, ^bb637
      cf.br ^bb639
    ^bb639:  // 2 preds: ^bb635, ^bb638
      nvvm.fence.mbarrier.init
      cf.br ^bb640(%1593 : i1)
    ^bb640(%2848: i1):  // 2 preds: ^bb634, ^bb639
      cf.br ^bb641
    ^bb641:  // pred: ^bb640
      cf.cond_br %342, ^bb642, ^bb645
    ^bb642:  // pred: ^bb641
      %2849 = nvvm.elect.sync -> i1
      cf.cond_br %2849, ^bb643, ^bb644
    ^bb643:  // pred: ^bb642
      %2850 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %2850, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb644
    ^bb644:  // 2 preds: ^bb642, ^bb643
      cf.br ^bb645
    ^bb645:  // 2 preds: ^bb641, ^bb644
      nvvm.fence.mbarrier.init
      %2851 = arith.cmpi slt, %244, %c8_i32 : i32
      cf.cond_br %2851, ^bb646, ^bb813
    ^bb646:  // pred: ^bb645
      nvvm.setmaxregister  decrease 112
      %int_tuple_819 = cute.make_int_tuple(%itup_286) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %2852 = cute.get_scalars(%int_tuple_819) <{only_dynamic}> : !cute.int_tuple<"?">
      %c1_i32_820 = arith.constant 1 : i32
      %c0_i32_821 = arith.constant 0 : i32
      %c-1_i32_822 = arith.constant -1 : i32
      %2853 = arith.cmpi sgt, %c256_i32, %c0_i32_821 : i32
      %2854 = arith.select %2853, %c-1_i32_822, %c1_i32_820 : i32
      %2855 = arith.addi %2854, %2852 : i32
      %2856 = arith.divsi %2855, %c256_i32 : i32
      %2857 = arith.addi %c1_i32_820, %2856 : i32
      %2858 = arith.subi %c0_i32_821, %2852 : i32
      %2859 = arith.divsi %2858, %c256_i32 : i32
      %2860 = arith.subi %c0_i32_821, %2859 : i32
      %2861 = arith.cmpi slt, %2852, %c0_i32_821 : i32
      %2862 = arith.cmpi sgt, %2852, %c0_i32_821 : i32
      %2863 = arith.cmpi slt, %c256_i32, %c0_i32_821 : i32
      %2864 = arith.cmpi sgt, %c256_i32, %c0_i32_821 : i32
      %2865 = arith.andi %2861, %2863 : i1
      %2866 = arith.andi %2862, %2864 : i1
      %2867 = arith.ori %2865, %2866 : i1
      %2868 = arith.select %2867, %2857, %2860 : i32
      %int_tuple_823 = cute.make_int_tuple(%2868) : (i32) -> !cute.int_tuple<"?">
      %e0_824 = cute.get_leaves(%int_tuple_823) : !cute.int_tuple<"?">
      %sub_825 = cute.tuple_sub(%e0_824, %222) : (!cute.int_tuple<"?">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
      %2869 = cute.get_scalars(%sub_825) : !cute.int_tuple<"?">
      %2870 = arith.remsi %225, %c256_i32 : i32
      %atom_826 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8, 32 b>
      %coord_827 = cute.make_coord(%2870) : (i32) -> !cute.coord<"?">
      %2871 = cute.get_scalars(%coord_827) <{only_dynamic}> : !cute.coord<"?">
      %2872 = arith.divsi %2871, %c4_i32 : i32
      %2873 = arith.remsi %2871, %c4_i32 : i32
      %2874 = arith.muli %2873, %c16_i32 : i32
      %2875 = arith.muli %2872, %c64_i32 : i32
      %2876 = arith.addi %2874, %2875 : i32
      %iv_828 = cute.assume(%2876) : (i32) -> !cute.i32<divby 16>
      %int_tuple_829 = cute.make_int_tuple(%iv_828) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_830 = cute.add_offset(%iter_135, %int_tuple_829) : (!cute.ptr<i8, smem, align<256>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %ptr_831 = cute.add_offset(%iter_121, %int_tuple_829) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %int_tuple_832 = cute.make_int_tuple(%2872) : (i32) -> !cute.int_tuple<"?">
      %ptr_833 = cute.add_offset(%iter_125, %int_tuple_832) : (!cute.ptr<bf16, smem, align<512>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2877 = cute.get_scalars(%149) : !cute.int_tuple<"16">
      %2878 = cute.get_scalars(%211) : !cute.int_tuple<"2">
      %swizzled_834 = cute.apply_swizzle(%ptr_830) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2879 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %swizzled_835 = cute.apply_swizzle(%ptr_830) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2880 = cute.get_scalars(%209) : !cute.int_tuple<"4">
      %swizzled_836 = cute.apply_swizzle(%ptr_830) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %swizzled_837 = cute.apply_swizzle(%ptr_830) : !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2881 = arith.divsi %2871, %c64_i32 : i32
      %2882 = arith.remsi %2871, %c64_i32 : i32
      %2883 = arith.muli %2882, %c16_i32 : i32
      %2884 = arith.muli %2881, %c1024_i32 : i32
      %2885 = arith.addi %2883, %2884 : i32
      %iv_838 = cute.assume(%2885) : (i32) -> !cute.i32<divby 16>
      %int_tuple_839 = cute.make_int_tuple(%iv_838) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_840 = cute.add_offset(%iter_136, %int_tuple_839) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_841 = cute.add_offset(%iter_122, %int_tuple_839) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2886 = arith.divsi %2882, %c4_i32 : i32
      %2887 = arith.muli %2881, %c16_i32 : i32
      %2888 = arith.addi %2886, %2887 : i32
      %int_tuple_842 = cute.make_int_tuple(%2888) : (i32) -> !cute.int_tuple<"?">
      %ptr_843 = cute.add_offset(%iter_128, %int_tuple_842) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2889 = cute.get_scalars(%5) : !cute.int_tuple<"32">
      %2890 = arith.divsi %2871, %c64_i32 : i32
      %2891 = arith.remsi %2871, %c64_i32 : i32
      %2892 = arith.muli %2891, %c16_i32 : i32
      %2893 = arith.muli %2890, %c1024_i32 : i32
      %2894 = arith.addi %2892, %2893 : i32
      %iv_844 = cute.assume(%2894) : (i32) -> !cute.i32<divby 16>
      %int_tuple_845 = cute.make_int_tuple(%iv_844) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_846 = cute.add_offset(%iter_136, %int_tuple_845) : (!cute.ptr<i8, smem, align<256>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_847 = cute.add_offset(%iter_122, %int_tuple_845) : (!cute.ptr<bf16, smem, align<512>, S<3,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<bf16, smem, align<32>, S<3,4,3>>
      %2895 = arith.divsi %2891, %c4_i32 : i32
      %2896 = arith.muli %2890, %c16_i32 : i32
      %2897 = arith.addi %2895, %2896 : i32
      %int_tuple_848 = cute.make_int_tuple(%2897) : (i32) -> !cute.int_tuple<"?">
      %ptr_849 = cute.add_offset(%iter_128, %int_tuple_848) : (!cute.ptr<bf16, smem, align<256>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %2898 = cute.get_scalars(%5) : !cute.int_tuple<"32">
      cf.br ^bb647(%c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %2848 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb647(%2899: i32, %2900: i32, %2901: i32, %2902: i32, %2903: i32, %2904: i32, %2905: i32, %2906: i32, %2907: i32, %2908: i32, %2909: i32, %2910: i32, %2911: i1):  // 2 preds: ^bb646, ^bb803
      cf.cond_br %2911, ^bb648(%2899, %2900, %2901, %2902, %2903, %2904, %2905, %2906, %2907, %2908, %2909, %2910 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32), ^bb804
    ^bb648(%2912: i32, %2913: i32, %2914: i32, %2915: i32, %2916: i32, %2917: i32, %2918: i32, %2919: i32, %2920: i32, %2921: i32, %2922: i32, %2923: i32):  // pred: ^bb647
      %2924 = cute.make_tiled_copy(%atom_826) : !copy_simt1
      %rmem_850 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_851 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_852 = cute.memref.alloca() : !memref_rmem_bf16_3
      %int_tuple_853 = cute.make_int_tuple(%2916) : (i32) -> !cute.int_tuple<"?">
      %ptr_854 = cute.add_offset(%iter_61, %int_tuple_853) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2925 = builtin.unrealized_conversion_cast %ptr_854 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2925, %2917, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2926 = arith.addi %2916, %c1_i32 : i32
      %2927 = arith.addi %2915, %c1_i32 : i32
      %2928 = arith.cmpi eq, %2926, %c5_i32 : i32
      %2929 = arith.select %2928, %c0_i32, %2926 : i32
      cf.cond_br %2928, ^bb649, ^bb650
    ^bb649:  // pred: ^bb648
      %2930 = arith.xori %2917, %c1_i32 : i32
      cf.br ^bb651(%2930 : i32)
    ^bb650:  // pred: ^bb648
      cf.br ^bb651(%2917 : i32)
    ^bb651(%2931: i32):  // 2 preds: ^bb649, ^bb650
      cf.br ^bb652
    ^bb652:  // pred: ^bb651
      %coord_855 = cute.make_coord(%2916) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_856 = cute.crd2idx(%coord_855, %14) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,(8,1),5):((0,0),64,0,0,(0,1),128)">) -> !cute.int_tuple<"?{div=128}">
      %iter_857 = cute.get_iter(%rmem_852) : !memref_rmem_bf16_3
      cf.br ^bb653(%c0_i32 : i32)
    ^bb653(%2932: i32):  // 2 preds: ^bb652, ^bb654
      %2933 = arith.cmpi slt, %2932, %2877 : i32
      cf.cond_br %2933, ^bb654, ^bb655 {llvm.loop_annotation = #loop_annotation}
    ^bb654:  // pred: ^bb653
      %coord_858 = cute.make_coord(%2932) : (i32) -> !cute.coord<"(_,?)">
      %idx_859 = cute.crd2idx(%coord_858, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(64,0,0,(0,1)))">) -> !cute.int_tuple<"?">
      %ptr_860 = cute.add_offset(%ptr_833, %idx_859) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_861 = cute.add_offset(%ptr_860, %idx_856) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem>
      %idx_862 = cute.crd2idx(%coord_858, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(1,0,0,(0,0)))">) -> !cute.int_tuple<"?">
      %ptr_863 = cute.add_offset(%iter_857, %idx_862) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %2934 = builtin.unrealized_conversion_cast %ptr_861 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %2935 = builtin.unrealized_conversion_cast %ptr_863 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %2936 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2936, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2937 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2937, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2938 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2938, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2939 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2939, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2940 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2940, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2941 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2941, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2942 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2942, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2943 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2943, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2944 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2944, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2945 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2945, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2946 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2946, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2947 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2947, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2948 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2948, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2949 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2949, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2950 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2950, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2951 = llvm.load %2934 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %2951, %2935 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %2952 = arith.addi %2932, %c1_i32 : i32
      cf.br ^bb653(%2952 : i32)
    ^bb655:  // pred: ^bb653
      %int_tuple_864 = cute.make_int_tuple(%2913) : (i32) -> !cute.int_tuple<"?">
      %ptr_865 = cute.add_offset(%iter_46, %int_tuple_864) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %2953 = builtin.unrealized_conversion_cast %ptr_865 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %2953, %2914, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %2954 = arith.addi %2913, %c1_i32 : i32
      %2955 = arith.addi %2912, %c1_i32 : i32
      %2956 = arith.cmpi eq, %2954, %c5_i32 : i32
      %2957 = arith.select %2956, %c0_i32, %2954 : i32
      cf.cond_br %2956, ^bb656, ^bb657
    ^bb656:  // pred: ^bb655
      %2958 = arith.xori %2914, %c1_i32 : i32
      cf.br ^bb658(%2958 : i32)
    ^bb657:  // pred: ^bb655
      cf.br ^bb658(%2914 : i32)
    ^bb658(%2959: i32):  // 2 preds: ^bb656, ^bb657
      cf.br ^bb659
    ^bb659:  // pred: ^bb658
      %coord_866 = cute.make_coord(%2913) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_867 = cute.crd2idx(%coord_866, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %iter_868 = cute.get_iter(%rmem_850) : !memref_rmem_i8_
      %ptr_869 = cute.add_offset(%swizzled_834, %idx_867) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb660(%c0_i32 : i32)
    ^bb660(%2960: i32):  // 2 preds: ^bb659, ^bb661
      %2961 = arith.cmpi slt, %2960, %2878 : i32
      cf.cond_br %2961, ^bb661, ^bb662 {llvm.loop_annotation = #loop_annotation}
    ^bb661:  // pred: ^bb660
      %coord_870 = cute.make_coord(%2960) : (i32) -> !cute.coord<"(_,?)">
      %idx_871 = cute.crd2idx(%coord_870, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_872 = cute.crd2idx(%coord_870, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_873 = cute.add_offset(%iter_868, %idx_872) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_874 = cute.add_offset(%ptr_869, %idx_871) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %2962 = builtin.unrealized_conversion_cast %ptr_874 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %2963 = builtin.unrealized_conversion_cast %ptr_873 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %2964 = llvm.load %2962 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %2964, %2963 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %2965 = arith.addi %2960, %c1_i32 : i32
      cf.br ^bb660(%2965 : i32)
    ^bb662:  // pred: ^bb660
      %view_875 = cute.make_view(%iter_868) : !memref_rmem_i8_1
      %2966 = cute.memref.load_vec %view_875 : !memref_rmem_i8_1
      %2967 = vector.extract_strided_slice %2966 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2968 = llvm.bitcast %2967 : vector<4xi8> to i32
      %2969 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2968, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2970 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2968, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2971 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2968, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2972 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2968, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2973 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2969 : (i32) -> f32
      %2974 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2970 : (i32) -> f32
      %2975 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2971 : (i32) -> f32
      %2976 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2972 : (i32) -> f32
      %2977 = vector.from_elements %2973, %2974, %2975, %2976 : vector<4xf32>
      %2978 = vector.extract_strided_slice %2977 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2979 = vector.extract_strided_slice %2977 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %2980 = vector.extractelement %2978[%c0_i32 : i32] : vector<2xf32>
      %2981 = vector.extractelement %2978[%c1_i32 : i32] : vector<2xf32>
      %2982 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2981, %2980 : (f32, f32) -> i32
      %2983 = llvm.bitcast %2982 : i32 to vector<2xbf16>
      %2984 = vector.extractelement %2979[%c0_i32 : i32] : vector<2xf32>
      %2985 = vector.extractelement %2979[%c1_i32 : i32] : vector<2xf32>
      %2986 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %2985, %2984 : (f32, f32) -> i32
      %2987 = llvm.bitcast %2986 : i32 to vector<2xbf16>
      %2988 = vector.insert_strided_slice %2983, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2989 = vector.insert_strided_slice %2987, %2988 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %2990 = vector.extract_strided_slice %2966 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %2991 = llvm.bitcast %2990 : vector<4xi8> to i32
      %2992 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2991, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2993 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2991, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2994 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2991, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2995 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %2991, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %2996 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2992 : (i32) -> f32
      %2997 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2993 : (i32) -> f32
      %2998 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2994 : (i32) -> f32
      %2999 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %2995 : (i32) -> f32
      %3000 = vector.from_elements %2996, %2997, %2998, %2999 : vector<4xf32>
      %3001 = vector.extract_strided_slice %3000 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3002 = vector.extract_strided_slice %3000 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3003 = vector.extractelement %3001[%c0_i32 : i32] : vector<2xf32>
      %3004 = vector.extractelement %3001[%c1_i32 : i32] : vector<2xf32>
      %3005 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3004, %3003 : (f32, f32) -> i32
      %3006 = llvm.bitcast %3005 : i32 to vector<2xbf16>
      %3007 = vector.extractelement %3002[%c0_i32 : i32] : vector<2xf32>
      %3008 = vector.extractelement %3002[%c1_i32 : i32] : vector<2xf32>
      %3009 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3008, %3007 : (f32, f32) -> i32
      %3010 = llvm.bitcast %3009 : i32 to vector<2xbf16>
      %3011 = vector.insert_strided_slice %3006, %2989 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3012 = vector.insert_strided_slice %3010, %3011 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3013 = vector.extract_strided_slice %2966 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3014 = llvm.bitcast %3013 : vector<4xi8> to i32
      %3015 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3014, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3016 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3014, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3017 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3014, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3018 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3014, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3019 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3015 : (i32) -> f32
      %3020 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3016 : (i32) -> f32
      %3021 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3017 : (i32) -> f32
      %3022 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3018 : (i32) -> f32
      %3023 = vector.from_elements %3019, %3020, %3021, %3022 : vector<4xf32>
      %3024 = vector.extract_strided_slice %3023 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3025 = vector.extract_strided_slice %3023 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3026 = vector.extractelement %3024[%c0_i32 : i32] : vector<2xf32>
      %3027 = vector.extractelement %3024[%c1_i32 : i32] : vector<2xf32>
      %3028 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3027, %3026 : (f32, f32) -> i32
      %3029 = llvm.bitcast %3028 : i32 to vector<2xbf16>
      %3030 = vector.extractelement %3025[%c0_i32 : i32] : vector<2xf32>
      %3031 = vector.extractelement %3025[%c1_i32 : i32] : vector<2xf32>
      %3032 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3031, %3030 : (f32, f32) -> i32
      %3033 = llvm.bitcast %3032 : i32 to vector<2xbf16>
      %3034 = vector.insert_strided_slice %3029, %3012 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3035 = vector.insert_strided_slice %3033, %3034 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3036 = vector.extract_strided_slice %2966 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3037 = llvm.bitcast %3036 : vector<4xi8> to i32
      %3038 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3037, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3039 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3037, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3040 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3037, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3041 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3037, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3042 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3038 : (i32) -> f32
      %3043 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3039 : (i32) -> f32
      %3044 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3040 : (i32) -> f32
      %3045 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3041 : (i32) -> f32
      %3046 = vector.from_elements %3042, %3043, %3044, %3045 : vector<4xf32>
      %3047 = vector.extract_strided_slice %3046 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3048 = vector.extract_strided_slice %3046 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3049 = vector.extractelement %3047[%c0_i32 : i32] : vector<2xf32>
      %3050 = vector.extractelement %3047[%c1_i32 : i32] : vector<2xf32>
      %3051 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3050, %3049 : (f32, f32) -> i32
      %3052 = llvm.bitcast %3051 : i32 to vector<2xbf16>
      %3053 = vector.extractelement %3048[%c0_i32 : i32] : vector<2xf32>
      %3054 = vector.extractelement %3048[%c1_i32 : i32] : vector<2xf32>
      %3055 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3054, %3053 : (f32, f32) -> i32
      %3056 = llvm.bitcast %3055 : i32 to vector<2xbf16>
      %3057 = vector.insert_strided_slice %3052, %3035 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3058 = vector.insert_strided_slice %3056, %3057 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3059 = vector.extract_strided_slice %2966 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3060 = llvm.bitcast %3059 : vector<4xi8> to i32
      %3061 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3060, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3062 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3060, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3063 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3060, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3064 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3060, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3065 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3061 : (i32) -> f32
      %3066 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3062 : (i32) -> f32
      %3067 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3063 : (i32) -> f32
      %3068 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3064 : (i32) -> f32
      %3069 = vector.from_elements %3065, %3066, %3067, %3068 : vector<4xf32>
      %3070 = vector.extract_strided_slice %3069 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3071 = vector.extract_strided_slice %3069 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3072 = vector.extractelement %3070[%c0_i32 : i32] : vector<2xf32>
      %3073 = vector.extractelement %3070[%c1_i32 : i32] : vector<2xf32>
      %3074 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3073, %3072 : (f32, f32) -> i32
      %3075 = llvm.bitcast %3074 : i32 to vector<2xbf16>
      %3076 = vector.extractelement %3071[%c0_i32 : i32] : vector<2xf32>
      %3077 = vector.extractelement %3071[%c1_i32 : i32] : vector<2xf32>
      %3078 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3077, %3076 : (f32, f32) -> i32
      %3079 = llvm.bitcast %3078 : i32 to vector<2xbf16>
      %3080 = vector.insert_strided_slice %3075, %3058 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3081 = vector.insert_strided_slice %3079, %3080 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3082 = vector.extract_strided_slice %2966 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3083 = llvm.bitcast %3082 : vector<4xi8> to i32
      %3084 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3083, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3085 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3083, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3086 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3083, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3087 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3083, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3088 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3084 : (i32) -> f32
      %3089 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3085 : (i32) -> f32
      %3090 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3086 : (i32) -> f32
      %3091 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3087 : (i32) -> f32
      %3092 = vector.from_elements %3088, %3089, %3090, %3091 : vector<4xf32>
      %3093 = vector.extract_strided_slice %3092 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3094 = vector.extract_strided_slice %3092 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3095 = vector.extractelement %3093[%c0_i32 : i32] : vector<2xf32>
      %3096 = vector.extractelement %3093[%c1_i32 : i32] : vector<2xf32>
      %3097 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3096, %3095 : (f32, f32) -> i32
      %3098 = llvm.bitcast %3097 : i32 to vector<2xbf16>
      %3099 = vector.extractelement %3094[%c0_i32 : i32] : vector<2xf32>
      %3100 = vector.extractelement %3094[%c1_i32 : i32] : vector<2xf32>
      %3101 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3100, %3099 : (f32, f32) -> i32
      %3102 = llvm.bitcast %3101 : i32 to vector<2xbf16>
      %3103 = vector.insert_strided_slice %3098, %3081 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3104 = vector.insert_strided_slice %3102, %3103 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3105 = vector.extract_strided_slice %2966 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3106 = llvm.bitcast %3105 : vector<4xi8> to i32
      %3107 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3106, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3108 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3106, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3109 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3106, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3110 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3106, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3111 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3107 : (i32) -> f32
      %3112 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3108 : (i32) -> f32
      %3113 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3109 : (i32) -> f32
      %3114 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3110 : (i32) -> f32
      %3115 = vector.from_elements %3111, %3112, %3113, %3114 : vector<4xf32>
      %3116 = vector.extract_strided_slice %3115 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3117 = vector.extract_strided_slice %3115 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3118 = vector.extractelement %3116[%c0_i32 : i32] : vector<2xf32>
      %3119 = vector.extractelement %3116[%c1_i32 : i32] : vector<2xf32>
      %3120 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3119, %3118 : (f32, f32) -> i32
      %3121 = llvm.bitcast %3120 : i32 to vector<2xbf16>
      %3122 = vector.extractelement %3117[%c0_i32 : i32] : vector<2xf32>
      %3123 = vector.extractelement %3117[%c1_i32 : i32] : vector<2xf32>
      %3124 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3123, %3122 : (f32, f32) -> i32
      %3125 = llvm.bitcast %3124 : i32 to vector<2xbf16>
      %3126 = vector.insert_strided_slice %3121, %3104 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3127 = vector.insert_strided_slice %3125, %3126 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3128 = vector.extract_strided_slice %2966 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3129 = llvm.bitcast %3128 : vector<4xi8> to i32
      %3130 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3129, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3131 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3129, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3132 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3129, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3133 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3129, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3134 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3130 : (i32) -> f32
      %3135 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3131 : (i32) -> f32
      %3136 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3132 : (i32) -> f32
      %3137 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3133 : (i32) -> f32
      %3138 = vector.from_elements %3134, %3135, %3136, %3137 : vector<4xf32>
      %3139 = vector.extract_strided_slice %3138 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3140 = vector.extract_strided_slice %3138 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3141 = vector.extractelement %3139[%c0_i32 : i32] : vector<2xf32>
      %3142 = vector.extractelement %3139[%c1_i32 : i32] : vector<2xf32>
      %3143 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3142, %3141 : (f32, f32) -> i32
      %3144 = llvm.bitcast %3143 : i32 to vector<2xbf16>
      %3145 = vector.extractelement %3140[%c0_i32 : i32] : vector<2xf32>
      %3146 = vector.extractelement %3140[%c1_i32 : i32] : vector<2xf32>
      %3147 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3146, %3145 : (f32, f32) -> i32
      %3148 = llvm.bitcast %3147 : i32 to vector<2xbf16>
      %3149 = vector.insert_strided_slice %3144, %3127 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3150 = vector.insert_strided_slice %3148, %3149 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_876 = cute.make_view(%iter_857) : !memref_rmem_bf16_4
      %3151 = cute.memref.load_vec %view_876 : !memref_rmem_bf16_4
      %3152 = arith.mulf %3150, %3151 : vector<32xbf16>
      %iter_877 = cute.get_iter(%rmem_851) : !memref_rmem_bf16_2
      %view_878 = cute.make_view(%iter_877) : !memref_rmem_bf16_5
      cute.memref.store_vec %3152, %view_878 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_879 = cute.add_offset(%ptr_51, %int_tuple_864) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3153 = builtin.unrealized_conversion_cast %ptr_879 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3153, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb663(%c1_i32, %2918, %2919, %2920, %2955, %2957, %2959 : i32, i32, i32, i32, i32, i32, i32)
    ^bb663(%3154: i32, %3155: i32, %3156: i32, %3157: i32, %3158: i32, %3159: i32, %3160: i32):  // 2 preds: ^bb662, ^bb678
      %3161 = arith.cmpi slt, %3154, %c8_i32 : i32
      cf.cond_br %3161, ^bb664, ^bb679 {loop_annotation = #loop_annotation1}
    ^bb664:  // pred: ^bb663
      %int_tuple_880 = cute.make_int_tuple(%3156) : (i32) -> !cute.int_tuple<"?">
      %ptr_881 = cute.add_offset(%ptr_96, %int_tuple_880) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3162 = builtin.unrealized_conversion_cast %ptr_881 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3162, %3157, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3163 = arith.addi %3156, %c1_i32 : i32
      %3164 = arith.addi %3155, %c1_i32 : i32
      %3165 = arith.cmpi eq, %3163, %c3_i32 : i32
      %3166 = arith.select %3165, %c0_i32, %3163 : i32
      cf.cond_br %3165, ^bb665, ^bb666
    ^bb665:  // pred: ^bb664
      %3167 = arith.xori %3157, %c1_i32 : i32
      cf.br ^bb667(%3167 : i32)
    ^bb666:  // pred: ^bb664
      cf.br ^bb667(%3157 : i32)
    ^bb667(%3168: i32):  // 2 preds: ^bb665, ^bb666
      cf.br ^bb668
    ^bb668:  // pred: ^bb667
      %3169 = arith.subi %3154, %c1_i32 : i32
      %3170 = arith.remsi %3169, %c2_i32 : i32
      %coord_882 = cute.make_coord(%3170) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_883 = cute.crd2idx(%coord_882, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_884 = cute.add_offset(%iter_877, %idx_883) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_885 = cute.make_coord(%3156) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_886 = cute.crd2idx(%coord_885, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb669(%c0_i32 : i32)
    ^bb669(%3171: i32):  // 2 preds: ^bb668, ^bb670
      %3172 = arith.cmpi slt, %3171, %2879 : i32
      cf.cond_br %3172, ^bb670, ^bb671 {llvm.loop_annotation = #loop_annotation}
    ^bb670:  // pred: ^bb669
      %coord_887 = cute.make_coord(%3171) : (i32) -> !cute.coord<"(_,?)">
      %idx_888 = cute.crd2idx(%coord_887, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_889 = cute.add_offset(%ptr_884, %idx_888) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_890 = cute.crd2idx(%coord_887, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_891 = cute.add_offset(%ptr_831, %idx_890) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_892 = cute.apply_swizzle(%ptr_891) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_893 = cute.add_offset(%swizzled_892, %idx_886) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3173 = builtin.unrealized_conversion_cast %ptr_889 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3174 = builtin.unrealized_conversion_cast %ptr_893 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3175 = llvm.load %3173 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3175, %3174 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3176 = arith.addi %3171, %c1_i32 : i32
      cf.br ^bb669(%3176 : i32)
    ^bb671:  // pred: ^bb669
      %int_tuple_894 = cute.make_int_tuple(%3159) : (i32) -> !cute.int_tuple<"?">
      %ptr_895 = cute.add_offset(%iter_46, %int_tuple_894) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3177 = builtin.unrealized_conversion_cast %ptr_895 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3177, %3160, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3178 = arith.addi %3159, %c1_i32 : i32
      %3179 = arith.addi %3158, %c1_i32 : i32
      %3180 = arith.cmpi eq, %3178, %c5_i32 : i32
      %3181 = arith.select %3180, %c0_i32, %3178 : i32
      cf.cond_br %3180, ^bb672, ^bb673
    ^bb672:  // pred: ^bb671
      %3182 = arith.xori %3160, %c1_i32 : i32
      cf.br ^bb674(%3182 : i32)
    ^bb673:  // pred: ^bb671
      cf.br ^bb674(%3160 : i32)
    ^bb674(%3183: i32):  // 2 preds: ^bb672, ^bb673
      cf.br ^bb675
    ^bb675:  // pred: ^bb674
      %coord_896 = cute.make_coord(%3159) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_897 = cute.crd2idx(%coord_896, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %3184 = arith.remsi %3154, %c2_i32 : i32
      %coord_898 = cute.make_coord(%3184) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_899 = cute.crd2idx(%coord_898, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_900 = cute.add_offset(%iter_868, %idx_899) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      %ptr_901 = cute.add_offset(%swizzled_835, %idx_897) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb676(%c0_i32 : i32)
    ^bb676(%3185: i32):  // 2 preds: ^bb675, ^bb677
      %3186 = arith.cmpi slt, %3185, %2878 : i32
      cf.cond_br %3186, ^bb677, ^bb678 {llvm.loop_annotation = #loop_annotation}
    ^bb677:  // pred: ^bb676
      %coord_902 = cute.make_coord(%3185) : (i32) -> !cute.coord<"(_,?)">
      %idx_903 = cute.crd2idx(%coord_902, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_904 = cute.crd2idx(%coord_902, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_905 = cute.add_offset(%ptr_900, %idx_904) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_906 = cute.add_offset(%ptr_901, %idx_903) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %3187 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %3188 = builtin.unrealized_conversion_cast %ptr_905 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3189 = llvm.load %3187 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3189, %3188 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3190 = arith.addi %3185, %c1_i32 : i32
      cf.br ^bb676(%3190 : i32)
    ^bb678:  // pred: ^bb676
      %view_907 = cute.make_view(%ptr_900) : !memref_rmem_i8_1
      %3191 = cute.memref.load_vec %view_907 : !memref_rmem_i8_1
      %3192 = vector.extract_strided_slice %3191 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3193 = llvm.bitcast %3192 : vector<4xi8> to i32
      %3194 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3193, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3195 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3193, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3196 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3193, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3197 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3193, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3198 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3194 : (i32) -> f32
      %3199 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3195 : (i32) -> f32
      %3200 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3196 : (i32) -> f32
      %3201 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3197 : (i32) -> f32
      %3202 = vector.from_elements %3198, %3199, %3200, %3201 : vector<4xf32>
      %3203 = vector.extract_strided_slice %3202 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3204 = vector.extract_strided_slice %3202 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3205 = vector.extractelement %3203[%c0_i32 : i32] : vector<2xf32>
      %3206 = vector.extractelement %3203[%c1_i32 : i32] : vector<2xf32>
      %3207 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3206, %3205 : (f32, f32) -> i32
      %3208 = llvm.bitcast %3207 : i32 to vector<2xbf16>
      %3209 = vector.extractelement %3204[%c0_i32 : i32] : vector<2xf32>
      %3210 = vector.extractelement %3204[%c1_i32 : i32] : vector<2xf32>
      %3211 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3210, %3209 : (f32, f32) -> i32
      %3212 = llvm.bitcast %3211 : i32 to vector<2xbf16>
      %3213 = vector.insert_strided_slice %3208, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3214 = vector.insert_strided_slice %3212, %3213 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3215 = vector.extract_strided_slice %3191 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3216 = llvm.bitcast %3215 : vector<4xi8> to i32
      %3217 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3216, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3218 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3216, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3219 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3216, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3220 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3216, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3221 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3217 : (i32) -> f32
      %3222 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3218 : (i32) -> f32
      %3223 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3219 : (i32) -> f32
      %3224 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3220 : (i32) -> f32
      %3225 = vector.from_elements %3221, %3222, %3223, %3224 : vector<4xf32>
      %3226 = vector.extract_strided_slice %3225 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3227 = vector.extract_strided_slice %3225 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3228 = vector.extractelement %3226[%c0_i32 : i32] : vector<2xf32>
      %3229 = vector.extractelement %3226[%c1_i32 : i32] : vector<2xf32>
      %3230 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3229, %3228 : (f32, f32) -> i32
      %3231 = llvm.bitcast %3230 : i32 to vector<2xbf16>
      %3232 = vector.extractelement %3227[%c0_i32 : i32] : vector<2xf32>
      %3233 = vector.extractelement %3227[%c1_i32 : i32] : vector<2xf32>
      %3234 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3233, %3232 : (f32, f32) -> i32
      %3235 = llvm.bitcast %3234 : i32 to vector<2xbf16>
      %3236 = vector.insert_strided_slice %3231, %3214 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3237 = vector.insert_strided_slice %3235, %3236 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3238 = vector.extract_strided_slice %3191 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3239 = llvm.bitcast %3238 : vector<4xi8> to i32
      %3240 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3239, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3241 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3239, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3242 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3239, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3243 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3239, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3244 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3240 : (i32) -> f32
      %3245 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3241 : (i32) -> f32
      %3246 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3242 : (i32) -> f32
      %3247 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3243 : (i32) -> f32
      %3248 = vector.from_elements %3244, %3245, %3246, %3247 : vector<4xf32>
      %3249 = vector.extract_strided_slice %3248 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3250 = vector.extract_strided_slice %3248 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3251 = vector.extractelement %3249[%c0_i32 : i32] : vector<2xf32>
      %3252 = vector.extractelement %3249[%c1_i32 : i32] : vector<2xf32>
      %3253 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3252, %3251 : (f32, f32) -> i32
      %3254 = llvm.bitcast %3253 : i32 to vector<2xbf16>
      %3255 = vector.extractelement %3250[%c0_i32 : i32] : vector<2xf32>
      %3256 = vector.extractelement %3250[%c1_i32 : i32] : vector<2xf32>
      %3257 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3256, %3255 : (f32, f32) -> i32
      %3258 = llvm.bitcast %3257 : i32 to vector<2xbf16>
      %3259 = vector.insert_strided_slice %3254, %3237 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3260 = vector.insert_strided_slice %3258, %3259 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3261 = vector.extract_strided_slice %3191 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3262 = llvm.bitcast %3261 : vector<4xi8> to i32
      %3263 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3262, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3264 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3262, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3265 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3262, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3266 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3262, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3267 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3263 : (i32) -> f32
      %3268 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3264 : (i32) -> f32
      %3269 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3265 : (i32) -> f32
      %3270 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3266 : (i32) -> f32
      %3271 = vector.from_elements %3267, %3268, %3269, %3270 : vector<4xf32>
      %3272 = vector.extract_strided_slice %3271 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3273 = vector.extract_strided_slice %3271 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3274 = vector.extractelement %3272[%c0_i32 : i32] : vector<2xf32>
      %3275 = vector.extractelement %3272[%c1_i32 : i32] : vector<2xf32>
      %3276 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3275, %3274 : (f32, f32) -> i32
      %3277 = llvm.bitcast %3276 : i32 to vector<2xbf16>
      %3278 = vector.extractelement %3273[%c0_i32 : i32] : vector<2xf32>
      %3279 = vector.extractelement %3273[%c1_i32 : i32] : vector<2xf32>
      %3280 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3279, %3278 : (f32, f32) -> i32
      %3281 = llvm.bitcast %3280 : i32 to vector<2xbf16>
      %3282 = vector.insert_strided_slice %3277, %3260 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3283 = vector.insert_strided_slice %3281, %3282 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3284 = vector.extract_strided_slice %3191 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3285 = llvm.bitcast %3284 : vector<4xi8> to i32
      %3286 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3285, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3287 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3285, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3288 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3285, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3289 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3285, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3290 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3286 : (i32) -> f32
      %3291 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3287 : (i32) -> f32
      %3292 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3288 : (i32) -> f32
      %3293 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3289 : (i32) -> f32
      %3294 = vector.from_elements %3290, %3291, %3292, %3293 : vector<4xf32>
      %3295 = vector.extract_strided_slice %3294 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3296 = vector.extract_strided_slice %3294 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3297 = vector.extractelement %3295[%c0_i32 : i32] : vector<2xf32>
      %3298 = vector.extractelement %3295[%c1_i32 : i32] : vector<2xf32>
      %3299 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3298, %3297 : (f32, f32) -> i32
      %3300 = llvm.bitcast %3299 : i32 to vector<2xbf16>
      %3301 = vector.extractelement %3296[%c0_i32 : i32] : vector<2xf32>
      %3302 = vector.extractelement %3296[%c1_i32 : i32] : vector<2xf32>
      %3303 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3302, %3301 : (f32, f32) -> i32
      %3304 = llvm.bitcast %3303 : i32 to vector<2xbf16>
      %3305 = vector.insert_strided_slice %3300, %3283 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3306 = vector.insert_strided_slice %3304, %3305 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3307 = vector.extract_strided_slice %3191 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3308 = llvm.bitcast %3307 : vector<4xi8> to i32
      %3309 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3308, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3310 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3308, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3311 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3308, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3312 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3308, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3313 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3309 : (i32) -> f32
      %3314 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3310 : (i32) -> f32
      %3315 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3311 : (i32) -> f32
      %3316 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3312 : (i32) -> f32
      %3317 = vector.from_elements %3313, %3314, %3315, %3316 : vector<4xf32>
      %3318 = vector.extract_strided_slice %3317 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3319 = vector.extract_strided_slice %3317 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3320 = vector.extractelement %3318[%c0_i32 : i32] : vector<2xf32>
      %3321 = vector.extractelement %3318[%c1_i32 : i32] : vector<2xf32>
      %3322 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3321, %3320 : (f32, f32) -> i32
      %3323 = llvm.bitcast %3322 : i32 to vector<2xbf16>
      %3324 = vector.extractelement %3319[%c0_i32 : i32] : vector<2xf32>
      %3325 = vector.extractelement %3319[%c1_i32 : i32] : vector<2xf32>
      %3326 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3325, %3324 : (f32, f32) -> i32
      %3327 = llvm.bitcast %3326 : i32 to vector<2xbf16>
      %3328 = vector.insert_strided_slice %3323, %3306 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3329 = vector.insert_strided_slice %3327, %3328 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3330 = vector.extract_strided_slice %3191 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3331 = llvm.bitcast %3330 : vector<4xi8> to i32
      %3332 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3331, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3333 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3331, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3334 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3331, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3335 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3331, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3336 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3332 : (i32) -> f32
      %3337 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3333 : (i32) -> f32
      %3338 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3334 : (i32) -> f32
      %3339 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3335 : (i32) -> f32
      %3340 = vector.from_elements %3336, %3337, %3338, %3339 : vector<4xf32>
      %3341 = vector.extract_strided_slice %3340 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3342 = vector.extract_strided_slice %3340 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3343 = vector.extractelement %3341[%c0_i32 : i32] : vector<2xf32>
      %3344 = vector.extractelement %3341[%c1_i32 : i32] : vector<2xf32>
      %3345 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3344, %3343 : (f32, f32) -> i32
      %3346 = llvm.bitcast %3345 : i32 to vector<2xbf16>
      %3347 = vector.extractelement %3342[%c0_i32 : i32] : vector<2xf32>
      %3348 = vector.extractelement %3342[%c1_i32 : i32] : vector<2xf32>
      %3349 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3348, %3347 : (f32, f32) -> i32
      %3350 = llvm.bitcast %3349 : i32 to vector<2xbf16>
      %3351 = vector.insert_strided_slice %3346, %3329 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3352 = vector.insert_strided_slice %3350, %3351 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3353 = vector.extract_strided_slice %3191 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3354 = llvm.bitcast %3353 : vector<4xi8> to i32
      %3355 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3354, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3356 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3354, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3357 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3354, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3358 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3354, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3359 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3355 : (i32) -> f32
      %3360 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3356 : (i32) -> f32
      %3361 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3357 : (i32) -> f32
      %3362 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3358 : (i32) -> f32
      %3363 = vector.from_elements %3359, %3360, %3361, %3362 : vector<4xf32>
      %3364 = vector.extract_strided_slice %3363 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3365 = vector.extract_strided_slice %3363 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3366 = vector.extractelement %3364[%c0_i32 : i32] : vector<2xf32>
      %3367 = vector.extractelement %3364[%c1_i32 : i32] : vector<2xf32>
      %3368 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3367, %3366 : (f32, f32) -> i32
      %3369 = llvm.bitcast %3368 : i32 to vector<2xbf16>
      %3370 = vector.extractelement %3365[%c0_i32 : i32] : vector<2xf32>
      %3371 = vector.extractelement %3365[%c1_i32 : i32] : vector<2xf32>
      %3372 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3371, %3370 : (f32, f32) -> i32
      %3373 = llvm.bitcast %3372 : i32 to vector<2xbf16>
      %3374 = vector.insert_strided_slice %3369, %3352 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3375 = vector.insert_strided_slice %3373, %3374 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3376 = cute.memref.load_vec %view_876 : !memref_rmem_bf16_4
      %3377 = arith.mulf %3375, %3376 : vector<32xbf16>
      %ptr_908 = cute.add_offset(%iter_877, %idx_899) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_909 = cute.make_view(%ptr_908) : !memref_rmem_bf16_5
      cute.memref.store_vec %3377, %view_909 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_910 = cute.add_offset(%ptr_51, %int_tuple_894) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3378 = builtin.unrealized_conversion_cast %ptr_910 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3378, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_911 = cute.add_offset(%iter_93, %int_tuple_880) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3379 = builtin.unrealized_conversion_cast %ptr_911 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3380 = nvvm.mapa.shared.cluster %3379, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3380, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %3381 = arith.addi %3154, %c1_i32 : i32
      cf.br ^bb663(%3381, %3164, %3166, %3168, %3179, %3181, %3183 : i32, i32, i32, i32, i32, i32, i32)
    ^bb679:  // pred: ^bb663
      %int_tuple_912 = cute.make_int_tuple(%3156) : (i32) -> !cute.int_tuple<"?">
      %ptr_913 = cute.add_offset(%ptr_96, %int_tuple_912) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3382 = builtin.unrealized_conversion_cast %ptr_913 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3382, %3157, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3383 = arith.addi %3156, %c1_i32 : i32
      %3384 = arith.addi %3155, %c1_i32 : i32
      %3385 = arith.cmpi eq, %3383, %c3_i32 : i32
      %3386 = arith.select %3385, %c0_i32, %3383 : i32
      cf.cond_br %3385, ^bb680, ^bb681
    ^bb680:  // pred: ^bb679
      %3387 = arith.xori %3157, %c1_i32 : i32
      cf.br ^bb682(%3387 : i32)
    ^bb681:  // pred: ^bb679
      cf.br ^bb682(%3157 : i32)
    ^bb682(%3388: i32):  // 2 preds: ^bb680, ^bb681
      cf.br ^bb683
    ^bb683:  // pred: ^bb682
      %ptr_914 = cute.add_offset(%iter_877, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_915 = cute.make_coord(%3156) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_916 = cute.crd2idx(%coord_915, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb684(%c0_i32 : i32)
    ^bb684(%3389: i32):  // 2 preds: ^bb683, ^bb685
      %3390 = arith.cmpi slt, %3389, %2880 : i32
      cf.cond_br %3390, ^bb685, ^bb686 {llvm.loop_annotation = #loop_annotation}
    ^bb685:  // pred: ^bb684
      %coord_917 = cute.make_coord(%3389) : (i32) -> !cute.coord<"(_,?)">
      %idx_918 = cute.crd2idx(%coord_917, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_919 = cute.add_offset(%ptr_914, %idx_918) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_920 = cute.crd2idx(%coord_917, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_921 = cute.add_offset(%ptr_831, %idx_920) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_922 = cute.apply_swizzle(%ptr_921) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_923 = cute.add_offset(%swizzled_922, %idx_916) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3391 = builtin.unrealized_conversion_cast %ptr_919 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3392 = builtin.unrealized_conversion_cast %ptr_923 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3393 = llvm.load %3391 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3393, %3392 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3394 = arith.addi %3389, %c1_i32 : i32
      cf.br ^bb684(%3394 : i32)
    ^bb686:  // pred: ^bb684
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_924 = cute.add_offset(%iter_93, %int_tuple_912) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3395 = builtin.unrealized_conversion_cast %ptr_924 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3396 = nvvm.mapa.shared.cluster %3395, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3396, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_925 = cute.add_offset(%ptr_66, %int_tuple_853) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3397 = builtin.unrealized_conversion_cast %ptr_925 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3397, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb687(%c1_i32, %3158, %3159, %3160, %2927, %2929, %2931, %3384, %3386, %3388, %2921, %2922, %2923 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb687(%3398: i32, %3399: i32, %3400: i32, %3401: i32, %3402: i32, %3403: i32, %3404: i32, %3405: i32, %3406: i32, %3407: i32, %3408: i32, %3409: i32, %3410: i32):  // 2 preds: ^bb686, ^bb764
      %3411 = arith.cmpi slt, %3398, %2869 : i32
      cf.cond_br %3411, ^bb688, ^bb765 {loop_annotation = #loop_annotation2}
    ^bb688:  // pred: ^bb687
      %3412 = cute.make_tiled_copy(%atom_826) : !copy_simt1
      %rmem_926 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_927 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_928 = cute.memref.alloca() : !memref_rmem_bf16_3
      %int_tuple_929 = cute.make_int_tuple(%3403) : (i32) -> !cute.int_tuple<"?">
      %ptr_930 = cute.add_offset(%iter_61, %int_tuple_929) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3413 = builtin.unrealized_conversion_cast %ptr_930 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3413, %3404, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3414 = arith.addi %3403, %c1_i32 : i32
      %3415 = arith.addi %3402, %c1_i32 : i32
      %3416 = arith.cmpi eq, %3414, %c5_i32 : i32
      %3417 = arith.select %3416, %c0_i32, %3414 : i32
      cf.cond_br %3416, ^bb689, ^bb690
    ^bb689:  // pred: ^bb688
      %3418 = arith.xori %3404, %c1_i32 : i32
      cf.br ^bb691(%3418 : i32)
    ^bb690:  // pred: ^bb688
      cf.br ^bb691(%3404 : i32)
    ^bb691(%3419: i32):  // 2 preds: ^bb689, ^bb690
      cf.br ^bb692
    ^bb692:  // pred: ^bb691
      %coord_931 = cute.make_coord(%3403) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_932 = cute.crd2idx(%coord_931, %14) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,(8,1),5):((0,0),64,0,0,(0,1),128)">) -> !cute.int_tuple<"?{div=128}">
      %iter_933 = cute.get_iter(%rmem_928) : !memref_rmem_bf16_3
      cf.br ^bb693(%c0_i32 : i32)
    ^bb693(%3420: i32):  // 2 preds: ^bb692, ^bb694
      %3421 = arith.cmpi slt, %3420, %2877 : i32
      cf.cond_br %3421, ^bb694, ^bb695 {llvm.loop_annotation = #loop_annotation}
    ^bb694:  // pred: ^bb693
      %coord_934 = cute.make_coord(%3420) : (i32) -> !cute.coord<"(_,?)">
      %idx_935 = cute.crd2idx(%coord_934, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(64,0,0,(0,1)))">) -> !cute.int_tuple<"?">
      %ptr_936 = cute.add_offset(%ptr_833, %idx_935) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_937 = cute.add_offset(%ptr_936, %idx_932) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<bf16, smem>
      %idx_938 = cute.crd2idx(%coord_934, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(8,1))):((0,0),(1,0,0,(0,0)))">) -> !cute.int_tuple<"?">
      %ptr_939 = cute.add_offset(%iter_933, %idx_938) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %3422 = builtin.unrealized_conversion_cast %ptr_937 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %3423 = builtin.unrealized_conversion_cast %ptr_939 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %3424 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3424, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3425 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3425, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3426 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3426, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3427 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3427, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3428 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3428, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3429 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3429, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3430 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3430, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3431 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3431, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3432 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3432, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3433 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3433, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3434 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3434, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3435 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3435, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3436 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3436, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3437 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3437, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3438 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3438, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3439 = llvm.load %3422 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3439, %3423 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3440 = arith.addi %3420, %c1_i32 : i32
      cf.br ^bb693(%3440 : i32)
    ^bb695:  // pred: ^bb693
      %int_tuple_940 = cute.make_int_tuple(%3400) : (i32) -> !cute.int_tuple<"?">
      %ptr_941 = cute.add_offset(%iter_46, %int_tuple_940) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3441 = builtin.unrealized_conversion_cast %ptr_941 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3441, %3401, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3442 = arith.addi %3400, %c1_i32 : i32
      %3443 = arith.addi %3399, %c1_i32 : i32
      %3444 = arith.cmpi eq, %3442, %c5_i32 : i32
      %3445 = arith.select %3444, %c0_i32, %3442 : i32
      cf.cond_br %3444, ^bb696, ^bb697
    ^bb696:  // pred: ^bb695
      %3446 = arith.xori %3401, %c1_i32 : i32
      cf.br ^bb698(%3446 : i32)
    ^bb697:  // pred: ^bb695
      cf.br ^bb698(%3401 : i32)
    ^bb698(%3447: i32):  // 2 preds: ^bb696, ^bb697
      cf.br ^bb699
    ^bb699:  // pred: ^bb698
      %coord_942 = cute.make_coord(%3400) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_943 = cute.crd2idx(%coord_942, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %iter_944 = cute.get_iter(%rmem_926) : !memref_rmem_i8_
      %ptr_945 = cute.add_offset(%swizzled_836, %idx_943) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb700(%c0_i32 : i32)
    ^bb700(%3448: i32):  // 2 preds: ^bb699, ^bb701
      %3449 = arith.cmpi slt, %3448, %2878 : i32
      cf.cond_br %3449, ^bb701, ^bb702 {llvm.loop_annotation = #loop_annotation}
    ^bb701:  // pred: ^bb700
      %coord_946 = cute.make_coord(%3448) : (i32) -> !cute.coord<"(_,?)">
      %idx_947 = cute.crd2idx(%coord_946, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_948 = cute.crd2idx(%coord_946, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_949 = cute.add_offset(%iter_944, %idx_948) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_950 = cute.add_offset(%ptr_945, %idx_947) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %3450 = builtin.unrealized_conversion_cast %ptr_950 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %3451 = builtin.unrealized_conversion_cast %ptr_949 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3452 = llvm.load %3450 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3452, %3451 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3453 = arith.addi %3448, %c1_i32 : i32
      cf.br ^bb700(%3453 : i32)
    ^bb702:  // pred: ^bb700
      %view_951 = cute.make_view(%iter_944) : !memref_rmem_i8_1
      %3454 = cute.memref.load_vec %view_951 : !memref_rmem_i8_1
      %3455 = vector.extract_strided_slice %3454 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3456 = llvm.bitcast %3455 : vector<4xi8> to i32
      %3457 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3456, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3458 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3456, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3459 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3456, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3460 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3456, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3461 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3457 : (i32) -> f32
      %3462 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3458 : (i32) -> f32
      %3463 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3459 : (i32) -> f32
      %3464 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3460 : (i32) -> f32
      %3465 = vector.from_elements %3461, %3462, %3463, %3464 : vector<4xf32>
      %3466 = vector.extract_strided_slice %3465 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3467 = vector.extract_strided_slice %3465 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3468 = vector.extractelement %3466[%c0_i32 : i32] : vector<2xf32>
      %3469 = vector.extractelement %3466[%c1_i32 : i32] : vector<2xf32>
      %3470 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3469, %3468 : (f32, f32) -> i32
      %3471 = llvm.bitcast %3470 : i32 to vector<2xbf16>
      %3472 = vector.extractelement %3467[%c0_i32 : i32] : vector<2xf32>
      %3473 = vector.extractelement %3467[%c1_i32 : i32] : vector<2xf32>
      %3474 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3473, %3472 : (f32, f32) -> i32
      %3475 = llvm.bitcast %3474 : i32 to vector<2xbf16>
      %3476 = vector.insert_strided_slice %3471, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3477 = vector.insert_strided_slice %3475, %3476 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3478 = vector.extract_strided_slice %3454 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3479 = llvm.bitcast %3478 : vector<4xi8> to i32
      %3480 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3479, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3481 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3479, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3482 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3479, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3483 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3479, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3484 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3480 : (i32) -> f32
      %3485 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3481 : (i32) -> f32
      %3486 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3482 : (i32) -> f32
      %3487 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3483 : (i32) -> f32
      %3488 = vector.from_elements %3484, %3485, %3486, %3487 : vector<4xf32>
      %3489 = vector.extract_strided_slice %3488 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3490 = vector.extract_strided_slice %3488 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3491 = vector.extractelement %3489[%c0_i32 : i32] : vector<2xf32>
      %3492 = vector.extractelement %3489[%c1_i32 : i32] : vector<2xf32>
      %3493 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3492, %3491 : (f32, f32) -> i32
      %3494 = llvm.bitcast %3493 : i32 to vector<2xbf16>
      %3495 = vector.extractelement %3490[%c0_i32 : i32] : vector<2xf32>
      %3496 = vector.extractelement %3490[%c1_i32 : i32] : vector<2xf32>
      %3497 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3496, %3495 : (f32, f32) -> i32
      %3498 = llvm.bitcast %3497 : i32 to vector<2xbf16>
      %3499 = vector.insert_strided_slice %3494, %3477 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3500 = vector.insert_strided_slice %3498, %3499 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3501 = vector.extract_strided_slice %3454 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3502 = llvm.bitcast %3501 : vector<4xi8> to i32
      %3503 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3502, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3504 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3502, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3505 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3502, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3506 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3502, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3507 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3503 : (i32) -> f32
      %3508 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3504 : (i32) -> f32
      %3509 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3505 : (i32) -> f32
      %3510 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3506 : (i32) -> f32
      %3511 = vector.from_elements %3507, %3508, %3509, %3510 : vector<4xf32>
      %3512 = vector.extract_strided_slice %3511 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3513 = vector.extract_strided_slice %3511 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3514 = vector.extractelement %3512[%c0_i32 : i32] : vector<2xf32>
      %3515 = vector.extractelement %3512[%c1_i32 : i32] : vector<2xf32>
      %3516 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3515, %3514 : (f32, f32) -> i32
      %3517 = llvm.bitcast %3516 : i32 to vector<2xbf16>
      %3518 = vector.extractelement %3513[%c0_i32 : i32] : vector<2xf32>
      %3519 = vector.extractelement %3513[%c1_i32 : i32] : vector<2xf32>
      %3520 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3519, %3518 : (f32, f32) -> i32
      %3521 = llvm.bitcast %3520 : i32 to vector<2xbf16>
      %3522 = vector.insert_strided_slice %3517, %3500 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3523 = vector.insert_strided_slice %3521, %3522 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3524 = vector.extract_strided_slice %3454 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3525 = llvm.bitcast %3524 : vector<4xi8> to i32
      %3526 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3525, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3527 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3525, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3528 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3525, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3529 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3525, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3530 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3526 : (i32) -> f32
      %3531 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3527 : (i32) -> f32
      %3532 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3528 : (i32) -> f32
      %3533 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3529 : (i32) -> f32
      %3534 = vector.from_elements %3530, %3531, %3532, %3533 : vector<4xf32>
      %3535 = vector.extract_strided_slice %3534 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3536 = vector.extract_strided_slice %3534 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3537 = vector.extractelement %3535[%c0_i32 : i32] : vector<2xf32>
      %3538 = vector.extractelement %3535[%c1_i32 : i32] : vector<2xf32>
      %3539 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3538, %3537 : (f32, f32) -> i32
      %3540 = llvm.bitcast %3539 : i32 to vector<2xbf16>
      %3541 = vector.extractelement %3536[%c0_i32 : i32] : vector<2xf32>
      %3542 = vector.extractelement %3536[%c1_i32 : i32] : vector<2xf32>
      %3543 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3542, %3541 : (f32, f32) -> i32
      %3544 = llvm.bitcast %3543 : i32 to vector<2xbf16>
      %3545 = vector.insert_strided_slice %3540, %3523 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3546 = vector.insert_strided_slice %3544, %3545 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3547 = vector.extract_strided_slice %3454 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3548 = llvm.bitcast %3547 : vector<4xi8> to i32
      %3549 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3548, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3550 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3548, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3551 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3548, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3552 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3548, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3553 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3549 : (i32) -> f32
      %3554 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3550 : (i32) -> f32
      %3555 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3551 : (i32) -> f32
      %3556 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3552 : (i32) -> f32
      %3557 = vector.from_elements %3553, %3554, %3555, %3556 : vector<4xf32>
      %3558 = vector.extract_strided_slice %3557 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3559 = vector.extract_strided_slice %3557 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3560 = vector.extractelement %3558[%c0_i32 : i32] : vector<2xf32>
      %3561 = vector.extractelement %3558[%c1_i32 : i32] : vector<2xf32>
      %3562 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3561, %3560 : (f32, f32) -> i32
      %3563 = llvm.bitcast %3562 : i32 to vector<2xbf16>
      %3564 = vector.extractelement %3559[%c0_i32 : i32] : vector<2xf32>
      %3565 = vector.extractelement %3559[%c1_i32 : i32] : vector<2xf32>
      %3566 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3565, %3564 : (f32, f32) -> i32
      %3567 = llvm.bitcast %3566 : i32 to vector<2xbf16>
      %3568 = vector.insert_strided_slice %3563, %3546 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3569 = vector.insert_strided_slice %3567, %3568 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3570 = vector.extract_strided_slice %3454 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3571 = llvm.bitcast %3570 : vector<4xi8> to i32
      %3572 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3571, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3573 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3571, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3574 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3571, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3575 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3571, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3576 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3572 : (i32) -> f32
      %3577 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3573 : (i32) -> f32
      %3578 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3574 : (i32) -> f32
      %3579 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3575 : (i32) -> f32
      %3580 = vector.from_elements %3576, %3577, %3578, %3579 : vector<4xf32>
      %3581 = vector.extract_strided_slice %3580 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3582 = vector.extract_strided_slice %3580 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3583 = vector.extractelement %3581[%c0_i32 : i32] : vector<2xf32>
      %3584 = vector.extractelement %3581[%c1_i32 : i32] : vector<2xf32>
      %3585 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3584, %3583 : (f32, f32) -> i32
      %3586 = llvm.bitcast %3585 : i32 to vector<2xbf16>
      %3587 = vector.extractelement %3582[%c0_i32 : i32] : vector<2xf32>
      %3588 = vector.extractelement %3582[%c1_i32 : i32] : vector<2xf32>
      %3589 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3588, %3587 : (f32, f32) -> i32
      %3590 = llvm.bitcast %3589 : i32 to vector<2xbf16>
      %3591 = vector.insert_strided_slice %3586, %3569 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3592 = vector.insert_strided_slice %3590, %3591 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3593 = vector.extract_strided_slice %3454 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3594 = llvm.bitcast %3593 : vector<4xi8> to i32
      %3595 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3594, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3596 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3594, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3597 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3594, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3598 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3594, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3599 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3595 : (i32) -> f32
      %3600 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3596 : (i32) -> f32
      %3601 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3597 : (i32) -> f32
      %3602 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3598 : (i32) -> f32
      %3603 = vector.from_elements %3599, %3600, %3601, %3602 : vector<4xf32>
      %3604 = vector.extract_strided_slice %3603 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3605 = vector.extract_strided_slice %3603 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3606 = vector.extractelement %3604[%c0_i32 : i32] : vector<2xf32>
      %3607 = vector.extractelement %3604[%c1_i32 : i32] : vector<2xf32>
      %3608 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3607, %3606 : (f32, f32) -> i32
      %3609 = llvm.bitcast %3608 : i32 to vector<2xbf16>
      %3610 = vector.extractelement %3605[%c0_i32 : i32] : vector<2xf32>
      %3611 = vector.extractelement %3605[%c1_i32 : i32] : vector<2xf32>
      %3612 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3611, %3610 : (f32, f32) -> i32
      %3613 = llvm.bitcast %3612 : i32 to vector<2xbf16>
      %3614 = vector.insert_strided_slice %3609, %3592 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3615 = vector.insert_strided_slice %3613, %3614 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3616 = vector.extract_strided_slice %3454 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3617 = llvm.bitcast %3616 : vector<4xi8> to i32
      %3618 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3617, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3619 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3617, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3620 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3617, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3621 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3617, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3622 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3618 : (i32) -> f32
      %3623 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3619 : (i32) -> f32
      %3624 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3620 : (i32) -> f32
      %3625 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3621 : (i32) -> f32
      %3626 = vector.from_elements %3622, %3623, %3624, %3625 : vector<4xf32>
      %3627 = vector.extract_strided_slice %3626 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3628 = vector.extract_strided_slice %3626 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3629 = vector.extractelement %3627[%c0_i32 : i32] : vector<2xf32>
      %3630 = vector.extractelement %3627[%c1_i32 : i32] : vector<2xf32>
      %3631 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3630, %3629 : (f32, f32) -> i32
      %3632 = llvm.bitcast %3631 : i32 to vector<2xbf16>
      %3633 = vector.extractelement %3628[%c0_i32 : i32] : vector<2xf32>
      %3634 = vector.extractelement %3628[%c1_i32 : i32] : vector<2xf32>
      %3635 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3634, %3633 : (f32, f32) -> i32
      %3636 = llvm.bitcast %3635 : i32 to vector<2xbf16>
      %3637 = vector.insert_strided_slice %3632, %3615 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3638 = vector.insert_strided_slice %3636, %3637 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_952 = cute.make_view(%iter_933) : !memref_rmem_bf16_4
      %3639 = cute.memref.load_vec %view_952 : !memref_rmem_bf16_4
      %3640 = arith.mulf %3638, %3639 : vector<32xbf16>
      %iter_953 = cute.get_iter(%rmem_927) : !memref_rmem_bf16_2
      %view_954 = cute.make_view(%iter_953) : !memref_rmem_bf16_5
      cute.memref.store_vec %3640, %view_954 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_955 = cute.add_offset(%ptr_51, %int_tuple_940) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3641 = builtin.unrealized_conversion_cast %ptr_955 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3641, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb703(%c1_i32, %3405, %3406, %3407, %3443, %3445, %3447 : i32, i32, i32, i32, i32, i32, i32)
    ^bb703(%3642: i32, %3643: i32, %3644: i32, %3645: i32, %3646: i32, %3647: i32, %3648: i32):  // 2 preds: ^bb702, ^bb718
      %3649 = arith.cmpi slt, %3642, %c8_i32 : i32
      cf.cond_br %3649, ^bb704, ^bb719 {loop_annotation = #loop_annotation1}
    ^bb704:  // pred: ^bb703
      %int_tuple_956 = cute.make_int_tuple(%3644) : (i32) -> !cute.int_tuple<"?">
      %ptr_957 = cute.add_offset(%ptr_96, %int_tuple_956) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3650 = builtin.unrealized_conversion_cast %ptr_957 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3650, %3645, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3651 = arith.addi %3644, %c1_i32 : i32
      %3652 = arith.addi %3643, %c1_i32 : i32
      %3653 = arith.cmpi eq, %3651, %c3_i32 : i32
      %3654 = arith.select %3653, %c0_i32, %3651 : i32
      cf.cond_br %3653, ^bb705, ^bb706
    ^bb705:  // pred: ^bb704
      %3655 = arith.xori %3645, %c1_i32 : i32
      cf.br ^bb707(%3655 : i32)
    ^bb706:  // pred: ^bb704
      cf.br ^bb707(%3645 : i32)
    ^bb707(%3656: i32):  // 2 preds: ^bb705, ^bb706
      cf.br ^bb708
    ^bb708:  // pred: ^bb707
      %3657 = arith.subi %3642, %c1_i32 : i32
      %3658 = arith.remsi %3657, %c2_i32 : i32
      %coord_958 = cute.make_coord(%3658) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_959 = cute.crd2idx(%coord_958, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_960 = cute.add_offset(%iter_953, %idx_959) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_961 = cute.make_coord(%3644) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_962 = cute.crd2idx(%coord_961, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb709(%c0_i32 : i32)
    ^bb709(%3659: i32):  // 2 preds: ^bb708, ^bb710
      %3660 = arith.cmpi slt, %3659, %2880 : i32
      cf.cond_br %3660, ^bb710, ^bb711 {llvm.loop_annotation = #loop_annotation}
    ^bb710:  // pred: ^bb709
      %coord_963 = cute.make_coord(%3659) : (i32) -> !cute.coord<"(_,?)">
      %idx_964 = cute.crd2idx(%coord_963, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_965 = cute.add_offset(%ptr_960, %idx_964) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_966 = cute.crd2idx(%coord_963, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_967 = cute.add_offset(%ptr_831, %idx_966) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_968 = cute.apply_swizzle(%ptr_967) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_969 = cute.add_offset(%swizzled_968, %idx_962) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3661 = builtin.unrealized_conversion_cast %ptr_965 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3662 = builtin.unrealized_conversion_cast %ptr_969 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3663 = llvm.load %3661 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3663, %3662 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3664 = arith.addi %3659, %c1_i32 : i32
      cf.br ^bb709(%3664 : i32)
    ^bb711:  // pred: ^bb709
      %int_tuple_970 = cute.make_int_tuple(%3647) : (i32) -> !cute.int_tuple<"?">
      %ptr_971 = cute.add_offset(%iter_46, %int_tuple_970) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3665 = builtin.unrealized_conversion_cast %ptr_971 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3665, %3648, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3666 = arith.addi %3647, %c1_i32 : i32
      %3667 = arith.addi %3646, %c1_i32 : i32
      %3668 = arith.cmpi eq, %3666, %c5_i32 : i32
      %3669 = arith.select %3668, %c0_i32, %3666 : i32
      cf.cond_br %3668, ^bb712, ^bb713
    ^bb712:  // pred: ^bb711
      %3670 = arith.xori %3648, %c1_i32 : i32
      cf.br ^bb714(%3670 : i32)
    ^bb713:  // pred: ^bb711
      cf.br ^bb714(%3648 : i32)
    ^bb714(%3671: i32):  // 2 preds: ^bb712, ^bb713
      cf.br ^bb715
    ^bb715:  // pred: ^bb714
      %coord_972 = cute.make_coord(%3647) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_973 = cute.crd2idx(%coord_972, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %3672 = arith.remsi %3642, %c2_i32 : i32
      %coord_974 = cute.make_coord(%3672) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_975 = cute.crd2idx(%coord_974, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_976 = cute.add_offset(%iter_944, %idx_975) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      %ptr_977 = cute.add_offset(%swizzled_837, %idx_973) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      cf.br ^bb716(%c0_i32 : i32)
    ^bb716(%3673: i32):  // 2 preds: ^bb715, ^bb717
      %3674 = arith.cmpi slt, %3673, %2878 : i32
      cf.cond_br %3674, ^bb717, ^bb718 {llvm.loop_annotation = #loop_annotation}
    ^bb717:  // pred: ^bb716
      %coord_978 = cute.make_coord(%3673) : (i32) -> !cute.coord<"(_,?)">
      %idx_979 = cute.crd2idx(%coord_978, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %idx_980 = cute.crd2idx(%coord_978, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_981 = cute.add_offset(%ptr_976, %idx_980) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %ptr_982 = cute.add_offset(%ptr_977, %idx_979) : (!cute.ptr<i8, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>, S<2,4,3>>
      %3675 = builtin.unrealized_conversion_cast %ptr_982 : !cute.ptr<i8, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %3676 = builtin.unrealized_conversion_cast %ptr_981 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3677 = llvm.load %3675 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3677, %3676 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3678 = arith.addi %3673, %c1_i32 : i32
      cf.br ^bb716(%3678 : i32)
    ^bb718:  // pred: ^bb716
      %view_983 = cute.make_view(%ptr_976) : !memref_rmem_i8_1
      %3679 = cute.memref.load_vec %view_983 : !memref_rmem_i8_1
      %3680 = vector.extract_strided_slice %3679 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3681 = llvm.bitcast %3680 : vector<4xi8> to i32
      %3682 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3681, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3683 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3681, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3684 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3681, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3685 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3681, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3686 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3682 : (i32) -> f32
      %3687 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3683 : (i32) -> f32
      %3688 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3684 : (i32) -> f32
      %3689 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3685 : (i32) -> f32
      %3690 = vector.from_elements %3686, %3687, %3688, %3689 : vector<4xf32>
      %3691 = vector.extract_strided_slice %3690 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3692 = vector.extract_strided_slice %3690 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3693 = vector.extractelement %3691[%c0_i32 : i32] : vector<2xf32>
      %3694 = vector.extractelement %3691[%c1_i32 : i32] : vector<2xf32>
      %3695 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3694, %3693 : (f32, f32) -> i32
      %3696 = llvm.bitcast %3695 : i32 to vector<2xbf16>
      %3697 = vector.extractelement %3692[%c0_i32 : i32] : vector<2xf32>
      %3698 = vector.extractelement %3692[%c1_i32 : i32] : vector<2xf32>
      %3699 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3698, %3697 : (f32, f32) -> i32
      %3700 = llvm.bitcast %3699 : i32 to vector<2xbf16>
      %3701 = vector.insert_strided_slice %3696, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3702 = vector.insert_strided_slice %3700, %3701 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3703 = vector.extract_strided_slice %3679 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3704 = llvm.bitcast %3703 : vector<4xi8> to i32
      %3705 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3704, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3706 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3704, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3707 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3704, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3708 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3704, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3709 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3705 : (i32) -> f32
      %3710 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3706 : (i32) -> f32
      %3711 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3707 : (i32) -> f32
      %3712 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3708 : (i32) -> f32
      %3713 = vector.from_elements %3709, %3710, %3711, %3712 : vector<4xf32>
      %3714 = vector.extract_strided_slice %3713 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3715 = vector.extract_strided_slice %3713 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3716 = vector.extractelement %3714[%c0_i32 : i32] : vector<2xf32>
      %3717 = vector.extractelement %3714[%c1_i32 : i32] : vector<2xf32>
      %3718 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3717, %3716 : (f32, f32) -> i32
      %3719 = llvm.bitcast %3718 : i32 to vector<2xbf16>
      %3720 = vector.extractelement %3715[%c0_i32 : i32] : vector<2xf32>
      %3721 = vector.extractelement %3715[%c1_i32 : i32] : vector<2xf32>
      %3722 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3721, %3720 : (f32, f32) -> i32
      %3723 = llvm.bitcast %3722 : i32 to vector<2xbf16>
      %3724 = vector.insert_strided_slice %3719, %3702 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3725 = vector.insert_strided_slice %3723, %3724 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3726 = vector.extract_strided_slice %3679 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3727 = llvm.bitcast %3726 : vector<4xi8> to i32
      %3728 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3727, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3729 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3727, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3730 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3727, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3731 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3727, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3732 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3728 : (i32) -> f32
      %3733 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3729 : (i32) -> f32
      %3734 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3730 : (i32) -> f32
      %3735 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3731 : (i32) -> f32
      %3736 = vector.from_elements %3732, %3733, %3734, %3735 : vector<4xf32>
      %3737 = vector.extract_strided_slice %3736 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3738 = vector.extract_strided_slice %3736 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3739 = vector.extractelement %3737[%c0_i32 : i32] : vector<2xf32>
      %3740 = vector.extractelement %3737[%c1_i32 : i32] : vector<2xf32>
      %3741 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3740, %3739 : (f32, f32) -> i32
      %3742 = llvm.bitcast %3741 : i32 to vector<2xbf16>
      %3743 = vector.extractelement %3738[%c0_i32 : i32] : vector<2xf32>
      %3744 = vector.extractelement %3738[%c1_i32 : i32] : vector<2xf32>
      %3745 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3744, %3743 : (f32, f32) -> i32
      %3746 = llvm.bitcast %3745 : i32 to vector<2xbf16>
      %3747 = vector.insert_strided_slice %3742, %3725 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3748 = vector.insert_strided_slice %3746, %3747 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3749 = vector.extract_strided_slice %3679 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3750 = llvm.bitcast %3749 : vector<4xi8> to i32
      %3751 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3750, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3752 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3750, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3753 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3750, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3754 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3750, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3755 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3751 : (i32) -> f32
      %3756 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3752 : (i32) -> f32
      %3757 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3753 : (i32) -> f32
      %3758 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3754 : (i32) -> f32
      %3759 = vector.from_elements %3755, %3756, %3757, %3758 : vector<4xf32>
      %3760 = vector.extract_strided_slice %3759 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3761 = vector.extract_strided_slice %3759 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3762 = vector.extractelement %3760[%c0_i32 : i32] : vector<2xf32>
      %3763 = vector.extractelement %3760[%c1_i32 : i32] : vector<2xf32>
      %3764 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3763, %3762 : (f32, f32) -> i32
      %3765 = llvm.bitcast %3764 : i32 to vector<2xbf16>
      %3766 = vector.extractelement %3761[%c0_i32 : i32] : vector<2xf32>
      %3767 = vector.extractelement %3761[%c1_i32 : i32] : vector<2xf32>
      %3768 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3767, %3766 : (f32, f32) -> i32
      %3769 = llvm.bitcast %3768 : i32 to vector<2xbf16>
      %3770 = vector.insert_strided_slice %3765, %3748 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3771 = vector.insert_strided_slice %3769, %3770 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3772 = vector.extract_strided_slice %3679 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3773 = llvm.bitcast %3772 : vector<4xi8> to i32
      %3774 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3773, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3775 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3773, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3776 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3773, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3777 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3773, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3778 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3774 : (i32) -> f32
      %3779 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3775 : (i32) -> f32
      %3780 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3776 : (i32) -> f32
      %3781 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3777 : (i32) -> f32
      %3782 = vector.from_elements %3778, %3779, %3780, %3781 : vector<4xf32>
      %3783 = vector.extract_strided_slice %3782 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3784 = vector.extract_strided_slice %3782 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3785 = vector.extractelement %3783[%c0_i32 : i32] : vector<2xf32>
      %3786 = vector.extractelement %3783[%c1_i32 : i32] : vector<2xf32>
      %3787 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3786, %3785 : (f32, f32) -> i32
      %3788 = llvm.bitcast %3787 : i32 to vector<2xbf16>
      %3789 = vector.extractelement %3784[%c0_i32 : i32] : vector<2xf32>
      %3790 = vector.extractelement %3784[%c1_i32 : i32] : vector<2xf32>
      %3791 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3790, %3789 : (f32, f32) -> i32
      %3792 = llvm.bitcast %3791 : i32 to vector<2xbf16>
      %3793 = vector.insert_strided_slice %3788, %3771 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3794 = vector.insert_strided_slice %3792, %3793 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3795 = vector.extract_strided_slice %3679 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3796 = llvm.bitcast %3795 : vector<4xi8> to i32
      %3797 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3796, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3798 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3796, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3799 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3796, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3800 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3796, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3801 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3797 : (i32) -> f32
      %3802 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3798 : (i32) -> f32
      %3803 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3799 : (i32) -> f32
      %3804 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3800 : (i32) -> f32
      %3805 = vector.from_elements %3801, %3802, %3803, %3804 : vector<4xf32>
      %3806 = vector.extract_strided_slice %3805 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3807 = vector.extract_strided_slice %3805 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3808 = vector.extractelement %3806[%c0_i32 : i32] : vector<2xf32>
      %3809 = vector.extractelement %3806[%c1_i32 : i32] : vector<2xf32>
      %3810 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3809, %3808 : (f32, f32) -> i32
      %3811 = llvm.bitcast %3810 : i32 to vector<2xbf16>
      %3812 = vector.extractelement %3807[%c0_i32 : i32] : vector<2xf32>
      %3813 = vector.extractelement %3807[%c1_i32 : i32] : vector<2xf32>
      %3814 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3813, %3812 : (f32, f32) -> i32
      %3815 = llvm.bitcast %3814 : i32 to vector<2xbf16>
      %3816 = vector.insert_strided_slice %3811, %3794 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3817 = vector.insert_strided_slice %3815, %3816 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3818 = vector.extract_strided_slice %3679 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3819 = llvm.bitcast %3818 : vector<4xi8> to i32
      %3820 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3819, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3821 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3819, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3822 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3819, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3823 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3819, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3824 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3820 : (i32) -> f32
      %3825 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3821 : (i32) -> f32
      %3826 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3822 : (i32) -> f32
      %3827 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3823 : (i32) -> f32
      %3828 = vector.from_elements %3824, %3825, %3826, %3827 : vector<4xf32>
      %3829 = vector.extract_strided_slice %3828 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3830 = vector.extract_strided_slice %3828 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3831 = vector.extractelement %3829[%c0_i32 : i32] : vector<2xf32>
      %3832 = vector.extractelement %3829[%c1_i32 : i32] : vector<2xf32>
      %3833 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3832, %3831 : (f32, f32) -> i32
      %3834 = llvm.bitcast %3833 : i32 to vector<2xbf16>
      %3835 = vector.extractelement %3830[%c0_i32 : i32] : vector<2xf32>
      %3836 = vector.extractelement %3830[%c1_i32 : i32] : vector<2xf32>
      %3837 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3836, %3835 : (f32, f32) -> i32
      %3838 = llvm.bitcast %3837 : i32 to vector<2xbf16>
      %3839 = vector.insert_strided_slice %3834, %3817 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3840 = vector.insert_strided_slice %3838, %3839 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3841 = vector.extract_strided_slice %3679 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3842 = llvm.bitcast %3841 : vector<4xi8> to i32
      %3843 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3842, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3844 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3842, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3845 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3842, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3846 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3842, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3847 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3843 : (i32) -> f32
      %3848 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3844 : (i32) -> f32
      %3849 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3845 : (i32) -> f32
      %3850 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3846 : (i32) -> f32
      %3851 = vector.from_elements %3847, %3848, %3849, %3850 : vector<4xf32>
      %3852 = vector.extract_strided_slice %3851 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3853 = vector.extract_strided_slice %3851 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3854 = vector.extractelement %3852[%c0_i32 : i32] : vector<2xf32>
      %3855 = vector.extractelement %3852[%c1_i32 : i32] : vector<2xf32>
      %3856 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3855, %3854 : (f32, f32) -> i32
      %3857 = llvm.bitcast %3856 : i32 to vector<2xbf16>
      %3858 = vector.extractelement %3853[%c0_i32 : i32] : vector<2xf32>
      %3859 = vector.extractelement %3853[%c1_i32 : i32] : vector<2xf32>
      %3860 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3859, %3858 : (f32, f32) -> i32
      %3861 = llvm.bitcast %3860 : i32 to vector<2xbf16>
      %3862 = vector.insert_strided_slice %3857, %3840 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3863 = vector.insert_strided_slice %3861, %3862 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3864 = cute.memref.load_vec %view_952 : !memref_rmem_bf16_4
      %3865 = arith.mulf %3863, %3864 : vector<32xbf16>
      %ptr_984 = cute.add_offset(%iter_953, %idx_975) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_985 = cute.make_view(%ptr_984) : !memref_rmem_bf16_5
      cute.memref.store_vec %3865, %view_985 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_986 = cute.add_offset(%ptr_51, %int_tuple_970) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3866 = builtin.unrealized_conversion_cast %ptr_986 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3866, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_987 = cute.add_offset(%iter_93, %int_tuple_956) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3867 = builtin.unrealized_conversion_cast %ptr_987 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3868 = nvvm.mapa.shared.cluster %3867, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3868, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %3869 = arith.addi %3642, %c1_i32 : i32
      cf.br ^bb703(%3869, %3652, %3654, %3656, %3667, %3669, %3671 : i32, i32, i32, i32, i32, i32, i32)
    ^bb719:  // pred: ^bb703
      %int_tuple_988 = cute.make_int_tuple(%3644) : (i32) -> !cute.int_tuple<"?">
      %ptr_989 = cute.add_offset(%ptr_96, %int_tuple_988) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3870 = builtin.unrealized_conversion_cast %ptr_989 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3870, %3645, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3871 = arith.addi %3644, %c1_i32 : i32
      %3872 = arith.addi %3643, %c1_i32 : i32
      %3873 = arith.cmpi eq, %3871, %c3_i32 : i32
      %3874 = arith.select %3873, %c0_i32, %3871 : i32
      cf.cond_br %3873, ^bb720, ^bb721
    ^bb720:  // pred: ^bb719
      %3875 = arith.xori %3645, %c1_i32 : i32
      cf.br ^bb722(%3875 : i32)
    ^bb721:  // pred: ^bb719
      cf.br ^bb722(%3645 : i32)
    ^bb722(%3876: i32):  // 2 preds: ^bb720, ^bb721
      cf.br ^bb723
    ^bb723:  // pred: ^bb722
      %ptr_990 = cute.add_offset(%iter_953, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_991 = cute.make_coord(%3644) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_992 = cute.crd2idx(%coord_991, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb724(%c0_i32 : i32)
    ^bb724(%3877: i32):  // 2 preds: ^bb723, ^bb725
      %3878 = arith.cmpi slt, %3877, %2880 : i32
      cf.cond_br %3878, ^bb725, ^bb726 {llvm.loop_annotation = #loop_annotation}
    ^bb725:  // pred: ^bb724
      %coord_993 = cute.make_coord(%3877) : (i32) -> !cute.coord<"(_,?)">
      %idx_994 = cute.crd2idx(%coord_993, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_995 = cute.add_offset(%ptr_990, %idx_994) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_996 = cute.crd2idx(%coord_993, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_997 = cute.add_offset(%ptr_831, %idx_996) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_998 = cute.apply_swizzle(%ptr_997) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_999 = cute.add_offset(%swizzled_998, %idx_992) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %3879 = builtin.unrealized_conversion_cast %ptr_995 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %3880 = builtin.unrealized_conversion_cast %ptr_999 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %3881 = llvm.load %3879 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %3881, %3880 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %3882 = arith.addi %3877, %c1_i32 : i32
      cf.br ^bb724(%3882 : i32)
    ^bb726:  // pred: ^bb724
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1000 = cute.add_offset(%iter_93, %int_tuple_988) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3883 = builtin.unrealized_conversion_cast %ptr_1000 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %3884 = nvvm.mapa.shared.cluster %3883, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %3884, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_1001 = cute.add_offset(%ptr_66, %int_tuple_929) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3885 = builtin.unrealized_conversion_cast %ptr_1001 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %3885, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %3886 = cute.make_tiled_copy(%atom_826) : !copy_simt2
      %rmem_1002 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_1003 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_1004 = cute.memref.alloca() : !memref_rmem_bf16_6
      %int_tuple_1005 = cute.make_int_tuple(%3409) : (i32) -> !cute.int_tuple<"?">
      %ptr_1006 = cute.add_offset(%iter_77, %int_tuple_1005) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3887 = builtin.unrealized_conversion_cast %ptr_1006 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3887, %3410, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3888 = arith.addi %3409, %c1_i32 : i32
      %3889 = arith.addi %3408, %c1_i32 : i32
      %3890 = arith.cmpi eq, %3888, %c5_i32 : i32
      %3891 = arith.select %3890, %c0_i32, %3888 : i32
      cf.cond_br %3890, ^bb727, ^bb728
    ^bb727:  // pred: ^bb726
      %3892 = arith.xori %3410, %c1_i32 : i32
      cf.br ^bb729(%3892 : i32)
    ^bb728:  // pred: ^bb726
      cf.br ^bb729(%3410 : i32)
    ^bb729(%3893: i32):  // 2 preds: ^bb727, ^bb728
      cf.br ^bb730
    ^bb730:  // pred: ^bb729
      %coord_1007 = cute.make_coord(%3409) : (i32) -> !cute.coord<"(_,_,_,_,_,(_,?))">
      %idx_1008 = cute.crd2idx(%coord_1007, %3) : (!cute.coord<"(_,_,_,_,_,(_,?))">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),(4,5)):((0,0),0,0,0,(0,(0,1)),(64,256))">) -> !cute.int_tuple<"?{div=256}">
      %iter_1009 = cute.get_iter(%rmem_1004) : !memref_rmem_bf16_6
      cf.br ^bb731(%c0_i32 : i32)
    ^bb731(%3894: i32):  // 2 preds: ^bb730, ^bb732
      %3895 = arith.cmpi slt, %3894, %2889 : i32
      cf.cond_br %3895, ^bb732, ^bb733 {llvm.loop_annotation = #loop_annotation}
    ^bb732:  // pred: ^bb731
      %coord_1010 = cute.make_coord(%3894) : (i32) -> !cute.coord<"(_,?)">
      %idx_1011 = cute.crd2idx(%coord_1010, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,1)),64))">) -> !cute.int_tuple<"?">
      %ptr_1012 = cute.add_offset(%ptr_843, %idx_1011) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_1013 = cute.add_offset(%ptr_1012, %idx_1008) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, smem>
      %idx_1014 = cute.crd2idx(%coord_1010, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,0)),1))">) -> !cute.int_tuple<"?">
      %ptr_1015 = cute.add_offset(%iter_1009, %idx_1014) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %3896 = builtin.unrealized_conversion_cast %ptr_1013 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %3897 = builtin.unrealized_conversion_cast %ptr_1015 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %3898 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3898, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3899 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3899, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3900 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3900, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3901 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3901, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3902 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3902, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3903 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3903, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3904 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3904, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3905 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3905, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3906 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3906, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3907 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3907, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3908 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3908, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3909 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3909, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3910 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3910, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3911 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3911, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3912 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3912, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3913 = llvm.load %3896 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %3913, %3897 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %3914 = arith.addi %3894, %c1_i32 : i32
      cf.br ^bb731(%3914 : i32)
    ^bb733:  // pred: ^bb731
      %int_tuple_1016 = cute.make_int_tuple(%3647) : (i32) -> !cute.int_tuple<"?">
      %ptr_1017 = cute.add_offset(%iter_46, %int_tuple_1016) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %3915 = builtin.unrealized_conversion_cast %ptr_1017 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %3915, %3648, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %3916 = arith.addi %3647, %c1_i32 : i32
      %3917 = arith.addi %3646, %c1_i32 : i32
      %3918 = arith.cmpi eq, %3916, %c5_i32 : i32
      %3919 = arith.select %3918, %c0_i32, %3916 : i32
      cf.cond_br %3918, ^bb734, ^bb735
    ^bb734:  // pred: ^bb733
      %3920 = arith.xori %3648, %c1_i32 : i32
      cf.br ^bb736(%3920 : i32)
    ^bb735:  // pred: ^bb733
      cf.br ^bb736(%3648 : i32)
    ^bb736(%3921: i32):  // 2 preds: ^bb734, ^bb735
      cf.br ^bb737
    ^bb737:  // pred: ^bb736
      %coord_1018 = cute.make_coord(%3647) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1019 = cute.crd2idx(%coord_1018, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1020 = cute.add_offset(%ptr_840, %idx_1019) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %iter_1021 = cute.get_iter(%rmem_1002) : !memref_rmem_i8_
      cf.br ^bb738(%c0_i32 : i32)
    ^bb738(%3922: i32):  // 2 preds: ^bb737, ^bb739
      %3923 = arith.cmpi slt, %3922, %2878 : i32
      cf.cond_br %3923, ^bb739, ^bb740 {llvm.loop_annotation = #loop_annotation}
    ^bb739:  // pred: ^bb738
      %coord_1022 = cute.make_coord(%3922) : (i32) -> !cute.coord<"(_,?)">
      %idx_1023 = cute.crd2idx(%coord_1022, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1024 = cute.add_offset(%ptr_1020, %idx_1023) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1025 = cute.crd2idx(%coord_1022, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1026 = cute.add_offset(%iter_1021, %idx_1025) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %3924 = builtin.unrealized_conversion_cast %ptr_1024 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %3925 = builtin.unrealized_conversion_cast %ptr_1026 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %3926 = llvm.load %3924 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %3926, %3925 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %3927 = arith.addi %3922, %c1_i32 : i32
      cf.br ^bb738(%3927 : i32)
    ^bb740:  // pred: ^bb738
      %view_1027 = cute.make_view(%iter_1021) : !memref_rmem_i8_1
      %3928 = cute.memref.load_vec %view_1027 : !memref_rmem_i8_1
      %3929 = vector.extract_strided_slice %3928 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3930 = llvm.bitcast %3929 : vector<4xi8> to i32
      %3931 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3930, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3932 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3930, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3933 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3930, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3934 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3930, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3935 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3931 : (i32) -> f32
      %3936 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3932 : (i32) -> f32
      %3937 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3933 : (i32) -> f32
      %3938 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3934 : (i32) -> f32
      %3939 = vector.from_elements %3935, %3936, %3937, %3938 : vector<4xf32>
      %3940 = vector.extract_strided_slice %3939 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3941 = vector.extract_strided_slice %3939 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3942 = vector.extractelement %3940[%c0_i32 : i32] : vector<2xf32>
      %3943 = vector.extractelement %3940[%c1_i32 : i32] : vector<2xf32>
      %3944 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3943, %3942 : (f32, f32) -> i32
      %3945 = llvm.bitcast %3944 : i32 to vector<2xbf16>
      %3946 = vector.extractelement %3941[%c0_i32 : i32] : vector<2xf32>
      %3947 = vector.extractelement %3941[%c1_i32 : i32] : vector<2xf32>
      %3948 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3947, %3946 : (f32, f32) -> i32
      %3949 = llvm.bitcast %3948 : i32 to vector<2xbf16>
      %3950 = vector.insert_strided_slice %3945, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3951 = vector.insert_strided_slice %3949, %3950 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3952 = vector.extract_strided_slice %3928 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3953 = llvm.bitcast %3952 : vector<4xi8> to i32
      %3954 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3953, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3955 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3953, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3956 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3953, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3957 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3953, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3958 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3954 : (i32) -> f32
      %3959 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3955 : (i32) -> f32
      %3960 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3956 : (i32) -> f32
      %3961 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3957 : (i32) -> f32
      %3962 = vector.from_elements %3958, %3959, %3960, %3961 : vector<4xf32>
      %3963 = vector.extract_strided_slice %3962 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3964 = vector.extract_strided_slice %3962 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3965 = vector.extractelement %3963[%c0_i32 : i32] : vector<2xf32>
      %3966 = vector.extractelement %3963[%c1_i32 : i32] : vector<2xf32>
      %3967 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3966, %3965 : (f32, f32) -> i32
      %3968 = llvm.bitcast %3967 : i32 to vector<2xbf16>
      %3969 = vector.extractelement %3964[%c0_i32 : i32] : vector<2xf32>
      %3970 = vector.extractelement %3964[%c1_i32 : i32] : vector<2xf32>
      %3971 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3970, %3969 : (f32, f32) -> i32
      %3972 = llvm.bitcast %3971 : i32 to vector<2xbf16>
      %3973 = vector.insert_strided_slice %3968, %3951 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3974 = vector.insert_strided_slice %3972, %3973 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3975 = vector.extract_strided_slice %3928 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3976 = llvm.bitcast %3975 : vector<4xi8> to i32
      %3977 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3976, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3978 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3976, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3979 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3976, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3980 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3976, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %3981 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3977 : (i32) -> f32
      %3982 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3978 : (i32) -> f32
      %3983 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3979 : (i32) -> f32
      %3984 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %3980 : (i32) -> f32
      %3985 = vector.from_elements %3981, %3982, %3983, %3984 : vector<4xf32>
      %3986 = vector.extract_strided_slice %3985 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3987 = vector.extract_strided_slice %3985 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %3988 = vector.extractelement %3986[%c0_i32 : i32] : vector<2xf32>
      %3989 = vector.extractelement %3986[%c1_i32 : i32] : vector<2xf32>
      %3990 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3989, %3988 : (f32, f32) -> i32
      %3991 = llvm.bitcast %3990 : i32 to vector<2xbf16>
      %3992 = vector.extractelement %3987[%c0_i32 : i32] : vector<2xf32>
      %3993 = vector.extractelement %3987[%c1_i32 : i32] : vector<2xf32>
      %3994 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %3993, %3992 : (f32, f32) -> i32
      %3995 = llvm.bitcast %3994 : i32 to vector<2xbf16>
      %3996 = vector.insert_strided_slice %3991, %3974 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3997 = vector.insert_strided_slice %3995, %3996 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %3998 = vector.extract_strided_slice %3928 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %3999 = llvm.bitcast %3998 : vector<4xi8> to i32
      %4000 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3999, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4001 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3999, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4002 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3999, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4003 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %3999, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4004 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4000 : (i32) -> f32
      %4005 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4001 : (i32) -> f32
      %4006 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4002 : (i32) -> f32
      %4007 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4003 : (i32) -> f32
      %4008 = vector.from_elements %4004, %4005, %4006, %4007 : vector<4xf32>
      %4009 = vector.extract_strided_slice %4008 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4010 = vector.extract_strided_slice %4008 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4011 = vector.extractelement %4009[%c0_i32 : i32] : vector<2xf32>
      %4012 = vector.extractelement %4009[%c1_i32 : i32] : vector<2xf32>
      %4013 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4012, %4011 : (f32, f32) -> i32
      %4014 = llvm.bitcast %4013 : i32 to vector<2xbf16>
      %4015 = vector.extractelement %4010[%c0_i32 : i32] : vector<2xf32>
      %4016 = vector.extractelement %4010[%c1_i32 : i32] : vector<2xf32>
      %4017 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4016, %4015 : (f32, f32) -> i32
      %4018 = llvm.bitcast %4017 : i32 to vector<2xbf16>
      %4019 = vector.insert_strided_slice %4014, %3997 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4020 = vector.insert_strided_slice %4018, %4019 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4021 = vector.extract_strided_slice %3928 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4022 = llvm.bitcast %4021 : vector<4xi8> to i32
      %4023 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4022, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4024 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4022, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4025 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4022, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4026 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4022, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4027 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4023 : (i32) -> f32
      %4028 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4024 : (i32) -> f32
      %4029 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4025 : (i32) -> f32
      %4030 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4026 : (i32) -> f32
      %4031 = vector.from_elements %4027, %4028, %4029, %4030 : vector<4xf32>
      %4032 = vector.extract_strided_slice %4031 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4033 = vector.extract_strided_slice %4031 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4034 = vector.extractelement %4032[%c0_i32 : i32] : vector<2xf32>
      %4035 = vector.extractelement %4032[%c1_i32 : i32] : vector<2xf32>
      %4036 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4035, %4034 : (f32, f32) -> i32
      %4037 = llvm.bitcast %4036 : i32 to vector<2xbf16>
      %4038 = vector.extractelement %4033[%c0_i32 : i32] : vector<2xf32>
      %4039 = vector.extractelement %4033[%c1_i32 : i32] : vector<2xf32>
      %4040 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4039, %4038 : (f32, f32) -> i32
      %4041 = llvm.bitcast %4040 : i32 to vector<2xbf16>
      %4042 = vector.insert_strided_slice %4037, %4020 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4043 = vector.insert_strided_slice %4041, %4042 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4044 = vector.extract_strided_slice %3928 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4045 = llvm.bitcast %4044 : vector<4xi8> to i32
      %4046 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4045, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4047 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4045, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4048 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4045, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4049 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4045, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4050 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4046 : (i32) -> f32
      %4051 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4047 : (i32) -> f32
      %4052 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4048 : (i32) -> f32
      %4053 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4049 : (i32) -> f32
      %4054 = vector.from_elements %4050, %4051, %4052, %4053 : vector<4xf32>
      %4055 = vector.extract_strided_slice %4054 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4056 = vector.extract_strided_slice %4054 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4057 = vector.extractelement %4055[%c0_i32 : i32] : vector<2xf32>
      %4058 = vector.extractelement %4055[%c1_i32 : i32] : vector<2xf32>
      %4059 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4058, %4057 : (f32, f32) -> i32
      %4060 = llvm.bitcast %4059 : i32 to vector<2xbf16>
      %4061 = vector.extractelement %4056[%c0_i32 : i32] : vector<2xf32>
      %4062 = vector.extractelement %4056[%c1_i32 : i32] : vector<2xf32>
      %4063 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4062, %4061 : (f32, f32) -> i32
      %4064 = llvm.bitcast %4063 : i32 to vector<2xbf16>
      %4065 = vector.insert_strided_slice %4060, %4043 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4066 = vector.insert_strided_slice %4064, %4065 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4067 = vector.extract_strided_slice %3928 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4068 = llvm.bitcast %4067 : vector<4xi8> to i32
      %4069 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4068, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4070 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4068, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4071 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4068, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4072 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4068, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4073 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4069 : (i32) -> f32
      %4074 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4070 : (i32) -> f32
      %4075 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4071 : (i32) -> f32
      %4076 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4072 : (i32) -> f32
      %4077 = vector.from_elements %4073, %4074, %4075, %4076 : vector<4xf32>
      %4078 = vector.extract_strided_slice %4077 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4079 = vector.extract_strided_slice %4077 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4080 = vector.extractelement %4078[%c0_i32 : i32] : vector<2xf32>
      %4081 = vector.extractelement %4078[%c1_i32 : i32] : vector<2xf32>
      %4082 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4081, %4080 : (f32, f32) -> i32
      %4083 = llvm.bitcast %4082 : i32 to vector<2xbf16>
      %4084 = vector.extractelement %4079[%c0_i32 : i32] : vector<2xf32>
      %4085 = vector.extractelement %4079[%c1_i32 : i32] : vector<2xf32>
      %4086 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4085, %4084 : (f32, f32) -> i32
      %4087 = llvm.bitcast %4086 : i32 to vector<2xbf16>
      %4088 = vector.insert_strided_slice %4083, %4066 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4089 = vector.insert_strided_slice %4087, %4088 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4090 = vector.extract_strided_slice %3928 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4091 = llvm.bitcast %4090 : vector<4xi8> to i32
      %4092 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4091, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4093 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4091, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4094 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4091, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4095 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4091, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4096 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4092 : (i32) -> f32
      %4097 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4093 : (i32) -> f32
      %4098 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4094 : (i32) -> f32
      %4099 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4095 : (i32) -> f32
      %4100 = vector.from_elements %4096, %4097, %4098, %4099 : vector<4xf32>
      %4101 = vector.extract_strided_slice %4100 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4102 = vector.extract_strided_slice %4100 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4103 = vector.extractelement %4101[%c0_i32 : i32] : vector<2xf32>
      %4104 = vector.extractelement %4101[%c1_i32 : i32] : vector<2xf32>
      %4105 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4104, %4103 : (f32, f32) -> i32
      %4106 = llvm.bitcast %4105 : i32 to vector<2xbf16>
      %4107 = vector.extractelement %4102[%c0_i32 : i32] : vector<2xf32>
      %4108 = vector.extractelement %4102[%c1_i32 : i32] : vector<2xf32>
      %4109 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4108, %4107 : (f32, f32) -> i32
      %4110 = llvm.bitcast %4109 : i32 to vector<2xbf16>
      %4111 = vector.insert_strided_slice %4106, %4089 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4112 = vector.insert_strided_slice %4110, %4111 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_1028 = cute.make_view(%iter_1009) : !memref_rmem_bf16_7
      %4113 = cute.memref.load_vec %view_1028 : !memref_rmem_bf16_7
      %4114 = arith.mulf %4112, %4113 : vector<32xbf16>
      %iter_1029 = cute.get_iter(%rmem_1003) : !memref_rmem_bf16_2
      %view_1030 = cute.make_view(%iter_1029) : !memref_rmem_bf16_5
      cute.memref.store_vec %4114, %view_1030 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1031 = cute.add_offset(%ptr_51, %int_tuple_1016) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4115 = builtin.unrealized_conversion_cast %ptr_1031 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4115, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb741(%c1_i32, %3872, %3874, %3876, %3917, %3919, %3921 : i32, i32, i32, i32, i32, i32, i32)
    ^bb741(%4116: i32, %4117: i32, %4118: i32, %4119: i32, %4120: i32, %4121: i32, %4122: i32):  // 2 preds: ^bb740, ^bb756
      %4123 = arith.cmpi slt, %4116, %c8_i32 : i32
      cf.cond_br %4123, ^bb742, ^bb757 {loop_annotation = #loop_annotation1}
    ^bb742:  // pred: ^bb741
      %int_tuple_1032 = cute.make_int_tuple(%4118) : (i32) -> !cute.int_tuple<"?">
      %ptr_1033 = cute.add_offset(%ptr_96, %int_tuple_1032) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4124 = builtin.unrealized_conversion_cast %ptr_1033 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4124, %4119, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4125 = arith.addi %4118, %c1_i32 : i32
      %4126 = arith.addi %4117, %c1_i32 : i32
      %4127 = arith.cmpi eq, %4125, %c3_i32 : i32
      %4128 = arith.select %4127, %c0_i32, %4125 : i32
      cf.cond_br %4127, ^bb743, ^bb744
    ^bb743:  // pred: ^bb742
      %4129 = arith.xori %4119, %c1_i32 : i32
      cf.br ^bb745(%4129 : i32)
    ^bb744:  // pred: ^bb742
      cf.br ^bb745(%4119 : i32)
    ^bb745(%4130: i32):  // 2 preds: ^bb743, ^bb744
      cf.br ^bb746
    ^bb746:  // pred: ^bb745
      %4131 = arith.subi %4116, %c1_i32 : i32
      %4132 = arith.remsi %4131, %c2_i32 : i32
      %coord_1034 = cute.make_coord(%4132) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1035 = cute.crd2idx(%coord_1034, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1036 = cute.add_offset(%iter_1029, %idx_1035) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1037 = cute.make_coord(%4118) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1038 = cute.crd2idx(%coord_1037, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb747(%c0_i32 : i32)
    ^bb747(%4133: i32):  // 2 preds: ^bb746, ^bb748
      %4134 = arith.cmpi slt, %4133, %2880 : i32
      cf.cond_br %4134, ^bb748, ^bb749 {llvm.loop_annotation = #loop_annotation}
    ^bb748:  // pred: ^bb747
      %coord_1039 = cute.make_coord(%4133) : (i32) -> !cute.coord<"(_,?)">
      %idx_1040 = cute.crd2idx(%coord_1039, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1041 = cute.add_offset(%ptr_1036, %idx_1040) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1042 = cute.crd2idx(%coord_1039, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1043 = cute.add_offset(%ptr_841, %idx_1042) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1044 = cute.apply_swizzle(%ptr_1043) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1045 = cute.add_offset(%swizzled_1044, %idx_1038) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4135 = builtin.unrealized_conversion_cast %ptr_1041 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4136 = builtin.unrealized_conversion_cast %ptr_1045 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4137 = llvm.load %4135 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4137, %4136 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4138 = arith.addi %4133, %c1_i32 : i32
      cf.br ^bb747(%4138 : i32)
    ^bb749:  // pred: ^bb747
      %int_tuple_1046 = cute.make_int_tuple(%4121) : (i32) -> !cute.int_tuple<"?">
      %ptr_1047 = cute.add_offset(%iter_46, %int_tuple_1046) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4139 = builtin.unrealized_conversion_cast %ptr_1047 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4139, %4122, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4140 = arith.addi %4121, %c1_i32 : i32
      %4141 = arith.addi %4120, %c1_i32 : i32
      %4142 = arith.cmpi eq, %4140, %c5_i32 : i32
      %4143 = arith.select %4142, %c0_i32, %4140 : i32
      cf.cond_br %4142, ^bb750, ^bb751
    ^bb750:  // pred: ^bb749
      %4144 = arith.xori %4122, %c1_i32 : i32
      cf.br ^bb752(%4144 : i32)
    ^bb751:  // pred: ^bb749
      cf.br ^bb752(%4122 : i32)
    ^bb752(%4145: i32):  // 2 preds: ^bb750, ^bb751
      cf.br ^bb753
    ^bb753:  // pred: ^bb752
      %coord_1048 = cute.make_coord(%4121) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1049 = cute.crd2idx(%coord_1048, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1050 = cute.add_offset(%ptr_840, %idx_1049) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %4146 = arith.remsi %4116, %c2_i32 : i32
      %coord_1051 = cute.make_coord(%4146) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1052 = cute.crd2idx(%coord_1051, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1053 = cute.add_offset(%iter_1021, %idx_1052) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      cf.br ^bb754(%c0_i32 : i32)
    ^bb754(%4147: i32):  // 2 preds: ^bb753, ^bb755
      %4148 = arith.cmpi slt, %4147, %2878 : i32
      cf.cond_br %4148, ^bb755, ^bb756 {llvm.loop_annotation = #loop_annotation}
    ^bb755:  // pred: ^bb754
      %coord_1054 = cute.make_coord(%4147) : (i32) -> !cute.coord<"(_,?)">
      %idx_1055 = cute.crd2idx(%coord_1054, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1056 = cute.add_offset(%ptr_1050, %idx_1055) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1057 = cute.crd2idx(%coord_1054, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1058 = cute.add_offset(%ptr_1053, %idx_1057) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %4149 = builtin.unrealized_conversion_cast %ptr_1056 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %4150 = builtin.unrealized_conversion_cast %ptr_1058 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %4151 = llvm.load %4149 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %4151, %4150 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %4152 = arith.addi %4147, %c1_i32 : i32
      cf.br ^bb754(%4152 : i32)
    ^bb756:  // pred: ^bb754
      %view_1059 = cute.make_view(%ptr_1053) : !memref_rmem_i8_1
      %4153 = cute.memref.load_vec %view_1059 : !memref_rmem_i8_1
      %4154 = vector.extract_strided_slice %4153 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4155 = llvm.bitcast %4154 : vector<4xi8> to i32
      %4156 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4155, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4157 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4155, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4158 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4155, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4159 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4155, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4160 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4156 : (i32) -> f32
      %4161 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4157 : (i32) -> f32
      %4162 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4158 : (i32) -> f32
      %4163 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4159 : (i32) -> f32
      %4164 = vector.from_elements %4160, %4161, %4162, %4163 : vector<4xf32>
      %4165 = vector.extract_strided_slice %4164 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4166 = vector.extract_strided_slice %4164 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4167 = vector.extractelement %4165[%c0_i32 : i32] : vector<2xf32>
      %4168 = vector.extractelement %4165[%c1_i32 : i32] : vector<2xf32>
      %4169 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4168, %4167 : (f32, f32) -> i32
      %4170 = llvm.bitcast %4169 : i32 to vector<2xbf16>
      %4171 = vector.extractelement %4166[%c0_i32 : i32] : vector<2xf32>
      %4172 = vector.extractelement %4166[%c1_i32 : i32] : vector<2xf32>
      %4173 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4172, %4171 : (f32, f32) -> i32
      %4174 = llvm.bitcast %4173 : i32 to vector<2xbf16>
      %4175 = vector.insert_strided_slice %4170, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4176 = vector.insert_strided_slice %4174, %4175 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4177 = vector.extract_strided_slice %4153 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4178 = llvm.bitcast %4177 : vector<4xi8> to i32
      %4179 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4178, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4180 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4178, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4181 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4178, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4182 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4178, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4183 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4179 : (i32) -> f32
      %4184 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4180 : (i32) -> f32
      %4185 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4181 : (i32) -> f32
      %4186 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4182 : (i32) -> f32
      %4187 = vector.from_elements %4183, %4184, %4185, %4186 : vector<4xf32>
      %4188 = vector.extract_strided_slice %4187 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4189 = vector.extract_strided_slice %4187 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4190 = vector.extractelement %4188[%c0_i32 : i32] : vector<2xf32>
      %4191 = vector.extractelement %4188[%c1_i32 : i32] : vector<2xf32>
      %4192 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4191, %4190 : (f32, f32) -> i32
      %4193 = llvm.bitcast %4192 : i32 to vector<2xbf16>
      %4194 = vector.extractelement %4189[%c0_i32 : i32] : vector<2xf32>
      %4195 = vector.extractelement %4189[%c1_i32 : i32] : vector<2xf32>
      %4196 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4195, %4194 : (f32, f32) -> i32
      %4197 = llvm.bitcast %4196 : i32 to vector<2xbf16>
      %4198 = vector.insert_strided_slice %4193, %4176 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4199 = vector.insert_strided_slice %4197, %4198 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4200 = vector.extract_strided_slice %4153 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4201 = llvm.bitcast %4200 : vector<4xi8> to i32
      %4202 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4201, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4203 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4201, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4204 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4201, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4205 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4201, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4206 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4202 : (i32) -> f32
      %4207 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4203 : (i32) -> f32
      %4208 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4204 : (i32) -> f32
      %4209 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4205 : (i32) -> f32
      %4210 = vector.from_elements %4206, %4207, %4208, %4209 : vector<4xf32>
      %4211 = vector.extract_strided_slice %4210 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4212 = vector.extract_strided_slice %4210 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4213 = vector.extractelement %4211[%c0_i32 : i32] : vector<2xf32>
      %4214 = vector.extractelement %4211[%c1_i32 : i32] : vector<2xf32>
      %4215 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4214, %4213 : (f32, f32) -> i32
      %4216 = llvm.bitcast %4215 : i32 to vector<2xbf16>
      %4217 = vector.extractelement %4212[%c0_i32 : i32] : vector<2xf32>
      %4218 = vector.extractelement %4212[%c1_i32 : i32] : vector<2xf32>
      %4219 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4218, %4217 : (f32, f32) -> i32
      %4220 = llvm.bitcast %4219 : i32 to vector<2xbf16>
      %4221 = vector.insert_strided_slice %4216, %4199 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4222 = vector.insert_strided_slice %4220, %4221 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4223 = vector.extract_strided_slice %4153 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4224 = llvm.bitcast %4223 : vector<4xi8> to i32
      %4225 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4224, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4226 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4224, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4227 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4224, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4228 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4224, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4229 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4225 : (i32) -> f32
      %4230 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4226 : (i32) -> f32
      %4231 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4227 : (i32) -> f32
      %4232 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4228 : (i32) -> f32
      %4233 = vector.from_elements %4229, %4230, %4231, %4232 : vector<4xf32>
      %4234 = vector.extract_strided_slice %4233 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4235 = vector.extract_strided_slice %4233 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4236 = vector.extractelement %4234[%c0_i32 : i32] : vector<2xf32>
      %4237 = vector.extractelement %4234[%c1_i32 : i32] : vector<2xf32>
      %4238 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4237, %4236 : (f32, f32) -> i32
      %4239 = llvm.bitcast %4238 : i32 to vector<2xbf16>
      %4240 = vector.extractelement %4235[%c0_i32 : i32] : vector<2xf32>
      %4241 = vector.extractelement %4235[%c1_i32 : i32] : vector<2xf32>
      %4242 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4241, %4240 : (f32, f32) -> i32
      %4243 = llvm.bitcast %4242 : i32 to vector<2xbf16>
      %4244 = vector.insert_strided_slice %4239, %4222 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4245 = vector.insert_strided_slice %4243, %4244 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4246 = vector.extract_strided_slice %4153 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4247 = llvm.bitcast %4246 : vector<4xi8> to i32
      %4248 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4247, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4249 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4247, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4250 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4247, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4251 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4247, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4252 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4248 : (i32) -> f32
      %4253 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4249 : (i32) -> f32
      %4254 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4250 : (i32) -> f32
      %4255 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4251 : (i32) -> f32
      %4256 = vector.from_elements %4252, %4253, %4254, %4255 : vector<4xf32>
      %4257 = vector.extract_strided_slice %4256 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4258 = vector.extract_strided_slice %4256 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4259 = vector.extractelement %4257[%c0_i32 : i32] : vector<2xf32>
      %4260 = vector.extractelement %4257[%c1_i32 : i32] : vector<2xf32>
      %4261 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4260, %4259 : (f32, f32) -> i32
      %4262 = llvm.bitcast %4261 : i32 to vector<2xbf16>
      %4263 = vector.extractelement %4258[%c0_i32 : i32] : vector<2xf32>
      %4264 = vector.extractelement %4258[%c1_i32 : i32] : vector<2xf32>
      %4265 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4264, %4263 : (f32, f32) -> i32
      %4266 = llvm.bitcast %4265 : i32 to vector<2xbf16>
      %4267 = vector.insert_strided_slice %4262, %4245 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4268 = vector.insert_strided_slice %4266, %4267 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4269 = vector.extract_strided_slice %4153 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4270 = llvm.bitcast %4269 : vector<4xi8> to i32
      %4271 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4270, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4272 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4270, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4273 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4270, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4274 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4270, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4275 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4271 : (i32) -> f32
      %4276 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4272 : (i32) -> f32
      %4277 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4273 : (i32) -> f32
      %4278 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4274 : (i32) -> f32
      %4279 = vector.from_elements %4275, %4276, %4277, %4278 : vector<4xf32>
      %4280 = vector.extract_strided_slice %4279 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4281 = vector.extract_strided_slice %4279 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4282 = vector.extractelement %4280[%c0_i32 : i32] : vector<2xf32>
      %4283 = vector.extractelement %4280[%c1_i32 : i32] : vector<2xf32>
      %4284 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4283, %4282 : (f32, f32) -> i32
      %4285 = llvm.bitcast %4284 : i32 to vector<2xbf16>
      %4286 = vector.extractelement %4281[%c0_i32 : i32] : vector<2xf32>
      %4287 = vector.extractelement %4281[%c1_i32 : i32] : vector<2xf32>
      %4288 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4287, %4286 : (f32, f32) -> i32
      %4289 = llvm.bitcast %4288 : i32 to vector<2xbf16>
      %4290 = vector.insert_strided_slice %4285, %4268 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4291 = vector.insert_strided_slice %4289, %4290 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4292 = vector.extract_strided_slice %4153 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4293 = llvm.bitcast %4292 : vector<4xi8> to i32
      %4294 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4293, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4295 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4293, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4296 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4293, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4297 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4293, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4298 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4294 : (i32) -> f32
      %4299 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4295 : (i32) -> f32
      %4300 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4296 : (i32) -> f32
      %4301 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4297 : (i32) -> f32
      %4302 = vector.from_elements %4298, %4299, %4300, %4301 : vector<4xf32>
      %4303 = vector.extract_strided_slice %4302 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4304 = vector.extract_strided_slice %4302 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4305 = vector.extractelement %4303[%c0_i32 : i32] : vector<2xf32>
      %4306 = vector.extractelement %4303[%c1_i32 : i32] : vector<2xf32>
      %4307 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4306, %4305 : (f32, f32) -> i32
      %4308 = llvm.bitcast %4307 : i32 to vector<2xbf16>
      %4309 = vector.extractelement %4304[%c0_i32 : i32] : vector<2xf32>
      %4310 = vector.extractelement %4304[%c1_i32 : i32] : vector<2xf32>
      %4311 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4310, %4309 : (f32, f32) -> i32
      %4312 = llvm.bitcast %4311 : i32 to vector<2xbf16>
      %4313 = vector.insert_strided_slice %4308, %4291 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4314 = vector.insert_strided_slice %4312, %4313 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4315 = vector.extract_strided_slice %4153 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4316 = llvm.bitcast %4315 : vector<4xi8> to i32
      %4317 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4316, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4318 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4316, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4319 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4316, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4320 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4316, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4321 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4317 : (i32) -> f32
      %4322 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4318 : (i32) -> f32
      %4323 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4319 : (i32) -> f32
      %4324 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4320 : (i32) -> f32
      %4325 = vector.from_elements %4321, %4322, %4323, %4324 : vector<4xf32>
      %4326 = vector.extract_strided_slice %4325 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4327 = vector.extract_strided_slice %4325 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4328 = vector.extractelement %4326[%c0_i32 : i32] : vector<2xf32>
      %4329 = vector.extractelement %4326[%c1_i32 : i32] : vector<2xf32>
      %4330 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4329, %4328 : (f32, f32) -> i32
      %4331 = llvm.bitcast %4330 : i32 to vector<2xbf16>
      %4332 = vector.extractelement %4327[%c0_i32 : i32] : vector<2xf32>
      %4333 = vector.extractelement %4327[%c1_i32 : i32] : vector<2xf32>
      %4334 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4333, %4332 : (f32, f32) -> i32
      %4335 = llvm.bitcast %4334 : i32 to vector<2xbf16>
      %4336 = vector.insert_strided_slice %4331, %4314 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4337 = vector.insert_strided_slice %4335, %4336 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4338 = arith.divsi %4116, %c2_i32 : i32
      %4339 = arith.muli %4338, %c2_i32 : i32
      %4340 = arith.cmpi ne, %4116, %4339 : i32
      %c0_i32_1060 = arith.constant 0 : i32
      %4341 = arith.cmpi slt, %4116, %c0_i32_1060 : i32
      %4342 = arith.cmpi slt, %c2_i32, %c0_i32_1060 : i32
      %4343 = arith.cmpi ne, %4341, %4342 : i1
      %4344 = arith.andi %4340, %4343 : i1
      %c-1_i32_1061 = arith.constant -1 : i32
      %4345 = arith.addi %4338, %c-1_i32_1061 : i32
      %4346 = arith.select %4344, %4345, %4338 : i32
      %coord_1062 = cute.make_coord(%247, %4146, %4346) : (i32, i32, i32) -> !cute.coord<"(_,_,_,_,(?,?),?)">
      %idx_1063 = cute.crd2idx(%coord_1062, %4) : (!cute.coord<"(_,_,_,_,(?,?),?)">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">) -> !cute.int_tuple<"?">
      %ptr_1064 = cute.add_offset(%iter_1009, %idx_1063) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %view_1065 = cute.make_view(%ptr_1064) : !memref_rmem_bf16_8
      %4347 = cute.memref.load_vec %view_1065 : !memref_rmem_bf16_8
      %4348 = arith.mulf %4337, %4347 : vector<32xbf16>
      %ptr_1066 = cute.add_offset(%iter_1029, %idx_1052) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_1067 = cute.make_view(%ptr_1066) : !memref_rmem_bf16_5
      cute.memref.store_vec %4348, %view_1067 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1068 = cute.add_offset(%ptr_51, %int_tuple_1046) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4349 = builtin.unrealized_conversion_cast %ptr_1068 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4349, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_1069 = cute.add_offset(%iter_93, %int_tuple_1032) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4350 = builtin.unrealized_conversion_cast %ptr_1069 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4351 = nvvm.mapa.shared.cluster %4350, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4351, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %4352 = arith.addi %4116, %c1_i32 : i32
      cf.br ^bb741(%4352, %4126, %4128, %4130, %4141, %4143, %4145 : i32, i32, i32, i32, i32, i32, i32)
    ^bb757:  // pred: ^bb741
      %int_tuple_1070 = cute.make_int_tuple(%4118) : (i32) -> !cute.int_tuple<"?">
      %ptr_1071 = cute.add_offset(%ptr_96, %int_tuple_1070) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4353 = builtin.unrealized_conversion_cast %ptr_1071 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4353, %4119, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4354 = arith.addi %4118, %c1_i32 : i32
      %4355 = arith.addi %4117, %c1_i32 : i32
      %4356 = arith.cmpi eq, %4354, %c3_i32 : i32
      %4357 = arith.select %4356, %c0_i32, %4354 : i32
      cf.cond_br %4356, ^bb758, ^bb759
    ^bb758:  // pred: ^bb757
      %4358 = arith.xori %4119, %c1_i32 : i32
      cf.br ^bb760(%4358 : i32)
    ^bb759:  // pred: ^bb757
      cf.br ^bb760(%4119 : i32)
    ^bb760(%4359: i32):  // 2 preds: ^bb758, ^bb759
      cf.br ^bb761
    ^bb761:  // pred: ^bb760
      %ptr_1072 = cute.add_offset(%iter_1029, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1073 = cute.make_coord(%4118) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1074 = cute.crd2idx(%coord_1073, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb762(%c0_i32 : i32)
    ^bb762(%4360: i32):  // 2 preds: ^bb761, ^bb763
      %4361 = arith.cmpi slt, %4360, %2880 : i32
      cf.cond_br %4361, ^bb763, ^bb764 {llvm.loop_annotation = #loop_annotation}
    ^bb763:  // pred: ^bb762
      %coord_1075 = cute.make_coord(%4360) : (i32) -> !cute.coord<"(_,?)">
      %idx_1076 = cute.crd2idx(%coord_1075, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1077 = cute.add_offset(%ptr_1072, %idx_1076) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1078 = cute.crd2idx(%coord_1075, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1079 = cute.add_offset(%ptr_841, %idx_1078) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1080 = cute.apply_swizzle(%ptr_1079) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1081 = cute.add_offset(%swizzled_1080, %idx_1074) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4362 = builtin.unrealized_conversion_cast %ptr_1077 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4363 = builtin.unrealized_conversion_cast %ptr_1081 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4364 = llvm.load %4362 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4364, %4363 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4365 = arith.addi %4360, %c1_i32 : i32
      cf.br ^bb762(%4365 : i32)
    ^bb764:  // pred: ^bb762
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1082 = cute.add_offset(%iter_93, %int_tuple_1070) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4366 = builtin.unrealized_conversion_cast %ptr_1082 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4367 = nvvm.mapa.shared.cluster %4366, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4367, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_1083 = cute.add_offset(%ptr_82, %int_tuple_1005) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4368 = builtin.unrealized_conversion_cast %ptr_1083 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4368, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %4369 = arith.addi %3398, %c1_i32 : i32
      cf.br ^bb687(%4369, %4120, %4121, %4122, %3415, %3417, %3419, %4355, %4357, %4359, %3889, %3891, %3893 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb765:  // pred: ^bb687
      %4370 = cute.make_tiled_copy(%atom_826) : !copy_simt2
      %rmem_1084 = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_1085 = cute.memref.alloca() : !memref_rmem_bf16_2
      %rmem_1086 = cute.memref.alloca() : !memref_rmem_bf16_6
      %int_tuple_1087 = cute.make_int_tuple(%3409) : (i32) -> !cute.int_tuple<"?">
      %ptr_1088 = cute.add_offset(%iter_77, %int_tuple_1087) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4371 = builtin.unrealized_conversion_cast %ptr_1088 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4371, %3410, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4372 = arith.addi %3409, %c1_i32 : i32
      %4373 = arith.addi %3408, %c1_i32 : i32
      %4374 = arith.cmpi eq, %4372, %c5_i32 : i32
      %4375 = arith.select %4374, %c0_i32, %4372 : i32
      cf.cond_br %4374, ^bb766, ^bb767
    ^bb766:  // pred: ^bb765
      %4376 = arith.xori %3410, %c1_i32 : i32
      cf.br ^bb768(%4376 : i32)
    ^bb767:  // pred: ^bb765
      cf.br ^bb768(%3410 : i32)
    ^bb768(%4377: i32):  // 2 preds: ^bb766, ^bb767
      cf.br ^bb769
    ^bb769:  // pred: ^bb768
      %coord_1089 = cute.make_coord(%3409) : (i32) -> !cute.coord<"(_,_,_,_,_,(_,?))">
      %idx_1090 = cute.crd2idx(%coord_1089, %3) : (!cute.coord<"(_,_,_,_,_,(_,?))">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),(4,5)):((0,0),0,0,0,(0,(0,1)),(64,256))">) -> !cute.int_tuple<"?{div=256}">
      %iter_1091 = cute.get_iter(%rmem_1086) : !memref_rmem_bf16_6
      cf.br ^bb770(%c0_i32 : i32)
    ^bb770(%4378: i32):  // 2 preds: ^bb769, ^bb771
      %4379 = arith.cmpi slt, %4378, %2898 : i32
      cf.cond_br %4379, ^bb771, ^bb772 {llvm.loop_annotation = #loop_annotation}
    ^bb771:  // pred: ^bb770
      %coord_1092 = cute.make_coord(%4378) : (i32) -> !cute.coord<"(_,?)">
      %idx_1093 = cute.crd2idx(%coord_1092, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,1)),64))">) -> !cute.int_tuple<"?">
      %ptr_1094 = cute.add_offset(%ptr_849, %idx_1093) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, smem>
      %ptr_1095 = cute.add_offset(%ptr_1094, %idx_1090) : (!cute.ptr<bf16, smem>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<bf16, smem>
      %idx_1096 = cute.crd2idx(%coord_1092, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4,4),(2,1,1,(2,(2,1)),4)):((0,0),(0,0,0,(0,(0,0)),1))">) -> !cute.int_tuple<"?">
      %ptr_1097 = cute.add_offset(%iter_1091, %idx_1096) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %4380 = builtin.unrealized_conversion_cast %ptr_1095 : !cute.ptr<bf16, smem> to !llvm.ptr<3>
      %4381 = builtin.unrealized_conversion_cast %ptr_1097 : !cute.ptr<bf16, rmem> to !llvm.ptr
      %4382 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4382, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4383 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4383, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4384 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4384, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4385 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4385, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4386 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4386, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4387 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4387, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4388 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4388, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4389 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4389, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4390 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4390, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4391 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4391, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4392 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4392, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4393 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4393, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4394 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4394, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4395 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4395, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4396 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4396, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4397 = llvm.load %4380 {alignment = 2 : i64} : !llvm.ptr<3> -> vector<1xbf16>
      llvm.store %4397, %4381 {alignment = 2 : i64} : vector<1xbf16>, !llvm.ptr
      %4398 = arith.addi %4378, %c1_i32 : i32
      cf.br ^bb770(%4398 : i32)
    ^bb772:  // pred: ^bb770
      %int_tuple_1098 = cute.make_int_tuple(%3400) : (i32) -> !cute.int_tuple<"?">
      %ptr_1099 = cute.add_offset(%iter_46, %int_tuple_1098) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4399 = builtin.unrealized_conversion_cast %ptr_1099 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4399, %3401, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4400 = arith.addi %3400, %c1_i32 : i32
      %4401 = arith.addi %3399, %c1_i32 : i32
      %4402 = arith.cmpi eq, %4400, %c5_i32 : i32
      %4403 = arith.select %4402, %c0_i32, %4400 : i32
      cf.cond_br %4402, ^bb773, ^bb774
    ^bb773:  // pred: ^bb772
      %4404 = arith.xori %3401, %c1_i32 : i32
      cf.br ^bb775(%4404 : i32)
    ^bb774:  // pred: ^bb772
      cf.br ^bb775(%3401 : i32)
    ^bb775(%4405: i32):  // 2 preds: ^bb773, ^bb774
      cf.br ^bb776
    ^bb776:  // pred: ^bb775
      %coord_1100 = cute.make_coord(%3400) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1101 = cute.crd2idx(%coord_1100, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1102 = cute.add_offset(%ptr_846, %idx_1101) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %iter_1103 = cute.get_iter(%rmem_1084) : !memref_rmem_i8_
      cf.br ^bb777(%c0_i32 : i32)
    ^bb777(%4406: i32):  // 2 preds: ^bb776, ^bb778
      %4407 = arith.cmpi slt, %4406, %2878 : i32
      cf.cond_br %4407, ^bb778, ^bb779 {llvm.loop_annotation = #loop_annotation}
    ^bb778:  // pred: ^bb777
      %coord_1104 = cute.make_coord(%4406) : (i32) -> !cute.coord<"(_,?)">
      %idx_1105 = cute.crd2idx(%coord_1104, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1106 = cute.add_offset(%ptr_1102, %idx_1105) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1107 = cute.crd2idx(%coord_1104, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1108 = cute.add_offset(%iter_1103, %idx_1107) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %4408 = builtin.unrealized_conversion_cast %ptr_1106 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %4409 = builtin.unrealized_conversion_cast %ptr_1108 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %4410 = llvm.load %4408 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %4410, %4409 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %4411 = arith.addi %4406, %c1_i32 : i32
      cf.br ^bb777(%4411 : i32)
    ^bb779:  // pred: ^bb777
      %view_1109 = cute.make_view(%iter_1103) : !memref_rmem_i8_1
      %4412 = cute.memref.load_vec %view_1109 : !memref_rmem_i8_1
      %4413 = vector.extract_strided_slice %4412 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4414 = llvm.bitcast %4413 : vector<4xi8> to i32
      %4415 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4414, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4416 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4414, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4417 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4414, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4418 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4414, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4419 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4415 : (i32) -> f32
      %4420 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4416 : (i32) -> f32
      %4421 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4417 : (i32) -> f32
      %4422 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4418 : (i32) -> f32
      %4423 = vector.from_elements %4419, %4420, %4421, %4422 : vector<4xf32>
      %4424 = vector.extract_strided_slice %4423 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4425 = vector.extract_strided_slice %4423 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4426 = vector.extractelement %4424[%c0_i32 : i32] : vector<2xf32>
      %4427 = vector.extractelement %4424[%c1_i32 : i32] : vector<2xf32>
      %4428 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4427, %4426 : (f32, f32) -> i32
      %4429 = llvm.bitcast %4428 : i32 to vector<2xbf16>
      %4430 = vector.extractelement %4425[%c0_i32 : i32] : vector<2xf32>
      %4431 = vector.extractelement %4425[%c1_i32 : i32] : vector<2xf32>
      %4432 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4431, %4430 : (f32, f32) -> i32
      %4433 = llvm.bitcast %4432 : i32 to vector<2xbf16>
      %4434 = vector.insert_strided_slice %4429, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4435 = vector.insert_strided_slice %4433, %4434 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4436 = vector.extract_strided_slice %4412 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4437 = llvm.bitcast %4436 : vector<4xi8> to i32
      %4438 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4437, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4439 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4437, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4440 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4437, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4441 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4437, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4442 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4438 : (i32) -> f32
      %4443 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4439 : (i32) -> f32
      %4444 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4440 : (i32) -> f32
      %4445 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4441 : (i32) -> f32
      %4446 = vector.from_elements %4442, %4443, %4444, %4445 : vector<4xf32>
      %4447 = vector.extract_strided_slice %4446 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4448 = vector.extract_strided_slice %4446 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4449 = vector.extractelement %4447[%c0_i32 : i32] : vector<2xf32>
      %4450 = vector.extractelement %4447[%c1_i32 : i32] : vector<2xf32>
      %4451 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4450, %4449 : (f32, f32) -> i32
      %4452 = llvm.bitcast %4451 : i32 to vector<2xbf16>
      %4453 = vector.extractelement %4448[%c0_i32 : i32] : vector<2xf32>
      %4454 = vector.extractelement %4448[%c1_i32 : i32] : vector<2xf32>
      %4455 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4454, %4453 : (f32, f32) -> i32
      %4456 = llvm.bitcast %4455 : i32 to vector<2xbf16>
      %4457 = vector.insert_strided_slice %4452, %4435 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4458 = vector.insert_strided_slice %4456, %4457 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4459 = vector.extract_strided_slice %4412 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4460 = llvm.bitcast %4459 : vector<4xi8> to i32
      %4461 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4460, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4462 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4460, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4463 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4460, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4464 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4460, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4465 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4461 : (i32) -> f32
      %4466 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4462 : (i32) -> f32
      %4467 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4463 : (i32) -> f32
      %4468 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4464 : (i32) -> f32
      %4469 = vector.from_elements %4465, %4466, %4467, %4468 : vector<4xf32>
      %4470 = vector.extract_strided_slice %4469 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4471 = vector.extract_strided_slice %4469 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4472 = vector.extractelement %4470[%c0_i32 : i32] : vector<2xf32>
      %4473 = vector.extractelement %4470[%c1_i32 : i32] : vector<2xf32>
      %4474 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4473, %4472 : (f32, f32) -> i32
      %4475 = llvm.bitcast %4474 : i32 to vector<2xbf16>
      %4476 = vector.extractelement %4471[%c0_i32 : i32] : vector<2xf32>
      %4477 = vector.extractelement %4471[%c1_i32 : i32] : vector<2xf32>
      %4478 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4477, %4476 : (f32, f32) -> i32
      %4479 = llvm.bitcast %4478 : i32 to vector<2xbf16>
      %4480 = vector.insert_strided_slice %4475, %4458 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4481 = vector.insert_strided_slice %4479, %4480 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4482 = vector.extract_strided_slice %4412 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4483 = llvm.bitcast %4482 : vector<4xi8> to i32
      %4484 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4483, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4485 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4483, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4486 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4483, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4487 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4483, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4488 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4484 : (i32) -> f32
      %4489 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4485 : (i32) -> f32
      %4490 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4486 : (i32) -> f32
      %4491 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4487 : (i32) -> f32
      %4492 = vector.from_elements %4488, %4489, %4490, %4491 : vector<4xf32>
      %4493 = vector.extract_strided_slice %4492 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4494 = vector.extract_strided_slice %4492 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4495 = vector.extractelement %4493[%c0_i32 : i32] : vector<2xf32>
      %4496 = vector.extractelement %4493[%c1_i32 : i32] : vector<2xf32>
      %4497 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4496, %4495 : (f32, f32) -> i32
      %4498 = llvm.bitcast %4497 : i32 to vector<2xbf16>
      %4499 = vector.extractelement %4494[%c0_i32 : i32] : vector<2xf32>
      %4500 = vector.extractelement %4494[%c1_i32 : i32] : vector<2xf32>
      %4501 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4500, %4499 : (f32, f32) -> i32
      %4502 = llvm.bitcast %4501 : i32 to vector<2xbf16>
      %4503 = vector.insert_strided_slice %4498, %4481 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4504 = vector.insert_strided_slice %4502, %4503 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4505 = vector.extract_strided_slice %4412 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4506 = llvm.bitcast %4505 : vector<4xi8> to i32
      %4507 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4506, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4508 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4506, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4509 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4506, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4510 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4506, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4511 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4507 : (i32) -> f32
      %4512 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4508 : (i32) -> f32
      %4513 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4509 : (i32) -> f32
      %4514 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4510 : (i32) -> f32
      %4515 = vector.from_elements %4511, %4512, %4513, %4514 : vector<4xf32>
      %4516 = vector.extract_strided_slice %4515 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4517 = vector.extract_strided_slice %4515 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4518 = vector.extractelement %4516[%c0_i32 : i32] : vector<2xf32>
      %4519 = vector.extractelement %4516[%c1_i32 : i32] : vector<2xf32>
      %4520 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4519, %4518 : (f32, f32) -> i32
      %4521 = llvm.bitcast %4520 : i32 to vector<2xbf16>
      %4522 = vector.extractelement %4517[%c0_i32 : i32] : vector<2xf32>
      %4523 = vector.extractelement %4517[%c1_i32 : i32] : vector<2xf32>
      %4524 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4523, %4522 : (f32, f32) -> i32
      %4525 = llvm.bitcast %4524 : i32 to vector<2xbf16>
      %4526 = vector.insert_strided_slice %4521, %4504 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4527 = vector.insert_strided_slice %4525, %4526 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4528 = vector.extract_strided_slice %4412 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4529 = llvm.bitcast %4528 : vector<4xi8> to i32
      %4530 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4529, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4531 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4529, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4532 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4529, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4533 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4529, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4534 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4530 : (i32) -> f32
      %4535 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4531 : (i32) -> f32
      %4536 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4532 : (i32) -> f32
      %4537 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4533 : (i32) -> f32
      %4538 = vector.from_elements %4534, %4535, %4536, %4537 : vector<4xf32>
      %4539 = vector.extract_strided_slice %4538 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4540 = vector.extract_strided_slice %4538 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4541 = vector.extractelement %4539[%c0_i32 : i32] : vector<2xf32>
      %4542 = vector.extractelement %4539[%c1_i32 : i32] : vector<2xf32>
      %4543 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4542, %4541 : (f32, f32) -> i32
      %4544 = llvm.bitcast %4543 : i32 to vector<2xbf16>
      %4545 = vector.extractelement %4540[%c0_i32 : i32] : vector<2xf32>
      %4546 = vector.extractelement %4540[%c1_i32 : i32] : vector<2xf32>
      %4547 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4546, %4545 : (f32, f32) -> i32
      %4548 = llvm.bitcast %4547 : i32 to vector<2xbf16>
      %4549 = vector.insert_strided_slice %4544, %4527 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4550 = vector.insert_strided_slice %4548, %4549 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4551 = vector.extract_strided_slice %4412 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4552 = llvm.bitcast %4551 : vector<4xi8> to i32
      %4553 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4552, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4554 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4552, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4555 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4552, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4556 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4552, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4557 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4553 : (i32) -> f32
      %4558 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4554 : (i32) -> f32
      %4559 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4555 : (i32) -> f32
      %4560 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4556 : (i32) -> f32
      %4561 = vector.from_elements %4557, %4558, %4559, %4560 : vector<4xf32>
      %4562 = vector.extract_strided_slice %4561 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4563 = vector.extract_strided_slice %4561 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4564 = vector.extractelement %4562[%c0_i32 : i32] : vector<2xf32>
      %4565 = vector.extractelement %4562[%c1_i32 : i32] : vector<2xf32>
      %4566 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4565, %4564 : (f32, f32) -> i32
      %4567 = llvm.bitcast %4566 : i32 to vector<2xbf16>
      %4568 = vector.extractelement %4563[%c0_i32 : i32] : vector<2xf32>
      %4569 = vector.extractelement %4563[%c1_i32 : i32] : vector<2xf32>
      %4570 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4569, %4568 : (f32, f32) -> i32
      %4571 = llvm.bitcast %4570 : i32 to vector<2xbf16>
      %4572 = vector.insert_strided_slice %4567, %4550 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4573 = vector.insert_strided_slice %4571, %4572 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4574 = vector.extract_strided_slice %4412 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4575 = llvm.bitcast %4574 : vector<4xi8> to i32
      %4576 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4575, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4577 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4575, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4578 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4575, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4579 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4575, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4580 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4576 : (i32) -> f32
      %4581 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4577 : (i32) -> f32
      %4582 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4578 : (i32) -> f32
      %4583 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4579 : (i32) -> f32
      %4584 = vector.from_elements %4580, %4581, %4582, %4583 : vector<4xf32>
      %4585 = vector.extract_strided_slice %4584 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4586 = vector.extract_strided_slice %4584 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4587 = vector.extractelement %4585[%c0_i32 : i32] : vector<2xf32>
      %4588 = vector.extractelement %4585[%c1_i32 : i32] : vector<2xf32>
      %4589 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4588, %4587 : (f32, f32) -> i32
      %4590 = llvm.bitcast %4589 : i32 to vector<2xbf16>
      %4591 = vector.extractelement %4586[%c0_i32 : i32] : vector<2xf32>
      %4592 = vector.extractelement %4586[%c1_i32 : i32] : vector<2xf32>
      %4593 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4592, %4591 : (f32, f32) -> i32
      %4594 = llvm.bitcast %4593 : i32 to vector<2xbf16>
      %4595 = vector.insert_strided_slice %4590, %4573 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4596 = vector.insert_strided_slice %4594, %4595 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %view_1110 = cute.make_view(%iter_1091) : !memref_rmem_bf16_7
      %4597 = cute.memref.load_vec %view_1110 : !memref_rmem_bf16_7
      %4598 = arith.mulf %4596, %4597 : vector<32xbf16>
      %iter_1111 = cute.get_iter(%rmem_1085) : !memref_rmem_bf16_2
      %view_1112 = cute.make_view(%iter_1111) : !memref_rmem_bf16_5
      cute.memref.store_vec %4598, %view_1112 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1113 = cute.add_offset(%ptr_51, %int_tuple_1098) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4599 = builtin.unrealized_conversion_cast %ptr_1113 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4599, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb780(%c1_i32, %3405, %3406, %3407, %4401, %4403, %4405 : i32, i32, i32, i32, i32, i32, i32)
    ^bb780(%4600: i32, %4601: i32, %4602: i32, %4603: i32, %4604: i32, %4605: i32, %4606: i32):  // 2 preds: ^bb779, ^bb795
      %4607 = arith.cmpi slt, %4600, %c8_i32 : i32
      cf.cond_br %4607, ^bb781, ^bb796 {loop_annotation = #loop_annotation1}
    ^bb781:  // pred: ^bb780
      %int_tuple_1114 = cute.make_int_tuple(%4602) : (i32) -> !cute.int_tuple<"?">
      %ptr_1115 = cute.add_offset(%ptr_96, %int_tuple_1114) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4608 = builtin.unrealized_conversion_cast %ptr_1115 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4608, %4603, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4609 = arith.addi %4602, %c1_i32 : i32
      %4610 = arith.addi %4601, %c1_i32 : i32
      %4611 = arith.cmpi eq, %4609, %c3_i32 : i32
      %4612 = arith.select %4611, %c0_i32, %4609 : i32
      cf.cond_br %4611, ^bb782, ^bb783
    ^bb782:  // pred: ^bb781
      %4613 = arith.xori %4603, %c1_i32 : i32
      cf.br ^bb784(%4613 : i32)
    ^bb783:  // pred: ^bb781
      cf.br ^bb784(%4603 : i32)
    ^bb784(%4614: i32):  // 2 preds: ^bb782, ^bb783
      cf.br ^bb785
    ^bb785:  // pred: ^bb784
      %4615 = arith.subi %4600, %c1_i32 : i32
      %4616 = arith.remsi %4615, %c2_i32 : i32
      %coord_1116 = cute.make_coord(%4616) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1117 = cute.crd2idx(%coord_1116, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1118 = cute.add_offset(%iter_1111, %idx_1117) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1119 = cute.make_coord(%4602) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1120 = cute.crd2idx(%coord_1119, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb786(%c0_i32 : i32)
    ^bb786(%4617: i32):  // 2 preds: ^bb785, ^bb787
      %4618 = arith.cmpi slt, %4617, %2880 : i32
      cf.cond_br %4618, ^bb787, ^bb788 {llvm.loop_annotation = #loop_annotation}
    ^bb787:  // pred: ^bb786
      %coord_1121 = cute.make_coord(%4617) : (i32) -> !cute.coord<"(_,?)">
      %idx_1122 = cute.crd2idx(%coord_1121, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1123 = cute.add_offset(%ptr_1118, %idx_1122) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1124 = cute.crd2idx(%coord_1121, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1125 = cute.add_offset(%ptr_847, %idx_1124) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1126 = cute.apply_swizzle(%ptr_1125) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1127 = cute.add_offset(%swizzled_1126, %idx_1120) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4619 = builtin.unrealized_conversion_cast %ptr_1123 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4620 = builtin.unrealized_conversion_cast %ptr_1127 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4621 = llvm.load %4619 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4621, %4620 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4622 = arith.addi %4617, %c1_i32 : i32
      cf.br ^bb786(%4622 : i32)
    ^bb788:  // pred: ^bb786
      %int_tuple_1128 = cute.make_int_tuple(%4605) : (i32) -> !cute.int_tuple<"?">
      %ptr_1129 = cute.add_offset(%iter_46, %int_tuple_1128) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4623 = builtin.unrealized_conversion_cast %ptr_1129 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4623, %4606, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4624 = arith.addi %4605, %c1_i32 : i32
      %4625 = arith.addi %4604, %c1_i32 : i32
      %4626 = arith.cmpi eq, %4624, %c5_i32 : i32
      %4627 = arith.select %4626, %c0_i32, %4624 : i32
      cf.cond_br %4626, ^bb789, ^bb790
    ^bb789:  // pred: ^bb788
      %4628 = arith.xori %4606, %c1_i32 : i32
      cf.br ^bb791(%4628 : i32)
    ^bb790:  // pred: ^bb788
      cf.br ^bb791(%4606 : i32)
    ^bb791(%4629: i32):  // 2 preds: ^bb789, ^bb790
      cf.br ^bb792
    ^bb792:  // pred: ^bb791
      %coord_1130 = cute.make_coord(%4605) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1131 = cute.crd2idx(%coord_1130, %11) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,5):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_1132 = cute.add_offset(%ptr_846, %idx_1131) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<i8, smem, align<16>>
      %4630 = arith.remsi %4600, %c2_i32 : i32
      %coord_1133 = cute.make_coord(%4630) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1134 = cute.crd2idx(%coord_1133, %15) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,2):((1,4),16,0,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_1135 = cute.add_offset(%iter_1103, %idx_1134) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<i8, rmem, align<32>>
      cf.br ^bb793(%c0_i32 : i32)
    ^bb793(%4631: i32):  // 2 preds: ^bb792, ^bb794
      %4632 = arith.cmpi slt, %4631, %2878 : i32
      cf.cond_br %4632, ^bb794, ^bb795 {llvm.loop_annotation = #loop_annotation}
    ^bb794:  // pred: ^bb793
      %coord_1136 = cute.make_coord(%4631) : (i32) -> !cute.coord<"(_,?)">
      %idx_1137 = cute.crd2idx(%coord_1136, %10) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_1138 = cute.add_offset(%ptr_1132, %idx_1137) : (!cute.ptr<i8, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<i8, smem, align<16>>
      %idx_1139 = cute.crd2idx(%coord_1136, %16) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(2)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_1140 = cute.add_offset(%ptr_1135, %idx_1139) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i8, rmem, align<16>>
      %4633 = builtin.unrealized_conversion_cast %ptr_1138 : !cute.ptr<i8, smem, align<16>> to !llvm.ptr<3>
      %4634 = builtin.unrealized_conversion_cast %ptr_1140 : !cute.ptr<i8, rmem, align<16>> to !llvm.ptr
      %4635 = llvm.load %4633 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<16xi8>
      llvm.store %4635, %4634 {alignment = 16 : i64} : vector<16xi8>, !llvm.ptr
      %4636 = arith.addi %4631, %c1_i32 : i32
      cf.br ^bb793(%4636 : i32)
    ^bb795:  // pred: ^bb793
      %view_1141 = cute.make_view(%ptr_1135) : !memref_rmem_i8_1
      %4637 = cute.memref.load_vec %view_1141 : !memref_rmem_i8_1
      %4638 = vector.extract_strided_slice %4637 {offsets = [0], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4639 = llvm.bitcast %4638 : vector<4xi8> to i32
      %4640 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4639, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4641 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4639, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4642 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4639, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4643 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4639, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4644 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4640 : (i32) -> f32
      %4645 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4641 : (i32) -> f32
      %4646 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4642 : (i32) -> f32
      %4647 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4643 : (i32) -> f32
      %4648 = vector.from_elements %4644, %4645, %4646, %4647 : vector<4xf32>
      %4649 = vector.extract_strided_slice %4648 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4650 = vector.extract_strided_slice %4648 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4651 = vector.extractelement %4649[%c0_i32 : i32] : vector<2xf32>
      %4652 = vector.extractelement %4649[%c1_i32 : i32] : vector<2xf32>
      %4653 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4652, %4651 : (f32, f32) -> i32
      %4654 = llvm.bitcast %4653 : i32 to vector<2xbf16>
      %4655 = vector.extractelement %4650[%c0_i32 : i32] : vector<2xf32>
      %4656 = vector.extractelement %4650[%c1_i32 : i32] : vector<2xf32>
      %4657 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4656, %4655 : (f32, f32) -> i32
      %4658 = llvm.bitcast %4657 : i32 to vector<2xbf16>
      %4659 = vector.insert_strided_slice %4654, %9 {offsets = [0], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4660 = vector.insert_strided_slice %4658, %4659 {offsets = [2], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4661 = vector.extract_strided_slice %4637 {offsets = [4], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4662 = llvm.bitcast %4661 : vector<4xi8> to i32
      %4663 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4662, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4664 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4662, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4665 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4662, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4666 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4662, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4667 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4663 : (i32) -> f32
      %4668 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4664 : (i32) -> f32
      %4669 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4665 : (i32) -> f32
      %4670 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4666 : (i32) -> f32
      %4671 = vector.from_elements %4667, %4668, %4669, %4670 : vector<4xf32>
      %4672 = vector.extract_strided_slice %4671 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4673 = vector.extract_strided_slice %4671 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4674 = vector.extractelement %4672[%c0_i32 : i32] : vector<2xf32>
      %4675 = vector.extractelement %4672[%c1_i32 : i32] : vector<2xf32>
      %4676 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4675, %4674 : (f32, f32) -> i32
      %4677 = llvm.bitcast %4676 : i32 to vector<2xbf16>
      %4678 = vector.extractelement %4673[%c0_i32 : i32] : vector<2xf32>
      %4679 = vector.extractelement %4673[%c1_i32 : i32] : vector<2xf32>
      %4680 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4679, %4678 : (f32, f32) -> i32
      %4681 = llvm.bitcast %4680 : i32 to vector<2xbf16>
      %4682 = vector.insert_strided_slice %4677, %4660 {offsets = [4], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4683 = vector.insert_strided_slice %4681, %4682 {offsets = [6], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4684 = vector.extract_strided_slice %4637 {offsets = [8], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4685 = llvm.bitcast %4684 : vector<4xi8> to i32
      %4686 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4685, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4687 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4685, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4688 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4685, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4689 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4685, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4690 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4686 : (i32) -> f32
      %4691 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4687 : (i32) -> f32
      %4692 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4688 : (i32) -> f32
      %4693 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4689 : (i32) -> f32
      %4694 = vector.from_elements %4690, %4691, %4692, %4693 : vector<4xf32>
      %4695 = vector.extract_strided_slice %4694 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4696 = vector.extract_strided_slice %4694 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4697 = vector.extractelement %4695[%c0_i32 : i32] : vector<2xf32>
      %4698 = vector.extractelement %4695[%c1_i32 : i32] : vector<2xf32>
      %4699 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4698, %4697 : (f32, f32) -> i32
      %4700 = llvm.bitcast %4699 : i32 to vector<2xbf16>
      %4701 = vector.extractelement %4696[%c0_i32 : i32] : vector<2xf32>
      %4702 = vector.extractelement %4696[%c1_i32 : i32] : vector<2xf32>
      %4703 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4702, %4701 : (f32, f32) -> i32
      %4704 = llvm.bitcast %4703 : i32 to vector<2xbf16>
      %4705 = vector.insert_strided_slice %4700, %4683 {offsets = [8], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4706 = vector.insert_strided_slice %4704, %4705 {offsets = [10], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4707 = vector.extract_strided_slice %4637 {offsets = [12], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4708 = llvm.bitcast %4707 : vector<4xi8> to i32
      %4709 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4708, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4710 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4708, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4711 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4708, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4712 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4708, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4713 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4709 : (i32) -> f32
      %4714 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4710 : (i32) -> f32
      %4715 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4711 : (i32) -> f32
      %4716 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4712 : (i32) -> f32
      %4717 = vector.from_elements %4713, %4714, %4715, %4716 : vector<4xf32>
      %4718 = vector.extract_strided_slice %4717 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4719 = vector.extract_strided_slice %4717 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4720 = vector.extractelement %4718[%c0_i32 : i32] : vector<2xf32>
      %4721 = vector.extractelement %4718[%c1_i32 : i32] : vector<2xf32>
      %4722 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4721, %4720 : (f32, f32) -> i32
      %4723 = llvm.bitcast %4722 : i32 to vector<2xbf16>
      %4724 = vector.extractelement %4719[%c0_i32 : i32] : vector<2xf32>
      %4725 = vector.extractelement %4719[%c1_i32 : i32] : vector<2xf32>
      %4726 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4725, %4724 : (f32, f32) -> i32
      %4727 = llvm.bitcast %4726 : i32 to vector<2xbf16>
      %4728 = vector.insert_strided_slice %4723, %4706 {offsets = [12], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4729 = vector.insert_strided_slice %4727, %4728 {offsets = [14], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4730 = vector.extract_strided_slice %4637 {offsets = [16], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4731 = llvm.bitcast %4730 : vector<4xi8> to i32
      %4732 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4731, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4733 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4731, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4734 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4731, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4735 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4731, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4736 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4732 : (i32) -> f32
      %4737 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4733 : (i32) -> f32
      %4738 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4734 : (i32) -> f32
      %4739 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4735 : (i32) -> f32
      %4740 = vector.from_elements %4736, %4737, %4738, %4739 : vector<4xf32>
      %4741 = vector.extract_strided_slice %4740 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4742 = vector.extract_strided_slice %4740 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4743 = vector.extractelement %4741[%c0_i32 : i32] : vector<2xf32>
      %4744 = vector.extractelement %4741[%c1_i32 : i32] : vector<2xf32>
      %4745 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4744, %4743 : (f32, f32) -> i32
      %4746 = llvm.bitcast %4745 : i32 to vector<2xbf16>
      %4747 = vector.extractelement %4742[%c0_i32 : i32] : vector<2xf32>
      %4748 = vector.extractelement %4742[%c1_i32 : i32] : vector<2xf32>
      %4749 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4748, %4747 : (f32, f32) -> i32
      %4750 = llvm.bitcast %4749 : i32 to vector<2xbf16>
      %4751 = vector.insert_strided_slice %4746, %4729 {offsets = [16], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4752 = vector.insert_strided_slice %4750, %4751 {offsets = [18], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4753 = vector.extract_strided_slice %4637 {offsets = [20], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4754 = llvm.bitcast %4753 : vector<4xi8> to i32
      %4755 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4754, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4756 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4754, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4757 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4754, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4758 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4754, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4759 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4755 : (i32) -> f32
      %4760 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4756 : (i32) -> f32
      %4761 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4757 : (i32) -> f32
      %4762 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4758 : (i32) -> f32
      %4763 = vector.from_elements %4759, %4760, %4761, %4762 : vector<4xf32>
      %4764 = vector.extract_strided_slice %4763 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4765 = vector.extract_strided_slice %4763 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4766 = vector.extractelement %4764[%c0_i32 : i32] : vector<2xf32>
      %4767 = vector.extractelement %4764[%c1_i32 : i32] : vector<2xf32>
      %4768 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4767, %4766 : (f32, f32) -> i32
      %4769 = llvm.bitcast %4768 : i32 to vector<2xbf16>
      %4770 = vector.extractelement %4765[%c0_i32 : i32] : vector<2xf32>
      %4771 = vector.extractelement %4765[%c1_i32 : i32] : vector<2xf32>
      %4772 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4771, %4770 : (f32, f32) -> i32
      %4773 = llvm.bitcast %4772 : i32 to vector<2xbf16>
      %4774 = vector.insert_strided_slice %4769, %4752 {offsets = [20], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4775 = vector.insert_strided_slice %4773, %4774 {offsets = [22], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4776 = vector.extract_strided_slice %4637 {offsets = [24], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4777 = llvm.bitcast %4776 : vector<4xi8> to i32
      %4778 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4777, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4779 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4777, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4780 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4777, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4781 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4777, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4782 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4778 : (i32) -> f32
      %4783 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4779 : (i32) -> f32
      %4784 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4780 : (i32) -> f32
      %4785 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4781 : (i32) -> f32
      %4786 = vector.from_elements %4782, %4783, %4784, %4785 : vector<4xf32>
      %4787 = vector.extract_strided_slice %4786 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4788 = vector.extract_strided_slice %4786 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4789 = vector.extractelement %4787[%c0_i32 : i32] : vector<2xf32>
      %4790 = vector.extractelement %4787[%c1_i32 : i32] : vector<2xf32>
      %4791 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4790, %4789 : (f32, f32) -> i32
      %4792 = llvm.bitcast %4791 : i32 to vector<2xbf16>
      %4793 = vector.extractelement %4788[%c0_i32 : i32] : vector<2xf32>
      %4794 = vector.extractelement %4788[%c1_i32 : i32] : vector<2xf32>
      %4795 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4794, %4793 : (f32, f32) -> i32
      %4796 = llvm.bitcast %4795 : i32 to vector<2xbf16>
      %4797 = vector.insert_strided_slice %4792, %4775 {offsets = [24], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4798 = vector.insert_strided_slice %4796, %4797 {offsets = [26], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4799 = vector.extract_strided_slice %4637 {offsets = [28], sizes = [4], strides = [1]} : vector<32xi8> to vector<4xi8>
      %4800 = llvm.bitcast %4799 : vector<4xi8> to i32
      %4801 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4800, %c1_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4802 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4800, %c256_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4803 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4800, %c65536_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4804 = llvm.inline_asm has_side_effects asm_dialect = att "dp4a.s32.s32 $0, $1, $2, $3;", "=r,r,r,r" %4800, %c16777216_i32, %c0_i32 : (i32, i32, i32) -> i32
      %4805 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4801 : (i32) -> f32
      %4806 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4802 : (i32) -> f32
      %4807 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4803 : (i32) -> f32
      %4808 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.f32.s32 $0, $1;", "=f,r" %4804 : (i32) -> f32
      %4809 = vector.from_elements %4805, %4806, %4807, %4808 : vector<4xf32>
      %4810 = vector.extract_strided_slice %4809 {offsets = [0], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4811 = vector.extract_strided_slice %4809 {offsets = [2], sizes = [2], strides = [1]} : vector<4xf32> to vector<2xf32>
      %4812 = vector.extractelement %4810[%c0_i32 : i32] : vector<2xf32>
      %4813 = vector.extractelement %4810[%c1_i32 : i32] : vector<2xf32>
      %4814 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4813, %4812 : (f32, f32) -> i32
      %4815 = llvm.bitcast %4814 : i32 to vector<2xbf16>
      %4816 = vector.extractelement %4811[%c0_i32 : i32] : vector<2xf32>
      %4817 = vector.extractelement %4811[%c1_i32 : i32] : vector<2xf32>
      %4818 = llvm.inline_asm has_side_effects asm_dialect = att "cvt.rn.satfinite.bf16x2.f32 $0, $1, $2;", "=r,f,f" %4817, %4816 : (f32, f32) -> i32
      %4819 = llvm.bitcast %4818 : i32 to vector<2xbf16>
      %4820 = vector.insert_strided_slice %4815, %4798 {offsets = [28], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4821 = vector.insert_strided_slice %4819, %4820 {offsets = [30], strides = [1]} : vector<2xbf16> into vector<32xbf16>
      %4822 = arith.divsi %4600, %c2_i32 : i32
      %4823 = arith.muli %4822, %c2_i32 : i32
      %4824 = arith.cmpi ne, %4600, %4823 : i32
      %c0_i32_1142 = arith.constant 0 : i32
      %4825 = arith.cmpi slt, %4600, %c0_i32_1142 : i32
      %4826 = arith.cmpi slt, %c2_i32, %c0_i32_1142 : i32
      %4827 = arith.cmpi ne, %4825, %4826 : i1
      %4828 = arith.andi %4824, %4827 : i1
      %c-1_i32_1143 = arith.constant -1 : i32
      %4829 = arith.addi %4822, %c-1_i32_1143 : i32
      %4830 = arith.select %4828, %4829, %4822 : i32
      %coord_1144 = cute.make_coord(%247, %4630, %4830) : (i32, i32, i32) -> !cute.coord<"(_,_,_,_,(?,?),?)">
      %idx_1145 = cute.crd2idx(%coord_1144, %4) : (!cute.coord<"(_,_,_,_,(?,?),?)">, !cute.layout<"((4,4),2,1,1,(2,(2,1)),4):((0,0),0,0,0,(0,(0,0)),1)">) -> !cute.int_tuple<"?">
      %ptr_1146 = cute.add_offset(%iter_1091, %idx_1145) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<bf16, rmem>
      %view_1147 = cute.make_view(%ptr_1146) : !memref_rmem_bf16_8
      %4831 = cute.memref.load_vec %view_1147 : !memref_rmem_bf16_8
      %4832 = arith.mulf %4821, %4831 : vector<32xbf16>
      %ptr_1148 = cute.add_offset(%iter_1111, %idx_1134) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<bf16, rmem, align<32>>
      %view_1149 = cute.make_view(%ptr_1148) : !memref_rmem_bf16_5
      cute.memref.store_vec %4832, %view_1149 : !memref_rmem_bf16_5
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1150 = cute.add_offset(%ptr_51, %int_tuple_1128) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4833 = builtin.unrealized_conversion_cast %ptr_1150 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4833, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %ptr_1151 = cute.add_offset(%iter_93, %int_tuple_1114) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4834 = builtin.unrealized_conversion_cast %ptr_1151 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4835 = nvvm.mapa.shared.cluster %4834, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4835, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %4836 = arith.addi %4600, %c1_i32 : i32
      cf.br ^bb780(%4836, %4610, %4612, %4614, %4625, %4627, %4629 : i32, i32, i32, i32, i32, i32, i32)
    ^bb796:  // pred: ^bb780
      %int_tuple_1152 = cute.make_int_tuple(%4602) : (i32) -> !cute.int_tuple<"?">
      %ptr_1153 = cute.add_offset(%ptr_96, %int_tuple_1152) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4837 = builtin.unrealized_conversion_cast %ptr_1153 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4837, %4603, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %4838 = arith.addi %4602, %c1_i32 : i32
      %4839 = arith.addi %4601, %c1_i32 : i32
      %4840 = arith.cmpi eq, %4838, %c3_i32 : i32
      %4841 = arith.select %4840, %c0_i32, %4838 : i32
      cf.cond_br %4840, ^bb797, ^bb798
    ^bb797:  // pred: ^bb796
      %4842 = arith.xori %4603, %c1_i32 : i32
      cf.br ^bb799(%4842 : i32)
    ^bb798:  // pred: ^bb796
      cf.br ^bb799(%4603 : i32)
    ^bb799(%4843: i32):  // 2 preds: ^bb797, ^bb798
      cf.br ^bb800
    ^bb800:  // pred: ^bb799
      %ptr_1154 = cute.add_offset(%iter_1111, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %coord_1155 = cute.make_coord(%4602) : (i32) -> !cute.coord<"(_,_,_,_,?)">
      %idx_1156 = cute.crd2idx(%coord_1155, %8) : (!cute.coord<"(_,_,_,_,?)">, !cute.layout<"((4,4),2,1,1,3):((1,4),4096,0,0,8192)">) -> !cute.int_tuple<"?{div=8192}">
      cf.br ^bb801(%c0_i32 : i32)
    ^bb801(%4844: i32):  // 2 preds: ^bb800, ^bb802
      %4845 = arith.cmpi slt, %4844, %2880 : i32
      cf.cond_br %4845, ^bb802, ^bb803 {llvm.loop_annotation = #loop_annotation}
    ^bb802:  // pred: ^bb801
      %coord_1157 = cute.make_coord(%4844) : (i32) -> !cute.coord<"(_,?)">
      %idx_1158 = cute.crd2idx(%coord_1157, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(4)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1159 = cute.add_offset(%ptr_1154, %idx_1158) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %idx_1160 = cute.crd2idx(%coord_1157, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((2,2))):(1,((8,4096)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_1161 = cute.add_offset(%ptr_847, %idx_1160) : (!cute.ptr<bf16, smem, align<32>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %swizzled_1162 = cute.apply_swizzle(%ptr_1161) : !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %ptr_1163 = cute.add_offset(%swizzled_1162, %idx_1156) : (!cute.ptr<bf16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, smem, align<16>, S<3,4,3>>
      %4846 = builtin.unrealized_conversion_cast %ptr_1159 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %4847 = builtin.unrealized_conversion_cast %ptr_1163 : !cute.ptr<bf16, smem, align<16>, S<3,4,3>> to !llvm.ptr<3>
      %4848 = llvm.load %4846 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %4848, %4847 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<3>
      %4849 = arith.addi %4844, %c1_i32 : i32
      cf.br ^bb801(%4849 : i32)
    ^bb803:  // pred: ^bb801
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      %ptr_1164 = cute.add_offset(%iter_93, %int_tuple_1152) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4850 = builtin.unrealized_conversion_cast %ptr_1164 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %4851 = nvvm.mapa.shared.cluster %4850, %331 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %4851, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %ptr_1165 = cute.add_offset(%ptr_82, %int_tuple_1087) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4852 = builtin.unrealized_conversion_cast %ptr_1165 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %4852, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb647(%4604, %4605, %4606, %3402, %3403, %3404, %4839, %4841, %4843, %4373, %4375, %4377, %false : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i1)
    ^bb804:  // pred: ^bb647
      %4853 = arith.addi %2906, %c1_i32 : i32
      %4854 = arith.cmpi eq, %4853, %c3_i32 : i32
      %4855 = arith.select %4854, %c0_i32, %4853 : i32
      cf.cond_br %4854, ^bb805, ^bb806
    ^bb805:  // pred: ^bb804
      %4856 = arith.xori %2907, %c1_i32 : i32
      cf.br ^bb807(%4856 : i32)
    ^bb806:  // pred: ^bb804
      cf.br ^bb807(%2907 : i32)
    ^bb807(%4857: i32):  // 2 preds: ^bb805, ^bb806
      cf.br ^bb808
    ^bb808:  // pred: ^bb807
      %4858 = arith.addi %4855, %c1_i32 : i32
      %4859 = arith.cmpi eq, %4858, %c3_i32 : i32
      %4860 = arith.select %4859, %c0_i32, %4858 : i32
      cf.cond_br %4859, ^bb809, ^bb810
    ^bb809:  // pred: ^bb808
      %4861 = arith.xori %4857, %c1_i32 : i32
      cf.br ^bb811(%4861 : i32)
    ^bb810:  // pred: ^bb808
      cf.br ^bb811(%4857 : i32)
    ^bb811(%4862: i32):  // 2 preds: ^bb809, ^bb810
      cf.br ^bb812
    ^bb812:  // pred: ^bb811
      %int_tuple_1166 = cute.make_int_tuple(%4860) : (i32) -> !cute.int_tuple<"?">
      %ptr_1167 = cute.add_offset(%ptr_96, %int_tuple_1166) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %4863 = builtin.unrealized_conversion_cast %ptr_1167 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %4863, %4862, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb813
    ^bb813:  // 2 preds: ^bb645, ^bb812
      %4864 = arith.cmpi sgt, %244, %c13_i32 : i32
      cf.cond_br %4864, ^bb814, ^bb815
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
    %16 = arith.divsi %arg9, %arg10 : i32
    %17 = arith.muli %16, %arg10 : i32
    %18 = arith.cmpi ne, %arg9, %17 : i32
    %c0_i32_0 = arith.constant 0 : i32
    %19 = arith.cmpi slt, %arg9, %c0_i32_0 : i32
    %20 = arith.cmpi slt, %arg10, %c0_i32_0 : i32
    %21 = arith.cmpi ne, %19, %20 : i1
    %22 = arith.andi %18, %21 : i1
    %c-1_i32 = arith.constant -1 : i32
    %23 = arith.addi %16, %c-1_i32 : i32
    %24 = arith.select %22, %23, %16 : i32
    %25 = arith.muli %arg11, %arg7 : i32
    %26 = arith.muli %25, %24 : i32
    %27 = arith.muli %24, %arg10 : i32
    %28 = arith.muli %27, %arg7 : i32
    %29 = arith.muli %28, %arg11 : i32
    %shape = cute.make_shape(%arg7, %arg11, %24, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride = cute.make_stride(%arg11, %25, %26, %29) : (i32, i32, i32, i32) -> !cute.stride<"(?,1,((?,?),?))">
    %lay = cute.make_layout(%shape, %stride) : !cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">
    %30 = arith.muli %arg11, %arg8 : i32
    %31 = arith.muli %arg10, %arg8 : i32
    %32 = arith.muli %31, %arg11 : i32
    %shape_1 = cute.make_shape(%arg8, %arg11, %24, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride_2 = cute.make_stride(%arg11, %30, %32) : (i32, i32, i32) -> !cute.stride<"(?,1,((0,?),?))">
    %lay_3 = cute.make_layout(%shape_1, %stride_2) : !cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">
    %shape_4 = cute.make_shape(%arg11, %arg8, %24, %arg10, %arg6) : (i32, i32, i32, i32, i32) -> !cute.shape<"(?,?,((?,?),?))">
    %stride_5 = cute.make_stride(%arg11, %30, %32) : (i32, i32, i32) -> !cute.stride<"(1,?,((0,?),?))">
    %lay_6 = cute.make_layout(%shape_4, %stride_5) : !cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">
    %iv = cute.assume(%arg11) : (i32) -> !cute.i32<divby 256>
    %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_7 = cute.assume(%25) : (i32) -> !cute.i32<divby 256>
    %int_tuple_8 = cute.make_int_tuple(%iv_7) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_9 = cute.assume(%26) : (i32) -> !cute.i32<divby 256>
    %int_tuple_10 = cute.make_int_tuple(%iv_9) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %iv_11 = cute.assume(%29) : (i32) -> !cute.i32<divby 256>
    %int_tuple_12 = cute.make_int_tuple(%iv_11) : (!cute.i32<divby 256>) -> !cute.int_tuple<"?{div=256}">
    %stride_13 = cute.make_stride(%int_tuple, %int_tuple_8, %int_tuple_10, %int_tuple_12) : (!cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">, !cute.int_tuple<"?{div=256}">) -> !cute.stride<"(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
    %lay_14 = cute.make_layout(%shape, %stride_13) : !cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">
    %view = cute.make_view(%arg3, %lay_14) : !memref_gmem_bf16_
    %shape_15 = cute.make_shape(%arg8, %24, %arg10, %arg6) : (i32, i32, i32, i32) -> !cute.shape<"(?,((?,?),?))">
    %stride_16 = cute.make_stride(%arg8, %31) : (i32, i32) -> !cute.stride<"(1,((0,?),?))">
    %lay_17 = cute.make_layout(%shape_15, %stride_16) : !cute.layout<"(?,((?,?),?)):(1,((0,?),?))">
    %33 = cute.get_shape(%lay_14) : (!cute.layout<"(?,?,((?,?),?)):(?{div=256},1,((?{div=256},?{div=256}),?{div=256}))">) -> !cute.shape<"(?,?,((?,?),?))">
    %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%33) : !cute.shape<"(?,?,((?,?),?))">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_18 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_19 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_20 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_21 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_21) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_22 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %int_tuple_23 = cute.make_int_tuple(%e0_22) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %34 = cute.get_scalars(%int_tuple_23) <{only_dynamic}> : !cute.int_tuple<"?">
    %c1_i32_24 = arith.constant 1 : i32
    %c0_i32_25 = arith.constant 0 : i32
    %c-1_i32_26 = arith.constant -1 : i32
    %35 = arith.cmpi sgt, %c64_i32, %c0_i32_25 : i32
    %36 = arith.select %35, %c-1_i32_26, %c1_i32_24 : i32
    %37 = arith.addi %36, %34 : i32
    %38 = arith.divsi %37, %c64_i32 : i32
    %39 = arith.addi %c1_i32_24, %38 : i32
    %40 = arith.subi %c0_i32_25, %34 : i32
    %41 = arith.divsi %40, %c64_i32 : i32
    %42 = arith.subi %c0_i32_25, %41 : i32
    %43 = arith.cmpi slt, %34, %c0_i32_25 : i32
    %44 = arith.cmpi sgt, %34, %c0_i32_25 : i32
    %45 = arith.cmpi slt, %c64_i32, %c0_i32_25 : i32
    %46 = arith.cmpi sgt, %c64_i32, %c0_i32_25 : i32
    %47 = arith.andi %43, %45 : i1
    %48 = arith.andi %44, %46 : i1
    %49 = arith.ori %47, %48 : i1
    %50 = arith.select %49, %39, %42 : i32
    %int_tuple_27 = cute.make_int_tuple(%50) : (i32) -> !cute.int_tuple<"?">
    %e0_28 = cute.get_leaves(%int_tuple_27) : !cute.int_tuple<"?">
    %51 = cute.get_scalars(%e0_28) : !cute.int_tuple<"?">
    %int_tuple_29 = cute.make_int_tuple(%itup_18, %itup_19) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?)">
    %sz_30 = cute.size(%int_tuple_29) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
    %e0_31 = cute.get_leaves(%sz_30) : !cute.int_tuple<"?">
    %52 = cute.get_scalars(%e0_31) : !cute.int_tuple<"?">
    %int_tuple_32 = cute.make_int_tuple(%itup_20) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_33 = cute.size(%int_tuple_32) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_34 = cute.get_leaves(%sz_33) : !cute.int_tuple<"?">
    %53 = cute.get_scalars(%e0_34) : !cute.int_tuple<"?">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %54 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %55 = cute_nvgpu.atom.set_value(%54, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %56 = cute_nvgpu.atom.set_value(%55, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, k), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %57 = cute.make_tiled_mma(%56) : !mma_bf16_bf16_f32_128x256x16_
    %atom_35 = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %58 = cute_nvgpu.atom.set_value(%atom_35, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %59 = cute_nvgpu.atom.set_value(%58, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %60 = cute_nvgpu.atom.set_value(%59, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 2, ab_major = (k, mn), elem_type = (bf16, bf16, f32), frag_kind = ss, c_scale_exp = 0>
    %61 = cute.make_tiled_mma(%60) : !mma_bf16_bf16_f32_128x256x16_1
    %62 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %63:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">
    %64 = arith.extui %63#1 : i32 to i64
    %65 = arith.extui %63#0 : i32 to i64
    %66 = arith.extui %63#5 : i32 to i64
    %67 = llvm.mul %66, %c2_i64 : i64
    %68 = arith.extui %63#2 : i32 to i64
    %69 = arith.extui %63#6 : i32 to i64
    %70 = llvm.mul %69, %c2_i64 : i64
    %71 = arith.extui %63#3 : i32 to i64
    %72 = arith.extui %63#7 : i32 to i64
    %73 = llvm.mul %72, %c2_i64 : i64
    %74 = arith.extui %63#4 : i32 to i64
    %75 = arith.extui %63#8 : i32 to i64
    %76 = llvm.mul %75, %c2_i64 : i64
    %77 = cute.ptrtoint(%arg0) : !cute.ptr<bf16, gmem, align<128>> to i64
    %78 = llvm.getelementptr %62[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %78 : i64, !llvm.ptr
    %79 = llvm.getelementptr %62[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %79 : i64, !llvm.ptr
    %80 = llvm.getelementptr %62[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %80 : i64, !llvm.ptr
    %81 = llvm.getelementptr %62[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %81 : i64, !llvm.ptr
    %82 = llvm.getelementptr %62[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %82 : i64, !llvm.ptr
    %83 = llvm.getelementptr %62[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %83 : i64, !llvm.ptr
    %84 = llvm.getelementptr %62[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %84 : i64, !llvm.ptr
    %85 = llvm.getelementptr %62[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %85 : i64, !llvm.ptr
    %86 = llvm.getelementptr %62[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %86 : i64, !llvm.ptr
    %87 = llvm.getelementptr %62[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %87 : i64, !llvm.ptr
    %88 = llvm.getelementptr %62[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %88 : i64, !llvm.ptr
    %89 = llvm.getelementptr %62[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %89 : i64, !llvm.ptr
    %90 = llvm.getelementptr %62[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %90 : i64, !llvm.ptr
    %91 = llvm.getelementptr %62[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %91 : i64, !llvm.ptr
    %92 = llvm.getelementptr %62[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %92 : i64, !llvm.ptr
    %93 = llvm.getelementptr %62[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %93 : i64, !llvm.ptr
    %94 = llvm.udiv %77, %c16_i64 : i64
    %95 = llvm.and %94, %c9007199254740991_i64 : i64
    %96 = llvm.shl %95, %c4_i64 : i64
    llvm.store %96, %78 : i64, !llvm.ptr
    %97 = llvm.sub %65, %c1_i64 : i64
    %98 = llvm.sub %68, %c1_i64 : i64
    %99 = llvm.sub %71, %c1_i64 : i64
    %100 = llvm.sub %74, %c1_i64 : i64
    %101 = llvm.mul %97, %67 : i64
    %102 = llvm.mul %98, %70 : i64
    %103 = llvm.mul %99, %73 : i64
    %104 = llvm.mul %100, %76 : i64
    %105 = llvm.add %101, %102 : i64
    %106 = llvm.add %103, %104 : i64
    %107 = llvm.mul %64, %c16_i64 : i64
    %108 = llvm.udiv %107, %c8_i64 : i64
    %109 = llvm.add %108, %105 : i64
    %110 = llvm.add %109, %106 : i64
    %111 = llvm.icmp "uge" %110, %c131072_i64 : i64
    %112 = llvm.zext %111 : i1 to i64
    %113 = llvm.shl %112, %c21_i64 : i64
    %114 = llvm.udiv %67, %c16_i64 : i64
    %115 = llvm.shl %114, %c32_i64 : i64
    %116 = llvm.or %c0_i64, %113 : i64
    %117 = llvm.or %116, %115 : i64
    %118 = llvm.or %8, %117 : i64
    llvm.store %118, %79 : i64, !llvm.ptr
    %119 = llvm.udiv %70, %c16_i64 : i64
    %120 = llvm.and %119, %c4294967295_i64 : i64
    %121 = llvm.shl %120, %c0_i64 : i64
    %122 = llvm.udiv %73, %c16_i64 : i64
    %123 = llvm.shl %122, %c32_i64 : i64
    %124 = llvm.or %121, %123 : i64
    llvm.store %124, %80 : i64, !llvm.ptr
    %125 = llvm.udiv %76, %c16_i64 : i64
    %126 = llvm.and %125, %c4294967295_i64 : i64
    %127 = llvm.shl %126, %c0_i64 : i64
    %128 = llvm.lshr %67, %c36_i64 : i64
    %129 = llvm.and %128, %c15_i64 : i64
    %130 = llvm.shl %129, %c32_i64 : i64
    %131 = llvm.lshr %70, %c36_i64 : i64
    %132 = llvm.and %131, %c15_i64 : i64
    %133 = llvm.shl %132, %c36_i64 : i64
    %134 = llvm.lshr %73, %c36_i64 : i64
    %135 = llvm.and %134, %c15_i64 : i64
    %136 = llvm.shl %135, %c40_i64 : i64
    %137 = llvm.lshr %76, %c36_i64 : i64
    %138 = llvm.shl %137, %c44_i64 : i64
    %139 = llvm.or %130, %133 : i64
    %140 = llvm.or %136, %138 : i64
    %141 = llvm.or %139, %140 : i64
    %142 = llvm.or %127, %141 : i64
    llvm.store %142, %81 : i64, !llvm.ptr
    %143 = llvm.sub %64, %c1_i64 : i64
    %144 = llvm.and %143, %c4294967295_i64 : i64
    %145 = llvm.shl %144, %c0_i64 : i64
    %146 = llvm.shl %97, %c32_i64 : i64
    %147 = llvm.or %145, %146 : i64
    llvm.store %147, %82 : i64, !llvm.ptr
    %148 = llvm.and %98, %c4294967295_i64 : i64
    %149 = llvm.shl %148, %c0_i64 : i64
    %150 = llvm.shl %99, %c32_i64 : i64
    %151 = llvm.or %149, %150 : i64
    llvm.store %151, %83 : i64, !llvm.ptr
    %152 = llvm.and %100, %c4294967295_i64 : i64
    %153 = llvm.or %152, %c0_i64 : i64
    %154 = llvm.or %153, %7 : i64
    llvm.store %154, %84 : i64, !llvm.ptr
    llvm.store %6, %85 : i64, !llvm.ptr
    %155 = builtin.unrealized_conversion_cast %62 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %156 = cute.ptrtoint(%155) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %157 = llvm.inttoptr %156 : i64 to !llvm.ptr
    %158 = llvm.load %157 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %159 = builtin.unrealized_conversion_cast %158 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_36 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>
    %160 = cute_nvgpu.atom.set_value(%atom_36, %159 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>
    %161 = cute.get_shape(%lay) : (!cute.layout<"(?,?,((?,?),?)):(?,1,((?,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_37 = cute.make_layout(%161, %15) : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
    %view_38 = cute.make_view(%14, %lay_37) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">
    %162 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %163:8 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">
    %164 = arith.extui %163#1 : i32 to i64
    %165 = arith.extui %163#0 : i32 to i64
    %166 = arith.extui %163#5 : i32 to i64
    %167 = llvm.mul %166, %c1_i64 : i64
    %168 = arith.extui %163#3 : i32 to i64
    %169 = arith.extui %163#6 : i32 to i64
    %170 = llvm.mul %169, %c1_i64 : i64
    %171 = arith.extui %163#4 : i32 to i64
    %172 = arith.extui %163#7 : i32 to i64
    %173 = llvm.mul %172, %c1_i64 : i64
    %174 = cute.ptrtoint(%arg1) : !cute.ptr<i8, gmem, align<128>> to i64
    %175 = llvm.getelementptr %162[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %175 : i64, !llvm.ptr
    %176 = llvm.getelementptr %162[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %176 : i64, !llvm.ptr
    %177 = llvm.getelementptr %162[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %177 : i64, !llvm.ptr
    %178 = llvm.getelementptr %162[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %178 : i64, !llvm.ptr
    %179 = llvm.getelementptr %162[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %179 : i64, !llvm.ptr
    %180 = llvm.getelementptr %162[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %180 : i64, !llvm.ptr
    %181 = llvm.getelementptr %162[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %181 : i64, !llvm.ptr
    %182 = llvm.getelementptr %162[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %162[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %162[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %162[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %162[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %162[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %162[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %162[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %162[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.udiv %174, %c16_i64 : i64
    %192 = llvm.and %191, %c9007199254740991_i64 : i64
    %193 = llvm.shl %192, %c4_i64 : i64
    llvm.store %193, %175 : i64, !llvm.ptr
    %194 = llvm.sub %165, %c1_i64 : i64
    %195 = llvm.sub %168, %c1_i64 : i64
    %196 = llvm.sub %171, %c1_i64 : i64
    %197 = llvm.sub %c1_i64, %c1_i64 : i64
    %198 = llvm.mul %194, %167 : i64
    %199 = llvm.mul %195, %170 : i64
    %200 = llvm.mul %196, %173 : i64
    %201 = llvm.mul %197, %c0_i64 : i64
    %202 = llvm.add %198, %199 : i64
    %203 = llvm.add %200, %201 : i64
    %204 = llvm.mul %164, %c8_i64 : i64
    %205 = llvm.udiv %204, %c8_i64 : i64
    %206 = llvm.add %205, %202 : i64
    %207 = llvm.add %206, %203 : i64
    %208 = llvm.icmp "uge" %207, %c131072_i64 : i64
    %209 = llvm.zext %208 : i1 to i64
    %210 = llvm.shl %209, %c21_i64 : i64
    %211 = llvm.udiv %167, %c16_i64 : i64
    %212 = llvm.shl %211, %c32_i64 : i64
    %213 = llvm.or %c0_i64, %210 : i64
    %214 = llvm.or %213, %212 : i64
    %215 = llvm.or %5, %214 : i64
    llvm.store %215, %176 : i64, !llvm.ptr
    %216 = llvm.udiv %170, %c16_i64 : i64
    %217 = llvm.and %216, %c4294967295_i64 : i64
    %218 = llvm.shl %217, %c0_i64 : i64
    %219 = llvm.udiv %173, %c16_i64 : i64
    %220 = llvm.shl %219, %c32_i64 : i64
    %221 = llvm.or %218, %220 : i64
    llvm.store %221, %177 : i64, !llvm.ptr
    %222 = llvm.udiv %c0_i64, %c16_i64 : i64
    %223 = llvm.and %222, %c4294967295_i64 : i64
    %224 = llvm.shl %223, %c0_i64 : i64
    %225 = llvm.lshr %167, %c36_i64 : i64
    %226 = llvm.and %225, %c15_i64 : i64
    %227 = llvm.shl %226, %c32_i64 : i64
    %228 = llvm.lshr %170, %c36_i64 : i64
    %229 = llvm.and %228, %c15_i64 : i64
    %230 = llvm.shl %229, %c36_i64 : i64
    %231 = llvm.lshr %173, %c36_i64 : i64
    %232 = llvm.and %231, %c15_i64 : i64
    %233 = llvm.shl %232, %c40_i64 : i64
    %234 = llvm.lshr %c0_i64, %c36_i64 : i64
    %235 = llvm.shl %234, %c44_i64 : i64
    %236 = llvm.or %227, %230 : i64
    %237 = llvm.or %233, %235 : i64
    %238 = llvm.or %236, %237 : i64
    %239 = llvm.or %224, %238 : i64
    llvm.store %239, %178 : i64, !llvm.ptr
    %240 = llvm.sub %164, %c1_i64 : i64
    %241 = llvm.and %240, %c4294967295_i64 : i64
    %242 = llvm.shl %241, %c0_i64 : i64
    %243 = llvm.shl %194, %c32_i64 : i64
    %244 = llvm.or %242, %243 : i64
    llvm.store %244, %179 : i64, !llvm.ptr
    %245 = llvm.and %195, %c4294967295_i64 : i64
    %246 = llvm.shl %245, %c0_i64 : i64
    %247 = llvm.shl %196, %c32_i64 : i64
    %248 = llvm.or %246, %247 : i64
    llvm.store %248, %180 : i64, !llvm.ptr
    %249 = llvm.and %197, %c4294967295_i64 : i64
    %250 = llvm.or %249, %c0_i64 : i64
    %251 = llvm.or %250, %7 : i64
    llvm.store %251, %181 : i64, !llvm.ptr
    llvm.store %4, %182 : i64, !llvm.ptr
    %252 = builtin.unrealized_conversion_cast %162 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %253 = cute.ptrtoint(%252) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %254 = llvm.inttoptr %253 : i64 to !llvm.ptr
    %255 = llvm.load %254 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %256 = builtin.unrealized_conversion_cast %255 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_39 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %257 = cute_nvgpu.atom.set_value(%atom_39, %256 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %258 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,((?,?),?)):(?,1,((0,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_40 = cute.make_layout(%258, %13) : !cute.layout<"(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
    %view_41 = cute.make_view(%12, %lay_40) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">
    %259 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %260:6 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,((?,?),?)):(1,((0,?),?))">
    %261 = arith.extui %260#0 : i32 to i64
    %262 = arith.extui %260#2 : i32 to i64
    %263 = arith.extui %260#4 : i32 to i64
    %264 = llvm.mul %263, %c2_i64 : i64
    %265 = arith.extui %260#3 : i32 to i64
    %266 = arith.extui %260#5 : i32 to i64
    %267 = llvm.mul %266, %c2_i64 : i64
    %268 = cute.ptrtoint(%arg4) : !cute.ptr<bf16, gmem, align<128>> to i64
    %269 = llvm.getelementptr %259[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %269 : i64, !llvm.ptr
    %270 = llvm.getelementptr %259[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %270 : i64, !llvm.ptr
    %271 = llvm.getelementptr %259[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %271 : i64, !llvm.ptr
    %272 = llvm.getelementptr %259[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %272 : i64, !llvm.ptr
    %273 = llvm.getelementptr %259[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %273 : i64, !llvm.ptr
    %274 = llvm.getelementptr %259[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %274 : i64, !llvm.ptr
    %275 = llvm.getelementptr %259[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %275 : i64, !llvm.ptr
    %276 = llvm.getelementptr %259[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %276 : i64, !llvm.ptr
    %277 = llvm.getelementptr %259[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %277 : i64, !llvm.ptr
    %278 = llvm.getelementptr %259[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %278 : i64, !llvm.ptr
    %279 = llvm.getelementptr %259[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %279 : i64, !llvm.ptr
    %280 = llvm.getelementptr %259[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %280 : i64, !llvm.ptr
    %281 = llvm.getelementptr %259[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %281 : i64, !llvm.ptr
    %282 = llvm.getelementptr %259[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %282 : i64, !llvm.ptr
    %283 = llvm.getelementptr %259[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %283 : i64, !llvm.ptr
    %284 = llvm.getelementptr %259[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %284 : i64, !llvm.ptr
    %285 = llvm.udiv %268, %c16_i64 : i64
    %286 = llvm.and %285, %c9007199254740991_i64 : i64
    %287 = llvm.shl %286, %c4_i64 : i64
    llvm.store %287, %269 : i64, !llvm.ptr
    %288 = llvm.sub %262, %c1_i64 : i64
    %289 = llvm.sub %265, %c1_i64 : i64
    %290 = llvm.mul %288, %264 : i64
    %291 = llvm.mul %289, %267 : i64
    %292 = llvm.add %290, %291 : i64
    %293 = llvm.add %201, %201 : i64
    %294 = llvm.mul %261, %c16_i64 : i64
    %295 = llvm.udiv %294, %c8_i64 : i64
    %296 = llvm.add %295, %292 : i64
    %297 = llvm.add %296, %293 : i64
    %298 = llvm.icmp "uge" %297, %c131072_i64 : i64
    %299 = llvm.zext %298 : i1 to i64
    %300 = llvm.shl %299, %c21_i64 : i64
    %301 = llvm.udiv %264, %c16_i64 : i64
    %302 = llvm.shl %301, %c32_i64 : i64
    %303 = llvm.or %c0_i64, %300 : i64
    %304 = llvm.or %303, %302 : i64
    %305 = llvm.or %3, %304 : i64
    llvm.store %305, %270 : i64, !llvm.ptr
    %306 = llvm.udiv %267, %c16_i64 : i64
    %307 = llvm.and %306, %c4294967295_i64 : i64
    %308 = llvm.shl %307, %c0_i64 : i64
    %309 = llvm.shl %222, %c32_i64 : i64
    %310 = llvm.or %308, %309 : i64
    llvm.store %310, %271 : i64, !llvm.ptr
    %311 = llvm.lshr %264, %c36_i64 : i64
    %312 = llvm.and %311, %c15_i64 : i64
    %313 = llvm.shl %312, %c32_i64 : i64
    %314 = llvm.lshr %267, %c36_i64 : i64
    %315 = llvm.and %314, %c15_i64 : i64
    %316 = llvm.shl %315, %c36_i64 : i64
    %317 = llvm.and %234, %c15_i64 : i64
    %318 = llvm.shl %317, %c40_i64 : i64
    %319 = llvm.or %313, %316 : i64
    %320 = llvm.or %318, %235 : i64
    %321 = llvm.or %319, %320 : i64
    %322 = llvm.or %224, %321 : i64
    llvm.store %322, %272 : i64, !llvm.ptr
    %323 = llvm.sub %261, %c1_i64 : i64
    %324 = llvm.and %323, %c4294967295_i64 : i64
    %325 = llvm.shl %324, %c0_i64 : i64
    %326 = llvm.shl %288, %c32_i64 : i64
    %327 = llvm.or %325, %326 : i64
    llvm.store %327, %273 : i64, !llvm.ptr
    %328 = llvm.and %289, %c4294967295_i64 : i64
    %329 = llvm.shl %328, %c0_i64 : i64
    %330 = llvm.shl %197, %c32_i64 : i64
    %331 = llvm.or %329, %330 : i64
    llvm.store %331, %274 : i64, !llvm.ptr
    %332 = llvm.or %250, %2 : i64
    llvm.store %332, %275 : i64, !llvm.ptr
    llvm.store %1, %276 : i64, !llvm.ptr
    %333 = builtin.unrealized_conversion_cast %259 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %334 = cute.ptrtoint(%333) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %335 = llvm.inttoptr %334 : i64 to !llvm.ptr
    %336 = llvm.load %335 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %337 = builtin.unrealized_conversion_cast %336 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_42 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %338 = cute_nvgpu.atom.set_value(%atom_42, %337 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %339 = cute.get_shape(%lay_17) : (!cute.layout<"(?,((?,?),?)):(1,((0,?),?))">) -> !cute.shape<"(?,((?,?),?))">
    %lay_43 = cute.make_layout(%339, %11) : !cute.layout<"(?,((?,?),?)):(1@0,((0,1@1),1@2))">
    %view_44 = cute.make_view(%10, %lay_43) : !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">
    %340 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %341:8 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">
    %342 = arith.extui %341#0 : i32 to i64
    %343 = arith.extui %341#1 : i32 to i64
    %344 = arith.extui %341#5 : i32 to i64
    %345 = llvm.mul %344, %c1_i64 : i64
    %346 = arith.extui %341#3 : i32 to i64
    %347 = arith.extui %341#6 : i32 to i64
    %348 = llvm.mul %347, %c1_i64 : i64
    %349 = arith.extui %341#4 : i32 to i64
    %350 = arith.extui %341#7 : i32 to i64
    %351 = llvm.mul %350, %c1_i64 : i64
    %352 = cute.ptrtoint(%arg2) : !cute.ptr<i8, gmem, align<128>> to i64
    %353 = llvm.getelementptr %340[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %353 : i64, !llvm.ptr
    %354 = llvm.getelementptr %340[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %354 : i64, !llvm.ptr
    %355 = llvm.getelementptr %340[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %355 : i64, !llvm.ptr
    %356 = llvm.getelementptr %340[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %356 : i64, !llvm.ptr
    %357 = llvm.getelementptr %340[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %357 : i64, !llvm.ptr
    %358 = llvm.getelementptr %340[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %358 : i64, !llvm.ptr
    %359 = llvm.getelementptr %340[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %359 : i64, !llvm.ptr
    %360 = llvm.getelementptr %340[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %360 : i64, !llvm.ptr
    %361 = llvm.getelementptr %340[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %361 : i64, !llvm.ptr
    %362 = llvm.getelementptr %340[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %362 : i64, !llvm.ptr
    %363 = llvm.getelementptr %340[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %363 : i64, !llvm.ptr
    %364 = llvm.getelementptr %340[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %364 : i64, !llvm.ptr
    %365 = llvm.getelementptr %340[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %365 : i64, !llvm.ptr
    %366 = llvm.getelementptr %340[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %366 : i64, !llvm.ptr
    %367 = llvm.getelementptr %340[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %367 : i64, !llvm.ptr
    %368 = llvm.getelementptr %340[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %368 : i64, !llvm.ptr
    %369 = llvm.udiv %352, %c16_i64 : i64
    %370 = llvm.and %369, %c9007199254740991_i64 : i64
    %371 = llvm.shl %370, %c4_i64 : i64
    llvm.store %371, %353 : i64, !llvm.ptr
    %372 = llvm.sub %343, %c1_i64 : i64
    %373 = llvm.sub %346, %c1_i64 : i64
    %374 = llvm.sub %349, %c1_i64 : i64
    %375 = llvm.mul %372, %345 : i64
    %376 = llvm.mul %373, %348 : i64
    %377 = llvm.mul %374, %351 : i64
    %378 = llvm.add %375, %376 : i64
    %379 = llvm.add %377, %201 : i64
    %380 = llvm.mul %342, %c8_i64 : i64
    %381 = llvm.udiv %380, %c8_i64 : i64
    %382 = llvm.add %381, %378 : i64
    %383 = llvm.add %382, %379 : i64
    %384 = llvm.icmp "uge" %383, %c131072_i64 : i64
    %385 = llvm.zext %384 : i1 to i64
    %386 = llvm.shl %385, %c21_i64 : i64
    %387 = llvm.udiv %345, %c16_i64 : i64
    %388 = llvm.shl %387, %c32_i64 : i64
    %389 = llvm.or %c0_i64, %386 : i64
    %390 = llvm.or %389, %388 : i64
    %391 = llvm.or %0, %390 : i64
    llvm.store %391, %354 : i64, !llvm.ptr
    %392 = llvm.udiv %348, %c16_i64 : i64
    %393 = llvm.and %392, %c4294967295_i64 : i64
    %394 = llvm.shl %393, %c0_i64 : i64
    %395 = llvm.udiv %351, %c16_i64 : i64
    %396 = llvm.shl %395, %c32_i64 : i64
    %397 = llvm.or %394, %396 : i64
    llvm.store %397, %355 : i64, !llvm.ptr
    %398 = llvm.lshr %345, %c36_i64 : i64
    %399 = llvm.and %398, %c15_i64 : i64
    %400 = llvm.shl %399, %c32_i64 : i64
    %401 = llvm.lshr %348, %c36_i64 : i64
    %402 = llvm.and %401, %c15_i64 : i64
    %403 = llvm.shl %402, %c36_i64 : i64
    %404 = llvm.lshr %351, %c36_i64 : i64
    %405 = llvm.and %404, %c15_i64 : i64
    %406 = llvm.shl %405, %c40_i64 : i64
    %407 = llvm.or %400, %403 : i64
    %408 = llvm.or %406, %235 : i64
    %409 = llvm.or %407, %408 : i64
    %410 = llvm.or %224, %409 : i64
    llvm.store %410, %356 : i64, !llvm.ptr
    %411 = llvm.sub %342, %c1_i64 : i64
    %412 = llvm.and %411, %c4294967295_i64 : i64
    %413 = llvm.shl %412, %c0_i64 : i64
    %414 = llvm.shl %372, %c32_i64 : i64
    %415 = llvm.or %413, %414 : i64
    llvm.store %415, %357 : i64, !llvm.ptr
    %416 = llvm.and %373, %c4294967295_i64 : i64
    %417 = llvm.shl %416, %c0_i64 : i64
    %418 = llvm.shl %374, %c32_i64 : i64
    %419 = llvm.or %417, %418 : i64
    llvm.store %419, %358 : i64, !llvm.ptr
    llvm.store %251, %359 : i64, !llvm.ptr
    llvm.store %6, %360 : i64, !llvm.ptr
    %420 = builtin.unrealized_conversion_cast %340 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %421 = cute.ptrtoint(%420) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %422 = llvm.inttoptr %421 : i64 to !llvm.ptr
    %423 = llvm.load %422 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %424 = builtin.unrealized_conversion_cast %423 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_45 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %425 = cute_nvgpu.atom.set_value(%atom_45, %424 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>
    %426 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?,((?,?),?)):(1,?,((0,?),?))">) -> !cute.shape<"(?,?,((?,?),?))">
    %lay_46 = cute.make_layout(%426, %9) : !cute.layout<"(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
    %view_47 = cute.make_view(%12, %lay_46) : !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">
    %427 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %428 = cute.ptrtoint(%arg5) : !cute.ptr<bf16, gmem, align<128>> to i64
    %429 = llvm.getelementptr %427[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %429 : i64, !llvm.ptr
    %430 = llvm.getelementptr %427[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %430 : i64, !llvm.ptr
    %431 = llvm.getelementptr %427[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %431 : i64, !llvm.ptr
    %432 = llvm.getelementptr %427[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %432 : i64, !llvm.ptr
    %433 = llvm.getelementptr %427[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %433 : i64, !llvm.ptr
    %434 = llvm.getelementptr %427[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %434 : i64, !llvm.ptr
    %435 = llvm.getelementptr %427[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %435 : i64, !llvm.ptr
    %436 = llvm.getelementptr %427[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %436 : i64, !llvm.ptr
    %437 = llvm.getelementptr %427[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %437 : i64, !llvm.ptr
    %438 = llvm.getelementptr %427[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %438 : i64, !llvm.ptr
    %439 = llvm.getelementptr %427[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %439 : i64, !llvm.ptr
    %440 = llvm.getelementptr %427[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %440 : i64, !llvm.ptr
    %441 = llvm.getelementptr %427[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %441 : i64, !llvm.ptr
    %442 = llvm.getelementptr %427[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %442 : i64, !llvm.ptr
    %443 = llvm.getelementptr %427[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %443 : i64, !llvm.ptr
    %444 = llvm.getelementptr %427[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %444 : i64, !llvm.ptr
    %445 = llvm.udiv %428, %c16_i64 : i64
    %446 = llvm.and %445, %c9007199254740991_i64 : i64
    %447 = llvm.shl %446, %c4_i64 : i64
    llvm.store %447, %429 : i64, !llvm.ptr
    llvm.store %305, %430 : i64, !llvm.ptr
    llvm.store %310, %431 : i64, !llvm.ptr
    llvm.store %322, %432 : i64, !llvm.ptr
    llvm.store %327, %433 : i64, !llvm.ptr
    llvm.store %331, %434 : i64, !llvm.ptr
    llvm.store %251, %435 : i64, !llvm.ptr
    llvm.store %1, %436 : i64, !llvm.ptr
    %448 = builtin.unrealized_conversion_cast %427 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %449 = cute.ptrtoint(%448) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %450 = llvm.inttoptr %449 : i64 to !llvm.ptr
    %451 = llvm.load %450 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %452 = builtin.unrealized_conversion_cast %451 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_48 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %453 = cute_nvgpu.atom.set_value(%atom_48, %452 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>
    %454 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c512_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c226048_i64, gridDim = (%51, %52, %53), stream = %arg14) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%454] (%c2_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %455 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__MixedInputFusedMultiHeadAttentionPrefill_object_at__TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK12825616_TVLayoutA26416641128_TV_0<%454> (%57, %61, %160, %view_38, %257, %view_41, %338, %view_44, %425, %view_47, %453, %view_44, %view, %arg12, %arg13, %51, %52, %53) : !cuda.launch_cfg<max_attrs = 2>, (!mma_bf16_bf16_f32_128x256x16_, !mma_bf16_bf16_f32_128x256x16_1, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm, bf16, copy_bits = 65536, tma_gbasis = <"(64,64,1,1,(1)):(1@1,1@0,1@0@0@2,1@1@0@2,(1@1@2))">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((1@2,1@3),1@4))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 65536, tma_gbasis = <"(64,128,1,1):(1@1,1@0,1@1@0@2,1@1@2)">, internal_val_type = i8>, !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@1,1@0,((0,1@2),1@3))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 2048, tma_gbasis = <"(128,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, i8, copy_bits = 32768, tma_gbasis = <"(64,64,1,1):(1@0,1@1,1@1@0@2,1@1@2)">, internal_val_type = i8>, !cute.coord_tensor<"(0,0,0,0)", "(?,?,((?,?),?)):(1@0,1@1,((0,1@2),1@3))">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, bf16, copy_bits = 1024, tma_gbasis = <"(64,1,1):(1@0,1@1@0@1,1@1@1)">, internal_val_type = bf16>, !cute.coord_tensor<"(0,0,0)", "(?,((?,?),?)):(1@0,((0,1@1),1@2))">, !memref_gmem_bf16_, f32, f32, i32, i32, i32) -> !cuda.result
    %456 = cuda.cast %455 : !cuda.result -> i32
    cuda.return_if_error %456 : i32
    return %c0_i32 : i32
  }
}
