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

# This function tries to find the hardware base path,
#    i.e. the path that ends as ".../hardware"
#
function(find_hardware_base_path__
   test_dir_
   base_dir_var_
   vendor_id_var_
   architecture_id_var_
)
   # First we try, if the "Kaleidoscope-CMake" directory is below the directory
   # we search for. As we do a string search in the path, we have to make sure 
   # that any symbolic links and ".." are removed first.
   #
   get_filename_component(cmake_source_dir_realpath "${KALEIDOSCOPE_CMAKE_SOURCE_DIR}" REALPATH)
   string(FIND "${cmake_source_dir_realpath}" 
      "/hardware/" find_pos REVERSE)
      
   # If the string is not found, string(FIND...) returns -1 in find_pos
   #
   if(find_pos GREATER -1)

      # The "Kaleidoscope-CMake" directory is obviously a subdirectory
      # of the directory we are looking for.
      
      math(EXPR find_pos "${find_pos} + 9")

      # Get the start of the path up to the place where the search string was 
      # found
      #
      string(SUBSTRING "${cmake_source_dir_realpath}" 0 ${find_pos} 
         base_dir)
         
      string(SUBSTRING "${cmake_source_dir_realpath}" ${find_pos} -1
         path_remainder)
      
      if("${path_remainder}" MATCHES "/([^/]*)/.*")
         set(default_vendor_id "${CMAKE_MATCH_1}")
      endif()
      
      if("${path_remainder}" MATCHES "/[^/]*/([a-zA-Z0-9_]*)/.*")
         set(default_architecture_id "${CMAKE_MATCH_1}")
      endif()
      
      set(${base_dir_var_} "${base_dir}" PARENT_SCOPE)
      set(${vendor_id_var_} "${default_vendor_id}" PARENT_SCOPE)
      set(${architecture_id_var_} "${default_architecture_id}" PARENT_SCOPE)
   
      return()
   endif()
   
   set(${base_dir_var_} "" PARENT_SCOPE)
   set(${vendor_id_var_} "" PARENT_SCOPE)
   set(${architecture_id_var_} "" PARENT_SCOPE)
endfunction()

macro(find_hardware_base_path
   path_list_
)
   foreach(path ${path_list_})
      find_hardware_base_path__(
         "${path}"
         default_hardware_base_path
         default_vendor_id
         default_architecture_id
      )
      if(default_hardware_base_path)
         break()
      endif()
   endforeach()
endmacro()

# Both the binary and the source tree could be below
# a hardware directory.
#
get_filename_component(below_libs_directory "${CMAKE_SOURCE_DIR}" PATH)
find_hardware_base_path("${CMAKE_BINARY_DIR};${below_libs_directory}")#;${KALEIDOSCOPE_CMAKE_SOURCE_DIR}")

if(NOT default_hardware_base_path)

   # We have no clue where to look for the hardware directory.
   #
   set(default_hardware_base_path "<undefined>")
   set(default_vendor_id "<undefined>")
   set(default_architecture_id  "<undefined>")
endif()

# Make the hardware base directory, the vendor id and the architecture id
# user configurable through a CMake cache variable.
#
set(KALEIDOSCOPE_HARDWARE_BASE_PATH "${default_hardware_base_path}" 
   CACHE PATH "The path to the Kaleidoscope hardware base directory.")
   
set(KALEIDOSCOPE_VENDOR_ID "${default_vendor_id}" 
   CACHE STRING "The vendor id of the board to build a firmware for.")

set(KALEIDOSCOPE_ARCHITECTURE_ID "${default_architecture_id}"
   CACHE STRING "The architecture id of the board to build a firmware for.")

