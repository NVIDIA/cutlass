#!/bin/bash

echo ""

# check param whether is NULL
if [ -z "$1" ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

if [ ! -f "$1" ]; then
    # if param is not file_path, then read param into commit_msg
    commit_msg="$1"
else
    # if param is file_path, then read content into commit_msg
    echo "commit-msg file: $1"
    commit_msg=$(cat "$1")
fi

# log
echo "commit-msg     : $commit_msg"

valid_typees="feat|fix|revert|test|chore|docs"

match=$(echo "$commit_msg" | grep -E "^\\[($valid_typees)\\]:.*$")
if [ -z "$match" ]; then
    echo "Error commit message format. Expected:"
    echo "[type]: content"
    echo "#### ####"
    echo "type is one of $valid_typees."
    echo "#1 feat    : new add xxx feature, ops, perf enhance or other logical code..."
    echo "#2 fix     : fix xxx bug"
    echo "#3 revert  : revert commit"
    echo "#4 test    : add new test case or UT tools or ci ref..."
    echo "#5 chore   : [NO logical code changing !!!] maintain dependencies, third-party,"
    echo  "                 no-UT tools, build process, code style, comment..."
    echo "#6 docs    : [NO logical code changing !!!] change document"
    echo "#### ####"
    echo "commit msg check Failure"
    echo ""
    exit 1
fi

echo "commit-title format check OK"
echo ""

exit 0