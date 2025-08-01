terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_network" "app-network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  ports {
    internal  = 80
    external  = 8180
  }
  depends_on = [docker_network.app-network.id]
  networks_advanced {
    name = docker_network.app-network.name
  }
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  ports {
    internal = 5000
    external = 8100
  }
  volumes {
    host_path      = "./app"
    container_path = "/app"
  }
  depends_on = [docker_network.app-network.id]
  networks_advanced {
    name = docker_network.app-network.name
  }
}
