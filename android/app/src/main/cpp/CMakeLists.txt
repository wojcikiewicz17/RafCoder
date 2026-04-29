cmake_minimum_required(VERSION 3.22.1)
project(rafcoder_native)

set(RAFCODER_ROOT "" CACHE PATH "Absolute path to RafCoder repository root. Preferred source of truth via -DRAFCODER_ROOT=/path/to/repo")

set(RAFCODER_ROOT_FALLBACK "${CMAKE_CURRENT_LIST_DIR}/../../../../..")
if(NOT RAFCODER_ROOT)
    get_filename_component(RAFCODER_ROOT "${RAFCODER_ROOT_FALLBACK}" ABSOLUTE)
endif()

set(RAFCODER_SECTOR_C "${RAFCODER_ROOT}/core/sector.c")
set(RAFCODER_PRIMITIVES_C "${RAFCODER_ROOT}/core/arch/primitives.c")

if(NOT EXISTS "${RAFCODER_SECTOR_C}")
    message(FATAL_ERROR
        "RAFCODER_ROOT is invalid: '${RAFCODER_ROOT}'. Missing required file: '${RAFCODER_SECTOR_C}'. "
        "Set -DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root (or fix the fallback path '${RAFCODER_ROOT_FALLBACK}').")
endif()

if(NOT EXISTS "${RAFCODER_PRIMITIVES_C}")
    message(FATAL_ERROR
        "RAFCODER_ROOT is invalid: '${RAFCODER_ROOT}'. Missing required file: '${RAFCODER_PRIMITIVES_C}'. "
        "Set -DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root (or fix the fallback path '${RAFCODER_ROOT_FALLBACK}').")
endif()

set(RAFCODER_NATIVE_SOURCES
    native-lib.cpp
    "${RAFCODER_SECTOR_C}"
    "${RAFCODER_PRIMITIVES_C}"
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
