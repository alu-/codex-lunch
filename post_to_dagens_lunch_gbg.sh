#!/usr/bin/env bash

set -euo pipefail

SLACK_API_URL="https://slack.com/api/chat.postMessage"
DEFAULT_CHANNEL="#dagens-lunch-gbg"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

usage() {
  cat <<'EOF'
Usage:
  ./post_to_dagens_lunch_gbg.sh "Lunch message"
  printf 'Lunch message\n' | ./post_to_dagens_lunch_gbg.sh

Environment:
  ENV_FILE          Optional. Path to a .env file to source before reading Slack vars.
  SLACK_BOT_TOKEN   Required. Bot token with chat:write scope.
  SLACK_CHANNEL     Optional. Defaults to #dagens-lunch-gbg.

Notes:
  - Sends an application/json POST to chat.postMessage.
  - Automatically loads .env from this script's directory if present.
  - Uses the top-level text field for the message body.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "${SLACK_BOT_TOKEN:-}" ]]; then
  echo "SLACK_BOT_TOKEN is required." >&2
  exit 1
fi

if [[ $# -gt 0 ]]; then
  message_text=$1
else
  message_text=$(cat)
fi

message_text="${message_text#"${message_text%%[![:space:]]*}"}"
message_text="${message_text%"${message_text##*[![:space:]]}"}"

if [[ -z "$message_text" ]]; then
  echo "Message text is required via the first argument or stdin." >&2
  exit 1
fi

channel="${SLACK_CHANNEL:-$DEFAULT_CHANNEL}"

if command -v jq >/dev/null 2>&1; then
  payload=$(
    jq -n \
      --arg channel "$channel" \
      --arg text "$message_text" \
      '{channel: $channel, text: $text}'
  )
else
  escaped_text=$(printf '%s' "$message_text" | sed 's/\\/\\\\/g; s/"/\\"/g')
  escaped_channel=$(printf '%s' "$channel" | sed 's/\\/\\\\/g; s/"/\\"/g')
  payload=$(printf '{"channel":"%s","text":"%s"}' "$escaped_channel" "$escaped_text")
fi

response=$(
  curl -sS \
    -X POST \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    --data "$payload" \
    "$SLACK_API_URL"
)

if command -v jq >/dev/null 2>&1; then
  if [[ "$(printf '%s' "$response" | jq -r '.ok // false')" != "true" ]]; then
    error_message=$(printf '%s' "$response" | jq -r '.error // "unknown_error"')
    echo "Slack API error: $error_message" >&2
    exit 1
  fi

  printf '%s\n' "$response" | jq -r '"Posted to \(.channel) at ts \(.ts)"'
else
  if [[ "$response" != *'"ok":true'* ]]; then
    echo "Slack API error: $response" >&2
    exit 1
  fi

  printf 'Message posted successfully.\n'
fi
