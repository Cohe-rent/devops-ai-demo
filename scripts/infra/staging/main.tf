terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

# Create a Docker network named app-network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Define a Docker container named nginx
resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"

  # Connect to the app-network
  networks_advanced {
    name = docker_network.app_network.name
  }

  # Map container port 80 to host port 8180
  ports {
    internal = 80
    external = 8180
  }

  depends_on = [docker_network.app_network]
}

# Define a Docker container named flask_app
resource "docker_container" "flask_app" {
  name  = "flask_app"
  image = "tiangolo/uwsgi-nginx-flask:python3.8"

  # Mount host folder into container
  volumes {
    host_path      = abspath(path.module) + "/app"
    container_path = "/app"
  }

  # Map port 5000 to host port 8100
  ports {
    internal = 5000
    external = 8100
  }

  # Attach to the app-network
  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_network.app_network, docker_container.nginx]
}
resources {
  # Create a Docker image for the flask_app
  resource "docker_image" "flask_app" {
    name = "flask_backend"
    build {
      context  = "${path.module}/app"
      dockerfile = "Dockerfile"
    }
  }

  # Create a Docker image for the nginx_app
  resource "docker_image" "nginx_app" {
    name = "flask_nginx"
    build {
      context  = "${path.module}/nginx"
      dockerfile = "Dockerfile"
    }
  }

  # Create Dockers for the apps
  resource "docker_container" "app" {
    name  = "flask_app"
    image = docker_image.flask_app.latest
    ports {
      internal = 5000
      external = 8100
    }
  }

  resource "docker_container" "nginx" {
    name  = "nginx_app"
    image = docker_image.nginx_app.latest
    ports {
      internal = 80
      external = 8180
    }
  }
}
