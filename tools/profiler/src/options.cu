/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
   \brief Command line options for performance test program
*/

#include <algorithm>

#include "cutlass/cutlass.h"
#include "cutlass/version.h"

#include "options.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Newline and indent for help strings
static char const *end_of_line = "\n                                             ";

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Device::Device(cutlass::CommandLine const &cmdline) {

  cmdline.get_cmd_line_argument("device", device, 0);

  cudaError_t result;
  result = cudaGetDeviceProperties(&properties, device);

  if (result != cudaSuccess) {
    throw std::runtime_error("cudaGetDeviceProperties() failed for given device");
  }

  result = cudaSetDevice(device);
  if (result != cudaSuccess) {
    throw std::runtime_error("cudaSetDevice() failed for given device.");
  }

  // Permit overriding the compute capability
  if (cmdline.check_cmd_line_flag("compute-capability")) {
    int cc = compute_capability();
    cmdline.get_cmd_line_argument("compute-capability", cc, cc);
    properties.major = cc / 10;
    properties.minor = cc % 10;
  }

}

void Options::Device::print_usage(std::ostream &out) const {

  out << "Device:\n"
    << "  --device=<int>                         "
    << "    CUDA Device ID\n\n";

  int device_count = 0;
  cudaError_t result = cudaGetDeviceCount(&device_count);

  if (result != cudaSuccess) {
    out << "      <could not query for CUDA devices>\n";
  }
  else {

    for (int idx = 0; idx < device_count; ++idx) {
      cudaDeviceProp prop;
      result = cudaGetDeviceProperties(&prop, idx);
      if (result != cudaSuccess) {
        out << "      <could not obtain device properties for device " << idx << ">" << std::endl;
        break;
      }
      else {
        out << "    [" << idx << "] - " 
          << prop.name << " - SM " << prop.major << "." << prop.minor << ", " 
          << prop.multiProcessorCount << " SMs @ " << (prop.clockRate / 1000.0) << " MHz, " 
          << "L2 cache: " << (prop.l2CacheSize >> 20) << " MB, Global Memory: " << (prop.totalGlobalMem >> 30) << " GB"
          << std::endl; 
      }
    }
    out << "\n";
  }

  out
    << "  --compute-capability=<int>             "
    << "    Override the compute capability.\n\n";

}

void Options::Device::print_device_info(std::ostream &out) const {
  int num_devices;
  cudaDeviceProp props;

  cudaError_t result;
  result = cudaGetDeviceCount(&num_devices);

  if (result != cudaSuccess) {
    throw std::runtime_error("cudaGetNumDevices() failed");
  }

  out << "Device Name,SM,CUDA Device ID,Phy Device ID" << std::endl;

  for(int device = 0; device < num_devices; device++) {
    result = cudaSetDevice(device);
    if (result != cudaSuccess) {
      throw std::runtime_error("cudaSetDevice() failed for device");
    }

    result = cudaGetDeviceProperties(&props, device);
    if (result != cudaSuccess) {
      throw std::runtime_error("cudaGetDeviceProperties failed for device");
    }

    out << props.name << "," << props.major << props.minor << ","
      << device << "," << props.multiGpuBoardGroupID << std::endl;

  }
}

void Options::Device::print_options(std::ostream &out, int indent) const {

  out
    << indent_str(indent) << "device: " << device << "\n"
    << indent_str(indent) << "clock: " << int(double(properties.clockRate) / 1000.0) << "\n"
    << indent_str(indent) << "compute-capability: " << compute_capability() << "\n";
}

