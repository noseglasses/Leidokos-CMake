#  -*- mode: cmake -*-
# Kaleidoscope-CMake -- An alternative build system that
#    enables building Kaleidoscope with CMake
# Copyright (C) 2017 noseglasses <shinynoseglasses@gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# This is an alternative build system for the Kaleidoscope keyboard
# firmware.
#
# This CMakeLists.txt file assumes, that the Kaleidoscope-CMake
# project is checked out in .../hardware/keyboardio/avr/libraries.
# 
# The following definintions must occur before the toolchain
# file is included below, to make them visibile to Arduino-CMakes build
# system.
#
set(KALEIDOSCOPE_KEYBOARD_HARDWARE "Model01" CACHE STRING
   "The type of the keyboard hardware. Currently supported Model01, Raise, Shortcut")

# TODO: Allow this to work for all devices using Kaleidoscope
#
set(ARDUINO_CXX_FLAGS "-std=gnu++11 -DKALEIDOSCOPE_HARDWARE_H=\\\"Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}.h\\\" -DUSB_MANUFACTURER=\\\"Keyboardio\\\" \"-DUSB_PRODUCT=\\\"Model 01\\\"\" -Wall -Wextra -fno-threadsafe-statics")

# The toolchain file is used when the project is initialized using\
# the project directive further down.
#
set(CMAKE_TOOLCHAIN_FILE 
   "${CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/ArduinoToolchain.cmake")

# Make sure that the correct avr-gcc of the arduino installation
# is found. 
#
# Note: To do this right the toolchain file would need to be modified
#       to use the actually determined ARDUINO_SDK_PATH to 
#       define CMAKE_PREFIX_PATH.
#
if(NOT "$ENV{ARDUINO_PATH}" STREQUAL "")
   set(CMAKE_PREFIX_PATH "$ENV{ARDUINO_PATH}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
elseif(NOT "$ENV{ARDUINO_SDK_PATH}" STREQUAL "")
   set(CMAKE_PREFIX_PATH "$ENV{ARDUINO_SDK_PATH}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
endif()

# Initialize the CMake project. This uses the CMAKE_TOOLCHAIN_FILE
# defined above.
#
project(Kaleidoscope)
cmake_minimum_required(VERSION 2.8)

# Determine the device port for flashing
# (taken over from keyboardio/avr/libraries/Kaleidoscope/etc/kaleidoscope-builder.conf)
#
if(APPLE)

   macro(get_device_port cmd_)
      if("${device_port}" STREQUAL "")
         execute_process(
            COMMAND ${cmd_}
            OUTPUT_VARIABLE device_port
         )
      endif()
   endmacro()
   
   get_device_port("ls /dev/cu.usbmodemCkbio*")
   get_device_port("ls /dev/cu.usbmodemCkbio*")
   get_device_port("ls /dev/cu.usbmodemHID*")
   get_device_port("ls /dev/cu.usbmodemCHID*")
   get_device_port("ls /dev/cu.usbmodem14*")

else()
   execute_process(
      COMMAND ls /dev/ttyACM*
      OUTPUT_VARIABLE device_port
   )
endif()

if("${device_port}" STREQUAL "")
   message(WARNING "Unable to determine keyboard device port. Is the keyboard actually connected?")
   set(device_port 10000)
endif()

# Enable this for detailed debugging of Arduino-CMake output.
#
# arduino_debug_on()

# Allow the standard directory containing Kaleidoscope libraries
# to be found. Note: Arduino-CMake relies on this to be defined
# to search for Arduino libraries.
#
link_directories("${CMAKE_SOURCE_DIR}/..")

get_filename_component(kaleidoscope_lib_dir "${CMAKE_SOURCE_DIR}" DIRECTORY)

# Add all Arduino library dirs as include (-I...) directories
#
file(GLOB dirs "${kaleidoscope_lib_dir}/*")
foreach(dir ${dirs})
   include_directories("${dir}")
   include_directories("${dir}/src")
   include_directories("${dir}/src/Kaleidoscope")
endforeach()

# Registers the keyboardio hardwares
#
get_filename_component(kaleidoscope_hardware_dir "${CMAKE_SOURCE_DIR}/../../../../keyboardio" REALPATH)

# Defining KEYBOARDIO_CORES_PATH is necessary as
# hardware/keyboardio/avr does not come with a cores
# directory. It prevents that other unrelated directories named 
# cores are found through paths in the users PATH variable.
#
set(KEYBOARDIO_CORES_PATH "${ARDUINO_SDK_PATH}/hardware/arduino/avr/cores" CACHE PATH "")
register_hardware_platform("${kaleidoscope_hardware_dir}")

# Define some additional libraries whose sources must be defined explicitly
# as they are not found by Arduino-CMake's library autodetection mechanism.
#
set(additional_libraries 
   "Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}"
   "KeyboardioScanner"
)

set(all_add_src)
foreach(add_lib ${additional_libraries})
   file(GLOB_RECURSE add_src "${kaleidoscope_lib_dir}/${add_lib}/*.cpp")
message("add_src: ${add_src}")
   list(APPEND all_add_src ${add_src})
endforeach()

message("all_add_src: ${all_add_src}")

# Prevent some of Arduino's standard libraries to be found. This
# is necessary as there is a Keyboard.h header in the Kaleidoscope
# project. Arduino-CMake searches for libraries with names equal
# to headers. If we would not blacklist such libraries, they
# would be build and linked and thus lead to ambiguously defined 
# symbols.
#
set(BLACKLISTED_ARDUINO_LIBS "${ARDUINO_SDK_PATH}/libraries/Keyboard")

generate_arduino_firmware(
   kaleidoscope.firmware # CMake target name
   BOARD model01
   SKETCH "${kaleidoscope_lib_dir}/Model01-Firmware/Model01-Firmware.ino"
   SRCS ${all_add_src}
   PORT "${device_port}"
   PROGRAMMER avrispmkii
)