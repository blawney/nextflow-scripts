From ubuntu:jammy

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
  apt-get install -y build-essential \
    wget \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libncurses-dev \
    libbz2-dev \
    liblzma-dev \
    libxml2-dev \
    libopenblas-dev \
    curl

# Install all software under /opt/software:
RUN mkdir -p /opt/software 
RUN mkdir -p /opt/software/scripts

# Get the minimamba installer script and run it in silent mode:
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

ADD conda-lock.yml /opt/software/
RUN micromamba install -y --channel=conda-forge --name=base conda-lock
RUN micromamba create -p /opt/software/deseq2_env --file /opt/software/conda-lock.yml

ENV PATH="/opt/software/deseq2_env/bin:${PATH}"

ADD deseq2.R /opt/software/scripts/