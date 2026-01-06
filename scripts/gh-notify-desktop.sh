#!/bin/bash
# Cron-safe wrapper for GitHub desktop notifications
# Extension: https://github.com/benelan/gh-notify-desktop - follow steps there first (ignore gh auth)

# Load GH token from .env in scripts directory
ENV_FILE="$HOME/scripts/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Ensure gh CLI sees a token
# Prefer GH_TOKEN, export to GITHUB_TOKEN for gh
if [ -n "$GH_TOKEN" ]; then
  export GITHUB_TOKEN="$GH_TOKEN"
fi
# Fall back: if GH_TOKEN empty but GITHUB_TOKEN set, set GH_TOKEN
if [ -z "$GH_TOKEN" ] && [ -n "$GITHUB_TOKEN" ]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi

PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
exec gh notify-desktop
