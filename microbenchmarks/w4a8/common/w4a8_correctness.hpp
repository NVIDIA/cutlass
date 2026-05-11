#pragma once

// bf16 output equality check shared by every non-baseline experiment.
//
// compare_block_D<GemmRef, GemmTest>(ref_ctx, test_ctx, atol, rtol)
//   - copies both block_D allocations to host
//   - tracks max abs diff and max rel diff over all elements
//   - declares passed = true iff every element satisfies
//         |ref - test| <= atol  OR  |ref - test|/|ref| <= rtol
//   - always prints the two diff numbers so the caller sees the actual gap
//
// Tolerances default to (atol=1e-2, rtol=5e-3), tuned for bf16 outputs of the
// W4A8 grouped GEMM at the target problem shapes.

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <vector>

#include "common/w4a8_grouped_setup.cuh"

#include "cutlass/numeric_conversion.h"
#include "cutlass/numeric_types.h"

#ifdef INT4FP8_GROUPED_SUPPORTED

struct EqResult {
  double max_abs_diff = 0.0;
  double max_rel_diff = 0.0;
  size_t total_elements = 0;
  size_t mismatched = 0;
  bool   passed = true;
  double atol = 0.0;
  double rtol = 0.0;
};

template <class GemmRef, class GemmTest>
inline EqResult compare_block_D(W4A8GemmContext<GemmRef> const &ref,
                                W4A8GemmContext<GemmTest> const &test,
                                double atol = 1e-2,
                                double rtol = 5e-3) {
  using ElementRef = typename W4A8GemmContext<GemmRef>::ElementOut;
  using ElementTest = typename W4A8GemmContext<GemmTest>::ElementOut;

  EqResult r;
  r.atol = atol;
  r.rtol = rtol;

  if (ref.block_D.size() != test.block_D.size()) {
    std::cerr << "compare_block_D: size mismatch ref=" << ref.block_D.size()
              << " test=" << test.block_D.size() << "\n";
    r.passed = false;
    return r;
  }

  size_t n = ref.block_D.size();
  r.total_elements = n;

  std::vector<ElementRef> h_ref(n);
  std::vector<ElementTest> h_test(n);
  ref.block_D.copy_to_host(h_ref.data());
  test.block_D.copy_to_host(h_test.data());

  for (size_t i = 0; i < n; ++i) {
    double a = static_cast<double>(static_cast<float>(h_ref[i]));
    double b = static_cast<double>(static_cast<float>(h_test[i]));
    double abs_diff = std::abs(a - b);
    double denom = std::max(std::abs(a), 1e-12);
    double rel_diff = abs_diff / denom;

    if (abs_diff > r.max_abs_diff) r.max_abs_diff = abs_diff;
    if (rel_diff > r.max_rel_diff) r.max_rel_diff = rel_diff;

    if (abs_diff > atol && rel_diff > rtol) {
      r.mismatched += 1;
    }
  }

  r.passed = (r.mismatched == 0);
  return r;
}

inline void print_eq_result(EqResult const &eq) {
  std::cout << "Equality check ("
            << "atol=" << std::scientific << std::setprecision(1) << eq.atol
            << ", rtol=" << eq.rtol << "): "
            << (eq.passed ? "PASS" : "FAIL")
            << "  max_abs_diff=" << std::scientific << std::setprecision(3) << eq.max_abs_diff
            << "  max_rel_diff=" << eq.max_rel_diff
            << "  mismatched=" << eq.mismatched << "/" << eq.total_elements
            << std::defaultfloat << "\n";
}

#endif // INT4FP8_GROUPED_SUPPORTED
