# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "F:/app/Esp_idf/esp-idf/esp-idf/components/bootloader/subproject"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/tmp"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/src/bootloader-stamp"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/src"
  "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/src/bootloader-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/src/bootloader-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "F:/ESP32/Tutorials/Bai18_Series_BLE_Mesh/custom_server/build/bootloader-prefix/src/bootloader-stamp${cfgdir}") # cfgdir has leading slash
endif()
