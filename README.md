# 🤖 AI 热点论坛

自动收集 AI 界热点新闻的简易论坛系统。

**🌐 公网访问**: https://kelvinlei688.github.io/ai-forum/

## 📁 文件结构

```
forum/
├── index.html      # 论坛前端页面
├── data.json       # 帖子数据存储
├── publish.sh      # 自动发布脚本
└── README.md       # 本文件
```

## 🚀 访问方式

**本地访问**: http://localhost:8888

**外部访问**: 需要配置服务器防火墙和端口转发

## ⏰ 自动更新

- **收集时间**: 每小时整点（:00）
- **发布时间**: 每小时 5 分（:05）
- **自动刷新**: 页面每 60 秒自动刷新

## 🔧 手动操作

### 手动发布帖子
```bash
cd /root/.openclaw/workspace/forum
bash publish.sh
```

### 查看帖子数据
```bash
cat data.json | jq '.posts'
```

### 重启 HTTP 服务器
```bash
# 停止现有服务器
pkill -f "python3 -m http.server 8888"

# 启动新服务器
cd /root/.openclaw/workspace/forum
nohup python3 -m http.server 8888 > http-server.log 2>&1 &
```

## 📊 数据来源

- Hacker News 热门帖子（AI 相关）
- 自动过滤关键词：AI, LLM, GPT, Claude, Gemini, neural, machine learning, transformer, diffusion, model, deep learning

## 🎨 功能特点

- ✅ 自动收集 AI 热点
- ✅ 去重机制（避免重复帖子）
- ✅ 时间戳和热度分数
- ✅ 分类标签（AI, Business, Tech）
- ✅ 响应式设计（手机/电脑通用）
- ✅ 自动刷新（60 秒）
- ✅ 深色主题

## 📝 Cron 任务

```bash
# 查看当前 cron
crontab -l

# 每小时 0 分：收集 AI 新闻
0 * * * * /root/.openclaw/workspace/scripts/ai-news-hourly.sh

# 每小时 5 分：发布到论坛
5 * * * * /root/.openclaw/workspace/forum/publish.sh
```

---

**创建时间**: 2026-03-11
**创建者**: OpenClaw Agent
