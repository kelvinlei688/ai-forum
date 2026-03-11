#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 热点论坛自动发布脚本
每小时收集 AI 界热点新闻并发布到论坛
"""

import json
import urllib.request
import sys
from datetime import datetime
from pathlib import Path

FORUM_DIR = Path("/root/.openclaw/workspace/forum")
DATA_FILE = FORUM_DIR / "data.json"

def fetch_json(url, timeout=10):
    """获取 JSON 数据"""
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return None

def get_hn_ai_posts(limit=10):
    """获取 Hacker News AI 相关帖子"""
    posts = []
    
    # 获取热门帖子 ID 列表
    top_stories = fetch_json("https://hacker-news.firebaseio.com/v0/topstories.json")
    if not top_stories:
        return posts
    
    ai_keywords = ['ai', 'llm', 'gpt', 'claude', 'gemini', 'neural', 'machine learning', 
                   'transformer', 'diffusion', 'model', 'deep learning', 'agentic']
    
    for story_id in top_stories[:50]:  # 检查前 50 个
        item = fetch_json(f"https://hacker-news.firebaseio.com/v0/item/{story_id}.json", timeout=5)
        if not item:
            continue
        
        title = item.get('title', '')
        score = item.get('score', 0)
        url = item.get('url', '')
        
        # 检查是否 AI 相关
        if any(kw.lower() in title.lower() for kw in ai_keywords):
            tags = ['AI']
            if any(kw in title.lower() for kw in ['business', 'funding', 'raises', '$']):
                tags.append('Business')
            elif any(kw in title.lower() for kw in ['tech', 'code', 'github', 'launch']):
                tags.append('Tech')
            
            posts.append({
                'title': title,
                'content': f"Hacker News 热门 AI 帖子，{score} 分支持",
                'url': url,
                'score': score,
                'tags': tags,
                'source': 'Hacker News'
            })
            
            if len(posts) >= limit:
                break
    
    return posts

def load_forum_data():
    """加载论坛数据"""
    if DATA_FILE.exists():
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {'posts': [], 'created': datetime.now().isoformat(), 'lastUpdated': None}

def save_forum_data(data):
    """保存论坛数据"""
    FORUM_DIR.mkdir(parents=True, exist_ok=True)
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def publish_posts(posts):
    """发布新帖子到论坛"""
    data = load_forum_data()
    now = datetime.now().isoformat()
    
    # 检查是否已有相同帖子（避免重复）
    existing_titles = {p.get('title', '') for p in data['posts']}
    
    new_posts = []
    for post in posts:
        if post['title'] not in existing_titles:
            post['timestamp'] = now
            post['id'] = f"post_{len(data['posts']) + len(new_posts) + 1}"
            new_posts.append(post)
            existing_titles.add(post['title'])
    
    if new_posts:
        # 新帖子添加到开头
        data['posts'] = new_posts + data['posts']
        data['lastUpdated'] = now
        save_forum_data(data)
        print(f"✅ 发布了 {len(new_posts)} 篇新帖子")
        for post in new_posts:
            print(f"   - {post['title'][:50]}...")
    else:
        print("ℹ️ 没有新帖子（可能已存在）")
    
    return len(new_posts)

def main():
    print(f"🕐 [{datetime.now().strftime('%Y-%m-%d %H:%M')}] 开始收集 AI 热点...")
    
    # 获取 HN AI 帖子
    hn_posts = get_hn_ai_posts(limit=10)
    print(f"📰 从 Hacker News 获取到 {len(hn_posts)} 篇 AI 相关帖子")
    
    if hn_posts:
        # 发布到论坛
        published = publish_posts(hn_posts)
        print(f"🎉 完成！共发布 {published} 篇新帖子")
    else:
        print("⚠️ 未获取到 AI 相关帖子")
    
    print(f"📁 数据已保存到：{DATA_FILE}")
    print(f"🌐 论坛页面：{FORUM_DIR}/index.html")

if __name__ == '__main__':
    main()
