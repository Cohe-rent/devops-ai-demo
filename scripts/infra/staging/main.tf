terraform {
  required_version = ">= 1.1.0"
  required_providers {
    docker = {
      source  = "cloudnativedocker/PADOR"
      version = "2.17.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  registryेहतर = "registry.hub.docker.com"
}

resource "docker_network" "example" {
  name = "example"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:1.21.1"
  port {
    target     = 80
    published   = 8080
    protocol    = "tcp"
  }
  network {
    name = docker_network.example.name
  }
  depends_on = [docker_container.flask]
  command = ["nginx", "-default.conf"]
}

resource "docker_container" "flask" {
  name  = "flask"
  image = "flask:2.0.2"
  port {
    target     = 5000
    published   = 5000
    protocol    = "tcp"
  }
  network {
    name = docker_network.example.name
  }
  env = ["FLASK_APP=app.py"]
  command = ["flask", "run", "--host=0.0.0.0", "--port=5000"]
}

resource "docker_network_service" "example" {
  name = "example"
  network {
    name = docker_network.example.name
  }
  depends_on = [docker_container.nginx, docker_container.flask]
  config {
    restart = "always"
  }
  port {
    target     = 5000
    published   = 5000
    protocol    = "tcp"
  }
  port {
    target     = 80
    published   = 8080
    protocol    = "tcp"
  }
}

resource "docker_container" "reverseproxy" {
  name  = "reverseproxy"
  image = "nginx:1.21.1"
  port {
    target     = 80
    published   = 8080
    protocol    = "tcp"
  }
  network {
    name = docker_network.example.name
  }
  command = ["nginx", "-conf_suppressed"]
  default_conf = <<CONF
http {
  server {
    listen 8080;
    location / {
      proxy_pass http://flask:5000;
      proxy_set_header  Host             $host;
      proxy_set_header  X-Real-IP       $remote_addr;
    }
  }
}
CONF
  depends_on = [docker_container.flask]
}
