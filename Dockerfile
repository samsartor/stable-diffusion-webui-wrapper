# Start with Intel's own IPEX container
FROM intel/intel-extension-for-pytorch:2.1.10-xpu-pip-base

# Install the CPU version of pytorch specifically, since that is what we want IPEX to use
RUN python -m pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cpu
RUN python -m pip install intel-extension-for-pytorch==2.1.100
RUN python -m pip install oneccl_bind_pt==2.1.0 --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/cpu/us/

# Make sure Ubuntu has Automatic1111's required packages installed
RUN apt-get update &&\
     apt-get install -y git libgl1 libgl1-mesa-dri libglib2.0-0 tini libpng16-16 &&\
     rm -rf /var/lib/apt/lists

# Install python requirements and setup system
ADD ./stable-diffusion-webui/requirements_versions.txt /stable-diffusion-webui/requirements_versions.txt
WORKDIR /stable-diffusion-webui
RUN pip install -r requirements_versions.txt
ADD ./stable-diffusion-webui/modules /stable-diffusion-webui/modules
ADD ./stable-diffusion-webui/launch.py /stable-diffusion-webui/launch.py
RUN python launch.py --exit --skip-torch-cuda-test
RUN rm -r repositories/*/.git

# Add and patch the WebUI source
ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD webui.patch webui.patch
RUN patch -p1 < webui.patch
ADD ./icon.png icon.png

# Install additional default extensions
#RUN wget -qO- https://github.com/Bing-su/adetailer/archive/refs/tags/v23.9.2.tar.gz | tar xz -C extensions-builtin
#RUN python extensions-builtin/adetailer-23.9.2/install.py

# Clear the cache dir
RUN rm -r /root/.cache

# Create init directory to be copied to /mnt/files/ on startup
RUN mv models models_init

# Copy important scripts from the start9 wrapper repository
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD --chmod=755 ./check-mem.py /usr/local/bin/check-mem.py
ADD --chmod=755 ./serve-progress.py /usr/local/bin/serve-progress.py
ADD --chmod=755 ./download-model.py /usr/local/bin/download-model.py
