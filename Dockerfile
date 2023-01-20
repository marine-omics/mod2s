FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  time locales \
  build-essential unzip wget python3-pip python3-dev bwa \
  libncurses5-dev libbz2-dev liblzma-dev zlib1g zlib1g-dev pkg-config

WORKDIR /usr/local/

ENV LC_ALL C
ENV PATH=/usr/local/bin:$PATH

# samtools
ARG SAMTOOLSVER=1.16.1
RUN wget https://github.com/samtools/samtools/releases/download/${SAMTOOLSVER}/samtools-${SAMTOOLSVER}.tar.bz2 && \
 tar -xjf samtools-${SAMTOOLSVER}.tar.bz2 && \
 rm samtools-${SAMTOOLSVER}.tar.bz2 && \
 cd samtools-${SAMTOOLSVER} && \
 ./configure && \
 make && \
 make install && rm -rf /usr/local/samtools-1.16.1

RUN wget --no-check-certificate 'https://github.com/gmarcais/Jellyfish/releases/download/v2.3.0/jellyfish-2.3.0.tar.gz' && \
  tar -zxvf jellyfish-2.3.0.tar.gz && \
  cd jellyfish-2.3.0 && \
  ./configure --prefix=/usr/local && make && make install && \
  rm -rf jellyfish-2.3.0

RUN ldconfig /usr/local/lib

RUN python3 -m pip install d2ssect

RUN wget 'https://github.com/lh3/seqtk/archive/refs/tags/v1.3.tar.gz' && \
  tar -zxvf v1.3.tar.gz && \
  cd seqtk-1.3/ && \
  make && mv seqtk /usr/local/bin && \
  rm -rf seqtk-1.3/


# Cleanup apt package lists to save space
RUN rm -rf /var/lib/apt/lists/*

