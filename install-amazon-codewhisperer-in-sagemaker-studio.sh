#!/usr/bin/env bash

eval "$(conda shell.bash hook)"
conda activate studio
pip install amazon-codewhisperer-jupyterlab-ext~=1.0
jupyter server extension enable amazon_codewhisperer_jupyterlab_ext
conda deactivate
restart-jupyter-server
