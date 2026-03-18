#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output_file="${1:-$script_dir/lunch_output.txt}"

if [[ "$output_file" != /* ]]; then
  output_file="$script_dir/$output_file"
fi

prompt=$(cat <<'EOF'
$lunch-planner
EOF
)

codex exec \
  --cd "$script_dir" \
  --sandbox workspace-write \
  --output-last-message "$output_file" \
  "$prompt"

printf 'Saved lunch summary to %s\n' "$output_file"
