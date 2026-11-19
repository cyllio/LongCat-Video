#!/usr/bin/env bash
# Execute inside a Linux GPU Pod, never on the local Intel laptop.
set -Eeuo pipefail
trap 'echo "Instalacao interrompida na linha $LINENO. Corrija o erro acima e execute novamente." >&2' ERR
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[[ "$(uname -s)" == Linux ]] || { echo 'Use uma maquina Linux com GPU NVIDIA.' >&2; exit 1; }
for tool in conda nvidia-smi nvcc; do
    command -v "$tool" >/dev/null || { echo "Falta $tool. Use a imagem PyTorch/CUDA devel indicada no guia." >&2; exit 1; }
done
nvcc --version | grep -q 'release 12.4' || { echo 'Este instalador requer CUDA Toolkit 12.4.' >&2; exit 1; }
nvidia-smi --query-gpu=name,memory.total --format=csv
available_kb=$(df -Pk . | awk 'END {print $4}')
(( available_kb >= 100 * 1024 * 1024 )) || { echo 'Reserve pelo menos 100 GiB livres antes da instalacao.' >&2; exit 1; }

if command -v apt-get >/dev/null && [[ "$(id -u)" == 0 ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ffmpeg libgl1 libglib2.0-0
else
    echo 'Confira se o sistema ja possui FFmpeg, libGL e GLib instalados.'
fi

if [[ ! -x .venv/bin/python ]]; then
    conda create --yes --override-channels --channel conda-forge --prefix "$PWD/.venv" python=3.10 pip
fi
export PATH="$PWD/.venv/bin:$PATH"
export HF_HOME="$PWD/weights/.huggingface"
export MAX_JOBS="${MAX_JOBS:-4}"
python -m pip install --upgrade pip setuptools wheel
python -m pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124
python - <<'PY'
import torch
if not torch.cuda.is_available():
    raise SystemExit('GPU CUDA indisponivel. Confira a GPU e o driver do Pod.')
if torch.cuda.get_device_properties(0).total_memory < 75 * 1024**3:
    raise SystemExit('Este roteiro foi preparado para uma GPU de 80 GB ou mais.')
if torch.cuda.get_device_capability(0)[0] < 8:
    raise SystemExit('Use uma GPU NVIDIA Ampere ou mais recente (ex.: A100).')
print('GPU:', torch.cuda.get_device_name(0))
PY
python -m pip install ninja packaging psutil
python -m pip install flash-attn==2.7.4.post1 --no-build-isolation
python -m pip install -r requirements.txt sentencepiece protobuf
python -m pip check
python - <<'PY'
import torch
from flash_attn import flash_attn_func
from longcat_video.pipeline_longcat_video import LongCatVideoPipeline
q = torch.randn(1, 32, 2, 64, device='cuda', dtype=torch.bfloat16)
result = flash_attn_func(q, q, q)
assert result.shape == q.shape and torch.isfinite(result).all()
print('PyTorch, FlashAttention e pipeline importados e GPU verificada.')
PY

python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download('meituan-longcat/LongCat-Video', local_dir='./weights/LongCat-Video')
PY
echo 'Instalacao concluida. Inicie com: bash scripts/start-cloud.sh'
