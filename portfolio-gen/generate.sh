#!/bin/bash
# Agent Portfolio Generator
# Usage: ./generate.sh <moltbook_api_key> <agent_name>

API_KEY="$1"
AGENT_NAME="$2"

if [ -z "$API_KEY" ] || [ -z "$AGENT_NAME" ]; then
    echo "Usage: ./generate.sh <moltbook_api_key> <agent_name>"
    exit 1
fi

# Fetch agent data
echo "Fetching data for $AGENT_NAME..."
curl -s "https://www.moltbook.com/api/v1/agents/profile?name=$AGENT_NAME" \
  -H "Authorization: Bearer $API_KEY" > /tmp/agent_data.json

# Extract data using Python (more reliable than jq)
python3 << PYTHON
import json
import re

with open('/tmp/agent_data.json') as f:
    data = json.load(f)

agent = data.get('agent', {})
posts = data.get('recentPosts', [])

# Extract fields
name = agent.get('name', 'Unknown')
desc = agent.get('description', 'No description')
karma = agent.get('karma', 0)
post_count = agent.get('stats', {}).get('posts', 0)
comment_count = agent.get('stats', {}).get('comments', 0)

# Build posts HTML
posts_html = ""
for post in posts[:3]:  # Top 3 posts
    title = post.get('title', 'Untitled')
    content = post.get('content', '')[:200] + "..." if len(post.get('content', '')) > 200 else post.get('content', '')
    upvotes = post.get('upvotes', 0)
    posts_html += f'''
    <div class="post">
      <h3>{title}</h3>
      <p>{content}</p>
      <div class="meta">↑ {upvotes} upvotes</div>
    </div>
    '''

if not posts_html:
    posts_html = "<p>No posts yet.</p>"

# Read template
with open('/tmp/portfolio-gen/template.html') as f:
    template = f.read()

# Replace placeholders
template = template.replace('{{AGENT_NAME}}', name)
template = template.replace('{{DESCRIPTION}}', desc)
template = template.replace('{{KARMA}}', str(karma))
template = template.replace('{{POSTS}}', str(post_count))
template = template.replace('{{COMMENTS}}', str(comment_count))
template = template.replace('{{POSTS_SECTION}}', posts_html)

# Write output
output_file = f"/tmp/portfolio-gen/{name}_portfolio.html"
with open(output_file, 'w') as f:
    f.write(template)

print(f"Portfolio generated: {output_file}")
print(f"Karma: {karma}, Posts: {post_count}, Comments: {comment_count}")
PYTHON

