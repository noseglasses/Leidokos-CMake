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
# If so, it is able to autodetect all necessary paths of the 
# Kaleidoscope firmware.
#
################################################################################
# Setup and variable definitions
################################################################################
# 
# The following definintions must occur before the toolchain
# file is included below, to make them visibile to Arduino-CMakes build
# system.
#
# Let the user choose a name of the keyboard a firmware is supposed to be 
# build for
#
set(KALEIDOSCOPE_KEYBOARD_HARDWARE "Model01" CACHE STRING
   "The type of the keyboard hardware. \
   Currently supported Model01, Raise, Shortcut")
   
# Based on the keyboard name, we set some alternative name string variables
# that are used in the configurations below
#
if("${KALEIDOSCOPE_KEYBOARD_HARDWARE}" STREQUAL "Model01")
   set(usb_product "Model 01")
   set(usb_manufacturer "Keyboardio")
   set(board "model01")
# **Note:** Define above variables for other keyboards accordingly 
# elseif("${KALEIDOSCOPE_KEYBOARD_HARDWARE}" STREQUAL "Raise")
# elseif("${KALEIDOSCOPE_KEYBOARD_HARDWARE}" STREQUAL "Shortcut")
else()
   message(FATAL_ERROR "Unknown KALEIDOSCOPE_KEYBOARD_HARDWARE=\"${KALEIDOSCOPE_KEYBOARD_HARDWARE}\"")
endif()

# Add some additional compiler command line flags that are needed
# to build Kaleidoscope.
#
set(ARDUINO_CXX_FLAGS 
   "\
-std=gnu++11 \
-DKALEIDOSCOPE_HARDWARE_H=\\\"Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}.h\\\" \
-DUSB_MANUFACTURER=\\\"${usb_manufacturer}\\\" \
\"-DUSB_PRODUCT=\\\"${usb_product}\\\"\" \
-Wall \
-Wextra \
-fno-threadsafe-statics"
)

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
   message(WARNING 
"Unable to determine keyboard device port. \
Is the keyboard actually connected?")
   set(device_port 10000)
endif()

# Try to find the hardware path,
#    i.e. the path that ends as ".../hardware/keyboardio"
#
# First we try, if the "Kaleidoscope-CMake" directory is below the directory
# we search for. As we do a string search in the path, we have to make sure 
# that any symbolic links and ".." are removed first.
#
get_filename_component(cmake_source_dir_realpath "${CMAKE_SOURCE_DIR}" REALPATH)
string(FIND "${cmake_source_dir_realpath}" 
   "hardware/keyboardio/avr" find_pos REVERSE)
   
# If the string is not found, string(FIND...) returns -1 in find_pos
#
if(find_pos GREATER -1)

   # The "Kaleidoscope-CMake" directory is obviously a subdirectory
   # of the directory we are looking for.

   # Get the start of the path up to the place where the search string was 
   # found
   #
   string(SUBSTRING "${cmake_source_dir_realpath}" 0 ${find_pos} 
      kaleidoscope_hardware_dir_guess)
   
   # Extend the path accordingly
   #
   set(kaleidoscope_hardware_dir_guess 
      "${kaleidoscope_hardware_dir_guess}/hardware/keyboardio")
#    message("kaleidoscope_hardware_dir_guess=${kaleidoscope_hardware_dir_guess}")
else()
   # We have no clue where to look for the hardware directory.
   #
   set(kaleidoscope_hardware_dir_guess "<undefined>")
endif()

# Make the hardware directory user configurable by defining a cache variable.
#
set(KALEIDOSCOPE_HARDWARE_DIR "${kaleidoscope_hardware_dir_guess}" 
   CACHE PATH "The path to the Kaleidoscope hardware directory")

if(NOT EXISTS "${KALEIDOSCOPE_HARDWARE_DIR}")
   message(FATAL_ERROR "Unable to find \
KALEIDOSCOPE_HARDWARE_DIR=${KALEIDOSCOPE_HARDWARE_DIR}")
endif()

set(kaleidoscope_lib_dir "${KALEIDOSCOPE_HARDWARE_DIR}/avr/libraries")

# Make the firmware sketch user configurable.
#
set(KALEIDOSCOPE_FIRMWARE_SKETCH 
   "${kaleidoscope_lib_dir}/${KALEIDOSCOPE_KEYBOARD_HARDWARE}-Firmware\
/${KALEIDOSCOPE_KEYBOARD_HARDWARE}-Firmware.ino"
   CACHE FILEPATH 
   "The path to the Kaleidoscope firmware sketch"
)

if(NOT EXISTS "${KALEIDOSCOPE_FIRMWARE_SKETCH}")
   message(FATAL_ERROR "Unable to find KALEIDOSCOPE_FIRMWARE_SKETCH=\"${KALEIDOSCOPE_FIRMWARE_SKETCH}\"")
endif()

