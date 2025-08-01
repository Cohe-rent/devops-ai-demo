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

resource "docker_container" "nginx_container" {
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

resource "docker_container" "flask_container" {
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

  depends_on = [docker_container.nginx_container, docker_network.app_network]
}
