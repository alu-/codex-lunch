#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output_file="${1:-$script_dir/lunch_output.txt}"

if [[ "$output_file" != /* ]]; then
  output_file="$script_dir/$output_file"
fi

prompt=$(cat <<'EOF'
Use $lunch-planner and format the output as markdown.
Decorate the menu items with icons. If Meat/Kött then use a meat icon, fish/fisk then use a fish icon, etc.
If showing a price then use a money icon. Add other icons if suitable, but not to many inline icons.
EOF
)

codex exec \
  --cd "$script_dir" \
  --sandbox workspace-write \
  --output-last-message "$output_file" \
  "$prompt"

printf 'Saved lunch summary to %s\n' "$output_file"
