# syntax=docker/dockerfile:1.7

ARG CUDA_DEVEL_IMAGE=nvidia/cuda:13.1.2-devel-ubuntu24.04
ARG CUDA_RUNTIME_IMAGE=nvidia/cuda:13.1.2-runtime-ubuntu24.04

# ---------- Build stage ----------
FROM ${CUDA_DEVEL_IMAGE} AS build

ARG CUDA_ARCH=86
ARG MAYA_SOURCE_REF=unknown

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      git \
      ninja-build \
      pkg-config \
      python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# 构建 A10 对应的 sm_86 CUDA 二进制。
# STRATA_PORTABLE=ON 让 CPU 部分使用 AVX2 基线，避免依赖 GitHub runner 的特定 CPU 指令集。
RUN cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCH} \
      -DSTRATA_ENABLE_CUDA=ON \
      -DSTRATA_BUILD_TESTS=OFF \
      -DSTRATA_PORTABLE=ON \
    && cmake --build build --target strata --parallel 2 \
    && install -D -m 0755 build/strata /out/strata \
    && printf '%s\n' "${MAYA_SOURCE_REF}" > /out/MAYA_SOURCE_REF \
    && printf '%s\n' "${CUDA_ARCH}" > /out/CUDA_ARCH

# ---------- Runtime stage ----------
FROM ${CUDA_RUNTIME_IMAGE} AS runtime

ARG CUDA_ARCH=86
ARG MAYA_SOURCE_REF=unknown

LABEL org.opencontainers.image.title="Project Maya compiled engine" \
      org.opencontainers.image.source="https://github.com/mw00/project-maya" \
      org.opencontainers.image.version="${MAYA_SOURCE_REF}" \
      org.opencontainers.image.description="Project Maya CUDA ${CUDA_ARCH} / NVIDIA A10 sm_86 build"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      libgomp1 \
      libnuma1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/strata /usr/local/bin/strata
COPY --from=build /out/MAYA_SOURCE_REF /usr/share/project-maya/MAYA_SOURCE_REF
COPY --from=build /out/CUDA_ARCH /usr/share/project-maya/CUDA_ARCH

# 此镜像打包的是编译后的 strata 引擎，不包含模型权重。
# 可以在运行时覆盖 CMD 来执行需要的命令。
CMD ["/bin/bash"]
