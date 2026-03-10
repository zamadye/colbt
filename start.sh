#!/bin/bash

export GITHUB_TOKEN="${GITHUB_TOKEN}"

echo "🎯 OPENCLAW MULTI-AGENT BOUNTY HUNTER"
echo "======================================"
echo ""

# Main Orchestrator spawns sub-agents
timeout 900 openclaw agent --session-id bounty-orchestrator --message "BOUNTY HUNTING ORCHESTRATOR

You are the main orchestrator. Spawn 5 sub-agents sequentially using sessions_spawn tool:

1. DISCOVERY AGENT:
   sessions_spawn with task: 'Use discovery-agent skill. Search GitHub API for issues with labels: good first issue, typo, documentation. Score each issue (min 15 pts). Use curl + jq. Save to discovery-results.json with format: {issues:[{url,score,labels,confidence}]}'
   
2. ANALYSIS AGENT (after discovery completes):
   sessions_spawn with task: 'Use analysis-agent skill. Read discovery-results.json. For each high-score issue: clone repo, check if tests exist (pytest/jest/cargo), run tests, count files to change. If >3 files REJECT. Save to analysis-results.json with format: {issues:[{url,repo_cloned,has_tests,solvable,confidence}]}'

3. CODING AGENT (after analysis completes):
   sessions_spawn with task: 'Use coding-agent skill. Read analysis-results.json (solvable=true). For each: generate MINIMAL patch (max 50 lines). Types: typo|import|lint|logic. NO refactoring. Apply patches and save details to coding-results.json'

4. VERIFICATION AGENT (after coding completes):
   sessions_spawn with task: 'Use verification-agent skill. For each patched repo: run test suite, check lint, verify build. ALL must pass. Save to verification-results.json with format: {issues:[{url,tests_passed,all_checks,confidence}]}'

5. SUBMISSION AGENT (after verification completes):
   sessions_spawn with task: 'Use submission-agent skill. Read verification-results.json (all_checks=true). For each: fork repo, push branch, create PR using GitHub token: $GITHUB_TOKEN. Git config: kahfie@gmail.com. Save to submission-results.json with PR URLs'

Wait for each sub-agent to complete before spawning next.
Report final summary with PR URLs and success rate." 2>&1 | tee logs/orchestrator.log

echo ""
echo "✅ Orchestrator complete!"
echo "📊 Check: *-results.json"
