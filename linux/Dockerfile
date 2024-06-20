FROM ubuntu:latest

RUN apt update && \
    apt install -y \
    libboost-dev \
    libboost-all-dev \
    git \
    curl \
    cmake \
    gcc g++ \
    python3-pip python3-venv 

RUN python3 -m venv .venv
COPY requirements-swmm.txt .

RUN . /.venv/bin/activate && pip install -r requirements-swmm.txt


ENTRYPOINT [ "/bin/bash" ]
