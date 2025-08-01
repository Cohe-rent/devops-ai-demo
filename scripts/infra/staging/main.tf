terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  // Add credentials if not using Docker CLI
  // credentials_file = "/path/to/credentials.json"
}

# Create a Docker network named app-network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Create a Docker container named nginx
resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"
  networks_advanced {
    name    = docker_network.app_network.name
    aliases = ["nginx"]
  }
  ports {
    internal = 80
    external = 8180
  }
  depends_on = [docker_network.app_network]
}

# Create a Docker container named flask_app
resource "docker_container" "flask_app" {
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
    name    = docker_network.app_network.name
    aliases = ["flask_app"]
  }
  depends_on = [docker_network.app_network, docker_container.nginx]
}
