
# Kubernetes Learning Lab: From Bare Metal to GitOps 🚀

This repository documents my journey of building a Kubernetes cluster from scratch to understand its core internal mechanisms. Unlike managed services (EKS, AKS), this lab focuses on manual provisioning, networking principles, and GitOps automation on a local environment.

## 🎯 Project Goals

- **De-mystify Kubernetes Internals:** Move beyond "magic" and understand how components (API Server, Controller Manager, Kubelet, CNI) interact.
- **Deep Dive into Networking:** specific focus on Pod-to-Pod communication, Service discovery, and Ingress controllers.
- **Infrastructure as Code (IaC):** Automate local infrastructure provisioning.
- **GitOps Implementation:** Build a complete CI/CD pipeline using ArgoCD.

## 🏗 Architecture

- **Host Environment:** macOS (Apple Silicon M1/M2/M3)
- **Virtualization:** Canonical Multipass (Lightweight VM manager for Ubuntu)
- **Cluster Topology:**
  - **Control Plane:** 1 Node (`k8s-master`)
  - **Worker Nodes:** 2 Nodes (`k8s-worker1`, `k8s-worker2`)
- **OS:** Ubuntu 22.04 LTS
- **Container Runtime:** Containerd
- **CNI:** Calico / Flannel (TBD)

## 🛠 Prerequisites

Before running any scripts, ensure you have the following tools installed on your local machine.

### 1. Install Multipass
This project uses **Multipass** to spawn Ubuntu VMs on macOS (Apple Silicon). It is a lightweight alternative to VirtualBox.

```bash
# Install via Homebrew
brew install --cask multipass

# Verify installation
multipass --version
```

### 2. Install Git

```bash
brew install git
```

### 3. (Optional) Local Kubectl

It is recommended to have `kubectl` installed on your host machine to interact with the cluster later.

```bash
brew install kubectl
```

---

## 🗺️ Roadmap & Phases

### Phase 0: Infrastructure Provisioning 🚧

> **Goal:** Set up the virtual environment (VMs) required for the cluster.

* [ ] Provision 3 Ubuntu nodes using Multipass script.
* [ ] Verify SSH connectivity between nodes.

### Phase 1: Cluster Installation (The Hard Way-ish)

> **Goal:** Manually install and configure Kubernetes components to understand the bootstrap process.

* [ ] Configure OS prerequisites (Swap off, Kernel modules).
* [ ] Install Container Runtime (**Containerd**).
* [ ] Initialize Control Plane (`kubeadm init`).
* [ ] Join Worker Nodes to the cluster.
* [ ] Install CNI Plugin (Network Interface).

### Phase 2: Networking Deep Dive 🔍

> **Goal:** Experiment with Kubernetes networking models.

* [ ] Test Pod-to-Pod communication across different nodes.
* [ ] Analyze `ClusterIP` and `NodePort` mechanisms (iptables/IPVS).
* [ ] Deploy and configure an **Ingress Controller** (Nginx).

### Phase 3: Workload Management

> **Goal:** Deploy stateless and stateful applications.

* [ ] Deploy basic web applications (Deployment).
* [ ] Manage persistent storage and databases (StatefulSet, PV/PVC).

### Phase 4: GitOps & Automation ♾️

> **Goal:** Implement modern DevOps practices.

* [ ] Install **ArgoCD**.
* [ ] Implement "App of Apps" pattern.
* [ ] Automate application updates via Git commits.

---

## 🚀 Getting Started

1. **Clone the repository**
```bash
git clone [https://github.com/YOUR_USERNAME/k8s-learning-lab.git](https://github.com/YOUR_USERNAME/k8s-learning-lab.git)
cd k8s-learning-lab
```


2. **Provision Infrastructure (Phase 0)**
```bash
chmod +x 00-provisioning/setup-vms.sh
./00-provisioning/setup-vms.sh
```


3. **Install Kubernetes (Phase 1)**
```bash
chmod +x 01-cluster-installation/install-on-all-nodes.sh
./01-cluster-installation/install-on-all-nodes.sh
# Follow the specific instructions in 01-cluster-installation/README.md for kubeadm init
```



## 📝 Lab Notes & Troubleshooting

Check the `troubleshooting/` directory for detailed logs of issues encountered and their resolutions.


