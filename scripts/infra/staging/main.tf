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

resource "docker_container" "flask_container" {
  name  = "flask_container"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  ports = [
    {
      container_port = 5000
      host_port      = 8100
    }
  ]
  volumes = [
    {
      host_path      = "${abspath(path.module)}/scripts/app"
      container_path = "/app"
    }
  ]
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [
    docker_network.app_network
  ]
}
