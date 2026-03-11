#!/bin/bash
# AI 热点论坛自动发布脚本 - Bash 版本 v2

FORUM_DIR="/root/.openclaw/workspace/forum"
DATA_FILE="$FORUM_DIR/data.json"
TIMESTAMP=$(date -Iseconds)
TIMESTAMP_READABLE=$(date "+%Y-%m-%d %H:%M")

mkdir -p "$FORUM_DIR"

echo "🕐 [$TIMESTAMP_READABLE] 开始收集 AI 热点..."

# 获取 HN 前 50 个故事 ID
HN_IDS=$(curl -s --max-time 10 "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq -r '.[0:50] | .[]' 2>/dev/null)

if [ -z "$HN_IDS" ]; then
    echo "⚠️ 无法获取 Hacker News 数据"
    exit 1
fi

# 临时文件存储新帖子数组
NEW_POSTS_ARRAY="["
POST_COUNT=0
FIRST=true

echo "📰 正在检查 AI 相关帖子..."

for id in $HN_IDS; do
    ITEM=$(curl -s --max-time 3 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null)
    TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null)
    SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null)
    URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null)
    
    # 检查是否 AI 相关
    if echo "$TITLE" | grep -qiE "ai|llm|gpt|claude|gemini|neural|machine learning|transformer|diffusion|model|deep learning"; then
        # 确定标签
        if echo "$TITLE" | grep -qiE "business|funding|raises|\\\$|billion|million"; then
            TAGS_JSON='["AI", "Business"]'
        elif echo "$TITLE" | grep -qiE "tech|code|github|launch"; then
            TAGS_JSON='["AI", "Tech"]'
        else
            TAGS_JSON='["AI"]'
        fi
        
        # 构建 JSON 对象
        POST_JSON=$(jq -n \
            --arg id "post_$(date +%s%N)_$POST_COUNT" \
            --arg title "$TITLE" \
            --arg content "Hacker News 热门 AI 帖子，$SCORE 分支持" \
            --arg url "$URL" \
            --argjson score "$SCORE" \
            --argjson tags "$TAGS_JSON" \
            --arg source "Hacker News" \
            --arg timestamp "$TIMESTAMP" \
            '{id: $id, title: $title, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
        
        if [ "$FIRST" = true ]; then
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$POST_JSON"
            FIRST=false
        else
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$POST_JSON"
        fi
        
        POST_COUNT=$((POST_COUNT + 1))
        echo "   🔥 $TITLE (${SCORE}分)"
        
        # 限制最多 5 篇
        if [ $POST_COUNT -ge 5 ]; then
            break
        fi
    fi
done

NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY]"

if [ $POST_COUNT -eq 0 ]; then
    echo "⚠️ 未获取到 AI 相关帖子"
    exit 0
fi

echo "✅ 找到 $POST_COUNT 篇 AI 相关帖子"

# 读取现有帖子
if [ -f "$DATA_FILE" ]; then
    EXISTING_POSTS=$(jq '.posts // []' "$DATA_FILE" 2>/dev/null)
    CREATED_TIME=$(jq -r '.created // "'$TIMESTAMP'"' "$DATA_FILE" 2>/dev/null)
else
    EXISTING_POSTS="[]"
    CREATED_TIME="$TIMESTAMP"
fi

# 去重合并（基于 title）
MERGED_POSTS=$(jq -n \
    --argjson existing "$EXISTING_POSTS" \
    --argjson new "$NEW_POSTS_ARRAY" \
    '($existing | map(.title) | unique) as $existing_titles | 
     ($new | map(select(.title as $t | $existing_titles | index($t) | not))) as $unique_new |
     ($unique_new + $existing)')

# 保存数据
jq -n \
    --argjson posts "$MERGED_POSTS" \
    --arg created "$CREATED_TIME" \
    --arg lastUpdated "$TIMESTAMP" \
    '{posts: $posts, created: $created, lastUpdated: $lastUpdated}' > "$DATA_FILE"

echo "🎉 完成！发布了 $POST_COUNT 篇新帖子"
echo "📁 数据文件：$DATA_FILE"
echo "🌐 论坛页面：$FORUM_DIR/index.html"
