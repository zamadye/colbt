#!/bin/bash
echo "🔧 Setting up OpenClaw environment..."

# Create OpenClaw directories
mkdir -p ~/.openclaw/workspace

# Copy config
cp openclaw-config.json ~/.openclaw/openclaw.json

# Copy skills
cp -r skills ~/.openclaw/workspace/

# Copy identity and agents
cp IDENTITY.md ~/.openclaw/workspace/
cp AGENTS.md ~/.openclaw/workspace/

# Set permissions
chmod -R 755 ~/.openclaw/

echo "✅ OpenClaw environment ready"
ls -la ~/.openclaw/
ls -la ~/.openclaw/workspace/
