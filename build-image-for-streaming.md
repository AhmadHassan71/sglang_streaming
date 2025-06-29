# Build Image for Streaming with CUDA 12.8.1

Run the following commands to build and run the Docker image for streaming with CUDA 12.8.1:

```bash 
docker build --build-arg CUDA_VERSION=12.8.1 --build-arg BUILD_TYPE=all -t sglang:cuda128 -f docker/Dockerfile .
docker run --gpus all -p 30000:30000 \
  -d \
  --name sglang_container \
  --network sg_network \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -v $(pwd)/Avery_0.2_3_16:/model \
  -v $(pwd)/torch_cache:/root/inductor_root_cache \
  --env "HF_TOKEN=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" \
  --env "PYTORCH_FORCE_FLOAT32=1" \
  --env "TORCHINDUCTOR_CACHE_DIR=/root/inductor_root_cache" \
  lmsysorg/sglang:latest \
  python3 -m sglang.launch_server \
    --model-path /model \
    --tokenizer-path /model \
    --tokenizer-mode auto \
    --attention-backend flashinfer \
    --enable-torch-compile \
    --cuda-graph-max-bs 16 \
    --stream-interval 4 \
    --enable-tokenizer-batch-encode \
    --host 0.0.0.0 \
    --port 30000
```