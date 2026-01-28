#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

git config --local core.hooksPath ".githooks"
chmod +x "$repo_root/.githooks/pre-commit"

echo "Installed git hooks in .githooks"
