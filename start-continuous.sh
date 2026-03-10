#!/bin/bash

export GITHUB_TOKEN="${GITHUB_TOKEN}"
ITERATION=1

while true; do
  echo "🎯 ITERATION #$ITERATION - $(date)"
  
  timeout 600 openclaw agent --session-id hunt-$ITERATION --message "HUNT #$ITERATION

CRITICAL: HUMAN IDENTITY (read IDENTITY.md)
- Git: Kahfi Elhady <kahfie@gmail.com>
- Commits: casual, lowercase (\"fix typo\", \"oops missed this\")
- PR: conversational (\"hey i fixed this\", \"let me know if changes needed\")
- NO \"copilot\", NO formal tone, NO perfect grammar
- Wait 15-20 min before submitting PR
- Multiple commits (not 1 perfect commit)

WORKFLOW:
1. Algora: curl https://console.algora.io/api/bounties.json
2. GitHub: is:issue is:open label:\"good first issue\" created:>2026-03-01
3. Pick 1 simple issue (typo/import/lint)
4. Clone repo
5. Wait 15 min (simulate human reading)
6. Make fix with human-like commits
7. PR with casual description
8. Token: $GITHUB_TOKEN

Keep it natural, not AI-perfect." 2>&1 | tee logs/hunt-$ITERATION.log | tail -50
  
  timeout 120 openclaw agent --session-id monitor-$ITERATION --message "Check PRs. If maintainer commented, respond casually (human-like). Token: $GITHUB_TOKEN" 2>&1 | tee logs/monitor-$ITERATION.log | tail -30
  
  echo "✅ Done. Next in 20 min..."
  ITERATION=$((ITERATION + 1))
  sleep 1200
done
