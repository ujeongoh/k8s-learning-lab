# Phase 4: Persistent Storage

## 🎯 Learning Objectives
Up to Phase 3, the deployed application had a **Stateless** architecture, meaning all internal data was lost whenever a Pod restarted.
The primary goal of Phase 4 is to understand **Stateful** architecture and ensure that database (Redis) data persists independently of the Pod lifecycle.

### Key Concepts
* **Ephemeral vs. Persistent:** Understanding the difference between volatile and permanent data.
* **PV (Persistent Volume):** Physical storage resources in the cluster (Admin context).
* **PVC (Persistent Volume Claim):** A request for storage by a user (Developer context).
* **Volume Mount:** The mechanism connecting the host filesystem to the container filesystem.
* **Node Affinity / Selector:** Why Pods must be pinned to a specific node when using local storage (`hostPath`).

---

## 🏗️ Architecture & Methodology

Given the local VM environment (Multipass), I implemented persistent storage using the **Worker Node's local disk (`hostPath`)** instead of network-based storage (NFS/Cloud).

### 1. Failure Reproduction (Testing Data Loss)
* **Scenario:** Saved data to the Redis Pod without storage configuration and forced a Pod deletion.
* **Result:** Verified that data returned `(nil)` after the Pod regenerated, proving data loss in a stateless setup.

### 2. Physical Storage Provisioning
* **Target Node:** `k8s-worker1`
* **Path:** `/data/redis` (Created directory manually inside the worker node)

### 3. PV & PVC Configuration
* **PV (redis-pv):** Configured with `hostPath` pointing to `/data/redis` on `k8s-worker1`. Used the `Retain` policy to preserve data even if the PV is released.
* **PVC (redis-pvc):** Requested 1Gi storage with `ReadWriteOnce` access mode.

### 4. Workload Update (Deployment)
* **Volume Mount:** Mounted the container's internal `/data` path to the PVC.
* **Node Selector:** Since the physical data resides only on `k8s-worker1`, the Redis Pod was configured to strictly schedule on this node to prevent data fragmentation.

---

## 🧪 Verification Scenario

To ensure data persistence, the following validation steps were performed:

1.  **Write Data:** Executed `redis-cli set mykey "Persistent Data Success!"`
2.  **Disruption:** Triggered a restart using `kubectl delete pod ...`.
3.  **Read Data:** Executed `redis-cli get mykey` in the newly created Pod.
4.  **Result:** Confirmed that the data remained intact despite the Pod replacement.

---

## ⚠️ Limitations & Notes

* **hostPath Constraints:** This approach couples the workload to a specific node (`worker1`). If the node fails, the data becomes inaccessible.
* **Scalability Issues:** High availability (HA) is restricted because the Pod loses mobility (cannot be rescheduled to other nodes).
* **Production Best Practices:** In a real-world production environment, network-based dynamic provisioning (e.g., AWS EBS, Azure Disk, NFS) should be used to decouple storage from compute nodes.