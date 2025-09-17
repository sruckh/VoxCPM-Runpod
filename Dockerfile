FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /workspace

COPY scripts/bootstrap.sh /usr/local/bin/bootstrap.sh

RUN chmod +x /usr/local/bin/bootstrap.sh

ENTRYPOINT ["/usr/local/bin/bootstrap.sh"]
