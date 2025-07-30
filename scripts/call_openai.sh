#!/bin/bash

# Load the prompt from file
prompt=$(cat prompt.txt)

echo "Generating Terraform code for prompt:"
echo "$prompt"

# Call OpenAI API
response=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are a Terraform and Azure expert.\"},
      {\"role\": \"user\", \"content\": \"$prompt\"}
    ]
  }" | jq -r '.choices[0].message.content')

# Check for null or empty response
if [[ "$response" == "null" || -z "$response" ]]; then
  echo "❌ No response or null returned from OpenAI API."
  exit 1
fi

# Save Terraform code
mkdir -p ../infra/staging
echo "$response" > ../infra/staging/main.tf

echo "✅ Terraform code written to infra/staging/main.tf"
