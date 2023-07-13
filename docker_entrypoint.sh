#!/bin/sh

cd /stable-diffusion-webui

mkdir -p /mnt/files/models
rsync -ru ./models_init/ /mnt/files/models/
cp -r /mnt/default-models/ /mnt/files/models/
ln -s /mnt/files/models

mkdir -p /mnt/files/saved
ln -s /mnt/files/saved

mkdir -p /mnt/files/outputs
ln -s /mnt/files/outputs

exec tini -- python -u webui.py \
  --listen --port=7860 \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file /data/config.json --ui-config-file /data/ui-config.json \
  --hide-ui-dir-config \
  --use-intel-oneapi 