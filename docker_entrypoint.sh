#!/bin/sh

cd /stable-diffusion-webui

mkdir -p /data/models
rsync -ru ./models /data/models
rm -r ./models
ln -s /data/models

mkdir -p /data/log
ln -s /data/log

mkdir -p /data/outputs
ln -s /data/outputs

mkdir -p /data/config
ln -s /data/config

python -u webui.py \
  --listen --port=7860 \
  --use-intel-oneapi \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file config/config.json --ui-config-file config/ui-config.json
  # --use-cpu all \
