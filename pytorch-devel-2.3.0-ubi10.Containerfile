# vim: syntax=dockerfile expandtab tabstop=4 shiftwidth=4
FROM registry.redhat.io/ubi10/ubi-minimal:10.0-beta

ARG PYTHON_VERSION=3
ARG PYTHON=python${PYTHON_VERSION}
ARG VIRTUAL_ENV=/workspace/venv
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

ENV CCACHE_VERSION=4.10
ENV CCACHE_DIR="/root/.cache/ccache"
ENV LD_LIBRARY_PATH="/usr/lib64"

ARG NVIDIA_DRIVER_VERSION=550.54.15
ARG NVIDIA_DRIVER_STREAM=550
ARG CUDA_VERSION=12.4.1
ARG CUDA_MAJOR_VERSION=12
ARG CUDA_MINOR_VERSION=12.4
ARG CUDA_DASHED_VERSION=12-4
ARG CUDNN_MAJOR_VERSION=9
ARG NCCL_VERSION=2.21.5
ARG NSIGHT_COMPUTE_VERSION=2024.2.0
ARG NSIGHT_SYSTEMS_VERSION=2024.2.3
ARG NVINFER_MAJOR_VERSION=10
ARG ONNXPARSERS_MAJOR_VERSION=10

ARG PYTORCH_VERSION=2.3.0
ARG PYTORCH_AUDIO_VERSION=2.3.0
ARG PYTORCH_TEXT_VERSION=0.18.0
ARG PYTORCH_VISION_VERSION=0.18.0
ARG NVIDIA_FUSER_VERSION=0.0.13

COPY ./ubi10.repo /etc/yum.repos.d/ubi.repo

WORKDIR /workspace

#RUN microdnf -y install --nobest --nodocs --setopt=install_weak_deps=0 --enablerepo=codeready-builder-for-rhel-10-x86_64-rpms \
RUN microdnf -y install --nobest --nodocs --setopt=install_weak_deps=0 \
        ${PYTHON} ${PYTHON}-pip ${PYTHON}-devel ${PYTHON}-pybind11 pybind11-devel \
        findutils file which \
        git-core ninja-build \
        autoconf automake cmake \
        gcc gcc-c++ gcc-fortran \
        cargo rust \
        libffi libffi-devel \
        libibumad \
        libibverbs libibverbs-utils \
        libjpeg-turbo libjpeg-turbo-devel \
        libpng libpng-devel \
        libquadmath \
        librdmacm \
        libtirpc libtirpc-devel \
        openblas openblas-devel \
        openssl-devel \
        protobuf-compiler && \
    microdnf clean all && \
    ${PYTHON} -m venv ${VIRTUAL_ENV} && \
    mkdir -p /root/.local/bin
#        openmpi openmpi-devel \

#ENV OPENMPI_HOME="/usr/lib64/openmpi"
ENV OMPI_MCA_coll_hcoll_enable=0

#ENV PATH="/${OPENMPI_HOME}/bin:${PATH}"
#ENV LD_LIBRARY_PATH="${OPENMPI_HOME}/lib64:${LD_LIBRARY_PATH}"
#ENV LIBRARY_PATH="${OPENMPI_HOME}/lib64:${LIBRARY_PATH}"
#ENV CMAKE_LIBRARY_PATH="${OPENMPI_HOME}/lib:${CUDA_HOME}/lib64:${CMAKE_LIBRARY_PATH}"
#ENV C_INCLUDE_PATH="${OPENMPI_HOME}/include:${C_INCLUDE_PATH}"
#ENV CPLUS_INCLUDE_PATH="${OPENMPI_HOME}/include:${CPLUS_INCLUDE_PATH}"
#ENV CMAKE_INCLUDE_PATH="${OPENMPI_HOME}/include:${CMAKE_INCLUDE_PATH}"

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install numpy pyaml typing_extensions wheel

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    git clone --depth 1 -b v${CCACHE_VERSION} https://github.com/ccache/ccache

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    cd /workspace/ccache && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    mkdir -p ${CCACHE_DIR}

