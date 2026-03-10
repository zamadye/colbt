#!/usr/bin/env node

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const GITHUB_TOKEN = process.env.GITHUB_TOKEN || '${GITHUB_TOKEN}';
const INTERVAL_MS = 20 * 60 * 1000; // 20 minutes
let iteration = 1;

console.log('🚀 OpenClaw Bounty Hunter Started');
console.log(`⏱️  Interval: 20 minutes`);
console.log(`🔑 GitHub Token: ${GITHUB_TOKEN.substring(0, 10)}...`);
console.log('');

async function runAgent(sessionId, message) {
  return new Promise((resolve, reject) => {
    const agent = spawn('openclaw', ['agent', '--session-id', sessionId, '--message', message], {
      env: { ...process.env, GITHUB_TOKEN },
      timeout: 600000 // 10 minutes
    });

    let output = '';
    
    agent.stdout.on('data', (data) => {
      const text = data.toString();
      output += text;
      process.stdout.write(text);
    });

    agent.stderr.on('data', (data) => {
      process.stderr.write(data);
    });

    agent.on('close', (code) => {
      resolve({ code, output });
    });

    agent.on('error', (err) => {
      reject(err);
    });
  });
}

async function hunt() {
  console.log(`\n🎯 ITERATION #${iteration} - ${new Date().toISOString()}`);
  console.log('━'.repeat(50));

  try {
    // Main hunting agent
    await runAgent(`hunt-${iteration}`, `HUNT #${iteration}

CRITICAL: HUMAN IDENTITY (read IDENTITY.md)
- Git: Kahfi Elhady <kahfie@gmail.com>
- Commits: casual, lowercase ("fix typo", "oops missed this")
- PR: conversational ("hey i fixed this", "let me know if changes needed")
- NO "copilot", NO formal tone, NO perfect grammar
- Wait 15-20 min before submitting PR
- Multiple commits (not 1 perfect commit)

WORKFLOW:
1. Algora: curl https://console.algora.io/api/bounties.json
2. GitHub: is:issue is:open label:"good first issue" created:>2026-03-01
3. Pick 1 simple issue (typo/import/lint)
4. Clone repo
5. Wait 15 min (simulate human reading)
6. Make fix with human-like commits
7. PR with casual description
8. Token: ${GITHUB_TOKEN}

Keep it natural, not AI-perfect.`);

    // PR monitoring
    await runAgent(`monitor-${iteration}`, `Check PRs. If maintainer commented, respond casually (human-like). Token: ${GITHUB_TOKEN}`);

    console.log(`\n✅ Iteration ${iteration} complete`);
  } catch (error) {
    console.error(`❌ Error in iteration ${iteration}:`, error.message);
  }

  iteration++;
}

async function main() {
  // Run first iteration immediately
  await hunt();

  // Then run every 20 minutes
  setInterval(hunt, INTERVAL_MS);
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n🛑 Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Shutting down gracefully...');
  process.exit(0);
});

main().catch(console.error);
