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
    cuda.kernel @kernel_cutlass_kernel_amperetensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o51225616256113_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_1, %arg2: !memref_gmem_f16_2, %arg3: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      cf.cond_br %71, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cf.br ^bb88
    ^bb2:  // pred: ^bb0
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
      cf.br ^bb3(%c0_i32 : i32)
    ^bb3(%116: i32):  // 2 preds: ^bb2, ^bb4
      %117 = arith.cmpi slt, %116, %c4_i32 : i32
      cf.cond_br %117, ^bb4, ^bb5
    ^bb4:  // pred: ^bb3
      %coord_72 = cute.make_coord(%116) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_73 = cute.crd2idx(%coord_72, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_74 = cute.add_offset(%iter_71, %idx_73) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
      %e0_75, %e1_76, %e2_77 = cute.get_leaves(%tup_74) : !cute.int_tuple<"(?,?,?)">
      %coord_78 = cute.make_coord(%e0_75) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %118 = cute.get_scalars(%coord_78) : !cute.coord<"?">
      %119 = arith.cmpi slt, %118, %115 : i32
      %120 = arith.extui %119 : i1 to i8
      %coord_79 = cute.make_coord(%116) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_80 = cute.derefine(%coord_79) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem, %dyn_80, %120) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %121 = arith.addi %116, %c1_i32 : i32
      cf.br ^bb3(%121 : i32)
    ^bb5:  // pred: ^bb3
      %iter_81 = cute.get_iter(%dyn_69) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %122 = cute.get_scalars(%41) : !cute.coord<"256">
      cf.br ^bb6(%c0_i32 : i32)
    ^bb6(%123: i32):  // 2 preds: ^bb5, ^bb7
      %124 = arith.cmpi slt, %123, %c4_i32 : i32
      cf.cond_br %124, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %coord_82 = cute.make_coord(%123) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_83 = cute.crd2idx(%coord_82, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_84 = cute.add_offset(%iter_81, %idx_83) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
      %e0_85, %e1_86, %e2_87 = cute.get_leaves(%tup_84) : !cute.int_tuple<"(?,?,?)">
      %coord_88 = cute.make_coord(%e0_85) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %125 = cute.get_scalars(%coord_88) : !cute.coord<"?">
      %126 = arith.cmpi slt, %125, %122 : i32
      %127 = arith.extui %126 : i1 to i8
      %coord_89 = cute.make_coord(%123) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_90 = cute.derefine(%coord_89) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem_70, %dyn_90, %127) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %128 = arith.addi %123, %c1_i32 : i32
      cf.br ^bb6(%128 : i32)
    ^bb8:  // pred: ^bb6
      cute.memref.store_vec %cst_0, %view_52 : !memref_smem_f16_
      cute.memref.store_vec %cst_0, %view_55 : !memref_smem_f16_
      nvvm.barrier
      %iter_91 = cute.get_iter(%dyn_66) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %e0_92, %e1_93, %e2_94 = cute.get_leaves(%iter_91) : !cute.int_tuple<"(?,?,?)">
      %coord_95 = cute.make_coord() : () -> !cute.coord<"-1">
      %dyn_96 = cute.derefine(%coord_95) : !cute.coord<"-1"> to !cute.coord<"?">
      %coord_97 = cute.make_coord(%e1_93) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %129 = cute.get_scalars(%dyn_96) : !cute.coord<"?">
      %130 = cute.get_scalars(%coord_97) : !cute.coord<"?">
      %131 = arith.cmpi slt, %129, %130 : i32
      cf.cond_br %131, ^bb9, ^bb13
    ^bb9:  // pred: ^bb8
      %iter_98 = cute.get_iter(%rmem) : !memref_rmem_i8_
      %132 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb10(%c0_i32 : i32)
    ^bb10(%133: i32):  // 2 preds: ^bb9, ^bb11
      %134 = arith.cmpi slt, %133, %132 : i32
      cf.cond_br %134, ^bb11, ^bb12 {llvm.loop_annotation = #loop_annotation}
    ^bb11:  // pred: ^bb10
      %coord_99 = cute.make_coord(%133) : (i32) -> !cute.coord<"(_,?)">
      %idx_100 = cute.crd2idx(%coord_99, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_101 = cute.add_offset(%ptr_48, %idx_100) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_102 = cute.crd2idx(%coord_99, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_103 = cute.add_offset(%ptr_51, %idx_102) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_104 = cute.crd2idx(%coord_99, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
      %ptr_105 = cute.add_offset(%iter_98, %idx_104) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %135 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i8, rmem> to !llvm.ptr
      %136 = llvm.load %135 : !llvm.ptr -> i8
      %137 = llvm.trunc %136 : i8 to i1
      %iter_106 = cute.recast_iter(%ptr_101) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_107 = cute.recast_iter(%ptr_103) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_107 : !cute.ptr<i128, smem>, %iter_106 : !cute.ptr<i128, gmem>, %137 : i1) {cache_mode = <global>}
      %138 = arith.addi %133, %c1_i32 : i32
      cf.br ^bb10(%138 : i32)
    ^bb12:  // pred: ^bb10
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb8, ^bb12
      %iter_108 = cute.get_iter(%dyn_69) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %e0_109, %e1_110, %e2_111 = cute.get_leaves(%iter_108) : !cute.int_tuple<"(?,?,?)">
      %coord_112 = cute.make_coord(%e1_110) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %139 = cute.get_scalars(%coord_112) : !cute.coord<"?">
      %140 = arith.cmpi slt, %129, %139 : i32
      cf.cond_br %140, ^bb14, ^bb18
    ^bb14:  // pred: ^bb13
      %iter_113 = cute.get_iter(%rmem_70) : !memref_rmem_i8_
      %141 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb15(%c0_i32 : i32)
    ^bb15(%142: i32):  // 2 preds: ^bb14, ^bb16
      %143 = arith.cmpi slt, %142, %141 : i32
      cf.cond_br %143, ^bb16, ^bb17 {llvm.loop_annotation = #loop_annotation}
    ^bb16:  // pred: ^bb15
      %coord_114 = cute.make_coord(%142) : (i32) -> !cute.coord<"(_,?)">
      %idx_115 = cute.crd2idx(%coord_114, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_116 = cute.add_offset(%ptr_53, %idx_115) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_117 = cute.crd2idx(%coord_114, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_118 = cute.add_offset(%ptr_54, %idx_117) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_119 = cute.crd2idx(%coord_114, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
      %ptr_120 = cute.add_offset(%iter_113, %idx_119) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %144 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i8, rmem> to !llvm.ptr
      %145 = llvm.load %144 : !llvm.ptr -> i8
      %146 = llvm.trunc %145 : i8 to i1
      %iter_121 = cute.recast_iter(%ptr_116) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_122 = cute.recast_iter(%ptr_118) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_122 : !cute.ptr<i128, smem>, %iter_121 : !cute.ptr<i128, gmem>, %146 : i1) {cache_mode = <global>}
      %147 = arith.addi %142, %c1_i32 : i32
      cf.br ^bb15(%147 : i32)
    ^bb17:  // pred: ^bb15
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb13, ^bb17
      nvvm.cp.async.commit.group
      %iter_123 = cute.get_iter(%rmem) : !memref_rmem_i8_
      %iter_124 = cute.get_iter(%rmem_70) : !memref_rmem_i8_
      %coord_125 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
      %idx_126 = cute.crd2idx(%coord_125, %40) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"32">
      %ptr_127 = cute.add_offset(%ptr_48, %idx_126) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_128 = cute.crd2idx(%coord_125, %35) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"4096">
      %ptr_129 = cute.add_offset(%ptr_51, %idx_128) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
      %148 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%149: i32):  // 2 preds: ^bb18, ^bb20
      %150 = arith.cmpi slt, %149, %148 : i32
      cf.cond_br %150, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation}
    ^bb20:  // pred: ^bb19
      %coord_130 = cute.make_coord(%149) : (i32) -> !cute.coord<"(_,?)">
      %idx_131 = cute.crd2idx(%coord_130, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_132 = cute.add_offset(%ptr_127, %idx_131) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_133 = cute.crd2idx(%coord_130, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_134 = cute.add_offset(%ptr_129, %idx_133) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_135 = cute.crd2idx(%coord_130, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_136 = cute.add_offset(%iter_123, %idx_135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %151 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<i8, rmem> to !llvm.ptr
      %152 = llvm.load %151 : !llvm.ptr -> i8
      %153 = llvm.trunc %152 : i8 to i1
      %iter_137 = cute.recast_iter(%ptr_132) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_138 = cute.recast_iter(%ptr_134) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_138 : !cute.ptr<i128, smem>, %iter_137 : !cute.ptr<i128, gmem>, %153 : i1) {cache_mode = <global>}
      %154 = arith.addi %149, %c1_i32 : i32
      cf.br ^bb19(%154 : i32)
    ^bb21:  // pred: ^bb19
      %ptr_139 = cute.add_offset(%ptr_53, %idx_126) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
      %ptr_140 = cute.add_offset(%ptr_54, %idx_128) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb22(%c0_i32 : i32)
    ^bb22(%155: i32):  // 2 preds: ^bb21, ^bb23
      %156 = arith.cmpi slt, %155, %148 : i32
      cf.cond_br %156, ^bb23, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %coord_141 = cute.make_coord(%155) : (i32) -> !cute.coord<"(_,?)">
      %idx_142 = cute.crd2idx(%coord_141, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_143 = cute.add_offset(%ptr_139, %idx_142) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_144 = cute.crd2idx(%coord_141, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_145 = cute.add_offset(%ptr_140, %idx_144) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_146 = cute.crd2idx(%coord_141, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_147 = cute.add_offset(%iter_124, %idx_146) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %157 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i8, rmem> to !llvm.ptr
      %158 = llvm.load %157 : !llvm.ptr -> i8
      %159 = llvm.trunc %158 : i8 to i1
      %iter_148 = cute.recast_iter(%ptr_143) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_149 = cute.recast_iter(%ptr_145) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_149 : !cute.ptr<i128, smem>, %iter_148 : !cute.ptr<i128, gmem>, %159 : i1) {cache_mode = <global>}
      %160 = arith.addi %155, %c1_i32 : i32
      cf.br ^bb22(%160 : i32)
    ^bb24:  // pred: ^bb22
      nvvm.cp.async.commit.group
      %161 = arith.remsi %81, %c32_i32 : i32
      %162 = arith.divsi %81, %c32_i32 : i32
      %163 = arith.remsi %162, %c2_i32 : i32
      %164 = arith.divsi %81, %c64_i32 : i32
      %165 = arith.remsi %164, %c2_i32 : i32
      %166 = arith.remsi %161, %c32_i32 : i32
      %167 = arith.remsi %163, %c2_i32 : i32
      %168 = arith.remsi %165, %c2_i32 : i32
      %169 = arith.divsi %166, %c4_i32 : i32
      %170 = arith.muli %169, %c128_i32 : i32
      %171 = arith.muli %168, %c8_i32 : i32
      %172 = arith.addi %170, %171 : i32
      %173 = arith.remsi %166, %c4_i32 : i32
      %174 = arith.muli %173, %c2_i32 : i32
      %175 = arith.muli %167, %c2048_i32 : i32
      %176 = arith.addi %174, %175 : i32
      %177 = arith.andi %172, %c256_i32 : i32
      %178 = arith.cmpi eq, %177, %c0_i32 : i32
      %179 = arith.select %178, %c16_i32, %c-16_i32 : i32
      %180 = arith.andi %172, %c512_i32 : i32
      %181 = arith.cmpi eq, %180, %c0_i32 : i32
      %182 = arith.select %181, %c32_i32, %c-32_i32 : i32
      %183 = arith.andi %172, %c896_i32 : i32
      %184 = arith.shrsi %183, %c4_i32 : i32
      %185 = arith.xori %172, %184 : i32
      %186 = arith.addi %185, %176 : i32
      %iv_150 = cute.assume(%186) : (i32) -> !cute.i32<divby 2>
      %int_tuple_151 = cute.make_int_tuple(%iv_150) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_152 = cute.add_offset(%iter_44, %int_tuple_151) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, smem, align<4>>
      %iv_153 = cute.assume(%179) : (i32) -> !cute.i32<divby 16>
      %iv_154 = cute.assume(%182) : (i32) -> !cute.i32<divby 32>
      %stride = cute.make_stride(%iv_153, %iv_154) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,1024),4096,(?{div=16},?{div=32},64))">
      %lay = cute.make_layout(%31, %stride) : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
      %rmem_155 = cute.memref.alloca() : !memref_rmem_f16_
      %rmem_156 = cute.memref.alloca() : !memref_rmem_f16_1
      %rmem_157 = cute.memref.alloca() : !memref_rmem_f32_
      cute.memref.store_vec %cst, %rmem_157 : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %187 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %188 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %189 = arith.divsi %101, %c2_i32 : i32
      %190 = arith.remsi %189, %c4_i32 : i32
      %191 = arith.muli %190, %c64_i32 : i32
      %192 = arith.remsi %100, %c2_i32 : i32
      %193 = arith.muli %192, %c8_i32 : i32
      %194 = arith.addi %191, %193 : i32
      %195 = arith.remsi %101, %c2_i32 : i32
      %196 = arith.muli %195, %c32_i32 : i32
      %197 = arith.divsi %189, %c4_i32 : i32
      %198 = arith.muli %197, %c256_i32 : i32
      %199 = arith.addi %196, %198 : i32
      %200 = arith.divsi %100, %c2_i32 : i32
      %201 = arith.remsi %200, %c2_i32 : i32
      %202 = arith.muli %201, %c512_i32 : i32
      %203 = arith.addi %199, %202 : i32
      %204 = arith.andi %194, %c128_i32 : i32
      %205 = arith.cmpi eq, %204, %c0_i32 : i32
      %206 = arith.select %205, %c16_i32, %c-16_i32 : i32
      %207 = arith.andi %194, %c192_i32 : i32
      %208 = arith.shrsi %207, %c3_i32 : i32
      %209 = arith.xori %194, %208 : i32
      %210 = arith.addi %209, %203 : i32
      %iv_158 = cute.assume(%210) : (i32) -> !cute.i32<divby 8>
      %int_tuple_159 = cute.make_int_tuple(%iv_158) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_160 = cute.add_offset(%iter_42, %int_tuple_159) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %iv_161 = cute.assume(%206) : (i32) -> !cute.i32<divby 16>
      %stride_162 = cute.make_stride(%iv_161) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
      %lay_163 = cute.make_layout(%30, %stride_162) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iter_164 = cute.get_iter(%rmem_155) : !memref_rmem_f16_
      %211 = arith.divsi %81, %c8_i32 : i32
      %212 = arith.remsi %81, %c8_i32 : i32
      %213 = arith.divsi %212, %c2_i32 : i32
      %214 = arith.muli %213, %c64_i32 : i32
      %215 = arith.remsi %211, %c2_i32 : i32
      %216 = arith.muli %215, %c8_i32 : i32
      %217 = arith.addi %214, %216 : i32
      %218 = arith.remsi %212, %c2_i32 : i32
      %219 = arith.muli %218, %c32_i32 : i32
      %220 = arith.divsi %211, %c2_i32 : i32
      %221 = arith.divsi %220, %c2_i32 : i32
      %222 = arith.remsi %220, %c2_i32 : i32
      %223 = arith.muli %222, %c512_i32 : i32
      %224 = arith.addi %219, %223 : i32
      %225 = arith.divsi %221, %c2_i32 : i32
      %226 = arith.muli %225, %c256_i32 : i32
      %227 = arith.addi %224, %226 : i32
      %228 = arith.andi %217, %c128_i32 : i32
      %229 = arith.cmpi eq, %228, %c0_i32 : i32
      %230 = arith.select %229, %c16_i32, %c-16_i32 : i32
      %231 = arith.andi %217, %c192_i32 : i32
      %232 = arith.shrsi %231, %c3_i32 : i32
      %233 = arith.xori %217, %232 : i32
      %234 = arith.addi %233, %227 : i32
      %iv_165 = cute.assume(%234) : (i32) -> !cute.i32<divby 8>
      %int_tuple_166 = cute.make_int_tuple(%iv_165) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_167 = cute.add_offset(%iter_43, %int_tuple_166) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %iv_168 = cute.assume(%230) : (i32) -> !cute.i32<divby 16>
      %stride_169 = cute.make_stride(%iv_168) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
      %lay_170 = cute.make_layout(%30, %stride_169) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iter_171 = cute.get_iter(%rmem_156) : !memref_rmem_f16_1
      %235 = cute.get_scalars(%lay_163) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iv_172 = cute.assume(%235) : (i32) -> !cute.i32<divby 16>
      %stride_173 = cute.make_stride(%iv_172) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
      %lay_174 = cute.make_layout(%29, %stride_173) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
      %view_175 = cute.make_view(%ptr_160, %lay_174) : !memref_smem_f16_1
      %236 = builtin.unrealized_conversion_cast %view_175 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      %237 = cute.get_scalars(%lay_170) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iv_176 = cute.assume(%237) : (i32) -> !cute.i32<divby 16>
      %stride_177 = cute.make_stride(%iv_176) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
      %lay_178 = cute.make_layout(%29, %stride_177) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
      %view_179 = cute.make_view(%ptr_167, %lay_178) : !memref_smem_f16_1
      %238 = builtin.unrealized_conversion_cast %view_179 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%239: i32):  // 2 preds: ^bb24, ^bb26
      %240 = arith.cmpi slt, %239, %148 : i32
      cf.cond_br %240, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %coord_180 = cute.make_coord(%239) : (i32) -> !cute.coord<"(_,?)">
      %idx_181 = cute.crd2idx(%coord_180, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_182 = cute.add_offset(%ptr_160, %idx_181) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_183 = cute.crd2idx(%coord_180, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_184 = cute.add_offset(%iter_164, %idx_183) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %241 = cute_nvgpu.arch.copy.ldsm %ptr_182{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %242 = vector.extractelement %241[%27 : i32] : vector<4xi32>
      %243 = builtin.unrealized_conversion_cast %ptr_184 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %242, %243 : i32, !llvm.ptr
      %244 = vector.extractelement %241[%26 : i32] : vector<4xi32>
      %ptr_185 = cute.add_offset(%ptr_184, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %245 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %244, %245 : i32, !llvm.ptr
      %246 = vector.extractelement %241[%24 : i32] : vector<4xi32>
      %ptr_186 = cute.add_offset(%ptr_184, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %247 = builtin.unrealized_conversion_cast %ptr_186 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %246, %247 : i32, !llvm.ptr
      %248 = vector.extractelement %241[%23 : i32] : vector<4xi32>
      %ptr_187 = cute.add_offset(%ptr_184, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %249 = builtin.unrealized_conversion_cast %ptr_187 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %248, %249 : i32, !llvm.ptr
      %250 = arith.addi %239, %c1_i32 : i32
      cf.br ^bb25(%250 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%c0_i32 : i32)
    ^bb28(%251: i32):  // 2 preds: ^bb27, ^bb29
      %252 = arith.cmpi slt, %251, %148 : i32
      cf.cond_br %252, ^bb29, ^bb30 {llvm.loop_annotation = #loop_annotation}
    ^bb29:  // pred: ^bb28
      %coord_188 = cute.make_coord(%251) : (i32) -> !cute.coord<"(_,?)">
      %idx_189 = cute.crd2idx(%coord_188, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_190 = cute.add_offset(%ptr_167, %idx_189) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_191 = cute.crd2idx(%coord_188, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_192 = cute.add_offset(%iter_171, %idx_191) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %253 = cute_nvgpu.arch.copy.ldsm %ptr_190{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %254 = vector.extractelement %253[%27 : i32] : vector<4xi32>
      %255 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %254, %255 : i32, !llvm.ptr
      %256 = vector.extractelement %253[%26 : i32] : vector<4xi32>
      %ptr_193 = cute.add_offset(%ptr_192, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %257 = builtin.unrealized_conversion_cast %ptr_193 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %256, %257 : i32, !llvm.ptr
      %258 = vector.extractelement %253[%24 : i32] : vector<4xi32>
      %ptr_194 = cute.add_offset(%ptr_192, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %259 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %258, %259 : i32, !llvm.ptr
      %260 = vector.extractelement %253[%23 : i32] : vector<4xi32>
      %ptr_195 = cute.add_offset(%ptr_192, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %261 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %260, %261 : i32, !llvm.ptr
      %262 = arith.addi %251, %c1_i32 : i32
      cf.br ^bb28(%262 : i32)
    ^bb30:  // pred: ^bb28
      %iter_196 = cute.get_iter(%rmem_157) : !memref_rmem_f32_
      %263 = cute.get_scalars(%15) : !cute.int_tuple<"1">
      %264 = cute.get_scalars(%14) : !cute.int_tuple<"8">
      cf.br ^bb31(%c0_i32, %236, %238, %c2_i32, %c2_i32, %c0_i32 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb31(%265: i32, %266: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %267: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %268: i32, %269: i32, %270: i32):  // 2 preds: ^bb30, ^bb70
      %271 = arith.cmpi slt, %265, %c4_i32 : i32
      cf.cond_br %271, ^bb32, ^bb71
    ^bb32:  // pred: ^bb31
      cf.br ^bb33(%c0_i32, %266, %267, %268, %269, %270 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb33(%272: i32, %273: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %274: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %275: i32, %276: i32, %277: i32):  // 2 preds: ^bb32, ^bb69
      %278 = arith.cmpi slt, %272, %c2_i32 : i32
      cf.cond_br %278, ^bb34, ^bb70 {loop_annotation = #loop_annotation1}
    ^bb34:  // pred: ^bb33
      %279 = arith.cmpi eq, %272, %c1_i32 : i32
      cf.cond_br %279, ^bb35, ^bb36
    ^bb35:  // pred: ^bb34
      %coord_197 = cute.make_coord(%277) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_198 = cute.crd2idx(%coord_197, %lay_163) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_199 = cute.add_offset(%ptr_160, %idx_198) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      %view_200 = cute.make_view(%ptr_199, %lay_174) : !memref_smem_f16_1
      %280 = builtin.unrealized_conversion_cast %view_200 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      %idx_201 = cute.crd2idx(%coord_197, %lay_170) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_202 = cute.add_offset(%ptr_167, %idx_201) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      %view_203 = cute.make_view(%ptr_202, %lay_178) : !memref_smem_f16_1
      %281 = builtin.unrealized_conversion_cast %view_203 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier
      cf.br ^bb37(%280, %281 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>)
    ^bb36:  // pred: ^bb34
      cf.br ^bb37(%273, %274 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>)
    ^bb37(%282: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %283: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>):  // 2 preds: ^bb35, ^bb36
      cf.br ^bb38
    ^bb38:  // pred: ^bb37
      %284 = builtin.unrealized_conversion_cast %283 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)> to !memref_smem_f16_1
      %285 = builtin.unrealized_conversion_cast %282 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)> to !memref_smem_f16_1
      %286 = arith.addi %272, %c1_i32 : i32
      %287 = arith.remsi %286, %c2_i32 : i32
      %coord_204 = cute.make_coord(%287) : (i32) -> !cute.coord<"(_,_,?)">
      %lay_205 = cute.get_layout(%285) : !memref_smem_f16_1
      %idx_206 = cute.crd2idx(%coord_204, %lay_205) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
      %iter_207 = cute.get_iter(%285) : !memref_smem_f16_1
      %ptr_208 = cute.add_offset(%iter_207, %idx_206) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_209 = cute.crd2idx(%coord_204, %21) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),8,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_210 = cute.add_offset(%iter_164, %idx_209) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
      cf.br ^bb39(%c0_i32 : i32)
    ^bb39(%288: i32):  // 2 preds: ^bb38, ^bb40
      %289 = arith.cmpi slt, %288, %148 : i32
      cf.cond_br %289, ^bb40, ^bb41 {llvm.loop_annotation = #loop_annotation}
    ^bb40:  // pred: ^bb39
      %coord_211 = cute.make_coord(%288) : (i32) -> !cute.coord<"(_,?)">
      %idx_212 = cute.crd2idx(%coord_211, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_213 = cute.add_offset(%ptr_208, %idx_212) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_214 = cute.crd2idx(%coord_211, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_215 = cute.add_offset(%ptr_210, %idx_214) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %290 = cute_nvgpu.arch.copy.ldsm %ptr_213{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %291 = vector.extractelement %290[%27 : i32] : vector<4xi32>
      %292 = builtin.unrealized_conversion_cast %ptr_215 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %291, %292 : i32, !llvm.ptr
      %293 = vector.extractelement %290[%26 : i32] : vector<4xi32>
      %ptr_216 = cute.add_offset(%ptr_215, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %294 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %293, %294 : i32, !llvm.ptr
      %295 = vector.extractelement %290[%24 : i32] : vector<4xi32>
      %ptr_217 = cute.add_offset(%ptr_215, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %296 = builtin.unrealized_conversion_cast %ptr_217 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %295, %296 : i32, !llvm.ptr
      %297 = vector.extractelement %290[%23 : i32] : vector<4xi32>
      %ptr_218 = cute.add_offset(%ptr_215, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %298 = builtin.unrealized_conversion_cast %ptr_218 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %297, %298 : i32, !llvm.ptr
      %299 = arith.addi %288, %c1_i32 : i32
      cf.br ^bb39(%299 : i32)
    ^bb41:  // pred: ^bb39
      %lay_219 = cute.get_layout(%284) : !memref_smem_f16_1
      %idx_220 = cute.crd2idx(%coord_204, %lay_219) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
      %iter_221 = cute.get_iter(%284) : !memref_smem_f16_1
      %ptr_222 = cute.add_offset(%iter_221, %idx_220) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
      %ptr_223 = cute.add_offset(%iter_171, %idx_209) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%300: i32):  // 2 preds: ^bb41, ^bb43
      %301 = arith.cmpi slt, %300, %148 : i32
      cf.cond_br %301, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %coord_224 = cute.make_coord(%300) : (i32) -> !cute.coord<"(_,?)">
      %idx_225 = cute.crd2idx(%coord_224, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_226 = cute.add_offset(%ptr_222, %idx_225) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_227 = cute.crd2idx(%coord_224, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_228 = cute.add_offset(%ptr_223, %idx_227) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %302 = cute_nvgpu.arch.copy.ldsm %ptr_226{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %303 = vector.extractelement %302[%27 : i32] : vector<4xi32>
      %304 = builtin.unrealized_conversion_cast %ptr_228 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %303, %304 : i32, !llvm.ptr
      %305 = vector.extractelement %302[%26 : i32] : vector<4xi32>
      %ptr_229 = cute.add_offset(%ptr_228, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %306 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %305, %306 : i32, !llvm.ptr
      %307 = vector.extractelement %302[%24 : i32] : vector<4xi32>
      %ptr_230 = cute.add_offset(%ptr_228, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %308 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %307, %308 : i32, !llvm.ptr
      %309 = vector.extractelement %302[%23 : i32] : vector<4xi32>
      %ptr_231 = cute.add_offset(%ptr_228, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %310 = builtin.unrealized_conversion_cast %ptr_231 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %309, %310 : i32, !llvm.ptr
      %311 = arith.addi %300, %c1_i32 : i32
      cf.br ^bb42(%311 : i32)
    ^bb44:  // pred: ^bb42
      %312 = arith.cmpi eq, %272, %c0_i32 : i32
      cf.cond_br %312, ^bb45, ^bb51
    ^bb45:  // pred: ^bb44
      %313 = arith.addi %265, %c2_i32 : i32
      %314 = arith.cmpi slt, %313, %c4_i32 : i32
      cf.cond_br %314, ^bb46, ^bb50
    ^bb46:  // pred: ^bb45
      %coord_232 = cute.make_coord(%275) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_233 = cute.crd2idx(%coord_232, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_234 = cute.add_offset(%ptr_48, %idx_233) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
      %coord_235 = cute.make_coord(%276) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_236 = cute.crd2idx(%coord_235, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_237 = cute.add_offset(%ptr_51, %idx_236) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb47(%c0_i32 : i32)
    ^bb47(%315: i32):  // 2 preds: ^bb46, ^bb48
      %316 = arith.cmpi slt, %315, %148 : i32
      cf.cond_br %316, ^bb48, ^bb49 {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %coord_238 = cute.make_coord(%315) : (i32) -> !cute.coord<"(_,?)">
      %idx_239 = cute.crd2idx(%coord_238, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_240 = cute.add_offset(%ptr_234, %idx_239) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_241 = cute.crd2idx(%coord_238, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_242 = cute.add_offset(%ptr_237, %idx_241) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_243 = cute.crd2idx(%coord_238, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_244 = cute.add_offset(%iter_123, %idx_243) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %317 = builtin.unrealized_conversion_cast %ptr_244 : !cute.ptr<i8, rmem> to !llvm.ptr
      %318 = llvm.load %317 : !llvm.ptr -> i8
      %319 = llvm.trunc %318 : i8 to i1
      %iter_245 = cute.recast_iter(%ptr_240) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_246 = cute.recast_iter(%ptr_242) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_246 : !cute.ptr<i128, smem>, %iter_245 : !cute.ptr<i128, gmem>, %319 : i1) {cache_mode = <global>}
      %320 = arith.addi %315, %c1_i32 : i32
      cf.br ^bb47(%320 : i32)
    ^bb49:  // pred: ^bb47
      cf.br ^bb50
    ^bb50:  // 2 preds: ^bb45, ^bb49
      cf.br ^bb51
    ^bb51:  // 2 preds: ^bb44, ^bb50
      %coord_247 = cute.make_coord(%272) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_248 = cute.crd2idx(%coord_247, %20) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2,2),4,2):((1,2,4),8,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_249 = cute.add_offset(%iter_164, %idx_248) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_250 = cute.crd2idx(%coord_247, %19) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2),8,2):((1,2),4,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_251 = cute.add_offset(%iter_171, %idx_250) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
      cf.br ^bb52(%c0_i32 : i32)
    ^bb52(%321: i32):  // 2 preds: ^bb51, ^bb59
      %322 = arith.cmpi slt, %321, %263 : i32
      cf.cond_br %322, ^bb53, ^bb60 {llvm.loop_annotation = #loop_annotation}
    ^bb53:  // pred: ^bb52
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%323: i32):  // 2 preds: ^bb53, ^bb58
      %324 = arith.cmpi slt, %323, %148 : i32
      cf.cond_br %324, ^bb55, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %coord_252 = cute.make_coord(%323, %321) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_253 = cute.crd2idx(%coord_252, %17) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),4,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_254 = cute.add_offset(%ptr_249, %idx_253) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %325 = builtin.unrealized_conversion_cast %ptr_254 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %326 = llvm.getelementptr %325[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %327 = llvm.getelementptr %325[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %328 = llvm.getelementptr %325[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%329: i32):  // 2 preds: ^bb55, ^bb57
      %330 = arith.cmpi slt, %329, %264 : i32
      cf.cond_br %330, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      %coord_255 = cute.make_coord(%329, %321) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_256 = cute.make_coord(%323, %329) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_257 = cute.crd2idx(%coord_255, %16) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_258 = cute.add_offset(%ptr_251, %idx_257) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_259 = cute.crd2idx(%coord_256, %18) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,8):((1,2),4,16)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_260 = cute.add_offset(%iter_196, %idx_259) : (!cute.ptr<f32, rmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %331 = llvm.load %325 : !llvm.ptr -> vector<2xf16>
      %332 = llvm.load %326 : !llvm.ptr -> vector<2xf16>
      %333 = llvm.load %327 : !llvm.ptr -> vector<2xf16>
      %334 = llvm.load %328 : !llvm.ptr -> vector<2xf16>
      %335 = builtin.unrealized_conversion_cast %ptr_258 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %336 = llvm.load %335 : !llvm.ptr -> vector<2xf16>
      %337 = llvm.getelementptr %335[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %338 = llvm.load %337 : !llvm.ptr -> vector<2xf16>
      %339 = builtin.unrealized_conversion_cast %ptr_260 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %340 = llvm.load %339 : !llvm.ptr -> f32
      %341 = llvm.getelementptr %339[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %342 = llvm.load %341 : !llvm.ptr -> f32
      %343 = llvm.getelementptr %339[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %344 = llvm.load %343 : !llvm.ptr -> f32
      %345 = llvm.getelementptr %339[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %346 = llvm.load %345 : !llvm.ptr -> f32
      %347:4 = cute_nvgpu.arch.mma.SM80 A[%331, %332, %333, %334]  B[%336, %338]  C[%340, %342, %344, %346] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %347#0, %339 : f32, !llvm.ptr
      llvm.store %347#1, %341 : f32, !llvm.ptr
      llvm.store %347#2, %343 : f32, !llvm.ptr
      llvm.store %347#3, %345 : f32, !llvm.ptr
      %348 = arith.addi %329, %c1_i32 : i32
      cf.br ^bb56(%348 : i32)
    ^bb58:  // pred: ^bb56
      %349 = arith.addi %323, %c1_i32 : i32
      cf.br ^bb54(%349 : i32)
    ^bb59:  // pred: ^bb54
      %350 = arith.addi %321, %c1_i32 : i32
      cf.br ^bb52(%350 : i32)
    ^bb60:  // pred: ^bb52
      %351 = arith.select %312, %277, %276 : i32
      cf.cond_br %312, ^bb61, ^bb67
    ^bb61:  // pred: ^bb60
      %352 = arith.addi %265, %c2_i32 : i32
      %353 = arith.cmpi slt, %352, %c4_i32 : i32
      cf.cond_br %353, ^bb62, ^bb66
    ^bb62:  // pred: ^bb61
      %coord_261 = cute.make_coord(%275) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_262 = cute.crd2idx(%coord_261, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_263 = cute.add_offset(%ptr_53, %idx_262) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
      %coord_264 = cute.make_coord(%276) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_265 = cute.crd2idx(%coord_264, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_266 = cute.add_offset(%ptr_54, %idx_265) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb63(%c0_i32 : i32)
    ^bb63(%354: i32):  // 2 preds: ^bb62, ^bb64
      %355 = arith.cmpi slt, %354, %148 : i32
      cf.cond_br %355, ^bb64, ^bb65 {llvm.loop_annotation = #loop_annotation}
    ^bb64:  // pred: ^bb63
      %coord_267 = cute.make_coord(%354) : (i32) -> !cute.coord<"(_,?)">
      %idx_268 = cute.crd2idx(%coord_267, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_269 = cute.add_offset(%ptr_263, %idx_268) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_270 = cute.crd2idx(%coord_267, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_271 = cute.add_offset(%ptr_266, %idx_270) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_272 = cute.crd2idx(%coord_267, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_273 = cute.add_offset(%iter_124, %idx_272) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %356 = builtin.unrealized_conversion_cast %ptr_273 : !cute.ptr<i8, rmem> to !llvm.ptr
      %357 = llvm.load %356 : !llvm.ptr -> i8
      %358 = llvm.trunc %357 : i8 to i1
      %iter_274 = cute.recast_iter(%ptr_269) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_275 = cute.recast_iter(%ptr_271) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_275 : !cute.ptr<i128, smem>, %iter_274 : !cute.ptr<i128, gmem>, %358 : i1) {cache_mode = <global>}
      %359 = arith.addi %354, %c1_i32 : i32
      cf.br ^bb63(%359 : i32)
    ^bb65:  // pred: ^bb63
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb61, ^bb65
      %360 = arith.addi %275, %c1_i32 : i32
      nvvm.cp.async.commit.group
      %361 = arith.addi %277, %c1_i32 : i32
      %362 = arith.cmpi eq, %361, %c3_i32 : i32
      %363 = arith.select %362, %c0_i32, %361 : i32
      cf.br ^bb68(%360, %363 : i32, i32)
    ^bb67:  // pred: ^bb60
      cf.br ^bb68(%275, %277 : i32, i32)
    ^bb68(%364: i32, %365: i32):  // 2 preds: ^bb66, ^bb67
      cf.br ^bb69
    ^bb69:  // pred: ^bb68
      %366 = arith.addi %272, %c1_i32 : i32
      cf.br ^bb33(%366, %282, %283, %364, %351, %365 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb70:  // pred: ^bb33
      %367 = arith.addi %265, %c1_i32 : i32
      cf.br ^bb31(%367, %273, %274, %275, %276, %277 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb71:  // pred: ^bb31
      nvvm.cp.async.wait.group 0
      nvvm.barrier
      %rmem_276 = cute.memref.alloca() : !memref_rmem_f16_2
      %368 = cute.memref.load_vec %rmem_157 : !memref_rmem_f32_
      %369 = arith.truncf %368 : vector<128xf32> to vector<128xf16>
      %iter_277 = cute.get_iter(%rmem_276) : !memref_rmem_f16_2
      %view_278 = cute.make_view(%iter_277) : !memref_rmem_f16_2
      cute.memref.store_vec %369, %view_278 : !memref_rmem_f16_2
      %370:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
      %iv_279 = cute.assume(%370#0) : (i32) -> !cute.i32<divby 16>
      %iv_280 = cute.assume(%370#1) : (i32) -> !cute.i32<divby 32>
      %stride_281 = cute.make_stride(%iv_279, %iv_280) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
      %lay_282 = cute.make_layout(%13, %stride_281) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %371:2 = cute.get_scalars(%lay_282) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %iv_283 = cute.assume(%371#0) : (i32) -> !cute.i32<divby 16>
      %iv_284 = cute.assume(%371#1) : (i32) -> !cute.i32<divby 32>
      %stride_285 = cute.make_stride(%iv_283, %iv_284) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
      %lay_286 = cute.make_layout(%13, %stride_285) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %append = cute.append_to_rank<2> (%lay_286, %57) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">, !cute.layout<"1:0">
      %372:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %iv_287 = cute.assume(%372#0) : (i32) -> !cute.i32<divby 16>
      %iv_288 = cute.assume(%372#1) : (i32) -> !cute.i32<divby 32>
      %stride_289 = cute.make_stride(%iv_287, %iv_288) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,((1024,4096,?{div=16},?{div=32},64)))">
      %lay_290 = cute.make_layout(%11, %stride_289) : !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">
      %373 = cute.get_scalars(%10) : !cute.int_tuple<"64">
      cf.br ^bb72(%c0_i32 : i32)
    ^bb72(%374: i32):  // 2 preds: ^bb71, ^bb73
      %375 = arith.cmpi slt, %374, %373 : i32
      cf.cond_br %375, ^bb73, ^bb74 {llvm.loop_annotation = #loop_annotation}
    ^bb73:  // pred: ^bb72
      %coord_291 = cute.make_coord(%374) : (i32) -> !cute.coord<"(_,?)">
      %idx_292 = cute.crd2idx(%coord_291, %12) : (!cute.coord<"(_,?)">, !cute.layout<"(2,(64)):(1,(2))">) -> !cute.int_tuple<"?{div=2}">
      %ptr_293 = cute.add_offset(%iter_277, %idx_292) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, rmem, align<4>>
      %idx_294 = cute.crd2idx(%coord_291, %lay_290) : (!cute.coord<"(_,?)">, !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_295 = cute.add_offset(%ptr_152, %idx_294) : (!cute.ptr<f16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<4>>
      %376 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      %377 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<f16, smem, align<4>> to !llvm.ptr<3>
      %378 = llvm.load %376 {alignment = 4 : i64} : !llvm.ptr -> vector<2xf16>
      llvm.store %378, %377 {alignment = 4 : i64} : vector<2xf16>, !llvm.ptr<3>
      %379 = arith.addi %374, %c1_i32 : i32
      cf.br ^bb72(%379 : i32)
    ^bb74:  // pred: ^bb72
      %idx_296 = cute.crd2idx(%coord, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,1):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
      %tup_297 = cute.add_offset(%48, %idx_296) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
      %idx_298 = cute.crd2idx(%coord_14, %8) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((1@0,1@1),(128@0,128@1))">) -> !cute.int_tuple<"(?{div=128},?{div=128})">
      %tup_299 = cute.add_offset(%tup_297, %idx_298) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},?{div=128})">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %iv_300 = cute.assume(%112) : (i32) -> !cute.i32<divby 8>
      %int_tuple_301 = cute.make_int_tuple(%100, %iv_300) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_302 = cute.add_offset(%tup_299, %int_tuple_301) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %rmem_303 = cute.memref.alloca() : !memref_rmem_f16_3
      nvvm.barrier
      %iter_304 = cute.get_iter(%rmem_303) : !memref_rmem_f16_3
      %380 = cute.get_scalars(%5) : !cute.int_tuple<"16">
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%381: i32):  // 2 preds: ^bb74, ^bb76
      %382 = arith.cmpi slt, %381, %380 : i32
      cf.cond_br %382, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      %coord_305 = cute.make_coord(%381) : (i32) -> !cute.coord<"(_,?)">
      %idx_306 = cute.crd2idx(%coord_305, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(1024))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_307 = cute.add_offset(%ptr_58, %idx_306) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_308 = cute.crd2idx(%coord_305, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_309 = cute.add_offset(%iter_304, %idx_308) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %383 = builtin.unrealized_conversion_cast %ptr_307 : !cute.ptr<f16, smem, align<16>> to !llvm.ptr<3>
      %384 = builtin.unrealized_conversion_cast %ptr_309 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %385 = llvm.load %383 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xf16>
      llvm.store %385, %384 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr
      %386 = arith.addi %381, %c1_i32 : i32
      cf.br ^bb75(%386 : i32)
    ^bb77:  // pred: ^bb75
      %rmem_310 = cute.memref.alloca() : !memref_rmem_i8_1
      %387 = cute.get_scalars(%42) : !cute.coord<"512">
      cf.br ^bb78(%c0_i32 : i32)
    ^bb78(%388: i32):  // 2 preds: ^bb77, ^bb79
      %389 = arith.cmpi slt, %388, %c16_i32 : i32
      cf.cond_br %389, ^bb79, ^bb80
    ^bb79:  // pred: ^bb78
      %coord_311 = cute.make_coord(%388) : (i32) -> !cute.coord<"((0,0),?,0)">
      %idx_312 = cute.crd2idx(%coord_311, %4) : (!cute.coord<"((0,0),?,0)">, !cute.layout<"((8,1),16,1):((1@1,0),8@0,0)">) -> !cute.int_tuple<"(?{div=8},0)">
      %tup_313 = cute.add_offset(%tup_302, %idx_312) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(?{div=8},0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %e0_314, %e1_315, %e2_316 = cute.get_leaves(%tup_313) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_317 = cute.make_coord(%e0_314) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %390 = cute.get_scalars(%coord_317) : !cute.coord<"?">
      %391 = arith.cmpi slt, %390, %387 : i32
      %392 = arith.extui %391 : i1 to i8
      %coord_318 = cute.make_coord(%388) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_319 = cute.derefine(%coord_318) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem_310, %dyn_319, %392) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
      %393 = arith.addi %388, %c1_i32 : i32
      cf.br ^bb78(%393 : i32)
    ^bb80:  // pred: ^bb78
      %e0_320, %e1_321, %e2_322 = cute.get_leaves(%tup_302) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_323 = cute.make_coord(%e1_321) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %394 = cute.get_scalars(%coord_323) : !cute.coord<"?{div=8}">
      %395 = cute.get_scalars(%41) : !cute.coord<"256">
      %396 = arith.cmpi slt, %394, %395 : i32
      cf.cond_br %396, ^bb81, ^bb87
    ^bb81:  // pred: ^bb80
      %iter_324 = cute.get_iter(%rmem_310) : !memref_rmem_i8_1
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%397: i32):  // 2 preds: ^bb81, ^bb85
      %398 = arith.cmpi slt, %397, %380 : i32
      cf.cond_br %398, ^bb83, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      %coord_325 = cute.make_coord(%397) : (i32) -> !cute.coord<"(_,?)">
      %idx_326 = cute.crd2idx(%coord_325, %3) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_327 = cute.add_offset(%iter_304, %idx_326) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_328 = cute.crd2idx(%coord_325, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((2048)))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_329 = cute.add_offset(%ptr_61, %idx_328) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_330 = cute.crd2idx(%coord_325, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((16))):(16,((1)))">) -> !cute.int_tuple<"?">
      %ptr_331 = cute.add_offset(%iter_324, %idx_330) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %399 = builtin.unrealized_conversion_cast %ptr_331 : !cute.ptr<i8, rmem> to !llvm.ptr
      %400 = llvm.load %399 : !llvm.ptr -> i8
      %401 = llvm.icmp "ne" %400, %0 : i8
      cf.cond_br %401, ^bb84, ^bb85
    ^bb84:  // pred: ^bb83
      %402 = builtin.unrealized_conversion_cast %ptr_327 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %403 = builtin.unrealized_conversion_cast %ptr_329 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
      %404 = llvm.load %402 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %404, %403 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      cf.br ^bb85
    ^bb85:  // 2 preds: ^bb83, ^bb84
      %405 = arith.addi %397, %c1_i32 : i32
      cf.br ^bb82(%405 : i32)
    ^bb86:  // pred: ^bb82
      cf.br ^bb87
    ^bb87:  // 2 preds: ^bb80, ^bb86
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb1, ^bb87
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
    %8 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_amperetensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o51225616256113_0<%7> (%view, %view_0, %view_1, %c2_i32) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f16_, !memref_gmem_f16_1, !memref_gmem_f16_2, i32) -> !cuda.result
    %9 = cuda.cast %8 : !cuda.result -> i32
    cuda.return_if_error %9 : i32
    return %c0_i32 : i32
  }
}
