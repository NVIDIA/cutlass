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
    func.func public @kernel_cutlass_kernel_tensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o512256162561131072_S_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_1, %arg2: !memref_gmem_f16_2, %arg3: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %62 = arith.divsi %59, %arg3 : i32
      %63 = arith.muli %62, %arg3 : i32
      %64 = arith.cmpi ne, %59, %63 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %65 = arith.cmpi slt, %59, %c0_i32_1 : i32
      %66 = arith.cmpi slt, %arg3, %c0_i32_1 : i32
      %67 = arith.cmpi ne, %65, %66 : i1
      %68 = arith.andi %64, %67 : i1
      %c-1_i32 = arith.constant -1 : i32
      %69 = arith.addi %62, %c-1_i32 : i32
      %70 = arith.select %68, %69, %62 : i32
      %71 = arith.remsi %59, %arg3 : i32
      %72 = arith.muli %60, %arg3 : i32
      %73 = arith.addi %71, %72 : i32
      %74 = arith.cmpi sge, %70, %c4_i32 : i32
      %75 = arith.cmpi sge, %73, %c2_i32 : i32
      %76 = arith.extui %74 : i1 to i32
      %77 = arith.extui %75 : i1 to i32
      %78 = arith.select %74, %76, %77 : i32
      %79 = arith.cmpi ne, %78, %c0_i32 : i32
      cf.cond_br %79, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cf.br ^bb88
    ^bb2:  // pred: ^bb0
      %coord = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
      %idx = cute.crd2idx(%coord, %56) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,128,16):(128,1,65536)">) -> !cute.int_tuple<"?{div=65536}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=65536}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_2 = cute.make_coord(%70, %73) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %80:2 = cute.get_scalars(%coord_2) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_3 = cute.make_coord(%80#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %idx_4 = cute.crd2idx(%coord_3, %55) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(4,4)):((128,1),(16384,32))">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_5 = cute.add_offset(%ptr, %idx_4) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, gmem, align<32>>
      %idx_6 = cute.crd2idx(%coord, %54) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(128,1,32768)">) -> !cute.int_tuple<"?{div=32768}">
      %iter_7 = cute.get_iter(%arg1) : !memref_gmem_f16_1
      %ptr_8 = cute.add_offset(%iter_7, %idx_6) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=32768}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_9 = cute.make_coord(%80#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %idx_10 = cute.crd2idx(%coord_9, %53) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((128,1),(16384,32))">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_11 = cute.add_offset(%ptr_8, %idx_10) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, gmem, align<32>>
      %idx_12 = cute.crd2idx(%coord, %52) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,16):(256,1,131072)">) -> !cute.int_tuple<"?{div=131072}">
      %iter_13 = cute.get_iter(%arg2) : !memref_gmem_f16_2
      %ptr_14 = cute.add_offset(%iter_13, %idx_12) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=131072}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_15 = cute.make_coord(%80#0, %80#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %idx_16 = cute.crd2idx(%coord_15, %51) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((256,1),(32768,128))">) -> !cute.int_tuple<"?{div=128}">
      %ptr_17 = cute.add_offset(%ptr_14, %idx_16) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f16, gmem, align<32>>
      %view = cute.make_view(%ptr_5, %50) : !memref_gmem_f16_3
      %dyn = cute.derefine(%view) : !memref_gmem_f16_3 to !memref_gmem_f16_4
      %iter_18 = cute.get_iter(%dyn) : !memref_gmem_f16_4
      %view_19 = cute.make_view(%ptr_11, %50) : !memref_gmem_f16_3
      %dyn_20 = cute.derefine(%view_19) : !memref_gmem_f16_3 to !memref_gmem_f16_4
      %iter_21 = cute.get_iter(%dyn_20) : !memref_gmem_f16_4
      %81 = cute.ptrtoint(%iter_18) : !cute.ptr<f16, gmem> to i64
      %82 = arith.addi %81, %c15_i64 : i64
      %83 = arith.andi %82, %c-16_i64 : i64
      %iv = cute.assume(%83) : (i64) -> !cute.i64<divby 16>
      %84 = cute.inttoptr(%iv) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %85 = cute.ptrtoint(%iter_21) : !cute.ptr<f16, gmem> to i64
      %86 = arith.addi %85, %c15_i64 : i64
      %87 = arith.andi %86, %c-16_i64 : i64
      %iv_22 = cute.assume(%87) : (i64) -> !cute.i64<divby 16>
      %88 = cute.inttoptr(%iv_22) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %idx_23 = cute.crd2idx(%coord, %49) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
      %tup = cute.add_offset(%48, %idx_23) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
      %idx_24 = cute.crd2idx(%coord_3, %47) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(4,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %tup_25 = cute.add_offset(%tup, %idx_24) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_25) : !cute.int_tuple<"(?{div=128},0,?)">
      %idx_26 = cute.crd2idx(%coord, %46) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
      %tup_27 = cute.add_offset(%48, %idx_26) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
      %idx_28 = cute.crd2idx(%coord_9, %45) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
      %tup_29 = cute.add_offset(%tup_27, %idx_28) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %e0_30, %e1_31, %e2_32 = cute.get_leaves(%tup_29) : !cute.int_tuple<"(?{div=128},0,?)">
      %int_tuple = cute.make_int_tuple(%e0, %e2) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %e0_33, %e1_34, %e2_35 = cute.get_leaves(%int_tuple) : !cute.int_tuple<"(?{div=128},0,?)">
      %int_tuple_36 = cute.make_int_tuple(%e0_33, %e2_35) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %int_tuple_37 = cute.make_int_tuple(%e0_30, %e2_32) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %e0_38, %e1_39, %e2_40 = cute.get_leaves(%int_tuple_37) : !cute.int_tuple<"(?{div=128},0,?)">
      %int_tuple_41 = cute.make_int_tuple(%e0_38, %e2_40) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr_42 = cute.add_offset(%smem_ptr, %44) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"24576">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_43 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
      %iter_44 = cute.recast_iter(%ptr_42) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
      %iter_45 = cute.recast_iter(%iter_43) : !cute.ptr<f16, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
      %coord_46 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
      %89 = cute.get_scalars(%coord_46) <{only_dynamic}> : !cute.coord<"?">
      %90 = arith.divsi %89, %c4_i32 : i32
      %91 = arith.remsi %89, %c4_i32 : i32
      %92 = arith.muli %91, %c8_i32 : i32
      %93 = arith.muli %90, %c128_i32 : i32
      %94 = arith.addi %92, %93 : i32
      %iv_47 = cute.assume(%94) : (i32) -> !cute.i32<divby 8>
      %int_tuple_48 = cute.make_int_tuple(%iv_47) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_49 = cute.add_offset(%84, %int_tuple_48) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %95 = arith.divsi %90, %c2_i32 : i32
      %96 = arith.remsi %95, %c4_i32 : i32
      %97 = arith.muli %96, %c64_i32 : i32
      %98 = arith.addi %92, %97 : i32
      %99 = arith.remsi %90, %c2_i32 : i32
      %100 = arith.muli %99, %c32_i32 : i32
      %101 = arith.divsi %95, %c4_i32 : i32
      %102 = arith.muli %101, %c256_i32 : i32
      %103 = arith.addi %100, %102 : i32
      %104 = arith.andi %98, %c192_i32 : i32
      %105 = arith.shrsi %104, %c3_i32 : i32
      %106 = arith.xori %98, %105 : i32
      %107 = arith.addi %106, %103 : i32
      %iv_50 = cute.assume(%107) : (i32) -> !cute.i32<divby 8>
      %int_tuple_51 = cute.make_int_tuple(%iv_50) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_52 = cute.add_offset(%iter_43, %int_tuple_51) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %view_53 = cute.make_view(%ptr_52) : !memref_smem_f16_
      %ptr_54 = cute.add_offset(%88, %int_tuple_48) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %ptr_55 = cute.add_offset(%iter_44, %int_tuple_51) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %view_56 = cute.make_view(%ptr_55) : !memref_smem_f16_
      %108 = arith.divsi %89, %c16_i32 : i32
      %109 = arith.remsi %89, %c16_i32 : i32
      %110 = arith.remsi %109, %c8_i32 : i32
      %111 = arith.muli %110, %c8_i32 : i32
      %112 = arith.muli %108, %c128_i32 : i32
      %113 = arith.addi %111, %112 : i32
      %114 = arith.divsi %109, %c8_i32 : i32
      %115 = arith.muli %114, %c64_i32 : i32
      %116 = arith.andi %113, %c896_i32 : i32
      %117 = arith.shrsi %116, %c4_i32 : i32
      %118 = arith.xori %113, %117 : i32
      %119 = arith.addi %118, %115 : i32
      %iv_57 = cute.assume(%119) : (i32) -> !cute.i32<divby 8>
      %int_tuple_58 = cute.make_int_tuple(%iv_57) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_59 = cute.add_offset(%iter_45, %int_tuple_58) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %120 = arith.muli %109, %c8_i32 : i32
      %121 = arith.muli %108, %c256_i32 : i32
      %122 = arith.addi %120, %121 : i32
      %iv_60 = cute.assume(%122) : (i32) -> !cute.i32<divby 8>
      %int_tuple_61 = cute.make_int_tuple(%iv_60) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_62 = cute.add_offset(%ptr_17, %int_tuple_61) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %iv_63 = cute.assume(%92) : (i32) -> !cute.i32<divby 8>
      %int_tuple_64 = cute.make_int_tuple(%90, %iv_63) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_65 = cute.add_offset(%int_tuple_36, %int_tuple_64) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_66 = cute.make_view(%tup_65) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %dyn_67 = cute.derefine(%view_66) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %tup_68 = cute.add_offset(%int_tuple_41, %int_tuple_64) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_69 = cute.make_view(%tup_68) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %dyn_70 = cute.derefine(%view_69) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %rmem = cute.memref.alloca() : !memref_rmem_i8_
      %rmem_71 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_72 = cute.get_iter(%dyn_67) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %123 = cute.get_scalars(%42) : !cute.coord<"512">
      cf.br ^bb3(%c0_i32 : i32)
    ^bb3(%124: i32):  // 2 preds: ^bb2, ^bb4
      %125 = arith.cmpi slt, %124, %c4_i32 : i32
      cf.cond_br %125, ^bb4, ^bb5
    ^bb4:  // pred: ^bb3
      %coord_73 = cute.make_coord(%124) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_74 = cute.crd2idx(%coord_73, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_75 = cute.add_offset(%iter_72, %idx_74) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
      %e0_76, %e1_77, %e2_78 = cute.get_leaves(%tup_75) : !cute.int_tuple<"(?,?,?)">
      %coord_79 = cute.make_coord(%e0_76) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %126 = cute.get_scalars(%coord_79) : !cute.coord<"?">
      %127 = arith.cmpi slt, %126, %123 : i32
      %128 = arith.extui %127 : i1 to i8
      %coord_80 = cute.make_coord(%124) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_81 = cute.derefine(%coord_80) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem, %dyn_81, %128) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %129 = arith.addi %124, %c1_i32 : i32
      cf.br ^bb3(%129 : i32)
    ^bb5:  // pred: ^bb3
      %iter_82 = cute.get_iter(%dyn_70) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %130 = cute.get_scalars(%41) : !cute.coord<"256">
      cf.br ^bb6(%c0_i32 : i32)
    ^bb6(%131: i32):  // 2 preds: ^bb5, ^bb7
      %132 = arith.cmpi slt, %131, %c4_i32 : i32
      cf.cond_br %132, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %coord_83 = cute.make_coord(%131) : (i32) -> !cute.coord<"((0,0),?,0,0)">
      %idx_84 = cute.crd2idx(%coord_83, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_85 = cute.add_offset(%iter_82, %idx_84) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
      %e0_86, %e1_87, %e2_88 = cute.get_leaves(%tup_85) : !cute.int_tuple<"(?,?,?)">
      %coord_89 = cute.make_coord(%e0_86) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %133 = cute.get_scalars(%coord_89) : !cute.coord<"?">
      %134 = arith.cmpi slt, %133, %130 : i32
      %135 = arith.extui %134 : i1 to i8
      %coord_90 = cute.make_coord(%131) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_91 = cute.derefine(%coord_90) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem_71, %dyn_91, %135) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
      %136 = arith.addi %131, %c1_i32 : i32
      cf.br ^bb6(%136 : i32)
    ^bb8:  // pred: ^bb6
      cute.memref.store_vec %cst_0, %view_53, row_major : !memref_smem_f16_
      cute.memref.store_vec %cst_0, %view_56, row_major : !memref_smem_f16_
      nvvm.barrier
      %iter_92 = cute.get_iter(%dyn_67) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %e0_93, %e1_94, %e2_95 = cute.get_leaves(%iter_92) : !cute.int_tuple<"(?,?,?)">
      %coord_96 = cute.make_coord() : () -> !cute.coord<"-1">
      %dyn_97 = cute.derefine(%coord_96) : !cute.coord<"-1"> to !cute.coord<"?">
      %coord_98 = cute.make_coord(%e1_94) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %137 = cute.get_scalars(%dyn_97) : !cute.coord<"?">
      %138 = cute.get_scalars(%coord_98) : !cute.coord<"?">
      %139 = arith.cmpi slt, %137, %138 : i32
      cf.cond_br %139, ^bb9, ^bb13
    ^bb9:  // pred: ^bb8
      %iter_99 = cute.get_iter(%rmem) : !memref_rmem_i8_
      %140 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb10(%c0_i32 : i32)
    ^bb10(%141: i32):  // 2 preds: ^bb9, ^bb11
      %142 = arith.cmpi slt, %141, %140 : i32
      cf.cond_br %142, ^bb11, ^bb12 {llvm.loop_annotation = #loop_annotation}
    ^bb11:  // pred: ^bb10
      %coord_100 = cute.make_coord(%141) : (i32) -> !cute.coord<"(_,?)">
      %idx_101 = cute.crd2idx(%coord_100, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_102 = cute.add_offset(%ptr_49, %idx_101) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_103 = cute.crd2idx(%coord_100, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_104 = cute.add_offset(%ptr_52, %idx_103) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_105 = cute.crd2idx(%coord_100, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
      %ptr_106 = cute.add_offset(%iter_99, %idx_105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %143 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i8, rmem> to !llvm.ptr
      %144 = llvm.load %143 : !llvm.ptr -> i8
      %145 = llvm.trunc %144 : i8 to i1
      %iter_107 = cute.recast_iter(%ptr_102) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_108 = cute.recast_iter(%ptr_104) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_108 : !cute.ptr<i128, smem>, %iter_107 : !cute.ptr<i128, gmem>, %145 : i1) {cache_mode = <global>}
      %146 = arith.addi %141, %c1_i32 : i32
      cf.br ^bb10(%146 : i32)
    ^bb12:  // pred: ^bb10
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb8, ^bb12
      %iter_109 = cute.get_iter(%dyn_70) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
      %e0_110, %e1_111, %e2_112 = cute.get_leaves(%iter_109) : !cute.int_tuple<"(?,?,?)">
      %coord_113 = cute.make_coord(%e1_111) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %147 = cute.get_scalars(%coord_113) : !cute.coord<"?">
      %148 = arith.cmpi slt, %137, %147 : i32
      cf.cond_br %148, ^bb14, ^bb18
    ^bb14:  // pred: ^bb13
      %iter_114 = cute.get_iter(%rmem_71) : !memref_rmem_i8_
      %149 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb15(%c0_i32 : i32)
    ^bb15(%150: i32):  // 2 preds: ^bb14, ^bb16
      %151 = arith.cmpi slt, %150, %149 : i32
      cf.cond_br %151, ^bb16, ^bb17 {llvm.loop_annotation = #loop_annotation}
    ^bb16:  // pred: ^bb15
      %coord_115 = cute.make_coord(%150) : (i32) -> !cute.coord<"(_,?)">
      %idx_116 = cute.crd2idx(%coord_115, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_117 = cute.add_offset(%ptr_54, %idx_116) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_118 = cute.crd2idx(%coord_115, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_119 = cute.add_offset(%ptr_55, %idx_118) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_120 = cute.crd2idx(%coord_115, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
      %ptr_121 = cute.add_offset(%iter_114, %idx_120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %152 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i8, rmem> to !llvm.ptr
      %153 = llvm.load %152 : !llvm.ptr -> i8
      %154 = llvm.trunc %153 : i8 to i1
      %iter_122 = cute.recast_iter(%ptr_117) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_123 = cute.recast_iter(%ptr_119) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_123 : !cute.ptr<i128, smem>, %iter_122 : !cute.ptr<i128, gmem>, %154 : i1) {cache_mode = <global>}
      %155 = arith.addi %150, %c1_i32 : i32
      cf.br ^bb15(%155 : i32)
    ^bb17:  // pred: ^bb15
      cf.br ^bb18
    ^bb18:  // 2 preds: ^bb13, ^bb17
      nvvm.cp.async.commit.group
      %iter_124 = cute.get_iter(%rmem) : !memref_rmem_i8_
      %iter_125 = cute.get_iter(%rmem_71) : !memref_rmem_i8_
      %coord_126 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
      %idx_127 = cute.crd2idx(%coord_126, %40) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"32">
      %ptr_128 = cute.add_offset(%ptr_49, %idx_127) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_129 = cute.crd2idx(%coord_126, %35) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"4096">
      %ptr_130 = cute.add_offset(%ptr_52, %idx_129) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
      %156 = cute.get_scalars(%36) : !cute.int_tuple<"4">
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%157: i32):  // 2 preds: ^bb18, ^bb20
      %158 = arith.cmpi slt, %157, %156 : i32
      cf.cond_br %158, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation}
    ^bb20:  // pred: ^bb19
      %coord_131 = cute.make_coord(%157) : (i32) -> !cute.coord<"(_,?)">
      %idx_132 = cute.crd2idx(%coord_131, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_133 = cute.add_offset(%ptr_128, %idx_132) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_134 = cute.crd2idx(%coord_131, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_135 = cute.add_offset(%ptr_130, %idx_134) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_136 = cute.crd2idx(%coord_131, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_137 = cute.add_offset(%iter_124, %idx_136) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %159 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i8, rmem> to !llvm.ptr
      %160 = llvm.load %159 : !llvm.ptr -> i8
      %161 = llvm.trunc %160 : i8 to i1
      %iter_138 = cute.recast_iter(%ptr_133) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_139 = cute.recast_iter(%ptr_135) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_139 : !cute.ptr<i128, smem>, %iter_138 : !cute.ptr<i128, gmem>, %161 : i1) {cache_mode = <global>}
      %162 = arith.addi %157, %c1_i32 : i32
      cf.br ^bb19(%162 : i32)
    ^bb21:  // pred: ^bb19
      %ptr_140 = cute.add_offset(%ptr_54, %idx_127) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
      %ptr_141 = cute.add_offset(%ptr_55, %idx_129) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb22(%c0_i32 : i32)
    ^bb22(%163: i32):  // 2 preds: ^bb21, ^bb23
      %164 = arith.cmpi slt, %163, %156 : i32
      cf.cond_br %164, ^bb23, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %coord_142 = cute.make_coord(%163) : (i32) -> !cute.coord<"(_,?)">
      %idx_143 = cute.crd2idx(%coord_142, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_144 = cute.add_offset(%ptr_140, %idx_143) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_145 = cute.crd2idx(%coord_142, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_146 = cute.add_offset(%ptr_141, %idx_145) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_147 = cute.crd2idx(%coord_142, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_148 = cute.add_offset(%iter_125, %idx_147) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %165 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<i8, rmem> to !llvm.ptr
      %166 = llvm.load %165 : !llvm.ptr -> i8
      %167 = llvm.trunc %166 : i8 to i1
      %iter_149 = cute.recast_iter(%ptr_144) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_150 = cute.recast_iter(%ptr_146) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_150 : !cute.ptr<i128, smem>, %iter_149 : !cute.ptr<i128, gmem>, %167 : i1) {cache_mode = <global>}
      %168 = arith.addi %163, %c1_i32 : i32
      cf.br ^bb22(%168 : i32)
    ^bb24:  // pred: ^bb22
      nvvm.cp.async.commit.group
      %169 = arith.remsi %89, %c32_i32 : i32
      %170 = arith.divsi %89, %c32_i32 : i32
      %171 = arith.remsi %170, %c2_i32 : i32
      %172 = arith.divsi %89, %c64_i32 : i32
      %173 = arith.remsi %172, %c2_i32 : i32
      %174 = arith.remsi %169, %c32_i32 : i32
      %175 = arith.remsi %171, %c2_i32 : i32
      %176 = arith.remsi %173, %c2_i32 : i32
      %177 = arith.divsi %174, %c4_i32 : i32
      %178 = arith.muli %177, %c128_i32 : i32
      %179 = arith.muli %176, %c8_i32 : i32
      %180 = arith.addi %178, %179 : i32
      %181 = arith.remsi %174, %c4_i32 : i32
      %182 = arith.muli %181, %c2_i32 : i32
      %183 = arith.muli %175, %c2048_i32 : i32
      %184 = arith.addi %182, %183 : i32
      %185 = arith.andi %180, %c256_i32 : i32
      %186 = arith.cmpi eq, %185, %c0_i32 : i32
      %187 = arith.select %186, %c16_i32, %c-16_i32 : i32
      %188 = arith.andi %180, %c512_i32 : i32
      %189 = arith.cmpi eq, %188, %c0_i32 : i32
      %190 = arith.select %189, %c32_i32, %c-32_i32 : i32
      %191 = arith.andi %180, %c896_i32 : i32
      %192 = arith.shrsi %191, %c4_i32 : i32
      %193 = arith.xori %180, %192 : i32
      %194 = arith.addi %193, %184 : i32
      %iv_151 = cute.assume(%194) : (i32) -> !cute.i32<divby 2>
      %int_tuple_152 = cute.make_int_tuple(%iv_151) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
      %ptr_153 = cute.add_offset(%iter_45, %int_tuple_152) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, smem, align<4>>
      %iv_154 = cute.assume(%187) : (i32) -> !cute.i32<divby 16>
      %iv_155 = cute.assume(%190) : (i32) -> !cute.i32<divby 32>
      %stride = cute.make_stride(%iv_154, %iv_155) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,1024),4096,(?{div=16},?{div=32},64))">
      %lay = cute.make_layout(%31, %stride) : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
      %rmem_156 = cute.memref.alloca() : !memref_rmem_f16_
      %rmem_157 = cute.memref.alloca() : !memref_rmem_f16_1
      %rmem_158 = cute.memref.alloca() : !memref_rmem_f32_
      cute.memref.store_vec %cst, %rmem_158, row_major : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
      %195 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %196 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %197 = arith.divsi %109, %c2_i32 : i32
      %198 = arith.remsi %197, %c4_i32 : i32
      %199 = arith.muli %198, %c64_i32 : i32
      %200 = arith.remsi %108, %c2_i32 : i32
      %201 = arith.muli %200, %c8_i32 : i32
      %202 = arith.addi %199, %201 : i32
      %203 = arith.remsi %109, %c2_i32 : i32
      %204 = arith.muli %203, %c32_i32 : i32
      %205 = arith.divsi %197, %c4_i32 : i32
      %206 = arith.muli %205, %c256_i32 : i32
      %207 = arith.addi %204, %206 : i32
      %208 = arith.divsi %108, %c2_i32 : i32
      %209 = arith.remsi %208, %c2_i32 : i32
      %210 = arith.muli %209, %c512_i32 : i32
      %211 = arith.addi %207, %210 : i32
      %212 = arith.andi %202, %c128_i32 : i32
      %213 = arith.cmpi eq, %212, %c0_i32 : i32
      %214 = arith.select %213, %c16_i32, %c-16_i32 : i32
      %215 = arith.andi %202, %c192_i32 : i32
      %216 = arith.shrsi %215, %c3_i32 : i32
      %217 = arith.xori %202, %216 : i32
      %218 = arith.addi %217, %211 : i32
      %iv_159 = cute.assume(%218) : (i32) -> !cute.i32<divby 8>
      %int_tuple_160 = cute.make_int_tuple(%iv_159) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_161 = cute.add_offset(%iter_43, %int_tuple_160) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %iv_162 = cute.assume(%214) : (i32) -> !cute.i32<divby 16>
      %stride_163 = cute.make_stride(%iv_162) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
      %lay_164 = cute.make_layout(%30, %stride_163) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iter_165 = cute.get_iter(%rmem_156) : !memref_rmem_f16_
      %219 = arith.divsi %89, %c8_i32 : i32
      %220 = arith.remsi %89, %c8_i32 : i32
      %221 = arith.divsi %220, %c2_i32 : i32
      %222 = arith.muli %221, %c64_i32 : i32
      %223 = arith.remsi %219, %c2_i32 : i32
      %224 = arith.muli %223, %c8_i32 : i32
      %225 = arith.addi %222, %224 : i32
      %226 = arith.remsi %220, %c2_i32 : i32
      %227 = arith.muli %226, %c32_i32 : i32
      %228 = arith.divsi %219, %c2_i32 : i32
      %229 = arith.divsi %228, %c2_i32 : i32
      %230 = arith.remsi %228, %c2_i32 : i32
      %231 = arith.muli %230, %c512_i32 : i32
      %232 = arith.addi %227, %231 : i32
      %233 = arith.divsi %229, %c2_i32 : i32
      %234 = arith.muli %233, %c256_i32 : i32
      %235 = arith.addi %232, %234 : i32
      %236 = arith.andi %225, %c128_i32 : i32
      %237 = arith.cmpi eq, %236, %c0_i32 : i32
      %238 = arith.select %237, %c16_i32, %c-16_i32 : i32
      %239 = arith.andi %225, %c192_i32 : i32
      %240 = arith.shrsi %239, %c3_i32 : i32
      %241 = arith.xori %225, %240 : i32
      %242 = arith.addi %241, %235 : i32
      %iv_166 = cute.assume(%242) : (i32) -> !cute.i32<divby 8>
      %int_tuple_167 = cute.make_int_tuple(%iv_166) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_168 = cute.add_offset(%iter_44, %int_tuple_167) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
      %iv_169 = cute.assume(%238) : (i32) -> !cute.i32<divby 16>
      %stride_170 = cute.make_stride(%iv_169) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
      %lay_171 = cute.make_layout(%30, %stride_170) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iter_172 = cute.get_iter(%rmem_157) : !memref_rmem_f16_1
      %243 = cute.get_scalars(%lay_164) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iv_173 = cute.assume(%243) : (i32) -> !cute.i32<divby 16>
      %stride_174 = cute.make_stride(%iv_173) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
      %lay_175 = cute.make_layout(%29, %stride_174) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
      %view_176 = cute.make_view(%ptr_161, %lay_175) : !memref_smem_f16_1
      %244 = builtin.unrealized_conversion_cast %view_176 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      %245 = cute.get_scalars(%lay_171) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
      %iv_177 = cute.assume(%245) : (i32) -> !cute.i32<divby 16>
      %stride_178 = cute.make_stride(%iv_177) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
      %lay_179 = cute.make_layout(%29, %stride_178) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
      %view_180 = cute.make_view(%ptr_168, %lay_179) : !memref_smem_f16_1
      %246 = builtin.unrealized_conversion_cast %view_180 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%247: i32):  // 2 preds: ^bb24, ^bb26
      %248 = arith.cmpi slt, %247, %156 : i32
      cf.cond_br %248, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %coord_181 = cute.make_coord(%247) : (i32) -> !cute.coord<"(_,?)">
      %idx_182 = cute.crd2idx(%coord_181, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_183 = cute.add_offset(%ptr_161, %idx_182) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_184 = cute.crd2idx(%coord_181, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_185 = cute.add_offset(%iter_165, %idx_184) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %249 = cute_nvgpu.arch.copy.ldsm %ptr_183{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %250 = vector.extractelement %249[%27 : i32] : vector<4xi32>
      %251 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %250, %251 : i32, !llvm.ptr
      %252 = vector.extractelement %249[%26 : i32] : vector<4xi32>
      %ptr_186 = cute.add_offset(%ptr_185, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %253 = builtin.unrealized_conversion_cast %ptr_186 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %252, %253 : i32, !llvm.ptr
      %254 = vector.extractelement %249[%24 : i32] : vector<4xi32>
      %ptr_187 = cute.add_offset(%ptr_185, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %255 = builtin.unrealized_conversion_cast %ptr_187 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %254, %255 : i32, !llvm.ptr
      %256 = vector.extractelement %249[%23 : i32] : vector<4xi32>
      %ptr_188 = cute.add_offset(%ptr_185, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %257 = builtin.unrealized_conversion_cast %ptr_188 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %256, %257 : i32, !llvm.ptr
      %258 = arith.addi %247, %c1_i32 : i32
      cf.br ^bb25(%258 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%c0_i32 : i32)
    ^bb28(%259: i32):  // 2 preds: ^bb27, ^bb29
      %260 = arith.cmpi slt, %259, %156 : i32
      cf.cond_br %260, ^bb29, ^bb30 {llvm.loop_annotation = #loop_annotation}
    ^bb29:  // pred: ^bb28
      %coord_189 = cute.make_coord(%259) : (i32) -> !cute.coord<"(_,?)">
      %idx_190 = cute.crd2idx(%coord_189, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_191 = cute.add_offset(%ptr_168, %idx_190) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_192 = cute.crd2idx(%coord_189, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_193 = cute.add_offset(%iter_172, %idx_192) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %261 = cute_nvgpu.arch.copy.ldsm %ptr_191{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %262 = vector.extractelement %261[%27 : i32] : vector<4xi32>
      %263 = builtin.unrealized_conversion_cast %ptr_193 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %262, %263 : i32, !llvm.ptr
      %264 = vector.extractelement %261[%26 : i32] : vector<4xi32>
      %ptr_194 = cute.add_offset(%ptr_193, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %265 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %264, %265 : i32, !llvm.ptr
      %266 = vector.extractelement %261[%24 : i32] : vector<4xi32>
      %ptr_195 = cute.add_offset(%ptr_193, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %267 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %266, %267 : i32, !llvm.ptr
      %268 = vector.extractelement %261[%23 : i32] : vector<4xi32>
      %ptr_196 = cute.add_offset(%ptr_193, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %269 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %268, %269 : i32, !llvm.ptr
      %270 = arith.addi %259, %c1_i32 : i32
      cf.br ^bb28(%270 : i32)
    ^bb30:  // pred: ^bb28
      %iter_197 = cute.get_iter(%rmem_158) : !memref_rmem_f32_
      %271 = cute.get_scalars(%15) : !cute.int_tuple<"1">
      %272 = cute.get_scalars(%14) : !cute.int_tuple<"8">
      cf.br ^bb31(%c0_i32, %244, %246, %c2_i32, %c2_i32, %c0_i32 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb31(%273: i32, %274: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %275: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %276: i32, %277: i32, %278: i32):  // 2 preds: ^bb30, ^bb70
      %279 = arith.cmpi slt, %273, %c4_i32 : i32
      cf.cond_br %279, ^bb32, ^bb71
    ^bb32:  // pred: ^bb31
      cf.br ^bb33(%c0_i32, %274, %275, %276, %277, %278 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb33(%280: i32, %281: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %282: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %283: i32, %284: i32, %285: i32):  // 2 preds: ^bb32, ^bb69
      %286 = arith.cmpi slt, %280, %c2_i32 : i32
      cf.cond_br %286, ^bb34, ^bb70 {loop_annotation = #loop_annotation1}
    ^bb34:  // pred: ^bb33
      %287 = arith.cmpi eq, %280, %c1_i32 : i32
      cf.cond_br %287, ^bb35, ^bb36
    ^bb35:  // pred: ^bb34
      %coord_198 = cute.make_coord(%285) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_199 = cute.crd2idx(%coord_198, %lay_164) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_200 = cute.add_offset(%ptr_161, %idx_199) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      %view_201 = cute.make_view(%ptr_200, %lay_175) : !memref_smem_f16_1
      %288 = builtin.unrealized_conversion_cast %view_201 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      %idx_202 = cute.crd2idx(%coord_198, %lay_171) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_203 = cute.add_offset(%ptr_168, %idx_202) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      %view_204 = cute.make_view(%ptr_203, %lay_179) : !memref_smem_f16_1
      %289 = builtin.unrealized_conversion_cast %view_204 : !memref_smem_f16_1 to !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>
      nvvm.cp.async.wait.group 1
      nvvm.barrier
      cf.br ^bb37(%288, %289 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>)
    ^bb36:  // pred: ^bb34
      cf.br ^bb37(%281, %282 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>)
    ^bb37(%290: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, %291: !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>):  // 2 preds: ^bb35, ^bb36
      cf.br ^bb38
    ^bb38:  // pred: ^bb37
      %292 = builtin.unrealized_conversion_cast %291 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)> to !memref_smem_f16_1
      %293 = builtin.unrealized_conversion_cast %290 : !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)> to !memref_smem_f16_1
      %294 = arith.addi %280, %c1_i32 : i32
      %295 = arith.remsi %294, %c2_i32 : i32
      %coord_205 = cute.make_coord(%295) : (i32) -> !cute.coord<"(_,_,?)">
      %lay_206 = cute.get_layout(%293) : !memref_smem_f16_1
      %idx_207 = cute.crd2idx(%coord_205, %lay_206) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
      %iter_208 = cute.get_iter(%293) : !memref_smem_f16_1
      %ptr_209 = cute.add_offset(%iter_208, %idx_207) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_210 = cute.crd2idx(%coord_205, %21) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),8,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_211 = cute.add_offset(%iter_165, %idx_210) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
      cf.br ^bb39(%c0_i32 : i32)
    ^bb39(%296: i32):  // 2 preds: ^bb38, ^bb40
      %297 = arith.cmpi slt, %296, %156 : i32
      cf.cond_br %297, ^bb40, ^bb41 {llvm.loop_annotation = #loop_annotation}
    ^bb40:  // pred: ^bb39
      %coord_212 = cute.make_coord(%296) : (i32) -> !cute.coord<"(_,?)">
      %idx_213 = cute.crd2idx(%coord_212, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_214 = cute.add_offset(%ptr_209, %idx_213) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_215 = cute.crd2idx(%coord_212, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_216 = cute.add_offset(%ptr_211, %idx_215) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %298 = cute_nvgpu.arch.copy.ldsm %ptr_214{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %299 = vector.extractelement %298[%27 : i32] : vector<4xi32>
      %300 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %299, %300 : i32, !llvm.ptr
      %301 = vector.extractelement %298[%26 : i32] : vector<4xi32>
      %ptr_217 = cute.add_offset(%ptr_216, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %302 = builtin.unrealized_conversion_cast %ptr_217 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %301, %302 : i32, !llvm.ptr
      %303 = vector.extractelement %298[%24 : i32] : vector<4xi32>
      %ptr_218 = cute.add_offset(%ptr_216, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %304 = builtin.unrealized_conversion_cast %ptr_218 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %303, %304 : i32, !llvm.ptr
      %305 = vector.extractelement %298[%23 : i32] : vector<4xi32>
      %ptr_219 = cute.add_offset(%ptr_216, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %306 = builtin.unrealized_conversion_cast %ptr_219 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %305, %306 : i32, !llvm.ptr
      %307 = arith.addi %296, %c1_i32 : i32
      cf.br ^bb39(%307 : i32)
    ^bb41:  // pred: ^bb39
      %lay_220 = cute.get_layout(%292) : !memref_smem_f16_1
      %idx_221 = cute.crd2idx(%coord_205, %lay_220) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
      %iter_222 = cute.get_iter(%292) : !memref_smem_f16_1
      %ptr_223 = cute.add_offset(%iter_222, %idx_221) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
      %ptr_224 = cute.add_offset(%iter_172, %idx_210) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%308: i32):  // 2 preds: ^bb41, ^bb43
      %309 = arith.cmpi slt, %308, %156 : i32
      cf.cond_br %309, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %coord_225 = cute.make_coord(%308) : (i32) -> !cute.coord<"(_,?)">
      %idx_226 = cute.crd2idx(%coord_225, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_227 = cute.add_offset(%ptr_223, %idx_226) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_228 = cute.crd2idx(%coord_225, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_229 = cute.add_offset(%ptr_224, %idx_228) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %310 = cute_nvgpu.arch.copy.ldsm %ptr_227{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
      %311 = vector.extractelement %310[%27 : i32] : vector<4xi32>
      %312 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %311, %312 : i32, !llvm.ptr
      %313 = vector.extractelement %310[%26 : i32] : vector<4xi32>
      %ptr_230 = cute.add_offset(%ptr_229, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %314 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %313, %314 : i32, !llvm.ptr
      %315 = vector.extractelement %310[%24 : i32] : vector<4xi32>
      %ptr_231 = cute.add_offset(%ptr_229, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %316 = builtin.unrealized_conversion_cast %ptr_231 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %315, %316 : i32, !llvm.ptr
      %317 = vector.extractelement %310[%23 : i32] : vector<4xi32>
      %ptr_232 = cute.add_offset(%ptr_229, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %318 = builtin.unrealized_conversion_cast %ptr_232 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %317, %318 : i32, !llvm.ptr
      %319 = arith.addi %308, %c1_i32 : i32
      cf.br ^bb42(%319 : i32)
    ^bb44:  // pred: ^bb42
      %320 = arith.cmpi eq, %280, %c0_i32 : i32
      cf.cond_br %320, ^bb45, ^bb51
    ^bb45:  // pred: ^bb44
      %321 = arith.addi %273, %c2_i32 : i32
      %322 = arith.cmpi slt, %321, %c4_i32 : i32
      cf.cond_br %322, ^bb46, ^bb50
    ^bb46:  // pred: ^bb45
      %coord_233 = cute.make_coord(%283) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_234 = cute.crd2idx(%coord_233, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_235 = cute.add_offset(%ptr_49, %idx_234) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
      %coord_236 = cute.make_coord(%284) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_237 = cute.crd2idx(%coord_236, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_238 = cute.add_offset(%ptr_52, %idx_237) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb47(%c0_i32 : i32)
    ^bb47(%323: i32):  // 2 preds: ^bb46, ^bb48
      %324 = arith.cmpi slt, %323, %156 : i32
      cf.cond_br %324, ^bb48, ^bb49 {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %coord_239 = cute.make_coord(%323) : (i32) -> !cute.coord<"(_,?)">
      %idx_240 = cute.crd2idx(%coord_239, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_241 = cute.add_offset(%ptr_235, %idx_240) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_242 = cute.crd2idx(%coord_239, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_243 = cute.add_offset(%ptr_238, %idx_242) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_244 = cute.crd2idx(%coord_239, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_245 = cute.add_offset(%iter_124, %idx_244) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %325 = builtin.unrealized_conversion_cast %ptr_245 : !cute.ptr<i8, rmem> to !llvm.ptr
      %326 = llvm.load %325 : !llvm.ptr -> i8
      %327 = llvm.trunc %326 : i8 to i1
      %iter_246 = cute.recast_iter(%ptr_241) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_247 = cute.recast_iter(%ptr_243) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_247 : !cute.ptr<i128, smem>, %iter_246 : !cute.ptr<i128, gmem>, %327 : i1) {cache_mode = <global>}
      %328 = arith.addi %323, %c1_i32 : i32
      cf.br ^bb47(%328 : i32)
    ^bb49:  // pred: ^bb47
      cf.br ^bb50
    ^bb50:  // 2 preds: ^bb45, ^bb49
      cf.br ^bb51
    ^bb51:  // 2 preds: ^bb44, ^bb50
      %coord_248 = cute.make_coord(%280) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_249 = cute.crd2idx(%coord_248, %20) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2,2),4,2):((1,2,4),8,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_250 = cute.add_offset(%iter_165, %idx_249) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_251 = cute.crd2idx(%coord_248, %19) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2),8,2):((1,2),4,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_252 = cute.add_offset(%iter_172, %idx_251) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
      cf.br ^bb52(%c0_i32 : i32)
    ^bb52(%329: i32):  // 2 preds: ^bb51, ^bb59
      %330 = arith.cmpi slt, %329, %271 : i32
      cf.cond_br %330, ^bb53, ^bb60 {llvm.loop_annotation = #loop_annotation}
    ^bb53:  // pred: ^bb52
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%331: i32):  // 2 preds: ^bb53, ^bb58
      %332 = arith.cmpi slt, %331, %156 : i32
      cf.cond_br %332, ^bb55, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %coord_253 = cute.make_coord(%331, %329) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_254 = cute.crd2idx(%coord_253, %17) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),4,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_255 = cute.add_offset(%ptr_250, %idx_254) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %333 = builtin.unrealized_conversion_cast %ptr_255 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %334 = llvm.getelementptr %333[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %335 = llvm.getelementptr %333[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %336 = llvm.getelementptr %333[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%337: i32):  // 2 preds: ^bb55, ^bb57
      %338 = arith.cmpi slt, %337, %272 : i32
      cf.cond_br %338, ^bb57, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb57:  // pred: ^bb56
      %coord_256 = cute.make_coord(%337, %329) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_257 = cute.make_coord(%331, %337) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_258 = cute.crd2idx(%coord_256, %16) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_259 = cute.add_offset(%ptr_252, %idx_258) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_260 = cute.crd2idx(%coord_257, %18) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,8):((1,2),4,16)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_261 = cute.add_offset(%iter_197, %idx_260) : (!cute.ptr<f32, rmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %339 = llvm.load %333 : !llvm.ptr -> vector<2xf16>
      %340 = llvm.load %334 : !llvm.ptr -> vector<2xf16>
      %341 = llvm.load %335 : !llvm.ptr -> vector<2xf16>
      %342 = llvm.load %336 : !llvm.ptr -> vector<2xf16>
      %343 = builtin.unrealized_conversion_cast %ptr_259 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %344 = llvm.load %343 : !llvm.ptr -> vector<2xf16>
      %345 = llvm.getelementptr %343[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %346 = llvm.load %345 : !llvm.ptr -> vector<2xf16>
      %347 = builtin.unrealized_conversion_cast %ptr_261 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %348 = llvm.load %347 : !llvm.ptr -> f32
      %349 = llvm.getelementptr %347[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %350 = llvm.load %349 : !llvm.ptr -> f32
      %351 = llvm.getelementptr %347[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %352 = llvm.load %351 : !llvm.ptr -> f32
      %353 = llvm.getelementptr %347[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %354 = llvm.load %353 : !llvm.ptr -> f32
      %355:4 = cute_nvgpu.arch.mma.SM80 A[%339, %340, %341, %342]  B[%344, %346]  C[%348, %350, %352, %354] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %355#0, %347 : f32, !llvm.ptr
      llvm.store %355#1, %349 : f32, !llvm.ptr
      llvm.store %355#2, %351 : f32, !llvm.ptr
      llvm.store %355#3, %353 : f32, !llvm.ptr
      %356 = arith.addi %337, %c1_i32 : i32
      cf.br ^bb56(%356 : i32)
    ^bb58:  // pred: ^bb56
      %357 = arith.addi %331, %c1_i32 : i32
      cf.br ^bb54(%357 : i32)
    ^bb59:  // pred: ^bb54
      %358 = arith.addi %329, %c1_i32 : i32
      cf.br ^bb52(%358 : i32)
    ^bb60:  // pred: ^bb52
      %359 = arith.select %320, %285, %284 : i32
      cf.cond_br %320, ^bb61, ^bb67
    ^bb61:  // pred: ^bb60
      %360 = arith.addi %273, %c2_i32 : i32
      %361 = arith.cmpi slt, %360, %c4_i32 : i32
      cf.cond_br %361, ^bb62, ^bb66
    ^bb62:  // pred: ^bb61
      %coord_262 = cute.make_coord(%283) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_263 = cute.crd2idx(%coord_262, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
      %ptr_264 = cute.add_offset(%ptr_54, %idx_263) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
      %coord_265 = cute.make_coord(%284) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_266 = cute.crd2idx(%coord_265, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_267 = cute.add_offset(%ptr_55, %idx_266) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
      cf.br ^bb63(%c0_i32 : i32)
    ^bb63(%362: i32):  // 2 preds: ^bb62, ^bb64
      %363 = arith.cmpi slt, %362, %156 : i32
      cf.cond_br %363, ^bb64, ^bb65 {llvm.loop_annotation = #loop_annotation}
    ^bb64:  // pred: ^bb63
      %coord_268 = cute.make_coord(%362) : (i32) -> !cute.coord<"(_,?)">
      %idx_269 = cute.crd2idx(%coord_268, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_270 = cute.add_offset(%ptr_264, %idx_269) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_271 = cute.crd2idx(%coord_268, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_272 = cute.add_offset(%ptr_267, %idx_271) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_273 = cute.crd2idx(%coord_268, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
      %ptr_274 = cute.add_offset(%iter_125, %idx_273) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %364 = builtin.unrealized_conversion_cast %ptr_274 : !cute.ptr<i8, rmem> to !llvm.ptr
      %365 = llvm.load %364 : !llvm.ptr -> i8
      %366 = llvm.trunc %365 : i8 to i1
      %iter_275 = cute.recast_iter(%ptr_270) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_276 = cute.recast_iter(%ptr_272) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_276 : !cute.ptr<i128, smem>, %iter_275 : !cute.ptr<i128, gmem>, %366 : i1) {cache_mode = <global>}
      %367 = arith.addi %362, %c1_i32 : i32
      cf.br ^bb63(%367 : i32)
    ^bb65:  // pred: ^bb63
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb61, ^bb65
      %368 = arith.addi %283, %c1_i32 : i32
      nvvm.cp.async.commit.group
      %369 = arith.addi %285, %c1_i32 : i32
      %370 = arith.cmpi eq, %369, %c3_i32 : i32
      %371 = arith.select %370, %c0_i32, %369 : i32
      cf.br ^bb68(%368, %371 : i32, i32)
    ^bb67:  // pred: ^bb60
      cf.br ^bb68(%283, %285 : i32, i32)
    ^bb68(%372: i32, %373: i32):  // 2 preds: ^bb66, ^bb67
      cf.br ^bb69
    ^bb69:  // pred: ^bb68
      %374 = arith.addi %280, %c1_i32 : i32
      cf.br ^bb33(%374, %290, %291, %372, %359, %373 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb70:  // pred: ^bb33
      %375 = arith.addi %273, %c1_i32 : i32
      cf.br ^bb31(%375, %281, %282, %283, %284, %285 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, i32)>)>, i32, i32, i32)
    ^bb71:  // pred: ^bb31
      nvvm.cp.async.wait.group 0
      nvvm.barrier
      %rmem_277 = cute.memref.alloca() : !memref_rmem_f16_2
      %376 = cute.memref.load_vec %rmem_158, row_major : !memref_rmem_f32_
      %377 = arith.truncf %376 : vector<128xf32> to vector<128xf16>
      %iter_278 = cute.get_iter(%rmem_277) : !memref_rmem_f16_2
      %view_279 = cute.make_view(%iter_278) : !memref_rmem_f16_2
      cute.memref.store_vec %377, %view_279, row_major : !memref_rmem_f16_2
      %378:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
      %iv_280 = cute.assume(%378#0) : (i32) -> !cute.i32<divby 16>
      %iv_281 = cute.assume(%378#1) : (i32) -> !cute.i32<divby 32>
      %stride_282 = cute.make_stride(%iv_280, %iv_281) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
      %lay_283 = cute.make_layout(%13, %stride_282) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %379:2 = cute.get_scalars(%lay_283) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %iv_284 = cute.assume(%379#0) : (i32) -> !cute.i32<divby 16>
      %iv_285 = cute.assume(%379#1) : (i32) -> !cute.i32<divby 32>
      %stride_286 = cute.make_stride(%iv_284, %iv_285) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
      %lay_287 = cute.make_layout(%13, %stride_286) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %append = cute.append_to_rank<2> (%lay_287, %57) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">, !cute.layout<"1:0">
      %380:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
      %iv_288 = cute.assume(%380#0) : (i32) -> !cute.i32<divby 16>
      %iv_289 = cute.assume(%380#1) : (i32) -> !cute.i32<divby 32>
      %stride_290 = cute.make_stride(%iv_288, %iv_289) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,((1024,4096,?{div=16},?{div=32},64)))">
      %lay_291 = cute.make_layout(%11, %stride_290) : !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">
      %381 = cute.get_scalars(%10) : !cute.int_tuple<"64">
      cf.br ^bb72(%c0_i32 : i32)
    ^bb72(%382: i32):  // 2 preds: ^bb71, ^bb73
      %383 = arith.cmpi slt, %382, %381 : i32
      cf.cond_br %383, ^bb73, ^bb74 {llvm.loop_annotation = #loop_annotation}
    ^bb73:  // pred: ^bb72
      %coord_292 = cute.make_coord(%382) : (i32) -> !cute.coord<"(_,?)">
      %idx_293 = cute.crd2idx(%coord_292, %12) : (!cute.coord<"(_,?)">, !cute.layout<"(2,(64)):(1,(2))">) -> !cute.int_tuple<"?{div=2}">
      %ptr_294 = cute.add_offset(%iter_278, %idx_293) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, rmem, align<4>>
      %idx_295 = cute.crd2idx(%coord_292, %lay_291) : (!cute.coord<"(_,?)">, !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_296 = cute.add_offset(%ptr_153, %idx_295) : (!cute.ptr<f16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<4>>
      %384 = builtin.unrealized_conversion_cast %ptr_294 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      %385 = builtin.unrealized_conversion_cast %ptr_296 : !cute.ptr<f16, smem, align<4>> to !llvm.ptr<3>
      %386 = llvm.load %384 {alignment = 4 : i64} : !llvm.ptr -> vector<2xf16>
      llvm.store %386, %385 {alignment = 4 : i64} : vector<2xf16>, !llvm.ptr<3>
      %387 = arith.addi %382, %c1_i32 : i32
      cf.br ^bb72(%387 : i32)
    ^bb74:  // pred: ^bb72
      %idx_297 = cute.crd2idx(%coord, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,1):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
      %tup_298 = cute.add_offset(%48, %idx_297) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
      %idx_299 = cute.crd2idx(%coord_15, %8) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((1@0,1@1),(128@0,128@1))">) -> !cute.int_tuple<"(?{div=128},?{div=128})">
      %tup_300 = cute.add_offset(%tup_298, %idx_299) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},?{div=128})">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %iv_301 = cute.assume(%120) : (i32) -> !cute.i32<divby 8>
      %int_tuple_302 = cute.make_int_tuple(%108, %iv_301) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_303 = cute.add_offset(%tup_300, %int_tuple_302) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %rmem_304 = cute.memref.alloca() : !memref_rmem_f16_3
      nvvm.barrier
      %iter_305 = cute.get_iter(%rmem_304) : !memref_rmem_f16_3
      %388 = cute.get_scalars(%5) : !cute.int_tuple<"16">
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%389: i32):  // 2 preds: ^bb74, ^bb76
      %390 = arith.cmpi slt, %389, %388 : i32
      cf.cond_br %390, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      %coord_306 = cute.make_coord(%389) : (i32) -> !cute.coord<"(_,?)">
      %idx_307 = cute.crd2idx(%coord_306, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(1024))">) -> !cute.int_tuple<"?{div=1024}">
      %ptr_308 = cute.add_offset(%ptr_59, %idx_307) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
      %idx_309 = cute.crd2idx(%coord_306, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_310 = cute.add_offset(%iter_305, %idx_309) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %391 = builtin.unrealized_conversion_cast %ptr_308 : !cute.ptr<f16, smem, align<16>> to !llvm.ptr<3>
      %392 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %393 = llvm.load %391 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xf16>
      llvm.store %393, %392 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr
      %394 = arith.addi %389, %c1_i32 : i32
      cf.br ^bb75(%394 : i32)
    ^bb77:  // pred: ^bb75
      %rmem_311 = cute.memref.alloca() : !memref_rmem_i8_1
      %395 = cute.get_scalars(%42) : !cute.coord<"512">
      cf.br ^bb78(%c0_i32 : i32)
    ^bb78(%396: i32):  // 2 preds: ^bb77, ^bb79
      %397 = arith.cmpi slt, %396, %c16_i32 : i32
      cf.cond_br %397, ^bb79, ^bb80
    ^bb79:  // pred: ^bb78
      %coord_312 = cute.make_coord(%396) : (i32) -> !cute.coord<"((0,0),?,0)">
      %idx_313 = cute.crd2idx(%coord_312, %4) : (!cute.coord<"((0,0),?,0)">, !cute.layout<"((8,1),16,1):((1@1,0),8@0,0)">) -> !cute.int_tuple<"(?{div=8},0)">
      %tup_314 = cute.add_offset(%tup_303, %idx_313) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(?{div=8},0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %e0_315, %e1_316, %e2_317 = cute.get_leaves(%tup_314) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_318 = cute.make_coord(%e0_315) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
      %398 = cute.get_scalars(%coord_318) : !cute.coord<"?">
      %399 = arith.cmpi slt, %398, %395 : i32
      %400 = arith.extui %399 : i1 to i8
      %coord_319 = cute.make_coord(%396) : (i32) -> !cute.coord<"(0,?,0)">
      %dyn_320 = cute.derefine(%coord_319) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
      cute.memref.store(%rmem_311, %dyn_320, %400) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
      %401 = arith.addi %396, %c1_i32 : i32
      cf.br ^bb78(%401 : i32)
    ^bb80:  // pred: ^bb78
      %e0_321, %e1_322, %e2_323 = cute.get_leaves(%tup_303) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_324 = cute.make_coord(%e1_322) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %402 = cute.get_scalars(%coord_324) : !cute.coord<"?{div=8}">
      %403 = cute.get_scalars(%41) : !cute.coord<"256">
      %404 = arith.cmpi slt, %402, %403 : i32
      cf.cond_br %404, ^bb81, ^bb87
    ^bb81:  // pred: ^bb80
      %iter_325 = cute.get_iter(%rmem_311) : !memref_rmem_i8_1
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%405: i32):  // 2 preds: ^bb81, ^bb85
      %406 = arith.cmpi slt, %405, %388 : i32
      cf.cond_br %406, ^bb83, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      %coord_326 = cute.make_coord(%405) : (i32) -> !cute.coord<"(_,?)">
      %idx_327 = cute.crd2idx(%coord_326, %3) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_328 = cute.add_offset(%iter_305, %idx_327) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_329 = cute.crd2idx(%coord_326, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((2048)))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_330 = cute.add_offset(%ptr_62, %idx_329) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f16, gmem, align<16>>
      %idx_331 = cute.crd2idx(%coord_326, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((16))):(16,((1)))">) -> !cute.int_tuple<"?">
      %ptr_332 = cute.add_offset(%iter_325, %idx_331) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %407 = builtin.unrealized_conversion_cast %ptr_332 : !cute.ptr<i8, rmem> to !llvm.ptr
      %408 = llvm.load %407 : !llvm.ptr -> i8
      %409 = llvm.icmp "ne" %408, %0 : i8
      cf.cond_br %409, ^bb84, ^bb85
    ^bb84:  // pred: ^bb83
      %410 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %411 = builtin.unrealized_conversion_cast %ptr_330 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
      %412 = llvm.load %410 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %412, %411 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      cf.br ^bb85
    ^bb85:  // 2 preds: ^bb83, ^bb84
      %413 = arith.addi %405, %c1_i32 : i32
      cf.br ^bb82(%413 : i32)
    ^bb86:  // pred: ^bb82
      cf.br ^bb87
    ^bb87:  // 2 preds: ^bb80, ^bb86
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb1, ^bb87
      return
    }
  }
  func.func @cutlass_tensor_op_gemm_wrapper___main__BufferWithLayoutobjectat___main__BufferWithLayoutobjectat___main__BufferWithLayoutobjectat_512_256_128_16_Float32_2_2_1(%arg0: !cute.ptr<f16, gmem, align<32>>, %arg1: !cute.ptr<f16, gmem, align<32>>, %arg2: !cute.ptr<f16, gmem, align<32>>) attributes {llvm.emit_c_interface} {
    %c8 = arith.constant 8 : index
    %c49152_i32 = arith.constant 49152 : i32
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c16 = arith.constant 16 : index
    %c2_i32 = arith.constant 2 : i32
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
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_tensorop_gemmTensorOpGemm_object_at__tensorptrf16gmemalign32o51212816128165536_tensorptrf16gmemalign32o25612816128132768_tensorptrf16gmemalign32o512256162561131072_S_0 blocks in (%c8, %c1, %c16) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c49152_i32 args(%view : !memref_gmem_f16_, %view_0 : !memref_gmem_f16_1, %view_1 : !memref_gmem_f16_2, %c2_i32 : i32) {use_pdl = false}
    return
  }
}
