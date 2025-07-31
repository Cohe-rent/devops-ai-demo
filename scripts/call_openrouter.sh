#!/bin/bash

set -e

# Your OpenRouter prompt
PROMPT="$1"
OUTPUT_DIR="scripts/infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "⚙️  Generating Terraform code using OpenRouter..."

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-4o",
    "messages": [{"role": "user", "content": "'"${PROMPT}"'"}],
    "temperature": 0.3
  }')

# Extract the code block from the response
TERRAFORM_CODE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed -n '/```/,/```/p' | sed '/```/d')

# Save to output file
echo "$TERRAFORM_CODE" > "$OUTPUT_FILE"

echo "✅ Terraform code saved to $OUTPUT_FILE"

# Git operations
echo "📦 Pushing changes to GitHub..."

# Move to project root (assumes script is in scripts/)
cd "$(git rev-parse --show-toplevel)"

# Add only the relevant files
git add "$OUTPUT_FILE" "scripts/call_openrouter.sh"

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "ℹ️  No changes to commit."
else
  git commit -m "AI Update: Generated Terraform code and updated script"
  git pull --rebase origin main
  git push origin main
  echo "✅ Git push successful."
fi
