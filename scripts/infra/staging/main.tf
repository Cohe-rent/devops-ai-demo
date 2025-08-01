terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
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
  network = docker_network.app_network.name
  ports = ["8180:80"]
}

resource "docker_container" "flask" {
  name  = "flask"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  network = docker_network.app_network.name
  volumes = [
    "./app:/app"
  ]
  ports = ["8100:5000"]
}
terraform init
terraform apply
