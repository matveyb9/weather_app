cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided by the Flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Set fallback configurations for older versions of the flutter tool.
if (NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "windows-x64")
endif()

# === Flutter Library ===
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Flutter Windows library.
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${FLUTTER_MANAGED_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_MANAGED_DIR}/flutter_windows.dll.lib")
add_dependencies(flutter flutter_assemble)

# === Dart Build ===
# These are glue libraries provided by the flutter tool for using the
# Dart VM from the Windows Flutter embedding.
add_library(flutter_wrapper_app STATIC
  "${WRAPPER_ROOT}/flutter_engine.cc"
  "${WRAPPER_ROOT}/flutter_view.cc"
  "${WRAPPER_ROOT}/plugin_registrar.cc"
  "${WRAPPER_ROOT}/engine_method_channel.cc"
)
apply_standard_settings(flutter_wrapper_app)
set_target_properties(flutter_wrapper_app PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)
set_target_properties(flutter_wrapper_app PROPERTIES
  COMPILE_WARNING_AS_ERROR ON
)
target_compile_options(flutter_wrapper_app PRIVATE /W4 /WX)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_include_directories(flutter_wrapper_app PUBLIC
  "${WRAPPER_ROOT}/include"
)
add_dependencies(flutter_wrapper_app flutter_assemble)

# === Plugin registrant ===
add_library(flutter_wrapper_plugin STATIC
  "${WRAPPER_ROOT}/flutter_engine.cc"
)
apply_standard_settings(flutter_wrapper_plugin)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

# Generated registrant
set(GENERATED_PLUGIN_REGISTRANT
  "${EPHEMERAL_DIR}/generated_plugin_registrant.cc"
)
