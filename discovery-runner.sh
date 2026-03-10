#!/bin/bash
set -e

echo "=== DISCOVERY AGENT ==="
echo "Searching GitHub API for issues with labels: good first issue, typo, documentation"

# Search for issues with specific labels
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Search queries
QUERIES=(
  'label:"good first issue"+state:open'
  'label:typo+state:open'
  'label:documentation+state:open'
)

echo '{"issues":[]}' > /root/.openclaw/workspace/discovery-results.json

for query in "${QUERIES[@]}"; do
  echo "Querying: $query"
  
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/search/issues?q=$query&per_page=10&sort=updated&order=desc")
  
  # Extract issues using jq
  echo "$response" | jq -r '
    [.items[] | {
      url: .html_url,
      api_url: .url,
      title: .title,
      score: (
        (if (.labels[]? | .name == "good first issue") then 20 else 0 end) +
        (if (.labels[]? | .name == "typo") then 15 else 0 end) +
        (if (.labels[]? | .name == "documentation") then 10 else 0 end) +
        (if .comments == 0 then 5 else 0 end)
      ),
      labels: [.labels[].name],
      confidence: 0.8
    }] | select(.[].score >= 15)
  ' >> /tmp/discovery_part.json
  
  sleep 2
done

# Merge results
echo "Merging results..."
jq -s '{issues: (map(.issues) | add | unique_by(.url) | sort_by(.score) | reverse)}' \
  /tmp/discovery_part.json > /root/.openclaw/workspace/discovery-results.json

echo "Discovery complete!"
cat /root/.openclaw/workspace/discovery-results.json | jq '.issues | length'