#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
#    microdnf -y install --nobest --nodocs --setopt=install_weak_deps=0 --enablerepo=codeready-builder-for-rhel-10-x86_64-rpms \
#        ccache \
#        ffmpeg-free ffmpeg-free-devel \
#        hdf5 hdf5-devel \
#        libswscale-free libswscale-free-devel \
#        libavcodec-free libavcodec-free-devel \
#        libswresample-free libswresample-free-devel \
#        libavformat-free libavformat-free-devel \
#        libavutil-free libavutil-free-devel \
#        rapidjson-devel && \
#    microdnf clean all && \
#    mkdir -p ${CCACHE_DIR}

#ENV C_INCLUDE_PATH="/usr/include/ffmpeg:${C_INCLUDE_PATH}"
#ENV CPLUS_INCLUDE_PATH="/usr/include/ffmpeg:${CPLUS_INCLUDE_PATH}"
#ENV CMAKE_INCLUDE_PATH="/usr/include/ffmpeg:${CMAKE_INCLUDE_PATH}"

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ln -s /usr/local/bin/ccache /root/.local/bin/gcc && \
    ln -s /usr/local/bin/ccache /root/.local/bin/g++ && \
    ln -s /usr/local/bin/ccache /root/.local/bin/cc && \
    ln -s /usr/local/bin/ccache /root/.local/bin/c++ && \
    ln -s /usr/local/bin/ccache /root/.local/bin/cc1plus

#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    ln -s /usr/local/bin/ccache /root/.local/bin/mpiCC && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/mpicc && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/mpic++ && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/mpicxx && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/orteCC && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/ortecc && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/ortec++ && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/ortecxx && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/oshCC && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/oshcc && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/oshc++ && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/oshcxx && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/shmemCC && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/shmemcc && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/shmemc++ && \
#    ln -s /usr/local/bin/ccache /root/.local/bin/shmemmcxx

# Installing NVIDIA CUDA packages
RUN curl -sL -o /etc/yum.repos.d/cuda.repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo && \
    sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/yum.repos.d/cuda.repo && \
    microdnf -y module enable nvidia-driver:${NVIDIA_DRIVER_STREAM} && \
    microdnf -y install --nobest --nodocs --setopt=install_weak_deps=0 \
        cuda-cccl-${CUDA_DASHED_VERSION} \
        cuda-command-line-tools-${CUDA_DASHED_VERSION} \
        cuda-compat-${CUDA_DASHED_VERSION} \
        cuda-compiler-${CUDA_DASHED_VERSION} \
        cuda-crt-${CUDA_DASHED_VERSION} \
        cuda-cudart-${CUDA_DASHED_VERSION} cuda-cudart-devel-${CUDA_DASHED_VERSION} \
        cuda-cuobjdump-${CUDA_DASHED_VERSION} \
        cuda-cupti-${CUDA_DASHED_VERSION} \
        cuda-cuxxfilt-${CUDA_DASHED_VERSION} \
        cuda-driver-devel-${CUDA_DASHED_VERSION} \
        cuda-gdb-${CUDA_DASHED_VERSION} \
        cuda-libraries-${CUDA_DASHED_VERSION} cuda-libraries-devel-${CUDA_DASHED_VERSION} \
        cuda-minimal-build-${CUDA_DASHED_VERSION} \
        cuda-nsight-compute-${CUDA_DASHED_VERSION} \
        cuda-nvcc-${CUDA_DASHED_VERSION} \
        cuda-nvdisasm-${CUDA_DASHED_VERSION} \
        cuda-nvml-devel-${CUDA_DASHED_VERSION} \
        cuda-nvprof-${CUDA_DASHED_VERSION} \
        cuda-nvprune-${CUDA_DASHED_VERSION} \
        cuda-nvrtc-${CUDA_DASHED_VERSION} cuda-nvrtc-devel-${CUDA_DASHED_VERSION} \
        cuda-nvtx-${CUDA_DASHED_VERSION} \
        cuda-nvvm-${CUDA_DASHED_VERSION} \
        cuda-opencl-${CUDA_DASHED_VERSION} cuda-opencl-devel-${CUDA_DASHED_VERSION} \
        cuda-profiler-api-${CUDA_DASHED_VERSION} \
        cuda-sanitizer-${CUDA_DASHED_VERSION} \
        cuda-toolkit-${CUDA_DASHED_VERSION}-config-common cuda-toolkit-${CUDA_MAJOR_VERSION}-config-common cuda-toolkit-config-common \
        libcublas-${CUDA_DASHED_VERSION} libcublas-devel-${CUDA_DASHED_VERSION} \
        libcudnn9-cuda-${CUDA_MAJOR_VERSION} libcudnn9-devel-cuda-${CUDA_MAJOR_VERSION} \
        libcufft-${CUDA_DASHED_VERSION} libcufft-devel-${CUDA_DASHED_VERSION} \
        libcufile-${CUDA_DASHED_VERSION} libcufile-devel-${CUDA_DASHED_VERSION} \
        libcurand-${CUDA_DASHED_VERSION} libcurand-devel-${CUDA_DASHED_VERSION} \
        libcusolver-${CUDA_DASHED_VERSION} libcusolver-devel-${CUDA_DASHED_VERSION} \
        libcusparse-${CUDA_DASHED_VERSION} libcusparse-devel-${CUDA_DASHED_VERSION} \
        libnccl libnccl-devel \
        libnpp-${CUDA_DASHED_VERSION} libnpp-devel-${CUDA_DASHED_VERSION} \
        libnvfatbin-${CUDA_DASHED_VERSION} libnvfatbin-devel-${CUDA_DASHED_VERSION} \
        libnvjitlink-${CUDA_DASHED_VERSION} libnvjitlink-devel-${CUDA_DASHED_VERSION} \
        libnvjpeg-${CUDA_DASHED_VERSION} libnvjpeg-devel-${CUDA_DASHED_VERSION} \
        nsight-compute-${NSIGHT_COMPUTE_VERSION} && \
    microdnf clean all

