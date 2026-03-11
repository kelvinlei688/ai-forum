# 🤖 AI 热点论坛

自动收集 AI 界热点新闻的简易论坛系统。

**🌐 公网访问**: https://kelvinlei688.github.io/ai-forum/

---

## 🚀 部署到 GitHub Pages

### 第一步：创建 GitHub 仓库

1. 登录 GitHub (kelvinlei688)
2. 创建新仓库，名称：`ai-forum`
3. 设为 **Public**
4. 不要初始化 README

### 第二步：推送代码到 GitHub

```bash
cd /root/.openclaw/workspace/forum

# 初始化 git
git init
git add .
git commit -m "Initial commit: AI Forum"

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/kelvinlei688/ai-forum.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

### 第三步：配置 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Source** 选择：**GitHub Actions**
3. 保存

### 第四步：配置 GitHub Actions 权限

1. 进入仓库 **Settings** → **Actions** → **General**
2. 确保 **Allow all actions and reusable workflows** 已启用
3. 进入 **Settings** → **Actions** → **Permissions**
4. 确保 **Read and write permissions** 已启用

### 第五步：手动触发第一次部署

1. 进入仓库 **Actions** 标签
2. 点击 **"Deploy AI Forum to GitHub Pages"** 工作流
3. 点击 **"Run workflow"** → **"Run workflow"**
4. 等待部署完成（约 1-2 分钟）

### 第六步：访问你的论坛

部署成功后，访问：
```
https://kelvinlei688.github.io/ai-forum/
```

---

## ⏰ 自动更新

- **GitHub Actions** 每小时 5 分自动运行（UTC 时间）
- 对应北京时间：**每小时 13 分**
- 自动收集 AI 热点并部署

---

## 📁 文件结构

```
forum/
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 配置
├── index.html              # 论坛前端页面
├── data.json               # 帖子数据存储
├── publish.sh              # 数据收集脚本
└── README.md               # 本文件
```

---

## 🔧 手动操作

### 本地测试
```bash
cd /root/.openclaw/workspace/forum

# 运行收集脚本
bash publish.sh

# 启动本地服务器
python3 -m http.server 8888

# 访问 http://localhost:8888
```

### 查看帖子数据
```bash
cat data.json | jq '.posts'
```

---

## 📊 数据来源

- Hacker News 热门帖子（AI 相关）
- 自动过滤关键词：AI, LLM, GPT, Claude, Gemini, neural, machine learning, transformer, diffusion, model, deep learning

---

## 🎨 功能特点

- ✅ 自动收集 AI 热点
- ✅ 去重机制（避免重复帖子）
- ✅ 时间戳和热度分数
- ✅ 分类标签（AI, Business, Tech）
- ✅ 响应式设计（手机/电脑通用）
- ✅ 自动刷新（60 秒）
- ✅ 深色主题
- ✅ GitHub Pages 免费托管
- ✅ GitHub Actions 自动部署

---

## 🔗 相关链接

- **GitHub 仓库**: https://github.com/kelvinlei688/ai-forum
- **在线论坛**: https://kelvinlei688.github.io/ai-forum/
- **GitHub Actions**: https://github.com/kelvinlei688/ai-forum/actions

---

**创建时间**: 2026-03-11
**创建者**: OpenClaw Agent for Kelvin
