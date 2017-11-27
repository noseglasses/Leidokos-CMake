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
# The following definintions must occur before the toolchain
# file is included below, to make them visible to Arduino-CMakes build
# system.

# To enable Kaleidoscope-CMake to be included in other 
# CMake projects' CMakeLists.txt files, we use KALEIDOSCOPE_CMAKE_SOURCE_DIR
# instead of CMAKE_SOURCE_DIR. KALEIDOSCOPE_CMAKE_SOURCE_DIR
# can be set by the including CMake code.
#
set(KALEIDOSCOPE_CMAKE_SOURCE_DIR "${CMAKE_SOURCE_DIR}"
   CACHE PATH "The path to the Kaleidoscope-CMake sources. This is only \"
required to be set when Kaleidoscope-CMake is wrapped \
by other CMake build systems")

# The toolchain file is used when the project is initialized using
# the project(...) directive further down.
#
set(KALEIDOSCOPE_HOST_BUILD FALSE CACHE BOOL "Enable this flag in the \
rare case that you want to build for the host system instead of the \
Arduino architecture (virtual builds)")

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
   
set(KALEIDOSCOPE_DOWNLOAD_ARDUINO FALSE CACHE BOOL "If this flag is \
enabled, the build system downloads Arduino")

# Travis testing settings
#
set(travis_arduino "arduino-1.8.5")
set(travis_arduino_file "${travis_arduino}-linux64.tar.xz")
set(travis_arduino_path "${CMAKE_BINARY_DIR}/${travis_arduino}")
set(travis_arduino_download_url "http://downloads.arduino.cc/${travis_arduino_file}")

if(KALEIDOSCOPE_DOWNLOAD_ARDUINO)

   if(NOT EXISTS "${travis_arduino_path}")
      message("Installing Arduino...")
      file(DOWNLOAD "${travis_arduino_download_url}" "${CMAKE_BINARY_DIR}/${travis_arduino_file}")
      execute_process(
         COMMAND "${CMAKE_COMMAND}" -E tar xf "${CMAKE_BINARY_DIR}/${travis_arduino_file}"
         WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      )
   endif()
   
   set(ARDUINO_SDK_PATH "${CMAKE_BINARY_DIR}/${travis_arduino}" CACHE PATH "")
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

# Initialize the CMake project. This uses the CMAKE_TOOLCHAIN_FILE
# defined above and implicitly includes 
# ${KALEIDOSCOPE_CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/Platform/Arduino.cmake
#
project(Kaleidoscope)
cmake_minimum_required(VERSION 2.8)

################################################################################
# Setup and variable definitions
################################################################################

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
   CACHE PATH "The path to the Kaleidoscope hardware base directory")
   
set(KALEIDOSCOPE_VENDOR_ID "${default_vendor_id}" 
   CACHE STRING "The vendor id of the board to build a firmware for")

set(KALEIDOSCOPE_ARCHITECTURE_ID "${default_architecture_id}"
   CACHE STRING "The architecture id of the board to build a firmware for")

if(NOT EXISTS "${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
   message(FATAL_ERROR "Unable to find \
KALEIDOSCOPE_HARDWARE_BASE_PATH=${KALEIDOSCOPE_HARDWARE_BASE_PATH}")
endif()

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
   "A path to the libraries directory where the Kaleidoscope libraries live")

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
   Currently supported: ${${vendor_id_upper}_BOARDS}")
   
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
   "${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware\
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

# Some targets require additional CMake scripts that enable using
# portable CMake code during the build stage.
#
set(cmake_scripts_dir "${CMAKE_BINARY_DIR}/cmake_scripts")
if(NOT EXISTS "${cmake_scripts_dir}")
   file(MAKE_DIRECTORY "${cmake_scripts_dir}")
endif()

# kaleidoscope_firmware_target is used as identifier 
# for auto generated target names.
#
set(kaleidoscope_firmware_target "kaleidoscope.firmware")

set(ARDUINO_CMAKE_RECURSION_DEFAULT TRUE CACHE INTERNAL "")

################################################################################
# Project generation
################################################################################

# Uncomment this for detailed debugging of Arduino-CMake output.
#
# arduino_debug_on()

# Allow the standard directory containing Kaleidoscope libraries
# to be found. Note: Arduino-CMake relies on this to be defined
# to search for Arduino libraries.
#
link_directories("${KALEIDOSCOPE_LIBRARIES_DIR}")

# Make sure that all Arduino library dirs are exported 
# as include (-I...) directories.
#
file(GLOB dirs "${KALEIDOSCOPE_LIBRARIES_DIR}/*")
foreach(dir ${dirs})
   include_directories("${dir}")
   include_directories("${dir}/src")
   include_directories("${dir}/src/Kaleidoscope")
endforeach()

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
endforeach()

set(KALEIDOSCOPE_ADDITIONAL_SOURCES "" CACHE STRING
   "A list of absolute paths of source files that are included in the \
firmware build. This is only required for advanced use, e.g. when \
Kaleidoscope-CMake is embedded in another CMake build system")

