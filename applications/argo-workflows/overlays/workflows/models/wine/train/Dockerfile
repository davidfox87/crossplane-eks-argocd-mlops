FROM python:3.9-slim as builder

# copy requirements.txt into /app working dir
COPY requirements.txt requirements.txt 

# install python packages
RUN pip3 install --user -r requirements.txt

# second unnamed stage
FROM python:3.9-slim

RUN apt-get update && apt-get install -y git \
        && apt-get clean

# copy only the dependencies installation from the 1st stage image
COPY --from=builder /root/.local /root/.local

# copy source files into /app working dir
COPY ./src /opt/workdir
WORKDIR /opt/workdir

# update PATH environment variable
ENV PATH=/root/.local:$PATH


