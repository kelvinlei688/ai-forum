#!/bin/bash
# AI 热点论坛自动发布脚本 - GitHub Actions 兼容版本

set -e  # 遇到错误立即退出

FORUM_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_FILE="$FORUM_DIR/data.json"
TIMESTAMP=$(date -Iseconds)
TIMESTAMP_READABLE=$(date "+%Y-%m-%d %H:%M")

echo "🕐 [$TIMESTAMP_READABLE] 开始收集 AI 热点..."
echo ""

# 临时文件存储新帖子
NEW_POSTS_FILE=$(mktemp)
POST_COUNT=0
FIRST=true

# ========== 渠道 1: Hacker News ==========
echo "📰 渠道 1: Hacker News..."
HN_IDS=$(curl -s --max-time 15 "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq -r '.[0:30] | .[]' 2>/dev/null || echo "")

if [ -n "$HN_IDS" ]; then
    for id in $HN_IDS; do
        ITEM=$(curl -s --max-time 5 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null || echo "{}")
        TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null || echo "")
        SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null || echo "0")
        URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null || echo "")
        
        if [ -n "$TITLE" ] && echo "$TITLE" | grep -qiE "ai|llm|gpt|claude|gemini|neural|machine learning|transformer|diffusion|model|deep learning"; then
            if echo "$TITLE" | grep -qiE "business|funding|raises|\\\$|billion|million"; then
                TAGS_JSON='["AI", "Business"]'
            elif echo "$TITLE" | grep -qiE "tech|code|github|launch"; then
                TAGS_JSON='["AI", "Tech"]'
            else
                TAGS_JSON='["AI"]'
            fi
            
            POST_JSON=$(jq -n \
                --arg id "hn_$(date +%s%N)_$POST_COUNT" \
                --arg title "$TITLE" \
                --arg content "Hacker News 热门 AI 帖子，$SCORE 分支持" \
                --arg url "$URL" \
                --argjson score "$SCORE" \
                --argjson tags "$TAGS_JSON" \
                --arg source "Hacker News" \
                --arg timestamp "$TIMESTAMP" \
                '{id: $id, title: $title, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
            
            echo "$POST_JSON" >> "$NEW_POSTS_FILE"
            POST_COUNT=$((POST_COUNT + 1))
            echo "   🔥 $TITLE (${SCORE}分)"
            
            if [ $POST_COUNT -ge 3 ]; then
                break
            fi
        fi
    done
fi

# ========== 渠道 2: GitHub Trending ==========
echo ""
echo "📰 渠道 2: GitHub Trending..."
GH_API="https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=3"
GH_DATA=$(curl -s --max-time 15 "$GH_API" 2>/dev/null || echo '{"items":[]}')

for i in 0 1 2; do
    NAME=$(echo "$GH_DATA" | jq -r ".items[$i].full_name // empty" 2>/dev/null || echo "")
    DESC=$(echo "$GH_DATA" | jq -r ".items[$i].description // empty" 2>/dev/null || echo "")
    STARS=$(echo "$GH_DATA" | jq -r ".items[$i].stargazers_count // 0" 2>/dev/null || echo "0")
    HTML_URL=$(echo "$GH_DATA" | jq -r ".items[$i].html_url // empty" 2>/dev/null || echo "")
    
    if [ -n "$NAME" ] && [ "$NAME" != "null" ] && [ "$NAME" != "" ]; then
        DESC_CLEAN="${DESC:-AI 相关开源项目}"
        
        POST_JSON=$(jq -n \
            --arg id "gh_$(date +%s%N)_$i" \
            --arg title "⭐ GitHub: $NAME" \
            --arg content "$DESC_CLEAN" \
            --arg url "$HTML_URL" \
            --argjson stars "$STARS" \
            --argjson tags '["AI", "OpenSource"]' \
            --arg source "GitHub" \
            --arg timestamp "$TIMESTAMP" \
            '{id: $id, title: $title, content: $content, url: $url, stars: $stars, tags: $tags, source: $source, timestamp: $timestamp}')
        
        echo "$POST_JSON" >> "$NEW_POSTS_FILE"
        POST_COUNT=$((POST_COUNT + 1))
        echo "   ⭐ $NAME ($STARS ⭐)"
    fi
done

# 构建新帖子数组
NEW_POSTS_ARRAY="["
if [ -s "$NEW_POSTS_FILE" ]; then
    while IFS= read -r line; do
        if [ "$FIRST" = true ]; then
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$line"
            FIRST=false
        else
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$line"
        fi
    done < "$NEW_POSTS_FILE"
fi
NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY]"

rm -f "$NEW_POSTS_FILE"

echo ""
echo "✅ 共收集到 $POST_COUNT 篇内容"

# 读取现有帖子
if [ -f "$DATA_FILE" ]; then
    EXISTING_POSTS=$(jq '.posts // []' "$DATA_FILE" 2>/dev/null || echo "[]")
    CREATED_TIME=$(jq -r '.created // "'$TIMESTAMP'"' "$DATA_FILE" 2>/dev/null || echo "$TIMESTAMP")
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
     ($unique_new + $existing)' 2>/dev/null || echo "$EXISTING_POSTS")

# 保存数据
jq -n \
    --argjson posts "$MERGED_POSTS" \
    --arg created "$CREATED_TIME" \
    --arg lastUpdated "$TIMESTAMP" \
    '{posts: $posts, created: $created, lastUpdated: $lastUpdated}' > "$DATA_FILE"

echo "🎉 完成！论坛数据已更新"
echo "📁 数据文件：$DATA_FILE"
echo ""
echo "📊 帖子统计:"
jq '.posts | length' "$DATA_FILE" 2>/dev/null || echo "0"
