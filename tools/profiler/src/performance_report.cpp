/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/* \file
   \brief Execution environment
*/

#include <iostream>
#include <stdexcept>
#include <iomanip>
#include <algorithm>
#include <cstring>

#include "cutlass/library/util.h"

#include "cutlass/library/util.h"

#include "performance_report.h"
#include "debug.h"
namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

#if defined(__unix__)

#define SHELL_COLOR_BRIGHT()  "\033[1;37m"
#define SHELL_COLOR_GREEN()   "\033[1;32m"
#define SHELL_COLOR_RED()     "\033[1;31m"
#define SHELL_COLOR_END()     "\033[0m"

#else

#define SHELL_COLOR_BRIGHT()  ""
#define SHELL_COLOR_GREEN()   ""
#define SHELL_COLOR_RED()     ""
#define SHELL_COLOR_END()     ""

#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

PerformanceReport::PerformanceReport(
  Options const &options,
  std::vector<std::string> const &argument_names,
  library::OperationKind const &op_kind
):
  options_(options), argument_names_(argument_names), problem_index_(0), good_(true), op_kind_(op_kind) {

  // Strip '.csv' if present
  std::string base_path = options_.report.output_path.substr(
    0, options_.report.output_path.rfind(".csv"));

  op_file_name_ = base_path + "." + to_string(op_kind_) + ".csv";

  //
  // Open output file for operation of PerformanceReport::op_kind
  //
  if (!options_.report.output_path.empty()) {

    bool print_header = true;

    if (options_.report.append) {

      std::ifstream test_output_file(op_file_name_);
      
      if (test_output_file.is_open()) {
        print_header = false;
        test_output_file.close();
      }

      output_file_.open(op_file_name_, std::ios::app);
    }
    else {
      output_file_.open(op_file_name_);
    }

    if (!output_file_.good()) {

      std::cerr << "Could not open output file at path '"
         << options_.report.output_path << "'" << std::endl;

      good_ = false;
    }

    if (print_header) {
      print_csv_header_(output_file_) << std::endl;
    }
  }
}

void PerformanceReport::next_problem() {
  ++problem_index_;
}

void PerformanceReport::append_result(PerformanceResult result) {

  result.problem_index = problem_index_;

  if (options_.report.verbose) {
    std::cout << "\n";
    print_result_pretty_(std::cout, result) << std::flush; 
  }

  if (output_file_.is_open()) {
    print_result_csv_(output_file_, result) << std::endl;
  }
  else {
    concatenated_results_.push_back(result);
  }
}

void PerformanceReport::append_results(PerformanceResultVector const &results) {

  if (options_.report.verbose) {
    std::cout << "\n\n";
  }

  // For each result
  for (auto const & result : results) {
    append_result(result);
  }
}

void PerformanceReport::close() {

  //
  // Output results to stdout if they were not written to a file already.
  //
  if (options_.report.verbose && !concatenated_results_.empty()) {

    std::cout << "\n\n";
    std::cout << "=============================\n\n";
    std::cout << "CSV Results:\n\n";

    print_csv_header_(std::cout) << std::endl;
    
    for (auto const &result : concatenated_results_) {
      print_result_csv_(std::cout, result) << "\n";
    }
  }
  else if (output_file_.is_open() && options_.report.verbose) {
    std::cout << "\n\nWrote results to '" << op_file_name_ << "'" << std::endl;
  }
}

static const char *disposition_status_color(Disposition disposition) {
  switch (disposition) {
    case Disposition::kPassed: return SHELL_COLOR_GREEN();
    case Disposition::kIncorrect: return SHELL_COLOR_RED();
    case Disposition::kFailed: return SHELL_COLOR_RED();
    default:
    break;
  }
  return SHELL_COLOR_END();
}

