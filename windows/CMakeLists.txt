cmake_minimum_required(VERSION 3.14)
project(weather_app LANGUAGES CXX)

set(BINARY_NAME "weather_app")
set(APPLICATION_ID "ru.matveyb9.test.weatherapp")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/run" CACHE PATH "Install to run dir")
set(CMAKE_INSTALL_BINDIR ".")

find_package(Flutter REQUIRED)

add_subdirectory(flutter)
add_subdirectory(runner)

set_target_properties(${BINARY_NAME} PROPERTIES
  OUTPUT_NAME "weather_app"
)

set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL}"
)

apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
