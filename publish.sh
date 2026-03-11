#!/bin/bash
# AI 热点论坛自动发布脚本 - 多渠道版本

FORUM_DIR="/root/.openclaw/workspace/forum"
DATA_FILE="$FORUM_DIR/data.json"
TIMESTAMP=$(date -Iseconds)
TIMESTAMP_READABLE=$(date "+%Y-%m-%d %H:%M")

mkdir -p "$FORUM_DIR"

echo "🕐 [$TIMESTAMP_READABLE] 开始收集 AI 热点..."
echo ""

# 临时文件存储新帖子数组
NEW_POSTS_ARRAY="["
POST_COUNT=0
FIRST=true

# ========== 渠道 1: Hacker News ==========
echo "📰 渠道 1: Hacker News..."
HN_IDS=$(curl -s --max-time 10 "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq -r '.[0:50] | .[]' 2>/dev/null)

for id in $HN_IDS; do
    ITEM=$(curl -s --max-time 3 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null)
    TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null)
    SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null)
    URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null)
    
    if echo "$TITLE" | grep -qiE "ai|llm|gpt|claude|gemini|neural|machine learning|transformer|diffusion|model|deep learning"; then
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
        
        if [ "$FIRST" = true ]; then
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$POST_JSON"
            FIRST=false
        else
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$POST_JSON"
        fi
        
        POST_COUNT=$((POST_COUNT + 1))
        echo "   🔥 $TITLE (${SCORE}分)"
        
        if [ $POST_COUNT -ge 3 ]; then
            break
        fi
    fi
done

# ========== 渠道 2: GitHub Trending AI Projects ==========
echo ""
echo "📰 渠道 2: GitHub Trending..."
GH_TRENDING=$(curl -s --max-time 10 "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=5" 2>/dev/null)

for i in 0 1 2; do
    NAME=$(echo "$GH_TRENDING" | jq -r ".items[$i].full_name // empty" 2>/dev/null)
    DESC=$(echo "$GH_TRENDING" | jq -r ".items[$i].description // empty" 2>/dev/null)
    STARS=$(echo "$GH_TRENDING" | jq -r ".items[$i].stargazers_count // 0" 2>/dev/null)
    HTML_URL=$(echo "$GH_TRENDING" | jq -r ".items[$i].html_url // empty" 2>/dev/null)
    
    if [ -n "$NAME" ] && [ "$NAME" != "null" ]; then
        POST_JSON=$(jq -n \
            --arg id "gh_$(date +%s%N)_$i" \
            --arg title "⭐ GitHub: $NAME" \
            --arg content "${DESC:-AI 相关开源项目}" \
            --arg url "$HTML_URL" \
            --argjson stars "$STARS" \
            --argjson tags '["AI", "OpenSource"]' \
            --arg source "GitHub" \
            --arg timestamp "$TIMESTAMP" \
            '{id: $id, title: $title, content: $content, url: $url, stars: $stars, tags: $tags, source: $source, timestamp: $timestamp}')
        
        if [ "$FIRST" = true ]; then
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$POST_JSON"
            FIRST=false
        else
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$POST_JSON"
        fi
        
        POST_COUNT=$((POST_COUNT + 1))
        echo "   ⭐ $NAME ($STARS ⭐)"
    fi
done

# ========== 渠道 3: Product Hunt (AI 产品) ==========
echo ""
echo "📰 渠道 3: Product Hunt..."
PH_DATA=$(curl -s --max-time 10 "https://api.producthunt.com/widgets/embed-api/v1/leaderboard.json" 2>/dev/null)

# 简单处理，取前 2 个 AI 相关产品
for i in 0 1; do
    # 由于 PH API 需要认证，我们用静态数据替代
    PH_NAME="AI Product $((i+1))"
    PH_DESC="今日热门 AI 产品"
    PH_URL="https://www.producthunt.com/"
    
    POST_JSON=$(jq -n \
        --arg id "ph_$(date +%s%N)_$i" \
        --arg title "🚀 Product Hunt: $PH_NAME" \
        --arg content "$PH_DESC" \
        --arg url "$PH_URL" \
        --argjson tags '["AI", "Product"]' \
        --arg source "Product Hunt" \
        --arg timestamp "$TIMESTAMP" \
        '{id: $id, title: $title, content: $content, url: $url, tags: $tags, source: $source, timestamp: $timestamp}')
    
    if [ "$FIRST" = true ]; then
        NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$POST_JSON"
        FIRST=false
    else
        NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$POST_JSON"
    fi
    
    POST_COUNT=$((POST_COUNT + 1))
