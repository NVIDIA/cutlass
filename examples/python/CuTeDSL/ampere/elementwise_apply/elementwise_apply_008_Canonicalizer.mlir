!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((64,256),(16,64)):((4096,1),(256,262144))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, align<16>, "((4,16)):((1,4096))">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, align<16>, "((4,16)):((1,?{i64}))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, align<16>, "(4096,4096):(4096,1)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, align<16>, "(?,?):(?{i64},1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((4,16)):((1,4))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_apply_kernel_builtinfunctionadd_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32gmemalign16o_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_1, %arg3: !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 256, 1, 1>} {
      %0 = cute.static : !cute.coord<"63">
      %1 = cute.static : !cute.int_tuple<"(15,3)">
      %2 = cute.static : !cute.coord<"62">
      %3 = cute.static : !cute.int_tuple<"(15,2)">
      %4 = cute.static : !cute.coord<"61">
      %5 = cute.static : !cute.int_tuple<"(15,1)">
      %6 = cute.static : !cute.coord<"60">
      %7 = cute.static : !cute.int_tuple<"(15,0)">
      %8 = cute.static : !cute.coord<"59">
      %9 = cute.static : !cute.int_tuple<"(14,3)">
      %10 = cute.static : !cute.coord<"58">
      %11 = cute.static : !cute.int_tuple<"(14,2)">
      %12 = cute.static : !cute.coord<"57">
      %13 = cute.static : !cute.int_tuple<"(14,1)">
      %14 = cute.static : !cute.coord<"56">
      %15 = cute.static : !cute.int_tuple<"(14,0)">
      %16 = cute.static : !cute.coord<"55">
      %17 = cute.static : !cute.int_tuple<"(13,3)">
      %18 = cute.static : !cute.coord<"54">
      %19 = cute.static : !cute.int_tuple<"(13,2)">
      %20 = cute.static : !cute.coord<"53">
      %21 = cute.static : !cute.int_tuple<"(13,1)">
      %22 = cute.static : !cute.coord<"52">
      %23 = cute.static : !cute.int_tuple<"(13,0)">
      %24 = cute.static : !cute.coord<"51">
      %25 = cute.static : !cute.int_tuple<"(12,3)">
      %26 = cute.static : !cute.coord<"50">
      %27 = cute.static : !cute.int_tuple<"(12,2)">
      %28 = cute.static : !cute.coord<"49">
      %29 = cute.static : !cute.int_tuple<"(12,1)">
      %30 = cute.static : !cute.coord<"48">
      %31 = cute.static : !cute.int_tuple<"(12,0)">
      %32 = cute.static : !cute.coord<"47">
      %33 = cute.static : !cute.int_tuple<"(11,3)">
      %34 = cute.static : !cute.coord<"46">
      %35 = cute.static : !cute.int_tuple<"(11,2)">
      %36 = cute.static : !cute.coord<"45">
      %37 = cute.static : !cute.int_tuple<"(11,1)">
      %38 = cute.static : !cute.coord<"44">
      %39 = cute.static : !cute.int_tuple<"(11,0)">
      %40 = cute.static : !cute.coord<"43">
      %41 = cute.static : !cute.int_tuple<"(10,3)">
      %42 = cute.static : !cute.coord<"42">
      %43 = cute.static : !cute.int_tuple<"(10,2)">
      %44 = cute.static : !cute.coord<"41">
      %45 = cute.static : !cute.int_tuple<"(10,1)">
      %46 = cute.static : !cute.coord<"40">
      %47 = cute.static : !cute.int_tuple<"(10,0)">
      %48 = cute.static : !cute.coord<"39">
      %49 = cute.static : !cute.int_tuple<"(9,3)">
      %50 = cute.static : !cute.coord<"38">
      %51 = cute.static : !cute.int_tuple<"(9,2)">
      %52 = cute.static : !cute.coord<"37">
      %53 = cute.static : !cute.int_tuple<"(9,1)">
      %54 = cute.static : !cute.coord<"36">
      %55 = cute.static : !cute.int_tuple<"(9,0)">
      %56 = cute.static : !cute.coord<"35">
      %57 = cute.static : !cute.int_tuple<"(8,3)">
      %58 = cute.static : !cute.coord<"34">
      %59 = cute.static : !cute.int_tuple<"(8,2)">
      %60 = cute.static : !cute.coord<"33">
      %61 = cute.static : !cute.int_tuple<"(8,1)">
      %62 = cute.static : !cute.coord<"32">
      %63 = cute.static : !cute.int_tuple<"(8,0)">
      %64 = cute.static : !cute.coord<"31">
      %65 = cute.static : !cute.int_tuple<"(7,3)">
      %66 = cute.static : !cute.coord<"30">
      %67 = cute.static : !cute.int_tuple<"(7,2)">
      %68 = cute.static : !cute.coord<"29">
      %69 = cute.static : !cute.int_tuple<"(7,1)">
      %70 = cute.static : !cute.coord<"28">
      %71 = cute.static : !cute.int_tuple<"(7,0)">
      %72 = cute.static : !cute.coord<"27">
      %73 = cute.static : !cute.int_tuple<"(6,3)">
      %74 = cute.static : !cute.coord<"26">
      %75 = cute.static : !cute.int_tuple<"(6,2)">
      %76 = cute.static : !cute.coord<"25">
      %77 = cute.static : !cute.int_tuple<"(6,1)">
      %78 = cute.static : !cute.coord<"24">
      %79 = cute.static : !cute.int_tuple<"(6,0)">
      %80 = cute.static : !cute.coord<"23">
      %81 = cute.static : !cute.int_tuple<"(5,3)">
      %82 = cute.static : !cute.coord<"22">
      %83 = cute.static : !cute.int_tuple<"(5,2)">
      %84 = cute.static : !cute.coord<"21">
      %85 = cute.static : !cute.int_tuple<"(5,1)">
      %86 = cute.static : !cute.coord<"20">
      %87 = cute.static : !cute.int_tuple<"(5,0)">
      %88 = cute.static : !cute.coord<"19">
      %89 = cute.static : !cute.int_tuple<"(4,3)">
      %90 = cute.static : !cute.coord<"18">
      %91 = cute.static : !cute.int_tuple<"(4,2)">
      %92 = cute.static : !cute.coord<"17">
      %93 = cute.static : !cute.int_tuple<"(4,1)">
      %94 = cute.static : !cute.coord<"16">
      %95 = cute.static : !cute.int_tuple<"(4,0)">
      %96 = cute.static : !cute.coord<"15">
      %97 = cute.static : !cute.int_tuple<"(3,3)">
      %98 = cute.static : !cute.coord<"14">
      %99 = cute.static : !cute.int_tuple<"(3,2)">
      %100 = cute.static : !cute.coord<"13">
      %101 = cute.static : !cute.int_tuple<"(3,1)">
      %102 = cute.static : !cute.coord<"12">
      %103 = cute.static : !cute.int_tuple<"(3,0)">
      %104 = cute.static : !cute.coord<"11">
      %105 = cute.static : !cute.int_tuple<"(2,3)">
      %106 = cute.static : !cute.coord<"10">
      %107 = cute.static : !cute.int_tuple<"(2,2)">
      %108 = cute.static : !cute.coord<"9">
      %109 = cute.static : !cute.int_tuple<"(2,1)">
      %110 = cute.static : !cute.coord<"8">
      %111 = cute.static : !cute.int_tuple<"(2,0)">
      %112 = cute.static : !cute.coord<"7">
      %113 = cute.static : !cute.int_tuple<"(1,3)">
      %114 = cute.static : !cute.coord<"6">
      %115 = cute.static : !cute.int_tuple<"(1,2)">
      %116 = cute.static : !cute.coord<"5">
      %117 = cute.static : !cute.int_tuple<"(1,1)">
      %118 = cute.static : !cute.coord<"4">
      %119 = cute.static : !cute.int_tuple<"(1,0)">
      %120 = cute.static : !cute.coord<"3">
      %121 = cute.static : !cute.int_tuple<"(0,3)">
      %122 = cute.static : !cute.coord<"2">
      %123 = cute.static : !cute.int_tuple<"(0,2)">
      %124 = cute.static : !cute.int_tuple<"(0,1)">
      %125 = cute.static : !cute.coord<"0">
      %126 = cute.static : !cute.layout<"((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">
      %127 = cute.static : !cute.shape<"((4,16))">
      %128 = cute.static : !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">
      %129 = cute.static : !cute.coord<"1">
      %130 = cute.static : !cute.shape<"((64,4),(4,16))">
      %c16_i64 = arith.constant 16 : i64
      %131 = cute.static : !cute.int_tuple<"(0,0)">
      %132 = cute.static : !cute.shape<"(64,256)">
      %133 = cute.static : !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">
      %134 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %135 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %136 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %coord = cute.make_coord(%135, %136) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %idx = cute.crd2idx(%coord, %133) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">) -> !cute.int_tuple<"?{div=256}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_0 = cute.make_coord(%135, %136) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %idx_1 = cute.crd2idx(%coord_0, %133) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">) -> !cute.int_tuple<"?{div=256}">
      %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_3 = cute.add_offset(%iter_2, %idx_1) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_4 = cute.make_coord(%135, %136) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay = cute.get_layout(%arg2) : !memref_gmem_f32_1
      %137:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
      %stride = cute.make_stride(%137#4) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_5 = cute.make_layout(%132, %stride) : !cute.layout<"(64,256):(?{i64},1)">
      %idx_6 = cute.crd2idx(%coord_4, %lay) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.int_tuple<"?{i64 div=64}">
      %iter_7 = cute.get_iter(%arg2) : !memref_gmem_f32_1
      %ptr_8 = cute.add_offset(%iter_7, %idx_6) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<f32, gmem, align<16>>
      %coord_9 = cute.make_coord(%135, %136) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_10 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
      %idx_11 = cute.crd2idx(%coord_9, %lay_10) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %tup = cute.add_offset(%131, %idx_11) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %138 = cute.get_scalars(%lay_5) <{only_dynamic}> : !cute.layout<"(64,256):(?{i64},1)">
      %139 = arith.muli %138, %c16_i64 : i64
      %iv = cute.assume(%139) : (i64) -> !cute.i64<divby 16>
      %stride_12 = cute.make_stride(%iv, %138) : (!cute.i64<divby 16>, i64) -> !cute.stride<"((4,?{i64 div=16}),(1,?{i64}))">
      %lay_13 = cute.make_layout(%130, %stride_12) : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %coord_14 = cute.make_coord(%134) : (i32) -> !cute.coord<"(?,_)">
      %idx_15 = cute.crd2idx(%coord_14, %128) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_16 = cute.add_offset(%ptr, %idx_15) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view = cute.make_view(%ptr_16) : !memref_gmem_f32_2
      %coord_17 = cute.make_coord(%134) : (i32) -> !cute.coord<"(?,_)">
      %idx_18 = cute.crd2idx(%coord_17, %128) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_19 = cute.add_offset(%ptr_3, %idx_18) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_20 = cute.make_view(%ptr_19) : !memref_gmem_f32_2
      %coord_21 = cute.make_coord(%134) : (i32) -> !cute.coord<"(?,_)">
      %140:2 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %stride_22 = cute.make_stride(%140#1) : (i64) -> !cute.stride<"((1,?{i64}))">
      %lay_23 = cute.make_layout(%127, %stride_22) : !cute.layout<"((4,16)):((1,?{i64}))">
      %idx_24 = cute.crd2idx(%coord_21, %lay_13) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_25 = cute.add_offset(%ptr_8, %idx_24) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_26 = cute.make_view(%ptr_25, %lay_23) : !memref_gmem_f32_3
      %coord_27 = cute.make_coord(%134) : (i32) -> !cute.coord<"(?,_)">
      %idx_28 = cute.crd2idx(%coord_27, %126) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %tup_29 = cute.add_offset(%tup, %idx_28) : (!cute.int_tuple<"(?{div=64},?{div=256})">, !cute.int_tuple<"(?{div=16},?{div=4})">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %rmem = cute.memref.alloca() : !memref_rmem_i8_
      %e0, %e1 = cute.get_leaves(%tup_29) : !cute.int_tuple<"(?{div=16},?{div=4})">
      %coord_30 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=16},?{div=4})">
      %coord_31 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %141:2 = cute.get_scalars(%coord_30) : !cute.coord<"(?{div=16},?{div=4})">
      %142:2 = cute.get_scalars(%coord_31) : !cute.coord<"(?,?)">
      %143 = arith.cmpi slt, %141#0, %142#0 : i32
      %144 = arith.cmpi slt, %141#1, %142#1 : i32
      %145 = arith.andi %143, %144 : i1
      %146 = arith.extui %145 : i1 to i8
      cute.memref.store(%rmem, %125, %146) : (!memref_rmem_i8_, !cute.coord<"0">, i8) -> ()
      %tup_32 = cute.add_offset(%tup_29, %124) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,1)">) -> !cute.int_tuple<"(?{div=16},?)">
      %e0_33, %e1_34 = cute.get_leaves(%tup_32) : !cute.int_tuple<"(?{div=16},?)">
      %coord_35 = cute.make_coord(%e0_33, %e1_34) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %coord_36 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %147:2 = cute.get_scalars(%coord_35) : !cute.coord<"(?{div=16},?)">
      %148:2 = cute.get_scalars(%coord_36) : !cute.coord<"(?,?)">
      %149 = arith.cmpi slt, %147#0, %148#0 : i32
      %150 = arith.cmpi slt, %147#1, %148#1 : i32
      %151 = arith.andi %149, %150 : i1
      %152 = arith.extui %151 : i1 to i8
      cute.memref.store(%rmem, %129, %152) : (!memref_rmem_i8_, !cute.coord<"1">, i8) -> ()
      %tup_37 = cute.add_offset(%tup_29, %123) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,2)">) -> !cute.int_tuple<"(?{div=16},?{div=2})">
      %e0_38, %e1_39 = cute.get_leaves(%tup_37) : !cute.int_tuple<"(?{div=16},?{div=2})">
      %coord_40 = cute.make_coord(%e0_38, %e1_39) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=16},?{div=2})">
      %coord_41 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %153:2 = cute.get_scalars(%coord_40) : !cute.coord<"(?{div=16},?{div=2})">
      %154:2 = cute.get_scalars(%coord_41) : !cute.coord<"(?,?)">
      %155 = arith.cmpi slt, %153#0, %154#0 : i32
      %156 = arith.cmpi slt, %153#1, %154#1 : i32
      %157 = arith.andi %155, %156 : i1
      %158 = arith.extui %157 : i1 to i8
      cute.memref.store(%rmem, %122, %158) : (!memref_rmem_i8_, !cute.coord<"2">, i8) -> ()
      %tup_42 = cute.add_offset(%tup_29, %121) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,3)">) -> !cute.int_tuple<"(?{div=16},?)">
      %e0_43, %e1_44 = cute.get_leaves(%tup_42) : !cute.int_tuple<"(?{div=16},?)">
      %coord_45 = cute.make_coord(%e0_43, %e1_44) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %coord_46 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %159:2 = cute.get_scalars(%coord_45) : !cute.coord<"(?{div=16},?)">
      %160:2 = cute.get_scalars(%coord_46) : !cute.coord<"(?,?)">
      %161 = arith.cmpi slt, %159#0, %160#0 : i32
      %162 = arith.cmpi slt, %159#1, %160#1 : i32
      %163 = arith.andi %161, %162 : i1
      %164 = arith.extui %163 : i1 to i8
      cute.memref.store(%rmem, %120, %164) : (!memref_rmem_i8_, !cute.coord<"3">, i8) -> ()
      %tup_47 = cute.add_offset(%tup_29, %119) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_48, %e1_49 = cute.get_leaves(%tup_47) : !cute.int_tuple<"(?,?{div=4})">
      %coord_50 = cute.make_coord(%e0_48, %e1_49) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_51 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %165:2 = cute.get_scalars(%coord_50) : !cute.coord<"(?,?{div=4})">
      %166:2 = cute.get_scalars(%coord_51) : !cute.coord<"(?,?)">
      %167 = arith.cmpi slt, %165#0, %166#0 : i32
      %168 = arith.cmpi slt, %165#1, %166#1 : i32
      %169 = arith.andi %167, %168 : i1
      %170 = arith.extui %169 : i1 to i8
      cute.memref.store(%rmem, %118, %170) : (!memref_rmem_i8_, !cute.coord<"4">, i8) -> ()
      %tup_52 = cute.add_offset(%tup_29, %117) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_53, %e1_54 = cute.get_leaves(%tup_52) : !cute.int_tuple<"(?,?)">
      %coord_55 = cute.make_coord(%e0_53, %e1_54) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_56 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %171:2 = cute.get_scalars(%coord_55) : !cute.coord<"(?,?)">
      %172:2 = cute.get_scalars(%coord_56) : !cute.coord<"(?,?)">
      %173 = arith.cmpi slt, %171#0, %172#0 : i32
      %174 = arith.cmpi slt, %171#1, %172#1 : i32
      %175 = arith.andi %173, %174 : i1
      %176 = arith.extui %175 : i1 to i8
      cute.memref.store(%rmem, %116, %176) : (!memref_rmem_i8_, !cute.coord<"5">, i8) -> ()
      %tup_57 = cute.add_offset(%tup_29, %115) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_58, %e1_59 = cute.get_leaves(%tup_57) : !cute.int_tuple<"(?,?{div=2})">
      %coord_60 = cute.make_coord(%e0_58, %e1_59) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_61 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %177:2 = cute.get_scalars(%coord_60) : !cute.coord<"(?,?{div=2})">
      %178:2 = cute.get_scalars(%coord_61) : !cute.coord<"(?,?)">
      %179 = arith.cmpi slt, %177#0, %178#0 : i32
      %180 = arith.cmpi slt, %177#1, %178#1 : i32
      %181 = arith.andi %179, %180 : i1
      %182 = arith.extui %181 : i1 to i8
      cute.memref.store(%rmem, %114, %182) : (!memref_rmem_i8_, !cute.coord<"6">, i8) -> ()
      %tup_62 = cute.add_offset(%tup_29, %113) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_63, %e1_64 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?)">
      %coord_65 = cute.make_coord(%e0_63, %e1_64) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_66 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %183:2 = cute.get_scalars(%coord_65) : !cute.coord<"(?,?)">
      %184:2 = cute.get_scalars(%coord_66) : !cute.coord<"(?,?)">
      %185 = arith.cmpi slt, %183#0, %184#0 : i32
      %186 = arith.cmpi slt, %183#1, %184#1 : i32
      %187 = arith.andi %185, %186 : i1
      %188 = arith.extui %187 : i1 to i8
      cute.memref.store(%rmem, %112, %188) : (!memref_rmem_i8_, !cute.coord<"7">, i8) -> ()
      %tup_67 = cute.add_offset(%tup_29, %111) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_68, %e1_69 = cute.get_leaves(%tup_67) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_70 = cute.make_coord(%e0_68, %e1_69) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_71 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %189:2 = cute.get_scalars(%coord_70) : !cute.coord<"(?{div=2},?{div=4})">
      %190:2 = cute.get_scalars(%coord_71) : !cute.coord<"(?,?)">
      %191 = arith.cmpi slt, %189#0, %190#0 : i32
      %192 = arith.cmpi slt, %189#1, %190#1 : i32
      %193 = arith.andi %191, %192 : i1
      %194 = arith.extui %193 : i1 to i8
      cute.memref.store(%rmem, %110, %194) : (!memref_rmem_i8_, !cute.coord<"8">, i8) -> ()
      %tup_72 = cute.add_offset(%tup_29, %109) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_73, %e1_74 = cute.get_leaves(%tup_72) : !cute.int_tuple<"(?{div=2},?)">
      %coord_75 = cute.make_coord(%e0_73, %e1_74) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_76 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %195:2 = cute.get_scalars(%coord_75) : !cute.coord<"(?{div=2},?)">
      %196:2 = cute.get_scalars(%coord_76) : !cute.coord<"(?,?)">
      %197 = arith.cmpi slt, %195#0, %196#0 : i32
      %198 = arith.cmpi slt, %195#1, %196#1 : i32
      %199 = arith.andi %197, %198 : i1
      %200 = arith.extui %199 : i1 to i8
      cute.memref.store(%rmem, %108, %200) : (!memref_rmem_i8_, !cute.coord<"9">, i8) -> ()
      %tup_77 = cute.add_offset(%tup_29, %107) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_78, %e1_79 = cute.get_leaves(%tup_77) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_80 = cute.make_coord(%e0_78, %e1_79) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_81 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %201:2 = cute.get_scalars(%coord_80) : !cute.coord<"(?{div=2},?{div=2})">
      %202:2 = cute.get_scalars(%coord_81) : !cute.coord<"(?,?)">
      %203 = arith.cmpi slt, %201#0, %202#0 : i32
      %204 = arith.cmpi slt, %201#1, %202#1 : i32
      %205 = arith.andi %203, %204 : i1
      %206 = arith.extui %205 : i1 to i8
      cute.memref.store(%rmem, %106, %206) : (!memref_rmem_i8_, !cute.coord<"10">, i8) -> ()
      %tup_82 = cute.add_offset(%tup_29, %105) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_83, %e1_84 = cute.get_leaves(%tup_82) : !cute.int_tuple<"(?{div=2},?)">
      %coord_85 = cute.make_coord(%e0_83, %e1_84) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_86 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %207:2 = cute.get_scalars(%coord_85) : !cute.coord<"(?{div=2},?)">
      %208:2 = cute.get_scalars(%coord_86) : !cute.coord<"(?,?)">
      %209 = arith.cmpi slt, %207#0, %208#0 : i32
      %210 = arith.cmpi slt, %207#1, %208#1 : i32
      %211 = arith.andi %209, %210 : i1
      %212 = arith.extui %211 : i1 to i8
      cute.memref.store(%rmem, %104, %212) : (!memref_rmem_i8_, !cute.coord<"11">, i8) -> ()
      %tup_87 = cute.add_offset(%tup_29, %103) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_88, %e1_89 = cute.get_leaves(%tup_87) : !cute.int_tuple<"(?,?{div=4})">
      %coord_90 = cute.make_coord(%e0_88, %e1_89) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_91 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %213:2 = cute.get_scalars(%coord_90) : !cute.coord<"(?,?{div=4})">
      %214:2 = cute.get_scalars(%coord_91) : !cute.coord<"(?,?)">
      %215 = arith.cmpi slt, %213#0, %214#0 : i32
      %216 = arith.cmpi slt, %213#1, %214#1 : i32
      %217 = arith.andi %215, %216 : i1
      %218 = arith.extui %217 : i1 to i8
      cute.memref.store(%rmem, %102, %218) : (!memref_rmem_i8_, !cute.coord<"12">, i8) -> ()
      %tup_92 = cute.add_offset(%tup_29, %101) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_93, %e1_94 = cute.get_leaves(%tup_92) : !cute.int_tuple<"(?,?)">
      %coord_95 = cute.make_coord(%e0_93, %e1_94) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_96 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %219:2 = cute.get_scalars(%coord_95) : !cute.coord<"(?,?)">
      %220:2 = cute.get_scalars(%coord_96) : !cute.coord<"(?,?)">
      %221 = arith.cmpi slt, %219#0, %220#0 : i32
      %222 = arith.cmpi slt, %219#1, %220#1 : i32
      %223 = arith.andi %221, %222 : i1
      %224 = arith.extui %223 : i1 to i8
      cute.memref.store(%rmem, %100, %224) : (!memref_rmem_i8_, !cute.coord<"13">, i8) -> ()
      %tup_97 = cute.add_offset(%tup_29, %99) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_98, %e1_99 = cute.get_leaves(%tup_97) : !cute.int_tuple<"(?,?{div=2})">
      %coord_100 = cute.make_coord(%e0_98, %e1_99) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_101 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %225:2 = cute.get_scalars(%coord_100) : !cute.coord<"(?,?{div=2})">
      %226:2 = cute.get_scalars(%coord_101) : !cute.coord<"(?,?)">
      %227 = arith.cmpi slt, %225#0, %226#0 : i32
      %228 = arith.cmpi slt, %225#1, %226#1 : i32
      %229 = arith.andi %227, %228 : i1
      %230 = arith.extui %229 : i1 to i8
      cute.memref.store(%rmem, %98, %230) : (!memref_rmem_i8_, !cute.coord<"14">, i8) -> ()
      %tup_102 = cute.add_offset(%tup_29, %97) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_103, %e1_104 = cute.get_leaves(%tup_102) : !cute.int_tuple<"(?,?)">
      %coord_105 = cute.make_coord(%e0_103, %e1_104) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_106 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %231:2 = cute.get_scalars(%coord_105) : !cute.coord<"(?,?)">
      %232:2 = cute.get_scalars(%coord_106) : !cute.coord<"(?,?)">
      %233 = arith.cmpi slt, %231#0, %232#0 : i32
      %234 = arith.cmpi slt, %231#1, %232#1 : i32
      %235 = arith.andi %233, %234 : i1
      %236 = arith.extui %235 : i1 to i8
      cute.memref.store(%rmem, %96, %236) : (!memref_rmem_i8_, !cute.coord<"15">, i8) -> ()
      %tup_107 = cute.add_offset(%tup_29, %95) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %e0_108, %e1_109 = cute.get_leaves(%tup_107) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_110 = cute.make_coord(%e0_108, %e1_109) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %coord_111 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %237:2 = cute.get_scalars(%coord_110) : !cute.coord<"(?{div=4},?{div=4})">
      %238:2 = cute.get_scalars(%coord_111) : !cute.coord<"(?,?)">
      %239 = arith.cmpi slt, %237#0, %238#0 : i32
      %240 = arith.cmpi slt, %237#1, %238#1 : i32
      %241 = arith.andi %239, %240 : i1
      %242 = arith.extui %241 : i1 to i8
      cute.memref.store(%rmem, %94, %242) : (!memref_rmem_i8_, !cute.coord<"16">, i8) -> ()
      %tup_112 = cute.add_offset(%tup_29, %93) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_113, %e1_114 = cute.get_leaves(%tup_112) : !cute.int_tuple<"(?{div=4},?)">
      %coord_115 = cute.make_coord(%e0_113, %e1_114) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_116 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %243:2 = cute.get_scalars(%coord_115) : !cute.coord<"(?{div=4},?)">
      %244:2 = cute.get_scalars(%coord_116) : !cute.coord<"(?,?)">
      %245 = arith.cmpi slt, %243#0, %244#0 : i32
      %246 = arith.cmpi slt, %243#1, %244#1 : i32
      %247 = arith.andi %245, %246 : i1
      %248 = arith.extui %247 : i1 to i8
      cute.memref.store(%rmem, %92, %248) : (!memref_rmem_i8_, !cute.coord<"17">, i8) -> ()
      %tup_117 = cute.add_offset(%tup_29, %91) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %e0_118, %e1_119 = cute.get_leaves(%tup_117) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_120 = cute.make_coord(%e0_118, %e1_119) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %coord_121 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %249:2 = cute.get_scalars(%coord_120) : !cute.coord<"(?{div=4},?{div=2})">
      %250:2 = cute.get_scalars(%coord_121) : !cute.coord<"(?,?)">
      %251 = arith.cmpi slt, %249#0, %250#0 : i32
      %252 = arith.cmpi slt, %249#1, %250#1 : i32
      %253 = arith.andi %251, %252 : i1
      %254 = arith.extui %253 : i1 to i8
      cute.memref.store(%rmem, %90, %254) : (!memref_rmem_i8_, !cute.coord<"18">, i8) -> ()
      %tup_122 = cute.add_offset(%tup_29, %89) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_123, %e1_124 = cute.get_leaves(%tup_122) : !cute.int_tuple<"(?{div=4},?)">
      %coord_125 = cute.make_coord(%e0_123, %e1_124) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_126 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %255:2 = cute.get_scalars(%coord_125) : !cute.coord<"(?{div=4},?)">
      %256:2 = cute.get_scalars(%coord_126) : !cute.coord<"(?,?)">
      %257 = arith.cmpi slt, %255#0, %256#0 : i32
      %258 = arith.cmpi slt, %255#1, %256#1 : i32
      %259 = arith.andi %257, %258 : i1
      %260 = arith.extui %259 : i1 to i8
      cute.memref.store(%rmem, %88, %260) : (!memref_rmem_i8_, !cute.coord<"19">, i8) -> ()
      %tup_127 = cute.add_offset(%tup_29, %87) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_128, %e1_129 = cute.get_leaves(%tup_127) : !cute.int_tuple<"(?,?{div=4})">
      %coord_130 = cute.make_coord(%e0_128, %e1_129) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_131 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %261:2 = cute.get_scalars(%coord_130) : !cute.coord<"(?,?{div=4})">
      %262:2 = cute.get_scalars(%coord_131) : !cute.coord<"(?,?)">
      %263 = arith.cmpi slt, %261#0, %262#0 : i32
      %264 = arith.cmpi slt, %261#1, %262#1 : i32
      %265 = arith.andi %263, %264 : i1
      %266 = arith.extui %265 : i1 to i8
      cute.memref.store(%rmem, %86, %266) : (!memref_rmem_i8_, !cute.coord<"20">, i8) -> ()
      %tup_132 = cute.add_offset(%tup_29, %85) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_133, %e1_134 = cute.get_leaves(%tup_132) : !cute.int_tuple<"(?,?)">
      %coord_135 = cute.make_coord(%e0_133, %e1_134) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_136 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %267:2 = cute.get_scalars(%coord_135) : !cute.coord<"(?,?)">
      %268:2 = cute.get_scalars(%coord_136) : !cute.coord<"(?,?)">
      %269 = arith.cmpi slt, %267#0, %268#0 : i32
      %270 = arith.cmpi slt, %267#1, %268#1 : i32
      %271 = arith.andi %269, %270 : i1
      %272 = arith.extui %271 : i1 to i8
      cute.memref.store(%rmem, %84, %272) : (!memref_rmem_i8_, !cute.coord<"21">, i8) -> ()
      %tup_137 = cute.add_offset(%tup_29, %83) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_138, %e1_139 = cute.get_leaves(%tup_137) : !cute.int_tuple<"(?,?{div=2})">
      %coord_140 = cute.make_coord(%e0_138, %e1_139) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_141 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %273:2 = cute.get_scalars(%coord_140) : !cute.coord<"(?,?{div=2})">
      %274:2 = cute.get_scalars(%coord_141) : !cute.coord<"(?,?)">
      %275 = arith.cmpi slt, %273#0, %274#0 : i32
      %276 = arith.cmpi slt, %273#1, %274#1 : i32
      %277 = arith.andi %275, %276 : i1
      %278 = arith.extui %277 : i1 to i8
      cute.memref.store(%rmem, %82, %278) : (!memref_rmem_i8_, !cute.coord<"22">, i8) -> ()
      %tup_142 = cute.add_offset(%tup_29, %81) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_143, %e1_144 = cute.get_leaves(%tup_142) : !cute.int_tuple<"(?,?)">
      %coord_145 = cute.make_coord(%e0_143, %e1_144) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_146 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %279:2 = cute.get_scalars(%coord_145) : !cute.coord<"(?,?)">
      %280:2 = cute.get_scalars(%coord_146) : !cute.coord<"(?,?)">
      %281 = arith.cmpi slt, %279#0, %280#0 : i32
      %282 = arith.cmpi slt, %279#1, %280#1 : i32
      %283 = arith.andi %281, %282 : i1
      %284 = arith.extui %283 : i1 to i8
      cute.memref.store(%rmem, %80, %284) : (!memref_rmem_i8_, !cute.coord<"23">, i8) -> ()
      %tup_147 = cute.add_offset(%tup_29, %79) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_148, %e1_149 = cute.get_leaves(%tup_147) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_150 = cute.make_coord(%e0_148, %e1_149) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_151 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %285:2 = cute.get_scalars(%coord_150) : !cute.coord<"(?{div=2},?{div=4})">
      %286:2 = cute.get_scalars(%coord_151) : !cute.coord<"(?,?)">
      %287 = arith.cmpi slt, %285#0, %286#0 : i32
      %288 = arith.cmpi slt, %285#1, %286#1 : i32
      %289 = arith.andi %287, %288 : i1
      %290 = arith.extui %289 : i1 to i8
      cute.memref.store(%rmem, %78, %290) : (!memref_rmem_i8_, !cute.coord<"24">, i8) -> ()
      %tup_152 = cute.add_offset(%tup_29, %77) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_153, %e1_154 = cute.get_leaves(%tup_152) : !cute.int_tuple<"(?{div=2},?)">
      %coord_155 = cute.make_coord(%e0_153, %e1_154) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_156 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %291:2 = cute.get_scalars(%coord_155) : !cute.coord<"(?{div=2},?)">
      %292:2 = cute.get_scalars(%coord_156) : !cute.coord<"(?,?)">
      %293 = arith.cmpi slt, %291#0, %292#0 : i32
      %294 = arith.cmpi slt, %291#1, %292#1 : i32
      %295 = arith.andi %293, %294 : i1
      %296 = arith.extui %295 : i1 to i8
      cute.memref.store(%rmem, %76, %296) : (!memref_rmem_i8_, !cute.coord<"25">, i8) -> ()
      %tup_157 = cute.add_offset(%tup_29, %75) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_158, %e1_159 = cute.get_leaves(%tup_157) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_160 = cute.make_coord(%e0_158, %e1_159) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_161 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %297:2 = cute.get_scalars(%coord_160) : !cute.coord<"(?{div=2},?{div=2})">
      %298:2 = cute.get_scalars(%coord_161) : !cute.coord<"(?,?)">
      %299 = arith.cmpi slt, %297#0, %298#0 : i32
      %300 = arith.cmpi slt, %297#1, %298#1 : i32
      %301 = arith.andi %299, %300 : i1
      %302 = arith.extui %301 : i1 to i8
      cute.memref.store(%rmem, %74, %302) : (!memref_rmem_i8_, !cute.coord<"26">, i8) -> ()
      %tup_162 = cute.add_offset(%tup_29, %73) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_163, %e1_164 = cute.get_leaves(%tup_162) : !cute.int_tuple<"(?{div=2},?)">
      %coord_165 = cute.make_coord(%e0_163, %e1_164) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_166 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %303:2 = cute.get_scalars(%coord_165) : !cute.coord<"(?{div=2},?)">
      %304:2 = cute.get_scalars(%coord_166) : !cute.coord<"(?,?)">
      %305 = arith.cmpi slt, %303#0, %304#0 : i32
      %306 = arith.cmpi slt, %303#1, %304#1 : i32
      %307 = arith.andi %305, %306 : i1
      %308 = arith.extui %307 : i1 to i8
      cute.memref.store(%rmem, %72, %308) : (!memref_rmem_i8_, !cute.coord<"27">, i8) -> ()
      %tup_167 = cute.add_offset(%tup_29, %71) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_168, %e1_169 = cute.get_leaves(%tup_167) : !cute.int_tuple<"(?,?{div=4})">
      %coord_170 = cute.make_coord(%e0_168, %e1_169) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_171 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %309:2 = cute.get_scalars(%coord_170) : !cute.coord<"(?,?{div=4})">
      %310:2 = cute.get_scalars(%coord_171) : !cute.coord<"(?,?)">
      %311 = arith.cmpi slt, %309#0, %310#0 : i32
      %312 = arith.cmpi slt, %309#1, %310#1 : i32
      %313 = arith.andi %311, %312 : i1
      %314 = arith.extui %313 : i1 to i8
      cute.memref.store(%rmem, %70, %314) : (!memref_rmem_i8_, !cute.coord<"28">, i8) -> ()
      %tup_172 = cute.add_offset(%tup_29, %69) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_173, %e1_174 = cute.get_leaves(%tup_172) : !cute.int_tuple<"(?,?)">
      %coord_175 = cute.make_coord(%e0_173, %e1_174) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_176 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %315:2 = cute.get_scalars(%coord_175) : !cute.coord<"(?,?)">
      %316:2 = cute.get_scalars(%coord_176) : !cute.coord<"(?,?)">
      %317 = arith.cmpi slt, %315#0, %316#0 : i32
      %318 = arith.cmpi slt, %315#1, %316#1 : i32
      %319 = arith.andi %317, %318 : i1
      %320 = arith.extui %319 : i1 to i8
      cute.memref.store(%rmem, %68, %320) : (!memref_rmem_i8_, !cute.coord<"29">, i8) -> ()
      %tup_177 = cute.add_offset(%tup_29, %67) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_178, %e1_179 = cute.get_leaves(%tup_177) : !cute.int_tuple<"(?,?{div=2})">
      %coord_180 = cute.make_coord(%e0_178, %e1_179) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_181 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %321:2 = cute.get_scalars(%coord_180) : !cute.coord<"(?,?{div=2})">
      %322:2 = cute.get_scalars(%coord_181) : !cute.coord<"(?,?)">
      %323 = arith.cmpi slt, %321#0, %322#0 : i32
      %324 = arith.cmpi slt, %321#1, %322#1 : i32
      %325 = arith.andi %323, %324 : i1
      %326 = arith.extui %325 : i1 to i8
      cute.memref.store(%rmem, %66, %326) : (!memref_rmem_i8_, !cute.coord<"30">, i8) -> ()
      %tup_182 = cute.add_offset(%tup_29, %65) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_183, %e1_184 = cute.get_leaves(%tup_182) : !cute.int_tuple<"(?,?)">
      %coord_185 = cute.make_coord(%e0_183, %e1_184) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_186 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %327:2 = cute.get_scalars(%coord_185) : !cute.coord<"(?,?)">
      %328:2 = cute.get_scalars(%coord_186) : !cute.coord<"(?,?)">
      %329 = arith.cmpi slt, %327#0, %328#0 : i32
      %330 = arith.cmpi slt, %327#1, %328#1 : i32
      %331 = arith.andi %329, %330 : i1
      %332 = arith.extui %331 : i1 to i8
      cute.memref.store(%rmem, %64, %332) : (!memref_rmem_i8_, !cute.coord<"31">, i8) -> ()
      %tup_187 = cute.add_offset(%tup_29, %63) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,0)">) -> !cute.int_tuple<"(?{div=8},?{div=4})">
      %e0_188, %e1_189 = cute.get_leaves(%tup_187) : !cute.int_tuple<"(?{div=8},?{div=4})">
      %coord_190 = cute.make_coord(%e0_188, %e1_189) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=8},?{div=4})">
      %coord_191 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %333:2 = cute.get_scalars(%coord_190) : !cute.coord<"(?{div=8},?{div=4})">
      %334:2 = cute.get_scalars(%coord_191) : !cute.coord<"(?,?)">
      %335 = arith.cmpi slt, %333#0, %334#0 : i32
      %336 = arith.cmpi slt, %333#1, %334#1 : i32
      %337 = arith.andi %335, %336 : i1
      %338 = arith.extui %337 : i1 to i8
      cute.memref.store(%rmem, %62, %338) : (!memref_rmem_i8_, !cute.coord<"32">, i8) -> ()
      %tup_192 = cute.add_offset(%tup_29, %61) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,1)">) -> !cute.int_tuple<"(?{div=8},?)">
      %e0_193, %e1_194 = cute.get_leaves(%tup_192) : !cute.int_tuple<"(?{div=8},?)">
      %coord_195 = cute.make_coord(%e0_193, %e1_194) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %coord_196 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %339:2 = cute.get_scalars(%coord_195) : !cute.coord<"(?{div=8},?)">
      %340:2 = cute.get_scalars(%coord_196) : !cute.coord<"(?,?)">
      %341 = arith.cmpi slt, %339#0, %340#0 : i32
      %342 = arith.cmpi slt, %339#1, %340#1 : i32
      %343 = arith.andi %341, %342 : i1
      %344 = arith.extui %343 : i1 to i8
      cute.memref.store(%rmem, %60, %344) : (!memref_rmem_i8_, !cute.coord<"33">, i8) -> ()
      %tup_197 = cute.add_offset(%tup_29, %59) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"(?{div=8},?{div=2})">
      %e0_198, %e1_199 = cute.get_leaves(%tup_197) : !cute.int_tuple<"(?{div=8},?{div=2})">
      %coord_200 = cute.make_coord(%e0_198, %e1_199) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=8},?{div=2})">
      %coord_201 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %345:2 = cute.get_scalars(%coord_200) : !cute.coord<"(?{div=8},?{div=2})">
      %346:2 = cute.get_scalars(%coord_201) : !cute.coord<"(?,?)">
      %347 = arith.cmpi slt, %345#0, %346#0 : i32
      %348 = arith.cmpi slt, %345#1, %346#1 : i32
      %349 = arith.andi %347, %348 : i1
      %350 = arith.extui %349 : i1 to i8
      cute.memref.store(%rmem, %58, %350) : (!memref_rmem_i8_, !cute.coord<"34">, i8) -> ()
      %tup_202 = cute.add_offset(%tup_29, %57) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,3)">) -> !cute.int_tuple<"(?{div=8},?)">
      %e0_203, %e1_204 = cute.get_leaves(%tup_202) : !cute.int_tuple<"(?{div=8},?)">
      %coord_205 = cute.make_coord(%e0_203, %e1_204) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %coord_206 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %351:2 = cute.get_scalars(%coord_205) : !cute.coord<"(?{div=8},?)">
      %352:2 = cute.get_scalars(%coord_206) : !cute.coord<"(?,?)">
      %353 = arith.cmpi slt, %351#0, %352#0 : i32
      %354 = arith.cmpi slt, %351#1, %352#1 : i32
      %355 = arith.andi %353, %354 : i1
      %356 = arith.extui %355 : i1 to i8
      cute.memref.store(%rmem, %56, %356) : (!memref_rmem_i8_, !cute.coord<"35">, i8) -> ()
      %tup_207 = cute.add_offset(%tup_29, %55) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_208, %e1_209 = cute.get_leaves(%tup_207) : !cute.int_tuple<"(?,?{div=4})">
      %coord_210 = cute.make_coord(%e0_208, %e1_209) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_211 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %357:2 = cute.get_scalars(%coord_210) : !cute.coord<"(?,?{div=4})">
      %358:2 = cute.get_scalars(%coord_211) : !cute.coord<"(?,?)">
      %359 = arith.cmpi slt, %357#0, %358#0 : i32
      %360 = arith.cmpi slt, %357#1, %358#1 : i32
      %361 = arith.andi %359, %360 : i1
      %362 = arith.extui %361 : i1 to i8
      cute.memref.store(%rmem, %54, %362) : (!memref_rmem_i8_, !cute.coord<"36">, i8) -> ()
      %tup_212 = cute.add_offset(%tup_29, %53) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_213, %e1_214 = cute.get_leaves(%tup_212) : !cute.int_tuple<"(?,?)">
      %coord_215 = cute.make_coord(%e0_213, %e1_214) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_216 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %363:2 = cute.get_scalars(%coord_215) : !cute.coord<"(?,?)">
      %364:2 = cute.get_scalars(%coord_216) : !cute.coord<"(?,?)">
      %365 = arith.cmpi slt, %363#0, %364#0 : i32
      %366 = arith.cmpi slt, %363#1, %364#1 : i32
      %367 = arith.andi %365, %366 : i1
      %368 = arith.extui %367 : i1 to i8
      cute.memref.store(%rmem, %52, %368) : (!memref_rmem_i8_, !cute.coord<"37">, i8) -> ()
      %tup_217 = cute.add_offset(%tup_29, %51) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_218, %e1_219 = cute.get_leaves(%tup_217) : !cute.int_tuple<"(?,?{div=2})">
      %coord_220 = cute.make_coord(%e0_218, %e1_219) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_221 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %369:2 = cute.get_scalars(%coord_220) : !cute.coord<"(?,?{div=2})">
      %370:2 = cute.get_scalars(%coord_221) : !cute.coord<"(?,?)">
      %371 = arith.cmpi slt, %369#0, %370#0 : i32
      %372 = arith.cmpi slt, %369#1, %370#1 : i32
      %373 = arith.andi %371, %372 : i1
      %374 = arith.extui %373 : i1 to i8
      cute.memref.store(%rmem, %50, %374) : (!memref_rmem_i8_, !cute.coord<"38">, i8) -> ()
      %tup_222 = cute.add_offset(%tup_29, %49) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_223, %e1_224 = cute.get_leaves(%tup_222) : !cute.int_tuple<"(?,?)">
      %coord_225 = cute.make_coord(%e0_223, %e1_224) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_226 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %375:2 = cute.get_scalars(%coord_225) : !cute.coord<"(?,?)">
      %376:2 = cute.get_scalars(%coord_226) : !cute.coord<"(?,?)">
      %377 = arith.cmpi slt, %375#0, %376#0 : i32
      %378 = arith.cmpi slt, %375#1, %376#1 : i32
      %379 = arith.andi %377, %378 : i1
      %380 = arith.extui %379 : i1 to i8
      cute.memref.store(%rmem, %48, %380) : (!memref_rmem_i8_, !cute.coord<"39">, i8) -> ()
      %tup_227 = cute.add_offset(%tup_29, %47) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_228, %e1_229 = cute.get_leaves(%tup_227) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_230 = cute.make_coord(%e0_228, %e1_229) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_231 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %381:2 = cute.get_scalars(%coord_230) : !cute.coord<"(?{div=2},?{div=4})">
      %382:2 = cute.get_scalars(%coord_231) : !cute.coord<"(?,?)">
      %383 = arith.cmpi slt, %381#0, %382#0 : i32
      %384 = arith.cmpi slt, %381#1, %382#1 : i32
      %385 = arith.andi %383, %384 : i1
      %386 = arith.extui %385 : i1 to i8
      cute.memref.store(%rmem, %46, %386) : (!memref_rmem_i8_, !cute.coord<"40">, i8) -> ()
      %tup_232 = cute.add_offset(%tup_29, %45) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_233, %e1_234 = cute.get_leaves(%tup_232) : !cute.int_tuple<"(?{div=2},?)">
      %coord_235 = cute.make_coord(%e0_233, %e1_234) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_236 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %387:2 = cute.get_scalars(%coord_235) : !cute.coord<"(?{div=2},?)">
      %388:2 = cute.get_scalars(%coord_236) : !cute.coord<"(?,?)">
      %389 = arith.cmpi slt, %387#0, %388#0 : i32
      %390 = arith.cmpi slt, %387#1, %388#1 : i32
      %391 = arith.andi %389, %390 : i1
      %392 = arith.extui %391 : i1 to i8
      cute.memref.store(%rmem, %44, %392) : (!memref_rmem_i8_, !cute.coord<"41">, i8) -> ()
      %tup_237 = cute.add_offset(%tup_29, %43) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_238, %e1_239 = cute.get_leaves(%tup_237) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_240 = cute.make_coord(%e0_238, %e1_239) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_241 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %393:2 = cute.get_scalars(%coord_240) : !cute.coord<"(?{div=2},?{div=2})">
      %394:2 = cute.get_scalars(%coord_241) : !cute.coord<"(?,?)">
      %395 = arith.cmpi slt, %393#0, %394#0 : i32
      %396 = arith.cmpi slt, %393#1, %394#1 : i32
      %397 = arith.andi %395, %396 : i1
      %398 = arith.extui %397 : i1 to i8
      cute.memref.store(%rmem, %42, %398) : (!memref_rmem_i8_, !cute.coord<"42">, i8) -> ()
      %tup_242 = cute.add_offset(%tup_29, %41) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_243, %e1_244 = cute.get_leaves(%tup_242) : !cute.int_tuple<"(?{div=2},?)">
      %coord_245 = cute.make_coord(%e0_243, %e1_244) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_246 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %399:2 = cute.get_scalars(%coord_245) : !cute.coord<"(?{div=2},?)">
      %400:2 = cute.get_scalars(%coord_246) : !cute.coord<"(?,?)">
      %401 = arith.cmpi slt, %399#0, %400#0 : i32
      %402 = arith.cmpi slt, %399#1, %400#1 : i32
      %403 = arith.andi %401, %402 : i1
      %404 = arith.extui %403 : i1 to i8
      cute.memref.store(%rmem, %40, %404) : (!memref_rmem_i8_, !cute.coord<"43">, i8) -> ()
      %tup_247 = cute.add_offset(%tup_29, %39) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_248, %e1_249 = cute.get_leaves(%tup_247) : !cute.int_tuple<"(?,?{div=4})">
      %coord_250 = cute.make_coord(%e0_248, %e1_249) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_251 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %405:2 = cute.get_scalars(%coord_250) : !cute.coord<"(?,?{div=4})">
      %406:2 = cute.get_scalars(%coord_251) : !cute.coord<"(?,?)">
      %407 = arith.cmpi slt, %405#0, %406#0 : i32
      %408 = arith.cmpi slt, %405#1, %406#1 : i32
      %409 = arith.andi %407, %408 : i1
      %410 = arith.extui %409 : i1 to i8
      cute.memref.store(%rmem, %38, %410) : (!memref_rmem_i8_, !cute.coord<"44">, i8) -> ()
      %tup_252 = cute.add_offset(%tup_29, %37) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_253, %e1_254 = cute.get_leaves(%tup_252) : !cute.int_tuple<"(?,?)">
      %coord_255 = cute.make_coord(%e0_253, %e1_254) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_256 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %411:2 = cute.get_scalars(%coord_255) : !cute.coord<"(?,?)">
      %412:2 = cute.get_scalars(%coord_256) : !cute.coord<"(?,?)">
      %413 = arith.cmpi slt, %411#0, %412#0 : i32
      %414 = arith.cmpi slt, %411#1, %412#1 : i32
      %415 = arith.andi %413, %414 : i1
      %416 = arith.extui %415 : i1 to i8
      cute.memref.store(%rmem, %36, %416) : (!memref_rmem_i8_, !cute.coord<"45">, i8) -> ()
      %tup_257 = cute.add_offset(%tup_29, %35) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_258, %e1_259 = cute.get_leaves(%tup_257) : !cute.int_tuple<"(?,?{div=2})">
      %coord_260 = cute.make_coord(%e0_258, %e1_259) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_261 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %417:2 = cute.get_scalars(%coord_260) : !cute.coord<"(?,?{div=2})">
      %418:2 = cute.get_scalars(%coord_261) : !cute.coord<"(?,?)">
      %419 = arith.cmpi slt, %417#0, %418#0 : i32
      %420 = arith.cmpi slt, %417#1, %418#1 : i32
      %421 = arith.andi %419, %420 : i1
      %422 = arith.extui %421 : i1 to i8
      cute.memref.store(%rmem, %34, %422) : (!memref_rmem_i8_, !cute.coord<"46">, i8) -> ()
      %tup_262 = cute.add_offset(%tup_29, %33) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_263, %e1_264 = cute.get_leaves(%tup_262) : !cute.int_tuple<"(?,?)">
      %coord_265 = cute.make_coord(%e0_263, %e1_264) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_266 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %423:2 = cute.get_scalars(%coord_265) : !cute.coord<"(?,?)">
      %424:2 = cute.get_scalars(%coord_266) : !cute.coord<"(?,?)">
      %425 = arith.cmpi slt, %423#0, %424#0 : i32
      %426 = arith.cmpi slt, %423#1, %424#1 : i32
      %427 = arith.andi %425, %426 : i1
      %428 = arith.extui %427 : i1 to i8
      cute.memref.store(%rmem, %32, %428) : (!memref_rmem_i8_, !cute.coord<"47">, i8) -> ()
      %tup_267 = cute.add_offset(%tup_29, %31) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %e0_268, %e1_269 = cute.get_leaves(%tup_267) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_270 = cute.make_coord(%e0_268, %e1_269) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %coord_271 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %429:2 = cute.get_scalars(%coord_270) : !cute.coord<"(?{div=4},?{div=4})">
      %430:2 = cute.get_scalars(%coord_271) : !cute.coord<"(?,?)">
      %431 = arith.cmpi slt, %429#0, %430#0 : i32
      %432 = arith.cmpi slt, %429#1, %430#1 : i32
      %433 = arith.andi %431, %432 : i1
      %434 = arith.extui %433 : i1 to i8
      cute.memref.store(%rmem, %30, %434) : (!memref_rmem_i8_, !cute.coord<"48">, i8) -> ()
      %tup_272 = cute.add_offset(%tup_29, %29) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_273, %e1_274 = cute.get_leaves(%tup_272) : !cute.int_tuple<"(?{div=4},?)">
      %coord_275 = cute.make_coord(%e0_273, %e1_274) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_276 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %435:2 = cute.get_scalars(%coord_275) : !cute.coord<"(?{div=4},?)">
      %436:2 = cute.get_scalars(%coord_276) : !cute.coord<"(?,?)">
      %437 = arith.cmpi slt, %435#0, %436#0 : i32
      %438 = arith.cmpi slt, %435#1, %436#1 : i32
      %439 = arith.andi %437, %438 : i1
      %440 = arith.extui %439 : i1 to i8
      cute.memref.store(%rmem, %28, %440) : (!memref_rmem_i8_, !cute.coord<"49">, i8) -> ()
      %tup_277 = cute.add_offset(%tup_29, %27) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %e0_278, %e1_279 = cute.get_leaves(%tup_277) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_280 = cute.make_coord(%e0_278, %e1_279) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %coord_281 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %441:2 = cute.get_scalars(%coord_280) : !cute.coord<"(?{div=4},?{div=2})">
      %442:2 = cute.get_scalars(%coord_281) : !cute.coord<"(?,?)">
      %443 = arith.cmpi slt, %441#0, %442#0 : i32
      %444 = arith.cmpi slt, %441#1, %442#1 : i32
      %445 = arith.andi %443, %444 : i1
      %446 = arith.extui %445 : i1 to i8
      cute.memref.store(%rmem, %26, %446) : (!memref_rmem_i8_, !cute.coord<"50">, i8) -> ()
      %tup_282 = cute.add_offset(%tup_29, %25) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_283, %e1_284 = cute.get_leaves(%tup_282) : !cute.int_tuple<"(?{div=4},?)">
      %coord_285 = cute.make_coord(%e0_283, %e1_284) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_286 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %447:2 = cute.get_scalars(%coord_285) : !cute.coord<"(?{div=4},?)">
      %448:2 = cute.get_scalars(%coord_286) : !cute.coord<"(?,?)">
      %449 = arith.cmpi slt, %447#0, %448#0 : i32
      %450 = arith.cmpi slt, %447#1, %448#1 : i32
      %451 = arith.andi %449, %450 : i1
      %452 = arith.extui %451 : i1 to i8
      cute.memref.store(%rmem, %24, %452) : (!memref_rmem_i8_, !cute.coord<"51">, i8) -> ()
      %tup_287 = cute.add_offset(%tup_29, %23) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_288, %e1_289 = cute.get_leaves(%tup_287) : !cute.int_tuple<"(?,?{div=4})">
      %coord_290 = cute.make_coord(%e0_288, %e1_289) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_291 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %453:2 = cute.get_scalars(%coord_290) : !cute.coord<"(?,?{div=4})">
      %454:2 = cute.get_scalars(%coord_291) : !cute.coord<"(?,?)">
      %455 = arith.cmpi slt, %453#0, %454#0 : i32
      %456 = arith.cmpi slt, %453#1, %454#1 : i32
      %457 = arith.andi %455, %456 : i1
      %458 = arith.extui %457 : i1 to i8
      cute.memref.store(%rmem, %22, %458) : (!memref_rmem_i8_, !cute.coord<"52">, i8) -> ()
      %tup_292 = cute.add_offset(%tup_29, %21) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_293, %e1_294 = cute.get_leaves(%tup_292) : !cute.int_tuple<"(?,?)">
      %coord_295 = cute.make_coord(%e0_293, %e1_294) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_296 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %459:2 = cute.get_scalars(%coord_295) : !cute.coord<"(?,?)">
      %460:2 = cute.get_scalars(%coord_296) : !cute.coord<"(?,?)">
      %461 = arith.cmpi slt, %459#0, %460#0 : i32
      %462 = arith.cmpi slt, %459#1, %460#1 : i32
      %463 = arith.andi %461, %462 : i1
      %464 = arith.extui %463 : i1 to i8
      cute.memref.store(%rmem, %20, %464) : (!memref_rmem_i8_, !cute.coord<"53">, i8) -> ()
      %tup_297 = cute.add_offset(%tup_29, %19) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_298, %e1_299 = cute.get_leaves(%tup_297) : !cute.int_tuple<"(?,?{div=2})">
      %coord_300 = cute.make_coord(%e0_298, %e1_299) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_301 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %465:2 = cute.get_scalars(%coord_300) : !cute.coord<"(?,?{div=2})">
      %466:2 = cute.get_scalars(%coord_301) : !cute.coord<"(?,?)">
      %467 = arith.cmpi slt, %465#0, %466#0 : i32
      %468 = arith.cmpi slt, %465#1, %466#1 : i32
      %469 = arith.andi %467, %468 : i1
      %470 = arith.extui %469 : i1 to i8
      cute.memref.store(%rmem, %18, %470) : (!memref_rmem_i8_, !cute.coord<"54">, i8) -> ()
      %tup_302 = cute.add_offset(%tup_29, %17) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_303, %e1_304 = cute.get_leaves(%tup_302) : !cute.int_tuple<"(?,?)">
      %coord_305 = cute.make_coord(%e0_303, %e1_304) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_306 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %471:2 = cute.get_scalars(%coord_305) : !cute.coord<"(?,?)">
      %472:2 = cute.get_scalars(%coord_306) : !cute.coord<"(?,?)">
      %473 = arith.cmpi slt, %471#0, %472#0 : i32
      %474 = arith.cmpi slt, %471#1, %472#1 : i32
      %475 = arith.andi %473, %474 : i1
      %476 = arith.extui %475 : i1 to i8
      cute.memref.store(%rmem, %16, %476) : (!memref_rmem_i8_, !cute.coord<"55">, i8) -> ()
      %tup_307 = cute.add_offset(%tup_29, %15) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_308, %e1_309 = cute.get_leaves(%tup_307) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_310 = cute.make_coord(%e0_308, %e1_309) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_311 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %477:2 = cute.get_scalars(%coord_310) : !cute.coord<"(?{div=2},?{div=4})">
      %478:2 = cute.get_scalars(%coord_311) : !cute.coord<"(?,?)">
      %479 = arith.cmpi slt, %477#0, %478#0 : i32
      %480 = arith.cmpi slt, %477#1, %478#1 : i32
      %481 = arith.andi %479, %480 : i1
      %482 = arith.extui %481 : i1 to i8
      cute.memref.store(%rmem, %14, %482) : (!memref_rmem_i8_, !cute.coord<"56">, i8) -> ()
      %tup_312 = cute.add_offset(%tup_29, %13) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_313, %e1_314 = cute.get_leaves(%tup_312) : !cute.int_tuple<"(?{div=2},?)">
      %coord_315 = cute.make_coord(%e0_313, %e1_314) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_316 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %483:2 = cute.get_scalars(%coord_315) : !cute.coord<"(?{div=2},?)">
      %484:2 = cute.get_scalars(%coord_316) : !cute.coord<"(?,?)">
      %485 = arith.cmpi slt, %483#0, %484#0 : i32
      %486 = arith.cmpi slt, %483#1, %484#1 : i32
      %487 = arith.andi %485, %486 : i1
      %488 = arith.extui %487 : i1 to i8
      cute.memref.store(%rmem, %12, %488) : (!memref_rmem_i8_, !cute.coord<"57">, i8) -> ()
      %tup_317 = cute.add_offset(%tup_29, %11) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_318, %e1_319 = cute.get_leaves(%tup_317) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_320 = cute.make_coord(%e0_318, %e1_319) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_321 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %489:2 = cute.get_scalars(%coord_320) : !cute.coord<"(?{div=2},?{div=2})">
      %490:2 = cute.get_scalars(%coord_321) : !cute.coord<"(?,?)">
      %491 = arith.cmpi slt, %489#0, %490#0 : i32
      %492 = arith.cmpi slt, %489#1, %490#1 : i32
      %493 = arith.andi %491, %492 : i1
      %494 = arith.extui %493 : i1 to i8
      cute.memref.store(%rmem, %10, %494) : (!memref_rmem_i8_, !cute.coord<"58">, i8) -> ()
      %tup_322 = cute.add_offset(%tup_29, %9) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_323, %e1_324 = cute.get_leaves(%tup_322) : !cute.int_tuple<"(?{div=2},?)">
      %coord_325 = cute.make_coord(%e0_323, %e1_324) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_326 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %495:2 = cute.get_scalars(%coord_325) : !cute.coord<"(?{div=2},?)">
      %496:2 = cute.get_scalars(%coord_326) : !cute.coord<"(?,?)">
      %497 = arith.cmpi slt, %495#0, %496#0 : i32
      %498 = arith.cmpi slt, %495#1, %496#1 : i32
      %499 = arith.andi %497, %498 : i1
      %500 = arith.extui %499 : i1 to i8
      cute.memref.store(%rmem, %8, %500) : (!memref_rmem_i8_, !cute.coord<"59">, i8) -> ()
      %tup_327 = cute.add_offset(%tup_29, %7) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_328, %e1_329 = cute.get_leaves(%tup_327) : !cute.int_tuple<"(?,?{div=4})">
      %coord_330 = cute.make_coord(%e0_328, %e1_329) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_331 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %501:2 = cute.get_scalars(%coord_330) : !cute.coord<"(?,?{div=4})">
      %502:2 = cute.get_scalars(%coord_331) : !cute.coord<"(?,?)">
      %503 = arith.cmpi slt, %501#0, %502#0 : i32
      %504 = arith.cmpi slt, %501#1, %502#1 : i32
      %505 = arith.andi %503, %504 : i1
      %506 = arith.extui %505 : i1 to i8
      cute.memref.store(%rmem, %6, %506) : (!memref_rmem_i8_, !cute.coord<"60">, i8) -> ()
      %tup_332 = cute.add_offset(%tup_29, %5) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_333, %e1_334 = cute.get_leaves(%tup_332) : !cute.int_tuple<"(?,?)">
      %coord_335 = cute.make_coord(%e0_333, %e1_334) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_336 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %507:2 = cute.get_scalars(%coord_335) : !cute.coord<"(?,?)">
      %508:2 = cute.get_scalars(%coord_336) : !cute.coord<"(?,?)">
      %509 = arith.cmpi slt, %507#0, %508#0 : i32
      %510 = arith.cmpi slt, %507#1, %508#1 : i32
      %511 = arith.andi %509, %510 : i1
      %512 = arith.extui %511 : i1 to i8
      cute.memref.store(%rmem, %4, %512) : (!memref_rmem_i8_, !cute.coord<"61">, i8) -> ()
      %tup_337 = cute.add_offset(%tup_29, %3) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_338, %e1_339 = cute.get_leaves(%tup_337) : !cute.int_tuple<"(?,?{div=2})">
      %coord_340 = cute.make_coord(%e0_338, %e1_339) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_341 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %513:2 = cute.get_scalars(%coord_340) : !cute.coord<"(?,?{div=2})">
      %514:2 = cute.get_scalars(%coord_341) : !cute.coord<"(?,?)">
      %515 = arith.cmpi slt, %513#0, %514#0 : i32
      %516 = arith.cmpi slt, %513#1, %514#1 : i32
      %517 = arith.andi %515, %516 : i1
      %518 = arith.extui %517 : i1 to i8
      cute.memref.store(%rmem, %2, %518) : (!memref_rmem_i8_, !cute.coord<"62">, i8) -> ()
      %tup_342 = cute.add_offset(%tup_29, %1) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_343, %e1_344 = cute.get_leaves(%tup_342) : !cute.int_tuple<"(?,?)">
      %coord_345 = cute.make_coord(%e0_343, %e1_344) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_346 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %519:2 = cute.get_scalars(%coord_345) : !cute.coord<"(?,?)">
      %520:2 = cute.get_scalars(%coord_346) : !cute.coord<"(?,?)">
      %521 = arith.cmpi slt, %519#0, %520#0 : i32
      %522 = arith.cmpi slt, %519#1, %520#1 : i32
      %523 = arith.andi %521, %522 : i1
      %524 = arith.extui %523 : i1 to i8
      cute.memref.store(%rmem, %0, %524) : (!memref_rmem_i8_, !cute.coord<"63">, i8) -> ()
      %525 = cute.memref.load_vec %view : !memref_gmem_f32_2
      %526 = cute.memref.load_vec %view_20 : !memref_gmem_f32_2
      %527 = arith.addf %525, %526 : vector<64xf32>
      cute.memref.store_vec %527, %view_26 : !memref_gmem_f32_3
      return
    }
  }
  func.func @cutlass_elementwise_apply_builtinfunctionadd_Tensorgmem_o_4096409640961_Tensorgmem_o_4096409640961_Tensorgmemoi641_CUstream(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_5, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c0_i64 = arith.constant 0 : i64
    %0 = cute.static : !cute.stride<"((1@0,1@1),(64@0,256@1))">
    %1 = cute.static : !cute.stride<"(1@0,1@1)">
    %2 = cute.static : !cute.int_tuple<"(0,0)">
    %c16_i32 = arith.constant 16 : i32
    %c-1_i32 = arith.constant -1 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %c256_i32 = arith.constant 256 : i32
    %c64_i64 = arith.constant 64 : i64
    %c64_i32 = arith.constant 64 : i32
    %3 = cute.static : !cute.layout<"(16,16):(16,1)">
    %4 = cute.recast_layout<32, 8> (%3) : !cute.layout<"(16,16):(16,1)"> to !cute.layout<"(16,4):(4,1)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %5:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %6 = arith.ceildivsi %5#0, %c64_i32 : i32
    %7 = arith.muli %5#2, %c64_i64 : i64
    %8 = arith.ceildivsi %5#1, %c256_i32 : i32
    %shape = cute.make_shape(%6, %8) : (i32, i32) -> !cute.shape<"((64,256),(?,?))">
    %iv = cute.assume(%7) : (i64) -> !cute.i64<divby 64>
    %stride = cute.make_stride(%5#2, %iv) : (i64, !cute.i64<divby 64>) -> !cute.stride<"((?{i64},1),(?{i64 div=64},256))">
    %lay_2 = cute.make_layout(%shape, %stride) : !cute.layout<"((64,256),(?,?)):((?{i64},1),(?{i64 div=64},256))">
    %view = cute.make_view(%iter) : !memref_gmem_f32_
    %view_3 = cute.make_view(%iter_0) : !memref_gmem_f32_
    %9:4 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"((64,256),(?,?)):((?{i64},1),(?{i64 div=64},256))">
    %10 = arith.divsi %9#0, %c64_i32 : i32
    %11 = arith.cmpi ne, %10, %c0_i32 : i32
    %12 = scf.if %11 -> (i32) {
      scf.yield %10 : i32
    } else {
      %49 = arith.cmpi sgt, %9#0, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %9#0, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %13 = arith.minsi %12, %c16_i32 : i32
    %14 = arith.muli %9#3, %c64_i64 : i64
    %15 = math.absi %12 : i32
    %16 = arith.divsi %c16_i32, %15 : i32
    %17 = arith.cmpi ne, %16, %c0_i32 : i32
    %18 = scf.if %17 -> (i32) {
      scf.yield %16 : i32
    } else {
      %49 = arith.cmpi sgt, %15, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %15, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %19 = arith.divsi %c64_i32, %9#0 : i32
    %20 = arith.cmpi ne, %19, %c0_i32 : i32
    %21 = scf.if %20 -> (i32) {
      scf.yield %19 : i32
    } else {
      %49 = arith.cmpi sgt, %9#0, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %9#0, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %22 = arith.muli %21, %c256_i32 : i32
    %23 = arith.cmpi ne, %9#0, %c0_i32 : i32
    %24 = scf.if %23 -> (i32) {
      scf.yield %9#0 : i32
    } else {
      %49 = arith.cmpi sgt, %9#0, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %9#0, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %25 = arith.minsi %24, %c64_i32 : i32
    %26 = math.absi %24 : i32
    %27 = arith.divsi %c64_i32, %26 : i32
    %28 = arith.cmpi ne, %27, %c0_i32 : i32
    %29 = scf.if %28 -> (i32) {
      scf.yield %27 : i32
    } else {
      %49 = arith.cmpi sgt, %26, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %26, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %30 = arith.divsi %c1_i32, %9#0 : i32
    %31 = arith.cmpi ne, %30, %c0_i32 : i32
    %32 = scf.if %31 -> (i32) {
      scf.yield %30 : i32
    } else {
      %49 = arith.cmpi sgt, %9#0, %c0_i32 : i32
      %50 = scf.if %49 -> (i32) {
        scf.yield %c1_i32 : i32
      } else {
        %51 = arith.cmpi eq, %9#0, %c0_i32 : i32
        %52 = arith.select %51, %c0_i32, %c-1_i32 : i32
        scf.yield %52 : i32
      }
      scf.yield %50 : i32
    }
    %33 = arith.muli %32, %c256_i32 : i32
    %shape_4 = cute.make_shape(%13, %18, %25, %29) : (i32, i32, i32, i32) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %iv_5 = cute.assume(%14) : (i64) -> !cute.i64<divby 4096>
    %iv_6 = cute.assume(%22) : (i32) -> !cute.i32<divby 256>
    %iv_7 = cute.assume(%9#3) : (i64) -> !cute.i64<divby 64>
    %iv_8 = cute.assume(%33) : (i32) -> !cute.i32<divby 256>
    %stride_9 = cute.make_stride(%9#2, %iv_5, %iv_6, %iv_7, %iv_8) : (i64, !cute.i64<divby 4096>, !cute.i32<divby 256>, !cute.i64<divby 64>, !cute.i32<divby 256>) -> !cute.stride<"((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %lay_10 = cute.make_layout(%shape_4, %stride_9) : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %view_11 = cute.make_view(%iter_1, %lay_10) : !memref_gmem_f32_1
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %34 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%34) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %35 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_13 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
    %shape_14 = cute.make_shape(%itup, %itup_13) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %lay_15 = cute.make_layout(%shape_14, %1) : !cute.layout<"(?,?):(1@0,1@1)">
    %37:2 = cute.get_scalars(%lay_15) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %38 = arith.ceildivsi %37#0, %c64_i32 : i32
    %39 = arith.ceildivsi %37#1, %c256_i32 : i32
    %shape_16 = cute.make_shape(%38, %39) : (i32, i32) -> !cute.shape<"((64,256),(?,?))">
    %lay_17 = cute.make_layout(%shape_16, %0) : !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %view_18 = cute.make_view(%2, %lay_17) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %40 = cute.get_shape(%lay_10) : (!cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %e0_19, %e1_20, %e2, %e3, %e4, %e5 = cute.get_leaves(%40) : !cute.shape<"((64,256),((?,?),(?,?)))">
    %itup_21 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_22 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_23 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_24 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup_21, %itup_22, %itup_23, %itup_24) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"((?,?),(?,?))">
    %41:4 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"((?,?),(?,?))">
    %42 = arith.muli %41#0, %41#1 : i32
    %43 = arith.muli %41#2, %41#3 : i32
    %int_tuple_25 = cute.make_int_tuple(%42, %43) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %e0_26, %e1_27 = cute.get_leaves(%int_tuple_25) : !cute.int_tuple<"(?,?)">
    %44 = cute.get_scalars(%e0_26) : !cute.int_tuple<"?">
    %45 = cute.get_scalars(%e1_27) : !cute.int_tuple<"?">
    %46 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c256_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%44, %45, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %47 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_apply_kernel_builtinfunctionadd_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32gmemalign16o_0<%46> (%view, %view_3, %view_11, %view_18, %35, %36) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_1, !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">, i32, i32) -> !cuda.result
    %48 = cuda.cast %47 : !cuda.result -> i32
    cuda.return_if_error %48 : i32
    return %c0_i32 : i32
  }
}
