#!/usr/bin/env bash
# One headless builder turn for the Hoard Rally trial.
#   drive.sh new "<prompt>"          start a fresh session (prints its id)
#   drive.sh <session-id> "<reply>"  resume that session with the owner's reply
# Transcripts land in sessions/ next to this script; the builder never sees them.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
game=~/hobbys/dragonhoard_test
plugin=~/hobbys/dragonhoard_trial_plugin
mkdir -p "$here/sessions"
if [ "$1" = new ]; then id=$(python3 -c 'import uuid; print(uuid.uuid4())'); session=(--session-id "$id")
else id=$1; session=(--resume "$id"); fi
out="$here/sessions/$(date -u +%Y%m%dT%H%M%SZ)-${id:0:8}.json"
cd "$game"
claude -p "$2" "${session[@]}" --plugin-dir "$plugin" --output-format json \
  --permission-mode acceptEdits \
  --allowedTools Bash Read Write Edit Glob Grep Agent Skill WebFetch WebSearch TodoWrite \
  --disallowedTools "Bash(git commit:*)" "Bash(git push:*)" "Bash(git reset:*)" "Bash(git checkout:*)" \
  </dev/null > "$out"
python3 - "$out" "$id" <<'EOF'
import json, sys
data = json.load(open(sys.argv[1]))
print(f"session {sys.argv[2]} | turns {data.get('num_turns')} | {data.get('duration_ms', 0) // 1000}s | error {data.get('is_error')}")
print(data.get("result", ""))
EOF
