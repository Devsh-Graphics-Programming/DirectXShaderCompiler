function(llvm_create_cross_target_internal target_name toolchain buildtype)

  if(NOT DEFINED LLVM_${target_name}_BUILD)
    set(LLVM_${target_name}_BUILD "${CMAKE_BINARY_DIR}/${target_name}")
    set(LLVM_${target_name}_BUILD ${LLVM_${target_name}_BUILD} PARENT_SCOPE)
    message(STATUS "Setting native build dir to " ${LLVM_${target_name}_BUILD})
  endif(NOT DEFINED LLVM_${target_name}_BUILD)

  if (EXISTS ${LLVM_MAIN_SRC_DIR}/cmake/platforms/${toolchain}.cmake)
    set(CROSS_TOOLCHAIN_FLAGS_${target_name} 
        -DCMAKE_TOOLCHAIN_FILE=\"${LLVM_MAIN_SRC_DIR}/cmake/platforms/${toolchain}.cmake\"
        CACHE STRING "Toolchain file for ${target_name}")
  endif()

  set(_native_compiler_flags_${target_name})
  set(_native_config_flags_${target_name})
  if(${target_name} STREQUAL "NATIVE")
    if(NOT LLVM_NATIVE_C_COMPILER)
      find_program(LLVM_NATIVE_C_COMPILER NAMES clang gcc cc)
    endif()
    if(NOT LLVM_NATIVE_CXX_COMPILER)
      find_program(LLVM_NATIVE_CXX_COMPILER NAMES clang++ g++ c++)
    endif()
    if(LLVM_NATIVE_C_COMPILER)
      list(APPEND _native_compiler_flags_${target_name} -DCMAKE_C_COMPILER=${LLVM_NATIVE_C_COMPILER})
    endif()
    if(LLVM_NATIVE_CXX_COMPILER)
      list(APPEND _native_compiler_flags_${target_name} -DCMAKE_CXX_COMPILER=${LLVM_NATIVE_CXX_COMPILER})
    endif()
    list(APPEND _native_config_flags_${target_name}
      -DLLVM_INCLUDE_TESTS=OFF
      -DHLSL_INCLUDE_TESTS=OFF
      -DSPIRV_BUILD_TESTS=OFF
      -DLLVM_INCLUDE_EXAMPLES=OFF)
    if(DEFINED LLVM_ENABLE_EH)
      list(APPEND _native_config_flags_${target_name} -DLLVM_ENABLE_EH=${LLVM_ENABLE_EH})
    endif()
    if(DEFINED LLVM_ENABLE_RTTI)
      list(APPEND _native_config_flags_${target_name} -DLLVM_ENABLE_RTTI=${LLVM_ENABLE_RTTI})
    endif()
    if(DEFINED ENABLE_SPIRV_CODEGEN)
      list(APPEND _native_config_flags_${target_name} -DENABLE_SPIRV_CODEGEN=${ENABLE_SPIRV_CODEGEN})
    endif()
  endif()

  add_custom_command(OUTPUT ${LLVM_${target_name}_BUILD}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${LLVM_${target_name}_BUILD}
    COMMENT "Creating ${LLVM_${target_name}_BUILD}...")

  add_custom_command(OUTPUT ${LLVM_${target_name}_BUILD}/CMakeCache.txt
    COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}"
        ${_native_compiler_flags_${target_name}}
        ${_native_config_flags_${target_name}}
        ${CROSS_TOOLCHAIN_FLAGS_${target_name}} ${CMAKE_SOURCE_DIR}
    WORKING_DIRECTORY ${LLVM_${target_name}_BUILD}
    DEPENDS ${LLVM_${target_name}_BUILD}
    COMMENT "Configuring ${target_name} LLVM...")

  add_custom_target(CONFIGURE_LLVM_${target_name}
                    DEPENDS ${LLVM_${target_name}_BUILD}/CMakeCache.txt)

  set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES
                                      ${LLVM_${target_name}_BUILD})

  if(NOT IS_DIRECTORY ${LLVM_${target_name}_BUILD})
    

    message(STATUS "Configuring ${target_name} build...")
    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
      ${LLVM_${target_name}_BUILD} )

    message(STATUS "Configuring ${target_name} targets...")
    if (buildtype)
      set(build_type_flags "-DCMAKE_BUILD_TYPE=${buildtype}")
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} ${build_type_flags}
        -G "${CMAKE_GENERATOR}" -DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}
        ${_native_compiler_flags_${target_name}}
        ${_native_config_flags_${target_name}}
        ${CROSS_TOOLCHAIN_FLAGS_${target_name}} ${CMAKE_SOURCE_DIR}
      WORKING_DIRECTORY ${LLVM_${target_name}_BUILD} )
  endif(NOT IS_DIRECTORY ${LLVM_${target_name}_BUILD})

endfunction()

function(llvm_create_cross_target target_name sysroot)
  llvm_create_cross_target_internal(${target_name} ${sysroot} ${CMAKE_BUILD_TYPE})
endfunction()

llvm_create_cross_target_internal(NATIVE "" Release)
