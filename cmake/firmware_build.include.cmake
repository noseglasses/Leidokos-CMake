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

# kaleidoscope_firmware_target is used as identifier 
# for auto generated target names.
#
set(kaleidoscope_firmware_target "kaleidoscope.firmware")

# Uncomment this for detailed debugging of Arduino-CMake output.
#
# arduino_debug_on()

# Allow the standard directory containing Kaleidoscope libraries
# to be found. Note: Arduino-CMake relies on this to be defined
# to search for Arduino libraries.
#
link_directories("${KALEIDOSCOPE_LIBRARIES_DIR}")

include_directories("${KALEIDOSCOPE_LIBRARIES_DIR}/Kaleidoscope-Hardware-${product_id}/src")

# Defining ${vendor_id_upper}_CORES_PATH is necessary as
# hardware/${KALEIDOSCOPE_VENDOR_ID}/${KALEIDOSCOPE_ARCHITECTURE_ID} does not always come with a "cores"
# directory. This prevents other unrelated directories named 
# "cores" from being found, e.g. through paths in the users PATH variable.
#
# Note: By defining the cache variable INTERNAL, we prevent it from being
#       listed in configuration GUIs.
#
string(TOUPPER "${KALEIDOSCOPE_VENDOR_ID}" vendor_id_upper)
set(${vendor_id_upper}_CORES_PATH "${ARDUINO_SDK_PATH}/hardware/arduino/${KALEIDOSCOPE_ARCHITECTURE_ID}/cores" 
   CACHE INTERNAL "")

# Define some additional libraries' sources 
# that are not found by Arduino-CMake's library autodetection mechanism.
#
set(all_add_src)
foreach(add_lib ${platform_additional_libraries})
   file(GLOB_RECURSE add_src "${KALEIDOSCOPE_LIBRARIES_DIR}/${add_lib}/*.cpp")
   list(APPEND all_add_src ${add_src})
   include_directories("${KALEIDOSCOPE_LIBRARIES_DIR}/${add_lib}/src")
endforeach()

set(KALEIDOSCOPE_ADDITIONAL_SOURCES "" CACHE STRING
   "A list of absolute paths of source files that are included in the \
firmware build. This is only required for advanced use, e.g. when \
Leidokos-CMake is embedded in another CMake build system.")
mark_as_advanced(KALEIDOSCOPE_ADDITIONAL_SOURCES)

if(NOT "${KALEIDOSCOPE_ADDITIONAL_SOURCES}" STREQUAL "")
   list(APPEND all_add_src ${KALEIDOSCOPE_ADDITIONAL_SOURCES})
endif()

list(APPEND all_add_src ${modules_additional_sources})

set(KALEIDOSCOPE_ADDITIONAL_HEADERS "" CACHE STRING
   "A list of absolute paths of header files that are included in the \
firmware build. This is only required for advanced use, e.g. when \
Leidokos-CMake is embedded in another CMake build system.")
mark_as_advanced(KALEIDOSCOPE_ADDITIONAL_HEADERS)

set(all_headers "HDRS")
if(NOT "${KALEIDOSCOPE_ADDITIONAL_HEADERS}" STREQUAL "")
   list(APPEND all_headers ${KALEIDOSCOPE_ADDITIONAL_HEADERS} ${module_additional_headers})
endif()

list(APPEND all_headers ${modules_additional_headers})

if("${all_headers}" STREQUAL "HDRS")
   set(all_headers "")
endif()
message("all_headers: ${all_headers}")

# Prevent some of Arduino's standard libraries to be found. This
# is necessary as there is a Keyboard.h header in the Kaleidoscope
# project. Arduino-CMake searches for libraries with names equal
# to headers. If we would not blacklist such libraries, they
# would be build and linked and thus lead to ambiguously defined 
# symbols.
#
file(TO_CMAKE_PATH "${ARDUINO_SDK_PATH}" ARDUINO_SDK_PATH_native)
set(ARDUINO_LIBRARY_BLACKLIST 
   "\
${ARDUINO_SDK_PATH_native}/libraries/Keyboard/src;\
${ARDUINO_SDK_PATH_native}/libraries/Mouse/src;\
${ARDUINO_SDK_PATH}/libraries/Keyboard/src;\
${ARDUINO_SDK_PATH}/libraries/Mouse/src;\
${blacklisted_libraries}\
"
   CACHE INTERNAL "")

generate_arduino_firmware(
   "${kaleidoscope_firmware_target}" # CMake target name
   BOARD "${board_id}"
   SKETCH "${KALEIDOSCOPE_FIRMWARE_SKETCH}"
   ${all_headers}
   SRCS ${all_add_src}
   PORT "${device_port}"
   PROGRAMMER "${KALEIDOSCOPE_ARDUINO_PROGRAMMER}"
)

# The configure_firmware_target function can be defined in custom
# hardware files in hardware/... subdirectories of this project
#
if(COMMAND configure_firmware_target)
   configure_firmware_target("${kaleidoscope_firmware_target}")
endif()

# Allow to assign an alternative filename for the output file
#
if(COMMAND kaleidoscope_set_binary_basename_hook)
   kaleidoscope_set_binary_basename_hook(binary_basename_default)
endif()
set(KALEIDOSCOPE_BINARY_BASENAME "${binary_basename_default}" CACHE STRING 
   "An alternative name for the generated firmware binary. The default name is used if empty.")
mark_as_advanced(KALEIDOSCOPE_BINARY_BASENAME)
   
string(TOUPPER "${product_id}" product_id_upper)
#target_compile_definitions("${kaleidoscope_firmware_target}" PUBLIC "-DARDUINO_AVR_${product_id_upper}")
add_definitions("-DARDUINO_AVR_${product_id_upper}")
   
if(NOT "${KALEIDOSCOPE_BINARY_BASENAME}" STREQUAL "")
   set_target_properties("${kaleidoscope_firmware_target}" 
      PROPERTIES OUTPUT_NAME "${KALEIDOSCOPE_BINARY_BASENAME}")
   set_target_properties("${kaleidoscope_firmware_target}" PROPERTIES PREFIX "")
   set_target_properties("${kaleidoscope_firmware_target}" PROPERTIES SUFFIX "")
endif()
