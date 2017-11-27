set(product_id "Virtual")
set(board_id "virtual")
set(usb_product "Virtual")
set(usb_manufacturer "Nowbody")
# set(platform_additional_libraries 
#     "Kaleidoscope-Hardware-${product_id}")#;KeyboardioScanner")
   
# The distinction between guest and virtual HID libraries is done via
# a #ifdef clause in the source code. This cannot be handled 
# by Arduino-CMake. Thus, we suppress the accidentally founde
# guest HID library.
#
set(blacklisted_libraries "\
${KALEIDOSCOPE_LIBRARIES_DIR}/HID;\
${KALEIDOSCOPE_LIBRARIES_DIR}/HID/src;\
${KALEIDOSCOPE_LIBRARIES_DIR}/KeyboardioHID;\
${KALEIDOSCOPE_LIBRARIES_DIR}/KeyboardioHID/src\
")
# 
# function(configure_firmware_target
#    target_
# )
#    target_link_libraries("${target_}" m)
# endfunction()

# This forces creation of a shared firmware library instead of an executable
#
set(ARDUINO_CMAKE_GENERATE_SHARED_LIBRARIES TRUE CACHE INTERNAL "")
set(ARDUINO_CMAKE_ONLY_ELF TRUE CACHE INTERNAL "")
