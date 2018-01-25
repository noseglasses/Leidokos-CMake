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

set(plugin_test_support_dir "${kaleidoscope_platform_dir}/build-tools")
set(plugin_test_bin_dir "${plugin_test_support_dir}/x86_64/bin")

# Add a custom target for the astyle teste
#
add_custom_target(
   astyle
   COMMAND "${plugin_test_support_dir}/run-astyle"
)

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

# Prevent problems with backslashes on windows
#
file(TO_CMAKE_PATH "${ARDUINO_SDK_PATH}" cmake_arduino_sdk_path)

string(REPLACE "\\" "\\\\" cmake_program_fixed "${CMAKE_MAKE_PROGRAM}")

file(WRITE "${stock_build_script}" "\
set(ENV{BOARD_HARDWARE_PATH} \"${KALEIDOSCOPE_HARDWARE_BASE_PATH}\")
set(ENV{ARDUINO_SDK_PATH} \"${cmake_arduino_sdk_path}\")
set(ENV{ARDUINO_PATH} \"${cmake_arduino_sdk_path}\")

execute_process(
   COMMAND \"${cmake_program_fixed}\"
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

set(windows_hints "/c/cygwin64/bin" "/msys64/usr/bin")

find_program(
	CUT_EXECUTABLE
	NAMES cut
	HINTS ${windows_hints}
)

find_program(
	SORT_EXECUTABLE
	NAMES sort
	HINTS ${windows_hints}
)

find_program(
	DIFF_EXECUTABLE
	NAMES diff
	HINTS ${windows_hints}
)

set(nm_diff_script "${cmake_scripts_dir}/nm_diff.script.cmake")
file(WRITE "${nm_diff_script}" "\
set(nm_out_legacy \"${CMAKE_BINARY_DIR}/nm_legacy.txt\")
execute_process(
   COMMAND \"${AVRNM_PROGRAM}\" -C \"${KALEIDOSCOPE_LIBRARIES_DIR}/${product_id}-Firmware/output/${product_id}-Firmware/${product_id}-Firmware-latest.elf\"
   COMMAND ${CUT_EXECUTABLE} \"-d \" -f3
   COMMAND ${SORT_EXECUTABLE}
   OUTPUT_FILE \"\${nm_out_legacy}\"
)

set(nm_out_new \"${CMAKE_BINARY_DIR}/nm_new.txt\")
execute_process(
   COMMAND \"${AVRNM_PROGRAM}\" -C \"${CMAKE_BINARY_DIR}/${kaleidoscope_firmware_target}.elf\"
   COMMAND ${CUT_EXECUTABLE} \"-d \" -f3
   COMMAND ${SORT_EXECUTABLE}
   OUTPUT_FILE \"\${nm_out_new}\"
)

execute_process(
   COMMAND ${DIFF_EXECUTABLE} \"\${nm_out_legacy}\" \"\${nm_out_new}\"
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