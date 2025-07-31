#!/bin/bash

# Prompt passed as the first argument
PROMPT="$1"

# Output directory
OUTPUT_DIR="infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

# API Key should be set beforehand as an environment variable
if [[ -z "$OPENROUTER_API_KEY" ]]; then
  echo "❌ OPENROUTER_API_KEY is not set"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "⚙️  Generating Terraform code using OpenRouter..."

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-4o",
    "messages": [{"role": "user", "content": "'"${PROMPT//\"/\\\"}"'"}],
    "temperature": 0.3
  }')

# Extract response content
TERRAFORM_CODE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Check if code was returned
if [[ -z "$TERRAFORM_CODE" || "$TERRAFORM_CODE" == "null" ]]; then
  echo "❌ Failed to generate code from OpenRouter."
  echo "Full response: $RESPONSE"
  exit 1
fi

echo "$TERRAFORM_CODE" > "$OUTPUT_FILE"
echo "✅ Terraform code saved to $OUTPUT_FILE"

# Optional Git commit and push
echo "📦 Committing and pushing to GitHub..."
git add "$OUTPUT_FILE"
git commit -m "🤖 Generated main.tf from AI prompt"
git push

echo "🚀 Pushed to GitHub successfully!"

