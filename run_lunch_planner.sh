#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
output_file="${1:-$script_dir/lunch_output.txt}"
skill_dir="$script_dir/.codex/skills/lunch-planner"
restaurants_file="$skill_dir/references/restaurants.md"
extractor="$skill_dir/scripts/extract_menu_text.py"
tmp_dir="$script_dir/tmp/lunch-planner"
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36'

if [[ "$output_file" != /* ]]; then
  output_file="$script_dir/$output_file"
fi

mkdir -p "$tmp_dir"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

manifest_file="$tmp_dir/manifest.md"

cat >"$manifest_file" <<EOF
# Lunch Planner Input Manifest

All HTML and extracted text files in this directory tree were fetched and prepared by \`run_lunch_planner.sh\`.
Use these local files as the input source for the lunch summary.
Do not fetch webpages.
Do not run the extraction helper again.

EOF

declare -a fetch_pids=()

while IFS= read -r line; do
  [[ $line == "- "*": "* ]] || continue

  name=${line#- }
  name=${name%%: *}
  url=${line#*: }
  slug=$(slugify "$name")
  html_file="$tmp_dir/$slug.html"
  text_file="$tmp_dir/$slug.txt"

  (
    curl -L -A "$user_agent" "$url" -o "$html_file"
    python3 "$extractor" "$html_file" >"$text_file"
  ) &
  fetch_pids+=("$!")

  cat >>"$manifest_file" <<EOF
## $name
- URL: $url
- HTML: tmp/lunch-planner/$slug.html
- Parsed text: tmp/lunch-planner/$slug.txt

EOF
done <"$restaurants_file"

for pid in "${fetch_pids[@]}"; do
  wait "$pid"
done

prompt=$(cat <<'EOF'
Use $lunch-planner and format the output as markdown.
Use only the local files prepared under `tmp/lunch-planner/`, especially `tmp/lunch-planner/manifest.md`.
Do not fetch webpages.
Do not run the extraction helper script.
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
