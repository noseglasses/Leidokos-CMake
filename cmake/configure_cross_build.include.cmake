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
if(NOT KALEIDOSCOPE_HOST_BUILD)
   set(CMAKE_TOOLCHAIN_FILE 
      "${KALEIDOSCOPE_CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/ArduinoToolchain.cmake")

   # Add some additional compiler command line flags that are needed
   # to build Kaleidoscope.
   #
   set(ARDUINO_CXX_FLAGS 
      "\
   -std=gnu++11 \
   -Wall \
   -Wextra \
   -fno-threadsafe-statics \
   -fno-exceptions \
   -ffunction-sections \
   -fdata-sections\
   ")
else()

   # Define empty flags. Else Arduino-CMake will define something Arduino
   # specific, which we have to avoid for host builds.
   #
   set(ARDUINO_C_FLAGS "")
   set(ARDUINO_CXX_FLAGS "\
   -std=gnu++11 \
   -Wall \
   -Wextra \
   -DARDUINO_VIRTUAL\
   ")
   
   set(ARDUINO_LIBRARIES_PATH "___dummy__")
   
   # Include Arduino.cmake directly to avoid Arduino toolchain setup as
   # it would be performed through defining CMAKE_TOOLCHAIN_FILE
   # as done in the platform build setup above.
   #
   include("${KALEIDOSCOPE_CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/Platform/Arduino.cmake")
endif()