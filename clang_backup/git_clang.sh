#!/bin/bash
echo ""

# 获取所有被修改且是 C++ 文件的列表
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cpp|cxx|cc|c|h|hpp)$')

# clang-format
if [ -n "$files" ]; then
    for file in $files; do
        echo "clang-format :$file"
        # 使用 clang-format 格式化文件
        clang-format -i "$file"
        # 将格式化后的文件添加到暂存区
        git add "$file"
    done
fi
echo "commit clang-format check OK"
echo ""

build_path="build"
# clang-tidy
if [ -n "$files" ]; then
    for file in $files; do
        # 运行 clang-tidy 检查，并将输出保存到变量中
        output=$(clang-tidy "$file" -p $build_path --quiet 2>&1)
        # 检查输出中是否包含 "warning"
        if echo "$output" | grep -q "warning:"; then
            echo "clang-tidy found warnings in $file. Please fix it."
            echo "$output"
            exit 1
        fi
        # 检查 clang-tidy 是否返回非零状态码
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            echo "clang-tidy found issues in $file. Please fix it."
            echo "$output"
            exit 1
        fi

    done
fi
echo "commit clang-tidy check OK"
echo ""

exit 0