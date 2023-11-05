cmake_minimum_required(VERSION 3.14)

include(cmake/prelude.cmake)

project(
    jacktimebase
    VERSION 0.1.0
    DESCRIPTION "Short description"
    HOMEPAGE_URL "https://example.com/"
    LANGUAGES C
)

include(cmake/project-is-top-level.cmake)
include(cmake/variables.cmake)

# ---- Declare library ----

add_library(
    libjacktimebase_libjacktimebase
    source/jacktimebase.c
)
add_library(libjacktimebase::libjacktimebase ALIAS libjacktimebase_libjacktimebase)

include(GenerateExportHeader)
generate_export_header(
    libjacktimebase_libjacktimebase
    BASE_NAME libjacktimebase
    EXPORT_FILE_NAME export/libjacktimebase/libjacktimebase_export.h
)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(libjacktimebase_libjacktimebase PUBLIC libjacktimebase_STATIC_DEFINE)
endif()

set_target_properties(
    libjacktimebase_libjacktimebase PROPERTIES
    C_VISIBILITY_PRESET hidden
    VERSION "${PROJECT_VERSION}"
    SOVERSION "${PROJECT_VERSION_MAJOR}"
    EXPORT_NAME jacktimebase
    OUTPUT_NAME jacktimebase
)

target_include_directories(
    libjacktimebase_libjacktimebase ${warning_guard}
    PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
)

target_include_directories(
    libjacktimebase_libjacktimebase SYSTEM
    PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/export>"
)

target_compile_features(libjacktimebase_libjacktimebase PUBLIC c_std_99)

target_link_libraries(libjacktimebase_libjacktimebase jack)

add_custom_target(run
    COMMAND LD_LIBRARY_PATH=${PROJECT_BINARY_DIR} luajit lua/test1.lua
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
add_dependencies(run libjacktimebase_libjacktimebase)

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/install-rules.cmake)
endif()

# ---- Developer mode ----

if(NOT libjacktimebase_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(
      AUTHOR_WARNING
      "Developer mode is intended for developers of libjacktimebase"
  )
endif()

include(cmake/dev-mode.cmake)
