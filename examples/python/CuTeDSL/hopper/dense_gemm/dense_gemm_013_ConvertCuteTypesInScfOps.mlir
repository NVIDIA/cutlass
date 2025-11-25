!copy_stsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>, layout_copy_tv = <"((4,8,4),(2,2,2)):((64,1,8),(256,32,512))">, tiler_mn = <"[(8,4,2):(1,16,8);(4,2,2):(2,1,8)]">>
!copy_stsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>, layout_copy_tv = <"((4,32),((2,2,2),1)):((64,1),((256,32,512),0))">, tiler_mn = <"[(8,4,2):(1,16,8);(4,2,2):(2,1,8)]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "(((2,2,2),1),1,2):(((1,2,4),0),0,8)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2,16),2,1):((1,2,4),64,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((8,8),2,1):((1,8),64,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(((2,2,2),1),1,2):(((1,2,4),0),0,8)">
!mma_f16_f16_f32_64x128x16_ = !cute.tiled_mma<!cute_nvgpu.sm90.mma<64x128x16, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<disable = true, count = 1 : i32>
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
      scf.if %172 {
        cute_nvgpu.prefetch_tma_desc(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      }
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
      %188:2 = scf.if %187 -> (i32, i32) {
        %396 = arith.remsi %176, %c8_i32 : i32
        %shape_65 = cute.make_shape(%396, %177) : (i32, i32) -> !cute.shape<"(?,?)">
        %stride_66 = cute.make_stride(%396) : (i32) -> !cute.stride<"(1,?)">
        %lay_67 = cute.make_layout(%shape_65, %stride_66) : !cute.layout<"(?,?):(1,?)">
        %sub = cute.tuple_sub(%int_tuple_0, %e0) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">) -> !cute.int_tuple<"?">
        %397 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
        %398 = cute.get_flat_coord(%397, %lay_67) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
        %e0_68, %e1_69 = cute.get_leaves(%398) : !cute.coord<"(?,?)">
        %itup_70 = cute.to_int_tuple(%e0_68) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_71 = cute.to_int_tuple(%e1_69) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %399 = cute.get_scalars(%itup_71) : !cute.int_tuple<"?">
        %sz_72 = cute.size(%int_tuple) <{mode = [0]}> : (!cute.int_tuple<"((8,?),?)">) -> !cute.int_tuple<"?{div=8}">
        %e0_73 = cute.get_leaves(%sz_72) : !cute.int_tuple<"?{div=8}">
        %tup_74 = cute.add_offset(%e0_73, %itup_70) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
        %400 = cute.get_scalars(%tup_74) : !cute.int_tuple<"?">
        scf.yield %400, %399 : i32, i32
      } else {
        scf.yield %185, %186 : i32, i32
      }
      %189 = nvvm.read.ptx.sreg.cluster.ctaid.x : i32
      %190 = nvvm.read.ptx.sreg.cluster.ctaid.y : i32
      %191 = arith.addi %188#0, %189 : i32
      %192 = arith.addi %188#1, %190 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %159) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_3 = cute.add_offset(%smem_ptr, %158) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"115712">) -> !cute.ptr<i8, smem, align<1024>>
      %iter = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      scf.if %172 {
        %396 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %396, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_65 = cute.add_offset(%iter, %157) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %397 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %397, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_66 = cute.add_offset(%iter, %156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %398 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %398, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_67 = cute.add_offset(%iter, %155) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %399 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %399, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_68 = cute.add_offset(%iter, %154) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
        %400 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %400, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_69 = cute.add_offset(%iter, %153) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %401 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %401, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_70 = cute.add_offset(%iter, %152) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %402 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %402, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_4 = cute.add_offset(%iter, %151) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      scf.if %172 {
        %396 = builtin.unrealized_conversion_cast %ptr_4 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %396, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_65 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_66 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
        %dyn = cute.derefine(%ptr_66) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
        %397 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %397, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_67 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_68 = cute.add_offset(%iter, %int_tuple_67) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
        %398 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %398, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_69 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_70 = cute.add_offset(%iter, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
        %dyn_71 = cute.derefine(%ptr_70) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
        %399 = builtin.unrealized_conversion_cast %dyn_71 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %399, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_72 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_73 = cute.add_offset(%iter, %int_tuple_72) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
        %400 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %400, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_74 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_75 = cute.add_offset(%iter, %int_tuple_74) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
        %dyn_76 = cute.derefine(%ptr_75) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
        %401 = builtin.unrealized_conversion_cast %dyn_76 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %401, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_77 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_78 = cute.add_offset(%iter, %int_tuple_77) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
        %402 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %402, %c4_i32 : !llvm.ptr<3>, i32
      }
      %193 = arith.remsi %160, %c32_i32 : i32
      %194 = arith.cmpi slt, %193, %c1_i32 : i32
      %195 = arith.extui %194 : i1 to i32
      %196 = arith.select %194, %c1_i32, %195 : i32
      %197 = arith.cmpi ne, %196, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_5 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_6 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_7 = cute.recast_iter(%iter_5) : !cute.ptr<f16, smem, align<1024>, S<3,4,3>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord = cute.make_coord(%191, %192, %173) : (i32, i32, i32) -> !cute.coord<"(?,?,_,?)">
      %198:3 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_,?)">
      %coord_8 = cute.make_coord(%198#0, %198#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_9 = cute.get_layout(%arg1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %199:3 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %200 = arith.ceildivsi %199#0, %c128_i32 : i32
      %201 = arith.ceildivsi %199#1, %c64_i32 : i32
      %shape_10 = cute.make_shape(%200, %201, %199#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_11 = cute.make_layout(%shape_10, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %202:3 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_12 = cute.make_shape(%202#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_13 = cute.make_layout(%shape_12, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_8, %lay_11) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup = cute.add_offset(%148, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_14 = cute.make_coord(%198#1, %198#2) : (i32, i32) -> !cute.coord<"((_,_),(?,_,?))">
      %lay_15 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %203:3 = cute.get_scalars(%lay_15) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %204 = arith.ceildivsi %203#0, %c128_i32 : i32
      %205 = arith.ceildivsi %203#1, %c64_i32 : i32
      %shape_16 = cute.make_shape(%204, %205, %203#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_17 = cute.make_layout(%shape_16, %150) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %206:3 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_18 = cute.make_shape(%206#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_19 = cute.make_layout(%shape_18, %149) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx_20 = cute.crd2idx(%coord_14, %lay_17) : (!cute.coord<"((_,_),(?,_,?))">, !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_21 = cute.add_offset(%148, %idx_20) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_22 = cute.make_coord(%198#0, %198#1, %198#2) : (i32, i32, i32) -> !cute.coord<"((_,_),(?,?,?))">
      %lay_23 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %207:3 = cute.get_scalars(%lay_23) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %208 = arith.ceildivsi %207#0, %c128_i32 : i32
      %209 = arith.ceildivsi %207#1, %c128_i32 : i32
      %shape_24 = cute.make_shape(%208, %209, %207#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_25 = cute.make_layout(%shape_24, %147) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %idx_26 = cute.crd2idx(%coord_22, %lay_25) : (!cute.coord<"((_,_),(?,?,?))">, !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %tup_27 = cute.add_offset(%148, %idx_26) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %210 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_28 = cute.make_shape(%210) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_29 = cute.make_layout(%shape_28, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %211 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_30 = cute.make_shape(%211) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_31 = cute.make_layout(%shape_30, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %212 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_32 = cute.make_shape(%212) : (i32) -> !cute.shape<"((128,64),?)">
      %lay_33 = cute.make_layout(%shape_32, %146) : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %213 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"((128,64),?):((1@1,1@0),64@0)">
      %shape_34 = cute.make_shape(%213) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_35 = cute.make_layout(%shape_34, %145) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %gmmaSmemDesc = cute_nvgpu.make_gmma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((64,16),2,4,(1,7)):((64,1),4096,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %gmmaSmemDesc_36 = cute_nvgpu.make_gmma_smem_desc(%iter_6 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,(1,7)):((64,1),0,16,(0,8192))">, major = <k> -> !cute_nvgpu.smem_desc
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      nvvm.barrier
      %sz_37 = cute.size(%lay_13) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_38 = cute.get_leaves(%sz_37) : !cute.int_tuple<"?">
      %214 = cute.get_scalars(%e0_38) : !cute.int_tuple<"?">
      %215 = arith.minsi %214, %c7_i32 : i32
      %216 = arith.maxsi %215, %c0_i32 : i32
      %217:3 = scf.if %172 -> (i32, i32, i32) {
        %396 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %398 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
        %399:3 = scf.for %arg7 = %c0_i32 to %216 step %c1_i32 iter_args(%arg8 = %c0_i32, %arg9 = %c0_i32, %arg10 = %c1_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_65 = cute.make_int_tuple(%arg9) : (i32) -> !cute.int_tuple<"?">
          %ptr_66 = cute.add_offset(%ptr_4, %int_tuple_65) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %400 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %400, %arg10, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %401 = nvvm.elect.sync -> i1
          scf.if %401 {
            %ptr_85 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %413 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %413, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
          %coord_67 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
          %idx_68 = cute.crd2idx(%coord_67, %lay_31) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_69 = cute.add_offset(%tup, %idx_68) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %e0_70, %e1_71, %e2 = cute.get_leaves(%tup_69) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %coord_72 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %idx_73 = cute.crd2idx(%coord_72, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_74 = cute.add_offset(%iter_5, %idx_73) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
          %idx_75 = cute.crd2idx(%coord_67, %lay_35) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_76 = cute.add_offset(%tup_21, %idx_75) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %e0_77, %e1_78, %e2_79 = cute.get_leaves(%tup_76) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %ptr_80 = cute.add_offset(%iter_6, %idx_73) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
          %ptr_81 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_82 = cute.make_int_tuple(%e0_70, %e1_71, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %402 = cute_nvgpu.atom.set_value(%396, %ptr_81 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %403 = cute_nvgpu.atom.get_value(%402 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%402 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
          %404:3 = cute.get_scalars(%int_tuple_82) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          scf.for %arg11 = %c0_i32 to %397 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_74 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %403 : !cute.ptr<smem, align<8>>, [%404#0, %404#1, %404#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %int_tuple_83 = cute.make_int_tuple(%e0_77, %e1_78, %e2_79) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %405 = cute_nvgpu.atom.set_value(%398, %ptr_81 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %406 = cute_nvgpu.atom.get_value(%405 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr_84 = cute_nvgpu.get_tma_desc_addr(%405 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
          %407:3 = cute.get_scalars(%int_tuple_83) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          scf.for %arg11 = %c0_i32 to %397 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_84 : !cute.ptr<generic, align<64>>, %ptr_80 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %406 : !cute.ptr<smem, align<8>>, [%407#0, %407#1, %407#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %408 = arith.addi %arg9, %c1_i32 : i32
          %409 = arith.addi %arg8, %c1_i32 : i32
          %410 = arith.cmpi eq, %408, %c7_i32 : i32
          %411 = arith.select %410, %c0_i32, %408 : i32
          %412 = scf.if %410 -> (i32) {
            %413 = arith.xori %arg10, %c1_i32 : i32
            scf.yield %413 : i32
          } else {
            scf.yield %arg10 : i32
          }
          scf.yield %409, %411, %412 : i32, i32, i32
        } {loop_annotation = #loop_annotation1}
        scf.yield %399#0, %399#1, %399#2 : i32, i32, i32
      } else {
        scf.yield %c0_i32, %c0_i32, %c1_i32 : i32, i32, i32
      }
      %218 = arith.cmpi sgt, %214, %c0_i32 : i32
      %219 = scf.if %218 -> (i1) {
        %dyn = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
        %396 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %397 = nvvm.mbarrier.wait.parity %396, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
        scf.yield %397 : i1
      } else {
        scf.yield %true : i1
      }
      %220 = cute_nvgpu.atom.set_value(%arg6, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
      %221 = builtin.unrealized_conversion_cast %220 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
      %222 = arith.extui %219 : i1 to i32
      %223 = arith.cmpi eq, %222, %c0_i32 : i32
      scf.if %223 {
        %dyn = cute.derefine(%iter) : !cute.ptr<i64, smem, align<1024>> to !cute.ptr<i64, smem>
        %396 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %396, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      }
      nvvm.wgmma.fence.aligned
      %iter_39 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %224 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %225 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      %226 = scf.for %arg7 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg8 = %221) -> (!llvm.struct<(i1)>)  : i32 {
        %396 = builtin.unrealized_conversion_cast %arg8 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,_,?,0)">
        %idx_66 = cute.crd2idx(%coord_65, %142) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
        %tup_67 = cute.add_offset(%gmmaSmemDesc, %idx_66) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
        %idx_68 = cute.crd2idx(%coord_65, %141) : (!cute.coord<"(_,_,?,0)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
        %tup_69 = cute.add_offset(%gmmaSmemDesc_36, %idx_68) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
        %397 = cute_nvgpu.atom.get_value(%396 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
        scf.for %arg9 = %c0_i32 to %224 step %c1_i32  : i32 {
          scf.for %arg10 = %c0_i32 to %225 step %c1_i32  : i32 {
            %coord_70 = cute.make_coord(%arg10, %arg9) : (i32, i32) -> !cute.coord<"(_,?,?)">
            %idx_71 = cute.crd2idx(%coord_70, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
            %tup_72 = cute.add_offset(%tup_67, %idx_71) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
            scf.for %arg11 = %c0_i32 to %224 step %c1_i32  : i32 {
              %coord_73 = cute.make_coord(%arg10, %arg11) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_74 = cute.crd2idx(%coord_73, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
              %ptr_75 = cute.add_offset(%iter_39, %idx_74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
              %400 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
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
              %528:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_72 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_69 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%401, %403, %405, %407, %409, %411, %413, %415, %417, %419, %421, %423, %425, %427, %429, %431, %433, %435, %437, %439, %441, %443, %445, %447, %449, %451, %453, %455, %457, %459, %461, %463, %465, %467, %469, %471, %473, %475, %477, %479, %481, %483, %485, %487, %489, %491, %493, %495, %497, %499, %501, %503, %505, %507, %509, %511, %513, %515, %517, %519, %521, %523, %525, %527], accum = %397 : i1)
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
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {llvm.loop_annotation = #loop_annotation}
        %398 = cute_nvgpu.atom.set_value(%396, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : !mma_f16_f16_f32_64x128x16_
        %399 = builtin.unrealized_conversion_cast %398 : !mma_f16_f16_f32_64x128x16_ to !llvm.struct<(i1)>
        scf.yield %399 : !llvm.struct<(i1)>
      } {loop_annotation = #loop_annotation2}
      %227 = builtin.unrealized_conversion_cast %226 : !llvm.struct<(i1)> to !mma_f16_f16_f32_64x128x16_
      nvvm.wgmma.commit.group.sync.aligned
      %228 = arith.cmpi sgt, %214, %c1_i32 : i32
      %229 = scf.if %228 -> (i1) {
        %int_tuple_65 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_66 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %396 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        %397 = nvvm.mbarrier.wait.parity %396, %c0_i32 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
        scf.yield %397 : i1
      } else {
        scf.yield %true : i1
      }
      %iter_40 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %230 = cute.get_scalars(%157) : !cute.int_tuple<"1">
      %231 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      %232 = cute_nvgpu.atom.get_value(%227 : !mma_f16_f16_f32_64x128x16_) {field = #cute_nvgpu.atom_mma_field_sm90<accum_c>} : i1
      %233 = arith.extui %172 : i1 to i32
      %234:10 = scf.for %arg7 = %c1_i32 to %214 step %c1_i32 iter_args(%arg8 = %229, %arg9 = %c1_i32, %arg10 = %c1_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %c0_i32, %arg14 = %c0_i32, %arg15 = %217#0, %arg16 = %217#1, %arg17 = %217#2) -> (i1, i32, i32, i32, i32, i32, i32, i32, i32, i32)  : i32 {
        %396 = arith.extui %arg8 : i1 to i32
        %397 = arith.cmpi eq, %396, %c0_i32 : i32
        scf.if %397 {
          %int_tuple_65 = cute.make_int_tuple(%arg10) : (i32) -> !cute.int_tuple<"?">
          %ptr_66 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %415 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %415, %arg11, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
        nvvm.wgmma.fence.aligned
        scf.for %arg18 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
          %coord_65 = cute.make_coord(%arg18, %arg10) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
          %idx_66 = cute.crd2idx(%coord_65, %142) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,2,4,(1,7)):(0,512,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
          %tup_67 = cute.add_offset(%gmmaSmemDesc, %idx_66) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_68 = cute.crd2idx(%coord_65, %141) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,(1,7)):(0,0,2,(0,1024))">) -> !cute.int_tuple<"?{div=2}">
          %tup_69 = cute.add_offset(%gmmaSmemDesc_36, %idx_68) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          scf.for %arg19 = %c0_i32 to %230 step %c1_i32  : i32 {
            scf.for %arg20 = %c0_i32 to %231 step %c1_i32  : i32 {
              %coord_70 = cute.make_coord(%arg20, %arg19) : (i32, i32) -> !cute.coord<"(_,?,?)">
              %idx_71 = cute.crd2idx(%coord_70, %140) : (!cute.coord<"(_,?,?)">, !cute.layout<"(1,2,1):(0,512,0)">) -> !cute.int_tuple<"?{div=512}">
              %tup_72 = cute.add_offset(%tup_67, %idx_71) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=512}">) -> !cute_nvgpu.smem_desc
              scf.for %arg21 = %c0_i32 to %230 step %c1_i32  : i32 {
                %coord_73 = cute.make_coord(%arg20, %arg21) : (i32, i32) -> !cute.coord<"(_,?,?)">
                %idx_74 = cute.crd2idx(%coord_73, %144) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,16),2,1):((1,2,4),64,0)">) -> !cute.int_tuple<"?{div=64}">
                %ptr_75 = cute.add_offset(%iter_40, %idx_74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, rmem, align<32>>
                %415 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
                %416 = llvm.load %415 : !llvm.ptr -> f32
                %417 = llvm.getelementptr %415[1] : (!llvm.ptr) -> !llvm.ptr, f32
                %418 = llvm.load %417 : !llvm.ptr -> f32
                %419 = llvm.getelementptr %415[2] : (!llvm.ptr) -> !llvm.ptr, f32
                %420 = llvm.load %419 : !llvm.ptr -> f32
                %421 = llvm.getelementptr %415[3] : (!llvm.ptr) -> !llvm.ptr, f32
                %422 = llvm.load %421 : !llvm.ptr -> f32
                %423 = llvm.getelementptr %415[4] : (!llvm.ptr) -> !llvm.ptr, f32
                %424 = llvm.load %423 : !llvm.ptr -> f32
                %425 = llvm.getelementptr %415[5] : (!llvm.ptr) -> !llvm.ptr, f32
                %426 = llvm.load %425 : !llvm.ptr -> f32
                %427 = llvm.getelementptr %415[6] : (!llvm.ptr) -> !llvm.ptr, f32
                %428 = llvm.load %427 : !llvm.ptr -> f32
                %429 = llvm.getelementptr %415[7] : (!llvm.ptr) -> !llvm.ptr, f32
                %430 = llvm.load %429 : !llvm.ptr -> f32
                %431 = llvm.getelementptr %415[8] : (!llvm.ptr) -> !llvm.ptr, f32
                %432 = llvm.load %431 : !llvm.ptr -> f32
                %433 = llvm.getelementptr %415[9] : (!llvm.ptr) -> !llvm.ptr, f32
                %434 = llvm.load %433 : !llvm.ptr -> f32
                %435 = llvm.getelementptr %415[10] : (!llvm.ptr) -> !llvm.ptr, f32
                %436 = llvm.load %435 : !llvm.ptr -> f32
                %437 = llvm.getelementptr %415[11] : (!llvm.ptr) -> !llvm.ptr, f32
                %438 = llvm.load %437 : !llvm.ptr -> f32
                %439 = llvm.getelementptr %415[12] : (!llvm.ptr) -> !llvm.ptr, f32
                %440 = llvm.load %439 : !llvm.ptr -> f32
                %441 = llvm.getelementptr %415[13] : (!llvm.ptr) -> !llvm.ptr, f32
                %442 = llvm.load %441 : !llvm.ptr -> f32
                %443 = llvm.getelementptr %415[14] : (!llvm.ptr) -> !llvm.ptr, f32
                %444 = llvm.load %443 : !llvm.ptr -> f32
                %445 = llvm.getelementptr %415[15] : (!llvm.ptr) -> !llvm.ptr, f32
                %446 = llvm.load %445 : !llvm.ptr -> f32
                %447 = llvm.getelementptr %415[16] : (!llvm.ptr) -> !llvm.ptr, f32
                %448 = llvm.load %447 : !llvm.ptr -> f32
                %449 = llvm.getelementptr %415[17] : (!llvm.ptr) -> !llvm.ptr, f32
                %450 = llvm.load %449 : !llvm.ptr -> f32
                %451 = llvm.getelementptr %415[18] : (!llvm.ptr) -> !llvm.ptr, f32
                %452 = llvm.load %451 : !llvm.ptr -> f32
                %453 = llvm.getelementptr %415[19] : (!llvm.ptr) -> !llvm.ptr, f32
                %454 = llvm.load %453 : !llvm.ptr -> f32
                %455 = llvm.getelementptr %415[20] : (!llvm.ptr) -> !llvm.ptr, f32
                %456 = llvm.load %455 : !llvm.ptr -> f32
                %457 = llvm.getelementptr %415[21] : (!llvm.ptr) -> !llvm.ptr, f32
                %458 = llvm.load %457 : !llvm.ptr -> f32
                %459 = llvm.getelementptr %415[22] : (!llvm.ptr) -> !llvm.ptr, f32
                %460 = llvm.load %459 : !llvm.ptr -> f32
                %461 = llvm.getelementptr %415[23] : (!llvm.ptr) -> !llvm.ptr, f32
                %462 = llvm.load %461 : !llvm.ptr -> f32
                %463 = llvm.getelementptr %415[24] : (!llvm.ptr) -> !llvm.ptr, f32
                %464 = llvm.load %463 : !llvm.ptr -> f32
                %465 = llvm.getelementptr %415[25] : (!llvm.ptr) -> !llvm.ptr, f32
                %466 = llvm.load %465 : !llvm.ptr -> f32
                %467 = llvm.getelementptr %415[26] : (!llvm.ptr) -> !llvm.ptr, f32
                %468 = llvm.load %467 : !llvm.ptr -> f32
                %469 = llvm.getelementptr %415[27] : (!llvm.ptr) -> !llvm.ptr, f32
                %470 = llvm.load %469 : !llvm.ptr -> f32
                %471 = llvm.getelementptr %415[28] : (!llvm.ptr) -> !llvm.ptr, f32
                %472 = llvm.load %471 : !llvm.ptr -> f32
                %473 = llvm.getelementptr %415[29] : (!llvm.ptr) -> !llvm.ptr, f32
                %474 = llvm.load %473 : !llvm.ptr -> f32
                %475 = llvm.getelementptr %415[30] : (!llvm.ptr) -> !llvm.ptr, f32
                %476 = llvm.load %475 : !llvm.ptr -> f32
                %477 = llvm.getelementptr %415[31] : (!llvm.ptr) -> !llvm.ptr, f32
                %478 = llvm.load %477 : !llvm.ptr -> f32
                %479 = llvm.getelementptr %415[32] : (!llvm.ptr) -> !llvm.ptr, f32
                %480 = llvm.load %479 : !llvm.ptr -> f32
                %481 = llvm.getelementptr %415[33] : (!llvm.ptr) -> !llvm.ptr, f32
                %482 = llvm.load %481 : !llvm.ptr -> f32
                %483 = llvm.getelementptr %415[34] : (!llvm.ptr) -> !llvm.ptr, f32
                %484 = llvm.load %483 : !llvm.ptr -> f32
                %485 = llvm.getelementptr %415[35] : (!llvm.ptr) -> !llvm.ptr, f32
                %486 = llvm.load %485 : !llvm.ptr -> f32
                %487 = llvm.getelementptr %415[36] : (!llvm.ptr) -> !llvm.ptr, f32
                %488 = llvm.load %487 : !llvm.ptr -> f32
                %489 = llvm.getelementptr %415[37] : (!llvm.ptr) -> !llvm.ptr, f32
                %490 = llvm.load %489 : !llvm.ptr -> f32
                %491 = llvm.getelementptr %415[38] : (!llvm.ptr) -> !llvm.ptr, f32
                %492 = llvm.load %491 : !llvm.ptr -> f32
                %493 = llvm.getelementptr %415[39] : (!llvm.ptr) -> !llvm.ptr, f32
                %494 = llvm.load %493 : !llvm.ptr -> f32
                %495 = llvm.getelementptr %415[40] : (!llvm.ptr) -> !llvm.ptr, f32
                %496 = llvm.load %495 : !llvm.ptr -> f32
                %497 = llvm.getelementptr %415[41] : (!llvm.ptr) -> !llvm.ptr, f32
                %498 = llvm.load %497 : !llvm.ptr -> f32
                %499 = llvm.getelementptr %415[42] : (!llvm.ptr) -> !llvm.ptr, f32
                %500 = llvm.load %499 : !llvm.ptr -> f32
                %501 = llvm.getelementptr %415[43] : (!llvm.ptr) -> !llvm.ptr, f32
                %502 = llvm.load %501 : !llvm.ptr -> f32
                %503 = llvm.getelementptr %415[44] : (!llvm.ptr) -> !llvm.ptr, f32
                %504 = llvm.load %503 : !llvm.ptr -> f32
                %505 = llvm.getelementptr %415[45] : (!llvm.ptr) -> !llvm.ptr, f32
                %506 = llvm.load %505 : !llvm.ptr -> f32
                %507 = llvm.getelementptr %415[46] : (!llvm.ptr) -> !llvm.ptr, f32
                %508 = llvm.load %507 : !llvm.ptr -> f32
                %509 = llvm.getelementptr %415[47] : (!llvm.ptr) -> !llvm.ptr, f32
                %510 = llvm.load %509 : !llvm.ptr -> f32
                %511 = llvm.getelementptr %415[48] : (!llvm.ptr) -> !llvm.ptr, f32
                %512 = llvm.load %511 : !llvm.ptr -> f32
                %513 = llvm.getelementptr %415[49] : (!llvm.ptr) -> !llvm.ptr, f32
                %514 = llvm.load %513 : !llvm.ptr -> f32
                %515 = llvm.getelementptr %415[50] : (!llvm.ptr) -> !llvm.ptr, f32
                %516 = llvm.load %515 : !llvm.ptr -> f32
                %517 = llvm.getelementptr %415[51] : (!llvm.ptr) -> !llvm.ptr, f32
                %518 = llvm.load %517 : !llvm.ptr -> f32
                %519 = llvm.getelementptr %415[52] : (!llvm.ptr) -> !llvm.ptr, f32
                %520 = llvm.load %519 : !llvm.ptr -> f32
                %521 = llvm.getelementptr %415[53] : (!llvm.ptr) -> !llvm.ptr, f32
                %522 = llvm.load %521 : !llvm.ptr -> f32
                %523 = llvm.getelementptr %415[54] : (!llvm.ptr) -> !llvm.ptr, f32
                %524 = llvm.load %523 : !llvm.ptr -> f32
                %525 = llvm.getelementptr %415[55] : (!llvm.ptr) -> !llvm.ptr, f32
                %526 = llvm.load %525 : !llvm.ptr -> f32
                %527 = llvm.getelementptr %415[56] : (!llvm.ptr) -> !llvm.ptr, f32
                %528 = llvm.load %527 : !llvm.ptr -> f32
                %529 = llvm.getelementptr %415[57] : (!llvm.ptr) -> !llvm.ptr, f32
                %530 = llvm.load %529 : !llvm.ptr -> f32
                %531 = llvm.getelementptr %415[58] : (!llvm.ptr) -> !llvm.ptr, f32
                %532 = llvm.load %531 : !llvm.ptr -> f32
                %533 = llvm.getelementptr %415[59] : (!llvm.ptr) -> !llvm.ptr, f32
                %534 = llvm.load %533 : !llvm.ptr -> f32
                %535 = llvm.getelementptr %415[60] : (!llvm.ptr) -> !llvm.ptr, f32
                %536 = llvm.load %535 : !llvm.ptr -> f32
                %537 = llvm.getelementptr %415[61] : (!llvm.ptr) -> !llvm.ptr, f32
                %538 = llvm.load %537 : !llvm.ptr -> f32
                %539 = llvm.getelementptr %415[62] : (!llvm.ptr) -> !llvm.ptr, f32
                %540 = llvm.load %539 : !llvm.ptr -> f32
                %541 = llvm.getelementptr %415[63] : (!llvm.ptr) -> !llvm.ptr, f32
                %542 = llvm.load %541 : !llvm.ptr -> f32
                %543:64 = cute_nvgpu.arch.mma.SM90(shapeMNK = "(64,128,16)", A = %tup_72 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], B = %tup_69 : [!cute_nvgpu.smem_desc, f16, #cute_nvgpu.major<k>], C[%416, %418, %420, %422, %424, %426, %428, %430, %432, %434, %436, %438, %440, %442, %444, %446, %448, %450, %452, %454, %456, %458, %460, %462, %464, %466, %468, %470, %472, %474, %476, %478, %480, %482, %484, %486, %488, %490, %492, %494, %496, %498, %500, %502, %504, %506, %508, %510, %512, %514, %516, %518, %520, %522, %524, %526, %528, %530, %532, %534, %536, %538, %540, %542], accum = %232 : i1)
< {cd_type = f32, operandSegmentSizes = array<i32: 1, 1, 64, 1>}> :(!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, f32, i1) -> (f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32)
                llvm.store %543#0, %415 : f32, !llvm.ptr
                llvm.store %543#1, %417 : f32, !llvm.ptr
                llvm.store %543#2, %419 : f32, !llvm.ptr
                llvm.store %543#3, %421 : f32, !llvm.ptr
                llvm.store %543#4, %423 : f32, !llvm.ptr
                llvm.store %543#5, %425 : f32, !llvm.ptr
                llvm.store %543#6, %427 : f32, !llvm.ptr
                llvm.store %543#7, %429 : f32, !llvm.ptr
                llvm.store %543#8, %431 : f32, !llvm.ptr
                llvm.store %543#9, %433 : f32, !llvm.ptr
                llvm.store %543#10, %435 : f32, !llvm.ptr
                llvm.store %543#11, %437 : f32, !llvm.ptr
                llvm.store %543#12, %439 : f32, !llvm.ptr
                llvm.store %543#13, %441 : f32, !llvm.ptr
                llvm.store %543#14, %443 : f32, !llvm.ptr
                llvm.store %543#15, %445 : f32, !llvm.ptr
                llvm.store %543#16, %447 : f32, !llvm.ptr
                llvm.store %543#17, %449 : f32, !llvm.ptr
                llvm.store %543#18, %451 : f32, !llvm.ptr
                llvm.store %543#19, %453 : f32, !llvm.ptr
                llvm.store %543#20, %455 : f32, !llvm.ptr
                llvm.store %543#21, %457 : f32, !llvm.ptr
                llvm.store %543#22, %459 : f32, !llvm.ptr
                llvm.store %543#23, %461 : f32, !llvm.ptr
                llvm.store %543#24, %463 : f32, !llvm.ptr
                llvm.store %543#25, %465 : f32, !llvm.ptr
                llvm.store %543#26, %467 : f32, !llvm.ptr
                llvm.store %543#27, %469 : f32, !llvm.ptr
                llvm.store %543#28, %471 : f32, !llvm.ptr
                llvm.store %543#29, %473 : f32, !llvm.ptr
                llvm.store %543#30, %475 : f32, !llvm.ptr
                llvm.store %543#31, %477 : f32, !llvm.ptr
                llvm.store %543#32, %479 : f32, !llvm.ptr
                llvm.store %543#33, %481 : f32, !llvm.ptr
                llvm.store %543#34, %483 : f32, !llvm.ptr
                llvm.store %543#35, %485 : f32, !llvm.ptr
                llvm.store %543#36, %487 : f32, !llvm.ptr
                llvm.store %543#37, %489 : f32, !llvm.ptr
                llvm.store %543#38, %491 : f32, !llvm.ptr
                llvm.store %543#39, %493 : f32, !llvm.ptr
                llvm.store %543#40, %495 : f32, !llvm.ptr
                llvm.store %543#41, %497 : f32, !llvm.ptr
                llvm.store %543#42, %499 : f32, !llvm.ptr
                llvm.store %543#43, %501 : f32, !llvm.ptr
                llvm.store %543#44, %503 : f32, !llvm.ptr
                llvm.store %543#45, %505 : f32, !llvm.ptr
                llvm.store %543#46, %507 : f32, !llvm.ptr
                llvm.store %543#47, %509 : f32, !llvm.ptr
                llvm.store %543#48, %511 : f32, !llvm.ptr
                llvm.store %543#49, %513 : f32, !llvm.ptr
                llvm.store %543#50, %515 : f32, !llvm.ptr
                llvm.store %543#51, %517 : f32, !llvm.ptr
                llvm.store %543#52, %519 : f32, !llvm.ptr
                llvm.store %543#53, %521 : f32, !llvm.ptr
                llvm.store %543#54, %523 : f32, !llvm.ptr
                llvm.store %543#55, %525 : f32, !llvm.ptr
                llvm.store %543#56, %527 : f32, !llvm.ptr
                llvm.store %543#57, %529 : f32, !llvm.ptr
                llvm.store %543#58, %531 : f32, !llvm.ptr
                llvm.store %543#59, %533 : f32, !llvm.ptr
                llvm.store %543#60, %535 : f32, !llvm.ptr
                llvm.store %543#61, %537 : f32, !llvm.ptr
                llvm.store %543#62, %539 : f32, !llvm.ptr
                llvm.store %543#63, %541 : f32, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
        } {loop_annotation = #loop_annotation2}
        nvvm.wgmma.commit.group.sync.aligned
        nvvm.wgmma.wait.group.sync.aligned 1
        scf.if %197 {
          %int_tuple_65 = cute.make_int_tuple(%arg13) : (i32) -> !cute.int_tuple<"?">
          %ptr_66 = cute.add_offset(%ptr_4, %int_tuple_65) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %415 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.txn %415, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
        }
        %398 = arith.addi %arg10, %c1_i32 : i32
        %399 = arith.addi %arg9, %c1_i32 : i32
        %400 = arith.cmpi eq, %398, %c7_i32 : i32
        %401 = arith.select %400, %c0_i32, %398 : i32
        %402 = scf.if %400 -> (i32) {
          %415 = arith.xori %arg11, %c1_i32 : i32
          scf.yield %415 : i32
        } else {
          scf.yield %arg11 : i32
        }
        %403 = arith.addi %arg13, %c1_i32 : i32
        %404 = arith.addi %arg12, %c1_i32 : i32
        %405 = arith.cmpi eq, %403, %c7_i32 : i32
        %406 = arith.select %405, %c0_i32, %403 : i32
        %407 = scf.if %405 -> (i32) {
          %415 = arith.xori %arg14, %c1_i32 : i32
          scf.yield %415 : i32
        } else {
          scf.yield %arg14 : i32
        }
        %408 = arith.cmpi sgt, %214, %399 : i32
        %409 = scf.if %408 -> (i1) {
          %int_tuple_65 = cute.make_int_tuple(%401) : (i32) -> !cute.int_tuple<"?">
          %ptr_66 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %415 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          %416 = nvvm.mbarrier.wait.parity %415, %402 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
          scf.yield %416 : i1
        } else {
          scf.yield %true : i1
        }
        %410 = arith.cmpi sgt, %214, %arg15 : i32
        %411 = arith.extui %410 : i1 to i32
        %412 = arith.select %172, %411, %233 : i32
        %413 = arith.cmpi ne, %412, %c0_i32 : i32
        %414:3 = scf.if %413 -> (i32, i32, i32) {
          %int_tuple_65 = cute.make_int_tuple(%arg16) : (i32) -> !cute.int_tuple<"?">
          %ptr_66 = cute.add_offset(%ptr_4, %int_tuple_65) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %415 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %415, %arg17, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %416 = nvvm.elect.sync -> i1
          scf.if %416 {
            %ptr_85 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %431 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %431, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
          %coord_67 = cute.make_coord(%arg15) : (i32) -> !cute.coord<"(_,?)">
          %idx_68 = cute.crd2idx(%coord_67, %lay_31) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_69 = cute.add_offset(%tup, %idx_68) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %e0_70, %e1_71, %e2 = cute.get_leaves(%tup_69) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %coord_72 = cute.make_coord(%arg16) : (i32) -> !cute.coord<"(_,?)">
          %idx_73 = cute.crd2idx(%coord_72, %143) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),(1,7)):((1,0),(0,8192))">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_74 = cute.add_offset(%iter_5, %idx_73) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
          %idx_75 = cute.crd2idx(%coord_67, %lay_35) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_76 = cute.add_offset(%tup_21, %idx_75) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %e0_77, %e1_78, %e2_79 = cute.get_leaves(%tup_76) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %ptr_80 = cute.add_offset(%iter_6, %idx_73) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
          %ptr_81 = cute.add_offset(%iter, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_82 = cute.make_int_tuple(%e0_70, %e1_71, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %417 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %418 = cute_nvgpu.atom.set_value(%417, %ptr_81 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %419 = cute.get_scalars(%157) : !cute.int_tuple<"1">
          %420 = cute_nvgpu.atom.get_value(%418 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%418 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
          %421:3 = cute.get_scalars(%int_tuple_82) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          scf.for %arg18 = %c0_i32 to %419 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_74 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %420 : !cute.ptr<smem, align<8>>, [%421#0, %421#1, %421#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %int_tuple_83 = cute.make_int_tuple(%e0_77, %e1_78, %e2_79) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
          %422 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %423 = cute_nvgpu.atom.set_value(%422, %ptr_81 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
          %424 = cute_nvgpu.atom.get_value(%423 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr_84 = cute_nvgpu.get_tma_desc_addr(%423 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
          %425:3 = cute.get_scalars(%int_tuple_83) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
          scf.for %arg18 = %c0_i32 to %419 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_84 : !cute.ptr<generic, align<64>>, %ptr_80 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %424 : !cute.ptr<smem, align<8>>, [%425#0, %425#1, %425#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %426 = arith.addi %arg16, %c1_i32 : i32
          %427 = arith.addi %arg15, %c1_i32 : i32
          %428 = arith.cmpi eq, %426, %c7_i32 : i32
          %429 = arith.select %428, %c0_i32, %426 : i32
          %430 = scf.if %428 -> (i32) {
            %431 = arith.xori %arg17, %c1_i32 : i32
            scf.yield %431 : i32
          } else {
            scf.yield %arg17 : i32
          }
          scf.yield %427, %429, %430 : i32, i32, i32
        } else {
          scf.yield %arg15, %arg16, %arg17 : i32, i32, i32
        }
        scf.yield %409, %399, %401, %402, %404, %406, %407, %414#0, %414#1, %414#2 : i1, i32, i32, i32, i32, i32, i32, i32, i32, i32
      } {loop_annotation = #loop_annotation1}
      nvvm.wgmma.wait.group.sync.aligned 0
      nvvm.barrier
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, n>
      %235 = cute.make_tiled_copy(%atom) : !copy_stsm_4_
      %236 = cute.make_tiled_copy(%atom) : !copy_stsm_4_1
      %coord_41 = cute.make_coord(%160) : (i32) -> !cute.coord<"?">
      %237 = cute.get_scalars(%coord_41) <{only_dynamic}> : !cute.coord<"?">
      %238 = arith.divsi %237, %c8_i32 : i32
      %239 = arith.remsi %237, %c8_i32 : i32
      %240 = arith.muli %239, %c32_i32 : i32
      %241 = arith.divsi %238, %c2_i32 : i32
      %242 = arith.remsi %238, %c2_i32 : i32
      %243 = arith.muli %242, %c256_i32 : i32
      %244 = arith.addi %240, %243 : i32
      %245 = arith.divsi %241, %c2_i32 : i32
      %246 = arith.remsi %241, %c2_i32 : i32
      %247 = arith.muli %246, %c8_i32 : i32
      %248 = arith.addi %244, %247 : i32
      %249 = arith.muli %245, %c512_i32 : i32
      %250 = arith.addi %248, %249 : i32
      %iv = cute.assume(%250) : (i32) -> !cute.i32<divby 8>
      %int_tuple_42 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_43 = cute.add_offset(%iter_7, %int_tuple_42) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %iter_44 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %view = cute.make_view(%iter_44) : !memref_rmem_f32_1
      %rmem_45 = cute.memref.alloca() : !memref_rmem_f32_2
      %251 = cute.memref.load(%view, %139) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      cute.memref.store(%rmem_45, %139, %251) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %252 = cute.memref.load(%view, %138) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      cute.memref.store(%rmem_45, %138, %252) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %253 = cute.memref.load(%view, %137) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      cute.memref.store(%rmem_45, %137, %253) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %254 = cute.memref.load(%view, %136) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      cute.memref.store(%rmem_45, %136, %254) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %255 = cute.memref.load(%view, %135) : (!memref_rmem_f32_1, !cute.coord<"4">) -> f32
      cute.memref.store(%rmem_45, %135, %255) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %256 = cute.memref.load(%view, %134) : (!memref_rmem_f32_1, !cute.coord<"5">) -> f32
      cute.memref.store(%rmem_45, %134, %256) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %257 = cute.memref.load(%view, %133) : (!memref_rmem_f32_1, !cute.coord<"6">) -> f32
      cute.memref.store(%rmem_45, %133, %257) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %258 = cute.memref.load(%view, %132) : (!memref_rmem_f32_1, !cute.coord<"7">) -> f32
      cute.memref.store(%rmem_45, %132, %258) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %259 = cute.memref.load(%view, %131) : (!memref_rmem_f32_1, !cute.coord<"8">) -> f32
      cute.memref.store(%rmem_45, %131, %259) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %260 = cute.memref.load(%view, %130) : (!memref_rmem_f32_1, !cute.coord<"9">) -> f32
      cute.memref.store(%rmem_45, %130, %260) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %261 = cute.memref.load(%view, %129) : (!memref_rmem_f32_1, !cute.coord<"10">) -> f32
      cute.memref.store(%rmem_45, %129, %261) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %262 = cute.memref.load(%view, %128) : (!memref_rmem_f32_1, !cute.coord<"11">) -> f32
      cute.memref.store(%rmem_45, %128, %262) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %263 = cute.memref.load(%view, %127) : (!memref_rmem_f32_1, !cute.coord<"12">) -> f32
      cute.memref.store(%rmem_45, %127, %263) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %264 = cute.memref.load(%view, %126) : (!memref_rmem_f32_1, !cute.coord<"13">) -> f32
      cute.memref.store(%rmem_45, %126, %264) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %265 = cute.memref.load(%view, %125) : (!memref_rmem_f32_1, !cute.coord<"14">) -> f32
      cute.memref.store(%rmem_45, %125, %265) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %266 = cute.memref.load(%view, %124) : (!memref_rmem_f32_1, !cute.coord<"15">) -> f32
      cute.memref.store(%rmem_45, %124, %266) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_46 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_47 = cute.get_iter(%rmem_46) : !memref_rmem_f16_
      %267 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %268 = arith.truncf %267 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %268, %rmem_46, row_major : !memref_rmem_f16_
      %269 = cute.get_scalars(%156) : !cute.int_tuple<"2">
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_47, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_43, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %e0_65, %e1_66, %e2 = cute.get_leaves(%tup_27) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
        %int_tuple_67 = cute.make_int_tuple(%e0_65, %e1_66, %e2) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_67) : !cute.int_tuple<"(?{div=128},?{div=128},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_7 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %270 = cute.memref.load(%view, %121) : (!memref_rmem_f32_1, !cute.coord<"16">) -> f32
      cute.memref.store(%rmem_45, %139, %270) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %271 = cute.memref.load(%view, %120) : (!memref_rmem_f32_1, !cute.coord<"17">) -> f32
      cute.memref.store(%rmem_45, %138, %271) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %272 = cute.memref.load(%view, %119) : (!memref_rmem_f32_1, !cute.coord<"18">) -> f32
      cute.memref.store(%rmem_45, %137, %272) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %273 = cute.memref.load(%view, %118) : (!memref_rmem_f32_1, !cute.coord<"19">) -> f32
      cute.memref.store(%rmem_45, %136, %273) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %274 = cute.memref.load(%view, %117) : (!memref_rmem_f32_1, !cute.coord<"20">) -> f32
      cute.memref.store(%rmem_45, %135, %274) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %275 = cute.memref.load(%view, %116) : (!memref_rmem_f32_1, !cute.coord<"21">) -> f32
      cute.memref.store(%rmem_45, %134, %275) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %276 = cute.memref.load(%view, %115) : (!memref_rmem_f32_1, !cute.coord<"22">) -> f32
      cute.memref.store(%rmem_45, %133, %276) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %277 = cute.memref.load(%view, %114) : (!memref_rmem_f32_1, !cute.coord<"23">) -> f32
      cute.memref.store(%rmem_45, %132, %277) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %278 = cute.memref.load(%view, %113) : (!memref_rmem_f32_1, !cute.coord<"24">) -> f32
      cute.memref.store(%rmem_45, %131, %278) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %279 = cute.memref.load(%view, %112) : (!memref_rmem_f32_1, !cute.coord<"25">) -> f32
      cute.memref.store(%rmem_45, %130, %279) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %280 = cute.memref.load(%view, %111) : (!memref_rmem_f32_1, !cute.coord<"26">) -> f32
      cute.memref.store(%rmem_45, %129, %280) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %281 = cute.memref.load(%view, %110) : (!memref_rmem_f32_1, !cute.coord<"27">) -> f32
      cute.memref.store(%rmem_45, %128, %281) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %282 = cute.memref.load(%view, %109) : (!memref_rmem_f32_1, !cute.coord<"28">) -> f32
      cute.memref.store(%rmem_45, %127, %282) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %283 = cute.memref.load(%view, %108) : (!memref_rmem_f32_1, !cute.coord<"29">) -> f32
      cute.memref.store(%rmem_45, %126, %283) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %284 = cute.memref.load(%view, %107) : (!memref_rmem_f32_1, !cute.coord<"30">) -> f32
      cute.memref.store(%rmem_45, %125, %284) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %285 = cute.memref.load(%view, %106) : (!memref_rmem_f32_1, !cute.coord<"31">) -> f32
      cute.memref.store(%rmem_45, %124, %285) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_48 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_49 = cute.get_iter(%rmem_48) : !memref_rmem_f16_
      %286 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %287 = arith.truncf %286 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %287, %rmem_48, row_major : !memref_rmem_f16_
      %ptr_50 = cute.add_offset(%ptr_43, %105) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_49, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_50, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %104) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %288 = cute.memref.load(%view, %103) : (!memref_rmem_f32_1, !cute.coord<"32">) -> f32
      cute.memref.store(%rmem_45, %139, %288) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %289 = cute.memref.load(%view, %102) : (!memref_rmem_f32_1, !cute.coord<"33">) -> f32
      cute.memref.store(%rmem_45, %138, %289) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %290 = cute.memref.load(%view, %101) : (!memref_rmem_f32_1, !cute.coord<"34">) -> f32
      cute.memref.store(%rmem_45, %137, %290) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %291 = cute.memref.load(%view, %100) : (!memref_rmem_f32_1, !cute.coord<"35">) -> f32
      cute.memref.store(%rmem_45, %136, %291) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %292 = cute.memref.load(%view, %99) : (!memref_rmem_f32_1, !cute.coord<"36">) -> f32
      cute.memref.store(%rmem_45, %135, %292) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %293 = cute.memref.load(%view, %98) : (!memref_rmem_f32_1, !cute.coord<"37">) -> f32
      cute.memref.store(%rmem_45, %134, %293) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %294 = cute.memref.load(%view, %97) : (!memref_rmem_f32_1, !cute.coord<"38">) -> f32
      cute.memref.store(%rmem_45, %133, %294) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %295 = cute.memref.load(%view, %96) : (!memref_rmem_f32_1, !cute.coord<"39">) -> f32
      cute.memref.store(%rmem_45, %132, %295) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %296 = cute.memref.load(%view, %95) : (!memref_rmem_f32_1, !cute.coord<"40">) -> f32
      cute.memref.store(%rmem_45, %131, %296) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %297 = cute.memref.load(%view, %94) : (!memref_rmem_f32_1, !cute.coord<"41">) -> f32
      cute.memref.store(%rmem_45, %130, %297) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %298 = cute.memref.load(%view, %93) : (!memref_rmem_f32_1, !cute.coord<"42">) -> f32
      cute.memref.store(%rmem_45, %129, %298) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %299 = cute.memref.load(%view, %92) : (!memref_rmem_f32_1, !cute.coord<"43">) -> f32
      cute.memref.store(%rmem_45, %128, %299) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %300 = cute.memref.load(%view, %91) : (!memref_rmem_f32_1, !cute.coord<"44">) -> f32
      cute.memref.store(%rmem_45, %127, %300) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %301 = cute.memref.load(%view, %90) : (!memref_rmem_f32_1, !cute.coord<"45">) -> f32
      cute.memref.store(%rmem_45, %126, %301) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %302 = cute.memref.load(%view, %89) : (!memref_rmem_f32_1, !cute.coord<"46">) -> f32
      cute.memref.store(%rmem_45, %125, %302) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %303 = cute.memref.load(%view, %88) : (!memref_rmem_f32_1, !cute.coord<"47">) -> f32
      cute.memref.store(%rmem_45, %124, %303) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_51 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_52 = cute.get_iter(%rmem_51) : !memref_rmem_f16_
      %304 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %305 = arith.truncf %304 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %305, %rmem_51, row_major : !memref_rmem_f16_
      %ptr_53 = cute.add_offset(%ptr_43, %87) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_52, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_53, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %86) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=128},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=64},?{div=128},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %306 = cute.memref.load(%view, %85) : (!memref_rmem_f32_1, !cute.coord<"48">) -> f32
      cute.memref.store(%rmem_45, %139, %306) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %307 = cute.memref.load(%view, %84) : (!memref_rmem_f32_1, !cute.coord<"49">) -> f32
      cute.memref.store(%rmem_45, %138, %307) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %308 = cute.memref.load(%view, %83) : (!memref_rmem_f32_1, !cute.coord<"50">) -> f32
      cute.memref.store(%rmem_45, %137, %308) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %309 = cute.memref.load(%view, %82) : (!memref_rmem_f32_1, !cute.coord<"51">) -> f32
      cute.memref.store(%rmem_45, %136, %309) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %310 = cute.memref.load(%view, %81) : (!memref_rmem_f32_1, !cute.coord<"52">) -> f32
      cute.memref.store(%rmem_45, %135, %310) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %311 = cute.memref.load(%view, %80) : (!memref_rmem_f32_1, !cute.coord<"53">) -> f32
      cute.memref.store(%rmem_45, %134, %311) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %312 = cute.memref.load(%view, %79) : (!memref_rmem_f32_1, !cute.coord<"54">) -> f32
      cute.memref.store(%rmem_45, %133, %312) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %313 = cute.memref.load(%view, %78) : (!memref_rmem_f32_1, !cute.coord<"55">) -> f32
      cute.memref.store(%rmem_45, %132, %313) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %314 = cute.memref.load(%view, %77) : (!memref_rmem_f32_1, !cute.coord<"56">) -> f32
      cute.memref.store(%rmem_45, %131, %314) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %315 = cute.memref.load(%view, %76) : (!memref_rmem_f32_1, !cute.coord<"57">) -> f32
      cute.memref.store(%rmem_45, %130, %315) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %316 = cute.memref.load(%view, %75) : (!memref_rmem_f32_1, !cute.coord<"58">) -> f32
      cute.memref.store(%rmem_45, %129, %316) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %317 = cute.memref.load(%view, %74) : (!memref_rmem_f32_1, !cute.coord<"59">) -> f32
      cute.memref.store(%rmem_45, %128, %317) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %318 = cute.memref.load(%view, %73) : (!memref_rmem_f32_1, !cute.coord<"60">) -> f32
      cute.memref.store(%rmem_45, %127, %318) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %319 = cute.memref.load(%view, %72) : (!memref_rmem_f32_1, !cute.coord<"61">) -> f32
      cute.memref.store(%rmem_45, %126, %319) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %320 = cute.memref.load(%view, %71) : (!memref_rmem_f32_1, !cute.coord<"62">) -> f32
      cute.memref.store(%rmem_45, %125, %320) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %321 = cute.memref.load(%view, %70) : (!memref_rmem_f32_1, !cute.coord<"63">) -> f32
      cute.memref.store(%rmem_45, %124, %321) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_54 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_55 = cute.get_iter(%rmem_54) : !memref_rmem_f16_
      %322 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %323 = arith.truncf %322 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %323, %rmem_54, row_major : !memref_rmem_f16_
      %ptr_56 = cute.add_offset(%ptr_43, %69) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_55, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_56, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %68) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %324 = cute.memref.load(%view, %67) : (!memref_rmem_f32_1, !cute.coord<"64">) -> f32
      cute.memref.store(%rmem_45, %139, %324) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %325 = cute.memref.load(%view, %66) : (!memref_rmem_f32_1, !cute.coord<"65">) -> f32
      cute.memref.store(%rmem_45, %138, %325) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %326 = cute.memref.load(%view, %65) : (!memref_rmem_f32_1, !cute.coord<"66">) -> f32
      cute.memref.store(%rmem_45, %137, %326) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %327 = cute.memref.load(%view, %64) : (!memref_rmem_f32_1, !cute.coord<"67">) -> f32
      cute.memref.store(%rmem_45, %136, %327) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %328 = cute.memref.load(%view, %63) : (!memref_rmem_f32_1, !cute.coord<"68">) -> f32
      cute.memref.store(%rmem_45, %135, %328) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %329 = cute.memref.load(%view, %62) : (!memref_rmem_f32_1, !cute.coord<"69">) -> f32
      cute.memref.store(%rmem_45, %134, %329) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %330 = cute.memref.load(%view, %61) : (!memref_rmem_f32_1, !cute.coord<"70">) -> f32
      cute.memref.store(%rmem_45, %133, %330) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %331 = cute.memref.load(%view, %60) : (!memref_rmem_f32_1, !cute.coord<"71">) -> f32
      cute.memref.store(%rmem_45, %132, %331) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %332 = cute.memref.load(%view, %59) : (!memref_rmem_f32_1, !cute.coord<"72">) -> f32
      cute.memref.store(%rmem_45, %131, %332) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %333 = cute.memref.load(%view, %58) : (!memref_rmem_f32_1, !cute.coord<"73">) -> f32
      cute.memref.store(%rmem_45, %130, %333) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %334 = cute.memref.load(%view, %57) : (!memref_rmem_f32_1, !cute.coord<"74">) -> f32
      cute.memref.store(%rmem_45, %129, %334) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %335 = cute.memref.load(%view, %56) : (!memref_rmem_f32_1, !cute.coord<"75">) -> f32
      cute.memref.store(%rmem_45, %128, %335) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %336 = cute.memref.load(%view, %55) : (!memref_rmem_f32_1, !cute.coord<"76">) -> f32
      cute.memref.store(%rmem_45, %127, %336) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %337 = cute.memref.load(%view, %54) : (!memref_rmem_f32_1, !cute.coord<"77">) -> f32
      cute.memref.store(%rmem_45, %126, %337) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %338 = cute.memref.load(%view, %53) : (!memref_rmem_f32_1, !cute.coord<"78">) -> f32
      cute.memref.store(%rmem_45, %125, %338) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %339 = cute.memref.load(%view, %52) : (!memref_rmem_f32_1, !cute.coord<"79">) -> f32
      cute.memref.store(%rmem_45, %124, %339) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_57 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_58 = cute.get_iter(%rmem_57) : !memref_rmem_f16_
      %340 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %341 = arith.truncf %340 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %341, %rmem_57, row_major : !memref_rmem_f16_
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_58, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_43, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %tup_65 = cute.add_offset(%tup_27, %51) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(0,64)">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
        %e0_66, %e1_67, %e2 = cute.get_leaves(%tup_65) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
        %int_tuple_68 = cute.make_int_tuple(%e0_66, %e1_67, %e2) : (!cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=128},?{div=64},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_68) : !cute.int_tuple<"(?{div=128},?{div=64},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_7 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %342 = cute.memref.load(%view, %50) : (!memref_rmem_f32_1, !cute.coord<"80">) -> f32
      cute.memref.store(%rmem_45, %139, %342) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %343 = cute.memref.load(%view, %49) : (!memref_rmem_f32_1, !cute.coord<"81">) -> f32
      cute.memref.store(%rmem_45, %138, %343) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %344 = cute.memref.load(%view, %48) : (!memref_rmem_f32_1, !cute.coord<"82">) -> f32
      cute.memref.store(%rmem_45, %137, %344) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %345 = cute.memref.load(%view, %47) : (!memref_rmem_f32_1, !cute.coord<"83">) -> f32
      cute.memref.store(%rmem_45, %136, %345) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %346 = cute.memref.load(%view, %46) : (!memref_rmem_f32_1, !cute.coord<"84">) -> f32
      cute.memref.store(%rmem_45, %135, %346) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %347 = cute.memref.load(%view, %45) : (!memref_rmem_f32_1, !cute.coord<"85">) -> f32
      cute.memref.store(%rmem_45, %134, %347) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %348 = cute.memref.load(%view, %44) : (!memref_rmem_f32_1, !cute.coord<"86">) -> f32
      cute.memref.store(%rmem_45, %133, %348) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %349 = cute.memref.load(%view, %43) : (!memref_rmem_f32_1, !cute.coord<"87">) -> f32
      cute.memref.store(%rmem_45, %132, %349) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %350 = cute.memref.load(%view, %42) : (!memref_rmem_f32_1, !cute.coord<"88">) -> f32
      cute.memref.store(%rmem_45, %131, %350) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %351 = cute.memref.load(%view, %41) : (!memref_rmem_f32_1, !cute.coord<"89">) -> f32
      cute.memref.store(%rmem_45, %130, %351) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %352 = cute.memref.load(%view, %40) : (!memref_rmem_f32_1, !cute.coord<"90">) -> f32
      cute.memref.store(%rmem_45, %129, %352) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %353 = cute.memref.load(%view, %39) : (!memref_rmem_f32_1, !cute.coord<"91">) -> f32
      cute.memref.store(%rmem_45, %128, %353) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %354 = cute.memref.load(%view, %38) : (!memref_rmem_f32_1, !cute.coord<"92">) -> f32
      cute.memref.store(%rmem_45, %127, %354) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %355 = cute.memref.load(%view, %37) : (!memref_rmem_f32_1, !cute.coord<"93">) -> f32
      cute.memref.store(%rmem_45, %126, %355) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %356 = cute.memref.load(%view, %36) : (!memref_rmem_f32_1, !cute.coord<"94">) -> f32
      cute.memref.store(%rmem_45, %125, %356) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %357 = cute.memref.load(%view, %35) : (!memref_rmem_f32_1, !cute.coord<"95">) -> f32
      cute.memref.store(%rmem_45, %124, %357) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_59 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_60 = cute.get_iter(%rmem_59) : !memref_rmem_f16_
      %358 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %359 = arith.truncf %358 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %359, %rmem_59, row_major : !memref_rmem_f16_
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_60, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_50, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %105) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %34) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(32,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %360 = cute.memref.load(%view, %33) : (!memref_rmem_f32_1, !cute.coord<"96">) -> f32
      cute.memref.store(%rmem_45, %139, %360) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %361 = cute.memref.load(%view, %32) : (!memref_rmem_f32_1, !cute.coord<"97">) -> f32
      cute.memref.store(%rmem_45, %138, %361) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %362 = cute.memref.load(%view, %31) : (!memref_rmem_f32_1, !cute.coord<"98">) -> f32
      cute.memref.store(%rmem_45, %137, %362) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %363 = cute.memref.load(%view, %30) : (!memref_rmem_f32_1, !cute.coord<"99">) -> f32
      cute.memref.store(%rmem_45, %136, %363) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %364 = cute.memref.load(%view, %29) : (!memref_rmem_f32_1, !cute.coord<"100">) -> f32
      cute.memref.store(%rmem_45, %135, %364) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %365 = cute.memref.load(%view, %28) : (!memref_rmem_f32_1, !cute.coord<"101">) -> f32
      cute.memref.store(%rmem_45, %134, %365) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %366 = cute.memref.load(%view, %27) : (!memref_rmem_f32_1, !cute.coord<"102">) -> f32
      cute.memref.store(%rmem_45, %133, %366) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %367 = cute.memref.load(%view, %26) : (!memref_rmem_f32_1, !cute.coord<"103">) -> f32
      cute.memref.store(%rmem_45, %132, %367) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %368 = cute.memref.load(%view, %25) : (!memref_rmem_f32_1, !cute.coord<"104">) -> f32
      cute.memref.store(%rmem_45, %131, %368) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %369 = cute.memref.load(%view, %24) : (!memref_rmem_f32_1, !cute.coord<"105">) -> f32
      cute.memref.store(%rmem_45, %130, %369) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %370 = cute.memref.load(%view, %23) : (!memref_rmem_f32_1, !cute.coord<"106">) -> f32
      cute.memref.store(%rmem_45, %129, %370) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %371 = cute.memref.load(%view, %22) : (!memref_rmem_f32_1, !cute.coord<"107">) -> f32
      cute.memref.store(%rmem_45, %128, %371) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %372 = cute.memref.load(%view, %21) : (!memref_rmem_f32_1, !cute.coord<"108">) -> f32
      cute.memref.store(%rmem_45, %127, %372) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %373 = cute.memref.load(%view, %20) : (!memref_rmem_f32_1, !cute.coord<"109">) -> f32
      cute.memref.store(%rmem_45, %126, %373) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %374 = cute.memref.load(%view, %19) : (!memref_rmem_f32_1, !cute.coord<"110">) -> f32
      cute.memref.store(%rmem_45, %125, %374) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %375 = cute.memref.load(%view, %18) : (!memref_rmem_f32_1, !cute.coord<"111">) -> f32
      cute.memref.store(%rmem_45, %124, %375) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_61 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_62 = cute.get_iter(%rmem_61) : !memref_rmem_f16_
      %376 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %377 = arith.truncf %376 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %377, %rmem_61, row_major : !memref_rmem_f16_
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_62, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_53, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %87) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"4096">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %17) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(64,64)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      %378 = cute.memref.load(%view, %16) : (!memref_rmem_f32_1, !cute.coord<"112">) -> f32
      cute.memref.store(%rmem_45, %139, %378) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %379 = cute.memref.load(%view, %15) : (!memref_rmem_f32_1, !cute.coord<"113">) -> f32
      cute.memref.store(%rmem_45, %138, %379) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %380 = cute.memref.load(%view, %14) : (!memref_rmem_f32_1, !cute.coord<"114">) -> f32
      cute.memref.store(%rmem_45, %137, %380) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %381 = cute.memref.load(%view, %13) : (!memref_rmem_f32_1, !cute.coord<"115">) -> f32
      cute.memref.store(%rmem_45, %136, %381) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %382 = cute.memref.load(%view, %12) : (!memref_rmem_f32_1, !cute.coord<"116">) -> f32
      cute.memref.store(%rmem_45, %135, %382) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %383 = cute.memref.load(%view, %11) : (!memref_rmem_f32_1, !cute.coord<"117">) -> f32
      cute.memref.store(%rmem_45, %134, %383) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %384 = cute.memref.load(%view, %10) : (!memref_rmem_f32_1, !cute.coord<"118">) -> f32
      cute.memref.store(%rmem_45, %133, %384) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %385 = cute.memref.load(%view, %9) : (!memref_rmem_f32_1, !cute.coord<"119">) -> f32
      cute.memref.store(%rmem_45, %132, %385) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %386 = cute.memref.load(%view, %8) : (!memref_rmem_f32_1, !cute.coord<"120">) -> f32
      cute.memref.store(%rmem_45, %131, %386) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %387 = cute.memref.load(%view, %7) : (!memref_rmem_f32_1, !cute.coord<"121">) -> f32
      cute.memref.store(%rmem_45, %130, %387) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %388 = cute.memref.load(%view, %6) : (!memref_rmem_f32_1, !cute.coord<"122">) -> f32
      cute.memref.store(%rmem_45, %129, %388) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %389 = cute.memref.load(%view, %5) : (!memref_rmem_f32_1, !cute.coord<"123">) -> f32
      cute.memref.store(%rmem_45, %128, %389) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %390 = cute.memref.load(%view, %4) : (!memref_rmem_f32_1, !cute.coord<"124">) -> f32
      cute.memref.store(%rmem_45, %127, %390) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %391 = cute.memref.load(%view, %3) : (!memref_rmem_f32_1, !cute.coord<"125">) -> f32
      cute.memref.store(%rmem_45, %126, %391) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %392 = cute.memref.load(%view, %2) : (!memref_rmem_f32_1, !cute.coord<"126">) -> f32
      cute.memref.store(%rmem_45, %125, %392) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %393 = cute.memref.load(%view, %1) : (!memref_rmem_f32_1, !cute.coord<"127">) -> f32
      cute.memref.store(%rmem_45, %124, %393) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_63 = cute.memref.alloca() : !memref_rmem_f16_
      %iter_64 = cute.get_iter(%rmem_63) : !memref_rmem_f16_
      %394 = cute.memref.load_vec %rmem_45, row_major : !memref_rmem_f32_2
      %395 = arith.truncf %394 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %395, %rmem_63, row_major : !memref_rmem_f16_
      scf.for %arg7 = %c0_i32 to %269 step %c1_i32  : i32 {
        %coord_65 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
        %idx_66 = cute.crd2idx(%coord_65, %123) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((1,2))):(((1,2,4),0),((0,8)))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_67 = cute.add_offset(%iter_64, %idx_66) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
        %idx_68 = cute.crd2idx(%coord_65, %122) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,4),1),((1,2))):(((1,2),0),((0,16)))">) -> !cute.int_tuple<"?{div=16}">
        %ptr_69 = cute.add_offset(%ptr_56, %idx_68) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        %396 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
        %397 = llvm.load %396 : !llvm.ptr -> vector<4xi32>
        %swizzled = cute.apply_swizzle(%ptr_69) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
        cute_nvgpu.arch.copy.stsm(%swizzled, %397) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32} : <f16, smem, align<16>, S<2,4,3>>, vector<4xi32>
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        %ptr_65 = cute.add_offset(%iter_7, %69) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"6144">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
        %tup_66 = cute.add_offset(%tup_27, %0) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(96,64)">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %e0_67, %e1_68, %e2 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %int_tuple_69 = cute.make_int_tuple(%e0_67, %e1_68, %e2) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=64},?)">
        %396 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>
        %397 = cute.get_scalars(%157) : !cute.int_tuple<"1">
        %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%396 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,64,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
        %398:3 = cute.get_scalars(%int_tuple_69) : !cute.int_tuple<"(?{div=32},?{div=64},?)">
        scf.for %arg7 = %c0_i32 to %397 step %c1_i32  : i32 {
          cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_65 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%398#0, %398#1, %398#2] : i32, i32, i32) mode = <tiled>
        } {llvm.loop_annotation = #loop_annotation}
        nvvm.cp.async.bulk.commit.group
        nvvm.cp.async.bulk.wait_group 3 {read}
      }
      nvvm.barrier id = %c1_i32
      scf.if %172 {
        nvvm.cp.async.bulk.wait_group 0 {read}
      }
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
