module.exports = async (req, res) => {
  try {
    const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
    
    // Get latest workflow run
    const runsResponse = await fetch('https://api.github.com/repos/zamadye/colbt/actions/runs?per_page=1', {
      headers: {
        'Authorization': `token ${GITHUB_TOKEN}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    
    const runsData = await runsResponse.json();
    const latestRun = runsData.workflow_runs?.[0];
    
    if (!latestRun) {
      return res.status(200).json({ logs: ['No workflow runs found'] });
    }
    
    // Get jobs for the run
    const jobsResponse = await fetch(`https://api.github.com/repos/zamadye/colbt/actions/runs/${latestRun.id}/jobs`, {
      headers: {
        'Authorization': `token ${GITHUB_TOKEN}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    
    const jobsData = await jobsResponse.json();
    const job = jobsData.jobs?.[0];
    
    if (!job) {
      return res.status(200).json({ logs: ['No job data found'] });
    }
    
    // Get logs URL (note: actual log content requires additional API call)
    const logs = [
      `[${new Date(latestRun.created_at).toLocaleTimeString()}] Workflow started: ${latestRun.name}`,
      `[${new Date(latestRun.updated_at).toLocaleTimeString()}] Status: ${latestRun.status}`,
      `[${new Date(latestRun.updated_at).toLocaleTimeString()}] Conclusion: ${latestRun.conclusion || 'running'}`,
      `[${new Date().toLocaleTimeString()}] Monitoring active...`
    ];
    
    res.status(200).json({ 
      logs,
      runId: latestRun.id,
      status: latestRun.status,
      conclusion: latestRun.conclusion
    });
    
  } catch (error) {
    console.error('Logs API error:', error);
    res.status(500).json({ logs: [`Error: ${error.message}`] });
  }
};
