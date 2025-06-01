FROM ubuntu:jammy

RUN apt-get update && \
    apt-get install -y wget \
        python3-dev \
        python3-pip

RUN mkdir -p /opt/software

# Get latest STAR source from releases
RUN cd /opt/software && \
    wget https://github.com/alexdobin/STAR/archive/2.7.11a.tar.gz && \
    tar -xzf 2.7.11a.tar.gz

RUN pip3 install multiqc