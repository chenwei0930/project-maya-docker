#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

# 脚本位于 <repo>/tools/；把仓库根目录加入模块搜索路径，
# 以便导入根目录下的 maya.py 和 setup.py。
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import maya as M
import setup as S


def main():
    raw_archs = os.environ.get(
        "CUDA_ARCHITECTURES",
        "75;80;86;89;90;100;120",
    )
    archs = sorted({
        int(item)
        for item in raw_archs.replace(",", ";").split(";")
        if item.strip()
    })

    if not archs:
        raise SystemExit("CUDA_ARCHITECTURES must contain at least one architecture")

    nvcc = shutil.which("nvcc")
    if not nvcc:
        raise SystemExit(
            "nvcc not found; the Docker base image must be a CUDA devel image"
        )

    llama = S.get_llama_cpp()
    source_hash = S.source_hash(S.ENGINE_SOURCES)

    # 让 Maya 的构建逻辑按有限内存估算并行任务数。
    M.mem_gb = lambda: (8.0, 8.0)

    result = M.compile_engine(
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
