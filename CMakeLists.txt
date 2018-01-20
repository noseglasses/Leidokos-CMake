#  -*- mode: cmake -*-
# Leidokos-CMake -- An alternative build system that
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

# This is an alternative build system for the Kaleidoscope keyboard
# firmware.

# To enable Leidokos-CMake to be included in other 
# CMake projects' CMakeLists.txt files, we use LEIDOKOS_CMAKE_SOURCE_DIR
# instead of CMAKE_SOURCE_DIR. LEIDOKOS_CMAKE_SOURCE_DIR
# can be set by the including CMake code.
#
set(LEIDOKOS_CMAKE_SOURCE_DIR "${CMAKE_SOURCE_DIR}"
   CACHE INTERNAL "The path to the Leidokos-CMake sources. This is only \"
required to be set when Leidokos-CMake is wrapped \
by other CMake build systems.")

macro(_include_cmake file_basename_)
   include("${LEIDOKOS_CMAKE_SOURCE_DIR}/cmake/${file_basename_}.include.cmake")
endmacro()

message("1 WIN32=${WIN32}")

################################################################################
# General setup of the CMake build system
################################################################################

_include_cmake(cmake_system)

message("2 WIN32=${WIN32}")
################################################################################
# Setup the build system for builds that target Arduino platforms but
# also for host builds (virtual builds).
################################################################################

_include_cmake(cross_build)

message("3 WIN32=${WIN32}")
################################################################################
# Configure travis testing with Leidokos-CMake.
################################################################################

_include_cmake(travis)

message("4 WIN32=${WIN32}")
################################################################################
# Configure Arduino search paths and download Arduino if necessary.
################################################################################

_include_cmake(arduino)

message("5 WIN32=${WIN32}")
project(Kaleidoscope)
cmake_minimum_required(VERSION 2.8)

message("6 WIN32=${WIN32}")
################################################################################
# Configure the target platform hardware.
################################################################################

_include_cmake(platform)

message("7 WIN32=${WIN32}")
################################################################################
# Configure the device upload
################################################################################

_include_cmake(device_upload)

message("8 WIN32=${WIN32}")
################################################################################
# Setup Arduino-CMake
################################################################################

_include_cmake(arduino_cmake)
   
message("WIN32=${WIN32}")
################################################################################
# Configure the firmware build using Arduino-CMake
################################################################################

_include_cmake(firmware_build)
   
message("9 WIN32=${WIN32}")
################################################################################
# Additional targets for maintainance
################################################################################

_include_cmake(maintainance_targets)

message("10 WIN32=${WIN32}")
################################################################################
# Targets taken over from Kaleidoscopes main build system
################################################################################

_include_cmake(kaleidoscope_default_targets)
message("11 WIN32=${WIN32}")