# Make the programmer user configurable
#
set(programmers "avrisp;avrispmkii;usbtinyisp;parallel;arduinoisp")
set(KALEIDOSCOPE_ARDUINO_PROGRAMMER 
   "avrispmkii" CACHE STRING
   "The firmware programmer to use for flashing (available: ${programmers})"
)

set(programmer_ok FALSE)
foreach(programmer ${programmers})
   if("${KALEIDOSCOPE_ARDUINO_PROGRAMMER}" STREQUAL "${programmer}")
      set(programmer_ok TRUE)
      break()
   endif()
endforeach()
if(NOT programmer_ok)
   message(FATAL_ERROR "Please set KALEIDOSCOPE_ARDUINO_PROGRAMMER to one of the following: ${programmers}")
endif()

# Make sure that the correct avr-gcc of the arduino installation
# is found. To achieve this we add the path to the Arduino SDK to
# CMAKE_PREFIX_PATH, which is the path list that CMake uses to search for
# binaries, libraries, etc.
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

# kaleidoscope_firmware_target is used as identifier 
# for auto generated target names.
#
set(kaleidoscope_firmware_target "kaleidoscope.firmware")

# The toolchain file is used when the project is initialized using
# the project(...) directive further down.
#
set(CMAKE_TOOLCHAIN_FILE 
   "${CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/ArduinoToolchain.cmake")
   
# Uncomment this for detailed debugging of Arduino-CMake output.
#
# arduino_debug_on()

################################################################################
# Project generation
################################################################################

# Initialize the CMake project. This uses the CMAKE_TOOLCHAIN_FILE
# defined above.
#
project(Kaleidoscope)
cmake_minimum_required(VERSION 2.8)

# Allow the standard directory containing Kaleidoscope libraries
# to be found. Note: Arduino-CMake relies on this to be defined
# to search for Arduino libraries.
#
link_directories("${kaleidoscope_lib_dir}")

# Make sure that all Arduino library dirs are exported 
# as include (-I...) directories.
#
file(GLOB dirs "${kaleidoscope_lib_dir}/*")
foreach(dir ${dirs})
   include_directories("${dir}")
   include_directories("${dir}/src")
   include_directories("${dir}/src/Kaleidoscope")
endforeach()

# Defining KEYBOARDIO_CORES_PATH is necessary as
# hardware/keyboardio/avr does not come with a "cores"
# directory. This prevents other unrelated directories named 
# "cores" from being found, e.g. through paths in the users PATH variable.
#
# Note: By defining the cache variable INTERNAL, we prevent it from being
#       listed in configuration GUIs.
#
set(KEYBOARDIO_CORES_PATH "${ARDUINO_SDK_PATH}/hardware/arduino/avr/cores" 
   CACHE INTERNAL "")
   
# This registers our keyboard hardware with the Arduino-CMake 
# system. Necessary information is read from files in the Arduino conforming 
# directory structure available through KALEIDOSCOPE_HARDWARE_DIR.
#
register_hardware_platform("${KALEIDOSCOPE_HARDWARE_DIR}")

# Define some additional libraries' sources 
# that are not found by Arduino-CMake's library autodetection mechanism.
#
set(additional_libraries 
   "Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}"
   "KeyboardioScanner"
)

set(all_add_src)
foreach(add_lib ${additional_libraries})
   file(GLOB_RECURSE add_src "${kaleidoscope_lib_dir}/${add_lib}/*.cpp")
   list(APPEND all_add_src ${add_src})
endforeach()

# Prevent some of Arduino's standard libraries to be found. This
# is necessary as there is a Keyboard.h header in the Kaleidoscope
# project. Arduino-CMake searches for libraries with names equal
# to headers. If we would not blacklist such libraries, they
# would be build and linked and thus lead to ambiguously defined 
# symbols.
#
set(BLACKLISTED_ARDUINO_LIBS "${ARDUINO_SDK_PATH}/libraries/Keyboard/src")

generate_arduino_firmware(
   "${kaleidoscope_firmware_target}" # CMake target name
   BOARD "${board}"
   SKETCH "${KALEIDOSCOPE_FIRMWARE_SKETCH}"
   SRCS ${all_add_src}
   PORT "${device_port}"
   PROGRAMMER "${KALEIDOSCOPE_ARDUINO_PROGRAMMER}"
)

# Add a decompile (actual a disassembly) target
#
if(NOT AVROBJDUMP_PROGRAM)
   find_program(AVROBJDUMP_PROGRAM
            avr-objdump)
endif()

add_custom_target(
   decompile
   COMMAND "${AVROBJDUMP_PROGRAM}" -d "${kaleidoscope_firmware_target}.elf"
)

# Add a target that simplifies listing symbols.
#
if(NOT AVRNM_PROGRAM)
   find_program(AVRNM_PROGRAM
            nm)
endif()
add_custom_target(
   nm
   COMMAND "${AVRNM_PROGRAM}" -C "${kaleidoscope_firmware_target}.elf"
)