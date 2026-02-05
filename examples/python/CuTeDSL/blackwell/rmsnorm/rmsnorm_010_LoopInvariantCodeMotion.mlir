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
      %52 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %53 = arith.ceildivsi %52, %c2_i32 : i32
      %shape_5 = cute.make_shape(%53) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_6 = cute.make_layout(%shape_5, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx = cute.crd2idx(%coord_4, %lay_6) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_7 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_8 = cute.add_offset(%iter_7, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %lay_9 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %54 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %55 = arith.ceildivsi %54, %c2_i32 : i32
      %shape_10 = cute.make_shape(%55) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_11 = cute.make_layout(%shape_10, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_12 = cute.crd2idx(%coord_4, %lay_11) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_13 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_14 = cute.add_offset(%iter_13, %idx_12) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %56 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %57 = arith.ceildivsi %56, %c2_i32 : i32
      %shape_15 = cute.make_shape(%57) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_16 = cute.make_layout(%shape_15, %41) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_17 = cute.crd2idx(%coord_4, %lay_16) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %tup = cute.add_offset(%44, %idx_17) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_18 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %58 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %59 = cute.make_tiled_copy(%atom_18) : !copy_simt
      %60 = cute.make_tiled_copy(%atom_18) : !copy_simt
      %coord_19 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %61 = cute.get_scalars(%coord_19) <{only_dynamic}> : !cute.coord<"?">
      %62 = arith.divsi %61, %c64_i32 : i32
      %63 = arith.remsi %61, %c64_i32 : i32
      %64 = arith.muli %63, %c8_i32 : i32
      %65 = arith.muli %62, %c4096_i32 : i32
      %66 = arith.addi %64, %65 : i32
      %iv = cute.assume(%66) : (i32) -> !cute.i32<divby 8>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_20 = cute.add_offset(%ptr_8, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_21 = cute.add_offset(%iter_1, %int_tuple) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_22 = cute.add_offset(%ptr_14, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_23 = cute.assume(%64) : (i32) -> !cute.i32<divby 8>
      %int_tuple_24 = cute.make_int_tuple(%62, %iv_23) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_25 = cute.add_offset(%tup, %int_tuple_24) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_26 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_27 = cute.get_iter(%rmem_26) : !memref_rmem_bf16_
      %int_tuple_28 = cute.make_int_tuple(%iv_23) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_29 = cute.add_offset(%iter, %int_tuple_28) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %rmem_30 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_31 = cute.get_iter(%rmem_30) : !memref_rmem_bf16_
      %view_32 = cute.make_view(%iter_31) : !memref_rmem_bf16_
      %rmem_33 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_34 = cute.get_iter(%rmem_33) : !memref_rmem_i8_
      %e0_35, %e1_36 = cute.get_leaves(%tup_25) : !cute.int_tuple<"(?,?{div=8})">
      %coord_37 = cute.make_coord(%e1_36) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %67 = cute.get_scalars(%coord_37) : !cute.coord<"?{div=8}">
      %68 = cute.get_scalars(%40) : !cute.coord<"4096">
      %69 = arith.cmpi slt, %67, %68 : i32
      %70 = arith.extui %69 : i1 to i8
      cute.memref.store(%rmem_33, %39, %70) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_38 = cute.add_offset(%tup_25, %38) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_39, %e1_40 = cute.get_leaves(%tup_38) : !cute.int_tuple<"(?,?{div=8})">
      %coord_41 = cute.make_coord(%e1_40) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %71 = cute.get_scalars(%coord_41) : !cute.coord<"?{div=8}">
      %72 = arith.cmpi slt, %71, %68 : i32
      %73 = arith.extui %72 : i1 to i8
      cute.memref.store(%rmem_33, %37, %73) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %tup_42 = cute.add_offset(%tup_25, %36) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_43, %e1_44 = cute.get_leaves(%tup_42) : !cute.int_tuple<"(?,?{div=8})">
      %coord_45 = cute.make_coord(%e1_44) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %74 = cute.get_scalars(%coord_45) : !cute.coord<"?{div=8}">
      %75 = arith.cmpi slt, %74, %68 : i32
      %76 = arith.extui %75 : i1 to i8
      cute.memref.store(%rmem_33, %35, %76) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %tup_46 = cute.add_offset(%tup_25, %34) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_47, %e1_48 = cute.get_leaves(%tup_46) : !cute.int_tuple<"(?,?{div=8})">
      %coord_49 = cute.make_coord(%e1_48) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %77 = cute.get_scalars(%coord_49) : !cute.coord<"?{div=8}">
      %78 = arith.cmpi slt, %77, %68 : i32
      %79 = arith.extui %78 : i1 to i8
      cute.memref.store(%rmem_33, %33, %79) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %tup_50 = cute.add_offset(%tup_25, %32) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_51, %e1_52 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(?,?{div=8})">
      %coord_53 = cute.make_coord(%e1_52) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %80 = cute.get_scalars(%coord_53) : !cute.coord<"?{div=8}">
      %81 = arith.cmpi slt, %80, %68 : i32
      %82 = arith.extui %81 : i1 to i8
      cute.memref.store(%rmem_33, %31, %82) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %tup_54 = cute.add_offset(%tup_25, %30) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_55, %e1_56 = cute.get_leaves(%tup_54) : !cute.int_tuple<"(?,?{div=8})">
      %coord_57 = cute.make_coord(%e1_56) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %83 = cute.get_scalars(%coord_57) : !cute.coord<"?{div=8}">
      %84 = arith.cmpi slt, %83, %68 : i32
      %85 = arith.extui %84 : i1 to i8
      cute.memref.store(%rmem_33, %29, %85) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %tup_58 = cute.add_offset(%tup_25, %28) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_59, %e1_60 = cute.get_leaves(%tup_58) : !cute.int_tuple<"(?,?{div=8})">
      %coord_61 = cute.make_coord(%e1_60) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %86 = cute.get_scalars(%coord_61) : !cute.coord<"?{div=8}">
      %87 = arith.cmpi slt, %86, %68 : i32
      %88 = arith.extui %87 : i1 to i8
      cute.memref.store(%rmem_33, %27, %88) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %tup_62 = cute.add_offset(%tup_25, %26) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_63, %e1_64 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?{div=8})">
      %coord_65 = cute.make_coord(%e1_64) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %89 = cute.get_scalars(%coord_65) : !cute.coord<"?{div=8}">
      %90 = arith.cmpi slt, %89, %68 : i32
      %91 = arith.extui %90 : i1 to i8
      cute.memref.store(%rmem_33, %25, %91) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %92 = cute.get_scalars(%e0_35) : !cute.int_tuple<"?">
      %93 = arith.cmpi slt, %92, %50 : i32
      scf.if %93 {
        %147 = cute.get_scalars(%23) : !cute.int_tuple<"1">
        %iter_69 = cute.recast_iter(%ptr_20) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_70 = cute.recast_iter(%ptr_21) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_71 = cute.add_offset(%ptr_20, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_72 = cute.add_offset(%ptr_21, %22) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_73 = cute.recast_iter(%ptr_71) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_74 = cute.recast_iter(%ptr_72) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_75 = cute.add_offset(%ptr_20, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_76 = cute.add_offset(%ptr_21, %21) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_77 = cute.recast_iter(%ptr_75) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_78 = cute.recast_iter(%ptr_76) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_79 = cute.add_offset(%ptr_20, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_80 = cute.add_offset(%ptr_21, %19) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_81 = cute.recast_iter(%ptr_79) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_82 = cute.recast_iter(%ptr_80) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_83 = cute.add_offset(%ptr_20, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_84 = cute.add_offset(%ptr_21, %17) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_85 = cute.recast_iter(%ptr_83) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_86 = cute.recast_iter(%ptr_84) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_87 = cute.add_offset(%ptr_20, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_88 = cute.add_offset(%ptr_21, %15) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_89 = cute.recast_iter(%ptr_87) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_90 = cute.recast_iter(%ptr_88) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_91 = cute.add_offset(%ptr_20, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_92 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_93 = cute.recast_iter(%ptr_91) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_94 = cute.recast_iter(%ptr_92) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        %ptr_95 = cute.add_offset(%ptr_20, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
        %ptr_96 = cute.add_offset(%ptr_21, %11) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
        %iter_97 = cute.recast_iter(%ptr_95) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
        %iter_98 = cute.recast_iter(%ptr_96) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
        scf.for %arg4 = %c0_i32 to %147 step %c1_i32  : i32 {
          %coord_99 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_100 = cute.crd2idx(%coord_99, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_101 = cute.add_offset(%iter_34, %idx_100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %148 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i8, rmem> to !llvm.ptr
          %149 = llvm.load %148 : !llvm.ptr -> i8
          %150 = llvm.trunc %149 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_70 : !cute.ptr<i128, smem>, %iter_69 : !cute.ptr<i128, gmem>, %150 : i1) {cache_mode = <always>}
          %ptr_102 = cute.add_offset(%ptr_101, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %151 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i8, rmem> to !llvm.ptr
          %152 = llvm.load %151 : !llvm.ptr -> i8
          %153 = llvm.trunc %152 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_74 : !cute.ptr<i128, smem>, %iter_73 : !cute.ptr<i128, gmem>, %153 : i1) {cache_mode = <always>}
          %ptr_103 = cute.add_offset(%ptr_101, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %154 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i8, rmem> to !llvm.ptr
          %155 = llvm.load %154 : !llvm.ptr -> i8
          %156 = llvm.trunc %155 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_78 : !cute.ptr<i128, smem>, %iter_77 : !cute.ptr<i128, gmem>, %156 : i1) {cache_mode = <always>}
          %ptr_104 = cute.add_offset(%ptr_101, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %157 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i8, rmem> to !llvm.ptr
          %158 = llvm.load %157 : !llvm.ptr -> i8
          %159 = llvm.trunc %158 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_82 : !cute.ptr<i128, smem>, %iter_81 : !cute.ptr<i128, gmem>, %159 : i1) {cache_mode = <always>}
          %ptr_105 = cute.add_offset(%ptr_101, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %160 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i8, rmem> to !llvm.ptr
          %161 = llvm.load %160 : !llvm.ptr -> i8
          %162 = llvm.trunc %161 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_86 : !cute.ptr<i128, smem>, %iter_85 : !cute.ptr<i128, gmem>, %162 : i1) {cache_mode = <always>}
          %ptr_106 = cute.add_offset(%ptr_101, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %163 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i8, rmem> to !llvm.ptr
          %164 = llvm.load %163 : !llvm.ptr -> i8
          %165 = llvm.trunc %164 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_90 : !cute.ptr<i128, smem>, %iter_89 : !cute.ptr<i128, gmem>, %165 : i1) {cache_mode = <always>}
          %ptr_107 = cute.add_offset(%ptr_101, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %166 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i8, rmem> to !llvm.ptr
          %167 = llvm.load %166 : !llvm.ptr -> i8
          %168 = llvm.trunc %167 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_94 : !cute.ptr<i128, smem>, %iter_93 : !cute.ptr<i128, gmem>, %168 : i1) {cache_mode = <always>}
          %ptr_108 = cute.add_offset(%ptr_101, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %169 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i8, rmem> to !llvm.ptr
          %170 = llvm.load %169 : !llvm.ptr -> i8
          %171 = llvm.trunc %170 : i8 to i1
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_98 : !cute.ptr<i128, smem>, %iter_97 : !cute.ptr<i128, gmem>, %171 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %rmem_66 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_67 = cute.get_iter(%rmem_66) : !memref_rmem_i8_
      cute.memref.store(%rmem_66, %39, %70) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %37, %73) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %35, %76) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %33, %79) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %31, %82) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %29, %85) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %27, %88) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      cute.memref.store(%rmem_66, %25, %91) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %94 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      scf.for %arg4 = %c0_i32 to %94 step %c1_i32  : i32 {
        %coord_69 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_70 = cute.crd2idx(%coord_69, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %ptr_71 = cute.add_offset(%iter_67, %idx_70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %147 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
        %148 = llvm.load %147 : !llvm.ptr -> i8
        %149 = llvm.icmp "ne" %148, %9 : i8
        scf.if %149 {
          %171 = builtin.unrealized_conversion_cast %ptr_29 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_72 = cute.add_offset(%ptr_71, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %150 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem> to !llvm.ptr
        %151 = llvm.load %150 : !llvm.ptr -> i8
        %152 = llvm.icmp "ne" %151, %9 : i8
        scf.if %152 {
          %ptr_79 = cute.add_offset(%ptr_29, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_73 = cute.add_offset(%ptr_71, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.icmp "ne" %154, %9 : i8
        scf.if %155 {
          %ptr_79 = cute.add_offset(%ptr_29, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_74 = cute.add_offset(%ptr_71, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %156 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<i8, rmem> to !llvm.ptr
        %157 = llvm.load %156 : !llvm.ptr -> i8
        %158 = llvm.icmp "ne" %157, %9 : i8
        scf.if %158 {
          %ptr_79 = cute.add_offset(%ptr_29, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_75 = cute.add_offset(%ptr_71, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %159 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<i8, rmem> to !llvm.ptr
        %160 = llvm.load %159 : !llvm.ptr -> i8
        %161 = llvm.icmp "ne" %160, %9 : i8
        scf.if %161 {
          %ptr_79 = cute.add_offset(%ptr_29, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_76 = cute.add_offset(%ptr_71, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %162 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<i8, rmem> to !llvm.ptr
        %163 = llvm.load %162 : !llvm.ptr -> i8
        %164 = llvm.icmp "ne" %163, %9 : i8
        scf.if %164 {
          %ptr_79 = cute.add_offset(%ptr_29, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_77 = cute.add_offset(%ptr_71, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %165 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i8, rmem> to !llvm.ptr
        %166 = llvm.load %165 : !llvm.ptr -> i8
        %167 = llvm.icmp "ne" %166, %9 : i8
        scf.if %167 {
          %ptr_79 = cute.add_offset(%ptr_29, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %ptr_78 = cute.add_offset(%ptr_71, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %168 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i8, rmem> to !llvm.ptr
        %169 = llvm.load %168 : !llvm.ptr -> i8
        %170 = llvm.icmp "ne" %169, %9 : i8
        scf.if %170 {
          %ptr_79 = cute.add_offset(%ptr_29, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %ptr_80 = cute.add_offset(%iter_31, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %iter_68 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %95 = cute.get_scalars(%8) : !cute.int_tuple<"8">
      scf.for %arg4 = %c0_i32 to %95 step %c1_i32  : i32 {
        %coord_69 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_70 = cute.crd2idx(%coord_69, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_71 = cute.add_offset(%ptr_21, %idx_70) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %idx_72 = cute.crd2idx(%coord_69, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_73 = cute.add_offset(%iter_68, %idx_72) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %147 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %148 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %149 = llvm.load %147 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %149, %148 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %96 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %97 = arith.extf %96 : vector<64xbf16> to vector<64xf32>
      %98 = arith.mulf %97, %97 : vector<64xf32>
      %99 = vector.reduction <add>, %98, %cst_0 : vector<64xf32> into f32
      %100 = nvvm.shfl.sync  bfly %c-1_i32, %99, %c16_i32, %c31_i32 : f32 -> f32
      %101 = arith.addf %100, %99 : f32
      %102 = nvvm.shfl.sync  bfly %c-1_i32, %101, %c8_i32, %c31_i32 : f32 -> f32
      %103 = arith.addf %101, %102 : f32
      %104 = nvvm.shfl.sync  bfly %c-1_i32, %103, %c4_i32, %c31_i32 : f32 -> f32
      %105 = arith.addf %103, %104 : f32
      %106 = nvvm.shfl.sync  bfly %c-1_i32, %105, %c2_i32, %c31_i32 : f32 -> f32
      %107 = arith.addf %105, %106 : f32
      %108 = nvvm.shfl.sync  bfly %c-1_i32, %107, %c1_i32, %c31_i32 : f32 -> f32
      %109 = arith.addf %107, %108 : f32
      %110 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %111 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %112 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %113 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %114 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %115 = arith.muli %111, %113 : i32
      %116 = arith.addi %47, %115 : i32
      %117 = arith.muli %112, %113 : i32
      %118 = arith.muli %117, %114 : i32
      %119 = arith.addi %116, %118 : i32
      %120 = arith.floordivsi %119, %c32_i32 : i32
      %121 = arith.floordivsi %120, %c2_i32 : i32
      %122 = arith.remsi %120, %c2_i32 : i32
      %123 = arith.cmpi eq, %110, %c0_i32 : i32
      scf.if %123 {
        %coord_69 = cute.make_coord(%121, %122) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view, %coord_69, %109) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      }
      nvvm.barrier
      %124 = arith.cmpi slt, %110, %c2_i32 : i32
      %125 = scf.if %124 -> (f32) {
        %coord_69 = cute.make_coord(%121, %110) : (i32, i32) -> !cute.coord<"(?,?)">
        %147 = cute.memref.load(%view, %coord_69) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %147 : f32
      } else {
        scf.yield %cst_0 : f32
      }
      %126 = nvvm.shfl.sync  bfly %c-1_i32, %125, %c16_i32, %c31_i32 : f32 -> f32
      %127 = arith.addf %125, %126 : f32
      %128 = nvvm.shfl.sync  bfly %c-1_i32, %127, %c8_i32, %c31_i32 : f32 -> f32
      %129 = arith.addf %127, %128 : f32
      %130 = nvvm.shfl.sync  bfly %c-1_i32, %129, %c4_i32, %c31_i32 : f32 -> f32
      %131 = arith.addf %129, %130 : f32
      %132 = nvvm.shfl.sync  bfly %c-1_i32, %131, %c2_i32, %c31_i32 : f32 -> f32
      %133 = arith.addf %131, %132 : f32
      %134 = nvvm.shfl.sync  bfly %c-1_i32, %133, %c1_i32, %c31_i32 : f32 -> f32
      %135 = arith.addf %133, %134 : f32
      %136 = arith.divf %135, %cst : f32
      %137 = arith.addf %136, %arg3 : f32
      %138 = math.rsqrt %137 fastmath<fast> : f32
      nvvm.barrier
      scf.for %arg4 = %c0_i32 to %95 step %c1_i32  : i32 {
        %coord_69 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %idx_70 = cute.crd2idx(%coord_69, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_71 = cute.add_offset(%ptr_21, %idx_70) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %idx_72 = cute.crd2idx(%coord_69, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_73 = cute.add_offset(%iter_68, %idx_72) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %147 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %148 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %149 = llvm.load %147 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %149, %148 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %139 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %140 = arith.extf %139 : vector<64xbf16> to vector<64xf32>
      %141 = vector.broadcast %138 : f32 to vector<64xf32>
      %142 = arith.mulf %140, %141 : vector<64xf32>
      %143 = cute.memref.load_vec %view_32 : !memref_rmem_bf16_
      %144 = arith.extf %143 : vector<64xbf16> to vector<64xf32>
      %145 = arith.mulf %142, %144 : vector<64xf32>
      %146 = arith.truncf %145 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %146, %rmem_26 : !memref_rmem_bf16_
      scf.if %93 {
        scf.for %arg4 = %c0_i32 to %94 step %c1_i32  : i32 {
          %coord_69 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %idx_70 = cute.crd2idx(%coord_69, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_71 = cute.add_offset(%iter_34, %idx_70) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %147 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
          %148 = llvm.load %147 : !llvm.ptr -> i8
          %149 = llvm.icmp "ne" %148, %9 : i8
          scf.if %149 {
            %171 = builtin.unrealized_conversion_cast %iter_27 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_72 = cute.add_offset(%ptr_71, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem> to !llvm.ptr
          %151 = llvm.load %150 : !llvm.ptr -> i8
          %152 = llvm.icmp "ne" %151, %9 : i8
          scf.if %152 {
            %ptr_79 = cute.add_offset(%iter_27, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_80 = cute.add_offset(%ptr_22, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_73 = cute.add_offset(%ptr_71, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %153 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
          %154 = llvm.load %153 : !llvm.ptr -> i8
          %155 = llvm.icmp "ne" %154, %9 : i8
          scf.if %155 {
            %ptr_79 = cute.add_offset(%iter_27, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_80 = cute.add_offset(%ptr_22, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_74 = cute.add_offset(%ptr_71, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %156 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<i8, rmem> to !llvm.ptr
          %157 = llvm.load %156 : !llvm.ptr -> i8
          %158 = llvm.icmp "ne" %157, %9 : i8
          scf.if %158 {
            %ptr_79 = cute.add_offset(%iter_27, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_80 = cute.add_offset(%ptr_22, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_75 = cute.add_offset(%ptr_71, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %159 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<i8, rmem> to !llvm.ptr
          %160 = llvm.load %159 : !llvm.ptr -> i8
          %161 = llvm.icmp "ne" %160, %9 : i8
          scf.if %161 {
            %ptr_79 = cute.add_offset(%iter_27, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_80 = cute.add_offset(%ptr_22, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_76 = cute.add_offset(%ptr_71, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %162 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<i8, rmem> to !llvm.ptr
          %163 = llvm.load %162 : !llvm.ptr -> i8
          %164 = llvm.icmp "ne" %163, %9 : i8
          scf.if %164 {
            %ptr_79 = cute.add_offset(%iter_27, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_80 = cute.add_offset(%ptr_22, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_77 = cute.add_offset(%ptr_71, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %165 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i8, rmem> to !llvm.ptr
          %166 = llvm.load %165 : !llvm.ptr -> i8
          %167 = llvm.icmp "ne" %166, %9 : i8
          scf.if %167 {
            %ptr_79 = cute.add_offset(%iter_27, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %ptr_80 = cute.add_offset(%ptr_22, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %ptr_78 = cute.add_offset(%ptr_71, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %168 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i8, rmem> to !llvm.ptr
          %169 = llvm.load %168 : !llvm.ptr -> i8
          %170 = llvm.icmp "ne" %169, %9 : i8
          scf.if %170 {
            %ptr_79 = cute.add_offset(%iter_27, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %ptr_80 = cute.add_offset(%ptr_22, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %171 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %172 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %173 = llvm.load %171 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %173, %172 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
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
    %view_0 = cute.make_view(%arg2, %lay) : !memref_gmem_bf16_
    %view_1 = cute.make_view(%arg1, %0) : !memref_gmem_bf16_1
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %3 = arith.ceildivsi %2, %c2_i32 : i32
    %int_tuple_2 = cute.make_int_tuple(%3) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_2) : !cute.int_tuple<"?">
    %4 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %5 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c16400_i64, gridDim = (%4, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %6 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%5> (%view, %view_1, %view_0, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %7 = cuda.cast %6 : !cuda.result -> i32
    cuda.return_if_error %7 : i32
    return %c0_i32 : i32
  }
}