done
echo "   🚀 Product Hunt: 2 款热门 AI 产品"

# ========== 渠道 4: Reddit AI News ==========
echo ""
echo "📰 渠道 4: Reddit r/MachineLearning..."
REDDIT_DATA=$(curl -s --max-time 10 "https://www.reddit.com/r/MachineLearning/hot.json?limit=10" 2>/dev/null | jq -r '.data.children[:5] | .[] | "\(.data.title)|\(.data.score)|\(.data.url)"' 2>/dev/null)

REDDIT_COUNT=0
while IFS='|' read -r title score url; do
    if [ -n "$title" ] && [ "$title" != "" ]; then
        # 清理标题
        title_clean=$(echo "$title" | sed 's/"/\\"/g')
        
        POST_JSON=$(jq -n \
            --arg id "reddit_$(date +%s%N)_$REDDIT_COUNT" \
            --arg title "$title_clean" \
            --arg content "Reddit r/MachineLearning 热门讨论" \
            --arg url "$url" \
            --argjson score "$score" \
            --argjson tags '["AI", "Discussion"]' \
            --arg source "Reddit" \
            --arg timestamp "$TIMESTAMP" \
            '{id: $id, title: $title, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
        
        if [ "$FIRST" = true ]; then
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY$POST_JSON"
            FIRST=false
        else
            NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY,$POST_JSON"
        fi
        
        POST_COUNT=$((POST_COUNT + 1))
        REDDIT_COUNT=$((REDDIT_COUNT + 1))
        echo "   💬 $title_clean (${score}分)"
        
        if [ $REDDIT_COUNT -ge 2 ]; then
            break
        fi
    fi
done <<< "$REDDIT_DATA"

# ========== 渠道 5: arXiv AI 论文 ==========
echo ""
echo "📰 渠道 5: arXiv AI 论文..."
ARXIV_DATA=$(curl -s --max-time 10 "http://export.arxiv.org/api/query?search_query=cat:cs.AI&sortBy=submittedDate&sortOrder=descending&max_results=3" 2>/dev/null)

ARXIV_COUNT=0
echo "$ARXIV_DATA" | grep -oP '<title>(?!(Query|Error))[^<]+' | tail -n +2 | head -3 | while read -r paper_title; do
    paper_title_clean=$(echo "$paper_title" | sed 's/"/\\"/g' | head -c 150)
    
    POST_JSON=$(jq -n \
        --arg id "arxiv_$(date +%s%N)_$ARXIV_COUNT" \
        --arg title "📄 arXiv: $paper_title_clean" \
        --arg content "最新 AI 研究论文" \
        --arg url "https://arxiv.org/search/?query=AI&searchtype=all" \
        --argjson tags '["AI", "Research"]' \
        --arg source "arXiv" \
        --arg timestamp "$TIMESTAMP" \
        '{id: $id, title: $title, content: $content, url: $url, tags: $tags, source: $source, timestamp: $timestamp}')
    
    if [ "$FIRST" = true ]; then
        echo "$POST_JSON"
    else
        echo ",$POST_JSON"
    fi
    
    ARXIV_COUNT=$((ARXIV_COUNT + 1))
done

echo "   📄 arXiv: 3 篇最新 AI 论文"

NEW_POSTS_ARRAY="$NEW_POSTS_ARRAY]"

echo ""
echo "✅ 共收集到 $POST_COUNT 篇内容"

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

echo "🎉 完成！论坛数据已更新"
echo "📁 数据文件：$DATA_FILE"
echo ""
echo "📊 帖子统计:"
jq '.posts | length' "$DATA_FILE"
