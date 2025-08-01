terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "app_network" {
  name     = "app-network"
  driver   = "bridge"
}

resource "docker_container" "flask_app" {
  name  = "flask-app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  restart = "always"
  ports {
    internal = 5000
    external = 8100
  }
  volumes {
    host_path      = "${abspath(path.module)}/scripts/app"
    container_path = "/app"
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_network.app_network]
}

resource "docker_container" "nginx_proxy" {
  name  = "nginx-proxy"
  image = "nginx:latest"
  restart = "always"
  ports {
    internal = 80
    external = 8180
  }
  volumes {
    host_path      = "${abspath(path.module)}/scripts/nginx/default.conf"
    container_path = "/etc/nginx/conf.d/default.conf"
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_network.app_network, docker_container.flask_app]
}

output "flask_app_url" {
  value = "http://localhost:8100"
}

output "nginx_proxy_url" {
  value = "http://localhost:8180"
}
FROM tiangolo/uwsgi-nginx-flask:python3.8

WORKDIR /app

COPY app.py /app/
COPY requirements.txt /app/

RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["uwsgi", "--http", ":5000", "--wsgi-file", "app.py"]
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Flask!"

if __name__ == "__main__":
    app.run(debug=True)
flask
http {
    upstream flask_app {
        server flask_app:5000;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://flask_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
devops-ai-demo/
+-- main.tf
+-- Dockerfile-flask
+-- scripts/
    +-- app/
        +-- app.py
        +-- requirements.txt
    +-- nginx/
        +-- default.conf
        +-- Dockerfile (optional)
