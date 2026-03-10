#!/bin/bash
set -e

echo "=== DISCOVERY AGENT ==="

GITHUB_TOKEN="${GITHUB_TOKEN}"
OUTPUT="/root/.openclaw/workspace/discovery-results.json"

echo '{"issues":[]}' > "$OUTPUT"

# Search for good first issues
echo "Searching for 'good first issue'..."
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/search/issues?q=label:%22good%20first%20issue%22+state:open&per_page=5&sort=updated&order=desc" \
  | jq -r '
    [.items[] | select(.score >= 15) | {
      url: .html_url,
      title: .title,
      score: 20,
      labels: [.labels[].name],
      confidence: 0.8
    }]
  ' > /tmp/good-first.json 2>/dev/null || echo '[]' > /tmp/good-first.json

# Search for typo issues
echo "Searching for 'typo'..."
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/search/issues?q=label:typo+state:open&per_page=5&sort=updated" \
  | jq -r '
    [.items[] | {
      url: .html_url,
      title: .title,
      score: 15,
      labels: [.labels[].name],
      confidence: 0.8
    }]
  ' > /tmp/typo.json 2>/dev/null || echo '[]' > /tmp/typo.json

# Merge
echo "Merging results..."
jq -s '{issues: ((.[0] + .[1]) | unique_by(.url) | sort_by(-.score) | .[0:10])}' \
  /tmp/good-first.json /tmp/typo.json > "$OUTPUT"

echo "Discovery complete!"
echo "Found $(jq '.issues | length' "$OUTPUT") issues"
jq '.' "$OUTPUT"
