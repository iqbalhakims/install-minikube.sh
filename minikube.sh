#!/bin/bash

# Exit script on error
set -e

# Function to add a new user and grant permissions
create_new_user() {
    echo "Creating a new user..."
    read -p "Enter the username for the new user: " new_user
    sudo adduser "$new_user"
    sudo usermod -aG sudo "$new_user"
    echo "New user '$new_user' created and added to sudo group."
}

# Update system and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl apt-transport-https ca-certificates conntrack gnupg software-properties-common unzip

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
echo "Docker installed and started."

# Add user to the Docker group
echo "Adding new user to Docker group..."
create_new_user
sudo groupadd docker || true
sudo usermod -aG docker "$new_user"
echo "Docker group permissions assigned to '$new_user'."

# Switch to the new user to finalize Docker group setup
echo "Switching to the new user to finalize Docker setup..."
sudo -u "$new_user" bash -c "
    sudo usermod -aG docker \$USER && newgrp docker
    echo 'Docker setup completed for the new user.'
"

# Install Minikube
echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "Minikube installed."

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
echo "kubectl installed."

# Install Terraform
echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
echo "Terraform installed."

# Verify installations
echo "Verifying installations..."
echo "Docker version:"
docker --version
echo "Minikube version:"
minikube version
echo "kubectl version:"
kubectl version --client
echo "Terraform version:"
terraform version

# Cleanup Docker system and restart Minikube
echo "Cleaning up Docker resources and restarting Minikube..."
sudo -u "$new_user" bash -c "
    docker system prune -f
    minikube delete
    minikube start --driver=docker
    echo 'Minikube started successfully after cleanup.'
"

echo "Installation and setup of Minikube, kubectl, and Terraform completed successfully!"
echo "Switch to the new user using 'su - $new_user' for further operations."
