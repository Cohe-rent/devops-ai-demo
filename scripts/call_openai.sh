#!/bin/bash

PROMPT="$1"
OUTPUT_DIR="infra/staging"
OUTPUT_FILE="$OUTPUT_DIR/main.tf"

mkdir -p "$OUTPUT_DIR"

echo "Generating Terraform code for prompt: $PROMPT"

RESPONSE=$(curl https://api.openai.com/v1/chat/completions \
  -s \
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

echo "$RESPONSE" | jq -r '.choices[0].message.content' > "$OUTPUT_FILE"

echo "Terraform code written to $OUTPUT_FILE"
