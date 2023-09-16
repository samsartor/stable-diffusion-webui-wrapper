#!/usr/bin/bash

set -x

# The root directory of the webui server
cd /stable-diffusion-webui

# Make sure the correcte models dir exists in the file browser
mkdir -p /mnt/files/models
rm -rf /mnt/files/models.tmp
# Switch to a temporary directory in case the entrypoint dies
mv -T /mnt/files/models /mnt/files/models.tmp
# Copy small README-style files from the webui directory
rsync -ru ./models_init/. /mnt/files/models.tmp/
# Make the temporary directory official
mv -T /mnt/files/models.tmp /mnt/files/models
# Symlink the models directory into the webui directory where it is expected
ln -s /mnt/files/models

# Set up other persistant directories
for dir in saved outputs extensions; do
  mkdir -p /mnt/files/$dir
  rsync -ru ./$dir_init/. /mnt/files/$dir
  ln -s /mnt/files/$dir
done

# Start downloading the model in the background
download-model.py \
  '/mnt/files/models/Stable-diffusion' \
  'https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors' \
  'dcd690123cfc64383981a31d955694f6acf2072a80537fdb612c8e58ec87a8ac' \
  'stable-diffusion-v2_1.safetensors' \
  'https://civitai.com/api/download/models/128713' \
  '879db523c30d3b9017143d56705015e15a2cb5628762c11d086fed9538abd7fd' \
  'dreamshaper-v8.safetensors'

# Start the webui server
exec tini -- \
  python -u webui.py \
  --listen --port=7860 \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file /data/config.json --ui-config-file /data/ui-config.json \
  --no-download-sd-model \
  --hide-ui-dir-config \
  --use-intel-oneapi 