# The following definintions must occur before the toolchain
# file is included below, to make them visibile to Arduino-CMakes build
# system.
#
set(KALEIDOSCOPE_KEYBOARD_HARDWARE "Model01" CACHE STRING
   "The type of the keyboard hardware. Currently supported Model01, Raise, Shortcut")

set(ARDUINO_CXX_FLAGS "-std=gnu++11 -DKALEIDOSCOPE_HARDWARE_H=\\\"Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}.h\\\" -DUSB_MANUFACTURER=\\\"Keyboardio\\\" \"-DUSB_PRODUCT=\\\"Model 01\\\"\" -Wall -Wextra")

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/3rd_party/arduino-cmake/cmake/ArduinoToolchain.cmake")

# Make sure that the correct avr-gcc of the arduino installation
# is found. 
#
# Note: To do this right the toolchain file would need to be modified
#       to use the actually determined ARDUINO_SDK_PATH to 
#       define CMAKE_PREFIX_PATH.
#
if(NOT "$ENV{ARDUINO_PATH}" STREQUAL "")
   set(CMAKE_PREFIX_PATH "$ENV{ARDUINO_PATH}/hardware/tools/avr;${CMAKE_PREFIX_PATH}")
endif()

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

arduino_debug_on()


# set_target_properties(kaleidoscope.firmware PROPERTIES
#   COMPILE_FLAGS -DKALEIDOSCOPE_HARDWARE_H="Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}.h"
# )

# Enables for the standard directory containing Kaleidoscope libraries
# to be found
#
link_directories("${CMAKE_SOURCE_DIR}/..")

# Allows the Arduino default sources to be found
#
# include_directories("${ARDUINO_SDK_PATH}/hardware/arduino/avr/cores/arduino")

get_filename_component(kaleidoscope_lib_dir "${CMAKE_SOURCE_DIR}" DIRECTORY)

# Add all Arduino library dirs as include directories
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

 set(additional_libraries 
    "Kaleidoscope-Hardware-${KALEIDOSCOPE_KEYBOARD_HARDWARE}"
#    "Kaleidoscope"
    "KeyboardioScanner"
#    "Kaleidoscope-Focus"
#    "Kaleidoscope-LED-AlphaSquare"
)

set(all_add_src)
foreach(add_lib ${additional_libraries})
   file(GLOB_RECURSE add_src "${kaleidoscope_lib_dir}/${add_lib}/*.cpp")
message("add_src: ${add_src}")
   list(APPEND all_add_src ${add_src})
endforeach()

message("all_add_src: ${all_add_src}")

generate_arduino_firmware(
   kaleidoscope.firmware # CMake target name
   BOARD model01
   SKETCH "${kaleidoscope_lib_dir}/Model01-Firmware/Model01-Firmware.ino"
   SRCS ${all_add_src}
   PORT "${device_port}"
   PROGRAMMER avrispmkii
#    NO_AUTOLIBS
)