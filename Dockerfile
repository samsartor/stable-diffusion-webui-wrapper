# First build our patched version of the Gradio UI framework
FROM ubuntu:23.04 as gradio_build
RUN apt-get update
RUN apt-get install nodejs patch python3 python3-pip curl wget -y
RUN curl -fsSL https://get.pnpm.io/install.sh | PNPM_VERSION=7.33.6 bash -
ENV PATH="${PATH}:/root/.local/share/pnpm"
ENV NODE_OPTIONS="--max-old-space-size=8192"
ADD ./gradio /gradio-src
WORKDIR /gradio-src
ADD gradio.patch /gradio-src/gradio.patch
RUN patch -p1 < gradio.patch
#RUN bash scripts/install_gradio.sh
RUN bash scripts/build_frontend.sh
RUN apt-get install python3-build python3-requests python3-venv -y
RUN python3 -m build -w

# Now build the actual package
FROM start9/ai-base:latest as stable_diffusion_build

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

# Install the Gradio wheel
COPY --from=gradio_build /gradio-src/dist/* /tmp/gradio-dist/
RUN pip install /tmp/gradio-dist/*.whl --force-reinstall --no-deps

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