ENV CUDA_HOME="/usr/local/cuda"

ENV PATH="${CUDA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
ENV LIBRARY_PATH="${CUDA_HOME}/lib64:${LIBRARY_PATH}"
ENV CMAKE_LIBRARY_PATH="${CUDA_HOME}/lib64:${CMAKE_LIBRARY_PATH}"
ENV C_INCLUDE_PATH="${CUDA_HOME}/include:${C_INCLUDE_PATH}"
ENV CPLUS_INCLUDE_PATH="${CUDA_HOME}/include:${CPLUS_INCLUDE_PATH}"
ENV CMAKE_INCLUDE_PATH="${CUDA_HOME}/include:${CMAKE_INCLUDE_PATH}"

ENV NCCL_LIB_DIR="${CUDA_HOME}/lib64"
ENV NCCL_INCLUDE_DIR="${CUDA_HOME}/include"
ENV XLA_TARGET="cuda124"
ENV XLA_FLAGS="--xla_gpu_cuda_data_dir=${CUDA_HOME}"
ENV CMAKE_ARGS="-DLLAMA_CUBLAS=on"
ENV CFLAGS="-mno-avx"
ENV NVCC_PREPEND_FLAGS="-allow-unsupported-compiler"

ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,video

ENV NVIDIA_REQUIRE_CUDA=cuda>=9.0
ENV CUDA_CACHE_DISABLE=1
ENV CUDA_MODULE_LOADING=LAZY
ENV NCCL_WORK_FIFO_DEPTH=4194304
ENV USE_EXPERIMENTAL_CUDNN_V8_API=1
ENV UCC_CL_BASIC_TLS=^sharp

ENV TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.7 8.9 9.0"
ENV TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1
ENV TORCH_CUDNN_V8_API_ENABLED=1
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ln -s /usr/bin/ccache /root/.local/bin/nvcc && \
    ln -s /usr/bin/ccache /root/.local/bin/cicc && \
    ln -s /usr/bin/ccache /root/.local/bin/ptxas

# Installing Intel OneAPI MKL packages
#COPY ./oneapi.repo /etc/yum.repos.d/oneapi.repo

#RUN microdnf -y install --nobest --nodocs --setopt=install_weak_deps=0 \
#        intel-oneapi-mkl intel-oneapi-mkl-devel && \
#    microdnf clean all

#ENV INTEL_MKL_HOME="/opt/intel/oneapi/mkl/latest"

