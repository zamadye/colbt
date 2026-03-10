#!/bin/bash

export GITHUB_TOKEN="${GITHUB_TOKEN}"
ITERATION=1

while true; do
  echo "========================================="
  echo "🎯 BOUNTY HUNT ITERATION #$ITERATION"
  echo "$(date)"
  echo "========================================="
  
  # Run orchestrator
  timeout 900 openclaw agent --session-id bounty-hunt-$ITERATION --message "CONTINUOUS BOUNTY HUNTING - ITERATION #$ITERATION

PRIORITY 1: ALGORA BOUNTIES
1. Search Algora.io API first: https://console.algora.io/api/bounties.json
2. Filter: status=open, reward>0
3. Parse bounty data and GitHub issue URLs

PRIORITY 2: GITHUB BOUNTIES (if Algora has <3 bounties)
4. Search GitHub: is:issue is:open label:bounty OR label:\"good first issue\"

ORCHESTRATION:
Spawn 5 sub-agents using sessions_spawn:

1. DISCOVERY AGENT:
   Task: 'Search Algora API first (curl https://console.algora.io/api/bounties.json). Parse open bounties. Then search GitHub for additional bounties. Score each (min 15 pts). Save to discovery-results.json'

2. ANALYSIS AGENT:
   Task: 'Read discovery-results.json. Clone repos, check tests, verify solvability. Save to analysis-results.json'

3. CODING AGENT:
   Task: 'Read analysis-results.json. Generate minimal patches. Apply fixes. Save to coding-results.json'

4. VERIFICATION AGENT:
   Task: 'Run tests, check lint, verify build. Save to verification-results.json'

5. SUBMISSION AGENT:
   Task: 'Fork, push, create PR. GitHub token: $GITHUB_TOKEN. Git: kahfie@gmail.com. Save to submission-results.json'

PR MONITORING:
6. After submission, check for PR comments every 30 minutes
7. If maintainer comments, spawn RESPONSE AGENT:
   Task: 'Read PR comments, understand feedback, apply requested changes, push updates, reply to comment'
8. Continue monitoring until PR is merged or closed

Report: PRs created, comments handled, bounties completed, earnings estimate" \
    2>&1 | tee logs/iteration-$ITERATION.log | tail -100
  
  # Monitor active PRs
  echo ""
  echo "📬 Monitoring active PRs for comments..."
  timeout 300 openclaw agent --session-id pr-monitor-$ITERATION --message "PR COMMENT MONITOR

Read submission-results.json from previous iterations.
For each open PR:
1. Check for new comments using GitHub API
2. If maintainer commented:
   - Spawn RESPONSE AGENT with sessions_spawn
   - Task: 'Read comment, understand feedback, apply changes, push update, reply'
3. If PR merged:
   - Update status
   - Calculate earnings
4. Save to pr-status.json

GitHub token: $GITHUB_TOKEN" \
    2>&1 | tee logs/pr-monitor-$ITERATION.log | tail -50
  
  echo ""
  echo "✅ Iteration $ITERATION complete"
  echo "💤 Resting 30 minutes before next hunt..."
  echo ""
  
  ITERATION=$((ITERATION + 1))
  sleep 1800
done
