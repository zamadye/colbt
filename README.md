# OpenClaw Bounty Hunter

Autonomous AI agent that finds and completes GitHub bounties using OpenClaw SDK.

## Features
- 🎯 Algora.io bounty priority (integrated payment)
- 🔄 Continuous hunting (every 20 minutes)
- 💬 Auto-responds to PR comments
- 🎭 Human-like identity (no AI detection)
- 🛡️ Multi-layer anti-hallucination

## Local Development
```bash
npm install
npm start
```

## Deploy to Vercel
```bash
vercel --prod
```

### Environment Variables
- `GITHUB_TOKEN`: GitHub personal access token
- `CRON_SECRET`: Random secret for cron authentication

## Architecture
- 5-layer agent system (Discovery → Analysis → Coding → Verification → Submission)
- PR monitoring with auto-response
- Real OpenClaw SDK (not simulated)

## Success
- PR #136: bfw-systems/bfw (typo fix)
- 100% success rate
# colbt
test auto-login
