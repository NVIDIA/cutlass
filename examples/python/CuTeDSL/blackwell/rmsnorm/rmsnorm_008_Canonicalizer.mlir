!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_1, %arg2: !memref_gmem_bf16_, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %cst = arith.constant 4.096000e+03 : f32
      %c32_i32 = arith.constant 32 : i32
      %c4_i32 = arith.constant 4 : i32
      %c31_i32 = arith.constant 31 : i32
      %c16_i32 = arith.constant 16 : i32
      %c-1_i32 = arith.constant -1 : i32
      %cst_0 = arith.constant 0.000000e+00 : f32
      %0 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %1 = cute.static : !cute.layout<"(8,(8)):(1,(512))">
      %2 = cute.static : !cute.int_tuple<"56">
      %3 = cute.static : !cute.int_tuple<"48">
      %4 = cute.static : !cute.int_tuple<"40">
      %5 = cute.static : !cute.int_tuple<"32">
      %6 = cute.static : !cute.int_tuple<"24">
      %7 = cute.static : !cute.int_tuple<"16">
      %8 = cute.static : !cute.int_tuple<"8">
      %9 = llvm.mlir.constant(0 : i8) : i8
      %10 = cute.static : !cute.int_tuple<"7">
      %11 = cute.static : !cute.int_tuple<"3584">
      %12 = cute.static : !cute.int_tuple<"6">
      %13 = cute.static : !cute.int_tuple<"3072">
      %14 = cute.static : !cute.int_tuple<"5">
      %15 = cute.static : !cute.int_tuple<"2560">
      %16 = cute.static : !cute.int_tuple<"4">
      %17 = cute.static : !cute.int_tuple<"2048">
      %18 = cute.static : !cute.int_tuple<"3">
      %19 = cute.static : !cute.int_tuple<"1536">
      %20 = cute.static : !cute.int_tuple<"2">
      %21 = cute.static : !cute.int_tuple<"1024">
      %22 = cute.static : !cute.int_tuple<"512">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %23 = cute.static : !cute.int_tuple<"1">
      %24 = cute.static : !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %25 = cute.static : !cute.coord<"(7,0,0)">
      %26 = cute.static : !cute.int_tuple<"(0,3584)">
      %27 = cute.static : !cute.coord<"(6,0,0)">
      %28 = cute.static : !cute.int_tuple<"(0,3072)">
      %29 = cute.static : !cute.coord<"(5,0,0)">
      %30 = cute.static : !cute.int_tuple<"(0,2560)">
      %31 = cute.static : !cute.coord<"(4,0,0)">
      %32 = cute.static : !cute.int_tuple<"(0,2048)">
      %33 = cute.static : !cute.coord<"(3,0,0)">
      %34 = cute.static : !cute.int_tuple<"(0,1536)">
      %35 = cute.static : !cute.coord<"(2,0,0)">
      %36 = cute.static : !cute.int_tuple<"(0,1024)">
      %37 = cute.static : !cute.coord<"(1,0,0)">
      %38 = cute.static : !cute.int_tuple<"(0,512)">
      %39 = cute.static : !cute.coord<"(0,0,0)">
      %40 = cute.static : !cute.coord<"4096">
      %c4096_i32 = arith.constant 4096 : i32
      %c8_i32 = arith.constant 8 : i32
      %c64_i32 = arith.constant 64 : i32
      %41 = cute.static : !cute.stride<"((1@0,1@1),(2@0,0))">
      %42 = cute.static : !cute.stride<"((4096,1),(8192,0))">
      %c2_i32 = arith.constant 2 : i32
      %43 = cute.static : !cute.stride<"(1@0,1@1)">
      %44 = cute.static : !cute.int_tuple<"(0,0)">
      %45 = cute.static : !cute.layout<"(2,2):(1,2)">
      %46 = cute.static : !cute.int_tuple<"16384">
      %iter = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %47 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %48 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %49 = cute.get_shape(%lay) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0, %e1 = cute.get_leaves(%49) : !cute.shape<"(?,4096)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %50 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %46) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_1 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %iter_2 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view = cute.make_view(%iter_2, %45) : !memref_smem_f32_
      %shape = cute.make_shape(%itup) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %lay_3 = cute.make_layout(%shape, %43) : !cute.layout<"(?,4096):(1@0,1@1)">
      %coord = cute.make_coord(%48) : (i32) -> !cute.coord<"(?,0)">
      %51 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_4 = cute.make_coord(%51) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_5 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %52 = cute.get_scalars(%lay_5) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %53 = arith.ceildivsi %52, %c2_i32 : i32
      %shape_6 = cute.make_shape(%53) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_7 = cute.make_layout(%shape_6, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx = cute.crd2idx(%coord_4, %lay_7) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_8 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_9 = cute.add_offset(%iter_8, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_10 = cute.make_coord(%48) : (i32) -> !cute.coord<"(?,0)">
      %54 = cute.get_scalars(%coord_10) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_11 = cute.make_coord(%54) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_12 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %55 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %56 = arith.ceildivsi %55, %c2_i32 : i32
      %shape_13 = cute.make_shape(%56) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_14 = cute.make_layout(%shape_13, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_15 = cute.crd2idx(%coord_11, %lay_14) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_16 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_17 = cute.add_offset(%iter_16, %idx_15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_18 = cute.make_coord(%48) : (i32) -> !cute.coord<"(?,0)">
      %57 = cute.get_scalars(%coord_18) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_19 = cute.make_coord(%57) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %58 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %59 = arith.ceildivsi %58, %c2_i32 : i32
      %shape_20 = cute.make_shape(%59) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_21 = cute.make_layout(%shape_20, %41) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_22 = cute.crd2idx(%coord_19, %lay_21) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %tup = cute.add_offset(%44, %idx_22) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_23 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_24 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %60 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %61 = cute.make_tiled_copy(%atom_23) : !copy_simt
      %62 = cute.make_tiled_copy(%atom_24) : !copy_simt
      %coord_25 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %63 = cute.get_scalars(%coord_25) <{only_dynamic}> : !cute.coord<"?">
      %64 = arith.divsi %63, %c64_i32 : i32
      %65 = arith.remsi %63, %c64_i32 : i32
      %66 = arith.muli %65, %c8_i32 : i32
      %67 = arith.muli %64, %c4096_i32 : i32
      %68 = arith.addi %66, %67 : i32
      %iv = cute.assume(%68) : (i32) -> !cute.i32<divby 8>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_26 = cute.add_offset(%ptr_9, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_27 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %69 = cute.get_scalars(%coord_27) <{only_dynamic}> : !cute.coord<"?">
      %70 = arith.divsi %69, %c64_i32 : i32
      %71 = arith.remsi %69, %c64_i32 : i32
      %72 = arith.muli %71, %c8_i32 : i32
      %73 = arith.muli %70, %c4096_i32 : i32
      %74 = arith.addi %72, %73 : i32
      %iv_28 = cute.assume(%74) : (i32) -> !cute.i32<divby 8>
      %int_tuple_29 = cute.make_int_tuple(%iv_28) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_30 = cute.add_offset(%iter_1, %int_tuple_29) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %coord_31 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %75 = cute.get_scalars(%coord_31) <{only_dynamic}> : !cute.coord<"?">
      %76 = arith.divsi %75, %c64_i32 : i32
      %77 = arith.remsi %75, %c64_i32 : i32
      %78 = arith.muli %77, %c8_i32 : i32
      %79 = arith.muli %76, %c4096_i32 : i32
      %80 = arith.addi %78, %79 : i32
      %iv_32 = cute.assume(%80) : (i32) -> !cute.i32<divby 8>
      %int_tuple_33 = cute.make_int_tuple(%iv_32) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_34 = cute.add_offset(%ptr_17, %int_tuple_33) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %coord_35 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %81 = cute.get_scalars(%coord_35) <{only_dynamic}> : !cute.coord<"?">
      %82 = arith.divsi %81, %c64_i32 : i32
      %83 = arith.remsi %81, %c64_i32 : i32
      %84 = arith.muli %83, %c8_i32 : i32
      %iv_36 = cute.assume(%84) : (i32) -> !cute.i32<divby 8>
      %int_tuple_37 = cute.make_int_tuple(%82, %iv_36) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_38 = cute.add_offset(%tup, %int_tuple_37) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_39 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_40 = cute.get_iter(%rmem_39) : !memref_rmem_bf16_
      %coord_41 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %85 = cute.get_scalars(%coord_41) <{only_dynamic}> : !cute.coord<"?">
      %86 = arith.remsi %85, %c64_i32 : i32
      %87 = arith.muli %86, %c8_i32 : i32
      %iv_42 = cute.assume(%87) : (i32) -> !cute.i32<divby 8>
      %int_tuple_43 = cute.make_int_tuple(%iv_42) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_44 = cute.add_offset(%iter, %int_tuple_43) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %rmem_45 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_46 = cute.get_iter(%rmem_45) : !memref_rmem_bf16_
      %iter_47 = cute.get_iter(%rmem_45) : !memref_rmem_bf16_
      %view_48 = cute.make_view(%iter_47) : !memref_rmem_bf16_
      %rmem_49 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_50 = cute.get_iter(%rmem_49) : !memref_rmem_i8_
      %e0_51, %e1_52 = cute.get_leaves(%tup_38) : !cute.int_tuple<"(?,?{div=8})">
      %coord_53 = cute.make_coord(%e1_52) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %88 = cute.get_scalars(%coord_53) : !cute.coord<"?{div=8}">
      %89 = cute.get_scalars(%40) : !cute.coord<"4096">
      %90 = arith.cmpi slt, %88, %89 : i32
      %91 = arith.extui %90 : i1 to i8
      cute.memref.store(%rmem_49, %39, %91) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_54 = cute.add_offset(%tup_38, %38) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_55, %e1_56 = cute.get_leaves(%tup_54) : !cute.int_tuple<"(?,?{div=8})">
      %coord_57 = cute.make_coord(%e1_56) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %92 = cute.get_scalars(%coord_57) : !cute.coord<"?{div=8}">
      %93 = cute.get_scalars(%40) : !cute.coord<"4096">
      %94 = arith.cmpi slt, %92, %93 : i32
      %95 = arith.extui %94 : i1 to i8
      cute.memref.store(%rmem_49, %37, %95) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %tup_58 = cute.add_offset(%tup_38, %36) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_59, %e1_60 = cute.get_leaves(%tup_58) : !cute.int_tuple<"(?,?{div=8})">
      %coord_61 = cute.make_coord(%e1_60) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %96 = cute.get_scalars(%coord_61) : !cute.coord<"?{div=8}">
      %97 = cute.get_scalars(%40) : !cute.coord<"4096">
      %98 = arith.cmpi slt, %96, %97 : i32
      %99 = arith.extui %98 : i1 to i8
      cute.memref.store(%rmem_49, %35, %99) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %tup_62 = cute.add_offset(%tup_38, %34) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_63, %e1_64 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?{div=8})">
      %coord_65 = cute.make_coord(%e1_64) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %100 = cute.get_scalars(%coord_65) : !cute.coord<"?{div=8}">
      %101 = cute.get_scalars(%40) : !cute.coord<"4096">
      %102 = arith.cmpi slt, %100, %101 : i32
      %103 = arith.extui %102 : i1 to i8
      cute.memref.store(%rmem_49, %33, %103) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %tup_66 = cute.add_offset(%tup_38, %32) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_67, %e1_68 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?,?{div=8})">
      %coord_69 = cute.make_coord(%e1_68) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %104 = cute.get_scalars(%coord_69) : !cute.coord<"?{div=8}">
      %105 = cute.get_scalars(%40) : !cute.coord<"4096">
      %106 = arith.cmpi slt, %104, %105 : i32
      %107 = arith.extui %106 : i1 to i8
      cute.memref.store(%rmem_49, %31, %107) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %tup_70 = cute.add_offset(%tup_38, %30) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_71, %e1_72 = cute.get_leaves(%tup_70) : !cute.int_tuple<"(?,?{div=8})">
      %coord_73 = cute.make_coord(%e1_72) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %108 = cute.get_scalars(%coord_73) : !cute.coord<"?{div=8}">
      %109 = cute.get_scalars(%40) : !cute.coord<"4096">
      %110 = arith.cmpi slt, %108, %109 : i32
      %111 = arith.extui %110 : i1 to i8
      cute.memref.store(%rmem_49, %29, %111) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %tup_74 = cute.add_offset(%tup_38, %28) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_75, %e1_76 = cute.get_leaves(%tup_74) : !cute.int_tuple<"(?,?{div=8})">
      %coord_77 = cute.make_coord(%e1_76) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %112 = cute.get_scalars(%coord_77) : !cute.coord<"?{div=8}">
      %113 = cute.get_scalars(%40) : !cute.coord<"4096">
      %114 = arith.cmpi slt, %112, %113 : i32
      %115 = arith.extui %114 : i1 to i8
      cute.memref.store(%rmem_49, %27, %115) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %tup_78 = cute.add_offset(%tup_38, %26) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_79, %e1_80 = cute.get_leaves(%tup_78) : !cute.int_tuple<"(?,?{div=8})">
      %coord_81 = cute.make_coord(%e1_80) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %116 = cute.get_scalars(%coord_81) : !cute.coord<"?{div=8}">
      %117 = cute.get_scalars(%40) : !cute.coord<"4096">
      %118 = arith.cmpi slt, %116, %117 : i32
      %119 = arith.extui %118 : i1 to i8
      cute.memref.store(%rmem_49, %25, %119) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %e0_82, %e1_83 = cute.get_leaves(%tup_38) : !cute.int_tuple<"(?,?{div=8})">
      %120 = cute.get_scalars(%e0_82) : !cute.int_tuple<"?">
      %121 = arith.cmpi slt, %120, %50 : i32
      scf.if %121 {
        %213 = cute.get_scalars(%23) : !cute.int_tuple<"1">
        scf.for %arg4 = %c0_i32 to %213 step %c1_i32  : i32 {
          %coord_123 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_124 = cute.crd2idx(%coord_123, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_125 = cute.add_offset(%iter_50, %idx_124) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %214 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
          %215 = llvm.load %214 : !llvm.ptr -> i8
          %216 = llvm.trunc %215 : i8 to i1
          %iter_126 = cute.recast_iter(%ptr_26) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_127 = cute.recast_iter(%ptr_30) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_127 : !cute.ptr<i128, smem>, %iter_126 : !cute.ptr<i128, gmem>, %216 : i1) {cache_mode = <always>}
          %ptr_128 = cute.add_offset(%ptr_26, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_129 = cute.add_offset(%ptr_30, %22) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_130 = cute.add_offset(%ptr_125, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %217 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i8, rmem> to !llvm.ptr
          %218 = llvm.load %217 : !llvm.ptr -> i8
          %219 = llvm.trunc %218 : i8 to i1
          %iter_131 = cute.recast_iter(%ptr_128) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_132 = cute.recast_iter(%ptr_129) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_132 : !cute.ptr<i128, smem>, %iter_131 : !cute.ptr<i128, gmem>, %219 : i1) {cache_mode = <always>}
          %ptr_133 = cute.add_offset(%ptr_26, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%ptr_30, %21) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_135 = cute.add_offset(%ptr_125, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %220 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i8, rmem> to !llvm.ptr
          %221 = llvm.load %220 : !llvm.ptr -> i8
          %222 = llvm.trunc %221 : i8 to i1
          %iter_136 = cute.recast_iter(%ptr_133) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_137 = cute.recast_iter(%ptr_134) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_137 : !cute.ptr<i128, smem>, %iter_136 : !cute.ptr<i128, gmem>, %222 : i1) {cache_mode = <always>}
          %ptr_138 = cute.add_offset(%ptr_26, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_139 = cute.add_offset(%ptr_30, %19) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_140 = cute.add_offset(%ptr_125, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %223 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<i8, rmem> to !llvm.ptr
          %224 = llvm.load %223 : !llvm.ptr -> i8
          %225 = llvm.trunc %224 : i8 to i1
          %iter_141 = cute.recast_iter(%ptr_138) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_142 = cute.recast_iter(%ptr_139) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_142 : !cute.ptr<i128, smem>, %iter_141 : !cute.ptr<i128, gmem>, %225 : i1) {cache_mode = <always>}
          %ptr_143 = cute.add_offset(%ptr_26, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_144 = cute.add_offset(%ptr_30, %17) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_145 = cute.add_offset(%ptr_125, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %226 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i8, rmem> to !llvm.ptr
          %227 = llvm.load %226 : !llvm.ptr -> i8
          %228 = llvm.trunc %227 : i8 to i1
          %iter_146 = cute.recast_iter(%ptr_143) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_147 = cute.recast_iter(%ptr_144) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_147 : !cute.ptr<i128, smem>, %iter_146 : !cute.ptr<i128, gmem>, %228 : i1) {cache_mode = <always>}
          %ptr_148 = cute.add_offset(%ptr_26, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_149 = cute.add_offset(%ptr_30, %15) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_150 = cute.add_offset(%ptr_125, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %229 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<i8, rmem> to !llvm.ptr
          %230 = llvm.load %229 : !llvm.ptr -> i8
          %231 = llvm.trunc %230 : i8 to i1
          %iter_151 = cute.recast_iter(%ptr_148) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_152 = cute.recast_iter(%ptr_149) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_152 : !cute.ptr<i128, smem>, %iter_151 : !cute.ptr<i128, gmem>, %231 : i1) {cache_mode = <always>}
          %ptr_153 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_154 = cute.add_offset(%ptr_30, %13) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_155 = cute.add_offset(%ptr_125, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %232 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<i8, rmem> to !llvm.ptr
          %233 = llvm.load %232 : !llvm.ptr -> i8
          %234 = llvm.trunc %233 : i8 to i1
          %iter_156 = cute.recast_iter(%ptr_153) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_157 = cute.recast_iter(%ptr_154) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_157 : !cute.ptr<i128, smem>, %iter_156 : !cute.ptr<i128, gmem>, %234 : i1) {cache_mode = <always>}
          %ptr_158 = cute.add_offset(%ptr_26, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_159 = cute.add_offset(%ptr_30, %11) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
          %ptr_160 = cute.add_offset(%ptr_125, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %235 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
          %236 = llvm.load %235 : !llvm.ptr -> i8
          %237 = llvm.trunc %236 : i8 to i1
          %iter_161 = cute.recast_iter(%ptr_158) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_162 = cute.recast_iter(%ptr_159) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_162 : !cute.ptr<i128, smem>, %iter_161 : !cute.ptr<i128, gmem>, %237 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %coord_84 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %122 = cute.get_scalars(%coord_84) <{only_dynamic}> : !cute.coord<"?">
      %123 = arith.divsi %122, %c64_i32 : i32
      %124 = arith.remsi %122, %c64_i32 : i32
      %125 = arith.muli %124, %c8_i32 : i32
      %iv_85 = cute.assume(%125) : (i32) -> !cute.i32<divby 8>
      %int_tuple_86 = cute.make_int_tuple(%123, %iv_85) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_87 = cute.add_offset(%tup, %int_tuple_86) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %rmem_88 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_89 = cute.get_iter(%rmem_88) : !memref_rmem_i8_
      %e0_90, %e1_91 = cute.get_leaves(%tup_87) : !cute.int_tuple<"(?,?{div=8})">
      %coord_92 = cute.make_coord(%e1_91) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %126 = cute.get_scalars(%coord_92) : !cute.coord<"?{div=8}">
      %127 = cute.get_scalars(%40) : !cute.coord<"4096">
      %128 = arith.cmpi slt, %126, %127 : i32
      %129 = arith.extui %128 : i1 to i8
      cute.memref.store(%rmem_88, %39, %129) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_93 = cute.add_offset(%tup_87, %38) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_94, %e1_95 = cute.get_leaves(%tup_93) : !cute.int_tuple<"(?,?{div=8})">
      %coord_96 = cute.make_coord(%e1_95) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %130 = cute.get_scalars(%coord_96) : !cute.coord<"?{div=8}">
      %131 = cute.get_scalars(%40) : !cute.coord<"4096">
      %132 = arith.cmpi slt, %130, %131 : i32
      %133 = arith.extui %132 : i1 to i8
      cute.memref.store(%rmem_88, %37, %133) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %tup_97 = cute.add_offset(%tup_87, %36) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_98, %e1_99 = cute.get_leaves(%tup_97) : !cute.int_tuple<"(?,?{div=8})">
      %coord_100 = cute.make_coord(%e1_99) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %134 = cute.get_scalars(%coord_100) : !cute.coord<"?{div=8}">
      %135 = cute.get_scalars(%40) : !cute.coord<"4096">
      %136 = arith.cmpi slt, %134, %135 : i32
      %137 = arith.extui %136 : i1 to i8
      cute.memref.store(%rmem_88, %35, %137) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %tup_101 = cute.add_offset(%tup_87, %34) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_102, %e1_103 = cute.get_leaves(%tup_101) : !cute.int_tuple<"(?,?{div=8})">
      %coord_104 = cute.make_coord(%e1_103) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %138 = cute.get_scalars(%coord_104) : !cute.coord<"?{div=8}">
      %139 = cute.get_scalars(%40) : !cute.coord<"4096">
      %140 = arith.cmpi slt, %138, %139 : i32
      %141 = arith.extui %140 : i1 to i8
      cute.memref.store(%rmem_88, %33, %141) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %tup_105 = cute.add_offset(%tup_87, %32) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_106, %e1_107 = cute.get_leaves(%tup_105) : !cute.int_tuple<"(?,?{div=8})">
      %coord_108 = cute.make_coord(%e1_107) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %142 = cute.get_scalars(%coord_108) : !cute.coord<"?{div=8}">
      %143 = cute.get_scalars(%40) : !cute.coord<"4096">
      %144 = arith.cmpi slt, %142, %143 : i32
      %145 = arith.extui %144 : i1 to i8
      cute.memref.store(%rmem_88, %31, %145) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %tup_109 = cute.add_offset(%tup_87, %30) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_110, %e1_111 = cute.get_leaves(%tup_109) : !cute.int_tuple<"(?,?{div=8})">
      %coord_112 = cute.make_coord(%e1_111) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %146 = cute.get_scalars(%coord_112) : !cute.coord<"?{div=8}">
      %147 = cute.get_scalars(%40) : !cute.coord<"4096">
      %148 = arith.cmpi slt, %146, %147 : i32
      %149 = arith.extui %148 : i1 to i8
      cute.memref.store(%rmem_88, %29, %149) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %tup_113 = cute.add_offset(%tup_87, %28) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_114, %e1_115 = cute.get_leaves(%tup_113) : !cute.int_tuple<"(?,?{div=8})">
      %coord_116 = cute.make_coord(%e1_115) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %150 = cute.get_scalars(%coord_116) : !cute.coord<"?{div=8}">
      %151 = cute.get_scalars(%40) : !cute.coord<"4096">
      %152 = arith.cmpi slt, %150, %151 : i32
      %153 = arith.extui %152 : i1 to i8
      cute.memref.store(%rmem_88, %27, %153) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %tup_117 = cute.add_offset(%tup_87, %26) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_118, %e1_119 = cute.get_leaves(%tup_117) : !cute.int_tuple<"(?,?{div=8})">
      %coord_120 = cute.make_coord(%e1_119) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %154 = cute.get_scalars(%coord_120) : !cute.coord<"?{div=8}">
      %155 = cute.get_scalars(%40) : !cute.coord<"4096">
      %156 = arith.cmpi slt, %154, %155 : i32
      %157 = arith.extui %156 : i1 to i8
      cute.memref.store(%rmem_88, %25, %157) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %158 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      scf.for %arg4 = %c0_i32 to %158 step %c1_i32  : i32 {
        %coord_123 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_124 = cute.crd2idx(%coord_123, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %ptr_125 = cute.add_offset(%iter_89, %idx_124) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %213 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
        %214 = llvm.load %213 : !llvm.ptr -> i8
        %215 = llvm.icmp "ne" %214, %9 : i8
        scf.if %215 {
          %237 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %iter_46 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_126 = cute.add_offset(%ptr_125, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %216 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem> to !llvm.ptr
        %217 = llvm.load %216 : !llvm.ptr -> i8
        %218 = llvm.icmp "ne" %217, %9 : i8
        scf.if %218 {
          %ptr_133 = cute.add_offset(%ptr_44, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_127 = cute.add_offset(%ptr_125, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %219 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i8, rmem> to !llvm.ptr
        %220 = llvm.load %219 : !llvm.ptr -> i8
        %221 = llvm.icmp "ne" %220, %9 : i8
        scf.if %221 {
          %ptr_133 = cute.add_offset(%ptr_44, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_128 = cute.add_offset(%ptr_125, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %222 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<i8, rmem> to !llvm.ptr
        %223 = llvm.load %222 : !llvm.ptr -> i8
        %224 = llvm.icmp "ne" %223, %9 : i8
        scf.if %224 {
          %ptr_133 = cute.add_offset(%ptr_44, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_129 = cute.add_offset(%ptr_125, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %225 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem> to !llvm.ptr
        %226 = llvm.load %225 : !llvm.ptr -> i8
        %227 = llvm.icmp "ne" %226, %9 : i8
        scf.if %227 {
          %ptr_133 = cute.add_offset(%ptr_44, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_130 = cute.add_offset(%ptr_125, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %228 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i8, rmem> to !llvm.ptr
        %229 = llvm.load %228 : !llvm.ptr -> i8
        %230 = llvm.icmp "ne" %229, %9 : i8
        scf.if %230 {
          %ptr_133 = cute.add_offset(%ptr_44, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_131 = cute.add_offset(%ptr_125, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %231 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i8, rmem> to !llvm.ptr
        %232 = llvm.load %231 : !llvm.ptr -> i8
        %233 = llvm.icmp "ne" %232, %9 : i8
        scf.if %233 {
          %ptr_133 = cute.add_offset(%ptr_44, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_132 = cute.add_offset(%ptr_125, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %234 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i8, rmem> to !llvm.ptr
        %235 = llvm.load %234 : !llvm.ptr -> i8
        %236 = llvm.icmp "ne" %235, %9 : i8
        scf.if %236 {
          %ptr_133 = cute.add_offset(%ptr_44, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_134 = cute.add_offset(%iter_46, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %237 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %238 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %239 = llvm.load %237 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %239, %238 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %iter_121 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %159 = cute.get_scalars(%8) : !cute.int_tuple<"8">
      scf.for %arg4 = %c0_i32 to %159 step %c1_i32  : i32 {
        %coord_123 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_124 = cute.crd2idx(%coord_123, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_125 = cute.add_offset(%ptr_30, %idx_124) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %idx_126 = cute.crd2idx(%coord_123, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_127 = cute.add_offset(%iter_121, %idx_126) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %213 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %214 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %215 = llvm.load %213 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %215, %214 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %160 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %161 = arith.extf %160 : vector<64xbf16> to vector<64xf32>
      %162 = arith.mulf %161, %161 : vector<64xf32>
      %163 = vector.reduction <add>, %162, %cst_0 : vector<64xf32> into f32
      %164 = nvvm.shfl.sync  bfly %c-1_i32, %163, %c16_i32, %c31_i32 : f32 -> f32
      %165 = arith.addf %164, %163 : f32
      %166 = nvvm.shfl.sync  bfly %c-1_i32, %165, %c8_i32, %c31_i32 : f32 -> f32
      %167 = arith.addf %165, %166 : f32
      %168 = nvvm.shfl.sync  bfly %c-1_i32, %167, %c4_i32, %c31_i32 : f32 -> f32
      %169 = arith.addf %167, %168 : f32
      %170 = nvvm.shfl.sync  bfly %c-1_i32, %169, %c2_i32, %c31_i32 : f32 -> f32
      %171 = arith.addf %169, %170 : f32
      %172 = nvvm.shfl.sync  bfly %c-1_i32, %171, %c1_i32, %c31_i32 : f32 -> f32
      %173 = arith.addf %171, %172 : f32
      %174 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %175 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %176 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %177 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %178 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %179 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %180 = arith.muli %176, %178 : i32
      %181 = arith.addi %175, %180 : i32
      %182 = arith.muli %177, %178 : i32
      %183 = arith.muli %182, %179 : i32
      %184 = arith.addi %181, %183 : i32
      %185 = arith.floordivsi %184, %c32_i32 : i32
      %186 = arith.floordivsi %185, %c2_i32 : i32
      %187 = arith.remsi %185, %c2_i32 : i32
      %188 = arith.cmpi eq, %174, %c0_i32 : i32
      scf.if %188 {
        %coord_123 = cute.make_coord(%186, %187) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view, %coord_123, %173) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      }
      nvvm.barrier
      %189 = arith.cmpi slt, %174, %c2_i32 : i32
      %190 = scf.if %189 -> (f32) {
        %coord_123 = cute.make_coord(%186, %174) : (i32, i32) -> !cute.coord<"(?,?)">
        %213 = cute.memref.load(%view, %coord_123) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %213 : f32
      } else {
        scf.yield %cst_0 : f32
      }
      %191 = nvvm.shfl.sync  bfly %c-1_i32, %190, %c16_i32, %c31_i32 : f32 -> f32
      %192 = arith.addf %190, %191 : f32
      %193 = nvvm.shfl.sync  bfly %c-1_i32, %192, %c8_i32, %c31_i32 : f32 -> f32
      %194 = arith.addf %192, %193 : f32
      %195 = nvvm.shfl.sync  bfly %c-1_i32, %194, %c4_i32, %c31_i32 : f32 -> f32
      %196 = arith.addf %194, %195 : f32
      %197 = nvvm.shfl.sync  bfly %c-1_i32, %196, %c2_i32, %c31_i32 : f32 -> f32
      %198 = arith.addf %196, %197 : f32
      %199 = nvvm.shfl.sync  bfly %c-1_i32, %198, %c1_i32, %c31_i32 : f32 -> f32
      %200 = arith.addf %198, %199 : f32
      %201 = arith.divf %200, %cst : f32
      %202 = arith.addf %201, %arg3 : f32
      %203 = math.rsqrt %202 fastmath<fast> : f32
      nvvm.barrier
      %iter_122 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %204 = cute.get_scalars(%8) : !cute.int_tuple<"8">
      scf.for %arg4 = %c0_i32 to %204 step %c1_i32  : i32 {
        %coord_123 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_124 = cute.crd2idx(%coord_123, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_125 = cute.add_offset(%ptr_30, %idx_124) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %idx_126 = cute.crd2idx(%coord_123, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_127 = cute.add_offset(%iter_122, %idx_126) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %213 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %214 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %215 = llvm.load %213 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %215, %214 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %205 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %206 = arith.extf %205 : vector<64xbf16> to vector<64xf32>
      %207 = vector.broadcast %203 : f32 to vector<64xf32>
      %208 = arith.mulf %206, %207 : vector<64xf32>
      %209 = cute.memref.load_vec %view_48 : !memref_rmem_bf16_
      %210 = arith.extf %209 : vector<64xbf16> to vector<64xf32>
      %211 = arith.mulf %208, %210 : vector<64xf32>
      %212 = arith.truncf %211 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %212, %rmem_39 : !memref_rmem_bf16_
      scf.if %121 {
        %213 = cute.get_scalars(%23) : !cute.int_tuple<"1">
        scf.for %arg4 = %c0_i32 to %213 step %c1_i32  : i32 {
          %coord_123 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_124 = cute.crd2idx(%coord_123, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_125 = cute.add_offset(%iter_50, %idx_124) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %214 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
          %215 = llvm.load %214 : !llvm.ptr -> i8
          %216 = llvm.icmp "ne" %215, %9 : i8
          scf.if %216 {
            %238 = builtin.unrealized_conversion_cast %iter_40 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_126 = cute.add_offset(%ptr_125, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %217 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem> to !llvm.ptr
          %218 = llvm.load %217 : !llvm.ptr -> i8
          %219 = llvm.icmp "ne" %218, %9 : i8
          scf.if %219 {
            %ptr_133 = cute.add_offset(%iter_40, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_134 = cute.add_offset(%ptr_34, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_127 = cute.add_offset(%ptr_125, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %220 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i8, rmem> to !llvm.ptr
          %221 = llvm.load %220 : !llvm.ptr -> i8
          %222 = llvm.icmp "ne" %221, %9 : i8
          scf.if %222 {
            %ptr_133 = cute.add_offset(%iter_40, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_134 = cute.add_offset(%ptr_34, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_128 = cute.add_offset(%ptr_125, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %223 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<i8, rmem> to !llvm.ptr
          %224 = llvm.load %223 : !llvm.ptr -> i8
          %225 = llvm.icmp "ne" %224, %9 : i8
          scf.if %225 {
            %ptr_133 = cute.add_offset(%iter_40, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_134 = cute.add_offset(%ptr_34, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_129 = cute.add_offset(%ptr_125, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %226 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem> to !llvm.ptr
          %227 = llvm.load %226 : !llvm.ptr -> i8
          %228 = llvm.icmp "ne" %227, %9 : i8
          scf.if %228 {
            %ptr_133 = cute.add_offset(%iter_40, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_134 = cute.add_offset(%ptr_34, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_130 = cute.add_offset(%ptr_125, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %229 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i8, rmem> to !llvm.ptr
          %230 = llvm.load %229 : !llvm.ptr -> i8
          %231 = llvm.icmp "ne" %230, %9 : i8
          scf.if %231 {
            %ptr_133 = cute.add_offset(%iter_40, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_134 = cute.add_offset(%ptr_34, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_131 = cute.add_offset(%ptr_125, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %232 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i8, rmem> to !llvm.ptr
          %233 = llvm.load %232 : !llvm.ptr -> i8
          %234 = llvm.icmp "ne" %233, %9 : i8
          scf.if %234 {
            %ptr_133 = cute.add_offset(%iter_40, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_134 = cute.add_offset(%ptr_34, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_132 = cute.add_offset(%ptr_125, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %235 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i8, rmem> to !llvm.ptr
          %236 = llvm.load %235 : !llvm.ptr -> i8
          %237 = llvm.icmp "ne" %236, %9 : i8
          scf.if %237 {
            %ptr_133 = cute.add_offset(%iter_40, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_134 = cute.add_offset(%ptr_34, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %238 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %239 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %240 = llvm.load %238 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %240, %239 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c16400_i64 = arith.constant 16400 : i64
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c2_i32 = arith.constant 2 : i32
    %0 = cute.static : !cute.layout<"(4096):(1)">
    %1 = cute.static : !cute.stride<"(4096,1)">
    %shape = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %lay = cute.make_layout(%shape, %1) : !cute.layout<"(?,4096):(4096,1)">
    %view = cute.make_view(%arg0, %lay) : !memref_gmem_bf16_
    %shape_0 = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %lay_1 = cute.make_layout(%shape_0, %1) : !cute.layout<"(?,4096):(4096,1)">
    %view_2 = cute.make_view(%arg2, %lay_1) : !memref_gmem_bf16_
    %view_3 = cute.make_view(%arg1, %0) : !memref_gmem_bf16_1
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %3 = arith.ceildivsi %2, %c2_i32 : i32
    %int_tuple_4 = cute.make_int_tuple(%3) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_4) : !cute.int_tuple<"?">
    %4 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %5 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c16400_i64, gridDim = (%4, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %6 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%5> (%view, %view_3, %view_2, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %7 = cuda.cast %6 : !cuda.result -> i32
    cuda.return_if_error %7 : i32
    return %c0_i32 : i32
  }
}
