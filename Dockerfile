ARG CUDA_VERSION="11.8.0"
ARG CUDNN_VERSION="8"
ARG UBUNTU_VERSION="22.04"

# Base NVidia CUDA Ubuntu image
FROM nvidia/cuda:$CUDA_VERSION-cudnn$CUDNN_VERSION-devel-ubuntu$UBUNTU_VERSION AS base

ENV HOME /root
WORKDIR $HOME
ENV PYTHON_VERSION=3.9.18
ENV PATH="/usr/local/cuda/bin:${PATH}"
#
# Install Python plus openssh, which is our minimum set of required packages.
# Install useful command line utility software
ARG APTPKGS="zsh wget tmux tldr nvtop vim neovim curl rsync net-tools less iputils-ping 7zip zip unzip"
RUN apt-get update -y && \
    apt-get install -y python3 python3-pip python3-venv libasound2-dev portaudio19-dev libgl1 && \
    apt-get install -y --no-install-recommends openssh-server openssh-client git git-lfs && \
    python3 -m pip install --upgrade pip && \
    apt-get install -y --no-install-recommends $APTPKGS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda for Python env management
ENV PATH="${HOME}/miniconda3/bin:${PATH}"
ENV BASEPATH="${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir ${HOME}/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b -p ${HOME}/miniconda3 \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

# Make base conda environment
ENV CONDA=pytorch
RUN conda create -n "${CONDA}" python="${PYTHON_VERSION}"
ENV PATH="${HOME}/miniconda3/envs/${CONDA}/bin:${BASEPATH}"

# Set up git to support LFS, and to store credentials; useful for Huggingface Hub
RUN git config --global credential.helper store && \
    git lfs install

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "pytorch", "/bin/bash", "-c"]

RUN conda install conda-forge::ffmpeg # ffmpeg with libx264 codec to turn images to video

# should install torch, and pytorch3d by conda, there is problems when installing pytorch3d by pip
# torch2.0.1+cuda11.8 is recommended , cuda11.8 is compatible with RTX 4090.
# And torch=2.1+cuda12.1 will cause error of torch-ngp 
RUN conda install pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch3d pytorch-cuda=11.8 -c pytorch -c nvidia

# install mmcv by mim
RUN pip install --no-cache-dir -U chardet cython openmim==0.3.9 && \ 
    mim install mmcv==2.1.0 

COPY . /workspace
WORKDIR /workspace

# other dependencies
RUN pip install --no-cache-dir -U -r docs/prepare_env/requirements.txt 

CMD [ "tail -f /dev/null" ]
