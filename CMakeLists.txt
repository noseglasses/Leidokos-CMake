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
# project is checked out in .../hardware/<vendor_id>/<architecture_id>/libraries.
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

# Tries to find the hardware base path,
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
   get_filename_component(cmake_source_dir_realpath "${CMAKE_SOURCE_DIR}" REALPATH)
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
         set(vendor_id "${CMAKE_MATCH_1}")
      endif()
      
      if("${path_remainder}" MATCHES "/[^/]*/([a-zA-Z0-9_]*)/.*")
         set(architecture_id "${CMAKE_MATCH_1}")
      endif()
      
      set(${base_dir_var_} "${base_dir}" PARENT_SCOPE)
      set(${vendor_id_var_} "${vendor_id}" PARENT_SCOPE)
      set(${architecture_id_var_} "${architecture_id}" PARENT_SCOPE)
   
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
         hardware_base_path
         vendor_id
         architecture_id
      )
      if(hardware_base_path)
         break()
      endif()
   endforeach()
endmacro()

find_hardware_base_path("${CMAKE_BINARY_DIR};${CMAKE_SOURCE_DIR}")

if(NOT hardware_base_path)

   # We have no clue where to look for the hardware directory.
   #
   set(hardware_base_path "<undefined>")
   set(vendor_id "<undefined>")
   set(architecture_id  "<undefined>")
endif()

message("hardware_base_path: ${hardware_base_path}")
message("vendor_id: ${vendor_id}")
message("architecture_id: ${architecture_id}")

# Make the hardware directory user configurable by defining a cache variable.
#
set(KALEIDOSCOPE_HARDWARE_BASE_PATH "${hardware_base_path}" 
   CACHE PATH "The path to the Kaleidoscope hardware base directory")
   
set(KALEIDOSCOPE_VENDOR_ID "${vendor_id}" 
   CACHE STRING "The vendor id of the board to build a firmware for")

set(KALEIDOSCOPE_ARCHITECTURE_ID "${architecture_id}"
   CACHE STRING "The architecture id of the board to build a firmware for")

