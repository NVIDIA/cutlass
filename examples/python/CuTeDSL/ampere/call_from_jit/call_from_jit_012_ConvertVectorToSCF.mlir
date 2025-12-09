!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<f16, cache = global, 128 b>, layout_copy_tv = <"((4,32),8):((256,1),32)">, tiler_mn = <"[32:1;32:1]">>
!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,2,2),((2,2,2),(1,1))):((64,1,16,0),((32,8,256),(0,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>, layout_copy_tv = <"((4,8,2,2),((2,2),(2,1))):((64,1,0,8),((32,256),(16,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f16, 128 b>, layout_copy_tv = <"((16,8),8):((64,1),8)">, tiler_mn = <"[8:1;128:1]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(512,128,16):(128,1,65536)">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<32>, "(256,128,16):(128,1,32768)">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, align<32>, "(512,256,16):(256,1,131072)">
!memref_gmem_f16_3 = !cute.memref<f16, gmem, align<32>, "(128,32,4):(128,1,32)">
!memref_gmem_f16_4 = !cute.memref<f16, gmem, "(128,32,4):(128,1,32)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<16>, "((2,2,2),4,2):((1,2,4),8,32)">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<8>, "((2,2),8,2):((1,2),4,32)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "((2,2),4,8):((1,2),4,16)">
!memref_rmem_f16_3 = !cute.memref<f16, rmem, align<32>, "((8,1),16,1):((1,0),8,0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<16>, "((2,2),4,8):((1,2),4,16)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(1,4,1):(4,1,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(1,16,1):(16,1,0)">
!memref_smem_f16_ = !cute.memref<f16, smem, align<16>, "((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">
!memref_smem_f16_1 = !cute.memref<f16, smem, align<16>, "((8,1),4,2):((1,0),1024,?{div=16})">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_tensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o512256162561131072_S_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_1, %arg2: !memref_gmem_f16_2, %arg3: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %cst = arith.constant dense<0.000000e+00> : vector<128xf32>
      %cst_0 = arith.constant dense<0.000000e+00> : vector<96xf16>
      %c15_i64 = arith.constant 15 : i64
      %0 = llvm.mlir.constant(0 : i8) : i8
      %1 = cute.static : !cute.layout<"(1,((16))):(16,((1)))">
      %2 = cute.static : !cute.layout<"((8,1),((16))):((1,0),((2048)))">
      %3 = cute.static : !cute.layout<"((8,1),((16))):((1,0),((8)))">
      %4 = cute.static : !cute.layout<"((8,1),16,1):((1@1,0),8@0,0)">
      %5 = cute.static : !cute.int_tuple<"16">
      %6 = cute.static : !cute.layout<"(8,(16)):(1,(8))">
      %7 = cute.static : !cute.layout<"(8,(16)):(1,(1024))">
      %8 = cute.static : !cute.layout<"((128,128),(4,2)):((1@0,1@1),(128@0,128@1))">
      %9 = cute.static : !cute.layout<"(512,256,1):(1@0,1@1,1@2)">
      %10 = cute.static : !cute.int_tuple<"64">
      %11 = cute.static : !cute.shape<"(2,((2,4,2,2,2)))">
      %12 = cute.static : !cute.layout<"(2,(64)):(1,(2))">
      %13 = cute.static : !cute.shape<"(2,(2,4,2,2,2))">
      %14 = cute.static : !cute.int_tuple<"8">
      %15 = cute.static : !cute.int_tuple<"1">
      %16 = cute.static : !cute.layout<"((2,2),8,1):((1,2),4,0)">
      %17 = cute.static : !cute.layout<"((2,2,2),4,1):((1,2,4),8,0)">
      %18 = cute.static : !cute.layout<"((2,2),4,8):((1,2),4,16)">
      %19 = cute.static : !cute.layout<"((2,2),8,2):((1,2),4,32)">
      %20 = cute.static : !cute.layout<"((2,2,2),4,2):((1,2,4),8,32)">
      %21 = cute.static : !cute.layout<"((8,1),4,2):((1,0),8,32)">
      %22 = cute.static : !cute.int_tuple<"6">
      %23 = llvm.mlir.constant(3 : i32) : i32
      %24 = llvm.mlir.constant(2 : i32) : i32
      %25 = cute.static : !cute.int_tuple<"2">
      %26 = llvm.mlir.constant(1 : i32) : i32
      %27 = llvm.mlir.constant(0 : i32) : i32
      %28 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((8)))">
      %29 = cute.static : !cute.shape<"((8,1),4,2)">
      %30 = cute.static : !cute.shape<"((8,1),4,2,(1,3))">
      %31 = cute.static : !cute.shape<"((2,2),4,(2,2,2))">
      %c-32_i32 = arith.constant -32 : i32
      %c512_i32 = arith.constant 512 : i32
      %c-16_i32 = arith.constant -16 : i32
      %c2048_i32 = arith.constant 2048 : i32
      %32 = cute.static : !cute.layout<"(1,((4,1))):(4,((1,0)))">
      %33 = cute.static : !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">
      %34 = cute.static : !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">
      %35 = cute.static : !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">
      %36 = cute.static : !cute.int_tuple<"4">
      %37 = cute.static : !cute.layout<"(1,((4))):(4,((1)))">
      %38 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((1024)))">
      %39 = cute.static : !cute.layout<"((8,1),((4))):((1,0),((4096)))">
      %40 = cute.static : !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">
      %41 = cute.static : !cute.coord<"256">
      %42 = cute.static : !cute.coord<"512">
      %43 = cute.static : !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %c1_i32 = arith.constant 1 : i32
      %c896_i32 = arith.constant 896 : i32
      %c16_i32 = arith.constant 16 : i32
      %c3_i32 = arith.constant 3 : i32
      %c192_i32 = arith.constant 192 : i32
      %c256_i32 = arith.constant 256 : i32
      %c32_i32 = arith.constant 32 : i32
      %c64_i32 = arith.constant 64 : i32
      %c128_i32 = arith.constant 128 : i32
      %c8_i32 = arith.constant 8 : i32
      %44 = cute.static : !cute.int_tuple<"24576">
      %45 = cute.static : !cute.layout<"((128,32),(2,4)):((1@0,1@1),(128@0,32@1))">
      %46 = cute.static : !cute.layout<"(256,128,16):(1@0,1@1,1@2)">
      %47 = cute.static : !cute.layout<"((128,32),(4,4)):((1@0,1@1),(128@0,32@1))">
      %48 = cute.static : !cute.int_tuple<"(0,0,0)">
      %49 = cute.static : !cute.layout<"(512,128,16):(1@0,1@1,1@2)">
      %c-16_i64 = arith.constant -16 : i64
      %50 = cute.static : !cute.layout<"(128,32,4):(128,1,32)">
      %51 = cute.static : !cute.layout<"((128,128),(4,2)):((256,1),(32768,128))">
      %52 = cute.static : !cute.layout<"(512,256,16):(256,1,131072)">
      %53 = cute.static : !cute.layout<"((128,32),(2,4)):((128,1),(16384,32))">
      %54 = cute.static : !cute.layout<"(256,128,16):(128,1,32768)">
      %55 = cute.static : !cute.layout<"((128,32),(4,4)):((128,1),(16384,32))">
      %56 = cute.static : !cute.layout<"(512,128,16):(128,1,65536)">
      %c0_i32 = arith.constant 0 : i32
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %57 = cute.static : !cute.layout<"1:0">
      %58 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %59 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %60 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %61 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %62 = arith.floordivsi %59, %arg3 : i32
      %63 = arith.remsi %59, %arg3 : i32
      %64 = arith.muli %60, %arg3 : i32
      %65 = arith.addi %63, %64 : i32
      %66 = arith.cmpi sge, %62, %c4_i32 : i32
      %67 = arith.cmpi sge, %65, %c2_i32 : i32
      %68 = arith.extui %66 : i1 to i32
      %69 = arith.extui %67 : i1 to i32
      %70 = arith.select %66, %68, %69 : i32
      %71 = arith.cmpi ne, %70, %c0_i32 : i32
      scf.if %71 {
      } else {
        %coord = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx = cute.crd2idx(%coord, %56) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,128,16):(128,1,65536)">) -> !cute.int_tuple<"?{div=65536}">
        %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
        %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=65536}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_1 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %72:2 = cute.get_scalars(%coord_1) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_2 = cute.make_coord(%72#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
        %idx_3 = cute.crd2idx(%coord_2, %55) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(4,4)):((128,1),(16384,32))">) -> !cute.int_tuple<"?{div=16384}">
        %ptr_4 = cute.add_offset(%ptr, %idx_3) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, gmem, align<32>>
        %idx_5 = cute.crd2idx(%coord, %54) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(128,1,32768)">) -> !cute.int_tuple<"?{div=32768}">
        %iter_6 = cute.get_iter(%arg1) : !memref_gmem_f16_1
        %ptr_7 = cute.add_offset(%iter_6, %idx_5) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=32768}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_8 = cute.make_coord(%72#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
        %idx_9 = cute.crd2idx(%coord_8, %53) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((128,1),(16384,32))">) -> !cute.int_tuple<"?{div=16384}">
        %ptr_10 = cute.add_offset(%ptr_7, %idx_9) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, gmem, align<32>>
        %idx_11 = cute.crd2idx(%coord, %52) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,16):(256,1,131072)">) -> !cute.int_tuple<"?{div=131072}">
        %iter_12 = cute.get_iter(%arg2) : !memref_gmem_f16_2
        %ptr_13 = cute.add_offset(%iter_12, %idx_11) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=131072}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_14 = cute.make_coord(%72#0, %72#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
        %idx_15 = cute.crd2idx(%coord_14, %51) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((256,1),(32768,128))">) -> !cute.int_tuple<"?{div=128}">
        %ptr_16 = cute.add_offset(%ptr_13, %idx_15) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f16, gmem, align<32>>
        %view = cute.make_view(%ptr_4, %50) : !memref_gmem_f16_3
        %dyn = cute.derefine(%view) : !memref_gmem_f16_3 to !memref_gmem_f16_4
        %iter_17 = cute.get_iter(%dyn) : !memref_gmem_f16_4
        %view_18 = cute.make_view(%ptr_10, %50) : !memref_gmem_f16_3
        %dyn_19 = cute.derefine(%view_18) : !memref_gmem_f16_3 to !memref_gmem_f16_4
        %iter_20 = cute.get_iter(%dyn_19) : !memref_gmem_f16_4
        %73 = cute.ptrtoint(%iter_17) : !cute.ptr<f16, gmem> to i64
        %74 = arith.addi %73, %c15_i64 : i64
        %75 = arith.andi %74, %c-16_i64 : i64
        %iv = cute.assume(%75) : (i64) -> !cute.i64<divby 16>
        %76 = cute.inttoptr(%iv) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
        %77 = cute.ptrtoint(%iter_20) : !cute.ptr<f16, gmem> to i64
        %78 = arith.addi %77, %c15_i64 : i64
        %79 = arith.andi %78, %c-16_i64 : i64
        %iv_21 = cute.assume(%79) : (i64) -> !cute.i64<divby 16>
        %80 = cute.inttoptr(%iv_21) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
        %idx_22 = cute.crd2idx(%coord, %49) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup = cute.add_offset(%48, %idx_22) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %idx_23 = cute.crd2idx(%coord_2, %47) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(4,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
        %tup_24 = cute.add_offset(%tup, %idx_23) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0, %e1, %e2 = cute.get_leaves(%tup_24) : !cute.int_tuple<"(?{div=128},0,?)">
        %idx_25 = cute.crd2idx(%coord, %46) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup_26 = cute.add_offset(%48, %idx_25) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %idx_27 = cute.crd2idx(%coord_8, %45) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
        %tup_28 = cute.add_offset(%tup_26, %idx_27) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_29, %e1_30, %e2_31 = cute.get_leaves(%tup_28) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple = cute.make_int_tuple(%e0, %e2) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_32, %e1_33, %e2_34 = cute.get_leaves(%int_tuple) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_35 = cute.make_int_tuple(%e0_32, %e2_34) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_36 = cute.make_int_tuple(%e0_29, %e2_31) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_37, %e1_38, %e2_39 = cute.get_leaves(%int_tuple_36) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_40 = cute.make_int_tuple(%e0_37, %e2_39) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
        %ptr_41 = cute.add_offset(%smem_ptr, %44) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"24576">) -> !cute.ptr<i8, smem, align<1024>>
        %iter_42 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %iter_43 = cute.recast_iter(%ptr_41) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %iter_44 = cute.recast_iter(%iter_42) : !cute.ptr<f16, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %coord_45 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %81 = cute.get_scalars(%coord_45) <{only_dynamic}> : !cute.coord<"?">
        %82 = arith.divsi %81, %c4_i32 : i32
        %83 = arith.remsi %81, %c4_i32 : i32
        %84 = arith.muli %83, %c8_i32 : i32
        %85 = arith.muli %82, %c128_i32 : i32
        %86 = arith.addi %84, %85 : i32
        %iv_46 = cute.assume(%86) : (i32) -> !cute.i32<divby 8>
        %int_tuple_47 = cute.make_int_tuple(%iv_46) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_48 = cute.add_offset(%76, %int_tuple_47) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %87 = arith.divsi %82, %c2_i32 : i32
        %88 = arith.remsi %87, %c4_i32 : i32
        %89 = arith.muli %88, %c64_i32 : i32
        %90 = arith.addi %84, %89 : i32
        %91 = arith.remsi %82, %c2_i32 : i32
        %92 = arith.muli %91, %c32_i32 : i32
        %93 = arith.divsi %87, %c4_i32 : i32
        %94 = arith.muli %93, %c256_i32 : i32
        %95 = arith.addi %92, %94 : i32
        %96 = arith.andi %90, %c192_i32 : i32
        %97 = arith.shrsi %96, %c3_i32 : i32
        %98 = arith.xori %90, %97 : i32
        %99 = arith.addi %98, %95 : i32
        %iv_49 = cute.assume(%99) : (i32) -> !cute.i32<divby 8>
        %int_tuple_50 = cute.make_int_tuple(%iv_49) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_51 = cute.add_offset(%iter_42, %int_tuple_50) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %view_52 = cute.make_view(%ptr_51) : !memref_smem_f16_
        %ptr_53 = cute.add_offset(%80, %int_tuple_47) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %ptr_54 = cute.add_offset(%iter_43, %int_tuple_50) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %view_55 = cute.make_view(%ptr_54) : !memref_smem_f16_
        %100 = arith.divsi %81, %c16_i32 : i32
        %101 = arith.remsi %81, %c16_i32 : i32
        %102 = arith.remsi %101, %c8_i32 : i32
        %103 = arith.muli %102, %c8_i32 : i32
        %104 = arith.muli %100, %c128_i32 : i32
        %105 = arith.addi %103, %104 : i32
        %106 = arith.divsi %101, %c8_i32 : i32
        %107 = arith.muli %106, %c64_i32 : i32
        %108 = arith.andi %105, %c896_i32 : i32
        %109 = arith.shrsi %108, %c4_i32 : i32
        %110 = arith.xori %105, %109 : i32
        %111 = arith.addi %110, %107 : i32
        %iv_56 = cute.assume(%111) : (i32) -> !cute.i32<divby 8>
        %int_tuple_57 = cute.make_int_tuple(%iv_56) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_58 = cute.add_offset(%iter_44, %int_tuple_57) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %112 = arith.muli %101, %c8_i32 : i32
        %113 = arith.muli %100, %c256_i32 : i32
        %114 = arith.addi %112, %113 : i32
        %iv_59 = cute.assume(%114) : (i32) -> !cute.i32<divby 8>
        %int_tuple_60 = cute.make_int_tuple(%iv_59) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_61 = cute.add_offset(%ptr_16, %int_tuple_60) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %iv_62 = cute.assume(%84) : (i32) -> !cute.i32<divby 8>
        %int_tuple_63 = cute.make_int_tuple(%82, %iv_62) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
        %tup_64 = cute.add_offset(%int_tuple_35, %int_tuple_63) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %view_65 = cute.make_view(%tup_64) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %dyn_66 = cute.derefine(%view_65) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %tup_67 = cute.add_offset(%int_tuple_40, %int_tuple_63) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %view_68 = cute.make_view(%tup_67) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %dyn_69 = cute.derefine(%view_68) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %rmem = cute.memref.alloca() : !memref_rmem_i8_
        %rmem_70 = cute.memref.alloca() : !memref_rmem_i8_
        %iter_71 = cute.get_iter(%dyn_66) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %115 = cute.get_scalars(%42) : !cute.coord<"512">
        scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0,0)">
          %idx_155 = cute.crd2idx(%coord_154, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
          %tup_156 = cute.add_offset(%iter_71, %idx_155) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
          %e0_157, %e1_158, %e2_159 = cute.get_leaves(%tup_156) : !cute.int_tuple<"(?,?,?)">
          %coord_160 = cute.make_coord(%e0_157) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %213 = cute.get_scalars(%coord_160) : !cute.coord<"?">
          %214 = arith.cmpi slt, %213, %115 : i32
          %215 = arith.extui %214 : i1 to i8
          %coord_161 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_162 = cute.derefine(%coord_161) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem, %dyn_162, %215) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        %iter_72 = cute.get_iter(%dyn_69) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %116 = cute.get_scalars(%41) : !cute.coord<"256">
        scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0,0)">
          %idx_155 = cute.crd2idx(%coord_154, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
          %tup_156 = cute.add_offset(%iter_72, %idx_155) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
          %e0_157, %e1_158, %e2_159 = cute.get_leaves(%tup_156) : !cute.int_tuple<"(?,?,?)">
          %coord_160 = cute.make_coord(%e0_157) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %213 = cute.get_scalars(%coord_160) : !cute.coord<"?">
          %214 = arith.cmpi slt, %213, %116 : i32
          %215 = arith.extui %214 : i1 to i8
          %coord_161 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_162 = cute.derefine(%coord_161) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem_70, %dyn_162, %215) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        cute.memref.store_vec %cst_0, %view_52 : !memref_smem_f16_
        cute.memref.store_vec %cst_0, %view_55 : !memref_smem_f16_
        nvvm.barrier
        %iter_73 = cute.get_iter(%dyn_66) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %e0_74, %e1_75, %e2_76 = cute.get_leaves(%iter_73) : !cute.int_tuple<"(?,?,?)">
        %coord_77 = cute.make_coord() : () -> !cute.coord<"-1">
        %dyn_78 = cute.derefine(%coord_77) : !cute.coord<"-1"> to !cute.coord<"?">
        %coord_79 = cute.make_coord(%e1_75) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %117 = cute.get_scalars(%dyn_78) : !cute.coord<"?">
        %118 = cute.get_scalars(%coord_79) : !cute.coord<"?">
        %119 = arith.cmpi slt, %117, %118 : i32
        scf.if %119 {
          %iter_154 = cute.get_iter(%rmem) : !memref_rmem_i8_
          %213 = cute.get_scalars(%36) : !cute.int_tuple<"4">
          scf.for %arg4 = %c0_i32 to %213 step %c1_i32  : i32 {
            %coord_155 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_156 = cute.crd2idx(%coord_155, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_157 = cute.add_offset(%ptr_48, %idx_156) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_158 = cute.crd2idx(%coord_155, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_159 = cute.add_offset(%ptr_51, %idx_158) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
            %idx_160 = cute.crd2idx(%coord_155, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
            %ptr_161 = cute.add_offset(%iter_154, %idx_160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %214 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
            %215 = llvm.load %214 : !llvm.ptr -> i8
            %216 = llvm.trunc %215 : i8 to i1
            %iter_162 = cute.recast_iter(%ptr_157) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_163 = cute.recast_iter(%ptr_159) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_163 : !cute.ptr<i128, smem>, %iter_162 : !cute.ptr<i128, gmem>, %216 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        %iter_80 = cute.get_iter(%dyn_69) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?,?,?)">
        %coord_84 = cute.make_coord(%e1_82) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %120 = cute.get_scalars(%coord_84) : !cute.coord<"?">
        %121 = arith.cmpi slt, %117, %120 : i32
        scf.if %121 {
          %iter_154 = cute.get_iter(%rmem_70) : !memref_rmem_i8_
          %213 = cute.get_scalars(%36) : !cute.int_tuple<"4">
          scf.for %arg4 = %c0_i32 to %213 step %c1_i32  : i32 {
            %coord_155 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_156 = cute.crd2idx(%coord_155, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_157 = cute.add_offset(%ptr_53, %idx_156) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_158 = cute.crd2idx(%coord_155, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_159 = cute.add_offset(%ptr_54, %idx_158) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
            %idx_160 = cute.crd2idx(%coord_155, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
            %ptr_161 = cute.add_offset(%iter_154, %idx_160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %214 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
            %215 = llvm.load %214 : !llvm.ptr -> i8
            %216 = llvm.trunc %215 : i8 to i1
            %iter_162 = cute.recast_iter(%ptr_157) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_163 = cute.recast_iter(%ptr_159) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_163 : !cute.ptr<i128, smem>, %iter_162 : !cute.ptr<i128, gmem>, %216 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %iter_85 = cute.get_iter(%rmem) : !memref_rmem_i8_
        %iter_86 = cute.get_iter(%rmem_70) : !memref_rmem_i8_
        %coord_87 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
        %idx_88 = cute.crd2idx(%coord_87, %40) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"32">
        %ptr_89 = cute.add_offset(%ptr_48, %idx_88) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
        %idx_90 = cute.crd2idx(%coord_87, %35) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"4096">
        %ptr_91 = cute.add_offset(%ptr_51, %idx_90) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
        %122 = cute.get_scalars(%36) : !cute.int_tuple<"4">
        scf.for %arg4 = %c0_i32 to %122 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_156 = cute.add_offset(%ptr_89, %idx_155) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
          %idx_157 = cute.crd2idx(%coord_154, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_158 = cute.add_offset(%ptr_91, %idx_157) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_159 = cute.crd2idx(%coord_154, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
          %ptr_160 = cute.add_offset(%iter_85, %idx_159) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %213 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
          %214 = llvm.load %213 : !llvm.ptr -> i8
          %215 = llvm.trunc %214 : i8 to i1
          %iter_161 = cute.recast_iter(%ptr_156) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_162 = cute.recast_iter(%ptr_158) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_162 : !cute.ptr<i128, smem>, %iter_161 : !cute.ptr<i128, gmem>, %215 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
        %ptr_92 = cute.add_offset(%ptr_53, %idx_88) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
        %ptr_93 = cute.add_offset(%ptr_54, %idx_90) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
        scf.for %arg4 = %c0_i32 to %122 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_156 = cute.add_offset(%ptr_92, %idx_155) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
          %idx_157 = cute.crd2idx(%coord_154, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_158 = cute.add_offset(%ptr_93, %idx_157) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_159 = cute.crd2idx(%coord_154, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
          %ptr_160 = cute.add_offset(%iter_86, %idx_159) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %213 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
          %214 = llvm.load %213 : !llvm.ptr -> i8
          %215 = llvm.trunc %214 : i8 to i1
          %iter_161 = cute.recast_iter(%ptr_156) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_162 = cute.recast_iter(%ptr_158) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_162 : !cute.ptr<i128, smem>, %iter_161 : !cute.ptr<i128, gmem>, %215 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.commit.group
        %123 = arith.remsi %81, %c32_i32 : i32
        %124 = arith.divsi %81, %c32_i32 : i32
        %125 = arith.remsi %124, %c2_i32 : i32
        %126 = arith.divsi %81, %c64_i32 : i32
        %127 = arith.remsi %126, %c2_i32 : i32
        %128 = arith.remsi %123, %c32_i32 : i32
        %129 = arith.remsi %125, %c2_i32 : i32
        %130 = arith.remsi %127, %c2_i32 : i32
        %131 = arith.divsi %128, %c4_i32 : i32
        %132 = arith.muli %131, %c128_i32 : i32
        %133 = arith.muli %130, %c8_i32 : i32
        %134 = arith.addi %132, %133 : i32
        %135 = arith.remsi %128, %c4_i32 : i32
        %136 = arith.muli %135, %c2_i32 : i32
        %137 = arith.muli %129, %c2048_i32 : i32
        %138 = arith.addi %136, %137 : i32
        %139 = arith.andi %134, %c256_i32 : i32
        %140 = arith.cmpi eq, %139, %c0_i32 : i32
        %141 = arith.select %140, %c16_i32, %c-16_i32 : i32
        %142 = arith.andi %134, %c512_i32 : i32
        %143 = arith.cmpi eq, %142, %c0_i32 : i32
        %144 = arith.select %143, %c32_i32, %c-32_i32 : i32
        %145 = arith.andi %134, %c896_i32 : i32
        %146 = arith.shrsi %145, %c4_i32 : i32
        %147 = arith.xori %134, %146 : i32
        %148 = arith.addi %147, %138 : i32
        %iv_94 = cute.assume(%148) : (i32) -> !cute.i32<divby 2>
        %int_tuple_95 = cute.make_int_tuple(%iv_94) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
        %ptr_96 = cute.add_offset(%iter_44, %int_tuple_95) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, smem, align<4>>
        %iv_97 = cute.assume(%141) : (i32) -> !cute.i32<divby 16>
        %iv_98 = cute.assume(%144) : (i32) -> !cute.i32<divby 32>
        %stride = cute.make_stride(%iv_97, %iv_98) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,1024),4096,(?{div=16},?{div=32},64))">
        %lay = cute.make_layout(%31, %stride) : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
        %rmem_99 = cute.memref.alloca() : !memref_rmem_f16_
        %rmem_100 = cute.memref.alloca() : !memref_rmem_f16_1
        %rmem_101 = cute.memref.alloca() : !memref_rmem_f32_
        cute.memref.store_vec %cst, %rmem_101 : !memref_rmem_f32_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
        %149 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
        %150 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
        %151 = arith.divsi %101, %c2_i32 : i32
        %152 = arith.remsi %151, %c4_i32 : i32
        %153 = arith.muli %152, %c64_i32 : i32
        %154 = arith.remsi %100, %c2_i32 : i32
        %155 = arith.muli %154, %c8_i32 : i32
        %156 = arith.addi %153, %155 : i32
        %157 = arith.remsi %101, %c2_i32 : i32
        %158 = arith.muli %157, %c32_i32 : i32
        %159 = arith.divsi %151, %c4_i32 : i32
        %160 = arith.muli %159, %c256_i32 : i32
        %161 = arith.addi %158, %160 : i32
        %162 = arith.divsi %100, %c2_i32 : i32
        %163 = arith.remsi %162, %c2_i32 : i32
        %164 = arith.muli %163, %c512_i32 : i32
        %165 = arith.addi %161, %164 : i32
        %166 = arith.andi %156, %c128_i32 : i32
        %167 = arith.cmpi eq, %166, %c0_i32 : i32
        %168 = arith.select %167, %c16_i32, %c-16_i32 : i32
        %169 = arith.andi %156, %c192_i32 : i32
        %170 = arith.shrsi %169, %c3_i32 : i32
        %171 = arith.xori %156, %170 : i32
        %172 = arith.addi %171, %165 : i32
        %iv_102 = cute.assume(%172) : (i32) -> !cute.i32<divby 8>
        %int_tuple_103 = cute.make_int_tuple(%iv_102) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_104 = cute.add_offset(%iter_42, %int_tuple_103) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %iv_105 = cute.assume(%168) : (i32) -> !cute.i32<divby 16>
        %stride_106 = cute.make_stride(%iv_105) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
        %lay_107 = cute.make_layout(%30, %stride_106) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iter_108 = cute.get_iter(%rmem_99) : !memref_rmem_f16_
        %173 = arith.divsi %81, %c8_i32 : i32
        %174 = arith.remsi %81, %c8_i32 : i32
        %175 = arith.divsi %174, %c2_i32 : i32
        %176 = arith.muli %175, %c64_i32 : i32
        %177 = arith.remsi %173, %c2_i32 : i32
        %178 = arith.muli %177, %c8_i32 : i32
        %179 = arith.addi %176, %178 : i32
        %180 = arith.remsi %174, %c2_i32 : i32
        %181 = arith.muli %180, %c32_i32 : i32
        %182 = arith.divsi %173, %c2_i32 : i32
        %183 = arith.divsi %182, %c2_i32 : i32
        %184 = arith.remsi %182, %c2_i32 : i32
        %185 = arith.muli %184, %c512_i32 : i32
        %186 = arith.addi %181, %185 : i32
        %187 = arith.divsi %183, %c2_i32 : i32
        %188 = arith.muli %187, %c256_i32 : i32
        %189 = arith.addi %186, %188 : i32
        %190 = arith.andi %179, %c128_i32 : i32
        %191 = arith.cmpi eq, %190, %c0_i32 : i32
        %192 = arith.select %191, %c16_i32, %c-16_i32 : i32
        %193 = arith.andi %179, %c192_i32 : i32
        %194 = arith.shrsi %193, %c3_i32 : i32
        %195 = arith.xori %179, %194 : i32
        %196 = arith.addi %195, %189 : i32
        %iv_109 = cute.assume(%196) : (i32) -> !cute.i32<divby 8>
        %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_111 = cute.add_offset(%iter_43, %int_tuple_110) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %iv_112 = cute.assume(%192) : (i32) -> !cute.i32<divby 16>
        %stride_113 = cute.make_stride(%iv_112) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
        %lay_114 = cute.make_layout(%30, %stride_113) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iter_115 = cute.get_iter(%rmem_100) : !memref_rmem_f16_1
        %197 = cute.get_scalars(%lay_107) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iv_116 = cute.assume(%197) : (i32) -> !cute.i32<divby 16>
        %stride_117 = cute.make_stride(%iv_116) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
        %lay_118 = cute.make_layout(%29, %stride_117) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
        %view_119 = cute.make_view(%ptr_104, %lay_118) : !memref_smem_f16_1
        %198 = cute.get_scalars(%lay_114) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iv_120 = cute.assume(%198) : (i32) -> !cute.i32<divby 16>
        %stride_121 = cute.make_stride(%iv_120) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
        %lay_122 = cute.make_layout(%29, %stride_121) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
        %view_123 = cute.make_view(%ptr_111, %lay_122) : !memref_smem_f16_1
        nvvm.cp.async.wait.group 1
        nvvm.barrier
        scf.for %arg4 = %c0_i32 to %122 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_156 = cute.add_offset(%ptr_104, %idx_155) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_157 = cute.crd2idx(%coord_154, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_158 = cute.add_offset(%iter_108, %idx_157) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %213 = cute_nvgpu.arch.copy.ldsm %ptr_156{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
          %214 = vector.extractelement %213[%27 : i32] : vector<4xi32>
          %215 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          llvm.store %214, %215 : i32, !llvm.ptr
          %216 = vector.extractelement %213[%26 : i32] : vector<4xi32>
          %ptr_159 = cute.add_offset(%ptr_158, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
          %217 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %216, %217 : i32, !llvm.ptr
          %218 = vector.extractelement %213[%24 : i32] : vector<4xi32>
          %ptr_160 = cute.add_offset(%ptr_158, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
          %219 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %218, %219 : i32, !llvm.ptr
          %220 = vector.extractelement %213[%23 : i32] : vector<4xi32>
          %ptr_161 = cute.add_offset(%ptr_158, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
          %221 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %220, %221 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        scf.for %arg4 = %c0_i32 to %122 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_156 = cute.add_offset(%ptr_111, %idx_155) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_157 = cute.crd2idx(%coord_154, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_158 = cute.add_offset(%iter_115, %idx_157) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
          %213 = cute_nvgpu.arch.copy.ldsm %ptr_156{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
          %214 = vector.extractelement %213[%27 : i32] : vector<4xi32>
          %215 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %214, %215 : i32, !llvm.ptr
          %216 = vector.extractelement %213[%26 : i32] : vector<4xi32>
          %ptr_159 = cute.add_offset(%ptr_158, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
          %217 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %216, %217 : i32, !llvm.ptr
          %218 = vector.extractelement %213[%24 : i32] : vector<4xi32>
          %ptr_160 = cute.add_offset(%ptr_158, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
          %219 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %218, %219 : i32, !llvm.ptr
          %220 = vector.extractelement %213[%23 : i32] : vector<4xi32>
          %ptr_161 = cute.add_offset(%ptr_158, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
          %221 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %220, %221 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %iter_124 = cute.get_iter(%rmem_101) : !memref_rmem_f32_
        %199 = cute.get_scalars(%15) : !cute.int_tuple<"1">
        %200 = cute.get_scalars(%14) : !cute.int_tuple<"8">
        %201:5 = scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg5 = %view_119, %arg6 = %view_123, %arg7 = %c2_i32, %arg8 = %c2_i32, %arg9 = %c0_i32) -> (!memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32)  : i32 {
          %213:5 = scf.for %arg10 = %c0_i32 to %c2_i32 step %c1_i32 iter_args(%arg11 = %arg5, %arg12 = %arg6, %arg13 = %arg7, %arg14 = %arg8, %arg15 = %arg9) -> (!memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32)  : i32 {
            %214 = arith.cmpi eq, %arg10, %c1_i32 : i32
            %215:2 = scf.if %214 -> (!memref_smem_f16_1, !memref_smem_f16_1) {
              %coord_171 = cute.make_coord(%arg15) : (i32) -> !cute.coord<"(_,_,_,?)">
              %idx_172 = cute.crd2idx(%coord_171, %lay_107) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_173 = cute.add_offset(%ptr_104, %idx_172) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
              %view_174 = cute.make_view(%ptr_173, %lay_118) : !memref_smem_f16_1
              %idx_175 = cute.crd2idx(%coord_171, %lay_114) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_176 = cute.add_offset(%ptr_111, %idx_175) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
              %view_177 = cute.make_view(%ptr_176, %lay_122) : !memref_smem_f16_1
              nvvm.cp.async.wait.group 1
              nvvm.barrier
              scf.yield %view_174, %view_177 : !memref_smem_f16_1, !memref_smem_f16_1
            } else {
              scf.yield %arg11, %arg12 : !memref_smem_f16_1, !memref_smem_f16_1
            }
            %216 = arith.addi %arg10, %c1_i32 : i32
            %217 = arith.remsi %216, %c2_i32 : i32
            %coord_154 = cute.make_coord(%217) : (i32) -> !cute.coord<"(_,_,?)">
            %lay_155 = cute.get_layout(%215#0) : !memref_smem_f16_1
            %idx_156 = cute.crd2idx(%coord_154, %lay_155) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
            %iter_157 = cute.get_iter(%215#0) : !memref_smem_f16_1
            %ptr_158 = cute.add_offset(%iter_157, %idx_156) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
            %idx_159 = cute.crd2idx(%coord_154, %21) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),8,32)">) -> !cute.int_tuple<"?{div=32}">
            %ptr_160 = cute.add_offset(%iter_108, %idx_159) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
            scf.for %arg16 = %c0_i32 to %122 step %c1_i32  : i32 {
              %coord_171 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
              %idx_172 = cute.crd2idx(%coord_171, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
              %ptr_173 = cute.add_offset(%ptr_158, %idx_172) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
              %idx_174 = cute.crd2idx(%coord_171, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
              %ptr_175 = cute.add_offset(%ptr_160, %idx_174) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
              %221 = cute_nvgpu.arch.copy.ldsm %ptr_173{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
              %222 = vector.extractelement %221[%27 : i32] : vector<4xi32>
              %223 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              llvm.store %222, %223 : i32, !llvm.ptr
              %224 = vector.extractelement %221[%26 : i32] : vector<4xi32>
              %ptr_176 = cute.add_offset(%ptr_175, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
              %225 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %224, %225 : i32, !llvm.ptr
              %226 = vector.extractelement %221[%24 : i32] : vector<4xi32>
              %ptr_177 = cute.add_offset(%ptr_175, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
              %227 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %226, %227 : i32, !llvm.ptr
              %228 = vector.extractelement %221[%23 : i32] : vector<4xi32>
              %ptr_178 = cute.add_offset(%ptr_175, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
              %229 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %228, %229 : i32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %lay_161 = cute.get_layout(%215#1) : !memref_smem_f16_1
            %idx_162 = cute.crd2idx(%coord_154, %lay_161) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
            %iter_163 = cute.get_iter(%215#1) : !memref_smem_f16_1
            %ptr_164 = cute.add_offset(%iter_163, %idx_162) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
            %ptr_165 = cute.add_offset(%iter_115, %idx_159) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
            scf.for %arg16 = %c0_i32 to %122 step %c1_i32  : i32 {
              %coord_171 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
              %idx_172 = cute.crd2idx(%coord_171, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
              %ptr_173 = cute.add_offset(%ptr_164, %idx_172) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
              %idx_174 = cute.crd2idx(%coord_171, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
              %ptr_175 = cute.add_offset(%ptr_165, %idx_174) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
              %221 = cute_nvgpu.arch.copy.ldsm %ptr_173{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
              %222 = vector.extractelement %221[%27 : i32] : vector<4xi32>
              %223 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %222, %223 : i32, !llvm.ptr
              %224 = vector.extractelement %221[%26 : i32] : vector<4xi32>
              %ptr_176 = cute.add_offset(%ptr_175, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
              %225 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %224, %225 : i32, !llvm.ptr
              %226 = vector.extractelement %221[%24 : i32] : vector<4xi32>
              %ptr_177 = cute.add_offset(%ptr_175, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
              %227 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %226, %227 : i32, !llvm.ptr
              %228 = vector.extractelement %221[%23 : i32] : vector<4xi32>
              %ptr_178 = cute.add_offset(%ptr_175, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
              %229 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %228, %229 : i32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %218 = arith.cmpi eq, %arg10, %c0_i32 : i32
            scf.if %218 {
              %221 = arith.addi %arg4, %c2_i32 : i32
              %222 = arith.cmpi slt, %221, %c4_i32 : i32
              scf.if %222 {
                %coord_171 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_172 = cute.crd2idx(%coord_171, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
                %ptr_173 = cute.add_offset(%ptr_48, %idx_172) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
                %coord_174 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_175 = cute.crd2idx(%coord_174, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
                %ptr_176 = cute.add_offset(%ptr_51, %idx_175) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
                scf.for %arg16 = %c0_i32 to %122 step %c1_i32  : i32 {
                  %coord_177 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
                  %idx_178 = cute.crd2idx(%coord_177, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
                  %ptr_179 = cute.add_offset(%ptr_173, %idx_178) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
                  %idx_180 = cute.crd2idx(%coord_177, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
                  %ptr_181 = cute.add_offset(%ptr_176, %idx_180) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
                  %idx_182 = cute.crd2idx(%coord_177, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
                  %ptr_183 = cute.add_offset(%iter_85, %idx_182) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
                  %223 = builtin.unrealized_conversion_cast %ptr_183 : !cute.ptr<i8, rmem> to !llvm.ptr
                  %224 = llvm.load %223 : !llvm.ptr -> i8
                  %225 = llvm.trunc %224 : i8 to i1
                  %iter_184 = cute.recast_iter(%ptr_179) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
                  %iter_185 = cute.recast_iter(%ptr_181) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
                  cute_nvgpu.arch.copy.SM80.cp_async(%iter_185 : !cute.ptr<i128, smem>, %iter_184 : !cute.ptr<i128, gmem>, %225 : i1) {cache_mode = <global>}
                } {llvm.loop_annotation = #loop_annotation}
              }
            }
            %coord_166 = cute.make_coord(%arg10) : (i32) -> !cute.coord<"(_,_,?)">
            %idx_167 = cute.crd2idx(%coord_166, %20) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2,2),4,2):((1,2,4),8,32)">) -> !cute.int_tuple<"?{div=32}">
            %ptr_168 = cute.add_offset(%iter_108, %idx_167) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
            %idx_169 = cute.crd2idx(%coord_166, %19) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2),8,2):((1,2),4,32)">) -> !cute.int_tuple<"?{div=32}">
            %ptr_170 = cute.add_offset(%iter_115, %idx_169) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
            scf.for %arg16 = %c0_i32 to %199 step %c1_i32  : i32 {
              scf.for %arg17 = %c0_i32 to %122 step %c1_i32  : i32 {
                %coord_171 = cute.make_coord(%arg17, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %idx_172 = cute.crd2idx(%coord_171, %17) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),4,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
                %ptr_173 = cute.add_offset(%ptr_168, %idx_172) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
                %221 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
                %222 = llvm.getelementptr %221[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                %223 = llvm.getelementptr %221[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                %224 = llvm.getelementptr %221[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                scf.for %arg18 = %c0_i32 to %200 step %c1_i32  : i32 {
                  %coord_174 = cute.make_coord(%arg18, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
                  %coord_175 = cute.make_coord(%arg17, %arg18) : (i32, i32) -> !cute.coord<"(_,?,?)">
                  %idx_176 = cute.crd2idx(%coord_174, %16) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
                  %ptr_177 = cute.add_offset(%ptr_170, %idx_176) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
                  %idx_178 = cute.crd2idx(%coord_175, %18) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,8):((1,2),4,16)">) -> !cute.int_tuple<"?{div=4}">
                  %ptr_179 = cute.add_offset(%iter_124, %idx_178) : (!cute.ptr<f32, rmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
                  %225 = llvm.load %221 : !llvm.ptr -> vector<2xf16>
                  %226 = llvm.load %222 : !llvm.ptr -> vector<2xf16>
                  %227 = llvm.load %223 : !llvm.ptr -> vector<2xf16>
                  %228 = llvm.load %224 : !llvm.ptr -> vector<2xf16>
                  %229 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
                  %230 = llvm.load %229 : !llvm.ptr -> vector<2xf16>
                  %231 = llvm.getelementptr %229[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                  %232 = llvm.load %231 : !llvm.ptr -> vector<2xf16>
                  %233 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
                  %234 = llvm.load %233 : !llvm.ptr -> f32
                  %235 = llvm.getelementptr %233[1] : (!llvm.ptr) -> !llvm.ptr, f32
                  %236 = llvm.load %235 : !llvm.ptr -> f32
                  %237 = llvm.getelementptr %233[2] : (!llvm.ptr) -> !llvm.ptr, f32
                  %238 = llvm.load %237 : !llvm.ptr -> f32
                  %239 = llvm.getelementptr %233[3] : (!llvm.ptr) -> !llvm.ptr, f32
                  %240 = llvm.load %239 : !llvm.ptr -> f32
                  %241:4 = cute_nvgpu.arch.mma.SM80 A[%225, %226, %227, %228]  B[%230, %232]  C[%234, %236, %238, %240] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
                  llvm.store %241#0, %233 : f32, !llvm.ptr
                  llvm.store %241#1, %235 : f32, !llvm.ptr
                  llvm.store %241#2, %237 : f32, !llvm.ptr
                  llvm.store %241#3, %239 : f32, !llvm.ptr
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %219 = arith.select %218, %arg15, %arg14 : i32
            %220:2 = scf.if %218 -> (i32, i32) {
              %221 = arith.addi %arg4, %c2_i32 : i32
              %222 = arith.cmpi slt, %221, %c4_i32 : i32
              scf.if %222 {
                %coord_171 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_172 = cute.crd2idx(%coord_171, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
                %ptr_173 = cute.add_offset(%ptr_53, %idx_172) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
                %coord_174 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_175 = cute.crd2idx(%coord_174, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
                %ptr_176 = cute.add_offset(%ptr_54, %idx_175) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
                scf.for %arg16 = %c0_i32 to %122 step %c1_i32  : i32 {
                  %coord_177 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
                  %idx_178 = cute.crd2idx(%coord_177, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
                  %ptr_179 = cute.add_offset(%ptr_173, %idx_178) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
                  %idx_180 = cute.crd2idx(%coord_177, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
                  %ptr_181 = cute.add_offset(%ptr_176, %idx_180) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
                  %idx_182 = cute.crd2idx(%coord_177, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
                  %ptr_183 = cute.add_offset(%iter_86, %idx_182) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
                  %227 = builtin.unrealized_conversion_cast %ptr_183 : !cute.ptr<i8, rmem> to !llvm.ptr
                  %228 = llvm.load %227 : !llvm.ptr -> i8
                  %229 = llvm.trunc %228 : i8 to i1
                  %iter_184 = cute.recast_iter(%ptr_179) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
                  %iter_185 = cute.recast_iter(%ptr_181) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
                  cute_nvgpu.arch.copy.SM80.cp_async(%iter_185 : !cute.ptr<i128, smem>, %iter_184 : !cute.ptr<i128, gmem>, %229 : i1) {cache_mode = <global>}
                } {llvm.loop_annotation = #loop_annotation}
              }
              %223 = arith.addi %arg13, %c1_i32 : i32
              nvvm.cp.async.commit.group
              %224 = arith.addi %arg15, %c1_i32 : i32
              %225 = arith.cmpi eq, %224, %c3_i32 : i32
              %226 = arith.select %225, %c0_i32, %224 : i32
              scf.yield %223, %226 : i32, i32
            } else {
              scf.yield %arg13, %arg15 : i32, i32
            }
            scf.yield %215#0, %215#1, %220#0, %219, %220#1 : !memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          scf.yield %213#0, %213#1, %213#2, %213#3, %213#4 : !memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32
        }
        nvvm.cp.async.wait.group 0
        nvvm.barrier
        %rmem_125 = cute.memref.alloca() : !memref_rmem_f16_2
        %202 = cute.memref.load_vec %rmem_101 : !memref_rmem_f32_
        %203 = arith.truncf %202 : vector<128xf32> to vector<128xf16>
        %iter_126 = cute.get_iter(%rmem_125) : !memref_rmem_f16_2
        %view_127 = cute.make_view(%iter_126) : !memref_rmem_f16_2
        cute.memref.store_vec %203, %view_127 : !memref_rmem_f16_2
        %204:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
        %iv_128 = cute.assume(%204#0) : (i32) -> !cute.i32<divby 16>
        %iv_129 = cute.assume(%204#1) : (i32) -> !cute.i32<divby 32>
        %stride_130 = cute.make_stride(%iv_128, %iv_129) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
        %lay_131 = cute.make_layout(%13, %stride_130) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %205:2 = cute.get_scalars(%lay_131) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %iv_132 = cute.assume(%205#0) : (i32) -> !cute.i32<divby 16>
        %iv_133 = cute.assume(%205#1) : (i32) -> !cute.i32<divby 32>
        %stride_134 = cute.make_stride(%iv_132, %iv_133) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
        %lay_135 = cute.make_layout(%13, %stride_134) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %append = cute.append_to_rank<2> (%lay_135, %57) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">, !cute.layout<"1:0">
        %206:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %iv_136 = cute.assume(%206#0) : (i32) -> !cute.i32<divby 16>
        %iv_137 = cute.assume(%206#1) : (i32) -> !cute.i32<divby 32>
        %stride_138 = cute.make_stride(%iv_136, %iv_137) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,((1024,4096,?{div=16},?{div=32},64)))">
        %lay_139 = cute.make_layout(%11, %stride_138) : !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">
        %207 = cute.get_scalars(%10) : !cute.int_tuple<"64">
        scf.for %arg4 = %c0_i32 to %207 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %12) : (!cute.coord<"(_,?)">, !cute.layout<"(2,(64)):(1,(2))">) -> !cute.int_tuple<"?{div=2}">
          %ptr_156 = cute.add_offset(%iter_126, %idx_155) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, rmem, align<4>>
          %idx_157 = cute.crd2idx(%coord_154, %lay_139) : (!cute.coord<"(_,?)">, !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_158 = cute.add_offset(%ptr_96, %idx_157) : (!cute.ptr<f16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<4>>
          %213 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          %214 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f16, smem, align<4>> to !llvm.ptr<3>
          %215 = llvm.load %213 {alignment = 4 : i64} : !llvm.ptr -> vector<2xf16>
          llvm.store %215, %214 {alignment = 4 : i64} : vector<2xf16>, !llvm.ptr<3>
        } {llvm.loop_annotation = #loop_annotation}
        %idx_140 = cute.crd2idx(%coord, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,1):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup_141 = cute.add_offset(%48, %idx_140) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %idx_142 = cute.crd2idx(%coord_14, %8) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((1@0,1@1),(128@0,128@1))">) -> !cute.int_tuple<"(?{div=128},?{div=128})">
        %tup_143 = cute.add_offset(%tup_141, %idx_142) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},?{div=128})">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
        %iv_144 = cute.assume(%112) : (i32) -> !cute.i32<divby 8>
        %int_tuple_145 = cute.make_int_tuple(%100, %iv_144) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
        %tup_146 = cute.add_offset(%tup_143, %int_tuple_145) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %rmem_147 = cute.memref.alloca() : !memref_rmem_f16_3
        nvvm.barrier
        %iter_148 = cute.get_iter(%rmem_147) : !memref_rmem_f16_3
        %208 = cute.get_scalars(%5) : !cute.int_tuple<"16">
        scf.for %arg4 = %c0_i32 to %208 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_155 = cute.crd2idx(%coord_154, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(1024))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_156 = cute.add_offset(%ptr_58, %idx_155) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_157 = cute.crd2idx(%coord_154, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_158 = cute.add_offset(%iter_148, %idx_157) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %213 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f16, smem, align<16>> to !llvm.ptr<3>
          %214 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          %215 = llvm.load %213 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xf16>
          llvm.store %215, %214 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %rmem_149 = cute.memref.alloca() : !memref_rmem_i8_1
        %209 = cute.get_scalars(%42) : !cute.coord<"512">
        scf.for %arg4 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
          %coord_154 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0)">
          %idx_155 = cute.crd2idx(%coord_154, %4) : (!cute.coord<"((0,0),?,0)">, !cute.layout<"((8,1),16,1):((1@1,0),8@0,0)">) -> !cute.int_tuple<"(?{div=8},0)">
          %tup_156 = cute.add_offset(%tup_146, %idx_155) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(?{div=8},0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
          %e0_157, %e1_158, %e2_159 = cute.get_leaves(%tup_156) : !cute.int_tuple<"(?,?{div=8},?)">
          %coord_160 = cute.make_coord(%e0_157) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %213 = cute.get_scalars(%coord_160) : !cute.coord<"?">
          %214 = arith.cmpi slt, %213, %209 : i32
          %215 = arith.extui %214 : i1 to i8
          %coord_161 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_162 = cute.derefine(%coord_161) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem_149, %dyn_162, %215) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        %e0_150, %e1_151, %e2_152 = cute.get_leaves(%tup_146) : !cute.int_tuple<"(?,?{div=8},?)">
        %coord_153 = cute.make_coord(%e1_151) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
        %210 = cute.get_scalars(%coord_153) : !cute.coord<"?{div=8}">
        %211 = cute.get_scalars(%41) : !cute.coord<"256">
        %212 = arith.cmpi slt, %210, %211 : i32
        scf.if %212 {
          %iter_154 = cute.get_iter(%rmem_149) : !memref_rmem_i8_1
          scf.for %arg4 = %c0_i32 to %208 step %c1_i32  : i32 {
            %coord_155 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_156 = cute.crd2idx(%coord_155, %3) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
            %ptr_157 = cute.add_offset(%iter_148, %idx_156) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
            %idx_158 = cute.crd2idx(%coord_155, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((2048)))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_159 = cute.add_offset(%ptr_61, %idx_158) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_160 = cute.crd2idx(%coord_155, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((16))):(16,((1)))">) -> !cute.int_tuple<"?">
            %ptr_161 = cute.add_offset(%iter_154, %idx_160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %213 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
            %214 = llvm.load %213 : !llvm.ptr -> i8
            %215 = llvm.icmp "ne" %214, %0 : i8
            scf.if %215 {
              %216 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %217 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
              %218 = llvm.load %216 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %218, %217 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
      }
      return
    }
  }
  func.func @cutlass_tensor_op_gemm_wrapper___main__BufferWithLayoutobjectat___main__BufferWithLayoutobjectat___main__BufferWithLayoutobjectat_512_256_128_16_Float32_2_2_1(%arg0: !cute.ptr<f16, gmem, align<32>>, %arg1: !cute.ptr<f16, gmem, align<32>>, %arg2: !cute.ptr<f16, gmem, align<32>>) -> i32 attributes {llvm.emit_c_interface} {
    %c49152_i64 = arith.constant 49152 : i64
    %c8_i32 = arith.constant 8 : i32
    %c0_i32 = arith.constant 0 : i32
    %c16_i32 = arith.constant 16 : i32
    %c128_i32 = arith.constant 128 : i32
    %c0_i64 = arith.constant 0 : i64
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %0 = cute.static : !cute.layout<"(512,256,16):(256,1,131072)">
    %1 = cute.static : !cute.layout<"(256,128,16):(128,1,32768)">
    %2 = cute.static : !cute.layout<"(512,128,16):(128,1,65536)">
    %view = cute.make_view(%arg0, %2) : !memref_gmem_f16_
    %view_0 = cute.make_view(%arg1, %1) : !memref_gmem_f16_1
    %view_1 = cute.make_view(%arg2, %0) : !memref_gmem_f16_2
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<f16, cache = global, 128 b>
    %3 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %4 = cute.make_tiled_copy(%atom) : !copy_ldgsts
    %atom_2 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f16, 128 b>
    %5 = cute.make_tiled_copy(%atom_2) : !copy_simt
    %6 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %7 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c49152_i64, gridDim = (%c8_i32, %c1_i32, %c16_i32), stream = %6) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %8 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_tensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o512256162561131072_S_0<%7> (%view, %view_0, %view_1, %c2_i32) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f16_, !memref_gmem_f16_1, !memref_gmem_f16_2, i32) -> !cuda.result
    %9 = cuda.cast %8 : !cuda.result -> i32
    cuda.return_if_error %9 : i32
    return %c0_i32 : i32
  }
}
