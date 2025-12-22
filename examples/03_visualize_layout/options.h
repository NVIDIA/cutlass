#pragma once

#include <vector>
#include <iostream>

// Cutlass command line parser
#include "cutlass/util/command_line.h"

class Options {
public:

  bool help;
  bool good;
  std::vector<int> extent;          ///< extent of tile to fill
  std::vector<int> stride;          ///< stride vector for layout function
  std::vector<int> output_shape;    ///< output shape
  int vectorize;                    ///< sequences of consecutive output elements are concatenated into a vector
                                    ///  if, and only if, they were consecutive in source memory

public:

  /// Options
  Options(): 
    help(false),
    good(true),
    extent({32, 8}),
    stride({32}),
    output_shape({16, 8}), 
    vectorize(1) { 

  }

  /// Constructs from command line parser
  Options(cutlass::CommandLine const & cmd_line): help(false), good(true) {

    if (cmd_line.check_cmd_line_flag("help") ||
        cmd_line.check_cmd_line_flag("h")) {

      help = true;
    }

    if (cmd_line.check_cmd_line_flag("extent")) {
      cmd_line.get_cmd_line_arguments("extent", extent);
    }
    else {
      extent = {32, 8};
    }

    if (cmd_line.check_cmd_line_flag("stride")) {
      cmd_line.get_cmd_line_arguments("stride", stride);
    }
    
    int default_output_shape[] = {16, 8}; 

    if (cmd_line.check_cmd_line_flag("output-shape")) {
      cmd_line.get_cmd_line_arguments("output-shape", output_shape);
    }

    for (int i = int(output_shape.size()); i < 2; ++i) {
      output_shape.push_back(default_output_shape[i]);
    }

    if (cmd_line.check_cmd_line_flag("vectorize")) {
      cmd_line.get_cmd_line_argument("vectorize", vectorize);
    }
    else {
      vectorize = 1;
    }

    if (output_shape.front() % vectorize) {

      std::cerr << "Error: --vectorize=" << vectorize 
        << " must divide contiguous elements in --output-shape="
        << output_shape.at(0) << "," << output_shape.at(1) << std::endl;

      good = false;
    }
  }

  /// Prints usage statement
  static void print_usage(std::ostream &out) {
    out
      << "  Options:\n"
      << "    --help                              Displays this help message.\n"
      << "    --extent=<extent>                   Specifies the layout-specific extent (as comma-delimited array).\n"
      << "    --stride=<stride>                   Specifies the layout-specific stride vector (comma-delimited array)\n"
      << "    --output-shape=<extent>             Specifies the dimensions of a row-major output matrix. \n"
      << "    --vectorize=<vector length>         If possible, vectorizes the output into vectors of consecutive elements\n";
  }
};
