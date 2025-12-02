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
      %170 = arith.divsi %169, %c32_i32 : i32
      %171 = arith.muli %170, %c32_i32 : i32
      %172 = arith.cmpi ne, %169, %171 : i32
      %c0_i32_0 = arith.constant 0 : i32
      %173 = arith.cmpi slt, %169, %c0_i32_0 : i32
      %174 = arith.cmpi slt, %c32_i32, %c0_i32_0 : i32
      %175 = arith.cmpi ne, %173, %174 : i1
      %176 = arith.andi %172, %175 : i1
      %c-1_i32 = arith.constant -1 : i32
      %177 = arith.addi %170, %c-1_i32 : i32
      %178 = arith.select %176, %177, %170 : i32
      %179 = cute_nvgpu.arch.make_warp_uniform(%178) : i32
      %180 = arith.cmpi eq, %179, %c0_i32 : i32
      cf.cond_br %180, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %181 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %182 = nvvm.read.ptx.sreg.clusterid.x : i32
      %183 = nvvm.read.ptx.sreg.clusterid.y : i32
      %184 = nvvm.read.ptx.sreg.nclusterid.x : i32
      %185 = nvvm.read.ptx.sreg.nclusterid.y : i32
      %186 = arith.muli %184, %183 : i32
      %187 = arith.addi %182, %186 : i32
      %188 = arith.divsi %184, %c8_i32 : i32
      %189 = arith.muli %188, %c8_i32 : i32
      %190 = arith.cmpi ne, %184, %189 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %191 = arith.cmpi slt, %184, %c0_i32_1 : i32
      %192 = arith.cmpi slt, %c8_i32, %c0_i32_1 : i32
      %193 = arith.cmpi ne, %191, %192 : i1
      %194 = arith.andi %190, %193 : i1
      %c-1_i32_2 = arith.constant -1 : i32
      %195 = arith.addi %188, %c-1_i32_2 : i32
      %196 = arith.select %194, %195, %188 : i32
      %197 = arith.muli %185, %c8_i32 : i32
      %shape = cute.make_shape(%196, %185) : (i32, i32) -> !cute.shape<"((8,?),?)">
      %stride = cute.make_stride(%197) : (i32) -> !cute.stride<"((1,?),8)">
      %lay = cute.make_layout(%shape, %stride) : !cute.layout<"((8,?),?):((1,?),8)">
      %int_tuple = cute.make_int_tuple(%196, %185) : (i32, i32) -> !cute.int_tuple<"((8,?),?)">
      %sz = cute.size(%int_tuple) : (!cute.int_tuple<"((8,?),?)">) -> !cute.int_tuple<"?{div=8}">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?{div=8}">
      %198 = cute.get_scalars(%e0) : !cute.int_tuple<"?{div=8}">
      %int_tuple_3 = cute.make_int_tuple(%187) : (i32) -> !cute.int_tuple<"?">
      %mod = cute.tuple_mod(%int_tuple_3, %e0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.int_tuple<"?">
      %199 = cute.get_scalars(%mod) : !cute.int_tuple<"?">
      %200 = cute.get_flat_coord(%199, %lay) : (i32, !cute.layout<"((8,?),?):((1,?),8)">) -> !cute.coord<"(?,?)">
      %e0_4, %e1 = cute.get_leaves(%200) : !cute.coord<"(?,?)">
      %itup = cute.to_int_tuple(%e0_4) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %201 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_5 = cute.to_int_tuple(%e1) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %202 = cute.get_scalars(%itup_5) : !cute.int_tuple<"?">
      %203 = arith.cmpi sle, %198, %187 : i32
      cf.cond_br %203, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %204 = arith.remsi %184, %c8_i32 : i32
      %shape_6 = cute.make_shape(%204, %185) : (i32, i32) -> !cute.shape<"(?,?)">
      %stride_7 = cute.make_stride(%204) : (i32) -> !cute.stride<"(1,?)">
      %lay_8 = cute.make_layout(%shape_6, %stride_7) : !cute.layout<"(?,?):(1,?)">
      %sub = cute.tuple_sub(%int_tuple_3, %e0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.int_tuple<"?">
      %205 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %206 = cute.get_flat_coord(%205, %lay_8) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_9, %e1_10 = cute.get_leaves(%206) : !cute.coord<"(?,?)">
      %itup_11 = cute.to_int_tuple(%e0_9) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e1_10) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %207 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %sz_13 = cute.size(%int_tuple) <{mode = [0]}> : (!cute.int_tuple<"((8,?),?)">) -> !cute.int_tuple<"?{div=8}">
      %e0_14 = cute.get_leaves(%sz_13) : !cute.int_tuple<"?{div=8}">
      %tup = cute.add_offset(%e0_14, %itup_11) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %208 = cute.get_scalars(%tup) : !cute.int_tuple<"?">
      cf.br ^bb5(%208, %207 : i32, i32)
    ^bb4:  // pred: ^bb2
      cf.br ^bb5(%201, %202 : i32, i32)
    ^bb5(%209: i32, %210: i32):  // 2 preds: ^bb3, ^bb4
      cf.br ^bb6
    ^bb6:  // pred: ^bb5
      %211 = nvvm.read.ptx.sreg.cluster.ctaid.x : i32
      %212 = nvvm.read.ptx.sreg.cluster.ctaid.y : i32
      %213 = arith.addi %209, %211 : i32
      %214 = arith.addi %210, %212 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %159) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_15 = cute.add_offset(%smem_ptr, %158) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"115712">) -> !cute.ptr<i8, smem, align<1024>>
      %iter = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %180, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %215 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %215, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter, %157) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %216 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %216, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_17 = cute.add_offset(%iter, %156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %217 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %217, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_18 = cute.add_offset(%iter, %155) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %218 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %218, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_19 = cute.add_offset(%iter, %154) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %219 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %219, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_20 = cute.add_offset(%iter, %153) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %220 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %220, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_21 = cute.add_offset(%iter, %152) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %221 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %221, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_22 = cute.add_offset(%iter, %151) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %180, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %222 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %222, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_23 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_24 = cute.add_offset(%iter, %int_tuple_23) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_24) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %223 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %223, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_25 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_26 = cute.add_offset(%iter, %int_tuple_25) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %224 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %224, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_28 = cute.add_offset(%iter, %int_tuple_27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_29 = cute.derefine(%ptr_28) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %225 = builtin.unrealized_conversion_cast %dyn_29 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %225, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_30 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_31 = cute.add_offset(%iter, %int_tuple_30) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %226 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %226, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_32 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_33 = cute.add_offset(%iter, %int_tuple_32) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_34 = cute.derefine(%ptr_33) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %227 = builtin.unrealized_conversion_cast %dyn_34 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %227, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_35 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_36 = cute.add_offset(%iter, %int_tuple_35) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %228 = builtin.unrealized_conversion_cast %ptr_36 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %228, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %229 = arith.remsi %160, %c32_i32 : i32
      %230 = arith.cmpi slt, %229, %c1_i32 : i32
      %231 = arith.extui %230 : i1 to i32
      %232 = arith.select %230, %c1_i32, %231 : i32
      %233 = arith.cmpi ne, %232, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_37 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_38 = cute.recast_iter(%ptr_15) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_39 = cute.recast_iter(%iter_37) : !cute.ptr<f16, smem, align<1024>, S<3,4,3>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord = cute.make_coord(%213, %214, %181) : (i32, i32, i32) -> !cute.coord<"(?,?,_,?)">
      %234:3 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_,?)">
      %coord_40 = cute.make_coord(%234#0, %234#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_41 = cute.get_layout(%arg1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %235:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_42 = arith.constant 1 : i32
      %c0_i32_43 = arith.constant 0 : i32
      %c-1_i32_44 = arith.constant -1 : i32
      %236 = arith.cmpi sgt, %c128_i32, %c0_i32_43 : i32
      %237 = arith.select %236, %c-1_i32_44, %c1_i32_42 : i32
      %238 = arith.addi %237, %235#0 : i32
      %239 = arith.divsi %238, %c128_i32 : i32
      %240 = arith.addi %c1_i32_42, %239 : i32
      %241 = arith.subi %c0_i32_43, %235#0 : i32
      %242 = arith.divsi %241, %c128_i32 : i32
      %243 = arith.subi %c0_i32_43, %242 : i32
      %244 = arith.cmpi slt, %235#0, %c0_i32_43 : i32
      %245 = arith.cmpi sgt, %235#0, %c0_i32_43 : i32
      %246 = arith.cmpi slt, %c128_i32, %c0_i32_43 : i32
      %247 = arith.cmpi sgt, %c128_i32, %c0_i32_43 : i32
      %248 = arith.andi %244, %246 : i1
      %249 = arith.andi %245, %247 : i1
      %250 = arith.ori %248, %249 : i1
      %251 = arith.select %250, %240, %243 : i32
      %c1_i32_45 = arith.constant 1 : i32
      %c0_i32_46 = arith.constant 0 : i32
      %c-1_i32_47 = arith.constant -1 : i32
      %252 = arith.cmpi sgt, %c64_i32, %c0_i32_46 : i32
      %253 = arith.select %252, %c-1_i32_47, %c1_i32_45 : i32
      %254 = arith.addi %253, %235#1 : i32
      %255 = arith.divsi %254, %c64_i32 : i32
      %256 = arith.addi %c1_i32_45, %255 : i32
      %257 = arith.subi %c0_i32_46, %235#1 : i32
      %258 = arith.divsi %257, %c64_i32 : i32
      %259 = arith.subi %c0_i32_46, %258 : i32
      %260 = arith.cmpi slt, %235#1, %c0_i32_46 : i32
      %261 = arith.cmpi sgt, %235#1, %c0_i32_46 : i32
      %262 = arith.cmpi slt, %c64_i32, %c0_i32_46 : i32
      %263 = arith.cmpi sgt, %c64_i32, %c0_i32_46 : i32
      %264 = arith.andi %260, %262 : i1
      %265 = arith.andi %261, %263 : i1
      %266 = arith.ori %264, %265 : i1
      %267 = arith.select %266, %256, %259 : i32
      %shape_48 = cute.make_shape(%251, %267, %235#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_49 = cute.make_layout(%shape_48, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %268:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_50 = cute.make_shape(%268#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_51 = cute.make_layout(%shape_50, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_40, %lay_49) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_52 = cute.add_offset(%148, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_53 = cute.make_coord(%234#1, %234#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_54 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %269:3 = cute.get_scalars(%lay_54) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_55 = arith.constant 1 : i32
      %c0_i32_56 = arith.constant 0 : i32
      %c-1_i32_57 = arith.constant -1 : i32
      %270 = arith.cmpi sgt, %c128_i32, %c0_i32_56 : i32
      %271 = arith.select %270, %c-1_i32_57, %c1_i32_55 : i32
      %272 = arith.addi %271, %269#0 : i32
      %273 = arith.divsi %272, %c128_i32 : i32
      %274 = arith.addi %c1_i32_55, %273 : i32
      %275 = arith.subi %c0_i32_56, %269#0 : i32
      %276 = arith.divsi %275, %c128_i32 : i32
      %277 = arith.subi %c0_i32_56, %276 : i32
      %278 = arith.cmpi slt, %269#0, %c0_i32_56 : i32
      %279 = arith.cmpi sgt, %269#0, %c0_i32_56 : i32
      %280 = arith.cmpi slt, %c128_i32, %c0_i32_56 : i32
      %281 = arith.cmpi sgt, %c128_i32, %c0_i32_56 : i32
      %282 = arith.andi %278, %280 : i1
      %283 = arith.andi %279, %281 : i1
      %284 = arith.ori %282, %283 : i1
      %285 = arith.select %284, %274, %277 : i32
      %c1_i32_58 = arith.constant 1 : i32
      %c0_i32_59 = arith.constant 0 : i32
      %c-1_i32_60 = arith.constant -1 : i32
      %286 = arith.cmpi sgt, %c64_i32, %c0_i32_59 : i32
      %287 = arith.select %286, %c-1_i32_60, %c1_i32_58 : i32
      %288 = arith.addi %287, %269#1 : i32
      %289 = arith.divsi %288, %c64_i32 : i32
      %290 = arith.addi %c1_i32_58, %289 : i32
      %291 = arith.subi %c0_i32_59, %269#1 : i32
      %292 = arith.divsi %291, %c64_i32 : i32
      %293 = arith.subi %c0_i32_59, %292 : i32
      %294 = arith.cmpi slt, %269#1, %c0_i32_59 : i32
      %295 = arith.cmpi sgt, %269#1, %c0_i32_59 : i32
      %296 = arith.cmpi slt, %c64_i32, %c0_i32_59 : i32
      %297 = arith.cmpi sgt, %c64_i32, %c0_i32_59 : i32
      %298 = arith.andi %294, %296 : i1
      %299 = arith.andi %295, %297 : i1
      %300 = arith.ori %298, %299 : i1
      %301 = arith.select %300, %290, %293 : i32
      %shape_61 = cute.make_shape(%285, %301, %269#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_62 = cute.make_layout(%shape_61, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %302:3 = cute.get_scalars(%lay_62) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_63 = cute.make_shape(%302#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_64 = cute.make_layout(%shape_63, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx_65 = cute.crd2idx(%coord_53, %lay_62) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_66 = cute.add_offset(%148, %idx_65) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_67 = cute.make_coord(%234#0, %234#1, %234#2) : (i32, i32, i32) -> !cute.coord<"((_,_),(?,?,?))">
      %lay_68 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %303:3 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_69 = arith.constant 1 : i32
      %c0_i32_70 = arith.constant 0 : i32
      %c-1_i32_71 = arith.constant -1 : i32
      %304 = arith.cmpi sgt, %c128_i32, %c0_i32_70 : i32
      %305 = arith.select %304, %c-1_i32_71, %c1_i32_69 : i32
      %306 = arith.addi %305, %303#0 : i32
      %307 = arith.divsi %306, %c128_i32 : i32
      %308 = arith.addi %c1_i32_69, %307 : i32
      %309 = arith.subi %c0_i32_70, %303#0 : i32
      %310 = arith.divsi %309, %c128_i32 : i32
      %311 = arith.subi %c0_i32_70, %310 : i32
      %312 = arith.cmpi slt, %303#0, %c0_i32_70 : i32
      %313 = arith.cmpi sgt, %303#0, %c0_i32_70 : i32
      %314 = arith.cmpi slt, %c128_i32, %c0_i32_70 : i32
      %315 = arith.cmpi sgt, %c128_i32, %c0_i32_70 : i32
      %316 = arith.andi %312, %314 : i1
      %317 = arith.andi %313, %315 : i1
      %318 = arith.ori %316, %317 : i1
      %319 = arith.select %318, %308, %311 : i32
      %c1_i32_72 = arith.constant 1 : i32
      %c0_i32_73 = arith.constant 0 : i32
      %c-1_i32_74 = arith.constant -1 : i32
      %320 = arith.cmpi sgt, %c128_i32, %c0_i32_73 : i32
      %321 = arith.select %320, %c-1_i32_74, %c1_i32_72 : i32
      %322 = arith.addi %321, %303#1 : i32
      %323 = arith.divsi %322, %c128_i32 : i32
      %324 = arith.addi %c1_i32_72, %323 : i32
      %325 = arith.subi %c0_i32_73, %303#1 : i32
      %326 = arith.divsi %325, %c128_i32 : i32
      %327 = arith.subi %c0_i32_73, %326 : i32
      %328 = arith.cmpi slt, %303#1, %c0_i32_73 : i32
      %329 = arith.cmpi sgt, %303#1, %c0_i32_73 : i32
      %330 = arith.cmpi slt, %c128_i32, %c0_i32_73 : i32
      %331 = arith.cmpi sgt, %c128_i32, %c0_i32_73 : i32
      %332 = arith.andi %328, %330 : i1
      %333 = arith.andi %329, %331 : i1
      %334 = arith.ori %332, %333 : i1
      %335 = arith.select %334, %324, %327 : i32
      %shape_75 = cute.make_shape(%319, %335, %303#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_76 = cute.make_layout(%shape_75, %147) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %idx_77 = cute.crd2idx(%coord_67, %lay_76) : (!cute.coord<"((_,_),(?,?,?))">, !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %tup_78 = cute.add_offset(%148, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %336 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_79 = cute.make_shape(%336) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_80 = cute.make_layout(%shape_79, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %337 = cute.get_scalars(%lay_80) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_81 = cute.make_shape(%337) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_82 = cute.make_layout(%shape_81, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %338 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_83 = cute.make_shape(%338) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_84 = cute.make_layout(%shape_83, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %339 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_85 = cute.make_shape(%339) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_86 = cute.make_layout(%shape_85, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %gmmaSmemDesc = cute_nvgpu.make_gmma_smem_desc(%iter_37 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((64,16),2,4,(1,7)):((64,1),4096,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %gmmaSmemDesc_87 = cute_nvgpu.make_gmma_smem_desc(%iter_38 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,(1,7)):((64,1),0,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      nvvm.barrier
      %sz_88 = cute.size(%lay_51) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_89 = cute.get_leaves(%sz_88) : !cute.int_tuple<"?">
      %340 = cute.get_scalars(%e0_89) : !cute.int_tuple<"?">
      %341 = arith.cmpi slt, %340, %c7_i32 : i32
      %342 = arith.select %341, %340, %c7_i32 : i32
      %343 = arith.cmpi sgt, %342, %c0_i32 : i32
      %344 = arith.select %343, %342, %c0_i32 : i32
      cf.cond_br %180, ^bb11, ^bb27
    ^bb11:  // pred: ^bb10
      %345 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %346 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %347 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb12(%c0_i32, %c0_i32, %c0_i32, %c1_i32 : i32, i32, i32, i32)
    ^bb12(%348: i32, %349: i32, %350: i32, %351: i32):  // 2 preds: ^bb11, ^bb25
      %352 = arith.cmpi slt, %348, %344 : i32
      cf.cond_br %352, ^bb13, ^bb26 {loop_annotation = #loop_annotation}
    ^bb13:  // pred: ^bb12
      %int_tuple_90 = cute.make_int_tuple(%350) : (i32) -> !cute.int_tuple<"?">
      %ptr_91 = cute.add_offset(%ptr_22, %int_tuple_90) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %353 = builtin.unrealized_conversion_cast %ptr_91 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %353, %351, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %354 = nvvm.elect.sync -> i1
      cf.cond_br %354, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %ptr_92 = cute.add_offset(%iter, %int_tuple_90) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %355 = builtin.unrealized_conversion_cast %ptr_92 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %355, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %coord_93 = cute.make_coord(%349) : (i32) -> !cute.coord<"(_,?)">
      %idx_94 = cute.crd2idx(%coord_93, %lay_82) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_95 = cute.add_offset(%tup_52, %idx_94) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_96, %e1_97, %e2 = cute.get_leaves(%tup_95) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %coord_98 = cute.make_coord(%350) : (i32) -> !cute.coord<"(_,?)">
      %idx_99 = cute.crd2idx(%coord_98, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_100 = cute.add_offset(%iter_37, %idx_99) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_101 = cute.crd2idx(%coord_93, %lay_86) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_102 = cute.add_offset(%tup_66, %idx_101) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_103, %e1_104, %e2_105 = cute.get_leaves(%tup_102) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %ptr_106 = cute.add_offset(%iter_38, %idx_99) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_107 = cute.add_offset(%iter, %int_tuple_90) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_108 = cute.make_int_tuple(%e0_96, %e1_97, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %356 = cute_nvgpu.atom.set_value(%345, %ptr_107 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %357 = cute_nvgpu.atom.get_value(%356 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%356 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %358:3 = cute.get_scalars(%int_tuple_108) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb16(%c0_i32 : i32)
    ^bb16(%359: i32):  // 2 preds: ^bb15, ^bb17
      %360 = arith.cmpi slt, %359, %346 : i32
      cf.cond_br %360, ^bb17, ^bb18 {llvm.loop_annotation = #loop_annotation1}
    ^bb17:  // pred: ^bb16
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_100 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %357 : !cute.ptr<smem, align<8>>, [%358#0, %358#1, %358#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %361 = arith.addi %359, %c1_i32 : i32
      cf.br ^bb16(%361 : i32)
    ^bb18:  // pred: ^bb16
      %int_tuple_109 = cute.make_int_tuple(%e0_103, %e1_104, %e2_105) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %362 = cute_nvgpu.atom.set_value(%347, %ptr_107 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %363 = cute_nvgpu.atom.get_value(%362 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_110 = cute_nvgpu.get_tma_desc_addr(%362 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %364:3 = cute.get_scalars(%int_tuple_109) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%365: i32):  // 2 preds: ^bb18, ^bb20
      %366 = arith.cmpi slt, %365, %346 : i32
      cf.cond_br %366, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation1}
    ^bb20:  // pred: ^bb19
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_110 : !cute.ptr<generic, align<64>>, %ptr_106 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %363 : !cute.ptr<smem, align<8>>, [%364#0, %364#1, %364#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %367 = arith.addi %365, %c1_i32 : i32
      cf.br ^bb19(%367 : i32)
    ^bb21:  // pred: ^bb19
      %368 = arith.addi %350, %c1_i32 : i32
      %369 = arith.addi %349, %c1_i32 : i32
      %370 = arith.cmpi eq, %368, %c7_i32 : i32
      %371 = arith.select %370, %c0_i32, %368 : i32
      cf.cond_br %370, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %372 = arith.xori %351, %c1_i32 : i32
      cf.br ^bb24(%372 : i32)
    ^bb23:  // pred: ^bb21
      cf.br ^bb24(%351 : i32)
    ^bb24(%373: i32):  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // pred: ^bb24
      %374 = arith.addi %348, %c1_i32 : i32
      cf.br ^bb12(%374, %369, %371, %373 : i32, i32, i32, i32)
    ^bb26:  // pred: ^bb12
      cf.br ^bb28(%349, %350, %351 : i32, i32, i32)
    ^bb27:  // pred: ^bb10
      cf.br ^bb28(%c0_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb28(%375: i32, %376: i32, %377: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %378 = arith.cmpi sgt, %340, %c0_i32 : i32
      cf.cond_br %378, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %dyn_111 = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
      %379 = builtin.unrealized_conversion_cast %dyn_111 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %380 = nvvm.mbarrier.wait.parity %379, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb32(%380 : i1)
    ^bb31:  // pred: ^bb29
      cf.br ^bb32(%true : i1)
    ^bb32(%381: i1):  // 2 preds: ^bb30, ^bb31
      cf.br ^bb33
    ^bb33:  // pred: ^bb32
      %382 = cute_nvgpu.atom.set_value(%arg6, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
      %383 = builtin.unrealized_conversion_cast %382 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
      %384 = arith.extui %381 : i1 to i32
      %385 = arith.cmpi eq, %384, %c0_i32 : i32
      cf.cond_br %385, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %dyn_112 = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
      %386 = builtin.unrealized_conversion_cast %dyn_112 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %386, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb35
    ^bb35:  // 2 preds: ^bb33, ^bb34
      nvvm.wgmma.fence.aligned
      %iter_113 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %387 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %388 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      cf.br ^bb36(%c0_i32, %383 : i32, !llvm.struct<(i1)>)
    ^bb36(%389: i32, %390: !llvm.struct<(i1)>):  // 2 preds: ^bb35, ^bb46
      %391 = arith.cmpi slt, %389, %c4_i32 : i32
      cf.cond_br %391, ^bb37, ^bb47 {loop_annotation = #loop_annotation2}
    ^bb37:  // pred: ^bb36
      %392 = builtin.unrealized_conversion_cast %390 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
      %coord_114 = cute.make_coord(%389) : (i32) -> !cute.coord<"(_,_,?,0)">
      %idx_115 = cute.crd2idx(%coord_114, %142) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_116 = cute.add_offset(%gmmaSmemDesc, %idx_115) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_117 = cute.crd2idx(%coord_114, %141) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_118 = cute.add_offset(%gmmaSmemDesc_87, %idx_117) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %393 = cute_nvgpu.atom.get_value(%392 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%394: i32):  // 2 preds: ^bb37, ^bb45
      %395 = arith.cmpi slt, %394, %387 : i32
      cf.cond_br %395, ^bb39, ^bb46 {llvm.loop_annotation = #loop_annotation1}
    ^bb39:  // pred: ^bb38
      cf.br ^bb40(%c0_i32 : i32)
    ^bb40(%396: i32):  // 2 preds: ^bb39, ^bb44
      %397 = arith.cmpi slt, %396, %388 : i32
      cf.cond_br %397, ^bb41, ^bb45 {llvm.loop_annotation = #loop_annotation1}
    ^bb41:  // pred: ^bb40
      %coord_119 = cute.make_coord(%396, %394) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_120 = cute.crd2idx(%coord_119, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
      %tup_121 = cute.add_offset(%tup_116, %idx_120) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%398: i32):  // 2 preds: ^bb41, ^bb43
      %399 = arith.cmpi slt, %398, %387 : i32
      cf.cond_br %399, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation1}
    ^bb43:  // pred: ^bb42
      %coord_122 = cute.make_coord(%396, %398) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_123 = cute.crd2idx(%coord_122, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_124 = cute.add_offset(%iter_113, %idx_123) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
      %400 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %401 = llvm.load %400 : !llvm.ptr -> f32
      %402 = llvm.getelementptr %400[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %403 = llvm.load %402 : !llvm.ptr -> f32
      %404 = llvm.getelementptr %400[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %405 = llvm.load %404 : !llvm.ptr -> f32
      %406 = llvm.getelementptr %400[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %407 = llvm.load %406 : !llvm.ptr -> f32
      %408 = llvm.getelementptr %400[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %409 = llvm.load %408 : !llvm.ptr -> f32
      %410 = llvm.getelementptr %400[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %411 = llvm.load %410 : !llvm.ptr -> f32
      %412 = llvm.getelementptr %400[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %413 = llvm.load %412 : !llvm.ptr -> f32
      %414 = llvm.getelementptr %400[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %415 = llvm.load %414 : !llvm.ptr -> f32
      %416 = llvm.getelementptr %400[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %417 = llvm.load %416 : !llvm.ptr -> f32
      %418 = llvm.getelementptr %400[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %419 = llvm.load %418 : !llvm.ptr -> f32
      %420 = llvm.getelementptr %400[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %421 = llvm.load %420 : !llvm.ptr -> f32
      %422 = llvm.getelementptr %400[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %423 = llvm.load %422 : !llvm.ptr -> f32
      %424 = llvm.getelementptr %400[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %425 = llvm.load %424 : !llvm.ptr -> f32
      %426 = llvm.getelementptr %400[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %427 = llvm.load %426 : !llvm.ptr -> f32
      %428 = llvm.getelementptr %400[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %429 = llvm.load %428 : !llvm.ptr -> f32
      %430 = llvm.getelementptr %400[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %431 = llvm.load %430 : !llvm.ptr -> f32
      %432 = llvm.getelementptr %400[16] : (!llvm.ptr) -> !llvm.ptr, f32
      %433 = llvm.load %432 : !llvm.ptr -> f32
      %434 = llvm.getelementptr %400[17] : (!llvm.ptr) -> !llvm.ptr, f32
      %435 = llvm.load %434 : !llvm.ptr -> f32
      %436 = llvm.getelementptr %400[18] : (!llvm.ptr) -> !llvm.ptr, f32
      %437 = llvm.load %436 : !llvm.ptr -> f32
      %438 = llvm.getelementptr %400[19] : (!llvm.ptr) -> !llvm.ptr, f32
      %439 = llvm.load %438 : !llvm.ptr -> f32
      %440 = llvm.getelementptr %400[20] : (!llvm.ptr) -> !llvm.ptr, f32
      %441 = llvm.load %440 : !llvm.ptr -> f32
      %442 = llvm.getelementptr %400[21] : (!llvm.ptr) -> !llvm.ptr, f32
      %443 = llvm.load %442 : !llvm.ptr -> f32
      %444 = llvm.getelementptr %400[22] : (!llvm.ptr) -> !llvm.ptr, f32
      %445 = llvm.load %444 : !llvm.ptr -> f32
      %446 = llvm.getelementptr %400[23] : (!llvm.ptr) -> !llvm.ptr, f32
      %447 = llvm.load %446 : !llvm.ptr -> f32
      %448 = llvm.getelementptr %400[24] : (!llvm.ptr) -> !llvm.ptr, f32
      %449 = llvm.load %448 : !llvm.ptr -> f32
      %450 = llvm.getelementptr %400[25] : (!llvm.ptr) -> !llvm.ptr, f32
      %451 = llvm.load %450 : !llvm.ptr -> f32
      %452 = llvm.getelementptr %400[26] : (!llvm.ptr) -> !llvm.ptr, f32
      %453 = llvm.load %452 : !llvm.ptr -> f32
      %454 = llvm.getelementptr %400[27] : (!llvm.ptr) -> !llvm.ptr, f32
      %455 = llvm.load %454 : !llvm.ptr -> f32
      %456 = llvm.getelementptr %400[28] : (!llvm.ptr) -> !llvm.ptr, f32
      %457 = llvm.load %456 : !llvm.ptr -> f32
      %458 = llvm.getelementptr %400[29] : (!llvm.ptr) -> !llvm.ptr, f32
      %459 = llvm.load %458 : !llvm.ptr -> f32
      %460 = llvm.getelementptr %400[30] : (!llvm.ptr) -> !llvm.ptr, f32
      %461 = llvm.load %460 : !llvm.ptr -> f32
      %462 = llvm.getelementptr %400[31] : (!llvm.ptr) -> !llvm.ptr, f32
      %463 = llvm.load %462 : !llvm.ptr -> f32
      %464 = llvm.getelementptr %400[32] : (!llvm.ptr) -> !llvm.ptr, f32
      %465 = llvm.load %464 : !llvm.ptr -> f32
      %466 = llvm.getelementptr %400[33] : (!llvm.ptr) -> !llvm.ptr, f32
      %467 = llvm.load %466 : !llvm.ptr -> f32
      %468 = llvm.getelementptr %400[34] : (!llvm.ptr) -> !llvm.ptr, f32
      %469 = llvm.load %468 : !llvm.ptr -> f32
      %470 = llvm.getelementptr %400[35] : (!llvm.ptr) -> !llvm.ptr, f32
      %471 = llvm.load %470 : !llvm.ptr -> f32
      %472 = llvm.getelementptr %400[36] : (!llvm.ptr) -> !llvm.ptr, f32
      %473 = llvm.load %472 : !llvm.ptr -> f32
      %474 = llvm.getelementptr %400[37] : (!llvm.ptr) -> !llvm.ptr, f32
      %475 = llvm.load %474 : !llvm.ptr -> f32
      %476 = llvm.getelementptr %400[38] : (!llvm.ptr) -> !llvm.ptr, f32
      %477 = llvm.load %476 : !llvm.ptr -> f32
      %478 = llvm.getelementptr %400[39] : (!llvm.ptr) -> !llvm.ptr, f32
      %479 = llvm.load %478 : !llvm.ptr -> f32
      %480 = llvm.getelementptr %400[40] : (!llvm.ptr) -> !llvm.ptr, f32
      %481 = llvm.load %480 : !llvm.ptr -> f32
      %482 = llvm.getelementptr %400[41] : (!llvm.ptr) -> !llvm.ptr, f32
      %483 = llvm.load %482 : !llvm.ptr -> f32
      %484 = llvm.getelementptr %400[42] : (!llvm.ptr) -> !llvm.ptr, f32
      %485 = llvm.load %484 : !llvm.ptr -> f32
      %486 = llvm.getelementptr %400[43] : (!llvm.ptr) -> !llvm.ptr, f32
      %487 = llvm.load %486 : !llvm.ptr -> f32
      %488 = llvm.getelementptr %400[44] : (!llvm.ptr) -> !llvm.ptr, f32
      %489 = llvm.load %488 : !llvm.ptr -> f32
      %490 = llvm.getelementptr %400[45] : (!llvm.ptr) -> !llvm.ptr, f32
      %491 = llvm.load %490 : !llvm.ptr -> f32
      %492 = llvm.getelementptr %400[46] : (!llvm.ptr) -> !llvm.ptr, f32
      %493 = llvm.load %492 : !llvm.ptr -> f32
      %494 = llvm.getelementptr %400[47] : (!llvm.ptr) -> !llvm.ptr, f32
      %495 = llvm.load %494 : !llvm.ptr -> f32
      %496 = llvm.getelementptr %400[48] : (!llvm.ptr) -> !llvm.ptr, f32
      %497 = llvm.load %496 : !llvm.ptr -> f32
      %498 = llvm.getelementptr %400[49] : (!llvm.ptr) -> !llvm.ptr, f32
      %499 = llvm.load %498 : !llvm.ptr -> f32
      %500 = llvm.getelementptr %400[50] : (!llvm.ptr) -> !llvm.ptr, f32
      %501 = llvm.load %500 : !llvm.ptr -> f32
      %502 = llvm.getelementptr %400[51] : (!llvm.ptr) -> !llvm.ptr, f32
      %503 = llvm.load %502 : !llvm.ptr -> f32
      %504 = llvm.getelementptr %400[52] : (!llvm.ptr) -> !llvm.ptr, f32
      %505 = llvm.load %504 : !llvm.ptr -> f32
      %506 = llvm.getelementptr %400[53] : (!llvm.ptr) -> !llvm.ptr, f32
      %507 = llvm.load %506 : !llvm.ptr -> f32
      %508 = llvm.getelementptr %400[54] : (!llvm.ptr) -> !llvm.ptr, f32
      %509 = llvm.load %508 : !llvm.ptr -> f32
      %510 = llvm.getelementptr %400[55] : (!llvm.ptr) -> !llvm.ptr, f32
      %511 = llvm.load %510 : !llvm.ptr -> f32
      %512 = llvm.getelementptr %400[56] : (!llvm.ptr) -> !llvm.ptr, f32
      %513 = llvm.load %512 : !llvm.ptr -> f32
      %514 = llvm.getelementptr %400[57] : (!llvm.ptr) -> !llvm.ptr, f32
      %515 = llvm.load %514 : !llvm.ptr -> f32
      %516 = llvm.getelementptr %400[58] : (!llvm.ptr) -> !llvm.ptr, f32
      %517 = llvm.load %516 : !llvm.ptr -> f32
      %518 = llvm.getelementptr %400[59] : (!llvm.ptr) -> !llvm.ptr, f32
      %519 = llvm.load %518 : !llvm.ptr -> f32
      %520 = llvm.getelementptr %400[60] : (!llvm.ptr) -> !llvm.ptr, f32
      %521 = llvm.load %520 : !llvm.ptr -> f32
      %522 = llvm.getelementptr %400[61] : (!llvm.ptr) -> !llvm.ptr, f32
      %523 = llvm.load %522 : !llvm.ptr -> f32
      %524 = llvm.getelementptr %400[62] : (!llvm.ptr) -> !llvm.ptr, f32
      %525 = llvm.load %524 : !llvm.ptr -> f32
      %526 = llvm.getelementptr %400[63] : (!llvm.ptr) -> !llvm.ptr, f32
      %527 = llvm.load %526 : !llvm.ptr -> f32
      %528:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_121 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_118 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%401, %403, %405, %407, %409, %411, %413, %415, %417, %419, %421, %423, %425, %427, %429, %431, %433, %435, %437, %439, %441, %443, %445, %447, %449, %451, %453, %455, %457, %459, %461, %463, %465, %467, %469, %471, %473, %475, %477, %479, %481, %483, %485, %487, %489, %491, %493, %495, %497, %499, %501, %503, %505, %507, %509, %511, %513, %515, %517, %519, %521, %523, %525, %527], accum = %393 : i1)
< {cd_type = f32, operandSegmentSizes = array<i32: 1, 1, 64, 1>}> :(!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, f32, i1) -> (f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32)
      llvm.store %528#0, %400 : f32, !llvm.ptr
      llvm.store %528#1, %402 : f32, !llvm.ptr
      llvm.store %528#2, %404 : f32, !llvm.ptr
      llvm.store %528#3, %406 : f32, !llvm.ptr
      llvm.store %528#4, %408 : f32, !llvm.ptr
      llvm.store %528#5, %410 : f32, !llvm.ptr
      llvm.store %528#6, %412 : f32, !llvm.ptr
      llvm.store %528#7, %414 : f32, !llvm.ptr
      llvm.store %528#8, %416 : f32, !llvm.ptr
      llvm.store %528#9, %418 : f32, !llvm.ptr
      llvm.store %528#10, %420 : f32, !llvm.ptr
      llvm.store %528#11, %422 : f32, !llvm.ptr
      llvm.store %528#12, %424 : f32, !llvm.ptr
      llvm.store %528#13, %426 : f32, !llvm.ptr
      llvm.store %528#14, %428 : f32, !llvm.ptr
      llvm.store %528#15, %430 : f32, !llvm.ptr
      llvm.store %528#16, %432 : f32, !llvm.ptr
      llvm.store %528#17, %434 : f32, !llvm.ptr
      llvm.store %528#18, %436 : f32, !llvm.ptr
      llvm.store %528#19, %438 : f32, !llvm.ptr
      llvm.store %528#20, %440 : f32, !llvm.ptr
      llvm.store %528#21, %442 : f32, !llvm.ptr
      llvm.store %528#22, %444 : f32, !llvm.ptr
      llvm.store %528#23, %446 : f32, !llvm.ptr
      llvm.store %528#24, %448 : f32, !llvm.ptr
      llvm.store %528#25, %450 : f32, !llvm.ptr
      llvm.store %528#26, %452 : f32, !llvm.ptr
      llvm.store %528#27, %454 : f32, !llvm.ptr
      llvm.store %528#28, %456 : f32, !llvm.ptr
      llvm.store %528#29, %458 : f32, !llvm.ptr
      llvm.store %528#30, %460 : f32, !llvm.ptr
      llvm.store %528#31, %462 : f32, !llvm.ptr
      llvm.store %528#32, %464 : f32, !llvm.ptr
      llvm.store %528#33, %466 : f32, !llvm.ptr
      llvm.store %528#34, %468 : f32, !llvm.ptr
      llvm.store %528#35, %470 : f32, !llvm.ptr
      llvm.store %528#36, %472 : f32, !llvm.ptr
      llvm.store %528#37, %474 : f32, !llvm.ptr
      llvm.store %528#38, %476 : f32, !llvm.ptr
      llvm.store %528#39, %478 : f32, !llvm.ptr
      llvm.store %528#40, %480 : f32, !llvm.ptr
      llvm.store %528#41, %482 : f32, !llvm.ptr
      llvm.store %528#42, %484 : f32, !llvm.ptr
      llvm.store %528#43, %486 : f32, !llvm.ptr
      llvm.store %528#44, %488 : f32, !llvm.ptr
      llvm.store %528#45, %490 : f32, !llvm.ptr
      llvm.store %528#46, %492 : f32, !llvm.ptr
      llvm.store %528#47, %494 : f32, !llvm.ptr
      llvm.store %528#48, %496 : f32, !llvm.ptr
      llvm.store %528#49, %498 : f32, !llvm.ptr
      llvm.store %528#50, %500 : f32, !llvm.ptr
      llvm.store %528#51, %502 : f32, !llvm.ptr
      llvm.store %528#52, %504 : f32, !llvm.ptr
      llvm.store %528#53, %506 : f32, !llvm.ptr
      llvm.store %528#54, %508 : f32, !llvm.ptr
      llvm.store %528#55, %510 : f32, !llvm.ptr
      llvm.store %528#56, %512 : f32, !llvm.ptr
      llvm.store %528#57, %514 : f32, !llvm.ptr
      llvm.store %528#58, %516 : f32, !llvm.ptr
      llvm.store %528#59, %518 : f32, !llvm.ptr
      llvm.store %528#60, %520 : f32, !llvm.ptr
      llvm.store %528#61, %522 : f32, !llvm.ptr
      llvm.store %528#62, %524 : f32, !llvm.ptr
      llvm.store %528#63, %526 : f32, !llvm.ptr
      %529 = arith.addi %398, %c1_i32 : i32
      cf.br ^bb42(%529 : i32)
    ^bb44:  // pred: ^bb42
      %530 = arith.addi %396, %c1_i32 : i32
      cf.br ^bb40(%530 : i32)
    ^bb45:  // pred: ^bb40
      %531 = arith.addi %394, %c1_i32 : i32
      cf.br ^bb38(%531 : i32)
    ^bb46:  // pred: ^bb38
      %532 = cute_nvgpu.atom.set_value(%392, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
      %533 = builtin.unrealized_conversion_cast %532 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
      %534 = arith.addi %389, %c1_i32 : i32
      cf.br ^bb36(%534, %533 : i32, !llvm.struct<(i1)>)
    ^bb47:  // pred: ^bb36
      %535 = builtin.unrealized_conversion_cast %390 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
      nvvm.wgmma.commit.group.sync.aligned
      %536 = arith.cmpi sgt, %340, %c1_i32 : i32
      cf.cond_br %536, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %int_tuple_125 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
      %ptr_126 = cute.add_offset(%iter, %int_tuple_125) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %537 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %538 = nvvm.mbarrier.wait.parity %537, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb50(%538 : i1)
    ^bb49:  // pred: ^bb47
      cf.br ^bb50(%true : i1)
    ^bb50(%539: i1):  // 2 preds: ^bb48, ^bb49
      cf.br ^bb51
    ^bb51:  // pred: ^bb50
      %iter_127 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %540 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %541 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      %542 = cute_nvgpu.atom.get_value(%535 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
      %543 = arith.extui %180 : i1 to i32
      cf.br ^bb52(%c1_i32, %539, %c1_i32, %c1_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %375, %376, %377 : i32, i1, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb52(%544: i32, %545: i1, %546: i32, %547: i32, %548: i32, %549: i32, %550: i32, %551: i32, %552: i32, %553: i32, %554: i32):  // 2 preds: ^bb51, ^bb97
      %555 = arith.cmpi slt, %544, %340 : i32
      cf.cond_br %555, ^bb53, ^bb98 {loop_annotation = #loop_annotation}
    ^bb53:  // pred: ^bb52
      %556 = arith.extui %545 : i1 to i32
      %557 = arith.cmpi eq, %556, %c0_i32 : i32
      cf.cond_br %557, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %int_tuple_128 = cute.make_int_tuple(%547) : (i32) -> !cute.int_tuple<"?">
      %ptr_129 = cute.add_offset(%iter, %int_tuple_128) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %558 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %558, %548, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      nvvm.wgmma.fence.aligned
      cf.br ^bb56(%c0_i32 : i32)
    ^bb56(%559: i32):  // 2 preds: ^bb55, ^bb66
      %560 = arith.cmpi slt, %559, %c4_i32 : i32
      cf.cond_br %560, ^bb57, ^bb67 {loop_annotation = #loop_annotation2}
    ^bb57:  // pred: ^bb56
      %coord_130 = cute.make_coord(%559, %547) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_131 = cute.crd2idx(%coord_130, %142) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_132 = cute.add_offset(%gmmaSmemDesc, %idx_131) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_133 = cute.crd2idx(%coord_130, %141) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
      %tup_134 = cute.add_offset(%gmmaSmemDesc_87, %idx_133) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb58(%c0_i32 : i32)
    ^bb58(%561: i32):  // 2 preds: ^bb57, ^bb65
      %562 = arith.cmpi slt, %561, %540 : i32
      cf.cond_br %562, ^bb59, ^bb66 {llvm.loop_annotation = #loop_annotation1}
    ^bb59:  // pred: ^bb58
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%563: i32):  // 2 preds: ^bb59, ^bb64
      %564 = arith.cmpi slt, %563, %541 : i32
      cf.cond_br %564, ^bb61, ^bb65 {llvm.loop_annotation = #loop_annotation1}
    ^bb61:  // pred: ^bb60
      %coord_135 = cute.make_coord(%563, %561) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_136 = cute.crd2idx(%coord_135, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
      %tup_137 = cute.add_offset(%tup_132, %idx_136) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%565: i32):  // 2 preds: ^bb61, ^bb63
      %566 = arith.cmpi slt, %565, %540 : i32
      cf.cond_br %566, ^bb63, ^bb64 {llvm.loop_annotation = #loop_annotation1}
    ^bb63:  // pred: ^bb62
      %coord_138 = cute.make_coord(%563, %565) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_139 = cute.crd2idx(%coord_138, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
      %ptr_140 = cute.add_offset(%iter_127, %idx_139) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
      %567 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %568 = llvm.load %567 : !llvm.ptr -> f32
      %569 = llvm.getelementptr %567[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %570 = llvm.load %569 : !llvm.ptr -> f32
      %571 = llvm.getelementptr %567[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %572 = llvm.load %571 : !llvm.ptr -> f32
      %573 = llvm.getelementptr %567[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %574 = llvm.load %573 : !llvm.ptr -> f32
      %575 = llvm.getelementptr %567[4] : (!llvm.ptr) -> !llvm.ptr, f32
      %576 = llvm.load %575 : !llvm.ptr -> f32
      %577 = llvm.getelementptr %567[5] : (!llvm.ptr) -> !llvm.ptr, f32
      %578 = llvm.load %577 : !llvm.ptr -> f32
      %579 = llvm.getelementptr %567[6] : (!llvm.ptr) -> !llvm.ptr, f32
      %580 = llvm.load %579 : !llvm.ptr -> f32
      %581 = llvm.getelementptr %567[7] : (!llvm.ptr) -> !llvm.ptr, f32
      %582 = llvm.load %581 : !llvm.ptr -> f32
      %583 = llvm.getelementptr %567[8] : (!llvm.ptr) -> !llvm.ptr, f32
      %584 = llvm.load %583 : !llvm.ptr -> f32
      %585 = llvm.getelementptr %567[9] : (!llvm.ptr) -> !llvm.ptr, f32
      %586 = llvm.load %585 : !llvm.ptr -> f32
      %587 = llvm.getelementptr %567[10] : (!llvm.ptr) -> !llvm.ptr, f32
      %588 = llvm.load %587 : !llvm.ptr -> f32
      %589 = llvm.getelementptr %567[11] : (!llvm.ptr) -> !llvm.ptr, f32
      %590 = llvm.load %589 : !llvm.ptr -> f32
      %591 = llvm.getelementptr %567[12] : (!llvm.ptr) -> !llvm.ptr, f32
      %592 = llvm.load %591 : !llvm.ptr -> f32
      %593 = llvm.getelementptr %567[13] : (!llvm.ptr) -> !llvm.ptr, f32
      %594 = llvm.load %593 : !llvm.ptr -> f32
      %595 = llvm.getelementptr %567[14] : (!llvm.ptr) -> !llvm.ptr, f32
      %596 = llvm.load %595 : !llvm.ptr -> f32
      %597 = llvm.getelementptr %567[15] : (!llvm.ptr) -> !llvm.ptr, f32
      %598 = llvm.load %597 : !llvm.ptr -> f32
      %599 = llvm.getelementptr %567[16] : (!llvm.ptr) -> !llvm.ptr, f32
      %600 = llvm.load %599 : !llvm.ptr -> f32
      %601 = llvm.getelementptr %567[17] : (!llvm.ptr) -> !llvm.ptr, f32
      %602 = llvm.load %601 : !llvm.ptr -> f32
      %603 = llvm.getelementptr %567[18] : (!llvm.ptr) -> !llvm.ptr, f32
      %604 = llvm.load %603 : !llvm.ptr -> f32
      %605 = llvm.getelementptr %567[19] : (!llvm.ptr) -> !llvm.ptr, f32
      %606 = llvm.load %605 : !llvm.ptr -> f32
      %607 = llvm.getelementptr %567[20] : (!llvm.ptr) -> !llvm.ptr, f32
      %608 = llvm.load %607 : !llvm.ptr -> f32
      %609 = llvm.getelementptr %567[21] : (!llvm.ptr) -> !llvm.ptr, f32
      %610 = llvm.load %609 : !llvm.ptr -> f32
      %611 = llvm.getelementptr %567[22] : (!llvm.ptr) -> !llvm.ptr, f32
      %612 = llvm.load %611 : !llvm.ptr -> f32
      %613 = llvm.getelementptr %567[23] : (!llvm.ptr) -> !llvm.ptr, f32
      %614 = llvm.load %613 : !llvm.ptr -> f32
      %615 = llvm.getelementptr %567[24] : (!llvm.ptr) -> !llvm.ptr, f32
      %616 = llvm.load %615 : !llvm.ptr -> f32
      %617 = llvm.getelementptr %567[25] : (!llvm.ptr) -> !llvm.ptr, f32
      %618 = llvm.load %617 : !llvm.ptr -> f32
      %619 = llvm.getelementptr %567[26] : (!llvm.ptr) -> !llvm.ptr, f32
      %620 = llvm.load %619 : !llvm.ptr -> f32
      %621 = llvm.getelementptr %567[27] : (!llvm.ptr) -> !llvm.ptr, f32
      %622 = llvm.load %621 : !llvm.ptr -> f32
      %623 = llvm.getelementptr %567[28] : (!llvm.ptr) -> !llvm.ptr, f32
      %624 = llvm.load %623 : !llvm.ptr -> f32
      %625 = llvm.getelementptr %567[29] : (!llvm.ptr) -> !llvm.ptr, f32
      %626 = llvm.load %625 : !llvm.ptr -> f32
      %627 = llvm.getelementptr %567[30] : (!llvm.ptr) -> !llvm.ptr, f32
      %628 = llvm.load %627 : !llvm.ptr -> f32
      %629 = llvm.getelementptr %567[31] : (!llvm.ptr) -> !llvm.ptr, f32
      %630 = llvm.load %629 : !llvm.ptr -> f32
      %631 = llvm.getelementptr %567[32] : (!llvm.ptr) -> !llvm.ptr, f32
      %632 = llvm.load %631 : !llvm.ptr -> f32
      %633 = llvm.getelementptr %567[33] : (!llvm.ptr) -> !llvm.ptr, f32
      %634 = llvm.load %633 : !llvm.ptr -> f32
      %635 = llvm.getelementptr %567[34] : (!llvm.ptr) -> !llvm.ptr, f32
      %636 = llvm.load %635 : !llvm.ptr -> f32
      %637 = llvm.getelementptr %567[35] : (!llvm.ptr) -> !llvm.ptr, f32
      %638 = llvm.load %637 : !llvm.ptr -> f32
      %639 = llvm.getelementptr %567[36] : (!llvm.ptr) -> !llvm.ptr, f32
      %640 = llvm.load %639 : !llvm.ptr -> f32
      %641 = llvm.getelementptr %567[37] : (!llvm.ptr) -> !llvm.ptr, f32
      %642 = llvm.load %641 : !llvm.ptr -> f32
      %643 = llvm.getelementptr %567[38] : (!llvm.ptr) -> !llvm.ptr, f32
      %644 = llvm.load %643 : !llvm.ptr -> f32
      %645 = llvm.getelementptr %567[39] : (!llvm.ptr) -> !llvm.ptr, f32
      %646 = llvm.load %645 : !llvm.ptr -> f32
      %647 = llvm.getelementptr %567[40] : (!llvm.ptr) -> !llvm.ptr, f32
      %648 = llvm.load %647 : !llvm.ptr -> f32
      %649 = llvm.getelementptr %567[41] : (!llvm.ptr) -> !llvm.ptr, f32
      %650 = llvm.load %649 : !llvm.ptr -> f32
      %651 = llvm.getelementptr %567[42] : (!llvm.ptr) -> !llvm.ptr, f32
      %652 = llvm.load %651 : !llvm.ptr -> f32
      %653 = llvm.getelementptr %567[43] : (!llvm.ptr) -> !llvm.ptr, f32
      %654 = llvm.load %653 : !llvm.ptr -> f32
      %655 = llvm.getelementptr %567[44] : (!llvm.ptr) -> !llvm.ptr, f32
      %656 = llvm.load %655 : !llvm.ptr -> f32
      %657 = llvm.getelementptr %567[45] : (!llvm.ptr) -> !llvm.ptr, f32
      %658 = llvm.load %657 : !llvm.ptr -> f32
      %659 = llvm.getelementptr %567[46] : (!llvm.ptr) -> !llvm.ptr, f32
      %660 = llvm.load %659 : !llvm.ptr -> f32
      %661 = llvm.getelementptr %567[47] : (!llvm.ptr) -> !llvm.ptr, f32
      %662 = llvm.load %661 : !llvm.ptr -> f32
      %663 = llvm.getelementptr %567[48] : (!llvm.ptr) -> !llvm.ptr, f32
      %664 = llvm.load %663 : !llvm.ptr -> f32
      %665 = llvm.getelementptr %567[49] : (!llvm.ptr) -> !llvm.ptr, f32
      %666 = llvm.load %665 : !llvm.ptr -> f32
      %667 = llvm.getelementptr %567[50] : (!llvm.ptr) -> !llvm.ptr, f32
      %668 = llvm.load %667 : !llvm.ptr -> f32
      %669 = llvm.getelementptr %567[51] : (!llvm.ptr) -> !llvm.ptr, f32
      %670 = llvm.load %669 : !llvm.ptr -> f32
      %671 = llvm.getelementptr %567[52] : (!llvm.ptr) -> !llvm.ptr, f32
      %672 = llvm.load %671 : !llvm.ptr -> f32
      %673 = llvm.getelementptr %567[53] : (!llvm.ptr) -> !llvm.ptr, f32
      %674 = llvm.load %673 : !llvm.ptr -> f32
      %675 = llvm.getelementptr %567[54] : (!llvm.ptr) -> !llvm.ptr, f32
      %676 = llvm.load %675 : !llvm.ptr -> f32
      %677 = llvm.getelementptr %567[55] : (!llvm.ptr) -> !llvm.ptr, f32
      %678 = llvm.load %677 : !llvm.ptr -> f32
      %679 = llvm.getelementptr %567[56] : (!llvm.ptr) -> !llvm.ptr, f32
      %680 = llvm.load %679 : !llvm.ptr -> f32
      %681 = llvm.getelementptr %567[57] : (!llvm.ptr) -> !llvm.ptr, f32
      %682 = llvm.load %681 : !llvm.ptr -> f32
      %683 = llvm.getelementptr %567[58] : (!llvm.ptr) -> !llvm.ptr, f32
      %684 = llvm.load %683 : !llvm.ptr -> f32
      %685 = llvm.getelementptr %567[59] : (!llvm.ptr) -> !llvm.ptr, f32
      %686 = llvm.load %685 : !llvm.ptr -> f32
      %687 = llvm.getelementptr %567[60] : (!llvm.ptr) -> !llvm.ptr, f32
      %688 = llvm.load %687 : !llvm.ptr -> f32
      %689 = llvm.getelementptr %567[61] : (!llvm.ptr) -> !llvm.ptr, f32
      %690 = llvm.load %689 : !llvm.ptr -> f32
      %691 = llvm.getelementptr %567[62] : (!llvm.ptr) -> !llvm.ptr, f32
      %692 = llvm.load %691 : !llvm.ptr -> f32
      %693 = llvm.getelementptr %567[63] : (!llvm.ptr) -> !llvm.ptr, f32
      %694 = llvm.load %693 : !llvm.ptr -> f32
      %695:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_137 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_134 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%568, %570, %572, %574, %576, %578, %580, %582, %584, %586, %588, %590, %592, %594, %596, %598, %600, %602, %604, %606, %608, %610, %612, %614, %616, %618, %620, %622, %624, %626, %628, %630, %632, %634, %636, %638, %640, %642, %644, %646, %648, %650, %652, %654, %656, %658, %660, %662, %664, %666, %668, %670, %672, %674, %676, %678, %680, %682, %684, %686, %688, %690, %692, %694], accum = %542 : i1)
< {cd_type = f32, operandSegmentSizes = array<i32: 1, 1, 64, 1>}> :(!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, f32, i1) -> (f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32)
      llvm.store %695#0, %567 : f32, !llvm.ptr
      llvm.store %695#1, %569 : f32, !llvm.ptr
      llvm.store %695#2, %571 : f32, !llvm.ptr
      llvm.store %695#3, %573 : f32, !llvm.ptr
      llvm.store %695#4, %575 : f32, !llvm.ptr
      llvm.store %695#5, %577 : f32, !llvm.ptr
      llvm.store %695#6, %579 : f32, !llvm.ptr
      llvm.store %695#7, %581 : f32, !llvm.ptr
      llvm.store %695#8, %583 : f32, !llvm.ptr
      llvm.store %695#9, %585 : f32, !llvm.ptr
      llvm.store %695#10, %587 : f32, !llvm.ptr
      llvm.store %695#11, %589 : f32, !llvm.ptr
      llvm.store %695#12, %591 : f32, !llvm.ptr
      llvm.store %695#13, %593 : f32, !llvm.ptr
      llvm.store %695#14, %595 : f32, !llvm.ptr
      llvm.store %695#15, %597 : f32, !llvm.ptr
      llvm.store %695#16, %599 : f32, !llvm.ptr
      llvm.store %695#17, %601 : f32, !llvm.ptr
      llvm.store %695#18, %603 : f32, !llvm.ptr
      llvm.store %695#19, %605 : f32, !llvm.ptr
      llvm.store %695#20, %607 : f32, !llvm.ptr
      llvm.store %695#21, %609 : f32, !llvm.ptr
      llvm.store %695#22, %611 : f32, !llvm.ptr
      llvm.store %695#23, %613 : f32, !llvm.ptr
      llvm.store %695#24, %615 : f32, !llvm.ptr
      llvm.store %695#25, %617 : f32, !llvm.ptr
      llvm.store %695#26, %619 : f32, !llvm.ptr
      llvm.store %695#27, %621 : f32, !llvm.ptr
      llvm.store %695#28, %623 : f32, !llvm.ptr
      llvm.store %695#29, %625 : f32, !llvm.ptr
      llvm.store %695#30, %627 : f32, !llvm.ptr
      llvm.store %695#31, %629 : f32, !llvm.ptr
      llvm.store %695#32, %631 : f32, !llvm.ptr
      llvm.store %695#33, %633 : f32, !llvm.ptr
      llvm.store %695#34, %635 : f32, !llvm.ptr
      llvm.store %695#35, %637 : f32, !llvm.ptr
      llvm.store %695#36, %639 : f32, !llvm.ptr
      llvm.store %695#37, %641 : f32, !llvm.ptr
      llvm.store %695#38, %643 : f32, !llvm.ptr
      llvm.store %695#39, %645 : f32, !llvm.ptr
      llvm.store %695#40, %647 : f32, !llvm.ptr
      llvm.store %695#41, %649 : f32, !llvm.ptr
      llvm.store %695#42, %651 : f32, !llvm.ptr
      llvm.store %695#43, %653 : f32, !llvm.ptr
      llvm.store %695#44, %655 : f32, !llvm.ptr
      llvm.store %695#45, %657 : f32, !llvm.ptr
      llvm.store %695#46, %659 : f32, !llvm.ptr
      llvm.store %695#47, %661 : f32, !llvm.ptr
      llvm.store %695#48, %663 : f32, !llvm.ptr
      llvm.store %695#49, %665 : f32, !llvm.ptr
      llvm.store %695#50, %667 : f32, !llvm.ptr
      llvm.store %695#51, %669 : f32, !llvm.ptr
      llvm.store %695#52, %671 : f32, !llvm.ptr
      llvm.store %695#53, %673 : f32, !llvm.ptr
      llvm.store %695#54, %675 : f32, !llvm.ptr
      llvm.store %695#55, %677 : f32, !llvm.ptr
      llvm.store %695#56, %679 : f32, !llvm.ptr
      llvm.store %695#57, %681 : f32, !llvm.ptr
      llvm.store %695#58, %683 : f32, !llvm.ptr
      llvm.store %695#59, %685 : f32, !llvm.ptr
      llvm.store %695#60, %687 : f32, !llvm.ptr
      llvm.store %695#61, %689 : f32, !llvm.ptr
      llvm.store %695#62, %691 : f32, !llvm.ptr
      llvm.store %695#63, %693 : f32, !llvm.ptr
      %696 = arith.addi %565, %c1_i32 : i32
      cf.br ^bb62(%696 : i32)
    ^bb64:  // pred: ^bb62
      %697 = arith.addi %563, %c1_i32 : i32
      cf.br ^bb60(%697 : i32)
    ^bb65:  // pred: ^bb60
      %698 = arith.addi %561, %c1_i32 : i32
      cf.br ^bb58(%698 : i32)
    ^bb66:  // pred: ^bb58
      %699 = arith.addi %559, %c1_i32 : i32
      cf.br ^bb56(%699 : i32)
    ^bb67:  // pred: ^bb56
      nvvm.wgmma.commit.group.sync.aligned
      nvvm.wgmma.wait.group.sync.aligned 1
      cf.cond_br %233, ^bb68, ^bb69
    ^bb68:  // pred: ^bb67
      %int_tuple_141 = cute.make_int_tuple(%550) : (i32) -> !cute.int_tuple<"?">
      %ptr_142 = cute.add_offset(%ptr_22, %int_tuple_141) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %700 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %700, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %701 = arith.addi %547, %c1_i32 : i32
      %702 = arith.addi %546, %c1_i32 : i32
      %703 = arith.cmpi eq, %701, %c7_i32 : i32
      %704 = arith.select %703, %c0_i32, %701 : i32
      cf.cond_br %703, ^bb70, ^bb71
    ^bb70:  // pred: ^bb69
      %705 = arith.xori %548, %c1_i32 : i32
      cf.br ^bb72(%705 : i32)
    ^bb71:  // pred: ^bb69
      cf.br ^bb72(%548 : i32)
    ^bb72(%706: i32):  // 2 preds: ^bb70, ^bb71
      cf.br ^bb73
    ^bb73:  // pred: ^bb72
      %707 = arith.addi %550, %c1_i32 : i32
      %708 = arith.addi %549, %c1_i32 : i32
      %709 = arith.cmpi eq, %707, %c7_i32 : i32
      %710 = arith.select %709, %c0_i32, %707 : i32
      cf.cond_br %709, ^bb74, ^bb75
    ^bb74:  // pred: ^bb73
      %711 = arith.xori %551, %c1_i32 : i32
      cf.br ^bb76(%711 : i32)
    ^bb75:  // pred: ^bb73
      cf.br ^bb76(%551 : i32)
    ^bb76(%712: i32):  // 2 preds: ^bb74, ^bb75
      cf.br ^bb77
    ^bb77:  // pred: ^bb76
      %713 = arith.cmpi sgt, %340, %702 : i32
      cf.cond_br %713, ^bb78, ^bb79
    ^bb78:  // pred: ^bb77
      %int_tuple_143 = cute.make_int_tuple(%704) : (i32) -> !cute.int_tuple<"?">
      %ptr_144 = cute.add_offset(%iter, %int_tuple_143) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %714 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %715 = nvvm.mbarrier.wait.parity %714, %706 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb80(%715 : i1)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%true : i1)
    ^bb80(%716: i1):  // 2 preds: ^bb78, ^bb79
      cf.br ^bb81
    ^bb81:  // pred: ^bb80
      %717 = arith.cmpi sgt, %340, %552 : i32
      %718 = arith.extui %717 : i1 to i32
      %719 = arith.select %180, %718, %543 : i32
      %720 = arith.cmpi ne, %719, %c0_i32 : i32
      cf.cond_br %720, ^bb82, ^bb95
    ^bb82:  // pred: ^bb81
      %int_tuple_145 = cute.make_int_tuple(%553) : (i32) -> !cute.int_tuple<"?">
      %ptr_146 = cute.add_offset(%ptr_22, %int_tuple_145) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %721 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %721, %554, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %722 = nvvm.elect.sync -> i1
      cf.cond_br %722, ^bb83, ^bb84
    ^bb83:  // pred: ^bb82
      %ptr_147 = cute.add_offset(%iter, %int_tuple_145) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %723 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %723, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      %coord_148 = cute.make_coord(%552) : (i32) -> !cute.coord<"(_,?)">
      %idx_149 = cute.crd2idx(%coord_148, %lay_82) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_150 = cute.add_offset(%tup_52, %idx_149) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_151, %e1_152, %e2_153 = cute.get_leaves(%tup_150) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %coord_154 = cute.make_coord(%553) : (i32) -> !cute.coord<"(_,?)">
      %idx_155 = cute.crd2idx(%coord_154, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_156 = cute.add_offset(%iter_37, %idx_155) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_157 = cute.crd2idx(%coord_148, %lay_86) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_158 = cute.add_offset(%tup_66, %idx_157) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_159, %e1_160, %e2_161 = cute.get_leaves(%tup_158) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %ptr_162 = cute.add_offset(%iter_38, %idx_155) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_163 = cute.add_offset(%iter, %int_tuple_145) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_164 = cute.make_int_tuple(%e0_151, %e1_152, %e2_153) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %724 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %725 = cute_nvgpu.atom.set_value(%724, %ptr_163 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %726 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %727 = cute_nvgpu.atom.get_value(%725 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_165 = cute_nvgpu.get_tma_desc_addr(%725 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %728:3 = cute.get_scalars(%int_tuple_164) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%729: i32):  // 2 preds: ^bb84, ^bb86
      %730 = arith.cmpi slt, %729, %726 : i32
      cf.cond_br %730, ^bb86, ^bb87 {llvm.loop_annotation = #loop_annotation1}
    ^bb86:  // pred: ^bb85
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_165 : !cute.ptr<generic, align<64>>, %ptr_156 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %727 : !cute.ptr<smem, align<8>>, [%728#0, %728#1, %728#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %731 = arith.addi %729, %c1_i32 : i32
      cf.br ^bb85(%731 : i32)
    ^bb87:  // pred: ^bb85
      %int_tuple_166 = cute.make_int_tuple(%e0_159, %e1_160, %e2_161) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %732 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %733 = cute_nvgpu.atom.set_value(%732, %ptr_163 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %734 = cute_nvgpu.atom.get_value(%733 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_167 = cute_nvgpu.get_tma_desc_addr(%733 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %735:3 = cute.get_scalars(%int_tuple_166) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb88(%c0_i32 : i32)
    ^bb88(%736: i32):  // 2 preds: ^bb87, ^bb89
      %737 = arith.cmpi slt, %736, %726 : i32
      cf.cond_br %737, ^bb89, ^bb90 {llvm.loop_annotation = #loop_annotation1}
    ^bb89:  // pred: ^bb88
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_167 : !cute.ptr<generic, align<64>>, %ptr_162 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %734 : !cute.ptr<smem, align<8>>, [%735#0, %735#1, %735#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %738 = arith.addi %736, %c1_i32 : i32
      cf.br ^bb88(%738 : i32)
    ^bb90:  // pred: ^bb88
      %739 = arith.addi %553, %c1_i32 : i32
      %740 = arith.addi %552, %c1_i32 : i32
      %741 = arith.cmpi eq, %739, %c7_i32 : i32
      %742 = arith.select %741, %c0_i32, %739 : i32
      cf.cond_br %741, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %743 = arith.xori %554, %c1_i32 : i32
      cf.br ^bb93(%743 : i32)
    ^bb92:  // pred: ^bb90
      cf.br ^bb93(%554 : i32)
    ^bb93(%744: i32):  // 2 preds: ^bb91, ^bb92
      cf.br ^bb94
    ^bb94:  // pred: ^bb93
      cf.br ^bb96(%740, %742, %744 : i32, i32, i32)
    ^bb95:  // pred: ^bb81
      cf.br ^bb96(%552, %553, %554 : i32, i32, i32)
    ^bb96(%745: i32, %746: i32, %747: i32):  // 2 preds: ^bb94, ^bb95
      cf.br ^bb97
    ^bb97:  // pred: ^bb96
      %748 = arith.addi %544, %c1_i32 : i32
      cf.br ^bb52(%748, %716, %702, %704, %706, %708, %710, %712, %745, %746, %747 : i32, i1, i32, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb98:  // pred: ^bb52
      nvvm.wgmma.wait.group.sync.aligned 0
      nvvm.barrier
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>
      %749 = cute.make_tiled_copy(%atom) : !copy_stsm_4_
      %750 = cute.make_tiled_copy(%atom) : !copy_stsm_4_1
      %coord_168 = cute.make_coord(%160) : (i32) -> !cute.coord<"?">
      %751 = cute.get_scalars(%coord_168) <{only_dynamic}> : !cute.coord<"?">
      %752 = arith.divsi %751, %c8_i32 : i32
      %753 = arith.remsi %751, %c8_i32 : i32
      %754 = arith.muli %753, %c32_i32 : i32
      %755 = arith.divsi %752, %c2_i32 : i32
      %756 = arith.remsi %752, %c2_i32 : i32
      %757 = arith.muli %756, %c256_i32 : i32
      %758 = arith.addi %754, %757 : i32
      %759 = arith.divsi %755, %c2_i32 : i32
      %760 = arith.remsi %755, %c2_i32 : i32
      %761 = arith.muli %760, %c8_i32 : i32
      %762 = arith.addi %758, %761 : i32
      %763 = arith.muli %759, %c512_i32 : i32
      %764 = arith.addi %762, %763 : i32
      %iv = cute.assume(%764) : (i32) -> !cute.i32<divby 8>
      %int_tuple_169 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_170 = cute.add_offset(%iter_39, %int_tuple_169) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %iter_171 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %view = cute.make_view(%iter_171) : !memref_rmem_f32_1
      %rmem_172 = cute.memref.alloca() : !memref_rmem_f32_2
      %765 = cute.memref.load(%view, %139) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      cute.memref.store(%rmem_172, %139, %765) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %766 = cute.memref.load(%view, %138) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      cute.memref.store(%rmem_172, %138, %766) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %767 = cute.memref.load(%view, %137) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      cute.memref.store(%rmem_172, %137, %767) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %768 = cute.memref.load(%view, %136) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      cute.memref.store(%rmem_172, %136, %768) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %769 = cute.memref.load(%view, %135) : (!memref_rmem_f32_1, !cute.coord<"4">) -> f32
      cute.memref.store(%rmem_172, %135, %769) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %770 = cute.memref.load(%view, %134) : (!memref_rmem_f32_1, !cute.coord<"5">) -> f32
      cute.memref.store(%rmem_172, %134, %770) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %771 = cute.memref.load(%view, %133) : (!memref_rmem_f32_1, !cute.coord<"6">) -> f32
      cute.memref.store(%rmem_172, %133, %771) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %772 = cute.memref.load(%view, %132) : (!memref_rmem_f32_1, !cute.coord<"7">) -> f32
      cute.memref.store(%rmem_172, %132, %772) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %773 = cute.memref.load(%view, %131) : (!memref_rmem_f32_1, !cute.coord<"8">) -> f32
      cute.memref.store(%rmem_172, %131, %773) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %774 = cute.memref.load(%view, %130) : (!memref_rmem_f32_1, !cute.coord<"9">) -> f32
      cute.memref.store(%rmem_172, %130, %774) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %775 = cute.memref.load(%view, %129) : (!memref_rmem_f32_1, !cute.coord<"10">) -> f32
      cute.memref.store(%rmem_172, %129, %775) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %776 = cute.memref.load(%view, %128) : (!memref_rmem_f32_1, !cute.coord<"11">) -> f32
      cute.memref.store(%rmem_172, %128, %776) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %777 = cute.memref.load(%view, %127) : (!memref_rmem_f32_1, !cute.coord<"12">) -> f32
      cute.memref.store(%rmem_172, %127, %777) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %778 = cute.memref.load(%view, %126) : (!memref_rmem_f32_1, !cute.coord<"13">) -> f32
      cute.memref.store(%rmem_172, %126, %778) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %779 = cute.memref.load(%view, %125) : (!memref_rmem_f32_1, !cute.coord<"14">) -> f32
      cute.memref.store(%rmem_172, %125, %779) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %780 = cute.memref.load(%view, %124) : (!memref_rmem_f32_1, !cute.coord<"15">) -> f32
      cute.memref.store(%rmem_172, %124, %780) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_173 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_174 = cute.get_iter(%rmem_173) : !memref_rmem_f16_
      %781 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %782 = arith.truncf %781 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %782, %rmem_173, row_major : !memref_rmem_f16_
      %783 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      cf.br ^bb99(%c0_i32 : i32)
    ^bb99(%784: i32):  // 2 preds: ^bb98, ^bb100
      %785 = arith.cmpi slt, %784, %783 : i32
      cf.cond_br %785, ^bb100, ^bb101 {llvm.loop_annotation = #loop_annotation1}
    ^bb100:  // pred: ^bb99
      %coord_175 = cute.make_coord(%784) : (i32) -> !cute.coord<"(_,?)">
      %idx_176 = cute.crd2idx(%coord_175, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_177 = cute.add_offset(%iter_174, %idx_176) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_178 = cute.crd2idx(%coord_175, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_179 = cute.add_offset(%ptr_170, %idx_178) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %786 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %787 = llvm.load %786 : !llvm.ptr -> vector<4xi32>
      %swizzled = cute.apply_swizzle(%ptr_179) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled, %787) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %788 = arith.addi %784, %c1_i32 : i32
      cf.br ^bb99(%788 : i32)
    ^bb101:  // pred: ^bb99
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb102, ^bb106
    ^bb102:  // pred: ^bb101
      %e0_180, %e1_181, %e2_182 = cute.get_leaves(%tup_78) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %int_tuple_183 = cute.make_int_tuple(%e0_180, %e1_181, %e2_182) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %789 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %790 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_184 = cute_nvgpu.get_tma_desc_addr(%789 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %791:3 = cute.get_scalars(%int_tuple_183) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%792: i32):  // 2 preds: ^bb102, ^bb104
      %793 = arith.cmpi slt, %792, %790 : i32
      cf.cond_br %793, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation1}
    ^bb104:  // pred: ^bb103
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_184 : !cute.ptr<generic, align<64>>, %iter_39 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%791#0, %791#1, %791#2] : i32, i32, i32) mode = <tiled>
      %794 = arith.addi %792, %c1_i32 : i32
      cf.br ^bb103(%794 : i32)
    ^bb105:  // pred: ^bb103
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb101, ^bb105
      nvvm.barrier id = %c1_i32
      %795 = cute.memref.load(%view, %121) : (!memref_rmem_f32_1, !cute.coord<"16">) -> f32
      cute.memref.store(%rmem_172, %139, %795) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %796 = cute.memref.load(%view, %120) : (!memref_rmem_f32_1, !cute.coord<"17">) -> f32
      cute.memref.store(%rmem_172, %138, %796) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %797 = cute.memref.load(%view, %119) : (!memref_rmem_f32_1, !cute.coord<"18">) -> f32
      cute.memref.store(%rmem_172, %137, %797) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %798 = cute.memref.load(%view, %118) : (!memref_rmem_f32_1, !cute.coord<"19">) -> f32
      cute.memref.store(%rmem_172, %136, %798) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %799 = cute.memref.load(%view, %117) : (!memref_rmem_f32_1, !cute.coord<"20">) -> f32
      cute.memref.store(%rmem_172, %135, %799) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %800 = cute.memref.load(%view, %116) : (!memref_rmem_f32_1, !cute.coord<"21">) -> f32
      cute.memref.store(%rmem_172, %134, %800) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %801 = cute.memref.load(%view, %115) : (!memref_rmem_f32_1, !cute.coord<"22">) -> f32
      cute.memref.store(%rmem_172, %133, %801) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %802 = cute.memref.load(%view, %114) : (!memref_rmem_f32_1, !cute.coord<"23">) -> f32
      cute.memref.store(%rmem_172, %132, %802) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %803 = cute.memref.load(%view, %113) : (!memref_rmem_f32_1, !cute.coord<"24">) -> f32
      cute.memref.store(%rmem_172, %131, %803) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %804 = cute.memref.load(%view, %112) : (!memref_rmem_f32_1, !cute.coord<"25">) -> f32
      cute.memref.store(%rmem_172, %130, %804) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %805 = cute.memref.load(%view, %111) : (!memref_rmem_f32_1, !cute.coord<"26">) -> f32
      cute.memref.store(%rmem_172, %129, %805) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %806 = cute.memref.load(%view, %110) : (!memref_rmem_f32_1, !cute.coord<"27">) -> f32
      cute.memref.store(%rmem_172, %128, %806) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %807 = cute.memref.load(%view, %109) : (!memref_rmem_f32_1, !cute.coord<"28">) -> f32
      cute.memref.store(%rmem_172, %127, %807) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %808 = cute.memref.load(%view, %108) : (!memref_rmem_f32_1, !cute.coord<"29">) -> f32
      cute.memref.store(%rmem_172, %126, %808) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %809 = cute.memref.load(%view, %107) : (!memref_rmem_f32_1, !cute.coord<"30">) -> f32
      cute.memref.store(%rmem_172, %125, %809) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %810 = cute.memref.load(%view, %106) : (!memref_rmem_f32_1, !cute.coord<"31">) -> f32
      cute.memref.store(%rmem_172, %124, %810) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_185 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_186 = cute.get_iter(%rmem_185) : !memref_rmem_f16_
      %811 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %812 = arith.truncf %811 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %812, %rmem_185, row_major : !memref_rmem_f16_
      %ptr_187 = cute.add_offset(%ptr_170, %105) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb107(%c0_i32 : i32)
    ^bb107(%813: i32):  // 2 preds: ^bb106, ^bb108
      %814 = arith.cmpi slt, %813, %783 : i32
      cf.cond_br %814, ^bb108, ^bb109 {llvm.loop_annotation = #loop_annotation1}
    ^bb108:  // pred: ^bb107
      %coord_188 = cute.make_coord(%813) : (i32) -> !cute.coord<"(_,?)">
      %idx_189 = cute.crd2idx(%coord_188, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_190 = cute.add_offset(%iter_186, %idx_189) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_191 = cute.crd2idx(%coord_188, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_192 = cute.add_offset(%ptr_187, %idx_191) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %815 = builtin.unrealized_conversion_cast %ptr_190 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %816 = llvm.load %815 : !llvm.ptr -> vector<4xi32>
      %swizzled_193 = cute.apply_swizzle(%ptr_192) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_193, %816) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %817 = arith.addi %813, %c1_i32 : i32
      cf.br ^bb107(%817 : i32)
    ^bb109:  // pred: ^bb107
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb110, ^bb114
    ^bb110:  // pred: ^bb109
      %ptr_194 = cute.add_offset(%iter_39, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_195 = cute.add_offset(%tup_78, %104) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_196, %e1_197, %e2_198 = cute.get_leaves(%tup_195) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %int_tuple_199 = cute.make_int_tuple(%e0_196, %e1_197, %e2_198) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %818 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %819 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_200 = cute_nvgpu.get_tma_desc_addr(%818 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %820:3 = cute.get_scalars(%int_tuple_199) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%821: i32):  // 2 preds: ^bb110, ^bb112
      %822 = arith.cmpi slt, %821, %819 : i32
      cf.cond_br %822, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation1}
    ^bb112:  // pred: ^bb111
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_200 : !cute.ptr<generic, align<64>>, %ptr_194 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%820#0, %820#1, %820#2] : i32, i32, i32) mode = <tiled>
      %823 = arith.addi %821, %c1_i32 : i32
      cf.br ^bb111(%823 : i32)
    ^bb113:  // pred: ^bb111
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb109, ^bb113
      nvvm.barrier id = %c1_i32
      %824 = cute.memref.load(%view, %103) : (!memref_rmem_f32_1, !cute.coord<"32">) -> f32
      cute.memref.store(%rmem_172, %139, %824) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %825 = cute.memref.load(%view, %102) : (!memref_rmem_f32_1, !cute.coord<"33">) -> f32
      cute.memref.store(%rmem_172, %138, %825) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %826 = cute.memref.load(%view, %101) : (!memref_rmem_f32_1, !cute.coord<"34">) -> f32
      cute.memref.store(%rmem_172, %137, %826) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %827 = cute.memref.load(%view, %100) : (!memref_rmem_f32_1, !cute.coord<"35">) -> f32
      cute.memref.store(%rmem_172, %136, %827) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %828 = cute.memref.load(%view, %99) : (!memref_rmem_f32_1, !cute.coord<"36">) -> f32
      cute.memref.store(%rmem_172, %135, %828) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %829 = cute.memref.load(%view, %98) : (!memref_rmem_f32_1, !cute.coord<"37">) -> f32
      cute.memref.store(%rmem_172, %134, %829) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %830 = cute.memref.load(%view, %97) : (!memref_rmem_f32_1, !cute.coord<"38">) -> f32
      cute.memref.store(%rmem_172, %133, %830) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %831 = cute.memref.load(%view, %96) : (!memref_rmem_f32_1, !cute.coord<"39">) -> f32
      cute.memref.store(%rmem_172, %132, %831) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %832 = cute.memref.load(%view, %95) : (!memref_rmem_f32_1, !cute.coord<"40">) -> f32
      cute.memref.store(%rmem_172, %131, %832) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %833 = cute.memref.load(%view, %94) : (!memref_rmem_f32_1, !cute.coord<"41">) -> f32
      cute.memref.store(%rmem_172, %130, %833) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %834 = cute.memref.load(%view, %93) : (!memref_rmem_f32_1, !cute.coord<"42">) -> f32
      cute.memref.store(%rmem_172, %129, %834) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %835 = cute.memref.load(%view, %92) : (!memref_rmem_f32_1, !cute.coord<"43">) -> f32
      cute.memref.store(%rmem_172, %128, %835) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %836 = cute.memref.load(%view, %91) : (!memref_rmem_f32_1, !cute.coord<"44">) -> f32
      cute.memref.store(%rmem_172, %127, %836) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %837 = cute.memref.load(%view, %90) : (!memref_rmem_f32_1, !cute.coord<"45">) -> f32
      cute.memref.store(%rmem_172, %126, %837) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %838 = cute.memref.load(%view, %89) : (!memref_rmem_f32_1, !cute.coord<"46">) -> f32
      cute.memref.store(%rmem_172, %125, %838) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %839 = cute.memref.load(%view, %88) : (!memref_rmem_f32_1, !cute.coord<"47">) -> f32
      cute.memref.store(%rmem_172, %124, %839) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_201 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_202 = cute.get_iter(%rmem_201) : !memref_rmem_f16_
      %840 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %841 = arith.truncf %840 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %841, %rmem_201, row_major : !memref_rmem_f16_
      %ptr_203 = cute.add_offset(%ptr_170, %87) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%842: i32):  // 2 preds: ^bb114, ^bb116
      %843 = arith.cmpi slt, %842, %783 : i32
      cf.cond_br %843, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation1}
    ^bb116:  // pred: ^bb115
      %coord_204 = cute.make_coord(%842) : (i32) -> !cute.coord<"(_,?)">
      %idx_205 = cute.crd2idx(%coord_204, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_206 = cute.add_offset(%iter_202, %idx_205) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_207 = cute.crd2idx(%coord_204, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_208 = cute.add_offset(%ptr_203, %idx_207) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %844 = builtin.unrealized_conversion_cast %ptr_206 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %845 = llvm.load %844 : !llvm.ptr -> vector<4xi32>
      %swizzled_209 = cute.apply_swizzle(%ptr_208) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_209, %845) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %846 = arith.addi %842, %c1_i32 : i32
      cf.br ^bb115(%846 : i32)
    ^bb117:  // pred: ^bb115
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb118, ^bb122
    ^bb118:  // pred: ^bb117
      %ptr_210 = cute.add_offset(%iter_39, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_211 = cute.add_offset(%tup_78, %86) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %e0_212, %e1_213, %e2_214 = cute.get_leaves(%tup_211) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %int_tuple_215 = cute.make_int_tuple(%e0_212, %e1_213, %e2_214) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
      %847 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %848 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_216 = cute_nvgpu.get_tma_desc_addr(%847 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %849:3 = cute.get_scalars(%int_tuple_215) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
      cf.br ^bb119(%c0_i32 : i32)
    ^bb119(%850: i32):  // 2 preds: ^bb118, ^bb120
      %851 = arith.cmpi slt, %850, %848 : i32
      cf.cond_br %851, ^bb120, ^bb121 {llvm.loop_annotation = #loop_annotation1}
    ^bb120:  // pred: ^bb119
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_216 : !cute.ptr<generic, align<64>>, %ptr_210 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%849#0, %849#1, %849#2] : i32, i32, i32) mode = <tiled>
      %852 = arith.addi %850, %c1_i32 : i32
      cf.br ^bb119(%852 : i32)
    ^bb121:  // pred: ^bb119
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb122
    ^bb122:  // 2 preds: ^bb117, ^bb121
      nvvm.barrier id = %c1_i32
      %853 = cute.memref.load(%view, %85) : (!memref_rmem_f32_1, !cute.coord<"48">) -> f32
      cute.memref.store(%rmem_172, %139, %853) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %854 = cute.memref.load(%view, %84) : (!memref_rmem_f32_1, !cute.coord<"49">) -> f32
      cute.memref.store(%rmem_172, %138, %854) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %855 = cute.memref.load(%view, %83) : (!memref_rmem_f32_1, !cute.coord<"50">) -> f32
      cute.memref.store(%rmem_172, %137, %855) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %856 = cute.memref.load(%view, %82) : (!memref_rmem_f32_1, !cute.coord<"51">) -> f32
      cute.memref.store(%rmem_172, %136, %856) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %857 = cute.memref.load(%view, %81) : (!memref_rmem_f32_1, !cute.coord<"52">) -> f32
      cute.memref.store(%rmem_172, %135, %857) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %858 = cute.memref.load(%view, %80) : (!memref_rmem_f32_1, !cute.coord<"53">) -> f32
      cute.memref.store(%rmem_172, %134, %858) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %859 = cute.memref.load(%view, %79) : (!memref_rmem_f32_1, !cute.coord<"54">) -> f32
      cute.memref.store(%rmem_172, %133, %859) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %860 = cute.memref.load(%view, %78) : (!memref_rmem_f32_1, !cute.coord<"55">) -> f32
      cute.memref.store(%rmem_172, %132, %860) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %861 = cute.memref.load(%view, %77) : (!memref_rmem_f32_1, !cute.coord<"56">) -> f32
      cute.memref.store(%rmem_172, %131, %861) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %862 = cute.memref.load(%view, %76) : (!memref_rmem_f32_1, !cute.coord<"57">) -> f32
      cute.memref.store(%rmem_172, %130, %862) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %863 = cute.memref.load(%view, %75) : (!memref_rmem_f32_1, !cute.coord<"58">) -> f32
      cute.memref.store(%rmem_172, %129, %863) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %864 = cute.memref.load(%view, %74) : (!memref_rmem_f32_1, !cute.coord<"59">) -> f32
      cute.memref.store(%rmem_172, %128, %864) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %865 = cute.memref.load(%view, %73) : (!memref_rmem_f32_1, !cute.coord<"60">) -> f32
      cute.memref.store(%rmem_172, %127, %865) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %866 = cute.memref.load(%view, %72) : (!memref_rmem_f32_1, !cute.coord<"61">) -> f32
      cute.memref.store(%rmem_172, %126, %866) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %867 = cute.memref.load(%view, %71) : (!memref_rmem_f32_1, !cute.coord<"62">) -> f32
      cute.memref.store(%rmem_172, %125, %867) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %868 = cute.memref.load(%view, %70) : (!memref_rmem_f32_1, !cute.coord<"63">) -> f32
      cute.memref.store(%rmem_172, %124, %868) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_217 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_218 = cute.get_iter(%rmem_217) : !memref_rmem_f16_
      %869 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %870 = arith.truncf %869 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %870, %rmem_217, row_major : !memref_rmem_f16_
      %ptr_219 = cute.add_offset(%ptr_170, %69) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cf.br ^bb123(%c0_i32 : i32)
    ^bb123(%871: i32):  // 2 preds: ^bb122, ^bb124
      %872 = arith.cmpi slt, %871, %783 : i32
      cf.cond_br %872, ^bb124, ^bb125 {llvm.loop_annotation = #loop_annotation1}
    ^bb124:  // pred: ^bb123
      %coord_220 = cute.make_coord(%871) : (i32) -> !cute.coord<"(_,?)">
      %idx_221 = cute.crd2idx(%coord_220, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_222 = cute.add_offset(%iter_218, %idx_221) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_223 = cute.crd2idx(%coord_220, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_224 = cute.add_offset(%ptr_219, %idx_223) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %873 = builtin.unrealized_conversion_cast %ptr_222 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %874 = llvm.load %873 : !llvm.ptr -> vector<4xi32>
      %swizzled_225 = cute.apply_swizzle(%ptr_224) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_225, %874) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %875 = arith.addi %871, %c1_i32 : i32
      cf.br ^bb123(%875 : i32)
    ^bb125:  // pred: ^bb123
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb126, ^bb130
    ^bb126:  // pred: ^bb125
      %ptr_226 = cute.add_offset(%iter_39, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_227 = cute.add_offset(%tup_78, %68) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_228, %e1_229, %e2_230 = cute.get_leaves(%tup_227) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %int_tuple_231 = cute.make_int_tuple(%e0_228, %e1_229, %e2_230) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %876 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %877 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_232 = cute_nvgpu.get_tma_desc_addr(%876 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %878:3 = cute.get_scalars(%int_tuple_231) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb127(%c0_i32 : i32)
    ^bb127(%879: i32):  // 2 preds: ^bb126, ^bb128
      %880 = arith.cmpi slt, %879, %877 : i32
      cf.cond_br %880, ^bb128, ^bb129 {llvm.loop_annotation = #loop_annotation1}
    ^bb128:  // pred: ^bb127
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_232 : !cute.ptr<generic, align<64>>, %ptr_226 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%878#0, %878#1, %878#2] : i32, i32, i32) mode = <tiled>
      %881 = arith.addi %879, %c1_i32 : i32
      cf.br ^bb127(%881 : i32)
    ^bb129:  // pred: ^bb127
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb130
    ^bb130:  // 2 preds: ^bb125, ^bb129
      nvvm.barrier id = %c1_i32
      %882 = cute.memref.load(%view, %67) : (!memref_rmem_f32_1, !cute.coord<"64">) -> f32
      cute.memref.store(%rmem_172, %139, %882) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %883 = cute.memref.load(%view, %66) : (!memref_rmem_f32_1, !cute.coord<"65">) -> f32
      cute.memref.store(%rmem_172, %138, %883) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %884 = cute.memref.load(%view, %65) : (!memref_rmem_f32_1, !cute.coord<"66">) -> f32
      cute.memref.store(%rmem_172, %137, %884) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %885 = cute.memref.load(%view, %64) : (!memref_rmem_f32_1, !cute.coord<"67">) -> f32
      cute.memref.store(%rmem_172, %136, %885) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %886 = cute.memref.load(%view, %63) : (!memref_rmem_f32_1, !cute.coord<"68">) -> f32
      cute.memref.store(%rmem_172, %135, %886) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %887 = cute.memref.load(%view, %62) : (!memref_rmem_f32_1, !cute.coord<"69">) -> f32
      cute.memref.store(%rmem_172, %134, %887) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %888 = cute.memref.load(%view, %61) : (!memref_rmem_f32_1, !cute.coord<"70">) -> f32
      cute.memref.store(%rmem_172, %133, %888) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %889 = cute.memref.load(%view, %60) : (!memref_rmem_f32_1, !cute.coord<"71">) -> f32
      cute.memref.store(%rmem_172, %132, %889) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %890 = cute.memref.load(%view, %59) : (!memref_rmem_f32_1, !cute.coord<"72">) -> f32
      cute.memref.store(%rmem_172, %131, %890) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %891 = cute.memref.load(%view, %58) : (!memref_rmem_f32_1, !cute.coord<"73">) -> f32
      cute.memref.store(%rmem_172, %130, %891) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %892 = cute.memref.load(%view, %57) : (!memref_rmem_f32_1, !cute.coord<"74">) -> f32
      cute.memref.store(%rmem_172, %129, %892) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %893 = cute.memref.load(%view, %56) : (!memref_rmem_f32_1, !cute.coord<"75">) -> f32
      cute.memref.store(%rmem_172, %128, %893) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %894 = cute.memref.load(%view, %55) : (!memref_rmem_f32_1, !cute.coord<"76">) -> f32
      cute.memref.store(%rmem_172, %127, %894) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %895 = cute.memref.load(%view, %54) : (!memref_rmem_f32_1, !cute.coord<"77">) -> f32
      cute.memref.store(%rmem_172, %126, %895) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %896 = cute.memref.load(%view, %53) : (!memref_rmem_f32_1, !cute.coord<"78">) -> f32
      cute.memref.store(%rmem_172, %125, %896) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %897 = cute.memref.load(%view, %52) : (!memref_rmem_f32_1, !cute.coord<"79">) -> f32
      cute.memref.store(%rmem_172, %124, %897) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_233 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_234 = cute.get_iter(%rmem_233) : !memref_rmem_f16_
      %898 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %899 = arith.truncf %898 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %899, %rmem_233, row_major : !memref_rmem_f16_
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%900: i32):  // 2 preds: ^bb130, ^bb132
      %901 = arith.cmpi slt, %900, %783 : i32
      cf.cond_br %901, ^bb132, ^bb133 {llvm.loop_annotation = #loop_annotation1}
    ^bb132:  // pred: ^bb131
      %coord_235 = cute.make_coord(%900) : (i32) -> !cute.coord<"(_,?)">
      %idx_236 = cute.crd2idx(%coord_235, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_237 = cute.add_offset(%iter_234, %idx_236) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_238 = cute.crd2idx(%coord_235, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_239 = cute.add_offset(%ptr_170, %idx_238) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %902 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %903 = llvm.load %902 : !llvm.ptr -> vector<4xi32>
      %swizzled_240 = cute.apply_swizzle(%ptr_239) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_240, %903) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %904 = arith.addi %900, %c1_i32 : i32
      cf.br ^bb131(%904 : i32)
    ^bb133:  // pred: ^bb131
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb134, ^bb138
    ^bb134:  // pred: ^bb133
      %tup_241 = cute.add_offset(%tup_78, %51) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(0,64)">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %e0_242, %e1_243, %e2_244 = cute.get_leaves(%tup_241) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %int_tuple_245 = cute.make_int_tuple(%e0_242, %e1_243, %e2_244) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
      %905 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %906 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_246 = cute_nvgpu.get_tma_desc_addr(%905 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %907:3 = cute.get_scalars(%int_tuple_245) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%908: i32):  // 2 preds: ^bb134, ^bb136
      %909 = arith.cmpi slt, %908, %906 : i32
      cf.cond_br %909, ^bb136, ^bb137 {llvm.loop_annotation = #loop_annotation1}
    ^bb136:  // pred: ^bb135
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_246 : !cute.ptr<generic, align<64>>, %iter_39 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%907#0, %907#1, %907#2] : i32, i32, i32) mode = <tiled>
      %910 = arith.addi %908, %c1_i32 : i32
      cf.br ^bb135(%910 : i32)
    ^bb137:  // pred: ^bb135
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb138
    ^bb138:  // 2 preds: ^bb133, ^bb137
      nvvm.barrier id = %c1_i32
      %911 = cute.memref.load(%view, %50) : (!memref_rmem_f32_1, !cute.coord<"80">) -> f32
      cute.memref.store(%rmem_172, %139, %911) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %912 = cute.memref.load(%view, %49) : (!memref_rmem_f32_1, !cute.coord<"81">) -> f32
      cute.memref.store(%rmem_172, %138, %912) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %913 = cute.memref.load(%view, %48) : (!memref_rmem_f32_1, !cute.coord<"82">) -> f32
      cute.memref.store(%rmem_172, %137, %913) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %914 = cute.memref.load(%view, %47) : (!memref_rmem_f32_1, !cute.coord<"83">) -> f32
      cute.memref.store(%rmem_172, %136, %914) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %915 = cute.memref.load(%view, %46) : (!memref_rmem_f32_1, !cute.coord<"84">) -> f32
      cute.memref.store(%rmem_172, %135, %915) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %916 = cute.memref.load(%view, %45) : (!memref_rmem_f32_1, !cute.coord<"85">) -> f32
      cute.memref.store(%rmem_172, %134, %916) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %917 = cute.memref.load(%view, %44) : (!memref_rmem_f32_1, !cute.coord<"86">) -> f32
      cute.memref.store(%rmem_172, %133, %917) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %918 = cute.memref.load(%view, %43) : (!memref_rmem_f32_1, !cute.coord<"87">) -> f32
      cute.memref.store(%rmem_172, %132, %918) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %919 = cute.memref.load(%view, %42) : (!memref_rmem_f32_1, !cute.coord<"88">) -> f32
      cute.memref.store(%rmem_172, %131, %919) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %920 = cute.memref.load(%view, %41) : (!memref_rmem_f32_1, !cute.coord<"89">) -> f32
      cute.memref.store(%rmem_172, %130, %920) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %921 = cute.memref.load(%view, %40) : (!memref_rmem_f32_1, !cute.coord<"90">) -> f32
      cute.memref.store(%rmem_172, %129, %921) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %922 = cute.memref.load(%view, %39) : (!memref_rmem_f32_1, !cute.coord<"91">) -> f32
      cute.memref.store(%rmem_172, %128, %922) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %923 = cute.memref.load(%view, %38) : (!memref_rmem_f32_1, !cute.coord<"92">) -> f32
      cute.memref.store(%rmem_172, %127, %923) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %924 = cute.memref.load(%view, %37) : (!memref_rmem_f32_1, !cute.coord<"93">) -> f32
      cute.memref.store(%rmem_172, %126, %924) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %925 = cute.memref.load(%view, %36) : (!memref_rmem_f32_1, !cute.coord<"94">) -> f32
      cute.memref.store(%rmem_172, %125, %925) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %926 = cute.memref.load(%view, %35) : (!memref_rmem_f32_1, !cute.coord<"95">) -> f32
      cute.memref.store(%rmem_172, %124, %926) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_247 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_248 = cute.get_iter(%rmem_247) : !memref_rmem_f16_
      %927 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %928 = arith.truncf %927 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %928, %rmem_247, row_major : !memref_rmem_f16_
      cf.br ^bb139(%c0_i32 : i32)
    ^bb139(%929: i32):  // 2 preds: ^bb138, ^bb140
      %930 = arith.cmpi slt, %929, %783 : i32
      cf.cond_br %930, ^bb140, ^bb141 {llvm.loop_annotation = #loop_annotation1}
    ^bb140:  // pred: ^bb139
      %coord_249 = cute.make_coord(%929) : (i32) -> !cute.coord<"(_,?)">
      %idx_250 = cute.crd2idx(%coord_249, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_251 = cute.add_offset(%iter_248, %idx_250) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_252 = cute.crd2idx(%coord_249, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_253 = cute.add_offset(%ptr_187, %idx_252) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %931 = builtin.unrealized_conversion_cast %ptr_251 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %932 = llvm.load %931 : !llvm.ptr -> vector<4xi32>
      %swizzled_254 = cute.apply_swizzle(%ptr_253) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_254, %932) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %933 = arith.addi %929, %c1_i32 : i32
      cf.br ^bb139(%933 : i32)
    ^bb141:  // pred: ^bb139
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb142, ^bb146
    ^bb142:  // pred: ^bb141
      %ptr_255 = cute.add_offset(%iter_39, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_256 = cute.add_offset(%tup_78, %34) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %e0_257, %e1_258, %e2_259 = cute.get_leaves(%tup_256) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %int_tuple_260 = cute.make_int_tuple(%e0_257, %e1_258, %e2_259) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %934 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %935 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_261 = cute_nvgpu.get_tma_desc_addr(%934 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %936:3 = cute.get_scalars(%int_tuple_260) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      cf.br ^bb143(%c0_i32 : i32)
    ^bb143(%937: i32):  // 2 preds: ^bb142, ^bb144
      %938 = arith.cmpi slt, %937, %935 : i32
      cf.cond_br %938, ^bb144, ^bb145 {llvm.loop_annotation = #loop_annotation1}
    ^bb144:  // pred: ^bb143
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_261 : !cute.ptr<generic, align<64>>, %ptr_255 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%936#0, %936#1, %936#2] : i32, i32, i32) mode = <tiled>
      %939 = arith.addi %937, %c1_i32 : i32
      cf.br ^bb143(%939 : i32)
    ^bb145:  // pred: ^bb143
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb146
    ^bb146:  // 2 preds: ^bb141, ^bb145
      nvvm.barrier id = %c1_i32
      %940 = cute.memref.load(%view, %33) : (!memref_rmem_f32_1, !cute.coord<"96">) -> f32
      cute.memref.store(%rmem_172, %139, %940) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %941 = cute.memref.load(%view, %32) : (!memref_rmem_f32_1, !cute.coord<"97">) -> f32
      cute.memref.store(%rmem_172, %138, %941) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %942 = cute.memref.load(%view, %31) : (!memref_rmem_f32_1, !cute.coord<"98">) -> f32
      cute.memref.store(%rmem_172, %137, %942) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %943 = cute.memref.load(%view, %30) : (!memref_rmem_f32_1, !cute.coord<"99">) -> f32
      cute.memref.store(%rmem_172, %136, %943) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %944 = cute.memref.load(%view, %29) : (!memref_rmem_f32_1, !cute.coord<"100">) -> f32
      cute.memref.store(%rmem_172, %135, %944) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %945 = cute.memref.load(%view, %28) : (!memref_rmem_f32_1, !cute.coord<"101">) -> f32
      cute.memref.store(%rmem_172, %134, %945) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %946 = cute.memref.load(%view, %27) : (!memref_rmem_f32_1, !cute.coord<"102">) -> f32
      cute.memref.store(%rmem_172, %133, %946) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %947 = cute.memref.load(%view, %26) : (!memref_rmem_f32_1, !cute.coord<"103">) -> f32
      cute.memref.store(%rmem_172, %132, %947) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %948 = cute.memref.load(%view, %25) : (!memref_rmem_f32_1, !cute.coord<"104">) -> f32
      cute.memref.store(%rmem_172, %131, %948) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %949 = cute.memref.load(%view, %24) : (!memref_rmem_f32_1, !cute.coord<"105">) -> f32
      cute.memref.store(%rmem_172, %130, %949) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %950 = cute.memref.load(%view, %23) : (!memref_rmem_f32_1, !cute.coord<"106">) -> f32
      cute.memref.store(%rmem_172, %129, %950) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %951 = cute.memref.load(%view, %22) : (!memref_rmem_f32_1, !cute.coord<"107">) -> f32
      cute.memref.store(%rmem_172, %128, %951) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %952 = cute.memref.load(%view, %21) : (!memref_rmem_f32_1, !cute.coord<"108">) -> f32
      cute.memref.store(%rmem_172, %127, %952) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %953 = cute.memref.load(%view, %20) : (!memref_rmem_f32_1, !cute.coord<"109">) -> f32
      cute.memref.store(%rmem_172, %126, %953) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %954 = cute.memref.load(%view, %19) : (!memref_rmem_f32_1, !cute.coord<"110">) -> f32
      cute.memref.store(%rmem_172, %125, %954) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %955 = cute.memref.load(%view, %18) : (!memref_rmem_f32_1, !cute.coord<"111">) -> f32
      cute.memref.store(%rmem_172, %124, %955) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_262 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_263 = cute.get_iter(%rmem_262) : !memref_rmem_f16_
      %956 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %957 = arith.truncf %956 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %957, %rmem_262, row_major : !memref_rmem_f16_
      cf.br ^bb147(%c0_i32 : i32)
    ^bb147(%958: i32):  // 2 preds: ^bb146, ^bb148
      %959 = arith.cmpi slt, %958, %783 : i32
      cf.cond_br %959, ^bb148, ^bb149 {llvm.loop_annotation = #loop_annotation1}
    ^bb148:  // pred: ^bb147
      %coord_264 = cute.make_coord(%958) : (i32) -> !cute.coord<"(_,?)">
      %idx_265 = cute.crd2idx(%coord_264, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_266 = cute.add_offset(%iter_263, %idx_265) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_267 = cute.crd2idx(%coord_264, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_268 = cute.add_offset(%ptr_203, %idx_267) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %960 = builtin.unrealized_conversion_cast %ptr_266 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %961 = llvm.load %960 : !llvm.ptr -> vector<4xi32>
      %swizzled_269 = cute.apply_swizzle(%ptr_268) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_269, %961) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %962 = arith.addi %958, %c1_i32 : i32
      cf.br ^bb147(%962 : i32)
    ^bb149:  // pred: ^bb147
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb150, ^bb154
    ^bb150:  // pred: ^bb149
      %ptr_270 = cute.add_offset(%iter_39, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_271 = cute.add_offset(%tup_78, %17) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,64)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_272, %e1_273, %e2_274 = cute.get_leaves(%tup_271) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %int_tuple_275 = cute.make_int_tuple(%e0_272, %e1_273, %e2_274) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %963 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %964 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_276 = cute_nvgpu.get_tma_desc_addr(%963 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %965:3 = cute.get_scalars(%int_tuple_275) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb151(%c0_i32 : i32)
    ^bb151(%966: i32):  // 2 preds: ^bb150, ^bb152
      %967 = arith.cmpi slt, %966, %964 : i32
      cf.cond_br %967, ^bb152, ^bb153 {llvm.loop_annotation = #loop_annotation1}
    ^bb152:  // pred: ^bb151
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_276 : !cute.ptr<generic, align<64>>, %ptr_270 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%965#0, %965#1, %965#2] : i32, i32, i32) mode = <tiled>
      %968 = arith.addi %966, %c1_i32 : i32
      cf.br ^bb151(%968 : i32)
    ^bb153:  // pred: ^bb151
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb149, ^bb153
      nvvm.barrier id = %c1_i32
      %969 = cute.memref.load(%view, %16) : (!memref_rmem_f32_1, !cute.coord<"112">) -> f32
      cute.memref.store(%rmem_172, %139, %969) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %970 = cute.memref.load(%view, %15) : (!memref_rmem_f32_1, !cute.coord<"113">) -> f32
      cute.memref.store(%rmem_172, %138, %970) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %971 = cute.memref.load(%view, %14) : (!memref_rmem_f32_1, !cute.coord<"114">) -> f32
      cute.memref.store(%rmem_172, %137, %971) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %972 = cute.memref.load(%view, %13) : (!memref_rmem_f32_1, !cute.coord<"115">) -> f32
      cute.memref.store(%rmem_172, %136, %972) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %973 = cute.memref.load(%view, %12) : (!memref_rmem_f32_1, !cute.coord<"116">) -> f32
      cute.memref.store(%rmem_172, %135, %973) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %974 = cute.memref.load(%view, %11) : (!memref_rmem_f32_1, !cute.coord<"117">) -> f32
      cute.memref.store(%rmem_172, %134, %974) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %975 = cute.memref.load(%view, %10) : (!memref_rmem_f32_1, !cute.coord<"118">) -> f32
      cute.memref.store(%rmem_172, %133, %975) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %976 = cute.memref.load(%view, %9) : (!memref_rmem_f32_1, !cute.coord<"119">) -> f32
      cute.memref.store(%rmem_172, %132, %976) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %977 = cute.memref.load(%view, %8) : (!memref_rmem_f32_1, !cute.coord<"120">) -> f32
      cute.memref.store(%rmem_172, %131, %977) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %978 = cute.memref.load(%view, %7) : (!memref_rmem_f32_1, !cute.coord<"121">) -> f32
      cute.memref.store(%rmem_172, %130, %978) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %979 = cute.memref.load(%view, %6) : (!memref_rmem_f32_1, !cute.coord<"122">) -> f32
      cute.memref.store(%rmem_172, %129, %979) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %980 = cute.memref.load(%view, %5) : (!memref_rmem_f32_1, !cute.coord<"123">) -> f32
      cute.memref.store(%rmem_172, %128, %980) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %981 = cute.memref.load(%view, %4) : (!memref_rmem_f32_1, !cute.coord<"124">) -> f32
      cute.memref.store(%rmem_172, %127, %981) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %982 = cute.memref.load(%view, %3) : (!memref_rmem_f32_1, !cute.coord<"125">) -> f32
      cute.memref.store(%rmem_172, %126, %982) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %983 = cute.memref.load(%view, %2) : (!memref_rmem_f32_1, !cute.coord<"126">) -> f32
      cute.memref.store(%rmem_172, %125, %983) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %984 = cute.memref.load(%view, %1) : (!memref_rmem_f32_1, !cute.coord<"127">) -> f32
      cute.memref.store(%rmem_172, %124, %984) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_277 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_278 = cute.get_iter(%rmem_277) : !memref_rmem_f16_
      %985 = cute.memref.load_vec %rmem_172, row_major : !memref_rmem_f32_2
      %986 = arith.truncf %985 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %986, %rmem_277, row_major : !memref_rmem_f16_
      cf.br ^bb155(%c0_i32 : i32)
    ^bb155(%987: i32):  // 2 preds: ^bb154, ^bb156
      %988 = arith.cmpi slt, %987, %783 : i32
      cf.cond_br %988, ^bb156, ^bb157 {llvm.loop_annotation = #loop_annotation1}
    ^bb156:  // pred: ^bb155
      %coord_279 = cute.make_coord(%987) : (i32) -> !cute.coord<"(_,?)">
      %idx_280 = cute.crd2idx(%coord_279, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_281 = cute.add_offset(%iter_278, %idx_280) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_282 = cute.crd2idx(%coord_279, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_283 = cute.add_offset(%ptr_219, %idx_282) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %989 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %990 = llvm.load %989 : !llvm.ptr -> vector<4xi32>
      %swizzled_284 = cute.apply_swizzle(%ptr_283) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_284, %990) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      %991 = arith.addi %987, %c1_i32 : i32
      cf.br ^bb155(%991 : i32)
    ^bb157:  // pred: ^bb155
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb158, ^bb162
    ^bb158:  // pred: ^bb157
      %ptr_285 = cute.add_offset(%iter_39, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %tup_286 = cute.add_offset(%tup_78, %0) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %e0_287, %e1_288, %e2_289 = cute.get_leaves(%tup_286) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %int_tuple_290 = cute.make_int_tuple(%e0_287, %e1_288, %e2_289) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
      %992 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
      %993 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %TMADescAddr_291 = cute_nvgpu.get_tma_desc_addr(%992 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %994:3 = cute.get_scalars(%int_tuple_290) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
      cf.br ^bb159(%c0_i32 : i32)
    ^bb159(%995: i32):  // 2 preds: ^bb158, ^bb160
      %996 = arith.cmpi slt, %995, %993 : i32
      cf.cond_br %996, ^bb160, ^bb161 {llvm.loop_annotation = #loop_annotation1}
    ^bb160:  // pred: ^bb159
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_291 : !cute.ptr<generic, align<64>>, %ptr_285 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%994#0, %994#1, %994#2] : i32, i32, i32) mode = <tiled>
      %997 = arith.addi %995, %c1_i32 : i32
      cf.br ^bb159(%997 : i32)
    ^bb161:  // pred: ^bb159
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb162
    ^bb162:  // 2 preds: ^bb157, ^bb161
      nvvm.barrier id = %c1_i32
      cf.cond_br %180, ^bb163, ^bb164
    ^bb163:  // pred: ^bb162
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb164
    ^bb164:  // 2 preds: ^bb162, ^bb163
      return
    }
  }
  func.func @cutlass___call_____main__HopperWgmmaGemmKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_CUstream0x90b7ef0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_, %arg3: !gpu.async.token) attributes {llvm.emit_c_interface} {
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
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %244 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %245 = arith.select %244, %c-1_i32, %c1_i32 : i32
    %246 = arith.addi %245, %172#0 : i32
    %247 = arith.divsi %246, %c128_i32 : i32
    %248 = arith.addi %c1_i32, %247 : i32
    %249 = arith.subi %c0_i32, %172#0 : i32
    %250 = arith.divsi %249, %c128_i32 : i32
    %251 = arith.subi %c0_i32, %250 : i32
    %252 = arith.cmpi slt, %172#0, %c0_i32 : i32
    %253 = arith.cmpi sgt, %172#0, %c0_i32 : i32
    %254 = arith.cmpi slt, %c128_i32, %c0_i32 : i32
    %255 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %256 = arith.andi %252, %254 : i1
    %257 = arith.andi %253, %255 : i1
    %258 = arith.ori %256, %257 : i1
    %259 = arith.select %258, %248, %251 : i32
    %260 = arith.muli %172#3, %c128_i64 : i64
    %c1_i32_11 = arith.constant 1 : i32
    %c0_i32_12 = arith.constant 0 : i32
    %c-1_i32_13 = arith.constant -1 : i32
    %261 = arith.cmpi sgt, %c128_i32, %c0_i32_12 : i32
    %262 = arith.select %261, %c-1_i32_13, %c1_i32_11 : i32
    %263 = arith.addi %262, %172#1 : i32
    %264 = arith.divsi %263, %c128_i32 : i32
    %265 = arith.addi %c1_i32_11, %264 : i32
    %266 = arith.subi %c0_i32_12, %172#1 : i32
    %267 = arith.divsi %266, %c128_i32 : i32
    %268 = arith.subi %c0_i32_12, %267 : i32
    %269 = arith.cmpi slt, %172#1, %c0_i32_12 : i32
    %270 = arith.cmpi sgt, %172#1, %c0_i32_12 : i32
    %271 = arith.cmpi slt, %c128_i32, %c0_i32_12 : i32
    %272 = arith.cmpi sgt, %c128_i32, %c0_i32_12 : i32
    %273 = arith.andi %269, %271 : i1
    %274 = arith.andi %270, %272 : i1
    %275 = arith.ori %273, %274 : i1
    %276 = arith.select %275, %265, %268 : i32
    %shape = cute.make_shape(%259, %276, %172#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
    %iv = cute.assume(%260) : (i64) -> !cute.i64<divby 128>
    %stride = cute.make_stride(%172#3, %iv, %172#4) : (i64, !cute.i64<divby 128>, i64) -> !cute.stride<"((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %lay_14 = cute.make_layout(%shape, %stride) : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %277:6 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %shape_15 = cute.make_shape(%277#0, %277#1, %277#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_16 = cute.assume(%277#4) : (i64) -> !cute.i64<divby 128>
    %stride_17 = cute.make_stride(%iv_16, %277#5) : (!cute.i64<divby 128>, i64) -> !cute.stride<"(?{i64 div=128},128,?{i64})">
    %lay_18 = cute.make_layout(%shape_15, %stride_17) : !cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">
    %278 = cute.get_shape(%lay_18) : (!cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%278) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_19 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_20 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_19, %itup_20) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %279:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_21 = cute.make_int_tuple(%279#0, %279#1, %279#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_22, %e1_23, %e2_24 = cute.get_leaves(%int_tuple_21) : !cute.int_tuple<"(?,?,?)">
    %mul = cute.tuple_mul(%e0_22, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %280 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
    %mul_25 = cute.tuple_mul(%e1_23, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %281 = cute.get_scalars(%mul_25) : !cute.int_tuple<"?">
    %mul_26 = cute.tuple_mul(%e2_24, %6) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %282 = cute.get_scalars(%mul_26) : !cute.int_tuple<"?">
    %283 = arith.index_cast %280 : i32 to index
    %284 = arith.index_cast %281 : i32 to index
    %285 = arith.index_cast %282 : i32 to index
    %286 = gpu.launch_func async [%arg3] @kernels::@kernel_cutlass_kernel___main__HopperWgmmaGemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1819201_TVLayoutDst1819201_Valuetypef16_tensor000o111012_CopyAtom_ThrID10_TVLayoutSrc1819201_TVL_0 clusters in (%c1, %c1, %c1) blocks in (%283, %284, %285) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c230400_i32 args(%97 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %169 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %242 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_10 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %10 : !mma_f16_f16_f32_64x128x16_) {use_pdl = false}
    return
  }
}
