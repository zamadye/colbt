const { spawn } = require('child_process');

module.exports = async (req, res) => {
  // Verify cron secret
  const authHeader = req.headers.authorization;
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  console.log('🎯 Cron triggered:', new Date().toISOString());

  // Respond immediately (Vercel has 10s timeout)
  res.status(200).json({ 
    success: true, 
    message: 'Bounty hunt started',
    timestamp: new Date().toISOString(),
    note: 'Agent running in background'
  });

  // Run single hunt iteration
  try {
    const result = await runHunt();
    console.log('✅ Hunt completed:', result);
  } catch (error) {
    console.error('❌ Hunt failed:', error.message);
  }
};

function runHunt() {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      agent.kill();
      reject(new Error('Timeout after 8 seconds'));
    }, 8000);

    const agent = spawn('openclaw', [
      'agent',
      '--session-id', `cron-${Date.now()}`,
      '--message', `BOUNTY HUNT

HUMAN IDENTITY:
- Git: Kahfi Elhady <kahfie@gmail.com>
- Casual commits & PR
- NO AI markers

WORKFLOW:
1. Algora API: curl https://console.algora.io/api/bounties.json
2. GitHub backup: is:issue is:open label:"good first issue"
3. Pick 1 simple issue (typo/import/lint)
4. Clone, fix, test, PR
5. Monitor existing PRs for comments

Token: ${process.env.GITHUB_TOKEN}

Keep it quick and simple.`
    ], {
      env: process.env,
      detached: true,
      stdio: 'ignore'
    });

    agent.unref();
    
    agent.on('spawn', () => {
      clearTimeout(timeout);
      resolve({ status: 'started', pid: agent.pid });
    });

    agent.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}