/// Returns the compute capability of the listed device (e.g. 61, 60, 70, 75)
int Options::Device::compute_capability() const {
  return properties.major * 10 + properties.minor;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Initialization::Initialization(cutlass::CommandLine const &cmdline) {

  cmdline.get_cmd_line_argument("initialization-enabled", enabled, true);

  if (cmdline.check_cmd_line_flag("initialization-provider")) {
    std::string str;
    cmdline.get_cmd_line_argument("initialization-provider", str);
    provider = from_string<Provider>(str);
    if (provider == Provider::kInvalid) {
      enabled = false;
    }
    else if (provider != Provider::kReferenceHost && provider != Provider::kReferenceDevice) {
      throw std::runtime_error("Unsupported intialization provider specified."); 
    }
  }
  else {
    provider = Provider::kReferenceDevice;
  }

  cmdline.get_cmd_line_argument("seed", seed, 2019);

  if (cmdline.check_cmd_line_flag("dist")) {
    get_distribution(cmdline, "dist", data_distribution);
  }
  else {
    data_distribution.set_uniform(-4, 4, 0);
  }

}

/// Gets the initial distribution
void Options::Initialization::get_distribution(
  cutlass::CommandLine const &args,
  std::string const &arg,
  cutlass::Distribution &dist) {

  struct {
    const char *label;
    cutlass::Distribution::Kind kind;
  } distribution_kinds[] = {
    {"uniform", cutlass::Distribution::Uniform},
    {"gaussian", cutlass::Distribution::Gaussian},
    {"identity", cutlass::Distribution::Identity},
    {"sequential", cutlass::Distribution::Sequential},
    {0, cutlass::Distribution::Invalid}
  };

  struct {
    char const *label;
    double *member;
  } members[] = {
    {"min", &dist.uniform.min},
    {"max", &dist.uniform.max},
    {"mean", &dist.gaussian.mean},
    {"stddev", &dist.gaussian.stddev},
    {"start", &dist.sequential.start},
    {"delta", &dist.sequential.delta},
    {0, 0}
  };

  using KeyValueVector = std::vector<std::pair<std::string, std::string> >;

  KeyValueVector values;
  args.get_cmd_line_argument_pairs(arg.c_str(), values);

  // The parser expects the first token to be a string identifying the distribution type.
  auto it = values.begin();
  if (it != values.end()) {
    for (int i = 0; distribution_kinds[i].label; ++i) {
      if (it->first == distribution_kinds[i].label) {
        dist.kind = distribution_kinds[i].kind;
        break;
      }
    }
    ++it;
  }

  // Subsequent key-value pairs update the named field of the distribution struct.
  for (; it != values.end(); ++it) {
    // Integer scaling factor - if < 0, no integer rounding is performed.
    if ((it->first.compare("scale") == 0) && !it->second.empty()) {
      std::stringstream ss;
      ss << it->second;
      ss >> dist.int_scale;
      continue;  // next token
    }

    // Casts as integer without scaling
    if (it->first.compare("integer") == 0) {
      dist.int_scale = 0;
      continue;  // next token
    }

    // Casts as integer without scaling
    if (it->first.compare("integer") == 0) {
      dist.int_scale = 0;
      continue;  // next token
    }

    // initialize other members
    for (int m = 0; members[m].label; ++m) {
      if (it->first == members[m].label && !it->second.empty()) {
        std::stringstream ss;
        ss << it->second;
        ss >> *(members[m].member);
      }
    }
  }
}

void Options::Initialization::print_usage(std::ostream &out) const {

  out << "Initialization:\n"

    << "  --initialization=<bool>                "
    << "    Enables initialization (default: true). If false, device memory is" << end_of_line
    << "not initialized after allocation.\n\n"

    << "  --initialization-provider=<provider>   "
    << "    Selects 'device' or 'host' initialization.\n\n"

    << "  --dist=<distribution>                  "
    << "    Data distribution of input tensors\n\n"

    << "  --seed=<int>                           "
    << "    Random number generator seed. Used to enforce deterministic" << end_of_line
    << "initialization.\n\n";

}

void Options::Initialization::print_options(std::ostream &out, int indent) const {

}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Library::Library(cutlass::CommandLine const &cmdline) {

  algorithm_mode = AlgorithmMode::kDefault;

  if (cmdline.check_cmd_line_flag("library-algo-mode")) {
    std::string mode = "default";
    cmdline.get_cmd_line_argument("library-algo-mode", mode);
    algorithm_mode = from_string<AlgorithmMode>(mode);
  }  

  if (cmdline.check_cmd_line_flag("library-algos")) {

    // If algorithms are specified, override as kBest.
    algorithm_mode = AlgorithmMode::kBest;

    std::vector<std::string> tokens;
    cmdline.get_cmd_line_arguments("library-algos", tokens);

    algorithms.reserve(tokens.size());

    for (auto const & token : tokens) {
      if (token.find(":")) {
        // todo - tokenized range
      }
      else {
        int algo;
        std::stringstream ss; 

        ss << token;
        ss >> algo;

        algorithms.push_back(algo);
      }
    }
  }
}

void Options::Library::print_usage(std::ostream &out) const {

  out << "Library:\n"

    << "  --library-algo-mode=<mode>             "
    << "    Indicates algorithm mode used to call libraries such as cuBLAS and cuDNN.\n"
    << "                                         "
    << "    mode={default*,matching,best}\n\n"

    << "  --library-algos=<range-list>           "
    << "    If --algorithm-mode=best, permits specifying a selection of algorithms.\n\n";

}

void Options::Library::print_options(std::ostream &out, int indent) const {

  out
    << indent_str(indent) << "library-algo-mode: " << to_string(algorithm_mode) << "\n"
    << indent_str(indent) << "library-algos: ";

  int j = 0;
  for (int x : algorithms) {
    out << (j++ ? "," : "") << x;
  }

  out << "\n\n";
}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Profiling::Profiling(cutlass::CommandLine const &cmdline) {
  
  cmdline.get_cmd_line_argument("warmup-iterations", warmup_iterations, 10);
  cmdline.get_cmd_line_argument("profiling-iterations", iterations, 100);
  cmdline.get_cmd_line_argument("sleep-duration", sleep_duration, 50);
  cmdline.get_cmd_line_argument("profiling-enabled", enabled, true);
  
  if (cmdline.check_cmd_line_flag("providers")) {

    std::vector<std::string> tokens;
    cmdline.get_cmd_line_arguments("providers", tokens);

    providers.clear();

    for (auto const &token : tokens) {
      providers.push_back(from_string<Provider>(token));
    }
  }
  else {
    providers.push_back(Provider::kCUTLASS);
    providers.push_back(Provider::kCUBLAS);
  }
}

void Options::Profiling::print_usage(std::ostream &out) const {

  out << "Profiling:\n"

    << "  --profiling-iterations=<iterations>    "
    << "    Number of iterations to profile each kernel. If zero, kernels" << end_of_line
    << "are launched up to the profiling duration.\n\n"

    << "  --warmup-iterations=<iterations>       "
    << "    Number of iterations to execute each kernel prior to profiling.\n\n"

    << "  --sleep-duration=<duration>            "
    << "    Number of ms to sleep between profiling periods (ms)\n\n"

    << "  --profiling-enabled=<bool>             "
    << "    If true, profiling is actually conducted.\n\n"

    << "  --providers=<providers>                "
    << "    List of providers to be profiled for performance\n\n";
}

void Options::Profiling::print_options(std::ostream &out, int indent) const {

  out
    << indent_str(indent) << "profiling_iterations: " << iterations << "\n"
    << indent_str(indent) << "sleep_duration: " << sleep_duration << "\n"
    << indent_str(indent) << "profiling_enabled: " << enabled << "\n"
    << indent_str(indent) << "providers: [";

  int j = 0;
  for (auto const & provider : providers) {
    out << (j++ ? ", " : "") << to_string(provider);
  }
  out << "]\n";
}

/// Returns true if a provider is enabled
bool Options::Profiling::provider_enabled(Provider provider) const {
  return std::find(providers.begin(), providers.end(), provider) != providers.end();
}

/// Returns the index of a provider if its enabled
size_t Options::Profiling::index(Provider provider) const {
  size_t idx = 0;
  for (auto const & x : providers) {
    if (x == provider) {
      return idx;
    }
    ++idx;
  }
  return idx;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Verification::Verification(cutlass::CommandLine const &cmdline) {
  
  cmdline.get_cmd_line_argument("verification-enabled", enabled, true);

  cmdline.get_cmd_line_argument("epsilon", epsilon, 0.05);

  cmdline.get_cmd_line_argument("nonzero-floor", nonzero_floor, 1.0 / 256.0);

  if (cmdline.check_cmd_line_flag("save-workspace")) {
    std::string value;
    cmdline.get_cmd_line_argument("save-workspace", value);
    save_workspace = from_string<SaveWorkspace>(value);
  }
  else {
    save_workspace = SaveWorkspace::kNever;
  }

  if (cmdline.check_cmd_line_flag("verification-providers")) {
    
    std::vector<std::string> tokens;
    cmdline.get_cmd_line_arguments("verification-providers", tokens);

    providers.clear();

    for (auto const &token : tokens) {
      Provider provider = from_string<Provider>(token);
      if (provider != Provider::kInvalid) {
        providers.push_back(provider);
      }
    }
  }
  else {
    providers.push_back(Provider::kCUBLAS);
  }
}

void Options::Verification::print_usage(std::ostream &out) const {

  out << "Verification:\n"

    << "  --verification-enabled=<bool>          "
    << "    Whether to perform verification checks.\n\n"

    << "  --epsilon=<error>                      "
    << "    Error threshold. Setting to zero (default) requires" << end_of_line
    << "bit-level equivalence.\n\n"

    << "  --nonzero-floor=<floor>                "
    << "    Results whose absolute value is less than this quantity" << end_of_line
    << "are treated as zero for comparisons.\n\n"

    << "  --save-workspace={*never,incorrect,always}"
    << " Specifies when to save the GEMM inputs and results to the filesystem.\n\n"

    << "  --verification-providers=<providers>   "
    << "    List of providers used to verify result. (default: device)\n\n";
}

void Options::Verification::print_options(std::ostream &out, int indent) const {

  out
    << indent_str(indent) << "verification_enabled: " << enabled << "\n"
    << indent_str(indent) << "epsilon: " << epsilon << "\n"
    << indent_str(indent) << "save_workspace: " << to_string(save_workspace) << "\n"
    << indent_str(indent) << "verification_providers: [";

  int j = 0;
  for (auto const & provider : providers) {
    out << (j++ ? ", " : "") << to_string(provider);
  }
  out << "]\n";
}

/// Returns true if a provider is enabled
bool Options::Verification::provider_enabled(Provider provider) const {
  return std::find(providers.begin(), providers.end(), provider) != providers.end();
}

/// Returns the index of a provider if its enabled
size_t Options::Verification::index(Provider provider) const {
  size_t idx = 0;
  for (auto const & x : providers) {
    if (x == provider) {
      return idx;
    }
    ++idx;
  }
  return idx;
}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Report::Report(cutlass::CommandLine const &cmdline) {
  
  cmdline.get_cmd_line_argument("append", append, false);
  cmdline.get_cmd_line_argument("output", output_path);

  if (cmdline.check_cmd_line_flag("tags")) {
    cmdline.get_cmd_line_argument_pairs("tags", pivot_tags);
  }

  cmdline.get_cmd_line_argument("report-not-run", report_not_run, false);

  cmdline.get_cmd_line_argument("verbose", verbose, true);
}

void Options::Report::print_usage(std::ostream &out) const {

  out << "Report:\n"

    << "  --append=<bool>                        "
    << "    If true, result is appended to possibly existing file. Otherwise, " << end_of_line
    << "any existing file is overwritten.\n\n"

    << "  --output=<path>                        "
    << "    Path to output file for machine readable results.\n\n"

    << "  --report-not-run=<bool>                "
    << "    If true, reports the status of all kernels including those that" << end_of_line
    << "do not satisfy the given arguments.\n\n"

    << "  --tags=<column:tag,...>                "
    << "    Inserts leading columns in output table and uniform values for each" << end_of_line
    << "column. Useful for generating pivot tables.\n\n"

    << "  --verbose=<bool>                       "
    << "    Prints human-readable text to stdout. If false, nothing is written to stdout.\n\n";
}

void Options::Report::print_options(std::ostream &out, int indent) const {

  out
    << indent_str(indent) << "append: " << append << "\n"
    << indent_str(indent) << "output: " << output_path << "\n"
    << indent_str(indent) << "report_not_run: " << report_not_run << "\n"
    << indent_str(indent) << "tags:\n";

  for (auto const & tag : pivot_tags) {
    out << indent_str(indent + 1) << tag.first << ": " << tag.second << "\n";
  }

  out
    << indent_str(indent) << "verbose: " << verbose << "\n";
}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::About::About(cutlass::CommandLine const &cmdline) {
  help = cmdline.check_cmd_line_flag("help");
  version = cmdline.check_cmd_line_flag("version");
  device_info = cmdline.check_cmd_line_flag("device-info");
}

void Options::About::print_usage(std::ostream &out) const {

  out << "About:\n"
    << "  --version                                  ";

  print_version(out);

  out << "\n";
}

void Options::About::print_version(std::ostream &out) {
  out << "CUTLASS " << cutlass::getVersionString()
      << " built on " << __DATE__ << " at " << __TIME__;
  if (!cutlass::getGitRevision().empty()) out << " with commit " << cutlass::getGitRevision() << "";
}

void Options::About::print_options(std::ostream &out, int indent) const {

}

/////////////////////////////////////////////////////////////////////////////////////////////////

Options::Options(cutlass::CommandLine const &cmdline):
  cmdline(cmdline),
  device(cmdline),
  initialization(cmdline),
  library(cmdline),
  profiling(cmdline), 
  verification(cmdline), 
  report(cmdline),
  about(cmdline) {
  
  if (cmdline.check_cmd_line_flag("mode")) {
    std::string token;
    cmdline.get_cmd_line_argument("mode", token);
    execution_mode = from_string<ExecutionMode>(token);
  }
  else {
    execution_mode = ExecutionMode::kProfile;
  }

  // Enumerating kernels is equivalent to a dry run.
  if (execution_mode == ExecutionMode::kEnumerate) {
    execution_mode = ExecutionMode::kDryRun;
  }

  if (cmdline.check_cmd_line_flag("operation")) {
    std::string str;
    cmdline.get_cmd_line_argument("operation", str);
    operation_kind = library::from_string<library::OperationKind>(str);
  }
  else if (cmdline.check_cmd_line_flag("function")) {
    std::string str;
    cmdline.get_cmd_line_argument("function", str);
    operation_kind = library::from_string<library::OperationKind>(str);
  }
  else {
    operation_kind = library::OperationKind::kInvalid;
  }

  if (cmdline.check_cmd_line_flag("operation_names")) {
    cmdline.get_cmd_line_arguments("operation_names", operation_names);
  }
  else if (cmdline.check_cmd_line_flag("kernels")) {
    cmdline.get_cmd_line_arguments("kernels", operation_names);
  }

  // Prevent launches on the device for anything other than CUTLASS operation
  if (execution_mode == ExecutionMode::kTrace) {
    initialization.provider = Provider::kReferenceHost;
    verification.enabled = false;
    profiling.enabled = false;
  }
}

void Options::print_usage(std::ostream &out) const {

  out
    << "CUTLASS Performance Tool\n"
    << "usage:\n\n"
    << "    cutlass_profiler [options]\n\n"
    << "  --help\n\n"

    << "  --mode={profile*,single,dry,trace,enumerate} "
    << "    Regular profiling, single kernel mode only, or no profiling.\n\n"

    << "  --device-info                          "
    << "    Prints information on all GPUs present in the system\n\n"

    << "  --operation=<operation_kind>           "
    << "    CUTLASS operation to profile.\n\n"

    << "  --kernels=<string_list>        "
    << "    List of substrings to filter operations by name.\n\n"
    ;

  //
  // Detailed options
  //

  device.print_usage(out);
  out << "\n";

  initialization.print_usage(out);
  out << "\n";

  library.print_usage(out);
  out << "\n";

  profiling.print_usage(out);
  out << "\n";

  verification.print_usage(out);
  out << "\n";

  report.print_usage(out);
  out << "\n";

  about.print_usage(out);
  out << "\n";
}

void Options::print_options(std::ostream &out) const {

  out
    << "options:\n"
    << "  help: " << about.help << "\n"
    << "  mode: " << to_string(execution_mode) << "\n";

  out
    << "  device:\n";
  device.print_options(out, 2);

  out
    << "  initialization:\n";
  initialization.print_options(out, 2);

  out
    << "  profiling:\n";
  profiling.print_options(out, 2);

  out
    << "  verification:\n";
  verification.print_options(out, 2);

  out
    << "  report:\n";
  report.print_options(out, 2);
}

std::string Options::indent_str(int indent) {
  return std::string(indent * 2, ' ');
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

