# Common CMake helpers for CLF projects.

# Find a required package. Additional arguments are treated as components.
# A macro is intentional: legacy Find modules often expose variables that need
# to remain visible in the caller's scope.
macro(find_required_library _lib_name)
    if(ARGN)
        find_package(${_lib_name} REQUIRED COMPONENTS ${ARGN})
    else()
        find_package(${_lib_name} REQUIRED)
    endif()
endmacro()

# Apply common C++ settings to a target (or PROJECT_NAME when omitted).
function(clf_common_set)
    if(ARGC GREATER 0)
        set(TARGET_NAME ${ARGV0})
    else()
        set(TARGET_NAME ${PROJECT_NAME})
    endif()

    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "clf_common_set: target '${TARGET_NAME}' does not exist")
    endif()

    target_compile_features(${TARGET_NAME} PRIVATE cxx_std_17)
    set_target_properties(${TARGET_NAME} PROPERTIES CXX_EXTENSIONS OFF)
    target_compile_options(${TARGET_NAME} PRIVATE
        $<$<CXX_COMPILER_ID:GNU>:-Wall>
        $<$<CXX_COMPILER_ID:Clang>:-Wall>
        $<$<CXX_COMPILER_ID:AppleClang>:-Wall>
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
    )
endfunction()

# Apply common CUDA settings to a target (or PROJECT_NAME when omitted).
function(clf_cuda_common_set)
    if(ARGC GREATER 0)
        set(TARGET_NAME ${ARGV0})
    else()
        set(TARGET_NAME ${PROJECT_NAME})
    endif()

    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "clf_cuda_common_set: target '${TARGET_NAME}' does not exist")
    endif()
    if(NOT CMAKE_CUDA_COMPILER_LOADED)
        message(FATAL_ERROR
            "clf_cuda_common_set: CUDA is not enabled; add CUDA to project(LANGUAGES ...)"
        )
    endif()

    set_target_properties(${TARGET_NAME} PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        # Build native cubins for Ampere and Ada, then retain compute_89 PTX as
        # a forward-compatible fallback for future GPU architectures.
        CUDA_ARCHITECTURES "80-real;86-real;89"
    )
    target_compile_features(${TARGET_NAME} PRIVATE cuda_std_17)
    target_compile_options(${TARGET_NAME} PRIVATE
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CUDA_COMPILER_ID:NVIDIA>,$<CONFIG:Debug>>:-G>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CUDA_COMPILER_ID:NVIDIA>,$<CONFIG:Debug>>:-g>
    )

    # CUDA_ARCHITECTURES above generates the equivalent of:
    #   -gencode arch=compute_80,code=sm_80
    #   -gencode arch=compute_86,code=sm_86
    #   -gencode arch=compute_89,code=sm_89
    #   -gencode arch=compute_89,code=compute_89
    target_compile_definitions(${TARGET_NAME} PRIVATE CLF_CUDA_ENABLED)
endfunction()

# Install and export a library target.
# Usage: clf_lib_install([TARGET target] [CONFIG_TEMPLATE path])
function(clf_lib_install)
    set(one_value_args TARGET CONFIG_TEMPLATE)
    cmake_parse_arguments(CLF_INSTALL "" "${one_value_args}" "" ${ARGN})

    if(CLF_INSTALL_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "clf_lib_install: unknown arguments: ${CLF_INSTALL_UNPARSED_ARGUMENTS}"
        )
    endif()
    if(CLF_INSTALL_TARGET)
        set(TARGET_NAME ${CLF_INSTALL_TARGET})
    else()
        set(TARGET_NAME ${PROJECT_NAME})
    endif()
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "clf_lib_install: target '${TARGET_NAME}' does not exist")
    endif()

    include(GNUInstallDirs)
    include(CMakePackageConfigHelpers)
    set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

    if(CLF_INSTALL_CONFIG_TEMPLATE)
        set(CONFIG_TEMPLATE ${CLF_INSTALL_CONFIG_TEMPLATE})
    else()
        set(CONFIG_TEMPLATE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-config.cmake.in)
    endif()
    if(NOT EXISTS "${CONFIG_TEMPLATE}")
        message(FATAL_ERROR
            "clf_lib_install: package config template not found: ${CONFIG_TEMPLATE}"
        )
    endif()

    message(STATUS "${PROJECT_NAME} install directory: ${CMAKE_INSTALL_PREFIX}")

    install(TARGETS ${TARGET_NAME}
        EXPORT ${PROJECT_NAME}-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

    # Keep the installed target name stable even when the local target differs
    # from the package name: <project>::<project>.
    set_target_properties(${TARGET_NAME} PROPERTIES EXPORT_NAME ${PROJECT_NAME})
    install(EXPORT ${PROJECT_NAME}-targets
        FILE ${PROJECT_NAME}-targets.cmake
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${INSTALL_CONFIGDIR}
    )

    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
    )
    configure_package_config_file(
        ${CONFIG_TEMPLATE}
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
    )
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
        DESTINATION ${INSTALL_CONFIGDIR}
    )

    export(EXPORT ${PROJECT_NAME}-targets
        FILE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-targets.cmake
        NAMESPACE ${PROJECT_NAME}::
    )
endfunction()
