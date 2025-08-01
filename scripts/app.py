# Use an official Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy the current directory contents into the container
COPY . .

# Install Flask
RUN pip install flask

# Expose the port
EXPOSE 5000

# Command to run the app
CMD ["python", "app.py"]
