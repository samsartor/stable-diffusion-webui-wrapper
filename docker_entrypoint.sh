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
for dir in saved outputs; do
  mkdir -p /mnt/files/$dir
  ln -s /mnt/files/$dir
done

serve-progress.py & disown

# Start downloading the model in the background
download-model.py \
  '/mnt/files/models/Stable-diffusion' \
  \
  'https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors?download=true' \
  'e869ac7d6942cb327d68d5ed83a40447aadf20e0c3358d98b2cc9e270db0da26' \
  'sd_xl_turbo_1.0_fp16.safetensors' \
  \
  'https://civitai.com/api/download/models/351306' \
  '4496b36d48bfd7cfe4e5dbce3485db567bcefa2bef7238d290dbd45612125083' \
  'dreamshaperXL_v21TurboDPMSDE.safetensors'

# Set the Huggingface cache dir
export HF_HOME=/data/.cache/huggingface

WEBUI_EXTRA='--use-cpu'
if grep -q -wi 'GenuineIntel' /proc/cpuinfo; then
  WEBUI_EXTRA='--use-ipex'
fi

# Start the webui server
exec tini -s -- \
  python -u webui.py \
  --listen --port=7860 \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file /data/config.json --ui-config-file /data/ui-config.json \
  --no-download-sd-model \
  --hide-ui-dir-config \
  --ckpt /mnt/files/models/Stable-diffusion/dreamshaperXL_v21TurboDPMSDE.safetensors \
  $WEBUI_EXTRA
