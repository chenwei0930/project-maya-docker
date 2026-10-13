#!/usr/bin/env python3
"""Compile Maya's CUDA engine for a Docker image, without requiring a GPU."""

import os
import shutil
from pathlib import Path

import maya
import setup as S


def main() -> None:
    raw_archs = os.environ.get(
        "CUDA_ARCHITECTURES", "75;80;86;89;90;100;120"
    )
    archs = sorted({
        int(item)
        for item in raw_archs.replace(",", ";").split(";")
        if item.strip()
    })

    if not archs:
        raise SystemExit("CUDA_ARCHITECTURES must contain at least one SM number")

    nvcc = shutil.which("nvcc")
    if not nvcc:
        raise SystemExit("nvcc was not found; use a CUDA devel image")

    llama = S.get_llama_cpp()
    source_hash = S.source_hash(maya.ENGINE_SOURCES)

    # Keep peak compiler memory reasonable on hosted GitHub runners.
    maya.mem_gb = lambda: (8.0, 8.0)

    result = maya.compile_engine(
        archs=archs,
        gpu_ids=[],
        nvcc=nvcc,
        host_compiler=None,
        llama=Path(llama),
        src=source_hash,
    )
    if result is None:
        raise SystemExit("Maya engine compilation failed")


if __name__ == "__main__":
    main()
