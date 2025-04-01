echo "**** **** clang-format --version"
clang-format --version

echo "**** **** clang-tidy --version"
clang-tidy --version


hooks_folder="./.git/hooks/"
if [ ! -d "$hooks_folder" ]; then
    mkdir -p "$hooks_folder"
    echo "Created git.hook folder: $hooks_folder"
else
    echo "git.hook already exists: $hooks_folder"
fi


echo "**** **** commit-title format cfg"
commit_msg_path="git_commit.sh"
dst_path="./.git/hooks/commit-msg"
if [ ! -f $commit_msg_path ]; then
    echo "Error: $commit_msg_path not exist in repo"
else
    cp $commit_msg_path $dst_path
    chmod +x $dst_path
    echo "git commit checker is OK"
fi

echo "**** **** commit clang-format cfg"
pre_commit_path="git_clang.sh"
dst_path="./.git/hooks/pre-commit"
if [ ! -f $pre_commit_path ]; then
    echo "Error: $pre_commit_path not exist in repo"
else
    cp $pre_commit_path $dst_path
    chmod +x $dst_path
    echo "git format checker is OK"
fi