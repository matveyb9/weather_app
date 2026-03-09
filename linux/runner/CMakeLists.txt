cmake_minimum_required(VERSION 3.13)

set(BINARY_NAME "weather_app")

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${GENERATED_PLUGIN_REGISTRANT}"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE APPLICATION_ID="${APPLICATION_ID}")

target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  PkgConfig::GTK
)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)

install(TARGETS ${BINARY_NAME}
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  COMPONENT Runtime
)