if(NOT "${KALEIDOSCOPE_ADDITIONAL_SOURCES}" STREQUAL "")
   list(APPEND all_add_src ${KALEIDOSCOPE_ADDITIONAL_SOURCES})
endif()

set(KALEIDOSCOPE_ADDITIONAL_HEADERS "" CACHE STRING
   "A list of absolute paths of header files that are included in the \
firmware build. This is only required for advanced use, e.g. when \
Kaleidoscope-CMake is embedded in another CMake build system")

if(NOT "${KALEIDOSCOPE_ADDITIONAL_HEADERS}" STREQUAL "")
   set(add_headers HDRS ${KALEIDOSCOPE_ADDITIONAL_HEADERS})
endif()

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
${ARDUINO_SDK_PATH}/libraries/Mouse/src;\
${blacklisted_libraries}\
"
   CACHE INTERNAL "")

generate_arduino_firmware(
   "${kaleidoscope_firmware_target}" # CMake target name
   BOARD "${board_id}"
   SKETCH "${KALEIDOSCOPE_FIRMWARE_SKETCH}"
   ${add_headers}
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
if(COMMAND kaleidoscope_set_binary_basename)
   kaleidoscope_set_binary_basename(binary_basename_default)
endif()
set(KALEIDOSCOPE_BINARY_BASENAME "${binary_basename_default}" CACHE STRING 
   "An alternative name for the generated firmware binary. The default name is used if empty.")
   
if(NOT "${KALEIDOSCOPE_BINARY_BASENAME}" STREQUAL "")
   set_target_properties("${kaleidoscope_firmware_target}" 
      PROPERTIES OUTPUT_NAME "${KALEIDOSCOPE_BINARY_BASENAME}")
   set_target_properties("${kaleidoscope_firmware_target}" PROPERTIES PREFIX "")
   set_target_properties("${kaleidoscope_firmware_target}" PROPERTIES SUFFIX "")
endif()
   
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

# Add a custom target for the astyle tests
#
set(stock_build_script "${cmake_scripts_dir}/stock_build.script.cmake")

file(WRITE "${stock_build_script}" "\
set(ENV{BOARD_HARDWARE_PATH} \"${KALEIDOSCOPE_HARDWARE_BASE_PATH}\")
set(ENV{ARDUINO_SDK_PATH} \"${ARDUINO_SDK_PATH}\")
set(ENV{ARDUINO_PATH} \"${ARDUINO_SDK_PATH}\")

execute_process(
   COMMAND make
   WORKING_DIRECTORY \"${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware\"
)
")

add_custom_target(
   stock_build
   COMMAND "${CMAKE_COMMAND}" -P "${stock_build_script}"
   COMMENT "Running a build with the stock firmware"
)

add_custom_target(
   firmware_binary_check
   COMMAND diff "${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware/output/${product_id}-Firmware/${product_id}-Firmware-latest.elf" "${CMAKE_BINARY_DIR}/${kaleidoscope_firmware_target}.elf"
   COMMENT "Comparing to firmware build with stock build system"
)

add_dependencies(firmware_binary_check stock_build "${kaleidoscope_firmware_target}")

set(nm_diff_script "${cmake_scripts_dir}/nm_diff.script.cmake")
file(WRITE "${nm_diff_script}" "\
set(nm_out_legacy \"${CMAKE_BINARY_DIR}/nm_legacy.txt\")
execute_process(
   COMMAND \"${AVRNM_PROGRAM}\" -C \"${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware/output/${product_id}-Firmware/${product_id}-Firmware-latest.elf\"
   COMMAND cut \"-d \" -f3
   COMMAND sort
   OUTPUT_FILE \"\${nm_out_legacy}\"
)

set(nm_out_new \"${CMAKE_BINARY_DIR}/nm_new.txt\")
execute_process(
   COMMAND \"${AVRNM_PROGRAM}\" -C \"${CMAKE_BINARY_DIR}/${kaleidoscope_firmware_target}.elf\"
   COMMAND cut \"-d \" -f3
   COMMAND sort
   OUTPUT_FILE \"\${nm_out_new}\"
)

execute_process(
   COMMAND diff \"\${nm_out_legacy}\" \"\${nm_out_new}\"
   OUTPUT_VARIABLE output
   ERROR_VARIABLE error
   RESULT_VARIABLE diff_result
)

if(NOT diff_result EQUAL 0)
   message(\"Legacy and new build differ\")
   message(\"\${output}\")
   message(\"\${error}\")
   message(FATAL_ERROR \"Aborting.\")
else()
   message(\"Success: Both firmwares contain the same symbols\")
endif()
")

add_custom_target(
   nm_diff
   COMMAND "${CMAKE_COMMAND}" -P "${nm_diff_script}"
   COMMENT "Comparing nm output of legacy and new build system"
)

add_dependencies(nm_diff stock_build "${kaleidoscope_firmware_target}")