# Configure the Docker provider
required_providers {
  docker = {
    source = "kreuzwerker/docker"
    version = "~> 3.0.2"
  }
}

# Create a Docker network
resource "docker_network" "app_network" {
  name = "app-network"
  driver = "bridge"
}

# Create an Nginx container
resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  restart = "always"
  ports {
    internal  = 80
    external  = 8180
  }
  networks_advanced {
    name    = docker_network.app_network.name
    alias   = "nginx"
  }
}

# Create a Flask app container
resource "docker_container" "flask_app" {
  name  = "flask-app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  restart = "always"
  ports {
    internal = 5000
    external = 8100
  }
  volumes {
    type = "bind"
    source      = "${abspath(path.module)}/app"
    target      = "/app"
  }
  networks_advanced {
    name    = docker_network.app_network.name
    alias   = "flask-app"
  }
}
