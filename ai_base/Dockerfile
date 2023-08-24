# Start with Intel's own IPEX container
FROM intel/intel-extension-for-pytorch:xpu-flex as compile

# We need to support the Comet Lake iGPU
ARG AOT_DEVICES=cml

# Pin to a specific IPEX version
ARG IPEX_REVISION=509a3789d7a6b1f67fda0b2b8b785a81d1ce221d

# Install the dependencies needed to compile IPEX
USER root
RUN apt-get update && \
    apt-get install -y git intel-oneapi-dpcpp-cpp-2023.2.0 intel-oneapi-mkl-devel pkg-config libpng-dev libjpeg-dev python3-dev && \
    rm -rf /var/lib/apt/lists

# Compile the specific IPEX version we need, this takes a very long time
ADD --chmod=755 ./ipex_compile_bundle.sh /ipex/compile_bundle.sh
WORKDIR /ipex
RUN ./compile_bundle.sh ${IPEX_REVISION} /opt/intel/oneapi/compiler/latest /opt/intel/oneapi/mkl/latest ${AOT_DEVICES}
		
# Reset all the build dependency stuff
FROM intel/intel-extension-for-pytorch:xpu-flex

# Copy over the compiled python packages
COPY --from=compile /usr/local/lib/python3.10/dist-packages/ /usr/local/lib/python3.10/dist-packages/
