FROM ubuntu:22.04 as minimal

ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

COPY entrypoint.sh /app/entrypoint.sh

RUN apt update

# Install AUTOMATIC1111 pre-requisites
RUN apt update && \
    apt install -y \
    cmake \
    rustc \
    git-all \
    wget \
    apt-utils \
    jq

RUN apt -y autoremove && apt autoclean

# Install Python pre-requisites, including Python 3.x
# Google perftools includes TCMalloc, which helps with CPU memory usage
RUN apt-get install -y \
    software-properties-common \
    python3 \
    python3-pip \
    python3-ipykernel \
    libopencv-dev \
    python3-opencv \
    python3.10-venv \
    google-perftools \
    sudo

RUN apt -y autoremove && apt autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1000 sdgroup && \
    useradd -m -s /bin/bash -u 1000 -g 1000 --home /app sduser && \
    ln -s /app /home/sduser && \
    chown -R sduser:sdgroup /app && \
    chmod +x /app/entrypoint.sh

USER sduser
WORKDIR /app

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui stable-diffusion-webui && \
    cd stable-diffusion-webui && \
    ./webui.sh -h

WORKDIR /app/stable-diffusion-webui
VOLUME /app/stable-diffusion-webui/extensions
VOLUME /app/stable-diffusion-webui/textual_inversion_templates
VOLUME /app/stable-diffusion-webui/embeddings
VOLUME /app/stable-diffusion-webui/inputs
VOLUME /app/stable-diffusion-webui/models
VOLUME /app/stable-diffusion-webui/outputs
VOLUME /app/stable-diffusion-webui/localizations

EXPOSE 8080

#ENV PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

ENTRYPOINT ["/app/entrypoint.sh", "--update-check", "--xformers", "--listen", "--port", "8080"]


FROM minimal as full

RUN cd /app/stable-diffusion-webui && \
    touch install.log && \
    timeout 2h bash -c "./webui.sh --skip-torch-cuda-test --no-download-sd-model --exit"