FROM start9/ai-base:latest

# Make sure Ubuntu has the required packages installed
RUN apt-get update &&\
     apt-get install -y git libgl1 libgl1-mesa-dri libglib2.0-0 tini libpng16-16 &&\
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

# Also install node version 18 so we can install gradio (version 12 is too old)
# NVM could do this in a normal environment but is a pain in docker. Nodesource used
# to have simple scripts but now we have to this:
ENV NODE_MAJOR 18
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt update && apt install -y nodejs && rm -rf /var/lib/apt/lists

# Install our patch of gradio
ADD ./gradio /gradio-src
ADD gradio.patch /gradio-src/gradio.patch
RUN cd /gradio-src && patch -p1 < gradio.patch
RUN curl -fsSL https://get.pnpm.io/install.sh | PNPM_VERSION=7.33.6 bash -
ENV PATH="${PATH}:/root/.local/share/pnpm"
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN bash /gradio-src/scripts/install_gradio.sh
RUN bash /gradio-src/scripts/build_frontend.sh --filter @gradio/client --filter @gradio/lite

# Node is no longer needed
RUN apt-get purge nodejs -y && \
    rm -r /etc/apt/sources.list.d/nodesource.list && \
    rm -r /etc/apt/keyrings/nodesource.gpg

# Add and patch the WebUI source
ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD webui.patch webui.patch
RUN patch -p1 < webui.patch
ADD ./icon.png icon.png

# Install additional default extensions
RUN wget -qO- https://github.com/Bing-su/adetailer/archive/refs/tags/v23.9.2.tar.gz | tar xz -C extensions-builtin
RUN python extensions-builtin/adetailer-23.9.2/install.py

# Clear the cache dir
RUN rm -r /root/.cache

# Create init directory to be copied to /mnt/files/ on startup
RUN mv models models_init

# Copy important scripts from the start9 wrapper repository
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD --chmod=755 ./check-mem.py /usr/local/bin/check-mem.py
ADD --chmod=755 ./serve-progress.py /usr/local/bin/serve-progress.py
ADD --chmod=755 ./download-model.py /usr/local/bin/download-model.py
