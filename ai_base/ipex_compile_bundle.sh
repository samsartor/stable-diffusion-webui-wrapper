#!/usr/bin/env bash
#
# Please review the system requirements before running this script
# https://intel.github.io/intel-extension-for-pytorch/xpu/latest/tutorials/installation.html
#
set -ueo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: bash $0 <DPCPPROOT> <MKLROOT> [AOT]"
    echo "DPCPPROOT and MKLROOT are mandatory, should be absolute or relative path to the root directory of DPC++ compiler and oneMKL respectively."
    echo "AOT is optional, should be the text string for environment variable USE_AOT_DEVLIST."
    exit 1
fi

VER_LLVM="llvmorg-13.0.0"
VER_PYTORCH="v2.0.1"
VER_TORCHVISION="v0.15.2"
VER_TORCHAUDIO="v2.0.2"
VER_IPEX=$1 # Start9: pin to a specific commit
VER_GCC=11

DPCPP_ROOT=$2
ONEMKL_ROOT=$3
AOT=""
if [[ $# -ge 4 ]]; then
    AOT=$4
fi

# Check existance of DPCPP and ONEMKL environments
DPCPP_ENV=${DPCPP_ROOT}/env/vars.sh
if [ ! -f ${DPCPP_ENV} ]; then
    echo "DPC++ compiler environment ${DPCPP_ENV} doesn't seem to exist."
    exit 2
fi

ONEMKL_ENV=${ONEMKL_ROOT}/env/vars.sh
if [ ! -f ${ONEMKL_ENV} ]; then
    echo "oneMKL environment ${ONEMKL_ENV} doesn't seem to exist."
    exit 3
fi

# Check existance of required Linux commands
for APP in python git patch pkg-config nproc bzip2 gcc g++; do
    command -v $APP || (echo "Error: Command \"${APP}\" not found." ; exit 4)
done

# Check existance of required libs
for LIB_NAME in libpng libjpeg; do
    pkg-config --exists $LIB_NAME || (echo "Error: \"${LIB_NAME}\" not found in pkg-config." ; exit 5)
done

if [ $(gcc -dumpversion) -ne $VER_GCC ]; then
    echo -e '\a'
    echo "Warning: GCC version ${VER_GCC} is recommended"
    echo "Found GCC version $(gcc -dumpfullversion)"
    sleep 5
fi

# set number of compile processes, if not already defined
if [ -z "${MAX_JOBS-}" ]; then
    export MAX_JOBS=$(nproc)
fi

# Save current directory path
BASEFOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${BASEFOLDER}

# Be verbose now
set -x

#  Intel® Extension for PyTorch*
cd intel-extension-for-pytorch
python -m pip install -r requirements.txt
if [[ ! ${AOT} == "" ]]; then
    export USE_AOT_DEVLIST=${AOT}
fi
export USE_LLVM=${LLVM_ROOT}
export LLVM_DIR=${USE_LLVM}/lib/cmake/llvm
export DNNL_GRAPH_BUILD_COMPILER_BACKEND=1
python setup.py clean
python setup.py bdist_wheel 2>&1 | tee build.log
unset DNNL_GRAPH_BUILD_COMPILER_BACKEND
unset LLVM_DIR
unset USE_LLVM
if [[ ! ${AOT} == "" ]]; then
    unset USE_AOT_DEVLIST
fi
python -m pip install --force-reinstall dist/*.whl

# Sanity Test
cd ..
python -c "import torch; import torchvision; import torchaudio; import intel_extension_for_pytorch as ipex; print(f'torch_cxx11_abi:     {torch.compiled_with_cxx11_abi()}'); print(f'torch_version:       {torch.__version__}'); print(f'torchvision_version: {torchvision.__version__}'); print(f'torchaudio_version:  {torchaudio.__version__}'); print(f'ipex_version:        {ipex.__version__}');"

