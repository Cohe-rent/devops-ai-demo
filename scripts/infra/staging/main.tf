terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  // credentials for your Docker Hub registry if necessary
}

resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  network {
    name = docker_network.app_network.name
  }
  ports {
    internal = 80
    external = 8180
  }
  depends_on = [docker_network.app_network]
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  volumes {
    host_path  = path.module("path/to/app")
    container_path = "/app"
  }
  network {
    name = docker_network.app_network.name
  }
  ports {
    internal = 5000
    external = 8100
  }
  depends_on = [docker_network.app_network, docker_container.nginx]
}
