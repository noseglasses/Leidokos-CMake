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

# Some targets require additional CMake scripts that enable using
# portable CMake code during the build stage.
#
set(cmake_scripts_dir "${CMAKE_BINARY_DIR}/cmake_scripts")
if(NOT EXISTS "${cmake_scripts_dir}")
   file(MAKE_DIRECTORY "${cmake_scripts_dir}")
endif()

if(WIN32)
   set(CMAKE_C_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
   set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
   set(CMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS 1)
   set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS 1)
   set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES 1)
   set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES 1)

   set(CMAKE_NINJA_FORCE_RESPONSE_FILE 1 CACHE INTERNAL "")

   set(CMAKE_C_RESPONSE_FILE_LINK_FLAG "@")
   set(CMAKE_CXX_RESPONSE_FILE_LINK_FLAG "@")
endif()