# Phase 9: ArgoCD "The Hard Way" & GitOps Implementation

## 🎯 1. My Goals

The primary objective of this phase was to look beyond the convenience of Helm Charts and **understand the direct interactions of Kubernetes resources** by building the system manually.

1. **Deconstruct ArgoCD:** Analyze the **Raw Manifests** (thousands of lines of YAML) to understand the internal components (Server, Repo Server, Dex, Redis, etc.) and their roles without relying on Helm's abstraction.
2. **Network Engineering:** Manually customize **Service (NodePort)** settings for external access in a local virtualization environment (Multipass) and troubleshoot connectivity issues.
3. **True GitOps:** Verify ArgoCD's **Self-Healing** and **Drift Detection** capabilities by forcibly altering the application state after deployment.

---

## 💡 2. Key Learnings & Insights

### A. Precision in Kubernetes Service Mapping (Service Port Logic)

* **The Challenge:** Simply opening a `NodePort` did not guarantee connectivity; I encountered `Connection Refused` errors due to a **Protocol Mismatch**.
* **The Insight:** The `targetPort` in a Service definition is not just a number—it must align exactly with the protocol (HTTP vs. HTTPS) the container is listening on.
* Since ArgoCD enforces HTTPS (443), the NodePort (30090) must be mapped to the `https(443)` section, not the `http(80)` section.
* **Syntax Awareness:** Kubernetes YAML is strictly case-sensitive. `targetport` (lowercase) does not throw a syntax error but fails to function logically. It must be written as **`targetPort` (CamelCase)**.



### B. Architecture Compatibility in Multi-Platform Environments

* **The Challenge:** The deployed Pod failed to start, throwing an `exec format error`.
* **The Insight:** Container images must match the host architecture.
* Running an AMD64-only image (from the old example) on a local **Apple Silicon (ARM64)** environment caused the binary failure.
* Solved by hot-swapping the image to `nginx:alpine` (which supports multi-architecture) directly in the live state, proving the importance of checking image build targets.



### C. The Core of GitOps: "Source of Truth"

* **Verification:** When I manually changed the image via the ArgoCD UI, the application status immediately turned **`OutOfSync` (Yellow)**.
* **The Meaning:** Even if the cluster (Reality) changes, if it differs from Git (The Blueprint), ArgoCD flags it as an "incorrect state." This visually validated the core GitOps principle: **"Git is the single Source of Truth."**

---

## 🛠️ 3. Implementation Workflow

### 3.1 Manual Installation (Helm-less)

Installed using official manifests to bypass the "Black Box" nature of Helm.

```bash
# Create namespace and apply raw manifests
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3.2 Service Exposure (NodePort Patch)

Modified the ClusterIP service to NodePort to enable external access.

```bash
# Edit Service (Assigning port 30090 to the HTTPS section)
kubectl edit svc argocd-server -n argocd
```

### 3.3 GitOps Pipeline Setup

* **App:** `guestbook` (Argo Project Example)
* **Repo:** `https://github.com/argoproj/argocd-example-apps`
* **Policy:** Automated Sync + Prune + Self Heal (Enabled)

---

## 🐛 4. Incident Log (Troubleshooting)

Documentation of the critical connectivity and compatibility issues encountered.

### Issue 1: HTTPS Connection Refused

**Symptom:**
Accessing `curl -k https://192.168.64.3:30090` failed despite the Pod being `Running`.

**Root Cause Analysis:**
`kubectl get svc` revealed that port `30090` was mapped to the internal port `80` (HTTP). However, the client was attempting an HTTPS handshake, causing the traffic to be rejected.

**Resolution (Service Patch):**
Edited the YAML to move `nodePort: 30090` under the `name: https` section.

```yaml
  - name: https      # <--- Moved here
    nodePort: 30090
    port: 443
    protocol: TCP
    targetPort: 8080 # <--- Fixed Typo (targetport -> targetPort)
```

### Issue 2: Exec Format Error (CrashLoopBackOff)

**Symptom:**
The Guestbook Pod failed to start after deployment. Logs showed `exec format error`.

**Root Cause Analysis:**
The outdated example image was built for AMD64 (Intel), making it incompatible with the host's M1 Mac (ARM64) architecture.

**Resolution (Live Manifest Edit):**
Since the Git repository was read-only, I leveraged ArgoCD's "Live Manifest" feature to override the image with `nginx:alpine`. This successfully started the Pod and simultaneously triggered a **Drift (OutOfSync)**, allowing me to verify ArgoCD's change detection mechanism.