/// Prints the result in human readable form
std::ostream & PerformanceReport::print_result_pretty_(
  std::ostream &out, 
  PerformanceResult const &result) {

  out << "=============================\n"
    << "  Problem ID: " << result.problem_index << "\n";

  if (!options_.report.pivot_tags.empty()) {

    out << "        Tags: ";

    int column_idx = 0;
    for (auto const & tag : options_.report.pivot_tags) {
      out << (column_idx++ ? "," : "") << tag.first << ":" << tag.second;
    } 

    out << "\n";
  }

  out
    << "\n"
    << "        Provider: " << SHELL_COLOR_BRIGHT() << library::to_string(result.provider, true) << SHELL_COLOR_END() << "\n"
    << "   OperationKind: " << SHELL_COLOR_BRIGHT() << library::to_string(result.op_kind) << SHELL_COLOR_END() << "\n"
    << "       Operation: " << result.operation_name << "\n\n"
    << "          Status: " << SHELL_COLOR_BRIGHT() << library::to_string(result.status, true) << SHELL_COLOR_END() << "\n"
    << "    Verification: " << SHELL_COLOR_BRIGHT() << (options_.verification.enabled ? "ON":"OFF") << SHELL_COLOR_END() << "\n"
    << "     Disposition: " << disposition_status_color(result.disposition) << to_string(result.disposition, true) << SHELL_COLOR_END() << "\n\n";

  // Display individual verification results for each verification-provider
  if (options_.verification.enabled) {

    static int const indent_spaces = 16;

    for(auto & m : result.verification_map) {
      out  << std::right << std::setw(indent_spaces) << library::to_string(m.first, true) << ": " << to_string(m.second, true) << "\n";  
    }
  }

  out
    << "\n       Arguments:";

  int column_idx = 0;
  for (auto const &arg : result.arguments) {
    if (!arg.second.empty()) {
      out << " --" << arg.first << "=" << arg.second; 
      column_idx += int(4 + arg.first.size() + arg.second.size());
      if (column_idx > 98) {
        out << "  \\\n                 ";
        column_idx = 0;
      }
    }
  }
  out << "\n\n";

  out 
    << "           Bytes: " << result.bytes << "  bytes\n"
    << "           FLOPs: " << result.flops << "  flops\n\n";

  if (result.good()) {

    out
      << "         Runtime: " << result.runtime << "  ms\n"
      << "          Memory: " << result.gbytes_per_sec() << " GiB/s\n"
      << "\n            Math: " << result.gflops_per_sec() << " GFLOP/s\n";

  }

  return out;
}

/// Prints the CSV header
std::ostream & PerformanceReport::print_csv_header_(
  std::ostream &out) {

  int column_idx = 0;

  // Pivot tags
  for (auto const & tag : options_.report.pivot_tags) {
    out << (column_idx++ ? "," : "") << tag.first;
  }

  out 
    << (column_idx ? "," : "") << "Problem,Provider"
    << ",OperationKind,Operation,Disposition,Status";

  for (auto const &arg_name : argument_names_) {
    // Operand E is internal to the sparse kernel
    if (arg_name.compare("E") == 0)
      continue;

    out << "," << arg_name;
  }

  out 
    << ",Bytes"
    << ",Flops"
    << ",Runtime"
    << ",GB/s"
    << ",GFLOPs"
    ;

  return out;
}

/// Print the result in CSV output
std::ostream & PerformanceReport::print_result_csv_(
  std::ostream &out, 
  PerformanceResult const &result) {

  int column_idx = 0;

  // Pivot tags
  for (auto const & tag : options_.report.pivot_tags) {
    out << (column_idx++ ? "," : "") << tag.second;
  }

  out 
    << (column_idx ? "," : "") 
    << result.problem_index
    << "," << to_string(result.provider, true)
    << "," << to_string(result.op_kind)
    << "," << result.operation_name
    << "," << to_string(result.disposition)
    << "," << library::to_string(result.status);

  for (auto const & arg : result.arguments) {
    out << "," << arg.second;
  }

  out 
    << "," << result.bytes
    << "," << result.flops
    << "," << result.runtime;

  if (result.good()) {

    out
      << "," << result.gbytes_per_sec()
      << "," << result.gflops_per_sec()
      ;
  }
  else {
    out << std::string(2
      , ','
    ); 
  }

  return out;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass
