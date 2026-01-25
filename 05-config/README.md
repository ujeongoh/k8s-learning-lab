# Phase 5: Configuration Management

## 🎯 Learning Objectives
In previous phases, application settings (such as ports and arguments) were hardcoded into the deployment YAML files. This approach makes it difficult to manage different settings across environments (Dev, Stage, Prod).
The goal of Phase 5 is to **decouple configuration from the application code**, enabling the same container image to behave differently based on the injected configuration.

### Key Concepts
* **ConfigMap:** A mechanism to store non-confidential data (e.g., config files, command-line arguments).
* **Secret:** A mechanism to store sensitive data (e.g., passwords, API keys, certificates).
* **Injection Methods:** Learning how to inject these configs into Pods via **Environment Variables** and **Volume Mounts**.
* **12-Factor App:** Adhering to the principle of "Store config in the environment."

---

## 🏗️ Architecture & Methodology

I refactored the Redis deployment to remove hardcoded values and utilize external configuration objects.

### 1. Configuration Objects
* **ConfigMap (`redis-config`):**
    * Stores the `redis.conf` file content.
    * Configured memory limits (`maxmemory 256mb`) and eviction policies.
* **Secret (`redis-secret`):**
    * Stores the Redis password securely.
    * Kubernetes handles the Base64 encoding/decoding automatically when mounting or injecting.

### 2. Deployment Refactoring (`redis-master-final.yaml`)
* **Command Override:** Modified the container entrypoint to execute `redis-server /redis-master/redis.conf` instead of the default command.
* **Volume Mount (File Injection):**
    * Mounted the `redis-config` ConfigMap to the `/redis-master` directory inside the container.
    * This makes the `redis.conf` file available as a physical file.
* **Environment Variable (Env Injection):**
    * Injected the `redis-password` from the Secret into the container as the `REDIS_PASSWORD` environment variable.

---

## 🧪 Verification Scenario

To verify that the configurations were successfully injected without modifying the container image:

1.  **Check ConfigMap Injection:**
    * Command: `kubectl exec ... -- cat /redis-master/redis.conf`
    * Result: Confirmed that the custom configuration (e.g., `maxmemory 256mb`) exists inside the Pod.
2.  **Check Secret Injection:**
    * Command: `kubectl exec ... -- env | grep REDIS_PASSWORD`
    * Result: Verified that the `REDIS_PASSWORD` variable contains the correct value (`SuperSecretPassword123!`).

---

## 📝 Best Practices & Future Improvements

* **Environment Segregation:**
    * Currently, we are manually applying files. In a real-world scenario, tools like **Kustomize** or **Helm** should be used to manage different ConfigMaps/Secrets for Dev, Staging, and Production environments (e.g., different memory limits or passwords).
* **Secret Management:**
    * Kubernetes Secrets are stored as Base64 encoded strings, not encrypted, in etcd. For higher security, integration with external secret managers (e.g., **HashiCorp Vault**, **AWS Secrets Manager**) is recommended.
* **Hot Reloading:**
    * Standard Pods do not automatically restart when a ConfigMap changes. A "Reloader" controller or a rolling restart is required to apply configuration updates.