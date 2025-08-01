terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_image" "flask_app" {
  name = "tiangolo/uwsgi-nginx-flask:python3.8"
}

resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name    = "nginx"
  image   = docker_image.nginx.name
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
  name    = "flask-app"
  image   = docker_image.flask_app.name
  volumes {
    host_path      = "${path.module}/app"
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
