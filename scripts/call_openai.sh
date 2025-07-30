#!/bin/bash

PROMPT="$1"
OUTPUT_DIR="infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "❌ Error: OPENAI_API_KEY is not set."
  exit 1
fi

if [ -z "$PROMPT" ]; then
  echo "Usage: $0 \"<your terraform prompt here>\""
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "⚙️  Generating Terraform code for prompt: $PROMPT"

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"gpt-4o\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are a DevOps assistant that generates Terraform code.\"},
      {\"role\": \"user\", \"content\": \"${PROMPT}\"}
    ],
    \"temperature\": 0.2
  }")

# Write response to file, stripping triple backticks if present
echo "$RESPONSE" | jq -r '.choices[0].message.content' | sed '/^```/,/^```/d' > "$OUTPUT_FILE"

echo "✅ Terraform code written to $OUTPUT_FILE"
