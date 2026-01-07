#!/bin/bash
# Cron-safe wrapper for GitHub desktop notifications
# Extension: https://github.com/benelan/gh-notify-desktop - follow steps there first (ignore gh auth)

# Load GH token from .env in scripts directory
ENV_FILE="$HOME/scripts/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Build list of tokens/hosts to use
# Supports: GH_TOKEN/GITHUB_TOKEN with GH_HOST (default github.com),
# and GH_TOKEN_2..GH_TOKEN_9 with matching GH_HOST_2..GH_HOST_9
TOKENS=()
HOSTS=()
DEFAULT_HOST="${GH_HOST:-github.com}"

# Primary token
if [ -n "$GH_TOKEN" ]; then
  TOKENS+=("$GH_TOKEN"); HOSTS+=("$DEFAULT_HOST")
elif [ -n "$GITHUB_TOKEN" ]; then
  TOKENS+=("$GITHUB_TOKEN"); HOSTS+=("$DEFAULT_HOST")
fi

# Numbered tokens + optional hosts
for n in {2..9}; do
  t_var="GH_TOKEN_${n}"
  h_var="GH_HOST_${n}"
  t_val="${!t_var}"
  [ -n "$t_val" ] || continue
  h_val="${!h_var}"
  [ -n "$h_val" ] || h_val="$DEFAULT_HOST"
  TOKENS+=("$t_val"); HOSTS+=("$h_val")
done

# Deduplicate pairs (token,host)
DEDUP_TOKENS=()
DEDUP_HOSTS=()
for i in "${!TOKENS[@]}"; do
  t="${TOKENS[$i]}"; h="${HOSTS[$i]}"
  skip=
  for j in "${!DEDUP_TOKENS[@]}"; do
    if [ "$t" = "${DEDUP_TOKENS[$j]}" ] && [ "$h" = "${DEDUP_HOSTS[$j]}" ]; then
      skip=1; break
    fi
  done
  if [ -z "$skip" ]; then
    DEDUP_TOKENS+=("$t"); DEDUP_HOSTS+=("$h")
  fi
done
TOKENS=("${DEDUP_TOKENS[@]}")
HOSTS=("${DEDUP_HOSTS[@]}")

PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

# No tokens provided: run once with current env
if [ ${#TOKENS[@]} -eq 0 ]; then
  gh notify-desktop "$@"
  exit $?
fi

# Run sequentially for each token/host, isolating state per pair
rc=0
for i in "${!TOKENS[@]}"; do
  token="${TOKENS[$i]}"; host="${HOSTS[$i]}"
  tok_id=$(printf '%s' "$token|$host" | shasum -a 256 | awk '{print $1}' | cut -c1-12)
  data_dir_base="${XDG_STATE_HOME:-$HOME/.local/state}/gh-notify-desktop"
  data_dir="$data_dir_base/$tok_id"

  if [ -n "$GH_ND_DEBUG" ] || [ -n "$GH_ND_PREFLIGHT" ]; then
    login=$(GH_HOST="$host" GH_TOKEN="$token" gh api user -q .login 2>/dev/null)
    echo "[gh-notify-desktop] preflight host=$host login=${login:-unknown} data_dir=$data_dir"
    if ! GH_HOST="$host" GH_TOKEN="$token" gh api -I /notifications >/dev/null 2>&1; then
      echo "[gh-notify-desktop] preflight FAILED for host=$host login=${login:-unknown}." >&2
      echo "  Ensure PAT is valid and has: notifications (read) + repo (if private)." >&2
      echo "  Also verify host matches the token's server." >&2
      rc=4
      continue
    fi
  fi

  GH_HOST="$host" GH_TOKEN="$token" GITHUB_TOKEN="$token" GH_ND_DATA_DIR="$data_dir" gh notify-desktop || rc=$?
done
exit $rc
