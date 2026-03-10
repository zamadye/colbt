#!/bin/bash
set -e

echo "=== ANALYSIS AGENT ==="

DISCOVERY="/root/.openclaw/workspace/discovery-results.json"
OUTPUT="/root/.openclaw/workspace/analysis-results.json"
WORKDIR="/root/.openclaw/workspace/repos"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Analyzing $(jq '.issues | length' "$DISCOVERY") issues..."

jq -s '{issues: []}' > "$OUTPUT"

# Read issues from discovery
jq -c '.issues[]' "$DISCOVERY" | while read -r issue; do
  url=$(echo "$issue" | jq -r '.url')

  echo "Checking: $url"

  # Extract repo info from URL
  if [[ $url =~ github\.com/([^/]+)/([^/]+)/ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    repo_dir="$WORKDIR/${owner}_${repo}"

    echo "  Owner: $owner, Repo: $repo"

    # Clone if not exists
    if [ ! -d "$repo_dir" ]; then
      echo "  Cloning..."
      git clone "https://github.com/$owner/$repo.git" "$repo_dir" 2>/dev/null || {
        echo "  Clone FAILED"
        echo '{"url":"'"$url"'","repo_cloned":false,"has_tests":false,"solvable":false,"confidence":0.0}' >> /tmp/analysis_issues.jsonl
        continue
      }
    fi

    cd "$repo_dir"

    # Check for test frameworks
    has_pytest=false
    has_jest=false
    has_cargo=false

    [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] && ls test*.py 2>/dev/null | grep -q . && has_pytest=true
    [ -f "package.json" ] && grep -q "jest\|vitest\|mocha" package.json && has_jest=true
    [ -f "Cargo.toml" ] && has_cargo=true

    # Count potential files to change (look for obvious typo/doc locations)
    files_change=0
    [ -f "README.md" ] && ((files_change++))
    [ -d "docs" ] && ((files_change += $(find docs -name "*.md" 2>/dev/null | wc -l)))

    # Determine solvability
    solvable=false
    if [ "$files_change" -le 3 ]; then
      solvable=true
    fi

    echo "  Tests: pytest=$has_pytest, jest=$has_jest, cargo=$has_cargo"
    echo "  Files to change: $files_change"
    echo "  Solvable: $solvable"

    # Output result
    cat >> /tmp/analysis_issues.jsonl << EOF
{"url":"$url","repo_cloned":true,"has_tests":$has_pytest,"test_framework":"$(if $has_pytest; then echo "pytest"; elif $has_jest; then echo "jest"; elif $has_cargo; then echo "cargo"; else echo "NONE"; fi)","files_to_change":$files_change,"solvable":$solvable,"confidence":0.7}
EOF

    cd "$WORKDIR"
  fi
done

# Combine results
if [ -f /tmp/analysis_issues.jsonl ]; then
  jq -s '{issues: .}' /tmp/analysis_issues.jsonl > "$OUTPUT"
else
  echo '{"issues":[]}' > "$OUTPUT"
fi

echo "Analysis complete!"
jq '.' "$OUTPUT"
