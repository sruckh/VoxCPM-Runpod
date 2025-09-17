FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /workspace

COPY scripts/bootstrap.sh /usr/local/bin/bootstrap.sh
COPY scripts/run_voxcpm_demo.sh /usr/local/bin/run_voxcpm_demo.sh

RUN chmod +x /usr/local/bin/bootstrap.sh /usr/local/bin/run_voxcpm_demo.sh

ENTRYPOINT ["/usr/local/bin/bootstrap.sh"]
