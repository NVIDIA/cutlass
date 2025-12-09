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
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_1 = cute.add_offset(%iter_0, %idx) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<f32, gmem, align<16>>
      %lay = cute.get_layout(%arg2) : !memref_gmem_f32_1
      %137:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
      %stride = cute.make_stride(%137#4) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_2 = cute.make_layout(%132, %stride) : !cute.layout<"(64,256):(?{i64},1)">
      %idx_3 = cute.crd2idx(%coord, %lay) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.int_tuple<"?{i64 div=64}">
      %iter_4 = cute.get_iter(%arg2) : !memref_gmem_f32_1
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<f32, gmem, align<16>>
      %lay_6 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
      %idx_7 = cute.crd2idx(%coord, %lay_6) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %tup = cute.add_offset(%131, %idx_7) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %138 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(64,256):(?{i64},1)">
      %139 = arith.muli %138, %c16_i64 : i64
      %iv = cute.assume(%139) : (i64) -> !cute.i64<divby 16>
      %stride_8 = cute.make_stride(%iv, %138) : (!cute.i64<divby 16>, i64) -> !cute.stride<"((4,?{i64 div=16}),(1,?{i64}))">
      %lay_9 = cute.make_layout(%130, %stride_8) : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %coord_10 = cute.make_coord(%134) : (i32) -> !cute.coord<"(?,_)">
      %idx_11 = cute.crd2idx(%coord_10, %128) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">) -> !cute.int_tuple<"?{div=4}">
      %ptr_12 = cute.add_offset(%ptr, %idx_11) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view = cute.make_view(%ptr_12) : !memref_gmem_f32_2
      %ptr_13 = cute.add_offset(%ptr_1, %idx_11) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_14 = cute.make_view(%ptr_13) : !memref_gmem_f32_2
      %140:2 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %stride_15 = cute.make_stride(%140#1) : (i64) -> !cute.stride<"((1,?{i64}))">
      %lay_16 = cute.make_layout(%127, %stride_15) : !cute.layout<"((4,16)):((1,?{i64}))">
      %idx_17 = cute.crd2idx(%coord_10, %lay_9) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_18 = cute.add_offset(%ptr_5, %idx_17) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_19 = cute.make_view(%ptr_18, %lay_16) : !memref_gmem_f32_3
      %idx_20 = cute.crd2idx(%coord_10, %126) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %tup_21 = cute.add_offset(%tup, %idx_20) : (!cute.int_tuple<"(?{div=64},?{div=256})">, !cute.int_tuple<"(?{div=16},?{div=4})">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %rmem = cute.memref.alloca() : !memref_rmem_i8_
      %e0, %e1 = cute.get_leaves(%tup_21) : !cute.int_tuple<"(?{div=16},?{div=4})">
      %coord_22 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=16},?{div=4})">
      %coord_23 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %141:2 = cute.get_scalars(%coord_22) : !cute.coord<"(?{div=16},?{div=4})">
      %142:2 = cute.get_scalars(%coord_23) : !cute.coord<"(?,?)">
      %143 = arith.cmpi slt, %141#0, %142#0 : i32
      %144 = arith.cmpi slt, %141#1, %142#1 : i32
      %145 = arith.andi %143, %144 : i1
      %146 = arith.extui %145 : i1 to i8
      cute.memref.store(%rmem, %125, %146) : (!memref_rmem_i8_, !cute.coord<"0">, i8) -> ()
      %tup_24 = cute.add_offset(%tup_21, %124) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,1)">) -> !cute.int_tuple<"(?{div=16},?)">
      %e0_25, %e1_26 = cute.get_leaves(%tup_24) : !cute.int_tuple<"(?{div=16},?)">
      %coord_27 = cute.make_coord(%e0_25, %e1_26) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %147:2 = cute.get_scalars(%coord_27) : !cute.coord<"(?{div=16},?)">
      %148 = arith.cmpi slt, %147#0, %142#0 : i32
      %149 = arith.cmpi slt, %147#1, %142#1 : i32
      %150 = arith.andi %148, %149 : i1
      %151 = arith.extui %150 : i1 to i8
      cute.memref.store(%rmem, %129, %151) : (!memref_rmem_i8_, !cute.coord<"1">, i8) -> ()
      %tup_28 = cute.add_offset(%tup_21, %123) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,2)">) -> !cute.int_tuple<"(?{div=16},?{div=2})">
      %e0_29, %e1_30 = cute.get_leaves(%tup_28) : !cute.int_tuple<"(?{div=16},?{div=2})">
      %coord_31 = cute.make_coord(%e0_29, %e1_30) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=16},?{div=2})">
      %152:2 = cute.get_scalars(%coord_31) : !cute.coord<"(?{div=16},?{div=2})">
      %153 = arith.cmpi slt, %152#0, %142#0 : i32
      %154 = arith.cmpi slt, %152#1, %142#1 : i32
      %155 = arith.andi %153, %154 : i1
      %156 = arith.extui %155 : i1 to i8
      cute.memref.store(%rmem, %122, %156) : (!memref_rmem_i8_, !cute.coord<"2">, i8) -> ()
      %tup_32 = cute.add_offset(%tup_21, %121) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,3)">) -> !cute.int_tuple<"(?{div=16},?)">
      %e0_33, %e1_34 = cute.get_leaves(%tup_32) : !cute.int_tuple<"(?{div=16},?)">
      %coord_35 = cute.make_coord(%e0_33, %e1_34) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %157:2 = cute.get_scalars(%coord_35) : !cute.coord<"(?{div=16},?)">
      %158 = arith.cmpi slt, %157#0, %142#0 : i32
      %159 = arith.cmpi slt, %157#1, %142#1 : i32
      %160 = arith.andi %158, %159 : i1
      %161 = arith.extui %160 : i1 to i8
      cute.memref.store(%rmem, %120, %161) : (!memref_rmem_i8_, !cute.coord<"3">, i8) -> ()
      %tup_36 = cute.add_offset(%tup_21, %119) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_37, %e1_38 = cute.get_leaves(%tup_36) : !cute.int_tuple<"(?,?{div=4})">
      %coord_39 = cute.make_coord(%e0_37, %e1_38) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %162:2 = cute.get_scalars(%coord_39) : !cute.coord<"(?,?{div=4})">
      %163 = arith.cmpi slt, %162#0, %142#0 : i32
      %164 = arith.cmpi slt, %162#1, %142#1 : i32
      %165 = arith.andi %163, %164 : i1
      %166 = arith.extui %165 : i1 to i8
      cute.memref.store(%rmem, %118, %166) : (!memref_rmem_i8_, !cute.coord<"4">, i8) -> ()
      %tup_40 = cute.add_offset(%tup_21, %117) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_41, %e1_42 = cute.get_leaves(%tup_40) : !cute.int_tuple<"(?,?)">
      %coord_43 = cute.make_coord(%e0_41, %e1_42) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %167:2 = cute.get_scalars(%coord_43) : !cute.coord<"(?,?)">
      %168 = arith.cmpi slt, %167#0, %142#0 : i32
      %169 = arith.cmpi slt, %167#1, %142#1 : i32
      %170 = arith.andi %168, %169 : i1
      %171 = arith.extui %170 : i1 to i8
      cute.memref.store(%rmem, %116, %171) : (!memref_rmem_i8_, !cute.coord<"5">, i8) -> ()
      %tup_44 = cute.add_offset(%tup_21, %115) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_45, %e1_46 = cute.get_leaves(%tup_44) : !cute.int_tuple<"(?,?{div=2})">
      %coord_47 = cute.make_coord(%e0_45, %e1_46) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %172:2 = cute.get_scalars(%coord_47) : !cute.coord<"(?,?{div=2})">
      %173 = arith.cmpi slt, %172#0, %142#0 : i32
      %174 = arith.cmpi slt, %172#1, %142#1 : i32
      %175 = arith.andi %173, %174 : i1
      %176 = arith.extui %175 : i1 to i8
      cute.memref.store(%rmem, %114, %176) : (!memref_rmem_i8_, !cute.coord<"6">, i8) -> ()
      %tup_48 = cute.add_offset(%tup_21, %113) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_49, %e1_50 = cute.get_leaves(%tup_48) : !cute.int_tuple<"(?,?)">
      %coord_51 = cute.make_coord(%e0_49, %e1_50) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %177:2 = cute.get_scalars(%coord_51) : !cute.coord<"(?,?)">
      %178 = arith.cmpi slt, %177#0, %142#0 : i32
      %179 = arith.cmpi slt, %177#1, %142#1 : i32
      %180 = arith.andi %178, %179 : i1
      %181 = arith.extui %180 : i1 to i8
      cute.memref.store(%rmem, %112, %181) : (!memref_rmem_i8_, !cute.coord<"7">, i8) -> ()
      %tup_52 = cute.add_offset(%tup_21, %111) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_53, %e1_54 = cute.get_leaves(%tup_52) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_55 = cute.make_coord(%e0_53, %e1_54) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %182:2 = cute.get_scalars(%coord_55) : !cute.coord<"(?{div=2},?{div=4})">
      %183 = arith.cmpi slt, %182#0, %142#0 : i32
      %184 = arith.cmpi slt, %182#1, %142#1 : i32
      %185 = arith.andi %183, %184 : i1
      %186 = arith.extui %185 : i1 to i8
      cute.memref.store(%rmem, %110, %186) : (!memref_rmem_i8_, !cute.coord<"8">, i8) -> ()
      %tup_56 = cute.add_offset(%tup_21, %109) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_57, %e1_58 = cute.get_leaves(%tup_56) : !cute.int_tuple<"(?{div=2},?)">
      %coord_59 = cute.make_coord(%e0_57, %e1_58) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %187:2 = cute.get_scalars(%coord_59) : !cute.coord<"(?{div=2},?)">
      %188 = arith.cmpi slt, %187#0, %142#0 : i32
      %189 = arith.cmpi slt, %187#1, %142#1 : i32
      %190 = arith.andi %188, %189 : i1
      %191 = arith.extui %190 : i1 to i8
      cute.memref.store(%rmem, %108, %191) : (!memref_rmem_i8_, !cute.coord<"9">, i8) -> ()
      %tup_60 = cute.add_offset(%tup_21, %107) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_61, %e1_62 = cute.get_leaves(%tup_60) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_63 = cute.make_coord(%e0_61, %e1_62) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %192:2 = cute.get_scalars(%coord_63) : !cute.coord<"(?{div=2},?{div=2})">
      %193 = arith.cmpi slt, %192#0, %142#0 : i32
      %194 = arith.cmpi slt, %192#1, %142#1 : i32
      %195 = arith.andi %193, %194 : i1
      %196 = arith.extui %195 : i1 to i8
      cute.memref.store(%rmem, %106, %196) : (!memref_rmem_i8_, !cute.coord<"10">, i8) -> ()
      %tup_64 = cute.add_offset(%tup_21, %105) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_65, %e1_66 = cute.get_leaves(%tup_64) : !cute.int_tuple<"(?{div=2},?)">
      %coord_67 = cute.make_coord(%e0_65, %e1_66) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %197:2 = cute.get_scalars(%coord_67) : !cute.coord<"(?{div=2},?)">
      %198 = arith.cmpi slt, %197#0, %142#0 : i32
      %199 = arith.cmpi slt, %197#1, %142#1 : i32
      %200 = arith.andi %198, %199 : i1
      %201 = arith.extui %200 : i1 to i8
      cute.memref.store(%rmem, %104, %201) : (!memref_rmem_i8_, !cute.coord<"11">, i8) -> ()
      %tup_68 = cute.add_offset(%tup_21, %103) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_69, %e1_70 = cute.get_leaves(%tup_68) : !cute.int_tuple<"(?,?{div=4})">
      %coord_71 = cute.make_coord(%e0_69, %e1_70) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %202:2 = cute.get_scalars(%coord_71) : !cute.coord<"(?,?{div=4})">
      %203 = arith.cmpi slt, %202#0, %142#0 : i32
      %204 = arith.cmpi slt, %202#1, %142#1 : i32
      %205 = arith.andi %203, %204 : i1
      %206 = arith.extui %205 : i1 to i8
      cute.memref.store(%rmem, %102, %206) : (!memref_rmem_i8_, !cute.coord<"12">, i8) -> ()
      %tup_72 = cute.add_offset(%tup_21, %101) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_73, %e1_74 = cute.get_leaves(%tup_72) : !cute.int_tuple<"(?,?)">
      %coord_75 = cute.make_coord(%e0_73, %e1_74) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %207:2 = cute.get_scalars(%coord_75) : !cute.coord<"(?,?)">
      %208 = arith.cmpi slt, %207#0, %142#0 : i32
      %209 = arith.cmpi slt, %207#1, %142#1 : i32
      %210 = arith.andi %208, %209 : i1
      %211 = arith.extui %210 : i1 to i8
      cute.memref.store(%rmem, %100, %211) : (!memref_rmem_i8_, !cute.coord<"13">, i8) -> ()
      %tup_76 = cute.add_offset(%tup_21, %99) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_77, %e1_78 = cute.get_leaves(%tup_76) : !cute.int_tuple<"(?,?{div=2})">
      %coord_79 = cute.make_coord(%e0_77, %e1_78) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %212:2 = cute.get_scalars(%coord_79) : !cute.coord<"(?,?{div=2})">
      %213 = arith.cmpi slt, %212#0, %142#0 : i32
      %214 = arith.cmpi slt, %212#1, %142#1 : i32
      %215 = arith.andi %213, %214 : i1
      %216 = arith.extui %215 : i1 to i8
      cute.memref.store(%rmem, %98, %216) : (!memref_rmem_i8_, !cute.coord<"14">, i8) -> ()
      %tup_80 = cute.add_offset(%tup_21, %97) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_81, %e1_82 = cute.get_leaves(%tup_80) : !cute.int_tuple<"(?,?)">
      %coord_83 = cute.make_coord(%e0_81, %e1_82) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %217:2 = cute.get_scalars(%coord_83) : !cute.coord<"(?,?)">
      %218 = arith.cmpi slt, %217#0, %142#0 : i32
      %219 = arith.cmpi slt, %217#1, %142#1 : i32
      %220 = arith.andi %218, %219 : i1
      %221 = arith.extui %220 : i1 to i8
      cute.memref.store(%rmem, %96, %221) : (!memref_rmem_i8_, !cute.coord<"15">, i8) -> ()
      %tup_84 = cute.add_offset(%tup_21, %95) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %e0_85, %e1_86 = cute.get_leaves(%tup_84) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_87 = cute.make_coord(%e0_85, %e1_86) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %222:2 = cute.get_scalars(%coord_87) : !cute.coord<"(?{div=4},?{div=4})">
      %223 = arith.cmpi slt, %222#0, %142#0 : i32
      %224 = arith.cmpi slt, %222#1, %142#1 : i32
      %225 = arith.andi %223, %224 : i1
      %226 = arith.extui %225 : i1 to i8
      cute.memref.store(%rmem, %94, %226) : (!memref_rmem_i8_, !cute.coord<"16">, i8) -> ()
      %tup_88 = cute.add_offset(%tup_21, %93) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_89, %e1_90 = cute.get_leaves(%tup_88) : !cute.int_tuple<"(?{div=4},?)">
      %coord_91 = cute.make_coord(%e0_89, %e1_90) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %227:2 = cute.get_scalars(%coord_91) : !cute.coord<"(?{div=4},?)">
      %228 = arith.cmpi slt, %227#0, %142#0 : i32
      %229 = arith.cmpi slt, %227#1, %142#1 : i32
      %230 = arith.andi %228, %229 : i1
      %231 = arith.extui %230 : i1 to i8
      cute.memref.store(%rmem, %92, %231) : (!memref_rmem_i8_, !cute.coord<"17">, i8) -> ()
      %tup_92 = cute.add_offset(%tup_21, %91) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %e0_93, %e1_94 = cute.get_leaves(%tup_92) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_95 = cute.make_coord(%e0_93, %e1_94) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %232:2 = cute.get_scalars(%coord_95) : !cute.coord<"(?{div=4},?{div=2})">
      %233 = arith.cmpi slt, %232#0, %142#0 : i32
      %234 = arith.cmpi slt, %232#1, %142#1 : i32
      %235 = arith.andi %233, %234 : i1
      %236 = arith.extui %235 : i1 to i8
      cute.memref.store(%rmem, %90, %236) : (!memref_rmem_i8_, !cute.coord<"18">, i8) -> ()
      %tup_96 = cute.add_offset(%tup_21, %89) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_97, %e1_98 = cute.get_leaves(%tup_96) : !cute.int_tuple<"(?{div=4},?)">
      %coord_99 = cute.make_coord(%e0_97, %e1_98) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %237:2 = cute.get_scalars(%coord_99) : !cute.coord<"(?{div=4},?)">
      %238 = arith.cmpi slt, %237#0, %142#0 : i32
      %239 = arith.cmpi slt, %237#1, %142#1 : i32
      %240 = arith.andi %238, %239 : i1
      %241 = arith.extui %240 : i1 to i8
      cute.memref.store(%rmem, %88, %241) : (!memref_rmem_i8_, !cute.coord<"19">, i8) -> ()
      %tup_100 = cute.add_offset(%tup_21, %87) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_101, %e1_102 = cute.get_leaves(%tup_100) : !cute.int_tuple<"(?,?{div=4})">
      %coord_103 = cute.make_coord(%e0_101, %e1_102) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %242:2 = cute.get_scalars(%coord_103) : !cute.coord<"(?,?{div=4})">
      %243 = arith.cmpi slt, %242#0, %142#0 : i32
      %244 = arith.cmpi slt, %242#1, %142#1 : i32
      %245 = arith.andi %243, %244 : i1
      %246 = arith.extui %245 : i1 to i8
      cute.memref.store(%rmem, %86, %246) : (!memref_rmem_i8_, !cute.coord<"20">, i8) -> ()
      %tup_104 = cute.add_offset(%tup_21, %85) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_105, %e1_106 = cute.get_leaves(%tup_104) : !cute.int_tuple<"(?,?)">
      %coord_107 = cute.make_coord(%e0_105, %e1_106) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %247:2 = cute.get_scalars(%coord_107) : !cute.coord<"(?,?)">
      %248 = arith.cmpi slt, %247#0, %142#0 : i32
      %249 = arith.cmpi slt, %247#1, %142#1 : i32
      %250 = arith.andi %248, %249 : i1
      %251 = arith.extui %250 : i1 to i8
      cute.memref.store(%rmem, %84, %251) : (!memref_rmem_i8_, !cute.coord<"21">, i8) -> ()
      %tup_108 = cute.add_offset(%tup_21, %83) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_109, %e1_110 = cute.get_leaves(%tup_108) : !cute.int_tuple<"(?,?{div=2})">
      %coord_111 = cute.make_coord(%e0_109, %e1_110) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %252:2 = cute.get_scalars(%coord_111) : !cute.coord<"(?,?{div=2})">
      %253 = arith.cmpi slt, %252#0, %142#0 : i32
      %254 = arith.cmpi slt, %252#1, %142#1 : i32
      %255 = arith.andi %253, %254 : i1
      %256 = arith.extui %255 : i1 to i8
      cute.memref.store(%rmem, %82, %256) : (!memref_rmem_i8_, !cute.coord<"22">, i8) -> ()
      %tup_112 = cute.add_offset(%tup_21, %81) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_113, %e1_114 = cute.get_leaves(%tup_112) : !cute.int_tuple<"(?,?)">
      %coord_115 = cute.make_coord(%e0_113, %e1_114) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %257:2 = cute.get_scalars(%coord_115) : !cute.coord<"(?,?)">
      %258 = arith.cmpi slt, %257#0, %142#0 : i32
      %259 = arith.cmpi slt, %257#1, %142#1 : i32
      %260 = arith.andi %258, %259 : i1
      %261 = arith.extui %260 : i1 to i8
      cute.memref.store(%rmem, %80, %261) : (!memref_rmem_i8_, !cute.coord<"23">, i8) -> ()
      %tup_116 = cute.add_offset(%tup_21, %79) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_117, %e1_118 = cute.get_leaves(%tup_116) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_119 = cute.make_coord(%e0_117, %e1_118) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %262:2 = cute.get_scalars(%coord_119) : !cute.coord<"(?{div=2},?{div=4})">
      %263 = arith.cmpi slt, %262#0, %142#0 : i32
      %264 = arith.cmpi slt, %262#1, %142#1 : i32
      %265 = arith.andi %263, %264 : i1
      %266 = arith.extui %265 : i1 to i8
      cute.memref.store(%rmem, %78, %266) : (!memref_rmem_i8_, !cute.coord<"24">, i8) -> ()
      %tup_120 = cute.add_offset(%tup_21, %77) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_121, %e1_122 = cute.get_leaves(%tup_120) : !cute.int_tuple<"(?{div=2},?)">
      %coord_123 = cute.make_coord(%e0_121, %e1_122) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %267:2 = cute.get_scalars(%coord_123) : !cute.coord<"(?{div=2},?)">
      %268 = arith.cmpi slt, %267#0, %142#0 : i32
      %269 = arith.cmpi slt, %267#1, %142#1 : i32
      %270 = arith.andi %268, %269 : i1
      %271 = arith.extui %270 : i1 to i8
      cute.memref.store(%rmem, %76, %271) : (!memref_rmem_i8_, !cute.coord<"25">, i8) -> ()
      %tup_124 = cute.add_offset(%tup_21, %75) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_125, %e1_126 = cute.get_leaves(%tup_124) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_127 = cute.make_coord(%e0_125, %e1_126) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %272:2 = cute.get_scalars(%coord_127) : !cute.coord<"(?{div=2},?{div=2})">
      %273 = arith.cmpi slt, %272#0, %142#0 : i32
      %274 = arith.cmpi slt, %272#1, %142#1 : i32
      %275 = arith.andi %273, %274 : i1
      %276 = arith.extui %275 : i1 to i8
      cute.memref.store(%rmem, %74, %276) : (!memref_rmem_i8_, !cute.coord<"26">, i8) -> ()
      %tup_128 = cute.add_offset(%tup_21, %73) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_129, %e1_130 = cute.get_leaves(%tup_128) : !cute.int_tuple<"(?{div=2},?)">
      %coord_131 = cute.make_coord(%e0_129, %e1_130) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %277:2 = cute.get_scalars(%coord_131) : !cute.coord<"(?{div=2},?)">
      %278 = arith.cmpi slt, %277#0, %142#0 : i32
      %279 = arith.cmpi slt, %277#1, %142#1 : i32
      %280 = arith.andi %278, %279 : i1
      %281 = arith.extui %280 : i1 to i8
      cute.memref.store(%rmem, %72, %281) : (!memref_rmem_i8_, !cute.coord<"27">, i8) -> ()
      %tup_132 = cute.add_offset(%tup_21, %71) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_133, %e1_134 = cute.get_leaves(%tup_132) : !cute.int_tuple<"(?,?{div=4})">
      %coord_135 = cute.make_coord(%e0_133, %e1_134) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %282:2 = cute.get_scalars(%coord_135) : !cute.coord<"(?,?{div=4})">
      %283 = arith.cmpi slt, %282#0, %142#0 : i32
      %284 = arith.cmpi slt, %282#1, %142#1 : i32
      %285 = arith.andi %283, %284 : i1
      %286 = arith.extui %285 : i1 to i8
      cute.memref.store(%rmem, %70, %286) : (!memref_rmem_i8_, !cute.coord<"28">, i8) -> ()
      %tup_136 = cute.add_offset(%tup_21, %69) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_137, %e1_138 = cute.get_leaves(%tup_136) : !cute.int_tuple<"(?,?)">
      %coord_139 = cute.make_coord(%e0_137, %e1_138) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %287:2 = cute.get_scalars(%coord_139) : !cute.coord<"(?,?)">
      %288 = arith.cmpi slt, %287#0, %142#0 : i32
      %289 = arith.cmpi slt, %287#1, %142#1 : i32
      %290 = arith.andi %288, %289 : i1
      %291 = arith.extui %290 : i1 to i8
      cute.memref.store(%rmem, %68, %291) : (!memref_rmem_i8_, !cute.coord<"29">, i8) -> ()
      %tup_140 = cute.add_offset(%tup_21, %67) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_141, %e1_142 = cute.get_leaves(%tup_140) : !cute.int_tuple<"(?,?{div=2})">
      %coord_143 = cute.make_coord(%e0_141, %e1_142) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %292:2 = cute.get_scalars(%coord_143) : !cute.coord<"(?,?{div=2})">
      %293 = arith.cmpi slt, %292#0, %142#0 : i32
      %294 = arith.cmpi slt, %292#1, %142#1 : i32
      %295 = arith.andi %293, %294 : i1
      %296 = arith.extui %295 : i1 to i8
      cute.memref.store(%rmem, %66, %296) : (!memref_rmem_i8_, !cute.coord<"30">, i8) -> ()
      %tup_144 = cute.add_offset(%tup_21, %65) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_145, %e1_146 = cute.get_leaves(%tup_144) : !cute.int_tuple<"(?,?)">
      %coord_147 = cute.make_coord(%e0_145, %e1_146) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %297:2 = cute.get_scalars(%coord_147) : !cute.coord<"(?,?)">
      %298 = arith.cmpi slt, %297#0, %142#0 : i32
      %299 = arith.cmpi slt, %297#1, %142#1 : i32
      %300 = arith.andi %298, %299 : i1
      %301 = arith.extui %300 : i1 to i8
      cute.memref.store(%rmem, %64, %301) : (!memref_rmem_i8_, !cute.coord<"31">, i8) -> ()
      %tup_148 = cute.add_offset(%tup_21, %63) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,0)">) -> !cute.int_tuple<"(?{div=8},?{div=4})">
      %e0_149, %e1_150 = cute.get_leaves(%tup_148) : !cute.int_tuple<"(?{div=8},?{div=4})">
      %coord_151 = cute.make_coord(%e0_149, %e1_150) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=8},?{div=4})">
      %302:2 = cute.get_scalars(%coord_151) : !cute.coord<"(?{div=8},?{div=4})">
      %303 = arith.cmpi slt, %302#0, %142#0 : i32
      %304 = arith.cmpi slt, %302#1, %142#1 : i32
      %305 = arith.andi %303, %304 : i1
      %306 = arith.extui %305 : i1 to i8
      cute.memref.store(%rmem, %62, %306) : (!memref_rmem_i8_, !cute.coord<"32">, i8) -> ()
      %tup_152 = cute.add_offset(%tup_21, %61) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,1)">) -> !cute.int_tuple<"(?{div=8},?)">
      %e0_153, %e1_154 = cute.get_leaves(%tup_152) : !cute.int_tuple<"(?{div=8},?)">
      %coord_155 = cute.make_coord(%e0_153, %e1_154) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %307:2 = cute.get_scalars(%coord_155) : !cute.coord<"(?{div=8},?)">
      %308 = arith.cmpi slt, %307#0, %142#0 : i32
      %309 = arith.cmpi slt, %307#1, %142#1 : i32
      %310 = arith.andi %308, %309 : i1
      %311 = arith.extui %310 : i1 to i8
      cute.memref.store(%rmem, %60, %311) : (!memref_rmem_i8_, !cute.coord<"33">, i8) -> ()
      %tup_156 = cute.add_offset(%tup_21, %59) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"(?{div=8},?{div=2})">
      %e0_157, %e1_158 = cute.get_leaves(%tup_156) : !cute.int_tuple<"(?{div=8},?{div=2})">
      %coord_159 = cute.make_coord(%e0_157, %e1_158) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=8},?{div=2})">
      %312:2 = cute.get_scalars(%coord_159) : !cute.coord<"(?{div=8},?{div=2})">
      %313 = arith.cmpi slt, %312#0, %142#0 : i32
      %314 = arith.cmpi slt, %312#1, %142#1 : i32
      %315 = arith.andi %313, %314 : i1
      %316 = arith.extui %315 : i1 to i8
      cute.memref.store(%rmem, %58, %316) : (!memref_rmem_i8_, !cute.coord<"34">, i8) -> ()
      %tup_160 = cute.add_offset(%tup_21, %57) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,3)">) -> !cute.int_tuple<"(?{div=8},?)">
      %e0_161, %e1_162 = cute.get_leaves(%tup_160) : !cute.int_tuple<"(?{div=8},?)">
      %coord_163 = cute.make_coord(%e0_161, %e1_162) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %317:2 = cute.get_scalars(%coord_163) : !cute.coord<"(?{div=8},?)">
      %318 = arith.cmpi slt, %317#0, %142#0 : i32
      %319 = arith.cmpi slt, %317#1, %142#1 : i32
      %320 = arith.andi %318, %319 : i1
      %321 = arith.extui %320 : i1 to i8
      cute.memref.store(%rmem, %56, %321) : (!memref_rmem_i8_, !cute.coord<"35">, i8) -> ()
      %tup_164 = cute.add_offset(%tup_21, %55) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_165, %e1_166 = cute.get_leaves(%tup_164) : !cute.int_tuple<"(?,?{div=4})">
      %coord_167 = cute.make_coord(%e0_165, %e1_166) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %322:2 = cute.get_scalars(%coord_167) : !cute.coord<"(?,?{div=4})">
      %323 = arith.cmpi slt, %322#0, %142#0 : i32
      %324 = arith.cmpi slt, %322#1, %142#1 : i32
      %325 = arith.andi %323, %324 : i1
      %326 = arith.extui %325 : i1 to i8
      cute.memref.store(%rmem, %54, %326) : (!memref_rmem_i8_, !cute.coord<"36">, i8) -> ()
      %tup_168 = cute.add_offset(%tup_21, %53) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_169, %e1_170 = cute.get_leaves(%tup_168) : !cute.int_tuple<"(?,?)">
      %coord_171 = cute.make_coord(%e0_169, %e1_170) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %327:2 = cute.get_scalars(%coord_171) : !cute.coord<"(?,?)">
      %328 = arith.cmpi slt, %327#0, %142#0 : i32
      %329 = arith.cmpi slt, %327#1, %142#1 : i32
      %330 = arith.andi %328, %329 : i1
      %331 = arith.extui %330 : i1 to i8
      cute.memref.store(%rmem, %52, %331) : (!memref_rmem_i8_, !cute.coord<"37">, i8) -> ()
      %tup_172 = cute.add_offset(%tup_21, %51) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_173, %e1_174 = cute.get_leaves(%tup_172) : !cute.int_tuple<"(?,?{div=2})">
      %coord_175 = cute.make_coord(%e0_173, %e1_174) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %332:2 = cute.get_scalars(%coord_175) : !cute.coord<"(?,?{div=2})">
      %333 = arith.cmpi slt, %332#0, %142#0 : i32
      %334 = arith.cmpi slt, %332#1, %142#1 : i32
      %335 = arith.andi %333, %334 : i1
      %336 = arith.extui %335 : i1 to i8
      cute.memref.store(%rmem, %50, %336) : (!memref_rmem_i8_, !cute.coord<"38">, i8) -> ()
      %tup_176 = cute.add_offset(%tup_21, %49) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_177, %e1_178 = cute.get_leaves(%tup_176) : !cute.int_tuple<"(?,?)">
      %coord_179 = cute.make_coord(%e0_177, %e1_178) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %337:2 = cute.get_scalars(%coord_179) : !cute.coord<"(?,?)">
      %338 = arith.cmpi slt, %337#0, %142#0 : i32
      %339 = arith.cmpi slt, %337#1, %142#1 : i32
      %340 = arith.andi %338, %339 : i1
      %341 = arith.extui %340 : i1 to i8
      cute.memref.store(%rmem, %48, %341) : (!memref_rmem_i8_, !cute.coord<"39">, i8) -> ()
      %tup_180 = cute.add_offset(%tup_21, %47) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_181, %e1_182 = cute.get_leaves(%tup_180) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_183 = cute.make_coord(%e0_181, %e1_182) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %342:2 = cute.get_scalars(%coord_183) : !cute.coord<"(?{div=2},?{div=4})">
      %343 = arith.cmpi slt, %342#0, %142#0 : i32
      %344 = arith.cmpi slt, %342#1, %142#1 : i32
      %345 = arith.andi %343, %344 : i1
      %346 = arith.extui %345 : i1 to i8
      cute.memref.store(%rmem, %46, %346) : (!memref_rmem_i8_, !cute.coord<"40">, i8) -> ()
      %tup_184 = cute.add_offset(%tup_21, %45) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_185, %e1_186 = cute.get_leaves(%tup_184) : !cute.int_tuple<"(?{div=2},?)">
      %coord_187 = cute.make_coord(%e0_185, %e1_186) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %347:2 = cute.get_scalars(%coord_187) : !cute.coord<"(?{div=2},?)">
      %348 = arith.cmpi slt, %347#0, %142#0 : i32
      %349 = arith.cmpi slt, %347#1, %142#1 : i32
      %350 = arith.andi %348, %349 : i1
      %351 = arith.extui %350 : i1 to i8
      cute.memref.store(%rmem, %44, %351) : (!memref_rmem_i8_, !cute.coord<"41">, i8) -> ()
      %tup_188 = cute.add_offset(%tup_21, %43) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_189, %e1_190 = cute.get_leaves(%tup_188) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_191 = cute.make_coord(%e0_189, %e1_190) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %352:2 = cute.get_scalars(%coord_191) : !cute.coord<"(?{div=2},?{div=2})">
      %353 = arith.cmpi slt, %352#0, %142#0 : i32
      %354 = arith.cmpi slt, %352#1, %142#1 : i32
      %355 = arith.andi %353, %354 : i1
      %356 = arith.extui %355 : i1 to i8
      cute.memref.store(%rmem, %42, %356) : (!memref_rmem_i8_, !cute.coord<"42">, i8) -> ()
      %tup_192 = cute.add_offset(%tup_21, %41) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_193, %e1_194 = cute.get_leaves(%tup_192) : !cute.int_tuple<"(?{div=2},?)">
      %coord_195 = cute.make_coord(%e0_193, %e1_194) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %357:2 = cute.get_scalars(%coord_195) : !cute.coord<"(?{div=2},?)">
      %358 = arith.cmpi slt, %357#0, %142#0 : i32
      %359 = arith.cmpi slt, %357#1, %142#1 : i32
      %360 = arith.andi %358, %359 : i1
      %361 = arith.extui %360 : i1 to i8
      cute.memref.store(%rmem, %40, %361) : (!memref_rmem_i8_, !cute.coord<"43">, i8) -> ()
      %tup_196 = cute.add_offset(%tup_21, %39) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_197, %e1_198 = cute.get_leaves(%tup_196) : !cute.int_tuple<"(?,?{div=4})">
      %coord_199 = cute.make_coord(%e0_197, %e1_198) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %362:2 = cute.get_scalars(%coord_199) : !cute.coord<"(?,?{div=4})">
      %363 = arith.cmpi slt, %362#0, %142#0 : i32
      %364 = arith.cmpi slt, %362#1, %142#1 : i32
      %365 = arith.andi %363, %364 : i1
      %366 = arith.extui %365 : i1 to i8
      cute.memref.store(%rmem, %38, %366) : (!memref_rmem_i8_, !cute.coord<"44">, i8) -> ()
      %tup_200 = cute.add_offset(%tup_21, %37) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_201, %e1_202 = cute.get_leaves(%tup_200) : !cute.int_tuple<"(?,?)">
      %coord_203 = cute.make_coord(%e0_201, %e1_202) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %367:2 = cute.get_scalars(%coord_203) : !cute.coord<"(?,?)">
      %368 = arith.cmpi slt, %367#0, %142#0 : i32
      %369 = arith.cmpi slt, %367#1, %142#1 : i32
      %370 = arith.andi %368, %369 : i1
      %371 = arith.extui %370 : i1 to i8
      cute.memref.store(%rmem, %36, %371) : (!memref_rmem_i8_, !cute.coord<"45">, i8) -> ()
      %tup_204 = cute.add_offset(%tup_21, %35) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_205, %e1_206 = cute.get_leaves(%tup_204) : !cute.int_tuple<"(?,?{div=2})">
      %coord_207 = cute.make_coord(%e0_205, %e1_206) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %372:2 = cute.get_scalars(%coord_207) : !cute.coord<"(?,?{div=2})">
      %373 = arith.cmpi slt, %372#0, %142#0 : i32
      %374 = arith.cmpi slt, %372#1, %142#1 : i32
      %375 = arith.andi %373, %374 : i1
      %376 = arith.extui %375 : i1 to i8
      cute.memref.store(%rmem, %34, %376) : (!memref_rmem_i8_, !cute.coord<"46">, i8) -> ()
      %tup_208 = cute.add_offset(%tup_21, %33) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_209, %e1_210 = cute.get_leaves(%tup_208) : !cute.int_tuple<"(?,?)">
      %coord_211 = cute.make_coord(%e0_209, %e1_210) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %377:2 = cute.get_scalars(%coord_211) : !cute.coord<"(?,?)">
      %378 = arith.cmpi slt, %377#0, %142#0 : i32
      %379 = arith.cmpi slt, %377#1, %142#1 : i32
      %380 = arith.andi %378, %379 : i1
      %381 = arith.extui %380 : i1 to i8
      cute.memref.store(%rmem, %32, %381) : (!memref_rmem_i8_, !cute.coord<"47">, i8) -> ()
      %tup_212 = cute.add_offset(%tup_21, %31) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %e0_213, %e1_214 = cute.get_leaves(%tup_212) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_215 = cute.make_coord(%e0_213, %e1_214) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %382:2 = cute.get_scalars(%coord_215) : !cute.coord<"(?{div=4},?{div=4})">
      %383 = arith.cmpi slt, %382#0, %142#0 : i32
      %384 = arith.cmpi slt, %382#1, %142#1 : i32
      %385 = arith.andi %383, %384 : i1
      %386 = arith.extui %385 : i1 to i8
      cute.memref.store(%rmem, %30, %386) : (!memref_rmem_i8_, !cute.coord<"48">, i8) -> ()
      %tup_216 = cute.add_offset(%tup_21, %29) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_217, %e1_218 = cute.get_leaves(%tup_216) : !cute.int_tuple<"(?{div=4},?)">
      %coord_219 = cute.make_coord(%e0_217, %e1_218) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %387:2 = cute.get_scalars(%coord_219) : !cute.coord<"(?{div=4},?)">
      %388 = arith.cmpi slt, %387#0, %142#0 : i32
      %389 = arith.cmpi slt, %387#1, %142#1 : i32
      %390 = arith.andi %388, %389 : i1
      %391 = arith.extui %390 : i1 to i8
      cute.memref.store(%rmem, %28, %391) : (!memref_rmem_i8_, !cute.coord<"49">, i8) -> ()
      %tup_220 = cute.add_offset(%tup_21, %27) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %e0_221, %e1_222 = cute.get_leaves(%tup_220) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_223 = cute.make_coord(%e0_221, %e1_222) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %392:2 = cute.get_scalars(%coord_223) : !cute.coord<"(?{div=4},?{div=2})">
      %393 = arith.cmpi slt, %392#0, %142#0 : i32
      %394 = arith.cmpi slt, %392#1, %142#1 : i32
      %395 = arith.andi %393, %394 : i1
      %396 = arith.extui %395 : i1 to i8
      cute.memref.store(%rmem, %26, %396) : (!memref_rmem_i8_, !cute.coord<"50">, i8) -> ()
      %tup_224 = cute.add_offset(%tup_21, %25) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %e0_225, %e1_226 = cute.get_leaves(%tup_224) : !cute.int_tuple<"(?{div=4},?)">
      %coord_227 = cute.make_coord(%e0_225, %e1_226) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %397:2 = cute.get_scalars(%coord_227) : !cute.coord<"(?{div=4},?)">
      %398 = arith.cmpi slt, %397#0, %142#0 : i32
      %399 = arith.cmpi slt, %397#1, %142#1 : i32
      %400 = arith.andi %398, %399 : i1
      %401 = arith.extui %400 : i1 to i8
      cute.memref.store(%rmem, %24, %401) : (!memref_rmem_i8_, !cute.coord<"51">, i8) -> ()
      %tup_228 = cute.add_offset(%tup_21, %23) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_229, %e1_230 = cute.get_leaves(%tup_228) : !cute.int_tuple<"(?,?{div=4})">
      %coord_231 = cute.make_coord(%e0_229, %e1_230) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %402:2 = cute.get_scalars(%coord_231) : !cute.coord<"(?,?{div=4})">
      %403 = arith.cmpi slt, %402#0, %142#0 : i32
      %404 = arith.cmpi slt, %402#1, %142#1 : i32
      %405 = arith.andi %403, %404 : i1
      %406 = arith.extui %405 : i1 to i8
      cute.memref.store(%rmem, %22, %406) : (!memref_rmem_i8_, !cute.coord<"52">, i8) -> ()
      %tup_232 = cute.add_offset(%tup_21, %21) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_233, %e1_234 = cute.get_leaves(%tup_232) : !cute.int_tuple<"(?,?)">
      %coord_235 = cute.make_coord(%e0_233, %e1_234) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %407:2 = cute.get_scalars(%coord_235) : !cute.coord<"(?,?)">
      %408 = arith.cmpi slt, %407#0, %142#0 : i32
      %409 = arith.cmpi slt, %407#1, %142#1 : i32
      %410 = arith.andi %408, %409 : i1
      %411 = arith.extui %410 : i1 to i8
      cute.memref.store(%rmem, %20, %411) : (!memref_rmem_i8_, !cute.coord<"53">, i8) -> ()
      %tup_236 = cute.add_offset(%tup_21, %19) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_237, %e1_238 = cute.get_leaves(%tup_236) : !cute.int_tuple<"(?,?{div=2})">
      %coord_239 = cute.make_coord(%e0_237, %e1_238) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %412:2 = cute.get_scalars(%coord_239) : !cute.coord<"(?,?{div=2})">
      %413 = arith.cmpi slt, %412#0, %142#0 : i32
      %414 = arith.cmpi slt, %412#1, %142#1 : i32
      %415 = arith.andi %413, %414 : i1
      %416 = arith.extui %415 : i1 to i8
      cute.memref.store(%rmem, %18, %416) : (!memref_rmem_i8_, !cute.coord<"54">, i8) -> ()
      %tup_240 = cute.add_offset(%tup_21, %17) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_241, %e1_242 = cute.get_leaves(%tup_240) : !cute.int_tuple<"(?,?)">
      %coord_243 = cute.make_coord(%e0_241, %e1_242) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %417:2 = cute.get_scalars(%coord_243) : !cute.coord<"(?,?)">
      %418 = arith.cmpi slt, %417#0, %142#0 : i32
      %419 = arith.cmpi slt, %417#1, %142#1 : i32
      %420 = arith.andi %418, %419 : i1
      %421 = arith.extui %420 : i1 to i8
      cute.memref.store(%rmem, %16, %421) : (!memref_rmem_i8_, !cute.coord<"55">, i8) -> ()
      %tup_244 = cute.add_offset(%tup_21, %15) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %e0_245, %e1_246 = cute.get_leaves(%tup_244) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_247 = cute.make_coord(%e0_245, %e1_246) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %422:2 = cute.get_scalars(%coord_247) : !cute.coord<"(?{div=2},?{div=4})">
      %423 = arith.cmpi slt, %422#0, %142#0 : i32
      %424 = arith.cmpi slt, %422#1, %142#1 : i32
      %425 = arith.andi %423, %424 : i1
      %426 = arith.extui %425 : i1 to i8
      cute.memref.store(%rmem, %14, %426) : (!memref_rmem_i8_, !cute.coord<"56">, i8) -> ()
      %tup_248 = cute.add_offset(%tup_21, %13) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_249, %e1_250 = cute.get_leaves(%tup_248) : !cute.int_tuple<"(?{div=2},?)">
      %coord_251 = cute.make_coord(%e0_249, %e1_250) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %427:2 = cute.get_scalars(%coord_251) : !cute.coord<"(?{div=2},?)">
      %428 = arith.cmpi slt, %427#0, %142#0 : i32
      %429 = arith.cmpi slt, %427#1, %142#1 : i32
      %430 = arith.andi %428, %429 : i1
      %431 = arith.extui %430 : i1 to i8
      cute.memref.store(%rmem, %12, %431) : (!memref_rmem_i8_, !cute.coord<"57">, i8) -> ()
      %tup_252 = cute.add_offset(%tup_21, %11) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %e0_253, %e1_254 = cute.get_leaves(%tup_252) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_255 = cute.make_coord(%e0_253, %e1_254) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %432:2 = cute.get_scalars(%coord_255) : !cute.coord<"(?{div=2},?{div=2})">
      %433 = arith.cmpi slt, %432#0, %142#0 : i32
      %434 = arith.cmpi slt, %432#1, %142#1 : i32
      %435 = arith.andi %433, %434 : i1
      %436 = arith.extui %435 : i1 to i8
      cute.memref.store(%rmem, %10, %436) : (!memref_rmem_i8_, !cute.coord<"58">, i8) -> ()
      %tup_256 = cute.add_offset(%tup_21, %9) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %e0_257, %e1_258 = cute.get_leaves(%tup_256) : !cute.int_tuple<"(?{div=2},?)">
      %coord_259 = cute.make_coord(%e0_257, %e1_258) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %437:2 = cute.get_scalars(%coord_259) : !cute.coord<"(?{div=2},?)">
      %438 = arith.cmpi slt, %437#0, %142#0 : i32
      %439 = arith.cmpi slt, %437#1, %142#1 : i32
      %440 = arith.andi %438, %439 : i1
      %441 = arith.extui %440 : i1 to i8
      cute.memref.store(%rmem, %8, %441) : (!memref_rmem_i8_, !cute.coord<"59">, i8) -> ()
      %tup_260 = cute.add_offset(%tup_21, %7) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %e0_261, %e1_262 = cute.get_leaves(%tup_260) : !cute.int_tuple<"(?,?{div=4})">
      %coord_263 = cute.make_coord(%e0_261, %e1_262) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %442:2 = cute.get_scalars(%coord_263) : !cute.coord<"(?,?{div=4})">
      %443 = arith.cmpi slt, %442#0, %142#0 : i32
      %444 = arith.cmpi slt, %442#1, %142#1 : i32
      %445 = arith.andi %443, %444 : i1
      %446 = arith.extui %445 : i1 to i8
      cute.memref.store(%rmem, %6, %446) : (!memref_rmem_i8_, !cute.coord<"60">, i8) -> ()
      %tup_264 = cute.add_offset(%tup_21, %5) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,1)">) -> !cute.int_tuple<"(?,?)">
      %e0_265, %e1_266 = cute.get_leaves(%tup_264) : !cute.int_tuple<"(?,?)">
      %coord_267 = cute.make_coord(%e0_265, %e1_266) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %447:2 = cute.get_scalars(%coord_267) : !cute.coord<"(?,?)">
      %448 = arith.cmpi slt, %447#0, %142#0 : i32
      %449 = arith.cmpi slt, %447#1, %142#1 : i32
      %450 = arith.andi %448, %449 : i1
      %451 = arith.extui %450 : i1 to i8
      cute.memref.store(%rmem, %4, %451) : (!memref_rmem_i8_, !cute.coord<"61">, i8) -> ()
      %tup_268 = cute.add_offset(%tup_21, %3) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %e0_269, %e1_270 = cute.get_leaves(%tup_268) : !cute.int_tuple<"(?,?{div=2})">
      %coord_271 = cute.make_coord(%e0_269, %e1_270) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %452:2 = cute.get_scalars(%coord_271) : !cute.coord<"(?,?{div=2})">
      %453 = arith.cmpi slt, %452#0, %142#0 : i32
      %454 = arith.cmpi slt, %452#1, %142#1 : i32
      %455 = arith.andi %453, %454 : i1
      %456 = arith.extui %455 : i1 to i8
      cute.memref.store(%rmem, %2, %456) : (!memref_rmem_i8_, !cute.coord<"62">, i8) -> ()
      %tup_272 = cute.add_offset(%tup_21, %1) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,3)">) -> !cute.int_tuple<"(?,?)">
      %e0_273, %e1_274 = cute.get_leaves(%tup_272) : !cute.int_tuple<"(?,?)">
      %coord_275 = cute.make_coord(%e0_273, %e1_274) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %457:2 = cute.get_scalars(%coord_275) : !cute.coord<"(?,?)">
      %458 = arith.cmpi slt, %457#0, %142#0 : i32
      %459 = arith.cmpi slt, %457#1, %142#1 : i32
      %460 = arith.andi %458, %459 : i1
      %461 = arith.extui %460 : i1 to i8
      cute.memref.store(%rmem, %0, %461) : (!memref_rmem_i8_, !cute.coord<"63">, i8) -> ()
      %462 = cute.memref.load_vec %view : !memref_gmem_f32_2
      %463 = cute.memref.load_vec %view_14 : !memref_gmem_f32_2
      %464 = arith.addf %462, %463 : vector<64xf32>
      cute.memref.store_vec %464, %view_19 : !memref_gmem_f32_3
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
    cf.cond_br %11, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    cf.br ^bb7(%10 : i32)
  ^bb2:  // pred: ^bb0
    %12 = arith.cmpi sgt, %9#0, %c0_i32 : i32
    cf.cond_br %12, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    cf.br ^bb5(%c1_i32 : i32)
  ^bb4:  // pred: ^bb2
    %13 = arith.cmpi eq, %9#0, %c0_i32 : i32
    %14 = arith.select %13, %c0_i32, %c-1_i32 : i32
    cf.br ^bb5(%14 : i32)
  ^bb5(%15: i32):  // 2 preds: ^bb3, ^bb4
    cf.br ^bb6
  ^bb6:  // pred: ^bb5
    cf.br ^bb7(%15 : i32)
  ^bb7(%16: i32):  // 2 preds: ^bb1, ^bb6
    cf.br ^bb8
  ^bb8:  // pred: ^bb7
    %17 = arith.minsi %16, %c16_i32 : i32
    %18 = arith.muli %9#3, %c64_i64 : i64
    %19 = math.absi %16 : i32
    %20 = arith.divsi %c16_i32, %19 : i32
    %21 = arith.cmpi ne, %20, %c0_i32 : i32
    cf.cond_br %21, ^bb9, ^bb10
  ^bb9:  // pred: ^bb8
    cf.br ^bb15(%20 : i32)
  ^bb10:  // pred: ^bb8
    %22 = arith.cmpi sgt, %19, %c0_i32 : i32
    cf.cond_br %22, ^bb11, ^bb12
  ^bb11:  // pred: ^bb10
    cf.br ^bb13(%c1_i32 : i32)
  ^bb12:  // pred: ^bb10
    %23 = arith.cmpi eq, %19, %c0_i32 : i32
    %24 = arith.select %23, %c0_i32, %c-1_i32 : i32
    cf.br ^bb13(%24 : i32)
  ^bb13(%25: i32):  // 2 preds: ^bb11, ^bb12
    cf.br ^bb14
  ^bb14:  // pred: ^bb13
    cf.br ^bb15(%25 : i32)
  ^bb15(%26: i32):  // 2 preds: ^bb9, ^bb14
    cf.br ^bb16
  ^bb16:  // pred: ^bb15
    %27 = arith.divsi %c64_i32, %9#0 : i32
    %28 = arith.cmpi ne, %27, %c0_i32 : i32
    cf.cond_br %28, ^bb17, ^bb18
  ^bb17:  // pred: ^bb16
    cf.br ^bb23(%27 : i32)
  ^bb18:  // pred: ^bb16
    %29 = arith.cmpi sgt, %9#0, %c0_i32 : i32
    cf.cond_br %29, ^bb19, ^bb20
  ^bb19:  // pred: ^bb18
    cf.br ^bb21(%c1_i32 : i32)
  ^bb20:  // pred: ^bb18
    %30 = arith.cmpi eq, %9#0, %c0_i32 : i32
    %31 = arith.select %30, %c0_i32, %c-1_i32 : i32
    cf.br ^bb21(%31 : i32)
  ^bb21(%32: i32):  // 2 preds: ^bb19, ^bb20
    cf.br ^bb22
  ^bb22:  // pred: ^bb21
    cf.br ^bb23(%32 : i32)
  ^bb23(%33: i32):  // 2 preds: ^bb17, ^bb22
    cf.br ^bb24
  ^bb24:  // pred: ^bb23
    %34 = arith.muli %33, %c256_i32 : i32
    %35 = arith.cmpi ne, %9#0, %c0_i32 : i32
    cf.cond_br %35, ^bb25, ^bb26
  ^bb25:  // pred: ^bb24
    cf.br ^bb31(%9#0 : i32)
  ^bb26:  // pred: ^bb24
    %36 = arith.cmpi sgt, %9#0, %c0_i32 : i32
    cf.cond_br %36, ^bb27, ^bb28
  ^bb27:  // pred: ^bb26
    cf.br ^bb29(%c1_i32 : i32)
  ^bb28:  // pred: ^bb26
    %37 = arith.cmpi eq, %9#0, %c0_i32 : i32
    %38 = arith.select %37, %c0_i32, %c-1_i32 : i32
    cf.br ^bb29(%38 : i32)
  ^bb29(%39: i32):  // 2 preds: ^bb27, ^bb28
    cf.br ^bb30
  ^bb30:  // pred: ^bb29
    cf.br ^bb31(%39 : i32)
  ^bb31(%40: i32):  // 2 preds: ^bb25, ^bb30
    cf.br ^bb32
  ^bb32:  // pred: ^bb31
    %41 = arith.minsi %40, %c64_i32 : i32
    %42 = math.absi %40 : i32
    %43 = arith.divsi %c64_i32, %42 : i32
    %44 = arith.cmpi ne, %43, %c0_i32 : i32
    cf.cond_br %44, ^bb33, ^bb34
  ^bb33:  // pred: ^bb32
    cf.br ^bb39(%43 : i32)
  ^bb34:  // pred: ^bb32
    %45 = arith.cmpi sgt, %42, %c0_i32 : i32
    cf.cond_br %45, ^bb35, ^bb36
  ^bb35:  // pred: ^bb34
    cf.br ^bb37(%c1_i32 : i32)
  ^bb36:  // pred: ^bb34
    %46 = arith.cmpi eq, %42, %c0_i32 : i32
    %47 = arith.select %46, %c0_i32, %c-1_i32 : i32
    cf.br ^bb37(%47 : i32)
  ^bb37(%48: i32):  // 2 preds: ^bb35, ^bb36
    cf.br ^bb38
  ^bb38:  // pred: ^bb37
    cf.br ^bb39(%48 : i32)
  ^bb39(%49: i32):  // 2 preds: ^bb33, ^bb38
    cf.br ^bb40
  ^bb40:  // pred: ^bb39
    %50 = arith.divsi %c1_i32, %9#0 : i32
    %51 = arith.cmpi ne, %50, %c0_i32 : i32
    cf.cond_br %51, ^bb41, ^bb42
  ^bb41:  // pred: ^bb40
    cf.br ^bb47(%50 : i32)
  ^bb42:  // pred: ^bb40
    %52 = arith.cmpi sgt, %9#0, %c0_i32 : i32
    cf.cond_br %52, ^bb43, ^bb44
  ^bb43:  // pred: ^bb42
    cf.br ^bb45(%c1_i32 : i32)
  ^bb44:  // pred: ^bb42
    %53 = arith.cmpi eq, %9#0, %c0_i32 : i32
    %54 = arith.select %53, %c0_i32, %c-1_i32 : i32
    cf.br ^bb45(%54 : i32)
  ^bb45(%55: i32):  // 2 preds: ^bb43, ^bb44
    cf.br ^bb46
  ^bb46:  // pred: ^bb45
    cf.br ^bb47(%55 : i32)
  ^bb47(%56: i32):  // 2 preds: ^bb41, ^bb46
    cf.br ^bb48
  ^bb48:  // pred: ^bb47
    %57 = arith.muli %56, %c256_i32 : i32
    %shape_4 = cute.make_shape(%17, %26, %41, %49) : (i32, i32, i32, i32) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %iv_5 = cute.assume(%18) : (i64) -> !cute.i64<divby 4096>
    %iv_6 = cute.assume(%34) : (i32) -> !cute.i32<divby 256>
    %iv_7 = cute.assume(%9#3) : (i64) -> !cute.i64<divby 64>
    %iv_8 = cute.assume(%57) : (i32) -> !cute.i32<divby 256>
    %stride_9 = cute.make_stride(%9#2, %iv_5, %iv_6, %iv_7, %iv_8) : (i64, !cute.i64<divby 4096>, !cute.i32<divby 256>, !cute.i64<divby 64>, !cute.i32<divby 256>) -> !cute.stride<"((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %lay_10 = cute.make_layout(%shape_4, %stride_9) : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %view_11 = cute.make_view(%iter_1, %lay_10) : !memref_gmem_f32_1
    %58 = cute.get_shape(%lay) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%58) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %59 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_12 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %60 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
    %shape_13 = cute.make_shape(%itup, %itup_12) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %lay_14 = cute.make_layout(%shape_13, %1) : !cute.layout<"(?,?):(1@0,1@1)">
    %61:2 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %62 = arith.ceildivsi %61#0, %c64_i32 : i32
    %63 = arith.ceildivsi %61#1, %c256_i32 : i32
    %shape_15 = cute.make_shape(%62, %63) : (i32, i32) -> !cute.shape<"((64,256),(?,?))">
    %lay_16 = cute.make_layout(%shape_15, %0) : !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %view_17 = cute.make_view(%2, %lay_16) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %64 = cute.get_shape(%lay_10) : (!cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %e0_18, %e1_19, %e2, %e3, %e4, %e5 = cute.get_leaves(%64) : !cute.shape<"((64,256),((?,?),(?,?)))">
    %itup_20 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_21 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_22 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_23 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup_20, %itup_21, %itup_22, %itup_23) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"((?,?),(?,?))">
    %65:4 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"((?,?),(?,?))">
    %66 = arith.muli %65#0, %65#1 : i32
    %67 = arith.muli %65#2, %65#3 : i32
    %int_tuple_24 = cute.make_int_tuple(%66, %67) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %e0_25, %e1_26 = cute.get_leaves(%int_tuple_24) : !cute.int_tuple<"(?,?)">
    %68 = cute.get_scalars(%e0_25) : !cute.int_tuple<"?">
    %69 = cute.get_scalars(%e1_26) : !cute.int_tuple<"?">
    %70 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c256_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%68, %69, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %71 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_apply_kernel_builtinfunctionadd_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32gmemalign16o_0<%70> (%view, %view_3, %view_11, %view_17, %59, %60) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_1, !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">, i32, i32) -> !cuda.result
    %72 = cuda.cast %71 : !cuda.result -> i32
    cuda.return_if_error %72 : i32
    return %c0_i32 : i32
  }
}
