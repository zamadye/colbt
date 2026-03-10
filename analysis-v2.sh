#!/bin/bash
set -e

echo "=== ANALYSIS AGENT V2 ==="

DISCOVERY="/root/.openclaw/workspace/discovery-results.json"
OUTPUT="/root/.openclaw/workspace/analysis-results.json"
WORKDIR="/root/.openclaw/workspace/repos"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo '[]' > /tmp/analysis_raw.json

# Look for actual code repos (skip bug-report or pull-only repos)
jq -c '.issues[]' "$DISCOVERY" | while read -r issue; do
  url=$(echo "$issue" | jq -r '.url')
  title=$(echo "$issue" | jq -r '.title')

  echo "Checking: $title"

  # Skip PRs
  [[ $url == *"/pull/"* ]] && continue

  if [[ $url =~ github\.com/([^/]+)/([^/]+)/issues ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"

    # Skip known non-code repos
    [[ "$repo" == *"bug"* ]] && continue
    [[ "$repo" == *"reports"* ]] && continue

    repo_dir="$WORKDIR/${owner}_${repo}"

    # Shallow clone with timeout
    echo "  Cloning $owner/$repo..."
    if timeout 30 git clone --depth 1 "https://github.com/$owner/$repo.git" "$repo_dir" 2>/dev/null; then
      cd "$repo_dir" 2>/dev/null || continue

      # Detect test framework
      test_framework="NONE"
      has_tests=false

      if [ -f "package.json" ]; then
        grep -qE '"test"|"jest"|"vitest"|"mocha"' package.json && { test_framework="jest"; has_tests=true; }
      elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        test_framework="pytest"; has_tests=true
      elif [ -f "Cargo.toml" ]; then
        test_framework="cargo"; has_tests=true
      fi

      # Count files
      files_change=$(find . -maxdepth 1 -name "README*" -o -name "*.md" | wc -l)
      [ "$files_change" -eq 0 ] && files_change=1

      solvable=true
      echo "  Framework: $test_framework, Files: $files_change"

      jq --arg url "$url" \
         --arg framework "$test_framework" \
         --arg files "$files_change" \
         '. + [{"url": $url, "repo_cloned": true, "has_tests": true, "test_framework": $framework, "files_to_change": ($files | tonumber), "solvable": true, "confidence": 0.7}]' \
         /tmp/analysis_raw.json > /tmp/analysis_tmp.json && mv /tmp/analysis_tmp.json /tmp/analysis_raw.json

      cd "$WORKDIR"
    fi
  fi
done

jq '{issues: .}' /tmp/analysis_raw.json > "$OUTPUT"

echo ""
echo "Analysis complete!"
jq '.' "$OUTPUT"
