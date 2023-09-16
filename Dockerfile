FROM start9/ai-base:latest

# Make sure Ubuntu has the required packages installed
RUN apt-get update && \
    apt-get install -y git libgl1 libgl1-mesa-dri libglib2.0-0 tini && \
    rm -rf /var/lib/apt/lists

# Install requirements and setup system
ADD ./stable-diffusion-webui/requirements_versions.txt /stable-diffusion-webui/requirements_versions.txt
WORKDIR /stable-diffusion-webui
RUN pip install -r requirements_versions.txt
ADD ./stable-diffusion-webui/modules/paths_internal.py /stable-diffusion-webui/modules/paths_internal.py
ADD ./stable-diffusion-webui/modules/cmd_args.py /stable-diffusion-webui/modules/cmd_args.py
ADD ./stable-diffusion-webui/launch.py /stable-diffusion-webui/launch.py
RUN python launch.py --exit --skip-torch-cuda-test
RUN rm -r repositories/*/.git

# Add and patch the WebUI source
ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD webui.patch webui.patch
RUN patch -p1 < webui.patch
ADD ./icon.png icon.png

# Install additional default extensions
RUN wget -qO- https://github.com/Bing-su/adetailer/archive/refs/tags/v23.9.2.tar.gz | tar xz -C extensions-builtin
RUN python extensions-builtin/adetailer-23.9.2/install.py

# Create init directories to be copied to /mnt/files/ on startup
RUN mv models models_init
RUN mv extensions extensions_init
RUN mkdir saved_init
RUN mkdir outputs_init

# Copy important scripts from the start9 wrapper repository
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD --chmod=755 ./check-mem.py /usr/local/bin/check-mem.py
ADD --chmod=755 ./check-download.py /usr/local/bin/check-download.py
ADD --chmod=755 ./serveprogress.py /usr/local/bin/serveprogress.py
ADD --chmod=755 ./download-model.py /usr/local/bin/download-model.py
