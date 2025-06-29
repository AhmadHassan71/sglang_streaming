# SGLang TTS Deployment Guide
It does take a bit of time for the service to be fully operational after deployment, especially when using GPU resources. Please allow sufficient time for the service to initialize and become ready. Just in case Kubernetes marks it to be failed, just change the liveness and readiness probes to a higher value in the Helm chart values file. Once it has been deployed, it will start faster on subsequent restarts. Then we can ammend the values file to lower the liveness and readiness probes.
## Prerequisites

The devops engineering team must ensure that the naming of the service is consistent across the deployment and infrastructure configurations. The service should be named `sglang-service` in all configurations.

### Step 1: GPU Support Configuration

Please ensure that GPU support has been configured in your Kubernetes cluster. This includes having the NVIDIA device plugin installed and ensuring that your nodes have GPUs available.

### Step 2: Namespace Configuration

Create the `dh-avery-tts` namespace and ensure it is properly mapped with the tokenizer service namespace for inter-service communication.

```bash
kubectl create namespace dh-avery-tts
```

**Note**: The DevOps team must ensure proper network policies and service mesh configuration between the `sglang-service` service and the tokenizer service. They must have the same namespace.

### Step 3: PVC Management (DevOps Responsibility)

**The DevOps team is responsible for creating and managing the following PVCs:**

#### Model PVC (Read-Only)

- **PVC Name**: `sglang-model-pvc`
- **Mount Path**: `/model`
- **Access Mode**: Read-Only
- **Content**: Model files from `gs://drivehealth-dev-tts-model/Avery_0.2_3_16/`
- **Storage Class**: As per infrastructure requirements

#### Torch Cache PVC (Read-Write)

- **PVC Name**: `sglang-torch-cache-pvc`
- **Mount Path**: `/torch_cache/inductor_root_cache`
- **Access Mode**: Read-Write
- **Purpose**: Caching torch inductor files for faster service startup
- **Storage Class**: Fast SSD recommended

**Note**: The DevOps team must configure the Google CSI driver for GCS bucket mapping and ensure proper PVC creation with appropriate storage classes and access modes.

## Deployment Process

### Step 4: Build and Push Docker Image

Create a CI/CD pipeline with the following steps:

```bash
# Build the Docker image
docker build --build-arg CUDA_VERSION=12.8.1 --build-arg BUILD_TYPE=all -t sglang:cuda128 -f docker/Dockerfile .

# Push to your container registry
```

### Step 5: Configure Helm Values

Update the `values.yaml` file:

- Set `global.image.repository` to your pushed image repository
- Set `global.image.tag` to your image tag
- Verify PVC names match those created by DevOps team
- Configure node selectors and resource requirements as per infrastructure

### Step 6: Deploy with Helm
Deploy the SGLang TTS service using Helm.

## Testing and Validation

### Step 7: Service Validation

**Note**: Port 30000 should only be exposed for testing purposes. In production, communication should be between the tokenizer service and sglang service only.

Test the deployment:

```bash
curl -X POST http://{server-ip}:30000/generate ^
 -H "Content-Type: application/json" ^
 -d "{\"text\": \"^<^|task_tts^|^>^<^|start_content^|^>The stars whisper softly above a sleeping city.^<^|end_content^|^>^<^|start_global_token^|^>\", \"sampling_params\": {\"temperature\": 0.8, \"top_k\": 40, \"top_p\": 0.9, \"max_new_tokens\": 512}, \"stream\": true}"

 # This is a windows friendly command, for Linux/Mac use their respective ones.
```

Replace `{server-ip}` with the actual IP address of your server.

Expected output:
![output](image.png)

## Scaling and Monitoring

### HPA Configuration

The deployment includes Horizontal Pod Autoscaler (HPA) with:

- **Min Replicas**: 1
- **Max Replicas**: 3
- **CPU Target**: 70%
- **Memory Target**: 80%

### Infrastructure Notes

- Node selection, tolerations, and affinity rules are managed by the infrastructure team
- GPU resource allocation is configured according to DevOps and DriveHealth team requirements
- Service mesh and network policies are maintained by the infrastructure team
- Monitoring and alerting should be configured as per organizational standards

## Troubleshooting

### Common Issues

1. **PVC Mount Issues**: Verify with DevOps team that PVCs are properly created and accessible
2. **GPU Allocation**: Ensure NVIDIA device plugin is running and GPU nodes are available
3. **Network Connectivity**: Verify namespace-to-namespace communication is configured
4. **Resource Limits**: Check if resource requests/limits align with available cluster resources