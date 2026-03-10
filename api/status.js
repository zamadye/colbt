module.exports = async (req, res) => {
  try {
    // Mock data - in real implementation, fetch from GitHub API
    const data = {
      github: {
        status: 'success',
        lastRun: new Date(Date.now() - 600000).toLocaleString(), // 10 min ago
        nextRun: new Date(Date.now() + 600000).toLocaleString()  // 10 min from now
      },
      vercel: {
        status: 'success'
      },
      metrics: {
        totalRuns: 4,
        successRate: 75
      },
      activity: [
        {
          number: 4,
          status: 'success',
          duration: '11s',
          timestamp: new Date(Date.now() - 600000).toLocaleString()
        },
        {
          number: 3,
          status: 'success',
          duration: '46s',
          timestamp: new Date(Date.now() - 1800000).toLocaleString()
        },
        {
          number: 2,
          status: 'success',
          duration: '44s',
          timestamp: new Date(Date.now() - 3600000).toLocaleString()
        },
        {
          number: 1,
          status: 'error',
          duration: '47s',
          timestamp: new Date(Date.now() - 7200000).toLocaleString()
        }
      ]
    };
    
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
