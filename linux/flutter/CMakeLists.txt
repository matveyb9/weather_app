cmake_minimum_required(VERSION 3.13)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

include(${EPHEMERAL_DIR}/generated_config.cmake)

set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Flutter shared library.
add_library(flutter SHARED IMPORTED)
set_target_properties(flutter PROPERTIES
  IMPORTED_LOCATION "${FLUTTER_LIBRARY}"
)

# Plugin registrant.
set(GENERATED_PLUGIN_REGISTRANT "${EPHEMERAL_DIR}/generated_plugin_registrant.cc")
