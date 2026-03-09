cmake_minimum_required(VERSION 3.13)

project(runner LANGUAGES CXX)

set(BINARY_NAME "weather_app")
set(APPLICATION_ID "ru.matveyb9.test.weatherapp")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/bundle" CACHE PATH "Install to bundle")
set(CMAKE_INSTALL_BINDIR "bin")

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

find_package(Threads REQUIRED)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(${FLUTTER_MANAGED_DIR})
add_subdirectory("runner")

set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_BINDIR}/../lib")
set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_BINDIR}/../data")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

install(DIRECTORY "${FLUTTER_ASSET_DIR}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime)

# Install application icon following XDG hicolor icon theme standard
foreach(icon_size 16 24 32 48 64 128 256 512)
  install(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/icons/hicolor/${icon_size}x${icon_size}/apps/weather_app.png"
    DESTINATION "share/icons/hicolor/${icon_size}x${icon_size}/apps"
    COMPONENT Runtime
  )
endforeach()

# Install .desktop file for application launcher integration
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/weather_app.desktop"
  DESTINATION "share/applications"
  COMPONENT Runtime
)
