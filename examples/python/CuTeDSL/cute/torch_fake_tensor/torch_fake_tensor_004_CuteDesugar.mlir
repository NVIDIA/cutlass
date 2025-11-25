!memref_generic_f32_ = !cute.memref<f32, generic, "(3,4):(4,1)">
!memref_generic_f32_1 = !cute.memref<f32, generic, "(3,4,(1)):(4,1,(0))">
module attributes {gpu.container_module} {
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
    cute.print("tensor({} o {}, data=\0A", %iter_3, %lay_4) : !cute.ptr<f32, generic>, !cute.layout<"(3,4):(4,1)">
    %sz = cute.size(%lay_6) <{mode = [0]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"3">
    %sz_7 = cute.size(%lay_6) <{mode = [1]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"4">
    %sz_8 = cute.size(%lay_6) <{mode = [2]}> : (!cute.layout<"(3,4,(1)):(4,1,(0))">) -> !cute.int_tuple<"1">
    %2 = cute.get_scalars(%sz) : !cute.int_tuple<"3">
    %3 = cute.get_scalars(%sz_7) : !cute.int_tuple<"4">
    %4 = cute.get_scalars(%sz_8) : !cute.int_tuple<"1">
    %5 = arith.index_cast %2 : i32 to index
    %6 = arith.index_cast %3 : i32 to index
    %7 = arith.index_cast %4 : i32 to index
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    cute.print("       ", ) : 
    scf.for %arg1 = %c0 to %7 step %c1 {
      %8 = arith.subi %7, %c1 : index
      %9 = arith.cmpi ne, %arg1, %8 : index
      %10 = arith.cmpi ne, %arg1, %c0 : index
      scf.if %10 {
        cute.print("       ", ) : 
      }
      cute.print("[", ) : 
      %c1_9 = arith.constant 1 : index
      scf.for %arg2 = %c0 to %5 step %c1_9 {
        %c2 = arith.constant 2 : index
        %c3 = arith.constant 3 : index
        %11 = arith.cmpi sgt, %arg2, %c2 : index
        %12 = arith.subi %5, %c3 : index
        %13 = arith.cmpi slt, %arg2, %12 : index
        %14 = arith.andi %11, %13 : i1
        scf.if %14 {
          %c3_10 = arith.constant 3 : index
          %15 = arith.cmpi eq, %arg2, %c3_10 : index
          scf.if %15 {
            cute.print("        ...\0A", ) : 
          }
        } else {
          %15 = arith.cmpi ne, %arg2, %c0 : index
          %16 = arith.subi %5, %c1 : index
          %17 = arith.cmpi slt, %arg2, %16 : index
          scf.if %15 {
            cute.print("        ", ) : 
          }
          cute.print("[", ) : 
          %c0_10 = arith.constant 0 : index
          %c1_11 = arith.constant 1 : index
          scf.for %arg3 = %c0_10 to %6 step %c1_11 {
            %c2_12 = arith.constant 2 : index
            %c3_13 = arith.constant 3 : index
            %18 = arith.cmpi sgt, %arg3, %c2_12 : index
            %19 = arith.subi %6, %c3_13 : index
            %20 = arith.cmpi slt, %arg3, %19 : index
            %21 = arith.andi %18, %20 : i1
            scf.if %21 {
              %c3_14 = arith.constant 3 : index
              %22 = arith.cmpi eq, %arg3, %c3_14 : index
              scf.if %22 {
                cute.print("..., ", ) : 
              }
            } else {
              %22 = arith.index_cast %arg1 : index to i32
              %23 = arith.index_cast %arg3 : index to i32
              %24 = arith.index_cast %arg2 : index to i32
              %coord = cute.make_coord(%24, %23, %22) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
              %25 = cute.memref.load(%view, %coord) : (!memref_generic_f32_1, !cute.coord<"(?,?,?)">) -> f32
              %cst = arith.constant 0.000000e+00 : f32
              %26 = arith.cmpf oge, %25, %cst : f32
              scf.if %26 {
                cute.print(" {}, ", %25) : f32
              } else {
                cute.print("{}, ", %25) : f32
              }
            }
          }
          cute.print("]", ) : 
          scf.if %17 {
            cute.print(",\0A", ) : 
          }
        }
      }
      cute.print("]", ) : 
      scf.if %9 {
        cute.print(",\0A\0A", ) : 
      }
    }
    cute.print(")\0A", ) : 
    return
  }
}
