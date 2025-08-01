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

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    container_port = 80
    host_port      = 8180
  }
  depends_on = [docker_network.app_network]
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  mounts {
    target = "/app"
    source  = "${path.module}/app"
    type    = "volume"
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    container_port = 5000
    host_port      = 8100
  }
  depends_on = [docker_network.app_network, docker_container.nginx]
}
