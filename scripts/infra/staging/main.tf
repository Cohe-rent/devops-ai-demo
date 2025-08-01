# Configure the Docker provider
provider "docker" {
  source  = "kreuzwerker/docker"
  version = "~> 3.0.2"
}

provider "docker" {}

# Docker network for app communication
resource "docker_network" "app_network" {
  name     = "app-network"
  driver   = "bridge"
  ipam_config {
    range   = "192.168.0.0/16"
    gateway = "192.168.0.1"
  }
}

# Flask container (Backend)
resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  depends_on = [docker_network.app_network]
  volumes = [
    "${path.module}/scripts/app:/app"
  ]
  ports = [
    {
      internal = 5000
      external = 8100
    }
  ]
  networks_advanced {
    name   = docker_network.app_network.name
  }
}

# Nginx container (Frontend)
resource "docker_container" "nginx_proxy" {
  name  = "nginx_proxy"
  image = "nginx:latest"
  depends_on = [docker_container.flask_app, docker_network.app_network]
  volumes = [
    "${path.module}/scripts/nginx:/etc/nginx/conf.d/"
  ]
  ports = [
    {
      internal = 80
      external = 80
    }
  ]
  networks_advanced {
    name   = docker_network.app_network.name
  }
}
