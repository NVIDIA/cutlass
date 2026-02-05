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
      %c1_i32_5 = arith.constant 1 : i32
      %c0_i32_6 = arith.constant 0 : i32
      %c-1_i32_7 = arith.constant -1 : i32
      %53 = arith.cmpi sgt, %c2_i32, %c0_i32_6 : i32
      %54 = arith.select %53, %c-1_i32_7, %c1_i32_5 : i32
      %55 = arith.addi %54, %52 : i32
      %56 = arith.divsi %55, %c2_i32 : i32
      %57 = arith.addi %c1_i32_5, %56 : i32
      %58 = arith.subi %c0_i32_6, %52 : i32
      %59 = arith.divsi %58, %c2_i32 : i32
      %60 = arith.subi %c0_i32_6, %59 : i32
      %61 = arith.cmpi slt, %52, %c0_i32_6 : i32
      %62 = arith.cmpi sgt, %52, %c0_i32_6 : i32
      %63 = arith.cmpi slt, %c2_i32, %c0_i32_6 : i32
      %64 = arith.cmpi sgt, %c2_i32, %c0_i32_6 : i32
      %65 = arith.andi %61, %63 : i1
      %66 = arith.andi %62, %64 : i1
      %67 = arith.ori %65, %66 : i1
      %68 = arith.select %67, %57, %60 : i32
      %shape_8 = cute.make_shape(%68) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_9 = cute.make_layout(%shape_8, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx = cute.crd2idx(%coord_4, %lay_9) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_10 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_11 = cute.add_offset(%iter_10, %idx) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %lay_12 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %69 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c1_i32_13 = arith.constant 1 : i32
      %c0_i32_14 = arith.constant 0 : i32
      %c-1_i32_15 = arith.constant -1 : i32
      %70 = arith.cmpi sgt, %c2_i32, %c0_i32_14 : i32
      %71 = arith.select %70, %c-1_i32_15, %c1_i32_13 : i32
      %72 = arith.addi %71, %69 : i32
      %73 = arith.divsi %72, %c2_i32 : i32
      %74 = arith.addi %c1_i32_13, %73 : i32
      %75 = arith.subi %c0_i32_14, %69 : i32
      %76 = arith.divsi %75, %c2_i32 : i32
      %77 = arith.subi %c0_i32_14, %76 : i32
      %78 = arith.cmpi slt, %69, %c0_i32_14 : i32
      %79 = arith.cmpi sgt, %69, %c0_i32_14 : i32
      %80 = arith.cmpi slt, %c2_i32, %c0_i32_14 : i32
      %81 = arith.cmpi sgt, %c2_i32, %c0_i32_14 : i32
      %82 = arith.andi %78, %80 : i1
      %83 = arith.andi %79, %81 : i1
      %84 = arith.ori %82, %83 : i1
      %85 = arith.select %84, %74, %77 : i32
      %shape_16 = cute.make_shape(%85) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_17 = cute.make_layout(%shape_16, %42) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_18 = cute.crd2idx(%coord_4, %lay_17) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_19 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_20 = cute.add_offset(%iter_19, %idx_18) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %86 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %c1_i32_21 = arith.constant 1 : i32
      %c0_i32_22 = arith.constant 0 : i32
      %c-1_i32_23 = arith.constant -1 : i32
      %87 = arith.cmpi sgt, %c2_i32, %c0_i32_22 : i32
      %88 = arith.select %87, %c-1_i32_23, %c1_i32_21 : i32
      %89 = arith.addi %88, %86 : i32
      %90 = arith.divsi %89, %c2_i32 : i32
      %91 = arith.addi %c1_i32_21, %90 : i32
      %92 = arith.subi %c0_i32_22, %86 : i32
      %93 = arith.divsi %92, %c2_i32 : i32
      %94 = arith.subi %c0_i32_22, %93 : i32
      %95 = arith.cmpi slt, %86, %c0_i32_22 : i32
      %96 = arith.cmpi sgt, %86, %c0_i32_22 : i32
      %97 = arith.cmpi slt, %c2_i32, %c0_i32_22 : i32
      %98 = arith.cmpi sgt, %c2_i32, %c0_i32_22 : i32
      %99 = arith.andi %95, %97 : i1
      %100 = arith.andi %96, %98 : i1
      %101 = arith.ori %99, %100 : i1
      %102 = arith.select %101, %91, %94 : i32
      %shape_24 = cute.make_shape(%102) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %lay_25 = cute.make_layout(%shape_24, %41) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_26 = cute.crd2idx(%coord_4, %lay_25) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %tup = cute.add_offset(%44, %idx_26) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_27 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %103 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %104 = cute.make_tiled_copy(%atom_27) : !copy_simt
      %105 = cute.make_tiled_copy(%atom_27) : !copy_simt
      %coord_28 = cute.make_coord(%47) : (i32) -> !cute.coord<"?">
      %106 = cute.get_scalars(%coord_28) <{only_dynamic}> : !cute.coord<"?">
      %107 = arith.divsi %106, %c64_i32 : i32
      %108 = arith.remsi %106, %c64_i32 : i32
      %109 = arith.muli %108, %c8_i32 : i32
      %110 = arith.muli %107, %c4096_i32 : i32
      %111 = arith.addi %109, %110 : i32
      %iv = cute.assume(%111) : (i32) -> !cute.i32<divby 8>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_29 = cute.add_offset(%ptr_11, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_30 = cute.add_offset(%iter_1, %int_tuple) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %ptr_31 = cute.add_offset(%ptr_20, %int_tuple) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %iv_32 = cute.assume(%109) : (i32) -> !cute.i32<divby 8>
      %int_tuple_33 = cute.make_int_tuple(%107, %iv_32) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_34 = cute.add_offset(%tup, %int_tuple_33) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %rmem = cute.memref.alloca() : !memref_rmem_bf16_
      %rmem_35 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_36 = cute.get_iter(%rmem_35) : !memref_rmem_bf16_
      %int_tuple_37 = cute.make_int_tuple(%iv_32) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_38 = cute.add_offset(%iter, %int_tuple_37) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %rmem_39 = cute.memref.alloca() : !memref_rmem_bf16_
      %iter_40 = cute.get_iter(%rmem_39) : !memref_rmem_bf16_
      %view_41 = cute.make_view(%iter_40) : !memref_rmem_bf16_
      %rmem_42 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_43 = cute.get_iter(%rmem_42) : !memref_rmem_i8_
      %e0_44, %e1_45 = cute.get_leaves(%tup_34) : !cute.int_tuple<"(?,?{div=8})">
      %coord_46 = cute.make_coord(%e1_45) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %112 = cute.get_scalars(%coord_46) : !cute.coord<"?{div=8}">
      %113 = cute.get_scalars(%40) : !cute.coord<"4096">
      %114 = arith.cmpi slt, %112, %113 : i32
      %115 = arith.extui %114 : i1 to i8
      cute.memref.store(%rmem_42, %39, %115) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %tup_47 = cute.add_offset(%tup_34, %38) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_48, %e1_49 = cute.get_leaves(%tup_47) : !cute.int_tuple<"(?,?{div=8})">
      %coord_50 = cute.make_coord(%e1_49) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %116 = cute.get_scalars(%coord_50) : !cute.coord<"?{div=8}">
      %117 = arith.cmpi slt, %116, %113 : i32
      %118 = arith.extui %117 : i1 to i8
      cute.memref.store(%rmem_42, %37, %118) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %tup_51 = cute.add_offset(%tup_34, %36) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_52, %e1_53 = cute.get_leaves(%tup_51) : !cute.int_tuple<"(?,?{div=8})">
      %coord_54 = cute.make_coord(%e1_53) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %119 = cute.get_scalars(%coord_54) : !cute.coord<"?{div=8}">
      %120 = arith.cmpi slt, %119, %113 : i32
      %121 = arith.extui %120 : i1 to i8
      cute.memref.store(%rmem_42, %35, %121) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %tup_55 = cute.add_offset(%tup_34, %34) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_56, %e1_57 = cute.get_leaves(%tup_55) : !cute.int_tuple<"(?,?{div=8})">
      %coord_58 = cute.make_coord(%e1_57) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %122 = cute.get_scalars(%coord_58) : !cute.coord<"?{div=8}">
      %123 = arith.cmpi slt, %122, %113 : i32
      %124 = arith.extui %123 : i1 to i8
      cute.memref.store(%rmem_42, %33, %124) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %tup_59 = cute.add_offset(%tup_34, %32) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_60, %e1_61 = cute.get_leaves(%tup_59) : !cute.int_tuple<"(?,?{div=8})">
      %coord_62 = cute.make_coord(%e1_61) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %125 = cute.get_scalars(%coord_62) : !cute.coord<"?{div=8}">
      %126 = arith.cmpi slt, %125, %113 : i32
      %127 = arith.extui %126 : i1 to i8
      cute.memref.store(%rmem_42, %31, %127) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %tup_63 = cute.add_offset(%tup_34, %30) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_64, %e1_65 = cute.get_leaves(%tup_63) : !cute.int_tuple<"(?,?{div=8})">
      %coord_66 = cute.make_coord(%e1_65) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %128 = cute.get_scalars(%coord_66) : !cute.coord<"?{div=8}">
      %129 = arith.cmpi slt, %128, %113 : i32
      %130 = arith.extui %129 : i1 to i8
      cute.memref.store(%rmem_42, %29, %130) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %tup_67 = cute.add_offset(%tup_34, %28) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_68, %e1_69 = cute.get_leaves(%tup_67) : !cute.int_tuple<"(?,?{div=8})">
      %coord_70 = cute.make_coord(%e1_69) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %131 = cute.get_scalars(%coord_70) : !cute.coord<"?{div=8}">
      %132 = arith.cmpi slt, %131, %113 : i32
      %133 = arith.extui %132 : i1 to i8
      cute.memref.store(%rmem_42, %27, %133) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %tup_71 = cute.add_offset(%tup_34, %26) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %e0_72, %e1_73 = cute.get_leaves(%tup_71) : !cute.int_tuple<"(?,?{div=8})">
      %coord_74 = cute.make_coord(%e1_73) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %134 = cute.get_scalars(%coord_74) : !cute.coord<"?{div=8}">
      %135 = arith.cmpi slt, %134, %113 : i32
      %136 = arith.extui %135 : i1 to i8
      cute.memref.store(%rmem_42, %25, %136) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %137 = cute.get_scalars(%e0_44) : !cute.int_tuple<"?">
      %138 = arith.cmpi slt, %137, %50 : i32
      cf.cond_br %138, ^bb1, ^bb5
    ^bb1:  // pred: ^bb0
      %139 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      %iter_75 = cute.recast_iter(%ptr_29) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_76 = cute.recast_iter(%ptr_30) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_77 = cute.add_offset(%ptr_29, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_78 = cute.add_offset(%ptr_30, %22) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_79 = cute.recast_iter(%ptr_77) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_80 = cute.recast_iter(%ptr_78) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_81 = cute.add_offset(%ptr_29, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_82 = cute.add_offset(%ptr_30, %21) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_83 = cute.recast_iter(%ptr_81) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_84 = cute.recast_iter(%ptr_82) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_85 = cute.add_offset(%ptr_29, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_86 = cute.add_offset(%ptr_30, %19) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_87 = cute.recast_iter(%ptr_85) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_88 = cute.recast_iter(%ptr_86) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_89 = cute.add_offset(%ptr_29, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_90 = cute.add_offset(%ptr_30, %17) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_91 = cute.recast_iter(%ptr_89) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_92 = cute.recast_iter(%ptr_90) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_93 = cute.add_offset(%ptr_29, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_94 = cute.add_offset(%ptr_30, %15) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_95 = cute.recast_iter(%ptr_93) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_96 = cute.recast_iter(%ptr_94) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_97 = cute.add_offset(%ptr_29, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_98 = cute.add_offset(%ptr_30, %13) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_99 = cute.recast_iter(%ptr_97) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_100 = cute.recast_iter(%ptr_98) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      %ptr_101 = cute.add_offset(%ptr_29, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_102 = cute.add_offset(%ptr_30, %11) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
      %iter_103 = cute.recast_iter(%ptr_101) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
      %iter_104 = cute.recast_iter(%ptr_102) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%140: i32):  // 2 preds: ^bb1, ^bb3
      %141 = arith.cmpi slt, %140, %139 : i32
      cf.cond_br %141, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %coord_105 = cute.make_coord(%140) : (i32) -> !cute.coord<"(_,?)">
      %idx_106 = cute.crd2idx(%coord_105, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_107 = cute.add_offset(%iter_43, %idx_106) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %142 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i8, rmem> to !llvm.ptr
      %143 = llvm.load %142 : !llvm.ptr -> i8
      %144 = llvm.trunc %143 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_76 : !cute.ptr<i128, smem>, %iter_75 : !cute.ptr<i128, gmem>, %144 : i1) {cache_mode = <always>}
      %ptr_108 = cute.add_offset(%ptr_107, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %145 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i8, rmem> to !llvm.ptr
      %146 = llvm.load %145 : !llvm.ptr -> i8
      %147 = llvm.trunc %146 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_80 : !cute.ptr<i128, smem>, %iter_79 : !cute.ptr<i128, gmem>, %147 : i1) {cache_mode = <always>}
      %ptr_109 = cute.add_offset(%ptr_107, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<i8, rmem> to !llvm.ptr
      %149 = llvm.load %148 : !llvm.ptr -> i8
      %150 = llvm.trunc %149 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_84 : !cute.ptr<i128, smem>, %iter_83 : !cute.ptr<i128, gmem>, %150 : i1) {cache_mode = <always>}
      %ptr_110 = cute.add_offset(%ptr_107, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %151 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<i8, rmem> to !llvm.ptr
      %152 = llvm.load %151 : !llvm.ptr -> i8
      %153 = llvm.trunc %152 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_88 : !cute.ptr<i128, smem>, %iter_87 : !cute.ptr<i128, gmem>, %153 : i1) {cache_mode = <always>}
      %ptr_111 = cute.add_offset(%ptr_107, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %154 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i8, rmem> to !llvm.ptr
      %155 = llvm.load %154 : !llvm.ptr -> i8
      %156 = llvm.trunc %155 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_92 : !cute.ptr<i128, smem>, %iter_91 : !cute.ptr<i128, gmem>, %156 : i1) {cache_mode = <always>}
      %ptr_112 = cute.add_offset(%ptr_107, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %157 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<i8, rmem> to !llvm.ptr
      %158 = llvm.load %157 : !llvm.ptr -> i8
      %159 = llvm.trunc %158 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_96 : !cute.ptr<i128, smem>, %iter_95 : !cute.ptr<i128, gmem>, %159 : i1) {cache_mode = <always>}
      %ptr_113 = cute.add_offset(%ptr_107, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %160 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<i8, rmem> to !llvm.ptr
      %161 = llvm.load %160 : !llvm.ptr -> i8
      %162 = llvm.trunc %161 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_100 : !cute.ptr<i128, smem>, %iter_99 : !cute.ptr<i128, gmem>, %162 : i1) {cache_mode = <always>}
      %ptr_114 = cute.add_offset(%ptr_107, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %163 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i8, rmem> to !llvm.ptr
      %164 = llvm.load %163 : !llvm.ptr -> i8
      %165 = llvm.trunc %164 : i8 to i1
      cute_nvgpu.arch.copy.SM80.cp_async(%iter_104 : !cute.ptr<i128, smem>, %iter_103 : !cute.ptr<i128, gmem>, %165 : i1) {cache_mode = <always>}
      %166 = arith.addi %140, %c1_i32 : i32
      cf.br ^bb2(%166 : i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb5
    ^bb5:  // 2 preds: ^bb0, ^bb4
      nvvm.cp.async.commit.group
      %rmem_115 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_116 = cute.get_iter(%rmem_115) : !memref_rmem_i8_
      cute.memref.store(%rmem_115, %39, %115) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %37, %118) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %35, %121) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %33, %124) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %31, %127) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %29, %130) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %27, %133) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      cute.memref.store(%rmem_115, %25, %136) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %167 = cute.get_scalars(%23) : !cute.int_tuple<"1">
      cf.br ^bb6(%c0_i32 : i32)
    ^bb6(%168: i32):  // 2 preds: ^bb5, ^bb23
      %169 = arith.cmpi slt, %168, %167 : i32
      cf.cond_br %169, ^bb7, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %coord_117 = cute.make_coord(%168) : (i32) -> !cute.coord<"(_,?)">
      %idx_118 = cute.crd2idx(%coord_117, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_119 = cute.add_offset(%iter_116, %idx_118) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %170 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<i8, rmem> to !llvm.ptr
      %171 = llvm.load %170 : !llvm.ptr -> i8
      %172 = llvm.icmp "ne" %171, %9 : i8
      cf.cond_br %172, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %173 = builtin.unrealized_conversion_cast %ptr_38 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %174 = builtin.unrealized_conversion_cast %iter_40 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %175 = llvm.load %173 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %175, %174 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %ptr_120 = cute.add_offset(%ptr_119, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %176 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i8, rmem> to !llvm.ptr
      %177 = llvm.load %176 : !llvm.ptr -> i8
      %178 = llvm.icmp "ne" %177, %9 : i8
      cf.cond_br %178, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %ptr_121 = cute.add_offset(%ptr_38, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_122 = cute.add_offset(%iter_40, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %179 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %180 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %181 = llvm.load %179 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %181, %180 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %ptr_123 = cute.add_offset(%ptr_119, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %182 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i8, rmem> to !llvm.ptr
      %183 = llvm.load %182 : !llvm.ptr -> i8
      %184 = llvm.icmp "ne" %183, %9 : i8
      cf.cond_br %184, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %ptr_124 = cute.add_offset(%ptr_38, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_125 = cute.add_offset(%iter_40, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %185 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %186 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %187 = llvm.load %185 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %187, %186 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %ptr_126 = cute.add_offset(%ptr_119, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %188 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem> to !llvm.ptr
      %189 = llvm.load %188 : !llvm.ptr -> i8
      %190 = llvm.icmp "ne" %189, %9 : i8
      cf.cond_br %190, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %ptr_127 = cute.add_offset(%ptr_38, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_128 = cute.add_offset(%iter_40, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %191 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %192 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %193 = llvm.load %191 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %193, %192 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %ptr_129 = cute.add_offset(%ptr_119, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %194 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem> to !llvm.ptr
      %195 = llvm.load %194 : !llvm.ptr -> i8
      %196 = llvm.icmp "ne" %195, %9 : i8
      cf.cond_br %196, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %ptr_130 = cute.add_offset(%ptr_38, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_131 = cute.add_offset(%iter_40, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %197 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %198 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %199 = llvm.load %197 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %199, %198 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %ptr_132 = cute.add_offset(%ptr_119, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %200 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i8, rmem> to !llvm.ptr
      %201 = llvm.load %200 : !llvm.ptr -> i8
      %202 = llvm.icmp "ne" %201, %9 : i8
      cf.cond_br %202, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %ptr_133 = cute.add_offset(%ptr_38, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_134 = cute.add_offset(%iter_40, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %203 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %204 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %205 = llvm.load %203 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %205, %204 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %ptr_135 = cute.add_offset(%ptr_119, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %206 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i8, rmem> to !llvm.ptr
      %207 = llvm.load %206 : !llvm.ptr -> i8
      %208 = llvm.icmp "ne" %207, %9 : i8
      cf.cond_br %208, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %ptr_136 = cute.add_offset(%ptr_38, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_137 = cute.add_offset(%iter_40, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %209 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %210 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %211 = llvm.load %209 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %211, %210 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %ptr_138 = cute.add_offset(%ptr_119, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %212 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i8, rmem> to !llvm.ptr
      %213 = llvm.load %212 : !llvm.ptr -> i8
      %214 = llvm.icmp "ne" %213, %9 : i8
      cf.cond_br %214, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %ptr_139 = cute.add_offset(%ptr_38, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %ptr_140 = cute.add_offset(%iter_40, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %215 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %216 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %217 = llvm.load %215 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
      llvm.store %217, %216 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      cf.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %218 = arith.addi %168, %c1_i32 : i32
      cf.br ^bb6(%218 : i32)
    ^bb24:  // pred: ^bb6
      nvvm.cp.async.wait.group 0
      %iter_141 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %219 = cute.get_scalars(%8) : !cute.int_tuple<"8">
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%220: i32):  // 2 preds: ^bb24, ^bb26
      %221 = arith.cmpi slt, %220, %219 : i32
      cf.cond_br %221, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      %coord_142 = cute.make_coord(%220) : (i32) -> !cute.coord<"(_,?)">
      %idx_143 = cute.crd2idx(%coord_142, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %ptr_144 = cute.add_offset(%ptr_30, %idx_143) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_145 = cute.crd2idx(%coord_142, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_146 = cute.add_offset(%iter_141, %idx_145) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %222 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %223 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %224 = llvm.load %222 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %224, %223 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %225 = arith.addi %220, %c1_i32 : i32
      cf.br ^bb25(%225 : i32)
    ^bb27:  // pred: ^bb25
      %226 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %227 = arith.extf %226 : vector<64xbf16> to vector<64xf32>
      %228 = arith.mulf %227, %227 : vector<64xf32>
      %229 = vector.reduction <add>, %228, %cst_0 : vector<64xf32> into f32
      %230 = nvvm.shfl.sync  bfly %c-1_i32, %229, %c16_i32, %c31_i32 : f32 -> f32
      %231 = arith.addf %230, %229 : f32
      %232 = nvvm.shfl.sync  bfly %c-1_i32, %231, %c8_i32, %c31_i32 : f32 -> f32
      %233 = arith.addf %231, %232 : f32
      %234 = nvvm.shfl.sync  bfly %c-1_i32, %233, %c4_i32, %c31_i32 : f32 -> f32
      %235 = arith.addf %233, %234 : f32
      %236 = nvvm.shfl.sync  bfly %c-1_i32, %235, %c2_i32, %c31_i32 : f32 -> f32
      %237 = arith.addf %235, %236 : f32
      %238 = nvvm.shfl.sync  bfly %c-1_i32, %237, %c1_i32, %c31_i32 : f32 -> f32
      %239 = arith.addf %237, %238 : f32
      %240 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %241 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %242 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %243 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %244 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %245 = arith.muli %241, %243 : i32
      %246 = arith.addi %47, %245 : i32
      %247 = arith.muli %242, %243 : i32
      %248 = arith.muli %247, %244 : i32
      %249 = arith.addi %246, %248 : i32
      %250 = arith.divsi %249, %c32_i32 : i32
      %251 = arith.muli %250, %c32_i32 : i32
      %252 = arith.cmpi ne, %249, %251 : i32
      %c0_i32_147 = arith.constant 0 : i32
      %253 = arith.cmpi slt, %249, %c0_i32_147 : i32
      %254 = arith.cmpi slt, %c32_i32, %c0_i32_147 : i32
      %255 = arith.cmpi ne, %253, %254 : i1
      %256 = arith.andi %252, %255 : i1
      %c-1_i32_148 = arith.constant -1 : i32
      %257 = arith.addi %250, %c-1_i32_148 : i32
      %258 = arith.select %256, %257, %250 : i32
      %259 = arith.divsi %258, %c2_i32 : i32
      %260 = arith.muli %259, %c2_i32 : i32
      %261 = arith.cmpi ne, %258, %260 : i32
      %c0_i32_149 = arith.constant 0 : i32
      %262 = arith.cmpi slt, %258, %c0_i32_149 : i32
      %263 = arith.cmpi slt, %c2_i32, %c0_i32_149 : i32
      %264 = arith.cmpi ne, %262, %263 : i1
      %265 = arith.andi %261, %264 : i1
      %c-1_i32_150 = arith.constant -1 : i32
      %266 = arith.addi %259, %c-1_i32_150 : i32
      %267 = arith.select %265, %266, %259 : i32
      %268 = arith.remsi %258, %c2_i32 : i32
      %269 = arith.cmpi eq, %240, %c0_i32 : i32
      cf.cond_br %269, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %coord_151 = cute.make_coord(%267, %268) : (i32, i32) -> !cute.coord<"(?,?)">
      cute.memref.store(%view, %coord_151, %239) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
      cf.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      nvvm.barrier
      %270 = arith.cmpi slt, %240, %c2_i32 : i32
      cf.cond_br %270, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %coord_152 = cute.make_coord(%267, %240) : (i32, i32) -> !cute.coord<"(?,?)">
      %271 = cute.memref.load(%view, %coord_152) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
      cf.br ^bb32(%271 : f32)
    ^bb31:  // pred: ^bb29
      cf.br ^bb32(%cst_0 : f32)
    ^bb32(%272: f32):  // 2 preds: ^bb30, ^bb31
      cf.br ^bb33
    ^bb33:  // pred: ^bb32
      %273 = nvvm.shfl.sync  bfly %c-1_i32, %272, %c16_i32, %c31_i32 : f32 -> f32
      %274 = arith.addf %272, %273 : f32
      %275 = nvvm.shfl.sync  bfly %c-1_i32, %274, %c8_i32, %c31_i32 : f32 -> f32
      %276 = arith.addf %274, %275 : f32
      %277 = nvvm.shfl.sync  bfly %c-1_i32, %276, %c4_i32, %c31_i32 : f32 -> f32
      %278 = arith.addf %276, %277 : f32
      %279 = nvvm.shfl.sync  bfly %c-1_i32, %278, %c2_i32, %c31_i32 : f32 -> f32
      %280 = arith.addf %278, %279 : f32
      %281 = nvvm.shfl.sync  bfly %c-1_i32, %280, %c1_i32, %c31_i32 : f32 -> f32
      %282 = arith.addf %280, %281 : f32
      %283 = arith.divf %282, %cst : f32
      %284 = arith.addf %283, %arg3 : f32
      %285 = math.rsqrt %284 fastmath<fast> : f32
      nvvm.barrier
      cf.br ^bb34(%c0_i32 : i32)
    ^bb34(%286: i32):  // 2 preds: ^bb33, ^bb35
      %287 = arith.cmpi slt, %286, %219 : i32
      cf.cond_br %287, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %coord_153 = cute.make_coord(%286) : (i32) -> !cute.coord<"(_,?)">
      %idx_154 = cute.crd2idx(%coord_153, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
      %ptr_155 = cute.add_offset(%ptr_30, %idx_154) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
      %idx_156 = cute.crd2idx(%coord_153, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_157 = cute.add_offset(%iter_141, %idx_156) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
      %288 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
      %289 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %290 = llvm.load %288 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
      llvm.store %290, %289 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      %291 = arith.addi %286, %c1_i32 : i32
      cf.br ^bb34(%291 : i32)
    ^bb36:  // pred: ^bb34
      %292 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %293 = arith.extf %292 : vector<64xbf16> to vector<64xf32>
      %294 = vector.broadcast %285 : f32 to vector<64xf32>
      %295 = arith.mulf %293, %294 : vector<64xf32>
      %296 = cute.memref.load_vec %view_41 : !memref_rmem_bf16_
      %297 = arith.extf %296 : vector<64xbf16> to vector<64xf32>
      %298 = arith.mulf %295, %297 : vector<64xf32>
      %299 = arith.truncf %298 : vector<64xf32> to vector<64xbf16>
      cute.memref.store_vec %299, %rmem_35 : !memref_rmem_bf16_
      cf.cond_br %138, ^bb37, ^bb57
    ^bb37:  // pred: ^bb36
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%300: i32):  // 2 preds: ^bb37, ^bb55
      %301 = arith.cmpi slt, %300, %167 : i32
      cf.cond_br %301, ^bb39, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      %coord_158 = cute.make_coord(%300) : (i32) -> !cute.coord<"(_,?)">
      %idx_159 = cute.crd2idx(%coord_158, %24) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
      %ptr_160 = cute.add_offset(%iter_43, %idx_159) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
      %302 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
      %303 = llvm.load %302 : !llvm.ptr -> i8
      %304 = llvm.icmp "ne" %303, %9 : i8
      cf.cond_br %304, ^bb40, ^bb41
    ^bb40:  // pred: ^bb39
      %305 = builtin.unrealized_conversion_cast %iter_36 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %306 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %307 = llvm.load %305 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %307, %306 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb41
    ^bb41:  // 2 preds: ^bb39, ^bb40
      %ptr_161 = cute.add_offset(%ptr_160, %23) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %308 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
      %309 = llvm.load %308 : !llvm.ptr -> i8
      %310 = llvm.icmp "ne" %309, %9 : i8
      cf.cond_br %310, ^bb42, ^bb43
    ^bb42:  // pred: ^bb41
      %ptr_162 = cute.add_offset(%iter_36, %8) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_163 = cute.add_offset(%ptr_31, %22) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
      %311 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %312 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %313 = llvm.load %311 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %313, %312 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb41, ^bb42
      %ptr_164 = cute.add_offset(%ptr_160, %20) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
      %314 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem> to !llvm.ptr
      %315 = llvm.load %314 : !llvm.ptr -> i8
      %316 = llvm.icmp "ne" %315, %9 : i8
      cf.cond_br %316, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %ptr_165 = cute.add_offset(%iter_36, %7) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_166 = cute.add_offset(%ptr_31, %21) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
      %317 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %318 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %319 = llvm.load %317 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %319, %318 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb45
    ^bb45:  // 2 preds: ^bb43, ^bb44
      %ptr_167 = cute.add_offset(%ptr_160, %18) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %320 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem> to !llvm.ptr
      %321 = llvm.load %320 : !llvm.ptr -> i8
      %322 = llvm.icmp "ne" %321, %9 : i8
      cf.cond_br %322, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %ptr_168 = cute.add_offset(%iter_36, %6) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_169 = cute.add_offset(%ptr_31, %19) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
      %323 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %324 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %325 = llvm.load %323 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %325, %324 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %ptr_170 = cute.add_offset(%ptr_160, %16) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
      %326 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem> to !llvm.ptr
      %327 = llvm.load %326 : !llvm.ptr -> i8
      %328 = llvm.icmp "ne" %327, %9 : i8
      cf.cond_br %328, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %ptr_171 = cute.add_offset(%iter_36, %5) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_172 = cute.add_offset(%ptr_31, %17) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
      %329 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %330 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %331 = llvm.load %329 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %331, %330 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %ptr_173 = cute.add_offset(%ptr_160, %14) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %332 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<i8, rmem> to !llvm.ptr
      %333 = llvm.load %332 : !llvm.ptr -> i8
      %334 = llvm.icmp "ne" %333, %9 : i8
      cf.cond_br %334, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %ptr_174 = cute.add_offset(%iter_36, %4) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_175 = cute.add_offset(%ptr_31, %15) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
      %335 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %336 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %337 = llvm.load %335 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %337, %336 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %ptr_176 = cute.add_offset(%ptr_160, %12) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
      %338 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<i8, rmem> to !llvm.ptr
      %339 = llvm.load %338 : !llvm.ptr -> i8
      %340 = llvm.icmp "ne" %339, %9 : i8
      cf.cond_br %340, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %ptr_177 = cute.add_offset(%iter_36, %3) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
      %ptr_178 = cute.add_offset(%ptr_31, %13) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
      %341 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
      %342 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %343 = llvm.load %341 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %343, %342 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %ptr_179 = cute.add_offset(%ptr_160, %10) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %344 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<i8, rmem> to !llvm.ptr
      %345 = llvm.load %344 : !llvm.ptr -> i8
      %346 = llvm.icmp "ne" %345, %9 : i8
      cf.cond_br %346, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %ptr_180 = cute.add_offset(%iter_36, %2) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
      %ptr_181 = cute.add_offset(%ptr_31, %11) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
      %347 = builtin.unrealized_conversion_cast %ptr_180 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
      %348 = builtin.unrealized_conversion_cast %ptr_181 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
      %349 = llvm.load %347 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
      llvm.store %349, %348 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %350 = arith.addi %300, %c1_i32 : i32
      cf.br ^bb38(%350 : i32)
    ^bb56:  // pred: ^bb38
      cf.br ^bb57
    ^bb57:  // 2 preds: ^bb36, ^bb56
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
    %c1_i32_2 = arith.constant 1 : i32
    %c0_i32_3 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %3 = arith.cmpi sgt, %c2_i32, %c0_i32_3 : i32
    %4 = arith.select %3, %c-1_i32, %c1_i32_2 : i32
    %5 = arith.addi %4, %2 : i32
    %6 = arith.divsi %5, %c2_i32 : i32
    %7 = arith.addi %c1_i32_2, %6 : i32
    %8 = arith.subi %c0_i32_3, %2 : i32
    %9 = arith.divsi %8, %c2_i32 : i32
    %10 = arith.subi %c0_i32_3, %9 : i32
    %11 = arith.cmpi slt, %2, %c0_i32_3 : i32
    %12 = arith.cmpi sgt, %2, %c0_i32_3 : i32
    %13 = arith.cmpi slt, %c2_i32, %c0_i32_3 : i32
    %14 = arith.cmpi sgt, %c2_i32, %c0_i32_3 : i32
    %15 = arith.andi %11, %13 : i1
    %16 = arith.andi %12, %14 : i1
    %17 = arith.ori %15, %16 : i1
    %18 = arith.select %17, %7, %10 : i32
    %int_tuple_4 = cute.make_int_tuple(%18) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_4) : !cute.int_tuple<"?">
    %19 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %20 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c16400_i64, gridDim = (%19, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %21 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%20> (%view, %view_1, %view_0, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %22 = cuda.cast %21 : !cuda.result -> i32
    cuda.return_if_error %22 : i32
    return %c0_i32 : i32
  }
}
