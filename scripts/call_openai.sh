#!/bin/bash

set -e

PROMPT="$1"
OUTFILE="infra/staging/main.tf"

echo "Generating Terraform code for prompt: $PROMPT"

mkdir -p infra/staging

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "'"$PROMPT"'"}],
    "temperature": 0.5
  }')

echo "$RESPONSE" | jq -r '.choices[0].message.content' > "$OUTFILE"

echo "Terraform code written to $OUTFILE"
