#!/bin/bash
# AI 热点论坛自动发布脚本 - GitHub Actions 兼容版本
# 支持三个分类: AI热点 | 军事 | 数码科技，每个分类每日更新5条热点

set -e  # 遇到错误立即退出

FORUM_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_FILE="$FORUM_DIR/data.json"
TIMESTAMP=$(date -Iseconds)
TIMESTAMP_READABLE=$(date "+%Y-%m-%d %H:%M")

echo "🕐 [$TIMESTAMP_READABLE] 开始收集热点..."
echo ""

# 临时文件存储新帖子
NEW_POSTS_FILE=$(mktemp)
POST_COUNT=0
FIRST=true

# ========== 分类 1: AI 热点 (Hacker News + GitHub) ==========
echo "🤖 分类 1: AI 热点..."

# Hacker News AI 热门帖子
HN_IDS=$(curl -s --max-time 15 "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq -r '.[0:50] | .[]' 2>/dev/null || echo "")

if [ -n "$HN_IDS" ]; then
    AI_COLLECTED=0
    for id in $HN_IDS; do
        if [ $AI_COLLECTED -ge 3 ]; then
            break
        fi
        ITEM=$(curl -s --max-time 5 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null || echo "{}")
        TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null || echo "")
        SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null || echo "0")
        URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null || echo "")
        
        if [ -n "$TITLE" ] && echo "$TITLE" | grep -qiE "ai|llm|gpt|claude|gemini|neural|machine learning|transformer|diffusion|model|deep learning"; then
            if echo "$TITLE" | grep -qiE "business|funding|raises|fund|\$|billion|million"; then
                TAGS_JSON='["AI", "Business"]'
            elif echo "$TITLE" | grep -qiE "tech|code|github|launch|open source"; then
                TAGS_JSON='["AI", "Tech"]'
            else
                TAGS_JSON='["AI"]'
            fi
            
            CATEGORY="AI热点"
            POST_JSON=$(jq -n \
                --arg id "hn_$(date +%s%N)_$POST_COUNT" \
                --arg title "$TITLE" \
                --arg category "$CATEGORY" \
                --arg content "Hacker News 热门 AI 帖子，$SCORE 分支持" \
                --arg url "$URL" \
                --argjson score "$SCORE" \
                --argjson tags "$TAGS_JSON" \
                --arg source "Hacker News" \
                --arg timestamp "$TIMESTAMP" \
                '{id: $id, title: $title, category: $category, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
            
            echo "$POST_JSON" >> "$NEW_POSTS_FILE"
            POST_COUNT=$((POST_COUNT + 1))
            AI_COLLECTED=$((AI_COLLECTED + 1))
            echo "   🔥 $TITLE (${SCORE}分)"
        fi
    done
fi

# GitHub Trending AI
GH_API="https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=2"
GH_DATA=$(curl -s --max-time 15 "$GH_API" 2>/dev/null || echo '{"items":[]}')

for i in 0 1; do
    if [ $AI_COLLECTED -ge 5 ]; then
        break
    fi
    NAME=$(echo "$GH_DATA" | jq -r ".items[$i].full_name // empty" 2>/dev/null || echo "")
    DESC=$(echo "$GH_DATA" | jq -r ".items[$i].description // empty" 2>/dev/null || echo "")
    STARS=$(echo "$GH_DATA" | jq -r ".items[$i].stargazers_count // 0" 2>/dev/null || echo "0")
    HTML_URL=$(echo "$GH_DATA" | jq -r ".items[$i].html_url // empty" 2>/dev/null || echo "")
    
    if [ -n "$NAME" ] && [ "$NAME" != "null" ] && [ "$NAME" != "" ]; then
        DESC_CLEAN="${DESC:-AI 相关开源项目}"
        CATEGORY="AI热点"
        
        POST_JSON=$(jq -n \
            --arg id "gh_$(date +%s%N)_$POST_COUNT" \
            --arg title "⭐ GitHub: $NAME" \
            --arg category "$CATEGORY" \
            --arg content "$DESC_CLEAN" \
            --arg url "$HTML_URL" \
            --argjson stars "$STARS" \
            --argjson tags '["AI", "OpenSource"]' \
            --arg source "GitHub" \
            --arg timestamp "$TIMESTAMP" \
            '{id: $id, title: $title, category: $category, content: $content, url: $url, stars: $stars, tags: $tags, source: $source, timestamp: $timestamp}')
        
        echo "$POST_JSON" >> "$NEW_POSTS_FILE"
        POST_COUNT=$((POST_COUNT + 1))
        AI_COLLECTED=$((AI_COLLECTED + 1))
        echo "   ⭐ $NAME ($STARS ⭐)"
    fi
done

echo "   ✅ AI热点: 收集到 $AI_COLLECTED 条"
echo ""

# ========== 分类 2: 军事热点 (Reddit r/worldnews + 过滤军事关键词) ==========
echo "🗡️  分类 2: 军事热点..."

# Reddit worldnews top
MILITARY_COLLECTED=0
REDDIT_DATA=$(curl -s --max-time 20 "https://www.reddit.com/r/worldnews/top/.json?limit=25&t=day" 2>/dev/null || echo '{"data":{"children":[]}}')

if [ -n "$REDDIT_DATA" ]; then
    for i in $(seq 0 24); do
        if [ $MILITARY_COLLECTED -ge 5 ]; then
            break
        fi
        TITLE=$(echo "$REDDIT_DATA" | jq -r ".data.children[$i].data.title // empty" 2>/dev/null || echo "")
        SCORE=$(echo "$REDDIT_DATA" | jq -r ".data.children[$i].data.score // 0" 2>/dev/null || echo "0")
        URL=$(echo "$REDDIT_DATA" | jq -r ".data.children[$i].data.url // empty" 2>/dev/null || echo "")
        
        if [ -n "$TITLE" ] && echo "$TITLE" | grep -qiE "military|army|navy|air force|defense|war|weapon|china|russia|ukraine|us|north korea|missile|nuclear|tank|plane|ship|armor"; then
            CATEGORY="军事"
            TAGS_JSON='["军事"]'
            
            POST_JSON=$(jq -n \
                --arg id "mil_$(date +%s%N)_$POST_COUNT" \
                --arg title "$TITLE" \
                --arg category "$CATEGORY" \
                --arg content "Reddit 今日热门军事新闻，$SCORE 分点赞" \
                --arg url "$URL" \
                --argjson score "$SCORE" \
                --argjson tags "$TAGS_JSON" \
                --arg source "Reddit" \
                --arg timestamp "$TIMESTAMP" \
                '{id: $id, title: $title, category: $category, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
            
            echo "$POST_JSON" >> "$NEW_POSTS_FILE"
            POST_COUNT=$((POST_COUNT + 1))
            MILITARY_COLLECTED=$((MILITARY_COLLECTED + 1))
            echo "   🗡️  $TITLE (${SCORE}票)"
        fi
    done
fi

# 补够5条 - 如果不够从HN获取
if [ $MILITARY_COLLECTED -lt 5 ] && [ -n "$HN_IDS" ]; then
    for id in $HN_IDS; do
        if [ $MILITARY_COLLECTED -ge 5 ]; then
            break
        fi
        ITEM=$(curl -s --max-time 5 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null || echo "{}")
        TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null || echo "")
        SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null || echo "0")
        URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null || echo "")
        
        if [ -n "$TITLE" ] && echo "$TITLE" | grep -qiE "war|military|defense|china|russia|ukraine|nuclear|missile"; then
            CATEGORY="军事"
            TAGS_JSON='["军事"]'
            
            POST_JSON=$(jq -n \
                --arg id "hnmil_$(date +%s%N)_$POST_COUNT" \
                --arg title "$TITLE" \
                --arg category "$CATEGORY" \
                --arg content "Hacker News 热门军事话题，$SCORE 分支持" \
                --arg url "$URL" \
                --argjson score "$SCORE" \
                --argjson tags "$TAGS_JSON" \
                --arg source "Hacker News" \
                --arg timestamp "$TIMESTAMP" \
                '{id: $id, title: $title, category: $category, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
            
            echo "$POST_JSON" >> "$NEW_POSTS_FILE"
            POST_COUNT=$((POST_COUNT + 1))
            MILITARY_COLLECTED=$((MILITARY_COLLECTED + 1))
            echo "   🗡️  $TITLE (${SCORE}分)"
        fi
    done
fi

echo "   ✅ 军事热点: 收集到 $MILITARY_COLLECTED 条"
echo ""

# ========== 分类 3: 数码科技 ==========
echo "💻 分类 3: 数码科技..."

DIGI_COLLECTED=0
# Hacker News 找数码科技
if [ -n "$HN_IDS" ]; then
    for id in $HN_IDS; do
        if [ $DIGI_COLLECTED -ge 5 ]; then
            break
        fi
        ITEM=$(curl -s --max-time 5 "https://hacker-news.firebaseio.com/v0/item/$id.json" 2>/dev/null || echo "{}")
        TITLE=$(echo "$ITEM" | jq -r '.title // empty' 2>/dev/null || echo "")
        SCORE=$(echo "$ITEM" | jq -r '.score // 0' 2>/dev/null || echo "0")
        URL=$(echo "$ITEM" | jq -r '.url // empty' 2>/dev/null || echo "")
        
        if [ -n "$TITLE" ] && echo "$TITLE" | grep -qiE "apple|iphone|mac|samsung|galaxy|google|pixel|tech|gadget|phone|laptop|computer|chip|cpu|gpu|camera|digital"; then
            # 排除已经被分到AI的
            if ! echo "$TITLE" | grep -qiE "ai|llm|gpt|claude|gemini"; then
                CATEGORY="数码科技"
                TAGS_JSON='["数码科技"]'
                
                POST_JSON=$(jq -n \
                    --arg id "dig_$(date +%s%N)_$POST_COUNT" \
                    --arg title "$TITLE" \
                    --arg category "$CATEGORY" \
                    --arg content "Hacker News 热门数码科技话题，$SCORE 分支持" \
                    --arg url "$URL" \
                    --argjson score "$SCORE" \
                    --argjson tags "$TAGS_JSON" \
                    --arg source "Hacker News" \
                    --arg timestamp "$TIMESTAMP" \
                    '{id: $id, title: $title, category: $category, content: $content, url: $url, score: $score, tags: $tags, source: $source, timestamp: $timestamp}')
                
                echo "$POST_JSON" >> "$NEW_POSTS_FILE"
                POST_COUNT=$((POST_COUNT + 1))
                DIGI_COLLECTED=$((DIGI_COLLECTED + 1))
                echo "   💻 $TITLE (${SCORE}分)"
            fi
        fi
    done
fi

# GitHub 找开源数码项目
if [ $DIGI_COLLECTED -lt 5 ]; then
    GH_API="https://api.github.com/search/repositories?q=topic:gadget+topic:hardware&sort=stars&order=desc&per_page=5"
    GH_DATA=$(curl -s --max-time 15 "$GH_API" 2>/dev/null || echo '{"items":[]}')

    for i in 0 1 2 3 4; do
        if [ $DIGI_COLLECTED -ge 5 ]; then
            break
        fi
        NAME=$(echo "$GH_DATA" | jq -r ".items[$i].full_name // empty" 2>/dev/null || echo "")
        DESC=$(echo "$GH_DATA" | jq -r ".items[$i].description // empty" 2>/dev/null || echo "")
        STARS=$(echo "$GH_DATA" | jq -r ".items[$i].stargazers_count // 0" 2>/dev/null || echo "0")
        HTML_URL=$(echo "$GH_DATA" | jq -r ".items[$i].html_url // empty" 2>/dev/null || echo "")
        
        if [ -n "$NAME" ] && [ "$NAME" != "null" ] && [ "$NAME" != "" ]; then
            DESC_CLEAN="${DESC:-数码开源项目}"
            CATEGORY="数码科技"
            
            POST_JSON=$(jq -n \
                --arg id "ghdig_$(date +%s%N)_$POST_COUNT" \
                --arg title "💻 GitHub: $NAME" \
                --arg category "$CATEGORY" \
                --arg content "$DESC_CLEAN" \
                --arg url "$HTML_URL" \
                --argjson stars "$STARS" \
                --argjson tags '["数码科技", "OpenSource"]' \
                --arg source "GitHub" \
                --arg timestamp "$TIMESTAMP" \
                '{id: $id, title: $title, category: $category, content: $content, url: $url, stars: $stars, tags: $tags, source: $source, timestamp: $timestamp}')
            
            echo "$POST_JSON" >> "$NEW_POSTS_FILE"
            POST_COUNT=$((POST_COUNT + 1))
            DIGI_COLLECTED=$((DIGI_COLLECTED + 1))
            echo "   💻 $NAME ($STARS ⭐)"
        fi
    done
fi

echo "   ✅ 数码科技: 收集到 $DIGI_COLLECTED 条"
echo ""

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

echo "✅ 本次共收集到 $POST_COUNT 篇新内容"
echo "   AI热点: $(echo "$NEW_POSTS_ARRAY" | jq '[.[] | select(.category == "AI热点")] | length') 条"
echo "   军事: $(echo "$NEW_POSTS_ARRAY" | jq '[.[] | select(.category == "军事")] | length') 条"
echo "   数码科技: $(echo "$NEW_POSTS_ARRAY" | jq '[.[] | select(.category == "数码科技")] | length') 条"

# 读取现有帖子
if [ -f "$DATA_FILE" ]; then
    EXISTING_POSTS=$(jq '.posts // []' "$DATA_FILE" 2>/dev/null || echo "[]")
    CREATED_TIME=$(jq -r '.created // "'$TIMESTAMP'"' "$DATA_FILE" 2>/dev/null || echo "$TIMESTAMP")
else
    EXISTING_POSTS="[]"
    CREATED_TIME="$TIMESTAMP"
fi

# 去重合并（基于 title），每个分类保留最近 30 条（避免无限增长）
MERGED_POSTS=$(jq -n \
    --argjson existing "$EXISTING_POSTS" \
    --argjson new "$NEW_POSTS_ARRAY" \
    '
    # 按分类分组
    ($existing + $new) as $all_posts
    | $all_posts
    | group_by(.category)
    | map(
        sort_by(-.score | .timestamp)
        | .[0:30]  # 每个分类保留最多30条
      )
    | flatten
    | reverse  # 最新的在前
    ' 2>/dev/null || echo "$EXISTING_POSTS")

# 统计各分类
echo ""
echo "📊 合并后统计:"
for cat in "AI热点" "军事" "数码科技"; do
    CNT=$(echo "$MERGED_POSTS" | jq "[.[] | select(.category == \"$cat\")] | length" 2>/dev/null || echo 0)
    echo "   $cat: $CNT 条"
done

# 保存数据
jq -n \
    --argjson posts "$MERGED_POSTS" \
    --arg created "$CREATED_TIME" \
    --arg lastUpdated "$TIMESTAMP" \
    '{posts: $posts, created: $created, lastUpdated: $lastUpdated}' > "$DATA_FILE"

echo ""
echo "🎉 完成！论坛数据已更新"
echo "📁 数据文件：$DATA_FILE"
