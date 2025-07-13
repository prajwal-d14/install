#!/bin/bash

set -e  # Exit if any command fails

# Step 1: Update apt and install transport
echo "Updating apt and installing transport..."
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Step 2: Add Kubernetes GPG key and apt repo
echo "Setting up Kubernetes APT repo..."
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    sudo gpg --dearmor -o /usr/share/keyrings/kubernetes.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Step 3: Install Docker
echo "Installing Docker..."
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Step 4: Configure Docker cgroup driver
echo "Configuring Docker to use systemd as cgroup driver..."
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# Step 5: Install Kubernetes components
echo "Installing kubelet, kubeadm, kubectl..."
sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni
sudo apt-mark hold kubelet kubeadm kubectl

echo "✅ Kubernetes setup completed successfully!"
