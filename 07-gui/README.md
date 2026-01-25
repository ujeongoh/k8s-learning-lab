# Phase 7: GUI Dashboard (Portainer)

## 🎯 Learning Objectives
Until now, I have managed the cluster exclusively using the CLI (`kubectl`). While powerful for precision, it lacks immediate visibility into the overall cluster status and makes log inspection cumbersome.
The goal of this phase is to adopt **Portainer** to establish cluster observability and to practice deploying operational tools using **Helm**.

### Key Concepts
* **Portainer:** A lightweight management UI for Kubernetes environments.
* **Helm Upgrade:** The process of modifying configuration and re-deploying an existing release.
* **NodePort & Networking:** Troubleshooting external access in a local VM environment (Multipass).

---

## 🛠️ Implementation

### 1. Helm Repository Setup
Added the official Portainer Helm repository to the local environment.
```bash
helm repo add portainer [https://portainer.github.io/k8s/](https://portainer.github.io/k8s/)
helm repo update
```

### 2. Configuration (`portainer-values.yaml`)

Created a custom values file to override default settings.

* **Service:** Used `NodePort` type for external access.
* **Persistence:** Disabled persistence (`enabled: false`) to prevent the Pod from getting stuck in a `Pending` state, as the local Multipass environment lacks dynamic volume provisioning.

```yaml
service:
  type: NodePort
  httpNodePort: 30007   # Fixed port for HTTP
  httpsNodePort: 30008  # Fixed port for HTTPS

persistence:
  enabled: false # Critical: Prevents waiting for PV creation in Multipass
```

### 3. Deployment & Upgrade

Executed the installation using the custom values file.

```bash
helm upgrade --install portainer portainer/portainer \
  --namespace portainer \
  --create-namespace \
  -f portainer-values.yaml
```

---

## 🔍 Access Guide

In a Bare Metal/VM environment (like Multipass) without a Cloud LoadBalancer, identifying the correct access route is crucial.

### 1. Locate the Pod

Identify which Worker Node is hosting the Pod. (Master nodes may not bridge traffic by default).

```bash
kubectl get pods -n portainer -o wide
# Example Result: k8s-worker1
```

### 2. Identify Worker IP

Get the actual IP address of that Worker Node.

```bash
multipass info k8s-worker1
# Example Result: 192.168.64.3
```

### 3. Verify Service Ports

Check the actual exposed port numbers (HTTPS is recommended).

```bash
kubectl get svc -n portainer
# Example Result: 9443:30008/TCP -> 30008 is the HTTPS port
```

### 4. Browser Access

* **URL:** `https://<Worker-IP>:<Port>` (e.g., `https://192.168.64.3:30008`)
* **Note:** Accept the "Self-signed Certificate Warning" in the browser to proceed.

---

## 🔧 Troubleshooting (Incident Report)

A summary of network issues encountered and resolved during deployment.

### 1. Connection Refused (Master IP Inaccessible)

* **Symptom:** Accessing via Master Node IP (`192.168.64.2`) resulted in `Connection Refused`.
* **Cause:** In a local VM setup, the Master Node does not automatically route NodePort traffic to Worker Nodes. The Pod resides only on the Worker Node.
* **Resolution:** Accessed the dashboard directly via the **Worker Node IP** where the Pod is running.

### 2. SSL Protocol Error

* **Symptom:** `curl` returned `error:1404B42E:SSL routines:ST_CONNECT:tlsv1 alert protocol version`.
* **Cause:** Attempted to use the HTTPS protocol (`https://`) on a non-secure HTTP port (e.g., 30007).
* **Resolution:** Verified port mappings via `kubectl get svc` and switched to the **HTTPS-dedicated port (e.g., 30008)**.

### 3. Security Timeout Redirect

* **Symptom:** Redirected to `/timeout.html` immediately after connection.
* **Cause:** Portainer enforces a security policy that locks the instance if the admin password is not set within **5 minutes** of startup.
* **Resolution:** Restarted the deployment to reset the security timer.
```bash
kubectl rollout restart deployment portainer -n portainer
```