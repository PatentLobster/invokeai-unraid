FROM ubuntu:22.04
RUN apt-get update && apt-get install -y git wget dos2unix libgl1-mesa-glx libglib2.0-0 lshw
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b
RUN rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH /root/miniconda3/bin:$PATH
RUN conda update -n base -c defaults conda

WORKDIR     /

ADD /start.sh .
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]