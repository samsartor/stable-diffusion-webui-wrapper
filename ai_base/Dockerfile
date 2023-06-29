# We need to support the Comet Lake iGPU
ARG AOT_DEVICES=cml

# Pin to a specific IPEX version
ARG IPEX_REVISION=b7412a424a7f4cf048efcf4c20fabd9b311ae369

# Start with Intel's own IPEX container
FROM intel/intel-extension-for-pytorch:xpu-flex as compile

# Install the dependencies needed to compile IPEX
RUN apt-get update && \
    apt-get install -y git intel-oneapi-dpcpp-cpp-2023.1.0 intel-oneapi-mkl-devel pkg-config libpng-dev libjpeg-dev python3-dev && \
    rm -rf /var/lib/apt/lists

# Patch the DPC++ compiler to support IPEX stuff
RUN cd ~ && \
    wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/89283df8-c667-47b0-b7e1-c4573e37bd3e/2023.1-linux-hotfix.zip && \
    unzip 2023.1-linux-hotfix.zip && \
    bash 2023.1-linux-hotfix/installpatch.sh

# Compile the specific IPEX version we need, this takes a very long time
ADD --chmod=755 ./ipex_*_bundle.sh /ipex/
WORKDIR /ipex
RUN ./prepare_bundle.sh ${IPEX_REVISION} /opt/intel/oneapi/compiler/latest /opt/intel/oneapi/mkl/latest ${AOT_DEVICES}
RUN ./compile_bundle.sh ${IPEX_REVISION} /opt/intel/oneapi/compiler/latest /opt/intel/oneapi/mkl/latest ${AOT_DEVICES}
		
# Reset to Intel's default IPEX container
FROM intel/intel-extension-for-pytorch:xpu-flex as compile

# Copy over the compiled python packages
COPY --from=compile /usr/local/lib/python3.10/dist-packages/ /usr/local/lib/python3.10/dist-packages/
