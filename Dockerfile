FROM start9/ai-base:latest

RUN apt-get update && \
    apt-get install -y git libgl1 libgl1-mesa-dri libglib2.0-0 tini && \
    rm -rf /var/lib/apt/lists

ADD ./stable-diffusion-webui/requirements_versions.txt /stable-diffusion-webui/requirements_versions.txt
WORKDIR /stable-diffusion-webui
RUN pip install -r requirements_versions.txt
ADD ./stable-diffusion-webui/modules/paths_internal.py /stable-diffusion-webui/modules/paths_internal.py
ADD ./stable-diffusion-webui/modules/cmd_args.py /stable-diffusion-webui/modules/cmd_args.py
ADD ./stable-diffusion-webui/launch.py /stable-diffusion-webui/launch.py
RUN python launch.py --exit --skip-torch-cuda-test
RUN rm -r repositories/*/.git

ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD webui.patch webui.patch
RUN patch -p1 < webui.patch
ADD ./icon.png icon.png
RUN mv models models_init
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD --chmod=755 ./check-mem.py /usr/local/bin/check-mem.py
ADD --chmod=755 ./check-download.py /usr/local/bin/check-download.py
ADD --chmod=755 ./download-model.py /usr/local/bin/download-model.py
