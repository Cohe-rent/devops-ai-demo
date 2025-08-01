mkdir -p devops-ai-demo/scripts/app

cat <<EOF > app.py
from flask import Flask
app = Flask(__name__)
@app.route("/")
def hello():
    return "Hello from Flask!"
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
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_container" "nginx_container" {
  name  = "nginx-proxy"
  image = "flask-nginx"
  network {
    attachments {
      network_id = docker_network.app_network.id
    }
  }
  ports {
    internal  = 80
    external = 8180
  }
  depends_on = [docker_network.app_network]
}

resource "docker_container" "flask_container" {
  name  = "flask-server"
  image = "flask-backend"
  network {
    id = docker_network.app_network.id
  }
  volumes {
    host_path = "${abspath(path.module)}/app"
    container_path = "/app"
  }
  ports {
    internal = 5000
    external = 8100
  }
  depends_on = [docker_network.app_network]
}
