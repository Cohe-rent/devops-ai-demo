# Configure the Docker provider
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Define a Docker bridge network
resource "docker_network" "my_network" {
  name = "my_network"
  driver = "bridge"
}

# Define the frontend container
resource "docker_container" "frontend" {
  name  = "frontend"
  image = "nginx:latest"
  networks_advanced = [
    {
      attachment_type = "bridge"
      name           = docker_network.my_network.name
    }
  ]
  ports = [
    {
      container_port = 80
      host_port      = 80
    }
  ]
}

# Define the backend container
resource "docker_container" "backend" {
  name  = "backend"
  image = "python:3.9-slim-buster"
  command = ["python", "-m", "flask", "run", "--host=0.0.0.0"]
  networks_advanced = [
    {
      attachment_type = "bridge"
      name           = docker_network.my_network.name
    }
  ]
  ports = [
    {
      container_port = 5000
      host_port      = 5000
    }
  ]
}
