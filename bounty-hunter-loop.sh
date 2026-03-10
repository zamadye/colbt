#!/bin/bash

export GITHUB_TOKEN="${GITHUB_TOKEN}"
ITERATION=1

while true; do
  echo "========================================="
  echo "🎯 BOUNTY HUNT ITERATION #$ITERATION"
  echo "$(date)"
  echo "========================================="
  
  timeout 600 openclaw agent \
    --session-id bounty-hunt-$ITERATION \
    --message "CONTINUOUS BOUNTY HUNTING - ITERATION #$ITERATION

MISSION: Find and complete GitHub bounties to earn money.

WORKFLOW:
1. Search for NEW bounties on:
   - GitHub issues with 'bounty' label
   - Algora.io
   - Gitcoin
   - HackerOne (if applicable)
   
2. Filter bounties:
   - Open and unclaimed
   - Coding tasks (bug fixes, features, refactoring)
   - Reward: \$20+ or equivalent
   - Within skill level
   
3. For EACH bounty found:
   - Clone repo (if not already cloned)
   - Analyze requirements
   - Implement solution
   - Test thoroughly
   - Commit with proper message
   - Fork repo (if needed)
   - Push to fork
   - Create PR with GitHub token
   
4. Track progress in bounty-report.md

5. Report:
   - Bounties found: [count]
   - PRs created: [count]
   - Estimated earnings: \$[amount]
   - Next targets: [list]

USE GITHUB TOKEN: $GITHUB_TOKEN
Git config: kahfie@gmail.com

CONTINUE hunting until you find and complete at least 1 new bounty per iteration!" \
    2>&1 | tee -a ~/.openclaw/logs/bounty-hunt-$ITERATION.log | tail -100
  
  echo ""
  echo "✅ Iteration $ITERATION complete"
  echo "💤 Resting 5 minutes before next hunt..."
  echo ""
  
  ITERATION=$((ITERATION + 1))
  sleep 300
done
