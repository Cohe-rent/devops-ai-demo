# Configure the Docker provider
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create a Docker network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Define the Flask image
resource "docker_image" "flask" {
  name = "myflaskapp"
  build {
    context = path.module("./scripts/app", "")
    dockerfile = "Dockerfile"
  }
}

# Define the NGINX image
resource "docker_image" "nginx" {
  name = "mynginxapp"
  build {
    context = path.module("./scripts/nginx", "")
    dockerfile = "Dockerfile"
  }
}

# Create a Docker container for Flask
resource "docker_container" "flask" {
  name = "flask"
  depends_on = [docker_network.app_network]
  image = docker_image.flask.name
  network_mode = docker_network.app_network.name
  ports {
    internal = 5000
    external = 8100
  }
  volumes {
    container_path = "/app"
    host_path      = path.module("./scripts/app", "")
    read_only      = false
  }
}

# Create a Docker container for NGINX
resource "docker_container" "nginx" {
  name = "nginx"
  depends_on = [docker_network.app_network]
  image = docker_image.nginx.name
  network_mode = docker_network.app_network.name
  ports {
    internal = 80
    external = 8180
  }
  depends_on = [docker_container.flask]
}

# Define the Docker network
resource "docker_network" "app_network" {
  name = "app-network"
}
from flask import Flask

app = Flask(__name__)

@app.route('/hello', methods=['GET'])
def hello():
    return 'Hello from Flask backend!'

if __name__ == '__main__':
    app.run(debug=True, port=5000)
flask
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt.

RUN pip install -r requirements.txt

COPY app.py.

CMD ["python", "app.py"]
http {
    server {
        listen 80;
        location / {
            proxy_pass http://flask:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
FROM nginx:1.21.6-alpine

COPY default.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
