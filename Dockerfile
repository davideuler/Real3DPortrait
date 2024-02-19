FROM ubuntu22.04-cu118-conda:torch2.0.1-py39 

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "pytorch", "/bin/bash", "-c"]

RUN conda install conda-forge::ffmpeg # ffmpeg with libx264 codec to turn images to video

# Commented to avoid conflicts of conda packages and pip packages.
# torch2.0.1+cuda11.8 is recommended , cuda11.8 is compatible with RTX 4090.
# And torch=2.1+cuda12.1 will cause error of torch-ngp 
#RUN conda install pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch-cuda=11.8 -c pytorch -c nvidia

# Install from pytorch3d from conda (For fast installation, Linux only)
#RUN conda install pytorch3d::pytorch3d

# install mmcv by mim
RUN pip install --no-cache-dir -U chardet && \
    FORCE_CUDA=1 pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable" && \
    pip install --no-cache-dir -U cython && pip install --no-cache-dir -U openmim==0.3.9 && \ 
    mim install mmcv==2.1.0 

COPY . /workspace
WORKDIR /workspace

# other dependencies
RUN apt update -y && apt-get install -y libasound2-dev portaudio19-dev libgl1 && \
    pip install --no-cache-dir -U -r docs/prepare_env/requirements.txt && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

