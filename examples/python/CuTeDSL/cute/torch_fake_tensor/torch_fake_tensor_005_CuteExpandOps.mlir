!memref_generic_f32_ = !cute.memref<f32, generic, "(3,4):(4,1)">
!memref_generic_f32_1 = !cute.memref<f32, generic, "(3,4,(1)):(4,1,(0))">
module attributes {gpu.container_module} {
  llvm.mlir.global internal constant @printfFormat_14(")\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_13(",\0A\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_12("]\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_11(",\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_10("]\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_9("%f, \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_8(" %f, \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_7("..., \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_6("[\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_5("        \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_4("        ...\0A\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_3("[\00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_2("       \00") {addr_space = 0 : i32}
  llvm.mlir.global internal constant @printfFormat_1("       \00") {addr_space = 0 : i32}
  llvm.func @printf(!llvm.ptr, ...) -> i32
  llvm.mlir.global internal constant @printfFormat_0("tensor(raw_ptr(0x%016llx: f32, generic, align<4>) o (3,4):(4,1), data=\0A\00") {addr_space = 0 : i32}
  gpu.module @kernels {
  }
  func.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !memref_generic_f32_) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_generic_f32_
    %iter_0 = cute.get_iter(%arg0) : !memref_generic_f32_
    %lay = cute.get_layout(%arg0) : !memref_generic_f32_
    %0 = cute.get_shape(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.shape<"(3,4)">
    %e0, %e1 = cute.get_leaves(%0) : !cute.shape<"(3,4)">
    %1 = cute.get_stride(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_1, %e1_2 = cute.get_leaves(%1) : !cute.stride<"(4,1)">
    %iter_3 = cute.get_iter(%arg0) : !memref_generic_f32_
    %lay_4 = cute.get_layout(%arg0) : !memref_generic_f32_
    %shape = cute.make_shape() : () -> !cute.shape<"1">
    %lay_5 = cute.make_layout() : !cute.layout<"1:0">
    %append = cute.append_to_rank<3> (%lay_4, %lay_5) : !cute.layout<"(3,4):(4,1)">, !cute.layout<"1:0">
    %lay_6 = cute.make_layout() : !cute.layout<"(3,4,(1)):(4,1,(0))">
    %view = cute.make_view(%iter_3, %lay_6) : !memref_generic_f32_1
    %2 = builtin.unrealized_conversion_cast %iter_3 : !cute.ptr<f32, generic> to !llvm.ptr
    %3 = llvm.ptrtoint %2 : !llvm.ptr to i64
    %4 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %c0_i64 = arith.constant 0 : i64
    %5 = llvm.getelementptr %4[%c0_i64, %c0_i64] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<72 x i8>
    %6 = llvm.call @printf(%5, %3) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64) -> i32
    %sz = cute.size(%lay_6) <{mode = [0]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"3">
    %sz_7 = cute.size(%lay_6) <{mode = [1]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"4">
    %sz_8 = cute.size(%lay_6) <{mode = [2]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"1">
    %7 = cute.get_scalars(%sz) : !cute.int_tuple<"3">
    %8 = cute.get_scalars(%sz_7) : !cute.int_tuple<"4">
    %9 = cute.get_scalars(%sz_8) : !cute.int_tuple<"1">
    %10 = arith.index_cast %7 : i32 to index
    %11 = arith.index_cast %8 : i32 to index
    %12 = arith.index_cast %9 : i32 to index
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %13 = llvm.mlir.addressof @printfFormat_1 : !llvm.ptr
    %c0_i64_9 = arith.constant 0 : i64
    %14 = llvm.getelementptr %13[%c0_i64_9, %c0_i64_9] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<8 x i8>
    %15 = llvm.call @printf(%14) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    scf.for %arg1 = %c0 to %12 step %c1 {
      %19 = arith.subi %12, %c1 : index
      %20 = arith.cmpi ne, %arg1, %19 : index
      %21 = arith.cmpi ne, %arg1, %c0 : index
      scf.if %21 {
        %28 = llvm.mlir.addressof @printfFormat_2 : !llvm.ptr
        %c0_i64_14 = arith.constant 0 : i64
        %29 = llvm.getelementptr %28[%c0_i64_14, %c0_i64_14] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<8 x i8>
        %30 = llvm.call @printf(%29) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
      %22 = llvm.mlir.addressof @printfFormat_3 : !llvm.ptr
      %c0_i64_11 = arith.constant 0 : i64
      %23 = llvm.getelementptr %22[%c0_i64_11, %c0_i64_11] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
      %24 = llvm.call @printf(%23) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      %c1_12 = arith.constant 1 : index
      scf.for %arg2 = %c0 to %10 step %c1_12 {
        %c2 = arith.constant 2 : index
        %c3 = arith.constant 3 : index
        %28 = arith.cmpi sgt, %arg2, %c2 : index
        %29 = arith.subi %10, %c3 : index
        %30 = arith.cmpi slt, %arg2, %29 : index
        %31 = arith.andi %28, %30 : i1
        scf.if %31 {
          %c3_14 = arith.constant 3 : index
          %32 = arith.cmpi eq, %arg2, %c3_14 : index
          scf.if %32 {
            %33 = llvm.mlir.addressof @printfFormat_4 : !llvm.ptr
            %c0_i64_15 = arith.constant 0 : i64
            %34 = llvm.getelementptr %33[%c0_i64_15, %c0_i64_15] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<13 x i8>
            %35 = llvm.call @printf(%34) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        } else {
          %32 = arith.cmpi ne, %arg2, %c0 : index
          %33 = arith.subi %10, %c1 : index
          %34 = arith.cmpi slt, %arg2, %33 : index
          scf.if %32 {
            %41 = llvm.mlir.addressof @printfFormat_5 : !llvm.ptr
            %c0_i64_18 = arith.constant 0 : i64
            %42 = llvm.getelementptr %41[%c0_i64_18, %c0_i64_18] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<9 x i8>
            %43 = llvm.call @printf(%42) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
          %35 = llvm.mlir.addressof @printfFormat_6 : !llvm.ptr
          %c0_i64_14 = arith.constant 0 : i64
          %36 = llvm.getelementptr %35[%c0_i64_14, %c0_i64_14] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
          %37 = llvm.call @printf(%36) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          %c0_15 = arith.constant 0 : index
          %c1_16 = arith.constant 1 : index
          scf.for %arg3 = %c0_15 to %11 step %c1_16 {
            %c2_18 = arith.constant 2 : index
            %c3_19 = arith.constant 3 : index
            %41 = arith.cmpi sgt, %arg3, %c2_18 : index
            %42 = arith.subi %11, %c3_19 : index
            %43 = arith.cmpi slt, %arg3, %42 : index
            %44 = arith.andi %41, %43 : i1
            scf.if %44 {
              %c3_20 = arith.constant 3 : index
              %45 = arith.cmpi eq, %arg3, %c3_20 : index
              scf.if %45 {
                %46 = llvm.mlir.addressof @printfFormat_7 : !llvm.ptr
                %c0_i64_21 = arith.constant 0 : i64
                %47 = llvm.getelementptr %46[%c0_i64_21, %c0_i64_21] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<6 x i8>
                %48 = llvm.call @printf(%47) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
              }
            } else {
              %45 = arith.index_cast %arg1 : index to i32
              %46 = arith.index_cast %arg3 : index to i32
              %47 = arith.index_cast %arg2 : index to i32
              %coord = cute.make_coord(%47, %46, %45) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
              %48 = cute.memref.load(%view, %coord) : (!memref_generic_f32_1, !cute.coord<"(?,?,?)">) -> f32
              %cst = arith.constant 0.000000e+00 : f32
              %49 = arith.cmpf oge, %48, %cst : f32
              scf.if %49 {
                %50 = arith.extf %48 : f32 to f64
                %51 = llvm.mlir.addressof @printfFormat_8 : !llvm.ptr
                %c0_i64_20 = arith.constant 0 : i64
                %52 = llvm.getelementptr %51[%c0_i64_20, %c0_i64_20] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<6 x i8>
                %53 = llvm.call @printf(%52, %50) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              } else {
                %50 = arith.extf %48 : f32 to f64
                %51 = llvm.mlir.addressof @printfFormat_9 : !llvm.ptr
                %c0_i64_20 = arith.constant 0 : i64
                %52 = llvm.getelementptr %51[%c0_i64_20, %c0_i64_20] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<5 x i8>
                %53 = llvm.call @printf(%52, %50) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, f64) -> i32
              }
            }
          }
          %38 = llvm.mlir.addressof @printfFormat_10 : !llvm.ptr
          %c0_i64_17 = arith.constant 0 : i64
          %39 = llvm.getelementptr %38[%c0_i64_17, %c0_i64_17] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
          %40 = llvm.call @printf(%39) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          scf.if %34 {
            %41 = llvm.mlir.addressof @printfFormat_11 : !llvm.ptr
            %c0_i64_18 = arith.constant 0 : i64
            %42 = llvm.getelementptr %41[%c0_i64_18, %c0_i64_18] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<3 x i8>
            %43 = llvm.call @printf(%42) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
          }
        }
      }
      %25 = llvm.mlir.addressof @printfFormat_12 : !llvm.ptr
      %c0_i64_13 = arith.constant 0 : i64
      %26 = llvm.getelementptr %25[%c0_i64_13, %c0_i64_13] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<2 x i8>
      %27 = llvm.call @printf(%26) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      scf.if %20 {
        %28 = llvm.mlir.addressof @printfFormat_13 : !llvm.ptr
        %c0_i64_14 = arith.constant 0 : i64
        %29 = llvm.getelementptr %28[%c0_i64_14, %c0_i64_14] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<4 x i8>
        %30 = llvm.call @printf(%29) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
      }
    }
    %16 = llvm.mlir.addressof @printfFormat_14 : !llvm.ptr
    %c0_i64_10 = arith.constant 0 : i64
    %17 = llvm.getelementptr %16[%c0_i64_10, %c0_i64_10] : (!llvm.ptr, i64, i64) -> !llvm.ptr, !llvm.array<3 x i8>
    %18 = llvm.call @printf(%17) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr) -> i32
    return
  }
}
