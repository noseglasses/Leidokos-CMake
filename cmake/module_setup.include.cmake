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

file(GLOB dir_entries "${KALEIDOSCOPE_PLATFORM_LIBRARIES_PATH}")

set(module_blacklist
   "Leidokos-CMake")

foreach(dir_entry ${dir_entries})

   if(NOT IS_DIRECTORY "${dir_entry}")
      continue()
   endif()
   
   set(cmake_lists_file "${dir_entry}/CMakeLists.txt")
   
   if(NOT EXISTS "${cmake_lists_file}")
      continue()
   endif()
   
   get_filename_component(basename "${dir_entry}" NAME)
   
   list(FIND module_blacklist "${basename}" _index)
   if (${_index} GREATER -1)
      continue()
   endif()
   
   message("Configuring module ${basename}")
   
   set(build_dir "${dir_entry}/module_build")
   
   file(MAKE_DIRECTORY "${build_dir}")
   
   # Configure the module
   #
   execute_process(
      COMMAND "${CMAKE_COMMAND}"
         "-DKALEIDOSCOPE_LIBRARIES_DIR=${KALEIDOSCOPE_LIBRARIES_DIR}"
         "-DKALEIDOSCOPE_FIRMWARE_SKETCH=${KALEIDOSCOPE_FIRMWARE_SKETCH}"
         "${dir_entry}"
      WORKING_DIRECTORY "${build_dir}"
   )
   
   # Build the module
   #
   execute_process(
      COMMAND "${CMAKE_COMMAND}" --build .
      WORKING_DIRECTORY "${build_dir}"
   )
endforeach()
