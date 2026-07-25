@echo off
chcp 65001 >nul
setlocal
rem 从上游仓库同步最新代码，保留本地新增的文档。
rem 用法：sync-upstream.bat [分支名]   分支名默认为 main

set "BRANCH=%~1"
if "%BRANCH%"=="" set "BRANCH=main"
set "UPSTREAM_URL=https://github.com/cyneprepou4uk/NES-Games-Disassembly.git"

cd /d "%~dp0"

rem 首次运行时自动登记上游远端
git remote get-url upstream >nul 2>&1
if errorlevel 1 (
	echo 登记上游远端：%UPSTREAM_URL%
	git remote add upstream "%UPSTREAM_URL%"
)

rem 有未提交改动就先停下，避免同步过程把工作区搅乱
for /f %%i in ('git status --porcelain') do (
	echo 工作区有未提交的改动，请先提交或 stash 后再同步：
	git status --short
	exit /b 1
)

echo 拉取上游...
git fetch upstream
if errorlevel 1 exit /b 1

for /f %%i in ('git rev-parse HEAD') do set "BEFORE=%%i"

echo 把本地提交重放到上游最新代码之上...
git rebase upstream/%BRANCH%
if errorlevel 1 (
	echo.
	echo rebase 遇到冲突。解决冲突后执行：git rebase --continue
	echo 想放弃本次同步则执行：git rebase --abort
	exit /b 1
)

for /f %%i in ('git rev-parse HEAD') do set "AFTER=%%i"
if "%BEFORE%"=="%AFTER%" (
	echo 已是最新，无需同步。
) else (
	echo 同步完成。本地领先上游的提交：
	git --no-pager log --oneline upstream/%BRANCH%..HEAD
	echo.
	echo 接下来推送到自己的 fork（因为 rebase 改写了历史，需要 --force-with-lease）：
	echo     git push --force-with-lease origin %BRANCH%
)

endlocal
