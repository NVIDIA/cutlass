/*! \file
  \brief CUTLASS layout visualization example
*/

#pragma once

#include <map>
#include <memory>

#include "options.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

struct VisualizeLayoutBase {
  virtual bool visualize(Options const &) = 0;
  virtual bool verify(bool verbose, std::ostream &out) = 0;
  virtual void print_csv(std::ostream &out, char delim = '|', char new_line = '\n') = 0;
  virtual std::ostream &print_help(std::ostream &out) {
    return out;
  }
  virtual ~VisualizeLayoutBase() { }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

void RegisterLayouts(std::map<std::string, std::unique_ptr<VisualizeLayoutBase> > &layouts);

/////////////////////////////////////////////////////////////////////////////////////////////////
