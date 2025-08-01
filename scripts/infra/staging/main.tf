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
  network  = docker_network.app_network.name
  ports = [
    "80:8180"
  ]
}

resource "docker_container" "flask_app" {
  name  = "flask-app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  network  = docker_network.app_network.name
  volumes = [
    "./app:/app"
  ]
  ports = [
    "5000:8100"
  ]
}
