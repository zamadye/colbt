#!/bin/bash
set -e

echo "=== ANALYSIS AGENT (FAST) ==="

DISCOVERY="/root/.openclaw/workspace/discovery-results.json"
OUTPUT="/root/.openclaw/workspace/analysis-results.json"
WORKDIR="/root/.openclaw/workspace/repos"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo '[]' > /tmp/analysis_raw.json

# Process only first 2 issues for speed
jq -c '.issues[0:2][]' "$DISCOVERY" | while read -r issue; do
  url=$(echo "$issue" | jq -r '.url')
  title=$(echo "$issue" | jq -r '.title')

  echo "Checking: $title"

  # Skip PRs, focus on issues
  if [[ $url == *"/pull/"* ]]; then
    echo "  SKIP: This is a PR"
    continue
  fi

  if [[ $url =~ github\.com/([^/]+)/([^/]+)/ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    repo_dir="$WORKDIR/${owner}_${repo}"

    # Shallow clone (depth 1)
    echo "  Cloning $owner/$repo (shallow)..."
    if git clone --depth 1 "https://github.com/$owner/$repo.git" "$repo_dir" 2>/dev/null; then
      cd "$repo_dir"

      # Quick checks
      has_tests=false
      test_framework="NONE"

      if [ -f "package.json" ]; then
        if grep -qE "\"test\"|jest|vitest|mocha" package.json; then
          has_tests=true
          test_framework="jest"
        fi
      elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "pytest.ini" ]; then
        has_tests=true
        test_framework="pytest"
      elif [ -f "Cargo.toml" ]; then
        has_tests=true
        test_framework="cargo"
      fi

      # Check for docs/README
      files_change=0
      [ -f "README.md" ] && ((files_change++))
      [ -f "README.rst" ] && ((files_change++))

      solvable=false
      if [ "$files_change" -le 3 ] && [ "$files_change" -gt 0 ]; then
        solvable=true
      fi

      echo "  Framework: $test_framework, Files: $files_change, Solvable: $solvable"

      jq --arg url "$url" \
         --arg cloned "true" \
         --arg tests "$has_tests" \
         --arg framework "$test_framework" \
         --arg files "$files_change" \
         --arg solvable "$solvable" \
         '. + [{"url": $url, "repo_cloned": ($cloned == "true"), "has_tests": ($tests == "true"), "test_framework": $framework, "files_to_change": ($files | tonumber), "solvable": ($solvable == "true"), "confidence": 0.7}]' \
         /tmp/analysis_raw.json > /tmp/analysis_tmp.json && mv /tmp/analysis_tmp.json /tmp/analysis_raw.json

      cd "$WORKDIR"
    else
      echo "  Clone FAILED"
    fi
  fi
done

# Final output
jq '{issues: .}' /tmp/analysis_raw.json > "$OUTPUT"

echo ""
echo "Analysis complete!"
jq '.' "$OUTPUT"
