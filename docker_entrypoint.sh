#!/usr/bin/bash

# The root directory of the webui server
cd /stable-diffusion-webui

# Make sure the correcte models dir exists in the file browser
mkdir -p /mnt/files/models
rm -rf /mnt/files/models.tmp
# Switch to a temporary directory in case the entrypoint dies
mv -T /mnt/files/models /mnt/files/models.tmp
# Copy small README-style files from the webui directory
rsync -ru ./models_init/. /mnt/files/models.tmp/
# Copy the larger default model checkpoints, using cp since it supports reflink
cp -au --reflink=auto /mnt/default-models/. /mnt/files/models.tmp/
# Make the temporary directory official
mv -T /mnt/files/models.tmp /mnt/files/models
# Symlink the models directory into the webui directory where it is expected
ln -s /mnt/files/models

# Set up other persistant directories
for dir in saved outputs; do
  mkdir -p /mnt/files/$dir
  ln -s /mnt/files/$dir
done


# Start the webui server
exec tini -- python -u webui.py \
  --listen --port=7860 \
  --precision full --no-half \
  --allow-code --enable-insecure-extension-access --api \
  --ui-settings-file /data/config.json --ui-config-file /data/ui-config.json \
  --no-download-sd-model \
  --hide-ui-dir-config \
  --use-intel-oneapi 