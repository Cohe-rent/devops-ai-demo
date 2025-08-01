terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"

  ports {
    internal = 80
    external = 8180
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_network.app_network]
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"

  volumes {
    host_path      = "${abspath(path.module)}/app"
    container_path = "/app"
  }

  ports {
    internal = 5000
    external = 8100
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_network.app_network]
}
