provider "docker" {}

# Define a single Docker network resource
resource "docker_network" "app_network" {
  name = "app-network"
}

# Create a container for Flask app
resource "docker_container" "flask" {
  name  = "flask-app"
  image = "flask-app"
  port {
    internal = 5000
    external = 8100
  }
  depends_on = [docker_image.flask]
  volumes {
    container_path = "/app"
    host_path      = "${path.module}/scripts/app"
    read_only      = false
  }
}

# Create a container for NGINX
resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx"
  port {
    internal = 80
    external = 8180
  }
  depends_on = [docker_image.nginx]
  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Build the Flask image
resource "docker_image" "flask" {
  name = "flask-app"
  build {
    context = path.module
    dockerfile = "${path.module}/scripts/app/Dockerfile"
  }
}

# Build the NGINX image
resource "docker_image" "nginx" {
  name = "nginx"
  build {
    context = path.module
    dockerfile = "${path.module}/scripts/nginx/Dockerfile"
    build_args = {
      VIRTUAL_HOST = "localhost:8180"
    }
  }
}
from flask import Flask

app = Flask(__name__)

@app.route('/hello', methods=['GET'])
def hello():
    return 'Hello from Flask backend!'

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
flask
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
server {
    listen 80;
    server_name localhost:8180;

    location / {
        proxy_pass http://flask-app:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
FROM nginx:latest

COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /etc/nginx

CMD ["nginx", "-g", "daemon off;"]
