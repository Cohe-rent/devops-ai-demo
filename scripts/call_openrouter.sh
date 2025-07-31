#!/bin/bash

PROMPT="$1"
OUTPUT_DIR="infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

# Use the exported variable
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

TF_CODE=$(echo "$CONTENT" | awk '/```hcl/{flag=1; next} /```/{flag=0} flag')

if [[ -z "$TF_CODE" ]]; then
  TF_CODE=$(echo "$CONTENT" | awk '/```/{flag=1; next} /```/{flag=0} flag')
fi

if [[ -n "$TF_CODE" ]]; then
  echo "$TF_CODE" > "$OUTPUT_FILE"
  echo "✅ Terraform code saved to $OUTPUT_FILE"
else
  echo "❌ Failed to extract Terraform code."
  echo "🔍 Raw response:"
  echo "$RESPONSE"
fi
# Git operations
echo "📦 Pushing changes to GitHub..."

# Move to project root (assumes script is in scripts/)
cd "$(git rev-parse --show-toplevel)"

# Add only the relevant files
git add .

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "ℹ️  No changes to commit."
else
  git commit -m "AI"
  git pull origin main
  git push origin main
  echo "✅ Git push successful."
fi
