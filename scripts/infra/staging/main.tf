terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  version = "3.0.2"
}

# Create a Docker network
resource "docker_network" "app_network" {
  name    = "app-network"
  check_duplicate = false
}

# Define a Docker container named nginx
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

# Define a Docker container named flask_app
resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  ports {
    internal = 5000
    external = 8100
  }
  volumes {
    host_path      = "${abspath(path.module)}/app"
    container_path = "/app"
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_network.app_network]
}