#ENV PATH="${INTEL_MKL_HOME}/bin:${PATH}"
#ENV LD_LIBRARY_PATH="${INTEL_MKL_HOME}/lib:${LD_LIBRARY_PATH}"
#ENV LIBRARY_PATH="${INTEL_MKL_HOME}/lib:${LIBRARY_PATH}"
#ENV CMAKE_LIBRARY_PATH="${INTEL_MKL_HOME}/lib:${CMAKE_LIBRARY_PATH}"
#ENV C_INCLUDE_PATH="${INTEL_MKL_HOME}/include:${C_INCLUDE_PATH}"
#ENV CPLUS_INCLUDE_PATH="${INTEL_MKL_HOME}/include:${CPLUS_INCLUDE_PATH}"
#ENV CMAKE_INCLUDE_PATH="${INTEL_MKL_HOME}/include:${CMAKE_INCLUDE_PATH}"

WORKDIR /workspace

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    git clone --depth 1 -b v${PYTORCH_VERSION} https://github.com/pytorch/pytorch.git && \
    cd pytorch && \
    git submodule sync && \
    git submodule update --init --recursive

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install setuptools

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    cd /workspace/pytorch && \
    MAX_JOBS=$(nproc) ${VIRTUAL_ENV}/bin/${PYTHON} setup.py bdist_wheel

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install /workspace/pytorch/dist/*.whl

ENV PYTORCH_HOME="${VIRTUAL_ENV}/lib64/${PYTHON}/site-packages/torch"
ENV TORCH_HOME="${VIRTUAL_ENV}/lib64/${PYTHON}/site-packages/torch"

ENV PATH="${PYTORCH_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${PYTORCH_HOME}/lib:${LD_LIBRARY_PATH}"
ENV LIBRARY_PATH="${PYTORCH_HOME}/lib:${LIBRARY_PATH}"
ENV CMAKE_LIBRARY_PATH="${PYTORCH_HOME}/lib:${CMAKE_LIBRARY_PATH}"
ENV C_INCLUDE_PATH="${PYTORCH_HOME}/include:${C_INCLUDE_PATH}"
ENV CPLUS_INCLUDE_PATH="${PYTORCH_HOME}/include:${CPLUS_INCLUDE_PATH}"
ENV CMAKE_INCLUDE_PATH="${PYTORCH_HOME}/include:${CMAKE_INCLUDE_PATH}"

#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    git clone --depth 1 -b v${NVIDIA_FUSER_VERSION} https://github.com/NVIDIA/Fuser.git && \
#    cd Fuser && \
#    git submodule sync --recursive && \
#    git submodule update --init --recursive
#
#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    cd /workspace/Fuser && \
#    Torch_DIR=${PYTORCH_HOME}/share/cmake/Torch TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 9.0" MAX_JOBS=$(nproc) ${VIRTUAL_ENV}/bin/${PYTHON} setup.py bdist_wheel
#
#RUN ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install /workspace/Fuser/dist/*.whl

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    git clone --depth 1 -b v${PYTORCH_AUDIO_VERSION} https://github.com/pytorch/audio.git

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    source ${VIRTUAL_ENV}/bin/activate && \
    cd /workspace/audio && \
    PYTORCH_VERSION=$(${VIRTUAL_ENV}/bin/${PYTHON} -m pip show torch | grep 'Version:' | awk '{ print $2; }') USE_CUDA=1 BUILD_SOX=0 MAX_JOBS=$(nproc) ${VIRTUAL_ENV}/bin/${PYTHON} setup.py bdist_wheel

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install /workspace/audio/dist/*.whl

#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    git clone --depth 1 -b v${PYTORCH_TEXT_VERSION} https://github.com/pytorch/text.git && \
#    cd text && \
#    git submodule sync --recursive && \
#    git submodule update --init --recursive
#
#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    source ${VIRTUAL_ENV}/bin/activate && \
#    cd /workspace/text && \
#    PYTORCH_VERSION=$(${VIRTUAL_ENV}/bin/${PYTHON} -m pip show torch | grep 'Version:' | awk '{ print $2; }') USE_CUDA=1 MAX_JOBS=$(nproc) ${VIRTUAL_ENV}/bin/${PYTHON} setup.py bdist_wheel
#
#RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
#    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install /workspace/text/dist/*.whl

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    git clone --depth 1 -b v${PYTORCH_VISION_VERSION} https://github.com/pytorch/vision.git

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    source ${VIRTUAL_ENV}/bin/activate && \
    cd /workspace/vision && \
    PYTORCH_VERSION=$(${VIRTUAL_ENV}/bin/${PYTHON} -m pip show torch | grep 'Version:' | awk '{ print $2; }') TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.7 8.9 9.0" FORCE_CUDA=1 MAX_JOBS=$(nproc) ${VIRTUAL_ENV}/bin/${PYTHON} setup.py bdist_wheel

RUN --mount=type=cache,id=cache,dst=/root/.cache,mode=0777,Z \
    ${VIRTUAL_ENV}/bin/${PYTHON} -m pip install /workspace/vision/dist/*.whl

ENV OPENMPI_HOME="/usr/lib64/openmpi"
ENV PATH="${OPENMPI_HOME}/bin:${PATH}"

ENV NSIGHT_COMPUTE_VERSION=2024.2.0
ENV NSIGHT_SYSTEMS_VERSION=2024.2.3

ENV CUDA_HOME="/usr/local/cuda"
ENV NCCL_LIB_DIR="${CUDA_HOME}/lib64"
ENV NSIGHT_COMPUTE_HOME="/opt/nvidia/nsight-compute/${NSIGHT_COMPUTE_VERSION}"
ENV NSIGHT_SYSTEMS_HOME="/opt/nvidia/nsight-systems/${NSIGHT_SYSTEMS_VERSION}"
ENV CUDNN_LIB_DIR="/usr/lib64/cudnn"
ENV TENSORT_LIB_DIRS="/usr/lib64/libcutensor/11:/usr/lib64/libcutensor/11.0:/usr/lib64/libcutensor/12"

ENV PATH="${CUDA_HOME}/bin:${PATH}"
ENV LIBRARY_PATH="${CUDA_HOME}/lib64/stubs:${LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CUDA_HOME}/lib64"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CUDNN_LIB_DIR}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${NSIGHT_COMPUTE_HOME}/extras/python"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${NSIGHT_COMPUTE_HOME}/host/target-linux-x64"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${NSIGHT_COMPUTE_HOME}/target/linux-desktop-glibc_2_11_3-x64"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${NSIGHT_SYSTEMS_HOME}/host-linux-x64"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${TENSOR_LIB_DIRS}"

ENV NUMPY_LIBS="${VIRTUAL_ENV}/lib/${PYTHON}/site-packages/numpy.libs"
ENV PILLOW_LIBS="${VIRTUAL_ENV}/lib/${PYTHON}/site-packages/pillow.libs"

ENV SAMBA_LIBS="/usr/lib64/samba"
ENV SYSTEMD_LIBS="/usr/lib64/systemd"
ENV TORIO_LIBS="${VIRTUAL_ENV}/lib/${PYTHON}/site-packages/torio/lib"

ENV PYTORCH_HOME="${VIRTUAL_ENV}/lib64/${PYTHON}/site-packages/torch"
ENV PYTORCH_AUDIO_HOME="${VIRTUAL_ENV}/lib64/${PYTHON}/site-packages/torchaudio"
ENV PYTORCH_VISION_HOME="${VIRTUAL_ENV}/lib64/${PYTHON}/site-packages/torchvision"

ENV PATH="${OPENMPI_HOME}/bin:${CUDA_HOME}/bin:${INTEL_ONEAPI_MKL_HOME}/bin:${PYTORCH_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PYTORCH_HOME}/lib:${PYTORCH_AUDIO_HOME}/lib:${PYTORCH_VISION_HOME}"

ENV INTEL_ONEAPI_HOME="/opt/intel/oneapi"
ENV INTEL_ONEAPI_COMPILER_HOME="${INTEL_ONEAPI_HOME}/compiler/latest"
ENV INTEL_ONEAPI_MKL_HOME="${INTEL_ONEAPI_HOME}/mkl/latest"
ENV INTEL_ONEAPI_TBB_HOME="${INTEL_ONEAPI_HOME}/tbb/latest"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${INTEL_ONEAPI_COMPILER_HOME}/lib:${INTEL_ONEAPI_MKL_HOME}/lib:${INTEL_ONEAPI_TBB_HOME}/lib"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${NUMPY_LIBS}:${PILLOW_LIBS}"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${OPENMPI_HOME}/lib64:${SAMBA_LIBS}:${SYSTEMD_LIBS}:${TORIO_LIBS}"

ENV JUPYTER_PORT=8888
ENV TENSORBOARD_PORT=6006

WORKDIR /workspace
ENTRYPOINT ["/usr/bin/bash"]
