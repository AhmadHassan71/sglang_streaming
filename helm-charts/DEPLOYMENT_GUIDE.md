# SGLang Kubernetes Deployment Guide

This guide provides step-by-step instructions for deploying SGLang on Kubernetes using Helm charts.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Deployment Scenarios](#deployment-scenarios)
4. [Configuration Examples](#configuration-examples)
5. [Testing and Validation](#testing-and-validation)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Kubernetes Cluster Setup

Ensure you have a Kubernetes cluster with:

* Kubernetes version 1.19+
* At least 2 nodes with GPU support
* NVIDIA GPU Operator installed
* Sufficient resources (CPU, Memory, GPU)

### 2. Required Tools

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version

# Install kubectl (if not already installed)
# Follow instructions at https://kubernetes.io/docs/tasks/tools/
```

### 3. GPU Support Setup

```bash
# Install NVIDIA GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace
```

### 4. LeaderWorkerSet (for LWS deployments)

```bash
# Install LeaderWorkerSet CRDs
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.6.0/manifests.yaml

# Verify installation
kubectl get crd leaderworkersets.leaderworkerset.x-k8s.io
```

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/FarazRashid/sglang_streaming.git
cd sglang_streaming
```

### 2. Verify Helm Chart

```bash
# Lint the Helm chart
helm lint ./helm-charts/sglang

# Render templates to verify syntax
helm template test-sglang ./helm-charts/sglang --dry-run
```

### 3. Choose Your Deployment Scenario

Select one of the following deployment modes based on your requirements:

* **Single Node**: For testing or small workloads
* **Distributed**: For large models requiring multiple GPUs across nodes
* **LeaderWorkerSet**: For advanced distributed deployments with better scheduling

## Deployment Scenarios

### Scenario 1: Single Node Development *(Recommended for First-Time Setup)*

Perfect for development and testing with smaller models.

```bash
# Create namespace
kubectl create namespace sglang

# Deploy with simple configuration
helm install sglang ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/simple.yaml
```

**Important:** Before deploying, make sure to manually update the following fields in your `simple.yaml` (or any values YAML file you use):

* `global.model.path`: Provide the correct Hugging Face model path or local model mount path
* `global.image.repository`: Set your container image repo if it's not public or default

**Model Path Guidance:**

* The `--model-path` parameter **must** point to a folder location mounted via a PersistentVolumeClaim (PVC), not just a remote URL.
* For private access to a Google Cloud Storage bucket, use:

  ```
  --model-path="gs://drivehealth-dev-tts-model/Avery_0.2_3_16/"
  ```

  Ensure your service account has appropriate access and the volume is mounted.
* For public access (not recommended for secure setups), use:

  ```
  --model-path="https://storage.googleapis.com/drivehealth-dev-tts-model/Avery_0.2_3_16"
  ```

  But still ensure this is mounted into the pod via PVC before being referenced.

**Key Features:**

* Single pod deployment
* Uses small models (e.g., DialoGPT-medium)
* ClusterIP service for internal access
* Minimal resource requirements

### Scenario 2: Single Node Production

For production workloads on a single powerful GPU node.

```bash
# Deploy with production settings
helm install sglang-prod ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/single-node.yaml \
  --set global.huggingface.token="YOUR_HF_TOKEN"
```

**Important:**
Manually update the following fields in `single-node.yaml`:

* `global.model.path`
* `global.image.repository`

**Model Path Note:** It must be a folder mounted through a PVC (e.g., via GCS Fuse or similar) accessible inside the pod container.

**Key Features:**

* LoadBalancer service for external access
* Health checks and monitoring
* Larger resource allocations
* Production-ready configuration

### Scenario 3: Distributed High-Performance

... *(unchanged content)* ...

## Best Practices

1. **Resource Planning**: Always plan for 2x memory overhead for model loading
2. **Node Affinity**: Use node selectors to ensure pods land on appropriate hardware
3. **Health Checks**: Enable health checks for production deployments
4. **Monitoring**: Set up comprehensive monitoring for GPU, memory, and network
5. **Security**: Use least-privilege principles and avoid privileged mode when possible
6. **Backup**: Regularly backup your model data and configurations
7. **Manual Configuration Reminder**: Always double-check and manually set `global.model.path` and `global.image.repository` fields in your values YAML file.
8. **PVC Mount Required**: The model path must point to a mounted folder using a PersistentVolumeClaim. Remote links (e.g., GCS, HTTP) should be used only as backing sources for mounted volumes, not as direct `--model-path` values.

This guide should help you successfully deploy and manage SGLang on Kubernetes. For additional support, refer to the main README and official documentation.