if(NOT EXISTS "${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
   message(FATAL_ERROR "Unable to find \
KALEIDOSCOPE_HARDWARE_BASE_PATH=${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
endif()

set(kaleidoscope_platform_dir "${KALEIDOSCOPE_HARDWARE_BASE_PATH}/${KALEIDOSCOPE_VENDOR_ID}/${KALEIDOSCOPE_ARCHITECTURE_ID}")

if(NOT EXISTS "${kaleidoscope_platform_dir}")
   message(SEND_ERROR "Unable to find platform directory \"${kaleidoscope_platform_dir}\"")
   message(SEND_ERROR "The following CMake variables are related:")
   message(SEND_ERROR "   KALEIDOSCOPE_HARDWARE_BASE_PATH = ${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
   message(SEND_ERROR "   KALEIDOSCOPE_VENDOR_ID = ${KALEIDOSCOPE_VENDOR_ID}")
   message(SEND_ERROR "   KALEIDOSCOPE_ARCHITECTURE_ID = ${KALEIDOSCOPE_ARCHITECTURE_ID}")
   message(FATAL_ERROR "Aborting.")
endif()

set(kaleidoscope_lib_dir "${kaleidoscope_platform_dir}/libraries")

# Let the user choose a name of the keyboard a firmware is supposed to be 
# build for
#
set(KALEIDOSCOPE_KEYBOARD_HARDWARE "model01" CACHE STRING
   "The type of the keyboard hardware. \
   Currently supported model01, raise, shortcut")
   
# Based on the keyboard name, we set some alternative name string variables
# that are used in the configurations below
#
set(hardware_definition_file "${CMAKE_SOURCE_DIR}/hardware/${vendor_id}/${architecture_id}/${KALEIDOSCOPE_KEYBOARD_HARDWARE}.cmake")
if(NOT EXISTS "${hardware_definition_file}")
   message(FATAL_ERROR "Unnable to find hardware definition file \"${hardware_definition_file}\" for \
KALEIDOSCOPE_KEYBOARD_HARDWARE=${KALEIDOSCOPE_KEYBOARD_HARDWARE}")
else()
   include("${hardware_definition_file}")
endif()

# Add some additional compiler command line flags that are needed
# to build Kaleidoscope.
#
set(ARDUINO_CXX_FLAGS 
   "\
-std=gnu++11 \
-DKALEIDOSCOPE_HARDWARE_H=\\\"Kaleidoscope-Hardware-${product_id}.h\\\" \
-DUSB_MANUFACTURER=\\\"${usb_manufacturer}\\\" \
\"-DUSB_PRODUCT=\\\"${usb_product}\\\"\" \
-Wall \
-Wextra \
-fno-threadsafe-statics \
-fno-exceptions \
-ffunction-sections \
-fdata-sections\
")

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

# Make the firmware sketch user configurable.
#
set(KALEIDOSCOPE_FIRMWARE_SKETCH 
   "${kaleidoscope_lib_dir}/${product_id}-Firmware\
/${product_id}-Firmware.ino"
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

# Travis testing settings
#
set(travis_arduino "arduino-1.8.2")
set(travis_arduino_file "${travis_arduino}-linux64.tar.xz")
set(travis_arduino_path "${CMAKE_BINARY_DIR}/${travis_arduino}")
set(travis_arduino_download_url "http://downloads.arduino.cc/${travis_arduino_file}")

# Some targets require additional CMake scripts that enable using
# portable CMake code during the build stage.
#
set(cmake_scripts_dir "${CMAKE_BINARY_DIR}/cmake_scripts")
if(NOT EXISTS "${cmake_scripts_dir}")
   file(MAKE_DIRECTORY "${cmake_scripts_dir}")
endif()

set(KALEIDOSCOPE_DOWNLOAD_ARDUINO FALSE CACHE BOOL "If this flag is \
enabled, the build system downloads Arduino")

if(KALEIDOSCOPE_DOWNLOAD_ARDUINO)

   if(NOT EXISTS "${travis_arduino_path}")
      message("Installing Arduino...")
      file(DOWNLOAD "${travis_arduino_download_url}" "${CMAKE_BINARY_DIR}/${travis_arduino_file}" SHOW_PROGRESS)
      execute_process(
         COMMAND "${CMAKE_COMMAND}" -E tar xvf "${CMAKE_BINARY_DIR}/${travis_arduino_file}"
      )
   endif()
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
if(KALEIDOSCOPE_DOWNLOAD_ARDUINO)
   set(CMAKE_PREFIX_PATH "${travis_arduino_path}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
elseif(NOT "$ENV{ARDUINO_PATH}" STREQUAL "")
   set(CMAKE_PREFIX_PATH "$ENV{ARDUINO_PATH}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
elseif(NOT "$ENV{ARDUINO_SDK_PATH}" STREQUAL "")
   set(CMAKE_PREFIX_PATH "$ENV{ARDUINO_SDK_PATH}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
endif()

# kaleidoscope_firmware_target is used as identifier 
# for auto generated target names.
#
set(kaleidoscope_firmware_target "kaleidoscope.firmware")

set(ARDUINO_CMAKE_RECURSION_DEFAULT TRUE CACHE INTERNAL "")

# The toolchain file is used when the project is initialized using
# the project(...) directive further down.
#
set(CMAKE_TOOLCHAIN_FILE 
   "${CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/ArduinoToolchain.cmake")

################################################################################
# Project generation
################################################################################

# Initialize the CMake project. This uses the CMAKE_TOOLCHAIN_FILE
# defined above.
#
project(Kaleidoscope)
cmake_minimum_required(VERSION 2.8)

# Uncomment this for detailed debugging of Arduino-CMake output.
#
# arduino_debug_on()

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

# Defining ${vendor_id_upper}_CORES_PATH is necessary as
# hardware/${vendor_id}/${architecture_id} does not always come with a "cores"
# directory. This prevents other unrelated directories named 
# "cores" from being found, e.g. through paths in the users PATH variable.
#
# Note: By defining the cache variable INTERNAL, we prevent it from being
#       listed in configuration GUIs.
#
string(TOUPPER "${vendor_id}" vendor_id_upper)
set(${vendor_id_upper}_CORES_PATH "${ARDUINO_SDK_PATH}/hardware/arduino/${architecture_id}/cores" 
   CACHE INTERNAL "")
   
# This registers our keyboard hardware with the Arduino-CMake 
# system. Necessary information is read from files in the Arduino conforming 
# directory structure available through kaleidoscope_vendor_dir.
#
register_hardware_platform_bva(
   "${KALEIDOSCOPE_HARDWARE_BASE_PATH}"
   "${KALEIDOSCOPE_VENDOR_ID}"
   "${KALEIDOSCOPE_ARCHITECTURE_ID}"
)

# Define some additional libraries' sources 
# that are not found by Arduino-CMake's library autodetection mechanism.
#
set(additional_libraries 
   "Kaleidoscope-Hardware-${product_id}"
   ${platform_additional_libraries}
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
set(ARDUINO_CMAKE_BLACKLISTED_ARDUINO_LIBS 
   "\
${ARDUINO_SDK_PATH}/libraries/Keyboard/src;\
${ARDUINO_SDK_PATH}/libraries/Mouse/src"
   CACHE INTERNAL "")

generate_arduino_firmware(
   "${kaleidoscope_firmware_target}" # CMake target name
   BOARD "${board}"
   SKETCH "${KALEIDOSCOPE_FIRMWARE_SKETCH}"
   SRCS ${all_add_src}
   PORT "${device_port}"
   PROGRAMMER "${KALEIDOSCOPE_ARDUINO_PROGRAMMER}"
)

################################################################################
# Additional targets for maintainance
################################################################################

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

add_custom_target(
   disassembly
   COMMAND "${AVROBJDUMP_PROGRAM}" -d "${kaleidoscope_firmware_target}.elf"
)

# Add a target that simplifies listing symbols.
#
if(NOT AVRNM_PROGRAM)
   find_program(AVRNM_PROGRAM
            avr-nm)
endif()
add_custom_target(
   nm
   COMMAND "${AVRNM_PROGRAM}" -C "${kaleidoscope_firmware_target}.elf"
)

################################################################################
# Targets taken over from Kaleidoscopes main build system
################################################################################

set(plugin_test_support_dir "${kaleidoscope_platform_dir}/build-tools")
set(plugin_test_bin_dir "${plugin_test_support_dir}/x86_64/bin")

# Add a custom target for the astyle teste
#
add_custom_target(
   astyle
   COMMAND "${plugin_test_support_dir}/run-astyle"
)

# set(travis_install_arduino_script "${cmake_scripts_dir}/travis_install_arduino.script.cmake")
# 
# file(WRITE "${travis_install_arduino_script}"
# "\
# if(NOT EXISTS \"${travis_arduino_path}\")
#    message(\"Installing Arduino...\")
#    file(DOWNLOAD \"${travis_arduino_download_url}\" \"${CMAKE_BINARY_DIR}/${travis_arduino_file}\" SHOW_PROGRESS)
#    execute_process(
#       COMMAND \"${CMAKE_COMMAND}\" -E tar xvf \"${CMAKE_BINARY_DIR}/${travis_arduino_file}\"
#    )
# endif()
# "
# )
# 
# add_custom_command(
#    OUTPUT "${travis_arduino_path}"
#    COMMAND "${CMAKE_COMMAND}" -P "${travis_install_arduino_script}"
#    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
# )
#    
# add_custom_target(travis-install-arduino DEPENDS "${travis_arduino_path}")

add_custom_target(
   travis-smoke-examples
#    COMMAND "${CMAKE_COMMAND}" --build . --target travis-install-arduino
   COMMAND "${CMAKE_COMMAND}" --build . --target "${kaleidoscope_firmware_target}"
   WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
   COMMENT "Running smoke examples..."
)

# Add a custom target for the astyle tests
#
set(astyle_script "${cmake_scripts_dir}/astyle.script.cmake")


find_program(
   GIT_PROGRAM 
   git
)

file(WRITE "${astyle_script}"
"\
set(ENV{PATH} \"${plugin_test_bin_dir}:$ENV{PATH}\")
execute_process(
   COMMAND \"${plugin_test_support_dir}/run-astyle\"
)
execute_process(
   COMMAND \"${GIT_PROGRAM}\" diff --exit-code
   RESULT_VARIABLE result
)
if(NOT \"${result}\" EQUAL 0)
   message(FATAL_ERROR \"Astyle check found code style differences. Please run \\\"cmake --build . --target astyle\\\" and commit your changes\")
endif()
"
)

add_custom_target(
   travis-check-astyle
   COMMAND "${CMAKE_COMMAND}" -P "${astyle_script}"
   COMMENT "Running astyle to check code style compliance"
)
	
add_custom_target(travis-test)
add_dependencies(travis-test travis-smoke-examples travis-check-astyle)

add_custom_target(
   cpplint-noisy
   COMMAND "${plugin_test_support_dir}/cpplint.py"
      --filter=-legal/copyright,-build/include,-readability/namespace,,-whitespace/line_length 
      --recursive 
      --extensions=cpp,h,ino 
      "--exclude=${kaleidoscope_platform_dir}" 
      --exclude=${travis_arduino}
      src examples
)
	
add_custom_target(
   cpplint
	COMMAND "${plugin_test_support_dir}/cpplint.py"
      --quiet 
      --filter=-whitespace,-legal/copyright,-build/include,-readability/namespace  
      --recursive 
      --extensions=cpp,h,ino 
      src examples
)

add_custom_target(
   check-docs
   COMMAND doxygen "${plugin_test_support_dir}/check-docs.conf"
	COMMAND python "${plugin_test_support_dir}/doxy-coverage.py" /tmp/undocced/xml
)

add_custom_target(
   check-astyle
	COMMAND "${plugin_test_support_dir}/run-astyle"
	COMMAND "${GIT_PROGRAM}" diff --exit-code
)

# Note: The target name test is reserved in CMake for being used with CTest
#
add_custom_target(firmware_test)
add_dependencies(firmware_test "${kaleidoscope_firmware_target}" check-astyle cpplint-noisy check-docs)
