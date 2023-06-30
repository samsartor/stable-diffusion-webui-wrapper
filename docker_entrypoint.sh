#!/bin/sh

cd /stable-diffusion-webui

mkdir -p /mnt/files/models
rsync -ru ./models_init/ /mnt/files/models/
ln -s /mnt/files/models

mkdir -p /mnt/files/saved
mkdir -p log
ln -s /mnt/files/saved log/images

mkdir -p /mnt/files/outputs
ln -s /mnt/files/outputs

python -u webui.py \
  --listen --port=7860 \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file /data/config.json --ui-config-file /data/ui-config.json \
  --hide_ui_dir_config true \
  --use-cpu all
# --use-intel-oneapi
