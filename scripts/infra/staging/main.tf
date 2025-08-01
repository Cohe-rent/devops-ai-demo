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

  volumes {
    host_path      = "${abspath(path.module)}/scripts/app"
    container_path = "/app"
  }

  ports {
    target = 5000
    protocol = "tcp"
    published = "8100"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_network.app_network
  ]
}

resource "docker_container" "nginx_container" {
  name  = "nginx_container"
  image = "nginx:latest"

  ports {
    target = 80
    protocol = "tcp"
    published = "8080"
  }

  volumes {
    host_path      = "${abspath(path.module)}/scripts/nginx.conf"
    container_path = "/etc/nginx/nginx.conf"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [
    docker_network.app_network,
    docker_container.flask_container
  ]

  env = [
    " Servers = flask_container:5000"
  ]
}
