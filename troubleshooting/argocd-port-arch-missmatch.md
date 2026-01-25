# 🐛 Incident Report: ArgoCD Service Port Mapping & Architecture Mismatch

**Date:** 2026-01-25
**Component:** Kubernetes Services, ArgoCD (Manual Install), Workloads
**Status:** ✅ Resolved
**Severity:** High (Service Inaccessible & Deployment Failure)

---

## 1. Issue Description

**Issue A (Connectivity):** After manually deploying ArgoCD manifests and patching the Service to `NodePort`, the web UI was inaccessible. The connection was refused even when targeting the correct Worker Node IP via HTTPS.

**Issue B (Workload Crash):** After successfully accessing the UI and deploying the `guestbook` sample application, the Pods failed to start, entering a `CrashLoopBackOff` state.

## 2. Environment

* **OS:** Ubuntu 22.04 LTS (Multipass VMs on macOS M-series)
* **Kubernetes Version:** v1.28+
* **Installation Method:** Manual Manifests (`install.yaml`)
* **Target Architecture:** ARM64 (Apple Silicon)

## 3. Error Logs & Symptoms

**Symptom 1: HTTPS Connection Refused**
Attempting to access the ArgoCD Server via the assigned NodePort (`30090`) resulted in a failure to connect. (used port `30090` since portainer is using `30080`)

```text
curl -v -k https://192.168.64.3:30090
* connect to 192.168.64.3 port 30090 failed: Connection refused
```

**Symptom 2: Incorrect Service Mapping**
Inspecting the Service configuration revealed the NodePort was attached to the wrong internal port.

```text
# kubectl get svc -n argocd
PORT(S): 80:30090/TCP, 443:30443/TCP
```

*(NodePort 30090 was mapped to container port 80, but client requested HTTPS/443)*

**Symptom 3: Pod Exec Format Error**
The deployed `guestbook` application logs showed a binary compatibility error.

```text
exec /usr/local/bin/docker-php-entrypoint: exec format error
```

## 4. Root Cause Analysis (RCA)

This incident stemmed from two distinct configuration and compatibility errors.

1. **Service Port Misconfiguration:**
* **Protocol Mismatch:** ArgoCD enforces HTTPS communication. However, the `NodePort: 30090` was manually configured under the `http` (port 80) section of the Service manifest.
* **Traffic Drop:** When the client sent an SSL Client Hello (`https://`) to port 30090, the traffic was routed to the container's HTTP port (80), which rejected the encrypted traffic or failed to establish the handshake correctly.
* **Syntax Error:** During the remediation attempt, a YAML case-sensitivity error (`targetport` vs `targetPort`) prevented the configuration from being applied correctly.


2. **Architecture Incompatibility (ARM vs AMD):**
* The user is running Kubernetes on an **Apple Silicon (M1/M2/M3)** host, which requires **ARM64** container images.
* The official ArgoCD `guestbook` example uses an older image built only for **AMD64 (Intel/x86)** architecture.
* Kubernetes attempted to run the x86 binary on an ARM processor, resulting in the `exec format error`.



## 5. Resolution Steps

### Step 1: Remap Service Port (Fixing Connectivity)

Modified the `argocd-server` Service to correctly map the external `NodePort` to the internal HTTPS port.

* **Action:** Edited the Service manifest (`kubectl edit svc`).
* **Change:** Moved `nodePort: 30090` from the `http` block to the `https` block.
* **Correction:** Fixed the typo `targetport` to `targetPort`.

```yaml
# Corrected Configuration
  - name: https
    nodePort: 30090  # Moved to HTTPS section
    port: 443
    protocol: TCP
    targetPort: 8080 # Case-sensitive correction
```

### Step 2: Hot-Swap Container Image (Fixing Workload)

Since the source code in the Git repository could not be modified (Read-Only), the "Live Manifest" feature in ArgoCD was used to override the image.

* **Action:** Edited the Deployment manifest within the ArgoCD UI.
* **Change:** Replaced the incompatible `gcr.io/.../guestbook:v1` image with `nginx:alpine`.
* **Rationale:** `nginx:alpine` supports multi-architecture (including ARM64) and is lightweight for verification.

## 6. Verification

1. **Connectivity:** Validated access via `curl -v -k https://192.168.64.3:30090`. The TLS handshake was successful.
2. **Login:** Successfully logged into the ArgoCD Web UI using the initial admin password.
3. **Workload Status:** The Guestbook application transitioned from `CrashLoopBackOff` (Red) to `Running` (Green) after the image swap.
4. **Drift Detection:** Confirmed that ArgoCD correctly identified the application status as `OutOfSync` due to the manual image change, verifying GitOps functionality.

## 7. Lessons Learned

* **Port Mapping Precision:** When using `NodePort`, explicitly verifying which internal port (HTTP vs HTTPS) receives the traffic is crucial.
* **YAML Sensitivity:** Kubernetes manifests are strictly case-sensitive. A simple typo like `targetport` (lowercase) is valid syntax but invalid logic, leading to silent failures.
* **Architecture Awareness:** When working on local VMs (especially Mac), always verify if the target container images support `linux/arm64`. Standard tutorials often default to `linux/amd64`.