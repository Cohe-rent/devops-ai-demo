#!/bin/bash

# Corrected call_openrouter.sh - Uses exported API key and creates Terraform using OpenRouter AI

PROMPT="$1"
OUTPUT_DIR="scripts/infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

# Check if API key is set
if [[ -z "$OPENROUTER_API_KEY" ]]; then
  echo "❌ OPENROUTER_API_KEY environment variable is not set."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "⚙️  Generating Terraform code using OpenRouter..."

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/mixtral-8x7b",
    "messages": [{"role": "user", "content": "'"$PROMPT"'"}],
    "temperature": 0.4
  }')

# Parse and save response
CODE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

if [[ -z "$CODE" || "$CODE" == "null" ]]; then
  echo "❌ Failed to extract code from OpenRouter response"
  exit 1
fi

echo "$CODE" > "$OUTPUT_FILE"
echo "✅ Terraform code saved to $OUTPUT_FILE"

# Git push
echo "📦 Pushing changes to GitHub..."
git add "$OUTPUT_FILE" scripts/call_openrouter.sh
git commit -m "Auto: Update main.tf and script"
git push origin main
