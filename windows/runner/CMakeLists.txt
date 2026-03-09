cmake_minimum_required(VERSION 3.14)

set(BINARY_NAME "weather_app")

configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/runner.rc.in"
  "${CMAKE_CURRENT_BINARY_DIR}/runner.rc"
)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${CMAKE_CURRENT_BINARY_DIR}/runner.rc"
  "Runner.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  flutter_wrapper_app
)
target_link_libraries(${BINARY_NAME} PRIVATE
  "dwmapi.lib"
)
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
