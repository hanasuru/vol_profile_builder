#!/bin/bash
TARGET_OS=$1
KERNEL_VER=$2
OUTPUT="Ubuntu${TARGET_OS}-${KERNEL_VER}.zip"

if [ "$#" -ne 2 ]; then
    echo "Usage: ./build.sh os_version kernel_version"
else
    cat <<EOF > Dockerfile
    FROM ubuntu:20.04

    RUN apt update 
    RUN apt -y install linux-tools-5.4.0-42-generic
    RUN apt -y install linux-headers-5.4.0-42-generic
    RUN apt -y install linux-modules-5.4.0-42-generic
    RUN apt -y install zip git build-essential dwarfdump

    RUN git clone https://github.com/volatilityfoundation/volatility.git
    RUN sed -i 's/\$(shell uname -r)/"5.4.0-42-generic"/' volatility/tools/linux/Makefile
    RUN cd volatility/tools/linux/ && make
    RUN zip /Ubuntu20.04-5.4.0-42-generic.zip volatility/tools/linux/module.dwarf /boot/System.map-$KERNEL_VER
EOF

    sed -i "s/20.04/$TARGET_OS/g" Dockerfile
    sed -i "s/5.4.0-42-generic/$KERNEL_VER/" Dockerfile

    docker build -t volatility:$TARGET_OS .
    docker run --name profile volatility:$TARGET_OS
    docker cp profile:"/$OUTPUT" $OUTPUT
    docker rm profile
fi