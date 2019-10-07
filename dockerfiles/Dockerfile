FROM 4dndcic/ubuntu16.04-miniconda-python36:v1
MAINTAINER Tiziana Sanavia (tiziana.sanavia@gmail.com)

# general updates & installing necessary Linux components
RUN apt-get update && apt-get install -y \
nano

# BICseq2 normalization
ADD ./dockerfiles/NBICseq-norm_v0.2.4 /usr/local/bin/NBICseq-norm_v0.2.4
RUN cd NBICseq-norm_v0.2.4 && \
make clean && \
make

# BICseq2 segmentation 
ADD ./dockerfiles/NBICseq-seg_v0.7.2 /usr/local/bin/NBICseq-seg_v0.7.2
RUN cd NBICseq-seg_v0.7.2 && \
make clean && \
make

#ENV PATH=/usr/local/bin/NBICseq-norm_v0.2.4/:$PATH
#ENV PATH=/usr/local/bin/NBICseq-seg_v0.7.2/:$PATH

CMD ["bash"]
