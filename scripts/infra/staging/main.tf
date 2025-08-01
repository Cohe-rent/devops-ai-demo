provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "app_network" {
  name = "app-network"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  ports {
    internal = 80
    external = 8180
  }
  networks_advanced {
    name        = docker_network.app_network.name
    aliases     = []
  }
}

resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"
  ports {
    internal = 5000
    external = 8100
  }
  volumes = [
    "${abspath(path.module)}/app:/app"
  ]
  networks_advanced {
    name        = docker_network.app_network.name
    aliases     = []
  }
}
