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
        %coord_5 = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_6 = cute.crd2idx(%coord_5, %54) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(128,1,32768)">) -> !cute.int_tuple<"?{div=32768}">
        %iter_7 = cute.get_iter(%arg1) : !memref_gmem_f16_1
        %ptr_8 = cute.add_offset(%iter_7, %idx_6) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=32768}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_9 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %73:2 = cute.get_scalars(%coord_9) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_10 = cute.make_coord(%73#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
        %idx_11 = cute.crd2idx(%coord_10, %53) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((128,1),(16384,32))">) -> !cute.int_tuple<"?{div=16384}">
        %ptr_12 = cute.add_offset(%ptr_8, %idx_11) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_13 = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_14 = cute.crd2idx(%coord_13, %52) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,16):(256,1,131072)">) -> !cute.int_tuple<"?{div=131072}">
        %iter_15 = cute.get_iter(%arg2) : !memref_gmem_f16_2
        %ptr_16 = cute.add_offset(%iter_15, %idx_14) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=131072}">) -> !cute.ptr<f16, gmem, align<32>>
        %coord_17 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %74:2 = cute.get_scalars(%coord_17) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_18 = cute.make_coord(%74#0, %74#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
        %idx_19 = cute.crd2idx(%coord_18, %51) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((256,1),(32768,128))">) -> !cute.int_tuple<"?{div=128}">
        %ptr_20 = cute.add_offset(%ptr_16, %idx_19) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f16, gmem, align<32>>
        %view = cute.make_view(%ptr_4, %50) : !memref_gmem_f16_3
        %dyn = cute.derefine(%view) : !memref_gmem_f16_3 to !memref_gmem_f16_4
        %iter_21 = cute.get_iter(%dyn) : !memref_gmem_f16_4
        %view_22 = cute.make_view(%ptr_12, %50) : !memref_gmem_f16_3
        %dyn_23 = cute.derefine(%view_22) : !memref_gmem_f16_3 to !memref_gmem_f16_4
        %iter_24 = cute.get_iter(%dyn_23) : !memref_gmem_f16_4
        %75 = cute.ptrtoint(%iter_21) : !cute.ptr<f16, gmem> to i64
        %76 = arith.addi %75, %c15_i64 : i64
        %77 = arith.andi %76, %c-16_i64 : i64
        %iv = cute.assume(%77) : (i64) -> !cute.i64<divby 16>
        %78 = cute.inttoptr(%iv) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
        %79 = cute.ptrtoint(%iter_24) : !cute.ptr<f16, gmem> to i64
        %80 = arith.addi %79, %c15_i64 : i64
        %81 = arith.andi %80, %c-16_i64 : i64
        %iv_25 = cute.assume(%81) : (i64) -> !cute.i64<divby 16>
        %82 = cute.inttoptr(%iv_25) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
        %coord_26 = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_27 = cute.crd2idx(%coord_26, %49) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup = cute.add_offset(%48, %idx_27) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %coord_28 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %83:2 = cute.get_scalars(%coord_28) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_29 = cute.make_coord(%83#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
        %idx_30 = cute.crd2idx(%coord_29, %47) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(4,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
        %tup_31 = cute.add_offset(%tup, %idx_30) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0, %e1, %e2 = cute.get_leaves(%tup_31) : !cute.int_tuple<"(?{div=128},0,?)">
        %coord_32 = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_33 = cute.crd2idx(%coord_32, %46) : (!cute.coord<"(_,_,?)">, !cute.layout<"(256,128,16):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup_34 = cute.add_offset(%48, %idx_33) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %coord_35 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %84:2 = cute.get_scalars(%coord_35) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_36 = cute.make_coord(%84#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
        %idx_37 = cute.crd2idx(%coord_36, %45) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,32),(2,4)):((1@0,1@1),(128@0,32@1))">) -> !cute.int_tuple<"(?{div=128},0)">
        %tup_38 = cute.add_offset(%tup_34, %idx_37) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_39, %e1_40, %e2_41 = cute.get_leaves(%tup_38) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple = cute.make_int_tuple(%e0, %e2) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_42, %e1_43, %e2_44 = cute.get_leaves(%int_tuple) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_45 = cute.make_int_tuple(%e0_42, %e2_44) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_46 = cute.make_int_tuple(%e0_39, %e2_41) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %e0_47, %e1_48, %e2_49 = cute.get_leaves(%int_tuple_46) : !cute.int_tuple<"(?{div=128},0,?)">
        %int_tuple_50 = cute.make_int_tuple(%e0_47, %e2_49) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},0,?)">
        %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
        %ptr_51 = cute.add_offset(%smem_ptr, %44) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"24576">) -> !cute.ptr<i8, smem, align<1024>>
        %iter_52 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %iter_53 = cute.recast_iter(%ptr_51) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %iter_54 = cute.recast_iter(%iter_52) : !cute.ptr<f16, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>>
        %coord_55 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %85 = cute.get_scalars(%coord_55) <{only_dynamic}> : !cute.coord<"?">
        %86 = arith.divsi %85, %c4_i32 : i32
        %87 = arith.remsi %85, %c4_i32 : i32
        %88 = arith.muli %87, %c8_i32 : i32
        %89 = arith.muli %86, %c128_i32 : i32
        %90 = arith.addi %88, %89 : i32
        %iv_56 = cute.assume(%90) : (i32) -> !cute.i32<divby 8>
        %int_tuple_57 = cute.make_int_tuple(%iv_56) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_58 = cute.add_offset(%78, %int_tuple_57) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %coord_59 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %91 = cute.get_scalars(%coord_59) <{only_dynamic}> : !cute.coord<"?">
        %92 = arith.divsi %91, %c4_i32 : i32
        %93 = arith.remsi %91, %c4_i32 : i32
        %94 = arith.muli %93, %c8_i32 : i32
        %95 = arith.divsi %92, %c2_i32 : i32
        %96 = arith.remsi %95, %c4_i32 : i32
        %97 = arith.muli %96, %c64_i32 : i32
        %98 = arith.addi %94, %97 : i32
        %99 = arith.divsi %91, %c4_i32 : i32
        %100 = arith.divsi %99, %c2_i32 : i32
        %101 = arith.remsi %99, %c2_i32 : i32
        %102 = arith.muli %101, %c32_i32 : i32
        %103 = arith.divsi %100, %c4_i32 : i32
        %104 = arith.muli %103, %c256_i32 : i32
        %105 = arith.addi %102, %104 : i32
        %106 = arith.andi %98, %c192_i32 : i32
        %107 = arith.shrsi %106, %c3_i32 : i32
        %108 = arith.xori %98, %107 : i32
        %109 = arith.addi %108, %105 : i32
        %iv_60 = cute.assume(%109) : (i32) -> !cute.i32<divby 8>
        %int_tuple_61 = cute.make_int_tuple(%iv_60) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_62 = cute.add_offset(%iter_52, %int_tuple_61) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %view_63 = cute.make_view(%ptr_62) : !memref_smem_f16_
        %coord_64 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %110 = cute.get_scalars(%coord_64) <{only_dynamic}> : !cute.coord<"?">
        %111 = arith.divsi %110, %c4_i32 : i32
        %112 = arith.remsi %110, %c4_i32 : i32
        %113 = arith.muli %112, %c8_i32 : i32
        %114 = arith.muli %111, %c128_i32 : i32
        %115 = arith.addi %113, %114 : i32
        %iv_65 = cute.assume(%115) : (i32) -> !cute.i32<divby 8>
        %int_tuple_66 = cute.make_int_tuple(%iv_65) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%82, %int_tuple_66) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %coord_68 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %116 = cute.get_scalars(%coord_68) <{only_dynamic}> : !cute.coord<"?">
        %117 = arith.divsi %116, %c4_i32 : i32
        %118 = arith.remsi %116, %c4_i32 : i32
        %119 = arith.muli %118, %c8_i32 : i32
        %120 = arith.divsi %117, %c2_i32 : i32
        %121 = arith.remsi %120, %c4_i32 : i32
        %122 = arith.muli %121, %c64_i32 : i32
        %123 = arith.addi %119, %122 : i32
        %124 = arith.divsi %116, %c4_i32 : i32
        %125 = arith.divsi %124, %c2_i32 : i32
        %126 = arith.remsi %124, %c2_i32 : i32
        %127 = arith.muli %126, %c32_i32 : i32
        %128 = arith.divsi %125, %c4_i32 : i32
        %129 = arith.muli %128, %c256_i32 : i32
        %130 = arith.addi %127, %129 : i32
        %131 = arith.andi %123, %c192_i32 : i32
        %132 = arith.shrsi %131, %c3_i32 : i32
        %133 = arith.xori %123, %132 : i32
        %134 = arith.addi %133, %130 : i32
        %iv_69 = cute.assume(%134) : (i32) -> !cute.i32<divby 8>
        %int_tuple_70 = cute.make_int_tuple(%iv_69) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_71 = cute.add_offset(%iter_53, %int_tuple_70) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %view_72 = cute.make_view(%ptr_71) : !memref_smem_f16_
        %coord_73 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %135 = cute.get_scalars(%coord_73) <{only_dynamic}> : !cute.coord<"?">
        %136 = arith.divsi %135, %c16_i32 : i32
        %137 = arith.remsi %135, %c16_i32 : i32
        %138 = arith.remsi %137, %c8_i32 : i32
        %139 = arith.muli %138, %c8_i32 : i32
        %140 = arith.muli %136, %c128_i32 : i32
        %141 = arith.addi %139, %140 : i32
        %142 = arith.remsi %135, %c16_i32 : i32
        %143 = arith.divsi %142, %c8_i32 : i32
        %144 = arith.muli %143, %c64_i32 : i32
        %145 = arith.andi %141, %c896_i32 : i32
        %146 = arith.shrsi %145, %c4_i32 : i32
        %147 = arith.xori %141, %146 : i32
        %148 = arith.addi %147, %144 : i32
        %iv_74 = cute.assume(%148) : (i32) -> !cute.i32<divby 8>
        %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_76 = cute.add_offset(%iter_54, %int_tuple_75) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %coord_77 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %149 = cute.get_scalars(%coord_77) <{only_dynamic}> : !cute.coord<"?">
        %150 = arith.divsi %149, %c16_i32 : i32
        %151 = arith.remsi %149, %c16_i32 : i32
        %152 = arith.muli %151, %c8_i32 : i32
        %153 = arith.muli %150, %c256_i32 : i32
        %154 = arith.addi %152, %153 : i32
        %iv_78 = cute.assume(%154) : (i32) -> !cute.i32<divby 8>
        %int_tuple_79 = cute.make_int_tuple(%iv_78) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_80 = cute.add_offset(%ptr_20, %int_tuple_79) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
        %coord_81 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %155 = cute.get_scalars(%coord_81) <{only_dynamic}> : !cute.coord<"?">
        %156 = arith.divsi %155, %c4_i32 : i32
        %157 = arith.remsi %155, %c4_i32 : i32
        %158 = arith.muli %157, %c8_i32 : i32
        %iv_82 = cute.assume(%158) : (i32) -> !cute.i32<divby 8>
        %int_tuple_83 = cute.make_int_tuple(%156, %iv_82) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
        %tup_84 = cute.add_offset(%int_tuple_45, %int_tuple_83) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %view_85 = cute.make_view(%tup_84) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %dyn_86 = cute.derefine(%view_85) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %coord_87 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %159 = cute.get_scalars(%coord_87) <{only_dynamic}> : !cute.coord<"?">
        %160 = arith.divsi %159, %c4_i32 : i32
        %161 = arith.remsi %159, %c4_i32 : i32
        %162 = arith.muli %161, %c8_i32 : i32
        %iv_88 = cute.assume(%162) : (i32) -> !cute.i32<divby 8>
        %int_tuple_89 = cute.make_int_tuple(%160, %iv_88) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
        %tup_90 = cute.add_offset(%int_tuple_50, %int_tuple_89) : (!cute.int_tuple<"(?{div=128},0,?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %view_91 = cute.make_view(%tup_90) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %dyn_92 = cute.derefine(%view_91) : !cute.coord_tensor<"(?,?{div=8},?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)"> to !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %rmem = cute.memref.alloca() : !memref_rmem_i8_
        %rmem_93 = cute.memref.alloca() : !memref_rmem_i8_
        scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0,0)">
          %idx_193 = cute.crd2idx(%coord_192, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
          %iter_194 = cute.get_iter(%dyn_86) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
          %tup_195 = cute.add_offset(%iter_194, %idx_193) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
          %e0_196, %e1_197, %e2_198 = cute.get_leaves(%tup_195) : !cute.int_tuple<"(?,?,?)">
          %coord_199 = cute.make_coord(%e0_196) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %275 = cute.get_scalars(%coord_199) : !cute.coord<"?">
          %276 = cute.get_scalars(%42) : !cute.coord<"512">
          %277 = arith.cmpi slt, %275, %276 : i32
          %278 = arith.extui %277 : i1 to i8
          %coord_200 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_201 = cute.derefine(%coord_200) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem, %dyn_201, %278) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0,0)">
          %idx_193 = cute.crd2idx(%coord_192, %43) : (!cute.coord<"((0,0),?,0,0)">, !cute.layout<"((8,1),4,1,4):((1@1,0),32@0,0,32@1)">) -> !cute.int_tuple<"(?{div=32},0)">
          %iter_194 = cute.get_iter(%dyn_92) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
          %tup_195 = cute.add_offset(%iter_194, %idx_193) : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?,?,?)">
          %e0_196, %e1_197, %e2_198 = cute.get_leaves(%tup_195) : !cute.int_tuple<"(?,?,?)">
          %coord_199 = cute.make_coord(%e0_196) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %275 = cute.get_scalars(%coord_199) : !cute.coord<"?">
          %276 = cute.get_scalars(%41) : !cute.coord<"256">
          %277 = arith.cmpi slt, %275, %276 : i32
          %278 = arith.extui %277 : i1 to i8
          %coord_200 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_201 = cute.derefine(%coord_200) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem_93, %dyn_201, %278) : (!memref_rmem_i8_, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        cute.memref.store_vec %cst_0, %view_63 : !memref_smem_f16_
        cute.memref.store_vec %cst_0, %view_72 : !memref_smem_f16_
        nvvm.barrier
        %iter_94 = cute.get_iter(%dyn_86) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %e0_95, %e1_96, %e2_97 = cute.get_leaves(%iter_94) : !cute.int_tuple<"(?,?,?)">
        %coord_98 = cute.make_coord() : () -> !cute.coord<"-1">
        %dyn_99 = cute.derefine(%coord_98) : !cute.coord<"-1"> to !cute.coord<"?">
        %coord_100 = cute.make_coord(%e1_96) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %163 = cute.get_scalars(%dyn_99) : !cute.coord<"?">
        %164 = cute.get_scalars(%coord_100) : !cute.coord<"?">
        %165 = arith.cmpi slt, %163, %164 : i32
        scf.if %165 {
          %iter_192 = cute.get_iter(%rmem) : !memref_rmem_i8_
          %275 = cute.get_scalars(%36) : !cute.int_tuple<"4">
          scf.for %arg4 = %c0_i32 to %275 step %c1_i32  : i32 {
            %coord_193 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_194 = cute.crd2idx(%coord_193, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_195 = cute.add_offset(%ptr_58, %idx_194) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_196 = cute.crd2idx(%coord_193, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_197 = cute.add_offset(%ptr_62, %idx_196) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
            %idx_198 = cute.crd2idx(%coord_193, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
            %ptr_199 = cute.add_offset(%iter_192, %idx_198) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %276 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<i8, rmem> to !llvm.ptr
            %277 = llvm.load %276 : !llvm.ptr -> i8
            %278 = llvm.trunc %277 : i8 to i1
            %iter_200 = cute.recast_iter(%ptr_195) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_201 = cute.recast_iter(%ptr_197) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_201 : !cute.ptr<i128, smem>, %iter_200 : !cute.ptr<i128, gmem>, %278 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        %iter_101 = cute.get_iter(%dyn_92) : !cute.coord_tensor<"(?,?,?)", "((8,1),4,1,4):((1@1,0),32@0,0,32@1)">
        %e0_102, %e1_103, %e2_104 = cute.get_leaves(%iter_101) : !cute.int_tuple<"(?,?,?)">
        %coord_105 = cute.make_coord() : () -> !cute.coord<"-1">
        %dyn_106 = cute.derefine(%coord_105) : !cute.coord<"-1"> to !cute.coord<"?">
        %coord_107 = cute.make_coord(%e1_103) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
        %166 = cute.get_scalars(%dyn_106) : !cute.coord<"?">
        %167 = cute.get_scalars(%coord_107) : !cute.coord<"?">
        %168 = arith.cmpi slt, %166, %167 : i32
        scf.if %168 {
          %iter_192 = cute.get_iter(%rmem_93) : !memref_rmem_i8_
          %275 = cute.get_scalars(%36) : !cute.int_tuple<"4">
          scf.for %arg4 = %c0_i32 to %275 step %c1_i32  : i32 {
            %coord_193 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_194 = cute.crd2idx(%coord_193, %39) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((4096)))">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_195 = cute.add_offset(%ptr_67, %idx_194) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_196 = cute.crd2idx(%coord_193, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
            %ptr_197 = cute.add_offset(%ptr_71, %idx_196) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
            %idx_198 = cute.crd2idx(%coord_193, %37) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4))):(4,((1)))">) -> !cute.int_tuple<"?">
            %ptr_199 = cute.add_offset(%iter_192, %idx_198) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %276 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<i8, rmem> to !llvm.ptr
            %277 = llvm.load %276 : !llvm.ptr -> i8
            %278 = llvm.trunc %277 : i8 to i1
            %iter_200 = cute.recast_iter(%ptr_195) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
            %iter_201 = cute.recast_iter(%ptr_197) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
            cute_nvgpu.arch.copy.SM80.cp_async(%iter_201 : !cute.ptr<i128, smem>, %iter_200 : !cute.ptr<i128, gmem>, %278 : i1) {cache_mode = <global>}
          } {llvm.loop_annotation = #loop_annotation}
        }
        nvvm.cp.async.commit.group
        %iter_108 = cute.get_iter(%rmem) : !memref_rmem_i8_
        %iter_109 = cute.get_iter(%rmem_93) : !memref_rmem_i8_
        %coord_110 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
        %idx_111 = cute.crd2idx(%coord_110, %40) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"32">
        %ptr_112 = cute.add_offset(%ptr_58, %idx_111) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
        %coord_113 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
        %idx_114 = cute.crd2idx(%coord_113, %35) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"4096">
        %ptr_115 = cute.add_offset(%ptr_62, %idx_114) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
        %169 = cute.get_scalars(%36) : !cute.int_tuple<"4">
        scf.for %arg4 = %c0_i32 to %169 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_194 = cute.add_offset(%ptr_112, %idx_193) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
          %idx_195 = cute.crd2idx(%coord_192, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_196 = cute.add_offset(%ptr_115, %idx_195) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_197 = cute.crd2idx(%coord_192, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
          %ptr_198 = cute.add_offset(%iter_108, %idx_197) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %275 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<i8, rmem> to !llvm.ptr
          %276 = llvm.load %275 : !llvm.ptr -> i8
          %277 = llvm.trunc %276 : i8 to i1
          %iter_199 = cute.recast_iter(%ptr_194) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_200 = cute.recast_iter(%ptr_196) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_200 : !cute.ptr<i128, smem>, %iter_199 : !cute.ptr<i128, gmem>, %277 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
        %coord_116 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
        %idx_117 = cute.crd2idx(%coord_116, %40) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"32">
        %ptr_118 = cute.add_offset(%ptr_67, %idx_117) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, gmem, align<16>>
        %coord_119 = cute.make_coord() : () -> !cute.coord<"(_,_,_,1)">
        %idx_120 = cute.crd2idx(%coord_119, %35) : (!cute.coord<"(_,_,_,1)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"4096">
        %ptr_121 = cute.add_offset(%ptr_71, %idx_120) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>>
        %170 = cute.get_scalars(%36) : !cute.int_tuple<"4">
        scf.for %arg4 = %c0_i32 to %170 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
          %ptr_194 = cute.add_offset(%ptr_118, %idx_193) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
          %idx_195 = cute.crd2idx(%coord_192, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_196 = cute.add_offset(%ptr_121, %idx_195) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_197 = cute.crd2idx(%coord_192, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
          %ptr_198 = cute.add_offset(%iter_109, %idx_197) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %275 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<i8, rmem> to !llvm.ptr
          %276 = llvm.load %275 : !llvm.ptr -> i8
          %277 = llvm.trunc %276 : i8 to i1
          %iter_199 = cute.recast_iter(%ptr_194) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_200 = cute.recast_iter(%ptr_196) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_200 : !cute.ptr<i128, smem>, %iter_199 : !cute.ptr<i128, gmem>, %277 : i1) {cache_mode = <global>}
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.commit.group
        %iter_122 = cute.get_iter(%rmem) : !memref_rmem_i8_
        %iter_123 = cute.get_iter(%rmem_93) : !memref_rmem_i8_
        %coord_124 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %171 = cute.get_scalars(%coord_124) <{only_dynamic}> : !cute.coord<"?">
        %172 = arith.remsi %171, %c32_i32 : i32
        %173 = arith.divsi %171, %c32_i32 : i32
        %174 = arith.remsi %173, %c2_i32 : i32
        %175 = arith.divsi %171, %c64_i32 : i32
        %176 = arith.remsi %175, %c2_i32 : i32
        %177 = arith.remsi %172, %c32_i32 : i32
        %178 = arith.remsi %174, %c2_i32 : i32
        %179 = arith.remsi %176, %c2_i32 : i32
        %180 = arith.divsi %177, %c4_i32 : i32
        %181 = arith.muli %180, %c128_i32 : i32
        %182 = arith.muli %179, %c8_i32 : i32
        %183 = arith.addi %181, %182 : i32
        %184 = arith.remsi %177, %c4_i32 : i32
        %185 = arith.muli %184, %c2_i32 : i32
        %186 = arith.muli %178, %c2048_i32 : i32
        %187 = arith.addi %185, %186 : i32
        %188 = arith.andi %183, %c256_i32 : i32
        %189 = arith.cmpi eq, %188, %c0_i32 : i32
        %190 = arith.select %189, %c16_i32, %c-16_i32 : i32
        %191 = arith.andi %183, %c512_i32 : i32
        %192 = arith.cmpi eq, %191, %c0_i32 : i32
        %193 = arith.select %192, %c32_i32, %c-32_i32 : i32
        %194 = arith.andi %183, %c896_i32 : i32
        %195 = arith.shrsi %194, %c4_i32 : i32
        %196 = arith.xori %183, %195 : i32
        %197 = arith.addi %196, %187 : i32
        %iv_125 = cute.assume(%197) : (i32) -> !cute.i32<divby 2>
        %int_tuple_126 = cute.make_int_tuple(%iv_125) : (!cute.i32<divby 2>) -> !cute.int_tuple<"?{div=2}">
        %ptr_127 = cute.add_offset(%iter_54, %int_tuple_126) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, smem, align<4>>
        %iv_128 = cute.assume(%190) : (i32) -> !cute.i32<divby 16>
        %iv_129 = cute.assume(%193) : (i32) -> !cute.i32<divby 32>
        %stride = cute.make_stride(%iv_128, %iv_129) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"((1,1024),4096,(?{div=16},?{div=32},64))">
        %lay = cute.make_layout(%31, %stride) : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
        %rmem_130 = cute.memref.alloca() : !memref_rmem_f16_
        %rmem_131 = cute.memref.alloca() : !memref_rmem_f16_1
        %rmem_132 = cute.memref.alloca() : !memref_rmem_f32_
        cute.memref.store_vec %cst, %rmem_132 : !memref_rmem_f32_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
        %atom_133 = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, n>
        %198 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
        %199 = cute.make_tiled_copy(%atom_133) : !copy_ldsm_4_1
        %coord_134 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %200 = cute.get_scalars(%coord_134) <{only_dynamic}> : !cute.coord<"?">
        %201 = arith.divsi %200, %c16_i32 : i32
        %202 = arith.remsi %200, %c16_i32 : i32
        %203 = arith.divsi %202, %c2_i32 : i32
        %204 = arith.remsi %203, %c4_i32 : i32
        %205 = arith.muli %204, %c64_i32 : i32
        %206 = arith.remsi %201, %c2_i32 : i32
        %207 = arith.muli %206, %c8_i32 : i32
        %208 = arith.addi %205, %207 : i32
        %209 = arith.divsi %200, %c16_i32 : i32
        %210 = arith.remsi %200, %c16_i32 : i32
        %211 = arith.divsi %210, %c2_i32 : i32
        %212 = arith.remsi %210, %c2_i32 : i32
        %213 = arith.muli %212, %c32_i32 : i32
        %214 = arith.divsi %211, %c4_i32 : i32
        %215 = arith.muli %214, %c256_i32 : i32
        %216 = arith.addi %213, %215 : i32
        %217 = arith.divsi %209, %c2_i32 : i32
        %218 = arith.remsi %217, %c2_i32 : i32
        %219 = arith.muli %218, %c512_i32 : i32
        %220 = arith.addi %216, %219 : i32
        %221 = arith.andi %208, %c128_i32 : i32
        %222 = arith.cmpi eq, %221, %c0_i32 : i32
        %223 = arith.select %222, %c16_i32, %c-16_i32 : i32
        %224 = arith.andi %208, %c192_i32 : i32
        %225 = arith.shrsi %224, %c3_i32 : i32
        %226 = arith.xori %208, %225 : i32
        %227 = arith.addi %226, %220 : i32
        %iv_135 = cute.assume(%227) : (i32) -> !cute.i32<divby 8>
        %int_tuple_136 = cute.make_int_tuple(%iv_135) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_137 = cute.add_offset(%iter_52, %int_tuple_136) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %iv_138 = cute.assume(%223) : (i32) -> !cute.i32<divby 16>
        %stride_139 = cute.make_stride(%iv_138) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
        %lay_140 = cute.make_layout(%30, %stride_139) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iter_141 = cute.get_iter(%rmem_130) : !memref_rmem_f16_
        %coord_142 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %228 = cute.get_scalars(%coord_142) <{only_dynamic}> : !cute.coord<"?">
        %229 = arith.divsi %228, %c8_i32 : i32
        %230 = arith.remsi %228, %c8_i32 : i32
        %231 = arith.divsi %230, %c2_i32 : i32
        %232 = arith.muli %231, %c64_i32 : i32
        %233 = arith.remsi %229, %c2_i32 : i32
        %234 = arith.muli %233, %c8_i32 : i32
        %235 = arith.addi %232, %234 : i32
        %236 = arith.divsi %228, %c8_i32 : i32
        %237 = arith.remsi %228, %c8_i32 : i32
        %238 = arith.remsi %237, %c2_i32 : i32
        %239 = arith.muli %238, %c32_i32 : i32
        %240 = arith.divsi %236, %c2_i32 : i32
        %241 = arith.divsi %240, %c2_i32 : i32
        %242 = arith.remsi %240, %c2_i32 : i32
        %243 = arith.muli %242, %c512_i32 : i32
        %244 = arith.addi %239, %243 : i32
        %245 = arith.divsi %241, %c2_i32 : i32
        %246 = arith.muli %245, %c256_i32 : i32
        %247 = arith.addi %244, %246 : i32
        %248 = arith.andi %235, %c128_i32 : i32
        %249 = arith.cmpi eq, %248, %c0_i32 : i32
        %250 = arith.select %249, %c16_i32, %c-16_i32 : i32
        %251 = arith.andi %235, %c192_i32 : i32
        %252 = arith.shrsi %251, %c3_i32 : i32
        %253 = arith.xori %235, %252 : i32
        %254 = arith.addi %253, %247 : i32
        %iv_143 = cute.assume(%254) : (i32) -> !cute.i32<divby 8>
        %int_tuple_144 = cute.make_int_tuple(%iv_143) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
        %ptr_145 = cute.add_offset(%iter_53, %int_tuple_144) : (!cute.ptr<f16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>>
        %iv_146 = cute.assume(%250) : (i32) -> !cute.i32<divby 16>
        %stride_147 = cute.make_stride(%iv_146) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16},(0,4096))">
        %lay_148 = cute.make_layout(%30, %stride_147) : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iter_149 = cute.get_iter(%rmem_131) : !memref_rmem_f16_1
        %255 = cute.get_scalars(%lay_140) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iv_150 = cute.assume(%255) : (i32) -> !cute.i32<divby 16>
        %stride_151 = cute.make_stride(%iv_150) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
        %lay_152 = cute.make_layout(%29, %stride_151) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
        %view_153 = cute.make_view(%ptr_137, %lay_152) : !memref_smem_f16_1
        %256 = cute.get_scalars(%lay_148) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
        %iv_154 = cute.assume(%256) : (i32) -> !cute.i32<divby 16>
        %stride_155 = cute.make_stride(%iv_154) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
        %lay_156 = cute.make_layout(%29, %stride_155) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
        %view_157 = cute.make_view(%ptr_145, %lay_156) : !memref_smem_f16_1
        nvvm.cp.async.wait.group 1
        nvvm.barrier
        %257 = cute.get_scalars(%36) : !cute.int_tuple<"4">
        scf.for %arg4 = %c0_i32 to %257 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_194 = cute.add_offset(%ptr_137, %idx_193) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_195 = cute.crd2idx(%coord_192, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_196 = cute.add_offset(%iter_141, %idx_195) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %275 = cute_nvgpu.arch.copy.ldsm %ptr_194{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
          %276 = vector.extractelement %275[%27 : i32] : vector<4xi32>
          %277 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          llvm.store %276, %277 : i32, !llvm.ptr
          %278 = vector.extractelement %275[%26 : i32] : vector<4xi32>
          %ptr_197 = cute.add_offset(%ptr_196, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
          %279 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %278, %279 : i32, !llvm.ptr
          %280 = vector.extractelement %275[%24 : i32] : vector<4xi32>
          %ptr_198 = cute.add_offset(%ptr_196, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
          %281 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %280, %281 : i32, !llvm.ptr
          %282 = vector.extractelement %275[%23 : i32] : vector<4xi32>
          %ptr_199 = cute.add_offset(%ptr_196, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
          %283 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %282, %283 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %258 = cute.get_scalars(%36) : !cute.int_tuple<"4">
        scf.for %arg4 = %c0_i32 to %258 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_194 = cute.add_offset(%ptr_145, %idx_193) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_195 = cute.crd2idx(%coord_192, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_196 = cute.add_offset(%iter_149, %idx_195) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
          %275 = cute_nvgpu.arch.copy.ldsm %ptr_194{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
          %276 = vector.extractelement %275[%27 : i32] : vector<4xi32>
          %277 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %276, %277 : i32, !llvm.ptr
          %278 = vector.extractelement %275[%26 : i32] : vector<4xi32>
          %ptr_197 = cute.add_offset(%ptr_196, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
          %279 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %278, %279 : i32, !llvm.ptr
          %280 = vector.extractelement %275[%24 : i32] : vector<4xi32>
          %ptr_198 = cute.add_offset(%ptr_196, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
          %281 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
          llvm.store %280, %281 : i32, !llvm.ptr
          %282 = vector.extractelement %275[%23 : i32] : vector<4xi32>
          %ptr_199 = cute.add_offset(%ptr_196, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
          %283 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          llvm.store %282, %283 : i32, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %259:5 = scf.for %arg4 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg5 = %view_153, %arg6 = %view_157, %arg7 = %c2_i32, %arg8 = %c2_i32, %arg9 = %c0_i32) -> (!memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32)  : i32 {
          %275:5 = scf.for %arg10 = %c0_i32 to %c2_i32 step %c1_i32 iter_args(%arg11 = %arg5, %arg12 = %arg6, %arg13 = %arg7, %arg14 = %arg8, %arg15 = %arg9) -> (!memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32)  : i32 {
            %276 = arith.cmpi eq, %arg10, %c1_i32 : i32
            %277:2 = scf.if %276 -> (!memref_smem_f16_1, !memref_smem_f16_1) {
              %coord_217 = cute.make_coord(%arg15) : (i32) -> !cute.coord<"(_,_,_,?)">
              %289 = cute.get_scalars(%lay_140) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
              %iv_218 = cute.assume(%289) : (i32) -> !cute.i32<divby 16>
              %stride_219 = cute.make_stride(%iv_218) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
              %lay_220 = cute.make_layout(%29, %stride_219) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
              %idx_221 = cute.crd2idx(%coord_217, %lay_140) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_222 = cute.add_offset(%ptr_137, %idx_221) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
              %view_223 = cute.make_view(%ptr_222, %lay_220) : !memref_smem_f16_1
              %coord_224 = cute.make_coord(%arg15) : (i32) -> !cute.coord<"(_,_,_,?)">
              %290 = cute.get_scalars(%lay_148) <{only_dynamic}> : !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">
              %iv_225 = cute.assume(%290) : (i32) -> !cute.i32<divby 16>
              %stride_226 = cute.make_stride(%iv_225) : (!cute.i32<divby 16>) -> !cute.stride<"((1,0),1024,?{div=16})">
              %lay_227 = cute.make_layout(%29, %stride_226) : !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">
              %idx_228 = cute.crd2idx(%coord_224, %lay_148) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,2,(1,3)):((1,0),1024,?{div=16},(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_229 = cute.add_offset(%ptr_145, %idx_228) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
              %view_230 = cute.make_view(%ptr_229, %lay_227) : !memref_smem_f16_1
              nvvm.cp.async.wait.group 1
              nvvm.barrier
              scf.yield %view_223, %view_230 : !memref_smem_f16_1, !memref_smem_f16_1
            } else {
              scf.yield %arg11, %arg12 : !memref_smem_f16_1, !memref_smem_f16_1
            }
            %278 = arith.addi %arg10, %c1_i32 : i32
            %279 = arith.remsi %278, %c2_i32 : i32
            %coord_192 = cute.make_coord(%279) : (i32) -> !cute.coord<"(_,_,?)">
            %lay_193 = cute.get_layout(%277#0) : !memref_smem_f16_1
            %idx_194 = cute.crd2idx(%coord_192, %lay_193) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
            %iter_195 = cute.get_iter(%277#0) : !memref_smem_f16_1
            %ptr_196 = cute.add_offset(%iter_195, %idx_194) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
            %coord_197 = cute.make_coord(%279) : (i32) -> !cute.coord<"(_,_,?)">
            %idx_198 = cute.crd2idx(%coord_197, %21) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),8,32)">) -> !cute.int_tuple<"?{div=32}">
            %ptr_199 = cute.add_offset(%iter_141, %idx_198) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
            %280 = cute.get_scalars(%36) : !cute.int_tuple<"4">
            scf.for %arg16 = %c0_i32 to %280 step %c1_i32  : i32 {
              %coord_217 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
              %idx_218 = cute.crd2idx(%coord_217, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
              %ptr_219 = cute.add_offset(%ptr_196, %idx_218) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
              %idx_220 = cute.crd2idx(%coord_217, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
              %ptr_221 = cute.add_offset(%ptr_199, %idx_220) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
              %289 = cute_nvgpu.arch.copy.ldsm %ptr_219{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
              %290 = vector.extractelement %289[%27 : i32] : vector<4xi32>
              %291 = builtin.unrealized_conversion_cast %ptr_221 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              llvm.store %290, %291 : i32, !llvm.ptr
              %292 = vector.extractelement %289[%26 : i32] : vector<4xi32>
              %ptr_222 = cute.add_offset(%ptr_221, %25) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
              %293 = builtin.unrealized_conversion_cast %ptr_222 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %292, %293 : i32, !llvm.ptr
              %294 = vector.extractelement %289[%24 : i32] : vector<4xi32>
              %ptr_223 = cute.add_offset(%ptr_221, %36) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
              %295 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %294, %295 : i32, !llvm.ptr
              %296 = vector.extractelement %289[%23 : i32] : vector<4xi32>
              %ptr_224 = cute.add_offset(%ptr_221, %22) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
              %297 = builtin.unrealized_conversion_cast %ptr_224 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %296, %297 : i32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %coord_200 = cute.make_coord(%279) : (i32) -> !cute.coord<"(_,_,?)">
            %lay_201 = cute.get_layout(%277#1) : !memref_smem_f16_1
            %idx_202 = cute.crd2idx(%coord_200, %lay_201) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),1024,?{div=16})">) -> !cute.int_tuple<"?{div=16}">
            %iter_203 = cute.get_iter(%277#1) : !memref_smem_f16_1
            %ptr_204 = cute.add_offset(%iter_203, %idx_202) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>>
            %coord_205 = cute.make_coord(%279) : (i32) -> !cute.coord<"(_,_,?)">
            %idx_206 = cute.crd2idx(%coord_205, %21) : (!cute.coord<"(_,_,?)">, !cute.layout<"((8,1),4,2):((1,0),8,32)">) -> !cute.int_tuple<"?{div=32}">
            %ptr_207 = cute.add_offset(%iter_149, %idx_206) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
            %281 = cute.get_scalars(%36) : !cute.int_tuple<"4">
            scf.for %arg16 = %c0_i32 to %281 step %c1_i32  : i32 {
              %coord_217 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
              %idx_218 = cute.crd2idx(%coord_217, %38) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((1024)))">) -> !cute.int_tuple<"?{div=1024}">
              %ptr_219 = cute.add_offset(%ptr_204, %idx_218) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
              %idx_220 = cute.crd2idx(%coord_217, %28) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
              %ptr_221 = cute.add_offset(%ptr_207, %idx_220) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
              %289 = cute_nvgpu.arch.copy.ldsm %ptr_219{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32} : <f16, smem, align<16>> -> vector<4xi32>
              %290 = vector.extractelement %289[%27 : i32] : vector<4xi32>
              %291 = builtin.unrealized_conversion_cast %ptr_221 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %290, %291 : i32, !llvm.ptr
              %292 = vector.extractelement %289[%26 : i32] : vector<4xi32>
              %ptr_222 = cute.add_offset(%ptr_221, %25) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
              %293 = builtin.unrealized_conversion_cast %ptr_222 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %292, %293 : i32, !llvm.ptr
              %294 = vector.extractelement %289[%24 : i32] : vector<4xi32>
              %ptr_223 = cute.add_offset(%ptr_221, %36) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
              %295 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
              llvm.store %294, %295 : i32, !llvm.ptr
              %296 = vector.extractelement %289[%23 : i32] : vector<4xi32>
              %ptr_224 = cute.add_offset(%ptr_221, %22) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
              %297 = builtin.unrealized_conversion_cast %ptr_224 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
              llvm.store %296, %297 : i32, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %282 = arith.cmpi eq, %arg10, %c0_i32 : i32
            scf.if %282 {
              %289 = arith.addi %arg4, %c2_i32 : i32
              %290 = arith.cmpi slt, %289, %c4_i32 : i32
              scf.if %290 {
                %coord_217 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_218 = cute.crd2idx(%coord_217, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
                %ptr_219 = cute.add_offset(%ptr_58, %idx_218) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
                %coord_220 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_221 = cute.crd2idx(%coord_220, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
                %ptr_222 = cute.add_offset(%ptr_62, %idx_221) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
                %291 = cute.get_scalars(%36) : !cute.int_tuple<"4">
                scf.for %arg16 = %c0_i32 to %291 step %c1_i32  : i32 {
                  %coord_223 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
                  %idx_224 = cute.crd2idx(%coord_223, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
                  %ptr_225 = cute.add_offset(%ptr_219, %idx_224) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
                  %idx_226 = cute.crd2idx(%coord_223, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
                  %ptr_227 = cute.add_offset(%ptr_222, %idx_226) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
                  %idx_228 = cute.crd2idx(%coord_223, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
                  %ptr_229 = cute.add_offset(%iter_122, %idx_228) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
                  %292 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<i8, rmem> to !llvm.ptr
                  %293 = llvm.load %292 : !llvm.ptr -> i8
                  %294 = llvm.trunc %293 : i8 to i1
                  %iter_230 = cute.recast_iter(%ptr_225) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
                  %iter_231 = cute.recast_iter(%ptr_227) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
                  cute_nvgpu.arch.copy.SM80.cp_async(%iter_231 : !cute.ptr<i128, smem>, %iter_230 : !cute.ptr<i128, gmem>, %294 : i1) {cache_mode = <global>}
                } {llvm.loop_annotation = #loop_annotation}
              }
            }
            %coord_208 = cute.make_coord(%arg10) : (i32) -> !cute.coord<"(_,_,?)">
            %idx_209 = cute.crd2idx(%coord_208, %20) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2,2),4,2):((1,2,4),8,32)">) -> !cute.int_tuple<"?{div=32}">
            %iter_210 = cute.get_iter(%rmem_130) : !memref_rmem_f16_
            %ptr_211 = cute.add_offset(%iter_210, %idx_209) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<16>>
            %coord_212 = cute.make_coord(%arg10) : (i32) -> !cute.coord<"(_,_,?)">
            %idx_213 = cute.crd2idx(%coord_212, %19) : (!cute.coord<"(_,_,?)">, !cute.layout<"((2,2),8,2):((1,2),4,32)">) -> !cute.int_tuple<"?{div=32}">
            %iter_214 = cute.get_iter(%rmem_131) : !memref_rmem_f16_1
            %ptr_215 = cute.add_offset(%iter_214, %idx_213) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, rmem, align<8>>
            %iter_216 = cute.get_iter(%rmem_132) : !memref_rmem_f32_
            %283 = cute.get_scalars(%15) : !cute.int_tuple<"1">
            %284 = cute.get_scalars(%36) : !cute.int_tuple<"4">
            %285 = cute.get_scalars(%14) : !cute.int_tuple<"8">
            scf.for %arg16 = %c0_i32 to %283 step %c1_i32  : i32 {
              scf.for %arg17 = %c0_i32 to %284 step %c1_i32  : i32 {
                scf.for %arg18 = %c0_i32 to %285 step %c1_i32  : i32 {
                  %coord_217 = cute.make_coord(%arg17, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
                  %coord_218 = cute.make_coord(%arg18, %arg16) : (i32, i32) -> !cute.coord<"(_,?,?)">
                  %coord_219 = cute.make_coord(%arg17, %arg18) : (i32, i32) -> !cute.coord<"(_,?,?)">
                  %idx_220 = cute.crd2idx(%coord_217, %17) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),4,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
                  %ptr_221 = cute.add_offset(%ptr_211, %idx_220) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
                  %idx_222 = cute.crd2idx(%coord_218, %16) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),8,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
                  %ptr_223 = cute.add_offset(%ptr_215, %idx_222) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
                  %idx_224 = cute.crd2idx(%coord_219, %18) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,8):((1,2),4,16)">) -> !cute.int_tuple<"?{div=4}">
                  %ptr_225 = cute.add_offset(%iter_216, %idx_224) : (!cute.ptr<f32, rmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
                  %289 = builtin.unrealized_conversion_cast %ptr_221 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
                  %290 = llvm.load %289 : !llvm.ptr -> vector<2xf16>
                  %291 = llvm.getelementptr %289[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                  %292 = llvm.load %291 : !llvm.ptr -> vector<2xf16>
                  %293 = llvm.getelementptr %289[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                  %294 = llvm.load %293 : !llvm.ptr -> vector<2xf16>
                  %295 = llvm.getelementptr %289[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                  %296 = llvm.load %295 : !llvm.ptr -> vector<2xf16>
                  %297 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
                  %298 = llvm.load %297 : !llvm.ptr -> vector<2xf16>
                  %299 = llvm.getelementptr %297[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
                  %300 = llvm.load %299 : !llvm.ptr -> vector<2xf16>
                  %301 = builtin.unrealized_conversion_cast %ptr_225 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
                  %302 = llvm.load %301 : !llvm.ptr -> f32
                  %303 = llvm.getelementptr %301[1] : (!llvm.ptr) -> !llvm.ptr, f32
                  %304 = llvm.load %303 : !llvm.ptr -> f32
                  %305 = llvm.getelementptr %301[2] : (!llvm.ptr) -> !llvm.ptr, f32
                  %306 = llvm.load %305 : !llvm.ptr -> f32
                  %307 = llvm.getelementptr %301[3] : (!llvm.ptr) -> !llvm.ptr, f32
                  %308 = llvm.load %307 : !llvm.ptr -> f32
                  %309:4 = cute_nvgpu.arch.mma.SM80 A[%290, %292, %294, %296]  B[%298, %300]  C[%302, %304, %306, %308] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
                  %310 = builtin.unrealized_conversion_cast %ptr_225 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
                  llvm.store %309#0, %310 : f32, !llvm.ptr
                  %311 = llvm.getelementptr %310[1] : (!llvm.ptr) -> !llvm.ptr, f32
                  llvm.store %309#1, %311 : f32, !llvm.ptr
                  %312 = llvm.getelementptr %310[2] : (!llvm.ptr) -> !llvm.ptr, f32
                  llvm.store %309#2, %312 : f32, !llvm.ptr
                  %313 = llvm.getelementptr %310[3] : (!llvm.ptr) -> !llvm.ptr, f32
                  llvm.store %309#3, %313 : f32, !llvm.ptr
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %286 = arith.cmpi eq, %arg10, %c0_i32 : i32
            %287 = arith.select %286, %arg15, %arg14 : i32
            %288:2 = scf.if %286 -> (i32, i32) {
              %289 = arith.addi %arg4, %c2_i32 : i32
              %290 = arith.cmpi slt, %289, %c4_i32 : i32
              scf.if %290 {
                %coord_217 = cute.make_coord(%arg13) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_218 = cute.crd2idx(%coord_217, %40) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,4):((1,0),4096,0,32)">) -> !cute.int_tuple<"?{div=32}">
                %ptr_219 = cute.add_offset(%ptr_67, %idx_218) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, gmem, align<16>>
                %coord_220 = cute.make_coord(%arg14) : (i32) -> !cute.coord<"(_,_,_,?)">
                %idx_221 = cute.crd2idx(%coord_220, %35) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),4,1,(1,3)):((1,0),1024,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
                %ptr_222 = cute.add_offset(%ptr_71, %idx_221) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>>
                %295 = cute.get_scalars(%36) : !cute.int_tuple<"4">
                scf.for %arg16 = %c0_i32 to %295 step %c1_i32  : i32 {
                  %coord_223 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
                  %idx_224 = cute.crd2idx(%coord_223, %34) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((4096,0)))">) -> !cute.int_tuple<"?{div=4096}">
                  %ptr_225 = cute.add_offset(%ptr_219, %idx_224) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, gmem, align<16>>
                  %idx_226 = cute.crd2idx(%coord_223, %33) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((4,1))):((1,0),((1024,0)))">) -> !cute.int_tuple<"?{div=1024}">
                  %ptr_227 = cute.add_offset(%ptr_222, %idx_226) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
                  %idx_228 = cute.crd2idx(%coord_223, %32) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((4,1))):(4,((1,0)))">) -> !cute.int_tuple<"?">
                  %ptr_229 = cute.add_offset(%iter_123, %idx_228) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
                  %296 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<i8, rmem> to !llvm.ptr
                  %297 = llvm.load %296 : !llvm.ptr -> i8
                  %298 = llvm.trunc %297 : i8 to i1
                  %iter_230 = cute.recast_iter(%ptr_225) : !cute.ptr<f16, gmem, align<16>> to !cute.ptr<i128, gmem>
                  %iter_231 = cute.recast_iter(%ptr_227) : !cute.ptr<f16, smem, align<16>> to !cute.ptr<i128, smem>
                  cute_nvgpu.arch.copy.SM80.cp_async(%iter_231 : !cute.ptr<i128, smem>, %iter_230 : !cute.ptr<i128, gmem>, %298 : i1) {cache_mode = <global>}
                } {llvm.loop_annotation = #loop_annotation}
              }
              %291 = arith.addi %arg13, %c1_i32 : i32
              nvvm.cp.async.commit.group
              %292 = arith.addi %arg15, %c1_i32 : i32
              %293 = arith.cmpi eq, %292, %c3_i32 : i32
              %294 = arith.select %293, %c0_i32, %292 : i32
              scf.yield %291, %294 : i32, i32
            } else {
              scf.yield %arg13, %arg15 : i32, i32
            }
            scf.yield %277#0, %277#1, %288#0, %287, %288#1 : !memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          scf.yield %275#0, %275#1, %275#2, %275#3, %275#4 : !memref_smem_f16_1, !memref_smem_f16_1, i32, i32, i32
        }
        nvvm.cp.async.wait.group 0
        nvvm.barrier
        %rmem_158 = cute.memref.alloca() : !memref_rmem_f16_2
        %260 = cute.memref.load_vec %rmem_132 : !memref_rmem_f32_
        %261 = arith.truncf %260 : vector<128xf32> to vector<128xf16>
        %iter_159 = cute.get_iter(%rmem_158) : !memref_rmem_f16_2
        %view_160 = cute.make_view(%iter_159) : !memref_rmem_f16_2
        cute.memref.store_vec %261, %view_160 : !memref_rmem_f16_2
        %iter_161 = cute.get_iter(%rmem_158) : !memref_rmem_f16_2
        %262:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((2,2),4,(2,2,2)):((1,1024),4096,(?{div=16},?{div=32},64))">
        %iv_162 = cute.assume(%262#0) : (i32) -> !cute.i32<divby 16>
        %iv_163 = cute.assume(%262#1) : (i32) -> !cute.i32<divby 32>
        %stride_164 = cute.make_stride(%iv_162, %iv_163) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
        %lay_165 = cute.make_layout(%13, %stride_164) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %263:2 = cute.get_scalars(%lay_165) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %iv_166 = cute.assume(%263#0) : (i32) -> !cute.i32<divby 16>
        %iv_167 = cute.assume(%263#1) : (i32) -> !cute.i32<divby 32>
        %stride_168 = cute.make_stride(%iv_166, %iv_167) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,(1024,4096,?{div=16},?{div=32},64))">
        %lay_169 = cute.make_layout(%13, %stride_168) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %append = cute.append_to_rank<2> (%lay_169, %57) : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">, !cute.layout<"1:0">
        %264:2 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,(2,4,2,2,2)):(1,(1024,4096,?{div=16},?{div=32},64))">
        %iv_170 = cute.assume(%264#0) : (i32) -> !cute.i32<divby 16>
        %iv_171 = cute.assume(%264#1) : (i32) -> !cute.i32<divby 32>
        %stride_172 = cute.make_stride(%iv_170, %iv_171) : (!cute.i32<divby 16>, !cute.i32<divby 32>) -> !cute.stride<"(1,((1024,4096,?{div=16},?{div=32},64)))">
        %lay_173 = cute.make_layout(%11, %stride_172) : !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">
        %265 = cute.get_scalars(%10) : !cute.int_tuple<"64">
        scf.for %arg4 = %c0_i32 to %265 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %12) : (!cute.coord<"(_,?)">, !cute.layout<"(2,(64)):(1,(2))">) -> !cute.int_tuple<"?{div=2}">
          %ptr_194 = cute.add_offset(%iter_161, %idx_193) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, rmem, align<4>>
          %idx_195 = cute.crd2idx(%coord_192, %lay_173) : (!cute.coord<"(_,?)">, !cute.layout<"(2,((2,4,2,2,2))):(1,((1024,4096,?{div=16},?{div=32},64)))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_196 = cute.add_offset(%ptr_127, %idx_195) : (!cute.ptr<f16, smem, align<4>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<4>>
          %275 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
          %276 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, smem, align<4>> to !llvm.ptr<3>
          %277 = llvm.load %275 {alignment = 4 : i64} : !llvm.ptr -> vector<2xf16>
          llvm.store %277, %276 {alignment = 4 : i64} : vector<2xf16>, !llvm.ptr<3>
        } {llvm.loop_annotation = #loop_annotation}
        %coord_174 = cute.make_coord(%61) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_175 = cute.crd2idx(%coord_174, %9) : (!cute.coord<"(_,_,?)">, !cute.layout<"(512,256,1):(1@0,1@1,1@2)">) -> !cute.int_tuple<"(0,0,?)">
        %tup_176 = cute.add_offset(%48, %idx_175) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,0,?)">) -> !cute.int_tuple<"(0,0,?)">
        %coord_177 = cute.make_coord(%62, %65) : (i32, i32) -> !cute.coord<"(?,?,_)">
        %266:2 = cute.get_scalars(%coord_177) <{only_dynamic}> : !cute.coord<"(?,?,_)">
        %coord_178 = cute.make_coord(%266#0, %266#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
        %idx_179 = cute.crd2idx(%coord_178, %8) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,128),(4,2)):((1@0,1@1),(128@0,128@1))">) -> !cute.int_tuple<"(?{div=128},?{div=128})">
        %tup_180 = cute.add_offset(%tup_176, %idx_179) : (!cute.int_tuple<"(0,0,?)">, !cute.int_tuple<"(?{div=128},?{div=128})">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
        %coord_181 = cute.make_coord(%58) : (i32) -> !cute.coord<"?">
        %267 = cute.get_scalars(%coord_181) <{only_dynamic}> : !cute.coord<"?">
        %268 = arith.divsi %267, %c16_i32 : i32
        %269 = arith.remsi %267, %c16_i32 : i32
        %270 = arith.muli %269, %c8_i32 : i32
        %iv_182 = cute.assume(%270) : (i32) -> !cute.i32<divby 8>
        %int_tuple_183 = cute.make_int_tuple(%268, %iv_182) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
        %tup_184 = cute.add_offset(%tup_180, %int_tuple_183) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
        %rmem_185 = cute.memref.alloca() : !memref_rmem_f16_3
        nvvm.barrier
        %iter_186 = cute.get_iter(%rmem_185) : !memref_rmem_f16_3
        %271 = cute.get_scalars(%5) : !cute.int_tuple<"16">
        scf.for %arg4 = %c0_i32 to %271 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_193 = cute.crd2idx(%coord_192, %7) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(1024))">) -> !cute.int_tuple<"?{div=1024}">
          %ptr_194 = cute.add_offset(%ptr_76, %idx_193) : (!cute.ptr<f16, smem, align<16>>, !cute.int_tuple<"?{div=1024}">) -> !cute.ptr<f16, smem, align<16>>
          %idx_195 = cute.crd2idx(%coord_192, %6) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(16)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_196 = cute.add_offset(%iter_186, %idx_195) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %275 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<f16, smem, align<16>> to !llvm.ptr<3>
          %276 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          %277 = llvm.load %275 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xf16>
          llvm.store %277, %276 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %rmem_187 = cute.memref.alloca() : !memref_rmem_i8_1
        scf.for %arg4 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
          %coord_192 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"((0,0),?,0)">
          %idx_193 = cute.crd2idx(%coord_192, %4) : (!cute.coord<"((0,0),?,0)">, !cute.layout<"((8,1),16,1):((1@1,0),8@0,0)">) -> !cute.int_tuple<"(?{div=8},0)">
          %tup_194 = cute.add_offset(%tup_184, %idx_193) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(?{div=8},0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
          %e0_195, %e1_196, %e2_197 = cute.get_leaves(%tup_194) : !cute.int_tuple<"(?,?{div=8},?)">
          %coord_198 = cute.make_coord(%e0_195) : (!cute.int_tuple<"?">) -> !cute.coord<"?">
          %275 = cute.get_scalars(%coord_198) : !cute.coord<"?">
          %276 = cute.get_scalars(%42) : !cute.coord<"512">
          %277 = arith.cmpi slt, %275, %276 : i32
          %278 = arith.extui %277 : i1 to i8
          %coord_199 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(0,?,0)">
          %dyn_200 = cute.derefine(%coord_199) : !cute.coord<"(0,?,0)"> to !cute.coord<"(?,?,0)">
          cute.memref.store(%rmem_187, %dyn_200, %278) : (!memref_rmem_i8_1, !cute.coord<"(?,?,0)">, i8) -> ()
        }
        %e0_188, %e1_189, %e2_190 = cute.get_leaves(%tup_184) : !cute.int_tuple<"(?,?{div=8},?)">
        %coord_191 = cute.make_coord(%e1_189) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
        %272 = cute.get_scalars(%coord_191) : !cute.coord<"?{div=8}">
        %273 = cute.get_scalars(%41) : !cute.coord<"256">
        %274 = arith.cmpi slt, %272, %273 : i32
        scf.if %274 {
          %iter_192 = cute.get_iter(%rmem_185) : !memref_rmem_f16_3
          %iter_193 = cute.get_iter(%rmem_187) : !memref_rmem_i8_1
          %275 = cute.get_scalars(%5) : !cute.int_tuple<"16">
          scf.for %arg4 = %c0_i32 to %275 step %c1_i32  : i32 {
            %coord_194 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
            %idx_195 = cute.crd2idx(%coord_194, %3) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
            %ptr_196 = cute.add_offset(%iter_192, %idx_195) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
            %idx_197 = cute.crd2idx(%coord_194, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((16))):((1,0),((2048)))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_198 = cute.add_offset(%ptr_80, %idx_197) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f16, gmem, align<16>>
            %idx_199 = cute.crd2idx(%coord_194, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(1,((16))):(16,((1)))">) -> !cute.int_tuple<"?">
            %ptr_200 = cute.add_offset(%iter_193, %idx_199) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
            %276 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<i8, rmem> to !llvm.ptr
            %277 = llvm.load %276 : !llvm.ptr -> i8
            %278 = llvm.icmp "ne" %277, %0 : i8
            scf.if %278 {
              %279 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %280 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
              %281 = llvm.load %279 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %281, %280 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
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
