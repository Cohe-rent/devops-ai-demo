# Configure the local backend
backend "local" {
  path = "/Users/<your_username>/tf-local-dev/env.tfstate"
}

# Create a directory for the frontend server
resource "local_file" "frontend_dir" {
  content = <<EOF
mkdir frontend
cd frontend &&
echo "This is the frontend directory" > index.html
EOF
  directory_path = "/Users/<your_username>/tf-local-dev/frontend"
}

# Create a directory for the backend server
resource "local_file" "backend_dir" {
  content = <<EOF
mkdir backend
cd backend &&
python -m venv venv &&
echo "This is the backend directory" > app.py
EOF
  directory_path = "/Users/<your_username>/tf-local-dev/backend"
}

# Install nginx
resource "null_resource" "install_nginx" {
  provisioner "local-exec" {
    command = "sudo apt-get update && sudo apt-get install -y nginx"
  }
}

# Configure nginx
resource "local_file" "nginx_config" {
  content = <<EOF
server {
    listen 8080;
    server_name localhost;

    location / {
        root /Users/<your_username>/tf-local-dev/frontend;
        index index.html;
    }
}
EOF
  directory_path = "/etc/nginx/sites-available"
  filename = "default.conf"
}

# Configure Flask backend server
resource "null_resource" "install_flask" {
  provisioner "local-exec" {
    command = "python -m venv venv && venv/bin/pip install flask"
  }
}

# Start the Flask backend server
resource "null_resource" "start_flask" {
  provisioner "local-exec" {
    command = "venv/bin/python app.py"
  }
}
