# cmake/vision_common_functions.cmake

# Function for find required package
function(find_required_library _lib_name)
    # 1: parse optional args (the args after first arg)
    set(_components ${ARGN})
    
    # 2: do find
    if(_components)
        find_package(${_lib_name} REQUIRED COMPONENTS ${_components})
    else()
        find_package(${_lib_name} REQUIRED)
    endif()

    # 3: check whether FOUND (such as X11 → X11_FOUND，glfw3 → glfw3_FOUND)
    set(_found_var "${_lib_name}_FOUND")
    if(${_found_var})
        # if(_components)
        #     message(STATUS "${PROJECT_NAME}: ${_lib_name} is found (components: ${_components})")
        # else()
        #     message(STATUS "${PROJECT_NAME}: ${_lib_name} is found")
        # endif()
        # set(_lib_var "${_lib_name}_LIBRARIES")
        # message(STATUS "${PROJECT_NAME}: ${_lib_var}: ${${_lib_var}}")
    else()
        message(FATAL_ERROR "${PROJECT_NAME}: Cannot find ${_lib_name}")
    endif()
endfunction()

# Function for cmake CXX common settings
function(cvlf_common_set)
    target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
    target_compile_options(${PROJECT_NAME} PRIVATE -std=c++17)
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "Release" CACHE INTERNAL "Build type for ${PROJECT_NAME}")
    endif()
    target_compile_options(${PROJECT_NAME} PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Wall>)
endfunction()

# Function for CUDA common settings
function(cvlf_cuda_common_set)
    set_target_properties(${PROJECT_NAME} PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:
            -gencode arch=compute_61,code=sm_61
            -gencode arch=compute_75,code=sm_75
            -gencode arch=compute_80,code=sm_80
            -gencode arch=compute_86,code=sm_86
            -std=c++17
            -rdc=true
            -diag-suppress=611
            --disable-warnings
            -O2
            -G
            -g            
        >
    )
    get_target_property(IS_SEPARABLE ${PROJECT_NAME} CUDA_SEPARABLE_COMPILATION)
    message(STATUS "CUDA_SEPARABLE_COMPILATION: ${IS_SEPARABLE}")
    message(STATUS "CUDA_INCLUDE_DIRS:          ${CUDA_INCLUDE_DIRS}")
    message(STATUS "CUDAToolkit_INCLUDE_DIRS:   ${CUDAToolkit_INCLUDE_DIRS}")
    message(STATUS "CUDA_TOOLKIT_ROOT_DIR:      ${CUDA_TOOLKIT_ROOT_DIR}")
    message(STATUS "CUDAToolkit_ROOT:           ${CUDAToolkit_ROOT}")
    get_target_property(COMPILE_OPTIONS ${PROJECT_NAME} COMPILE_OPTIONS)
    message(STATUS "COMPILE_OPTIONS: ${COMPILE_OPTIONS}")
endfunction()

# Function for install
function(cvlf_lib_install)
    include(GNUInstallDirs)
    set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

    message(STATUS "${PROJECT_NAME} install directory: ${INSTALL_CONFIGDIR}")

    install(TARGETS ${PROJECT_NAME}
        EXPORT ${PROJECT_NAME}-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

    # This is required so that the exported target has the name ${PROJECT_NAME} 
    set_target_properties(${PROJECT_NAME} PROPERTIES EXPORT_NAME ${PROJECT_NAME})

    # Export the targets to a script
    install(EXPORT ${PROJECT_NAME}-targets
        FILE
            ${PROJECT_NAME}-targets.cmake
        DESTINATION
            ${INSTALL_CONFIGDIR}
    )

    # Create a -config-version.cmake file
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    configure_package_config_file(
        ${CMAKE_CURRENT_LIST_DIR}/cmake/${PROJECT_NAME}-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
    )

    # Install the config, configversion and custom find modules
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
        DESTINATION ${INSTALL_CONFIGDIR}
    )

    ##############################################
    ## Exporting from the build tree
    # configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/FindRapidJSON.cmake
    #     ${CMAKE_CURRENT_BINARY_DIR}/FindRapidJSON.cmake
    #     COPYONLY)

    export(EXPORT ${PROJECT_NAME}-targets FILE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-targets.cmake)

    #Register package in user's package registry
    export(PACKAGE ${PROJECT_NAME})

    #if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
    #	add_subdirectory(test)
    #endif(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
endfunction()