#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
[[ -x .venv/bin/python ]] || { echo 'Execute primeiro: bash scripts/setup-cloud.sh' >&2; exit 1; }
[[ -f weights/LongCat-Video/dit/config.json ]] || { echo 'Modelo ausente. Execute novamente o instalador.' >&2; exit 1; }
export PATH="$PWD/.venv/bin:$PATH"
export HF_HOME="$PWD/weights/.huggingface"
python - <<'PY'
import torch
if not torch.cuda.is_available():
    raise SystemExit('A GPU NVIDIA nao esta disponivel.')
PY
# Loopback by default: access through the SSH tunnel described in the guide.
exec python -m streamlit run run_streamlit.py \
    --server.address=127.0.0.1 \
    --server.port=8501 \
    --server.headless=true \
    --server.fileWatcherType=none \
    --browser.gatherUsageStats=false
