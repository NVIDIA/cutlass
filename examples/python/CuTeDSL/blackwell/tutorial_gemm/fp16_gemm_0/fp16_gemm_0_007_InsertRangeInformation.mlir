!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<32>, "(128,256):(?{i64 div=8192},1)">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, align<32>, "((128,256),1,1):((?{i64 div=8192},1),0,0)">
!memref_gmem_f16_3 = !cute.memref<f16, gmem, align<32>, "(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
!memref_gmem_f16_4 = !cute.memref<f16, gmem, align<32>, "((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
!memref_gmem_f16_5 = !cute.memref<f16, gmem, align<32>, "((64,1),1):((1,0),0)">
!memref_gmem_f16_6 = !cute.memref<f16, gmem, align<32>, "(64,1):(1,0)">
!memref_gmem_f16_7 = !cute.memref<f16, gmem, align<32>, "(16,4):(1,16)">
!memref_gmem_f16_8 = !cute.memref<f16, gmem, align<32>, "(16):(1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<32>, "(64,1):(1,0)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "(16,4):(1,16)">
!memref_rmem_f16_3 = !cute.memref<f16, rmem, align<32>, "(16):(1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((64,1),(1)):((1,0),(0))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((64,1)):((1,0))">
!memref_smem_f16_ = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((128,16),1,4,4):((64,1),0,16,8192)">
!memref_smem_f16_1 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((256,16),1,4,4):((64,1),0,16,16384)">
!memref_smem_f16_2 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "(((128,16),1,4),4):(((64,1),0,16),8192)">
!memref_smem_f16_3 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((8192,1),4):((1,0),8192)">
!memref_smem_f16_4 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "(((256,16),1,4),4):(((64,1),0,16),16384)">
!memref_smem_f16_5 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((16384,1),4):((1,0),16384)">
!memref_smem_f16_6 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((8192,1)):((1,0))">
!memref_smem_f16_7 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((8192,1),1):((1,0),0)">
!memref_smem_f16_8 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((8192,1),(1)):((1,0),(0))">
!memref_smem_f16_9 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((16384,1)):((1,0))">
!memref_smem_f16_10 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((16384,1),1):((1,0),0)">
!memref_smem_f16_11 = !cute.memref<f16, smem, align<128>, S<3,4,3>, "((16384,1),(1)):((1,0),(0))">
!memref_tmem_f32_ = !cute.memref<f32, tmem, align<16>, "((128,256),1,1):((65536,1),0,0)">
!memref_tmem_f32_1 = !cute.memref<f32, tmem, align<16>, "(((128,64)),((1,4),1,1)):(((65536,1)),((0,64),0,0))">
!memref_tmem_f32_2 = !cute.memref<f32, tmem, align<16>, "(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
!memref_tmem_f32_3 = !cute.memref<f32, tmem, align<16>, "((128,256)):((65536,1))">
!memref_tmem_f32_4 = !cute.memref<f32, tmem, align<16>, "(((64,32),1),1):(((1,65536),0),0)">
!memref_tmem_f32_5 = !cute.memref<f32, tmem, align<16>, "(((64,32),1),(1)):(((1,65536),0),(0))">
!memref_tmem_f32_6 = !cute.memref<f32, tmem, align<16>, "(((64,32),1)):(((1,65536),0))">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_128x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((128,16),1,4,4):((64,1),0,16,8192)">
      %1 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((256,16),1,4,4):((64,1),0,16,16384)">
      %2 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
      %3 = cute.static : !cute.tile<"[_;_;_]">
      %4 = cute.static : !cute.layout<"1:0">
      %5 = cute.static : !cute.shape<"(128,256,16)">
      %6 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
      %7 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
      %8 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
      %9 = cute.static : !cute.layout<"1:0">
      %10 = cute.static : !cute.layout<"(1,8192):(0,1)">
      %11 = cute.static : !cute.layout<"(1,8192):(0,1)">
      %12 = cute.static : !cute.layout<"1:0">
      %13 = cute.static : !cute.layout<"(1,16384):(0,1)">
      %14 = cute.static : !cute.layout<"(1,16384):(0,1)">
      %15 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %16 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %17 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %18 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %19 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %20 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %21 = arith.muli %17, %19 : i32
      %22 = arith.addi %16, %21 : i32
      %23 = arith.muli %18, %19 : i32
      %24 = arith.muli %23, %20 : i32
      %25 = arith.addi %22, %24 : i32
      %c32_i32 = arith.constant 32 : i32
      %26 = arith.floordivsi %25, %c32_i32 : i32
      %27 = cute_nvgpu.arch.make_warp_uniform(%26) : i32
      %28 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %29 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %30 = cute.static : !cute.int_tuple<"88">
      %ptr = cute.add_offset(%smem_ptr, %30) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %31 = cute.static : !cute.int_tuple<"0">
      %ptr_0 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %32 = cute.static : !cute.int_tuple<"64">
      %ptr_1 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %33 = cute.static : !cute.int_tuple<"80">
      %ptr_2 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %34 = cute.static : !cute.layout<"((128,16),1,4,4):((64,1),0,16,8192)">
      %35 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %c128_i32 = arith.constant 128 : i32
      %36 = arith.addi %35, %c128_i32 : i32
      %c1_i32 = arith.constant 1 : i32
      %37 = arith.subi %36, %c1_i32 : i32
      %c-128_i32 = arith.constant -128 : i32
      %38 = arith.andi %37, %c-128_i32 : i32
      %39 = arith.extsi %38 : i32 to i64
      %iv = cute.assume(%39) : (i64) -> !cute.i64<divby 128>
      %40 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %41 = cute.static : !cute.int_tuple<"65536">
      %ptr_3 = cute.add_offset(%40, %41) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_4 = cute.recast_iter(%40) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %view = cute.make_view(%iter_4, %34) : !memref_smem_f16_
      %42 = cute.static : !cute.layout<"((256,16),1,4,4):((64,1),0,16,16384)">
      %iter_5 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %view_6 = cute.make_view(%iter_5, %42) : !memref_smem_f16_1
      %43 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %44 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %45 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %46 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %47 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %48 = arith.muli %44, %46 : i32
      %49 = arith.addi %43, %48 : i32
      %50 = arith.muli %45, %46 : i32
      %51 = arith.muli %50, %47 : i32
      %52 = arith.addi %49, %51 : i32
      %53 = arith.floordivsi %52, %c32_i32 : i32
      %54 = cute_nvgpu.arch.make_warp_uniform(%53) : i32
      %c0_i32 = arith.constant 0 : i32
      %55 = arith.cmpi eq, %54, %c0_i32 : i32
      scf.if %55 {
        %c512_i32 = arith.constant 512 : i32
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      }
      %56 = arith.cmpi eq, %27, %c0_i32 : i32
      scf.if %56 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %57 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((128,16),1,4):((64,1),0,16)">
      %58 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((256,16),1,4):((64,1),0,16)">
      %iter_7 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %59 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %60 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %61 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %62 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %63 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %64 = arith.muli %60, %62 : i32
      %65 = arith.addi %59, %64 : i32
      %66 = arith.muli %61, %62 : i32
      %67 = arith.muli %66, %63 : i32
      %68 = arith.addi %65, %67 : i32
      %69 = arith.floordivsi %68, %c32_i32 : i32
      %70 = cute_nvgpu.arch.make_warp_uniform(%69) : i32
      %71 = arith.cmpi eq, %70, %c0_i32 : i32
      scf.if %71 {
        %206 = cute.static : !cute.int_tuple<"0">
        %ptr_127 = cute.add_offset(%iter_7, %206) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i64, smem, align<1024>>
        %207 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        %c1_i32_128 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %207, %c1_i32_128 : !llvm.ptr<3>, i32
        %208 = cute.static : !cute.int_tuple<"1">
        %ptr_129 = cute.add_offset(%iter_7, %208) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %209 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c1_i32_130 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %209, %c1_i32_130 : !llvm.ptr<3>, i32
        %210 = cute.static : !cute.int_tuple<"2">
        %ptr_131 = cute.add_offset(%iter_7, %210) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %211 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        %c1_i32_132 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %211, %c1_i32_132 : !llvm.ptr<3>, i32
        %212 = cute.static : !cute.int_tuple<"3">
        %ptr_133 = cute.add_offset(%iter_7, %212) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %213 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c1_i32_134 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %213, %c1_i32_134 : !llvm.ptr<3>, i32
      }
      %72 = cute.static : !cute.int_tuple<"4">
      %ptr_8 = cute.add_offset(%iter_7, %72) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %73 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %74 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %75 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %76 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %77 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %78 = arith.muli %74, %76 : i32
      %79 = arith.addi %73, %78 : i32
      %80 = arith.muli %75, %76 : i32
      %81 = arith.muli %80, %77 : i32
      %82 = arith.addi %79, %81 : i32
      %83 = arith.floordivsi %82, %c32_i32 : i32
      %84 = cute_nvgpu.arch.make_warp_uniform(%83) : i32
      %85 = arith.cmpi eq, %84, %c0_i32 : i32
      scf.if %85 {
        %206 = cute.static : !cute.int_tuple<"0">
        %ptr_127 = cute.add_offset(%ptr_8, %206) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i64, smem, align<32>>
        %207 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        %c1_i32_128 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %207, %c1_i32_128 : !llvm.ptr<3>, i32
        %208 = cute.static : !cute.int_tuple<"1">
        %ptr_129 = cute.add_offset(%ptr_8, %208) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %209 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c1_i32_130 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %209, %c1_i32_130 : !llvm.ptr<3>, i32
        %210 = cute.static : !cute.int_tuple<"2">
        %ptr_131 = cute.add_offset(%ptr_8, %210) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %211 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        %c1_i32_132 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %211, %c1_i32_132 : !llvm.ptr<3>, i32
        %212 = cute.static : !cute.int_tuple<"3">
        %ptr_133 = cute.add_offset(%ptr_8, %212) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %213 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c1_i32_134 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %213, %c1_i32_134 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_9 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      %86 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %87 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %88 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %89 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %90 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %91 = arith.muli %87, %89 : i32
      %92 = arith.addi %86, %91 : i32
      %93 = arith.muli %88, %89 : i32
      %94 = arith.muli %93, %90 : i32
      %95 = arith.addi %92, %94 : i32
      %96 = arith.floordivsi %95, %c32_i32 : i32
      %97 = cute_nvgpu.arch.make_warp_uniform(%96) : i32
      %98 = arith.cmpi eq, %97, %c0_i32 : i32
      scf.if %98 {
        %206 = cute.static : !cute.int_tuple<"0">
        %ptr_127 = cute.add_offset(%iter_9, %206) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"0">) -> !cute.ptr<i64, smem, align<64>>
        %207 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
        %c1_i32_128 = arith.constant 1 : i32
        nvvm.mbarrier.init.shared %207, %c1_i32_128 : !llvm.ptr<3>, i32
      }
      %99 = cute.static : !cute.int_tuple<"1">
      %ptr_10 = cute.add_offset(%iter_9, %99) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %100 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %101 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %102 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %103 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %104 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %105 = arith.muli %101, %103 : i32
      %106 = arith.addi %100, %105 : i32
      %107 = arith.muli %102, %103 : i32
      %108 = arith.muli %107, %104 : i32
      %109 = arith.addi %106, %108 : i32
      %110 = arith.floordivsi %109, %c32_i32 : i32
      %111 = cute_nvgpu.arch.make_warp_uniform(%110) : i32
      %112 = arith.cmpi eq, %111, %c0_i32 : i32
      scf.if %112 {
        %206 = cute.static : !cute.int_tuple<"0">
        %ptr_127 = cute.add_offset(%ptr_10, %206) : (!cute.ptr<i64, smem>, !cute.int_tuple<"0">) -> !cute.ptr<i64, smem>
        %207 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c128_i32_128 = arith.constant 128 : i32
        nvvm.mbarrier.init.shared %207, %c128_i32_128 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%28, %29) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %113:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_11 = cute.make_coord(%113#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %114:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c128_i32_12 = arith.constant 128 : i32
      %115 = arith.ceildivsi %114#0, %c128_i32_12 : i32
      %c64_i32 = arith.constant 64 : i32
      %116 = arith.ceildivsi %114#1, %c64_i32 : i32
      %shape = cute.make_shape(%115, %116) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %117 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0))">
      %lay_13 = cute.make_layout(%shape, %117) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %118:2 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_14 = cute.make_shape(%118#1) : (i32) -> !cute.shape<"(128,64,?)">
      %119 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %lay_15 = cute.make_layout(%shape_14, %119) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_11, %lay_13) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %120 = cute.static : !cute.int_tuple<"(0,0)">
      %tup = cute.add_offset(%120, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %view_16 = cute.make_view(%tup, %lay_15) : !cute.coord_tensor<"(0,?{div=128})", "(128,64,?):(1@1,1@0,64@0)">
      %coord_17 = cute.make_coord(%28, %29) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %121:2 = cute.get_scalars(%coord_17) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_18 = cute.make_coord(%121#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_19 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %122:2 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c256_i32 = arith.constant 256 : i32
      %123 = arith.ceildivsi %122#0, %c256_i32 : i32
      %c64_i32_20 = arith.constant 64 : i32
      %124 = arith.ceildivsi %122#1, %c64_i32_20 : i32
      %shape_21 = cute.make_shape(%123, %124) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %125 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %lay_22 = cute.make_layout(%shape_21, %125) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %126:2 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_23 = cute.make_shape(%126#1) : (i32) -> !cute.shape<"(256,64,?)">
      %127 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %lay_24 = cute.make_layout(%shape_23, %127) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_25 = cute.crd2idx(%coord_18, %lay_22) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %128 = cute.static : !cute.int_tuple<"(0,0)">
      %tup_26 = cute.add_offset(%128, %idx_25) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %view_27 = cute.make_view(%tup_26, %lay_24) : !cute.coord_tensor<"(0,?{div=256})", "(256,64,?):(1@1,1@0,64@0)">
      %coord_28 = cute.make_coord(%28, %29) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %129:2 = cute.get_scalars(%coord_28) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_29 = cute.make_coord(%129#0, %129#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_30 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %130:3 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %c128_i32_31 = arith.constant 128 : i32
      %131 = arith.ceildivsi %130#0, %c128_i32_31 : i32
      %c128_i64 = arith.constant 128 : i64
      %132 = arith.muli %130#2, %c128_i64 : i64
      %c256_i32_32 = arith.constant 256 : i32
      %133 = arith.ceildivsi %130#1, %c256_i32_32 : i32
      %shape_33 = cute.make_shape(%131, %133) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_34 = cute.assume(%130#2) : (i64) -> !cute.i64<divby 8192>
      %iv_35 = cute.assume(%132) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_34, %iv_35) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_36 = cute.make_layout(%shape_33, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %134:4 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %135 = cute.static : !cute.shape<"(128,256)">
      %iv_37 = cute.assume(%134#2) : (i64) -> !cute.i64<divby 8192>
      %stride_38 = cute.make_stride(%iv_37) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_39 = cute.make_layout(%135, %stride_38) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_40 = cute.crd2idx(%coord_29, %lay_36) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_41 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_42 = cute.add_offset(%iter_41, %idx_40) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %view_43 = cute.make_view(%ptr_42, %lay_39) : !memref_gmem_f16_1
      %iter_44 = cute.get_iter(%view_16) : !cute.coord_tensor<"(0,?{div=128})", "(128,64,?):(1@1,1@0,64@0)">
      %lay_45 = cute.get_layout(%view_16) : !cute.coord_tensor<"(0,?{div=128})", "(128,64,?):(1@1,1@0,64@0)">
      %136 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_46 = cute.make_shape(%136) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %137 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %lay_47 = cute.make_layout(%shape_46, %137) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %view_48 = cute.make_view(%iter_44, %lay_47) : !cute.coord_tensor<"(0,?{div=128})", "((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %iter_49 = cute.get_iter(%view_27) : !cute.coord_tensor<"(0,?{div=256})", "(256,64,?):(1@1,1@0,64@0)">
      %lay_50 = cute.get_layout(%view_27) : !cute.coord_tensor<"(0,?{div=256})", "(256,64,?):(1@1,1@0,64@0)">
      %138 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_51 = cute.make_shape(%138) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %139 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %lay_52 = cute.make_layout(%shape_51, %139) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %view_53 = cute.make_view(%iter_49, %lay_52) : !cute.coord_tensor<"(0,?{div=256})", "((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %iter_54 = cute.get_iter(%view_43) : !memref_gmem_f16_1
      %lay_55 = cute.get_layout(%view_43) : !memref_gmem_f16_1
      %140 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %141 = cute.static : !cute.shape<"((128,256),1,1)">
      %iv_56 = cute.assume(%140) : (i64) -> !cute.i64<divby 8192>
      %stride_57 = cute.make_stride(%iv_56) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_58 = cute.make_layout(%141, %stride_57) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %view_59 = cute.make_view(%iter_54, %lay_58) : !memref_gmem_f16_2
      %iter_60 = cute.get_iter(%view) : !memref_smem_f16_
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_60 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %view_61 = cute.make_view(%ummaSmemDesc) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,1024)">
      %iter_62 = cute.get_iter(%view_6) : !memref_smem_f16_1
      %ummaSmemDesc_63 = cute_nvgpu.make_umma_smem_desc(%iter_62 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %view_64 = cute.make_view(%ummaSmemDesc_63) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,2048)">
      %iter_65 = cute.get_iter(%view) : !memref_smem_f16_
      %view_66 = cute.make_view(%iter_65) : !memref_smem_f16_2
      %iter_67 = cute.get_iter(%view_48) : !cute.coord_tensor<"(0,?{div=128})", "((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %lay_68 = cute.get_layout(%view_48) : !cute.coord_tensor<"(0,?{div=128})", "((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %142 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_69 = cute.make_shape(%142) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %143 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %lay_70 = cute.make_layout(%shape_69, %143) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %view_71 = cute.make_view(%iter_67, %lay_70) : !cute.coord_tensor<"(0,?{div=128})", "(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %iter_72 = cute.get_iter(%view_66) : !memref_smem_f16_2
      %iter_73 = cute.get_iter(%view_71) : !cute.coord_tensor<"(0,?{div=128})", "(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %lay_74 = cute.get_layout(%view_71) : !cute.coord_tensor<"(0,?{div=128})", "(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %144 = cute.get_scalars(%lay_74) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %view_75 = cute.make_view(%iter_72) : !memref_smem_f16_3
      %shape_76 = cute.make_shape(%144) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %145 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %lay_77 = cute.make_layout(%shape_76, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %view_78 = cute.make_view(%iter_73, %lay_77) : !cute.coord_tensor<"(0,?{div=128})", "(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %iter_79 = cute.get_iter(%view_6) : !memref_smem_f16_1
      %view_80 = cute.make_view(%iter_79) : !memref_smem_f16_4
      %iter_81 = cute.get_iter(%view_53) : !cute.coord_tensor<"(0,?{div=256})", "((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %lay_82 = cute.get_layout(%view_53) : !cute.coord_tensor<"(0,?{div=256})", "((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %146 = cute.get_scalars(%lay_82) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_83 = cute.make_shape(%146) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %147 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %lay_84 = cute.make_layout(%shape_83, %147) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %view_85 = cute.make_view(%iter_81, %lay_84) : !cute.coord_tensor<"(0,?{div=256})", "(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %iter_86 = cute.get_iter(%view_80) : !memref_smem_f16_4
      %iter_87 = cute.get_iter(%view_85) : !cute.coord_tensor<"(0,?{div=256})", "(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %lay_88 = cute.get_layout(%view_85) : !cute.coord_tensor<"(0,?{div=256})", "(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %148 = cute.get_scalars(%lay_88) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %view_89 = cute.make_view(%iter_86) : !memref_smem_f16_5
      %shape_90 = cute.make_shape(%148) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %149 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %lay_91 = cute.make_layout(%shape_90, %149) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      %view_92 = cute.make_view(%iter_87, %lay_91) : !cute.coord_tensor<"(0,?{div=256})", "(((64,256),1),?):(((1@0,1@1),0),64@0)">
      %c1_i32_93 = arith.constant 1 : i32
      %c128_i32_94 = arith.constant 128 : i32
      nvvm.barrier id = %c1_i32_93 number_of_threads = %c128_i32_94
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %150 = cute.static : !cute.layout<"((128,256),1,1):((65536,1),0,0)">
      %view_95 = cute.make_view(%tmem_ptr, %150) : !memref_tmem_f32_
      %iter_96 = cute.get_iter(%view_95) : !memref_tmem_f32_
      %view_97 = cute.make_view(%iter_96) : !memref_tmem_f32_1
      %iter_98 = cute.get_iter(%view_59) : !memref_gmem_f16_2
      %lay_99 = cute.get_layout(%view_59) : !memref_gmem_f16_2
      %151 = cute.get_scalars(%lay_99) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %152 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %iv_100 = cute.assume(%151) : (i64) -> !cute.i64<divby 8192>
      %stride_101 = cute.make_stride(%iv_100) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_102 = cute.make_layout(%152, %stride_101) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %view_103 = cute.make_view(%iter_98, %lay_102) : !memref_gmem_f16_3
      %coord_104 = cute.make_coord(%15) : (i32) -> !cute.coord<"?">
      %iter_105 = cute.get_iter(%view_97) : !memref_tmem_f32_1
      %153 = cute.get_scalars(%coord_104) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32_106 = arith.constant 32 : i32
      %154 = arith.divsi %153, %c32_i32_106 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %155 = arith.muli %154, %c2097152_i32 : i32
      %iv_107 = cute.assume(%155) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple = cute.make_int_tuple(%iv_107) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_108 = cute.add_offset(%iter_105, %int_tuple) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %view_109 = cute.make_view(%ptr_108) : !memref_tmem_f32_2
      %coord_110 = cute.make_coord(%15) : (i32) -> !cute.coord<"?">
      %iter_111 = cute.get_iter(%view_103) : !memref_gmem_f16_3
      %lay_112 = cute.get_layout(%view_103) : !memref_gmem_f16_3
      %156 = cute.get_scalars(%lay_112) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %157 = cute.get_scalars(%coord_110) <{only_dynamic}> : !cute.coord<"?">
      %c32_i64 = arith.constant 32 : i64
      %158 = arith.muli %156, %c32_i64 : i64
      %c32_i32_113 = arith.constant 32 : i32
      %159 = arith.divsi %157, %c32_i32_113 : i32
      %c32_i32_114 = arith.constant 32 : i32
      %160 = arith.remsi %157, %c32_i32_114 : i32
      %161 = arith.extsi %160 : i32 to i64
      %162 = arith.muli %161, %156 : i64
      %163 = arith.extsi %159 : i32 to i64
      %164 = arith.muli %163, %158 : i64
      %165 = arith.addi %162, %164 : i64
      %iv_115 = cute.assume(%165) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_116 = cute.make_int_tuple(%iv_115) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_117 = cute.add_offset(%iter_111, %int_tuple_116) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %view_118 = cute.make_view(%ptr_117) : !memref_gmem_f16_4
      %166 = cute.static : !cute.layout<"((64,1),1):((1,0),0)">
      %rmem = cute.memref.alloca(%166) : !memref_rmem_f32_
      %167 = cute.static : !cute.layout<"((64,1),1):((1,0),0)">
      %rmem_119 = cute.memref.alloca(%167) : !memref_rmem_f16_
      %lay_120 = cute.get_layout(%view_16) : !cute.coord_tensor<"(0,?{div=128})", "(128,64,?):(1@1,1@0,64@0)">
      %sz = cute.size(%lay_120) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %168 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      %169 = arith.cmpi eq, %27, %c0_i32 : i32
      %170 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
      %171 = cute.static : !cute.tile<"[_;_;_]">
      %172 = cute.static : !cute.layout<"1:0">
      %173 = cute.static : !cute.shape<"(128,256,16)">
      %174 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
      %175 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
      %176 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
      %c0_i32_121 = arith.constant 0 : i32
      %c1_i32_122 = arith.constant 1 : i32
      %177:10 = scf.if %169 -> (i32, i32, i32, i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_) {
        %true_127 = arith.constant true
        scf.if %true_127 {
          %int_tuple_134 = cute.make_int_tuple(%c0_i32_121) : (i32) -> !cute.int_tuple<"?">
          %ptr_135 = cute.add_offset(%ptr_10, %int_tuple_134) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %237 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          %c10000000_i32 = arith.constant 10000000 : i32
          nvvm.mbarrier.try_wait.parity.shared %237, %c1_i32_122, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
        %c1_i32_128 = arith.constant 1 : i32
        %206 = arith.addi %c0_i32_121, %c1_i32_128 : i32
        %207 = arith.addi %c0_i32_121, %c1_i32_128 : i32
        %208 = arith.cmpi eq, %206, %c1_i32_128 : i32
        %209:2 = scf.if %208 -> (i32, i32) {
          %c1_i32_134 = arith.constant 1 : i32
          %237 = arith.xori %c1_i32_122, %c1_i32_134 : i32
          %c0_i32_135 = arith.constant 0 : i32
          scf.yield %c0_i32_135, %237 : i32, i32
        } else {
          scf.yield %206, %c1_i32_122 : i32, i32
        }
        %210 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
        %211 = cute.static : !cute.tile<"[_;_;_]">
        %212 = cute.static : !cute.layout<"1:0">
        %213 = cute.static : !cute.shape<"(128,256,16)">
        %214 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
        %215 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
        %216 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
        %c0_i32_129 = arith.constant 0 : i32
        %c1_i32_130 = arith.constant 1 : i32
        %true_131 = arith.constant true
        %c1_i32_132 = arith.constant 1 : i32
        %c4_i32_133 = arith.constant 4 : i32
        %217 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
        %218 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
        %219 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
        %220 = cute.static : !cute.tile<"[_;_;_]">
        %221 = cute.static : !cute.layout<"1:0">
        %222 = cute.static : !cute.shape<"(128,256,16)">
        %223 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
        %224 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
        %225 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
        %c2_i32 = arith.constant 2 : i32
        %226 = arith.minsi %c2_i32, %168 : i32
        %227:3 = scf.for %arg6 = %c0_i32_129 to %226 step %c1_i32_130 iter_args(%arg7 = %c0_i32_121, %arg8 = %c1_i32_122, %arg9 = %c0_i32_121) -> (i32, i32, i32)  : i32 {
          scf.if %true_131 {
            %int_tuple_185 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
            %ptr_186 = cute.add_offset(%ptr_8, %int_tuple_185) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %255 = builtin.unrealized_conversion_cast %ptr_186 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %c10000000_i32 = arith.constant 10000000 : i32
            nvvm.mbarrier.try_wait.parity.shared %255, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          }
          scf.if %true_131 {
            %255 = nvvm.elect.sync -> i1
            scf.if %255 {
              %int_tuple_185 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
              %ptr_186 = cute.add_offset(%iter_7, %int_tuple_185) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %256 = builtin.unrealized_conversion_cast %ptr_186 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %c49152_i32 = arith.constant 49152 : i32
              nvvm.mbarrier.txn %256, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
          }
          %237 = arith.addi %arg7, %c1_i32_132 : i32
          %238 = arith.addi %arg9, %c1_i32_132 : i32
          %239 = arith.cmpi eq, %237, %c4_i32_133 : i32
          %240:2 = scf.if %239 -> (i32, i32) {
            %255 = arith.xori %arg8, %c1_i32_132 : i32
            %c0_i32_185 = arith.constant 0 : i32
            scf.yield %c0_i32_185, %255 : i32, i32
          } else {
            scf.yield %237, %arg8 : i32, i32
          }
          %coord_134 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %lay_135 = cute.get_layout(%view_78) : !cute.coord_tensor<"(0,?{div=128})", "(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %idx_136 = cute.crd2idx(%coord_134, %lay_135) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %iter_137 = cute.get_iter(%view_78) : !cute.coord_tensor<"(0,?{div=128})", "(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %tup_138 = cute.add_offset(%iter_137, %idx_136) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %view_139 = cute.make_view(%tup_138) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
          %iter_140 = cute.get_iter(%view_139) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
          %e0_141, %e1 = cute.get_leaves(%iter_140) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %coord_142 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %241 = cute.static : !cute.layout<"((8192,1),4):((1,0),8192)">
          %idx_143 = cute.crd2idx(%coord_142, %241) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %iter_144 = cute.get_iter(%view_75) : !memref_smem_f16_3
          %ptr_145 = cute.add_offset(%iter_144, %idx_143) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %view_146 = cute.make_view(%ptr_145) : !memref_smem_f16_6
          %iter_147 = cute.get_iter(%view_146) : !memref_smem_f16_6
          %int_tuple_148 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_149 = cute.add_offset(%iter_7, %int_tuple_148) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %242 = cute.static : !cute.layout<"(((64,128),1),1):(((1@0,1@1),0),0)">
          %int_tuple_150 = cute.make_int_tuple(%e0_141, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %view_151 = cute.make_view(%int_tuple_150, %242) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),1):(((1@0,1@1),0),0)">
          %iter_152 = cute.get_iter(%view_151) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),1):(((1@0,1@1),0),0)">
          %view_153 = cute.make_view(%iter_152) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),(1)):(((1@0,1@1),0),(0))">
          %243 = cute.static : !cute.layout<"((8192,1),1):((1,0),0)">
          %view_154 = cute.make_view(%iter_147, %243) : !memref_smem_f16_7
          %iter_155 = cute.get_iter(%view_154) : !memref_smem_f16_7
          %view_156 = cute.make_view(%iter_155) : !memref_smem_f16_8
          %244 = cute_nvgpu.atom.set_value(%217, %ptr_149 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
          %245 = cute.static : !cute.layout<"1:0">
          %iter_157 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),(1)):(((1@0,1@1),0),(0))">
          %iter_158 = cute.get_iter(%view_156) : !memref_smem_f16_8
          %246 = cute.static : !cute.int_tuple<"1">
          %247 = cute.get_scalars(%246) : !cute.int_tuple<"1">
          %c0_i32_159 = arith.constant 0 : i32
          %c1_i32_160 = arith.constant 1 : i32
          scf.for %arg10 = %c0_i32_159 to %247 step %c1_i32_160  : i32 {
            %255 = cute.static : !cute.layout<"(((64,128),1)):(((1@0,1@1),0))">
            %256 = cute.static : !cute.int_tuple<"(0,0)">
            %tup_185 = cute.add_offset(%iter_157, %256) : (!cute.int_tuple<"(?{div=64},?{div=128})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %view_186 = cute.make_view(%tup_185, %255) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
            %257 = cute.static : !cute.layout<"((8192,1)):((1,0))">
            %258 = cute.static : !cute.int_tuple<"0">
            %ptr_187 = cute.add_offset(%iter_158, %258) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %view_188 = cute.make_view(%ptr_187, %257) : !memref_smem_f16_6
            %iter_189 = cute.get_iter(%view_186) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
            %iter_190 = cute.get_iter(%view_188) : !memref_smem_f16_6
            %259 = cute_nvgpu.atom.get_value(%244 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %260 = cute_nvgpu.atom.get_value(%244 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%244 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %261:2 = cute.get_scalars(%iter_189) : !cute.int_tuple<"(?{div=64},?{div=128})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_190 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %259 : !cute.ptr<smem, align<8>>, [%261#0, %261#1] : i32, i32) cache_policy = %260 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %lay_161 = cute.get_layout(%view_92) : !cute.coord_tensor<"(0,?{div=256})", "(((64,256),1),?):(((1@0,1@1),0),64@0)">
          %idx_162 = cute.crd2idx(%coord_134, %lay_161) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %iter_163 = cute.get_iter(%view_92) : !cute.coord_tensor<"(0,?{div=256})", "(((64,256),1),?):(((1@0,1@1),0),64@0)">
          %tup_164 = cute.add_offset(%iter_163, %idx_162) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %view_165 = cute.make_view(%tup_164) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
          %iter_166 = cute.get_iter(%view_165) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
          %e0_167, %e1_168 = cute.get_leaves(%iter_166) : !cute.int_tuple<"(?{div=64},?{div=256})">
          %248 = cute.static : !cute.layout<"((16384,1),4):((1,0),16384)">
          %idx_169 = cute.crd2idx(%coord_142, %248) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
          %iter_170 = cute.get_iter(%view_89) : !memref_smem_f16_5
          %ptr_171 = cute.add_offset(%iter_170, %idx_169) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %view_172 = cute.make_view(%ptr_171) : !memref_smem_f16_9
          %iter_173 = cute.get_iter(%view_172) : !memref_smem_f16_9
          %249 = cute.static : !cute.layout<"(((64,256),1),1):(((1@0,1@1),0),0)">
          %int_tuple_174 = cute.make_int_tuple(%e0_167, %e1_168) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %view_175 = cute.make_view(%int_tuple_174, %249) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),1):(((1@0,1@1),0),0)">
          %iter_176 = cute.get_iter(%view_175) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),1):(((1@0,1@1),0),0)">
          %view_177 = cute.make_view(%iter_176) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),(1)):(((1@0,1@1),0),(0))">
          %250 = cute.static : !cute.layout<"((16384,1),1):((1,0),0)">
          %view_178 = cute.make_view(%iter_173, %250) : !memref_smem_f16_10
          %iter_179 = cute.get_iter(%view_178) : !memref_smem_f16_10
          %view_180 = cute.make_view(%iter_179) : !memref_smem_f16_11
          %251 = cute_nvgpu.atom.set_value(%218, %ptr_149 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
          %252 = cute.static : !cute.layout<"1:0">
          %iter_181 = cute.get_iter(%view_177) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),(1)):(((1@0,1@1),0),(0))">
          %iter_182 = cute.get_iter(%view_180) : !memref_smem_f16_11
          %253 = cute.static : !cute.int_tuple<"1">
          %254 = cute.get_scalars(%253) : !cute.int_tuple<"1">
          %c0_i32_183 = arith.constant 0 : i32
          %c1_i32_184 = arith.constant 1 : i32
          scf.for %arg10 = %c0_i32_183 to %254 step %c1_i32_184  : i32 {
            %255 = cute.static : !cute.layout<"(((64,256),1)):(((1@0,1@1),0))">
            %256 = cute.static : !cute.int_tuple<"(0,0)">
            %tup_185 = cute.add_offset(%iter_181, %256) : (!cute.int_tuple<"(?{div=64},?{div=256})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %view_186 = cute.make_view(%tup_185, %255) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
            %257 = cute.static : !cute.layout<"((16384,1)):((1,0))">
            %258 = cute.static : !cute.int_tuple<"0">
            %ptr_187 = cute.add_offset(%iter_182, %258) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %view_188 = cute.make_view(%ptr_187, %257) : !memref_smem_f16_9
            %iter_189 = cute.get_iter(%view_186) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
            %iter_190 = cute.get_iter(%view_188) : !memref_smem_f16_9
            %259 = cute_nvgpu.atom.get_value(%251 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %260 = cute_nvgpu.atom.get_value(%251 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%251 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %261:2 = cute.get_scalars(%iter_189) : !cute.int_tuple<"(?{div=64},?{div=256})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_190 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %259 : !cute.ptr<smem, align<8>>, [%261#0, %261#1] : i32, i32) cache_policy = %260 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %240#0, %240#1, %238 : i32, i32, i32
        }
        %228:7 = scf.for %arg6 = %c0_i32_129 to %168 step %c1_i32_130 iter_args(%arg7 = %227#2, %arg8 = %227#0, %arg9 = %227#1, %arg10 = %c0_i32_121, %arg11 = %c0_i32_121, %arg12 = %c0_i32_121, %arg13 = %arg0) -> (i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_)  : i32 {
          %237 = arith.addi %arg6, %226 : i32
          %238 = arith.cmpi ult, %237, %168 : i32
          %239:3 = scf.if %238 -> (i32, i32, i32) {
            scf.if %true_131 {
              %int_tuple_241 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
              %ptr_242 = cute.add_offset(%ptr_8, %int_tuple_241) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %303 = builtin.unrealized_conversion_cast %ptr_242 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %c10000000_i32 = arith.constant 10000000 : i32
              nvvm.mbarrier.try_wait.parity.shared %303, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            scf.if %true_131 {
              %303 = nvvm.elect.sync -> i1
              scf.if %303 {
                %int_tuple_241 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
                %ptr_242 = cute.add_offset(%iter_7, %int_tuple_241) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
                %304 = builtin.unrealized_conversion_cast %ptr_242 : !cute.ptr<i64, smem> to !llvm.ptr<3>
                %c49152_i32 = arith.constant 49152 : i32
                nvvm.mbarrier.txn %304, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
              }
            }
            %285 = arith.addi %arg8, %c1_i32_132 : i32
            %286 = arith.addi %arg7, %c1_i32_132 : i32
            %287 = arith.cmpi eq, %285, %c4_i32_133 : i32
            %288:2 = scf.if %287 -> (i32, i32) {
              %303 = arith.xori %arg9, %c1_i32_132 : i32
              %c0_i32_241 = arith.constant 0 : i32
              scf.yield %c0_i32_241, %303 : i32, i32
            } else {
              scf.yield %285, %arg9 : i32, i32
            }
            %coord_190 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %lay_191 = cute.get_layout(%view_78) : !cute.coord_tensor<"(0,?{div=128})", "(((64,128),1),?):(((1@0,1@1),0),64@0)">
            %idx_192 = cute.crd2idx(%coord_190, %lay_191) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %iter_193 = cute.get_iter(%view_78) : !cute.coord_tensor<"(0,?{div=128})", "(((64,128),1),?):(((1@0,1@1),0),64@0)">
            %tup_194 = cute.add_offset(%iter_193, %idx_192) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %view_195 = cute.make_view(%tup_194) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
            %iter_196 = cute.get_iter(%view_195) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
            %e0_197, %e1 = cute.get_leaves(%iter_196) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_198 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %289 = cute.static : !cute.layout<"((8192,1),4):((1,0),8192)">
            %idx_199 = cute.crd2idx(%coord_198, %289) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %iter_200 = cute.get_iter(%view_75) : !memref_smem_f16_3
            %ptr_201 = cute.add_offset(%iter_200, %idx_199) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %view_202 = cute.make_view(%ptr_201) : !memref_smem_f16_6
            %iter_203 = cute.get_iter(%view_202) : !memref_smem_f16_6
            %int_tuple_204 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_205 = cute.add_offset(%iter_7, %int_tuple_204) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %290 = cute.static : !cute.layout<"(((64,128),1),1):(((1@0,1@1),0),0)">
            %int_tuple_206 = cute.make_int_tuple(%e0_197, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %view_207 = cute.make_view(%int_tuple_206, %290) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),1):(((1@0,1@1),0),0)">
            %iter_208 = cute.get_iter(%view_207) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),1):(((1@0,1@1),0),0)">
            %view_209 = cute.make_view(%iter_208) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),(1)):(((1@0,1@1),0),(0))">
            %291 = cute.static : !cute.layout<"((8192,1),1):((1,0),0)">
            %view_210 = cute.make_view(%iter_203, %291) : !memref_smem_f16_7
            %iter_211 = cute.get_iter(%view_210) : !memref_smem_f16_7
            %view_212 = cute.make_view(%iter_211) : !memref_smem_f16_8
            %292 = cute_nvgpu.atom.set_value(%217, %ptr_205 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
            %293 = cute.static : !cute.layout<"1:0">
            %iter_213 = cute.get_iter(%view_209) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1),(1)):(((1@0,1@1),0),(0))">
            %iter_214 = cute.get_iter(%view_212) : !memref_smem_f16_8
            %294 = cute.static : !cute.int_tuple<"1">
            %295 = cute.get_scalars(%294) : !cute.int_tuple<"1">
            %c0_i32_215 = arith.constant 0 : i32
            %c1_i32_216 = arith.constant 1 : i32
            scf.for %arg14 = %c0_i32_215 to %295 step %c1_i32_216  : i32 {
              %303 = cute.static : !cute.layout<"(((64,128),1)):(((1@0,1@1),0))">
              %304 = cute.static : !cute.int_tuple<"(0,0)">
              %tup_241 = cute.add_offset(%iter_213, %304) : (!cute.int_tuple<"(?{div=64},?{div=128})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
              %view_242 = cute.make_view(%tup_241, %303) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
              %305 = cute.static : !cute.layout<"((8192,1)):((1,0))">
              %306 = cute.static : !cute.int_tuple<"0">
              %ptr_243 = cute.add_offset(%iter_214, %306) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
              %view_244 = cute.make_view(%ptr_243, %305) : !memref_smem_f16_6
              %iter_245 = cute.get_iter(%view_242) : !cute.coord_tensor<"(?{div=64},?{div=128})", "(((64,128),1)):(((1@0,1@1),0))">
              %iter_246 = cute.get_iter(%view_244) : !memref_smem_f16_6
              %307 = cute_nvgpu.atom.get_value(%292 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %308 = cute_nvgpu.atom.get_value(%292 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%292 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %309:2 = cute.get_scalars(%iter_245) : !cute.int_tuple<"(?{div=64},?{div=128})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_246 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %307 : !cute.ptr<smem, align<8>>, [%309#0, %309#1] : i32, i32) cache_policy = %308 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %lay_217 = cute.get_layout(%view_92) : !cute.coord_tensor<"(0,?{div=256})", "(((64,256),1),?):(((1@0,1@1),0),64@0)">
            %idx_218 = cute.crd2idx(%coord_190, %lay_217) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %iter_219 = cute.get_iter(%view_92) : !cute.coord_tensor<"(0,?{div=256})", "(((64,256),1),?):(((1@0,1@1),0),64@0)">
            %tup_220 = cute.add_offset(%iter_219, %idx_218) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %view_221 = cute.make_view(%tup_220) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
            %iter_222 = cute.get_iter(%view_221) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
            %e0_223, %e1_224 = cute.get_leaves(%iter_222) : !cute.int_tuple<"(?{div=64},?{div=256})">
            %296 = cute.static : !cute.layout<"((16384,1),4):((1,0),16384)">
            %idx_225 = cute.crd2idx(%coord_198, %296) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
            %iter_226 = cute.get_iter(%view_89) : !memref_smem_f16_5
            %ptr_227 = cute.add_offset(%iter_226, %idx_225) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %view_228 = cute.make_view(%ptr_227) : !memref_smem_f16_9
            %iter_229 = cute.get_iter(%view_228) : !memref_smem_f16_9
            %297 = cute.static : !cute.layout<"(((64,256),1),1):(((1@0,1@1),0),0)">
            %int_tuple_230 = cute.make_int_tuple(%e0_223, %e1_224) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %view_231 = cute.make_view(%int_tuple_230, %297) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),1):(((1@0,1@1),0),0)">
            %iter_232 = cute.get_iter(%view_231) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),1):(((1@0,1@1),0),0)">
            %view_233 = cute.make_view(%iter_232) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),(1)):(((1@0,1@1),0),(0))">
            %298 = cute.static : !cute.layout<"((16384,1),1):((1,0),0)">
            %view_234 = cute.make_view(%iter_229, %298) : !memref_smem_f16_10
            %iter_235 = cute.get_iter(%view_234) : !memref_smem_f16_10
            %view_236 = cute.make_view(%iter_235) : !memref_smem_f16_11
            %299 = cute_nvgpu.atom.set_value(%218, %ptr_205 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
            %300 = cute.static : !cute.layout<"1:0">
            %iter_237 = cute.get_iter(%view_233) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1),(1)):(((1@0,1@1),0),(0))">
            %iter_238 = cute.get_iter(%view_236) : !memref_smem_f16_11
            %301 = cute.static : !cute.int_tuple<"1">
            %302 = cute.get_scalars(%301) : !cute.int_tuple<"1">
            %c0_i32_239 = arith.constant 0 : i32
            %c1_i32_240 = arith.constant 1 : i32
            scf.for %arg14 = %c0_i32_239 to %302 step %c1_i32_240  : i32 {
              %303 = cute.static : !cute.layout<"(((64,256),1)):(((1@0,1@1),0))">
              %304 = cute.static : !cute.int_tuple<"(0,0)">
              %tup_241 = cute.add_offset(%iter_237, %304) : (!cute.int_tuple<"(?{div=64},?{div=256})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
              %view_242 = cute.make_view(%tup_241, %303) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
              %305 = cute.static : !cute.layout<"((16384,1)):((1,0))">
              %306 = cute.static : !cute.int_tuple<"0">
              %ptr_243 = cute.add_offset(%iter_238, %306) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
              %view_244 = cute.make_view(%ptr_243, %305) : !memref_smem_f16_9
              %iter_245 = cute.get_iter(%view_242) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(((64,256),1)):(((1@0,1@1),0))">
              %iter_246 = cute.get_iter(%view_244) : !memref_smem_f16_9
              %307 = cute_nvgpu.atom.get_value(%299 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %308 = cute_nvgpu.atom.get_value(%299 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%299 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %309:2 = cute.get_scalars(%iter_245) : !cute.int_tuple<"(?{div=64},?{div=256})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_246 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %307 : !cute.ptr<smem, align<8>>, [%309#0, %309#1] : i32, i32) cache_policy = %308 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %288#0, %288#1, %286 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          scf.if %true_131 {
            %int_tuple_190 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
            %ptr_191 = cute.add_offset(%iter_7, %int_tuple_190) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %285 = builtin.unrealized_conversion_cast %ptr_191 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %c10000000_i32 = arith.constant 10000000 : i32
            nvvm.mbarrier.try_wait.parity.shared %285, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          }
          %240 = arith.addi %arg11, %c1_i32_132 : i32
          %241 = arith.addi %arg10, %c1_i32_132 : i32
          %242 = arith.cmpi eq, %240, %c4_i32_133 : i32
          %243:2 = scf.if %242 -> (i32, i32) {
            %285 = arith.xori %arg12, %c1_i32_132 : i32
            %c0_i32_190 = arith.constant 0 : i32
            scf.yield %c0_i32_190, %285 : i32, i32
          } else {
            scf.yield %240, %arg12 : i32, i32
          }
          %coord_134 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
          %244 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
          %idx_135 = cute.crd2idx(%coord_134, %244) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %iter_136 = cute.get_iter(%view_61) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,1024)">
          %tup_137 = cute.add_offset(%iter_136, %idx_135) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
          %view_138 = cute.make_view(%tup_137) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %245 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
          %idx_139 = cute.crd2idx(%coord_134, %245) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %iter_140 = cute.get_iter(%view_64) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,2048)">
          %tup_141 = cute.add_offset(%iter_140, %idx_139) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
          %view_142 = cute.make_view(%tup_141) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_143 = cute.get_iter(%view_138) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_144 = cute.get_iter(%view_142) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_145 = cute.get_iter(%view_95) : !memref_tmem_f32_
          %246 = cute.static : !cute.layout<"1:0">
          %247 = cute.static : !cute.int_tuple<"1">
          %248 = cute.static : !cute.int_tuple<"1">
          %249 = cute.static : !cute.int_tuple<"1">
          %250 = cute.get_scalars(%247) : !cute.int_tuple<"1">
          %251 = cute.get_scalars(%248) : !cute.int_tuple<"1">
          %252 = cute.get_scalars(%249) : !cute.int_tuple<"1">
          %c0_i32_146 = arith.constant 0 : i32
          %c1_i32_147 = arith.constant 1 : i32
          scf.for %arg14 = %c0_i32_146 to %250 step %c1_i32_147  : i32 {
            scf.for %arg15 = %c0_i32_146 to %251 step %c1_i32_147  : i32 {
              scf.for %arg16 = %c0_i32_146 to %252 step %c1_i32_147  : i32 {
                %285 = cute.static : !cute.layout<"(1):(0)">
                %286 = cute.static : !cute.int_tuple<"0">
                %tup_190 = cute.add_offset(%iter_143, %286) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_191 = cute.make_view(%tup_190, %285) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %287 = cute.static : !cute.layout<"(1):(0)">
                %288 = cute.static : !cute.int_tuple<"0">
                %tup_192 = cute.add_offset(%iter_144, %288) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_193 = cute.make_view(%tup_192, %287) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %289 = cute.static : !cute.layout<"((128,256)):((65536,1))">
                %290 = cute.static : !cute.int_tuple<"0">
                %ptr_194 = cute.add_offset(%iter_145, %290) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, tmem, align<16>>
                %view_195 = cute.make_view(%ptr_194, %289) : !memref_tmem_f32_3
                %iter_196 = cute.get_iter(%view_191) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_197 = cute.get_iter(%view_193) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_198 = cute.get_iter(%view_195) : !memref_tmem_f32_3
                %291 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %292 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %293 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %c138412048_i32 = arith.constant 138412048 : i32
                %294 = arith.extui %291 : i1 to i32
                %295 = arith.extui %292 : i1 to i32
                %c13_i32 = arith.constant 13 : i32
                %c14_i32 = arith.constant 14 : i32
                %296 = arith.shli %294, %c13_i32 : i32
                %297 = arith.shli %295, %c14_i32 : i32
                %298 = arith.ori %296, %c138412048_i32 : i32
                %299 = arith.ori %298, %297 : i32
                cute_nvgpu.arch.mma.SM100.umma(%iter_196, %iter_197, %iter_198, %299, %293) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %253 = cute_nvgpu.atom.set_value(%arg13, %true_131 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_148 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
          %254 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
          %idx_149 = cute.crd2idx(%coord_148, %254) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %iter_150 = cute.get_iter(%view_61) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,1024)">
          %tup_151 = cute.add_offset(%iter_150, %idx_149) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %view_152 = cute.make_view(%tup_151) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %255 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
          %idx_153 = cute.crd2idx(%coord_148, %255) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %iter_154 = cute.get_iter(%view_64) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,2048)">
          %tup_155 = cute.add_offset(%iter_154, %idx_153) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %view_156 = cute.make_view(%tup_155) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_157 = cute.get_iter(%view_152) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_158 = cute.get_iter(%view_156) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_159 = cute.get_iter(%view_95) : !memref_tmem_f32_
          %256 = cute.static : !cute.layout<"1:0">
          %257 = cute.static : !cute.int_tuple<"1">
          %258 = cute.static : !cute.int_tuple<"1">
          %259 = cute.static : !cute.int_tuple<"1">
          %260 = cute.get_scalars(%257) : !cute.int_tuple<"1">
          %261 = cute.get_scalars(%258) : !cute.int_tuple<"1">
          %262 = cute.get_scalars(%259) : !cute.int_tuple<"1">
          %c0_i32_160 = arith.constant 0 : i32
          %c1_i32_161 = arith.constant 1 : i32
          scf.for %arg14 = %c0_i32_160 to %260 step %c1_i32_161  : i32 {
            scf.for %arg15 = %c0_i32_160 to %261 step %c1_i32_161  : i32 {
              scf.for %arg16 = %c0_i32_160 to %262 step %c1_i32_161  : i32 {
                %285 = cute.static : !cute.layout<"(1):(0)">
                %286 = cute.static : !cute.int_tuple<"0">
                %tup_190 = cute.add_offset(%iter_157, %286) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_191 = cute.make_view(%tup_190, %285) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %287 = cute.static : !cute.layout<"(1):(0)">
                %288 = cute.static : !cute.int_tuple<"0">
                %tup_192 = cute.add_offset(%iter_158, %288) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_193 = cute.make_view(%tup_192, %287) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %289 = cute.static : !cute.layout<"((128,256)):((65536,1))">
                %290 = cute.static : !cute.int_tuple<"0">
                %ptr_194 = cute.add_offset(%iter_159, %290) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, tmem, align<16>>
                %view_195 = cute.make_view(%ptr_194, %289) : !memref_tmem_f32_3
                %iter_196 = cute.get_iter(%view_191) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_197 = cute.get_iter(%view_193) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_198 = cute.get_iter(%view_195) : !memref_tmem_f32_3
                %291 = cute_nvgpu.atom.get_value(%253 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %292 = cute_nvgpu.atom.get_value(%253 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %293 = cute_nvgpu.atom.get_value(%253 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %c138412048_i32 = arith.constant 138412048 : i32
                %294 = arith.extui %291 : i1 to i32
                %295 = arith.extui %292 : i1 to i32
                %c13_i32 = arith.constant 13 : i32
                %c14_i32 = arith.constant 14 : i32
                %296 = arith.shli %294, %c13_i32 : i32
                %297 = arith.shli %295, %c14_i32 : i32
                %298 = arith.ori %296, %c138412048_i32 : i32
                %299 = arith.ori %298, %297 : i32
                cute_nvgpu.arch.mma.SM100.umma(%iter_196, %iter_197, %iter_198, %299, %293) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %263 = cute_nvgpu.atom.set_value(%253, %true_131 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_162 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
          %264 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
          %idx_163 = cute.crd2idx(%coord_162, %264) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
          %iter_164 = cute.get_iter(%view_61) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,1024)">
          %tup_165 = cute.add_offset(%iter_164, %idx_163) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %view_166 = cute.make_view(%tup_165) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %265 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
          %idx_167 = cute.crd2idx(%coord_162, %265) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
          %iter_168 = cute.get_iter(%view_64) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,2048)">
          %tup_169 = cute.add_offset(%iter_168, %idx_167) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %view_170 = cute.make_view(%tup_169) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_171 = cute.get_iter(%view_166) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_172 = cute.get_iter(%view_170) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_173 = cute.get_iter(%view_95) : !memref_tmem_f32_
          %266 = cute.static : !cute.layout<"1:0">
          %267 = cute.static : !cute.int_tuple<"1">
          %268 = cute.static : !cute.int_tuple<"1">
          %269 = cute.static : !cute.int_tuple<"1">
          %270 = cute.get_scalars(%267) : !cute.int_tuple<"1">
          %271 = cute.get_scalars(%268) : !cute.int_tuple<"1">
          %272 = cute.get_scalars(%269) : !cute.int_tuple<"1">
          %c0_i32_174 = arith.constant 0 : i32
          %c1_i32_175 = arith.constant 1 : i32
          scf.for %arg14 = %c0_i32_174 to %270 step %c1_i32_175  : i32 {
            scf.for %arg15 = %c0_i32_174 to %271 step %c1_i32_175  : i32 {
              scf.for %arg16 = %c0_i32_174 to %272 step %c1_i32_175  : i32 {
                %285 = cute.static : !cute.layout<"(1):(0)">
                %286 = cute.static : !cute.int_tuple<"0">
                %tup_190 = cute.add_offset(%iter_171, %286) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_191 = cute.make_view(%tup_190, %285) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %287 = cute.static : !cute.layout<"(1):(0)">
                %288 = cute.static : !cute.int_tuple<"0">
                %tup_192 = cute.add_offset(%iter_172, %288) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_193 = cute.make_view(%tup_192, %287) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %289 = cute.static : !cute.layout<"((128,256)):((65536,1))">
                %290 = cute.static : !cute.int_tuple<"0">
                %ptr_194 = cute.add_offset(%iter_173, %290) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, tmem, align<16>>
                %view_195 = cute.make_view(%ptr_194, %289) : !memref_tmem_f32_3
                %iter_196 = cute.get_iter(%view_191) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_197 = cute.get_iter(%view_193) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_198 = cute.get_iter(%view_195) : !memref_tmem_f32_3
                %291 = cute_nvgpu.atom.get_value(%263 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %292 = cute_nvgpu.atom.get_value(%263 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %293 = cute_nvgpu.atom.get_value(%263 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %c138412048_i32 = arith.constant 138412048 : i32
                %294 = arith.extui %291 : i1 to i32
                %295 = arith.extui %292 : i1 to i32
                %c13_i32 = arith.constant 13 : i32
                %c14_i32 = arith.constant 14 : i32
                %296 = arith.shli %294, %c13_i32 : i32
                %297 = arith.shli %295, %c14_i32 : i32
                %298 = arith.ori %296, %c138412048_i32 : i32
                %299 = arith.ori %298, %297 : i32
                cute_nvgpu.arch.mma.SM100.umma(%iter_196, %iter_197, %iter_198, %299, %293) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %273 = cute_nvgpu.atom.set_value(%263, %true_131 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_176 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
          %274 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
          %idx_177 = cute.crd2idx(%coord_176, %274) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %iter_178 = cute.get_iter(%view_61) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,1024)">
          %tup_179 = cute.add_offset(%iter_178, %idx_177) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %view_180 = cute.make_view(%tup_179) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %275 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
          %idx_181 = cute.crd2idx(%coord_176, %275) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %iter_182 = cute.get_iter(%view_64) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1,4,4):(0,0,2,2048)">
          %tup_183 = cute.add_offset(%iter_182, %idx_181) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %view_184 = cute.make_view(%tup_183) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_185 = cute.get_iter(%view_180) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_186 = cute.get_iter(%view_184) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1,1):(0,0)">
          %iter_187 = cute.get_iter(%view_95) : !memref_tmem_f32_
          %276 = cute.static : !cute.layout<"1:0">
          %277 = cute.static : !cute.int_tuple<"1">
          %278 = cute.static : !cute.int_tuple<"1">
          %279 = cute.static : !cute.int_tuple<"1">
          %280 = cute.get_scalars(%277) : !cute.int_tuple<"1">
          %281 = cute.get_scalars(%278) : !cute.int_tuple<"1">
          %282 = cute.get_scalars(%279) : !cute.int_tuple<"1">
          %c0_i32_188 = arith.constant 0 : i32
          %c1_i32_189 = arith.constant 1 : i32
          scf.for %arg14 = %c0_i32_188 to %280 step %c1_i32_189  : i32 {
            scf.for %arg15 = %c0_i32_188 to %281 step %c1_i32_189  : i32 {
              scf.for %arg16 = %c0_i32_188 to %282 step %c1_i32_189  : i32 {
                %285 = cute.static : !cute.layout<"(1):(0)">
                %286 = cute.static : !cute.int_tuple<"0">
                %tup_190 = cute.add_offset(%iter_185, %286) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_191 = cute.make_view(%tup_190, %285) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %287 = cute.static : !cute.layout<"(1):(0)">
                %288 = cute.static : !cute.int_tuple<"0">
                %tup_192 = cute.add_offset(%iter_186, %288) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"0">) -> !cute_nvgpu.smem_desc
                %view_193 = cute.make_view(%tup_192, %287) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %289 = cute.static : !cute.layout<"((128,256)):((65536,1))">
                %290 = cute.static : !cute.int_tuple<"0">
                %ptr_194 = cute.add_offset(%iter_187, %290) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, tmem, align<16>>
                %view_195 = cute.make_view(%ptr_194, %289) : !memref_tmem_f32_3
                %iter_196 = cute.get_iter(%view_191) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_197 = cute.get_iter(%view_193) : !cute_nvgpu.smem_desc_view<!cute_nvgpu.smem_desc, "(1):(0)">
                %iter_198 = cute.get_iter(%view_195) : !memref_tmem_f32_3
                %291 = cute_nvgpu.atom.get_value(%273 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %292 = cute_nvgpu.atom.get_value(%273 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %293 = cute_nvgpu.atom.get_value(%273 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %c138412048_i32 = arith.constant 138412048 : i32
                %294 = arith.extui %291 : i1 to i32
                %295 = arith.extui %292 : i1 to i32
                %c13_i32 = arith.constant 13 : i32
                %c14_i32 = arith.constant 14 : i32
                %296 = arith.shli %294, %c13_i32 : i32
                %297 = arith.shli %295, %c14_i32 : i32
                %298 = arith.ori %296, %c138412048_i32 : i32
                %299 = arith.ori %298, %297 : i32
                cute_nvgpu.arch.mma.SM100.umma(%iter_196, %iter_197, %iter_198, %299, %293) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %283 = cute_nvgpu.atom.set_value(%273, %true_131 : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %284 = nvvm.elect.sync -> i1
          scf.if %284 {
            %int_tuple_190 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
            %ptr_191 = cute.add_offset(%ptr_8, %int_tuple_190) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %285 = builtin.unrealized_conversion_cast %ptr_191 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %285 : !llvm.ptr<3>
          }
          scf.yield %239#2, %239#0, %239#1, %241, %243#0, %243#1, %283 : i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_
        }
        %229 = nvvm.elect.sync -> i1
        scf.if %229 {
          %int_tuple_134 = cute.make_int_tuple(%c0_i32_121) : (i32) -> !cute.int_tuple<"?">
          %ptr_135 = cute.add_offset(%iter_9, %int_tuple_134) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %237 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.tcgen05.commit.arrive %237 : !llvm.ptr<3>
        }
        %230 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
        %231 = cute.static : !cute.tile<"[_;_;_]">
        %232 = cute.static : !cute.layout<"1:0">
        %233 = cute.static : !cute.shape<"(128,256,16)">
        %234 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
        %235 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
        %236 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
        scf.yield %207, %209#0, %209#1, %228#0, %228#1, %228#2, %228#3, %228#4, %228#5, %228#6 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_
      } else {
        %206 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
        %207 = cute.static : !cute.tile<"[_;_;_]">
        %208 = cute.static : !cute.layout<"1:0">
        %209 = cute.static : !cute.shape<"(128,256,16)">
        %210 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
        %211 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
        %212 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
        scf.yield %c0_i32_121, %c0_i32_121, %c1_i32_122, %c0_i32_121, %c0_i32_121, %c1_i32_122, %c0_i32_121, %c0_i32_121, %c0_i32_121, %arg0 : i32, i32, i32, i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_
      }
      %178 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %179 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %180 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %181 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %182 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %183 = arith.muli %179, %181 : i32
      %184 = arith.addi %178, %183 : i32
      %185 = arith.muli %180, %181 : i32
      %186 = arith.muli %185, %182 : i32
      %187 = arith.addi %184, %186 : i32
      %188 = arith.floordivsi %187, %c32_i32 : i32
      %189 = cute_nvgpu.arch.make_warp_uniform(%188) : i32
      %190 = arith.cmpi eq, %189, %c0_i32 : i32
      scf.if %190 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      }
      %true = arith.constant true
      scf.if %true {
        %c0_i32_127 = arith.constant 0 : i32
        %int_tuple_128 = cute.make_int_tuple(%c0_i32_127) : (i32) -> !cute.int_tuple<"?">
        %ptr_129 = cute.add_offset(%iter_9, %int_tuple_128) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %206 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %c0_i32_130 = arith.constant 0 : i32
        %c10000000_i32 = arith.constant 10000000 : i32
        nvvm.mbarrier.try_wait.parity.shared %206, %c0_i32_130, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      }
      %c4_i32 = arith.constant 4 : i32
      %191:2 = scf.for %arg6 = %c0_i32_121 to %c4_i32 step %c1_i32_122 iter_args(%arg7 = %rmem_119, %arg8 = %rmem) -> (!memref_rmem_f16_, !memref_rmem_f32_)  : i32 {
        %iter_127 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %coord_128 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %206 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
        %idx_129 = cute.crd2idx(%coord_128, %206) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %iter_130 = cute.get_iter(%view_109) : !memref_tmem_f32_2
        %ptr_131 = cute.add_offset(%iter_130, %idx_129) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        %view_132 = cute.make_view(%ptr_131) : !memref_tmem_f32_4
        %iter_133 = cute.get_iter(%view_132) : !memref_tmem_f32_4
        %207 = cute.static : !cute.layout<"(((64,32),1),1):(((1,65536),0),0)">
        %view_134 = cute.make_view(%iter_133, %207) : !memref_tmem_f32_4
        %iter_135 = cute.get_iter(%view_134) : !memref_tmem_f32_4
        %view_136 = cute.make_view(%iter_135) : !memref_tmem_f32_5
        %208 = cute.static : !cute.layout<"((64,1),1):((1,0),0)">
        %view_137 = cute.make_view(%iter_127, %208) : !memref_rmem_f32_
        %iter_138 = cute.get_iter(%view_137) : !memref_rmem_f32_
        %view_139 = cute.make_view(%iter_138) : !memref_rmem_f32_1
        %209 = cute.static : !cute.layout<"1:0">
        %iter_140 = cute.get_iter(%view_136) : !memref_tmem_f32_5
        %iter_141 = cute.get_iter(%view_139) : !memref_rmem_f32_1
        %210 = cute.static : !cute.int_tuple<"1">
        %211 = cute.get_scalars(%210) : !cute.int_tuple<"1">
        %c0_i32_142 = arith.constant 0 : i32
        %c1_i32_143 = arith.constant 1 : i32
        scf.for %arg9 = %c0_i32_142 to %211 step %c1_i32_143  : i32 {
          %220 = cute.static : !cute.layout<"(((64,32),1)):(((1,65536),0))">
          %221 = cute.static : !cute.int_tuple<"0">
          %ptr_161 = cute.add_offset(%iter_140, %221) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, tmem, align<16>>
          %view_162 = cute.make_view(%ptr_161, %220) : !memref_tmem_f32_6
          %222 = cute.static : !cute.layout<"((64,1)):((1,0))">
          %223 = cute.static : !cute.int_tuple<"0">
          %ptr_163 = cute.add_offset(%iter_141, %223) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_164 = cute.make_view(%ptr_163, %222) : !memref_rmem_f32_2
          %iter_165 = cute.get_iter(%view_162) : !memref_tmem_f32_6
          %iter_166 = cute.get_iter(%view_164) : !memref_rmem_f32_2
          %224 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%iter_165) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          %225 = builtin.unrealized_conversion_cast %iter_166 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          llvm.store %224, %225 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %212 = cute.memref.load_vec %arg8 : !memref_rmem_f32_
        %213 = arith.truncf %212 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %213, %arg7 : !memref_rmem_f16_
        %coord_144 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %214 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
        %idx_145 = cute.crd2idx(%coord_144, %214) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %iter_146 = cute.get_iter(%view_118) : !memref_gmem_f16_4
        %ptr_147 = cute.add_offset(%iter_146, %idx_145) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        %view_148 = cute.make_view(%ptr_147) : !memref_gmem_f16_5
        %iter_149 = cute.get_iter(%arg7) : !memref_rmem_f16_
        %view_150 = cute.make_view(%iter_149) : !memref_rmem_f16_1
        %iter_151 = cute.get_iter(%view_148) : !memref_gmem_f16_5
        %view_152 = cute.make_view(%iter_151) : !memref_gmem_f16_6
        %iter_153 = cute.get_iter(%view_150) : !memref_rmem_f16_1
        %view_154 = cute.make_view(%iter_153) : !memref_rmem_f16_2
        %iter_155 = cute.get_iter(%view_152) : !memref_gmem_f16_6
        %view_156 = cute.make_view(%iter_155) : !memref_gmem_f16_7
        %215 = cute.static : !cute.layout<"1:0">
        %iter_157 = cute.get_iter(%view_154) : !memref_rmem_f16_2
        %iter_158 = cute.get_iter(%view_156) : !memref_gmem_f16_7
        %216 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
        %217 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
        %218 = cute.static : !cute.int_tuple<"4">
        %219 = cute.get_scalars(%218) : !cute.int_tuple<"4">
        %c0_i32_159 = arith.constant 0 : i32
        %c1_i32_160 = arith.constant 1 : i32
        scf.for %arg9 = %c0_i32_159 to %219 step %c1_i32_160  : i32 {
          %coord_161 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %220 = cute.static : !cute.layout<"(16):(1)">
          %idx_162 = cute.crd2idx(%coord_161, %216) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_163 = cute.add_offset(%iter_157, %idx_162) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
          %view_164 = cute.make_view(%ptr_163, %220) : !memref_rmem_f16_3
          %221 = cute.static : !cute.layout<"(16):(1)">
          %idx_165 = cute.crd2idx(%coord_161, %217) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_166 = cute.add_offset(%iter_158, %idx_165) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
          %view_167 = cute.make_view(%ptr_166, %221) : !memref_gmem_f16_8
          %iter_168 = cute.get_iter(%view_164) : !memref_rmem_f16_3
          %iter_169 = cute.get_iter(%view_167) : !memref_gmem_f16_8
          %222 = builtin.unrealized_conversion_cast %iter_168 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %223 = builtin.unrealized_conversion_cast %iter_169 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
          %224 = llvm.load %222 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
          llvm.store %224, %223 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
        scf.yield %arg7, %arg8 : !memref_rmem_f16_, !memref_rmem_f32_
      }
      %int_tuple_123 = cute.make_int_tuple(%c0_i32_121) : (i32) -> !cute.int_tuple<"?">
      %ptr_124 = cute.add_offset(%ptr_10, %int_tuple_123) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %192 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %c1_i32_125 = arith.constant 1 : i32
      nvvm.mbarrier.txn %192, %c1_i32_125 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      %c1_i32_126 = arith.constant 1 : i32
      nvvm.barrier id = %c1_i32_126
      %193 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %194 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %195 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %196 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %197 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %198 = arith.muli %194, %196 : i32
      %199 = arith.addi %193, %198 : i32
      %200 = arith.muli %195, %196 : i32
      %201 = arith.muli %200, %197 : i32
      %202 = arith.addi %199, %201 : i32
      %203 = arith.floordivsi %202, %c32_i32 : i32
      %204 = cute_nvgpu.arch.make_warp_uniform(%203) : i32
      %205 = arith.cmpi eq, %204, %c0_i32 : i32
      scf.if %205 {
        %c512_i32 = arith.constant 512 : i32
        cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      }
      return
    }
  }
  func.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_) -> i32 attributes {llvm.emit_c_interface} {
    %false = arith.constant false
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %0 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %1 = cute_nvgpu.atom.set_value(%0, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %2 = cute_nvgpu.atom.set_value(%1, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %3 = cute.make_tiled_mma(%2) : !mma_f16_f16_f32_128x256x16_
    %4 = cute.static : !cute.swizzle<"S<3,4,3>">
    %5 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((128,16),1,4,(1,4)):((64,1),0,16,(0,8192))">
    %6 = cute.static : !cute.swizzle<"S<3,4,3>">
    %7 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((256,16),1,4,(1,4)):((64,1),0,16,(0,16384))">
    %8 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((128,16),1,4):((64,1),0,16)">
    %9 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((256,16),1,4):((64,1),0,16)">
    %10 = cute.static : !cute.layout<"((1,(1,1)),((128,16),(1,4))):((0,(0,0)),((1@0,1@1),(0,16@1)))">
    %c16_i32 = arith.constant 16 : i32
    %11 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %12:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %c0_i64 = arith.constant 0 : i64
    %c1_i64 = arith.constant 1 : i64
    %13 = arith.extui %12#1 : i32 to i64
    %14 = arith.extui %12#0 : i32 to i64
    %c2_i64 = arith.constant 2 : i64
    %15 = llvm.mul %12#2, %c2_i64 : i64
    %16 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<32>> to i64
    %c0_i64_0 = arith.constant 0 : i64
    %c1_i64_1 = arith.constant 1 : i64
    %c8_i64 = arith.constant 8 : i64
    %c16_i64 = arith.constant 16 : i64
    %c24_i64 = arith.constant 24 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c0_i64_2 = arith.constant 0 : i64
    %c4_i64 = arith.constant 4 : i64
    %c16_i64_3 = arith.constant 16 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %17 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %17 : i64, !llvm.ptr
    %18 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %18 : i64, !llvm.ptr
    %19 = llvm.getelementptr %11[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %19 : i64, !llvm.ptr
    %20 = llvm.getelementptr %11[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %20 : i64, !llvm.ptr
    %21 = llvm.getelementptr %11[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %11[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %11[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %11[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %11[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %11[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %11[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %11[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %11[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %11[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %11[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %11[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_2, %32 : i64, !llvm.ptr
    %33 = llvm.udiv %16, %c16_i64_3 : i64
    %34 = llvm.and %33, %c9007199254740991_i64 : i64
    %35 = llvm.shl %34, %c4_i64 : i64
    %36 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %35, %36 : i64, !llvm.ptr
    %c1_i64_4 = arith.constant 1 : i64
    %c16_i64_5 = arith.constant 16 : i64
    %c2_i64_6 = arith.constant 2 : i64
    %c16_i64_7 = arith.constant 16 : i64
    %c768_i64 = arith.constant 768 : i64
    %c0_i64_8 = arith.constant 0 : i64
    %c24576_i64 = arith.constant 24576 : i64
    %c0_i64_9 = arith.constant 0 : i64
    %c0_i64_10 = arith.constant 0 : i64
    %c262144_i64 = arith.constant 262144 : i64
    %c0_i64_11 = arith.constant 0 : i64
    %37 = llvm.sub %14, %c1_i64_4 : i64
    %38 = llvm.sub %c1_i64, %c1_i64_4 : i64
    %39 = llvm.sub %c1_i64, %c1_i64_4 : i64
    %40 = llvm.sub %c1_i64, %c1_i64_4 : i64
    %41 = llvm.mul %37, %15 : i64
    %42 = llvm.mul %38, %c0_i64 : i64
    %43 = llvm.mul %39, %c0_i64 : i64
    %44 = llvm.mul %40, %c0_i64 : i64
    %45 = llvm.add %41, %42 : i64
    %46 = llvm.add %43, %44 : i64
    %c8_i64_12 = arith.constant 8 : i64
    %c16_i64_13 = arith.constant 16 : i64
    %47 = llvm.mul %13, %c16_i64_13 : i64
    %48 = llvm.udiv %47, %c8_i64_12 : i64
    %49 = llvm.add %48, %45 : i64
    %50 = llvm.add %49, %46 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %51 = llvm.icmp "uge" %50, %c131072_i64 : i64
    %52 = llvm.zext %51 : i1 to i64
    %c21_i64 = arith.constant 21 : i64
    %53 = llvm.shl %52, %c21_i64 : i64
    %54 = llvm.udiv %15, %c16_i64_5 : i64
    %c32_i64 = arith.constant 32 : i64
    %55 = llvm.shl %54, %c32_i64 : i64
    %56 = llvm.or %c2_i64_6, %c16_i64_7 : i64
    %57 = llvm.or %c768_i64, %c0_i64_8 : i64
    %58 = llvm.or %c24576_i64, %c0_i64_9 : i64
    %59 = llvm.or %c0_i64_10, %c262144_i64 : i64
    %60 = llvm.or %c0_i64_11, %53 : i64
    %61 = llvm.or %56, %57 : i64
    %62 = llvm.or %58, %59 : i64
    %63 = llvm.or %60, %55 : i64
    %64 = llvm.or %61, %62 : i64
    %65 = llvm.or %64, %63 : i64
    %66 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %65, %66 : i64, !llvm.ptr
    %c0_i64_14 = arith.constant 0 : i64
    %c1_i64_15 = arith.constant 1 : i64
    %c16_i64_16 = arith.constant 16 : i64
    %c32_i64_17 = arith.constant 32 : i64
    %c36_i64 = arith.constant 36 : i64
    %c4294967295_i64_18 = arith.constant 4294967295 : i64
    %67 = llvm.udiv %c0_i64, %c16_i64_16 : i64
    %68 = llvm.and %67, %c4294967295_i64_18 : i64
    %69 = llvm.shl %68, %c0_i64_14 : i64
    %70 = llvm.udiv %c0_i64, %c16_i64_16 : i64
    %71 = llvm.shl %70, %c32_i64_17 : i64
    %72 = llvm.or %69, %71 : i64
    %73 = llvm.getelementptr %11[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %72, %73 : i64, !llvm.ptr
    %74 = llvm.udiv %c0_i64, %c16_i64_16 : i64
    %75 = llvm.and %74, %c4294967295_i64_18 : i64
    %76 = llvm.shl %75, %c0_i64_14 : i64
    %c15_i64 = arith.constant 15 : i64
    %77 = llvm.lshr %15, %c36_i64 : i64
    %78 = llvm.and %77, %c15_i64 : i64
    %79 = llvm.shl %78, %c32_i64_17 : i64
    %80 = llvm.lshr %c0_i64, %c36_i64 : i64
    %81 = llvm.and %80, %c15_i64 : i64
    %c36_i64_19 = arith.constant 36 : i64
    %82 = llvm.shl %81, %c36_i64_19 : i64
    %83 = llvm.lshr %c0_i64, %c36_i64 : i64
    %84 = llvm.and %83, %c15_i64 : i64
    %c40_i64 = arith.constant 40 : i64
    %85 = llvm.shl %84, %c40_i64 : i64
    %86 = llvm.lshr %c0_i64, %c36_i64 : i64
    %c44_i64 = arith.constant 44 : i64
    %87 = llvm.shl %86, %c44_i64 : i64
    %88 = llvm.or %79, %82 : i64
    %89 = llvm.or %85, %87 : i64
    %90 = llvm.or %88, %89 : i64
    %91 = llvm.or %76, %90 : i64
    %92 = llvm.getelementptr %11[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %91, %92 : i64, !llvm.ptr
    %93 = llvm.sub %13, %c1_i64_15 : i64
    %94 = llvm.and %93, %c4294967295_i64_18 : i64
    %95 = llvm.shl %94, %c0_i64_14 : i64
    %96 = llvm.sub %14, %c1_i64_15 : i64
    %97 = llvm.shl %96, %c32_i64_17 : i64
    %98 = llvm.or %95, %97 : i64
    %99 = llvm.getelementptr %11[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %98, %99 : i64, !llvm.ptr
    %100 = llvm.sub %c1_i64, %c1_i64_15 : i64
    %101 = llvm.and %100, %c4294967295_i64_18 : i64
    %102 = llvm.shl %101, %c0_i64_14 : i64
    %103 = llvm.sub %c1_i64, %c1_i64_15 : i64
    %104 = llvm.shl %103, %c32_i64_17 : i64
    %105 = llvm.or %102, %104 : i64
    %106 = llvm.getelementptr %11[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %105, %106 : i64, !llvm.ptr
    %107 = llvm.sub %c1_i64, %c1_i64_1 : i64
    %108 = llvm.and %107, %c4294967295_i64 : i64
    %c0_i64_20 = arith.constant 0 : i64
    %c63_i64 = arith.constant 63 : i64
    %c56_i64 = arith.constant 56 : i64
    %109 = llvm.shl %c63_i64, %c56_i64 : i64
    %110 = llvm.or %108, %c0_i64_20 : i64
    %111 = llvm.or %110, %109 : i64
    %112 = llvm.getelementptr %11[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %111, %112 : i64, !llvm.ptr
    %c127_i64 = arith.constant 127 : i64
    %113 = llvm.shl %c127_i64, %c0_i64_0 : i64
    %c0_i64_21 = arith.constant 0 : i64
    %114 = llvm.shl %c0_i64_21, %c8_i64 : i64
    %c0_i64_22 = arith.constant 0 : i64
    %115 = llvm.shl %c0_i64_22, %c16_i64 : i64
    %c0_i64_23 = arith.constant 0 : i64
    %116 = llvm.shl %c0_i64_23, %c24_i64 : i64
    %117 = llvm.or %113, %114 : i64
    %118 = llvm.or %115, %116 : i64
    %119 = llvm.or %117, %118 : i64
    %120 = llvm.getelementptr %11[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %119, %120 : i64, !llvm.ptr
    %121 = builtin.unrealized_conversion_cast %11 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %122 = cute.ptrtoint(%121) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %123 = llvm.inttoptr %122 : i64 to !llvm.ptr
    %124 = llvm.load %123 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %125 = builtin.unrealized_conversion_cast %124 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_24 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %126 = cute_nvgpu.atom.set_value(%atom_24, %125 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %lay_25 = cute.get_layout(%arg0) : !memref_gmem_f16_
    %127 = cute.get_shape(%lay_25) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %128 = cute.static : !cute.stride<"(1@1,1@0)">
    %lay_26 = cute.make_layout(%127, %128) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %129 = cute.static : !cute.int_tuple<"(0,0)">
    %view = cute.make_view(%129, %lay_26) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %130 = cute.static : !cute.layout<"((1,(1,1)),((256,16),(1,4))):((0,(0,0)),((1@0,1@1),(0,16@1)))">
    %c16_i32_27 = arith.constant 16 : i32
    %131 = llvm.alloca %c16_i32_27 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_28 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_29 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %132:3 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %c0_i64_30 = arith.constant 0 : i64
    %c1_i64_31 = arith.constant 1 : i64
    %133 = arith.extui %132#1 : i32 to i64
    %134 = arith.extui %132#0 : i32 to i64
    %c2_i64_32 = arith.constant 2 : i64
    %135 = llvm.mul %132#2, %c2_i64_32 : i64
    %136 = cute.ptrtoint(%iter_28) : !cute.ptr<f16, gmem, align<32>> to i64
    %c0_i64_33 = arith.constant 0 : i64
    %c1_i64_34 = arith.constant 1 : i64
    %c8_i64_35 = arith.constant 8 : i64
    %c16_i64_36 = arith.constant 16 : i64
    %c24_i64_37 = arith.constant 24 : i64
    %c4294967295_i64_38 = arith.constant 4294967295 : i64
    %c0_i64_39 = arith.constant 0 : i64
    %c4_i64_40 = arith.constant 4 : i64
    %c16_i64_41 = arith.constant 16 : i64
    %c9007199254740991_i64_42 = arith.constant 9007199254740991 : i64
    %137 = llvm.getelementptr %131[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %137 : i64, !llvm.ptr
    %138 = llvm.getelementptr %131[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %138 : i64, !llvm.ptr
    %139 = llvm.getelementptr %131[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %139 : i64, !llvm.ptr
    %140 = llvm.getelementptr %131[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %140 : i64, !llvm.ptr
    %141 = llvm.getelementptr %131[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %141 : i64, !llvm.ptr
    %142 = llvm.getelementptr %131[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %142 : i64, !llvm.ptr
    %143 = llvm.getelementptr %131[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %143 : i64, !llvm.ptr
    %144 = llvm.getelementptr %131[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %144 : i64, !llvm.ptr
    %145 = llvm.getelementptr %131[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %145 : i64, !llvm.ptr
    %146 = llvm.getelementptr %131[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %146 : i64, !llvm.ptr
    %147 = llvm.getelementptr %131[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %147 : i64, !llvm.ptr
    %148 = llvm.getelementptr %131[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %148 : i64, !llvm.ptr
    %149 = llvm.getelementptr %131[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %149 : i64, !llvm.ptr
    %150 = llvm.getelementptr %131[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %150 : i64, !llvm.ptr
    %151 = llvm.getelementptr %131[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %151 : i64, !llvm.ptr
    %152 = llvm.getelementptr %131[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64_39, %152 : i64, !llvm.ptr
    %153 = llvm.udiv %136, %c16_i64_41 : i64
    %154 = llvm.and %153, %c9007199254740991_i64_42 : i64
    %155 = llvm.shl %154, %c4_i64_40 : i64
    %156 = llvm.getelementptr %131[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %155, %156 : i64, !llvm.ptr
    %c1_i64_43 = arith.constant 1 : i64
    %c16_i64_44 = arith.constant 16 : i64
    %c2_i64_45 = arith.constant 2 : i64
    %c16_i64_46 = arith.constant 16 : i64
    %c768_i64_47 = arith.constant 768 : i64
    %c0_i64_48 = arith.constant 0 : i64
    %c24576_i64_49 = arith.constant 24576 : i64
    %c0_i64_50 = arith.constant 0 : i64
    %c0_i64_51 = arith.constant 0 : i64
    %c262144_i64_52 = arith.constant 262144 : i64
    %c0_i64_53 = arith.constant 0 : i64
    %157 = llvm.sub %134, %c1_i64_43 : i64
    %158 = llvm.sub %c1_i64_31, %c1_i64_43 : i64
    %159 = llvm.sub %c1_i64_31, %c1_i64_43 : i64
    %160 = llvm.sub %c1_i64_31, %c1_i64_43 : i64
    %161 = llvm.mul %157, %135 : i64
    %162 = llvm.mul %158, %c0_i64_30 : i64
    %163 = llvm.mul %159, %c0_i64_30 : i64
    %164 = llvm.mul %160, %c0_i64_30 : i64
    %165 = llvm.add %161, %162 : i64
    %166 = llvm.add %163, %164 : i64
    %c8_i64_54 = arith.constant 8 : i64
    %c16_i64_55 = arith.constant 16 : i64
    %167 = llvm.mul %133, %c16_i64_55 : i64
    %168 = llvm.udiv %167, %c8_i64_54 : i64
    %169 = llvm.add %168, %165 : i64
    %170 = llvm.add %169, %166 : i64
    %c131072_i64_56 = arith.constant 131072 : i64
    %171 = llvm.icmp "uge" %170, %c131072_i64_56 : i64
    %172 = llvm.zext %171 : i1 to i64
    %c21_i64_57 = arith.constant 21 : i64
    %173 = llvm.shl %172, %c21_i64_57 : i64
    %174 = llvm.udiv %135, %c16_i64_44 : i64
    %c32_i64_58 = arith.constant 32 : i64
    %175 = llvm.shl %174, %c32_i64_58 : i64
    %176 = llvm.or %c2_i64_45, %c16_i64_46 : i64
    %177 = llvm.or %c768_i64_47, %c0_i64_48 : i64
    %178 = llvm.or %c24576_i64_49, %c0_i64_50 : i64
    %179 = llvm.or %c0_i64_51, %c262144_i64_52 : i64
    %180 = llvm.or %c0_i64_53, %173 : i64
    %181 = llvm.or %176, %177 : i64
    %182 = llvm.or %178, %179 : i64
    %183 = llvm.or %180, %175 : i64
    %184 = llvm.or %181, %182 : i64
    %185 = llvm.or %184, %183 : i64
    %186 = llvm.getelementptr %131[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %185, %186 : i64, !llvm.ptr
    %c0_i64_59 = arith.constant 0 : i64
    %c1_i64_60 = arith.constant 1 : i64
    %c16_i64_61 = arith.constant 16 : i64
    %c32_i64_62 = arith.constant 32 : i64
    %c36_i64_63 = arith.constant 36 : i64
    %c4294967295_i64_64 = arith.constant 4294967295 : i64
    %187 = llvm.udiv %c0_i64_30, %c16_i64_61 : i64
    %188 = llvm.and %187, %c4294967295_i64_64 : i64
    %189 = llvm.shl %188, %c0_i64_59 : i64
    %190 = llvm.udiv %c0_i64_30, %c16_i64_61 : i64
    %191 = llvm.shl %190, %c32_i64_62 : i64
    %192 = llvm.or %189, %191 : i64
    %193 = llvm.getelementptr %131[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %192, %193 : i64, !llvm.ptr
    %194 = llvm.udiv %c0_i64_30, %c16_i64_61 : i64
    %195 = llvm.and %194, %c4294967295_i64_64 : i64
    %196 = llvm.shl %195, %c0_i64_59 : i64
    %c15_i64_65 = arith.constant 15 : i64
    %197 = llvm.lshr %135, %c36_i64_63 : i64
    %198 = llvm.and %197, %c15_i64_65 : i64
    %199 = llvm.shl %198, %c32_i64_62 : i64
    %200 = llvm.lshr %c0_i64_30, %c36_i64_63 : i64
    %201 = llvm.and %200, %c15_i64_65 : i64
    %c36_i64_66 = arith.constant 36 : i64
    %202 = llvm.shl %201, %c36_i64_66 : i64
    %203 = llvm.lshr %c0_i64_30, %c36_i64_63 : i64
    %204 = llvm.and %203, %c15_i64_65 : i64
    %c40_i64_67 = arith.constant 40 : i64
    %205 = llvm.shl %204, %c40_i64_67 : i64
    %206 = llvm.lshr %c0_i64_30, %c36_i64_63 : i64
    %c44_i64_68 = arith.constant 44 : i64
    %207 = llvm.shl %206, %c44_i64_68 : i64
    %208 = llvm.or %199, %202 : i64
    %209 = llvm.or %205, %207 : i64
    %210 = llvm.or %208, %209 : i64
    %211 = llvm.or %196, %210 : i64
    %212 = llvm.getelementptr %131[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %211, %212 : i64, !llvm.ptr
    %213 = llvm.sub %133, %c1_i64_60 : i64
    %214 = llvm.and %213, %c4294967295_i64_64 : i64
    %215 = llvm.shl %214, %c0_i64_59 : i64
    %216 = llvm.sub %134, %c1_i64_60 : i64
    %217 = llvm.shl %216, %c32_i64_62 : i64
    %218 = llvm.or %215, %217 : i64
    %219 = llvm.getelementptr %131[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %218, %219 : i64, !llvm.ptr
    %220 = llvm.sub %c1_i64_31, %c1_i64_60 : i64
    %221 = llvm.and %220, %c4294967295_i64_64 : i64
    %222 = llvm.shl %221, %c0_i64_59 : i64
    %223 = llvm.sub %c1_i64_31, %c1_i64_60 : i64
    %224 = llvm.shl %223, %c32_i64_62 : i64
    %225 = llvm.or %222, %224 : i64
    %226 = llvm.getelementptr %131[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %225, %226 : i64, !llvm.ptr
    %227 = llvm.sub %c1_i64_31, %c1_i64_34 : i64
    %228 = llvm.and %227, %c4294967295_i64_38 : i64
    %c0_i64_69 = arith.constant 0 : i64
    %c63_i64_70 = arith.constant 63 : i64
    %c56_i64_71 = arith.constant 56 : i64
    %229 = llvm.shl %c63_i64_70, %c56_i64_71 : i64
    %230 = llvm.or %228, %c0_i64_69 : i64
    %231 = llvm.or %230, %229 : i64
    %232 = llvm.getelementptr %131[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %231, %232 : i64, !llvm.ptr
    %c255_i64 = arith.constant 255 : i64
    %233 = llvm.shl %c255_i64, %c0_i64_33 : i64
    %c0_i64_72 = arith.constant 0 : i64
    %234 = llvm.shl %c0_i64_72, %c8_i64_35 : i64
    %c0_i64_73 = arith.constant 0 : i64
    %235 = llvm.shl %c0_i64_73, %c16_i64_36 : i64
    %c0_i64_74 = arith.constant 0 : i64
    %236 = llvm.shl %c0_i64_74, %c24_i64_37 : i64
    %237 = llvm.or %233, %234 : i64
    %238 = llvm.or %235, %236 : i64
    %239 = llvm.or %237, %238 : i64
    %240 = llvm.getelementptr %131[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %239, %240 : i64, !llvm.ptr
    %241 = builtin.unrealized_conversion_cast %131 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %242 = cute.ptrtoint(%241) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %243 = llvm.inttoptr %242 : i64 to !llvm.ptr
    %244 = llvm.load %243 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %245 = builtin.unrealized_conversion_cast %244 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_75 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %246 = cute_nvgpu.atom.set_value(%atom_75, %245 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %lay_76 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %247 = cute.get_shape(%lay_76) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %248 = cute.static : !cute.stride<"(1@1,1@0)">
    %lay_77 = cute.make_layout(%247, %248) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %249 = cute.static : !cute.int_tuple<"(0,0)">
    %view_78 = cute.make_view(%249, %lay_77) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %lay_79 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %250 = cute.get_shape(%lay_79) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %e0, %e1 = cute.get_leaves(%250) : !cute.shape<"(?,?{div=8192})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_80 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=8192}"> to !cute.int_tuple<"?{div=8192}">
    %int_tuple = cute.make_int_tuple(%itup, %itup_80) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %251:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=8192},1)">
    %c128_i32 = arith.constant 128 : i32
    %252 = arith.ceildivsi %251#0, %c128_i32 : i32
    %c256_i32 = arith.constant 256 : i32
    %253 = arith.ceildivsi %251#1, %c256_i32 : i32
    %int_tuple_81 = cute.make_int_tuple(%252, %253) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %254 = cute.static : !cute.int_tuple<"1">
    %e0_82, %e1_83, %e2 = cute.get_leaves(%int_tuple_81) : !cute.int_tuple<"(?,?,1)">
    %255 = cute.get_scalars(%e0_82) : !cute.int_tuple<"?">
    %256 = cute.get_scalars(%e1_83) : !cute.int_tuple<"?">
    %257 = cute.static : !cute.layout<"(1,1,1,1):(0,0,0,0)">
    %258 = cute.static : !cute.tile<"[_;_;_]">
    %259 = cute.static : !cute.layout<"1:0">
    %260 = cute.static : !cute.shape<"(128,256,16)">
    %261 = cute.static : !cute.layout<"(1,(128,16)):(128,(1,128))">
    %262 = cute.static : !cute.layout<"(1,(256,16)):(256,(1,256))">
    %263 = cute.static : !cute.layout<"(1,(128,256)):(128,(1,128))">
    %264 = cute.static : !cute.layout<"1:0">
    %265 = cute.static : !cute.layout<"(1,8192):(0,1)">
    %266 = cute.static : !cute.layout<"(1,8192):(0,1)">
    %267 = cute.static : !cute.layout<"1:0">
    %268 = cute.static : !cute.layout<"(1,16384):(0,1)">
    %269 = cute.static : !cute.layout<"(1,16384):(0,1)">
    %c196736_i32 = arith.constant 196736 : i32
    %c0_i64_84 = arith.constant 0 : i64
    %270 = cuda.cast %c0_i64_84 : i64 -> !cuda.stream
    %271 = arith.extsi %c196736_i32 : i32 to i64
    %c128_i32_85 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %272 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_85, %c1_i32, %c1_i32), dynamicSmemBytes = %271, gridDim = (%255, %256, %c1_i32), stream = %270) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %273 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0<%272> (%3, %126, %view, %246, %view_78, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_128x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %274 = cuda.cast %273 : !cuda.result -> i32
    cuda.return_if_error %274 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