if(NOT EXISTS "${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
   message(FATAL_ERROR "Unable to find \
KALEIDOSCOPE_HARDWARE_BASE_PATH=${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
endif()

if(COMMAND kaleidoscope_cmake_after_configure_platform_hook)
   kaleidoscope_cmake_after_configure_platform_hook()
endif()

# Check the platform directory's validity

set(kaleidoscope_platform_dir 
   "${KALEIDOSCOPE_HARDWARE_BASE_PATH}/${KALEIDOSCOPE_VENDOR_ID}/${KALEIDOSCOPE_ARCHITECTURE_ID}")

if(NOT EXISTS "${kaleidoscope_platform_dir}")
   message(SEND_ERROR "Unable to find platform directory \"${kaleidoscope_platform_dir}\"")
   message(SEND_ERROR "The following CMake variables are related:")
   message(SEND_ERROR "   KALEIDOSCOPE_HARDWARE_BASE_PATH = ${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
   message(SEND_ERROR "   KALEIDOSCOPE_VENDOR_ID = ${KALEIDOSCOPE_VENDOR_ID}")
   message(SEND_ERROR "   KALEIDOSCOPE_ARCHITECTURE_ID = ${KALEIDOSCOPE_ARCHITECTURE_ID}")
   message(FATAL_ERROR "Aborting.")
endif()

set(KALEIDOSCOPE_LIBRARIES_DIR "${kaleidoscope_platform_dir}/libraries" CACHE PATH 
   "A path to the libraries directory where the Kaleidoscope libraries live.")
   
# This registers our keyboard hardware with the Arduino-CMake 
# system. Necessary information is read from files in the Arduino conforming 
# directory structure available through kaleidoscope_vendor_dir.
#
message("Registering new hardware in \"${KALEIDOSCOPE_HARDWARE_BASE_PATH}/\
${KALEIDOSCOPE_VENDOR_ID}/${KALEIDOSCOPE_ARCHITECTURE_ID}")

register_hardware_platform_bva(
   "${KALEIDOSCOPE_HARDWARE_BASE_PATH}"
   "${KALEIDOSCOPE_VENDOR_ID}"
   "${KALEIDOSCOPE_ARCHITECTURE_ID}"
)

string(TOUPPER "${KALEIDOSCOPE_VENDOR_ID}" vendor_id_upper)

# Generate a default name for the board setting
#
# Allow for the BOARD env variable to be captured
# to achieve similar behavior as with Kaleidoscope's own
# build system
#
if(NOT "$ENV{BOARD}" STREQUAL "")
   set(default_board "$ENV{BOARD}")
else()
#    list(LENGTH ${vendor_id_upper}_BOARDS n_boards_found)
#    if(n_boards_found GREATER 0)
#       list(GET ${vendor_id_upper}_BOARDS 0 default_board)
#    endif()
   set(default_board "model01")
endif()

# Let the user choose a name of the target arduino board
#
set(KALEIDOSCOPE_BOARD "${default_board}" CACHE STRING
   "The type of board hardware. \
   Currently supported: ${${vendor_id_upper}_BOARDS} .")
   
# Based on the keyboard name, we set some alternative name string variables
# that are used in the configurations below
#
set(hardware_definition_file "${KALEIDOSCOPE_CMAKE_SOURCE_DIR}/hardware/${KALEIDOSCOPE_VENDOR_ID}/${KALEIDOSCOPE_ARCHITECTURE_ID}/${KALEIDOSCOPE_BOARD}.cmake")

if(NOT EXISTS "${hardware_definition_file}")
   message(FATAL_ERROR "Unnable to find hardware definition file \"${hardware_definition_file}\" for \
KALEIDOSCOPE_BOARD=${KALEIDOSCOPE_BOARD}")
else()
   include("${hardware_definition_file}")
endif()

# Make the firmware sketch user configurable.
#
set(KALEIDOSCOPE_FIRMWARE_SKETCH 
   "${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware\
/${product_id}-Firmware.ino"
   CACHE FILEPATH 
   "The path to the Kaleidoscope firmware sketch"
)

if(NOT EXISTS "${KALEIDOSCOPE_FIRMWARE_SKETCH}")
   message(FATAL_ERROR "Unable to find KALEIDOSCOPE_FIRMWARE_SKETCH=\"${KALEIDOSCOPE_FIRMWARE_SKETCH}\"")
endif()