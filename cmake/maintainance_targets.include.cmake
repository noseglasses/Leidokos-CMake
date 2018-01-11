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
