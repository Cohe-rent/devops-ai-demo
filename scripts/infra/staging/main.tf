terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

# Create a Docker network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Create a Docker container for NGINX (Reverse Proxy)
resource "docker_container" "nginx" {
  name  = "flask-nginx"
  image = "flask-nginx"
  networks_advanced {
    name = docker_network.app_network.name
  }
  port_bindings {
    container_port = 80
    host_port = 8180
  }
  depends_on = [docker_network.app_network]
}

# Create a Docker container for Flask App
resource "docker_container" "flask" {
  name  = "flask-backend"
  image = "flask-backend"
  volumes {
    host_path      = "${abspath(path.module)}/app"
    container_path = "/app"
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  port_bindings {
    container_port = 5000
    host_port = 8100
  }
  depends_on = [docker_network.app_network]
}
mkdir -p devops-ai-demo/scripts/app
cat <<EOF > app.py
from flask import Flask
app = Flask(__name__)
@app.route("/")
def hello():
    return "? Hello from Flask!"
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
echo "flask" > requirements.txt
cat <<EOF > Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
EOF
docker build -t flask-backend ./app
mkdir nginx
cd nginx
cat <<EOF > default.conf
server {
    listen 80;
    location / {
        proxy_pass http://host.docker.internal:8100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
cat <<EOF > Dockerfile
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
EOF
docker build -t flask-nginx .
terraform init
terraform apply
