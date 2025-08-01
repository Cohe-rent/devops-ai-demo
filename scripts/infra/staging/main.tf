# Configure the Docker provider
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Define the Docker network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Define the Flask image
resource "docker_image" "flask" {
  name         = "flask:latest"
  keep_locally = false
}

# Define the Flask container
resource "docker_container" "flask" {
  name  = "flask"
  image = docker_image.flask.name
  depends_on = [docker_container.nginx]
  ports {
    internal = 5000
    external = 8100
  }
  env = ["FLASK_APP=app.py"]
  volumes = [
    "${path.module}/scripts/app" => "/app"
  ]
}

# Define the NGINX image
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Define the NGINX container
resource "docker_container" "nginx" {
  name  = "nginx"
  image = docker_image.nginx.name
  depends_on = [docker_container.flask]
  ports {
    internal = 80
    external = 8180
  }
  volumes = [
    "${path.module}/scripts/nginx" => "/etc/nginx/conf.d"
  ]
}

# Define the Docker network and attach containers
resource "docker_network_attach" "attach" {
  container = docker_container.flask.name
  network = docker_network.app_network.name
}

resource "docker_network_attach" "attach_nginx" {
  container = docker_container.nginx.name
  network = docker_network.app_network.name
}
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Flask!"

if __name__ == "__main__":
    app.run(debug=True)
Flask==2.0.2
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt.

RUN pip install -r requirements.txt

COPY app.py /app/

CMD ["python", "app.py"]
http {
    upstream flask {
        server localhost:5000;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://flask;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
FROM nginx:latest

COPY default.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
docker build -t flask-app -f scripts/app/Dockerfile scripts/app
docker run -p 8100:5000 flask-app
docker build -t nginx-reverse-proxy -f scripts/nginx/Dockerfile scripts/nginx
docker run -p 8180:80 nginx-reverse-proxy
docker run -d -p 8100:5000 flask-app
docker run -d -p 8180:80 nginx-reverse-proxy
