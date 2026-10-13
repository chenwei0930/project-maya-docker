# syntax=docker/dockerfile:1

# Use a CUDA *devel* image: nvcc is required at image-build time.
FROM nvidia/cuda:12.8.1-devel-ubuntu24.04

ARG CUDA_ARCHITECTURES=75;80;86;89;90;100;120

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
    HOME=/root

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      libgomp1 \
      python3 \
      python3-pip \
      python3-venv \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/project-maya
COPY . .

RUN python3 -m venv .venv \
    && .venv/bin/pip install --no-cache-dir --upgrade pip \
    && .venv/bin/pip install --no-cache-dir \
         numpy jinja2 regex pyyaml tqdm requests cmake ninja pillow psutil \
    && chmod +x maya.sh \
    && .venv/bin/python tools/docker_build.py

# Model files, pack, and user data are kept outside the image.
RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 8080

ENTRYPOINT ["/opt/project-maya/docker-entrypoint.sh"]
