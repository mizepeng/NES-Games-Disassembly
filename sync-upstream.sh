#!/usr/bin/env bash
# 从上游仓库同步最新代码，保留本地新增的文档。
# 用法：./sync-upstream.sh [分支名]   分支名默认为 main
set -euo pipefail

BRANCH="${1:-main}"
UPSTREAM_URL="https://github.com/cyneprepou4uk/NES-Games-Disassembly.git"

cd "$(dirname "$0")"

# 首次运行时自动登记上游远端
if ! git remote get-url upstream >/dev/null 2>&1; then
	echo "登记上游远端：$UPSTREAM_URL"
	git remote add upstream "$UPSTREAM_URL"
fi

# 有未提交改动就先停下，避免同步过程把工作区搅乱
if [ -n "$(git status --porcelain)" ]; then
	echo "工作区有未提交的改动，请先提交或 stash 后再同步："
	git status --short
	exit 1
fi

echo "拉取上游..."
git fetch upstream

BEFORE="$(git rev-parse HEAD)"

echo "把本地提交重放到上游最新代码之上..."
git rebase "upstream/$BRANCH"

AFTER="$(git rev-parse HEAD)"
if [ "$BEFORE" = "$AFTER" ]; then
	echo "已是最新，无需同步。"
else
	echo "同步完成。本地领先上游的提交："
	git --no-pager log --oneline "upstream/$BRANCH..HEAD"
	echo
	echo "接下来推送到自己的 fork（因为 rebase 改写了历史，需要 --force-with-lease）："
	echo "    git push --force-with-lease origin $BRANCH"
fi
