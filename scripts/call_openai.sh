#!/bin/bash

# Input: natural language instruction
PROMPT="$1"

# Output Terraform path
OUTPUT_FILE="infra/staging/main.tf"

# Call OpenAI (replace YOUR_API_KEY with your OpenAI key)
curl https://api.openai.com/v1/chat/completions \
  -s \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "'"$PROMPT"'"}],
    "temperature": 0.7
  }' | jq -r '.choices[0].message.content' > "$OUTPUT_FILE"

echo "✅ Terraform code generated at $OUTPUT_FILE"
