#!/bin/bash

export GITHUB_TOKEN="${GITHUB_TOKEN}"
ITERATION=1
STATE_FILE=~/.openclaw/workspace/hunter-state.json

# Initialize state
if [ ! -f "$STATE_FILE" ]; then
  echo '{"visited_repos":[],"attempted_issues":[],"failed_issues":[],"successful_prs":[],"iteration":0}' > "$STATE_FILE"
fi

while true; do
  echo "========================================="
  echo "🎯 LAYERED BOUNTY HUNT #$ITERATION"
  echo "$(date)"
  echo "========================================="
  
  # LAYER 1: DISCOVERY
  echo "📡 LAYER 1: Discovery Agent"
  timeout 300 openclaw agent \
    --session-id discovery-$ITERATION \
    --message "LAYER 1: DISCOVERY AGENT

TASK: Find high-score GitHub issues

RULES:
1. Use GitHub API ONLY
2. Search queries:
   - is:issue is:open label:\"good first issue\" language:python
   - is:issue is:open label:typo
   - is:issue is:open label:documentation
3. Score each issue (min 15 points)
4. NO assumptions
5. If data missing → UNKNOWN

OUTPUT FORMAT (XML):
<discovery_result>
    <issue_url>https://github.com/...</issue_url>
    <score>20</score>
    <labels>good first issue,typo</labels>
    <confidence>0.85</confidence>
</discovery_result>

Find 5-10 high-score issues.
Save to discovery-results.json" \
    2>&1 | tee ~/.openclaw/logs/layer1-$ITERATION.log | tail -50
  
  # LAYER 2: ANALYSIS
  echo "🔍 LAYER 2: Analysis Agent"
  timeout 300 openclaw agent \
    --session-id analysis-$ITERATION \
    --message "LAYER 2: ANALYSIS AGENT

TASK: Verify issues are solvable

INPUT: Read discovery-results.json

FOR EACH high-score issue:
1. Clone repo
2. Check test framework exists
3. Run tests
4. Count files to change
5. Determine if solvable

RULES:
- If > 3 files needed → REJECT
- If no tests → confidence 0.5
- If tests fail to run → REJECT

OUTPUT FORMAT (XML):
<analysis_result>
    <issue_url></issue_url>
    <repo_cloned>true</repo_cloned>
    <has_tests>true</has_tests>
    <test_framework>pytest</test_framework>
    <files_to_change>2</files_to_change>
    <solvable>true</solvable>
    <confidence>0.9</confidence>
</analysis_result>

Save to analysis-results.json
Select TOP 2 solvable issues" \
    2>&1 | tee ~/.openclaw/logs/layer2-$ITERATION.log | tail -50
  
  # LAYER 3: CODING
  echo "💻 LAYER 3: Coding Agent"
  timeout 300 openclaw agent \
    --session-id coding-$ITERATION \
    --message "LAYER 3: CODING AGENT

TASK: Generate minimal patches

INPUT: Read analysis-results.json (solvable issues)

FOR EACH solvable issue:
1. Read relevant files
2. Generate MINIMAL patch
3. Max 50 lines changed
4. Types: typo|import|lint|logic

RULES:
- NO refactoring
- NO architecture changes
- MINIMAL changes only

OUTPUT FORMAT (XML):
<coding_result>
    <issue_url></issue_url>
    <files_changed>file1.py,file2.py</files_changed>
    <patch_type>typo</patch_type>
    <lines_changed>5</lines_changed>
    <confidence>0.95</confidence>
</coding_result>

Save patches and continue" \
    2>&1 | tee ~/.openclaw/logs/layer3-$ITERATION.log | tail -50
  
  # LAYER 4: VERIFICATION
  echo "✅ LAYER 4: Verification Agent"
  timeout 300 openclaw agent \
    --session-id verify-$ITERATION \
    --message "LAYER 4: VERIFICATION AGENT

TASK: Verify patches work

FOR EACH patched repo:
1. Run test suite
2. Check lint
3. Verify build

RULES:
- ALL checks must pass
- If ANY fail → REJECT patch

OUTPUT FORMAT (XML):
<verification_result>
    <issue_url></issue_url>
    <tests_passed>true</tests_passed>
    <lint_passed>true</lint_passed>
    <build_passed>true</build_passed>
    <all_checks>true</all_checks>
    <confidence>1.0</confidence>
</verification_result>

Save to verification-results.json
Only proceed with all_checks=true" \
    2>&1 | tee ~/.openclaw/logs/layer4-$ITERATION.log | tail -50
  
  # LAYER 5: SUBMISSION
  echo "🚀 LAYER 5: Submission Agent"
  timeout 300 openclaw agent \
    --session-id submit-$ITERATION \
    --message "LAYER 5: SUBMISSION AGENT

TASK: Create PRs for verified patches

INPUT: Read verification-results.json (all_checks=true)

FOR EACH verified patch:
1. Fork repo (if not forked)
2. Push branch
3. Create PR with evidence
4. Link to issue

GitHub Token: $GITHUB_TOKEN
Git: kahfie@gmail.com

OUTPUT FORMAT (XML):
<submission_result>
    <issue_url></issue_url>
    <pr_url></pr_url>
    <pr_number>123</pr_number>
    <status>created</status>
    <confidence>1.0</confidence>
</submission_result>

Save to submission-results.json" \
    2>&1 | tee ~/.openclaw/logs/layer5-$ITERATION.log | tail -50
  
  # Update state
  jq ".iteration = $ITERATION" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  
  echo ""
  echo "✅ Iteration $ITERATION complete"
  echo "📊 Check results in ~/.openclaw/workspace/*-results.json"
  echo "💤 Resting 15 minutes..."
  echo ""
  
  ITERATION=$((ITERATION + 1))
  sleep 900
done
