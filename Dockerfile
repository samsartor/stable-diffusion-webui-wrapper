FROM intel/intel-extension-for-pytorch:xpu-flex

RUN apt-get update && \
    apt-get install -y git libgl1 libgl1-mesa-dri libglib2.0-0 && \
    rm -rf /var/lib/apt/lists

ADD ./stable-diffusion-webui/requirements_versions.txt /stable-diffusion-webui/requirements_versions.txt
WORKDIR /stable-diffusion-webui
RUN pip install -r requirements_versions.txt
RUN pip install torch==1.13.0a0+git6c9b55e torchvision==0.14.1a0 intel_extension_for_pytorch==1.13.120+xpu -f https://developer.intel.com/ipex-whl-stable-xpu
ADD ./stable-diffusion-webui/modules/paths_internal.py /stable-diffusion-webui/modules/paths_internal.py
ADD ./stable-diffusion-webui/modules/cmd_args.py /stable-diffusion-webui/modules/cmd_args.py
ADD ./stable-diffusion-webui/launch.py /stable-diffusion-webui/launch.py
RUN python launch.py --exit --skip-torch-cuda-test
RUN rm -r repositories/*/.git

ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
