FROM ubuntu:jammy

RUN apt-get update && \
    apt-get install -y python3-dev \
        python3-pip

RUN mkdir -p /opt/software

RUN pip3 install pandas==2.1.3

ADD concat_star_quants.py /opt/software/