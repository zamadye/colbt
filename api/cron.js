const { spawn } = require('child_process');

module.exports = async (req, res) => {
  // Verify cron secret (optional security)
  const authHeader = req.headers.authorization;
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  console.log('🎯 Cron triggered:', new Date().toISOString());

  try {
    const result = await runHunt();
    res.status(200).json({ 
      success: true, 
      timestamp: new Date().toISOString(),
      result 
    });
  } catch (error) {
    console.error('❌ Hunt failed:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
};

function runHunt() {
  return new Promise((resolve, reject) => {
    const agent = spawn('openclaw', [
      'agent',
      '--session-id', `cron-${Date.now()}`,
      '--message', `CRON HUNT

HUMAN IDENTITY:
- Git: Kahfi Elhady <kahfie@gmail.com>
- Casual commits & PR descriptions
- NO AI markers

WORKFLOW:
1. Algora API first
2. GitHub bounties backup
3. Pick 1 issue, fix, PR
4. Monitor existing PRs

Token: ${process.env.GITHUB_TOKEN}`
    ], {
      env: process.env,
      timeout: 600000
    });

    let output = '';
    agent.stdout.on('data', (data) => output += data.toString());
    agent.on('close', (code) => resolve({ code, output: output.substring(0, 500) }));
    agent.on('error', reject);
  });
}
