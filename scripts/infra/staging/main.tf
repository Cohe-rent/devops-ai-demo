terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

# Create a Docker network named app-network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Flask Container
resource "docker_container" "flask" {
  name  = "flask"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  volumes {
    host_path      = "${abspath(path.module)}/scripts/app"
    container_path = "/app"
  }
  ports {
    host_port = "8100"
    container_port = 5000
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_network.app_network]
}

# Nginx Configuration
resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  ports {
    host_port = "80"
    container_port = 80
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_network.app_network, docker_container.flask]
}

# Nginx Configuration File
resource "docker_volume" "nginx_config" {
  name = "nginx_config"
}

resource "docker_container" "nginx_config" {
  name  = "nginx_config"
  image = "nginx:latest"
  volumes {
    container_path = "/etc/nginx/nginx.conf"
    volume_config {
      driver = "local"
      type   = "bind"
      source  = docker_volume.nginx_config.name
      target = "/etc/nginx/nginx.conf"
    }
  }
  depends_on = [docker_volume.nginx_config]
}
