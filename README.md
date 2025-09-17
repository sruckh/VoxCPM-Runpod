# VoxCPM on RunPod

This repository provides the minimal container scaffolding required to launch the upstream [OpenBMB/VoxCPM](https://github.com/OpenBMB/VoxCPM) project on RunPod. The resulting image is intentionally bare: every dependency is installed on first container boot so the base image stays small and simple.

## Image layout

* **Base image:** `nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04` keeps GPU support without pre-installing Python tooling.
* **Bootstrap script:** `/usr/local/bin/bootstrap.sh` runs whenever the container starts. On first launch it:
  1. Installs system dependencies with `apt` (Python 3.10, git, ffmpeg, etc.).
  2. Clones or updates the upstream VoxCPM repository into `/workspace/VoxCPM`.
  3. Creates a virtual environment in `/workspace/.venv` and installs VoxCPM with all Python dependencies. `PIP_EXTRA_INDEX_URL` defaults to the CUDA 12.4 PyTorch wheel index so GPU wheels are retrieved automatically.
  4. Writes `/workspace/.env` which can be customised before starting workloads.

A marker file (`/workspace/.voxcpm_bootstrapped`) prevents repeat installations. Delete it if you want to re-run the full setup.

After bootstrapping, the script sources the virtual environment and, if no command is provided, keeps the container alive with `tail -f /dev/null`. Supplying a command to the container runs it inside the prepared environment.

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

Provide a command to the container to start services automatically:

```bash
docker run --rm -it gemneye/voxcpm-runpod:latest \
  bash -lc "source /workspace/.venv/bin/activate && python app.py"
```

## Local build and publish

```bash
docker build -t gemneye/voxcpm-runpod:latest .
```

Pushing is handled by GitHub Actions (see [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml)). The job logs in with `DOCKER_USERNAME` and `DOCKER_PASSWORD` and pushes the `latest` tag to Docker Hub.
