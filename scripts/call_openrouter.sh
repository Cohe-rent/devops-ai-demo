#!/bin/bash

PROMPT="$1"
OUTPUT_DIR="infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

API_KEY="$OPENROUTER_API_KEY"
MODEL="meta-llama/llama-3-8b-instruct"

mkdir -p "$OUTPUT_DIR"

echo "⚙️  Generating Terraform code using OpenRouter..."

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL"'",
    "messages": [{"role": "user", "content": "'"$PROMPT"'"}]
  }')

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

# Try to extract inside ``` blocks if they exist
TF_CODE=$(echo "$CONTENT" | awk '/^```/{flag=!flag; next} flag')

# If no fenced code block found, fall back to full content
if [[ -z "$TF_CODE" ]]; then
  TF_CODE="$CONTENT"
fi

# Final fallback if everything failed
if [[ -z "$TF_CODE" ]]; then
  echo "❌ Failed to extract Terraform code."
  echo "🔍 Raw response:"
  echo "$RESPONSE"
  exit 1
fi

# Save to file
echo "$TF_CODE" > "$OUTPUT_FILE"
echo "✅ Terraform code saved to $OUTPUT_FILE"

# Git operations
echo "📦 Pushing changes to GitHub..."

cd "$(git rev-parse --show-toplevel)"

git add .

if git diff --cached --quiet; then
  echo "ℹ️  No changes to commit."
else
  git commit -m "Update: regenerate main.tf via AI"
  git pull origin main --rebase
  git push origin main
  echo "✅ Git push successful."
fi
