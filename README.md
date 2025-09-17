# VoxCPM on RunPod

This repository provides the minimal container scaffolding required to launch the upstream [OpenBMB/VoxCPM](https://github.com/OpenBMB/VoxCPM) project on RunPod. The resulting image is intentionally bare: every dependency is installed on first container boot so the base image stays small and simple.

## Image layout

* **Base image:** `nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04` keeps GPU support without pre-installing Python tooling.
* **Bootstrap script:** `/usr/local/bin/bootstrap.sh` runs whenever the container starts. On first launch it:
  1. Installs system dependencies with `apt` (Python 3.12, git, ffmpeg, etc.).
  2. Clones or updates the upstream VoxCPM repository into `/workspace/VoxCPM`.
  3. Creates a virtual environment in `/workspace/.venv` and installs VoxCPM with all Python dependencies. `PIP_EXTRA_INDEX_URL` defaults to the CUDA 12.4 PyTorch wheel index and `PIP_PREFER_BINARY=1` nudges pip towards pre-built wheels to avoid noisy source builds.
  4. Writes `/workspace/.env` which can be customised before starting workloads.
* **Runtime launcher:** `/usr/local/bin/run_voxcpm_demo.sh` imports the upstream Gradio app and launches it with `share=True` by default so the public Gradio link is created even if RunPod's proxy is unreliable.
* **GPU driver guardrails:** Bootstrap ensures a `libcuda.so` symlink exists when the NVIDIA runtime mounts the host driver, avoiding Triton/torch compile failures that expect that SONAME.

A marker file (`/workspace/.voxcpm_bootstrapped`) prevents repeat installations. Delete it if you want to re-run the full setup.

After bootstrapping, the script sources the virtual environment and:

* Runs any command supplied to the container using the prepared environment.
* Otherwise defaults to `run_voxcpm_demo.sh`, which launches the upstream Gradio interface with `share=True` so the Gradio tunnel link is returned reliably.

## Running on RunPod

1. Deploy the image built from this repository (`gemneye/voxcpm-runpod:latest`).
2. On first start, wait for the bootstrap log messages to finish (installs can take several minutes depending on network speed).
3. Connect to the pod (SSH or RunPod web shell) and run workloads from `/workspace/VoxCPM`:
   ```bash
   source /workspace/.venv/bin/activate
   python app.py   # launches the upstream Gradio demo
   ```

### Customising installation

Environment variables control bootstrap behaviour:

* `REPO_URL` – override the upstream Git URL.
* `REPO_DIR` – change where VoxCPM is cloned.
* `PIP_EXTRA_INDEX_URL` – point to a different PyTorch wheel index if needed.
* `HF_HOME`, `TORCH_HOME`, `OMP_NUM_THREADS` – edit `/workspace/.env` after the first start to tweak caching and runtime settings.
* `PIP_PREFER_BINARY` – opt out of preferring wheels if you need to force source installs.
* `DEFAULT_CMD` – change the default command executed when the container starts with no arguments (defaults to `run_voxcpm_demo.sh`).
* `GRADIO_SHARE` – set to `false` if you prefer to disable Gradio's public tunnel.
* `GRADIO_SERVER_NAME` / `GRADIO_SERVER_PORT` / `GRADIO_MAX_QUEUE` / `GRADIO_SHOW_ERROR` – tune how Gradio serves the demo.
* `CUDA_LIB_DIR` – override the directory where the bootstrapper ensures `libcuda.so` points to `libcuda.so.1` (defaults to `/usr/lib/x86_64-linux-gnu`).

Provide a command to the container to start services automatically:

```bash
docker run --rm -it gemneye/voxcpm-runpod:latest \
  bash -lc "source /workspace/.venv/bin/activate && run_voxcpm_demo.sh"
```

## Local build and publish

```bash
docker build -t gemneye/voxcpm-runpod:latest .
```

Pushing is handled by GitHub Actions (see [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml)). The job logs in with `DOCKER_USERNAME` and `DOCKER_PASSWORD` and pushes the `latest` tag to Docker Hub.
