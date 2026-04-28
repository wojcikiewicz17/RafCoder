cmake_minimum_required(VERSION 3.22.1)
project(rafcoder_native)

set(RAFCODER_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../..")

set(RAFCODER_NATIVE_SOURCES
    native-lib.cpp
    "${RAFCODER_ROOT}/core/sector.c"
    "${RAFCODER_ROOT}/core/arch/primitives.c"
)

if(ANDROID_ABI STREQUAL "arm64-v8a")
    list(APPEND RAFCODER_NATIVE_SOURCES
        "${RAFCODER_ROOT}/core/arch/aarch64/primitives.S"
    )
endif()

add_library(rafcoder_native SHARED ${RAFCODER_NATIVE_SOURCES})

target_include_directories(rafcoder_native PRIVATE
    "${RAFCODER_ROOT}/core"
    "${RAFCODER_ROOT}/core/arch"
)

find_library(log-lib log)

target_link_libraries(rafcoder_native ${log-lib})
