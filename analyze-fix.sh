#!/bin/bash
set -e

echo "=== QUICK ANALYZE & FIX ==="

# Clone and fix
WORKDIR="/root/.openclaw/workspace/repos"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

REPO="bfw-systems/bfw"
ISSUE_URL="https://github.com/bfw-systems/bfw/issues/100"

echo "Cloning $REPO..."
git clone --depth 1 "https://github.com/$REPO.git" bfw 2>/dev/null || {
  echo "Clone failed!"
  exit 1
}

cd bfw

echo "Finding typo 'Infos -> Info'..."
grep -rn "Infos" --include="*.py" --include="*.js" --include="*.ts" --include="*.md" . 2>/dev/null | head -20

# Check for tests
echo ""
echo "Test framework detection:"
if [ -f "package.json" ]; then
  echo "  Node.js project"
  grep -E '"test"|"jest"' package.json || echo "  No test found"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  echo "  Python project"
else
  echo "  Unknown project type"
fi

echo ""
echo "Files in repo:"
find . -maxdepth 2 -name "*.py" -o -name "*.js" -o -name "*.md" | head -10
