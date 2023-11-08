#!/usr/bin/env bash

sudo yum install -y iproute jq lsof

eval "$(conda shell.bash hook)"
conda activate studio
pip install -r requirements.txt
conda deactivate
