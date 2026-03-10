const { spawn } = require('child_process');

module.exports = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  console.log('🎯 Daily cron triggered:', new Date().toISOString());
  console.log('⏱️  Will run for 24 hours with 20-min intervals');

  // Run for 24 hours (72 iterations x 20 min)
  const maxIterations = 72;
  let iteration = 1;
  const results = [];

  const runLoop = async () => {
    while (iteration <= maxIterations) {
      console.log(`\n🔄 Iteration ${iteration}/${maxIterations}`);
      
      try {
        const result = await runHunt(iteration);
        results.push({ iteration, success: true, timestamp: new Date().toISOString() });
      } catch (error) {
        console.error(`❌ Iteration ${iteration} failed:`, error.message);
        results.push({ iteration, success: false, error: error.message });
      }

      iteration++;
      
      // Wait 20 minutes before next iteration (unless last one)
      if (iteration <= maxIterations) {
        await new Promise(resolve => setTimeout(resolve, 20 * 60 * 1000));
      }
    }
  };

  // Start loop in background
  runLoop().catch(console.error);

  // Respond immediately
  res.status(200).json({ 
    success: true, 
    message: '24-hour bounty hunt started',
    iterations: maxIterations,
    interval: '20 minutes',
    started: new Date().toISOString()
  });
};

function runHunt(iteration) {
  return new Promise((resolve, reject) => {
    const agent = spawn('openclaw', [
      'agent',
      '--session-id', `cron-${Date.now()}-${iteration}`,
      '--message', `HUNT ITERATION ${iteration}

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
