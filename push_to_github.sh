#!/bin/bash
# Pushes this whole project to its own branch "liquidglasslab" of
# lu8389772-cloud/AwemeAlbumMorphBar-SwiftUI26. That repository's main branch
# (the old tweak) is never touched. The push to that branch starts the
# GitHub Actions build, which uploads LiquidGlassLab-0.4.0 (IPA + deb).
set -euo pipefail
shopt -s nocasematch

project_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="/var/mobile/LiquidGlassLab-import"
branch_name="liquidglasslab"
old_clone="/var/mobile/AwemeAlbumMorphBar-SwiftUI26"
default_url="https://github.com/lu8389772-cloud/AwemeAlbumMorphBar-SwiftUI26.git"
commit_message="LiquidGlassLab 0.4.0: Douyin home with native top group, side buttons and scalable action column"

# Reuse the old local clone's remote when it is this same repository (it may
# be the SSH form that already has working credentials on this phone).
remote_url="${LAB_REMOTE_URL:-}"
if [ -z "$remote_url" ] && [ -d "$old_clone/.git" ]; then
  candidate="$(git -C "$old_clone" remote get-url origin 2>/dev/null || true)"
  if [[ "$candidate" == *lu8389772-cloud/AwemeAlbumMorphBar-SwiftUI26* ]]; then
    remote_url="$candidate"
  fi
fi
remote_url="${remote_url:-$default_url}"
echo "目标仓库：$remote_url"
echo "目标分支：$branch_name（不会改动 main）"

if [ ! -d "$repo_dir/.git" ]; then
  git clone "$remote_url" "$repo_dir"
fi
cd "$repo_dir"
if [ "$(git remote get-url origin)" != "$remote_url" ]; then
  echo "此目录的 origin 不是预期仓库，已停止：$repo_dir" >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "仓库目录有未提交的改动，请先处理：$repo_dir" >&2
  exit 1
fi

git fetch origin
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  git checkout -q "$branch_name"
  if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    git merge --ff-only "origin/$branch_name"
  fi
elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
  git checkout -q -b "$branch_name" "origin/$branch_name"
else
  # First push: a fresh branch with no history from main.
  git checkout -q --orphan "$branch_name"
  git rm -rq --cached . >/dev/null 2>&1 || true
  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
fi

# The branch mirrors this project exactly: drop every tracked file, then copy
# the project (no build products) back in.
git ls-files | while IFS= read -r file; do rm -f "$file"; done
( cd "$project_dir" && find . -type f \
    ! -path './.git/*' ! -path './.theos/*' ! -path './packages/*' \
    ! -path './build/*' ! -path './out/*' \
    ! -name '*.deb' ! -name '*.ipa' ! -name '.DS_Store' -print ) | while IFS= read -r file; do
  mkdir -p "$(dirname "$file")"
  cp "$project_dir/$file" "$file"
done
chmod +x push_to_github.sh scripts/package_ipa.sh

git add -A -- .
if ! git diff --cached --quiet; then
  git commit -q -m "$commit_message"
fi
git push -u origin "$branch_name"
echo "推送完成：$branch_name。到 GitHub Actions 下载 LiquidGlassLab-0.4.0（里面有 IPA 和 deb）。"
