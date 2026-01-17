# Phase 1: Cluster Installation & Bootstrapping 🛠️

This directory contains the scripts required to bootstrap a Kubernetes cluster on top of the provisioned Ubuntu VMs.
Since there are dependencies between the steps, **you must execute the scripts in the following order.**

## 🚀 Execution Order

### Step 1. Setup Prerequisites on All Nodes
Installs the Container Runtime (Containerd) and Kubernetes tools (kubeadm, kubelet, kubectl) on all nodes (Master & Workers).

```bash
# This script internally distributes 'common-setup.sh' to all nodes.
./install-on-all-nodes.sh
```

### Step 2. Initialize Control Plane (Master)

Runs `kubeadm init` on the master node to bootstrap the cluster's control plane.

```bash
./run-master-init.sh
```

### Step 3. Join Worker Nodes

Generates a join token from the master and automatically executes `kubeadm join` on the worker nodes to connect them to the cluster.

```bash
./join-workers.sh
```

### Step 4. Install Network Plugin (CNI)

Deploys the CNI plugin (Calico) to enable Pod-to-Pod communication. Nodes will remain in a `NotReady` state until this step is completed.

```bash
./install-cni.sh
```

### Step 5. Verify Installation

Checks if all nodes have joined successfully and are in the `Ready` state.

```bash
./verify-cluster.sh
```

---

## 📂 File Descriptions

| Filename | Description | Execution Context |
| --- | --- | --- |
| **`common-setup.sh`** | Contains common setup logic such as disabling swap, loading kernel modules, and installing Containerd. (Called by other scripts). | All Nodes |
| **`install-on-all-nodes.sh`** | Orchestration script that distributes and executes `common-setup.sh` on every node via SSH. | Host (Mac) |
| **`run-master-init.sh`** | Executes `kubeadm init` and configures the `kubeconfig` file for the admin user. | Host -> Master |
| **`control-plane-setup.sh`** | Helper script containing variables or specific logic for the control plane setup. | Master |
| **`join-workers.sh`** | Automates the worker joining process by fetching the token from the master and running the join command on workers. | Host (Mac) |
| **`install-cni.sh`** | Applies the CNI manifest (Calico) to the cluster. | Host -> Master |
| **`verify-cluster.sh`** | Runs `kubectl get nodes` to verify the cluster status. | Host (Mac) |
