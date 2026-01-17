#!/bin/bash

# ==============================================================================
# Kubernetes Common Setup Script (Master & Workers)
# This script installs Containerd and configures OS prerequisites for Kubernetes.
# ==============================================================================

# 1. Disable Swap (Kubernetes requires swap to be disabled)
echo "[Task 1] Disabling Swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Load Kernel Modules
# overlay: Required for containerd overlayfs storage driver
# br_netfilter: Required for iptables to see bridged traffic
echo "[Task 2] Loading Kernel Modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Configure Sysctl Parameters
# net.bridge.bridge-nf-call-iptables: Ensures packets traversing the bridge are processed by iptables for filtering
# net.ipv4.ip_forward: Enables IP forwarding
echo "[Task 3] Configuring Sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 4. Install Containerd Runtime
echo "[Task 4] Installing Containerd..."
# Add Docker's official GPG key and repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

# 5. Configure Containerd with systemd cgroup driver
# Kubernetes recommends 'systemd' cgroup driver over 'cgroupfs'
echo "[Task 5] Configuring Containerd cgroup driver..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
# Replace 'SystemdCgroup = false' with 'SystemdCgroup = true'
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart Containerd to apply changes
sudo systemctl restart containerd
sudo systemctl enable containerd

# 6. Install Kubernetes Components (Kubelet, Kubeadm, Kubectl)
echo "[Task 6] Installing Kubernetes Components (kubeadm, kubelet, kubectl)..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Using Kubernetes v1.30 (Stable for Ubuntu 24.04)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "✅ Common setup completed successfully!"