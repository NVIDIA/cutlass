#!/bin/bash

set -e

function formatFiles {
    for f in `find "$1" -type f -name "*.$2"` ; do
        COMMAND="clang-format -i $f"
        echo $COMMAND
        $COMMAND
    done
}

formatFiles "cutlass" "h"
formatFiles "tools/test" "h"
formatFiles "tools/test" "cpp"
formatFiles "tools/util" "h"

