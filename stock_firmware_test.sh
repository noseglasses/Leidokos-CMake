#!/bin/bash

TARGET_DIR=${PWD}

cd ${TARGET_DIR}
mkdir -p hardware/keyboardio

git clone --recursive https://github.com/keyboardio/Arduino-Boards.git \
    hardware/keyboardio/avr
    
cd hardware/keyboardio/avr/libraries

git clone --recursive https://github.com/noseglasses/Kaleidoscope-CMake.git

cd ${TARGET_DIR}

mkdir build
cd build

cmake ${TARGET_DIR}/hardware/keyboardio/avr/libraries/Kaleidoscope-CMake

make