
# Kubernetes Learning Lab: From Bare Metal to GitOps 🚀

This repository documents my journey of building a Kubernetes cluster from scratch to understand its core internal mechanisms. Unlike managed services (EKS, AKS), this lab focuses on **manual provisioning**, **networking principles**, and **GitOps automation** on a local environment.

## 🎯 Project Goals

* **De-mystify Kubernetes Internals:** Move beyond "magic" and understand how components (API Server, Controller Manager, Kubelet) interact.
* **Deep Dive into Networking:** Specific focus on CNI (Calico), DNS (CoreDNS), and Ingress Controllers (Nginx).
* **Infrastructure as Code (IaC):** Automate local infrastructure provisioning.
* **GitOps Implementation:** Build a complete CI/CD pipeline using ArgoCD (Planned).

## 🏗 Architecture

* **Host Environment:** macOS (Apple Silicon M3)
* **Virtualization:** Canonical Multipass (Lightweight VM manager for Ubuntu)
* **Cluster Topology:**
* **Control Plane:** 1 Node (`k8s-master`)
* **Worker Nodes:** 2 Nodes (`k8s-worker1`, `k8s-worker2`)


* **OS:** Ubuntu 22.04 LTS
* **Container Runtime:** Containerd
* **CNI (Network Interface):** **Calico** (Overlay Network)
* **Ingress Controller:** **Nginx Ingress Controller** (Bare-metal NodePort Mode)

## 📂 Repository Structure

```text
.
├── 00-provisioning/         # Scripts to create Multipass VMs
├── 01-cluster-setup/        # Kubeadm bootstrap scripts & configs
├── 02-networking-lab/       # Network experiments (Pod-to-Pod, DNS, Ingress)
│   ├── pod-to-pod/       # CNI & Overlay network verification
│   ├── service-discovery/# CoreDNS & Service IP testing
│   └── ingress/          # Nginx Ingress Controller & Domain routing
├── TIL/            # Daily TIL (Today I Learned) notes
└── README.md

```

## 🗺️ Roadmap & Progress

### Phase 0: Infrastructure Provisioning ✅

> **Goal:** Set up the virtual environment (VMs) required for the cluster.

* [x] Provision 3 Ubuntu nodes using Multipass.
* [x] Configure SSH connectivity and local mounts.

### Phase 1: Cluster Installation (The Hard Way-ish) ✅

> **Goal:** Manually install and configure Kubernetes components.

* [x] Configure OS prerequisites (Swap off, Kernel modules).
* [x] Install Container Runtime (**Containerd**).
* [x] Initialize Control Plane (`kubeadm init`).
* [x] Join Worker Nodes to the cluster.
* [x] Install **Calico CNI** for Pod networking.

### Phase 2: Networking Deep Dive ✅

> **Goal:** Experiment with Kubernetes networking models.

* [x] Verify Pod-to-Pod communication across different nodes (Overlay Network).
* [x] Validate Service Discovery & DNS resolution (`nslookup`).
* [x] Install **Nginx Ingress Controller** (Bare-metal).
* [x] Implement Name-based Virtual Hosting (Routing `devops.local` via Host Header).

### Phase 3: Workload Management 🚧 (Next Step)

> **Goal:** Deploy stateless and stateful applications.

* [ ] Deploy full-stack applications (Frontend + Backend).
* [ ] Manage persistent storage (PV/PVC).
* [ ] Handle configuration (ConfigMap/Secret).

### Phase 4: GitOps & Automation ♾️

> **Goal:** Implement modern DevOps practices.

* [ ] Install **ArgoCD**.
* [ ] Implement "App of Apps" pattern.
* [ ] Automate application updates via Git commits.

---

## 🚀 Getting Started

### 1. Prerequisites

Ensure you have the following installed:

* **Multipass:** `brew install --cask multipass`
* **Kubectl:** `brew install kubectl`
* **Git:** `brew install git`

### 2. Quick Setup (If starting from scratch)

**Step 1: Provision VMs**

```bash
cd 00-provisioning
./setup-vms.sh
```

**Step 2: Bootstrap Cluster**

```bash
cd ../01-cluster-setup
# Run setup scripts (Detailed in 01-cluster-setup/README.md)
```

**Step 3: Run Networking Labs**

```bash
cd ../02-networking-lab/03-ingress
./verify-ingress.sh
```

---

## 📚 Learning Log (TIL)

I document my daily learning and troubleshooting steps in the `learning-log` directory.

* [**Phase 0-2 Summary:** From VM Setup to Ingress](https://www.google.com/search?q=./learning-log/phase0-2-summary.md)

---

## 📝 Troubleshooting

* **DNS Issues:** If `nslookup` fails intermittently on Alpine images, use `busybox:1.28` or check CoreDNS logs.
* **Ingress 404:** Ensure the `Host` header matches the Ingress rule exactly.
* **M1 Mac Issues:** Ensure `multipass` uses the `qemu` driver if encountering stability issues.