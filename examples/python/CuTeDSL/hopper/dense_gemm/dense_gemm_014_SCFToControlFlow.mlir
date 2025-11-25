!copy_stsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),(2,2,2)):((64,1,8),(256,32,512))">, tiler_mn = <"[(8,4,2):(1,16,8);(4,2,2):(2,1,8)]">>
!copy_stsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>, layout_copy_tv = <"((4,32),((2,2,2),1)):((64,1),((256,32,512),0))">, tiler_mn = <"[(8,4,2):(1,16,8);(4,2,2):(2,1,8)]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "(((2,2,2),1),1,2):(((1,2,4),0),0,8)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2,16),2,1):((1,2,4),64,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((8,8),2,1):((1,8),64,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(((2,2,2),1),1,2):(((1,2,4),0),0,8)">
!mma_f16_f16_f32_64x128x16_ = !cute.tiled_mma<!cute_nvgpu.sm90.mma<64x128x16, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_unroll1 = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll2 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
#loop_annotation2 = #llvm.loop_annotation<unroll = #loop_unroll2>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel___main__HopperWgmmaGemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1819201_TVLayoutDst1819201_Valuetypef16_tensor000o111012_CopyAtom_ThrID10_TVLayoutSrc1819201_TVL_0(%arg0: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg1: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg2: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg3: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg4: !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg5: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg6: !mma_f16_f16_f32_64x128x16_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"(96,64)">
      %1 = cute.static : !cute.coord<"127">
      %2 = cute.static : !cute.coord<"126">
      %3 = cute.static : !cute.coord<"125">
      %4 = cute.static : !cute.coord<"124">
      %5 = cute.static : !cute.coord<"123">
      %6 = cute.static : !cute.coord<"122">
      %7 = cute.static : !cute.coord<"121">
      %8 = cute.static : !cute.coord<"120">
      %9 = cute.static : !cute.coord<"119">
      %10 = cute.static : !cute.coord<"118">
      %11 = cute.static : !cute.coord<"117">
      %12 = cute.static : !cute.coord<"116">
      %13 = cute.static : !cute.coord<"115">
      %14 = cute.static : !cute.coord<"114">
      %15 = cute.static : !cute.coord<"113">
      %16 = cute.static : !cute.coord<"112">
      %17 = cute.static : !cute.int_tuple<"(64,64)">
      %18 = cute.static : !cute.coord<"111">
      %19 = cute.static : !cute.coord<"110">
      %20 = cute.static : !cute.coord<"109">
      %21 = cute.static : !cute.coord<"108">
      %22 = cute.static : !cute.coord<"107">
      %23 = cute.static : !cute.coord<"106">
      %24 = cute.static : !cute.coord<"105">
      %25 = cute.static : !cute.coord<"104">
      %26 = cute.static : !cute.coord<"103">
      %27 = cute.static : !cute.coord<"102">
      %28 = cute.static : !cute.coord<"101">
      %29 = cute.static : !cute.coord<"100">
      %30 = cute.static : !cute.coord<"99">
      %31 = cute.static : !cute.coord<"98">
      %32 = cute.static : !cute.coord<"97">
      %33 = cute.static : !cute.coord<"96">
      %34 = cute.static : !cute.int_tuple<"(32,64)">
      %35 = cute.static : !cute.coord<"95">
      %36 = cute.static : !cute.coord<"94">
      %37 = cute.static : !cute.coord<"93">
      %38 = cute.static : !cute.coord<"92">
      %39 = cute.static : !cute.coord<"91">
      %40 = cute.static : !cute.coord<"90">
      %41 = cute.static : !cute.coord<"89">
      %42 = cute.static : !cute.coord<"88">
      %43 = cute.static : !cute.coord<"87">
      %44 = cute.static : !cute.coord<"86">
      %45 = cute.static : !cute.coord<"85">
      %46 = cute.static : !cute.coord<"84">
      %47 = cute.static : !cute.coord<"83">
      %48 = cute.static : !cute.coord<"82">
      %49 = cute.static : !cute.coord<"81">
      %50 = cute.static : !cute.coord<"80">
      %51 = cute.static : !cute.int_tuple<"(0,64)">
      %52 = cute.static : !cute.coord<"79">
      %53 = cute.static : !cute.coord<"78">
      %54 = cute.static : !cute.coord<"77">
      %55 = cute.static : !cute.coord<"76">
      %56 = cute.static : !cute.coord<"75">
      %57 = cute.static : !cute.coord<"74">
      %58 = cute.static : !cute.coord<"73">
      %59 = cute.static : !cute.coord<"72">
      %60 = cute.static : !cute.coord<"71">
      %61 = cute.static : !cute.coord<"70">
      %62 = cute.static : !cute.coord<"69">
      %63 = cute.static : !cute.coord<"68">
      %64 = cute.static : !cute.coord<"67">
      %65 = cute.static : !cute.coord<"66">
      %66 = cute.static : !cute.coord<"65">
      %67 = cute.static : !cute.coord<"64">
      %68 = cute.static : !cute.int_tuple<"(96,0)">
      %69 = cute.static : !cute.int_tuple<"6144">
      %70 = cute.static : !cute.coord<"63">
      %71 = cute.static : !cute.coord<"62">
      %72 = cute.static : !cute.coord<"61">
      %73 = cute.static : !cute.coord<"60">
      %74 = cute.static : !cute.coord<"59">
      %75 = cute.static : !cute.coord<"58">
      %76 = cute.static : !cute.coord<"57">
      %77 = cute.static : !cute.coord<"56">
      %78 = cute.static : !cute.coord<"55">
      %79 = cute.static : !cute.coord<"54">
      %80 = cute.static : !cute.coord<"53">
      %81 = cute.static : !cute.coord<"52">
      %82 = cute.static : !cute.coord<"51">
      %83 = cute.static : !cute.coord<"50">
      %84 = cute.static : !cute.coord<"49">
      %85 = cute.static : !cute.coord<"48">
      %86 = cute.static : !cute.int_tuple<"(64,0)">
      %87 = cute.static : !cute.int_tuple<"4096">
      %88 = cute.static : !cute.coord<"47">
      %89 = cute.static : !cute.coord<"46">
      %90 = cute.static : !cute.coord<"45">
      %91 = cute.static : !cute.coord<"44">
      %92 = cute.static : !cute.coord<"43">
      %93 = cute.static : !cute.coord<"42">
      %94 = cute.static : !cute.coord<"41">
      %95 = cute.static : !cute.coord<"40">
      %96 = cute.static : !cute.coord<"39">
      %97 = cute.static : !cute.coord<"38">
      %98 = cute.static : !cute.coord<"37">
      %99 = cute.static : !cute.coord<"36">
      %100 = cute.static : !cute.coord<"35">
      %101 = cute.static : !cute.coord<"34">
      %102 = cute.static : !cute.coord<"33">
      %103 = cute.static : !cute.coord<"32">
      %104 = cute.static : !cute.int_tuple<"(32,0)">
      %105 = cute.static : !cute.int_tuple<"2048">
      %106 = cute.static : !cute.coord<"31">
      %107 = cute.static : !cute.coord<"30">
      %108 = cute.static : !cute.coord<"29">
      %109 = cute.static : !cute.coord<"28">
      %110 = cute.static : !cute.coord<"27">
      %111 = cute.static : !cute.coord<"26">
      %112 = cute.static : !cute.coord<"25">
      %113 = cute.static : !cute.coord<"24">
      %114 = cute.static : !cute.coord<"23">
      %115 = cute.static : !cute.coord<"22">
      %116 = cute.static : !cute.coord<"21">
      %117 = cute.static : !cute.coord<"20">
      %118 = cute.static : !cute.coord<"19">
      %119 = cute.static : !cute.coord<"18">
      %120 = cute.static : !cute.coord<"17">
      %121 = cute.static : !cute.coord<"16">
      %122 = cute.static : !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">
      %123 = cute.static : !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">
      %124 = cute.static : !cute.coord<"15">
      %125 = cute.static : !cute.coord<"14">
      %126 = cute.static : !cute.coord<"13">
      %127 = cute.static : !cute.coord<"12">
      %128 = cute.static : !cute.coord<"11">
      %129 = cute.static : !cute.coord<"10">
      %130 = cute.static : !cute.coord<"9">
      %131 = cute.static : !cute.coord<"8">
      %132 = cute.static : !cute.coord<"7">
      %133 = cute.static : !cute.coord<"6">
      %134 = cute.static : !cute.coord<"5">
      %135 = cute.static : !cute.coord<"4">
      %136 = cute.static : !cute.coord<"3">
      %137 = cute.static : !cute.coord<"2">
      %138 = cute.static : !cute.coord<"1">
      %139 = cute.static : !cute.coord<"0">
      %c512_i32 = arith.constant 512 : i32
      %c256_i32 = arith.constant 256 : i32
      %c2_i32 = arith.constant 2 : i32
      %140 = cute.static : !cute.layout<"(1,2,1):(0,512,0)">
      %141 = cute.static : !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">
      %142 = cute.static : !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">
      %143 = cute.static : !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %c7_i32 = arith.constant 7 : i32
      %144 = cute.static : !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">
      %145 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %146 = cute.static : !cute.stride<"((1@1,1@0),64@0)">
      %147 = cute.static : !cute.stride<"((1@1,1@0),(128@1,128@0,1@2))">
      %148 = cute.static : !cute.int_tuple<"(0,0,0)">
      %149 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %150 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0,1@2))">
      %c64_i32 = arith.constant 64 : i32
      %c128_i32 = arith.constant 128 : i32
      %true = arith.constant true
      %false = arith.constant false
      %c4_i32 = arith.constant 4 : i32
      %151 = cute.static : !cute.int_tuple<"7">
      %152 = cute.static : !cute.int_tuple<"6">
      %153 = cute.static : !cute.int_tuple<"5">
      %154 = cute.static : !cute.int_tuple<"4">
      %155 = cute.static : !cute.int_tuple<"3">
      %156 = cute.static : !cute.int_tuple<"2">
      %157 = cute.static : !cute.int_tuple<"1">
      %158 = cute.static : !cute.int_tuple<"115712">
      %159 = cute.static : !cute.int_tuple<"1024">
      %c1_i32 = arith.constant 1 : i32
      %c8_i32 = arith.constant 8 : i32
      %c0_i32 = arith.constant 0 : i32
      %c32_i32 = arith.constant 32 : i32
      %160 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %161 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %162 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %163 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %164 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %165 = arith.muli %161, %163 : i32
      %166 = arith.addi %160, %165 : i32
      %167 = arith.muli %162, %163 : i32
      %168 = arith.muli %167, %164 : i32
      %169 = arith.addi %166, %168 : i32
      %170 = arith.floordivsi %169, %c32_i32 : i32
      %171 = cute_nvgpu.arch.make_warp_uniform(%170) : i32
      %172 = arith.cmpi eq, %171, %c0_i32 : i32
      cf.cond_br %172, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %173 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %174 = nvvm.read.ptx.sreg.clusterid.x : i32
      %175 = nvvm.read.ptx.sreg.clusterid.y : i32
      %176 = nvvm.read.ptx.sreg.nclusterid.x : i32
      %177 = nvvm.read.ptx.sreg.nclusterid.y : i32
      %178 = arith.muli %176, %175 : i32
      %179 = arith.addi %174, %178 : i32
      %180 = arith.floordivsi %176, %c8_i32 : i32
      %181 = arith.muli %177, %c8_i32 : i32
      %shape = cute.make_shape(%180, %177) : (i32, i32) -> !cute.shape<"((8,?),?)">
      %stride = cute.make_stride(%181) : (i32) -> !cute.stride<"((1,?),8)">
      %lay = cute.make_layout(%shape, %stride) : !cute.layout<"((8,?),?):((1,?),8)">
      %int_tuple = cute.make_int_tuple(%180, %177) : (i32, i32) -> !cute.int_tuple<"((8,?),?)">
      %sz = cute.size(%int_tuple) : (!cute.int_tuple<"((8,?),?)">) -> !cute.int_tuple<"?{div=8}">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?{div=8}">
      %182 = cute.get_scalars(%e0) : !cute.int_tuple<"?{div=8}">
      %int_tuple_0 = cute.make_int_tuple(%179) : (i32) -> !cute.int_tuple<"?">
      %mod = cute.tuple_mod(%int_tuple_0, %e0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.int_tuple<"?">
      %183 = cute.get_scalars(%mod) : !cute.int_tuple<"?">
      %184 = cute.get_flat_coord(%183, %lay) : (i32, !cute.layout<"((8,?),?):((1,?),8)">) -> !cute.coord<"(?,?)">
      %e0_1, %e1 = cute.get_leaves(%184) : !cute.coord<"(?,?)">
      %itup = cute.to_int_tuple(%e0_1) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %185 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_2 = cute.to_int_tuple(%e1) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %186 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
      %187 = arith.cmpi sle, %182, %179 : i32
      cf.cond_br %187, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %188 = arith.remsi %176, %c8_i32 : i32
      %shape_3 = cute.make_shape(%188, %177) : (i32, i32) -> !cute.shape<"(?,?)">
      %stride_4 = cute.make_stride(%188) : (i32) -> !cute.stride<"(1,?)">
      %lay_5 = cute.make_layout(%shape_3, %stride_4) : !cute.layout<"(?,?):(1,?)">
      %sub = cute.tuple_sub(%int_tuple_0, %e0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.int_tuple<"?">
      %189 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %190 = cute.get_flat_coord(%189, %lay_5) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_6, %e1_7 = cute.get_leaves(%190) : !cute.coord<"(?,?)">
      %itup_8 = cute.to_int_tuple(%e0_6) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_9 = cute.to_int_tuple(%e1_7) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %191 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?">
      %sz_10 = cute.size(%int_tuple) <{mode = [0]}> : (!cute.int_tuple<"((8,?),?)">) -> !cute.int_tuple<"?{div=8}">
      %e0_11 = cute.get_leaves(%sz_10) : !cute.int_tuple<"?{div=8}">
      %tup = cute.add_offset(%e0_11, %itup_8) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %192 = cute.get_scalars(%tup) : !cute.int_tuple<"?">
      cf.br ^bb5(%192, %191 : i32, i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb5(%185, %186 : i32, i32)
    ^bb5(%193: i32, %194: i32):  // 2 preds: ^bb3, ^bb4
      cf.br ^bb6
    ^bb6:  // pred: ^bb5
      %195 = nvvm.read.ptx.sreg.cluster.ctaid.x : i32
      %196 = nvvm.read.ptx.sreg.cluster.ctaid.y : i32
      %197 = arith.addi %193, %195 : i32
      %198 = arith.addi %194, %196 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %159) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_12 = cute.add_offset(%smem_ptr, %158) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"115712">) -> !cute.ptr<i8, smem, align<1024>>
      %iter = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %172, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %199 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %199, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_13 = cute.add_offset(%iter, %157) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %200 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %200, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_14 = cute.add_offset(%iter, %156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %201 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %201, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_15 = cute.add_offset(%iter, %155) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %202 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %202, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter, %154) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %203 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %203, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_17 = cute.add_offset(%iter, %153) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %204 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %204, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_18 = cute.add_offset(%iter, %152) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %205 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %205, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_19 = cute.add_offset(%iter, %151) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %172, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %206 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %206, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_20 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_21 = cute.add_offset(%iter, %int_tuple_20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_21) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %207 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %207, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_22 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_23 = cute.add_offset(%iter, %int_tuple_22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %208 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %208, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_24 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_25 = cute.add_offset(%iter, %int_tuple_24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_26 = cute.derefine(%ptr_25) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %209 = builtin.unrealized_conversion_cast %dyn_26 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %209, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_28 = cute.add_offset(%iter, %int_tuple_27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %210 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %210, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_29 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_30 = cute.add_offset(%iter, %int_tuple_29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_31 = cute.derefine(%ptr_30) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %211 = builtin.unrealized_conversion_cast %dyn_31 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %211, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_32 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_33 = cute.add_offset(%iter, %int_tuple_32) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %212 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %212, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %213 = arith.remsi %160, %c32_i32 : i32
      %214 = arith.cmpi slt, %213, %c1_i32 : i32
      %215 = arith.extui %214 : i1 to i32
      %216 = arith.select %214, %c1_i32, %215 : i32
      %217 = arith.cmpi ne, %216, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_34 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_35 = cute.recast_iter(%ptr_12) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_36 = cute.recast_iter(%iter_34) : !cute.ptr<f16, smem, align<1024>, S<3,4,3>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord = cute.make_coord(%197, %198, %173) : (i32, i32, i32) -> !cute.coord<"(?,?,_,?)">
      %218:3 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_,?)">
      %coord_37 = cute.make_coord(%218#0, %218#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_38 = cute.get_layout(%arg1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %219:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %220 = arith.ceildivsi %219#0, %c128_i32 : i32
      %221 = arith.ceildivsi %219#1, %c64_i32 : i32
      %shape_39 = cute.make_shape(%220, %221, %219#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_40 = cute.make_layout(%shape_39, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %222:3 = cute.get_scalars(%lay_40) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_41 = cute.make_shape(%222#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_42 = cute.make_layout(%shape_41, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_37, %lay_40) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_43 = cute.add_offset(%148, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_44 = cute.make_coord(%218#1, %218#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_45 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %223:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %224 = arith.ceildivsi %223#0, %c128_i32 : i32
      %225 = arith.ceildivsi %223#1, %c64_i32 : i32
      %shape_46 = cute.make_shape(%224, %225, %223#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_47 = cute.make_layout(%shape_46, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %226:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_48 = cute.make_shape(%226#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_49 = cute.make_layout(%shape_48, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx_50 = cute.crd2idx(%coord_44, %lay_47) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_51 = cute.add_offset(%148, %idx_50) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_52 = cute.make_coord(%218#0, %218#1, %218#2) : (i32, i32, i32) -> !cute.coord<"((_,_),(?,?,?))">
      %lay_53 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %227:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %228 = arith.ceildivsi %227#0, %c128_i32 : i32
      %229 = arith.ceildivsi %227#1, %c128_i32 : i32
      %shape_54 = cute.make_shape(%228, %229, %227#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_55 = cute.make_layout(%shape_54, %147) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %idx_56 = cute.crd2idx(%coord_52, %lay_55) : (!cute.coord<"((_,_),(?,?,?))">, !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %tup_57 = cute.add_offset(%148, %idx_56) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %230 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_58 = cute.make_shape(%230) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_59 = cute.make_layout(%shape_58, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %231 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_60 = cute.make_shape(%231) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_61 = cute.make_layout(%shape_60, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %232 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_62 = cute.make_shape(%232) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_63 = cute.make_layout(%shape_62, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %233 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_64 = cute.make_shape(%233) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_65 = cute.make_layout(%shape_64, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %gmmaSmemDesc = cute_nvgpu.make_gmma_smem_desc(%iter_34 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((64,16),2,4,(1,7)):((64,1),4096,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %gmmaSmemDesc_66 = cute_nvgpu.make_gmma_smem_desc(%iter_35 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,(1,7)):((64,1),0,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      nvvm.barrier
      %sz_67 = cute.size(%lay_42) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_68 = cute.get_leaves(%sz_67) : !cute.int_tuple<"?">
      %234 = cute.get_scalars(%e0_68) : !cute.int_tuple<"?">
      %235 = arith.minsi %234, %c7_i32 : i32
      %236 = arith.maxsi %235, %c0_i32 : i32
      cf.cond_br %172, ^bb11, ^bb27
    ^bb11:  // pred: ^bb10
      %237 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %238 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %239 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb12(%c0_i32, %c0_i32, %c0_i32, %c1_i32 : i32, i32, i32, i32)
    ^bb12(%240: i32, %241: i32, %242: i32, %243: i32):  // 2 preds: ^bb11, ^bb25
      %244 = arith.cmpi slt, %240, %236 : i32
      cf.cond_br %244, ^bb13, ^bb26 {loop_annotation = #loop_annotation}
    ^bb13:  // pred: ^bb12
      %int_tuple_69 = cute.make_int_tuple(%242) : (i32) -> !cute.int_tuple<"?">
      %ptr_70 = cute.add_offset(%ptr_19, %int_tuple_69) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %245 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %245, %243, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %246 = nvvm.elect.sync -> i1
      cf.cond_br %246, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %ptr_71 = cute.add_offset(%iter, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %247 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %247, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %coord_72 = cute.make_coord(%241) : (i32) -> !cute.coord<"(_,?)">
      %idx_73 = cute.crd2idx(%coord_72, %lay_61) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_74 = cute.add_offset(%tup_43, %idx_73) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_75, %e1_76, %e2 = cute.get_leaves(%tup_74) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %coord_77 = cute.make_coord(%242) : (i32) -> !cute.coord<"(_,?)">
      %idx_78 = cute.crd2idx(%coord_77, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_79 = cute.add_offset(%iter_34, %idx_78) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_80 = cute.crd2idx(%coord_72, %lay_65) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_81 = cute.add_offset(%tup_51, %idx_80) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_82, %e1_83, %e2_84 = cute.get_leaves(%tup_81) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %ptr_85 = cute.add_offset(%iter_35, %idx_78) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_86 = cute.add_offset(%iter, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_87 = cute.make_int_tuple(%e0_75, %e1_76, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %248 = cute_nvgpu.atom.set_value(%237, %ptr_86 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %249 = cute_nvgpu.atom.get_value(%248 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%248 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %250:3 = cute.get_scalars(%int_tuple_87) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb16(%c0_i32 : i32)
    ^bb16(%251: i32):  // 2 preds: ^bb15, ^bb17
      %252 = arith.cmpi slt, %251, %238 : i32
      cf.cond_br %252, ^bb17, ^bb18 {llvm.loop_annotation = #loop_annotation1}
    ^bb17:  // pred: ^bb16
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_79 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %249 : !cute.ptr<smem, align<8>>, [%250#0, %250#1, %250#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %253 = arith.addi %251, %c1_i32 : i32
      cf.br ^bb16(%253 : i32)
    ^bb18:  // pred: ^bb16
      %int_tuple_88 = cute.make_int_tuple(%e0_82, %e1_83, %e2_84) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %254 = cute_nvgpu.atom.set_value(%239, %ptr_86 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %255 = cute_nvgpu.atom.get_value(%254 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_89 = cute_nvgpu.get_tma_desc_addr(%254 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %256:3 = cute.get_scalars(%int_tuple_88) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%257: i32):  // 2 preds: ^bb18, ^bb20
      %258 = arith.cmpi slt, %257, %238 : i32
      cf.cond_br %258, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation1}
    ^bb20:  // pred: ^bb19
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_89 : !cute.ptr<generic, align<64>>, %ptr_85 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %255 : !cute.ptr<smem, align<8>>, [%256#0, %256#1, %256#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %259 = arith.addi %257, %c1_i32 : i32
      cf.br ^bb19(%259 : i32)
    ^bb21:  // pred: ^bb19
      %260 = arith.addi %242, %c1_i32 : i32
      %261 = arith.addi %241, %c1_i32 : i32
      %262 = arith.cmpi eq, %260, %c7_i32 : i32
      %263 = arith.select %262, %c0_i32, %260 : i32
      cf.cond_br %262, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %264 = arith.xori %243, %c1_i32 : i32
      cf.br ^bb24(%264 : i32)
    ^bb23:  // pred: ^bb21
      cf.br ^bb24(%243 : i32)
    ^bb24(%265: i32):  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // pred: ^bb24
      %266 = arith.addi %240, %c1_i32 : i32
      cf.br ^bb12(%266, %261, %263, %265 : i32, i32, i32, i32)
    ^bb26:  // pred: ^bb12
      cf.br ^bb28(%241, %242, %243 : i32, i32, i32)
    ^bb27:  // pred: ^bb10
      cf.br ^bb28(%c0_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb28(%267: i32, %268: i32, %269: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %270 = arith.cmpi sgt, %234, %c0_i32 : i32
      cf.cond_br %270, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %dyn_90 = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
      %271 = builtin.unrealized_conversion_cast %dyn_90 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %272 = nvvm.mbarrier.wait.parity %271, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb32(%272 : i1)
    ^bb31:  // pred: ^bb29
      cf.br ^bb32(%true : i1)
    ^bb32(%273: i1):  // 2 preds: ^bb30, ^bb31
      cf.br ^bb33
    ^bb33:  // pred: ^bb32
      %274 = cute_nvgpu.atom.set_value(%arg6, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
      %275 = builtin.unrealized_conversion_cast %274 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
      %276 = arith.extui %273 : i1 to i32
      %277 = arith.cmpi eq, %276, %c0_i32 : i32
      cf.cond_br %277, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %dyn_91 = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
      %278 = builtin.unrealized_conversion_cast %dyn_91 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %278, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb35
    ^bb35:  // 2 preds: ^bb33, ^bb34
      nvvm.wgmma.fence.aligned
      %iter_92 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %279 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %280 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      cf.br ^bb36(%c0_i32, %275 : i32, !llvm.struct<(i1)>)
    ^bb36(%281: i32, %282: !llvm.struct<(i1)>):  // 2 preds: ^bb35, ^bb46
      %283 = arith.cmpi slt, %281, %c4_i32 : i32
      cf.cond_br %283, ^bb37, ^bb47 {loop_annotation = #loop_annotation2}
    ^bb37:  // pred: ^bb36
      %284 = builtin.unrealized_conversion_cast %282 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
      %coord_93 = cute.make_coord(%281) : (i32) -> !cute.coord<"(_,_,?,0)">
      %idx_94 = cute.crd2idx(%coord_93, %142) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_95 = cute.add_offset(%gmmaSmemDesc, %idx_94) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_96 = cute.crd2idx(%coord_93, %141) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_97 = cute.add_offset(%gmmaSmemDesc_66, %idx_96) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %285 = cute_nvgpu.atom.get_value(%284 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%286: i32):  // 2 preds: ^bb37, ^bb45
      %287 = arith.cmpi slt, %286, %279 : i32
      cf.cond_br %287, ^bb39, ^bb46 {llvm.loop_annotation = #loop_annotation1}
    ^bb39:  // pred: ^bb38
      cf.br ^bb40(%c0_i32 : i32)
    ^bb40(%288: i32):  // 2 preds: ^bb39, ^bb44
      %289 = arith.cmpi slt, %288, %280 : i32
      cf.cond_br %289, ^bb41, ^bb45 {llvm.loop_annotation = #loop_annotation1}
    ^bb41:  // pred: ^bb40
      %coord_98 = cute.make_coord(%288, %286) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_99 = cute.crd2idx(%coord_98, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
      %tup_100 = cute.add_offset(%tup_95, %idx_99) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%290: i32):  // 2 preds: ^bb41, ^bb43
      %291 = arith.cmpi slt, %290, %279 : i32
      cf.cond_br %291, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation1}
    ^bb43:  // pred: ^bb42
      %coord_101 = cute.make_coord(%288, %290) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_102 = cute.crd2idx(%coord_101, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_103 = cute.add_offset(%iter_92, %idx_102) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
      %292 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %293 = llvm.load %292 : !llvm.ptr -> f32
      %294 = llvm.getelementptr %292[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %295 = llvm.load %294 : !llvm.ptr -> f32
      %296 = llvm.getelementptr %292[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %297 = llvm.load %296 : !llvm.ptr -> f32
      %298 = llvm.getelementptr %292[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %299 = llvm.load %298 : !llvm.ptr -> f32
      %300 = llvm.getelementptr %292[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %301 = llvm.load %300 : !llvm.ptr -> f32
      %302 = llvm.getelementptr %292[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %303 = llvm.load %302 : !llvm.ptr -> f32
      %304 = llvm.getelementptr %292[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %305 = llvm.load %304 : !llvm.ptr -> f32
      %306 = llvm.getelementptr %292[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %307 = llvm.load %306 : !llvm.ptr -> f32
      %308 = llvm.getelementptr %292[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %309 = llvm.load %308 : !llvm.ptr -> f32
      %310 = llvm.getelementptr %292[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %311 = llvm.load %310 : !llvm.ptr -> f32
      %312 = llvm.getelementptr %292[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %313 = llvm.load %312 : !llvm.ptr -> f32
      %314 = llvm.getelementptr %292[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %315 = llvm.load %314 : !llvm.ptr -> f32
      %316 = llvm.getelementptr %292[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %317 = llvm.load %316 : !llvm.ptr -> f32
      %318 = llvm.getelementptr %292[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %319 = llvm.load %318 : !llvm.ptr -> f32
      %320 = llvm.getelementptr %292[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %321 = llvm.load %320 : !llvm.ptr -> f32
      %322 = llvm.getelementptr %292[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %323 = llvm.load %322 : !llvm.ptr -> f32
      %324 = llvm.getelementptr %292[16] : (!llvm.ptr) -> !llvm.ptr, f32
      %325 = llvm.load %324 : !llvm.ptr -> f32
      %326 = llvm.getelementptr %292[17] : (!llvm.ptr) -> !llvm.ptr, f32
      %327 = llvm.load %326 : !llvm.ptr -> f32
      %328 = llvm.getelementptr %292[18] : (!llvm.ptr) -> !llvm.ptr, f32
      %329 = llvm.load %328 : !llvm.ptr -> f32
      %330 = llvm.getelementptr %292[19] : (!llvm.ptr) -> !llvm.ptr, f32
      %331 = llvm.load %330 : !llvm.ptr -> f32
      %332 = llvm.getelementptr %292[20] : (!llvm.ptr) -> !llvm.ptr, f32
      %333 = llvm.load %332 : !llvm.ptr -> f32
      %334 = llvm.getelementptr %292[21] : (!llvm.ptr) -> !llvm.ptr, f32
      %335 = llvm.load %334 : !llvm.ptr -> f32
      %336 = llvm.getelementptr %292[22] : (!llvm.ptr) -> !llvm.ptr, f32
      %337 = llvm.load %336 : !llvm.ptr -> f32
      %338 = llvm.getelementptr %292[23] : (!llvm.ptr) -> !llvm.ptr, f32
      %339 = llvm.load %338 : !llvm.ptr -> f32
      %340 = llvm.getelementptr %292[24] : (!llvm.ptr) -> !llvm.ptr, f32
      %341 = llvm.load %340 : !llvm.ptr -> f32
      %342 = llvm.getelementptr %292[25] : (!llvm.ptr) -> !llvm.ptr, f32
      %343 = llvm.load %342 : !llvm.ptr -> f32
      %344 = llvm.getelementptr %292[26] : (!llvm.ptr) -> !llvm.ptr, f32
      %345 = llvm.load %344 : !llvm.ptr -> f32
      %346 = llvm.getelementptr %292[27] : (!llvm.ptr) -> !llvm.ptr, f32
      %347 = llvm.load %346 : !llvm.ptr -> f32
      %348 = llvm.getelementptr %292[28] : (!llvm.ptr) -> !llvm.ptr, f32
      %349 = llvm.load %348 : !llvm.ptr -> f32
      %350 = llvm.getelementptr %292[29] : (!llvm.ptr) -> !llvm.ptr, f32
      %351 = llvm.load %350 : !llvm.ptr -> f32
      %352 = llvm.getelementptr %292[30] : (!llvm.ptr) -> !llvm.ptr, f32
      %353 = llvm.load %352 : !llvm.ptr -> f32
      %354 = llvm.getelementptr %292[31] : (!llvm.ptr) -> !llvm.ptr, f32
      %355 = llvm.load %354 : !llvm.ptr -> f32
      %356 = llvm.getelementptr %292[32] : (!llvm.ptr) -> !llvm.ptr, f32
      %357 = llvm.load %356 : !llvm.ptr -> f32
      %358 = llvm.getelementptr %292[33] : (!llvm.ptr) -> !llvm.ptr, f32
      %359 = llvm.load %358 : !llvm.ptr -> f32
      %360 = llvm.getelementptr %292[34] : (!llvm.ptr) -> !llvm.ptr, f32
      %361 = llvm.load %360 : !llvm.ptr -> f32
      %362 = llvm.getelementptr %292[35] : (!llvm.ptr) -> !llvm.ptr, f32
      %363 = llvm.load %362 : !llvm.ptr -> f32
      %364 = llvm.getelementptr %292[36] : (!llvm.ptr) -> !llvm.ptr, f32
      %365 = llvm.load %364 : !llvm.ptr -> f32
      %366 = llvm.getelementptr %292[37] : (!llvm.ptr) -> !llvm.ptr, f32
      %367 = llvm.load %366 : !llvm.ptr -> f32
      %368 = llvm.getelementptr %292[38] : (!llvm.ptr) -> !llvm.ptr, f32
      %369 = llvm.load %368 : !llvm.ptr -> f32
      %370 = llvm.getelementptr %292[39] : (!llvm.ptr) -> !llvm.ptr, f32
      %371 = llvm.load %370 : !llvm.ptr -> f32
      %372 = llvm.getelementptr %292[40] : (!llvm.ptr) -> !llvm.ptr, f32
      %373 = llvm.load %372 : !llvm.ptr -> f32
      %374 = llvm.getelementptr %292[41] : (!llvm.ptr) -> !llvm.ptr, f32
      %375 = llvm.load %374 : !llvm.ptr -> f32
      %376 = llvm.getelementptr %292[42] : (!llvm.ptr) -> !llvm.ptr, f32
      %377 = llvm.load %376 : !llvm.ptr -> f32
      %378 = llvm.getelementptr %292[43] : (!llvm.ptr) -> !llvm.ptr, f32
      %379 = llvm.load %378 : !llvm.ptr -> f32
      %380 = llvm.getelementptr %292[44] : (!llvm.ptr) -> !llvm.ptr, f32
      %381 = llvm.load %380 : !llvm.ptr -> f32
      %382 = llvm.getelementptr %292[45] : (!llvm.ptr) -> !llvm.ptr, f32
      %383 = llvm.load %382 : !llvm.ptr -> f32
      %384 = llvm.getelementptr %292[46] : (!llvm.ptr) -> !llvm.ptr, f32
      %385 = llvm.load %384 : !llvm.ptr -> f32
      %386 = llvm.getelementptr %292[47] : (!llvm.ptr) -> !llvm.ptr, f32
      %387 = llvm.load %386 : !llvm.ptr -> f32
      %388 = llvm.getelementptr %292[48] : (!llvm.ptr) -> !llvm.ptr, f32
      %389 = llvm.load %388 : !llvm.ptr -> f32
      %390 = llvm.getelementptr %292[49] : (!llvm.ptr) -> !llvm.ptr, f32
      %391 = llvm.load %390 : !llvm.ptr -> f32
      %392 = llvm.getelementptr %292[50] : (!llvm.ptr) -> !llvm.ptr, f32
      %393 = llvm.load %392 : !llvm.ptr -> f32
      %394 = llvm.getelementptr %292[51] : (!llvm.ptr) -> !llvm.ptr, f32
      %395 = llvm.load %394 : !llvm.ptr -> f32
      %396 = llvm.getelementptr %292[52] : (!llvm.ptr) -> !llvm.ptr, f32
      %397 = llvm.load %396 : !llvm.ptr -> f32
      %398 = llvm.getelementptr %292[53] : (!llvm.ptr) -> !llvm.ptr, f32
      %399 = llvm.load %398 : !llvm.ptr -> f32
      %400 = llvm.getelementptr %292[54] : (!llvm.ptr) -> !llvm.ptr, f32
      %401 = llvm.load %400 : !llvm.ptr -> f32
      %402 = llvm.getelementptr %292[55] : (!llvm.ptr) -> !llvm.ptr, f32
      %403 = llvm.load %402 : !llvm.ptr -> f32
      %404 = llvm.getelementptr %292[56] : (!llvm.ptr) -> !llvm.ptr, f32
      %405 = llvm.load %404 : !llvm.ptr -> f32
      %406 = llvm.getelementptr %292[57] : (!llvm.ptr) -> !llvm.ptr, f32
      %407 = llvm.load %406 : !llvm.ptr -> f32
      %408 = llvm.getelementptr %292[58] : (!llvm.ptr) -> !llvm.ptr, f32
      %409 = llvm.load %408 : !llvm.ptr -> f32
      %410 = llvm.getelementptr %292[59] : (!llvm.ptr) -> !llvm.ptr, f32
      %411 = llvm.load %410 : !llvm.ptr -> f32
      %412 = llvm.getelementptr %292[60] : (!llvm.ptr) -> !llvm.ptr, f32
      %413 = llvm.load %412 : !llvm.ptr -> f32
      %414 = llvm.getelementptr %292[61] : (!llvm.ptr) -> !llvm.ptr, f32
      %415 = llvm.load %414 : !llvm.ptr -> f32
      %416 = llvm.getelementptr %292[62] : (!llvm.ptr) -> !llvm.ptr, f32
      %417 = llvm.load %416 : !llvm.ptr -> f32
      %418 = llvm.getelementptr %292[63] : (!llvm.ptr) -> !llvm.ptr, f32
      %419 = llvm.load %418 : !llvm.ptr -> f32
      %420:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_100 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_97 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%293, %295, %297, %299, %301, %303, %305, %307, %309, %311, %313, %315, %317, %319, %321, %323, %325, %327, %329, %331, %333, %335, %337, %339, %341, %343, %345, %347, %349, %351, %353, %355, %357, %359, %361, %363, %365, %367, %369, %371, %373, %375, %377, %379, %381, %383, %385, %387, %389, %391, %393, %395, %397, %399, %401, %403, %405, %407, %409, %411, %413, %415, %417, %419], accum = %285 : i1)
< {cd_type = f32, operandSegmentSizes = array<i32: 1, 1, 64, 1>}> :(!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, f32, i1) -> (f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32)
      llvm.store %420#0, %292 : f32, !llvm.ptr
      llvm.store %420#1, %294 : f32, !llvm.ptr
      llvm.store %420#2, %296 : f32, !llvm.ptr
      llvm.store %420#3, %298 : f32, !llvm.ptr
      llvm.store %420#4, %300 : f32, !llvm.ptr
      llvm.store %420#5, %302 : f32, !llvm.ptr
      llvm.store %420#6, %304 : f32, !llvm.ptr
      llvm.store %420#7, %306 : f32, !llvm.ptr
      llvm.store %420#8, %308 : f32, !llvm.ptr
      llvm.store %420#9, %310 : f32, !llvm.ptr
      llvm.store %420#10, %312 : f32, !llvm.ptr
      llvm.store %420#11, %314 : f32, !llvm.ptr
      llvm.store %420#12, %316 : f32, !llvm.ptr
      llvm.store %420#13, %318 : f32, !llvm.ptr
      llvm.store %420#14, %320 : f32, !llvm.ptr
      llvm.store %420#15, %322 : f32, !llvm.ptr
      llvm.store %420#16, %324 : f32, !llvm.ptr
      llvm.store %420#17, %326 : f32, !llvm.ptr
      llvm.store %420#18, %328 : f32, !llvm.ptr
      llvm.store %420#19, %330 : f32, !llvm.ptr
      llvm.store %420#20, %332 : f32, !llvm.ptr
      llvm.store %420#21, %334 : f32, !llvm.ptr
      llvm.store %420#22, %336 : f32, !llvm.ptr
      llvm.store %420#23, %338 : f32, !llvm.ptr
      llvm.store %420#24, %340 : f32, !llvm.ptr
      llvm.store %420#25, %342 : f32, !llvm.ptr
      llvm.store %420#26, %344 : f32, !llvm.ptr
      llvm.store %420#27, %346 : f32, !llvm.ptr
      llvm.store %420#28, %348 : f32, !llvm.ptr
      llvm.store %420#29, %350 : f32, !llvm.ptr
      llvm.store %420#30, %352 : f32, !llvm.ptr
      llvm.store %420#31, %354 : f32, !llvm.ptr
      llvm.store %420#32, %356 : f32, !llvm.ptr
      llvm.store %420#33, %358 : f32, !llvm.ptr
      llvm.store %420#34, %360 : f32, !llvm.ptr
      llvm.store %420#35, %362 : f32, !llvm.ptr
      llvm.store %420#36, %364 : f32, !llvm.ptr
      llvm.store %420#37, %366 : f32, !llvm.ptr
      llvm.store %420#38, %368 : f32, !llvm.ptr
      llvm.store %420#39, %370 : f32, !llvm.ptr
      llvm.store %420#40, %372 : f32, !llvm.ptr
      llvm.store %420#41, %374 : f32, !llvm.ptr
      llvm.store %420#42, %376 : f32, !llvm.ptr
      llvm.store %420#43, %378 : f32, !llvm.ptr
      llvm.store %420#44, %380 : f32, !llvm.ptr
      llvm.store %420#45, %382 : f32, !llvm.ptr
      llvm.store %420#46, %384 : f32, !llvm.ptr
      llvm.store %420#47, %386 : f32, !llvm.ptr
      llvm.store %420#48, %388 : f32, !llvm.ptr
      llvm.store %420#49, %390 : f32, !llvm.ptr
      llvm.store %420#50, %392 : f32, !llvm.ptr
      llvm.store %420#51, %394 : f32, !llvm.ptr
      llvm.store %420#52, %396 : f32, !llvm.ptr
      llvm.store %420#53, %398 : f32, !llvm.ptr
      llvm.store %420#54, %400 : f32, !llvm.ptr
      llvm.store %420#55, %402 : f32, !llvm.ptr
      llvm.store %420#56, %404 : f32, !llvm.ptr
      llvm.store %420#57, %406 : f32, !llvm.ptr
      llvm.store %420#58, %408 : f32, !llvm.ptr
      llvm.store %420#59, %410 : f32, !llvm.ptr
      llvm.store %420#60, %412 : f32, !llvm.ptr
      llvm.store %420#61, %414 : f32, !llvm.ptr
      llvm.store %420#62, %416 : f32, !llvm.ptr
      llvm.store %420#63, %418 : f32, !llvm.ptr
      %421 = arith.addi %290, %c1_i32 : i32
      cf.br ^bb42(%421 : i32)
    ^bb44:  // pred: ^bb42
      %422 = arith.addi %288, %c1_i32 : i32
      cf.br ^bb40(%422 : i32)
    ^bb45:  // pred: ^bb40
      %423 = arith.addi %286, %c1_i32 : i32
      cf.br ^bb38(%423 : i32)
    ^bb46:  // pred: ^bb38
      %424 = cute_nvgpu.atom.set_value(%284, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
      %425 = builtin.unrealized_conversion_cast %424 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
      %426 = arith.addi %281, %c1_i32 : i32
      cf.br ^bb36(%426, %425 : i32, !llvm.struct<(i1)>)
    ^bb47:  // pred: ^bb36
      %427 = builtin.unrealized_conversion_cast %282 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
      nvvm.wgmma.commit.group.sync.aligned
      %428 = arith.cmpi sgt, %234, %c1_i32 : i32
      cf.cond_br %428, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %int_tuple_104 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %ptr_105 = cute.add_offset(%iter, %int_tuple_104) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %429 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %430 = nvvm.mbarrier.wait.parity %429, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb50(%430 : i1)
    ^bb49:  // pred: ^bb47
      cf.br ^bb50(%true : i1)
    ^bb50(%431: i1):  // 2 preds: ^bb48, ^bb49
      cf.br ^bb51
    ^bb51:  // pred: ^bb50
      %iter_106 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %432 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %433 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      %434 = cute_nvgpu.atom.get_value(%427 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
      %435 = arith.extui %172 : i1 to i32
      cf.br ^bb52(%c1_i32, %431, %c1_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %267, %268, %269 : i32, i1, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb52(%436: i32, %437: i1, %438: i32, %439: i32, %440: i32, %441: i32, %442: i32, %443: i32, %444: i32, %445: i32, %446: i32):  // 2 preds: ^bb51, ^bb97
      %447 = arith.cmpi slt, %436, %234 : i32
      cf.cond_br %447, ^bb53, ^bb98 {loop_annotation = #loop_annotation}
    ^bb53:  // pred: ^bb52
      %448 = arith.extui %437 : i1 to i32
      %449 = arith.cmpi eq, %448, %c0_i32 : i32
      cf.cond_br %449, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %int_tuple_107 = cute.make_int_tuple(%439) : (i32) -> !cute.int_tuple<"?">
      %ptr_108 = cute.add_offset(%iter, %int_tuple_107) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %450 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %450, %440, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      nvvm.wgmma.fence.aligned
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%451: i32):  // 2 preds: ^bb55, ^bb66
      %452 = arith.cmpi slt, %451, %c4_i32 : i32
      cf.cond_br %452, ^bb57, ^bb67 {loop_annotation = #loop_annotation2}
    ^bb57:  // pred: ^bb56
      %coord_109 = cute.make_coord(%451, %439) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_110 = cute.crd2idx(%coord_109, %142) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_111 = cute.add_offset(%gmmaSmemDesc, %idx_110) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_112 = cute.crd2idx(%coord_109, %141) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_113 = cute.add_offset(%gmmaSmemDesc_66, %idx_112) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb58(%c0_i32 : i32)
    ^bb58(%453: i32):  // 2 preds: ^bb57, ^bb65
      %454 = arith.cmpi slt, %453, %432 : i32
      cf.cond_br %454, ^bb59, ^bb66 {llvm.loop_annotation = #loop_annotation1}
    ^bb59:  // pred: ^bb58
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%455: i32):  // 2 preds: ^bb59, ^bb64
      %456 = arith.cmpi slt, %455, %433 : i32
      cf.cond_br %456, ^bb61, ^bb65 {llvm.loop_annotation = #loop_annotation1}
    ^bb61:  // pred: ^bb60
      %coord_114 = cute.make_coord(%455, %453) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_115 = cute.crd2idx(%coord_114, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
      %tup_116 = cute.add_offset(%tup_111, %idx_115) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%457: i32):  // 2 preds: ^bb61, ^bb63
      %458 = arith.cmpi slt, %457, %432 : i32
      cf.cond_br %458, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation1}
    ^bb63:  // pred: ^bb62
      %coord_117 = cute.make_coord(%455, %457) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_118 = cute.crd2idx(%coord_117, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_119 = cute.add_offset(%iter_106, %idx_118) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
      %459 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %460 = llvm.load %459 : !llvm.ptr -> f32
      %461 = llvm.getelementptr %459[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %462 = llvm.load %461 : !llvm.ptr -> f32
      %463 = llvm.getelementptr %459[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %464 = llvm.load %463 : !llvm.ptr -> f32
      %465 = llvm.getelementptr %459[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %466 = llvm.load %465 : !llvm.ptr -> f32
      %467 = llvm.getelementptr %459[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %468 = llvm.load %467 : !llvm.ptr -> f32
      %469 = llvm.getelementptr %459[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %470 = llvm.load %469 : !llvm.ptr -> f32
      %471 = llvm.getelementptr %459[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %472 = llvm.load %471 : !llvm.ptr -> f32
      %473 = llvm.getelementptr %459[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %474 = llvm.load %473 : !llvm.ptr -> f32
      %475 = llvm.getelementptr %459[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %476 = llvm.load %475 : !llvm.ptr -> f32
      %477 = llvm.getelementptr %459[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %478 = llvm.load %477 : !llvm.ptr -> f32
      %479 = llvm.getelementptr %459[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %480 = llvm.load %479 : !llvm.ptr -> f32
      %481 = llvm.getelementptr %459[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %482 = llvm.load %481 : !llvm.ptr -> f32
      %483 = llvm.getelementptr %459[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %484 = llvm.load %483 : !llvm.ptr -> f32
      %485 = llvm.getelementptr %459[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %486 = llvm.load %485 : !llvm.ptr -> f32
      %487 = llvm.getelementptr %459[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %488 = llvm.load %487 : !llvm.ptr -> f32
      %489 = llvm.getelementptr %459[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %490 = llvm.load %489 : !llvm.ptr -> f32
      %491 = llvm.getelementptr %459[16] : (!llvm.ptr) -> !llvm.ptr, f32
      %492 = llvm.load %491 : !llvm.ptr -> f32
      %493 = llvm.getelementptr %459[17] : (!llvm.ptr) -> !llvm.ptr, f32
      %494 = llvm.load %493 : !llvm.ptr -> f32
      %495 = llvm.getelementptr %459[18] : (!llvm.ptr) -> !llvm.ptr, f32
      %496 = llvm.load %495 : !llvm.ptr -> f32
      %497 = llvm.getelementptr %459[19] : (!llvm.ptr) -> !llvm.ptr, f32
      %498 = llvm.load %497 : !llvm.ptr -> f32
      %499 = llvm.getelementptr %459[20] : (!llvm.ptr) -> !llvm.ptr, f32
      %500 = llvm.load %499 : !llvm.ptr -> f32
      %501 = llvm.getelementptr %459[21] : (!llvm.ptr) -> !llvm.ptr, f32
      %502 = llvm.load %501 : !llvm.ptr -> f32
      %503 = llvm.getelementptr %459[22] : (!llvm.ptr) -> !llvm.ptr, f32
      %504 = llvm.load %503 : !llvm.ptr -> f32
      %505 = llvm.getelementptr %459[23] : (!llvm.ptr) -> !llvm.ptr, f32
      %506 = llvm.load %505 : !llvm.ptr -> f32
      %507 = llvm.getelementptr %459[24] : (!llvm.ptr) -> !llvm.ptr, f32
      %508 = llvm.load %507 : !llvm.ptr -> f32
      %509 = llvm.getelementptr %459[25] : (!llvm.ptr) -> !llvm.ptr, f32
      %510 = llvm.load %509 : !llvm.ptr -> f32
      %511 = llvm.getelementptr %459[26] : (!llvm.ptr) -> !llvm.ptr, f32
      %512 = llvm.load %511 : !llvm.ptr -> f32
      %513 = llvm.getelementptr %459[27] : (!llvm.ptr) -> !llvm.ptr, f32
      %514 = llvm.load %513 : !llvm.ptr -> f32
      %515 = llvm.getelementptr %459[28] : (!llvm.ptr) -> !llvm.ptr, f32
      %516 = llvm.load %515 : !llvm.ptr -> f32
      %517 = llvm.getelementptr %459[29] : (!llvm.ptr) -> !llvm.ptr, f32
      %518 = llvm.load %517 : !llvm.ptr -> f32
      %519 = llvm.getelementptr %459[30] : (!llvm.ptr) -> !llvm.ptr, f32
      %520 = llvm.load %519 : !llvm.ptr -> f32
      %521 = llvm.getelementptr %459[31] : (!llvm.ptr) -> !llvm.ptr, f32
      %522 = llvm.load %521 : !llvm.ptr -> f32
      %523 = llvm.getelementptr %459[32] : (!llvm.ptr) -> !llvm.ptr, f32
      %524 = llvm.load %523 : !llvm.ptr -> f32
      %525 = llvm.getelementptr %459[33] : (!llvm.ptr) -> !llvm.ptr, f32
      %526 = llvm.load %525 : !llvm.ptr -> f32
      %527 = llvm.getelementptr %459[34] : (!llvm.ptr) -> !llvm.ptr, f32
      %528 = llvm.load %527 : !llvm.ptr -> f32
      %529 = llvm.getelementptr %459[35] : (!llvm.ptr) -> !llvm.ptr, f32
      %530 = llvm.load %529 : !llvm.ptr -> f32
      %531 = llvm.getelementptr %459[36] : (!llvm.ptr) -> !llvm.ptr, f32
      %532 = llvm.load %531 : !llvm.ptr -> f32
      %533 = llvm.getelementptr %459[37] : (!llvm.ptr) -> !llvm.ptr, f32
      %534 = llvm.load %533 : !llvm.ptr -> f32
      %535 = llvm.getelementptr %459[38] : (!llvm.ptr) -> !llvm.ptr, f32
      %536 = llvm.load %535 : !llvm.ptr -> f32
      %537 = llvm.getelementptr %459[39] : (!llvm.ptr) -> !llvm.ptr, f32
      %538 = llvm.load %537 : !llvm.ptr -> f32
      %539 = llvm.getelementptr %459[40] : (!llvm.ptr) -> !llvm.ptr, f32
      %540 = llvm.load %539 : !llvm.ptr -> f32
      %541 = llvm.getelementptr %459[41] : (!llvm.ptr) -> !llvm.ptr, f32
      %542 = llvm.load %541 : !llvm.ptr -> f32
      %543 = llvm.getelementptr %459[42] : (!llvm.ptr) -> !llvm.ptr, f32
      %544 = llvm.load %543 : !llvm.ptr -> f32
      %545 = llvm.getelementptr %459[43] : (!llvm.ptr) -> !llvm.ptr, f32
      %546 = llvm.load %545 : !llvm.ptr -> f32
      %547 = llvm.getelementptr %459[44] : (!llvm.ptr) -> !llvm.ptr, f32
      %548 = llvm.load %547 : !llvm.ptr -> f32
      %549 = llvm.getelementptr %459[45] : (!llvm.ptr) -> !llvm.ptr, f32
      %550 = llvm.load %549 : !llvm.ptr -> f32
      %551 = llvm.getelementptr %459[46] : (!llvm.ptr) -> !llvm.ptr, f32
      %552 = llvm.load %551 : !llvm.ptr -> f32
      %553 = llvm.getelementptr %459[47] : (!llvm.ptr) -> !llvm.ptr, f32
      %554 = llvm.load %553 : !llvm.ptr -> f32
      %555 = llvm.getelementptr %459[48] : (!llvm.ptr) -> !llvm.ptr, f32
      %556 = llvm.load %555 : !llvm.ptr -> f32
      %557 = llvm.getelementptr %459[49] : (!llvm.ptr) -> !llvm.ptr, f32
      %558 = llvm.load %557 : !llvm.ptr -> f32
      %559 = llvm.getelementptr %459[50] : (!llvm.ptr) -> !llvm.ptr, f32
      %560 = llvm.load %559 : !llvm.ptr -> f32
      %561 = llvm.getelementptr %459[51] : (!llvm.ptr) -> !llvm.ptr, f32
      %562 = llvm.load %561 : !llvm.ptr -> f32
      %563 = llvm.getelementptr %459[52] : (!llvm.ptr) -> !llvm.ptr, f32
      %564 = llvm.load %563 : !llvm.ptr -> f32
      %565 = llvm.getelementptr %459[53] : (!llvm.ptr) -> !llvm.ptr, f32
      %566 = llvm.load %565 : !llvm.ptr -> f32
      %567 = llvm.getelementptr %459[54] : (!llvm.ptr) -> !llvm.ptr, f32
      %568 = llvm.load %567 : !llvm.ptr -> f32
      %569 = llvm.getelementptr %459[55] : (!llvm.ptr) -> !llvm.ptr, f32
      %570 = llvm.load %569 : !llvm.ptr -> f32
      %571 = llvm.getelementptr %459[56] : (!llvm.ptr) -> !llvm.ptr, f32
      %572 = llvm.load %571 : !llvm.ptr -> f32
      %573 = llvm.getelementptr %459[57] : (!llvm.ptr) -> !llvm.ptr, f32
      %574 = llvm.load %573 : !llvm.ptr -> f32
      %575 = llvm.getelementptr %459[58] : (!llvm.ptr) -> !llvm.ptr, f32
      %576 = llvm.load %575 : !llvm.ptr -> f32
      %577 = llvm.getelementptr %459[59] : (!llvm.ptr) -> !llvm.ptr, f32
      %578 = llvm.load %577 : !llvm.ptr -> f32
      %579 = llvm.getelementptr %459[60] : (!llvm.ptr) -> !llvm.ptr, f32
      %580 = llvm.load %579 : !llvm.ptr -> f32
      %581 = llvm.getelementptr %459[61] : (!llvm.ptr) -> !llvm.ptr, f32
      %582 = llvm.load %581 : !llvm.ptr -> f32
      %583 = llvm.getelementptr %459[62] : (!llvm.ptr) -> !llvm.ptr, f32
      %584 = llvm.load %583 : !llvm.ptr -> f32
      %585 = llvm.getelementptr %459[63] : (!llvm.ptr) -> !llvm.ptr, f32
      %586 = llvm.load %585 : !llvm.ptr -> f32
      %587:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_116 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_113 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%460, %462, %464, %466, %468, %470, %472, %474, %476, %478, %480, %482, %484, %486, %488, %490, %492, %494, %496, %498, %500, %502, %504, %506, %508, %510, %512, %514, %516, %518, %520, %522, %524, %526, %528, %530, %532, %534, %536, %538, %540, %542, %544, %546, %548, %550, %552, %554, %556, %558, %560, %562, %564, %566, %568, %570, %572, %574, %576, %578, %580, %582, %584, %586], accum = %434 : i1)
< {cd_type = f32, operandSegmentSizes = array<i32: 1, 1, 64, 1>}> :(!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, f32, i1) -> (f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32)
      llvm.store %587#0, %459 : f32, !llvm.ptr
      llvm.store %587#1, %461 : f32, !llvm.ptr
      llvm.store %587#2, %463 : f32, !llvm.ptr
      llvm.store %587#3, %465 : f32, !llvm.ptr
      llvm.store %587#4, %467 : f32, !llvm.ptr
      llvm.store %587#5, %469 : f32, !llvm.ptr
      llvm.store %587#6, %471 : f32, !llvm.ptr
      llvm.store %587#7, %473 : f32, !llvm.ptr
      llvm.store %587#8, %475 : f32, !llvm.ptr
      llvm.store %587#9, %477 : f32, !llvm.ptr
      llvm.store %587#10, %479 : f32, !llvm.ptr
      llvm.store %587#11, %481 : f32, !llvm.ptr
      llvm.store %587#12, %483 : f32, !llvm.ptr
      llvm.store %587#13, %485 : f32, !llvm.ptr
      llvm.store %587#14, %487 : f32, !llvm.ptr
      llvm.store %587#15, %489 : f32, !llvm.ptr
      llvm.store %587#16, %491 : f32, !llvm.ptr
      llvm.store %587#17, %493 : f32, !llvm.ptr
      llvm.store %587#18, %495 : f32, !llvm.ptr
      llvm.store %587#19, %497 : f32, !llvm.ptr
      llvm.store %587#20, %499 : f32, !llvm.ptr
      llvm.store %587#21, %501 : f32, !llvm.ptr
      llvm.store %587#22, %503 : f32, !llvm.ptr
      llvm.store %587#23, %505 : f32, !llvm.ptr
      llvm.store %587#24, %507 : f32, !llvm.ptr
      llvm.store %587#25, %509 : f32, !llvm.ptr
      llvm.store %587#26, %511 : f32, !llvm.ptr
      llvm.store %587#27, %513 : f32, !llvm.ptr
      llvm.store %587#28, %515 : f32, !llvm.ptr
      llvm.store %587#29, %517 : f32, !llvm.ptr
      llvm.store %587#30, %519 : f32, !llvm.ptr
      llvm.store %587#31, %521 : f32, !llvm.ptr
      llvm.store %587#32, %523 : f32, !llvm.ptr
      llvm.store %587#33, %525 : f32, !llvm.ptr
      llvm.store %587#34, %527 : f32, !llvm.ptr
      llvm.store %587#35, %529 : f32, !llvm.ptr
      llvm.store %587#36, %531 : f32, !llvm.ptr
      llvm.store %587#37, %533 : f32, !llvm.ptr
      llvm.store %587#38, %535 : f32, !llvm.ptr
      llvm.store %587#39, %537 : f32, !llvm.ptr
      llvm.store %587#40, %539 : f32, !llvm.ptr
      llvm.store %587#41, %541 : f32, !llvm.ptr
      llvm.store %587#42, %543 : f32, !llvm.ptr
      llvm.store %587#43, %545 : f32, !llvm.ptr
      llvm.store %587#44, %547 : f32, !llvm.ptr
      llvm.store %587#45, %549 : f32, !llvm.ptr
      llvm.store %587#46, %551 : f32, !llvm.ptr
      llvm.store %587#47, %553 : f32, !llvm.ptr
      llvm.store %587#48, %555 : f32, !llvm.ptr
      llvm.store %587#49, %557 : f32, !llvm.ptr
      llvm.store %587#50, %559 : f32, !llvm.ptr
      llvm.store %587#51, %561 : f32, !llvm.ptr
      llvm.store %587#52, %563 : f32, !llvm.ptr
      llvm.store %587#53, %565 : f32, !llvm.ptr
      llvm.store %587#54, %567 : f32, !llvm.ptr
      llvm.store %587#55, %569 : f32, !llvm.ptr
      llvm.store %587#56, %571 : f32, !llvm.ptr
      llvm.store %587#57, %573 : f32, !llvm.ptr
      llvm.store %587#58, %575 : f32, !llvm.ptr
      llvm.store %587#59, %577 : f32, !llvm.ptr
      llvm.store %587#60, %579 : f32, !llvm.ptr
      llvm.store %587#61, %581 : f32, !llvm.ptr
      llvm.store %587#62, %583 : f32, !llvm.ptr
      llvm.store %587#63, %585 : f32, !llvm.ptr
      %588 = arith.addi %457, %c1_i32 : i32
      cf.br ^bb62(%588 : i32)
    ^bb64:  // pred: ^bb62
      %589 = arith.addi %455, %c1_i32 : i32
      cf.br ^bb60(%589 : i32)
    ^bb65:  // pred: ^bb60
      %590 = arith.addi %453, %c1_i32 : i32
      cf.br ^bb58(%590 : i32)
    ^bb66:  // pred: ^bb58
      %591 = arith.addi %451, %c1_i32 : i32
      cf.br ^bb56(%591 : i32)
    ^bb67:  // pred: ^bb56
      nvvm.wgmma.commit.group.sync.aligned
      nvvm.wgmma.wait.group.sync.aligned 1
      cf.cond_br %217, ^bb68, ^bb69
    ^bb68:  // pred: ^bb67
      %int_tuple_120 = cute.make_int_tuple(%442) : (i32) -> !cute.int_tuple<"?">
      %ptr_121 = cute.add_offset(%ptr_19, %int_tuple_120) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %592 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %592, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %593 = arith.addi %439, %c1_i32 : i32
      %594 = arith.addi %438, %c1_i32 : i32
      %595 = arith.cmpi eq, %593, %c7_i32 : i32
      %596 = arith.select %595, %c0_i32, %593 : i32
      cf.cond_br %595, ^bb70, ^bb71
    ^bb70:  // pred: ^bb69
      %597 = arith.xori %440, %c1_i32 : i32
      cf.br ^bb72(%597 : i32)
    ^bb71:  // pred: ^bb69
      cf.br ^bb72(%440 : i32)
    ^bb72(%598: i32):  // 2 preds: ^bb70, ^bb71
      cf.br ^bb73
    ^bb73:  // pred: ^bb72
      %599 = arith.addi %442, %c1_i32 : i32
      %600 = arith.addi %441, %c1_i32 : i32
      %601 = arith.cmpi eq, %599, %c7_i32 : i32
      %602 = arith.select %601, %c0_i32, %599 : i32
      cf.cond_br %601, ^bb74, ^bb75
    ^bb74:  // pred: ^bb73
      %603 = arith.xori %443, %c1_i32 : i32
      cf.br ^bb76(%603 : i32)
    ^bb75:  // pred: ^bb73
      cf.br ^bb76(%443 : i32)
    ^bb76(%604: i32):  // 2 preds: ^bb74, ^bb75
      cf.br ^bb77
    ^bb77:  // pred: ^bb76
      %605 = arith.cmpi sgt, %234, %594 : i32
      cf.cond_br %605, ^bb78, ^bb79
    ^bb78:  // pred: ^bb77
      %int_tuple_122 = cute.make_int_tuple(%596) : (i32) -> !cute.int_tuple<"?">
      %ptr_123 = cute.add_offset(%iter, %int_tuple_122) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %606 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %607 = nvvm.mbarrier.wait.parity %606, %598 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb80(%607 : i1)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%true : i1)
    ^bb80(%608: i1):  // 2 preds: ^bb78, ^bb79
      cf.br ^bb81
    ^bb81:  // pred: ^bb80
      %609 = arith.cmpi sgt, %234, %444 : i32
      %610 = arith.extui %609 : i1 to i32
      %611 = arith.select %172, %610, %435 : i32
      %612 = arith.cmpi ne, %611, %c0_i32 : i32
      cf.cond_br %612, ^bb82, ^bb95
    ^bb82:  // pred: ^bb81
      %int_tuple_124 = cute.make_int_tuple(%445) : (i32) -> !cute.int_tuple<"?">
      %ptr_125 = cute.add_offset(%ptr_19, %int_tuple_124) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %613 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %613, %446, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %614 = nvvm.elect.sync -> i1
      cf.cond_br %614, ^bb83, ^bb84
    ^bb83:  // pred: ^bb82
      %ptr_126 = cute.add_offset(%iter, %int_tuple_124) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %615 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %615, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      %coord_127 = cute.make_coord(%444) : (i32) -> !cute.coord<"(_,?)">
      %idx_128 = cute.crd2idx(%coord_127, %lay_61) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_129 = cute.add_offset(%tup_43, %idx_128) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_130, %e1_131, %e2_132 = cute.get_leaves(%tup_129) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %coord_133 = cute.make_coord(%445) : (i32) -> !cute.coord<"(_,?)">
      %idx_134 = cute.crd2idx(%coord_133, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_135 = cute.add_offset(%iter_34, %idx_134) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_136 = cute.crd2idx(%coord_127, %lay_65) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_137 = cute.add_offset(%tup_51, %idx_136) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_138, %e1_139, %e2_140 = cute.get_leaves(%tup_137) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %ptr_141 = cute.add_offset(%iter_35, %idx_134) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_142 = cute.add_offset(%iter, %int_tuple_124) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_143 = cute.make_int_tuple(%e0_130, %e1_131, %e2_132) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %616 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %617 = cute_nvgpu.atom.set_value(%616, %ptr_142 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %618 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %619 = cute_nvgpu.atom.get_value(%617 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_144 = cute_nvgpu.get_tma_desc_addr(%617 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %620:3 = cute.get_scalars(%int_tuple_143) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%621: i32):  // 2 preds: ^bb84, ^bb86
      %622 = arith.cmpi slt, %621, %618 : i32
      cf.cond_br %622, ^bb86, ^bb87 {llvm.loop_annotation = #loop_annotation1}
    ^bb86:  // pred: ^bb85
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_144 : !cute.ptr<generic, align<64>>, %ptr_135 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %619 : !cute.ptr<smem, align<8>>, [%620#0, %620#1, %620#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %623 = arith.addi %621, %c1_i32 : i32
      cf.br ^bb85(%623 : i32)
    ^bb87:  // pred: ^bb85
      %int_tuple_145 = cute.make_int_tuple(%e0_138, %e1_139, %e2_140) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %624 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %625 = cute_nvgpu.atom.set_value(%624, %ptr_142 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %626 = cute_nvgpu.atom.get_value(%625 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_146 = cute_nvgpu.get_tma_desc_addr(%625 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %627:3 = cute.get_scalars(%int_tuple_145) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb88(%c0_i32 : i32)
    ^bb88(%628: i32):  // 2 preds: ^bb87, ^bb89
      %629 = arith.cmpi slt, %628, %618 : i32
      cf.cond_br %629, ^bb89, ^bb90 {llvm.loop_annotation = #loop_annotation1}
    ^bb89:  // pred: ^bb88
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_146 : !cute.ptr<generic, align<64>>, %ptr_141 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %626 : !cute.ptr<smem, align<8>>, [%627#0, %627#1, %627#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %630 = arith.addi %628, %c1_i32 : i32
      cf.br ^bb88(%630 : i32)
    ^bb90:  // pred: ^bb88
      %631 = arith.addi %445, %c1_i32 : i32
      %632 = arith.addi %444, %c1_i32 : i32
      %633 = arith.cmpi eq, %631, %c7_i32 : i32
      %634 = arith.select %633, %c0_i32, %631 : i32
      cf.cond_br %633, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %635 = arith.xori %446, %c1_i32 : i32
      cf.br ^bb93(%635 : i32)
    ^bb92:  // pred: ^bb90
      cf.br ^bb93(%446 : i32)
    ^bb93(%636: i32):  // 2 preds: ^bb91, ^bb92
      cf.br ^bb94
    ^bb94:  // pred: ^bb93
      cf.br ^bb96(%632, %634, %636 : i32, i32, i32)
    ^bb95:  // pred: ^bb81
      cf.br ^bb96(%444, %445, %446 : i32, i32, i32)
    ^bb96(%637: i32, %638: i32, %639: i32):  // 2 preds: ^bb94, ^bb95
      cf.br ^bb97
    ^bb97:  // pred: ^bb96
      %640 = arith.addi %436, %c1_i32 : i32
      cf.br ^bb52(%640, %608, %594, %596, %598, %600, %602, %604, %637, %638, %639 : i32, i1, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb98:  // pred: ^bb52
      nvvm.wgmma.wait.group.sync.aligned 0
      nvvm.barrier
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>
      %641 = cute.make_tiled_copy(%atom) : !copy_stsm_4_
      %642 = cute.make_tiled_copy(%atom) : !copy_stsm_4_1
      %coord_147 = cute.make_coord(%160) : (i32) -> !cute.coord<"?">
      %643 = cute.get_scalars(%coord_147) <{only_dynamic}> : !cute.coord<"?">
      %644 = arith.divsi %643, %c8_i32 : i32
      %645 = arith.remsi %643, %c8_i32 : i32
      %646 = arith.muli %645, %c32_i32 : i32
      %647 = arith.divsi %644, %c2_i32 : i32
      %648 = arith.remsi %644, %c2_i32 : i32
      %649 = arith.muli %648, %c256_i32 : i32
      %650 = arith.addi %646, %649 : i32
      %651 = arith.divsi %647, %c2_i32 : i32
      %652 = arith.remsi %647, %c2_i32 : i32
      %653 = arith.muli %652, %c8_i32 : i32
      %654 = arith.addi %650, %653 : i32
      %655 = arith.muli %651, %c512_i32 : i32
      %656 = arith.addi %654, %655 : i32
      %iv = cute.assume(%656) : (i32) -> !cute.i32<divby 8>
      %int_tuple_148 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_149 = cute.add_offset(%iter_36, %int_tuple_148) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %iter_150 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %view = cute.make_view(%iter_150) : !memref_rmem_f32_1
      %rmem_151 = cute.memref.alloca() : !memref_rmem_f32_2
      %657 = cute.memref.load(%view, %139) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      cute.memref.store(%rmem_151, %139, %657) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %658 = cute.memref.load(%view, %138) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      cute.memref.store(%rmem_151, %138, %658) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %659 = cute.memref.load(%view, %137) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      cute.memref.store(%rmem_151, %137, %659) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %660 = cute.memref.load(%view, %136) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      cute.memref.store(%rmem_151, %136, %660) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %661 = cute.memref.load(%view, %135) : (!memref_rmem_f32_1, !cute.coord<"4">) -> f32
      cute.memref.store(%rmem_151, %135, %661) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %662 = cute.memref.load(%view, %134) : (!memref_rmem_f32_1, !cute.coord<"5">) -> f32
      cute.memref.store(%rmem_151, %134, %662) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %663 = cute.memref.load(%view, %133) : (!memref_rmem_f32_1, !cute.coord<"6">) -> f32
      cute.memref.store(%rmem_151, %133, %663) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %664 = cute.memref.load(%view, %132) : (!memref_rmem_f32_1, !cute.coord<"7">) -> f32
      cute.memref.store(%rmem_151, %132, %664) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %665 = cute.memref.load(%view, %131) : (!memref_rmem_f32_1, !cute.coord<"8">) -> f32
      cute.memref.store(%rmem_151, %131, %665) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %666 = cute.memref.load(%view, %130) : (!memref_rmem_f32_1, !cute.coord<"9">) -> f32
      cute.memref.store(%rmem_151, %130, %666) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %667 = cute.memref.load(%view, %129) : (!memref_rmem_f32_1, !cute.coord<"10">) -> f32
      cute.memref.store(%rmem_151, %129, %667) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %668 = cute.memref.load(%view, %128) : (!memref_rmem_f32_1, !cute.coord<"11">) -> f32
      cute.memref.store(%rmem_151, %128, %668) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %669 = cute.memref.load(%view, %127) : (!memref_rmem_f32_1, !cute.coord<"12">) -> f32
      cute.memref.store(%rmem_151, %127, %669) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %670 = cute.memref.load(%view, %126) : (!memref_rmem_f32_1, !cute.coord<"13">) -> f32
      cute.memref.store(%rmem_151, %126, %670) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %671 = cute.memref.load(%view, %125) : (!memref_rmem_f32_1, !cute.coord<"14">) -> f32
      cute.memref.store(%rmem_151, %125, %671) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %672 = cute.memref.load(%view, %124) : (!memref_rmem_f32_1, !cute.coord<"15">) -> f32
      cute.memref.store(%rmem_151, %124, %672) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_152 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_153 = cute.get_iter(%rmem_152) : !memref_rmem_f16_
      %673 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %674 = arith.truncf %673 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %674, %rmem_152, row_major : !memref_rmem_f16_
      %675 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      cf.br ^bb99(%c0_i32 : i32)
    ^bb99(%676: i32):  // 2 preds: ^bb98, ^bb100
      %677 = arith.cmpi slt, %676, %675 : i32
      cf.cond_br %677, ^bb100, ^bb101 {llvm.loop_annotation = #loop_annotation1}
    ^bb100:  // pred: ^bb99
      %coord_154 = cute.make_coord(%676) : (i32) -> !cute.coord<"(_,?)">
      %idx_155 = cute.crd2idx(%coord_154, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_156 = cute.add_offset(%iter_153, %idx_155) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_157 = cute.crd2idx(%coord_154, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_158 = cute.add_offset(%ptr_149, %idx_157) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %678 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %679 = llvm.load %678 : !llvm.ptr -> vector<4xi32>
      %swizzled = cute.apply_swizzle(%ptr_158) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled, %679) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %680 = arith.addi %676, %c1_i32 : i32
      cf.br ^bb99(%680 : i32)
    ^bb101:  // pred: ^bb99
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb102, ^bb106
    ^bb102:  // pred: ^bb101
      %e0_159, %e1_160, %e2_161 = cute.get_leaves(%tup_57) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %int_tuple_162 = cute.make_int_tuple(%e0_159, %e1_160, %e2_161) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %681 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %682 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_163 = cute_nvgpu.get_tma_desc_addr(%681 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %683:3 = cute.get_scalars(%int_tuple_162) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%684: i32):  // 2 preds: ^bb102, ^bb104
      %685 = arith.cmpi slt, %684, %682 : i32
      cf.cond_br %685, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation1}
    ^bb104:  // pred: ^bb103
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_163 : !cute.ptr<generic, align<64>>, %iter_36 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%683#0, %683#1, %683#2] : i32, i32, i32) mode = <tiled>
      %686 = arith.addi %684, %c1_i32 : i32
      cf.br ^bb103(%686 : i32)
    ^bb105:  // pred: ^bb103
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb101, ^bb105
      nvvm.barrier id = %c1_i32
      %687 = cute.memref.load(%view, %121) : (!memref_rmem_f32_1, !cute.coord<"16">) -> f32
      cute.memref.store(%rmem_151, %139, %687) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %688 = cute.memref.load(%view, %120) : (!memref_rmem_f32_1, !cute.coord<"17">) -> f32
      cute.memref.store(%rmem_151, %138, %688) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %689 = cute.memref.load(%view, %119) : (!memref_rmem_f32_1, !cute.coord<"18">) -> f32
      cute.memref.store(%rmem_151, %137, %689) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %690 = cute.memref.load(%view, %118) : (!memref_rmem_f32_1, !cute.coord<"19">) -> f32
      cute.memref.store(%rmem_151, %136, %690) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %691 = cute.memref.load(%view, %117) : (!memref_rmem_f32_1, !cute.coord<"20">) -> f32
      cute.memref.store(%rmem_151, %135, %691) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %692 = cute.memref.load(%view, %116) : (!memref_rmem_f32_1, !cute.coord<"21">) -> f32
      cute.memref.store(%rmem_151, %134, %692) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %693 = cute.memref.load(%view, %115) : (!memref_rmem_f32_1, !cute.coord<"22">) -> f32
      cute.memref.store(%rmem_151, %133, %693) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %694 = cute.memref.load(%view, %114) : (!memref_rmem_f32_1, !cute.coord<"23">) -> f32
      cute.memref.store(%rmem_151, %132, %694) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %695 = cute.memref.load(%view, %113) : (!memref_rmem_f32_1, !cute.coord<"24">) -> f32
      cute.memref.store(%rmem_151, %131, %695) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %696 = cute.memref.load(%view, %112) : (!memref_rmem_f32_1, !cute.coord<"25">) -> f32
      cute.memref.store(%rmem_151, %130, %696) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %697 = cute.memref.load(%view, %111) : (!memref_rmem_f32_1, !cute.coord<"26">) -> f32
      cute.memref.store(%rmem_151, %129, %697) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %698 = cute.memref.load(%view, %110) : (!memref_rmem_f32_1, !cute.coord<"27">) -> f32
      cute.memref.store(%rmem_151, %128, %698) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %699 = cute.memref.load(%view, %109) : (!memref_rmem_f32_1, !cute.coord<"28">) -> f32
      cute.memref.store(%rmem_151, %127, %699) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %700 = cute.memref.load(%view, %108) : (!memref_rmem_f32_1, !cute.coord<"29">) -> f32
      cute.memref.store(%rmem_151, %126, %700) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %701 = cute.memref.load(%view, %107) : (!memref_rmem_f32_1, !cute.coord<"30">) -> f32
      cute.memref.store(%rmem_151, %125, %701) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %702 = cute.memref.load(%view, %106) : (!memref_rmem_f32_1, !cute.coord<"31">) -> f32
      cute.memref.store(%rmem_151, %124, %702) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_164 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_165 = cute.get_iter(%rmem_164) : !memref_rmem_f16_
      %703 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %704 = arith.truncf %703 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %704, %rmem_164, row_major : !memref_rmem_f16_
      %ptr_166 = cute.add_offset(%ptr_149, %105) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb107(%c0_i32 : i32)
    ^bb107(%705: i32):  // 2 preds: ^bb106, ^bb108
      %706 = arith.cmpi slt, %705, %675 : i32
      cf.cond_br %706, ^bb108, ^bb109 {llvm.loop_annotation = #loop_annotation1}
    ^bb108:  // pred: ^bb107
      %coord_167 = cute.make_coord(%705) : (i32) -> !cute.coord<"(_,?)">
      %idx_168 = cute.crd2idx(%coord_167, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_169 = cute.add_offset(%iter_165, %idx_168) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_170 = cute.crd2idx(%coord_167, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_171 = cute.add_offset(%ptr_166, %idx_170) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %707 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %708 = llvm.load %707 : !llvm.ptr -> vector<4xi32>
      %swizzled_172 = cute.apply_swizzle(%ptr_171) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_172, %708) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %709 = arith.addi %705, %c1_i32 : i32
      cf.br ^bb107(%709 : i32)
    ^bb109:  // pred: ^bb107
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb110, ^bb114
    ^bb110:  // pred: ^bb109
      %ptr_173 = cute.add_offset(%iter_36, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_174 = cute.add_offset(%tup_57, %104) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_175, %e1_176, %e2_177 = cute.get_leaves(%tup_174) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %int_tuple_178 = cute.make_int_tuple(%e0_175, %e1_176, %e2_177) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %710 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %711 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_179 = cute_nvgpu.get_tma_desc_addr(%710 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %712:3 = cute.get_scalars(%int_tuple_178) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%713: i32):  // 2 preds: ^bb110, ^bb112
      %714 = arith.cmpi slt, %713, %711 : i32
      cf.cond_br %714, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation1}
    ^bb112:  // pred: ^bb111
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_179 : !cute.ptr<generic, align<64>>, %ptr_173 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%712#0, %712#1, %712#2] : i32, i32, i32) mode = <tiled>
      %715 = arith.addi %713, %c1_i32 : i32
      cf.br ^bb111(%715 : i32)
    ^bb113:  // pred: ^bb111
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb109, ^bb113
      nvvm.barrier id = %c1_i32
      %716 = cute.memref.load(%view, %103) : (!memref_rmem_f32_1, !cute.coord<"32">) -> f32
      cute.memref.store(%rmem_151, %139, %716) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %717 = cute.memref.load(%view, %102) : (!memref_rmem_f32_1, !cute.coord<"33">) -> f32
      cute.memref.store(%rmem_151, %138, %717) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %718 = cute.memref.load(%view, %101) : (!memref_rmem_f32_1, !cute.coord<"34">) -> f32
      cute.memref.store(%rmem_151, %137, %718) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %719 = cute.memref.load(%view, %100) : (!memref_rmem_f32_1, !cute.coord<"35">) -> f32
      cute.memref.store(%rmem_151, %136, %719) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %720 = cute.memref.load(%view, %99) : (!memref_rmem_f32_1, !cute.coord<"36">) -> f32
      cute.memref.store(%rmem_151, %135, %720) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %721 = cute.memref.load(%view, %98) : (!memref_rmem_f32_1, !cute.coord<"37">) -> f32
      cute.memref.store(%rmem_151, %134, %721) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %722 = cute.memref.load(%view, %97) : (!memref_rmem_f32_1, !cute.coord<"38">) -> f32
      cute.memref.store(%rmem_151, %133, %722) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %723 = cute.memref.load(%view, %96) : (!memref_rmem_f32_1, !cute.coord<"39">) -> f32
      cute.memref.store(%rmem_151, %132, %723) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %724 = cute.memref.load(%view, %95) : (!memref_rmem_f32_1, !cute.coord<"40">) -> f32
      cute.memref.store(%rmem_151, %131, %724) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %725 = cute.memref.load(%view, %94) : (!memref_rmem_f32_1, !cute.coord<"41">) -> f32
      cute.memref.store(%rmem_151, %130, %725) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %726 = cute.memref.load(%view, %93) : (!memref_rmem_f32_1, !cute.coord<"42">) -> f32
      cute.memref.store(%rmem_151, %129, %726) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %727 = cute.memref.load(%view, %92) : (!memref_rmem_f32_1, !cute.coord<"43">) -> f32
      cute.memref.store(%rmem_151, %128, %727) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %728 = cute.memref.load(%view, %91) : (!memref_rmem_f32_1, !cute.coord<"44">) -> f32
      cute.memref.store(%rmem_151, %127, %728) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %729 = cute.memref.load(%view, %90) : (!memref_rmem_f32_1, !cute.coord<"45">) -> f32
      cute.memref.store(%rmem_151, %126, %729) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %730 = cute.memref.load(%view, %89) : (!memref_rmem_f32_1, !cute.coord<"46">) -> f32
      cute.memref.store(%rmem_151, %125, %730) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %731 = cute.memref.load(%view, %88) : (!memref_rmem_f32_1, !cute.coord<"47">) -> f32
      cute.memref.store(%rmem_151, %124, %731) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_180 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_181 = cute.get_iter(%rmem_180) : !memref_rmem_f16_
      %732 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %733 = arith.truncf %732 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %733, %rmem_180, row_major : !memref_rmem_f16_
      %ptr_182 = cute.add_offset(%ptr_149, %87) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%734: i32):  // 2 preds: ^bb114, ^bb116
      %735 = arith.cmpi slt, %734, %675 : i32
      cf.cond_br %735, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation1}
    ^bb116:  // pred: ^bb115
      %coord_183 = cute.make_coord(%734) : (i32) -> !cute.coord<"(_,?)">
      %idx_184 = cute.crd2idx(%coord_183, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_185 = cute.add_offset(%iter_181, %idx_184) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_186 = cute.crd2idx(%coord_183, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_187 = cute.add_offset(%ptr_182, %idx_186) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %736 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %737 = llvm.load %736 : !llvm.ptr -> vector<4xi32>
      %swizzled_188 = cute.apply_swizzle(%ptr_187) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_188, %737) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %738 = arith.addi %734, %c1_i32 : i32
      cf.br ^bb115(%738 : i32)
    ^bb117:  // pred: ^bb115
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb118, ^bb122
    ^bb118:  // pred: ^bb117
      %ptr_189 = cute.add_offset(%iter_36, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_190 = cute.add_offset(%tup_57, %86) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_191, %e1_192, %e2_193 = cute.get_leaves(%tup_190) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %int_tuple_194 = cute.make_int_tuple(%e0_191, %e1_192, %e2_193) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %739 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %740 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_195 = cute_nvgpu.get_tma_desc_addr(%739 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %741:3 = cute.get_scalars(%int_tuple_194) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb119(%c0_i32 : i32)
    ^bb119(%742: i32):  // 2 preds: ^bb118, ^bb120
      %743 = arith.cmpi slt, %742, %740 : i32
      cf.cond_br %743, ^bb120, ^bb121 {llvm.loop_annotation = #loop_annotation1}
    ^bb120:  // pred: ^bb119
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_195 : !cute.ptr<generic, align<64>>, %ptr_189 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%741#0, %741#1, %741#2] : i32, i32, i32) mode = <tiled>
      %744 = arith.addi %742, %c1_i32 : i32
      cf.br ^bb119(%744 : i32)
    ^bb121:  // pred: ^bb119
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb122
    ^bb122:  // 2 preds: ^bb117, ^bb121
      nvvm.barrier id = %c1_i32
      %745 = cute.memref.load(%view, %85) : (!memref_rmem_f32_1, !cute.coord<"48">) -> f32
      cute.memref.store(%rmem_151, %139, %745) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %746 = cute.memref.load(%view, %84) : (!memref_rmem_f32_1, !cute.coord<"49">) -> f32
      cute.memref.store(%rmem_151, %138, %746) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %747 = cute.memref.load(%view, %83) : (!memref_rmem_f32_1, !cute.coord<"50">) -> f32
      cute.memref.store(%rmem_151, %137, %747) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %748 = cute.memref.load(%view, %82) : (!memref_rmem_f32_1, !cute.coord<"51">) -> f32
      cute.memref.store(%rmem_151, %136, %748) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %749 = cute.memref.load(%view, %81) : (!memref_rmem_f32_1, !cute.coord<"52">) -> f32
      cute.memref.store(%rmem_151, %135, %749) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %750 = cute.memref.load(%view, %80) : (!memref_rmem_f32_1, !cute.coord<"53">) -> f32
      cute.memref.store(%rmem_151, %134, %750) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %751 = cute.memref.load(%view, %79) : (!memref_rmem_f32_1, !cute.coord<"54">) -> f32
      cute.memref.store(%rmem_151, %133, %751) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %752 = cute.memref.load(%view, %78) : (!memref_rmem_f32_1, !cute.coord<"55">) -> f32
      cute.memref.store(%rmem_151, %132, %752) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %753 = cute.memref.load(%view, %77) : (!memref_rmem_f32_1, !cute.coord<"56">) -> f32
      cute.memref.store(%rmem_151, %131, %753) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %754 = cute.memref.load(%view, %76) : (!memref_rmem_f32_1, !cute.coord<"57">) -> f32
      cute.memref.store(%rmem_151, %130, %754) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %755 = cute.memref.load(%view, %75) : (!memref_rmem_f32_1, !cute.coord<"58">) -> f32
      cute.memref.store(%rmem_151, %129, %755) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %756 = cute.memref.load(%view, %74) : (!memref_rmem_f32_1, !cute.coord<"59">) -> f32
      cute.memref.store(%rmem_151, %128, %756) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %757 = cute.memref.load(%view, %73) : (!memref_rmem_f32_1, !cute.coord<"60">) -> f32
      cute.memref.store(%rmem_151, %127, %757) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %758 = cute.memref.load(%view, %72) : (!memref_rmem_f32_1, !cute.coord<"61">) -> f32
      cute.memref.store(%rmem_151, %126, %758) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %759 = cute.memref.load(%view, %71) : (!memref_rmem_f32_1, !cute.coord<"62">) -> f32
      cute.memref.store(%rmem_151, %125, %759) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %760 = cute.memref.load(%view, %70) : (!memref_rmem_f32_1, !cute.coord<"63">) -> f32
      cute.memref.store(%rmem_151, %124, %760) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_196 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_197 = cute.get_iter(%rmem_196) : !memref_rmem_f16_
      %761 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %762 = arith.truncf %761 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %762, %rmem_196, row_major : !memref_rmem_f16_
      %ptr_198 = cute.add_offset(%ptr_149, %69) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb123(%c0_i32 : i32)
    ^bb123(%763: i32):  // 2 preds: ^bb122, ^bb124
      %764 = arith.cmpi slt, %763, %675 : i32
      cf.cond_br %764, ^bb124, ^bb125 {llvm.loop_annotation = #loop_annotation1}
    ^bb124:  // pred: ^bb123
      %coord_199 = cute.make_coord(%763) : (i32) -> !cute.coord<"(_,?)">
      %idx_200 = cute.crd2idx(%coord_199, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_201 = cute.add_offset(%iter_197, %idx_200) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_202 = cute.crd2idx(%coord_199, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_203 = cute.add_offset(%ptr_198, %idx_202) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %765 = builtin.unrealized_conversion_cast %ptr_201 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %766 = llvm.load %765 : !llvm.ptr -> vector<4xi32>
      %swizzled_204 = cute.apply_swizzle(%ptr_203) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_204, %766) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %767 = arith.addi %763, %c1_i32 : i32
      cf.br ^bb123(%767 : i32)
    ^bb125:  // pred: ^bb123
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb126, ^bb130
    ^bb126:  // pred: ^bb125
      %ptr_205 = cute.add_offset(%iter_36, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_206 = cute.add_offset(%tup_57, %68) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_207, %e1_208, %e2_209 = cute.get_leaves(%tup_206) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %int_tuple_210 = cute.make_int_tuple(%e0_207, %e1_208, %e2_209) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %768 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %769 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_211 = cute_nvgpu.get_tma_desc_addr(%768 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %770:3 = cute.get_scalars(%int_tuple_210) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb127(%c0_i32 : i32)
    ^bb127(%771: i32):  // 2 preds: ^bb126, ^bb128
      %772 = arith.cmpi slt, %771, %769 : i32
      cf.cond_br %772, ^bb128, ^bb129 {llvm.loop_annotation = #loop_annotation1}
    ^bb128:  // pred: ^bb127
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_211 : !cute.ptr<generic, align<64>>, %ptr_205 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%770#0, %770#1, %770#2] : i32, i32, i32) mode = <tiled>
      %773 = arith.addi %771, %c1_i32 : i32
      cf.br ^bb127(%773 : i32)
    ^bb129:  // pred: ^bb127
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb130
    ^bb130:  // 2 preds: ^bb125, ^bb129
      nvvm.barrier id = %c1_i32
      %774 = cute.memref.load(%view, %67) : (!memref_rmem_f32_1, !cute.coord<"64">) -> f32
      cute.memref.store(%rmem_151, %139, %774) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %775 = cute.memref.load(%view, %66) : (!memref_rmem_f32_1, !cute.coord<"65">) -> f32
      cute.memref.store(%rmem_151, %138, %775) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %776 = cute.memref.load(%view, %65) : (!memref_rmem_f32_1, !cute.coord<"66">) -> f32
      cute.memref.store(%rmem_151, %137, %776) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %777 = cute.memref.load(%view, %64) : (!memref_rmem_f32_1, !cute.coord<"67">) -> f32
      cute.memref.store(%rmem_151, %136, %777) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %778 = cute.memref.load(%view, %63) : (!memref_rmem_f32_1, !cute.coord<"68">) -> f32
      cute.memref.store(%rmem_151, %135, %778) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %779 = cute.memref.load(%view, %62) : (!memref_rmem_f32_1, !cute.coord<"69">) -> f32
      cute.memref.store(%rmem_151, %134, %779) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %780 = cute.memref.load(%view, %61) : (!memref_rmem_f32_1, !cute.coord<"70">) -> f32
      cute.memref.store(%rmem_151, %133, %780) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %781 = cute.memref.load(%view, %60) : (!memref_rmem_f32_1, !cute.coord<"71">) -> f32
      cute.memref.store(%rmem_151, %132, %781) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %782 = cute.memref.load(%view, %59) : (!memref_rmem_f32_1, !cute.coord<"72">) -> f32
      cute.memref.store(%rmem_151, %131, %782) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %783 = cute.memref.load(%view, %58) : (!memref_rmem_f32_1, !cute.coord<"73">) -> f32
      cute.memref.store(%rmem_151, %130, %783) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %784 = cute.memref.load(%view, %57) : (!memref_rmem_f32_1, !cute.coord<"74">) -> f32
      cute.memref.store(%rmem_151, %129, %784) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %785 = cute.memref.load(%view, %56) : (!memref_rmem_f32_1, !cute.coord<"75">) -> f32
      cute.memref.store(%rmem_151, %128, %785) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %786 = cute.memref.load(%view, %55) : (!memref_rmem_f32_1, !cute.coord<"76">) -> f32
      cute.memref.store(%rmem_151, %127, %786) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %787 = cute.memref.load(%view, %54) : (!memref_rmem_f32_1, !cute.coord<"77">) -> f32
      cute.memref.store(%rmem_151, %126, %787) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %788 = cute.memref.load(%view, %53) : (!memref_rmem_f32_1, !cute.coord<"78">) -> f32
      cute.memref.store(%rmem_151, %125, %788) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %789 = cute.memref.load(%view, %52) : (!memref_rmem_f32_1, !cute.coord<"79">) -> f32
      cute.memref.store(%rmem_151, %124, %789) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_212 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_213 = cute.get_iter(%rmem_212) : !memref_rmem_f16_
      %790 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %791 = arith.truncf %790 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %791, %rmem_212, row_major : !memref_rmem_f16_
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%792: i32):  // 2 preds: ^bb130, ^bb132
      %793 = arith.cmpi slt, %792, %675 : i32
      cf.cond_br %793, ^bb132, ^bb133 {llvm.loop_annotation = #loop_annotation1}
    ^bb132:  // pred: ^bb131
      %coord_214 = cute.make_coord(%792) : (i32) -> !cute.coord<"(_,?)">
      %idx_215 = cute.crd2idx(%coord_214, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_216 = cute.add_offset(%iter_213, %idx_215) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_217 = cute.crd2idx(%coord_214, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_218 = cute.add_offset(%ptr_149, %idx_217) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %794 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %795 = llvm.load %794 : !llvm.ptr -> vector<4xi32>
      %swizzled_219 = cute.apply_swizzle(%ptr_218) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_219, %795) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %796 = arith.addi %792, %c1_i32 : i32
      cf.br ^bb131(%796 : i32)
    ^bb133:  // pred: ^bb131
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb134, ^bb138
    ^bb134:  // pred: ^bb133
      %tup_220 = cute.add_offset(%tup_57, %51) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(0,64)">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %e0_221, %e1_222, %e2_223 = cute.get_leaves(%tup_220) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %int_tuple_224 = cute.make_int_tuple(%e0_221, %e1_222, %e2_223) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %797 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %798 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_225 = cute_nvgpu.get_tma_desc_addr(%797 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %799:3 = cute.get_scalars(%int_tuple_224) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%800: i32):  // 2 preds: ^bb134, ^bb136
      %801 = arith.cmpi slt, %800, %798 : i32
      cf.cond_br %801, ^bb136, ^bb137 {llvm.loop_annotation = #loop_annotation1}
    ^bb136:  // pred: ^bb135
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_225 : !cute.ptr<generic, align<64>>, %iter_36 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%799#0, %799#1, %799#2] : i32, i32, i32) mode = <tiled>
      %802 = arith.addi %800, %c1_i32 : i32
      cf.br ^bb135(%802 : i32)
    ^bb137:  // pred: ^bb135
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb138
    ^bb138:  // 2 preds: ^bb133, ^bb137
      nvvm.barrier id = %c1_i32
      %803 = cute.memref.load(%view, %50) : (!memref_rmem_f32_1, !cute.coord<"80">) -> f32
      cute.memref.store(%rmem_151, %139, %803) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %804 = cute.memref.load(%view, %49) : (!memref_rmem_f32_1, !cute.coord<"81">) -> f32
      cute.memref.store(%rmem_151, %138, %804) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %805 = cute.memref.load(%view, %48) : (!memref_rmem_f32_1, !cute.coord<"82">) -> f32
      cute.memref.store(%rmem_151, %137, %805) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %806 = cute.memref.load(%view, %47) : (!memref_rmem_f32_1, !cute.coord<"83">) -> f32
      cute.memref.store(%rmem_151, %136, %806) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %807 = cute.memref.load(%view, %46) : (!memref_rmem_f32_1, !cute.coord<"84">) -> f32
      cute.memref.store(%rmem_151, %135, %807) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %808 = cute.memref.load(%view, %45) : (!memref_rmem_f32_1, !cute.coord<"85">) -> f32
      cute.memref.store(%rmem_151, %134, %808) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %809 = cute.memref.load(%view, %44) : (!memref_rmem_f32_1, !cute.coord<"86">) -> f32
      cute.memref.store(%rmem_151, %133, %809) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %810 = cute.memref.load(%view, %43) : (!memref_rmem_f32_1, !cute.coord<"87">) -> f32
      cute.memref.store(%rmem_151, %132, %810) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %811 = cute.memref.load(%view, %42) : (!memref_rmem_f32_1, !cute.coord<"88">) -> f32
      cute.memref.store(%rmem_151, %131, %811) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %812 = cute.memref.load(%view, %41) : (!memref_rmem_f32_1, !cute.coord<"89">) -> f32
      cute.memref.store(%rmem_151, %130, %812) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %813 = cute.memref.load(%view, %40) : (!memref_rmem_f32_1, !cute.coord<"90">) -> f32
      cute.memref.store(%rmem_151, %129, %813) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %814 = cute.memref.load(%view, %39) : (!memref_rmem_f32_1, !cute.coord<"91">) -> f32
      cute.memref.store(%rmem_151, %128, %814) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %815 = cute.memref.load(%view, %38) : (!memref_rmem_f32_1, !cute.coord<"92">) -> f32
      cute.memref.store(%rmem_151, %127, %815) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %816 = cute.memref.load(%view, %37) : (!memref_rmem_f32_1, !cute.coord<"93">) -> f32
      cute.memref.store(%rmem_151, %126, %816) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %817 = cute.memref.load(%view, %36) : (!memref_rmem_f32_1, !cute.coord<"94">) -> f32
      cute.memref.store(%rmem_151, %125, %817) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %818 = cute.memref.load(%view, %35) : (!memref_rmem_f32_1, !cute.coord<"95">) -> f32
      cute.memref.store(%rmem_151, %124, %818) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_226 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_227 = cute.get_iter(%rmem_226) : !memref_rmem_f16_
      %819 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %820 = arith.truncf %819 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %820, %rmem_226, row_major : !memref_rmem_f16_
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%821: i32):  // 2 preds: ^bb138, ^bb140
      %822 = arith.cmpi slt, %821, %675 : i32
      cf.cond_br %822, ^bb140, ^bb141 {llvm.loop_annotation = #loop_annotation1}
    ^bb140:  // pred: ^bb139
      %coord_228 = cute.make_coord(%821) : (i32) -> !cute.coord<"(_,?)">
      %idx_229 = cute.crd2idx(%coord_228, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_230 = cute.add_offset(%iter_227, %idx_229) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_231 = cute.crd2idx(%coord_228, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_232 = cute.add_offset(%ptr_166, %idx_231) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %823 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %824 = llvm.load %823 : !llvm.ptr -> vector<4xi32>
      %swizzled_233 = cute.apply_swizzle(%ptr_232) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_233, %824) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %825 = arith.addi %821, %c1_i32 : i32
      cf.br ^bb139(%825 : i32)
    ^bb141:  // pred: ^bb139
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb142, ^bb146
    ^bb142:  // pred: ^bb141
      %ptr_234 = cute.add_offset(%iter_36, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_235 = cute.add_offset(%tup_57, %34) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %e0_236, %e1_237, %e2_238 = cute.get_leaves(%tup_235) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %int_tuple_239 = cute.make_int_tuple(%e0_236, %e1_237, %e2_238) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %826 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %827 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_240 = cute_nvgpu.get_tma_desc_addr(%826 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %828:3 = cute.get_scalars(%int_tuple_239) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      cf.br ^bb143(%c0_i32 : i32)
    ^bb143(%829: i32):  // 2 preds: ^bb142, ^bb144
      %830 = arith.cmpi slt, %829, %827 : i32
      cf.cond_br %830, ^bb144, ^bb145 {llvm.loop_annotation = #loop_annotation1}
    ^bb144:  // pred: ^bb143
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_240 : !cute.ptr<generic, align<64>>, %ptr_234 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%828#0, %828#1, %828#2] : i32, i32, i32) mode = <tiled>
      %831 = arith.addi %829, %c1_i32 : i32
      cf.br ^bb143(%831 : i32)
    ^bb145:  // pred: ^bb143
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb146
    ^bb146:  // 2 preds: ^bb141, ^bb145
      nvvm.barrier id = %c1_i32
      %832 = cute.memref.load(%view, %33) : (!memref_rmem_f32_1, !cute.coord<"96">) -> f32
      cute.memref.store(%rmem_151, %139, %832) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %833 = cute.memref.load(%view, %32) : (!memref_rmem_f32_1, !cute.coord<"97">) -> f32
      cute.memref.store(%rmem_151, %138, %833) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %834 = cute.memref.load(%view, %31) : (!memref_rmem_f32_1, !cute.coord<"98">) -> f32
      cute.memref.store(%rmem_151, %137, %834) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %835 = cute.memref.load(%view, %30) : (!memref_rmem_f32_1, !cute.coord<"99">) -> f32
      cute.memref.store(%rmem_151, %136, %835) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %836 = cute.memref.load(%view, %29) : (!memref_rmem_f32_1, !cute.coord<"100">) -> f32
      cute.memref.store(%rmem_151, %135, %836) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %837 = cute.memref.load(%view, %28) : (!memref_rmem_f32_1, !cute.coord<"101">) -> f32
      cute.memref.store(%rmem_151, %134, %837) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %838 = cute.memref.load(%view, %27) : (!memref_rmem_f32_1, !cute.coord<"102">) -> f32
      cute.memref.store(%rmem_151, %133, %838) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %839 = cute.memref.load(%view, %26) : (!memref_rmem_f32_1, !cute.coord<"103">) -> f32
      cute.memref.store(%rmem_151, %132, %839) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %840 = cute.memref.load(%view, %25) : (!memref_rmem_f32_1, !cute.coord<"104">) -> f32
      cute.memref.store(%rmem_151, %131, %840) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %841 = cute.memref.load(%view, %24) : (!memref_rmem_f32_1, !cute.coord<"105">) -> f32
      cute.memref.store(%rmem_151, %130, %841) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %842 = cute.memref.load(%view, %23) : (!memref_rmem_f32_1, !cute.coord<"106">) -> f32
      cute.memref.store(%rmem_151, %129, %842) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %843 = cute.memref.load(%view, %22) : (!memref_rmem_f32_1, !cute.coord<"107">) -> f32
      cute.memref.store(%rmem_151, %128, %843) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %844 = cute.memref.load(%view, %21) : (!memref_rmem_f32_1, !cute.coord<"108">) -> f32
      cute.memref.store(%rmem_151, %127, %844) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %845 = cute.memref.load(%view, %20) : (!memref_rmem_f32_1, !cute.coord<"109">) -> f32
      cute.memref.store(%rmem_151, %126, %845) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %846 = cute.memref.load(%view, %19) : (!memref_rmem_f32_1, !cute.coord<"110">) -> f32
      cute.memref.store(%rmem_151, %125, %846) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %847 = cute.memref.load(%view, %18) : (!memref_rmem_f32_1, !cute.coord<"111">) -> f32
      cute.memref.store(%rmem_151, %124, %847) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_241 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_242 = cute.get_iter(%rmem_241) : !memref_rmem_f16_
      %848 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %849 = arith.truncf %848 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %849, %rmem_241, row_major : !memref_rmem_f16_
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%850: i32):  // 2 preds: ^bb146, ^bb148
      %851 = arith.cmpi slt, %850, %675 : i32
      cf.cond_br %851, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation1}
    ^bb148:  // pred: ^bb147
      %coord_243 = cute.make_coord(%850) : (i32) -> !cute.coord<"(_,?)">
      %idx_244 = cute.crd2idx(%coord_243, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_245 = cute.add_offset(%iter_242, %idx_244) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_246 = cute.crd2idx(%coord_243, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_247 = cute.add_offset(%ptr_182, %idx_246) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %852 = builtin.unrealized_conversion_cast %ptr_245 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %853 = llvm.load %852 : !llvm.ptr -> vector<4xi32>
      %swizzled_248 = cute.apply_swizzle(%ptr_247) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_248, %853) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %854 = arith.addi %850, %c1_i32 : i32
      cf.br ^bb147(%854 : i32)
    ^bb149:  // pred: ^bb147
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb150, ^bb154
    ^bb150:  // pred: ^bb149
      %ptr_249 = cute.add_offset(%iter_36, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_250 = cute.add_offset(%tup_57, %17) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,64)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_251, %e1_252, %e2_253 = cute.get_leaves(%tup_250) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %int_tuple_254 = cute.make_int_tuple(%e0_251, %e1_252, %e2_253) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %855 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %856 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_255 = cute_nvgpu.get_tma_desc_addr(%855 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %857:3 = cute.get_scalars(%int_tuple_254) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb151(%c0_i32 : i32)
    ^bb151(%858: i32):  // 2 preds: ^bb150, ^bb152
      %859 = arith.cmpi slt, %858, %856 : i32
      cf.cond_br %859, ^bb152, ^bb153 {llvm.loop_annotation = #loop_annotation1}
    ^bb152:  // pred: ^bb151
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_255 : !cute.ptr<generic, align<64>>, %ptr_249 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%857#0, %857#1, %857#2] : i32, i32, i32) mode = <tiled>
      %860 = arith.addi %858, %c1_i32 : i32
      cf.br ^bb151(%860 : i32)
    ^bb153:  // pred: ^bb151
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb149, ^bb153
      nvvm.barrier id = %c1_i32
      %861 = cute.memref.load(%view, %16) : (!memref_rmem_f32_1, !cute.coord<"112">) -> f32
      cute.memref.store(%rmem_151, %139, %861) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %862 = cute.memref.load(%view, %15) : (!memref_rmem_f32_1, !cute.coord<"113">) -> f32
      cute.memref.store(%rmem_151, %138, %862) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %863 = cute.memref.load(%view, %14) : (!memref_rmem_f32_1, !cute.coord<"114">) -> f32
      cute.memref.store(%rmem_151, %137, %863) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %864 = cute.memref.load(%view, %13) : (!memref_rmem_f32_1, !cute.coord<"115">) -> f32
      cute.memref.store(%rmem_151, %136, %864) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %865 = cute.memref.load(%view, %12) : (!memref_rmem_f32_1, !cute.coord<"116">) -> f32
      cute.memref.store(%rmem_151, %135, %865) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %866 = cute.memref.load(%view, %11) : (!memref_rmem_f32_1, !cute.coord<"117">) -> f32
      cute.memref.store(%rmem_151, %134, %866) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %867 = cute.memref.load(%view, %10) : (!memref_rmem_f32_1, !cute.coord<"118">) -> f32
      cute.memref.store(%rmem_151, %133, %867) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %868 = cute.memref.load(%view, %9) : (!memref_rmem_f32_1, !cute.coord<"119">) -> f32
      cute.memref.store(%rmem_151, %132, %868) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %869 = cute.memref.load(%view, %8) : (!memref_rmem_f32_1, !cute.coord<"120">) -> f32
      cute.memref.store(%rmem_151, %131, %869) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %870 = cute.memref.load(%view, %7) : (!memref_rmem_f32_1, !cute.coord<"121">) -> f32
      cute.memref.store(%rmem_151, %130, %870) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %871 = cute.memref.load(%view, %6) : (!memref_rmem_f32_1, !cute.coord<"122">) -> f32
      cute.memref.store(%rmem_151, %129, %871) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %872 = cute.memref.load(%view, %5) : (!memref_rmem_f32_1, !cute.coord<"123">) -> f32
      cute.memref.store(%rmem_151, %128, %872) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %873 = cute.memref.load(%view, %4) : (!memref_rmem_f32_1, !cute.coord<"124">) -> f32
      cute.memref.store(%rmem_151, %127, %873) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %874 = cute.memref.load(%view, %3) : (!memref_rmem_f32_1, !cute.coord<"125">) -> f32
      cute.memref.store(%rmem_151, %126, %874) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %875 = cute.memref.load(%view, %2) : (!memref_rmem_f32_1, !cute.coord<"126">) -> f32
      cute.memref.store(%rmem_151, %125, %875) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %876 = cute.memref.load(%view, %1) : (!memref_rmem_f32_1, !cute.coord<"127">) -> f32
      cute.memref.store(%rmem_151, %124, %876) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_256 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_257 = cute.get_iter(%rmem_256) : !memref_rmem_f16_
      %877 = cute.memref.load_vec %rmem_151, row_major : !memref_rmem_f32_2
      %878 = arith.truncf %877 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %878, %rmem_256, row_major : !memref_rmem_f16_
      cf.br ^bb155(%c0_i32 : i32)
    ^bb155(%879: i32):  // 2 preds: ^bb154, ^bb156
      %880 = arith.cmpi slt, %879, %675 : i32
      cf.cond_br %880, ^bb156, ^bb157 {llvm.loop_annotation = #loop_annotation1}
    ^bb156:  // pred: ^bb155
      %coord_258 = cute.make_coord(%879) : (i32) -> !cute.coord<"(_,?)">
      %idx_259 = cute.crd2idx(%coord_258, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_260 = cute.add_offset(%iter_257, %idx_259) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_261 = cute.crd2idx(%coord_258, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_262 = cute.add_offset(%ptr_198, %idx_261) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %881 = builtin.unrealized_conversion_cast %ptr_260 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %882 = llvm.load %881 : !llvm.ptr -> vector<4xi32>
      %swizzled_263 = cute.apply_swizzle(%ptr_262) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_263, %882) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %883 = arith.addi %879, %c1_i32 : i32
      cf.br ^bb155(%883 : i32)
    ^bb157:  // pred: ^bb155
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb158, ^bb162
    ^bb158:  // pred: ^bb157
      %ptr_264 = cute.add_offset(%iter_36, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_265 = cute.add_offset(%tup_57, %0) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %e0_266, %e1_267, %e2_268 = cute.get_leaves(%tup_265) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %int_tuple_269 = cute.make_int_tuple(%e0_266, %e1_267, %e2_268) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %884 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %885 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_270 = cute_nvgpu.get_tma_desc_addr(%884 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %886:3 = cute.get_scalars(%int_tuple_269) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      cf.br ^bb159(%c0_i32 : i32)
    ^bb159(%887: i32):  // 2 preds: ^bb158, ^bb160
      %888 = arith.cmpi slt, %887, %885 : i32
      cf.cond_br %888, ^bb160, ^bb161 {llvm.loop_annotation = #loop_annotation1}
    ^bb160:  // pred: ^bb159
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_270 : !cute.ptr<generic, align<64>>, %ptr_264 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%886#0, %886#1, %886#2] : i32, i32, i32) mode = <tiled>
      %889 = arith.addi %887, %c1_i32 : i32
      cf.br ^bb159(%889 : i32)
    ^bb161:  // pred: ^bb159
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb162
    ^bb162:  // 2 preds: ^bb157, ^bb161
      nvvm.barrier id = %c1_i32
      cf.cond_br %172, ^bb163, ^bb164
    ^bb163:  // pred: ^bb162
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb164
    ^bb164:  // 2 preds: ^bb162, ^bb163
      return
    }
  }
  func.func @cutlass___call_____main__HopperWgmmaGemmKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_CUstream0x99dc670(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_, %arg3: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(63 : i64) : i64
    %1 = llvm.mlir.constant(2233785415175766016 : i64) : i64
    %2 = llvm.mlir.constant(279330 : i64) : i64
    %3 = llvm.mlir.constant(127 : i64) : i64
    %4 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %5 = llvm.mlir.constant(287522 : i64) : i64
    %c230400_i32 = arith.constant 230400 : i32
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %6 = cute.static : !cute.int_tuple<"1">
    %c128_i64 = arith.constant 128 : i64
    %c128_i32 = arith.constant 128 : i32
    %7 = cute.static : !cute.int_tuple<"(0,0,0)">
    %8 = cute.static : !cute.stride<"(1@1,1@0,1@2)">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c32_i64 = arith.constant 32 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4_i64 = arith.constant 4 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c2_i64 = arith.constant 2 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c16_i32 = arith.constant 16 : i32
    %false = arith.constant false
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm90.mma<64x128x16, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss>
    %9 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !cute_nvgpu.sm90.mma<64x128x16, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss>
    %10 = cute.make_tiled_mma(%9) : !mma_f16_f16_f32_64x128x16_
    %11 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %12:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %13 = arith.extui %12#1 : i32 to i64
    %14 = arith.extui %12#0 : i32 to i64
    %15 = llvm.mul %12#3, %c2_i64 : i64
    %16 = arith.extui %12#2 : i32 to i64
    %17 = llvm.mul %12#4, %c2_i64 : i64
    %18 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<16>> to i64
    %19 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %19 : i64, !llvm.ptr
    %20 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %20 : i64, !llvm.ptr
    %21 = llvm.getelementptr %11[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %11[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %11[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %11[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %11[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %11[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %11[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %11[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %11[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %11[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %11[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %11[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %11[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %11[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.udiv %18, %c16_i64 : i64
    %36 = llvm.and %35, %c9007199254740991_i64 : i64
    %37 = llvm.shl %36, %c4_i64 : i64
    llvm.store %37, %19 : i64, !llvm.ptr
    %38 = llvm.sub %14, %c1_i64 : i64
    %39 = llvm.sub %16, %c1_i64 : i64
    %40 = llvm.sub %c1_i64, %c1_i64 : i64
    %41 = llvm.mul %38, %15 : i64
    %42 = llvm.mul %39, %17 : i64
    %43 = llvm.mul %40, %c0_i64 : i64
    %44 = llvm.add %41, %42 : i64
    %45 = llvm.add %43, %43 : i64
    %46 = llvm.mul %13, %c16_i64 : i64
    %47 = llvm.udiv %46, %c8_i64 : i64
    %48 = llvm.add %47, %44 : i64
    %49 = llvm.add %48, %45 : i64
    %50 = llvm.icmp "uge" %49, %c131072_i64 : i64
    %51 = llvm.zext %50 : i1 to i64
    %52 = llvm.shl %51, %c21_i64 : i64
    %53 = llvm.udiv %15, %c16_i64 : i64
    %54 = llvm.shl %53, %c32_i64 : i64
    %55 = llvm.or %c0_i64, %52 : i64
    %56 = llvm.or %55, %54 : i64
    %57 = llvm.or %5, %56 : i64
    llvm.store %57, %20 : i64, !llvm.ptr
    %58 = llvm.udiv %17, %c16_i64 : i64
    %59 = llvm.and %58, %c4294967295_i64 : i64
    %60 = llvm.shl %59, %c0_i64 : i64
    %61 = llvm.udiv %c0_i64, %c16_i64 : i64
    %62 = llvm.shl %61, %c32_i64 : i64
    %63 = llvm.or %60, %62 : i64
    llvm.store %63, %21 : i64, !llvm.ptr
    %64 = llvm.and %61, %c4294967295_i64 : i64
    %65 = llvm.shl %64, %c0_i64 : i64
    %66 = llvm.lshr %15, %c36_i64 : i64
    %67 = llvm.and %66, %c15_i64 : i64
    %68 = llvm.shl %67, %c32_i64 : i64
    %69 = llvm.lshr %17, %c36_i64 : i64
    %70 = llvm.and %69, %c15_i64 : i64
    %71 = llvm.shl %70, %c36_i64 : i64
    %72 = llvm.lshr %c0_i64, %c36_i64 : i64
    %73 = llvm.and %72, %c15_i64 : i64
    %74 = llvm.shl %73, %c40_i64 : i64
    %75 = llvm.shl %72, %c44_i64 : i64
    %76 = llvm.or %68, %71 : i64
    %77 = llvm.or %74, %75 : i64
    %78 = llvm.or %76, %77 : i64
    %79 = llvm.or %65, %78 : i64
    llvm.store %79, %22 : i64, !llvm.ptr
    %80 = llvm.sub %13, %c1_i64 : i64
    %81 = llvm.and %80, %c4294967295_i64 : i64
    %82 = llvm.shl %81, %c0_i64 : i64
    %83 = llvm.shl %38, %c32_i64 : i64
    %84 = llvm.or %82, %83 : i64
    llvm.store %84, %23 : i64, !llvm.ptr
    %85 = llvm.and %39, %c4294967295_i64 : i64
    %86 = llvm.shl %85, %c0_i64 : i64
    %87 = llvm.shl %40, %c32_i64 : i64
    %88 = llvm.or %86, %87 : i64
    llvm.store %88, %24 : i64, !llvm.ptr
    %89 = llvm.and %40, %c4294967295_i64 : i64
    %90 = llvm.or %89, %c0_i64 : i64
    %91 = llvm.or %90, %4 : i64
    llvm.store %91, %25 : i64, !llvm.ptr
    llvm.store %3, %26 : i64, !llvm.ptr
    %92 = builtin.unrealized_conversion_cast %11 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %93 = cute.ptrtoint(%92) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %94 = llvm.inttoptr %93 : i64 to !llvm.ptr
    %95 = llvm.load %94 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %96 = builtin.unrealized_conversion_cast %95 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %97 = cute_nvgpu.atom.set_value(%atom_0, %96 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %98 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_1 = cute.make_layout(%98, %8) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view = cute.make_view(%7, %lay_1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %99 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %100:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %101 = arith.extui %100#1 : i32 to i64
    %102 = arith.extui %100#0 : i32 to i64
    %103 = llvm.mul %100#3, %c2_i64 : i64
    %104 = arith.extui %100#2 : i32 to i64
    %105 = llvm.mul %100#4, %c2_i64 : i64
    %106 = cute.ptrtoint(%iter_2) : !cute.ptr<f16, gmem, align<16>> to i64
    %107 = llvm.getelementptr %99[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %107 : i64, !llvm.ptr
    %108 = llvm.getelementptr %99[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %108 : i64, !llvm.ptr
    %109 = llvm.getelementptr %99[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.getelementptr %99[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.getelementptr %99[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %111 : i64, !llvm.ptr
    %112 = llvm.getelementptr %99[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %112 : i64, !llvm.ptr
    %113 = llvm.getelementptr %99[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %113 : i64, !llvm.ptr
    %114 = llvm.getelementptr %99[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %114 : i64, !llvm.ptr
    %115 = llvm.getelementptr %99[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %99[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %99[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %99[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %99[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %99[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %99[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %99[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.udiv %106, %c16_i64 : i64
    %124 = llvm.and %123, %c9007199254740991_i64 : i64
    %125 = llvm.shl %124, %c4_i64 : i64
    llvm.store %125, %107 : i64, !llvm.ptr
    %126 = llvm.sub %102, %c1_i64 : i64
    %127 = llvm.sub %104, %c1_i64 : i64
    %128 = llvm.mul %126, %103 : i64
    %129 = llvm.mul %127, %105 : i64
    %130 = llvm.add %128, %129 : i64
    %131 = llvm.mul %101, %c16_i64 : i64
    %132 = llvm.udiv %131, %c8_i64 : i64
    %133 = llvm.add %132, %130 : i64
    %134 = llvm.add %133, %45 : i64
    %135 = llvm.icmp "uge" %134, %c131072_i64 : i64
    %136 = llvm.zext %135 : i1 to i64
    %137 = llvm.shl %136, %c21_i64 : i64
    %138 = llvm.udiv %103, %c16_i64 : i64
    %139 = llvm.shl %138, %c32_i64 : i64
    %140 = llvm.or %c0_i64, %137 : i64
    %141 = llvm.or %140, %139 : i64
    %142 = llvm.or %5, %141 : i64
    llvm.store %142, %108 : i64, !llvm.ptr
    %143 = llvm.udiv %105, %c16_i64 : i64
    %144 = llvm.and %143, %c4294967295_i64 : i64
    %145 = llvm.shl %144, %c0_i64 : i64
    %146 = llvm.or %145, %62 : i64
    llvm.store %146, %109 : i64, !llvm.ptr
    %147 = llvm.lshr %103, %c36_i64 : i64
    %148 = llvm.and %147, %c15_i64 : i64
    %149 = llvm.shl %148, %c32_i64 : i64
    %150 = llvm.lshr %105, %c36_i64 : i64
    %151 = llvm.and %150, %c15_i64 : i64
    %152 = llvm.shl %151, %c36_i64 : i64
    %153 = llvm.or %149, %152 : i64
    %154 = llvm.or %153, %77 : i64
    %155 = llvm.or %65, %154 : i64
    llvm.store %155, %110 : i64, !llvm.ptr
    %156 = llvm.sub %101, %c1_i64 : i64
    %157 = llvm.and %156, %c4294967295_i64 : i64
    %158 = llvm.shl %157, %c0_i64 : i64
    %159 = llvm.shl %126, %c32_i64 : i64
    %160 = llvm.or %158, %159 : i64
    llvm.store %160, %111 : i64, !llvm.ptr
    %161 = llvm.and %127, %c4294967295_i64 : i64
    %162 = llvm.shl %161, %c0_i64 : i64
    %163 = llvm.or %162, %87 : i64
    llvm.store %163, %112 : i64, !llvm.ptr
    llvm.store %91, %113 : i64, !llvm.ptr
    llvm.store %3, %114 : i64, !llvm.ptr
    %164 = builtin.unrealized_conversion_cast %99 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %165 = cute.ptrtoint(%164) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %166 = llvm.inttoptr %165 : i64 to !llvm.ptr
    %167 = llvm.load %166 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %168 = builtin.unrealized_conversion_cast %167 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %169 = cute_nvgpu.atom.set_value(%atom_0, %168 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %170 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%170, %8) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_5 = cute.make_view(%7, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %171 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_6 = cute.get_iter(%arg2) : !memref_gmem_f16_
    %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %172:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %173 = arith.extui %172#1 : i32 to i64
    %174 = arith.extui %172#0 : i32 to i64
    %175 = llvm.mul %172#3, %c2_i64 : i64
    %176 = arith.extui %172#2 : i32 to i64
    %177 = llvm.mul %172#4, %c2_i64 : i64
    %178 = cute.ptrtoint(%iter_6) : !cute.ptr<f16, gmem, align<16>> to i64
    %179 = llvm.getelementptr %171[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %179 : i64, !llvm.ptr
    %180 = llvm.getelementptr %171[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %180 : i64, !llvm.ptr
    %181 = llvm.getelementptr %171[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %181 : i64, !llvm.ptr
    %182 = llvm.getelementptr %171[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %171[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %171[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %171[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %171[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %171[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %171[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %171[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %171[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %171[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %171[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %171[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %171[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.udiv %178, %c16_i64 : i64
    %196 = llvm.and %195, %c9007199254740991_i64 : i64
    %197 = llvm.shl %196, %c4_i64 : i64
    llvm.store %197, %179 : i64, !llvm.ptr
    %198 = llvm.sub %174, %c1_i64 : i64
    %199 = llvm.sub %176, %c1_i64 : i64
    %200 = llvm.mul %198, %175 : i64
    %201 = llvm.mul %199, %177 : i64
    %202 = llvm.add %200, %201 : i64
    %203 = llvm.mul %173, %c16_i64 : i64
    %204 = llvm.udiv %203, %c8_i64 : i64
    %205 = llvm.add %204, %202 : i64
    %206 = llvm.add %205, %45 : i64
    %207 = llvm.icmp "uge" %206, %c131072_i64 : i64
    %208 = llvm.zext %207 : i1 to i64
    %209 = llvm.shl %208, %c21_i64 : i64
    %210 = llvm.udiv %175, %c16_i64 : i64
    %211 = llvm.shl %210, %c32_i64 : i64
    %212 = llvm.or %c0_i64, %209 : i64
    %213 = llvm.or %212, %211 : i64
    %214 = llvm.or %2, %213 : i64
    llvm.store %214, %180 : i64, !llvm.ptr
    %215 = llvm.udiv %177, %c16_i64 : i64
    %216 = llvm.and %215, %c4294967295_i64 : i64
    %217 = llvm.shl %216, %c0_i64 : i64
    %218 = llvm.or %217, %62 : i64
    llvm.store %218, %181 : i64, !llvm.ptr
    %219 = llvm.lshr %175, %c36_i64 : i64
    %220 = llvm.and %219, %c15_i64 : i64
    %221 = llvm.shl %220, %c32_i64 : i64
    %222 = llvm.lshr %177, %c36_i64 : i64
    %223 = llvm.and %222, %c15_i64 : i64
    %224 = llvm.shl %223, %c36_i64 : i64
    %225 = llvm.or %221, %224 : i64
    %226 = llvm.or %225, %77 : i64
    %227 = llvm.or %65, %226 : i64
    llvm.store %227, %182 : i64, !llvm.ptr
    %228 = llvm.sub %173, %c1_i64 : i64
    %229 = llvm.and %228, %c4294967295_i64 : i64
    %230 = llvm.shl %229, %c0_i64 : i64
    %231 = llvm.shl %198, %c32_i64 : i64
    %232 = llvm.or %230, %231 : i64
    llvm.store %232, %183 : i64, !llvm.ptr
    %233 = llvm.and %199, %c4294967295_i64 : i64
    %234 = llvm.shl %233, %c0_i64 : i64
    %235 = llvm.or %234, %87 : i64
    llvm.store %235, %184 : i64, !llvm.ptr
    %236 = llvm.or %90, %1 : i64
    llvm.store %236, %185 : i64, !llvm.ptr
    llvm.store %0, %186 : i64, !llvm.ptr
    %237 = builtin.unrealized_conversion_cast %171 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %238 = cute.ptrtoint(%237) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %239 = llvm.inttoptr %238 : i64 to !llvm.ptr
    %240 = llvm.load %239 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %241 = builtin.unrealized_conversion_cast %240 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_8 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %242 = cute_nvgpu.atom.set_value(%atom_8, %241 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %243 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_9 = cute.make_layout(%243, %8) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_10 = cute.make_view(%7, %lay_9) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %244 = arith.ceildivsi %172#0, %c128_i32 : i32
    %245 = arith.muli %172#3, %c128_i64 : i64
    %246 = arith.ceildivsi %172#1, %c128_i32 : i32
    %shape = cute.make_shape(%244, %246, %172#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
    %iv = cute.assume(%245) : (i64) -> !cute.i64<divby 128>
    %stride = cute.make_stride(%172#3, %iv, %172#4) : (i64, !cute.i64<divby 128>, i64) -> !cute.stride<"((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %lay_11 = cute.make_layout(%shape, %stride) : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %247:6 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %shape_12 = cute.make_shape(%247#0, %247#1, %247#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_13 = cute.assume(%247#4) : (i64) -> !cute.i64<divby 128>
    %stride_14 = cute.make_stride(%iv_13, %247#5) : (!cute.i64<divby 128>, i64) -> !cute.stride<"(?{i64 div=128},128,?{i64})">
    %lay_15 = cute.make_layout(%shape_12, %stride_14) : !cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">
    %248 = cute.get_shape(%lay_15) : (!cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%248) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_17 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_16, %itup_17) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %249:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_18 = cute.make_int_tuple(%249#0, %249#1, %249#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_19, %e1_20, %e2_21 = cute.get_leaves(%int_tuple_18) : !cute.int_tuple<"(?,?,?)">
    %mul = cute.tuple_mul(%e0_19, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %250 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
    %mul_22 = cute.tuple_mul(%e1_20, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %251 = cute.get_scalars(%mul_22) : !cute.int_tuple<"?">
    %mul_23 = cute.tuple_mul(%e2_21, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %252 = cute.get_scalars(%mul_23) : !cute.int_tuple<"?">
    %253 = arith.index_cast %250 : i32 to index
    %254 = arith.index_cast %251 : i32 to index
    %255 = arith.index_cast %252 : i32 to index
    %256 = gpu.launch_func async [%arg3] @kernels::@kernel_cutlass_kernel___main__HopperWgmmaGemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1819201_TVLayoutDst1819201_Valuetypef16_tensor000o111012_CopyAtom_ThrID10_TVLayoutSrc1819201_TVL_0 clusters in (%c1, %c1, %c1) blocks in (%253, %254, %255) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c230400_i32 args(%97 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %169 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %242 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_10 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %10 : !mma_f16_f16_f32_64x128x16_) {use_pdl = false}
    return
  }
}
