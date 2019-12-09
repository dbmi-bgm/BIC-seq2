FROM 4dndcic/ubuntu16.04-miniconda-python36:v1

# 1. general updates & installing necessary Linux components
RUN apt-get update -y && apt-get install -y \
bzip2 \
gcc \
git \
less \
libncurses-dev \
make \
time \
unzip \
vim \
wget \
zlib1g-dev \
liblz4-tool \
libbz2-dev \
liblzma-dev \
locales \
parallel
