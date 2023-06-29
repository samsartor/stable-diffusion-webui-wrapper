FROM intel/intel-extension-for-pytorch:xpu-flex

RUN apt-get update && \
    apt-get install -y libgl1 libgl1-mesa-dri libglib2.0-0 && \
    apt-get install -y git intel-oneapi-dpcpp-cpp-2023.1.0 intel-oneapi-mkl-devel pkg-config libpng-dev libjpeg-dev python3-dev && \
    rm -rf /var/lib/apt/lists

RUN cd ~ && \
    wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/89283df8-c667-47b0-b7e1-c4573e37bd3e/2023.1-linux-hotfix.zip && \
    unzip 2023.1-linux-hotfix.zip && \
    bash 2023.1-linux-hotfix/installpatch.sh

RUN cd ~ && \
    git clone https://github.com/intel/intel-extension-for-pytorch.git && \
    cd intel-extension-for-pytorch && \
    git checkout b7412a424a7f4cf048efcf4c20fabd9b311ae369 && \
    bash scripts/compile_bundle.sh /opt/intel/oneapi/compiler/latest /opt/intel/oneapi/mkl/latest cml

ADD ./stable-diffusion-webui/requirements_versions.txt /stable-diffusion-webui/requirements_versions.txt
WORKDIR /stable-diffusion-webui
RUN pip install -r requirements_versions.txt
#RUN pip --force-reinstall ~/intel-extension-for-pytorch/dist/*.whl
ADD ./stable-diffusion-webui/modules/paths_internal.py /stable-diffusion-webui/modules/paths_internal.py
ADD ./stable-diffusion-webui/modules/cmd_args.py /stable-diffusion-webui/modules/cmd_args.py
ADD ./stable-diffusion-webui/launch.py /stable-diffusion-webui/launch.py
RUN python launch.py --exit --skip-torch-cuda-test
RUN rm -r repositories/*/.git

ADD ./stable-diffusion-webui /stable-diffusion-webui
ADD --chmod=755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
