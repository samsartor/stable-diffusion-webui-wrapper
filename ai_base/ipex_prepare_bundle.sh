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

# Install python dependency
python -m pip install cmake astunparse numpy ninja pyyaml mkl-static mkl-include setuptools cffi typing_extensions future six requests dataclasses Pillow

# Checkout individual components
if [ ! -d llvm-project ]; then
    git clone https://github.com/llvm/llvm-project.git
fi
if [ ! -d pytorch ]; then
    git clone https://github.com/pytorch/pytorch.git
fi
if [ ! -d vision ]; then
    git clone https://github.com/pytorch/vision.git
fi
if [ ! -d audio ]; then
    git clone https://github.com/pytorch/audio.git
fi
if [ ! -d intel-extension-for-pytorch ]; then
    git clone https://github.com/intel/intel-extension-for-pytorch.git
fi

# Checkout required branch/commit and update submodules
cd llvm-project
if [ ! -z ${VER_LLVM} ]; then
    git checkout ${VER_LLVM}
fi
git submodule sync
git submodule update --init --recursive
cd ../pytorch
if [ ! -z ${VER_PYTORCH} ]; then
    git checkout ${VER_PYTORCH}
fi
git submodule sync
git submodule update --init --recursive
cd ../vision
if [ ! -z ${VER_TORCHVISION} ]; then
    git checkout ${VER_TORCHVISION}
fi
git submodule sync
git submodule update --init --recursive
cd ../audio
if [ ! -z ${VER_TORCHAUDIO} ]; then
    git checkout ${VER_TORCHAUDIO}
fi
git submodule sync
git submodule update --init --recursive
cd ../intel-extension-for-pytorch
if [ ! -z ${VER_IPEX} ]; then
    git checkout ${VER_IPEX}
fi
git submodule sync
git submodule update --init --recursive

# Compile individual component
#  LLVM
cd ../llvm-project
if [ -d build ]; then
    rm -rf build
fi
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=1" -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF ../llvm/
cmake --build . -j $MAX_JOBS
LLVM_ROOT="$(pwd)/../release"
if [ -d ${LLVM_ROOT} ]; then
    rm -rf ${LLVM_ROOT}
fi
cmake -DCMAKE_INSTALL_PREFIX=${LLVM_ROOT}/../release/ -P cmake_install.cmake
ln -s ${LLVM_ROOT}/bin/llvm-config ${LLVM_ROOT}/bin/llvm-config-13
export PATH=${LLVM_ROOT}/bin:$PATH
export LD_LIBRARY_PATH=${LLVM_ROOT}/lib:$LD_LIBRARY_PATH
cd ..
#  PyTorch
cd ../pytorch
git stash
git clean -f
git apply ../intel-extension-for-pytorch/torch_patches/*.patch
export USE_LLVM=${LLVM_ROOT}
export LLVM_DIR=${USE_LLVM}/lib/cmake/llvm
# Ensure cmake can find python packages when using conda or virtualenv
if [ -n "${CONDA_PREFIX-}" ]; then
    export CMAKE_PREFIX_PATH=${CONDA_PREFIX:-"$(dirname $(command -v conda))/../"}
elif [ -n "${VIRTUAL_ENV-}" ]; then
    export CMAKE_PREFIX_PATH=${VIRTUAL_ENV:-"$(dirname $(command -v python))/../"}
fi
export USE_STATIC_MKL=1
export _GLIBCXX_USE_CXX11_ABI=1
export USE_NUMA=0
export USE_CUDA=0
python setup.py clean
python setup.py bdist_wheel 2>&1 | tee build.log
unset USE_CUDA
unset USE_NUMA
unset _GLIBCXX_USE_CXX11_ABI
unset USE_STATIC_MKL
unset CMAKE_PREFIX_PATH
unset LLVM_DIR
unset USE_LLVM
python -m pip uninstall -y mkl-static mkl-include
python -m pip install --force-reinstall dist/*.whl
#  TorchVision
cd ../vision
python setup.py clean
python setup.py bdist_wheel 2>&1 | tee build.log
python -m pip install --force-reinstall --no-deps dist/*.whl
# don't fail on external scripts
set +uex
source ${DPCPP_ENV}
source ${ONEMKL_ENV}
set -uex
#  TorchAudio
cd ../audio
python -m pip install -r requirements.txt
python setup.py clean
python setup.py bdist_wheel 2>&1 | tee build.log
python -m pip install --force-reinstall --no-deps dist/*.whl
