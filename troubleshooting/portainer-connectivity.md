# 🐛 Incident Report: Portainer Connectivity & SSL Protocol Mismatch

**Date:** 2026-01-25
**Component:** Kubernetes Services, Helm, Portainer
**Status:** ✅ Resolved
**Severity:** Medium (Dashboard Inaccessible)

---

## 1. Issue Description

After deploying Portainer via Helm with a `NodePort` configuration, the dashboard was inaccessible from the host machine. Attempts to connect resulted in `Connection Refused` errors, SSL protocol mismatches, and eventually a security timeout redirection.

## 2. Environment

* **OS:** Ubuntu 22.04 LTS (Multipass VMs on macOS)
* **Kubernetes Version:** v1.28+
* **Installation Method:** Helm Chart (`portainer/portainer`)
* **Network Topology:** 1 Master, 2 Workers (Local VM Network)

## 3. Error Logs & Symptoms

Three distinct error patterns were observed during the troubleshooting process:

**Symptom 1: Connection Refused on Master Node**
Attempting to access via the Master Node IP (`192.168.64.2`) failed:

```text
curl: (7) Failed to connect to 192.168.64.2 port 30007: Connection refused
```

**Symptom 2: SSL Protocol Error**
Attempting to access the HTTP port (`30007`) using the HTTPS protocol:

```text
curl: (35) LibreSSL/3.3.6: error:1404B42E:SSL routines:ST_CONNECT:tlsv1 alert protocol version
```

**Symptom 3: Security Timeout**
Upon successful connection, the browser redirected to an error page:

```text
HTTP/1.1 307 Temporary Redirect
Location: /timeout.html
```

## 4. Root Cause Analysis (RCA)

The issue was caused by a combination of **Network Topology constraints** and **Application Security policies**.

1. **Node Routing Limitation (Bare-metal/VM):**
* Unlike Cloud Providers (AWS/Azure) that use LoadBalancers, this local environment relies on `NodePort`.
* The Portainer Pod was scheduled on `k8s-worker1`.
* The Control Plane (Master) node was not configured to forward traffic to the Worker node for this specific port range, causing `Connection Refused` when hitting the Master IP.


2. **Protocol Mismatch:**
* The Service exposed port `30007` for **HTTP** and `30008` for **HTTPS**.
* The client attempted to send an SSL Handshake (`https://`) to the non-secure HTTP port (`30007`), causing the protocol version alert.


3. **Security Lockout:**
* Portainer enforces a strict security policy: The admin password must be configured within **5 minutes** of container startup.
* Due to the prolonged troubleshooting of network issues, this time window expired, causing the application to lock itself and redirect to `/timeout.html`.



## 5. Resolution Steps

### Step 1: Identify Pod Location & Correct IP

Used `kubectl get pods -o wide` to confirm the Pod was running on `k8s-worker1`. Switched the connection target from the Master IP to the Worker Node IP.

```bash
kubectl get pods -n portainer -o wide
# Output confirmed Pod running on k8s-worker1 (192.168.64.3)
```

### Step 2: Correct Protocol Usage

Identified the correct port mappings via `kubectl get svc`.

* **Action:** Switched to using the **HTTPS** port (`30008`) with the `https://` protocol.

### Step 3: Reset Security Timer

Restarted the deployment to reset the 5-minute configuration window.

```bash
kubectl rollout restart deployment portainer -n portainer
```

## 6. Verification

1. **Connectivity:** Accessed `https://<Worker-IP>:30008` successfully via browser.
2. **Login:** The setup screen appeared immediately, allowing the definition of the `admin` password.
3. **Functionality:** Dashboard successfully displayed Cluster resources (Namespaces, Pods).

## 7. Lessons Learned

* **Node Affinity in Local K8s:** In local VM setups (Multipass/VirtualBox), always target the specific Node IP where the Pod is running, as Master nodes may not bridge traffic by default.
* **Port & Protocol matching:** Always verify `kubectl get svc` to distinguish between HTTP and HTTPS ports to avoid SSL handshake errors.
* **Application-Specific Timeouts:** Be aware that some security tools (like Portainer) have "setup windows" that require a restart if missed.