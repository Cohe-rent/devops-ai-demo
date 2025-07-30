# DevOps + AI Demo

This project lets you describe infrastructure in **natural language**, then it automatically generates Terraform code using **OpenAI**, and deploys it via **GitHub Actions**.

---

## 🌐 How it works

1. You input something like:
   > Deploy a staging PostgreSQL database on Azure

2. GitHub Actions will:
   - Send the prompt to OpenAI
   - Generate Terraform code
   - Apply it using `terraform apply`

---

## 📁 Project Structure

