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

# Determine the device port for flashing
# (taken over from keyboardio/avr/libraries/Kaleidoscope/etc/kaleidoscope-builder.conf)
#
if(CMAKE_HOST_APPLE)

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

# Make the programmer user configurable
#
set(programmers "avrisp;avrispmkii;usbtinyisp;parallel;arduinoisp")
set(KALEIDOSCOPE_ARDUINO_PROGRAMMER 
   "avrispmkii" CACHE STRING
   "The firmware programmer to use for flashing (available: ${programmers})."
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