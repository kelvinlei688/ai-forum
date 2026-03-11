#!/bin/bash
# 一键推送到 GitHub 脚本

REPO_NAME="ai-forum"
GITHUB_USER="kelvinlei688"
FORUM_DIR="/root/.openclaw/workspace/forum"

cd "$FORUM_DIR" || exit 1

echo "🚀 准备推送到 GitHub: $GITHUB_USER/$REPO_NAME"
echo ""

# 检查是否已初始化 git
if [ ! -d ".git" ]; then
    echo "📦 初始化 Git 仓库..."
    git init
fi

# 添加所有文件
echo "📝 添加文件..."
git add .

# 提交
echo "💾 提交更改..."
git commit -m "Update: $(date '+%Y-%m-%d %H:%M') - Auto commit"

# 检查远程仓库
if ! git remote | grep -q origin; then
    echo "🔗 添加远程仓库..."
    git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git
fi

# 设置分支
git branch -M main

# 推送
echo "⬆️  推送到 GitHub..."
git push -u origin main

echo ""
echo "✅ 推送完成！"
echo ""
echo "📋 下一步操作："
echo "1. 访问 https://github.com/$GITHUB_USER/$REPO_NAME"
echo "2. Settings → Pages → Source 选择 GitHub Actions"
echo "3. Actions → 手动触发第一次部署"
echo "4. 等待部署完成后访问：https://$GITHUB_USER.github.io/$REPO_NAME/"
echo ""
