if(PROJECT_IS_TOP_LEVEL)
  set(
      CMAKE_INSTALL_INCLUDEDIR "include/libjacktimebase-${PROJECT_VERSION}"
      CACHE PATH ""
  )
endif()

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# find_package(<package>) call for consumers to find this project
set(package libjacktimebase)

install(
    DIRECTORY
    include/
    "${PROJECT_BINARY_DIR}/export/"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    COMPONENT libjacktimebase_Development
)

install(
    TARGETS libjacktimebase_libjacktimebase
    EXPORT libjacktimebaseTargets
    RUNTIME #
    COMPONENT libjacktimebase_Runtime
    LIBRARY #
    COMPONENT libjacktimebase_Runtime
    NAMELINK_COMPONENT libjacktimebase_Development
    ARCHIVE #
    COMPONENT libjacktimebase_Development
    INCLUDES #
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

write_basic_package_version_file(
    "${package}ConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)

# Allow package maintainers to freely override the path for the configs
set(
    libjacktimebase_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${package}"
    CACHE PATH "CMake package config location relative to the install prefix"
)
mark_as_advanced(libjacktimebase_INSTALL_CMAKEDIR)

install(
    FILES cmake/install-config.cmake
    DESTINATION "${libjacktimebase_INSTALL_CMAKEDIR}"
    RENAME "${package}Config.cmake"
    COMPONENT libjacktimebase_Development
)

install(
    FILES "${PROJECT_BINARY_DIR}/${package}ConfigVersion.cmake"
    DESTINATION "${libjacktimebase_INSTALL_CMAKEDIR}"
    COMPONENT libjacktimebase_Development
)

install(
    EXPORT libjacktimebaseTargets
    NAMESPACE libjacktimebase::
    DESTINATION "${libjacktimebase_INSTALL_CMAKEDIR}"
    COMPONENT libjacktimebase_Development
)

if(PROJECT_IS_TOP_LEVEL)
  include(CPack)
endif()
