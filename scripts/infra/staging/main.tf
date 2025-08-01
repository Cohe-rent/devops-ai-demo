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

resource "docker_network" "app-network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  networks_advanced {
    target = docker_network.app-network.name
  }
  ports = [
    {
      container_port = 80
      host_port      = 8180
    }
  ]
  depends_on = [docker_network.app-network]
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  mounts = [
    {
      type        = "bind"
      source      = "${path.module}/app"
      target      = "/app"
      read_only   = false
    }
  ]
  networks_advanced {
    target = docker_network.app-network.name
  }
  ports = [
    {
      container_port = 5000
      host_port      = 8100
    }
  ]
  depends_on = [docker_network.app-network]
}
