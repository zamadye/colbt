module.exports = async (req, res) => {
  try {
    const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
    
    // Fetch real GitHub Actions data
    const actionsResponse = await fetch('https://api.github.com/repos/zamadye/colbt/actions/runs', {
      headers: {
        'Authorization': `token ${GITHUB_TOKEN}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    
    const actionsData = await actionsResponse.json();
    const runs = actionsData.workflow_runs || [];
    
    // Calculate metrics
    const totalRuns = runs.length;
    const successfulRuns = runs.filter(run => run.conclusion === 'success').length;
    const successRate = totalRuns > 0 ? Math.round((successfulRuns / totalRuns) * 100) : 0;
    
    // Get latest run
    const latestRun = runs[0];
    const lastRun = latestRun ? new Date(latestRun.updated_at).toLocaleString() : 'Never';
    
    // Calculate next run (every 20 minutes)
    const nextRunTime = latestRun ? 
      new Date(new Date(latestRun.updated_at).getTime() + 20 * 60 * 1000) : 
      new Date(Date.now() + 20 * 60 * 1000);
    const nextRun = nextRunTime > new Date() ? nextRunTime.toLocaleString() : 'Soon';
    
    const data = {
      github: {
        status: latestRun?.conclusion === 'success' ? 'success' : 'error',
        lastRun,
        nextRun
      },
      vercel: {
        status: 'success' // Test Vercel endpoint
      },
      metrics: {
        totalRuns,
        successRate
      },
      activity: runs.slice(0, 5).map((run, index) => ({
        number: runs.length - index,
        status: run.conclusion || 'running',
        duration: calculateDuration(run.created_at, run.updated_at),
        timestamp: new Date(run.updated_at).toLocaleString(),
        url: run.html_url
      }))
    };
    
    res.status(200).json(data);
  } catch (error) {
    console.error('Status API error:', error);
    res.status(500).json({ error: error.message });
  }
};

function calculateDuration(start, end) {
  const startTime = new Date(start);
  const endTime = new Date(end);
  const diffMs = endTime - startTime;
  const diffSec = Math.round(diffMs / 1000);
  return `${diffSec}s`;
}
