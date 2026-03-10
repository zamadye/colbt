#!/bin/bash
set -e

echo "=== DISCOVERY AGENT V2 - Targeting Small Repos ==="

GITHUB_TOKEN="${GITHUB_TOKEN}"
OUTPUT="/root/.openclaw/workspace/discovery-results.json"

# Search for typo issues in smaller repos (stars < 100)
echo "Searching for small repos with typos..."

curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/search/issues?q=label:typo+state:open+stars:<100&per_page=10&sort=updated" \
  | jq -r '
    [.items[] | select(.pull_request == null) | {
      url: .html_url,
      title: .title,
      repo: .repository_url,
      score: 15,
      labels: [.labels[].name],
      confidence: 0.8
    }]
  ' > /tmp/typo-small.json

echo '{"issues": []}' > "$OUTPUT"
jq -s '{issues: .[0]}' /tmp/typo-small.json > "$OUTPUT"

echo "Discovery complete!"
echo "Found $(jq '.issues | length' "$OUTPUT") issues from smaller repos"
jq '.issues[] | {url, title}' "$OUTPUT"
