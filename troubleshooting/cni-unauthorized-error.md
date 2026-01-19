# 🐛 Incident Report: Calico CNI Authorization Failure

**Date:** 2026-01-19
**Component:** Kubernetes Networking (CNI), Kubelet
**Status:** ✅ Resolved
**Severity:** High (Workloads failed to start)

---

## 1. Issue Description
After re-initializing the Kubernetes Control Plane (`kubeadm init`), newly deployed Pods (e.g., Redis) failed to start. The Pods remained stuck in the `ContainerCreating` state indefinitely.

## 2. Environment
- **OS:** Ubuntu 22.04 LTS (Multipass VMs on macOS)
- **Kubernetes Version:** v1.28+
- **CNI Plugin:** Calico
- **Cluster Topology:** 1 Master, 2 Workers

## 3. Error Logs & Symptoms
Upon inspecting the Pod events using `kubectl describe pod`, the following error messages were observed repeatedly:

```text
Warning  FailedCreatePodSandBox  25m  kubelet  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "...": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized
```

* **Observation:** The error `connection is unauthorized` suggests that the CNI plugin on the worker nodes is trying to communicate with the API Server using invalid credentials.

## 4. Root Cause Analysis (RCA)

The issue stemmed from a **mismatch between the new Control Plane and the old Worker Node configurations**.

1. **Cluster Re-initialization:** The Master node was re-initialized using `kubeadm init`, which generated a new CA certificate and new authentication tokens.
2. **Stale Configuration:** The Worker nodes (VMs) were reused without being fully reset. Specifically, the CNI configuration directory (`/etc/cni/net.d/`) still contained the **old `calico-kubeconfig` file** with the authentication token from the *previous* cluster installation.
3. **Authentication Failure:** When the Calico plugin on the Worker nodes tried to set up networking for new pods, it presented the **expired/invalid token** to the new API Server. The API Server correctly rejected the request as `Unauthorized`.

## 5. Resolution Steps

To resolve the issue, the stale CNI configurations were purged, forcing Calico to regenerate valid credentials.

### Step 1: Purge Stale CNI Configs on Worker Nodes

Executed the following command on all worker nodes to remove the old configuration files.
*Note: Used `bash -c` to ensure wildcard (`*`) expansion happens inside the VM.*

```bash
# On k8s-worker1 & k8s-worker2
sudo bash -c "rm -rf /etc/cni/net.d/*"
```

### Step 2: Restart Calico Pods

Deleted the existing Calico pods to trigger a restart. Upon startup, the Calico node agent detected the missing config and generated a new `calico-kubeconfig` using the current valid service account tokens.

```bash
kubectl delete pods -n calico-system -l k8s-app=calico-node
```

### Step 3: Redeploy Workload

Deleted the stuck application pods to trigger the scheduler to re-create them.

```bash
kubectl delete pod -l app=redis
```

## 6. Verification

After applying the fix, the following checks confirmed the resolution:

1. **Pod Status:** Redis pods transitioned from `ContainerCreating` to `Running`.
2. **Endpoints:** `kubectl get endpoints redis-master` correctly displayed the Pod IP address.

## 7. Lessons Learned

* **Always Reset Nodes:** When re-installing Kubernetes on existing VMs, always run `kubeadm reset` and manually clean up CNI directories (`/etc/cni/net.d/`) to avoid configuration drift.
* **Check Events:** The `kubectl describe pod` events are the first place to look when pods are stuck. `Unauthorized` errors usually point to stale tokens or certificate issues.
